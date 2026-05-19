import Foundation
import Security

enum AppText {
    private enum InterfaceLanguage {
        case english
        case korean
        case japanese
        case chineseSimplified
        case russian
    }

    private static var interfaceLanguage: InterfaceLanguage {
        if ProcessInfo.processInfo.environment["AIRTRANSLATE_PRODUCT_HUNT_SCREENSHOTS"] == "1" {
            return .english
        }

        let languageCode = Locale.preferredLanguages.first?.lowercased() ?? ""
        if languageCode.hasPrefix("ko") {
            return .korean
        }
        if languageCode.hasPrefix("ja") {
            return .japanese
        }
        if languageCode.hasPrefix("zh") {
            return .chineseSimplified
        }
        if languageCode.hasPrefix("ru") {
            return .russian
        }
        return .english
    }

    static func localized(english: String, korean: String, russian: String? = nil) -> String {
        localized(
            english: english,
            korean: korean,
            japanese: english,
            chineseSimplified: english,
            russian: russian
        )
    }

    static func localized(
        english: String,
        korean: String,
        japanese: String,
        chineseSimplified: String,
        russian: String? = nil
    ) -> String {
        switch interfaceLanguage {
        case .english:
            english
        case .korean:
            korean
        case .japanese:
            japanese
        case .chineseSimplified:
            chineseSimplified
        case .russian:
            russian ?? english
        }
    }

