// ============================================================
// MÃDULO 4: ATLETAS â Rotas da API
// ERP SAF
// ============================================================

const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { autenticar, autorizarPerfis } = require('../middleware/auth');

router.use(autenticar);

// ------------------------------------------------------------
// GET /api/atletas/resumo â KPIs do dashboard
// ------------------------------------------------------------
router.get('/resumo', async (req, res) => {
    try {
        const r = await db.query(`
            SELECT
                COUNT(*) FILTER (WHERE a.status = 'ativo')          AS ativos,
                COUNT(*) FILTER (WHERE a.status = 'lesionado')       AS lesionados,
                COUNT(*) FILTER (WHERE a.status = 'suspenso')        AS suspensos,
                COUNT(*) FILTER (WHERE a.status = 'emprestado')      AS emprestados,
                COALESCE(SUM(c.salario_bruto) FILTER (WHERE c.status = 'ativo'), 0) AS folha_total,
                COUNT(*) FILTER (
                    WHERE c.data_fim BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '90 days'
                    AND c.status = 'ativo'
                ) AS contratos_vencendo
            FROM atletas a
            LEFT JOIN contratos_atleta c ON c.atleta_id = a.id AND c.status = 'ativo'
        `);
        res.json(r.rows[0]);
    } catch (err) {
        console.error('Erro /atletas/resumo:', err);
        res.status(500).json({ erro: 'Erro ao buscar resumo' });
    }
});

// ------------------------------------------------------------
// GET /api/atletas â Lista com filt2os e paginaÃ§Ã£o
// ------------------------------------------------------------
router.get('/', async (req, res) => {
    try {
        const { status, posicao, busca, pagina = 1, por_pagina = 20 } = req.query;
        const conds = [];
        const params = [];

        if (status) { params.push(status); conds.push('a.status = $' + params.length); }
        if (posicao) { params.push(posicao); conds.push('a.posicao = $' + params.length); }
        if (busca) {
            params.push('%' + busca + '%');
            conds.push('(a.nome ILIKE $' + params.length + ' OR a.nome_guerra ILIKE $' + params.length + ')');
        }

        const where = conds.length ? 'WHERE ' + conds.join(' AND ') : '';
        const offset = (parseInt(pagina) - 1) * parseInt(por_pagina);
        params.push(parseInt(por_pagina), offset);

        const query = `
            SELECT
                a.id, a.nome, a.nome_guerra, a.posicao, a.status,
                a.pe_dominante, a.altura_cm, a.peso_kg, a.nacionalidade, a.data_nascimento,
                c.data_inicio AS contrato_inicio,
                c.data_fim AS contrato_fim,
                c.salario_bruto,
                c.salario_carteira,
                c.direitos_imagem,
                c.tipo AS contrato_tipo,
                c.clube_cedente,
                (c.data_fim - CURRENT_DATE) AS dias_ate_vencimento,
                COALESCE((SELECT SUM(e.gols) FROM estatisticas_atleta e WHERE e.atleta_id = a.id AND e.temporada = TO_CHAR(NOW(),'YYYY')), 0) AS total_gols,
                COALESCE((SELECT SUM(e.assistencias) FROM estatisticas_atleta e WHERE e.atleta_id = a.id AND e.temporada = TO_CHAR(NOW(),'YYYY')), 0) AS total_assistencias,
                COALESCE((SELECT SUM(e.jogos_disputados) FROM estatisticas_atleta e WHERE e.atleta_id = a.id AND e.temporada = TO_CHAR(NOW(),'YYYY')), 0) AS total_jogos,
                COALESCE((SELECT SUM(e.jogos_sem_sofrer_gol) FROM estatisticas_atleta e WHERE e.atleta_id = a.id AND e.temporada = TO_CHAR(NOW(),'YYYY')), 0) AS total_clean_sheets
            FROM atletas a
            LEFT JOIN contratos_atleta c ON c.atleta_id = a.id AND c.status = 'ativo'
            ${where}
            ORDER BY
                CASE a.posicao
                    WHEN 'goleiro' THEN 1 WHEN 'lateral_direito' THEN 2 WHEN 'lateral_esquerdo' THEN 3
                    WHEN 'zagueiro' THEN 4 WHEN 'volante' THEN 5 WHEN 'meia_central' THEN 6
                    WHEN 'meia_atacante' THEN 7 WHEN 'ponta_direita' THEN 8
                    WHEN 'ponta_esquerda' THEN 9 WHEN 'centroavante' THEN 10 ELSE 11
                END, a.nome
            LIMIT $${params.length - 1} OFFSET $${params.length}
        `;

        const countQ = `SELECT COUNT(*) AS total FROM atletas a ${where}`;

        const [dados, cnt] = await Promise.all([
            db.query(query, params),
            db.query(countQ, params.slice(0, -2))
        ]);

        res.json({ atletas: dados.rows, total: parseInt(cnt.rows[0].total), pagina: parseInt(pagina), por_pagina: parseInt(por_pagina) });
    } catch (err) {
        console.error('Erro GET /atletas:', err);
        res.status(500).json({ erro: 'Erro ao listar atletas' });
    }
});

