class NotificacaoModel {
  final int id;
  final int? idUtilizador;
  final String descricao;
  final DateTime dataHora;

  NotificacaoModel({
    required this.id,
    this.idUtilizador,
    required this.descricao,
    required this.dataHora,
  });

  factory NotificacaoModel.fromJson(Map<String, dynamic> json) {
    return NotificacaoModel(
      id: json['idnotificacao'],
      idUtilizador: json['idutilizador'],
      descricao: json['descricao'],
      dataHora: DateTime.parse(json['datahora']),
    );
  }
}
