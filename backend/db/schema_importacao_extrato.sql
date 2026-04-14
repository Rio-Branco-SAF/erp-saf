-- ERP SAF: Schema Importacao de Extrato Bancario (OFX/CSV/PDF)

CREATE TABLE importacoes_extrato (
  id SERIAL PRIMARY KEY,
  conta_bancaria_id INTEGER REFERENCES contas_bancarias(id),
  nome_arquivo VARCHAR(255) NOT NULL,
  formato VARCHAR(5) NOT NULL CHECK (formato IN ('OFX','CSV','PDF')),
  status VARCHAR(20) NOT NULL DEFAULT 'revisao' CHECK (status IN ('revisao','confirmado','cancelado')),
  total_lancamentos INTEGER NOT NULL DEFAULT 0,
  total_confirmados INTEGER NOT NULL DEFAULT 0,
  total_ignorados INTEGER NOT NULL DEFAULT 0,
  valor_total_credito NUMERIC(14,2) NOT NULL DEFAULT 0,
  valor_total_debito NUMERIC(14,2) NOT NULL DEFAULT 0,
  periodo_inicio DATE,
  periodo_fim DATE,
  importado_por INTEGER REFERENCES usuarios(id),
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE lancamentos_importados (
  id SERIAL PRIMARY KEY,
  importacao_id INTEGER NOT NULL REFERENCES importacoes_extrato(id) ON DELETE CASCADE,
  data_lancamento DATE NOT NULL,
  descricao VARCHAR(500) NOT NULL,
  valor NUMERIC(14,2) NOT NULL,
  tipo VARCHAR(10) NOT NULL CHECK (tipo IN ('receita','despesa')),
  referencia_banco VARCHAR(100),
  saldo_apos NUMERIC(14,2),
  categoria_id INTEGER REFERENCES categorias_financeiras(id),
  categoria_sugerida_id INTEGER REFERENCES categorias_financeiras(id),
  confianca_sugestao NUMERIC(3,2) DEFAULT 0,
  keywords_match VARCHAR(200),
  status VARCHAR(15) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','confirmado','ignorado')),
  observacao TEXT,
  lancamento_financeiro_id INTEGER REFERENCES lancamentos_financeiros(id),
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE regras_categorizacao (
  id SERIAL PRIMARY KEY,
  keyword VARCHAR(100) NOT NULL,
  categoria_id INTEGER NOT NULL REFERENCES categorias_financeiras(id),
  tipo_transacao VARCHAR(10) CHECK (tipo_transacao IN ('receita','despesa','ambos')),
  prioridade INTEGER NOT NULL DEFAULT 5,
  ativo BOOLEAN NOT NULL DEFAULT true,
  criado_por INTEGER REFERENCES usuarios(id),
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_importacoes_status ON importacoes_extrato(status);
CREATE INDEX idx_lanc_imp_importacao ON lancamentos_importados(importacao_id);
CREATE INDEX idx_lanc_imp_status ON lancamentos_importados(status);
