-- ============================================================
-- MÓDULO 3: PEDIDOS DE COMPRA
-- ERP SAF — Schema do Banco de Dados
-- ============================================================

CREATE TABLE IF NOT EXISTS fornecedores (
    id              SERIAL PRIMARY KEY,
    nome            VARCHAR(200) NOT NULL,
    cnpj            VARCHAR(18),
    contato         VARCHAR(100),
    email           VARCHAR(150),
    telefone        VARCHAR(20),
    categoria       VARCHAR(100),
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    observacoes     TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS pedidos_compra (
    id                      SERIAL PRIMARY KEY,
    numero                  VARCHAR(20) NOT NULL UNIQUE,
    titulo                  VARCHAR(200) NOT NULL,
    descricao               TEXT,
    solicitante_id          INTEGER REFERENCES usuarios(id),
    departamento_id         INTEGER REFERENCES departamentos(id),
    prioridade              VARCHAR(10) NOT NULL DEFAULT 'normal'
                            CHECK (prioridade IN ('baixa','normal','alta','urgente')),
    data_necessidade        DATE,
    status                  VARCHAR(30) NOT NULL DEFAULT 'rascunho'
                            CHECK (status IN ('rascunho','aguardando_cotacao','em_cotacao','aguardando_aprovacao','aprovado','rejeitado','em_compra','concluido','cancelado')),
    aprovador_id            INTEGER REFERENCES usuarios(id),
    data_aprovacao          TIMESTAMP WITH TIME ZONE,
    motivo_rejeicao         TEXT,
    categoria_financeira_id INTEGER REFERENCES categorias_financeiras(id),
    centro_custo_id         INTEGER REFERENCES centros_custo(id),
    valor_estimado          NUMERIC(12,2),
    valor_aprovado          NUMERIC(12,2),
    valor_final             NUMERIC(12,2),
    observacoes             TEXT,
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS itens_pedido (
    id                          SERIAL PRIMARY KEY,
    pedido_id                   INTEGER NOT NULL REFERENCES pedidos_compra(id) ON DELETE CASCADE,
    descricao                   VARCHAR(300) NOT NULL,
    quantidade                  NUMERIC(10,2) NOT NULL DEFAULT 1,
    unidade                     VARCHAR(30) DEFAULT 'un',
    valor_unitario_estimado     NUMERIC(12,2),
    valor_unitario_final        NUMERIC(12,2),
    observacoes                 TEXT,
    created_at                  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS cotacoes (
    id                  SERIAL PRIMARY KEY,
    pedido_id           INTEGER NOT NULL REFERENCES pedidos_compra(id) ON DELETE CASCADE,
    fornecedor_id       INTEGER REFERENCES fornecedores(id),
    numero_cotacao      VARCHAR(50),
    data_cotacao        DATE NOT NULL DEFAULT CURRENT_DATE,
    validade_cotacao    DATE,
    prazo_entrega       INTEGER,
    status              VARCHAR(20) NOT NULL DEFAULT 'pendente'
                        CHECK (status IN ('pendente','recebida','selecionada','rejeitada')),
    valor_total         NUMERIC(12,2),
    condicoes_pagamento VARCHAR(200),
    observacoes         TEXT,
    arquivo_cotacao     VARCHAR(300),
    selecionada         BOOLEAN DEFAULT FALSE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pedidos_status      ON pedidos_compra(status);
CREATE INDEX IF NOT EXISTS idx_pedidos_numero      ON pedidos_compra(numero);
CREATE INDEX IF NOT EXISTS idx_cotacoes_pedido     ON cotacoes(pedido_id);
CREATE INDEX IF NOT EXISTS idx_itens_pedido        ON itens_pedido(pedido_id);

CREATE OR REPLACE VIEW pedidos_completo AS
SELECT p.*, u.nome AS solicitante_nome, d.nome AS departamento_nome,
    COALESCE((SELECT SUM(ip.quantidade * ip.valor_unitario_estimado) FROM itens_pedido ip WHERE ip.pedido_id = p.id), 0) AS valor_total_estimado
FROM pedidos_compra p
LEFT JOIN usuarios u ON u.id = p.solicitante_id
LEFT JOIN departamentos d ON d.id = p.departamento_id;

INSERT INTO fornecedores (nome, cnpj, contato, email, telefone, categoria) VALUES
    ('SportMax Equipamentos', '11.222.333/0001-44', 'Carlos Lima', 'vendas@sportmax.com.br', '(11) 3000-1111', 'Material Esportivo'),
    ('Nutrição Total', '22.333.444/0001-55', 'Ana Paula', 'ana@nutricaototal.com', '(11) 9999-2222', 'Alimentação'),
    ('MedSport Clínica', '33.444.555/0001-66', 'Dr. Roberto', 'contato@medsport.com.br', '(11) 3500-3333', 'Saúde e Medicina')
ON CONFLICT DO NOTHING;
