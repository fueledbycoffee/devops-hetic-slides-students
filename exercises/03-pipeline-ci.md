# J3 — CI propre avec GitHub Actions

## Mission Acme

Acme a maintenant :

```text
branche -> PR -> review -> CI minimale -> merge
```

Objectif :

```text
CI = lint + test + build + matrix + cache
```

Le repo utilisé est celui du J2.

---

## Pré-requis

- `main` protégée
- workflow `.github/workflows/ci.yml` existant
- CI verte sur `main`
- required status check actif

---

## Atelier 1 — CI complète

Créer une branche :

```bash
git checkout main
git pull
git checkout -b ci/full-checks
```

Remplacer `.github/workflows/ci.yml` par :

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20

      - run: npm ci
      - run: npm run lint
      - run: npm test
      - run: npm run build
```

```bash
git add .github/workflows/ci.yml
git commit -m "ci: run lint test and build"
git push -u origin ci/full-checks
```

Ouvrir une PR. Vérifier que le job `ci` est vert.

### Livrable

PR mergée avec `npm run lint`, `npm test`, `npm run build`.

---

## Atelier 2 — Required check `ci`

Dans GitHub :

```text
Settings -> Branches -> main -> Edit
```

Mettre à jour les required checks :

- retirer l'ancien check `test` si présent ;
- sélectionner `ci`.

Tester avec une PR rouge :

```bash
git checkout main
git pull
git checkout -b ci/break-lint
```

Dans `src/index.js`, supprimer une accolade ou ajouter une erreur de syntaxe.

```bash
git add src/index.js
git commit -m "test: break lint on purpose"
git push -u origin ci/break-lint
```

Ouvrir une PR. Constater le merge bloqué.

Corriger :

```bash
git add src/index.js
git commit -m "test: restore valid syntax"
git push
```

Merger quand la CI est verte.

---

## Atelier 3 — Matrix Node

Créer une branche :

```bash
git checkout main
git pull
git checkout -b ci/node-matrix
```

Remplacer le job `ci` par :

```yaml
jobs:
  ci:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        node: [20, 22]
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}

      - run: npm ci
      - run: npm run lint
      - run: npm test
      - run: npm run build
```

```bash
git add .github/workflows/ci.yml
git commit -m "ci: test on node 20 and 22"
git push -u origin ci/node-matrix
```

Ouvrir une PR. Vérifier 2 jobs en parallèle.

---

## Atelier 4 — Cache npm

Créer une branche :

```bash
git checkout main
git pull
git checkout -b ci/npm-cache
```

Dans `actions/setup-node@v4`, ajouter :

```yaml
        with:
          node-version: ${{ matrix.node }}
          cache: npm
```

```bash
git add .github/workflows/ci.yml
git commit -m "ci: cache npm dependencies"
git push -u origin ci/npm-cache
```

Observer :

- premier run : le cache est créé ;
- deuxième run : le cache est réutilisé.

Déclencher un deuxième run :

```bash
git commit --allow-empty -m "ci: trigger cache check"
git push
```

### Livrable

Capture ou note du temps `npm ci` avant / après cache.

---

## Atelier 5 — Badge README

Dans GitHub :

```text
Actions -> CI -> ... -> Create status badge
```

Ajouter le badge en haut de `README.md` :

```markdown
![CI](https://github.com/<owner>/<repo>/actions/workflows/ci.yml/badge.svg)
```

```bash
git checkout main
git pull
git checkout -b docs/add-ci-badge
git add README.md
git commit -m "docs: add ci badge"
git push -u origin docs/add-ci-badge
```

Ouvrir une PR, faire review, merger.

---

## Atelier 6 — Action communautaire simple

Option recommandée : upload du résultat de test.

Créer une branche :

```bash
git checkout main
git pull
git checkout -b ci/upload-test-log
```

Remplacer le step `npm test` par :

```yaml
      - name: Run tests
        run: npm test 2>&1 | tee test-output.txt

      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-output-node-${{ matrix.node }}
          path: test-output.txt
```

```bash
git add .github/workflows/ci.yml
git commit -m "ci: upload test logs"
git push -u origin ci/upload-test-log
```

Ouvrir une PR. Vérifier l'artefact dans le run Actions.

---

## Checklist fin CI

- [ ] CI `lint + test + build`
- [ ] Required check `ci`
- [ ] PR rouge bloquée
- [ ] Matrix Node 20 / 22
- [ ] Cache npm
- [ ] Badge ou artefact Actions
