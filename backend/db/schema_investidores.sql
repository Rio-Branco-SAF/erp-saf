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
    investidor_id   INTEGER NOT NULL REFERENCES investidores(id) ON DELETE CASCADE,

    tipo            VARCHAR(25) NOT NULL
                    CHECK (tipo IN (
                        'aporte_capital',   -- entrada de capital (equity)
                        'patrocinio',       -- patrocínio (custeio sem retorno financeiro)
                        'emprestimo',       -- empréstimo (deve ser devolvido + juros)
                        'doacao'            -- doação sem retorno
                    )),

    descricao       VARCHAR(300) NOT NULL,
    valor           NUMERIC(14,2) NOT NULL CHECK (valor > 0),

    data_aporte     DATE NOT NULL DEFAULT CURRENT_DATE,
    competencia     DATE,                -- mês de competência contábil

    -- Para aportes de capital: equity concedido
    percentual_concedido NUMERIC(6,3) DEFAULT 0,   -- % do clube concedido neste aporte

    -- Para empréstimos
    taxa_juros_anual    NUMERIC(5,2),              -- ex: 12.00 = 12% a.a.
    data_vencimento     DATE,                       -- prazo para devolução
    valor_devolvido     NUMERIC(14,2) DEFAULT 0,   -- quanto já foi pago de volta

    -- Para patrocínios: o que o patrocinador recebe em troca
    contrapartida       TEXT,                       -- ex: "Camisa + banner estádio"

    status          VARCHAR(20) NOT NULL DEFAULT 'confirmado'
                    CHECK (status IN ('pendente','confirmado','cancelado')),

    comprovante     VARCHAR(300),                   -- nome do arquivo
    observacoes     TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- RETORNOS AOS INVESTIDORES (dividendos, juros, devoluções)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS retornos_investidor (
    id              SERIAL PRIMARY KEY,
    investidor_id   INTEGER NOT NULL REFERENCES investidores(id) ON DELETE CASCADE,
    aporte_id       INTEGER REFERENCES aportes(id),

    tipo            VARCHAR(20) NOT NULL
                    CHECK (tipo IN (
                        'dividendo',        -- distribuição de lucro
                        'juros',            -- juros de empréstimo
                        'devolucao',        -- devolução de capital
                        'bonificacao'       -- bonificação extra
                    )),

    descricao       VARCHAR(300) NOT NULL,
    valor           NUMERIC(14,2) NOT NULL CHECK (valor > 0),
    data_pagamento  DATE NOT NULL,
    competencia     DATE,

    status          VARCHAR(20) NOT NULL DEFAULT 'pendente'
                    CHECK (status IN ('pendente','pago','cancelado')),

    observacoes     TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- DOCUMENTOS DO INVESTIDOR
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS documentos_investidor (
    id              SERIAL PRIMARY KEY,
    investidor_id   INTEGER NOT NULL REFERENCES investidores(id) ON DELETE CASCADE,
    nome            VARCHAR(200) NOT NULL,
    tipo            VARCHAR(50),          -- ex: "Contrato", "Comprovante", "NDA"
    arquivo         VARCHAR(300),
    observacoes     TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- TRIGGER updated_at
-- ------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_investidores_updated_at') THEN
        CREATE TRIGGER trg_investidores_updated_at
            BEFORE UPDATE ON investidores
            FOR EACH ROW EXECUTE FUNCTION atualizar_updated_at();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_aportes_updated_at') THEN
        CREATE TRIGGER trg_aportes_updated_at
            BEFORE UPDATE ON aportes
            FOR EACH ROW EXECUTE FUNCTION atualizar_updated_at();
    END IF;
END
$$;

-- ------------------------------------------------------------
-- ÍNDICES
-- ----------------------------------