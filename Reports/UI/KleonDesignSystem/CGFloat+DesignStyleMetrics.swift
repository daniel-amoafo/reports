// Created by Daniel Amoafo on 8/3/2024.

import Foundation

extension CGFloat {

    /// Defines the spacing values as per the figma style guide.
    /// There are to be used to allow the appropriate spacing bewteen items, eg. padding & inset, margin values.
    enum Spacing {
        static let pt4: CGFloat = 4.0
        static let pt8: CGFloat = 8.0
        static let pt12: CGFloat = 12.0
        static let pt16: CGFloat = 16.0
        static let pt24: CGFloat = 24.0
        static let pt32: CGFloat = 32.0
    }

    enum Corner {
        static let rd8: CGFloat = 8
        static let rd12: CGFloat = 12
    }
}
