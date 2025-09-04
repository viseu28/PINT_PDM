import 'package:flutter/material.dart';
import '../models/comentario_model.dart';
import '../services/comentario_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ComentariosSection extends StatefulWidget {
  final int cursoId;
  final bool? isInscrito; // *** DEPRECATED: Mantido por compatibilidade, mas sem efeito ***
  

  const ComentariosSection({
    super.key, 
    required this.cursoId,
    this.isInscrito, // *** OPTIONAL: Já não tem efeito na funcionalidade ***
  });

  @override
  State<ComentariosSection> createState() => _ComentariosSectionState();
}

class _ComentariosSectionState extends State<ComentariosSection> {
  Future<List<ComentarioModel>>? _comentariosFuture;
  final _formKey = GlobalKey<FormState>();
  final _comentarioController = TextEditingController();
  double _avaliacao = 0.0; // Começar com 0 estrelas
  bool _isLoading = false;
  int? _userId;
  
  // Variáveis para paginação
  int _paginaAtual = 0;
  final int _comentariosPorPagina = 5;
  List<ComentarioModel> _todosComentarios = [];
  
  @override
  void initState() {
    super.initState();
    _carregarComentarios();
    _carregarUserId();
  }

  Future<void> _carregarComentarios() async {
    final comentarios = await ComentarioService.buscarComentariosPorCurso(widget.cursoId);
    setState(() {
      _todosComentarios = comentarios;
      _paginaAtual = 0; // Reset para primeira página
      _comentariosFuture = Future.value(_comentariosPaginados());
    });
  }
  
  List<ComentarioModel> _comentariosPaginados() {
    final inicio = _paginaAtual * _comentariosPorPagina;
    final fim = inicio + _comentariosPorPagina;
    
    if (inicio >= _todosComentarios.length) {
      return [];
    }
    
    return _todosComentarios.sublist(
      inicio, 
      fim > _todosComentarios.length ? _todosComentarios.length : fim
    );
  }
  
  int get _totalPaginas {
    return (_todosComentarios.length / _comentariosPorPagina).ceil();
  }
  
  bool get _temProximaPagina {
    return _paginaAtual < _totalPaginas - 1;
  }
  
  bool get _temPaginaAnterior {
    return _paginaAtual > 0;
  }
  
  void _irParaPagina(int pagina) {
    if (pagina >= 0 && pagina < _totalPaginas) {
      setState(() {
        _paginaAtual = pagina;
        _comentariosFuture = Future.value(_comentariosPaginados());
      });
    }
  }
  
