-- ============================================================
-- MIGRATION 001: Colunas de autenticação JWT
-- Executar UMA VEZ em produção após deploy
-- ============================================================

-- Colunas adicionadas para suporte a:
--   · refresh token (invalidação por hash)
--   · reset de senha (token temporário + expiração)
--   · controle de primeiro acesso
--   · audit trail (updated_at)

ALTER TABLE usuarios
  ADD COLUMN IF NOT EXISTS updated_at       TIMESTAMP,
  ADD COLUMN IF NOT EXISTS primeiro_acesso  BOOLEAN     NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS reset_token_hash VARCHAR(255),
  ADD COLUMN IF NOT EXISTS reset_token_exp  TIMESTAMP;

-- Índice para acelerar busca por reset_token_exp (limpeza de tokens expirados)
CREATE INDEX IF NOT EXISTS idx_usuarios_reset_exp
  ON usuarios(reset_token_exp)
  WHERE reset_token_exp IS NOT NULL;

-- Trigger: atualiza updated_at automaticamente na tabela usuarios
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'trg_usuarios_updated_at'
  ) THEN
    CREATE TRIGGER trg_usuarios_updated_at
    BEFORE UPDATE ON usuarios
    FOR EACH ROW EXECUTE FUNCTION atualizar_updated_at();
  END IF;
END $$;

-- Inicializa updated_at para registros existentes
UPDATE usuarios SET updated_at = created_at WHERE updated_at IS NULL;

-- ============================================================
-- TABELA: refresh_tokens (revogação por hash — opcional)
-- Permite invalidar refresh tokens individuais no logout
-- ============================================================
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id          SERIAL PRIMARY KEY,
  usuario_id  INTEGER      NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  token_hash  VARCHAR(255) NOT NULL UNIQUE,
  criado_em   TIMESTAMP    NOT NULL DEFAULT NOW(),
  expira_em   TIMESTAMP    NOT NULL,
  revogado    BOOLEAN      NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_usuario
  ON refresh_tokens(usuario_id);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expira
  ON refresh_tokens(expira_em)
  WHERE NOT revogado;

-- ============================================================
-- LIMPEZA: remove refresh tokens expirados (cron job / manual)
-- ============================================================
-- DELETE FROM refresh_tokens WHERE expira_em < NOW() OR revogado = true;

-- Add nome column to usuarios (used by auth routes)
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS nome VARCHAR(150);
-- Populate nome from linked funcionario
UPDATE usuarios u SET nome = (SELECT nome_completo FROM funcionarios f WHERE f.id = u.funcionario_id) WHERE u.funcionario_id IS NOT NULL AND u.nome IS NULL;
