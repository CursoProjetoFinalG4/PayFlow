
// Importa os recursos visuais e componentes de interface usados na construção das telas.
import SwiftUI
// Importa o suporte ao Core Data, utilizado para acesso e persistência de dados no aplicativo.
import CoreData

// Esta view funciona como ponto de entrada da interface e decide qual tela mostrar com base no estado da sessão.
struct ContentView: View {

    // Guarda o estado da sessão do usuário para decidir qual tela deve ser exibida.
    @EnvironmentObject private var sessionStore: SessionStore

    // Monta a tela principal do app e alterna entre login e área interna conforme o estado da sessão.
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

/* Esta pré-visualização serve para testar a ContentView no canvas do Xcode,
   já injetando o contexto do Core Data e os objetos compartilhados usados pela tela. */
#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(SessionStore())
        .environmentObject(AppDependencies.live)
}
