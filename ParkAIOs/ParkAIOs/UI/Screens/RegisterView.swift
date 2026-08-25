import SwiftUI

struct RegisterView: View {
    var onBackClick: () -> Void = {}
    var onLoginClick: () -> Void = {}
    var onRegisterSuccess: (_ nombre: String, _ email: String, _ password: String) -> Void = { _, _, _ in }

    @State private var nombre = ""
    @State private var email = ""
    @State private var password = ""
    @State private var repeatPassword = ""
    @State private var passwordVisible = false
    @State private var repeatPasswordVisible = false
    @State private var acceptTerms = false
    @State private var acceptEmails = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var isFormValid: Bool {
        !nombre.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == repeatPassword &&
        acceptTerms
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 8)

                Text("Crear cuenta")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.parkaiBlueDark)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 32)

                ParkaiTextField(label: "Nombre", text: $nombre)

                Spacer().frame(height: 16)

                ParkaiTextField(label: "Correo electrónico", text: $email, keyboardType: .emailAddress)

                Spacer().frame(height: 16)

                ParkaiSecureField(
                    label: "Contraseña",
                    text: $password,
                    isVisible: $passwordVisible
                )

                Spacer().frame(height: 16)

                ParkaiSecureField(
                    label: "Repetir contraseña",
                    text: $repeatPassword,
                    isVisible: $repeatPasswordVisible,
                    isError: !repeatPassword.isEmpty && repeatPassword != password
                )

                if !repeatPassword.isEmpty && repeatPassword != password {
                    Text("Las contraseñas no coinciden")
                        .foregroundColor(.red)
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 4)
                        .padding(.top, 4)
                }

                Spacer().frame(height: 24)

                HStack(alignment: .top) {
                    Toggle(isOn: $acceptTerms) { EmptyView() }
                        .toggleStyle(ParkaiCheckboxStyle())
                    Text("Acepto los Términos y Condiciones y la Política de Privacidad.")
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.294, green: 0.333, blue: 0.388))
                }

                HStack(alignment: .top) {
                    Toggle(isOn: $acceptEmails) { EmptyView() }
                        .toggleStyle(ParkaiCheckboxStyle())
                    Text("Acepto recibir correos electronicos y/o SMS.")
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.294, green: 0.333, blue: 0.388))
                }

                Spacer().frame(height: 24)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.system(size: 13))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 12)
                }

                Button(action: register) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Crear cuenta")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(isFormValid ? Color.parkaiBlue : Color.parkaiGray.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFormValid ? Color.parkaiBlueDark : Color.clear, lineWidth: 1.5)
                )
                .cornerRadius(12)
                .disabled(!isFormValid || isLoading)

                Spacer().frame(height: 20)

                HStack {
                    Text("¿Ya tenés una cuenta? ")
                        .font(.system(size: 14))
                        .foregroundColor(.parkaiGray)
                    Text("Iniciar sesión")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.parkaiBlueDark)
                        .onTapGesture { onLoginClick() }
                }

                Spacer().frame(height: 24)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.white)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onBackClick) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.parkaiBlueDark)
                }
            }
        }
    }

    private func register() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let request = RegisterRequest(name: nombre, email: email, password: password)
                let (statusCode, user) = try await AuthAPIClient.register(request)

                if (200...299).contains(statusCode), let user {
                    onRegisterSuccess(user.name, user.email, password)
                } else {
                    errorMessage = switch statusCode {
                    case 400: "Los datos ingresados no son válidos."
                    case 409: "El correo electrónico ya está registrado."
                    default: "No se pudo crear la cuenta."
                    }
                }
            } catch {
                errorMessage = "Error: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}

// ---------- Componentes reutilizables de campo de texto ----------
private struct ParkaiTextField: View {
    let label: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        TextField(label, text: $text)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.horizontal, 14)
            .frame(height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.parkaiGray, lineWidth: 1)
            )
    }
}

private struct ParkaiSecureField: View {
    let label: String
    @Binding var text: String
    @Binding var isVisible: Bool
    var isError: Bool = false

    var body: some View {
        HStack {
            Group {
                if isVisible {
                    TextField(label, text: $text)
                } else {
                    SecureField(label, text: $text)
                }
            }
            Button(action: { isVisible.toggle() }) {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .foregroundColor(.parkaiGray)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isError ? Color.red : Color.parkaiGray, lineWidth: 1)
        )
    }
}

// ---------- Checkbox estilo custom (SwiftUI no trae uno nativo como Android) ----------
private struct ParkaiCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .parkaiBlue : .parkaiGray)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RegisterView()
}
