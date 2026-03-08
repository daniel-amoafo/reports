# Product Guidelines

## Design & UX (Apple HIG)
- **Human Interface Guidelines (HIG):** Strictly follow Apple's HIG.
- **Accessibility:** Support Dynamic Type.
- **Hit Targets:** Ensure all interactive elements meet the minimum 44x44pt hit target.
- **Themes:** Support both Light and Dark mode themes.

## Architecture & Coding Standards
- **Modular Design:** The project is split into local Swift Packages to encapsulate domain logic and service integrations:
    - `BudgetProviderKit`: Manages budget-related data and YNAB service interactions.
- **UI Framework:** SwiftUI.
- **Architecture:** Composable Architecture (TCA).
