//
//  ntfy_trayApp.swift
//  ntfy-tray
//
//  Created by Marc Hilgenberg on 17.09.26.
//

import SwiftData
import SwiftUI

@main
struct NtfyTrayApp: App {
    private let modelContainer: ModelContainer
    @State private var appModel: AppModel

    init() {
        FontAwesomeFontRegistrar.registerFonts()

        let schema = Schema([
            ServerConfiguration.self,
            TopicSubscription.self,
            InboxMessage.self,
            QuietHoursRule.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            modelContainer = container
            _appModel = State(initialValue: AppModel(modelContext: container.mainContext))
        } catch {
            fatalError("Unable to create the ntfy-tray data store: \(error)")
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarMenu()
                .environment(appModel)
        } label: {
            MenuBarStatusLabel()
                .environment(appModel)
        }

        Window("Inbox", id: "inbox") {
            ContentView()
                .environment(appModel)
                .frame(minWidth: 800, minHeight: 520)
        }
        .modelContainer(modelContainer)
        .defaultSize(width: 960, height: 640)

        Window("Welcome to ntfy-tray", id: "onboarding") {
            OnboardingView()
                .environment(appModel)
                .frame(minWidth: 560, minHeight: 440)
        }
        .modelContainer(modelContainer)
        .defaultSize(width: 620, height: 500)

        Window("Settings", id: "settings") {
            SettingsView()
                .environment(appModel)
                .frame(minWidth: 620, minHeight: 520)
        }
        .modelContainer(modelContainer)
        .defaultSize(width: 680, height: 580)
    }
}
