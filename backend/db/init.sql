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
CREATE TABLE funcionarios (
  id               SERIAL PRIMARY KEY,

  -- Dados pessoais
  nome_completo    VARCHAR(200) NOT NULL,
  cpf              VARCHAR(14)  UNIQUE,          -- 000.000.000-00
  rg               VARCHAR(20),
  data_nascimento  DATE,
  email            VARCHAR(150) UNIQUE,
  email_corporativo VARCHAR(150),
  telefone         VARCHAR(20),
  endereco         TEXT,
  foto_url         VARCHAR(500),

  -- Dados profissionais
  cargo            VARCHAR(100) NOT NULL,
  departamento_id  INTEGER NOT NULL REFERENCES departamentos(id),
  tipo_contrato    VARCHAR(5)   NOT NULL CHECK (tipo_contrato IN ('CLT', 'PJ')),
  salario          NUMERIC(12,2) NOT NULL,
  data_admissao    DATE         NOT NULL,
  data_demissao    DATE,
  gestor_id        INTEGER REFERENCES funcionarios(id),   -- hierarquia

  -- Para contratos PJ
  cnpj             VARCHAR(18),                 -- CNPJ da empresa PJ
  razao_social     VARCHAR(200),                -- Razão social da empresa PJ

  -- Controle
  status           VARCHAR(20)  NOT NULL DEFAULT 'ativo'
                   CHECK (status IN ('ativo', 'ferias', 'afastado', 'desligado')),
  observacoes      TEXT,
  created_at       TIMESTAMP    NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_funcionarios_status        ON funcionarios(status);
CREATE INDEX idx_funcionarios_departamento  ON funcionarios(departamento_id);
CREATE INDEX idx_funcionarios_tipo_contrato ON