const router    = require('express').Router();
const bcrypt    = require('bcrypt');
const jwt       = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const pool      = require('../config/database');
const authMW    = require('../middleware/auth');

// ── Helpers ───────────────────────────────────────────────────────────────────
const JWT_SECRET      = process.env.JWT_SECRET;
const JWT_EXPIRES_IN  = process.env.JWT_EXPIRES_IN  || '8h';
const JWT_REFRESH_EXP = process.env.JWT_REFRESH_EXP || '7d';
const SALT_ROUNDS     = 12;

function gerarTokens(payload) {
  const access  = jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
  const refresh = jwt.sign({ id: payload.id }, JWT_SECRET, { expiresIn: JWT_REFRESH_EXP });
  return { access, refresh };
}

function handleValidation(req, res) {
  const erros = validationResult(req);
  if (!erros.isEmpty()) {
    res.status(422).json({ error: 'Dados inválidos.', detalhes: erros.array() });
    return false;
  }
  return true;
}

// ── POST /api/auth/login ──────────────────────────────────────────────────────
router.post('/login',
  body('email').isEmail().normalizeEmail().withMessage('E-mail inválido.'),
  body('senha').notEmpty().withMessage('Senha obrigatória.'),
  async (req, res) => {
    if (!handleValidation(req, res)) return;
    const { email, senha } = req.body;
    try {
      const result = await pool.query(
        `SELECT u.id, u.nome, u.email, u.senha_hash, u.ativo, u.perfil,
                u.primeiro_acesso, u.ultimo_acesso
           FROM usuarios u
          WHERE u.email = $1`,
        [email]
      );
      const user = result.rows[0];
      if (!user) {
        return res.status(401).json({ error: 'E-mail ou senha incorretos.' });
      }
      if (!user.ativo) {
        return res.status(403).json({ error: 'Usuário inativo. Contate o administrador.' });
      }
      const senhaOk = await bcrypt.compare(senha, user.senha_hash);
      if (!senhaOk) {
        return res.status(401).json({ error: 'E-mail ou senha incorretos.' });
      }
      // Atualizar último acesso
      await pool.query(
        'UPDATE usuarios SET ultimo_acesso = NOW() WHERE id = $1',
        [user.id]
      );
      const payload = {
        id:     user.id,
        nome:   user.nome,
        email:  user.email,
        perfil: user.perfil,
      };
      const { access, refresh } = gerarTokens(payload);
      return res.json({
        token:         access,
        refresh_token: refresh,
        usuario: {
          id:              user.id,
          nome:            user.nome,
          email:           user.email,
          perfil:          user.perfil,
          primeiro_acesso: user.primeiro_acesso,
        },
      });
    } catch (err) {
      console.error('[auth/login]', err.message);
      return res.status(500).json({ error: 'Erro interno ao fazer login.' });
    }
  }
);

// ── POST /api/auth/refresh ────────────────────────────────────────────────────
router.post('/refresh',
  body('refresh_token').notEmpty().withMessage('refresh_token obrigatório.'),
  async (req, res) => {
    if (!handleValidation(req, res)) return;
    const { refresh_token } = req.body;
    try {
      const decoded = jwt.verify(refresh_token, JWT_SECRET);
      const result = await pool.query(
        'SELECT id, nome, email, perfil, ativo FROM usuarios WHERE id = $1',
        [decoded.id]
      );
      const user = result.rows[0];
      if (!user || !user.ativo) {
        return res.status(401).json({ error: 'Sessão inválida.' });
      }
      const payload = { id: user.id, nome: user.nome, email: user.email, perfil: user.perfil };
      const { access, refresh } = gerarTokens(payload);
      return res.json({ token: access, refresh_token: refresh });
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        return res.status(401).json({ error: 'Sessão expirada. Faça login novamente.' });
      }
      return res.status(401).json({ error: 'Token inválido.' });
    }
  }
);

