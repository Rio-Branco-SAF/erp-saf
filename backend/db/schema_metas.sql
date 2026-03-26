-- ============================================================
-- MÓDULC: METAS ESPORTIVAS E FINANCEIRAS
-- ERP SAF — Schema do Banco de Dados
-- ===========================================================

-- ------------------------------------------------------------
-- METAS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS metas (
    id              SERIAL PRIMARY KEY,
    titulo          VARCHAR(200) NOT NULL,
    descricao       TEXT
