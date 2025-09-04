const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', { 
  host: '172.201.108.53', 
  dialect: 'postgres', 
  port: 5432,
  logging: false 
});

async function createTestNotifications() {
  try {
    console.log('🔔 Criando notificações de teste...\n');
    
    // Verificar se já existem notificações para o utilizador ID 8
    const existing = await sequelize.query(`
      SELECT COUNT(*) as total
      FROM notificacao 
      WHERE idutilizador = 8
    `);
    
    console.log(`📊 Notificações existentes para utilizador 8: ${existing[0][0].total}`);
    
    // Criar algumas notificações de teste se não existirem muitas
    if (existing[0][0].total < 3) {
      console.log('🛠️ Criando notificações de teste...');
      
      // Encontrar o maior ID existente
      const maxIdResult = await sequelize.query(`
        SELECT COALESCE(MAX(idnotificacao), 0) as maxid FROM notificacao
      `);
      const nextId = parseInt(maxIdResult[0][0].maxid) + 1;
      console.log(`🔢 Próximo ID disponível: ${nextId}`);
      
      await sequelize.query(`
        INSERT INTO notificacao (idnotificacao, idutilizador, descricao, datahora)
        VALUES 
        (${nextId}, 8, 'Nova aula disponível: Introdução ao Python está agora disponível', NOW()),
        (${nextId + 1}, 8, 'Parabéns! Completou o quiz de JavaScript com sucesso', NOW() - INTERVAL '1 hour'),
        (${nextId + 2}, 8, 'Novos materiais foram adicionados ao curso de HTML/CSS', NOW() - INTERVAL '2 hours')
      `);
      
      console.log('✅ Notificações de teste criadas');
    }
    
    // Verificar o estado atual
    const current = await sequelize.query(`
      SELECT idnotificacao, descricao, datahora
      FROM notificacao 
      WHERE idutilizador = 8
      ORDER BY datahora DESC
      LIMIT 5
    `);
    
    console.log('\n📋 Notificações atuais:');
    console.log('═══════════════════════════════════════════════════════════════');
    
    current[0].forEach((notif, index) => {
      console.log(`${index + 1}. ID: ${notif.idnotificacao}`);
      console.log(`   Descrição: ${notif.descricao}`);
      console.log(`   Data: ${notif.datahora}`);
      console.log('───────────────────────────────────────────────────────────────');
    });
    
    console.log(`\n🎯 Total de notificações para utilizador 8: ${current[0].length}`);
    
  } catch (error) {
    console.error('❌ Erro:', error);
  } finally {
    process.exit();
  }
}

createTestNotifications();
