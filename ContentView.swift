import SwiftUI

struct ContentView: View {
    @StateObject var authViewModel = AuthViewModel()
    
    var body: some View {
        switch authViewModel.currentScreen {
        case .login:
            LoginView(viewModel: authViewModel)
        case .register:
            RegisterView(viewModel: authViewModel)
        case .mygarden:
            MainTabView(authViewModel: authViewModel)
        }
    }
}