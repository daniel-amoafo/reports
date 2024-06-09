// Created by Daniel Amoafo on 6/6/2024.

import Foundation

extension String {

    static func andAccountIds(_ accountIds: String?) -> String {
        guard let accountIds, accountIds.isNotEmpty else { return " " }
        // expecting a comma , separated list of account ids, convert to a SQL IN expression.
        // e.g. account.id IN ('SomeUUID','AnotherUUID')
        let inValues = "('\(accountIds.replacingOccurrences(of: ",", with: "','"))')"
        return """

        AND account.id IN \(inValues)

        """
    }
}
