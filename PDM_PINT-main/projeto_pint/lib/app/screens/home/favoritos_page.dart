// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:projeto_pint/app/routes/route_names.dart';
// import '../../services/curso_service.dart';
// import '../../models/curso_model.dart';
// import '../courses/curso_detail_page.dart';
// import 'dart:convert'; 
// import 'dart:typed_data'; 

// class FavoritosPage extends StatefulWidget {
//   const FavoritosPage({super.key});

//   @override
//   State<FavoritosPage> createState() => _FavoritosPageState();
// }

// class _FavoritosPageState extends State<FavoritosPage> {
//   bool _isLoading = true;
//   List<Curso> _cursosFavoritos = [];

//   @override
//   void initState() {
//     super.initState();
//     _carregarFavoritos();
//   }

//   Future<void> _carregarFavoritos() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final favoritos = await CursoService.buscarFavoritos();

//       if (mounted) {
//         setState(() {
//           _cursosFavoritos = favoritos;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Erro ao carregar favoritos: $e');
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F1FA),
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () {
//             // Verificar se pode fazer pop, senão volta para home
//             if (Navigator.canPop(context)) {
//               Navigator.pop(context);
//             } else {
//               context.go(RouteNames.home);
//             }
//           },
//         ),
//         title: const Text(
//           'Cursos Favoritos',
//           style: TextStyle(
//             color: Colors.black,
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//       body: RefreshIndicator(
//         onRefresh: _carregarFavoritos,
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             // Mostrar spinner durante carregamento
//             if (_isLoading)
//               const Center(
//                 child: Padding(
//                   padding: EdgeInsets.all(32.0),
//                   child: CircularProgressIndicator(),
//                 ),
//               )
//             // Mostrar lista de favoritos
//             else
//               _buildCursosFavoritos(),
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         backgroundColor: Colors.white,
//         selectedItemColor: Colors.blue,
//         unselectedItemColor: Colors.grey.shade400,
//         showSelectedLabels: false,
//         showUnselectedLabels: false,
//         elevation: 0,
//         currentIndex: 2,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: ""),
//           BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), label: ""),
//           BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: ""),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings_outlined),
//             label: "",
//           ),
//         ],
//         onTap: (index) {
//           switch (index) {
//             case 0:
//               context.go(RouteNames.home);
//               break;
//             case 1:
//               context.go(RouteNames.forum);
//               break;
//             case 2:
//               // Já está na página de favoritos, não faz nada
//               break;
//             case 3:
//               context.go(RouteNames.settings);
//               break;
//             default:
//               break;
//           }
//         },
//       ),
//     );
//   }

//   Widget _buildCursosFavoritos() {
//     if (_cursosFavoritos.isEmpty) {
//       return _buildEmptyState(
//         'Nenhum curso favorito ainda',
//         'Explore os cursos disponíveis e marque seus favoritos tocando no ícone de marcador. Eles aparecerão aqui para acesso rápido.',
//         Icons.bookmark_border,
//       );
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(Icons.bookmark, color: Colors.blue[600], size: 24),
//             const SizedBox(width: 8),
//             Text(
//               'Os seus cursos favoritos',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//             const Spacer(),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(
//                 color: Colors.blue[50],
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: Colors.blue[200]!),
//               ),
//               child: Text(
//                 '${_cursosFavoritos.length} ${_cursosFavoritos.length == 1 ? 'curso' : 'cursos'}',
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.blue[700],
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),
//         ...List.generate(_cursosFavoritos.length, (index) {
//           final curso = _cursosFavoritos[index];
//           return _buildCursoCard(curso);
//         }),
//       ],
//     );
//   }

