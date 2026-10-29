import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
@Injectable()
export class ElectionService {
  constructor(private readonly db: DatabaseService) {}
  async current(userId: string) {
    const elections = await this.db.query('SELECT id,title,starts_at,ends_at,status FROM elections ORDER BY starts_at DESC LIMIT 1');
    if (!elections.rows.length) throw new NotFoundException('No hay elección configurada');
    const e = elections.rows[0];
    const candidates = await this.db.query('SELECT id,name,proposal FROM candidates WHERE election_id=$1 ORDER BY name', [e.id]);
    const p = await this.db.query('SELECT receipt_code FROM participations WHERE user_id=$1 AND election_id=$2', [userId,e.id]);
    const open = e.status === 'OPEN' && new Date(e.starts_at) <= new Date() && new Date(e.ends_at) > new Date();
    return { id:e.id, title:e.title, startsAt:e.starts_at, endsAt:e.ends_at, status:open?'OPEN':'CLOSED', alreadyVoted:p.rowCount !== 0, receipt:p.rows[0]?.receipt_code ?? null, candidates:candidates.rows };
  }
  async results() {
    const q = await this.db.query('SELECT id,title,status,starts_at,ends_at FROM elections ORDER BY starts_at DESC LIMIT 1');
    if (!q.rows.length) throw new NotFoundException('No hay elección');
    const e = q.rows[0];
    if (e.status === 'OPEN' && new Date(e.ends_at) > new Date()) throw new ForbiddenException('Los resultados se publican al terminar la elección');
    const counts = await this.db.query(
      'SELECT c.name, count(b.id)::int AS votes FROM candidates c LEFT JOIN ballots b ON b.candidate_id=c.id WHERE c.election_id=$1 GROUP BY c.id,c.name ORDER BY c.name', [e.id],
    );
    return { election:e.title, results:counts.rows };
  }
  async close(adminId: string) {
    return this.db.transaction(async c => {
      const r = await c.query('SELECT id,status FROM elections ORDER BY starts_at DESC LIMIT 1 FOR UPDATE');
      if (!r.rows.length) throw new NotFoundException('No hay elección');
      if (r.rows[0].status !== 'CLOSED') {
        await c.query('UPDATE elections SET status=$1 WHERE id=$2', ['CLOSED',r.rows[0].id]);
        await c.query('INSERT INTO audit_events(actor_id,action,context) VALUES ($1,$2,$3)', [adminId,'ELECTION_CLOSED',JSON.stringify({ electionId:r.rows[0].id })]);
      }
      return { status:'CLOSED' };
    });
  }
}
