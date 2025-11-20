import SwiftUI

struct MainTabView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject var plantViewModel = PlantViewModel()
    @StateObject var reminderViewModel = ReminderViewModel()
    
    var body: some View {
        TabView {
            MyGardenView(
                plantViewModel: plantViewModel,
                reminderViewModel: reminderViewModel,
                authViewModel: authViewModel
            )
                .tabItem {
                    Label("My Garden", systemImage: "leaf")
                }
            
            GalleryView(authViewModel: authViewModel)
                .tabItem {
                    Label("Gallery", systemImage: "photo.on.rectangle")
                }
            
            RemindersView(
                reminderViewModel: reminderViewModel,
                plantViewModel: plantViewModel,
                authViewModel: authViewModel
            )
                .tabItem {
                    Label("Reminders", systemImage: "alarm")
                }
            
            ProfileView(authViewModel: authViewModel)
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
        .onAppear {
            // เชื่อมต่อ plantViewModel กับ reminderViewModel
            reminderViewModel.plantViewModel = plantViewModel
        }
        .alert("⏰ ถึงเวลาที่ตั้งไว้แล้ว!", isPresented: $reminderViewModel.showAlert) {
            Button("ตกลง", role: .cancel) {
                reminderViewModel.showAlert = false
            }
        } message: {
            Text(reminderViewModel.alertMessage)
        }
    }
}