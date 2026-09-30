# ADR-0002 — Base de données : code-first avec Prisma

Date : septembre 2026 · Statut : accepté

## Contexte
Un schéma complet a d'abord été conçu et optimisé (dbdiagram.io → 30 tables,
`docs/schema-bdd-optimise.sql`, syntaxe validée). Question : le schéma reste-t-il
la source de vérité (DB-first) ou passe-t-on en code-first (ORM) ?

## Décision
**Code-first avec Prisma.** `apps/api/prisma/schema.prisma` est la source de vérité
versionnée ; les migrations sont générées (`prisma migrate dev`), relisibles et
rejouables ; le client est typé.

## Justification
- Solo : un seul endroit à maintenir (le schéma), le SQL est généré — jamais de
  `ALTER TABLE` manuel en production.
- La CI rejoue toutes les migrations sur une base éphémère = vérification vivante.
- Le client typé élimine une classe entière d'erreurs au compile-time.

## Écarts assumés par rapport au SQL de référence
- Les **CHECK de plages/longueurs** (ex. `length(pseudo) BETWEEN 2 AND 32`) sont
  garantis par la couche applicative (DTO class-validator) — pratique standard Prisma.
- Les **index partiels** (ex. serveur par défaut unique) sont gérés en logique
  applicative transactionnelle — TODO commentés dans `schema.prisma`.
- Le SQL complet reste la spécification de référence : `docs/schema-bdd-optimise.sql`.
