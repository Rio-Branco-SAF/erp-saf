-- ============================================================
-- SEED: INVESTIDORES — Dados de Demonstração
-- ERP SAF
-- ============================================================

-- ------------------------------------------------------------
-- INVESTIDORES
-- ------------------------------------------------------------
INSERT INTO investidores (nome, tipo, cpf_cnpj, perfil, email, telefone, percentual_participacao, nome_fantasia, responsavel, observacoes) VALUES

-- Sócios com participação acionária
('Roberto Andrade Menezes',     'pessoa_fisica',   '111.222.333-44', 'socio',        'roberto.menezes@email.com',   '(11) 99999-1111', 25.000, NULL,                  NULL,                'Sócio majoritário. Empresário do setor imobiliário.'),
('Grupo Empresarial Vitória',   'pessoa_juridica', '22.333.444/0001-55','socio',     'contato@grupovitoria.com.br', '(11) 3000-2222', 20.000, 'Grupo Vitória',       'Marcos Vitória',    'Grupo com 3 empresas do setor financeiro. Interesse em visibilidade no esporte.'),
('Patricia Lima Coutinho',      'pessoa_fisica',   '333.444.555-66', 'socio',        'patricia.coutinho@email.com', '(11) 98888-3333',  8.000, NULL,                  NULL,                'Sócia investidora. Família tradicional da cidade.'),

-- Patrocinadores
('Construtora Apex S/A',        'pessoa_juridica', '44.555.666/0001-77','patrocinador','comercial@apex.com.br',     '(11) 3500-4444',  0.000, 'Apex Construções',    'Fernando Apex',     'Patrocinador master da camisa. Contrato anual.'),
('Farmácias Saúde Total',       'pessoa_juridica', '55.666.777/0001-88','patrocinador','mkt@saudetotal.com.br',     '(11) 3200-5555',  0.000, 'Saúde Total',           'Ana Diretora',       'Patrocinador cota ouro. Faixa de publicidade no estádio.'),
('Auto Peças Rodrigues Ltda',   'pessoa_juridica', '66.777.888/0001-99','patrocinador','contato@autorodrigues.com', '(11) 9700-6666',  0.000, 'Rodrigues Peças',     'Paulo Rodrigues',   'Patrocinador local. Renovação anual.'),

-- Investidores financeiros
('Ricardo Fontes Barros',       'pessoa_fisica',   '777.888.999-00', 'investidor',   'r.fontes@email.com',          '(11) 97777-7777',  0.000, NULL,                  NULL,                'Investidor financeiro. Espera retorno em dividendos futuros.'),
('Fundo Esporte Capital FIP',   'pessoa_juridica', '88.999.000/0001-11','investidor','gestao@esportecapital.com',  '(11) 3100-8888',  0.000, 'Esporte Capital',     'Gestora Fundo',     'Fundo de investimento em clubes. Aportes via empréstimo com conversão.'),

-- Mecenas / Doadores
('Dr. Henrique Albuquerque',    'pessoa_fisica',   '999.000.111-22', 'mecenatismo',  'dr.henrique@clinica.com.br',  '(11) 96666-9999',  0.000, NULL,                  NULL,                'Médico e torcedor apaixonado. Doações regulares.');

-- ------------------------------------------------------------
-- APORTES
-- ------------------------------------------------------------
INSERT INTO aportes (investidor_id, tipo, descricao, valor, data_aporte, competencia, percentual_concedido, contrapartida, status, observacoes) VALUES

-- Roberto Andrade (sócio 25%)
(1, 'aporte_capital', 'Aporte inicial de capitalização — fundação da SAF', 2500000.00, '2023-01-15', '2023-01-01', 25.000, NULL, 'confirmado', 'Aporte que formalizou a participação acionária de 25%.'),
(1, 'aporte_capital', 'Aporte complementar — reforço de elenco 2024',       500000.00, '2024-02-10', '2024-02-01',  0.000, NULL, 'confirmado', 'Aporte adicional sem diluição de terceiros.'),
(1, 'aporte_capital', 'Aporte para infraestrutura — CT reforma',             800000.00, '2025-06-01', '2025-06-01',  0.000, NULL, 'confirmado', 'Reforma do Centro de Treinamento.'),

