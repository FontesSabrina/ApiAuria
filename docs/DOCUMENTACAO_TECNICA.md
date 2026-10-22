# Documentação técnica — decisões de arquitetura da AuriaAPI

Este documento explica **por que** a API foi organizada como está. O passo a passo de uso fica no
[README](../README.md).

## 1. Camadas e regra de dependência

A API segue a Clean Architecture dentro de um único projeto .NET, com uma pasta por camada. A
especificação aceita nomes diferentes desde que as responsabilidades fiquem claras.

| Camada | Pasta | Responsabilidade | Depende de |
|---|---|---|---|
| Domain | `Domain/` | Entidades, regras de negócio, constantes e **interfaces** de repositório | nada |
| Application | `Application/` | Casos de uso (services), DTOs, validação de entrada, ResultWrapper, interfaces de serviços técnicos | Domain |
| Infrastructure | `Infra/` | EF Core/MySQL, repositórios, cache, JWT, BCrypt, seed do admin | Domain, Application (interfaces) |
| API/Presentation | `Api/` | Controllers, middleware de erros, configuração de JWT/Swagger/CORS | Application |

O `Program.cs` é o único ponto que conhece todas as camadas: ele liga cada interface à sua
implementação, por injeção de dependência.

**Por que um projeto só, e não quatro?** A especificação permite pastas. Com um projeto só, a
execução fica mais simples (`dotnet run`, uma migration). Em contrapartida, o compilador não impede
que uma camada referencie outra indevidamente; a regra de dependência é mantida por disciplina e pode
ser conferida pelos `using` de cada arquivo. Uma evolução natural é separar em `Auria.Domain`,
`Auria.Application`, `Auria.Infrastructure` e `Auria.Api`, como no tutorial da disciplina.

## 2. Onde fica cada regra de negócio

**Regras que dependem só da própria entidade ficam nela (Domain).** Exemplos:

- `Chamado.Cancelar()`: só cancela chamados "Aberto".
- `Chamado.IniciarExecucao()` e `Chamado.Concluir()`.
- `OrdemServico.Concluir()`: não conclui duas vezes.
- `OrdemServico.RegistrarConsumo()`: soma a peça se ela já foi usada na mesma OS.
- `ItemEstoque.Debitar()`: não deixa o estoque ficar negativo.
- `Ativo.MotivosAlertaPreventiva()`.

A violação lança `RegraDeNegocioException`, convertida em **400**.

**Regras que dependem de outros dados ou de quem está logado ficam nos services (Application).** Exemplos:

- E-mail único.
- Só o técnico designado conclui a OS.
- O solicitante só vê os próprios chamados.
- Não excluir ambiente com ativos, ativo com chamados, item já consumido ou usuário com histórico. Sem essas verificações, as FKs em cascata da migration apagariam dados em silêncio.
- O admin não remove o próprio perfil de administrador.

**Os controllers não têm regra.** Eles só recebem a requisição, pegam o usuário do token, chamam o
service e devolvem o resultado.

**O app Flutter não tem regra de negócio de dados.** A baixa de estoque, as notificações, os
indicadores e os alertas de preventiva, que antes eram feitos no app, passaram para a API. O app só
faz validações de tela, para dar retorno rápido ao usuário.

## 3. Repositórios e Unit of Work

- Cada agregado tem uma interface no Domain (`IChamadoRepository`, `IOrdemServicoRepository`...) e uma implementação EF Core em `Infra/EF/Repositories`.
- Os métodos comuns (`ObterPorId`, `Adicionar`, `Remover`...) ficam em `IRepository<T>` / `RepositoryEF<T>`, para não repetir código.
- As consultas com `Include` ficam no repositório, então o service não conhece o EF Core.
- **`IUnitOfWork.SalvarAlteracoesAsync()`** grava tudo de uma vez. Por exemplo, abrir uma OS altera o chamado, cria a OS, debita o estoque e cria notificações. Como todos os repositórios compartilham o mesmo `DbContext` (*scoped*), um único `SaveChanges` grava tudo numa transação: ou tudo é salvo, ou nada.

## 4. Tratamento de erros e ResultWrapper

- **Sucesso:** o controller devolve `Result<T>.SuccessResult(...)`.
- **Erro esperado:** o service lança uma exceção com significado. O `ExceptionHandlingMiddleware` a traduz:

| Exceção | HTTP |
|---|---|
| `RegraDeNegocioException` | 400 |
| `CredenciaisInvalidasException` | 401 |
| `AcessoNegadoException` | 403 |
| `RecursoNaoEncontradoException` | 404 |
| `ConflitoException` | 409 |
| `DbUpdateException` | 409 |
| qualquer outra | 500, com o erro registrado no log e uma mensagem genérica para o cliente |

