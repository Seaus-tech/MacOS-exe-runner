import SwiftUI

struct AIView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("macexe.ai.email") private var savedEmail = ""
    @AppStorage("macexe.ai.approved") private var aiApproved = false

    @Binding var targetFilePath: String
    @Binding var extraArgs: String

    let logOutput: String

    @StateObject private var aiEngine = AIEngine()

    var body: some View {
        VStack(spacing: 18) {
            header

            VStack(alignment: .leading, spacing: 10) {
                Label(executableName, systemImage: "doc.badge.gearshape")
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(targetFilePath.isEmpty ? "Select a Windows executable before running AI analysis." : targetFilePath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))

            if let errorMessage = aiEngine.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            recommendationView

            HStack(spacing: 10) {
                Button("Done") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    applySuggestedArguments()
                } label: {
                    Label("Apply Args", systemImage: "text.badge.checkmark")
                }
                .buttonStyle(.bordered)
                .disabled(aiEngine.recommendation.suggestedArguments.isEmpty)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 8))

                Button {
                    Task { await analyze() }
                } label: {
                    if aiEngine.isAnalyzing {
                        ProgressView().controlSize(.small).frame(width: 86)
                    } else {
                        Label("Analyze", systemImage: "sparkles")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canAnalyze || aiEngine.isAnalyzing)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(24)
        .frame(width: 460)
    }

    private var header: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(Color.accentColor.opacity(0.15)).frame(width: 58, height: 58)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 26))
                    .foregroundStyle(.tint)
            }

            Text("AI Execution Manager")
                .font(.title2.bold())

            Text("Analyze the selected executable and recent Wine output for launch suggestions.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var recommendationView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recommendation", systemImage: "wand.and.stars")
                .font(.headline)

            Text(aiEngine.recommendation.summary)
                .font(.callout)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !aiEngine.recommendation.suggestedArguments.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Suggested arguments")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(aiEngine.recommendation.suggestedArguments)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if !aiEngine.recommendation.notes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(aiEngine.recommendation.notes, id: \.self) { note in
                        Label(note, systemImage: "checkmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
    }

    private var canAnalyze: Bool {
        aiApproved && !savedEmail.isEmpty && !targetFilePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var executableName: String {
        guard !targetFilePath.isEmpty else { return "No executable selected" }
        return URL(fileURLWithPath: targetFilePath).lastPathComponent
    }

    private func analyze() async {
        await aiEngine.analyze(
            email: savedEmail,
            executablePath: targetFilePath,
            currentArguments: extraArgs,
            logOutput: logOutput
        )
    }

    private func applySuggestedArguments() {
        extraArgs = aiEngine.recommendation.suggestedArguments
    }
}

#Preview {
    AIView(
        targetFilePath: .constant("/Users/example/Downloads/setup.exe"),
        extraArgs: .constant(""),
        logOutput: ""
    )
}
