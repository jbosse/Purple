//
//  KeychainManager.swift
//  Purple
//
//  Created by Jimmy Bosse on 9/20/25.
//

import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    private let service = "com.purple.otpmanager"

    private init() {}

    // MARK: - Store Secret

    func store(secret: Data, for identifier: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier,
            kSecValueData as String: secret,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete any existing item first
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Retrieve Secret

    func retrieve(for identifier: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            return result as? Data
        }

        return nil
    }

    // MARK: - Delete Secret

    func delete(for identifier: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }

    // MARK: - Update Secret

    func update(secret: Data, for identifier: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier
        ]

        let updateAttributes: [String: Any] = [
            kSecValueData as String: secret
        ]

        let status = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)

        if status == errSecItemNotFound {
            // Item doesn't exist, create it
            return store(secret: secret, for: identifier)
        }

        return status == errSecSuccess
    }

    // MARK: - Check if Secret Exists

    func exists(for identifier: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Store Base32 Secret

    func storeBase32Secret(_ secret: String, for identifier: String) -> Bool {
        guard let secretData = OTPGenerator.decodeBase32Secret(secret) else {
            return false
        }
        return store(secret: secretData, for: identifier)
    }

    // MARK: - Generate Secret Identifier

    static func generateSecretIdentifier() -> String {
        return "otp_secret_\(UUID().uuidString)"
    }
}
