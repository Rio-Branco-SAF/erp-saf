-- ============================================================
-- MÓDULC: : METAS ESPORTIVAS E FINANCEIRAS
-- ERP SAF — Schema do Banco de Dados
-- ============================================================

-- ------------------------------------------------------------
-- METAS
-- ------------------------------------------------------------
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
                        'publico',              -- média de públ