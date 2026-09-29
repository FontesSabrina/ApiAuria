# Auria API

API REST desenvolvida em ASP.NET Core para o sistema de gestão de manutenção predial
(ambientes, ativos, chamados, ordens de serviço e estoque), evoluindo o aplicativo Flutter
desenvolvido anteriormente de um armazenamento local para uma arquitetura cliente-servidor.

Trabalho prático da disciplina de Engenharia de Software — 2026.

## Integrantes da equipe

 Sabrina Fontes  - Sabrinacfontes@gmail.com
 Alexandre Quintão - aleequintogti@gmail.com 

## Descrição do sistema

A Auria API centraliza o processamento e a persistência de dados de um sistema de gestão
de manutenção predial:

- **Ambientes**: locais físicos (salas, blocos, andares) onde os ativos estão instalados.
- **Ativos**: equipamentos/bens patrimoniais vinculados a um ambiente.
- **Chamados**: solicitações de manutenção abertas por um usuário para um ativo.
- **Ordens de Serviço**: execução de um chamado por um técnico, com tempo gasto, parecer
  técnico e custo de mão de obra.
- **Itens de Estoque**: peças/materiais usados na execução de ordens de serviço.
- **Notificações**: avisos direcionados a um usuário.
- **Usuários**: autenticam via JWT e possuem um perfil (`Solicitante`, `Tecnico` ou `Admin`).

O aplicativo Flutter desenvolvido anteriormente consome esses endpoints via HTTP/HTTPS
em vez de acessar dados localmente.

## Tecnologias utilizadas

- **.NET 9 / ASP.NET Core Web API** — framework da API
- **Entity Framework Core 9** + **Pomelo.EntityFrameworkCore.MySql** — ORM e acesso a um
  banco **MySQL**
- **JWT Bearer** (`Microsoft.AspNetCore.Authentication.JwtBearer`) — autenticação
- **BCrypt.Net-Next** — hash de senhas
- **Microsoft.Extensions.Caching.Memory** (`IMemoryCache`) — cache em memória
- **Swashbuckle / Swagger** — documentação e teste interativo dos endpoints

## Estrutura da arquitetura

O projeto segue uma organização em camadas inspirada em Clean Architecture:

```
AuriaAPI/
├── Models/              # Entidades de domínio (Usuario, Ambiente, Ativo, Chamado, ...)
├── Domain/Repository/   # Abstrações de persistência (IRepository<T>, IUsuarioRepository, IChamadoRepository)
├── Application/
│   ├── DTOs/             # Contratos de entrada/saída dos endpoints (não expõem entidades EF)
│   └── Services/         # Regras de aplicação/casos de uso (AuthService, ChamadoService, AmbienteService, ...)
├── Infra/EF/             # Implementação de persistência (AuriaDbContext, RepositoryEF<T>, *RepositoryEF)
├── Core/Security/        # Geração de token JWT (JwtTokenGenerator)
├── Common/               # Result<T> — o ResultWrapper usado em todas as respostas
├── Controllers/          # Camada de apresentação/API (endpoints HTTP)
└── Program.cs            # Composition root: DI, autenticação, CORS, Swagger, pipeline HTTP
```

Regra de dependência: `Controllers` depende de `Application.Services`, que depende de
`Domain.Repository` (interfaces) e `Models`; as implementações concretas de persistência
(`Infra.EF`) são injetadas via DI e não são referenciadas diretamente pelos Controllers.

### Controle de acesso por perfil (Roles)

Usuários têm um `Perfil`: `Solicitante`, `Tecnico` ou `Admin` (claim `role` no JWT).
Todo endpoint autenticado exige apenas um token válido (`[Authorize]`), exceto:

- `POST /api/ordemservico` e `PUT /api/ordemservico/{id}/concluir` — restritos a
  `Tecnico` ou `Admin` (abrir/concluir uma ordem de serviço é atividade técnica);
- `PUT /api/auth/usuarios/{id}/perfil` — restrito a `Admin` (promove outro usuário a
  `Tecnico`/`Admin`).

O cadastro público (`POST /api/auth/register`) sempre cria o usuário como `Solicitante`.
Não existe endpoint para "auto-promoção" — para ter o primeiro `Admin` do sistema,
atualize a coluna `perfil` de um usuário diretamente no banco (`UPDATE usuario SET
perfil = 'Admin' WHERE id = <id>;`); a partir daí, esse Admin pode promover os demais
via `PUT /api/auth/usuarios/{id}/perfil`.

### Padronização de respostas — ResultWrapper

Todas as respostas seguem o formato definido em [`Common/Result.cs`](Common/Result.cs):

