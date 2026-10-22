import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:get_it/get_it.dart';

import '../../core/acessibilidade/painel_acessibilidade.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/ui/app_theme.dart';
import '../../core/ui/auria_colors.dart';
import '../../core/ui/auria_logo.dart';
import '../../core/ui/widgets.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/usuario_repository.dart';
import '../../routes.dart';
import '../views/abrir_chamado_view.dart';
import '../views/ambientes_view.dart';
import '../views/ativos_view.dart';
import '../views/chamados_kanban_view.dart';
import '../views/estoque_view.dart';
import '../views/indicadores_view.dart';
import '../views/meus_chamados_view.dart';
import '../views/notificacoes_view.dart';
import '../views/ordens_view.dart';
import '../views/painel_admin_view.dart';
import '../views/painel_solicitante_view.dart';
import '../views/painel_tecnico_view.dart';
import '../views/preventivas_view.dart';
import '../views/usuarios_view.dart';
import 'app_dados.dart';

/// Seções do app. Cada perfil vê só as que fazem sentido para ele (ver [_itensDoMenu]).
enum Secao { painel, chamados, ordens, preventivas, estoque, ativos, ambientes, usuarios, indicadores, notificacoes, meusChamados, abrirChamado }

/// Estrutura de todas as telas depois do login: menu lateral escuro + cabeçalho
/// (título, busca, tema, notificações) + conteúdo. Em telas estreitas o menu vira gaveta.
class AuriaShell extends StatefulWidget {
  final Usuario usuario;
  const AuriaShell({super.key, required this.usuario});

  @override
  State<AuriaShell> createState() => _AuriaShellState();
}

class _AuriaShellState extends State<AuriaShell> {
  late final AppDados _dados = AppDados(widget.usuario);
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _buscaController = TextEditingController();
  Secao _secao = Secao.painel;

  static const _larguraMinimaMenuFixo = 900.0;

  @override
  void initState() {
    super.initState();
    _dados.carregar();
  }

