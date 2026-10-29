import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { IsUUID } from 'class-validator';
import { AuthRequest, JwtAuthGuard } from '../auth/auth.guard';
import { VoteService } from './votes.service';
class VoteDto { @IsUUID() candidateId!: string; }
@Controller('votes') @UseGuards(JwtAuthGuard)
export class VoteController {
  constructor(private readonly votes: VoteService) {}
  @Post() cast(@Req() req:AuthRequest,@Body() dto:VoteDto) { return this.votes.cast(req.user.id,req.user.role,dto.candidateId); }
  @Get('me') me(@Req() req:AuthRequest) { return this.votes.myParticipation(req.user.id); }
}