    static let appName = "AirTranslateX"
    static let appTagline = localized(
        english: "Live transcript translator",
        korean: "실시간 기록 번역",
        japanese: "リアルタイム記録翻訳",
        chineseSimplified: "实时转写翻译"
    )
    static let ready = localized(english: "Ready", korean: "준비됨", japanese: "準備完了", chineseSimplified: "就绪")
    static let stopped = localized(english: "Stopped", korean: "중지됨", japanese: "停止中", chineseSimplified: "已停止")
    static let paused = localized(english: "Paused", korean: "일시정지됨", japanese: "一時停止中", chineseSimplified: "已暂停")
    static let capture = localized(english: "Capture", korean: "캡처", japanese: "キャプチャ", chineseSimplified: "捕获")
    static let start = localized(english: "Start", korean: "시작", japanese: "開始", chineseSimplified: "开始")
    static let stop = localized(english: "Stop", korean: "중지", japanese: "停止", chineseSimplified: "停止")
    static let close = localized(english: "Close", korean: "닫기", japanese: "閉じる", chineseSimplified: "关闭")
    static let cancel = localized(english: "Cancel", korean: "취소", japanese: "キャンセル", chineseSimplified: "取消")
    static let pause = localized(english: "Pause", korean: "일시정지", japanese: "一時停止", chineseSimplified: "暂停")
    static let resume = localized(english: "Resume", korean: "재개", japanese: "再開", chineseSimplified: "继续")
    static let languages = localized(english: "Languages", korean: "언어", japanese: "言語", chineseSimplified: "语言")
    static let from = localized(english: "From", korean: "원문", japanese: "原文", chineseSimplified: "原文")
    static let to = localized(english: "To", korean: "번역", japanese: "翻訳", chineseSimplified: "译文")
    static let autoDetectShort = localized(english: "Auto", korean: "자동", japanese: "自動", chineseSimplified: "自动")
    static let autoDetectInput = localized(
        english: "Auto-detect input",
        korean: "입력 언어 자동 감지",
        japanese: "入力言語を自動検出",
        chineseSimplified: "自动检测输入语言"
    )
    static let autoDetectionLanguageChangeTitle = localized(
        english: "New input language detected",
        korean: "새 입력 언어가 감지되었습니다",
        japanese: "新しい入力言語を検出しました",
        chineseSimplified: "检测到新的输入语言"
    )
    static let startNewAutoDetectionSession = localized(
        english: "Start New Session",
        korean: "새 세션 시작",
        japanese: "新しいセッションを開始",
        chineseSimplified: "开始新会话"
    )
    static let keepCurrentAutoDetectionLanguage = localized(
        english: "Keep Current Session",
        korean: "현재 세션 유지",
        japanese: "現在のセッションを維持",
        chineseSimplified: "保留当前会话"
    )
    static let preferredLanguageShort = localized(english: "Pref.", korean: "선호", japanese: "優先", chineseSimplified: "首选")
    static let preferredLanguage = localized(
        english: "Preferred language",
        korean: "선호 언어",
        japanese: "優先言語",
        chineseSimplified: "首选语言"
    )
    static let swapLanguages = localized(english: "Swap Languages", korean: "언어 바꾸기", japanese: "言語を入れ替え", chineseSimplified: "交换语言")
    static let model = localized(english: "Mode", korean: "처리 방식", japanese: "処理方式", chineseSimplified: "处理方式")
    static let audioInputSource = localized(
        english: "Audio Input",
        korean: "오디오 입력",
        japanese: "オーディオ入力",
        chineseSimplified: "音频输入"
    )
    static let systemAudioInput = localized(
        english: "Mac Audio",
        korean: "PC 소리",
        japanese: "Mac音声",
        chineseSimplified: "Mac 音频"
    )
    static let microphoneInput = localized(
        english: "Microphone",
        korean: "마이크",
        japanese: "マイク",
        chineseSimplified: "麦克风"
    )
    static let microphoneInputDevice = localized(
        english: "Input Device",
        korean: "입력 장치",
        japanese: "入力デバイス",
        chineseSimplified: "输入设备"
    )
    static let systemDefaultMicrophone = localized(
        english: "System Default",
        korean: "시스템 기본값",
        japanese: "システム標準",
        chineseSimplified: "系统默认"
    )
    static let modelStatusChecking = localized(english: "Checking", korean: "확인 중", japanese: "確認中", chineseSimplified: "正在检查")
    static let modelStatusInstalled = localized(english: "Installed", korean: "설치됨", japanese: "インストール済み", chineseSimplified: "已安装")
    static let modelStatusDownloadRequired = localized(english: "Download Needed", korean: "다운로드 필요", japanese: "ダウンロードが必要", chineseSimplified: "需要下载")
    static let modelStatusDownloading = localized(english: "Downloading", korean: "다운로드 중", japanese: "ダウンロード中", chineseSimplified: "正在下载")
    static let modelStatusUnsupported = localized(english: "Unsupported", korean: "미지원", japanese: "未対応", chineseSimplified: "不支持")
    static let modelStatusUnavailable = localized(english: "Unavailable", korean: "사용 불가", japanese: "利用不可", chineseSimplified: "不可用")
    static let modelStatusFailed = localized(english: "Check Failed", korean: "확인 실패", japanese: "確認失敗", chineseSimplified: "检查失败")
    static let download = localized(english: "Download", korean: "다운로드", japanese: "ダウンロード", chineseSimplified: "下载")
    static let downloadModelAssets = localized(
        english: "Download model assets",
        korean: "모델 자산 다운로드"
    )
    static let requiredAssets = localized(english: "Required Assets", korean: "필요 자산")
    static let speechLanguagePack = localized(
        english: "Speech Recognition Pack",
        korean: "음성 인식 언어팩"
    )
    static let translationLanguagePack = localized(
        english: "Translation Language Pack",
        korean: "번역 언어팩"
    )
    static let openAIAPIKey = localized(english: "OpenAI API Key", korean: "OpenAI API 키")
    static let openAIAPIKeyDescription = localized(
        english: "Enter your API key in the app. AirTranslate stores it in Documents/AirTranslateX/config.ini.",
        korean: "앱에서 API 키를 입력하세요. AirTranslate는 Documents/AirTranslateX/config.ini에 저장합니다.",
        japanese: "アプリでAPIキーを入力してください。AirTranslateはDocuments/AirTranslateX/config.iniに保存します。",
        chineseSimplified: "在应用中输入 API key。AirTranslate 会保存到 Documents/AirTranslateX/config.ini。"
    )
    static let openAIAPIKeyPlaceholder = localized(
        english: "Paste API key",
        korean: "API 키 붙여넣기",
        japanese: "APIキーを貼り付け",
        chineseSimplified: "粘贴 API key"
    )
    static let googleTranslateAPIKeyPlaceholder = localized(
        english: "Paste Google API key",
        korean: "Google API 키 붙여넣기",
        japanese: "Google APIキーを貼り付け",
        chineseSimplified: "粘贴 Google API key"
    )
    static let deepLAPIKeyPlaceholder = localized(
        english: "Paste DeepL API key",
        korean: "DeepL API 키 붙여넣기",
        japanese: "DeepL APIキーを貼り付け",
        chineseSimplified: "粘贴 DeepL API key"
    )
    static let saveOpenAIAPIKey = localized(english: "Save API Key", korean: "API 키 저장", japanese: "APIキーを保存", chineseSimplified: "保存 API key")
    static let removeOpenAIAPIKey = localized(english: "Remove API Key", korean: "API 키 삭제", japanese: "APIキーを削除", chineseSimplified: "删除 API key")
    static let testOpenAIAPIKey = localized(english: "Test API Key", korean: "API 키 테스트", japanese: "APIキーをテスト", chineseSimplified: "测试 API key")
    static let openAIAPIKeySaved = localized(
        english: "OpenAI API key saved in config.ini.",
        korean: "OpenAI API 키가 config.ini에 저장되었습니다.",
        japanese: "OpenAI APIキーをconfig.iniに保存しました。",
        chineseSimplified: "OpenAI API key 已保存到 config.ini。"
    )
    static let openAIAPIKeyRemoved = localized(
        english: "OpenAI API key removed.",
        korean: "OpenAI API 키가 삭제되었습니다."
    )
    static let openAIAPIKeyConfigured = localized(
        english: "API key saved",
        korean: "API 키 저장됨",
        japanese: "APIキー保存済み",
        chineseSimplified: "API key 已保存"
    )
    static let openAIAPIKeyNotConfigured = localized(
        english: "API key required",
        korean: "API 키 필요",
        japanese: "APIキーが必要",
        chineseSimplified: "需要 API key"
    )
    static let openAIAPIKeyMissing = localized(
        english: "Add an OpenAI API key in Settings before using OpenAI Translation.",
        korean: "OpenAI 번역을 사용하려면 설정에서 OpenAI API 키를 먼저 입력하세요."
    )
    static let googleTranslateAPIKeyMissing = localized(
        english: "Add a Google Cloud Translation API key in Settings.",
        korean: "설정에서 Google Cloud Translation API 키를 입력하세요.",
        japanese: "設定でGoogle Cloud Translation APIキーを入力してください。",
        chineseSimplified: "请先在设置里添加 Google Cloud Translation API key。"
    )
    static let deepLAPIKeyMissing = localized(
        english: "Add a DeepL API key in Settings.",
        korean: "설정에서 DeepL API 키를 입력하세요.",
        japanese: "設定でDeepL APIキーを入力してください。",
        chineseSimplified: "请先在设置里添加 DeepL API key。"
    )
    static let openAIAPIKeyRequiredForAIMode = localized(
        english: "Enter an API key to use AI Mode.",
        korean: "AI 모드를 사용하려면 API 키를 입력하세요.",
        japanese: "AIモードを使うにはAPIキーを入力してください。",
        chineseSimplified: "要使用 AI 模式，请输入 API key。"
    )
    static let openAIAPIKeyEmpty = localized(
        english: "Enter an OpenAI API key before saving.",
        korean: "저장하기 전에 OpenAI API 키를 입력하세요."
    )
    static let openAIAPIKeyInvalidStoredValue = localized(
        english: "The stored OpenAI API key could not be read.",
        korean: "저장된 OpenAI API 키를 읽을 수 없습니다."
    )
    static let openAIAPIKeyMaskedPlaceholder = localized(
        english: "Enter the real API key, not the masked placeholder.",
        korean: "마스킹 표시가 아닌 실제 API 키를 입력하세요."
    )
    static let deepgramAPIKeyPlaceholder = localized(
        english: "Paste Deepgram API key",
        korean: "Deepgram API 키 붙여넣기",
        japanese: "Deepgram APIキーを貼り付け",
        chineseSimplified: "粘贴 Deepgram API key"
    )
    static let saveDeepgramAPIKey = localized(english: "Save Deepgram API Key", korean: "Deepgram API 키 저장", japanese: "Deepgram APIキーを保存", chineseSimplified: "保存 Deepgram API key")
    static let removeDeepgramAPIKey = localized(english: "Remove Deepgram API Key", korean: "Deepgram API 키 삭제", japanese: "Deepgram APIキーを削除", chineseSimplified: "删除 Deepgram API key")
    static let testDeepgramAPIKey = localized(english: "Test Deepgram API Key", korean: "Deepgram API 키 테스트", japanese: "Deepgram APIキーをテスト", chineseSimplified: "测试 Deepgram API key")
    static let deepgramAPIKeySaved = localized(
        english: "Deepgram API key saved in config.ini.",
        korean: "Deepgram API 키가 config.ini에 저장되었습니다.",
        japanese: "Deepgram APIキーをconfig.iniに保存しました。",
        chineseSimplified: "Deepgram API key 已保存到 config.ini。"
    )
    static let deepgramAPIKeyRemoved = localized(
        english: "Deepgram API key removed.",
        korean: "Deepgram API 키가 삭제되었습니다."
    )
    static let deepgramAPIKeyConfigured = localized(
        english: "Deepgram API key saved",
        korean: "Deepgram API 키 저장됨",
        japanese: "Deepgram APIキー保存済み",
        chineseSimplified: "Deepgram API key 已保存"
    )
    static let deepgramAPIKeyNotConfigured = localized(
        english: "Deepgram API key required",
        korean: "Deepgram API 키 필요",
        japanese: "Deepgram APIキーが必要",
        chineseSimplified: "需要 Deepgram API key"
    )
    static func providerAPIKeySaved(_ provider: String) -> String {
        localized(
            english: "\(provider) API key saved.",
            korean: "\(provider) API 키가 저장되었습니다.",
            japanese: "\(provider) APIキーを保存しました。",
            chineseSimplified: "\(provider) API key 已保存。"
        )
    }
    static func providerAPIKeyRemoved(_ provider: String) -> String {
        localized(
            english: "\(provider) API key removed.",
            korean: "\(provider) API 키를 삭제했습니다.",
            japanese: "\(provider) APIキーを削除しました。",
            chineseSimplified: "\(provider) API key 已删除。"
        )
    }
    static func providerAPIKeyConfigured(_ provider: String) -> String {
        localized(
            english: "\(provider) API key saved",
            korean: "\(provider) API 키 저장됨",
            japanese: "\(provider) APIキー保存済み",
            chineseSimplified: "\(provider) API key 已保存"
        )
    }
    static func providerAPIKeyNotConfigured(_ provider: String) -> String {
        localized(
            english: "\(provider) API key required",
            korean: "\(provider) API 키 필요",
            japanese: "\(provider) APIキーが必要",
            chineseSimplified: "需要 \(provider) API key"
        )
    }
    static let appleProcessingMode = localized(english: "Apple Mode", korean: "Apple 기본 모드", japanese: "Apple標準モード", chineseSimplified: "Apple 默认模式")
    static let appleProcessingModeDescription = localized(
        english: "Use Apple's local speech and translation workflow.",
        korean: "Apple 로컬 음성 인식 및 번역 흐름을 사용합니다.",
        japanese: "Appleのローカル音声認識と翻訳ワークフローを使用します。",
        chineseSimplified: "使用 Apple 本地语音识别和翻译流程。"
    )
    static let aiModels = localized(english: "AI Providers", korean: "AI 제공업체", japanese: "AIプロバイダー", chineseSimplified: "AI 服务")
    static let aiTranscriptionModel = localized(
        english: "Transcription",
        korean: "전사",
        japanese: "文字起こし",
        chineseSimplified: "转写"
    )
    static let aiTranslationModel = localized(
        english: "Translation",
        korean: "자동번역",
        japanese: "自動翻訳",
        chineseSimplified: "翻译"
    )
    static let aiModelsDescription = localized(
        english: "Choose Deepgram for live transcription, then translate with Apple, a custom LLM API, Google, or DeepL.",
        korean: "실시간 전사는 Deepgram을 선택하고 번역은 Apple, Custom LLM API, Google, DeepL 중에서 고를 수 있습니다.",
        japanese: "ライブ文字起こしはDeepgram、翻訳はApple、Custom LLM API、Google、DeepLから選べます。",
        chineseSimplified: "可用 Deepgram 实时转写，并用 Apple、自定义 LLM API、Google 或 DeepL 翻译。"
    )
    static let customLLMBaseURL = localized(
        english: "Base URL",
        korean: "Base URL",
        japanese: "Base URL",
        chineseSimplified: "Base URL"
    )
    static let customLLMBaseURLPlaceholder = localized(
        english: "https://openrouter.ai/api/v1",
        korean: "https://openrouter.ai/api/v1",
        japanese: "https://openrouter.ai/api/v1",
        chineseSimplified: "https://openrouter.ai/api/v1"
    )
    static let customLLMModel = localized(
        english: "Model",
        korean: "모델",
        japanese: "モデル",
        chineseSimplified: "模型"
    )
    static let customLLMModelPlaceholder = localized(
        english: "openai/gpt-4o-mini",
        korean: "openai/gpt-4o-mini",
        japanese: "openai/gpt-4o-mini",
        chineseSimplified: "openai/gpt-4o-mini"
    )
    static let customLLMDescription = localized(
        english: "Use any OpenAI-compatible /chat/completions API, including OpenRouter and AiHubMix.",
        korean: "OpenRouter와 AiHubMix를 포함해 OpenAI 호환 /chat/completions API를 사용할 수 있습니다.",
        japanese: "OpenRouterやAiHubMixなど、OpenAI互換の/chat/completions APIを使用できます。",
        chineseSimplified: "可使用 OpenRouter、AiHubMix 等 OpenAI 兼容的 /chat/completions API。"
    )
    static let openAILanguageModeDescription = localized(
        english: "OpenAI detects the input language and translates it to your preferred language.",
        korean: "OpenAI가 입력 언어를 자동 감지하고 선호 언어로 번역합니다.",
        japanese: "OpenAIが入力言語を自動検出し、優先言語へ翻訳します。",
        chineseSimplified: "OpenAI 会自动检测输入语言并翻译为首选语言。"
    )
    static let appleAutoLanguageModeDescription = localized(
        english: "Apple Speech listens with installed supported language models and translates from the detected source language.",
        korean: "Apple Speech가 설치된 지원 언어 모델로 듣고 감지된 원문 언어에서 번역합니다.",
        japanese: "Apple Speechがインストール済みの対応言語モデルで聞き取り、検出した原文言語から翻訳します。",
        chineseSimplified: "Apple Speech 会使用已安装的受支持语言模型收听，并从检测到的原文语言翻译。"
    )
    static let appleAutoLanguageModeUnavailableDescription = localized(
        english: "Auto-detect input is temporarily disabled and will be improved in a future update.",
        korean: "입력 언어 자동 감지는 잠시 비활성화되어 있으며 추후 업데이트에서 개선될 예정입니다.",
        japanese: "入力言語の自動検出は一時的に無効化されており、今後のアップデートで改善予定です。",
        chineseSimplified: "输入语言自动检测已暂时停用，将在后续更新中改进。"
    )
    static let appleAutoLanguageModeUnavailableToast = localized(
        english: "Auto-detect input will be improved in a future update.",
        korean: "입력 언어 자동 감지는 추후 업데이트에서 개선될 예정입니다.",
        japanese: "入力言語の自動検出は今後のアップデートで改善予定です。",
        chineseSimplified: "输入语言自动检测将在后续更新中改进。"
    )
    static let translatedVoiceOutput = localized(
        english: "AI translated voice",
        korean: "AI 번역 음성",
        japanese: "翻訳音声",
        chineseSimplified: "译文语音"
    )
    static let translatedVoiceOutputDescription = localized(
        english: "Play translated speech from the selected AI workflow.",
        korean: "선택한 AI 흐름의 번역 음성을 재생합니다.",
        japanese: "選択したAIワークフローの翻訳音声を再生します。",
        chineseSimplified: "播放所选 AI 流程的译文语音。"
    )
    static let openAIAPIKeyPlatformPrompt = localized(
        english: "No API key yet?",
        korean: "API 키가 없다면",
        japanese: "APIキーがない場合",
        chineseSimplified: "还没有 API key？"
    )
    static let openAIAPIKeyPlatformLink = localized(
        english: "Open OpenAI API Platform",
        korean: "OpenAI API 플랫폼 열기",
        japanese: "OpenAI API Platformを開く",
        chineseSimplified: "打开 OpenAI API 平台"
    )
    static let aiRealtimeTranslationOnlySource = localized(
        english: "OpenAI realtime translation",
        korean: "OpenAI 실시간 번역"
    )
    static let output = localized(english: "Output", korean: "출력", japanese: "出力", chineseSimplified: "输出")
    static let translationSettings = localized(english: "Translation Settings", korean: "번역 설정", japanese: "翻訳設定", chineseSimplified: "翻译设置")
    static let configureTranslationSettings = localized(
        english: "Configure Translation Settings",
        korean: "번역 설정 구성"
    )
    static let transcript = localized(english: "Transcript", korean: "기록", japanese: "記録", chineseSimplified: "记录")
    static let liveOutput = localized(english: "Live Output", korean: "실시간 출력", japanese: "リアルタイム出力", chineseSimplified: "实时输出")
    static let library = localized(english: "Library", korean: "저장소", japanese: "ライブラリ", chineseSimplified: "资料库")
    static let dubbing = localized(english: "Dubbing", korean: "더빙", japanese: "音声出力", chineseSimplified: "配音")
    static let voiceOutput = localized(english: "Voice Output", korean: "음성 출력", japanese: "音声出力", chineseSimplified: "语音输出")
    static let menuBarTitle = localized(english: "Captions", korean: "자막")
    static let menuBarRunningTitle = localized(english: "Live", korean: "기록 중")
    static let menuBarPausedTitle = localized(english: "Paused", korean: "일시정지")
    static let floatingCaptions = localized(english: "Floating Captions", korean: "플로팅 자막")
    static let showFloatingCaptions = localized(english: "Show Floating Captions", korean: "플로팅 자막 보기")
    static let floatingCaptionPowerOn = localized(english: "ON", korean: "켜짐")
    static let floatingCaptionPowerOff = localized(english: "OFF", korean: "꺼짐")
    static let captionsWindow = localized(english: "Caption Window", korean: "자막 창")
    static let hideFloatingCaptions = localized(english: "Hide Floating Captions", korean: "플로팅 자막 숨기기")
    static let openMainWindow = localized(english: "Open Main Window", korean: "메인 창 열기")
    static let floatingDisplay = localized(english: "Floating Display", korean: "플로팅 표시")
    static let floatingPlacement = localized(english: "Position", korean: "위치", japanese: "位置", chineseSimplified: "位置")
    static let floatingDisplayDescription = localized(
        english: "Choose what appears in the detachable floating caption window.",
        korean: "따로 띄우는 플로팅 자막 창에 표시할 내용을 선택합니다."
    )
    static let floatingTextSize = localized(english: "Floating Text Size", korean: "플로팅 글자 크기")
    static let floatingLineCount = localized(english: "Floating Lines", korean: "플로팅 표시 줄 수")
    static let floatingFontStyle = localized(english: "Font", korean: "글꼴", japanese: "フォント", chineseSimplified: "字体")
    static let floatingTextColor = localized(english: "Text Color", korean: "글자 색", japanese: "文字色", chineseSimplified: "字体颜色")
    static let floatingBackgroundColor = localized(english: "Background Color", korean: "배경 색", japanese: "背景色", chineseSimplified: "背景色")
    static let floatingBackgroundOpacity = localized(english: "Background Opacity", korean: "배경 투명도", japanese: "背景の透明度", chineseSimplified: "背景透明度")
    static let originalOnly = localized(english: "Original", korean: "원문", japanese: "原文", chineseSimplified: "原文")
    static let originalAndTranslation = localized(english: "Original + Translation", korean: "원문 + 번역", japanese: "原文 + 翻訳", chineseSimplified: "原文 + 译文")
    static let translationOnly = localized(english: "Translation", korean: "번역", japanese: "翻訳", chineseSimplified: "译文")
    static let textSizeSmall = localized(english: "Small", korean: "작게", japanese: "小", chineseSimplified: "小")
    static let textSizeMedium = localized(english: "Medium", korean: "보통", japanese: "中", chineseSimplified: "中")
    static let textSizeLarge = localized(english: "Large", korean: "크게", japanese: "大", chineseSimplified: "大")
    static let textSizeExtraLarge = localized(english: "Extra Large", korean: "아주 크게", japanese: "特大", chineseSimplified: "特大")
    static let noFloatingCaptionsYet = localized(
        english: "Live captions will appear here.",
        korean: "실시간 자막이 여기에 표시됩니다."
    )
    static let transcriptLint = localized(english: "Transcript Word Lint", korean: "기록 단어 다듬기", japanese: "記録単語の補正", chineseSimplified: "记录词语修正")
    static let transcriptPolish = localized(english: "Transcript Polish", korean: "기록 다듬기", japanese: "記録を整える", chineseSimplified: "整理记录")
    static let transcriptLintDescription = localized(
        english: "During silence, conservatively fixes transcription words when macOS spelling suggestions are confident. It does not remove repeated sentences or transcript content.",
        korean: "침묵 시간에 macOS 맞춤법 후보가 확실한 기록 단어만 보수적으로 고칩니다. 반복 문장이나 기록 내용은 제거하지 않습니다."
    )
    static let paragraphBreakSilenceInterval = localized(
        english: "Paragraph Break Silence",
        korean: "문단 개행 숨고르기"
    )
    static let paragraphBreakSilenceDescription = localized(
        english: "When speech resumes after this much silence, the transcript starts a new paragraph.",
        korean: "이 시간만큼 말이 멈춘 뒤 다시 시작되면 기록을 새 문단으로 나눕니다."
    )
    static let savedTranscripts = localized(english: "Saved Transcripts", korean: "저장된 기록", japanese: "保存済み記録", chineseSimplified: "已保存记录")
    static let savedTranscriptContent = localized(
        english: "Saved Content",
        korean: "저장 내용"
    )
    static let autoSave = localized(english: "Auto-save", korean: "자동 저장")
    static let autoSaveDescription = localized(
        english: "Transcript text is kept in memory while listening, then saved as a dated plain .txt file with a short content title when capture stops or the app quits.",
        korean: "기록 중에는 메모리에 유지하고, 캡처 중지 또는 앱 종료 직전에 날짜와 짧은 내용 제목이 들어간 일반 .txt 파일로 저장됩니다."
    )
    static let openSaveFolder = localized(
        english: "Open Save Folder",
        korean: "저장 폴더 열기"
    )
    static let openLibrary = localized(
        english: "Open Library",
        korean: "저장소 열기"
    )
    static let manageSavedTranscripts = localized(
        english: "Manage Saved Transcripts",
        korean: "저장된 기록 관리",
        japanese: "保存済み記録を管理",
        chineseSimplified: "管理已保存记录"
    )
    static let librarySummary = localized(
        english: "Review, edit, delete, or open saved transcript files in a focused library window.",
        korean: "저장된 기록 확인, 수정, 삭제, 폴더 열기는 별도 관리 창에서 처리합니다."
    )
    static let savedEmpty = localized(
        english: "Auto-saved transcripts will appear here.",
        korean: "자동 저장된 기록이 여기에 표시됩니다."
    )
    static let noSavedTranscriptSelected = localized(
        english: "Select a saved transcript.",
        korean: "저장된 기록을 선택하세요."
    )
    static let deleteAllSavedTranscripts = localized(
        english: "Delete All",
        korean: "모두 지우기"
    )
    static let deleteAllSavedTranscriptsConfirmation = localized(
        english: "Delete all saved transcript files? This cannot be undone.",
        korean: "저장된 기록 파일을 모두 지울까요? 이 작업은 되돌릴 수 없습니다."
    )
    static let deleteAllSavedTranscriptsHelp = localized(
        english: "Delete every saved transcript file.",
        korean: "저장된 모든 기록 파일을 삭제합니다."
    )
    static let editSaved = localized(english: "Edit Saved", korean: "저장본 편집")
    static let title = localized(english: "Title", korean: "제목")
    static let original = localized(english: "Original", korean: "원문")
    static let originalDescription = localized(
        english: "Incoming speech with live paragraph cleanup.",
        korean: "들어오는 음성을 실시간 문단 정리와 함께 보여줍니다."
    )
    static let transcriptText = localized(english: "Transcript Text", korean: "기록 텍스트")
    static let deleteSavedTranscript = localized(english: "Delete Transcript", korean: "기록 삭제")
    static let translation = localized(english: "Translation", korean: "번역")
    static let translationDescription = localized(
        english: "Translated output aligned to the same transcript flow.",
        korean: "같은 기록 흐름에 맞춰 번역 결과를 정렬해 보여줍니다."
    )
    static let saveEdits = localized(english: "Save Edits", korean: "수정 저장")
    static let liveCaptions = localized(english: "Live Captions", korean: "실시간 기록")
    static let transcriptWorkspace = localized(english: "Transcript Workspace", korean: "실시간 기록")
    static let delete = localized(english: "Delete", korean: "삭제")
    static let waitingForTranscript = localized(
        english: "Captions will appear here.",
        korean: "기록이 시작되면 여기에 표시됩니다."
    )
    static let transcriptSavedToast = localized(
        english: "Transcript saved",
        korean: "기록이 저장되었습니다"
    )
    static let copy = localized(english: "Copy", korean: "복사")
    static let copied = localized(english: "Copied", korean: "복사됨")
    static let appleIntelligenceWritingTools = localized(
        english: "Apple Intelligence Writing Tools",
        korean: "Apple Intelligence 글쓰기 도구"
    )
    static let foundationModelCleanup = localized(
        english: "Clean with Foundation Model",
        korean: "Foundation Model로 전체 정리"
    )
    static let foundationModelCleanupShort = localized(
        english: "Foundation Clean",
        korean: "Foundation 정리"
    )
    static let foundationModelCleanupHelp = localized(
        english: "Use Apple's on-device Foundation Model to clean the selected saved transcript draft. Review the result, then save edits.",
        korean: "Apple 온디바이스 Foundation Model로 선택한 저장 기록 draft 전체를 정리합니다. 결과를 확인한 뒤 수정 저장하세요."
    )
    static let foundationModelCleanupRunning = localized(
        english: "Cleaning transcript with Foundation Model...",
        korean: "Foundation Model로 기록 정리 중..."
    )
    static let foundationModelCleanupComplete = localized(
        english: "Foundation Model cleanup complete. Review and save edits.",
        korean: "Foundation Model 정리가 완료되었습니다. 확인 후 수정 저장하세요."
    )
    static func foundationModelCleanupFailed(_ reason: String) -> String {
        localized(
            english: "Foundation Model cleanup failed: \(reason)",
            korean: "Foundation Model 정리 실패: \(reason)"
        )
    }
    static let foundationModelCleanupFrameworkUnavailable = localized(
        english: "Foundation Models is not available in this build.",
        korean: "이 빌드에서는 Foundation Models를 사용할 수 없습니다."
    )
    static func foundationModelCleanupUnavailable(_ reason: String) -> String {
        localized(
            english: "Foundation Model is unavailable: \(reason)",
            korean: "Foundation Model을 사용할 수 없습니다: \(reason)"
        )
    }
    static func copyTranscriptPane(_ title: String) -> String {
        localized(english: "Copy \(title)", korean: "\(title) 복사")
    }
    static let listening = localized(english: "Listening", korean: "듣는 중")
    static let idle = localized(english: "Idle", korean: "대기")
    static let noCaptionsYet = localized(english: "No captions yet", korean: "아직 기록 없음")
    static let noCaptionsDescription = localized(
        english: "Start capture, play audio on this Mac, and grant Screen Recording, System Audio Recording, and Speech permissions.",
        korean: "캡처를 시작하고 이 Mac에서 오디오를 재생한 뒤 화면 기록, 시스템 오디오 녹음, 음성 인식 권한을 허용하세요."
    )
    static let openPrivacySettings = localized(
        english: "Open Privacy Settings",
        korean: "개인정보 보호 설정 열기"
    )
    static let permissions = localized(english: "Permissions", korean: "권한")
    static let permissionsHelp = localized(
        english: "AirTranslate needs Screen Recording, System Audio Recording, and Speech Recognition permission. After changing privacy settings, quit and relaunch the app.",
        korean: "AirTranslate에는 화면 기록, 시스템 오디오 녹음, 음성 인식 권한이 필요합니다. 개인정보 보호 설정을 변경한 뒤 앱을 종료하고 다시 실행하세요."
    )
    static let checkingScreenPermission = localized(
        english: "Checking screen recording permission...",
        korean: "화면 기록 권한 확인 중..."
    )
    static let checkingMicrophonePermission = localized(
        english: "Checking microphone permission...",
        korean: "마이크 권한 확인 중..."
    )
    static let checkingSpeechPermission = localized(
        english: "Checking speech recognition permission...",
        korean: "음성 인식 권한 확인 중..."
    )
    static func startingCapture(for source: AudioInputSource) -> String {
        switch source {
        case .systemAudio:
            localized(english: "Starting Mac audio capture...", korean: "Mac 오디오 캡처 시작 중...")
        case .microphone:
            localized(english: "Starting microphone capture...", korean: "마이크 캡처 시작 중...")
        }
    }
    static func listeningForSpeech(from source: AudioInputSource) -> String {
        switch source {
        case .systemAudio:
            localized(english: "Listening to Mac audio, waiting for speech...", korean: "Mac 오디오를 듣는 중, 음성을 기다리는 중...")
        case .microphone:
            localized(english: "Listening to microphone, waiting for speech...", korean: "마이크를 듣는 중, 음성을 기다리는 중...")
        }
    }
    static let translating = localized(english: "Translating...", korean: "번역 중...")
    static let translationDisabledForSpeechOnly = localized(
        english: "Translation is off in Transcribe Only mode.",
        korean: "전사만 모드에서는 번역이 꺼져 있습니다."
    )
    static let sameLanguageTranslationUnavailable = localized(
        english: "Choose different source and target languages to translate.",
        korean: "번역하려면 원문과 번역 언어를 다르게 선택하세요."
    )
    static func legacySpeechRecognizerFallback(source: String) -> String {
        localized(
            english: "Using macOS Speech Recognition for \(source).",
            korean: "\(source)에 macOS 음성 인식을 사용합니다.",
            japanese: "\(source)にmacOS音声認識を使用します。",
            chineseSimplified: "正在使用 macOS 语音识别处理\(source)。"
        )
    }
    static let untitledTranscript = localized(english: "Untitled Transcript", korean: "제목 없는 기록")

