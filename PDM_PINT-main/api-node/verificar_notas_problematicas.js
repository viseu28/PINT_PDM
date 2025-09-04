// Script para verificar e corrigir notas existentes na BD
require('dotenv').config();
const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false
});

async function verificarECorrigirNotas() {
  try {
    console.log('🔍 Verificando notas existentes na BD...\n');
    
    // Buscar todas as respostas de quiz
    const respostas = await sequelize.query(`
      SELECT rq.id_resposta, rq.id_quiz, rq.id_utilizador, rq.nota, rq.respostas, rq.tentativa,
             q.titulo as quiz_titulo
      FROM respostas_quiz rq
      JOIN quizzes q ON rq.id_quiz = q.id_quiz
      ORDER BY rq.id_resposta DESC
    `, {
      type: Sequelize.QueryTypes.SELECT
    });
    
    console.log(`📊 Encontradas ${respostas.length} respostas de quiz na BD:`);
    
    for (const resp of respostas) {
      const notaAtual = parseFloat(resp.nota);
      
      // Contar questões a partir das respostas JSON
      let totalQuestoes = 3; // padrão
      try {
        if (resp.respostas) {
          const respostasArray = JSON.parse(resp.respostas);
          if (Array.isArray(respostasArray)) {
            totalQuestoes = respostasArray.length;
          }
        }
      } catch (e) {
        console.log(`   ⚠️  Erro ao parsear respostas para calcular total`);
      }
      
      console.log(`\n📝 Quiz: "${resp.quiz_titulo}" (ID: ${resp.id_quiz})`);
      console.log(`   Utilizador: ${resp.id_utilizador} | Tentativa: ${resp.tentativa}`);
      console.log(`   Total questões estimado: ${totalQuestoes}`);
      console.log(`   Nota atual: ${notaAtual}`);
      
      // Verificar se a nota está numa escala suspeita (>20 ou valores estranhos)
      if (notaAtual > 20) {
        console.log(`   ⚠️  PROBLEMA: Nota ${notaAtual} está acima de 20!`);
        
        // Tentar inferir a nota correta
        // Se a nota é muito alta, pode ser que tenha sido calculada com a fórmula errada
        let notaCorrigida = null;
        
        // Se parece que foi multiplicada por 20 indevidamente
        if (notaAtual > 20 && notaAtual <= 100) {
          // Pode ser (acertos/total) * 20 * 20 / total = (acertos * 20 * 20) / (total * total)
          // Vamos tentar reverter: acertos = sqrt(nota * total * total / 400)
          const acertosEstimados = Math.round(Math.sqrt(notaAtual * totalQuestoes * totalQuestoes / 400));
          if (acertosEstimados <= totalQuestoes) {
            notaCorrigida = (acertosEstimados / totalQuestoes) * 20;
            console.log(`   🔧 Tentativa de correção: ${acertosEstimados} acertos → ${notaCorrigida.toFixed(2)}/20`);
          }
        }
        
        if (notaCorrigida && notaCorrigida <= 20) {
          console.log(`   ✅ Sugerindo correção para: ${notaCorrigida.toFixed(2)}/20`);
        } else {
          console.log(`   ❌ Não foi possível inferir nota correta automaticamente`);
        }
        
      } else if (notaAtual >= 0 && notaAtual <= 20) {
        console.log(`   ✅ Nota parece correta (0-20)`);
      } else {
        console.log(`   ⚠️  Nota com valor estranho: ${notaAtual}`);
      }
    }
    
    console.log(`\n🎯 RESUMO:`);
    console.log(`   • Total de respostas: ${respostas.length}`);
    const notasProblematicas = respostas.filter(r => parseFloat(r.nota) > 20);
    console.log(`   • Notas problemáticas (>20): ${notasProblematicas.length}`);
    console.log(`   • Com as correções no código, novas submissões já ficarão corretas`);
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

verificarECorrigirNotas();
