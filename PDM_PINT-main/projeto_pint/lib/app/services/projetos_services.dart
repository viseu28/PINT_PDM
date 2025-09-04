import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/projetos_model.dart';
import '../config/api_config.dart';

class ProjetoService {
  static String get baseUrl => '${ApiConfig.baseUrl}/projetos';

  // Busca todos os projetos
  static Future<List<ProjetoModel>> fetchProjetos() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ProjetoModel.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao carregar projetos');
    }
  }

  // Busca submissões de um projeto específico
  static Future<List<ProjetoSubmissaoModel>> fetchSubmissoesPorProjeto(int idProjeto) async {
    final response = await http.get(Uri.parse('$baseUrl/$idProjeto/submissoes'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ProjetoSubmissaoModel.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao carregar submissões do projeto');
    }
  }

  // Busca projetos por curso
static Future<List<ProjetoModel>> fetchProjetosPorCurso(int idCurso, int userid) async {
  print("🧪 DEBUG fetchProjetosPorCurso: idCurso=$idCurso, userid=$userid");

  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/projetos/curso/$idCurso/formando/$userid'),
  );

  print('🔵 RAW RESPONSE: ${response.body}'); // Adicione esta linha

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    print('🟢 PARSED DATA: $data'); // E esta linha
    return data.map((json) => ProjetoModel.fromJson(json)).toList();
  } else {
    throw Exception('Erro ao carregar projetos');
  }
}





  // Busca submissões por curso e utilizador
  static Future<List<ProjetoSubmissaoModel>> fetchSubmissoesPorCursoEUtilizador(int cursoId, int utilizadorId) async {
    final url = '${ApiConfig.baseUrl}/projetos_submissoes?curso_id=$cursoId&utilizador_id=$utilizadorId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ProjetoSubmissaoModel.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao carregar submissões do curso e utilizador');
    }
  }
}
