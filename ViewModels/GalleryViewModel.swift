import Foundation
import SwiftUI
import UIKit
import AVKit

class GalleryViewModel: ObservableObject {
    @Published var galleryItems: [GalleryItem] = []
    
    private let galleryItemsKey = "user_gallery_items"
    
    // Directory สำหรับเก็บรูปภาพและวิดีโอ
    private var galleryMediaDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let galleryDir = documentsDirectory.appendingPathComponent("GalleryMedia")
        
        // สร้าง directory ถ้ายังไม่มี
        if !FileManager.default.fileExists(atPath: galleryDir.path) {
            try? FileManager.default.createDirectory(at: galleryDir, withIntermediateDirectories: true)
        }
        
        return galleryDir
    }
    
    init() {
        loadGalleryItems()
    }
    
    // โหลดข้อมูล gallery items ทั้งหมดจาก UserDefaults
    private func loadGalleryItems() {
        if let data = UserDefaults.standard.data(forKey: galleryItemsKey),
           let decoded = try? JSONDecoder().decode([GalleryItem].self, from: data) {
            galleryItems = decoded
        } else {
            galleryItems = []
        }
    }
    
    // บันทึกข้อมูล gallery items ทั้งหมดกลับไปที่ UserDefaults
    private func saveGalleryItems() {
        if let data = try? JSONEncoder().encode(galleryItems) {
            UserDefaults.standard.set(data, forKey: galleryItemsKey)
        }
    }
    
    // ดึงข้อมูล gallery items ของผู้ใช้ที่ระบุ
    func getGalleryItems(for userId: UUID) -> [GalleryItem] {
        return galleryItems.filter { $0.userId == userId }.sorted { $0.createdAt > $1.createdAt }
    }
    
    // เพิ่มรูปภาพใหม่
    func addPhoto(userId: UUID, image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        let newItem = GalleryItem(
            userId: userId,
            createdAt: Date(),
            mediaType: .photo,
            filePath: ""
        )
        
        let fileName = "\(newItem.id.uuidString).jpg"
        let fileURL = galleryMediaDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            var updatedItem = newItem
            updatedItem.filePath = fileName
            galleryItems.append(updatedItem)
            saveGalleryItems()
        } catch {
            print("Error saving photo: \(error)")
        }
    }
    
    // เพิ่มวิดีโอใหม่
    func addVideo(userId: UUID, videoURL: URL) {
        let newItem = GalleryItem(
            userId: userId,
            createdAt: Date(),
            mediaType: .video,
            filePath: ""
        )
        
        let fileName = "\(newItem.id.uuidString).mov"
        let fileURL = galleryMediaDirectory.appendingPathComponent(fileName)
        
        do {
            // คัดลอกไฟล์วิดีโอ
            try FileManager.default.copyItem(at: videoURL, to: fileURL)
            var updatedItem = newItem
            updatedItem.filePath = fileName
            galleryItems.append(updatedItem)
            saveGalleryItems()
        } catch {
            print("Error saving video: \(error)")
        }
    }
    
    // ลบ gallery item
    func deleteGalleryItem(_ item: GalleryItem) {
        // ลบไฟล์ถ้ามี
        let fileURL = galleryMediaDirectory.appendingPathComponent(item.filePath)
        try? FileManager.default.removeItem(at: fileURL)
        
        galleryItems.removeAll { $0.id == item.id }
        saveGalleryItems()
    }
    
    // ลบ gallery items หลายรายการ
    func deleteGalleryItems(_ items: [GalleryItem]) {
        for item in items {
            // ลบไฟล์ถ้ามี
            let fileURL = galleryMediaDirectory.appendingPathComponent(item.filePath)
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        let itemIds = Set(items.map { $0.id })
        galleryItems.removeAll { itemIds.contains($0.id) }
        saveGalleryItems()
    }
    
    // โหลดรูปภาพ
    func loadImage(from item: GalleryItem) -> UIImage? {
        guard item.mediaType == .photo else { return nil }
        
        let fileURL = galleryMediaDirectory.appendingPathComponent(item.filePath)
        
        guard let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData) else {
            return nil
        }
        
        return image
    }
    
    // โหลด URL ของวิดีโอ
    func loadVideoURL(from item: GalleryItem) -> URL? {
        guard item.mediaType == .video else { return nil }
        
        let fileURL = galleryMediaDirectory.appendingPathComponent(item.filePath)
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
}

