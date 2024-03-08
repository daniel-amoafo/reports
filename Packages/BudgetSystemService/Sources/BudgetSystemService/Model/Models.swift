//  Created by Daniel Amoafo on 3/2/2024.
//

import Foundation

public struct Account: Identifiable, Equatable {
    
    public var id: String
    public var name: String
    
    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct BudgetSummary: Identifiable, Equatable {
    /// Budget id
    public let id: String

    /// Budget name
    public let name: String

    /// Date the budget was last modified
    public let lastModifiedOn: String

    /// Budget's first month
    public let firstMonth: String

    /// Budget's last month
    public let lastMonth: String

    public init(
        id: String,
        name: String,
        lastModifiedOn: String,
        firstMonth: String,
        lastMonth: String
    ) {
        self.id = id
        self.name = name
        self.lastModifiedOn = lastModifiedOn
        self.firstMonth = firstMonth
        self.lastMonth = lastMonth
    }
}
