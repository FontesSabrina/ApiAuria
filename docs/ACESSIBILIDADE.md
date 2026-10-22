# Acessibilidade no app Auria

O objetivo é que qualquer pessoa consiga **abrir um chamado, acompanhar uma ordem de serviço ou
administrar o sistema**, inclusive quem:

- usa leitor de tela;
- tem baixa visão ou daltonismo;
- tem dislexia;
- navega só pelo teclado;
- sente desconforto com movimento na tela.

A referência é a **WCAG 2.2, nível AA**, a diretriz internacional de acessibilidade para web e apps.
No Brasil, ela é a base da Lei Brasileira de Inclusão (Lei 13.146/2015, art. 63) e do eMAG.

## 1. Painel de acessibilidade

Fica no botão com ícone de pessoa, no cabeçalho de todas as telas e no login
(`lib/core/acessibilidade/painel_acessibilidade.dart`). As escolhas são salvas no aparelho com
`shared_preferences` (`AcessibilidadeController`) e valem na hora, sem reiniciar o app.

| Opção | O que faz | Para quem ajuda |
|---|---|---|
| Tamanho do texto | Normal (1×), Grande (1,15×), Maior (1,3×) e Máximo (1,5×). Multiplica o tamanho já escolhido no sistema, até 2× no total. | Baixa visão, idosos |
| Alto contraste | Paletas `altoContrasteClaro` e `altoContrasteEscuro`: texto preto ou branco, bordas escuras e mais grossas, e cores de status mais fortes. | Baixa visão, ambientes muito claros |
| Fonte de leitura facilitada | Troca a fonte pela **Atkinson Hyperlegible**, criada pelo Braille Institute para diferenciar letras parecidas (I, l, 1, O, 0). | Baixa visão, dislexia |
| Tema escuro | Fundo escuro. | Sensibilidade à luz |
| Reduzir animações | Zera as transições de tela, de painel e de tema, e o efeito de "subir" dos cards. | Distúrbios vestibulares (tontura), TDAH |

## 2. Configurações do sistema que o app respeita

- **Tamanho da fonte do sistema:** o `textScaler` do sistema é multiplicado pela escolha do app.
- **Texto em negrito** (iOS e Android): o Flutter aplica sozinho.
- **Alto contraste do sistema:** `highContrastTheme` e `highContrastDarkTheme` no `MaterialApp`.
- **Remover animações** (`MediaQuery.disableAnimations`): tem o mesmo efeito da opção do app.

## 3. Leitor de tela (TalkBack, VoiceOver, NVDA, JAWS)

| O que foi feito | Onde |
|---|---|
| Na web, a árvore de acessibilidade do Flutter é ligada desde o início (`SemanticsBinding.ensureSemantics`). Sem isso, o NVDA só "enxerga" o app depois de um clique num botão escondido. | `main.dart` |
| A página web está declarada em português (`<html lang="pt-BR">`), então o leitor usa a voz certa. | `web/index.html` |
| Botões só com ícone têm nome (ex.: "Notificações, 3 não lidas", "Abrir menu", "Mostrar senha"). | `BotaoIcone`, `IconButton` com `tooltip` |
| Campos de formulário são lidos junto com o rótulo visível ("E-mail, campo de texto"). | `CampoFormulario`, login |
| Títulos de página, de card e de seção são marcados como **cabeçalho**, para a navegação por títulos. | cabeçalho do shell, `AuriaCard`, `RotuloSecao`, `TituloPainel` |
| Itens do menu informam se são a página atual e quantas pendências têm. | `_BotaoMenu` |
| A troca de página é anunciada ("Página Estoque"). | `AuriaShell._irPara` |
| Avisos de sucesso e de erro são anunciados na hora (*live region*), com o prefixo "Erro:". | `snackAuria`, erro do login |
| Painéis laterais funcionam como diálogos: o leitor fica dentro do painel até ele ser fechado. | `mostrarPainelLateral` |
| Seleções em cartões (equipamento e prioridade no "Abrir chamado") informam o estado "selecionado". | `abrir_chamado_view.dart` |
| Gráficos e barras têm a descrição dos dados em texto (ex.: "Ordens por ativo: Bebedouro, 3 ordens; ..."). | `BarraStatus`, `RankingBarras`, gráfico e custos dos Indicadores |
| Os indicadores de carregamento têm nome ("Carregando dados", "Entrando", "Salvando"). | várias telas |
| Elementos decorativos (avatar de iniciais, ícones ao lado de texto) ficam ocultos para o leitor. | `AvatarIniciais` |
| O logo é lido como "Logo Auria". | `auria_logo.dart` |

