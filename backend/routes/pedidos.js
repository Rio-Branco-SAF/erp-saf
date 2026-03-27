// ============================================================
// MÓDULO 3: PEDIDOS DE COMPRA — Rotas da API
// ERP SAF
// ============================================================

const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { autenticar, autorizarPerfis } = require('../middleware/auth');

// Todos os endpoints exigem autenticação
router.use(autenticar);

// ------------------------------------------------------------
// HELPERS
// ------------------------------------------------------------
function gerarNumeroPedido(id) {
    const ano = new Date().getFullYear();
    return 'PC-' + ano + '-' + String(id).padStart(3, '0');
}

// ------------------------------------------------------------
// GET /api/pedidos/resumo
// KPIs do dashboard
// ------------------------------------------------------------
router.get('/resumo', async (req, res) => {
    try {
        const resultado = await db.query(`
            SELECT
                COUNT(*) FILTER (WHERE status NOT IN ('cancelado','concluido'))     AS em_aberto,
                COUNT(*) FILTER (WHERE status = 'aguardando_aprovacao')             AS aguardando_aprovacao,
                COUNT(*) FILTER (WHERE status IN ('em_cotacao','aguardando_cotacao')) AS em_cotacao,
                COUNT(*) FILTER (WHERE status = 'concluido'
                    AND DATE_TRUNC('month', updated_at) = DATE_TRUNC('month', NOW())) AS concluidos_mes,
                COALESCE(SUM(valor_final) FILTER (
                    WHERE status = 'concluido'
                    AND DATE_TRUNC('month', updated_at) = DATE_TRUNC('month', NOW())
                ), 0)                                                               AS valor_gasto_mes,
                COALESCE(SUM(valor_estimado) FILTER (
                    WHERE status NOT IN ('cancelado','rejeitado','concluido')
                ), 0)                                                               AS valor_em_aberto
            FROM pedidos_compra
        `);

        res.json(resultado.rows[0]);
    } catch (err) {
        console.error('Erro /pedidos/resumo:', err);
        res.status(500).json({ erro: 'Erro ao buscar resumo de pedidos' });
    }
});

// ------------------------------------------------------------
// GET /api/pedidos
// Lista com filtros e paginação
// ------------------------------------------------------------
router.get('/', async (req, res) => {
    try {
        const {
            status,
            prioridade,
            departamento_id,
            busca,
            pagina = 1,
            por_pagina = 15
        } = req.query;

        const conditions = [];
        const params = [];

        if (status) {
            params.push(status);
            conditions.push('p.status = $' + params.length);
        }
        if (prioridade) {
            params.push(prioridade);
            conditions.push('p.prioridade = $' + params.length);
        }
        if (departamento_id) {
            params.push(parseInt(departamento_id));
            conditions.push('p.departamento_id = $' + params.length);
        }
        if (busca) {
            params.push('%' + busca + '%');
            conditions.push('(p.titulo ILIKE $' + params.length + ' OR p.numero ILIKE $' + params.length + ')');
        }

        const where = conditions.length > 0 ? 'WHERE ' + conditions.join(' AND ') : '';

        const offset = (parseInt(pagina) - 1) * parseInt(por_pagina);
        params.push(parseInt(por_pagina));
        params.push(offset);

        const query = `
            SELECT
                p.id, p.numero, p.titulo, p.status, p.prioridade,
                p.data_necessidade, p.created_at, p.updated_at,
                p.valor_estimado, p.valor_aprovado, p.valor_final,
                u.nome AS solicitante_nome,
                d.nome AS departamento_nome,
                cc.nome AS centro_custo_nome,
                COALESCE((SELECT COUNT(*) FROM cotacoes c WHERE c.pedido_id = p.id), 0) AS total_cotacoes
            FROM pedidos_compra p
            LEFT JOIN usuarios u ON u.id = p.solicitante_id
            LEFT JOIN departamentos d ON d.id = p.departamento_id
            LEFT JOIN centros_custo cc ON cc.id = p.centro_custo_id
            ${where}
            ORDER BY
                CASE p.status
                    WHEN 'aguardando_aprovacao' THEN 1
                    WHEN 'em_cotacao' THEN 2
                    WHEN 'aguardando_cotacao' THEN 3
                    WHEN 'em_compra' THEN 4
                    WHEN 'aprovado' THEN 5
                    WHEN 'rascunho' THEN 6
                    ELSE 7
                END,
                CASE p.prioridade
                    WHEN 'urgente' THEN 1
                    WHEN 'alta' THEN 2
                    WHEN 'normal' THEN 3
                    ELSE 4
                END,
                p.updated_at DESC
            LIMIT $${params.length - 1} OFFSET $${params.length}
        `;

        const countQuery = `
            SELECT COUNT(*) AS total
            FROM pedidos_compra p
            ${where}
        `;

        const [dados, contagem] = await Promise.all([
            db.query(query, params),
            db.query(countQuery, params.slice(0, -2))
        ]);

        res.json({
            pedidos: dados.rows,
            total: parseInt(contagem.rows[0].total),
            pagina: parseInt(pagina),
            por_pagina: parseInt(por_pagina)
        });
    } catch (err) {
        console.error('Erro GET /pedidos:', err);
        res.status(500).json({ erro: 'Erro ao listar pedidos' });
    }
});

