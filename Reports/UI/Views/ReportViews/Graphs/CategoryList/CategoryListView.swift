// Created by Daniel Amoafo on 10/6/2024.

import Charts
import ComposableArchitecture
import GRDB
import MoneyCommon
import SwiftUI

struct CategoryListView: View {

    var store: StoreOf<CategoryListFeature>
    @ScaledMetric(relativeTo: .body) private var breadcrumbChevronWidth: CGFloat = 5.0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    Text(Strings.categorized)
                        .typography(.title2Emphasized)
                        .foregroundStyle(Color.Text.secondary)
                    Spacer()
                }
                HStack {
                    Text(store.primaryLabel)
                        .typography(.bodyEmphasized)
                        .foregroundStyle(
                            store.isDisplayingSubCategory ? Color.Text.link : Color.Text.secondary
                        )
                        .onTapGesture {
                            if store.isDisplayingSubCategory {
                                store.send(.delegate(.subTitleTapped), animation: .default)
                            }
                        }
                        .accessibilityAddTraits(store.isDisplayingSubCategory ? .isButton : [])
                        .accessibilityAction {
                            if store.isDisplayingSubCategory {
                                store.send(.delegate(.subTitleTapped), animation: .default)
                            }
                        }
                    if let breadcrumbTitle = store.maybeCategoryName {
                        Image(systemName: "chevron.right")
                            .resizable()
                            .scaledToFit()
                            .frame(width: breadcrumbChevronWidth)
                            .foregroundStyle(Color.Icon.secondary)
                        Text(breadcrumbTitle)
                            .typography(.bodyEmphasized)
                            .foregroundStyle(Color.Text.primary)
                    }
                    Spacer()
                }
            }
            .listRowTop()

            // Category rows
            ForEach(store.listItems) { record in
                Button {
                    store.send(.listRowTapped(id: record.id), animation: .smooth)
                } label: {
                    HStack {
                        BasicChartSymbolShape.circle
                            .foregroundStyle(store.state.colorFor(record.name))
                            .frame(width: 8, height: 8)
                        Text(record.name)
                            .typography(.bodyEmphasized)
                            .foregroundStyle(Color.Text.primary)
                        Spacer()
                        Text(record.total.reportsFormatted)
                            .typography(.bodyEmphasized)
                            .foregroundStyle(Color.Text.primary)
                    }
                }
                .buttonStyle(.listRow)
            }

            // Footer row
            Text("")
                .listRowBottom()
        }
        .backgroundShadow()
    }

}

// MARK: -

private enum Strings {

    static let categorized = String(
        localized: "Categories",
        comment: "title for list of categories for the selected data set"
    )
}

// MARK: - Previews

#Preview("Category Group List") {
    CategoryListView(
        store: .init(
            initialState: .init(
                contentType: .group,
                fromDate: PreviewFactory.fromDate,
                toDate: PreviewFactory.toDate,
                listItems: PreviewFactory.grocerySubcategoryToAny,
                chartNameColor: PreviewFactory.namesForColors,
                categorySelectionMode: .all,
                transactionEntries: Shared(value: nil)
            )
        ) {
            CategoryListFeature()
        }
    )
    .padding()
}

private enum PreviewFactory {

    static let fromDate = Date.iso8601local.date(from: "2024-03-01")!
    static let toDate = Date.iso8601local.date(from: "2024-04-30")!

    static let groupItems: [TrendRecord] = [
        .init(
            date: Date.iso8601local.date(from: "2024-01-01")!,
            name: "Groceries",
            total: Money(minorUnitAmount: 50_00, currency: .AUD),
            recordId: "1"
        ),
        .init(
            date: Date.iso8601local.date(from: "2024-02-01")!,
            name: "Shopping",
            total: Money(minorUnitAmount: 250_49, currency: .AUD),
            recordId: "2"
        ),
        .init(
            date: Date.iso8601local.date(from: "2024-02-01")!,
            name: "Rent",
            total: Money(minorUnitAmount: 199_85, currency: .AUD),
            recordId: "3"
        ),
        .init(
            date: Date.iso8601local.date(from: "2024-03-01")!,
            name: "Dining",
            total: Money(minorUnitAmount: 80_50, currency: .AUD),
            recordId: "4"
        ),
    ]

    static var groupItemsToAny: [AnyCategoryListItem] {
        groupItems.map(AnyCategoryListItem.init)
    }

    static let grocerySubcategory: [TrendRecord] = [
        .init(
            date: Date.iso8601local.date(from: "2024-01-01")!,
            name: "Woolworths",
            total: Money(minorUnitAmount: 20_00, currency: .AUD),
            recordId: "G1"
        ),
        .init(
            date: Date.iso8601local.date(from: "2024-01-28")!,
            name: "Coles",
            total: Money(minorUnitAmount: 30_00, currency: .AUD),
            recordId: "G2"
        ),
    ]

    static var grocerySubcategoryToAny: [AnyCategoryListItem] {
        grocerySubcategory.map(AnyCategoryListItem.init)
    }

    static var namesForColors: ChartNameColor {
        .init(names: grocerySubcategory.map(\.name))
    }
}
