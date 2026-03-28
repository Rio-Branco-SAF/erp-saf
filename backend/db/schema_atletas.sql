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
                            'goleiro','lateral_direito',