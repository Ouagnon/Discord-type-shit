# packages/api-client — client Dart typé

Ce paquet contiendra le client d'API **généré** depuis l'OpenAPI de NestJS
(`@nestjs/swagger` — http://localhost:3000/docs-json), puis importé par
`apps/app` et `apps/admin`.

## Génération (guide ch. 5)

```bash
npm install -g @openapitools/openapi-generator-cli

# API démarrée en local (npm run start:dev) :
openapi-generator-cli generate \
  -i http://localhost:3000/docs-json \
  -g dart-dio \
  -o packages/api-client \
  --additional-properties=pubLibrary=dts_api_client
```

Régénérer à chaque évolution du contrat d'API (commité dans le dépôt,
cf. guide ch. 14 : le client voyage avec le code qui l'utilise).