// ------------------------------------------------------------
// GET /api/pedidos/:id
// Detalhe completo com itens, cotações e histórico
// ------------------------------------------------------------
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const [pedido, itens, cotacoes, historico] = await Promise.all([
            db.query(`
                SELECT p.*,
                    u.nome AS solicitante_nome,
                    d.nome AS departamento_nome,
                    ap.nome AS aprovador_nome,
                    cf.nome AS categoria_nome,
                    cc.nome AS centro_custo_nome
                FROM pedidos_compra p
                LEFT JOIN usuarios u ON u.id = p.solicitante_id
                LEFT JOIN departamentos d ON d.id = p.departamento_id
                LEFT JOIN usuarios ap ON ap.id = p.aprovador_id
                LEFT JOIN categorias_financeiras cf ON cf.id = p.categoria_financeira_id
                LEFT JOIN centros_custo cc ON cc.id = p.centro_custo_id
                WHERE p.id = $1
            `, [id]),

            db.query(`
                SELECT * FROM itens_pedido WHERE pedido_id = $1 ORDER BY id
            `, [id]),

            db.query(`
                SELECT c.*,
                    f.nome AS fornecedor_nome,
                    f.cnpj AS fornecedor_cnpj,
                    f.email AS fornecedor_email,
                    f.telefone AS fornecedor_telefone
                FROM cotacoes c
                LEFT JOIN fornecedores f ON f.id = c.fornecedor_id
                WHERE c.pedido_id = $1
                ORDER BY
                    CASE c.status WHEN 'selecionada' THEN 1 ELSE 2 END,
                    c.valor_total ASC NULLS LAST
            `, [id]),

            db.query(`
                SELECT h.*, u.nome AS usuario_nome
                FROM historico_pedido h
                LEFT JOIN usuarios u ON u.id = h.usuario_id
                WHERE h.pedido_id = $1
                ORDER BY h.created_at DESC
            `, [id])
        ]);

        if (pedido.rows.length === 0) {
            return res.status(404).json({ erro: 'Pedido não encontrado' });
        }

        // Para cada cotação, busca seus itens
        const cotacoesComItens = await Promise.all(
            cotacoes.rows.map(async (cot) => {
                const itensCot = await db.query(`
                    SELECT ic.*, ip.descricao AS item_descricao, ip.unidade
                    FROM itens_cotacao ic
                    JOIN itens_pedido ip ON ip.id = ic.item_pedido_id
                    WHERE ic.cotacao_id = $1
                `, [cot.id]);
                return { ...cot, itens: itensCot.rows };
            })
        );

        res.json({
            ...pedido.rows[0],
            itens: itens.rows,
            cotacoes: cotacoesComItens,
            historico: historico.rows
        });
    } catch (err) {
        console.error('Erro GET /pedidos/:id:', err);
        res.status(500).json({ erro: 'Erro ao buscar pedido' });
    }
});

