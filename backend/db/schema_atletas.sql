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
-- CONTRATOS DE ATLETAS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS contratos_atleta (
    id                      SERIAL PRIMARY KEY,
    atleta_id               INTEGER NOT NULL REFERENCES atletas(id) ON DELETE CASCADE,
    numero_contrato         VARCHAR(50),

    tipo                    VARCHAR(20) NOT NULL DEFAULT 'profissional'
                            CHECK (tipo IN ('profissional','amador','emprestimo','formacao')),

    -- Vigência
    data_inicio             DATE NOT NULL,
    data_fim                DATE NOT NULL,

    -- Remuneração
    salario_bruto           NUMERIC(12,2) NOT NULL,     -- salário total combinado
    salario_carteira        NUMERIC(12,2),              -- valor registrado na CTPS (CLT)
    direitos_imagem         NUMERIC(12,2) DEFAULT 0,    -- parcela de imagem (PJ)
    luvas                   NUMERIC(12,2) DEFAULT 0,    -- bônus de assinatura
    clausula_rescisoria     NUMERIC(12,2),              -- multa rescisória

    -- Status do contrato
    status       