# Auria — Gestão de Manutenção Predial (API ASP.NET Core + App Flutter)

Trabalho prático da disciplina de **Engenharia de Software** — IF Sudeste MG, Campus Muriaé (2026).

Evolução do sistema **Aura**, que antes funcionava só no aplicativo Flutter com armazenamento local,
para uma arquitetura **cliente-servidor**: o app Flutter passa a consumir a **AuriaAPI**, uma API REST
em ASP.NET Core responsável pelas regras de negócio, pelo acesso ao banco MySQL, pela autenticação
JWT e pelo cache.

```
┌──────────────────┐   HTTP/HTTPS + JWT    ┌───────────────────────┐   EF Core   ┌─────────┐
│  App Flutter     │ ────────────────────▶ │  AuriaAPI             │ ──────────▶ │  MySQL  │
│  (cliente)       │ ◀──── ResultWrapper ── │  (ASP.NET Core 9)     │ ◀────────── │         │
└──────────────────┘                        └───────────────────────┘             └─────────┘
```

## Integrantes da equipe

- Sabrina Caetano Fontes — sabrinacfontes@gmail.com
- Alexandre do Amaral Quintão — aleequintogti@gmail.com

## Sumário

1. [Descrição do sistema](#descrição-do-sistema)
2. [Tecnologias utilizadas](#tecnologias-utilizadas)
3. [Estrutura do repositório e da arquitetura](#estrutura-do-repositório-e-da-arquitetura)
4. [Configuração (banco, JWT e admin inicial)](#configuração-banco-jwt-e-admin-inicial)
5. [Como executar a API](#como-executar-a-api)
6. [Como executar o aplicativo Flutter](#como-executar-o-aplicativo-flutter)
   - [Dados de demonstração e logins de teste](#dados-de-demonstração-e-logins-de-teste)
   - [Acessibilidade](#acessibilidade)
7. [Autenticação JWT](#autenticação-jwt)
8. [Estratégia de cache](#estratégia-de-cache)
9. [ResultWrapper (padronização das respostas)](#resultwrapper-padronização-das-respostas)
10. [Principais endpoints](#principais-endpoints)
11. [Exemplos de requisições e respostas](#exemplos-de-requisições-e-respostas)
12. [Reproduzindo o projeto do zero (passo a passo)](#reproduzindo-o-projeto-do-zero-passo-a-passo)

---

## Descrição do sistema

O Auria centraliza a manutenção predial e patrimonial de uma organização:

| Módulo | O que faz |
|---|---|
| **Ambientes** | Locais físicos (salas, blocos, andares) onde os ativos ficam. |
| **Ativos** | Equipamentos/bens patrimoniais, vinculados a um ambiente, com estado de conservação. |
| **Chamados** | Solicitações de manutenção (corretiva, preventiva ou preditiva) abertas por um usuário. |
| **Ordens de Serviço** | Execução de um chamado por um técnico: peças consumidas, tempo gasto, parecer e custos. |
| **Estoque** | Peças e materiais; o estoque é debitado automaticamente ao registrar o consumo numa OS. |
| **Notificações** | Avisos gerados pela API (novo chamado, OS designada, chamado concluído, estoque baixo). |
| **Indicadores** | Painel de BI: taxa de conclusão, custos, tempo médio de atendimento, ativos com mais falhas. |
| **Planejamento** | Cronograma de preventivas e alertas de ativos que precisam de manutenção. |

**Perfis de usuário:**

- `Solicitante`: abre chamados e acompanha os próprios chamados.
- `Tecnico`: executa as ordens de serviço designadas a ele e registra o consumo de peças.
- `Admin`: gerencia tudo (usuários, ambientes, ativos, estoque, aprovação de chamados, indicadores).

**Fluxo principal:**

1. O solicitante abre um chamado e os admins são notificados.
2. O admin aprova e designa um técnico: a OS é criada e o chamado passa a **Em Execucao**.
3. O técnico registra as peças usadas (o estoque é debitado) e conclui a OS.
4. O chamado passa a **Concluido** e o solicitante é notificado.

## Tecnologias utilizadas

**API**

- **.NET 9 / ASP.NET Core Web API** (C#)
- **Entity Framework Core 9** + **Pomelo.EntityFrameworkCore.MySql** (ORM, banco **MySQL 8**)
- **JWT Bearer** (`Microsoft.AspNetCore.Authentication.JwtBearer`) para autenticação
- **BCrypt.Net-Next** para o hash de senhas
- **IMemoryCache** (`Microsoft.Extensions.Caching.Memory`) para o cache em memória
- **Swagger / Swashbuckle** para documentação e teste dos endpoints
- **Data Annotations** (`[Required]`, `[EmailAddress]`, `[Range]`, `[AllowedValues]`…) para validar as entradas

**App**

- **Flutter / Dart**, alvo principal Windows Desktop (também roda na Web)
- `http` (requisições), `shared_preferences` (guarda o token), `get_it` (injeção de dependências)
- `fl_chart`, `pdf` e `printing` (painel de indicadores e relatório em PDF)

**Outros:** Git/GitHub, MySQL Workbench (modelo do banco em [`docs/aura_db.sql.mwb`](docs/aura_db.sql.mwb)).

## Estrutura do repositório e da arquitetura

```
ApiAuria/
├── AuriaAPI/               ← API ASP.NET Core
├── flutter_aura_2026/      ← App Flutter (cliente da API)
├── docs/
│   ├── DOCUMENTACAO_TECNICA.md   ← decisões de arquitetura (por que cada escolha)
│   └── aura_db.sql.mwb           ← modelo do banco (MySQL Workbench)
└── README.md
```

### Camadas da API (Clean Architecture)

```
AuriaAPI/
├── Domain/                 ← núcleo: não depende de nenhuma outra camada
│   ├── Entities/           Usuario, Ambiente, Ativo, Chamado, OrdemServico, ItemEstoque, Notificacao...
│   │                       (com regras: Chamado.Cancelar(), OrdemServico.Concluir(), ItemEstoque.Debitar()...)
│   ├── Constants/          Perfis, StatusChamado, Prioridades, TiposManutencao, EstadosConservacao
│   ├── Exceptions/         RegraDeNegocioException
│   └── Repositories/       Interfaces: IRepository<T>, IUnitOfWork, IChamadoRepository, ...
├── Application/            ← casos de uso: depende só do Domain
│   ├── Services/           AuthService, ChamadoService, OrdemServicoService, IndicadorService...
│   ├── Interfaces/         IChamadoService, ..., ICacheService, ITokenService, IPasswordHasher
│   ├── DTOs/               Contratos de entrada (com validação) e de saída
│   ├── Mappings/           Entidade → DTO
│   ├── Exceptions/         RecursoNaoEncontrado (404), AcessoNegado (403), Conflito (409)...
│   └── Common/             Result<T> (ResultWrapper), UsuarioLogado, ChavesCache
├── Infra/                  ← detalhes técnicos: implementa as interfaces acima
│   ├── EF/                 AuriaDbContext, EfUnitOfWork e Repositories/ (EF Core + MySQL)
│   ├── Cache/              MemoryCacheService (IMemoryCache + logs)
│   ├── Security/           JwtTokenService, BCryptPasswordHasher, JwtSettings
│   └── Seed/               AdminSeeder (cria o primeiro Admin)
├── Api/                    ← apresentação/HTTP
│   ├── Controllers/        Endpoints REST (finos: recebem, chamam o service, respondem)
│   ├── Middleware/         ExceptionHandlingMiddleware (erros → ResultWrapper)
│   └── Extensions/         Registro de dependências, JWT, Swagger, CORS, validação
├── Migrations/             Migrations do EF Core
└── Program.cs              Composition root
```

**Regra de dependência:** `Api → Application → Domain ← Infra`.

- O **Domain** não conhece EF Core, HTTP nem JWT.
- A **Application** só enxerga interfaces: os repositórios, o cache, o gerador de token e o hash de senha.
- A **Infra** implementa essas interfaces. A ligação entre interface e implementação acontece só no `Program.cs`, por injeção de dependência.
- Os **Controllers** não têm regra de negócio: chamam um service e devolvem o resultado.

As justificativas de cada decisão estão em [`docs/DOCUMENTACAO_TECNICA.md`](docs/DOCUMENTACAO_TECNICA.md).

### Camadas do app Flutter

```
flutter_aura_2026/lib/
├── core/network/   ApiClient (HTTP + JWT + ResultWrapper), AuthSession (token), api_config (URL da API)
├── core/ui/        design system: cores (claro/escuro/alto contraste), tipografia, botões, cards, painéis, logo
├── core/acessibilidade/  preferências de acessibilidade (salvas no aparelho) e o painel de ajustes
├── data/           datasources/remote (chamadas HTTP) e repositories (implementações)
├── domain/         entidades, interfaces de repositório e domain services
└── pages/          login, shell (menu lateral por perfil + estado compartilhado) e views (telas)
```

**Interface:** depois do login, todas as telas ficam dentro de um layout único com menu lateral
(vira gaveta em telas estreitas), busca, alternância de tema claro/escuro e notificações. O menu muda
conforme o perfil:

- **Admin:** Painel, Chamados (quadro kanban com aprovação no painel lateral), Ordens de serviço,
  Preventivas, Estoque, Ativos, Ambientes, Usuários, Indicadores e Notificações.
- **Técnico:** Meu dia, Minhas ordens (execução com registro de peças e conclusão), Chamados, Estoque e Notificações.
- **Solicitante:** Início, Abrir chamado (em 3 etapas), Meus chamados (com linha do tempo) e Notificações.

Cadastros e detalhes abrem em painéis que deslizam da direita, sem sair da tela.

**Logo:** o símbolo do Auria é um prédio com uma janela acesa em âmbar ("alguém está cuidando dele").
Ele é desenhado em código (`core/ui/auria_logo.dart`), aparece no login e no menu, e também é o ícone
do app na web, no Android, no iOS e no macOS.

**Acessibilidade:** o app funciona com leitor de tela e só pelo teclado, e tem um painel de ajustes
(tamanho do texto, alto contraste, fonte de leitura facilitada e redução de animações). Detalhes na
seção [Acessibilidade](#acessibilidade).

## Configuração (banco, JWT e admin inicial)

Os valores sensíveis (senha do banco, chave do JWT e senha do admin) **não ficam no código nem no
Git**. O `appsettings.json` versionado tem esses campos vazios. Há duas formas de configurar.

**Opção A — `dotnet user-secrets` (recomendada).** Os valores ficam fora da pasta do projeto:

```bash
cd AuriaAPI
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=localhost;Database=aura_db;User=root;Password=SUA_SENHA;"
dotnet user-secrets set "Jwt:SecretKey" "uma-chave-aleatoria-com-pelo-menos-32-caracteres"
dotnet user-secrets set "AdminInicial:Nome" "Administrador"
dotnet user-secrets set "AdminInicial:Email" "admin@auria.com"
dotnet user-secrets set "AdminInicial:Senha" "Admin@123"
```

**Opção B — arquivo local.** Copie `AuriaAPI/appsettings.Development.example.json` para
`AuriaAPI/appsettings.Development.json` e preencha os valores. Esse arquivo está no `.gitignore`.

Em produção, use variáveis de ambiente, por exemplo `Jwt__SecretKey` e `ConnectionStrings__DefaultConnection`.

| Chave | Para que serve |
|---|---|
| `ConnectionStrings:DefaultConnection` | Conexão com o MySQL (o banco `aura_db` é criado pela migration). |
| `Jwt:SecretKey` | Chave de assinatura do token, com **no mínimo 32 caracteres**. A API não inicia sem ela. |
| `Jwt:Issuer` / `Jwt:Audience` / `Jwt:ExpiracaoHoras` | Emissor, público e validade do token (padrão: `AuriaAPI`, `AuriaAPI`, 8h). |
| `AdminInicial:*` | Se ainda não existir nenhum Admin, a API cria este usuário ao iniciar. |
| `DadosDemonstracao:Ativar` / `SenhaUsuarios` | Só em Development: cria usuários de teste, ambientes, ativos, estoque e chamados de exemplo (veja [Dados de demonstração](#dados-de-demonstração-e-logins-de-teste)). Não são dados sensíveis; em produção nada é criado. |

### Banco de dados

- **MySQL 8** acessado pelo **EF Core** com o provedor **Pomelo**.
- Tabelas: `usuario`, `ambiente`, `ativo`, `chamado`, `ordem_servico`, `ordem_servico_item_estoque`, `item_estoque` e `notificacao`. O modelo está em [`docs/aura_db.sql.mwb`](docs/aura_db.sql.mwb).
- O banco é criado pela migration `InitialCreate`, versionada em `AuriaAPI/Migrations`, com `dotnet ef database update`.
- As senhas são gravadas com **hash BCrypt**, nunca em texto puro.

## Como executar a API

Pré-requisitos: **.NET 9 SDK**, **MySQL 8** rodando e a ferramenta do EF (`dotnet tool install --global dotnet-ef`).

```bash
git clone https://github.com/FontesSabrina/ApiAuria.git
cd ApiAuria/AuriaAPI
dotnet restore
# configure os segredos (seção anterior)
dotnet ef database update      # cria o banco aura_db e as tabelas
dotnet run
```

- A API sobe em `http://localhost:5131`.
- O Swagger fica em **http://localhost:5131/swagger**. Use o botão **Authorize** para colar o token.
- O arquivo [`AuriaAPI/AuriaAPI.http`](AuriaAPI/AuriaAPI.http) tem o **roteiro completo da demonstração**. Ele roda no VS Code (extensão REST Client) ou no Visual Studio.

## Como executar o aplicativo Flutter

Pré-requisitos: **Flutter SDK** e a **API rodando**.

```bash
cd ApiAuria/flutter_aura_2026
flutter pub get
flutter run -d windows     # ou: flutter run -d chrome
```

- O endereço da API fica em `flutter_aura_2026/lib/core/network/api_config.dart`. O padrão é `http://localhost:5131/api`.
  - Num emulador Android, use `http://10.0.2.2:5131/api`.
  - Num celular físico, use o IP do computador na rede.
- Entre com o **admin inicial** (configurado em `AdminInicial`) e cadastre técnicos e solicitantes em **Cadastro de Usuários**.
- Para rodar os testes do app: `flutter test`.

### Dados de demonstração e logins de teste

Ao rodar a API em **Development** (o padrão do `dotnet run`), o `DadosDemonstracaoSeeder` deixa o
sistema pronto para a apresentação. Ele **só cria o que ainda não existe** (compara e-mail, nome do
ambiente, patrimônio e nome do item), então não duplica nem altera o que você já cadastrou.

| Perfil | E-mail | Senha |
|---|---|---|
| Admin | o configurado em `AdminInicial:Email` | a configurada em `AdminInicial:Senha` |
| Técnico | `tecnico@auria.com` (Carlos Lima) | `Demo@2026` |
| Técnico | `tecnico2@auria.com` (Paula Souza) | `Demo@2026` |
| Solicitante | `solicitante@auria.com` (Ana Martins) | `Demo@2026` |
| Solicitante | `solicitante2@auria.com` (Bruno Costa) | `Demo@2026` |

Também são criados:

- 7 ambientes, como Recepção, Sala 3 e Auditório;
- 8 ativos (ar-condicionado, projetor, bebedouro...), alguns com estado ruim ou garantia vencida, para aparecerem nas **preventivas**;
- 10 itens de estoque, 3 deles abaixo do mínimo, para o **alerta de reposição**;
- 4 chamados abertos, criados só se o banco ainda não tiver nenhum chamado.

Para desligar, use `"DadosDemonstracao": { "Ativar": false }` (ou `dotnet user-secrets set "DadosDemonstracao:Ativar" "false"`).

### Acessibilidade

O professor não pediu, mas o app foi pensado para ser usado por pessoas com deficiência, seguindo as
diretrizes **WCAG 2.2** (nível AA). O botão **Acessibilidade** (ícone de pessoa) fica no cabeçalho de
todas as telas e na tela de login. Ele abre um painel com:

- **Tamanho do texto:** Normal, Grande, Maior ou Máximo. Multiplica o tamanho que a pessoa já usa no sistema, até 2×.
- **Alto contraste:** paleta com texto preto ou branco, bordas escuras e cores de status mais fortes, nos temas claro e escuro.
- **Fonte de leitura facilitada:** usa a *Atkinson Hyperlegible*, feita para baixa visão. Também ajuda na dislexia.
- **Tema escuro.**
- **Reduzir animações:** desliga transições e efeitos de movimento.

As escolhas ficam salvas no aparelho. O app também segue as configurações do próprio sistema: fonte
grande, texto em negrito, alto contraste e remover animações.

Além do painel:

- **Leitor de tela** (TalkBack, VoiceOver, NVDA):
  - todo botão de ícone tem nome;
  - campos de formulário são lidos junto com o rótulo;
  - títulos são marcados como cabeçalho, para a navegação por títulos;
  - avisos e erros são anunciados automaticamente;
  - a troca de página é anunciada;
  - gráficos e barras têm uma descrição em texto dos dados.
- **Teclado:** dá para usar tudo com Tab, Shift+Tab, Enter e Esc (fecha painéis), e o foco aparece com um contorno bem visível.
- **Cor nunca é a única informação:** status, prioridade e nível de estoque sempre têm texto junto da cor.
- **Contraste:** textos com pelo menos 4,5:1 nas paletas normais e 7:1 no alto contraste.
- **Toque:** áreas de toque de pelo menos 44 px.
- **Web:** página em `lang="pt-BR"`, com a acessibilidade do Flutter ligada desde o início.

A lista completa, com cada critério da WCAG, está em [`docs/ACESSIBILIDADE.md`](docs/ACESSIBILIDADE.md).

## Autenticação JWT

| Etapa | Onde acontece |
|---|---|
| **Cadastro** | `POST /api/auth/register` é público e cria um `Solicitante`. Usuários com outros perfis são criados por um Admin em `POST /api/usuarios`. |
| **Validação das credenciais** | `AuthService.LoginAsync` busca o usuário pelo e-mail e compara a senha com o hash BCrypt. |
| **Geração do token** | `JwtTokenService` assina com HMAC-SHA256. Claims: `sub` (id), `name`, `email`, `role` (perfil) e `jti`. Validade de 8h. |
| **Retorno ao cliente** | A resposta do login traz `token` e `expiraEm`. O app guarda o token e o envia em `Authorization: Bearer <token>`. |
| **Validação nas requisições** | O middleware JWT confere assinatura, emissor, público e expiração (`ClockSkew = 0`). Configuração em `Api/Extensions/AutenticacaoExtensions.cs`. |
| **Restrição de acesso** | `[Authorize]` exige um token válido. `[Authorize(Roles = "Admin")]` e `"Tecnico,Admin"` restringem por perfil. Regras finas ficam nos services (ex.: só o técnico designado conclui a OS; o solicitante só vê os próprios chamados). |

- Sem token, ou com token inválido ou expirado, a resposta é **401**. Com token válido mas perfil sem permissão, é **403**. As duas seguem o formato do ResultWrapper.
- No app, um 401 encerra a sessão e leva de volta à tela de login.
- **Endpoints públicos:** só `POST /api/auth/register` e `POST /api/auth/login`.

## Estratégia de cache

O cache usa **IMemoryCache** com a estratégia **cache-aside**: o service consulta o cache e, se o
dado não estiver lá, busca no banco e guarda o resultado. A lógica fica em
`Infra/Cache/MemoryCacheService.cs`, por trás da interface `ICacheService`. Ele é usado em duas
funcionalidades reais:

| Dado em cache | Endpoint | Expiração | Invalidado quando |
|---|---|---|---|
| Lista de ambientes | `GET /api/ambientes` | 5 min | Um ambiente é criado, alterado ou removido. |
| Indicadores do BI | `GET /api/indicadores` | 2 min | Um chamado é aberto ou cancelado, uma OS é criada ou concluída, peças são consumidas ou um item de estoque é alterado. |

**Como identificar cada situação.** Todo passo aparece no **console da API**:

```
[CACHE MISS] 'ambientes:lista' não está no cache — buscando na fonte original (banco de dados).
[CACHE ARMAZENADO] 'ambientes:lista' guardado no cache por 5 minuto(s).
[CACHE HIT] 'ambientes:lista' devolvido do cache, sem consultar o banco.
[CACHE INVALIDADO] 'ambientes:lista' removido do cache porque os dados foram alterados.
```

Nos indicadores, o campo `geradoEm` da resposta também mostra o cache funcionando: ele não muda
enquanto o resultado vem do cache.

**Por que esses dois dados?**

- A lista de ambientes muda pouco e é lida em várias telas.
- Os indicadores exigem percorrer todas as ordens e chamados, o que é caro para calcular a cada acesso.
- Dados que mudam a todo momento (como o saldo de estoque) não ficam em cache, para não mostrar valores desatualizados.

## ResultWrapper (padronização das respostas)

**Todas** as respostas seguem o formato de `Application/Common/Result.cs`, inclusive validação (400),
login inválido (401), falta de permissão (403), registro não encontrado (404), conflito (409) e erro
interno (500):

```json
{ "success": true, "message": "Ambiente criado com sucesso.", "data": { "id": 1, "identificacao": "Sala 101" }, "errors": [] }
```

```json
{ "success": false, "message": "Dados inválidos.", "data": null,
  "errors": ["O nome é obrigatório.", "Informe um e-mail válido."] }
```

Quem monta cada resposta:

- **Sucesso:** os controllers (`ApiControllerBase`).
- **Erros de regra:** os services lançam exceções e o `ExceptionHandlingMiddleware` as converte.
- **Validação:** o `InvalidModelStateResponseFactory`.
- **401/403:** os eventos do JWT.

## Principais endpoints

Todas as rotas começam com `/api`. Legenda: 🔓 público · 🔑 qualquer usuário logado · 👷 Técnico ou Admin · 👑 Admin.

| Método | Rota | Acesso | Descrição |
|---|---|---|---|
| POST | `/auth/register` | 🔓 | Cadastra um usuário (Solicitante) e retorna o token |
| POST | `/auth/login` | 🔓 | Autentica e retorna o token JWT |
| GET | `/usuarios?perfil=Tecnico` | 👑 | Lista usuários (filtro opcional por perfil) |
| GET | `/usuarios/{id}` | 👑 | Consulta um usuário |
| POST | `/usuarios` | 👑 | Cria usuário já com perfil |
| PUT | `/usuarios/{id}` | 👑 | Atualiza nome, e-mail, perfil e (opcional) senha |
| PUT | `/usuarios/{id}/perfil` | 👑 | Altera só o perfil |
| DELETE | `/usuarios/{id}` | 👑 | Remove (bloqueado se tiver chamados/OS) |
| GET | `/ambientes` | 🔑 | Lista ambientes **(cache)** |
| GET | `/ambientes/{id}` | 🔑 | Consulta um ambiente |
| POST / PUT / DELETE | `/ambientes` · `/ambientes/{id}` | 👑 | Cria / altera / remove (remoção bloqueada se houver ativos) |
| GET | `/ativos?ambienteId=1` | 🔑 | Lista ativos (filtro opcional por ambiente) |
| GET | `/ativos/{id}` | 🔑 | Consulta um ativo |
| POST / PUT / DELETE | `/ativos` · `/ativos/{id}` | 👑 | Cria / altera / remove (remoção bloqueada se houver chamados) |
| GET | `/chamados?status=Aberto` | 👷 | Lista todos os chamados |
| GET | `/chamados/meus` | 🔑 | Chamados do usuário logado |
| GET | `/chamados/{id}` | 🔑 | Consulta (o solicitante só vê os próprios) |
| POST | `/chamados` | 🔑 | Abre chamado (notifica os admins) |
| PUT | `/chamados/{id}/cancelar` | 🔑 | Cancela chamado "Aberto" (admin ou o próprio solicitante) |
| GET | `/ordemservico` | 👷 | Lista ordens de serviço |
| GET | `/ordemservico/minhas` | 👷 | Ordens designadas ao técnico logado |
| GET | `/ordemservico/{id}` | 👷 | Consulta uma OS |
| POST | `/ordemservico` | 👷 | Abre OS para um chamado "Aberto" e designa o técnico |
| POST | `/ordemservico/{id}/itens` | 👷 | Registra peças consumidas (debita o estoque) |
| PUT | `/ordemservico/{id}/concluir` | 👷 | Conclui a OS e o chamado (só o técnico designado ou um admin) |
| GET | `/itensestoque` | 🔑 | Lista itens de estoque |
| GET | `/itensestoque/criticos` | 🔑 | Itens abaixo do estoque mínimo |
| GET | `/itensestoque/{id}` | 🔑 | Consulta um item |
| POST / PUT / DELETE | `/itensestoque` · `/itensestoque/{id}` | 👑 | Cria / altera / remove (remoção bloqueada se já foi usado) |
| GET | `/notificacoes` | 🔑 | Notificações do usuário logado |
| POST | `/notificacoes` | 👑 | Envia um aviso manual a um usuário |
| PUT | `/notificacoes/{id}/lida` | 🔑 | Marca como lida (só as próprias) |
| DELETE | `/notificacoes/{id}` | 🔑 | Remove (só as próprias) |
| GET | `/indicadores` | 👑 | Indicadores do painel de BI **(cache)** |
| GET | `/planejamento/cronograma?data=2026-10-22` | 👑 | Ordens de serviço preventivas do dia |
| GET | `/planejamento/alertas` | 👑 | Ativos que precisam de manutenção preventiva |

## Exemplos de requisições e respostas

**Login — `POST /api/auth/login`**

```json
{ "email": "admin@auria.com", "senha": "Admin@123" }
```

```json
{
  "success": true,
  "message": "Login realizado com sucesso.",
  "data": {
    "id": 1,
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiraEm": "2026-10-22T20:00:00Z",
    "nome": "Administrador",
    "email": "admin@auria.com",
    "role": "Admin"
  },
  "errors": []
}
```

**Login inválido — 401**

```json
{ "success": false, "message": "Credenciais inválidas.", "data": null, "errors": ["Credenciais inválidas."] }
```

**Endpoint protegido sem token — `GET /api/ambientes` sem o header — 401**

```json
{ "success": false, "message": "Token de autenticação não informado. Envie o header 'Authorization: Bearer <token>'.", "data": null, "errors": ["..."] }
```

**Perfil sem permissão — um Solicitante em `GET /api/indicadores` — 403**

```json
{ "success": false, "message": "Você não tem permissão para acessar este recurso com o seu perfil de usuário.", "data": null, "errors": ["..."] }
```

**Abrir OS com peças — `POST /api/ordemservico`** (Admin ou Técnico)

```json
{ "chamadoId": 1, "tecnicoId": 2, "tempoGastoMinutos": 0, "custoMaoObra": 0,
  "itensUtilizados": [ { "itemEstoqueId": 3, "quantidadeUtilizada": 2 } ] }
```

Resposta **201** (resumida):

```json
{
  "success": true,
  "message": "Ordem de serviço criada com sucesso.",
  "data": {
    "id": 5, "chamadoId": 1, "tecnicoId": 2, "tecnicoNome": "Carlos",
    "custoMaoObra": 0, "custoPecas": 24.50, "custoTotal": 24.50,
    "concluida": false, "statusChamado": "Em Execucao",
    "ativoNome": "Luminária sala 101", "prioridade": "Alta",
    "itensUtilizados": [ { "itemEstoqueId": 3, "itemNome": "Lâmpada LED", "quantidadeUtilizada": 2, "custoUnitario": 12.25, "subtotal": 24.50 } ]
  },
  "errors": []
}
```

**Regra de negócio violada — concluir de novo uma OS já concluída — 400**

```json
{ "success": false, "message": "Esta ordem de serviço já foi concluída.", "data": null, "errors": ["Esta ordem de serviço já foi concluída."] }
```

**Excluir ambiente com ativos — 409**

```json
{ "success": false, "message": "Este ambiente possui ativos vinculados. Transfira ou remova os ativos antes de excluí-lo.", "data": null, "errors": ["..."] }
```

## Reproduzindo o projeto do zero (passo a passo)

1. Instale o **.NET 9 SDK**, o **MySQL 8**, o **Flutter SDK** e rode `dotnet tool install --global dotnet-ef`.
2. Clone o repositório: `git clone https://github.com/FontesSabrina/ApiAuria.git`.
3. Em `AuriaAPI/`, configure a connection string, a chave JWT e o admin inicial, como na seção [Configuração](#configuração-banco-jwt-e-admin-inicial).
4. Ainda em `AuriaAPI/`, rode `dotnet ef database update` e depois `dotnet run`. No console deve aparecer `Primeiro administrador criado`.
5. Abra `http://localhost:5131/swagger`, faça login com o admin e clique em **Authorize**.
6. Em `flutter_aura_2026/`, rode `flutter pub get` e depois `flutter run -d windows` (ou `-d chrome`).
7. No app, entre como admin e siga o fluxo:
   1. Cadastre um ambiente, um ativo, um item de estoque, um técnico e um solicitante.
   2. Entre como solicitante e abra um chamado.
   3. Entre como admin e aprove o chamado, designando o técnico.
   4. Entre como técnico, registre o consumo de peças e conclua a OS.
   5. Confira as notificações e o painel de indicadores.
