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
    static let allAccountsName = String(
        localized: "All Accounts",
        comment: "A special account instance indicating all available accounts should be selected for the report."
    )
}
