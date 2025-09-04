const { Sequelize } = require('sequelize');
const { FirebasePushService } = require('./services/firebase-push.service');

// Configuração da base de dados
const sequelize = new Sequelize('projeto_pint', 'postgres', 'root', {
  host: 'localhost',
  dialect: 'postgres',
  logging: false
});

// Mock do objeto db
const db = {
  sequelize,
  cursos: {
    findByPk: async (id) => {
      const [result] = await sequelize.query(`
        SELECT * FROM cursos WHERE id = :id
      `, {
        replacements: { id },
        type: sequelize.QueryTypes.SELECT
      });
      return result[0] || null;
    }
  },
  utilizador: {
    findByPk: async (id) => {
      const [result] = await sequelize.query(`
        SELECT * FROM utilizador WHERE id = :id
      `, {
        replacements: { id },
        type: sequelize.QueryTypes.SELECT
      });
      return result[0] || null;
    }
  }
};

async function testarNotificacaoLinks() {
  try {
    await sequelize.authenticate();
    console.log('✅ Conectado à base de dados');
    
    // Inicializar o serviço de push
    const pushService = new FirebasePushService(db);
    
    console.log('\n🔗 Testando notificação de NOVO LINK...');
    
    // Testar notificação de novo link no curso 2 (Desenvolvimento Front-End)
    const resultadoNovoLink = await pushService.notificarNovoLink(
      2, 
      'ChatGPT - Ferramenta IA', 
      'https://chatgpt.com/'
    );
    
    console.log('📤 Resultado da notificação (novo link):', resultadoNovoLink);
    
    console.log('\n🗑️ Testando notificação de LINK REMOVIDO...');
    
    // Testar notificação de link removido
    const resultadoLinkRemovido = await pushService.notificarLinkRemovido(
      2,
      'ChatGPT - Ferramenta IA'
    );
    
    console.log('📤 Resultado da notificação (link removido):', resultadoLinkRemovido);
    
    if (resultadoNovoLink && resultadoNovoLink.length > 0) {
      console.log('\n🎉 SUCESSO! Sistema de notificações para links funcionando:');
      resultadoNovoLink.forEach((res, index) => {
        console.log(`   👤 Utilizador ${res.idUtilizador}: ${res.sucesso ? '✅ Enviado' : '❌ Falhou'}`);
      });
      
      console.log('\n📱 As notificações deveriam aparecer no centro de notificações!');
      console.log('🔧 Se não apareceram, o problema pode ser:');
      console.log('   1. Tokens FCM não são reais');
      console.log('   2. Firebase não está configurado com credenciais reais');
      console.log('   3. App Flutter não está a escutar notificações');
    } else {
      console.log('\n❌ Falhou ao enviar notificações');
    }
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
    console.error('Stack:', error.stack);
  } finally {
    await sequelize.close();
  }
}

// Executar teste
testarNotificacaoLinks();
