module.exports = (db) => {
  const router = require('express').Router();

  // GET /permissoes/:id
  router.get('/:id', async (req, res) => {
    try {
      const { id } = req.params;
      const permissao = await db.permissoes.findByPk(id, {
        attributes: ['id', 'nome', 'descricao', 'categoria', 'ativo', 'ligado'],
        include: [
          {
            model: db.roles_permissoes,
            as: 'rolesPermissoes',
            attributes: ['id', 'id_role', 'datacriacao', 'dataatualizacao']
          }
        ]
      });

      if (!permissao) {
        return res.status(404).json({ erro: 'Permissão não encontrada' });
      }

      res.json(permissao);
    } catch (err) {
      console.error('Erro ao buscar permissão:', err);
      res.status(500).json({ erro: 'Erro ao buscar permissão' });
    }
  });

  // GET /permissoes/:id/roles  -> só os roles dessa permissão
  router.get('/:id/roles', async (req, res) => {
    try {
      const { id } = req.params;
      const roles = await db.roles_permissoes.findAll({
        where: { id_permissao: id },
        attributes: ['id', 'id_role', 'datacriacao', 'dataatualizacao']
      });

      res.json(roles);
    } catch (err) {
      console.error('Erro ao buscar roles da permissão:', err);
      res.status(500).json({ erro: 'Erro ao buscar roles da permissão' });
    }
  });

  return router;
};
