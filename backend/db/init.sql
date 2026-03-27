-- ============================================================
-- ERP SAF β€” Schema do Banco de Dados
-- MΓ³dulo 1: FuncionΓ΅rios e ComissΓ£o TΓ©cnica
-- ============================================================

-- ExtensΓ£o para UUIDs (opcional, mas boa prΓ΅tica)
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

-- Departamentos padrΓ£o de uma SAF
INSERT INTO departamentos (nome, descricao) VALUES
  ('Futebol Profissional', 'ComissΓ£o tΓ©cnica e suporte ao elenco'),
  ('Futebol de Base', 'Categorias de formaΓ§Γ£o'),
  ('Financeiro', 'Controladoria, contabilidade e tesouraria'),
  ('Administrativo', 'GestΓ£o geral e suporte administrativo'),
  ('Marketing e Comercial', 'PatrocΓ­nios, comunicaΓ§Γ£o e vendas'),
  ('JurΓ­dico', 'Contratos, compliance e assessoria legal'),
  ('MΓ©dico e Fisioterapia', 'SaΓΊde e reabilitaΓ§Γ£o dos atletas'),
  ('TI e AnΓ΅lise de Dados', 'Tecnologia e anΓ΅lise de desempenho'),
  ('SeguranΓ§a', 'SeguranΓ§a patrimonial e dos jogos');

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
  razao_social     VARCHAR(200),                -- RazΓ£o social da empresa PJ

  -- Controle
  status           VARCHAR(20)  NOT NULL DEFAULT 'ativo'
                   CHECK (status IN ('ativo', 'ferias', 'afastado', 'desligado')),
  observacoes      TEXT,
  created_at       TIMESTAMP    NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Γndices para performance
CREATE INDEX idx_funcionarios_status        ON funcionarios(status);
CREATE INDEX idx_funcionarios_departamento  ON funcionarios(departamento_id);
CREATE INDEX idx_funcionarios_tipo_contrato ON funcionarios(tipo_contrato);

-- ============================================================
-- TABELA: historico_salarios
-- Toda alteraΓ§Γ£o de salΓ΅rio Γ© registrada aqui
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
  data_upload     TIMESTAMP     NOT NULL DEFAULT NOW(),(€ΥΑ±½…‘•‘}Α½Θ€€€%9QH€€€€€€II9L™ΥΉ¥½Ή…Ι¥½Μ΅¥¤(¤μ((΄΄€ττττττττττττττττττττττττττττττττττττττττττττττττττττττττττττ(΄΄Q	1θΥΝΥ…Ι¥½Μ(΄¬½ΉΡΙ½±”‘”…•ΝΝΌ…ΌΝ¥ΝΡ•µ„(΄΄€τττττττττττττττττττττττ