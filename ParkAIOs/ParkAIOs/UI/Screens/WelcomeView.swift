import SwiftUI

struct WelcomeView: View {
    var onGoogleSignIn: () -> Void = {}
    var onAppleSignIn: () -> Void = {}
    var onEmailSignIn: () -> Void = {}
    var onRegisterClick: () -> Void = {}

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 48)

                // Logo (pin + auto)
                ParkaiLogo()

                Spacer().frame(height: 8)

                // Nombre de marca
                ParkaiBrandName()

                Spacer().frame(height: 4)

                Text("— Estacioná mejor. Viví la ciudad. —")
                    .font(.system(size: 12))
                    .foregroundColor(.parkaiGray)

                Spacer().frame(height: 64)

                Text("¡Bienvenido!")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.parkaiBlueDark)

                Spacer().frame(height: 16)

                Text("Encontrá zonas con mayor disponibilidad de estacionamiento y ahorrá tiempo en cada viaje.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(red: 0.294, green: 0.333, blue: 0.388)) // #4B5563
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 8)

                Spacer()

                // Botón Google
                SocialButton(
                    text: "Ingresar con Google",
                    backgroundColor: .parkaiBlue,
                    action: onGoogleSignIn
                ) {
                    GoogleIcon()
                }

                Spacer().frame(height: 14)

                // Botón Apple
                SocialButton(
                    text: "Ingresar con Apple ID",
                    backgroundColor: .parkaiBlue,
                    action: onAppleSignIn
                ) {
                    AppleIcon()
                }

                Spacer().frame(height: 14)

                // Botón Correo (con borde oscuro)
                Button(action: onEmailSignIn) {
                    Text("Ingresar con correo")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.parkaiBlue)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.parkaiBlueDark, lineWidth: 1.5)
                        )
                        .cornerRadius(12)
                }

                Spacer().frame(height: 40)

                // Registrate
                (
                    Text("¿No tenes una cuenta? ")
                        .foregroundColor(.parkaiGray)
                    +
                    Text("Registrate")
                        .foregroundColor(.parkaiBlueDark)
                        .fontWeight(.bold)
                )
                .font(.system(size: 14))
                .onTapGesture {
                    onRegisterClick()
                }

                Spacer().frame(height: 24)
            }
            .padding(.horizontal, 24)
        }
    }
}

// ---------- Botón social reutilizable ----------
private struct SocialButton<Icon: View>: View {
    let text: String
    let backgroundColor: Color
    let action: () -> Void
    @ViewBuilder let icon: Icon

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                icon
                Text(text)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(backgroundColor)
            .cornerRadius(12)
        }
    }
}

// ---------- Logo dibujado con Canvas (pin + auto) ----------
private struct ParkaiLogo: View {
    var body: some View {
        ZStack {
            Canvas { context, size in
                let w = size.width
                let h = size.height

                // Pin (gota) con gradiente
                var pinPath = Path()
                pinPath.move(to: CGPoint(x: w * 0.5, y: h * 0.98))
                pinPath.addCurve(
                    to: CGPoint(x: w * 0.5, y: h * 0.05),
                    control1: CGPoint(x: w * 0.15, y: h * 0.65),
                    control2: CGPoint(x: w * 0.1, y: h * 0.35)
                )
                pinPath.addCurve(
                    to: CGPoint(x: w * 0.5, y: h * 0.98),
                    control1: CGPoint(x: w * 0.9, y: h * 0.35),
                    control2: CGPoint(x: w * 0.85, y: h * 0.65)
                )
                pinPath.closeSubpath()

                context.fill(
                    pinPath,
                    with: .linearGradient(
                        Gradient(colors: [.parkaiCyan, .parkaiBlue, .parkaiBlueDark]),
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: w, y: h)
                    )
                )

                // Círculo blanco interior
                let circleRadius = w * 0.24
                let circleCenter = CGPoint(x: w * 0.5, y: h * 0.38)
                let circleRect = CGRect(
                    x: circleCenter.x - circleRadius,
                    y: circleCenter.y - circleRadius,
                    width: circleRadius * 2,
                    height: circleRadius * 2
                )
                context.fill(Path(ellipseIn: circleRect), with: .color(.white))

                // Sombra elipse abajo
                let shadowRect = CGRect(
                    x: w * 0.28, y: h * 0.97,
                    width: w * 0.44, height: h * 0.05
                )
                context.fill(Path(ellipseIn: shadowRect), with: .color(Color.black.opacity(0.13)))
            }
            .frame(width: 120, height: 120)

            Image(systemName: "car.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .foregroundColor(.parkaiBlueDark)
                .offset(y: -16)
        }
        .frame(width: 120, height: 120)
    }
}

private struct ParkaiBrandName: View {
    var body: some View {
        (
            Text("PARK")
                .foregroundColor(.parkaiBlueDark)
                .fontWeight(.heavy)
            +
            Text("AI")
                .foregroundColor(.parkaiCyan)
                .fontWeight(.heavy)
        )
        .font(.system(size: 34))
        .tracking(1)
    }
}

// ---------- Íconos Google/Apple ----------
private struct GoogleIcon: View {
    var body: some View {
        Text("G")
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.parkaiBlue)
            .frame(width: 20, height: 20)
            .background(Color.white)
            .cornerRadius(2)
    }
}

private struct AppleIcon: View {
    var body: some View {
        Image(systemName: "apple.logo")
            .font(.system(size: 18))
            .foregroundColor(.white)
    }
}

#Preview {
    WelcomeView()
}
