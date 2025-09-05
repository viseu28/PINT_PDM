const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { gerarToken, verificarToken } = require('../helpers/jwt.helper');

// Usar JWT_SECRET do helper para manter consistência
const JWT_SECRET = process.env.JWT_SECRET || 'chave_secreta_segura_para_desenvolvimento';
const JWT_EXPIRES_IN = '7d';

module.exports = (db) => {
  const router = express.Router();
  const { utilizador: Utilizador, sequelize } = db;

  router.get('/', async (req, res) => {
    try {
      const utilizadores = await db.utilizador.findAll();
      res.json(utilizadores);
    } catch (err) {
      res.status(500).json({ erro: err.message });
    }
  });

  // Novo endpoint para listar formandos
  router.get('/formandos', async (req, res) => {
    try {
      const formandos = await Utilizador.findAll({
        where: {
          tipo: 'formando',
          estado: 'ativo'
        }
      });
      res.json(formandos);
    } catch (err) {
      res.status(500).json({ erro: err.message });
    }
  });

  // Endpoint para buscar utilizador por ID
  router.get('/:id', verificarToken, async (req, res) => {
    try {
      const { id } = req.params;

      if (parseInt(id) !== req.user.id) {
        return res.status(403).json({ erro: 'Acesso negado' });
      }

      const utilizador = await Utilizador.findOne({
        where: {
          idutilizador: id,
          tipo: 'formando',
          estado: 'ativo'
        }
      });

      if (!utilizador) {
        return res.status(404).json({
          erro: 'Utilizador não encontrado'
        });
      }

      res.json(utilizador);
    } catch (err) {
      console.error('Erro ao buscar utilizador:', err);
      res.status(500).json({ erro: 'Erro ao buscar utilizador' });
    }
  });

  router.post('/login', async (req, res) => {
    try {
      const { email, senha } = req.body;
      console.log(`🔍 Tentativa de login para: ${email}`);

      const utilizador = await Utilizador.findOne({
        where: {
          email: email,
          tipo: 'formando',
          estado: 'ativo'
        }
      });

      if (!utilizador) {
        console.log(`❌ Utilizador não encontrado: ${email}`);
        return res.status(401).json({
          erro: 'Credenciais inválidas ou usuário não é formando'
        });
      }

      console.log(`✅ Utilizador encontrado: ${utilizador.nome} (ID: ${utilizador.idutilizador})`);
      console.log(`🔒 Verificando password...`);

      // MELHORAMENTO DO COLEGA: Verificação com bcrypt
      const senhaCorreta = await bcrypt.compare(senha, utilizador.palavrapasse);
      console.log(`🔒 Password correta: ${senhaCorreta}`);

      if (!senhaCorreta) {
        console.log(`❌ Password incorreta para: ${email}`);
        return res.status(401).json({
          erro: 'Credenciais inválidas'
        });
      }

      // Atualizar último acesso
      await utilizador.update({
        ultimoacesso: new Date()
      });

      // Criar JWT Token usando helper para garantir consistência
      const token = gerarToken(
        {
          id: utilizador.idutilizador,
          email: utilizador.email,
          tipo: utilizador.tipo
        },
        { expiresIn: JWT_EXPIRES_IN }
      );

      // Retorna token + dados do utilizador
      const dadosCompletos = {
        token: token,
        utilizador: {
          idutilizador: utilizador.idutilizador,
          nome: utilizador.nome,
          email: utilizador.email,
          datanascimento: utilizador.datanascimento,
          morada: utilizador.morada,
          pontos: utilizador.pontos || 0,
          tipo: utilizador.tipo,
          estado: utilizador.estado,
          temquealterarpassword: utilizador.temquealterarpassword
        }
      };

      res.json(dadosCompletos);
    } catch (err) {
      console.error('Erro no login:', err);
      res.status(500).json({ erro: 'Erro ao processar login' });
    }
  });

  router.get('/verify', verificarToken, (req, res) => {
    res.json({
      valido: true,
      utilizador: req.user
    });
  });

  // Endpoint para alterar password
  router.put('/alterar-password', verificarToken, async (req, res) => {
    try {
      const { passwordAtual, novaPassword } = req.body;
      const { id } = req.user; // CORREÇÃO: usar 'id' em vez de 'idutilizador'

      console.log('🔍 Dados recebidos para alterar password:');
      console.log('📋 Body:', req.body);
      console.log('👤 User do token:', req.user);
      console.log('🆔 ID do utilizador:', id);

      if (!passwordAtual || !novaPassword) {
        return res.status(400).json({ erro: 'Password atual e nova password são obrigatórias' });
      }

      // Buscar utilizador
      const utilizador = await Utilizador.findByPk(id); // CORREÇÃO: usar 'id'
      console.log('🔍 Utilizador encontrado na BD:', utilizador ? 'SIM' : 'NÃO');
      
      if (!utilizador) {
        return res.status(404).json({ erro: 'Utilizador não encontrado' });
      }

      // Se for primeira alteração, não verificar password atual
      if (!utilizador.temquealterarpassword) {
        // Verificar password atual
        const passwordCorreta = await bcrypt.compare(passwordAtual, utilizador.palavrapasse);
        if (!passwordCorreta) {
          return res.status(400).json({ erro: 'Password atual incorreta' });
        }
      }

      // Encriptar nova password
      const saltRounds = 10;
      const novaPasswordHash = await bcrypt.hash(novaPassword, saltRounds);

      // Atualizar utilizador
      await utilizador.update({
        palavrapasse: novaPasswordHash,
        temquealterarpassword: false
      });

      res.json({ 
        sucesso: true, 
        mensagem: 'Password alterada com sucesso',
        primeiraAlteracao: utilizador.temquealterarpassword 
      });

    } catch (err) {
      console.error('Erro ao alterar password:', err);
      res.status(500).json({ erro: 'Erro interno do servidor' });
    }
  });

  return router;
};