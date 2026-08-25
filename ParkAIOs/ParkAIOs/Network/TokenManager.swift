import Foundation

enum TokenManager {
    private static let key = "auth_token"

    static func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: key)
    }

    static func getToken() -> String? {
        UserDefaults.standard.string(forKey: key)
    }

    static func clearToken() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
