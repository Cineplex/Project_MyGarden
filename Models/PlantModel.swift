import Foundation

struct Plant: Codable, Identifiable, Equatable {
    var id = UUID()
    var userId: UUID
    var name: String
    var plantingDate: Date
    var additionalDetails: String
    var imagePath: String? = nil
}

