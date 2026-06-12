//
//  FinalProjectPayFlowTests.swift
//  FinalProjectPayFlowTests
//
//  Created by Santos, Adriano da Silva on 01/06/26.
//

import Testing
import CoreData
@testable import FinalProjectPayFlow

// MARK: - Apoios usados pelos testes

/* Implementação falsa do repositório de preços.
   Devolve sempre a mesma lista fixa, sem depender de internet,
   deixando os testes rápidos e previsíveis.
   A média dos preços abaixo é 75 (50 e 100). */
private struct PricingRepositoryFake: PricingRepositoryProtocol {
    func fetchRemoteServices() async throws -> [RemoteService] {
        [
            RemoteService(id: 1, title: "Serviço A", price: 50, category: "streaming", description: "teste"),
            RemoteService(id: 2, title: "Serviço B", price: 100, category: "música", description: "teste")
        ]
    }
}

/* Cria um repositório de despesas usando Core Data em memória.
   Cada chamada devolve um banco novo e vazio, então um teste
   nunca enxerga os dados criados por outro. */
private func makeRepositorioEmMemoria() -> AssinaturaRepositoryProtocol {
    let controller = PersistenceController(inMemory: true)
    return CoreDataAssinaturaRepository(context: controller.container.viewContext)
}

// MARK: - Meses

// Testa a fonte única de meses, usada na ordenação cronológica do app.
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

    // Meses desconhecidos (ou nulos) precisam ir para o final da ordenação.
    @Test func mesDesconhecidoVaiParaOFinal() {
        #expect(Meses.indice(de: "MesQueNaoExiste") == Meses.todos.count)
        #expect(Meses.indice(de: nil) == Meses.todos.count)
    }
}

// MARK: - FakeAuthRepository

/* Testa o repositório de autenticação local.
   A suíte roda em série porque os usuários ficam no UserDefaults,
   que é compartilhado; em paralelo um teste atrapalharia o outro. */
@Suite(.serialized)
struct FakeAuthRepositoryTests {

    init() {
        // Limpa os usuários salvos antes de cada teste.
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

// MARK: - CoreDataAssinaturaRepository

// Testa o repositório local usando um banco em memória (nada vai para o disco).
// Roda em série porque todos compartilham o mesmo store /dev/null em memória.
@Suite(.serialized)
struct CoreDataAssinaturaRepositoryTests {

    @Test func salvarCriaUmaDespesaNova() throws {
        let repo = makeRepositorioEmMemoria()

        try repo.save(despesa: nil, nome: "Streaming", valor: 39.90, mes: "Janeiro", emailUsuario: "teste@test.com")

        let itens = try repo.fetchAll(emailUsuario: "teste@test.com")
        #expect(itens.count == 1)
        #expect(itens.first?.nomeDespesa == "Streaming")
    }

    // A lista precisa sair na ordem do calendário, não em ordem alfabética.
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

// MARK: - FormDespesasViewModel

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

// MARK: - CriarContaViewModel

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

// MARK: - SessionStore

/* Testa o controle de sessão.
   Roda em série porque a sessão é persistida no UserDefaults compartilhado. */
@MainActor
@Suite(.serialized)
struct SessionStoreTests {

    @Test func loginGuardaEmailEMarcaSessao() {
        let sessao = SessionStore()

        sessao.login(email: "will@email.com")

        #expect(sessao.isLoggedIn == true)
        #expect(sessao.email == "will@email.com")

        // Limpa para não influenciar outros testes.
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

// MARK: - LoginViewModel

// Testa o fluxo de login de ponta a ponta com o repositório fake.
@MainActor
@Suite(.serialized)
struct LoginViewModelTests {

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

        // Limpa para não influenciar outros testes.
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

// MARK: - CadastroViewModel

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

// MARK: - MesesDespesasViewModel

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

// MARK: - ResumoMensalViewModel

// Testa o resumo mensal e as sugestões de economia.
@MainActor
struct ResumoMensalViewModelTests {

    @Test func geraSugestaoApenasParaDespesaAcimaDaMedia() async throws {
        let repo = makeRepositorioEmMemoria()

        // A média dos serviços fake é 75: só a despesa de 200 deve virar sugestão.
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
