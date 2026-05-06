-- ============================================================
-- ERP SAF — Schema: Módulo de Projetos / Kanban
-- ============================================================

-- ============================================================
-- TABELA: projetos
-- ============================================================
CREATE TABLE IF NOT EXISTS projetos (
  id          SERIAL PRIMARY KEY,
  nome        VARCHAR(200) NOT NULL,
  descricao   TEXT,
  status      VARCHAR(20)  NOT NULL DEFAULT 'ativo'
              CHECK (status IN ('ativo', 'pausado', 'concluido', 'cancelado')),
  cor         VARCHAR(7)   NOT NULL DEFAULT '#3B82F6',
  criado_por  INTEGER      REFERENCES usuarios(id),
  data_inicio DATE,
  data_fim    DATE,
  created_at  TIMESTAMP    NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_projetos_status ON projetos(status);

-- ============================================================
-- TABELA: epics
-- ============================================================
CREATE TABLE IF NOT EXISTS epics (
  id          SERIAL PRIMARY KEY,
  projeto_id  INTEGER      NOT NULL REFERENCES projetos(id) ON DELETE CASCADE,
  nome        VARCHAR(200) NOT NULL,
  descricao   TEXT,
  cor         VARCHAR(7)   NOT NULL DEFAULT '#8B5CF6',
  criado_por  INTEGER      REFERENCES usuarios(id),
  created_at  TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_epics_projeto ON epics(projeto_id);

-- ============================================================
-- TABELA: tarefas
-- ============================================================
CREATE TABLE IF NOT EXISTS tarefas (
  id              SERIAL PRIMARY KEY,
  projeto_id      INTEGER      NOT NULL REFERENCES projetos(id) ON DELETE CASCADE,
  epic_id         INTEGER      REFERENCES epics(id) ON DELETE SET NULL,
  titulo          VARCHAR(300) NOT NULL,
  descricao       TEXT,
  status          VARCHAR(20)  NOT NULL DEFAULT 'a_fazer'
                  CHECK (status IN ('a_fazer', 'em_andamento', 'em_revisao', 'concluido')),
  prioridade      VARCHAR(10)  NOT NULL DEFAULT 'media'
                  CHECK (prioridade IN ('baixa', 'media', 'alta', 'urgente')),
  responsavel_id  INTEGER      REFERENCES funcionarios(id) ON DELETE SET NULL,
  responsavel_nome VARCHAR(200),
  criado_por      INTEGER      REFERENCES usuarios(id),
  data_prazo      DATE,
  data_conclusao  DATE,
  posicao         INTEGER      NOT NULL DEFAULT 0,
  created_at      TIMESTAMP    NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tarefas_projeto     ON tarefas(projeto_id);
CREATE INDEX IF NOT EXISTS idx_tarefas_status      ON tarefas(status);
CREATE INDEX IF NOT EXISTS idx_tarefas_responsavel ON tarefas(responsavel_id);
CREATE INDEX IF NOT EXISTS idx_tarefas_epic        ON tarefas(epic_id);

-- ============================================================
-- TABELA: notificacoes
-- ============================================================
CREATE TABLE IF NOT EXISTS notificacoes (
  id          SERIAL PRIMARY KEY,
  usuario_id  INTEGER      NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  tarefa_id   INTEGER      REFERENCES tarefas(id) ON DELETE CASCADE,
  projeto_id  INTEGER      REFERENCES projetos(id) ON DELETE CASCADE,
  tipo        VARCHAR(30)  NOT NULL
              CHECK (tipo IN ('atribuicao', 'prazo_48h', 'prazo_vencido', 'movimento', 'conclusao')),
  mensagem    TEXT         NOT NULL,
  lida        BOOLEAN      NOT NULL DEFAULT false,
  created_at  TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notificacoes_usuario ON notificacoes(usuario_id);
CREATE INDEX IF NOT EXISTS idx_notificacoes_lida    ON notificacoes(usuario_id, lida);

-- ============================================================
-- TRIGGER: atualiza updated_at
-- ============================================================
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_projetos_updated_at'
  ) THEN
    CREATE TRIGGER trg_projetos_updated_at
      BEFORE UPDATE ON projetos
      FOR EACH ROW EXECUTE FUNCTION atualizar_updated_at();
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_tarefas_updated_at'
  ) THEN
    CREATE TRIGGER trg_tarefas_updated_at
      BEFORE UPDATE ON tarefas
      FOR EACH ROW EXECUTE FUNCTION atualizar_updated_at();
  END IF;
END $$;

-- ============================================================
-- VIEW: tarefas_completo
-- ============================================================
CREATE OR REPLACE VIEW tarefas_completo AS
SELECT
  t.id,
  t.projeto_id,
  p.nome           AS projeto_nome,
  p.cor            AS projeto_cor,
  t.epic_id,
  e.nome           AS epic_nome,
  e.cor            AS epic_cor,
  t.titulo,
  t.descricao,
  t.status,
  t.prioridade,
  t.responsavel_id,
  t.responsavel_nome,
  f.nome_completo  AS responsavel_nome_cadastro,
  f.cargo          AS responsavel_cargo,
  t.data_prazo,
  t.data_conclusao,
  t.posicao,
  t.criado_por,
  t.created_at,
  t.updated_at,
  CASE
    WHEN t.status != 'concluido' AND t.data_prazo < CURRENT_DATE THEN 'vencida'
    WHEN t.status != 'concluido' AND t.data_prazo = CURRENT_DATE THEN 'vence_hoje'
    WHEN t.status != 'concluido' AND t.data_prazo = CURRENT_DATE + 1 THEN 'vence_amanha'
    WHEN t.status != 'concluido' AND t.data_prazo <= CURRENT_DATE + 2 THEN 'prazo_48h'
    ELSE 'ok'
  END AS alerta_prazo
FROM tarefas t
JOIN projetos p ON p.id = t.projeto_id
LEFT JOIN epics e ON e.id = t.epic_id
LEFT JOIN funcionarios f ON f.id = t.responsavel_id;
