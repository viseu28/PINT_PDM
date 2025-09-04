const express = require('express');
const upload = require('../config/upload'); // Importar configuração de upload
const { FirebasePushService } = require('../services/firebase-push.service');

module.exports = (db) => {
  const router = express.Router(); // <-- Move para dentro da função
  const pushService = new FirebasePushService(db);

  // Listar todos os tópicos (na verdade, posts)
  router.get('/topicos', async (req, res) => {
    try {
      const topicos = await db.post.findAll({
        order: [['datahora', 'DESC']],
        include: [{
          model: db.utilizador,
          attributes: ['nome'],
          as: 'utilizador'
        }]
      });

      // Adiciona o nome do utilizador ao objeto de cada post
      const result = topicos.map(post => {
        const postJson = post.toJSON();
        postJson.autor = postJson.utilizador ? postJson.utilizador.nome : 'Utilizador';
        delete postJson.utilizador;
        return postJson;
      });

      res.json(result);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  // Criar novo tópico (forum)
  router.post('/topicos', async (req, res) => {
    try {
      const { nome, descricao, estado, autor } = req.body;
      const novoTopico = await db.forum.create({
        nome,
        descricao,
        estado,
        autor,
        datahora: new Date()
      });
      res.status(201).json(novoTopico);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  // Listar todos os posts (pode ser filtrado por categoria, titulo, etc)
  router.get('/posts', async (req, res) => {
    try {
      const posts = await db.post.findAll({ order: [['datahora', 'ASC']] });
      res.json(posts);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  // Criar novo post
  router.post('/posts', async (req, res) => {
    try {
      const { idutilizador, texto, titulo, anexo, url, idtopico } = req.body; // removido idcategoria
      const novoPost = await db.post.create({
        idutilizador,
        texto,
        titulo,
        anexo: anexo || '',
        url: url || '',
        idtopico,
        datahora: new Date()
      });
      res.status(201).json(novoPost);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  // Criar novo post com ficheiro anexado
  router.post('/posts/com-ficheiro', upload.single('ficheiro'), async (req, res) => {
    try {
      const { idutilizador, texto, titulo, url, idtopico } = req.body;
      
      console.log('📁 Criando post com ficheiro:', {
        idutilizador,
        titulo: titulo?.substring(0, 50) + '...',
        ficheiro: req.file ? req.file.originalname : 'Nenhum'
      });

      // Preparar URL do anexo
      let anexoUrl = '';
      if (req.file) {
        anexoUrl = req.file.path; // URL do Cloudinary
      }

      const novoPost = await db.post.create({
        idutilizador,
        texto,
        titulo,
        anexo: anexoUrl,
        url: url || '',
        idtopico,
        datahora: new Date()
      });

      console.log('✅ Post com ficheiro criado:', novoPost.idpost);
      res.status(201).json(novoPost);
    } catch (err) {
      console.error('❌ Erro ao criar post com ficheiro:', err);
      res.status(500).json({ error: err.message });
    }
  });

  // Eliminar post
  router.delete('/posts/:id', async (req, res) => {
    try {
      const id = req.params.id;
      // Elimina todas as respostas associadas ao post
      await db.resposta.destroy({ where: { idpost: id } });
      // Elimina todos os likes/dislikes associados ao post
      await db.likes_forum.destroy({ where: { idpost: id } });
      // Elimina todos os guardados associados ao post (corrigido para singular)
      await db.guardado.destroy({ where: { idpost: id } });
      // Agora elimina o post
      const deleted = await db.post.destroy({ where: { idpost: id } });
      if (deleted) {
        res.status(200).json({ message: 'Post eliminado com sucesso' });
      } else {
        res.status(404).json({ error: 'Post não encontrado' });
      }
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  // Endpoint para devolver só os tópicos para o dropdown
  router.get('/topicos_dropdown', async (req, res) => {
    try {
      const topicos = await db.topicos.findAll({
        attributes: ['idtopicos', 'nome'],
        order: [['nome', 'ASC']]
      });
      res.json(topicos);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  // Endpoint para devolver categorias, áreas e tópicos organizados
  router.get('/categorias_areas_topicos', async (req, res) => {
    try {
      const categorias = await db.categorias.findAll({
        include: [{
          model: db.areas,
          as: 'areas',
          include: [{
            model: db.topicos,
            as: 'topicos'
          }]
        }]
      });

      const result = categorias.map(cat => ({
        idcategoria: cat.idcategoria,
        nome: cat.nome,
        areas: cat.areas.map(area => ({
          idarea: area.idarea,
          nome: area.nome,
          topicos: area.topicos.map(topico => ({
            idtopicos: topico.idtopicos,
            nome: topico.nome
          }))
        }))
      }));

      res.json(result);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  return router;
};