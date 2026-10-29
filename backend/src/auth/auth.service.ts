import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import { DatabaseService } from '../database/database.service';

export type AuthUser = { id: string; role: 'VOTER' | 'ADMIN' };
@Injectable()
export class AuthService {
  private readonly secret: string;
  constructor(private readonly db: DatabaseService, private readonly jwt: JwtService) {
    const secret = process.env.JWT_SECRET || '';
    if (secret.length < 32) throw new Error('JWT_SECRET debe contener 32+ caracteres');
    this.secret = secret;
  }
  async login(email: string, password: string) {
    const response = await this.db.query<{id:string;full_name:string;email:string;role:'VOTER'|'ADMIN';enabled:boolean;password_hash:string}>(
      'SELECT id, full_name, email, role, enabled, password_hash FROM users WHERE email=$1', [email.trim().toLowerCase()],
    );
    const user = response.rows[0];
    // Respuesta idéntica si el usuario no existe o la clave es incorrecta.
    if (!user || !user.enabled || !(await argon2.verify(user.password_hash, password))) {
      throw new UnauthorizedException('Credenciales inválidas');
    }
    const accessToken = await this.jwt.signAsync({ sub: user.id, role: user.role }, { secret: this.secret, expiresIn: '60m', algorithm: 'HS256' });
    await this.db.query('INSERT INTO audit_events(actor_id, action) VALUES ($1, $2)', [user.id, 'LOGIN_SUCCESS']);
    return { accessToken, user: { id: user.id, fullName: user.full_name, role: user.role } };
  }
  async verify(token: string): Promise<AuthUser> {
    try {
      const payload = await this.jwt.verifyAsync<{sub:string;role:'VOTER'|'ADMIN'}>(token, { secret: this.secret, algorithms: ['HS256'] });
      // Revalidar en BD: un socio deshabilitado pierde acceso inmediatamente.
      const result = await this.db.query<{id:string;role:'VOTER'|'ADMIN'}>('SELECT id, role FROM users WHERE id=$1 AND enabled=TRUE', [payload.sub]);
      if (!result.rows[0]) throw new Error('No habilitado');
      return result.rows[0];
    } catch { throw new UnauthorizedException('Sesión inválida o vencida'); }
  }
}
