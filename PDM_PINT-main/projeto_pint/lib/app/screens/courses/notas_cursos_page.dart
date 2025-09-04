import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/curso_model.dart';
import '../../services/curso_service.dart';
import '../../widgets/notification_badge.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class GradesCoursesScreen extends StatefulWidget {
  const GradesCoursesScreen({super.key});

  @override
  _GradesCoursesScreenState createState() => _GradesCoursesScreenState();
}

class _GradesCoursesScreenState extends State<GradesCoursesScreen>
    with SingleTickerProviderStateMixin {
  int? _userId;
  late TabController _tabController;
  bool _isLoading = true;
  List<Curso> _todosCursos = [];
  List<Curso> _cursosPendentes = [];
  List<Curso> _cursosConcluidos = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarDados();
    _carregarUserId();
  }

  Future<void> _carregarUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId != null) {
      setState(() => _userId = userId);
    }
  }

  Future<void> _carregarDados() async {
    try {
      final cursos = await CursoService.buscarMeusCursos();
      setState(() {
        _todosCursos = cursos;
        _cursosPendentes =
            cursos.where((c) => c.estado != 'Terminado').toList();
        _cursosConcluidos =
            cursos.where((c) => c.estado == 'Terminado').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    }
  }

  // Função para pull-to-refresh
  Future<void> _onRefresh() async {
    print('🔄 Pull-to-refresh ativado em NotasCursosPage');
    setState(() => _isLoading = true);
    await _carregarDados();
    print('✅ Notas de cursos atualizadas');
  }

  // Widget para construir a imagem do curso
  Widget _buildCourseImage(String? imagemUrl) {
    if (imagemUrl == null || imagemUrl.isEmpty) {
      return _buildImagePlaceholder();
    }

    // 1. URL do Cloudinary ou outras URLs externas
    if (imagemUrl.startsWith('http')) {
      return Image.network(
        imagemUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Erro ao carregar URL: $imagemUrl');
          return _buildImagePlaceholder();
        },
      );
    }

    // 2. Base64 (começa com data:image)
    if (imagemUrl.startsWith('data:image')) {
      final imageData = _decodeBase64Image(imagemUrl);
      if (imageData != null) {
        return Image.memory(
          imageData,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder();
          },
        );
      }
    }

    // 3. Nome de arquivo local (assets)
    if (imagemUrl.contains('.')) {
      return Image.asset(
        'assets/$imagemUrl',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          // Tentar sem prefixo assets/ caso o nome já inclua o caminho
          return Image.asset(
            imagemUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Erro ao carregar asset: $imagemUrl');
              return _buildImagePlaceholder();
            },
          );
        },
      );
    }

    // Fallback para placeholder
    return _buildImagePlaceholder();
  }

  Uint8List? _decodeBase64Image(String base64String) {
    try {
      if (base64String.endsWith('.jpg') ||
          base64String.endsWith('.png') ||
          base64String.endsWith('.jpeg') ||
          base64String.endsWith('.gif') ||
          base64String.length < 50) {
        return null;
      }
      String cleanBase64 =
          base64String.contains(',') ? base64String.split(',').last : base64String;
      return base64Decode(cleanBase64);
    } catch (e) {
      return null;
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.8),
            Colors.purple.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.school, size: 60, color: Colors.white.withOpacity(0.8)),
    );
  }

  void _abrirNotas(Curso curso, int userId) {
    debugPrint("🚀 A abrir notas com userId: $userId");
    context.push('/notas', extra: {
      'curso': curso,
      'userid': userId,
    });
  }

  Widget _buildCourseCard(Curso curso, {bool concluido = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: _buildCourseImage(curso.imagemUrl),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: curso.corDificuldade,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      curso.nivelDificuldade,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  curso.titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Formador: ${curso.formadorResponsavel ?? 'N/D'}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                if (concluido && curso.dataFim != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Conclusão: ${_formatarData(DateTime.parse(curso.dataFim!))}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: concluido && _userId != null
                            ? () => _abrirNotas(curso, _userId!)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              concluido ? Colors.blue : Colors.grey[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey[400],
                          disabledForegroundColor: Colors.white,
                        ),
                        child: Text(concluido ? 'Ver Notas' : 'Curso em Progresso'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.blue,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        indicatorWeight: 3,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timelapse, size: 18),
                SizedBox(width: 8),
                Text('Pendentes (${_cursosPendentes.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 18),
                SizedBox(width: 8),
                Text('Concluídos (${_cursosConcluidos.length})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 80,
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                fontFamily: 'Roboto',
              ),
              children: [
                TextSpan(text: 'Soft', style: TextStyle(fontWeight: FontWeight.w300)),
                TextSpan(
                  text: 'Skills',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          centerTitle: false,
          actions: [
            const NotificationBadge(),
            IconButton(
              icon: Icon(Icons.account_circle_outlined, color: Colors.black, size: 28),
              onPressed: () => context.go('/perfil'),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(48),
            child: _buildTabBar(),
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: _cursosPendentes.isEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: 400,
                                child: Center(
                                  child: Text(
                                    'Nenhum curso pendente no momento.',
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _cursosPendentes.length,
                              itemBuilder: (context, index) =>
                                  _buildCourseCard(_cursosPendentes[index]),
                            ),
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: _cursosConcluidos.isEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: 400,
                                child: Center(
                                  child: Text(
                                    'Nenhum curso concluído ainda.',
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _cursosConcluidos.length,
                              itemBuilder: (context, index) => _buildCourseCard(
                                _cursosConcluidos[index],
                                concluido: true,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey,
                spreadRadius: 1,
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey.shade400,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            elevation: 0,
            currentIndex: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: ""),
              BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), label: ""),
              BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: ""),
              BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: ""),
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
                  context.go('/configuracoes');
                  break;
              }
            },
          ),
        ),
      ),
    );
  }
}