import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/link_model.dart';
import '../../config/api_config.dart';

class LinkService {
  static const String baseUrl = '${ApiConfig.baseUrl}/cursos';

  // Busca links por curso
  static Future<List<LinkModel>> fetchLinksPorCurso(int idCurso) async {
    print("🔗 DEBUG fetchLinksPorCurso: idCurso=$idCurso");

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$idCurso/links'),
      );

      print('🔵 RAW RESPONSE Links: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('🟢 PARSED DATA Links: $data');
        
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> linksData = data['data'];
          return linksData.map((json) => LinkModel.fromJson(json)).toList();
        } else {
          print('⚠️ Resposta sem sucesso ou sem dados');
          return [];
        }
      } else {
        print('❌ Erro HTTP: ${response.statusCode}');
        throw Exception('Erro ao carregar links do curso: ${response.statusCode}');
      }
    } catch (error) {
      print('❌ Erro ao buscar links: $error');
      throw Exception('Erro ao carregar links do curso: $error');
    }
  }
}
