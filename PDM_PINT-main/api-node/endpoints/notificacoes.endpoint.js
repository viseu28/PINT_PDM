const express = require('express');
const router = express.Router();
const db = require('../models/utilizador');

module.exports = (db) => {
  // GET notificações de um utilizador
  router.get('/:idutilizador', async (req, res) => {
    const { idutilizador } = req.params;
    try {
      const notificacoes = await db.notificacao.findAll({
        where: { idutilizador },
        order: [['datahora', 'DESC']],
      });
      res.json(notificacoes);
    } catch (err) {
      console.error('Erro ao buscar notificações:', err);
      res.status(500).json({ erro: 'Erro ao buscar notificações' });
    }
  });

router.delete('/:id', async (req, res) => {
  const { id } = req.params;
  try {
    await db.notificacao.destroy({ where: { idnotificacao: id } });
    res.status(200).json({ message: 'Notificação apagada com sucesso' });
  } catch (error) {
    console.error('Erro ao apagar notificação:', error);
    res.status(500).json({ erro: 'Erro ao apagar notificação' });
  }
});

return router;
};

