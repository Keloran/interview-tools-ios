//
//  Stage.swift
//  Interviews
//
//  Created by keloran on 05/12/2025.
//

import Foundation
import SwiftData

@Model
final class Stage {
    var id: Int?
    var stage: String

    @Relationship(inverse: \Interview.stage)
    var interviews: [Interview]? = []

    init(id: Int? = nil, stage: String) {
        self.id = id
        self.stage = stage
    }
}
