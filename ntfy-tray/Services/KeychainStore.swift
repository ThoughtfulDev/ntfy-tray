import Foundation
import Security

nonisolated enum KeychainStoreError: LocalizedError, Sendable {
    case missingEntitlement
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .missingEntitlement:
            "This build is not signed with a macOS development identity, so it cannot access the Keychain. Choose a signing team in Xcode, then build and run the app again."
        case let .unexpectedStatus(status):
            "Keychain error \(status)."
        }
    }

    static func from(status: OSStatus) -> KeychainStoreError {
        status == errSecMissingEntitlement ? .missingEntitlement : .unexpectedStatus(status)
    }
}

actor KeychainStore {
    private let service = "com.thoughtful-dev.ntfy-tray"
    private let account = "ntfy-bearer-token"

    func token() throws -> String? {
        var query = baseQuery
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

    func save(token: String) throws {
        if token.isEmpty {
            try deleteToken()
            return
        }

        var addQuery = baseQuery
        addQuery[kSecValueData] = Data(token.utf8)
        addQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        switch addStatus {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            let updates: [CFString: Any] = [kSecValueData: Data(token.utf8)]
            let updateStatus = SecItemUpdate(baseQuery as CFDictionary, updates as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainStoreError.from(status: updateStatus)
            }
        default:
            throw KeychainStoreError.from(status: addStatus)
        }
    }

    func deleteToken() throws {
        let query = baseQuery

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainStoreError.from(status: status)
        }
    }

    private var baseQuery: [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecUseDataProtectionKeychain: true,
        ]
    }
}
