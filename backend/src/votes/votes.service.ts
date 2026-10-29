import { ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { randomBytes } from 'node:crypto';
import { DatabaseService } from '../database/database.service';
@Injectable()
export class VoteService {
  constructor(private readonly db: DatabaseService) {}
  async cast(userId:string, role:string, candidateId:string) {
    if (role !== 'VOTER') throw new ForbiddenException('Solo los socios habilitados pueden votar');
    return this.db.transaction(async c => {
      // Bloqueos y UNIQUE(election_id,user_id) evitan duplicados concurrentes.
      const u = await c.query('SELECT id,enabled FROM users WHERE id=$1 FOR UPDATE', [userId]);
      if (!u.rows[0]?.enabled) throw new ForbiddenException('Socio inhabilitado');
      const e = await c.query('SELECT id,starts_at,ends_at,status FROM elections ORDER BY starts_at DESC LIMIT 1 FOR SHARE');
      if (!e.rows.length) throw new NotFoundException('No hay elección');
      const election = e.rows[0];
      const now = new Date();
      if (election.status !== 'OPEN' || now < new Date(election.starts_at) || now >= new Date(election.ends_at)) {
        throw new ForbiddenException('La jornada no está abierta');
      }
      const candidate = await c.query('SELECT id FROM candidates WHERE id=$1 AND election_id=$2', [candidateId,election.id]);
      if (!candidate.rows.length) throw new NotFoundException('Candidatura inválida');
      const receipt = randomBytes(24).toString('base64url');
      const participation = await c.query(
        'INSERT INTO participations(election_id,user_id,receipt_code) VALUES ($1,$2,$3) ON CONFLICT(election_id,user_id) DO NOTHING RETURNING id',
        [election.id,userId,receipt],
      );
      if (!participation.rowCount) throw new ConflictException('Este socio ya emitió su voto');
      // La papeleta no contiene identidad ni número de comprobante.
      await c.query('INSERT INTO ballots(election_id,candidate_id) VALUES($1,$2)', [election.id,candidateId]);
      // Nunca registrar candidateId ni receipt en la auditoría.
      await c.query('INSERT INTO audit_events(actor_id,action,context) VALUES ($1,$2,$3)', [userId,'VOTE_CAST',JSON.stringify({electionId:election.id})]);
      return { receipt, message:'Participación registrada correctamente' };
    });
  }
  async myParticipation(userId:string) {
    const q = await this.db.query('SELECT p.receipt_code FROM participations p JOIN elections e ON e.id=p.election_id WHERE p.user_id=$1 ORDER BY e.starts_at DESC LIMIT 1', [userId]);
    return { hasVoted:q.rowCount !== 0, receipt:q.rows[0]?.receipt_code ?? null };
  }
}
