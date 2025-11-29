import SwiftUI
import LocalAuthentication

struct SettingView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var biometricEnabled = false
    
    private let backgroundColor = Color(red: 0.956, green: 0.949, blue: 0.922)
    private let navBarColor = Color(red: 0x95 / 255.0, green: 0xB1 / 255.0, blue: 0x5D / 255.0)
    
    var body: some View {
        List {
            // Face/Touch ID
            if authViewModel.isBiometricAvailable() {
                Section {
                    Toggle("Face ID / Touch ID", isOn: $biometricEnabled)
                        .onChange(of: biometricEnabled) { newValue in
                            if let user = authViewModel.currentUser {
                                authViewModel.setBiometricEnabled(newValue, for: user.email)
                            }
                        }
                    
                    Text("เปิดใช้งานเพื่อยืนยันตัวตนด้วย Face ID หรือ Touch ID เมื่อเข้าสู่ระบบ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // เปลี่ยนรหัสผ่าน
            Section {
                NavigationLink(destination: ChangePasswordView(authViewModel: authViewModel)) {
                    HStack {
                        Text("เปลี่ยนรหัสผ่าน")
                        Spacer()
                    }
                }
            }
            
            // ลบบัญชี
            Section {
                NavigationLink(destination: DeleteAccountView(authViewModel: authViewModel)) {
                    Text("ลบบัญชี")
                        .foregroundColor(.red)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(backgroundColor)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let user = authViewModel.currentUser {
                biometricEnabled = authViewModel.isBiometricEnabled(for: user.email)
            }
        }
        .onChange(of: authViewModel.currentUser?.id) { _ in
            if let user = authViewModel.currentUser {
                biometricEnabled = authViewModel.isBiometricEnabled(for: user.email)
            }
        }
        .toolbarBackground(navBarColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

