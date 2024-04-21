// Created by Daniel Amoafo on 14/4/2024.

import SwiftUI

struct ViewRectReader {
    @Binding var rect: CGRect
    let coordinateSpace: CoordinateSpace

    init(rect: Binding<CGRect>, coordinateSpace: CoordinateSpace) {
        _rect = rect
        self.coordinateSpace = coordinateSpace
    }
}

// MARK: - Preference keys

private struct RectPreferenceKey: PreferenceKey {
    typealias Value = CGRect
    static var defaultValue: Value = .zero

    static func reduce(value _: inout Value, nextValue: () -> Value) {
        _ = nextValue()
    }
}

// MARK: - View Modifier

extension ViewRectReader: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: RectPreferenceKey.self, value: proxy.frame(in: coordinateSpace))
                }
            )
            .onPreferenceChange(RectPreferenceKey.self) { preferences in
                DispatchQueue.main.async {
                    self.rect = preferences
                }
            }
    }
}

// MARK: - View Extension

/// Read view's rect from the coordinate space.
///
/// - Parameters:
///   - to: A binding variable to store the view's rect
///   - coordinateSpace: Default value is global, which will read the rect on the screen regardless the safe area.
public extension View {

    func readRect(_ rect: Binding<CGRect>, coordinateSpace: CoordinateSpace = .global) -> some View {
        self.modifier(ViewRectReader(rect: rect, coordinateSpace: coordinateSpace))
    }
}
