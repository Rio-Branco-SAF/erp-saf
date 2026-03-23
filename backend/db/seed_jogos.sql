-- ============================================================
-- SEED — MÓDULO 8: AGENDA DE JOGOS
-- ============================================================

-- ─── Templates de orçamento ──────────────────────────────────

-- Template: Jogo em casa (mandante)
INSERT INTO templates_orcamento_jogo (nome, tipo_jogo, competicao) VALUES
('Padrão Mandante - Série B',   'mandante',  'Série B'),
('Padrão Visitante - Série B',  'visitante', 'Série B'),
('Padrão Mandante - Copa',      'mandante',  'Copa do Brasil'),
('Padrão Visitante - Copa',     'visitante', 'Copa do Brasil')
ON CONFLICT DO NOTHING;

-- Itens do template mandante Série B (id=1)
INSERT INTO itens_template_orcamento (template_id, categoria, descricao, valor_padrao, obrigatorio, ordem) VALUES
(1, 'Arbitragem',    'Taxa de arbitragem CBF',                  3500.00,  TRUE,  1),
(1, 'Segurança',     'Segurança privada (30 agentes)',           4800.00,  TRUE,  2),
(1, 'Segurança',     'Policiamento militar (taxa)',              1200.00,  TRUE,  3),
(1, 'Operacional',   'Bilheteiros e porteiros',                 2400.00,  TRUE,  4),
(1, 'Operacional',   'Equipe de campo (gramado, redes)',         800.00,  TRUE,  5),
(1, 'Operacional',   'Limpeza e higienização',                  1200.00,  TRUE,  6),
(1, 'Operacional',   'Médico e fisioterapeuta de plantão',       600.00,  TRUE,  7),
(1, 'Comunicação',   'Assessoria de imprensa',                   900.00, FALSE,  8),
(1, 'Comunicação',   'Transmissão ao vivo (produção)',          2500.00, FALSE,  9),
(1, 'Hospedagem',    'Hotel adversário (delegação)',            3200.00,  TRUE, 10),
(1, 'Alimentação',   'Refeição elenco e comissão',               960.00,  TRUE, 11),
(1, 'Outros',        'Premiação de campo (bola, material)',       350.00, FALSE, 12)
ON CONFLICT DO NOTHING;

-- Itens do template visitante Série B (id=2)
INSERT INTO itens_template_orcamento (template_id, categoria, descricao, valor_padrao, obrigatorio, ordem) VALUES
(2, 'Transporte',    'Ônibus fretado (ida e volta)',            3800.00,  TRUE,  1),
(2, 'Hospedagem',    'Hotel delegação (15 apartamentos)',       6500.00,  TRUE,  2),
(2, 'Alimentação',   'Diárias de alimentação (2 dias)',         2400.00,  TRUE,  3),
(2, 'Arbitragem',    'Taxa visitante CBF',                       800.00,  TRUE,  4),
(2, 'Operacional',   'Médico e fisio em deslocamento',           600.00,  TRUE,  5),
(2, 'Outros',        'Seguros e taxas diversas',                 500.00, FALSE,  6)
ON CONFLICT DO NOTHING;

-- Itens do template mandante Copa (id=3)
INSERT INTO itens_template_orcamento (template_id, categoria, descricao, valor_padrao, obrigatorio, ordem) VALUES
(3, 'Arbitragem',    'Taxa de arbitragem CBF - Copa',           4200.00,  TRUE,  1),
(3, 'Segurança',     'Segurança reforçada Copa',                6500.00,  TRUE,  2),
(3, 'Segurança',     'Policiamento militar',                    1800.00,  TRUE,  3),
(3, 'Operacional',   'Bilheteiros e porteiros',                 2800.00,  TRUE,  4),
(3, 'Operacional',   'Limpeza e higienização',                  1500.00,  TRUE,  5),
(3, 'Comunicação',   'Transmissão CBF TV',                      3500.00,  TRUE,  6),
(3, 'Hospedagem',    'Hotel adversário delegação',              4200.00,  TRUE,  7),
(3, 'Alimentação',   'Refeição elenco',                         1200.00,  TRUE,  8),
(3, 'Outros',        'Premiação e material CBF',                 600.00, FALSE,  9)
ON CONFLICT DO NOTHING;

