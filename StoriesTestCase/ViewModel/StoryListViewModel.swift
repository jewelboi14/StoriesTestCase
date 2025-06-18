//
//  StoryListViewModel.swift
//  StoriesTestCase
//
//  Created by Mikhail Yurov on 18.06.2025.
//

import SwiftUI
import SwiftData
import Combine

@MainActor
final class StoryListViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var hasMoreUsers = true

    private let service: UserServiceProtocol

    init(service: UserServiceProtocol = ServiceLocator.shared.resolve()) {
        self.service = service
    }

    var usersWithUnseenStories: [User] {
        users.filter { $0.hasUnseenStories }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let savedUsers = try await service.loadSavedUsers()
            if !savedUsers.isEmpty {
                users = savedUsers
                await generateStoriesIfNeeded()
            }
            await loadMoreUsersIfNeeded()
        } catch {
            print("Failed to load initial data: \(error)")
        }
    }

    func loadMoreUsersIfNeeded() async {
        guard hasMoreUsers else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            if let newUsers = try await service.fetchNextPage() {
                if newUsers.isEmpty {
                    hasMoreUsers = false
                } else {
                    let filteredNewUsers = newUsers.filter { newUser in
                        !users.contains(where: { $0.id == newUser.id })
                    }
                    users.append(contentsOf: filteredNewUsers)
                    await generateStoriesIfNeeded()
                }
            } else {
                hasMoreUsers = false
            }
        } catch {
            print("Failed to load more users: \(error)")
        }
    }

    private func generateStoriesIfNeeded() async {
        let usersWithoutStories = users.filter { $0.stories.isEmpty }
        await service.generateStories(for: usersWithoutStories)
    }

    func markStorySeen(_ story: Story) async {
        do {
            try await service.markSeen(story)
        } catch {
            print("Failed to mark story as seen: \(error)")
        }
    }

    func toggleStoryLike(_ story: Story) async {
        do {
            try await service.toggleLike(story)
        } catch {
            print("Failed to toggle story like: \(error)")
        }
    }

    func getNextStory(from current: Story, in user: User) -> Story? {
        guard let i = user.stories.firstIndex(where: { $0.id == current.id }) else { return nil }
        let next = i + 1
        return next < user.stories.count ? user.stories[next] : nil
    }

    func getPreviousStory(from current: Story, in user: User) -> Story? {
        guard let i = user.stories.firstIndex(where: { $0.id == current.id }) else { return nil }
        let prev = i - 1
        return prev >= 0 ? user.stories[prev] : nil
    }
}
