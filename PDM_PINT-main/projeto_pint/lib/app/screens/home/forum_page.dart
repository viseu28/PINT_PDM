import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:projeto_pint/app/routes/route_names.dart';
import 'package:projeto_pint/app/database/local_database.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../widgets/notification_badge.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'conversa_page.dart';
import 'guardados_page.dart';
import 'perfil_page.dart';
import '../../services/curso_service.dart';
import '../../../config/api_config.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  _ForumPageState createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  late Future<List<dynamic>> topicos;
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _urlController =
      TextEditingController(); // Novo campo para URL
  PlatformFile? _selectedFile; // Ficheiro selecionado

  Set<int> likedPosts = {};
  Set<int> dislikedPosts = {};
  Set<int> guardados = {};

  UserModel? currentUser;
  bool isLoadingUser = true;
  int? _topicoSelecionado;
  List<dynamic> _listaTopicosDropdown = [];
  bool _loadingDropdown = true;
  int? categoriaSelecionada;
  int? areaSelecionada;
  int? selectedTopicoId;

  @override
  void initState() {
    super.initState();
    topicos = fetchTopicos();
    _loadUserData();
    _carregarTopicosDropdown();
  }

  // Função para pull-to-refresh
  Future<void> _onRefresh() async {
    print('🔄 Pull-to-refresh ativado em ForumPage');

    // Recarregar todos os dados em paralelo
    await Future.wait([_loadUserData(), _carregarTopicosDropdown()]);

    setState(() {
      topicos = fetchTopicos();
    });

    print('✅ Fórum atualizado com sucesso');
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(mensagem)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthService.getCurrentUser();
      setState(() {
        currentUser = user;
        isLoadingUser = false;
      });
      if (user != null) {
        final set = await fetchGuardados(user.id);
        setState(() {
          guardados = set;
        });
        await fetchLikesDislikes(user.id);
      }
    } catch (e) {
      setState(() {
        isLoadingUser = false;
      });
    }
  }

  // Funções para guardar/remover e buscar guardados do backend
  Future<void> guardarPost(int idUtilizador, int idPost) async {
    await http.post(
      Uri.parse('${ApiConfig.guardadosUrl}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idutilizador': idUtilizador, 'idpost': idPost}),
    );
  }

  Future<void> removerGuardado(int idUtilizador, int idPost) async {
    await http.delete(
      Uri.parse('${ApiConfig.guardadosUrl}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idutilizador': idUtilizador, 'idpost': idPost}),
    );
  }

  Future<Set<int>> fetchGuardados(int idUtilizador) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.guardadosUrl}/$idUtilizador'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map<int>((e) => e['idpost'] as int).toSet();
    }
    return {};
  }

  // Funções para likes/dislikes
  Future<void> likePost(int idUtilizador, int idPost) async {
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/likes_forum'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idutilizador': idUtilizador,
        'idpost': idPost,
        'tipo': 'like',
      }),
    );
    // NÃO faças fetchLikesDislikes aqui!
  }

  Future<void> dislikePost(int idUtilizador, int idPost) async {
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/likes_forum'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idutilizador': idUtilizador,
        'idpost': idPost,
        'tipo': 'dislike',
      }),
    );
    // NÃO faças fetchLikesDislikes aqui!
  }

  Future<void> removerLikeDislike(int idUtilizador, int idPost) async {
    await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/likes_forum'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idutilizador': idUtilizador, 'idpost': idPost}),
    );
    // NÃO faças fetchLikesDislikes aqui!
  }

  Future<void> fetchLikesDislikes(int idUtilizador) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/likes_forum/$idUtilizador'),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        // Obter lista de posts existentes para filtrar likes órfãos
        final postsResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/forum/topicos'),
        );

        if (postsResponse.statusCode == 200) {
          final List posts = jsonDecode(postsResponse.body);
          final Set<int> postIds =
              posts.map<int>((p) => p['idpost'] as int).toSet();

          // Filtrar apenas likes/dislikes de posts que existem
          final validLikes =
              data.where((e) => postIds.contains(e['idpost'] as int)).toList();

          setState(() {
            likedPosts =
                validLikes
                    .where((e) => e['tipo'] == 'like')
                    .map<int>((e) => e['idpost'] as int)
                    .toSet();
            dislikedPosts =
                validLikes
                    .where((e) => e['tipo'] == 'dislike')
                    .map<int>((e) => e['idpost'] as int)
                    .toSet();
          });
        } else {
          // Fallback se não conseguir obter os posts
          setState(() {
            likedPosts =
                data
                    .where((e) => e['tipo'] == 'like')
                    .map<int>((e) => e['idpost'] as int)
                    .toSet();
            dislikedPosts =
                data
                    .where((e) => e['tipo'] == 'dislike')
                    .map<int>((e) => e['idpost'] as int)
                    .toSet();
          });
        }
      }
    } catch (e) {
      print('Erro ao buscar likes/dislikes: $e');
    }
  }

  // ALTERAÇÃO: Buscar tópicos do endpoint correto para o dropdown
  Future<void> _carregarTopicosDropdown() async {
    setState(() {
      _loadingDropdown = true;
    });
    try {
      final lista = await fetchTopicosDropdown();
      setState(() {
        _listaTopicosDropdown = lista;
        _loadingDropdown = false;
      });
    } catch (e) {
      setState(() {
        _listaTopicosDropdown = [];
        _loadingDropdown = false;
      });
    }
  }

  // NOVO: Busca tópicos só para o dropdown
  Future<List<dynamic>> fetchTopicosDropdown() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/forum/topicos_dropdown'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao carregar tópicos');
    }
  }

  // Adiciona esta função ao _ForumPageState:
  Future<void> denunciarPost(int idPost, String motivo) async {
    if (currentUser == null) return;
    final response = await http.post(
      Uri.parse('${ApiConfig.denunciaUrl}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idpost': idPost,
        'motivo': motivo,
        'idutilizador': currentUser!.id,
        'idcomentario': null,
        'data': DateTime.now().toIso8601String(),
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Falha ao denunciar post');
    }
  }

  // NOVO: Busca categorias e áreas para o dropdown
  Future<List<dynamic>> fetchCategoriasAreasTopicos() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/forum/categorias_areas_topicos'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao carregar categorias');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildForumDrawer(context),
      backgroundColor: Color(0xFFF3F0F4),
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bem-vindo ao Fórum!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                Text(
                  isLoadingUser
                      ? 'A Carregar ...'
                      : (currentUser?.nome ?? 'Utilizador'),
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          const NotificationBadge(),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              context.go(RouteNames.settings);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: 16),
              _buildCreatePostCard(),
              SizedBox(height: 16),
              FutureBuilder<List<dynamic>>(
                future: topicos,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('Nenhum post encontrado.'));
                  } else {
                    // Filtra os posts pelo tópico selecionado, se houver
                    final posts =
                        selectedTopicoId == null
                            ? snapshot.data!
                            : snapshot.data!
                                .where(
                                  (post) =>
                                      post['idtopico'] == selectedTopicoId,
                                )
                                .toList();
                    if (posts.isEmpty) {
                      return Center(
                        child: Text('Nenhum post encontrado para este tópico.'),
                      );
                    }
                    return Column(
                      children:
                          posts
                              .map(
                                (topico) =>
                                    _buildForumPostCard(context, topico),
                              )
                              .toList(),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey.shade400,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        currentIndex: 1,
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
              // Já está na página do fórum, não faz nada
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

  Widget _buildCreatePostCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Reduzir padding de 16 para 12
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color.fromARGB(255, 178, 68, 119),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _nomeController,
                    decoration: InputDecoration(
                      hintText: 'Título',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Dropdown de tópicos com botão para sugerir novo
            Row(
              children: [
                Expanded(
                  child:
                      _loadingDropdown
                          ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: LinearProgressIndicator(),
                          )
                          : DropdownButtonFormField<int>(
                            value: _topicoSelecionado,
                            isDense: true,
                            decoration: InputDecoration(
                              hintText: 'Escolha o tópico',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                            items:
                                _listaTopicosDropdown
                                    .where(
                                      (topico) =>
                                          topico['nome'] != null &&
                                          topico['idtopicos'] != null,
                                    )
                                    .map<DropdownMenuItem<int>>((topico) {
                                      return DropdownMenuItem<int>(
                                        value: topico['idtopicos'],
                                        child: Text(topico['nome'].toString()),
                                      );
                                    })
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                _topicoSelecionado = value;
                              });
                            },
                            validator:
                                (value) =>
                                    value == null
                                        ? 'Selecione um tópico'
                                        : null,
                          ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _mostrarModalSugerirTopico();
                  },
                  icon: Icon(Icons.add_circle_outline, size: 16),
                  label: Text(
                    'Pedir novo tópico',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 178, 68, 119),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 2,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            TextField(
              controller: _descricaoController,
              decoration: InputDecoration(
                hintText: 'Descrição',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6, // Reduzir de 8 para 6
                ),
              ),
              maxLines: 1, // Reduzir de 2 para 1 linha
            ),
            SizedBox(height: 6), // Reduzir espaçamento
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'URL (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6, // Reduzir padding
                ),
                prefixIcon: Icon(Icons.link, size: 16), // Ícone menor
              ),
              keyboardType: TextInputType.url,
            ),
            SizedBox(height: 6),
            // Seção para anexo de ficheiro (mais compacta)
            Container(
              padding: EdgeInsets.all(8), // Reduzir padding
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_file, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 6),
                  Expanded(
                    child:
                        _selectedFile != null
                            ? Row(
                              children: [
                                Icon(
                                  _getFileIcon(
                                    _getFileExtension(_selectedFile!.name),
                                  ),
                                  color: Colors.green[600],
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _selectedFile!.name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedFile = null;
                                    });
                                  },
                                  icon: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.red,
                                  ),
                                  constraints: BoxConstraints(),
                                  padding: EdgeInsets.all(2),
                                ),
                              ],
                            )
                            : Text(
                              'Anexar ficheiro',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                  ),
                  TextButton(
                    onPressed: _selecionarFicheiro,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[600],
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: Text('Selecionar', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 6), // Reduzir espaçamento
            Row(
              children: [
                Icon(Icons.format_bold, size: 18), // Ícones menores
                SizedBox(width: 6),
                Icon(Icons.format_italic, size: 18),
                SizedBox(width: 6),
                Icon(Icons.format_list_bulleted, size: 18),
                SizedBox(width: 6),
                Icon(Icons.format_quote, size: 18),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      debugPrint('🚀 Botão pressionado');

                      // 🔍 Verificar permissão antes de criar o post
                      debugPrint('🔄 Verificando permissão 11...');
                      final temPermissao =
                          await CursoService.permissaoLigacaoEspecifica(11);
                      debugPrint(
                        '✅ Permissão de role "formando" para id 11: $temPermissao',
                      );

                      if (!temPermissao) {
                        debugPrint(
                          '⛔ Permissão negada: usuário não é "formando" para este idpermissao',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Ação bloqueada devido à permissão 11'
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // ⚠️ Validação dos campos obrigatórios
                      debugPrint('🔄 Validando campos obrigatórios...');
                      if (_nomeController.text.trim().isEmpty ||
                          _descricaoController.text.trim().isEmpty ||
                          _topicoSelecionado == null) {
                        debugPrint('❌ Campos incompletos');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Preencha o título, descrição e selecione um tópico!',
                            ),
                          ),
                        );
                        return;
                      }
                      debugPrint('✅ Campos validados');

                      // 📄 Criar post com ou sem ficheiro
                      if (_selectedFile != null) {
                        debugPrint('📎 Ficheiro selecionado: $_selectedFile');
                        await _criarPostComFicheiro();
                        debugPrint('✅ Post com ficheiro criado');
                      } else {
                        debugPrint('📝 Sem ficheiro, criando post normal...');
                        await criarTopico(
                          _nomeController.text,
                          _descricaoController.text,
                          true,
                          _topicoSelecionado,
                          _urlController.text.trim(),
                        );
                        debugPrint('✅ Post normal criado');
                      }

                      // 🔄 Atualizar estado da UI
                      debugPrint('🔄 Atualizando estado da UI...');
                      setState(() {
                        topicos = fetchTopicos();
                        _topicoSelecionado = null;
                        _selectedFile = null;
                      });
                      debugPrint('✅ Estado atualizado');

                      // 🧹 Limpar campos
                      debugPrint('🧹 Limpando campos...');
                      _nomeController.clear();
                      _descricaoController.clear();
                      _urlController.clear();
                      debugPrint('✅ Campos limpos');
                    } catch (e, st) {
                      debugPrint('❌ Erro no botão: $e');
                      debugPrint('$st');
                    }
                  },
                  icon: Icon(Icons.send, size: 16),
                  label: Text('Criar post', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForumPostCard(BuildContext context, dynamic topico) {
    final int? idPost =
        topico['idpost'] ??
        topico['id'] ??
        topico['idforum'] ??
        topico['idPost'];
    final int postId = idPost ?? topico.hashCode;

    int likes = topico['likes'] ?? 0;
    int dislikes = topico['dislikes'] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ConversaPage(
                  topico: topico,
                  nomeUtilizador: currentUser?.nome ?? 'Utilizador',
                  idUtilizador: currentUser?.id ?? 0,
                ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        margin: EdgeInsets.only(bottom: 18),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do post com autor, categoria e data
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Text(
                    topico['autor'] ?? 'utilizador',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      // Mostra o nome do tópico correspondente ao idtopico do post
                      (() {
                        final idTopico = topico['idtopico'];
                        final topicoObj = _listaTopicosDropdown.firstWhere(
                          (t) => t['idtopicos'] == idTopico,
                          orElse: () => null,
                        );
                        return topicoObj != null
                            ? topicoObj['nome'].toString()
                            : 'Categoria';
                      })(),
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  // Só mostra o menu se o post for do utilizador autenticado
                  if (topico['idutilizador'] == currentUser?.id)
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'eliminar') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text('Eliminar Post'),
                                  content: Text(
                                    'Tem a certeza que deseja eliminar este post?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: Text(
                                        'Eliminar',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                          );
                          if (confirm == true) {
                            await eliminarPost(idPost!);
                          }
                        }
                      },
                      itemBuilder:
                          (context) => [
                            PopupMenuItem(
                              value: 'eliminar',
                              child: Text(
                                'Eliminar',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                      icon: Icon(Icons.more_vert),
                    )
                  else
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        // Mantém por compatibilidade, mas ação real está no onTap do item
                        print('🎯 onSelected chamado: $value');
                      },
                      itemBuilder:
                          (context) => [
                            PopupMenuItem(
                              value: 'denunciar',
                              onTap: () {
                                Future.microtask(() async {
                                  try {
                                    print('🟠 Tap em Denunciar');
                                    final ligado =
                                        await CursoService.permissaoLigacaoEspecifica(
                                          15,
                                        );
                                    print(
                                      '🟢 Permissão 15 = $ligado',
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Permissão 15: $ligado',
                                        ),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                    if (ligado == false) {
                                      _mostrarErro(
                                        'Ação bloqueada devido à permissão 15',
                                      );
                                      return;
                                    }

                                    String motivo = '';
                                    final result = await showDialog<String>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text('Denunciar Post'),
                                          content: TextField(
                                            autofocus: true,
                                            decoration: InputDecoration(
                                              hintText: 'Motivo da denúncia',
                                            ),
                                            onChanged:
                                                (value) => motivo = value,
                                            maxLines: 3,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    null,
                                                  ),
                                              child: Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    motivo,
                                                  ),
                                              child: Text(
                                                'Denunciar',
                                                style: TextStyle(
                                                  color: Colors.orange,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (result != null &&
                                        result.trim().isNotEmpty) {
                                      try {
                                        await denunciarPost(
                                          idPost!,
                                          result.trim(),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Denúncia enviada!'),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Erro ao denunciar post',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    debugPrint(
                                      '❌ Erro em denunciar (menu): $e',
                                    );
                                  }
                                });
                              },
                              child: Text(
                                'Denunciar',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                      icon: Icon(Icons.more_vert),
                    ),

                  Spacer(),
                  Text(
                    topico['datahora'] != null
                        ? DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(DateTime.parse(topico['datahora']).toLocal())
                        : '',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),

              SizedBox(height: 8),

              Text(
                topico['titulo'] ?? '',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(topico['texto'] ?? ''),

              // Mostrar URL se existir
              if (topico['url'] != null && topico['url'].toString().isNotEmpty)
                _buildUrlSection(topico['url'].toString()),

              // Mostrar anexo/ficheiro se existir
              if (topico['anexo'] != null &&
                  topico['anexo'].toString().isNotEmpty)
                _buildAnexoSection(topico['anexo'].toString()),

              SizedBox(height: 8),

              // Linha com ícones, comentários, partilha, bookmark, likes e dislikes
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey),
                  SizedBox(width: 4),
                  FutureBuilder<int>(
                    future:
                        idPost != null
                            ? fetchNumeroRespostas(idPost)
                            : Future.value(0),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text('...');
                      }
                      if (snapshot.hasError) {
                        return Text('0');
                      }
                      return Text('${snapshot.data ?? 0}');
                    },
                  ),
                  SizedBox(width: 16),

                  Icon(Icons.share_outlined, size: 20, color: Colors.grey),
                  SizedBox(width: 16),

                  IconButton(
                    icon: Icon(
                      guardados.contains(postId)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      size: 20,
                      color: Colors.blue,
                    ),
                    onPressed: () async {
                      if (currentUser == null) return;
                      if (guardados.contains(postId)) {
                        await removerGuardado(currentUser!.id, postId);
                        setState(() {
                          guardados.remove(postId);
                        });
                      } else {
                        await guardarPost(currentUser!.id, postId);
                        setState(() {
                          guardados.add(postId);
                        });
                      }
                    },
                  ),
                  SizedBox(width: 8),

                  // Botão Responder ao lado do bookmark
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ConversaPage(
                                topico: topico,
                                nomeUtilizador:
                                    currentUser?.nome ?? 'Utilizador',
                                idUtilizador:
                                    currentUser?.id ??
                                    0, // <-- ADICIONA ESTA LINHA
                              ),
                        ),
                      );
                      setState(
                        () {},
                      ); // Atualiza o número de comentários ao voltar
                    },
                    icon: Icon(Icons.reply, size: 18, color: Colors.blue),
                    label: Text(
                      'Responder',
                      style: TextStyle(color: Colors.blue),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),

                  Spacer(),

                  // Botão Like
                  GestureDetector(
                    onTap: () async {
                      if (currentUser == null) return;
                      final bool estavaLiked = likedPosts.contains(postId);
                      setState(() {
                        if (estavaLiked) {
                          likedPosts.remove(postId);
                        } else {
                          likedPosts.add(postId);
                          dislikedPosts.remove(postId);
                        }
                      });
                      if (estavaLiked) {
                        await removerLikeDislike(currentUser!.id, postId);
                      } else {
                        await likePost(currentUser!.id, postId);
                      }
                      // NÃO faças await fetchLikesDislikes aqui!
                    },
                    child: Icon(
                      Icons.thumb_up_alt_outlined,
                      size: 20,
                      color:
                          likedPosts.contains(postId)
                              ? Colors.green
                              : Colors.grey,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text('${likes + (likedPosts.contains(postId) ? 1 : 0)}'),

                  SizedBox(width: 8),

                  // Botão Dislike
                  GestureDetector(
                    onTap: () async {
                      if (currentUser == null) return;
                      final bool estavaDisliked = dislikedPosts.contains(
                        postId,
                      );
                      setState(() {
                        if (estavaDisliked) {
                          dislikedPosts.remove(postId);
                        } else {
                          dislikedPosts.add(postId);
                          likedPosts.remove(postId);
                        }
                      });
                      if (estavaDisliked) {
                        await removerLikeDislike(currentUser!.id, postId);
                      } else {
                        await dislikePost(currentUser!.id, postId);
                      }
                      // NÃO faças await fetchLikesDislikes aqui!
                    },
                    child: Icon(
                      Icons.thumb_down_alt_outlined,
                      size: 20,
                      color:
                          dislikedPosts.contains(postId)
                              ? Colors.red
                              : Colors.grey,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${dislikes + (dislikedPosts.contains(postId) ? 1 : 0)}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForumDrawer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionTitleStyle = TextStyle(
      color: isDark ? Colors.grey[400] : Colors.grey[700],
      fontWeight: FontWeight.bold,
      fontSize: 13,
      letterSpacing: 0.5,
    );

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.blue.shade50,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  radius: 28,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLoadingUser
                          ? 'A Carregar ...'
                          : (currentUser?.nome ?? 'Utilizador'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Conta pessoal',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('Conta', style: sectionTitleStyle),
          ),
          _buildDrawerItem(Icons.person_outline, 'Perfil', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PerfilPage()),
            );
          }),
          _buildDrawerItem(Icons.bookmark_border, 'Guardados', () async {
            final topicosList = await topicos;
            final guardadosPosts =
                topicosList.where((t) {
                  final id =
                      t['idpost'] ?? t['id'] ?? t['idforum'] ?? t.hashCode;
                  return guardados.contains(id);
                }).toList();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => GuardadosPage(
                      guardadosPosts: guardadosPosts,
                      nomeUtilizador: currentUser?.nome ?? 'Utilizador',
                      idUtilizador: currentUser?.id ?? 0,
                    ),
              ),
            );
          }),
          Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('Fórum', style: sectionTitleStyle),
          ),
          // Botão para ver todos os tópicos
          ListTile(
            leading: Icon(Icons.list, color: Colors.blue),
            title: Text('Todos os tópicos'),
            onTap: () {
              setState(() {
                selectedTopicoId = null;
                Navigator.pop(context);
              });
            },
          ),
          // Drawer dinâmico
          FutureBuilder<List<dynamic>>(
            future: fetchCategoriasAreasTopicos(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LinearProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Erro ao carregar categorias'),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Nenhuma categoria encontrada'),
                );
              } else {
                final categorias = snapshot.data!;
                return Column(
                  children: [
                    for (final categoria in categorias)
                      ExpansionTile(
                        leading: Icon(Icons.folder, color: Colors.blue),
                        title: Text(categoria['nome']),
                        children: [
                          for (final area in categoria['areas'])
                            ExpansionTile(
                              leading: Icon(
                                Icons.folder_open,
                                color: Colors.blue,
                              ),
                              title: Text(area['nome']),
                              children: [
                                for (final topico in area['topicos'])
                                  ListTile(
                                    leading: Icon(
                                      Icons.label_outline,
                                      color: Colors.blue,
                                    ),
                                    title: Text(topico['nome']),
                                    onTap: () {
                                      setState(() {
                                        selectedTopicoId = topico['idtopicos'];
                                        Navigator.pop(context);
                                      });
                                    },
                                  ),
                              ],
                            ),
                        ],
                      ),
                  ],
                );
              }
            },
          ),
          Divider(),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: Colors.blue, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
      minLeadingWidth: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Future<void> criarTopico(
    String nome,
    String descricao,
    bool estado,
    int? idtopico,
    String? url, // Novo parâmetro para URL
  ) async {
    // Validar e corrigir URL se fornecida
    String urlFinal = '';
    if (url != null && url.trim().isNotEmpty) {
      urlFinal = _corrigirUrl(url.trim());
      if (!_isValidUrl(urlFinal)) {
        throw Exception('URL inválida: $urlFinal');
      }
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/forum/posts'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'idutilizador': currentUser?.id,
        'titulo': nome,
        'texto': descricao,
        'anexo': '',
        'url': urlFinal, // Usar URL corrigida
        'idtopico': idtopico,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Falha ao criar post');
    }
  }

  // Este fetchTopicos é só para os posts, não mexas
  Future<List<dynamic>> fetchTopicos() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/forum/topicos'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Cache local (best-effort)
        try {
          await LocalDatabase.upsertPostsForum(
            List<Map<String, dynamic>>.from(
              data.map((e) => Map<String, dynamic>.from(e as Map)),
            ),
          );
          final locais = await LocalDatabase.listarTodosPostsForum();
          print('[Forum] Upsert concluído. Posts locais: ${locais.length}');
        } catch (_) {}
        print('[Forum] Dados da API recebidos: ${data.length} posts');
        return data;
      } else {
        throw Exception('Falha ao carregar tópicos');
      }
    } catch (e) {
      // Fallback local
      try {
        final locais = await LocalDatabase.listarTodosPostsForum();
        print('[Forum] Fallback local ativado. Posts locais: ${locais.length}');
        return locais
            .map((row) => {
                  'idpost': row['id'],
                  'autor': row['autor_nome'],
                  'idtopico': row['topico_id'],
                  'datahora': row['datahora'],
                  'titulo': row['titulo'] ?? (row['conteudo'] ?? '').toString(),
                  'texto': row['conteudo'] ?? '',
                  'anexo': row['ficheiro'],
                  'url': row['url'],
                  'idutilizador': row['autor_id'],
                  'likes': 0,
                  'dislikes': 0,
                })
            .toList();
      } catch (_) {
        rethrow;
      }
    }
  }

  Future<int> fetchNumeroRespostas(int idTopico) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.respostasUrl}/$idTopico'),
    );
    if (response.statusCode == 200) {
      final respostas = jsonDecode(response.body);
      return respostas.length;
    }
    return 0;
  }

  Future<void> eliminarPost(int idPost) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/forum/posts/$idPost'),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao eliminar post');
    }
    setState(() {
      topicos = fetchTopicos();
    });
  }

  // Widget para mostrar URL de forma amigável
  Widget _buildUrlSection(String url) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.link, color: Colors.blue[600], size: 20),
          SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _abrirUrl(url),
              child: Text(
                _formatUrl(url),
                style: TextStyle(
                  color: Colors.blue[600],
                  decoration: TextDecoration.underline,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar anexo/ficheiro
  Widget _buildAnexoSection(String anexoUrl) {
    final fileName = _getFileNameFromUrl(anexoUrl);
    final fileExtension = _getFileExtension(fileName);
    final IconData fileIcon = _getFileIcon(fileExtension);

    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(fileIcon, color: Colors.green[600], size: 20),
          SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _abrirFicheiro(anexoUrl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ficheiro anexado:',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 2),
                  Text(
                    fileName,
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          Icon(Icons.download, color: Colors.green[600], size: 18),
        ],
      ),
    );
  }

  // Função para selecionar ficheiro
  Future<void> _selecionarFicheiro() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'jpg',
        'jpeg',
        'png',
        'zip',
        'txt',
      ],
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  // Função para criar post com ficheiro
  Future<void> _criarPostComFicheiro() async {
    if (_selectedFile == null) return;

    try {
      // Validar URL se fornecida
      String urlFinal = '';
      if (_urlController.text.trim().isNotEmpty) {
        urlFinal = _corrigirUrl(_urlController.text.trim());
        if (!_isValidUrl(urlFinal)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('URL inválida: ${_urlController.text}')),
          );
          return;
        }
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/forum/posts/com-ficheiro'),
      );

      // Adicionar campos de texto
      request.fields['idutilizador'] = currentUser?.id.toString() ?? '';
      request.fields['titulo'] = _nomeController.text;
      request.fields['texto'] = _descricaoController.text;
      request.fields['url'] = urlFinal; // Usar URL corrigida
      request.fields['idtopico'] = _topicoSelecionado.toString();

      // Adicionar ficheiro
      request.files.add(
        await http.MultipartFile.fromPath('ficheiro', _selectedFile!.path!),
      );

      var response = await request.send();

      if (response.statusCode != 201) {
        throw Exception('Falha ao criar post com ficheiro');
      }

      print('✅ Post com ficheiro criado com sucesso');
    } catch (e) {
      print('❌ Erro ao criar post com ficheiro: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao enviar ficheiro: $e')));
    }
  }

  // Funções helper
  String _formatUrl(String url) {
    // Remover protocolo e www para display mais limpo
    String display = url
        .replaceFirst(RegExp(r'https?://'), '')
        .replaceFirst('www.', '');

    // Se for muito longo, cortar
    if (display.length > 50) {
      display = '${display.substring(0, 47)}...';
    }

    return display;
  }

  // Função para validar e corrigir URLs
  String _corrigirUrl(String url) {
    if (url.isEmpty) return '';

    // Se já tem protocolo, retorna como está
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Se não tem, adiciona https://
    return 'https://$url';
  }

  // Função para validar URL
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // Função melhorada para abrir URLs
  Future<void> _abrirUrl(String url) async {
    try {
      print('🔗 Tentando abrir URL: $url');

      // Garantir que o URL tem protocolo
      String urlFinal = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        urlFinal = 'https://$url';
        print('🔗 URL corrigido para: $urlFinal');
      }

      final uri = Uri.parse(urlFinal);
      print('🔗 URI criado: $uri');

      // Tentar diferentes abordagens
      bool sucesso = false;

      // Tentativa 1: Verificar com canLaunchUrl e abrir
      try {
        if (await canLaunchUrl(uri)) {
          print('🔗 canLaunchUrl = true, abrindo...');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          sucesso = true;
        }
      } catch (e) {
        print('❌ Erro na tentativa 1: $e');
      }

      // Tentativa 2: Abrir diretamente sem verificação
      if (!sucesso) {
        try {
          print('🔗 Tentativa 2: Abrindo diretamente...');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          sucesso = true;
          print('✅ Sucesso na tentativa 2');
        } catch (e) {
          print('❌ Erro na tentativa 2: $e');
        }
      }

      // Tentativa 3: Usar modo platformDefault
      if (!sucesso) {
        try {
          print('🔗 Tentativa 3: Usando platformDefault...');
          await launchUrl(uri, mode: LaunchMode.platformDefault);
          sucesso = true;
          print('✅ Sucesso na tentativa 3');
        } catch (e) {
          print('❌ Erro na tentativa 3: $e');
        }
      }

      // Tentativa 4: Tentar com inAppWebView
      if (!sucesso) {
        try {
          print('🔗 Tentativa 4: Usando inAppWebView...');
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
          sucesso = true;
          print('✅ Sucesso na tentativa 4');
        } catch (e) {
          print('❌ Erro na tentativa 4: $e');
        }
      }

      if (!sucesso) {
        print('❌ Todas as tentativas falharam');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível abrir o link. Instale um navegador web.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Erro geral ao abrir URL: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao processar o link')));
    }
  }

  // Função para abrir ficheiros
  Future<void> _abrirFicheiro(String anexoUrl) async {
    try {
      print('📁 Tentando abrir ficheiro: $anexoUrl');

      // Verificar se é um URL válido
      if (!anexoUrl.startsWith('http://') && !anexoUrl.startsWith('https://')) {
        print('❌ URL do ficheiro não tem protocolo: $anexoUrl');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('URL do ficheiro inválido')));
        return;
      }

      final uri = Uri.parse(anexoUrl);
      print('📁 URI do ficheiro: $uri');

      // Tentar abrir o ficheiro
      bool sucesso = false;

      // Tentativa 1: Abrir diretamente
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        sucesso = true;
        print('✅ Ficheiro aberto com sucesso');
      } catch (e) {
        print('❌ Erro na tentativa 1: $e');

        // Tentativa 2: Usar modo platformDefault
        try {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
          sucesso = true;
          print('✅ Ficheiro aberto com platformDefault');
        } catch (e2) {
          print('❌ Erro na tentativa 2: $e2');
        }
      }

      if (!sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir o ficheiro')),
        );
      }
    } catch (e) {
      print('❌ Erro ao abrir ficheiro: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao abrir ficheiro: $e')));
    }
  }

  String _getFileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    if (segments.isNotEmpty) {
      return segments.last;
    }
    return 'Ficheiro';
  }

  String _getFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot != -1) {
      return fileName.substring(lastDot + 1).toLowerCase();
    }
    return '';
  }

  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'zip':
      case 'rar':
        return Icons.archive;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      default:
        return Icons.attach_file;
    }
  }

  // ===== FUNCIONALIDADES PARA SUGERIR TÓPICOS =====

  void _mostrarModalSugerirTopico() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ModalSugerirTopico(
          userId: currentUser?.id ?? 0,
          onPedidoCriado: () {
            // Callback quando o pedido for criado com sucesso
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Pedido de tópico enviado com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      },
    );
  }
}

