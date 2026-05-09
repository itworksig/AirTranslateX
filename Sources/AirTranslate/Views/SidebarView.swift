import AppKit
import SwiftUI

struct SidebarView: View {
    @Bindable var session: TranslationSessionStore
    @State private var isLibraryPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                brandHeader
                sessionCard
                outputCard
                libraryCard
            }
            .padding(12)
        }
        .background(.bar)
        .navigationTitle("AirTranslate")
        .sheet(isPresented: $isLibraryPresented) {
            TranscriptLibraryView(session: session)
        }
    }

    private var brandHeader: some View {
        HStack(spacing: 12) {
            AppIconMark()

            VStack(alignment: .leading, spacing: 3) {
                Text(AppText.appName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(AppText.appTagline)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                CaptureStatusIndicator(
                    symbolName: statusSymbolName,
                    color: statusColor,
                    statusMessage: session.statusMessage
                )

                if needsPermissionAction {
                    Button {
                        session.openPrivacySettings()
                    } label: {
                        Image(systemName: "gear")
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .help(AppText.openPrivacySettings)
                    .accessibilityLabel(AppText.openPrivacySettings)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        }
    }

    private var sessionCard: some View {
        SidebarCard(title: AppText.session) {
            VStack(spacing: 10) {
                Picker(AppText.from, selection: $session.sourceLanguage) {
                    ForEach(LanguageOption.supported) { language in
                        Text(language.localizedTitle).tag(language)
                    }
                }

                Picker(AppText.to, selection: $session.targetLanguage) {
                    ForEach(LanguageOption.supported) { language in
                        Text(language.localizedTitle).tag(language)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text(AppText.model)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(IntelligenceModel.allCases) { model in
                            Button {
                                session.selectedModel = model
                            } label: {
                                ModelModeRow(
                                    model: model,
                                    isSelected: session.selectedModel == model
                                )
                            }
                            .buttonStyle(.plain)
                            .help(model.detail)
                        }
                    }

                    Text(AppText.requiredAssets)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 6) {
                        AssetAvailabilityRow(
                            title: AppText.speechLanguagePack,
                            availability: session.modelAvailability(for: .appleSpeechOnly),
                            helpText: "\(IntelligenceModel.appleSpeechOnly.detail)\n\(session.modelAvailability(for: .appleSpeechOnly).detail)"
                        ) {
                            session.downloadModelAssets(for: .appleSpeechOnly)
                        }

                        if session.selectedModel == .appleSystem {
                            AssetAvailabilityRow(
                                title: AppText.translationLanguagePack,
                                availability: session.modelAvailability(for: .appleOnDevice),
                                helpText: "\(IntelligenceModel.appleOnDevice.detail)\n\(session.modelAvailability(for: .appleOnDevice).detail)"
                            ) {
                                session.downloadModelAssets(for: .appleOnDevice)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            session.refreshModelAvailability()
        }
    }

    private var outputCard: some View {
        SidebarCard(title: AppText.liveOutput) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(AppText.transcriptPolish, isOn: $session.isTranscriptLintEnabled)
                Toggle(AppText.voiceOutput, isOn: $session.isDubbingEnabled)
            }
        }
    }

    private var libraryCard: some View {
        SidebarCard(title: AppText.library) {
            VStack(alignment: .leading, spacing: 10) {
                Text(AppText.librarySummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    isLibraryPresented = true
                } label: {
                    Label(AppText.manageSavedTranscripts, systemImage: "tray.full")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .controlSize(.small)
            }
        }
    }

    private var needsPermissionAction: Bool {
        session.statusMessage.localizedCaseInsensitiveContains("permission")
            || session.statusMessage.localizedCaseInsensitiveContains("권한")
    }

    private var statusSymbolName: String {
        if session.isPaused {
            return "pause.circle.fill"
        }
        if session.isRunning {
            return "waveform.circle.fill"
        }
        return "circle.dotted"
    }

    private var statusColor: Color {
        if session.isPaused {
            return .orange
        }
        if session.isRunning {
            return .green
        }
        return .secondary
    }
}

private struct AppIconMark: View {
    private var appIcon: NSImage {
        NSImage(named: "AppIcon") ?? NSApp.applicationIconImage
    }

    var body: some View {
        Image(nsImage: appIcon)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 46, height: 46)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: Color.black.opacity(0.16), radius: 5, x: 0, y: 2)
            .accessibilityHidden(true)
    }
}

private struct CaptureStatusIndicator: View {
    let symbolName: String
    let color: Color
    let statusMessage: String

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.14))

            Circle()
                .strokeBorder(color.opacity(0.36), lineWidth: 1)

            Image(systemName: symbolName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(width: 30, height: 30)
        .help(statusMessage)
        .accessibilityLabel(AppText.capture)
        .accessibilityValue(statusMessage)
    }
}

private struct ModelModeRow: View {
    let model: IntelligenceModel
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.5))
                .frame(width: 14, height: 14)

            Text(model.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Image(systemName: "info.circle")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
    }
}

private struct AssetAvailabilityRow: View {
    let title: String
    let availability: ModelAvailability
    let helpText: String
    let download: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: assetSymbolName)
                .font(.caption)
                .foregroundStyle(availabilityColor)
                .frame(width: 14, height: 14)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Image(systemName: "info.circle")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .help(helpText)

            Spacer(minLength: 4)

            trailingStatus
        }
        .help(helpText)
    }

    @ViewBuilder
    private var trailingStatus: some View {
        if availability.state == .downloading || availability.state == .checking {
            ProgressView()
                .controlSize(.small)
                .help(availability.state.title)
        } else if availability.state.canDownload {
            Button {
                download()
            } label: {
                Label(AppText.download, systemImage: "arrow.down.circle")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(availabilityColor)
            .help(AppText.downloadModelAssets)
        } else {
            Text(availability.state.title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(availabilityColor)
                .lineLimit(1)
        }
    }

    private var assetSymbolName: String {
        switch availability.state {
        case .checking:
            "clock"
        case .installed:
            "checkmark.seal.fill"
        case .downloadRequired:
            "arrow.down.circle"
        case .downloading:
            "arrow.down.circle"
        case .unsupported, .unavailable, .failed:
            "exclamationmark.triangle.fill"
        }
    }

    private var availabilityColor: Color {
        switch availability.state {
        case .checking:
            .secondary
        case .installed:
            .green
        case .downloadRequired, .downloading:
            .orange
        case .unsupported, .unavailable, .failed:
            .red
        }
    }
}

private struct SidebarCard<Content: View>: View {
    let title: String?
    @ViewBuilder let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        }
    }
}