    static func languageSummary(source: String, target: String) -> String {
        localized(english: "\(source) to \(target)", korean: "\(source) → \(target)")
    }

    static func openAILanguageSummary(target: String) -> String {
        localized(
            english: "Auto-detect to \(target)",
            korean: "자동 감지 → \(target)",
            japanese: "自動検出 → \(target)",
            chineseSimplified: "自动检测 → \(target)"
        )
    }

    static func autoDetectionLanguageChangePaused(current: String, detected: String) -> String {
        localized(
            english: "\(detected) detected after \(current). Waiting for confirmation.",
            korean: "\(current) 다음에 \(detected)이 감지되었습니다. 확인을 기다리는 중입니다.",
            japanese: "\(current)の後に\(detected)を検出しました。確認待ちです。",
            chineseSimplified: "在\(current)之后检测到\(detected)。正在等待确认。"
        )
    }

    static func autoDetectionLanguageChangeMessage(current: String, detected: String, target: String) -> String {
        localized(
            english: "AirTranslate was translating \(current) to \(target), then detected \(detected) after a pause. Start a new session to avoid mixing languages in the same transcript.",
            korean: "AirTranslate가 \(current)에서 \(target)으로 번역하던 중, 잠시 멈춘 뒤 \(detected)이 감지되었습니다. 같은 기록에 언어가 섞이지 않도록 새 세션으로 시작하세요.",
            japanese: "AirTranslateは\(current)から\(target)へ翻訳中でしたが、一時停止後に\(detected)を検出しました。同じ記録で言語が混ざらないよう、新しいセッションを開始してください。",
            chineseSimplified: "AirTranslate 原本正在将\(current)翻译为\(target)，暂停后检测到\(detected)。请开始新会话，避免同一记录中混合语言。"
        )
    }

