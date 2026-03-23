-- ============================================================
-- ERP SAF — Dados financeiros de exemplo
-- Simula 6 meses de movimentação de uma SAF real
-- ============================================================

-- Receitas (ids de categorias: 1=Patrocínio, 2=Bilheteria, 3=TV, 4=Transfer, 5=Aporte, 6=Loja, 7=Prêmios)
INSERT INTO lancamentos_financeiros
  (tipo, descricao, valor, categoria_id, centro_custo_id, conta_bancaria_id, data_competencia, data_pagamento, status, origem_tipo)
VALUES
  -- Outubro 2025
  ('receita', 'Patrocínio máster – Empresa ABC',        120000, 1, 7, 1, '2025-10-01', '2025-10-03', 'realizado', 'manual'),
  ('receita', 'Bilheteria – Jogo Campeonato Estadual',    28500, 2, 1, 1, '2025-10-10', '2025-10-10', 'realizado', 'manual'),
  ('receita', 'Cota direitos de TV – Outubro',            45000, 3, 7, 1, '2025-10-15', '2025-10-16', 'realizado', 'manual'),
  ('despesa', 'Folha de pagamento CLT – Outubro',        198000, 9, 3, 1, '2025-10-31', '2025-10-31', 'realizado', 'folha'),
  ('despesa', 'Contratos PJ comissão técnica – Out',      56000,10, 1, 1, '2025-10-31', '2025-10-31', 'realizado', 'folha'),
  ('despesa', 'Aluguel e manutenção CT – Outubro',        18000,14, 6, 1, '2025-10-05', '2025-10-05', 'realizado', 'manual'),
  ('despesa', 'Viagem jogo fora – combustível e hotel',    8700,13, 1, 3, '2025-10-12', '2025-10-12', 'realizado', 'manual'),
  ('despesa', 'Materiais esportivos – bolas e coletes',    4200,12, 1, 3, '2025-10-18', '2025-10-20', 'realizado', 'pedido_compra'),
  ('despesa', 'Medicamentos e insumos médicos',            3100,15, 5, 1, '2025-10-22', '2025-10-24', 'realizado', 'pedido_compra'),

  -- Novembro 2025
  ('receita', 'Patrocínio máster – Empresa ABC',        120000, 1, 7, 1, '2025-11-01', '2025-11-04', 'realizado', 'manual'),
  ('receita', 'Bilheteria – Jogo Copa do Estado',         42000, 2, 1, 1, '2025-11-08', '2025-11-08', 'realizado', 'manual'),
  ('receita', 'Cota direitos de TV – Novembro',           45000, 3, 7, 1, '2025-11-15', '2025-11-15', 'realizado', 'manual'),
  ('receita', 'Loja oficial – vendas novembro',            9800, 6, 4, 1, '2025-11-30', '2025-11-30', 'realizado', 'manual'),
  ('despesa', 'Folha de pagamento CLT – Novembro',       198000, 9, 3, 1, '2025-11-30', '2025-11-30', 'realizado', 'folha'),
  ('despesa', 'Contratos PJ comissão técnica – Nov',      56000,10, 1, 1, '2025-11-30', '2025-11-30', 'realizado', 'folha'),
  ('despesa', 'Aluguel e manutenção CT – Novembro',       18000,14, 6, 1, '2025-11-05', '2025-11-05', 'realizado', 'manual'),
  ('despesa', 'Patrocínio contra – uniforme jogadores',    6500,16, 4, 1, '2025-11-20', '2025-11-22', 'realizado', 'manual'),
  ('despesa', 'Seguro de saúde – equipe completa',         7200,15, 5, 1, '2025-11-10', '2025-11-10', 'realizado', 'manual'),

  -- Dezembro 2025
  ('receita', 'Patrocínio máster – Empresa ABC',        120000, 1, 7, 1, '2025-12-01', '2025-12-02', 'realizado', 'manual'),
  ('receita', 'Cota direitos de TV – Dezembro',           45000, 3, 7, 1, '2025-12-15', '2025-12-16', 'realizado', 'manual'),
  ('receita', 'Prêmio classificação playoffs',            30000, 7, 1, 1, '2025-12-20', '2025-12-20', 'realizado', 'manual'),
  ('despesa', 'Folha de pagamento CLT – Dezembro',       198000, 9, 3, 1, '2025-12-31', '2025-12-31', 'realizado', 'folha'),
  ('despesa', 'Contratos PJ comissão técnica – Dez',      56000,10, 1, 1, '2025-12-31', '2025-12-31', 'realizado', 'folha'),
  ('despesa', 'Aluguel e manutenção CT – Dezembro',       18000,14, 6, 1, '2025-12-05', '2025-12-05', 'realizado', 'manual'),
  ('despesa', '13º salário – parcela 2ª',                 99000, 9, 3, 1, '2025-12-20', '2025-12-20', 'realizado', 'folha'),

  -- Janeiro 2026
  ('receita', 'Patrocínio máster – Empresa ABC',        120000, 1, 7, 1, '2026-01-01', '2026-01-03', 'realizado', 'manual'),
  ('receita', 'Aporte investidor – Fundo Alpha',         350000, 5, 7, 1, '2026-01-10', '2026-01-10', 'realizado', 'manual'),
  ('receita', 'Cota direitos de TV – Janeiro',            45000, 3, 7, 1, '2026-01-15', '2026-01-15', 'realizado', 'manual'),
  ('despesa', 'Folha de pagamento CLT – Janeiro',        198000, 9, 3, 1, '2026-01-31', '2026-01-31', 'realizado', 'folha'),
  ('despesa', 'Contratos PJ comissão técnica – Jan',      56000,10, 1, 1, '2026-01-31', '2026-01-31', 'realizado', 'folha'),
  ('despesa', 'Aluguel e manutenção CT – Janeiro',        18000,14, 6, 1, '2026-01-05', '2026-01-05', 'realizado', 'manual'),
  ('despesa', 'Renovação de contratos – honorários jur.', 12000,17, 7, 1, '2026-01-15', '2026-01-18', 'realizado', 'manual'),
  ('despesa', 'Equipamento academia – musculação',        22000,12, 1, 1, '2026-01-20', '2026-01-22', 'realizado', 'pedido_compra'),

  -- Fevereiro 2026
  ('receita', 'Patrocínio máster – Empresa ABC',        120000, 1, 7, 1, '2026-02-01', '2026-02-04', 'realizado', 'manual'),
  ('receita', 'Bilheteria – Amistoso pré-temporada',      15000, 2, 1, 1, '2026-02-14', '2026-02-14', 'realizado', 'manual'),
  ('receita', 'Cota direitos de TV – Fevereiro',          45000, 3, 7, 1, '2026-02-15', '2026-02-16', 'realizado', 'manual'),
  ('despesa', 'Folha de pagamento CLT – Fevereiro',      198000, 9, 3, 1, '2026-02-28', '2026-02-28', 'realizado', 'folha'),
  ('despesa', 'Contratos PJ comissão técnica – Fev',      56000,10, 1, 1, '2026-02-28', '2026-02-28', 'realizado', 'folha'),
  ('despesa', 'Aluguel e manutenção CT – Fevereiro',      18000,14, 6, 1, '2026-02-05', '2026-02-05', 'realizado', 'manual'),
  ('despesa', 'Viagem pré-temporada – Chapecó',           14500,13, 1, 1, '2026-02-10', '2026-02-12', 'realizado', 'manual'),
  ('despesa', 'Materiais treino – pré-temporada',          6800,12, 1, 3, '2026-02-08', '2026-02-09', 'realizado', 'pedido_compra'),

  -- Março 2026
  ('receita', 'Patrocínio máster – Empresa ABC',        120000, 1, 7, 1, '2026-03-01', '2026-03-03', 'realizado', 'manual'),
  ('receita', 'Bilheteria – 1ª rodada Campeonato',        31000, 2, 1, 1, '2026-03-08', '2026-03-08', 'realizado', 'manual'),
  ('receita', 'Cota direitos de TV – Março',              45000, 3, 7, 1, '2026-03-15', NULL,          'previsto',  'manual'),
  ('receita', 'Loja oficial – vendas março',               8200, 6, 4, 1, '2026-03-20', NULL,          'previsto',  'manual'),
  ('despesa', 'Folha de pagamento CLT – Março',          198000, 9, 3, 1, '2026-03-31', NULL,          'previsto',  'folha'),
  ('despesa', 'Contratos PJ comissão técnica – Mar',      56000,10, 1, 1, '2026-03-31', NULL,          'previsto',  'folha'),
  ('despesa', 'Aluguel e manutenção CT – Março',          18000,14, 6, 1, '2026-03-05', '2026-03-05',  'realizado', 'manual'),
  ('despesa', 'Encargos FGTS e INSS – Março',             42000,11, 3, 1, '2026-03-20', NULL,          'previsto',  'folha'),
  ('despesa', 'Uniforme 1º time – temporada 2026',        35000,12, 1, 1, '2026-03-10', '2026-03-12',  'realizado', 'pedido_compra'),
  ('despesa', 'Marketing redes sociais – Março',           5500,16, 4, 1, '2026-03-01', '2026-03-01',  'realizado', 'manual');
