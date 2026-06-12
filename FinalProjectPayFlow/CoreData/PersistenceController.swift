// Disponibiliza tipos básicos do sistema, como URL e outras estruturas usadas no arquivo.
import Foundation

// Traz os recursos do Core Data, responsáveis por criar e gerenciar a persistência.
import CoreData

// Essa estrutura concentra a configuração do Core Data e entrega um ponto único de acesso ao banco local.
struct PersistenceController {

    // Instância compartilhada usada pelo aplicativo para acessar a configuração principal do Core Data.
    static let shared = PersistenceController()

    // Container principal que carrega o modelo, o contexto e os arquivos de persistência.
    let container: NSPersistentContainer

    /* Esse inicializador prepara toda a base do Core Data para o aplicativo funcionar.
       Primeiro ele cria o container usando o nome do modelo de dados.
       Se o modo em memória estiver ligado, os dados não são gravados em disco,
       o que ajuda bastante em testes e pré-visualizações.
       Depois disso, o método carrega os arquivos de persistência e verifica se houve algum problema.
       Por fim, ajusta o contexto principal para mesclar mudanças vindas de outros contextos
       e define a política de conflito para priorizar os valores mais recentes do objeto atual. */
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Model")

        if inMemory {
            // Redireciona o armazenamento para um caminho temporário, evitando gravação real em disco.
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        // Habilita migração automática para suportar novas versões do modelo (ex.: campo emailUsuario).
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // Interrompe a execução caso o Core Data não consiga ser carregado corretamente.
                fatalError("Erro ao carregar Core Data: \(error)")
            }
        }

        // Faz o contexto principal receber automaticamente alterações feitas em outros contextos.
        container.viewContext.automaticallyMergesChangesFromParent = true

        // Define que, em caso de conflito, os dados do objeto em memória terão prioridade.
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
