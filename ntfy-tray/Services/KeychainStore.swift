import Foundation
import Security

enum KeychainStoreError: LocalizedError {
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case let .unexpectedStatus(status):
            "Keychain error \(status)."
        }
    }
}

struct KeychainStore {
    private let service = "com.thoughtful-dev.ntfy-tray"
    private let account = "ntfy-bearer-token"

    func token() throws -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainStoreError.unexpectedStatus(status)
        }
        return String(decoding: data, as: UTF8.self)
    }

    func save(token: String) throws {
        if token.isEmpty {
            try deleteToken()
            return
        }

        let data = Data(token.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
        let attributes: [CFString: Any] = [kSecValueData: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData] = data
            addQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainStoreError.unexpectedStatus(addStatus)
            }
            return
        }

        guard updateStatus == errSecSuccess else {
            throw KeychainStoreError.unexpectedStatus(updateStatus)
        }
    }

    func deleteToken() throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainStoreError.unexpectedStatus(status)
        }
    }
}
