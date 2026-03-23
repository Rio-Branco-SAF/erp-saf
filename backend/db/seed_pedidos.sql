-- ============================================================
-- SEED: PEDIDOS DE COMPRA — Dados de Demonstração
-- ERP SAF
-- ============================================================

-- Nota: este seed pressupõe que os schemas de funcionarios
-- e financeiro já foram executados (categorias_financeiras,
-- centros_custo, departamentos, usuarios existem).

-- ------------------------------------------------------------
-- PEDIDOS DE COMPRA
-- ------------------------------------------------------------
INSERT INTO pedidos_compra
    (numero, titulo, descricao, departamento_id, prioridade, data_necessidade,
     status, centro_custo_id, categoria_financeira_id,
     valor_estimado, valor_aprovado, valor_final, observacoes)
VALUES
-- 1. Concluído
(
    'PC-2026-001',
    'Compra de Uniformes — Temporada 2026',
    'Uniformes completos para elenco principal (22 atletas), comissão técnica e staff. Inclui camisa, calção e meias em 3 versões (jogo, treino, aquecimento).',
    3,  -- Futebol / Esporte
    'alta',
    '2026-01-15',
    'concluido',
    3,  -- Futebol Profissional
    10, -- Despesa: Material Esportivo
    45000.00, 43500.00, 42800.00,
    'Pedido concluído. Uniformes entregues em 12/01/2026.'
),
-- 2. Aprovado / Em compra
(
    'PC-2026-002',
    'Equipamentos de Academia — Renovação',
    'Substituição de 4 esteiras, 2 bicicletas ergométricas e conjunto de pesos livres. Equipamentos atuais com mais de 5 anos de uso.',
    3,
    'normal',
    '2026-02-28',
    'em_compra',
    3,
    10,
    38000.00, 36500.00, NULL,
    'Aprovado pelo diretor financeiro. Aguardando entrega do fornecedor.'
),
-- 3. Aguardando aprovação
(
    'PC-2026-003',
    'Serviço de Fisioterapia — Contrato Mensal',
    'Contratação de empresa de fisioterapia para atendimento diário ao elenco. Estimativa de 3 fisioterapeutas por período.',
    3,
    'alta',
    '2026-03-01',
    'aguardando_aprovacao',
    3,
    10,
    18000.00, NULL, NULL,
    'Urgente — início do campeonato em março. 3 cotações coletadas.'
),
-- 4. Em cotação
(
    'PC-2026-004',
    'Transporte para Jogo Fora — Abril',
    'Fretamento de ônibus executivo para 3 partidas fora de casa em abril. Inclui motorista, seguro e combustível.',
    3,
    'normal',
    '2026-03-25',
    'em_cotacao',
    3,
    10,
    12000.00, NULL, NULL,
    'Aguardando cotação de 2 transportadoras.'
),
-- 5. Aguardando cotação
(
    'PC-2026-005',
    'Material de Escritório — Trimestre Q2',
    'Resmas de papel, cartuchos de impressora, canetas, pastas e material de organização para os departamentos administrativos.',
    2,  -- Administração
    'baixa',
    '2026-04-10',
    'aguardando_cotacao',
    6,  -- Administração Geral
    10,
    3500.00, NULL, NULL,
    NULL
),
-- 6. Rascunho
(
    'PC-2026-006',
    'Software de Análise de Desempenho — Atletas',
    'Licença anual de plataforma de vídeo-análise e métricas físicas para comissão técnica. Comparação com Hudl, Wyscout e Krossover em andamento.',
    3,
    'normal',
    '2026-04-30',
    'rascunho',
    3,
    12,  -- Despesa: Tecnologia / Infraestrutura
    28000.00, NULL, NULL,
    'Em avaliação. Precisa aprovação do diretor técnico antes de enviar para cotação.'
),
-- 7. Rejeitado
(
    'PC-2026-007',
    'Cadeiras VIP — Reforma do Camarote',
    'Compra de 40 cadeiras estofadas para reforma do camarote dos investidores.',
    1,  -- Diretoria
    'baixa',
    '2026-02-15',
    'rejeitado',
    6,
    10,
    22000.00, NULL, NULL,
    NULL
),
-- 8. Cancelado
(
    'PC-2026-008',
    'Campanha de Marketing — Redes Sociais',
    'Contratação de agência para gestão das redes sociais e criação de conteúdo.',
    5,  -- Marketing
    'normal',
    '2026-02-01',
    'cancelado',
    7,  -- Marketing
    13,  -- Despesa: Marketing
    9500.00, NULL, NULL,
    'Cancelado — orçamento redirecionado para reforço no elenco.'
);

