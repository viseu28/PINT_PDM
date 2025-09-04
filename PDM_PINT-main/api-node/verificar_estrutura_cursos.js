const { Sequelize } = require('sequelize');

// Conexão à base de dados
const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false
});

async function verificarEstruturaCursos() {
  try {
    await sequelize.authenticate();
    console.log('✅ Conectado à base de dados');
    
    // Verificar estrutura da tabela cursos
    const [columns] = await sequelize.query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'cursos' 
      ORDER BY ordinal_position
    `);
    
    console.log('\n📋 Estrutura da tabela cursos:');
    console.log('===============================');
    columns.forEach(col => {
      console.log(`${col.column_name} (${col.data_type}) - ${col.is_nullable === 'YES' ? 'NULL' : 'NOT NULL'}`);
    });
    
    // Buscar alguns cursos para ver os dados
    const [cursos] = await sequelize.query('SELECT * FROM cursos LIMIT 3');
    
    console.log('\n📚 Exemplos de cursos:');
    console.log('======================');
    cursos.forEach((curso, index) => {
      console.log(`\nCurso ${index + 1}:`);
      Object.keys(curso).forEach(key => {
        console.log(`  ${key}: ${curso[key]}`);
      });
    });
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

verificarEstruturaCursos();
