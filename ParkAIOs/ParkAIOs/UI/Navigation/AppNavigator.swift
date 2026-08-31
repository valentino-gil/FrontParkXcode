import SwiftUI

struct AppNavigator: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(
                onGoogleSignIn: { /* TODO */ },
                onAppleSignIn: { /* TODO */ },
                onEmailSignIn: {
                    path.append(AppRoute.login)
                },
                onRegisterClick: {
                    path.append(AppRoute.register)
                }
            )
            .navigationDestination(for: AppRoute.self) { route in
                destinationView(for: route)
            }
        }
    }

    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .register:
            RegisterView(
                onBackClick: { path.removeLast() },
                onLoginClick: { path.removeLast() },
                onRegisterSuccess: { nombre, email, password in
                    UserSession.saveName(nombre)   // 👈 agregar esta línea
                    path.append(AppRoute.verifyCode(email: email))
                }
            )

        case .verifyCode(let email):
            VerifyCodeView(
                email: email,
                onBackClick: { path.removeLast() },
                onResendCodeClick: {
                    path.append(AppRoute.resendCode(email: email))
                },
                onVerifyFailed: {                              // 👈 ¿está esta línea?
                    path.append(AppRoute.verifyFailed(email: email))
                },
                onVerifySuccess: { token in
                    TokenManager.saveToken(token)
                    path.removeLast(path.count)
                    path.append(AppRoute.verifySuccess)
                }
            )
            
        case .verifyFailed:
            FailureView(
                onRetry: {
                    path.removeLast()
                }
            )

        case .resendCode(let email):
            ResendCodeView(
                initialEmail: email,
                onBackClick: { path.removeLast() },
                onCodeSent: { _ in
                    path.removeLast() 
                }
            )

        case .verifySuccess:
            SuccessView(
                onAcceptClick: {
                    path.removeLast(path.count)
                    path.append(AppRoute.onboarding)
                }
            )

        case .onboarding:
            OnboardingView(
                imageName: "onboarding_park",
                titleText: "Dejá que ParkAI te ayude\na estacionar en CABA",
                bodyText: "Encontrá zonas con mayor disponibilidad estimada según tu ubicación, el día y la hora. Guardá tus lugares favoritos y ayudá a la comunidad compartiendo reportes.",
                onSkipClick: { /* TODO */ },
                onNextClick: { path.append(AppRoute.onboarding2) }
            )

        case .onboarding2:
            OnboardingView(
                imageName: "onboarding_report",
                titleText: "Ayudá a mejorar ParkAI",
                bodyText: "Reportá cómo está el estacionamiento en tu zona y contribuí a mejorar las estimaciones para toda la comunidad.",
                onSkipClick: { /* TODO */ },
                onNextClick: { path.append(AppRoute.onboarding3) }
            )

        case .onboarding3:
            OnboardingView(
                imageName: "onboarding_garages",
                titleText: "Encontrá estacionamientos\nprivados cerca tuyo",
                bodyText: "Consultá playas y garages cercanos, compará precios actualizados y elegí una alternativa cuando estacionar en la calle sea difícil.",
                onSkipClick: {
                    path.removeLast(path.count)
                    path.append(AppRoute.home)
                },
                onNextClick: {
                    path.removeLast(path.count)
                    path.append(AppRoute.home)
                }
            )

        case .home:
            HomeView(
                onReportClick: {
                    path.append(AppRoute.report(
                        streetName: "Av. Santa Fe 3200, Palermo",
                        latitude: -34.5875,
                        longitude: -58.4205
                    ))
                }
            )

        case .login:
            LoginView(
                onBackClick: { path.removeLast() },
                onLoginSuccess: { token in
                    TokenManager.saveToken(token)
                    Task {
                        if let (_, user) = try? await AuthAPIClient.getCurrentUser(token: token), let user {
                            UserSession.saveName(user.name)
                        }
                    }
                    path.removeLast(path.count)
                    path.append(AppRoute.home)
                },
                //onForgotPasswordClick: {
                    //path.append(AppRoute.forgotPassword)
                //}
            )

        case .report(let streetName, let latitude, let longitude):
            ReportView(
                streetName: streetName,
                latitude: latitude,
                longitude: longitude,
                authToken: TokenManager.getToken() ?? "",
                onClose: { path.removeLast() },
                onReportSent: { path.removeLast() }
            )
        }
    }
}
