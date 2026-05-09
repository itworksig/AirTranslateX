import AppKit
import SwiftUI

struct CaptionBoardView: View {
    @Bindable var session: TranslationSessionStore
    @State private var isFloatingCaptionVisible = FloatingCaptionWindowController.isOpen
    @State private var isStopConfirmationPresented = false
    @State private var transcriptSessionIDPendingDeletion: UUID?
    @State private var isClearTranscriptSessionsConfirmationPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SessionOverviewCard(
                title: AppText.transcriptWorkspace,
                subtitle: session.languageSummary,
                isRunning: session.isRunning,
                isPaused: session.isPaused,
                isFloatingCaptionVisible: isFloatingCaptionVisible,
                toggleCapture: {
                    requestCaptureToggle()
                },
                togglePause: {
                    togglePause()
                },
                showFloatingCaptions: {
                    toggleFloatingCaptions()
                }
            )

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        if !session.hasTranscriptSessionContent && !session.isRunning {
                            ContentUnavailableView(
                                AppText.noCaptionsYet,
                                systemImage: "captions.bubble",
                                description: Text(AppText.noCaptionsDescription)
                            )
                            .frame(maxWidth: .infinity, minHeight: 320)
                            .padding(24)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.08))
                            }
                        }

                        if !session.transcriptSessions.isEmpty {
                            PreviousSessionsHeader(
                                sessionCount: session.transcriptSessions.count,
                                clearAll: {
                                    isClearTranscriptSessionsConfirmationPresented = true
                                }
                            )

                            ForEach(session.transcriptSessions) { transcriptSession in
                                TranscriptSessionSection(
                                    title: AppText.previousSession,
                                    subtitle: transcriptSession.languageSummary,
                                    startedAt: transcriptSession.startedAt,
                                    lines: transcriptSession.lines,
                                    isExpanded: transcriptSession.isExpanded,
                                    canToggle: true,
                                    emptyMessage: AppText.noCaptionsYet,
                                    delete: {
                                        transcriptSessionIDPendingDeletion = transcriptSession.id
                                    },
                                    toggle: {
                                        session.toggleTranscriptSession(transcriptSession.id)
                                    }
                                )
                                .id(transcriptSession.id)
                            }
                        }

                        if session.shouldShowCurrentTranscriptSession {
                            TranscriptSessionSection(
                                title: AppText.currentSession,
                                subtitle: session.languageSummary,
                                startedAt: session.currentTranscriptSessionDate,
                                lines: session.lines,
                                isExpanded: true,
                                canToggle: false,
                                emptyMessage: AppText.waitingForSessionTranscript,
                                delete: nil,
                                toggle: {}
                            )
                        }
                    }
                    .padding(.vertical, 4)
                    .animation(.spring(response: 0.32, dampingFraction: 0.86), value: session.lines.count)
                    .animation(.spring(response: 0.32, dampingFraction: 0.86), value: session.transcriptSessions)
                }
                .onChange(of: session.lines.last?.id) { _, id in
                    if let id {
                        withAnimation(.easeOut(duration: 0.22)) {
                            proxy.scrollTo(id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: session.lines.last?.revision) { _, _ in
                    if let id = session.lines.last?.id {
                        withAnimation(.easeOut(duration: 0.22)) {
                            proxy.scrollTo(id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .padding(24)
        .onAppear {
            syncFloatingCaptionVisibility()
        }
        .onReceive(NotificationCenter.default.publisher(for: FloatingCaptionWindowController.visibilityDidChangeNotification)) { _ in
            syncFloatingCaptionVisibility()
        }
        .alert(AppText.stopCaptureConfirmationTitle, isPresented: $isStopConfirmationPresented) {
            Button(AppText.cancel, role: .cancel) {}
            Button(AppText.stop, role: .destructive) {
                session.stop()
            }
        } message: {
            Text(AppText.stopCaptureConfirmationMessage)
        }
        .alert(
            AppText.deleteTranscriptSessionConfirmationTitle,
            isPresented: Binding(
                get: { transcriptSessionIDPendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        transcriptSessionIDPendingDeletion = nil
                    }
                }
            )
        ) {
            Button(AppText.cancel, role: .cancel) {}
            Button(AppText.delete, role: .destructive) {
                if let id = transcriptSessionIDPendingDeletion {
                    session.deleteTranscriptSession(id)
                }
                transcriptSessionIDPendingDeletion = nil
            }
        } message: {
            Text(AppText.deleteTranscriptSessionConfirmationMessage)
        }
        .alert(AppText.deleteAllTranscriptSessionsConfirmationTitle, isPresented: $isClearTranscriptSessionsConfirmationPresented) {
            Button(AppText.cancel, role: .cancel) {}
            Button(AppText.deleteAllTranscriptSessions, role: .destructive) {
                session.deleteAllTranscriptSessions()
            }
        } message: {
            Text(AppText.deleteAllTranscriptSessionsConfirmationMessage)
        }
    }

    private func toggleFloatingCaptions() {
        FloatingCaptionWindowController.toggle(session: session)
        syncFloatingCaptionVisibility()
    }

    private func requestCaptureToggle() {
        if session.isRunning {
            isStopConfirmationPresented = true
        } else {
            session.start()
        }
    }

    private func togglePause() {
        session.isPaused ? session.resume() : session.pause()
    }

    private func syncFloatingCaptionVisibility() {
        isFloatingCaptionVisible = FloatingCaptionWindowController.isOpen
    }
}

private struct PreviousSessionsHeader: View {
    let sessionCount: Int
    let clearAll: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(AppText.previousSessions)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(AppText.previousSessionCount(sessionCount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Button(role: .destructive, action: clearAll) {
                Label(AppText.deleteAllTranscriptSessions, systemImage: "trash")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .help(AppText.deleteAllTranscriptSessions)
            .accessibilityLabel(AppText.deleteAllTranscriptSessions)
        }
        .padding(.horizontal, 2)
        .padding(.top, 2)
    }
}

private struct CaptionLineView: View {
    let line: CaptionLine

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            TranscriptPane(
                title: AppText.original,
                description: AppText.originalDescription,
                text: line.sourceText,
                isPrimary: true
            )
            TranscriptPane(
                title: AppText.translation,
                description: AppText.translationDescription,
                text: line.translatedText,
                isPrimary: false
            )
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct TranscriptSessionSection: View {
    let title: String
    let subtitle: String
    let startedAt: Date
    let lines: [CaptionLine]
    let isExpanded: Bool
    let canToggle: Bool
    let emptyMessage: String
    let delete: (() -> Void)?
    let toggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                if canToggle {
                    Button(action: toggle) {
                        headerContent
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(title)
                } else {
                    headerContent
                }

                if let delete {
                    Button(role: .destructive, action: delete) {
                        Label(AppText.delete, systemImage: "trash")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .help(AppText.deleteTranscriptSession)
                    .accessibilityLabel(AppText.deleteTranscriptSession)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06))
            }

            if isExpanded {
                if lines.isEmpty {
                    Text(emptyMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 96)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.08))
                        }
                } else {
                    ForEach(lines) { line in
                        CaptionLineView(line: line)
                            .id(line.id)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
    }

    private var headerContent: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(canToggle ? .secondary : .tertiary)
                .frame(width: 14)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(AppText.lineCount(lines.count))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(startedAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

private struct TranscriptPane: View {
    let title: String
    let description: String
    let text: String
    let isPrimary: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 8)

                Button {
                    copyText()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                .help(AppText.copyTranscriptPane(title))
                .accessibilityLabel(AppText.copyTranscriptPane(title))
                .disabled(!canCopy)
            }

            Text(description)
                .font(.caption)
                .foregroundStyle(.tertiary)

            StreamingTranscriptText(
                text: text,
                font: isPrimary ? .body : .body.weight(.medium)
            )
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 360, alignment: .topLeading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08))
        }
    }

    private var canCopy: Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedText.isEmpty && trimmedText != AppText.translating
    }

    private func copyText() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, trimmedText != AppText.translating else { return }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(trimmedText, forType: .string)
    }
}

