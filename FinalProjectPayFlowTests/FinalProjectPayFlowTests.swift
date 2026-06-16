
import Testing
import CoreData
@testable import FinalProjectPayFlow


private struct PricingRepositoryFake: PricingRepositoryProtocol {
    func fetchRemoteServices() async throws -> [RemoteService] {
        [
            RemoteService(id: 1, title: "Serviço A", price: 50, category: "streaming", description: "teste"),
            RemoteService(id: 2, title: "Serviço B", price: 100, category: "música", description: "teste")
        ]
    }
}


@MainActor
private func makeRepositorioEmMemoria() -> AssinaturaRepositoryProtocol {
    let controller = PersistenceController(inMemory: true)
    return CoreDataAssinaturaRepository(context: controller.container.viewContext)
}


struct MesesTests {

    @Test func listaTemDozeMeses() {
        #expect(Meses.todos.count == 12)
    }

    @Test func janeiroEhOPrimeiroMes() {
        #expect(Meses.indice(de: "Janeiro") == 0)
    }

    @Test func dezembroEhOUltimoMes() {
        #expect(Meses.indice(de: "Dezembro") == 11)
    }

    @Test func mesDesconhecidoVaiParaOFinal() {
        #expect(Meses.indice(de: "MesQueNaoExiste") == Meses.todos.count)
        #expect(Meses.indice(de: nil) == Meses.todos.count)
    }
}


@Suite(.serialized)
struct FakeAuthRepositoryTests {

    init() {
        UserDefaults.standard.removeObject(forKey: "usuariosCadastrados")
    }

    @Test func loginComSenhaDeDemonstracaoFunciona() async throws {
        let repo = FakeAuthRepository()
        try await repo.login(email: "teste@email.com", password: "123456")
    }

    @Test func loginComSenhaErradaFalha() async {
        let repo = FakeAuthRepository()
        await #expect(throws: AuthError.self) {
            try await repo.login(email: "teste@email.com", password: "senha-errada")
        }
    }

    @Test func loginComEmailVazioFalha() async {
        let repo = FakeAuthRepository()
        await #expect(throws: AuthError.self) {
            try await repo.login(email: "   ", password: "123456")
        }
    }

    @Test func cadastrarEEntrarComContaNovaFunciona() async throws {
        let repo = FakeAuthRepository()
        try await repo.register(email: "novo@email.com", password: "minhasenha")
        try await repo.login(email: "novo@email.com", password: "minhasenha")
    }

    @Test func cadastrarEmailRepetidoFalha() async throws {
        let repo = FakeAuthRepository()
        try await repo.register(email: "repetido@email.com", password: "minhasenha")
        await #expect(throws: AuthError.self) {
            try await repo.register(email: "repetido@email.com", password: "outrasenha")
        }
    }

    @Test func cadastrarComSenhaCurtaFalha() async {
        let repo = FakeAuthRepository()
        await #expect(throws: AuthError.self) {
            try await repo.register(email: "novo@email.com", password: "123")
        }
    }
}


@MainActor
struct CoreDataAssinaturaRepositoryTests {

    @Test func salvarCriaUmaDespesaNova() throws {
        let repo = makeRepositorioEmMemoria()

        try repo.save(despesa: nil, nome: "Streaming", valor: 39.90, mes: "Janeiro", emailUsuario: "teste@test.com")

        let itens = try repo.fetchAll(emailUsuario: "teste@test.com")
        #expect(itens.count == 1)
        #expect(itens.first?.nomeDespesa == "Streaming")
    }

    @Test func fetchAllOrdenaPelaOrdemDoCalendario() throws {
        let repo = makeRepositorioEmMemoria()

        try repo.save(despesa: nil, nome: "C", valor: 10, mes: "Dezembro", emailUsuario: "teste@test.com")
        try repo.save(despesa: nil, nome: "A", valor: 10, mes: "Janeiro", emailUsuario: "teste@test.com")
        try repo.save(despesa: nil, nome: "B", valor: 10, mes: "Abril", emailUsuario: "teste@test.com")

        let meses = try repo.fetchAll(emailUsuario: "teste@test.com").map { $0.mes ?? "" }
        #expect(meses == ["Janeiro", "Abril", "Dezembro"])
    }

