-- ============================================================
-- MÓDULO 5: INVESTIDORES E APORTES
-- ERP SAF — Schema do Banco de Dados
-- ============================================================

-- ------------------------------------------------------------
-- INVESTIDORES
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS investidores (
    id              SERIAL PRIMARY KEY,
    nome            VARCHAR(200) NOT NULL,
    tipo            VARCHAR(20) NOT NULL DEFAULT 'pessoa_fisica'
                    CHECK (tipo IN ('pessoa_fisica','pessoa_juridica')),
    cpf_cnpj        VARCHAR(18),
    rg              VARCHAR(20),
    perfil          VARCHAR(30) NOT NULL DEFAULT 'investidor'
                    CHECK (perfil IN ('socio','patrocinador','investidor','mecenatismo')),
    email           VARCHAR(150),
    telefone        VARCHAR(20),
    endereco        TEXT,
    nome_fantasia   VARCHAR(150),
    responsavel     VARCHAR(150),
    percentual_participacao NUMERIC(6,3) DEFAULT 0,
    ativo           BOOLEAN DEFAULT TRUE,
    observacoes     TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS aportes (
    id              SERIAL PRIMARY KEY,
    investidor_id   INTEGER NOT NULL REFERENCES investidores(id) ON DELETE CASCADE,
    tipo            VARCHAR(25) NOT NULL
                    CHECK (tipo IN ('aporte_capital','patrocinio','emprestimo','doacao')),
    descricao       VARCHAR(300) NOT NULL,
    valor           NUMERIC(14,2) NOT NULL CHECK (valor > 0),
    data_aporte     DATE NOT NULL DEFAULT CURRENT_DATE,
    competencia     DATE,
    percentual_concedido NUMERIC(6,3) DEFAULT 0,
    taxa_juros_anual    NUMERIC(5,2),
    data_vencimento     DATE,
    valor_devolvido     NUMERIC(14,2) DEFAULT 0,
    contrapartida       TEXT,
    status          VARCHAR(20) NOT NULL DEFAULT 'confirmado'
                    CHECK (status IN ('pendente','confirmado','cancelado')),
    comprovante     VARCHAR(300),
    observacoes     TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS retornos_investidor (
    id              SERIAL PRIMARY KEY,
    investidor_id   INTEGER NOT NULL REFERENCES investidores(id) ON DELETE CASCADE,
    aporte_id       INTEGER REFERENCES aportes(id),
    tipo            VARCHAR(20) NOT NULL
                    CHECK (tipo IN ('dividendo','juros','devolucao','bonificacao')),
    descricao       VARCHAR(300) NOT NULL,
    valor           NUMERIC(14,2) NOT NULL CHECK (valor > 0),
    data_pagamento  DATE NOT NULL,
    competencia     DATE,
    status          VARCHAR(20) NOT NULL DEFAULT 'pendente'
                    CHECK (status IN ('pendente','pago','cancelado')),
    observacoes     TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_aportes_investidor  ON aportes(investidor_id);
CREATE INDEX IF NOT EXISTS idx_retornos_investidor ON retornos_investidor(investidor_id);

CREATE OR REPLACE VIEW investidores_completo AS
SELECT i.*,
    COALESCE((SELECT SUM(a.valor) FROM aportes a WHERE a.investidor_id = i.id AND a.status = 'confirmado'), 0) AS total_aportado,
    COALESCE((SELECT SUM(a.valor) FROM aportes a WHERE a.investidor_id = i.id AND a.tipo = 'patrocinio' AND a.status = 'confirmado'), 0) AS total_patrocinio,
    COALESCE((SELECT SUM(a.valor) FROM aportes a WHERE a.investidor_id = i.id AND a.tipo = 'emprestimo' AND a.status = 'confirmado'), 0) AS total_emprestado,
    COALESCE((SELECT SUM(r.valor) FROM retornos_investidor r WHERE r.investidor_id = i.id AND r.status = 'pago'), 0) AS total_retornado
FROM investidores i;