-- Grupo Vitória (sócio 20%)
(2, 'aporte_capital', 'Entrada do Grupo Vitória — participação societária', 2000000.00, '2023-03-01', '2023-03-01', 20.000, NULL, 'confirmado', 'Ingresso do grupo como segundo maior acionista.'),
(2, 'aporte_capital', 'Aporte temporada 2025 — folha de atletas',            600000.00, '2025-01-15', '2025-01-01',  0.000, NULL, 'confirmado', NULL),
(2, 'aporte_capital', 'Aporte 2026 — planejamento esportivo',                700000.00, '2026-01-10', '2026-01-01',  0.000, NULL, 'confirmado', NULL),

-- Patrícia Lima (sócia 8%)
(3, 'aporte_capital', 'Aporte de ingresso — participação 8%',                800000.00, '2023-07-01', '2023-07-01',  8.000, NULL, 'confirmado', NULL),
(3, 'aporte_capital', 'Aporte adicional — Copa do Brasil 2025',              200000.00, '2025-04-01', '2025-04-01',  0.000, NULL, 'confirmado', NULL),

-- Construtora Apex (patrocinador master)
(4, 'patrocinio', 'Patrocínio master camisa 2024 (Apex)',                   480000.00, '2024-01-15', '2024-01-01',  0.000, 'Logo frente camisa titular + reserva, naming rights CT, área VIP 10 pessoas', 'confirmado', 'Contrato anual. Pago em 12x.'),
(4, 'patrocinio', 'Patrocínio master camisa 2025 (Apex)',                   540000.00, '2025-01-15', '2025-01-01',  0.000, 'Logo frente camisa titular + reserva, naming rights CT, área VIP 10 pessoas', 'confirmado', 'Reajuste de 12.5%.'),
(4, 'patrocinio', 'Patrocínio master camisa 2026 (Apex)',                   600000.00, '2026-01-10', '2026-01-01',  0.000, 'Logo frente camisa + naming CT + camarote 10 lugares + redes sociais', 'confirmado', 'Reajuste de 11.1%.'),

-- Farmácias Saúde Total (patrocinador ouro)
(5, 'patrocinio', 'Patrocínio cota ouro 2025 (Saúde Total)',               180000.00, '2025-02-01', '2025-02-01',  0.000, 'Faixa de publicidade estádio + 4 ingressos por jogo + redes sociais', 'confirmado', NULL),
(5, 'patrocinio', 'Patrocínio cota ouro 2026 (Saúde Total)',                200000.00, '2026-02-01', '2026-02-01',  0.000, 'Faixa publicidade + logo no aquecimento + 6 ingressos por jogo', 'confirmado', NULL),

-- Auto Peças Rodrigues (patrocinador local)
(6, 'patrocinio', 'Patrocínio cota prata 2026 (Rodrigues Peças)',           60000.00, '2026-01-20', '2026-01-01',  0.000, 'Logo no uniforme de treino + 2 ingressos por jogo + post no Instagram mensal', 'confirmado', NULL),

-- Ricardo Fontes (investidor financeiro)
(7, 'emprestimo', 'Empréstimo para contratação de atletas (jan/2025)',      400000.00, '2025-01-20', '2025-01-01',  0.000, NULL, 'confirmado', 'Taxa: 10% a.a. Prazo: 24 meses. Vencimento jan/2027.'),
(7, 'emprestimo', 'Empréstimo complementar (reforço mid-2025)',             200000.00, '2025-07-10', '2025-07-01',  0.000, NULL, 'confirmado', 'Taxa: 10% a.a. Prazo: 18 meses. Vencimento jan/2027.'),

-- Fundo Esporte Capital (investidor — empréstimo conversível)
(8, 'emprestimo', 'Empréstimo conversível (Fundo Esporte Capital)',         1000000.00, '2024-06-01', '2024-06-01',  0.000, NULL, 'confirmado', 'Conversível em equity (até 5%) ao final. Taxa: 8% a.a. Prazo: 36 meses.'),

