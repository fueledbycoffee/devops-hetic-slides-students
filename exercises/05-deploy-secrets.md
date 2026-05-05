# Secrets, environments & déploiement réel

## Objectif
Mettre l'app en production sur internet, déclenchée automatiquement par un merge sur `main`, avec une porte d'approval manuelle pour la prod, des secrets bien gérés, et une CI factorisée via reusable workflow.

Pré-requis : image Docker publiée sur GHCR (atelier 04).

---

## Atelier 1 : Secrets repo & environment (≈ 45 min)

### Consignes

1. **Créer un secret repo** : Settings → Secrets and variables → Actions → New repository secret
   - Nom : `DUMMY_TOKEN`
   - Valeur : `secret-test-12345`

2. **Créer un environment** `staging` : Settings → Environments → New environment → `staging`. Pas de protection.

3. **Créer un environment** `production` : avec protections :
   - **Required reviewers** : vous-même + binôme
   - **Wait timer** : 1 minute
   - **Deployment branches** : `main` uniquement

4. **Ajouter un secret d'environment** au `production` : `PROD_DEPLOY_TOKEN` = `prod-secret-67890` (factice pour ce TP).

5. **Créer `.github/workflows/secrets-test.yml`** :
   ```yaml
   name: Secrets test

   on:
     workflow_dispatch:

   jobs:
     show-repo-secret:
       runs-on: ubuntu-latest
       steps:
         - run: |
             echo "Repo secret length: ${#DUMMY_TOKEN}"
             echo "Le contenu est masqué dans les logs"
           env:
             DUMMY_TOKEN: ${{ secrets.DUMMY_TOKEN }}

     deploy-prod:
       runs-on: ubuntu-latest
       environment: production
       steps:
         - run: |
             echo "Token prod length: ${#PROD_DEPLOY_TOKEN}"
           env:
             PROD_DEPLOY_TOKEN: ${{ secrets.PROD_DEPLOY_TOKEN }}
   ```

6. Lancer manuellement le workflow (Actions → Secrets test → Run workflow).

7. **Observer** :
   - Le job `show-repo-secret` part directement
   - Le job `deploy-prod` attend votre approval (cliquer sur **Review deployments**)
   - Dans les logs : `***` à la place du contenu du secret
   - Le `length` permet de vérifier qu'il a bien été chargé sans le révéler

### Livrable
Un workflow qui montre la différence repo / environment, et un job prod qui attend une approbation manuelle.

