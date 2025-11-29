import SwiftUI
import UIKit

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
        .toolbarBackground(Color(red: 0x95 / 255.0, green: 0xB1 / 255.0, blue: 0x5D / 255.0), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .tint(Color(red: 0x12 / 255.0, green: 0x4D / 255.0, blue: 0x51 / 255.0))
        .onAppear {
            // เชื่อมต่อ plantViewModel กับ reminderViewModel
            reminderViewModel.plantViewModel = plantViewModel
// ตั้งค่าสีของ unselected tab items
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 0x95 / 255.0, green: 0xB1 / 255.0, blue: 0x5D / 255.0, alpha: 1.0)
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(red: 0xC7 / 255.0, green: 0xE0 / 255.0, blue: 0x97 / 255.0, alpha: 1.0)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(red: 0xC7 / 255.0, green: 0xE0 / 255.0, blue: 0x97 / 255.0, alpha: 1.0)]
            appearance.stackedLayoutAppearance.selected.iconColor = .white
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
.alert("⏰
 ถึงเวลาที่ตั้งไว้แล้ว!", isPresented: $reminderViewModel.showAlert) {
            Button("ตกลง", role: .cancel) {
                reminderViewModel.showAlert = false
            }
        } message: {
            Text(reminderViewModel.alertMessage)
        }
    }
}