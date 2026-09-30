# Application « Discord type shit » (Flutter)

## Premier lancement

```bash
flutter create . --platforms android,windows,ios,linux,macos
flutter pub get
flutter run                      # cible par défaut
flutter run -d windows           # PC
flutter run -d <deviceId>        # mobile (flutter devices)
```

`flutter create .` génère les dossiers de plateformes manquants (android/,
windows/…) **sans écraser** les fichiers existants (lib/, pubspec.yaml).

> POC semaine 1 (guide ch. 15) : valider ici la fenêtre transparente
> toujours au-dessus (`window_manager` + platform channels) et le salon
> vocal LiveKit (paquet `livekit_client` — à ajouter en P3).

## Structure

```
lib/
├── main.dart          # point d'entrée + écran d'accueil
└── core/
    ├── theme.dart     # thème sombre (charte de l'app)
    └── env.dart       # configuration (URL de l'API…)
```

Le client API typé sera généré dans `packages/api-client`
(voir son README) puis importé ici.
