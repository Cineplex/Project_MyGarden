import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // ✅ ขอสิทธิ์แจ้งเตือนจากผู้ใช้
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Error requesting permission:", error.localizedDescription)
            } else {
                print(granted ? "✅ Permission granted" : "🚫 Permission denied")
            }
        }
    }
    
    // ✅ สร้าง Local Notification สำหรับ reminder
    func scheduleNotification(for reminder: Reminder, day: Int) {
        guard reminder.isEnabled else { return }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminder.time)
        
        var dateComponents = DateComponents()
        dateComponents.weekday = day
        dateComponents.hour = components.hour
        dateComponents.minute = components.minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let content = UNMutableNotificationContent()
        if let title = reminder.title, !title.isEmpty {
            content.title = title
        } else {
            content.title = "⏰ ถึงเวลาที่ตั้งไว้แล้ว!"
        }
        content.body = "ครบเวลา \(formatTime(reminder.time)) แล้ว 🎉"
        content.sound = .default
        content.badge = 1
        
        let identifier = "\(reminder.id.uuidString)_\(day)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification:", error.localizedDescription)
            } else {
                print("✅ Notification scheduled for reminder \(reminder.id)")
            }
        }
    }
    
    // ✅ ยกเลิกการแจ้งเตือน
    func cancelNotification(for reminder: Reminder) {
        for day in reminder.daysOfWeek {
            let identifier = "\(reminder.id.uuidString)_\(day)"
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        }
    }
    
    // ✅ ลบการแจ้งเตือนทั้งหมด
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // ✅ Helper function สำหรับ format เวลา
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "th_TH")
        return formatter.string(from: date)
    }
}

