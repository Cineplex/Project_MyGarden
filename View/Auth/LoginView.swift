import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isAuthenticating = false
    
    var body: some View {
        VStack(spacing: 20) {
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
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("รหัสผ่าน")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                SecureField("รหัสผ่าน", text: $password)
                    .textFieldStyle(.roundedBorder)
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
            .disabled(isAuthenticating)
            
            Button("ยังไม่มีบัญชี? สมัครสมาชิก") {
                viewModel.currentScreen = .register
            }
            .font(.caption)
            .disabled(isAuthenticating)
        }
        .padding()
        .onAppear {
            attemptBiometricLogin()
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