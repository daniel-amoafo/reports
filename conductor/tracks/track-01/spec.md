# Specification: Income vs. Expense Report

## Objective
Implement the Income vs. Expense report to visualize and compare total income against total expenses over a selected period.

## UX/Design
The report follows a clean, card-based layout with a clear hierarchy of information.

### Header
- **Background:** Gradient (Purple Dusk: `#6418c3` to `#a700a3`).
- **Title:** "Financial Report" (White, Bold).
- **Subtitle:** "Track your income & expenses" (Light blue).

### Filter & Controls
- **Date Filter:** A button/dropdown at the top to select the reporting period (e.g., "Last 30 Days").
- **Chart Toggle:** Segmented control to switch between **Bar** and **Line** chart views for the Trend Analysis.

### Summary Cards
Each card includes a title, total amount, and a trend indicator.
- **Total Income:**
  - Icon: Green background with an upward arrow.
  - Data: Total amount (e.g., "$6,550.00") and percentage increase (e.g., "↑ 8.2% vs last period").
- **Total Expenses:**
  - Icon: Red background with a downward arrow.
  - Data: Total amount (e.g., "$2,465.00") and percentage decrease (e.g., "↓ 3.1% vs last period").
- **Net Balance:**
  - Icon: Blue background with a wallet/balance icon.
  - Data: Net total (e.g., "$4,085.00").

### Trend Analysis
- **Chart:** A line or bar chart visualizing **Income** (Green: `#10b981`) and **Expense** (Red: `#ef4444`) over the selected time axis.
- **X-Axis:** Time intervals (e.g., dates).
- **Y-Axis:** Monetary values.
- **Legend:** Located at the bottom of the chart area.

### Transactions List
- **Header:** "Transactions" title with an "All Transactions" action button.
- **List Items:**
  - **Icon:** Category-specific icon with a color-coded circular background (Light Green for Income, Light Red for Expense).
  - **Text:** Category name (Bold) followed by a short description or note.
  - **Date:** Transaction date (Grey).
  - **Amount:** Color-coded value (Green with '+' for income, Red with '-' for expense).

## Data Requirements
- **Aggregated Totals:** Sum of income and expenses for the current and previous periods to calculate percentage changes.
- **Time-Series Data:** Arrays of income and expense totals grouped by the appropriate time interval (day/week/month) for the chart.
- **Transaction Details:** Fetching the most recent transactions with metadata (category, note, date, amount, type).
