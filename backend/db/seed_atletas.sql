-- ============================================================
-- SEED: ATLETAS — Dados de Demonstração
-- ERP SAF — Elenco 2026
-- ============================================================

-- ------------------------------------------------------------
-- ATLETAS
-- ------------------------------------------------------------
INSERT INTO atletas (nome, nome_guerra, data_nascimento, nacionalidade, posicao, pe_dominante, altura_cm, peso_kg, status, clube_formacao, agente) VALUES
-- Goleiros
('Ricardo Souza Mendes',     'Ricardo',    '1995-03-12', 'Brasileira', 'goleiro',           'direito',  188, 85.0, 'ativo',    'Flamengo',      'Diego Agente'),
('Paulo Henrique Tavares',   'Paulão',     '2000-07-25', 'Brasileira', 'goleiro',           'direito',  186, 82.5, 'ativo',    'Grêmio',        NULL),
-- Laterais
('Marcus Vinícius Costa',    'Markinho',   '1998-11-08', 'Brasileira', 'lateral_direito',   'direito',  175, 72.0, 'ativo',    'Santos',        'Agência Élite'),
('Gabriel Fernandes Lima',   'Biel',       '2001-02-14', 'Brasileira', 'lateral_esquerdo',  'esquerdo', 172, 68.0, 'ativo',    'Atlético-MG',   NULL),
-- Zagueiros
('Carlos Alberto Nunes',     'Carlão',     '1993-06-30', 'Brasileira', 'zagueiro',          'direito',  190, 90.0, 'ativo',    'Corinthians',   'Diego Agente'),
('Emerson Rodrigues Silva',  'Emerson',    '1997-09-18', 'Brasileira', 'zagueiro',          'direito',  185, 84.0, 'lesionado','Vasco',         NULL),
('Jorge Luis Pereira',       'Jorge',      '2002-04-05', 'Brasileira', 'zagueiro',          'esquerdo', 183, 80.0, 'ativo',    'Formação própria', NULL),
-- Volantes
('Anderson Silva Gomes',     'Anderson',   '1996-12-21', 'Brasileira', 'volante',           'direito',  180, 78.0, 'ativo',    'Internacional', 'Carlos Reps'),
('Thiago Barbosa Alves',     'Thiagão',    '1999-08-17', 'Brasileira', 'volante',           'direito',  177, 75.5, 'suspenso', 'Bahia',         NULL),
-- Meias
('Felipe Augusto Ramos',     'Felipão',    '1994-01-29', 'Brasileira', 'meia_central',      'direito',  176, 74.0, 'ativo',    'Fluminense',    'Agência Élite'),
('Diego Henrique Carvalho',  'Diegão',     '1997-05-03', 'Brasileira', 'meia_atacante',     'esquerdo', 174, 71.0, 'ativo',    'Cruzeiro',      'Diego Agente'),
('Lucas Martins Ribeiro',    'Lukinha',    '2003-10-12', 'Brasileira', 'meia_atacante',     'direito',  170, 66.0, 'ativo',    'Formação própria','Carlos Reps'),
-- Pontas e Atacantes
('Rodrigo Alves Pinto',      'Rodrigo',    '1995-07-19', 'Brasileira', 'ponta_direita',     'direito',  173, 70.0, 'ativo',    'Botafogo',      'Diego Agente'),
('Hélio Santos Vieira',      'Helinho',    '2000-03-28', 'Brasileira', 'ponta_esquerda',    'esquerdo', 171, 68.5, 'ativo',    'Coritiba',      NULL),
('Alexandre Costa Prado',    'Alemão',     '1992-11-14', 'Brasileira', 'centroavante',      'direito',  181, 82.0, 'ativo',    'Athletico-PR',  'Carlos Reps'),
('William Nascimento Faria', 'Will',       '1998-04-22', 'Brasileira', 'centroavante',      'direito',  179, 79.0, 'emprestado','Fortaleza',    'Agência Élite'),
('Mateus Oliveira Torres',   'Mateuzinho', '2001-09-06', 'Brasileira', 'ponta_direita',     'ambidestro',168,65.0, 'ativo',    'Formação própria', NULL);

