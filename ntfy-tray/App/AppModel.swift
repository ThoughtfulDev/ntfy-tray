import AppKit
import Foundation
import Observation
import SwiftData
@preconcurrency import UserNotifications

@MainActor
@Observable
final class AppModel {
    private let modelContext: ModelContext
    private let keychainStore: any BearerTokenStoring
    private let subscriptionClient = NtfySubscriptionClient()
    private let notificationCoordinator: any NotificationCoordinating
    private var subscriptionTask: Task<Void, Never>?
    private var lastSubscribedServerURL: String?
    private var inboxRevision = 0
    private var quietHoursRevision = 0

    private(set) var configuration: ServerConfiguration?
    private(set) var connectionState: ConnectionState = .idle
    private(set) var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var lastError: String?
    private(set) var isPrepared = false

    init(
        modelContext: ModelContext,
        keychainStore: any BearerTokenStoring = KeychainStore(),
        notificationCoordinator: any NotificationCoordinating = NotificationCoordinator()
    ) {
        self.modelContext = modelContext
        self.keychainStore = keychainStore
        self.notificationCoordinator = notificationCoordinator
    }

    var needsOnboarding: Bool {
        !(configuration?.didCompleteOnboarding ?? false)
    }

    var isQuiet: Bool {
        _ = quietHoursRevision
        guard let configuration else { return false }
        return configuration.isManualDoNotDisturbEnabled || QuietHoursEvaluator.isQuiet(at: .now, rules: quietHoursRules)
    }

    var statusSymbolName: String {
        if isQuiet { return "moon.zzz.fill" }
        if unreadCount > 0 { return "bell.badge.fill" }
        return connectionState.symbolName
    }

    var statusLabel: String {
        if isQuiet { return "Do Not Disturb is on" }
        if unreadCount > 0 { return "\(unreadCount) unread notifications" }
        return connectionState.label
    }

