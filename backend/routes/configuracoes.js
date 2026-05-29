'use strict';
// CRUD dos cadastros estruturais (plano de contas / dimensoes):
//   - /departamentos
//   - /categorias-financeiras
//   - /centros-custo
//   - /contas-bancarias
// Todas as rotas exigem perfil admin.
const router = require('express').Router();
const pool = require('../config/database');
const authMW = require('../middleware/auth');
const { requirePerfil } = authMW;

router.use(authMW);
router.use(requirePerfil('admin'));

// ---------------------------------------------------------------
// helpers
// ---------------------------------------------------------------
function handleError(res, e, msg) {
  console.error('[config]', msg, e.message);
  if (e.code === '23505') return res.status(409).json({ error: 'Já existe um registro com esse nome.' });
  if (e.code === '23503') return res.status(409).json({ error: 'Não foi possível desativar/excluir: há registros vinculados.' });
  return res.status(500).json({ error: msg });
}

// ---------------------------------------------------------------
// DEPARTAMENTOS
// ---------------------------------------------------------------
router.get('/departamentos', async (_req, res) => {
  try {
    const r = await pool.query('SELECT id, nome, descricao, ativo, created_at FROM departamentos ORDER BY nome');
    res.json(r.rows);
  } catch (e) { handleError(res, e, 'Erro ao listar departamentos'); }
});

router.post('/departamentos', async (req, res) => {
  const { nome, descricao = null, ativo = true } = req.body || {};
  if (!nome || !nome.trim()) return res.status(400).json({ error: 'Nome é obrigatório.' });
  try {
    const r = await pool.query(
      'INSERT INTO departamentos (nome, descricao, ativo) VALUES ($1,$2,$3) RETURNING *',
      [nome.trim(), descricao, ativo]
    );
    res.status(201).json(r.rows[0]);
  } catch (e) { handleError(res, e, 'Erro ao criar departamento'); }
});

router.put('/departamentos/:id', async (req, res) => {
  const { nome, descricao, ativo } = req.body || {};
  try {
    const r = await pool.query(
      `UPDATE departamentos SET
         nome = COALESCE($1, nome),
         descricao = COALESCE($2, descricao),
         ativo = COALESCE($3, ativo)
       WHERE id = $4 RETURNING *`,
      [nome, descricao, ativo, req.params.id]
    );
    if (!r.rowCount) return res.status(404).json({ error: 'Departamento não encontrado.' });
    res.json(r.rows[0]);
  } catch (e) { handleError(res, e, 'Erro ao atualizar departamento'); }
});

// ---------------------------------------------------------------
// CATEGORIAS FINANCEIRAS
// ---------------------------------------------------------------
router.get('/categorias-financeiras', async (_req, res) => {
  try {
    const r = await pool.query('SELECT id, nome, tipo, icone, cor, ativo FROM categorias_financeiras ORDER BY tipo, nome');
    res.json(r.rows);
  } catch (e) { handleError(res, e, 'Erro ao listar categorias'); }
});

router.post('/categorias-financeiras', async (req, res) => {
  const { nome, tipo, icone = null, cor = null, ativo = true } = req.body || {};
  if (!nome || !tipo) return res.status(400).json({ error: 'Nome e tipo são obrigatórios.' });
  if (!['receita', 'despesa'].includes(tipo)) return res.status(400).json({ error: 'Tipo deve ser "receita" ou "despesa".' });
  try {
    const r = await pool.query(
      'INSERT INTO categorias_financeiras (nome, tipo, icone, cor, ativo) VALUES ($1,$2,$3,$4,$5) RETURNING *',
      [nome.trim(), tipo, icone, cor, ativo]
    );
    res.status(201).json(r.rows[0]);
  } catch (e) { handleError(res, e, 'Erro ao criar categoria'); }
});