### Anti-patterns à connaître
- `echo ${{ secrets.X }}` — leak du secret dans les logs (GitHub masque mais c'est best-effort)
- Stocker un secret dans `env:` au niveau workflow (visible à tous les jobs même ceux qui n'en ont pas besoin)
- Hardcoder un token dans le YAML
- Logguer une URL contenant un token : `curl https://api.com?token=$X` → l'URL apparaît dans les logs

---

## Atelier 2 : Déploiement réel sur PaaS gratuit (≈ 1h30)

Choisir **un** PaaS. Options recommandées (free tier, pas de carte requise pour démarrer) :
- **Render** (`render.com`) — recommandé, le plus simple
- **Fly.io** (`fly.io`) — CLI sympa, free tier généreux
- **Railway** (`railway.com`) — UI agréable, free tier limité dans le temps

### Render — chemin recommandé

1. Créer un compte Render avec votre email GitHub.
2. **New → Web Service** → **Build and deploy from a Git repository** → connecter le repo binôme.
3. Configuration :
   - Branch : `main`
   - Root Directory : `.`
   - Runtime : Docker
   - Plan : Free
4. **Désactiver Auto-Deploy** dans Settings (on va déclencher depuis GHA).
5. Récupérer le **Deploy Hook** : Settings → Deploy Hook → copier l'URL `https://api.render.com/deploy/srv-xxxx?key=yyyy`.
6. Ajouter ce hook en secret `RENDER_DEPLOY_HOOK` (environnement `production`).
7. Créer `.github/workflows/deploy.yml` :
   ```yaml
   name: Deploy

   on:
     push:
       branches: [main]

   jobs:
     deploy-prod:
       runs-on: ubuntu-latest
       environment:
         name: production
         url: https://${{ vars.RENDER_APP_HOSTNAME }}
       steps:
         - name: Trigger Render deploy
           run: curl -fsSL -X POST "$DEPLOY_HOOK"
           env:
             DEPLOY_HOOK: ${{ secrets.RENDER_DEPLOY_HOOK }}

         - name: Wait & smoke test
           run: |
             for i in {1..30}; do
               if curl -fsSL "https://${{ vars.RENDER_APP_HOSTNAME }}/health"; then
                 echo "✓ App live"
                 exit 0
               fi
               echo "Attempt $i — not ready, sleeping 10s"
               sleep 10
             done
             echo "✗ Timeout"
             exit 1
   ```
8. Ajouter une **variable** d'environnement `RENDER_APP_HOSTNAME` (Settings → Environments → production → Add variable). Valeur = le hostname Render (ex. `devops-app-xxxx.onrender.com`).
9. Merger une PR sur `main`. Approuver le deploy. Vérifier que l'app est live :
   ```bash
   curl https://votre-app.onrender.com/health
   ```

### Fly.io — chemin alternatif

1. Installer `flyctl` : `brew install flyctl` ou `curl -L https://fly.io/install.sh | sh`
2. `fly auth signup` (ou `fly auth login`)
3. `fly launch` — accepter les défauts, ne pas déployer immédiatement
4. Récupérer un token : `fly tokens create deploy -x 999999h`. Ajouter en secret `FLY_API_TOKEN` (env production).
5. Workflow `deploy.yml` :
   ```yaml
   - uses: superfly/flyctl-actions/setup-flyctl@master
   - run: flyctl deploy --remote-only
     env:
       FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
   ```

### Livrable
URL publique d'une app live, déclenchée par merge sur `main` avec approval manuel.

---

## Atelier 3 : Reusable workflow (≈ 45 min)

### Consignes

1. **Créer le workflow réutilisable** `.github/workflows/reusable-ci.yml` :
   ```yaml
   name: Reusable CI

   on:
     workflow_call:
       inputs:
         node-version:
           type: string
           default: '20'
         working-directory:
           type: string
           default: '.'

   jobs:
     ci:
       runs-on: ubuntu-latest
       defaults:
         run:
           working-directory: ${{ inputs.working-directory }}
       steps:
         - uses: actions/checkout@v4
         - uses: actions/setup-node@v4
           with:
             node-version: ${{ inputs.node-version }}
             cache: 'npm'
             cache-dependency-path: ${{ inputs.working-directory }}/package-lock.json
         - run: npm ci
         - run: npm test
   ```

2. **Remplacer** `.github/workflows/ci.yml` par un appelant :
   ```yaml
   name: CI

   on:
     pull_request:
     push:
       branches: [main]

   jobs:
     call-ci:
       uses: ./.github/workflows/reusable-ci.yml
       with:
         working-directory: .
         node-version: '20'
   ```

3. Pousser, vérifier que la CI tourne toujours.

4. **Bonus** — utiliser le reusable workflow depuis un **autre repo** (par exemple un fork du starter dans un repo séparé) :
   ```yaml
   uses: <votre-org>/<votre-repo>/.github/workflows/reusable-ci.yml@main
   ```
   Cela demande que le repo source soit accessible (public ou même org).

### Livrable
CI factorisée dans un reusable workflow, appelée depuis le workflow principal.

### Quand factoriser ?
- < 3 repos qui ont la même CI : copier-coller. Factoriser est de la complexité prématurée.
- ≥ 3 repos avec CI identique : reusable workflow.
- Plusieurs orgs : action composite ou repo dédié `infra/shared-workflows`.

---

## Aide

**Atelier 1 — `Review deployments` ne s'affiche pas** : vérifier que l'environment a bien `Required reviewers`. Sinon le job s'exécute sans attente.

**Atelier 1 — secret reste vide dans le job** : vérifier le scope. Un secret repo est dans `secrets.X`, un secret environment n'est lisible que dans un job qui a `environment: <name>`.

**Atelier 2 — Render déploie automatiquement avant que la GHA ait approval** : il faut **désactiver Auto-Deploy** dans Render. Le déclenchement se fait uniquement via le deploy hook.

**Atelier 2 — `/health` répond 502 Bad Gateway** : Render n'a pas fini de booter. Augmenter le nombre d'itérations du smoke test, ou augmenter le sleep. Vérifier que l'app expose bien le port via `process.env.PORT` (Render impose le port dynamique).

**Atelier 2 — Render demande une CB** : non, le free tier n'en demande pas. Si la page demande, vérifier que vous êtes bien sur le plan Free.

**Atelier 3 — `uses: ./.github/workflows/reusable-ci.yml` échoue** : la syntaxe `./` ne marche que sur la **même branche du même repo**. Le workflow appelant et le workflow appelé doivent être tous les deux dans le même commit.

**Atelier 3 — `inputs` ne sont pas passés** : le bloc `with:` doit être au niveau du job appelant, pas du step. La syntaxe `uses: ...` au niveau job est ce qui appelle un reusable, pas une action.
