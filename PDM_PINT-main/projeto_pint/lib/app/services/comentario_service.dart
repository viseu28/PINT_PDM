import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/comentario_model.dart';
import '../config/api_config.dart';

class ComentarioService {
  static String get baseUrl => ApiConfig.baseUrl;
  
  // Buscar comentários por curso
  static Future<List<ComentarioModel>> buscarComentariosPorCurso(int idCurso) async {
    try {
      print('🔍 Buscando comentários para curso ID: $idCurso');
      
      // Verificar se a URL está correta
      final url = '$baseUrl/comentarios/curso/$idCurso';
      print('🔗 URL da requisição: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('🌐 Status da resposta: ${response.statusCode}');
      if (response.body.length < 1000) {
        // Se a resposta for pequena, imprime completa
        print('📦 Corpo da resposta: ${response.body}');
      } else {
        // Se for grande, imprime apenas o início
        print('📦 Início da resposta: ${response.body.substring(0, 500)}...');
      }
      
      // Obter ID do usuário atual para marcar comentários próprios
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId'); // Alterado de 'user_id' para 'userId'
      print('👤 ID do usuário atual: $userId');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);
          List<dynamic> comentariosJson = [];
          
          // Verificar estrutura da resposta
          if (jsonResponse.containsKey('success')) {
            if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
              comentariosJson = jsonResponse['data'] as List<dynamic>;
              print('📊 Total de comentários no JSON: ${comentariosJson.length}');
            } else {
              print('⚠️ Resposta com success=false ou data nula');
              return [];
            }
          } else if (response.body.startsWith('[')) {
            // Caso seja array direto
            comentariosJson = json.decode(response.body) as List<dynamic>;
            print('📊 Total de comentários no array direto: ${comentariosJson.length}');
          } else {
            print('⚠️ Formato de resposta inesperado');
            print('💾 Conteúdo: ${response.body}');
            return [];
          }
          
          final comentarios = comentariosJson.map((json) {
            // Adicionar flag para identificar se o comentário pertence ao usuário atual
            final ehProprietario = userId != null && json['idutilizador'] == userId;
            
            try {
              // Converter os dados da query SQL para o formato do modelo
              return ComentarioModel(
                id: json['id'] as int,
                idcurso: json['idcurso'] as int,
                idutilizador: json['idutilizador'] as int,
                comentario: json['comentario'] as String,
                avaliacao: json['avaliacao'] != null ? 
                  (json['avaliacao'] as num).toDouble() : 0.0,
                data: DateTime.parse(json['data'] as String),
                nomeUtilizador: json['nome_utilizador'],
                avatarUtilizador: null, // Implementar quando houver avatar
                ehProprietario: ehProprietario,
                tipoUtilizador: json['tipo_utilizador'], // ✅ Agora mapeia o tipo do utilizador
              );
            } catch (e) {
              print('❌ Erro ao converter comentário: $e');
              print('💾 Dados do comentário com erro: $json');
              return null;
            }
          }).where((item) => item != null).toList().cast<ComentarioModel>();
          
          print('✅ Comentários processados com sucesso: ${comentarios.length}');
          return comentarios;
        } catch (e) {
          print('❌ Erro ao processar resposta JSON: $e');
          return [];
        }
      } else {
        print('❌ Erro na requisição HTTP: ${response.statusCode}');
        print('💾 Corpo da resposta: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Exceção no serviço: $e');
      return [];
    }
  }

  // Buscar estatísticas dos comentários de um curso
  static Future<Map<String, dynamic>?> buscarEstatisticasCurso(int idCurso) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/comentarios/estatisticas/$idCurso'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return jsonResponse['data'];
        }
      }
      
      return null;
    } catch (e) {
      print('Erro ao buscar estatísticas: $e');
      return null;
    }
  }

  // Criar novo comentário
  static Future<bool> criarComentario({
    required int idCurso,
    required int idUtilizador,
    required String comentario,
    double? avaliacao,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'idcurso': idCurso,
        'idutilizador': idUtilizador,
        'comentario': comentario,
      };
      
      if (avaliacao != null) {
        body['avaliacao'] = avaliacao;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/comentarios'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse['success'] == true;
      }
      
      print('Erro ao criar comentário: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Erro na requisição de criação: $e');
      return false;
    }
  }

  // Criar novo comentário com tratamento de erros
  static Future<Map<String, dynamic>> criarComentarioComErro({
    required int idCurso,
    required int idUtilizador,
    required String comentario,
    double? avaliacao,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'idcurso': idCurso,
        'idutilizador': idUtilizador,
        'comentario': comentario,
      };
      
      if (avaliacao != null) {
        body['avaliacao'] = avaliacao;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/comentarios'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return {
          'sucesso': jsonResponse['success'] == true,
          'mensagem': 'Comentário criado com sucesso'
        };
      } else if (response.statusCode == 403) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return {
          'sucesso': false,
          'mensagem': jsonResponse['error'] ?? 'Acesso negado'
        };
      } else {
        return {
          'sucesso': false,
          'mensagem': 'Erro ao criar comentário. Tente novamente.'
        };
      }
    } catch (e) {
      print('Erro na requisição de criação: $e');
      return {
        'sucesso': false,
        'mensagem': 'Erro de conexão. Verifique sua internet.'
      };
    }
  }

  // Atualizar um comentário existente
  static Future<bool> atualizarComentario({
    required int idComentario,
    required String novoComentario,
    double? novaAvaliacao,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'comentario': novoComentario,
      };
      
      if (novaAvaliacao != null) {
        body['avaliacao'] = novaAvaliacao;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/comentarios/$idComentario'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse['success'] == true;
      }
      
      print('Erro ao atualizar comentário: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Erro na requisição de atualização: $e');
      return false;
    }
  }

  // Atualizar comentário com tratamento de erros
  static Future<Map<String, dynamic>> atualizarComentarioComErro({
    required int idComentario,
    required String novoComentario,
    double? novaAvaliacao,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'comentario': novoComentario,
      };
      
      if (novaAvaliacao != null) {
        body['avaliacao'] = novaAvaliacao;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/comentarios/$idComentario'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return {
          'sucesso': jsonResponse['success'] == true,
          'mensagem': 'Comentário atualizado com sucesso'
        };
      } else if (response.statusCode == 403) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return {
          'sucesso': false,
          'mensagem': jsonResponse['error'] ?? 'Acesso negado'
        };
      } else if (response.statusCode == 404) {
        return {
          'sucesso': false,
          'mensagem': 'Comentário não encontrado'
        };
      } else {
        return {
          'sucesso': false,
          'mensagem': 'Erro ao atualizar comentário. Tente novamente.'
        };
      }
    } catch (e) {
      print('Erro na requisição de atualização: $e');
      return {
        'sucesso': false,
        'mensagem': 'Erro de conexão. Verifique sua internet.'
      };
    }
  }

  // Excluir um comentário
  static Future<bool> excluirComentario(int idComentario) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/comentarios/$idComentario'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse['success'] == true;
      }
      
      print('Erro ao excluir comentário: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Erro na requisição de exclusão: $e');
      return false;
    }
  }

  // Denunciar um comentário
  static Future<bool> denunciarComentario({
    required int idComentario,
    required int idUtilizador,
    required String motivo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/comentarios/$idComentario/denunciar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'idutilizador': idUtilizador,
          'motivo': motivo,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse['success'] == true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Denunciar um comentário com tratamento de erros detalhado
  static Future<Map<String, dynamic>> denunciarComentarioComErro({
    required int idComentario,
    required int idUtilizador,
    required String motivo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/comentarios/$idComentario/denunciar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'idutilizador': idUtilizador,
          'motivo': motivo,
        }),
      );

      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'sucesso': true,
          'mensagem': 'Denúncia enviada com sucesso! Nossa equipe irá analisar o comentário.'
        };
      } else if (response.statusCode == 409) {
        return {
          'sucesso': false,
          'mensagem': 'Você já denunciou este comentário anteriormente.'
        };
      } else if (response.statusCode == 403) {
        return {
          'sucesso': false,
          'mensagem': jsonResponse['error'] ?? 'Não é possível denunciar seu próprio comentário.'
        };
      } else if (response.statusCode == 404) {
        return {
          'sucesso': false,
          'mensagem': 'Comentário não encontrado.'
        };
      } else {
        return {
          'sucesso': false,
          'mensagem': jsonResponse['error'] ?? 'Erro ao enviar denúncia. Tente novamente.'
        };
      }
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro de conexão. Verifique sua internet e tente novamente.'
      };
    }
  }

  // Verificar se o utilizador já avaliou um curso
  static Future<Map<String, dynamic>?> verificarAvaliacaoExistente(
    int idCurso, 
    int idUtilizador
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/comentarios/verificar/$idCurso/$idUtilizador'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          // Se existe, retorna os dados da avaliação
          return jsonResponse['data'];
        }
      }
      
      return null; // Não tem avaliação
    } catch (e) {
      print('Erro ao verificar avaliação: $e');
      return null;
    }
  }

  // Testar conectividade com o endpoint
  static Future<bool> testarConectividade() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/comentarios/test'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erro no teste de conectividade: $e');
      return false;
    }
  }
}
