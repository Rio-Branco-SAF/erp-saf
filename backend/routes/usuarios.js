const express = require('express');
const bcrypt  = require('bcrypt');
const pool    = require('../config/database');
const { autenticar, autorizarPerfis } = require('../middleware/auth');

const router = express.Router();

// Todos os endpoints exigem login
router.use(autenticar);

// ============================================================
// GET /api/usuarios
// Lista todos os usuários (apenas admin e rh)
// ============================================================
router.get('/', autorizarPerfis('admin', 'rh'), async (req, res) => {
  try {
    const resultado = await pool.query(`
      SELECT
        u.id, u.email, u.perfil, u.ativo, u.ultimo_acesso, u.created_at,
        f.nome_completo, f.cargo, f.departamento_id,
        d.nome AS departamento
      FROM usuarios u
      LEFT JOIN funcionarios f ON f.id = u.funcionario_id
      LEFT JOIN departamentos d ON d.id = f.departamento_id
      ORDER BY u.ativo DESC, f.nome_completo ASC
    `);
    res.json(resultado.rows);
  } catch (err) {
    console.error('Erro ao listar usuários:', err);
    res.status(500).json({ erro: 'Erro ao buscar usuários.' });
  }
});

// ============================================================
// POST /api/usuarios
// Cria login para um funcionário (apenas admin)
// Body: { funcionario_id, email, senha, perfil }
// ============================================================
router.post('/', autorizarPerfis('admin'), async (req, res) => {
  const { funcionario_id, email, senha, perfil } = req.body;

  if (!email || !senha || !perfil) {
    return res.status(400).json({ erro: 'E-mail, senha e perfil são obrigatórios.' });
  }

  const perfisValidos = ['admin', 'gestor', 'financeiro', 'rh', 'funcionario'];
  if (!perfisValidos.includes(perfil)) {
    return res.status(400).json({ erro: `Perfil inválido. Use: ${perfisValidos.join(', ')}.` });
  }

  if (senha.length < 8) {
    return res.status(400).json({ erro: 'A senha deve ter pelo menos 8 caracteres.' });
  }

  try {
    const hash = await bcrypt.hash(senha, 12);

    const resultado = await pool.query(
      `INSERT INTO usuarios (funcionario_id, email, senha_hash, perfil)
       VALUES ($1, $2, $3, $4)
       RETURNING id, email, perfil, ativo, created_at`,
      [funcionario_id || null, email.toLowerCase().trim(), hash, perfil]
    );

    res.status(201).json({
      mensagem: 'Usuário criado com sucesso.',
      usuario: resultado.rows[0],
    });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ erro: 'Este e-mail já está cadastrado.' });
    }
    console.error('Erro ao criar usuário:', err);
    res.status(500).json({ erro: 'Erro ao criar usuário.' });
  }
});

// ============================================================
// PUT /api/usuarios/:id
// Atualiza perfil ou ativa/desativa um usuário
// ============================================================
router.put('/:id', autorizarPerfis('admin'), async (req, res) => {
  const { id } = req.params;
  const { perfil, ativo } = req.body;

  // Impede que o admin desative a própria conta
  if (parseInt(id) === req.usuario.id && ativo === false) {
    return res.status(400).json({ erro: 'Você não pode desativar a sua própria conta.' });
  }

  try {
    const resultado = await pool.query(
      `UPDATE usuarios
       SET perfil = COALESCE($1, perfil),
           ativo  = COALESCE($2, ativo)
       WHERE id = $3
       RETURNING id, email, perfil, ativo`,
      [perfil || null, ativo !== undefined ? ativo : null, id]
    );

    if (resultado.rows.length === 0) {
      return res.status(404).json({ erro: 'Usuário não encontrado.' });
    }

    res.json({ mensagem: 'Usuário atualizado.', usuario: resultado.rows[0] });
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao atualizar usuário.' });
  }
});

// ============================================================
// POST /api/usuarios/:id/resetar-senha
// Admin redefine a senha de qualquer usuário
// ============================================================
router.post('/:id/resetar-senha', autorizarPerfis('admin'), async (req, res) => {
  const { nova_senha } = req.body;

  if (!nova_senha || nova_senha.length < 8) {
    return res.status(400).json({ erro: 'A nova senha deve ter pelo menos 8 caracteres.' });
  }

  try {
    const hash = await bcrypt.hash(nova_senha, 12);
    const resultado = await pool.query(
      'UPDATE usuarios SET senha_hash = $1, primeiro_acesso = true WHERE id = $2 RETURNING id, email',
      [hash, req.params.id]
    );

    if (resultado.rows.length === 0) {
      return res.status(404).json({ erro: 'Usuário não encontrado.' });
    }

    res.json({ mensagem: `Senha do usuário ${resultado.rows[0].email} redefinida com sucesso.` });
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao redefinir senha.' });
  }
});

// ============================================================
// GET /api/usuarios/perfis
// Retorna os perfis disponíveis com descrição
// ============================================================
router.get('/perfis', async (req, res) => {
  res.json([
    { valor: 'admin',       label: 'Administrador',  descricao: 'Acesso total ao sistema. Pode criar/editar usuários.' },
    { valor: 'gestor',      label: 'Gestor',         descricao: 'Acesso completo a todos os módulos, sem gestão de usuários.' },
    { valor: 'financeiro',  label: 'Financeiro',     descricao: 'Acesso ao módulo financeiro, pedidos de compra e relatórios.' },
    { valor: 'rh',          label: 'RH',             descricao: 'Acesso ao módulo de funcionários, contratos e folha.' },
    { valor: 'funcionario', label: 'Funcionário',    descricao: 'Acesso limitado: perfil próprio e pedidos de compra.' },
  ]);
});

module.exports = router;