// ------------------------------------------------------------
// POST /api/pedidos
// Criar novo pedido (rascunho)
// ------------------------------------------------------------
router.post('/', async (req, res) => {
    try {
        const {
            titulo, descricao, departamento_id, prioridade,
            data_necessidade, categoria_financeira_id, centro_custo_id,
            valor_estimado, observacoes, itens = []
        } = req.body;

        if (!titulo) {
            return res.status(400).json({ erro: 'Título é obrigatório' });
        }

        // Cria o pedido sem número ainda
        const result = await db.query(`
            INSERT INTO pedidos_compra
                (numero, titulo, descricao, solicitante_id, departamento_id,
                 prioridade, data_necessidade, status,
                 categoria_financeira_id, centro_custo_id,
                 valor_estimado, observacoes)
            VALUES ($1, $2, $3, $4, $5, $6, $7, 'rascunho', $8, $9, $10, $11)
            RETURNING *
        `, [
            'PC-TEMP',
            titulo,
            descricao || null,
            req.usuario.id,
            departamento_id || null,
            prioridade || 'normal',
            data_necessidade || null,
            categoria_financeira_id || null,
            centro_custo_id || null,
            valor_estimado || null,
            observacoes || null
        ]);

        const pedido = result.rows[0];
        const numero = gerarNumeroPedido(pedido.id);

        // Atualiza com número real
        await db.query('UPDATE pedidos_compra SET numero = $1 WHERE id = $2', [numero, pedido.id]);

        // Insere itens se fornecidos
        if (itens.length > 0) {
            for (const item of itens) {
                await db.query(`
                    INSERT INTO itens_pedido
                        (pedido_id, descricao, quantidade, unidade, valor_unitario_estimado, observacoes)
                    VALUES ($1, $2, $3, $4, $5, $6)
                `, [
                    pedido.id,
                    item.descricao,
                    item.quantidade || 1,
                    item.unidade || 'un',
                    item.valor_unitario_estimado || null,
                    item.observacoes || null
                ]);
            }
        }

        // Registra histórico
        await db.query(`
            INSERT INTO historico_pedido (pedido_id, usuario_id, acao, descricao)
            VALUES ($1, $2, 'criou', 'Pedido criado como rascunho.')
        `, [pedido.id, req.usuario.id]);

        res.status(201).json({ ...pedido, numero });
    } catch (err) {
        console.error('Erro POST /pedidos:', err);
        res.status(500).json({ erro: 'Erro ao criar pedido' });
    }
});

// ------------------------------------------------------------
// PUT /api/pedidos/:id
// Editar pedido (apenas rascunho ou aguardando_cotacao)
// ------------------------------------------------------------
router.put('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const {
            titulo, descricao, departamento_id, prioridade,
            data_necessidade, categoria_financeira_id, centro_custo_id,
            valor_estimado, observacoes
        } = req.body;

        const check = await db.query('SELECT status FROM pedidos_compra WHERE id = $1', [id]);
        if (check.rows.length === 0) return res.status(404).json({ erro: 'Pedido não encontrado' });

        const statusAtual = check.rows[0].status;
        if (!['rascunho', 'aguardando_cotacao'].includes(statusAtual)) {
            return res.status(400).json({ erro: 'Pedido não pode ser editado no status atual: ' + statusAtual });
        }

        const result = await db.query(`
            UPDATE pedidos_compra SET
                titulo = COALESCE($1, titulo),
                descricao = COALESCE($2, descricao),
                departamento_id = COALESCE($3, departamento_id),
                prioridade = COALESCE($4, prioridade),
                data_necessidade = COALESCE($5, data_necessidade),
                categoria_financeira_id = COALESCE($6, categoria_financeira_id),
                centro_custo_id = COALESCE($7, centro_custo_id),
                valor_estimado = COALESCE($8, valor_estimado),
                observacoes = COALESCE($9, observacoes)
            WHERE id = $10
            RETURNING *
        `, [titulo, descricao, departamento_id, prioridade, data_necessidade,
            categoria_financeira_id, centro_custo_id, valor_estimado, observacoes, id]);

        await db.query(`
            INSERT INTO historico_pedido (pedido_id, usuario_id, acao, descricao)
            VALUES ($1, $2, 'editou', 'Dados do pedido atualizados.')
        `, [id, req.usuario.id]);

        res.json(result.rows[0]);
    } catch (err) {
        console.error('Erro PUT /pedidos/:id:', err);
        res.status(500).json({ erro: 'Erro ao atualizar pedido' });
    }
});

