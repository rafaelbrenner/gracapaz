-- Tabela para armazenar o estado da conversa do bot
CREATE TABLE bot_estados (
    id SERIAL PRIMARY KEY,
    telefone TEXT UNIQUE NOT NULL,
    estado TEXT NOT NULL,
    nome TEXT,
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW()
);

-- Trigger para atualizar o campo 'atualizado_em' automaticamente
CREATE OR REPLACE FUNCTION update_atualizado_em_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_bot_estados_atualizado_em
BEFORE UPDATE ON bot_estados
FOR EACH ROW
EXECUTE FUNCTION update_atualizado_em_column();

-- Comentários para clareza
COMMENT ON TABLE bot_estados IS 'Armazena o estado atual da conversa de um usuário com o bot para evitar que o menu seja reenviado a cada mensagem.';
COMMENT ON COLUMN bot_estados.telefone IS 'Número do WhatsApp do usuário (ex: 5561999998888@s.whatsapp.net)';
COMMENT ON COLUMN bot_estados.estado IS 'O estado atual da conversa (ex: aguardando_equipe, aguardando_pastoral)';