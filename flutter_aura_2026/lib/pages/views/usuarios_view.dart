import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/ui/auria_colors.dart';
import '../../core/ui/botoes.dart';
import '../../core/ui/layout.dart';
import '../../core/ui/widgets.dart';
import '../../domain/entities/usuario.dart';
import '../shell/app_dados.dart';

String nomePerfil(Perfil p) => switch (p) {
      Perfil.administrador => 'Administrador',
      Perfil.tecnicoResponsavel => 'Técnico',
      Perfil.solicitante => 'Solicitante',
    };

class PilulaPerfil extends StatelessWidget {
  final Perfil perfil;
  const PilulaPerfil({super.key, required this.perfil});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final (cor, fundo) = switch (perfil) {
      Perfil.administrador => (c.ambar, c.ambarFundo),
      Perfil.tecnicoResponsavel => (c.laranja, c.laranjaFundo),
      Perfil.solicitante => (c.azul, c.azulFundo),
    };
    return Pilula(texto: nomePerfil(perfil), cor: cor, fundo: fundo);
  }
}

class UsuariosView extends StatefulWidget {
  final AppDados dados;
  const UsuariosView({super.key, required this.dados});

  @override
  State<UsuariosView> createState() => _UsuariosViewState();
}

class _UsuariosViewState extends State<UsuariosView> {
  Perfil? _perfil;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final d = widget.dados;
    final lista = d.usuarios
        .where((u) => _perfil == null || u.perfil == _perfil)
        .where((u) => d.passaNaBusca('${u.nome} ${u.email}'))
        .toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChipFiltro(texto: 'Todos (${d.usuarios.length})', selecionado: _perfil == null, onTap: () => setState(() => _perfil = null)),
            for (final p in Perfil.values)
              ChipFiltro(
                texto: '${nomePerfil(p)} (${d.usuarios.where((u) => u.perfil == p).length})',
                selecionado: _perfil == p,
                onTap: () => setState(() => _perfil = p),
              ),
            const SizedBox(width: 12),
            FilledButton.icon(
              style: botaoDestaque(c),
              onPressed: () => abrirFormularioUsuario(context, d),
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
              label: const Text('Novo usuário'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        AuriaCard(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
          child: lista.isEmpty
              ? const EstadoVazio(mensagem: 'Nenhum usuário encontrado.', icone: Icons.group_outlined)
              : Column(
                  children: [
                    for (var i = 0; i < lista.length; i++)
                      InkWell(
                        onTap: () => abrirFormularioUsuario(context, d, usuario: lista[i]),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(border: i == lista.length - 1 ? null : Border(bottom: BorderSide(color: c.borda))),
                          child: Row(
                            children: [
                              AvatarIniciais(nome: lista[i].nome, tamanho: 40),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Flexible(child: Text(lista[i].nome, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700))),
                                      if (lista[i].id == d.usuario.id) ...[
                                        const SizedBox(width: 8),
                                        Pilula(texto: 'Você', cor: c.textoSecundario, fundo: c.cinzaFundo, comPonto: false),
                                      ],
                                    ]),
                                    Text(lista[i].email, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: c.textoSecundario)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              PilulaPerfil(perfil: lista[i].perfil),
                              const SizedBox(width: 6),
                              Icon(Icons.chevron_right_rounded, color: c.textoSecundario),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

Future<void> abrirFormularioUsuario(BuildContext context, AppDados dados, {Usuario? usuario}) =>
    mostrarPainelLateral(context, builder: (_) => _FormularioUsuario(dados: dados, usuario: usuario));

class _FormularioUsuario extends StatefulWidget {
  final AppDados dados;
  final Usuario? usuario;
  const _FormularioUsuario({required this.dados, this.usuario});

  @override
  State<_FormularioUsuario> createState() => _FormularioUsuarioState();
}

class _FormularioUsuarioState extends State<_FormularioUsuario> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.usuario?.nome ?? '');
  late final _email = TextEditingController(text: widget.usuario?.email ?? '');
  final _senha = TextEditingController();
  final _confirmar = TextEditingController();
  late Perfil _perfil = widget.usuario?.perfil ?? Perfil.solicitante;
  bool _verSenha = false;
  bool _enviando = false;

  bool get _edicao => widget.usuario != null;
  bool get _souEu => widget.usuario?.id == widget.dados.usuario.id;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    final u = Usuario(
      id: widget.usuario?.id ?? const Uuid().v4(),
      nome: _nome.text.trim(),
      email: _email.text.trim(),
      senha: _senha.text,
      perfil: _perfil,
    );
    final ok = await executarComAviso(context, () => widget.dados.salvarUsuario(u), _edicao ? 'Usuário atualizado!' : 'Usuário cadastrado!');
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _enviando = false);
    }
  }

  Future<void> _excluir() async {
    final u = widget.usuario!;
    final ok = await confirmar(context,
        titulo: 'Excluir ${u.nome}?', mensagem: 'Usuários com chamados ou ordens de serviço não podem ser excluídos — nesse caso, altere o perfil.', acao: 'Excluir', perigosa: true);
    if (!ok || !mounted) return;
    if (await executarComAviso(context, () => widget.dados.excluirUsuario(u), 'Usuário excluído') && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final olho = IconButton(
      tooltip: _verSenha ? 'Esconder senha' : 'Mostrar senha',
      onPressed: () => setState(() => _verSenha = !_verSenha),
      icon: Icon(_verSenha ? Icons.visibility_off_outlined : Icons.visibility_outlined),
    );

    return Form(
      key: _form,
      child: EstruturaPainel(
        cabecalho: TituloPainel(
          titulo: _edicao ? widget.usuario!.nome : 'Novo usuário',
          sobretitulo: _edicao ? widget.usuario!.email : null,
          etiquetas: _edicao ? [PilulaPerfil(perfil: widget.usuario!.perfil)] : const [],
        ),
        corpo: [
          CampoFormulario(
            rotulo: 'Nome completo',
            campo: TextFormField(controller: _nome, validator: (v) => (v ?? '').trim().length < 3 ? 'Informe o nome (mínimo 3 letras)' : null),
          ),
          CampoFormulario(
            rotulo: 'E-mail',
            campo: TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Informe um e-mail válido',
            ),
          ),
          CampoFormulario(
            rotulo: 'Perfil de acesso',
            ajuda: _souEu ? 'Você não pode tirar o seu próprio perfil de administrador.' : null,
            campo: SeletorPilulas<Perfil>(
              opcoes: Perfil.values,
              selecionado: _perfil,
              rotulo: nomePerfil,
              onSelecionar: (p) => setState(() => _perfil = p),
            ),
          ),
          CampoFormulario(
            rotulo: _edicao ? 'Nova senha (deixe em branco para manter)' : 'Senha',
            campo: TextFormField(
              controller: _senha,
              obscureText: !_verSenha,
              decoration: InputDecoration(suffixIcon: olho),
              validator: (v) {
                final s = v ?? '';
                if (s.isEmpty) return _edicao ? null : 'Informe a senha';
                return s.length < 6 ? 'A senha deve ter pelo menos 6 caracteres' : null;
              },
            ),
          ),
          CampoFormulario(
            rotulo: 'Confirmar senha',
            campo: TextFormField(
              controller: _confirmar,
              obscureText: !_verSenha,
              validator: (v) => (v ?? '') != _senha.text ? 'As senhas não coincidem' : null,
            ),
          ),
        ],
        rodape: Row(
          children: [
            if (_edicao && !_souEu) ...[
              OutlinedButton(style: botaoSecundario(c, cor: c.vermelho), onPressed: _enviando ? null : _excluir, child: const Text('Excluir')),
              const SizedBox(width: 10),
            ],
            Expanded(child: FilledButton(style: botaoDestaque(c), onPressed: _enviando ? null : _salvar, child: Text(_edicao ? 'Salvar alterações' : 'Cadastrar usuário'))),
          ],
        ),
      ),
    );
  }
}
