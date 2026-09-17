//
//  ntfy_trayTests.swift
//  ntfy-trayTests
//
//  Created by Marc Hilgenberg on 17.09.26.
//

@testable import ntfy_tray
import Foundation
import Testing

struct NtfyTrayTests {
    @Test @MainActor func overnightQuietHoursContinueIntoTheFollowingDay() {
        let sundayRule = QuietHoursRule(weekday: 1, isEnabled: true, startMinutes: 1_320, endMinutes: 360)
        let mondayAtOne = date(year: 2026, month: 9, day: 21, hour: 1, minute: 0)
        let mondayAtSeven = date(year: 2026, month: 9, day: 21, hour: 7, minute: 0)

        let calendar = Calendar(identifier: .gregorian)
        #expect(QuietHoursEvaluator.isQuiet(at: mondayAtOne, rules: [sundayRule], calendar: calendar))
        #expect(!QuietHoursEvaluator.isQuiet(at: mondayAtSeven, rules: [sundayRule], calendar: calendar))
    }

    @Test func subscriptionURLIncludesTopicsAndReplayIdentifier() throws {
        let request = NtfySubscriptionRequest(
            serverURL: try #require(URL(string: "https://ntfy.example")),
            topics: ["alerts", "builds"],
            bearerToken: "token",
            sinceMessageID: "abc123"
        )

        let url = try NtfyURLBuilder.subscriptionURL(for: request)
        #expect(url.path.contains("alerts"))
        #expect(url.path.contains("builds"))
        #expect(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.contains(URLQueryItem(name: "since", value: "abc123")) == true)
    }

    @Test func subscriptionURLRejectsInsecureHTTPServers() throws {
        let request = NtfySubscriptionRequest(
            serverURL: try #require(URL(string: "http://ntfy.example")),
            topics: ["alerts"],
            bearerToken: nil,
            sinceMessageID: nil
        )

        #expect(throws: NtfyURLBuilderError.invalidServerURL) {
            try NtfyURLBuilder.subscriptionURL(for: request)
        }
    }

    @Test func ntfyMessageEventsDecodeTheirMetadata() throws {
        let data = Data("""
        {"id":"a1","time":1780000000,"event":"message","topic":"alerts","message":"Backup failed","title":"Warning","tags":["warning"],"priority":4}
        """.utf8)

        let event = try JSONDecoder().decode(NtfyEvent.self, from: data)
        #expect(event.isMessage)
        #expect(event.id == "a1")
        #expect(event.title == "Warning")
        #expect(event.tags == ["warning"])
        #expect(event.priority == 4)
    }

    @Test func deleteAndClearEventsAreRecognized() throws {
        let deleteJSON = #"{"id":"a1","time":0,"event":"message_delete","topic":"alerts"}"#
        let clearJSON = #"{"id":"a2","time":0,"event":"message_clear","topic":"alerts"}"#
        let delete = try JSONDecoder().decode(NtfyEvent.self, from: Data(deleteJSON.utf8))
        let clear = try JSONDecoder().decode(NtfyEvent.self, from: Data(clearJSON.utf8))

        #expect(delete.isDelete)
        #expect(clear.isClear)
    }

    @Test func notificationDeliveryRespectsAuthorizationAndQuietHours() {
        #expect(NotificationDeliveryPolicy.shouldDeliver(isAuthorized: true, isQuiet: false))
        #expect(!NotificationDeliveryPolicy.shouldDeliver(isAuthorized: false, isQuiet: false))
        #expect(!NotificationDeliveryPolicy.shouldDeliver(isAuthorized: true, isQuiet: true))
    }

    @MainActor
    private func date(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return components.date ?? .distantPast
    }
}
