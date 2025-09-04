const { Sequelize } = require('sequelize');
const { FirebasePushService } = require('./services/firebase-push.service');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false
});

// Simulação dos modelos
const db = {
  sequelize,
  utilizador: {
    findByPk: async (id) => {
      console.log(`🔍 Mock utilizador findByPk chamado com ID: ${id}`);
      const results = await sequelize.query(
        'SELECT * FROM utilizador WHERE idutilizador = :id',
        { replacements: { id }, type: sequelize.QueryTypes.SELECT }
      );
      console.log(`📊 Utilizador query retornou:`, results.length > 0 ? results[0] : 'nenhum');
      return results.length > 0 ? results[0] : null;
    }
  },
  cursos: {
    findByPk: async (id) => {
      console.log(`🔍 Mock findByPk chamado com ID: ${id}`);
      const results = await sequelize.query(
        'SELECT * FROM cursos WHERE id = :id',
        { replacements: { id }, type: sequelize.QueryTypes.SELECT }
      );
      console.log(`📊 Query retornou:`, results);
      return results.length > 0 ? results[0] : null;
    }
  }
};

async function testarNotificacao() {
  try {
    await sequelize.authenticate();
    console.log('✅ Conectado à base de dados');
    
    // Inicializar o serviço de push
    const pushService = new FirebasePushService(db);
    
    // Simular alteração do formador no curso 36 (teste1)
    console.log('🔄 Simulando alteração de formador no curso "teste1"...');
    
    const resultado = await pushService.notificarAlteracaoFormador(36, 'Novo Formador X');
    
    console.log('📤 Resultado da notificação:', resultado);
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
    console.error('Stack:', error.stack);
  } finally {
    await sequelize.close();
  }
}

testarNotificacao();
