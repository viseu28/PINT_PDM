import 'package:flutter/material.dart';
import '../../services/curso_service.dart';

class QuizPage extends StatefulWidget {
  final Map<String, dynamic> quiz;
  final int cursoId;
  final String userId;

  const QuizPage({
    super.key,
    required this.quiz,
    required this.cursoId,
    required this.userId,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _quizDetalhes;
  final Map<int, String> _respostas = {}; // perguntaId -> resposta selecionada
  bool _carregando = true;
  bool _submetendo = false;
  List<dynamic> _questoes = [];

  @override
  void initState() {
    super.initState();
    _carregarQuizDetalhes();
  }

  Future<void> _carregarQuizDetalhes() async {
    try {
      setState(() => _carregando = true);

      final detalhes = await CursoService.buscarQuiz(
        widget.quiz['id'],
        widget.userId,
      );

      if (detalhes != null && mounted) {
        setState(() {
          _quizDetalhes = detalhes;
          _questoes = detalhes['questoes'] ?? [];
          
          // Inicializar TabController com base no número de questões
          _tabController = TabController(
            length: _questoes.length + 1, // +1 para tab de revisão
            vsync: this,
          );
          
          _carregando = false;
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar detalhes do quiz: $e');
      if (mounted) {
        setState(() => _carregando = false);
        _mostrarErro('Erro ao carregar quiz');
      }
    }
  }

  void _selecionarResposta(int perguntaId, String opcao) {
    setState(() {
      _respostas[perguntaId] = opcao;
    });
  }

  Future<void> _submeterQuiz() async {
    if (_respostas.length < _questoes.length) {
      _mostrarErro('Por favor, responda a todas as perguntas antes de submeter.');
      return;
    }

    try {
      setState(() => _submetendo = true);

      // Preparar respostas no formato esperado pela API
      final respostasFormatadas = _questoes.asMap().entries.map((entry) {
        final index = entry.key;
        final questao = entry.value;
        final perguntaId = questao['id'] ?? index;
        final respostaSelecionada = _respostas[perguntaId] ?? '';

        return {
          'pergunta_id': perguntaId,
          'resposta': respostaSelecionada,
        };
      }).toList();

      final resultado = await CursoService.submeterQuiz(
        widget.quiz['id'],
        widget.userId,
        respostasFormatadas,
      );

      if (resultado != null && mounted) {
        _mostrarResultado(resultado);
      }
    } catch (e) {
      print('❌ Erro ao submeter quiz: $e');
      _mostrarErro('Erro ao submeter quiz. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _submetendo = false);
      }
    }
  }

  void _mostrarResultado(Map<String, dynamic> resultado) {
    // Mostrar notificação rápida de sucesso
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quiz submetido com sucesso!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    
    // Redirecionamento direto para a página do curso
    Navigator.of(context).pop(); // Voltar para página do curso
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.quiz['titulo'] ?? 'Quiz'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_quizDetalhes == null || _questoes.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.quiz['titulo'] ?? 'Quiz'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Não foi possível carregar as questões do quiz.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz['titulo'] ?? 'Quiz'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.blue[50],
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                ..._questoes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final questao = entry.value;
                  final perguntaId = questao['id'] ?? index;
                  final respondida = _respostas.containsKey(perguntaId);
                  
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          respondida ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 16,
                          color: respondida ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text('${index + 1}'),
                      ],
                    ),
                  );
                }),
                const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment_turned_in, size: 16),
                      SizedBox(width: 4),
                      Text('Revisar'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ..._questoes.asMap().entries.map((entry) {
            final index = entry.key;
            final questao = entry.value;
            return _buildQuestaoTab(questao, index);
          }),
          _buildRevisaoTab(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              '${_respostas.length}/${_questoes.length} respondidas',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _submetendo ? null : _submeterQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: _respostas.length == _questoes.length ? Colors.green : Colors.grey,
              ),
              child: _submetendo
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Submeter Quiz'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestaoTab(Map<String, dynamic> questao, int index) {
    final perguntaId = questao['id'] ?? index;
    final pergunta = questao['pergunta'] ?? '';
    final opcoes = questao['opcoes'] as List<dynamic>? ?? [];
    final pontos = questao['pontos'] ?? 0;
    final respostaSelecionada = _respostas[perguntaId];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho da pergunta
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        pergunta,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (pontos > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '($pontos pontos)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Aviso
              if (widget.quiz['completo'] != true)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    border: Border.all(color: Colors.orange[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Atenção: Este quiz só pode ser respondido uma vez. Revise suas respostas antes de submeter.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Opções de resposta
              ...opcoes.asMap().entries.map((entry) {
                final opcaoIndex = entry.key;
                final opcao = entry.value;
                final letra = String.fromCharCode(65 + opcaoIndex); // A, B, C, D...
                final isSelected = respostaSelecionada == letra;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _selecionarResposta(perguntaId, letra),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[50] : Colors.grey[50],
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                letra,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              opcao.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                color: isSelected ? Colors.blue[700] : Colors.black87,
                                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevisaoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Revisão das Respostas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              ..._questoes.asMap().entries.map((entry) {
                final index = entry.key;
                final questao = entry.value;
                final perguntaId = questao['id'] ?? index;
                final pergunta = questao['pergunta'] ?? '';
                final respostaSelecionada = _respostas[perguntaId];
                final respondida = respostaSelecionada != null;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: respondida ? Colors.green[50] : Colors.red[50],
                    border: Border.all(
                      color: respondida ? Colors.green[200]! : Colors.red[200]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: respondida ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
                              pergunta,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              respondida ? 'Resposta: $respostaSelecionada' : 'Não respondida',
                              style: TextStyle(
                                fontSize: 12,
                                color: respondida ? Colors.green[700] : Colors.red[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        respondida ? Icons.check_circle : Icons.error,
                        color: respondida ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                );
              }),
              
              const SizedBox(height: 20),
              
              // Resumo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total de perguntas:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text('${_questoes.length}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Respondidas:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${_respostas.length}',
                          style: TextStyle(
                            color: _respostas.length == _questoes.length ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Faltam:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${_questoes.length - _respostas.length}',
                          style: TextStyle(
                            color: _respostas.length == _questoes.length ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