  @override
  void dispose() {
    _dados.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  void _irPara(Secao secao) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) Navigator.pop(context);
    _buscaController.clear();
    _dados.definirBusca('');
    setState(() => _secao = secao);
    // Avisa o leitor de tela que a página mudou (o foco continua no menu).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SemanticsService.sendAnnouncement(View.of(context), 'Página ${_titulo().$1}', TextDirection.ltr);
    });
  }

  Future<void> _sair() async {
    await GetIt.I<UsuarioRepository>().logout();
    if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  List<_ItemMenu> _itensDoMenu() {
    final d = _dados;
    if (d.ehAdmin) {
      return [
        const _ItemMenu.rotulo('Operação'),
        const _ItemMenu(Secao.painel, Icons.space_dashboard_outlined, 'Painel'),
        _ItemMenu(Secao.chamados, Icons.confirmation_number_outlined, 'Chamados', contador: d.abertos),
        _ItemMenu(Secao.ordens, Icons.handyman_outlined, 'Ordens de serviço', contador: d.ordensEmAndamento.length),
        const _ItemMenu(Secao.preventivas, Icons.event_repeat_outlined, 'Preventivas'),
        const _ItemMenu.rotulo('Cadastros'),
        _ItemMenu(Secao.estoque, Icons.inventory_2_outlined, 'Estoque', contador: d.criticos.length, alerta: true),
        const _ItemMenu(Secao.ativos, Icons.devices_other_outlined, 'Ativos'),
        const _ItemMenu(Secao.ambientes, Icons.apartment_outlined, 'Ambientes'),
        const _ItemMenu(Secao.usuarios, Icons.group_outlined, 'Usuários'),
        const _ItemMenu.rotulo('Análise'),
        const _ItemMenu(Secao.indicadores, Icons.insights_outlined, 'Indicadores'),
        _ItemMenu(Secao.notificacoes, Icons.notifications_none_rounded, 'Notificações', contador: d.naoLidas, alerta: true),
      ];
    }
    if (d.ehTecnico) {
      return [
        const _ItemMenu.rotulo('Meu trabalho'),
        const _ItemMenu(Secao.painel, Icons.space_dashboard_outlined, 'Meu dia'),
        _ItemMenu(Secao.ordens, Icons.handyman_outlined, 'Minhas ordens', contador: d.ordensEmAndamento.length),
        const _ItemMenu(Secao.chamados, Icons.confirmation_number_outlined, 'Chamados'),
        const _ItemMenu.rotulo('Consulta'),
        _ItemMenu(Secao.estoque, Icons.inventory_2_outlined, 'Estoque', contador: d.criticos.length, alerta: true),
        _ItemMenu(Secao.notificacoes, Icons.notifications_none_rounded, 'Notificações', contador: d.naoLidas, alerta: true),
      ];
    }
    return [
      const _ItemMenu.rotulo('Manutenção'),
      const _ItemMenu(Secao.painel, Icons.home_outlined, 'Início'),
      const _ItemMenu(Secao.abrirChamado, Icons.add_circle_outline_rounded, 'Abrir chamado'),
      _ItemMenu(Secao.meusChamados, Icons.list_alt_rounded, 'Meus chamados', contador: d.chamados.where((c) => c.status.index < 2).length),
      _ItemMenu(Secao.notificacoes, Icons.notifications_none_rounded, 'Notificações', contador: d.naoLidas, alerta: true),
    ];
  }

  (String, String) _titulo() {
    final d = _dados;
    return switch (_secao) {
      Secao.painel => d.ehAdmin
          ? ('Painel', 'Visão geral da manutenção predial hoje')
          : d.ehTecnico
              ? ('Meu dia', 'Suas ordens de serviço e avisos')
              : ('Início', 'Acompanhe os seus pedidos de manutenção'),
      Secao.chamados => ('Chamados', d.ehAdmin ? 'Quadro de acompanhamento por status' : 'Todos os chamados, por status'),
      Secao.ordens => d.ehAdmin ? ('Ordens de serviço', 'Execução das manutenções') : ('Minhas ordens', 'Ordens de serviço designadas a você'),
      Secao.preventivas => ('Preventivas', 'Cronograma e alertas de manutenção preventiva'),
      Secao.estoque => ('Estoque', 'Peças e materiais para as ordens de serviço'),
      Secao.ativos => ('Ativos', 'Equipamentos e bens patrimoniais'),
      Secao.ambientes => ('Ambientes', 'Locais onde os ativos estão instalados'),
      Secao.usuarios => ('Usuários', 'Quem acessa o sistema e com qual perfil'),
      Secao.indicadores => ('Indicadores', 'Desempenho da manutenção, calculado pela API'),
      Secao.notificacoes => ('Notificações', 'Avisos gerados pelo sistema para você'),
      Secao.meusChamados => ('Meus chamados', 'Acompanhe o andamento dos seus pedidos'),
      Secao.abrirChamado => ('Abrir chamado', 'Conte o que está acontecendo e onde'),
    };
  }

  /// Seções sem campo de busca no cabeçalho.
  bool get _temBusca => !{Secao.painel, Secao.preventivas, Secao.indicadores, Secao.abrirChamado, Secao.notificacoes}.contains(_secao);

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return ListenableBuilder(
      listenable: _dados,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final menuFixo = constraints.maxWidth >= _larguraMinimaMenuFixo;
            final titulo = _titulo();
            final menu = _MenuLateral(
              itens: _itensDoMenu(),
              secao: _secao,
              usuario: widget.usuario,
              onSecao: _irPara,
              onSair: _sair,
            );

            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: c.fundo,
              drawer: menuFixo ? null : Drawer(width: 272, backgroundColor: c.menu, child: menu),
              body: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (menuFixo) SizedBox(width: 248, child: menu),
                  Expanded(
                    child: SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Cabecalho(
                            titulo: titulo.$1,
                            subtitulo: titulo.$2,
                            mostrarBotaoMenu: !menuFixo,
                            onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                            mostrarBusca: _temBusca,
                            buscaController: _buscaController,
                            onBusca: _dados.definirBusca,
                            naoLidas: _dados.naoLidas,
                            onNotificacoes: () => _irPara(Secao.notificacoes),
                          ),
                          Expanded(child: _conteudo(context, menuFixo)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _conteudo(BuildContext context, bool telaLarga) {
    final c = context.cores;
    if (_dados.carregando) return const Center(child: CircularProgressIndicator(semanticsLabel: 'Carregando dados'));
    if (_dados.erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 40, color: c.textoSecundario),
              const SizedBox(height: 12),
              Text(_dados.erro!, textAlign: TextAlign.center, style: TextStyle(color: c.textoSecundario)),
              const SizedBox(height: 16),
              OutlinedButton.icon(onPressed: _dados.carregar, icon: const Icon(Icons.refresh_rounded), label: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
    }

    final d = _dados;
    final Widget tela = switch (_secao) {
      Secao.painel => d.ehAdmin
          ? PainelAdminView(dados: d, onIrPara: _irPara)
          : d.ehTecnico
              ? PainelTecnicoView(dados: d, onIrPara: _irPara)
              : PainelSolicitanteView(dados: d, onIrPara: _irPara),
      Secao.chamados => ChamadosKanbanView(dados: d),
      Secao.ordens => OrdensView(dados: d),
      Secao.preventivas => PreventivasView(dados: d),
      Secao.estoque => EstoqueView(dados: d),
      Secao.ativos => AtivosView(dados: d),
      Secao.ambientes => AmbientesView(dados: d),
      Secao.usuarios => UsuariosView(dados: d),
      Secao.indicadores => IndicadoresView(dados: d),
      Secao.notificacoes => NotificacoesView(dados: d),
      Secao.meusChamados => MeusChamadosView(dados: d, onIrPara: _irPara),
      Secao.abrirChamado => AbrirChamadoView(dados: d, onIrPara: _irPara),
    };

    return RefreshIndicator(
      onRefresh: _dados.carregar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(telaLarga ? 28 : 16, 8, telaLarga ? 28 : 16, 40),
        child: tela,
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final bool mostrarBotaoMenu;
  final VoidCallback onMenu;
  final bool mostrarBusca;
  final TextEditingController buscaController;
  final ValueChanged<String> onBusca;
  final int naoLidas;
  final VoidCallback onNotificacoes;

  const _Cabecalho({
    required this.titulo,
    required this.subtitulo,
    required this.mostrarBotaoMenu,
    required this.onMenu,
    required this.mostrarBusca,
    required this.buscaController,
    required this.onBusca,
    required this.naoLidas,
    required this.onNotificacoes,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final temaEscuro = GetIt.I<ThemeController>().themeMode == ThemeMode.dark;
    final estreita = MediaQuery.sizeOf(context).width < 600;

    return Padding(
      padding: EdgeInsets.fromLTRB(estreita ? 16 : 28, 22, estreita ? 16 : 28, 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (mostrarBotaoMenu) ...[
                BotaoIcone(icone: Icons.menu_rounded, rotulo: 'Abrir menu', onPressed: onMenu),
                const SizedBox(width: 12),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: estreita ? 230 : 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(titulo, style: TextStyle(fontSize: estreita ? 22 : 26, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                    ),
                    Text(subtitulo, style: TextStyle(fontSize: 14, color: c.textoSecundario)),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (mostrarBusca) ...[
                SizedBox(
                  width: estreita ? 170 : 320,
                  child: MergeSemantics(
                      child: Semantics(
                    label: 'Buscar nesta tela',
                    child: TextField(
                    controller: buscaController,
                    onChanged: onBusca,
                    textAlignVertical: TextAlignVertical.center,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Buscar…',
                      hintStyle: TextStyle(fontSize: 14, color: c.textoSecundario),
                      prefixIcon: Icon(Icons.search_rounded, color: c.textoSecundario, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                      isDense: true,
                    ),
                  ))),
                ),
                const SizedBox(width: 10),
              ],
              const BotaoAcessibilidade(),
              const SizedBox(width: 10),
              BotaoIcone(
                icone: temaEscuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                rotulo: temaEscuro ? 'Usar tema claro' : 'Usar tema escuro',
                onPressed: () => GetIt.I<ThemeController>().toggleTheme(),
              ),
              const SizedBox(width: 10),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  BotaoIcone(
                    icone: Icons.notifications_none_rounded,
                    rotulo: naoLidas == 0 ? 'Notificações' : 'Notificações, $naoLidas não ${naoLidas == 1 ? 'lida' : 'lidas'}',
                    onPressed: onNotificacoes,
                  ),
                  if (naoLidas > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                            child: Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          height: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: AuriaColors.nivelCritico, borderRadius: BorderRadius.circular(10)),
                          child: Text(naoLidas > 9 ? '9+' : '$naoLidas',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                        )),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Item do menu: ou um rótulo de grupo, ou um link para uma seção.
class _ItemMenu {
  final Secao? secao;
  final IconData? icone;
  final String texto;
  final int contador;
  final bool alerta;

  const _ItemMenu(Secao this.secao, IconData this.icone, this.texto, {this.contador = 0, this.alerta = false});
  const _ItemMenu.rotulo(this.texto)
      : secao = null,
        icone = null,
        contador = 0,
        alerta = false;
}

class _MenuLateral extends StatelessWidget {
  final List<_ItemMenu> itens;
  final Secao secao;
  final Usuario usuario;
  final ValueChanged<Secao> onSecao;
  final VoidCallback onSair;

  const _MenuLateral({required this.itens, required this.secao, required this.usuario, required this.onSecao, required this.onSair});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final perfil = switch (usuario.perfil) {
      Perfil.administrador => 'Administrador',
      Perfil.tecnicoResponsavel => 'Técnico',
      Perfil.solicitante => 'Solicitante',
    };

    return Container(
      color: c.menu,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AuriaMarca(
                  tamanhoSimbolo: 38,
                  tamanhoTexto: 20,
                  corPredio: Colors.white,
                  corTexto: Colors.white,
                  subtitulo: 'Manutenção predial',
                  corSubtitulo: c.menuRotulo,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final item in itens)
                    if (item.secao == null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
                        child: Semantics(
                          header: true,
                          label: item.texto,
                          excludeSemantics: true,
                          child: Text(item.texto.toUpperCase(),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: c.menuRotulo)),
                        ),
                      )
                    else
                      _BotaoMenu(item: item, ativo: item.secao == secao, onTap: () => onSecao(item.secao!)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 14, 0, 0),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1)))),
              child: Row(
                children: [
                  AvatarIniciais(nome: usuario.nome, tamanho: 40, cor: c.sobreDestaque, fundo: c.destaque),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(usuario.nome, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text(perfil, style: TextStyle(fontSize: 12, color: c.menuRotulo)),
                      ],
                    ),
                  ),
                  IconButton(tooltip: 'Sair', onPressed: onSair, icon: Icon(Icons.logout_rounded, color: c.menuTexto)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotaoMenu extends StatefulWidget {
  final _ItemMenu item;
  final bool ativo;
  final VoidCallback onTap;
  const _BotaoMenu({required this.item, required this.ativo, required this.onTap});

  @override
  State<_BotaoMenu> createState() => _BotaoMenuState();
}

class _BotaoMenuState extends State<_BotaoMenu> {
  bool _foco = false;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final item = widget.item;
    final ativo = widget.ativo;
    final contador = item.contador > 0
        ? (item.secao == Secao.estoque
            ? ', ${item.contador} ${item.contador == 1 ? 'item abaixo do mínimo' : 'itens abaixo do mínimo'}'
            : item.secao == Secao.notificacoes
                ? ', ${item.contador} não ${item.contador == 1 ? 'lida' : 'lidas'}'
                : ', ${item.contador} pendentes')
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Semantics(
        button: true,
        selected: ativo,
        label: '${item.texto}$contador${ativo ? ', página atual' : ''}',
        excludeSemantics: true,
        onTap: widget.onTap,
        child: Stack(
          children: [
            Material(
              color: ativo ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: _foco ? BorderSide(color: c.destaque, width: 2.5) : BorderSide.none,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                hoverColor: Colors.white.withValues(alpha: 0.06),
                focusColor: Colors.white.withValues(alpha: 0.10),
                onTap: widget.onTap,
                onFocusChange: (f) => setState(() => _foco = f),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(item.icone, size: 20, color: ativo ? Colors.white : c.menuTexto),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(item.texto,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ativo ? Colors.white : c.menuTexto)),
                      ),
                      if (item.contador > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.alerta ? AuriaColors.nivelCritico : Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('${item.contador}', style: AppTheme.numero(tamanho: 12, cor: Colors.white)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (ativo)
              Positioned(
                left: 0,
                top: 12,
                child: Container(width: 4, height: 20, decoration: BoxDecoration(color: c.destaque, borderRadius: BorderRadius.circular(4))),
              ),
          ],
        ),
      ),
    );
  }
}
