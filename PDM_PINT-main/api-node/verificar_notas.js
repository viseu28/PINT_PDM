// Script para verificar as notas reais na base de dados
require('dotenv').config();
const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false,
});

async function verificarNotas() {
  try {
    await sequelize.authenticate();
    
    const respostasComDetalhes = await sequelize.query(`
      SELECT 
        rq.id_quiz,
        rq.id_utilizador,
        rq.nota,
        rq.tentativa,
        q.titulo as quiz_titulo,
        q.questoes
      FROM respostas_quiz rq
      JOIN quizzes q ON rq.id_quiz = q.id_quiz
      ORDER BY rq.id_quiz, rq.tentativa
    `, {
      type: Sequelize.QueryTypes.SELECT
    });

    console.log('📊 ANÁLISE DAS NOTAS NA BASE DE DADOS');
    console.log('=====================================');
    
    respostasComDetalhes.forEach(resposta => {
      let totalPerguntas = 0;
      try {
        if (typeof resposta.questoes === 'object' && resposta.questoes !== null) {
          totalPerguntas = Array.isArray(resposta.questoes) ? resposta.questoes.length : 0;
        } else {
          const questoes = JSON.parse(resposta.questoes || '[]');
          totalPerguntas = questoes.length;
        }
      } catch (e) {
        totalPerguntas = 0;
      }

      const percentualCorreto = totalPerguntas > 0 ? Math.round((resposta.nota / totalPerguntas) * 100) : 0;
      
      console.log(`\n🔹 Quiz: "${resposta.quiz_titulo}"`);
      console.log(`   Utilizador: ${resposta.id_utilizador}`);
      console.log(`   Nota raw: ${resposta.nota}`);
      console.log(`   Total perguntas: ${totalPerguntas}`);
      console.log(`   Percentual correto: ${percentualCorreto}%`);
      console.log(`   Tentativa: ${resposta.tentativa}`);
    });

  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

verificarNotas();