// ------------------------------------------------------------
// PATCH /api/pedidos/:id/enviar-cotacao
// Rascunho → Aguardando Cotação
// ------------------------------------------------------------
router.patch('/:id/enviar-cotacao', async (req, res) => {
    try {
        const { id } = req.params;

        const check = await db.query('SELECT status FROM pedidos_compra WHERE id = $1', [id]);
        if (check.rows.length === 0) return res.status(404).json({ erro: 'Pedido não encontrado' });
        if (check.rows[0].status !== 'rascunho') {
            return res.status(400).json({ erro: 'Somente pedidos em rascunho podem ser enviados para cotação' });
        }

        // Verifica se tem pelo menos 1 item
        const itens = await db.query('SELECT COUNT(*) AS total FROM itens_pedido WHERE pedido_id = $1', [id]);
        if (parseInt(itens.rows[0].total) === 0) {
            return res.status(400).json({ erro: 'Adicione pelo menos 1 item antes de enviar para cotação' });
        }

        await db.query("UPDATE pedidos_compra SET status = 'aguardando_cotacao' WHERE id = $1", [id]);
        await db.query(`
            INSERT INTO historico_pedido (pedido_id, usuario_id, acao, descricao)
            VALUES ($1, $2, 'enviou_cotacao', 'Pedido enviado para cotação com fornecedores.')
        `, [id, req.usuario.id]);

        res.json({ mensagem: 'Pedido enviado para cotação' });
    } catch (err) {
        console.error('Erro enviar-cotacao:', err);
        res.status(500).json({ erro: 'Erro ao enviar pedido para cotação' });
    }
});

// ------------------------------------------------------------
// PATCH /api/pedidos/:id/enviar-aprovacao
// Em Cotação → Aguardando Aprovação
// ------------------------------------------------------------
router.patch('/:id/enviar-aprovacao', async (req, res) => {
    try {
        const { id } = req.params;

        const check = await db.query('SELECT status FROM pedidos_compra WHERE id = $1', [id]);
        if (check.rows.length === 0) return res.status(404).json({ erro: 'Pedido não encontrado' });
        if (!['em_cotacao', 'aguardando_cotacao'].includes(check.rows[0].status)) {
            return res.status(400).json({ erro: 'Status inválido para enviar aprovação' });
        }

        // Verifica se tem cotação selecionada
        const cotSel = await db.query(
            "SELECT COUNT(*) AS total FROM cotacoes WHERE pedido_id = $1 AND status = 'selecionada'",
            [id]
        );
        if (parseInt(cotSel.rows[0].total) === 0) {
            return res.status(400).json({ erro: 'Selecione uma cotação antes de enviar para aprovação' });
        }

        await db.query("UPDATE pedidos_compra SET status = 'aguardando_aprovacao' WHERE id = $1", [id]);
        await db.query(`
            INSERT INTO historico_pedido (pedido_id, usuario_id, acao, descricao)
            VALUES ($1, $2, 'enviou_aprovacao', 'Pedido enviado para aprovação do gestor.')
        `, [id, req.usuario.id]);

        res.json({ mensagem: 'Pedido enviado para aprovação' });
    } catch (err) {
        console.error('Erro enviar-aprovacao:', err);
        res.status(500).json({ erro: 'Erro ao enviar para aprovação' });
    }
});