-- ------------------------------------------------------------
-- CONTRATOS ATIVOS
-- ------------------------------------------------------------
INSERT INTO contratos_atleta
    (atleta_id, numero_contrato, tipo, data_inicio, data_fim,
     salario_bruto, salario_carteira, direitos_imagem, luvas, clausula_rescisoria, status, observacoes)
VALUES
-- 1. Ricardo (Goleiro titular)
(1,  'CT-2026-001', 'profissional', '2024-01-01', '2026-12-31', 35000.00, 5000.00, 30000.00, 0,       5000000.00, 'ativo', 'Goleiro titular. Renovação pendente para 2027.'),
-- 2. Paulão (Goleiro reserva)
(2,  'CT-2026-002', 'profissional', '2025-02-01', '2027-01-31', 8000.00,  4000.00, 4000.00,  0,       200000.00,  'ativo', NULL),
-- 3. Markinho (Lateral D)
(3,  'CT-2026-003', 'profissional', '2023-07-01', '2026-06-30', 18000.00, 4500.00, 13500.00, 0,       1500000.00, 'ativo', 'Contrato vencendo em junho. Negociação em andamento.'),
-- 4. Biel (Lateral E)
(4,  'CT-2026-004', 'profissional', '2025-01-15', '2027-12-31', 12000.00, 4000.00, 8000.00,  0,       500000.00,  'ativo', NULL),
-- 5. Carlão (Zagueiro)
(5,  'CT-2026-005', 'profissional', '2022-03-01', '2026-02-28', 22000.00, 5500.00, 16500.00, 10000.00,2000000.00, 'ativo', 'Contrato VENCIDO — renovação em análise.'),
-- 6. Emerson (Zagueiro — lesionado)
(6,  'CT-2026-006', 'profissional', '2024-08-01', '2027-07-31', 14000.00, 4000.00, 10000.00, 0,       800000.00,  'ativo', 'Lesão no joelho esquerdo. Previsão de retorno: maio/2026.'),
-- 7. Jorge (Zagueiro jovem)
(7,  'CT-2026-007', 'formacao',     '2025-01-01', '2026-12-31', 5000.00,  5000.00, 0,         0,       50000.00,   'ativo', 'Contrato de formação. Promissor.'),
-- 8. Anderson (Volante)
(8,  'CT-2026-008', 'profissional', '2024-06-01', '2027-05-31', 20000.00, 5000.00, 15000.00, 5000.00, 2500000.00, 'ativo', 'Capitão do time.'),
-- 9. Thiagão (Volante — suspenso)
(9,  'CT-2026-009', 'profissional', '2025-03-01', '2027-02-28', 11000.00, 4000.00, 7000.00,  0,       400000.00,  'ativo', 'Suspenso por 3 jogos. Dois cartões vermelhos na temporada.'),
-- 10. Felipão (Meia)
(10, 'CT-2026-010', 'profissional', '2023-01-01', '2026-12-31', 28000.00, 6000.00, 22000.00, 8000.00, 4000000.00, 'ativo', 'Destaque do time. Interesse de clubes da Série A.'),
-- 11. Diegão (Meia-atacante)
(11, 'CT-2026-011', 'profissional', '2024-07-01', '2027-06-30', 16000.00, 4500.00, 11500.00, 0,       1000000.00, 'ativo', NULL),
-- 12. Lukinha (Meia jovem)
(12, 'CT-2026-012', 'formacao',     '2025-01-01', '2027-12-31', 4500.00,  4500.00, 0,         0,       80000.00,   'ativo', 'Revelação das categorias de base.'),
-- 13. Rodrigo (Ponta D)
(13, 'CT-2026-013', 'profissional', '2024-01-15', '2026-12-31', 19000.00, 5000.00, 14000.00, 0,       1800000.00, 'ativo', NULL),
-- 14. Helinho (Ponta E)
(14, 'CT-2026-014', 'profissional', '2025-04-01', '2027-03-31', 13500.00, 4000.00, 9500.00,  0,       600000.00,  'ativo', NULL),
-- 15. Alemão (Centroavante — artilheiro)
(15, 'CT-2026-015', 'profissional', '2023-06-01', '2026-05-31', 32000.00, 7000.00, 25000.00, 15000.00,3500000.00, 'ativo', 'Artilheiro da equipe. Renovação prioritária.'),
-- 16. Will (Emprestado)
(16, 'CT-2026-016', 'emprestimo',   '2026-01-01', '2026-06-30', 18000.00, 5000.00, 13000.00, 0,       NULL,       'ativo', 'Cedido pelo Fortaleza. Opção de compra por R$ 3,5M.', ),
-- 17. Mateuzinho (Jovem)
(17, 'CT-2026-017', 'formacao',     '2025-06-01', '2027-05-31', 3500.00,  3500.00, 0,         0,       30000.00,   'ativo', NULL);

