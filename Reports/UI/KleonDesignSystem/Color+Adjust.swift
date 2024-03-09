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
}
