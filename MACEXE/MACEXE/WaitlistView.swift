import SwiftUI
import Foundation

struct WaitlistView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("macexe.ai.email") private var savedEmail = ""
    @AppStorage("macexe.ai.approved") private var aiApproved = false

    @State private var email = ""
    @State private var submitted = false
    @State private var loading = false
    @State private var error: String?
    @State private var statusMessage = ""

    private let serviceURL = URL(string: "https://macexe.yash-behera.workers.dev")!

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: statusIcon)
                    .font(.system(size: 28))
                    .foregroundStyle(statusColor)
            }

            VStack(spacing: 8) {
                Text("AI Execution Manager").font(.title2.bold())
                Text("An AI that understands your Windows apps, launches the right exe, passes the right flags, and manages your Wine prefix automatically.")
                    .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }

            if aiApproved {
                VStack(spacing: 8) {
                    Text("Approved").font(.headline)
                    Text("AI access is enabled for \(savedEmail).")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 8)
            } else if submitted {
                VStack(spacing: 10) {
                    Text("Pending approval").font(.headline)
                    Text(statusMessage.isEmpty ? "Your request is waiting for approval." : statusMessage)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        Task { await checkApprovalStatus() }
                    } label: {
                        if loading {
                            ProgressView().controlSize(.small).frame(maxWidth: .infinity)
                        } else {
                            Text("Check Status").frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(loading)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10))
                }
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    TextField("your@email.com", text: $email)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12).padding(.vertical, 9)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10))

                    if let error {
                        Text(error).font(.caption).foregroundStyle(.red)
                    }

                    Button {
                        Task { await joinWaitlist() }
                    } label: {
                        if loading {
                            ProgressView().controlSize(.small).frame(maxWidth: .infinity)
                        } else {
                            Text("Request Access").frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(normalizedEmail.isEmpty || loading)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10))
                }
            }

            Button(aiApproved ? "Done" : "Maybe later") { dismiss() }
                .buttonStyle(.plain).foregroundStyle(.secondary).font(.caption)
        }
        .padding(28)
        .frame(width: 360)
        .onAppear {
            email = savedEmail
            submitted = !savedEmail.isEmpty
            if !savedEmail.isEmpty && !aiApproved {
                Task { await checkApprovalStatus() }
            }
        }
    }

    private var normalizedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var statusIcon: String {
        if aiApproved { return "checkmark.circle.fill" }
        if submitted { return "clock.fill" }
        return "brain.head.profile"
    }

    private var statusColor: Color {
        if aiApproved { return .green }
        if submitted { return .orange }
        return .accentColor
    }

    @MainActor
    private func joinWaitlist() async {
        let email = normalizedEmail
        guard email.contains("@"), email.contains(".") else {
            error = "Enter a valid email"
            return
        }

        loading = true
        error = nil

        do {
            var request = URLRequest(url: serviceURL.appending(path: "waitlist"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(WaitlistRequest(email: email, product: "macexe-ai"))

            let (data, response) = try await URLSession.shared.data(for: request)
            try validate(response: response)

            let joinResponse = try? JSONDecoder().decode(ApprovalStatusResponse.self, from: data)
            savedEmail = email
            aiApproved = joinResponse?.approved ?? false
            submitted = true
            statusMessage = joinResponse?.message ?? defaultStatusMessage
        } catch {
            self.error = "Could not request access. Try again later."
        }

        loading = false
    }

    @MainActor
    private func checkApprovalStatus() async {
        let emailToCheck = savedEmail.isEmpty ? normalizedEmail : savedEmail
        guard !emailToCheck.isEmpty else { return }

        loading = true
        error = nil

        do {
            var components = URLComponents(url: serviceURL.appending(path: "ai/status"), resolvingAgainstBaseURL: false)
            components?.queryItems = [URLQueryItem(name: "email", value: emailToCheck)]
            guard let url = components?.url else { throw URLError(.badURL) }

            let (data, response) = try await URLSession.shared.data(from: url)
            try validate(response: response)

            let status = try JSONDecoder().decode(ApprovalStatusResponse.self, from: data)
            savedEmail = status.email ?? emailToCheck
            aiApproved = status.approved
            submitted = true
            statusMessage = status.message ?? (status.approved ? "AI access is enabled." : defaultStatusMessage)
        } catch {
            statusMessage = "Could not check approval status. Try again later."
        }

        loading = false
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    private var defaultStatusMessage: String {
        "Your request is waiting for approval."
    }
}

private struct WaitlistRequest: Encodable {
    let email: String
    let product: String
}

private struct ApprovalStatusResponse: Decodable {
    let email: String?
    let approved: Bool
    let message: String?
}

#Preview { WaitlistView() }
