//
//  UserPersistenceService.swift
//  StoriesTestCase
//
//  Created by Mikhail Yurov on 18.06.2025.
//

import SwiftData
import Foundation

protocol UserPersistenceServiceProtocol {
    func saveUsers(_ users: [User]) async throws
    func fetchAllUsers() async throws -> [User]
    func markSeen(_ story: Story) async throws
    func toggleLike(_ story: Story) async throws
}

@MainActor
final class UserPersistenceService: UserPersistenceServiceProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func saveUsers(_ users: [User]) async throws {
        for user in users {
            let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.id == user.id })
            let existing = try context.fetch(descriptor)

            if let existingUser = existing.first {
                for story in user.stories where !existingUser.stories.contains(where: { $0.id == story.id }) {
                    existingUser.stories.append(story)
                }
            } else {
                context.insert(user)
            }
        }
        try context.save()
    }

    func fetchAllUsers() async throws -> [User] {
        try context.fetch(FetchDescriptor<User>())
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
