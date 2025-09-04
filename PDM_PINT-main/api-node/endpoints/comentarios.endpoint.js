const express = require('express');

module.exports = (db) => {
  const router = express.Router();
  const { comentario: Comentário, sequelize } = db;
  const Utilizador = db.utilizador;

  // GET /comentarios/curso/:idcurso - buscar comentários por curso
  router.get('/curso/:idcurso', async (req, res) => {
    try {
      const { idcurso } = req.params;
      
      console.log(`🔍 Buscando comentários para o curso ${idcurso}`);
      
      // Buscar comentários com informações do utilizador
      const comentarios = await sequelize.query(`
        SELECT 
          c.id,
          c.idcurso,
          c.idutilizador,
          c.comentario,
          c.avaliacao,
          c.data,
          u.nome as nome_utilizador,
          u.email as email_utilizador,
          u.tipo as tipo_utilizador
        FROM comentarios c
        LEFT JOIN utilizador u ON c.idutilizador = u.idutilizador
        WHERE c.idcurso = :idcurso
        ORDER BY c.data DESC
      `, {
        replacements: { idcurso: Number(idcurso) },
        type: sequelize.QueryTypes.SELECT
      });
      
      console.log(`📤 Encontrados ${comentarios.length} comentários`);
        // Verificar se existem comentários na tabela
        const totalComentarios = await sequelize.query(
          "SELECT COUNT(*) as total FROM comentarios",
          { type: sequelize.QueryTypes.SELECT }
        );
        console.log(`📊 Total de comentários na tabela: ${totalComentarios[0].total}`);
        
        // Verificar comentários para este curso específico
        const comentariosCurso = await sequelize.query(
          "SELECT * FROM comentarios WHERE idcurso = :idcurso",
          { 
            replacements: { idcurso: Number(idcurso) },
            type: sequelize.QueryTypes.SELECT 
          }
        );
      
      console.log(`� Encontrados ${comentarios.length} comentários`);
      
      res.json({
        success: true,
        data: comentarios,
        total: comentarios.length
      });
      
    } catch (error) {
      console.error('❌ Erro ao buscar comentários:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao buscar comentários',
        message: error.message
      });
    }
  });

  // POST /comentarios - criar novo comentário
  router.post('/', async (req, res) => {
    try {
      const { idcurso, idutilizador, comentario, avaliacao } = req.body;
      
      console.log('📝 Criando novo comentário:', {
        idcurso,
        idutilizador,
        comentario: comentario?.substring(0, 50) + '...',
        avaliacao
      });
      
      // Validações básicas
      if (!idcurso || !idutilizador || !comentario) {
        return res.status(400).json({
          success: false,
          error: 'Campos obrigatórios: idcurso, idutilizador, comentario'
        });
      }
      
      if (avaliacao && (avaliacao < 0 || avaliacao > 5)) {
        return res.status(400).json({
          success: false,
          error: 'Avaliação deve estar entre 0 e 5'
        });
      }
      
      // *** REMOVIDO: Verificação de inscrição - permitindo que qualquer pessoa comente ***
      // Comentário: Agora qualquer utilizador logado pode comentar e avaliar cursos
      
      console.log('✅ Utilizador autorizado a comentar (sem verificação de inscrição)');
      
      // Criar o comentário
      const [result] = await sequelize.query(`
        INSERT INTO comentarios (idcurso, idutilizador, comentario, avaliacao, data)
        VALUES (:idcurso, :idutilizador, :comentario, :avaliacao, NOW())
        RETURNING *
      `, {
        replacements: {
          idcurso,
          idutilizador,
          comentario,
          avaliacao: avaliacao || null
        },
        type: sequelize.QueryTypes.INSERT
      });
      
      console.log('✅ Comentário criado com sucesso');
      
      res.status(201).json({
        success: true,
        data: result[0],
        message: 'Comentário criado com sucesso'
      });
      
    } catch (error) {
      console.error('❌ Erro ao criar comentário:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao criar comentário',
        message: error.message
      });
    }
  });

  // GET /comentarios/estatisticas/:idcurso - estatísticas dos comentários de um curso
  router.get('/estatisticas/:idcurso', async (req, res) => {
    try {
      const { idcurso } = req.params;
      
      console.log(`📊 Buscando estatísticas de comentários para o curso ${idcurso}`);
      
      const [stats] = await sequelize.query(`
        SELECT 
          COUNT(*) as total_comentarios,
          AVG(avaliacao) as avaliacao_media,
          COUNT(CASE WHEN avaliacao IS NOT NULL THEN 1 END) as total_avaliacoes,
          MIN(avaliacao) as avaliacao_minima,
          MAX(avaliacao) as avaliacao_maxima
        FROM comentarios 
        WHERE idcurso = :idcurso
      `, {
        replacements: { idcurso },
        type: sequelize.QueryTypes.SELECT
      });
      
      // Distribuição das avaliações
      const [distribuicao] = await sequelize.query(`
        SELECT 
          avaliacao,
          COUNT(*) as quantidade
        FROM comentarios 
        WHERE idcurso = :idcurso AND avaliacao IS NOT NULL
        GROUP BY avaliacao
        ORDER BY avaliacao
      `, {
        replacements: { idcurso },
        type: sequelize.QueryTypes.SELECT
      });
      
      const resultado = {
        ...stats[0],
        distribuicao_avaliacoes: distribuicao,
        avaliacao_media_formatada: stats[0].avaliacao_media ? 
          parseFloat(stats[0].avaliacao_media).toFixed(1) : null
      };
      
      console.log('📤 Estatísticas enviadas:', resultado);
      
      res.json({
        success: true,
        data: resultado
      });
      
    } catch (error) {
      console.error('❌ Erro ao buscar estatísticas:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao buscar estatísticas',
        message: error.message
      });
    }
  });

  // Rota removida (duplicada)

  // GET /comentarios/test - testar conectividade
  router.get('/test', (req, res) => {
    console.log('✅ Teste de conectividade com endpoint de comentários');
    res.json({
      success: true,
      message: 'API de comentários está funcionando corretamente',
      timestamp: new Date().toISOString()
    });
  });

  // Rota de depuração para verificar todos os comentários
  router.get('/debug', async (req, res) => {
    try {
      console.log('🔍 Executando rota de depuração de comentários');
      
      // Verificar estrutura da tabela comentarios
      const estruturaComentarios = await sequelize.query(
        "SELECT column_name FROM information_schema.columns WHERE table_name = 'comentarios'",
        { type: sequelize.QueryTypes.SELECT }
      );
      
      console.log('📋 Estrutura da tabela comentarios:');
      estruturaComentarios.forEach(col => console.log(`   - ${col.column_name}`));
      
      // Verificar estrutura da tabela utilizador
      const estruturaUtilizador = await sequelize.query(
        "SELECT column_name FROM information_schema.columns WHERE table_name = 'utilizador'",
        { type: sequelize.QueryTypes.SELECT }
      );
      
      console.log('📋 Estrutura da tabela utilizador:');
      estruturaUtilizador.forEach(col => console.log(`   - ${col.column_name}`));
      
      // Consulta para obter todos os comentários
      const todosComentarios = await sequelize.query(
        "SELECT * FROM comentarios",
        { type: sequelize.QueryTypes.SELECT }
      );
      
      console.log(`📊 Total de comentários na tabela: ${todosComentarios.length}`);
      
      // Agrupar por curso
      const comentariosPorCurso = {};
      todosComentarios.forEach(c => {
        const cursoId = c.idcurso;
        if (!comentariosPorCurso[cursoId]) {
          comentariosPorCurso[cursoId] = [];
        }
        comentariosPorCurso[cursoId].push(c);
      });
      
      res.json({
        success: true,
        total: todosComentarios.length,
        estruturaComentarios: estruturaComentarios,
        estruturaUtilizador: estruturaUtilizador,
        comentarios: todosComentarios,
        porCurso: comentariosPorCurso
      });
    } catch (error) {
      console.error('❌ Erro na depuração:', error);
      res.status(500).json({
        success: false,
        error: 'Erro na depuração de comentários',
        message: error.message
      });
    }
  });

  // GET /comentarios/verificar/:idcurso/:idutilizador - verificar se utilizador já avaliou o curso
  router.get('/verificar/:idcurso/:idutilizador', async (req, res) => {
    try {
      const { idcurso, idutilizador } = req.params;
      
      console.log(`🔍 Verificando se utilizador ${idutilizador} já avaliou o curso ${idcurso}`);
      
      // Buscar comentário/avaliação existente
      const comentario = await sequelize.query(`
        SELECT 
          id,
          idcurso,
          idutilizador,
          comentario,
          avaliacao,
          data
        FROM comentarios
        WHERE idcurso = :idcurso AND idutilizador = :idutilizador
      `, {
        replacements: { 
          idcurso: Number(idcurso),
          idutilizador: Number(idutilizador)
        },
        type: sequelize.QueryTypes.SELECT
      });
      
      console.log(`📊 Resultado da verificação: ${comentario.length > 0 ? 'Encontrado' : 'Não encontrado'}`);
      
      if (comentario.length > 0) {
        res.json({
          success: true,
          data: comentario[0],
          message: 'Avaliação existente encontrada'
        });
      } else {
        res.json({
          success: false,
          message: 'Nenhuma avaliação encontrada para este utilizador neste curso'
        });
      }
      
    } catch (error) {
      console.error('❌ Erro ao verificar avaliação existente:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao verificar avaliação existente',
        message: error.message
      });
    }
  });

  // GET /comentarios/verificar-inscricao/:idcurso/:idutilizador - verificar se utilizador está inscrito no curso
  router.get('/verificar-inscricao/:idcurso/:idutilizador', async (req, res) => {
    try {
      const { idcurso, idutilizador } = req.params;
      
      console.log(`🔍 Verificando inscrição - User: ${idutilizador}, Curso: ${idcurso}`);
      
      // Verificar se o utilizador está inscrito no curso
      const inscricao = await sequelize.query(`
        SELECT fi.idinscricao, fi.estado, c.titulo
        FROM form_inscricao fi
        INNER JOIN inscricao_curso ic ON fi.idinscricao = ic.idinscricao
        INNER JOIN cursos c ON ic.idcurso = c.id
        WHERE fi.idutilizador = :idutilizador 
          AND ic.idcurso = :idcurso 
          AND fi.estado = true
      `, {
        replacements: { 
          idcurso: Number(idcurso),
          idutilizador: Number(idutilizador)
        },
        type: sequelize.QueryTypes.SELECT
      });
      
      const inscrito = inscricao.length > 0;
      
      console.log(`✅ Resultado da verificação de inscrição: ${inscrito ? 'INSCRITO' : 'NÃO INSCRITO'}`);
      if (inscrito) {
        console.log(`   Curso: ${inscricao[0].titulo}`);
      }
      
      res.json({
        success: true,
        inscrito: inscrito,
        curso_id: parseInt(idcurso),
        user_id: parseInt(idutilizador),
        data: inscrito ? {
          inscricao_id: inscricao[0].idinscricao,
          curso_titulo: inscricao[0].titulo
        } : null
      });
      
    } catch (error) {
      console.error('❌ Erro ao verificar inscrição para comentários:', error);
      res.status(500).json({
        success: false,
        inscrito: false,
        error: 'Erro ao verificar inscrição',
        message: error.message
      });
    }
  });

  // PUT /comentarios/:id - atualizar comentário existente
  router.put('/:id', async (req, res) => {
    try {
      const { id } = req.params;
      const { comentario, avaliacao } = req.body;
      
      console.log('📝 Atualizando comentário:', {
        id,
        comentario: comentario?.substring(0, 50) + '...',
        avaliacao
      });
      
      // Validações básicas
      if (!comentario) {
        return res.status(400).json({
          success: false,
          error: 'Campo obrigatório: comentario'
        });
      }
      
      if (avaliacao && (avaliacao < 0 || avaliacao > 5)) {
        return res.status(400).json({
          success: false,
          error: 'Avaliação deve estar entre 0 e 5'
        });
      }
      
      // Buscar o comentário existente para verificar se o utilizador está inscrito
      const comentarioExistente = await sequelize.query(`
        SELECT idcurso, idutilizador 
        FROM comentarios 
        WHERE id = :id
      `, {
        replacements: { id },
        type: sequelize.QueryTypes.SELECT
      });
      
      if (comentarioExistente.length === 0) {
        return res.status(404).json({
          success: false,
          error: 'Comentário não encontrado'
        });
      }
      
      const { idcurso, idutilizador } = comentarioExistente[0];
      
      // *** REMOVIDO: Verificação de inscrição para atualização de comentários ***
      // Comentário: Qualquer utilizador pode atualizar seus próprios comentários
      
      console.log('✅ Utilizador autorizado a atualizar comentário (sem verificação de inscrição)');
      
      // Atualizar o comentário
      const [result] = await sequelize.query(`
        UPDATE comentarios 
        SET comentario = :comentario, avaliacao = :avaliacao, data = NOW()
        WHERE id = :id
        RETURNING *
      `, {
        replacements: {
          id,
          comentario,
          avaliacao: avaliacao || null
        },
        type: sequelize.QueryTypes.UPDATE
      });
      
      console.log('✅ Comentário atualizado com sucesso');
      
      res.status(200).json({
        success: true,
        data: result[0],
        message: 'Comentário atualizado com sucesso'
      });
      
    } catch (error) {
      console.error('❌ Erro ao atualizar comentário:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao atualizar comentário',
        message: error.message
      });
    }
  });

  // DELETE /comentarios/:id - excluir comentário
  router.delete('/:id', async (req, res) => {
    try {
      const { id } = req.params;
      
      console.log('🗑️ Excluindo comentário:', { id });
      
      // Buscar o comentário existente para verificar permissões
      const comentarioExistente = await sequelize.query(`
        SELECT idcurso, idutilizador 
        FROM comentarios 
        WHERE id = :id
      `, {
        replacements: { id },
        type: sequelize.QueryTypes.SELECT
      });
      
      if (comentarioExistente.length === 0) {
        return res.status(404).json({
          success: false,
          error: 'Comentário não encontrado'
        });
      }
      
      const { idcurso, idutilizador } = comentarioExistente[0];
      
      // *** REMOVIDO: Verificação de inscrição para exclusão de comentários ***
      // Comentário: Qualquer utilizador pode excluir seus próprios comentários
      
      console.log('✅ Utilizador autorizado a excluir comentário (sem verificação de inscrição)');
      
      // Excluir o comentário
      const result = await sequelize.query(`
        DELETE FROM comentarios 
        WHERE id = :id
        RETURNING *
      `, {
        replacements: { id },
        type: sequelize.QueryTypes.DELETE
      });
      
      console.log('✅ Comentário excluído com sucesso');
      
      res.status(200).json({
        success: true,
        message: 'Comentário excluído com sucesso'
      });
      
    } catch (error) {
      console.error('❌ Erro ao excluir comentário:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao excluir comentário',
        message: error.message
      });
    }
  });

  // POST /comentarios/:id/denunciar - denunciar comentário
  router.post('/:id/denunciar', async (req, res) => {
    try {
      const { id } = req.params;
      const { idutilizador, motivo } = req.body;
      
      console.log('🚨 Criando denúncia de comentário:', {
        idComentario: id,
        idutilizador,
        motivo: motivo?.substring(0, 50) + '...'
      });
      
      // Validações básicas
      if (!idutilizador || !motivo) {
        return res.status(400).json({
          success: false,
          error: 'Campos obrigatórios: idutilizador, motivo'
        });
      }
      
      if (motivo.length < 10) {
        return res.status(400).json({
          success: false,
          error: 'O motivo deve ter pelo menos 10 caracteres'
        });
      }
      
      // Verificar se o comentário existe
      const comentarioExiste = await sequelize.query(`
        SELECT id, idutilizador as proprietario 
        FROM comentarios 
        WHERE id = :id
      `, {
        replacements: { id },
        type: sequelize.QueryTypes.SELECT
      });
      
      if (comentarioExiste.length === 0) {
        return res.status(404).json({
          success: false,
          error: 'Comentário não encontrado'
        });
      }
      
      // Verificar se o usuário não está denunciando seu próprio comentário
      if (comentarioExiste[0].proprietario === parseInt(idutilizador)) {
        return res.status(400).json({
          success: false,
          error: 'Não é possível denunciar seu próprio comentário'
        });
      }
      
      // Verificar se já existe uma denúncia deste usuário para este comentário
      const denunciaExistente = await sequelize.query(`
        SELECT iddenuncia 
        FROM denuncia 
        WHERE idcomentario = :idcomentario AND idutilizador = :idutilizador
      `, {
        replacements: { idcomentario: id, idutilizador },
        type: sequelize.QueryTypes.SELECT
      });
      
      if (denunciaExistente.length > 0) {
        return res.status(409).json({
          success: false,
          error: 'Você já denunciou este comentário'
        });
      }
      
      // Criar a denúncia
      const resultado = await sequelize.query(`
        INSERT INTO denuncia (idcomentario, idutilizador, motivo, data)
        VALUES (:idcomentario, :idutilizador, :motivo, NOW())
        RETURNING *
      `, {
        replacements: {
          idcomentario: id,
          idutilizador,
          motivo
        },
        type: sequelize.QueryTypes.INSERT
      });
      
      console.log('✅ Denúncia criada com sucesso');
      
      // Aqui você pode adicionar lógica para notificar administradores
      // Por exemplo, enviar email ou criar notificação no sistema
      
      res.status(201).json({
        success: true,
        data: resultado[0],
        message: 'Denúncia enviada com sucesso! Nossa equipe irá analisar.'
      });
      
    } catch (error) {
      console.error('❌ Erro ao criar denúncia:', error);
      
      // Verificar se precisa adicionar os campos na tabela denuncia
      if (error.message.includes('column "idcomentario" of relation "denuncia" does not exist') ||
          error.message.includes('column "idutilizador" of relation "denuncia" does not exist')) {
        console.log('📝 Adicionando campos necessários na tabela denuncia...');
        
        try {
          // Adicionar campo idcomentario se não existir
          await sequelize.query(`
            ALTER TABLE denuncia 
            ADD COLUMN IF NOT EXISTS idcomentario INTEGER REFERENCES comentarios(id) ON DELETE CASCADE
          `);
          
          // Adicionar campo idutilizador se não existir
          await sequelize.query(`
            ALTER TABLE denuncia 
            ADD COLUMN IF NOT EXISTS idutilizador INTEGER REFERENCES utilizador(idutilizador) ON DELETE CASCADE
          `);
          
          console.log('✅ Campos adicionados na tabela denuncia com sucesso');
          
          // Tentar novamente criar a denúncia
          const resultado = await sequelize.query(`
            INSERT INTO denuncia (idcomentario, idutilizador, motivo, data)
            VALUES (:idcomentario, :idutilizador, :motivo, NOW())
            RETURNING *
          `, {
            replacements: {
              idcomentario: req.params.id,
              idutilizador: req.body.idutilizador,
              motivo: req.body.motivo
            },
            type: sequelize.QueryTypes.INSERT
          });
          
          res.status(201).json({
            success: true,
            data: resultado[0],
            message: 'Denúncia enviada com sucesso! Nossa equipe irá analisar.'
          });
          
        } catch (createError) {
          console.error('❌ Erro ao adicionar campos:', createError);
          res.status(500).json({
            success: false,
            error: 'Erro ao processar denúncia',
            message: createError.message
          });
        }
      } else {
        res.status(500).json({
          success: false,
          error: 'Erro ao processar denúncia',
          message: error.message
        });
      }
    }
  });

  // GET /comentarios/test-denuncias - ENDPOINT TEMPORÁRIO para testar denúncias
  router.get('/test-denuncias', async (req, res) => {
    try {
      console.log('🔍 Testando acesso à tabela denuncia...');
      
      // Verificar se a tabela existe e contar registros
      const totalDenuncias = await sequelize.query(`
        SELECT COUNT(*) as total FROM denuncia
      `, {
        type: sequelize.QueryTypes.SELECT
      });
      
      // Contar denúncias de comentários especificamente
      const denunciasComentarios = await sequelize.query(`
        SELECT COUNT(*) as total FROM denuncia WHERE idcomentario IS NOT NULL
      `, {
        type: sequelize.QueryTypes.SELECT
      });
      
      // Buscar as últimas 5 denúncias
      const ultimasDenuncias = await sequelize.query(`
        SELECT 
          iddenuncia,
          idcomentario,
          idpost,
          idutilizador,
          motivo,
          data
        FROM denuncia 
        ORDER BY data DESC 
        LIMIT 5
      `, {
        type: sequelize.QueryTypes.SELECT
      });
      
      console.log(`� Total de denúncias: ${totalDenuncias[0].total}`);
      console.log(`📊 Denúncias de comentários: ${denunciasComentarios[0].total}`);
      
      res.json({
        success: true,
        data: {
          total_denuncias: totalDenuncias[0].total,
          denuncias_comentarios: denunciasComentarios[0].total,
          ultimas_denuncias: ultimasDenuncias
        },
        message: 'Acesso à tabela denuncia realizado com sucesso'
      });
      
    } catch (error) {
      console.error('❌ Erro ao acessar tabela denuncia:', error);
      
      if (error.message.includes('relation "denuncia" does not exist')) {
        res.status(404).json({
          success: false,
          error: 'Tabela denuncia não existe',
          message: 'A tabela denuncia não foi encontrada no banco de dados'
        });
      } else {
        res.status(500).json({
          success: false,
          error: 'Erro ao acessar tabela denuncia',
          message: error.message
        });
      }
    }
  });

  // GET /comentarios/admin/denuncias - Listar denúncias de comentários para administradores
  router.get('/admin/denuncias', async (req, res) => {
    try {
      console.log('🔍 Admin: Buscando denúncias de comentários...');
      
      // Buscar denúncias de comentários com informações completas
      const denuncias = await sequelize.query(`
        SELECT 
          d.iddenuncia,
          d.idcomentario,
          d.idutilizador as denunciante_id,
          d.motivo,
          d.data as data_denuncia,
          u_denunciante.nome as denunciante_nome,
          u_denunciante.email as denunciante_email,
          c.comentario,
          c.avaliacao,
          c.idutilizador as autor_comentario_id,
          u_autor.nome as autor_comentario_nome,
          c.idcurso,
          cur.titulo as curso_titulo
        FROM denuncia d
        INNER JOIN comentarios c ON d.idcomentario = c.id
        INNER JOIN utilizador u_denunciante ON d.idutilizador = u_denunciante.idutilizador
        INNER JOIN utilizador u_autor ON c.idutilizador = u_autor.idutilizador
        LEFT JOIN cursos cur ON c.idcurso = cur.id
        WHERE d.idcomentario IS NOT NULL
        ORDER BY d.data DESC
      `, {
        type: sequelize.QueryTypes.SELECT
      });
      
      console.log(`📤 Encontradas ${denuncias.length} denúncias de comentários`);
      
      res.json({
        success: true,
        data: denuncias,
        total: denuncias.length,
        message: 'Denúncias de comentários carregadas com sucesso'
      });
      
    } catch (error) {
      console.error('❌ Erro ao buscar denúncias:', error);
      
      if (error.message.includes('relation "denuncia" does not exist')) {
        res.status(404).json({
          success: false,
          error: 'Tabela denuncia não encontrada',
          message: 'A tabela denuncia ainda não foi criada no banco de dados'
        });
      } else {
        res.status(500).json({
          success: false,
          error: 'Erro ao buscar denúncias',
          message: error.message
        });
      }
    }
  });

  return router;
};
