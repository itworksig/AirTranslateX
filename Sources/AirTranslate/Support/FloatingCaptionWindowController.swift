import AppKit
import SwiftUI

@MainActor
final class FloatingCaptionWindowController: NSObject, NSWindowDelegate {
    static let visibilityDidChangeNotification = Notification.Name("AirTranslateFloatingCaptionVisibilityDidChange")

    static var isOpen: Bool {
        shared.window?.isVisible == true
    }

    static func toggle(session: TranslationSessionStore) {
        isOpen ? close() : open(session: session)
    }

    static func open(session: TranslationSessionStore) {
        shared.open(session: session)
    }

    static func close() {
        shared.close()
    }

    private static let shared = FloatingCaptionWindowController()

    private var window: NSPanel?

    private func open(session: TranslationSessionStore) {
        closeOrphanFloatingWindows()

        let panel = window ?? makeWindow(session: session)
        panel.contentView = NSHostingView(rootView: FloatingCaptionWindowView(session: session))
        configure(panel, placement: session.floatingCaptionPlacement)
        if window == nil {
            positionForFirstOpen(panel, placement: session.floatingCaptionPlacement)
        }
        window = panel
        panel.orderFrontRegardless()
        notifyVisibilityChanged()
    }

    private func close() {
        window?.close()
        window = nil
        notifyVisibilityChanged()
    }

    func windowWillClose(_ notification: Notification) {
        guard notification.object as? NSWindow === window else { return }
        window = nil
        Self.notifyVisibilityChanged()
    }

    private func makeWindow(session: TranslationSessionStore) -> NSPanel {
        let size: NSSize = session.floatingCaptionPlacement == .notchIsland
            ? NSSize(width: 520, height: 96)
            : NSSize(width: 720, height: 170)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = NSHostingView(rootView: FloatingCaptionWindowView(session: session))
        panel.delegate = self
        panel.isReleasedWhenClosed = false
        return panel
    }

    private func configure(_ panel: NSPanel, placement: FloatingCaptionPlacement) {
        panel.identifier = NSUserInterfaceItemIdentifier(AirTranslateWindowID.floatingCaptions)
        panel.title = AppText.floatingCaptions
        panel.level = placement == .notchIsland ? .statusBar : .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
    }

    private func positionForFirstOpen(_ panel: NSPanel, placement: FloatingCaptionPlacement) {
        guard let screen = NSScreen.main else { return }

        let frame = panel.frame
        let x = screen.frame.midX - frame.width / 2
        let y: CGFloat
        switch placement {
        case .lowerThird:
            let visibleFrame = screen.visibleFrame
            y = visibleFrame.minY + min(180, visibleFrame.height * 0.18)
        case .notchIsland:
            y = screen.frame.maxY - frame.height - 6
        }
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func closeOrphanFloatingWindows() {
        for candidate in NSApp.windows where candidate !== window {
            if candidate.identifier?.rawValue == AirTranslateWindowID.floatingCaptions
                || candidate.title == AppText.floatingCaptions {
                candidate.close()
            }
        }
    }

    private func notifyVisibilityChanged() {
        Self.notifyVisibilityChanged()
    }

    private static func notifyVisibilityChanged() {
        NotificationCenter.default.post(name: visibilityDidChangeNotification, object: nil)
    }
}
