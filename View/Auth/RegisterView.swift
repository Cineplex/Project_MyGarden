import SwiftUI

struct RegisterView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Register")
                .font(.largeTitle)
                .bold()
            
            // ช่องชื่อผู้ใช้
            VStack(alignment: .leading, spacing: 5) {
                Text("ชื่อผู้ใช้งาน")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("ชื่อผู้ใช้งาน", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.none)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
            }
            
            // ช่องอีเมล
            VStack(alignment: .leading, spacing: 5) {
                Text("อีเมล")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("อีเมล", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .textContentType(.none)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
            }
            
            // ช่องรหัสผ่าน
            VStack(alignment: .leading, spacing: 5) {
                Text("รหัสผ่าน")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("รหัสผ่าน", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.none) // ปิด Strong Password
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
            }
            
            // ช่องยืนยันรหัสผ่าน
            VStack(alignment: .leading, spacing: 5) {
                Text("ยืนยันรหัสผ่าน")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                SecureField("ยืนยันรหัสผ่าน", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.none) // ปิด Strong Password
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
            }
            
            // แสดงข้อความ error ถ้ามี
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            // ปุ่มสมัครสมาชิก
            Button("สร้างบัญชี") {
                errorMessage = viewModel.register(
                    username: username,
                    email: email,
                    password: password,
                    confirmPassword: confirmPassword
                )
            }
            .buttonStyle(.borderedProminent)
            
            // ลิงก์ไปหน้า Login
            Button("มีบัญชีอยู่แล้ว? เข้าสู่ระบบ") {
                viewModel.currentScreen = .login
            }
            .font(.caption)
        }
        .padding()
    }
}