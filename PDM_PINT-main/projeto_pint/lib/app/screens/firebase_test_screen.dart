import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projeto_pint/app/services/firebase_messaging_service.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String? fcmToken;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getFCMToken();
  }

  Future<void> _getFCMToken() async {
    try {
      final token = await FirebaseMessagingService.getToken();
      setState(() {
        fcmToken = token;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        fcmToken = 'Erro ao obter token: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _copyToken() async {
    if (fcmToken != null) {
      await Clipboard.setData(ClipboardData(text: fcmToken!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token copiado para área de transferência!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _subscribeToTestTopic() async {
    try {
      await FirebaseMessagingService.subscribeToTopic('test_notifications');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscrito no tópico "test_notifications"!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao inscrever no tópico: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste Firebase'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase Cloud Messaging',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Token FCM
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Token FCM:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      SelectableText(
                        fcmToken ?? 'Token não disponível',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    const SizedBox(height: 10),
                    if (!isLoading && fcmToken != null)
                      ElevatedButton.icon(
                        onPressed: _copyToken,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copiar Token'),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Botões de teste
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Testes:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _subscribeToTestTopic,
                        child: const Text('Inscrever em Tópico de Teste'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _getFCMToken,
                        child: const Text('Atualizar Token'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Instruções
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Como testar:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '1. Copie o token FCM acima\n'
                      '2. Vá para Firebase Console > Cloud Messaging\n'
                      '3. Clique em "Send your first message"\n'
                      '4. Cole o token no campo "FCM registration token"\n'
                      '5. Envie a notificação de teste',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
