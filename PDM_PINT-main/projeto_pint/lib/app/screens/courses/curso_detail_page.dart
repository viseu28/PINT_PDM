import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:go_router/go_router.dart';
import '../../models/curso_model.dart';
import '../../services/curso_service.dart';
import '../../components/comentarios_section_v2.dart';
import '../video/video_player_page.dart';
import 'curso_inscrito_page.dart';

class CursoDetailPage extends StatefulWidget {
  final Curso curso;

  const CursoDetailPage({super.key, required this.curso});

  @override
  State<CursoDetailPage> createState() => _CursoDetailPageState();
}

class _CursoDetailPageState extends State<CursoDetailPage> {
  late ScrollController _scrollController;
  bool _showAppBarTitle = false;

  // Estatísticas dinâmicas do curso
  Map<String, dynamic>? _estatisticasCurso;

  // Módulos dinâmicos do curso
  List<Map<String, dynamic>> _modulosCurso = [];
  bool _carregandoModulos = true;

  // Estado do favorito e inscrição
  bool _isFavorito = false;
  bool _carregandoFavorito = true;
  bool _isInscrito = false;
  bool _carregandoInscricao = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // 🐛 DEBUG: Verificar dados do curso
    print('🔍 CURSO DEBUG - ${widget.curso.titulo}:');
    print('   ID: ${widget.curso.id}');
    print('   Título: ${widget.curso.titulo}');
    print('   Formador RAW: "${widget.curso.formadorResponsavel}"');
    print('   Formador é null? ${widget.curso.formadorResponsavel == null}');
    print('   Formador é vazio? ${widget.curso.formadorResponsavel?.isEmpty}');
    print(
      '   Formador após trim: "${widget.curso.formadorResponsavel?.trim()}"',
    );

    // Verificar se tem formador válido
    final bool temFormador =
        widget.curso.formadorResponsavel != null &&
        widget.curso.formadorResponsavel!.trim().isNotEmpty;
    print('   🎯 TEM FORMADOR? $temFormador');

