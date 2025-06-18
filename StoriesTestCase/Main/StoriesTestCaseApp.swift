//
//  StoriesTestCaseApp.swift
//  StoriesTestCase
//
//  Created by Mikhail Yurov on 18.06.2025.
//

import SwiftUI
import SwiftData

@main
struct StoriesApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([User.self, Story.self])  // Include User model as well
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    init() {
        let userPersistence = UserPersistenceService(context: sharedModelContainer.mainContext)
        let userService = UserService(persistence: userPersistence)

        let storyPersistence = StoryPersistenceService(context: sharedModelContainer.mainContext)
        let storyService = StoryService(persistence: storyPersistence)

        ServiceLocator.shared.register(userService as UserServiceProtocol)
        ServiceLocator.shared.register(storyPersistence as StoryPersistenceProtocol)
        ServiceLocator.shared.register(storyService as StoryServiceProtocol)
    }

    var body: some Scene {
        WindowGroup {
            StoryListView()
                .modelContainer(sharedModelContainer)
        }
    }
}