// ------------------------------------------------------------
// GET /api/atletas/:id â Detalhe completo
// ------------------------------------------------------------
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const [atleta, contratos, stats, metas, bonificacoes, historico_sal] = await Promise.all([
            db.query('SELECT * FROM atletas WHERE id = $1', [id]),

            db.query(`
                SELECT c.*, m.id AS meta_id, m.tipo AS meta_tipo, m.descricao AS meta_desc,
                    m.meta_quantidade, m.valor_bonus, m.tipo_calculo, m.competicao AS meta_competicao,
                    m.ativo AS meta_ativa
                FROM contratos_atleta c
                LEFT JOIN metas_contrato m ON m.contrato_id = c.id
                WHERE c.atleta_id = $1
                ORDER BY c.status DESC, c.data_inicio DESC, m.id
            `, [id]),

            db.query(`
                SELECT * FROM estatisticas_atleta WHERE atleta_id = $1
                ORDER BY temporada DESC, competicao
            `, [id]),

            db.query(`
                SELECT mc.*, ca.data_inicio, ca.data_fim, ca.status AS contrato_status
                FROM metas_contrato mc
                JOIN contratos_atleta ca ON ca.id = mc.contrato_id
                WHERE ca.atleta_id = $1 AND ca.status = 'ativo'
                ORDER BY mc.tipo, mc.id
            `, [id]),

            db.query(`
                SELECT b.*, mc.tipo AS meta_tipo
                FROM bonificacoes_atleta b
                LEFT JOIN metas_contrato mc ON mc.id = b.meta_id
                WHERE b.atleta_id = $1
                ORDER BY b.competencia DESC, b.created_at DESC
                LIMIT 20
            `, [id]),

            db.query(`
                SELECT * FROM historico_salario_atleta
                WHERE atleta_id = $1
                ORDER BY data_alteracao DESC
            `, [id])
        ]);

        if (!atleta.rows[0]) return res.status(404).json({ erro: 'Atleta nÃ£o encontrado' });

        // Reagrupa contratos com suas metas
        const contratosMap = {};
        for (const row of contratos.rows) {
            if (!contratosMap[row.id]) {
                contratosMap[row.id] = {
                    id: row.id, numero_contrato: row.numero_contrato, tipo: row.tipo,
                    data_inicio: row.data_inicio, data_fim: row.data_fim,
                    salario_bruto: row.salario_bruto, salario_carteira: row.salario_carteira,
                    direitos_imagem: row.direitos_imagem, luvas: row.luvas,
                    clausula_rescisoria: row.clausula_rescisoria, status: row.status,
                    clube_cedente: row.clube_cedente, clube_cessionario: row.clube_cessionario,
                    observacoes: row.observacoes,
                    metas: []
                };
            }
            if (row.meta_id) {
                contratosMap[row.id].metas.push({
                    id: row.meta_id, tipo: row.meta_tipo, descricao: row.meta_desc,
                    meta_quantidade: row.meta_quantidade, valor_bonus: row.valor_bonus,
                    tipo_calculo: row.tipo_calculo, competicao: row.meta_competicao,
                    ativo: row.meta_ativa
                });
            }
        }

        res.json({
            ...atleta.rows[0],
            contratos: Object.values(contratosMap),
            estatisticas: stats.rows,
            metas_ativas: metas.rows,
            bonificacoes: bonificacoes.rows,
            historico_salario: historico_sal.rows
        });
    } catch (err) {
        console.error('Erro GET /atletas/:id:', err);
        re3.status(500).json({ erro: 'Erro ao buscar atleta' });
    }
});

