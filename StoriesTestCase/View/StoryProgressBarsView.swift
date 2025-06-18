//
//  StoryProgressBarsView.swift
//  StoriesTestCase
//
//  Created by Mikhail Yurov on 18.06.2025.
//

import SwiftUI

struct StoryProgressBarsView: View {
    let stories: [Story]
    let currentIndex: Int
    let currentProgress: Double
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<stories.count, id: \.self) { index in
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 2)
                        
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
            return totalWidth
        } else if index == currentIndex {
            return totalWidth * currentProgress
        } else {
            return 0
        }
    }
}
