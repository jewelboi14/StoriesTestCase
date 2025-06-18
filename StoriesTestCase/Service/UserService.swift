//
//  UserService.swift
//  StoriesTestCase
//
//  Created by Mikhail Yurov on 18.06.2025.
//

import SwiftData
import CryptoKit
import Foundation

protocol UserServiceProtocol {
    func fetchNextPage() async throws -> [User]?
    func resetPagination()
    var cachedUsers: [User] { get }
    func loadSavedUsers() async throws -> [User]
    func generateStories(for users: [User]) async
    func markSeen(_ story: Story) async throws
    func toggleLike(_ story: Story) async throws
}

final class UserService: UserServiceProtocol {
    private var allPages: [Page] = []
    private var currentPageIndex = 0
    private(set) var cachedUsers: [User] = []
    private var hasLoadedData = false

    private let persistence: UserPersistenceServiceProtocol

    init(persistence: UserPersistenceServiceProtocol) {
        self.persistence = persistence
    }

    func resetPagination() {
        currentPageIndex = 0
        cachedUsers = []
    }

    func fetchNextPage() async throws -> [User]? {
        if !hasLoadedData {
            try await loadLocalJSON()
        }

        guard currentPageIndex < allPages.count else { return nil }

        let users = allPages[currentPageIndex].users
        currentPageIndex += 1
        cachedUsers += users

        try await persistence.saveUsers(users)
        return users
    }

    private func loadLocalJSON() async throws {
        guard let url = Bundle.main.url(forResource: "users", withExtension: "json") else {
            throw URLError(.badURL)
        }
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(PagedUserResponse.self, from: data)
        self.allPages = decoded.pages
        self.hasLoadedData = true
    }

    func loadSavedUsers() async throws -> [User] {
        try await persistence.fetchAllUsers()
    }

    func generateStories(for users: [User]) async {
        for user in users {
            let count = Int.random(in: 2...4)
            let stories = (1...count).map { i in
                Story(id: UUID(), imageUrl: URL(string: "https://picsum.photos/seed/\(sha256("\(user.id)-\(i)"))/200/300")!)
            }
            user.stories.append(contentsOf: stories)
        }

        do {
            try await persistence.saveUsers(users)
        } catch {
            print("Failed to save generated stories: \(error)")
        }
    }

    func markSeen(_ story: Story) async throws {
        try await persistence.markSeen(story)
    }

    func toggleLike(_ story: Story) async throws {
        try await persistence.toggleLike(story)
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
