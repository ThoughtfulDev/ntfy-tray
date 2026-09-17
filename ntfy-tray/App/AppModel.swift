import AppKit
import Foundation
import Observation
import SwiftData
@preconcurrency import UserNotifications

@MainActor
@Observable
final class AppModel {
    private let modelContext: ModelContext
    private let keychainStore = KeychainStore()
    private let subscriptionClient = NtfySubscriptionClient()
    private let notificationCoordinator = NotificationCoordinator()
    private var subscriptionTask: Task<Void, Never>?
    private var lastSubscribedServerURL: String?
    private var inboxRevision = 0
    private var quietHoursRevision = 0

    private(set) var configuration: ServerConfiguration?
    private(set) var connectionState: ConnectionState = .idle
    private(set) var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var lastError: String?
    private(set) var isPrepared = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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
            _ = try await notificationCoordinator.requestAuthorization()
        } catch {
            lastError = "Could not request notifications: \(error.localizedDescription)"
        }
        await refreshNotificationAuthorizationStatus()
    }

    func refreshNotificationAuthorizationStatus() async {
        notificationAuthorizationStatus = await notificationCoordinator.authorizationStatus()
    }

    func openNotificationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") else { return }
        NSWorkspace.shared.open(url)
    }

    func saveServer(urlString: String, bearerToken: String, acknowledgedInsecureTransport: Bool) throws {
        let normalizedURL = try validatedServerURL(from: urlString)
        guard normalizedURL.scheme?.lowercased() != "http" || acknowledgedInsecureTransport else {
            throw AppModelError.insecureTransportNeedsAcknowledgement
        }
        guard let configuration else { throw AppModelError.notPrepared }

        try keychainStore.save(token: bearerToken.trimmingCharacters(in: .whitespacesAndNewlines))
        configuration.serverURLString = normalizedURL.absoluteString
        try saveContext()
        lastError = nil
        restartSubscriptionIfPossible()
    }

    func storedBearerToken() -> String {
        do {
            return try keychainStore.token() ?? ""
        } catch {
            lastError = error.localizedDescription
            return ""
        }
    }

    func completeOnboarding(
        urlString: String,
        bearerToken: String,
        topicName: String,
        acknowledgedInsecureTransport: Bool
    ) async throws {
        try saveServer(
            urlString: urlString,
            bearerToken: bearerToken,
            acknowledgedInsecureTransport: acknowledgedInsecureTransport
        )

        if !NtfyURLBuilder.normalizeTopic(topicName).isEmpty {
            try addTopic(named: topicName, symbolName: "bell.fill")
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

    func saveTopicChanges() {
        do {
            try saveContext()
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

    private func restartSubscriptionIfPossible() {
        subscriptionTask?.cancel()
        connectionState = .idle

        guard isPrepared, !needsOnboarding, !enabledTopics.isEmpty else { return }
        subscriptionTask = Task { [weak self] in
            await self?.runSubscription()
        }
    }

    private func runSubscription() async {
        var retryDelay = 1
        while !Task.isCancelled {
            do {
                let request = try subscriptionRequest()
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

    private func subscriptionRequest() throws -> NtfySubscriptionRequest {
        guard let configuration, let serverURL = configuration.serverURL else {
            throw NtfyURLBuilderError.invalidServerURL
        }

        let serverChanged = lastSubscribedServerURL != configuration.serverURLString
        lastSubscribedServerURL = configuration.serverURLString
        return NtfySubscriptionRequest(
            serverURL: serverURL,
            topics: enabledTopics.map(\.name),
            bearerToken: try keychainStore.token(),
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

            if !message.wasSilenced, notificationAuthorizationStatus == .authorized {
                Task { [notificationCoordinator] in
                    do {
                        try await notificationCoordinator.deliver(message)
                    } catch {
                        lastError = "Could not deliver a notification: \(error.localizedDescription)"
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

    private func deleteMessages(matching predicate: Predicate<InboxMessage>) throws {
        let descriptor = FetchDescriptor<InboxMessage>(predicate: predicate)
        try modelContext.fetch(descriptor).forEach(modelContext.delete)
        try saveContext()
        inboxRevision += 1
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
        guard ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
            throw NtfyURLBuilderError.invalidServerURL
        }
        return url
    }

    private func saveContext() throws {
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }
}

enum AppModelError: LocalizedError {
    case notPrepared
    case insecureTransportNeedsAcknowledgement
    case emptyTopic
    case duplicateTopic

    var errorDescription: String? {
        switch self {
        case .notPrepared:
            "The app is still preparing its data store."
        case .insecureTransportNeedsAcknowledgement:
            "Confirm that you understand an HTTP server is insecure before continuing."
        case .emptyTopic:
            "Enter a topic name."
        case .duplicateTopic:
            "That topic is already subscribed."
        }
    }
}
