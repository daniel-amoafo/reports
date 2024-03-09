// Created by Daniel Amoafo on 8/3/2024.

import ComposableArchitecture
import SwiftUI

@Reducer
struct Home {

    struct State: Equatable {

    }

    enum Action {

    }

}

private enum Strings {
    static let title = String(localized: "Budget Reports", comment: "The home screen main title")
}

struct HomeView: View {
    var body: some View {
        ZStack {
            Color(R.color.colors.surface.primary)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                Text(Strings.title)
                    .typography(.title1Emphasized)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: .Spacing.large) {
                        // New Report Section
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: .Spacing.small) {
                                ForEach(0..<10) {
                                    Text("Item \($0)")
                                        .typography(.title2Emphasized)
                                        .foregroundStyle(.white)
                                        .frame(width: 140, height: 166)
                                        .background(.red)
                                }
                            }
                        }
                        .contentMargins(.leading, .Spacing.medium)
                        .padding(.top, .Spacing.large)

                        // Select Budget Picker Section
                        Button(action: {

                        }, label: {
                            HStack {
                                Image(systemName: "note.text")
                                Text("Main Budget")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                        })
                        .buttonStyle(.listRowSingle)
                        .padding(.horizontal, .Spacing.medium)

                        // Saved Reports
                        VStack(spacing: 0) {
                            HStack {
                                Text("Saved Reports")
                                    .typography(.title3Emphasized)
                                    .foregroundColor(Color(R.color.colors.text.secondary))
                                Spacer()
                            }
                            .listRowTop(showHorizontalRule: false)

                            Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
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
                            })
                            .buttonStyle(.listRowMiddle)

                            GeometryReader { geometry in
                                HStack {
                                    Button("View All") {

                                    }
                                    .buttonStyle(.kleonPrimary)
                                }
                                .frame(width: geometry.size.width * 0.6)
                                .listRowBottom()
                            }
                        }
                        .padding(.horizontal, .Spacing.medium)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    HomeView()
}
