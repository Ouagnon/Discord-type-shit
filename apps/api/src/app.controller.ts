import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

@ApiTags('app')
@Controller()
export class AppController {
  /** Racine : identité de l'API — sert de smoke test (e2e). */
  @Get()
  @ApiOperation({ summary: 'Identité de l’API' })
  getRoot() {
    return {
      name: 'Discord type shit — API',
      version: '0.1.0',
      env: process.env.NODE_ENV ?? 'development',
      time: new Date().toISOString(),
    };
  }
}
