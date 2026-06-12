// Importa os recursos necessários para montar a interface principal do aplicativo.
import SwiftUI

// Importa o Core Data, responsável pela camada de persistência dos dados.
import CoreData

// Marca esta estrutura como ponto inicial de execução do aplicativo.
@main

// Esta estrutura representa a aplicação inteira e define como o app é inicializado.
struct PersistenciaCoreDataApp: App {

    // Mantém uma referência compartilhada ao controlador de persistência usado em todo o app.
    let persistenceController = PersistenceController.shared

    // Guarda o estado da sessão do usuário enquanto o aplicativo estiver em execução.
    @StateObject private var sessionStore = SessionStore()

    // Centraliza as dependências compartilhadas para facilitar o acesso entre as telas.
    @StateObject private var dependencies = AppDependencies.live

    init() {
        // Garante que o título grande da NavigationBar (scroll edge) apareça
        // sempre preto, independentemente da cor de fundo da barra.
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

    /* Este trecho monta a cena principal do aplicativo.
       Aqui é criado o grupo de janelas e também são injetados os objetos compartilhados,
       como o contexto do Core Data, o controle de sessão e as dependências usadas pelas views.
       Dessa forma, as telas internas conseguem acessar essas informações sem precisar
       criar tudo novamente por conta própria. */
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(sessionStore)
                .environmentObject(dependencies)
        }
    }
}
