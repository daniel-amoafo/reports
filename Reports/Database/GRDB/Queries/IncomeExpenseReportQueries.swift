// Created by Daniel Amoafo on 3/3/2026.

import BudgetSystemService
import Dependencies
import Foundation
import GRDB
import MoneyCommon

enum IncomeExpenseReportQueries {

    static let logger = LogFactory.create(Self.self)

    static func fetchReportData(
        budgetId: String,
        fromDate: Date,
        toDate: Date,
        accountIds: String?,
        categoryIds: String?,
        grdb: GRDBDatabase
    ) -> IncomeExpenseReportData {

        let currencyCode = (try? grdb.fetchRecord(
            BudgetSummary.self,
            request: BudgetSummary.filter(id: budgetId)
        ))?.currencyCode ?? "AUD"
        let currency = Currency.iso4217Currency(for: currencyCode) ?? .AUD

        // Calculate current period data
        let currentTrends = fetchTrends(
            budgetId: budgetId,
            fromDate: fromDate,
            toDate: toDate,
            accountIds: accountIds,
            categoryIds: categoryIds,
            grdb: grdb
        )

        let incomeTrends = currentTrends.filter { $0.name == "Income" }
        let expenseTrends = currentTrends.filter { $0.name == "Expense" }

        let totalIncome = incomeTrends.reduce(Money.zero(currency)) { $0 + $1.total }
        let totalExpenses = expenseTrends.reduce(Money.zero(currency)) { $0 + $1.total }
        let netBalance = totalIncome - totalExpenses

        // Calculate previous period for trends
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: fromDate, to: toDate)
        let monthsCount = max(1, (components.month ?? 0) + 1)

        let previousFromDate = fromDate.advanceMonths(by: -monthsCount)
        let previousToDate = toDate.advanceMonths(by: -monthsCount)

        let previousTrends = fetchTrends(
            budgetId: budgetId,
            fromDate: previousFromDate,
            toDate: previousToDate,
            accountIds: accountIds,
            categoryIds: categoryIds,
            grdb: grdb
        )

        let prevTotalIncome = previousTrends.filter { $0.name == "Income" }
            .reduce(Money.zero(currency)) { $0 + $1.total }
        let prevTotalExpenses = previousTrends.filter { $0.name == "Expense" }
            .reduce(Money.zero(currency)) { $0 + $1.total }

        let incomePercentageChange = calculatePercentageChange(current: totalIncome, previous: prevTotalIncome)
        let expensePercentageChange = calculatePercentageChange(current: totalExpenses, previous: prevTotalExpenses)

        return IncomeExpenseReportData(
            incomeTrends: incomeTrends,
            expenseTrends: expenseTrends,
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            netBalance: netBalance,
            incomePercentageChange: incomePercentageChange,
            expensePercentageChange: expensePercentageChange
        )
    }

    private static func fetchTrends(
        budgetId: String,
        fromDate: Date,
        toDate: Date,
        accountIds: String?,
        categoryIds: String?,
        grdb: GRDBDatabase
    ) -> [TrendRecord] {

        let incomeSQL = """
        SELECT
            date(strftime('%Y-%m-01', transactionEntry.date)) as year_month,
            'Income' as name,
            SUM(amount) as total,
            budgetSummary.currencyCode,
            '' as id
        FROM transactionEntry
        INNER JOIN account on account.id = transactionEntry.accountId
        INNER JOIN budgetSummary on budgetSummary.id = transactionEntry.budgetSummaryId
        WHERE date BETWEEN :startDate AND :finishDate
        AND account.onBudget = 1
        AND transactionEntry.deleted <> 1
        AND transactionEntry.budgetSummaryId = :budgetId
        AND amount > 0
        """ +
        .andAccountIds(accountIds) +
        """
        GROUP BY year_month
        """

        let expenseSQL = """
        SELECT
            date(strftime('%Y-%m-01', transactionEntry.date)) as year_month,
            'Expense' as name,
            SUM(amount) * -1 as total,
            budgetSummary.currencyCode,
            '' as id
        FROM transactionEntry
        INNER JOIN account on account.id = transactionEntry.accountId
        INNER JOIN budgetSummary on budgetSummary.id = transactionEntry.budgetSummaryId
        WHERE date BETWEEN :startDate AND :finishDate
        AND account.onBudget = 1
        AND transactionEntry.deleted <> 1
        AND transactionEntry.budgetSummaryId = :budgetId
        AND amount < 0
        """ +
        .andAccountIds(accountIds) +
        .andCategoryIds(categoryIds) +
        """
        GROUP BY year_month
        """

        let fullSQL = "\(incomeSQL) UNION ALL \(expenseSQL) ORDER BY year_month ASC"

        let arguments: [String: any DatabaseValueConvertible] = [
            "startDate": Date.iso8601local.string(from: fromDate),
            "finishDate": Date.iso8601local.string(from: toDate),
            "budgetId": budgetId,
        ]

        do {
            let builder = GRDBDatabase.RecordSQLBuilder(
                record: TrendRecord.self,
                sql: fullSQL,
                arguments: arguments
            )
            return try grdb.fetchRecords(builder: builder)
        } catch {
            logger.error("Failed to fetch income/expense trends: \(error)")
            return []
        }
    }

    private static func calculatePercentageChange(current: Money, previous: Money) -> Double? {
        guard previous.centsAmount > 0 else { return nil }
        let diff = current.centsAmount - previous.centsAmount
        return (Double(diff) / Double(previous.centsAmount)) * 100.0
    }
}
