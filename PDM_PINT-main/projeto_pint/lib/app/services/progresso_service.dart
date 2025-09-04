import 'package:shared_preferences/shared_preferences.dart';

class ProgressoService {
  // Obter progresso detalhado de um curso
  Future<Map<String, dynamic>> obterProgressoDetalhado(int cursoId) async {
    try {
      // Simulação de dados para exemplo
      // Em uma implementação real, isso viria de uma API ou banco de dados local
      return {
        'progressoGeral': 65.5,
        'horasEstudadas': 12,
        'horasTotal': 20,
        'modulos': [
          {
            'titulo': 'Introdução ao Flutter',
            'progresso': 100.0,
            'concluido': true,
            'aulas': [
              {
                'titulo': 'O que é Flutter?',
                'concluida': true,
                'duracao': '15 min'
              },
              {
                'titulo': 'Instalação do Flutter',
                'concluida': true,
                'duracao': '20 min'
              },
            ],
          },
          {
            'titulo': 'Widgets Básicos',
            'progresso': 60.0,
            'concluido': false,
            'aulas': [
              {
                'titulo': 'Scaffold e AppBar',
                'concluida': true,
                'duracao': '25 min'
              },
              {
                'titulo': 'Container e Text',
                'concluida': true,
                'duracao': '30 min'
              },
              {
                'titulo': 'Botões e Interações',
                'concluida': false,
                'duracao': '35 min'
              },
            ],
          },
          {
            'titulo': 'Layouts Avançados',
            'progresso': 0.0,
            'concluido': false,
            'aulas': [
              {
                'titulo': 'Row e Column',
                'concluida': false,
                'duracao': '40 min'
              },
              {
                'titulo': 'Stack e Positioned',
                'concluida': false,
                'duracao': '45 min'
              },
            ],
          },
        ],
        'estatisticas': {
          'streak': 7,
          'mediaDiaria': 45,
          'ultimaAtividade': '2 horas atrás',
        },
        'proximasAtividades': [
          {
            'titulo': 'Botões e Interações',
            'tipo': 'aula',
            'prazo': '',
          },
          {
            'titulo': 'Projeto: App de Lista de Tarefas',
            'tipo': 'projeto',
            'prazo': '25/08/2025',
          },
        ],
      };
    } catch (e) {
      throw Exception('Erro ao carregar progresso: $e');
    }
  }

  // Atualizar progresso de uma aula
  Future<void> atualizarProgressoAula(int cursoId, int aulaId, bool concluida) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'progresso_curso_${cursoId}_aula_$aulaId';
      await prefs.setBool(key, concluida);
    } catch (e) {
      throw Exception('Erro ao atualizar progresso: $e');
    }
  }

  // Obter progresso geral do usuário
  Future<Map<String, dynamic>> obterProgressoGeral() async {
    try {
      return {
        'cursosInscritos': 5,
        'cursosConcluidos': 2,
        'horasTotaisEstudo': 150,
        'streakAtual': 7,
        'ultimoCursoAcessado': {
          'id': 1,
          'titulo': 'Flutter para Iniciantes',
          'progresso': 65.5,
        },
      };
    } catch (e) {
      throw Exception('Erro ao carregar progresso geral: $e');
    }
  }

  // Salvar tempo de estudo
  Future<void> salvarTempoEstudo(int cursoId, int minutosEstudados) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'tempo_estudo_curso_$cursoId';
      final tempoAtual = prefs.getInt(key) ?? 0;
      await prefs.setInt(key, tempoAtual + minutosEstudados);
      
      // Atualizar estatísticas gerais
      final tempoTotal = prefs.getInt('tempo_total_estudo') ?? 0;
      await prefs.setInt('tempo_total_estudo', tempoTotal + minutosEstudados);
    } catch (e) {
      throw Exception('Erro ao salvar tempo de estudo: $e');
    }
  }

  // Calcular streak de estudos
  Future<int> calcularStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ultimoEstudo = prefs.getString('ultimo_estudo');
      
      if (ultimoEstudo == null) return 0;
      
      final ultimaData = DateTime.parse(ultimoEstudo);
      final hoje = DateTime.now();
      final diferenca = hoje.difference(ultimaData).inDays;
      
      if (diferenca <= 1) {
        return prefs.getInt('streak_atual') ?? 0;
      } else {
        // Reset streak se passou mais de 1 dia
        await prefs.setInt('streak_atual', 0);
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  // Atualizar streak
  Future<void> atualizarStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hoje = DateTime.now().toIso8601String().split('T')[0];
      final ultimoEstudo = prefs.getString('ultimo_estudo_data');
      
      if (ultimoEstudo != hoje) {
        final streakAtual = prefs.getInt('streak_atual') ?? 0;
        await prefs.setInt('streak_atual', streakAtual + 1);
        await prefs.setString('ultimo_estudo_data', hoje);
        await prefs.setString('ultimo_estudo', DateTime.now().toIso8601String());
      }
    } catch (e) {
      print('Erro ao atualizar streak: $e');
    }
  }
}