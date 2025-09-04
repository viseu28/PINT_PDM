class ProjetoModel {
  final int idProjeto;
  final int? idUtilizador;
  final int? idCurso;
  final String nomeProjeto;
  final String? descricao;
  final String? ficheiroUrl;
  final String? ficheiroNomeOriginal;
  final DateTime? dataSubmissao;
  final bool entregue;

  ProjetoModel({
    required this.idProjeto,
    this.idUtilizador,
    this.idCurso,
    required this.nomeProjeto,
    this.descricao,
    this.ficheiroUrl,
    this.ficheiroNomeOriginal,
    this.dataSubmissao,
    required this.entregue,
  });

  factory ProjetoModel.fromJson(Map<String, dynamic> json) {
  print('🔴 RAW JSON: $json'); // Debug adicional
  
  return ProjetoModel(
    idProjeto: json['id_projeto'] ?? 0,
    idUtilizador: json['id_utilizador'],
    idCurso: json['id_curso'],
    nomeProjeto: json['nome_projeto'] ?? 'Sem nome', // Corrigido para snake_case
    descricao: json['descricao'],
    ficheiroUrl: json['ficheiro_url'], // Mantenha snake_case
    ficheiroNomeOriginal: json['ficheiro_nome_original'],
    dataSubmissao: json['data_submissao'] != null 
        ? DateTime.parse(json['data_submissao']) 
        : null,
    entregue: json['entregue'] ?? false, // Adicione este campo se existir
  );
}



  Map<String, dynamic> toJson() {
    return {
      'id_projeto': idProjeto,
      'id_utilizador': idUtilizador,
      'id_curso': idCurso,
      'nome_projeto': nomeProjeto,
      'descricao': descricao,
      'ficheiro_url': ficheiroUrl,
      'ficheiro_nome_original': ficheiroNomeOriginal,
      'data_submissao': dataSubmissao?.toIso8601String(),
    };
  }
}

class ProjetoSubmissaoModel {
  final int idSubmissao;
  final int idProjeto;
  final int idUtilizador;
  final String? ficheiroUrl;
  final String? ficheiroNomeOriginal;
  final DateTime dataSubmissao;

  ProjetoSubmissaoModel({
    required this.idSubmissao,
    required this.idProjeto,
    required this.idUtilizador,
    this.ficheiroUrl,
    this.ficheiroNomeOriginal,
    required this.dataSubmissao,
  });

  factory ProjetoSubmissaoModel.fromJson(Map<String, dynamic> json) {
    return ProjetoSubmissaoModel(
      idSubmissao: json['id_submissao'],
      idProjeto: json['id_projeto'],
      idUtilizador: json['id_utilizador'],
      ficheiroUrl: json['ficheiro_url'],
      ficheiroNomeOriginal: json['ficheiro_nome_original'],
      dataSubmissao: DateTime.parse(json['data_submissao']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_submissao': idSubmissao,
      'id_projeto': idProjeto,
      'id_utilizador': idUtilizador,
      'ficheiro_url': ficheiroUrl,
      'ficheiro_nome_original': ficheiroNomeOriginal,
      'data_submissao': dataSubmissao.toIso8601String(),
    };
  }
}
