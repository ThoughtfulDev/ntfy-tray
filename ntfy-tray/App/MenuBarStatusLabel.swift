import SwiftUI

struct MenuBarStatusLabel: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Image(nsImage: MenuBarAppIcon.image(isMuted: appModel.isQuiet))
            .accessibilityLabel(appModel.statusLabel)
            .task {
                await appModel.prepare {
                    if appModel.needsOnboarding {
                        openWindow(id: "onboarding")
                    } else {
                        openWindow(id: "inbox")
                    }
                }
            }
    }
}
