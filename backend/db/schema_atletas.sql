-- ============================================================
-- MÓDULC: 4: ATLETA
-- ERP SAF — Schema do Banco de Dados
-- ============================================================

-- ------------------------------------------------------------
-- ATLETAS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS atletas (
    id                  SERIAL PRIMARY KEY,
    nome                VARCHAR(200) NOT NULL,
    nome_guerra         VARCHAR(80),            -- nome em campo (ex: "Ronaldinho")
    foto_url            VARCHAR(300),

    -- Documentos pessoais
    cpf                 VARCHAR(14),
    rg                  VARCHAR(20),
    passaporte          VARCHAR(30),
    data_nascimento     DATE,
    nacionalidade       VARCHAR(80) DEFAULT 'Brasileira',
    naturalidade        VARCHAR(100),           -- cidade/estado de origem

    -- Dados físicos
    posicao             VARCHAR(30) NOT NULL
                        CHECK (posicao IN (
                            'goleiro','lateral_direito','lateral_esquerdo',
                            'zagueiro','volante','meia_central',
                            'meia_atacante','ponta_direita','ponta_esquerda',
                            'centroavante'
                        )),
    pe_dominante        VARCHAR(10) DEFAULT 'direito'
                        CHECK (pe_dominante IN ('direito','esquerdo','ambidestro')),
    altura_cm           INTEGER,                -- ex: 182
    peso_kg             NUMERIC(5,2),           -- ex: 78.5

    -- Status
    status              VARCHAR(20) NOT NULL DEFAULT 'ativo'
                        CHECK (status IN ('ativo','lesionado','emprestado','suspenso','inativo')),

    -- Clube origem / formação
    clube_formacao      VARCHAR(100),
    agente              VARCHAR(150),           -- representante / agente

    observacoes         TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- CONTRATO