```json
{
  "success": true,
  "message": "Ambiente criado com sucesso.",
  "data": { "id": 1, "identificacao": "Sala 101" },
  "errors": []
}
```

Em caso de erro:

```json
{
  "success": false,
  "message": "Ambiente não encontrado.",
  "data": null,
  "errors": []
}
```

## Configuração do banco de dados

O projeto usa MySQL via Pomelo EF Core. A connection string fica em
`appsettings.Development.json` (não versionado com valores reais em produção):

```json
"ConnectionStrings": {
  "DefaultConnection": "Server=localhost;Database=aura_db;User=root;Password=;"
}
```

Ajuste `Server`, `User` e `Password` para o seu ambiente local. Em seguida, aplique a
migration `InitialCreate` já versionada em [`Migrations/`](Migrations/):

```bash
dotnet ef database update
```

## Autenticação JWT

- `POST /api/auth/register` cria um usuário (senha armazenada com hash via BCrypt, nunca
  em texto puro) e já retorna um token.
- `POST /api/auth/login` valida e-mail/senha e retorna um token.
- O token deve ser enviado no header `Authorization: Bearer <token>` em todos os endpoints
  marcados com `[Authorize]`.
- Configuração (`Jwt:SecretKey`, `Jwt:Issuer`, `Jwt:Audience`) fica em
  `appsettings.Development.json` em desenvolvimento; em produção deve vir de variável de
  ambiente ou user-secrets — a API falha ao iniciar se a chave não estiver configurada.
- Token expira em 8 horas e carrega as claims `sub` (id), `name`, `email` e `role`
  (perfil do usuário).

## Estratégia de cache

`AmbienteService` (`Application/Services/AmbienteService.cs`) usa `IMemoryCache` na
listagem de ambientes (`GET /api/ambientes`):

- Na primeira consulta, os dados são buscados no banco e armazenados em cache por
  **5 minutos** (expiração absoluta).
- Consultas seguintes dentro desse período são servidas direto do cache, sem acessar o
  banco.
- O cache é invalidado (removido) sempre que um ambiente é criado, atualizado ou
  removido, garantindo que a próxima leitura busque dados atualizados na fonte original.

## Como executar a API

Pré-requisitos: .NET 9 SDK e um servidor MySQL acessível.

```bash
git clone https://github.com/FontesSabrina/ApiAuria.git
cd ApiAuria
dotnet restore
dotnet ef database update
dotnet run
```

A API sobe em `http://localhost:5131` (perfil `http` em
`Properties/launchSettings.json`). O Swagger fica disponível em
`http://localhost:5131/swagger`, com suporte ao botão **Authorize** para colar o token
JWT (`Bearer <token>`).

## Como executar o aplicativo Flutter

O app fica em [`../flutter_aura_2026`](../flutter_aura_2026) (README próprio lá). Resumo:

```bash
cd ../flutter_aura_2026
flutter pub get
flutter run -d windows   # ou -d chrome, se não tiver o Visual Studio instalado
```

A `baseUrl` usada pelo app fica em `lib/core/network/api_config.dart` — por padrão
`http://localhost:5131/api`, pensada para rodar como Windows Desktop na mesma máquina
que a API. Ajuste esse arquivo se for rodar num emulador Android ou dispositivo físico.

## Principais endpoints