    static func lineCount(_ count: Int) -> String {
        localized(english: "\(count) lines", korean: "\(count)줄")
    }

    static func seconds(_ seconds: Double) -> String {
        let value = seconds.rounded(.toNearestOrAwayFromZero) == seconds
            ? String(Int(seconds))
            : String(format: "%.1f", seconds)
        return localized(english: "\(value) sec", korean: "\(value)초")
    }

    static func speechModelAvailabilityDetail(source: String, status: String) -> String {
        localized(
            english: "Source: \(source). Local asset: \(status).",
            korean: "원문: \(source). 로컬 자산: \(status)."
        )
    }

    static func translationModelAvailabilityDetail(source: String, target: String, status: String) -> String {
        localized(
            english: "\(source) to \(target). Local asset: \(status).",
            korean: "\(source) → \(target). 로컬 자산: \(status)."
        )
    }

    static func combinedModelAvailabilityDetail(
        model: String,
        speechStatus: String,
        translationStatus: String
    ) -> String {
        localized(
            english: "Speech: \(speechStatus). Translation: \(translationStatus).",
            korean: "음성 인식: \(speechStatus). 번역: \(translationStatus)."
        )
    }

    static func openAIModelAvailabilityDetail(hasAPIKey: Bool) -> String {
        localized(
            english: hasAPIKey ? "OpenAI API key is saved in config.ini." : "Save an OpenAI API key in Settings or config.ini.",
            korean: hasAPIKey ? "OpenAI API 키가 config.ini에 저장되어 있습니다." : "설정 또는 config.ini에 OpenAI API 키를 저장하세요.",
            japanese: hasAPIKey ? "OpenAI APIキーはconfig.iniに保存されています。" : "設定またはconfig.iniにOpenAI APIキーを保存してください。",
            chineseSimplified: hasAPIKey ? "OpenAI API key 已保存在 config.ini。" : "请在设置或 config.ini 中保存 OpenAI API key。"
        )
    }

