//
//  StoryListView.swift
//  StoriesTestCase
//
//  Created by Mikhail Yurov on 18.06.2025.
//

import SwiftUI
import SwiftData

struct StoryListView: View {
    @StateObject private var viewModel = StoryListViewModel()
    @State private var selectedUser: User?

    var body: some View {
        NavigationView {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(viewModel.usersWithUnseenStories, id: \.id) { user in
                        UserStoryRowView(user: user)
                            .onTapGesture {
                                selectedUser = user
                            }
                            .onAppear {
                                if user == viewModel.usersWithUnseenStories.last {
                                    Task { @MainActor in
                                        await viewModel.loadMoreUsersIfNeeded()
                                    }
                                }
                            }
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(width: 90, height: 160)
                            .padding(5)
                    }
                }
                .padding()
                .animation(.easeInOut, value: viewModel.usersWithUnseenStories.count)
            }
            .navigationTitle("Stories")
            .task {
                await viewModel.load()
            }
            .fullScreenCover(item: $selectedUser) { user in
                StoryViewerView(
                    startingUser: user,
                    startingStory: user.firstUnseenStory,
                    viewModel: viewModel
                )
            }
        }
    }
}
