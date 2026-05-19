import AppKit
import SwiftUI

@main
struct AirTranslateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var session = TranslationSessionStore()
    @State private var menuBarPanelController = MenuBarPanelController()

    var body: some Scene {
        WindowGroup(AppText.appName, id: AirTranslateWindowID.main) {
            ContentView(session: session)
                .frame(minWidth: 900, minHeight: 560)
                .background(MenuBarPanelInstaller(session: session, controller: menuBarPanelController))
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    session.prepareForTermination()
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu(AppText.floatingCaptions) {
                Button(AppText.localized(english: "Bottom Captions", korean: "하단 자막", japanese: "下部字幕", chineseSimplified: "底部字幕")) {
                    FloatingCaptionWindowController.applyPlacement(.lowerThird, session: session)
                    FloatingCaptionWindowController.open(session: session)
                }
                .keyboardShortcut("1", modifiers: [.command, .option])

                Button(AppText.localized(english: "Notch Island", korean: "노치 아일랜드", japanese: "ノッチアイランド", chineseSimplified: "刘海灵动岛")) {
                    FloatingCaptionWindowController.applyPlacement(.notchIsland, session: session)
                    FloatingCaptionWindowController.open(session: session)
                }
                .keyboardShortcut("2", modifiers: [.command, .option])

                Button(AppText.localized(english: "Hide Captions", korean: "자막 숨기기", japanese: "字幕を隠す", chineseSimplified: "隐藏字幕")) {
                    FloatingCaptionWindowController.close()
                }
                .keyboardShortcut("0", modifiers: [.command, .option])
            }
        }

        Window(AppText.floatingCaptions, id: AirTranslateWindowID.floatingCaptions) {
            FloatingCaptionWindowView(session: session)
        }
        .defaultSize(width: 720, height: 170)
        .windowStyle(.plain)
        .restorationBehavior(.disabled)

        Settings {
            SettingsView(session: session)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let appIcon = NSImage(named: "AppIcon") {
            NSApp.applicationIconImage = appIcon
        }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