    static func openAITranslationInstructions(source: String, target: String, scenarioMode: CaptionScenarioMode = .standard) -> String {
        localized(
            english: "Translate live captions from \(source) to \(target). Return only the translated subtitle text. Keep it concise and natural for simultaneous interpretation. Preserve the current meaning even if the sentence is incomplete. Prefer one or two short subtitle lines, and avoid explanations, labels, quotation marks, or markdown. Scenario: \(scenarioMode.subtitleStyleHint)",
            korean: "\(source)에서 \(target)로 실시간 자막을 번역하세요. 번역 자막 텍스트만 반환하세요. 동시통역처럼 간결하고 자연스럽게 쓰고, 문장이 미완성이어도 현재 의미를 유지하세요. 가능하면 짧은 한두 줄 자막으로 만들고 설명, 라벨, 따옴표, 마크다운은 쓰지 마세요. 장면: \(scenarioMode.subtitleStyleHint)",
            japanese: "\(source)から\(target)へライブ字幕として翻訳してください。翻訳字幕のみを返してください。同時通訳向けに簡潔で自然にし、文が未完成でも現在の意味を保ってください。短い1〜2行の字幕を優先し、説明、ラベル、引用符、Markdownは使わないでください。シーン: \(scenarioMode.subtitleStyleHint)",
            chineseSimplified: "把 \(source) 实时字幕翻译成 \(target)。只返回翻译后的字幕文本。按同声传译风格处理，简洁、自然，句子未完成时也保留当前语义。优先输出一到两行短字幕，不要解释、标签、引号或 Markdown。场景：\(scenarioMode.subtitleStyleHint)"
        )
    }

