const express = require('express');
const router  = express.Router();
const db      = require('../config/database');
const { autenticarToken, autorizarPerfis } = require('../middleware/auth');

router.use(autenticarToken);

// ── RESUMO EXECUTIVO ────────────────────────────────────────────
router.get('/executivo', async (req, res) => {
  try {
    const { rows } = await db.query('SELECT * FROM vw_resumo_executivo');
    const dados = rows[0] || {};

    // Folha total consolidada
    dados.folha_total = (parseFloat(dados.folha_atletas) || 0) +
                        (parseFloat(dados.folha_funcionarios) || 0);
    dados.resultado_mes = (parseFloat(dados.receita_mes) || 0) -
                          (parseFloat(dados.despesa_mes) || 0);
    dados.resultado_ano = (parseFloat(dados.receita_ano) || 0) -
                          (parseFloat(dados.despesa_ano) || 0);

    res.json({ sucesso: true, dados });
  } catch (err) {
    console.error(err);
    res.status(500).json({ sucesso: false, erro: err.message });
  }
});

// ── RELATÓRIO FINANCEIRO ────────────────────────────────────────
router.get('/financeiro', async (req, res) => {
  try {
    const { periodo_ini, periodo_fim, categoria } = req.query;

    // Evolução mensal
    const evolucao = await db.query('SELECT * FROM vw_evolucao_financeira');

    // Transações do período
    let filtros = ['1=1'];
    const params = [];
    if (periodo_ini) { params.push(periodo_ini); filtros.push(`data_transacao >= $${params.length}`); }
    if (periodo_fim) { params.push(periodo_fim); filtros.push(`data_transacao <= $${params.length}`); }
    if (categoria)   { params.push(categoria);   filtros.push(`categoria = $${params.length}`); }

    const transacoes = await db.query(
      `SELECT t.*, u.nome AS usuario_nome
       FROM transacoes t
       LEFT JOIN usuarios u ON u.id = t.criado_por
       WHERE ${filtros.join(' AND ')}
       ORDER BY data_transacao DESC
       LIMIT 200`,
      params
    );

    // Totais por categoria
    const porCategoria = await db.query(
      `SELECT categoria, tipo,
              COUNT(*) AS qtd,
              SUM(valor) AS total
       FROM transacoes
       WHERE ${filtros.join(' AND ')}
       GROUP BY categoria, tipo
       ORDER BY total DESC`,
      params
    );

    // KPIs do período
    const kpis = await db.query(
      `SELECT
         SUM(CASE WHEN tipo='receita' THEN valor ELSE 0 END) AS receita_total,
         SUM(CASE WHEN tipo='despesa' THEN valor ELSE 0 END) AS despesa_total,
         COUNT(CASE WHEN tipo='receita' THEN 1 END)          AS qtd_receitas,
         COUNT(CASE WHEN tipo='despesa' THEN 1 END)          AS qtd_despesas
       FROM transacoes
       WHERE ${filtros.join(' AND ')}`,
      params
    );

    res.json({
      sucesso: true,
      evolucao: evolucao.rows,
      transacoes: transacoes.rows,
      por_categoria: porCategoria.rows,
      kpis: kpis.rows[0]
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ sucesso: false, erro: err.message });
  }
});

