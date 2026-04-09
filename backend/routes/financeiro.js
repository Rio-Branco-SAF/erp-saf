const express = require('express');
const pool    = require('../config/database');
const { autenticar, autorizarPerfis } = require('../middleware/auth');

const router = express.Router();
router.use(autenticar);

// ============================================================
// GET /api/financeiro/resumo
// Dashboard: saldo, totais do mês, mês anterior, comparativo
// ============================================================
router.get('/resumo', async (req, res) => {
  try {
    const { mes, ano } = req.query;
    const mesRef = mes ? parseInt(mes) : new Date().getMonth() + 1;
    const anoRef = ano ? parseInt(ano) : new Date().getFullYear();

    // Saldo acumulado realizado até hoje
    const saldoRes = await pool.query(`
      SELECT
        COALESCE(SUM(CASE WHEN tipo='receita' THEN valor ELSE -valor END), 0) AS saldo_total,
        COALESCE(SUM(CASE WHEN tipo='receita' AND status='realizado' THEN valor ELSE 0 END), 0) AS total_receitas_realizado,
        COALESCE(SUM(CASE WHEN tipo='despesa' AND status='realizado' THEN valor ELSE 0 END), 0) AS total_despesas_realizado
      FROM lancamentos_financeiros
      WHERE status != 'cancelado'
        AND data_competencia <= CURRENT_DATE
    `);

    // Mês de referência
    const mesAtualRes = await pool.query(`
      SELECT
        COALESCE(SUM(CASE WHEN tipo='receita' THEN valor ELSE 0 END), 0) AS receitas,
        COALESCE(SUM(CASE WHEN tipo='despesa' THEN valor ELSE 0 END), 0) AS despesas,
        COALESCE(SUM(CASE WHEN tipo='receita' AND status='realizado' THEN valor ELSE 0 END), 0) AS receitas_realizado,
        COALESCE(SUM(CASE WHEN tipo='despesa' AND status='realizado' THEN valor ELSE 0 END), 0) AS despesas_realizado,
        COUNT(*) FILTER (WHERE status='previsto') AS qtd_previsto
      FROM lancamentos_financeiros
      WHERE status != 'cancelado'
        AND EXTRACT(MONTH FROM data_competencia) = $1
        AND EXTRACT(YEAR  FROM data_competencia) = $2
    `, [mesRef, anoRef]);

    // Mês anterior (para comparativo)
    const mesAntRef = mesRef === 1 ? 12 : mesRef - 1;
    const anoAntRef = mesRef === 1 ? anoRef - 1 : anoRef;
    const mesAntRes = await pool.query(`
      SELECT
        COALESCE(SUM(CASE WHEN tipo='receita' THEN valor ELSE 0 END), 0) AS receitas,
        COALESCE(SUM(CASE WHEN tipo='despesa' THEN valor ELSE 0 END), 0) AS despesas
      FROM lancamentos_financeiros
      WHERE status != 'cancelado'
        AND EXTRACT(MONTH FROM data_competencia) = $1
        AND EXTRACT(YEAR  FROM data_competencia) = $2
    `, [mesAntRef, anoAntRef]);

    // Contas a pagar (previstas, vencendo em 30 dias)
    const proximosRes = await pool.query(`
      SELECT COUNT(*) AS qtd, COALESCE(SUM(valor),0) AS total
      FROM lancamentos_financeiros
      WHERE tipo = 'despesa' AND status = 'previsto'
        AND data_competencia BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
    `);

    // Contas a receber (previstas, nos próximos 30 dias)
    const receberRes = await pool.query(`
      SELECT COUNT(*) AS qtd, COALESCE(SUM(valor),0) AS total
      FROM lancamentos_financeiros
      WHERE tipo = 'receita' AND status = 'previsto'
        AND data_competencia BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
    `);

    res.json({
      saldo:                  parseFloat(saldoRes.rows[0].saldo_total),
      total_receitas_all:     parseFloat(saldoRes.rows[0].total_receitas_realizado),
      total_despesas_all:     parseFloat(saldoRes.rows[0].total_despesas_realizado),
      mes_atual: {
        receitas:             parseFloat(mesAtualRes.rows[0].receitas),
        despesas:             parseFloat(mesAtualRes.rows[0].despesas),
        receitas_realizado:   parseFloat(mesAtualRes.rows[0].receitas_realizado),
        despesas_realizado:   parseFloat(mesAtualRes.rows[0].despesas_realizado),
        saldo:                parseFloat(mesAtualRes.rows[0].receitas) - parseFloat(mesAtualRes.rows[0].despesas),
        qtd_previsto:         parseInt(mesAtualRes.rows[0].qtd_previsto),
      },
      mes_anterior: {
        receitas:             parseFloat(mesAntRes.rows[0].receitas),
        despesas:             parseFloat(mesAntRes.rows[0].despesas),
        saldo:                parseFloat(mesAntRes.rows[0].receitas) - parseFloat(mesAntRes.rows[0].despesas),
      },
      proximos_30_dias: {
        a_pagar:  { qtd: parseInt(proximosRes.rows[0].qtd),  total: parseFloat(proximosRes.rows[0].total) },
        a_receber:{ qtd: parseInt(receberRes.rows[0].qtd),   total: parseFloat(receberRes.rows[0].total) },
      },
    });
  } catch (err) {
    console.error('Erro no resumo financeiro:', err);
    res.status(500).json({ erro: 'Erro ao buscar resumo financeiro.', detalhe: err.message, codigo: err.code });
  }
});