-- Itens do template visitante Copa (id=4)
INSERT INTO itens_template_orcamento (template_id, categoria, descricao, valor_padrao, obrigatorio, ordem) VALUES
(4, 'Transporte',    'Passagens aéreas delegação',              18000.00, TRUE,  1),
(4, 'Hospedagem',    'Hotel delegação (2 noites)',               9800.00, TRUE,  2),
(4, 'Alimentação',   'Diárias e refeições viagem',               3200.00, TRUE,  3),
(4, 'Arbitragem',    'Taxa visitante CBF - Copa',                1200.00, TRUE,  4),
(4, 'Operacional',   'Equipe médica deslocamento',                900.00, TRUE,  5),
(4, 'Outros',        'Seguros, taxas e imprevistos',             1000.00, TRUE,  6)
ON CONFLICT DO NOTHING;

-- ─── Jogos ───────────────────────────────────────────────────
-- Jogos já realizados (passado)
INSERT INTO jogos (competicao, rodada, adversario, data_jogo, local_jogo, tipo_jogo, status,
                   gols_nos, gols_adversario, capacidade_estadio, publico_pagante, publico_cortesias,
                   transmissao_tv, transmissao_streaming)
VALUES
('Série B', 'Rodada 1',  'Atlético Goianiense',  '2026-01-18 16:00', 'Estádio Municipal', 'mandante', 'realizado', 2, 1, 18000, 6800,  420, TRUE,  TRUE),
('Série B', 'Rodada 2',  'CRB',                   '2026-01-25 11:00', 'Estádio Rei Pelé',  'visitante','realizado', 1, 1, 30000,  0,      0,  TRUE,  FALSE),
('Série B', 'Rodada 3',  'Guarani',               '2026-02-01 18:30', 'Estádio Municipal', 'mandante', 'realizado', 3, 0, 18000, 7200,  380, FALSE, TRUE),
('Série B', 'Rodada 4',  'Ponte Preta',           '2026-02-08 16:00', 'Moisés Lucarelli',  'visitante','realizado', 0, 2, 20000,  0,      0,  FALSE, FALSE),
('Série B', 'Rodada 5',  'Vila Nova',             '2026-02-15 11:00', 'Estádio Municipal', 'mandante', 'realizado', 1, 0, 18000, 5900,  310, TRUE,  TRUE),
('Copa do Brasil', 'Primeira Fase', 'Madureira EC','2026-01-28 19:00', 'Estádio Municipal', 'mandante', 'realizado', 4, 1, 18000, 4200,  600, FALSE, TRUE),
('Copa do Brasil', 'Segunda Fase', 'Fluminense',  '2026-02-19 21:30', 'Maracanã',          'visitante','realizado', 1, 2, 78000,  0,      0,  TRUE,  TRUE),
('Série B', 'Rodada 6',  'Ituano',                '2026-02-22 16:00', 'Estádio Municipal', 'mandante', 'realizado', 2, 2, 18000, 6100,  290, FALSE, TRUE)
ON CONFLICT DO NOTHING;

-- Jogos futuros confirmados / agendados
INSERT INTO jogos (competicao, rodada, adversario, data_jogo, local_jogo, tipo_jogo, status,
                   capacidade_estadio, transmissao_tv, transmissao_streaming)
