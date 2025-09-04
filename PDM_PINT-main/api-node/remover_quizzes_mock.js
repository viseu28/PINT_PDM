// Script para remover quizzes de teste/mock e manter apenas os originais
require('dotenv').config();
const { Sequelize } = require('sequelize');

// Conexão à base de dados
const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false,
});

async function removerQuizzesMock() {
  try {
    console.log('🔍 Conectando à base de dados...');
    await sequelize.authenticate();
    console.log('✅ Conexão bem sucedida!');

    // Primeiro, listar todos os quizzes para ver quais existem
    const todosQuizzes = await sequelize.query(`
      SELECT id_quiz, titulo, descricao, created_at 
      FROM quizzes 
      ORDER BY created_at ASC
    `, {
      type: Sequelize.QueryTypes.SELECT
    });

    console.log('📋 Quizzes atuais na base de dados:');
    todosQuizzes.forEach(quiz => {
      console.log(`  - ID: ${quiz.id_quiz}, Título: "${quiz.titulo}", Criado: ${quiz.created_at}`);
    });

    // Identificar e remover quizzes que são claramente de teste/mock
    // Baseado nos títulos que criei: "Quiz de Teste Dinâmico" e "Quiz de Programação"
    const quizzesParaRemover = await sequelize.query(`
      SELECT id_quiz, titulo 
      FROM quizzes 
      WHERE titulo IN ('Quiz de Teste Dinâmico', 'Quiz de Programação')
      OR descricao IN ('Este é um quiz dinâmico para testar o sistema completo', 'Teste os seus conhecimentos de programação')
    `, {
      type: Sequelize.QueryTypes.SELECT
    });

    if (quizzesParaRemover.length > 0) {
      console.log('\n🗑️  Quizzes de teste/mock a remover:');
      quizzesParaRemover.forEach(quiz => {
        console.log(`  - ID: ${quiz.id_quiz}, Título: "${quiz.titulo}"`);
      });

      // Primeiro remover respostas associadas
      for (const quiz of quizzesParaRemover) {
        console.log(`🧹 Removendo respostas do quiz ${quiz.id_quiz}...`);
        await sequelize.query(`
          DELETE FROM respostas_quiz WHERE id_quiz = :id_quiz
        `, {
          replacements: { id_quiz: quiz.id_quiz }
        });
      }

      // Depois remover os quizzes
      console.log('🧹 Removendo quizzes de teste...');
      await sequelize.query(`
        DELETE FROM quizzes 
        WHERE titulo IN ('Quiz de Teste Dinâmico', 'Quiz de Programação')
        OR descricao IN ('Este é um quiz dinâmico para testar o sistema completo', 'Teste os seus conhecimentos de programação')
      `);

      console.log('✅ Quizzes de teste removidos com sucesso!');
    } else {
      console.log('ℹ️  Nenhum quiz de teste encontrado para remover.');
    }

    // Mostrar quizzes restantes
    const quizzesRestantes = await sequelize.query(`
      SELECT id_quiz, titulo, descricao, created_at 
      FROM quizzes 
      ORDER BY created_at ASC
    `, {
      type: Sequelize.QueryTypes.SELECT
    });

    console.log('\n📋 Quizzes restantes (originais):');
    if (quizzesRestantes.length > 0) {
      quizzesRestantes.forEach(quiz => {
        console.log(`  - ID: ${quiz.id_quiz}, Título: "${quiz.titulo}", Descrição: "${quiz.descricao}"`);
      });
    } else {
      console.log('  Nenhum quiz restante na base de dados.');
    }

  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

removerQuizzesMock();
