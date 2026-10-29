import { Controller, Get, Post, Req, UseGuards, ForbiddenException } from '@nestjs/common';
import { AuthRequest, JwtAuthGuard } from '../auth/auth.guard';
import { ElectionService } from './election.service';
@Controller('election') @UseGuards(JwtAuthGuard)
export class ElectionController {
  constructor(private readonly election: ElectionService) {}
  @Get() get(@Req() req: AuthRequest) { return this.election.current(req.user.id); }
  @Get('results') results() { return this.election.results(); }
  @Post('close') close(@Req() req: AuthRequest) {
    if (req.user.role !== 'ADMIN') throw new ForbiddenException('Solo el administrador puede cerrar la elección');
    return this.election.close(req.user.id);
  }
}
