import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { HealthModule } from './health/health.module';
import { PrismaModule } from './prisma/prisma.module';

/**
 * Modules prévus par la feuille de route (guide ch. 15) — à créer au fil des phases :
 *   P1  AuthModule      (CPT-01..06 : inscription, login, A2F TOTP)
 *   P2  UsersModule, FriendsModule, ChannelsModule, MessagesModule, UploadsModule
 *   P3  VoiceModule     (jetons LiveKit, états vocaux via Redis)
 *   P5  AdminModule     (MOD/CSR/ANA/CFG — 18 user stories back-office)
 */
@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, envFilePath: ['.env'] }),
    PrismaModule,
    HealthModule,
  ],
  controllers: [AppController],
  providers: [],
})
export class AppModule {}
