// Created by Daniel Amoafo on 6/7/2024.

import Foundation
import SwiftUI

struct ChartNameColor: Equatable {

    let names: [String]

    private let colors: [Color] = [.blue, .green, .orange, .purple, .red, .cyan, .yellow, .indigo]

    init(names rawNames: [String]) {
        self.names = rawNames
            .removingDuplicates()
    }

    func colorFor(_ name: String) -> Color {
        let index = names.firstIndex(of: name) ?? 0
        return colors[index % colors.count]
    }

}
