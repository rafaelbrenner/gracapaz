-- Migration: converte hora_evento de VARCHAR(10) para TIME
-- Banco: evolution
-- Seguro executar mesmo se já for TIME (USING converte strings válidas como '19:00')
ALTER TABLE gp_escala
    ALTER COLUMN hora_evento TYPE TIME
    USING hora_evento::TIME;