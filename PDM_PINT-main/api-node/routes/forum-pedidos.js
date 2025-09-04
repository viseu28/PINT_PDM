const express = require('express');
const { Pool } = require('pg');

module.exports = (db) => {
  const router = express.Router();

  // Conexão à base de dados
  const pool = new Pool({
      user: 'grupo',
      host: '172.201.108.53',
      database: 'pint',
      password: 'paswwordpint',
      port: 5432,
  });

  // GET - Obter todas as categorias para dropdown
  router.get('/categorias', async (req, res) => {
      try {
          console.log('📋 Obtendo categorias para dropdown...');
          
          const result = await pool.query(`
              SELECT idcategoria as id, nome 
              FROM categorias 
              ORDER BY nome
          `);
          
          res.json({
              success: true,
              categorias: result.rows
          });
          
      } catch (error) {
          console.error('❌ Erro ao obter categorias:', error);
          res.status(500).json({
              success: false,
              message: 'Erro ao obter categorias',
              error: error.message
          });
      }
  });

  // GET - Obter áreas por categoria para dropdown dependente
  router.get('/areas/:categoriaId', async (req, res) => {
      try {
          const { categoriaId } = req.params;
          console.log(`📂 Obtendo áreas para categoria ${categoriaId}...`);
          
          const result = await pool.query(`
              SELECT idarea as id, nome 
              FROM areas 
              WHERE idcategoria = $1 
              ORDER BY nome
          `, [categoriaId]);
          
          res.json({
              success: true,
              areas: result.rows
          });
          
      } catch (error) {
          console.error('❌ Erro ao obter áreas:', error);
          res.status(500).json({
              success: false,
              message: 'Erro ao obter áreas',
              error: error.message
          });
      }
  });

  // POST - Criar novo pedido de tópico
  router.post('/pedidos', async (req, res) => {
      try {
          const {
              user_id,
              categoria_id,
              categoria_sugerida,
              area_id,
              area_sugerida,
              topico_sugerido,
              descricao
          } = req.body;
          
          console.log('📝 Criando novo pedido de tópico:', {
              user_id,
              categoria_id,
              categoria_sugerida,
              area_id,
              area_sugerida,
              topico_sugerido
          });
          
          // Validações
          if (!user_id || !topico_sugerido) {
              return res.status(400).json({
                  success: false,
                  message: 'user_id e topico_sugerido são obrigatórios'
              });
          }
          
          // Se não escolheu categoria existente, deve ter categoria_sugerida
          if (!categoria_id && !categoria_sugerida) {
              return res.status(400).json({
                  success: false,
                  message: 'Deve escolher uma categoria existente ou sugerir uma nova'
              });
          }
          
          // Se não escolheu área existente, deve ter area_sugerida
          if (!area_id && !area_sugerida) {
              return res.status(400).json({
                  success: false,
                  message: 'Deve escolher uma área existente ou sugerir uma nova'
              });
          }
          
          const result = await pool.query(`
              INSERT INTO pedidos_topicos (
                  user_id, categoria_id, categoria_sugerida, 
                  area_id, area_sugerida, topico_sugerido, descricao
              ) VALUES ($1, $2, $3, $4, $5, $6, $7)
              RETURNING *
          `, [
              user_id,
              categoria_id || null,
              categoria_sugerida || null,
              area_id || null,
              area_sugerida || null,
              topico_sugerido,
              descricao || null
          ]);
          
          console.log('✅ Pedido criado com sucesso:', result.rows[0]);
          
          res.json({
              success: true,
              message: 'Pedido de tópico criado com sucesso',
              pedido: result.rows[0]
          });
          
      } catch (error) {
          console.error('❌ Erro ao criar pedido:', error);
          res.status(500).json({
              success: false,
              message: 'Erro ao criar pedido de tópico',
              error: error.message
          });
      }
  });

  // GET - Obter pedidos de um utilizador
  router.get('/pedidos/usuario/:userId', async (req, res) => {
      try {
          const { userId } = req.params;
          console.log(`📋 Obtendo pedidos do utilizador ${userId}...`);
          
          const result = await pool.query(`
              SELECT 
                  p.*,
                  c.nome as categoria_nome,
                  a.nome as area_nome,
                  u.nome as utilizador_nome
              FROM pedidos_topicos p
              LEFT JOIN categorias c ON p.categoria_id = c.idcategoria
              LEFT JOIN areas a ON p.area_id = a.idarea
              LEFT JOIN utilizador u ON p.user_id = u.idutilizador
              WHERE p.user_id = $1
              ORDER BY p.data_pedido DESC
          `, [userId]);
          
          res.json({
              success: true,
              pedidos: result.rows
          });
          
      } catch (error) {
          console.error('❌ Erro ao obter pedidos do utilizador:', error);
          res.status(500).json({
              success: false,
              message: 'Erro ao obter pedidos do utilizador',
              error: error.message
          });
      }
  });

  // GET - Obter todos os pedidos (para admin)
  router.get('/pedidos', async (req, res) => {
      try {
          const { estado } = req.query;
          console.log('📋 Obtendo todos os pedidos...');
          
          let query = `
              SELECT 
                  p.*,
                  c.nome as categoria_nome,
                  a.nome as area_nome,
                  u.nome as utilizador_nome,
                  admin.nome as admin_nome
              FROM pedidos_topicos p
              LEFT JOIN categorias c ON p.categoria_id = c.idcategoria
              LEFT JOIN areas a ON p.area_id = a.idarea
              LEFT JOIN utilizador u ON p.user_id = u.idutilizador
              LEFT JOIN utilizador admin ON p.admin_responsavel = admin.idutilizador
          `;
          
          const params = [];
          if (estado) {
              query += ' WHERE p.estado = $1';
              params.push(estado);
          }
          
          query += ' ORDER BY p.data_pedido DESC';
          
          const result = await pool.query(query, params);
          
          res.json({
              success: true,
              pedidos: result.rows
          });
          
      } catch (error) {
          console.error('❌ Erro ao obter pedidos:', error);
          res.status(500).json({
              success: false,
              message: 'Erro ao obter pedidos',
              error: error.message
          });
      }
  });

  // PUT - Atualizar estado do pedido (aceitar/recusar)
  router.put('/pedidos/:id/estado', async (req, res) => {
      try {
          const { id } = req.params;
          const { estado, admin_responsavel, observacoes } = req.body;
          
          console.log(`🔄 Atualizando estado do pedido ${id} para ${estado}...`);
          
          if (!['aceite', 'recusado'].includes(estado)) {
              return res.status(400).json({
                  success: false,
                  message: 'Estado deve ser "aceite" ou "recusado"'
              });
          }
          
          const result = await pool.query(`
              UPDATE pedidos_topicos 
              SET estado = $1, admin_responsavel = $2, observacoes = $3, data_resposta = CURRENT_TIMESTAMP
              WHERE id = $4
              RETURNING *
          `, [estado, admin_responsavel, observacoes || null, id]);
          
          if (result.rows.length === 0) {
              return res.status(404).json({
                  success: false,
                  message: 'Pedido não encontrado'
              });
          }
          
          console.log('✅ Estado do pedido atualizado:', result.rows[0]);
          
          res.json({
              success: true,
              message: `Pedido ${estado} com sucesso`,
              pedido: result.rows[0]
          });
          
      } catch (error) {
          console.error('❌ Erro ao atualizar estado do pedido:', error);
          res.status(500).json({
              success: false,
              message: 'Erro ao atualizar estado do pedido',
              error: error.message
          });
      }
  });

  return router;
};
