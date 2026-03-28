-- ============================================================
-- MÓDULC: : PEDIDOS DE COMPRA
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
CREATE TABLE IF NOT EXISTS pedidos_compra (
    id                      SERIAL PRIMARY KEY,
    numero                  VARCHAR(20) NOT NULL UNIQUE,   -- ex: PC-2026-001
    titulo                  VARCHAR(200) NOT NULL,
    descricao               TEXT,

    -- Solicitante e departamento
    solicitante_id          INTEGER REFERENCES usuarios(id),
    departamento_id         INTEGER REFERENCES departamentos(id),

    -- Prioridade e prazo
    prioridade              VARCHAR(10) NOT NULL DEFAULT 'normal'
                            CHECK (prioridade IN ('baixa','normal','alta','urgente')),
    data_necessidade        DATE,

    -- Status do fluxo de aprovação
    status                  VARCHAR(30) NOT NULL DEFAULT 'rascunho'
                            CHECK (status IN (
                                'rascunho',
                                'aguardando_cotacao',                                   'em_cotacao',                                   'aguardando_aprovacao',                                  'aprovado',
                                     SERIAL PRIMARY KEY,
    pedido_id                   INTEGER NOT NULL REFERENCES pedidos_compra(id) ON DELETE CASCADE,
    descricao                   VARCHAR(300) NOT NULL,
    quantidade                  NUMERIC(10,2) NOT NULL DEFAULT 1,
    unidade                     VARCHAR(30) DEFAULT 'un',    -- un, kg, m, caixa, etc.
    valor_unitario_estimado     NUMERIC(12,2),
    valor_unitario_final        NUMERIC(12,2),
    observacoes                 TEXT,
    created_at                  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- COTAÇÕES (ORÇAEMENTCuS (ORÇAEMENE0