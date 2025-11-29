import SwiftUI

struct DeleteAccountView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var password = ""
    @State private var confirmText = ""
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?
    
    enum Field {
        case password
        case confirmText
    }
    
    private let navBarColor = Color(red: 0x95 / 255.0, green: 0xB1 / 255.0, blue: 0x5D / 255.0)
    
    var body: some View {
        ScrollView {
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
                        .focused($focusedField, equals: .password)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(focusedField == .password ? Color(red: 42/255, green: 111/255, blue: 54/255) : Color.clear, lineWidth: 2)
                        )
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("พิมพ์คำว่า \"confirm\"")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("confirm", text: $confirmText)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .confirmText)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(focusedField == .confirmText ? Color(red: 42/255, green: 111/255, blue: 54/255) : Color.clear, lineWidth: 2)
                        )
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                HStack(spacing: 15) {
                    Button("ลบบัญชี") {
                        errorMessage = authViewModel.deleteAccountWithConfirmation(
                            password: password,
                            confirmText: confirmText
                        )
                        // ไม่ต้อง dismiss() เพราะ deleteAccount() จะเปลี่ยน currentScreen เป็น .login แล้ว
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(password.isEmpty || confirmText.isEmpty)
                    
                    Button("ยกเลิก") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.gray)
                }
            }
            .padding(30)
            .navigationTitle("ลบบัญชี")
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