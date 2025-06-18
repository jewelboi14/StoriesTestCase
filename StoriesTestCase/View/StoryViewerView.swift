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
    
    private let storyDuration: Double = 5.0 // 5 seconds per story
    
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
                    // Progress bars at the top
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
            // Move to next user with unseen stories
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
            // Move to previous user
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

struct StoryProgressBarsView: View {
    let stories: [Story]
    let currentIndex: Int
    let currentProgress: Double
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<stories.count, id: \.self) { index in
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background bar
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 2)
                        
                        // Progress bar
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white)
                            .frame(
                                width: progressWidth(for: index, totalWidth: geometry.size.width),
                                height: 2
                            )
                            .animation(.linear(duration: 0.1), value: currentProgress)
                    }
                }
                .frame(height: 2)
            }
        }
    }
    
    private func progressWidth(for index: Int, totalWidth: CGFloat) -> CGFloat {
        if index < currentIndex {
            // Completed stories
            return totalWidth
        } else if index == currentIndex {
            // Current story
            return totalWidth * currentProgress
        } else {
            // Future stories
            return 0
        }
    }
}

private struct StoryContentView: View {
    let story: Story
    let user: User
    @ObservedObject var viewModel: StoryListViewModel
    let dismiss: DismissAction
    let onTap: (CGPoint, CGSize) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header with user info and controls
                HStack {
                    // User info
                    HStack(spacing: 12) {
                        AsyncImage(url: user.profilePictureURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                            default:
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 32, height: 32)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.name)
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .semibold))
                            
                            Text("2h") // You can add timestamp logic here
                                .foregroundColor(.white.opacity(0.6))
                                .font(.system(size: 12))
                        }
                    }
                    
                    Spacer()
                    
                    // Controls
                    HStack(spacing: 16) {
                        Button {
                            Task {
                                await viewModel.toggleStoryLike(story)
                            }
                        } label: {
                            Image(systemName: story.isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 24))
                                .foregroundColor(story.isLiked ? .red : .white)
                        }
                        
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Story content area
                ZStack {
                    AsyncImage(url: story.imageUrl) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.2)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .clipped()
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo")
                                            .font(.system(size: 50))
                                            .foregroundColor(.white.opacity(0.6))
                                        Text("Failed to load")
                                            .foregroundColor(.white.opacity(0.8))
                                            .font(.caption)
                                    }
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    
                    // Invisible tap areas for navigation
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onTap(CGPoint(x: 0, y: 0), geometry.size)
                            }
                        
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onTap(CGPoint(x: geometry.size.width, y: 0), geometry.size)
                            }
                    }
                }
                
                Spacer(minLength: 0)
            }
        }
    }
}
