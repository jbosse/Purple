//
//  Item.swift
//  Purple
//
//  Created by Jimmy Bosse on 9/20/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
