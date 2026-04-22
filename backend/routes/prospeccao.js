'use strict';

const express = require('express');
const router  = express.Router();
const db      = require('../db');
const { autenticar, autorizarPerfis } = require('../middleware/auth');

// Inicializacao da tabela
(async () => {
  try {
    await db.query(`
      CREATE TABLE IF NOT EXISTS prospeccao (
        id                  SERIAL PRIMARY KEY,
        nome                TEXT NOT NULL,
        posicao             TEXT,
        clube_atual         TEXT,
        data_nascimento     DATE,
        nacionalidade       TEXT,
        agente              TEXT,
        observacoes         TEXT,
        status_prospeccao   TEXT NOT NULL DEFAULT 'observacao',
        prioridade          TEXT NOT NULL DEFAULT 'media',
        avaliacao_geral     INTEGER DEFAULT 0,
        valor_mercado       NUMERIC(15,2) DEFAULT 0,
        salario_atual       NUMERIC(15,2) DEFAULT 0,
        contrato_ate        DATE,
        attr_finalizacao    INTEGER DEFAULT 0,
        attr_passe_curto    INTEGER DEFAULT 0,
        attr_passe_longo    INTEGER DEFAULT 0,
        attr_drible         INTEGER DEFAULT 0,
        attr_cruzamento     INTEGER DEFAULT 0,
        attr_cabeceio       INTEGER DEFAULT 0,
        attr_controle       INTEGER DEFAULT 0,
        attr_marcacao       INTEGER DEFAULT 0,
        attr_desarme        INTEGER DEFAULT 0,
        attr_velocidade     INTEGER DEFAULT 0,
        attr_aceleracao     INTEGER DEFAULT 0,
        attr_forca          INTEGER DEFAULT 0,
        attr_resistencia    INTEGER DEFAULT 0,
        attr_agilidade      INTEGER DEFAULT 0,
        attr_salto          INTEGER DEFAULT 0,
        attr_visao          INTEGER DEFAULT 0,
        attr_decisao        INTEGER DEFAULT 0,
        attr_posicionamento INTEGER DEFAULT 0,
        attr_criatividade   INTEGER DEFAULT 0,
        attr_dedicacao      INTEGER DEFAULT 0,
        attr_trabalho       INTEGER DEFAULT 0,
        attr_defesas        INTEGER DEFAULT 0,
        attr_reflexos       INTEGER DEFAULT 0,
        attr_saida          INTEGER DEFAULT 0,
        attr_comando        INTEGER DEFAULT 0,
        attr_distribuicao   INTEGER DEFAULT 0,
        stats_temporada     TEXT,
        stats_jogos         INTEGER DEFAULT 0,
        stats_gols          INTEGER DEFAULT 0,
        criado_em           TIMESTAMP DEFAULT NOW(),
        atualizado_em       TIMESTAMP DEFAULT NOW()
      )
    `);
  } catch (e) {
    console.error('[prospeccao] Erro ao criar tabela:', e.message);
  }
})();
// GET /resumo
router.get('/resumo', autenticar, async (req, res) => {
  try {
    const [total, porStatus, porPrioridade, porPosicao] = await Promise.all([
      db.query('SELECT COUNT(*) AS total FROM prospeccao'),
      db.query('SELECT status_prospeccao, COUNT(*) AS total FROM prospeccao GROUP BY status_prospeccao'),
      db.query('SELECT prioridade, COUNT(*) AS total FROM prospeccao GROUP BY prioridade'),
      db.query('SELECT posicao, COUNT(*) AS total FROM prospeccao WHERE posicao IS NOT NULL GROUP BY posicao ORDER BY total DESC'),
    ]);
    res.json({ sucesso: true, dados: {
      total: parseInt(total.rows[0].total, 10),
      por_status: porStatus.rows,
      por_prioridade: porPrioridade.rows,
      por_posicao: porPosicao.rows,
    }});
  } catch (err) {
    console.error('[prospeccao] GET /resumo:', err);
    res.status(500).json({ sucesso: false, erro: 'Erro interno ao gerar resumo.' });
  }
});

