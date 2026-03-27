-- ============================================================
-- ERP SAF — Schema do Banco de Dados
-- Módulo 1: Funcionários e Comissão Técnica
-- ============================================================

-- Extensão para UUIDs (opcional, mas boa prática)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- TABELA: departamentos
-- ============================================================
CREATE TABLE departamentos (
  id        SERIAL PRIMARY KEY,
  nome      VARCHAR(100) NOT NULL UNIQUE,
  descricao TEXT,
  ativo     BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Departamentos padrão de uma SAF
INSERT INTO departamentos (nome, descricao) VALUES
  ('Futebol Profissional', 'Comissão técnica e suporte ao elenco'),
  ('Futebol de Base', 'Categorias de formação'),
  ('Financeiro', 'Controladoria, contabilidade e tesouraria'),
  ('Administrativo', 'Gestão geral e suporte administrativo'),
  ('Marketing e Comercial', 'Patrocínios, comunicação e vendas'),
  ('Jurídico', 'Contratos, compliance e assessoria legal'),
  ('Médico e Fisioterapia', 'Saúde e reabilitação dos atletas'),
  ('TI e Análise de Dados', 'Tecnologia e análise de desempenho'),
  ('Segurança', 'Segurança patrimonial e dos jogos');

-- ============================================================
-- TABELA: funcionarios
-- ============================================================
CREAT