-- ------------------------------------------------------------
-- METAS / BONIFICAÇÕES (por contrato)
-- ------------------------------------------------------------
INSERT INTO metas_contrato (contrato_id, tipo, descricao, meta_quantidade, valor_bonus, tipo_calculo, competicao, observacoes) VALUES

-- GOLEIRO RICARDO (ct 1)
(1, 'jogo_sem_sofrer_gol', 'Bônus por jogo sem sofrer gol (clean sheet)', 1, 1500.00, 'por_unidade', NULL, 'Pago mensalmente com base nos jogos do mês'),
(1, 'jogo_disputado',      'Bônus por jogo disputado (titular)',           1,  500.00, 'por_unidade', NULL, NULL),
(1, 'cartao_amarelo',      'Desconto por cartão amarelo',                  1, -300.00, 'por_unidade', NULL, 'Aplicado por advertência desnecessária'),

-- CARLÃO — zagueiro (ct 5)
(5, 'jogo_disputado',      'Bônus por jogo disputado como titular',        1,  800.00, 'por_unidade', NULL, NULL),
(5, 'jogo_sem_sofrer_gol', 'Bônus por jogo sem sofrer gol',                1,  600.00, 'por_unidade', NULL, NULL),
(5, 'gol',                 'Bônus por gol marcado (bola parada)',          1, 2000.00, 'por_unidade', NULL, 'Válido para gols em escanteio e falta'),
(5, 'cartao_amarelo',      'Desconto por cartão amarelo',                  1, -500.00, 'por_unidade', NULL, NULL),
(5, 'cartao_vermelho',     'Desconto por cartão vermelho',                 1,-1500.00, 'por_unidade', NULL, NULL),

-- ANDERSON — capitão/volante (ct 8)
(8, 'jogo_disputado',      'Bônus por partida como titular',               1,  700.00, 'por_unidade', NULL, NULL),
(8, 'assistencia',         'Bônus por assistência para gol',               1, 1500.00, 'por_unidade', NULL, NULL),
(8, 'gol',                 'Bônus por gol marcado',                        1, 2500.00, 'por_unidade', NULL, NULL),
(8, 'cartao_vermelho',     'Desconto por cartão vermelho',                 1,-2000.00, 'por_unidade', NULL, NULL),

-- FELIPÃO — meia destaque (ct 10)
(10,'gol',                 'Bônus por gol marcado',                        1, 3000.00, 'por_unidade', NULL, NULL),
(10,'assistencia',         'Bônus por assistência',                        1, 2000.00, 'por_unidade', NULL, NULL),
(10,'jogo_disputado',      'Bônus por jogo disputado',                     1,  600.00, 'por_unidade', NULL, NULL),
(10,'artilharia',          'Bônus por ser artilheiro da competição',       1,15000.00, 'total_periodo','Série B','Pago ao fim da competição'),
(10,'classificacao',       'Bônus por acesso à Série A',                   1,50000.00, 'total_periodo', NULL, 'Pago em caso de acesso ao final do campeonato'),