  Future<void> _carregarUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    
    if (userId != null) {
      setState(() => _userId = userId);
    }
  }
  
  Future<void> _enviarComentario() async {
    if (_formKey.currentState?.validate() != true || _userId == null) {
      return;
    }
    
    // *** REMOVIDO: Verificação de inscrição - agora qualquer pessoa pode comentar ***
    // Comentário: Permitindo que qualquer utilizador comente e avalie cursos
    
    setState(() => _isLoading = true);
    
    try {
      bool sucesso;
      String mensagemErro = '';
      
      // Sempre criar novo comentário (não há mais edição)
      final resultado = await ComentarioService.criarComentarioComErro(
        idCurso: widget.cursoId,
        idUtilizador: _userId!,
        comentario: _comentarioController.text,
        avaliacao: _avaliacao,
      );
      sucesso = resultado['sucesso'];
      mensagemErro = resultado['mensagem'] ?? '';
      
      setState(() {
        _isLoading = false;
        if (sucesso) {
          // Sempre limpar o formulário após envio bem-sucedido
          _comentarioController.clear();
          _avaliacao = 0.0;
          _carregarComentarios(); // Recarregar comentários
        }
      });
      
      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comentário publicado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Mostrar mensagem de erro específica
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagemErro.isNotEmpty 
                ? mensagemErro 
                : 'Erro ao enviar comentário. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro inesperado. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _excluirComentario(int comentarioId) async {
    // Confirmação
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir comentário'),
        content: const Text('Tem certeza que deseja excluir este comentário?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    
    if (confirmar != true) return;
    
    setState(() => _isLoading = true);
    final sucesso = await ComentarioService.excluirComentario(comentarioId);
    setState(() {
      _isLoading = false;
      if (sucesso) {
        _carregarComentarios();
      }
    });
    
    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comentário excluído com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  Future<void> _denunciarComentario(ComentarioModel comentario) async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa estar conectado para denunciar um comentário.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final motivoController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    final motivo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Denunciar comentário'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: motivoController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Motivo da denúncia',
              hintText: 'Descreva o motivo da denúncia',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor, informe o motivo da denúncia';
              }
              if (value.length < 10) {
                return 'O motivo deve ter pelo menos 10 caracteres';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(context, motivoController.text);
              }
            },
            child: const Text('Denunciar'),
          ),
        ],
      ),
    );
    
    if (motivo == null) return;
    
    setState(() => _isLoading = true);
    
    final resultado = await ComentarioService.denunciarComentarioComErro(
      idComentario: comentario.id,
      idUtilizador: _userId!,
      motivo: motivo,
    );
    
    setState(() => _isLoading = false);
    
    if (resultado['sucesso'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['mensagem']),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['mensagem']),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        _buildHeader(),
        const SizedBox(height: 16),
        _buildAvaliacao(),
        // *** ALTERADO: Mostrar formulário para todos os utilizadores logados ***
        if (_userId != null) _buildFormularioComentario(),
        // *** REMOVIDO: Aviso de inscrição - já não é necessário ***
        const SizedBox(height: 16),
        _buildListaComentarios(),
      ],
    );
  }
  
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Comentários e Avaliações',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Mostrar total de comentários se houver mais de 5
            if (_todosComentarios.length > _comentariosPorPagina)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_todosComentarios.length} comentários',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
        // *** REMOVIDO: Aviso de inscrição - agora qualquer pessoa pode comentar ***
      ],
    );
  }
  
  Widget _buildAvaliacao() {
    if (_todosComentarios.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Ainda não há avaliações para este curso. Seja o primeiro a avaliar!'),
      );
    }
    
    final mediaAvaliacao = _todosComentarios.fold<double>(
      0, (sum, item) => sum + item.avaliacao) / _todosComentarios.length;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mediaAvaliacao.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < mediaAvaliacao.floor() 
                          ? Icons.star 
                          : (index < mediaAvaliacao 
                              ? Icons.star_half 
                              : Icons.star_border),
                      color: Colors.amber,
                    ),
                  ),
                ),
                Text('${_todosComentarios.length} avaliações'),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                children: [
                  _buildBarraAvaliacao(5, _todosComentarios),
                  _buildBarraAvaliacao(4, _todosComentarios),
                  _buildBarraAvaliacao(3, _todosComentarios),
                  _buildBarraAvaliacao(2, _todosComentarios),
                  _buildBarraAvaliacao(1, _todosComentarios),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBarraAvaliacao(int estrelas, List<ComentarioModel> comentarios) {
    final total = comentarios.length;
    final quantidade = comentarios.where((c) => 
        c.avaliacao.round() == estrelas).length;
    final percentual = total > 0 ? quantidade / total : 0.0;
    
    return Row(
      children: [
        Text('$estrelas'),
        const SizedBox(width: 4),
        const Icon(Icons.star, size: 14, color: Colors.amber),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: percentual,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.amber,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$quantidade'),
      ],
    );
  }
  
  Widget _buildFormularioComentario() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sua avaliação:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    icon: Icon(
                      index < _avaliacao ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                    onPressed: () {
                      setState(() {
                        // Se clicar na última estrela selecionada, volta para 0
                        if (_avaliacao == index + 1.0) {
                          _avaliacao = 0.0;
                        } else {
                          _avaliacao = index + 1.0;
                        }
                      });
                    },
                  ),
                ),
              ),
              // Mostrar o valor da avaliação atual
              Center(
                child: Text(
                  _avaliacao == 0 ? 'Nenhuma estrela selecionada' : '${_avaliacao.toInt()} estrela${_avaliacao > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _comentarioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Seu comentário',
                  hintText: 'Compartilhe sua experiência com este curso',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, escreva um comentário';
                  }
                  if (value.length < 3) {
                    return 'O comentário deve ter pelo menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _enviarComentario,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Publicar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildListaComentarios() {
    // Se ainda não temos Future, mostrar loading
    if (_comentariosFuture == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return FutureBuilder<List<ComentarioModel>>(
      future: _comentariosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final comentarios = snapshot.data ?? [];
        if (_todosComentarios.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Ainda não há comentários para este curso.'),
            ),
          );
        }
        
        return Column(
          children: [
            // Lista de comentários da página atual
            ...comentarios.map((comentario) {
              return _buildComentarioCard(comentario);
            }),
            
            // Controles de paginação (só mostrar se houver mais de 5 comentários)
            if (_todosComentarios.length > _comentariosPorPagina)
              _buildControlesPaginacao(),
          ],
        );
      },
    );
  }
  
  Widget _buildControlesPaginacao() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Botão página anterior
            ElevatedButton.icon(
              onPressed: _temPaginaAnterior ? () => _irParaPagina(_paginaAtual - 1) : null,
              icon: const Icon(Icons.arrow_back_ios, size: 14),
              label: const Text('Anterior', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _temPaginaAnterior ? null : Colors.grey[300],
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(80, 32),
              ),
            ),
            
            // Informação da página
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Página ${_paginaAtual + 1} de $_totalPaginas',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            // Botão próxima página
            ElevatedButton.icon(
              onPressed: _temProximaPagina ? () => _irParaPagina(_paginaAtual + 1) : null,
              label: const Text('Próxima', style: TextStyle(fontSize: 12)),
              icon: const Icon(Icons.arrow_forward_ios, size: 14),
              style: ElevatedButton.styleFrom(
                backgroundColor: _temProximaPagina ? null : Colors.grey[300],
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(80, 32),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildComentarioCard(ComentarioModel comentario) {
    final bool isOwner = comentario.ehProprietario == true;
    final bool podeAvaliar = true; // *** ALTERADO: Qualquer pessoa pode avaliar ***
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  backgroundImage: comentario.avatarUtilizador != null 
                      ? NetworkImage(comentario.avatarUtilizador!)
                      : null,
                  child: comentario.avatarUtilizador == null 
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            comentario.nomeUtilizador ?? 'Utilizador',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          // Mostrar tipo de utilizador se não for formando
                          if (comentario.tipoUtilizadorLabel != null)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6, 
                                vertical: 1
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                comentario.tipoUtilizadorLabel!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          // Badge "Você" para o próprio utilizador
                          if (isOwner)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8, 
                                vertical: 2
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Você',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        comentario.dataFormatada,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < comentario.avaliacao 
                          ? Icons.star 
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comentario.comentario),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isOwner && podeAvaliar) ...[
                  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Excluir'),
                    onPressed: () => _excluirComentario(comentario.id),
                  ),
                ] else if (_userId != null) ...[
                  TextButton.icon(
                    icon: const Icon(Icons.flag, size: 18),
                    label: const Text('Denunciar'),
                    onPressed: () => _denunciarComentario(comentario),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
