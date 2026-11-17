import Foundation


enum AppRoute: Hashable {
    case register
    case verifyCode(email: String)
    case resendCode(email: String)
    case verifyFailed(email: String)
    case verifySuccess
    case onboarding
    case onboarding2
    case onboarding3
    case home
    case login
    case report(streetName: String, latitude: Double, longitude: Double)
    case favorites
    case placeDetail(name: String, neighborhood: String, latitude: Double, longitude: Double)
    case history
    case profile
}