VALUES
('Série B', 'Rodada 9',  'Operário PR',  '2026-03-22 16:00', 'Estádio Municipal',     'mandante',  'confirmado', 18000, TRUE,  TRUE),
('Série B', 'Rodada 10', 'Mirassol',     '2026-03-29 11:00', 'Estádio Municipal Lins', 'visitante', 'agendado',   12000, FALSE, FALSE),
('Série B', 'Rodada 11', 'Amazonas FC',  '2026-04-05 18:30', 'Estádio Municipal',      'mandante',  'agendado',   18000, FALSE, TRUE),
('Série B', 'Rodada 12', 'Novorizontino','2026-04-12 16:00', 'Jorge Ismael de Biasi',  'visitante', 'agendado',   17000, FALSE, FALSE),
('Série B', 'Rodada 13', 'Chapecoense',  '2026-04-19 11:00', 'Estádio Municipal',      'mandante',  'agendado',   18000, TRUE,  TRUE),
('Série B', 'Rodada 14', 'Avaí',         '2026-04-26 18:30', 'Avaí',                   'visitante', 'agendado',   22000, FALSE, FALSE),
('Série B', 'Rodada 15', 'Sport',        '2026-05-03 16:00', 'Estádio Municipal',       'mandante',  'agendado',  18000, TRUE,  TRUE)
ON CONFLICT DO NOTHING;

-- ─── Orçamentos dos jogos realizados ─────────────────────────
-- Jogo 1: Mandante Série B (rodada 1)
INSERT INTO orcamentos_jogo (jogo_id, status) VALUES (1, 'realizado') ON CONFLICT DO NOTHING;
INSERT INTO itens_orcamento_jogo (orcamento_id, categoria, descricao, valor_estimado, valor_realizado, pago, ordem) VALUES
(1, 'Arbitragem',  'Taxa CBF arbitragem',           3500, 3500,  TRUE, 1),
(1, 'Segurança',   'Segurança privada',              4800, 5100,  TRUE, 2),
(1, 'Segurança',   'Policiamento militar',           1200, 1200,  TRUE, 3),
(1, 'Operacional', 'Bilheteiros e porteiros',        2400, 2400,  TRUE, 4),
(1, 'Operacional', 'Equipe de campo',                 800,  800,  TRUE, 5),
(1, 'Operacional', 'Limpeza',                        1200, 1100,  TRUE, 6),
(1, 'Operacional', 'Médico de plantão',               600,  600,  TRUE, 7),
(1, 'Comunicação', 'Produção transmissão',           2500, 2800,  TRUE, 8),
(1, 'Hospedagem',  'Hotel adversário',               3200, 3200,  TRUE, 9),
(1, 'Alimentação', 'Refeição elenco',                 960, 1040,  TRUE,10)
ON CONFLICT DO NOTHING;

-- Jogo 2: Visitante Série B (rodada 2)
INSERT INTO orcamentos_jogo (jogo_id, status) VALUES (2, 'realizado') ON CONFLICT DO NOTHING;
INSERT INTO itens_orcamento_jogo (orcamento_id, categoria, descricao, valor_estimado, valor_realizado, pago, ordem) VALUES
(2, 'Transporte',  'Ônibus fretado',   3800, 3800, TRUE, 1),
(2, 'Hospedagem',  'Hotel delegação',  6500, 6200, TRUE, 2),
(2, 'Alimentação', 'Diárias',          2400, 2550, TRUE, 3),
(2, 'Arbitragem',  'Taxa visitante',    800,  800, TRUE, 4),
(2, 'Operacional', 'Médico/fisio',      600,  600, TRUE, 5)
ON CONFLICT DO NOTHING;

-- Jogo 3: Mandante (rodada 3)
INSERT INTO orcamentos_jogo (jogo_id, status) VALUES (3, 'realizado') ON CONFLICT DO NOTHING;
INSERT INTO itens_orcamento_jogo (orcamento_id, categoria, descricao, valor_estimado, valor_realizado, pago, ordem) VALUES
(3, 'Arbitragem',  'Taxa CBF',          3500, 3500, TRUE, 1),
(3, 'Segurança',   'Segurança privada', 4800, 4800, TRUE, 2),
(3, 'Segurança',   'Policiamento',      1200, 1200, TRUE, 3),
(3, 'Operacional', 'Bilheteiros',       2400, 2400, TRUE, 4),
(3, 'Operacional', 'Equipe campo',       800,  800, TRUE, 5),
(3, 'Hospedagem',  'Hotel adversário',  3200, 3200, TRUE, 6),
(3, 'Alimentação', 'Refeição',           960,  960, TRUE, 7)
ON CONFLICT DO NOTHING;