//   Widget _buildEmptyState(String title, String message, IconData icon) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 80, color: Colors.grey[400]),
//             const SizedBox(height: 16),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[700],
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 12),
//             Text(
//               message,
//               style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: () {
//                 context.go(RouteNames.cursos);
//               },
//               icon: const Icon(Icons.explore),
//               label: const Text('Explorar cursos'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 24,
//                   vertical: 12,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Widget _buildCursoCard(Curso curso) {
//   //   return GestureDetector(
//   //     onTap: () {
//   //       Navigator.push(
//   //         context,
//   //         MaterialPageRoute(
//   //           builder: (context) => CursoDetailPage(curso: curso),
//   //         ),
//   //       ).then((_) => _carregarFavoritos());
//   //     },
//   //     child: Container(
//   //       margin: const EdgeInsets.only(bottom: 16),
//   //       decoration: BoxDecoration(
//   //         color: Colors.white,
//   //         borderRadius: BorderRadius.circular(12),
//   //         boxShadow: [
//   //           BoxShadow(
//   //             color: Colors.black.withOpacity(0.05),
//   //             blurRadius: 10,
//   //             offset: const Offset(0, 2),
//   //           ),
//   //         ],
//   //       ),
//   //       child: Column(
//   //         crossAxisAlignment: CrossAxisAlignment.start,
//   //         children: [
//   //           // Imagem do curso
//   //           ClipRRect(
//   //             borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//   //             child: curso.imagemUrl != null && curso.imagemUrl!.isNotEmpty
//   //               ? Image.network(
//   //                   curso.imagemUrl!.startsWith('http')
//   //                     ? curso.imagemUrl!
//   //                     : '${ApiConfig.baseUrl}/${curso.imagemUrl!}',
//   //                   height: 120,
//   //                   width: double.infinity,
//   //                   fit: BoxFit.cover,
//   //                   errorBuilder: (context, error, stackTrace) {
//   //                     return Image.asset(
//   //                       'assets/cursos.png',
//   //                       height: 120,
//   //                       width: double.infinity,
//   //                       fit: BoxFit.cover,
//   //                     );
//   //                   },
//   //                 )
//   //               : Image.asset(
//   //                   'assets/cursos.png',
//   //                   height: 120,
//   //                   width: double.infinity,
//   //                   fit: BoxFit.cover,
//   //                 ),
//   //           ),

//   //           // Conteúdo do curso
//   //           Padding(
//   //             padding: const EdgeInsets.all(16),
//   //             child: Column(
//   //               crossAxisAlignment: CrossAxisAlignment.start,
//   //               children: [
//   //                 // Título
//   //                 Text(
//   //                   curso.titulo,
//   //                   style: const TextStyle(
//   //                     fontSize: 18,
//   //                     fontWeight: FontWeight.bold,
//   //                   ),
//   //                   maxLines: 2,
//   //                   overflow: TextOverflow.ellipsis,
//   //                 ),
//   //                 const SizedBox(height: 8),

//   //                 // Avaliação
//   //                 if (curso.avaliacao != null)
//   //                   Row(
//   //                     children: [
//   //                       ...List.generate(5, (index) {
//   //                         return Icon(
//   //                           index < (curso.avaliacao ?? 0).floor()
//   //                               ? Icons.star
//   //                               : index < (curso.avaliacao ?? 0)
//   //                                   ? Icons.star_half
//   //                                   : Icons.star_border,
//   //                           color: Colors.amber,
//   //                           size: 18,
//   //                         );
//   //                       }),
//   //                       const SizedBox(width: 8),
//   //                       Text(
//   //                         curso.avaliacao?.toStringAsFixed(1) ?? '0.0',
//   //                         style: const TextStyle(
//   //                           fontSize: 14,
//   //                           fontWeight: FontWeight.w500,
//   //                         ),
//   //                       ),
//   //                     ],
//   //                   ),
//   //                 const SizedBox(height: 8),

//   //                 // Descrição
//   //                 Text(
//   //                   curso.descricao,
//   //                   style: TextStyle(
//   //                     fontSize: 14,
//   //                     color: Colors.grey[700],
//   //                   ),
//   //                   maxLines: 2,
//   //                   overflow: TextOverflow.ellipsis,
//   //                 ),
//   //                 const SizedBox(height: 12),

//   //                 // Botões de ação
//   //                 Row(
//   //                   children: [
//   //                     // Badge de dificuldade
//   //                     Container(
//   //                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//   //                       decoration: BoxDecoration(
//   //                         color: curso.corDificuldade,
//   //                         borderRadius: BorderRadius.circular(20),
//   //                       ),
//   //                       child: Text(
//   //                         curso.nivelDificuldade,
//   //                         style: const TextStyle(
//   //                           color: Colors.white,
//   //                           fontSize: 12,
//   //                           fontWeight: FontWeight.w600,
//   //                         ),
//   //                       ),
//   //                     ),
//   //                     const Spacer(),
//   //                     // Botão de remover dos favoritos
//   //                     IconButton(
//   //                       icon: const Icon(Icons.bookmark, color: Colors.yellow),
//   //                       onPressed: () async {
//   //                         final removido = await CursoService.removerDosFavoritos(curso.id!);
//   //                         if (removido) {
//   //                           _carregarFavoritos();
//   //                           ScaffoldMessenger.of(context).showSnackBar(
//   //                             const SnackBar(
//   //                               content: Text('Curso removido dos favoritos'),
//   //                               backgroundColor: Colors.red,
//   //                             ),
//   //                           );
//   //                         }
//   //                       },
//   //                     ),
//   //                   ],
//   //                 ),
//   //               ],
//   //             ),
//   //           ),
//   //         ],
//   //       ),
//   //     ),
//   //   );
//   // }^

