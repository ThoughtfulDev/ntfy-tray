import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var step = OnboardingStep.welcome
    @State private var serverURL = "https://ntfy.sh"
    @State private var bearerToken = ""
    @State private var topicName = ""
    @State private var acknowledgedInsecureTransport = false
    @State private var errorMessage: String?

    private var isHTTPServer: Bool {
        serverURL.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().hasPrefix("http://")
    }

    var body: some View {
        VStack(spacing: 24) {
            TabView(selection: $step) {
                welcomePage.tag(OnboardingStep.welcome)
                serverPage.tag(OnboardingStep.server)
                topicPage.tag(OnboardingStep.topic)
                finishPage.tag(OnboardingStep.finish)
            }
            .tabViewStyle(.automatic)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .padding(32)
    }

    private var welcomePage: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text("Welcome to ntfy-tray")
                .font(.largeTitle)
                .bold()
            Text("Keep your ntfy topics close without keeping another app in the Dock.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Get Started", action: advance)
                .buttonStyle(.borderedProminent)
        }
    }

    private var serverPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose your server")
                .font(.title)
                .bold()
            Text("Use ntfy.sh or enter the URL of your self-hosted server.")
                .foregroundStyle(.secondary)
            TextField("Server URL", text: $serverURL)
                .textContentType(.URL)
            SecureField("Bearer token (optional)", text: $bearerToken)
                .textContentType(.password)
            if isHTTPServer {
                Toggle("I understand HTTP is insecure", isOn: $acknowledgedInsecureTransport)
                Text("Use HTTPS whenever possible. An HTTP server can expose notification data and tokens on the network.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Button("Back", action: retreat)
                Spacer()
                Button("Continue", action: advance)
                    .buttonStyle(.borderedProminent)
                    .disabled(serverURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (isHTTPServer && !acknowledgedInsecureTransport))
            }
        }
    }

    private var topicPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add your first topic")
                .font(.title)
                .bold()
            Text("Topics are the channels you want ntfy-tray to monitor. You can add more later.")
                .foregroundStyle(.secondary)
            TextField("Topic name", text: $topicName)
            HStack {
                Button("Back", action: retreat)
                Spacer()
                Button("Continue", action: advance)
                    .buttonStyle(.borderedProminent)
                    .disabled(topicName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var finishPage: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            Text("You’re ready")
                .font(.title)
                .bold()
            Text("ntfy-tray will ask for notification permission, then start monitoring \(topicName).")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            HStack {
                Button("Back", action: retreat)
                Button("Finish Setup", action: finish)
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private func advance() {
        guard let next = OnboardingStep(rawValue: step.rawValue + 1) else { return }
        step = next
        errorMessage = nil
    }

    private func retreat() {
        guard let previous = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        step = previous
        errorMessage = nil
    }

    private func finish() {
        Task {
            do {
                try await appModel.completeOnboarding(
                    urlString: serverURL,
                    bearerToken: bearerToken,
                    topicName: topicName,
                    acknowledgedInsecureTransport: acknowledgedInsecureTransport
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                step = .server
            }
        }
    }
}