-- Jogo 9 (próximo): Orçamento aprovado
INSERT INTO orcamentos_jogo (jogo_id, status) VALUES (9, 'aprovado') ON CONFLICT DO NOTHING;
INSERT INTO itens_orcamento_jogo (orcamento_id, categoria, descricao, valor_estimado, pago, ordem) VALUES
(4, 'Arbitragem',  'Taxa CBF arbitragem',    3500, FALSE, 1),
(4, 'Segurança',   'Segurança privada',       4800, FALSE, 2),
(4, 'Segurança',   'Policiamento militar',    1200, FALSE, 3),
(4, 'Operacional', 'Bilheteiros e porteiros', 2400, FALSE, 4),
(4, 'Operacional', 'Equipe de campo',          800, FALSE, 5),
(4, 'Operacional', 'Limpeza',                 1200, FALSE, 6),
(4, 'Comunicação', 'Produção transmissão',    2500, FALSE, 7),
(4, 'Hospedagem',  'Hotel adversário',        3200, FALSE, 8),
(4, 'Alimentação', 'Refeição elenco',          960, FALSE, 9)
ON CONFLICT DO NOTHING;

-- ─── Receitas dos jogos realizados ───────────────────────────
-- Jogo 1
INSERT INTO receitas_jogo (jogo_id, tipo, descricao, quantidade, valor_unitario, valor_total, realizado) VALUES
(1, 'bilheteria_inteira', 'Ingresso inteira',    3200, 40.00, 128000, TRUE),
(1, 'bilheteria_meia',    'Ingresso meia-entrada',2400, 20.00,  48000, TRUE),
(1, 'bilheteria_socio',   'Sócio-torcedor',      1200,  0.00,       0, TRUE),
(1, 'patrocinio_jogo',    'Patrocínio Apex jogo',   1,     0, 25000,  TRUE),
(1, 'cota_tv',            'Cota transmissão',       1,     0, 18000,  TRUE),
(1, 'alimentacao',        'Alimentação/bebidas',    1,     0,  4200,  TRUE),
(1, 'estacionamento',     'Estacionamento',         1,     0,  3100,  TRUE)
ON CONFLICT DO NOTHING;

-- Jogo 3 (goleada em casa)
INSERT INTO receitas_jogo (jogo_id, tipo, descricao, quantidade, valor_unitario, valor_total, realizado) VALUES
(3, 'bilheteria_inteira', 'Ingresso inteira',    3600, 40.00, 144000, TRUE),
(3, 'bilheteria_meia',    'Ingresso meia-entrada',2600, 20.00,  52000, TRUE),
(3, 'bilheteria_socio',   'Sócio-torcedor',      1000,  0.00,       0, TRUE),
(3, 'patrocinio_jogo',    'Patrocínio Apex jogo',   1,     0, 25000,  TRUE),
(3, 'alimentacao',        'Alimentação/bebidas',    1,     0,  5100,  TRUE),
(3, 'estacionamento',     'Estacionamento',         1,     0,  3600,  TRUE)
ON CONFLICT DO NOTHING;

-- Jogo 5 (mandante)
INSERT INTO receitas_jogo (jogo_id, tipo, descricao, quantidade, valor_unitario, valor_total, realizado) VALUES
(5, 'bilheteria_inteira', 'Ingresso inteira',    2800, 40.00, 112000, TRUE),
(5, 'bilheteria_meia',    'Ingresso meia-entrada',2100, 20.00,  42000, TRUE),
(5, 'bilheteria_socio',   'Sócio-torcedor',      1000,  0.00,       0, TRUE),
(5, 'patrocinio_jogo',    'Patrocínio jogo',        1,     0, 22000,  TRUE),
(5, 'cota_tv',            'Cota transmissão',       1,     0, 18000,  TRUE),
(5, 'alimentacao',        'Alimentação',            1,     0,  3800,  TRUE)
ON CONFLICT DO NOTHING;

