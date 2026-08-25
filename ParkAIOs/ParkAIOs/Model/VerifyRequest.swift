import Foundation

struct VerifyRequest: Codable {
    let email: String
    let code: String
}
