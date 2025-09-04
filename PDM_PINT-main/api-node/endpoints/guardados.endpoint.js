const express = require('express');

module.exports = (db) => {
  const router = express.Router();
  const Guardado = db.guardado;

  // Adicionar um post aos guardados
  router.post('/', async (req, res) => {
    try {
      let { idutilizador, idpost } = req.body;
      idutilizador = parseInt(idutilizador);
      idpost = parseInt(idpost);
      if (isNaN(idutilizador) || isNaN(idpost)) {
        return res.status(400).json({ error: 'Dados inválidos.' });
      }
      await Guardado.create({ idutilizador, idpost });
      res.status(201).json({ message: 'Guardado com sucesso!' });
    } catch (err) {
      console.error('Erro ao guardar post:', err); // Mostra erro real na consola
      res.status(500).json({ error: 'Erro ao guardar post.' });
    }
  });

  // Remover um post dos guardados
  router.delete('/', async (req, res) => {
    try {
      let { idutilizador, idpost } = req.body;
      idutilizador = parseInt(idutilizador);
      idpost = parseInt(idpost);
      if (isNaN(idutilizador) || isNaN(idpost)) {
        return res.status(400).json({ error: 'Dados inválidos.' });
      }
      await Guardado.destroy({ where: { idutilizador, idpost } });
      res.json({ message: 'Removido dos guardados!' });
    } catch (err) {
      console.error('Erro ao remover guardado:', err);
      res.status(500).json({ error: 'Erro ao remover guardado.' });
    }
  });

  // Listar todos os posts guardados de um utilizador
  router.get('/:idutilizador', async (req, res) => {
    try {
      const idutilizador = parseInt(req.params.idutilizador);
      if (isNaN(idutilizador)) {
        return res.status(400).json({ error: 'ID inválido.' });
      }
      
      // Buscar IDs dos posts guardados
      const guardados = await Guardado.findAll({ 
        where: { idutilizador },
        attributes: ['idpost']
      });
      
      if (guardados.length === 0) {
        return res.json([]);
      }
      
      // Buscar os posts completos
      const idsPost = guardados.map(g => g.idpost);
      const posts = await db.post.findAll({
        where: { idpost: idsPost },
        include: [{
          model: db.utilizador,
          attributes: ['nome'],
          as: 'utilizador'
        }],
        order: [['datahora', 'DESC']]
      });
      
      // Formatar os dados
      const result = posts.map(post => {
        const postData = post.toJSON();
        postData.autor = postData.utilizador ? postData.utilizador.nome : 'Utilizador';
        delete postData.utilizador;
        return postData;
      });
      
      res.json(result);
    } catch (err) {
      console.error('Erro ao buscar guardados:', err);
      res.status(500).json({ error: 'Erro ao buscar guardados.' });
    }
  });

  return router;
};