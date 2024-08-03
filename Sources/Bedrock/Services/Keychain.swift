import Foundation

private struct KeychainAccounts {
    static let refreshToken = "refresh_token"
    static let accessToken = "access_token"
}

public struct KeychainWrapperError: Error {
    var message: String?
    var type: KeychainErrorType

    enum KeychainErrorType {
        case badData
        case servicesError
        case itemNotFound
        case unableToConvertToString
    }

    init(status: OSStatus, type: KeychainErrorType) {
        self.type = type
        if let errorMessage = SecCopyErrorMessageString(status, nil) {
            message = String(errorMessage)
        } else {
            message = "Status Code: \(status)"
        }
    }

    init(type: KeychainErrorType) {
        self.type = type
    }

    init(message: String, type: KeychainErrorType) {
        self.message = message
        self.type = type
    }
}

public class KeychainService {
    private static func storeGenericPasswordFor(
        account: String,
        service: String,
        password: String
    ) throws {

        if password.isEmpty {
            try deleteGenericPasswordFor(
                account: account,
                service: service)
            return
        }

        guard let passwordData = password.data(using: .utf8) else {
            print("Error converting value to data.")
            throw KeychainWrapperError(type: .badData)
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecValueData as String: passwordData
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        switch status {
        case errSecDuplicateItem:
            try updateGenericPasswordFor(
                account: account,
                service: service,
                password: password)

        case errSecSuccess:
            break
        default:
            throw KeychainWrapperError(status: status, type: .servicesError)
        }
    }

    private static func getGenericPasswordFor(account: String, service: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else {
            throw KeychainWrapperError(type: .itemNotFound)
        }
        guard status == errSecSuccess else {
            throw KeychainWrapperError(status: status, type: .servicesError)
        }

        guard let existingItem = item as? [String: Any],
              let valueData = existingItem[kSecValueData as String] as? Data,
              let value = String(data: valueData, encoding: .utf8)
        else {
            throw KeychainWrapperError(type: .unableToConvertToString)
        }

        return value
    }

    private static func updateGenericPasswordFor(
        account: String,
        service: String,
        password: String
    ) throws {
        guard let passwordData = password.data(using: .utf8) else {
            print("Error converting value to data.")
            return
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: passwordData
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        guard status != errSecItemNotFound else {
            throw KeychainWrapperError(
                message: "Matching Item Not Found",
                type: .itemNotFound)
        }
        guard status == errSecSuccess else {
            throw KeychainWrapperError(status: status, type: .servicesError)
        }
    }

    private static func deleteGenericPasswordFor(account: String, service: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainWrapperError(status: status, type: .servicesError)
        }
    }

    private static func storeRefreshToken(_ refreshToken: String) throws {
        try storeGenericPasswordFor(
            account: KeychainAccounts.refreshToken,
            service: KeychainAccounts.refreshToken,
            password: refreshToken)
    }

    private static func storeAccessToken(_ accessToken: String) throws {
        try storeGenericPasswordFor(
            account: KeychainAccounts.accessToken,
            service: KeychainAccounts.accessToken,
            password: accessToken)
    }

    static func storeTokens(_ accessToken: String, _ refreshToken: String, _ expiration: Date) throws {
        try storeRefreshToken(refreshToken)
        try storeAccessToken(accessToken)
    }

    static func getRefreshToken() throws -> String {
        return try getGenericPasswordFor(
            account: KeychainAccounts.refreshToken,
            service: KeychainAccounts.refreshToken)
    }

    static func getAccessToken() throws -> String {
        return try getGenericPasswordFor(
            account: KeychainAccounts.accessToken,
            service: KeychainAccounts.accessToken)
    }

    static func reset() {
        try? deleteGenericPasswordFor(
            account: KeychainAccounts.refreshToken,
            service: KeychainAccounts.refreshToken)
        try? deleteGenericPasswordFor(
            account: KeychainAccounts.accessToken,
            service: KeychainAccounts.accessToken)
    }
}

