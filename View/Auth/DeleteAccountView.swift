import SwiftUI

struct DeleteAccountView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var password = ""
    @State private var confirmText = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("ยืนยันการลบบัญชี")
                .font(.largeTitle)
                .bold()
                .padding(.top, 20)
            
            Text("กรุณากรอกรหัสผ่านและพิมพ์คำว่า \"confirm\" เพื่อยืนยันการลบบัญชี")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("รหัสผ่าน")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                SecureField("รหัสผ่าน", text: $password)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("พิมพ์คำว่า \"confirm\"")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("confirm", text: $confirmText)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button("ลบบัญชี") {
                errorMessage = authViewModel.deleteAccountWithConfirmation(
                    password: password,
                    confirmText: confirmText
                )
                // ไม่ต้อง dismiss() เพราะ deleteAccount() จะเปลี่ยน currentScreen เป็น .login แล้ว
            }
            .buttonStyle(.borderedProminent)
            .foregroundColor(.red)
            .disabled(password.isEmpty || confirmText.isEmpty)
            
            Button("ยกเลิก") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .navigationTitle("ลบบัญชี")
        .navigationBarTitleDisplayMode(.inline)
    }
}

