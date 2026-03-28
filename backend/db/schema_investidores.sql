-- ============================================================
-- MÓDULC: 5: INVESTIDORES E APORTES
-- ERP SAF — Schema do Banco de Dados
-- ===========================================================

-- ------------------------------------------------------------
-- INVESTIDORES
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS investidores (
    id              SERIAL PRIMARY KEY,
    nome            VARCHAR(200) NOT NULL,
    tipo            VARCHAR(20) NOT NULL DEFAULT 'pessoa_fisica'
                    CHECK (tipo IN ('pessoa_fisica','pessoa_juridica')),

    -- Documentos
    cpf_cnpj        VARCHAR(18),
    rg              VARCHAR(20),

    -- Perfil de investimento
    perfil          VARCHAR(30) NOT NULL DEFAULT 'investidor'
                    CHECK (perfil IN (
                        'socio',              -- sócio com participação acionária
                        'patrocinador',       -- patrocinador (visibilidade/marketing)
                        'investidor',         -