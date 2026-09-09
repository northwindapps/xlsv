//
//  OpenAIClient.swift
//  XLSV
//
//  Thin URLSession wrapper around OpenAI's Chat Completions endpoint.
//  Completion-handler based (not async/await) because the app's deployment
//  target is iOS 12; Swift concurrency only back-deploys to iOS 13.
//
//  Uses JSONSerialization rather than Codable to match the rest of the
//  codebase (ReadWriteJSON etc.). No streaming yet -- one request, one
//  response string.
//

import Foundation

final class OpenAIClient {

    struct Message {
        let role: String   // "system" | "user" | "assistant"
        let content: String
    }

    enum AIError: LocalizedError {
        case noAPIKey
        case transport(Error)
        case http(status: Int, message: String)
        case emptyResponse
        case cancelled

        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return AIConfig.localized("No API key set. Add one in Settings.",
                                          ja: "APIキーが未設定です。設定画面で入力してください。")
            case .transport(let e):
                return AIConfig.localized("Network error: \(e.localizedDescription)",
                                          ja: "通信エラー: \(e.localizedDescription)")
            case .http(let status, let message):
                let detail = message.isEmpty ? "" : "\n\(message)"
                return AIConfig.localized("OpenAI error (\(status)).\(detail)",
                                          ja: "OpenAIエラー (\(status))。\(detail)")
            case .emptyResponse:
                return AIConfig.localized("The model returned no answer.",
                                          ja: "モデルから応答がありませんでした。")
            case .cancelled:
                return AIConfig.localized("Cancelled.", ja: "キャンセルされました。")
            }
        }
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Sends `messages` and calls `completion` on the main thread with the
    /// assistant's reply text or an AIError. The returned task can be cancelled.
    @discardableResult
    func send(messages: [Message],
             model: String = AIConfig.model,
             completion: @escaping (Result<String, AIError>) -> Void) -> URLSessionDataTask? {

        guard let apiKey = AIKeychain.apiKey() else {
            DispatchQueue.main.async { completion(.failure(.noAPIKey)) }
            return nil
        }

        var request = URLRequest(url: AIConfig.chatCompletionsURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": model,
            "temperature": 0.2,
            "messages": messages.map { ["role": $0.role, "content": $0.content] }
        ]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            DispatchQueue.main.async { completion(.failure(.transport(error))) }
            return nil
        }

        let task = session.dataTask(with: request) { data, response, error in
            let finish: (Result<String, AIError>) -> Void = { result in
                DispatchQueue.main.async { completion(result) }
            }

            if let error = error {
                let ns = error as NSError
                if ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled {
                    finish(.failure(.cancelled))
                } else {
                    finish(.failure(.transport(error)))
                }
                return
            }

            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let json = data.flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any]

            guard (200..<300).contains(status) else {
                let apiMessage = ((json?["error"] as? [String: Any])?["message"] as? String) ?? ""
                finish(.failure(.http(status: status, message: apiMessage)))
                return
            }

            guard
                let choices = json?["choices"] as? [[String: Any]],
                let message = choices.first?["message"] as? [String: Any],
                let text = message["content"] as? String,
                !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else {
                finish(.failure(.emptyResponse))
                return
            }

            finish(.success(text))
        }
        task.resume()
        return task
    }
}
