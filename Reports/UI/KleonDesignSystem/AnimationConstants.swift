// Created by Daniel Amoafo on 9/3/2024.

import SwiftUI

struct AnimationConstants {

    static let enterHighlightedStateAnimationDuration: TimeInterval = 0.08

    static let returnToNormalStateAnimationDuration: TimeInterval = 0.25

    static func buttonHighlightAnimation(_ isPressed: Bool) -> Animation {
        // swiftlint:disable:next line_length
        let duration = isPressed ? Self.enterHighlightedStateAnimationDuration : Self.returnToNormalStateAnimationDuration
        return Animation.timingCurve(0.3, 0, 0.5, 1, duration: duration)
    }

}
