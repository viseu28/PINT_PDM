import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../widgets/notification_badge.dart';
import '../../config/api_config.dart';


class PercursoFormativoPage extends StatefulWidget {
  final int idUtilizador;
  const PercursoFormativoPage({super.key, required this.idUtilizador});

  @override
  State<PercursoFormativoPage> createState() => _PercursoFormativoPageState();
}

class _PercursoFormativoPageState extends State<PercursoFormativoPage> {
  List<dynamic> cursos = [];
  bool loading = true;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    fetchPercurso();
  }

  Future<void> fetchPercurso() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/percursoformativo/${widget.idUtilizador}')
      );
      print('Resposta status: ${response.statusCode}');
      print('Body: ${response.body}');
      if (response.statusCode == 200) {
        dynamic data;
        try {
          data = json.decode(response.body);
        } catch (e) {
          setState(() {
            loading = false;
            errorMsg = 'Erro ao fazer parsing do JSON: $e';
          });
          return;
        }
        List<dynamic> cursosList = [];
        if (data is Map && data.containsKey('data') && data['data'] is List) {
          cursosList = data['data'];
        } else if (data is List) {
          cursosList = data;
        } else {
          setState(() {
            loading = false;
            errorMsg = 'Resposta inesperada do backend.';
          });
          return;
        }
        setState(() {
          cursos = cursosList;
          loading = false;
          errorMsg = null;
        });
      } else {
        setState(() {
          loading = false;
          errorMsg = 'Erro ao carregar dados: status ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMsg = 'Erro de ligação ou parsing: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3FA),
        elevation: 0,
        title: const Text(
          'Percurso Formativo', 
          style: TextStyle(
            fontFamily: 'BebasNeue', 
            fontSize: 28, 
            color: Colors.black
          ),
          overflow: TextOverflow.visible,
        ),
        titleSpacing: 0,
        actions: [
          const NotificationBadge(),
          IconButton(icon: const Icon(Icons.account_circle, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg != null
              ? Center(child: Text(errorMsg!, style: const TextStyle(color: Colors.red)))
              : cursos.isEmpty
                  ? const Center(child: Text('Nenhum curso encontrado.'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      separatorBuilder: (context, index) => const Divider(height: 32),
                      itemCount: cursos.length,
                      itemBuilder: (context, index) {
                        final curso = cursos[index];
                        return Card(
                          color: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Imagem do curso
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: _buildCursoImage(curso),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Info do curso
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        curso['nome_curso'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                      ),
                                      const SizedBox(height: 8),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            const TextSpan(text: 'Data de Conclusão: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                            TextSpan(text: curso['data_fim'] != null ? curso['data_fim'].toString().split('T')[0] : '---'),
                                          ],
                                        ),
                                      ),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            const TextSpan(text: 'Número de Horas: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                            TextSpan(text: '40 horas'), // Valor fixo de 40 horas
                                          ],
                                        ),
                                      ),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            const TextSpan(text: 'Horas Presença: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                            TextSpan(text: '${curso['horas_presenca'] ?? '---'} horas'),
                                          ],
                                        ),
                                      ),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            const TextSpan(text: 'Nota Final: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                            TextSpan(text: curso['nota'] != null ? curso['nota'].toString() : '---'),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: 180,
                                        child: curso['nota'] != null
                                            ? ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF4CB6E6),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                onPressed: () async {
                                                  final url = '${ApiConfig.baseUrl}${curso['certificado']}';
                                                  try {
                                                    final response = await http.get(Uri.parse(url));
                                                    if (response.statusCode == 200) {
                                                      final bytes = response.bodyBytes;
                                                      final dir = await getTemporaryDirectory();
                                                      final file = File('${dir.path}/certificado_${curso['idinscricao']}.pdf');
                                                      await file.writeAsBytes(bytes);
                                                      await OpenFilex.open(file.path);
                                                    } else {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text('Erro ao baixar certificado: \\${response.statusCode}'))
                                                      );
                                                    }
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Erro: \\${e.toString()}'))
                                                    );
                                                  }
                                                },
                                                child: const Text('Baixar Certificado'),
                                              )
                                            : const Text(
                                                'Não pode baixar o certificado',
                                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                                              ),
                                      ),
                                    ],
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

  // Método para processar e exibir imagens dos cursos
  Widget _buildCursoImage(dynamic curso) {
    final imagemUrl = curso['imagem_url'];
    
    // Debug: imprimir dados do curso para ver o que está chegando
    print('📊 DEBUG DETALHADO - Curso: ${curso['nome_curso']}');
    print('🖼️ DEBUG - imagem_url: $imagemUrl');
    print('� DEBUG - tipo de imagem_url: ${imagemUrl.runtimeType}');
    print('🔍 DEBUG - length: ${imagemUrl?.toString().length ?? 'null'}');
    print('🏷️ DEBUG - tema: ${curso['tema']}');
    print('🏷️ DEBUG - tipo_curso: ${curso['tipo_curso']}');
    print('📚 DEBUG - nome_curso: ${curso['nome_curso']}');
    print('---');
    
    if (imagemUrl == null || imagemUrl.toString().isEmpty) {
      print('⚠️ Sem imagem_url, usando fallback para tema: ${curso['tipo_curso'] ?? curso['tema']}');
      return _buildAssetImageFallback(curso['tipo_curso'] ?? curso['tema']);
    }

    String imagemString = imagemUrl.toString();
    print('🖼️ Processando imagem: ${imagemString.length > 100 ? "${imagemString.substring(0, 100)}..." : imagemString} para curso: ${curso['nome_curso']}');
    
    // Primeiro, tentar como URL completa
    if (imagemString.startsWith('http')) {
      print('🌐 Detectado como URL HTTP: ${imagemString.length > 50 ? "${imagemString.substring(0, 50)}..." : imagemString}');
      return Image.network(
        imagemString,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Erro ao carregar URL: $imagemString - $error');
          return _buildAssetImageFallback(curso['tipo_curso'] ?? curso['tema']);
        },
      );
    }
    
    // Se contém dados Base64
    if (imagemString.startsWith('data:image')) {
      print('📄 Detectado como Base64 com prefixo data:image');
      final imageData = _decodeBase64Image(imagemString);
      return imageData != null
          ? Image.memory(
            imageData,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Erro ao exibir Base64 com prefixo: $error');
              return _buildAssetImageFallback(curso['tipo_curso'] ?? curso['tema']);
            },
          )
          : _buildAssetImageFallback(curso['tipo_curso'] ?? curso['tema']);
    }
    
    // Se é um nome de arquivo, construir URL do servidor
    if (imagemString.contains('.') && !imagemString.contains(',')) {
      final serverUrl = '${ApiConfig.uploadsUrl}/$imagemString';
      print('🔗 Detectado como arquivo, tentando servidor: $serverUrl');
      return Image.network(
        serverUrl,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Erro ao carregar do servidor: $serverUrl - $error');
          return _buildAssetImageFallback(curso['tipo_curso'] ?? curso['tema']);
        },
      );
    }
    
    // Verificar se é Base64 "puro" (sem prefixo data:image)
    // Base64 geralmente tem caracteres específicos e é longo
    if (imagemString.length > 100 && 
        RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(imagemString)) {
      print('📄 Detectado como Base64 sem prefixo (puro)');
      final imageData = _decodeBase64Image(imagemString);
      return imageData != null
          ? Image.memory(
            imageData,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Erro ao exibir Base64 puro: $error');
              return _buildAssetImageFallback(curso['tipo_curso'] ?? curso['tema']);
            },
          )
          : _buildAssetImageFallback(curso['tipo_curso'] ?? curso['tema']);
    }
    
    // Se nada funcionou, tentar forçar como Base64
    print('🔄 Tentando forçar como Base64...');
    final imageData = _decodeBase64Image(imagemString);
    return imageData != null
        ? Image.memory(
          imageData,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Erro ao forçar Base64: $error');
            return _buildAssetImageFallback(curso['tipo_curso'] ?? curso['tema']);
          },
        )
        : () {
          print('❌ Todos os métodos falharam, usando fallback');
          return _buildAssetImageFallback(curso['tipo_curso'] ?? curso['tema']);
        }();
  }

  // Decodificar imagem base64
  Uint8List? _decodeBase64Image(String base64String) {
    try {
      // Verificar se é realmente Base64 ou apenas um nome de arquivo
      if (base64String.endsWith('.jpg') ||
          base64String.endsWith('.png') ||
          base64String.endsWith('.jpeg') ||
          base64String.endsWith('.gif') ||
          base64String.length < 50) {
        // É apenas um nome de arquivo, não Base64
        return null;
      }

      // Remover prefixo data:image se existir
      String cleanBase64 = base64String;
      if (base64String.startsWith('data:image')) {
        cleanBase64 = base64String.split(',').last;
      }

      // Tentar decodificar Base64
      return base64Decode(cleanBase64);
    } catch (e) {
      // Se falhar na decodificação, retornar null (usar placeholder)
      print('⚠️ Erro ao decodificar imagem Base64: $e');
      return null;
    }
  }

  // Widget que usa imagens dos assets baseado no tema do curso
  Widget _buildAssetImageFallback(String? tema) {
    String assetImage;
    
    // Mapear tema para imagem do asset baseado nos dados reais da BD
    switch (tema?.toLowerCase()) {
      case 'programação':
      case 'programacao':
        assetImage = 'assets/python.png';
        break;
      case 'desenvolvimento mobile':
        assetImage = 'assets/frontend.png';
        break;
      case 'desenvolvimento web':
        assetImage = 'assets/html.png';
        break;
      case 'finanças em python':
      case 'financas em python':
        assetImage = 'assets/finanças.jpeg';
        break;
      case 'teste':
        assetImage = 'assets/cursos.png';
        break;
      case 'sdvsdvsdv':
      case 'dwefsfsefsf':
      case 'clsdjcsdc':
      case 'teste1':
        // Para dados de teste/placeholder
        assetImage = 'assets/cursos.png';
        break;
      default:
        assetImage = 'assets/cursos.png';
    }

    return Image.asset(
      assetImage,
      width: 64,
      height: 64,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('❌ Erro ao carregar asset: $assetImage');
        return _buildImagePlaceholder();
      },
    );
  }

  // Widget placeholder para quando não há imagem
  Widget _buildImagePlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.8),
            Colors.purple.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.school, size: 32, color: Colors.white.withOpacity(0.8)),
    );
  }
}