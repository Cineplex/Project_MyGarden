import SwiftUI
import PhotosUI

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var editingUsername = false
    @State private var tempUsername = ""
    @State private var usernameError: String?
    
    private let themeGreen = Color(red: 42/255, green: 111/255, blue: 54/255)
    private let backgroundColor = Color(red: 0.956, green: 0.949, blue: 0.922)
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [backgroundColor, .white]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    private let navBarColor = Color(red: 0x95 / 255.0, green: 0xB1 / 255.0, blue: 0x5D / 255.0)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 5) {
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
                            .stroke(themeGreen, lineWidth: 3)
                    )
                    .padding(.top, 20)
                    
                    // ปุ่มเปลี่ยนรูปโปรไฟล์
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Text("เปลี่ยนรูปโปรไฟล์")
                            .font(.subheadline)
                            .foregroundColor(themeGreen)
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
                    VStack(alignment: .leading, spacing: 5) {
                        Text("ชื่อผู้ใช้")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            if editingUsername {
                                TextField("ชื่อผู้ใช้", text: $tempUsername)
                                    .textFieldStyle(.roundedBorder)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(themeGreen, lineWidth: 2)
                                    )
                                    .onSubmit {
                                        saveUsername()
                                    }
                                
                                Button(action: saveUsername) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(themeGreen)
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
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 8)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                
                                Button(action: {
                                    tempUsername = user.username
                                    editingUsername = true
                                    usernameError = nil
                                }) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(themeGreen)
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
                    VStack(alignment: .leading, spacing: 5) {
                        Text("อีเมล")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(user.email)
                            .font(.body)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    
                    // ปุ่มออกจากระบบ
                    Button("ออกจากระบบ") {
                        authViewModel.logout()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                } else {
                    Text("ยังไม่ได้เข้าสู่ระบบ")
                }
                }
                .padding()
            }
            .background(backgroundGradient)
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingView(authViewModel: authViewModel)) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(navBarColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                loadProfileImage()
            }
            .onChange(of: authViewModel.currentUser?.id) { _ in
                loadProfileImage()
                editingUsername = false
                tempUsername = ""
                usernameError = nil
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