//   Widget _buildCursoCard(Curso curso) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => CursoDetailPage(curso: curso),
//           ),
//         ).then((_) => _carregarFavoritos());
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Imagem do curso
//             ClipRRect(
//               borderRadius: const BorderRadius.vertical(
//                 top: Radius.circular(12),
//               ),
//               child: _buildCourseImage(curso),
//             ),

//             // Conteúdo do curso
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Título
//                   Text(
//                     curso.titulo,
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 8),

//                   // Avaliação
//                   if (curso.avaliacao != null)
//                     Row(
//                       children: [
//                         ...List.generate(5, (index) {
//                           return Icon(
//                             index < (curso.avaliacao ?? 0).floor()
//                                 ? Icons.star
//                                 : index < (curso.avaliacao ?? 0)
//                                 ? Icons.star_half
//                                 : Icons.star_border,
//                             color: Colors.amber,
//                             size: 18,
//                           );
//                         }),
//                         const SizedBox(width: 8),
//                         Text(
//                           curso.avaliacao?.toStringAsFixed(1) ?? '0.0',
//                           style: const TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   const SizedBox(height: 8),

//                   // Descrição
//                   Text(
//                     curso.descricao,
//                     style: TextStyle(fontSize: 14, color: Colors.grey[700]),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 12),