// ── RELATÓRIO DE FOLHA ──────────────────────────────────────────
router.get('/folha', async (req, res) => {
  try {
    const { categoria } = req.query; // atleta | funcionario

    let sql = 'SELECT * FROM vw_folha_consolidada';
    const params = [];
    if (categoria) { params.push(categoria); sql += ` WHERE categoria = $1`; }
    sql += ' ORDER BY categoria, salario_bruto DESC';

    const { rows: pessoas } = await db.query(sql, params);

    // Totais
    const totais = pessoas.reduce((acc, p) => {
      acc.bruto        += parseFloat(p.salario_bruto)    || 0;
      acc.carteira     += parseFloat(p.salario_carteira) || 0;
      acc.complemento  += parseFloat(p.complemento)     || 0;
      acc[p.categoria] = (acc[p.categoria] || 0) + 1;
      return acc;
    }, { bruto: 0, carteira: 0, complemento: 0 });

    // Distribuição por departamento/posição
    const distribuicao = await db.query(`
      SELECT 'posicao' AS agrupador, posicao AS grupo,
             COUNT(*) AS qtd, SUM(ca.salario_bruto) AS folha
      FROM atletas a
      JOIN contratos_atleta ca ON ca.id = (
          SELECT id FROM contratos_atleta WHERE atleta_id=a.id AND status='ativo' LIMIT 1
      )
      WHERE a.status='ativo'
      GROUP BY posicao
      UNION ALL
      SELECT 'departamento', d.nome,
             COUNT(*), SUM(f.salario)
      FROM funcionarios f
      JOIN departamentos d ON d.id = f.departamento_id
      WHERE f.status='ativo'
      GROUP BY d.nome
      ORDER BY agrupador, folha DESC
    `);

    res.json({
      sucesso: true,
      pessoas,
      totais,
      distribuicao: distribuicao.rows
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ sucesso: false, erro: err.message });
  }
});

// ── RELATÓRIO ESPORTIVO ─────────────────────────────────────────
router.get('/esportivo', async (req, res) => {
  try {
    const { temporada } = req.query;

    const ano = temporada || new Date().getFullYear().toString();

    // Performance por competição
    const performance = await db.query(
      `SELECT * FROM vw_performance_esportiva WHERE temporada = $1`, [ano]
    );

    // Artilharia
    const artilharia = await db.query(
      `SELECT a.id, a.nome, a.posicao,
              SUM(ea.gols) AS gols, SUM(ea.assistencias) AS assistencias,
              SUM(ea.jogos) AS jogos, SUM(ea.clean_sheets) AS clean_sheets,
              SUM(ea.cartoes_amarelos) AS amarelos,
              SUM(ea.cartoes_vermelhos) AS vermelhos
       FROM atletas a
       JOIN estatisticas_atleta ea ON ea.atleta_id = a.id AND ea.temporada = $1
       GROUP BY a.id, a.nome, a.posicao
       ORDER BY gols DESC, assistencias DESC`,
      [ano]
    );

    // Metas esportivas
    const metas = await db.query(
      `SELECT m.*, mc.percentual, mc.dias_restantes
       FROM metas_completo mc
       JOIN metas m ON m.id = mc.id
       WHERE m.tipo = 'esportiva' AND m.temporada = $1
       ORDER BY mc.percentual DESC`,
      [ano]
    );

    // Atletas por status
    const statusAtletas = await db.query(
      `SELECT status, COUNT(*) AS qtd FROM atletas GROUP BY status ORDER BY qtd DESC`
    );

    res.json({
      sucesso: true,
      temporada: ano,
      performance: performance.rows,
      artilharia: artilharia.rows,
      metas: metas.rows,
      status_atletas: statusAtletas.rows
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ sucesso: false, erro: err.message });
  }
});

