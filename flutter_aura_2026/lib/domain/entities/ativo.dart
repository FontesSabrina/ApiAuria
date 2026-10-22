import 'package:flutter/foundation.dart' show immutable;

@immutable
class Ativo {
  final String id;
  final String patrimonio;
  final String nome;
  final String ambienteId;
  // Só para exibição (nome do ambiente vinculado); não é persistido, é
  // preenchido pelo datasource ao carregar a lista/detalhe.
  final String? ambienteNome;
  final String estadoConservacao;
  final DateTime dataAquisicao;

  const Ativo({
    required this.id,
    required this.patrimonio,
    required this.nome,
    required this.ambienteId,
    this.ambienteNome,
    required this.estadoConservacao,
    required this.dataAquisicao,
  });

  Ativo copyWith({
    String? patrimonio,
    String? nome,
    String? ambienteId,
    String? ambienteNome,
    String? estadoConservacao,
  }) {
    return Ativo(
      id: id,
      patrimonio: patrimonio ?? this.patrimonio,
      nome: nome ?? this.nome,
      ambienteId: ambienteId ?? this.ambienteId,
      ambienteNome: ambienteNome ?? this.ambienteNome,
      estadoConservacao: estadoConservacao ?? this.estadoConservacao,
      dataAquisicao: dataAquisicao,
    );
  }
}