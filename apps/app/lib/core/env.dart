import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode, defaultTargetPlatform;

/// Configuration d'exécution de l'application.
///
/// En debug, l'API tourne sur la machine de développement (docker compose).
/// En release (mini-PC de production), l'URL pointera vers
/// `https://api.<domaine>` — passée par `--dart-define` lors du build.
class Env {
  Env._();

  static const _apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// URL de base de l'API REST.
  static String get apiUrl => _apiUrl;

  /// Libellé de la plateforme courante (diagnostic écran d'accueil).
  static String get platformLabel {
    final platform = defaultTargetPlatform;
    final host = Platform.operatingSystemVersion;
    final mode = kDebugMode ? 'debug' : 'release';
    return '$platform · $mode · $host';
  }
}
