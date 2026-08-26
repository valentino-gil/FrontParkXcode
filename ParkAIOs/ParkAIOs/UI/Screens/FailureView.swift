import SwiftUI

struct FailureView: View {
    var title: String = "No pudimos verificar tu cuenta"
    var message: String = "El código ingresado es incorrecto o venció. Revisalo e intentá nuevamente."
    var buttonText: String = "Intentar nuevamente"
    var onRetry: () -> Void
    var onBackClick: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            Spacer()

            // Ilustración de error (círculo rojo con X + alerta)
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.12))
                    .frame(width: 220, height: 220)

                Image(systemName: "doc.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color(red: 0.85, green: 0.87, blue: 0.93))
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-8))

                Circle()
                    .fill(Color.red)
                    .frame(width: 90, height: 90)
                    .overlay(
                        Image(systemName: "xmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(y: 10)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.red)
                    .offset(x: 65, y: -55)
            }

            Spacer()

            Text(message)
                .font(.system(size: 15))
                .foregroundColor(Color(red: 0.294, green: 0.333, blue: 0.388))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            Spacer()

            Button(action: onRetry) {
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
        .toolbar {
            if let onBackClick {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onBackClick) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.parkaiBlueDark)
                    }
                }
            }
        }
    }
}

#Preview {
    FailureView(onRetry: {})
}
