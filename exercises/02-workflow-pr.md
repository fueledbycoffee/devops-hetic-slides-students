# J2 — Workflow PR + première CI

## Mission Acme

Acme pousse encore directement sur `main`.

Objectif du jour :

```text
branche -> PR -> review -> CI -> merge
```

Projet utilisé : `starter-code/app`.

`LoueUneChevre.com` est réservé au projet final J4.

---

## Planning

| Bloc | Durée |
|---|---:|
| Repo binôme + branch protection | 45 min |
| PR croisée avec review | 1 h 30 |
| Conflit + rebase | 1 h |
| Première GitHub Action | 1 h |
| Required status check + CI rouge | 1 h |
| Issues / project board | 45 min |

---

## Atelier 1 — Repo binôme

### À faire

1. Créer un repo GitHub :

```text
devops-coda-acme-<prenom1>-<prenom2>
```

2. Ajouter le binôme en collaborateur avec droit `Write`.

3. Initialiser le repo :

```bash
git clone <url-du-repo> .
cp -R /Users/sean/cours/DevOps-coda-slides/starter-code/app/. .
npm ci
npm test
git add .
git commit -m "chore: bootstrap Acme app"
git push origin main
```

4. Protéger `main` :

- Require a pull request before merging
- Require approvals : `1`
- Dismiss stale pull request approvals
- Require conversation resolution
- Require linear history
- Do not allow bypassing

5. Tester le refus de push direct :

```bash
echo "direct push test" >> README.md
git add README.md
git commit -m "test: direct push should fail"
git push origin main
```

Le push doit échouer.

Annuler le commit local :

```bash
git reset --hard HEAD~1
```

### Livrable

Capture des branch protection rules + push direct refusé.

---

## Atelier 2 — PR template

Créer `.github/pull_request_template.md` :

```markdown
## What


## Why


## Test plan

- [ ] npm test
- [ ] curl manuel
```

Commandes :

```bash
git checkout -b chore/pr-template
mkdir -p .github
git add .github/pull_request_template.md
git commit -m "chore: add pull request template"
git push -u origin chore/pr-template
```

Ouvrir une PR, faire approuver, merger.

---

## Atelier 3 — PR croisée

Chaque personne ouvre une PR différente.

### Personne A — route `/version`

```bash
git checkout main
git pull
git checkout -b feat/add-version-route
```

Dans `src/index.js`, ajouter ce bloc juste après le bloc `/health` :

```js
    if (path === "/version") {
      writeJson(res, 200, {
        version: "1.0.0",
        node: process.version
      });
      return;
    }
```

Tester :

```bash
npm run lint
npm test
npm start
```

Dans un autre terminal :

```bash
curl http://localhost:3000/version
```

Commit + push :

```bash
git add src/index.js
git commit -m "feat: add version endpoint"
git push -u origin feat/add-version-route
```

PR :

```markdown
## What
Add GET /version.

## Why
Acme needs a quick way to identify the running app version.

## Test plan
- [x] npm run lint
- [x] npm test
- [x] curl http://localhost:3000/version
```

### Personne B — route `/uptime`

```bash
git checkout main
git pull
git checkout -b feat/add-uptime-route
```

Dans `src/index.js`, ajouter ce bloc juste après le bloc `/` :

```js
    if (path === "/uptime") {
      writeJson(res, 200, {
        uptime: process.uptime()
      });
      return;
    }
```

Tester :

```bash
npm run lint
npm test
npm start
```

Dans un autre terminal :

```bash
curl http://localhost:3000/uptime
```

Commit + push :

```bash
git add src/index.js
git commit -m "feat: add uptime endpoint"
git push -u origin feat/add-uptime-route
```

PR :

```markdown
## What
Add GET /uptime.

## Why
Acme wants a simple runtime signal before adding real monitoring.

## Test plan
- [x] npm run lint
- [x] npm test
- [x] curl http://localhost:3000/uptime
```

---

## Atelier 4 — Review en jeu de rôle

Chaque reviewer doit laisser :

- 1 commentaire `must`
- 1 commentaire `should` ou `nit`
- 1 suggestion GitHub

### Suggestion pour la PR `/version`

Demander :

