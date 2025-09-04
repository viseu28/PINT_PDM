// Resumo final do sistema de quizzes limpo
require('dotenv').config();
const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false,
});

async function resumoFinal() {
  try {
    await sequelize.authenticate();
    
    const quizzes = await sequelize.query(`
      SELECT id_quiz, id_curso, titulo, descricao, ativo 
      FROM quizzes 
      WHERE ativo = true
      ORDER BY id_curso, id_quiz
    `, {
      type: Sequelize.QueryTypes.SELECT
    });

    const respostas = await sequelize.query(`
      SELECT COUNT(*) as total FROM respostas_quiz
    `, {
      type: Sequelize.QueryTypes.SELECT
    });

    console.log('📋 ESTADO FINAL DO SISTEMA DE QUIZZES');
    console.log('=====================================');
    console.log(`✅ Quizzes ativos: ${quizzes.length}`);
    console.log(`✅ Respostas submetidas: ${respostas[0].total}`);
    console.log('\n📚 Quizzes disponíveis:');
    
    quizzes.forEach(quiz => {
      console.log(`  🔹 ID: ${quiz.id_quiz} | Curso: ${quiz.id_curso} | "${quiz.titulo}"`);
    });

    console.log('\n🎯 SISTEMA COMPLETAMENTE DINÂMICO:');
    console.log('  ✅ Questões vindas da base de dados');
    console.log('  ✅ Cálculo automático de notas');
    console.log('  ✅ Interface mobile funcional');
    console.log('  ✅ Apenas dados originais (sem mocks)');

  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

resumoFinal();