// ── RELATÓRIO DE INVESTIDORES ───────────────────────────────────
router.get('/investidores', async (req, res) => {
  try {
    // Resumo por investidor
    const { rows: investidores } = await db.query(
      `SELECT * FROM investidores_completo ORDER BY total_aportado DESC`
    );

    // Evolução aportes mensais (últimos 12 meses)
    const { rows: evolucao } = await db.query(`
      SELECT
        TO_CHAR(DATE_TRUNC('month', data_aporte), 'YYYY-MM') AS mes,
        TO_CHAR(DATE_TRUNC('month', data_aporte), 'Mon/YY')  AS mes_label,
        SUM(CASE WHEN tipo='aporte_capital' THEN valor ELSE 0 END) AS capital,
        SUM(CASE WHEN tipo='patrocinio'     THEN valor ELSE 0 END) AS patrocinio,
        SUM(CASE WHEN tipo='emprestimo'     THEN valor ELSE 0 END) AS emprestimo,
        SUM(CASE WHEN tipo='doacao'         THEN valor ELSE 0 END) AS doacao,
        SUM(valor) AS total
      FROM aportes
      WHERE data_aporte >= CURRENT_DATE - INTERVAL '12 months'
      GROUP BY DATE_TRUNC('month', data_aporte)
      ORDER BY DATE_TRUNC('month', data_aporte)
    `);

    // Retornos pendentes
    const { rows: retornosPendentes } = await db.query(`
      SELECT r.*, i.nome AS investidor_nome
      FROM retornos_investidor r
      JOIN investidores i ON i.id = r.investidor_id
      WHERE r.status = 'pendente'
      ORDER BY r.data_prevista
    `);

    // Equity distribution
    const { rows: equity } = await db.query(`
      SELECT nome, percentual_participacao, perfil
      FROM investidores
      WHERE percentual_participacao > 0
      ORDER BY percentual_participacao DESC
    `);

    // Totais gerais
    const { rows: totais } = await db.query(`
      SELECT
        SUM(CASE WHEN tipo='aporte_capital' THEN valor ELSE 0 END) AS total_capital,
        SUM(CASE WHEN tipo='patrocinio'     THEN valor ELSE 0 END) AS total_patrocinio,
        SUM(CASE WHEN tipo='emprestimo'     THEN valor ELSE 0 END) AS total_emprestimo,
        SUM(CASE WHEN tipo='doacao'         THEN valor ELSE 0 END) AS total_doacao,
        SUM(valor) AS total_geral
      FROM aportes
    `);

    res.json({
      sucesso: true,
      investidores,
      evolucao,
      retornos_pendentes: retornosPendentes,
      equity,
      totais: totais[0]
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ sucesso: false, erro: err.message });
  }
});

// ── RELATÓRIO DE COMPRAS ────────────────────────────────────────
router.get('/compras', async (req, res) => {
  try {
    const { periodo_ini, periodo_fim } = req.query;

    let filtro = '1=1';
    const params = [];
    if (periodo_ini) { params.push(periodo_ini); filtro += ` AND pc.created_at >= $${params.length}`; }
    if (periodo_fim) { params.push(periodo_fim); filtro += ` AND pc.created_at <= $${params.length}`; }

    // Pedidos no período
    const { rows: pedidos } = await db.query(
      `SELECT p.*, f.nome AS fornecedor_nome
       FROM pedidos_completo p
       LEFT JOIN fornecedores f ON f.id = p.fornecedor_id
       WHERE ${filtro.replace(/pc\./g, 'p.')}
       ORDER BY p.created_at DESC`,
      params
    );

    // Por status
    const { rows: porStatus } = await db.query(`
      SELECT status, COUNT(*) AS qtd,
             COALESCE(SUM(valor_total_estimado),0) AS valor_total
      FROM pedidos_completo
      GROUP BY status ORDER BY qtd DESC
    `);

    // Por departamento
    const { rows: porDepto } = await db.query(`
      SELECT departamento, COUNT(*) AS qtd,
             COALESCE(SUM(valor_total_estimado),0) AS valor_total
      FROM pedidos_completo
      GROUP BY departamento ORDER BY valor_total DESC
    `);

    // Ranking fornecedores
    const { rows: fornecedores } = await db.query(
      'SELECT * FROM vw_ranking_fornecedores LIMIT 10'
    );

    res.json({
      sucesso: true,
      pedidos,
      por_status: porStatus,
      por_departamento: porDepto,
      ranking_fornecedores: fornecedores
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ sucesso: false, erro: err.message });
  }
});

// ── LOG DE RELATÓRIO GERADO ────────────────────────────────────
router.post('/log', async (req, res) => {
  try {
    const { tipo, periodo_ini, periodo_fim, parametros } = req.body;
    await db.query(
      `INSERT INTO relatorios_gerados (tipo, periodo_ini, periodo_fim, gerado_por, parametros)
       VALUES ($1, $2, $3, $4, $5)`,
      [tipo, periodo_ini || null, periodo_fim || null, req.usuario.id, parametros ? JSON.stringify(parametros) : null]
    );
    res.json({ sucesso: true });
  } catch (err) {
    res.status(500).json({ sucesso: false, erro: err.message });
  }
});

module.exports = router;
