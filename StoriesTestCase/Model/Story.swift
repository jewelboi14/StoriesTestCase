//
//  Story.swift
//  StoriesTestCase
//
//  Created by Mikhail Yurov on 18.06.2025.
//

import SwiftUI
import SwiftData
import Combine

@Model
final class Story {
    var id: UUID
    var imageUrl: URL
    var isSeen: Bool = false
    var isLiked: Bool = false
    var createdAt: Date = Date()
    
    @Relationship(inverse: \User.stories) var user: User?
    
    init(id: UUID, imageUrl: URL) {
        self.id = id
        self.imageUrl = imageUrl
    }
}
