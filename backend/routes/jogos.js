const express = require('express');
const router  = express.Router();
const db      = require('../config/database');
const { autenticar, autorizarPerfis } = require('../middleware/auth');

router.use(autenticar);

// ── RESUMO ──────────────────────────────────────────────────────
router.get('/resumo', async (req, res) => {
  try {
    const { rows } = await db.query(`
      SELECT
        COUNT(*)                                              AS total_jogos,
        COUNT(*) FILTER (WHERE status='realizado')           AS realizados,
        COUNT(*) FILTER (WHERE status IN ('agendado','confirmado')) AS proximos,
        COUNT(*) FILTER (WHERE status='realizado' AND gols_nos > gols_adversario) AS vitorias,
        COUNT(*) FILTER (WHERE status='realizado' AND gols_nos = gols_adversario) AS empates,
        COUNT(*) FILTER (WHERE status='realizado' AND gols_nos < gols_adversario) AS derrotas,
        COALESCE(SUM(gols_nos)        FILTER (WHERE status='realizado'), 0) AS gols_marcados,
        COALESCE(SUM(gols_adversario) FILTER (WHERE status='realizado'), 0) AS gols_sofridos,
        COALESCE(AVG(publico_total)   FILTER (WHERE status='realizado' AND tipo_jogo='mandante'), 0) AS media_publico,
        COALESCE(SUM(publico_total)   FILTER (WHERE status='realizado' AND tipo_jogo='mandante'), 0) AS publico_total_temporada
      FROM jogos
    `);

    // Financeiro geral
    const fin = await db.query(`
      SELECT
        COALESCE(SUM(rj.valor_total) FILTER (WHERE rj.realizado=TRUE), 0)  AS receita_total,
        COALESCE(SUM(ioj.valor_realizado), 0)                               AS custo_total,
        COALESCE(SUM(rj.valor_total) FILTER (WHERE rj.realizado=FALSE), 0) AS receita_estimada,
        COALESCE(SUM(ioj.valor_estimado) FILTER (WHERE ioj.valor_realizado IS NULL), 0) AS custo_estimado
      FROM jogos j
      LEFT JOIN receitas_jogo rj ON rj.jogo_id = j.id
      LEFT JOIN orcamentos_jogo oj ON oj.jogo_id = j.id
      LEFT JOIN itens_orcamento_jogo ioj ON ioj.orcamento_id = oj.id
    `);

    // Próximo jogo
    const proximo = await db.query(`
      SELECT j.*, jc.receita_total, jc.custo_estimado
      FROM jogos_completo jc
      JOIN jogos j ON j.id = jc.id
      WHERE j.status IN ('agendado','confirmado') AND j.data_jogo >= NOW()
      ORDER BY j.data_jogo ASC LIMIT 1
    `);

    const dados = {
      ...rows[0],
      ...fin.rows[0],
      proximo_jogo: proximo.rows[0] || null
    };
    const v = Number(dados.vitorias||0);
    const e = Number(dados.empates||0);
    const d = Number(dados.derrotas||0);
    const total_result = v + e + d;
    dados.aproveitamento = total_result > 0 ? Math.round(((v * 3 + e) / (total_result * 3)) * 100) : 0;

    res.json({ sucesso: true, dados });
  } catch (err) {
    console.error(err);
    res.status(500).json({ sucesso: false, erro: 'Erro interno no servidor.' });
  }
});

// ── LISTAR JOGOS ────────────────────────────────────────────────
router.get('/', async (req, res) => {
  try {
    const { status, competicao, tipo_jogo, busca } = req.query;
    const filtros = ['1=1'];
    const params  = [];

    if (status)     { params.push(status);     filtros.push(`j.status = $${params.length}`); }
    if (competicao) { params.push(competicao); filtros.push(`j.competicao = $${params.length}`); }
    if (tipo_jogo)  { params.push(tipo_jogo);  filtros.push(`j.tipo_jogo = $${params.length}`); }
    if (busca)      { params.push(`%${busca}%`); filtros.push(`(j.adversario ILIKE $${params.length} OR j.local_jogo ILIKE $${params.length})`); }

    const { rows } = await db.query(
      `SELECT jc.* FROM jogos_completo jc JOIN jogos j ON j.id = jc.id
       WHERE ${filtros.join(' AND ')}
       ORDER BY j.data_jogo DESC`,
      params
    );
    res.json({ sucesso: true, dados: rows });
  } catch (err) {
    res.status(500).json({ sucesso: false, erro: 'Erro interno no servidor.' });
  }
});

