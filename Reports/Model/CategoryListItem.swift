// Created by Daniel Amoafo on 10/6/2024.

import Dependencies
import Foundation
import MoneyCommon

// MARK: -

protocol CategoryListItem: Identifiable, Equatable {
    var id: String { get }
    var name: String { get }
    var total: Money { get }
}

// MARK: -

struct AnyCategoryListItem: CategoryListItem, Equatable {

    private let base: any CategoryListItem

    init(_ base: any CategoryListItem) {
        self.base = base
    }

    var id: String { base.id }

    var name: String { base.name }

    var total: Money { base.total }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.isEqual(to: rhs)
    }

    func isEqual(to other: any CategoryListItem) -> Bool {
        guard type(of: self) == type(of: other) else { return false }
        return self.id == other.id
    }

}

// MARK: - Conforming Types

extension TrendRecord: CategoryListItem {}

extension CategoryRecord: CategoryListItem {}
