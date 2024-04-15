// Created by Daniel Amoafo on 24/8/2023.

import ComposableArchitecture
import SwiftUI

struct SelectListView<Element: Identifiable & CustomStringConvertible>: View {

    private let items: IdentifiedArrayOf<Element>
    @Binding private var selected: [Element.ID]
    private var mode: SelectListViewSelectionMode
    private var noSelectionAllowed: Bool
    private var typography: Typography

    init(
        items: IdentifiedArrayOf<Element>,
        selectedItems: Binding<[Element.ID]>,
        noSelectionAllowed: Bool = false,
        typography: Typography = .title3Emphasized
    ) {
        self.items = items
        self._selected = selectedItems
        self.mode = .multi
        self.noSelectionAllowed = noSelectionAllowed
        self.typography = typography
    }

    init(
        items: IdentifiedArrayOf<Element>,
        selectedItem: Binding<Element.ID?>,
        noSelectionAllowed: Bool = false,
        typography: Typography = .title3Emphasized
    ) {
        self.items = items
        self.noSelectionAllowed = noSelectionAllowed
        self.typography = typography
        self.mode = .single

        // creates selected binding using the singleItem binding
        // as the backing source binding provider
        self._selected = Binding(
            get: {
                guard let value = selectedItem.wrappedValue else {
                    return []
                }
                return [value]
            },
            set: { newValue in
                if let singleSelected = newValue.first {
                    selectedItem.wrappedValue = singleSelected
                } else {
                    selectedItem.wrappedValue = nil
                }
            }
        )
    }

    var body: some View {
        List {
            ForEach(items) { item in
                Button(
                    action: {
                        toggleSelection(item)
                    },
                    label: {
                        HStack {
                            Text(item.description)
                                .typography(typography)
                            Spacer()
                            Image(
                                systemName: selected.contains(item.id) ? "square.inset.filled" : "square"
                            )
                            .symbolRenderingMode(.hierarchical)
                        }
                    }
                )
                .tag(item.id)
            }
        }
    }

    private func toggleSelection(_ item: Element) {
        if selected.contains(item.id) {
            if selected.count == 1 && noSelectionAllowed == false {
                // only one item selected and not allowing more to be selected
                return
            }
            selected = selected.filter { $0 != item.id }
        } else {
            switch mode {
            case .single:
                assert(selected.count < 2)
                if selected.isEmpty {
                    selected.append(item.id)
                } else {
                    selected[0] = item.id
                }
            case .multi:
                selected.append(item.id)
            }
        }
    }
}

enum SelectListViewSelectionMode {
    case single
    case multi
}

// MARK: - Preview Area

#Preview {
    ContainerView()
}

struct ContainerView: View {

    enum SelectionMode {
        case single, multi
    }

    @State private var multiSelect: [String] = ["2", "4"]
    @State private var singleSelect: String?
    @State private var noSelectionAllowed: Bool = false
    @State private var mode: SelectionMode = .multi

    private let list: IdentifiedArrayOf<Item> = [
        .init(id: "1", name: "First"),
        .init(id: "2", name: "Second"),
        .init(id: "3", name: "Third"),
        .init(id: "4", name: "Fourth"),
    ]

    var body: some View {
        VStack {
            Group {
                switch mode {
                case .multi:
                    SelectListView<Item>(
                        items: list,
                        selectedItems: $multiSelect,
                        noSelectionAllowed: noSelectionAllowed,
                        typography: .headlineEmphasized
                    )

                case .single:
                    SelectListView(
                        items: list,
                        selectedItem: $singleSelect,
                        noSelectionAllowed: noSelectionAllowed,
                        typography: .headlineEmphasized
                    )
                }
            }
            .frame(height: 300)
            .foregroundColor(Color(R.color.colors.text.primary))

            VStack {
                Divider()
                Text("Settings")
                Picker("Mode", selection: self.$mode) {
                    Text("Multi Selection").tag(SelectionMode.multi)
                    Text("Single").tag(SelectionMode.single)
                }
                .pickerStyle(.segmented)
                Toggle("No selection allowed", isOn: $noSelectionAllowed)
                VStack {
                    Text("Selected Values:")
                        .typography(.bodyEmphasized)
                    switch mode {
                    case .multi:
                        Text(multiSelect.compactMap({ list[id: $0] }).map(\.name).joined(separator: ", "))

                    case .single:
                        if let singleSelect {
                            Text([singleSelect].compactMap({ list[id: $0] }).map(\.name).joined(separator: ", "))
                        }
                    }
                }
                .listRowSingle()
            }
            .padding(.horizontal)
        }
    }
}

// A model object representing elements to select from
private struct Item: Identifiable, CustomStringConvertible {
    let id: String
    let name: String
    var description: String { name }
}
