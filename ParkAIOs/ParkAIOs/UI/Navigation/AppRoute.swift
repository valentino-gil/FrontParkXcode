import Foundation

/// Equivalente a "object Routes" de Android.
/// En SwiftUI no hace falta parsear strings con argumentos (como "verify_code/{email}"):
/// el enum lleva el argumento directamente en el caso (ej. .verifyCode(email: "x@x.com")).
enum AppRoute: Hashable {
    case register
    case verifyCode(email: String)
    case verifySuccess
    case onboarding
    case onboarding2
    case onboarding3
    case home
    case login
    case report(streetName: String, latitude: Double, longitude: Double)
}