// ------------------------------------------------------------
// POST /api/atletas â Cadastrar atleta
// ------------------------------------------------------------
router.post('/', autorizarPerfis('admin', 'gestor', 'rh'), async (req, res) => {
    try {
        const {
            nome, nome_guerra, data_nascimento, nacionalidade, naturalidade,
            cpf, rg, passaporte, posicao, pe_dominante,
            altura_cm, peso_kg, clube_formacao, agente, observacoes
        } = req.body;

        if (!nome || !posicao) return res.status(400).json({ erro: 'Nome e posiÃ§Ã£o sÃ£o obrigatÃ³rios' });

        const r = await db.query(`
            INSERT INTO atletas
                (nome, nome_guerra, data_nascimento, nacionalidade, naturalidade,
                 cpf, rg, passaporte, posicao, pe_dominante,
                 altura_cm, peso_kg, clube_formacao, agente, observacoes)
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)
            RETURNING *
        `, [nome, nome_guerra||null, data_nascimento||null, nacionalidade||'Brasileira',
            naturalidade||null, cpf||null, rg||null, passaporte||null, posicao,
            pe_dominante||'direito', altura_cm||null, peso_kg||null,
            c,ube_formacao||null, agente||null, observacoes||null]);

        res.status(201).json(r.rows[0]);
    } catch (err) {
        console.error('Erro POST /atletas:', err);
        res.status(500).json({ erro: 'Erro ao cadastrar atleta' });
    }
});

// ------------------------------------------------------------
// PUT /api/atletas/:id â Atualizar dados do atleta
// ------------------------------------------------------------
router.put('/:id', autorizarPerfis('admin', 'gestor', 'rh'), async (req, res) => {
    try {
        const { id } = req.params;
        const {
            nome, nome_guerra, data_nascimento, nacionalidade, naturalidade,
            cpf, rg, passaporte, posicao, pe_dominante, altura_cm, peso_kg,
            status, clube_formacao, agente, observacoes
        } = req.body;

        const r = await db.query(`
            UPDATE atletas SET
                nome = COALESCE($1, nome),
                nome_guerra = COALESCE($2, nome_guerra),
                data_nascimento = COALESCE($3, data_nascimento),
                nacionalidade = COALESCE($4, nacionalidade),
                naturalidade = COALESCE($5, naturalidade),
                cpf = COALESCE($6, cpf),
                rg = COALESCE($7, rg),
                passaporte = COALESCE($8, passaporte),
                posicao = COALESCE($9, posicao),
                pe_dominante = COALESCE($10, pe_dominante),
                altura_cm = COALESCE($11, altura_cm),
                peso_kg = COALESCE($12, peso_kg),
                status = COALESCE($13, status),
                clube_formacao = COALESCE($14, clube_formacao),
                agente = COALESCE($15, agente),
                observacoes = COALESCE($16, observacoes)
            WHERE id = $17 RETURNING *
        `, [nome, nome_guerra, data_nascimento, nacionalidade, naturalidade,
            cpf, rg, passaporte, posicao, pe_dominante, altura_cm, peso_kg,
            status, clube_formacao, agente, observacoes, id]);

        if (!r.rows[0]) return res.status(404).json({ erro: 'Atleta nÃ£o encontrado' });
        res.json(r.rows[0]);
    } catch (err) {
        console.error('Erro PUT /atletas:', err);
        res.status(500).json({ erro: 'Erro ao atualizar atleta' });
    }
});

