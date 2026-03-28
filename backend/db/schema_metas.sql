-- ===========================================================
-- MÓDULO 6: METAS ESPORTIVAS E FINANCEIRAS
-- ERP SAF — Schema do Banco de Dados
-- ============================================================

-- ------------------------------------------------------------
-- METAS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS metas (
    id              SERIAL PRIMARY KEY,
    titulo          VARCHAR(200) NOT NULL,
    descricao       TEXT,

    -- Classificação da meta
    tipo            VARCHAR(20) NOT NULL
                    CHECK (tipo IN ('esportiva','financeira','institucional')),

    categoria       VARCHAR(40) NOT NULL
                    CHECK (categoria IN (
                        -- Esportivas
                        'classificacao',        -- posição na tabela / acesso
                        'pontuacao',            -- pontos no campeonato
                        'vitorias',             -- número de vitórias
                        'gols_marcados',        -- gols 