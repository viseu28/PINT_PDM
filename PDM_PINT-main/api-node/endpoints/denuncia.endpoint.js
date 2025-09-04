const express = require('express');
const { FirebasePushService } = require('../services/firebase-push.service');

module.exports = (db) => {
  const router = express.Router();
  const pushService = new FirebasePushService(db);

  // Criar denúncia
  router.post('/', async (req, res) => {
    try {
      const { idpost, motivo, idutilizador, idcomentario, data } = req.body;
      
      // Criar a denúncia
      const denuncia = await db.denuncia.create({
        idpost,
        motivo,
        idutilizador,
        idcomentario: idcomentario || null,
        data: data ? new Date(data) : new Date(),
      });

      // 🔥 NOTIFICAÇÃO PUSH: Notificar o autor do comentário/post denunciado
      try {
        let idAutor = null;
        let tipoConteudo = '';

        if (idcomentario) {
          // É um comentário denunciado
          const comentario = await db.comentario.findByPk(idcomentario);
          if (comentario) {
            idAutor = comentario.idutilizador;
            tipoConteudo = 'comentário';
          }
        } else if (idpost) {
          // É um post do fórum denunciado
          const post = await db.post.findByPk(idpost);
          if (post) {
            idAutor = post.idutilizador;
            tipoConteudo = 'post';
          }
        }

        if (idAutor) {
          await pushService.notificarComentarioDenunciado(idAutor, tipoConteudo, motivo);
          console.log(`🔔 Notificação de denúncia enviada para utilizador ${idAutor}`);
        }
      } catch (notifError) {
        console.error('⚠️ Erro ao enviar notificação de denúncia:', notifError);
        // Não falhar a criação da denúncia por causa da notificação
      }

      res.status(201).json(denuncia);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  return router;
};