import Foundation

enum AuthAPIClient {

    static func register(_ request: RegisterRequest) async throws -> (statusCode: Int, user: UserResponse?) {
        let result = try await APIClient.post(path: "api/auth/register", body: request, responseType: UserResponse.self)
        return (result.statusCode, result.data)
    }

    static func verify(_ request: VerifyRequest) async throws -> (statusCode: Int, auth: AuthResponse?) {
        let result = try await APIClient.post(path: "api/auth/verify", body: request, responseType: AuthResponse.self)
        return (result.statusCode, result.data)
    }

    static func resendCode(_ request: ResendCodeRequest) async throws -> Int {
        try await APIClient.postNoContent(path: "api/auth/resend-code", body: request)
    }

    static func login(_ request: LoginRequest) async throws -> (statusCode: Int, auth: AuthResponse?) {
        let result = try await APIClient.post(path: "api/auth/login", body: request, responseType: AuthResponse.self)
        return (result.statusCode, result.data)
    }
    
    static func getCurrentUser(token: String) async throws -> (statusCode: Int, user: UserResponse?) {
        let result = try await APIClient.get(
            path: "api/auth/me",
            queryItems: [],
            authToken: "Bearer \(token)",
            responseType: UserResponse.self
        )
        return (result.statusCode, result.data)
    }
}
