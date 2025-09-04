import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:projeto_pint/app/database/local_database.dart';

class ApiService {
  static const String apiUrl = 'http://192.168.1.68:3000/cursos';

  static Future<void> descarregarCursosDaAPI() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final List<dynamic> dados = jsonDecode(response.body);

      for (var curso in dados) {
        final jaExiste = await LocalDatabase.existeCursoPorTitulo(
          curso['titulo'],
        );
        if (!jaExiste) {
          await LocalDatabase.inserirCurso(
            curso['titulo'],
            curso['descricao'],
            curso['data_inicio'],
            curso['data_fim'],
            curso['dificuldade'],
            curso['pontos'],
            curso['tema'],
            curso['estado']
          );
        }
      }

      print('Cursos carregados da API para SQLite.');
    } else {
      print('Erro ao buscar cursos da API: ${response.body}');
    }
  }

  static Future<void> enviarCursosParaAPI() async {
    final cursos = await LocalDatabase.obterCursosNaoSincronizados();

    for (var curso in cursos) {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'titulo': curso['titulo'],
          'descricao': curso['descricao'],
          'data_inicio': curso['data_inicio'],
          'data_fim': curso['data_fim'],
          'dificuldade': curso['dificuldade'],
          'pontos': curso['pontos'],
          'tema': curso['tema'],
          'estado': curso['estado'],
        }),
      );

      if (response.statusCode == 201) {
        print('Curso enviado com sucesso: ${curso['titulo']}');
        await LocalDatabase.marcarCursoComoSincronizado(curso['id']);
      } else {
        print('Erro ao enviar curso: ${response.body}');
      }
    }
  }
}