-- ALEMÃO — artilheiro (ct 15)
(15,'gol',                 'Bônus por gol marcado',                        1, 3500.00, 'por_unidade', NULL, 'Principal cláusula de desempenho'),
(15,'assistencia',         'Bônus por assistência para gol',               1, 1800.00, 'por_unidade', NULL, NULL),
(15,'jogo_disputado',      'Bônus por jogo como titular',                  1,  900.00, 'por_unidade', NULL, NULL),
(15,'artilharia',          'Bônus por artilharia da Série B',              1,25000.00, 'total_periodo','Série B', NULL),
(15,'classificacao',       'Bônus por acesso à Série A',                   1,80000.00, 'total_periodo', NULL, 'Cláusula de acesso'),

-- WILL — emprestado (ct 16)
(16,'gol',                 'Bônus por gol (repassado ao Fortaleza)',        1, 1000.00, 'por_unidade', NULL, '50% vai ao clube cedente'),
(16,'jogo_disputado',      'Bônus por jogo como titular',                  1,  500.00, 'por_unidade', NULL, NULL);

-- ------------------------------------------------------------
-- ESTATÍSTICAS 2026 — Série B e Copa do Brasil
-- ------------------------------------------------------------
INSERT INTO estatisticas_atleta
    (atleta_id, temporada, competicao, jogos_disputados, jogos_titular,
     minutos_jogados, gols, assistencias, jogos_sem_sofrer_gol,
     cartoes_amarelos, cartoes_vermelhos, defesas_dificeis)
VALUES
-- SÉRIE B 2026
(1,  '2026', 'Série B',       10, 10,  900,  0, 0, 6, 0, 0, 28),  -- Ricardo: 6 clean sheets
(2,  '2026', 'Série B',        2,  2,  180,  0, 0, 0, 1, 0,  4),  -- Paulão: reserva
(3,  '2026', 'Série B',        9,  9,  810,  1, 2, 0, 2, 0,  0),  -- Markinho: lateral ofensivo
(4,  '2026', 'Série B',        8,  8,  720,  0, 3, 0, 1, 0,  0),  -- Biel: lateral ofensivo
(5,  '2026', 'Série B',       10, 10,  900,  2, 1, 0, 3, 0,  0),  -- Carlão: 2 gols de bola parada
(6,  '2026', 'Série B',        3,  3,  270,  0, 0, 0, 0, 0,  0),  -- Emerson: lesionou
(7,  '2026', 'Série B',        5,  4,  380,  0, 0, 0, 1, 0,  0),  -- Jorge: jovem
(8,  '2026', 'Série B',       10, 10,  900,  3, 4, 0, 1, 0,  0),  -- Anderson: capitão
(9,  '2026', 'Série B',        7,  6,  570,  1, 1, 0, 3, 2,  0),  -- Thiagão: suspenso (2 vermelhos)
(10, '2026', 'Série B',       10, 10,  900,  5, 4, 0, 1, 0,  0),  -- Felipão: destaque
(11, '2026', 'Série B',        9,  8,  768,  3, 5, 0, 2, 0,  0),  -- Diegão: criativo
(12, '2026', 'Série B',        6,  3,  324,  1, 2, 0, 0, 0,  0),  -- Lukinha: jovem
(13, '2026', 'Série B',       10,  9,  840,  4, 3, 0, 1, 0,  0),  -- Rodrigo: ponta
(14, '2026', 'Série B',        8,  7,  630,  2, 4, 0, 1, 0,  0),  -- Helinho: ponta
(15, '2026', 'Série B',       10, 10,  900,  8, 2, 0, 0, 0,  0),  -- Alemão: artilheiro!
(16, '2026', 'Série B',        7,  6,  540,  3, 1, 0, 1, 0,  0),  -- Will: emprestado
(17, '2026', 'Série B',        4,  1,  180,  0, 1, 0, 0, 0,  0),  -- Mateuzinho: promessa

-- COPA DO BRASIL 2026
(1,  '2026', 'Copa do Brasil',  3,  3,  270,  0, 0, 2, 0, 0,  7),
(3,  '2026', 'Copa do Brasil',  3,  3,  270,  0, 1, 0, 0, 0,  0),
(5,  '2026', 'Copa do Brasil',  3,  3,  270,  1, 0, 0, 0, 0,  0),
(8,  '2026', 'Copa do Brasil',  3,  3,  270,  1, 1, 0, 0, 0,  0),
(10, '2026', 'Copa do Brasil',  3,  3,  270,  2, 1, 0, 0, 0,  0),
(15, '2026', 'Copa do Brasil',  3,  3,  270,  4, 0, 0, 0, 0,  0),  -- Alemão: 4 gols também na Copa!
(13, '2026', 'Copa do Brasil',  3,  2,  210,  1, 1, 0, 0, 0,  0);

