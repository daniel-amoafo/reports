// Created by Daniel Amoafo on 8/5/2024.

import Foundation

public extension ProcessInfo {

    var isSwiftUIPreview: Bool {
        environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
