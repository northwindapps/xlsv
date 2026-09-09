//
//  AIKeychain.swift
//  XLSV
//
//  Minimal Keychain wrapper for the one secret the LLM feature needs -- the
//  user's OpenAI API key. Deliberately not a general-purpose keychain library
//  (the app has none and doesn't need one): a single service/account pair,
//  string in / string out, no access-group or iCloud-sync options.
//
//  The key is stored with kSecAttrAccessibleAfterFirstUnlock so a background
//  refresh (should one ever be added) can still read it, but never leaves the
//  device except in the Authorization header of a request to api.openai.com.
//

import Foundation
import Security

enum AIKeychain {
    private static let service = "com.xlsv.openai"
    private static let account = "api_key"

    static func setAPIKey(_ key: String?) {
        let trimmed = key?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        // Clear first so a set is always a clean replace, never a duplicate-item error.
        SecItemDelete(baseQuery() as CFDictionary)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else { return }

        var add = baseQuery()
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(add as CFDictionary, nil)
    }

    static func apiKey() -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8),
              !key.isEmpty else { return nil }
        return key
    }

    static var hasAPIKey: Bool { apiKey() != nil }

    private static func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
