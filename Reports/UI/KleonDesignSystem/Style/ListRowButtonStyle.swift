// Created by Daniel Amoafo on 8/3/2024.

import SwiftUI

struct ListRowButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled

    let rowType: ListStyleViewModifier.RowType
    var showHorizontalRule: Bool = true

    private let backgroundColor = Color.Button.list
    private let backgroundColorHighlight = Color.Button.listHighlight

    init(
        rowType: ListStyleViewModifier.RowType = .middle,
        showHorizontalRule: Bool = true
    ) {
        self.rowType = rowType
        self.showHorizontalRule = showHorizontalRule
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundStyle(Color.Text.primary)
            .listRow(
                rowType: rowType,
                showHorizontalRule: showHorizontalRule,
                color: configuration.isPressed ? backgroundColorHighlight : backgroundColor
            )
            .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == ListRowButtonStyle {

    static var listRowTop: Self {
        ListRowButtonStyle(rowType: .top, showHorizontalRule: true)
    }

    static var listRow: Self {
        ListRowButtonStyle()
    }

    static var listRowBottom: Self {
        ListRowButtonStyle(rowType: .bottom, showHorizontalRule: false)
    }

    static var listRowSingle: Self {
        ListRowButtonStyle(rowType: .single, showHorizontalRule: false)
    }
}

private struct PreviewContentRow: View {
    var body: some View {
        HStack(spacing: .Spacing.pt12) {
            Image(.chartPie)
                .resizable()
                .frame(width: 42, height: 42)
            VStack(alignment: .leading) {
                Text("Total Spending")
                    .typography(.headlineEmphasized)
                Text("Aug 23 - Dec 23, Main Budget")
                    .typography(.bodyEmphasized)
            }
            Spacer()
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        Button(action: {}, label: {
            HStack {
                Image(systemName: "note.text")
                Text("Main Budget")
                Spacer()
                Image(systemName: "chevron.right")
            }
        })
        .buttonStyle(.listRowSingle)
        .backgroundShadow()

        VStack(spacing: 0) {
            Button(action: {}, label: {
                PreviewContentRow()
            })
            .buttonStyle(.listRowTop)

            Button(action: {}, label: {
                PreviewContentRow()
            })
            .buttonStyle(.listRow)

            Button(action: {}, label: {
                PreviewContentRow()
            })
            .buttonStyle(.listRowBottom)
        }
        .backgroundShadow()
    }
    .padding(.horizontal)
}
