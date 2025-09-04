import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projeto_pint/app/models/notificacoes_model.dart';
import 'package:projeto_pint/app/services/notificacoes_service.dart';
import 'package:projeto_pint/app/services/notification_manager.dart';
import 'package:projeto_pint/app/routes/route_names.dart';

class NotificacoesPage extends StatefulWidget {
  const NotificacoesPage({super.key});

  @override
  State<NotificacoesPage> createState() => _NotificacoesPageState();
}

class _NotificacoesPageState extends State<NotificacoesPage> {
  late Future<List<NotificacaoModel>> _notificacoesFuture;
  late NotificationManager _notificationManager;

  @override
  void initState() {
    super.initState();
    _notificationManager = NotificationManager();
    _notificacoesFuture = NotificacaoService.fetchNotificacoes();
  }

  @override
  void dispose() {
    // Marcar todas as notificações como lidas quando sair da página
    _notificationManager.markAllAsRead();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0E9F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0E9F7),
        elevation: 0,
        toolbarHeight: 100,
        title: const Padding(
          padding: EdgeInsets.only(top: 16.0),
          child: Text(
            'Notificações',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Colors.black,
              size: 30,
            ),
            onPressed: () async {
              context.go('/perfil');
            }
          ),
        ],
      ),
      body: FutureBuilder<List<NotificacaoModel>>(
        future: _notificacoesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "Sem notificações.",
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            );
          }

          final notificacoes = snapshot.data!;

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  itemCount: notificacoes.length + 1,
                  itemBuilder: (context, index) {
                    if (index == notificacoes.length) {
                      return const SizedBox(height: 100);
                    }

                    final notif = notificacoes[index];
                    final dataFormatada =
                        '${notif.dataHora.day}/${notif.dataHora.month}/${notif.dataHora.year} ${notif.dataHora.hour}:${notif.dataHora.minute.toString().padLeft(2, '0')}';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          notif.descricao,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(dataFormatada),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            try {
                              await NotificacaoService.deleteNotificacao(
                                notif.id,
                              );
                              setState(() {
                                notificacoes.removeAt(index);
                              });
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao apagar notificação'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: ""),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: "",
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(RouteNames.home);
              break;
            case 1:
              context.go(RouteNames.forum);
              break;
            case 2:
              context.go(RouteNames.favoritos);
              break;
            case 3:
              context.go(RouteNames.settings);
              break;
          }
        },
      ),
    );
  }
}
