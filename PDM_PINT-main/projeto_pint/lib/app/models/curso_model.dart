/*
curso_model.dart - O que é e para que serve?
O curso_model.dart é o modelo de dados que define a estrutura de um curso no seu app. 
Pensa nele como um "molde" ou "template" que define:

Principais funções:
  1-Estrutura de Dados: Define todos os campos que um curso pode ter 
    (título, descrição, pontos, etc.)
  2-Serialização: Converte dados JSON (da API) em objetos Dart e vice-versa
  3-Validação: Garante que os dados estão no formato correto
  4-Métodos Utilitários: Funções auxiliares como corDificuldade e nivelDificuldade

Exemplo prático:

// Em vez de trabalhar com dados "soltos" assim:
Map<String, dynamic> curso = {
  'titulo': 'Python Básico',
  'dificuldade': 'iniciante',
  'pontos': 100
};

// Você trabalha com um objeto estruturado:
Curso curso = Curso(
  titulo: 'Python Básico',
  dificuldade: 'Iniciante',
  pontos: 100
);

// E pode usar métodos úteis:
Color cor = curso.corDificuldade; // Retorna Colors.green automaticamente
*/

import 'package:flutter/material.dart';

class Curso {
  final int? id;
  final String titulo;
  final String descricao;
  final String? dataInicio;
  final String? dataFim;
  final String dificuldade;
  final int pontos;
  final String? tema;
  final String? categoria;
  final double? avaliacao;
  final bool inscrito;
  final String? imagemUrl;
  final int? progresso; // 0-100
  final bool? sincrono; // true = síncrono, false = assíncrono

  // Campo para estado do curso (ex: 'em curso', 'terminado')
  final String? estado;

  // Novas colunas adicionadas
  final String? formadorResponsavel;
  final String? informacoes;
  final String? video;
  final String? alertaFormador;
  final String? aprenderNoCurso;
  final String? requisitos;
  final String? publicoAlvo;
  final String? dados;
  final String? duracao;
  final String? idioma;
  bool favorito;

  Curso({
    this.id,
    required this.titulo,
    required this.descricao,
    this.dataInicio,
    this.dataFim,
    required this.dificuldade,
    required this.pontos,
    this.tema,
    this.categoria,
    this.avaliacao,
    this.inscrito = false,
    this.imagemUrl,
    this.progresso,
    this.sincrono,
    this.estado,
    // Novos campos
    this.formadorResponsavel,
    this.informacoes,
    this.video,
    this.alertaFormador,
    this.aprenderNoCurso,
    this.requisitos,
    this.publicoAlvo,
    this.dados,
    this.duracao,
    this.idioma,
    this.favorito = false,
  });

  factory Curso.fromJson(Map<String, dynamic> json) {
    return Curso(
      id: json['idcurso'] ?? json['id'], // Aceitar ambos os formatos
      titulo: json['titulo']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      dataInicio: json['data_inicio']?.toString(),
      dataFim: json['data_fim']?.toString(),
      dificuldade: json['dificuldade']?.toString() ?? 'Iniciante',
      pontos: json['pontos'] ?? 0,
      tema: json['tema']?.toString(),
      categoria: json['categoria']?.toString(),
      avaliacao: (json['avaliacao'] ?? 0).toDouble(),
      inscrito: json['inscrito'] ?? false,
      imagemUrl: json['imgcurso']?.toString(),
      progresso: json['progresso'] ?? 0,
      sincrono: json['sincrono'], // null se não especificado
      estado: json['estado']?.toString(),
      // Novos campos
      formadorResponsavel: json['formador_responsavel']?.toString(),
      informacoes: json['informacoes']?.toString(),
      video: json['video']?.toString(),
      alertaFormador: json['alerta_formador']?.toString(),
      aprenderNoCurso: json['aprender_no_curso']?.toString(),
      requisitos: json['requisitos']?.toString(),
      publicoAlvo: json['publico_alvo']?.toString(),
      dados: json['dados']?.toString(),
      duracao: json['duracao']?.toString(),
      idioma: json['idioma']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idcurso': id,
      'titulo': titulo,
      'descricao': descricao,
      'data_inicio': dataInicio,
      'data_fim': dataFim,
      'dificuldade': dificuldade,
      'pontos': pontos,
      'tema': tema,
      'categoria': categoria,
      'avaliacao': avaliacao,
      'inscrito': inscrito,
      'imgcurso': imagemUrl,
      'progresso': progresso,
      'sincrono': sincrono,
      'estado': estado,
      // Novos campos
      'formador_responsavel': formadorResponsavel,
      'informacoes': informacoes,
      'video': video,
      'alerta_formador': alertaFormador,
      'aprender_no_curso': aprenderNoCurso,
      'requisitos': requisitos,
      'publico_alvo': publicoAlvo,
      'dados': dados,
      'duracao': duracao,
      'idioma': idioma,
    };
  }

  String get nivelDificuldade {
    switch (dificuldade.toLowerCase()) {
      case 'iniciante':
        return 'Iniciante';
      case 'intermedio':
      case 'intermediário':
      case 'intermédio': // Variação portuguesa
        return 'Intermédio';
      case 'avancado':
      case 'avançado':
        return 'Avançado';
      default:
        return 'Iniciante';
    }
  }

  Color get corDificuldade {
    switch (dificuldade.toLowerCase()) {
      case 'iniciante':
        return Colors.green;
      case 'intermedio':
      case 'intermediário':
      case 'intermédio': // Adicionar variação portuguesa
        return Colors.orange;
      case 'avancado':
      case 'avançado':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  // Getter para texto de tipo (síncrono/assíncrono)
  String get tipoTexto {
    if (sincrono == null) return 'Não especificado';
    return sincrono! ? 'Síncrono' : 'Assíncrono';
  }

  // Getter para ícone do tipo
  IconData get tipoIcone {
    if (sincrono == null) return Icons.help_outline;
    return sincrono! ? Icons.video_call : Icons.play_circle_outline;
  }

  // Getter para cor do tipo
  Color get corTipo {
    if (sincrono == null) return Colors.grey;
    return sincrono! ? Colors.blue : Colors.purple;
  }





  

  // Getter para verificar se o curso está terminado
  bool get isTerminado {
    // Verificar o campo 'estado' primeiro
    if (estado != null) {
      String estadoLower = estado!.toLowerCase().trim();
      return estadoLower == 'terminado';
    }

    // Se não há estado, verificar pela data de fim
    if (dataFim != null && dataFim!.isNotEmpty) {
      try {
        DateTime dataFimParsed = DateTime.parse(dataFim!);
        DateTime agora = DateTime.now();
        return agora.isAfter(dataFimParsed);
      } catch (e) {
        // Se houver erro no parse, assumir que não está terminado
        return false;
      }
    }

    return false;
  }

  // Getter para texto do estado do curso
  String get textoEstado {
    if (isTerminado) return 'Terminado';
    if (estado != null && estado!.isNotEmpty) return estado!;
    return 'Em andamento';
  }

  // Getter para cor do estado do curso
  Color get corEstado {
    if (isTerminado) return Colors.red;
    return Colors.green;
  }
}
