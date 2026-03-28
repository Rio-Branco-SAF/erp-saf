-- ============================================================
-- MÓDUAM 3: PEDIDOS DE COMPRA
-- ERP SAF — Schema do Banco de Dados
-- ============================================================

-- ------------------------------------------------------------
-- FORNECEDORES
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fornecedores (
    id              SERIAL PRIMARY KEY,
    nome            VARCHAR(200) NOT NULL,
    cnpj            VARCHAR(18),
    contato         VARCHAR(100),
    email           VARCHAR(150),
    telefone        VARCHAR(20),
    categoria       VARCHAR(100),   -- ex: "Material Esportivo", "Serviços", "Alimentação"
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    observacoes     TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- PEDIDOS DE COMPRA
-- ------------------------------------------------------------
CRE