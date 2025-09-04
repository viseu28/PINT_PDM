import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:go_router/go_router.dart';
import 'package:projeto_pint/app/routes/route_names.dart';
import 'package:projeto_pint/app/models/curso_model.dart';
import 'package:projeto_pint/app/services/curso_service.dart';
import 'package:projeto_pint/app/screens/courses/curso_inscrito_page.dart';
import 'package:projeto_pint/app/widgets/notification_badge.dart';

class ProgressoPage extends StatefulWidget {
  const ProgressoPage({super.key});

  @override
  State<ProgressoPage> createState() => _ProgressoPageState();
}

class _ProgressoPageState extends State<ProgressoPage> {
  bool mostrarPorConcluir = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          const NotificationBadge(),
          IconButton(
            icon: Icon(Icons.account_circle_outlined, color: Colors.black, size: 28),
            onPressed: () => context.go('/perfil'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                mostrarPorConcluir = true;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: mostrarPorConcluir
                                    ? const Color(0xFFD6E9FA)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Text(
                                  'Por Concluir',
                                  style: TextStyle(
                                    color: mostrarPorConcluir
                                        ? Colors.black
                                        : Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                mostrarPorConcluir = false;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: !mostrarPorConcluir
                                    ? const Color(0xFFD6E9FA)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Text(
                                  'Concluido',
                                  style: TextStyle(
                                    color: !mostrarPorConcluir
                                        ? Colors.black
                                        : Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: mostrarPorConcluir
                ? _CursosPorConcluirBody()
                : _CursosConcluidosBody(),
          ),
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
        currentIndex: 0, // 0: progresso, 1: forum, 2: favoritos, 3: settings
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: ""),
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
            default:
              break;
          }
        },
      ),
    );
  }
}

class _CursosPorConcluirBody extends StatefulWidget {
  @override
  _CursosPorConcluirBodyState createState() => _CursosPorConcluirBodyState();
}

