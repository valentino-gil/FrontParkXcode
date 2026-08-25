import Foundation

struct CreateParkingReportRequest: Codable {
    let streetName: String
    let latitude: Double
    let longitude: Double
    let reportType: String
}

struct ParkingReportResponse: Codable {
    let id: Int64?
    let streetName: String?
    let latitude: Double?
    let longitude: Double?
    let reportType: String?
    let reportTime: String?
}
