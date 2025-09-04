import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../models/user_model.dart';
import 'firebase_messaging_service.dart';

class AuthService {
  // Configurações de URL - ajuste conforme necessário:
  // - Para emulador Android: 10.0.2.2:3000
  // - Para dispositivo físico na mesma rede: IP da máquina (ex: 192.168.1.68:3000)
  // - Para teste local: localhost:3000
  static const String baseUrl = 'http://192.168.1.68:3000';
  static const String apiUrl = '$baseUrl/utilizadores/login';
  static const String userApiUrl = '$baseUrl/utilizadores';
  static const Duration timeout = Duration(seconds: 5);

  //--------------------------------  CHECK IF USER IS LOGGED IN ------------------------------
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final hasToken = prefs.getString('jwt_token') != null;
    final isMarkedLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!hasToken || !isMarkedLoggedIn) {
      return false;
    }

    // Verifica se o token é válido
    final tokenValid = await isTokenValid();

    if (!tokenValid) {
      await logout();
      return false;
    }

    return true;
  }

  //--------------------------------  LOGIN ------------------------------
  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    try {
      debugPrint('🔍 Tentando login para: $email');
      
      // Testar conectividade primeiro
      final workingUrl = await testConnectivity();
      if (workingUrl == null) {
        throw 'Não foi possível conectar ao servidor. Verifique se o servidor está funcionando.';
      }
      
      final loginUrl = '$workingUrl/utilizadores/login';
      debugPrint('🌐 URL da API encontrada: $loginUrl');
      
      final body = jsonEncode({'email': email, 'senha': password});
      debugPrint('📤 Enviando dados: $body');
      
      final response = await http
          .post(
            Uri.parse(loginUrl),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(
            timeout,
            onTimeout: () {
              debugPrint('⏰ Timeout na conexão');
              throw TimeoutException(
                'A conexão demorou muito tempo. Por favor, tente novamente.',
              );
            },
          );

      debugPrint('📥 Status da resposta: ${response.statusCode}');
      debugPrint('📥 Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('jwt_token', data['token']);
        await prefs.setBool('isLoggedIn', true);

        final utilizador = data['utilizador'];
        await prefs.setString('userName', utilizador['nome']);
        await prefs.setInt('userId', utilizador['idutilizador']);
        await prefs.setString('userEmail', utilizador['email']);
        await prefs.setBool('temQueAlterarPassword', utilizador['temquealterarpassword'] ?? false);

        if (utilizador['datanascimento'] != null) {
          await prefs.setString('userBirthDate', utilizador['datanascimento']);
        }
        if (utilizador['morada'] != null) {
          await prefs.setString('userAddress', utilizador['morada']);
        }
        if (utilizador['pontos'] != null) {
          await prefs.setInt('userPoints', utilizador['pontos']);
        }

        debugPrint('✅ Login successful with JWT token');
        
        // 🔥 FIREBASE: Atualizar o utilizador ativo e enviar token FCM
        try {
          await FirebaseMessagingService.setCurrentUser(utilizador['idutilizador'].toString());
          debugPrint('🔔 Token FCM associado ao utilizador ${utilizador['idutilizador']}');
        } catch (e) {
          debugPrint('⚠️ Erro ao associar token FCM: $e');
          // Não falhar o login por causa do token FCM
        }
        
        return data;
      } else {
        debugPrint('❌ Erro HTTP: ${response.statusCode}');
        final error = jsonDecode(response.body);
        debugPrint('❌ Erro da API: ${error['erro']}');
        throw error['erro'] ?? 'Erro ao fazer login';
      }
    } on TimeoutException catch (e) {
      debugPrint('⏰ Timeout Exception: $e');
      rethrow;
    } catch (e) {
      debugPrint('❌ Login error: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('ClientException')) {
        throw 'Erro de conexão. Verifique se o servidor está funcionando e se o endereço está correto.';
      }
      throw 'Erro ao conectar com o servidor. Por favor, tente novamente.';
    }
  }

  //--------------------------------  Verifiy Token ------------------------------
  static Future<bool> isTokenValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        return false;
      }

      // Tenta fazer uma chamda a API com o token
      final response = await http
          .get(
            Uri.parse('$userApiUrl/verify'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Token verification failed: $e');
      return false;
    }
  }

  //------------------------------  LOGOUT  ------------------------------
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 🔥 FIREBASE: Limpar token FCM do servidor
    try {
      await FirebaseMessagingService.clearToken();
      debugPrint('🔔 Token FCM removido do servidor');
    } catch (e) {
      debugPrint('⚠️ Erro ao remover token FCM: $e');
      // Não falhar o logout por causa do token FCM
    }
    
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('jwt_token');
    await prefs.remove('userName');
    await prefs.remove('userId');
    await prefs.remove('userEmail');
    await prefs.remove('userBirthDate');
    await prefs.remove('userAddress');
    await prefs.remove('userPoints');
    debugPrint('Logout completo - token removido');
  }

  //--------------------------------  GET CURRENT USER DATA ------------------------------
  // busca os dados do utilizador que está logado
  static Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final userName = prefs.getString('userName');

      if (userId != null && userName != null) {
        // Verifica se tem dados completos no SharedPreferences
        final userEmail = prefs.getString('userEmail');
        final userBirthDate = prefs.getString('userBirthDate');
        final userAddress = prefs.getString('userAddress');

        // Se não tem dados completos, vai buscar à API
        if (userEmail == null || userEmail == 'por implementar') {
          debugPrint('Buscando dados completos do usuário da API...');
          final completeUser = await getUserDetails(userId);
          if (completeUser != null) {
            // Guarda os dados completos localmente para próxima vez
            await updateUserPreferences(completeUser);
            return completeUser;
          }
        }

        // Retorna dados do SharedPreferences (podem estar incompletos)
        return UserModel(
          id: userId,
          nome: userName,
          email: userEmail ?? 'Não disponível',
          dataNascimento: userBirthDate,
          morada: userAddress,
          pontos: prefs.getInt('userPoints') ?? 0,
          temQueAlterarPassword: prefs.getBool('temQueAlterarPassword') ?? false,
        );
      }

      return null;
    } catch (e) {
      debugPrint('Erro ao obter dados do usuário: $e');
      return null;
    }
  }

  //--------------------------------  GET USER DETAILS FROM API ------------------------------
  static Future<UserModel?> getUserDetails(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        debugPrint('No JWT token found');
        return null;
      }

      final response = await http
          .get(
            Uri.parse('$userApiUrl/$userId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Dados recebidos da API com token: $data');
        return UserModel.fromJson(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('Token inválido, fazendo logout automático');
        await logout();
        return null;
      } else {
        debugPrint(
          'Erro ao buscar detalhes do usuário: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Erro ao conectar com o servidor: $e');
      return null;
    }
  }

  //--------------------------------  UPDATE USER DATA IN PREFERENCES ------------------------------
  // guarda informações localmente no telemóvel (SharedPreferences)
  static Future<void> updateUserPreferences(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', user.nome);
    await prefs.setString('userEmail', user.email);
    await prefs.setInt('userPoints', user.pontos);
    await prefs.setBool('temQueAlterarPassword', user.temQueAlterarPassword);
    if (user.dataNascimento != null) {
      await prefs.setString('userBirthDate', user.dataNascimento!);
    }
    if (user.morada != null) {
      await prefs.setString('userAddress', user.morada!);
    }
  }

  //--------------------------------  ALTERAR PASSWORD ------------------------------
  static Future<bool> alterarPassword({
    required String passwordAtual,
    required String novaPassword,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw 'Utilizador não autenticado';
      }

      final response = await http.put(
        Uri.parse('$userApiUrl/alterar-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'passwordAtual': passwordAtual,
          'novaPassword': novaPassword,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Password alterada com sucesso');
        
        // Se era primeira alteração, atualizar dados do utilizador
        if (data['primeiraAlteracao'] == true) {
          final currentUser = await getCurrentUser();
          if (currentUser != null) {
            final updatedUser = UserModel(
              id: currentUser.id,
              nome: currentUser.nome,
              email: currentUser.email,
              dataNascimento: currentUser.dataNascimento,
              morada: currentUser.morada,
              pontos: currentUser.pontos,
              temQueAlterarPassword: false,
            );
            await updateUserPreferences(updatedUser);
          }
        }
        
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw error['erro'] ?? 'Erro desconhecido';
      }
    } catch (e) {
      debugPrint('❌ Erro ao alterar password: $e');
      rethrow;
    }
  }

  //--------------------------------  TEST CONNECTIVITY ------------------------------
  static Future<String?> testConnectivity() async {
    final testUrls = [
      'http://192.168.1.68:3000',
      'http://192.168.1.68:3000',
      'http://192.168.1.68:3000',
      'http://127.0.0.1:3000',
    ];

    for (String url in testUrls) {
      try {
        debugPrint('🔍 Testando conectividade com: $url');
        final response = await http
            .get(Uri.parse(url))
            .timeout(Duration(seconds: 3));
        
        if (response.statusCode == 200) {
          debugPrint('✅ Conectividade OK com: $url');
          return url;
        }
      } catch (e) {
        debugPrint('❌ Falha em: $url - $e');
      }
    }
    return null;
  }
}


/*
O updateUserPreferences() guarda dados simples no sistema operativo, 
não na tua base de dados SQLite. São duas coisas diferentes que trabalham juntas! 

Quando usar cada um:
SharedPreferences para:
✅ Nome do utilizador logado
✅ Estado de login
✅ Configurações da app
✅ Última sincronização

SQLite para:
✅ Lista de cursos
✅ Histórico de inscrições
✅ Dados que precisam de consultas
✅ Relações entre tabelas
*/