// ===== MODAL PARA SUGERIR TÓPICOS =====

class ModalSugerirTopico extends StatefulWidget {
  final int userId;
  final VoidCallback onPedidoCriado;

  const ModalSugerirTopico({
    super.key,
    required this.userId,
    required this.onPedidoCriado,
  });

  @override
  _ModalSugerirTopicoState createState() => _ModalSugerirTopicoState();
}

class _ModalSugerirTopicoState extends State<ModalSugerirTopico> {
  final _formKey = GlobalKey<FormState>();
  final _topicoController = TextEditingController();
  final _topicoSugeridoController = TextEditingController();
  final _categoriaSugeridaController = TextEditingController();
  final _areaSugeridaController = TextEditingController();

  List<dynamic> _categorias = [];
  List<dynamic> _areas = [];
  int? _categoriaSelecionada;
  int? _areaSelecionada;
  bool _loadingCategorias = true;
  bool _loadingAreas = false;
  bool _enviandoPedido = false;

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
  }

  Future<void> _carregarCategorias() async {
    try {
      print('🔄 Iniciando carregamento de categorias...');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/forum-pedidos/categorias'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 Status da resposta: ${response.statusCode}');
      print('📄 Body da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 Dados decodificados: $data');

        if (data['success']) {
          print('✅ Success = true, categorias: ${data['categorias']}');
          setState(() {
            _categorias = data['categorias'];
            _loadingCategorias = false;
          });
          print('📋 Categorias carregadas na variável: $_categorias');
        } else {
          print('❌ Success = false no response');
        }
      } else {
        print('❌ Erro ao carregar categorias: ${response.statusCode}');
        setState(() {
          _loadingCategorias = false;
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar categorias: $e');
      setState(() {
        _loadingCategorias = false;
      });
    }
  }

  Future<void> _carregarAreas(int categoriaId) async {
    setState(() {
      _loadingAreas = true;
      _areaSelecionada = null;
      _areas = [];
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/forum-pedidos/areas/$categoriaId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _areas = data['areas'];
            _loadingAreas = false;
          });
        }
      } else {
        print('❌ Erro ao carregar áreas: ${response.statusCode}');
        setState(() {
          _loadingAreas = false;
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar áreas: $e');
      setState(() {
        _loadingAreas = false;
      });
    }
  }

  Future<void> _enviarPedido() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _enviandoPedido = true;
    });

    try {
      final body = <String, dynamic>{'user_id': widget.userId};

      // Adicionar categoria (existente ou sugerida)
      if (_categoriaSelecionada != null && _categoriaSelecionada != -1) {
        body['categoria_id'] = _categoriaSelecionada!;
      } else {
        body['categoria_sugerida'] = _categoriaSugeridaController.text.trim();
      }

      // Adicionar área (existente ou sugerida)
      if (_areaSelecionada != null && _areaSelecionada != -1) {
        body['area_id'] = _areaSelecionada!;
      } else {
        body['area_sugerida'] = _areaSugeridaController.text.trim();
      }

      // Adicionar tópico sugerido
      body['topico_sugerido'] = _topicoSugeridoController.text.trim();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/forum-pedidos/pedidos'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          widget.onPedidoCriado();
          Navigator.of(context).pop();
        } else {
          _mostrarErro(data['message'] ?? 'Erro desconhecido');
        }
      } else {
        _mostrarErro('Erro no servidor: ${response.statusCode}');
      }
    } catch (e) {
      _mostrarErro('Erro de conexão: $e');
    } finally {
      setState(() {
        _enviandoPedido = false;
      });
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ $mensagem'), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Color.fromARGB(255, 178, 68, 119),
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pedir Novo Tópico',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Categoria
                        Text(
                          'Categoria',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        _loadingCategorias
                            ? LinearProgressIndicator()
                            : Builder(
                              builder: (context) {
                                print(
                                  '🏗️ Construindo dropdown - Loading: $_loadingCategorias, Categorias: $_categorias',
                                );
                                return DropdownButtonFormField<int>(
                                  value: _categoriaSelecionada,
                                  decoration: InputDecoration(
                                    hintText: 'Selecione uma categoria',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  items: [
                                    ..._categorias.map<DropdownMenuItem<int>>((
                                      cat,
                                    ) {
                                      return DropdownMenuItem<int>(
                                        value: cat['id'],
                                        child: Text(cat['nome']),
                                      );
                                    }),
                                    DropdownMenuItem<int>(
                                      value: -1,
                                      child: Text(
                                        'Outra (sugerir nova categoria)',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Color.fromARGB(
                                            255,
                                            178,
                                            68,
                                            119,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _categoriaSelecionada = value;
                                      if (value != null && value != -1) {
                                        _carregarAreas(value);
                                      } else {
                                        _areas = [];
                                        _areaSelecionada = null;
                                      }
                                    });
                                  },
                                  validator:
                                      (value) =>
                                          value == null
                                              ? 'Selecione uma categoria'
                                              : null,
                                );
                              },
                            ),

                        // Campo de categoria sugerida (se "Outra" for selecionada)
                        if (_categoriaSelecionada == -1) ...[
                          SizedBox(height: 12),
                          TextFormField(
                            controller: _categoriaSugeridaController,
                            decoration: InputDecoration(
                              labelText: 'Nome da nova categoria',
                              hintText: 'Ex: Inteligência Artificial',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            validator:
                                (value) =>
                                    value?.trim().isEmpty ?? true
                                        ? 'Digite o nome da categoria'
                                        : null,
                          ),
                        ],

                        SizedBox(height: 16),

                        // Área
                        Text(
                          'Área',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        _categoriaSelecionada == null ||
                                _categoriaSelecionada == -1
                            ? Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Primeiro selecione uma categoria',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                            : _loadingAreas
                            ? LinearProgressIndicator()
                            : DropdownButtonFormField<int>(
                              value: _areaSelecionada,
                              decoration: InputDecoration(
                                hintText: 'Selecione uma área',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              items: [
                                ..._areas.map<DropdownMenuItem<int>>((area) {
                                  return DropdownMenuItem<int>(
                                    value: area['id'],
                                    child: Text(area['nome']),
                                  );
                                }),
                                DropdownMenuItem<int>(
                                  value: -1,
                                  child: Text(
                                    'Outra (sugerir nova área)',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Color.fromARGB(255, 178, 68, 119),
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _areaSelecionada = value;
                                });
                              },
                              validator:
                                  (value) =>
                                      value == null
                                          ? 'Selecione uma área'
                                          : null,
                            ),

                        // Campo de área sugerida (se "Outra" for selecionada)
                        if (_areaSelecionada == -1) ...[
                          SizedBox(height: 12),
                          TextFormField(
                            controller: _areaSugeridaController,
                            decoration: InputDecoration(
                              labelText: 'Nome da nova área',
                              hintText: 'Ex: Machine Learning',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            validator:
                                (value) =>
                                    value?.trim().isEmpty ?? true
                                        ? 'Digite o nome da área'
                                        : null,
                          ),
                        ],

                        SizedBox(height: 16),

                        // Tópico
                        Text(
                          'Tópico',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        _areaSelecionada == null || _areaSelecionada == -1
                            ? Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Primeiro selecione uma área',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                            : TextFormField(
                              controller: _topicoSugeridoController,
                              decoration: InputDecoration(
                                labelText: 'Nome do novo tópico',
                                hintText: 'Ex: Introdução ao TensorFlow',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              validator:
                                  (value) =>
                                      value?.trim().isEmpty ?? true
                                          ? 'Digite o nome do tópico'
                                          : null,
                            ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Botões de ação
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Cancelar'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _enviandoPedido ? null : _enviarPedido,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 178, 68, 119),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child:
                            _enviandoPedido
                                ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : Text('Enviar Pedido'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _topicoController.dispose();
    _topicoSugeridoController.dispose();
    _categoriaSugeridaController.dispose();
    _areaSugeridaController.dispose();
    super.dispose();
  }
}
