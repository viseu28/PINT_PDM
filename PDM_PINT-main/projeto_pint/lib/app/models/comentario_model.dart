import 'package:flutter/material.dart';

class ComentarioModel {
  final int id;
  final int idcurso;
  final int idutilizador;
  final String comentario;
  final double avaliacao;
  final DateTime data;
  final String? nomeUtilizador;
  final String? avatarUtilizador;
  final bool? ehProprietario;
  final String? tipoUtilizador; // Novo campo para tipo do utilizador

  ComentarioModel({
    required this.id,
    required this.idcurso,
    required this.idutilizador,
    required this.comentario,
    required this.avaliacao,
    required this.data,
    this.nomeUtilizador,
    this.avatarUtilizador,
    this.ehProprietario,
    this.tipoUtilizador,
  });

  String get dataFormatada {
    // Formatação simples da data (DD/MM/AAAA)
    final day = data.day.toString().padLeft(2, '0');
    final month = data.month.toString().padLeft(2, '0');
    final year = data.year.toString();
    
    return '$day/$month/$year';
  }

  // Método para obter o rótulo do tipo de utilizador
  String? get tipoUtilizadorLabel {
    if (tipoUtilizador == null) return null;
    
    final tipoLimpo = tipoUtilizador!.toLowerCase().trim();
    
    switch (tipoLimpo) {
      case 'gestor':
      case 'administrador':
        return 'Gestor';
      case 'formador':
      case 'instrutor':
        return 'Formador';
      case 'formando':
      case 'aluno':
      case 'estudante':
        return null; // Não mostra nada para formandos
      default:
        return null;
    }
  }

  // Método para obter a cor do rótulo
  Color? get tipoUtilizadorColor {
    if (tipoUtilizador == null) return null;
    
    final tipoLimpo = tipoUtilizador!.toLowerCase().trim();
    
    switch (tipoLimpo) {
      case 'gestor':
      case 'administrador':
        return const Color(0xFF8B5CF6); // Roxo para gestor
      case 'formador':
      case 'instrutor':
        return const Color(0xFF10B981); // Verde para formador
      default:
        return null;
    }
  }
  
  factory ComentarioModel.fromJson(Map<String, dynamic> json) {
    DateTime parseData(dynamic data) {
      if (data == null) return DateTime.now();
      if (data is DateTime) return data;
      if (data is String) {
        try {
          return DateTime.parse(data);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }
    
    return ComentarioModel(
      id: json['id'] as int,
      idcurso: json['idcurso'] as int,
      idutilizador: json['idutilizador'] as int,
      comentario: json['comentario'] as String,
      avaliacao: (json['avaliacao'] is num) 
          ? (json['avaliacao'] as num).toDouble() 
          : (json['avaliacao'] is String) 
              ? double.tryParse(json['avaliacao']) ?? 0.0 
              : 0.0,
      data: parseData(json['data']),
      nomeUtilizador: json['nome_utilizador'],
      avatarUtilizador: json['avatar_utilizador'],
      ehProprietario: json['eh_proprietario'],
      tipoUtilizador: json['tipo_utilizador'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idcurso': idcurso,
      'idutilizador': idutilizador,
      'comentario': comentario,
      'avaliacao': avaliacao,
      'data': data.toIso8601String(),
    };
  }
}
