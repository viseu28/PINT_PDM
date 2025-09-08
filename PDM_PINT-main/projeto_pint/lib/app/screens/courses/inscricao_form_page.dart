import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/curso_model.dart';
import '../../services/curso_service.dart';
import 'package:http/http.dart' as http;

class InscricaoFormPage extends StatefulWidget {
  final Curso curso;

  const InscricaoFormPage({super.key, required this.curso});

  @override
  State<InscricaoFormPage> createState() => _InscricaoFormPageState();
}

class _InscricaoFormPageState extends State<InscricaoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _objetivosController = TextEditingController();

  bool _isLoading = false;
  int? _vagasDisponiveis;

  @override
  void initState() {
    super.initState();
    
    // 🔍 DEBUG: Logs imediatos na inicialização
    print('🔍 DEBUG INIT - dataInicio: ${widget.curso.dataInicio}');
    print('🔍 DEBUG INIT - curso completo: ${widget.curso.toJson()}');
    print('🔍 DEBUG INIT - título: ${widget.curso.titulo}');
    
    if (widget.curso.sincrono == true) {
      _verificarVagasDisponiveis();
    } else {
      _vagasDisponiveis = -1;
    }
  }

  @override
  void dispose() {
    _objetivosController.dispose();
    super.dispose();
  }

  Future<void> _verificarVagasDisponiveis() async {
    try {
      final vagas = await CursoService.verificarVagasDisponiveis(widget.curso.id!);
      if (mounted) {
        setState(() {
          _vagasDisponiveis = vagas;
        });
      }
    } catch (e) {
      print('⚠️ Erro ao verificar vagas: $e');
      if (mounted) setState(() => _vagasDisponiveis = 10);
    }
  }

