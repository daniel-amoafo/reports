// Created by Daniel Amoafo on 21/6/2024.

import ComposableArchitecture
import SwiftUI

 struct OnboardingView: View {

     @Bindable var store: StoreOf<OnboardingViewFeature>

     @State private var showSummariesPopup = false

    var body: some View {
        ZStack {
            KleonGradient.onboarding()
                .ignoresSafeArea()
            ScrollView {
                VStack {
                    Image(.onboardingChart)
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        HorizontalDivider(color: Color.Onboarding.stop1)
                        HorizontalDivider(color: Color.Onboarding.stop4)
                    }
                    .padding(.horizontal)

                    budgetSummariesSelection
                }
            }
        }
        .task {
            store.send(.onAppear)
        }
    }
 }

private extension OnboardingView {

    var budgetSummariesSelection: some View {
        VStack(spacing: .Spacing.pt12) {
            if store.isLoading {
                ProgressView()
            } else {
                Text(Strings.instructionsTitle)
                    .typography(.title3Emphasized)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal)

                budgetSelectionButton

                Button(Strings.submitTitle) {
                    store.send(.submitTapped)
                }
                .buttonStyle(.kleonPrimary)
                .disabled(store.submitDisabled)
                .containerRelativeFrame(.horizontal) { length, _ in
                    length * 0.6
                }
            }
        }
    }

    var budgetSelectionButton: some View {
        Button {
            showSummariesPopup = true
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: .Spacing.pt4) {
                    ZStack {
                        // hidden text to keep chevron arrow and text
                        // at correct alignment.
                        Text("Place holder")
                            .typography(.title2Emphasized)
                            .hidden()
                        Text(store.displayedBudgetId)
                            .typography(.title2Emphasized)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(Color.white)
                        .fontWeight(.bold)
                }
                .containerRelativeFrame(.horizontal) { length, _ in
                    length * 0.7
                }

                HorizontalDivider(color: .white, height: 1.0)
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length * 0.7
                    }
            }
        }
        .popover(isPresented: $showSummariesPopup) {
            BudgetSelectListView(
                summaries: store.budgetSummaries.elements,
                selected: $store.selectedBudgetId.sending(\.didSelectBudgetId)
            ) { id in
                store.send(.didSelectBudgetId(id))
                showSummariesPopup = false
            }
            .presentationBackground(.ultraThinMaterial)
            .presentationCompactAdaptation(.popover)
        }
    }
}

import BudgetSystemService

struct BudgetSelectListView: View {

    let summaries: [BudgetSummary]
    @Binding var selected: String?
    let performDidSelect: (String) -> Void

    var body: some View {
        VStack(spacing: .Spacing.pt8) {
            ForEach(summaries) { item in
                Button {
                    performDidSelect(item.id)
                } label: {
                    HStack {
                        Text(item.name)
                            .typography(.bodyEmphasized)
                        Spacer()
                        Image(
                            systemName: selected == item.id ? "square.inset.filled" : "square"
                        )
                        .symbolRenderingMode(.hierarchical)
                    }
                    .contentShape(.interaction, Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
}

private enum Strings {

    static let instructionsTitle = String(
        localized: "Select a budget to get started",
        comment: "Text explaining a budget needs to be selected to continue"
    )

    static let submitTitle = String(localized: "Let's Go", comment: "Submit button title")
}

// MARK: - Previews

 #Preview {
     OnboardingView(store: .init(initialState: .init()) {
         OnboardingViewFeature()
     })
 }

#Preview("Popover List") {
    VStack {
        BudgetSelectListView(
            summaries: IdentifiedArrayOf<BudgetSummary>.mocks.elements,
            selected: .constant(nil)
        ) {
            debugPrint("did select \($0)")
        }
    }
}
