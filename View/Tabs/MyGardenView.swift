import SwiftUI

struct MyGardenView: View {
    @ObservedObject var plantViewModel: PlantViewModel
    @ObservedObject var reminderViewModel: ReminderViewModel
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showCreatePlant = false
    
    private let navBarColor = Color(red: 0x95 / 255.0, green: 0xB1 / 255.0, blue: 0x5D / 255.0)
    private let backgroundColor = Color(red: 0.956, green: 0.949, blue: 0.922)
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [backgroundColor, .white]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var userPlants: [Plant] {
        guard let userId = authViewModel.currentUser?.id else { return [] }
        return plantViewModel.getPlants(for: userId)
            .sorted { $0.plantingDate > $1.plantingDate } // เรียงตามวันที่ปลูก โดยวันที่ล่าสุดอยู่ด้านบน
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
                            Text("ยังไม่มีต้นไม้")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("กดปุ่ม + เพื่อสร้างต้นไม้ของคุณ")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(userPlants) { plant in
                                    NavigationLink(destination: PlantDetailView(plantViewModel: plantViewModel, reminderViewModel: reminderViewModel, plant: plant)) {
                                        HStack(spacing: 12) {
                                            if let imagePath = plant.imagePath,
                                               let image = plantViewModel.loadPlantImage(from: imagePath) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 80, height: 80)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                                    )
                                            } else {
                                                RoundedRectangle(cornerRadius: 12)
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
                                            
                                            Spacer()
                                        }
                                        .padding()
                                        .background(.white.opacity(0.9))
                                        .clipShape(RoundedRectangle(cornerRadius: 18))
                                        .shadow(color: Color.black.opacity(0.07), radius: 8, y: 4)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 20)
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
                    .tint(.white)
                }
            }
            .toolbarBackground(navBarColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showCreatePlant) {
                if let userId = authViewModel.currentUser?.id {
                    CreatePlantView(plantViewModel: plantViewModel, userId: userId)
                }
            }
        }
        .background(backgroundGradient.ignoresSafeArea())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "th_TH")
        return formatter.string(from: date)
    }
    
}
