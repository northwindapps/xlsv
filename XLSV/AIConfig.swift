//
//  AIConfig.swift
//  XLSV
//
//  Non-secret settings for the "Ask about this sheet" feature. The API key
//  itself lives in AIKeychain; everything here is safe in UserDefaults.
//
//  consentGranted gates the very first network call: spreadsheet cell values
//  leave the device only after the user has explicitly acknowledged that in
//  AIChatViewController's first-use prompt. Resetting it (Settings) forces the
//  prompt again.
//

import Foundation

enum AIConfig {
    private static let d = UserDefaults.standard

    // Endpoint is fixed for now. When a hosted proxy is introduced this is the
    // single value that changes (and the Authorization header is dropped).
    static let chatCompletionsURL = URL(string: "https://api.openai.com/v1/chat/completions")!

    static var model: String {
        get { d.string(forKey: "ai.model") ?? "gpt-4o-mini" }
        set { d.set(newValue, forKey: "ai.model") }
    }

    static var consentGranted: Bool {
        get { d.bool(forKey: "ai.consentGranted") }
        set { d.set(newValue, forKey: "ai.consentGranted") }
    }

    // Hard ceiling on how many populated cells get serialized into one request,
    // so a 1.4M-cell sheet can't produce a multi-million-token body. The builder
    // truncates past this and tells the model (and the user) that it did.
    static var maxCellsPerRequest: Int {
        get {
            let v = d.integer(forKey: "ai.maxCells")
            return v > 0 ? v : 4000
        }
        set { d.set(newValue, forKey: "ai.maxCells") }
    }

    static func localized(_ en: String, ja: String) -> String {
        (Locale.preferredLanguages.first ?? "en").hasPrefix("ja") ? ja : en
    }
}
