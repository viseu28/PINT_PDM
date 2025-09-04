import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/local_database.dart';
import '../config/api_config.dart';


class FormInscricoesService {
  static Future<double?> fetchNotaFinal(int idCurso, int userid) async {
    try {
      // Tentar buscar da API primeiro
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      
      if (token == null) {
        print('❌ Token não encontrado, tentando cache local');
        return await _fetchNotaFinalLocal(idCurso, userid);
      }

      // Usar URL dinâmica como no CursoService
      String? urlFuncionando = await _encontrarUrlFuncionando();
      if (urlFuncionando == null) {
        print('❌ Nenhuma URL funcionando, tentando cache local');
        return await _fetchNotaFinalLocal(idCurso, userid);
      }

      final url = Uri.parse('$urlFuncionando/inscricoes/curso/$idCurso/formando/$userid/nota');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout ao buscar nota final'),
      );

      print('Status code: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('Decoded JSON: $jsonData');
        final nota = (jsonData['notaFinal'] as num?)?.toDouble();
        
        // Guardar no cache local se a nota existir
        if (nota != null) {
          await LocalDatabase.upsertNotaFinal(idCurso, userid, nota);
        }
        
        return nota;
      } else {
        print('❌ Erro na API (${response.statusCode}), tentando cache local');
        return await _fetchNotaFinalLocal(idCurso, userid);
      }
    } catch (e) {
      print('❌ Erro ao buscar nota final da API: $e');
      print('🔄 Tentando cache local...');
      return await _fetchNotaFinalLocal(idCurso, userid);
    }
  }

  /// Buscar nota final do cache local
  static Future<double?> _fetchNotaFinalLocal(int idCurso, int userid) async {
    try {
      final nota = await LocalDatabase.obterNotaFinalLocal(idCurso, userid);
      if (nota != null) {
        print('✅ Nota encontrada no cache local: $nota');
        return nota;
      } else {
        print('❌ Nota não encontrada no cache local');
        return null;
      }
    } catch (e) {
      print('❌ Erro ao buscar nota do cache local: $e');
      return null;
    }
  }

  /// Encontrar URL funcionando (reutilizar lógica do CursoService)
  static Future<String?> _encontrarUrlFuncionando() async {
    final urls = [
      '${ApiConfig.baseUrl}',
      'http://10.0.2.2:3000',
      'http://localhost:3000',
    ];

    for (final url in urls) {
      try {
        final response = await http.get(
          Uri.parse('$url/health'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 3));
        
        if (response.statusCode == 200) {
          print('✅ URL funcionando: $url');
          return url;
        }
      } catch (e) {
        print('❌ URL não funcionando: $url - $e');
      }
    }
    
    return null;
  }

}