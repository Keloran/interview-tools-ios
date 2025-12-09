//
//  Stats.swift
//  Interviews
//
//  Created by Keloran on 09/12/2025.
//
import Foundation
import SwiftData

@Model
final class Stats {
    var name: String
    var amount: Int?
    
    init(name: String, amount: Int) {
        self.name = name
        self.amount = amount
    }
}
