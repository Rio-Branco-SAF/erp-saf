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
  departamento_id  INTEGER      NOT NULL REFERENCES departamentos(id),
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
CREATE INDEX idx_funcionarios_tipo_contrato ON funcionarios(tipo_contrato);

-- ============================================================
-- TABELA: historico_salarios
-- Toda alteração de salário é registrada aqui
-- ============================================================
CREATE TABLE historico_salarios (
  id               SERIAL PRIMARY KEY,
  funcionario_id   INTEGER      NOT NULL REFERENCES funcionarios(id),
  salario_anterior NUMERIC(12,2),
  salario_novo     NUMERIC(12,2) NOT NULL,
  data_alteracao   DATE         NOT NULL DEFAULT CURRENT_DATE,
  motivo           VARCHAR(300),
  registrado_por   INTEGER      REFERENCES funcionarios(id),
  created_at       TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABELA: documentos_funcionarios
-- Armazena links para arquivos (contrato CLT, nota fiscal PJ, RG etc.)
-- ============================================================
CREATE TABLE documentos_funcionarios (
  id              SERIAL PRIMARY KEY,
  funcionario_id  INTEGER       NOT NULL REFERENCES funcionarios(id),
  tipo            VARCHAR(50)   NOT NULL,   -- 'contrato', 'rg', 'cpf', 'nota_fiscal', 'outro'
  nome_arquivo    VARCHAR(200)  NOT NULL,
  arquivo_url     VARCHAR(500)  NOT NULL,
  data_upload     TIMESTAMP     NOT NULL DEFAULT NOW(),
  uploaded_por    INTEGER       REFERENCES funcionarios(id)
);

-- ============================================================
-- TABELA: usuarios
-- Controle de acesso ao sistema
-- ============================================================
CREATE TABLE usuarios (
  id             SERIAL PRIMARY KEY,
  funcionario_id INTEGER      REFERENCES funcionarios(id),
  email          VARCHAR(150) NOT NULL UNIQUE,
  senha_hash     VARCHAR(255) NOT NULL,
  perfil         VARCHAR(20)  NOT NULL DEFAULT 'funcionario'
                 CHECK (perfil IN ('admin', 'gestor', 'financeiro', 'funcionario', 'rh')),
  ativo          BOOLEAN      NOT NULL DEFAULT true,
    primeiro_acesso  BOOLEAN      NOT NULL DEFAULT true,
  ultimo_acesso  TIMESTAMP,
  created_at     TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TRIGGER: atualiza updated_at automaticamente
-- ============================================================
CREATE OR REPLACE FUNCTION atualizar_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE PLpGql;

CREATE TRIGGER trg_funcionarios_updated_at
  BEFORE UPDATE ON funcionarios
  FOR EACH ROW EXECUTE FUNCTION atualizar_updated_at();

-- ============================================================
-- VIEW: funcionarios_completo
-- Junta todas as informações relevantes para a listagem
-- ============================================================
CREATE OR REPLACE VIEW funcionarios_completo AS
SELECT
  f.id,
  f.nome_completo,
  f.cpf,
  f.email,
  f.email_corporativo,
  f.telefone,
  f.cargo,
  d.nome            AS departamento,
  f.departamento_id,
  f.tipo_contrato,
  f.salario,
  f.data_admissao,
  f.data_demissao,
  f.status,
  f.foto_url,
  f.cnpj,
  f.razao_social,
  f.observacoes,
  g.nome_completo   AS gestor_nome,
  f.gestor_id,
  EXTRACT(YEAR FROM AGE(NOW(), f.data_admissao))::INTEGER AS anos_casa,
  f.created_at,
  f.updated_at
FROM funcionarios f
JOIN departamentos d ON d.id = f.departamento_id
LEFT JOIN funcionarios g ON g.id = f.gestor_id;
