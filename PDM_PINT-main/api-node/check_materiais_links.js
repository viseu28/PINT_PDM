const { Sequelize } = require('sequelize');

// Conexão à base de dados
const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false
});

(async () => {
  try {
    console.log('🔍 Verificando estrutura da tabela materiais_links...');
    
    // Verificar estrutura da tabela
    const [structure] = await sequelize.query(`
      SELECT column_name, data_type, is_nullable, column_default 
      FROM information_schema.columns 
      WHERE table_name = 'materiais_links' 
      ORDER BY ordinal_position
    `);
    
    console.log('📋 Estrutura da tabela materiais_links:');
    console.log(structure);
    
    // Verificar se há dados
    const [results] = await sequelize.query('SELECT * FROM materiais_links LIMIT 3');
    
    if (results.length > 0) {
      console.log('\n📄 Exemplo de dados:');
      console.log(results);
    } else {
      console.log('\n📦 Tabela está vazia');
    }
    
    await sequelize.close();
    process.exit(0);
  } catch (error) {
    console.error('❌ Erro:', error);
    process.exit(1);
  }
})();