// ------------------------------------------------------------
// PATCH /api/pedidos/:id/aprovar
// Aprovar pedido (perfis: admin, gestor, financeiro)
// ------------------------------------------------------------
router.patch('/:id/aprovar', autorizarPerfis('admin', 'gestor', 'financeiro'), async (req, res) => {
    try {
        const { id } = req.params;
        const { valor_aprovado, observacoes } = req.body;

        const check = await db.query('SELECT status FROM pedidos_compra WHERE id = $1', [id]);
        if (check.rows.length === 0) return res.status(404).json({ erro: 'Pedido não encontrado' });
        if (check.rows[0].status !== 'aguardando_aprovacao') {
            return res.status(400).json({ erro: 'Pedido não está aguardando aprovação' });
        }

        await db.query(`
            UPDATE pedidos_compra SET
                status = 'aprovado',
                aprovador_id = $1,
                data_aprovacao = NOW(),
                valor_aprovado = $2
            WHERE id = $3
        `, [req.usuario.id, valor_aprovado || null, id]);

        const descricao = 'Pedido aprovado.'
            + (valor_aprovado ? ' Valor aprovado: R$ ' + parseFloat(valor_aprovado).toFixed(2).replace('.', ',') + '.' : '')
            + (observacoes ? ' Obs: ' + observacoes : '');

        await db.query(`
            INSERT INTO historico_pedido (pedido_id, usuario_id, acao, descricao)
            VALUES ($1, $2, 'aprovou', $3)
        `, [id, req.usuario.id, descricao]);

        res.json({ mensagem: 'Pedido aprovado com sucesso' });
    } catch (err) {
        console.error('Erro aprovar:', err);
        res.status(500).json({ erro: 'Erro ao aprovar pedido' });
    }
});

// ------------------------------------------------------------
// PATCH /api/pedidos/:id/rejeitar
// Rejeitar pedido
// ------------------------------------------------------------
router.patch('/:id/rejeitar', autorizarPerfis('admin', 'gestor', 'financeiro'), async (req, res) => {
    try {
        const { id } = req.params;
        const { motivo } = req.body;

        if (!motivo) return res.status(400).json({ erro: 'Informe o motivo da rejeição' });

        const check = await db.query('SELECT status FROM pedidos_compra WHERE id = $1', [id]);
        if (check.rows.length === 0) return res.status(404).json({ erro: 'Pedido não encontrado' });
        if (check.rows[0].status !== 'aguardando_aprovacao') {
            return res.status(400).json({ erro: 'Pedido não está aguardando aprovação' });
        }

        await db.query(`
            UPDATE pedidos_compra SET
                status = 'rejeitado',
                aprovador_id = $1,
                data_aprovacao = NOW(),
                motivo_rejeicao = $2
            WHERE id = $3
        `, [req.usuario.id, motivo, id]);

        await db.query(`
            INSERT INTO historico_pedido (pedido_id, usuario_id, acao, descricao)
            VALUES ($1, $2, 'rejeitou', $3)
        `, [id, req.usuario.id, 'Pedido rejeitado. Motivo: ' + motivo]);

        res.json({ mensagem: 'Pedido rejeitado' });
    } catch (err) {
        console.error('Erro rejeitar:', err);
        res.status(500).json({ erro: 'Erro ao rejeitar pedido' });
    }
});

