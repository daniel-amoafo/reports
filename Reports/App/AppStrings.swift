// Created by Daniel Amoafo on 29/4/2024.

import Foundation

// Defines localized strings that repeat in meaning and use in multiple places in the app here
enum AppStrings {
    static let doneButtonTitle = String(localized: "Done", comment: "Button title to dismiss the current screen.")
    static let cancelButtonTitle = String(
        localized: "Cancel", comment: "Button title for a cancel action."
    )
    static let saveButtonTitle = String(
        localized: "Save",
        comment: "Button title for a save action."
    )
    static let okButtonTitle = String(
        localized: "OK",
        comment: "Button title for an OK action."
    )
    static let allAccountsTitle = String(
        localized: "All Accounts",
        comment: "A label indicating all available accounts will be selected for the report."
    )

    static let someAccountsTitle = String(
        localized: "Some Accounts",
        comment: "A label indicating a few accounts have been selected for the report."
    )

    static let someCategoriesTitle = String(
        localized: "Some Categories",
        comment: "A label indicating a few categories have been selected for the report."
    )

    static let allCategoriesTitle = String(
        localized: "All Categories",
        comment: "The collective name for top level category groups"
    )

    static let selectAll = String(
        localized: "Select All",
        comment: "button to select all accounts"
    )
    static let deselectAll = String(
        localized: "Select None",
        comment: "button to select deselect all accounts"
    )
}