// GET /
router.get('/', autenticar, async (req, res) => {
  try {
    const { busca, status, prioridade, posicao, sort = 'criado_em', order = 'DESC', page = 1, limit = 50 } = req.query;
    const conds = []; const vals = [];
    if (busca) { vals.push('%' + busca + '%'); conds.push('(nome ILIKE $' + vals.length + ' OR clube_atual ILIKE $' + vals.length + ' OR nacionalidade ILIKE $' + vals.length + ')'); }
    if (status) { vals.push(status); conds.push('status_prospeccao = $' + vals.length); }
    if (prioridade) { vals.push(prioridade); conds.push('prioridade = $' + vals.length); }
    if (posicao) { vals.push(posicao); conds.push('posicao = $' + vals.length); }
    const where = conds.length ? 'WHERE ' + conds.join(' AND ') : '';
    const SAFE = ['nome','status_prospeccao','prioridade','avaliacao_geral','clube_atual','criado_em'];
    const safeSort = SAFE.includes(sort) ? sort : 'criado_em';
    const safeOrder = order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';
    const filterVals = [...vals];
    vals.push(parseInt(limit, 10)); vals.push((parseInt(page, 10) - 1) * parseInt(limit, 10));
    const [rows, countRes] = await Promise.all([
      db.query('SELECT * FROM prospeccao ' + where + ' ORDER BY ' + safeSort + ' ' + safeOrder + ' LIMIT $' + (vals.length - 1) + ' OFFSET $' + vals.length, vals),
      db.query('SELECT COUNT(*) AS total FROM prospeccao ' + where, filterVals),
    ]);
    res.json({ sucesso: true, dados: rows.rows, total: parseInt(countRes.rows[0].total, 10), page: parseInt(page, 10), limit: parseInt(limit, 10) });
  } catch (err) {
    console.error('[prospeccao] GET /:', err);
    res.status(500).json({ sucesso: false, erro: 'Erro interno ao listar prospeccoes.' });
  }
});
// POST /
router.post('/', autenticar, autorizarPerfis('admin', 'gestor', 'scout'), async (req, res) => {
  try {
    const { nome, posicao, clube_atual, data_nascimento, nacionalidade, agente, observacoes,
      status_prospeccao = 'observacao', prioridade = 'media', avaliacao_geral = 0,
      valor_mercado = 0, salario_atual = 0, contrato_ate,
      attr_finalizacao = 0, attr_passe_curto = 0, attr_passe_longo = 0, attr_drible = 0,
      attr_cruzamento = 0, attr_cabeceio = 0, attr_controle = 0, attr_marcacao = 0, attr_desarme = 0,
      attr_velocidade = 0, attr_aceleracao = 0, attr_forca = 0, attr_resistencia = 0,
      attr_agilidade = 0, attr_salto = 0, attr_visao = 0, attr_decisao = 0,
      attr_posicionamento = 0, attr_criatividade = 0, attr_dedicacao = 0, attr_trabalho = 0,
      attr_defesas = 0, attr_reflexos = 0, attr_saida = 0, attr_comando = 0, attr_distribuicao = 0,
      stats_temporada, stats_jogos = 0, stats_gols = 0 } = req.body;
    if (!nome) return res.status(400).json({ sucesso: false, erro: 'Nome e obrigatorio.' });
    const r = await db.query(
      `INSERT INTO prospeccao (nome,posicao,clube_atual,data_nascimento,nacionalidade,agente,observacoes,
       status_prospeccao,prioridade,avaliacao_geral,valor_mercado,salario_atual,contrato_ate,
       attr_finalizacao,attr_passe_curto,attr_passe_longo,attr_drible,attr_cruzamento,
       attr_cabeceio,attr_controle,attr_marcacao,attr_desarme,attr_velocidade,attr_aceleracao,
       attr_forca,attr_resistencia,attr_agilidade,attr_salto,attr_visao,attr_decisao,
       attr_posicionamento,attr_criatividade,attr_dedicacao,attr_trabalho,
       attr_defesas,attr_reflexos,attr_saida,attr_comando,attr_distribuicao,
       stats_temporada,stats_jogos,stats_gols)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,
       $14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,
       $31,$32,$33,$34,$35,$36,$37,$38,$39,$40,$41,$42) RETURNING *`,
      [nome,posicao||null,clube_atual||null,data_nascimento||null,nacionalidade||null,agente||null,observacoes||null,
       status_prospeccao,prioridade,avaliacao_geral,valor_mercado,salario_atual,contrato_ate||null,
       attr_finalizacao,attr_passe_curto,attr_passe_longo,attr_drible,attr_cruzamento,
       attr_cabeceio,attr_controle,attr_marcacao,attr_desarme,attr_velocidade,attr_aceleracao,
       attr_forca,attr_resistencia,attr_agilidade,attr_salto,attr_visao,attr_decisao,
       attr_posicionamento,attr_criatividade,attr_dedicacao,attr_trabalho,
       attr_defesas,attr_reflexos,attr_saida,attr_comando,attr_distribuicao,
       stats_temporada||null,stats_jogos,stats_gols]);
    res.status(201).json({ sucesso: true, dados: r.rows[0] });
  } catch (err) {
    console.error('[prospeccao] POST /:', err);
    res.status(500).json({ sucesso: false, erro: 'Erro interno ao criar prospeccao.' });
  }
});
// PUT /:id
router.put('/:id', autenticar, autorizarPerfis('admin', 'gestor', 'scout'), async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    const { nome, posicao, clube_atual, data_nascimento, nacionalidade, agente, observacoes,
      status_prospeccao, prioridade, avaliacao_geral, valor_mercado, salario_atual, contrato_ate,
      attr_finalizacao, attr_passe_curto, attr_passe_longo, attr_drible, attr_cruzamento,
      attr_cabeceio, attr_controle, attr_marcacao, attr_desarme, attr_velocidade, attr_aceleracao,
      attr_forca, attr_resistencia, attr_agilidade, attr_salto, attr_visao, attr_decisao,
      attr_posicionamento, attr_criatividade, attr_dedicacao, attr_trabalho,
      attr_defesas, attr_reflexos, attr_saida, attr_comando, attr_distribuicao,
      stats_temporada, stats_jogos, stats_gols } = req.body;
    const r = await db.query(
      `UPDATE prospeccao SET nome=$1,posicao=$2,clube_atual=$3,data_nascimento=$4,nacionalidade=$5,
       agente=$6,observacoes=$7,status_prospeccao=$8,prioridade=$9,avaliacao_geral=$10,
       valor_mercado=$11,salario_atual=$12,contrato_ate=$13,
       attr_finalizacao=$14,attr_passe_curto=$15,attr_passe_longo=$16,attr_drible=$17,attr_cruzamento=$18,
       attr_cabeceio=$19,attr_controle=$20,attr_marcacao=$21,attr_desarme=$22,attr_velocidade=$23,attr_aceleracao=$24,
       attr_forca=$25,attr_resistencia=$26,attr_agilidade=$27,attr_salto=$28,attr_visao=$29,attr_decisao=$30,
       attr_posicionamento=$31,attr_criatividade=$32,attr_dedicacao=$33,attr_trabalho=$34,
       attr_defesas=$35,attr_reflexos=$36,attr_saida=$37,attr_comando=$38,attr_distribuicao=$39,
       stats_temporada=$40,stats_jogos=$41,stats_gols=$42,atualizado_em=NOW()
       WHERE id=$43 RETURNING *`,
      [nome,posicao||null,clube_atual||null,data_nascimento||null,nacionalidade||null,agente||null,observacoes||null,
       status_prospeccao,prioridade,avaliacao_geral,valor_mercado,salario_atual,contrato_ate||null,
       attr_finalizacao,attr_passe_curto,attr_passe_longo,attr_drible,attr_cruzamento,
       attr_cabeceio,attr_controle,attr_marcacao,attr_desarme,attr_velocidade,attr_aceleracao,
       attr_forca,attr_resistencia,attr_agilidade,attr_salto,attr_visao,attr_decisao,
       attr_posicionamento,attr_criatividade,attr_dedicacao,attr_trabalho,
       attr_defesas,attr_reflexos,attr_saida,attr_comando,attr_distribuicao,
       stats_temporada||null,stats_jogos,stats_gols,id]);
    if (!r.rows.length) return res.status(404).json({ sucesso: false, erro: 'Prospeccao nao encontrada.' });
    res.json({ sucesso: true, dados: r.rows[0] });
  } catch (err) {
    console.error('[prospeccao] PUT /:id:', err);
    res.status(500).json({ sucesso: false, erro: 'Erro interno ao atualizar prospeccao.' });
  }
});

