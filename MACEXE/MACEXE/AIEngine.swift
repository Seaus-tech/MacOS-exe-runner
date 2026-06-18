import Foundation
import Combine

struct AIAnalysisRequest: Encodable {
    let email: String
    let executablePath: String
    let executableName: String
    let currentArguments: String
    let recentLogOutput: String
}

struct AIRecommendation: Decodable, Equatable {
    let summary: String
    let suggestedArguments: String
    let confidence: String
    let notes: [String]

    static let empty = AIRecommendation(
        summary: "No recommendation yet.",
        suggestedArguments: "",
        confidence: "unknown",
        notes: []
    )
}

@MainActor
final class AIEngine: ObservableObject {
    @Published private(set) var isAnalyzing = false
    @Published private(set) var recommendation: AIRecommendation = .empty
    @Published var errorMessage: String?

    private let serviceURL = URL(string: "https://macexe.yash-behera.workers.dev")!

    func analyze(email: String, executablePath: String, currentArguments: String, logOutput: String) async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPath = executablePath.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedPath.isEmpty else {
            errorMessage = "Select an executable before asking AI."
            return
        }

        isAnalyzing = true
        errorMessage = nil

        do {
            let requestBody = AIAnalysisRequest(
                email: trimmedEmail,
                executablePath: trimmedPath,
                executableName: URL(fileURLWithPath: trimmedPath).lastPathComponent,
                currentArguments: currentArguments,
                recentLogOutput: String(logOutput.suffix(6000))
            )

            var request = URLRequest(url: serviceURL.appending(path: "ai/analyze"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(requestBody)

            let (data, response) = try await URLSession.shared.data(for: request)
            try validate(response: response)

            recommendation = try JSONDecoder().decode(AIRecommendation.self, from: data)
        } catch {
            errorMessage = "AI analysis is not available yet. Check the Cloudflare /ai/analyze route."
        }

        isAnalyzing = false
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
