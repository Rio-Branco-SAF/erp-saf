-- ============================================================
-- ERP SAF — Dados de Exemplo (Seed)
-- Use para testar o sistema antes de importar dados reais
-- ============================================================

-- Funcionários de exemplo (mix CLT e PJ)
INSERT INTO funcionarios
  (nome_completo, cpf, data_nascimento, email, email_corporativo, telefone, cargo, departamento_id, tipo_contrato, salario, data_admissao, status, gestor_id)
VALUES
  -- Diretoria (sem gestor)
  ('Carlos Eduardo Mendes',  '111.222.333-44', '1978-03-15', 'carlos.mendes@gmail.com',    'ceo@saf.com.br',         '(11) 99999-0001', 'CEO / Presidente',             4, 'CLT', 45000.00, '2022-01-01', 'ativo',  NULL),
  ('Fernanda Lima Costa',    '222.333.444-55', '1980-07-22', 'fernanda.lima@gmail.com',     'financeiro@saf.com.br',  '(11) 99999-0002', 'Diretora Financeira',          3, 'CLT', 35000.00, '2022-01-01', 'ativo',  1),
  ('Roberto Alves Neto',     '333.444.555-66', '1975-11-08', 'roberto.alves@gmail.com',     'dof@saf.com.br',         '(11) 99999-0003', 'Diretor de Futebol',           1, 'CLT', 38000.00, '2022-02-01', 'ativo',  1),

  -- Comissão Técnica (PJ)
  ('Marcelo Santos',         '444.555.666-77', '1968-05-20', 'marcelo.tecnico@gmail.com',   'tecnico@saf.com.br',     '(11) 99999-0004', 'Técnico Principal',            1, 'PJ',  25000.00, '2023-01-10', 'ativo',  3),
  ('André Oliveira',         '555.666.777-88', '1972-09-14', 'andre.assistente@gmail.com',  'assistente@saf.com.br',  '(11) 99999-0005', 'Assistente Técnico',           1, 'PJ',  12000.00, '2023-01-10', 'ativo',  4),
  ('Paulo Ferreira',         '666.777.888-99', '1970-04-02', 'paulo.prep@gmail.com',        'prep.fisico@saf.com.br', '(11) 99999-0006', 'Preparador Físico',            1, 'PJ',  10000.00, '2023-01-10', 'ativo',  4),
  ('Gustavo Rodrigues',      '777.888.999-00', '1985-08-30', 'gustavo.gol@gmail.com',       'prep.goleiros@saf.com.br','(11) 99999-0007','Preparador de Goleiros',       1, 'PJ',   9000.00, '2023-01-10', 'ativo',  4),

  -- Médico e Fisio (CLT)
  ('Dra. Juliana Pires',     '888.999.000-11', '1982-12-01', 'juliana.medica@gmail.com',    'medica@saf.com.br',      '(11) 99999-0008', 'Médica do Clube',              7, 'CLT', 18000.00, '2022-06-01', 'ativo',  3),
  ('Bruno Carvalho',         '999.000.111-22', '1990-02-18', 'bruno.fisio@gmail.com',       'fisio@saf.com.br',       '(11) 99999-0009', 'Fisioterapeuta',               7, 'CLT',  8500.00, '2022-06-01', 'ativo',  8),

  -- Financeiro (CLT)
  ('Mariana Souza',          '000.111.222-33', '1988-06-25', 'mariana.souza@gmail.com',     'controller@saf.com.br',  '(11) 99999-0010', 'Analista Financeiro Sênior',   3, 'CLT',  9500.00, '2022-03-01', 'ativo',  2),
  ('Rafael Cunha',           '111.000.222-44', '1993-10-11', 'rafael.cunha@gmail.com',      'financeiro2@saf.com.br', '(11) 99999-0011', 'Analista Financeiro Júnior',   3, 'CLT',  5500.00, '2023-04-01', 'ativo',  10),

  -- Marketing (CLT)
  ('Camila Torres',          '222.111.000-55', '1991-03-07', 'camila.torres@gmail.com',     'marketing@saf.com.br',   '(11) 99999-0012', 'Gerente de Marketing',         5, 'CLT', 11000.00, '2022-08-01', 'ativo',  1),
  ('Lucas Barbosa',          '333.222.111-66', '1995-07-19', 'lucas.barbosa@gmail.com',     'social@saf.com.br',      '(11) 99999-0013', 'Analista de Redes Sociais',    5, 'CLT',  5000.00, '2023-02-01', 'ativo',  12),

  -- TI (PJ)
  ('Diego Monteiro',         '444.333.222-77', '1989-01-28', 'diego.ti@gmail.com',          'ti@saf.com.br',          '(11) 99999-0014', 'Analista de TI',               8, 'PJ',   9000.00, '2022-09-01', 'ativo',  1),
  ('Thiago Nascimento',      '555.444.333-88', '1992-11-05', 'thiago.dados@gmail.com',      'dados@saf.com.br',       '(11) 99999-0015', 'Analista de Dados',            8, 'PJ',   8500.00, '2023-05-01', 'ativo',  14);

-- Histórico de salários de exemplo
INSERT INTO historico_salarios (funcionario_id, salario_anterior, salario_novo, data_alteracao, motivo)
VALUES
  (10, 8000.00,  9500.00, '2024-01-01', 'Promoção para Sênior'),
  (11, 4500.00,  5500.00, '2024-07-01', 'Reajuste anual'),
  (13, 4200.00,  5000.00, '2024-01-01', 'Reajuste anual');

-- Usuário administrador padrão
-- Senha: Admin@SAF2026 (troque imediatamente em produção!)
-- Hash gerado com bcrypt (12 rounds)
INSERT INTO usuarios (funcionario_id, email, senha_hash, perfil)
VALUES (1, 'ceo@saf.com.br', '$2b$12$oURfm9PrxyADroBRZDsdFu/RYVUFVK0FHCI0pW8QHfqcMNx.3wmLW', 'admin');
