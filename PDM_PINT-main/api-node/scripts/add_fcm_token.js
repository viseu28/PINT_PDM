const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: console.log
});

async function adicionarColunaFCM() {
  try {
    console.log('🔗 Conectando à base de dados...');
    await sequelize.authenticate();
    console.log('✅ Conexão estabelecida com sucesso');

    // Verificar se a coluna já existe
    console.log('🔍 Verificando se a coluna fcm_token já existe...');
    const [resultados] = await sequelize.query(
      `SELECT column_name FROM information_schema.columns WHERE table_name = 'utilizador' AND column_name = 'fcm_token'`
    );

    if (resultados.length > 0) {
      console.log('⚠️ A coluna fcm_token já existe na tabela utilizador');
      return;
    }

    console.log('📝 Adicionando coluna fcm_token à tabela utilizador...');
    await sequelize.query('ALTER TABLE utilizador ADD COLUMN fcm_token TEXT DEFAULT NULL');
    console.log('✅ Coluna fcm_token adicionada com sucesso!');

    // Adicionar comentário
    await sequelize.query(`COMMENT ON COLUMN utilizador.fcm_token IS 'Token FCM para notificações push do Firebase'`);
    console.log('💬 Comentário da coluna adicionado');

    // Verificar resultado
    const [verificacao] = await sequelize.query(
      `SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'utilizador' AND column_name = 'fcm_token'`
    );
    
    console.log('🔍 Verificação final:', verificacao[0]);
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
    console.log('🔌 Conexão fechada');
  }
}

adicionarColunaFCM();
