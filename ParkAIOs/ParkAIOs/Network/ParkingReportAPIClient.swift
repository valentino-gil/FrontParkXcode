import Foundation

enum ParkingReportAPIClient {

    static func createReport(
        token: String,
        request: CreateParkingReportRequest
    ) async throws -> (statusCode: Int, report: ParkingReportResponse?) {
        let result = try await APIClient.post(
            path: "api/reports",
            body: request,
            responseType: ParkingReportResponse.self,
            authToken: token
        )
        return (result.statusCode, result.data)
    }
}
