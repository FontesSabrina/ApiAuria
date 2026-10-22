import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/ambiente.dart';
import '../../domain/entities/ativo.dart';
import '../../domain/entities/chamado.dart';
import '../../domain/entities/indicadores.dart';
import '../../domain/entities/item_estoque.dart';
import '../../domain/entities/notificacao.dart';
import '../../domain/entities/ordem_servico.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/ambiente_repository.dart';
import '../../domain/repositories/ativo_repository.dart';
import '../../domain/repositories/chamado_repository.dart';
import '../../domain/repositories/estoque_repository.dart';
import '../../domain/repositories/indicadores_repository.dart';
import '../../domain/repositories/notificacao_repository.dart';
import '../../domain/repositories/ordem_servico_repository.dart';
import '../../domain/repositories/usuario_repository.dart';
import '../../domain/services/chamado_domain_services.dart';

/// Estado compartilhado de todas as telas (os três perfis).
/// Carrega da API só o que o perfil logado pode ver e é recarregado depois de cada ação.
class AppDados extends ChangeNotifier {
  final Usuario usuario;
  AppDados(this.usuario);

  final _chamadosRepo = GetIt.I<ChamadoRepository>();
  final _estoqueRepo = GetIt.I<EstoqueRepository>();
  final _notificacoesRepo = GetIt.I<NotificacaoRepository>();
  final _indicadoresRepo = GetIt.I<IndicadoresRepository>();
  final _ordensRepo = GetIt.I<OrdemServicoRepository>();
  final _usuariosRepo = GetIt.I<UsuarioRepository>();
  final _ativosRepo = GetIt.I<AtivoRepository>();
  final _ambientesRepo = GetIt.I<AmbienteRepository>();
  final _chamadoService = GetIt.I<ChamadoDomainServices>();

  bool get ehAdmin => usuario.perfil == Perfil.administrador;
  bool get ehTecnico => usuario.perfil == Perfil.tecnicoResponsavel;
  bool get ehSolicitante => usuario.perfil == Perfil.solicitante;

  bool carregando = true;
  String? erro;
  List<Chamado> chamados = [];
  List<ItemEstoque> estoque = [];
  List<Notificacao> notificacoes = [];
  List<OrdemServico> ordens = [];
  List<Usuario> usuarios = [];
  List<Ativo> ativos = [];
  List<Ambiente> ambientes = [];
  Indicadores? indicadores;

  /// Texto da busca do cabeçalho (cada tela filtra os seus itens com ele).
  String busca = '';

  bool _jaCarregou = false;

  Future<void> carregar() async {
    carregando = !_jaCarregou;
    erro = null;
    notifyListeners();
    try {
      notificacoes = await _notificacoesRepo.buscarMinhasNotificacoes();
      if (ehAdmin) {
        final r = await Future.wait([
          _chamadosRepo.buscarTodos(),
          _estoqueRepo.buscarTodos(),
          _ordensRepo.buscarTodos(),
          _usuariosRepo.buscarTodos(),
          _ativosRepo.buscarTodos(),
          _ambientesRepo.buscarTodos(),
        ]);
        chamados = r[0] as List<Chamado>;
        estoque = r[1] as List<ItemEstoque>;
        ordens = r[2] as List<OrdemServico>;
        usuarios = r[3] as List<Usuario>;
        ativos = r[4] as List<Ativo>;
        ambientes = r[5] as List<Ambiente>;
        try {
          indicadores = await _indicadoresRepo.buscarResumo();
        } catch (_) {
          indicadores = null; // o painel funciona mesmo sem os indicadores
        }
      } else if (ehTecnico) {
        final r = await Future.wait([
          _chamadosRepo.buscarTodos(),
          _estoqueRepo.buscarTodos(),
          _ordensRepo.buscarMinhas(),
        ]);
        chamados = r[0] as List<Chamado>;
        estoque = r[1] as List<ItemEstoque>;
        ordens = r[2] as List<OrdemServico>;
      } else {
        final r = await Future.wait([
          _chamadosRepo.buscarMeusChamados(),
          _ativosRepo.buscarTodos(),
        ]);
        chamados = r[0] as List<Chamado>;
        ativos = r[1] as List<Ativo>;
      }
      _jaCarregou = true;
    } catch (e) {
      erro = '$e';
    }
    carregando = false;
    notifyListeners();
  }

  void definirBusca(String texto) {
    busca = texto.trim().toLowerCase();
    notifyListeners();
  }

  bool passaNaBusca(String texto) => busca.isEmpty || texto.toLowerCase().contains(busca);

