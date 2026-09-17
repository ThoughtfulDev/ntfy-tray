import SwiftUI

struct MenuBarStatusLabel: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Image(systemName: appModel.statusSymbolName)
            .accessibilityLabel(appModel.statusLabel)
    }
}
