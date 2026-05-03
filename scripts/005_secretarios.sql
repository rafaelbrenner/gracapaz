-- Tabela de usuários com acesso ao formulário de escala
-- Banco: evolution
CREATE TABLE IF NOT EXISTS secretarios (
    id           SERIAL PRIMARY KEY,
    nome         VARCHAR(100) NOT NULL,
    usuario      VARCHAR(50) UNIQUE NOT NULL,
    senha        TEXT NOT NULL,
    departamento VARCHAR(100),
    ativo        BOOLEAN DEFAULT true,
    criado_em    TIMESTAMP DEFAULT NOW()
);

-- Usuário inicial (troque a senha após o primeiro acesso)
INSERT INTO secretarios (nome, usuario, senha, departamento)
VALUES ('Administrador', 'admin', 'gracaepaz2026', 'Administração')
ON CONFLICT (usuario) DO NOTHING;
