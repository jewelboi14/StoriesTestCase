//
//  UserService.swift
//  StoriesTestCase
//
//  Created by Mikhail Yurov on 18.06.2025.
//

import SwiftData
import Foundation

protocol UserServiceProtocol {
    func fetchNextPage() async throws -> [User]?
    func resetPagination()
    var cachedUsers: [User] { get }
    func loadSavedUsers() async throws -> [User]
}

final class UserService: UserServiceProtocol {
    private var allPages: [Page] = []
    private var currentPageIndex = 0
    private(set) var cachedUsers: [User] = []
    private var hasLoadedData = false
    private let persistence: UserPersistenceProtocol

    init(persistence: UserPersistenceProtocol) {
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
        return try await persistence.fetchAllUsers()
    }
}
