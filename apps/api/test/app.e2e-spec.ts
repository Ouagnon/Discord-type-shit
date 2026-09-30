import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppController } from '../src/app.controller';
import { AppModule } from '../src/app.module';

/**
 * e2e minimal — la racine doit répondre sans base de données
 * (les routes sensibles à la base sont couvertes par les tests unitaires
 * et par la CI, qui elle dispose d'un PostgreSQL éphémère).
 */
describe('App (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
      controllers: [AppController],
    }).compile();
    app = moduleRef.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET / renvoie l’identité de l’API', () => {
    return request(app.getHttpServer())
      .get('/')
      .expect(200)
      .expect((res: request.Response) => {
        expect(res.body.name).toContain('Discord type shit');
        expect(res.body.version).toBeDefined();
      });
  });
});
