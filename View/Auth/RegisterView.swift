import SwiftUI

struct RegisterView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?
    
    enum Field {
        case username
        case email
        case password
        case confirmPassword
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image("logo-RodNum")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                
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
                        .focused($focusedField, equals: .username)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(focusedField == .username ? Color(red: 42/255, green: 111/255, blue: 54/255) : Color.clear, lineWidth: 2)
                        )
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
                        .focused($focusedField, equals: .email)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(focusedField == .email ? Color(red: 42/255, green: 111/255, blue: 54/255) : Color.clear, lineWidth: 2)
                        )
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
                        .focused($focusedField, equals: .password)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(focusedField == .password ? Color(red: 42/255, green: 111/255, blue: 54/255) : Color.clear, lineWidth: 2)
                        )
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
                        .focused($focusedField, equals: .confirmPassword)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(focusedField == .confirmPassword ? Color(red: 42/255, green: 111/255, blue: 54/255) : Color.clear, lineWidth: 2)
                                )
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
                .tint(Color(red: 42/255, green: 111/255, blue: 54/255))
                
                // ลิงก์ไปหน้า Login
                Button("เข้าสู่ระบบ?") {
                    viewModel.currentScreen = .login
                }
                .font(.caption)
                .foregroundColor(.black)
            }
            .padding(30)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(red: 0.956, green: 0.949, blue: 0.922))
        .ignoresSafeArea()
        .onAppear {
            UITextField.appearance().tintColor = UIColor(red: 42/255, green: 111/255, blue: 54/255, alpha: 1.0)
        }
    }
}