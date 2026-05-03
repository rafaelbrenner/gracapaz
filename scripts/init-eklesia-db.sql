-- ============================================================
-- Tabelas para integração Eklesia - Igreja Batista Graça e Paz
-- Executar no banco: evolution
-- ============================================================

-- Membros sincronizados do Eklesia
CREATE TABLE IF NOT EXISTS gp_membros (
    codigo          INTEGER PRIMARY KEY,
    nome            VARCHAR(255) NOT NULL,
    celular         VARCHAR(20),
    celular_whatsapp VARCHAR(20),
    email           VARCHAR(255),
    sexo            VARCHAR(20),
    arrolamento     VARCHAR(100),
    data_arrolamento DATE,
    igreja          VARCHAR(255),
    sincronizado_em TIMESTAMP DEFAULT NOW()
);

-- Escala de cultos/eventos
CREATE TABLE IF NOT EXISTS gp_escala (
    id              SERIAL PRIMARY KEY,
    membro_codigo   INTEGER REFERENCES gp_membros(codigo) ON DELETE SET NULL,
    membro_nome     VARCHAR(255) NOT NULL,
    celular_whatsapp VARCHAR(20) NOT NULL,
    funcao          VARCHAR(100) NOT NULL,
    evento          VARCHAR(255),
    data_evento     DATE NOT NULL,
    hora_evento     TIME,
    status          VARCHAR(20) DEFAULT 'pendente'
                    CHECK (status IN ('pendente', 'enviado', 'confirmado', 'recusado')),
    enviado_em      TIMESTAMP,
    criado_em       TIMESTAMP DEFAULT NOW(),
    criado_por      VARCHAR(100)
);

-- Índices para busca por nome (busca fuzzy)
CREATE INDEX IF NOT EXISTS idx_gp_membros_nome
    ON gp_membros USING gin(to_tsvector('portuguese', nome));

CREATE INDEX IF NOT EXISTS idx_gp_escala_status
    ON gp_escala(status);

CREATE INDEX IF NOT EXISTS idx_gp_escala_data
    ON gp_escala(data_evento);
