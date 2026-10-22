import 'package:flutter/foundation.dart' show immutable;

@immutable
class Ambiente {
  final String id;
  final String nome;
  final String predio;
  final String andar;
  final String observacoes;

  const Ambiente({
    required this.id, 
    required this.nome, 
    required this.predio, 
    required this.andar, 
    required this.observacoes,
  });
}