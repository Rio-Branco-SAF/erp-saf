const express  = require('express');
const bcrypt   = require('bcrypt');
const jwt      = require('jsonwebtoken');
const pool     = require('../config/database');
const { autenticar } = require('../middleware/auth');
require('dotenv').config();

const router = express.Router();

// ============================================================
// POST /api/auth/login
// ============================================================
router.post('/login', async (req, res) => {
  const { email, senha } = req.body;

  if (!email || !senha) {
    return res.status(400).json({ erro: 'E-mail e senha são obrigatórios.' });
  }

  try {
    const resultado = await pool.query(
      `SELECT u.id, u.email, u.senha_hash, u.perfil, u.ativo,
              f.nome_completo, f.cargo, f.departamento_id, f.id AS funcionario_id
       FROM usuarios u
       LEFT JOIN funcionarios f ON f.id = u.funcionario_id
       WHERE u.email = $1`,
      [email.toLowerCase().trim()]
    );

    if (resultado.rows.length === 0) {
      return res.status(401).json({ erro: 'E-mail ou senha incorretos.' });
    }

    const usuario = resultado.rows[0];

    if (!usuario.ativo) {
      return res.status(403).json({ erro: 'Usuário inativo. Contate o administrador.' });
    }

    const senhaCorreta = await bcrypt.compare(senha, usuario.senha_hash);
    if (!senhaCorreta) {
      return res.status(401).json({ erro: 'E-mail ou senha incorretos.' });
    }

    // Atualiza último acesso
    await pool.query('UPDATE usuarios SET ultimo_acesso = NOW() WHERE id = $1', [usuario.id]);

    const token = jwt.sign(
      {
        id:             usuario.id,
        email:          usuario.email,
        perfil:         usuario.perfil,
        funcionario_id: usuario.funcionario_id,
        nome:           usuario.nome_completo,
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '8h' }
    );

    res.json({
      token,
      usuario: {
        id:             usuario.id,
        email:          usuario.email,
        perfil:         usuario.perfil,
        funcionario_id: usuario.funcionario_id,
        nome:           usuario.nome_completo,
        cargo:          usuario.cargo,
      }
    });

  } catch (err) {
    console.error('Erro no login:', err);
    res.status(500).json({ erro: 'Erro interno do servidor.' });
  }
});

// ============================================================
// GET /api/auth/me — retorna dados do usuário logado
// ============================================================
router.get('/me', autenticar, async (req, res) => {
  try {
    const resultado = await pool.query(
      `SELECT u.id, u.email, u.perfil, u.ultimo_acesso,
              f.nome_completo, f.cargo, f.foto_url
       FROM usuarios u
       LEFT JOIN funcionarios f ON f.id = u.funcionario_id
       WHERE u.id = $1`,
      [req.usuario.id]
    );

    if (resultado.rows.length === 0) {
      return res.status(404).json({ erro: 'Usuário não encontrado.' });
    }

    res.json(resultado.rows[0]);
  } catch (err) {
    res.status(500).json({ erro: 'Erro interno do servidor.' });
  }
});

// ============================================================
// POST /api/auth/trocar-senha
// ============================================================
router.post('/trocar-senha', autenticar, async (req, res) => {
  const { senha_atual, senha_nova } = req.body;

  if (!senha_atual || !senha_nova) {
    return res.status(400).json({ erro: 'Senha atual e nova senha são obrigatórias.' });
  }

  if (senha_nova.length < 8) {
    return res.status(400).json({ erro: 'A nova senha deve ter pelo menos 8 caracteres.' });
  }

  try {
    const resultado = await pool.query('SELECT senha_hash FROM usuarios WHERE id = $1', [req.usuario.id]);
    const usuario = resultado.rows[0];

    const senhaCorreta = await bcrypt.compare(senha_atual, usuario.senha_hash);
    if (!senhaCorreta) {
      return res.status(401).json({ erro: 'Senha atual incorreta.' });
    }

    const novoHash = await bcrypt.hash(senha_nova, 12);
    await pool.query('UPDATE usuarios SET senha_hash = $1 WHERE id = $2', [novoHash, req.usuario.id]);

    res.json({ mensagem: 'Senha alterada com sucesso.' });
  } catch (err) {
    res.status(500).json({ erro: 'Erro interno do servidor.' });
  }
});

module.exports = router;