private struct SessionOverviewCard: View {
    let title: String
    let subtitle: String
    let isRunning: Bool
    let isPaused: Bool
    let isFloatingCaptionVisible: Bool
    let toggleCapture: () -> Void
    let togglePause: () -> Void
    let showFloatingCaptions: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "captions.bubble.fill")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 34, height: 34)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .lineLimit(1)

                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                SessionStatusBadge(isRunning: isRunning, isPaused: isPaused)

                Button(action: toggleCapture) {
                    HeaderCaptureTransportButton(isRunning: isRunning, isPaused: isPaused)
                }
                .buttonStyle(.plain)
                .help(isRunning ? AppText.stop : AppText.start)
                .accessibilityLabel(isRunning ? AppText.stop : AppText.start)

                if isRunning {
                    Button(action: togglePause) {
                        HeaderPauseTransportButton(isPaused: isPaused)
                    }
                    .buttonStyle(.plain)
                    .help(isPaused ? AppText.resume : AppText.pause)
                    .accessibilityLabel(isPaused ? AppText.resume : AppText.pause)
                }

                Button(action: showFloatingCaptions) {
                    HeaderFloatingCaptionToggleButton(isOn: isFloatingCaptionVisible)
                }
                .buttonStyle(.plain)
                .help(AppText.showFloatingCaptions)
                .accessibilityLabel(AppText.showFloatingCaptions)
                .accessibilityValue(isFloatingCaptionVisible ? AppText.floatingCaptionPowerOn : AppText.floatingCaptionPowerOff)
            }
            .padding(6)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
            }
            .layoutPriority(2)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        }
    }
}

