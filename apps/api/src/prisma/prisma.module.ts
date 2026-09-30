import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';

/** Service Prisma disponible partout (un seul client par process). */
@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