// ------------------------------------------------------------
// POST /api/atletas/:id/contratos â Novo contrato
// ------------------------------------------------------------
router.post('/:id/contratos', autorizarPerfis('admin', 'gestor', 'rh', 'financeiro'), async (req, res) => {
    try {
        const { id } = req.params;
        const {
            numero_contrato, tipo, data_inicio, data_fim,
            salario_bruto, salario_carteira, direitos_imagem, luvas,
            clausula_rescisoria, clube_cedente, clube_cessionario, observacoes,
            metas = []
        } = req.body;

        if (!data_inicio || !data_fim || !salario_bruto) {
            return res.status(400).json({ erro: 'data_inicio, data_fim e salario_bruto sÃ£o obrigatÃ³rios' });
        }

        // Encerra contrato anterior se existir
        await db.query(`
            UPDATE contratos_atleta SET status = 'encerrado'
            WHERE atleta_id = $1 AND status = 'ativo'
        `, [id]);

        const r = await db.query(`
            INSERT INTO contratos_atleta
                (atleta_id, numero_contrato, tipo, data_inicio, data_fim,
                 salario_bruto, salario_carteira, direitos_imagem, luvas,
                 clausula_rescisoria, clube_cedente, clube_cessionario, observacoes)
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
            RETURNING *
        `, [id, numero_contrato||null, tipo||'profissional', data_inicio, data_fim,
            salario_bruto, salario_carteira||null, direitos_imagem||0, luvas||0,
            clausula_rescisoria||null, clube_cedente||null, clube_cessionario||null, observacoes||null]);

        const contrato = r.rows[0];

        // Registra histÃ³rico de salÃ¡rio
        const salAnterior = await db.query(`
            SELECT salario_novo FROM historico_salario_atleta
            WHERE atleta_id = $1 ORDER BY created_at DESC LIMIT 1
        `, [id]);

        await db.query(`
            INSERT INTO historico_salario_atleta
                (atleta_id, contrato_id, data_alteracao, salario_anterior, salario_novo, motivo)
            VALUES ($1, $2, $3, $4, $5, $6)
        `, [id, contrato.id, data_inicio,
            salAnterior.rows[0]?.salario_novo || null,
            salario_bruto,
            'Novo contrato â ' + (tipo || 'profissional')]);

        // Insere metas do contrato
        for (const meta of metas) {
            await db.query(`
                INSERT INTO metas_contrato
                    (contrato_id, tipo, descricao, meta_quantidade, valor_bonus, tipo_calculo, competicao, observacoes)
                VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
            `, [contrato.id, meta.tipo, meta.descricao, meta.meta_quantidade||1,
                meta.valor_bonus, meta.tipo_calculo||'por_unidade',
                meta.competicao||null, meta.observacoes||null]);
        }

        res.status(201).json(contrato);
    } catch (err) {
        console.error('Erro POST contrato:', err);
        res.status(500).json({ erro: 'Erro ao registrar contrato' });
    }
});

// ------------------------------------------------------------
// PUT /api/atletas/:id/estatisticas â Atualizar estatÃ­sticas
// (upsert â cria ou atualiza por temporada+competiÃ§Ã£o)
// ------------------------------------------------------------
router.put('/:id/estatisticas', autorizarPerfis('admin', 'gestor', 'rh'), async (req, res) => {
    try {
        const { id } = req.params;
        const {
            temporada, competicao,
            jogos_disputados, jogos_titular, minutos_jogados,
            gols, assistencias, chutes_a_gol,
            jogos_sem_sofrer_gol, defesas_dificeis, interceptacoes,
            cartoes_amarelos, cartoes_vermelhos, faltas_cometidas
        } = req.body;

        if (!temporada || !competicao) {
            return res.status(400).json({ erro: 'temporada e competicao sÃ£o obrigatÃ³rios' });
        }

        const r = await db.query(`
            INSERT INTO estatisticas_atleta
                (atleta_id, temporada, competicao,
                 jogos_disputados, jogos_titular, minutos_jogados,
                 gols, assistencias, chutes_a_gol,
                 jogos_sem_sofrer_gol, defesas_dificeis, interceptacoes,
                 cartoes_amarelos, cartoes_vermelhos, faltas_cometidas)
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)
            ON CONFLICT (atleta_id, temporada, competicao) DO UPDATE SET
                jogos_disputados = EXCLUDED.jogos_disputados,
                jogos_titular = EXCLUDED.jogos_titular,
                minutos_jogados = EXCLUDED.minutos_jogados,
                gols = EXCLUDED.gols,
                assistencias = EXCLUDED.assistencias,
                chutes_a_gol = EXCLUDED.chutes_a_gol,
                jogos_sem_sofrer_gol = EXCLUDED.jogos_sem_sofrer_gol,
                defesas_dificeis = EXCLUDED.defesas_dificeis,
                interceptacoes = EXCLUDED.interceptacoes,
                cartoes_amarelos = EXCLUDED.cartoes_amarelos,
                cartoes_vermelhos = EXCLUDED.cartoes_vermelhos,
                faltas_cometidas = EXCLUDED.faltas_cometidas,
                updated_at = NOW()
            RETURNING *
        `, [id, temporada, competicao,
            jogos_disputados||0, jogos_titular||0, minutos_jogados||0,
            gols||0, assistencias||0, chutes_a_gol||0,
            jogos_sem_sofrer_gol||0, defesas_dificeis||0, interceptacoes||0,
            cartoes_amarelos||0, cartoes_vermelhos||0, faltas_cometidas||0]);

        res.json(r.rows[0]);
    } catch (err) {
        console.error('Erro PUT estatisticas:', err);
        res.status(500).json({ erro: 'Erro ao salvar estatÃ­sticas' });
    }
});

