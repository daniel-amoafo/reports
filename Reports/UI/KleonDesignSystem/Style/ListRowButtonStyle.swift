// Created by Daniel Amoafo on 8/3/2024.

import SwiftUI

struct ListRowButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled

    let rowType: ListStyleViewModifier.RowType
    var showHorizontalRule: Bool = true

    private let backgroundColor = Color(R.color.colors.button.list)
    private let backgroundColorHighlight = Color(R.color.colors.button.listHighlight)

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
            .foregroundColor(Color(R.color.colors.text.primary))
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

    static var listRowMiddle: Self {
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
        HStack(spacing: .Spacing.small) {
            Image(R.image.pieChart)
                .resizable()
                .frame(width: 42, height: 42)
            VStack(alignment: .leading) {
                Text("Spending Trends")
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

        VStack(spacing: 0) {
            Button(action: {}, label: {
                PreviewContentRow()
            })
            .buttonStyle(.listRowTop)

            Button(action: {}, label: {
                PreviewContentRow()
            })
            .buttonStyle(.listRowMiddle)

            Button(action: {}, label: {
                PreviewContentRow()
            })
            .buttonStyle(.listRowBottom)
        }
    }
    .padding(.horizontal)
}
