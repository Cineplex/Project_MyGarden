import SwiftUI

struct CreateReminderView: View {
    @ObservedObject var reminderViewModel: ReminderViewModel
    @ObservedObject var plantViewModel: PlantViewModel
    @Environment(\.dismiss) var dismiss
    
    let userId: UUID
    let userPlants: [Plant]
    
    @State private var reminderTitle: String = ""
    @State private var selectedPlantId: UUID?
    @State private var selectedTime = Date()
    @State private var selectedDays: Set<Int> = []
    @State private var errorMessage: String?
    
    // วันในสัปดาห์
    private let daysOfWeek = [
        (1, "อาทิตย์"),
        (2, "จันทร์"),
        (3, "อังคาร"),
        (4, "พุธ"),
        (5, "พฤหัสบดี"),
        (6, "ศุกร์"),
        (7, "เสาร์")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("ชื่อการแจ้งเตือน")) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("ชื่อ (ไม่บังคับ)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("เช่น รดน้ำต้นไม้, ใส่ปุ๋ย", text: $reminderTitle)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("เลือกต้นไม้")) {
                    if userPlants.isEmpty {
                        Text("ยังไม่มีต้นไม้ กรุณาสร้างต้นไม้ก่อน")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    } else {
                        Picker("ต้นไม้", selection: $selectedPlantId) {
                            Text("เลือกต้นไม้").tag(nil as UUID?)
                            ForEach(userPlants) { plant in
                                Text(plant.name).tag(plant.id as UUID?)
                            }
                        }
                    }
                }
                
                Section(header: Text("เวลาแจ้งเตือน")) {
                    DatePicker("เวลา", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                }
                
                Section(header: Text("วันในสัปดาห์")) {
                    ForEach(daysOfWeek, id: \.0) { day in
                        Toggle(day.1, isOn: Binding(
                            get: { selectedDays.contains(day.0) },
                            set: { isOn in
                                if isOn {
                                    selectedDays.insert(day.0)
                                } else {
                                    selectedDays.remove(day.0)
                                }
                            }
                        ))
                    }
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("เพิ่มการแจ้งเตือน")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ยกเลิก") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("บันทึก") {
                        saveReminder()
                    }
                    .disabled(selectedPlantId == nil || selectedDays.isEmpty)
                }
            }
        }
    }
    
    private func saveReminder() {
        guard let plantId = selectedPlantId else {
            errorMessage = "กรุณาเลือกต้นไม้"
            return
        }
        
        guard !selectedDays.isEmpty else {
            errorMessage = "กรุณาเลือกอย่างน้อย 1 วัน"
            return
        }
        
        let title = reminderTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        reminderViewModel.addReminder(
            userId: userId,
            plantId: plantId,
            title: title.isEmpty ? nil : title,
            time: selectedTime,
            daysOfWeek: selectedDays
        )
        
        dismiss()
    }
}