class _CursosPorConcluirBodyState extends State<_CursosPorConcluirBody> {
  List<Curso>? _cursos;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarCursos();
  }

  Future<void> _carregarCursos() async {
    setState(() => _isLoading = true);
    try {
      final cursos = await CursoService.buscarMeusCursos();
      if (mounted) {
        setState(() {
          _cursos = cursos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cursos = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    print('🔄 Pull-to-refresh ativado em Cursos Por Concluir');
    await _carregarCursos();
    print('✅ Cursos Por Concluir atualizados');
  }

  Uint8List? _decodeBase64Image(String base64String) {
    try {
      // Verifica se é uma extensão de arquivo ou string muito curta
      if (base64String.endsWith('.jpg') ||
          base64String.endsWith('.png') ||
          base64String.endsWith('.jpeg') ||
          base64String.endsWith('.gif') ||
          base64String.endsWith('.webp') ||
          base64String.length < 50) {
        return null;
      }
      
      // Remove prefixo data URL se existir
      String cleanBase64 = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;
      
      // Remove espaços em branco
      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
      
      return base64Decode(cleanBase64);
    } catch (e) {
      print('Erro ao decodificar imagem base64: $e');
      return null;
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[200]!,
            Colors.grey[300]!,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 24,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 2),
          Text(
            'Curso',
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCursoImage(String? imagemUrl) {
    // Se não há imagem, mostra placeholder
    if (imagemUrl == null || imagemUrl.isEmpty || imagemUrl.trim() == '') {
      return _buildImagePlaceholder();
    }

    // Se é URL HTTP/HTTPS
    if (imagemUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imagemUrl,
          fit: BoxFit.cover,
          width: 56,
          height: 56,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Erro ao carregar imagem da URL: $imagemUrl - $error');
            return _buildImagePlaceholder();
          },
        ),
      );
    }
    
    // Tenta decodificar como base64
    final imageData = _decodeBase64Image(imagemUrl);
    if (imageData != null && imageData.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          imageData,
          fit: BoxFit.cover,
          width: 56,
          height: 56,
          errorBuilder: (context, error, stackTrace) {
            print('Erro ao exibir imagem base64: $error');
            return _buildImagePlaceholder();
          },
        ),
      );
    }
    
    // Se nada funcionou, usa placeholder
    return _buildImagePlaceholder();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final cursos = _cursos ?? [];
    final cursosPorConcluir = cursos
        .where((c) => (c.inscrito == true) && (c.estado != 'Terminado'))
        .toList();

    if (cursosPorConcluir.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: const Center(child: Text('Nenhum curso por concluir.')),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: cursosPorConcluir.length,
        itemBuilder: (context, index) {
          final curso = cursosPorConcluir[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CursoInscritoPage(curso: curso),
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCursoImage(curso.imagemUrl),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            curso.titulo,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            curso.descricao,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Cursos concluídos
class _CursosConcluidosBody extends StatefulWidget {
  @override
  _CursosConcluidosBodyState createState() => _CursosConcluidosBodyState();
}

class _CursosConcluidosBodyState extends State<_CursosConcluidosBody> {
  List<Curso>? _cursos;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarCursos();
  }

  Future<void> _carregarCursos() async {
    setState(() => _isLoading = true);
    try {
      final cursos = await CursoService.buscarMeusCursos();
      if (mounted) {
        setState(() {
          _cursos = cursos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cursos = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    print('🔄 Pull-to-refresh ativado em Cursos Concluídos');
    await _carregarCursos();
    print('✅ Cursos Concluídos atualizados');
  }

  Uint8List? _decodeBase64Image(String base64String) {
    try {
      // Verifica se é uma extensão de arquivo ou string muito curta
      if (base64String.endsWith('.jpg') ||
          base64String.endsWith('.png') ||
          base64String.endsWith('.jpeg') ||
          base64String.endsWith('.gif') ||
          base64String.endsWith('.webp') ||
          base64String.length < 50) {
        return null;
      }
      
      // Remove prefixo data URL se existir
      String cleanBase64 = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;
      
      // Remove espaços em branco
      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
      
      return base64Decode(cleanBase64);
    } catch (e) {
      print('Erro ao decodificar imagem base64: $e');
      return null;
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[200]!,
            Colors.grey[300]!,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 24,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 2),
          Text(
            'Curso',
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCursoImage(String? imagemUrl) {
    // Se não há imagem, mostra placeholder
    if (imagemUrl == null || imagemUrl.isEmpty || imagemUrl.trim() == '') {
      return _buildImagePlaceholder();
    }

    // Se é URL HTTP/HTTPS
    if (imagemUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imagemUrl,
          fit: BoxFit.cover,
          width: 56,
          height: 56,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Erro ao carregar imagem da URL: $imagemUrl - $error');
            return _buildImagePlaceholder();
          },
        ),
      );
    }
    
    // Tenta decodificar como base64
    final imageData = _decodeBase64Image(imagemUrl);
    if (imageData != null && imageData.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          imageData,
          fit: BoxFit.cover,
          width: 56,
          height: 56,
          errorBuilder: (context, error, stackTrace) {
            print('Erro ao exibir imagem base64: $error');
            return _buildImagePlaceholder();
          },
        ),
      );
    }
    
    // Se nada funcionou, usa placeholder
    return _buildImagePlaceholder();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final cursos = _cursos ?? [];
    final cursosConcluidos = cursos
        .where((c) => (c.inscrito == true) && (c.estado == 'Terminado'))
        .toList();

    if (cursosConcluidos.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: const Center(child: Text('Nenhum curso concluído.')),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: cursosConcluidos.length,
        itemBuilder: (context, index) {
          final curso = cursosConcluidos[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CursoInscritoPage(curso: curso),
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCursoImage(curso.imagemUrl),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            curso.titulo,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            curso.descricao,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
