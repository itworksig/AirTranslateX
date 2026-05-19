import AppKit
import SwiftUI

struct SidebarView: View {
    @Bindable var session: TranslationSessionStore
    @State private var isLibraryPresented = false
    @State private var isConfigurationPresented = false
    @State private var openAIAPIKey = ""
    @State private var deepgramAPIKey = ""
    @State private var googleTranslateAPIKey = ""
    @State private var googleTTSAPIKey = ""
    @State private var deepLFreeAPIKey = ""
    @State private var deepLProAPIKey = ""
    @State private var configurationNotice: String?
    @State private var shouldFocusOpenAIAPIKey = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                brandHeader
                sessionCard
                libraryCard
            }
            .padding(12)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle(AppText.appName)
        .sheet(isPresented: $isLibraryPresented) {
            TranscriptLibraryView(session: session)
        }
        .sheet(isPresented: $isConfigurationPresented) {
            ConfigurationSheetView(
                session: session,
                openAIAPIKey: $openAIAPIKey,
                deepgramAPIKey: $deepgramAPIKey,
                googleTranslateAPIKey: $googleTranslateAPIKey,
                googleTTSAPIKey: $googleTTSAPIKey,
                deepLFreeAPIKey: $deepLFreeAPIKey,
                deepLProAPIKey: $deepLProAPIKey,
                configurationNotice: $configurationNotice,
                shouldFocusOpenAIAPIKey: $shouldFocusOpenAIAPIKey,
                dismiss: { isConfigurationPresented = false }
            )
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

                Button {
                    session.openPrivacySettings()
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                .help(AppText.openPrivacySettings)
                .accessibilityLabel(AppText.openPrivacySettings)
                .opacity(needsPermissionAction ? 1 : 0)
                .disabled(!needsPermissionAction)
                .accessibilityHidden(!needsPermissionAction)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.7), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08))
        }
    }

    private var sessionCard: some View {
        SidebarCard(
            title: AppText.translationSettings,
            headerAccessory: {
                openConfigurationButton
            }
        ) {
            VStack(spacing: 10) {
                languageControls

                CurrentModeSummaryRow(session: session)

                FloatingCaptionShortcutPanel(session: session)

                CaptionScenarioModePicker(
                    selection: $session.captionScenarioMode,
                    isDisabled: session.isRunning
                )

                ResponsivenessModePicker(
                    selection: $session.captionResponsivenessMode,
                    isDisabled: session.isRunning
                )

                ProviderStatusPanel(session: session)

                ProcessingEnginePicker(
                    selection: processingEngineBinding,
                    isDisabled: session.isRunning
                )

                AudioInputSourcePicker(
                    selection: $session.audioInputSource,
                    isDisabled: session.isRunning
                )

                if session.audioInputSource == .microphone {
                    MicrophoneInputDevicePicker(
                        selection: $session.selectedMicrophoneInputDeviceID,
                        devices: session.microphoneInputDevices,
                        isDisabled: session.isRunning
                    )
                }

            }
        }
        .onAppear {
            session.refreshModelAvailability()
            session.refreshMicrophoneInputDevices()
            if usesOpenAIAutoLanguageFlow {
                session.usePreferredLanguageForOpenAIOutput()
            }
        }
    }

    @ViewBuilder
    private var languageControls: some View {
        if usesOpenAIAutoLanguageFlow {
            VStack(alignment: .leading, spacing: 6) {
                AutoLanguageRow(helpText: AppText.openAILanguageModeDescription)
                PreferredLanguageRow(
                    selection: $session.targetLanguage,
                    isDisabled: session.isRunning
                )

                Text(AppText.openAILanguageModeDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    if session.isAppleSourceAutoDetectionEnabled {
                        CompactAutoLanguagePicker(title: AppText.from)
                    } else {
                        CompactLanguagePicker(title: AppText.from, selection: $session.sourceLanguage)
                    }

                    Button {
                        swapLanguages()
                    } label: {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 24, height: 24)
                            .background(Color(nsColor: .textBackgroundColor).opacity(0.65), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(session.isRunning || session.isAppleSourceAutoDetectionEnabled)
                    .help(AppText.swapLanguages)
                    .accessibilityLabel(AppText.swapLanguages)

                    CompactLanguagePicker(title: AppText.to, selection: $session.targetLanguage)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                CompactToggleRow(
                    title: AppText.autoDetectInput,
                    systemImage: "sparkles",
                    isOn: appleSourceAutoDetectionBinding
                )
                .disabled(session.isRunning)
                .help(
                    session.isAppleSourceAutoDetectionAvailable
                        ? AppText.appleAutoLanguageModeDescription
                        : AppText.appleAutoLanguageModeUnavailableDescription
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var appleSourceAutoDetectionBinding: Binding<Bool> {
        Binding(
            get: {
                session.isAppleSourceAutoDetectionAvailable
                    && session.isAppleSourceAutoDetectionEnabled
            },
            set: { isEnabled in
                guard session.isAppleSourceAutoDetectionAvailable else {
                    session.showAppleSourceAutoDetectionUnavailableNotice()
                    return
                }

                session.isAppleSourceAutoDetectionEnabled = isEnabled
            }
        )
    }

    private var openConfigurationButton: some View {
        Button {
            isConfigurationPresented = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 26, height: 26)
                .background(Color(nsColor: .textBackgroundColor).opacity(0.75), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .help(AppText.configureTranslationSettings)
        .accessibilityLabel(AppText.configureTranslationSettings)
    }

    private var processingEngineBinding: Binding<ProcessingEngine> {
        Binding(
            get: {
                ProcessingEngine.current(for: session)
            },
            set: { engine in
                switch engine {
                case .apple:
                    session.useAppleDefaultMode()
                case .ai:
                    session.useAIMode()
                    isConfigurationPresented = true
                }
            }
        )
    }

    private func swapLanguages() {
        let sourceLanguage = session.sourceLanguage
        session.sourceLanguage = session.targetLanguage
        session.targetLanguage = sourceLanguage
    }

    private var usesOpenAIAutoLanguageFlow: Bool {
        false
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

private enum ProcessingEngine: String, CaseIterable, Identifiable {
    case apple
    case ai

    var id: String { rawValue }

    var title: String {
        switch self {
        case .apple:
            AppText.localized(
                english: "Apple Mode",
                korean: "Apple 기본 모드",
                japanese: "Apple標準モード",
                chineseSimplified: "Apple 默认模式"
            )
        case .ai:
            AppText.localized(
                english: "AI Mode",
                korean: "AI 모드",
                japanese: "AIモード",
                chineseSimplified: "AI 模式"
            )
        }
    }

    @MainActor
    static func current(for session: TranslationSessionStore) -> ProcessingEngine {
        session.openAITranscriptionModel.isEnabled || session.openAITranslationModel.isEnabled ? .ai : .apple
    }
}

private struct CurrentModeSummaryRow: View {
    @Bindable var session: TranslationSessionStore

    var body: some View {
        Label(summaryText, systemImage: "dot.radiowaves.left.and.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private var summaryText: String {
        [
            session.captionScenarioMode.title,
            transcriptionName,
            translationName,
            "\(session.sourceLanguage.localizedTitle) → \(session.targetLanguage.localizedTitle)"
        ].joined(separator: " · ")
    }

    private var transcriptionName: String {
        session.openAITranscriptionModel.isEnabled ? session.openAITranscriptionModel.title : "Apple Speech"
    }

    private var translationName: String {
        session.openAITranslationModel.isEnabled ? session.openAITranslationModel.title : "Apple Translation"
    }
}

private struct FloatingCaptionShortcutPanel: View {
    @Bindable var session: TranslationSessionStore

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            MiniSectionHeader(
                systemImage: "captions.bubble",
                title: AppText.floatingCaptions
            )

            HStack(spacing: 6) {
                PlacementButton(title: AppText.localized(english: "Bottom", korean: "하단", japanese: "下部", chineseSimplified: "底部"), systemImage: "rectangle.bottomthird.inset.filled") {
                    FloatingCaptionWindowController.applyPlacement(.lowerThird, session: session)
                    FloatingCaptionWindowController.open(session: session)
                }
                PlacementButton(title: AppText.localized(english: "Top", korean: "상단", japanese: "上部", chineseSimplified: "顶部"), systemImage: "rectangle.topthird.inset.filled") {
                    FloatingCaptionWindowController.applyPlacement(.topCenter, session: session)
                    FloatingCaptionWindowController.open(session: session)
                }
                PlacementButton(title: AppText.localized(english: "Island", korean: "아일랜드", japanese: "島", chineseSimplified: "灵动岛"), systemImage: "macbook") {
                    FloatingCaptionWindowController.applyPlacement(.notchIsland, session: session)
                    FloatingCaptionWindowController.open(session: session)
                }
                PlacementButton(title: AppText.localized(english: "Hide", korean: "숨김", japanese: "非表示", chineseSimplified: "隐藏"), systemImage: "eye.slash") {
                    FloatingCaptionWindowController.close()
                }
            }

            Picker(AppText.floatingDisplay, selection: $session.floatingCaptionDisplayMode) {
                ForEach(FloatingCaptionDisplayMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.systemImage).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
    }
}

private struct PlacementButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        }
    }
}

private struct ResponsivenessModePicker: View {
    @Binding var selection: CaptionResponsivenessMode
    let isDisabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            MiniSectionHeader(
                systemImage: "speedometer",
                title: AppText.localized(english: "Latency", korean: "지연", japanese: "遅延", chineseSimplified: "延迟/流畅度")
            )

            Picker(AppText.localized(english: "Latency", korean: "지연", japanese: "遅延", chineseSimplified: "延迟/流畅度"), selection: $selection) {
                ForEach(CaptionResponsivenessMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .disabled(isDisabled)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

private struct ProviderStatusPanel: View {
    @Bindable var session: TranslationSessionStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                MiniSectionHeader(
                    systemImage: "network",
                    title: AppText.localized(english: "Providers", korean: "제공자", japanese: "プロバイダー", chineseSimplified: "Provider 状态")
                )

                Spacer(minLength: 8)

                Button {
                    session.testCurrentAIPipeline()
                } label: {
                    if session.isCurrentPipelineTestRunning {
                        ProgressView()
                            .scaleEffect(0.55)
                            .frame(width: 16, height: 16)
                    } else {
                        Label(AppText.localized(english: "Test AI", korean: "AI 테스트", japanese: "AIテスト", chineseSimplified: "测试 AI 链路"), systemImage: "bolt.heart")
                            .labelStyle(.titleAndIcon)
                    }
                }
                .controlSize(.small)
                .disabled(session.isCurrentPipelineTestRunning)
            }

            HStack(spacing: 8) {
                ProviderStatusPill(
                    title: transcriptionTitle,
                    color: statusColor(session.transcriptionRuntimeStatus),
                    detail: "\(session.transcriptionRuntimeStatus.title) · \(session.transcriptionRuntimeDetail)"
                )
                ProviderStatusPill(
                    title: translationTitle,
                    color: statusColor(session.translationRuntimeStatus),
                    detail: "\(session.translationRuntimeStatus.title) · \(session.translationRuntimeDetail)"
                )
            }

            if let duration = session.lastProviderRequestDurationText {
                Label(duration, systemImage: "timer")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            if let message = session.currentPipelineTestMessage {
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(message.localizedCaseInsensitiveContains("failed") || message.contains("失败") ? .red : .secondary)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
    }

    private var transcriptionTitle: String {
        session.openAITranscriptionModel.isEnabled ? session.openAITranscriptionModel.title : "Apple Speech"
    }

    private var translationTitle: String {
        session.openAITranslationModel.isEnabled ? session.openAITranslationModel.title : "Apple"
    }

    private func statusColor(_ status: ProviderRuntimeStatus) -> Color {
        switch status {
        case .stable:
            .green
        case .delayed, .reconnecting, .fallback:
            .orange
        case .rateLimited, .failed:
            .red
        case .idle:
            .secondary
        }
    }
}

private struct ProviderStatusPill: View {
    let title: String
    let color: Color
    let detail: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct AdvancedInterpretationPanel: View {
    @Bindable var session: TranslationSessionStore
    @Binding var googleTTSAPIKey: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            MiniSectionHeader(
                systemImage: "person.2.wave.2",
                title: AppText.localized(
                    english: "Advanced Interpretation (Experimental)",
                    korean: "고급 동시통역(실험적)",
                    japanese: "高度同時通訳（実験的）",
                    chineseSimplified: "高级同传（实验性）"
                )
            )

            CompactToggleRow(
                title: AppText.localized(
                    english: "Two-way live voice",
                    korean: "양방향 실시간 음성",
                    japanese: "双方向ライブ音声",
                    chineseSimplified: "双向实时语音"
                ),
                systemImage: "waveform.and.person.filled",
                isOn: $session.isAdvancedInterpretationEnabled
            )

            Text(AppText.localized(
                english: "Both configured languages are recognized from the microphone. Source language is translated to target; target language is translated back to source.",
                korean: "마이크에서 두 설정 언어를 모두 인식합니다. 원문 언어는 번역 언어로, 번역 언어는 원문 언어로 말합니다.",
                japanese: "マイクでは設定した2言語を両方認識します。原文は訳文へ、訳文は原文へ戻して読み上げます。",
                chineseSimplified: "麦克风会同时识别原文/译文两种语言：说原文就翻译成译文，说译文就翻回原文。"
            ))
            .font(.caption2)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 8)

            ProviderAPIKeyRow(
                apiKey: $googleTTSAPIKey,
                provider: "Google TTS",
                systemImage: "speaker.wave.2.circle",
                placeholder: "Paste Google Cloud Text-to-Speech API key",
                hasAPIKey: session.hasGoogleTTSAPIKey,
                testMessage: session.googleTTSAPIConnectionTestMessage,
                isTesting: session.isGoogleTTSAPIConnectionTestRunning,
                save: {
                    session.saveGoogleTTSAPIKey(googleTTSAPIKey)
                    if session.hasGoogleTTSAPIKey { googleTTSAPIKey = "" }
                },
                remove: {
                    session.removeGoogleTTSAPIKey()
                    googleTTSAPIKey = ""
                },
                test: {
                    session.testGoogleTTSAPIConnection()
                }
            )

            Label(session.speechOutputRuntimeDetail, systemImage: "speaker.wave.2")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .padding(.horizontal, 8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
    }
}

private struct MiniSectionHeader: View {
    let systemImage: String
    let title: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 14)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}

private struct ConfigurationSheetView: View {
    @Bindable var session: TranslationSessionStore
    @Binding var openAIAPIKey: String
    @Binding var deepgramAPIKey: String
    @Binding var googleTranslateAPIKey: String
    @Binding var googleTTSAPIKey: String
    @Binding var deepLFreeAPIKey: String
    @Binding var deepLProAPIKey: String
    @Binding var configurationNotice: String?
    @Binding var shouldFocusOpenAIAPIKey: Bool
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "gearshape.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 34, height: 34)
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(AppText.localized(
                        english: "Session Options",
                        korean: "세부 설정",
                        japanese: "詳細設定",
                        chineseSimplified: "详细设置"
                    ))
                        .font(.headline.weight(.semibold))

                    Text(ProcessingEngine.current(for: session).title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(AppText.close)
                .accessibilityLabel(AppText.close)
            }
            .padding(16)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    appleProcessingSection
                    openAIModelsSection
                    liveOutputSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }

            Divider()

            HStack {
                Spacer()

                Button(AppText.close) {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 460)
        .frame(minHeight: 560)
        .onAppear {
            session.refreshModelAvailability()
        }
    }

    private var appleProcessingSection: some View {
        InlineSettingsGroup(
            systemImage: "apple.logo",
            title: AppText.appleProcessingMode
        ) {
            VStack(spacing: 6) {
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

                Text(AppText.appleProcessingModeDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
            }
        }
    }

    private var openAIModelsSection: some View {
        InlineSettingsGroup(
            systemImage: "sparkles",
            title: AppText.aiModels
        ) {
            VStack(spacing: 6) {
                AIModelMenuRow(
                    title: AppText.aiTranscriptionModel,
                    systemImage: "waveform.circle.fill",
                    value: session.openAITranscriptionModel.title
                ) {
                    ForEach(AITranscriptionModel.allCases) { model in
                        Button(model.title) {
                            session.openAITranscriptionModel = model
                        }
                    }
                }

                AIModelMenuRow(
                    title: AppText.aiTranslationModel,
                    systemImage: "globe",
                    value: session.openAITranslationModel.title
                ) {
                    ForEach(AITranslationModel.allCases) { model in
                        Button(model.title) {
                            session.openAITranslationModel = model
                        }
                    }
                }

                if session.openAITranslationModel == .customLLMAPI {
                    AIAPIKeyRow(
                        apiKey: $openAIAPIKey,
                        shouldFocusAPIKey: $shouldFocusOpenAIAPIKey,
                        hasAPIKey: session.hasOpenAIAPIKey,
                        notice: configurationNotice,
                        testMessage: session.openAIAPIConnectionTestMessage,
                        isTesting: session.isOpenAIAPIConnectionTestRunning,
                        save: {
                            session.saveOpenAIAPIKey(openAIAPIKey)
                            if session.hasOpenAIAPIKey {
                                openAIAPIKey = ""
                            }
                            configurationNotice = nil
                            shouldFocusOpenAIAPIKey = false
                        },
                        remove: {
                            session.removeOpenAIAPIKey()
                            openAIAPIKey = ""
                        },
                        test: {
                            session.testOpenAIAPIConnection()
                        }
                    )

                    CustomLLMAPISettingsView(
                        baseURL: $session.customLLMBaseURL,
                        model: $session.customLLMModel,
                        useOpenRouter: {
                            session.useOpenRouterLLMPreset()
                        },
                        useAiHubMix: {
                            session.useAiHubMixLLMPreset()
                        }
                    )
                } else if session.openAITranslationModel == .googleTranslate {
                    ProviderAPIKeyRow(
                        apiKey: $googleTranslateAPIKey,
                        provider: "Google",
                        systemImage: "globe",
                        placeholder: AppText.googleTranslateAPIKeyPlaceholder,
                        hasAPIKey: session.hasGoogleTranslateAPIKey,
                        testMessage: session.googleTranslateAPIConnectionTestMessage,
                        isTesting: session.isGoogleTranslateAPIConnectionTestRunning,
                        save: {
                            session.saveGoogleTranslateAPIKey(googleTranslateAPIKey)
                            if session.hasGoogleTranslateAPIKey { googleTranslateAPIKey = "" }
                        },
                        remove: {
                            session.removeGoogleTranslateAPIKey()
                            googleTranslateAPIKey = ""
                        },
                        test: {
                            session.testGoogleTranslateAPIConnection()
                        }
                    )
                } else if session.openAITranslationModel == .deepLFree {
                    ProviderAPIKeyRow(
                        apiKey: $deepLFreeAPIKey,
                        provider: "DeepL Free",
                        systemImage: "character.book.closed",
                        placeholder: AppText.deepLAPIKeyPlaceholder,
                        hasAPIKey: session.hasDeepLFreeAPIKey,
                        testMessage: session.deepLFreeAPIConnectionTestMessage,
                        isTesting: session.isDeepLFreeAPIConnectionTestRunning,
                        save: {
                            session.saveDeepLFreeAPIKey(deepLFreeAPIKey)
                            if session.hasDeepLFreeAPIKey { deepLFreeAPIKey = "" }
                        },
                        remove: {
                            session.removeDeepLFreeAPIKey()
                            deepLFreeAPIKey = ""
                        },
                        test: {
                            session.testDeepLFreeAPIConnection()
                        }
                    )
                } else if session.openAITranslationModel == .deepLPro {
                    ProviderAPIKeyRow(
                        apiKey: $deepLProAPIKey,
                        provider: "DeepL Pro",
                        systemImage: "character.book.closed.fill",
                        placeholder: AppText.deepLAPIKeyPlaceholder,
                        hasAPIKey: session.hasDeepLProAPIKey,
                        testMessage: session.deepLProAPIConnectionTestMessage,
                        isTesting: session.isDeepLProAPIConnectionTestRunning,
                        save: {
                            session.saveDeepLProAPIKey(deepLProAPIKey)
                            if session.hasDeepLProAPIKey { deepLProAPIKey = "" }
                        },
                        remove: {
                            session.removeDeepLProAPIKey()
                            deepLProAPIKey = ""
                        },
                        test: {
                            session.testDeepLProAPIConnection()
                        }
                    )
                }

                if session.openAITranscriptionModel == .deepgramStreaming {
                    DeepgramAPIKeyRow(
                        apiKey: $deepgramAPIKey,
                        hasAPIKey: session.hasDeepgramAPIKey,
                        testMessage: session.deepgramAPIConnectionTestMessage,
                        isTesting: session.isDeepgramAPIConnectionTestRunning,
                        save: {
                            session.saveDeepgramAPIKey(deepgramAPIKey)
                            if session.hasDeepgramAPIKey {
                                deepgramAPIKey = ""
                            }
                        },
                        remove: {
                            session.removeDeepgramAPIKey()
                            deepgramAPIKey = ""
                        },
                        test: {
                            session.testDeepgramAPIConnection()
                        }
                    )
                }

                Text(AppText.aiModelsDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)

                HStack(spacing: 5) {
                    Text(AppText.openAIAPIKeyPlatformPrompt)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Link(
                        AppText.openAIAPIKeyPlatformLink,
                        destination: URL(string: "https://platform.openai.com/api-keys")!
                    )
                    .font(.caption2.weight(.semibold))
                }
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var liveOutputSection: some View {
        InlineSettingsGroup(
            systemImage: "waveform.and.person.filled",
            title: AppText.liveOutput
        ) {
            VStack(spacing: 6) {
                CompactToggleRow(
                    title: AppText.transcriptPolish,
                    systemImage: "text.badge.checkmark",
                    isOn: $session.isTranscriptLintEnabled
                )
                .help(AppText.transcriptLintDescription)

                AdvancedInterpretationPanel(session: session, googleTTSAPIKey: $googleTTSAPIKey)
            }
        }
    }
}

private struct AutoLanguageRow: View {
    let helpText: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 16)

            Text(AppText.autoDetectInput)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Spacer(minLength: 6)

            Text(AppText.autoDetectShort)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.12), in: Capsule())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(helpText)
        .accessibilityLabel(AppText.autoDetectInput)
    }
}

private struct PreferredLanguageRow: View {
    @Binding var selection: LanguageOption
    let isDisabled: Bool

    var body: some View {
        Menu {
            ForEach(LanguageOption.supported) { language in
                Button(language.localizedTitle) {
                    selection = language
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 16)

                Text(AppText.preferredLanguage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 6)

                Text(selection.localizedTitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .help(AppText.preferredLanguage)
        .accessibilityLabel(AppText.preferredLanguage)
        .accessibilityValue(selection.localizedTitle)
    }
}

private struct OpenAIVoiceOutputRow: View {
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: isOn ? "speaker.wave.2.fill" : "speaker")
                .font(.caption.weight(.bold))
                .foregroundStyle(isOn ? Color.accentColor : Color.secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(AppText.translatedVoiceOutput)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(AppText.translatedVoiceOutputDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Toggle(AppText.translatedVoiceOutput, isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(AppText.translatedVoiceOutputDescription)
        .accessibilityLabel(AppText.translatedVoiceOutput)
        .accessibilityValue(isOn ? AppText.floatingCaptionPowerOn : AppText.floatingCaptionPowerOff)
    }
}

private struct ProcessingEnginePicker: View {
    @Binding var selection: ProcessingEngine
    let isDisabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 7) {
                Image(systemName: "switch.2")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 14)

                Text(AppText.model)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }

            Picker(AppText.model, selection: $selection) {
                ForEach(ProcessingEngine.allCases) { engine in
                    Text(engine.title).tag(engine)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .disabled(isDisabled)
            .accessibilityLabel(AppText.model)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

private struct CaptionScenarioModePicker: View {
    @Binding var selection: CaptionScenarioMode
    let isDisabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                Image(systemName: selection.systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 14)

                Text(AppText.localized(
                    english: "Scene",
                    korean: "장면",
                    japanese: "シーン",
                    chineseSimplified: "场景"
                ))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }

            Menu {
                ForEach(CaptionScenarioMode.allCases) { mode in
                    Button {
                        selection = mode
                    } label: {
                        Label(mode.title, systemImage: mode.systemImage)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: selection.systemImage)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 22)

                    Text(selection.title)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.07))
                }
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
            .help(selection.title)
            .accessibilityLabel(selection.title)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

private struct AudioInputSourcePicker: View {
    @Binding var selection: AudioInputSource
    let isDisabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 7) {
                Image(systemName: "waveform.badge.magnifyingglass")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 14)

                Text(AppText.audioInputSource)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }

            Picker(AppText.audioInputSource, selection: $selection) {
                ForEach(AudioInputSource.allCases) { source in
                    Text(source.title).tag(source)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .disabled(isDisabled)
            .accessibilityLabel(AppText.audioInputSource)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

private struct MicrophoneInputDevicePicker: View {
    @Binding var selection: String
    let devices: [MicrophoneInputDevice]
    let isDisabled: Bool

    var body: some View {
        Menu {
            ForEach(devices) { device in
                Button(device.name) {
                    selection = device.id
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "mic.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 16)

                Text(AppText.microphoneInputDevice)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 6)

                Text(selectedDeviceName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .help(AppText.microphoneInputDevice)
        .accessibilityLabel(AppText.microphoneInputDevice)
        .accessibilityValue(selectedDeviceName)
    }

    private var selectedDeviceName: String {
        devices.first { $0.id == selection }?.name ?? MicrophoneInputDevice.systemDefault.name
    }
}

private struct InlineSettingsGroup<Content: View>: View {
    let systemImage: String
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 16, height: 16)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }

            content
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
        }
    }
}

private struct CompactToggleRow: View {
    let title: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(isOn ? Color.accentColor : Color.secondary)
                .frame(width: 18, height: 18)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer(minLength: 12)

            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .accessibilityLabel(title)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct CompactInfoRow: View {
    let title: String
    let detail: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct AIModelMenuRow<MenuContent: View>: View {
    let title: String
    let systemImage: String
    let value: String
    @ViewBuilder let menuContent: MenuContent

    var body: some View {
        Menu {
            menuContent
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 16)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer(minLength: 6)

                Text(value)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(Color(nsColor: .textBackgroundColor).opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(title)
    }
}

private struct CustomLLMAPISettingsView: View {
    @Binding var baseURL: String
    @Binding var model: String
    let useOpenRouter: () -> Void
    let useAiHubMix: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Button("OpenRouter") {
                    useOpenRouter()
                }
                .buttonStyle(.borderless)

                Button("AiHubMix") {
                    useAiHubMix()
                }
                .buttonStyle(.borderless)

                Spacer(minLength: 0)
            }

            LabeledContent {
                TextField(AppText.customLLMBaseURLPlaceholder, text: $baseURL)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
            } label: {
                Text(AppText.customLLMBaseURL)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            LabeledContent {
                TextField(AppText.customLLMModelPlaceholder, text: $model)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
            } label: {
                Text(AppText.customLLMModel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(AppText.customLLMDescription)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct AIAPIKeyRow: View {
    @Binding var apiKey: String
    @Binding var shouldFocusAPIKey: Bool
    @FocusState private var isAPIKeyFocused: Bool
    let hasAPIKey: Bool
    let notice: String?
    let testMessage: String?
    let isTesting: Bool
    let save: () -> Void
    let remove: () -> Void
    let test: () -> Void

    private var trimmedAPIKey: String {
        apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var apiKeyPlaceholder: String {
        hasAPIKey ? "********" : AppText.openAIAPIKeyPlaceholder
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(hasAPIKey ? Color.green : Color.secondary)
                    .frame(width: 16)

                SecureField(apiKeyPlaceholder, text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                    .focused($isAPIKeyFocused)

                Button {
                    save()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                }
                .buttonStyle(.borderless)
                .disabled(trimmedAPIKey.isEmpty)
                .help(AppText.saveOpenAIAPIKey)
                .accessibilityLabel(AppText.saveOpenAIAPIKey)

                Button {
                    test()
                } label: {
                    Image(systemName: isTesting ? "hourglass" : "network")
                }
                .buttonStyle(.borderless)
                .disabled(!hasAPIKey || isTesting)
                .help(AppText.testOpenAIAPIKey)
                .accessibilityLabel(AppText.testOpenAIAPIKey)

                Button {
                    remove()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .disabled(!hasAPIKey)
                .help(AppText.removeOpenAIAPIKey)
                .accessibilityLabel(AppText.removeOpenAIAPIKey)
            }

            if let notice, !hasAPIKey {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.orange)

                    Text(notice)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 24)
            }

            if let testMessage {
                Text(testMessage)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(testMessage == AppText.openAIAPIConnectionSucceeded ? Color.green : Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 24)
            }

            Text(hasAPIKey ? AppText.openAIAPIKeyConfigured : AppText.openAIAPIKeyNotConfigured)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(hasAPIKey ? Color.green : Color.secondary)
                .padding(.leading, 24)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onAppear {
            focusAPIKeyIfNeeded()
        }
        .onChange(of: shouldFocusAPIKey) { _, _ in
            focusAPIKeyIfNeeded()
        }
    }

    private func focusAPIKeyIfNeeded() {
        guard shouldFocusAPIKey else { return }
        Task { @MainActor in
            isAPIKeyFocused = true
            shouldFocusAPIKey = false
        }
    }
}

private struct DeepgramAPIKeyRow: View {
    @Binding var apiKey: String
    let hasAPIKey: Bool
    let testMessage: String?
    let isTesting: Bool
    let save: () -> Void
    let remove: () -> Void
    let test: () -> Void

    private var trimmedAPIKey: String {
        apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var apiKeyPlaceholder: String {
        hasAPIKey ? "********" : AppText.deepgramAPIKeyPlaceholder
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.badge.magnifyingglass")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(hasAPIKey ? Color.green : Color.secondary)
                    .frame(width: 16)

                SecureField(apiKeyPlaceholder, text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)

                Button {
                    save()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                }
                .buttonStyle(.borderless)
                .disabled(trimmedAPIKey.isEmpty)
                .help(AppText.saveDeepgramAPIKey)
                .accessibilityLabel(AppText.saveDeepgramAPIKey)

                Button {
                    test()
                } label: {
                    Image(systemName: isTesting ? "hourglass" : "network")
                }
                .buttonStyle(.borderless)
                .disabled(!hasAPIKey || isTesting)
                .help(AppText.testDeepgramAPIKey)
                .accessibilityLabel(AppText.testDeepgramAPIKey)

                Button {
                    remove()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .disabled(!hasAPIKey)
                .help(AppText.removeDeepgramAPIKey)
                .accessibilityLabel(AppText.removeDeepgramAPIKey)
            }

            if let testMessage {
                Text(testMessage)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(testMessage == AppText.deepgramAPIConnectionSucceeded ? Color.green : Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 24)
            }

            Text(hasAPIKey ? AppText.deepgramAPIKeyConfigured : AppText.deepgramAPIKeyNotConfigured)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(hasAPIKey ? Color.green : Color.secondary)
                .padding(.leading, 24)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ProviderAPIKeyRow: View {
    @Binding var apiKey: String
    let provider: String
    let systemImage: String
    let placeholder: String
    let hasAPIKey: Bool
    let testMessage: String?
    let isTesting: Bool
    let save: () -> Void
    let remove: () -> Void
    let test: () -> Void

    private var trimmedAPIKey: String {
        apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var apiKeyPlaceholder: String {
        hasAPIKey ? "********" : placeholder
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(hasAPIKey ? Color.green : Color.secondary)
                    .frame(width: 16)

                SecureField(apiKeyPlaceholder, text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)

                Button {
                    save()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                }
                .buttonStyle(.borderless)
                .disabled(trimmedAPIKey.isEmpty)
                .help(AppText.saveOpenAIAPIKey)
                .accessibilityLabel(AppText.saveOpenAIAPIKey)

                Button {
                    test()
                } label: {
                    Image(systemName: isTesting ? "hourglass" : "network")
                }
                .buttonStyle(.borderless)
                .disabled(!hasAPIKey || isTesting)
                .help(AppText.testOpenAIAPIKey)
                .accessibilityLabel(AppText.testOpenAIAPIKey)

                Button {
                    remove()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .disabled(!hasAPIKey)
                .help(AppText.removeOpenAIAPIKey)
                .accessibilityLabel(AppText.removeOpenAIAPIKey)
            }

            if let testMessage {
                Text(testMessage)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(testMessage == AppText.providerAPIConnectionSucceeded(provider) ? Color.green : Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 24)
            }

            Text(hasAPIKey ? AppText.providerAPIKeyConfigured(provider) : AppText.providerAPIKeyNotConfigured(provider))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(hasAPIKey ? Color.green : Color.secondary)
                .padding(.leading, 24)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct CompactLanguagePicker: View {
    let title: String
    @Binding var selection: LanguageOption

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .trailing)
                .lineLimit(1)

            Menu {
                ForEach(LanguageOption.supported) { language in
                    Button(language.localizedTitle) {
                        selection = language
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selection.localizedTitle)
                        .font(.callout.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .frame(width: 72)
                .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .help(title)
            .accessibilityLabel(title)
            .accessibilityValue(selection.localizedTitle)
        }
        .frame(width: 100)
    }
}

private struct CompactAutoLanguagePicker: View {
    let title: String

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .trailing)
                .lineLimit(1)

            HStack(spacing: 4) {
                Text(AppText.autoDetectShort)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)

                Image(systemName: "sparkles")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .frame(width: 72)
            .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .frame(width: 100)
        .help(AppText.appleAutoLanguageModeUnavailableDescription)
        .accessibilityLabel(AppText.autoDetectInput)
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
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: modelSymbolName)
                .font(.callout.weight(.semibold))
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                .frame(width: 18, height: 18)

            Text(model.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.callout.weight(.semibold))
                .foregroundStyle(isSelected ? Color.green : Color.secondary.opacity(0.55))
                .frame(width: 18, height: 18)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor).opacity(isSelected ? 0.9 : 0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(isSelected ? Color.green.opacity(0.35) : Color.primary.opacity(0.06), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var modelSymbolName: String {
        switch model {
        case .appleSystem:
            "captions.bubble.fill"
        case .appleOnDevice:
            "arrow.down.circle.fill"
        case .appleSpeechOnly:
            "waveform"
        }
    }
}

private struct AssetAvailabilityRow: View {
    let title: String
    let availability: ModelAvailability
    let helpText: String
    let download: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: assetSymbolName)
                .font(.callout.weight(.semibold))
                .foregroundStyle(availabilityColor)
                .frame(width: 28, height: 28)
                .background(availabilityColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(availability.detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            trailingStatus
        }
        .padding(10)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
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
                    .font(.title3)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(availabilityColor)
            .help(AppText.downloadModelAssets)
        } else {
            Text(availability.state.title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(availabilityColor)
                .lineLimit(1)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(availabilityColor.opacity(0.12), in: Capsule())
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

private struct SidebarCard<Content: View, HeaderAccessory: View>: View {
    let title: String?
    @ViewBuilder let headerAccessory: HeaderAccessory
    @ViewBuilder let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) where HeaderAccessory == EmptyView {
        self.title = title
        self.headerAccessory = EmptyView()
        self.content = content()
    }

    init(
        title: String? = nil,
        @ViewBuilder headerAccessory: () -> HeaderAccessory,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.headerAccessory = headerAccessory()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Spacer(minLength: 0)

                    headerAccessory
                }
            }

            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.7), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.07))
        }
    }
}
