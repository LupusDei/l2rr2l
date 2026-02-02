import Foundation

// MARK: - Child Profile

struct Child: Codable, Identifiable, Equatable {
    let id: String
    let userId: String
    let name: String
    let age: Int?
    let sex: String?
    let avatar: String?
    let gradeLevel: String?
    let learningStyle: String?
    let interests: [String]?

    enum CodingKeys: String, CodingKey {
        case id, name, age, sex, avatar, interests
        case userId = "user_id"
        case gradeLevel = "grade_level"
        case learningStyle = "learning_style"
    }
}

// MARK: - Child Requests

struct CreateChildRequest: Codable {
    let name: String
    var age: Int?
    var sex: String?
    var avatar: String?
    var gradeLevel: String?
    var learningStyle: String?
    var interests: [String]?
}

struct UpdateChildRequest: Codable {
    var name: String?
    var age: Int?
    var sex: String?
    var avatar: String?
    var gradeLevel: String?
    var learningStyle: String?
    var interests: [String]?
}