## 4. Teclado

- **Tab** e **Shift+Tab** percorrem todos os botões, cards, campos e itens do menu.
- **Enter** ou **Espaço** ativam o elemento em foco.
- **Esc** fecha painéis e diálogos.
- O foco aparece com um **contorno de 2,5 px**: azul no tema normal, preto ou branco no alto contraste, e âmbar no menu. Isso vale para os cards clicáveis (`HoverCard`), botões de ícone, itens do menu e campos (WCAG 2.4.7 e 2.4.11).
- No login, Enter no campo de senha já envia o formulário.

## 5. Visão e cor

- **Contraste de texto** (calculado pela fórmula da WCAG):

  | Paleta | Texto normal | Texto secundário | Etiquetas de status |
  |---|---|---|---|
  | Clara | 15,7:1 | 5,6:1 | ≥ 4,5:1 |
  | Escura | 16,2:1 | 8,5:1 | ≥ 7,0:1 |
  | Alto contraste clara | 21:1 | 12,6:1 | ≥ 7,4:1 |
  | Alto contraste escura | 21:1 | 16,7:1 | ≥ 9,6:1 |

- **Cor nunca é a única informação** (WCAG 1.4.1):
  - status e prioridade sempre têm texto ("Em execução", "Alta");
  - o nível de estoque tem texto ("Repor já", "Atenção", "Ok");
  - o item escolhido tem, além da cor, um ícone de check e uma borda mais grossa.
- **Texto ampliado sem quebrar a tela** (WCAG 1.4.4): os layouts usam `Wrap` e larguras flexíveis, e o item do menu e a busca não têm altura fixa.

## 6. Toque e movimento

- **Áreas de toque:** pelo menos 44 × 44 px nos botões de ícone e itens do menu, e `MaterialTapTargetSize.padded` no tema (48 px no celular). Isso atende a WCAG 2.5.8.
- **Movimento:** nenhuma animação dura mais que 220 ms, e todas podem ser desligadas (WCAG 2.3.3).

## 7. Como testar

1. **Leitor de tela no Windows:** instale o **NVDA** (gratuito), rode `flutter run -d chrome`, entre no login e navegue com Tab e com a tecla **H** (pula de título em título).
2. **Celular:** no Android, ative o **TalkBack**; no iPhone, o **VoiceOver**. Depois deslize o dedo para ir de item em item.
3. **Teclado:** deixe o mouse de lado e faça o fluxo "abrir chamado" só com Tab, Enter e Esc.
4. **Tamanho do texto:** no painel de Acessibilidade, escolha **Máximo** e percorra as telas.
5. **Alto contraste e fonte:** ligue as duas opções juntas e compare com o tema normal.
6. **Ferramenta automática:** no Chrome, abra o DevTools, vá em **Lighthouse** e rode a auditoria de **Accessibility**.

## 8. Limitações conhecidas

- A legenda do gráfico do fl_chart (nomes embaixo das barras) não aumenta além do espaço reservado. O texto completo continua disponível para o leitor de tela e na tabela do PDF.
- O PDF exportado em Indicadores ainda não é um PDF "marcado" (*tagged PDF*), porque o pacote `pdf` não gera essa estrutura.
