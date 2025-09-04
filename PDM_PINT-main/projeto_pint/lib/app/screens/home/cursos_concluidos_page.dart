import 'package:flutter/material.dart';

class CursosConcluidosPage extends StatelessWidget {
  const CursosConcluidosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        automaticallyImplyLeading: true,
        title: const Text(
          'Progresso',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            fontFamily: 'Roboto',
          ),
        ),
      ),
      body: Center(
        child: Text(
          'Cursos Concluídos',
          style: TextStyle(fontSize: 24, color: Colors.black54),
        ),
      ),
    );
  }
}