- **Validação dos DTOs** (Data Annotations): o `InvalidModelStateResponseFactory` devolve **400** com a lista de erros em `errors`.
- **401/403 do JWT:** os eventos `OnChallenge`/`OnForbidden` escrevem o ResultWrapper. Sem isso, essas respostas sairiam com o corpo vazio.

Resultado: **nenhuma resposta sai fora do padrão**, e os controllers não têm `try/catch` nem `if (x == null) return NotFound(...)` repetidos.

## 5. Autenticação e autorização (JWT)

- **Por que JWT?** A API é *stateless*: o servidor não guarda sessão, e o próprio token, assinado, carrega quem é o usuário (`sub`) e o perfil (`role`).
- **Assinatura:** HMAC-SHA256 com chave simétrica de pelo menos 32 caracteres (256 bits), que vem da configuração e nunca do código. A API não inicia sem ela.
- **Validações:** emissor, público, assinatura e expiração, com `ClockSkew = 0`, para o token expirar exatamente na hora marcada.
- **Ciclo de vida:**
  1. O login gera o token, válido por 8h.
  2. O app guarda o token e o envia em cada requisição.
  3. A cada requisição, o middleware valida o token.
  4. Quando o token expira, a API responde 401 e o app volta para a tela de login.
  - Não há refresh token (está listado como melhoria futura).
- **Autorização em dois níveis:**
  1. Por perfil, com `[Authorize(Roles = ...)]` no controller.
  2. Por dono do recurso, nos services (técnico designado, dono do chamado, dono da notificação).
- **Senhas:** BCrypt, que gera um *salt* aleatório por senha e é propositalmente lento, para dificultar ataques de força bruta. A comparação é feita com `BCrypt.Verify`.
- **Primeiro admin:** o cadastro público sempre cria `Solicitante`, para ninguém se autopromover. O primeiro `Admin` é criado pelo `AdminSeeder` a partir da configuração.

## 6. Cache

- **Tecnologia:** `IMemoryCache` (memória do próprio processo). Basta para uma instância única da API e não exige infraestrutura extra. Se a API rodasse em várias instâncias, o cache precisaria ser distribuído (Redis), porque cada instância teria o seu.
- **Estratégia cache-aside com expiração absoluta e invalidação explícita** (`Infra/Cache/MemoryCacheService.cs`):
  1. O service pede o dado ao cache.
  2. Se não estiver lá (**MISS**), busca no banco e guarda (**ARMAZENADO**).
  3. Nas próximas leituras, devolve do cache (**HIT**).
  4. Quando o dado muda, o service remove a chave (**INVALIDADO**).
  - Cada passo aparece no log do console.
- **O que é cacheado e por quê:**
  - Lista de ambientes, por 5 minutos: muda pouco e é lida em várias telas.
  - Indicadores do BI, por 2 minutos: o cálculo é caro, porque percorre todas as ordens e chamados.
  - A expiração é uma "rede de segurança": mesmo que alguma alteração escape da invalidação, o dado se corrige sozinho.
- **O que não é cacheado:** dados que mudam o tempo todo e precisam estar exatos, como o saldo de estoque e o status de chamados e OS.
- **Abstração:** os services dependem de `ICacheService` (Application), não do `IMemoryCache`. Trocar para Redis exigiria só uma nova implementação na Infra.

## 7. Configurações sensíveis

- O `appsettings.json` versionado tem os campos sensíveis vazios.
- Os valores reais vêm de **user-secrets** (desenvolvimento), de `appsettings.Development.json` (fora do Git, pelo `.gitignore`) ou de **variáveis de ambiente** (produção).
- O arquivo `appsettings.Development.example.json` mostra quais chaves preencher.

## 8. Integração com o Flutter

- **`ApiClient`:**
  - Anexa o token.
  - Desembrulha o ResultWrapper e devolve só o `data`.
  - Transforma qualquer falha em `ApiException` com a mensagem da API, que as telas mostram num SnackBar.
  - Num 401 em rota protegida, chama `AuthSession.encerrarPorExpiracao`, e o app volta ao login.
- **Repositórios do app:** só falam com a API, sem banco local. As interfaces do domínio do app espelham os endpoints (`buscarMeusChamados`, `registrarConsumo`, `concluir`...).
- **Datas:** as datas geradas pelo servidor são gravadas em UTC e convertidas para o horário local no app (`api_parsers.dart`).

## 9. Limitações conhecidas

- O app não tem os campos "unidade de medida" e "fornecedor" do estoque na API, porque não existem no banco. O app envia o nome do item como código interno.
- O custo das peças é calculado com o custo unitário **atual** do item. Se o preço mudar, OS antigas são recalculadas. Para congelar o valor, seria preciso gravar o custo unitário na tabela `ordem_servico_item_estoque` (nova migration).
- O cronograma de preventivas compara datas pelo fuso horário do servidor da API.
- A aba "Movimentações" da tela de estoque no app é apenas ilustrativa: a API ainda não registra um histórico de entradas e saídas.
