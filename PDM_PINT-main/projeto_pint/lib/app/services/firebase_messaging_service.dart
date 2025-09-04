import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_pint/app/services/notificacao_service.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static String? _token;
  static String? _currentUserId;

  static String get apiBaseUrl => '${ApiConfig.baseUrl}'; // IP da API (mesmo do AuthService)

  // Inicializar o serviço de notificações Firebase
  static Future<void> initialize() async {
    try {
      // Solicitar permissão para notificações
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('Permissão de notificação: ${settings.authorizationStatus}');
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Permissões de notificação concedidas');
        
        // Obter token FCM
        await _getToken();
        
        // Configurar handlers de mensagens
        _setupMessageHandlers();
        
        // Escutar mudanças no token
        _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
        
      } else {
        print('❌ Permissões de notificação negadas');
      }
    } catch (e) {
      print('❌ Erro ao inicializar Firebase Messaging: $e');
    }
  }

  static Future<void> _getToken() async {
    try {
      _token = await _firebaseMessaging.getToken();
      if (_token != null) {
        if (kDebugMode) {
          print('🔑 Token FCM obtido: ${_token!.substring(0, 20)}...');
        }
        await _enviarTokenParaServidor(_token!);
      }
    } catch (e) {
      print('❌ Erro ao obter token FCM: $e');
    }
  }

  static Future<void> _onTokenRefresh(String newToken) async {
    print('🔄 Token FCM atualizado');
    _token = newToken;
    await _enviarTokenParaServidor(newToken);
  }

  static Future<void> _enviarTokenParaServidor(String token) async {
    try {
      // Obter ID do utilizador das preferências
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId') ?? prefs.getInt('id_utilizador') ?? prefs.getInt('idutilizador');
      
      if (userId == null) {
        print('! ID do utilizador não encontrado, token FCM não será enviado');
        return;
      }

      _currentUserId = userId.toString();
      
      final response = await http.post(
        Uri.parse('$apiBaseUrl/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'utilizador_id': userId,
          'fcm_token': token,
        }),
      );

      if (response.statusCode == 200) {
        print('🔔 Token FCM associado ao utilizador $userId');
      } else {
        print('❌ Erro ao enviar token FCM: ${response.statusCode}');
        print('📄 Resposta: ${response.body}');
      }
    } catch (e) {
      print('❌ Erro ao enviar token FCM para servidor: $e');
    }
  }

  // Configurar os handlers para diferentes estados da app
  static void _setupMessageHandlers() {
    // Quando a app está em foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Notificação recebida em foreground: ${message.notification?.title}');
      }
      
      // Mostrar notificação local quando a app está aberta
      _showLocalNotification(message);
    });

    // Quando o usuário toca numa notificação (app estava em background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Notificação aberta: ${message.notification?.title}');
      }
      
      // Navegar para tela específica baseada nos dados da notificação
      _handleNotificationTap(message);
    });

    // Verificar se a app foi aberta através de uma notificação
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print('App aberta através de notificação: ${message.notification?.title}');
        }
        _handleNotificationTap(message);
      }
    });
  }

  // Mostrar notificação local quando a app está em foreground
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    await NotificacaoService.mostrarNotificacao(
      id: message.hashCode,
      titulo: message.notification?.title ?? 'Nova notificação',
      corpo: message.notification?.body ?? '',
      payload: jsonEncode(message.data),
    );
  }

  // Lidar com o toque numa notificação
  static void _handleNotificationTap(RemoteMessage message) {
    // Aqui você pode implementar navegação baseada nos dados da notificação
    final data = message.data;
    final tipo = data['tipo'];
    
    switch (tipo) {
      case 'novo_material':
        final idCurso = data['idCurso'];
        print('📚 Navegar para curso $idCurso - novo material');
        // Implementar navegação para curso específico
        break;
      case 'alteracao_formador':
        final idCurso = data['idCurso'];
        print('👨‍� Navegar para curso $idCurso - formador alterado');
        // Implementar navegação para curso específico
        break;
      case 'alteracao_datas':
        final idCurso = data['idCurso'];
        print('📅 Navegar para curso $idCurso - datas alteradas');
        // Implementar navegação para curso específico
        break;
      case 'alteracao_estado':
        final idCurso = data['idCurso'];
        print('📢 Navegar para curso $idCurso - estado alterado');
        // Implementar navegação para curso específico
        break;
      case 'alteracao_informacoes':
        final idCurso = data['idCurso'];
        print('� Navegar para curso $idCurso - informações atualizadas');
        // Implementar navegação para curso específico
        break;
      case 'denuncia':
        print('⚠️ Navegar para notificações');
        // Implementar navegação para notificações
        break;
      case 'resposta_forum':
        print('💬 Navegar para fórum');
        // Implementar navegação para fórum
        break;
      default:
        if (data.containsKey('screen')) {
          // Navegar para tela específica
          final screen = data['screen'];
          if (kDebugMode) {
            print('Navegar para: $screen');
          }
          // Implementar navegação aqui
        }
        print('📱 Tipo de notificação desconhecido: $tipo');
    }
  }

  // Obter o token atual do dispositivo
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Método para atualizar o utilizador ativo
  static Future<void> setCurrentUser(String userId) async {
    _currentUserId = userId;
    if (_token != null) {
      await _enviarTokenParaServidor(_token!);
    }
  }

  // Método para limpar o token quando utilizador faz logout
  static Future<void> clearToken() async {
    try {
      if (_currentUserId != null) {
        final response = await http.delete(
          Uri.parse('$apiBaseUrl/fcm-token/$_currentUserId'),
        );
        
        if (response.statusCode == 200) {
          print('✅ Token FCM removido do servidor');
        }
      }
      
      _token = null;
      _currentUserId = null;
    } catch (e) {
      print('❌ Erro ao limpar token FCM: $e');
    }
  }

  // Inscrever-se num tópico
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    if (kDebugMode) {
      print('Inscrito no tópico: $topic');
    }
  }

  // Cancelar inscrição num tópico
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    if (kDebugMode) {
      print('Inscrição cancelada do tópico: $topic');
    }
  }
}

// Handler para notificações quando a app está completamente fechada
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Notificação recebida em background: ${message.notification?.title}');
  }
}
