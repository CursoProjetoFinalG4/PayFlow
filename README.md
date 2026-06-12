# PayFlow

Aplicativo iOS para **organizar assinaturas e gastos recorrentes**. O usuário cria uma conta (ou usa a conta de demonstração), cadastra suas despesas mensais e acompanha totais por mês, vencimentos e sugestões de economia comparadas com preços de serviços externos.

Projeto desenvolvido como atividade de acompanhamento do curso de iOS nativo.

## Funcionalidades

- **Login e criação de conta** com validações (e-mail, senha mínima de 6 caracteres e confirmação)
- **Sessão persistente** — o app continua logado ao ser reaberto
- **Isolamento de dados por usuário** — cada conta vê apenas suas próprias despesas
- **Cadastro de despesas/assinaturas** com nome, valor e mês de vencimento
- **Edição e exclusão** de despesas (inclusive com gesto de swipe na lista)
- **Histórico por mês** e lista de **vencimentos** em ordem cronológica
- **Resumo mensal** com totais agrupados por mês
- **Sugestões de economia** — compara suas despesas com a média de preços de serviços externos (API)
- **Dashboard** com total de assinaturas e gasto mensal

## Tecnologias

| Camada | Tecnologia |
|---|---|
| Interface | SwiftUI |
| Arquitetura | MVVM + Repository Pattern |
| Persistência local | Core Data |
| Sessão / contas demo | UserDefaults |
| Rede | URLSession com async/await |
| API externa | [fakestoreapi.com](https://fakestoreapi.com) (preços de referência) |
| Testes | Swift Testing (`@Test`, `#expect`) |

## Estrutura do projeto

```
FinalProjectPayFlow/
├── App/
│   ├── PersistenciaCoreDataApp.swift   # @main — injeta Core Data, sessão e dependências
│   └── ContentView.swift               # Decide entre LoginView e área interna
├── CoreData/
│   └── PersistenceController.swift     # Container do Core Data (com modo em memória)
├── Data/
│   ├── APIClient.swift                 # Cliente HTTP genérico (async/await)
│   ├── AppDependencies.swift           # Injeção de dependências
│   ├── Repositories.swift              # Protocolos + implementações (auth, preços, despesas)
│   └── SessionStore.swift              # Estado da sessão do usuário
├── Model/
│   └── Model.xcdatamodeld              # Entidade Despesa — versão 2 inclui emailUsuario
├── View/
│   ├── LoginView.swift                 # Tela de login
│   ├── CriarContaView.swift            # Criação de conta
│   ├── MesesDespesasView.swift         # Home (dashboard + serviços externos)
│   ├── CadastroView.swift              # Lista/histórico de despesas
│   ├── FormDespesasView.swift          # Formulário de cadastro/edição
│   ├── DetalheDespesaView.swift        # Detalhe com editar/excluir
│   ├── VencimentosView.swift           # Lista de vencimentos
│   ├── ResumoMensalView.swift          # Totais por mês + sugestões de economia
│   ├── LoginEstilo.swift               # Identidade visual da tela de login
│   └── DesignSystem.swift              # Design system premium (cards, cores, estilos globais)
└── ViewModel/
    ├── LoginViewModel.swift
    ├── CriarContaViewModel.swift
    ├── MesesDespesasViewModel.swift
    ├── CadastroViewModel.swift
    ├── FormDespesasViewModel.swift
    └── ResumoMensalViewModel.swift
```

### Como a arquitetura funciona

```
View (SwiftUI)  →  ViewModel (@Published / @MainActor)  →  Repository (protocolo)  →  Core Data / API
```

- As **Views** apenas exibem estado e repassam ações.
- Os **ViewModels** concentram validações, loading e mensagens de erro.
- Os **repositórios** são definidos por **protocolos** (`AuthRepositoryProtocol`, `PricingRepositoryProtocol`, `AssinaturaRepositoryProtocol`), o que permite trocar as implementações reais por fakes nos testes.
- O `enum Meses` é a fonte única da lista de meses e garante **ordenação cronológica** (Janeiro → Dezembro), já que o mês é armazenado como texto.

## Como executar

### Requisitos

- macOS com **Xcode 16** ou superior
- Simulador iOS (ou dispositivo físico)

### Passos

1. Clone ou baixe este repositório
2. Abra `FinalProjectPayFlow.xcodeproj` no Xcode
3. Selecione um simulador (ex.: iPhone 16)
4. Rode com **⌘R**

### Conta de demonstração

| Campo | Valor |
|---|---|
| E-mail | qualquer e-mail válido |
| Senha | `123456` |

Também é possível criar uma conta nova pela tela **"Criar Nova Conta"** (fica salva localmente no aparelho).

## Testes

A suíte cobre `Meses`, autenticação, repositório Core Data (com banco **em memória**) e os principais ViewModels — 27 testes no total.

Para rodar: **⌘U** no Xcode, ou:

```bash
xcodebuild test -project FinalProjectPayFlow.xcodeproj \
  -scheme FinalProjectPayFlow \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Limitações conhecidas (escopo didático)

- A autenticação é **local/fake**: contas e senhas ficam no `UserDefaults` em texto puro. Em produção seria backend real + Keychain — a troca é direta graças ao `AuthRepositoryProtocol`.
- Os preços da API externa são usados apenas como **referência didática** para as sugestões de economia.
- O app não sincroniza dados entre dispositivos (persistência apenas local).

## Integrantes
- Isabelle Gomez
- Adriano da Silva
- Alan Fagner
- Luca Andrey
- Rafael Moura
- Willian Alexandre














