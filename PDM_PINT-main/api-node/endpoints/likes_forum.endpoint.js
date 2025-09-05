const express = require('express');

module.exports = (db) => {
    const router = express.Router();
    const LikesForum = db.likes_forum;

    // Adicionar ou atualizar like/dislike
    router.post('/', async (req, res) => {
        const { idutilizador, idpost, idresposta, tipo } = req.body;
        try {
            // Validar que pelo menos um ID está presente
            if (!idpost && !idresposta) {
                return res.status(400).json({ error: 'Deve especificar idpost OU idresposta.' });
            }
            if (idpost && idresposta) {
                return res.status(400).json({ error: 'Não pode especificar idpost E idresposta ao mesmo tempo.' });
            }

            // Verificar se o post existe (se for like de post)
            if (idpost) {
                const postExists = await db.post.findByPk(idpost);
                if (!postExists) {
                    return res.status(404).json({ error: 'Post não encontrado.' });
                }
            }

            // Verificar se a resposta existe (se for like de resposta)
            if (idresposta) {
                const respostaExists = await db.resposta.findByPk(idresposta);
                if (!respostaExists) {
                    return res.status(404).json({ error: 'Resposta não encontrada.' });
                }
            }
            
            await LikesForum.upsert({ 
                id_utilizador: idutilizador, 
                id_post: idpost, 
                idresposta, 
                data_like: new Date() 
            });
            res.status(201).json({ message: 'Like/dislike registado!' });
        } catch (err) {
            console.error('Erro ao registar like/dislike:', err);
            res.status(500).json({ error: 'Erro ao registar like/dislike.' });
        }
    });

    // Remover like/dislike
    router.delete('/', async (req, res) => {
        const { idutilizador, idpost, idresposta } = req.body;
        try {
            // Construir a condição WHERE baseada nos parâmetros fornecidos
            const whereCondition = { id_utilizador: idutilizador };
            if (idpost) whereCondition.id_post = idpost;
            if (idresposta) whereCondition.idresposta = idresposta;
            
            await LikesForum.destroy({ where: whereCondition });
            res.json({ message: 'Like/dislike removido!' });
        } catch (err) {
            console.error('Erro ao remover like/dislike:', err);
            res.status(500).json({ error: 'Erro ao remover like/dislike.' });
        }
    });

    // Buscar likes/dislikes de um utilizador
    router.get('/:idutilizador', async (req, res) => {
        try {
            const idutilizador = parseInt(req.params.idutilizador);
            const likes = await LikesForum.findAll({ where: { idutilizador } });
            res.json(likes);
        } catch (err) {
            res.status(500).json({ error: 'Erro ao buscar likes.' });
        }
    });

    // Contar likes/dislikes de um post específico
    router.get('/count/:idpost', async (req, res) => {
        try {
            const idpost = parseInt(req.params.idpost);
            
            // Verificar se o post existe
            const postExists = await db.post.findByPk(idpost);
            if (!postExists) {
                return res.status(404).json({ error: 'Post não encontrado.' });
            }
            
            // Contar likes
            const likesCount = await LikesForum.count({ 
                where: { idpost, tipo: 'like' } 
            });
            
            // Contar dislikes  
            const dislikesCount = await LikesForum.count({ 
                where: { idpost, tipo: 'dislike' } 
            });
            
            res.json({ 
                likes: likesCount, 
                dislikes: dislikesCount 
            });
        } catch (err) {
            console.error('Erro ao contar likes/dislikes:', err);
            res.status(500).json({ error: 'Erro ao contar likes/dislikes.' });
        }
    });

    // Contar likes/dislikes de uma resposta específica
    router.get('/count/resposta/:idresposta', async (req, res) => {
        try {
            const idresposta = parseInt(req.params.idresposta);
            
            // Verificar se a resposta existe
            const respostaExists = await db.resposta.findByPk(idresposta);
            if (!respostaExists) {
                return res.status(404).json({ error: 'Resposta não encontrada.' });
            }
            
            // Contar likes
            const likesCount = await LikesForum.count({ 
                where: { idresposta, tipo: 'like' } 
            });
            
            // Contar dislikes  
            const dislikesCount = await LikesForum.count({ 
                where: { idresposta, tipo: 'dislike' } 
            });
            
            res.json({ 
                likes: likesCount, 
                dislikes: dislikesCount 
            });
        } catch (err) {
            console.error('Erro ao contar likes/dislikes da resposta:', err);
            res.status(500).json({ error: 'Erro ao contar likes/dislikes da resposta.' });
        }
    });

    return router;
};