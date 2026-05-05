# Pipeline CI/CD multi-stages

## Objectif
Construire un pipeline CI/CD complet avec build, test, scan et déploiement en utilisant GitHub Actions.

## Contexte
Vous travaillez sur l'application fil rouge du cours. Elle doit rester cohérente avec les labs suivants : Docker, Kubernetes, monitoring et GitOps.

## Consignes

### 1. Structure du projet

Point de départ recommandé :

```bash
cp -R starter-code/devops-app app
```

Le dossier `app/` doit contenir :

```
app/
  src/
    index.js
    math.js
  test/
    math.test.js
  package.json
  package-lock.json
  Dockerfile
  .dockerignore
.github/
  workflows/
    ci.yml
```

### 2. Application de base

**app/src/math.js** :
```javascript
function add(a, b) { return a + b; }
function multiply(a, b) { return a * b; }
function divide(a, b) {
  if (b === 0) throw new Error('Division by zero');
  return a / b;
}
module.exports = { add, multiply, divide };
```

**app/src/index.js** :
```javascript
const http = require('http');
const { add } = require('./math');

const durationBuckets = [0.05, 0.1, 0.2, 0.5, 1, 2];
const requestCounts = new Map();
const requestDurations = new Map();

function observe(labels, durationSeconds) {
  const key = JSON.stringify(labels);
  requestCounts.set(key, (requestCounts.get(key) || 0) + 1);

  const stats = requestDurations.get(key) || {
    sum: 0,
    count: 0,
    buckets: durationBuckets.map(() => 0)
  };

  stats.sum += durationSeconds;
  stats.count += 1;

  durationBuckets.forEach((bucket, index) => {
    if (durationSeconds <= bucket) {
      stats.buckets[index] += 1;
    }
  });

  requestDurations.set(key, stats);
}

function renderMetrics() {
  const lines = [
    '# HELP http_requests_total Total number of HTTP requests.',
    '# TYPE http_requests_total counter'
  ];

  for (const [key, count] of requestCounts.entries()) {
    const labels = JSON.parse(key);
    const labelString = Object.entries(labels)
      .map(([name, value]) => `${name}="${value}"`)
      .join(',');
    lines.push(`http_requests_total{${labelString}} ${count}`);
  }

  lines.push('# HELP http_request_duration_seconds HTTP request duration in seconds.');
  lines.push('# TYPE http_request_duration_seconds histogram');

  for (const [key, stats] of requestDurations.entries()) {
    const labels = JSON.parse(key);
    const baseLabels = Object.entries(labels)
      .map(([name, value]) => `${name}="${value}"`)
      .join(',');

    durationBuckets.forEach((bucket, index) => {
      lines.push(
        `http_request_duration_seconds_bucket{${baseLabels},le="${bucket}"} ${stats.buckets[index]}`
      );
    });

    lines.push(
      `http_request_duration_seconds_bucket{${baseLabels},le="+Inf"} ${stats.count}`
    );
    lines.push(`http_request_duration_seconds_sum{${baseLabels}} ${stats.sum.toFixed(6)}`);
    lines.push(`http_request_duration_seconds_count{${baseLabels}} ${stats.count}`);
  }

  return `${lines.join('\n')}\n`;
}

const server = http.createServer((req, res) => {
  const startedAt = process.hrtime.bigint();
  const path = new URL(req.url || '/', 'http://localhost').pathname;
  let statusCode = 200;

  try {
    if (path === '/metrics') {
      res.writeHead(200, {
        'Content-Type': 'text/plain; version=0.0.4; charset=utf-8'
      });
      res.end(renderMetrics());
      return;
    }

    if (path === '/health') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ status: 'healthy' }));
      return;
    }

    if (path === '/') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ status: 'ok', result: add(2, 3) }));
      return;
    }

    statusCode = 404;
    res.writeHead(statusCode, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not found' }));
  } finally {
    const durationSeconds = Number(process.hrtime.bigint() - startedAt) / 1_000_000_000;
    observe(
      {
        method: req.method || 'GET',
        path,
        status: String(statusCode)
      },
      durationSeconds
    );
  }
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`Server running on port ${PORT}`));
```

**app/test/math.test.js** :
```javascript
const test = require('node:test');
const assert = require('node:assert/strict');
const { add, multiply, divide } = require('../src/math');

test('add returns the sum of two numbers', () => {
  assert.equal(add(2, 3), 5);
});

test('multiply returns the product of two numbers', () => {
  assert.equal(multiply(3, 4), 12);
});

test('divide throws on division by zero', () => {
  assert.throws(() => divide(1, 0), /Division by zero/);
});
```

**app/package.json** :
```json
{
  "name": "devops-demo-app",
  "version": "1.0.0",
  "private": true,
  "type": "commonjs",
  "scripts": {
    "start": "node src/index.js",
    "test": "node --test"
  }
}
```

Vérifier localement avant la CI :

```bash
cd app
npm ci
npm test
node src/index.js
# puis tester http://localhost:3000/, /health et /metrics
```

### 3. Dockerfile multi-stage

**app/Dockerfile** :
```dockerfile
# Stage 1 : Test
FROM node:20-alpine AS test
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY src ./src
COPY test ./test
RUN npm test

# Stage 2 : Production
FROM node:20-alpine AS production
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --omit=dev
COPY src/ ./src/
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/health >/dev/null || exit 1
CMD ["node", "src/index.js"]
```

### 4. Pipeline GitHub Actions

Créer `.github/workflows/ci.yml` avec ces stages :

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  # Stage 1 : Tests
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18, 20, 22]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'
          cache-dependency-path: app/package-lock.json
      - run: cd app && npm ci
      - name: Run tests
        run: |
          cd app
          set -o pipefail
          npm test 2>&1 | tee test-output.txt
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-output-node-${{ matrix.node-version }}
          path: app/test-output.txt

  # Stage 2 : Build image Docker
  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/build-push-action@v5
        with:
          context: ./app
          push: false
          tags: devops-app:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  # Stage 3 : Scan de sécurité
  security:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Scan application files
        uses: aquasecurity/trivy-action@0.33.1
        with:
          scan-type: 'fs'
          scan-ref: 'app/'
          severity: 'HIGH,CRITICAL'
          exit-code: '1'
          format: 'table'

  # Stage 4 : Deploy (simulé)
  deploy:
    needs: [build, security]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - run: echo "Deploying version ${{ github.sha }}..."
```

> Bon réflexe : dans un repo de production, pinnez les actions tierces à un **SHA complet** plutôt qu'à un tag flottant.

### 5. Améliorations à implémenter

1. **Cache npm** : déjà en place via `cache: 'npm'`
2. **Matrix build** : tester sur Node 18, 20, 22
3. **Artefacts** : déjà en place pour les résultats de test
4. **Environnement protégé** : ajouter des reviewers sur l'environnement `production`
5. **Smoke test local** : vérifier `/health` et `/metrics` après le build Docker

## Livrable
- Pipeline CI/CD fonctionnel avec 4 stages
- Matrix build sur 3 versions Node
- Cache activé
- Tests passants
- Application accessible sur `/`, `/health` et `/metrics`

## Aide

### Déclencher le pipeline
```bash
git add -A
git commit -m "ci: add multi-stage pipeline"
git push origin main
```

### Vérifier les runs
```bash
gh run list
gh run view <run-id>
```

### Debug un job qui échoue
- Aller dans l'onglet Actions du repo GitHub
- Cliquer sur le run échoué
- Lire les logs de chaque step
