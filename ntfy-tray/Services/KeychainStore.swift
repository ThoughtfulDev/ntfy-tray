import Foundation
import Security

nonisolated enum KeychainStoreError: LocalizedError, Sendable {
    case missingEntitlement
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .missingEntitlement:
            "macOS did not authorize this app to access the Keychain."
        case let .unexpectedStatus(status):
            "Keychain error \(status)."
        }
    }

    static func from(status: OSStatus) -> KeychainStoreError {
        status == errSecMissingEntitlement ? .missingEntitlement : .unexpectedStatus(status)
    }
}

actor KeychainStore {
    private enum Storage {
        case dataProtection
        case fileBased
    }

    private let service = "com.thoughtful-dev.ntfy-tray"
    private let account = "ntfy-bearer-token"

    func token() throws -> String? {
        do {
            if let token = try token(in: .dataProtection) {
                return token
            }
        } catch KeychainStoreError.missingEntitlement {
            // A free Personal Team build can't use the data protection access group.
        }
        return try token(in: .fileBased)
    }

    func save(token: String) throws {
        if token.isEmpty {
            try deleteToken()
            return
        }

        do {
            try save(token: token, in: .dataProtection)
        } catch KeychainStoreError.missingEntitlement {
            try save(token: token, in: .fileBased)
        }
    }

    func deleteToken() throws {
        do {
            try deleteToken(in: .dataProtection)
        } catch KeychainStoreError.missingEntitlement {
            // A free Personal Team build can't use the data protection access group.
        }
        try deleteToken(in: .fileBased)
    }

    private func token(in storage: Storage) throws -> String? {
        var query = baseQuery(for: storage)
        query.merge([
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]) { _, new in new }

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainStoreError.from(status: status)
        }
        return String(decoding: data, as: UTF8.self)
    }

    private func save(token: String, in storage: Storage) throws {
        var addQuery = baseQuery(for: storage)
        addQuery[kSecValueData] = Data(token.utf8)
        if storage == .dataProtection {
            addQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        switch addStatus {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            let updates: [CFString: Any] = [kSecValueData: Data(token.utf8)]
            let updateStatus = SecItemUpdate(baseQuery(for: storage) as CFDictionary, updates as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainStoreError.from(status: updateStatus)
            }
        default:
            throw KeychainStoreError.from(status: addStatus)
        }
    }

    private func deleteToken(in storage: Storage) throws {
        let query = baseQuery(for: storage)
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainStoreError.from(status: status)
        }
    }

    private func baseQuery(for storage: Storage) -> [CFString: Any] {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
        if storage == .dataProtection {
            query[kSecUseDataProtectionKeychain] = true
        }
        return query
    }
}
