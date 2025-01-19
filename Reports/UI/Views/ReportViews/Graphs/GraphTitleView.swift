// Created by Daniel Amoafo on 19/1/2025.

import SwiftUI

struct GraphTitleView: View {

    let title: String
    let listSubTitle: String
    let selected: (name: String, buttonAction: () -> Void)?

    var body: some View {
        VStack {
            Text(title)
                .typography(.title3Emphasized)
                .foregroundStyle(Color.Text.secondary)
            Group {
                if let selected {
                    Button {
                        selected.buttonAction()
                    } label: {
                        HStack {
                            Text("⬅️")
                            Text(selected.name)
                        }
                    }
                } else {
                    Text(listSubTitle)
                }
            }
            .font(Typography.subheadlineEmphasized.font)
            .foregroundStyle(Color.Text.primary)
        }
    }
}

#Preview {
    GraphTitleView(
        title: "Graph Name",
        listSubTitle: "Some Categories",
        selected: ("Selected", { print("Subtitle Tapped") })
    )
}
