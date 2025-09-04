const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false
});

async function testarToken() {
  try {
    await sequelize.authenticate();
    console.log('✅ Conectado à base de dados');
    
    // Atualizar token FCM do utilizador 8
    await sequelize.query(`
      UPDATE utilizador 
      SET fcm_token = 'TESTE_TOKEN_123' 
      WHERE idutilizador = 8
    `, { type: sequelize.QueryTypes.UPDATE });
    
    console.log('✅ Token atualizado para utilizador 8');
    
    // Verificar se foi atualizado
    const [resultado] = await sequelize.query(`
      SELECT nome, fcm_token 
      FROM utilizador 
      WHERE idutilizador = 8
    `);
    
    console.log('📱 Estado atual do token:');
    console.table(resultado);
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

testarToken();