// ============================================================
// GET /api/financeiro/fluxo-mensal
// Dados para o gráfico de fluxo de caixa (últimos N meses)
// ============================================================
router.get('/fluxo-mensal', async (req, res) => {
  try {
    const meses = parseInt(req.query.meses) || 6;
    const resultado = await pool.query(`
      SELECT
        TO_CHAR(data_competencia, 'YYYY-MM')   AS mes,
        TO_CHAR(data_competencia, 'Mon/YY')    AS mes_label,
        SUM(CASE WHEN tipo='receita' THEN valor ELSE 0 END) AS receitas,
        SUM(CASE WHEN tipo='despesa' THEN valor ELSE 0 END) AS despesas,
        SUM(CASE WHEN tipo='receita' THEN valor ELSE -valor END) AS saldo
      FROM lancamentos_financeiros
      WHERE status != 'cancelado'
        AND data_competencia >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '${meses - 1} months'
        AND data_competencia <  DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
      GROUP BY TO_CHAR(data_competencia, 'YYYY-MM'), TO_CHAR(data_competencia, 'Mon/YY')
      ORDER BY mes
    `);
    res.json(resultado.rows.map(r => ({
      mes:       r.mes,
      label:     r.mes_label,
      receitas:  parseFloat(r.receitas),
      despesas:  parseFloat(r.despesas),
      saldo:     parseFloat(r.saldo),
    })));
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao buscar fluxo mensal.' });
  }
});

// ============================================================
// GET /api/financeiro/lancamentos
// Lista com filtros, busca e paginação
// ============================================================
router.get('/lancamentos', async (req, res) => {
  try {
    const {
      tipo, status, categoria_id, centro_custo_id,
      data_inicio, data_fim, busca,
      pagina = 1, limite = 25,
    } = req.query;

    const params  = [];
    const filtros = [];
    let i = 1;

    if (tipo)            { filtros.push(`l.tipo = $${i++}`);              params.push(tipo); }
    if (status)          { filtros.push(`l.status = $${i++}`);            params.push(status); }
    if (categoria_id)    { filtros.push(`l.categoria_id = $${i++}`);      params.push(categoria_id); }
    if (centro_custo_id) { filtros.push(`l.centro_custo_id = $${i++}`);   params.push(centro_custo_id); }
    if (data_inicio)     { filtros.push(`l.data_competencia >= $${i++}`); params.push(data_inicio); }
    if (data_fim)        { filtros.push(`l.data_competencia <= $${i++}`); params.push(data_fim); }
    if (busca)           { filtros.push(`l.descricao ILIKE $${i++}`);     params.push(`%${busca}%`); }

    const where = filtros.length ? 'WHERE ' + filtros.join(' AND ') : '';

    const totalRes = await pool.query(
      `SELECT COUNT(*) FROM lancamentos_financeiros l ${where}`, params
    );
    const total = parseInt(totalRes.rows[0].count);

    const offset = (parseInt(pagina) - 1) * parseInt(limite);
    params.push(parseInt(limite), offset);

    const resultado = await pool.query(`
      SELECT
        l.id, l.tipo, l.descricao, l.valor, l.status,
        l.data_competencia, l.data_pagamento, l.recorrente,
        l.origem_tipo, l.observacoes,
        c.nome AS categoria, c.icone AS categoria_icone, c.cor AS categoria_cor,
        cc.nome AS centro_custo,
        cb.nome AS conta_bancaria
      FROM lancamentos_financeiros l
      JOIN categorias_financeiras c ON c.id = l.categoria_id
      LEFT JOIN centros_custo cc    ON cc.id = l.centro_custo_id
      LEFT JOIN contas_bancarias cb ON cb.id = l.conta_bancaria_id
      ${where}
      ORDER BY l.data_competencia DESC, l.id DESC
      LIMIT $${i} OFFSET $${i+1}
    `, params);

    res.json({
      dados: resultado.rows,
      total,
      pagina:       parseInt(pagina),
      limite:       parseInt(limite),
      totalPaginas: Math.ceil(total / parseInt(limite)),
    });
  } catch (err) {
    console.error('Erro ao listar lançamentos:', err);
    res.status(500).json({ erro: 'Erro ao buscar lançamentos.' });
  }
});

