import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isAuthenticating = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email
        case password
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image("logo-RodNum")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
            
            Text("Login")
                .font(.largeTitle)
                .bold()
            
            VStack(alignment: .leading, spacing: 5) {
                Text("อีเมล")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("อีเมล", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .focused($focusedField, equals: .email)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(focusedField == .email ? Color(red: 42/255, green: 111/255, blue: 54/255) : Color.clear, lineWidth: 2)
                    )
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("รหัสผ่าน")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                SecureField("รหัสผ่าน", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .password)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(focusedField == .password ? Color(red: 42/255, green: 111/255, blue: 54/255) : Color.clear, lineWidth: 2)
                    )
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            if isAuthenticating {
                ProgressView("กำลังยืนยันตัวตน...")
            }
            
            Button("เข้าสู่ระบบ") {
                errorMessage = viewModel.login(email: email, password: password)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 42/255, green: 111/255, blue: 54/255))
            .disabled(isAuthenticating)
            
            Button("ยังไม่มีบัญชี?") {
                viewModel.currentScreen = .register
            }
            .font(.caption)
            .foregroundColor(.black)
            .disabled(isAuthenticating)
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.956, green: 0.949, blue: 0.922))
        .onAppear {
            attemptBiometricLogin()
            UITextField.appearance().tintColor = UIColor(red: 42/255, green: 111/255, blue: 54/255, alpha: 1.0)
        }
    }
    
    private func attemptBiometricLogin() {
        // ตรวจสอบว่ามีการเปิดใช้งาน Face/Touch ID และมีอีเมลที่บันทึกไว้
        guard let lastEmail = viewModel.getLastLoginEmail(),
              viewModel.isBiometricEnabled(for: lastEmail) else {
            return
        }
        
        isAuthenticating = true
        Task {
            let error = await viewModel.loginWithBiometrics()
            await MainActor.run {
                isAuthenticating = false
                if let error = error {
                    errorMessage = error
                }
            }
        }
    }
}