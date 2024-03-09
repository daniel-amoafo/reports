// Created by Daniel Amoafo on 8/3/2024.

import Foundation

extension CGFloat {

    /// Defines the spacing values as per the figma style guide.
    /// There are to be used to allow the appropriate spacing bewteen items, eg. padding & inset, margin values.
    enum Spacing {
        static let xxsmall: CGFloat = 4.0
        static let xsmall: CGFloat = 8.0
        static let small: CGFloat = 12.0
        static let medium: CGFloat = 16.0
        static let large: CGFloat = 24.0
        static let xlarge: CGFloat = 32.0
    }

    enum Corner {
        static let medium: CGFloat = 12
    }
}