// ============================================================
// GET /api/financeiro/lancamentos/:id
// ============================================================
router.get('/lancamentos/:id', async (req, res) => {
  try {
    const res2 = await pool.query(`
      SELECT l.*, c.nome AS categoria, c.icone, c.cor,
             cc.nome AS centro_custo, cb.nome AS conta_bancaria,
             f.nome_completo AS criado_por_nome
      FROM lancamentos_financeiros l
      JOIN categorias_financeiras c ON c.id = l.categoria_id
      LEFT JOIN centros_custo cc    ON cc.id = l.centro_custo_id
      LEFT JOIN contas_bancarias cb ON cb.id = l.conta_bancaria_id
      LEFT JOIN funcionarios f      ON f.id  = l.criado_por
      WHERE l.id = $1
    `, [req.params.id]);

    if (!res2.rows.length) return res.status(404).json({ erro: 'Lançamento não encontrado.' });
    res.json(res2.rows[0]);
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao buscar lançamento.' });
  }
});

// ============================================================
// POST /api/financeiro/lancamentos
// Cria um lançamento (receita ou despesa)
// ============================================================
router.post('/lancamentos', autorizarPerfis('admin', 'gestor', 'financeiro'), async (req, res) => {
  const {
    tipo, descricao, valor, categoria_id, centro_custo_id,
    conta_bancaria_id, data_competencia, data_pagamento,
    status = 'previsto', recorrente = false, observacoes, origem_tipo, origem_id,
  } = req.body;

  if (!tipo || !descricao || !valor || !categoria_id || !data_competencia) {
    return res.status(400).json({ erro: 'Campos obrigatórios: tipo, descricao, valor, categoria_id, data_competencia.' });
  }
  if (!['receita', 'despesa'].includes(tipo)) {
    return res.status(400).json({ erro: 'tipo deve ser "receita" ou "despesa".' });
  }
  if (parseFloat(valor) <= 0) {
    return res.status(400).json({ erro: 'Valor deve ser maior que zero.' });
  }

  try {
    const resultado = await pool.query(`
      INSERT INTO lancamentos_financeiros
        (tipo, descricao, valor, categoria_id, centro_custo_id, conta_bancaria_id,
         data_competencia, data_pagamento, status, recorrente, observacoes,
         origem_tipo, origem_id, criado_por)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)
      RETURNING *
    `, [
      tipo, descricao, parseFloat(valor), categoria_id,
      centro_custo_id || null, conta_bancaria_id || null,
      data_competencia, data_pagamento || null,
      status, recorrente,
      observacoes || null, origem_tipo || 'manual', origem_id || null,
      req.usuario.funcionario_id || null,
    ]);

    res.status(201).json({
      mensagem: 'Lançamento criado com sucesso.',
      lancamento: resultado.rows[0],
    });
  } catch (err) {
    console.error('Erro ao criar lançamento:', err);
    res.status(500).json({ erro: 'Erro ao criar lançamento.' });
  }
});

// ============================================================
// PUT /api/financeiro/lancamentos/:id
// ============================================================
router.put('/lancamentos/:id', autorizarPerfis('admin', 'gestor', 'financeiro'), async (req, res) => {
  const { id } = req.params;
  const {
    tipo, descricao, valor, categoria_id, centro_custo_id,
    conta_bancaria_id, data_competencia, data_pagamento,
    status, recorrente, observacoes,
  } = req.body;

  try {
    const resultado = await pool.query(`
      UPDATE lancamentos_financeiros SET
        tipo              = COALESCE($1,  tipo),
        descricao         = COALESCE($2,  descricao),
        valor             = COALESCE($3,  valor),
        categoria_id      = COALESCE($4,  categoria_id),
        centro_custo_id   = COALESCE($5,  centro_custo_id),
        conta_bancaria_id = COALESCE($6,  conta_bancaria_id),
        data_competencia  = COALESCE($7,  data_competencia),
        data_pagamento    = $8,
        status            = COALESCE($9,  status),
        recorrente        = COALESCE($10, recorrente),
        observacoes       = COALESCE($11, observacoes)
      WHERE id = $12
      RETURNING *
    `, [
      tipo || null, descricao || null,
      valor ? parseFloat(valor) : null,
      categoria_id || null, centro_custo_id || null,
      conta_bancaria_id || null, data_competencia || null,
      data_pagamento || null, status || null,
      recorrente !== undefined ? recorrente : null,
      observacoes || null, id,
    ]);

    if (!resultado.rows.length) return res.status(404).json({ erro: 'Lançamento não encontrado.' });
    res.json({ mensagem: 'Lançamento atualizado.', lancamento: resultado.rows[0] });
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao atualizar lançamento.' });
  }
});

