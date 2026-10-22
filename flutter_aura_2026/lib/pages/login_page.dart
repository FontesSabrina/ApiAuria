import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../core/acessibilidade/painel_acessibilidade.dart';
import '../core/ui/auria_colors.dart';
import '../core/ui/auria_logo.dart';
import '../core/ui/botoes.dart';
import '../domain/repositories/usuario_repository.dart';
import '../domain/services/usuario_domain_services.dart';
import 'shell/auria_shell.dart';

/// Tela de login: painel da marca à esquerda (some em telas estreitas) e formulário à direita.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  late final _service = UsuarioDomainServices(GetIt.I<UsuarioRepository>());
  bool _verSenha = false;
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_carregando || !_form.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final usuario = await _service.autenticar(_email.text, _senha.text);
      if (!mounted) return;
      if (usuario == null) {
        setState(() => _erro = 'Acesso negado. Verifique suas credenciais.');
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AuriaShell(usuario: usuario)));
        return;
      }
    } catch (e) {
      if (mounted) setState(() => _erro = '$e');
    }
    if (mounted) setState(() => _carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Scaffold(
      backgroundColor: c.fundo,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final larga = constraints.maxWidth >= 920;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (larga) Expanded(child: _PainelMarca(cores: c)),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Form(
                        key: _form,
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(children: [
                                if (!larga) AuriaMarca(tamanhoSimbolo: 42, tamanhoTexto: 22, corPredio: c.texto, corTexto: c.texto),
                                const Spacer(),
                                const BotaoAcessibilidade(),
                              ]),
                              SizedBox(height: larga ? 16 : 32),
                              Semantics(header: true, child: const Text('Entrar', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
                              const SizedBox(height: 6),
                              Text('Use o e-mail e a senha cadastrados pelo administrador.', style: TextStyle(fontSize: 14, color: c.textoSecundario)),
                              const SizedBox(height: 28),
                              MergeSemantics(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              const Text('E-mail', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(hintText: 'voce@empresa.com', prefixIcon: Icon(Icons.alternate_email_rounded, color: c.textoSecundario)),
                                validator: (v) => (v ?? '').trim().isEmpty ? 'Informe o e-mail' : null,
                              ),
                              ])),
                              const SizedBox(height: 16),
                              MergeSemantics(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              const Text('Senha', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _senha,
                                obscureText: !_verSenha,
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _entrar(),
                                decoration: InputDecoration(
                                  hintText: '••••••',
                                  prefixIcon: Icon(Icons.lock_outline_rounded, color: c.textoSecundario),
                                  suffixIcon: IconButton(
                                    tooltip: _verSenha ? 'Esconder senha' : 'Mostrar senha',
                                    onPressed: () => setState(() => _verSenha = !_verSenha),
                                    icon: Icon(_verSenha ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                  ),
                                ),
                                validator: (v) => (v ?? '').isEmpty ? 'Informe a senha' : null,
                              ),
                              ])),
                              if (_erro != null) ...[
                                const SizedBox(height: 16),
                                // liveRegion: o leitor de tela anuncia o erro assim que ele aparece.
                                Semantics(
                                  liveRegion: true,
                                  label: 'Erro: $_erro',
                                  excludeSemantics: true,
                                  child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: c.vermelhoFundo, borderRadius: BorderRadius.circular(12)),
                                  child: Row(children: [
                                    Icon(Icons.error_outline_rounded, color: c.vermelho, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(_erro!, style: TextStyle(color: c.vermelho, fontWeight: FontWeight.w600))),
                                  ]),
                                )),
                              ],
                              const SizedBox(height: 24),
                              FilledButton(
                                style: botaoDestaque(c).copyWith(minimumSize: const WidgetStatePropertyAll(Size(0, 50))),
                                onPressed: _carregando ? null : _entrar,
                                child: _carregando
                                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: c.sobreDestaque, semanticsLabel: 'Entrando'))
                                    : const Text('Entrar'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PainelMarca extends StatelessWidget {
  final AuriaColors cores;
  const _PainelMarca({required this.cores});

  @override
  Widget build(BuildContext context) {
    final c = cores;
    Widget beneficio(IconData icone, String texto) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Icon(icone, color: c.destaque, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(texto, style: TextStyle(fontSize: 15, color: c.menuTexto))),
          ]),
        );

    return Container(
      color: c.menu,
      padding: const EdgeInsets.all(56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuriaMarca(
            tamanhoSimbolo: 48,
            tamanhoTexto: 24,
            corPredio: Colors.white,
            corTexto: Colors.white,
            subtitulo: 'MANUTENÇÃO PREDIAL',
            corSubtitulo: c.menuRotulo,
          ),
          const Spacer(),
          const Text('Manutenção predial\nsem papel e sem planilha.',
              style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15, letterSpacing: -0.5)),
          const SizedBox(height: 32),
          beneficio(Icons.confirmation_number_outlined, 'Chamados abertos em segundos, de qualquer lugar'),
          beneficio(Icons.handyman_outlined, 'Ordens de serviço com peças e custos registrados'),
          beneficio(Icons.insights_outlined, 'Indicadores e alertas de manutenção preventiva'),
          const Spacer(),
          Text('IF Sudeste MG · Campus Muriaé', style: TextStyle(fontSize: 12, color: c.menuRotulo)),
        ],
      ),
    );
  }
}
