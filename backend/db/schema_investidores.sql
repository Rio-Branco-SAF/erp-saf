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
                        'investidor',         -- investidor financeiro (retorno esperado)
                        'mecenatismo'         -- mecenas / doador (sem retorno esperado)
                    )),

    -- Contato
    email           VARCHAR(150),
    telefone        VARCHAR(20),
    endereco        TEXT,

    -- Pessoa jurídica
    nome_fantasia   VARCHAR(150),        -- nome da empresa (se PJ)
    responsavel     VARCHAR(150),        -- nome do responsável na empresa

    -- Participação acionária total acumulada
    percentual_participacao NUMERIC(6,3) DEFAULT 0, -- % do clube (até 49.9% possível)

    ativo           BOOLEAN DEFAULT TRUE,
    observacoes     TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- APORTES (investimentos / patrocínios / empréstimos)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS aportes (
    id              SERIAL PRIMARY KEY,
    investidor_id   INT