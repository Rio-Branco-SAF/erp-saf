-- ============================================================
-- SEED: METAS — Dados de Demonstração
-- ERP SAF — Temporada 2026
-- ============================================================

-- ------------------------------------------------------------
-- METAS ESPORTIVAS
-- ------------------------------------------------------------
INSERT INTO metas
    (titulo, descricao, tipo, categoria, temporada, valor_meta, valor_atual,
     unidade, sentido, data_inicio, data_fim, status, prioridade, observacoes)
VALUES

-- PRINCIPAL: ACESSO À SÉRIE A
(
    'Acesso à Série A 2027',
    'Terminar a Série B 2026 entre os 4 primeiros colocados para garantir o acesso à Série A do Brasileirão.',
    'esportiva', 'classificacao', '2026',
    4, 6,    -- meta: top 4 | atual: 6º lugar
    'posição', 'abaixo',
    '2026-04-12', '2026-11-29',
    'ativa', 'alta',
    'A temporada começou bem, mas precisamos subir mais 2 posições. 28 rodadas ainda pela frente.'
),

-- PONTUAÇÃO
(
    'Atingir 65 pontos na Série B',
    'Acumular pelo menos 65 pontos na Série B para garantir o acesso com tranquilidade.',
    'esportiva', 'pontuacao', '2026',
    65, 18,
    'pontos', 'acima',
    '2026-04-12', '2026-11-29',
    'ativa', 'alta',
    '10 rodadas disputadas. Média atual: 1,8 pts/jogo. Precisamos manter ritmo.'
),

-- APROVEITAMENTO
(
    'Aproveitamento mínimo de 60%',
    'Manter aproveitamento acima de 60% ao longo de toda a Série B.',
    'esportiva', 'aproveitamento', '2026',
    60, 60,
    '%', 'acima',
    '2026-04-12', '2026-11-29',
    'ativa', 'media',
    '6 vitórias, 0 empates, 4 derrotas nas 10 primeiras rodadas = 60% de aproveitamento.'
),

-- VITÓRIAS
(
    'Mínimo de 20 vitórias na Série B',
    'Vencer pelo menos 20 jogos ao longo das 38 rodadas.',
    'esportiva', 'vitorias', '2026',
    20, 6,
    'vitórias', 'acima',
    '2026-04-12', '2026-11-29',
    'ativa', 'media',
    NULL
),

-- GOLS SOFRIDOS (meta: abaixo de X)
(
    'Sofrer menos de 30 gols na temporada',
    'Manter a defesa sólida com menos de 30 gols sofridos em toda a Série B.',
    'esportiva', 'gols_sofridos', '2026',
    30, 12,
    'gols sofridos', 'abaixo',
    '2026-04-12', '2026-11-29',
    'ativa', 'media',
    '10 rodadas: 12 gols sofridos. Ritmo atual projetaria 45 ao final. Precisa melhorar.'
),

-- CLEAN SHEETS
(
    'Mínimo de 12 jogos sem sofrer gol',
    'Conquistar pelo menos 12 clean sheets na temporada entre todas as competições.',
    'esportiva', 'clean_sheets', '2026',
    12, 8,
    'clean sheets', 'acima',
    '2026-01-01', '2026-11-29',
    'ativa', 'media',
    'Ricardo já tem 8 clean sheets em 13 jogos. Ritmo excelente!'
),

-- ARTILHEIRO (meta individual — Alemão)
(
    'Alemão: 20 gols na temporada',
    'Alexandre "Alemão" Costa atingir a marca de 20 gols considerando todas as competições em 2026.',
    'esportiva', 'artilheiro', '2026',
    20, 12,
    'gols', 'acima',
    '2026-01-01', '2026-11-29',
    'ativa', 'alta',
    '12 gols em 13 jogos. Ritmo impressionante — lidera a artilharia da Série B.'
),

-- TITULO COPA
(
    'Avançar às quartas de final da Copa do Brasil',
    'Chegar pelo menos às quartas de final da Copa do Brasil 2026.',
    'esportiva', 'titulo', '2026',
    1, 1,
    'fase', 'acima',
    '2026-01-01', '2026-08-31',
    'ativa', 'media',
    'Já avançamos para as oitavas. Meta mínima quase atingida.'
),

-- REVELAÇÃO DA BASE
(
    'Promover 2 atletas da base ao profissional',
    'Revelar e promover pelo menos 2 atletas das categorias de base para o elenco profissional em 2026.',
    'institucional', 'formacao', '2026',
    2, 1,
    'atletas', 'acima',
    '2026-01-01', '2026-12-31',
    'ativa', 'media',
    'Lukinha já foi promovido. Mateuzinho em observação.'
),

-- PÚBLICO
(
    'Média de 8.000 torcedores por jogo',
    'Alcançar média de público acima de 8.000 pagantes nos jogos como mandante na Série B.',
    'institucional', 'publico', '2026',
    8000, 6800,
    'torcedores', 'acima',
    '2026-04-12', '2026-11-29',
    'ativa', 'baixa',
    '5 jogos em casa. Média atual: 6.800. Crescimento em relação a 2025 (+15%).'
);