Future<void> _submeterInscricao() async {
  if (!_formKey.currentState!.validate()) return;
  
  // 🛡️ Proteção extra contra duplo clique
  if (_isLoading) {
    print('⚠️ Já está a processar inscrição, ignorando...');
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    // 🔹 Verificar permissão id 5 ANTES de inscrever
    final bool ligado = await CursoService.permissaoLigacaoEspecifica(5);
    print('🔹 Permissão id 5 ligada? $ligado');

    if (ligado == false) {
      _mostrarErro(
        'Ação bloqueada devido à permissão 5'
      );
      return; // ⚠️ Imprescindível para impedir inscrição
    }

    // 🔹 Verificar vagas apenas para cursos síncronos
    if (widget.curso.sincrono == true) {
      print('📊 Verificando vagas para o curso ${widget.curso.id}');
      final int vagas = await CursoService.verificarVagasDisponiveis(widget.curso.id!);
      print('📊 Vagas disponíveis: $vagas');

      if (vagas <= 0) {
        _mostrarErro('Não há vagas disponíveis para este curso');
        return;
      }
    }

    // 🔹 Chamar endpoint de inscrição
    print('📊 Chamando endpoint de inscrição...');
    final resultado = await CursoService.inscreverNoCurso(
      widget.curso.id!,
      objetivos: _objetivosController.text.trim(),
    );
    print('📡 Resultado da inscrição: $resultado');

    if (mounted) {
      if (resultado['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Inscrição realizada com sucesso!')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        await Future.delayed(Duration(milliseconds: 500));
        if (mounted) context.pop(true);
      } else {
        // Mostrar mensagem específica do erro
        final String mensagemErro = resultado['message'] ?? 'Erro ao realizar inscrição';
        _mostrarErro(mensagemErro);
      }
    }
  } catch (e) {
    print('❌ Erro inesperado no _submeterInscricao: $e');
    if (mounted) _mostrarErro('Erro inesperado: $e');
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}



  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(mensagem)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Inscrição no Curso'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(false),
        ),
      ),
      body: (_vagasDisponiveis == null && widget.curso.sincrono == true)
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCursoInfo(),
                  SizedBox(height: 24),
                  // Data limite de inscrição - DEBUG
                  _buildDataLimiteInfo(),
                  SizedBox(height: 24),
                  if (widget.curso.sincrono == true &&
                      _vagasDisponiveis != null &&
                      _vagasDisponiveis! >= 0) ...[
                    _buildVagasInfo(),
                    SizedBox(height: 24),
                  ],
                  _buildFormulario(),
                  SizedBox(height: 32),
                  _buildBotaoSubmeter(),
                  SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildCursoInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text(
                'Curso Selecionado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(widget.curso.titulo, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blue)),
          SizedBox(height: 8),
          Text(widget.curso.descricao,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]), maxLines: 3, overflow: TextOverflow.ellipsis),
          SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip('Dificuldade', widget.curso.dificuldade),
              SizedBox(width: 12),
              _buildInfoChip('Pontos', '${widget.curso.pontos}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Text('$label: $value', style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildVagasInfo() {
    final temVagas = _vagasDisponiveis! > 0;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: temVagas ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: temVagas ? Colors.green : Colors.red, width: 1),
      ),
      child: Row(
        children: [
          Icon(temVagas ? Icons.check_circle : Icons.warning, color: temVagas ? Colors.green : Colors.red, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vagas Disponíveis',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                SizedBox(height: 4),
                Text(
                  temVagas
                      ? _vagasDisponiveis == 10
                          ? 'Vagas disponíveis (verificação pendente)'
                          : '$_vagasDisponiveis vagas restantes'
                      : 'Curso lotado - sem vagas',
                  style: TextStyle(fontSize: 14, color: temVagas ? Colors.green[700] : Colors.red[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dados da Inscrição',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            SizedBox(height: 16),
            TextFormField(
              controller: _objetivosController,
              decoration: InputDecoration(
                labelText: 'Objetivos com o Curso *',
                hintText: 'Descreva seus objetivos ao fazer este curso',
                prefixIcon: Icon(Icons.track_changes),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Objetivos são obrigatórios';
                if (value.trim().length < 10) return 'Descreva seus objetivos com mais detalhes (mín. 10 caracteres)';
                return null;
              },
            ),
            SizedBox(height: 12),
            Text('* Campo obrigatório', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoSubmeter() {
    final cursoAssincrono = widget.curso.sincrono != true;
    final temVagas = _vagasDisponiveis != null && _vagasDisponiveis! > 0;
    final podeInscrever = cursoAssincrono || temVagas || _vagasDisponiveis == 10;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading || !podeInscrever ? null : _submeterInscricao,
        style: ElevatedButton.styleFrom(
          backgroundColor: podeInscrever ? Colors.blue : Colors.grey,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: (temVagas || _vagasDisponiveis == 10 || cursoAssincrono) ? 2 : 0,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
                  SizedBox(width: 12),
                  Text('Processando inscrição...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(podeInscrever ? Icons.send : Icons.block, size: 20),
                  SizedBox(width: 8),
                  Text(podeInscrever ? 'Confirmar Inscrição' : 'Sem Vagas Disponíveis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }

  Widget _buildDataLimiteInfo() {
    // 🔍 DEBUG: Verificar dados do curso
    print('🔍 DEBUG dataInicio: ${widget.curso.dataInicio}');
    print('🔍 DEBUG curso completo: ${widget.curso.toJson()}');
    
    if (widget.curso.dataInicio == null || widget.curso.dataInicio!.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.grey[600]),
            SizedBox(width: 12),
            Text(
              'Data de início não disponível',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    final dataLimiteTexto = _formatarDataLimite(widget.curso.dataInicio!);
    final bool isExpirado = dataLimiteTexto == 'Expirado';
    final bool isHoje = dataLimiteTexto == 'Hoje';
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isExpirado 
              ? [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)]
              : isHoje 
                  ? [Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.05)]
                  : [Colors.blue.withOpacity(0.1), Colors.blue.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpirado 
              ? Colors.red.withOpacity(0.3)
              : isHoje 
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isExpirado 
                  ? Colors.red.withOpacity(0.1)
                  : isHoje 
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isExpirado 
                  ? Icons.access_time_filled
                  : isHoje 
                      ? Icons.schedule
                      : Icons.schedule,
              color: isExpirado 
                  ? Colors.red[600]
                  : isHoje 
                      ? Colors.orange[600]
                      : Colors.blue[600],
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prazo de Inscrição',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  isExpirado 
                      ? 'Prazo expirado'
                      : isHoje 
                          ? 'Último dia para se inscrever!'
                          : 'Termina em $dataLimiteTexto',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isExpirado 
                        ? Colors.red[700]
                        : isHoje 
                            ? Colors.orange[700]
                            : Colors.blue[700],
                  ),
                ),
                if (!isExpirado && !isHoje) ...[
                  SizedBox(height: 2),
                  Text(
                    'As inscrições encerram no dia anterior ao início do curso',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatarDataLimite(String dataInicio) {
    try {
      print('🔍 DEBUG: Formatando data - Input: $dataInicio');
      final DateTime inicioDateTime = DateTime.parse(dataInicio);
      print('🔍 DEBUG: Data parseada: $inicioDateTime');
      
      // Data limite é o dia anterior ao início do curso
      final DateTime dataLimite = inicioDateTime.subtract(Duration(days: 1));
      final DateTime agora = DateTime.now();
      
      print('🔍 DEBUG: Data limite: $dataLimite');
      print('🔍 DEBUG: Data atual: $agora');
      
      // Calcular a diferença em dias
      final int diasRestantes = dataLimite.difference(agora).inDays;
      print('🔍 DEBUG: Dias restantes: $diasRestantes');
      
      if (diasRestantes > 0) {
        return '$diasRestantes dias';
      } else if (diasRestantes == 0) {
        return 'Hoje';
      } else {
        return 'Expirado';
      }
    } catch (e) {
      print('❌ Erro ao formatar data: $e');
      return 'Data inválida: $dataInicio';
    }
  }
}
