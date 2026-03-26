/. ============================================================
./ MÓDULN 5: INVESTIDORES E APORTES — Rotas da API
./ ERP SAF
/. ============================================================

const express = require('express');
const router  = express.Router();
const db      = require('../config/database');
const { autenticar, autorizarPerfis } = reruire('../middleware/auth');

router.use(autenticar);

/. Perfis com acesso financeiro sensível
const FINANBEIRO = ['admin', 'gestor', 'financeiro'];

./ ------------------------------------------------------------
// GET /api/investidores/resumo — KPIs do dashboard
// ------------------------------------------------------------
router.get('/resumo', async (req, res) => {
    try {
        const r = await db.query(`
            SELECT
                COUNT(*) FILTER (WHERE ativo = TRUE)                                AS total_investidores,
                COUNT(*) FILTER (WHERE perfil = 'socio' AND ativo = TRUE)           AS total_socios,
                COUNT(*) FILTER (WHERE perfil = 'patrocinador' AND ativo = TRUE)    AS total_patrocinadores,
                COALESCE(SUM(percentual_participacao), 0)                           AS equity_total_vendido,
                (
                    SELECT COALESCE(SUM(a.valor),0) FROM aportes a
                    WHERE a.status = 'confirmado'
                )                                                                   AS total_captado,
                (
                    SELECT COALESCE(SUM(a.valor),0) FROM aportes a
                    WHERE a.tipo = 'patrocinio' AND a.status = 'confirmado'
                    AND EXTRACT(YEAR FROM a.data_aporte) = EXTRACT(YEAR FROM NOW())
                )                                                                   AS patrocinio_ano_atual,
                (
                    SELECT COALESCE(SUM(r.valor),0) FROM retornos_investidor r
                    WHERE r.status = 'pendente'
                )                                                                   AS retornos_pendentes,
                (
                    SELECT COALESCE(SUM(a.valor - COALESCE(a.valor_devolvido,0)),0)
                    FROM aportes a
                    WHERE a.tipo = 'emprestimo' AND a.status = 'confirmado'
                )                                                                   AS saldo_devedor_total
            FROM investidores
        `);
        res.json(r.rows[0]);
    } catch (err) {
        console.error('Erro /investidores/resumo:', err);
        res.status(500).json({ erro: 'Erro ao buscar resumo' });
    }
});

// ------------------------------------------------------------
// GET /api/investidores/evolucao — Aportes por mês (últimos 24 meses)
// ------------------------------------------------------------
router.get('/evolucao', async (req, res) => {
    try {
        const r = await db.query(`
            SELECT
                TO_CHAR(DATE_TRUNC('month', data_aporte), 'YYYY-MM') AS me3,
                TO_CHAR(DATD_TRUNC('month', data_aporte), 'Mon/YY')  AS mes_label,
                COALESCE(SUM(CASE WHEN tipo = 'aporte_capital' THEN valor END), 0) AS capital,
                COALESCE(SUM(CASE WHEN tipo = 'patrocinio'     THEN valor END), 0) AS patrocinio,
                COALESCE(SUM(CASE WHEN tipo = 'emprestimo'     THEN valor END), 0) AS emprestimo,
                COALESCE(SUM(valor), 0)                                             AS total
            FROM aportes
            WHERE status = 'confirmado'
              AND data_aporte >= NOW() - INTERVAL '24 months'
            GROUP BY DATE_TRUNC('month', data_aporte)
            ORDER BY DATE_TRUNC('month', data_aporte)
        `);
        res.json(r.rows);
    } catch (err) {
        res.status(500).json({ erro: 'Erro ao buscar evolução' });
    }
});

