import SwiftUI

struct OnboardingView: View {
    var imageName: String = "onboarding_park"
    var titleText: String = "Dejá que ParkAI te ayude\na estacionar en CABA"
    var bodyText: String = "Encontrá zonas con mayor disponibilidad estimada según tu ubicación, el día y la hora. Guardá tus lugares favoritos y ayudá a la comunidad compartiendo reportes."

    var onSkipClick: () -> Void
    var onNextClick: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)

            // Reemplazá "onboarding_park" por el nombre real de tu imagen en Assets.xcassets
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(height: 320)

            Spacer().frame(height: 24)

            Text(titleText)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.parkaiBlueDark)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 16)

            Text(bodyText)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.294, green: 0.333, blue: 0.388))
                .multilineTextAlignment(.center)

            Spacer()

            HStack(spacing: 12) {
                Button(action: onSkipClick) {
                    Text("Omitir")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.parkaiBlueDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(red: 0.949, green: 0.949, blue: 0.949)) // #F2F2F2
                        .cornerRadius(12)
                }

                Button(action: onNextClick) {
                    Text("Siguiente")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.parkaiBlue)
                        .cornerRadius(12)
                }
            }

            Spacer().frame(height: 24)
        }
        .padding(.horizontal, 24)
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    OnboardingView(onSkipClick: {}, onNextClick: {})
}
