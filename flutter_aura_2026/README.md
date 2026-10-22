# Aura - Sistema de Gestão de Manutenção Predial e Ativos 🏢🛠️

O **Aura** é uma plataforma integrada desenvolvida para centralizar, automatizar e otimizar todas as operações de manutenção e controle patrimonial de uma organização. O sistema visa substituir controlos manuais por um fluxo eficiente que vai desde a abertura de chamados cotidianos até ao planejamento preventivo avançado da infraestrutura, garantindo alta disponibilidade dos ativos e controle rigoroso de custos, em conformidade com os requisitos da **ABNT NBR 5674** (Manutenção de edificações).

---

## 🚀 Escopo do Produto & Funcionalidades

### 📱 Portal de Chamados e Execução (Web/Mobile)
* **Abertura Simplificada:** Criação de chamados detalhando o problema, prioridade, tipo de manutenção (corretiva, preventiva ou preditiva) e localização exata.
* **Acompanhamento Real-Time:** Interface intuitiva para monitorar a evolução do status do chamado desde o recebimento até à conclusão.
* **Registro Técnico:** Os técnicos de campo podem registrar o tempo gasto, atividades executadas e insumos aplicados nas Ordens de Serviço (OS).
* **Mobilidade:** Consulta móvel da localização detalhada do ativo e do seu histórico prévio de intervenções.

### 💻 Painel Administrativo de Gestão Estratégica
* **Árvore de Ativos e Ambientes:** Cadastro estruturado de ativos físicos, responsáveis e mapeamento predial hierárquico (prédios, andares e salas).
* **Planos Preventivos:** Configuração de planos de manutenção preventiva automáticos baseados em tempo ou uso.
* **Almoxarifado & Estoque Integrado:** Controle de inventário de peças com baixa automatizada nas ordens de serviço, cálculo dinâmico de custos e alertas automáticos de nível mínimo de segurança.
* **Business Intelligence (BI):** Painel de indicadores com métricas críticas como Tempo Médio de Reparo (MTTR), taxa de falhas, custos por ativo e disponibilidade geral da infraestrutura.

---

## 🛠️ Especificações Técnicas

