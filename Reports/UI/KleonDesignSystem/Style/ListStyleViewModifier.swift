// Created by Daniel Amoafo on 9/3/2024.

import SwiftUI

struct ListStyleViewModifier {

    enum RowType {
        case top, middle, bottom, single
    }

    let rowType: RowType
    let showHorizontalRule: Bool
    var color: Color?

    private let cornerRadius = Double(CGFloat.Corner.rd12)

}

// MARK: - View Modifier

extension ListStyleViewModifier: ViewModifier {

    public func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.Spacing.pt12)
            .background(backgroundContent)
    }

    private var backgroundContent: some View {
        ZStack {
            Rectangle()
                .fill(color ?? Color(R.color.surface.secondary))
                .clipShape(
                    .rect(
                        topLeadingRadius: rowType.isTopRounded ? cornerRadius : 0,
                        bottomLeadingRadius: rowType.isBottomRounded ? cornerRadius : 0,
                        bottomTrailingRadius: rowType.isBottomRounded ? cornerRadius : 0,
                        topTrailingRadius: rowType.isTopRounded ? cornerRadius : 0
                    )
                )

            if showHorizontalRule {
                VStack {
                    if rowType == .bottom {
                        HorizontalDivider()
                        Spacer()
                    } else {
                        Spacer()
                        HorizontalDivider()
                    }
                }
            }
        }
    }
}

// MARK: - View Extension

extension View {

    func listRow(
        rowType: ListStyleViewModifier.RowType = .middle,
        showHorizontalRule: Bool = true,
        color: Color? = nil
    ) -> some View {
        modifier(ListStyleViewModifier(
            rowType: rowType,
            showHorizontalRule: showHorizontalRule,
            color: color
        ))
    }

    func listRowTop(showHorizontalRule: Bool = true) -> some View {
        listRow(rowType: .top, showHorizontalRule: showHorizontalRule)
    }

    func listRowBottom(showHorizontalRule: Bool = false) -> some View {
        listRow(rowType: .bottom, showHorizontalRule: showHorizontalRule)
    }

    func listRowSingle() -> some View {
        listRow(rowType: .single, showHorizontalRule: false)
    }

}

// MARK: -

private extension ListStyleViewModifier.RowType {

    var isTopRounded: Bool {
        switch self {
        case .top, .single: return true
        case .middle, .bottom: return false
        }
    }

    var isBottomRounded: Bool {
        switch self {
        case .bottom, .single: return true
        case .top, .middle: return false
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack {
            Text("This is a top row")
                .typography(.title2Emphasized)
            Spacer()
            Image(systemName: "chevron.right")
        }
        .listRowSingle()
        .backgroundShadow()

        VStack(spacing: 0) {
            Text("This is a top row")
                .typography(.title2Emphasized)
                .listRowTop()

            Text("This is a middle row")
                .typography(.title2Emphasized)
                .listRow()

            Text("This is a bottom row")
                .typography(.title2Emphasized)
                .listRowBottom()
        }
        .backgroundShadow()
    }
    .padding(.horizontal, .Spacing.pt16)
}
