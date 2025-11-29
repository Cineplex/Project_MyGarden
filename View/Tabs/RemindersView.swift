import SwiftUI
import UserNotifications

struct RemindersView: View {
    @ObservedObject var reminderViewModel: ReminderViewModel
    @ObservedObject var plantViewModel: PlantViewModel
    @ObservedObject var authViewModel: AuthViewModel
    
    @State private var showCreateReminder = false
    
    private let navBarColor = Color(red: 0x95 / 255.0, green: 0xB1 / 255.0, blue: 0x5D / 255.0)
    private let backgroundColor = Color(red: 0.956, green: 0.949, blue: 0.922)
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [backgroundColor, .white]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
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
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                VStack {
                    if userPlants.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            Image(systemName: "leaf")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("ยังไม่มีต้นไม้สำหรับสร้างการแจ้งเตือน")
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
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(userReminders) { reminder in
                                    ReminderRowView(
                                        reminder: reminder,
                                        reminderViewModel: reminderViewModel,
                                        plantViewModel: plantViewModel,
                                        userPlants: userPlants
                                    )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 20)
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
                    .tint(.white)
                    .disabled(userPlants.isEmpty)
                }
            }
            .toolbarBackground(navBarColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
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
                .labelsHidden()
                .frame(maxHeight: .infinity, alignment: .center)
                .onTapGesture { }
            }
            
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                Text("\(formattedTime) · \(formattedDays)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.07), radius: 8, y: 4)
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