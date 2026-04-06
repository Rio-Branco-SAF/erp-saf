-- ============================================================
-- MÓDULO 7 — RELATÓRIOS GERENCIAIS
-- Schema: tabela de logs + views consolidadas cross-módulo
-- ============================================================

-- Log de relatórios gerados
CREATE TABLE IF NOT EXISTS relatorios_gerados (
    id          SERIAL PRIMARY KEY,
    tipo        VARCHAR(60) NOT NULL,  -- financeiro, folha, esportivo, investidores, compras, executivo
    periodo_ini DATE,
    periodo_fim DATE,
    gerado_por  INTEGER REFERENCES usuarios(id),
    parametros  JSONB,
    created_at  TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- VIEW: Resumo Executivo Consolidado
-- ============================================================
-- View auxiliar: metas com percentual de progresso calculado
CREATE OR REPLACE VIEW metas_completo AS
SELECT
    *,
    CASE
        WHEN valor_meta IS NULL OR valor_meta = 0 THEN 0
        WHEN sentido = 'abaixo' THEN
            ROUND(GREATEST(0, LEAST(100, (CAST(valor_meta AS NUMERIC) / NULLIF(valor_atual, 0)) * 100)))
        ELSE
            ROUND(GREATEST(0, LEAST(100, (CAST(valor_atual AS NUMERIC) / NULLIF(valor_meta, 0)) * 100)))
    END AS percentual,
    GREATEST(0, (data_fim - CURRENT_DATE)) AS dias_restantes
FROM metas;

CREATE OR REPLACE VIEW vw_resumo_executivo AS
SELECT
    -- Financeiro
    (SELECT COALESCE(SUM(valor),0) FROM lancamentos_financeiros WHERE tipo='receita'  AND DATE_TRUNC('month', data_competencia) = DATE_TRUNC('month', CURRENT_DATE)) AS receita_mes,
    (SELECT COALESCE(SUM(valor),0) FROM lancamentos_financeiros WHERE tipo='despesa'  AND DATE_TRUNC('month', data_competencia) = DATE_TRUNC('month', CURRENT_DATE)) AS despesa_mes,
    (SELECT COALESCE(SUM(valor),0) FROM lancamentos_financeiros WHERE tipo='receita'  AND EXTRACT(YEAR FROM data_competencia) = EXTRACT(YEAR FROM CURRENT_DATE)) AS receita_ano,
    (SELECT COALESCE(SUM(valor),0) FROM lancamentos_financeiros WHERE tipo='despesa'  AND EXTRACT(YEAR FROM data_competencia) = EXTRACT(YEAR FROM CURRENT_DATE)) AS despesa_ano,

    -- Folha (atletas + funcionários)
    (SELECT COALESCE(SUM(salario_bruto),0)       FROM contratos_atleta  WHERE status='ativo') AS folha_atletas,
    (SELECT COALESCE(SUM(salario),0)         FROM funcionarios      WHERE status='ativo') AS folha_funcionarios,

    -- Atletas
    (SELECT COUNT(*) FROM atletas WHERE status='ativo')                          AS atletas_ativos,
    (SELECT COUNT(*) FROM contratos_atleta WHERE status='ativo'
        AND data_fim BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '90 days') AS contratos_vencendo,

    -- Investidores
    (SELECT COALESCE(SUM(valor),0) FROM aportes WHERE tipo='aporte_capital')     AS total_capital_investido,
    (SELECT COALESCE(SUM(valor),0) FROM aportes WHERE tipo='emprestimo'
        AND (valor - COALESCE(valor_devolvido,0)) > 0)                           AS saldo_devedor_emprestimos,

    -- Pedidos
    (SELECT COUNT(*) FROM pedidos_compra WHERE status NOT IN ('concluido','cancelado')) AS pedidos_abertos,
    (SELECT COALESCE(SUM(valor_total_estimado),0) FROM pedidos_completo
        WHERE status NOT IN ('concluido','cancelado'))                            AS valor_pedidos_abertos,

    -- Metas
    (SELECT COUNT(*) FROM metas WHERE status='ativa')                            AS metas_ativas,
    (SELECT ROUND(AVG(percentual))  FROM metas_completo WHERE status='ativa')    AS progresso_medio_metas,
    (SELECT COUNT(*) FROM metas_completo WHERE status='ativa' AND percentual < 30
        AND dias_restantes < 30)                                                  AS metas_criticas;

-- ============================================================
-- VIEW: Evolução Financeira Mensal (últimos 12 meses)
-- ============================================================
CREATE OR REPLACE VIEW vw_evolucao_financeira AS
SELECT
    TO_CHAR(DATE_TRUNC('month', data_competencia), 'YYYY-MM') AS mes,
    TO_CHAR(DATE_TRUNC('month', data_competencia), 'Mon/YY')  AS mes_label,
    SUM(CASE WHEN tipo='receita' THEN valor ELSE 0 END)     AS receita,
    SUM(CASE WHEN tipo='despesa' THEN valor ELSE 0 END)     AS despesa,
    SUM(CASE WHEN tipo='receita' THEN valor ELSE 0 END)
  - SUM(CASE WHEN tipo='despesa' THEN valor ELSE 0 END)     AS resultado
FROM lancamentos_financeiros
WHERE data_competencia >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', data_competencia)
ORDER BY DATE_TRUNC('month', data_competencia);

-- ============================================================
-- VIEW: Folha Consolidada (atletas + funcionários)
-- ============================================================
CREATE OR REPLACE VIEW vw_folha_consolidada AS
SELECT
    'atleta'                                AS categoria,
    a.id                                    AS pessoa_id,
    a.nome,
    a.posicao                               AS cargo_posicao,
    ca.salario_bruto                        AS salario_bruto,
    ca.salario_carteira                     AS salario_carteira,
    ca.direitos_imagem                      AS complemento,
    ca.data_fim                             AS contrato_ate,
    a.status
FROM atletas a
JOIN contratos_atleta ca ON ca.id = (
    SELECT id FROM contratos_atleta
    WHERE atleta_id = a.id AND status = 'ativo'
    LIMIT 1
)
WHERE a.status = 'ativo'

UNION ALL

SELECT
    'funcionario'                           AS categoria,
    f.id                                    AS pessoa_id,
    f.nome_completo,
    f.cargo                                 AS cargo_posicao,
    f.salario                          AS salario_bruto,
    f.salario                          AS salario_carteira,
    0                                       AS complemento,
    NULL                                    AS contrato_ate,
    f.status
FROM funcionarios f
WHERE f.status = 'ativo'

ORDER BY categoria, salario_bruto DESC;

-- ============================================================
-- VIEW: Ranking de Fornecedores (por volume de pedidos)
-- ============================================================
CREATE OR REPLACE VIEW vw_ranking_fornecedores AS
SELECT
    f.id,
    f.nome,
    f.categoria,
    COUNT(pc.id)                            AS total_pedidos,
    COUNT(CASE WHEN pc.status='concluido' THEN 1 END) AS pedidos_concluidos,
    COALESCE(SUM(co.valor_total), 0)        AS volume_total
FROM fornecedores f
LEFT JOIN cotacoes co ON co.fornecedor_id = f.id
LEFT JOIN pedidos_compra pc ON pc.id = co.pedido_id
GROUP BY f.id, f.nome, f.categoria
ORDER BY volume_total DESC;

-- ============================================================
-- VIEW: Performance Esportiva por Competição
-- ============================================================
CREATE OR REPLACE VIEW vw_performance_esportiva AS
SELECT
    ea.competicao,
    ea.temporada,
    COUNT(DISTINCT ea.atleta_id)            AS atletas,
    SUM(ea.jogos)                           AS total_jogos,
    SUM(ea.gols)                            AS total_gols,
    SUM(ea.assistencias)                    AS total_assistencias,
    SUM(ea.clean_sheets)                    AS total_clean_sheets,
    SUM(ea.cartoes_amarelos)                AS total_amarelos,
    SUM(ea.cartoes_vermelhos)               AS total_vermelhos,
    CASE WHEN SUM(ea.jogos) > 0
        THEN ROUND(SUM(ea.gols)::NUMERIC / SUM(ea.jogos), 2)
        ELSE 0
    END                                     AS media_gols_jogo
FROM estatisticas_atleta ea
GROUP BY ea.competicao, ea.temporada
ORDER BY ea.temporada DESC, total_jogos DESC;

-- ============================================================
-- VIEW: Artilharia Geral
-- ============================================================
CREATE OR REPLACE VIEW vw_artilharia AS
SELECT
    a.id,
    a.nome,
    a.posicao,
    SUM(ea.gols)                            AS total_gols,
    SUM(ea.assistencias)                    AS total_assistencias,
    SUM(ea.jogos)                           AS total_jogos,
    SUM(ea.clean_sheets)                    AS total_clean_sheets,
    CASE WHEN SUM(ea.jogos) > 0
        THEN ROUND(SUM(ea.gols)::NUMERIC / SUM(ea.jogos), 2)
        ELSE 0
    END                                     AS media_gols
FROM atletas a
JOIN estatisticas_atleta ea ON ea.atleta_id = a.id
WHERE EXTRACT(YEAR FROM CURRENT_DATE)::TEXT = ea.temporada
GROUP BY a.id, a.nome, a.posicao
ORDER BY total_gols DESC, total_assistencias DESC;
