//
//  Company.swift
//  Interviews
//
//  Created by keloran on 05/12/2025.
//

import Foundation
import SwiftData

@Model
final class Company {
    var id: Int?
    var name: String
    var userId: Int?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Interview.company)
    var interviews: [Interview]? = []

    init(id: Int? = nil, name: String, userId: Int? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.userId = userId
        self.createdAt = createdAt
    }
}