// ------------------------------------------------------------
// PATCH /api/pedidos/:id/concluir
// Aprovado/Em compra → Concluído
// ------------------------------------------------------------
router.patch('/:id/concluir', async (req, res) => {
    try {
        const { id } = req.params;
        const { valor_final } = req.body;

        const check = await db.query('SELECT status FROM pedidos_compra WHERE id = $1', [id]);
        if (check.rows.length === 0) return res.status(404).json({ erro: 'Pedido não encontrado' });
        if (!['aprovado', 'em_compra'].includes(check.rows[0].status)) {
            return res.status(400).json({ erro: 'Pedido não está em estado de compra' });
        }

        await db.query(`
            UPDATE pedidos_compra SET status = 'concluido', valor_final = $1 WHERE id = $2
        `, [valor_final || null, id]);

        await db.query(`
            INSERT INTO historico_pedido (pedido_id, usuario_id, acao, descricao)
            VALUES ($1, $2, 'concluiu', 'Compra concluída.')
        `, [id, req.usuario.id]);

        res.json({ mensagem: 'Pedido concluído' });
    } catch (err) {
        console.error('Erro concluir:', err);
        res.status(500).json({ erro: 'Erro ao concluir pedido' });
    }
});

// ------------------------------------------------------------
// PATCH /api/pedidos/:id/cancelar
// ------------------------------------------------------------
router.patch('/:id/cancelar', async (req, res) => {
    try {
        const { id } = req.params;
        const { motivo } = req.body;

        await db.query("UPDATE pedidos_compra SET status = 'cancelado' WHERE id = $1", [id]);
        await db.query(`
            INSERT INTO historico_pedido (pedido_id, usuario_id, acao, descricao)
            VALUES ($1, $2, 'cancelou', $3)
        `, [id, req.usuario.id, motivo ? 'Cancelado. Motivo: ' + motivo : 'Pedido cancelado.']);

        res.json({ mensagem: 'Pedido cancelado' });
    } catch (err) {
        console.error('Erro cancelar:', err);
        res.status(500).json({ erro: 'Erro ao cancelar pedido' });
    }
});

// ============================================================
// COTAÇÕES
// ============================================================

// POST /api/pedidos/:id/cotacoes — Adicionar cotação
router.post('/:id/cotacoes', async (req, res) => {
    try {
        const { id } = req.params;
        const {
            fornecedor_id, numero_cotacao, data_cotacao, validade_cotacao,
            prazo_entrega, valor_total, condicoes_pagamento, observacoes, itens = []
        } = req.body;

        // Muda status para em_cotacao
        await db.query(`
            UPDATE pedidos_compra
            SET status = CASE WHEN status = 'aguardando_cotacao' THEN 'em_cotacao' ELSE status END
            WHERE id = $1
        `, [id]);

        const result = await db.query(`
            INSERT INTO cotacoes
                (pedido_id, fornecedor_id, numero_cotacao, data_cotacao, validade_cotacao,
                 prazo_entrega, status, valor_total, condicoes_pagamento, observacoes, criado_por)
            VALUES ($1, $2, $3, $4, $5, $6, 'recebida', $7, $8, $9, $10)
            RETURNING *
        `, [
            id, fornecedor_id || null, numero_cotacao || null,
            data_cotacao || new Date().toISOString().split('T')[0],
            validade_cotacao || null, prazo_entrega || null,
            valor_total || null, condicoes_pagamento || null,
            observacoes || null, req.usuario.id
        ]);

        const cotacao = result.rows[0];

        // Insere itens da cotação
        if (itens.length > 0) {
            for (const item of itens) {
                await db.query(`
                    INSERT INTO itens_cotacao
                        (cotacao_id, item_pedido_id, valor_unitario, valor_total, disponivel, observacoes)
                    VALUES ($1, $2, $3, $4, $5, $6)
                `, [
                    cotacao.id, item.item_pedido_id,
                    item.valor_unitario || null,
                    item.valor_total || null,
                    item.disponivel !== false,
                    item.observacoes || null
                ]);
            }
        }

        const fornecedor = fornecedor_id ? await db.query('SELECT nome FROM fornecedores WHERE id = $1', [fornecedor_id]) : { rows: [{ nome: 'Fornecedor' }] };
        const nomeForn = fornecedor.rows[0] ? fornecedor.rows[0].nome : 'Fornecedor';

        await db.query(`
            INSERT INTO historico_pedido (pedido_id, usuario_id, acao, descricao)
            VALUES ($1, $2, 'cotacao', $3)
        `, [id, req.usuario.id,
            'Cotação recebida de ' + nomeForn + (valor_total ? ': R$ ' + parseFloat(valor_total).toFixed(2).replace('.', ',') : '') + '.'
        ]);

        res.status(201).json(cotacao);
    } catch (err) {
        console.error('Erro POST cotacao:', err);
        res.status(500).json({ erro: 'Erro ao adicionar cotação' });
    }
});