// ------------------------------------------------------------
// POST /api/atletas/:id/bonificacoes â Registrar bonificaÃ§Ã£o/desconto manual
// ------------------------------------------------------------
router.post('/:id/bonificacoes', autorizarPerfis('admin', 'gestor', 'financeiro'), async (req, res) => {
    try {
        const { id } = req.params;
        const { contrato_id, meta_id, competencia, descricao, valor, tipo } = req.body;
        if (!competencia || !descricao || !valor) {
            return res.status(400).json({ erro: 'competencia, descricao e valor sÃ£o obrigatÃ³rios' });
        }

        const r = await db.query(`
            INSERT INTO bonificacoes_atleta
                (atleta_id, contrato_id, meta_id, competencia, descricao, valor, tipo)
            VALUES ($1,$2,$3,$4,$5,$6,$7)
            RETURNING *
        `, [id, contrato_id||null, meta_id||null, competencia, descricao,
            Math.abs(parseFloat(valor)), tipo||'bonus']);

        res.status(201).json(r.rows[0]);
    } catch (err) {
        console.error('Erro POST bonificacao:', err);
        res.status(500).json({ erro: 'Erro ao registrar bonificaÃ§Ã£o' });
    }
});

// PATCH /api/atletas/:id/bonificacoes/:bonId/pagar
router.patch('/:id/bonificacoes/:bonId/pagar', autorizarPerfis('admin', 'financeiro'), async (req, res) => {
    try {
        const { bonId } = req.params;
        await db.query("UPDATE bonificacoes_atleta SET status = 'pago' WHERE id = $1", [bonId]);
        res.json({ mensagem: 'BonificaÃ§Ã£o marcada como paga' });
    } catch (err) {
        res.status(500).json({ erro: 'Erro ao atualizar bonificaÃ§Ã£o' });
    }
});

// ------------------------------------------------------------
// GET /api/atletas/artilharia â Ranking de artilheiros
// ------------------------------------------------------------
router.get('/aux/artilharia', async (req, res) => {
    try {
        const { temporada = new Date().getFullYear().toString() } = req.query;
        const r = await db.query(`
            SELECT
                a.id, a.nome, a.nome_guerra, a.posicao,
                SUM(e.gols) AS gols,
                SUM(e.assistencias) AS assistencias,
                SUM(e.jogos_disputados) AS jogos,
                SUM(e.jogos_sem_sofrer_gol) AS clean_sheets
            FROM atletas a
            JOIN estatisticas_atleta e ON e.atleta_id = a.id
            WHERE e.temporada = $1
            GROUP BY a.id, a.nome, a.nome_guerra, a.posicao
            HAVING SUM(e.gols) > 0 OR SUM(e.assistencias) > 0
            ORDER BY gols DESC, assistencias DESC
        `, [temporada]);
        res.json(r.rows);
    } catch (err) {
        res.status(500).json({ erro: 'Erro ao buscar artilharia' });
    }
});

module.exports = router;