// ── GET /api/auth/me ──────────────────────────────────────────────────────────
router.get('/me', authMW, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, nome, email, perfil, ativo, primeiro_acesso, ultimo_acesso,
              created_at
         FROM usuarios
        WHERE id = $1`,
      [req.usuario.id]
    );
    const user = result.rows[0];
    if (!user) return res.status(404).json({ error: 'Usuário não encontrado.' });
    return res.json(user);
  } catch (err) {
    console.error('[auth/me]', err.message);
    return res.status(500).json({ error: 'Erro interno.' });
  }
});

// ── POST /api/auth/logout ─────────────────────────────────────────────────────
// Stateless: apenas sinaliza ao cliente para descartar o token.
// Para blacklist real, seria necessário Redis ou tabela de tokens revogados.
router.post('/logout', authMW, (_req, res) => {
  return res.json({ message: 'Logout realizado com sucesso.' });
});

// ── POST /api/auth/trocar-senha ───────────────────────────────────────────────
router.post('/trocar-senha', authMW,
  body('senha_atual').notEmpty().withMessage('Senha atual obrigatória.'),
  body('nova_senha').isLength({ min: 8 }).withMessage('Nova senha deve ter ao menos 8 caracteres.'),
  body('confirmar_senha').custom((val, { req: r }) => {
    if (val !== r.body.nova_senha) throw new Error('As senhas não conferem.');
    return true;
  }),
  async (req, res) => {
    if (!handleValidation(req, res)) return;
    const { senha_atual, nova_senha } = req.body;
    try {
      const result = await pool.query(
        'SELECT senha_hash FROM usuarios WHERE id = $1',
        [req.usuario.id]
      );
      const user = result.rows[0];
      if (!user) return res.status(404).json({ error: 'Usuário não encontrado.' });
      const senhaOk = await bcrypt.compare(senha_atual, user.senha_hash);
      if (!senhaOk) {
        return res.status(400).json({ error: 'Senha atual incorreta.' });
      }
      const novoHash = await bcrypt.hash(nova_senha, SALT_ROUNDS);
      await pool.query(
        `UPDATE usuarios
            SET senha_hash = $1, primeiro_acesso = false, updated_at = NOW()
          WHERE id = $2`,
        [novoHash, req.usuario.id]
      );
      return res.json({ message: 'Senha alterada com sucesso.' });
    } catch (err) {
      console.error('[auth/trocar-senha]', err.message);
      return res.status(500).json({ error: 'Erro interno ao trocar senha.' });
    }
  }
);

// ── POST /api/auth/esqueci-senha ──────────────────────────────────────────────
// Gera um token temporário de reset (em produção, enviaria por e-mail).
router.post('/esqueci-senha',
  body('email').isEmail().normalizeEmail().withMessage('E-mail inválido.'),
  async (req, res) => {
    if (!handleValidation(req, res)) return;
    const { email } = req.body;
    try {
      const result = await pool.query(
        'SELECT id FROM usuarios WHERE email = $1 AND ativo = true',
        [email]
      );
      // Sempre retornar 200 para não revelar se o e-mail existe
      if (!result.rows[0]) {
        return res.json({ message: 'Se o e-mail existir, você receberá as instruções.' });
      }
      const userId = result.rows[0].id;
      // Token de reset válido por 1 hora
      const resetToken = jwt.sign({ id: userId, tipo: 'reset' }, JWT_SECRET, { expiresIn: '1h' });
      // Salvar token hash no banco (para invalidar após uso)
      const tokenHash = await bcrypt.hash(resetToken, 8);
      await pool.query(
        `UPDATE usuarios
            SET reset_token_hash = $1, reset_token_exp = NOW() + INTERVAL '1 hour'
          WHERE id = $2`,
        [tokenHash, userId]
      );
      // TODO: Enviar por e-mail em produção
      // Em dev, retornar o token diretamente para facilitar testes
      const payload = { message: 'Se o e-mail existir, você receberá as instruções.' };
      if (process.env.NODE_ENV !== 'production') {
        payload.debug_token = resetToken;
      }
      return res.json(payload);
    } catch (err) {
      console.error('[auth/esqueci-senha]', err.message);
      return res.status(500).json({ error: 'Erro interno.' });
    }
  }
);

// ── POST /api/auth/redefinir-senha ────────────────────────────────────────────
router.post('/redefinir-senha',
  body('token').notEmpty().withMessage('Token obrigatório.'),
  body('nova_senha').isLength({ min: 8 }).withMessage('Nova senha deve ter ao menos 8 caracteres.'),
  async (req, res) => {
    if (!handleValidation(req, res)) return;
    const { token, nova_senha } = req.body;
    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      if (decoded.tipo !== 'reset') {
        return res.status(400).json({ error: 'Token inválido.' });
      }
      const result = await pool.query(
        `SELECT id, reset_token_hash, reset_token_exp
           FROM usuarios
          WHERE id = $1 AND reset_token_exp > NOW()`,
        [decoded.id]
      );
      const user = result.rows[0];
      if (!user || !user.reset_token_hash) {
        return res.status(400).json({ error: 'Token inválido ou expirado.' });
      }
      const tokenOk = await bcrypt.compare(token, user.reset_token_hash);
      if (!tokenOk) {
        return res.status(400).json({ error: 'Token inválido.' });
      }
      const novoHash = await bcrypt.hash(nova_senha, SALT_ROUNDS);
      await pool.query(
        `UPDATE usuarios
            SET senha_hash = $1, reset_token_hash = NULL, reset_token_exp = NULL,
                primeiro_acesso = false, updated_at = NOW()
          WHERE id = $2`,
        [novoHash, decoded.id]
      );
      return res.json({ message: 'Senha redefinida com sucesso. Faça login.' });
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        return res.status(400).json({ error: 'Token expirado. Solicite um novo.' });
      }
      console.error('[auth/redefinir-senha]', err.message);
      return res.status(500).json({ error: 'Erro interno.' });
    }
  }
);

module.exports = router;
