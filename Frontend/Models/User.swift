//
//  User.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation

// MARK: - User Model
struct User: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let email: String
    let avatarURL: String?
    let createdAt: Date
    let updatedAt: Date
    let isEmailVerified: Bool
    let twoFactorEnabled: Bool

    // Computed properties
    var initials: String {
        let components = name.components(separatedBy: " ")
        return components.map { $0.first?.uppercased() ?? "" }.joined()
    }

    var displayName: String {
        name.isEmpty ? email : name
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - User Profile Update
struct UserProfileUpdate: Codable {
      let name: String?
      let avatarURL: String?

      init(name: String? = nil, avatarURL: String? = nil) {
          self.name = name
          self.avatarURL = avatarURL
      }
  }

// MARK: - Mock Data
extension User {
      static let mock = User(
          id: "user_123",
          name: "P D",
          email: "john.doe@example.com",
          avatarURL: nil,
          createdAt: Date().addingTimeInterval(-86400 * 30),
          updatedAt: Date(),
          isEmailVerified: true,
          twoFactorEnabled: false
      )

      static let mockPremium = User(
          id: "user_456",
          name: "Jane Smith",
          email: "jane@example.com",
          avatarURL: "https://example.com/avatar.jpg",
          createdAt: Date().addingTimeInterval(-86400 * 60),
          updatedAt: Date(),
          isEmailVerified: true,
          twoFactorEnabled: true
      )
  }
