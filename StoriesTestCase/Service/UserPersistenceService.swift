//
//  UserPersistenceService.swift
//  StoriesTestCase
//
//  Created by Mikhail Yurov on 18.06.2025.
//

import SwiftData
import Foundation

protocol UserPersistenceProtocol {
    func saveUsers(_ users: [User]) async throws
    func fetchAllUsers() async throws -> [User]
}

final class UserPersistenceService: UserPersistenceProtocol {
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
            }
        }
        try context.save()
    }

    func fetchAllUsers() async throws -> [User] {
        let fetchDescriptor = FetchDescriptor<User>()
        return try context.fetch(fetchDescriptor)
    }
}

