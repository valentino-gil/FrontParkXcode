import Foundation

struct RegisterRequest: Codable {
    let name: String
    let email: String
    let password: String
}
