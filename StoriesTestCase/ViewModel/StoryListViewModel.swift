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
    
    private let userService: UserServiceProtocol
    private let storyService: StoryServiceProtocol
    
    init(userService: UserServiceProtocol = ServiceLocator.shared.resolve(),
         storyService: StoryServiceProtocol = ServiceLocator.shared.resolve()) {
        self.userService = userService
        self.storyService = storyService
    }
    
    var usersWithUnseenStories: [User] {
        users.filter { $0.hasUnseenStories }
    }
    
    @MainActor
    func load() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let savedUsers = try await userService.loadSavedUsers()
            if !savedUsers.isEmpty {
                users = savedUsers
                await generateStoriesForUsersIfNeeded()
            }
            
            await loadMoreUsersIfNeeded()
        } catch {
            print("Failed to load initial data: \(error)")
        }
    }
    
    @MainActor
    func loadMoreUsersIfNeeded() async {
        guard (!isLoading || users.isEmpty) && hasMoreUsers else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let newUsers = try await userService.fetchNextPage() {
                if newUsers.isEmpty {
                    hasMoreUsers = false
                } else {
                    users.append(contentsOf: newUsers)
                    await generateStoriesForUsers(newUsers)
                }
            } else {
                hasMoreUsers = false
            }
        } catch {
            print("Failed to load more users: \(error)")
        }
    }
    
    private func generateStoriesForUsersIfNeeded() async {
        let usersWithoutStories = users.filter { $0.stories.isEmpty }
        await generateStoriesForUsers(usersWithoutStories)
    }
    
    private func generateStoriesForUsers(_ users: [User]) async {
        await storyService.generateStoriesForUsers(users)
    }
    
    func markStorySeen(_ story: Story) async {
        story.isSeen = true
        do {
            try await storyService.markSeen(story)
        } catch {
            print("Failed to mark story as seen: \(error)")
        }
    }
    
    func toggleStoryLike(_ story: Story) async {
        story.isLiked.toggle()
        do {
            try await storyService.toggleLike(story)
        } catch {
            print("Failed to toggle story like: \(error)")
        }
    }
    
    func getNextStory(from currentStory: Story, in user: User) -> Story? {
        guard let currentIndex = user.stories.firstIndex(where: { $0.id == currentStory.id }) else { return nil }
        let nextIndex = currentIndex + 1
        return nextIndex < user.stories.count ? user.stories[nextIndex] : nil
    }
    
    func getPreviousStory(from currentStory: Story, in user: User) -> Story? {
        guard let currentIndex = user.stories.firstIndex(where: { $0.id == currentStory.id }) else { return nil }
        let previousIndex = currentIndex - 1
        return previousIndex >= 0 ? user.stories[previousIndex] : nil
    }
}
