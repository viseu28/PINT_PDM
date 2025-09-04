// Script para verificar as datas de submissão dos quizzes
require('dotenv').config();
const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false,
});

async function verificarDatasSubmissao() {
  try {
    await sequelize.authenticate();
    
    const respostasComDatas = await sequelize.query(`
      SELECT 
        rq.id_quiz,
        rq.id_utilizador,
        rq.nota,
        rq.tentativa,
        rq.data_submissao,
        q.titulo as quiz_titulo
      FROM respostas_quiz rq
      JOIN quizzes q ON rq.id_quiz = q.id_quiz
      ORDER BY rq.data_submissao DESC
      LIMIT 10
    `, {
      type: Sequelize.QueryTypes.SELECT
    });

    console.log('📅 DATAS DE SUBMISSÃO DOS QUIZZES');
    console.log('==================================');
    
    if (respostasComDatas.length === 0) {
      console.log('❌ Nenhuma resposta encontrada');
      return;
    }

    respostasComDatas.forEach((resposta, index) => {
      console.log(`\n${index + 1}. Quiz: "${resposta.quiz_titulo}"`);
      console.log(`   ID do Quiz: ${resposta.id_quiz}`);
      console.log(`   Utilizador: ${resposta.id_utilizador}`);
      console.log(`   Nota: ${resposta.nota}/20`);
      console.log(`   Tentativa: ${resposta.tentativa}`);
      console.log(`   Data de Submissão: ${resposta.data_submissao}`);
    });

  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

verificarDatasSubmissao();
