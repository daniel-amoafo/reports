// Created by Daniel Amoafo on 29/5/2024.

import Foundation
import SwiftUI

struct IdentifiableIndices<Base: RandomAccessCollection>
where Base.Element: Identifiable, Base.Index: Sendable, Base.Element.ID: Sendable {

    typealias Index = Base.Index

    struct Element: Identifiable, Sendable {
        let id: Base.Element.ID
        let rawValue: Index
    }

    fileprivate var base: Base
}

extension ForEach where ID == Data.Element.ID,
                        Data.Element: Identifiable,
                        Content: View {
    init<T>(
        _ indices: Data,
        @ViewBuilder content: @escaping (Data.Index) -> Content
    ) where Data == IdentifiableIndices<T> {
        self.init(indices) { index in
            content(index.rawValue)
        }
    }
}

extension ForEach where ID == Data.Element.ID,
                        Data.Element: Identifiable,
                        Content: View {
    init<T>(
        _ data: Binding<T>,
        @ViewBuilder content: @escaping (T.Index, Binding<T.Element>) -> Content
    ) where Data == IdentifiableIndices<T>, T: MutableCollection {
        self.init(data.wrappedValue.identifiableIndices) { index in
            content(
                index.rawValue,
                Binding(
    get: { data.wrappedValue[index.rawValue] },
    set: { data.wrappedValue[index.rawValue] = $0 }
)
            )
        }
    }
}

extension IdentifiableIndices: RandomAccessCollection {
    var startIndex: Index { base.startIndex }
    var endIndex: Index { base.endIndex }

    subscript(position: Index) -> Element {
    Element(id: base[position].id, rawValue: position)
}

    func index(before index: Index) -> Index {
        base.index(before: index)
    }

    func index(after index: Index) -> Index {
        base.index(after: index)
    }
}

extension RandomAccessCollection
where Element: Identifiable, Element.ID: Sendable, Index: Sendable {
    var identifiableIndices: IdentifiableIndices<Self> {
        IdentifiableIndices(base: self)
    }
}
