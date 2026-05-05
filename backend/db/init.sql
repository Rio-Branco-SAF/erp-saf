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
$$ LANGUAGE plpgsql;

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
  TO_CHAR(data_competencia, 'YYYY-MM')          AS mes,
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
    ('SportMax Equipamentos',   '11.222.333/0001-44', 'Carlos Lima',    'vendas@sportmax.com.br',  '(11) 3000-1111', 'Material Esportivo'),
    ('Nutrição Total',          '22.333.444/0001-55', 'Ana Paula',      'ana@nutricaototal.com',   '(11) 9999-2222', 'Alimentação'),
    ('MedSport Clínica',        '33.444.555/0001-66', 'Dr. Roberto',    'contato@medsport.com.br', '(11) 3500-3333', 'Saúde e Medicina'),
    ('TechField Sistemas',      '44.555.666/0001-77', 'Felipe Tech',    'felipe@techfield.com',    '(11) 9888-4444', 'Tecnologia'),
    ('TransportesFut Ltda',     '55.666.777/0001-88', 'João Motorista', 'joao@transfut.com',       '(11) 9777-5555', 'Transporte'),
    ('Gráfica Campeão',         '66.777.888/0001-99', 'Marcos Gráfico', 'orcamento@grafica.com',   '(11) 3200-6666', 'Marketing'),
    ('Hotel Central',           '77.888.999/0001-00', 'Recepção',       'eventos@hotelcentral.com','(11) 3100-7777', 'Hospedagem'),
    ('Manutenção Expert',       '88.999.000/0001-11', 'Paulo Expert',   'paulo@manutencao.com',    '(11) 9666-8888', 'Manutenção')
ON CONFLICT DO NOTHING;
-- ============================================================
-- MÓDULO 4: ATLETAS
-- ERP SAF — Schema do Banco de Dados
-- ============================================================

