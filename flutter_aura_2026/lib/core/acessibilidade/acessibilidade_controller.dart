import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferências de acessibilidade do usuário, salvas no aparelho (shared_preferences).
///
/// Elas se somam às configurações do próprio sistema operacional: se a pessoa já usa
/// fonte grande, alto contraste ou "remover animações" no celular/computador, o app respeita.
class AcessibilidadeController extends ChangeNotifier {
  AcessibilidadeController._();
  static final AcessibilidadeController instance = AcessibilidadeController._();

  /// Tamanhos de texto oferecidos (multiplicam o tamanho escolhido no sistema).
  static const List<double> escalas = [1.0, 1.15, 1.3, 1.5];

  static String nomeEscala(double e) {
    if (e <= 1.0) return 'Normal';
    if (e <= 1.15) return 'Grande';
    if (e <= 1.3) return 'Maior';
    return 'Máximo';
  }

  /// Limite total (sistema × app), para o layout não quebrar.
  static const double escalaMaxima = 2.0;

  static const _kEscala = 'a11y_escala_texto';
  static const _kContraste = 'a11y_alto_contraste';
  static const _kFonte = 'a11y_fonte_legivel';
  static const _kMovimento = 'a11y_reduzir_movimento';

  double _escalaTexto = 1.0;
  bool _altoContraste = false;
  bool _fonteLegivel = false;
  bool _reduzirMovimento = false;

  double get escalaTexto => _escalaTexto;
  bool get altoContraste => _altoContraste;
  bool get fonteLegivel => _fonteLegivel;
  bool get reduzirMovimento => _reduzirMovimento;

  bool get personalizado => _escalaTexto != 1.0 || _altoContraste || _fonteLegivel || _reduzirMovimento;

  Future<void> carregar() async {
    try {
      final p = await SharedPreferences.getInstance();
      final escala = p.getDouble(_kEscala) ?? 1.0;
      _escalaTexto = escalas.contains(escala) ? escala : 1.0;
      _altoContraste = p.getBool(_kContraste) ?? false;
      _fonteLegivel = p.getBool(_kFonte) ?? false;
      _reduzirMovimento = p.getBool(_kMovimento) ?? false;
    } catch (_) {
      // Sem acesso ao armazenamento: segue com os padrões.
    }
  }

  Future<void> definirEscala(double valor) async {
    _escalaTexto = valor;
    notifyListeners();
    await _salvar((p) => p.setDouble(_kEscala, valor));
  }

  Future<void> definirAltoContraste(bool valor) async {
    _altoContraste = valor;
    notifyListeners();
    await _salvar((p) => p.setBool(_kContraste, valor));
  }

  Future<void> definirFonteLegivel(bool valor) async {
    _fonteLegivel = valor;
    notifyListeners();
    await _salvar((p) => p.setBool(_kFonte, valor));
  }

  Future<void> definirReduzirMovimento(bool valor) async {
    _reduzirMovimento = valor;
    notifyListeners();
    await _salvar((p) => p.setBool(_kMovimento, valor));
  }

  Future<void> restaurarPadrao() async {
    _escalaTexto = 1.0;
    _altoContraste = false;
    _fonteLegivel = false;
    _reduzirMovimento = false;
    notifyListeners();
    await _salvar((p) async {
      await p.remove(_kEscala);
      await p.remove(_kContraste);
      await p.remove(_kFonte);
      await p.remove(_kMovimento);
      return true;
    });
  }

  Future<void> _salvar(Future<bool> Function(SharedPreferences) acao) async {
    try {
      await acao(await SharedPreferences.getInstance());
    } catch (_) {
      // Falha ao salvar não impede o uso: a preferência vale até fechar o app.
    }
  }
}

/// Atalho: true quando as animações devem ser desligadas (pelo sistema ou pelo app).
bool semAnimacao(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