-- ------------------------------------------------------------
-- ITENS DOS PEDIDOS
-- ------------------------------------------------------------
INSERT INTO itens_pedido (pedido_id, descricao, quantidade, unidade, valor_unitario_estimado) VALUES
-- PC-2026-001 (uniformes)
(1, 'Camisa jogo titular (G/M/GG)', 22, 'un', 320.00),
(1, 'Camisa treino', 30, 'un', 180.00),
(1, 'Calção jogo', 25, 'un', 140.00),
(1, 'Meias (par)', 60, 'par', 45.00),
(1, 'Agasalho completo', 30, 'un', 280.00),
-- PC-2026-002 (academia)
(2, 'Esteira profissional', 4, 'un', 5800.00),
(2, 'Bicicleta ergométrica', 2, 'un', 3200.00),
(2, 'Conjunto de pesos livres 5-50kg', 1, 'conj', 12000.00),
(2, 'Banco supino ajustável', 3, 'un', 1800.00),
-- PC-2026-003 (fisioterapia)
(3, 'Fisioterapeuta período matutino (mensal)', 2, 'vaga', 6000.00),
(3, 'Fisioterapeuta período vespertino (mensal)', 1, 'vaga', 5500.00),
(3, 'Materiais consumíveis mensais', 1, 'kit', 800.00),
-- PC-2026-004 (transporte)
(4, 'Ônibus executivo 46 lugares — jogo 1', 1, 'diária', 3800.00),
(4, 'Ônibus executivo 46 lugares — jogo 2', 1, 'diária', 4200.00),
(4, 'Ônibus executivo 46 lugares — jogo 3', 1, 'diária', 3500.00),
-- PC-2026-005 (escritório)
(5, 'Resma de papel A4 500 folhas', 20, 'un', 28.00),
(5, 'Cartucho impressora HP preto', 5, 'un', 95.00),
(5, 'Cartucho impressora HP colorido', 4, 'un', 120.00),
(5, 'Pasta AZ', 30, 'un', 18.00),
(5, 'Canetas esferográficas (caixa 12)', 10, 'cx', 22.00);

-- ------------------------------------------------------------
-- COTAÇÕES
-- ------------------------------------------------------------
INSERT INTO cotacoes
    (pedido_id, fornecedor_id, numero_cotacao, data_cotacao, validade_cotacao,
     prazo_entrega, status, valor_total, condicoes_pagamento, observacoes)
VALUES
-- Cotações do PC-2026-001 (concluído — uniformes)
(1, 1, 'SM-2025-4421', '2025-12-10', '2025-12-31', 10, 'selecionada', 42800.00,
 '50% entrada, 50% na entrega', 'Melhor preço + entrega no prazo. SELECIONADA.'),
(1, 6, 'GC-2025-0891', '2025-12-11', '2025-12-31', 20, 'rejeitada',  46200.00,
 '30 dias', 'Prazo de entrega longo demais.'),

-- Cotações do PC-2026-002 (academia — em compra)
(2, 1, 'SM-2026-0112', '2026-01-20', '2026-02-20', 15, 'selecionada', 36500.00,
 '30 dias', 'Incluí instalação e garantia de 2 anos. SELECIONADA.'),
(2, 4, 'TF-2026-0034', '2026-01-22', '2026-02-22', 20, 'rejeitada',  39800.00,
 '28 dias', 'Valor acima do orçamento aprovado.'),

-- Cotações do PC-2026-003 (fisioterapia — aguardando aprovação)
(3, 3, 'MS-2026-0078', '2026-02-14', '2026-03-14', 3,  'selecionada', 17200.00,
 'Mensal', 'Proposta com 3 fisios + materiais. Referência no mercado. SELECIONADA.'),