router.put('/categorias-financeiras/:id', async (req, res) => {
  const { nome, tipo, icone, cor, ativo } = req.body || {};
  try {
    const r = await pool.query(
      `UPDATE categorias_financeiras SET
         nome = COALESCE($1, nome),
         tipo = COALESCE($2, tipo),
         icone = COALESCE($3, icone),
         cor = COALESCE($4, cor),
         ativo = COALESCE($5, ativo)
       WHERE id = $6 RETURNING *`,
      [nome, tipo, icone, cor, ativo, req.params.id]
    );
    if (!r.rowCount) return res.status(404).json({ error: 'Categoria não encontrada.' });
    res.json(r.rows[0]);
  } catch (e) { handleError(res, e, 'Erro ao atualizar categoria'); }
});

// ---------------------------------------------------------------
// CENTROS DE CUSTO
// ---------------------------------------------------------------
router.get('/centros-custo', async (_req, res) => {
  try {
    const r = await pool.query('SELECT id, nome, ativo FROM centros_custo ORDER BY nome');
    res.json(r.rows);
  } catch (e) { handleError(res, e, 'Erro ao listar centros de custo'); }
});

router.post('/centros-custo', async (req, res) => {
  const { nome, ativo = true } = req.body || {};
  if (!nome || !nome.trim()) return res.status(400).json({ error: 'Nome é obrigatório.' });
  try {
    const r = await pool.query(
      'INSERT INTO centros_custo (nome, ativo) VALUES ($1,$2) RETURNING *',
      [nome.trim(), ativo]
    );
    res.status(201).json(r.rows[0]);
  } catch (e) { handleError(res, e, 'Erro ao criar centro de custo'); }
});

router.put('/centros-custo/:id', async (req, res) => {
  const { nome, ativo } = req.body || {};
  try {
    const r = await pool.query(
      `UPDATE centros_custo SET
         nome = COALESCE($1, nome),
         ativo = COALESCE($2, ativo)
       WHERE id = $3 RETURNING *`,
      [nome, ativo, req.params.id]
    );
    if (!r.rowCount) return res.status(404).json({ error: 'Centro de custo não encontrado.' });
    res.json(r.rows[0]);
  } catch (e) { handleError(res, e, 'Erro ao atualizar centro de custo'); }
});

// ---------------------------------------------------------------
// CONTAS BANCARIAS
// ---------------------------------------------------------------
router.get('/contas-bancarias', async (_req, res) => {
  try {
    const r = await pool.query('SELECT id, nome, banco, agencia, conta, tipo, saldo_inicial, ativo, created_at FROM contas_bancarias ORDER BY nome');
    res.json(r.rows);
  } catch (e) { handleError(res, e, 'Erro ao listar contas bancárias'); }
});

router.post('/contas-bancarias', async (req, res) => {
  const { nome, banco = null, agencia = null, conta = null, tipo = 'corrente', saldo_inicial = 0, ativo = true } = req.body || {};
  if (!nome || !nome.trim()) return res.status(400).json({ error: 'Nome é obrigatório.' });
  try {
    const r = await pool.query(
      `INSERT INTO contas_bancarias (nome, banco, agencia, conta, tipo, saldo_inicial, ativo)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [nome.trim(), banco, agencia, conta, tipo, saldo_inicial, ativo]
    );
    res.status(201).json(r.rows[0]);
  } catch (e) { handleError(res, e, 'Erro ao criar conta bancária'); }
});

router.put('/contas-bancarias/:id', async (req, res) => {
  const { nome, banco, agencia, conta, tipo, saldo_inicial, ativo } = req.body || {};
  try {
    const r = await pool.query(
      `UPDATE contas_bancarias SET
         nome = COALESCE($1, nome),
         banco = COALESCE($2, banco),
         agencia = COALESCE($3, agencia),
         conta = COALESCE($4, conta),
         tipo = COALESCE($5, tipo),
         saldo_inicial = COALESCE($6, saldo_inicial),
         ativo = COALESCE($7, ativo)
       WHERE id = $8 RETURNING *`,
      [nome, banco, agencia, conta, tipo, saldo_inicial, ativo, req.params.id]
    );
    if (!r.rowCount) return res.status(404).json({ error: 'Conta bancária não encontrada.' });
    res.json(r.rows[0]);
  } catch (e) { handleError(res, e, 'Erro ao atualizar conta bancária'); }
});

module.exports = router;
