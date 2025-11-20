import SwiftUI

struct MyGardenView: View {
    @ObservedObject var plantViewModel: PlantViewModel
    @ObservedObject var reminderViewModel: ReminderViewModel
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showCreatePlant = false
    
    var userPlants: [Plant] {
        guard let userId = authViewModel.currentUser?.id else { return [] }
        return plantViewModel.getPlants(for: userId)
            .sorted { $0.plantingDate > $1.plantingDate } // เรียงตามวันที่ปลูก โดยวันที่ล่าสุดอยู่ด้านบน
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if userPlants.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Text("ขณะนี้ยังไม่มี")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(userPlants) { plant in
                            NavigationLink(destination: PlantDetailView(plantViewModel: plantViewModel, reminderViewModel: reminderViewModel, plant: plant)) {
                                HStack(spacing: 12) {
                                    // รูปภาพต้นไม้
                                    if let imagePath = plant.imagePath,
                                       let image = plantViewModel.loadPlantImage(from: imagePath) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                            )
                                    } else {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 80, height: 80)
                                            .overlay(
                                                Image(systemName: "leaf")
                                                    .font(.system(size: 30))
                                                    .foregroundColor(.gray)
                                            )
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(plant.name)
                                            .font(.headline)
                                        
                                        Text("วันที่ปลูก: \(formatDate(plant.plantingDate))")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        if !plant.additionalDetails.isEmpty {
                                            Text(plant.additionalDetails)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(2)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { indexSet in
                            deletePlants(at: indexSet)
                        }
                    }
                }
            }
            .navigationTitle("My Garden")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreatePlant = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreatePlant) {
                if let userId = authViewModel.currentUser?.id {
                    CreatePlantView(plantViewModel: plantViewModel, userId: userId)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "th_TH")
        return formatter.string(from: date)
    }
    
    private func deletePlants(at offsets: IndexSet) {
        guard let userId = authViewModel.currentUser?.id else { return }
        let plants = plantViewModel.getPlants(for: userId)
        for index in offsets {
            let plant = plants[index]
            // ลบ reminders ที่เกี่ยวข้องกับต้นไม้ก่อน
            reminderViewModel.deleteRemindersByPlantId(plant.id)
            // แล้วค่อยลบต้นไม้
            plantViewModel.deletePlant(plant)
        }
    }
}
