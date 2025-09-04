import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/route_names.dart';
import '../../models/curso_model.dart';
import '../../models/projetos_model.dart';
import '../../services/projetos_services.dart';
import '../../services/form_inscricoes.dart';
import '../../database/local_database.dart';

class GradesScreen extends StatefulWidget {
  final Curso curso;
  final int userid;

  const GradesScreen({Key? key, required this.curso, required this.userid})
      : super(key: key);

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  bool isLoading = true;
  int notificacoes = 0;
  List<ProjetoModel> projetos = [];
  double? notaFinal; // Variável para guardar a nota final

  @override
  void initState() {
    super.initState();
    _loadProjetos();
    _loadNotaFinal(); // Busca a nota final ao iniciar
  }

  Future<void> _loadProjetos() async {
    final int? idCurso = widget.curso.id;

    if (idCurso == null) {
      debugPrint("ID do curso está nulo.");
      setState(() => isLoading = false);
      return;
    }

    final int? userid = widget.userid;

    if (userid == null) {
      debugPrint("ID do formando está nulo.");
      setState(() => isLoading = false);
      return;
    }

    try {
      final data = await ProjetoService.fetchProjetosPorCurso(
        idCurso,
        userid,
      );
      debugPrint('Projetos recebidos: ${data.length}');

      setState(() {
        projetos = data;
      });
    } catch (e) {
      debugPrint("Erro ao buscar projetos: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

    Future<void> _loadNotaFinal() async {
    final idCurso = widget.curso.id;
    final userid = widget.userid;

    if (idCurso == null) {
      debugPrint("❌ ID do curso está nulo");
      return;
    }

    try {
      debugPrint("🔄 Iniciando busca da nota final para curso $idCurso, utilizador $userid");
      
      // Primeiro, verificar se já existe no cache local
      final notaLocal = await LocalDatabase.obterNotaFinalLocal(idCurso, userid);
      debugPrint("🔍 Verificação local inicial: $notaLocal");
      
      if (notaLocal != null) {
        debugPrint("✅ Nota encontrada no cache local: $notaLocal");
        setState(() {
          notaFinal = notaLocal;
        });
        return;
      }
      
      // Se não existe local, tentar buscar da API
      final nota = await FormInscricoesService.fetchNotaFinal(idCurso, userid);
      debugPrint('✅ Nota final recebida da API: $nota');
      
      setState(() {
        notaFinal = nota;
      });
      
      if (nota == null) {
        debugPrint("⚠️ Nota final não encontrada (pode estar offline ou não ter nota)");
      }
    } catch (e) {
      debugPrint("❌ Erro ao buscar nota final: $e");
      // Mesmo com erro, tentar buscar do cache local diretamente
      try {
        final notaLocal = await LocalDatabase.obterNotaFinalLocal(idCurso, userid);
        debugPrint("🔄 Tentativa de busca local direta: $notaLocal");
        setState(() {
          notaFinal = notaLocal;
        });
      } catch (localError) {
        debugPrint("❌ Erro ao buscar nota local: $localError");
      }
    }
  }


  Uint8List? _decodeBase64Image(String base64String) {
    try {
      if (base64String.endsWith('.jpg') ||
          base64String.endsWith('.png') ||
          base64String.endsWith('.jpeg') ||
          base64String.endsWith('.gif') ||
          base64String.length < 50) return null;

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
      height: 180,
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

  Widget _buildCourseImage() {
    final imagemUrl = widget.curso.imagemUrl;

    if (imagemUrl == null || imagemUrl.isEmpty) return _buildImagePlaceholder();

    final base64Image = _decodeBase64Image(imagemUrl);
    if (base64Image != null) {
      return Image.memory(
        base64Image,
        fit: BoxFit.cover,
        height: 180,
        width: double.infinity,
      );
    }

    if (imagemUrl.startsWith('http')) {
      return Image.network(
        imagemUrl,
        fit: BoxFit.cover,
        height: 180,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
      );
    }

    return Image.asset(
      imagemUrl,
      fit: BoxFit.cover,
      height: 180,
      width: double.infinity,
      errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Detalhes do Curso',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade700,
                Colors.blue.shade500,
                Colors.blue.shade300,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _buildBodyContent(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey.shade400,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 4,
        currentIndex: 3,
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
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: ""),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: "",
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'A carregar dados...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final dataFim = widget.curso.dataFim != null
        ? DateTime.tryParse(widget.curso.dataFim!)
        : null;
    final formador = widget.curso.formadorResponsavel ?? 'N/D';

    String formattedData = 'Data não disponível';
    if (dataFim != null) {
      formattedData =
          '${dataFim.day.toString().padLeft(2, '0')}/${dataFim.month.toString().padLeft(2, '0')}/${dataFim.year}';
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header com imagem e informações básicas
          _buildCourseHeader(formattedData, formador),
          
          // Informações detalhadas
          _buildDetailedInfo(),
          
          // Projetos
          _buildProjectsSection(),
          
          // Nota Final
          _buildFinalGradeSection(),
          
          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCourseHeader(String formattedData, String formador) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade600,
            Colors.blue.shade400,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Imagem do curso
          Container(
            height: 120,
            width: double.infinity,
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildCourseImage(),
            ),
          ),
          
          // Título do curso
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.curso.titulo,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          SizedBox(height: 6),
          
          // Subtítulo com data
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                SizedBox(width: 6),
                Text(
                  'Concluído em $formattedData',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDetailedInfo() {
    final formador = widget.curso.formadorResponsavel ?? 'N/D';
    
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações do Curso',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          
          _buildModernInfoRow(
            icon: Icons.school,
            label: 'ID do Curso',
            value: widget.curso.id.toString(),
            color: Colors.blue,
          ),
          
          _buildModernInfoRow(
            icon: Icons.person,
            label: 'Formador',
            value: formador,
            color: Colors.green,
          ),
          
          _buildModernInfoRow(
            icon: Icons.star,
            label: 'Dificuldade',
            value: widget.curso.dificuldade,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.assignment,
                  color: Colors.indigo,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Projetos Realizados',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${projetos.length}',
                  style: TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          if (projetos.isEmpty)
            _buildEmptyProjects()
          else
            ...projetos.map((projeto) => _buildProjectCard(projeto)).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyProjects() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 12),
          Text(
            'Nenhum projeto encontrado',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Este curso não possui projetos registados.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(ProjetoModel projeto) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.folder,
                  color: Colors.blue,
                  size: 18,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  projeto.nomeProjeto,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Concluído',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (projeto.descricao != null && projeto.descricao!.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              projeto.descricao!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinalGradeSection() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notaFinal != null ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: notaFinal != null 
                      ? Colors.green.withOpacity(0.1) 
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  notaFinal != null ? Icons.grade : Icons.help_outline,
                  color: notaFinal != null ? Colors.green.shade700 : Colors.grey.shade600,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nota Final',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    if (notaFinal == null) ...[
                      SizedBox(height: 4),
                      Text(
                        'Nota não disponível',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          if (notaFinal != null) ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    notaFinal!.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'valores',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Nota final',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 32,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Nota não disponível',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Esta nota ainda não foi registada',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          
          SizedBox(height: 16),
          
          // Botão para tentar recarregar
          if (notaFinal == null)
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  debugPrint("🔄 Tentando recarregar nota final...");
                  _loadNotaFinal();
                },
                icon: Icon(Icons.refresh, size: 18),
                label: Text('Tentar novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

}