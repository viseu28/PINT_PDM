import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'notificacoes_service.dart';

class NotificationManager extends ChangeNotifier {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  int _notificationCount = 0;
  bool _isLoading = false;

  int get notificationCount => _notificationCount;
  bool get isLoading => _isLoading;

  /// Carrega a contagem de notificações do servidor
  Future<void> loadNotificationCount() async {
    if (_isLoading) return;

    _isLoading = true;
    _safeNotifyListeners();

    try {
      final count = await NotificacaoService.contarNotificacoes();
      _notificationCount = count;
      debugPrint('📱 Notificações carregadas: $_notificationCount');
    } catch (e) {
      debugPrint('❌ Erro ao carregar notificações: $e');
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Marca todas as notificações como lidas (zera o badge)
  void markAllAsRead() {
    _notificationCount = 0;
    debugPrint('✅ Notificações marcadas como lidas');
    _safeNotifyListeners();
  }

  /// Adiciona uma nova notificação (quando receber via push)
  void addNotification() {
    _notificationCount++;
    debugPrint('🔔 Nova notificação recebida. Total: $_notificationCount');
    _safeNotifyListeners();
  }

  /// Remove uma notificação (quando apagar uma notificação específica)
  void removeNotification() {
    if (_notificationCount > 0) {
      _notificationCount--;
      debugPrint('🗑️ Notificação removida. Total: $_notificationCount');
      _safeNotifyListeners();
    }
  }

  /// Força a atualização da contagem
  Future<void> refresh() async {
    await loadNotificationCount();
  }

  /// Notifica listeners de forma segura
  void _safeNotifyListeners() {
    try {
      if (hasListeners) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (hasListeners) {
            notifyListeners();
          }
        });
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao notificar listeners: $e');
    }
  }
}
