import Foundation

struct GalleryItem: Codable, Identifiable, Equatable {
    var id = UUID()
    var userId: UUID
    var createdAt: Date
    var mediaType: MediaType // รูปภาพหรือวิดีโอ
    var filePath: String // path ไปยังไฟล์ในเครื่อง
    
    enum MediaType: String, Codable {
        case photo
        case video
    }
}

