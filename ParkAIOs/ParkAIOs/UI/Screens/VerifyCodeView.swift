import SwiftUI

private let codeLength = 6

struct VerifyCodeView: View {
    let email: String
    var onBackClick: () -> Void = {}
    var onVerifySuccess: (_ token: String) -> Void = { _ in }

    @State private var codeDigits: [String] = Array(repeating: "", count: codeLength)
    @FocusState private var focusedIndex: Int?

    @State private var isLoading = false
    @State private var isResending = false
    @State private var errorMessage: String?
    @State private var resendMessage: String?

    private var code: String { codeDigits.joined() }
    private var isCodeComplete: Bool { code.count == codeLength }

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 0) {
                Spacer().frame(height: 24)

                Text("Verificá tu correo")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.parkaiBlueDark)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 24)

                Text("Ingresá el código de 6 dígitos que\nenviamos a tu correo electrónico.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.294, green: 0.333, blue: 0.388))
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 32)

                HStack(spacing: 10) {
                    ForEach(0..<codeLength, id: \.self) { i in
                        CodeDigitField(
                            text: $codeDigits[i],
                            isFocused: focusedIndex == i
                        )
                        .focused($focusedIndex, equals: i)
                        .onChange(of: codeDigits[i]) { _, newValue in
                            handleDigitChange(index: i, newValue: newValue)
                        }
                    }
                }

                Spacer().frame(height: 20)

                HStack {
                    Text("¿No recibiste el código? ")
                        .font(.system(size: 14))
                        .foregroundColor(.parkaiGray)

                    if isResending {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.parkaiBlue)
                    } else {
                        Text("Reenviar código")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.parkaiBlueDark)
                            .onTapGesture { resendCode() }
                    }
                }

                if let resendMessage {
                    Spacer().frame(height: 8)
                    Text(resendMessage)
                        .foregroundColor(.parkaiBlue)
                        .font(.system(size: 12))
                        .multilineTextAlignment(.center)
                }

                if let errorMessage {
                    Spacer().frame(height: 16)
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.system(size: 13))
                        .multilineTextAlignment(.center)
                }

                Spacer().frame(minHeight: 40)

                Button(action: { verifyCode() }) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Verificar cuenta")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(isCodeComplete ? Color.parkaiBlue : Color.parkaiGray.opacity(0.5))
                .cornerRadius(12)
                .disabled(!isCodeComplete || isLoading)

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

    // MARK: - Lógica

    private func handleDigitChange(index: Int, newValue: String) {
        // Se queda solo con el último dígito numérico ingresado (igual que en Android)
        let filtered = String(newValue.filter(\.isNumber).suffix(1))
        if filtered != newValue {
            codeDigits[index] = filtered
        }
        errorMessage = nil

        if !filtered.isEmpty && index < codeLength - 1 {
            focusedIndex = index + 1
        }

        if isCodeComplete && !isLoading {
            verifyCode()
        }
    }

    private func verifyCode() {
        errorMessage = nil
        resendMessage = nil
        isLoading = true

        Task {
            do {
                let request = VerifyRequest(email: email, code: code)
                let (statusCode, auth) = try await AuthAPIClient.verify(request)

                if (200...299).contains(statusCode), let auth {
                    onVerifySuccess(auth.token)
                } else {
                    errorMessage = switch statusCode {
                    case 400: "Código incorrecto o expirado."
                    case 404: "No encontramos una cuenta con ese correo."
                    default: "No se pudo verificar la cuenta."
                    }
                    // Si falla, limpiamos el código para que lo reingresen
                    codeDigits = Array(repeating: "", count: codeLength)
                    focusedIndex = 0
                }
            } catch {
                errorMessage = "Error: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    private func resendCode() {
        errorMessage = nil
        resendMessage = nil
        isResending = true

        Task {
            do {
                let statusCode = try await AuthAPIClient.resendCode(ResendCodeRequest(email: email))
                resendMessage = (200...299).contains(statusCode)
                    ? "Te reenviamos el código a tu correo."
                    : (statusCode == 429 ? "Esperá unos segundos antes de pedir otro código." : "No se pudo reenviar el código.")
            } catch {
                errorMessage = "Error: \(error.localizedDescription)"
            }
            isResending = false
        }
    }
}

// ---------- Casillero individual de dígito ----------
private struct CodeDigitField: View {
    @Binding var text: String
    var isFocused: Bool

    var body: some View {
        TextField("", text: $text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.system(size: 20))
            .frame(height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.parkaiBlue : Color.parkaiGray, lineWidth: 1.5)
            )
    }
}

#Preview {
    VerifyCodeView(email: "test@test.com")
}
