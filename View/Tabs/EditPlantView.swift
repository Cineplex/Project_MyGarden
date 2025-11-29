import SwiftUI
import PhotosUI

struct EditPlantView: View {
    @ObservedObject var plantViewModel: PlantViewModel
    @Environment(\.dismiss) var dismiss
    
    let plant: Plant
    
    @State private var plantName: String
    @State private var plantingDate: Date
    @State private var additionalDetails: String
    @State private var errorMessage: String?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var plantImage: UIImage?
    
    private let navBarColor = Color(red: 0x95 / 255.0, green: 0xB1 / 255.0, blue: 0x5D / 255.0)
    private let backgroundColor = Color(red: 0.956, green: 0.949, blue: 0.922)
    
    init(plantViewModel: PlantViewModel, plant: Plant) {
        self.plantViewModel = plantViewModel
        self.plant = plant
        _plantName = State(initialValue: plant.name)
        _plantingDate = State(initialValue: plant.plantingDate)
        _additionalDetails = State(initialValue: plant.additionalDetails)
        
        // โหลดรูปภาพถ้ามี
        if let imagePath = plant.imagePath {
            _plantImage = State(initialValue: plantViewModel.loadPlantImage(from: imagePath))
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("รูปภาพต้นไม้")) {
                    VStack(spacing: 15) {
                        if let image = plantImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 200, height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 200, height: 200)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                        Text("เลือกรูปภาพ")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Text(plantImage == nil ? "เลือกรูปภาพ" : "เปลี่ยนรูปภาพ")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("ข้อมูลต้นไม้")) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("ชื่อต้นไม้")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("ชื่อต้นไม้", text: $plantName)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.vertical, 4)
                    
                    DatePicker("วันที่ปลูก", selection: $plantingDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("รายละเอียดเพิ่มเติม")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextEditor(text: $additionalDetails)
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 4)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
            }
            .scrollContentBackground(.hidden)
            .background(backgroundColor)
            .navigationTitle("แก้ไขข้อมูลต้นไม้")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ยกเลิก") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("บันทึก") {
                        savePlant()
                    }
                    .disabled(plantName.isEmpty)
                }
            }
            .toolbarBackground(navBarColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onChange(of: selectedPhoto) { newItem in
                Task {
                    if let newItem = newItem {
                        if let data = try? await newItem.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            plantImage = image
                        }
                    }
                }
            }
        }
    }
    
    private func savePlant() {
        guard !plantName.isEmpty else {
            errorMessage = "กรุณากรอกชื่อต้นไม้"
            return
        }
        
        var updatedPlant = plant
        updatedPlant.name = plantName
        updatedPlant.plantingDate = plantingDate
        updatedPlant.additionalDetails = additionalDetails
        
        // ตรวจสอบว่ามีรูปภาพใหม่หรือไม่
        let hasNewImage = selectedPhoto != nil && plantImage != nil
        
        plantViewModel.updatePlant(updatedPlant, newImage: hasNewImage ? plantImage : nil)
        
        dismiss()
    }
}

