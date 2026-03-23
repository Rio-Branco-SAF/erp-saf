const jwt = require('jsonwebtoken');
require('dotenv').config();

// ============================================================
// Middleware de autenticação JWT
// Verifica se o token é válido antes de acessar qualquer rota protegida
// ============================================================
function autenticar(req, res, next) {
  const authHeader = req.headers['authorization'];

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ erro: 'Token de autenticação não fornecido.' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.usuario = payload; // { id, email, perfil, funcionario_id }
    next();
  } catch (err) {
    return res.status(401).json({ erro: 'Token inválido ou expirado. Faça login novamente.' });
  }
}

// ============================================================
// Middleware de autorização por perfil
// Uso: autorizarPerfis('admin', 'rh')
// ============================================================
function autorizarPerfis(...perfisPermitidos) {
  return (req, res, next) => {
    if (!req.usuario) {
      return res.status(401).json({ erro: 'Não autenticado.' });
    }
    if (!perfisPermitidos.includes(req.usuario.perfil)) {
      return res.status(403).json({
        erro: `Acesso negado. Perfil necessário: ${perfisPermitidos.join(' ou ')}.`
      });
    }
    next();
  };
}

module.exports = { autenticar, autorizarPerfis };
