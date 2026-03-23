-- ============================================================
-- ERP SAF — Schema Financeiro
-- Módulo 2: Financeiro (Fluxo de Caixa, Receitas, Despesas)
-- Execute este arquivo APÓS o schema.sql principal
-- ============================================================

-- ============================================================
-- TABELA: contas_bancarias
-- Contas do clube (corrente, investimento, caixa físico etc.)
-- ============================================================
CREATE TABLE contas_bancarias (
  id          SERIAL PRIMARY KEY,
  nome        VARCHAR(100) NOT NULL,           -- Ex: "Conta Corrente Bradesco"
  banco       VARCHAR(80),
  agencia     VARCHAR(10),
  conta       VARCHAR(20),
  tipo        VARCHAR(30) NOT NULL DEFAULT 'corrente'
              CHECK (tipo IN ('corrente', 'poupanca', 'investimento', 'caixa', 'outro')),
  saldo_inicial NUMERIC(14,2) NOT NULL DEFAULT 0,
  ativo       BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

INSERT INTO contas_bancarias (nome, banco, tipo, saldo_inicial) VALUES
  ('Conta Corrente Principal', 'Bradesco', 'corrente',    500000.00),
  ('Conta Poupança Reserva',   'Itaú',     'poupanca',    200000.00),
  ('Caixa Físico CT',          NULL,       'caixa',         5000.00);

-- ============================================================
-- TABELA: categorias_financeiras
-- Classificação das receitas e despesas
-- ============================================================
CREATE TABLE categorias_financeiras (
  id        SERIAL PRIMARY KEY,
  nome      VARCHAR(100) NOT NULL,
  tipo      VARCHAR(10)  NOT NULL CHECK (tipo IN ('receita', 'despesa', 'ambos')),
  icone     VARCHAR(10),
  cor       VARCHAR(7),
  ativo     BOOLEAN NOT NULL DEFAULT true
);

-- Categorias de RECEITA
INSERT INTO categorias_financeiras (nome, tipo, icone, cor) VALUES
  ('Patrocínio',              'receita', '🏷️',  '#1e8449'),
  ('Bilheteria / Ingresso',   'receita', '🎟️',  '#2980b9'),
  ('Direitos de TV',          'receita', '📺',  '#8e44ad'),
  ('Transferência de Atleta', 'receita', '⚽',  '#e67e22'),
  ('Aporte de Investidor',    'receita', '📈',  '#27ae60'),
  ('Licenciamento / Loja',    'receita', '👕',  '#16a085'),
  ('Prêmios e Bônus',         'receita', '🏆',  '#f39c12'),
  ('Outras Receitas',         'receita', '💰',  '#95a5a6');

-- Categorias de DESPESA
INSERT INTO categorias_financeiras (nome, tipo, icone, cor) VALUES
  ('Salários CLT',            'despesa', '👔',  '#c0392b'),
  ('Contratos PJ',            'despesa', '📋',  '#e74c3c'),
  ('Encargos e Impostos',     'despesa', '🏛️',  '#922b21'),
  ('Compras e Equipamentos',  'despesa', '🛒',  '#e67e22'),
  ('Viagens e Hospedagem',    'despesa', '✈️',  '#d35400'),
  ('Aluguel e Infraestrutura','despesa', '🏟️',  '#7d6608'),
  ('Saúde e Medicina',        'despesa', '🏥',  '#1a5276'),
  ('Marketing e Comunicação', 'despesa', '📢',  '#6c3483'),
  ('Multas e Rescisões',      'despesa', '⚠️',  '#7b241c'),
  ('Outras Despesas',         'despesa', '📌',  '#5d6d7e');

-- ============================================================
-- TABELA: centros_custo
-- Para controlar gastos por área do clube
-- ============================================================
CREATE TABLE centros_custo (
  id    SERIAL PRIMARY KEY,
  nome  VARCHAR(100) NOT NULL,
  ativo BOOLEAN NOT NULL DEFAULT true
);

INSERT INTO centros_custo (nome) VALUES
  ('Futebol Profissional'),
  ('Futebol de Base'),
  ('Administrativo'),
  ('Marketing e Comercial'),
  ('Médico e Fisioterapia'),
  ('Infraestrutura / CT'),
  ('Diretoria');

-- ============================================================
-- TABELA: lancamentos_financeiros
-- Cada receita ou despesa do clube — tabela principal
-- ============================================================
CREATE TABLE lancamentos_financeiros (
  id                  SERIAL PRIMARY KEY,
  tipo                VARCHAR(10)   NOT NULL CHECK (tipo IN ('receita', 'despesa')),
  descricao           VARCHAR(300)  NOT NULL,
  valor               NUMERIC(14,2) NOT NULL CHECK (valor > 0),
  categoria_id        INTEGER       NOT NULL REFERENCES categorias_financeiras(id),
  centro_custo_id     INTEGER       REFERENCES centros_custo(id),
  conta_bancaria_id   INTEGER       REFERENCES contas_bancarias(id),

  -- Datas
  data_competencia    DATE          NOT NULL,   -- quando ocorreu contabilmente
  data_pagamento      DATE,                     -- quando foi pago/recebido de fato

  -- Controle
  status              VARCHAR(20)   NOT NULL DEFAULT 'previsto'
                      CHECK (status IN ('previsto', 'realizado', 'cancelado')),
  recorrente          BOOLEAN       NOT NULL DEFAULT false,
  observacoes         TEXT,

  -- Rastreabilidade (liga com outros módulos)
  origem_tipo         VARCHAR(50),   -- 'contrato_atleta', 'pedido_compra', 'folha', 'manual'
  origem_id           INTEGER,       -- ID do registro de origem

  -- Comprovante
  comprovante_url     VARCHAR(500),

  -- Controle de auditoria
  criado_por          INTEGER       REFERENCES funcionarios(id),
  created_at          TIMESTAMP     NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- Índices para performance nas consultas mais comuns
CREATE INDEX idx_lanc_tipo           ON lancamentos_financeiros(tipo);
CREATE INDEX idx_lanc_status         ON lancamentos_financeiros(status);
CREATE INDEX idx_lanc_data_comp      ON lancamentos_financeiros(data_competencia);
CREATE INDEX idx_lanc_data_pag       ON lancamentos_financeiros(data_pagamento);
CREATE INDEX idx_lanc_categoria      ON lancamentos_financeiros(categoria_id);

-- Trigger para atualizar updated_at
CREATE TRIGGER trg_lancamentos_updated_at
  BEFORE UPDATE ON lancamentos_financeiros
  FOR EACH ROW EXECUTE FUNCTION atualizar_updated_at();

-- ============================================================
-- VIEW: resumo_mensal
-- Totais agrupados por mês — usada nos gráficos do dashboard
-- ============================================================
CREATE OR REPLACE VIEW resumo_mensal AS
SELECT
  TC_CHAR(data_competencia, 'YYYY-MM')          AS mes,
  TO_CHAR(data_competencia, 'Mon/YYYY')         AS mes_label,
  SUM(CASE WHEN tipo = 'receita' THEN valor ELSE 0 END)  AS total_receitas,
  SUM(CASE WHEN tipo = 'despesa' THEN valor ELSE 0 END)  AS total_despesas,
  SUM(CASE WHEN tipo = 'receita' THEN valor ELSE -valor END) AS saldo,
  COUNT(*)                                       AS qtd_lancamentos
FROM lancamentos_financeiros
WHERE status != 'cancelado'
GROUP BY TO_CHAR(data_competencia, 'YYYY-MM'), TO_CHAR(data_competencia, 'Mon/YYYY')
ORDER BY mes;

-- ============================================================
-- VIEW: lancamentos_completo
-- Join com categorias, centro de custo e conta bancária
-- ============================================================
CREATE OR REPLACE VIEW lancamentos_completo AS
SELECT
  l.id, l.tipo, l.descricao, l.valor, l.status,
  l.data_competencia, l.data_pagamento,
  l.recorrente, l.observacoes, l.comprovante_url,
  l.origem_tipo, l.origem_id,
  c.nome   AS categoria,
  c.icone  AS categoria_icone,
  c.cor    AS categoria_cor,
  cc.nome  AS centro_custo,
  cb.nome  AS conta_bancaria,
  f.nome_completo AS criado_por_nome,
  l.created_at, l.updated_at
FROM lancamentos_financeiros l
JOIN categorias_financeiras c  ON c.id = l.categoria_id
LEFT JOIN centros_custo cc     ON cc.id = l.centro_custo_id
LEFT JOIN contas_bancarias cb  ON cb.id = l.conta_bancaria_id
LEFT JOIN funcionarios f       ON f.id  = l.criado_por;
