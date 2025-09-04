// Verificar as notas atuais na base de dados
require('dotenv').config();
const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false,
});

async function verificarNotasAtuais() {
  try {
    await sequelize.authenticate();
    
    const dados = await sequelize.query(`
      SELECT 
        rq.id_quiz,
        rq.nota,
        q.titulo,
        q.questoes
      FROM respostas_quiz rq
      JOIN quizzes q ON rq.id_quiz = q.id_quiz
      WHERE rq.id_quiz IN (10, 12, 13)
      GROUP BY rq.id_quiz, rq.nota, q.titulo, q.questoes
    `, {
      type: Sequelize.QueryTypes.SELECT
    });

    console.log('📊 NOTAS ATUAIS NA BASE DE DADOS');
    console.log('=================================');
    
    dados.forEach(item => {
      const totalQuestoes = Array.isArray(item.questoes) ? item.questoes.length : 0;
      const notaAtual = item.nota;
      const notaEscala20 = totalQuestoes > 0 ? Math.round((notaAtual / totalQuestoes) * 20) : 0;
      
      console.log(`\n📋 Quiz: "${item.titulo}"`);
      console.log(`   Nota na BD: ${notaAtual}`);
      console.log(`   Total questões: ${totalQuestoes}`);
      console.log(`   Cálculo: (${notaAtual} / ${totalQuestoes}) * 20 = ${notaEscala20}`);
      console.log(`   Nota esperada na escala 0-20: ${notaEscala20}/20`);
    });

  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

verificarNotasAtuais();
