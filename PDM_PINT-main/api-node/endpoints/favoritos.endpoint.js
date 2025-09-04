const express = require('express');
const router = express.Router();
const { Sequelize, Op } = require('sequelize');
const jwt = require('jsonwebtoken');

// Usar o mesmo JWT_SECRET que o endpoint de utilizador
const JWT_SECRET = 'chave_secreta_segura_para_desenvolvimento';

// Importar modelos
module.exports = (db) => {
  // Middleware para verificar token JWT
  const verificarToken = (req, res, next) => {
    const token = req.headers.authorization?.split(' ')[1];
    
    console.log(`[DEBUG] Verificando token para favoritos - Token presente: ${token ? 'Sim' : 'Não'}`);
    
    if (!token) {
      return res.status(401).json({ message: 'Token não fornecido' });
    }
    
    try {
      const decoded = jwt.verify(token, JWT_SECRET); // Usar o mesmo secret
      req.userId = decoded.id; // Corrigido: usar 'id' em vez de 'idutilizador'
      console.log(`[DEBUG] Token decodificado com sucesso - userId: ${req.userId}`);
      next();
    } catch (error) {
      console.error('[ERROR] Token verification failed:', error.message);
      return res.status(401).json({ message: 'Token inválido' });
    }
  };

  // Adicionar curso aos favoritos
  router.post('/:userId/:cursoId', verificarToken, async (req, res) => {
    try {
      const { userId, cursoId } = req.params;
      
      console.log(`[DEBUG] Adicionando favorito - userId: ${userId}, cursoId: ${cursoId}, req.userId: ${req.userId}`);
      
      // Verificar se o usuário tem acesso
      if (parseInt(req.userId) !== parseInt(userId)) {
        console.log(`[ERROR] Acesso negado - token userId: ${req.userId}, param userId: ${userId}`);
        return res.status(403).json({ message: 'Acesso negado' });
      }
      
      // Verificar se o curso existe
      const curso = await db.cursos.findByPk(cursoId);
      if (!curso) {
        return res.status(404).json({ message: 'Curso não encontrado' });
      }
      
      // Verificar se já existe o favorito
      const existeFavorito = await db.favoritos.findOne({
        where: {
          id_utilizador: userId,
          id_curso: cursoId
        }
      });
      
      if (existeFavorito) {
        return res.status(200).json({ message: 'Curso já está nos favoritos' });
      }
      
      // Criar o favorito
      await db.favoritos.create({
        id_utilizador: userId,
        id_curso: cursoId,
        data_adicionado: new Date()
      });
      
      res.status(201).json({ message: 'Curso adicionado aos favoritos com sucesso' });
    } catch (error) {
      console.error('Erro ao adicionar favorito:', error);
      res.status(500).json({ message: 'Erro interno do servidor' });
    }
  });

  // Remover curso dos favoritos
  router.delete('/:userId/:cursoId', verificarToken, async (req, res) => {
    try {
      const { userId, cursoId } = req.params;
      
      console.log(`[DEBUG] Removendo favorito - userId: ${userId}, cursoId: ${cursoId}`);
      
      // Verificar se o usuário tem acesso
      if (parseInt(req.userId) !== parseInt(userId)) {
        console.log(`[ERROR] Acesso negado - token userId: ${req.userId}, param userId: ${userId}`);
        return res.status(403).json({ message: 'Acesso negado' });
      }
      
      // Verificar se o favorito existe antes de remover
      const favorito = await db.favoritos.findOne({
        where: {
          id_utilizador: userId,
          id_curso: cursoId
        }
      });

      if (!favorito) {
        console.log(`[INFO] Favorito não encontrado para remover - userId: ${userId}, cursoId: ${cursoId}`);
        return res.status(404).json({ message: 'Favorito não encontrado' });
      }
      
      // Remover dos favoritos
      const resultado = await db.favoritos.destroy({
        where: {
          id_utilizador: userId,
          id_curso: cursoId
        }
      });
      
      console.log(`[INFO] Remoção de favorito - registros afetados: ${resultado}`);
      
      if (resultado > 0) {
        console.log(`[SUCCESS] Curso removido dos favoritos com sucesso - userId: ${userId}, cursoId: ${cursoId}`);
        res.status(200).json({ message: 'Curso removido dos favoritos com sucesso' });
      } else {
        console.log(`[ERROR] Falha ao remover favorito - userId: ${userId}, cursoId: ${cursoId}`);
        res.status(404).json({ message: 'Favorito não encontrado' });
      }
    } catch (error) {
      console.error('[ERROR] Erro ao remover favorito:', error);
      res.status(500).json({ message: 'Erro interno do servidor' });
    }
  });

  // Verificar se um curso está nos favoritos
  router.get('/:userId/verifica/:cursoId', verificarToken, async (req, res) => {
    try {
      const { userId, cursoId } = req.params;
      
      console.log(`[DEBUG] Verificando favorito - userId: ${userId}, cursoId: ${cursoId}, req.userId: ${req.userId}`);
      
      // Verificar se o usuário tem acesso
      if (parseInt(req.userId) !== parseInt(userId)) {
        console.log(`[ERROR] Acesso negado na verificação - token userId: ${req.userId}, param userId: ${userId}`);
        return res.status(403).json({ message: 'Acesso negado' });
      }
      
      // Verificar nos favoritos
      const favorito = await db.favoritos.findOne({
        where: {
          id_utilizador: userId,
          id_curso: cursoId
        }
      });
      
      res.status(200).json({ isFavorito: !!favorito });
    } catch (error) {
      console.error('Erro ao verificar favorito:', error);
      res.status(500).json({ message: 'Erro interno do servidor' });
    }
  });

  // Listar todos os cursos favoritos de um usuário
  router.get('/:userId', verificarToken, async (req, res) => {
    try {
      const { userId } = req.params;
      
      // Verificar se o usuário tem acesso
      if (parseInt(req.userId) !== parseInt(userId)) {
        return res.status(403).json({ message: 'Acesso negado' });
      }
      
      // Buscar cursos favoritos
      const favoritos = await db.favoritos.findAll({
        where: {
          id_utilizador: userId
        },
        include: [{
          model: db.cursos,
          as: 'curso'
        }],
        order: [['data_adicionado', 'DESC']]
      });
      
      // Mapear para retornar apenas os cursos
      const cursos = favoritos.map(fav => fav.curso);
      
      res.status(200).json(cursos);
    } catch (error) {
      console.error('Erro ao listar favoritos:', error);
      res.status(500).json({ message: 'Erro interno do servidor' });
    }
  });

  return router;
};
