// Script para verificar as questões do curso Python - Estrutura de Dados
require('dotenv').config();
const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false,
});

async function verificarQuizPython() {
  try {
    await sequelize.authenticate();
    
    // Buscar quizzes do curso Python - Estrutura de Dados
    const quizzes = await sequelize.query(`
      SELECT 
        q.id_quiz,
        q.titulo,
        q.questoes,
        c.titulo as curso_titulo
      FROM quizzes q
      JOIN cursos c ON q.id_curso = c.id
      WHERE c.titulo LIKE '%Python%'
      ORDER BY q.id_quiz
    `, {
      type: Sequelize.QueryTypes.SELECT
    });

    console.log('🔍 QUIZZES DO CURSO PYTHON');
    console.log('==========================');
    
    if (quizzes.length === 0) {
      console.log('❌ Nenhum quiz encontrado para curso Python');
      return;
    }

    quizzes.forEach(quiz => {
      console.log(`\n📋 Quiz ID: ${quiz.id_quiz} - "${quiz.titulo}"`);
      console.log(`📚 Curso: ${quiz.curso_titulo}`);
      
      if (Array.isArray(quiz.questoes)) {
        console.log(`📝 Total de questões: ${quiz.questoes.length}`);
        
        quiz.questoes.forEach((questao, index) => {
          console.log(`\n   Questão ${index + 1}:`);
          console.log(`   📖 Pergunta: ${questao.pergunta}`);
          console.log(`   📋 Opções: ${questao.opcoes?.join(', ')}`);
          console.log(`   ✅ Resposta correta: ${questao.resposta_correta} (tipo: ${typeof questao.resposta_correta})`);
          
          if (questao.opcoes && questao.resposta_correta !== undefined) {
            const respostaTexto = questao.opcoes[questao.resposta_correta];
            console.log(`   💬 Texto da resposta: "${respostaTexto}"`);
          }
        });
      } else {
        console.log('❌ Questões não são array ou estão malformadas');
      }
    });

    // Verificar também se há respostas submetidas
    const respostas = await sequelize.query(`
      SELECT 
        rq.*,
        q.titulo as quiz_titulo
      FROM respostas_quiz rq
      JOIN quizzes q ON rq.id_quiz = q.id_quiz
      JOIN cursos c ON q.id_curso = c.id
      WHERE c.titulo LIKE '%Python%'
      ORDER BY rq.data_submissao DESC
      LIMIT 5
    `, {
      type: Sequelize.QueryTypes.SELECT
    });

    if (respostas.length > 0) {
      console.log('\n📊 RESPOSTAS SUBMETIDAS RECENTES:');
      console.log('==================================');
      
      respostas.forEach(resposta => {
        console.log(`\n🎯 Resposta ID: ${resposta.id_resposta}`);
        console.log(`   Quiz: "${resposta.quiz_titulo}"`);
        console.log(`   Utilizador: ${resposta.id_utilizador}`);
        console.log(`   Respostas do utilizador: ${JSON.stringify(resposta.respostas)}`);
        console.log(`   Nota calculada: ${resposta.nota}`);
        console.log(`   Data: ${resposta.data_submissao}`);
        console.log(`   Tentativa: ${resposta.tentativa}`);
      });
    }

  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

verificarQuizPython();
