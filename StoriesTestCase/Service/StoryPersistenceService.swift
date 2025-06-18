//
//  StoryPersistenceService.swift
//  StoriesTestCase
//
//  Created by Mikhail Yurov on 18.06.2025.
//

import SwiftData
import Foundation

protocol StoryPersistenceProtocol {
    func saveUsers(_ users: [User]) async throws
    func markSeen(_ story: Story) async throws
    func toggleLike(_ story: Story) async throws
}

final class StoryPersistenceService: StoryPersistenceProtocol {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }
    
    func saveUsers(_ users: [User]) async throws {
        for user in users {
            let fetchDescriptor = FetchDescriptor<User>(predicate: #Predicate { $0.id == user.id })
            let existing = try context.fetch(fetchDescriptor)
            
            if existing.isEmpty {
                context.insert(user)
            } else if let existingUser = existing.first {
                // Update stories for existing user
                for story in user.stories {
                    if !existingUser.stories.contains(where: { $0.id == story.id }) {
                        existingUser.stories.append(story)
                    }
                }
            }
        }
        try context.save()
    }

    func markSeen(_ story: Story) async throws {
        story.isSeen = true
        try context.save()
    }

    func toggleLike(_ story: Story) async throws {
        story.isLiked.toggle()
        try context.save()
    }
}
