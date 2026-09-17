import Foundation

nonisolated enum NtfyURLBuilderError: LocalizedError, Equatable {
    case invalidServerURL
    case insecureTopics

    var errorDescription: String? {
        switch self {
        case .invalidServerURL:
            "Enter a complete HTTPS server URL."
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
            request.serverURL.scheme?.lowercased() == "https",
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
