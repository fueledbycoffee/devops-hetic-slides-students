# J4 — Projet final : audit DevOps LoueUneChevre.com

## Mission

Vous êtes consultants DevOps pour **LoueUneChevre.com**.

La startup vient de lever 1 M EUR. Elle passe de :

```text
1 dev + 1 admin sys
```

à :

```text
7 devs + 1 DevOps Engineer + 3 admins sys
```

Votre mission : auditer le projet et proposer un fonctionnement DevOps réaliste.

Base fournie :

```text
projects/LoueUneChevre.com
```

---

## Rendu

À rendre en binôme :

- 1 document de 4 pages maximum ou 6 slides maximum ;
- 1 schéma de pipeline cible ;
- 1 roadmap 30 / 60 / 90 jours ;
- 1 preuve technique simple si le temps le permet.

Le rendu peut être finalisé à la maison.

---

## Partie 1 — Diagnostic

Lire rapidement :

```text
README.md
docs/README-A-LIRE-AVANT-TOUT.md
docs/architecture.md
docs/backlog-avant-levee.md
docs/metriques-brutes.md
docs/incidents.md
ops/manual-deploy/PROCESS_DEPLOIEMENT_MAIN.md
ops/manual-deploy/journal-deploiements-2026.md
ops/manual-deploy/rollback-notes.md
docs/exploitation/inventaire-serveurs.md
docs/exploitation/handover-marc.md
```

Produire un diagnostic avec les 3 voies.

| Voie | Constats | Risques |
|---|---|---|
| Flux |  |  |
| Feedback |  |  |
| Apprentissage |  |  |

---

## Partie 2 — CALMS

Remplir :

| Pilier | Score actuel 1-5 | Justification | Cible 3 mois | Action prioritaire |
|---|---:|---|---:|---|
| Culture |  |  |  |  |
| Automation |  |  |  |  |
| Lean |  |  |  |  |
| Measurement |  |  |  |  |
| Sharing |  |  |  |  |

---

## Partie 3 — DORA

Définir comment LoueUneChevre.com doit mesurer DORA.

| Métrique | Définition retenue | Source | Objectif 3 mois |
|---|---|---|---|
| Deployment Frequency |  |  |  |
| Lead Time for Changes |  |  |  |
| MTTR |  |  |  |
| Change Failure Rate |  |  |  |

Sources possibles :

- GitHub PRs ;
- GitHub Actions ;
- tags / releases ;
- journal de déploiement ;
- incidents ;
- monitoring ;
- post-mortems.

---

## Partie 4 — Fonctionnement cible

Décrire le nouveau fonctionnement :

- branches ;
- PR ;
- review ;
- branch protection ;
- CI ;
- Docker / GHCR ;
- staging ;
- production ;
- rollback ;
- incidents ;
- documentation minimale.

Schéma attendu :

```text
Issue
  -> branche
  -> PR
  -> review
  -> CI
  -> build Docker
  -> GHCR
  -> staging
  -> approval prod
  -> prod
  -> smoke test
  -> monitoring
```

---

## Partie 5 — Pipeline cible

Vous pouvez réutiliser ce squelette.

```yaml
name: Release

on:
  push:
    branches: [main]

permissions:
  contents: read
  packages: write

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - run: npm ci
      - run: npm run lint
      - run: npm test
      - run: npm run build:web

  docker:
    needs: ci
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v6
        with:
          context: ./services/api
          push: true
          tags: |
            ghcr.io/${{ github.repository }}/api:${{ github.sha }}
            ghcr.io/${{ github.repository }}/api:latest

  deploy-staging:
    needs: docker
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - run: curl -fsSL -X POST "$DEPLOY_HOOK"
        env:
          DEPLOY_HOOK: ${{ secrets.STAGING_DEPLOY_HOOK }}

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment: production
    steps:
      - run: curl -fsSL -X POST "$DEPLOY_HOOK"
        env:
          DEPLOY_HOOK: ${{ secrets.PROD_DEPLOY_HOOK }}
```

À adapter dans le rendu :

- quels jobs garder maintenant ;
- quels jobs reporter ;
- quels secrets créer ;
- quels checks rendre bloquants ;
- où ajouter le smoke test ;
- où brancher monitoring / alerting.

---

## Partie 6 — Roadmap

| Horizon | Actions | Pourquoi | Métriques impactées |
|---|---|---|---|
| 30 jours |  |  |  |
| 60 jours |  |  |  |
| 90 jours |  |  |  |

Contraintes :

- pas uniquement "installer un outil" ;
- chaque action doit réduire un risque ;
- chaque action doit changer un comportement ;
- chaque action doit être reliée à CALMS ou DORA.

---

## Preuve technique simple

Option A :

```text
Créer une PR qui ajoute `.github/workflows/ci.yml` dans une copie du projet.
```

Option B :

```text
Créer une PR qui ajoute `docs/pipeline-cible.md`.
```

Option C :

```text
Créer une PR qui ajoute `docs/runbook-deploiement.md`.
```

Contenu minimal pour `docs/pipeline-cible.md` :

```markdown
# Pipeline cible LoueUneChevre.com

## Flux

Issue -> PR -> CI -> Docker -> GHCR -> staging -> approval -> prod -> smoke test.

## Checks bloquants

- CI API
- build web
- Docker build
- smoke test staging

## Secrets

- STAGING_DEPLOY_HOOK
- PROD_DEPLOY_HOOK

## Prochaines étapes

- branch protection sur main
- environment production avec reviewer
- monitoring /health
- post-mortem template
```

---

## Démo finale

5 à 7 minutes par binôme :

1. Contexte LoueUneChevre.com
2. 3 risques majeurs
3. CALMS + DORA
4. Pipeline cible
5. Roadmap 30 / 60 / 90
6. Preuve technique si disponible

---

## Barème indicatif

| Bloc | Points |
|---|---:|
| Diagnostic 3 voies | 5 |
| CALMS | 4 |
| DORA | 4 |
| Fonctionnement cible | 4 |
| Pipeline cible | 5 |
| Roadmap 30 / 60 / 90 | 4 |
| Preuve technique | 2 |
| Restitution | 2 |

---

## Aide

Questions à se poser :

- Qu'est-ce qui bloque le flux ?
- Où manque le feedback ?
- Que se passe-t-il après incident ?
- Quel changement doit être automatisé en premier ?
- Quelle règle protège `main` ?
- Quel signal dit que la prod est saine ?
- Quel rollback est possible en moins de 30 minutes ?
