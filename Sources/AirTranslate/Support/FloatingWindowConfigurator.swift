import AppKit
import SwiftUI

struct FloatingWindowConfigurator: NSViewRepresentable {
    let preferredContentHeight: CGFloat
    let preferredContentWidth: CGFloat
    let placement: FloatingCaptionPlacement

    func makeNSView(context _: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ view: NSView, context _: Context) {
        DispatchQueue.main.async {
            guard let window = view.window else { return }

            window.identifier = NSUserInterfaceItemIdentifier(AirTranslateWindowID.floatingCaptions)
            window.level = placement == .notchIsland ? .statusBar : .floating
            window.collectionBehavior.insert([.canJoinAllSpaces, .fullScreenAuxiliary])
            window.isMovableByWindowBackground = true
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false

            let minimumSize = NSSize(width: placement == .notchIsland ? 280 : 420, height: preferredContentHeight)
            window.minSize = minimumSize
            if placement == .notchIsland {
                window.setContentSize(NSSize(width: preferredContentWidth, height: preferredContentHeight))
            } else if placement == .topCenter || placement == .lowerFifth {
                window.setContentSize(
                    NSSize(
                        width: min(max(preferredContentWidth, minimumSize.width), maximumWidth(for: window)),
                        height: preferredContentHeight
                    )
                )
            } else if window.contentLayoutRect.height + 1 < preferredContentHeight {
                window.setContentSize(
                    NSSize(
                        width: max(window.contentLayoutRect.width, minimumSize.width),
                        height: preferredContentHeight
                    )
                )
            }
            if placement == .notchIsland {
                pinWindowToNotch(window)
            } else if placement == .topCenter || placement == .lowerFifth {
                pinWindow(window, placement: placement)
            } else {
                keepWindowVisible(window)
            }
        }
    }

    private func keepWindowVisible(_ window: NSWindow) {
        guard let visibleFrame = (window.screen ?? NSScreen.main)?.visibleFrame else { return }

        let inset: CGFloat = 16
        var frame = window.frame
        let maximumWidth = max(window.minSize.width, visibleFrame.width - inset * 2)
        let maximumHeight = max(window.minSize.height, visibleFrame.height - inset * 2)
        frame.size.width = min(max(frame.width, window.minSize.width), maximumWidth)
        frame.size.height = min(max(frame.height, window.minSize.height), maximumHeight)
        frame.origin.x = min(
            max(frame.origin.x, visibleFrame.minX + inset),
            visibleFrame.maxX - frame.width - inset
        )
        frame.origin.y = min(
            max(frame.origin.y, visibleFrame.minY + inset),
            visibleFrame.maxY - frame.height - inset
        )

        if !NSEqualRects(frame, window.frame) {
            window.setFrame(frame, display: true)
        }
    }

    private func pinWindowToNotch(_ window: NSWindow) {
        guard let screen = window.screen ?? NSScreen.main else { return }

        let screenFrame = screen.frame
        var frame = window.frame
        frame.origin.x = screenFrame.midX - frame.width / 2
        if screen.safeAreaInsets.top > 0 {
            frame.origin.y = screenFrame.maxY - frame.height - 4
        } else {
            frame.origin.y = screen.visibleFrame.maxY - frame.height - 8
        }
        window.setFrame(frame, display: true)
    }

    private func pinWindow(_ window: NSWindow, placement: FloatingCaptionPlacement) {
        guard let visibleFrame = (window.screen ?? NSScreen.main)?.visibleFrame else { return }

        var frame = window.frame
        frame.origin.x = visibleFrame.midX - frame.width / 2
        switch placement {
        case .topCenter:
            frame.origin.y = visibleFrame.maxY - frame.height - 14
        case .lowerFifth:
            frame.origin.y = visibleFrame.minY + visibleFrame.height * 0.2
        case .lowerThird:
            frame.origin.y = visibleFrame.minY + min(180, visibleFrame.height * 0.18)
        case .notchIsland:
            frame.origin.y = visibleFrame.maxY - frame.height - 8
        }
        window.setFrame(frame, display: true)
    }

    private func maximumWidth(for window: NSWindow) -> CGFloat {
        guard let visibleFrame = (window.screen ?? NSScreen.main)?.visibleFrame else {
            return preferredContentWidth
        }
        return visibleFrame.width - 32
    }
}