// ============================================================
// PATCH /api/financeiro/lancamentos/:id/realizar
// Marca um lançamento previsto como realizado
// ============================================================
router.patch('/lancamentos/:id/realizar', autorizarPerfis('admin', 'gestor', 'financeiro'), async (req, res) => {
  const { data_pagamento } = req.body;
  try {
    await pool.query(`
      UPDATE lancamentos_financeiros
      SET status = 'realizado', data_pagamento = $1
      WHERE id = $2 AND status = 'previsto'
    `, [data_pagamento || new Date(), req.params.id]);
    res.json({ mensagem: 'Lançamento confirmado como realizado.' });
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao realizar lançamento.' });
  }
});

// ============================================================
// PATCH /api/financeiro/lancamentos/:id/cancelar
// ============================================================
router.patch('/lancamentos/:id/cancelar', autorizarPerfis('admin', 'gestor', 'financeiro'), async (req, res) => {
  try {
    await pool.query(
      `UPDATE lancamentos_financeiros SET status='cancelado' WHERE id=$1`,
      [req.params.id]
    );
    res.json({ mensagem: 'Lançamento cancelado.' });
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao cancelar lançamento.' });
  }
});

// ============================================================
// DELETE /api/financeiro/lancamentos/:id (soft delete = cancelar)
// ============================================================
router.delete('/lancamentos/:id', autorizarPerfis('admin'), async (req, res) => {
  try {
    await pool.query(
      `UPDATE lancamentos_financeiros SET status='cancelado' WHERE id=$1`,
      [req.params.id]
    );
    res.json({ mensagem: 'Lançamento removido.' });
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao remover lançamento.' });
  }
});

// ============================================================
// GET /api/financeiro/categorias
// ============================================================
router.get('/categorias', async (req, res) => {
  try {
    const { tipo } = req.query;
    const resultado = await pool.query(
      `SELECT * FROM categorias_financeiras
       WHERE ativo = true ${tipo ? "AND (tipo = $1 OR tipo = 'ambos')" : ''}
       ORDER BY tipo, nome`,
      tipo ? [tipo] : []
    );
    res.json(resultado.rows);
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao buscar categorias.' });
  }
});

// ============================================================
// GET /api/financeiro/centros-custo
// ============================================================
router.get('/centros-custo', async (req, res) => {
  try {
    const resultado = await pool.query(
      `SELECT * FROM centros_custo WHERE ativo=true ORDER BY nome`
    );
    res.json(resultado.rows);
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao buscar centros de custo.' });
  }
});

// ============================================================
// GET /api/financeiro/contas-bancarias
// ============================================================
router.get('/contas-bancarias', async (req, res) => {
  try {
    const resultado = await pool.query(
      `SELECT * FROM contas_bancarias WHERE ativo=true ORDER BY nome`
    );
    res.json(resultado.rows);
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao buscar contas bancárias.' });
  }
});

// ============================================================
// GET /api/financeiro/por-categoria
// Totais agrupados por categoria (para gráfico de pizza)
// ============================================================
router.get('/por-categoria', async (req, res) => {
  try {
    const { tipo, mes, ano } = req.query;
    const mesRef = mes ? parseInt(mes) : new Date().getMonth() + 1;
    const anoRef = ano ? parseInt(ano) : new Date().getFullYear();

    const resultado = await pool.query(`
      SELECT
        c.nome AS categoria, c.icone, c.cor,
        COALESCE(SUM(l.valor), 0) AS total,
        COUNT(l.id) AS qtd
      FROM categorias_financeiras c
      LEFT JOIN lancamentos_financeiros l
        ON l.categoria_id = c.id
        AND l.status != 'cancelado'
        AND EXTRACT(MONTH FROM l.data_competencia) = $2
        AND EXTRACT(YEAR  FROM l.data_competencia) = $3
      WHERE c.tipo = $1 AND c.ativo = true
      GROUP BY c.id, c.nome, c.icone, c.cor
      HAVING COALESCE(SUM(l.valor), 0) > 0
      ORDER BY total DESC
    `, [tipo || 'despesa', mesRef, anoRef]);

    res.json(resultado.rows.map(r => ({
      ...r,
      total: parseFloat(r.total),
      qtd:   parseInt(r.qtd),
    })));
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao buscar totais por categoria.' });
  }
});

module.exports = router;