private struct HeaderCaptureTransportButton: View {
    let isRunning: Bool
    let isPaused: Bool

    private var accentColor: Color {
        if isPaused {
            return .orange
        }
        if isRunning {
            return .red
        }
        return .accentColor
    }

    private var systemImage: String {
        isRunning ? "stop.fill" : "play.fill"
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(accentColor.opacity(isRunning ? 0.18 : 0.14))

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(accentColor.opacity(isRunning ? 0.5 : 0.32), lineWidth: 1)

            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(accentColor)
                .offset(x: isRunning ? 0 : 1.4)

            if isRunning {
                Circle()
                    .fill(isPaused ? Color.orange : Color.green)
                    .frame(width: 7, height: 7)
                    .shadow(color: (isPaused ? Color.orange : Color.green).opacity(0.6), radius: 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(7)
            }
        }
        .frame(width: 42, height: 42)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct HeaderPauseTransportButton: View {
    let isPaused: Bool

    private var accentColor: Color {
        isPaused ? .accentColor : .secondary
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(accentColor.opacity(isPaused ? 0.14 : 0.1))

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(accentColor.opacity(isPaused ? 0.34 : 0.18), lineWidth: 1)

            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(accentColor)
                .offset(x: isPaused ? 1.1 : 0)
        }
        .frame(width: 42, height: 42)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct HeaderFloatingCaptionToggleButton: View {
    let isOn: Bool

    private var accentColor: Color {
        isOn ? .green : .secondary
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(accentColor.opacity(isOn ? 0.16 : 0.1))

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(accentColor.opacity(isOn ? 0.42 : 0.18), lineWidth: 1)

            Image(systemName: isOn ? "captions.bubble.fill" : "captions.bubble")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(accentColor)

            Circle()
                .fill(isOn ? Color.green : Color.secondary.opacity(0.55))
                .frame(width: 7, height: 7)
                .shadow(color: (isOn ? Color.green : Color.clear).opacity(0.6), radius: 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(7)
        }
        .frame(width: 42, height: 42)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct SessionStatusBadge: View {
    let isRunning: Bool
    let isPaused: Bool

    private var title: String {
        isPaused ? AppText.paused : (isRunning ? AppText.listening : AppText.idle)
    }

    private var systemImage: String {
        isPaused ? "pause.circle.fill" : (isRunning ? "waveform.circle.fill" : "moon.zzz.fill")
    }

    private var foregroundStyle: Color {
        isPaused ? .orange : (isRunning ? .green : .secondary)
    }

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(foregroundStyle)
            .frame(width: 42, height: 42)
            .background(foregroundStyle.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(foregroundStyle.opacity(0.18), lineWidth: 1)
            }
            .help(title)
            .accessibilityLabel(title)
    }
}
