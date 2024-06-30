// Created by Daniel Amoafo on 24/8/2023.

import ComposableArchitecture
import SwiftUI

/// Provides a generic UI solution to select a value / values from a list of items.
///  The list must conform to Identifiable
struct SelectListView<Element: Identifiable & CustomStringConvertible>: View {

    @Environment(\.dismiss) var dismiss

    private let items: IdentifiedArrayOf<Element>
    @Binding private var selected: Set<Element.ID>
    private var mode: SelectionMode
    private var noSelectionAllowed: Bool
    private var typography: Typography
    private let showDoneButton: Bool
    private let rowLayout: SelectListRowLayoutMode

    init(
        items: IdentifiedArrayOf<Element>,
        selectedItems: Binding<Set<Element.ID>>,
        noSelectionAllowed: Bool = false,
        typography: Typography = .title3Emphasized,
        showDoneButton: Bool = true,
        rowLayout: SelectListRowLayoutMode = .standard
    ) {
        self.items = items
        self._selected = selectedItems
        self.mode = .multi
        self.noSelectionAllowed = noSelectionAllowed
        self.typography = typography
        self.showDoneButton = showDoneButton
        self.rowLayout = rowLayout
    }

    init(
        items: IdentifiedArrayOf<Element>,
        selectedItem: Binding<Element.ID?>,
        noSelectionAllowed: Bool = false,
        typography: Typography = .title3Emphasized,
        showDoneButton: Bool = true,
        rowLayout: SelectListRowLayoutMode = .standard
    ) {
        self.items = items
        self.noSelectionAllowed = noSelectionAllowed
        self.typography = typography
        self.showDoneButton = showDoneButton
        self.mode = .single
        self.rowLayout = rowLayout

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
//        NavigationStack {
            ZStack {
                Color.Surface.primary
                    .ignoresSafeArea()
                scrollContent
            }
//        }
    }

    private var isNavRequired: Bool {
        showDoneButton == true
    }
}

private extension SelectListView {

    var scrollContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(items) { item in
                    rowView(for: item)
                }
            }
            .backgroundShadow()
            .padding()
            .toolbar {
                if showDoneButton {
                    Button(AppStrings.doneButtonTitle) {
                        dismiss()
                    }
                    .foregroundStyle(Color.Text.primary)
                }
            }
        }
    }

    func rowView(for item: Element) -> some View {
        Button {
            toggleSelection(item)
        } label: {
            let title = item.description
            let isSelected = selected.contains(item.id)
            switch rowLayout {
            case .standard:
                rowViewStandard(title: title, isSelected: isSelected)
            case .leading:
                rowViewLeading(title: title, isSelected: isSelected)
            }
        }
        .tag(item.id)
        .buttonStyle(listButtonStyle(for: item))
    }

    func rowViewStandard(title: String, isSelected: Bool) -> some View {
        HStack {
            Text(title)
                .typography(typography)
            Spacer()
            rowViewImage(isSelected)
        }
    }

    func rowViewLeading(title: String, isSelected: Bool) -> some View {
        HStack(spacing: .Spacing.pt4) {
            rowViewImage(isSelected)
            Text(title)
                .typography(typography)
            Spacer()
        }
    }

    func rowViewImage(_ isSelected: Bool) -> some View {
        Image(
            systemName: isSelected ? "square.inset.filled" : "square"
        )
        .symbolRenderingMode(.hierarchical)
    }

    func listButtonStyle(for item: Element) -> ListRowButtonStyle {
        guard items.count > 2 else {
            return .listRowSingle
        }

        if item.id == items.first?.id {
            return  .listRowTop
        } else if item.id == items.last?.id {
            return .listRowBottom
        }
        return .listRow
    }

    func toggleSelection(_ item: Element) {
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
                    selected.insert(item.id)
                } else {
                    selected.removeAll()
                    selected.insert(item.id)
                }
            case .multi:
                selected.insert(item.id)
            }
        }
    }
}

enum SelectListRowLayoutMode {
    case standard
    case leading
}

private enum SelectionMode {
    case single
    case multi
}

// MARK: - Preview Area

#Preview {
    ContainerView()
}

private struct ContainerView: View {

    enum SelectionMode {
        case single, multi
    }

    @State private var multiSelect: Set<String> = ["2", "4"]
    @State private var singleSelect: String?
    @State private var noSelectionAllowed: Bool = false
    @State private var showDoneButton: Bool = true
    @State private var mode: SelectionMode = .multi
    @State private var rowLayout: SelectListRowLayoutMode = .standard

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
                        typography: .headlineEmphasized,
                        showDoneButton: showDoneButton,
                        rowLayout: rowLayout
                    )

                case .single:
                    SelectListView(
                        items: list,
                        selectedItem: $singleSelect,
                        noSelectionAllowed: noSelectionAllowed,
                        typography: .headlineEmphasized,
                        showDoneButton: showDoneButton,
                        rowLayout: rowLayout
                    )
                }
            }
            .frame(height: 300)
            .foregroundStyle(Color.Text.primary)

            VStack {
                Divider()
                Text("Settings")
                Picker("Mode", selection: self.$mode) {
                    Text("Multi Selection").tag(SelectionMode.multi)
                    Text("Single").tag(SelectionMode.single)
                }
                .pickerStyle(.segmented)
                HStack {
                    Text("Row Layout")
                    Spacer()
                    Picker("", selection: self.$rowLayout) {
                        Text("Standard").tag(SelectListRowLayoutMode.standard)
                        Text("Leading").tag(SelectListRowLayoutMode.leading)
                    }
                    .pickerStyle(.segmented)
                }
                Toggle("No selection allowed", isOn: $noSelectionAllowed)
                Toggle("Show done button", isOn: $showDoneButton)
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
