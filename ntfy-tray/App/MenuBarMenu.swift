import AppKit
import SwiftUI

struct MenuBarMenu: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            Text(appModel.statusLabel)
            Divider()
            Button("Open Inbox", systemImage: "tray.full") {
                openWindow(id: "inbox")
            }
            Button(
                appModel.configuration?.isManualDoNotDisturbEnabled == true ? "Turn Off Do Not Disturb" : "Turn On Do Not Disturb",
                systemImage: appModel.configuration?.isManualDoNotDisturbEnabled == true ? "moon.zzz.fill" : "moon"
            ) {
                appModel.setManualDoNotDisturb(appModel.configuration?.isManualDoNotDisturbEnabled != true)
            }
            Divider()
            Button("Settings", systemImage: "gear") {
                openWindow(id: "settings")
            }
            if let lastError = appModel.lastError {
                Divider()
                Text(lastError)
                    .foregroundStyle(.secondary)
            }
            Divider()
            Button("Quit ntfy-tray", systemImage: "power") {
                NSApp.terminate(nil)
            }
        }
    }
}
