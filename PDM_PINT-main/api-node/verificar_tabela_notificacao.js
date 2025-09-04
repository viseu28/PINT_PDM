const { Sequelize } = require('sequelize');

// Configuração da base de dados (igual ao index.js)
const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false
});

async function verificarTabelaNotificacao() {
  try {
    console.log('🔍 Verificando estrutura da tabela notificacao...\n');
    
    // Verificar colunas da tabela
    const result = await sequelize.query(`
      SELECT column_name, data_type, is_nullable, column_default, character_maximum_length
      FROM information_schema.columns 
      WHERE table_name = 'notificacao' 
      ORDER BY ordinal_position
    `);
    
    console.log('📋 Colunas da tabela notificacao:');
    result[0].forEach(col => {
      console.log(`  ${col.column_name}: ${col.data_type} (nullable: ${col.is_nullable}, default: ${col.column_default})`);
    });
    
    // Verificar se existem sequences para auto-incremento
    const sequences = await sequelize.query(`
      SELECT column_name, column_default
      FROM information_schema.columns 
      WHERE table_name = 'notificacao' 
      AND column_default LIKE '%nextval%'
    `);
    
    if (sequences[0].length > 0) {
      console.log('\n🔢 Colunas com auto-incremento:');
      sequences[0].forEach(seq => {
        console.log(`  ${seq.column_name}: ${seq.column_default}`);
      });
    }
    
    // Testar uma inserção
    console.log('\n🧪 Testando inserção com DEFAULT para idnotificacao...');
    await sequelize.query(`
      INSERT INTO notificacao (idnotificacao, idutilizador, descricao, datahora)
      VALUES (DEFAULT, 8, 'Teste de notificação', NOW())
    `);
    console.log('✅ Inserção com DEFAULT funcionou!');
    
    // Verificar o que foi inserido
    const testResult = await sequelize.query(`
      SELECT * FROM notificacao WHERE idutilizador = 8 ORDER BY datahora DESC LIMIT 1
    `);
    
    console.log('\n📄 Última notificação inserida:');
    console.log(testResult[0][0]);
    
    // Apagar o teste
    await sequelize.query(`
      DELETE FROM notificacao WHERE idutilizador = 8 AND descricao = 'Teste de notificação'
    `);
    console.log('\n🧹 Notificação de teste removida');
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
    process.exit(0);
  }
}

verificarTabelaNotificacao();