    @Test func excluirRemoveADespesa() throws {
        let repo = makeRepositorioEmMemoria()

        try repo.save(despesa: nil, nome: "Internet", valor: 99.90, mes: "Maio", emailUsuario: "teste@test.com")
        let despesa = try #require(try repo.fetchAll(emailUsuario: "teste@test.com").first)

        try repo.delete(despesa)

        #expect(try repo.fetchAll(emailUsuario: "teste@test.com").isEmpty)
    }

    @Test func resumoSomaEAgrupaPorMes() throws {
        let repo = makeRepositorioEmMemoria()

        try repo.save(despesa: nil, nome: "Streaming", valor: 30, mes: "Janeiro", emailUsuario: "teste@test.com")
        try repo.save(despesa: nil, nome: "Música", valor: 20, mes: "Janeiro", emailUsuario: "teste@test.com")
        try repo.save(despesa: nil, nome: "Nuvem", valor: 10, mes: "Março", emailUsuario: "teste@test.com")

        let resumo = try repo.resumo(emailUsuario: "teste@test.com")

        #expect(resumo.totalAssinaturas == 3)
        #expect(resumo.totalMensal == 60)
        #expect(resumo.porMes.count == 2)

        // Janeiro vem primeiro e concentra a soma de 30 + 20.
        #expect(resumo.porMes.first?.month == "Janeiro")
        #expect(resumo.porMes.first?.total == 50)
    }
}


// Testa as validações do formulário de despesas.
@MainActor
struct FormDespesasViewModelTests {

    @Test func salvarComNomeVazioDevolveErro() {
        let viewModel = FormDespesasViewModel()

        let sucesso = viewModel.salvar(
            despesa: nil,
            nome: "   ",
            valor: 10,
            mes: "Janeiro",
            emailUsuario: "teste@test.com",
            repository: makeRepositorioEmMemoria()
        )

        #expect(sucesso == false)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func salvarComValorZeradoDevolveErro() {
        let viewModel = FormDespesasViewModel()

        let sucesso = viewModel.salvar(
            despesa: nil,
            nome: "Streaming",
            valor: 0,
            mes: "Janeiro",
            emailUsuario: "teste@test.com",
            repository: makeRepositorioEmMemoria()
        )

        #expect(sucesso == false)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func salvarComDadosValidosFunciona() {
        let viewModel = FormDespesasViewModel()

        let sucesso = viewModel.salvar(
            despesa: nil,
            nome: "Streaming",
            valor: 29.90,
            mes: "Janeiro",
            emailUsuario: "teste@test.com",
            repository: makeRepositorioEmMemoria()
        )

        #expect(sucesso == true)
        #expect(viewModel.errorMessage == nil)
    }
}


/* Testa as validações da tela de criar conta.
   Os cenários abaixo falham antes de chamar o repositório,
   então nenhum usuário é gravado no aparelho. */
@MainActor
struct CriarContaViewModelTests {

    @Test func emailVazioMostraErro() async {
        let viewModel = CriarContaViewModel()

        await viewModel.criarConta(
            email: "   ",
            senha: "minhasenha",
            confirmarSenha: "minhasenha",
            authRepository: FakeAuthRepository()
        )

        #expect(viewModel.cadastroConcluido == false)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func senhaCurtaMostraErro() async {
        let viewModel = CriarContaViewModel()

        await viewModel.criarConta(
            email: "a@a.com",
            senha: "123",
            confirmarSenha: "123",
            authRepository: FakeAuthRepository()
        )

        #expect(viewModel.cadastroConcluido == false)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func senhasDiferentesMostramErro() async {
        let viewModel = CriarContaViewModel()

        await viewModel.criarConta(
            email: "a@a.com",
            senha: "minhasenha",
            confirmarSenha: "outrasenha",
            authRepository: FakeAuthRepository()
        )

        #expect(viewModel.cadastroConcluido == false)
        #expect(viewModel.errorMessage != nil)
    }
}


/* Testa o controle de sessão.
   Roda em série porque a sessão é persistida no UserDefaults compartilhado. */
@MainActor
@Suite(.serialized)
struct SessionStoreTests {

