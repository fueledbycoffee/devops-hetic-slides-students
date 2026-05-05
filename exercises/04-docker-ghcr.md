# J3 — Docker build & push GHCR

## Mission Acme

La CI valide le code. Il faut maintenant produire un artefact livrable :

```text
PR -> CI -> build Docker -> GHCR
```

Le repo utilisé est celui du J2/J3.

---

## Pré-requis

- CI verte sur `main`
- Docker installé localement
- `Dockerfile` présent à la racine du repo

---

## Atelier 1 — Tester l'image en local

```bash
git checkout main
git pull
npm ci
npm test
docker build -t devops-app:local .
docker run --rm -p 3000:3000 devops-app:local
```

Dans un autre terminal :

```bash
curl http://localhost:3000/health
curl http://localhost:3000/metrics
```

Arrêter le conteneur avec `Ctrl+C`.

---

## Atelier 2 — Build Docker en CI

Créer une branche :

```bash
git checkout -b ci/docker-build
mkdir -p .github/workflows
```

Créer `.github/workflows/docker.yml` :

```yaml
name: Docker

on:
  pull_request:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: docker/setup-buildx-action@v3

      - uses: docker/build-push-action@v6
        with:
          context: .
          tags: devops-app:${{ github.sha }}
          load: true
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Smoke test image
        run: |
          docker run -d --name app -p 3000:3000 devops-app:${{ github.sha }}
          sleep 3
          curl -fsSL http://localhost:3000/health
          docker stop app
```

```bash
git add .github/workflows/docker.yml
git commit -m "ci: build docker image"
git push -u origin ci/docker-build
```

Ouvrir une PR. Vérifier le job `Docker / build`.

### Livrable

PR mergée avec build Docker + smoke test.

---

## Atelier 3 — Push GHCR

Créer une branche :

```bash
git checkout main
git pull
git checkout -b ci/push-ghcr
```

Remplacer `.github/workflows/docker.yml` par :

```yaml
name: Docker

on:
  pull_request:
  push:
    branches: [main]

permissions:
  contents: read
  packages: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: docker/setup-buildx-action@v3

      - name: Build image for validation
        uses: docker/build-push-action@v6
        with:
          context: .
          tags: devops-app:${{ github.sha }}
          load: true
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Smoke test image
        run: |
          docker run -d --name app -p 3000:3000 devops-app:${{ github.sha }}
          sleep 3
          curl -fsSL http://localhost:3000/health
          docker stop app

      - name: Login to GHCR
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Compute image tags
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=sha,prefix=
            type=raw,value=latest,enable={{is_default_branch}}

      - uses: docker/build-push-action@v6
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

```bash
git add .github/workflows/docker.yml
git commit -m "ci: publish docker image to ghcr"
git push -u origin ci/push-ghcr
```

Ouvrir une PR. Le push GHCR ne se fait pas sur PR.

Merger. Sur `main`, vérifier :

```text
Repo GitHub -> Packages
```

L'image doit avoir :

- un tag SHA ;
- un tag `latest`.

---

## Atelier 4 — Tester l'image publiée

Rendre le package public si nécessaire :

```text
Package -> Settings -> Change visibility -> Public
```

Tester :

```bash
docker pull ghcr.io/<owner>/<repo>:latest
docker run --rm -p 3000:3000 ghcr.io/<owner>/<repo>:latest
curl http://localhost:3000/health
```

---

## Bonus — tag git

Ajouter dans `docker/metadata-action` :

```yaml
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
```

Créer un tag :

```bash
git tag v1.0.0
git push origin v1.0.0
```

Vérifier les tags GHCR.

---

## Aide

**`permission denied` sur GHCR** : vérifier `permissions: packages: write` et Settings -> Actions -> General -> Workflow permissions.

**`docker pull` retourne `unauthorized`** : l'image est privée. Rendre le package public ou se connecter à GHCR.

**Le cache Docker ne va pas plus vite au premier run** : normal. Le premier run crée le cache.

**Le smoke test échoue** : vérifier que l'app écoute bien sur `PORT=3000` et que `/health` répond `200`.

---

## Checklist fin Docker

- [ ] Image buildée localement
- [ ] Image buildée en CI
- [ ] Smoke test image en CI
- [ ] Image publiée sur GHCR
- [ ] Tags SHA + `latest`
- [ ] `docker pull ghcr.io/<owner>/<repo>:latest` fonctionne
