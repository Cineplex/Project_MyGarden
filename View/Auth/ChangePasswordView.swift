import SwiftUI

struct ChangePasswordView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @FocusState private var focusedField: Field?
    
    enum Field {
        case oldPassword
        case newPassword
        case confirmPassword
    }
    
    private let navBarColor = Color(red: 0x95 / 255.0, green: 0xB1 / 255.0, blue: 0x5D / 255.0)
    
    var body: some View {
        ScrollView {
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
                        .focused($focusedField, equals: .oldPassword)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(focusedField == .oldPassword ? Color(red: 42/255, green: 111/255, blue: 54/255) : Color.clear, lineWidth: 2)
                        )
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("รหัสผ่านใหม่")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    SecureField("รหัสผ่านใหม่", text: $newPassword)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .newPassword)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(focusedField == .newPassword ? Color(red: 42/255, green: 111/255, blue: 54/255) : Color.clear, lineWidth: 2)
                        )
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("ยืนยันรหัสผ่านใหม่")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    SecureField("ยืนยันรหัสผ่านใหม่", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .confirmPassword)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(focusedField == .confirmPassword ? Color(red: 42/255, green: 111/255, blue: 54/255) : Color.clear, lineWidth: 2)
                        )
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
                
                HStack(spacing: 15) {
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
                    .tint(Color(red: 42/255, green: 111/255, blue: 54/255))
                    .disabled(oldPassword.isEmpty || newPassword.isEmpty ||  confirmPassword.isEmpty)
                    
                    Button("ยกเลิก") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
            .padding(30)
            .navigationTitle("เปลี่ยนรหัสผ่าน")
            .navigationBarTitleDisplayMode(.inline)
        }
        .background(Color(red: 0.956, green: 0.949, blue: 0.922))
        .toolbarBackground(navBarColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            UITextField.appearance().tintColor = UIColor(red: 42/255, green: 111/255, blue: 54/255, alpha: 1.0)
        }
    }
}