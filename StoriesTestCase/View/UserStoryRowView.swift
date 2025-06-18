//
//  UserStoryRowView.swift
//  StoriesTestCase
//
//  Created by Mikhail Yurov on 18.06.2025.
//

import SwiftUI

struct UserStoryRowView: View {
    let user: User
    
    private let gradientColors = [
        Color.purple,
        Color.pink,
        Color.orange,
        Color.yellow
    ]
    
    private let seenGradientColors = [
        Color.gray.opacity(0.3),
        Color.gray.opacity(0.5)
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Outer gradient ring
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: user.hasUnseenStories ? gradientColors : seenGradientColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 84, height: 84)
                    .animation(.easeInOut(duration: 0.3), value: user.hasUnseenStories)
                
                // Inner white ring for spacing
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 76, height: 76)
                
                // Profile image
                AsyncImage(url: user.profilePictureURL) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 70, height: 70)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                            .opacity(user.hasUnseenStories ? 1.0 : 0.6)
                            .animation(.easeInOut(duration: 0.3), value: user.hasUnseenStories)
                    case .failure:
                        Circle()
                            .fill(Color.red.opacity(0.3))
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            
            Text(user.name)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(maxWidth: 84)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 4)
    }
}
