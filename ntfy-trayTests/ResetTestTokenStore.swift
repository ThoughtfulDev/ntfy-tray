//
//  ResetTestTokenStore.swift
//  ntfy-trayTests
//

@testable import ntfy_tray

actor ResetTestTokenStore: BearerTokenStoring {
    private var storedToken: String?
    private var deleteCount = 0

    init(token: String? = nil) {
        storedToken = token
    }

    func token() async throws -> String? {
        storedToken
    }

    func save(token: String) async throws {
        storedToken = token
    }

    func deleteToken() async throws {
        storedToken = nil
        deleteCount += 1
    }

    func wasDeleted() -> Bool {
        deleteCount > 0
    }
}
