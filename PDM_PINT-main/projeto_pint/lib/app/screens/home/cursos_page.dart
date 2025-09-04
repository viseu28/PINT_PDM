import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/curso_model.dart';
import '../../services/curso_service.dart';
import '../../widgets/notification_badge.dart';
import '../courses/curso_detail_page.dart';
import '../courses/curso_inscrito_page.dart';
import '../../database/local_database.dart';
import '../../../config/api_config.dart';

class CoursesScreen extends StatefulWidget {
  @override
  _CoursesScreenState createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  List<Curso> _todosCursos = [];
  List<Curso> _cursosExibidos = [];
  List<Curso> _meusCursos = [];
  int _cursosEmBreveCount = 0; // *** NOVO: Contador para cursos "Em breve" ***
  int _meusCursosVisiveis = 0; // *** NOVO: Contador para "Meus Cursos" visíveis (após remoção de assíncronos terminados) ***
  bool _isLoading = true;
  String _textoPesquisa = '';
  List<String> _temasFiltro = []; // Mudado para lista para seleção múltipla
  List<String> _dificuldadesFiltro = []; // Mudado para lista para seleção múltipla (máx 2)
  String _tipoFiltro = 'Todos';
  String _ordenacao = 'Título A-Z';
  bool _mostrandoFiltros = false;
  bool _mostrandoBotoesFiltros = true; // Controla visibilidade dos botões
  bool _temPermissaoVerTerminados = true; // Permissão para ver cursos terminados

  final TextEditingController _controladorPesquisa = TextEditingController();

  // Listas dinâmicas que serão carregadas da API
  List<String> _temas = ['Todos']; // Para substituir categorias nos filtros
  List<String> _dificuldades = ['Todas']; // Lista dinâmica de dificuldades

  final List<String> _tipos = ['Todos', 'Síncrono', 'Assíncrono'];

  final List<String> _opcoesOrdenacao = [
    'Título A-Z',
    'Título Z-A',
    'Dificuldade',
    'Pontos',
    'Avaliação',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _verificarPermissao();
    _inicializarPagina();
  }

  Future<void> _verificarPermissao() async {
    print('🚨🚨🚨 INICIANDO _verificarPermissao() na CoursesScreen 🚨🚨🚨');
    final temPermissao = await CursoService.permissaoLigacaoEspecifica(4);
    print('🔐 VERIFICAÇÃO DE PERMISSÃO 4 na CoursesScreen: $temPermissao');
    setState(() {
      _temPermissaoVerTerminados = temPermissao;
    });
    print('🔐 _temPermissaoVerTerminados definido como: $_temPermissaoVerTerminados');
  }