-- ------------------------------------------------------------
-- ATLETAS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS atletas (
    id                  SERIAL PRIMARY KEY,
    nome                VARCHAR(200) NOT NULL,
    nome_guerra         VARCHAR(80),            -- nome em campo (ex: "Ronaldinho")
    foto_url            VARCHAR(300),

    -- Documentos pessoais
    cpf                 VARCHAR(14),
    rg                  VARCHAR(20),
    passaporte          VARCHAR(30),
    data_nascimento     DATE,
    nacionalidade       VARCHAR(80) DEFAULT 'Brasileira',
    naturalidade        VARCHAR(100),           -- cidade/estado de origem

    -- Dados físicos
    posicao             VARCHAR(30) NOT NULL
                        CHECK (posicao IN (
                            'goleiro','lateral_direito','lateral_esquerdo',
                            'zagueiro','volante','meia_central',
                            'meia_atacante','ponta_direita','ponta_esquerda',
                            'centroavante'
                        )),
    pe_dominante        VARCHAR(10) DEFAULT 'direito'
                        CHECK (pe_dominante IN ('direito','esquerdo','ambidestro')),
    altura_cm           INTEGER,                -- ex: 182
    peso_kg             NUMERIC(5,2),           -- ex: 78.5

    -- Status
    status              VARCHAR(20) NOT NULL DEFAULT 'ativo'
                        CHECK (status IN ('ativo','lesionado','emprestado','suspenso','inativo')),

    -- Clube origem / formação
    clube_formacao      VARCHAR(100),
    agente              VARCHAR(150),           -- representante / agente

    observacoes         TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- CONTRATOS DE ATLETAS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS contratos_atleta (
    id                      SERIAL PRIMARY KEY,
    atleta_id               INTEGER NOT NULL REFERENCES atletas(id) ON DELETE CASCADE,
    numero_contrato         VARCHAR(50),

    tipo                    VARCHAR(20) NOT NULL DEFAULT 'profissional'
                            CHECK (tipo IN ('profissional','amador','emprestimo','formacao')),

    -- Vigência
    data_inicio             DATE NOT NULL,
    data_fim                DATE NOT NULL,

    -- Remuneração
    salario_bruto           NUMERIC(12,2) NOT NULL,     -- salário total combinado
    salario_carteira        NUMERIC(12,2),              -- valor registrado na CTPS (CLT)
    direitos_imagem         NUMERIC(12,2) DEFAULT 0,    -- parcela de imagem (PJ)
    luvas                   NUMERIC(12,2) DEFAULT 0,    -- bônus de assinatura
    clausula_rescisoria     NUMERIC(12,2),              -- multa rescisória

    -- Status do contrato
    status                  VARCHAR(20) NOT NULL DEFAULT 'ativo'
                            CHECK (status IN ('ativo','encerrado','rescindido','suspenso')),

    -- Se empréstimo
    clube_cedente           VARCHAR(150),               -- clube que cedeu o atleta
    clube_cessionario       VARCHAR(150),               -- clube que recebeu (se cedemos)

    motivo_encerramento     TEXT,
    observacoes             TEXT,
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- METAS / BONIFICAÇÕES POR DESEMPENHO (por contrato)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS metas_contrato (
    id                  SERIAL PRIMARY KEY,
    contrato_id         INTEGER NOT NULL REFERENCES contratos_atleta(id) ON DELETE CASCADE,

    tipo                VARCHAR(30) NOT NULL
                        CHECK (tipo IN (
                            'gol',
                            'assistencia',
                            'jogo_disputado',
                            'jogo_titular',
                            'jogo_sem_sofrer_gol',
                            'cartao_amarelo',       -- desconto por advertência
                            'cartao_vermelho',      -- desconto por expulsão
                            'classificacao',        -- bônus se o clube subir/ganhar
                            'artilharia',           -- bônus de artilheiro
                            'titulos',              -- título conquistado
                            'custom'                -- meta personalizada
                        )),

    descricao           VARCHAR(300) NOT NULL,          -- ex: "Bônus por gol marcado"

    -- Gatilho
    meta_quantidade     INTEGER DEFAULT 1,              -- a cada quantas unidades paga
                                                        -- ex: 1 = a cada gol; 5 = a cada 5 jogos

    -- Valor do bônus
    valor_bonus         NUMERIC(12,2) NOT NULL,         -- R$ por ocorrência
    tipo_calculo        VARCHAR(20) DEFAULT 'por_unidade'
                        CHECK (tipo_calculo IN (
                            'por_unidade',              -- R$ X a cada meta_quantidade unidades
                            'total_periodo',            -- R$ X se atingir total no período
                            'percentual_salario'        -- % do salário bruto
                        )),

    -- Competição aplicável (NULL = todas)
    competicao          VARCHAR(100),                   -- ex: "Série B", "Copa do Brasil"

    ativo               BOOLEAN DEFAULT TRUE,
    observacoes         TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- ESTATÍSTICAS DO ATLETA (por temporada e competição)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS estatisticas_atleta (
    id                      SERIAL PRIMARY KEY,
    atleta_id               INTEGER NOT NULL REFERENCES atletas(id) ON DELETE CASCADE,
    temporada               VARCHAR(10) NOT NULL,       -- ex: "2026", "2025/2026"
    competicao              VARCHAR(100) NOT NULL,      -- ex: "Série B", "Copa do Brasil"

    -- Participação
    jogos_disputados        INTEGER DEFAULT 0,
    jogos_titular           INTEGER DEFAULT 0,
    minutos_jogados         INTEGER DEFAULT 0,

    -- Ofensivos
    gols                    INTEGER DEFAULT 0,
    assistencias            INTEGER DEFAULT 0,
    chutes_a_gol            INTEGER DEFAULT 0,

    -- Defensivos / Goleiro
    jogos_sem_sofrer_gol    INTEGER DEFAULT 0,          -- clean sheets
    defesas_dificeis        INTEGER DEFAULT 0,          -- para goleiros
    interceptacoes          INTEGER DEFAULT 0,

    -- Disciplina
    cartoes_amarelos        INTEGER DEFAULT 0,
    cartoes_vermelhos       INTEGER DEFAULT 0,
    faltas_cometidas        INTEGER DEFAULT 0,

    created_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(atleta_id, temporada, competicao)
);

-- ------------------------------------------------------------
-- BONIFICAÇÕES PAGAS / PENDENTES
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS bonificacoes_atleta (
    id              SERIAL PRIMARY KEY,
    atleta_id       INTEGER NOT NULL REFERENCES atletas(id) ON DELETE CASCADE,
    contrato_id     INTEGER REFERENCES contratos_atleta(id),
    meta_id         INTEGER REFERENCES metas_contrato(id),

    competencia     DATE NOT NULL,              -- mês de competência (1º dia do mês)
    descricao       VARCHAR(300) NOT NULL,
    valor           NUMERIC(12,2) NOT NULL,
    tipo            VARCHAR(10) NOT NULL DEFAULT 'bonus'
                    CHECK (tipo IN ('bonus','desconto')),  -- bônus ou desconto (cartão)
    status          VARCHAR(20) NOT NULL DEFAULT 'pendente'
                    CHECK (status IN ('pendente','pago','cancelado')),

    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- HISTÓRICO DE SALÁRIO DO ATLETA
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS historico_salario_atleta (
    id              SERIAL PRIMARY KEY,
    atleta_id       INTEGER NOT NULL REFERENCES atletas(id) ON DELETE CASCADE,
    contrato_id     INTEGER REFERENCES contratos_atleta(id),
    data_alteracao  DATE NOT NULL DEFAULT CURRENT_DATE,
    salario_anterior NUMERIC(12,2),
    salario_novo    NUMERIC(12,2) NOT NULL,
    motivo          VARCHAR(200),               -- ex: "Renovação contratual", "Promoção", "14 jogos completados"
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- TRIGGERS — updated_at automático
-- ------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_atletas_updated_at') THEN
        CREATE TRIGGER trg_atletas_updated_at
            BEFORE UPDATE ON atletas
            FOR EACH ROW EXECUTE FUNCTION atualizar_updated_at();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_contratos_atleta_updated_at') THEN
        CREATE TRIGGER trg_contratos_atleta_updated_at
            BEFORE UPDATE ON contratos_atleta
            FOR EACH ROW EXECUTE FUNCTION atualizar_updated_at();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_estatisticas_updated_at') THEN
        CREATE TRIGGER trg_estatisticas_updated_at
            BEFORE UPDATE ON estatisticas_atleta
            FOR EACH ROW EXECUTE FUNCTION atualizar_updated_at();
    END IF;
END
$$;

-- ------------------------------------------------------------
-- ÍNDICES
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_atletas_status     ON atletas(status);
CREATE INDEX IF NOT EXISTS idx_atletas_posicao    ON atletas(posicao);
CREATE INDEX IF NOT EXISTS idx_contratos_atleta   ON contratos_atleta(atleta_id);
CREATE INDEX IF NOT EXISTS idx_contratos_status   ON contratos_atleta(status);
CREATE INDEX IF NOT EXISTS idx_stats_atleta       ON estatisticas_atleta(atleta_id, temporada);
CREATE INDEX IF NOT EXISTS idx_bonus_atleta       ON bonificacoes_atleta(atleta_id, competencia);
CREATE INDEX IF NOT EXISTS idx_metas_contrato     ON metas_contrato(contrato_id);

-- ------------------------------------------------------------
-- VIEW: atletas com contrato ativo e totais de stats 2026
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW atletas_completo AS
SELECT
    a.*,
    -- Contrato ativo
    c.id                    AS contrato_id,
    c.tipo                  AS contrato_tipo,
    c.data_inicio           AS contrato_inicio,
    c.data_fim              AS contrato_fim,
    c.salario_bruto,
    c.salario_carteira,
    c.direitos_imagem,
    c.clausula_rescisoria,
    c.clube_cedente,
    -- Dias até vencimento
    (c.data_fim - CURRENT_DATE) AS dias_ate_vencimento,
    -- Estatísticas acumuladas (todas as competições na temporada atual)
    COALESCE((
        SELECT SUM(e.jogos_disputados) FROM estatisticas_atleta e
        WHERE e.atleta_id = a.id AND e.temporada = TO_CHAR(NOW(),'YYYY')
    ), 0) AS total_jogos,
    COALESCE((
        SELECT SUM(e.gols) FROM estatisticas_atleta e
        WHERE e.atleta_id = a.id AND e.temporada = TO_CHAR(NOW(),'YYYY')
    ), 0) AS total_gols,
    COALESCE((
        SELECT SUM(e.assistencias) FROM estatisticas_atleta e
        WHERE e.atleta_id = a.id AND e.temporada = TO_CHAR(NOW(),'YYYY')
    ), 0) AS total_assistencias,
    COALESCE((
        SELECT SUM(e.jogos_sem_sofrer_gol) FROM estatisticas_atleta e
        WHERE e.atleta_id = a.id AND e.temporada = TO_CHAR(NOW(),'YYYY')
    ), 0) AS total_clean_sheets,
    COALESCE((
        SELECT SUM(e.cartoes_amarelos) FROM estatisticas_atleta e
        WHERE e.atleta_id = a.id AND e.temporada = TO_CHAR(NOW(),'YYYY')
    ), 0) AS total_amarelos,
    COALESCE((
        SELECT SUM(e.cartoes_vermelhos) FROM estatisticas_atleta e
        WHERE e.atleta_id = a.id AND e.temporada = TO_CHAR(NOW(),'YYYY')
    ), 0) AS total_vermelhos
FROM atletas a
LEFT JOIN contratos_atleta c
    ON c.atleta_id = a.id AND c.status = 'ativo';
-- ============================================================
-- MÓDULO 5: INVESTIDORES E APORTES
-- ERP SAF — Schema do Banco de Dados
-- ============================================================

-- ------------------------------------------------------------
-- INVESTIDORES
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS investidores (
    id              SERIAL PRIMARY KEY,
    nome            VARCHAR(200) NOT NULL,
    tipo            VARCHAR(20) NOT NULL DEFAULT 'pessoa_fisica'
                    CHECK (tipo IN ('pessoa_fisica','pessoa_juridica')),

    -- Documentos
    cpf_cnpj        VARCHAR(18),
    rg              VARCHAR(20),

    -- Perfil de investimento
    perfil          VARCHAR(30) NOT NULL DEFAULT 'investidor'
                    CHECK (perfil IN (
                        'socio',              -- sócio com participação acionária
                        'patrocinador',       -- patrocinador (visibilidade/marketing)
                        'investidor',         -- investidor financeiro (retorno esperado)
                        'mecenatismo'         -- mecenas / doador (sem retorno esperado)
                    )),

    -- Contato
    email           VARCHAR(150),
    telefone        VARCHAR(20),
    endereco        TEXT,

    -- Pessoa jurídica
    nome_fantasia   VARCHAR(150),        -- nome da empresa (se PJ)
    responsavel     VARCHAR(150),        -- nome do responsável na empresa

    -- Participação acionária total acumulada
    percentual_participacao NUMERIC(6,3) DEFAULT 0, -- % do clube (até 49.9% possível)

    ativo           BOOLEAN DEFAULT TRUE,
    observacoes     TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- APORTES (investimentos / patrocínios / empréstimos)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS aportes (
    id              SERIAL PRIMARY KEY,
    investidor_id   INTEGER NOT NULL REFERENCES investidores(id) ON DELETE CASCADE,

    tipo            VARCHAR(25) NOT NULL
                    CHECK (tipo IN (
                        'aporte_capital',   -- entrada de capital (equity)
                        'patrocinio',       -- patrocínio (custeio sem retorno financeiro)
                        'emprestimo',       -- empréstimo (deve ser devolvido + juros)
                        'doacao'            -- doação sem retorno
                    )),

    descricao       VARCHAR(300) NOT NULL,
    valor           NUMERIC(14,2) NOT NULL CHECK (valor > 0),

    data_aporte     DATE NOT NULL DEFAULT CURRENT_DATE,
    competencia     DATE,                -- mês de competência contábil

    -- Para aportes de capital: equity concedido
    percentual_concedido NUMERIC(6,3) DEFAULT 0,   -- % do clube concedido neste aporte

    -- Para empréstimos
    taxa_juros_anual    NUMERIC(5,2),              -- ex: 12.00 = 12% a.a.
    data_vencimento     DATE,                       -- prazo para devolução
    valor_devolvido     NUMERIC(14,2) DEFAULT 0,   -- quanto já foi pago de volta

    -- Para patrocínios: o que o patrocinador recebe em troca
    contrapartida       TEXT,                       -- ex: "Camisa + banner estádio"

    status          VARCHAR(20) NOT NULL DEFAULT 'confirmado'
                    CHECK (status IN ('pendente','confirmado','cancelado')),

    comprovante     VARCHAR(300),                   -- nome do arquivo
    observacoes     TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- RETORNOS AOS INVESTIDORES (dividendos, juros, devoluções)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS retornos_investidor (
    id              SERIAL PRIMARY KEY,
    investidor_id   INTEGER NOT NULL REFERENCES investidores(id) ON DELETE CASCADE,
    aporte_id       INTEGER REFERENCES aportes(id),

    tipo            VARCHAR(20) NOT NULL
                    CHECK (tipo IN (
                        'dividendo',        -- distribuição de lucro
                        'juros',            -- juros de empréstimo
                        'devolucao',        -- devolução de capital
                        'bonificacao'       -- bonificação extra
                    )),

    descricao       VARCHAR(300) NOT NULL,
    valor           NUMERIC(14,2) NOT NULL CHECK (valor > 0),
    data_pagamento  DATE NOT NULL,
    competencia     DATE,

    status          VARCHAR(20) NOT NULL DEFAULT 'pendente'
                    CHECK (status IN ('pendente','pago','cancelado')),

    observacoes     TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- DOCUMENTOS DO INVESTIDOR
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS documentos_investidor (
    id              SERIAL PRIMARY KEY,
    investidor_id   INTEGER NOT NULL REFERENCES investidores(id) ON DELETE CASCADE,
    nome            VARCHAR(200) NOT NULL,
    tipo            VARCHAR(50),          -- ex: "Contrato", "Comprovante", "NDA"
    arquivo         VARCHAR(300),
    observacoes     TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- TRIGGER updated_at
-- ------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_investidores_updated_at') THEN
        CREATE TRIGGER trg_investidores_updated_at
            BEFORE UPDATE ON investidores
            FOR EACH ROW EXECUTE FUNCTION atualizar_updated_at();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_aportes_updated_at') THEN
        CREATE TRIGGER trg_aportes_updated_at
            BEFORE UPDATE ON aportes
            FOR EACH ROW EXECUTE FUNCTION atualizar_updated_at();
    END IF;
END
$$;

-- ------------------------------------------------------------
-- ÍNDICES
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_aportes_investidor  ON aportes(investidor_id);
CREATE INDEX IF NOT EXISTS idx_aportes_data        ON aportes(data_aporte DESC);
CREATE INDEX IF NOT EXISTS idx_retornos_investidor ON retornos_investidor(investidor_id);
CREATE INDEX IF NOT EXISTS idx_retornos_status     ON retornos_investidor(status);

-- ------------------------------------------------------------
-- VIEW: investidores com totais calculados
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW investidores_completo AS
SELECT
    i.*,
    -- Totais de aportes
    COALESCE((SELECT SUM(a.valor) FROM aportes a WHERE a.investidor_id = i.id AND a.status = 'confirmado'), 0)
        AS total_aportado,
    COALESCE((SELECT SUM(a.valor) FROM aportes a WHERE a.investidor_id = i.id AND a.tipo = 'patrocinio' AND a.status = 'confirmado'), 0)
        AS total_patrocinio,
    COALESCE((SELECT SUM(a.valor) FROM aportes a WHERE a.investidor_id = i.id AND a.tipo = 'emprestimo' AND a.status = 'confirmado'), 0)
        AS total_emprestado,
    -- Dívida de empréstimos
    COALESCE((SELECT SUM(a.valor - COALESCE(a.valor_devolvido,0)) FROM aportes a WHERE a.investidor_id = i.id AND a.tipo = 'emprestimo' AND a.status = 'confirmado'), 0)
        AS saldo_devedor,
    -- Retornos
    COALESCE((SELECT SUM(r.valor) FROM retornos_investidor r WHERE r.investidor_id = i.id AND r.status = 'pago'), 0)
        AS total_retornado,
    COALESCE((SELECT SUM(r.valor) FROM retornos_investidor r WHERE r.investidor_id = i.id AND r.status = 'pendente'), 0)
        AS retorno_pendente,
    -- Contagem de aportes
    (SELECT COUNT(*) FROM aportes a WHERE a.investidor_id = i.id AND a.status = 'confirmado')
        AS qtd_aportes
FROM investidores i;
-- ============================================================
-- MÓDULO 6: METAS ESPORTIVAS E FINANCEIRAS
-- ERP SAF — Schema do Banco de Dados
-- ============================================================

-- ------------------------------------------------------------
-- METAS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS metas (
    id              SERIAL PRIMARY KEY,
    titulo          VARCHAR(200) NOT NULL,
    descricao       TEXT,

    -- Classificação da meta
    tipo            VARCHAR(20) NOT NULL
                    CHECK (tipo IN ('esportiva','financeira','institucional')),

    categoria       VARCHAR(40) NOT NULL
                    CHECK (categoria IN (
                        -- Esportivas
                        'classificacao',        -- posição na tabela / acesso
                        'pontuacao',            -- pontos no campeonato
                        'vitorias',             -- número de vitórias
                        'gols_marcados',        -- gols da equipe
                        'gols_sofridos',        -- gols sofridos (meta: abaixo de X)
                        'clean_sheets',         -- jogos sem tomar gol
                        'aproveitamento',       -- % de aproveitamento
                        'artilheiro',           -- artilheiro individual
                        'titulo',               -- conquista de título
                        -- Financeiras
                        'receita',              -- meta de receita total
                        'reducao_custos',       -- reduzir custos em X%
                        'patrocinio',           -- captação de patrocínio
                        'folha_limite',         -- folha dentro do orçamento
                        'lucro',                -- lucro líquido
                        'captacao',             -- captação de investimento
                        -- Institucionais
                        'formacao',             -- revelar X atletas da base
                        'publico',              -- média de público
                        'custom'                -- personalizada
                    )),

    temporada       VARCHAR(10) NOT NULL DEFAULT '2026',

    -- Valores de referência
    valor_meta      NUMERIC(14,2) NOT NULL,         -- alvo a atingir (ex: 60 pontos, R$500k)
    valor_atual     NUMERIC(14,2) NOT NULL DEFAULT 0, -- progresso atual
    unidade         VARCHAR(30) DEFAULT '',          -- ex: 'pontos', 'gols', 'R$', '%', 'vitórias'

    -- Para metas do tipo "abaixo de X" (ex: gols sofridos, custos)
    sentido         VARCHAR(10) DEFAULT 'acima'
                    CHECK (sentido IN ('acima','abaixo')),   -- acima = quanto maior melhor

    -- Datas
    data_inicio     DATE NOT NULL DEFAULT CURRENT_DATE,
    data_fim        DATE NOT NULL,

    -- Status
    status          VARCHAR(20) NOT NULL DEFAULT 'ativa'
                    CHECK (status IN ('ativa','concluida','nao_atingida','cancelada')),

    prioridade      VARCHAR(10) NOT NULL DEFAULT 'media'
                    CHECK (prioridade IN ('alta','media','baixa')),

    -- Responsável
    responsavel_id  INTEGER REFERENCES usuarios(id),

    -- Vínculo com outros módulos
    atleta_id       INTEGER REFERENCES atletas(id),   -- meta individual de atleta
    contrato_id     INTEGER REFERENCES contratos_atleta(id), -- meta de contrato

    observacoes     TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- ATUALIZAÇÕES DE PROGRESSO
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS atualizacoes_meta (
    id              SERIAL PRIMARY KEY,
    meta_id         INTEGER NOT NULL REFERENCES metas(id) ON DELETE CASCADE,
    usuario_id      INTEGER REFERENCES usuarios(id),
    valor_anterior  NUMERIC(14,2),
    valor_novo      NUMERIC(14,2) NOT NULL,
    descricao       TEXT,              -- ex: "Rodada 10 — vitória 2x0"
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- TRIGGER updated_at
-- ------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_metas_updated_at') THEN
        CREATE TRIGGER trg_metas_updated_at
            BEFORE UPDATE ON metas
            FOR EACH ROW EXECUTE FUNCTION atualizar_updated_at();
    END IF;
END
$$;

-- ------------------------------------------------------------
-- ÍNDICES
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_metas_tipo      ON metas(tipo);
CREATE INDEX IF NOT EXISTS idx_metas_status    ON metas(status);
CREATE INDEX IF NOT EXISTS idx_metas_temporada ON metas(temporada);
CREATE INDEX IF NOT EXISTS idx_atualizacoes    ON atualizacoes_meta(meta_id);

-- ------------------------------------------------------------
-- VIEW: metas com progresso calculado
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW metas_completo AS
SELECT
    m.*,
    u.nome AS responsavel_nome,
    a.nome AS atleta_nome,
    a.nome_guerra AS atleta_guerra,
    -- Percentual de progresso
    CASE
        WHEN m.valor_meta = 0 THEN 0
        WHEN m.sentido = 'abaixo' THEN
            GREATEST(0, LEAST(100, ROUND((1 - (m.valor_atual / m.valor_meta)) * 100)))
        ELSE
            LEAST(100, ROUND((m.valor_atual / m.valor_meta) * 100))
    END AS percentual,
    -- Dias restantes
    (m.data_fim - CURRENT_DATE) AS dias_restantes
FROM metas m
LEFT JOIN usuarios u ON u.id = m.responsavel_id
LEFT JOIN atletas  a ON a.id = m.atleta_id;
-- ============================================================
-- MÓDULO 7 — RELATÓRIOS GERENCIAIS
-- Schema: tabela de logs + views consolidadas cross-módulo
-- ============================================================

-- Log de relatórios gerados
CREATE TABLE IF NOT EXISTS relatorios_gerados (
    id          SERIAL PRIMARY KEY,
    tipo        VARCHAR(60) NOT NULL,  -- financeiro, folha, esportivo, investidores, compras, executivo
    periodo_ini DATE,
    periodo_fim DATE,
    gerado_por  INTEGER REFERENCES usuarios(id),
    parametros  JSONB,
    created_at  TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- VIEW: Resumo Executivo Consolidado
-- ============================================================
CREATE OR REPLACE VIEW vw_resumo_executivo AS
SELECT
    -- Financeiro
    (SELECT COALESCE(SUM(valor),0) FROM transacoes WHERE tipo='receita'  AND DATE_TRUNC('month', data_transacao) = DATE_TRUNC('month', CURRENT_DATE)) AS receita_mes,
    (SELECT COALESCE(SUM(valor),0) FROM transacoes WHERE tipo='despesa'  AND DATE_TRUNC('month', data_transacao) = DATE_TRUNC('month', CURRENT_DATE)) AS despesa_mes,
    (SELECT COALESCE(SUM(valor),0) FROM transacoes WHERE tipo='receita'  AND EXTRACT(YEAR FROM data_transacao) = EXTRACT(YEAR FROM CURRENT_DATE)) AS receita_ano,
    (SELECT COALESCE(SUM(valor),0) FROM transacoes WHERE tipo='despesa'  AND EXTRACT(YEAR FROM data_transacao) = EXTRACT(YEAR FROM CURRENT_DATE)) AS despesa_ano,

    -- Folha (atletas + funcionários)
    (SELECT COALESCE(SUM(salario_bruto),0)       FROM contratos_atleta  WHERE status='ativo') AS folha_atletas,
    (SELECT COALESCE(SUM(salario_base),0)         FROM funcionarios      WHERE status='ativo') AS folha_funcionarios,

    -- Atletas
    (SELECT COUNT(*) FROM atletas WHERE status='ativo')                          AS atletas_ativos,
    (SELECT COUNT(*) FROM contratos_atleta WHERE status='ativo'
        AND data_fim BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '90 days') AS contratos_vencendo,

    -- Investidores
    (SELECT COALESCE(SUM(valor),0) FROM aportes WHERE tipo='aporte_capital')     AS total_capital_investido,
    (SELECT COALESCE(SUM(valor),0) FROM aportes WHERE tipo='emprestimo'
        AND (valor - COALESCE(valor_devolvido,0)) > 0)                           AS saldo_devedor_emprestimos,

    -- Pedidos
    (SELECT COUNT(*) FROM pedidos_compra WHERE status NOT IN ('concluido','cancelado')) AS pedidos_abertos,
    (SELECT COALESCE(SUM(valor_total_estimado),0) FROM pedidos_completo
        WHERE status NOT IN ('concluido','cancelado'))                            AS valor_pedidos_abertos,

    -- Metas
    (SELECT COUNT(*) FROM metas WHERE status='ativa')                            AS metas_ativas,
    (SELECT ROUND(AVG(percentual))  FROM metas_completo WHERE status='ativa')    AS progresso_medio_metas,
    (SELECT COUNT(*) FROM metas_completo WHERE status='ativa' AND percentual < 30
        AND dias_restantes < 30)                                                  AS metas_criticas;

-- ============================================================
-- VIEW: Evolução Financeira Mensal (últimos 12 meses)
-- ============================================================
CREATE OR REPLACE VIEW vw_evolucao_financeira AS
SELECT
    TO_CHAR(DATE_TRUNC('month', data_transacao), 'YYYY-MM') AS mes,
    TO_CHAR(DATE_TRUNC('month', data_transacao), 'Mon/YY')  AS mes_label,
    SUM(CASE WHEN tipo='receita' THEN valor ELSE 0 END)     AS receita,
    SUM(CASE WHEN tipo='despesa' THEN valor ELSE 0 END)     AS despesa,
    SUM(CASE WHEN tipo='receita' THEN valor ELSE 0 END)
  - SUM(CASE WHEN tipo='despesa' THEN valor ELSE 0 END)     AS resultado
FROM transacoes
WHERE data_transacao >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', data_transacao)
ORDER BY DATE_TRUNC('month', data_transacao);

-- ============================================================
-- VIEW: Folha Consolidada (atletas + funcionários)
-- ============================================================
CREATE OR REPLACE VIEW vw_folha_consolidada AS
SELECT
    'atleta'                                AS categoria,
    a.id                                    AS pessoa_id,
    a.nome,
    a.posicao                               AS cargo_posicao,
    ca.salario_bruto                        AS salario_bruto,
    ca.salario_carteira                     AS salario_carteira,
    ca.direitos_imagem                      AS complemento,
    ca.data_fim                             AS contrato_ate,
    a.status
FROM atletas a
JOIN contratos_atleta ca ON ca.id = (
    SELECT id FROM contratos_atleta
    WHERE atleta_id = a.id AND status = 'ativo'
    LIMIT 1
)
WHERE a.status = 'ativo'

UNION ALL

SELECT
    'funcionario'                           AS categoria,
    f.id                                    AS pessoa_id,
    f.nome,
    f.cargo                                 AS cargo_posicao,
    f.salario_base                          AS salario_bruto,
    f.salario_base                          AS salario_carteira,
    0                                       AS complemento,
    NULL                                    AS contrato_ate,
    f.status
FROM funcionarios f
WHERE f.status = 'ativo'

ORDER BY categoria, salario_bruto DESC;

-- ============================================================
-- VIEW: Ranking de Fornecedores (por volume de pedidos)
-- ============================================================
CREATE OR REPLACE VIEW vw_ranking_fornecedores AS
SELECT
    f.id,
    f.nome,
    f.categoria,
    COUNT(pc.id)                            AS total_pedidos,
    COUNT(CASE WHEN pc.status='concluido' THEN 1 END) AS pedidos_concluidos,
    COALESCE(SUM(co.valor_total), 0)        AS volume_total
FROM fornecedores f
LEFT JOIN pedidos_compra pc ON pc.fornecedor_id = f.id
LEFT JOIN cotacoes co ON co.pedido_id = pc.id AND co.selecionada = TRUE
GROUP BY f.id, f.nome, f.categoria
ORDER BY volume_total DESC;

-- ============================================================
-- VIEW: Performance Esportiva por Competição
-- ============================================================
CREATE OR REPLACE VIEW vw_performance_esportiva AS
SELECT
    ea.competicao,
    ea.temporada,
    COUNT(DISTINCT ea.atleta_id)            AS atletas,
    SUM(ea.jogos)                           AS total_jogos,
    SUM(ea.gols)                            AS total_gols,
    SUM(ea.assistencias)                    AS total_assistencias,
    SUM(ea.clean_sheets)                    AS total_clean_sheets,
    SUM(ea.cartoes_amarelos)                AS total_amarelos,
    SUM(ea.cartoes_vermelhos)               AS total_vermelhos,
    CASE WHEN SUM(ea.jogos) > 0
        THEN ROUND(SUM(ea.gols)::NUMERIC / SUM(ea.jogos), 2)
        ELSE 0
    END                                     AS media_gols_jogo
FROM estatisticas_atleta ea
GROUP BY ea.competicao, ea.temporada
ORDER BY ea.temporada DESC, total_jogos DESC;

-- ============================================================
-- VIEW: Artilharia Geral
-- ============================================================
CREATE OR REPLACE VIEW vw_artilharia AS
SELECT
    a.id,
    a.nome,
    a.posicao,
    SUM(ea.gols)                            AS total_gols,
    SUM(ea.assistencias)                    AS total_assistencias,
    SUM(ea.jogos)                           AS total_jogos,
    SUM(ea.clean_sheets)                    AS total_clean_sheets,
    CASE WHEN SUM(ea.jogos) > 0
        THEN ROUND(SUM(ea.gols)::NUMERIC / SUM(ea.jogos), 2)
        ELSE 0
    END                                     AS media_gols
FROM atletas a
JOIN estatisticas_atleta ea ON ea.atleta_id = a.id
WHERE EXTRACT(YEAR FROM CURRENT_DATE)::TEXT = ea.temporada
GROUP BY a.id, a.nome, a.posicao
ORDER BY total_gols DESC, total_assistencias DESC;
-- ============================================================
-- MÓDULO 8 — AGENDA DE JOGOS
-- Schema: jogos, orçamentos automáticos, público e receitas
-- ============================================================

-- ─── Templates de orçamento (base automática por tipo) ────────
CREATE TABLE IF NOT EXISTS templates_orcamento_jogo (
    id          SERIAL PRIMARY KEY,
    nome        VARCHAR(100) NOT NULL,
    tipo_jogo   VARCHAR(20) NOT NULL CHECK (tipo_jogo IN ('mandante','visitante','neutro')),
    competicao  VARCHAR(60),          -- NULL = válido para qualquer competição
    ativo       BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS itens_template_orcamento (
    id              SERIAL PRIMARY KEY,
    template_id     INTEGER NOT NULL REFERENCES templates_orcamento_jogo(id) ON DELETE CASCADE,
    categoria       VARCHAR(60) NOT NULL,
    descricao       VARCHAR(150) NOT NULL,
    valor_padrao    NUMERIC(12,2) NOT NULL DEFAULT 0,
    obrigatorio     BOOLEAN DEFAULT TRUE,
    ordem           INTEGER DEFAULT 0
);

-- ─── Jogos ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS jogos (
    id              SERIAL PRIMARY KEY,
    competicao      VARCHAR(80) NOT NULL,
    rodada          VARCHAR(40),                  -- "Rodada 12", "Oitavas de Final", etc.
    adversario      VARCHAR(100) NOT NULL,
    data_jogo       TIMESTAMP NOT NULL,
    local_jogo      VARCHAR(150),
    tipo_jogo       VARCHAR(20) NOT NULL CHECK (tipo_jogo IN ('mandante','visitante','neutro')),
    status          VARCHAR(20) NOT NULL DEFAULT 'agendado'
                    CHECK (status IN ('agendado','confirmado','realizado','cancelado','adiado')),

    -- Resultado
    gols_nos        INTEGER,
    gols_adversario INTEGER,

    -- Público
    capacidade_estadio  INTEGER,
    publico_pagante     INTEGER,
    publico_cortesias   INTEGER,
    publico_total       INTEGER GENERATED ALWAYS AS (
                            COALESCE(publico_pagante,0) + COALESCE(publico_cortesias,0)
                        ) STORED,

    -- Flags
    transmissao_tv      BOOLEAN DEFAULT FALSE,
    transmissao_streaming BOOLEAN DEFAULT FALSE,
    observacoes         TEXT,

    created_by      INTEGER REFERENCES usuarios(id),
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);
SELECT criar_trigger_updated_at('jogos');

-- ─── Orçamento do jogo ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orcamentos_jogo (
    id          SERIAL PRIMARY KEY,
    jogo_id     INTEGER NOT NULL REFERENCES jogos(id) ON DELETE CASCADE,
    status      VARCHAR(20) DEFAULT 'rascunho'
                CHECK (status IN ('rascunho','aprovado','realizado')),
    aprovado_por INTEGER REFERENCES usuarios(id),
    aprovado_em  TIMESTAMP,
    observacoes  TEXT,
    created_at   TIMESTAMP DEFAULT NOW(),
    updated_at   TIMESTAMP DEFAULT NOW(),
    UNIQUE(jogo_id)
);
SELECT criar_trigger_updated_at('orcamentos_jogo');

CREATE TABLE IF NOT EXISTS itens_orcamento_jogo (
    id              SERIAL PRIMARY KEY,
    orcamento_id    INTEGER NOT NULL REFERENCES orcamentos_jogo(id) ON DELETE CASCADE,
    categoria       VARCHAR(60) NOT NULL,
    descricao       VARCHAR(150) NOT NULL,
    valor_estimado  NUMERIC(12,2) NOT NULL DEFAULT 0,
    valor_realizado NUMERIC(12,2),
    pago            BOOLEAN DEFAULT FALSE,
    fornecedor      VARCHAR(100),
    ordem           INTEGER DEFAULT 0
);

-- ─── Receitas do jogo ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS receitas_jogo (
    id              SERIAL PRIMARY KEY,
    jogo_id         INTEGER NOT NULL REFERENCES jogos(id) ON DELETE CASCADE,
    tipo            VARCHAR(40) NOT NULL
                    CHECK (tipo IN (
                        'bilheteria_socio','bilheteria_inteira','bilheteria_meia',
                        'patrocinio_jogo','cota_tv','streaming','merchandising',
                        'alimentacao','estacionamento','outro'
                    )),
    descricao       VARCHAR(150),
    quantidade      INTEGER,               -- ingressos vendidos (p/ bilheteria)
    valor_unitario  NUMERIC(10,2),
    valor_total     NUMERIC(12,2) NOT NULL,
    realizado       BOOLEAN DEFAULT FALSE, -- estimado vs realizado
    created_at      TIMESTAMP DEFAULT NOW()
);

-- ─── Gols do jogo ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS gols_jogo (
    id          SERIAL PRIMARY KEY,
    jogo_id     INTEGER NOT NULL REFERENCES jogos(id) ON DELETE CASCADE,
    atleta_id   INTEGER REFERENCES atletas(id),
    minuto      INTEGER,
    tipo        VARCHAR(20) DEFAULT 'normal'
                CHECK (tipo IN ('normal','penalti','falta','cabeca','contra','outro')),
    time        VARCHAR(10) NOT NULL CHECK (time IN ('nos','adversario')),
    assistente_id INTEGER REFERENCES atletas(id)
);

-- ─── View: Jogos completos ────────────────────────────────────
CREATE OR REPLACE VIEW jogos_completo AS
SELECT
    j.*,
    -- Resultado formatado
    CASE
        WHEN j.status = 'realizado' AND j.gols_nos IS NOT NULL
        THEN CONCAT(j.gols_nos, ' x ', j.gols_adversario)
        ELSE NULL
    END AS placar,
    CASE
        WHEN j.status = 'realizado' AND j.gols_nos IS NOT NULL THEN
            CASE
                WHEN j.gols_nos > j.gols_adversario  THEN 'vitoria'
                WHEN j.gols_nos < j.gols_adversario  THEN 'derrota'
                ELSE 'empate'
            END
        ELSE NULL
    END AS resultado,
    -- Ocupação do estádio
    CASE
        WHEN j.capacidade_estadio > 0 AND j.publico_total > 0
        THEN ROUND((j.publico_total::NUMERIC / j.capacidade_estadio) * 100, 1)
        ELSE NULL
    END AS ocupacao_pct,
    -- Financeiro
    COALESCE((SELECT SUM(valor_estimado) FROM itens_orcamento_jogo ioj
              JOIN orcamentos_jogo oj ON oj.id = ioj.orcamento_id
              WHERE oj.jogo_id = j.id), 0) AS custo_estimado,
    COALESCE((SELECT SUM(valor_realizado) FROM itens_orcamento_jogo ioj
              JOIN orcamentos_jogo oj ON oj.id = ioj.orcamento_id
              WHERE oj.jogo_id = j.id AND ioj.valor_realizado IS NOT NULL), 0) AS custo_realizado,
    COALESCE((SELECT SUM(valor_total) FROM receitas_jogo rj WHERE rj.jogo_id = j.id), 0) AS receita_total,
    -- Qtd gols
    (SELECT COUNT(*) FROM gols_jogo gj WHERE gj.jogo_id = j.id AND gj.time = 'nos') AS qtd_gols_marcados,
    -- Status do orçamento
    (SELECT oj.status FROM orcamentos_jogo oj WHERE oj.jogo_id = j.id) AS orcamento_status
FROM jogos j;
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
-- ============================================================
-- ERP SAF — Dados financeiros de exemplo
-- Simula 6 meses de movimentação de uma SAF real
-- ============================================================

-- Receitas (ids de categorias: 1=Patrocínio, 2=Bilheteria, 3=TV, 4=Transfer, 5=Aporte, 6=Loja, 7=Prêmios)
INSERT INTO lancamentos_financeiros
  (tipo, descricao, valor, categoria_id, centro_custo_id, conta_bancaria_id, data_competencia, data_pagamento, status, origem_tipo)
VALUES
  -- Outubro 2025
  ('receita', 'Patrocínio máster – Empresa ABC',        120000, 1, 7, 1, '2025-10-01', '2025-10-03', 'realizado', 'manual'),
  ('receita', 'Bilheteria – Jogo Campeonato Estadual',    28500, 2, 1, 1, '2025-10-10', '2025-10-10', 'realizado', 'manual'),
  ('receita', 'Cota direitos de TV – Outubro',            45000, 3, 7, 1, '2025-10-15', '2025-10-16', 'realizado', 'manual'),
  ('despesa', 'Folha de pagamento CLT – Outubro',        198000, 9, 3, 1, '2025-10-31', '2025-10-31', 'realizado', 'folha'),
  ('despesa', 'Contratos PJ comissão técnica – Out',      56000,10, 1, 1, '2025-10-31', '2025-10-31', 'realizado', 'folha'),
  ('despesa', 'Aluguel e manutenção CT – Outubro',        18000,14, 6, 1, '2025-10-05', '2025-10-05', 'realizado', 'manual'),
  ('despesa', 'Viagem jogo fora – combustível e hotel',    8700,13, 1, 3, '2025-10-12', '2025-10-12', 'realizado', 'manual'),
  ('despesa', 'Materiais esportivos – bolas e coletes',    4200,12, 1, 3, '2025-10-18', '2025-10-20', 'realizado', 'pedido_compra'),
  ('despesa', 'Medicamentos e insumos médicos',            3100,15, 5, 1, '2025-10-22', '2025-10-24', 'realizado', 'pedido_compra'),

  -- Novembro 2025
  ('receita', 'Patrocínio máster – Empresa ABC',        120000, 1, 7, 1, '2025-11-01', '2025-11-04', 'realizado', 'manual'),
  ('receita', 'Bilheteria – Jogo Copa do Estado',         42000, 2, 1, 1, '2025-11-08', '2025-11-08', 'realizado', 'manual'),
  ('receita', 'Cota direitos de TV – Novembro',           45000, 3, 7, 1, '2025-11-15', '2025-11-15', 'realizado', 'manual'),
  ('receita', 'Loja oficial – vendas novembro',            9800, 6, 4, 1, '2025-11-30', '2025-11-30', 'realizado', 'manual'),
  ('despesa', 'Folha de pagamento CLT – Novembro',       198000, 9, 3, 1, '2025-11-30', '2025-11-30', 'realizado', 'folha'),
  ('despesa', 'Contratos PJ comissão técnica – Nov',      56000,10, 1, 1, '2025-11-30', '2025-11-30', 'realizado', 'folha'),
  ('despesa', 'Aluguel e manutenção CT – Novembro',       18000,14, 6, 1, '2025-11-05', '2025-11-05', 'realizado', 'manual'),
  ('despesa', 'Patrocínio contra – uniforme jogadores',    6500,16, 4, 1, '2025-11-20', '2025-11-22', 'realizado', 'manual'),
  ('despesa', 'Seguro de saúde – equipe completa',         7200,15, 5, 1, '2025-11-10', '2025-11-10', 'realizado', 'manual'),

  -- Dezembro 2025
  ('receita', 'Patrocínio máster – Empresa ABC',        120000, 1, 7, 1, '2025-12-01', '2025-12-02', 'realizado', 'manual'),
  ('receita', 'Cota direitos de TV – Dezembro',           45000, 3, 7, 1, '2025-12-15', '2025-12-16', 'realizado', 'manual'),
  ('receita', 'Prêmio classificação playoffs',            30000, 7, 1, 1, '2025-12-20', '2025-12-20', 'realizado', 'manual'),
  ('despesa', 'Folha de pagamento CLT – Dezembro',       198000, 9, 3, 1, '2025-12-31', '2025-12-31', 'realizado', 'folha'),
  ('despesa', 'Contratos PJ comissão técnica – Dez',      56000,10, 1, 1, '2025-12-31', '2025-12-31', 'realizado', 'folha'),
  ('despesa', 'Aluguel e manutenção CT – Dezembro',       18000,14, 6, 1, '2025-12-05', '2025-12-05', 'realizado', 'manual'),
  ('despesa', '13º salário – parcela 2ª',                 99000, 9, 3, 1, '2025-12-20', '2025-12-20', 'realizado', 'folha'),

  -- Janeiro 2026
  ('receita', 'Patrocínio máster – Empresa ABC',        120000, 1, 7, 1, '2026-01-01', '2026-01-03', 'realizado', 'manual'),
  ('receita', 'Aporte investidor – Fundo Alpha',         350000, 5, 7, 1, '2026-01-10', '2026-01-10', 'realizado', 'manual'),
  ('receita', 'Cota direitos de TV – Janeiro',            45000, 3, 7, 1, '2026-01-15', '2026-01-15', 'realizado', 'manual'),
  ('despesa', 'Folha de pagamento CLT – Janeiro',        198000, 9, 3, 1, '2026-01-31', '2026-01-31', 'realizado', 'folha'),
  ('despesa', 'Contratos PJ comissão técnica – Jan',      56000,10, 1, 1, '2026-01-31', '2026-01-31', 'realizado', 'folha'),
  ('despesa', 'Aluguel e manutenção CT – Janeiro',        18000,14, 6, 1, '2026-01-05', '2026-01-05', 'realizado', 'manual'),
  ('despesa', 'Renovação de contratos – honorários jur.', 12000,17, 7, 1, '2026-01-15', '2026-01-18', 'realizado', 'manual'),
  ('despesa', 'Equipamento academia – musculação',        22000,12, 1, 1, '2026-01-20', '2026-01-22', 'realizado', 'pedido_compra'),

  -- Fevereiro 2026
  ('receita', 'Patrocínio máster – Empresa ABC',        120000, 1, 7, 1, '2026-02-01', '2026-02-04', 'realizado', 'manual'),
  ('receita', 'Bilheteria – Amistoso pré-temporada',      15000, 2, 1, 1, '2026-02-14', '2026-02-14', 'realizado', 'manual'),
  ('receita', 'Cota direitos de TV – Fevereiro',          45000, 3, 7, 1, '2026-02-15', '2026-02-16', 'realizado', 'manual'),
  ('despesa', 'Folha de pagamento CLT – Fevereiro',      198000, 9, 3, 1, '2026-02-28', '2026-02-28', 'realizado', 'folha'),
  ('despesa', 'Contratos PJ comissão técnica – Fev',      56000,10, 1, 1, '2026-02-28', '2026-02-28', 'realizado', 'folha'),
  ('despesa', 'Aluguel e manutenção CT – Fevereiro',      18000,14, 6, 1, '2026-02-05', '2026-02-05', 'realizado', 'manual'),
  ('despesa', 'Viagem pré-temporada – Chapecó',           14500,13, 1, 1, '2026-02-10', '2026-02-12', 'realizado', 'manual'),
  ('despesa', 'Materiais treino – pré-temporada',          6800,12, 1, 3, '2026-02-08', '2026-02-09', 'realizado', 'pedido_compra'),

  -- Março 2026
  ('receita', 'Patrocínio máster – Empresa ABC',        120000, 1, 7, 1, '2026-03-01', '2026-03-03', 'realizado', 'manual'),
  ('receita', 'Bilheteria – 1ª rodada Campeonato',        31000, 2, 1, 1, '2026-03-08', '2026-03-08', 'realizado', 'manual'),
  ('receita', 'Cota direitos de TV – Março',              45000, 3, 7, 1, '2026-03-15', NULL,          'previsto',  'manual'),
  ('receita', 'Loja oficial – vendas março',               8200, 6, 4, 1, '2026-03-20', NULL,          'previsto',  'manual'),
  ('despesa', 'Folha de pagamento CLT – Março',          198000, 9, 3, 1, '2026-03-31', NULL,          'previsto',  'folha'),
  ('despesa', 'Contratos PJ comissão técnica – Mar',      56000,10, 1, 1, '2026-03-31', NULL,          'previsto',  'folha'),
  ('despesa', 'Aluguel e manutenção CT – Março',          18000,14, 6, 1, '2026-03-05', '2026-03-05',  'realizado', 'manual'),
  ('despesa', 'Encargos FGTS e INSS – Março',             42000,11, 3, 1, '2026-03-20', NULL,          'previsto',  'folha'),
  ('despesa', 'Uniforme 1º time – temporada 2026',        35000,12, 1, 1, '2026-03-10', '2026-03-12',  'realizado', 'pedido_compra'),
  ('despesa', 'Marketing redes sociais – Março',           5500,16, 4, 1, '2026-03-01', '2026-03-01',  'realizado', 'manual');
-- ============================================================
-- SEED: PEDIDOS DE COMPRA — Dados de Demonstração
-- ERP SAF
-- ============================================================

-- Nota: este seed pressupõe que os schemas de funcionarios
-- e financeiro já foram executados (categorias_financeiras,
-- centros_custo, departamentos, usuarios existem).

-- ------------------------------------------------------------
-- PEDIDOS DE COMPRA
-- ------------------------------------------------------------
INSERT INTO pedidos_compra
    (numero, titulo, descricao, departamento_id, prioridade, data_necessidade,
     status, centro_custo_id, categoria_financeira_id,
     valor_estimado, valor_aprovado, valor_final, observacoes)
VALUES
-- 1. Concluído
(
    'PC-2026-001',
    'Compra de Uniformes — Temporada 2026',
    'Uniformes completos para elenco principal (22 atletas), comissão técnica e staff. Inclui camisa, calção e meias em 3 versões (jogo, treino, aquecimento).',
    3,  -- Futebol / Esporte
    'alta',
    '2026-01-15',
    'concluido',
    3,  -- Futebol Profissional
    10, -- Despesa: Material Esportivo
    45000.00, 43500.00, 42800.00,
    'Pedido concluído. Uniformes entregues em 12/01/2026.'
),
-- 2. Aprovado / Em compra
(
    'PC-2026-002',
    'Equipamentos de Academia — Renovação',
    'Substituição de 4 esteiras, 2 bicicletas ergométricas e conjunto de pesos livres. Equipamentos atuais com mais de 5 anos de uso.',
    3,
    'normal',
    '2026-02-28',
    'em_compra',
    3,
    10,
    38000.00, 36500.00, NULL,
    'Aprovado pelo diretor financeiro. Aguardando entrega do fornecedor.'
),
-- 3. Aguardando aprovação
(
    'PC-2026-003',
    'Serviço de Fisioterapia — Contrato Mensal',
    'Contratação de empresa de fisioterapia para atendimento diário ao elenco. Estimativa de 3 fisioterapeutas por período.',
    3,
    'alta',
    '2026-03-01',
    'aguardando_aprovacao',
    3,
    10,
    18000.00, NULL, NULL,
    'Urgente — início do campeonato em março. 3 cotações coletadas.'
),
-- 4. Em cotação
(
    'PC-2026-004',
    'Transporte para Jogo Fora — Abril',
    'Fretamento de ônibus executivo para 3 partidas fora de casa em abril. Inclui motorista, seguro e combustível.',
    3,
    'normal',
    '2026-03-25',
    'em_cotacao',
    3,
    10,
    12000.00, NULL, NULL,
    'Aguardando cotação de 2 transportadoras.'
),
-- 5. Aguardando cotação
(
    'PC-2026-005',
    'Material de Escritório — Trimestre Q2',
    'Resmas de papel, cartuchos de impressora, canetas, pastas e material de organização para os departamentos administrativos.',
    2,  -- Administração
    'baixa',
    '2026-04-10',
    'aguardando_cotacao',
    6,  -- Administração Geral
    10,
    3500.00, NULL, NULL,
    NULL
),
-- 6. Rascunho
(
    'PC-2026-006',
    'Software de Análise de Desempenho — Atletas',
    'Licença anual de plataforma de vídeo-análise e métricas físicas para comissão técnica. Comparação com Hudl, Wyscout e Krossover em andamento.',
    3,
    'normal',
    '2026-04-30',
    'rascunho',
    3,
    12,  -- Despesa: Tecnologia / Infraestrutura
    28000.00, NULL, NULL,
    'Em avaliação. Precisa aprovação do diretor técnico antes de enviar para cotação.'
),
-- 7. Rejeitado
(
    'PC-2026-007',
    'Cadeiras VIP — Reforma do Camarote',
    'Compra de 40 cadeiras estofadas para reforma do camarote dos investidores.',
    1,  -- Diretoria
    'baixa',
    '2026-02-15',
    'rejeitado',
    6,
    10,
    22000.00, NULL, NULL,
    NULL
),
-- 8. Cancelado
(
    'PC-2026-008',
    'Campanha de Marketing — Redes Sociais',
    'Contratação de agência para gestão das redes sociais e criação de conteúdo.',
    5,  -- Marketing
    'normal',
    '2026-02-01',
    'cancelado',
    7,  -- Marketing
    13,  -- Despesa: Marketing
    9500.00, NULL, NULL,
    'Cancelado — orçamento redirecionado para reforço no elenco.'
);

-- ------------------------------------------------------------
-- ITENS DOS PEDIDOS
-- ------------------------------------------------------------
INSERT INTO itens_pedido (pedido_id, descricao, quantidade, unidade, valor_unitario_estimado) VALUES
-- PC-2026-001 (uniformes)
(1, 'Camisa jogo titular (G/M/GG)', 22, 'un', 320.00),
(1, 'Camisa treino', 30, 'un', 180.00),
(1, 'Calção jogo', 25, 'un', 140.00),
(1, 'Meias (par)', 60, 'par', 45.00),
(1, 'Agasalho completo', 30, 'un', 280.00),
-- PC-2026-002 (academia)
(2, 'Esteira profissional', 4, 'un', 5800.00),
(2, 'Bicicleta ergométrica', 2, 'un', 3200.00),
(2, 'Conjunto de pesos livres 5-50kg', 1, 'conj', 12000.00),
(2, 'Banco supino ajustável', 3, 'un', 1800.00),
-- PC-2026-003 (fisioterapia)
(3, 'Fisioterapeuta período matutino (mensal)', 2, 'vaga', 6000.00),
(3, 'Fisioterapeuta período vespertino (mensal)', 1, 'vaga', 5500.00),
(3, 'Materiais consumíveis mensais', 1, 'kit', 800.00),
-- PC-2026-004 (transporte)
(4, 'Ônibus executivo 46 lugares — jogo 1', 1, 'diária', 3800.00),
(4, 'Ônibus executivo 46 lugares — jogo 2', 1, 'diária', 4200.00),
(4, 'Ônibus executivo 46 lugares — jogo 3', 1, 'diária', 3500.00),
-- PC-2026-005 (escritório)
(5, 'Resma de papel A4 500 folhas', 20, 'un', 28.00),
(5, 'Cartucho impressora HP preto', 5, 'un', 95.00),
(5, 'Cartucho impressora HP colorido', 4, 'un', 120.00),
(5, 'Pasta AZ', 30, 'un', 18.00),
(5, 'Canetas esferográficas (caixa 12)', 10, 'cx', 22.00);

-- ------------------------------------------------------------
-- COTAÇÕES
-- ------------------------------------------------------------
INSERT INTO cotacoes
    (pedido_id, fornecedor_id, numero_cotacao, data_cotacao, validade_cotacao,
     prazo_entrega, status, valor_total, condicoes_pagamento, observacoes)
VALUES
-- Cotações do PC-2026-001 (concluído — uniformes)
(1, 1, 'SM-2025-4421', '2025-12-10', '2025-12-31', 10, 'selecionada', 42800.00,
 '50% entrada, 50% na entrega', 'Melhor preço + entrega no prazo. SELECIONADA.'),
(1, 6, 'GC-2025-0891', '2025-12-11', '2025-12-31', 20, 'rejeitada',  46200.00,
 '30 dias', 'Prazo de entrega longo demais.'),

-- Cotações do PC-2026-002 (academia — em compra)
(2, 1, 'SM-2026-0112', '2026-01-20', '2026-02-20', 15, 'selecionada', 36500.00,
 '30 dias', 'Incluí instalação e garantia de 2 anos. SELECIONADA.'),
(2, 4, 'TF-2026-0034', '2026-01-22', '2026-02-22', 20, 'rejeitada',  39800.00,
 '28 dias', 'Valor acima do orçamento aprovado.'),

-- Cotações do PC-2026-003 (fisioterapia — aguardando aprovação)
(3, 3, 'MS-2026-0078', '2026-02-14', '2026-03-14', 3,  'selecionada', 17200.00,
 'Mensal', 'Proposta com 3 fisios + materiais. Referência no mercado. SELECIONADA.'),
(3, 3, 'MS-2026-0079', '2026-02-15', '2026-03-15', 3,  'recebida',    18500.00,
 'Mensal', 'Proposta alternativa com 2 fisios sênior.'),
(3, 3, 'INDEP-2026-01', '2026-02-16', '2026-03-16', 1, 'recebida',    15000.00,
 'Mensal', 'Profissionais autônomos. Menor custo porém sem CNPJ.'),

-- Cotação do PC-2026-004 (transporte — em cotação)
(4, 5, 'TF-2026-0210', '2026-03-10', '2026-03-25', 2,  'recebida',    11500.00,
 '30 dias após evento', 'Ônibus Volvo executivo. Motorista incluso.');

-- ------------------------------------------------------------
-- ITENS DAS COTAÇÕES (vinculados ao pedido 1 — uniformes)
-- ------------------------------------------------------------
INSERT INTO itens_cotacao (cotacao_id, item_pedido_id, valor_unitario, valor_total, disponivel) VALUES
-- Cotação 1 (selecionada — SportMax) → itens pedido 1-5
(1, 1, 290.00,  6380.00, TRUE),
(1, 2, 160.00,  4800.00, TRUE),
(1, 3, 130.00,  3250.00, TRUE),
(1, 4,  38.00,  2280.00, TRUE),
(1, 5, 260.00,  7800.00, TRUE),
-- Cotação 2 (rejeitada — Gráfica) → itens pedido 1-5
(2, 1, 310.00,  6820.00, TRUE),
(2, 2, 195.00,  5850.00, TRUE),
(2, 3, 148.00,  3700.00, TRUE),
(2, 4,  50.00,  3000.00, TRUE),
(2, 5, 295.00,  8850.00, TRUE);

-- ------------------------------------------------------------
-- HISTÓRICO DOS PEDIDOS
-- ------------------------------------------------------------
INSERT INTO historico_pedido (pedido_id, acao, descricao) VALUES
(1, 'criou',           'Pedido criado como rascunho.'),
(1, 'enviou_cotacao',  'Pedido enviado para cotação com fornecedores.'),
(1, 'cotacao',         'Cotação recebida de SportMax Equipamentos: R$ 42.800,00.'),
(1, 'cotacao',         'Cotação recebida de Gráfica Campeão: R$ 46.200,00.'),
(1, 'selecionou',      'Cotação da SportMax selecionada como melhor proposta.'),
(1, 'enviou_aprovacao','Pedido enviado para aprovação do gestor.'),
(1, 'aprovou',         'Pedido aprovado. Valor aprovado: R$ 43.500,00.'),
(1, 'concluiu',        'Uniformes recebidos e conferidos. Valor final: R$ 42.800,00.'),

(2, 'criou',           'Pedido criado.'),
(2, 'enviou_cotacao',  'Enviado para cotação.'),
(2, 'cotacao',         'Cotação de SportMax: R$ 36.500,00 (inclui instalação e garantia).'),
(2, 'cotacao',         'Cotação de TechField: R$ 39.800,00.'),
(2, 'selecionou',      'SportMax selecionada. Melhor custo-benefício.'),
(2, 'aprovou',         'Aprovado pelo diretor. Em processo de compra.'),

(3, 'criou',           'Pedido criado. Início do campeonato exige fisioterapia diária.'),
(3, 'enviou_cotacao',  '3 cotações coletadas.'),
(3, 'selecionou',      'MedSport selecionada: R$ 17.200,00/mês.'),
(3, 'enviou_aprovacao','Aguardando aprovação da diretoria.'),

(4, 'criou',           'Pedido criado para jogos fora em abril.'),
(4, 'cotacao',         'Cotação de TransportesFut: R$ 11.500,00.'),

(5, 'criou',           'Pedido de material de escritório para Q2.'),

(7, 'criou',           'Pedido de reforma do camarote criado.'),
(7, 'rejeitou',        'Rejeitado. Não é prioridade no momento. Orçamento limitado.'),

(8, 'criou',           'Pedido de marketing criado.'),
(8, 'cancelou',        'Cancelado — verba redirecionada para contratação de atleta.');
-- ============================================================
-- SEED: ATLETAS — Dados de Demonstração
-- ERP SAF — Elenco 2026
-- ============================================================

-- ------------------------------------------------------------
-- ATLETAS
-- ------------------------------------------------------------
INSERT INTO atletas (nome, nome_guerra, data_nascimento, nacionalidade, posicao, pe_dominante, altura_cm, peso_kg, status, clube_formacao, agente) VALUES
-- Goleiros
('Ricardo Souza Mendes',     'Ricardo',    '1995-03-12', 'Brasileira', 'goleiro',           'direito',  188, 85.0, 'ativo',    'Flamengo',      'Diego Agente'),
('Paulo Henrique Tavares',   'Paulão',     '2000-07-25', 'Brasileira', 'goleiro',           'direito',  186, 82.5, 'ativo',    'Grêmio',        NULL),
-- Laterais
('Marcus Vinícius Costa',    'Markinho',   '1998-11-08', 'Brasileira', 'lateral_direito',   'direito',  175, 72.0, 'ativo',    'Santos',        'Agência Élite'),
('Gabriel Fernandes Lima',   'Biel',       '2001-02-14', 'Brasileira', 'lateral_esquerdo',  'esquerdo', 172, 68.0, 'ativo',    'Atlético-MG',   NULL),
-- Zagueiros
('Carlos Alberto Nunes',     'Carlão',     '1993-06-30', 'Brasileira', 'zagueiro',          'direito',  190, 90.0, 'ativo',    'Corinthians',   'Diego Agente'),
('Emerson Rodrigues Silva',  'Emerson',    '1997-09-18', 'Brasileira', 'zagueiro',          'direito',  185, 84.0, 'lesionado','Vasco',         NULL),
('Jorge Luis Pereira',       'Jorge',      '2002-04-05', 'Brasileira', 'zagueiro',          'esquerdo', 183, 80.0, 'ativo',    'Formação própria', NULL),
-- Volantes
('Anderson Silva Gomes',     'Anderson',   '1996-12-21', 'Brasileira', 'volante',           'direito',  180, 78.0, 'ativo',    'Internacional', 'Carlos Reps'),
('Thiago Barbosa Alves',     'Thiagão',    '1999-08-17', 'Brasileira', 'volante',           'direito',  177, 75.5, 'suspenso', 'Bahia',         NULL),
-- Meias
('Felipe Augusto Ramos',     'Felipão',    '1994-01-29', 'Brasileira', 'meia_central',      'direito',  176, 74.0, 'ativo',    'Fluminense',    'Agência Élite'),
('Diego Henrique Carvalho',  'Diegão',     '1997-05-03', 'Brasileira', 'meia_atacante',     'esquerdo', 174, 71.0, 'ativo',    'Cruzeiro',      'Diego Agente'),
('Lucas Martins Ribeiro',    'Lukinha',    '2003-10-12', 'Brasileira', 'meia_atacante',     'direito',  170, 66.0, 'ativo',    'Formação própria','Carlos Reps'),
-- Pontas e Atacantes
('Rodrigo Alves Pinto',      'Rodrigo',    '1995-07-19', 'Brasileira', 'ponta_direita',     'direito',  173, 70.0, 'ativo',    'Botafogo',      'Diego Agente'),
('Hélio Santos Vieira',      'Helinho',    '2000-03-28', 'Brasileira', 'ponta_esquerda',    'esquerdo', 171, 68.5, 'ativo',    'Coritiba',      NULL),
('Alexandre Costa Prado',    'Alemão',     '1992-11-14', 'Brasileira', 'centroavante',      'direito',  181, 82.0, 'ativo',    'Athletico-PR',  'Carlos Reps'),
('William Nascimento Faria', 'Will',       '1998-04-22', 'Brasileira', 'centroavante',      'direito',  179, 79.0, 'emprestado','Fortaleza',    'Agência Élite'),
('Mateus Oliveira Torres',   'Mateuzinho', '2001-09-06', 'Brasileira', 'ponta_direita',     'ambidestro',168,65.0, 'ativo',    'Formação própria', NULL);

-- ------------------------------------------------------------
-- CONTRATOS ATIVOS
-- ------------------------------------------------------------
INSERT INTO contratos_atleta
    (atleta_id, numero_contrato, tipo, data_inicio, data_fim,
     salario_bruto, salario_carteira, direitos_imagem, luvas, clausula_rescisoria, status, observacoes)
VALUES
-- 1. Ricardo (Goleiro titular)
(1,  'CT-2026-001', 'profissional', '2024-01-01', '2026-12-31', 35000.00, 5000.00, 30000.00, 0,       5000000.00, 'ativo', 'Goleiro titular. Renovação pendente para 2027.'),
-- 2. Paulão (Goleiro reserva)
(2,  'CT-2026-002', 'profissional', '2025-02-01', '2027-01-31', 8000.00,  4000.00, 4000.00,  0,       200000.00,  'ativo', NULL),
-- 3. Markinho (Lateral D)
(3,  'CT-2026-003', 'profissional', '2023-07-01', '2026-06-30', 18000.00, 4500.00, 13500.00, 0,       1500000.00, 'ativo', 'Contrato vencendo em junho. Negociação em andamento.'),
-- 4. Biel (Lateral E)
(4,  'CT-2026-004', 'profissional', '2025-01-15', '2027-12-31', 12000.00, 4000.00, 8000.00,  0,       500000.00,  'ativo', NULL),
-- 5. Carlão (Zagueiro)
(5,  'CT-2026-005', 'profissional', '2022-03-01', '2026-02-28', 22000.00, 5500.00, 16500.00, 10000.00,2000000.00, 'ativo', 'Contrato VENCIDO — renovação em análise.'),
-- 6. Emerson (Zagueiro — lesionado)
(6,  'CT-2026-006', 'profissional', '2024-08-01', '2027-07-31', 14000.00, 4000.00, 10000.00, 0,       800000.00,  'ativo', 'Lesão no joelho esquerdo. Previsão de retorno: maio/2026.'),
-- 7. Jorge (Zagueiro jovem)
(7,  'CT-2026-007', 'formacao',     '2025-01-01', '2026-12-31', 5000.00,  5000.00, 0,         0,       50000.00,   'ativo', 'Contrato de formação. Promissor.'),
-- 8. Anderson (Volante)
(8,  'CT-2026-008', 'profissional', '2024-06-01', '2027-05-31', 20000.00, 5000.00, 15000.00, 5000.00, 2500000.00, 'ativo', 'Capitão do time.'),
-- 9. Thiagão (Volante — suspenso)
(9,  'CT-2026-009', 'profissional', '2025-03-01', '2027-02-28', 11000.00, 4000.00, 7000.00,  0,       400000.00,  'ativo', 'Suspenso por 3 jogos. Dois cartões vermelhos na temporada.'),
-- 10. Felipão (Meia)
(10, 'CT-2026-010', 'profissional', '2023-01-01', '2026-12-31', 28000.00, 6000.00, 22000.00, 8000.00, 4000000.00, 'ativo', 'Destaque do time. Interesse de clubes da Série A.'),
-- 11. Diegão (Meia-atacante)
(11, 'CT-2026-011', 'profissional', '2024-07-01', '2027-06-30', 16000.00, 4500.00, 11500.00, 0,       1000000.00, 'ativo', NULL),
-- 12. Lukinha (Meia jovem)
(12, 'CT-2026-012', 'formacao',     '2025-01-01', '2027-12-31', 4500.00,  4500.00, 0,         0,       80000.00,   'ativo', 'Revelação das categorias de base.'),
-- 13. Rodrigo (Ponta D)
(13, 'CT-2026-013', 'profissional', '2024-01-15', '2026-12-31', 19000.00, 5000.00, 14000.00, 0,       1800000.00, 'ativo', NULL),
-- 14. Helinho (Ponta E)
(14, 'CT-2026-014', 'profissional', '2025-04-01', '2027-03-31', 13500.00, 4000.00, 9500.00,  0,       600000.00,  'ativo', NULL),
-- 15. Alemão (Centroavante — artilheiro)
(15, 'CT-2026-015', 'profissional', '2023-06-01', '2026-05-31', 32000.00, 7000.00, 25000.00, 15000.00,3500000.00, 'ativo', 'Artilheiro da equipe. Renovação prioritária.'),
-- 16. Will (Emprestado)
(16, 'CT-2026-016', 'emprestimo',   '2026-01-01', '2026-06-30', 18000.00, 5000.00, 13000.00, 0,       NULL,       'ativo', 'Cedido pelo Fortaleza. Opção de compra por R$ 3,5M.', ),
-- 17. Mateuzinho (Jovem)
(17, 'CT-2026-017', 'formacao',     '2025-06-01', '2027-05-31', 3500.00,  3500.00, 0,         0,       30000.00,   'ativo', NULL);

-- ------------------------------------------------------------
-- METAS / BONIFICAÇÕES (por contrato)
-- ------------------------------------------------------------
INSERT INTO metas_contrato (contrato_id, tipo, descricao, meta_quantidade, valor_bonus, tipo_calculo, competicao, observacoes) VALUES

-- GOLEIRO RICARDO (ct 1)
(1, 'jogo_sem_sofrer_gol', 'Bônus por jogo sem sofrer gol (clean sheet)', 1, 1500.00, 'por_unidade', NULL, 'Pago mensalmente com base nos jogos do mês'),
(1, 'jogo_disputado',      'Bônus por jogo disputado (titular)',           1,  500.00, 'por_unidade', NULL, NULL),
(1, 'cartao_amarelo',      'Desconto por cartão amarelo',                  1, -300.00, 'por_unidade', NULL, 'Aplicado por advertência desnecessária'),

-- CARLÃO — zagueiro (ct 5)
(5, 'jogo_disputado',      'Bônus por jogo disputado como titular',        1,  800.00, 'por_unidade', NULL, NULL),
(5, 'jogo_sem_sofrer_gol', 'Bônus por jogo sem sofrer gol',                1,  600.00, 'por_unidade', NULL, NULL),
(5, 'gol',                 'Bônus por gol marcado (bola parada)',          1, 2000.00, 'por_unidade', NULL, 'Válido para gols em escanteio e falta'),
(5, 'cartao_amarelo',      'Desconto por cartão amarelo',                  1, -500.00, 'por_unidade', NULL, NULL),
(5, 'cartao_vermelho',     'Desconto por cartão vermelho',                 1,-1500.00, 'por_unidade', NULL, NULL),

-- ANDERSON — capitão/volante (ct 8)
(8, 'jogo_disputado',      'Bônus por partida como titular',               1,  700.00, 'por_unidade', NULL, NULL),
(8, 'assistencia',         'Bônus por assistência para gol',               1, 1500.00, 'por_unidade', NULL, NULL),
(8, 'gol',                 'Bônus por gol marcado',                        1, 2500.00, 'por_unidade', NULL, NULL),
(8, 'cartao_vermelho',     'Desconto por cartão vermelho',                 1,-2000.00, 'por_unidade', NULL, NULL),

-- FELIPÃO — meia destaque (ct 10)
(10,'gol',                 'Bônus por gol marcado',                        1, 3000.00, 'por_unidade', NULL, NULL),
(10,'assistencia',         'Bônus por assistência',                        1, 2000.00, 'por_unidade', NULL, NULL),
(10,'jogo_disputado',      'Bônus por jogo disputado',                     1,  600.00, 'por_unidade', NULL, NULL),
(10,'artilharia',          'Bônus por ser artilheiro da competição',       1,15000.00, 'total_periodo','Série B','Pago ao fim da competição'),
(10,'classificacao',       'Bônus por acesso à Série A',                   1,50000.00, 'total_periodo', NULL, 'Pago em caso de acesso ao final do campeonato'),

-- ALEMÃO — artilheiro (ct 15)
(15,'gol',                 'Bônus por gol marcado',                        1, 3500.00, 'por_unidade', NULL, 'Principal cláusula de desempenho'),
(15,'assistencia',         'Bônus por assistência para gol',               1, 1800.00, 'por_unidade', NULL, NULL),
(15,'jogo_disputado',      'Bônus por jogo como titular',                  1,  900.00, 'por_unidade', NULL, NULL),
(15,'artilharia',          'Bônus por artilharia da Série B',              1,25000.00, 'total_periodo','Série B', NULL),
(15,'classificacao',       'Bônus por acesso à Série A',                   1,80000.00, 'total_periodo', NULL, 'Cláusula de acesso'),

-- WILL — emprestado (ct 16)
(16,'gol',                 'Bônus por gol (repassado ao Fortaleza)',        1, 1000.00, 'por_unidade', NULL, '50% vai ao clube cedente'),
(16,'jogo_disputado',      'Bônus por jogo como titular',                  1,  500.00, 'por_unidade', NULL, NULL);

-- ------------------------------------------------------------
-- ESTATÍSTICAS 2026 — Série B e Copa do Brasil
-- ------------------------------------------------------------
INSERT INTO estatisticas_atleta
    (atleta_id, temporada, competicao, jogos_disputados, jogos_titular,
     minutos_jogados, gols, assistencias, jogos_sem_sofrer_gol,
     cartoes_amarelos, cartoes_vermelhos, defesas_dificeis)
VALUES
-- SÉRIE B 2026
(1,  '2026', 'Série B',       10, 10,  900,  0, 0, 6, 0, 0, 28),  -- Ricardo: 6 clean sheets
(2,  '2026', 'Série B',        2,  2,  180,  0, 0, 0, 1, 0,  4),  -- Paulão: reserva
(3,  '2026', 'Série B',        9,  9,  810,  1, 2, 0, 2, 0,  0),  -- Markinho: lateral ofensivo
(4,  '2026', 'Série B',        8,  8,  720,  0, 3, 0, 1, 0,  0),  -- Biel: lateral ofensivo
(5,  '2026', 'Série B',       10, 10,  900,  2, 1, 0, 3, 0,  0),  -- Carlão: 2 gols de bola parada
(6,  '2026', 'Série B',        3,  3,  270,  0, 0, 0, 0, 0,  0),  -- Emerson: lesionou
(7,  '2026', 'Série B',        5,  4,  380,  0, 0, 0, 1, 0,  0),  -- Jorge: jovem
(8,  '2026', 'Série B',       10, 10,  900,  3, 4, 0, 1, 0,  0),  -- Anderson: capitão
(9,  '2026', 'Série B',        7,  6,  570,  1, 1, 0, 3, 2,  0),  -- Thiagão: suspenso (2 vermelhos)
(10, '2026', 'Série B',       10, 10,  900,  5, 4, 0, 1, 0,  0),  -- Felipão: destaque
(11, '2026', 'Série B',        9,  8,  768,  3, 5, 0, 2, 0,  0),  -- Diegão: criativo
(12, '2026', 'Série B',        6,  3,  324,  1, 2, 0, 0, 0,  0),  -- Lukinha: jovem
(13, '2026', 'Série B',       10,  9,  840,  4, 3, 0, 1, 0,  0),  -- Rodrigo: ponta
(14, '2026', 'Série B',        8,  7,  630,  2, 4, 0, 1, 0,  0),  -- Helinho: ponta
(15, '2026', 'Série B',       10, 10,  900,  8, 2, 0, 0, 0,  0),  -- Alemão: artilheiro!
(16, '2026', 'Série B',        7,  6,  540,  3, 1, 0, 1, 0,  0),  -- Will: emprestado
(17, '2026', 'Série B',        4,  1,  180,  0, 1, 0, 0, 0,  0),  -- Mateuzinho: promessa

-- COPA DO BRASIL 2026
(1,  '2026', 'Copa do Brasil',  3,  3,  270,  0, 0, 2, 0, 0,  7),
(3,  '2026', 'Copa do Brasil',  3,  3,  270,  0, 1, 0, 0, 0,  0),
(5,  '2026', 'Copa do Brasil',  3,  3,  270,  1, 0, 0, 0, 0,  0),
(8,  '2026', 'Copa do Brasil',  3,  3,  270,  1, 1, 0, 0, 0,  0),
(10, '2026', 'Copa do Brasil',  3,  3,  270,  2, 1, 0, 0, 0,  0),
(15, '2026', 'Copa do Brasil',  3,  3,  270,  4, 0, 0, 0, 0,  0),  -- Alemão: 4 gols também na Copa!
(13, '2026', 'Copa do Brasil',  3,  2,  210,  1, 1, 0, 0, 0,  0);

-- ------------------------------------------------------------
-- BONIFICAÇÕES PAGAS/PENDENTES — Fevereiro e Março 2026
-- ------------------------------------------------------------
INSERT INTO bonificacoes_atleta (atleta_id, contrato_id, meta_id, competencia, descricao, valor, tipo, status) VALUES
-- Ricardo — Fevereiro (3 clean sheets, 4 jogos)
(1, 1, 1, '2026-02-01', 'Clean sheets — Fevereiro (3 jogos)', 4500.00, 'bonus', 'pago'),
(1, 1, 2, '2026-02-01', 'Jogos disputados — Fevereiro (4 jogos)', 2000.00, 'bonus', 'pago'),
-- Carlão — Fevereiro (1 gol, 2 cartões)
(5, 5, 4, '2026-02-01', 'Jogos disputados — Fevereiro (4 jogos)', 3200.00, 'bonus', 'pago'),
(5, 5, 6, '2026-02-01', 'Gol de escanteio — Fevereiro', 2000.00, 'bonus', 'pago'),
(5, 5, 7, '2026-02-01', 'Cartão amarelo — Fevereiro (1)', -500.00, 'desconto', 'pago'),
-- Alemão — Fevereiro (4 gols, 4 jogos)
(15,15,18,'2026-02-01', 'Gols marcados — Fevereiro (4 gols)', 14000.00, 'bonus', 'pago'),
(15,15,20,'2026-02-01', 'Jogos disputados — Fevereiro (4 jogos)', 3600.00, 'bonus', 'pago'),
-- Felipão — Fevereiro (2 gols, 2 assistências)
(10,10,13,'2026-02-01', 'Gols marcados — Fevereiro (2 gols)', 6000.00, 'bonus', 'pago'),
(10,10,14,'2026-02-01', 'Assistências — Fevereiro (2)', 4000.00, 'bonus', 'pago'),
-- Thiagão — Desconto por vermelho — Março
(9, 9, NULL,'2026-03-01', 'Desconto cartão vermelho — Rodada 8', -2000.00, 'desconto', 'pendente'),
-- Anderson — Março (1 gol, 2 assistências)
(8, 8, 11, '2026-03-01', 'Gol marcado — Março', 2500.00, 'bonus', 'pendente'),
(8, 8, 10, '2026-03-01', 'Assistências — Março (2)', 3000.00, 'bonus', 'pendente'),
-- Ricardo — Março (3 clean sheets, 4 jogos)
(1, 1, 1, '2026-03-01', 'Clean sheets — Março (3 jogos)', 4500.00, 'bonus', 'pendente'),
(1, 1, 2, '2026-03-01', 'Jogos disputados — Março (4 jogos)', 2000.00, 'bonus', 'pendente');

-- ------------------------------------------------------------
-- HISTÓRICO DE SALÁRIO — Alterações por desempenho
-- ------------------------------------------------------------
INSERT INTO historico_salario_atleta (atleta_id, contrato_id, data_alteracao, salario_anterior, salario_novo, motivo) VALUES
(15, 15, '2026-01-01', 28000.00, 32000.00, 'Ajuste por artilharia da Série C — 18 gols na temporada 2025'),
(1,  1,  '2024-01-01', 28000.00, 35000.00, 'Renovação contratual com reajuste por desempenho'),
(10, 10, '2023-01-01', 22000.00, 28000.00, 'Renovação — melhor jogador da Série C 2022'),
(8,  8,  '2024-06-01', 16000.00, 20000.00, 'Reajuste — capitão e referência técnica'),
(3,  3,  '2023-07-01', 12000.00, 18000.00, 'Renovação após 14 jogos como titular consecutivos');
-- ============================================================
-- SEED: INVESTIDORES — Dados de Demonstração
-- ERP SAF
-- ============================================================

-- ------------------------------------------------------------
-- INVESTIDORES
-- ------------------------------------------------------------
INSERT INTO investidores (nome, tipo, cpf_cnpj, perfil, email, telefone, percentual_participacao, nome_fantasia, responsavel, observacoes) VALUES

-- Sócios com participação acionária
('Roberto Andrade Menezes',     'pessoa_fisica',   '111.222.333-44', 'socio',        'roberto.menezes@email.com',   '(11) 99999-1111', 25.000, NULL,                  NULL,                'Sócio majoritário. Empresário do setor imobiliário.'),
('Grupo Empresarial Vitória',   'pessoa_juridica', '22.333.444/0001-55','socio',     'contato@grupovitoria.com.br', '(11) 3000-2222', 20.000, 'Grupo Vitória',       'Marcos Vitória',    'Grupo com 3 empresas do setor financeiro. Interesse em visibilidade no esporte.'),
('Patricia Lima Coutinho',      'pessoa_fisica',   '333.444.555-66', 'socio',        'patricia.coutinho@email.com', '(11) 98888-3333',  8.000, NULL,                  NULL,                'Sócia investidora. Família tradicional da cidade.'),

-- Patrocinadores
('Construtora Apex S/A',        'pessoa_juridica', '44.555.666/0001-77','patrocinador','comercial@apex.com.br',     '(11) 3500-4444',  0.000, 'Apex Construções',    'Fernando Apex',     'Patrocinador master da camisa. Contrato anual.'),
('Farmácias Saúde Total',       'pessoa_juridica', '55.666.777/0001-88','patrocinador','mkt@saudetotal.com.br',     '(11) 3200-5555',  0.000, 'Saúde Total',         'Ana Diretora',      'Patrocinador cota ouro. Faixa de publicidade no estádio.'),
('Auto Peças Rodrigues Ltda',   'pessoa_juridica', '66.777.888/0001-99','patrocinador','contato@autorodrigues.com', '(11) 9700-6666',  0.000, 'Rodrigues Peças',     'Paulo Rodrigues',   'Patrocinador local. Renovação anual.'),

-- Investidores financeiros
('Ricardo Fontes Barros',       'pessoa_fisica',   '777.888.999-00', 'investidor',   'r.fontes@email.com',          '(11) 97777-7777',  0.000, NULL,                  NULL,                'Investidor financeiro. Espera retorno em dividendos futuros.'),
('Fundo Esporte Capital FIP',   'pessoa_juridica', '88.999.000/0001-11','investidor','gestao@esportecapital.com',  '(11) 3100-8888',  0.000, 'Esporte Capital',     'Gestora Fundo',     'Fundo de investimento em clubes. Aportes via empréstimo com conversão.'),

-- Mecenas / Doadores
('Dr. Henrique Albuquerque',    'pessoa_fisica',   '999.000.111-22', 'mecenatismo',  'dr.henrique@clinica.com.br',  '(11) 96666-9999',  0.000, NULL,                  NULL,                'Médico e torcedor apaixonado. Doações regulares.');

-- ------------------------------------------------------------
-- APORTES
-- ------------------------------------------------------------
INSERT INTO aportes (investidor_id, tipo, descricao, valor, data_aporte, competencia, percentual_concedido, contrapartida, status, observacoes) VALUES

-- Roberto Andrade (sócio 25%)
(1, 'aporte_capital', 'Aporte inicial de capitalização — fundação da SAF', 2500000.00, '2023-01-15', '2023-01-01', 25.000, NULL, 'confirmado', 'Aporte que formalizou a participação acionária de 25%.'),
(1, 'aporte_capital', 'Aporte complementar — reforço de elenco 2024',       500000.00, '2024-02-10', '2024-02-01',  0.000, NULL, 'confirmado', 'Aporte adicional sem diluição de terceiros.'),
(1, 'aporte_capital', 'Aporte para infraestrutura — CT reforma',             800000.00, '2025-06-01', '2025-06-01',  0.000, NULL, 'confirmado', 'Reforma do Centro de Treinamento.'),

-- Grupo Vitória (sócio 20%)
(2, 'aporte_capital', 'Entrada do Grupo Vitória — participação societária', 2000000.00, '2023-03-01', '2023-03-01', 20.000, NULL, 'confirmado', 'Ingresso do grupo como segundo maior acionista.'),
(2, 'aporte_capital', 'Aporte temporada 2025 — folha de atletas',            600000.00, '2025-01-15', '2025-01-01',  0.000, NULL, 'confirmado', NULL),
(2, 'aporte_capital', 'Aporte 2026 — planejamento esportivo',                700000.00, '2026-01-10', '2026-01-01',  0.000, NULL, 'confirmado', NULL),

-- Patrícia Lima (sócia 8%)
(3, 'aporte_capital', 'Aporte de ingresso — participação 8%',                800000.00, '2023-07-01', '2023-07-01',  8.000, NULL, 'confirmado', NULL),
(3, 'aporte_capital', 'Aporte adicional — Copa do Brasil 2025',              200000.00, '2025-04-01', '2025-04-01',  0.000, NULL, 'confirmado', NULL),

-- Construtora Apex (patrocinador master)
(4, 'patrocinio', 'Patrocínio master camisa 2024 — Apex',                   480000.00, '2024-01-15', '2024-01-01',  0.000, 'Logo frente camisa titular + reserva, naming rights CT, área VIP 10 pessoas', 'confirmado', 'Contrato anual. Pago em 12x.'),
(4, 'patrocinio', 'Patrocínio master camisa 2025 — Apex',                   540000.00, '2025-01-15', '2025-01-01',  0.000, 'Logo frente camisa titular + reserva, naming rights CT, área VIP 10 pessoas', 'confirmado', 'Reajuste de 12.5%.'),
(4, 'patrocinio', 'Patrocínio master camisa 2026 — Apex',                   600000.00, '2026-01-10', '2026-01-01',  0.000, 'Logo frente camisa + naming CT + camarote 10 lugares + redes sociais', 'confirmado', 'Reajuste de 11.1%.'),

-- Farmácias Saúde Total (patrocinador ouro)
(5, 'patrocinio', 'Patrocínio cota ouro 2025 — Saúde Total',               180000.00, '2025-02-01', '2025-02-01',  0.000, 'Faixa de publicidade estádio + 4 ingressos por jogo + redes sociais', 'confirmado', NULL),
(5, 'patrocinio', 'Patrocínio cota ouro 2026 — Saúde Total',               200000.00, '2026-02-01', '2026-02-01',  0.000, 'Faixa publicidade + logo no aquecimento + 6 ingressos por jogo', 'confirmado', NULL),

-- Auto Peças Rodrigues (patrocinador local)
(6, 'patrocinio', 'Patrocínio cota prata 2026 — Rodrigues Peças',           60000.00, '2026-01-20', '2026-01-01',  0.000, 'Logo no uniforme de treino + 2 ingressos por jogo + post no Instagram mensal', 'confirmado', NULL),

-- Ricardo Fontes (investidor financeiro)
(7, 'emprestimo', 'Empréstimo para contratação de atletas — jan/2025',      400000.00, '2025-01-20', '2025-01-01',  0.000, NULL, 'confirmado', 'Taxa: 10% a.a. Prazo: 24 meses. Vencimento jan/2027.'),
(7, 'emprestimo', 'Empréstimo complementar — reforços mid-2025',            200000.00, '2025-07-10', '2025-07-01',  0.000, NULL, 'confirmado', 'Taxa: 10% a.a. Prazo: 18 meses. Vencimento jan/2027.'),

-- Fundo Esporte Capital (investidor — empréstimo conversível)
(8, 'emprestimo', 'Empréstimo conversível — Fundo Esporte Capital',        1000000.00, '2024-06-01', '2024-06-01',  0.000, NULL, 'confirmado', 'Conversível em equity (até 5%) ao final. Taxa: 8% a.a. Prazo: 36 meses.'),

-- Dr. Henrique (mecenas / doador)
(9, 'doacao', 'Doação — equipamentos médicos para CT',                       45000.00, '2024-03-15', '2024-03-01',  0.000, NULL, 'confirmado', 'Doação de equipamentos fisioterapia.'),
(9, 'doacao', 'Doação — patrocínio categorias de base 2025',                 30000.00, '2025-01-05', '2025-01-01',  0.000, NULL, 'confirmado', 'Custeio de alimentação e transporte das categorias de base.'),
(9, 'doacao', 'Doação — fundo médico 2026',                                  20000.00, '2026-01-03', '2026-01-01',  0.000, NULL, 'confirmado', NULL);

-- Atualizar taxa de juros e vencimento dos empréstimos
UPDATE aportes SET taxa_juros_anual = 10.00, data_vencimento = '2027-01-20' WHERE id = 15;
UPDATE aportes SET taxa_juros_anual = 10.00, data_vencimento = '2027-01-10' WHERE id = 16;
UPDATE aportes SET taxa_juros_anual =  8.00, data_vencimento = '2027-06-01' WHERE id = 17;

-- Simula devolução parcial do empréstimo do Ricardo Fontes
UPDATE aportes SET valor_devolvido = 120000.00 WHERE id = 15;

-- ------------------------------------------------------------
-- RETORNOS AOS INVESTIDORES
-- ------------------------------------------------------------
INSERT INTO retornos_investidor (investidor_id, aporte_id, tipo, descricao, valor, data_pagamento, competencia, status) VALUES

-- Dividendos para sócios (fim de 2024 — resultado positivo)
(1, 1, 'dividendo', 'Distribuição de resultado — 2024 (25% do lucro líquido)', 125000.00, '2025-01-31', '2024-12-01', 'pago'),
(2, 4, 'dividendo', 'Distribuição de resultado — 2024 (20% do lucro líquido)', 100000.00, '2025-01-31', '2024-12-01', 'pago'),
(3, 7, 'dividendo', 'Distribuição de resultado — 2024 (8% do lucro líquido)',   40000.00, '2025-01-31', '2024-12-01', 'pago'),

-- Juros empréstimos Ricardo Fontes (2025)
(7, 15, 'juros', 'Juros empréstimo — jan a jun/2025 (10% a.a.)',  20000.00, '2025-07-10', '2025-06-01', 'pago'),
(7, 15, 'juros', 'Juros empréstimo — jul a dez/2025 (10% a.a.)', 22000.00, '2026-01-10', '2025-12-01', 'pago'),
(7, 16, 'juros', 'Juros empréstimo complementar — jul a dez/2025', 10000.00,'2026-01-10', '2025-12-01', 'pago'),

-- Juros Fundo Esporte Capital (2025)
(8, 17, 'juros', 'Juros empréstimo conversível — 2025 (8% a.a.)', 80000.00, '2026-01-31', '2025-12-01', 'pago'),

-- Dividendos 2025 para sócios (PENDENTES — aguardando fechamento)
(1, 1, 'dividendo', 'Distribuição parcial resultado — 1º semestre 2026', 80000.00, '2026-07-31', '2026-06-01', 'pendente'),
(2, 4, 'dividendo', 'Distribuição parcial resultado — 1º semestre 2026', 64000.00, '2026-07-31', '2026-06-01', 'pendente'),
(3, 7, 'dividendo', 'Distribuição parcial resultado — 1º semestre 2026', 25600.00, '2026-07-31', '2026-06-01', 'pendente'),

-- Juros Ricardo Fontes (2026 — pendentes)
(7, 15, 'juros', 'Juros empréstimo — jan a jun/2026 (10% a.a.)',  22000.00, '2026-07-10', '2026-06-01', 'pendente'),
(7, 16, 'juros', 'Juros empréstimo complementar — jan a jun/2026', 10000.00,'2026-07-10', '2026-06-01', 'pendente');
-- ============================================================
-- SEED: METAS — Dados de Demonstração
-- ERP SAF — Temporada 2026
-- ============================================================

-- ------------------------------------------------------------
-- METAS ESPORTIVAS
-- ------------------------------------------------------------
INSERT INTO metas
    (titulo, descricao, tipo, categoria, temporada, valor_meta, valor_atual,
     unidade, sentido, data_inicio, data_fim, status, prioridade, observacoes)
VALUES

-- PRINCIPAL: ACESSO À SÉRIE A
(
    'Acesso à Série A 2027',
    'Terminar a Série B 2026 entre os 4 primeiros colocados para garantir o acesso à Série A do Brasileirão.',
    'esportiva', 'classificacao', '2026',
    4, 6,    -- meta: top 4 | atual: 6º lugar
    'posição', 'abaixo',
    '2026-04-12', '2026-11-29',
    'ativa', 'alta',
    'A temporada começou bem, mas precisamos subir mais 2 posições. 28 rodadas ainda pela frente.'
),

-- PONTUAÇÃO
(
    'Atingir 65 pontos na Série B',
    'Acumular pelo menos 65 pontos na Série B para garantir o acesso com tranquilidade.',
    'esportiva', 'pontuacao', '2026',
    65, 18,
    'pontos', 'acima',
    '2026-04-12', '2026-11-29',
    'ativa', 'alta',
    '10 rodadas disputadas. Média atual: 1,8 pts/jogo. Precisamos manter ritmo.'
),

-- APROVEITAMENTO
(
    'Aproveitamento mínimo de 60%',
    'Manter aproveitamento acima de 60% ao longo de toda a Série B.',
    'esportiva', 'aproveitamento', '2026',
    60, 60,
    '%', 'acima',
    '2026-04-12', '2026-11-29',
    'ativa', 'media',
    '6 vitórias, 0 empates, 4 derrotas nas 10 primeiras rodadas = 60% de aproveitamento.'
),

-- VITÓRIAS
(
    'Mínimo de 20 vitórias na Série B',
    'Vencer pelo menos 20 jogos ao longo das 38 rodadas.',
    'esportiva', 'vitorias', '2026',
    20, 6,
    'vitórias', 'acima',
    '2026-04-12', '2026-11-29',
    'ativa', 'media',
    NULL
),

-- GOLS SOFRIDOS (meta: abaixo de X)
(
    'Sofrer menos de 30 gols na temporada',
    'Manter a defesa sólida com menos de 30 gols sofridos em toda a Série B.',
    'esportiva', 'gols_sofridos', '2026',
    30, 12,
    'gols sofridos', 'abaixo',
    '2026-04-12', '2026-11-29',
    'ativa', 'media',
    '10 rodadas: 12 gols sofridos. Ritmo atual projetaria 45 ao final. Precisa melhorar.'
),

-- CLEAN SHEETS
(
    'Mínimo de 12 jogos sem sofrer gol',
    'Conquistar pelo menos 12 clean sheets na temporada entre todas as competições.',
    'esportiva', 'clean_sheets', '2026',
    12, 8,
    'clean sheets', 'acima',
    '2026-01-01', '2026-11-29',
    'ativa', 'media',
    'Ricardo já tem 8 clean sheets em 13 jogos. Ritmo excelente!'
),

-- ARTILHEIRO (meta individual — Alemão)
(
    'Alemão: 20 gols na temporada',
    'Alexandre "Alemão" Costa atingir a marca de 20 gols considerando todas as competições em 2026.',
    'esportiva', 'artilheiro', '2026',
    20, 12,
    'gols', 'acima',
    '2026-01-01', '2026-11-29',
    'ativa', 'alta',
    '12 gols em 13 jogos. Ritmo impressionante — lidera a artilharia da Série B.'
),

-- TITULO COPA
(
    'Avançar às quartas de final da Copa do Brasil',
    'Chegar pelo menos às quartas de final da Copa do Brasil 2026.',
    'esportiva', 'titulo', '2026',
    1, 1,
    'fase', 'acima',
    '2026-01-01', '2026-08-31',
    'ativa', 'media',
    'Já avançamos para as oitavas. Meta mínima quase atingida.'
),

-- REVELAÇÃO DA BASE
(
    'Promover 2 atletas da base ao profissional',
    'Revelar e promover pelo menos 2 atletas das categorias de base para o elenco profissional em 2026.',
    'institucional', 'formacao', '2026',
    2, 1,
    'atletas', 'acima',
    '2026-01-01', '2026-12-31',
    'ativa', 'media',
    'Lukinha já foi promovido. Mateuzinho em observação.'
),

-- PÚBLICO
(
    'Média de 8.000 torcedores por jogo',
    'Alcançar média de público acima de 8.000 pagantes nos jogos como mandante na Série B.',
    'institucional', 'publico', '2026',
    8000, 6800,
    'torcedores', 'acima',
    '2026-04-12', '2026-11-29',
    'ativa', 'baixa',
    '5 jogos em casa. Média atual: 6.800. Crescimento em relação a 2025 (+15%).'
);

-- ------------------------------------------------------------
-- METAS FINANCEIRAS
-- ------------------------------------------------------------
INSERT INTO metas
    (titulo, descricao, tipo, categoria, temporada, valor_meta, valor_atual,
     unidade, sentido, data_inicio, data_fim, status, prioridade, observacoes)
VALUES

-- RECEITA TOTAL
(
    'Receita total de R$ 12M em 2026',
    'Atingir receita total de R$ 12 milhões somando patrocínios, bilheteria, direitos de TV, premiações e vendas.',
    'financeira', 'receita', '2026',
    12000000, 4800000,
    'R$', 'acima',
    '2026-01-01', '2026-12-31',
    'ativa', 'alta',
    'Março/2026: R$ 4,8M (40% da meta em 3 meses). Ritmo adequado.'
),

-- CAPTAÇÃO DE PATROCÍNIO
(
    'Captar R$ 1,5M em patrocínios em 2026',
    'Fechar novos contratos de patrocínio totalizando pelo menos R$ 1,5 milhão no ano.',
    'financeira', 'patrocinio', '2026',
    1500000, 860000,
    'R$', 'acima',
    '2026-01-01', '2026-12-31',
    'ativa', 'alta',
    'Apex R$600k + Saúde Total R$200k + Rodrigues R$60k = R$860k. Faltam R$640k.'
),

-- FOLHA DE PAGAMENTO
(
    'Folha de atletas abaixo de R$ 380k/mês',
    'Manter a folha total de atletas dentro do limite orçamentário de R$ 380 mil por mês.',
    'financeira', 'folha_limite', '2026',
    380000, 312000,
    'R$/mês', 'abaixo',
    '2026-01-01', '2026-12-31',
    'ativa', 'alta',
    'Folha atual: R$ 312k. Meta cumprida com folga. Atenção às renovações em curso.'
),

-- REDUÇÃO DE CUSTOS OPERACIONAIS
(
    'Reduzir custos operacionais em 10% vs 2025',
    'Reduzir despesas operacionais (excluindo folha) em 10% comparado ao exercício de 2025.',
    'financeira', 'reducao_custos', '2026',
    10, 6,
    '%', 'acima',
    '2026-01-01', '2026-12-31',
    'ativa', 'media',
    '6% de redução atingida até março. Negociações com fornecedores em andamento.'
),

-- CAPTAÇÃO DE INVESTIMENTO
(
    'Captar R$ 1M em novos aportes de sócios',
    'Atrair novos sócios investidores ou aportes adicionais dos sócios atuais totalizando R$ 1 milhão.',
    'financeira', 'captacao', '2026',
    1000000, 700000,
    'R$', 'acima',
    '2026-01-01', '2026-12-31',
    'ativa', 'alta',
    'Grupo Vitória aportou R$700k em janeiro. Negociação com novo sócio em andamento.'
),

-- RESULTADO FINANCEIRO (LUCRO)
(
    'Resultado operacional positivo em 2026',
    'Fechar 2026 com superávit operacional — receitas superando despesas operacionais.',
    'financeira', 'lucro', '2026',
    1, 1,
    'superávit', 'acima',
    '2026-01-01', '2026-12-31',
    'ativa', 'alta',
    'Projeção positiva se o acesso ocorrer (premiação + aumento de receitas).'
);

-- ------------------------------------------------------------
-- ATUALIZAÇÕES DE PROGRESSO (histórico)
-- ------------------------------------------------------------
INSERT INTO atualizacoes_meta (meta_id, valor_anterior, valor_novo, descricao) VALUES
-- Meta 1: Classificação
(1,  8,  7, 'Rodada 7 — vitória 2x1. Subimos uma posição.'),
(1,  7,  6, 'Rodada 10 — vitória 3x0. 6º lugar.'),

-- Meta 2: Pontuação
(2,  0,  6,  'Rodadas 1-3: 2V, 0E, 1D = 6 pts'),
(2,  6, 12, 'Rodadas 4-6: 2V, 0E, 1D = 6 pts'),
(2, 12, 18, 'Rodadas 7-10: 2V, 0E, 2D = 6 pts'),

-- Meta 7: Artilheiro (Alemão)
(7,  0,  4,  'Fevereiro — 4 gols na Série B'),
(7,  4,  8,  'Fevereiro — 4 gols na Copa do Brasil'),
(7,  8, 12,  'Março — 4 gols na Série B. Total: 12 gols em 13 jogos!'),

-- Meta 11: Receita
(11, 0,       1600000, 'Janeiro 2026 — aportes + patrocínio master Apex'),
(11, 1600000, 3200000, 'Fevereiro — patrocínios + bilheteria + cotas TV'),
(11, 3200000, 4800000, 'Março — premiação Copa do Brasil + patrocínios'),

-- Meta 12: Patrocínio
(12, 0,      600000, 'Contrato Apex Construções assinado — R$600k'),
(12, 600000, 800000, 'Saúde Total cota ouro — R$200k'),
(12, 800000, 860000, 'Rodrigues Peças cota prata — R$60k');
-- ============================================================
-- SEED — MÓDULO 8: AGENDA DE JOGOS
-- ============================================================

-- ─── Templates de orçamento ──────────────────────────────────

-- Template: Jogo em casa (mandante)
INSERT INTO templates_orcamento_jogo (nome, tipo_jogo, competicao) VALUES
('Padrão Mandante - Série B',   'mandante',  'Série B'),
('Padrão Visitante - Série B',  'visitante', 'Série B'),
('Padrão Mandante - Copa',      'mandante',  'Copa do Brasil'),
('Padrão Visitante - Copa',     'visitante', 'Copa do Brasil')
ON CONFLICT DO NOTHING;

-- Itens do template mandante Série B (id=1)
INSERT INTO itens_template_orcamento (template_id, categoria, descricao, valor_padrao, obrigatorio, ordem) VALUES
(1, 'Arbitragem',    'Taxa de arbitragem CBF',                  3500.00,  TRUE,  1),
(1, 'Segurança',     'Segurança privada (30 agentes)',           4800.00,  TRUE,  2),
(1, 'Segurança',     'Policiamento militar (taxa)',              1200.00,  TRUE,  3),
(1, 'Operacional',   'Bilheteiros e porteiros',                 2400.00,  TRUE,  4),
(1, 'Operacional',   'Equipe de campo (gramado, redes)',         800.00,  TRUE,  5),
(1, 'Operacional',   'Limpeza e higienização',                  1200.00,  TRUE,  6),
(1, 'Operacional',   'Médico e fisioterapeuta de plantão',       600.00,  TRUE,  7),
(1, 'Comunicação',   'Assessoria de imprensa',                   900.00, FALSE,  8),
(1, 'Comunicação',   'Transmissão ao vivo (produção)',          2500.00, FALSE,  9),
(1, 'Hospedagem',    'Hotel adversário (delegação)',            3200.00,  TRUE, 10),
(1, 'Alimentação',   'Refeição elenco e comissão',               960.00,  TRUE, 11),
(1, 'Outros',        'Premiação de campo (bola, material)',       350.00, FALSE, 12)
ON CONFLICT DO NOTHING;

-- Itens do template visitante Série B (id=2)
INSERT INTO itens_template_orcamento (template_id, categoria, descricao, valor_padrao, obrigatorio, ordem) VALUES
(2, 'Transporte',    'Ônibus fretado (ida e volta)',            3800.00,  TRUE,  1),
(2, 'Hospedagem',    'Hotel delegação (15 apartamentos)',       6500.00,  TRUE,  2),
(2, 'Alimentação',   'Diárias de alimentação (2 dias)',         2400.00,  TRUE,  3),
(2, 'Arbitragem',    'Taxa visitante CBF',                       800.00,  TRUE,  4),
(2, 'Operacional',   'Médico e fisio em deslocamento',           600.00,  TRUE,  5),
(2, 'Outros',        'Seguros e taxas diversas',                 500.00, FALSE,  6)
ON CONFLICT DO NOTHING;

-- Itens do template mandante Copa (id=3)
INSERT INTO itens_template_orcamento (template_id, categoria, descricao, valor_padrao, obrigatorio, ordem) VALUES
(3, 'Arbitragem',    'Taxa de arbitragem CBF - Copa',           4200.00,  TRUE,  1),
(3, 'Segurança',     'Segurança reforçada Copa',                6500.00,  TRUE,  2),
(3, 'Segurança',     'Policiamento militar',                    1800.00,  TRUE,  3),
(3, 'Operacional',   'Bilheteiros e porteiros',                 2800.00,  TRUE,  4),
(3, 'Operacional',   'Limpeza e higienização',                  1500.00,  TRUE,  5),
(3, 'Comunicação',   'Transmissão CBF TV',                      3500.00,  TRUE,  6),
(3, 'Hospedagem',    'Hotel adversário delegação',              4200.00,  TRUE,  7),
(3, 'Alimentação',   'Refeição elenco',                         1200.00,  TRUE,  8),
(3, 'Outros',        'Premiação e material CBF',                 600.00, FALSE,  9)
ON CONFLICT DO NOTHING;

-- Itens do template visitante Copa (id=4)
INSERT INTO itens_template_orcamento (template_id, categoria, descricao, valor_padrao, obrigatorio, ordem) VALUES
(4, 'Transporte',    'Passagens aéreas delegação',              18000.00, TRUE,  1),
(4, 'Hospedagem',    'Hotel delegação (2 noites)',               9800.00, TRUE,  2),
(4, 'Alimentação',   'Diárias e refeições viagem',               3200.00, TRUE,  3),
(4, 'Arbitragem',    'Taxa visitante CBF - Copa',                1200.00, TRUE,  4),
(4, 'Operacional',   'Equipe médica deslocamento',                900.00, TRUE,  5),
(4, 'Outros',        'Seguros, taxas e imprevistos',             1000.00, TRUE,  6)
ON CONFLICT DO NOTHING;

-- ─── Jogos ───────────────────────────────────────────────────
-- Jogos já realizados (passado)
INSERT INTO jogos (competicao, rodada, adversario, data_jogo, local_jogo, tipo_jogo, status,
                   gols_nos, gols_adversario, capacidade_estadio, publico_pagante, publico_cortesias,
                   transmissao_tv, transmissao_streaming)
VALUES
('Série B', 'Rodada 1',  'Atlético Goianiense',  '2026-01-18 16:00', 'Estádio Municipal', 'mandante', 'realizado', 2, 1, 18000, 6800,  420, TRUE,  TRUE),
('Série B', 'Rodada 2',  'CRB',                   '2026-01-25 11:00', 'Estádio Rei Pelé',  'visitante','realizado', 1, 1, 30000,  0,      0,  TRUE,  FALSE),
('Série B', 'Rodada 3',  'Guarani',               '2026-02-01 18:30', 'Estádio Municipal', 'mandante', 'realizado', 3, 0, 18000, 7200,  380, FALSE, TRUE),
('Série B', 'Rodada 4',  'Ponte Preta',           '2026-02-08 16:00', 'Moisés Lucarelli',  'visitante','realizado', 0, 2, 20000,  0,      0,  FALSE, FALSE),
('Série B', 'Rodada 5',  'Vila Nova',             '2026-02-15 11:00', 'Estádio Municipal', 'mandante', 'realizado', 1, 0, 18000, 5900,  310, TRUE,  TRUE),
('Copa do Brasil', 'Primeira Fase', 'Madureira EC','2026-01-28 19:00', 'Estádio Municipal', 'mandante', 'realizado', 4, 1, 18000, 4200,  600, FALSE, TRUE),
('Copa do Brasil', 'Segunda Fase', 'Fluminense',  '2026-02-19 21:30', 'Maracanã',          'visitante','realizado', 1, 2, 78000,  0,      0,  TRUE,  TRUE),
('Série B', 'Rodada 6',  'Ituano',                '2026-02-22 16:00', 'Estádio Municipal', 'mandante', 'realizado', 2, 2, 18000, 6100,  290, FALSE, TRUE)
ON CONFLICT DO NOTHING;

-- Jogos futuros confirmados / agendados
INSERT INTO jogos (competicao, rodada, adversario, data_jogo, local_jogo, tipo_jogo, status,
                   capacidade_estadio, transmissao_tv, transmissao_streaming)
VALUES
('Série B', 'Rodada 9',  'Operário PR',  '2026-03-22 16:00', 'Estádio Municipal',     'mandante',  'confirmado', 18000, TRUE,  TRUE),
('Série B', 'Rodada 10', 'Mirassol',     '2026-03-29 11:00', 'Estádio Municipal Lins', 'visitante', 'agendado',   12000, FALSE, FALSE),
('Série B', 'Rodada 11', 'Amazonas FC',  '2026-04-05 18:30', 'Estádio Municipal',      'mandante',  'agendado',   18000, FALSE, TRUE),
('Série B', 'Rodada 12', 'Novorizontino','2026-04-12 16:00', 'Jorge Ismael de Biasi',  'visitante', 'agendado',   17000, FALSE, FALSE),
('Série B', 'Rodada 13', 'Chapecoense',  '2026-04-19 11:00', 'Estádio Municipal',      'mandante',  'agendado',   18000, TRUE,  TRUE),
('Série B', 'Rodada 14', 'Avaí',         '2026-04-26 18:30', 'Avaí',                   'visitante', 'agendado',   22000, FALSE, FALSE),
('Série B', 'Rodada 15', 'Sport',        '2026-05-03 16:00', 'Estádio Municipal',       'mandante',  'agendado',  18000, TRUE,  TRUE)
ON CONFLICT DO NOTHING;

-- ─── Orçamentos dos jogos realizados ─────────────────────────
-- Jogo 1: Mandante Série B (rodada 1)
INSERT INTO orcamentos_jogo (jogo_id, status) VALUES (1, 'realizado') ON CONFLICT DO NOTHING;
INSERT INTO itens_orcamento_jogo (orcamento_id, categoria, descricao, valor_estimado, valor_realizado, pago, ordem) VALUES
(1, 'Arbitragem',  'Taxa CBF arbitragem',           3500, 3500,  TRUE, 1),
(1, 'Segurança',   'Segurança privada',              4800, 5100,  TRUE, 2),
(1, 'Segurança',   'Policiamento militar',           1200, 1200,  TRUE, 3),
(1, 'Operacional', 'Bilheteiros e porteiros',        2400, 2400,  TRUE, 4),
(1, 'Operacional', 'Equipe de campo',                 800,  800,  TRUE, 5),
(1, 'Operacional', 'Limpeza',                        1200, 1100,  TRUE, 6),
(1, 'Operacional', 'Médico de plantão',               600,  600,  TRUE, 7),
(1, 'Comunicação', 'Produção transmissão',           2500, 2800,  TRUE, 8),
(1, 'Hospedagem',  'Hotel adversário',               3200, 3200,  TRUE, 9),
(1, 'Alimentação', 'Refeição elenco',                 960, 1040,  TRUE,10)
ON CONFLICT DO NOTHING;

-- Jogo 2: Visitante Série B (rodada 2)
INSERT INTO orcamentos_jogo (jogo_id, status) VALUES (2, 'realizado') ON CONFLICT DO NOTHING;
INSERT INTO itens_orcamento_jogo (orcamento_id, categoria, descricao, valor_estimado, valor_realizado, pago, ordem) VALUES
(2, 'Transporte',  'Ônibus fretado',   3800, 3800, TRUE, 1),
(2, 'Hospedagem',  'Hotel delegação',  6500, 6200, TRUE, 2),
(2, 'Alimentação', 'Diárias',          2400, 2550, TRUE, 3),
(2, 'Arbitragem',  'Taxa visitante',    800,  800, TRUE, 4),
(2, 'Operacional', 'Médico/fisio',      600,  600, TRUE, 5)
ON CONFLICT DO NOTHING;

-- Jogo 3: Mandante (rodada 3)
INSERT INTO orcamentos_jogo (jogo_id, status) VALUES (3, 'realizado') ON CONFLICT DO NOTHING;
INSERT INTO itens_orcamento_jogo (orcamento_id, categoria, descricao, valor_estimado, valor_realizado, pago, ordem) VALUES
(3, 'Arbitragem',  'Taxa CBF',          3500, 3500, TRUE, 1),
(3, 'Segurança',   'Segurança privada', 4800, 4800, TRUE, 2),
(3, 'Segurança',   'Policiamento',      1200, 1200, TRUE, 3),
(3, 'Operacional', 'Bilheteiros',       2400, 2400, TRUE, 4),
(3, 'Operacional', 'Equipe campo',       800,  800, TRUE, 5),
(3, 'Hospedagem',  'Hotel adversário',  3200, 3200, TRUE, 6),
(3, 'Alimentação', 'Refeição',           960,  960, TRUE, 7)
ON CONFLICT DO NOTHING;

-- Jogo 9 (próximo): Orçamento aprovado
INSERT INTO orcamentos_jogo (jogo_id, status) VALUES (9, 'aprovado') ON CONFLICT DO NOTHING;
INSERT INTO itens_orcamento_jogo (orcamento_id, categoria, descricao, valor_estimado, pago, ordem) VALUES
(4, 'Arbitragem',  'Taxa CBF arbitragem',    3500, FALSE, 1),
(4, 'Segurança',   'Segurança privada',       4800, FALSE, 2),
(4, 'Segurança',   'Policiamento militar',    1200, FALSE, 3),
(4, 'Operacional', 'Bilheteiros e porteiros', 2400, FALSE, 4),
(4, 'Operacional', 'Equipe de campo',          800, FALSE, 5),
(4, 'Operacional', 'Limpeza',                 1200, FALSE, 6),
(4, 'Comunicação', 'Produção transmissão',    2500, FALSE, 7),
(4, 'Hospedagem',  'Hotel adversário',        3200, FALSE, 8),
(4, 'Alimentação', 'Refeição elenco',          960, FALSE, 9)
ON CONFLICT DO NOTHING;

-- ─── Receitas dos jogos realizados ───────────────────────────
-- Jogo 1
INSERT INTO receitas_jogo (jogo_id, tipo, descricao, quantidade, valor_unitario, valor_total, realizado) VALUES
(1, 'bilheteria_inteira', 'Ingresso inteira',    3200, 40.00, 128000, TRUE),
(1, 'bilheteria_meia',    'Ingresso meia-entrada',2400, 20.00,  48000, TRUE),
(1, 'bilheteria_socio',   'Sócio-torcedor',      1200,  0.00,       0, TRUE),
(1, 'patrocinio_jogo',    'Patrocínio Apex jogo',   1,     0, 25000,  TRUE),
(1, 'cota_tv',            'Cota transmissão',       1,     0, 18000,  TRUE),
(1, 'alimentacao',        'Alimentação/bebidas',    1,     0,  4200,  TRUE),
(1, 'estacionamento',     'Estacionamento',         1,     0,  3100,  TRUE)
ON CONFLICT DO NOTHING;

-- Jogo 3 (goleada em casa)
INSERT INTO receitas_jogo (jogo_id, tipo, descricao, quantidade, valor_unitario, valor_total, realizado) VALUES
(3, 'bilheteria_inteira', 'Ingresso inteira',    3600, 40.00, 144000, TRUE),
(3, 'bilheteria_meia',    'Ingresso meia-entrada',2600, 20.00,  52000, TRUE),
(3, 'bilheteria_socio',   'Sócio-torcedor',      1000,  0.00,       0, TRUE),
(3, 'patrocinio_jogo',    'Patrocínio Apex jogo',   1,     0, 25000,  TRUE),
(3, 'alimentacao',        'Alimentação/bebidas',    1,     0,  5100,  TRUE),
(3, 'estacionamento',     'Estacionamento',         1,     0,  3600,  TRUE)
ON CONFLICT DO NOTHING;

-- Jogo 5 (mandante)
INSERT INTO receitas_jogo (jogo_id, tipo, descricao, quantidade, valor_unitario, valor_total, realizado) VALUES
(5, 'bilheteria_inteira', 'Ingresso inteira',    2800, 40.00, 112000, TRUE),
(5, 'bilheteria_meia',    'Ingresso meia-entrada',2100, 20.00,  42000, TRUE),
(5, 'bilheteria_socio',   'Sócio-torcedor',      1000,  0.00,       0, TRUE),
(5, 'patrocinio_jogo',    'Patrocínio jogo',        1,     0, 22000,  TRUE),
(5, 'cota_tv',            'Cota transmissão',       1,     0, 18000,  TRUE),
(5, 'alimentacao',        'Alimentação',            1,     0,  3800,  TRUE)
ON CONFLICT DO NOTHING;

-- Jogo 6 (Copa do Brasil - mandante)
INSERT INTO receitas_jogo (jogo_id, tipo, descricao, quantidade, valor_unitario, valor_total, realizado) VALUES
(6, 'bilheteria_inteira', 'Ingresso inteira',   2000, 50.00, 100000, TRUE),
(6, 'bilheteria_meia',    'Ingresso meia',       1400, 25.00,  35000, TRUE),
(6, 'bilheteria_socio',   'Sócio-torcedor',       800,  0.00,      0, TRUE),
(6, 'cota_tv',            'Cota CBF - Copa',        1,     0, 32000,  TRUE),
(6, 'alimentacao',        'Alimentação',            1,     0,  2900,  TRUE)
ON CONFLICT DO NOTHING;

-- Jogo 8 (mandante rodada 6)
INSERT INTO receitas_jogo (jogo_id, tipo, descricao, quantidade, valor_unitario, valor_total, realizado) VALUES
(8, 'bilheteria_inteira', 'Ingresso inteira',    2900, 40.00, 116000, TRUE),
(8, 'bilheteria_meia',    'Ingresso meia',        2200, 20.00,  44000, TRUE),
(8, 'bilheteria_socio',   'Sócio-torcedor',       1000,  0.00,      0, TRUE),
(8, 'patrocinio_jogo',    'Patrocínio jogo',         1,     0, 25000, TRUE),
(8, 'alimentacao',        'Alimentação',             1,     0,  4100, TRUE)
ON CONFLICT DO NOTHING;

-- Receitas estimadas para jogo 9 (próximo)
INSERT INTO receitas_jogo (jogo_id, tipo, descricao, quantidade, valor_unitario, valor_total, realizado) VALUES
(9, 'bilheteria_inteira', 'Ingresso inteira (estimado)',    3000, 40.00, 120000, FALSE),
(9, 'bilheteria_meia',    'Ingresso meia (estimado)',        2200, 20.00,  44000, FALSE),
(9, 'bilheteria_socio',   'Sócio-torcedor (estimado)',       1100,  0.00,      0, FALSE),
(9, 'patrocinio_jogo',    'Patrocínio Apex',                    1,     0, 25000, FALSE),
(9, 'cota_tv',            'Cota transmissão',                   1,     0, 18000, FALSE)
ON CONFLICT DO NOTHING;

-- ─── Gols dos jogos realizados ────────────────────────────────
-- Jogo 1 (2x1): gols id atleta 1=Thiago Alemão, 2=Lucas, adversário
INSERT INTO gols_jogo (jogo_id, atleta_id, minuto, tipo, time) VALUES
(1, 1, 23, 'normal',  'nos'),
(1, 2, 67, 'normal',  'nos'),
(1, NULL, 80, 'normal','adversario')
ON CONFLICT DO NOTHING;

-- Jogo 3 (3x0)
INSERT INTO gols_jogo (jogo_id, atleta_id, minuto, tipo, time) VALUES
(3, 1, 12, 'normal',  'nos'),
(3, 1, 45, 'penalti', 'nos'),
(3, 3, 78, 'normal',  'nos')
ON CONFLICT DO NOTHING;

-- Jogo 5 (1x0)
INSERT INTO gols_jogo (jogo_id, atleta_id, minuto, tipo, time) VALUES
(5, 2, 55, 'normal', 'nos')
ON CONFLICT DO NOTHING;

-- Jogo 6 Copa (4x1)
INSERT INTO gols_jogo (jogo_id, atleta_id, minuto, tipo, time) VALUES
(6, 1, 8,  'normal', 'nos'),
(6, 1, 34, 'normal', 'nos'),
(6, 4, 56, 'cabeca', 'nos'),
(6, 3, 72, 'normal', 'nos'),
(6, NULL, 88, 'normal', 'adversario')
ON CONFLICT DO NOTHING;

-- Jogo 8 (2x2)
INSERT INTO gols_jogo (jogo_id, atleta_id, minuto, tipo, time) VALUES
(8, 2, 31, 'normal',  'nos'),
(8, 1, 65, 'penalti', 'nos'),
(8, NULL, 50, 'normal','adversario'),
(8, NULL, 88, 'normal','adversario')
ON CONFLICT DO NOTHING;
