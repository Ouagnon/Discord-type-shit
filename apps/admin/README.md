# Back-office « Discord type shit » (Flutter Web)

## Développement

```bash
flutter create . --platforms web
flutter pub get
flutter run -d chrome
```

## Build de production (déployé par Caddy)

```bash
flutter build web --release
# → build/web/ est monté dans le conteneur Caddy (docker-compose.prod.yml)
#   et servi sur https://bo.<domaine>
```

## Module à venir (guide ch. 15, phase P5)

18 user stories : modération (MOD-01..05), comptes & serveurs (CSR-01..06),
analytics (ANA-01..05), configuration système (CFG-01..06).
A2F obligatoire, journal d'audit en ajout seul, 3 niveaux de droits.
