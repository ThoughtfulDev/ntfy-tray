@preconcurrency import UserNotifications
import SwiftUI

struct GeneralSettingsView: View {
    @Environment(AppModel.self) private var appModel
    @State private var serverURL = ""
    @State private var bearerToken = ""
    @State private var launchAtLogin = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Server") {
                TextField("Server URL", text: $serverURL, prompt: Text("https://ntfy.sh"))
                    .textContentType(.URL)
                SecureField("Bearer token (optional)", text: $bearerToken)
                    .textContentType(.password)
                Text("Only HTTPS servers are supported. The optional token is stored securely in your Data Protection Keychain.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button("Save Server", systemImage: "checkmark") {
                    saveServer()
                }
            }

            Section("Notifications") {
                LabeledContent("Permission") {
                    Text(notificationStatusTitle)
                        .foregroundStyle(notificationStatusColor)
                }
                if notificationActionTitle != nil {
                    Button(notificationActionTitle ?? "") {
                        Task {
                            if appModel.notificationAuthorizationStatus == .denied {
                                appModel.openNotificationSettings()
                            } else {
                                await appModel.requestNotificationPermission()
                            }
                        }
                    }
                }
            }

            Section("Startup") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        appModel.setLaunchAtLogin(enabled)
                    }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .task {
            await loadValues()
            await appModel.refreshNotificationAuthorizationStatus()
        }
    }

    private var notificationStatusTitle: String {
        switch appModel.notificationAuthorizationStatus {
        case .authorized: "Allowed"
        case .denied: "Denied"
        case .notDetermined: "Not requested"
        case .provisional: "Provisional"
        case .ephemeral: "Ephemeral"
        @unknown default: "Unknown"
        }
    }

    private var notificationStatusColor: Color {
        appModel.notificationAuthorizationStatus == .authorized ? .green : .secondary
    }

    private var notificationActionTitle: String? {
        switch appModel.notificationAuthorizationStatus {
        case .notDetermined: "Allow Notifications"
        case .denied: "Open Notification Settings"
        default: nil
        }
    }

    private func loadValues() async {
        serverURL = appModel.configuration?.serverURLString ?? "https://ntfy.sh"
        bearerToken = await appModel.storedBearerToken()
        launchAtLogin = LoginItemService().isEnabled
    }

    private func saveServer() {
        Task {
            do {
                try await appModel.saveServer(
                    urlString: serverURL,
                    bearerToken: bearerToken
                )
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
