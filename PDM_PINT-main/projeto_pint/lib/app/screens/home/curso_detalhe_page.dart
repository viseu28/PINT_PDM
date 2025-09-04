import 'package:flutter/material.dart';
import 'package:projeto_pint/app/models/curso_model.dart';

class CursoDetalhePage extends StatelessWidget {
  final Curso curso;
  const CursoDetalhePage({super.key, required this.curso});

  @override
  Widget build(BuildContext context) {
    print('A construir detalhe para: ${curso.titulo}');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: const Color(0xFFF7F4FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (curso.imagemUrl != null && curso.imagemUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: curso.imagemUrl!.toLowerCase().startsWith('http')
                  ? Image.network(
                      curso.imagemUrl!,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      curso.imagemUrl!,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
              )
            else
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.image, size: 64, color: Colors.grey),
              ),
            const SizedBox(height: 16),
            Text(
              curso.titulo,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              curso.descricao,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Formador:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text(curso.formadorResponsavel ?? '---'),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5CA9F7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  child: const Text('Ver Perfil', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }


}
