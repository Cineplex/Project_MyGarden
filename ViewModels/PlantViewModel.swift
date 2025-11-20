import Foundation
import SwiftUI
import UIKit

class PlantViewModel: ObservableObject {
    @Published var plants: [Plant] = []
    
    private let plantsKey = "user_plants"
    
    // Directory สำหรับเก็บรูปต้นไม้
    private var plantImagesDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let plantDir = documentsDirectory.appendingPathComponent("PlantImages")
        
        // สร้าง directory ถ้ายังไม่มี
        if !FileManager.default.fileExists(atPath: plantDir.path) {
            try? FileManager.default.createDirectory(at: plantDir, withIntermediateDirectories: true)
        }
        
        return plantDir
    }
    
    init() {
        loadPlants()
    }
    
    // โหลดข้อมูลต้นไม้ทั้งหมดจาก UserDefaults
    private func loadPlants() {
        if let data = UserDefaults.standard.data(forKey: plantsKey),
           let decoded = try? JSONDecoder().decode([Plant].self, from: data) {
            plants = decoded
        } else {
            plants = []
        }
    }
    
    // บันทึกข้อมูลต้นไม้ทั้งหมดกลับไปที่ UserDefaults
    private func savePlants() {
        if let data = try? JSONEncoder().encode(plants) {
            UserDefaults.standard.set(data, forKey: plantsKey)
        }
    }
    
    // ดึงข้อมูลต้นไม้ของผู้ใช้ที่ระบุ
    func getPlants(for userId: UUID) -> [Plant] {
        return plants.filter { $0.userId == userId }
    }
    
    // เพิ่มต้นไม้ใหม่
    func addPlant(userId: UUID, name: String, plantingDate: Date, additionalDetails: String, image: UIImage? = nil) {
        // สร้าง plant ก่อนเพื่อได้ id
        let newPlant = Plant(
            userId: userId,
            name: name,
            plantingDate: plantingDate,
            additionalDetails: additionalDetails,
            imagePath: nil
        )
        
        // บันทึกรูปภาพถ้ามี (ใช้ plant.id)
        var updatedPlant = newPlant
        if let image = image {
            updatedPlant.imagePath = savePlantImage(image, for: newPlant.id)
        }
        
        plants.append(updatedPlant)
        savePlants()
    }
    
    // ลบต้นไม้
    func deletePlant(_ plant: Plant) {
        // ลบรูปภาพถ้ามี
        if let imagePath = plant.imagePath {
            let fileURL = plantImagesDirectory.appendingPathComponent(imagePath)
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        plants.removeAll { $0.id == plant.id }
        savePlants()
    }
    
    // อัพเดทข้อมูลต้นไม้
    func updatePlant(_ plant: Plant, newImage: UIImage? = nil) {
        if let index = plants.firstIndex(where: { $0.id == plant.id }) {
            var updatedPlant = plant
            
            // จัดการรูปภาพใหม่ถ้ามี
            if let newImage = newImage {
                // ลบรูปเก่าถ้ามี
                if let oldImagePath = plant.imagePath {
                    let oldFileURL = plantImagesDirectory.appendingPathComponent(oldImagePath)
                    try? FileManager.default.removeItem(at: oldFileURL)
                }
                
                // บันทึกรูปใหม่
                updatedPlant.imagePath = savePlantImage(newImage, for: plant.id)
            }
            
            plants[index] = updatedPlant
            savePlants()
        }
    }
    
    // บันทึกรูปต้นไม้
    func savePlantImage(_ image: UIImage, for plantId: UUID) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        let fileName = "\(plantId.uuidString).jpg"
        let fileURL = plantImagesDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            return fileName
        } catch {
            print("Error saving plant image: \(error)")
            return nil
        }
    }
    
    // โหลดรูปต้นไม้
    func loadPlantImage(from path: String?) -> UIImage? {
        guard let path = path else { return nil }
        
        let fileURL = plantImagesDirectory.appendingPathComponent(path)
        
        guard let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData) else {
            return nil
        }
        
        return image
    }
}