  // ---------- números ----------
  int contar(StatusChamado status) => chamados.where((c) => c.status == status).length;
  Map<StatusChamado, int> get chamadosPorStatus => {for (final s in StatusChamado.values) s: contar(s)};
  int get abertos => contar(StatusChamado.aberto);
  int get emExecucao => contar(StatusChamado.emExecucao);
  int get naoLidas => notificacoes.where((n) => !n.lida).length;

  List<ItemEstoque> get criticos => estoque.where((i) => i.quantidade <= i.nivelMinimo).toList();
  List<Usuario> get tecnicos => usuarios.where((u) => u.perfil == Perfil.tecnicoResponsavel).toList();
  List<OrdemServico> get ordensEmAndamento => ordens.where((o) => o.status != StatusOS.concluida).toList();
  List<OrdemServico> get ordensConcluidas => ordens.where((o) => o.status == StatusOS.concluida).toList();

  int get taxaConclusao {
    if (indicadores != null) return indicadores!.taxaConclusao.round();
    if (ordens.isEmpty) return 0;
    return (ordensConcluidas.length * 100 / ordens.length).round();
  }

  int cargaDoTecnico(Usuario tecnico) => ordensEmAndamento.where((o) => o.tecnicoResponsavelId == tecnico.id).length;

  int ativosNoAmbiente(Ambiente ambiente) => ativos.where((a) => a.ambienteId == ambiente.id).length;

  bool podeExecutar(OrdemServico os) =>
      os.status != StatusOS.concluida && (ehAdmin || (ehTecnico && os.tecnicoResponsavelId == usuario.id));

  // ---------- ações (cada uma recarrega os dados no fim) ----------
  Future<T> _eRecarregar<T>(Future<T> Function() acao) async {
    final r = await acao();
    await carregar();
    return r;
  }

  Future<void> aprovar(Chamado chamado, Usuario tecnico) =>
      _eRecarregar(() => _chamadoService.aprovarChamadoEGerarOS(chamado: chamado, tecnico: tecnico, usuarioLogado: usuario));

  Future<void> cancelar(Chamado chamado) => _eRecarregar(() => _chamadoService.cancelarChamado(chamado));

  Future<void> abrirChamado(Chamado chamado) => _eRecarregar(() => _chamadoService.registrarChamado(chamado));

  Future<void> registrarEntrada(ItemEstoque item, int quantidade) =>
      _eRecarregar(() => _estoqueRepo.salvar(item.copyWith(quantidade: item.quantidade + quantidade)));

  Future<void> salvarItem(ItemEstoque item) => _eRecarregar(() => _estoqueRepo.salvar(item));
  Future<void> excluirItem(ItemEstoque item) => _eRecarregar(() => _estoqueRepo.excluir(item.id));

  Future<void> salvarAtivo(Ativo ativo) => _eRecarregar(() => _ativosRepo.salvar(ativo));
  Future<void> excluirAtivo(Ativo ativo) => _eRecarregar(() => _ativosRepo.excluir(ativo.id));

  Future<void> salvarAmbiente(Ambiente ambiente) => _eRecarregar(() => _ambientesRepo.salvar(ambiente));
  Future<void> excluirAmbiente(Ambiente ambiente) => _eRecarregar(() => _ambientesRepo.excluir(ambiente.id));

  Future<void> salvarUsuario(Usuario u) => _eRecarregar(() => _usuariosRepo.salvar(u));
  Future<void> excluirUsuario(Usuario u) => _eRecarregar(() => _usuariosRepo.excluir(u.id));

  /// Registra peças na OS e devolve a OS atualizada (com o custo de peças recalculado pela API).
  Future<OrdemServico> registrarConsumo(OrdemServico os, ItemEstoque item, int quantidade) =>
      _eRecarregar(() => _ordensRepo.registrarConsumo(ordemId: os.id, itemEstoqueId: item.id, quantidade: quantidade));

  Future<void> concluirOrdem(OrdemServico os, {required String parecer, required int minutos, required double maoDeObra}) =>
      _eRecarregar(() => _ordensRepo.concluir(ordemId: os.id, parecerTecnico: parecer, tempoGastoMinutos: minutos, custoMaoDeObra: maoDeObra));

  Future<void> marcarComoLida(Notificacao n) => _eRecarregar(() => _notificacoesRepo.marcarComoLida(n.id));

  Future<void> marcarTodasComoLidas() => _eRecarregar(() async {
        for (final n in notificacoes.where((n) => !n.lida)) {
          await _notificacoesRepo.marcarComoLida(n.id);
        }
      });
}
