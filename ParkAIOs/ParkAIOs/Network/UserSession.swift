import Foundation

enum UserSession {
    private static let nameKey = "user_name"

    static func saveName(_ name: String) {
        UserDefaults.standard.set(name, forKey: nameKey)
    }

    static func getName() -> String? {
        UserDefaults.standard.string(forKey: nameKey)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: nameKey)
    }
}