* **Framework Principal:** [Flutter](https://flutter.dev/) (Alvo principal: Desktop - Windows)
* **Linguagem de Programação:** [Dart](https://dart.dev/)
* **Arquitetura:** Princípios de *Clean Code*, padrões consolidados e arquitetura modularizada (Clean Architecture).
* **Injeção de Dependências:** [GetIt](https://pub.dev/packages/get_it) (Service Locator)
* **Persistência:** via [AuriaAPI](../AuriaAPI) (backend ASP.NET Core + MySQL) — o app não guarda mais os dados localmente, ver seção de integração abaixo.
* **http:** Cliente HTTP para consumir a AuriaAPI.
* **shared_preferences:** Persistência local do token JWT da sessão.

## 🔌 Integração com a AuriaAPI

Este app **não usa mais armazenamento local** para as entidades principais
(ambientes, ativos, chamados, ordens de serviço, estoque, notificações,
usuários) — tudo passa pela [AuriaAPI](../AuriaAPI), autenticado via JWT.

* Endereço da API: [`lib/core/network/api_config.dart`](lib/core/network/api_config.dart)
  (`http://localhost:5131/api` por padrão, pensado para rodar como Windows
  Desktop na mesma máquina da API; o próprio arquivo comenta como trocar para
  emulador Android ou dispositivo físico).
* O token JWT fica em [`lib/core/network/auth_session.dart`](lib/core/network/auth_session.dart)
  e é anexado automaticamente pelo [`ApiClient`](lib/core/network/api_client.dart)
  em toda requisição autenticada.
* O `ApiClient` desembrulha o ResultWrapper da API (`success`, `message`, `data`, `errors`):
  em caso de erro, a mensagem enviada pela API (ex.: "Este ambiente possui ativos vinculados")
  é mostrada ao usuário num SnackBar.
* Se o token expirar ou for inválido (HTTP 401), a sessão é encerrada e o app volta
  sozinho para a tela de login, mostrando o aviso.
* **Toda regra de negócio fica na API**: baixa de estoque (consumo de peças na OS),
  mudanças de status do chamado, notificações automáticas, indicadores do painel de BI
  e alertas de manutenção preventiva são calculados no servidor.
* **A AuriaAPI precisa estar rodando** (`dotnet run` na pasta `AuriaAPI`,
  com o MySQL configurado) antes de abrir este app — sem ela, login e
  qualquer tela de dados vão falhar com uma mensagem de erro de conexão.
* Primeiro acesso: entre com o administrador inicial criado pela API
  (seção `AdminInicial` da configuração — veja o README da raiz do repositório).

---

## 📅 Plano de Liberações (Cronograma 2026)

O desenvolvimento do Aura está estruturado em quatro iterações bem definidas:

* **Iteração 1: Configuração Inicial e Inventário (01/03 a 15/03):** Modelação da base de dados relacional, estrutura de árvores de ambientes, cadastro centralizado de dados patrimoniais (garantias, vida útil e estado de conservação) e vínculo de equipes responsáveis.
* **Iteração 2: Núcleo Operacional — Chamados e OS (16/03 a 30/03):** Desenvolvimento do portal de solicitações de problemas, painel técnico de execução de OS com cronometragem e mecanismo de log imutável de histórico.
* **Iteração 3: Automatização Preventiva e Estoque (01/04 a 15/04):** Implementação do motor de regras para planos preventivos, módulo de almoxarifado por fornecedores e lógica de baixa automatizada de insumos com cálculo dinâmico de custos.
* **Iteração 4: Indicadores Gerenciais, Notificações e Implantação (16/04 a 30/04):** Construção de dashboards analíticos (MTTR, disponibilidade), motor de notificações automáticas (push/e-mail), rotinas de QA (testes de estresse e integração) e deploy final em produção.

---

## 📁 Estrutura de Pastas

```text
lib/
 ├── core/          # Temas, utilitários globais, rotas, acessibilidade e a camada de rede (core/network)
 ├── data/          # Datasources remotos (HTTP) e implementações dos repositórios
 ├── domain/        # Entidades puras de negócio, contratos/interfaces e regras de uso
 ├── core/ui/       # Design system do app: cores (claro/escuro), tema, botões, cards, painéis laterais
 ├── pages/
 │   ├── login_page.dart
 │   ├── shell/     # AuriaShell (menu lateral + cabeçalho, por perfil) e AppDados (estado compartilhado)
 │   └── views/     # Telas: painéis do Admin/Técnico/Solicitante, chamados (kanban), ordens,
 │                  # preventivas, estoque, ativos, ambientes, usuários, indicadores, notificações
 └── main.dart      # Inicialização do Service Locator (GetIt) e do App
```

## 🏁 Como Executar o Projeto Localmente

1. Clone o repositório:
   ```bash
   git clone https://github.com/FontesSabrina/ApiAuria.git
   cd ApiAuria/flutter_aura_2026
   ```
2. Obtenha as dependências:
   ```bash
   flutter pub get
   ```
3. Garanta que a [AuriaAPI](../AuriaAPI) está rodando (`dotnet run` na pasta `AuriaAPI`) e
   acessível no endereço configurado em `lib/core/network/api_config.dart`.
4. Rode o app:
   ```bash
   flutter config --enable-windows-desktop
   flutter run -d windows   # Windows Desktop (exige Visual Studio com "Desktop development with C++")
   flutter run -d chrome    # Web, alternativa que não exige Visual Studio
   ```

## 📋 Pré-requisitos

* [Flutter SDK](https://flutter.dev/docs/get-started/install) instalado.
* A [AuriaAPI](../AuriaAPI) rodando localmente (ver README dela).
* Um editor de código (como VS Code ou Android Studio).
* Para build nativo Windows: Visual Studio com o workload "Desktop
  development with C++", e o Modo de Desenvolvedor do Windows habilitado
  (Configurações → Privacidade e segurança → Para desenvolvedores).

## 🧑‍💻 Autores (IFSUDESTEMG - Campus Muriaé)

Trabalho desenvolvido para o curso de Gestão da Tecnologia da Informação:

* Alexandre do Amaral Quintão — Desenvolvedor do Projeto
* Sabrina Caetano Fontes — Desenvolvedora do Projeto

Developed as part of the GTI Academic Projects ecosystem. 🚀
