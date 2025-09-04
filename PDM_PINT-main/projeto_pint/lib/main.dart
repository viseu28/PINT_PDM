import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:projeto_pint/app/routes/app_router.dart';
import 'package:projeto_pint/app/services/notificacao_service.dart';
import 'package:projeto_pint/app/services/firebase_messaging_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Configurar handler para notificações em background
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Inicializar timezone
  tz.initializeTimeZones();
  
  // Inicializar notificações locais
  await NotificacaoService.init();
  
  // Inicializar Firebase Messaging
  await FirebaseMessagingService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SoftSkills',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      routerConfig: goRouter,
    );
  }
}

// Handler para notificações quando a app está completamente fechada
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Notificação recebida em background: ${message.notification?.title}');
}