    static func openAIAPIKeychainFailed(_ status: OSStatus) -> String {
        localized(
            english: "Keychain operation failed: \(status).",
            korean: "Keychain 작업 실패: \(status)."
        )
    }

    static let openAIInvalidResponse = localized(
        english: "OpenAI returned an invalid response.",
        korean: "OpenAI가 올바르지 않은 응답을 반환했습니다."
    )
    static let openAIEmptyOutput = localized(
        english: "OpenAI returned no translated text.",
        korean: "OpenAI가 번역 텍스트를 반환하지 않았습니다."
    )
    static let customLLMEndpointInvalid = localized(
        english: "Enter a valid LLM API base URL.",
        korean: "올바른 LLM API Base URL을 입력하세요."
    )
    static let customLLMModelMissing = localized(
        english: "Enter an LLM model name.",
        korean: "LLM 모델 이름을 입력하세요."
    )
    static let openAIAPIConnectionTesting = localized(
        english: "Testing API connection...",
        korean: "API 연결을 테스트하는 중..."
    )
    static let openAIAPIConnectionSucceeded = localized(
        english: "API connection works.",
        korean: "API 연결이 정상입니다."
    )
    static func providerAPIConnectionTesting(_ provider: String) -> String {
        localized(
            english: "Testing \(provider) connection...",
            korean: "\(provider) 연결을 테스트하는 중...",
            japanese: "\(provider) 接続をテスト中...",
            chineseSimplified: "正在测试 \(provider) 连接..."
        )
    }
    static func providerAPIConnectionSucceeded(_ provider: String) -> String {
        localized(
            english: "\(provider) connection works.",
            korean: "\(provider) 연결이 정상입니다.",
            japanese: "\(provider) 接続正常。",
            chineseSimplified: "\(provider) 连接正常。"
        )
    }
    static func openAIAPIConnectionFailed(_ message: String) -> String {
        localized(
            english: "API test failed: \(message)",
            korean: "API 테스트 실패: \(message)"
        )
    }
    static func providerAPIConnectionFailed(_ provider: String, message: String) -> String {
        localized(
            english: "\(provider) test failed: \(message)",
            korean: "\(provider) 테스트 실패: \(message)",
            japanese: "\(provider) テスト失敗: \(message)",
            chineseSimplified: "\(provider) 测试失败：\(message)"
        )
    }
    static let deepgramConnectedStatus = localized(
        english: "Deepgram connected.",
        korean: "Deepgram 연결됨.",
        japanese: "Deepgram接続済み。",
        chineseSimplified: "Deepgram 已连接。"
    )
    static func deepgramReconnectingStatus(attempt: Int) -> String {
        localized(
            english: "Deepgram reconnecting... (\(attempt)/5)",
            korean: "Deepgram 재연결 중... (\(attempt)/5)",
            japanese: "Deepgram再接続中... (\(attempt)/5)",
            chineseSimplified: "Deepgram 正在重连...（\(attempt)/5）"
        )
    }
    static let deepgramAPIConnectionTesting = localized(
        english: "Testing Deepgram connection...",
        korean: "Deepgram 연결을 테스트하는 중..."
    )
    static let deepgramAPIConnectionSucceeded = localized(
        english: "Deepgram connection works.",
        korean: "Deepgram 연결이 정상입니다."
    )
    static func deepgramAPIConnectionFailed(_ message: String) -> String {
        localized(
            english: "Deepgram test failed: \(message)",
            korean: "Deepgram 테스트 실패: \(message)"
        )
    }

