-- ============================================================
-- MÓDUAM 3: PEDIDOS DE COMPRA
-- ERP SAF — Schema do Banco de Dados
-- ============================================================

-- ------------------------------------------------------------
-- FORNECEDORES
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fornecedores (
    id              SERIAL PRIMARY KEY,
    nome            VARCHAR(200) NOT NULL,
    cnpj            VARCHAR(18),
    contato         VARCHAR(100),
    email           VARCHAR(150),
    telefone        VARCHAR(20),
    categoria       VARCHAR(100),   -- ex: "Material Esportivo", "Serviços", "Alimentação"
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    observacoes     TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- PEDIDOS DE COMPRA
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pedidos_compra (
    id                      SERIAL PRIMARY KEY,
    numero                  VARCHAR(20) NOT NULL UNIQUE,   -- ex: PC-2026-001
    titulo                  VARCHAR(200) NOT NULL,
    descricao               TEXT,

    -- Solicitante e departamento
    solicitante_id          INTEGER REFERENCES usuarios(id),
    departamento_id         INTEGER REFERENCES departamentos(id),

    -- Prioridade e prazo
    prioridade              VARCHAR(10) NOT NULL DEFAULT 'normal'
                            CHECK (prioridade IN ('baixa','normal','alta','urgente')),
    data_necessidade        DATE,

    -- Status do fluxo de aprovação
    status                  VARCHAR(30) NOT NULL DEFAULT 'rascunho'
                            CHECK (status IN (
                                'rascunho',
                                'aguardando_cotacao',
                                'em_cotacao',
                                'aguardando_aprovacao',
                                'aprovado',
                                'rejeitado',
                                'em_compra',
                                'concluido',
                                'cancelado'
                            )),

    -- Aprovação
    aprovador_id            INTEGER REFERENCES usuarios(id),
    data_aprovacao          TIMESTAMP WITH TIME ZONE,
    motivo_rejeicao         TEXT,

    -- Vínculo financeiro
    categoria_financeira_id INTEGER REFERENCES categorias_financeiras(id),
    centro_custo_id         INTEGER REFERENCES centros_custo(id),

    -- Valores
    valor_estimado          NUMERIC(12,2),
    valor_aprovado          NUMERIC(12,2),
    valor_final             NUMERIC(12,2),

    observacoes             TEXT,
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- ITENS DO PEDIDO
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS itens_pedido (
    id                          SERIAL PRIMARY KEY,
    pedido_id                   INTEGER NOT NULL REFERENCES pedidos_compra(id) ON DELETE CASCADE,
    descricao                   VARCHAR(300) NOT NULL,
    quantidade                  NUMERIC(10,2) NOT NULL DEFAULT 1,
    unidade                     VARCHAR(30) DEFAULT 'un',    -- un, kg, m, caixa, etc.
    valor_unitario_estimado     NUMERIC(12,2),
    valor_unitario_final        NUMERIC(12,2),
    observacoes                 TEXT,
    created_at                  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- COTAÇÕES (ORÇAEMENTOS DE FORNECEDORES)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS cotacoes (
    id                  SERIAL PRIMARY KEY,
    pedido_id           INTEGER NOT NULL REFERENCES pedidos_compra(id) ON DELETE CASCADE,
    fornecedor_id       INTEGER REFERENCES fornecedores(id),
    numero_cotacao      VARCHAR(50),        -- nԺmero da proposta do fornecedor

    data_cotacao        DATE NOT NULL DEFAULT CURRENT_DATE,
    validade_cotacao    DATE,               -- até quando a proposta é válida
    prazo_entrega       INTEGER,            -- dias para entrega

    status              VARCHAR(20) NOT NULL DEFAULT 'pendente'
                        CHECK (status IN ('pendente','recebida','selecionada','rejeitada')),

    valor_total         NUMERIC(12,2),
    condicoes_pagamento VARCHAR(200),
    observacoes         TEXT,
    arquivo_cotacao     VARCHAR(300),       -- nome do arquivo anexado

    criado_por          INTEGER REFERENCES usuarios(id),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- ITENS DA COTAÇÃO (vinculado a cada item do pedido)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS itens_cotacao (
    id              SERIAL PRIMARY KEY,
    cotacao_id      INTEGER NOT NULL REFERENCES cotacoes(id) ON DELATE CASEADELETE CASCADE,
    item_pedido_id  INTEGER NOT NULL REFERENCES itens_pedido(id) ON DELETE CASCADE,
    valor_unitario  NUMERIC(12,2),
    valor_total     NUMERIC(12,2),
    disponivel      BOOLEAN DEFAULT TRUE,
    observacoes     TEXT
);

-- ------------------------------------------------------------
-- HISTÓRICO / AUDITORIA DO PEDIDO
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS historico_pedido (
    id          SERIAL PRIMARY KEY,
    pedido_id   INTEGER NOT NULL REFERENCES pedidos_compra(id) ON DELETE CASCADE,
    usuario_id  INTEGER REFERENCES usuarios(id),
    acao        VARCHAR(50) NOT NULL,   -- ex: criou, editou, enviou_cotacao, aprovou, rejeitou
    descricao   TEXT,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- TRIGGERS — updated_at automatico
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION atualizar_updated_at()
BETURNS TRIGGER AS $$
BEGIN
    NEW.upda