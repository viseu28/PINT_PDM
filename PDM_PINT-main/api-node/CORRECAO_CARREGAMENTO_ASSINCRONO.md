# Correção do Carregamento da Página de Inscrição - Cursos Assíncronos

## Problema Identificado

A página de inscrição não carregava para cursos assíncronos, ficando indefinidamente com o indicator de carregamento.

## Causa Raiz

Para cursos assíncronos, a variável `_vagasDisponiveis` permanecia como `null` porque o método `_verificarVagasDisponiveis()` só era chamado para cursos síncronos. No entanto, a condição do body verificava apenas se `_vagasDisponiveis == null`, causando um loop infinito de carregamento.

```dart
// PROBLEMA: Condição que causava carregamento infinito
body: _vagasDisponiveis == null
    ? Center(child: CircularProgressIndicator())
    : SingleChildScrollView(
```

## Solução Implementada

### 1. Inicialização da Variável para Cursos Assíncronos
```dart
@override
void initState() {
  super.initState();
  if (widget.curso.sincrono == true) {
    _verificarVagasDisponiveis();
  } else {
    // Para cursos assíncronos, definir valor especial
    _vagasDisponiveis = -1; // Indica "não aplicável"
  }
}
```

### 2. Condição Corrigida do Body
```dart
// CORREÇÃO: Só mostrar carregamento para cursos síncronos
body: (_vagasDisponiveis == null && widget.curso.sincrono == true)
    ? Center(child: CircularProgressIndicator())
    : SingleChildScrollView(
```

### 3. Atualização da Exibição de Vagas
```dart
// Só mostrar seção de vagas para cursos síncronos com dados válidos
if (widget.curso.sincrono == true && _vagasDisponiveis != null && _vagasDisponiveis! >= 0) ...[
  _buildVagasInfo(),
  SizedBox(height: 24),
],
```

## Resultado

✅ **Cursos Assíncronos**: Página carrega imediatamente, sem seção de vagas
✅ **Cursos Síncronos**: Página carrega após verificar vagas, mostra seção de vagas

## Teste

Para testar:
1. Aceder a um curso assíncrono
2. Clicar em "Inscrever-se no Curso"
3. A página deve carregar imediatamente sem mostrar informações de vagas
4. O botão "Confirmar Inscrição" deve estar disponível

## Data da Correção
29 de Agosto de 2025