// ── DETALHE DO JOGO ─────────────────────────────────────────────
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const jogo = await db.query('SELECT * FROM jogos_completo WHERE id = $1', [id]);
    if (!jogo.rows.length) return res.status(404).json({ sucesso: false, erro: 'Jogo não encontrado.' });

    // Orçamento com itens
    const orcamento = await db.query(
      `SELECT oj.*, json_agg(ioj.* ORDER BY ioj.ordem) AS itens
       FROM orcamentos_jogo oj
       LEFT JOIN itens_orcamento_jogo ioj ON ioj.orcamento_id = oj.id
       WHERE oj.jogo_id = $1
       GROUP BY oj.id`, [id]
    );

    // Receitas
    const receitas = await db.query(
      `SELECT * FROM receitas_jogo WHERE jogo_id = $1 ORDER BY tipo, realizado DESC`, [id]
    );

    // Gols
    const gols = await db.query(
      `SELECT gj.*, a.nome AS atleta_nome, ass.nome AS assistente_nome
       FROM gols_jogo gj
       LEFT JOIN atletas a   ON a.id   = gj.atleta_id
       LEFT JOIN atletas ass ON ass.id = gj.assistente_id
       WHERE gj.jogo_id = $1
       ORDER BY gj.minuto`, [id]
    );

    res.json({
      sucesso: true,
      jogo: jogo.rows[0],
      orcamento: orcamento.rows[0] || null,
      receitas: receitas.rows,
      gols: gols.rows
    });
  } catch (err) {
    res.status(500).json({ sucesso: false, erro: 'Erro interno no servidor.' });
  }
});

// ── CRIAR JOGO ──────────────────────────────────────────────────
router.post('/', autorizarPerfis('admin','gestor'), async (req, res) => {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const {
      competicao, rodada, adversario, data_jogo, local_jogo,
      tipo_jogo, capacidade_estadio, transmissao_tv, transmissao_streaming, observacoes,
      gerar_orcamento_automatico = true
    } = req.body;

    // Cria o jogo
    const { rows: [jogo] } = await client.query(
      `INSERT INTO jogos (competicao, rodada, adversario, data_jogo, local_jogo, tipo_jogo,
                          capacidade_estadio, transmissao_tv, transmissao_streaming, observacoes, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING *`,
      [competicao, rodada, adversario, data_jogo, local_jogo, tipo_jogo,
       capacidade_estadio || null, transmissao_tv || false, transmissao_streaming || false,
       observacoes || null, req.usuario.id]
    );

    // Orçamento automático
    if (gerar_orcamento_automatico) {
      // Busca template mais específico (competição + tipo) → fallback (só tipo)
      const tmpl = await client.query(
        `SELECT id FROM templates_orcamento_jogo
         WHERE tipo_jogo = $1 AND ativo = TRUE
         ORDER BY (competicao = $2) DESC, id ASC
         LIMIT 1`,
        [tipo_jogo, competicao]
      );

      if (tmpl.rows.length) {
        const { rows: [orc] } = await client.query(
          `INSERT INTO orcamentos_jogo (jogo_id) VALUES ($1) RETURNING *`, [jogo.id]
        );
        const itens = await client.query(
          `SELECT * FROM itens_template_orcamento WHERE template_id = $1 ORDER BY ordem`, [tmpl.rows[0].id]
        );
        for (const item of itens.rows) {
          await client.query(
            `INSERT INTO itens_orcamento_jogo (orcamento_id, categoria, descricao, valor_estimado, ordem)
             VALUES ($1,$2,$3,$4,$5)`,
            [orc.id, item.categoria, item.descricao, item.valor_padrao, item.ordem]
          );
        }
        jogo.orcamento_id = orc.id;
      }
    }

    await client.query('COMMIT');
    res.status(201).json({ sucesso: true, jogo });
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ sucesso: false, erro: 'Erro interno no servidor.' });
  } finally {
    client.release();
  }
});

