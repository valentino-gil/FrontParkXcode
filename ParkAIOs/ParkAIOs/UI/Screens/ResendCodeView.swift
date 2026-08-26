import SwiftUI

struct ResendCodeView: View {
    var initialEmail: String = ""
    var onBackClick: () -> Void = {}
    var onCodeSent: (_ email: String) -> Void = { _ in }

    @State private var email: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var cooldownSeconds = 0
    @State private var cooldownTimer: Timer?

    init(initialEmail: String = "", onBackClick: @escaping () -> Void = {}, onCodeSent: @escaping (_ email: String) -> Void = { _ in }) {
        self.initialEmail = initialEmail
        self.onBackClick = onBackClick
        self.onCodeSent = onCodeSent
        _email = State(initialValue: initialEmail)
    }

    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && cooldownSeconds == 0
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer().frame(height: 24)

            Text("Reenviar código")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.parkaiBlueDark)

            Spacer().frame(height: 24)

            Text("Ingresá el correo electrónico con el que\nte registraste y te enviaremos un nuevo\ncódigo de verificación.")
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.294, green: 0.333, blue: 0.388))
                .multilineTextAlignment(.center)

            Spacer().frame(height: 24)

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

            if cooldownSeconds > 0 {
                Spacer().frame(height: 12)
                Text("Podés pedir otro código en \(cooldownSeconds)s")
                    .font(.system(size: 13))
                    .foregroundColor(.parkaiGray)
            }

            if let errorMessage {
                Spacer().frame(height: 16)
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: sendCode) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if cooldownSeconds > 0 {
                    Text("Esperá \(cooldownSeconds)s")
                        .font(.system(size: 16, weight: .semibold))
                } else {
                    Text("Enviar código")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isFormValid ? Color.parkaiBlue : Color.parkaiGray.opacity(0.5))
            .cornerRadius(12)
            .disabled(!isFormValid || isLoading)

            Spacer().frame(height: 24)
        }
        .padding(.horizontal, 24)
        .background(Color.white)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onBackClick) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.parkaiBlueDark)
                }
            }
        }
        .onDisappear {
            cooldownTimer?.invalidate()
        }
    }

    private func sendCode() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty else { return }

        errorMessage = nil
        isLoading = true

        Task {
            do {
                let statusCode = try await AuthAPIClient.resendCode(ResendCodeRequest(email: trimmedEmail))

                if (200...299).contains(statusCode) {
                    onCodeSent(trimmedEmail)
                } else {
                    switch statusCode {
                    case 400:
                        errorMessage = "La cuenta ya fue verificada."
                    case 404:
                        errorMessage = "No encontramos una cuenta con ese correo."
                    case 429:
                        errorMessage = "Esperá unos segundos antes de pedir otro código."
                        startCooldown(seconds: 60) // 👈 mismo valor que el backend (plusSeconds(60))
                    default:
                        errorMessage = "No se pudo reenviar el código."
                    }
                }
            } catch {
                errorMessage = "Error: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    private func startCooldown(seconds: Int) {
        cooldownSeconds = seconds
        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            Task { @MainActor in
                if cooldownSeconds > 0 {
                    cooldownSeconds -= 1
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}

#Preview {
    ResendCodeView()
}
