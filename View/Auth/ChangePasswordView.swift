import SwiftUI

struct ChangePasswordView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("เปลี่ยนรหัสผ่าน")
                .font(.largeTitle)
                .bold()
                .padding(.top, 20)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("รหัสผ่านเดิม")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                SecureField("รหัสผ่านเดิม", text: $oldPassword)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("รหัสผ่านใหม่")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                SecureField("รหัสผ่านใหม่", text: $newPassword)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("ยืนยันรหัสผ่านใหม่")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                SecureField("ยืนยันรหัสผ่านใหม่", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            if let success = successMessage {
                Text(success)
                    .foregroundColor(.green)
                    .font(.caption)
            }
            
            Button("บันทึก") {
                errorMessage = nil
                successMessage = nil
                
                let result = authViewModel.changePassword(
                    oldPassword: oldPassword,
                    newPassword: newPassword,
                    confirmPassword: confirmPassword
                )
                
                if let error = result {
                    errorMessage = error
                } else {
                    successMessage = "เปลี่ยนรหัสผ่านสำเร็จ"
                    // รีเซ็ตฟิลด์
                    oldPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                    
                    // ปิดหน้าหลัง 1.5 วินาที
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
            
            Button("ยกเลิก") {
                dismiss()
            }
            .buttonStyle(.bordered)
            
            Spacer()
        }
        .padding()
        .navigationTitle("เปลี่ยนรหัสผ่าน")
        .navigationBarTitleDisplayMode(.inline)
    }
}

