//
//  StageMethod.swift
//  Interviews
//
//  Created by keloran on 05/12/2025.
//

import Foundation
import SwiftData

@Model
final class StageMethod {
    var id: Int?
    var method: String

    @Relationship(inverse: \Interview.stageMethod)
    var interviews: [Interview]? = []

    init(id: Int? = nil, method: String) {
        self.id = id
        self.method = method
    }
}
