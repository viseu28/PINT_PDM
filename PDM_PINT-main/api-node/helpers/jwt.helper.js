const jwt = require('jsonwebtoken');

// Chave secreta para JWT (em produção deve ser uma variável de ambiente)
const JWT_SECRET = process.env.JWT_SECRET || 'chave_secreta_segura_para_desenvolvimento';

// Middleware para verificar token JWT
const verificarToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ 
      success: false, 
      message: 'Token de acesso requerido' 
    });
  }

  try {
    // Verificar e decodificar o token
    const decoded = jwt.verify(token, JWT_SECRET);
    req.userId = decoded.id; // Usar 'id' em vez de 'userId'
    req.user = decoded;
    next();
  } catch (error) {
    console.error('❌ Erro ao verificar token:', error.message);
    return res.status(403).json({ 
      success: false, 
      message: 'Token inválido ou expirado' 
    });
  }
};

// Função para gerar token JWT
const gerarToken = (payload, options = {}) => {
  const defaultOptions = {
    expiresIn: '24h' // Token expira em 24 horas
  };
  
  return jwt.sign(payload, JWT_SECRET, { ...defaultOptions, ...options });
};

// Função para decodificar token sem verificar (útil para debug)
const decodificarToken = (token) => {
  try {
    return jwt.decode(token);
  } catch (error) {
    return null;
  }
};

module.exports = {
  verificarToken,
  gerarToken,
  decodificarToken,
  JWT_SECRET
};