  Future<void> _inicializarPagina() async {
    setState(() => _isLoading = true);

    try {
      // Carregar dados em paralelo para melhor performance
      await Future.wait([
        _carregarTemas(),
        _carregarDificuldades(),
        _carregarCursos(),
      ]);
    } catch (e) {
      _mostrarErro('Erro ao carregar dados iniciais');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _carregarTemas() async {
    try {
      final temas = await CursoService.buscarTemas();
      setState(() {
        _temas = temas;
      });
    } catch (e) {
      // Manter temas padrão se houver erro
    }
  }

  Future<void> _carregarDificuldades() async {
    try {
      await CursoService.buscarDificuldades(); // Manter chamada à API para futura expansão
      setState(() {
        // Garantir que sempre temos as 3 opções principais
        _dificuldades = ['Todas', 'Iniciante', 'Intermédio', 'Avançado'];
      });
    } catch (e) {
      // Manter dificuldades padrão se houver erro
      setState(() {
        _dificuldades = ['Todas', 'Iniciante', 'Intermédio', 'Avançado'];
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controladorPesquisa.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      _aplicarFiltros();
    });
  }

  // Controlar visibilidade dos botões de filtro baseado no scroll
  void _onScroll() {
    if (_scrollController.hasClients) {
      const double scrollThreshold = 50.0; // Pixels para esconder/mostrar

      if (_scrollController.offset > scrollThreshold &&
          _mostrandoBotoesFiltros) {
        setState(() {
          _mostrandoBotoesFiltros = false;
          // Também esconder o painel de filtros se estiver aberto
          if (_mostrandoFiltros) {
            _mostrandoFiltros = false;
          }
        });
      } else if (_scrollController.offset <= scrollThreshold &&
          !_mostrandoBotoesFiltros) {
        setState(() {
          _mostrandoBotoesFiltros = true;
        });
      }
    }
  }

  Future<void> _carregarCursos() async {
    try {
      // Buscar todos os cursos da API
      final cursos = await CursoService.buscarTodosCursos();

      // Buscar meus cursos (inscritos) da API
      final meusCursos = await CursoService.buscarMeusCursos();

      // Buscar meus favoritos
      final favoritos = await CursoService.buscarFavoritos();

      // Marcar os cursos que são favoritos
      for (var curso in cursos) {
        curso.favorito = favoritos.any((favCurso) => favCurso.id == curso.id);
        // Sincronizar estado de favorito localmente
        if (curso.id != null) {
          try {
            await LocalDatabase.atualizarFavorito(curso.id!, curso.favorito);
          } catch (e) {
            print('⚠️ Erro ao sincronizar favorito localmente: $e');
          }
        }
      }

      // Marcar os cursos inscritos que são favoritos também
      for (var curso in meusCursos) {
        curso.favorito = favoritos.any((favCurso) => favCurso.id == curso.id);
        // Sincronizar estado de favorito localmente
        if (curso.id != null) {
          try {
            await LocalDatabase.atualizarFavorito(curso.id!, curso.favorito);
          } catch (e) {
            print('⚠️ Erro ao sincronizar favorito localmente: $e');
          }
        }
      }

      setState(() {
        _todosCursos = cursos;
        _meusCursos = meusCursos;
        
        // Calcular "Meus Cursos" visíveis (sem assíncronos terminados)
        _meusCursosVisiveis = meusCursos.where((curso) {
          return !(curso.sincrono == false && curso.estado == 'Terminado');
        }).length;
        
        _aplicarFiltros();
      });

      // Sincronizar favoritos locais com a API quando estiver online
      try {
        await CursoService.sincronizarFavoritosLocais();
      } catch (e) {
        print('⚠️ Erro na sincronização de favoritos: $e');
      }

      // Mostrar feedback ao usuário
      if (cursos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nenhum curso encontrado na base de dados.'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Tentar novamente',
              textColor: Colors.white,
              onPressed: () => _carregarCursos(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${cursos.length} cursos carregados!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar cursos: $e');
    }
  }

  Future<void> _atualizarDadosCompletamente() async {
    try {
      // Recarregar temas, dificuldades e cursos
      await Future.wait([
        _carregarTemas(),
        _carregarDificuldades(),
        _carregarCursos(),
      ]);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dados atualizados!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      _mostrarErro('Erro ao atualizar dados');
    }
  }

  void _aplicarFiltros() {
    List<Curso> cursosParaFiltrar =
        _tabController.index == 0 ? _meusCursos : _todosCursos;

    List<Curso> cursosFiltrados = cursosParaFiltrar;

    // *** NOVO: Aplicar regras de visibilidade na aba "Meus Cursos" ***
    if (_tabController.index == 0) {
      // Na aba "Meus Cursos", aplicar regras de visibilidade
      cursosFiltrados = cursosFiltrados.where((curso) {
        bool isAssincrono = curso.sincrono == false;
        bool isTerminado = curso.estado == 'Terminado';
        
        // Verificar permissão específica para ver cursos terminados
        // Se não tem permissão (ID 4), remove TODOS os cursos terminados
        if (!_temPermissaoVerTerminados && isTerminado) {
          print('🚫 REMOVENDO da aba Meus Cursos - curso terminado (sem permissão 4): ${curso.titulo}');
          return false;
        }
        
        // Se tem permissão, aplica a regra original (remove apenas assíncronos terminados)
        if (isAssincrono && isTerminado) {
          print('🚫 REMOVENDO da aba Meus Cursos - curso assíncrono terminado: ${curso.titulo}');
          return false; // Remove da lista
        }
        
        return true; // Mantém na lista
      }).toList();
      
      // Atualizar contador de "Meus Cursos" visíveis
      _meusCursosVisiveis = cursosFiltrados.length;
      print('📊 Meus Cursos após filtro: ${_meusCursosVisiveis}');
    }

    // *** FILTRO EXISTENTE: Filtrar por estado apenas na aba "Todos os cursos" (index 1) ***
    if (_tabController.index == 1) {
      // Na aba "Todos os cursos", mostrar apenas cursos "Em breve"
      cursosFiltrados = cursosFiltrados.where((curso) {
        print('🔍 Curso: ${curso.titulo} - Estado: ${curso.estado}');
        return curso.estado != null && 
               curso.estado!.toLowerCase().trim() == 'em breve';
      }).toList();
      
      print('📊 Total de cursos "Em breve": ${cursosFiltrados.length}');
    }

    // *** NOVO: Calcular contador de cursos "Em breve" para o TabBar ***
    _cursosEmBreveCount = _todosCursos.where((curso) {
      return curso.estado != null && 
             curso.estado!.toLowerCase().trim() == 'em breve';
    }).length;

    // Aplicar filtro de texto
    if (_textoPesquisa.isNotEmpty) {
      cursosFiltrados = CursoService.buscarPorTexto(
        cursosFiltrados,
        _textoPesquisa,
      );
    }

    // Aplicar filtro de tema (substituindo categoria) - agora com seleção múltipla
    cursosFiltrados = CursoService.filtrarPorTemas(
      cursosFiltrados,
      _temasFiltro,
    );

    // Aplicar filtro de dificuldade (múltipla seleção)
    cursosFiltrados = CursoService.filtrarPorDificuldades(
      cursosFiltrados,
      _dificuldadesFiltro,
    );

    // Aplicar filtro de tipo (síncrono/assíncrono)
    cursosFiltrados = CursoService.filtrarPorTipo(cursosFiltrados, _tipoFiltro);

    // Aplicar ordenação
    cursosFiltrados = CursoService.ordenarCursos(cursosFiltrados, _ordenacao);

    setState(() {
      _cursosExibidos = cursosFiltrados;
    });
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          if (_mostrandoFiltros) _buildFilterPanel(),
          _buildTabBar(),
          Expanded(
            child: _isLoading ? _buildLoadingIndicator() : _buildCoursesList(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.white,
        showSelectedLabels: false,
        elevation: 0,
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
              context.go('/home');
              break;
            case 1:
              context.go('/forum');
              break;
            case 2:
              context.go('/favoritos');
              break;
            case 3:
              context.go('/settings');
              break;
            default:
              break;
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      title: const Text(
        'Cursos',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      actions: [
        const NotificationBadge(),
        IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () {
            context.go('/perfil');
          },
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Campo de pesquisa
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _controladorPesquisa,
              decoration: const InputDecoration(
                hintText: 'Pesquisar cursos...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _textoPesquisa = value.toLowerCase();
                  _aplicarFiltros();
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          // Botões de ação com animação
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _mostrandoBotoesFiltros ? null : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _mostrandoBotoesFiltros ? 1.0 : 0.0,
              child:
                  _mostrandoBotoesFiltros
                      ? Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _mostrandoFiltros = !_mostrandoFiltros;
                                });
                              },
                              icon: Icon(
                                _mostrandoFiltros
                                    ? Icons.filter_list_off
                                    : Icons.filter_list,
                                size: 20,
                              ),
                              label: const Text('Filtros'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _mostrandoFiltros
                                        ? Colors.blue
                                        : Colors.grey[100],
                                foregroundColor:
                                    _mostrandoFiltros
                                        ? Colors.white
                                        : Colors.black54,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PopupMenuButton<String>(
                              onSelected: (value) {
                                setState(() {
                                  _ordenacao = value;
                                  _aplicarFiltros();
                                });
                              },
                              itemBuilder:
                                  (context) =>
                                      _opcoesOrdenacao
                                          .map(
                                            (opcao) => PopupMenuItem(
                                              value: opcao,
                                              child: Row(
                                                children: [
                                                  // Ícone de check para a opção selecionada
                                                  Icon(
                                                    _ordenacao == opcao
                                                        ? Icons.check
                                                        : Icons
                                                            .check_box_outline_blank,
                                                    size: 16,
                                                    color:
                                                        _ordenacao == opcao
                                                            ? Colors.blue
                                                            : Colors
                                                                .transparent,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    opcao,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          _ordenacao == opcao
                                                              ? FontWeight.w600
                                                              : FontWeight
                                                                  .normal,
                                                      color:
                                                          _ordenacao == opcao
                                                              ? Colors.blue
                                                              : Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                          .toList(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.sort,
                                      size: 20,
                                      color: Colors.black54,
                                    ),
                                    const SizedBox(width: 8),
                                    // Mostrar a opção selecionada em vez de "Ordenar"
                                    Flexible(
                                      child: Text(
                                        _ordenacao,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      size: 20,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                      : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Filtro de tema
          // Filtro de tema (com seleção múltipla)
          Row(
            children: [
              const Text(
                'Tema',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              if (_temasFiltro.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_temasFiltro.length} selecionado${_temasFiltro.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                _temas.map((tema) {
                  // Não permitir seleção de "Todos" quando há outros selecionados
                  final isTodos = tema == 'Todos';
                  final isSelected =
                      isTodos
                          ? _temasFiltro.isEmpty
                          : _temasFiltro.contains(tema);

                  // Calcular se pode ser selecionado
                  // Permitir até (total_temas - 2) seleções, ex: 4 temas -> máx 2 seleções
                  final temasDisponiveis =
                      _temas.where((t) => t != 'Todos').length;
                  final maxSelecoes =
                      temasDisponiveis -
                      1; // Pelo menos 1 tem que ficar não selecionado
                  final podeSelecionar =
                      isSelected ||
                      (_temasFiltro.length < maxSelecoes && !isTodos) ||
                      isTodos;

                  return FilterChip(
                    label: Text(tema),
                    selected: isSelected,
                    onSelected:
                        podeSelecionar
                            ? (selected) {
                              setState(() {
                                if (isTodos) {
                                  // Se selecionou "Todos", limpar outras seleções
                                  _temasFiltro.clear();
                                } else {
                                  // Se selecionou um tema específico
                                  if (selected) {
                                    _temasFiltro.add(tema);
                                  } else {
                                    _temasFiltro.remove(tema);
                                  }
                                }
                                _aplicarFiltros();
                              });
                            }
                            : null,
                    backgroundColor:
                        podeSelecionar ? Colors.grey[100] : Colors.grey[300],
                    selectedColor: Colors.blue[100],
                    checkmarkColor: Colors.blue,
                    // Adicionar tooltip para explicar quando não pode selecionar
                    tooltip:
                        !podeSelecionar && !isTodos
                            ? 'Máximo ${maxSelecoes} tema${maxSelecoes > 1 ? 's' : ''} podem ser selecionados'
                            : null,
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),
          // Filtro de dificuldade (seleção múltipla - máximo 2)
          const Text(
            'Dificuldade',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                _dificuldades.map((dificuldade) {
                  // Não permitir seleção de "Todas" quando há outros selecionados
                  final isTodas = dificuldade == 'Todas';
                  final isSelected =
                      isTodas
                          ? _dificuldadesFiltro.isEmpty
                          : _dificuldadesFiltro.contains(dificuldade);

                  // Calcular se pode ser selecionado
                  // Permitir máximo 2 seleções (excluindo "Todas")
                  final maxSelecoes = 2;
                  final podeSelecionar =
                      isSelected ||
                      (_dificuldadesFiltro.length < maxSelecoes && !isTodas) ||
                      isTodas;

                  return FilterChip(
                    label: Text(dificuldade),
                    selected: isSelected,
                    onSelected:
                        podeSelecionar
                            ? (selected) {
                              setState(() {
                                if (isTodas) {
                                  // Se selecionou "Todas", limpar outras seleções
                                  _dificuldadesFiltro.clear();
                                } else {
                                  // Se selecionou uma dificuldade específica
                                  if (selected) {
                                    _dificuldadesFiltro.add(dificuldade);
                                  } else {
                                    _dificuldadesFiltro.remove(dificuldade);
                                  }
                                }
                                _aplicarFiltros();
                              });
                            }
                            : null,
                    backgroundColor:
                        podeSelecionar ? Colors.grey[100] : Colors.grey[300],
                    selectedColor: Colors.orange[100],
                    checkmarkColor: Colors.orange,
                    // Adicionar tooltip para explicar quando não pode selecionar
                    tooltip:
                        !podeSelecionar && !isTodas
                            ? 'Máximo ${maxSelecoes} dificuldade${maxSelecoes > 1 ? 's' : ''} podem ser selecionadas'
                            : null,
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),
          // Filtro de tipo (síncrono/assíncrono)
          const Text(
            'Tipo de Curso',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                _tipos.map((tipo) {
                  final isSelected = _tipoFiltro == tipo;
                  return FilterChip(
                    label: Text(tipo),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _tipoFiltro = tipo;
                        _aplicarFiltros();
                      });
                    },
                    backgroundColor: Colors.grey[100],
                    selectedColor: Colors.purple[100],
                    checkmarkColor: Colors.purple,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.blue,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        indicatorWeight: 3,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, size: 18),
                const SizedBox(width: 8),
                Text('Meus Cursos ($_meusCursosVisiveis)'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.library_books_outlined, size: 18),
                const SizedBox(width: 8),
                Text('Todos os Cursos ($_cursosEmBreveCount)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Carregando cursos...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList() {
    if (_cursosExibidos.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _atualizarDadosCompletamente,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _cursosExibidos.length,
        itemBuilder: (context, index) {
          return _buildCourseCard(_cursosExibidos[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    // Função para gerar mensagem específica baseada nos filtros ativos
    String _getMensagemEspecifica() {
      if (_tabController.index == 0) {
        return 'O formando ainda não está inscrito em nenhum curso';
      }

      // Verificar se há filtros específicos aplicados
      List<String> filtrosAtivos = [];

      if (_textoPesquisa.isNotEmpty) {
        filtrosAtivos.add('termo "${_textoPesquisa}"');
      }

      // Mostrar filtros ativos
      if (_temasFiltro.isNotEmpty) {
        filtrosAtivos.add('temas "${_temasFiltro.join(', ')}"');
      }

      if (_dificuldadesFiltro.isNotEmpty) {
        filtrosAtivos.add('dificuldades "${_dificuldadesFiltro.join(', ')}"');
      }

      if (_tipoFiltro != 'Todos') {
        filtrosAtivos.add('tipo "${_tipoFiltro}"');
      }

      if (filtrosAtivos.isEmpty) {
        // Verificar se é porque não há dados da API vs. filtros aplicados
        if (_tabController.index == 1 && _todosCursos.isEmpty) {
          return 'Nenhum curso disponível na base de dados';
        }
        return 'Nenhum curso encontrado';
      } else if (filtrosAtivos.length == 1 && _tipoFiltro != 'Todos') {
        // Mensagem específica para filtro de tipo
        return _tipoFiltro == 'Síncrono'
            ? 'Nenhum curso síncrono encontrado'
            : 'Nenhum curso assíncrono encontrado';
      } else {
        return 'Nenhum curso encontrado para os filtros aplicados';
      }
    }

    String _getDicaEspecifica() {
      if (_tabController.index == 0) {
        return 'Explore os cursos disponíveis e inscreva-se!';
      }

      // Verificar se não há dados da API
      if (_todosCursos.isEmpty) {
        return 'Verifique se a API está rodando e se há cursos na base de dados.\nTente atualizar puxando para baixo.';
      }

      if (_tipoFiltro == 'Síncrono') {
        return 'Cursos síncronos têm aulas ao vivo em horários fixos.\nTente buscar por "Assíncrono" ou remover filtros.';
      } else if (_tipoFiltro == 'Assíncrono') {
        return 'Cursos assíncronos permitem estudar no seu próprio ritmo.\nTente buscar por "Síncrono" ou remover filtros.';
      } else if (_textoPesquisa.isNotEmpty ||
          _temasFiltro.isNotEmpty ||
          _dificuldadesFiltro.isNotEmpty) {
        return 'Tente remover alguns filtros ou alterar os termos de pesquisa.';
      }

      return 'Tente ajustar os filtros de pesquisa';
    }

    IconData _getIconeEspecifico() {
      if (_tabController.index == 0) {
        return Icons.school_outlined;
      }

      // Verificar se não há dados da API
      if (_todosCursos.isEmpty) {
        return Icons.cloud_off_outlined;
      }

      if (_tipoFiltro == 'Síncrono') {
        return Icons.video_call_outlined;
      } else if (_tipoFiltro == 'Assíncrono') {
        return Icons.play_circle_outline;
      }

      return Icons.search_off;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60), // Espaço do topo
            Icon(_getIconeEspecifico(), size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _getMensagemEspecifica(),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getDicaEspecifica(),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Botões de ação específicos
            if (_tabController.index == 0) ...[
              ElevatedButton(
                onPressed: () {
                  _tabController.animateTo(1);
                },
                child: const Text('Explorar Cursos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ] else if (_todosCursos.isEmpty) ...[
              // Botão específico para quando não há dados da API
              ElevatedButton.icon(
                onPressed: () {
                  _carregarCursos();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Recarregar Cursos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ] else if (_tipoFiltro != 'Todos') ...[
              // Botões para alternar entre Síncrono/Assíncrono
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _tipoFiltro =
                            _tipoFiltro == 'Síncrono'
                                ? 'Assíncrono'
                                : 'Síncrono';
                        _aplicarFiltros();
                      });
                    },
                    icon: Icon(
                      _tipoFiltro == 'Síncrono'
                          ? Icons.play_circle_outline
                          : Icons.video_call,
                    ),
                    label: Text(
                      _tipoFiltro == 'Síncrono'
                          ? 'Ver Assíncronos'
                          : 'Ver Síncronos',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple,
                      side: const BorderSide(color: Colors.purple),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _tipoFiltro = 'Todos';
                        _aplicarFiltros();
                      });
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Ver Todos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_textoPesquisa.isNotEmpty ||
                _temasFiltro.isNotEmpty ||
                _dificuldadesFiltro.isNotEmpty) ...[
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _textoPesquisa = '';
                    _temasFiltro.clear();
                    _dificuldadesFiltro.clear();
                    _tipoFiltro = 'Todos';
                    _controladorPesquisa.clear();
                    _aplicarFiltros();
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Limpar Filtros'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 60), // Espaço do fundo
          ],
        ),
      ),
    );
  }

void _logCursoDetails(Curso curso) {
  debugPrint('⏳ Curso ID: ${curso.id}');
  debugPrint('📝 Estado: ${curso.estado ?? "NULL"}');
  debugPrint('🔢 Pontos: ${curso.pontos}');
  debugPrint('📌 Tipo: ${curso.tipoTexto}');
  debugPrint('⭐ Avaliação: ${curso.avaliacao}');
}

  Widget _buildCourseCard(Curso curso) {

    _logCursoDetails(curso);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Imagem do curso
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Stack(
              children: [
                // Imagem do curso ou placeholder
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child:
                        curso.imagemUrl != null && curso.imagemUrl!.isNotEmpty
                            ? () {
                              print('🖼️ Processando imagem: ${curso.imagemUrl} para curso: ${curso.titulo}');
                              
                              // Primeiro, tentar como URL completa
                              if (curso.imagemUrl!.startsWith('http')) {
                                return Image.network(
                                  curso.imagemUrl!,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / 
                                              loadingProgress.expectedTotalBytes!
                                            : null,
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
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildAssetImageFallback(curso.tema);
                                    },
                                  )
                                  : _buildAssetImageFallback(curso.tema);
                            }()
                            : _buildAssetImageFallback(curso.tema),
                  ),
                ),
                // Overlay escuro para melhor legibilidade
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Badge de dificuldade
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                ),
                // Botão de favoritos
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        curso.favorito ? Icons.bookmark : Icons.bookmark_border,
                        color: curso.favorito ? Colors.yellow : null,
                      ),
                      onPressed: () async {
                        try {
                          final resultado = await CursoService.alternarFavorito(
                            curso.id!,
                          );

                          // Atualizar o estado do curso na lista
                          setState(() {
                            curso.favorito = resultado;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                resultado
                                    ? 'Curso adicionado aos favoritos!'
                                    : 'Curso removido dos favoritos!',
                              ),
                              backgroundColor:
                                  resultado ? Colors.green : Colors.red,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erro ao adicionar aos favoritos'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Conteúdo do card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título e tema
                Text(
                  curso.titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (curso.tema != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    curso.tema!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 8),
                // Descrição
                Text(
                  curso.descricao,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (curso.dataInicio != null || curso.dataFim != null) ...[
                  const SizedBox(height: 8),
                  // Datas do curso
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatarDatasCurso(curso.dataInicio, curso.dataFim),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                // Informações adicionais
                // Informações adicionais (badges)
                Row(
                  children: [
                    // Badge de PONTOS (existente)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars, size: 16, color: Colors.amber[700]),
                          const SizedBox(width: 4),
                          Text(
                            '${curso.pontos} pts',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Badge de TIPO (existente)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: curso.corTipo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(curso.tipoIcone, size: 16, color: curso.corTipo),
                          const SizedBox(width: 4),
                          Text(
                            curso.tipoTexto,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: curso.corTipo,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Badge de ESTADO (corrigido)
                    if (curso.estado != null && curso.estado!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          curso.estado!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),

                    // Badge de AVALIAÇÃO (condicional)
                    if (curso.avaliacao != null && curso.avaliacao! > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              curso.avaliacao!.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                // Botão de ação
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Verificar se o utilizador está inscrito no curso
                          if (curso.inscrito) {
                            // Navegar para página específica de curso inscrito
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        CursoInscritoPage(curso: curso),
                              ),
                            );
                          } else {
                            // Navegar para página de detalhes padrão
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => CursoDetailPage(curso: curso),
                              ),
                            );
                          }
                        },
                        child: const Text('Ver Detalhes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Formatar datas do curso
  String _formatarDatasCurso(String? dataInicio, String? dataFim) {
    if (dataInicio == null && dataFim == null) return '';

    try {
      if (dataInicio != null && dataFim != null) {
        final inicio = DateTime.parse(dataInicio);
        final fim = DateTime.parse(dataFim);
        return '${_formatarData(inicio)} - ${_formatarData(fim)}';
      } else if (dataInicio != null) {
        final inicio = DateTime.parse(dataInicio);
        return 'Início: ${_formatarData(inicio)}';
      } else if (dataFim != null) {
        final fim = DateTime.parse(dataFim);
        return 'Até: ${_formatarData(fim)}';
      }
    } catch (e) {
      // Silencioso em produção - falha na formatação de datas
    }
    return '';
  }

  // Formatar data individual
  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
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

  // Widget placeholder para quando não há imagem
  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
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
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('❌ Erro ao carregar asset: $assetImage');
        return _buildImagePlaceholder();
      },
    );
  }
}
