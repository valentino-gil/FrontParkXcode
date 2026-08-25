import SwiftUI

@main
struct ParkAIOsApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

/// Equivalente a "ParkaiApp" composable de Android: controla el splash.
struct RootView: View {
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashView()
            } else {
                AppNavigator()
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 segundos, igual que delay(2000)
            showSplash = false
        }
    }
}
