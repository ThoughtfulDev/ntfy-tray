protocol BearerTokenStoring: Sendable {
    func token() async throws -> String?
    func save(token: String) async throws
    func deleteToken() async throws
}