(3, 3, 'MS-2026-0079', '2026-02-15', '2026-03-15', 3,  'recebida',    18500.00,
 'Mensal', 'Proposta alternativa com 2 fisios sênior.'),
(3, 3, 'INDEP-2026-01', '2026-02-16', '2026-03-16', 1, 'recebida',    15000.00,
 'Mensal', 'Profissionais autônomos. Menor custo porém sem CNPJ.'),

-- Cotação do PC-2026-004 (transporte — em cotação)
(4, 5, 'TF-2026-0210', '2026-03-10', '2026-03-25', 2,  'recebida',    11500.00,
 '30 dias após evento', 'Ônibus Volvo executivo. Motorista incluso.');

-- ------------------------------------------------------------
-- ITENS DAS COTAÇÕES (vinculados ao pedido 1 — uniformes)
-- ------------------------------------------------------------
INSERT INTO itens_cotacao (cotacao_id, item_pedido_id, valor_unitario, valor_total, disponivel) VALUES
-- Cotação 1 (selecionada — SportMax) → itens pedido 1-5
(1, 1, 290.00,  6380.00, TRUE),
(1, 2, 160.00,  4800.00, TRUE),
(1, 3, 130.00,  3250.00, TRUE),
(1, 4,  38.00,  2280.00, TRUE),
(1, 5, 260.00,  7800.00, TRUE),
-- Cotação 2 (rejeitada — Gráfica) → itens pedido 1-5
(2, 1, 310.00,  6820.00, TRUE),
(2, 2, 195.00,  5850.00, TRUE),
(2, 3, 148.00,  3700.00, TRUE),
(2, 4,  50.00,  3000.00, TRUE),
(2, 5, 295.00,  8850.00, TRUE);

-- ------------------------------------------------------------
-- HISTÓRICO DOS PEDIDOS
-- ------------------------------------------------------------
INSERT INTO historico_pedido (pedido_id, acao, descricao) VALUES
(1, 'criou',           'Pedido criado como rascunho.'),
(1, 'enviou_cotacao',  'Pedido enviado para cotação com fornecedores.'),
(1, 'cotacao',         'Cotação recebida de SportMax Equipamentos: R$ 42.800,00.'),
(1, 'cotacao',         'Cotação recebida de Gráfica Campeão: R$ 46.200,00.'),
(1, 'selecionou',      'Cotação da SportMax selecionada como melhor proposta.'),
(1, 'enviou_aprovacao','Pedido enviado para aprovação do gestor.'),
(1, 'aprovou',         'Pedido aprovado. Valor aprovado: R$ 43.500,00.'),
(1, 'concluiu',        'Uniformes recebidos e conferidos. Valor final: R$ 42.800,00.'),

(2, 'criou',           'Pedido criado.'),
(2, 'enviou_cotacao',  'Enviado para cotação.'),
(2, 'cotacao',         'Cotação de SportMax: R$ 36.500,00 (inclui instalação e garantia).'),
(2, 'cotacao',         'Cotação de TechField: R$ 39.800,00.'),
(2, 'selecionou',      'SportMax selecionada. Melhor custo-benefício.'),
(2, 'aprovou',         'Aprovado pelo diretor. Em processo de compra.'),

(3, 'criou',           'Pedido criado. Início do campeonato exige fisioterapia diária.'),
(3, 'enviou_cotacao',  '3 cotações coletadas.'),
(3, 'selecionou',      'MedSport selecionada: R$ 17.200,00/mês.'),
(3, 'enviou_aprovacao','Aguardando aprovação da diretoria.'),

(4, 'criou',           'Pedido criado para jogos fora em abril.'),
(4, 'cotacao',         'Cotação de TransportesFut: R$ 11.500,00.'),

(5, 'criou',           'Pedido de material de escritório para Q2.'),

(7, 'criou',           'Pedido de reforma do camarote criado.'),
(7, 'rejeitou',        'Rejeitado. Não é prioridade no momento. Orçamento limitado.'),

(8, 'criou',           'Pedido de marketing criado.'),
(8, 'cancelou',        'Cancelado — verba redirecionada para contratação de atleta.');
