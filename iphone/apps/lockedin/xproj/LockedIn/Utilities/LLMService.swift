import Foundation

final class LLMService {
    static let shared = LLMService()

    private let session = URLSession.shared

    private func resolveAPIKey() -> String? {
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
           !plistKey.isEmpty, !plistKey.contains("$(") {
            return plistKey
        }
        var dir = Bundle.main.bundleURL.deletingLastPathComponent()
        for _ in 0..<10 {
            let envFile = dir.appendingPathComponent(".env")
            if let contents = try? String(contentsOf: envFile, encoding: .utf8) {
                for line in contents.components(separatedBy: .newlines) {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard trimmed.hasPrefix("OPENAI_API_KEY"), let eqIdx = trimmed.firstIndex(of: "=") else { continue }
                    var val = String(trimmed[trimmed.index(after: eqIdx)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if (val.hasPrefix("\"") && val.hasSuffix("\"")) || (val.hasPrefix("'") && val.hasSuffix("'")) {
                        val = String(val.dropFirst().dropLast())
                    }
                    if !val.isEmpty { return val }
                }
            }
            let parent = dir.deletingLastPathComponent()
            if parent.path == dir.path { break }
            dir = parent
        }
        if let udKey = UserDefaults.standard.string(forKey: "openai_api_key"), !udKey.isEmpty {
            return udKey
        }
        return nil
    }

    var isAvailable: Bool { resolveAPIKey() != nil }

    func generateReply(
        participantName: String,
        participantHeadline: String,
        currentUserName: String,
        currentUserHeadline: String,
        conversationHistory: [(role: String, content: String)],
        userMessage: String,
        completion: @escaping (String?) -> Void
    ) {
        guard let apiKey = resolveAPIKey() else {
            completion(nil)
            return
        }

        let systemPrompt = """
        You are \(participantName), a professional on LockedIn. \
        Your headline is: \(participantHeadline). \
        You are having a LockedIn message conversation with \(currentUserName) (\(currentUserHeadline)). \
        Reply as \(participantName) in 1-3 short, professional but friendly sentences. \
        Be natural and conversational, like a real LockedIn message. \
        Stay in character as a real person. \
        Do not use emojis excessively. Do not mention AI or being an assistant. \
        Do not use hashtags. Keep it concise like a real chat message.
        """

        var transcript = conversationHistory.suffix(10).map { entry in
            let name = entry.role == "participant" ? participantName : currentUserName
            return "\(name): \(entry.content)"
        }.joined(separator: "\n")
        if !transcript.isEmpty { transcript += "\n" }
        transcript += "\(currentUserName): \(userMessage)"

        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": "Here is the conversation so far:\n\(transcript)\n\nReply as \(participantName):"]
        ]

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "temperature": 0.8,
            "max_tokens": 200
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body),
              let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        request.timeoutInterval = 15

        session.dataTask(with: request) { data, _, error in
            guard error == nil, let data = data,
                  let raw = try? JSONSerialization.jsonObject(with: data),
                  let json = raw as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let first = choices.first,
                  let message = first["message"] as? [String: Any],
                  let text = message["content"] as? String else {
                completion(nil)
                return
            }
            completion(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }.resume()
    }
}