// ── ATUALIZAR JOGO ──────────────────────────────────────────────
router.put('/:id', autorizarPerfis('admin','gestor'), async (req, res) => {
  try {
    const { id } = req.params;
    const {
      adversario, data_jogo, local_jogo, tipo_jogo, rodada, status,
      gols_nos, gols_adversario, capacidade_estadio,
      publico_pagante, publico_cortesias, transmissao_tv, transmissao_streaming, observacoes
    } = req.body;

    const { rows } = await db.query(
      `UPDATE jogos SET
         adversario=$1, data_jogo=$2, local_jogo=$3, tipo_jogo=$4, rodada=$5, status=$6,
         gols_nos=$7, gols_adversario=$8, capacidade_estadio=$9,
         publico_pagante=$10, publico_cortesias=$11,
         transmissao_tv=$12, transmissao_streaming=$13, observacoes=$14
       WHERE id=$15 RETURNING *`,
      [adversario, data_jogo, local_jogo, tipo_jogo, rodada, status,
       gols_nos ?? null, gols_adversario ?? null, capacidade_estadio ?? null,
       publico_pagante ?? null, publico_cortesias ?? null,
       transmissao_tv || false, transmissao_streaming || false, observacoes || null, id]
    );
    if (!rows.length) return res.status(404).json({ sucesso: false, erro: 'Jogo não encontrado.' });
    res.json({ sucesso: true, jogo: rows[0] });
  } catch (err) {
    res.status(500).json({ sucesso: false, erro: 'Erro interno no servidor.' });
  }
});

// ── REGISTRAR RESULTADO ─────────────────────────────────────────
router.patch('/:id/resultado', autorizarPerfis('admin','gestor'), async (req, res) => {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { id } = req.params;
    const { gols_nos, gols_adversario, publico_pagante, publico_cortesias, gols = [] } = req.body;

    await client.query(
      `UPDATE jogos SET gols_nos=$1, gols_adversario=$2,
                        publico_pagante=$3, publico_cortesias=$4, status='realizado'
       WHERE id=$5`,
      [gols_nos, gols_adversario, publico_pagante || 0, publico_cortesias || 0, id]
    );

    // Registra gols
    if (gols.length) {
      await client.query('DELETE FROM gols_jogo WHERE jogo_id = $1', [id]);
      for (const g of gols) {
        await client.query(
          `INSERT INTO gols_jogo (jogo_id, atleta_id, minuto, tipo, time, assistente_id)
           VALUES ($1,$2,$3,$4,$5,$6)`,
          [id, g.atleta_id || null, g.minuto || null, g.tipo || 'normal', g.time, g.assistente_id || null]
        );
      }

      // Atualiza estatísticas dos atletas
      for (const g of gols.filter(g => g.time === 'nos' && g.atleta_id)) {
        await client.query(
          `INSERT INTO estatisticas_atleta (atleta_id, temporada, competicao, jogos, gols)
           VALUES ($1, EXTRACT(YEAR FROM CURRENT_DATE)::TEXT,
                   (SELECT competicao FROM jogos WHERE id=$2), 1, 1)
           ON CONFLICT (atleta_id, temporada, competicao)
           DO UPDATE SET gols = estatisticas_atleta.gols + 1`,
          [g.atleta_id, id]
        );
      }
    }

    // Finaliza orçamento
    await client.query(
      `UPDATE orcamentos_jogo SET status='realizado' WHERE jogo_id=$1`, [id]
    );

    await client.query('COMMIT');
    res.json({ sucesso: true, mensagem: 'Resultado registrado.' });
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ sucesso: false, erro: 'Erro interno no servidor.' });
  } finally {
    client.release();
  }
});

