import Foundation
import SwiftUI
import UserNotifications

class ReminderViewModel: ObservableObject {
    @Published var reminders: [Reminder] = []
    @Published var showAlert = false
    @Published var alertMessage: String = ""
    @Published var alertTime: Date?
    
    private let remindersKey = "user_reminders"
    private let notificationManager = NotificationManager.shared
    private var timer: Timer?
    private var lastCheckedReminders: Set<UUID> = []
    weak var plantViewModel: PlantViewModel?
    
    init() {
        loadReminders()
        requestNotificationPermission()
        startTimeChecker()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // ขออนุญาตการแจ้งเตือน
    func requestNotificationPermission() {
        notificationManager.requestPermission()
    }
    
    // โหลดข้อมูลการแจ้งเตือนทั้งหมดจาก UserDefaults
    private func loadReminders() {
        if let data = UserDefaults.standard.data(forKey: remindersKey),
           let decoded = try? JSONDecoder().decode([Reminder].self, from: data) {
            reminders = decoded
            scheduleAllNotifications()
        } else {
            reminders = []
        }
    }
    
    // บันทึกข้อมูลการแจ้งเตือนทั้งหมดกลับไปที่ UserDefaults
    private func saveReminders() {
        if let data = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(data, forKey: remindersKey)
        }
    }
    
    // ดึงข้อมูลการแจ้งเตือนของผู้ใช้ที่ระบุ
    func getReminders(for userId: UUID) -> [Reminder] {
        return reminders.filter { $0.userId == userId }
    }
    
    // เพิ่มการแจ้งเตือนใหม่
    func addReminder(userId: UUID, plantId: UUID, title: String?, time: Date, daysOfWeek: Set<Int>) {
        let newReminder = Reminder(
            userId: userId,
            plantId: plantId,
            title: title,
            time: time,
            daysOfWeek: daysOfWeek,
            isEnabled: true
        )
        reminders.append(newReminder)
        saveReminders()
        scheduleNotification(for: newReminder)
    }
    
    // ลบการแจ้งเตือน
    func deleteReminder(_ reminder: Reminder) {
        // ลบการแจ้งเตือนจากระบบ
        cancelNotification(for: reminder)
        
        reminders.removeAll { $0.id == reminder.id }
        saveReminders()
    }
    
    // ลบการแจ้งเตือนทั้งหมดที่เกี่ยวข้องกับต้นไม้
    func deleteRemindersByPlantId(_ plantId: UUID) {
        let remindersToDelete = reminders.filter { $0.plantId == plantId }
        
        for reminder in remindersToDelete {
            cancelNotification(for: reminder)
        }
        
        reminders.removeAll { $0.plantId == plantId }
        saveReminders()
    }
    
