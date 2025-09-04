const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false
});

async function verificarTabelas() {
  try {
    await sequelize.authenticate();
    
    console.log('🔍 Procurando tabelas relacionadas com inscrições:');
    const [tabelas] = await sequelize.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      AND (table_name LIKE '%inscr%' OR table_name LIKE '%enroll%' OR table_name LIKE '%subscription%')
      ORDER BY table_name
    `);
    
    console.table(tabelas);
    
    if (tabelas.length === 0) {
      console.log('\n📋 Todas as tabelas disponíveis:');
      const [todasTabelas] = await sequelize.query(`
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public'
        ORDER BY table_name
      `);
      console.table(todasTabelas.slice(0, 20)); // Primeiras 20 tabelas
    }
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

verificarTabelas();
