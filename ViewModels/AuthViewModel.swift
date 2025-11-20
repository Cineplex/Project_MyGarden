import Foundation
import SwiftUI
import UIKit
import LocalAuthentication

class AuthViewModel: ObservableObject {
    @Published var currentScreen: Screen = .login
    @Published var currentUser: User?
    
    private let usersKey = "registered_users"
    private let biometricEnabledKey = "biometric_enabled_"
    private let lastLoginEmailKey = "last_login_email"
    
    // Directory สำหรับเก็บรูปโปรไฟล์
    private var profileImagesDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let profileDir = documentsDirectory.appendingPathComponent("ProfileImages")
        
        // สร้าง directory ถ้ายังไม่มี
        if !FileManager.default.fileExists(atPath: profileDir.path) {
            try? FileManager.default.createDirectory(at: profileDir, withIntermediateDirectories: true)
        }
        
        return profileDir
    }
    
    enum Screen {
        case register, login, mygarden
    }
    
    // โหลดข้อมูลผู้ใช้ทั้งหมดจาก UserDefaults
    private func loadUsers() -> [User] {
        if let data = UserDefaults.standard.data(forKey: usersKey),
           let decoded = try? JSONDecoder().decode([User].self, from: data) {
            return decoded
        }
        return []
    }
    
    // บันทึกข้อมูลผู้ใช้ทั้งหมดกลับไปที่ UserDefaults
    private func saveUsers(_ users: [User]) {
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: usersKey)
        }
    }
    
    // สมัครสมาชิก
    func register(username: String, email: String, password: String, confirmPassword: String) -> String? {
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else {
            return "กรุณากรอกข้อมูลให้ครบถ้วน"
        }
        
        guard password == confirmPassword else {
            return "รหัสผ่านไม่ตรงกัน"
        }
        
        var users = loadUsers()
        if users.contains(where: { $0.email.lowercased() == email.lowercased() }) {
            return "อีเมลนี้ถูกใช้งานแล้ว"
        }
        
        let newUser = User(username: username, email: email, password: password)
        users.append(newUser)
        saveUsers(users)
        
        currentUser = newUser
        currentScreen = .mygarden
        return nil
    }
    
    // เข้าสู่ระบบ
    func login(email: String, password: String) -> String? {
        let users = loadUsers()
        if let user = users.first(where: {
            $0.email.lowercased() == email.lowercased() && $0.password == password
        }) {
            currentUser = user
            saveLastLoginEmail(email) // บันทึกอีเมลสำหรับ Face/Touch ID
            currentScreen = .mygarden
            return nil
        } else {
            return "อีเมลหรือรหัสผ่านไม่ถูกต้อง"
        }
    }
    
    func logout() {
        currentUser = nil
        currentScreen = .login
    }
    
    // บันทึกรูปโปรไฟล์
    func saveProfileImage(_ image: UIImage, for userId: UUID) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        let fileName = "\(userId.uuidString).jpg"
        let fileURL = profileImagesDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            return fileName
        } catch {
            print("Error saving profile image: \(error)")
            return nil
        }
    }
    
    // โหลดรูปโปรไฟล์
    func loadProfileImage(from path: String?) -> UIImage? {
        guard let path = path else { return nil }
        
        let fileURL = profileImagesDirectory.appendingPathComponent(path)
        
        guard let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData) else {
            return nil
        }
        
        return image
    }
    
    // อัพเดทรูปโปรไฟล์
    func updateProfileImage(_ image: UIImage) {
        guard let userId = currentUser?.id else { return }
        
        // ลบรูปเก่าถ้ามี
        if let oldPath = currentUser?.profileImagePath {
            let oldFileURL = profileImagesDirectory.appendingPathComponent(oldPath)
            try? FileManager.default.removeItem(at: oldFileURL)
        }
        
        // บันทึกรูปใหม่
        if let newPath = saveProfileImage(image, for: userId) {
            var users = loadUsers()
            if let index = users.firstIndex(where: { $0.id == userId }) {
                users[index].profileImagePath = newPath
                saveUsers(users)
                
                // อัพเดท currentUser
                currentUser?.profileImagePath = newPath
            }
        }
    }
    
    // อัพเดทชื่อผู้ใช้
    func updateUsername(_ newUsername: String) -> String? {
        guard let userId = currentUser?.id else { return "ไม่พบผู้ใช้" }
        
        guard !newUsername.isEmpty else {
            return "กรุณากรอกชื่อผู้ใช้"
        }
        
        var users = loadUsers()
        if let index = users.firstIndex(where: { $0.id == userId }) {
            users[index].username = newUsername
            saveUsers(users)
            
            // อัพเดท currentUser
            currentUser?.username = newUsername
            return nil
        }
        
        return "ไม่พบผู้ใช้"
    }
    
    // ตรวจสอบว่า Face/Touch ID พร้อมใช้งานหรือไม่
    func isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    // ตรวจสอบว่าเปิดใช้งาน Face/Touch ID หรือไม่
    func isBiometricEnabled(for email: String) -> Bool {
        return UserDefaults.standard.bool(forKey: "\(biometricEnabledKey)\(email.lowercased())")
    }
    
    // เปิด/ปิด Face/Touch ID
    func setBiometricEnabled(_ enabled: Bool, for email: String) {
        UserDefaults.standard.set(enabled, forKey: "\(biometricEnabledKey)\(email.lowercased())")
    }
    
    // บันทึกอีเมลผู้ใช้ล่าสุดที่ login
    func saveLastLoginEmail(_ email: String) {
        UserDefaults.standard.set(email.lowercased(), forKey: lastLoginEmailKey)
    }
    
    // โหลดอีเมลผู้ใช้ล่าสุด
    func getLastLoginEmail() -> String? {
        return UserDefaults.standard.string(forKey: lastLoginEmailKey)
    }
    
    // ยืนยันตัวตนด้วย Face/Touch ID
    func authenticateWithBiometrics() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "ยืนยันตัวตนเพื่อเข้าสู่ระบบ"
            )
            return success
        } catch {
            print("Biometric authentication failed: \(error.localizedDescription)")
            return false
        }
    }
    
    // Login ด้วย Face/Touch ID (ใช้กับอีเมลที่บันทึกไว้)
    func loginWithBiometrics() async -> String? {
        guard let lastEmail = getLastLoginEmail() else {
            return "ไม่พบข้อมูลการเข้าสู่ระบบล่าสุด"
        }
        
        let authenticated = await authenticateWithBiometrics()
        guard authenticated else {
            return "การยืนยันตัวตนล้มเหลว"
        }
        
        // หาข้อมูลผู้ใช้จากอีเมล
        let users = loadUsers()
        if let user = users.first(where: { $0.email.lowercased() == lastEmail.lowercased() }) {
            currentUser = user
            currentScreen = .mygarden
            return nil
        } else {
            return "ไม่พบข้อมูลผู้ใช้"
        }
    }
    
    // ลบบัญชี
    func deleteAccount() {
        guard let user = currentUser else { return }
        let userEmail = user.email.lowercased()
        let userId = user.id
        
        // ลบข้อมูลผู้ใช้จาก UserDefaults
        var users = loadUsers()
        users.removeAll(where: { $0.id == userId })
        saveUsers(users)
        
        // ลบรูปโปรไฟล์
        if let profileImagePath = user.profileImagePath {
            let fileURL = profileImagesDirectory.appendingPathComponent(profileImagePath)
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        // ลบการตั้งค่า Face/Touch ID
        UserDefaults.standard.removeObject(forKey: "\(biometricEnabledKey)\(userEmail)")
        
        // ลบอีเมลที่บันทึกไว้สำหรับ Face/Touch ID ถ้าเป็นบัญชีเดียวกัน
        if let lastEmail = getLastLoginEmail(), lastEmail.lowercased() == userEmail {
            UserDefaults.standard.removeObject(forKey: lastLoginEmailKey)
        }
        
        // ออกจากระบบ
        currentUser = nil
        currentScreen = .login
    }
    
    // ลบบัญชีพร้อมยืนยันรหัสผ่านและคำว่า confirm
    func deleteAccountWithConfirmation(password: String, confirmText: String) -> String? {
        guard let user = currentUser else {
            return "ไม่พบผู้ใช้"
        }
        
        // ตรวจสอบรหัสผ่าน
        guard user.password == password else {
            return "รหัสผ่านไม่ถูกต้อง"
        }
        
        // ตรวจสอบคำว่า confirm
        guard confirmText.lowercased() == "confirm" else {
            return "กรุณาพิมพ์คำว่า \"confirm\" ให้ถูกต้อง"
        }
        
        // ลบบัญชี
        deleteAccount()
        return nil
    }
    
    // เปลี่ยนรหัสผ่าน
    func changePassword(oldPassword: String, newPassword: String, confirmPassword: String) -> String? {
        guard let userId = currentUser?.id else {
            return "ไม่พบผู้ใช้"
        }
        
        // ตรวจสอบรหัสผ่านเดิม
        guard let user = currentUser, user.password == oldPassword else {
            return "รหัสผ่านเดิมไม่ถูกต้อง"
        }
        
        // ตรวจสอบว่ารหัสผ่านใหม่ไม่ว่าง
        guard !newPassword.isEmpty else {
            return "กรุณากรอกรหัสผ่านใหม่"
        }
        
        // ตรวจสอบว่ารหัสผ่านใหม่และยืนยันรหัสผ่านตรงกัน
        guard newPassword == confirmPassword else {
            return "รหัสผ่านใหม่ไม่ตรงกัน"
        }
        
        // ตรวจสอบว่ารหัสผ่านใหม่ไม่เหมือนกับรหัสผ่านเดิม
        guard newPassword != oldPassword else {
            return "รหัสผ่านใหม่ต้องแตกต่างจากรหัสผ่านเดิม"
        }
        
        // อัพเดทรหัสผ่าน
        var users = loadUsers()
        if let index = users.firstIndex(where: { $0.id == userId }) {
            users[index].password = newPassword
            saveUsers(users)
            
            // อัพเดท currentUser
            currentUser?.password = newPassword
            return nil
        }
        
        return "ไม่พบผู้ใช้"
    }
}