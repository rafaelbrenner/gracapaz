-- Migration: adiciona FK de gp_escala.membro_codigo → gp_membros.codigo
-- Banco: evolution
-- Pré-requisito: limpar escalas com membro_codigo inválido antes de rodar:
--   DELETE FROM gp_escala WHERE membro_codigo IS NOT NULL
--     AND membro_codigo NOT IN (SELECT codigo FROM gp_membros);
ALTER TABLE gp_escala
    ADD CONSTRAINT fk_escala_membro
    FOREIGN KEY (membro_codigo)
    REFERENCES gp_membros(codigo)
    ON DELETE SET NULL;