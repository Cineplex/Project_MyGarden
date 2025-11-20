import Foundation

struct User: Codable, Identifiable, Equatable {
    var id = UUID()
    var username: String
    var email: String
    var password: String
    var profileImagePath: String? = nil
}