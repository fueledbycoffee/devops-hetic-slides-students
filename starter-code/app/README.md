# Acme Demo App

Starter technique de la formation Coda. Service Node.js minimal pour pratiquer PR, CI, Docker et GHCR sans écrire d'application métier.

## Endpoints

- `/` — réponse JSON simple
- `/health` — healthcheck HTTP, utile pour les probes de plateforme (Render / Fly / etc.)
- `/metrics` — métriques au format texte

## Commandes

```bash
npm ci
npm run lint
npm test
npm run build
npm start
docker build -t devops-app:dev .
```