| Método | Rota | Autenticação | Descrição |
|---|---|---|---|
| POST | `/api/auth/register` | Não | Cadastra um usuário (perfil `Solicitante`) e retorna token + id |
| POST | `/api/auth/login` | Não | Autentica e retorna token JWT + id |
| GET | `/api/auth/usuarios` | Sim | Lista usuários (id, nome, email, perfil — sem senha) |
| PUT | `/api/auth/usuarios/{id}/perfil` | Admin | Altera o perfil de um usuário (`Solicitante`/`Tecnico`/`Admin`) |
| GET | `/api/ambientes` | Sim | Lista ambientes (cacheado por 5 min) |
| GET | `/api/ambientes/{id}` | Sim | Consulta um ambiente |
| POST | `/api/ambientes` | Sim | Cria um ambiente |
| PUT | `/api/ambientes/{id}` | Sim | Atualiza um ambiente |
| DELETE | `/api/ambientes/{id}` | Sim | Remove um ambiente |
| GET | `/api/ativos` | Sim | Lista ativos |
| GET | `/api/ativos/{id}` | Sim | Consulta um ativo |
| POST | `/api/ativos` | Sim | Cria um ativo (valida se o `AmbienteId` existe) |
| PUT | `/api/ativos/{id}` | Sim | Atualiza um ativo |
| DELETE | `/api/ativos/{id}` | Sim | Remove um ativo |
| GET | `/api/chamados` | Sim | Lista chamados com detalhes (solicitante, técnico responsável, ativo, ambiente) |
| GET | `/api/chamados/{id}` | Sim | Consulta um chamado |
| POST | `/api/chamados` | Sim | Abre um chamado (solicitante = usuário autenticado) |
| PUT | `/api/chamados/{id}/cancelar` | Sim | Cancela um chamado |
| GET | `/api/itensestoque` | Sim | Lista itens de estoque |
| POST | `/api/itensestoque` | Sim | Cria um item de estoque |
| PUT | `/api/itensestoque/{id}` | Sim | Atualiza um item de estoque |
| DELETE | `/api/itensestoque/{id}` | Sim | Remove um item de estoque |
| GET | `/api/notificacoes` | Sim | Lista notificações |
| POST | `/api/notificacoes` | Sim | Cria uma notificação |
| PUT | `/api/notificacoes/{id}/lida` | Sim | Marca notificação como lida |
| DELETE | `/api/notificacoes/{id}` | Sim | Remove uma notificação |
| GET | `/api/ordemservico` | Sim | Lista ordens de serviço |
| POST | `/api/ordemservico` | Tecnico, Admin | Abre uma ordem de serviço para um chamado (opcionalmente debitando itens de estoque), muda status para "Em Execucao" |
| PUT | `/api/ordemservico/{id}/concluir` | Tecnico, Admin | Conclui a ordem de serviço e fecha o chamado (corpo opcional: `tempoGastoMinutos`, `parecerTecnico`, `custoMaoObra`, para preencher esses dados só na conclusão) |

## Exemplo de requisição e resposta

**Requisição** — `POST /api/auth/login`

```json
{
  "email": "usuario@exemplo.com",
  "senha": "minhasenha123"
}
```

**Resposta — sucesso (200)**

```json
{
  "success": true,
  "message": "Login realizado com sucesso.",
  "data": {
    "id": 1,
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "nome": "Maria Silva",
    "email": "usuario@exemplo.com",
    "role": "Solicitante"
  },
  "errors": []
}
```

**Resposta — falha (401)**

```json
{
  "success": false,
  "message": "Credenciais inválidas.",
  "data": null,
  "errors": []
}
```

## Consumo de itens de estoque

Ao abrir uma ordem de serviço (`POST /api/ordemservico`), é possível informar quais itens
de estoque foram usados no campo opcional `itensUtilizados`:

```json
{
  "chamadoId": 1,
  "tecnicoId": 2,
  "tempoGastoMinutos": 45,
  "parecerTecnico": "Troca de lâmpada",
  "custoMaoObra": 50.00,
  "itensUtilizados": [
    { "itemEstoqueId": 3, "quantidadeUtilizada": 2 }
  ]
}
```

Cada item é validado antes de qualquer gravação: precisa existir, a quantidade deve ser
maior que zero, não pode haver `itemEstoqueId` duplicado na lista, e o estoque disponível
precisa ser suficiente — caso contrário a API responde `400` sem criar a ordem de serviço
nem debitar nada. Se a validação passa, o estoque (`ItemEstoque.QuantidadeEstoque`) é
debitado e um registro é criado em `OrdemServicoItemEstoque` para cada item, na mesma
operação de criação da ordem de serviço.

## Integração com o app Flutter

O app em [`../flutter_aura_2026`](../flutter_aura_2026) foi migrado de armazenamento
local (sqflite/memória) para consumir esta API via `http` + JWT. Duas divergências de
modelagem entre o app e a API foram resolvidas do lado do Flutter (ver README de lá):
`Ativo` passou a referenciar um `Ambiente` por id (antes era texto livre), e o
formulário de Ordem de Serviço soma "custo de peças" + "custo de mão de obra" num único
valor antes de enviar (a API guarda só `CustoMaoObra`). Duas telas do app (excluir
usuário e editar nome/e-mail de um usuário já existente) não têm endpoint correspondente
aqui de propósito — a API não expõe esse tipo de gestão administrativa ampla.

## Próximos passos / limitações conhecidas

- `TecnicoNome` na resposta de um chamado é derivado da sua ordem de serviço mais recente
  (a que ainda está em andamento tem prioridade); um chamado sem ordem de serviço aberta
  retorna `TecnicoNome: null`.
- A validação e o débito de estoque não usam uma transação/lock explícitos — em uso normal
  (poucas requisições concorrentes, como no escopo deste trabalho) não é um problema, mas
  duas ordens de serviço criadas ao mesmo tempo para o mesmo item, na mesma fração de
  segundo, poderiam ambas passar na validação antes de qualquer uma debitar o estoque.
