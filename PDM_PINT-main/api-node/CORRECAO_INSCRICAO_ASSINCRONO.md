# Correção: Erro de Inscrição em Cursos Assíncronos

## Problema Identificado

Ao tentar inscrever-se em cursos assíncronos, o sistema retornava erro:
```
"Não há vagas disponíveis para este curso"
```

## Causa Raiz

O endpoint `/inscricoes` estava a verificar vagas disponíveis para **todos** os tipos de curso, incluindo cursos assíncronos. No entanto:

1. Cursos **assíncronos** não devem ter limitação de vagas
2. Cursos **síncronos** devem ter verificação de vagas

## Problema no Código

### Antes da Correção:
```javascript
// ❌ PROBLEMA: Verificava vagas para todos os cursos
const vagasDisponiveis = curso.vagas_inscricao - totalInscritos;

if (vagasDisponiveis <= 0) {
  return res.status(400).json({
    success: false,
    message: 'Não há vagas disponíveis para este curso'
  });
}
```

### Query Original:
```sql
-- ❌ Não incluía o campo 'sincrono'
SELECT id, titulo, estado, vagas_inscricao, tema, data_inicio, data_fim, tipo, formador_responsavel
FROM cursos 
WHERE id = :idcurso AND estado = 'Em breve'
```

## Solução Implementada

### 1. Atualização da Query
```sql
-- ✅ Inclui o campo 'sincrono'
SELECT id, titulo, estado, vagas_inscricao, tema, data_inicio, data_fim, tipo, formador_responsavel, sincrono
FROM cursos 
WHERE id = :idcurso AND estado = 'Em breve'
```

### 2. Lógica Condicional de Verificação
```javascript
// ✅ CORREÇÃO: Verificação condicional baseada no tipo de curso
if (curso.sincrono === true) {
  console.log('📋 Verificando vagas para curso síncrono:', curso.titulo);
  
  // Verificar vagas apenas para cursos síncronos
  const totalInscritos = await contarInscritos(idcurso);
  const vagasDisponiveis = curso.vagas_inscricao - totalInscritos;

  if (vagasDisponiveis <= 0) {
    return res.status(400).json({
      success: false,
      message: 'Não há vagas disponíveis para este curso'
    });
  }
  
  console.log(`✅ Curso síncrono com ${vagasDisponiveis} vagas disponíveis`);
} else {
  console.log('📋 Curso assíncrono - sem verificação de vagas:', curso.titulo);
}
```

## Comportamento Corrigido

### Cursos Síncronos:
- ✅ Verificação de vagas aplicada
- ✅ Erro retornado se não houver vagas
- ✅ Inscrição permitida se houver vagas

### Cursos Assíncronos:
- ✅ **Sem verificação de vagas**
- ✅ **Inscrição sempre permitida**
- ✅ Logs informativos sobre o tipo de curso

## Logs de Debug Adicionados

```
📋 Verificando vagas para curso síncrono: [Nome do Curso]
✅ Curso síncrono com X vagas disponíveis

-- OU --

📋 Curso assíncrono - sem verificação de vagas: [Nome do Curso]
```

## Teste da Correção

Para testar:
1. Tentar inscrever-se num curso **assíncrono** → Deve funcionar sem verificação de vagas
2. Tentar inscrever-se num curso **síncrono** → Deve verificar vagas disponíveis
3. Verificar logs do servidor para confirmar o comportamento

## Data da Correção
29 de Agosto de 2025
