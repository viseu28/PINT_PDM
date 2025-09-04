import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notificacoes_model.dart';

class NotificacaoService {
  static const String baseUrl = 'http://192.168.1.68:3000/notificacoes';

  static Future<List<NotificacaoModel>> fetchNotificacoes() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) throw Exception('Utilizador não autenticado');

    final response = await http.get(Uri.parse('$baseUrl/$userId'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => NotificacaoModel.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao carregar notificações');
    }
  }

  static Future<void> deleteNotificacao(int idNotificacao) async {
    final response = await http.delete(Uri.parse('$baseUrl/$idNotificacao'));

    if (response.statusCode != 200) {
      throw Exception('Erro ao apagar notificação');
    }
  }

  static Future<int> contarNotificacoes() async {
    final notificacoes = await fetchNotificacoes();
    return notificacoes.length;
  }
}
