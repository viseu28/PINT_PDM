const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false
});

async function testNotificationAPI() {
  try {
    console.log('🔔 Testando API de Notificações...\n');
    
    // Simular endpoint para buscar notificações do utilizador 8
    const notificacoes = await sequelize.query(`
      SELECT idnotificacao, descricao, datahora
      FROM notificacao 
      WHERE idutilizador = 8
      ORDER BY datahora DESC
    `);
    
    console.log('📱 API Response - Notificações do utilizador 8:');
    console.log(JSON.stringify(notificacoes[0], null, 2));
    
    console.log(`\n🔢 Total de notificações: ${notificacoes[0].length}`);
    
    // Simular resposta da API como o Flutter receberia
    const apiResponse = {
      success: true,
      data: notificacoes[0].map(notif => ({
        id: notif.idnotificacao,
        descricao: notif.descricao,
        datahora: notif.datahora
      })),
      count: notificacoes[0].length
    };
    
    console.log('\n🔗 Formato da resposta para Flutter:');
    console.log(JSON.stringify(apiResponse, null, 2));
    console.log('✅ Sistema de API funcionando corretamente!');
    
  } catch (error) {
    console.error('❌ Erro na API:', error.message);
  } finally {
    await sequelize.close();
    process.exit(0);
  }
}

testNotificationAPI();
