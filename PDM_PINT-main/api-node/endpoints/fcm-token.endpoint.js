const express = require('express');

module.exports = (db) => {
  const router = express.Router();

  // Endpoint para atualizar o token FCM do utilizador
  router.post('/', async (req, res) => {
    try {
      const { idutilizador, utilizador_id, fcm_token } = req.body;
      
      // Aceitar tanto idutilizador quanto utilizador_id
      const userId = idutilizador || utilizador_id;
      
      if (!userId || !fcm_token) {
        return res.status(400).json({
          erro: 'idutilizador/utilizador_id e fcm_token são obrigatórios'
        });
      }

      // Atualizar o token FCM na base de dados
      await db.sequelize.query(`
        UPDATE utilizador 
        SET fcm_token = :fcm_token 
        WHERE idutilizador = :userId
      `, {
        replacements: { userId, fcm_token },
        type: db.sequelize.QueryTypes.UPDATE
      });

      console.log(`🔔 Token FCM atualizado para utilizador ${userId}: ${fcm_token.substring(0, 20)}...`);
      
      res.json({ 
        sucesso: true, 
        mensagem: `Token FCM registrado para utilizador ${userId}` 
      });
    } catch (error) {
      console.error('❌ Erro ao atualizar token FCM:', error);
      res.status(500).json({ erro: error.message });
    }
  });

  // Endpoint para remover o token FCM (quando utilizador faz logout)
  router.delete('/:idutilizador', async (req, res) => {
    try {
      const { idutilizador } = req.params;
      
      await db.sequelize.query(`
        UPDATE utilizador 
        SET fcm_token = NULL 
        WHERE idutilizador = :idutilizador
      `, {
        replacements: { idutilizador },
        type: db.sequelize.QueryTypes.UPDATE
      });

      console.log(`🗑️ Token FCM removido para utilizador ${idutilizador}`);
      
      res.json({ 
        sucesso: true, 
        mensagem: 'Token FCM removido com sucesso' 
      });
    } catch (error) {
      console.error('❌ Erro ao remover token FCM:', error);
      res.status(500).json({ erro: error.message });
    }
  });

  return router;
};
