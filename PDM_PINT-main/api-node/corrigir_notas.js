// Script para corrigir as notas na base de dados
require('dotenv').config();
const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false,
});

async function corrigirNotas() {
  try {
    await sequelize.authenticate();
    
    console.log('🔧 Corrigindo notas na base de dados...');
    
    const respostasParaCorrigir = await sequelize.query(`
      SELECT 
        rq.id_resposta,
        rq.id_quiz,
        rq.id_utilizador,
        rq.respostas,
        rq.nota as nota_antiga,
        q.questoes
      FROM respostas_quiz rq
      JOIN quizzes q ON rq.id_quiz = q.id_quiz
    `, {
      type: Sequelize.QueryTypes.SELECT
    });

    for (const resposta of respostasParaCorrigir) {
      const questoes = resposta.questoes;
      const respostasUsuario = resposta.respostas;
      
      let acertos = 0;
      questoes.forEach((questao, index) => {
        if (parseInt(respostasUsuario[index]) === parseInt(questao.resposta_correta)) {
          acertos++;
        }
      });
      
      console.log(`📝 Corrigindo resposta ${resposta.id_resposta}:`);
      console.log(`   Quiz: ${resposta.id_quiz}`);
      console.log(`   Utilizador: ${resposta.id_utilizador}`);
      console.log(`   Nota antiga: ${resposta.nota_antiga}`);
      console.log(`   Nota correta: ${acertos}`);
      console.log(`   Acertos: ${acertos}/${questoes.length} (${Math.round((acertos/questoes.length)*100)}%)`);
      
      // Atualizar na base de dados
      await sequelize.query(`
        UPDATE respostas_quiz 
        SET nota = :nota_correta 
        WHERE id_resposta = :id_resposta
      `, {
        replacements: {
          nota_correta: acertos,
          id_resposta: resposta.id_resposta
        }
      });
    }
    
    console.log('\n✅ Todas as notas foram corrigidas!');

  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

corrigirNotas();