-- Jogo 6 (Copa do Brasil - mandante)
INSERT INTO receitas_jogo (jogo_id, tipo, descricao, quantidade, valor_unitario, valor_total, realizado) VALUES
(6, 'bilheteria_inteira', 'Ingresso inteira',   2000, 50.00, 100000, TRUE),
(6, 'bilheteria_meia',    'Ingresso meia',       1400, 25.00,  35000, TRUE),
(6, 'bilheteria_socio',   'Sócio-torcedor',       800,  0.00,      0, TRUE),
(6, 'cota_tv',            'Cota CBF - Copa',        1,     0, 32000,  TRUE),
(6, 'alimentacao',        'Alimentação',            1,     0,  2900,  TRUE)
ON CONFLICT DO NOTHING;

-- Jogo 8 (mandante rodada 6)
INSERT INTO receitas_jogo (jogo_id, tipo, descricao, quantidade, valor_unitario, valor_total, realizado) VALUES
(8, 'bilheteria_inteira', 'Ingresso inteira',    2900, 40.00, 116000, TRUE),
(8, 'bilheteria_meia',    'Ingresso meia',        2200, 20.00,  44000, TRUE),
(8, 'bilheteria_socio',   'Sócio-torcedor',       1000,  0.00,      0, TRUE),
(8, 'patrocinio_jogo',    'Patrocínio jogo',         1,     0, 25000, TRUE),
(8, 'alimentacao',        'Alimentação',             1,     0,  4100, TRUE)
ON CONFLICT DO NOTHING;

-- Receitas estimadas para jogo 9 (próximo)
INSERT INTO receitas_jogo (jogo_id, tipo, descricao, quantidade, valor_unitario, valor_total, realizado) VALUES
(9, 'bilheteria_inteira', 'Ingresso inteira (estimado)',    3000, 40.00, 120000, FALSE),
(9, 'bilheteria_meia',    'Ingresso meia (estimado)',        2200, 20.00,  44000, FALSE),
(9, 'bilheteria_socio',   'Sócio-torcedor (estimado)',       1100,  0.00,      0, FALSE),
(9, 'patrocinio_jogo',    'Patrocínio Apex',                    1,     0, 25000, FALSE),
(9, 'cota_tv',            'Cota transmissão',                   1,     0, 18000, FALSE)
ON CONFLICT DO NOTHING;

-- ─── Gols dos jogos realizados ────────────────────────────────
-- Jogo 1 (2x1): gols id atleta 1=Thiago Alemão, 2=Lucas, adversário
INSERT INTO gols_jogo (jogo_id, atleta_id, minuto, tipo, time) VALUES
(1, 1, 23, 'normal',  'nos'),
(1, 2, 67, 'normal',  'nos'),
(1, NULL, 80, 'normal','adversario')
ON CONFLICT DO NOTHING;

-- Jogo 3 (3x0)
INSERT INTO gols_jogo (jogo_id, atleta_id, minuto, tipo, time) VALUES
(3, 1, 12, 'normal',  'nos'),
(3, 1, 45, 'penalti', 'nos'),
(3, 3, 78, 'normal',  'nos')
ON CONFLICT DO NOTHING;

-- Jogo 5 (1x0)
INSERT INTO gols_jogo (jogo_id, atleta_id, minuto, tipo, time) VALUES
(5, 2, 55, 'normal', 'nos')
ON CONFLICT DO NOTHING;

-- Jogo 6 Copa (4x1)
INSERT INTO gols_jogo (jogo_id, atleta_id, minuto, tipo, time) VALUES
(6, 1, 8,  'normal', 'nos'),
(6, 1, 34, 'normal', 'nos'),
(6, 4, 56, 'cabeca', 'nos'),
(6, 3, 72, 'normal', 'nos'),
(6, NULL, 88, 'normal', 'adversario')
ON CONFLICT DO NOTHING;

-- Jogo 8 (2x2)
INSERT INTO gols_jogo (jogo_id, atleta_id, minuto, tipo, time) VALUES
(8, 2, 31, 'normal',  'nos'),
(8, 1, 65, 'penalti', 'nos'),
(8, NULL, 50, 'normal','adversario'),
(8, NULL, 88, 'normal','adversario')
ON CONFLICT DO NOTHING;
