import 'package:flutter/material.dart';
import 'conversa_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GuardadosPage extends StatelessWidget {
  final List<dynamic> guardadosPosts;
  final String nomeUtilizador;
  final int idUtilizador; // ADICIONA ESTA LINHA

  const GuardadosPage({
    super.key,
    required this.guardadosPosts,
    required this.nomeUtilizador,
    required this.idUtilizador, // ADICIONA ESTA LINHA
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Guardados')),
      body: guardadosPosts.isEmpty
          ? Center(
              child: Text(
                'Ainda não guardaste nenhum post.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: guardadosPosts.length,
              itemBuilder: (context, index) {
                final post = guardadosPosts[index];
                final idPost = post['idpost'] ?? post['id'] ?? post['idforum'] ?? post.hashCode;
                final dataHoraStr = post['datahora'];
                String dataHoraFormatada = '';
                if (dataHoraStr != null) {
                  final dataHora = DateTime.tryParse(dataHoraStr);
                  if (dataHora != null) {
                    dataHoraFormatada = '${dataHora.day.toString().padLeft(2, '0')}/${dataHora.month.toString().padLeft(2, '0')}/${dataHora.year} ${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}';
                  }
                }
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ConversaPage(
                            topico: post,
                            nomeUtilizador: nomeUtilizador,
                            idUtilizador: idUtilizador, // ADICIONA ESTA LINHA
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Linha do avatar, autor, badge e data
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.green[100],
                                child: Icon(Icons.person, color: Colors.green[800]),
                              ),
                              SizedBox(width: 8),
                              Text(
                                post['autor'] ?? 'Desconhecido',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if ((post['topico'] ?? post['nome_topico']) != null) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    post['topico'] ?? post['nome_topico'] ?? 'Categoria',
                                    style: TextStyle(
                                      color: Colors.blue[900],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                              Spacer(),
                              if (dataHoraFormatada.isNotEmpty)
                                Text(
                                  dataHoraFormatada,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            post['titulo'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(post['texto'] ?? ''),
                          SizedBox(height: 12),
                          // Barra de ações
                          Row(
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey[700]),
                              SizedBox(width: 4),
                              FutureBuilder<int>(
                                future: fetchNumeroRespostas(idPost),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Text('...');
                                  }
                                  if (snapshot.hasError) {
                                    return Text('0');
                                  }
                                  return Text(
                                    '${snapshot.data ?? 0}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  );
                                },
                              ),
                              SizedBox(width: 16),
                              Icon(Icons.share, size: 20, color: Colors.grey[700]),
                              SizedBox(width: 16),
                              Icon(Icons.bookmark, size: 20, color: Colors.blue),
                              SizedBox(width: 16),
                              Icon(Icons.reply, size: 20, color: Colors.blue),
                              Text(
                                ' Responder',
                                style: TextStyle(color: Colors.blue, fontSize: 15),
                              ),
                              Spacer(),
                              // Likes e dislikes reais
                              FutureBuilder<Map<String, int>>(
                                future: fetchLikesDislikes(idPost),
                                builder: (context, snapshot) {
                                  final likes = snapshot.data?['likes'] ?? 0;
                                  final dislikes = snapshot.data?['dislikes'] ?? 0;
                                  return Row(
                                    children: [
                                      Icon(Icons.thumb_up_alt_outlined, size: 20, color: Colors.grey[700]),
                                      SizedBox(width: 4),
                                      Text('$likes'),
                                      SizedBox(width: 12),
                                      Icon(Icons.thumb_down_alt_outlined, size: 20, color: Colors.grey[700]),
                                      SizedBox(width: 4),
                                      Text('$dislikes'),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
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

Future<int> fetchNumeroRespostas(dynamic idForum) async {
  final response = await http.get(
    Uri.parse('http://localhost:3000/respostas/$idForum'),
  );
  if (response.statusCode == 200) {
    final respostas = jsonDecode(response.body);
    return respostas.length;
  }
  return 0;
}

// NOVO: Função para buscar likes/dislikes reais do backend
Future<Map<String, int>> fetchLikesDislikes(dynamic idPost) async {
  final response = await http.get(
    Uri.parse('http://localhost:3000/likes_forum/count/$idPost'),
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return {
      'likes': data['likes'] ?? 0,
      'dislikes': data['dislikes'] ?? 0,
    };
  }
  return {'likes': 0, 'dislikes': 0};
}