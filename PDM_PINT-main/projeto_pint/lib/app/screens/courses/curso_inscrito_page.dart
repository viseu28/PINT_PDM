import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/curso_model.dart';
import '../../services/curso_service.dart';
import '../video/video_player_page.dart';
import 'dart:io';
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import '../../models/projetos_model.dart';
import '../../services/projetos_services.dart';
import '../../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:http/io_client.dart';
import '../quiz/quiz_page.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/link_model.dart';
import '../../services/link_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_config.dart';

class CursoInscritoPage extends StatefulWidget {
  final Curso curso;

  const CursoInscritoPage({super.key, required this.curso});

  @override
  State<CursoInscritoPage> createState() => _CursoInscritoPageState();
}

class _CursoInscritoPageState extends State<CursoInscritoPage>
    with SingleTickerProviderStateMixin {
  String? idUser;
  late TabController _tabController;
  bool _isLoading = true;
  List<ProjetoModel> projetos = [];
  bool isLoading = true;
  PlatformFile? _arquivoSelecionado;
  bool _enviando = false;
  bool _mostrarConfirmacao = false;

  // Dados dinâmicos
  List<Map<String, dynamic>> _aulasCurso = [];
  List<Map<String, dynamic>> _materiaisApoio = [];
  List<Map<String, dynamic>> _quizzes = [];
  List<LinkModel> _linksCurso = [];
  bool _carregandoAulas = true;
  bool _carregandoMateriais = true;
  bool _carregandoQuizzes = true;
  bool _carregandoLinks = true;
  bool _cursoInacessivel = false;

  @override
  void initState() {
    super.initState();
    _verificarAcessibilidadeCurso();
    _tabController = TabController(
      length: 4,
      vsync: this,
    ); // Alterado para 4 tabs
    _initializeData(); // Carregar dados de forma sequencial
    _initAndLoadProjetos();

    if (!_cursoInacessivel) {
      _initializeData();
      _initAndLoadProjetos();
    } else {
      // Se for inacessível, marca como não carregando
      setState(() => _isLoading = false);
    }
  }

  void _verificarAcessibilidadeCurso() {
    final bool isAssincrono =
        widget.curso.sincrono == false ||
        widget.curso.sincrono == "false" ||
        widget.curso.sincrono == 0;

    final bool isTerminado = widget.curso.estado?.toLowerCase() == 'terminado';

    _cursoInacessivel = isAssincrono && isTerminado;

    print('🔍 Verificação de acessibilidade do curso:');
    print('   - Tipo: ${isAssincrono ? 'Assíncrono' : 'Síncrono'}');
    print('   - Estado: ${widget.curso.estado}');
    print('   - Curso inacessível: $_cursoInacessivel');
  }

  // Novo método para carregar dados na ordem correta
  Future<void> _initializeData() async {
    // Primeiro, carregar o userId
    await _fetchUserId();

    // Depois carregar os dados do curso (que precisam do userId para quizzes)
    await _carregarDadosCurso();
  }

  // Função para pull-to-refresh - recarrega todos os dados
  Future<void> _onRefresh() async {
    print('🔄 Pull-to-refresh ativado em CursoInscritoPage');

    // Recarregar todos os dados em paralelo
    await Future.wait([
      _initializeData(), // Dados do curso (aulas, materiais, links, quizzes)
      _initAndLoadProjetos(), // Projetos
    ]);

    print('✅ Dados atualizados com sucesso');
  }

  Future<void> _fetchUserId() async {
    final user = await AuthService.getCurrentUser();
    if (user != null) {
      setState(() {
        idUser = user.id.toString(); // Convertendo o id para String
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _abrirProjeto(String url) async {
    try {
      // 1. Pedir permissão para armazenamento
      if (!await _pedirPermissaoStorage()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão de armazenamento negada!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 2. Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Preparando arquivo...'),
                ],
              ),
            ),
      );

      // 3. Baixar o arquivo
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;

      // 4. Salvar localmente
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/projeto_temp.pdf');
      await file.writeAsBytes(bytes);

      // 5. Fechar loading
      if (mounted) Navigator.of(context).pop();

      // 6. Abrir o arquivo
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _initAndLoadProjetos() async {
    setState(() => isLoading = true);

    final user = await AuthService.getCurrentUser();
    if (user == null) {
      debugPrint("Nenhum utilizador autenticado encontrado.");
      setState(() => isLoading = false);
      return;
    }

    final int? idCurso = widget.curso.id;
    if (idCurso == null) {
      debugPrint("ID do curso está nulo.");
      setState(() => isLoading = false);
      return;
    }

    try {
      final data = await ProjetoService.fetchProjetosPorCurso(idCurso, user.id);
      debugPrint('Projetos recebidos: ${data.length}');
      setState(() {
        projetos = data;
      });
    } catch (e) {
      debugPrint("Erro ao buscar projetos: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _carregarDadosCurso() async {
    setState(() => _isLoading = true);

    try {
      // Carregar aulas, materiais e links em paralelo
      List<Future> futures = [
        _carregarAulas(),
        _carregarMateriais(),
        _carregarLinks(),
      ];

      // Debug do campo sincrono
      print('🔍 Debug curso:');
      print('   - Título: ${widget.curso.titulo}');
      print('   - Campo sincrono: ${widget.curso.sincrono}');
      print('   - Tipo do campo: ${widget.curso.sincrono.runtimeType}');

      // Se for curso assíncrono, carregar também os quizzes
      final bool isAssincrono =
          widget.curso.sincrono == false ||
          widget.curso.sincrono == "false" ||
          widget.curso.sincrono == 0;
      print('   - É assíncrono? $isAssincrono');

      if (isAssincrono) {
        print('✅ Adicionando _carregarQuizzes à lista de futures');
        futures.add(_carregarQuizzes());
      } else {
        print('❌ Curso é síncrono, não carregando quizzes');
      }

      await Future.wait(futures);
    } catch (e) {
      print('Erro ao carregar dados do curso: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _carregarAulas() async {
    try {
      setState(() => _carregandoAulas = true);

      print('🔍 Debug: Carregando aulas para curso:');
      print('   - ID: ${widget.curso.id}');
      print('   - Título: ${widget.curso.titulo}');

      final aulasBuscadas = await CursoService.buscarAulasCurso(
        widget.curso.id!,
      );

      if (mounted) {
        setState(() {
          _aulasCurso = aulasBuscadas;
          _carregandoAulas = false;
        });

        print('🔍 Debug: Aulas recebidas:');
        print('   - Quantidade: ${aulasBuscadas.length}');
        if (aulasBuscadas.isNotEmpty) {
          print('   - Primeira aula: ${aulasBuscadas.first}');
        }
      }
    } catch (e) {
      print('❌ Erro ao carregar aulas: $e');
      if (mounted) {
        setState(() {
          _aulasCurso = [];
          _carregandoAulas = false;
        });
      }
    }
  }

  Future<void> _carregarMateriais() async {
    try {
      setState(() => _carregandoMateriais = true);

      print('🔍 Debug: Carregando materiais para curso:');
      print('   - ID: ${widget.curso.id}');
      print('   - Título: ${widget.curso.titulo}');

      final materiaisBuscados = await CursoService.buscarMateriaisApoio(
        widget.curso.id!,
      );

      if (mounted) {
        setState(() {
          _materiaisApoio = materiaisBuscados;
          _carregandoMateriais = false;
        });

        print('🔍 Debug: Materiais recebidos:');
        print('   - Quantidade: ${materiaisBuscados.length}');
        if (materiaisBuscados.isNotEmpty) {
          print('   - Primeiro material: ${materiaisBuscados.first}');
        }
      }
    } catch (e) {
      print('❌ Erro ao carregar materiais: $e');
      if (mounted) {
        setState(() {
          _materiaisApoio = [];
          _carregandoMateriais = false;
        });
      }
    }
  }

  Future<void> _carregarLinks() async {
    try {
      setState(() => _carregandoLinks = true);

      print('🔗 Debug: Carregando links para curso:');
      print('   - ID: ${widget.curso.id}');
      print('   - Título: ${widget.curso.titulo}');

      final linksBuscados = await LinkService.fetchLinksPorCurso(
        widget.curso.id!,
      );

      if (mounted) {
        setState(() {
          _linksCurso = linksBuscados;
          _carregandoLinks = false;
        });

        print('🔗 Debug: Links recebidos:');
        print('   - Quantidade: ${linksBuscados.length}');
        if (linksBuscados.isNotEmpty) {
          print('   - Primeiro link: ${linksBuscados.first.titulo}');
        }
      }
    } catch (e) {
      print('❌ Erro ao carregar links: $e');
      if (mounted) {
        setState(() {
          _linksCurso = [];
          _carregandoLinks = false;
        });
      }
    }
  }

  Future<void> _carregarQuizzes() async {
    try {
      setState(() => _carregandoQuizzes = true);

      print('🔍 Debug _carregarQuizzes: idUser = $idUser');

      if (idUser == null) {
        print('❌ ID do utilizador não disponível - tentando recarregar...');
        await _fetchUserId(); // Tentar carregar o userId novamente

        if (idUser == null) {
          print('❌ Ainda não foi possível obter o ID do utilizador');
          throw Exception('ID do utilizador não disponível');
        }
      }

      print('✅ ID do utilizador disponível: $idUser');

      // Buscar quizzes da API
      final quizzesBuscados = await CursoService.buscarQuizzes(
        widget.curso.id!,
        idUser!,
      );

      if (mounted) {
        setState(() {
          _quizzes = quizzesBuscados;
          _carregandoQuizzes = false;
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar quizzes: $e');
      if (mounted) {
        setState(() {
          _quizzes = [];
          _carregandoQuizzes = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          widget.curso.titulo,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Carregando detalhes do curso...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Se o curso for inacessível, mostra mensagem
    if (_cursoInacessivel) {
      return _buildCursoInacessivel();
    }

    // Caso contrário, mostra o conteúdo normal
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildCourseHeader(),
            _buildInfoSection(),
            _buildTabSection(),
            _buildTabContent(),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar quando o curso é inacessível
  Widget _buildCursoInacessivel() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'Acesso Restrito',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Já não tem acesso ao conteúdo deste curso, visto que é um curso Assíncrono e foi dado como terminado.',
              style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.school, color: Colors.blue[700], size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.curso.titulo,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.curso.descricao,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                      // Removido maxLines e overflow para mostrar texto completo
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Removidos os chips de informação (Formador 148, Introdução à UC, Horário)
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Informação',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          // Descrição dinâmica do curso
          Text(
            widget.curso.descricao.isNotEmpty
                ? widget.curso.descricao
                : 'Descrição do curso não disponível.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Linha com Datas e Formador (dinâmicos)
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Datas',
                  _getDatasCurso(),
                  Icons.calendar_today,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Formador',
                  _getFormadorCurso(),
                  Icons.person,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Linha com Tipo e Dificuldade (dinâmicos)
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Tipo',
                  widget.curso.sincrono == true ? 'Síncrono' : 'Assíncrono',
                  Icons.access_time,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Dificuldade',
                  widget.curso.dificuldade,
                  Icons.trending_up,
                  widget.curso.corDificuldade,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    // Determinar se é curso assíncrono
    final bool isAssincrono =
        widget.curso.sincrono == false ||
        widget.curso.sincrono == "false" ||
        widget.curso.sincrono == 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.blue[700],
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.blue[700],
        isScrollable: true,
        tabAlignment: TabAlignment.center,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12.0),
        tabs: [
          const Tab(text: 'Aulas'),
          const Tab(text: 'Materiais'),
          const Tab(text: 'Links'),
          Tab(text: isAssincrono ? 'Quizzes' : 'Projetos'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    // Determinar se é curso assíncrono
    final bool isAssincrono =
        widget.curso.sincrono == false ||
        widget.curso.sincrono == "false" ||
        widget.curso.sincrono == 0;

    return SizedBox(
      height: 500,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildAulasTab(),
          _buildMateriaisTab(),
          _buildLinksTab(),
          isAssincrono ? _buildQuizzesTab() : _buildProjetosTab(),
        ],
      ),
    );
  }

  Widget _buildAulasTab() {
    if (_carregandoAulas) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando aulas...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
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
            _buildSectionTitle('Aulas do Curso', Icons.play_circle_outline),
            const SizedBox(height: 16),
            if (_aulasCurso.isEmpty)
              _buildEmptyState(
                'Nenhuma aula disponível',
                'As aulas do curso ainda não foram carregadas.',
                Icons.video_library_outlined,
              )
            else
              ..._aulasCurso.asMap().entries.map((entry) {
                final index = entry.key;
                final aula = entry.value;
                return Column(
                  children: [
                    _buildAulaCard(aula, index + 1),
                    if (index < _aulasCurso.length - 1)
                      const SizedBox(height: 12),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildMateriaisTab() {
    if (_carregandoMateriais) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando materiais...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
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
            _buildSectionTitle('Materiais de Apoio', Icons.file_download),
            const SizedBox(height: 16),
            if (_materiaisApoio.isEmpty)
              _buildEmptyState(
                'Nenhum material disponível',
                'Os materiais de apoio ainda não foram carregados.',
                Icons.folder_outlined,
              )
            else
              ..._materiaisApoio.asMap().entries.map((entry) {
                final index = entry.key;
                final material = entry.value;
                return Column(
                  children: [
                    _buildMaterialCard(material),
                    if (index < _materiaisApoio.length - 1)
                      const SizedBox(height: 12),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildLinksTab() {
    if (_carregandoLinks) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando links...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
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
            _buildSectionTitle('Links Úteis', Icons.link),
            const SizedBox(height: 16),
            if (_linksCurso.isEmpty)
              _buildEmptyState(
                'Nenhum link disponível',
                'Os links ainda não foram carregados.',
                Icons.link_off,
              )
            else
              ..._linksCurso.asMap().entries.map((entry) {
                final index = entry.key;
                final link = entry.value;
                return Column(
                  children: [
                    _buildLinkCard(link),
                    if (index < _linksCurso.length - 1)
                      const SizedBox(height: 12),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildProjetosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
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
            _buildSectionTitle('Projetos Finais', Icons.assignment),
            const SizedBox(height: 16),
            if (projetos.isEmpty)
              _buildEmptyState(
                'Nenhum projeto disponível',
                'Os projetos do curso ainda não foram definidos.',
                Icons.assignment_outlined,
              )
            else
              ...projetos.map((projeto) {
                return Column(
                  children: [
                    _buildProjetoItem(projeto, idUser ?? "0"),
                    const SizedBox(height: 12),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizzesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
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
            _buildSectionTitle('Quizzes Disponíveis', Icons.quiz),
            const SizedBox(height: 16),
            if (_carregandoQuizzes)
              const Center(child: CircularProgressIndicator())
            else if (_quizzes.isEmpty)
              _buildEmptyState(
                'Nenhum quiz disponível',
                'Os quizzes do curso ainda não foram criados.',
                Icons.quiz_outlined,
              )
            else
              // Ordenar quizzes: por fazer primeiro, depois concluídos
              ...(_quizzes..sort((a, b) {
                    final aCompleto = a['completo'] == true;
                    final bCompleto = b['completo'] == true;

                    // Se um está completo e outro não, o não completo vem primeiro
                    if (aCompleto && !bCompleto) return 1;
                    if (!aCompleto && bCompleto) return -1;

                    // Se ambos têm o mesmo status, manter ordem alfabética por título
                    return (a['titulo']?.toString() ?? '').compareTo(
                      b['titulo']?.toString() ?? '',
                    );
                  }))
                  .map((quiz) {
                    return Column(
                      children: [
                        _buildQuizItem(quiz),
                        const SizedBox(height: 12),
                      ],
                    );
                  })
                  ,
          ],
        ),
      ),
    );
  }

  Widget _buildQuizItem(Map<String, dynamic> quiz) {
    final titulo = quiz['titulo']?.toString() ?? 'Quiz sem título';
    final descricao =
        quiz['descricao']?.toString() ?? 'Sem descrição disponível';
    final totalPerguntas = quiz['total_perguntas']?.toString() ?? '0';
    final completo = quiz['completo'] == true;
    final pontuacao = quiz['pontuacao']?.toString();
    final dataSubmissao = quiz['data_submissao']?.toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: completo ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: completo ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do quiz
          Row(
            children: [
              Icon(
                completo ? Icons.check_circle : Icons.quiz,
                color: completo ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Descrição
          if (descricao.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Text(
                descricao,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
          ],

          // Informações do quiz
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.help_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$totalPerguntas perguntas',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (completo) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Concluído',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),

                // Mostrar data de submissão se completo
                if (completo && dataSubmissao != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Data de Submissão: ${_formatarDataSubmissao(dataSubmissao)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],

                // Mostrar pontuação se completo
                if (completo && pontuacao != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getNotaColor(pontuacao),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getNotaIcon(pontuacao),
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Nota: $pontuacao/20',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Botão de ação
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed:
                completo
                    ? null
                    : () => _iniciarQuiz(quiz), // Desabilitar se completo
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
              backgroundColor: completo ? Colors.grey[300] : Colors.blue,
              foregroundColor: completo ? Colors.grey[600] : Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (completo) ...[
                  const Icon(Icons.check_circle, size: 18),
                  const SizedBox(width: 8),
                  const Text("Concluído"),
                ] else ...[
                  const Icon(Icons.play_arrow, size: 18),
                  const SizedBox(width: 8),
                  const Text("Iniciar Quiz"),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _iniciarQuiz(Map<String, dynamic> quiz) {
    // Navegar para a página do quiz
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => QuizPage(
              quiz: quiz,
              cursoId: widget.curso.id!,
              userId: idUser ?? '',
            ),
      ),
    );
  }

  // Métodos auxiliares para as notas
  Color _getNotaColor(String pontuacao) {
    final nota = double.tryParse(pontuacao) ?? 0;
    if (nota >= 16) return Colors.green; // Excelente (16-20)
    if (nota >= 12) return Colors.orange; // Bom (12-15)
    return Colors.red; // Precisa melhorar (0-11)
  }

  IconData _getNotaIcon(String pontuacao) {
    final nota = double.tryParse(pontuacao) ?? 0;
    if (nota >= 16) return Icons.star; // Excelente (16-20)
    if (nota >= 12) return Icons.thumb_up; // Bom (12-15)
    return Icons.trending_up; // Precisa melhorar (0-11)
  }

  // Método auxiliar para formatar a data de submissão
  String _formatarDataSubmissao(String dataSubmissao) {
    try {
      final DateTime data = DateTime.parse(dataSubmissao);
      final String dia = data.day.toString().padLeft(2, '0');
      final String mes = data.month.toString().padLeft(2, '0');
      final String ano = data.year.toString();
      final String hora = data.hour.toString().padLeft(2, '0');
      final String minuto = data.minute.toString().padLeft(2, '0');

      return '$dia/$mes/$ano, $hora:$minuto';
    } catch (e) {
      return 'Data inválida';
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAulaCard(Map<String, dynamic> aula, int numeroAula) {
    final titulo = aula['titulo']?.toString() ?? 'Aula $numeroAula';
    final descricao =
        aula['descricao']?.toString() ?? 'Sem descrição disponível';
    final duracao = aula['duracao']?.toString() ?? '20 min';
    final completa = aula['completa'] == true;

    return GestureDetector(
      onTap: () => _reproduzirAula(aula),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: completa ? Colors.green[50] : Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: completa ? Colors.green[200]! : Colors.blue[200]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: completa ? Colors.green[100] : Colors.blue[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                completa ? Icons.check_circle : Icons.play_circle_outline,
                color: completa ? Colors.green[700] : Colors.blue[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Aula $numeroAula',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:
                              completa ? Colors.green[700] : Colors.blue[700],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          duracao,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descricao,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.play_arrow, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> material) {
    final titulo = material['titulo']?.toString() ?? 'Material sem título';
    final descricao =
        material['descricao']?.toString() ?? 'Sem descrição disponível';
    final tamanho = material['tamanho']?.toString() ?? '-- KB';
    final tipoMime = material['tipo_mime']?.toString() ?? 'application/pdf';

    IconData icon;
    Color iconColor;

    if (tipoMime.contains('pdf')) {
      icon = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (tipoMime.contains('zip')) {
      icon = Icons.archive;
      iconColor = Colors.orange;
    } else if (tipoMime.contains('video')) {
      icon = Icons.video_file;
      iconColor = Colors.purple;
    } else {
      icon = Icons.description;
      iconColor = Colors.blue;
    }

    return GestureDetector(
      onTap: () => _downloadMaterial(material),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          titulo,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tamanho,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descricao,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadMaterial(material),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard(LinkModel link) {
    return GestureDetector(
      onTap: () => _abrirLink(link.url),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.link, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (link.descricao != null && link.descricao!.isNotEmpty)
                    Text(
                      link.descricao!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    link.url,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () => _abrirLink(link.url),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirLink(String url) async {
    try {
      final Uri uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Não foi possível abrir o link: $url'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erro ao abrir link: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao abrir o link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Adicione estas variáveis na sua classe _CursoInscritoPageState

  // Substitua o método _abrirPickerEEnviarProjeto por este:
  Future<void> _abrirPickerEEnviarProjeto(
    String idProjeto,
    String idUser,
  ) async {
    debugPrint("==== Início de _abrirPickerEEnviarProjeto ====");
    debugPrint("Projeto ID: $idProjeto | Usuário ID: $idUser");

    // 1. Verificar permissões (Android)
    if (Platform.isAndroid) {
      debugPrint("Solicitando permissão de armazenamento...");
      final status = await Permission.manageExternalStorage.request();
      debugPrint("Permissão concedida? ${status.isGranted}");
      if (!status.isGranted) {
        debugPrint("Permissão negada, exibindo snackbar");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão de armazenamento necessária'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    try {
      // 2. Abrir seletor de arquivos
      debugPrint("Abrindo FilePicker...");
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'zip', 'txt'],
        allowMultiple: false,
        withData: true,
      );

      debugPrint(
        "FilePicker resultado: ${result != null ? 'Arquivo selecionado' : 'Nenhum arquivo'}",
      );

      if (result == null || result.files.isEmpty) {
        debugPrint("Nenhum arquivo foi selecionado. Cancelando operação.");
        return;
      }

      final file = result.files.first;
      debugPrint(
        "Arquivo selecionado: ${file.name}, tamanho: ${file.size} bytes",
      );

      // 3. Verificar se o arquivo foi carregado
      if (file.bytes == null) {
        debugPrint("Erro: bytes do arquivo são null");
        throw Exception('Não foi possível ler o conteúdo do arquivo');
      }

      // 4. Mostrar confirmação
      debugPrint("Atualizando estado para mostrar confirmação de envio");
      setState(() {
        _arquivoSelecionado = file;
        _mostrarConfirmacao = true;
      });

      debugPrint("==== Fim de _abrirPickerEEnviarProjeto ====");
    } catch (e, stack) {
      debugPrint("Erro ao selecionar arquivo: $e");
      debugPrint("Stacktrace: $stack");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _enviarArquivo(String idProjeto, String idUser) async {
    debugPrint("==== Início de _enviarArquivo ====");
    debugPrint("Projeto ID: $idProjeto | Usuário ID: $idUser");

    if (_arquivoSelecionado == null) {
      debugPrint("Nenhum arquivo selecionado para envio");
      return;
    }

    setState(() {
      _enviando = true;
      _mostrarConfirmacao = false;
    });

    try {
      // Mostra loading
      debugPrint("Mostrando diálogo de carregamento");
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Enviando arquivo..."),
                ],
              ),
            ),
      );

      // Prepara o request
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/projetos/$idProjeto/submeter',
      );
      debugPrint("Enviando para URI: $uri");
      final request = http.MultipartRequest('POST', uri);

      // Adiciona o arquivo
      debugPrint("Adicionando arquivo: ${_arquivoSelecionado!.name}");
      request.files.add(
        http.MultipartFile.fromBytes(
          'arquivo',
          _arquivoSelecionado!.bytes!,
          filename: _arquivoSelecionado!.name,
        ),
      );

      // Adiciona o ID do usuário
      debugPrint("Adicionando campo iduser: $idUser");
      request.fields['iduser'] = idUser;

      // Envia o request
      debugPrint("Enviando request...");
      final response = await request.send();
      debugPrint("Status code recebido: ${response.statusCode}");
      final responseBody = await response.stream.bytesToString();
      debugPrint("Resposta do servidor: $responseBody");

      // Fecha o diálogo de loading
      if (mounted) {
        debugPrint("Fechando diálogo de carregamento");
        Navigator.of(context).pop();
      }

      // Verifica a resposta
      if (response.statusCode == 201) {
        debugPrint("Arquivo enviado com sucesso!");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Arquivo enviado com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
        await _initAndLoadProjetos(); // Atualiza lista
      } else {
        debugPrint("Falha no envio. Status: ${response.statusCode}");
        throw Exception("Erro ${response.statusCode}: $responseBody");
      }
    } catch (e, stack) {
      debugPrint("Erro no envio: $e");
      debugPrint("Stacktrace: $stack");
      if (mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Falha no envio: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      debugPrint("Resetando estado de envio e arquivo selecionado");
      setState(() {
        _enviando = false;
        _arquivoSelecionado = null;
      });
      debugPrint("==== Fim de _enviarArquivo ====");
    }
  }

  // 4. Atualize o método _buildProjetoItem para incluir a confirmação
  Widget _buildProjetoItem(ProjetoModel projeto, String idUser) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: projeto.entregue ? Colors.green[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: projeto.entregue ? Colors.green[200]! : Colors.blue[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do projeto
          Row(
            children: [
              Icon(
                projeto.entregue ? Icons.check_circle : Icons.assignment,
                color: projeto.entregue ? Colors.green : Colors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  projeto.nomeProjeto,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Descrição (se existir)
          if (projeto.descricao != null && projeto.descricao!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Text(
                projeto.descricao!,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
          ],

          // Botão para baixar o enunciado do projeto
          if (projeto.ficheiroUrl != null && projeto.ficheiroUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 32.0, top: 8, bottom: 8),
              child: ElevatedButton(
                onPressed: () => _abrirProjeto(projeto.ficheiroUrl!),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Enunciado"),
              ),
            ),

          // Mostra o arquivo selecionado (se houver)
          if (_arquivoSelecionado != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_file, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _arquivoSelecionado!.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed:
                        () => setState(() {
                          _arquivoSelecionado = null;
                        }),
                  ),
                ],
              ),
            ),

          // Botão de envio ou confirmação
          if (_mostrarConfirmacao && _arquivoSelecionado != null)
            ElevatedButton(
              onPressed:
                  () => _enviarArquivo(projeto.idProjeto.toString(), idUser),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                backgroundColor: Colors.green,
              ),
              child: const Text("Confirmar Envio"),
            )
          else
            ElevatedButton(
              onPressed:
                  _enviando
                      ? null
                      : () => _abrirPickerEEnviarProjeto(
                        projeto.idProjeto.toString(),
                        idUser,
                      ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                backgroundColor: projeto.entregue ? Colors.orange : Colors.blue,
              ),
              child:
                  _enviando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                        projeto.entregue
                            ? "Substituir Arquivo"
                            : "Enviar Projeto",
                      ),
            ),
        ],
      ),
    );
  }

  Future<void> _baixarEAbriProjeto(String url) async {
    try {
      // Verificar se a URL é válida
      if (url.isEmpty || !Uri.parse(url).isAbsolute) {
        throw Exception('URL do projeto inválida');
      }

      print('🔽 Iniciando download do projeto: $url');

      // 1. Verificar permissões (Android)
      if (Platform.isAndroid) {
        final status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        }
      }

      // 2. Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Baixando arquivo...'),
                ],
              ),
            ),
      );

      // 3. Configurar cliente HTTP com timeout
      final client = IOClient(
        HttpClient()..connectionTimeout = const Duration(seconds: 15),
      );

      try {
        // 4. Fazer a requisição
        final response = await client.get(Uri.parse(url));

        if (response.statusCode != 200) {
          throw Exception('Erro HTTP ${response.statusCode}');
        }

        // 5. Obter bytes
        final bytes = response.bodyBytes;

        // 6. Salvar arquivo
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${directory.path}/projeto_$timestamp.pdf');
        await file.writeAsBytes(bytes);

        print('✅ Arquivo salvo em: ${file.path}');

        // 7. Abrir arquivo
        final result = await OpenFilex.open(file.path);

        if (result.type != ResultType.done) {
          throw Exception('Erro ao abrir arquivo: ${result.message}');
        }
      } finally {
        client.close();
      }
    } on SocketException {
      _mostrarErro('Sem conexão com a internet', url);
    } finally {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }

  void _mostrarErro(String mensagem, String url) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Tentar novamente',
          onPressed: () => _baixarEAbriProjeto(url),
        ),
      ),
    );
  }

  // Função para reproduzir vídeo da aula
  Future<void> _reproduzirAula(Map<String, dynamic> aula) async {
    try {
      final videoUrl = CursoService.obterUrlVideoAula(aula);

      if (videoUrl != null && videoUrl.isNotEmpty) {
        print('🎥 Reproduzindo vídeo: $videoUrl');

        // Mostrar dialog com informações do vídeo (ou implementar player)
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(aula['titulo'] ?? 'Vídeo da Aula'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('URL do vídeo: $videoUrl'),
                  const SizedBox(height: 12),
                  Text('Descrição: ${aula['descricao'] ?? 'Sem descrição'}'),
                  const SizedBox(height: 12),
                  Text('Duração: ${aula['duracao'] ?? 'N/A'}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    // Em vez de abrir com url_launcher, usar o mesmo fluxo da página de detalhes
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (context) => VideoPlayerPage(
                              videoUrl: videoUrl,
                              title: aula['titulo'] ?? 'Vídeo da Aula',
                            ),
                      ),
                    );
                  },
                  child: const Text('Reproduzir'),
                ),
              ],
            );
          },
        );
      } else {
        // Mostrar mensagem de erro se não há vídeo
        final stateContext = context;
        ScaffoldMessenger.of(stateContext).showSnackBar(
          const SnackBar(
            content: Text('Esta aula não possui vídeo disponível'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Erro ao reproduzir aula: $e');
      final stateContext = context;
      ScaffoldMessenger.of(stateContext).showSnackBar(
        const SnackBar(
          content: Text('Erro ao carregar vídeo da aula'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Função para download de material
  Future<void> _downloadMaterial(Map<String, dynamic> material) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final String url = material['caminho_arquivo'];
    final String fileName =
        material['nome_arquivo'] ??
        'material_${DateTime.now().millisecondsSinceEpoch}.pdf';

    try {
      // 1. Mostrar diálogo de progresso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Fazendo download...'),
                ],
              ),
            ),
      );

      // 2. Fazer a requisição HTTP
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception(
          'Falha ao baixar arquivo: Status ${response.statusCode}',
        );
      }

      // 3. Obter diretório de downloads
      final directory = await getExternalStorageDirectory();
      final downloadsDir = Directory('${directory?.path}/Download');

      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // 4. Salvar o arquivo
      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      // 5. Fechar diálogo de progresso
      if (mounted) Navigator.of(context).pop();

      // 6. Abrir o arquivo
      final result = await OpenFilex.open(file.path);

      if (result.type != ResultType.done) {
        throw Exception('Não foi possível abrir o arquivo: ${result.message}');
      }
    } on SocketException {
      if (mounted) Navigator.of(context).pop();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Sem conexão com a internet')),
      );
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString()}'),
          action: SnackBarAction(
            label: 'Tentar novamente',
            onPressed: () => _downloadMaterial(material),
          ),
        ),
      );
    }
  }

  Future<bool> _pedirPermissaoStorage() async {
    if (Platform.isAndroid) {
      final sdkInt = await _getAndroidSdkInt();
      print('Android SDK version: $sdkInt');

      if (sdkInt >= 30) {
        var status = await Permission.manageExternalStorage.status;
        print('manageExternalStorage status: $status');

        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
          print('manageExternalStorage pedido: $status');

          if (!status.isGranted) {
            await openAppSettings();
          }
        }
        return status.isGranted;
      } else {
        var status = await Permission.storage.status;
        print('storage status: $status');

        if (!status.isGranted) {
          status = await Permission.storage.request();
          print('storage pedido: $status');
        }
        return status.isGranted;
      }
    }
    return true;
  }

  Future<int> _getAndroidSdkInt() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    } catch (e) {
      print('Erro a obter SDK Android: $e');
      return 0;
    }
  }

  // Métodos auxiliares para dados dinâmicos
  String _getDatasCurso() {
    if (widget.curso.dataInicio != null && widget.curso.dataFim != null) {
      return '${widget.curso.dataInicio} -\n${widget.curso.dataFim}';
    } else if (widget.curso.dataInicio != null) {
      return 'Início:\n${widget.curso.dataInicio}';
    } else if (widget.curso.dataFim != null) {
      return 'Fim:\n${widget.curso.dataFim}';
    } else {
      return 'Datas não\ndefinidas';
    }
  }

  String _getFormadorCurso() {
    print(
      '🔍 DEBUG Formador: "${widget.curso.formadorResponsavel}" (${widget.curso.formadorResponsavel?.runtimeType})',
    );

    if (widget.curso.formadorResponsavel != null &&
        widget.curso.formadorResponsavel!.trim().isNotEmpty) {
      return widget.curso.formadorResponsavel!;
    } else {
      return 'A definir';
    }
  }
}
