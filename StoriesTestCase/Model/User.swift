//
//  User.swift
//  StoriesTestCase
//
//  Created by Mikhail Yurov on 18.06.2025.
//

import SwiftData
import Foundation

@Model
final class User: Identifiable, Codable, Equatable {
    @Attribute(.unique) var id: Int
    var name: String
    var profilePictureURL: URL
    @Relationship(deleteRule: .cascade) var stories: [Story] = []

    enum CodingKeys: String, CodingKey {
        case id, name
        case profilePictureURL = "profile_picture_url"
    }

    init(id: Int, name: String, profilePictureURL: URL) {
        self.id = id
        self.name = name
        self.profilePictureURL = profilePictureURL
    }

    // MARK: Codable manual conformance

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(Int.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let profilePictureURL = try container.decode(URL.self, forKey: .profilePictureURL)
        self.init(id: id, name: name, profilePictureURL: profilePictureURL)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(profilePictureURL, forKey: .profilePictureURL)
    }

    // MARK: Equatable

    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
    
    var hasUnseenStories: Bool {
        stories.contains { !$0.isSeen }
    }
    
    var firstUnseenStory: Story? {
        stories.first { !$0.isSeen }
    }
}

struct Page: Codable {
    let users: [User]
}

struct PagedUserResponse: Codable {
    let pages: [Page]
}
