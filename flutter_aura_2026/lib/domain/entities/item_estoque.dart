import 'package:flutter/foundation.dart' show immutable;

@immutable
class ItemEstoque {
  final String id;
  final String nome;
  final int quantidade;
  final int nivelMinimo;
  final String unidadeMedida;
  final String fornecedor;
  final double precoUnitario;

  const ItemEstoque({
    required this.id,
    required this.nome,
    required this.quantidade,
    this.nivelMinimo = 5,
    this.unidadeMedida = 'Unidade',
    this.fornecedor = 'Sem fornecedor',
    this.precoUnitario = 0.0,
  });

  bool get alertaEstoqueBaixo => quantidade <= nivelMinimo;

  ItemEstoque copyWith({
    String? id,
    String? nome,
    int? quantidade,
    int? nivelMinimo,
    String? unidadeMedida,
    String? fornecedor,
    double? precoUnitario,
  }) {
    return ItemEstoque(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      quantidade: quantidade ?? this.quantidade,
      nivelMinimo: nivelMinimo ?? this.nivelMinimo,
      unidadeMedida: unidadeMedida ?? this.unidadeMedida,
      fornecedor: fornecedor ?? this.fornecedor,
      precoUnitario: precoUnitario ?? this.precoUnitario,
    );
  }
}