    var unreadCount: Int {
        _ = inboxRevision
        return (try? modelContext.fetchCount(FetchDescriptor<InboxMessage>(predicate: #Predicate { !$0.isRead }))) ?? 0
    }

    var quietHoursRules: [QuietHoursRule] {
        let descriptor = FetchDescriptor<QuietHoursRule>(sortBy: [SortDescriptor(\QuietHoursRule.weekday)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func prepare(openInbox: @escaping () -> Void) async {
        guard !isPrepared else { return }
        do {
            let descriptor = FetchDescriptor<ServerConfiguration>()
            let existing = try modelContext.fetch(descriptor)
            let configuration = existing.first ?? ServerConfiguration()
            if existing.isEmpty {
                modelContext.insert(configuration)
            }
            self.configuration = configuration
            try seedQuietHoursRulesIfNeeded()
            try updateMessageTopicIcons()
            try modelContext.save()
            notificationCoordinator.configure(openInbox: openInbox)
            await refreshNotificationAuthorizationStatus()
            isPrepared = true
            restartSubscriptionIfPossible()
        } catch {
            lastError = error.localizedDescription
            connectionState = .failed(error.localizedDescription)
        }
    }

    func requestNotificationPermission() async {
        do {
            let isAuthorized = try await notificationCoordinator.requestAuthorization()
            await refreshNotificationAuthorizationStatus()
            if isAuthorized {
                lastError = nil
            } else {
                lastError = "Notifications are not allowed for this build. Open Notification Settings to allow them."
            }
        } catch {
            lastError = notificationErrorMessage(for: error, action: "request notification permission")
            await refreshNotificationAuthorizationStatus()
        }
    }

    func refreshNotificationAuthorizationStatus() async {
        notificationAuthorizationStatus = await notificationCoordinator.authorizationStatus()
    }

    func openNotificationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") else { return }
        NSWorkspace.shared.open(url)
    }

    func saveServer(urlString: String, bearerToken: String) async throws {
        let normalizedURL = try validatedServerURL(from: urlString)
        guard let configuration else { throw AppModelError.notPrepared }

        try await keychainStore.save(token: bearerToken.trimmingCharacters(in: .whitespacesAndNewlines))
        configuration.serverURLString = normalizedURL.absoluteString
        try saveContext()
        lastError = nil
        restartSubscriptionIfPossible()
    }

    func storedBearerToken() async -> String {
        do {
            return try await keychainStore.token() ?? ""
        } catch {
            lastError = error.localizedDescription
            return ""
        }
    }

    func completeOnboarding(
        urlString: String,
        bearerToken: String,
        topicName: String
    ) async throws {
        try await saveServer(
            urlString: urlString,
            bearerToken: bearerToken
        )

        if !NtfyURLBuilder.normalizeTopic(topicName).isEmpty {
            try addTopic(named: topicName, symbolName: TopicIconIdentifier.defaultValue)
        }
        configuration?.didCompleteOnboarding = true
        try saveContext()
        await requestNotificationPermission()
        restartSubscriptionIfPossible()
    }

    func addTopic(named name: String, symbolName: String) throws {
        let normalizedName = NtfyURLBuilder.normalizeTopic(name)
        guard !normalizedName.isEmpty else { throw AppModelError.emptyTopic }

        let descriptor = FetchDescriptor<TopicSubscription>()
        let topics = try modelContext.fetch(descriptor)
        guard !topics.contains(where: { $0.name.localizedCaseInsensitiveCompare(normalizedName) == .orderedSame }) else {
            throw AppModelError.duplicateTopic
        }

        modelContext.insert(TopicSubscription(name: normalizedName, symbolName: symbolName))
        try saveContext()
        restartSubscriptionIfPossible()
    }

    func deleteTopic(_ topic: TopicSubscription) {
        modelContext.delete(topic)
        do {
            try saveContext()
            restartSubscriptionIfPossible()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func resetAppData() async throws {
        guard let configuration else { throw AppModelError.notPrepared }

        subscriptionTask?.cancel()
        subscriptionTask = nil
        connectionState = .idle

        do {
            try await keychainStore.deleteToken()

            try modelContext.fetch(FetchDescriptor<TopicSubscription>()).forEach(modelContext.delete)
            try modelContext.fetch(FetchDescriptor<InboxMessage>()).forEach(modelContext.delete)
            try modelContext.fetch(FetchDescriptor<QuietHoursRule>()).forEach(modelContext.delete)

            configuration.serverURLString = "https://ntfy.sh"
            configuration.didCompleteOnboarding = false
            configuration.isManualDoNotDisturbEnabled = false
            try seedQuietHoursRulesIfNeeded()
            try saveContext()

            notificationCoordinator.removeAllNotifications()
            lastSubscribedServerURL = nil
            inboxRevision += 1
            quietHoursRevision += 1
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }

    func saveTopicChanges() {
        do {
            try updateMessageTopicIcons()
            try saveContext()
            inboxRevision += 1
            restartSubscriptionIfPossible()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func saveQuietHoursChanges() {
        do {
            try saveContext()
            quietHoursRevision += 1
        } catch {
            lastError = error.localizedDescription
        }
    }

    func setManualDoNotDisturb(_ enabled: Bool) {
        configuration?.isManualDoNotDisturbEnabled = enabled
        do {
            try saveContext()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LoginItemService().setEnabled(enabled)
            lastError = nil
        } catch {
            lastError = "Could not update launch at login: \(error.localizedDescription)"
        }
    }

    func markAllRead() {
        let descriptor = FetchDescriptor<InboxMessage>(predicate: #Predicate { !$0.isRead })
        guard let messages = try? modelContext.fetch(descriptor) else { return }
        messages.forEach { $0.isRead = true }
        do {
            try saveContext()
            inboxRevision += 1
        } catch {
            lastError = error.localizedDescription
        }
    }

    func markRead(_ message: InboxMessage) {
        guard !message.isRead else { return }
        message.isRead = true
        do {
            try saveContext()
            inboxRevision += 1
        } catch {
            lastError = error.localizedDescription
        }
    }

    func deleteMessage(_ message: InboxMessage) {
        do {
            let messageID = message.id
            try deleteMessages(matching: #Predicate { $0.id == messageID })
        } catch {
            lastError = error.localizedDescription
        }
    }

    func deleteMessages(forTopic topic: String) {
        do {
            try deleteMessages(matching: #Predicate { $0.topic == topic })
        } catch {
            lastError = error.localizedDescription
        }
    }

    func messageCount(forTopic topic: String) -> Int {
        let descriptor = FetchDescriptor<InboxMessage>(predicate: #Predicate { $0.topic == topic })
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    private func restartSubscriptionIfPossible() {
        subscriptionTask?.cancel()
        connectionState = .idle

        guard isPrepared, !enabledTopics.isEmpty else { return }
        subscriptionTask = Task { [weak self] in
            await self?.runSubscription()
        }
    }

    private func runSubscription() async {
        var retryDelay = 1
        while !Task.isCancelled {
            do {
                let request = try await subscriptionRequest()
                connectionState = retryDelay == 1 ? .connecting : .reconnecting
                let stream = try await subscriptionClient.events(for: request)
                connectionState = .connected

                for try await event in stream {
                    consume(event)
                    retryDelay = 1
                }
                connectionState = .reconnecting
            } catch is CancellationError {
                break
            } catch let error as NtfySubscriptionError {
                lastError = error.localizedDescription
                connectionState = .failed(error.localizedDescription)
                if case .unauthorized = error { break }
                if case .forbidden = error { break }
            } catch {
                lastError = error.localizedDescription
                connectionState = .reconnecting
            }

            do {
                try await Task.sleep(for: .seconds(retryDelay))
            } catch {
                break
            }
            retryDelay = min(retryDelay * 2, 30)
        }
    }

    private func subscriptionRequest() async throws -> NtfySubscriptionRequest {
        guard let configuration, let serverURL = configuration.serverURL else {
            throw NtfyURLBuilderError.invalidServerURL
        }

        let serverChanged = lastSubscribedServerURL != configuration.serverURLString
        lastSubscribedServerURL = configuration.serverURLString
        return NtfySubscriptionRequest(
            serverURL: serverURL,
            topics: enabledTopics.map(\.name),
            bearerToken: try await keychainStore.token(),
            sinceMessageID: serverChanged ? nil : latestMessageID
        )
    }

    private var enabledTopics: [TopicSubscription] {
        let descriptor = FetchDescriptor<TopicSubscription>(predicate: #Predicate { $0.isEnabled })
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private var latestMessageID: String? {
        var descriptor = FetchDescriptor<InboxMessage>(sortBy: [SortDescriptor(\InboxMessage.receivedAt, order: .reverse)])
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first?.id
    }

    private func consume(_ event: NtfyEvent) {
        do {
            if event.isDelete {
                try deleteMessages(matching: #Predicate { $0.id == event.id })
                return
            }
            if event.isClear {
                try deleteMessages(matching: #Predicate { $0.topic == event.topic })
                return
            }
            guard event.isMessage, !containsMessage(id: event.id) else { return }

            let message = InboxMessage(
                id: event.id,
                topic: event.topic,
                topicIconIdentifier: iconIdentifier(for: event.topic),
                title: event.title ?? event.topic,
                body: event.message ?? "",
                receivedAt: event.receivedAt,
                priority: event.priority ?? 3,
                tags: event.tags ?? [],
                wasSilenced: isQuiet
            )
            modelContext.insert(message)
            try saveContext()
            inboxRevision += 1

            if NotificationDeliveryPolicy.shouldDeliver(
                isAuthorized: notificationAuthorizationStatus == .authorized,
                isQuiet: message.wasSilenced
            ) {
                Task { [notificationCoordinator] in
                    do {
                        try await notificationCoordinator.deliver(message)
                    } catch {
                        lastError = notificationErrorMessage(for: error, action: "deliver a notification")
                    }
                }
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func containsMessage(id: String) -> Bool {
        let descriptor = FetchDescriptor<InboxMessage>(predicate: #Predicate { $0.id == id })
        return ((try? modelContext.fetchCount(descriptor)) ?? 0) > 0
    }

    private func iconIdentifier(for topic: String) -> String {
        let topicName = topic
        let descriptor = FetchDescriptor<TopicSubscription>(predicate: #Predicate { $0.name == topicName })
        return (try? modelContext.fetch(descriptor).first?.symbolName) ?? TopicIconIdentifier.defaultValue
    }

    private func updateMessageTopicIcons() throws {
        let topics = try modelContext.fetch(FetchDescriptor<TopicSubscription>())
        let iconIdentifiers = Dictionary(uniqueKeysWithValues: topics.map { ($0.name, $0.symbolName) })
        let messages = try modelContext.fetch(FetchDescriptor<InboxMessage>())
        for message in messages {
            if let iconIdentifier = iconIdentifiers[message.topic] {
                message.topicIconIdentifier = iconIdentifier
            }
        }
    }

    private func deleteMessages(matching predicate: Predicate<InboxMessage>) throws {
        let descriptor = FetchDescriptor<InboxMessage>(predicate: predicate)
        let messages = try modelContext.fetch(descriptor)
        let notificationIdentifiers = messages.map(\.id)
        messages.forEach(modelContext.delete)
        try saveContext()
        inboxRevision += 1
        notificationCoordinator.removeNotifications(withIdentifiers: notificationIdentifiers)
    }

    private func seedQuietHoursRulesIfNeeded() throws {
        let existingWeekdays = Set(quietHoursRules.map(\.weekday))
        for weekday in 1...7 where !existingWeekdays.contains(weekday) {
            modelContext.insert(QuietHoursRule(weekday: weekday))
        }
    }

    private func validatedServerURL(from string: String) throws -> URL {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), url.host != nil else {
            throw NtfyURLBuilderError.invalidServerURL
        }
        guard url.scheme?.lowercased() == "https" else {
            throw NtfyURLBuilderError.invalidServerURL
        }
        return url
    }

    private func saveContext() throws {
        try modelContext.save()
    }

    private func notificationErrorMessage(for error: Error, action: String) -> String {
        let error = error as NSError
        if error.domain == UNErrorDomain {
            return "macOS could not \(action) for this build. Check Notifications settings for ntfy-tray."
        }
        return "Could not \(action): \(error.localizedDescription)"
    }
}

enum AppModelError: LocalizedError {
    case notPrepared
    case emptyTopic
    case duplicateTopic

    var errorDescription: String? {
        switch self {
        case .notPrepared:
            "The app is still preparing its data store."
        case .emptyTopic:
            "Enter a topic name."
        case .duplicateTopic:
            "That topic is already subscribed."
        }
    }
}
