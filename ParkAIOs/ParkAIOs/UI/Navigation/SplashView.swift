import SwiftUI

struct SplashView: View {
    var body: some View {
        Image("parkai_splash") // agregá esta imagen en Assets.xcassets
            .resizable()
            .aspectRatio(contentMode: .fill)
            .ignoresSafeArea()
    }
}
