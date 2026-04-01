const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'dev_secret_change_in_production';

// ── Middleware principal: exige token de acesso válido ───────────────────────
function authMW(req, res, next) {
  const header = req.headers['authorization'] || '';
  const token  = header.startsWith('Bearer ') ? header.slice(7) : null;

  if (!token) {
    return res.status(401).json({ error: 'Token não fornecido.' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);

    // Rejeitar tokens de refresh ou reset usados como access
    if (decoded.tipo && decoded.tipo !== 'access') {
      return res.status(401).json({ error: 'Tipo de token inválido.' });
    }

    req.usuario = decoded; // { id, email, perfil, nome, ... }
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expirado.', expired: true });
    }
    return res.status(401).json({ error: 'Token inválido.' });
  }
}

// ── Middleware de perfil: restringe a perfis específicos ─────────────────────
// Uso: router.get('/rota', authMW, requirePerfil('admin'), handler)
function requirePerfil(...perfis) {
  return (req, res, next) => {
    if (!req.usuario) {
      return res.status(401).json({ error: 'Não autenticado.' });
    }
    if (!perfis.includes(req.usuario.perfil)) {
      return res.status(403).json({
        error: `Acesso restrito. Perfil necessário: ${perfis.join(' ou ')}.`,
      });
    }
    next();
  };
}

// ── Middleware opcional: não bloqueia mas popula req.usuario se houver token ─
function authOptional(req, res, next) {
  const header = req.headers['authorization'] || '';
  const token  = header.startsWith('Bearer ') ? header.slice(7) : null;

  if (token) {
    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      if (!decoded.tipo || decoded.tipo === 'access') {
        req.usuario = decoded;
      }
    } catch (_) {
      // Token inválido/expirado — continua sem req.usuario
    }
  }
  next();
}

// ── Exports ──────────────────────────────────────────────────────────────────
// Default export = authMW (compat. com rotas legadas: const autenticar = require(...))
// Named exports  = { authMW, requirePerfil, authOptional }
module.exports          = authMW;
module.exports.authMW   = authMW;
module.exports.requirePerfil  = requirePerfil;
module.exports.authOptional   = authOptional;

// === Aliases para compatibilidade com rotas ===
module.exports.autenticar      = authMW;
module.exports.autenticarToken = authMW;
module.exports.autorizarPerfis = requirePerfil;
