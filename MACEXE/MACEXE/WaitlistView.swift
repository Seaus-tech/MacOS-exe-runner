import SwiftUI

struct WaitlistView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var submitted = false
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle().fill(Color.accentColor.opacity(0.15)).frame(width: 64, height: 64)
                Image(systemName: "brain.head.profile").font(.system(size: 28)).foregroundStyle(.tint)
            }

            VStack(spacing: 8) {
                Text("AI Execution Manager").font(.title2.bold())
                Text("An AI that understands your Windows apps — launches the right exe, passes the right flags, and manages your Wine prefix automatically.")
                    .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }

            if submitted {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").font(.title).foregroundStyle(.green)
                    Text("You're on the list!").font(.headline)
                    Text("We'll email you when it's ready.").foregroundStyle(.secondary)
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
                        joinWaitlist()
                    } label: {
                        if loading {
                            ProgressView().controlSize(.small).frame(maxWidth: .infinity)
                        } else {
                            Text("Join Waitlist").frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(email.isEmpty || loading)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10))
                }
            }

            Button("Maybe later") { dismiss() }
                .buttonStyle(.plain).foregroundStyle(.secondary).font(.caption)
        }
        .padding(28)
        .frame(width: 360)
    }

    func joinWaitlist() {
        guard email.contains("@") else { error = "Enter a valid email"; return }
        loading = true; error = nil

        // Store locally + optionally POST to an endpoint
        var list = (UserDefaults.standard.stringArray(forKey: "macexe.waitlist") ?? [])
        if !list.contains(email) { list.append(email) }
        UserDefaults.standard.set(list, forKey: "macexe.waitlist")

        // Fire-and-forget to a collect endpoint (swap URL when ready)
        if let url = URL(string: "https://macexe.yash-behera.workers.dev/waitlist") {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try? JSONEncoder().encode(["email": email, "product": "macexe-ai"])
            URLSession.shared.dataTask(with: req).resume()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            loading = false; submitted = true
        }
    }
}

#Preview { WaitlistView() }