    static func openAIRequestFailed(statusCode: Int, message: String?) -> String {
        let detail = message.map { ": \($0)" } ?? ""
        return localized(
            english: "OpenAI request failed (\(statusCode))\(detail)",
            korean: "OpenAI 요청 실패(\(statusCode))\(detail)"
        )
    }

    static func startFailed(_ message: String) -> String {
        localized(english: "Start failed: \(message)", korean: "시작 실패: \(message)")
    }

    static func saveLibraryFailed(_ message: String) -> String {
        localized(
            english: "Could not save transcript library: \(message)",
            korean: "기록 저장소를 저장할 수 없습니다: \(message)"
        )
    }

    static func receivingAudioWaiting(sampleCount: Int, source: AudioInputSource) -> String {
        switch source {
        case .systemAudio:
            localized(
                english: "Receiving Mac audio (\(sampleCount) samples), waiting for speech...",
                korean: "Mac 오디오 수신 중(\(sampleCount) 샘플), 음성을 기다리는 중..."
            )
        case .microphone:
            localized(
                english: "Receiving microphone audio (\(sampleCount) samples), waiting for speech...",
                korean: "마이크 오디오 수신 중(\(sampleCount) 샘플), 음성을 기다리는 중..."
            )
        }
    }

    static func receivingSilentAudio(sampleCount: Int, level: Int, source: AudioInputSource) -> String {
        switch source {
        case .systemAudio:
            localized(
                english: "Receiving silent audio (\(sampleCount) samples, \(level) dB). Check System Audio Recording.",
                korean: "무음 오디오 수신 중(\(sampleCount) 샘플, \(level) dB). 시스템 오디오 녹음 권한을 확인하세요."
            )
        case .microphone:
            localized(
                english: "Receiving quiet microphone audio (\(sampleCount) samples, \(level) dB). Check Microphone permission or input level.",
                korean: "마이크 무음에 가까운 오디오 수신 중(\(sampleCount) 샘플, \(level) dB). 마이크 권한 또는 입력 레벨을 확인하세요."
            )
        }
    }

