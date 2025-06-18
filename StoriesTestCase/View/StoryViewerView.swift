//
//  StoryViewerView.swift
//  StoriesTestCase
//
//  Created by Mikhail Yurov on 18.06.2025.
//

import SwiftUI
import SwiftData
import Combine

struct StoryViewerView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentUser: User
    @State private var currentStoryIndex: Int
    @State private var progressTimer: Timer?
    @State private var currentProgress: Double = 0
    @State private var isPaused: Bool = false
    
    @ObservedObject var viewModel: StoryListViewModel
    
    private let storyDuration: Double = 5.0
    
    init(startingUser: User, startingStory: Story? = nil, viewModel: StoryListViewModel) {
        self.viewModel = viewModel
        self._currentUser = State(initialValue: startingUser)
        
        let storyIndex: Int
        if let startingStory = startingStory,
           let index = startingUser.stories.firstIndex(where: { $0.id == startingStory.id }) {
            storyIndex = index
        } else {
            storyIndex = 0
        }
        self._currentStoryIndex = State(initialValue: storyIndex)
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            if currentUser.stories.indices.contains(currentStoryIndex) {
                let currentStory = currentUser.stories[currentStoryIndex]
                
                VStack(spacing: 0) {
                    StoryProgressBarsView(
                        stories: currentUser.stories,
                        currentIndex: currentStoryIndex,
                        currentProgress: currentProgress
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    StoryContentView(
                        story: currentStory,
                        user: currentUser,
                        viewModel: viewModel,
                        dismiss: dismiss,
                        onTap: handleTap
                    )
                }
            } else {
                Text("No Stories")
                    .foregroundColor(.white)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.width < 0 {
                        withAnimation { goToNextStory() }
                    } else if value.translation.width > 0 {
                        withAnimation { goToPreviousStory() }
                    }
                }
        )
        .onAppear {
            markCurrentStorySeen()
            startProgressTimer()
        }
        .onDisappear {
            stopProgressTimer()
        }
    }
    
    private func handleTap(location: CGPoint, viewSize: CGSize) {
        if location.x < viewSize.width / 2 {
            withAnimation { goToPreviousStory() }
        } else {
            withAnimation { goToNextStory() }
        }
    }
    
    private func startProgressTimer() {
        stopProgressTimer()
        currentProgress = 0
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if !isPaused {
                currentProgress += 0.1 / storyDuration
                
                if currentProgress >= 1.0 {
                    withAnimation {
                        goToNextStory()
                    }
                }
            }
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func pauseProgress() {
        isPaused = true
    }
    
    private func resumeProgress() {
        isPaused = false
    }
    
    private func goToNextStory() {
        if currentStoryIndex < currentUser.stories.count - 1 {
            currentStoryIndex += 1
            markCurrentStorySeen()
            startProgressTimer()
        } else {
            let usersWithUnseen = viewModel.usersWithUnseenStories
            if let currentUserIndex = usersWithUnseen.firstIndex(where: { $0.id == currentUser.id }),
               currentUserIndex + 1 < usersWithUnseen.count {
                currentUser = usersWithUnseen[currentUserIndex + 1]
                currentStoryIndex = 0
                markCurrentStorySeen()
                startProgressTimer()
            } else {
                dismiss()
            }
        }
    }
    
    private func goToPreviousStory() {
        if currentStoryIndex > 0 {
            currentStoryIndex -= 1
            startProgressTimer()
        } else {
            let usersWithUnseen = viewModel.usersWithUnseenStories
            if let currentUserIndex = usersWithUnseen.firstIndex(where: { $0.id == currentUser.id }),
               currentUserIndex > 0 {
                currentUser = usersWithUnseen[currentUserIndex - 1]
                currentStoryIndex = currentUser.stories.count - 1
                startProgressTimer()
            }
        }
    }
    
    private func markCurrentStorySeen() {
        guard currentUser.stories.indices.contains(currentStoryIndex) else { return }
        let story = currentUser.stories[currentStoryIndex]
        if !story.isSeen {
            Task {
                await viewModel.markStorySeen(story)
            }
        }
    }
}