// PATCH /:id/status
router.patch('/:id/status', autenticar, autorizarPerfis('admin', 'gestor', 'scout'), async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    const { status_prospeccao } = req.body;
    const ALLOWED = ['interesse', 'negociando', 'observacao', 'contratado', 'descartado'];
    if (!ALLOWED.includes(status_prospeccao)) return res.status(400).json({ sucesso: false, erro: 'Status invalido.' });
    const r = await db.query('UPDATE prospeccao SET status_prospeccao=$1,atualizado_em=NOW() WHERE id=$2 RETURNING *', [status_prospeccao, id]);
    if (!r.rows.length) return res.status(404).json({ sucesso: false, erro: 'Prospeccao nao encontrada.' });
    res.json({ sucesso: true, dados: r.rows[0] });
  } catch (err) {
    console.error('[prospeccao] PATCH /:id/status:', err);
    res.status(500).json({ sucesso: false, erro: 'Erro interno ao atualizar status.' });
  }
});

// DELETE /:id
router.delete('/:id', autenticar, autorizarPerfis('admin', 'gestor'), async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    const r = await db.query('DELETE FROM prospeccao WHERE id=$1 RETURNING id', [id]);
    if (!r.rows.length) return res.status(404).json({ sucesso: false, erro: 'Prospeccao nao encontrada.' });
    res.json({ sucesso: true, mensagem: 'Prospeccao removida com sucesso.' });
  } catch (err) {
    console.error('[prospeccao] DELETE /:id:', err);
    res.status(500).json({ sucesso: false, erro: 'Erro interno ao remover prospeccao.' });
  }
});

module.exports = router;
