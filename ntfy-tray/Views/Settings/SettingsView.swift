import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            TopicsSettingsView()
                .tabItem {
                    Label("Topics", systemImage: "bell")
                }
            QuietHoursSettingsView()
                .tabItem {
                    Label("Quiet Hours", systemImage: "moon.zzz")
                }
        }
        .padding(20)
    }
}