    static func receivingAudioTranscribing(sampleCount: Int, level: Int, source: AudioInputSource) -> String {
        switch source {
        case .systemAudio:
            localized(
                english: "Receiving Mac audio (\(sampleCount) samples, \(level) dB), transcribing live...",
                korean: "Mac 오디오 수신 중(\(sampleCount) 샘플, \(level) dB), 실시간 기록 중..."
            )
        case .microphone:
            localized(
                english: "Receiving microphone audio (\(sampleCount) samples, \(level) dB), transcribing live...",
                korean: "마이크 오디오 수신 중(\(sampleCount) 샘플, \(level) dB), 실시간 기록 중..."
            )
        }
    }

    static func unsupportedTranslation(source: String, target: String) -> String {
        localized(
            english: "Apple Translation does not support \(source) to \(target).",
            korean: "Apple Translation은 \(source) → \(target) 번역을 지원하지 않습니다."
        )
    }

    static let speechPermissionDenied = localized(
        english: "Speech recognition permission was not granted.",
        korean: "음성 인식 권한이 허용되지 않았습니다."
    )
    static let recognizerUnavailable = localized(
        english: "The selected speech recognizer is unavailable.",
        korean: "선택한 음성 인식기를 사용할 수 없습니다."
    )
    static let screenRecordingNotGranted = localized(
        english: "Screen Recording permission is not active for this signed AirTranslate app. Grant it once, then quit and relaunch AirTranslate.",
        korean: "서명된 AirTranslate 앱에 화면 기록 권한이 활성화되어 있지 않습니다. 한 번 허용한 뒤 AirTranslate를 종료하고 다시 실행하세요."
    )
    static let microphoneNotGranted = localized(
        english: "Microphone permission is not active for this signed AirTranslate app. Grant it once, then quit and relaunch AirTranslate.",
        korean: "서명된 AirTranslate 앱에 마이크 권한이 활성화되어 있지 않습니다. 한 번 허용한 뒤 AirTranslate를 종료하고 다시 실행하세요."
    )
    static let microphoneUnavailable = localized(
        english: "The microphone input could not be started.",
        korean: "마이크 입력을 시작할 수 없습니다."
    )
    static let noActiveDisplay = localized(
        english: "No active display was available for system audio capture.",
        korean: "시스템 오디오 캡처에 사용할 수 있는 활성 디스플레이가 없습니다."
    )

    static func languageTitle(for id: String, fallback: String) -> String {
        switch id {
        case "en-US":
            localized(english: "English", korean: "영어", japanese: "英語", chineseSimplified: "英语", russian: "Английский")
        case "ko-KR":
            localized(english: "Korean", korean: "한국어", japanese: "韓国語", chineseSimplified: "韩语", russian: "Корейский")
        case "ja-JP":
            localized(english: "Japanese", korean: "일본어", japanese: "日本語", chineseSimplified: "日语", russian: "Японский")
        case "zh-CN":
            localized(english: "Chinese Simplified", korean: "중국어 간체", japanese: "簡体字中国語", chineseSimplified: "简体中文", russian: "Китайский упрощенный")
        case "es-ES":
            localized(english: "Spanish", korean: "스페인어", japanese: "スペイン語", chineseSimplified: "西班牙语", russian: "Испанский")
        case "fr-FR":
            localized(english: "French", korean: "프랑스어", japanese: "フランス語", chineseSimplified: "法语", russian: "Французский")
        case "de-DE":
            localized(english: "German", korean: "독일어", japanese: "ドイツ語", chineseSimplified: "德语", russian: "Немецкий")
        case "ru-RU":
            localized(english: "Russian", korean: "러시아어", japanese: "ロシア語", chineseSimplified: "俄语", russian: "Русский")
        case "ar-SA":
            localized(english: "Arabic", korean: "아랍어", japanese: "アラビア語", chineseSimplified: "阿拉伯语", russian: "Арабский")
        case "fa-IR":
            localized(english: "Persian", korean: "페르시아어", japanese: "ペルシア語", chineseSimplified: "波斯语", russian: "Персидский")
        case "id-ID":
            localized(english: "Indonesian", korean: "인도네시아어", japanese: "インドネシア語", chineseSimplified: "印尼语", russian: "Индонезийский")
        default:
            fallback
        }
    }
}
