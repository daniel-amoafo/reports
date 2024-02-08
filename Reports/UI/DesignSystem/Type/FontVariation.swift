// Created by Daniel Amoafo on 24/6/2023.

import CoreText

struct Axis {

    public let id: Int
    public let name: String

    public let minValue: CGFloat
    public let maxValue: CGFloat

    public let defaultValue: CGFloat

    public var value: CGFloat

    init(attributes: [AttrubuteName: Any]) {
        self.id = attributes[.id] as? Int ?? 0
        self.name = attributes[.name] as? String ?? "unknown"

        self.minValue = attributes[.minValue] as? CGFloat ?? 0.0
        self.maxValue = attributes[.maxValue] as? CGFloat ?? 0.0

        self.defaultValue = attributes[.defaultValue] as? CGFloat ?? 0.0
        self.value = defaultValue
    }

}

extension Axis {

    // Variable font attributes as defined in CoreText
    enum AttrubuteName: String {
        case id = "NSCTVariationAxisIdentifier"
        case name = "NSCTVariationAxisName"
        case maxValue = "NSCTVariationAxisMaximumValue"
        case minValue = "NSCTVariationAxisMinimumValue"
        case defaultValue = "NSCTVariationAxisDefaultValue"
    }

    // Variation id values
    enum Variation: Int {
        case weight = 2003265652
        case width = 2003072104
        case opticalSize = 1869640570
        case grad = 1196572996
        case slant = 1936486004
        case xtra = 1481921089
        case xopq = 1481592913
        case yopq = 1498370129
        case ytlc = 1498696771
        case ytuc = 1498699075
        case ytas = 1498693971
        case ytde = 1498694725
        case ytfi = 1498695241
    }
}