```text
must: rename node to nodeVersion, the response field is clearer.
```

Suggestion à appliquer :

```js
        nodeVersion: process.version
```

### Suggestion pour la PR `/uptime`

Demander :

```text
must: return an integer field named uptimeSeconds.
```

Suggestion à appliquer :

```js
        uptimeSeconds: Math.round(process.uptime())
```

Après correction :

```bash
npm run lint
npm test
git add src/index.js
git commit -m "fix: apply review suggestion"
git push
```

Le reviewer approuve. Merger en squash.

---

## Atelier 5 — Conflit + rebase

### Branche A

```bash
git checkout main
git pull
git checkout -b chore/health-runtime
```

Remplacer le bloc `/health` par :

```js
    if (path === "/health") {
      writeJson(res, 200, {
        status: "healthy",
        uptimeSeconds: Math.round(process.uptime())
      });
      return;
    }
```

```bash
npm run lint
npm test
git add src/index.js
git commit -m "chore: add uptime to health"
git push -u origin chore/health-runtime
```

Ouvrir la PR A, faire approuver, merger.

### Branche B

Ne pas faire `git pull` après le merge de A.

```bash
git checkout main
git checkout -b chore/health-timestamp
```

Remplacer le bloc `/health` par :

```js
    if (path === "/health") {
      writeJson(res, 200, {
        status: "healthy",
        timestamp: new Date().toISOString()
      });
      return;
    }
```

```bash
npm run lint
npm test
git add src/index.js
git commit -m "chore: add timestamp to health"
git push -u origin chore/health-timestamp
```

Ouvrir la PR B. GitHub doit annoncer un conflit.

Résoudre localement :

```bash
git pull --rebase origin main
```

Dans `src/index.js`, garder :

```js
    if (path === "/health") {
      writeJson(res, 200, {
        status: "healthy",
        uptimeSeconds: Math.round(process.uptime()),
        timestamp: new Date().toISOString()
      });
      return;
    }
```

Puis :

```bash
npm run lint
npm test
git add src/index.js
git rebase --continue
git push --force-with-lease
```

Faire review + merge.

---

## Atelier 6 — Première GitHub Action

```bash
git checkout main
git pull
git checkout -b ci/first-check
mkdir -p .github/workflows
```

Créer `.github/workflows/ci.yml` :

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npm test
```

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add first pull request check"
git push -u origin ci/first-check
```

Ouvrir une PR. Vérifier l'onglet `Checks`. Merger quand le job est vert.

---

## Atelier 7 — Required status check

Dans GitHub :

```text
Settings -> Branches -> main -> Edit
```

Activer :

- Require status checks to pass before merging
- Sélectionner le check `test`

Créer une PR rouge :

```bash
git checkout main
git pull
git checkout -b ci/break-test
```

Dans `test/math.test.js`, remplacer :

```js
assert.equal(add(2, 3), 5);
```

par :

```js
assert.equal(add(2, 3), 999);
```

```bash
git add test/math.test.js
git commit -m "test: break ci on purpose"
git push -u origin ci/break-test
```

Ouvrir une PR. Constater :

- CI rouge ;
- bouton merge bloqué.

Corriger :

```bash
# remettre assert.equal(add(2, 3), 5);
git add test/math.test.js
git commit -m "test: restore passing assertion"
git push
```

Quand la CI redevient verte, merger.

---

## Atelier 8 — Issues + board

Créer 6 issues :

- 2 bugs
- 2 features
- 1 question
- 1 tech debt

Créer les labels :

```text
priority/p0
priority/p1
priority/p2
area/api
area/tests
area/docs
tech-debt
```

Créer un project board :

```text
Backlog -> In progress -> In review -> Done
```

Ouvrir une PR qui ferme une issue avec :

```text
Closes #<numero>
```

### Livrable

Board rempli + 1 issue fermée automatiquement par merge.

---

## Checklist fin J2

- [ ] `main` protégée
- [ ] Push direct refusé
- [ ] 2 PRs reviewées et mergées
- [ ] 1 conflit résolu par rebase
- [ ] 1 workflow CI sur PR
- [ ] 1 PR rouge bloquée par required status check
- [ ] Issues + board créés
