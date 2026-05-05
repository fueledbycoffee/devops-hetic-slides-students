# Docker avancé

## Objectif
Maîtriser les builds multi-stage, l'optimisation d'images, la sécurité des conteneurs et Docker Compose pour des stacks complexes.

## Consignes

### 1. Analyse d'une image non optimisée

**app/Dockerfile.bad** (l'anti-pattern) :
```dockerfile
FROM ubuntu:22.04
RUN apt-get update
RUN apt-get install -y nodejs npm curl wget git python3
COPY . /app
WORKDIR /app
RUN npm install
EXPOSE 3000
CMD ["node", "src/index.js"]
```

```bash
# Construire l'image "mauvaise"
docker build -f app/Dockerfile.bad -t app:bad app/

# Vérifier la taille
docker images app:bad
# → probablement > 500 MB !
```

### 2. Dockerfile optimisé multi-stage

**app/Dockerfile** :
```dockerfile
# ── Stage 1 : Dependencies ──
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts

# ── Stage 2 : Test ──
FROM deps AS test
COPY . .
RUN npm test

# ── Stage 3 : Production ──
FROM node:20-alpine AS production

# Sécurité : user non-root
RUN addgroup -g 1001 appgroup && \
    adduser -u 1001 -G appgroup -s /bin/sh -D appuser

WORKDIR /app

# Copier seulement les deps de production
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts && \
    npm cache clean --force

# Copier le code source
COPY --from=deps /app/node_modules ./node_modules
COPY src/ ./src/

# Métadonnées
LABEL maintainer="devops-team"
LABEL version="1.0"

# Sécurité : filesystem read-only compatible
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

CMD ["node", "src/index.js"]
```

```bash
# Construire l'image optimisée
docker build -t app:optimized app/

# Comparer les tailles
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep app
# app:bad        → ~500 MB
# app:optimized  → ~80 MB
```

### 3. Sécurité des images

```bash
# Scanner avec Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image app:optimized

# Vérifier que le conteneur ne tourne pas en root
docker run --rm app:optimized whoami
# → appuser

# Inspecter les layers
docker history app:optimized
```

### 4. Docker Compose — stack complète

Créer `docker-compose.yml` à la racine :

```yaml
services:
  # Application
  app:
    build:
      context: ./app
      target: production
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_NAME=appdb
      - DB_USER=appuser
      - DB_PASSWORD=secret
      - REDIS_URL=redis://redis:6379
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    restart: unless-stopped
    networks:
      - app-net

  # Base de données
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: secret
    volumes:
      - pg-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U appuser -d appdb"]
      interval: 5s
      timeout: 3s
      retries: 5
    networks:
      - app-net

  # Cache
  redis:
    image: redis:7-alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5
    networks:
      - app-net

  # Reverse proxy
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - app
    networks:
      - app-net

volumes:
  pg-data:

networks:
  app-net:
    driver: bridge
```

### 5. Nginx reverse proxy

Créer `nginx/default.conf` :

```nginx
upstream app_backend {
    server app:3000;
}

server {
    listen 80;

    location / {
        proxy_pass http://app_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /health {
        return 200 '{"status": "ok"}';
        add_header Content-Type application/json;
    }
}
```

### 6. Lancer et vérifier

```bash
# Démarrer la stack
docker compose up -d

# Vérifier les services
docker compose ps
docker compose logs app

# Tester
curl http://localhost:80
curl http://localhost:80/health

# Arrêter
docker compose down -v
```

## Livrable
- Dockerfile multi-stage optimisé (< 100 MB)
- Conteneur non-root avec healthcheck
- Stack Docker Compose avec app + postgres + redis + nginx
- Comparaison taille image avant/après optimisation

## Aide

### .dockerignore
```
node_modules
.git
.github
*.md
Dockerfile*
docker-compose*
.env*
```

### Debug un conteneur
```bash
# Shell dans un conteneur running
docker exec -it devops-app-1 sh

# Logs en temps réel
docker compose logs -f app

# Inspecter un conteneur
docker inspect devops-app-1
```
