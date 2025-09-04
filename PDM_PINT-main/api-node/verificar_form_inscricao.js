const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false
});

async function encontrarInscricoes() {
  try {
    await sequelize.authenticate();
    
    // Verificar estrutura da tabela form_inscricao
    console.log('📋 Estrutura da tabela form_inscricao:');
    const [estrutura] = await sequelize.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'form_inscricao' 
      ORDER BY ordinal_position
    `);
    console.table(estrutura);
    
    // Ver alguns dados da tabela
    console.log('\n📊 Dados da tabela form_inscricao:');
    const [dados] = await sequelize.query(`SELECT * FROM form_inscricao LIMIT 5`);
    console.table(dados);
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

encontrarInscricoes();
