-- Tabela de estados do bot (contexto por usuário)
-- Executar no banco "n8n": psql -U root -d n8n -f criar-tabela-bot-estados.sql

CREATE TABLE IF NOT EXISTS bot_estados (
  telefone TEXT PRIMARY KEY,
  estado   TEXT NOT NULL,
  nome     TEXT,
  atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

-- Limpa estados antigos (> 24h) automaticamente via índice de expiração
CREATE INDEX IF NOT EXISTS idx_bot_estados_atualizado ON bot_estados (atualizado_em);

-- Limpeza manual de estados expirados (opcional, rodar via cron no N8N)
-- DELETE FROM bot_estados WHERE atualizado_em < NOW() - INTERVAL '24 hours';
