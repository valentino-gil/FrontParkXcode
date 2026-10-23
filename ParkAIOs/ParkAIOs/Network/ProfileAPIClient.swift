
import Foundation
import UIKit

enum ProfileAPIError: LocalizedError {
    case noToken
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case invalidImage
    case imageTooLarge

    var errorDescription: String? {
        switch self {
        case .noToken:
            return "Tu sesión expiró. Iniciá sesión nuevamente."
        case .invalidURL:
            return "La dirección del servidor no es válida."
        case .invalidResponse:
            return "Respuesta inválida del servidor."
        case .serverError(let code):
            return "Error del servidor: \(code)"
        case .invalidImage:
            return "No se pudo procesar la fotografía."
        case .imageTooLarge:
            return "La fotografía es demasiado grande."
        }
    }
}

enum ProfileAPIClient {

    private static let maxImageSize = 2 * 1024 * 1024

    // MARK: - Request autenticado

    private static func authenticatedRequest(
        path: String,
        method: String
    ) throws -> URLRequest {

        guard let token = TokenManager.getToken(),
              !token.isEmpty else {
            throw ProfileAPIError.noToken
        }

        guard let url = URL(
            string: APIClient.baseURL + path
        ) else {
            throw ProfileAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30

        request.setValue(
            "Bearer \(token)",
            forHTTPHeaderField: "Authorization"
        )

        return request
    }

    // MARK: - Comprimir fotografía

    private static func compressImage(
        _ image: UIImage
    ) throws -> Data {

        let maxDimension: CGFloat = 1200

        let size = image.size
        let maxSide = max(size.width, size.height)

        let scale = min(1.0, maxDimension / maxSide)

        let targetSize = CGSize(
            width: max(1, size.width * scale),
            height: max(1, size.height * scale)
        )

        let renderer = UIGraphicsImageRenderer(
            size: targetSize
        )

        let resizedImage = renderer.image { _ in
            image.draw(
                in: CGRect(
                    origin: .zero,
                    size: targetSize
                )
            )
        }

        for quality in [0.8, 0.6, 0.4, 0.2] {

            if let data = resizedImage.jpegData(
                compressionQuality: quality
            ), data.count <= maxImageSize {

                return data
            }
        }

        throw ProfileAPIError.imageTooLarge
    }

    // MARK: - Subir foto

    static func uploadPhoto(
        _ image: UIImage
    ) async throws {

        let imageData = try compressImage(image)
        let boundary = UUID().uuidString

        var request = try authenticatedRequest(
            path: "api/profile/photo",
            method: "POST"
        )

        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        var body = Data()

        body.append(Data(
            "--\(boundary)\r\n".utf8
        ))

        body.append(Data(
            "Content-Disposition: form-data; name=\"file\"; filename=\"profile.jpg\"\r\n".utf8
        ))

        body.append(Data(
            "Content-Type: image/jpeg\r\n\r\n".utf8
        ))

        body.append(imageData)

        body.append(Data(
            "\r\n--\(boundary)--\r\n".utf8
        ))

        request.httpBody = body

        let (_, response) = try await URLSession.shared.data(
            for: request
        )

        try validate(response)
    }

    // MARK: - Elegir avatar

    static func selectAvatar(
        _ avatarKey: String
    ) async throws {

        var request = try authenticatedRequest(
            path: "api/profile/avatar",
            method: "PUT"
        )

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        let body = AvatarRequest(
            avatarKey: avatarKey
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await URLSession.shared.data(
            for: request
        )

        try validate(response)
    }

    // MARK: - Obtener foto

    static func getPhoto() async throws -> UIImage {

        let request = try authenticatedRequest(
            path: "api/profile/photo",
            method: "GET"
        )

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        try validate(response)

        guard let image = UIImage(data: data) else {
            throw ProfileAPIError.invalidImage
        }

        return image
    }

    // MARK: - Validar respuesta

    private static func validate(
        _ response: URLResponse
    ) throws {

        guard let http = response as? HTTPURLResponse else {
            throw ProfileAPIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw ProfileAPIError.serverError(
                http.statusCode
            )
        }
    }
}

private struct AvatarRequest: Encodable {
    let avatarKey: String
}
