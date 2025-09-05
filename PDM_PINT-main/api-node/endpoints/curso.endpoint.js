const express = require('express');
const { adicionarDuracao, adicionarDuracaoLista } = require('../helpers/duracao.helper');
const { FirebasePushService } = require('../services/firebase-push.service');

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
  const router = express.Router();
  const { cursos: Curso, sequelize } = db;
  const pushService = new FirebasePushService(db);

  // ===== ENDPOINTS ESPECÍFICOS PRIMEIRO (antes do /:id) =====

  // GET /cursos/debug - verificar estrutura da tabela (apenas para debug)
  router.get('/debug', async (req, res) => {
    try {
      console.log('🔧 Verificando se sequelize está disponível...');
      console.log('Sequelize:', sequelize ? '✅ Disponível' : '❌ Não disponível');

      if (!sequelize) {
        return res.status(500).json({
          erro: 'Sequelize não está disponível',
          debug: 'Verificar configuração do banco de dados'
        });
      }

      // Executar uma query simples para ver o que existe na tabela
      const [results] = await sequelize.query('SELECT * FROM cursos LIMIT 1');

      // Verificar valores únicos de tipo
      const [tiposResults] = await sequelize.query('SELECT DISTINCT tipo FROM cursos');
      console.log('🔍 Tipos únicos na tabela:', tiposResults.map(r => r.tipo));

      if (results.length > 0) {
        console.log('🔍 Estrutura da primeira linha da tabela cursos:');
        console.log(JSON.stringify(results[0], null, 2));

        res.json({
          message: 'Primeira linha da tabela cursos',
          data: results[0],
          columns: Object.keys(results[0]),
          tipos_unicos: tiposResults.map(r => r.tipo)
        });
      } else {
        // Se não há dados, tentar obter a estrutura da tabela
        const [columns] = await sequelize.query(`
          SELECT column_name, data_type 
          FROM information_schema.columns 
          WHERE table_name = 'cursos' 
          AND table_schema = 'public'
        `);

        console.log('🔍 Colunas da tabela cursos:', columns);

        res.json({
          message: 'Tabela cursos está vazia, mas estas são as colunas',
          columns: columns,
          tipos_unicos: tiposResults.map(r => r.tipo)
        });
      }
    } catch (error) {
      console.error('❌ Erro ao verificar estrutura da tabela:', error);
      res.status(500).json({
        erro: error.message,
        details: 'Erro ao acessar tabela cursos'
      });
    }
  });

  // Express.js, por exemplo
  // app.get('/cursos/materiais_apoio', async (req, res) => {
  //   const materiais = await MateriaisApoioModel.findAll();
  //   res.json(materiais);
  // });


  // GET /cursos/test - endpoint de teste simples
  router.get('/test', async (req, res) => {
    try {
      console.log('🧪 Endpoint de teste chamado');

      const testResults = {
        timestamp: new Date().toISOString(),
        sequelize_available: !!sequelize,
        tests: []
      };

      // Teste 1: Conexão com o banco
      try {
        await sequelize.authenticate();
        testResults.tests.push({
          name: 'Database Connection',
          status: 'SUCCESS',
          message: 'Conectado à base de dados'
        });
      } catch (dbError) {
        testResults.tests.push({
          name: 'Database Connection',
          status: 'FAILED',
          message: dbError.message
        });
      }

      // Teste 2: Verificar se tabela cursos existe
      try {
        const [tableExists] = await sequelize.query(`
          SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = 'cursos'
          );
        `);

        if (tableExists[0].exists) {
          testResults.tests.push({
            name: 'Table Exists',
            status: 'SUCCESS',
            message: 'Tabela cursos existe'
          });

          // Teste 3: Contar registros
          const [count] = await sequelize.query(`SELECT COUNT(*) as total FROM cursos`);
          testResults.tests.push({
            name: 'Record Count',
            status: 'SUCCESS',
            message: `${count[0].total} registros encontrados`
          });

          // Teste 4: Cursos ativos
          const [activeCount] = await sequelize.query(`SELECT COUNT(*) as total FROM cursos WHERE estado = 'Ativo'`);
          testResults.tests.push({
            name: 'Active Courses',
            status: activeCount[0].total > 0 ? 'SUCCESS' : 'WARNING',
            message: `${activeCount[0].total} cursos ativos`
          });

        } else {
          testResults.tests.push({
            name: 'Table Exists',
            status: 'FAILED',
            message: 'Tabela cursos não existe'
          });
        }
      } catch (tableError) {
        testResults.tests.push({
          name: 'Table Check',
          status: 'FAILED',
          message: tableError.message
        });
      }

      const successCount = testResults.tests.filter(t => t.status === 'SUCCESS').length;
      const totalTests = testResults.tests.length;

      testResults.summary = {
        success_rate: `${successCount}/${totalTests}`,
        all_tests_passed: successCount === totalTests
      };

      console.log(`🧪 Teste completo: ${successCount}/${totalTests} sucessos`);
      res.json(testResults);

    } catch (error) {
      console.error('❌ Erro no endpoint de teste:', error);
      res.status(500).json({
        erro: 'Erro no endpoint de teste',
        message: error.message
      });
    }
  });

  // GET /cursos/simple - endpoint ultra simples para teste
  router.get('/simple', async (req, res) => {
    console.log('🧪 Endpoint simples chamado');

    try {
      // Teste super simples - apenas retornar dados hardcoded para teste
      const cursosSimples = [
        {
          id: 1,
          idcurso: 1,
          titulo: 'Curso de Teste',
          descricao: 'Este é um curso de teste para verificar conectividade',
          data_inicio: '2025-01-01',
          data_fim: '2025-12-31',
          dificuldade: 'Iniciante',
          pontos: 100,
          tema: 'Teste',
          categoria: 'Tecnologia',
          avaliacao: 5.0,
          tipo: 'assincrono',
          sincrono: false,
          estado: true,
          imgcurso: null,
          inscrito: false,
          progresso: 0
        }
      ];

      console.log('📤 Retornando curso de teste simples');
      res.json(cursosSimples);

    } catch (error) {
      console.error('❌ Erro no endpoint simples:', error);
      res.status(500).json({
        erro: 'Erro no endpoint simples',
        message: error.message
      });
    }
  });

  // GET /cursos/temas - buscar todos os temas disponíveis
  router.get('/temas', async (req, res) => {
    try {
      if (!sequelize) {
        return res.status(500).json({
          erro: 'Sequelize não configurado corretamente'
        });
      }

      // Buscar temas únicos de cursos válidos
      const [results] = await sequelize.query(`
        SELECT DISTINCT tema
        FROM cursos 
        WHERE tema IS NOT NULL AND tema != ''
        ORDER BY tema ASC
      `);

      // Adicionar "Todos" no início
      const temasFormatados = [
        'Todos',
        ...results.map(row => row.tema)
      ];

      console.log(`📤 API: Retornando ${temasFormatados.length} temas`);
      res.json(temasFormatados);
    } catch (error) {
      console.error('❌ Erro ao buscar temas:', error.message);
      res.status(500).json({
        erro: error.message
      });
    }
  });

  // GET /cursos/dificuldades - buscar todas as dificuldades disponíveis
  router.get('/dificuldades', async (req, res) => {
    try {
      if (!sequelize) {
        return res.status(500).json({
          erro: 'Sequelize não configurado corretamente'
        });
      }

      // Buscar dificuldades únicas de cursos válidos (não apenas "Ativo")
      const [results] = await sequelize.query(`
        SELECT DISTINCT dificuldade,
          CASE 
            WHEN dificuldade = 'Iniciante' THEN 1
            WHEN dificuldade = 'Intermédio' THEN 2
            WHEN dificuldade = 'Intermediário' THEN 2  
            WHEN dificuldade = 'Avançado' THEN 3
            ELSE 4
          END as ordem
        FROM cursos 
        WHERE dificuldade IS NOT NULL AND dificuldade != ''
        ORDER BY ordem ASC
      `);

      // Adicionar "Todas" no início
      const dificuldadesFormatadas = [
        'Todas',
        ...results.map(row => row.dificuldade)
      ];

      res.json(dificuldadesFormatadas);
    } catch (error) {
      console.error('❌ Erro ao buscar dificuldades:', error.message);
      res.status(500).json({
        erro: error.message
      });
    }
  });

  // ===== ENDPOINT PRINCIPAL (/) =====

  // GET /cursos – devolver todos os cursos
  router.get('/', async (req, res) => {
    try {
      console.log('🔍 Iniciando busca de cursos...');

      if (!sequelize) {
        console.error('❌ Sequelize não configurado');
        return res.status(500).json({
          erro: 'Sequelize não configurado corretamente'
        });
      }

      // Primeiro, verificar se a tabela cursos existe e tem dados
      console.log('🔍 Verificando estrutura da tabela cursos...');
      const [tableCheck] = await sequelize.query(`
        SELECT COUNT(*) as total FROM cursos
      `);

      const totalCursos = parseInt(tableCheck[0].total);
      console.log(`📊 Total de cursos na tabela: ${totalCursos}`);

      if (totalCursos === 0) {
        console.log('⚠️ Tabela cursos está vazia');
        return res.json([]);
      }

      // Verificar cursos ativos (agora com o valor correto)
      const [activeCheck] = await sequelize.query(`
        SELECT COUNT(*) as total FROM cursos WHERE estado = 'Ativo'
      `);

      const cursosAtivos = parseInt(activeCheck[0].total);
      console.log(`📊 Cursos ativos: ${cursosAtivos}`);

      if (cursosAtivos === 0) {
        console.log('⚠️ Nenhum curso ativo encontrado - tentando buscar todos os cursos para debug');

        // Para debug: mostrar todos os valores de estado na tabela
        const [allStates] = await sequelize.query(`
          SELECT DISTINCT estado, COUNT(*) as count 
          FROM cursos 
          GROUP BY estado
        `);

        console.log('🔍 Estados encontrados na tabela:');
        allStates.forEach(row => {
          console.log(`   - "${row.estado}": ${row.count} cursos`);
        });

        // Retornar todos os cursos independentemente do estado (para debug)
        console.log('📋 Retornando todos os cursos para debug...');
        const [allResults] = await sequelize.query(`
          SELECT 
            c.id,
            c.titulo,
            c.descricao,
            c.tema,
            c.data_inicio,
            c.data_fim,
            c.tipo,
            c.estado,
            c.imgcurso,
            c.avaliacao,
            c.dificuldade,
            c.pontos,
            c.requisitos,
            c.publico_alvo,
            c.dados,
            c.informacoes,
            c.video,
            c.alerta_formador,
            c.formador_responsavel,
            c.aprender_no_curso,
            c.idioma
          FROM cursos c
          ORDER BY c.titulo ASC
        `);

        console.log(`📊 Total de cursos encontrados: ${allResults.length}`);
        
        // Log dos estados dos cursos para debug
        allResults.forEach(curso => {
          console.log(`📚 Curso: "${curso.titulo}" - Estado: "${curso.estado}"`);
        });

        if (allResults.length > 0) {
          const cursosFormatados = allResults.map(curso => ({
            id: curso.id,
            idcurso: curso.id,  // Manter compatibilidade com Flutter
            titulo: curso.titulo || 'Sem título',
            descricao: curso.descricao || 'Sem descrição',
            data_inicio: curso.data_inicio,
            data_fim: curso.data_fim,
            dificuldade: curso.dificuldade || 'Iniciante',
            pontos: curso.pontos || 0,
            tema: curso.tema || 'Geral',
            categoria: 'Tecnologia',
            avaliacao: parseFloat(curso.avaliacao) || 0,
            tipo: curso.tipo || 'assincrono',
            sincrono: curso.tipo === 'Síncrono',
            estado: _formatarEstado(curso.estado),
            imgcurso: curso.imgcurso || null, // 🔧 CORREÇÃO: usar URL diretamente, não converter para base64
            inscrito: false,
            progresso: 0,
            // Novos campos adicionados
            formador_responsavel: curso.formador_responsavel,
            informacoes: curso.informacoes,
            video: curso.video,
            alerta_formador: curso.alerta_formador,
            aprender_no_curso: curso.aprender_no_curso,
            requisitos: curso.requisitos,
            publico_alvo: curso.publico_alvo,
            dados: curso.dados,
            idioma: curso.idioma
          }));

          // Adicionar duração calculada dinamicamente a todos os cursos
          const cursosComDuracao = adicionarDuracaoLista(cursosFormatados);

          console.log(`📤 API: Retornando ${cursosComDuracao.length} cursos (TODOS para debug) com duração calculada`);
          return res.json(cursosComDuracao);
        }

        return res.json([]);
      }

      // Buscar todos os cursos ativos com avaliação calculada dinamicamente
      const [results] = await sequelize.query(`
        SELECT 
          c.id,
          c.titulo,
          c.descricao,
          c.tema,
          c.data_inicio,
          c.data_fim,
          c.tipo,
          c.estado,
          c.imgcurso,
          COALESCE(
            (SELECT AVG(com.avaliacao) 
             FROM comentarios com 
             WHERE com.idcurso = c.id AND com.avaliacao IS NOT NULL), 
            0
          ) as avaliacao_dinamica,
          c.dificuldade,
          c.pontos,
          c.requisitos,
          c.publico_alvo,
          c.dados,
          c.informacoes,
          c.video,
          c.alerta_formador,
          c.formador_responsavel,
          c.aprender_no_curso,
          c.idioma
        FROM cursos c
        WHERE c.estado = 'Ativo'
        ORDER BY c.titulo ASC
      `);

      if (results.length > 0) {
        // Mapear os dados para o formato esperado pelo Flutter
        const cursosFormatados = results.map(curso => {
          try {
            const cursoMapeado = {
              id: curso.id,
              idcurso: curso.id,  // Manter compatibilidade com Flutter
              titulo: curso.titulo || 'Sem título',
              descricao: curso.descricao || 'Sem descrição',
              data_inicio: curso.data_inicio,
              data_fim: curso.data_fim,
              dificuldade: curso.dificuldade || 'Iniciante',
              pontos: curso.pontos || 0,
              tema: curso.tema || 'Geral',
              categoria: 'Tecnologia', // Valor padrão
              avaliacao: parseFloat(curso.avaliacao_dinamica) || 0,
              tipo: curso.tipo || 'assincrono',
              sincrono: curso.tipo === 'Síncrono',
              estado: curso.estado,
              imgcurso: curso.imgcurso || null, // 🔧 CORREÇÃO: usar URL diretamente, não converter para base64
              inscrito: false,
              progresso: 0,
              // Novos campos adicionados
              formador_responsavel: curso.formador_responsavel,
              informacoes: curso.informacoes,
              video: curso.video,
              alerta_formador: curso.alerta_formador,
              aprender_no_curso: curso.aprender_no_curso,
              requisitos: curso.requisitos,
              publico_alvo: curso.publico_alvo,
              dados: curso.dados,
              idioma: curso.idioma
            };

            return cursoMapeado;
          } catch (mapError) {
            console.error('❌ Erro ao mapear curso:', mapError);
            return null;
          }
        }).filter(curso => curso !== null);

        // Adicionar duração calculada dinamicamente a todos os cursos
        const cursosComDuracao = adicionarDuracaoLista(cursosFormatados);

        res.json(cursosComDuracao);
      } else {
        res.json([]);
      }
    } catch (error) {
      console.error('❌ Erro ao buscar cursos:', error.message);
      console.error('❌ Stack trace:', error.stack);

      res.status(500).json({
        erro: 'Erro no endpoint de cursos',
        message: error.message
      });
    }
  });

  // ===== ENDPOINTS COM PARÂMETROS (:id) POR ÚLTIMO =====

  // GET /cursos/:id – buscar curso específico por ID
  router.get('/:id', async (req, res) => {
    try {
      const { id } = req.params;
      const curso = await Curso.findByPk(id, {
        attributes: [
          'id',
          'titulo',
          'descricao',
          'tema',
          'data_inicio',
          'data_fim',
          'tipo',
          'estado',
          'imgcurso',
          'avaliacao',
          'dificuldade',
          'pontos',
          'requisitos',
          'publico_alvo',
          'dados',
          'informacoes',
          'video',
          'alerta_formador',
          'formador_responsavel',
          'aprender_no_curso',
          'idioma',
          'created_at',
          'updated_at'
        ]
      });

      if (!curso) {
        return res.status(404).json({ erro: 'Curso não encontrado' });
      }

      const cursoObj = curso.toJSON();
      cursoObj.sincrono = cursoObj.tipo === 'Síncrono';

      // Adicionar duração calculada dinamicamente
      const cursoComDuracao = adicionarDuracao(cursoObj);

      console.log(`📚 Retornando curso ${id}: ${cursoComDuracao.titulo} com duração: ${cursoComDuracao.duracao}`);
      res.json(cursoComDuracao);
    } catch (error) {
      console.error('❌ Erro ao buscar curso:', error);
      res.status(500).json({ erro: error.message });
    }
  });

  // POST /cursos – inserir novo curso
  router.post('/', async (req, res) => {
    try {
      console.log('Dados recebidos: ', req.body);

      const {
        titulo,
        descricao,
        data_inicio,
        data_fim,
        dificuldade,
        pontos,
        tema
      } = req.body;

      if (!titulo || !descricao || !data_inicio || !data_fim) {
        return res.status(400).json({
          erro: 'Campos obrigatórios em falta',
          obrigatorios: ['titulo', 'descricao', 'data_inicio', 'data_fim']
        });
      }

      const novoCurso = await Curso.create({
        titulo,
        descricao,
        data_inicio,
        data_fim,
        dificuldade: dificuldade || 'Iniciante',
        pontos: pontos || 0,
        tema: tema || 'Geral',
        tipo: 'online',
        estado: true,
        imgcurso: null,
        avaliacao: 0
      });

      console.log('Curso Inserido: ', novoCurso.toJSON());

      // NOTA: Removido notificação automática para todos os utilizadores
      // Apenas utilizadores inscritos devem receber notificações de alterações

      res.status(201).json(novoCurso);
    } catch (error) {
      console.log('Erro ao criar curso', error);
      res.status(500).json({ erro: error.message });
    }
  });

  // GET /cursos/:id/estatisticas - buscar estatísticas de um curso
  router.get('/:id/estatisticas', async (req, res) => {
    try {
      const { id } = req.params;

      console.log(`📊 Buscando estatísticas para o curso ${id}`);

      // Buscar número de inscritos
      // Buscar número de inscritos
      // Buscar número de inscritos
      const [inscritosResult] = await sequelize.query(`
  SELECT COUNT(DISTINCT fi.idutilizador) as total_inscritos
  FROM inscricao_curso ic
  INNER JOIN form_inscricao fi 
      ON ic.idinscricao = fi.idinscricao
  WHERE ic.idcurso = :idcurso 
    AND fi.estado = true
`, {
        replacements: { idcurso: id },
        type: sequelize.QueryTypes.SELECT
      });

      // Buscar estado do curso
      // Verifica se o curso está marcado como "Terminado"
      const [cursoEstado] = await sequelize.query(`
  SELECT estado FROM cursos WHERE id = :idcurso
`, {
        replacements: { idcurso: id },
        type: sequelize.QueryTypes.SELECT
      });

      const cursoTerminado = cursoEstado[0]?.estado === 'Terminado';
      const totalInscritos = parseInt(inscritosResult.total_inscritos) || 0;
      const concluidos = cursoTerminado ? totalInscritos : 0; // Se o curso terminou, todos inscritos estão "concluídos"
      
      // Calcular taxa de conclusão
      const taxaConclusao = totalInscritos > 0 ? 
        ((concluidos / totalInscritos) * 100).toFixed(1) : 0;

      // Buscar estatísticas dos comentários
      const [comentariosStats] = await sequelize.query(`
        SELECT 
          COUNT(*) as total_comentarios,
          AVG(avaliacao) as avaliacao_media,
          COUNT(CASE WHEN avaliacao IS NOT NULL THEN 1 END) as total_avaliacoes
        FROM comentarios 
        WHERE idcurso = :idcurso
      `, {
        replacements: { idcurso: id },
        type: sequelize.QueryTypes.SELECT
      });

      // Buscar data da última atualização (baseada na última modificação de comentários)
      const [ultimaAtualizacao] = await sequelize.query(`
        SELECT MAX(data) as ultima_atualizacao
        FROM comentarios 
        WHERE idcurso = :idcurso
      `, {
        replacements: { idcurso: id },
        type: sequelize.QueryTypes.SELECT
      });

      const estatisticas = {
        total_inscritos: parseInt(inscritosResult.total_inscritos) || 0,
        total_comentarios: parseInt(comentariosStats.total_comentarios) || 0,
        avaliacao_media: comentariosStats.avaliacao_media ?
          parseFloat(comentariosStats.avaliacao_media).toFixed(1) : null,
        total_avaliacoes: parseInt(comentariosStats.total_avaliacoes) || 0,
        ultima_atualizacao: ultimaAtualizacao.ultima_atualizacao || null,
        taxa_conclusao: taxaConclusao
      };

      console.log('📤 Estatísticas enviadas:', estatisticas);

      res.json({
        success: true,
        data: estatisticas
      });

    } catch (error) {
      console.error('❌ Erro ao buscar estatísticas do curso:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao buscar estatísticas',
        message: error.message
      });
    }
  });

  // GET /cursos/:id/modulos - buscar módulos/materiais de um curso
  router.get('/:id/modulos', async (req, res) => {
    try {
      const { id } = req.params;

      console.log(`📚 Buscando módulos para o curso ${id}`);

      // Buscar materiais do curso com informações do conteúdo
      const modulos = await sequelize.query(`
        SELECT 
          m.idmaterial,
          m.idconteudo,
          m.titulo as titulo_material,
          m.descricaoc as descricao_material,
          m.estado as material_ativo,
          m.tipo as tipo_material,
          c.titulo as titulo_conteudo,
          c.descricaoc as descricao_conteudo,
          c.tipo as tipo_conteudo,
          c.idutilizador as criador_conteudo
        FROM material m
        LEFT JOIN conteudo c ON m.idconteudo = c.idconteudo
        WHERE m.idcurso = :idcurso 
        AND m.estado = true
        ORDER BY m.idmaterial ASC
      `, {
        replacements: { idcurso: id },
        type: sequelize.QueryTypes.SELECT
      });

      // Verificar se modulos existe e é um array
      if (!modulos || !Array.isArray(modulos)) {
        console.log(`⚠️ Nenhum módulo encontrado para o curso ${id}`);
        return res.json({
          success: true,
          data: [],
          total: 0
        });
      }

      // Organizar módulos por tipo se necessário
      const modulosOrganizados = modulos.map((modulo, index) => ({
        id: modulo.idmaterial,
        numero: index + 1,
        titulo: modulo.titulo_material || modulo.titulo_conteudo || `Módulo ${index + 1}`,
        descricao: modulo.descricao_material || modulo.descricao_conteudo || 'Sem descrição disponível',
        tipo: modulo.tipo_material || modulo.tipo_conteudo || 'conteudo',
        ativo: modulo.material_ativo,
        conteudo: {
          id: modulo.idconteudo,
          titulo: modulo.titulo_conteudo,
          descricao: modulo.descricao_conteudo,
          tipo: modulo.tipo_conteudo,
          criador: modulo.criador_conteudo
        }
      }));

      console.log(`📤 Encontrados ${modulosOrganizados.length} módulos`);

      res.json({
        success: true,
        data: modulosOrganizados,
        total: modulosOrganizados.length
      });

    } catch (error) {
      console.error('❌ Erro ao buscar módulos do curso:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao buscar módulos',
        message: error.message
      });
    }
  });

  // GET /cursos/:id/vagas - verificar vagas disponíveis
  router.get('/:id/vagas', async (req, res) => {
    try {
      const { id } = req.params;

      console.log(`📊 Verificando vagas para o curso ${id}`);

      // Buscar dados do curso
      console.log(`🔍 TESTE: Procurando curso com id=${id}`);

      const curso = await sequelize.query(`
        SELECT id, titulo, vagas_inscricao 
        FROM cursos 
        WHERE id = :id
      `, {
        replacements: { id },
        type: sequelize.QueryTypes.SELECT
      });

      console.log(`🔍 TESTE: Resultado da query direta:`, curso);

      if (!curso || curso.length === 0) {
        console.log(`❌ Curso ${id} não encontrado`);
        return res.status(404).json({
          success: false,
          message: 'Curso não encontrado'
        });
      }

      const cursoData = curso[0]; // Pegar o primeiro resultado
      console.log(`✅ Curso encontrado: ${cursoData.titulo}`);
      console.log(`📋 Vagas configuradas: ${cursoData.vagas_inscricao}`);

      // Buscar número atual de inscritos
      const [inscritosResult] = await sequelize.query(`
        SELECT COUNT(*) as total_inscritos
        FROM inscricao_curso ic
        INNER JOIN form_inscricao fi ON ic.idinscricao = fi.idinscricao
        WHERE ic.idcurso = :idcurso AND fi.estado = true
      `, {
        replacements: { idcurso: id },
        type: sequelize.QueryTypes.SELECT
      });

      const totalInscritos = parseInt(inscritosResult.total_inscritos) || 0;
      const vagasTotais = cursoData.vagas_inscricao || 50; // Fallback para 50 se for null
      const vagasDisponiveis = Math.max(0, vagasTotais - totalInscritos);

      console.log(`📊 Cálculo de vagas:`);
      console.log(`   - Vagas totais: ${vagasTotais}`);
      console.log(`   - Inscritos atuais: ${totalInscritos}`);
      console.log(`   - Vagas disponíveis: ${vagasDisponiveis}`);

      const dadosVagas = {
        vagas_totais: vagasTotais,
        inscritos_atuais: totalInscritos,
        vagas_disponiveis: vagasDisponiveis,
        curso_lotado: vagasDisponiveis === 0
      };

      console.log('📤 Dados de vagas enviados:', dadosVagas);

      res.json({
        success: true,
        data: dadosVagas
      });

    } catch (error) {
      console.error('❌ Erro ao verificar vagas do curso:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao verificar vagas',
        message: error.message
      });
    }
  });

  // GET /cursos/:id/aulas - buscar aulas de um curso específico
  router.get('/:id/aulas', async (req, res) => {
    try {
      const { id } = req.params;

      console.log(`📚 Buscando aulas para o curso ${id}`);

      // Buscar aulas da tabela aulas relacionadas ao curso
      const results = await sequelize.query(`
        SELECT 
          a.id,
          a.titulo,
          a.descricao,
          a.duracao,
          a.video_url,
          a.curso_id,
          a.completa,
          a.created_at,
          a.updated_at
        FROM aulas a
        WHERE a.curso_id = :curso_id
        ORDER BY a.id ASC
      `, {
        replacements: { curso_id: id },
        type: sequelize.QueryTypes.SELECT
      });

      console.log(`🔍 Query SQL executada para aulas do curso ${id}`);
      console.log(`📊 Resultado direto da query aulas:`, results);

      // Garantir que results seja sempre um array
      const resultArray = Array.isArray(results) ? results : [];
      console.log(`✅ Encontradas ${resultArray.length} aulas específicas para o curso ${id}`);

      if (!resultArray || resultArray.length === 0) {
        console.log(`⚠️ Nenhuma aula encontrada na tabela 'aulas' para o curso ${id}`);

        return res.json({
          success: true,
          data: []
        });
      }

      // Formatar dados das aulas encontradas na tabela aulas
      const aulasFormatadas = resultArray.map((aula, index) => ({
        id: aula.id,
        titulo: String(aula.titulo || `Aula ${index + 1}`),
        descricao: String(aula.descricao || 'Sem descrição disponível'),
        duracao: String(aula.duracao || '20 min'),
        video_url: String(aula.video_url || ''),
        curso_id: Number(aula.curso_id),
        completa: Boolean(aula.completa || false),
        tipo: 'aula'
      }));

      console.log('📤 Aulas formatadas e enviadas');

      res.json({
        success: true,
        data: aulasFormatadas
      });

    } catch (error) {
      console.error('❌ Erro ao buscar aulas do curso:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao buscar aulas',
        message: error.message
      });
    }
  });

  // GET /cursos/:id/materiais-apoio - buscar materiais de apoio dinâmicos
  router.get('/:id/materiais-apoio', async (req, res) => {
    try {
      const { id } = req.params;

      console.log(`📖 Buscando materiais de apoio para o curso ${id}`);

      // Buscar materiais da tabela materiais_apoio relacionados ao curso
      const results = await sequelize.query(`
        SELECT 
          ma.id,
          ma.titulo,
          ma.descricao,
          ma.nome_arquivo,
          ma.caminho_arquivo,
          ma.tamanho,
          ma.tipo_mime,
          ma.curso_id,
          ma.criado_em,
          ma.atualizado_em
        FROM materiais_apoio ma
        WHERE ma.curso_id = :curso_id
        ORDER BY ma.id ASC
      `, {
        replacements: { curso_id: id },
        type: sequelize.QueryTypes.SELECT
      });

      console.log(`🔍 Query SQL executada para curso ${id}`);
      console.log(`📊 Resultado direto da query:`, results);

      // Garantir que results seja sempre um array
      const resultArray = Array.isArray(results) ? results : [];
      console.log(`✅ Encontrados ${resultArray.length} materiais específicos para o curso ${id}`);

      if (!resultArray || resultArray.length === 0) {
        console.log(`⚠️ Nenhum material encontrado na tabela 'materiais_apoio' para o curso ${id}`);

        return res.json({
          success: true,
          data: []
        });
      }

      // Formatar dados dos materiais encontrados na tabela materiais_apoio
      const materiaisFormatados = resultArray.map((material) => ({
        id: material.id,
        titulo: String(material.titulo || 'Material sem título'),
        descricao: String(material.descricao || 'Sem descrição disponível'),
        tipo_mime: String(material.tipo_mime || 'application/pdf'),
        tamanho: String(material.tamanho || '-- KB'),
        nome_arquivo: String(material.nome_arquivo || `material_${material.id}`),
        caminho_arquivo: String(material.caminho_arquivo || ''),
        curso_id: Number(material.curso_id),
        criado_em: material.criado_em ? String(material.criado_em) : null,
        atualizado_em: material.atualizado_em ? String(material.atualizado_em) : null
      }));

      console.log('📤 Materiais formatados e enviados');

      res.json({
        success: true,
        data: materiaisFormatados
      });

    } catch (error) {
      console.error('❌ Erro ao buscar materiais do curso:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao buscar materiais',
        message: error.message
      });
    }
  });

  // GET /cursos/:id/links - buscar links do curso
  router.get('/:id/links', async (req, res) => {
    try {
      const { id } = req.params;

      console.log(`🔗 Buscando links para o curso ${id}`);

      // Buscar links da tabela materiais_links relacionados ao curso
      const results = await sequelize.query(`
        SELECT 
          ml.id,
          ml.titulo,
          ml.descricao,
          ml.url,
          ml.curso_id,
          ml.aula_id,
          ml.criado_em,
          ml.atualizado_em,
          ml.estado
        FROM materiais_links ml
        WHERE ml.curso_id = :curso_id
        AND ml.estado = true
        ORDER BY ml.id ASC
      `, {
        replacements: { curso_id: id },
        type: sequelize.QueryTypes.SELECT
      });

      console.log(`🔍 Query SQL executada para curso ${id}`);
      console.log(`📊 Resultado direto da query:`, results);

      // Garantir que results seja sempre um array
      const resultArray = Array.isArray(results) ? results : [];
      console.log(`✅ Encontrados ${resultArray.length} links específicos para o curso ${id}`);

      if (!resultArray || resultArray.length === 0) {
        console.log(`⚠️ Nenhum link encontrado na tabela 'materiais_links' para o curso ${id}`);

        return res.json({
          success: true,
          data: []
        });
      }

      // Formatar dados dos links encontrados na tabela materiais_links
      const linksFormatados = resultArray.map((link) => ({
        id: link.id,
        titulo: String(link.titulo || 'Link sem título'),
        descricao: String(link.descricao || 'Sem descrição disponível'),
        url: String(link.url || ''),
        curso_id: Number(link.curso_id),
        aula_id: link.aula_id ? Number(link.aula_id) : null,
        criado_em: link.criado_em ? new Date(link.criado_em).toISOString() : null,
        atualizado_em: link.atualizado_em ? new Date(link.atualizado_em).toISOString() : null,
        estado: Boolean(link.estado)
      }));

      console.log('📤 Links formatados e enviados');

      res.json({
        success: true,
        data: linksFormatados
      });

    } catch (error) {
      console.error('❌ Erro ao buscar links do curso:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao buscar links',
        message: error.message
      });
    }
  });

  // POST /cursos/:id/links - adicionar novo link ao curso
  router.post('/:id/links', async (req, res) => {
    try {
      const { id } = req.params;
      const { titulo, descricao, url, aula_id } = req.body;

      console.log(`🔗 Adicionando novo link ao curso ${id}`);

      // Validações básicas
      if (!titulo || !url) {
        return res.status(400).json({
          success: false,
          error: 'Título e URL são obrigatórios'
        });
      }

      // Verificar se o curso existe
      const curso = await sequelize.query(`
        SELECT id, titulo FROM cursos WHERE id = :curso_id
      `, {
        replacements: { curso_id: id },
        type: sequelize.QueryTypes.SELECT
      });

      if (!curso || curso.length === 0) {
        return res.status(404).json({
          success: false,
          error: 'Curso não encontrado'
        });
      }

      // Inserir novo link
      const [result] = await sequelize.query(`
        INSERT INTO materiais_links (titulo, descricao, url, curso_id, aula_id, criado_em, atualizado_em, estado)
        VALUES (:titulo, :descricao, :url, :curso_id, :aula_id, NOW(), NOW(), true)
        RETURNING *
      `, {
        replacements: {
          titulo,
          descricao: descricao || '',
          url,
          curso_id: id,
          aula_id: aula_id || null
        },
        type: sequelize.QueryTypes.INSERT
      });

      const novoLink = result[0];
      console.log(`✅ Link adicionado com sucesso:`, novoLink);

      // 🔔 ENVIAR NOTIFICAÇÃO PUSH para inscritos no curso
      try {
        await pushService.notificarNovoLink(parseInt(id), titulo, url);
        console.log(`📱 Notificação enviada para inscritos do curso ${id}`);
      } catch (notError) {
        console.error('⚠️ Erro ao enviar notificação (link criado com sucesso):', notError);
      }

      res.status(201).json({
        success: true,
        data: {
          id: novoLink.id,
          titulo: novoLink.titulo,
          descricao: novoLink.descricao,
          url: novoLink.url,
          curso_id: novoLink.curso_id,
          aula_id: novoLink.aula_id,
          criado_em: new Date(novoLink.criado_em).toISOString(),
          atualizado_em: new Date(novoLink.atualizado_em).toISOString(),
          estado: novoLink.estado
        }
      });

    } catch (error) {
      console.error('❌ Erro ao adicionar link:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao adicionar link',
        message: error.message
      });
    }
  });

  // DELETE /cursos/:id/links/:linkId - remover link do curso
  router.delete('/:id/links/:linkId', async (req, res) => {
    try {
      const { id, linkId } = req.params;

      console.log(`🗑️ Removendo link ${linkId} do curso ${id}`);

      // Buscar o link antes de remover (para a notificação)
      const [linkExistente] = await sequelize.query(`
        SELECT * FROM materiais_links WHERE id = :link_id AND curso_id = :curso_id
      `, {
        replacements: { link_id: linkId, curso_id: id },
        type: sequelize.QueryTypes.SELECT
      });

      if (!linkExistente || linkExistente.length === 0) {
        return res.status(404).json({
          success: false,
          error: 'Link não encontrado'
        });
      }

      const tituloLink = linkExistente[0].titulo;

      // Remover o link (soft delete)
      await sequelize.query(`
        UPDATE materiais_links 
        SET estado = false, atualizado_em = NOW()
        WHERE id = :link_id AND curso_id = :curso_id
      `, {
        replacements: { link_id: linkId, curso_id: id },
        type: sequelize.QueryTypes.UPDATE
      });

      console.log(`✅ Link removido com sucesso`);

      // 🔔 ENVIAR NOTIFICAÇÃO PUSH para inscritos no curso
      try {
        await pushService.notificarLinkRemovido(parseInt(id), tituloLink);
        console.log(`📱 Notificação de remoção enviada para inscritos do curso ${id}`);
      } catch (notError) {
        console.error('⚠️ Erro ao enviar notificação (link removido com sucesso):', notError);
      }

      res.json({
        success: true,
        message: 'Link removido com sucesso'
      });

    } catch (error) {
      console.error('❌ Erro ao remover link:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao remover link',
        message: error.message
      });
    }
  });

  // GET /cursos/debug-material - verificar estrutura das tabelas aulas e materiais_apoio
  router.get('/debug-material', async (req, res) => {
    try {
      console.log('🔧 Verificando tabelas aulas e materiais_apoio...');

      const debug = {
        timestamp: new Date().toISOString(),
        tabelas: {}
      };

      // Verificar tabela aulas
      try {
        const [aulasCount] = await sequelize.query('SELECT COUNT(*) as total FROM aulas');
        const [aulasSample] = await sequelize.query('SELECT * FROM aulas LIMIT 3');

        debug.tabelas.aulas = {
          total_registros: aulasCount[0].total,
          exemplo_registros: aulasSample
        };

        if (aulasSample.length > 0) {
          debug.tabelas.aulas.colunas = Object.keys(aulasSample[0]);
        }
      } catch (error) {
        debug.tabelas.aulas = { erro: error.message };
      }

      // Verificar tabela materiais_apoio
      try {
        const [materiaisCount] = await sequelize.query('SELECT COUNT(*) as total FROM materiais_apoio');
        const [materiaisSample] = await sequelize.query('SELECT * FROM materiais_apoio LIMIT 3');

        debug.tabelas.materiais_apoio = {
          total_registros: materiaisCount[0].total,
          exemplo_registros: materiaisSample
        };

        if (materiaisSample.length > 0) {
          debug.tabelas.materiais_apoio.colunas = Object.keys(materiaisSample[0]);
        }
      } catch (error) {
        debug.tabelas.materiais_apoio = { erro: error.message };
      }

      // Verificar dados para curso 25
      try {
        const [aulasCurso25] = await sequelize.query(`
          SELECT * FROM aulas WHERE curso_id = 25
        `);

        const [materiaisCurso25] = await sequelize.query(`
          SELECT * FROM materiais_apoio WHERE curso_id = 25
        `);

        debug.curso_25 = {
          aulas: aulasCurso25,
          materiais: materiaisCurso25,
          total_aulas: aulasCurso25.length,
          total_materiais: materiaisCurso25.length
        };
      } catch (error) {
        debug.curso_25 = { erro: error.message };
      }

      // Verificar todos os cursos que têm aulas e materiais
      try {
        const [cursosComAulas] = await sequelize.query(`
          SELECT DISTINCT curso_id, COUNT(*) as total_aulas
          FROM aulas
          GROUP BY curso_id
          ORDER BY curso_id
        `);

        const [cursosComMateriais] = await sequelize.query(`
          SELECT DISTINCT curso_id, COUNT(*) as total_materiais
          FROM materiais_apoio
          GROUP BY curso_id
          ORDER BY curso_id
        `);

        debug.resumo_por_curso = {
          cursos_com_aulas: cursosComAulas,
          cursos_com_materiais: cursosComMateriais
        };
      } catch (error) {
        debug.resumo_por_curso = { erro: error.message };
      }

      console.log('📊 Debug de aulas e materiais_apoio:', JSON.stringify(debug, null, 2));
      res.json(debug);

    } catch (error) {
      console.error('❌ Erro no debug de aulas e materiais:', error);
      res.status(500).json({
        erro: error.message,
        details: 'Erro ao verificar tabelas aulas e materiais_apoio'
      });
    }
  });

  // POST /cursos/criar-dados-exemplo - inserir dados de exemplo para teste
  router.post('/criar-dados-exemplo', async (req, res) => {
    try {
      console.log('🔧 Criando dados de exemplo...');

      const resultado = {
        timestamp: new Date().toISOString(),
        operacoes: []
      };

      // Verificar se já existem dados
      const [conteudoExistente] = await sequelize.query('SELECT COUNT(*) as total FROM conteudo');
      const [materialExistente] = await sequelize.query('SELECT COUNT(*) as total FROM material');

      if (conteudoExistente[0].total > 0) {
        console.log('⚠️ Já existem dados na tabela conteudo, pulando inserção');
        resultado.operacoes.push({
          operacao: 'conteudo',
          status: 'pulado',
          motivo: `${conteudoExistente[0].total} registros já existem`
        });
      } else {
        // Inserir conteúdo de exemplo
        await sequelize.query(`
          INSERT INTO conteudo (titulo, descricaoc, tipo, estado, idutilizador) VALUES
          ('Introdução ao HTML', 'Conceitos básicos de HTML e estrutura de documentos', 'aula', true, 1),
          ('CSS Fundamentals', 'Estilização básica com CSS', 'aula', true, 1),
          ('JavaScript Basics', 'Introdução à programação em JavaScript', 'aula', true, 1),
          ('Manual HTML/CSS', 'Guia completo de HTML e CSS', 'documento', true, 1),
          ('Exercícios Práticos', 'Conjunto de exercícios para praticar', 'arquivo', true, 1),
          ('Vídeo Tutorial HTML', 'Tutorial em vídeo sobre HTML', 'video', true, 1)
        `);

        resultado.operacoes.push({
          operacao: 'conteudo',
          status: 'sucesso',
          registros_inseridos: 6
        });
      }

      if (materialExistente[0].total > 0) {
        console.log('⚠️ Já existem dados na tabela material, pulando inserção');
        resultado.operacoes.push({
          operacao: 'material',
          status: 'pulado',
          motivo: `${materialExistente[0].total} registros já existem`
        });
      } else {
        // Buscar IDs dos conteúdos inseridos
        const [conteudos] = await sequelize.query(`
          SELECT idconteudo, titulo, tipo FROM conteudo ORDER BY idconteudo ASC
        `);

        if (conteudos.length >= 6) {
          // Inserir materiais para curso 25
          await sequelize.query(`
            INSERT INTO material (idconteudo, idcurso, estado, tipo) VALUES
            (${conteudos[0].idconteudo}, 25, true, 'aula'),
            (${conteudos[1].idconteudo}, 25, true, 'aula'),
            (${conteudos[2].idconteudo}, 25, true, 'aula'),
            (${conteudos[3].idconteudo}, 25, true, 'documento'),
            (${conteudos[4].idconteudo}, 25, true, 'arquivo'),
            (${conteudos[5].idconteudo}, 25, true, 'video')
          `);

          // Inserir materiais para curso 1
          await sequelize.query(`
            INSERT INTO material (idconteudo, idcurso, estado, tipo) VALUES
            (${conteudos[0].idconteudo}, 1, true, 'aula'),
            (${conteudos[1].idconteudo}, 1, true, 'aula'),
            (${conteudos[3].idconteudo}, 1, true, 'documento'),
            (${conteudos[4].idconteudo}, 1, true, 'arquivo')
          `);

          // Inserir materiais para curso 2
          await sequelize.query(`
            INSERT INTO material (idconteudo, idcurso, estado, tipo) VALUES
            (${conteudos[0].idconteudo}, 2, true, 'aula'),
            (${conteudos[1].idconteudo}, 2, true, 'aula'),
            (${conteudos[2].idconteudo}, 2, true, 'aula'),
            (${conteudos[3].idconteudo}, 2, true, 'documento'),
            (${conteudos[4].idconteudo}, 2, true, 'arquivo'),
            (${conteudos[5].idconteudo}, 2, true, 'video')
          `);

          resultado.operacoes.push({
            operacao: 'material',
            status: 'sucesso',
            registros_inseridos: 16,
            detalhes: {
              curso_25: 6,
              curso_1: 4,
              curso_2: 6
            }
          });
        } else {
          throw new Error('Não foram encontrados conteúdos suficientes para criar materiais');
        }
      }

      // Verificar resultado final
      const [finalConteudo] = await sequelize.query('SELECT COUNT(*) as total FROM conteudo');
      const [finalMaterial] = await sequelize.query('SELECT COUNT(*) as total FROM material');

      resultado.estado_final = {
        conteudo_total: finalConteudo[0].total,
        material_total: finalMaterial[0].total
      };

      console.log('✅ Dados de exemplo criados com sucesso');
      res.json(resultado);

    } catch (error) {
      console.error('❌ Erro ao criar dados de exemplo:', error);
      res.status(500).json({
        erro: error.message,
        details: 'Erro ao inserir dados de exemplo'
      });
    }
  });

  // PUT /cursos/:id - atualizar curso com notificações automáticas
  router.put('/:id', async (req, res) => {
    try {
      const { id } = req.params;
      const {
        titulo,
        descricao,
        data_inicio,
        data_fim,
        dificuldade,
        pontos,
        tema,
        estado,
        formador,
        imgcurso,
        avaliacao
      } = req.body;

      // Buscar curso atual para comparar alterações
      const cursoAtual = await Curso.findByPk(id);
      if (!cursoAtual) {
        return res.status(404).json({ erro: 'Curso não encontrado' });
      }

      // Preparar dados para atualização
      const dadosAtualizacao = {};
      const alteracoes = [];

      // Verificar cada campo e detectar alterações
      if (titulo && titulo !== cursoAtual.titulo) {
        dadosAtualizacao.titulo = titulo;
        alteracoes.push('título');
      }

      if (descricao && descricao !== cursoAtual.descricao) {
        dadosAtualizacao.descricao = descricao;
        alteracoes.push('descrição');
      }

      if (data_inicio && data_inicio !== cursoAtual.data_inicio) {
        dadosAtualizacao.data_inicio = data_inicio;
        alteracoes.push('data de início');
      }

      if (data_fim && data_fim !== cursoAtual.data_fim) {
        dadosAtualizacao.data_fim = data_fim;
        alteracoes.push('data de fim');
      }

      if (dificuldade && dificuldade !== cursoAtual.dificuldade) {
        dadosAtualizacao.dificuldade = dificuldade;
        alteracoes.push('dificuldade');
      }

      if (pontos !== undefined && pontos !== cursoAtual.pontos) {
        dadosAtualizacao.pontos = pontos;
        alteracoes.push('pontuação');
      }

      if (tema && tema !== cursoAtual.tema) {
        dadosAtualizacao.tema = tema;
        alteracoes.push('categoria');
      }

      if (estado !== undefined && estado !== cursoAtual.estado) {
        dadosAtualizacao.estado = estado;
        alteracoes.push('estado');
      }

      if (formador && formador !== cursoAtual.formador) {
        dadosAtualizacao.formador = formador;
        alteracoes.push('formador');
      }

      if (imgcurso !== undefined) {
        dadosAtualizacao.imgcurso = imgcurso;
      }

      if (avaliacao !== undefined) {
        dadosAtualizacao.avaliacao = avaliacao;
      }

      // Se não há alterações, retornar sem fazer nada
      if (Object.keys(dadosAtualizacao).length === 0) {
        return res.json({
          mensagem: 'Nenhuma alteração detectada',
          curso: cursoAtual
        });
      }

      // Atualizar o curso
      await Curso.update(dadosAtualizacao, {
        where: { idcurso: id }
      });

      // Buscar curso atualizado
      const cursoAtualizado = await Curso.findByPk(id);

      console.log(`✅ Curso ${id} atualizado. Alterações: ${alteracoes.join(', ')}`);

      // 🔥 NOTIFICAÇÕES PUSH: Enviar notificações baseadas nas alterações
      try {
        // Notificar alteração de formador
        if (dadosAtualizacao.formador) {
          await pushService.notificarAlteracaoFormador(
            id,
            dadosAtualizacao.formador,
            cursoAtual.formador
          );
          console.log(`🔔 Notificação de alteração de formador enviada`);
        }

        // Notificar alteração de datas
        if (dadosAtualizacao.data_inicio || dadosAtualizacao.data_fim) {
          await pushService.notificarAlteracaoDatas(
            id,
            dadosAtualizacao.data_inicio || cursoAtual.data_inicio,
            dadosAtualizacao.data_fim || cursoAtual.data_fim,
            cursoAtual.data_inicio,
            cursoAtual.data_fim
          );
          console.log(`🔔 Notificação de alteração de datas enviada`);
        }

        // Notificar alteração de estado
        if (dadosAtualizacao.estado !== undefined) {
          await pushService.notificarAlteracaoEstado(
            id,
            dadosAtualizacao.estado,
            cursoAtual.estado
          );
          console.log(`🔔 Notificação de alteração de estado enviada`);
        }

        // Notificar outras alterações importantes
        if (dadosAtualizacao.dificuldade) {
          await pushService.notificarAlteracaoInformacoes(
            id,
            'dificuldade',
            `Nível alterado para: ${dadosAtualizacao.dificuldade}`
          );
        }

        if (dadosAtualizacao.tema) {
          await pushService.notificarAlteracaoInformacoes(
            id,
            'tema',
            `Categoria alterada para: ${dadosAtualizacao.tema}`
          );
        }

        if (dadosAtualizacao.titulo || dadosAtualizacao.descricao) {
          await pushService.notificarAlteracaoInformacoes(
            id,
            'descricao',
            `Informações do curso foram atualizadas`
          );
        }

      } catch (notifError) {
        console.error('⚠️ Erro ao enviar notificações de alteração:', notifError);
        // Não falhar a atualização por causa das notificações
      }

      res.json({
        mensagem: 'Curso atualizado com sucesso',
        alteracoes,
        curso: cursoAtualizado
      });

    } catch (error) {
      console.error('❌ Erro ao atualizar curso:', error);
      res.status(500).json({ erro: error.message });
    }
  });

  // POST /cursos/:id/aulas - adicionar nova aula ao curso
  router.post('/:id/aulas', async (req, res) => {
    try {
      const { id } = req.params;
      const { titulo, descricao, data, video_url, duracao, material_apoio } = req.body;

      if (!titulo || !data) {
        return res.status(400).json({
          erro: 'Título e data são obrigatórios'
        });
      }

      // Inserir nova aula usando a estrutura correta da tabela
      const [result] = await sequelize.query(`
        INSERT INTO aulas (titulo, descricao, data, video_url, duracao, curso_id, completa, material_apoio, created_at, updated_at) 
        VALUES (:titulo, :descricao, :data, :video_url, :duracao, :curso_id, false, :material_apoio, NOW(), NOW())
        RETURNING *
      `, {
        replacements: {
          titulo,
          descricao: descricao || '',
          data,
          video_url: video_url || null,
          duracao: duracao || null,
          curso_id: id,
          material_apoio: material_apoio || null
        },
        type: sequelize.QueryTypes.INSERT
      });

      console.log('✅ Aula adicionada ao curso:', result[0]);

      // 🔥 NOTIFICAÇÃO PUSH: Notificar utilizadores inscritos no curso
      try {
        await pushService.notificarNovaAula(id, titulo, data);
        console.log(`🔔 Notificação de nova aula enviada para curso ${id}`);
      } catch (notifError) {
        console.error('⚠️ Erro ao enviar notificação de nova aula:', notifError);
        // Não falhar a criação da aula por causa da notificação
      }

      res.status(201).json(result[0]);
    } catch (error) {
      console.error('❌ Erro ao adicionar aula ao curso:', error);
      res.status(500).json({ erro: error.message });
    }
  });

  // POST /cursos/:id/materiais - adicionar novo material ao curso
  router.post('/:id/materiais', async (req, res) => {
    try {
      const { id } = req.params;
      const { titulo, descricao, nome_arquivo, caminho_arquivo, tamanho, tipo_mime } = req.body;

      if (!titulo || !nome_arquivo || !caminho_arquivo) {
        return res.status(400).json({
          erro: 'Título, nome_arquivo e caminho_arquivo são obrigatórios'
        });
      }

      // Inserir novo material usando a estrutura correta da tabela
      const [result] = await sequelize.query(`
        INSERT INTO materiais_apoio (titulo, descricao, nome_arquivo, caminho_arquivo, tamanho, tipo_mime, curso_id, criado_em, atualizado_em) 
        VALUES (:titulo, :descricao, :nome_arquivo, :caminho_arquivo, :tamanho, :tipo_mime, :curso_id, NOW(), NOW())
        RETURNING *
      `, {
        replacements: {
          titulo,
          descricao: descricao || '',
          nome_arquivo,
          caminho_arquivo,
          tamanho: tamanho || 0,
          tipo_mime: tipo_mime || 'application/octet-stream',
          curso_id: id
        },
        type: sequelize.QueryTypes.INSERT
      });

      console.log('✅ Material adicionado ao curso:', result[0]);

      // 🔥 NOTIFICAÇÃO PUSH: Notificar utilizadores inscritos no curso
      try {
        const tipoMaterial = tipo_mime?.includes('video') ? 'vídeo' : 'material';
        await pushService.notificarNovoMaterial(id, tipoMaterial, titulo);
        console.log(`🔔 Notificação de novo material enviada para curso ${id}`);
      } catch (notifError) {
        console.error('⚠️ Erro ao enviar notificação de novo material:', notifError);
        // Não falhar a criação do material por causa da notificação
      }

      res.status(201).json(result[0]);
    } catch (error) {
      console.error('❌ Erro ao adicionar material ao curso:', error);
      res.status(500).json({ erro: error.message });
    }
  });

  // DELETE /cursos/:id/aulas/:aulaId - remover aula do curso
  router.delete('/:id/aulas/:aulaId', async (req, res) => {
    try {
      const { id, aulaId } = req.params;

      // Primeiro, buscar informações da aula antes de remover
      const [aulaInfo] = await sequelize.query(`
        SELECT titulo FROM aulas WHERE id = :aulaId AND curso_id = :cursoId
      `, {
        replacements: { aulaId, cursoId: id },
        type: sequelize.QueryTypes.SELECT
      });

      if (!aulaInfo || aulaInfo.length === 0) {
        return res.status(404).json({
          erro: 'Aula não encontrada'
        });
      }

      const tituloAula = aulaInfo[0].titulo;

      // Remover aula
      const [result] = await sequelize.query(`
        DELETE FROM aulas WHERE id = :aulaId AND curso_id = :cursoId
        RETURNING id
      `, {
        replacements: { aulaId, cursoId: id },
        type: sequelize.QueryTypes.DELETE
      });

      if (result.length === 0) {
        return res.status(404).json({
          erro: 'Aula não encontrada ou não pertence ao curso'
        });
      }

      console.log(`✅ Aula "${tituloAula}" removida do curso ${id}`);

      // 🔥 NOTIFICAÇÃO PUSH: Notificar utilizadores inscritos no curso
      try {
        await pushService.notificarAulaRemovida(id, tituloAula);
        console.log(`🔔 Notificação de aula removida enviada para curso ${id}`);
      } catch (notifError) {
        console.error('⚠️ Erro ao enviar notificação de aula removida:', notifError);
        // Não falhar a remoção por causa da notificação
      }

      res.json({ 
        sucesso: true, 
        mensagem: `Aula "${tituloAula}" removida com sucesso` 
      });
    } catch (error) {
      console.error('❌ Erro ao remover aula:', error);
      res.status(500).json({ erro: error.message });
    }
  });

  // DELETE /cursos/:id/materiais/:materialId - remover material do curso
  router.delete('/:id/materiais/:materialId', async (req, res) => {
    try {
      const { id, materialId } = req.params;

      // Primeiro, buscar informações do material antes de remover
      const [materialInfo] = await sequelize.query(`
        SELECT titulo, tipo_mime FROM materiais_apoio WHERE id = :materialId AND curso_id = :cursoId
      `, {
        replacements: { materialId, cursoId: id },
        type: sequelize.QueryTypes.SELECT
      });

      if (!materialInfo || materialInfo.length === 0) {
        return res.status(404).json({
          erro: 'Material não encontrado'
        });
      }

      const tituloMaterial = materialInfo[0].titulo;
      const tipoMaterial = materialInfo[0].tipo_mime?.includes('video') ? 'vídeo' : 'material';

      // Remover material
      const [result] = await sequelize.query(`
        DELETE FROM materiais_apoio WHERE id = :materialId AND curso_id = :cursoId
        RETURNING id
      `, {
        replacements: { materialId, cursoId: id },
        type: sequelize.QueryTypes.DELETE
      });

      if (result.length === 0) {
        return res.status(404).json({
          erro: 'Material não encontrado ou não pertence ao curso'
        });
      }

      console.log(`✅ Material "${tituloMaterial}" removido do curso ${id}`);

      // 🔥 NOTIFICAÇÃO PUSH: Notificar utilizadores inscritos no curso
      try {
        await pushService.notificarMaterialRemovido(id, tituloMaterial, tipoMaterial);
        console.log(`🔔 Notificação de material removido enviada para curso ${id}`);
      } catch (notifError) {
        console.error('⚠️ Erro ao enviar notificação de material removido:', notifError);
        // Não falhar a remoção por causa da notificação
      }

      res.json({ 
        sucesso: true, 
        mensagem: `${tipoMaterial} "${tituloMaterial}" removido com sucesso` 
      });
    } catch (error) {
      console.error('❌ Erro ao remover material:', error);
      res.status(500).json({ erro: error.message });
    }
  });

  // POST /cursos/criar-materiais-exemplo - inserir materiais de exemplo na tabela materiais_apoio
  router.post('/criar-materiais-exemplo', async (req, res) => {
    try {
      console.log('🔧 Criando materiais de exemplo na tabela materiais_apoio...');

      const resultado = {
        timestamp: new Date().toISOString(),
        operacoes: []
      };

      // Verificar se já existem materiais de apoio
      const [materiaisExistentes] = await sequelize.query('SELECT COUNT(*) as total FROM materiais_apoio');

      if (materiaisExistentes[0].total > 0) {
        console.log('⚠️ Já existem dados na tabela materiais_apoio, pulando inserção');
        resultado.operacoes.push({
          operacao: 'materiais_apoio',
          status: 'pulado',
          motivo: `${materiaisExistentes[0].total} registros já existem`
        });
      } else {
        // Inserir materiais de apoio de exemplo para diferentes cursos
        await sequelize.query(`
          INSERT INTO materiais_apoio (titulo, descricao, video_url, duracao, curso_id, completa, material_apoio) VALUES
          ('Manual do Curso HTML/CSS', 'Guia completo para desenvolvimento web com HTML e CSS', null, null, 25, false, 'manual_html_css.pdf'),
          ('Exercícios Práticos', 'Conjunto de exercícios para praticar HTML e CSS', null, null, 25, false, 'exercicios_praticos.zip'),
          ('Vídeo Tutorial - Introdução', 'Vídeo introdutório ao curso', 'https://example.com/video1', '15 min', 25, false, null),
          ('Recursos Complementares', 'Links e referências úteis para o curso', null, null, 25, false, 'recursos_links.txt'),
          ('Manual HTML Básico', 'Manual básico de HTML', null, null, 1, false, 'manual_html_basico.pdf'),
          ('Exercícios HTML', 'Exercícios práticos de HTML', null, null, 1, false, 'exercicios_html.zip'),
          ('Manual Front-End Avançado', 'Guia avançado de desenvolvimento front-end', null, null, 2, false, 'manual_frontend.pdf'),
          ('Projetos Exemplo', 'Projetos de exemplo para prática', null, null, 2, false, 'projetos_exemplo.zip'),
          ('Vídeo JavaScript', 'Tutorial de JavaScript', 'https://example.com/video_js', '30 min', 2, false, null)
        `);

        resultado.operacoes.push({
          operacao: 'materiais_apoio',
          status: 'sucesso',
          registros_inseridos: 9,
          detalhes: {
            curso_25: 4,
            curso_1: 2,
            curso_2: 3
          }
        });
      }

      // Verificar resultado final
      const [finalMateriais] = await sequelize.query('SELECT COUNT(*) as total FROM materiais_apoio');
      const [materiaisPorCurso] = await sequelize.query(`
        SELECT curso_id, COUNT(*) as total 
        FROM materiais_apoio 
        GROUP BY curso_id 
        ORDER BY curso_id
      `);

      resultado.estado_final = {
        materiais_total: finalMateriais[0].total,
        por_curso: materiaisPorCurso
      };

      console.log('✅ Materiais de exemplo criados com sucesso');
      res.json(resultado);

    } catch (error) {
      console.error('❌ Erro ao criar materiais de exemplo:', error);
      res.status(500).json({
        erro: error.message,
        details: 'Erro ao inserir materiais de exemplo'
      });
    }
  });

  // POST /cursos/criar-aulas-exemplo - inserir aulas de exemplo na tabela aulas
  router.post('/criar-aulas-exemplo', async (req, res) => {
    try {
      console.log('🔧 Criando aulas de exemplo na tabela aulas...');

      const resultado = {
        timestamp: new Date().toISOString(),
        operacoes: []
      };

      // Verificar se já existem aulas
      const [aulasExistentes] = await sequelize.query('SELECT COUNT(*) as total FROM aulas');

      if (aulasExistentes[0].total > 0) {
        console.log('⚠️ Já existem dados na tabela aulas, pulando inserção');
        resultado.operacoes.push({
          operacao: 'aulas',
          status: 'pulado',
          motivo: `${aulasExistentes[0].total} registros já existem`
        });
      } else {
        // Inserir aulas de exemplo para diferentes cursos
        await sequelize.query(`
          INSERT INTO aulas (titulo, descricao, duracao, curso_id, completa) VALUES
          ('Introdução ao HTML', 'Conceitos básicos de HTML e estrutura de documentos', '25 min', 25, false),
          ('Estilização com CSS', 'Aprenda a estilizar páginas web com CSS', '30 min', 25, false),
          ('JavaScript Básico', 'Introdução à programação em JavaScript', '35 min', 25, false),
          ('Responsive Design', 'Criando layouts responsivos', '28 min', 25, false),
          ('HTML Fundamentos', 'Fundamentos essenciais de HTML', '20 min', 1, false),
          ('CSS para Iniciantes', 'CSS básico para iniciantes', '25 min', 1, false),
          ('JavaScript Avançado', 'Conceitos avançados de JavaScript', '45 min', 2, false),
          ('Frameworks CSS', 'Introdução aos frameworks CSS', '40 min', 2, false),
          ('Projeto Final', 'Desenvolvimento do projeto final', '60 min', 2, false)
        `);

        resultado.operacoes.push({
          operacao: 'aulas',
          status: 'sucesso',
          registros_inseridos: 9,
          detalhes: {
            curso_25: 4,
            curso_1: 2,
            curso_2: 3
          }
        });
      }

      // Verificar resultado final
      const [finalAulas] = await sequelize.query('SELECT COUNT(*) as total FROM aulas');
      const [aulasPorCurso] = await sequelize.query(`
        SELECT curso_id, COUNT(*) as total 
        FROM aulas 
        GROUP BY curso_id 
        ORDER BY curso_id
      `);

      resultado.estado_final = {
        aulas_total: finalAulas[0].total,
        por_curso: aulasPorCurso
      };

      console.log('✅ Aulas de exemplo criadas com sucesso');
      res.json(resultado);

    } catch (error) {
      console.error('❌ Erro ao criar aulas de exemplo:', error);
      res.status(500).json({
        erro: error.message,
        details: 'Erro ao inserir aulas de exemplo'
      });
    }
  });

  // GET /cursos/materiais/:id/download - Download de material
  router.get('/materiais/:id/download', async (req, res) => {
    try {
      const { id } = req.params;

      console.log(`📥 [MATERIAL] Solicitação de download para material ID: ${id}`);

      // Buscar informações do material na base de dados
      const materialResult = await sequelize.query(`
        SELECT 
          ma.id,
          ma.titulo,
          ma.nome_arquivo,
          ma.caminho_arquivo,
          ma.tamanho,
          ma.tipo_mime
        FROM materiais_apoio ma
        WHERE ma.id = :id
        LIMIT 1
      `, {
        replacements: { id },
        type: sequelize.QueryTypes.SELECT
      });

      if (!materialResult || materialResult.length === 0) {
        console.log(`❌ [MATERIAL] Material com ID ${id} não encontrado`);
        return res.status(404).json({
          success: false,
          message: 'Material não encontrado'
        });
      }

      const material = materialResult[0];
      console.log(`📄 [MATERIAL] Material encontrado:`, {
        id: material.id,
        titulo: material.titulo,
        caminho: material.caminho_arquivo,
        nome: material.nome_arquivo
      });

      // Verificar se há caminho do arquivo
      if (!material.caminho_arquivo) {
        console.log(`❌ [MATERIAL] Caminho do arquivo não encontrado`);
        return res.status(404).json({
          success: false,
          message: 'Arquivo do material não encontrado'
        });
      }

      // Se é uma URL do Cloudinary (ou qualquer URL externa)
      if (material.caminho_arquivo.startsWith('http')) {
        console.log(`🔗 [MATERIAL] Redirecionando para Cloudinary: ${material.caminho_arquivo}`);
        
        // Definir headers para forçar download
        res.setHeader('Content-Disposition', `attachment; filename="${material.nome_arquivo}"`);
        
        // Redirecionar para a URL do Cloudinary
        return res.redirect(material.caminho_arquivo);
      }

      // Fallback para ficheiros locais (caso ainda existam alguns)
      console.log(`📁 [MATERIAL] Tentando enviar arquivo local: ${material.caminho_arquivo}`);
      const path = require('path');
      const fs = require('fs');

      // Caminho absoluto do ficheiro
      let filePath = material.caminho_arquivo;
      const uploadsBase = path.join(__dirname, '../public/uploads');
      
      // Remover barras iniciais e garantir sempre relativo a 'public/uploads'
      const relativePath = filePath.replace(/^\\+|^\/+/, '');
      filePath = path.join(uploadsBase, relativePath);
      
      console.log(`📁 [MATERIAL] Caminho absoluto: ${filePath}`);

      // Verificar se o ficheiro existe
      if (!fs.existsSync(filePath)) {
        console.log(`❌ [MATERIAL] Ficheiro local não encontrado: ${filePath}`);
        return res.status(404).json({
          success: false,
          message: 'Ficheiro não encontrado no servidor',
          filePath
        });
      }

      // Forçar headers corretos para download
      res.setHeader('Content-Type', material.tipo_mime || 'application/octet-stream');
      res.setHeader('Content-Disposition', `attachment; filename="${material.nome_arquivo}"`);
      res.setHeader('Content-Length', fs.statSync(filePath).size);

      // Stream binário seguro para ficheiros locais
      const readStream = fs.createReadStream(filePath);
      readStream.on('open', () => {
        console.log(`✅ [MATERIAL] Iniciando envio do ficheiro local: ${material.nome_arquivo}`);
        readStream.pipe(res);
      });
      readStream.on('error', (err) => {
        console.error('❌ [MATERIAL] Erro ao ler ficheiro para download:', err);
        if (!res.headersSent) {
          res.status(500).json({
            success: false,
            message: 'Erro ao ler ficheiro para download',
            error: err.message
          });
        } else {
          res.end();
        }
      });
      res.on('close', () => {
        console.log(`📦 Download finalizado ou conexão fechada para: ${material.nome_arquivo}`);
      });
    } catch (error) {
      console.error('❌ Erro ao processar download do material:', error);
      if (!res.headersSent) {
        res.status(500).json({
          success: false,
          error: 'Erro ao processar download',
          message: error.message
        });
      } else {
        res.end();
      }
    }
  });

  return router;
};