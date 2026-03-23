// ============================================================
// MÓDULO 6: METAS — Rotas da API
// ERP SAF
// ============================================================

const express = require('express');
const router  = express.Router();
const db      = require('../config/database');
const { autenticar, autorizarPerfis } = require('../middleware/auth');

router.use(autenticar);

// ------------------------------------------------------------
// GET /api/metas/resumo — KPIs do dashboard
// ------------------------------------------------------------
router.get('/resumo', async (req, res) => {
    try {
        const { temporada = new Date().getFullYear().toString() } = req.query;
        const r = await db.query(`
            SELECT
                COUNT(*)                                        AS total,
                COUNT(*) FILTER (WHERE status = 'ativa')       AS ativas,
                COUNT(*) FILTER (WHERE status = 'concluida')   AS concluidas,
                COUNT(*) FILTER (WHERE status = 'nao_atingida')AS nao_atingidas,
                COUNT(*) FILTER (WHERE tipo = 'esportiva'  AND status = 'ativa') AS esportivas_ativas,
                COUNT(*) FILTER (WHERE tipo = 'financeira' AND status = 'ativa') AS financeiras_ativas,
                -- % médio de progresso das metas ativas
                ROUND(AVG(
                    CASE
                        WHEN valor_meta = 0 THEN 0
                        WHEN sentido = 'abaixo' THEN GREATEST(0, LEAST(100, (1 - valor_atual/valor_meta)*100))
                        ELSE LEAST(100, (valor_atual/valor_meta)*100)
                    END
                ) FILTER (WHERE status = 'ativa'), 1)          AS progresso_medio,
                -- metas críticas: ativas, alta prioridade, abaixo de 50%
                COUNT(*) FILTER (
                    WHERE status = 'ativa' AND prioridade = 'alta'
                    AND (
                        CASE
                            WHEN sentido = 'abaixo' THEN (1 - valor_atual/NULLIF(valor_meta,0))*100
                            ELSE (valor_atual/NULLIF(valor_meta,0))*100
                        END
                    ) < 50
                )                                              AS criticas
            FROM metas
            WHERE temporada = $1
        `, [temporada]);
        res.json(r.rows[0]);
    } catch (err) {
        console.error('Erro /metas/resumo:', err);
        res.status(500).json({ erro: 'Erro ao buscar resumo' });
    }
});

// ------------------------------------------------------------
// GET /api/metas — Lista com filtros
// ------------------------------------------------------------
router.get('/', async (req, res) => {
    try {
        const { tipo, status, prioridade, temporada = new Date().getFullYear().toString(), busca } = req.query;
        const conds = ['m.temporada = $1'];
        const params = [temporada];

        if (tipo)      { params.push(tipo);      conds.push('m.tipo = $'      + params.length); }
        if (status)    { params.push(status);    conds.push('m.status = $'    + params.length); }
        if (prioridade){ params.push(prioridade);conds.push('m.prioridade = $'+ params.length); }
        if (busca)     { params.push('%'+busca+'%'); conds.push('m.titulo ILIKE $'+params.length); }

        const where = 'WHERE ' + conds.join(' AND ');

        const r = await db.query(`
            SELECT
                m.*,
                u.nome AS responsavel_nome,
                a.nome AS atleta_nome, a.nome_guerra AS atleta_guerra,
                CASE
                    WHEN m.valor_meta = 0 THEN 0
                    WHEN m.sentido = 'abaixo'
                        THEN GREATEST(0, LEAST(100, ROUND((1 - m.valor_atual/m.valor_meta)*100)))
                    ELSE LEAST(100, ROUND((m.valor_atual/m.valor_meta)*100))
                END AS percentual,
                (m.data_fim - CURRENT_DATE) AS dias_restantes,
                (SELECT COUNT(*) FROM atualizacoes_meta am WHERE am.meta_id = m.id) AS qtd_atualizacoes
            FROM metas m
            LEFT JOIN usuarios u ON u.id = m.responsavel_id
            LEFT JOIN atletas  a ON a.id = m.atleta_id
            ${where}
            ORDER BY
                CASE m.prioridade WHEN 'alta' THEN 1 WHEN 'media' THEN 2 ELSE 3 END,
                CASE m.status WHEN 'ativa' THEN 1 WHEN 'concluida' THEN 2 ELSE 3 END,
                m.tipo, m.titulo
        `, params);

        res.json(r.rows);
    } catch (err) {
        console.error('Erro GET /metas:', err);
        res.status(500).json({ erro: 'Erro ao listar metas' });
    }
});

// ------------------------------------------------------------
// GET /api/metas/:id — Detalhe com histórico de atualizações
// ------------------------------------------------------------
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const [meta, hist] = await Promise.all([
            db.query(`
                SELECT m.*, u.nome AS responsavel_nome,
                    a.nome AS atleta_nome, a.nome_guerra AS atleta_guerra,
                    CASE
                        WHEN m.valor_meta = 0 THEN 0
                        WHEN m.sentido = 'abaixo'
                            THEN GREATEST(0, LEAST(100, ROUND((1 - m.valor_atual/m.valor_meta)*100)))
                        ELSE LEAST(100, ROUND((m.valor_atual/m.valor_meta)*100))
                    END AS percentual,
                    (m.data_fim - CURRENT_DATE) AS dias_restantes
                FROM metas m
                LEFT JOIN usuarios u ON u.id = m.responsavel_id
                LEFT JOIN atletas  a ON a.id = m.atleta_id
                WHERE m.id = $1
            `, [id]),
            db.query(`
                SELECT am.*, u.nome AS usuario_nome
                FROM atualizacoes_meta am
                LEFT JOIN usuarios u ON u.id = am.usuario_id
                WHERE am.meta_id = $1
                ORDER BY am.created_at DESC
            `, [id])
        ]);
        if (!meta.rows[0]) return res.status(404).json({ erro: 'Meta não encontrada' });
        res.json({ ...meta.rows[0], historico: hist.rows });
    } catch (err) {
        res.status(500).json({ erro: 'Erro ao buscar meta' });
    }
});

