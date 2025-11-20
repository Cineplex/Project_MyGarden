import SwiftUI
import UserNotifications

struct RemindersView: View {
    @ObservedObject var reminderViewModel: ReminderViewModel
    @ObservedObject var plantViewModel: PlantViewModel
    @ObservedObject var authViewModel: AuthViewModel
    
    @State private var showCreateReminder = false
    
    var userReminders: [Reminder] {
        guard let userId = authViewModel.currentUser?.id else { return [] }
        // แสดง reminders ทั้งหมด (ไม่กรองตาม title)
        return reminderViewModel.getReminders(for: userId)
    }
    
    var userPlants: [Plant] {
        guard let userId = authViewModel.currentUser?.id else { return [] }
        return plantViewModel.getPlants(for: userId)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if userPlants.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "leaf")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("ยังไม่มีต้นไม้")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("กรุณาสร้างต้นไม้ก่อนเพิ่มการแจ้งเตือน")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding()
                } else if userReminders.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "alarm")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("ขณะนี้ยังไม่มี")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("กดปุ่ม + เพื่อเพิ่มการแจ้งเตือน")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                } else {
                    List {
                        ForEach(userReminders) { reminder in
                            ReminderRowView(
                                reminder: reminder,
                                reminderViewModel: reminderViewModel,
                                plantViewModel: plantViewModel,
                                userPlants: userPlants
                            )
                        }
                        .onDelete { indexSet in
                            deleteReminders(at: indexSet)
                        }
                    }
                }
            }
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateReminder = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .disabled(userPlants.isEmpty)
                }
            }
            .sheet(isPresented: $showCreateReminder) {
                if let userId = authViewModel.currentUser?.id {
                    CreateReminderView(
                        reminderViewModel: reminderViewModel,
                        plantViewModel: plantViewModel,
                        userId: userId,
                        userPlants: userPlants
                    )
                }
            }
        }
    }
    
    private func deleteReminders(at offsets: IndexSet) {
        guard let userId = authViewModel.currentUser?.id else { return }
        let reminders = reminderViewModel.getReminders(for: userId)
        for index in offsets {
            reminderViewModel.deleteReminder(reminders[index])
        }
    }
}

// View สำหรับแสดงแต่ละการแจ้งเตือน
struct ReminderRowView: View {
    let reminder: Reminder
    @ObservedObject var reminderViewModel: ReminderViewModel
    @ObservedObject var plantViewModel: PlantViewModel
    let userPlants: [Plant]
    
    @State private var showEditReminder = false
    
    // ดึงข้อมูล reminder ล่าสุดจาก ViewModel
    private var currentReminder: Reminder? {
        reminderViewModel.reminders.first { $0.id == reminder.id }
    }
    
    private var displayReminder: Reminder {
        currentReminder ?? reminder
    }
    
    private var plant: Plant? {
        userPlants.first { $0.id == displayReminder.plantId }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "th_TH")
        return formatter.string(from: displayReminder.time)
    }
    
    private var formattedDays: String {
        let dayNames = [
            1: "อา", 2: "จ", 3: "อ", 4: "พ", 5: "พฤ", 6: "ศ", 7: "ส"
        ]
        let sortedDays = displayReminder.daysOfWeek.sorted()
        return sortedDays.compactMap { dayNames[$0] }.joined(separator: ", ")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let title = displayReminder.title, !title.isEmpty {
                        Text(title)
                            .font(.headline)
                        Text(plant?.name ?? "ไม่พบต้นไม้")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text(plant?.name ?? "ไม่พบต้นไม้")
                            .font(.headline)
                    }
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { displayReminder.isEnabled },
                    set: { _ in
                        reminderViewModel.toggleReminder(displayReminder)
                    }
                ))
                .onTapGesture { }
            }
            
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                Text(formattedTime)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                Text(formattedDays)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if let currentReminder = currentReminder {
                showEditReminder = true
            }
        }
        .sheet(isPresented: $showEditReminder) {
            if let currentReminder = currentReminder {
                EditReminderView(
                    reminderViewModel: reminderViewModel,
                    plantViewModel: plantViewModel,
                    reminder: currentReminder,
                    userPlants: userPlants
                )
            }
        }
    }
}