    // อัพเดทการแจ้งเตือน
    func updateReminder(_ reminder: Reminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            // ลบการแจ้งเตือนเก่า
            cancelNotification(for: reminders[index])
            
            reminders[index] = reminder
            saveReminders()
            
            // สร้างการแจ้งเตือนใหม่
            if reminder.isEnabled {
                scheduleNotification(for: reminder)
            }
        }
    }
    
    // เปิด/ปิดการแจ้งเตือน
    func toggleReminder(_ reminder: Reminder) {
        var updatedReminder = reminder
        updatedReminder.isEnabled.toggle()
        updateReminder(updatedReminder)
    }
    
    // ตั้งเวลาการแจ้งเตือน
    private func scheduleNotification(for reminder: Reminder) {
        guard reminder.isEnabled else { return }
        
        // สร้างการแจ้งเตือนสำหรับแต่ละวันในสัปดาห์
        for day in reminder.daysOfWeek {
            notificationManager.scheduleNotification(for: reminder, day: day)
        }
    }
    
    // ยกเลิกการแจ้งเตือน
    private func cancelNotification(for reminder: Reminder) {
        notificationManager.cancelNotification(for: reminder)
    }
    
    // ตั้งเวลาการแจ้งเตือนทั้งหมดใหม่ (ใช้เมื่อโหลดข้อมูล)
    private func scheduleAllNotifications() {
        // ลบการแจ้งเตือนเก่าทั้งหมด
        notificationManager.removeAllNotifications()
        
        // สร้างการแจ้งเตือนใหม่ทั้งหมด
        for reminder in reminders {
            if reminder.isEnabled {
                scheduleNotification(for: reminder)
            }
        }
    }
    
    // เริ่มต้น timer เพื่อตรวจสอบเวลาอย่างต่อเนื่อง
    private func startTimeChecker() {
        // ตรวจสอบทันทีเมื่อเริ่มต้น
        checkReminderTimes()
        
        // สร้าง timer บน main thread - ตรวจสอบทุก 5 วินาทีเพื่อความแม่นยำและประหยัดพลังงาน
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
                self?.checkReminderTimes()
            }
            // เพิ่ม timer เข้า RunLoop เพื่อให้ทำงานได้ถูกต้อง
            if let timer = self.timer {
                RunLoop.current.add(timer, forMode: .common)
            }
        }
    }
    
    // ตรวจสอบว่าถึงเวลาที่ตั้งไว้หรือยัง
    private func checkReminderTimes() {
        let now = Date()
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        let currentHour = currentComponents.hour ?? 0
        let currentMinute = currentComponents.minute ?? 0
        let currentSecond = currentComponents.second ?? 0
        let currentWeekday = calendar.component(.weekday, from: now)
        
        var triggeredReminders: Set<UUID> = []
        
        for reminder in reminders {
            guard reminder.isEnabled else { continue }
            
            // ตรวจสอบว่าวันนี้ตรงกับวันที่ตั้งไว้หรือไม่
            guard reminder.daysOfWeek.contains(currentWeekday) else { continue }
            
            let reminderComponents = calendar.dateComponents([.hour, .minute], from: reminder.time)
            let reminderHour = reminderComponents.hour ?? 0
            let reminderMinute = reminderComponents.minute ?? 0
            
            // ตรวจสอบว่าเวลาตรงกันหรือไม่ (ตรวจสอบทุก 5 วินาที)
            if currentHour == reminderHour && currentMinute == reminderMinute {
                // ตรวจสอบว่าแสดง alert ไปแล้วหรือยัง (ป้องกันการแสดงซ้ำ)
                // แสดงเฉพาะเมื่ออยู่ในช่วง 0-10 วินาทีของนาทีนั้น เพื่อไม่ให้แสดงซ้ำ
                if !lastCheckedReminders.contains(reminder.id) && currentSecond < 10 {
                    triggeredReminders.insert(reminder.id)
                    showReminderAlert(for: reminder)
                }
            }
        }
        
        // อัพเดท reminders ที่แสดง alert แล้ว
        lastCheckedReminders.formUnion(triggeredReminders)
        
        // รีเซ็ต reminders ที่ผ่านนาทีแล้ว (เมื่อนาทีเปลี่ยน)
        let remindersToRemove = lastCheckedReminders.filter { reminderId in
            guard let reminder = reminders.first(where: { $0.id == reminderId }) else { return true }
            let reminderComponents = calendar.dateComponents([.hour, .minute], from: reminder.time)
            let reminderHour = reminderComponents.hour ?? 0
            let reminderMinute = reminderComponents.minute ?? 0
            
            // ถ้านาทีไม่ตรงกันแล้ว ให้ลบออกจาก lastCheckedReminders
            return !(currentHour == reminderHour && currentMinute == reminderMinute)
        }
        
        lastCheckedReminders.subtract(remindersToRemove)
    }
    
    // แสดง alert สำหรับ reminder
    private func showReminderAlert(for reminder: Reminder) {
        // ตรวจสอบว่าอยู่บน main thread หรือไม่
        if Thread.isMainThread {
            updateAlertMessage(for: reminder)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.updateAlertMessage(for: reminder)
            }
        }
    }
    
    // อัพเดทข้อความ alert
    private func updateAlertMessage(for reminder: Reminder) {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "th_TH")
        let formattedTime = formatter.string(from: reminder.time)
        
        // หาชื่อต้นไม้
        var plantName: String? = nil
        if let plantViewModel = self.plantViewModel {
            plantName = plantViewModel.plants.first { $0.id == reminder.plantId }?.name
        }
        
        // สร้างข้อความ alert
        var message = "ครบเวลา \(formattedTime) แล้ว 🎉"
        if let title = reminder.title, !title.isEmpty {
            message = "\(title) - \(message)"
        } else if let plantName = plantName {
            message = "\(plantName) - \(message)"
        }
        
        self.alertTime = reminder.time
        self.alertMessage = message
        self.showAlert = true
    }
    
    // Helper function สำหรับ format เวลา
    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "th_TH")
        return formatter.string(from: date)
    }
}

