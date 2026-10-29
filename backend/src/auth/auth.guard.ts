import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { Request } from 'express';
import { AuthService, AuthUser } from './auth.service';
export type AuthRequest = Request & { user: AuthUser };
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly auth: AuthService) {}
  async canActivate(context: ExecutionContext) {
    const request = context.switchToHttp().getRequest<AuthRequest>();
    const value = request.headers.authorization || '';
    const [kind, token] = value.split(' ');
    if (kind !== 'Bearer' || !token) throw new UnauthorizedException('Falta token Bearer');
    request.user = await this.auth.verify(token);
    return true;
  }
}
