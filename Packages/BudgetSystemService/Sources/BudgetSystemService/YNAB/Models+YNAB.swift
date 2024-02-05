// Created by Daniel Amoafo on 4/2/2024.

import Foundation
import SwiftYNAB

extension Account {
    
    init(ynabAccount: SwiftYNAB.Account) {
        self.id = ynabAccount.id
        self.name = ynabAccount.name
    }
}
