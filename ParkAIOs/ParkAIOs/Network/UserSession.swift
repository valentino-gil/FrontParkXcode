
import Foundation

enum UserSession {
    private static let nameKey = "user_name"
    private static let emailKey = "user_email"
    private static let idKey = "user_id"

    static func saveName(_ name: String) {
        UserDefaults.standard.set(name, forKey: nameKey)
    }

    static func getName() -> String? {
        UserDefaults.standard.string(forKey: nameKey)
    }

    static func saveUser(_ user: UserResponse) {
        UserDefaults.standard.set(user.name, forKey: nameKey)
        UserDefaults.standard.set(user.email, forKey: emailKey)

        if let id = user.id {
            UserDefaults.standard.set(id, forKey: idKey)
        }
    }

    static func getEmail() -> String? {
        UserDefaults.standard.string(forKey: emailKey)
    }

    static func getUserId() -> Int? {
        guard UserDefaults.standard.object(forKey: idKey) != nil else {
            return nil
        }
        return UserDefaults.standard.integer(forKey: idKey)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: nameKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
        UserDefaults.standard.removeObject(forKey: idKey)
    }
}