// PATCH /api/pedidos/:id/cotacoes/:cotId/selecionar — Selecionar melhor cotação
router.patch('/:id/cotacoes/:cotId/selecionar', async (req, res) => {
    try {
        const { id, cotId } = req.params;

        // Desmarca todas as outras
        await db.query(`
            UPDATE cotacoes SET status = 'recebida'
            WHERE pedido_id = $1 AND status = 'selecionada'
        `, [id]);

        // Seleciona a escolhida
        const result = await db.query(`
            UPDATE cotacoes SET status = 'selecionada' WHERE id = $1 AND pedido_id = $2 RETURNING *
        `, [cotId, id]);

        if (result.rows.length === 0) return res.status(404).json({ erro: 'Cotação não encontrada' });

        // Atualiza valor aprovado no pedido
        const cot = result.rows[0];
        if (cot.valor_total) {
            await db.query('UPDATE pedidos_compra SET valor_estimado = $1 WHERE id = $2', [cot.valor_total, id]);
        }

        await db.query(`
            INSERT INTO historico_pedido (pedido_id, usuario_id, acao, descricao)
            VALUES ($1, $2, 'selecionou', 'Cotação selecionada como melhor proposta.')
        `, [id, req.usuario.id]);

        res.json({ mensagem: 'Cotação selecionada', cotacao: cot });
    } catch (err) {
        console.error('Erro selecionar cotacao:', err);
        res.status(500).json({ erro: 'Erro ao selecionar cotação' });
    }
});

// ============================================================
// FORNECEDORES
// ============================================================

router.get('/aux/fornecedores', async (req, res) => {
    try {
        const { busca, categoria } = req.query;
        const conditions = ['ativo = TRUE'];
        const params = [];

        if (busca) {
            params.push('%' + busca + '%');
            conditions.push('(nome ILIKE $' + params.length + ' OR cnpj ILIKE $' + params.length + ')');
        }
        if (categoria) {
            params.push(categoria);
            conditions.push('categoria = $' + params.length);
        }

        const result = await db.query(`
            SELECT * FROM fornecedores
            WHERE ${conditions.join(' AND ')}
            ORDER BY nome
        `, params);

        res.json(result.rows);
    } catch (err) {
        console.error('Erro GET fornecedores:', err);
        res.status(500).json({ erro: 'Erro ao buscar fornecedores' });
    }
});

router.post('/aux/fornecedores', async (req, res) => {
    try {
        const { nome, cnpj, contato, email, telefone, categoria, observacoes } = req.body;
        if (!nome) return res.status(400).json({ erro: 'Nome é obrigatório' });

        const result = await db.query(`
            INSERT INTO fornecedores (nome, cnpj, contato, email, telefone, categoria, observacoes)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *
        `, [nome, cnpj || null, contato || null, email || null,
            telefone || null, categoria || null, observacoes || null]);

        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error('Erro POST fornecedor:', err);
        res.status(500).json({ erro: 'Erro ao cadastrar fornecedor' });
    }
});

// GET /api/pedidos/aux/departamentos
router.get('/aux/departamentos', async (req, res) => {
    try {
        const result = await db.query('SELECT id, nome FROM departamentos ORDER BY nome');
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ erro: 'Erro ao buscar departamentos' });
    }
});

module.exports = router;
