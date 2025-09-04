// FUNÇÃO HELPER PARA CALCULAR DURAÇÃO
// Adicionar ao endpoint de cursos ou criar arquivo separado

/**
 * Calcula a duração entre duas datas e retorna formatado
 * @param {Date} dataInicio - Data de início do curso
 * @param {Date} dataFim - Data de fim do curso
 * @returns {string} - Duração formatada (ex: "5 dias", "3 semanas", "2 meses")
 */
function calcularDuracao(dataInicio, dataFim) {
  if (!dataInicio || !dataFim) {
    return 'Duração não disponível';
  }

  const inicio = new Date(dataInicio);
  const fim = new Date(dataFim);
  
  // Calcular diferença em milissegundos e converter para dias
  const diferencaMs = fim - inicio;
  const diferencaDias = Math.ceil(diferencaMs / (1000 * 60 * 60 * 24));
  
  if (diferencaDias <= 0) {
    return 'Duração inválida';
  } else if (diferencaDias < 7) {
    return `${diferencaDias} ${diferencaDias === 1 ? 'dia' : 'dias'}`;
  } else if (diferencaDias <= 21) { // Até 3 semanas
    const semanas = Math.ceil(diferencaDias / 7);
    return `${semanas} ${semanas === 1 ? 'semana' : 'semanas'}`;
  } else {
    // A partir de 22 dias (~3+ semanas), mostrar em meses
    const meses = Math.round(diferencaDias / 30.5); // Média mais precisa
    return `${meses} ${meses === 1 ? 'mês' : 'meses'}`;
  }
}

/**
 * Adiciona duração calculada aos dados do curso
 * @param {Object} curso - Objeto do curso
 * @returns {Object} - Curso com duração adicionada
 */
function adicionarDuracao(curso) {
  if (!curso) return curso;
  
  const cursoComDuracao = { ...curso };
  cursoComDuracao.duracao = calcularDuracao(curso.data_inicio, curso.data_fim);
  
  return cursoComDuracao;
}

/**
 * Adiciona duração calculada a uma lista de cursos
 * @param {Array} cursos - Array de cursos
 * @returns {Array} - Array de cursos com duração adicionada
 */
function adicionarDuracaoLista(cursos) {
  if (!Array.isArray(cursos)) return cursos;
  
  return cursos.map(curso => adicionarDuracao(curso));
}

module.exports = {
  calcularDuracao,
  adicionarDuracao,
  adicionarDuracaoLista
};
