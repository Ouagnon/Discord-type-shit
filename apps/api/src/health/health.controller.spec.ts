import { HealthController } from './health.controller';
import { PrismaService } from '../prisma/prisma.service';

describe('HealthController', () => {
  it('répond « ok » quand la base répond', async () => {
    const prisma = { $queryRaw: () => Promise.resolve([{ 1: 1 }]) } as unknown as PrismaService;
    const controller = new HealthController(prisma);

    const result = await controller.check();

    expect(result.status).toBe('ok');
    expect(result.database).toBe('up');
    expect(typeof result.uptimeSeconds).toBe('number');
  });

  it('répond « degraded » quand la base est injoignable', async () => {
    const prisma = {
      $queryRaw: () => Promise.reject(new Error(' connexion perdue')),
    } as unknown as PrismaService;
    const controller = new HealthController(prisma);

    const result = await controller.check();

    expect(result.status).toBe('degraded');
    expect(result.database).toBe('down');
  });
});
