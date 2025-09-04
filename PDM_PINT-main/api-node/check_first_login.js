const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', { 
  host: '172.201.108.53', 
  dialect: 'postgres', 
  port: 5432,
  logging: false 
});

async function checkFirstLoginUsers() {
  try {
    console.log('🔍 Verificando utilizadores que precisam alterar password...\n');
    
    const users = await sequelize.query(`
      SELECT idutilizador, nome, email, temquealterarpassword, ultimoacesso
      FROM utilizador 
      WHERE tipo = 'formando' AND estado = 'ativo'
      ORDER BY idutilizador DESC
      LIMIT 10
    `);
    
    console.log('📊 Últimos 10 utilizadores:');
    console.log('═══════════════════════════════════════════════════════════════');
    
    users[0].forEach(user => {
      console.log(`ID: ${user.idutilizador}`);
      console.log(`Nome: ${user.nome}`);
      console.log(`Email: ${user.email}`);
      console.log(`Precisa alterar password: ${user.temquealterarpassword ? '✅ SIM' : '❌ NÃO'}`);
      console.log(`Último acesso: ${user.ultimoacesso}`);
      console.log('───────────────────────────────────────────────────────────────');
    });
    
    // Contar quantos precisam alterar
    const needChange = await sequelize.query(`
      SELECT COUNT(*) as total
      FROM utilizador 
      WHERE tipo = 'formando' AND estado = 'ativo' AND temquealterarpassword = true
    `);
    
    console.log(`\n🎯 Total de utilizadores que precisam alterar password: ${needChange[0][0].total}`);
    
  } catch (error) {
    console.error('❌ Erro:', error);
  } finally {
    process.exit();
  }
}

checkFirstLoginUsers();
