import SwiftUI

struct PlantDetailView: View {
    @ObservedObject var plantViewModel: PlantViewModel
    @ObservedObject var reminderViewModel: ReminderViewModel
    @Environment(\.dismiss) var dismiss
    
    let plant: Plant
    
    @State private var showEditPlant = false
    @State private var showDeleteAlert = false
    
    // ดึงข้อมูลต้นไม้ล่าสุดจาก ViewModel
    private var currentPlant: Plant? {
        plantViewModel.plants.first { $0.id == plant.id }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "th_TH")
        let dateToFormat = currentPlant?.plantingDate ?? plant.plantingDate
        return formatter.string(from: dateToFormat)
    }
    
    var body: some View {
        Form {
            // ส่วนแสดงรูปภาพ
            if let imagePath = currentPlant?.imagePath ?? plant.imagePath,
               let image = plantViewModel.loadPlantImage(from: imagePath) {
                Section {
                    VStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 300, height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            
            Section(header: Text("ข้อมูลต้นไม้")) {
                HStack {
                    Text("ชื่อต้นไม้")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(currentPlant?.name ?? plant.name)
                        .font(.headline)
                }
                
                HStack {
                    Text("วันที่ปลูก")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formattedDate)
                }
            }
            
            if let details = currentPlant?.additionalDetails ?? (plant.additionalDetails.isEmpty ? nil : plant.additionalDetails) {
                if !details.isEmpty {
                    Section(header: Text("รายละเอียดเพิ่มเติม")) {
                        Text(details)
                    }
                }
            }
            
            Section {
                Button(action: {
                    showEditPlant = true
                }) {
                    HStack {
                        Spacer()
                        Text("แก้ไข")
                            .foregroundColor(.blue)
                        Spacer()
                    }
                }
                
                Button(action: {
                    showDeleteAlert = true
                }) {
                    HStack {
                        Spacer()
                        Text("ลบ")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("รายละเอียดต้นไม้")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditPlant) {
            if let currentPlant = currentPlant {
                EditPlantView(plantViewModel: plantViewModel, plant: currentPlant)
            } else {
                EditPlantView(plantViewModel: plantViewModel, plant: plant)
            }
        }
        .alert("ยืนยันการลบ", isPresented: $showDeleteAlert) {
            Button("ยกเลิก", role: .cancel) { }
            Button("ลบ", role: .destructive) {
                deletePlant()
            }
        } message: {
            Text("คุณแน่ใจหรือไม่ว่าต้องการลบต้นไม้ \"\(currentPlant?.name ?? plant.name)\"?")
        }
    }
    
    private func deletePlant() {
        let plantToDelete = currentPlant ?? plant
        // ลบ reminders ที่เกี่ยวข้องกับต้นไม้ก่อน
        reminderViewModel.deleteRemindersByPlantId(plantToDelete.id)
        // แล้วค่อยลบต้นไม้
        plantViewModel.deletePlant(plantToDelete)
        dismiss()
    }
}