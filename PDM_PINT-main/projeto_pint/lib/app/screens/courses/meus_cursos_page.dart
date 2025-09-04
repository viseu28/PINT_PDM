import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/curso_model.dart';
import '../../services/curso_service.dart';
import 'curso_detail_page.dart';
import 'curso_inscrito_page.dart';
import '../../routes/route_names.dart';

class MeusCursosPage extends StatefulWidget {
  const MeusCursosPage({super.key});

  @override
  State<MeusCursosPage> createState() => _MeusCursosPageState();
}

class _MeusCursosPageState extends State<MeusCursosPage> {
  List<Curso> _meusCursos = [];
  bool _isLoading = true;
  String _filtroStatus = 'Todos'; // Todos, Em Progresso, Concluídos
  String _ordenacao =
      'Mais Recentes'; // Mais Recentes, Alfabética, Por Progresso
  final _textoPesquisa = '';
  bool _temPermissaoVerTerminados = true;

  final List<String> _opcoesStatus = ['Todos', 'Em Progresso', 'Concluídos'];
  final List<String> _opcoesOrdenacao = [
    'Mais Recentes',
    'Alfabética',
  ];

  @override
  void initState() {
    super.initState();
    print('🚨🚨🚨 INITSTATE EXECUTADO 🚨🚨🚨');
    print('🚨🚨🚨 PÁGINA MEUS CURSOS INICIALIZADA 🚨🚨🚨');
    _inicializar();
  }

  Future<void> _inicializar() async {
    print('🚨🚨🚨 _inicializar() EXECUTADO 🚨🚨🚨');
    await _verificarPermissao();
    await _carregarMeusCursos();
  }

  Future<void> _verificarPermissao() async {
  print('🚨🚨🚨 INICIANDO _verificarPermissao() 🚨🚨🚨');
  final temPermissao = await CursoService.permissaoLigacaoEspecifica(4);
  print('🔐 VERIFICAÇÃO DE PERMISSÃO 4: $temPermissao');
  setState(() {
    _temPermissaoVerTerminados = temPermissao;
  });
  print('🔐 _temPermissaoVerTerminados definido como: $_temPermissaoVerTerminados');
  print('🚨🚨🚨 FIM _verificarPermissao() 🚨🚨🚨');
}


  Future<void> _carregarMeusCursos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cursos = await CursoService.buscarMeusCursos();

      setState(() {
        _meusCursos = cursos;
        _isLoading = false;
      });

      final cursosVisiveis = _getCursosVisiveis();
      if (cursosVisiveis.isEmpty) {
        _mostrarMensagem(
          'Ainda não estás inscrito em nenhum curso',
          'Explore os cursos disponíveis e inscreve-te para começar a aprender!',
          Colors.blue,
        );
      } else {
        final cursosAssincronosTerminados = cursos.length - cursosVisiveis.length;
        String mensagem = '${cursosVisiveis.length} curso${cursosVisiveis.length == 1 ? '' : 's'} encontrado${cursosVisiveis.length == 1 ? '' : 's'}';
        if (cursosAssincronosTerminados > 0) {
          mensagem += '\n($cursosAssincronosTerminados curso${cursosAssincronosTerminados == 1 ? '' : 's'} assíncrono${cursosAssincronosTerminados == 1 ? '' : 's'} terminado${cursosAssincronosTerminados == 1 ? '' : 's'} oculto${cursosAssincronosTerminados == 1 ? '' : 's'})';
        }
        _mostrarMensagem(
          'Meus Cursos carregados!',
          mensagem,
          Colors.green,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _mostrarErro('Erro ao carregar os teus cursos: $e');
    }
  }

  void _mostrarMensagem(String titulo, String mensagem, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(mensagem),
          ],
        ),
        backgroundColor: cor,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Tentar novamente',
          textColor: Colors.white,
          onPressed: () => _carregarMeusCursos(),
        ),
      ),
    );
  }

  // Função auxiliar para obter cursos visíveis (excluindo assíncronos terminados)
