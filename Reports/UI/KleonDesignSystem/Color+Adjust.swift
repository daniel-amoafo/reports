// Created by Daniel Amoafo on 9/3/2024.

import SwiftUI

extension Color {

    private struct Components {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let opacity: CGFloat
    }

    private var components: Components {
        #if canImport(UIKit)
        typealias NativeColor = UIColor
        #elseif canImport(AppKit)
        typealias NativeColor = NSColor
        #endif

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard NativeColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return .init(red: 0, green: 0, blue: 0, opacity: 0)
        }
        return .init(red: red, green: green, blue: blue, opacity: alpha)
    }

    func lighter(by percentage: CGFloat = 10.0) -> Color {
        return self.adjust(by: abs(percentage) )
    }

    func darker(by percentage: CGFloat = 10.0) -> Color {
        return self.adjust(by: -1 * abs(percentage) )
    }

    func adjust(by percentage: CGFloat = 10.0) -> Color {
        return Color(
            red: min(Double(components.red + percentage/100), 1.0),
            green: min(Double(components.green + percentage/100), 1.0),
            blue: min(Double(components.blue + percentage/100), 1.0),
            opacity: Double(components.opacity)
        )
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let alpha, red, green, blue: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (alpha, red, green, blue) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (alpha, red, green, blue) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (alpha, red, green, blue) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (alpha, red, green, blue) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}
