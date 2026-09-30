import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { PrismaService } from '../prisma/prisma.service';

export type HealthStatus = 'ok' | 'degraded';

@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Sonde de santé — supervisée par UptimeRobot en production (docs/ops.md § 5).
   * « ok » si la base répond, « degraded » sinon (l'API reste servie).
   */
  @Get()
  @ApiOperation({ summary: 'Santé de l’API et de la base de données' })
  async check(): Promise<{
    status: HealthStatus;
    database: 'up' | 'down';
    uptimeSeconds: number;
    time: string;
  }> {
    let database: 'up' | 'down' = 'up';
    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch {
      database = 'down';
    }
    const status: HealthStatus = database === 'up' ? 'ok' : 'degraded';
    return {
      status,
      database,
      uptimeSeconds: Math.round(process.uptime()),
      time: new Date().toISOString(),
    };
  }
}
