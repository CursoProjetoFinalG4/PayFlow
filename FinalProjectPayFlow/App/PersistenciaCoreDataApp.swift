import SwiftUI
import CoreData

@main

struct PersistenciaCoreDataApp: App {

    let persistenceController = PersistenceController.shared

    @StateObject private var sessionStore = SessionStore()

    @StateObject private var dependencies = AppDependencies.live

    init() {
        // Garante que o título grande da NavigationBar (scroll edge) apareça
        let creme = UIColor(red: 0.98, green: 0.96, blue: 0.88, alpha: 0.95)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = creme
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    // Este trecho monta a cena principal do aplicativo.
        
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(sessionStore)
                .environmentObject(dependencies)
        }
    }
}
