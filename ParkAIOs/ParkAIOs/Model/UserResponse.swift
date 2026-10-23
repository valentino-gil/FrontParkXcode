import Foundation

struct UserResponse: Codable {
    let id: Int?
    let name: String
    let email: String
    let avatarKey: String?
    let hasProfileImage: Bool?
}