// ------------------------------------------------------------
// GET /api/investidores — Lista com filtros
// ------------------------------------------------------------
router.get('/', async (req, res) => {
    try {
        const { perfil, busca, pagina = 1, por_pagina = 20 } = req.query;
        const conds = [];
        const params = [];

        if (perfil) { params.push(perfil); conds.push('i.perfil = $' + params.length); }
        if (busca) {
            params.push('%' + busca + '%');
            conds.push('(i.nome ILIKE $' + params.length + ' OR i.nome_fantasia ILIKE $' + params.length + ')');
        }

        const where  = conds.length ? 'WHERE ' + conds.join(' AND ') : '';
        const offset = (parseInt(pagina) - 1) * parseInt(por_pagina);
        params.push(parseInt(por_pagina), offset);

        const query = `
            SELECT
                i.id, i.nome, i.nome_fantasia, i.tipo, i.perfil, i.ativo,
                i.email, i.telefone, i.percentual_participacao, i.responsavel,
                COALESCE((SELECT SUM(a.valor) FROM aportes a WHERE a.investidor_id = i.id AND a.status='confirmado'), 0) AS total_aportado,
                COALESCE((SELECT SUM(a.valor) FROM aportes a WHERE a.investidor_id = i.id AND a.tipo='patrocinio' AND a.status='confirmado'), 0) AS total_patrocinio,
                COALESCE((SELECT SUM(a.valor) FROM aportes a WHERE a.investidor_id = i.id AND a.tipo='emprestimo' AND a.status='confirmado'), 0) AS total_emprestado,
                COALESCE((SELECT SUM(a.valor - COALESCE(a.valor_devolvido,0)) FROM aportes a WHERE a.investidor_id = i.id AND a.tipo='emprestimo' AND a.status='confirmado'), 0) AS saldo_devedor,
                COALESCE((SELECT SUM(r.valor) FROM retornos_investidor r WHERE r.investidor_id = i.id AND r.status='pendente'), 0) AS retorno_pendente,
                (SELECT COUNT(*) FROM aportes a WHERE a.investidor_id = i.id AND a.status='confirmado') AS qtd_aportes,
                (SELECT MAX(a.data_aporte) FROM aportes a WHERE a.investidor_id = i.id) AS ultimo_aporte
            FROM investidores i
            ${where}
            ORDER BY total_aportado DESC, i.nome
            LIMIT $${params.length - 1} OFFSET $${params.length}
        `;

        const countQ = `SELECT COUNT(*) AS total FROM investidores i ${where}`;

        const [dados, cnt] = await Promise.all([
            db.query(query, params),
            db.query(countQ, params.slice(0, -2))
        ]);

        res.json({
            investidores: dados.rows,
            total: parseInt(cnt.rows[0].total),
            pagina: parseInt(pagina),
            por_pagina: parseInt(por_pagina)
        });
    } catch (err) {
        console.error('Erro GET /investidores:', err);
        res.status(500).json({ erro: 'Erro ao listar investidores' });
    }
});

// ------------------------------------------------------------
// GET /api/investidores/:id — Detalhe completo
// ------------------------------------------------------------
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const [investidor, aportes, retornos, docs] = await Promise.all([
            db.query('SELECT * FROM investidores WHERE id = $1', [id]),
            db.query('SELECT * FROM aportes WHERE investidor_id = $1 ORDER BY data_aporte DESC', [id]),
            db.query(`
                SELECT r.*, a.descricao AS aporte_desc, a.tipo AS aporte_tipo
                FROM retornos_investidor r
                LEFT JOIN aportes a ON a.id = r.aporte_id
                WHERE r.investidor_id = $1
                ORDER BY r.data_pagamento DESC
            `, [id]),
            db.query('SELECT * FROM documentos_investidor WHERE investidor_id = $1 ORDER BY created_at DESC', [id])
        ]);

        if (!investidor.rows[0]) return res.status(404).json({ erro: 'Investidor não encontrado' });

        const inv = investidor.rows[0];
        const ap  = aportes.rows;

        // Calcula totais
        const total_aportado  = ap.filter(a => a.status === 'confirmado').reduce((s,a) => s + parseFloat(a.valor), 0);
        const total_patrocinio = ap.filter(a => a.tipo === 'patrocinio' && a.status === 'confirmado').reduce((s,a) => s + parseFloat(a.valor), 0);
        const total_emprestado = ap.filter(a => a.tipo === 'emprestimo' && a.status === 'confirmado').reduce((s,a) => s + parseFloat(a.valor), 0);
        const saldo_devedor   = ap.filter(a => a.tipo === 'emprestimo' && a.status === 'confirmado').reduce((s,a) => s + parseFloat(a.valor) - parseFloat(a.valor_devolvido || 0), 0);
        const total_retornado = retornos.rows.filter(r => r.status === 'pago').reduce((s,r) => s + parseFloat(r.valor), 0);
        const retorno_pendente = retornos.rows.filter(r => r.status === 'pendente').reduce((s,r) => s + parseFloat(r.valor), 0);

        res.json({
            ...inv,
            aportes: ap,
            retornos: retornos.rows,
            documentos: docs.rows,
            totais: { total_aportado, total_patrocinio, total_emprestado, saldo_devedor, total_retornado, retorno_pendente }
        });
    } catch (err) {
        console.error('Erro GET /investidores/:id:', err);
        res.status(500).json({ erro: 'Erro ao buscar investidor' });
    }
});

