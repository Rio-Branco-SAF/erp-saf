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
CREATE OR REPLACE VIEW vw_resumo_executivo AS
SELECT
    -- Financeiro
    (SELECT COALESCE(SUM(valor),0) FROM transacoes WHERE tipo='receita'  AND DATE_TRUNC('month', data_transacao) = DATE_TRUNC('month', CURRENT_DATE)) AS receita_mes,
    (SELECT COALESCE(SUM(valor),0) FROM transacoes WHERE tipo='despesa'  AND DATE_TRUNC('month', data_transacao) = DATE_TRUNC('month', CURRENT_DATE)) AS despesa_mes,
    (SELECT COALESCE(SUM(valor),0) FROM transacoes WHERE tipo='receita'  AND EXTRACT(YEAR FROM data_transacao) = EXTRACT(YEAR FROM CURRENT_DATE)) AS receita_ano,
    (SELECT COALESCE(SUM(valor),0) FROM transacoes WHERE tipo='despesa'  AND EXTRACT(YEAR FROM data_transacao) = EXTRACT(YEAR FROM CURRENT_DATE)) AS despesa_ano,

    -- Folha (atletas + funcionários)
    (SELECT COALESCE(SUM(salario_bruto),0)       FROM contratos_atleta  WHERE status='ativo') AS folha_atletas,
    (SELECT COALESCE(SUM(salario_base),0)         FROM funcionarios      WHERE status='ativo') AS folha_funcionarios,

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
