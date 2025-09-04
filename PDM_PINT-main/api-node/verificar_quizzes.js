// Script para verificar se há quizzes na base de dados
require('dotenv').config();
const { Sequelize } = require('sequelize');

// Conexão à base de dados
const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: console.log, // Ativar logs SQL
});

async function verificarQuizzes() {
  try {
    console.log('🔍 Conectando à base de dados...');
    await sequelize.authenticate();
    console.log('✅ Conexão bem sucedida!');

    // Verificar quantos quizzes existem
    const totalQuizzes = await sequelize.query(`
      SELECT COUNT(*) as total FROM quizzes
    `, {
      type: Sequelize.QueryTypes.SELECT
    });

    console.log(`📊 Total de quizzes na base: ${totalQuizzes[0].total}`);

    // Verificar quizzes ativos
    const quizzesAtivos = await sequelize.query(`
      SELECT COUNT(*) as total FROM quizzes WHERE ativo = true
    `, {
      type: Sequelize.QueryTypes.SELECT
    });

    console.log(`✅ Quizzes ativos: ${quizzesAtivos[0].total}`);

    // Listar alguns quizzes para debug
    const quizzesSample = await sequelize.query(`
      SELECT id_quiz, id_curso, titulo, ativo, created_at 
      FROM quizzes 
      ORDER BY created_at DESC 
      LIMIT 5
    `, {
      type: Sequelize.QueryTypes.SELECT
    });

    console.log('📋 Últimos 5 quizzes:');
    quizzesSample.forEach(quiz => {
      console.log(`  - ID: ${quiz.id_quiz}, Curso: ${quiz.id_curso}, Título: ${quiz.titulo}, Ativo: ${quiz.ativo}`);
    });

    // Verificar se há cursos assíncronos
    const cursosAssincronos = await sequelize.query(`
      SELECT id, titulo, sincrono FROM cursos WHERE sincrono = false LIMIT 5
    `, {
      type: Sequelize.QueryTypes.SELECT
    });

    console.log('🔄 Cursos assíncronos:');
    cursosAssincronos.forEach(curso => {
      console.log(`  - ID: ${curso.id}, Título: ${curso.titulo}, Síncrono: ${curso.sincrono}`);
    });

  } catch (error) {
    console.error('❌ Erro:', error);
  } finally {
    await sequelize.close();
  }
}

verificarQuizzes();