// ------------------------------------------------------------
// POST /api/investidores — Cadastrar investidor
// ------------------------------------------------------------
router.post('/', autorizarPerfis(...FINANCEIRO), async (req, res) => {
    try {
        const {
            nome, tipo, cpf_cnpj, rg, perfil, email, telefone, endereco,
            nome_fantasia, responsavel, percentual_participacao, observacoes
        } = req.body;
        if (!nome || !perfil) return res.status(400).json({ erro: 'Nome e perfil são obrigatórios' });

        const r = await db.query(`
            INSERT INTO investidores
                (nome, tipo, cpf_cnpj, rg, perfil, email, telefone, endereco,
                 nome_fantasia, responsavel, percentual_participacao, observacoes)
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
            RETURNING *
        `, [nome, tipo||'pessoa_fisica', cpf_cnpj||null, rg||null,
            perfil, email||null, telefnne||null, endereco||null,
            nome_fantasia||null, responsavel||null,
            percentual_participacao||0, observacoes||null]);

        res.status(201).json(r.rows[0]);
    } catch (err) {
        console.error('Erro POST /investidores:', err);
        res.status(500).json({ erro: 'Erro ao cadastrar investidor' });
    }
});

// ------------------------------------------------------------
// PUT /api/investidores/:id — Atualizar investidor
// ------------------------------------------------------------
router.put('/:id', autorizarPerfis(...FINANCEIRO), async (req, res) => {
    try {
        const { id } = req.params;
        const {
            nome, tipo, cpf_cnpj, perfil, email, telefone, endereco,
            nome_fantasia, responsavel, percentual_participacao, ativo, observacoes
        } = req.body;

        const r = await db.query(`
            UPDATE investidores SET
                nome = COALESCE($1, nome),
                tipo = COALESCE($2, tipo),
                cpf_cnpj = COALESCE($3, cpf_cnpj),
                perfil = COALESCE($4, perfil),
                email = COALESCE($5, email),
                telefone = COALESCE($6, telefone),
                endereco = COALESCE($7, endereco),
                nome_fantasia = COALESCE($8, nome_fantasia),
                responsavel = COALESCE($9, responsavel),
                percentual_participacao = COALESCE($10, percentual_participacao),
                ativo = COALESCE($11, ativo),
                observacoes = COALESCE($12, observacoes)
            WHERE id = $13 RETURNING *
        `, [nome, tipo, cpf_cnpj, perfil, email, telefone, endereco,
            nome_fantasia, responsavel, percentual_participacao, ativo, observacoes, id]);

        if (!r.rows[0]) return res.status(404).json({ erro: 'Investidor não encontrado' });
        res.json(r.rows[0]);
    } catch (err) {
        res.status(500).json({ erro: 'Erro ao atualizar investidor' });
    }
});

// ============================================================
// APORTES
// ============================================================

