const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false
});

async function verificarCurso36() {
  try {
    await sequelize.authenticate();
    console.log('✅ Conectado à base de dados');
    
    // Verificar se curso 36 existe
    console.log('\n🔍 Procurando curso ID 36:');
    const [curso] = await sequelize.query(`
      SELECT * FROM cursos WHERE id = 36
    `);
    
    if (curso.length > 0) {
      console.log('📚 Curso encontrado:');
      console.table(curso);
    } else {
      console.log('❌ Curso ID 36 não encontrado!');
      
      // Mostrar todos os cursos disponíveis
      console.log('\n📚 Cursos disponíveis:');
      const [todosCursos] = await sequelize.query(`
        SELECT id, titulo, formador_responsavel FROM cursos ORDER BY id
      `);
      console.table(todosCursos);
    }
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

verificarCurso36();
