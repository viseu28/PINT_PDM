// Script para verificar a estrutura das questões
require('dotenv').config();
const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false,
});

async function verificarQuestoes() {
  try {
    await sequelize.authenticate();
    
    const quiz = await sequelize.query(`
      SELECT id_quiz, titulo, questoes 
      FROM quizzes 
      WHERE id_quiz = 12
      LIMIT 1
    `, {
      type: Sequelize.QueryTypes.SELECT
    });

    if (quiz.length > 0) {
      console.log(`📋 Quiz: "${quiz[0].titulo}"`);
      console.log('🔍 Estrutura das questões:');
      
      const questoes = quiz[0].questoes;
      if (Array.isArray(questoes)) {
        questoes.forEach((questao, index) => {
          console.log(`\n   Questão ${index + 1}:`);
          console.log(`   Pergunta: ${questao.pergunta}`);
          console.log(`   Pontos: ${questao.pontos || 'N/A'}`);
          console.log(`   Opções: ${questao.opcoes?.join(', ')}`);
          console.log(`   Resposta correta: ${questao.resposta_correta}`);
        });

        const totalPontos = questoes.reduce((sum, q) => sum + (q.pontos || 0), 0);
        console.log(`\n📊 Total de pontos possíveis: ${totalPontos}`);
      }
    }

    // Verificar também as respostas submetidas
    const respostas = await sequelize.query(`
      SELECT rq.nota, rq.respostas, q.titulo
      FROM respostas_quiz rq
      JOIN quizzes q ON rq.id_quiz = q.id_quiz
      WHERE rq.id_quiz = 12
      LIMIT 1
    `, {
      type: Sequelize.QueryTypes.SELECT
    });

    if (respostas.length > 0) {
      console.log(`\n🎯 Resposta submetida:`);
      console.log(`   Nota obtida: ${respostas[0].nota}`);
      console.log(`   Respostas: ${JSON.stringify(respostas[0].respostas)}`);
    }

  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

verificarQuestoes();
