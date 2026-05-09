import SwiftUI

struct CaptionBoardView: View {
    @Bindable var session: TranslationSessionStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppText.liveCaptions)
                        .font(.title2.weight(.semibold))

                    Text(session.languageSummary)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Label(session.isRunning ? AppText.listening : AppText.idle, systemImage: session.isRunning ? "waveform" : "pause.circle")
                    .foregroundStyle(session.isRunning ? .green : .secondary)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        if session.lines.isEmpty {
                            ContentUnavailableView(
                                AppText.noCaptionsYet,
                                systemImage: "captions.bubble",
                                description: Text(AppText.noCaptionsDescription)
                            )
                            .frame(maxWidth: .infinity, minHeight: 320)
                        }

                        ForEach(session.lines) { line in
                            CaptionLineView(line: line)
                                .id(line.id)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onChange(of: session.lines.last?.id) { _, id in
                    if let id {
                        proxy.scrollTo(id, anchor: .bottom)
                    }
                }
                .onChange(of: session.lines.last?.revision) { _, _ in
                    if let id = session.lines.last?.id {
                        proxy.scrollTo(id, anchor: .bottom)
                    }
                }
            }
        }
        .padding(24)
    }
}

private struct CaptionLineView: View {
    let line: CaptionLine

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            TranscriptPane(title: AppText.original, text: line.sourceText, isPrimary: true)
            TranscriptPane(title: AppText.translation, text: line.translatedText, isPrimary: false)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct TranscriptPane: View {
    let title: String
    let text: String
    let isPrimary: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(text)
                .font(isPrimary ? .body : .body.weight(.medium))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 420, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
