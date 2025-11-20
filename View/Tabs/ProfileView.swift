import SwiftUI
import LocalAuthentication
import PhotosUI

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var biometricEnabled = false
    @State private var authMessage = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var editingUsername = false
    @State private var tempUsername = ""
    @State private var usernameError: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                if let user = authViewModel.currentUser {
                    // รูปโปรไฟล์
                    ZStack {
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    )
                    
                    // ปุ่มเปลี่ยนรูปโปรไฟล์
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Text("เปลี่ยนรูปโปรไฟล์")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .onChange(of: selectedPhoto) { newItem in
                        Task {
                            if let newItem = newItem {
                                if let data = try? await newItem.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    profileImage = image
                                    authViewModel.updateProfileImage(image)
                                }
                            }
                        }
                    }
                    
                    // ชื่อผู้ใช้ (แก้ไขได้)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("ชื่อผู้ใช้")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        HStack {
                            if editingUsername {
                                TextField("ชื่อผู้ใช้", text: $tempUsername)
                                    .textFieldStyle(.roundedBorder)
                                    .onSubmit {
                                        saveUsername()
                                    }
                                
                                Button(action: saveUsername) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title3)
                                }
                                
                                Button(action: cancelEditUsername) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.title3)
                                }
                            } else {
                                Text(user.username)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    tempUsername = user.username
                                    editingUsername = true
                                    usernameError = nil
                                }) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.blue)
                                        .font(.subheadline)
                                }
                            }
                        }
                        
                        if let error = usernameError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                    
                    // อีเมล (แสดงอย่างเดียว)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("อีเมล")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        Text(user.email)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Face/Touch ID
                    if authViewModel.isBiometricAvailable() {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Face ID / Touch ID")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                
                                Toggle("", isOn: $biometricEnabled)
                                    .onChange(of: biometricEnabled) { newValue in
                                        authViewModel.setBiometricEnabled(newValue, for: user.email)
                                    }
                            }
                            
                            Text("เปิดใช้งานเพื่อยืนยันตัวตนด้วย Face ID หรือ Touch ID เมื่อเข้าสู่ระบบ")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    
                    // ปุ่มเปลี่ยนรหัสผ่าน
                    NavigationLink(destination: ChangePasswordView(authViewModel: authViewModel)) {
                        HStack {
                            Text("เปลี่ยนรหัสผ่าน")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)
                    
                    Button("ออกจากระบบ") {
                        authViewModel.logout()
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundColor(.red)
                    
                    // ปุ่มลบบัญชี
                    NavigationLink(destination: DeleteAccountView(authViewModel: authViewModel)) {
                        Text("ลบบัญชี")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 10)
                } else {
                    Text("ยังไม่ได้เข้าสู่ระบบ")
                }
                }
                .padding()
            }
            .navigationTitle("Profile")
            .onAppear {
                loadProfileImage()
                if let user = authViewModel.currentUser {
                    biometricEnabled = authViewModel.isBiometricEnabled(for: user.email)
                }
            }
            .onChange(of: authViewModel.currentUser?.id) { _ in
                loadProfileImage()
                editingUsername = false
                tempUsername = ""
                usernameError = nil
                if let user = authViewModel.currentUser {
                    biometricEnabled = authViewModel.isBiometricEnabled(for: user.email)
                }
            }
        }
    }
    
    private func loadProfileImage() {
        if let user = authViewModel.currentUser,
           let image = authViewModel.loadProfileImage(from: user.profileImagePath) {
            profileImage = image
        }
    }
    
    private func saveUsername() {
        usernameError = authViewModel.updateUsername(tempUsername)
        if usernameError == nil {
            editingUsername = false
        }
    }
    
    private func cancelEditUsername() {
        editingUsername = false
        tempUsername = ""
        usernameError = nil
    }
}