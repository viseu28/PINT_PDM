const express = require('express');
const upload = require('../config/upload'); // Importar configuração de upload
const router = express.Router();

module.exports = (db) => {
  router.post('/', async (req, res) => {
    try {
      const { idpost, autor, texto, idrespostapai, idutilizador, url } = req.body; // *** NOVO: Adicionar URL ***
      const novaResposta = await db.resposta.create({
        idpost,
        autor,
        texto,
        idrespostapai,
        idutilizador, 
        url, // *** NOVO: Incluir URL ***
        datahora: new Date()
      });
      res.status(201).json(novaResposta);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  // *** NOVO: Endpoint para criar resposta com ficheiro ***
  router.post('/upload', (req, res) => {
    console.log('📤 Upload endpoint chamado - ANTES do multer');
    console.log('📋 Headers:', req.headers);
    
    // Aplicar multer manualmente para ter mais controle
    upload.single('ficheiro')(req, res, async (err) => {
      if (err) {
        console.error('❌ Erro no multer:', err);
        return res.status(500).json({ error: 'Erro no upload: ' + err.message });
      }
      
      try {
        console.log('📤 Upload endpoint chamado - DEPOIS do multer');
        console.log('📋 Body:', req.body);
        console.log('📁 File:', req.file);
        console.log('📁 Files array:', req.files);
        
        const { idpost, autor, texto, idrespostapai, idutilizador } = req.body;
        
        let anexo = null;
        if (req.file) {
          // Para Cloudinary, usar a URL segura do ficheiro
          anexo = req.file.path; // Cloudinary retorna a URL completa em req.file.path
          console.log('✅ Ficheiro recebido:', anexo);
        } else {
          console.log('❌ Nenhum ficheiro recebido no req.file');
        }

        const novaResposta = await db.resposta.create({
          idpost,
          autor,
          texto,
          idrespostapai,
          idutilizador,
          anexo, // *** NOVO: Campo para ficheiro ***
          datahora: new Date()
        });
        
        console.log('✅ Resposta criada:', novaResposta.toJSON());
        res.status(201).json(novaResposta);
      } catch (err) {
        console.error('❌ Erro ao criar resposta com ficheiro:', err);
        res.status(500).json({ error: err.message });
      }
    });
  });

  // Listar respostas de um post
  router.get('/:idpost', async (req, res) => {
    try {
      const respostas = await db.resposta.findAll({
        where: { idpost: req.params.idpost },
        order: [['datahora', 'ASC']],
        attributes: [
          'idresposta', 'idutilizador', 'texto', 'datahora', 'idrespostapai', 'url', 'anexo' // *** NOVO: Adicionar url e anexo ***
        ],
        include: [
          {
            model: db.utilizador,
            as: 'autorUser',
            attributes: ['nome'] // só o nome do utilizador
          },
          {
            model: db.resposta,
            as: 'respostaPai',
            attributes: ['idresposta', 'texto']
          }
        ]
      });

      const respostasJson = respostas.map(r => {
        const obj = r.toJSON();
        return {
          ...obj,
          autor: obj.autorUser ? obj.autorUser.nome : null, // devolve o nome do autor
          resposta_pai_autor: obj.respostaPai ? obj.respostaPai.texto : null,
          resposta_pai_texto: obj.respostaPai ? obj.respostaPai.texto : null
        };
      });

      res.json(respostasJson);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.delete('/:id', async (req, res) => {
    try {
      const id = req.params.id;
      const deleted = await db.resposta.destroy({ where: { idresposta: id } }); 
      if (deleted) {
        res.status(200).json({ success: true });
      } else {
        res.status(404).json({ error: 'Resposta não encontrada' });
      }
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  return router;
};