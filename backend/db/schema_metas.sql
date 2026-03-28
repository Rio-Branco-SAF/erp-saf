-- ============================================================
-- MÓDULC: BÓNCO DE DADOS - ERP SAF
— NÓDULC: METAS ESPORTIVAS E FINANCEIRAS
-- ERP SAF — Schema do Banco de Dados
- H!==============================================================

-- ------------------------------------------------------------
-- METAS
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS metas (
    id              SERIAL PRIMARY KEY,
    titulo          VARCHAR(200) NOT NULL,
    descricao       TEXT,

    -- Classificação da meta
    tipo            VARCHAR(20) NOT NULL
                    CHECK (tipo IN ('esportiva','financeira','institucional')),

    categoria       VARCHAR(40) NOT NULL
                    CHECK (categoria IN (
                        -- Esportivas
                        'classificacao',        -- posição na tabela / acesso
                        'pontuacao',            -- pontos no campeonato
                        'vitorias',             -- número de vitórias
                        'gols_marcados',        -- gols da equipe
                        'gols_sofridos',        -- gols sofridos (meta: abaixo de X)
                        'clean_sheets',         -- jogos sem tomar gol
                        'aproveitamento',       -- % de aproveitamento
                        'artilheiro',           -- artilheiro individual
                        'titulo',               -- conquista de título
                        -- Financeiras
                        'receita',              -- meta de receita total
                        'reducao_custos',       -- reduzir custos em X%
                        'patrocinio',           -- captação de patrocínio
                        'folha_limite',         -- folha dentro do orçamento
                        'lucro',                -- lucro líquido
                        'captacao',             -- captação de investimento
                        -- Institucionais
                        'formacao',             -- revelar X atletas da base
                        'publico',              -- média de público
                        'custom'                -- personalizada
                    )),

    temporada       VARCHAR(10) NOT NULL DEFAULT '2026',

    -- Valores de referência
    valor_meta      NUMERIC(14,2) NOT NULL,         -- alvo a atingir (ex: 60 pontos, R$500k)
    valor_atual     NUMERIC(14,2) NOT NULL DEFAULT 0, -- progresso atual
    unidade         VARCHAR(30) DEFAULT '',          -- ex: 'pontos', 'gols', 'R$', '%', 'vitórias'

    -- Para metas do tipo "abaixo de X" (ex: gols sofridos, custos)
    sentido         VARCHAR(10) DEFAULT 'acima'
                    CHECK (sentido IN ('acima','abaixo')),   -- acima = quanto maior melhor

    -- Datas
    data_inicio     DATE NOT NULL DEFAULT CURRENT_DATE,
    data_fim        DATE NOT NULL,

    -- Status
    status          VARCHAR(20) NOT NULL DEFAULT 'ativa'
                    CHECK (status IN ('ativa','concluida','nao_atingida','cancelada')),

    prioridade      VARCHAR(10) NOT NULL DEFAULT 'media'
                    CHECK (prioridade IN ('alta','media','baixa')),

    -- Responsável
    responsavel_id  INTEGER REFERENCES usuarios(id),

    -- Vínculo com outros módulos
    atleta_id       INTEGER REFERENCES atletas(id),   -- meta individual de atleta
    contrato_id     INTEGER REFERENCES contratos_atleta(id), -- meta de contrato

    observacoes     TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- ATUALIZAÇÕES DE PROGRESSO
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS atualizacoes_meta (
    id              SERIAL PRIMARY KEY,
    meta_id         INTEGER NOT NULL REFERENCES metas(id) ON DELETE CASCADE,
    usuario_id      INTEGER REFERENCES usuarios(id),
    valor_anterior  NUMERIC(14,2),
    valor_novo      NUMERIC(14,2) NOT NULL,
    descricao       TEXT,              -- ex: "Rodada 10 — vitória 2x0"
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- TRIGGER updated_at
-- ------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_metas_updated_at') THEN
        CREATE TRIGGER trg_metas_updated_at
            BEFORE UPDATE ON metas
            FOR EACH ROW EXECUTE FUNCTION atualizar_updated_at();
    END IF;
END
$$;

-- ------------------------------------------------------------
-- ÍNDICES
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_metas_tipo      ON metas(tipo);
CREATE INDEX IF NOT EXISTS idx_metas_status    ON metas(status);
CREATE INDEX IF NOT EXISTS idx_metas_temporada ON metas(temporada);
CREATE INDEX IF NOT EXISTS idx_atualizacoes    ON atualizacoes_meta(meta_id);

-- ------------------------------------------------------------
-- VIEW: metas com progresso calculado
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW metas_completo AS
SELECT
    m.*,
    u.nome AS responsavel_nome,
    a.nome AS atleta_nome,
    a.nome_guerra AS atleta_guerra,
    -- Percentual de progresso
    CASE
        WHEN m.valor_meta = 0 THEN 0
        WHEN m.sentido = 'abaixo' THEN
            GREATEST(0, LEAST(100, ROUND((1 - (m.valor_atual / m.valor_meta)) * 100)))
        ELSE
            LEAST(100, ROUND((m.valor_atual / m.valor_meta) * 100))
    END AS percentual,
    -- Dias restantes
    (m.data_fim - CURRENT_DATE) AS dias_restantes
FROM metas m
LEFT JOIN usuarios u ON u.id = m.responsavel_id
LEFT JOIN atletas  a ON a.id = m.atleta_id;
