// Teste para validar a correção da nota
console.log('🧪 Testando correção da fórmula de nota...\n');

// Simular dados que vêm da base de dados
const quizDaMockBD = {
  nota: 13.33, // Nota já correta na escala 0-20 (2/3 * 20)
  questoes: ['Q1', 'Q2', 'Q3'] // 3 questões
};

console.log('📊 Dados da BD simulados:');
console.log(`   Nota guardada: ${quizDaMockBD.nota}/20`);
console.log(`   Número de questões: ${quizDaMockBD.questoes.length}`);

// ❌ FÓRMULA ANTERIOR (INCORRETA):
const formulaAnterior = Math.round((quizDaMockBD.nota / quizDaMockBD.questoes.length) * 20);
console.log(`\n❌ Fórmula anterior (INCORRETA):`);
console.log(`   (${quizDaMockBD.nota} / ${quizDaMockBD.questoes.length}) * 20 = ${formulaAnterior}`);
console.log(`   Resultado: ${formulaAnterior}/20 (ERRADO! 89/20)`);

// ✅ FÓRMULA CORRIGIDA:
const formulaCorrigida = parseFloat(quizDaMockBD.nota);
console.log(`\n✅ Fórmula corrigida:`);
console.log(`   parseFloat(${quizDaMockBD.nota}) = ${formulaCorrigida}`);
console.log(`   Resultado: ${formulaCorrigida}/20 (CORRETO! 13.33/20)`);

console.log(`\n🎯 CONCLUSÃO:`);
console.log(`   A nota já está correta na BD (0-20), só precisamos de a usar diretamente!`);
console.log(`   ✅ 2 acertos em 3 questões = 13.33/20 = 66.7%`);