-- Dr. Henrique (mecenas / doador)
(9, 'doacao', 'Doação de equipamentos médicos para CT',                       45000.00, '2024-03-15', '2024-03-01',  0.000, NULL, 'confirmado', 'Doação de equipamentos fisioterapia.'),
(9, 'doacao', 'Doação patrocínio categorias de base 2025',                 30000.00, '2025-01-05', '2025-01-01',  0.000, NULL, 'confirmado', 'Custeio de alimentação e transporte das categorias de base.'),
(9, 'doacao', 'Doação fundo médico 2026',                                   20000.00, '2026-01-03', '2026-01-01',  0.000, NULL, 'confirmado', NULL);

-- Atualizar taxa de juros e vencimento dos empréstimos
UPDATE aportes SET taxa_juros_anual = 10.00, data_vencimento = '2027-01-20' WHERE id = 15;
UPDATE aportes SET taxa_juros_anual = 10.00, data_vencimento = '2027-01-10' WHERE id = 16;
UPDATE aportes SET taxa_juros_anual =  8.00, data_vencimento = '2027-06-01' WHERE id = 17;

-- Simula devolução parcial do empréstimo do Ricardo Fontes
UPDATE aportes SET valor_devolvido = 120000.00 WHERE id = 15;

-- ------------------------------------------------------------
-- RETORNOS AOS INVESTIDORES
-- ------------------------------------------------------------
INSERT INTO retornos_investidor (investidor_id, aporte_id, tipo, descricao, valor, data_pagamento, competencia, status) VALUES

-- Dividendos para sócios (fim de 2024 — resultado positivo)
(1, 1, 'dividendo', 'Distribuição de resultado 2024 (25% do lucro líquido)', 125000.00, '2025-01-31', '2024-12-01', 'pago'),
(2, 4, 'dividendo', 'Distribuição de resultado 2024 (20% do lucro líquido)', 100000.00, '2025-01-31', '2024-12-01', 'pago'),
(3, 7, 'dividendo', 'Distribuição de resultado 2024 (8% do lucro líquido)',   40000.00, '2025-01-31', '2024-12-01', 'pago'),

-- Juros empréstimos Ricardo Fontes (2025)
(7, 15, 'juros', 'Juros empréstimo jan a jun/2025 (10% a.a.)',  20000.00, '2025-07-10', '2025-06-01', 'pago'),
(7, 15, 'juros', 'Juros empréstimo jul a dez/2025 (10% a.a.)', 22000.00, '2026-01-10', '2025-12-01', 'pago'),
(7, 16, 'juros', 'Juros empréstimo complementar jul a dez/2025', 10000.00,'2026-01-10', '2025-12-01', 'pago'),

-- Juros Fundo Esporte Capital (2025)
(8, 17, 'juros', 'Juros empréstimo conversível 2025 (8% a.a.)', 80000.00, '2026-01-31', '2025-12-01', 'pago'),

-- Dividendos 2025 para sócios (PENDENTES — aguardando fechamento)
(1, 1, 'dividendo', 'Distribuição parcial resultado 1º semestre 2026', 80000.00, '2026-07-31', '2026-06-01', 'pendente'),
(2, 4, 'dividendo', 'Distribuição parcial resultado 1 semestre 2026', 64000.00, '2026-07-31', '2026-06-01', 'pendente'),
(3, 7, 'dividendo', 'Distribuição parcial resultado 1º semestre 2026', 25600.00, '2026-07-31', '2026-06-01', 'pendente'),

-- Juros Ricardo Fontes (2026 — pendentes)
(7, 15, 'juros', 'Juros empréstimo jan a jun/2026 (10% a.a.)',  22000.00, '2026-07-10', '2026-06-01', 'pendente'),
(7, 16, 'juros', 'Juros empréstimo complementar jan a jun/2026', 10000.00,'2026-07-10', '2026-06-01', 'pendente');
