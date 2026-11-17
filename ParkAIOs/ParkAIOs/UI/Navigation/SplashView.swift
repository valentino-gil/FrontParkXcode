import SwiftUI

struct SplashView: View {
    var body: some View {
        Image("parkai_splash") 
            .resizable()
            .aspectRatio(contentMode: .fill)
            .ignoresSafeArea()
    }
}
