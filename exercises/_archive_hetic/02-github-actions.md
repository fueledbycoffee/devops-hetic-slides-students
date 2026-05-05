# GitHub Actions avancé

## Objectif
Maîtriser les fonctionnalités avancées de GitHub Actions : workflows réutilisables, secrets, environments et actions composites.

## Consignes

### 1. Workflow réutilisable

Créer `.github/workflows/reusable-docker.yml` :

```yaml
name: Reusable Docker Build

on:
  workflow_call:
    inputs:
      image-name:
        required: true
        type: string
      context:
        required: false
        type: string
        default: '.'
      dockerfile:
        required: false
        type: string
        default: 'Dockerfile'
    secrets:
      registry-username:
        required: false
      registry-password:
        required: false
    outputs:
      image-tag:
        description: "Tag de l'image construite"
        value: ${{ jobs.build.outputs.tag }}

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      tag: ${{ steps.meta.outputs.tags }}
    steps:
      - uses: actions/checkout@v4

      - name: Docker meta
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ inputs.image-name }}
          tags: |
            type=sha,prefix=
            type=ref,event=branch
            type=semver,pattern={{version}}

      - uses: docker/setup-buildx-action@v3

      - uses: docker/build-push-action@v5
        with:
          context: ${{ inputs.context }}
          file: ${{ inputs.context }}/${{ inputs.dockerfile }}
          push: false
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### 2. Appeler le workflow réutilisable

Modifier `.github/workflows/ci.yml` pour utiliser le workflow réutilisable :

```yaml
  build:
    needs: test
    uses: ./.github/workflows/reusable-docker.yml
    with:
      image-name: devops-app
      context: ./app
```

> En production, pinnez les actions tierces à un **SHA complet**. Pour les labs, gardez au minimum des versions figées et jamais `@master`.

### 3. Environnements avec protection

Configurer dans GitHub (Settings > Environments) :

| Environnement | Protection |
|---|---|
| `staging` | Aucune (déploiement auto) |
| `production` | 1 reviewer requis + wait timer 5 min |

Ajouter au pipeline :

```yaml
  deploy-staging:
    needs: build
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - run: echo "Deploying to staging..."

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment: production
    steps:
      - run: echo "Deploying to production..."
```

### 4. Secrets et variables

```yaml
    steps:
      - name: Use secrets
        env:
          DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
          API_KEY: ${{ secrets.API_KEY }}
        run: |
          echo "Secrets are masked in logs"
          echo "DB_PASSWORD length: ${#DB_PASSWORD}"
```

> **Règle** : ne JAMAIS afficher un secret dans les logs. GitHub les masque automatiquement si vous les utilisez via `${{ secrets.X }}`.

### 5. Action composite locale

Créer `.github/actions/setup-tools/action.yml` :

```yaml
name: 'Setup DevOps Tools'
description: 'Install common DevOps tools'

inputs:
  install-terraform:
    description: 'Install Terraform'
    required: false
    default: 'true'
  terraform-version:
    description: 'Terraform version'
    required: false
    default: '1.7.0'

runs:
  using: 'composite'
  steps:
    - name: Install Terraform
      if: inputs.install-terraform == 'true'
      shell: bash
      run: |
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt-get update && sudo apt-get install terraform=${{ inputs.terraform-version }}*

    - name: Verify tools
      shell: bash
      run: |
        echo "--- Installed Tools ---"
        terraform --version || echo "Terraform not installed"
        docker --version
        kubectl version --client || echo "kubectl not installed"
```

## Livrable
- 1 workflow réutilisable fonctionnel
- Environnements staging + production configurés
- Action composite locale
- Pipeline complet avec tous les éléments intégrés

## Aide

### Tester localement avec act
```bash
# Installer act (simule GitHub Actions localement)
brew install act

# Lancer le workflow
act push --workflows .github/workflows/ci.yml
```

### Débugger un workflow
Ajouter `ACTIONS_STEP_DEBUG: true` dans les secrets du repo pour avoir des logs détaillés.
