import 'package:flutter/material.dart';

import 'core/env.dart';
import 'core/theme.dart';

/// Point d'entrée de l'application « Discord type shit ».
void main() {
  runApp(const DtsApp());
}

class DtsApp extends StatelessWidget {
  const DtsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Discord type shit',
      debugShowCheckedModeBanner: false,
      theme: DtsTheme.dark(),
      home: const HomeScreen(),
    );
  }
}

/// Écran d'accueil provisoire : vérifie que le socle fonctionne
/// (thème, cible, API joignable) avant l'implémentation de CPT-01.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discord type shit'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard(apiUrl: Env.apiUrl),
          const _NextStepsCard(),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.apiUrl});

  final String apiUrl;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: DtsTheme.surfaceHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF23a55a),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Socle prêt',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'API : $apiUrl',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Plateforme : ${Env.platformLabel}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _NextStepsCard extends StatelessWidget {
  const _NextStepsCard();

  @override
  Widget build(BuildContext context) {
    const steps = [
      'POC 1 — fenêtre overlay toujours au-dessus (Windows)',
      'POC 2 — salon vocal LiveKit depuis Flutter',
      'POC 3 — événement temps réel de bout en bout',
      'P1 — comptes et authentification (CPT-01)',
    ];
    return Card(
      color: DtsTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prochaines étapes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final step in steps)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ', style: TextStyle(color: DtsTheme.brand)),
                    Expanded(child: Text(step)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
