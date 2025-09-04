import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projeto_pint/app/services/auth_service.dart';
import 'package:projeto_pint/app/routes/route_names.dart';
import '../../models/user_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  UserModel? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthService.getCurrentUser();
      setState(() {
        currentUser = user;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados do usuário')),
      );
    }
  }

  void _logout() async {
    await AuthService.logout();
    if (mounted) {
      context.go('/login');
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Logout'),
          content: Text('Você tem certeza que deseja sair da conta?'),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                context.pop();
              },
            ),
            TextButton(
              child: Text(
                'Sair',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                context.pop();
                _logout();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F1FA),
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Definições',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final String userName = currentUser?.nome ?? 'Utilizador';
    final String userInitial = currentUser?.iniciais ?? '?';
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1FA),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop(); // Volta para a página anterior
            } else {
              context.go('/home'); // Só vai para home se não há página anterior
            }
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Definições',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          // Cabeçalho com avatar e nome
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  userInitial,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              title: Text(
                'Olá, $userName!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              subtitle: Text(
                'Conta pessoal',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Secção Conta
          Text(
            'Conta',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            child: Column(
              children: [
                _buildSettingsItem(
                  Icons.person_outline,
                  'Dados pessoais',
                  () {},
                ),
                _buildSettingsItem(
                  Icons.lock_outline,
                  'Alterar password',
                  () {
                    context.push('/alterar-password');
                  },
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade300, thickness: 2),
          // Secção Privacidade
          const SizedBox(height: 16),
          Text(
            'Privacidade',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            child: Column(
              children: [
                _buildSettingsItem(Icons.security, 'Segurança', () {}),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade300, thickness: 2),
          // Secção Ajuda
          const SizedBox(height: 16),
          Text(
            'Ajuda',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            child: Column(
              children: [
                _buildSettingsItem(
                  Icons.headset_mic_outlined,
                  'Suporte',
                  () {},
                ),
                _buildSettingsItem(Icons.help_outline, 'Sobre Nós', () {}),
                _buildSettingsItem(Icons.feedback_outlined, 'Feedback', () {}),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade300, thickness: 2),
          // Secção Sobre
          const SizedBox(height: 16),
          Text(
            'Sobre',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            child: Column(
              children: [
                _buildSettingsItem(Icons.info_outline, 'Versão', () {}),
              ],
            ),
          ),
          const SizedBox(height: 35),
          // Botão de logout destacado
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                _showLogoutDialog();
              },
              icon: Icon(Icons.logout, color: Colors.white),
              label: const Text('Terminar sessão'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 35),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey.shade400,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        currentIndex: 3,
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
              // Já está na página de definições
              break;
            default:
              break;
          }
        },
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: Colors.blue, size: 24),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      minLeadingWidth: 0,
    );
  }
}
