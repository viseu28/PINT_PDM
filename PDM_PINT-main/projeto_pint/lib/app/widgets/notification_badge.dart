import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/notification_manager.dart';

class NotificationBadge extends StatefulWidget {
  final Color? iconColor;
  final double? iconSize;

  const NotificationBadge({
    super.key,
    this.iconColor = Colors.black,
    this.iconSize = 26,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  late NotificationManager _notificationManager;

  @override
  void initState() {
    super.initState();
    _notificationManager = NotificationManager();
    _notificationManager.addListener(_onNotificationCountChanged);
    
    // Carregar contagem inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _notificationManager.loadNotificationCount();
      }
    });
  }

  @override
  void dispose() {
    _notificationManager.removeListener(_onNotificationCountChanged);
    super.dispose();
  }

  void _onNotificationCountChanged() {
    // Tripla proteção contra setState após dispose
    if (!mounted) return;
    
    try {
      if (mounted) {
        setState(() {
          // Força rebuild quando a contagem muda
        });
      }
    } catch (e) {
      debugPrint('⚠️ Erro no NotificationBadge setState: $e');
    }
  }

  void _handleNotificationTap() {
    // Ir para página de notificações
    context.go('/notificacoes');
  }

  @override
  Widget build(BuildContext context) {
    final count = _notificationManager.notificationCount;
    
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_none,
            color: widget.iconColor,
            size: widget.iconSize,
          ),
          onPressed: _handleNotificationTap,
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
