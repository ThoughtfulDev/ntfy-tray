import Foundation

nonisolated enum NtfyURLBuilderError: LocalizedError, Equatable {
    case invalidServerURL
    case insecureTopics

    var errorDescription: String? {
        switch self {
        case .invalidServerURL:
            "Enter a complete HTTP or HTTPS server URL."
        case .insecureTopics:
            "Add at least one valid topic before connecting."
        }
    }
}

nonisolated struct NtfySubscriptionRequest: Sendable {
    let serverURL: URL
    let topics: [String]
    let bearerToken: String?
    let sinceMessageID: String?
}

nonisolated enum NtfyURLBuilder {
    static func subscriptionURL(for request: NtfySubscriptionRequest) throws -> URL {
        guard
            let scheme = request.serverURL.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            request.serverURL.host != nil
        else {
            throw NtfyURLBuilderError.invalidServerURL
        }

        let topics = request.topics.map(normalizeTopic).filter { !$0.isEmpty }
        guard !topics.isEmpty else {
            throw NtfyURLBuilderError.insecureTopics
        }

        var url = request.serverURL
        url.append(path: topics.joined(separator: ","))
        url.append(path: "json")

        if let sinceMessageID = request.sinceMessageID, !sinceMessageID.isEmpty {
            url.append(queryItems: [URLQueryItem(name: "since", value: sinceMessageID)])
        }
        return url
    }

    static func normalizeTopic(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
