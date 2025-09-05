import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/curso_service.dart';
import 'package:projeto_pint/app/database/local_database.dart';
import '../../config/api_config.dart';

class ConversaPage extends StatefulWidget {
  final dynamic topico;
  final String nomeUtilizador;
  final int idUtilizador;

  const ConversaPage({
    super.key,
    required this.topico,
    required this.nomeUtilizador,
    required this.idUtilizador,
  });

  @override
  State<ConversaPage> createState() => _ConversaPageState();
}

class _ConversaPageState extends State<ConversaPage> {
  final TextEditingController _controller = TextEditingController();
  late Future<List<dynamic>> _respostasFuture;
  String? _respostaAtiva;
  final TextEditingController _respostaController = TextEditingController();

  // *** NOVO: Campos para URL e ficheiro ***
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _urlRespostaController = TextEditingController();
  PlatformFile? _selectedFile;
  PlatformFile? _selectedRespostaFile;

  Set<String> likedRespostas = {};
  Set<String> dislikedRespostas = {};

  Future<void> likeResposta(String idResposta) async {
    print('[Forum] Like -> user=${widget.idUtilizador}, post=$idResposta');
    await http.post(
      Uri.parse('${ApiConfig.likesForumUrl}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idutilizador': widget.idUtilizador, 
        'idpost': int.parse(idResposta),
        'tipo': 'like',
      }),
    );
    try {
      await LocalDatabase.salvarLikeForum(
        widget.idUtilizador,
        int.parse(idResposta),
        'like',
      );
      final likesUser = await LocalDatabase.obterLikesDoUtilizador(
        widget.idUtilizador,
      );
      print(
        '[Forum] Like salvo localmente. Total likes(user): ${likesUser.length}',
      );
    } catch (e) {
      print('[Forum] Erro ao salvar like local: $e');
    }
  }

  Future<void> dislikeResposta(String idResposta) async {
    print('[Forum] Dislike -> user=${widget.idUtilizador}, post=$idResposta');
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/likes_forum'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idutilizador': widget.idUtilizador, 
        'idpost': int.parse(idResposta),
        'tipo': 'dislike',
      }),
    );
    try {
      await LocalDatabase.salvarLikeForum(
        widget.idUtilizador,
        int.parse(idResposta),
        'dislike',
      );
      final likesUser = await LocalDatabase.obterLikesDoUtilizador(
        widget.idUtilizador,
      );
      print(
        '[Forum] Dislike salvo localmente. Total likes(user): ${likesUser.length}',
      );
    } catch (e) {
      print('[Forum] Erro ao salvar dislike local: $e');
    }
  }

  Future<void> removerLikeDislikeResposta(String idResposta) async {
    print(
      '[Forum] Remover Like/Dislike -> user=${widget.idUtilizador}, post=$idResposta',
    );
    await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/likes_forum'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idutilizador': widget.idUtilizador, 
        'idpost': int.parse(idResposta),
      }),
    );
    try {
      await LocalDatabase.removerLikeForum(
        widget.idUtilizador,
        int.parse(idResposta),
      );
      final likesUser = await LocalDatabase.obterLikesDoUtilizador(
        widget.idUtilizador,
      );
      print(
        '[Forum] Like/Dislike removido localmente. Total likes(user): ${likesUser.length}',
      );
    } catch (e) {
      print('[Forum] Erro ao remover like/dislike local: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    print('[ConversaPage] initState - topico: ${widget.topico}');
    print('[ConversaPage] initState - idpost: ${widget.topico['idpost']}');
    _respostasFuture = fetchRespostas();
    _carregarLikesLocais();
  }

  /// Carregar likes/dislikes do cache local
  Future<void> _carregarLikesLocais() async {
    try {
      final likes = await LocalDatabase.obterLikesDoUtilizador(
        widget.idUtilizador,
      );
      setState(() {
        for (final like in likes) {
          final postId = like['idpost'].toString();
          if (like['tipo'] == 'like') {
            likedRespostas.add(postId);
          } else if (like['tipo'] == 'dislike') {
            dislikedRespostas.add(postId);
          }
        }
      });
      print(
        '[ConversaPage] Likes locais carregados: ${likedRespostas.length} likes, ${dislikedRespostas.length} dislikes',
      );
    } catch (e) {
      print('[ConversaPage] Erro ao carregar likes locais: $e');
    }
  }

  Future<void> enviarResposta(
    String texto, {
    String? idRespostaPai,
    String? url,
    PlatformFile? ficheiro,
  }) async {
    print('🚀 enviarResposta chamada com:');
    print('   texto: $texto');
    print('   url: $url');
    print('   ficheiro: ${ficheiro?.name ?? 'null'}');
    print('   ficheiro != null: ${ficheiro != null}');

    if (ficheiro != null) {
      print('📁 Enviando resposta com ficheiro...');
      // Enviar resposta com ficheiro
      await _enviarRespostaComFicheiro(
        texto,
        ficheiro,
        idRespostaPai: idRespostaPai,
      );
    } else {
      print('📝 Enviando resposta normal...');
      // Enviar resposta normal (com ou sem URL)
      await http.post(
        Uri.parse('${ApiConfig.respostasUrl}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idpost': widget.topico['idpost'],
          'idutilizador': widget.idUtilizador,
          'autor': widget.nomeUtilizador,
          'texto': texto,
          'idrespostapai': idRespostaPai,
          'url': url, // *** NOVO: Incluir URL ***
        }),
      );
    }
    _refreshRespostas();
  }

  // *** NOVO: Método para enviar resposta com ficheiro ***
  Future<void> _enviarRespostaComFicheiro(
    String texto,
    PlatformFile ficheiro, {
    String? idRespostaPai,
  }) async {
    try {
      print('📤 Preparando upload para: ${ficheiro.name}');
      print('📏 Tamanho do ficheiro: ${ficheiro.size} bytes');
      print('🔗 Bytes disponíveis: ${ficheiro.bytes != null}');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.respostasUrl}/upload'),
      );

      request.fields.addAll({
        'idpost': widget.topico['idpost'].toString(),
        'idutilizador': widget.idUtilizador.toString(),
        'autor': widget.nomeUtilizador,
        'texto': texto,
        if (idRespostaPai != null) 'idrespostapai': idRespostaPai,
      });

      print('📋 Campos enviados: ${request.fields}');

      if (ficheiro.bytes != null) {
        print('📁 Adicionando ficheiro ao request...');
        request.files.add(
          http.MultipartFile.fromBytes(
            'ficheiro', // Nome do campo - deve corresponder ao multer
            ficheiro.bytes!,
            filename: ficheiro.name,
          ),
        );
        print('✅ Ficheiro adicionado: ${ficheiro.name}');
      } else {
        print('❌ Ficheiro sem bytes!');
      }

      print('🚀 Enviando request...');
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('📨 Status code: ${response.statusCode}');
      print('📨 Response body: $responseBody');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Erro ao enviar ficheiro: ${response.statusCode} - $responseBody',
        );
      }
    } catch (e) {
      print('❌ Erro detalhado no upload: $e');
      throw Exception('Erro ao enviar ficheiro: $e');
    }
  }

  // *** NOVO: Método para selecionar ficheiro ***
  Future<void> _selecionarFicheiro({bool paraResposta = false}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
      withData: true, // *** IMPORTANTE: Carrega os bytes do ficheiro ***
    );

    if (result != null) {
      final file = result.files.first;
      print('📁 Ficheiro selecionado: ${file.name}');
      print('📏 Tamanho: ${file.size} bytes');
      print('🔗 Bytes carregados: ${file.bytes != null}');

      setState(() {
        if (paraResposta && _respostaAtiva != null) {
          _selectedRespostaFile = file;
        } else {
          _selectedFile = file;
        }
      });
    }
  }

  // *** NOVO: Métodos auxiliares para ícones de ficheiro ***
  String _getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Em conversa_page.dart - modificar o método fetchRespostas
  Future<List<dynamic>> fetchRespostas() async {
    print(
      '[ConversaPage] fetchRespostas iniciado para post: ${widget.topico['idpost']}',
    );

    // Primeiro tentar buscar do cache local
    try {
      final locais = await LocalDatabase.listarRespostasPorPost(
        widget.topico['idpost'] as int,
      );
      print('[ConversaPage] Cache local retornou ${locais.length} respostas');

      if (locais.isNotEmpty) {
        // Mesmo com cache local, tentar atualizar da API em segundo plano
        _tryUpdateFromApiInBackground();
        return locais;
      }
    } catch (e) {
      print('[ConversaPage] Erro no cache local: $e');
    }

    // Se não há cache local, tentar API
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.respostasUrl}/${widget.topico['idpost']}',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('[ConversaPage] API retornou ${data.length} respostas');

        // Cache local das respostas
        try {
          final respostasComPostId =
              data.map((e) {
                final Map<String, dynamic> resposta = Map<String, dynamic>.from(
                  e as Map,
                );
                resposta['idpost'] = widget.topico['idpost'];
                return resposta;
              }).toList();

          await LocalDatabase.upsertRespostasForum(respostasComPostId);
          print('[ConversaPage] Respostas guardadas no cache local');
        } catch (e) {
          print('[ConversaPage] Erro ao guardar cache local: $e');
        }

        return data;
      }

      return [];
    } catch (e) {
      print('[ConversaPage] Erro na API: $e');
      // Fallback local final
      try {
        final locais = await LocalDatabase.listarRespostasPorPost(
          widget.topico['idpost'] as int,
        );
        print(
          '[ConversaPage] Fallback final local: ${locais.length} respostas',
        );
        return locais;
      } catch (e) {
        print('[ConversaPage] Erro no fallback final: $e');
        return [];
      }
    }
  }

  // Método auxiliar para atualizar da API em segundo plano
  void _tryUpdateFromApiInBackground() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.respostasUrl}/${widget.topico['idpost']}',
            ),
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Atualizar cache local
        final respostasComPostId =
            data.map((e) {
              final Map<String, dynamic> resposta = Map<String, dynamic>.from(
                e as Map,
              );
              resposta['idpost'] = widget.topico['idpost'];
              return resposta;
            }).toList();

        await LocalDatabase.upsertRespostasForum(respostasComPostId);
        print('[ConversaPage] Cache atualizado em segundo plano');

        // Atualizar UI se ainda estiver na mesma página
        if (mounted) {
          setState(() {
            _respostasFuture = Future.value(data);
          });
        }
      }
    } catch (e) {
      print('[ConversaPage] Atualização em segundo plano falhou: $e');
    }
  }

  Future<void> denunciarComentario(String idComentario) async {
    await http.post(
      Uri.parse('${ApiConfig.denunciaUrl}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idcomentario': int.parse(idComentario),
        'idutilizador': widget.idUtilizador,
        'motivo': 'Comentário impróprio', // Podes pedir motivo ao utilizador
        'idpost': null,
        'data': DateTime.now().toIso8601String(),
      }),
    );
  }

  Future<void> eliminarComentario(String idComentario) async {
    await http.delete(
      Uri.parse('${ApiConfig.respostasUrl}/$idComentario'),
    );
    _refreshRespostas();
  }

  void _refreshRespostas() {
    setState(() {
      _respostasFuture = fetchRespostas();
    });
  }

  void _ativarResposta(String idResposta) {
    setState(() {
      _respostaAtiva = idResposta;
      _respostaController.clear();
    });
  }

  void _cancelarResposta() {
    setState(() {
      _respostaAtiva = null;
      _respostaController.clear();
      _urlRespostaController.clear(); // *** NOVO: Limpar URL ***
      _selectedRespostaFile = null; // *** NOVO: Limpar ficheiro ***
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Conversa')),
      body: Column(
        children: [
          // Card da mensagem principal
          Card(
            color: Colors.blue[50],
            margin: EdgeInsets.fromLTRB(8, 16, 8, 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.topico['autor'] ?? 'Utilizador',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      if (widget.topico['datahora'] != null)
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(
                            DateTime.tryParse(widget.topico['datahora']) ??
                                DateTime.now(),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    widget.topico['titulo'] ?? '',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 6),
                  Text(
                    widget.topico['texto'] ?? '',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _respostasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar respostas'));
                }
                final respostas = snapshot.data ?? [];
                if (respostas.isEmpty) {
                  return Center(child: Text('Ainda não há respostas.'));
                }
                return ListView.builder(
                  itemCount: respostas.length,
                  itemBuilder: (context, index) {
                    final resposta = respostas[index];
                    final idResposta = resposta['idresposta'].toString();
                    final dataHoraStr = resposta['datahora'];
                    String dataHoraFormatada = '';
                    if (dataHoraStr != null) {
                      final dataHora = DateTime.tryParse(dataHoraStr);
                      if (dataHora != null) {
                        dataHoraFormatada = DateFormat(
                          'yyyy-MM-dd HH:mm',
                        ).format(dataHora);
                      }
                    }
                    final int likes = resposta['likes'] ?? 0;
                    final int dislikes = resposta['dislikes'] ?? 0;
                    final bool isLiked = likedRespostas.contains(idResposta);
                    final bool isDisliked = dislikedRespostas.contains(
                      idResposta,
                    );

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Linha do autor e data
                            Row(
                              children: [
                                Text(
                                  resposta['autor'] ?? 'Utilizador',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Spacer(),
                                if (dataHoraFormatada.isNotEmpty)
                                  Text(
                                    dataHoraFormatada,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'eliminar') {
                                      await eliminarComentario(
                                        resposta['idresposta'].toString(),
                                      );
                                    } else if (value == 'denunciar') {
                                      // 🔍 Verificar permissão antes de denunciar
                                      final permitido =
                                          await CursoService.permissaoLigacaoEspecifica(
                                            15,
                                          );
                                      if (!permitido) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '⚠️ A funcionalidade de denúncia está desativada.',
                                            ),
                                          ),
                                        );
                                        return; // ❌ não deixa prosseguir
                                      }

                                      // ✅ Só chega aqui se tiver permissão
                                      await denunciarComentario(
                                        resposta['idresposta'].toString(),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Comentário denunciado!',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  itemBuilder: (context) {
                                    List<PopupMenuEntry<String>> items = [];
                                    if (resposta['idutilizador'] ==
                                        widget.idUtilizador) {
                                      items.add(
                                        PopupMenuItem(
                                          value: 'eliminar',
                                          child: Text(
                                            'Eliminar',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      );
                                    }
                                    if (resposta['idutilizador'] !=
                                        widget.idUtilizador) {
                                      items.add(
                                        PopupMenuItem(
                                          value: 'denunciar',
                                          child: Text(
                                            'Denunciar',
                                            style: TextStyle(
                                              color: Colors.amber[800],
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return items;
                                  },
                                  icon: Icon(Icons.more_vert),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            // Mostra se é resposta a outra resposta
                            if (resposta['idrespostapai'] != null &&
                                resposta['resposta_pai_autor'] != null) ...[
                              Container(
                                margin: EdgeInsets.only(bottom: 6),
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border(
                                    left: BorderSide(
                                      color: Colors.blue,
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      resposta['resposta_pai_autor'] ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[800],
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      resposta['resposta_pai_texto'] ?? '',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey[700],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            Text(
                              resposta['texto'] ?? '',
                              style: TextStyle(fontSize: 15),
                            ),

                            // *** NOVO: Exibir URL se existir ***
                            if (resposta['url'] != null &&
                                resposta['url'].toString().isNotEmpty) ...[
                              SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final url = resposta['url'].toString();
                                  if (await canLaunchUrl(Uri.parse(url))) {
                                    await launchUrl(
                                      Uri.parse(url),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue[200]!,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.link,
                                        color: Colors.blue,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          resposta['url'].toString(),
                                          style: TextStyle(
                                            color: Colors.blue,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            // *** NOVO: Exibir anexo se existir ***
                            if (resposta['anexo'] != null &&
                                resposta['anexo'].toString().isNotEmpty) ...[
                              SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final anexoUrl = resposta['anexo'].toString();
                                  if (await canLaunchUrl(Uri.parse(anexoUrl))) {
                                    await launchUrl(
                                      Uri.parse(anexoUrl),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green[200]!,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.attachment,
                                        color: Colors.green,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Ficheiro anexado',
                                          style: TextStyle(
                                            color: Colors.green[800],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.download,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            SizedBox(height: 8),
                            // Botão Responder
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () => _ativarResposta(idResposta),
                                  child: Text(
                                    'Responder',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ),
                                Spacer(),
                                GestureDetector(
                                  onTap: () async {
                                    final bool estavaLiked = likedRespostas
                                        .contains(idResposta);
                                    setState(() {
                                      if (estavaLiked) {
                                        likedRespostas.remove(idResposta);
                                      } else {
                                        likedRespostas.add(idResposta);
                                        dislikedRespostas.remove(idResposta);
                                      }
                                    });
                                    if (estavaLiked) {
                                      await removerLikeDislikeResposta(
                                        idResposta,
                                      );
                                    } else {
                                      await likeResposta(idResposta);
                                    }
                                  },
                                  child: Icon(
                                    Icons.thumb_up_alt_outlined,
                                    size: 20,
                                    color:
                                        likedRespostas.contains(idResposta)
                                            ? Colors.green
                                            : Colors.grey,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${likes + (likedRespostas.contains(idResposta) ? 1 : 0)}',
                                ),
                                SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final bool estavaDisliked =
                                        dislikedRespostas.contains(idResposta);
                                    setState(() {
                                      if (estavaDisliked) {
                                        dislikedRespostas.remove(idResposta);
                                      } else {
                                        dislikedRespostas.add(idResposta);
                                        likedRespostas.remove(idResposta);
                                      }
                                    });
                                    if (estavaDisliked) {
                                      await removerLikeDislikeResposta(
                                        idResposta,
                                      );
                                    } else {
                                      await dislikeResposta(idResposta);
                                    }
                                  },
                                  child: Icon(
                                    Icons.thumb_down_alt_outlined,
                                    size: 20,
                                    color:
                                        dislikedRespostas.contains(idResposta)
                                            ? Colors.red
                                            : Colors.grey,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${dislikes + (dislikedRespostas.contains(idResposta) ? 1 : 0)}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_respostaAtiva != null)
            FutureBuilder<List<dynamic>>(
              future: _respostasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return SizedBox.shrink();
                }
                final respostas = snapshot.data ?? [];
                final respostaPai = respostas.firstWhere(
                  (r) => r['idresposta'].toString() == _respostaAtiva,
                  orElse: () => null,
                );
                if (respostaPai == null) return SizedBox.shrink();
                return Container(
                  margin: EdgeInsets.fromLTRB(12, 0, 12, 4),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(color: Colors.blue, width: 4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.nomeUtilizador} a responder a ${respostaPai['autor'] ?? 'Utilizador'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              respostaPai['texto'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey),
                        onPressed: _cancelarResposta,
                        tooltip: 'Cancelar resposta',
                      ),
                    ],
                  ),
                );
              },
            ),
          // Campo de resposta global expandido
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Column(
              children: [
                // Campo de texto principal
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller:
                            _respostaAtiva == null
                                ? _controller
                                : _respostaController,
                        decoration: InputDecoration(
                          hintText: 'Escreva a sua resposta...',
                          border: OutlineInputBorder(),
                        ),
                        minLines: 1,
                        maxLines: 3,
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final texto =
                            (_respostaAtiva == null
                                    ? _controller.text
                                    : _respostaController.text)
                                .trim();
                        if (texto.isEmpty) return;

                        // *** NOVO: Obter URL e ficheiro conforme o contexto ***
                        final url =
                            (_respostaAtiva == null
                                ? _urlController.text.trim()
                                : _urlRespostaController.text.trim());
                        final ficheiro =
                            _respostaAtiva == null
                                ? _selectedFile
                                : _selectedRespostaFile;

                        await enviarResposta(
                          texto,
                          idRespostaPai: _respostaAtiva,
                          url:
                              url.isNotEmpty
                                  ? url
                                  : null, // *** NOVO: Passar URL ***
                          ficheiro: ficheiro, // *** NOVO: Passar ficheiro ***
                        );

                        // Limpar campos
                        if (_respostaAtiva == null) {
                          _controller.clear();
                          _urlController.clear();
                          _selectedFile = null;
                        } else {
                          _respostaController.clear();
                          _urlRespostaController.clear();
                          _selectedRespostaFile = null;
                          _cancelarResposta();
                        }
                        _refreshRespostas();
                        setState(() {}); // Atualizar UI
                      },
                      child: Text('Enviar'),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // *** NOVO: Campo de URL ***
                TextField(
                  controller:
                      _respostaAtiva == null
                          ? _urlController
                          : _urlRespostaController,
                  decoration: InputDecoration(
                    hintText: 'URL (opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link, size: 18),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: TextInputType.url,
                ),
                SizedBox(height: 8),
                // *** NOVO: Seção para anexo de ficheiro ***
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.attach_file,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: () {
                          final file =
                              _respostaAtiva == null
                                  ? _selectedFile
                                  : _selectedRespostaFile;
                          return file != null
                              ? Row(
                                children: [
                                  Icon(
                                    _getFileIcon(_getFileExtension(file.name)),
                                    color: Colors.green[600],
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      file.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        if (_respostaAtiva == null) {
                                          _selectedFile = null;
                                        } else {
                                          _selectedRespostaFile = null;
                                        }
                                      });
                                    },
                                    icon: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    constraints: BoxConstraints(),
                                    padding: EdgeInsets.all(2),
                                  ),
                                ],
                              )
                              : Text(
                                'Anexar ficheiro (opcional)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              );
                        }(),
                      ),
                      TextButton(
                        onPressed:
                            () => _selecionarFicheiro(
                              paraResposta: _respostaAtiva != null,
                            ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue[600],
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        child: Text(
                          'Selecionar',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
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
