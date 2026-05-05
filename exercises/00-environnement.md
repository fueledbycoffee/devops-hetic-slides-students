# Setup environnement

## Objectif
Avoir un poste opérationnel pour les 4 jours : Git, Node, Docker, compte GitHub, repo cloné, starter technique qui tourne.

## Pré-requis système
- Un terminal (bash / zsh sur macOS/Linux, WSL2 + Ubuntu sur Windows)
- Connexion internet
- Compte GitHub actif

## Consignes

### 1. Vérifier les outils

```bash
git --version            # >= 2.30
node --version           # >= 20
npm --version            # >= 10
docker --version         # >= 24
```

Si une commande manque, installer (instructions plus bas).

### 2. Configurer Git

```bash
git config --global user.name "Prénom Nom"
git config --global user.email "vous@exemple.fr"
git config --global init.defaultBranch main
git config --global pull.rebase true
```

### 3. Authentification GitHub (SSH recommandé)

```bash
# Générer une clé SSH si vous n'en avez pas
ssh-keygen -t ed25519 -C "vous@exemple.fr"

# Afficher la clé publique
cat ~/.ssh/id_ed25519.pub

# Copier puis ajouter sur GitHub : Settings → SSH and GPG keys → New SSH key

# Tester
ssh -T git@github.com
# Réponse attendue : "Hi <user>! You've successfully authenticated..."
```

### 4. Cloner le repo de formation

```bash
git clone git@github.com:<votre-fork-ou-le-repo>/devops-coda-slides.git
cd devops-coda-slides
```

### 5. Lancer le starter technique

```bash
cd starter-code/app
npm ci
npm test
npm start &
```

Vérifier que les endpoints répondent :

```bash
curl http://localhost:3000/
curl http://localhost:3000/health
curl http://localhost:3000/metrics
```

Arrêter l'app avec `kill %1` ou `Ctrl+C`.

### 6. Vérifier Docker

```bash
docker run --rm hello-world
docker pull node:20-alpine
```

## Installation des outils manquants

### macOS (Homebrew)
```bash
brew install git node
brew install --cask docker
```

### Ubuntu / Debian / WSL2
```bash
sudo apt update
sudo apt install -y git curl
# Node via nvm
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
source ~/.bashrc
nvm install 20
# Docker
sudo apt install -y docker.io
sudo usermod -aG docker $USER
# se déconnecter / reconnecter pour activer le groupe
```

### Windows natif
Activer WSL2 + Ubuntu, puis suivre les instructions Ubuntu ci-dessus depuis le shell Ubuntu. Ne pas faire le cours depuis PowerShell.

## Livrable
- [ ] `git --version`, `node --version`, `docker --version` retournent une version récente
- [ ] `ssh -T git@github.com` répond `Hi <user>!`
- [ ] Repo cloné, `starter-code/app` testé en local, 3 endpoints (`/`, `/health`, `/metrics`) qui répondent
- [ ] `docker run hello-world` réussit

## Aide

**SSH `Permission denied (publickey)`** : la clé n'est pas chargée. `ssh-add ~/.ssh/id_ed25519` puis retenter. Sur macOS, ajouter dans `~/.ssh/config` :
```
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```

**`docker: permission denied`** sur Linux : ajouter votre user au groupe `docker` (`sudo usermod -aG docker $USER`) puis se reconnecter.

**Le port 3000 est occupé** : `lsof -i :3000` pour trouver le PID, `kill <PID>`. Ou lancer l'app sur un autre port : `PORT=3001 npm start`.

**`npm ci` échoue** : supprimer `node_modules/` et `package-lock.json`, retenter `npm install`.

**Windows + Docker Desktop** : vérifier que WSL2 integration est activé pour la distribution Ubuntu (Settings → Resources → WSL integration).