List<Curso> _getCursosVisiveis() {
  return _meusCursos.where((curso) {
    bool isAssincrono = curso.sincrono == false;
    bool isTerminado = curso.estado == 'Terminado';
    
    // Verificar permissão específica para ver cursos terminados
    // Se não tem permissão (ID 4), remove TODOS os cursos terminados
    if (!_temPermissaoVerTerminados && isTerminado) {
      return false;
    }
    
    // Se tem permissão, aplica a regra original (remove apenas assíncronos terminados)
    if (isAssincrono && isTerminado) {
      return false;
    }
    
    return true;
  }).toList();
}

  List<Curso> _aplicarFiltros() {
    print('🚨🚨🚨 FUNÇÃO _aplicarFiltros EXECUTADA 🚨🚨🚨');
    print('🎯 INICIANDO _aplicarFiltros - Total de cursos: ${_meusCursos.length}');
    print('🔐 PERMISSÃO 4 ATUAL: $_temPermissaoVerTerminados');
    List<Curso> cursosFiltered = List.from(_meusCursos);

    // 🚫 Aplicar regras de visibilidade (mesma lógica de _getCursosVisiveis)
    cursosFiltered = cursosFiltered.where((curso) {
      // Debug: Mostrar informações do curso
      print('🔍 Analisando curso: ${curso.titulo}');
      print('   - Síncrono: ${curso.sincrono} (tipo: ${curso.sincrono.runtimeType})');
      print('   - Estado: "${curso.estado}" (tipo: ${curso.estado.runtimeType})');
      print('   - Tem permissão 4: $_temPermissaoVerTerminados');
      
      bool isAssincrono = curso.sincrono == false;
      bool isTerminado = curso.estado == 'Terminado';
      
      print('   - isAssincrono: $isAssincrono');
      print('   - isTerminado: $isTerminado');
      print('   - !_temPermissaoVerTerminados: ${!_temPermissaoVerTerminados}');
      
      // Verificar permissão específica para ver cursos terminados
      // Se não tem permissão (ID 4), remove TODOS os cursos terminados
      if (!_temPermissaoVerTerminados && isTerminado) {
        print('🚫 REMOVENDO curso terminado (sem permissão 4): ${curso.titulo}');
        return false;
      }
      
      // Se tem permissão, aplica a regra original (remove apenas assíncronos terminados)
      if (isAssincrono && isTerminado) {
        print('🚫 REMOVENDO curso assíncrono terminado: ${curso.titulo}');
        return false;
      }
      
      print('✅ MANTENDO curso na lista: ${curso.titulo}');
      return true; // Mantém na lista
    }).toList();

    // 🔍 Filtrar por texto pesquisado
    if (_textoPesquisa.isNotEmpty) {
      cursosFiltered =
          cursosFiltered.where((curso) {
            final titulo = curso.titulo.toLowerCase();
            return titulo.contains(_textoPesquisa);
          }).toList();
    }

    // 🎯 Filtrar por status
    if (_filtroStatus == 'Em Progresso') {
      cursosFiltered =
          cursosFiltered
              .where((curso) => (curso.estado != 'Terminado'))
              .toList();
    } else if (_filtroStatus == 'Concluídos') {
      cursosFiltered =
          cursosFiltered
              .where((curso) => (curso.estado == 'Terminado'))
              .toList();
    }

    // 📊 Ordenar
    switch (_ordenacao) {
      case 'Alfabética':
        cursosFiltered.sort((a, b) => a.titulo.compareTo(b.titulo));
        break;
      case 'Mais Recentes':
      default:
        break;
    }

    return cursosFiltered;
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ CONSTRUINDO MeusCursosPage...');
    print('   - Total de cursos carregados: ${_meusCursos.length}');
    
    // Mostrar todos os cursos carregados ANTES da filtragem
    for (int i = 0; i < _meusCursos.length; i++) {
      final curso = _meusCursos[i];
      print('   📚 Curso ${i+1}: ${curso.titulo}');
      print('      - Síncrono: ${curso.sincrono} (${curso.sincrono.runtimeType})');
      print('      - Estado: ${curso.estado} (${curso.estado.runtimeType})');
      print('      - Deve ser removido: ${curso.sincrono == false && curso.estado == 'Terminado'}');
    }
    
    print('🎯 Executando _aplicarFiltros()...');
    final cursosExibidos = _aplicarFiltros();
    print('✅ Filtros aplicados - Total exibido: ${cursosExibidos.length}');
    
    // Mostrar cursos que sobraram DEPOIS da filtragem
    for (int i = 0; i < cursosExibidos.length; i++) {
      final curso = cursosExibidos[i];
      final tipoTexto = (curso.sincrono == true) ? "Síncrono" : "Assíncrono";
      print('   ✅ Exibido ${i+1}: ${curso.titulo} ($tipoTexto - ${curso.estado})');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1FA),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.home);
            }
          },
        ),
        title: Text(
          'Meus Cursos',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _carregarMeusCursos),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Filtros e Estatísticas
                  _buildHeader(),

                  // Lista de Cursos
                  Expanded(
                    child:
                        cursosExibidos.isEmpty
                            ? _buildEmptyState()
                            : _buildCursosList(cursosExibidos),
                  ),
                ],
              ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Estatísticas (baseadas em cursos visíveis - exclui assíncronos terminados)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(
                'Total',
                '${_getCursosVisiveis().length}',
                Icons.school,
                Colors.blue,
              ),
              _buildStatCard(
                'Em Progresso',
                '${_getCursosVisiveis().where((c) => (c.estado ?? '') != 'Terminado').length}',
                Icons.play_circle,
                Colors.orange,
              ),
              _buildStatCard(
                'Concluídos',
                '${_getCursosVisiveis().where((c) => (c.estado ?? '') == 'Terminado').length}',
                Icons.check_circle,
                Colors.green,
              ),
            ],
          ),
          SizedBox(height: 16),

          // Filtros
          Row(
            children: [
              Expanded(
                child: _buildDropdownFiltro(
                  'Status',
                  _filtroStatus,
                  _opcoesStatus,
                  (value) => setState(() => _filtroStatus = value!),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildDropdownFiltro(
                  'Ordenar',
                  _ordenacao,
                  _opcoesOrdenacao,
                  (value) => setState(() => _ordenacao = value!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildDropdownFiltro(
    String label,
    String value,
    List<String> opcoes,
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items:
              opcoes.map((opcao) {
                return DropdownMenuItem(
                  value: opcao,
                  child: Text(opcao, style: TextStyle(fontSize: 14)),
                );
              }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80, color: Colors.grey[400]),
            SizedBox(height: 24),
            Text(
              'Ainda não tens cursos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Explora os cursos disponíveis e começa a tua jornada de aprendizado!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/cursos'),
              icon: Icon(Icons.explore),
              label: Text('Explorar Cursos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCursosList(List<Curso> cursos) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: cursos.length,
      itemBuilder: (context, index) {
        final curso = cursos[index];
        return _buildCursoCard(curso);
      },
    );
  }

  Widget _buildCursoCard(Curso curso) {
    // Atualiza o estado do curso dinamicamente baseado na data de fim
    Future<String?> buscarEstadoAtualizado(int cursoId) async {
      try {
        // Buscar o curso da lista local primeiro
        final cursoLocal = _meusCursos.firstWhere((c) => c.id == cursoId);

        // Verificar se tem data de fim para calcular o estado
        if (cursoLocal.dataFim != null) {
          try {
            final dataFim = DateTime.parse(cursoLocal.dataFim!);
            final agora = DateTime.now();
            return agora.isAfter(dataFim) ? 'Terminado' : 'Em Curso';
          } catch (e) {
            print('⚠️ Erro ao analisar data_fim: $e');
            return 'Em Curso';
          }
        }

        // Fallback para buscar via API se não tiver data local
        return await CursoService.buscarEstadoCurso(cursoId);
      } catch (e) {
        debugPrint('Erro ao buscar estado atualizado: $e');
        return 'Em Curso';
      }
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CursoDetailPage(curso: curso),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do curso
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagem/Ícone do curso
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getCursoColor(curso.tema).withOpacity(0.8),
                          _getCursoColor(curso.tema),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCursoIcon(curso.tema),
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  SizedBox(width: 16),

                  // Informações do curso
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          curso.titulo,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          curso.tema ?? 'Categoria geral',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              curso.sincrono == true
                                  ? 'Síncrono'
                                  : 'Assíncrono',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(width: 16),
                            Icon(Icons.star, size: 16, color: Colors.amber),
                            SizedBox(width: 4),
                            Text(
                              '${curso.pontos} pts',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            FutureBuilder<String?>(
                              future: buscarEstadoAtualizado(curso.id!),
                              builder: (context, snapshot) {
                                final estado = snapshot.data ?? curso.estado;

                                if (estado == null || estado.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    estado,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(width: 8),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              SizedBox(height: 12),

              // Botão de ação (apenas "Ver Detalhes")
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Como todos os cursos nesta página são inscritos, usar a nova página
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => CursoInscritoPage(curso: curso),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Ver Detalhes'),
                    ),
                  ),
                  SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      // TODO: Implementar funcionalidade de favoritos
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Funcionalidade em desenvolvimento'),
                        ),
                      );
                    },
                    icon: Icon(
                      curso.favorito ? Icons.favorite : Icons.favorite_border,
                      color: curso.favorito ? Colors.red : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Color _getCursoColor(String? tema) {
    switch (tema?.toLowerCase()) {
      case 'programação':
        return Colors.blue;
      case 'design':
        return Colors.purple;
      case 'marketing':
        return Colors.green;
      case 'finanças':
        return Colors.orange;
      default:
        return Colors.indigo;
    }
  }

  IconData _getCursoIcon(String? tema) {
    switch (tema?.toLowerCase()) {
      case 'programação':
        return Icons.code;
      case 'design':
        return Icons.design_services;
      case 'marketing':
        return Icons.campaign;
      case 'finanças':
        return Icons.account_balance;
      default:
        return Icons.school;
    }
  }
}
