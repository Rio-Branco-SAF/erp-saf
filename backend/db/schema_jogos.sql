-- ============================================================
-- MÓDULO 8 — AGENDA DE JOGOS
-- Schema: jogos, orçamentos automáticos, público e receitas
-- ============================================================

-- ─── Templates de orçamento (base automática por tipo) ────────
CREATE TABLE IF NOT EXISTS templates_orcamento_jogo (
    id          SERIAL PRIMARY KEY,
    nome        VARCHAR(100) NOT NULL,
    tipo_jogo   VARCHAR(20) NOT NULL CHECK (tipo_jogo IN ('mandante','visitante','neutro')),
    competicao  VARCHAR(60),          -- NULL = válido para qualquer competição
    ativo       BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS itens_template_orcamento (
    id              SERIAL PRIMARY KEY,
    template_id     INTEGER NOT NULL REFERENCES templates_orcamento_jogo(id) ON DELETE CASCADE,
    categoria       VARCHAR(60) NOT NULL,
    descricao       VARCHAR(150) NOT NULL,
    valor_padrao    NUMERIC(12,2) NOT NULL DEFAULT 0,
    obrigatorio     BOOLEAN DEFAULT TRUE,
    ordem           INTEGER DEFAULT 0
);

-- ─── Jogos ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS jogos (
    id              SERIAL PRIMARY KEY,
    competicao      VARCHAR(80) NOT NULL,
    rodada          VARCHAR(40),                  -- "Rodada 12", "Oitavas de Final", etc.
    adversario      VARCHAR(100) NOT NULL,
    data_jogo       TIMESTAMP NOT NULL,
    local_jogo      VARCHAR(150),
    tipo_jogo       VARCHAR(20) NOT NULL CHECK (tipo_jogo IN ('mandante','visitante','neutro')),
    status          VARCHAR(20) NOT NULL DEFAULT 'agendado'
                    CHECK (status IN ('agendado','confirmado','realizado','cancelado','adiado')),

    -- Resultado
    gols_nos        INTEGER,
    gols_adversario INTEGER,

    -- Público
    capacidade_estadio  INTEGER,
    publico_pagante     INTEGER,
    publico_cortesias   INTEGER,
    publico_total       INTEGER GENERATED ALWAYS AS (
                            COALESCE(publico_pagante,0) + COALESCE(publico_cortesias,0)
                        ) STORED,

    -- Flags
    transmissao_tv      BOOLEAN DEFAULT FALSE,
    transmissao_streaming BOOLEAN DEFAULT FALSE,
    observacoes         TEXT,

    created_by      INTEGER REFERENCES usuarios(id),
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);
SELECT criar_trigger_updated_at('jogos');

-- ─── Orçamento do jogo ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orcamentos_jogo (
    id          SERIAL PRIMARY KEY,
    jogo_id     INTEGER NOT NULL REFERENCES jogos(id) ON DELETE CASCADE,
    status      VARCHAR(20) DEFAULT 'rascunho'
                CHECK (status IN ('rascunho','aprovado','realizado')),
    aprovado_por INTEGER REFERENCES usuarios(id),
    aprovado_em  TIMESTAMP,
    observacoes  TEXT,
    created_at   TIMESTAMP DEFAULT NOW(),
    updated_at   TIMESTAMP DEFAULT NOW(),
    UNIQUE(jogo_id)
);
SELECT criar_trigger_updated_at('orcamentos_jogo');

CREATE TABLE IF NOT EXISTS itens_orcamento_jogo (
    id              SERIAL PRIMARY KEY,
    orcamento_id    INTEGER NOT NULL REFERENCES orcamentos_jogo(id) ON DELETE CASCADE,
    categoria       VARCHAR(60) NOT NULL,
    descricao       VARCHAR(150) NOT NULL,
    valor_estimado  NUMERIC(12,2) NOT NULL DEFAULT 0,
    valor_realizado NUMERIC(12,2),
    pago            BOOLEAN DEFAULT FALSE,
    fornecedor      VARCHAR(100),
    ordem           INTEGER DEFAULT 0
);

-- ─── Receitas do jogo ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS receitas_jogo (
    id              SERIAL PRIMARY KEY,
    jogo_id         INTEGER NOT NULL REFERENCES jogos(id) ON DELETE CASCADE,
    tipo            VARCHAR(40) NOT NULL
                    CHECK (tipo IN (
                        'bilheteria_socio','bilheteria_inteira','bilheteria_meia',
                        'patrocinio_jogo','cota_tv','streaming','merchandising',
                        'alimentacao','estacionamento','outro'
                    )),
    descricao       VARCHAR(150),
    quantidade      INTEGER,               -- ingressos vendidos (p/ bilheteria)
    valor_unitario  NUMERIC(10,2),
    valor_total     NUMERIC(12,2) NOT NULL,
    realizado       BOOLEAN DEFAULT FALSE, -- estimado vs realizado
    created_at      TIMESTAMP DEFAULT NOW()
);

-- ─── Gols do jogo ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS gols_jogo (
    id          SERIAL PRIMARY KEY,
    jogo_id     INTEGER NOT NULL REFERENCES jogos(id) ON DELETE CASCADE,
    atleta_id   INTEGER REFERENCES atletas(id),
    minuto      INTEGER,
    tipo        VARCHAR(20) DEFAULT 'normal'
                CHECK (tipo IN ('normal','penalti','falta','cabeca','contra','outro')),
    time        VARCHAR(10) NOT NULL CHECK (time IN ('nos','adversario')),
    assistente_id INTEGER REFERENCES atletas(id)
);

-- ─── View: Jogos completos ────────────────────────────────────
CREATE OR REPLACE VIEW jogos_completo AS
SELECT
    j*,
    -- Resultado formatado
    CASE
        WHEN j.status = 'realizado' AND j.gols_nos IS NOT NULL
        THEN CONCAT(j.gols_nos, ' x ', j.gols_adversario)
        ELSE NULL
    END AS placar,
    CASE
        WHEN j.status = 'realizado' AND j.gols_nos IS NOT NULL THEN
            CASE
                WHEN j.gols_nos > j.gols_adversario  THEN 'vitoria'
                WHEN j.gols_nos < j.gols_adversario  THEN 'derrota'
                ELSE 'empate'
            END
        ELSE NULL
    END AS resultado,
    -- Ocupação do estádio
    CASE
        WHEN j.capacidade_estadio > 0 AND j.publico_total > 0
        THEN ROUND((j.publico_total::NUMERIC / j.capacidade_estadio) * 100, 1)
        ELSE NULL
    END AS ocupacao_pct,
    -- Financeiro
    COALESCE((SELECT SUM(valor_estimado) FROM itens_orcamento_jogo ioj
              JOIN orcamentos_jogo oj ON oj.id = ioj.orcamento_id
              WHERE oj.jogo_id = j.id), 0) AS custo_estimado,
    COALESCE((SELECT SUM(valor_realizado) FROM itens_orcamento_jogo ioj
              JOIN orcamentos_jogo oj ON oj.id = ioj.orcamento_id
              WHERE oj.jogo_id = j.id AND ioj.valor_realizado IS NOT NULL), 0) AS custo_realizado,
    COALESCE((SELECT SUM(valor_total) FROM receitas_jogo rj WHERE rj.jogo_id = j.id), 0) AS receita_total,
    -- Qtd gols
    (SELECT COUNT(*) FROM gols_jogo gj WHERE gj.jogo_id = j.id AND gj.time = 'nos') AS qtd_gols_marcados,
    -- Status do orçamento
    (SELECT oj.status FROM orcamentos_jogo oj WHERE oj.jogo_id = j.id) AS orcamento_status
FROM jogos j;