    init() {
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "loggedUserEmail")
    }

    @Test func loginGuardaEmailEMarcaSessao() {
        let sessao = SessionStore()

        sessao.login(email: "will@email.com")

        #expect(sessao.isLoggedIn == true)
        #expect(sessao.email == "will@email.com")

        sessao.logout()
    }

    @Test func logoutLimpaASessao() {
        let sessao = SessionStore()
        sessao.login(email: "will@email.com")

        sessao.logout()

        #expect(sessao.isLoggedIn == false)
        #expect(sessao.email.isEmpty)
    }
}


// Testa o fluxo de login de ponta a ponta com o repositório fake.
@MainActor
@Suite(.serialized)
struct LoginViewModelTests {

    init() {
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "loggedUserEmail")
        UserDefaults.standard.removeObject(forKey: "usuariosCadastrados")
    }

    @Test func loginComSenhaCertaAtualizaASessao() async {
        let viewModel = LoginViewModel()
        let sessao = SessionStore()
        sessao.logout()

        await viewModel.login(
            email: "teste@email.com",
            password: "123456",
            authRepository: FakeAuthRepository(),
            sessionStore: sessao
        )

        #expect(viewModel.errorMessage == nil)
        #expect(sessao.isLoggedIn == true)
        #expect(viewModel.isLoading == false)

        sessao.logout()
    }

    @Test func loginComSenhaErradaMostraErroENaoLoga() async {
        let viewModel = LoginViewModel()
        let sessao = SessionStore()
        sessao.logout()

        await viewModel.login(
            email: "teste@email.com",
            password: "senha-errada",
            authRepository: FakeAuthRepository(),
            sessionStore: sessao
        )

        #expect(viewModel.errorMessage != nil)
        #expect(sessao.isLoggedIn == false)
        #expect(viewModel.isLoading == false)
    }
}


// Testa a exclusão feita a partir da lista de despesas.
@MainActor
struct CadastroViewModelTests {

    @Test func excluirRemoveAsDespesasInformadas() throws {
        let repo = makeRepositorioEmMemoria()
        try repo.save(despesa: nil, nome: "Streaming", valor: 30, mes: "Janeiro", emailUsuario: "teste@test.com")
        let despesa = try #require(try repo.fetchAll(emailUsuario: "teste@test.com").first)

        let viewModel = CadastroViewModel()
        viewModel.deleteDespesa([despesa], repository: repo)

        #expect(try repo.fetchAll(emailUsuario: "teste@test.com").isEmpty)
        #expect(viewModel.errorMessage == nil)
    }
}


// Testa o carregamento da tela principal usando o repositório de preços fake.
@MainActor
struct MesesDespesasViewModelTests {

    @Test func carregarPreencheTotaisEServicos() async throws {
        let repo = makeRepositorioEmMemoria()
        try repo.save(despesa: nil, nome: "Streaming", valor: 40, mes: "Janeiro", emailUsuario: "teste@test.com")

        let viewModel = MesesDespesasViewModel()
        await viewModel.load(
            assinaturaRepository: repo,
            pricingRepository: PricingRepositoryFake(),
            emailUsuario: "teste@test.com"
        )

        #expect(viewModel.totalAssinaturas == 1)
        #expect(viewModel.totalMensal == 40)
        #expect(viewModel.remoteServices.count == 2)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }
}


// Testa o resumo mensal e as sugestões de economia.
@MainActor
struct ResumoMensalViewModelTests {

    @Test func geraSugestaoApenasParaDespesaAcimaDaMedia() async throws {
        let repo = makeRepositorioEmMemoria()

        try repo.save(despesa: nil, nome: "Cara", valor: 200, mes: "Janeiro", emailUsuario: "teste@test.com")
        try repo.save(despesa: nil, nome: "Barata", valor: 10, mes: "Janeiro", emailUsuario: "teste@test.com")

        let viewModel = ResumoMensalViewModel()
        await viewModel.load(
            assinaturaRepository: repo,
            pricingRepository: PricingRepositoryFake(),
            emailUsuario: "teste@test.com"
        )

        #expect(viewModel.porMes.count == 1)
        #expect(viewModel.sugestoesEconomia.count == 1)
        #expect(viewModel.sugestoesEconomia.first?.nome == "Cara")
        #expect(viewModel.errorMessage == nil)
    }
}
