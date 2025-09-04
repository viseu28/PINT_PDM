/*
curso_service.dart - O que é e para que serve?
O curso_service.dart é a camada de serviço que gerencia toda a lógica de 
negócio relacionada aos cursos. É como o "cérebro" que coordena as operações.

Principais funções:
  1-Comunicação com API: Faz requisições HTTP para buscar cursos do servidor
  2-Lógica de Negócio: Filtros, ordenação, pesquisa
  3-Dados Dinâmicos: Retorna APENAS dados reais da base de dados via API
  4-Processamento: Transforma dados brutos em informações úteis

IMPORTANTE: Esta versão não possui fallback para dados mock/estáticos.
Se a API não estiver disponível, retorna lista vazia para incentivar
o desenvolvimento com dados reais da base de dados.

Exemplo prático:
// Em vez de fazer isso na interface:
final response = await http.get('http://api.com/cursos');
final data = json.decode(response.body);
List<Curso> cursos = data.map((json) => Curso.fromJson(json)).toList();

// Você simplesmente chama:
List<Curso> cursos = await CursoService.buscarTodosCursos();

// E pode usar funções prontas:
List<Curso> cursosFilltrados = CursoService.filtrarPorCategoria(cursos, 'Programação');
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/curso_model.dart';
import 'package:projeto_pint/app/utils/file_downloader.dart';
import 'package:projeto_pint/app/database/local_database.dart';

class CursoService {
  static const String baseUrl = 'http://192.168.1.68:3000';

  // Método para configurar IP dinamicamente se necessário
  static String _obterBaseUrl() {
    // Use o endereço configurado
    return baseUrl;
  }

  // Função auxiliar para testar conectividade e encontrar URL que funciona
  static Future<String?> _encontrarUrlFuncionando() async {
    final urlsTeste = [
      'http://192.168.1.68:3000', // IP atual da máquina
      'http://192.168.1.688:3000', // IPs próximos caso tenha mudado
      'http://192.168.1.5:3000', 
      'http://192.168.1.7:3000',
      'http://192.168.1.4:3000',
      'http://192.168.1.8:3000',
      'http://10.0.2.2:3000', // Para emulador Android
      'http://localhost:3000', // Para desenvolvimento local
      'http://127.0.0.1:3000',
    ];

    for (String url in urlsTeste) {
      try {
        print('🔍 Testando conectividade com: $url');

        final response = await http
            .get(
              Uri.parse('$url/health'),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                throw Exception('Timeout');
              },
            );

        if (response.statusCode == 200) {
          print('✅ URL funcionando: $url');
          return url;
        }
      } catch (e) {
        print('❌ Falha em $url: $e');
        continue;
      }
    }

    print('⚠️ Nenhuma URL funcionou, usando URL padrão');
    return baseUrl;
  }

  // Testar conectividade com a API
  static Future<bool> testarConectividade() async {
    try {
      final response = await http
          .get(
            Uri.parse('${_obterBaseUrl()}/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }


























// Buscar o estado de um curso específico pelo ID - Baseado na data de fim
static Future<String?> buscarEstadoCurso(int cursoId) async {
  try {
    final response = await http.get(
      Uri.parse('${_obterBaseUrl()}/cursos/$cursoId'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      
      // Primeiro, verificar se tem estado definido na BD
      final estadoBD = responseData['estado']?.toString();
      if (estadoBD != null && estadoBD.isNotEmpty && estadoBD != 'Em Curso') {
        return estadoBD; // Respeitar estado da BD (Ex: "Em breve")
      }
      
      // Só calcular baseado na data se estado for "Em Curso" ou não definido
      final dataFim = responseData['data_fim'];
      if (dataFim != null) {
        try {
          final dataFimParsed = DateTime.parse(dataFim);
          final agora = DateTime.now();
          return agora.isAfter(dataFimParsed) ? 'Terminado' : 'Em Curso';
        } catch (e) {
          print('⚠️ Erro ao analisar data_fim no buscarEstadoCurso: $e');
          return estadoBD ?? 'Em Curso';
        }
      }
      return estadoBD ?? 'Em Curso';
    }
    return null;
  } catch (e) {
    print('❌ Erro ao buscar estado do curso: $e');
    return null;
  }
}








static Future<bool> permissaoLigacaoEspecifica(int id) async {
  try {
    print('🔍 Verificando permissão de role "formando" para id $id...');
    final response = await http.get(Uri.parse('$baseUrl/permissoes/$id'));
    print('📡 Status da resposta: ${response.statusCode}');

    if (response.statusCode != 200) {
      print('❌ Erro na resposta HTTP ao buscar permissão.');
      return false;
    }

    final perm = jsonDecode(response.body) as Map<String, dynamic>;
    print('📋 Permissão recebida: $perm');

    final roles = perm['rolesPermissoes'] as List<dynamic>?;

    if (roles == null || roles.isEmpty) {
      print('⚠️ Nenhum role encontrado na permissão.');
      return false;
    }

    // 🔹 Verifica se existe alguma linha com role "formando"
    final existeFormando = roles.any((r) {
      final role = (r['role']?.toString().toLowerCase() ?? '');
      return role == 'formando';
    });

    print('🔹 Existe role "formando" com idpermissao $id? $existeFormando');
    return existeFormando;
  } catch (e) {
    print('❌ Erro ao verificar permissão $id: $e');
    return false;
  }
}













  // Buscar todos os cursos da API - SOMENTE DADOS REAIS
  static Future<List<Curso>> buscarTodosCursos() async {
    try {
      final response = await http
          .get(
            Uri.parse('${_obterBaseUrl()}/cursos'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout:
                () =>
                    throw Exception(
                      'Timeout: API não respondeu em 10 segundos',
                    ),
          );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Debug avançado
        if (data.isNotEmpty) {
          print('🔍 Primeiro curso recebido:');
          print(data.first);
        }

        final cursos = data
            .map((json) {
              try {
                return Curso(
                  id: json['id'] ?? json['idcurso'],
                  titulo: json['titulo'] ?? 'Sem título',
                  descricao: json['descricao'] ?? 'Sem descrição',
                  estado:
                      json['estado']?.toString() ?? 'Em curso', // Campo crítico
                  dataInicio: json['data_inicio'],
                  dataFim: json['data_fim'],
                  dificuldade: json['dificuldade'] ?? 'Iniciante',
                  pontos: json['pontos'] ?? 0,
                  tema: json['tema'],
                  categoria: _mapearCategoria(json['tema']),
                  avaliacao: _converterParaDouble(json['avaliacao']),
                  inscrito: false,
                  progresso: 0,
                  sincrono: _converterParaBoolean(json['sincrono']),
                  formadorResponsavel: json['formador_responsavel'],
                  informacoes: json['informacoes'],
                  video: json['video'],
                  alertaFormador: json['alerta_formador'],
                  aprenderNoCurso: json['aprender_no_curso'],
                  requisitos: json['requisitos'],
                  publicoAlvo: json['publico_alvo'],
                  dados: json['dados'],
                  duracao: json['duracao'],
                  idioma: json['idioma'],
                  imagemUrl: json['imgcurso'],
                );

                // 🐛 DEBUG curso criado
              } catch (e) {
                print('❌ Erro ao mapear curso: $e');
                return null;
              }
            })
            .whereType<Curso>()
            .toList();
        // Cache local de cursos para fallback offline
        try {
          for (final c in cursos) {
            await LocalDatabase.upsertCurso({
              'id': c.id,
              'titulo': c.titulo,
              'descricao': c.descricao,
              'estado': c.estado,
              'data_inicio': c.dataInicio,
              'data_fim': c.dataFim,
              'dificuldade': c.dificuldade,
              'pontos': c.pontos,
              'tema': c.tema,
              'categoria': c.categoria,
              'avaliacao': c.avaliacao,
              'sincrono': c.sincrono == true ? 1 : 0,
              'imgcurso': c.imagemUrl,
              'favorito': c.favorito ? 1 : 0, // Adicionar campo favorito
              'formador_responsavel': c.formadorResponsavel,
              'informacoes': c.informacoes,
              'video': c.video,
              'alerta_formador': c.alertaFormador,
              'aprender_no_curso': c.aprenderNoCurso,
              'requisitos': c.requisitos,
              'publico_alvo': c.publicoAlvo,
              'dados': c.dados,
              'duracao': c.duracao,
              'idioma': c.idioma,
              'inscrito': c.inscrito ? 1 : 0,
              'progresso': c.progresso,
            });
          }
        } catch (_) {}
        return cursos;
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erro em buscarTodosCursos: $e');
      try {
        final rows = await LocalDatabase.obterCursos();
        return rows
            .map((r) => Curso(
                  id: r['id'] as int?,
                  titulo: (r['titulo'] ?? '') as String,
                  descricao: (r['descricao'] ?? '') as String,
                  dataInicio: r['data_inicio'] as String?,
                  dataFim: r['data_fim'] as String?,
                  dificuldade: (r['dificuldade'] ?? 'Iniciante') as String,
                  pontos: (r['pontos'] ?? 0) as int,
                  tema: r['tema'] as String?,
                  categoria: r['categoria'] as String?,
                  avaliacao: (r['avaliacao'] is num) ? (r['avaliacao'] as num).toDouble() : 0.0,
                  inscrito: (r['inscrito'] ?? 0) == 1,
                  imagemUrl: r['imgcurso'] as String?,
                  progresso: r['progresso'] as int?,
                  sincrono: (r['sincrono'] ?? 0) == 1,
                  estado: r['estado'] as String?,
                  formadorResponsavel: r['formador_responsavel'] as String?,
                  informacoes: r['informacoes'] as String?,
                  video: r['video'] as String?,
                  alertaFormador: r['alerta_formador'] as String?,
                  aprenderNoCurso: r['aprender_no_curso'] as String?,
                  requisitos: r['requisitos'] as String?,
                  publicoAlvo: r['publico_alvo'] as String?,
                  dados: r['dados'] as String?,
                  duracao: r['duracao'] as String?,
                  idioma: r['idioma'] as String?,
                  favorito: (r['favorito'] ?? 0) == 1,
                ))
            .toList();
      } catch (e2) {
        print('❌ Fallback local falhou: $e2');
        return [];
      }
    }
  }

  // Método auxiliar para converter avaliação (string ou número) para double
  static double _converterParaDouble(dynamic valor) {
    if (valor == null) return 0.0;
    if (valor is double) return valor;
    if (valor is int) return valor.toDouble();
    if (valor is String) {
      try {
        return double.parse(valor);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  // Método auxiliar para converter sincrono (string) para boolean
  static bool _converterParaBoolean(dynamic valor) {
    if (valor == null) return false;
    if (valor is bool) return valor;
    if (valor is String) {
      final valorLower = valor.toLowerCase();
      // Verificar especificamente por "síncrono" mas não "assíncrono"
      if (valorLower == 'síncrono' || valorLower == 'sincrono' || valorLower == 'true') {
        return true;
      }
      if (valorLower == 'assíncrono' || valorLower == 'assincrono' || valorLower == 'false') {
        return false;
      }
      // Para outros casos, verificar se contém "síncrono" mas não "assíncrono"
      return valorLower.contains('síncrono') && !valorLower.contains('assíncrono');
    }
    if (valor is int) return valor == 1;
    return false;
  }

  // Mapear tema para categoria (pode ser customizado)
  static String _mapearCategoria(String? tema) {
    if (tema == null) return 'Tecnologia';

    final temaLower = tema.toLowerCase();
    if (temaLower.contains('python') ||
        temaLower.contains('javascript') ||
        temaLower.contains('html') ||
        temaLower.contains('css') ||
        temaLower.contains('front') ||
        temaLower.contains('back')) {
      return 'Programação';
    } else if (temaLower.contains('design') ||
        temaLower.contains('ui') ||
        temaLower.contains('ux')) {
      return 'Design';
    } else if (temaLower.contains('marketing') ||
        temaLower.contains('vendas')) {
      return 'Marketing';
    } else if (temaLower.contains('dados') ||
        temaLower.contains('data') ||
        temaLower.contains('analytics')) {
      return 'Dados';
    } else if (temaLower.contains('negócio') || temaLower.contains('gestão')) {
      return 'Negócios';
    }
    return 'Tecnologia';
  }

  // Buscar categorias disponíveis da API
  static Future<List<String>> buscarCategorias() async {
    try {
      final response = await http
          .get(
            Uri.parse('${_obterBaseUrl()}/cursos/categorias'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((cat) => cat['categoria'] as String).toList();
      } else {
        return _obterCategoriasPadrao();
      }
    } catch (e) {
      return _obterCategoriasPadrao();
    }
  }

  // Buscar temas disponíveis da API
  static Future<List<String>> buscarTemas() async {
    try {
      final response = await http
          .get(
            Uri.parse('${_obterBaseUrl()}/cursos/temas'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<String>();
      } else {
        return _obterTemasPadrao();
      }
    } catch (e) {
      return _obterTemasPadrao();
    }
  }

  // Buscar dificuldades disponíveis da API
  static Future<List<String>> buscarDificuldades() async {
    try {
      final response = await http
          .get(
            Uri.parse('${_obterBaseUrl()}/cursos/dificuldades'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<String>();
      } else {
        return _obterDificuldadesPadrao();
      }
    } catch (e) {
      return _obterDificuldadesPadrao();
    }
  }

  // Categorias padrão como fallback
  static List<String> _obterCategoriasPadrao() {
    return [
      'Todas',
      'Programação',
      'Design',
      'Marketing',
      'Negócios',
      'Tecnologia',
      'Dados',
      'Outras',
    ];
  }

  // Temas padrão como fallback
  static List<String> _obterTemasPadrao() {
    return [
      'Todos',
      'Programação',
      'Design',
      'Marketing',
      'Negócios',
      'Tecnologia',
      'Dados',
    ];
  }

  // Dificuldades padrão como fallback
  static List<String> _obterDificuldadesPadrao() {
    return [
      'Todas',
      'Iniciante',
      'Intermédio', // Corresponde exatamente à base de dados
      'Avançado',
    ];
  }

  // NOTA: Método _obterCursosMock() foi removido.
  // A aplicação agora utiliza EXCLUSIVAMENTE dados da base de dados via API.
  // Não há mais fallback para dados estáticos/mock.

  // Buscar cursos do banco local
  static Future<List<Curso>> buscarCursosLocais() async {
    try {
      // Implementar busca local quando necessário
      return [];
    } catch (e) {
      return [];
    }
  }

  // Buscar meus cursos (inscritos) - USANDO NOVO ENDPOINT
static Future<List<Curso>> buscarMeusCursos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final userId = prefs.getInt('userId');

      if (token == null || userId == null) {
        print('❌ Usuário não logado para buscar meus cursos');
        return [];
      }

      print('📚 Buscando meus cursos para o usuário $userId...');

      String? urlFuncionando = await _encontrarUrlFuncionando();
      if (urlFuncionando == null) {
        print('❌ Nenhuma URL de servidor funcionando');
        return [];
      }

      final response = await http.get(
        Uri.parse('$urlFuncionando/inscricoes/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout ao buscar inscrições'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> inscricoes = responseData['data'];
          final Map<int, int> progressoPorCurso = {1: 70, 2: 100, 3: 90, 4: 50};

          List<Curso> meusCursos = [];
          for (var inscricao in inscricoes) {
            try {
              // DEBUG AVANÇADO
              print('📌 Dados brutos da inscrição: ${jsonEncode(inscricao)}');
              print('🔍 Análise detalhada:');
              print('   - sincrono (bruto): ${inscricao['sincrono']} (${inscricao['sincrono'].runtimeType})');
              print('   - data_fim (bruto): ${inscricao['data_fim']}');
              
              final int? idCurso = inscricao['idcurso'] is int 
                  ? inscricao['idcurso'] 
                  : int.tryParse(inscricao['idcurso'].toString());

              // Usar o estado da base de dados como prioridade
              String estadoCurso = inscricao['estado']?.toString() ?? 'Em Curso';
              
              // Se o estado da BD for válido, usar apenas se for "Em breve" ou similar
              // Calcular estado baseado na data apenas se necessário
              if (estadoCurso == 'Em Curso' && inscricao['data_fim'] != null) {
                try {
                  final dataFim = DateTime.parse(inscricao['data_fim']);
                  final agora = DateTime.now();
                  estadoCurso = agora.isAfter(dataFim) ? 'Terminado' : 'Em Curso';
                  print('   - Data fim: $dataFim vs Agora: $agora = Estado calculado: $estadoCurso');
                } catch (e) {
                  print('⚠️ Erro ao analisar data_fim: $e');
                  estadoCurso = 'Em Curso'; // Fallback
                }
              } else {
                print('   - Estado da BD: $estadoCurso (mantido)');
              }
              
              // Processar sincrono
              final bool sincronoProcessado = _converterParaBoolean(inscricao['sincrono']);
              print('   - sincrono (processado): $sincronoProcessado');

              final curso = Curso(
                id: idCurso,
                titulo: inscricao['titulo'] ?? 'Sem título',
                descricao: inscricao['descricao'] ?? 'Sem descrição',
                estado: estadoCurso, // Usando o valor tratado
                dataInicio: inscricao['data_inicio'],
                dataFim: inscricao['data_fim'],
                dificuldade: inscricao['dificuldade'] ?? 'Iniciante',
                pontos: inscricao['pontos'] ?? 0,
                tema: inscricao['tema'],
                categoria: _mapearCategoria(inscricao['tema']),
                avaliacao: _converterParaDouble(inscricao['avaliacao']),
                inscrito: true,
                progresso: progressoPorCurso[idCurso] ?? 100,
                sincrono: sincronoProcessado,
                imagemUrl: inscricao['imgcurso']?.toString(),
                formadorResponsavel: inscricao['formador_responsavel'],
                informacoes: inscricao['informacoes'],
                video: inscricao['video'],
                alertaFormador: inscricao['alerta_formador'],
                aprenderNoCurso: inscricao['aprender_no_curso'],
                requisitos: inscricao['requisitos'],
                publicoAlvo: inscricao['publico_alvo'],
                dados: inscricao['dados'],
                duracao: inscricao['duracao'],
                idioma: inscricao['idioma'],
              );

              print('✅ Curso criado - ${curso.titulo}:');
              print('   - Estado: ${curso.estado} (${curso.estado.runtimeType})');
              print('   - Sincrono: ${curso.sincrono} (${curso.sincrono.runtimeType})');
              print('   - Deve ser removido?: ${curso.sincrono == false && curso.estado == 'Terminado'}');
              meusCursos.add(curso);
              // Cache local: marcar como inscrito para fallback offline
              try {
                if (curso.id != null) {
                  await LocalDatabase.upsertCurso({
                    'id': curso.id,
                    'titulo': curso.titulo,
                    'descricao': curso.descricao,
                    'data_inicio': curso.dataInicio,
                    'data_fim': curso.dataFim,
                    'dificuldade': curso.dificuldade,
                    'pontos': curso.pontos,
                    'tema': curso.tema,
                    'categoria': curso.categoria,
                    'avaliacao': curso.avaliacao,
                    'imgcurso': curso.imagemUrl,
                    'inscrito': 1,
                    'favorito': curso.favorito ? 1 : 0, // Adicionar campo favorito
                    'sincrono': (curso.sincrono ?? false) ? 1 : 0,
                    'estado': curso.estado,
                    'formador_responsavel': curso.formadorResponsavel,
                    'informacoes': curso.informacoes,
                    'video': curso.video,
                    'alerta_formador': curso.alertaFormador,
                    'aprender_no_curso': curso.aprenderNoCurso,
                    'requisitos': curso.requisitos,
                    'publico_alvo': curso.publicoAlvo,
                    'dados': curso.dados,
                    'duracao': curso.duracao,
                    'idioma': curso.idioma,
                    'progresso': curso.progresso,
                  });
                }
              } catch (_) {}
            } catch (e) {
              print('⚠️ Erro ao processar inscrição: $e');
              continue;
            }
          }
          return meusCursos;
        }
      }
      print('❌ Erro ao buscar cursos: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Erro fatal em buscarMeusCursos: $e');
      // Fallback local: retornar cursos marcados como inscritos
      try {
        final rows = await LocalDatabase.obterCursosInscritosLocais();
        return rows
            .map((r) => Curso(
                  id: r['id'] as int?,
                  titulo: (r['titulo'] ?? '') as String,
                  descricao: (r['descricao'] ?? '') as String,
                  dataInicio: r['data_inicio'] as String?,
                  dataFim: r['data_fim'] as String?,
                  dificuldade: (r['dificuldade'] ?? 'Iniciante') as String,
                  pontos: (r['pontos'] ?? 0) as int,
                  tema: r['tema'] as String?,
                  categoria: r['categoria'] as String?,
                  avaliacao: (r['avaliacao'] is num) ? (r['avaliacao'] as num).toDouble() : 0.0,
                  inscrito: true,
                  imagemUrl: r['imgcurso'] as String?,
                  progresso: r['progresso'] as int?,
                  sincrono: (r['sincrono'] ?? 0) == 1,
                  estado: r['estado'] as String?,
                  favorito: (r['favorito'] ?? 0) == 1, // Adicionar campo favorito
                  formadorResponsavel: r['formador_responsavel'] as String?,
                  informacoes: r['informacoes'] as String?,
                  video: r['video'] as String?,
                  alertaFormador: r['alerta_formador'] as String?,
                  aprenderNoCurso: r['aprender_no_curso'] as String?,
                  requisitos: r['requisitos'] as String?,
                  publicoAlvo: r['publico_alvo'] as String?,
                  dados: r['dados'] as String?,
                  duracao: r['duracao'] as String?,
                  idioma: r['idioma'] as String?,
                ))
            .toList();
      } catch (e2) {
        print('❌ Fallback local (meus cursos) falhou: $e2');
        return [];
      }
    }
  }

  // Buscar estatísticas de um curso específico
  static Future<Map<String, dynamic>?> buscarEstatisticasCurso(
    int idCurso,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('${_obterBaseUrl()}/cursos/$idCurso/estatisticas'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return jsonResponse['data'];
        }
      }

      print('❌ Erro ao buscar estatísticas: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ Erro na requisição de estatísticas: $e');
      return null;
    }
  }

  // Buscar módulos/materiais de um curso específico
  static Future<List<Map<String, dynamic>>> buscarModulosCurso(
    int idCurso,
  ) async {
    try {
      print('🔍 Buscando módulos para curso ID: $idCurso');

      final response = await http
          .get(
            Uri.parse('${_obterBaseUrl()}/cursos/$idCurso/modulos'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      print('📡 Status da resposta: ${response.statusCode}');
      print('📡 Body da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic rawResponse = json.decode(response.body);
        // Se for um array direto (sem wrapper), processar diretamente
        if (rawResponse is List) {
          print('⚠️ API retornou array direto (sem wrapper success/data)');
          final List<dynamic> modulosJson = rawResponse;
          return modulosJson.cast<Map<String, dynamic>>();
        }

        // Se for um objeto com wrapper success/data
        if (rawResponse is Map<String, dynamic>) {
          print('✅ API retornou objeto com wrapper');
          final Map<String, dynamic> jsonResponse = rawResponse;

          if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
            final List<dynamic> modulosJson = jsonResponse['data'];
            print('✅ Encontrados \\${modulosJson.length} módulos');
            return modulosJson.cast<Map<String, dynamic>>();
          } else {
            print('⚠️ Resposta sem sucesso ou sem dados: \\${jsonResponse}');
          }
        }
      }

      print('❌ Erro ao buscar módulos: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Erro na requisição de módulos: $e');
      return [];
    }
  }

  // Buscar aulas de um curso específico
  static Future<List<Map<String, dynamic>>> buscarAulasCurso(
    int idCurso,
  ) async {
    try {
      print('🔍 Buscando aulas para curso ID: $idCurso');

      final response = await http
          .get(
            Uri.parse('${_obterBaseUrl()}/cursos/$idCurso/aulas'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      print('📡 Status da resposta (aulas): ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic rawResponse = json.decode(response.body);
        print('📡 Resposta bruta (aulas): $rawResponse');

        if (rawResponse is Map<String, dynamic> &&
            rawResponse['success'] == true) {
          final dynamic dados = rawResponse['data'];
          if (dados is List) {
            final List<Map<String, dynamic>> aulasJson =
                dados.cast<Map<String, dynamic>>();
            print('✅ ${aulasJson.length} aulas recebidas com sucesso');
            return aulasJson;
          } else {
            print('⚠️ Resposta sem dados de aulas válidos: $dados');
          }
        }
      }

      print('❌ Erro ao buscar aulas: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Erro na requisição de aulas: $e');
      return [];
    }
  }

  // Buscar materiais de apoio de um curso específico
  static Future<List<Map<String, dynamic>>> buscarMateriaisApoio(
    int idCurso,
  ) async {
    try {
      print('🔍 Buscando materiais de apoio para curso ID: $idCurso');

      final response = await http
          .get(
            Uri.parse('${_obterBaseUrl()}/cursos/$idCurso/materiais-apoio'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      print('📡 Status da resposta (materiais): ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic rawResponse = json.decode(response.body);
        print('📡 Resposta bruta (materiais): $rawResponse');

        if (rawResponse is Map<String, dynamic> &&
            rawResponse['success'] == true) {
          final dynamic dados = rawResponse['data'];
          if (dados is List) {
            final List<Map<String, dynamic>> materiaisJson =
                dados.cast<Map<String, dynamic>>();
            print(
              '✅ ${materiaisJson.length} materiais de apoio recebidos com sucesso',
            );
            return materiaisJson;
          } else {
            print('⚠️ Resposta sem dados de materiais válidos: $dados');
          }
        }
      }

      print('❌ Erro ao buscar materiais de apoio: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Erro na requisição de materiais: $e');
      return [];
    }
  }

  // Buscar quizzes de um curso específico
  static Future<List<Map<String, dynamic>>> buscarQuizzes(
    int idCurso,
    String idUtilizador,
  ) async {
    try {
      print('🔍 Buscando quizzes para curso ID: $idCurso, utilizador: $idUtilizador');

      // Primeiro, encontrar a URL que funciona
      final urlFuncionando = await _encontrarUrlFuncionando();
      final baseUrlAtual = urlFuncionando ?? _obterBaseUrl();
      
      print('🌐 Usando URL para quizzes: $baseUrlAtual');

      final response = await http
          .get(
            Uri.parse('$baseUrlAtual/quizzes/curso/$idCurso/$idUtilizador'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      print('📡 Status da resposta (quizzes): ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic rawResponse = json.decode(response.body);
        print('📡 Resposta bruta (quizzes): $rawResponse');

        if (rawResponse is Map<String, dynamic> &&
            rawResponse['success'] == true) {
          final dynamic dados = rawResponse['data'];
          if (dados is List) {
            final List<Map<String, dynamic>> quizzesJson =
                dados.cast<Map<String, dynamic>>();
            print(
              '✅ ${quizzesJson.length} quizzes recebidos com sucesso',
            );
            return quizzesJson;
          } else {
            print('⚠️ Resposta sem dados de quizzes válidos: $dados');
          }
        }
      }

      print('❌ Erro ao buscar quizzes: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Erro na requisição de quizzes: $e');
      return [];
    }
  }

  // Buscar um quiz específico com suas questões
  static Future<Map<String, dynamic>?> buscarQuiz(
    int idQuiz,
    String idUtilizador,
  ) async {
    try {
      print('🔍 Buscando quiz ID: $idQuiz para utilizador: $idUtilizador');

      final response = await http
          .get(
            Uri.parse('${_obterBaseUrl()}/quizzes/$idQuiz/$idUtilizador'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      print('📡 Status da resposta (quiz): ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic rawResponse = json.decode(response.body);
        print('📡 Resposta bruta (quiz): $rawResponse');

        if (rawResponse is Map<String, dynamic> &&
            rawResponse['success'] == true) {
          final dynamic dados = rawResponse['data'];
          if (dados is Map<String, dynamic>) {
            print('✅ Quiz recebido com sucesso');
            return dados;
          } else {
            print('⚠️ Resposta sem dados de quiz válidos: $dados');
          }
        }
      }

      print('❌ Erro ao buscar quiz: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ Erro na requisição de quiz: $e');
      return null;
    }
  }

  // Submeter respostas do quiz
  static Future<Map<String, dynamic>?> submeterQuiz(
    int idQuiz,
    String idUtilizador,
    List<Map<String, dynamic>> respostas,
  ) async {
    try {
      print('📝 Submetendo respostas do quiz ID: $idQuiz');

      // Primeiro, encontrar a URL que funciona
      final urlFuncionando = await _encontrarUrlFuncionando();
      final baseUrlAtual = urlFuncionando ?? _obterBaseUrl();

      final response = await http
          .post(
            Uri.parse('$baseUrlAtual/quizzes/$idQuiz/submeter'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'id_utilizador': idUtilizador,
              'respostas': respostas,
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('📡 Status da resposta (submissão): ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic rawResponse = json.decode(response.body);
        print('📡 Resposta bruta (submissão): $rawResponse');

        if (rawResponse is Map<String, dynamic> &&
            rawResponse['success'] == true) {
          final dynamic dados = rawResponse['data'];
          if (dados is Map<String, dynamic>) {
            print('✅ Quiz submetido com sucesso');
            return dados;
          } else {
            print('⚠️ Resposta sem dados de submissão válidos: $dados');
          }
        }
      }

      print('❌ Erro ao submeter quiz: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ Erro na requisição de submissão: $e');
      return null;
    }
  }

  // Filtrar cursos por categoria
  static List<Curso> filtrarPorCategoria(
    List<Curso> cursos,
    String? categoria,
  ) {
    if (categoria == null || categoria.isEmpty || categoria == 'Todas') {
      return cursos;
    }
    return cursos.where((curso) => curso.categoria == categoria).toList();
  }

  // Filtrar cursos por tema (substitui o filtro por categoria na interface)
  static List<Curso> filtrarPorTema(List<Curso> cursos, String? tema) {
    if (tema == null || tema.isEmpty || tema == 'Todos') {
      return cursos;
    }
    return cursos
        .where((curso) => curso.tema?.toLowerCase() == tema.toLowerCase())
        .toList();
  }

  // Filtrar cursos por múltiplos temas (novo método para seleção múltipla)
  static List<Curso> filtrarPorTemas(List<Curso> cursos, List<String> temas) {
    if (temas.isEmpty) {
      return cursos; // Se nenhum tema selecionado, mostrar todos
    }

    return cursos
        .where(
          (curso) => temas.any(
            (tema) => curso.tema?.toLowerCase() == tema.toLowerCase(),
          ),
        )
        .toList();
  }

  // Filtrar cursos por dificuldade
  static List<Curso> filtrarPorDificuldade(
    List<Curso> cursos,
    String? dificuldade,
  ) {
    print('🔍 Filtrar por dificuldade: "${dificuldade}"');

    if (dificuldade == null || dificuldade.isEmpty || dificuldade == 'Todas') {
      print(
        '✅ Dificuldade é "Todas" - retornando todos os ${cursos.length} cursos',
      );
      return cursos;
    }

    print('📊 Cursos disponíveis para filtrar:');
    for (var curso in cursos) {
      print('   - "${curso.titulo}": dificuldade = "${curso.dificuldade}"');
    }

    final resultado =
        cursos
            .where(
              (curso) =>
                  curso.dificuldade.toLowerCase() == dificuldade.toLowerCase(),
            )
            .toList();

    print(
      '✅ Filtro aplicado - ${resultado.length} cursos correspondem à dificuldade "${dificuldade}"',
    );
    return resultado;
  }

  // Filtrar cursos por múltiplas dificuldades (novo método para seleção múltipla)
  static List<Curso> filtrarPorDificuldades(List<Curso> cursos, List<String> dificuldades) {
    print('🔍 Filtrar por dificuldades: ${dificuldades}');

    if (dificuldades.isEmpty) {
      print('✅ Nenhuma dificuldade selecionada - retornando todos os ${cursos.length} cursos');
      return cursos; // Se nenhuma dificuldade selecionada, mostrar todos
    }

    final resultado = cursos.where((curso) => 
      dificuldades.any((dificuldade) => 
        curso.dificuldade.toLowerCase() == dificuldade.toLowerCase()
      )
    ).toList();

    print('✅ Filtro aplicado - ${resultado.length} cursos correspondem às dificuldades "${dificuldades.join(', ')}"');
    return resultado;
  }

  // Filtrar cursos por tipo (síncrono/assíncrono)
  static List<Curso> filtrarPorTipo(List<Curso> cursos, String? tipo) {
    if (tipo == null || tipo.isEmpty || tipo == 'Todos') {
      return cursos;
    }

    // Filtrar baseado no tipo
    return cursos.where((curso) {
      if (tipo == 'Síncrono') {
        return curso.sincrono == true;
      } else if (tipo == 'Assíncrono') {
        return curso.sincrono == false;
      }
      return true; // Caso 'Todos'
    }).toList();
  }

  // Buscar cursos por texto
  static List<Curso> buscarPorTexto(List<Curso> cursos, String texto) {
    if (texto.isEmpty) return cursos;

    final textoLower = texto.toLowerCase();
    return cursos.where((curso) {
      return curso.titulo.toLowerCase().contains(textoLower) ||
          (curso.tema?.toLowerCase().contains(textoLower) ?? false);
    }).toList();
  }

  // Ordenar cursos
  static List<Curso> ordenarCursos(List<Curso> cursos, String criterio) {
    final List<Curso> cursosOrdenados = List.from(cursos);

    switch (criterio) {
      case 'Título A-Z':
        cursosOrdenados.sort((a, b) => a.titulo.compareTo(b.titulo));
        break;
      case 'Título Z-A':
        cursosOrdenados.sort((a, b) => b.titulo.compareTo(a.titulo));
        break;
      case 'Dificuldade':
        cursosOrdenados.sort((a, b) {
          final ordemDificuldade = {
            'iniciante': 1,
            'intermediário': 2,
            'avançado': 3,
          };
          return (ordemDificuldade[a.dificuldade.toLowerCase()] ?? 1).compareTo(
            ordemDificuldade[b.dificuldade.toLowerCase()] ?? 1,
          );
        });
        break;
      case 'Pontos':
        cursosOrdenados.sort((a, b) => b.pontos.compareTo(a.pontos));
        break;
      case 'Avaliação':
        cursosOrdenados.sort(
          (a, b) => (b.avaliacao ?? 0).compareTo(a.avaliacao ?? 0),
        );
        break;
      default:
        break;
    }

    return cursosOrdenados;
  }

  // NOVAS FUNÇÕES DINÂMICAS

  // Inscrever-se em um curso
 static Future<Map<String, dynamic>> inscreverNoCurso(
  int cursoId, {
  String? nome,
  String? email,
  String? objetivos,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final userId = prefs.getInt('userId');

    if (token == null || userId == null) {
      print('❌ Usuário não logado');
      return {'success': false, 'message': 'Usuário não logado'};
    }

    print('📝 Inscrevendo no curso $cursoId...');

    final response = await http
        .post(
          Uri.parse('${_obterBaseUrl()}/inscricoes'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'idcurso': cursoId,
            'nome': nome ?? '',
            'email': email ?? '',
            'objetivos': objetivos ?? 'Adquirir conhecimentos na área do curso',
          }),
        )
        .timeout(const Duration(seconds: 10));

    print('📡 Resposta da inscrição: ${response.statusCode}');
    print('📡 Body: ${response.body}');

    final responseData = json.decode(response.body);

    if (response.statusCode == 201 && responseData['success'] == true) {
      print('✅ Inscrição realizada com sucesso!');
      return {'success': true, 'message': 'Inscrição realizada com sucesso!'};
    } else if (response.statusCode == 400) {
      print('⚠️ ${responseData['message']}');
      return {'success': false, 'message': responseData['message']};
    }

    print('❌ Erro ao inscrever: ${response.statusCode}');
    return {'success': false, 'message': 'Erro ao inscrever no curso'};
  } catch (e) {
    print('❌ Erro na requisição de inscrição: $e');
    return {'success': false, 'message': 'Erro inesperado: $e'};
  }
}


  // Verificar se o usuário está inscrito em um curso
  static Future<bool> verificarInscricao(int cursoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final userId = prefs.getInt('userId');

      if (token == null || userId == null) {
        print('❌ Token ou userId não encontrados para verificar inscrição');
        return false;
      }

      final url = '${_obterBaseUrl()}/inscricoes/$userId/curso/$cursoId';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final inscrito = responseData['inscrito'] == true;
        return inscrito;
      }

      print('❌ Erro ao verificar inscrição - Status: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ Erro ao verificar inscrição: $e');
      return false;
    }
  }

  // Cancelar inscrição em um curso
  static Future<bool> cancelarInscricao(int cursoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final userId = prefs.getInt('userId');

      if (token == null || userId == null) {
        print('❌ Usuário não logado');
        return false;
      }

      print('🗑️ Cancelando inscrição no curso $cursoId...');

      final response = await http
          .delete(
            Uri.parse('${_obterBaseUrl()}/inscricoes/$userId/curso/$cursoId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('📡 Resposta do cancelamento: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          print('✅ Inscrição cancelada com sucesso!');
          return true;
        }
      }

      print('❌ Erro ao cancelar inscrição: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ Erro na requisição de cancelamento: $e');
      return false;
    }
  }

  // Atualizar progresso do curso
  static Future<bool> atualizarProgresso(int cursoId, int progresso) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final userId = prefs.getInt(
        'userId',
      ); // Corrigido: userId em vez de user_id

      if (token == null || userId == null) {
        print('Usuário não logado');
        return false;
      }

      final response = await http.put(
        Uri.parse('${_obterBaseUrl()}/inscricoes/$userId/$cursoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'progresso': progresso}),
      );

      if (response.statusCode == 200) {
        print('Progresso atualizado com sucesso');
        return true;
      } else {
        print('Erro ao atualizar progresso: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Erro ao atualizar progresso: $e');
      return false;
    }
  }

  // Adicionar curso aos favoritos
  static Future<bool> adicionarAosFavoritos(int cursoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final userId = prefs.getInt(
        'userId',
      ); // Corrigido: userId em vez de user_id

      if (token == null || userId == null) {
        print('Usuário não logado');
        return false;
      }

      final response = await http.post(
        Uri.parse('${_obterBaseUrl()}/favoritos/${userId}/${cursoId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Curso adicionado aos favoritos');
        return true;
      } else {
        print('Erro ao adicionar aos favoritos: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Erro ao adicionar aos favoritos: $e');
      return false;
    }
  }

  // Remover curso dos favoritos
  static Future<bool> removerDosFavoritos(int cursoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(
        'userId',
      ); // Corrigido: userId em vez de user_id
      final token = prefs.getString('jwt_token');

      if (userId == null || token == null) {
        return false;
      }

      final response = await http.delete(
        Uri.parse('${_obterBaseUrl()}/favoritos/$userId/$cursoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erro ao remover dos favoritos: $e');
      return false;
    }
  }

  // Verificar se um curso está nos favoritos
  static Future<bool> verificarFavorito(int cursoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(
        'userId',
      ); // Corrigido: userId em vez de user_id
      final token = prefs.getString('jwt_token');

      if (userId == null || token == null) {
        print('❌ verificarFavorito - Usuário não logado');
        return false;
      }

      print(
        '🔍 verificarFavorito - Verificando curso $cursoId para usuário $userId',
      );

      final url = '${_obterBaseUrl()}/favoritos/$userId/verifica/$cursoId';
      print('🌐 URL da requisição: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Resposta da API - Status: ${response.statusCode}');
      print('📥 Resposta da API - Corpo: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final isFavorito = data['isFavorito'] ?? false;
        print(
          '✅ Resultado da verificação: ${isFavorito ? "É favorito" : "Não é favorito"}',
        );
        return isFavorito;
      }

      print('❌ Resposta não bem-sucedida: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ Erro ao verificar favorito: $e');
      print('❌ Tipo do erro: ${e.runtimeType}');
      if (e is http.ClientException) {
        print('❌ Detalhes do erro HTTP: ${e.message}');
      }
      // Fallback offline: verificar favorito na base de dados local
      try {
        print('🔄 Tentando fallback local para verificar favorito...');
        final curso = await LocalDatabase.obterCursoPorId(cursoId);
        if (curso != null) {
          final isFavorito = (curso['favorito'] ?? 0) == 1;
          print('✅ Fallback local: curso ${curso['titulo']} é favorito: $isFavorito');
          return isFavorito;
        }
        return false;
      } catch (e2) {
        print('❌ Fallback local (verificar favorito) falhou: $e2');
        return false;
      }
    }
  }

  // Buscar todos os cursos favoritos do usuário
  static Future<List<Curso>> buscarFavoritos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(
        'userId',
      ); // Corrigido: userId em vez de user_id
      final token = prefs.getString('jwt_token');

      if (userId == null || token == null) {
        print('❌ Usuário não logado para buscar favoritos');
        return [];
      }

      final response = await http.get(
        Uri.parse('${_obterBaseUrl()}/favoritos/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isEmpty) {
          return [];
        }

        // Mapear para objetos Curso
        final favoritos =
            data
                .map((json) {
                  try {
                    final curso = Curso(
                      id: json['id'] ?? json['idcurso'],
                      titulo: json['titulo'] ?? 'Sem título',
                      descricao: json['descricao'] ?? 'Sem descrição',
                      dataInicio: json['data_inicio'],
                      dataFim: json['data_fim'],
                      dificuldade: json['dificuldade'] ?? 'Iniciante',

                      pontos: json['pontos'] ?? 0,
                      tema: json['tema'],
                      categoria: _mapearCategoria(json['tema']),
                      avaliacao: _converterParaDouble(json['avaliacao']),
                      inscrito: false,
                      progresso: 0,
                      sincrono:
                          json['tipo'] == 'presencial' ||
                          json['sincrono'] == true,
                      formadorResponsavel: json['formador_responsavel'],
                      informacoes: json['informacoes'],
                      video: json['video'],
                      alertaFormador: json['alerta_formador'],
                      aprenderNoCurso: json['aprender_no_curso'],
                      requisitos: json['requisitos'],
                      publicoAlvo: json['publico_alvo'],
                      dados: json['dados'],
                      duracao: json['duracao'],
                      idioma: json['idioma'],
                      imagemUrl: json['imgcurso'],
                      favorito: true, // Já está nos favoritos
                    );
                    return curso;
                  } catch (e) {
                    print('❌ Erro ao mapear curso favorito: $e');
                    return null;
                  }
                })
                .whereType<Curso>()
                .toList();

        return favoritos;
      }

      return [];
    } catch (e) {
      print('❌ Erro ao buscar favoritos: $e');
      // Fallback offline: buscar favoritos da base de dados local
      try {
        print('🔄 Tentando fallback local para favoritos...');
        final rows = await LocalDatabase.obterFavoritosLocais();
        print('📚 Encontrados ${rows.length} favoritos no cache local');
        
        if (rows.isEmpty) {
          print('⚠️ Nenhum favorito encontrado no cache local');
          return [];
        }
        
        final favoritos = rows
            .map((r) => Curso(
                  id: r['id'] as int?,
                  titulo: (r['titulo'] ?? '') as String,
                  descricao: (r['descricao'] ?? '') as String,
                  dataInicio: r['data_inicio'] as String?,
                  dataFim: r['data_fim'] as String?,
                  dificuldade: (r['dificuldade'] ?? 'Iniciante') as String,
                  pontos: (r['pontos'] ?? 0) as int,
                  tema: r['tema'] as String?,
                  categoria: r['categoria'] as String?,
                  avaliacao: (r['avaliacao'] is num) ? (r['avaliacao'] as num).toDouble() : 0.0,
                  inscrito: (r['inscrito'] ?? 0) == 1,
                  imagemUrl: r['imgcurso'] as String?,
                  progresso: r['progresso'] as int?,
                  sincrono: (r['sincrono'] ?? 0) == 1,
                  estado: r['estado'] as String?,
                  formadorResponsavel: r['formador_responsavel'] as String?,
                  informacoes: r['informacoes'] as String?,
                  video: r['video'] as String?,
                  alertaFormador: r['alerta_formador'] as String?,
                  aprenderNoCurso: r['aprender_no_curso'] as String?,
                  requisitos: r['requisitos'] as String?,
                  publicoAlvo: r['publico_alvo'] as String?,
                  dados: r['dados'] as String?,
                  duracao: r['duracao'] as String?,
                  idioma: r['idioma'] as String?,
                  favorito: true, // Sempre true para favoritos locais
                ))
            .toList();
        
        print('✅ Fallback local bem-sucedido: ${favoritos.length} favoritos carregados');
        return favoritos;
      } catch (e2) {
        print('❌ Fallback local (favoritos) falhou: $e2');
        return [];
      }
    }
  }

  // Alternar estado de favorito (adicionar ou remover)
  static Future<bool> alternarFavorito(int cursoId) async {
    // Primeiro verificar se já é favorito
    final isFavorito = await verificarFavorito(cursoId);
    print(
      '🔍 alternarFavorito - Estado atual: ${isFavorito ? "É favorito" : "Não é favorito"}',
    );

    bool resultado = false;

    if (isFavorito) {
      // Se já é favorito, remover
      final removido = await removerDosFavoritos(cursoId);
      print(
        '🔄 Removendo dos favoritos - Resultado: ${removido ? "Sucesso" : "Falha"}',
      );
      resultado = false; // Retorna false quando removido com sucesso
    } else {
      // Se não é favorito, adicionar
      final adicionado = await adicionarAosFavoritos(cursoId);
      print(
        '🔄 Adicionando aos favoritos - Resultado: ${adicionado ? "Sucesso" : "Falha"}',
      );
      resultado = true; // Retorna true quando adicionado com sucesso
    }

    // Atualizar estado local na base de dados
    try {
      await LocalDatabase.atualizarFavorito(cursoId, resultado);
      print('✅ Estado de favorito atualizado localmente: $resultado');
    } catch (e) {
      print('⚠️ Erro ao atualizar favorito localmente: $e');
    }

    // Verificar estado final após a operação
    final estadoFinal = await verificarFavorito(cursoId);
    print(
      '✅ Estado final após alteração: ${estadoFinal ? "É favorito" : "Não é favorito"}',
    );
    print('📤 alternarFavorito retornando: $resultado');

    return resultado;
  }

  // MÉTODOS UTILITÁRIOS

  // Verificar se a API está disponível
  static Future<bool> verificarStatusAPI() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${_obterBaseUrl()}/status',
            ), // Endpoint para verificar se API está funcionando
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ API não está disponível: $e');
      return false;
    }
  }

  // Método para debug - mostrar informações do sistema
  static Future<void> debugInfo() async {
    print('🔍 === DEBUG INFO - CURSO SERVICE ===');
    print('🌐 URL da API: $baseUrl');

    // Verificar status da API
    final apiDisponivel = await verificarStatusAPI();
    print(
      '📡 Status da API: ${apiDisponivel ? "✅ Disponível" : "❌ Indisponível"}',
    );

    // Verificar dados locais
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final userId = prefs.getInt(
      'userId',
    ); // Corrigido: userId em vez de user_id

    print('🔐 Token JWT: ${token != null ? "✅ Presente" : "❌ Ausente"}');
    print('👤 User ID: ${userId != null ? "✅ $userId" : "❌ Ausente"}');

    // Tentar buscar cursos
    try {
      final cursos = await buscarTodosCursos();
      print('📚 Cursos encontrados: ${cursos.length}');
      if (cursos.isNotEmpty) {
        print('📋 Primeiro curso: ${cursos.first.titulo}');
      }
    } catch (e) {
      print('❌ Erro ao buscar cursos: $e');
    }

    print('🔍 === FIM DEBUG INFO ===');
  }

  // Sincronizar dados com API (recarregar tudo)
  static Future<void> sincronizarDados() async {
    try {
      print('Iniciando sincronização de dados...');

      // Buscar todos os cursos e armazenar localmente se necessário
      await buscarTodosCursos();

      // Buscar meus cursos
      await buscarMeusCursos();

      // Sincronizar notas finais
      await _sincronizarNotasFinais();

      print('Sincronização concluída');
    } catch (e) {
      // Erro na sincronização - silencioso em produção
    }
  }

  // Sincronizar notas finais dos cursos concluídos
  static Future<void> _sincronizarNotasFinais() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      
      if (userId == null) {
        print('❌ UserId não encontrado para sincronizar notas');
        return;
      }

      // Buscar meus cursos para obter os IDs dos cursos concluídos
      final meusCursos = await buscarMeusCursos();
      final cursosConcluidos = meusCursos.where((curso) => curso.estado == 'Terminado').toList();
      
      print('🔄 Sincronizando notas de ${cursosConcluidos.length} cursos concluídos...');
      
      for (final curso in cursosConcluidos) {
        if (curso.id != null) {
          try {
            // Importar o FormInscricoesService aqui para evitar dependência circular
            final nota = await _fetchNotaFinalAPI(curso.id!, userId);
            if (nota != null) {
              await LocalDatabase.upsertNotaFinal(curso.id!, userId, nota);
              print('✅ Nota sincronizada para curso ${curso.titulo}: $nota');
            }
          } catch (e) {
            print('❌ Erro ao sincronizar nota do curso ${curso.titulo}: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Erro na sincronização de notas: $e');
    }
  }

  // Método auxiliar para buscar nota final da API
  static Future<double?> _fetchNotaFinalAPI(int idCurso, int userid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      
      if (token == null) return null;

      String? urlFuncionando = await _encontrarUrlFuncionando();
      if (urlFuncionando == null) return null;

      final url = Uri.parse('$urlFuncionando/inscricoes/curso/$idCurso/formando/$userid/nota');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return (jsonData['notaFinal'] as num?)?.toDouble();
      }
    } catch (e) {
      print('❌ Erro ao buscar nota da API: $e');
    }
    return null;
  }

  // Obter dados do utilizador logado
  static Future<Map<String, String?>> obterDadosUtilizador() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final userId = prefs.getInt('userId');

      if (token == null || userId == null) {
        return {'nome': null, 'email': null};
      }

      // Buscar dados do utilizador na API
      final response = await http
          .get(
            Uri.parse('$baseUrl/utilizadores/$userId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return {'nome': userData['nome'], 'email': userData['email']};
      }

      // Fallback para dados locais se API falhar
      return {
        'nome': prefs.getString('userName'),
        'email': prefs.getString('userEmail'),
      };
    } catch (e) {
      print('❌ Erro ao obter dados do utilizador: $e');
      // Fallback para dados locais
      try {
        final prefs = await SharedPreferences.getInstance();
        return {
          'nome': prefs.getString('userName'),
          'email': prefs.getString('userEmail'),
        };
      } catch (e) {
        return {'nome': null, 'email': null};
      }
    }
  }

  // Verificar vagas disponíveis de um curso
  static Future<int> verificarVagasDisponiveis(int cursoId) async {
    try {
      print('🔍 Verificando vagas para curso $cursoId...');

      final response = await http
          .get(
            Uri.parse('$baseUrl/cursos/$cursoId/vagas'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      print('📡 Status da resposta: ${response.statusCode}');
      print('📡 Body da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('📋 Dados recebidos: $responseData');

        if (responseData['success'] == true && responseData['data'] != null) {
          final vagas = responseData['data']['vagas_disponiveis'] ?? 0;
          print('✅ Vagas disponíveis retornadas: $vagas');
          return vagas;
        } else {
          print('⚠️ Resposta sem sucesso ou dados nulos');
        }
      } else {
        print('❌ Erro HTTP: ${response.statusCode}');
        print('❌ Mensagem: ${response.body}');
      }

      print('⚠️ Retornando 0 vagas por erro');
      return 0; // Assumir 0 vagas em caso de erro
    } catch (e) {
      print('❌ Erro na requisição de vagas: $e');
      return 0;
    }
  }

  // Fazer download de material (nova versão)
  static Future<bool> downloadMaterial({
    required String url,
    required String fileName,
  }) async {
    try {
      print('📥 Iniciando download: $url');
      await FileDownloader.downloadFileToDownloads(url, fileName);
      print('✅ Download concluído!');
      return true;
    } catch (e) {
      print('❌ Erro ao fazer download: $e');
      return false;
    }
  }

  // Obter URL do vídeo da aula
  static String? obterUrlVideoAula(Map<String, dynamic> aula) {
    final videoUrl = aula['video_url']?.toString();
    if (videoUrl != null && videoUrl.isNotEmpty && videoUrl != 'null') {
      print('🎥 URL do vídeo encontrada: $videoUrl');
      return videoUrl;
    }
    print('⚠️ Nenhuma URL de vídeo disponível para esta aula');
    return null;
  }

  // Sincronizar favoritos locais com a API quando estiver online
  static Future<void> sincronizarFavoritosLocais() async {
    try {
      print('🔄 Iniciando sincronização de favoritos locais...');
      
      // Verificar se a API está disponível
      final apiDisponivel = await testarConectividade();
      if (!apiDisponivel) {
        print('⚠️ API não disponível, mantendo favoritos locais');
        return;
      }

      // Obter favoritos locais
      final favoritosLocais = await LocalDatabase.obterFavoritosLocais();
      print('📚 Encontrados ${favoritosLocais.length} favoritos locais para sincronizar');

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final token = prefs.getString('jwt_token');

      if (userId == null || token == null) {
        print('❌ Usuário não logado para sincronizar favoritos');
        return;
      }

      // Para cada favorito local, verificar se ainda está na API
      for (final favorito in favoritosLocais) {
        final cursoId = favorito['id'] as int?;
        if (cursoId == null) continue;

        try {
          // Verificar se o curso ainda é favorito na API
          final isFavoritoNaAPI = await verificarFavorito(cursoId);
          
          // Se não é mais favorito na API, remover do local
          if (!isFavoritoNaAPI) {
            print('🗑️ Removendo favorito local que não existe mais na API: curso $cursoId');
            await LocalDatabase.atualizarFavorito(cursoId, false);
          }
        } catch (e) {
          print('⚠️ Erro ao verificar favorito $cursoId na API: $e');
        }
      }

      print('✅ Sincronização de favoritos concluída');
    } catch (e) {
      print('❌ Erro na sincronização de favoritos: $e');
    }
  }
}