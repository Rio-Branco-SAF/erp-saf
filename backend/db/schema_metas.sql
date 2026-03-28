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