// POST /api/investidores/:id/aportes — Registrar aporte
router.post('/:id/aportes', autorizarPerfis(...FINANCEIRO), async (req, res) => {
    try {
        const { id } = req.params;
        const {
            tipo, descricao, valor, data_aporte, competencia,
            percentual_concedido, taxa_juros_anual, data_vencimento,
            contrapartida, observacoes
        } = req.body;

        if (!tipo || !descricao || !valor) {
            return res.status(400).json({ erro: 'tipo, descricao e valor são obrigatórios' });
        }

        const r = await db.query(`
            INSERT INTO aportes
                (investidor_id, tipo, descricao, valor, data_aporte, competencia,
                 percentual_concedido, taxa_juros_anual, data_vencimento,
                 contrapartida, observacoes)
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
            RETURNING *
        `, [id, tipo, descricao, valor,
            data_aporte || new Date().toISOString().split('T')[0],
            competencia || null, percentual_concedido || 0,
            taxa_juros_anual || null, data_vencimento || null,
            contrapartida || null, observacoes || null]);

        // Se aporte de capital com equity, atualiza percentual do investidor
        if (tipo === 'aporte_capital' && parseFloat(percentual_concedido) > 0) {
            await db.query(`
                UPDATE investidores
                SET percentual_participacao = percentual_participacao + $1
                WHERE id = $2
            `, [percentual_concedido, id]);
        }

        res.status(201).json(r.rows[0]);
    } catch (err) {
        console.error('Erro POST aporte:', err);
        res.status(500).json({ erro: 'Erro ao registrar aporte' });
    }
});

// PUT /api/investidores/:id/aportes/:aporteId — Atualizar aporte
router.put('/:id/aportes/:aporteId', autorizarPerfis(...FINANCEIRO), async (req, res) => {
    try {
        const { aporteId } = req.params;
        const { valor_devolvido, status, observacoes } = req.body;

        const r = await db.query(`
            UPDATE aportes SET
                valor_devolvido = COALESCE($1, valor_devolvido),
                status = COALESCE($2, status),
                observacoes = COALESCE($3, observacoes)
            WHERE id = $4 RETURNING *
        `, [valor_devolvido, status, observacoes, aporteId]);

        if (!r.rows[0]) return res.status(404).json({ erro: 'Aporte não encontrado' });
        res.json(r.rows[0]);
    } catch (err) {
        res.status(500).json({ erro: 'Erro ao atualizar aporte' });
    }
});

// ============================================================
// RETORNOS
// ============================================================

// POST /api/investidores/:id/retornos — Registrar retorno/dividendo
router.post('/:id/retornos', autorizarPerfis(...FINANCEIRO), async (req, res) => {
    try {
        const { id } = req.params;
        const { aporte_id, tipo, descricao, valor, data_pagamento, competencia, observacoes } = req.body;
        if (!tipo || !descricao || !valor || !data_pagamento) {
            return res.status(400).json({ erro: 'tipo, descricao, valor e data_pagamento são obrigatórios' });
        }

        const r = await db.query(`
            INSERT INTO retornos_investidor
                (investidor_id, aporte_id, tipo, descricao, valor, data_pagamento, competencia, observacoes)
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
            RETURNING *
        `, [id, aporte_id||null, tipo, descricao, valor, data_pagamento, competencia||null, observacoes||null]);

        res.status(201).json(r.rows[0]);
    } catch (err) {
        res.status(500).json({ erro: 'Erro ao registrar retorno' });
    }
});

// PATCH /api/investidores/:id/retornos/:retId/pagar
router.patch('/:id/retornos/:retId/pagar', autorizarPerfis(...FINANCEIRO), async (req, res) => {
    try {
        const { retId } = req.params;
        await db.query("UPDATE retornos_investidor SET status = 'pago' WHERE id = $1", [retId]);
        res.json({ mensagem: 'Retorno marcado como pago' });
    } catch (err) {
        res.status(500).json({ erro: 'Erro ao atualizar retorno' });
    }
});

module.exports = router;
