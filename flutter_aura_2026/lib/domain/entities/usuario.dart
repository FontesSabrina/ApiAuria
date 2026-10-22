import 'package:flutter/foundation.dart' show immutable;

enum Perfil { administrador, tecnicoResponsavel, solicitante }

@immutable
class Usuario {
  final String id;
  final String nome;
  final String email;
  final String senha; 
  final Perfil perfil; 

  const Usuario({
    required this.id, 
    required this.nome, 
    required this.email, 
    required this.senha, 
    required this.perfil,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Usuario && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Usuario copyWith({
    String? id,
    String? nome,
    String? email,
    String? senha,
    Perfil? perfil,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      senha: senha ?? this.senha,
      perfil: perfil ?? this.perfil,
    );
  }
}