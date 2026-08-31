import SwiftUI

struct LoginView: View {
    var onBackClick: () -> Void = {}
    var onLoginSuccess: (_ token: String) -> Void = { _ in }
    var onForgotPasswordClick: () -> Void = {}

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer().frame(height: 60)

            Text("Iniciar sesión")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.parkaiBlueDark)

            Spacer().frame(height: 8)

            Text("Ingresá a tu cuenta de ParkAI")
                .font(.system(size: 15))
                .foregroundColor(Color(red: 0.420, green: 0.447, blue: 0.502)) // #6B7280

            Spacer().frame(height: 40)

            TextField("Correo electrónico", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 14)
                .frame(height: 52)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.parkaiGray, lineWidth: 1)
                )
                .onChange(of: email) { _, _ in errorMessage = nil }

            Spacer().frame(height: 16)

            SecureField("Contraseña", text: $password)
                .padding(.horizontal, 14)
                .frame(height: 52)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.parkaiGray, lineWidth: 1)
                )
                .onChange(of: password) { _, _ in errorMessage = nil }

            Spacer().frame(height: 20)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 14))
                    .padding(.bottom, 12)
            }

            Button(action: login) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Iniciar sesión")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.parkaiBlue)
            .cornerRadius(12)
            .disabled(isLoading)

            Spacer().frame(height: 20)
            Spacer().frame(height: 12)

            Text("¿Olvidaste tu contraseña?")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.parkaiBlueDark)
                .onTapGesture { onForgotPasswordClick() }

            Button(action: onBackClick) {
                Text("Volver")
                    .foregroundColor(.parkaiBlueDark)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    private func login() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)

        if trimmedEmail.isEmpty || password.isEmpty {
            errorMessage = "Completá todos los campos"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let request = LoginRequest(email: trimmedEmail, password: password)
                let (statusCode, auth) = try await AuthAPIClient.login(request)

                if (200...299).contains(statusCode) {
                    if let auth {
                        onLoginSuccess(auth.token)
                    } else {
                        errorMessage = "El servidor no devolvió el token."
                    }
                } else {
                    errorMessage = switch statusCode {
                    case 401: "Correo o contraseña incorrectos."
                    case 404: "No existe una cuenta con ese correo."
                    default: "Error al iniciar sesión. Código: \(statusCode)"
                    }
                }
            } catch {
                errorMessage = "No se pudo conectar con el servidor."
            }
            isLoading = false
        }
    }
}

#Preview {
    LoginView()
}
