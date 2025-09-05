module.exports = (db) => {
  const router = require('express').Router();

  // GET /permissoes/:id - BUSCA APENAS NA TABELA roles_permissoes
  router.get('/:id', async (req, res) => {
    try {
      const { id } = req.params;
      
      // Buscar apenas na tabela roles_permissoes
      const rolesPermissoes = await db.roles_permissoes.findAll({
        where: { 
          idpermissao: id 
        },
        attributes: ['idrole_permissao', 'role', 'datacriacao', 'dataatualizacao']
      });

      // Simular a estrutura esperada pela função Flutter
      const permissao = {
        idpermissao: parseInt(id),
        rolesPermissoes: rolesPermissoes
      };

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
        where: { idpermissao: id },
        attributes: ['idrole_permissao', 'role', 'datacriacao', 'dataatualizacao']
      });

      res.json(roles);
    } catch (err) {
      console.error('Erro ao buscar roles da permissão:', err);
      res.status(500).json({ erro: 'Erro ao buscar roles da permissão' });
    }
  });

  return router;
};
