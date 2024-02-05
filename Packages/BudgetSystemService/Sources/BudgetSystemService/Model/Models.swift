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