// ------------------------------------------------------------
// POST /api/metas — Criar meta
// ------------------------------------------------------------
router.post('/', autorizarPerfis('admin', 'gestor'), async (req, res) => {
    try {
        const {
            titulo, descricao, tipo, categoria, temporada,
            valor_meta, valor_atual, unidade, sentido,
            data_inicio, data_fim, prioridade,
            responsavel_id, atleta_id, observacoes
        } = req.body;

        if (!titulo || !tipo || !categoria || !valor_meta || !data_fim) {
            return res.status(400).json({ erro: 'titulo, tipo, categoria, valor_meta e data_fim são obrigatórios' });
        }

        const r = await db.query(`
            INSERT INTO metas
                (titulo, descricao, tipo, categoria, temporada,
                 valor_meta, valor_atual, unidade, sentido,
                 data_inicio, data_fim, prioridade,
                 responsavel_id, atleta_id, observacoes)
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)
            RETURNING *
        `, [titulo, descricao||null, tipo, categoria,
            temporada||new Date().getFullYear().toString(),
            valor_meta, valor_atual||0, unidade||'',
            sentido||'acima', data_inicio||new Date().toISOString().split('T')[0],
            data_fim, prioridade||'media',
            responsavel_id||null, atleta_id||null, observacoes||null]);

        res.status(201).json(r.rows[0]);
    } catch (err) {
        console.error('Erro POST /metas:', err);
        res.status(500).json({ erro: 'Erro ao criar meta' });
    }
});

// ------------------------------------------------------------
// PUT /api/metas/:id — Editar meta
// ------------------------------------------------------------
router.put('/:id', autorizarPerfis('admin', 'gestor'), async (req, res) => {
    try {
        const { id } = req.params;
        const { titulo, descricao, valor_meta, valor_atual, data_fim, prioridade, status, observacoes, unidade } = req.body;

        const r = await db.query(`
            UPDATE metas SET
                titulo      = COALESCE($1, titulo),
                descricao   = COALESCE($2, descricao),
                valor_meta  = COALESCE($3, valor_meta),
                valor_atual = COALESCE($4, valor_atual),
                data_fim    = COALESCE($5, data_fim),
                prioridade  = COALESCE($6, prioridade),
                status      = COALESCE($7, status),
                observacoes = COALESCE($8, observacoes),
                unidade     = COALESCE($9, unidade)
            WHERE id = $10 RETURNING *
        `, [titulo, descricao, valor_meta, valor_atual, data_fim, prioridade, status, observacoes, unidade, id]);

        if (!r.rows[0]) return res.status(404).json({ erro: 'Meta não encontrada' });
        res.json(r.rows[0]);
    } catch (err) {
        res.status(500).json({ erro: 'Erro ao atualizar meta' });
    }
});

// ------------------------------------------------------------
// PATCH /api/metas/:id/atualizar — Registrar novo progresso
// ------------------------------------------------------------
router.patch('/:id/atualizar', async (req, res) => {
    try {
        const { id } = req.params;
        const { valor_novo, descricao } = req.body;

        if (valor_novo === undefined || valor_novo === null) {
            return res.status(400).json({ erro: 'valor_novo é obrigatório' });
        }

        const atual = await db.query('SELECT valor_atual, valor_meta, sentido FROM metas WHERE id = $1', [id]);
        if (!atual.rows[0]) return res.status(404).json({ erro: 'Meta não encontrada' });

        const { valor_atual, valor_meta, sentido } = atual.rows[0];

        // Verifica se a meta foi atingida
        const atingida = sentido === 'abaixo'
            ? parseFloat(valor_novo) <= parseFloat(valor_meta)
            : parseFloat(valor_novo) >= parseFloat(valor_meta);

        await db.query(`
            UPDATE metas SET
                valor_atual = $1,
                status = CASE WHEN $2 THEN 'concluida' ELSE status END
            WHERE id = $3
        `, [valor_novo, atingida, id]);

        await db.query(`
            INSERT INTO atualizacoes_meta (meta_id, usuario_id, valor_anterior, valor_novo, descricao)
            VALUES ($1, $2, $3, $4, $5)
        `, [id, req.usuario.id, valor_atual, valor_novo, descricao || null]);

        res.json({
            mensagem: atingida ? '🎉 Meta atingida!' : 'Progresso atualizado',
            atingida,
            valor_novo,
            valor_anterior: valor_atual
        });
    } catch (err) {
        console.error('Erro PATCH atualizar:', err);
        res.status(500).json({ erro: 'Erro ao atualizar progresso' });
    }
});

// PATCH /api/metas/:id/status — Encerrar/Cancelar meta manualmente
router.patch('/:id/status', autorizarPerfis('admin', 'gestor'), async (req, res) => {
    try {
        const { id } = req.params;
        const { status, observacoes } = req.body;
        const validos = ['ativa','concluida','nao_atingida','cancelada'];
        if (!validos.includes(status)) return res.status(400).json({ erro: 'Status inválido' });

        await db.query('UPDATE metas SET status = $1, observacoes = COALESCE($2, observacoes) WHERE id = $3', [status, observacoes, id]);
        res.json({ mensagem: 'Status atualizado' });
    } catch (err) {
        res.status(500).json({ erro: 'Erro ao atualizar status' });
    }
});

module.exports = router;
