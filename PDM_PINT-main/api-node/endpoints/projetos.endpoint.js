const express = require('express');
const router = express.Router();
const upload = require('../config/upload');

module.exports = (db) => {
  // Confirma que os models existem
  if (!db || !db.projetos || !db.projetos_submissoes) {
    throw new Error('Models não encontrados em "db". Verifique a importação dos models.');
  }

  const Projetos = db.projetos;
  const Submissoes = db.projetos_submissoes;

  // GET /projetos
  router.get('/', async (req, res) => {
    try {
      const projetos = await Projetos.findAll({
        attributes: [
          'id_projeto',
          'id_utilizador',
          'id_curso',
          'nome_projeto',
          'descricao',
          'ficheiro_url',
          'data_submissao',
          'ficheiro_nome_original'
        ]
      });
      res.json(projetos);
    } catch (error) {
      console.error('Erro ao buscar projetos:', error);
      res.status(500).json({ erro: 'Erro ao buscar projetos' });
    }
  });

  // GET /projetos/submissoes
  router.get('/submissoes', async (req, res) => {
    try {
      const submissoes = await Submissoes.findAll({
        attributes: [
          'id_submissao',
          'id_projeto',
          'id_utilizador',
          'ficheiro_url',
          'ficheiro_nome_original',
          'data_submissao'
        ]
      });
      res.json(submissoes);
    } catch (error) {
      console.error('Erro ao buscar submissões:', error);
      res.status(500).json({ erro: 'Erro ao buscar submissões' });
    }
  });

  // GET /projetos/:id/submissoes
  router.get('/:id/submissoes', async (req, res) => {
    const { id } = req.params;
    try {
      const submissoes = await Submissoes.findAll({
        attributes: [
          'id_submissao',
          'id_projeto',
          'id_utilizador',
          'ficheiro_url',
          'ficheiro_nome_original',
          'data_submissao'
        ],
        where: { id_projeto: id }
      });
      res.json(submissoes);
    } catch (error) {
      console.error('Erro ao buscar submissões do projeto:', error);
      res.status(500).json({ erro: 'Erro ao buscar submissões' });
    }
  });

  // GET /projetos/curso/:idCurso/formando/:idFormando

router.get('/curso/:idCurso/formando/:userid', async (req, res) => {
  const { idCurso, userid } = req.params;

  try {
    const projetos = await db.projetos.findAll({
      where: { id_curso: idCurso },
      include: [
        {
          model: db.projetos_submissoes,
          required: false,
          where: { id_utilizador: userid },
          as: 'submissoes'
        }
      ],
      attributes: [ // Inclua todos os atributos necessários
        'id_projeto',
        'id_utilizador', 
        'id_curso',
        'nome_projeto',
        'descricao',
        'ficheiro_url',
        'ficheiro_nome_original',
        'data_submissao'
      ]
    });

    const result = projetos.map(p => ({
      id_projeto: p.id_projeto,
      id_utilizador: p.id_utilizador,
      id_curso: p.id_curso,
      nome_projeto: p.nome_projeto,
      descricao: p.descricao,
      ficheiro_url: p.ficheiro_url,
      ficheiro_nome_original: p.ficheiro_nome_original,
      data_submissao: p.data_submissao,
      entregue: p.submissoes.length > 0
    }));

    res.json(result);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Erro ao buscar projetos' });
  }
});


// Endpoint para upload
router.post('/:idProjeto/submeter', upload.single('arquivo'), async (req, res) => {
  try {
    const { idProjeto } = req.params;
    const { iduser } = req.body;

    // Validações
    if (!iduser) {
      return res.status(400).json({ error: 'ID do usuário é obrigatório' });
    }

    if (!req.file) {
      return res.status(400).json({ error: 'Nenhum arquivo enviado. Use o campo "arquivo"' });
    }

    // Verifica se o upload foi bem-sucedido no Cloudinary
    if (!req.file.path || !req.file.originalname) {
      throw new Error('Falha no upload para o Cloudinary');
    }

    // Cria a submissão no banco de dados
    const submissao = await db.projetos_submissoes.create({
      id_projeto: idProjeto,
      id_utilizador: iduser,
      ficheiro_url: req.file.secure_url || req.file.path, // Usa secure_url se disponível
      ficheiro_nome_original: req.file.originalname,
      data_submissao: new Date()
    });

    // Resposta padronizada
    res.status(201).json({
      success: true,
      data: {
        id_submissao: submissao.id_submissao,
        ficheiro_url: submissao.ficheiro_url,
        nome_original: submissao.ficheiro_nome_original,
        data_submissao: submissao.data_submissao
      }
    });

  } catch (error) {
    console.error("Erro no upload:", error);
    res.status(500).json({ 
      success: false,
      error: 'Erro no upload do arquivo',
      details: process.env.NODE_ENV === 'development' ? error.message : null
    });
  }
});

  // GET /projetos/download/:id - Download de enunciado de projeto
  router.get('/download/:id', async (req, res) => {
    const { id } = req.params;
    
    try {
      console.log(`🔍 [ENUNCIADO] Buscando projeto com ID: ${id}`);
      
      // Buscar o projeto na base de dados
      const projeto = await Projetos.findOne({
        where: { id_projeto: id },
        attributes: [
          'id_projeto',
          'nome_projeto',
          'ficheiro_url',
          'ficheiro_nome_original'
        ]
      });

      if (!projeto) {
        console.log(`❌ [ENUNCIADO] Projeto não encontrado: ${id}`);
        return res.status(404).json({ 
          success: false,
          error: 'Projeto não encontrado' 
        });
      }

      console.log(`✅ [ENUNCIADO] Projeto encontrado:`, {
        id: projeto.id_projeto,
        nome: projeto.nome_projeto,
        url: projeto.ficheiro_url,
        nome_original: projeto.ficheiro_nome_original
      });

      // Verificar se há ficheiro de enunciado
      if (!projeto.ficheiro_url) {
        console.log(`❌ [ENUNCIADO] Ficheiro de enunciado não encontrado`);
        return res.status(404).json({ 
          success: false,
          error: 'Enunciado do projeto não encontrado' 
        });
      }

      // Se é uma URL do Cloudinary (ou qualquer URL externa)
      if (projeto.ficheiro_url.startsWith('http')) {
        console.log(`🔗 [ENUNCIADO] Redirecionando para Cloudinary: ${projeto.ficheiro_url}`);
        
        // Definir headers para forçar download
        res.setHeader('Content-Disposition', `attachment; filename="${projeto.ficheiro_nome_original || projeto.nome_projeto}"`);
        
        // Redirecionar para a URL do Cloudinary
        return res.redirect(projeto.ficheiro_url);
      }

      // Fallback para ficheiros locais (caso ainda existam alguns)
      console.log(`📁 [ENUNCIADO] Tentando enviar arquivo local: ${projeto.ficheiro_url}`);
      const path = require('path');
      const fs = require('fs');
      
      const filePath = path.join(__dirname, '..', 'public', 'uploads', projeto.ficheiro_url);
      
      if (!fs.existsSync(filePath)) {
        console.log(`❌ [ENUNCIADO] Arquivo local não encontrado: ${filePath}`);
        return res.status(404).json({ 
          success: false,
          error: 'Arquivo do enunciado não encontrado no servidor' 
        });
      }

      // Definir headers para download
      res.setHeader('Content-Disposition', `attachment; filename="${projeto.ficheiro_nome_original || projeto.nome_projeto}"`);
      res.setHeader('Content-Type', 'application/octet-stream');
      
      // Enviar o arquivo local
      res.sendFile(filePath);

    } catch (error) {
      console.error('❌ [ENUNCIADO] Erro ao fazer download do enunciado:', error);
      res.status(500).json({ 
        success: false,
        error: 'Erro interno do servidor',
        details: process.env.NODE_ENV === 'development' ? error.message : null
      });
    }
  });

  // GET /projetos/submissao/download/:id - Download de submissão específica
  router.get('/submissao/download/:id', async (req, res) => {
    const { id } = req.params;
    
    try {
      console.log(`🔍 [DOWNLOAD] Buscando submissão com ID: ${id}`);
      
      // Buscar a submissão na base de dados
      const submissao = await Submissoes.findOne({
        where: { id_submissao: id },
        attributes: [
          'id_submissao',
          'ficheiro_url',
          'ficheiro_nome_original',
          'data_submissao'
        ]
      });

      if (!submissao) {
        console.log(`❌ [DOWNLOAD] Submissão não encontrada: ${id}`);
        return res.status(404).json({ 
          success: false,
          error: 'Submissão não encontrada' 
        });
      }

      console.log(`✅ [DOWNLOAD] Submissão encontrada:`, {
        id: submissao.id_submissao,
        url: submissao.ficheiro_url,
        nome: submissao.ficheiro_nome_original
      });

      // Como estás a usar Cloudinary, o ficheiro_url deve ser uma URL completa
      if (!submissao.ficheiro_url) {
        console.log(`❌ [DOWNLOAD] URL do ficheiro não encontrada`);
        return res.status(404).json({ 
          success: false,
          error: 'URL do arquivo não encontrada' 
        });
      }

      // Se é uma URL do Cloudinary (ou qualquer URL externa)
      if (submissao.ficheiro_url.startsWith('http')) {
        console.log(`🔗 [DOWNLOAD] Redirecionando para Cloudinary: ${submissao.ficheiro_url}`);
        
        // Definir headers para forçar download
        res.setHeader('Content-Disposition', `attachment; filename="${submissao.ficheiro_nome_original}"`);
        
        // Redirecionar para a URL do Cloudinary
        return res.redirect(submissao.ficheiro_url);
      }

      // Fallback para ficheiros locais (caso ainda existam alguns)
      console.log(`📁 [DOWNLOAD] Tentando enviar arquivo local: ${submissao.ficheiro_url}`);
      const path = require('path');
      const fs = require('fs');
      
      const filePath = path.join(__dirname, '..', 'uploads', submissao.ficheiro_url);
      
      if (!fs.existsSync(filePath)) {
        console.log(`❌ [DOWNLOAD] Arquivo local não encontrado: ${filePath}`);
        return res.status(404).json({ 
          success: false,
          error: 'Arquivo não encontrado no servidor' 
        });
      }

      // Definir headers para download
      res.setHeader('Content-Disposition', `attachment; filename="${submissao.ficheiro_nome_original}"`);
      res.setHeader('Content-Type', 'application/octet-stream');
      
      // Enviar o arquivo local
      res.sendFile(filePath);

    } catch (error) {
      console.error('❌ [DOWNLOAD] Erro ao fazer download da submissão:', error);
      res.status(500).json({ 
        success: false,
        error: 'Erro interno do servidor',
        details: process.env.NODE_ENV === 'development' ? error.message : null
      });
    }
  });

  return router;
};


