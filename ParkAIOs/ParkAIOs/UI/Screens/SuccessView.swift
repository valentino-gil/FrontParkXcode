import SwiftUI

struct SuccessView: View {
    var title: String = "¡Cuenta verificada!"
    var message: String = "Tu cuenta fue verificada correctamente. Ya podés iniciar sesión y comenzar a usar ParkAI."
    var buttonText: String = "Aceptar"
    var onAcceptClick: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 48)

            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.parkaiBlueDark)
                .multilineTextAlignment(.center)

            Spacer()

            // Círculo con el check (podés cambiarlo por tu ilustración/imagen con Image("nombre"))
            ZStack {
                Circle()
                    .fill(Color(red: 0.18, green: 0.80, blue: 0.44)) // #2ECC71
                    .frame(width: 160, height: 160)

                Image(systemName: "checkmark")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer().frame(height: 32)

            Text(message)
                .font(.system(size: 15))
                .foregroundColor(Color(red: 0.294, green: 0.333, blue: 0.388))
                .multilineTextAlignment(.center)

            Spacer()

            Button(action: onAcceptClick) {
                Text(buttonText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.parkaiBlue)
                    .cornerRadius(12)
            }

            Spacer().frame(height: 24)
        }
        .padding(.horizontal, 24)
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SuccessView(onAcceptClick: {})
}
