const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false
});

async function verificarColunaFCM() {
  try {
    await sequelize.authenticate();
    console.log('✅ Conectado à base de dados');
    
    // Verificar estrutura da coluna fcm_token
    console.log('\n📋 Estrutura da coluna fcm_token:');
    const [colunas] = await sequelize.query(`
      SELECT 
        column_name,
        data_type,
        character_maximum_length,
        is_nullable,
        column_default
      FROM information_schema.columns 
      WHERE table_name = 'utilizador' 
      AND column_name = 'fcm_token'
    `);
    
    if (colunas.length > 0) {
      console.table(colunas);
    } else {
      console.log('❌ Coluna fcm_token não encontrada!');
    }
    
    // Verificar todas as colunas da tabela utilizador para contexto
    console.log('\n📊 Todas as colunas da tabela utilizador:');
    const [todasColunas] = await sequelize.query(`
      SELECT 
        column_name,
        data_type,
        character_maximum_length,
        is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'utilizador'
      ORDER BY ordinal_position
    `);
    
    console.table(todasColunas);
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

verificarColunaFCM();
