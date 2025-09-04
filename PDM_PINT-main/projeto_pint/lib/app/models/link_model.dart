class LinkModel {
  final int id;
  final String titulo;
  final String? descricao;
  final String url;
  final int cursoId;
  final int? aulaId;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;
  final bool estado;

  LinkModel({
    required this.id,
    required this.titulo,
    this.descricao,
    required this.url,
    required this.cursoId,
    this.aulaId,
    this.criadoEm,
    this.atualizadoEm,
    required this.estado,
  });

  factory LinkModel.fromJson(Map<String, dynamic> json) {
    return LinkModel(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? 'Link sem título',
      descricao: json['descricao'],
      url: json['url'] ?? '',
      cursoId: json['curso_id'] ?? 0,
      aulaId: json['aula_id'],
      criadoEm: json['criado_em'] != null ? DateTime.parse(json['criado_em']) : null,
      atualizadoEm: json['atualizado_em'] != null ? DateTime.parse(json['atualizado_em']) : null,
      estado: json['estado'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'url': url,
      'curso_id': cursoId,
      'aula_id': aulaId,
      'criado_em': criadoEm?.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
      'estado': estado,
    };
  }
}
