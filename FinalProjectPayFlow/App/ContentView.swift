
import SwiftUI
import CoreData

struct ContentView: View {

    @EnvironmentObject private var sessionStore: SessionStore

    var body: some View {
        Group {
            if sessionStore.isLoggedIn {
                MesesDespesasView()
            } else {
                LoginView()
            }
        }
    }
}


#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(SessionStore())
        .environmentObject(AppDependencies.live)
}
