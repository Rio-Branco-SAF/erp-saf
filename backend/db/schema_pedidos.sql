-- ============================================================
-- MÓDULO 3: PEDIDOS DE COMPRA
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
-- COTAÇÕES (ORÇAMENTOS DE FORNECEDORES)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cotacoes (
    id                  SERIAL PRIMARY KEY,
    pedido_id           INTEGER NOT NULL REFERENCES pedidos_compra(id) ON DELETE CASCADE,
    fornecedor_id       INTEGER REFERENCES fornecedores(id),
    numero_cotacao      VARCHAR(50),        -- número da proposta do fornecedor

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
    cotacao_id      INTEGER NOT NULL REFERENCES cotacoes(id) ON DELETE CASCADE,
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
-- TRIGGERS — updated_at automático
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION atualizar_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'trg_fornecedores_updated_at'
    ) THEN
        CREATE TRIGGER trg_fornecedores_updated_at
            BEFORE UPDATE ON fornecedores
            FOR EACH ROW EXECUTE FUNCTION atualizar_updated_at();
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'trg_pedidos_updated_at'
    ) THEN
        CREATE TRIGGER trg_pedidos_updated_at
            BEFORE UPDATE ON pedidos_compra
            FOR EACH ROW EXECUTE FUNCTION atualizar_updated_at();
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'trg_cotacoes_updated_at'
    ) THEN
        CREATE TRIGGER trg_cotacoes_updated_at
            BEFORE UPDATE ON cotacoes
            FOR EACH ROW EXECUTE FUNCTION atualizar_updated_at();
    END IF;
END
$$;

-- ------------------------------------------------------------
-- ÍNDICES
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_pedidos_status      ON pedidos_compra(status);
CREATE INDEX IF NOT EXISTS idx_pedidos_solicitante ON pedidos_compra(solicitante_id);
CREATE INDEX IF NOT EXISTS idx_pedidos_numero      ON pedidos_compra(numero);
CREATE INDEX IF NOT EXISTS idx_cotacoes_pedido     ON cotacoes(pedido_id);
CREATE INDEX IF NOT EXISTS idx_historico_pedido    ON historico_pedido(pedido_id);
CREATE INDEX IF NOT EXISTS idx_itens_pedido        ON itens_pedido(pedido_id);

-- ------------------------------------------------------------
-- VIEW: pedidos com totais e nome do solicitante
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW pedidos_completo AS
SELECT
    p.*,
    u.nome                          AS solicitante_nome,
    d.nome                          AS departamento_nome,
    ap.nome                         AS aprovador_nome,
    cf.nome                         AS categoria_nome,
    cc.nome                         AS centro_custo_nome,
    COALESCE(
        (SELECT COUNT(*) FROM cotacoes c WHERE c.pedido_id = p.id), 0
    )                               AS total_cotacoes,
    COALESCE(
        (SELECT COUNT(*) FROM cotacoes c WHERE c.pedido_id = p.id AND c.status = 'selecionada'), 0
    )                               AS cotacao_selecionada,
    COALESCE(
        (SELECT SUM(ip.quantidade * ip.valor_unitario_estimado) FROM itens_pedido ip WHERE ip.pedido_id = p.id), 0
    )                               AS valor_total_estimado
FROM pedidos_compra p
LEFT JOIN usuarios u            ON u.id = p.solicitante_id
LEFT JOIN departamentos d       ON d.id = p.departamento_id
LEFT JOIN usuarios ap           ON ap.id = p.aprovador_id
LEFT JOIN categorias_financeiras cf ON cf.id = p.categoria_financeira_id
LEFT JOIN centros_custo cc      ON cc.id = p.centro_custo_id;

-- ------------------------------------------------------------
-- DADOS INICIAIS — FORNECEDORES PADRÃO
-- ------------------------------------------------------------
INSERT INTO fornecedores (nome, cnpj, contato, email, telefone, categoria) VALUES
    ('SportMax Equipamentos',   '11.222.333/0001-44', 'Carlos Lima',     'vendas@sportmax.com.br',  '(11) 3000-1111', 'Material Esportivo'),
    ('Nutrição Total',          '22.333.444/0001-55', 'Ana Paula',       'ana@nutricaototal.com',   '(11) 9999-2222', 'Alimentação'),
    ('MedSport Clínica',        '33.444.555/0001-66', 'Dr. Roberto',     'contato@medsport.com.br', '(11) 3500-3333', 'Saúde e Medicina'),
    ('TechField Sistemas',      '44.555.666/0001-77', 'Felipe Tech',     'felipe@techfield.com',    '(11) 9888-4444', 'Teonologia'),
    ('TransportesFut Ltda',     '55.666.777/0001-88', 'João Motorista', 'joao@transfut.com',       '(11) 9777-5555', 'Transporte'),
    ('Gráfica Campeão',         '66.777.888/0001-99', 'Marcos Gráfico', 'orcamento@grafica.com',   '(11) 3200-6666', 'Marketing'),
    ('Hotel Central',           '77.888.999/0001-00', 'Recepção',       'eventos@hotelcentral.com','(11) 3100-7777', 'Hospedagem'),
    ('Manutenção Expert',      '88.999.000/0001-11', 'Paulo Expert',    'paulo@manutencao.com',    '(11) 9666-8888', 'Manutenção')
ON CONFLICT DO NOTHING;
