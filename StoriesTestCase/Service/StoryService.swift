//
//  StoryService.swift
//  StoriesTestCase
//
//  Created by Mikhail Yurov on 18.06.2025.
//

import SwiftUI
import SwiftData
import Combine
import CryptoKit

protocol StoryServiceProtocol {
    func generateStoriesForUsers(_ users: [User]) async
    func markSeen(_ story: Story) async throws
    func toggleLike(_ story: Story) async throws
}

final class StoryService: StoryServiceProtocol {
    private let persistence: StoryPersistenceProtocol
    
    init(persistence: StoryPersistenceProtocol) {
        self.persistence = persistence
    }
    
    func generateStoriesForUsers(_ users: [User]) async {
        for user in users {
            let storyCount = Int.random(in: 2...4)
            let stories = (1...storyCount).map { index in
                return Story(
                    id: UUID(),
                    imageUrl: URL(string: "https://picsum.photos/seed/\(user.id)\(index)/200/300")!
                )
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
    
    func sha256Hash(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
