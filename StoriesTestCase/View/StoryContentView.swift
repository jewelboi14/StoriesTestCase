//
//  StoryContentView.swift
//  StoriesTestCase
//
//  Created by Mikhail Yurov on 18.06.2025.
//

import SwiftUI

struct StoryContentView: View {
    let story: Story
    let user: User
    @ObservedObject var viewModel: StoryListViewModel
    let dismiss: DismissAction
    let onTap: (CGPoint, CGSize) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack {
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
                            
                            Text("2h")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.system(size: 12))
                        }
                    }
                    
                    Spacer()
                    
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
