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





  return router;
};


