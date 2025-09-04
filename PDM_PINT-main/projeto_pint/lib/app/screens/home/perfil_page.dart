import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/curso_service.dart';
import '../../models/user_model.dart';
import '../../models/curso_model.dart';


class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  _PerfilPageState createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  UserModel? currentUser;
  bool isLoading = true;
  List<Curso> meusCursos = [];
  bool cursosLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadMeusCursos();
  }

  Future<void> _loadUserData() async {
    print('🔍 PerfilPage: Carregando dados do utilizador...');
    try {
      final user = await AuthService.getCurrentUser();
      print('✅ PerfilPage: Utilizador carregado - ID: ${user?.id}, Nome: ${user?.nome}');
      setState(() {
        currentUser = user;
        isLoading = false;
      });
    } catch (e) {
      print('❌ PerfilPage: Erro ao carregar dados do usuário: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados do usuário')),
      );
    }
  }

  Future<void> _loadMeusCursos() async {
    print('🔍 PerfilPage: Iniciando carregamento de meus cursos...');
    try {
      final cursos = await CursoService.buscarMeusCursos();
      print('✅ PerfilPage: Recebidos ${cursos.length} cursos do serviço');
      
      setState(() {
        meusCursos = cursos;
        cursosLoading = false;
      });
      
      if (cursos.isEmpty) {
        print('⚠️ PerfilPage: Lista de cursos está vazia');
      } else {
        print('📚 PerfilPage: Cursos carregados:');
        for (int i = 0; i < cursos.length; i++) {
          print('  ${i + 1}. ${cursos[i].titulo} (ID: ${cursos[i].id})');
        }
      }
    } catch (e) {
      print('❌ PerfilPage: Erro ao carregar meus cursos: $e');
      setState(() {
        cursosLoading = false;
      });
    }
  }

  void _logout() async {
    // Chama o método de logout da AuthService
    await AuthService.logout();
    // Após o logout, redireciona o utilizador para a tela de login
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
          title: Text(
            'Meu Perfil',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 1,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final String userName = currentUser?.nome ?? 'Usuário';
    final String userInitial = currentUser?.iniciais ?? '?';

    return Scaffold(
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
        title: Text(
          'Meu Perfil',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              context.go('/settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      userInitial,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    userName,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalhes do utilizador',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(),
                    _buildDetailRow(
                      Icons.person_outline,
                      'ID do utilizador:',
                      currentUser?.id.toString() ?? 'Não disponível',
                    ),
                    _buildDetailRow(
                      Icons.email,
                      'Endereço de email:',
                      currentUser?.email ?? 'Não disponível',
                    ),
                    _buildDetailRow(
                      Icons.cake,
                      'Data de nascimento:',
                      currentUser?.dataNascimento ?? 'Não disponível',
                    ),
                    _buildDetailRow(
                      Icons.home,
                      'Morada:',
                      currentUser?.morada ?? 'Não disponível',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.star, color: Colors.amber),
                    title: Text('Pontos obtidos'),
                    trailing: Chip(
                      label: Text('${currentUser?.pontos ?? 0} pontos'),
                      backgroundColor: Colors.amber.shade100,
                      labelStyle: TextStyle(
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.calendar_today, color: Colors.green),
                      title: Text('Calendário'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // TODO: Implementar navegação para página do calendário
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Funcionalidade em desenvolvimento')),
                        );
                      },
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.school, color: Colors.purple),
                      title: Text('Percurso Formativo'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        if (currentUser != null) {
                          context.push('/percurso-formativo/${currentUser!.id}');
                        }
                      },
                    ),
                ],
              ),
            ),
            SizedBox(height: 16),         
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cursos Inscritos',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            context.go('/meus-cursos');
                          },
                          child: Text(
                            'Ver todos',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    SizedBox(height: 8),
                    _buildCursosInscritos(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.grey.shade400,
        unselectedItemColor: Colors.grey.shade400,
        showSelectedLabels: false,
        elevation: 0,
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
              context.go('/home');
              break;
            case 1:
              context.go('/forum');
              break;
            case 2:
              context.go('/favoritos');
              break;
            case 3:
              context.go('/settings');
              break;
            default:
              break;
          }
        },
      ),
    );
  }

  Widget _buildCursosInscritos() {
    print('🔍 PerfilPage: _buildCursosInscritos chamado');
    print('📊 cursosLoading: $cursosLoading, meusCursos.length: ${meusCursos.length}');
    
    if (cursosLoading) {
      print('⏳ PerfilPage: Mostrando loading...');
      return SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (meusCursos.isEmpty) {
      print('⚠️ PerfilPage: Lista vazia, mostrando mensagem de "nenhum curso"');
      return Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.school_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhum curso inscrito',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Explore os cursos disponíveis e comece sua jornada de aprendizado!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    print('✅ PerfilPage: Mostrando ${meusCursos.length} cursos na UI');
    return SizedBox(
      height: 200, // Altura fixa como no protótipo
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: meusCursos.length,
        itemBuilder: (context, index) {
          final curso = meusCursos[index];
          return Container(
            width: 140, // Largura de cada card
            margin: EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Abrindo curso: ${curso.titulo}'),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Container da imagem do curso
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          // Tentar carregar a imagem real, se falhar, usar gradiente
                          curso.imagemUrl != null
                              ? Image.network(
                                  curso.imagemUrl!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildGradientContainer(curso);
                                  },
                                )
                              : _buildGradientContainer(curso),
                          // Overlay escuro para melhorar a legibilidade
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  // Título do curso
                  Text(
                    curso.titulo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  // Subtítulo
                  Text(
                    'Inscrito',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGradientContainer(Curso curso) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCourseColor(curso.categoria ?? 'Tecnologia').withOpacity(0.8),
            _getCourseColor(curso.categoria ?? 'Tecnologia'),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _getIconForCourse(curso.titulo),
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _getCourseColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'programação':
        return Colors.blue;
      case 'design':
        return Colors.purple;
      case 'marketing':
        return Colors.green;
      case 'finanças':
        return Colors.orange;
      default:
        return Colors.indigo;
    }
  }

  IconData _getIconForCourse(String titulo) {
    if (titulo.toLowerCase().contains('html') || titulo.toLowerCase().contains('css')) {
      return Icons.web;
    } else if (titulo.toLowerCase().contains('python')) {
      return Icons.code;
    } else if (titulo.toLowerCase().contains('desenvolvimento')) {
      return Icons.developer_mode;
    } else {
      return Icons.school;
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}