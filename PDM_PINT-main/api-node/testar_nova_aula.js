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
      const results = await sequelize.query(
        'SELECT * FROM utilizador WHERE idutilizador = :id',
        { replacements: { id }, type: sequelize.QueryTypes.SELECT }
      );
      return results.length > 0 ? results[0] : null;
    }
  },
  cursos: {
    findByPk: async (id) => {
      const results = await sequelize.query(
        'SELECT * FROM cursos WHERE id = :id',
        { replacements: { id }, type: sequelize.QueryTypes.SELECT }
      );
      return results.length > 0 ? results[0] : null;
    }
  }
};

async function testarNovaAula() {
  try {
    await sequelize.authenticate();
    console.log('✅ Conectado à base de dados');
    
    // Simular adição de aula
    const aulaData = {
      titulo: 'Aula de Teste - Notificações',
      descricao: 'Aula criada para testar as notificações push',
      data: '2025-08-23T16:00:00.000Z',
      video_url: 'https://www.youtube.com/watch?v=exemplo',
      duracao: 30,
      curso_id: 37
    };
    
    console.log('\n📚 Adicionando aula de teste ao curso 37...');
    
    // Inserir aula na base de dados
    const [result] = await sequelize.query(`
      INSERT INTO aulas (titulo, descricao, data, video_url, duracao, curso_id, completa, material_apoio, created_at, updated_at) 
      VALUES (:titulo, :descricao, :data, :video_url, :duracao, :curso_id, false, null, NOW(), NOW())
      RETURNING *
    `, {
      replacements: aulaData,
      type: sequelize.QueryTypes.INSERT
    });
    
    console.log('✅ Aula adicionada:', result[0]);
    
    // Testar notificação push
    console.log('\n🔔 Testando notificação push...');
    const pushService = new FirebasePushService(db);
    
    const resultado = await pushService.notificarNovaAula(37, aulaData.titulo, aulaData.data);
    
    console.log('📤 Resultado da notificação:', resultado);
    
    if (resultado && resultado.length > 0) {
      console.log('\n🎉 SUCESSO! Sistema de notificações funcionando:');
      resultado.forEach((res, index) => {
        console.log(`   👤 Utilizador ${res.idUtilizador}: ${res.sucesso ? '✅ Enviado' : '❌ Falhou'}`);
      });
      
      console.log('\n📱 A notificação deveria aparecer no centro de notificações do telemóvel!');
      console.log('🔧 Se não apareceu, o problema pode ser:');
      console.log('   1. Token FCM não é real (é apenas "TESTE_TOKEN_123")');
      console.log('   2. Firebase não está configurado com credenciais reais');
      console.log('   3. App Flutter não está a escutar notificações');
    } else {
      console.log('\n❌ Falhou ao enviar notificação');
    }
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
    console.error('Stack:', error.stack);
  } finally {
    await sequelize.close();
  }
}

testarNovaAula();
