import 'package:flutter/material.dart';
import 'package:projeto_pint/app/models/curso_model.dart';
import 'package:projeto_pint/app/services/progresso_service.dart';

class ProgressoDetalhadoPage extends StatefulWidget {
  final Curso curso;
  
  const ProgressoDetalhadoPage({super.key, required this.curso});

  @override
  State<ProgressoDetalhadoPage> createState() => _ProgressoDetalhadoPageState();
}

class _ProgressoDetalhadoPageState extends State<ProgressoDetalhadoPage> {
  final ProgressoService _progressoService = ProgressoService();
  Map<String, dynamic> progressoDetalhado = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarProgressoDetalhado();
  }

  Future<void> _carregarProgressoDetalhado() async {
    try {
      final progresso = await _progressoService.obterProgressoDetalhado(widget.curso.id ?? 0);
      setState(() {
        progressoDetalhado = progresso;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar progresso: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Progresso - ${widget.curso.titulo}'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card de Progresso Geral
                  _buildCardProgressoGeral(),
                  const SizedBox(height: 20),
                  
                  // Lista de Módulos
                  _buildListaModulos(),
                  const SizedBox(height: 20),
                  
                  // Estatísticas de Estudo
                  _buildEstatisticasEstudo(),
                  const SizedBox(height: 20),
                  
                  // Próximas Atividades
                  _buildProximasAtividades(),
                ],
              ),
            ),
    );
  }

  Widget _buildCardProgressoGeral() {
    final progressoGeral = progressoDetalhado['progressoGeral'] ?? 0.0;
    final horasEstudadas = progressoDetalhado['horasEstudadas'] ?? 0;
    final horasTotal = progressoDetalhado['horasTotal'] ?? 1;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Progresso Geral',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Indicador Circular de Progresso
            SizedBox(
              height: 120,
              width: 120,
              child: Stack(
                children: [
                  CircularProgressIndicator(
                    value: progressoGeral / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressoGeral >= 80 ? Colors.green : 
                      progressoGeral >= 50 ? Colors.orange : Colors.red,
                    ),
                  ),
                  Center(
                    child: Text(
                      '${progressoGeral.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Horas Estudadas', '$horasEstudadas h'),
                _buildStatItem('Horas Restantes', '${horasTotal - horasEstudadas} h'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildListaModulos() {
    final modulos = progressoDetalhado['modulos'] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Módulos do Curso',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        ...modulos.map<Widget>((modulo) => _buildModuloCard(modulo)).toList(),
      ],
    );
  }

  Widget _buildModuloCard(Map<String, dynamic> modulo) {
    final titulo = modulo['titulo'] ?? 'Módulo';
    final progresso = modulo['progresso'] ?? 0.0;
    final concluido = modulo['concluido'] ?? false;
    final aulas = modulo['aulas'] ?? [];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          concluido ? Icons.check_circle : Icons.radio_button_unchecked,
          color: concluido ? Colors.green : Colors.grey,
        ),
        title: Text(titulo),
        subtitle: LinearProgressIndicator(
          value: progresso / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            concluido ? Colors.green : Colors.blue,
          ),
        ),
        trailing: Text('${progresso.toStringAsFixed(0)}%'),
        children: [
          ...aulas.map<Widget>((aula) => _buildAulaItem(aula)).toList(),
        ],
      ),
    );
  }

  Widget _buildAulaItem(Map<String, dynamic> aula) {
    final titulo = aula['titulo'] ?? 'Aula';
    final concluida = aula['concluida'] ?? false;
    final duracao = aula['duracao'] ?? '0 min';
    
    return ListTile(
      leading: Icon(
        concluida ? Icons.play_circle_filled : Icons.play_circle_outline,
        color: concluida ? Colors.green : Colors.grey,
      ),
      title: Text(titulo),
      subtitle: Text(duracao),
      trailing: concluida ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        // Navegar para a aula
        // Navigator.push(...);
      },
    );
  }

  Widget _buildEstatisticasEstudo() {
    final estatisticas = progressoDetalhado['estatisticas'] ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estatísticas de Estudo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Streak', '${estatisticas['streak'] ?? 0} dias'),
                _buildStatItem('Média/Dia', '${estatisticas['mediaDiaria'] ?? 0} min'),
                _buildStatItem('Última Atividade', estatisticas['ultimaAtividade'] ?? 'N/A'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProximasAtividades() {
    final atividades = progressoDetalhado['proximasAtividades'] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Próximas Atividades',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        if (atividades.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Nenhuma atividade pendente. Parabéns!'),
            ),
          )
        else
          ...atividades.map<Widget>((atividade) => _buildAtividadeCard(atividade)).toList(),
      ],
    );
  }

  Widget _buildAtividadeCard(Map<String, dynamic> atividade) {
    final titulo = atividade['titulo'] ?? 'Atividade';
    final tipo = atividade['tipo'] ?? 'aula';
    final prazo = atividade['prazo'] ?? '';
    
    return Card(
      child: ListTile(
        leading: Icon(
          tipo == 'aula' ? Icons.play_lesson : Icons.assignment,
          color: Colors.blue,
        ),
        title: Text(titulo),
        subtitle: prazo.isNotEmpty ? Text('Prazo: $prazo') : null,
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Navegar para a atividade
        },
      ),
    );
  }
}
