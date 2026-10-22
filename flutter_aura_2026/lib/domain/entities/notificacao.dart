import 'package:flutter/foundation.dart' show immutable;

@immutable
class Notificacao {
  final String id;
  final String titulo;
  final String mensagem;
  final DateTime dataCriacao;
  final bool lida; 
  final String usuarioId; 

  const Notificacao({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.dataCriacao,
    this.lida = false, 
    required this.usuarioId,
  });

  Notificacao copyWith({bool? lida}) {
    return Notificacao(
      id: id,
      titulo: titulo,
      mensagem: mensagem,
      dataCriacao: dataCriacao,
      lida: lida ?? this.lida,
      usuarioId: usuarioId,
    );
  }
}