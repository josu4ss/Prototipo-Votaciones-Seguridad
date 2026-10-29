import { Controller, Get, Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { DatabaseService } from './database/database.service';
import { AuthController } from './auth/auth.controller';
import { AuthService } from './auth/auth.service';
import { JwtAuthGuard } from './auth/auth.guard';
import { ElectionController } from './election/election.controller';
import { ElectionService } from './election/election.service';
import { VoteController } from './votes/votes.controller';
import { VoteService } from './votes/votes.service';

@Controller('health') class HealthController { @Get() check() { return { status: 'ok' }; } }
@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true }), JwtModule.register({}), ThrottlerModule.forRoot([{ ttl: 60000, limit: 60 }])],
  controllers: [HealthController, AuthController, ElectionController, VoteController],
  providers: [DatabaseService, AuthService, JwtAuthGuard, ElectionService, VoteService, { provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
