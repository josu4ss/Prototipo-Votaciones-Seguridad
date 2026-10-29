import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { Pool, PoolClient, QueryResultRow } from 'pg';

@Injectable()
export class DatabaseService implements OnModuleDestroy {
  private readonly pool: Pool;
  constructor() {
    if (!process.env.DATABASE_URL) throw new Error('Falta DATABASE_URL');
    this.pool = new Pool({ connectionString: process.env.DATABASE_URL, max: 20 });
  }
  query<T extends QueryResultRow = any>(sql: string, params: unknown[] = []) {
    return this.pool.query<T>(sql, params);
  }
  async transaction<T>(operation: (client: PoolClient) => Promise<T>): Promise<T> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const result = await operation(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally { client.release(); }
  }
  async onModuleDestroy() { await this.pool.end(); }
}
