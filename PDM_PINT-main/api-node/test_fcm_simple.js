// Teste simples do endpoint FCM sem Firebase
const express = require('express');
const cors = require('cors');
const { Sequelize } = require('sequelize');

const app = express();
app.use(cors());
app.use(express.json());

// Conexão à base de dados
const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false,
});

// Teste simples do endpoint FCM
app.post('/fcm-token', async (req, res) => {
  try {
    const { idutilizador, fcm_token } = req.body;
    
    console.log('📨 Received request:', req.body);
    
    if (!idutilizador || !fcm_token) {
      return res.status(400).json({
        erro: 'idutilizador e fcm_token são obrigatórios'
      });
    }

    // Atualizar o token FCM na base de dados
    await sequelize.query(`
      UPDATE utilizador 
      SET fcm_token = :fcm_token 
      WHERE idutilizador = :idutilizador
    `, {
      replacements: { idutilizador, fcm_token },
      type: sequelize.QueryTypes.UPDATE
    });

    console.log(`✅ Token FCM atualizado para utilizador ${idutilizador}`);
    
    res.json({ 
      sucesso: true, 
      mensagem: 'Token FCM atualizado com sucesso',
      dados: { idutilizador, fcm_token }
    });
  } catch (error) {
    console.error('❌ Erro ao atualizar token FCM:', error);
    res.status(500).json({ erro: error.message });
  }
});

// Endpoint de status
app.get('/status', async (req, res) => {
  try {
    await sequelize.authenticate();
    res.json({
      status: 'OK',
      database: 'Conectada ✅',
      api: 'FCM Test funcionando',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      database: 'Desconectada ❌',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

const PORT = 3001;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Servidor de teste FCM a correr em http://0.0.0.0:${PORT}`);
});
