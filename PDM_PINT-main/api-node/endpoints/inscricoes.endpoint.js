const express = require('express');
const router = express.Router();
const { verificarToken } = require('../helpers/jwt.helper');
const { enviarNotificacaoInscricao } = require('../helpers/notificacao.helper.js');
const { utilizador } = require('../models/utilizador');

// Função helper para formatar estado
function _formatarEstado(estado) {
  if (typeof estado === 'boolean') {
    return estado ? 'Ativo' : 'Inativo';
  }
  if (typeof estado === 'string') {
    return estado;
  }
  return 'Em curso'; // fallback
}


module.exports = (db) => {
  const { sequelize } = db;

  // POST /inscricoes - Inscrever utilizador num curso
  router.post('/', verificarToken, async (req, res) => {
    try {
      console.log('📥 Dados recebidos no body:', req.body);

      const { idcurso, objetivos } = req.body;
      const idutilizador = req.userId;

      // Validação básica dos dados
      if (!idcurso || isNaN(idcurso)) {
        return res.status(400).json({
          success: false,
          message: 'ID do curso é inválido'
        });
      }

      if (!idutilizador) {
        return res.status(401).json({
          success: false,
          message: 'Utilizador não autenticado'
        });
      }

      console.log('🔍 Verificando se usuário existe:', idutilizador);

      // 1. Verificar se o usuário existe (SEM transação primeiro)
      const usuarioExiste = await sequelize.query(`
        SELECT idutilizador FROM utilizador WHERE idutilizador = $1 LIMIT 1
      `, {
        bind: [idutilizador],
        type: sequelize.QueryTypes.SELECT
      });

      console.log('✅ Resultado da verificação de usuário:', usuarioExiste);

      if (!usuarioExiste || usuarioExiste.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Utilizador não encontrado'
        });
      }

      console.log('🔍 Verificando se curso existe:', idcurso);

      // 2. Verificar se o curso existe e está ativo (SEM transação)
      const cursoResult = await sequelize.query(`
        SELECT id, titulo, estado, vagas_inscricao, tema, data_inicio, data_fim, tipo, formador_responsavel
        FROM cursos 
        WHERE id = $1 AND estado = 'Em breve'
      `, {
        bind: [idcurso],
        type: sequelize.QueryTypes.SELECT
      });

      console.log('✅ Resultado da verificação de curso:', cursoResult);

      if (!cursoResult || cursoResult.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Curso não encontrado ou não está ativo'
        });
      }

      const curso = cursoResult[0];
      console.log('✅ Curso encontrado:', curso);

      // 3. Verificar se o usuário já esteve inscrito neste curso anteriormente (SEM transação)
      console.log('🔍 Verificando se usuário já esteve inscrito neste curso');
      const inscricaoExistente = await sequelize.query(`
        SELECT idinscricao, estado FROM form_inscricao
        WHERE idutilizador = $1 AND idcurso = $2
        LIMIT 1
      `, {
        bind: [idutilizador, idcurso],
        type: sequelize.QueryTypes.SELECT
      });

      console.log('✅ Verificação de inscrição existente:', inscricaoExistente);

      if (inscricaoExistente.length > 0) {
        return res.status(400).json({
          success: false,
          message: 'Você já participou neste curso anteriormente. Cada curso só pode ser frequentado uma vez.'
        });
      }

      // 4. Verificar vagas disponíveis APENAS para cursos síncronos (SEM transação)
      const isSincrono = curso.tipo && curso.tipo.toLowerCase() === 'síncrono';
      
      if (isSincrono) {
        console.log('📋 Verificando vagas para curso síncrono:', curso.titulo);
        
        const result = await sequelize.query(`
          SELECT COUNT(*) AS total
          FROM form_inscricao
          WHERE idcurso = $1 AND estado = true
        `, {
          bind: [idcurso],
          type: sequelize.QueryTypes.SELECT,
          plain: true
        });

        console.log('🔍 Resultado bruto:', result);
        const totalInscritos = result ? Number(result.total) : 0;
        console.log('✅ Total de inscritos:', totalInscritos);
        const vagasDisponiveis = curso.vagas_inscricao - totalInscritos;

        if (vagasDisponiveis <= 0) {
          return res.status(400).json({
            success: false,
            message: 'Não há vagas disponíveis para este curso'
          });
        }
        
        console.log(`✅ Curso síncrono com ${vagasDisponiveis} vagas disponíveis`);
      } else {
        console.log('📋 Curso assíncrono - sem verificação de vagas:', curso.titulo);
      }

      // 5. AGORA SIM iniciar transação apenas para a inserção
      console.log('� Iniciando transação para inserção...');
      const transaction = await sequelize.transaction();

      try {
        // Inserir a inscrição principal
        console.log('📝 Inserindo nova inscrição');
        const dataAtual = new Date();
        const inscricaoResult = await sequelize.query(`
          INSERT INTO form_inscricao 
          (idutilizador, objetivos, data, estado, idcurso)
          VALUES ($1, $2, $3, $4, $5)
          RETURNING idinscricao;
        `, {
          bind: [
            idutilizador,
            objetivos || 'Adquirir conhecimentos na área do curso',
            dataAtual,
            true,
            idcurso
          ],
          type: sequelize.QueryTypes.SELECT,
          transaction,
          plain: true
        });
        
        console.log('✅ Inscrição inserida:', inscricaoResult);
        const novaInscricaoId = inscricaoResult.idinscricao;

        // Buscar dados do formando
        const formandoResult = await sequelize.query(`
          SELECT idutilizador, nome, email FROM utilizador
          WHERE idutilizador = $1
          LIMIT 1
        `, {
          bind: [idutilizador],
          type: sequelize.QueryTypes.SELECT,
          transaction,
          plain: true
        });

        // Buscar dados do formador (se houver)
        let formadorResult = null;
        if (curso.formador_responsavel) {
          formadorResult = await sequelize.query(`
            SELECT idutilizador, nome, email FROM utilizador
            WHERE nome = $1
            LIMIT 1
          `, {
            bind: [curso.formador_responsavel],
            type: sequelize.QueryTypes.SELECT,
            transaction,
            plain: true
          });
        }

        await transaction.commit();
        console.log('✅ Transação commitada com sucesso!');

        // Preparar dados para a notificação
        const formando = {
          id: formandoResult.idutilizador,
          nome: formandoResult.nome,
          email: formandoResult.email
        };

        const formador = formadorResult ? {
          id: formadorResult.idutilizador,
          nome: formadorResult.nome,
          email: formadorResult.email
        } : null;

        // Enviar notificações por email
        const resultadoNotificacao = await enviarNotificacaoInscricao(
          db,
          {
            id: curso.id,
            titulo: curso.titulo,
            tema: curso.tema,
            data_inicio: curso.data_inicio,
            data_fim: curso.data_fim,
            tipo: curso.tipo,
            estado: curso.estado
          },
          formando,
          formador
        );

        console.log('📧 Resultado do envio de notificações:', resultadoNotificacao);

        // Calcular vagas disponíveis para a resposta (apenas para cursos síncronos)
        let vagasDisponiveisResposta = null;
        const isSincronoResposta = curso.tipo && curso.tipo.toLowerCase() === 'síncrono';
        
        if (isSincronoResposta) {
          const resultVagas = await sequelize.query(`
            SELECT COUNT(*) AS total
            FROM form_inscricao
            WHERE idcurso = $1 AND estado = true
          `, {
            bind: [idcurso],
            type: sequelize.QueryTypes.SELECT,
            plain: true
          });
          const totalInscritos = resultVagas ? Number(resultVagas.total) : 0;
          vagasDisponiveisResposta = curso.vagas_inscricao - totalInscritos;
        }

        res.status(201).json({
          success: true,
          message: 'Inscrição realizada com sucesso',
          data: {
            idinscricao: novaInscricaoId,
            idcurso,
            data_inscricao: dataAtual,
            estado: true,
            vagas_disponiveis: vagasDisponiveisResposta
          },
          notificacao: resultadoNotificacao.success ? 'Emails de notificação enviados' : 'Erro ao enviar emails de notificação'
        });

      } catch (transactionError) {
        console.error('❌ Erro durante a transação:', transactionError);
        await transaction.rollback();
        return res.status(500).json({
          success: false,
          message: 'Erro ao processar inscrição'
        });
      }

    } catch (error) {
      console.error('❌ Erro geral ao processar inscrição:', {
        message: error.message,
        stack: error.stack
      });

      res.status(500).json({
        success: false,
        message: 'Erro interno do servidor',
        error: error.message
      });
    }
  });



  // GET /inscricoes - Listar inscrições do utilizador
  // GET /inscricoes - Listar inscrições do utilizador
  router.get('/', verificarToken, async (req, res) => {
    try {
      const userId = req.userId;

      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'Acesso negado'
        });
      }

      console.log(`📋 Buscando inscrições do utilizador: ${userId}`);

      // Buscar inscrições com dados do curso
      const inscricoes = await sequelize.query(`
      SELECT 
        fi.idinscricao,
        fi.objetivos,
        fi.data AS data_inscricao,
        fi.estado,
        c.id AS idcurso,
        c.titulo,
        c.descricao,
        c.data_inicio,
        c.data_fim,
        c.dificuldade,
        c.pontos,
        c.tema,
        c.avaliacao,
        c.estado AS estado_curso,
        CASE 
          WHEN c.tipo = 'Síncrono' THEN true 
          ELSE false 
        END as sincrono,
        c.imgcurso
      FROM form_inscricao fi
      INNER JOIN cursos c ON fi.idcurso = c.id
      WHERE fi.idutilizador = :userId AND fi.estado = true
      ORDER BY fi.data DESC
    `, {
        replacements: { userId },
        type: sequelize.QueryTypes.SELECT
      });

      const inscricoesFormatadas = inscricoes.map(inscricao => ({
        idinscricao: inscricao.idinscricao,
        objetivos: inscricao.objetivos,
        data_inscricao: inscricao.data_inscricao,
        estado: inscricao.estado,
        curso: {
          id: inscricao.idcurso,
          titulo: inscricao.titulo,
          descricao: inscricao.descricao,
          data_inicio: inscricao.data_inicio,
          data_fim: inscricao.data_fim,
          dificuldade: inscricao.dificuldade,
          pontos: inscricao.pontos,
          tema: inscricao.tema,
          avaliacao: inscricao.avaliacao,
          estado: _formatarEstado(inscricao.estado_curso),
          sincrono: inscricao.sincrono,
          imgcurso: inscricao.imgcurso
        }
      }));

      console.log(`✅ Encontradas ${inscricoesFormatadas.length} inscrições`);

      res.json({
        success: true,
        data: inscricoesFormatadas,
        total: inscricoesFormatadas.length
      });
    } catch (error) {
      console.error('❌ Erro ao buscar inscrições:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao buscar inscrições',
        message: error.message
      });
    }
  });


  // GET /inscricoes/:userId - Listar inscrições de um utilizador específico
  router.get('/:userId', async (req, res) => {
    try {
      const { userId } = req.params;

      if (!userId) {
        return res.status(400).json({
          success: false,
          message: 'ID do utilizador é obrigatório'
        });
      }

      console.log(`📋 Buscando inscrições do utilizador: ${userId}`);

      // Buscar inscrições com dados do curso - QUERY CORRIGIDA
      const inscricoes = await sequelize.query(`
        SELECT 
          fi.idinscricao,
          fi.objetivos,
          fi.data as data_inscricao,
          fi.estado,
          c.id as idcurso,
          c.titulo,
          c.descricao,
          c.data_inicio,
          c.data_fim,
          c.dificuldade,
          c.pontos,
          c.tema,
          c.avaliacao,
          c.estado as estado_curso,
          CASE 
            WHEN c.tipo = 'Síncrono' THEN true 
            ELSE false 
          END as sincrono,
          c.imgcurso,
          c.formador_responsavel,
          c.informacoes,
          c.video,
          c.alerta_formador,
          c.aprender_no_curso,
          c.requisitos,
          c.publico_alvo,
          c.dados,
          c.idioma
        FROM form_inscricao fi
        INNER JOIN cursos c ON fi.idcurso = c.id
        WHERE fi.idutilizador = :userId AND fi.estado = true
        ORDER BY fi.data DESC
      `, {
        replacements: { userId },
        type: sequelize.QueryTypes.SELECT
      });

      const inscricoesFormatadas = inscricoes.map(inscricao => ({
        idinscricao: inscricao.idinscricao,
        idcurso: inscricao.idcurso,
        titulo: inscricao.titulo,
        descricao: inscricao.descricao,
        data_inicio: inscricao.data_inicio,
        data_fim: inscricao.data_fim,
        dificuldade: inscricao.dificuldade,
        pontos: inscricao.pontos,
        tema: inscricao.tema,
        avaliacao: inscricao.avaliacao,
        estado: _formatarEstado(inscricao.estado_curso),
        sincrono: inscricao.sincrono,
        imgcurso: inscricao.imgcurso,
        objetivos: inscricao.objetivos,
        data_inscricao: inscricao.data_inscricao,
        estado_inscricao: inscricao.estado,
        // 🎯 CAMPOS ADICIONADOS - INCLUINDO FORMADOR RESPONSÁVEL
        formador_responsavel: inscricao.formador_responsavel,
        informacoes: inscricao.informacoes,
        video: inscricao.video,
        alerta_formador: inscricao.alerta_formador,
        aprender_no_curso: inscricao.aprender_no_curso,
        requisitos: inscricao.requisitos,
        publico_alvo: inscricao.publico_alvo,
        dados: inscricao.dados,
        idioma: inscricao.idioma
      }));

      console.log(`✅ Encontradas ${inscricoesFormatadas.length} inscrições para o utilizador ${userId}`);

      // 🐛 DEBUG - Verificar se formador_responsavel está sendo retornado
      if (inscricoesFormatadas.length > 0) {
        const primeiraInscricao = inscricoesFormatadas[0];
        console.log(`🔍 DEBUG primeira inscrição:`, {
          titulo: primeiraInscricao.titulo,
          formador_responsavel: primeiraInscricao.formador_responsavel,
          campos_disponiveis: Object.keys(primeiraInscricao)
        });
      }

      res.json({
        success: true,
        data: inscricoesFormatadas,
        total: inscricoesFormatadas.length
      });

    } catch (error) {
      console.error('❌ Erro ao buscar inscrições do utilizador:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao buscar inscrições do utilizador',
        message: error.message
      });
    }
  });

  // GET /inscricoes/:userId/curso/:cursoId - Verificar se utilizador está inscrito em curso específico
  router.get('/:userId/curso/:cursoId', async (req, res) => {
    try {
      const { userId, cursoId } = req.params;

      console.log(`🔍 Verificando inscrição - User: ${userId}, Curso: ${cursoId}`);

      // Verificar se existe inscrição ativa
      const inscricao = await sequelize.query(`
        SELECT fi.idinscricao, fi.estado, c.titulo
        FROM form_inscricao fi
        INNER JOIN cursos c ON fi.idcurso = c.id  
        WHERE fi.idutilizador = :userId 
        AND fi.idcurso = :cursoId 
        AND fi.estado = true
        LIMIT 1
      `, {
        replacements: { userId, cursoId },
        type: sequelize.QueryTypes.SELECT
      });

      const inscrito = inscricao.length > 0;

      console.log(`✅ Resultado da verificação: ${inscrito ? 'INSCRITO' : 'NÃO INSCRITO'}`);
      if (inscrito) {
        console.log(`   Curso: ${inscricao[0].titulo}`);
      }

      res.json({
        success: true,
        inscrito: inscrito,
        curso_id: parseInt(cursoId),
        user_id: parseInt(userId),
        data: inscrito ? {
          inscricao_id: inscricao[0].idinscricao,
          curso_titulo: inscricao[0].titulo
        } : null
      });

    } catch (error) {
      console.error('❌ Erro ao verificar inscrição específica:', error);
      res.status(500).json({
        success: false,
        inscrito: false,
        error: 'Erro ao verificar inscrição',
        message: error.message
      });
    }
  });

  // GET /inscricoes/curso/:idCurso/formando/:userid/nota
  router.get('/curso/:idCurso/formando/:userid/nota', async (req, res) => {
    const { idCurso, userid } = req.params;

    try {
      const result = await sequelize.query(`
      SELECT nota
      FROM form_inscricao
      WHERE idcurso = :idCurso AND idutilizador = :userid
      LIMIT 1
    `, {
        replacements: { idCurso, userid },
        type: sequelize.QueryTypes.SELECT
      });

      const notaFinal = result.length > 0 ? result[0].nota : null;

      res.json({ notaFinal });
    } catch (error) {
      console.error('Erro ao buscar nota final:', error);
      res.status(500).json({ error: 'Erro ao buscar nota final' });
    }
  });


  return router;
};
