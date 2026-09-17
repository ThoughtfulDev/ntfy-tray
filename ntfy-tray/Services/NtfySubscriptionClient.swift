import Foundation

nonisolated enum NtfySubscriptionError: LocalizedError, Sendable {
    case invalidResponse
    case unauthorized
    case forbidden
    case server(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "The server returned an invalid response."
        case .unauthorized:
            "The server rejected the bearer token."
        case .forbidden:
            "The configured token cannot read these topics."
        case let .server(status):
            "The server returned HTTP \(status)."
        }
    }
}

actor NtfySubscriptionClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func events(for request: NtfySubscriptionRequest) throws -> AsyncThrowingStream<NtfyEvent, Error> {
        let url = try NtfyURLBuilder.subscriptionURL(for: request)
        var urlRequest = URLRequest(url: url)
        urlRequest.timeoutInterval = 90
        urlRequest.setValue("application/x-ndjson", forHTTPHeaderField: "Accept")
        if let bearerToken = request.bearerToken, !bearerToken.isEmpty {
            urlRequest.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let (bytes, response) = try await self.session.bytes(for: urlRequest)
                    guard let response = response as? HTTPURLResponse else {
                        throw NtfySubscriptionError.invalidResponse
                    }
                    switch response.statusCode {
                    case 200:
                        break
                    case 401:
                        throw NtfySubscriptionError.unauthorized
                    case 403:
                        throw NtfySubscriptionError.forbidden
                    default:
                        throw NtfySubscriptionError.server(response.statusCode)
                    }

                    let decoder = JSONDecoder()
                    for try await line in bytes.lines where !line.isEmpty {
                        guard let data = line.data(using: .utf8) else { continue }
                        continuation.yield(try decoder.decode(NtfyEvent.self, from: data))
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable _ in task.cancel() }
        }
    }
}
