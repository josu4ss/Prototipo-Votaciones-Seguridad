import 'dotenv/config';
import * as argon2 from 'argon2';
import { Pool } from 'pg';

async function main() {
  if (process.env.NODE_ENV === 'production' || process.env.DEMO_SEED_ENABLED !== 'yes') {
    throw new Error('Seed deshabilitado; uso exclusivo para desarrollo local');
  }
  const db = new Pool({connectionString:process.env.DATABASE_URL});
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    // Borra los votos de pruebas anteriores: nunca ejecutar en producción.
    await client.query('TRUNCATE ballots, participations, audit_events, candidates, elections, users CASCADE');
    const password = await argon2.hash('DemoVoto#2026!', { type:argon2.argon2id });
    for (const [member,name,email,role] of [
      ['SOC001','Ana Demo','socio1@example.com','VOTER'],
      ['SOC002','Luis Demo','socio2@example.com','VOTER'],
      ['ADM001','Administración Demo','admin@example.com','ADMIN'],
    ]) {
      await client.query('INSERT INTO users(member_number,full_name,email,password_hash,role) VALUES ($1,$2,$3,$4,$5)', [member,name,email,password,role]);
    }
    const election = await client.query("INSERT INTO elections(title,starts_at,ends_at) VALUES ('Directiva de asociación — Demostración',now()-interval '1 hour',now()+interval '8 hours') RETURNING id");
    const electionId = election.rows[0].id;
    for (const [name,proposal] of [
      ['Lista Horizonte','Modernización de servicios y transparencia institucional.'],
      ['Lista Futuro','Formación profesional, innovación y participación.'],
      ['Lista Unidad','Colaboración, procesos claros y rendición de cuentas.'],
    ]) {
      await client.query('INSERT INTO candidates(election_id,name,proposal) VALUES ($1,$2,$3)', [electionId,name,proposal]);
    }
    await client.query('COMMIT');
    console.log('Datos de prueba cargados. Socios: socio1@example.com / socio2@example.com; admin: admin@example.com');
    console.log('Contraseña local de los tres usuarios: DemoVoto#2026!');
  } catch(error) { await client.query('ROLLBACK'); throw error; }
  finally { client.release(); await db.end(); }
}
main().catch(e=>{console.error(e);process.exitCode=1;});
