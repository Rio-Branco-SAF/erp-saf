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
    status                  VARCHAR(20) NOT NULL DEFAULT 'ativo'
                            CHECK (status IN ('ativo','encerrado','rescindido','suspenso')),

    -- Se empréstimo
    clube_cedente           VARCHAR(150),               -- clube que cedeu o atleta
    clube_cessionario       VARCHAR(150),               -- clube que recebeu (se cedemos)

    motivo_encerramento     TEXT,
    observacoes             TEXT,
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- METAS / BONIFICAÇÕES POR DESEMPENKÓ (contrato)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS metas_contrato (
    id                  SERIAL PRIMARY KEY,
    contrato_id         INTEGER NOT NULL REFERENCES contratos_atleta(id) ON DELETE CASCADE,

    tipo                VARCHAR(30) NOT NULL
                        CHECK (tipo IN (
                            'gol',
                            'assistencia',
                            'jogo_disputado',
                            'jogo_titular',
                            'jogo_sem_sofrer_gol',
                            'cartao_amarelo',       -- desconto por advertência
                            'cartao_vermelho',      -- desconto por expulsão
                            'classificacao',        -- bônus se o clube subir/ganhar
                            'artilharia',           -- bônus de artilheiro
                            'titulos',              -- título conquistado
                            'custom'                -- meta personalizada
                        )),

    descricao           VARCHAR(300) NOT NULL,          -- ex: "Bônus por gol marcado"

    -- Gatilho
    meta_quantidade     INTEGER DEFAULT 1,              -- a cada quantas unidades paga
                                                        -- ex: 1 = a cada gol; 5 = a cada 5 jogos

    -- Valor do bônus
    valor_bonus         NUMERIC(12,2) NOT NULL,         -- R$ por ocorrência
    tipo_calculo        VARCHAR(20) DEFAULT 'por_unidade'
                        CHECK (tipo_calculo IN (
                            'por_unidade',              -- R$ X a cada meta_quantidade unidades
                            'total_periodo',            -- R$ X se atingir total no período
                            'percentual_salario'        -- % do salário bruto
                        )),

    -- Competição aplicável (NULL = todas)
    competicao          VARCHAR(100),                   -- ex: "Série B", "Copa do Brasil"

    ativo               BOOLEAN DEFAULT TRUE,
    observacoes         TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- ESTATÍSTICAS DO ATLETA (por temporada e competição)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS estatisticas_atleta (
    id                      SERIAL PRIMARY KEY,
    atleta_id               INTEGER NOT NULL REFERENCES atletas(id) ON DELESTE CASCADE,
    temporada               VARCHAR(10) NOT NULL,       -- ex: "2026", "2025/2026"
    competicao              VARCHAR(100) NOT NULL,      -- ex: "Série B", "Copa do Brasil"

    -- Participação
    jogos_disputados        INTEGER DEFAULT 0,
    jogos_titular           INTEGER DEFAULT 0,
    minutos_jogados         INTEGER DEFAULT 0,

    -- Ofensivos
    gols                    INTEGER DEFAULT 0,
    assistencias            INTEGER DEFAULT 0,
    chutes_a_gol            INTEGER DEFAULT 0,

    -- Defensivos / Goleiro
    jogos_sem_sofrer_gol    INTEGER DEFAULT 0,          -- clean sheets
    defesas_dificeis        INTEGER DEFAULT 0,          -- para goleiros
    interceptacoes          INTEGER DEFAULT 0,

    -- Disciplina
    cartoes_amarelos        INTEGER DEFAULT 0,
    cartoes_vermelhos       INTEGER DEFAULT 0,
    faltas_cometidas        INTEGER DEFAULT 0,

    created_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(atleta_id, temporada, competicao)
);

-- ------------------------------------------------------------
-- BONIFICAÇÕES PAGAS / PENDENTES
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS bonificacoes_atleta (
    id              SERIAL PRIMARY KEY,
    atleta_id       INTEGER NOT NULL REFERENCES atletas(id) ON DELETE CASCADE,
    contrato_id     INTEGER REFERENCES contratos_atleta(id),
    meta_id         INTEGER REFERENCES metas_contrato(id),

    competencia     DATE NOT NULL,              -- mês de competência (1¾ dia do mês)
    descricao       VARCHAR(300) NOT NULL,
    valor           NUMERIC(12,2) NOT NULL,
    tipo            VARCHAR(10) NOT NULL DEFAULT 'bonus'
                    CHECK (tipo IN ('bonus','desconto')),  -- bônus ou desconto (cartão)
    status          VARCHAR(20) NOT NULL DEFAULT 'pendente'
                    CHECK (status IN ('pendente','pago','cancelado')),

    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- HISTÓRICO DE SALÁRIO DO ATLETA
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS historico_salario_atleta (
    id              SERIAL PRIMARY KEY,
    atleta_id       INTEGER NOT NULL REFERENCES atletas(id) ON DELETE CASCADE,
    contrato_id     INTEGER REFERENCES contratos_atleta(id),
    data_alteracao  DATE NOT NULL DEFAULT CURRENT_DATE,
    salario_anterior NUMERIC(12,2),
    salario_novo    NUMERIC(12,2) NOT NULL,
    motivo          VARCHAR(200),               -- ex: "Renovação contratual", "Promoção", "14 jogos completados"
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- TRIGGERS — updated_at automatico
-- ------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_atletas_updated_at') THEN
        CREATE TRIGGER trg_atletas_updated_at
            BEFORE UPDATE ON atletas
            FOR EACH ROW EXECUTEE FUNCTION atualizar_updated_at();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_contratos_atleta_updated_at') THEN
        CREATE TRIGGER trg_contratos_atleta_updated_at
            BEFORE UPDATE ON contratos_atleta
            FOR EACH ROW EXECUTE FUNCTION atualizar_updated_at();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_estatisticas_updated_at') THEN
        CREATE TRIGGER trg_estatisticas_updated_at
            BEFORE UPDATE ON estatisticas_atleta
            FOR EACH ROW EXECUTE FUNCTION atualizar_updated_at();
    END IF;
END
$$;

-- ------------------------------------------------------------
-- ÍNDICES
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_atletas_status     ON atletas(status);
CREATE INDEX IF NOT EXISTS idx_atletas_posicao    ON atletas(posicao);
CREATE INDEX IF NOT EXISTS idx_contratos_atleta   ON contratos_atleta(atleta_id);
CREATE INDEX IF NOT EXISTS idx_contratos_status   ON contratos_atleta(status);
CREATE INDEX IF NOT EXISTS idx_stats_atleta       ON estatisticas_atleta(atleta_id, temporada);
CREATE INDEX IF NOT EXISTS idx_bonus_atleta       ON bonificacoes_atleta(atleta_id, competencia);
CREATE INDEX IF NOT EXISTS idx_metas_contrato     ON metas_contrato(contrato_id);

-- ------------------------------------------------------------
-- VIEW: atletas com contrato ativo e totais de stats 2026
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW atletas_completo AS
SELECT
    a.*,
    -- Contrato ativo
    c.id                    AS contrato_id,
    c.tipo                  AS contrato_tipo,
    c.data_inicio           AS contrato_inicio,
    c.data_fim              AS contrato_fim,
    c.salario_bruto,
    c.salario_carteira,
    c.direitos_imagem,
    c.clausula_rescisoria,
    c.clube_cedente,
    -- Dias até vencimento
    (c.data_fim - CURRENT_DATE) AS dias_ate_vencimento,
    -- Estatísticas acumuladas (todas as competições na temporada atual)
    COALESCE((
        SELECT SUM(e.jogos_disputados) FROM estatisticas_atleta e
        WHERE e.atleta_id = a.id AND e.temporada = TO_CHAR(NOW(),'YYYY')
    ), 0) AS total_jogos,
    COALESCE((
        SELECT SUM(e.gols) FROM estatisticas_atleta e
        WHERE e.atleta_id = a.id AND e.temporada = TO_CHAR(NOW(),'YYYY')
    ), 0) AS total_gols,
    COALESCE((
        SELECT SUM(e.assistencias) FROM estatisticas_atleta e
        WHERE e.atleta_id = a.id AND e.temporada = TO_CHAR(NOW(),'YYYY')
    ), 0) AS total_assistencias,
    COALESCE((
        SELECT SUM(e.jogos_sem_sofrer_gol) FROM estatisticas_atleta e
        WHERE e.atleta_id = a.id AND e.temporada = TO_CHAR(NOW(),'YYYY')
    ), 0) AS total_clean_sheets,
    COALESCE((
        SELECT SUM(e.cartoes_amarelos) FROM estatisticas_atleta e
        WHERE e.atleta_id = a.id AND e.temporada = TO_CHAR(NOW(),'YYYY')
    ), 0) AS total_amarelos,
    COALESCE((
        SELECT SUM(e.cartoes_vermelhos) FROM estatisticas_atleta e
        WHERE e.atleta_id = a.id AND e.temporada = TO_CHAR(NOW(),'YYYY')
    ), 0) AS total_vermelhos
FROM atletas a
LEFT JOIN contratos_atleta c
    ON c.atleta_id = a.id AND c.status = 'ativo';