-- ------------------------------------------------------------
-- BONIFICAÇÕES PAGAS/PENDENTES — Fevereiro e Março 2026
-- ------------------------------------------------------------
INSERT INTO bonificacoes_atleta (atleta_id, contrato_id, meta_id, competencia, descricao, valor, tipo, status) VALUES
-- Ricardo — Fevereiro (3 clean sheets, 4 jogos)
(1, 1, 1, '2026-02-01', 'Clean sheets — Fevereiro (3 jogos)', 4500.00, 'bonus', 'pago'),
(1, 1, 2, '2026-02-01', 'Jogos disputados — Fevereiro (4 jogos)', 2000.00, 'bonus', 'pago'),
-- Carlão — Fevereiro (1 gol, 2 cartões)
(5, 5, 4, '2026-02-01', 'Jogos disputados — Fevereiro (4 jogos)', 3200.00, 'bonus', 'pago'),
(5, 5, 6, '2026-02-01', 'Gol de escanteio — Fevereiro', 2000.00, 'bonus', 'pago'),
(5, 5, 7, '2026-02-01', 'Cartão amarelo — Fevereiro (1)', -500.00, 'desconto', 'pago'),
-- Alemão — Fevereiro (4 gols, 4 jogos)
(15,15,18,'2026-02-01', 'Gols marcados — Fevereiro (4 gols)', 14000.00, 'bonus', 'pago'),
(15,15,20,'2026-02-01', 'Jogos disputados — Fevereiro (4 jogos)', 3600.00, 'bonus', 'pago'),
-- Felipão — Fevereiro (2 gols, 2 assistências)
(10,10,13,'2026-02-01', 'Gols marcados — Fevereiro (2 gols)', 6000.00, 'bonus', 'pago'),
(10,10,14,'2026-02-01', 'Assistências — Fevereiro (2)', 4000.00, 'bonus', 'pago'),
-- Thiagão — Desconto por vermelho — Março
(9, 9, NULL,'2026-03-01', 'Desconto cartão vermelho — Rodada 8', -2000.00, 'desconto', 'pendente'),
-- Anderson — Março (1 gol, 2 assistências)
(8, 8, 11, '2026-03-01', 'Gol marcado — Março', 2500.00, 'bonus', 'pendente'),
(8, 8, 10, '2026-03-01', 'Assistências — Março (2)', 3000.00, 'bonus', 'pendente'),
-- Ricardo — Março (3 clean sheets, 4 jogos)
(1, 1, 1, '2026-03-01', 'Clean sheets — Março (3 jogos)', 4500.00, 'bonus', 'pendente'),
(1, 1, 2, '2026-03-01', 'Jogos disputados — Março (4 jogos)', 2000.00, 'bonus', 'pendente');

-- ------------------------------------------------------------
-- HISTÓRICO DE SALÁRIO — Alterações por desempenho
-- ------------------------------------------------------------
INSERT INTO historico_salario_atleta (atleta_id, contrato_id, data_alteracao, salario_anterior, salario_novo, motivo) VALUES
(15, 15, '2026-01-01', 28000.00, 32000.00, 'Ajuste por artilharia da Série C — 18 gols na temporada 2025'),
(1,  1,  '2024-01-01', 28000.00, 35000.00, 'Renovação contratual com reajuste por desempenho'),
(10, 10, '2023-01-01', 22000.00, 28000.00, 'Renovação — melhor jogador da Série C 2022'),
(8,  8,  '2024-06-01', 16000.00, 20000.00, 'Reajuste — capitão e referência técnica'),
(3,  3,  '2023-07-01', 12000.00, 18000.00, 'Renovação após 14 jogos como titular consecutivos');