-- ------------------------------------------------------------
-- METAS FINANCEIRAS
-- ------------------------------------------------------------
INSERT INTO metas
    (titulo, descricao, tipo, categoria, temporada, valor_meta, valor_atual,
     unidade, sentido, data_inicio, data_fim, status, prioridade, observacoes)
VALUES

-- RECEITA TOTAL
(
    'Receita total de R$ 12M em 2026',
    'Atingir receita total de R$ 12 milhões somando patrocínios, bilheteria, direitos de TV, premiações e vendas.',
    'financeira', 'receita', '2026',
    12000000, 4800000,
    'R$', 'acima',
    '2026-01-01', '2026-12-31',
    'ativa', 'alta',
    'Março/2026: R$ 4,8M (40% da meta em 3 meses). Ritmo adequado.'
),

-- CAPTAÇÃO DE PATROCÍNIO
(
    'Captar R$ 1,5M em patrocínios em 2026',
    'Fechar novos contratos de patrocínio totalizando pelo menos R$ 1,5 milhão no ano.',
    'financeira', 'patrocinio', '2026',
    1500000, 860000,
    'R$', 'acima',
    '2026-01-01', '2026-12-31',
    'ativa', 'alta',
    'Apex R$600k + Saúde Total R$200k + Rodrigues R$60k = R$860k. Faltam R$640k.'
),

-- FOLHA DE PAGAMENTO
(
    'Folha de atletas abaixo de R$ 380k/mês',
    'Manter a folha total de atletas dentro do limite orçamentário de R$ 380 mil por mês.',
    'financeira', 'folha_limite', '2026',
    380000, 312000,
    'R$/mês', 'abaixo',
    '2026-01-01', '2026-12-31',
    'ativa', 'alta',
    'Folha atual: R$ 312k. Meta cumprida com folga. Atenção às renovações em curso.'
),

-- REDUÇÃO DE CUSTOS OPERACIONAIS
(
    'Reduzir custos operacionais em 10% vs 2025',
    'Reduzir despesas operacionais (excluindo folha) em 10% comparado ao exercício de 2025.',
    'financeira', 'reducao_custos', '2026',
    10, 6,
    '%', 'acima',
    '2026-01-01', '2026-12-31',
    'ativa', 'media',
    '6% de redução atingida até março. Negociações com fornecedores em andamento.'
),

-- CAPTAÇÃO DE INVESTIMENTO
(
    'Captar R$ 1M em novos aportes de sócios',
    'Atrair novos sócios investidores ou aportes adicionais dos sócios atuais totalizando R$ 1 milhão.',
    'financeira', 'captacao', '2026',
    1000000, 700000,
    'R$', 'acima',
    '2026-01-01', '2026-12-31',
    'ativa', 'alta',
    'Grupo Vitória aportou R$700k em janeiro. Negociação com novo sócio em andamento.'
),

-- RESULTADO FINANCEIRO (LUCRO)
(
    'Resultado operacional positivo em 2026',
    'Fechar 2026 com superávit operacional — receitas superando despesas operacionais.',
    'financeira', 'lucro', '2026',
    1, 1,
    'superávit', 'acima',
    '2026-01-01', '2026-12-31',
    'ativa', 'alta',
    'Projeção positiva se o acesso ocorrer (premiação + aumento de receitas).'
);

-- ------------------------------------------------------------
-- ATUALIZAÇÕES DE PROGRESSO (histórico)
-- ------------------------------------------------------------
INSERT INTO atualizacoes_meta (meta_id, valor_anterior, valor_novo, descricao) VALUES
-- Meta 1: Classificação
(1,  8,  7, 'Rodada 7 — vitória 2x1. Subimos uma posição.'),
(1,  7,  6, 'Rodada 10 — vitória 3x0. 5º lugar.'),

-- Meta 2: Pontuação
(2,  0,  6,  'Rodadas 1-3: 2V, 0E, 1D = 6 pts'),
(2,  6, 12, 'Rodadas 4-6: 2V, 0E, 1D = 6 pts'),
(2, 12, 18, 'Rodadas 7-10: 2V, 0E, 2D = 6 pts'),

-- Meta 7: Artilheiro (Alemão)
(7,  0,  4,  'Fevereiro — 4 gols na Série B'),
(7,  4,  8,  'Fevereiro — 4 gols na Copa do Brasil'),
(7,  8, 12,  'Março — 4 gols na Série B. Total: 12 gols em 13 jogos!'),

-- Meta 11: Receita
(11, 0,       1600000, 'Janeiro 2026 — aportes + patrocínio master Apex'),
(11, 1600000, 3200000, 'Fevereiro — patrocínios + bilheteria + cotas TV'),
(11, 3200000, 4800000, 'Março — premiação Copa do Brasil + patrocínios'),

-- Meta 12: Patrocínio
(12, 0,      600000, 'Contrato Apex Construções assinado — R$60k'),
(12, 600000, 800000, 'Saúde Total cota ouro – R$200k'),
(12, 800000, 860000, 'Rodrigues Peças cota prata – R$60k');
