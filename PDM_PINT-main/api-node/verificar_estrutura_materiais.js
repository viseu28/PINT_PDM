const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false
});

async function verificarEstruturaMateriais() {
  try {
    await sequelize.authenticate();
    console.log('✅ Conectado à base de dados');
    
    // Verificar estrutura da tabela materiais_apoio
    console.log('\n📋 Estrutura da tabela materiais_apoio:');
    const [colunas] = await sequelize.query(`
      SELECT 
        column_name,
        data_type,
        character_maximum_length,
        is_nullable,
        column_default
      FROM information_schema.columns 
      WHERE table_name = 'materiais_apoio'
      ORDER BY ordinal_position
    `);
    
    if (colunas.length > 0) {
      console.table(colunas);
    } else {
      console.log('❌ Tabela materiais_apoio não encontrada!');
    }
    
    // Ver dados existentes
    console.log('\n📊 Dados existentes na tabela:');
    const [dados] = await sequelize.query(`SELECT * FROM materiais_apoio LIMIT 3`);
    console.table(dados);
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

verificarEstruturaMateriais();
