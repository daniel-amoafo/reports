# Implementation Plan: Income vs. Expense Report

## Phase 1: Data Layer
- [x] Define the data model for the report (aggregating income and expenses per period).
- [x] Implement the database query/service logic to fetch and calculate these totals.

## Phase 2: UI Implementation
- [x] Create the UI component(s) based on the UX requirements (e.g., Table or Chart).
- [x] Integrate the UI component into the existing `ReportFeature` where the `incomeExpensesTable` stub currently resides.

## Phase 3: Testing & Polish
- [x] Write unit tests for the data aggregation logic.
- [x] Ensure the UI adheres to the HIG and project styling.
