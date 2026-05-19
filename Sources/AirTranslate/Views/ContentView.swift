import SwiftUI

struct ContentView: View {
    @Bindable var session: TranslationSessionStore

    var body: some View {
        ZStack(alignment: .top) {
            NavigationSplitView {
                SidebarView(session: session)
                    .navigationSplitViewColumnWidth(min: 300, ideal: 330, max: 380)
            } detail: {
                CaptionBoardView(session: session)
            }

            if let toastMessage = session.toastMessage {
                ToastMessageView(message: toastMessage)
                    .padding(.top, 18)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.26, dampingFraction: 0.84), value: session.toastSequence)
        .animation(.easeOut(duration: 0.18), value: session.toastMessage)
        .confirmationDialog(
            AppText.autoDetectionLanguageChangeTitle,
            isPresented: autoDetectionLanguageChangeBinding,
            titleVisibility: .visible
        ) {
            Button(AppText.startNewAutoDetectionSession) {
                session.confirmAutoDetectionLanguageChange()
            }

            Button(AppText.keepCurrentAutoDetectionLanguage, role: .cancel) {
                session.keepCurrentAutoDetectionLanguage()
            }
        } message: {
            if let languageChange = session.pendingAutoDetectionLanguageChange {
                Text(
                    AppText.autoDetectionLanguageChangeMessage(
                        current: languageChange.currentLanguage.localizedTitle,
                        detected: languageChange.detectedLanguage.localizedTitle,
                        target: languageChange.targetLanguage.localizedTitle
                    )
                )
            }
        }
    }

    private var autoDetectionLanguageChangeBinding: Binding<Bool> {
        Binding(
            get: {
                session.pendingAutoDetectionLanguageChange != nil
            },
            set: { isPresented in
                if !isPresented {
                    session.keepCurrentAutoDetectionLanguage()
                }
            }
        )
    }
}

private struct ToastMessageView: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "checkmark.circle.fill")
            .font(.callout.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(Color.primary.opacity(0.08))
            }
            .shadow(color: Color.black.opacity(0.16), radius: 14, y: 8)
            .accessibilityAddTraits(.updatesFrequently)
    }
}