    _carregarDadosDinamicos();
    _verificarFavorito();
    _verificarInscricao();
  }

  Future<void> _carregarDadosDinamicos() async {
    if (widget.curso.id != null) {
      // Carregar estatísticas e módulos em paralelo
      await Future.wait([_carregarEstatisticas(), _carregarModulos()]);
    } else {
      setState(() {
        _carregandoModulos = false;
      });
    }
  }

  // Função para pull-to-refresh - recarrega todos os dados
  Future<void> _onRefresh() async {
    print('🔄 Pull-to-refresh ativado em CursoDetailPage');
    
    // Recarregar todos os dados em paralelo
    await Future.wait([
      _carregarDadosDinamicos(),
      _verificarFavorito(),
      _verificarInscricao(),
    ]);
    
    print('✅ Dados atualizados com sucesso');
  }

  Future<void> _carregarEstatisticas() async {
    if (widget.curso.id == null) {
      print('❌ ID do curso é null, não é possível carregar estatísticas');
      return;
    }

    final estatisticas = await CursoService.buscarEstatisticasCurso(
      widget.curso.id!,
    );

    // Debug das estatísticas recebidas
    print('📊 Estatísticas recebidas para o curso ${widget.curso.id}:');
    if (estatisticas != null) {
      print('   Total inscritos: ${estatisticas['total_inscritos']}');
      print('   Total comentários: ${estatisticas['total_comentarios']}');
      print('   Avaliação média: ${estatisticas['avaliacao_media']}');
      print('   Última atualização: ${estatisticas['ultima_atualizacao']}');
      print(
        '   Tipo da última atualização: ${estatisticas['ultima_atualizacao']?.runtimeType}',
      );
    } else {
      print('❌ Nenhuma estatística retornada');
    }

    if (mounted) {
      setState(() {
        _estatisticasCurso = estatisticas;
      });
    }
  }

  Future<void> _carregarModulos() async {
    if (widget.curso.id == null) {
      print('❌ ID do curso é null, não é possível carregar módulos');
      if (mounted) {
        setState(() {
          _modulosCurso = [];
          _carregandoModulos = false;
        });
      }
      return;
    }

    final modulos = await CursoService.buscarModulosCurso(widget.curso.id!);
    if (mounted) {
      setState(() {
        _modulosCurso = modulos;
        _carregandoModulos = false;
      });
    }
  }

  void _onScroll() {
    // Mostrar titulo no AppBar quando scroll > 200px
    final showTitle = _scrollController.offset > 200;
    if (showTitle != _showAppBarTitle) {
      setState(() {
        _showAppBarTitle = showTitle;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: _showAppBarTitle ? Colors.white : Colors.transparent,
      foregroundColor: _showAppBarTitle ? Colors.black87 : Colors.white,
      title: AnimatedOpacity(
        opacity: _showAppBarTitle ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          widget.curso.titulo,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      actions: [_buildFavoriteButton()],
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(), // Permite scroll mesmo com pouco conteúdo
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TODO: CourseHeader widget
            _buildTemporaryHeader(),

            const SizedBox(height: 16),

            // TODO: CourseInfoSection widget
            _buildTemporaryInfoSection(),

            const SizedBox(height: 16),

            // TODO: CourseDescriptionSection widget
            _buildTemporaryDescriptionSection(),

            const SizedBox(height: 16),

            // NOVA: Seção Público Alvo (como container separado)
            if (widget.curso.publicoAlvo != null &&
                widget.curso.publicoAlvo!.isNotEmpty) ...[
              _buildPublicoAlvoSection(),
              const SizedBox(height: 16),
            ],

            // Seção de Comentários
            _buildCommentsSection(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // Widgets temporários para testar a estrutura
  Widget _buildTemporaryHeader() {
    return _buildCourseHeader();
  }

  Widget _buildCourseHeader() {
    return Container(
      height: 280,
      decoration: BoxDecoration(gradient: _getSimpleGradient()),
      child: Stack(
        children: [
          // Imagem do curso (se disponível)
          if (widget.curso.imagemUrl != null &&
              widget.curso.imagemUrl!.isNotEmpty)
            _buildCourseImage()
          else
            _buildSimpleDecoration(),

          // Overlay suave para legibilidade
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.6),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Título do curso
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.curso.titulo,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.curso.tema ?? 'Curso de Tecnologia',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleDecoration() {
    // Decoração simples quando não há imagem
    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Center(
        child: Icon(
          Icons.school,
          size: 100,
          color: Colors.white.withOpacity(0.1),
        ),
      ),
    );
  }

  LinearGradient _getSimpleGradient() {
    // Gradient simples e elegante - azul profundo
    return const LinearGradient(
      colors: [
        Color(0xFF1E3A8A), // Azul profundo
        Color(0xFF3B82F6), // Azul mais claro
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Widget _buildCourseImage() {
    final imageUrl = widget.curso.imagemUrl;

    // Verificação de segurança adicional
    if (imageUrl == null || imageUrl.isEmpty) {
      print('⚠️ imagemUrl é null ou vazio, retornando padrão decorativo');
      return _buildDecorativePattern();
    }

    // Verificar se é uma URL ou nome de arquivo
    if (imageUrl.startsWith('http') ||
        imageUrl.contains('.jpg') ||
        imageUrl.contains('.png') ||
        imageUrl.contains('.jpeg')) {
      // Caso seja um nome de arquivo ou URL, exibir usando Image.network ou Image.asset
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child:
            imageUrl.startsWith('http')
                ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('❌ Erro ao carregar imagem da URL: $error');
                    return _buildDecorativePattern();
                  },
                )
                : _buildAssetImage(imageUrl),
      );
    }
    // Se não for URL/arquivo, tentar como Base64
    else {
      try {
        final imageBytes = _decodeBase64Image(imageUrl);
        return SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Erro ao carregar imagem Base64: $error');
              return _buildDecorativePattern();
            },
          ),
        );
      } catch (e) {
        print('⚠️ Falha ao processar imagem do curso: $e');
        return _buildDecorativePattern();
      }
    }
  }

  Widget _buildAssetImage(String imageName) {
    // Tenta carregar a imagem de diversos caminhos potenciais de assets
    final List<String> possiblePaths = [
      'assets/$imageName',
      'assets/images/$imageName',
      'assets/cursos/$imageName',
      imageName,
    ];

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Image.asset(
        possiblePaths.first, // Tenta o primeiro caminho
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Erro ao carregar imagem do asset: $error');
          return _buildDecorativePattern();
        },
      ),
    );
  }

  Widget _buildDecorativePattern() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Padrão decorativo com ícones
          Positioned(
            top: 50,
            right: 30,
            child: Icon(
              Icons.code,
              size: 60,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Positioned(
            top: 120,
            left: 20,
            child: Icon(
              Icons.web,
              size: 40,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Positioned(
            bottom: 100,
            right: 50,
            child: Icon(
              Icons.design_services,
              size: 50,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Positioned(
            bottom: 150,
            left: 40,
            child: Icon(
              Icons.palette,
              size: 35,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  String _getEstimatedDuration() {
    // Usar duração real da BD se disponível
    if (widget.curso.duracao != null && widget.curso.duracao!.isNotEmpty) {
      return widget.curso.duracao!;
    }

    // Fallback para lógica anterior (caso não esteja preenchido na BD)
    if (widget.curso.nivelDificuldade.toLowerCase().contains('iniciante')) {
      return '2-4h';
    } else if (widget.curso.nivelDificuldade.toLowerCase().contains(
      'intermédio',
    )) {
      return '4-8h';
    } else {
      return '8-12h';
    }
  }

  Uint8List _decodeBase64Image(String imageStr) {
    try {
      // Verificar se é uma string Base64 ou um nome de arquivo
      if (imageStr.contains('/') ||
          imageStr.contains('.jpg') ||
          imageStr.contains('.png') ||
          imageStr.contains('.jpeg')) {
        // Se for um nome de arquivo, lançar uma exceção para tratar como fallback
        throw FormatException(
          'Isso é um nome de arquivo, não uma string Base64',
        );
      }

      // Limpar a string Base64 se tiver prefixo de data URL
      String cleanBase64 = imageStr;
      if (imageStr.startsWith('data:image')) {
        cleanBase64 = imageStr.split(',').last;
      }

      // Verificar se a string é um Base64 válido antes de decodificar
      // Base64 válido deve ter comprimento múltiplo de 4 e conter apenas caracteres válidos
      final validBase64Regex = RegExp(r'^[A-Za-z0-9+/=]+$');
      if (!validBase64Regex.hasMatch(cleanBase64) ||
          cleanBase64.length % 4 != 0) {
        throw FormatException('String não é um Base64 válido');
      }

      return base64Decode(cleanBase64);
    } catch (e) {
      // Em caso de erro, registrar no console e relançar para tratamento no widget
      print('❌ Erro ao decodificar imagem: $e');
      print('📋 Valor tentando decodificar: "$imageStr"');
      rethrow;
    }
  }

  Widget _buildTemporaryInfoSection() {
    return _buildCourseInfoSection();
  }

  Widget _buildCourseInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          // Header da seção
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Informações do Curso',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Grid de informações (inclui agora o card do formador)
          Padding(padding: const EdgeInsets.all(20), child: _buildInfoGrid()),

          // Estatísticas do curso
          const Divider(height: 1),
          _buildCourseStats(),

          // Pré-requisitos (se houver)
          if (_hasPrerequisites()) ...[
            const Divider(height: 1),
            _buildPrerequisites(),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    // 6 cards: 3 linhas x 2 colunas
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.language,
                title: 'Idioma',
                value: 'Português',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.schedule,
                title: 'Duração',
                value: _getEstimatedDuration(),
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: widget.curso.tipoIcone,
                title: 'Modalidade',
                value: widget.curso.tipoTexto,
                color: widget.curso.corTipo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.school,
                title: 'Nível',
                value: widget.curso.nivelDificuldade,
                color: _getDifficultyColor(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.stars,
                title: 'Pontos',
                value: '${widget.curso.pontos} pts',
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.update,
                title: 'Atualizado',
                value: _getLastUpdateText(),
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Card do Formador Responsável ocupa as duas colunas, mesma altura dos outros
        Row(children: [Expanded(child: _buildInstructorInfoCard())]),
      ],
    );
  }

  // Card reutilizável para informações do curso
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      height:
          96, // Altura fixa para cards compactos, ajustada para evitar overflow
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Primeira linha: ícone + título
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Segunda linha: valor principal
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 2,
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorInfoCard() {
    final bool temFormador =
        widget.curso.formadorResponsavel != null &&
        widget.curso.formadorResponsavel!.trim().isNotEmpty;
    final String nomeFormador =
        temFormador
            ? widget.curso.formadorResponsavel!
            : 'De momento, não há formador responsável';

    return Container(
      width: double.infinity,
      height: 96, // Mesma altura dos outros cards
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Primeira linha: ícone + título
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  temFormador ? Icons.person : Icons.person_outline,
                  color: temFormador ? Colors.blue[600] : Colors.grey[500],
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Formador Responsável',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Segunda linha: nome do formador
          Text(
            nomeFormador,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: temFormador ? Colors.black87 : Colors.grey[600],
            ),
            maxLines: 2,
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseStats() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estatísticas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.people,
                  value: _getEnrolledStudents(),
                  label: 'Inscritos',
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle,
                  value: _getCompletionRate(),
                  label: 'Taxa de Conclusão',
                  color: Colors.green,
                ),
              ),
              if (_getAvaliacaoMedia() != null && _getAvaliacaoMedia()! > 0)
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.star,
                    value: _getAvaliacaoMedia()!.toStringAsFixed(1),
                    label: 'Avaliação',
                    color: Colors.orange,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPrerequisites() {
    final prerequisites = _getPrerequisites();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Pré-requisitos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...prerequisites
              .map(
                (prereq) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.orange[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          prereq,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              ,
        ],
      ),
    );
  }

  Widget _buildTemporaryDescriptionSection() {
    return _buildCourseDescriptionSection();
  }

  Widget _buildCourseDescriptionSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          // Header da seção
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.school, // Ícone de educação/diploma
                    color: Colors.blue[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Este Curso inclui',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Conteúdo do que o curso inclui
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildCursoIncluiContent(),
          ),

          const Divider(height: 1),

          // O que vai aprender
          _buildLearningObjectives(),

          const Divider(height: 1),

          // Estrutura do curso
          _buildCourseStructure(),

          // Vídeo do curso (se disponível)
          if (widget.curso.video != null && widget.curso.video!.isNotEmpty) ...[
            const Divider(height: 1),
            _buildVideoSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildLearningObjectives() {
    final objectives = _getLearningObjectives();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.purple[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'O que vai aprender',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...objectives.asMap().entries.map((entry) {
            final index = entry.key;
            final objective = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      objective,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCourseStructure() {
    // Usar módulos dinâmicos se carregados, senão mostrar loading ou vazio
    final modules =
        _carregandoModulos
            ? []
            : _modulosCurso
                .map(
                  (m) => {
                    'title':
                        m['titulo'] ??
                        m['title'] ??
                        m['nome'] ??
                        'Módulo ${_modulosCurso.indexOf(m) + 1}',
                    'description':
                        m['descricao'] ??
                        m['description'] ??
                        'Conteúdo do módulo',
                  },
                )
                .toList();

    if (_carregandoModulos) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.layers, color: Colors.orange[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Estrutura do Curso',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          ],
        ),
      );
    }

    if (modules.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.layers, color: Colors.orange[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Estrutura do Curso',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                'Sem módulos disponíveis',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.layers, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Estrutura do Curso',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '${modules.length} módulos',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...modules.asMap().entries.map((entry) {
            final index = entry.key;
            final module = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[100]!, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module['title'] as String,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (module['description'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            module['description'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.play_circle_outline,
                    color: Colors.orange[600],
                    size: 20,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPublicoAlvoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          // Header da seção
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.people, color: Colors.teal[600], size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Público Alvo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Conteúdo do público alvo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildPublicoAlvoContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicoAlvoContent() {
    final publicoAlvo = widget.curso.publicoAlvo;

    // Verificação de segurança adicional
    if (publicoAlvo == null || publicoAlvo.isEmpty) {
      return const Text(
        'Informação não disponível',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Se contém marcadores (bullets, números, etc.), dividir em lista
    if (publicoAlvo.contains('•') ||
        publicoAlvo.contains('-') ||
        publicoAlvo.contains('\n')) {
      final items =
          publicoAlvo
              .split(RegExp(r'[•\n-]|(?:\d+\.)|(?:\*\s)'))
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty && item.length > 3)
              .toList();

      if (items.length > 1) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Colors.teal[600],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
        );
      }
    }

    // Se é texto corrido, mostrar normalmente
    return Text(
      publicoAlvo,
      style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
    );
  }

  // NOVA SEÇÃO: Este Curso inclui

  Widget _buildCursoIncluiContent() {
    final dados = widget.curso.dados;

    // Verificação de segurança adicional
    if (dados == null || dados.isEmpty) {
      return const Text(
        'Informação não disponível',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Se contém marcadores (bullets, números, etc.), dividir em lista
    if (dados.contains('•') ||
        dados.contains('-') ||
        dados.contains('\n') ||
        dados.contains('✓')) {
      final items =
          dados
              .split(RegExp(r'[•\n-✓]|(?:\d+\.)|(?:\*\s)'))
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty && item.length > 3)
              .toList();

      if (items.length > 1) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        );
      }
    }

    // Se é texto corrido, mostrar normalmente sem ícone
    return Text(
      dados,
      style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
    );
  }

  void _playVideo(String videoUrl) {
    if (videoUrl.isEmpty || videoUrl == 'null') {
      // Se não houver URL válida, mostrar uma mensagem
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text('Vídeo não disponível'),
              ],
            ),
            content: const Text(
              'Este curso não possui um vídeo de apresentação disponível no momento.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      );
      return;
    }

    // Se for URL do YouTube, extrair ID do vídeo e abrir na página de reprodução
    if (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => VideoPlayerPage(
                videoUrl: videoUrl,
                title: widget.curso.titulo,
              ),
        ),
      );
    } else {
      // Se for outro tipo de URL de vídeo, também abrir na página de reprodução
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => VideoPlayerPage(
                videoUrl: videoUrl,
                title: widget.curso.titulo,
              ),
        ),
      );
    }
  }

  // Método para selecionar um ícone apropriado baseado no conteúdo do item
  // Método _getIconForItem foi removido pois não é mais utilizado

  // Métodos auxiliares em falta
  String _getProgressMessage(int progress) {
    if (progress == 0) {
      return 'Ainda não iniciou o curso';
    } else if (progress < 25) {
      return 'Começou bem! Continue assim.';
    } else if (progress < 50) {
      return 'A meio caminho! Está indo bem.';
    } else if (progress < 75) {
      return 'Quase lá! Mantenha o ritmo.';
    } else if (progress < 100) {
      return 'Quase a terminar! Último esforço.';
    } else {
      return 'Parabéns! Curso concluído.';
    }
  }

  Color _getDifficultyColor() {
    return widget.curso.corDificuldade;
  }

  String _getLastUpdateText() {
    // Usar a data de última atualização das estatísticas
    if (_estatisticasCurso != null &&
        _estatisticasCurso!['ultima_atualizacao'] != null) {
      try {
        final dataStr = _estatisticasCurso!['ultima_atualizacao'].toString();
        final data = DateTime.parse(dataStr);

        // Formatação simples da data (DD/MM/AAAA)
        final dia = data.day.toString().padLeft(2, '0');
        final mes = data.month.toString().padLeft(2, '0');
        final ano = data.year.toString();
        return '$dia/$mes/$ano';
      } catch (e) {
        print('❌ Erro ao processar data de atualização: $e');
        print(
          '💾 Valor original: ${_estatisticasCurso!['ultima_atualizacao']}',
        );
      }
    }

    // Fallback para o caso de não haver data
    return 'Recentemente';
  }

  String _getEnrolledStudents() {
    if (_estatisticasCurso != null &&
        _estatisticasCurso!['total_inscritos'] != null) {
      final totalInscritos = _estatisticasCurso!['total_inscritos'] as int;

      if (totalInscritos > 1000) {
        // Formata para '1.2k' etc.
        return '${(totalInscritos / 1000).toStringAsFixed(1).replaceAll('.0', '')}k';
      } else {
        return totalInscritos.toString();
      }
    }
    // Se não tiver dado, pode mostrar um loading ou zero
    return '0';
  }

  String _getCompletionRate() {
    final taxa = _estatisticasCurso?['taxa_conclusao'];

    // Se for null (não há dados na API), mostrar 'N/A'
    if (taxa == null) return 'N/A';

    // Se for 0, ou qualquer outro número válido, mostrar com 1 casa decimal
    return '${(taxa as num).toStringAsFixed(1)}%';
  }

  bool _hasPrerequisites() {
    // Verificar se há requisitos nas novas colunas ou baseado no nível
    if (widget.curso.requisitos != null &&
        widget.curso.requisitos!.isNotEmpty) {
      return true;
    }
    return !widget.curso.nivelDificuldade.toLowerCase().contains('iniciante');
  }

  List<String> _getPrerequisites() {
    // Usar requisitos da nova coluna se disponível
    if (widget.curso.requisitos != null &&
        widget.curso.requisitos!.isNotEmpty) {
      // Dividir por marcadores comuns (pontos, vírgulas, quebras de linha, bullet points)
      return widget.curso.requisitos!
          .split(RegExp(r'[•\n-]|(?:\d+\.)|(?:\*\s)'))
          .map((req) => req.trim())
          .where((req) => req.isNotEmpty && req.length > 3)
          .take(6) // Limitar a 6 requisitos
          .toList();
    }

    // Fallback para lógica anterior
    final titulo = widget.curso.titulo.toLowerCase();

    if (titulo.contains('front') ||
        titulo.contains('html') ||
        titulo.contains('css')) {
      return [
        'Conhecimento básico de computação',
        'Familiaridade com navegadores web',
        'Motivação para aprender programação',
      ];
    } else if (titulo.contains('python')) {
      return [
        'Conhecimento básico de computação',
        'Lógica de programação (recomendado)',
        'Conhecimento básico de matemática',
      ];
    } else {
      return [
        'Conhecimento básico de informática',
        'Interesse pela área de estudo',
      ];
    }
  }

  List<String> _getLearningObjectives() {
    // Usar conteúdo da nova coluna se disponível
    if (widget.curso.aprenderNoCurso != null &&
        widget.curso.aprenderNoCurso!.isNotEmpty) {
      // Dividir por marcadores comuns (pontos, vírgulas, quebras de linha, bullet points)
      return widget.curso.aprenderNoCurso!
          .split(RegExp(r'[•\n-]|(?:\d+\.)|(?:\*\s)'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty && item.length > 3)
          .take(8) // Limitar a 8 objetivos
          .toList();
    }

    // Fallback para lógica anterior
    final titulo = widget.curso.titulo.toLowerCase();

    if (titulo.contains('front') ||
        titulo.contains('html') ||
        titulo.contains('css')) {
      return [
        'Entender os fundamentos do desenvolvimento web',
        'Criar páginas HTML estruturadas',
        'Estilizar páginas com CSS',
        'Implementar layouts responsivos',
      ];
    } else if (titulo.contains('python')) {
      return [
        'Dominar conceitos básicos de programação em Python',
        'Trabalhar com estruturas de dados e algoritmos',
        'Desenvolver pequenas aplicações funcionais',
        'Automatizar tarefas com scripts Python',
      ];
    } else {
      return [
        'Adquirir conhecimentos essenciais na área',
        'Desenvolver habilidades práticas para aplicação imediata',
        'Preparar-se para os desafios profissionais do mercado',
        'Obter certificação reconhecida',
      ];
    }
  }

  Widget _buildVideoSection() {
    final bool hasVideo =
        widget.curso.video != null &&
        widget.curso.video!.isNotEmpty &&
        widget.curso.video != 'null';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_circle_filled, color: Colors.red[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Vídeo de Apresentação',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (hasVideo)
            InkWell(
              onTap: () => _playVideo(widget.curso.video ?? ''),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Thumbnail do vídeo ou imagem genérica
                    ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Container(
                        color: Colors.black45,
                        width: double.infinity,
                        height: double.infinity,
                        child:
                            widget.curso.imagemUrl != null &&
                                    widget.curso.imagemUrl!.isNotEmpty
                                ? _getThumbnailImage(widget.curso.imagemUrl!)
                                : const Icon(
                                  Icons.video_library,
                                  size: 64,
                                  color: Colors.white38,
                                ),
                      ),
                    ),

                    // Ícone de play sobreposto
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Column(
                children: [
                  Icon(Icons.videocam_off, color: Colors.grey[500], size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Nenhum vídeo disponível para este curso',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Método auxiliar para obter a imagem de thumbnail adequada
  Widget _getThumbnailImage(String imageSource) {
    if (imageSource.startsWith('http')) {
      // Se for URL
      return Image.network(
        imageSource,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => const Icon(
              Icons.video_library,
              size: 64,
              color: Colors.white38,
            ),
      );
    } else if (imageSource.contains('.jpg') ||
        imageSource.contains('.png') ||
        imageSource.contains('.jpeg')) {
      // Se for nome de arquivo
      return Image.asset(
        'assets/$imageSource',
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => const Icon(
              Icons.video_library,
              size: 64,
              color: Colors.white38,
            ),
      );
    } else {
      // Se for Base64 ou outro formato
      try {
        final imageBytes = _decodeBase64Image(imageSource);
        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) => const Icon(
                Icons.video_library,
                size: 64,
                color: Colors.white38,
              ),
        );
      } catch (e) {
        return const Icon(Icons.video_library, size: 64, color: Colors.white38);
      }
    }
  }

  Widget? _buildActionButton() {
    // Se o curso já estiver inscrito, mostrar estado "Já inscrito"
    if (_isInscrito) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -2),
              blurRadius: 10,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => _mostrarAlertaJaInscrito(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 20),
              SizedBox(width: 8),
              Text(
                'Já inscrito',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    // Verificar se o curso está terminado
    bool cursoTerminado = _verificarCursoTerminado();

    // Caso contrário, mostrar botão de inscrição
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed:
            (_carregandoInscricao || cursoTerminado)
                ? null
                : _alternarInscricao,
        style: ElevatedButton.styleFrom(
          backgroundColor: cursoTerminado ? Colors.grey[400] : Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          disabledBackgroundColor: Colors.grey[400],
          disabledForegroundColor: Colors.white,
        ),
        child:
            _carregandoInscricao
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Inscrevendo...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school, size: 20),
                    SizedBox(width: 8),
                    Text(
                      cursoTerminado
                          ? 'Curso Terminado'
                          : 'Inscrever-se no Curso',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  // Método simplificado para verificar se o curso está terminado
  bool _verificarCursoTerminado() {
    return widget.curso.isTerminado;
  }

  Widget _buildCommentsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.comment, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Comentários',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                if (_estatisticasCurso != null)
                  Text(
                    '${_estatisticasCurso!['total_comentarios'] ?? 0} comentários',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          // Usando o componente de comentários - agora aberto para todos
          ComentariosSection(
            cursoId: widget.curso.id ?? 0,
            // *** REMOVIDO: isInscrito - agora qualquer pessoa pode comentar ***
          ),
        ],
      ),
    );
  }

  // Verificar se o curso é favorito ao carregar a página
  Future<void> _verificarFavorito() async {
    if (widget.curso.id != null) {
      final isFavorito = await CursoService.verificarFavorito(widget.curso.id!);
      if (mounted) {
        setState(() {
          _isFavorito = isFavorito;
          _carregandoFavorito = false;
        });
      }
    } else {
      setState(() {
        _carregandoFavorito = false;
      });
    }
  }

  Future<void> _alternarFavorito() async {
    setState(() {
      _carregandoFavorito = true;
    });

    print(
      '⚡ Alterando favorito para o curso ${widget.curso.id} - Estado atual: ${_isFavorito ? "É favorito" : "Não é favorito"}',
    );

    // Alternar o estado de favorito na API
    final novoEstado = await CursoService.alternarFavorito(widget.curso.id!);
    print(
      '⚡ Resultado da API: ${novoEstado ? "É favorito" : "Não é favorito"}',
    );

    if (mounted) {
      setState(() {
        _isFavorito = novoEstado;
        _carregandoFavorito = false;
      });

      // Mostrar feedback para o usuário baseado na alteração real
      final mensagem =
          novoEstado
              ? 'Curso adicionado aos favoritos!'
              : 'Curso removido dos favoritos!';
      print('📢 Mostrando mensagem: "$mensagem"');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: novoEstado ? Colors.green : Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Widget para o botão de favorito
  Widget _buildFavoriteButton() {
    return _carregandoFavorito
        ? Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(12),
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
          ),
        )
        : IconButton(
          icon: Icon(
            _isFavorito ? Icons.bookmark : Icons.bookmark_border,
            color: _isFavorito ? Colors.yellow : null,
          ),
          onPressed: _alternarFavorito,
        );
  }

  // Verificar se o curso está nas inscrições ao carregar a página
  Future<void> _verificarInscricao() async {
    // Sempre verificar via API para garantir dados atualizados
    if (widget.curso.id != null) {
      final isInscrito = await CursoService.verificarInscricao(
        widget.curso.id!,
      );
      if (mounted) {
        setState(() {
          _isInscrito = isInscrito;
          _carregandoInscricao = false;
        });
      }
    } else {
      setState(() {
        _carregandoInscricao = false;
      });
    }
  }

  Future<void> _alternarInscricao() async {
    if (widget.curso.id == null) return;

    setState(() {
      _carregandoInscricao = true;
    });

    print(
      '⚡ Alterando inscrição para o curso ${widget.curso.id} - Estado atual: ${_isInscrito ? "Inscrito" : "Não inscrito"}',
    );

    if (_isInscrito) {
      // Mostrar alerta informando que já está inscrito
      setState(() {
        _carregandoInscricao = false;
      });
      _mostrarAlertaJaInscrito();
      return;
    } else {
      // Fazer inscrição - navegar para formulário
      setState(() {
        _carregandoInscricao = false;
      });

      final resultado = await context.push('/inscricao', extra: widget.curso);

      if (resultado == true) {
        // Inscrição bem-sucedida, atualizar estado
        setState(() {
          _isInscrito = true;
        });
      }
    }
  }

  // Método para obter avaliação média dinâmica das estatísticas
  double? _getAvaliacaoMedia() {
    // Primeiro tentar usar a avaliação das estatísticas dinâmicas
    if (_estatisticasCurso != null &&
        _estatisticasCurso!['avaliacao_media'] != null) {
      try {
        return double.parse(_estatisticasCurso!['avaliacao_media'].toString());
      } catch (e) {
        print('❌ Erro ao converter avaliação média: $e');
      }
    }

    // Fallback para a avaliação do curso (caso as estatísticas não estejam carregadas ainda)
    return widget.curso.avaliacao;
  }

  // Mostrar alerta quando utilizador clica no botão "Já inscrito"
  void _mostrarAlertaJaInscrito() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 28),
              const SizedBox(width: 12),
              const Text(
                'Já Inscrito',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Já está inscrito no curso "${widget.curso.titulo}".',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                'Para aceder ao conteúdo do curso, vá para a página "Os Meus Cursos" ou clique no botão abaixo.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fechar', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // Navegar para a página específica de curso inscrito
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => CursoInscritoPage(curso: widget.curso),
                  ),
                );
              },
              icon: const Icon(Icons.school, size: 18),
              label: const Text('Ver Curso'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