//                   // Botões de ação
//                   Row(
//                     children: [
//                       // Badge de dificuldade
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 6,
//                         ),
//                         decoration: BoxDecoration(
//                           color: curso.corDificuldade,
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Text(
//                           curso.nivelDificuldade,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                       const Spacer(),
//                       // Botão de remover dos favoritos
//                       IconButton(
//                         icon: const Icon(Icons.bookmark, color: Colors.yellow),
//                         onPressed: () async {
//                           final removido =
//                               await CursoService.removerDosFavoritos(curso.id!);
//                           if (removido) {
//                             _carregarFavoritos();
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text('Curso removido dos favoritos'),
//                                 backgroundColor: Colors.red,
//                               ),
//                             );
//                           }
//                         },
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCourseImage(Curso curso) {
//     if (curso.imagemUrl == null || curso.imagemUrl!.isEmpty) {
//       return _buildAssetImageFallback(curso.tema);
//     }

//     print(
//       '🖼️ Processando imagem: ${curso.imagemUrl} para curso: ${curso.titulo}',
//     );

//     // Primeiro, tentar como URL completa
//     if (curso.imagemUrl!.startsWith('http')) {
//       return Image.network(
//         curso.imagemUrl!,
//         height: 120,
//         width: double.infinity,
//         fit: BoxFit.cover,
//         loadingBuilder: (context, child, loadingProgress) {
//           if (loadingProgress == null) return child;
//           return Container(
//             height: 120,
//             width: double.infinity,
//             child: Center(
//               child: CircularProgressIndicator(
//                 value:
//                     loadingProgress.expectedTotalBytes != null
//                         ? loadingProgress.cumulativeBytesLoaded /
//                             loadingProgress.expectedTotalBytes!
//                         : null,
//               ),
//             ),
//           );
//         },
//         errorBuilder: (context, error, stackTrace) {
//           print('❌ Erro ao carregar URL: ${curso.imagemUrl} - $error');
//           return _buildAssetImageFallback(curso.tema);
//         },
//       );
//     }

//     // Se contém dados Base64
//     if (curso.imagemUrl!.startsWith('data:image')) {
//       final imageData = _decodeBase64Image(curso.imagemUrl!);
//       return imageData != null
//           ? Image.memory(
//             imageData,
//             height: 120,
//             width: double.infinity,
//             fit: BoxFit.cover,
//             errorBuilder: (context, error, stackTrace) {
//               return _buildAssetImageFallback(curso.tema);
//             },
//           )
//           : _buildAssetImageFallback(curso.tema);
//     }

//     // Se é um nome de arquivo, construir URL do servidor
//     if (curso.imagemUrl!.contains('.')) {
//       // Primeiro tentar no diretório uploads
//       final serverUrl = '${ApiConfig.uploadsUrl}/${curso.imagemUrl!}';
//       print('🔗 Tentando carregar do servidor: $serverUrl');
//       return Image.network(
//         serverUrl,
//         height: 120,
//         width: double.infinity,
//         fit: BoxFit.cover,
//         errorBuilder: (context, error, stackTrace) {
//           print('❌ Erro ao carregar do servidor: $serverUrl - $error');
//           // Se falhar, tentar como asset
//           return _buildAssetImageFallback(curso.tema);
//         },
//       );
//     }

//     // Tentar como Base64 sem prefixo
//     final imageData = _decodeBase64Image(curso.imagemUrl!);
//     return imageData != null
//         ? Image.memory(
//           imageData,
//           height: 120,
//           width: double.infinity,
//           fit: BoxFit.cover,
//           errorBuilder: (context, error, stackTrace) {
//             return _buildAssetImageFallback(curso.tema);
//           },
//         )
//         : _buildAssetImageFallback(curso.tema);
//   }

//   // Decodificar imagem base64
//   Uint8List? _decodeBase64Image(String base64String) {
//     try {
//       // Verificar se é realmente Base64 ou apenas um nome de arquivo
//       if (base64String.endsWith('.jpg') ||
//           base64String.endsWith('.png') ||
//           base64String.endsWith('.jpeg') ||
//           base64String.endsWith('.gif') ||
//           base64String.length < 50) {
//         // É apenas um nome de arquivo, não Base64
//         return null;
//       }

//       // Remover prefixo data:image se existir
//       String cleanBase64 = base64String;
//       if (base64String.startsWith('data:image')) {
//         cleanBase64 = base64String.split(',').last;
//       }

//       // Tentar decodificar Base64
//       return base64Decode(cleanBase64);
//     } catch (e) {
//       // Se falhar na decodificação, retornar null (usar placeholder)
//       print('⚠️ Erro ao decodificar imagem Base64: $e');
//       return null;
//     }
//   }

//   // Widget que usa imagens dos assets baseado no tema do curso
//   Widget _buildAssetImageFallback(String? tema) {
//     String assetImage;

//     // Mapear tema para imagem do asset baseado nos dados reais da BD
//     switch (tema?.toLowerCase()) {
//       case 'programação':
//       case 'programacao':
//         assetImage = 'assets/python.png';
//         break;
//       case 'desenvolvimento mobile':
//         assetImage = 'assets/frontend.png';
//         break;
//       case 'desenvolvimento web':
//         assetImage = 'assets/html.png';
//         break;
//       case 'finanças em python':
//       case 'financas em python':
//         assetImage = 'assets/finanças.jpeg';
//         break;
//       case 'teste':
//         assetImage = 'assets/cursos.png';
//         break;
//       case 'sdvsdvsdv':
//       case 'dwefsfsefsf':
//       case 'clsdjcsdc':
//       case 'teste1':
//         // Para dados de teste/placeholder
//         assetImage = 'assets/cursos.png';
//         break;
//       default:
//         assetImage = 'assets/cursos.png';
//     }

//     return Image.asset(
//       assetImage,
//       height: 120,
//       width: double.infinity,
//       fit: BoxFit.cover,
//       errorBuilder: (context, error, stackTrace) {
//         print('❌ Erro ao carregar asset: $assetImage');
//         return Container(
//           height: 120,
//           width: double.infinity,
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Colors.blue.withOpacity(0.8),
//                 Colors.purple.withOpacity(0.8),
//               ],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//           child: Icon(
//             Icons.school,
//             size: 60,
//             color: Colors.white.withOpacity(0.8),
//           ),
//         );
//       },
//     );
//   }
// }



// --------------------------------------------------------------------------------------


import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projeto_pint/app/routes/route_names.dart';
import '../../services/curso_service.dart';
import '../../models/curso_model.dart';
import '../courses/curso_detail_page.dart';
import 'dart:convert'; 
import 'dart:typed_data';
import '../../../config/api_config.dart';

class FavoritosPage extends StatefulWidget {
  const FavoritosPage({super.key});

  @override
  State<FavoritosPage> createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  bool _isLoading = true;
  List<Curso> _cursosFavoritos = [];

  @override
  void initState() {
    super.initState();
    _carregarFavoritos();
  }

  Future<void> _carregarFavoritos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final favoritos = await CursoService.buscarFavoritos();
      
      if (mounted) {
        setState(() {
          _cursosFavoritos = favoritos;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar favoritos: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildCourseImage(Curso curso) {
    if (curso.imagemUrl == null || curso.imagemUrl!.isEmpty) {
      return _buildAssetImageFallback(curso.tema);
    }

    print('🖼️ Processando imagem: ${curso.imagemUrl} para curso: ${curso.titulo}');
    
    // Primeiro, tentar como URL completa
    if (curso.imagemUrl!.startsWith('http')) {
      return Image.network(
        curso.imagemUrl!,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            height: 120,
            width: double.infinity,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ Erro ao carregar URL: ${curso.imagemUrl} - $error');
          return _buildAssetImageFallback(curso.tema);
        },
      );
    }
    
    // Se contém dados Base64
    if (curso.imagemUrl!.startsWith('data:image')) {
      final imageData = _decodeBase64Image(curso.imagemUrl!);
      return imageData != null
          ? Image.memory(
            imageData,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildAssetImageFallback(curso.tema);
            },
          )
          : _buildAssetImageFallback(curso.tema);
    }
    
    // Se é um nome de arquivo, construir URL do servidor
    if (curso.imagemUrl!.contains('.')) {
      // Primeiro tentar no diretório uploads
      final serverUrl = '${ApiConfig.uploadsUrl}/${curso.imagemUrl!}';
      print('🔗 Tentando carregar do servidor: $serverUrl');
      return Image.network(
        serverUrl,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Erro ao carregar do servidor: $serverUrl - $error');
          // Se falhar, tentar como asset
          return _buildAssetImageFallback(curso.tema);
        },
      );
    }
    
    // Tentar como Base64 sem prefixo
    final imageData = _decodeBase64Image(curso.imagemUrl!);
    return imageData != null
        ? Image.memory(
          imageData,
          height: 120,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildAssetImageFallback(curso.tema);
          },
        )
        : _buildAssetImageFallback(curso.tema);
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
      height: 120,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('❌ Erro ao carregar asset: $assetImage');
        return Container(
          height: 120,
          width: double.infinity,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Verificar se pode fazer pop, senão volta para home
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go(RouteNames.home);
            }
          },
        ),
        title: const Text(
          'Cursos Favoritos', 
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          )
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _carregarFavoritos,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Mostrar spinner durante carregamento
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            // Mostrar lista de favoritos
            else
              _buildCursosFavoritos(),
          ],
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
        currentIndex: 2,
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
              context.go(RouteNames.forum);
              break;
            case 2:
              // Já está na página de favoritos, não faz nada
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

  Widget _buildCursosFavoritos() {
    if (_cursosFavoritos.isEmpty) {
      return _buildEmptyState(
        'Nenhum curso favorito ainda',
        'Explore os cursos disponíveis e marque seus favoritos tocando no ícone de marcador. Eles aparecerão aqui para acesso rápido.',
        Icons.bookmark_border,
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.bookmark,
              color: Colors.blue[600],
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Os seus cursos favoritos',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                '${_cursosFavoritos.length} ${_cursosFavoritos.length == 1 ? 'curso' : 'cursos'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(_cursosFavoritos.length, (index) {
          final curso = _cursosFavoritos[index];
          return _buildCursoCard(curso);
        }),
      ],
    );
  }

  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.go(RouteNames.cursos);
              },
              icon: const Icon(Icons.explore),
              label: const Text('Explorar cursos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCursoCard(Curso curso) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CursoDetailPage(curso: curso),
          ),
        ).then((_) => _carregarFavoritos());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            // ✅ IMAGEM CORRIGIDA
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: _buildCourseImage(curso),
            ),
            
            // Conteúdo do curso
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    curso.titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Avaliação
                  if (curso.avaliacao != null)
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < (curso.avaliacao ?? 0).floor() 
                                ? Icons.star 
                                : index < (curso.avaliacao ?? 0) 
                                    ? Icons.star_half 
                                    : Icons.star_border,
                            color: Colors.amber,
                            size: 18,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          curso.avaliacao?.toStringAsFixed(1) ?? '0.0',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  
                  // Descrição
                  Text(
                    curso.descricao,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // Botões de ação
                  Row(
                    children: [
                      // Badge de dificuldade
                      Container(
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
                      const Spacer(),
                      // Botão de remover dos favoritos
                      IconButton(
                        icon: const Icon(Icons.bookmark, color: Colors.yellow),
                        onPressed: () async {
                          final removido = await CursoService.removerDosFavoritos(curso.id!);
                          if (removido) {
                            _carregarFavoritos();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Curso removido dos favoritos'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}