// ── ORÇAMENTO: ADICIONAR ITEM ───────────────────────────────────
router.post('/:id/orcamento/itens', async (req, res) => {
  try {
    const { id } = req.params;
    const { categoria, descricao, valor_estimado, fornecedor } = req.body;

    // Garante que existe orçamento
    let orc = await db.query('SELECT id FROM orcamentos_jogo WHERE jogo_id=$1', [id]);
    if (!orc.rows.length) {
      orc = await db.query('INSERT INTO orcamentos_jogo (jogo_id) VALUES ($1) RETURNING *', [id]);
    }
    const orcId = orc.rows[0].id;

    const { rows: [item] } = await db.query(
      `INSERT INTO itens_orcamento_jogo (orcamento_id, categoria, descricao, valor_estimado, fornecedor)
       VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [orcId, categoria, descricao, valor_estimado, fornecedor || null]
    );
    res.status(201).json({ sucesso: true, item });
  } catch (err) {
    res.status(500).json({ sucesso: false, erro: 'Erro interno no servidor.' });
  }
});

// ── ORÇAMENTO: ATUALIZAR ITEM ───────────────────────────────────
router.put('/:id/orcamento/itens/:itemId', async (req, res) => {
  try {
    const { itemId } = req.params;
    const { descricao, valor_estimado, valor_realizado, pago, fornecedor } = req.body;
    const { rows } = await db.query(
      `UPDATE itens_orcamento_jogo SET
         descricao=$1, valor_estimado=$2, valor_realizado=$3, pago=$4, fornecedor=$5
       WHERE id=$6 RETURNING *`,
      [descricao, valor_estimado, valor_realizado ?? null, pago ?? false, fornecedor || null, itemId]
    );
    if (!rows.length) return res.status(404).json({ sucesso: false, erro: 'Item não encontrado.' });
    res.json({ sucesso: true, item: rows[0] });
  } catch (err) {
    res.status(500).json({ sucesso: false, erro: 'Erro interno no servidor.' });
  }
});

// ── ORÇAMENTO: APROVAR ──────────────────────────────────────────
router.patch('/:id/orcamento/aprovar', autorizarPerfis('admin','gestor','financeiro'), async (req, res) => {
  try {
    const { id } = req.params;
    await db.query(
      `UPDATE orcamentos_jogo SET status='aprovado', aprovado_por=$1, aprovado_em=NOW()
       WHERE jogo_id=$2`,
      [req.usuario.id, id]
    );
    res.json({ sucesso: true, mensagem: 'Orçamento aprovado.' });
  } catch (err) {
    res.status(500).json({ sucesso: false, erro: 'Erro interno no servidor.' });
  }
});

// ── RECEITAS: ADICIONAR ─────────────────────────────────────────
router.post('/:id/receitas', async (req, res) => {
  try {
    const { id } = req.params;
    const { tipo, descricao, quantidade, valor_unitario, valor_total, realizado } = req.body;
    const { rows: [rec] } = await db.query(
      `INSERT INTO receitas_jogo (jogo_id, tipo, descricao, quantidade, valor_unitario, valor_total, realizado)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [id, tipo, descricao || null, quantidade || null, valor_unitario || null, valor_total, realizado ?? false]
    );
    res.status(201).json({ sucesso: true, receita: rec });
  } catch (err) {
    res.status(500).json({ sucesso: false, erro: 'Erro interno no servidor.' });
  }
});

// ── RECEITAS: ATUALIZAR ─────────────────────────────────────────
router.put('/:id/receitas/:recId', async (req, res) => {
  try {
    const { recId } = req.params;
    const { tipo, descricao, quantidade, valor_unitario, valor_total, realizado } = req.body;
    const { rows } = await db.query(
      `UPDATE receitas_jogo SET tipo=$1, descricao=$2, quantidade=$3,
                                valor_unitario=$4, valor_total=$5, realizado=$6
       WHERE id=$7 RETURNING *`,
      [tipo, descricao || null, quantidade || null, valor_unitario || null, valor_total, realizado ?? false, recId]
    );
    if (!rows.length) return res.status(404).json({ sucesso: false, erro: 'Receita não encontrada.' });
    res.json({ sucesso: true, receita: rows[0] });
  } catch (err) {
    res.status(500).json({ sucesso: false, erro: 'Erro interno no servidor.' });
  }
});

// ── TEMPLATES ───────────────────────────────────────────────────
router.get('/aux/templates', async (req, res) => {
  try {
    const { tipo_jogo, competicao } = req.query;
    const tmpl = await db.query(
      `SELECT t.*, json_agg(i.* ORDER BY i.ordem) AS itens
       FROM templates_orcamento_jogo t
       JOIN itens_template_orcamento i ON i.template_id = t.id
       WHERE t.ativo = TRUE
         AND ($1::text IS NULL OR t.tipo_jogo = $1)
         AND ($2::text IS NULL OR t.competicao = $2 OR t.competicao IS NULL)
       GROUP BY t.id`,
      [tipo_jogo || null, competicao || null]
    );
    res.json({ sucesso: true, dados: tmpl.rows });
  } catch (err) {
    res.status(500).json({ sucesso: false, erro: 'Erro interno no servidor.' });
  }
});

// ── CALENDÁRIO (agrupado por mês) ───────────────────────────────
router.get('/aux/calendario', async (req, res) => {
  try {
    const { ano } = req.query;
    const a = ano || new Date().getFullYear();
    const { rows } = await db.query(
      `SELECT jc.*
       FROM jogos_completo jc JOIN jogos j ON j.id = jc.id
       WHERE EXTRACT(YEAR FROM j.data_jogo) = $1
       ORDER BY j.data_jogo`, [a]
    );
    // Agrupa por mês
    const meses = {};
    rows.forEach(j => {
      const mes = new Date(j.data_jogo).toISOString().slice(0, 7);
      if (!meses[mes]) meses[mes] = [];
      meses[mes].push(j);
    });
    res.json({ sucesso: true, dados: meses, total: rows.length });
  } catch (err) {
    res.status(500).json({ sucesso: false, erro: 'Erro interno no servidor.' });
  }
});

module.exports = router;
