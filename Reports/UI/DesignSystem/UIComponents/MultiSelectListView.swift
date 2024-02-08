// Created by Daniel Amoafo on 24/8/2023.

import ComposableArchitecture
import SwiftUI

struct MultiSelectListView<Element: Identifiable & CustomStringConvertible>: View {

    let items: IdentifiedArrayOf<Element>
    @Binding var selected: [Element.ID]

    var body: some View {
        List {
            ForEach(items) { item in
                Button(
                    action: {
                        toggleSelection(item)
                    },
                    label: {
                        HStack {
                            Text(item.description).foregroundColor(.black)
                            Spacer()
                            if selected.contains(item.id) {
                                Image(systemName: "checkmark").foregroundColor(.accentColor)
                            }
                        }
                    }
                ).tag(item.id)
            }
        }
    }

    private func toggleSelection(_ item: Element) {
        if selected.contains(item.id) {
            selected = selected.filter { $0 != item.id }
        } else {
            selected.append(item.id)
        }
    }
}

// MARK: - Preview Area

#Preview {
    ContainerView()
}

struct ContainerView: View {

    @State private var selected: [String] = ["2", "4"]

    private let list: IdentifiedArrayOf<ToDo> = [
        .init(id: "1", name: "First"),
        .init(id: "2", name: "Second"),
        .init(id: "3", name: "Third"),
        .init(id: "4", name: "Fourth"),
    ]

    var body: some View {
        MultiSelectListView<ToDo>(items: list, selected: $selected)
    }
}

private struct ToDo: Identifiable, CustomStringConvertible {
    let id: String
    let name: String
    var description: String { name }
}
