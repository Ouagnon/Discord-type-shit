import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Validation globale des DTO (class-validator) — guide ch. 5 :
  // les CHECK de plages/longueurs du schéma SQL de référence vivent ici.
  app.useGlobalPipes(
    new ValidationPipe({ whitelist: true, transform: true, forbidNonWhitelisted: true }),
  );

  // CORS restreint aux origines listées dans l'env
  const origins = (process.env.CORS_ORIGINS ?? 'http://localhost:5000')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
  app.enableCors({ origin: origins, credentials: true });

  // OpenAPI / Swagger — sert à générer le client Dart typé (packages/api-client)
  const config = new DocumentBuilder()
    .setTitle('Discord type shit — API')
    .setDescription('API de l’application de communication (REST ; temps réel en P2).')
    .setVersion('0.1.0')
    .addTag('health')
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('docs', app, document);

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port);
  console.warn(`API prête sur http://localhost:${port} (docs : /docs, santé : /health)`);
}
void bootstrap();
