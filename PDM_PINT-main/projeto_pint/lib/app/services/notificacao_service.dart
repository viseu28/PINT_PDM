import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificacaoService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notifications.initialize(initializationSettings);
  }

  // Notificação para lembrete de aula
  static Future<void> agendarLembreteAula({
    required int id,
    required String tituloAula,
    required String nomeCurso,
    required DateTime dataHora,
  }) async {
    await _notifications.zonedSchedule(
      id,
      'Lembrete de Aula 📚',
      'Aula "$tituloAula" do curso "$nomeCurso" em 15 minutos!',
      tz.TZDateTime.from(dataHora.subtract(const Duration(minutes: 15)), tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'aulas_channel',
          'Lembretes de Aulas',
          channelDescription: 'Notificações para lembretes de aulas',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Notificação para deadline de entrega
  static Future<void> agendarLembreteDeadline({
    required int id,
    required String tituloTarefa,
    required String nomeCurso,
    required DateTime deadline,
  }) async {
    // Lembrete 1 dia antes
    await _notifications.zonedSchedule(
      id,
      'Deadline Aproximando! ⏰',
      'Tarefa "$tituloTarefa" do curso "$nomeCurso" vence amanhã!',
      tz.TZDateTime.from(deadline.subtract(const Duration(days: 1)), tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'deadlines_channel',
          'Lembretes de Deadlines',
          channelDescription: 'Notificações para deadlines de tarefas',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    // Lembrete 2 horas antes
    await _notifications.zonedSchedule(
      id + 1000, // ID diferente
      'Deadline Hoje! 🚨',
      'Tarefa "$tituloTarefa" vence em 2 horas!',
      tz.TZDateTime.from(deadline.subtract(const Duration(hours: 2)), tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'deadlines_urgent_channel',
          'Deadlines Urgentes',
          channelDescription: 'Notificações urgentes de deadlines',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Notificação para motivação diária
  static Future<void> agendarMotivacaoDiaria() async {
    await _notifications.zonedSchedule(
      9999, // ID fixo para motivação
      'Hora de Estudar! 🎓',
      'Que tal continuar seus estudos? Seu futuro agradece!',
      _proximoHorario(19, 0), // 19:00 todos os dias
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'motivacao_channel',
          'Motivação Diária',
          channelDescription: 'Mensagens motivacionais diárias',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Notificação para novo conteúdo
  static Future<void> notificarNovoConteudo({
    required String tipoConteudo,
    required String titulo,
    required String nomeCurso,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Novo Conteúdo Disponível! 🆕',
      '$tipoConteudo "$titulo" foi adicionado ao curso "$nomeCurso"',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'conteudo_channel',
          'Novo Conteúdo',
          channelDescription: 'Notificações de novo conteúdo disponível',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  // Notificação para streak de estudos
  static Future<void> notificarStreak(int diasConsecutivos) async {
    String emoji = '';
    String mensagem = '';
    
    if (diasConsecutivos >= 30) {
      emoji = '🏆';
      mensagem = 'Incrível! $diasConsecutivos dias seguidos estudando!';
    } else if (diasConsecutivos >= 7) {
      emoji = '🔥';
      mensagem = 'Parabéns! $diasConsecutivos dias de streak!';
    } else {
      emoji = '⭐';
      mensagem = 'Ótimo! $diasConsecutivos dias seguidos!';
    }

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Streak Mantido! $emoji',
      mensagem,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_channel',
          'Streak de Estudos',
          channelDescription: 'Notificações para streak de estudos',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  // Função auxiliar para calcular próximo horário
  static tz.TZDateTime _proximoHorario(int hora, int minuto) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hora, minuto);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  // Cancelar notificação específica
  static Future<void> cancelarNotificacao(int id) async {
    await _notifications.cancel(id);
  }

  // Cancelar todas as notificações
  static Future<void> cancelarTodasNotificacoes() async {
    await _notifications.cancelAll();
  }

  // Método genérico para mostrar notificações (usado pelo Firebase)
  static Future<void> mostrarNotificacao({
    required int id,
    required String titulo,
    required String corpo,
    String? payload,
  }) async {
    await _notifications.show(
      id,
      titulo,
      corpo,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'firebase_channel',
          'Notificações Push',
          channelDescription: 'Notificações recebidas via Firebase',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }
}

// Configurações de notificação do utilizador
class ConfiguracoesNotificacao {
  bool aulaLembretes;
  bool deadlineLembretes;
  bool motivacaoDiaria;
  bool novoConteudo;
  bool streakNotificacao;
  TimeOfDay horarioMotivacao;

  ConfiguracoesNotificacao({
    this.aulaLembretes = true,
    this.deadlineLembretes = true,
    this.motivacaoDiaria = true,
    this.novoConteudo = true,
    this.streakNotificacao = true,
    this.horarioMotivacao = const TimeOfDay(hour: 19, minute: 0),
  });

  Map<String, dynamic> toJson() {
    return {
      'aulaLembretes': aulaLembretes,
      'deadlineLembretes': deadlineLembretes,
      'motivacaoDiaria': motivacaoDiaria,
      'novoConteudo': novoConteudo,
      'streakNotificacao': streakNotificacao,
      'horarioMotivacao': '${horarioMotivacao.hour}:${horarioMotivacao.minute}',
    };
  }

  factory ConfiguracoesNotificacao.fromJson(Map<String, dynamic> json) {
    final horario = json['horarioMotivacao']?.split(':') ?? ['19', '0'];
    return ConfiguracoesNotificacao(
      aulaLembretes: json['aulaLembretes'] ?? true,
      deadlineLembretes: json['deadlineLembretes'] ?? true,
      motivacaoDiaria: json['motivacaoDiaria'] ?? true,
      novoConteudo: json['novoConteudo'] ?? true,
      streakNotificacao: json['streakNotificacao'] ?? true,
      horarioMotivacao: TimeOfDay(
        hour: int.parse(horario[0]),
        minute: int.parse(horario[1]),
      ),
    );
  }
}
