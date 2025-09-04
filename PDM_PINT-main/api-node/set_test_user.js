const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', { 
  host: '172.201.108.53', 
  dialect: 'postgres', 
  port: 5432,
  logging: false 
});

async function setUserForTesting() {
  try {
    console.log('🔧 Configurando utilizador para teste de primeiro login...\n');
    
    // Definir utilizador ID 8 para precisar alterar password
    const result = await sequelize.query(`
      UPDATE utilizador 
      SET temquealterarpassword = true 
      WHERE idutilizador = 8
    `);
    
    console.log('✅ Utilizador ID 8 configurado para precisar alterar password');
    
    // Verificar a alteração
    const user = await sequelize.query(`
      SELECT idutilizador, nome, email, temquealterarpassword 
      FROM utilizador 
      WHERE idutilizador = 8
    `);
    
    console.log('\n📊 Estado atual do utilizador:');
    console.log(`ID: ${user[0][0].idutilizador}`);
    console.log(`Nome: ${user[0][0].nome}`);
    console.log(`Email: ${user[0][0].email}`);
    console.log(`Precisa alterar password: ${user[0][0].temquealterarpassword ? '✅ SIM' : '❌ NÃO'}`);
    
    console.log('\n🎯 Agora pode testar o login para ver a notificação!');
    
  } catch (error) {
    console.error('❌ Erro:', error);
  } finally {
    process.exit();
  }
}

setUserForTesting();
