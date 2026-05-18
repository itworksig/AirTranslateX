import AppKit
import SwiftUI

enum ColorHex {
    static func color(from hex: String, fallback: Color) -> Color {
        guard let nsColor = nsColor(from: hex) else { return fallback }
        return Color(nsColor: nsColor)
    }

    static func hex(from color: Color, fallback: String) -> String {
        let nsColor = NSColor(color)
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else { return fallback }

        let red = Int((rgbColor.redComponent * 255).rounded())
        let green = Int((rgbColor.greenComponent * 255).rounded())
        let blue = Int((rgbColor.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    private static func nsColor(from hex: String) -> NSColor? {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#").union(.whitespacesAndNewlines))
        guard cleaned.count == 6, let value = Int(cleaned, radix: 16) else {
            return nil
        }

        let red = CGFloat((value >> 16) & 0xFF) / 255
        let green = CGFloat((value >> 8) & 0xFF) / 255
        let blue = CGFloat(value & 0xFF) / 255
        return NSColor(srgbRed: red, green: green, blue: blue, alpha: 1)
    }
}

