-- Esquema de demostración: evita vinculación DIRECTA de identidad y selección.
-- No garantiza anonimato criptográfico ni protección ante administradores de DB.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_number VARCHAR(30) NOT NULL UNIQUE,
  full_name VARCHAR(160) NOT NULL,
  email VARCHAR(180) NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role VARCHAR(12) NOT NULL DEFAULT 'VOTER' CHECK(role IN ('VOTER','ADMIN')),
  enabled BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE IF NOT EXISTS elections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(200) NOT NULL,
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  status VARCHAR(12) NOT NULL DEFAULT 'OPEN' CHECK(status IN ('OPEN','CLOSED')),
  CHECK (ends_at > starts_at)
);
CREATE TABLE IF NOT EXISTS candidates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES elections(id),
  name VARCHAR(140) NOT NULL,
  proposal TEXT NOT NULL,
  UNIQUE(id, election_id)
);
CREATE TABLE IF NOT EXISTS participations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES elections(id),
  user_id UUID NOT NULL REFERENCES users(id),
  receipt_code VARCHAR(60) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(election_id, user_id)
);
CREATE TABLE IF NOT EXISTS ballots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES elections(id),
  candidate_id UUID NOT NULL,
  FOREIGN KEY (candidate_id, election_id) REFERENCES candidates(id, election_id)
  -- A propósito no guarda user_id, receipt_code ni created_at.
);
CREATE TABLE IF NOT EXISTS audit_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID REFERENCES users(id),
  action VARCHAR(80) NOT NULL,
  context JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- Evita modificaciones accidentales o maliciosas desde un rol de aplicación.
-- En producción se debe separar al rol propietario/migraciones del rol de la app.
CREATE OR REPLACE FUNCTION no_modificar_auditoria() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION 'audit_events es solo anexable'; END; $$;
DROP TRIGGER IF EXISTS audit_no_update ON audit_events;
CREATE TRIGGER audit_no_update BEFORE UPDATE OR DELETE ON audit_events
FOR EACH ROW EXECUTE FUNCTION no_modificar_auditoria();
