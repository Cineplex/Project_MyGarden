import Foundation

struct Reminder: Codable, Identifiable, Equatable {
    var id = UUID()
    var userId: UUID
    var plantId: UUID
    var title: String? // ชื่อการแจ้งเตือน (ถ้าไม่มีจะไม่แสดงใน RemindersView)
    var time: Date // เวลาที่ต้องการแจ้งเตือน
    var daysOfWeek: Set<Int> // วันในสัปดาห์ (1=Sunday, 2=Monday, ..., 7=Saturday)
    var isEnabled: Bool = true
}

