import 'package:flutter/foundation.dart' show immutable;
import 'usuario.dart';
import 'ativo.dart';

enum TipoManutencao { corretiva, preventiva, preditiva }
enum StatusChamado { aberto, emExecucao, concluido, cancelado }

@immutable
class Chamado {
  final String id;
  final Ativo ativo;
  final Usuario solicitante;
  final String descricaoFalha;
  final String prioridade;
  final TipoManutencao tipo;
  final StatusChamado status;
  final DateTime dataAbertura;
  final Usuario? tecnicoResponsavel;

  const Chamado({
    required this.id,
    required this.ativo,
    required this.solicitante,
    required this.descricaoFalha,
    required this.prioridade,
    required this.tipo,
    required this.status,
    required this.dataAbertura,
    this.tecnicoResponsavel,
  });

  Chamado copyWith({
    String? prioridade,
    TipoManutencao? tipo,
    StatusChamado? status,
    Usuario? tecnicoResponsavel,
  }) {
    return Chamado(
      id: id,
      ativo: ativo,
      solicitante: solicitante,
      descricaoFalha: descricaoFalha,
      prioridade: prioridade ?? this.prioridade,
      tipo: tipo ?? this.tipo,
      status: status ?? this.status,
      dataAbertura: dataAbertura,
      tecnicoResponsavel: tecnicoResponsavel ?? this.tecnicoResponsavel,
    );
  }
}