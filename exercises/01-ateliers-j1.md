# Ateliers J1 : démarche DevOps

## Objectif
Mettre en pratique la grille de lecture DevOps (3 voies, CALMS, DORA) sur des cas réels et fictifs.

4 ateliers : 3 en groupe (collaboratif) + 1 individuel à emporter.

---

## Atelier 1 : Blame culture & post-mortem (≈ 1h)

### Contexte
Une orga DevOps mature pratique des post-mortems **blameless**. Un post-mortem blameful cherche le coupable ; un blameless cherche les conditions systémiques qui ont permis l'incident.

### Consignes

1. Choisir **un** des incidents publics suivants :
   - **Knight Capital (août 2012)** — perte de 440 M$ en 45 minutes à cause d'un déploiement mal fait
   - **GitLab (janvier 2017)** — un opérateur supprime la base de production par erreur, 6h de downtime
   - **AWS S3 us-east-1 (février 2017)** — typo dans une commande de maintenance, demi-internet down
   - **Cloudflare (juillet 2019)** — un déploiement de regex CPU-bound met l'edge worldwide à plat

2. Lire 2-3 sources publiques (post-mortem officiel, articles).

3. Rédiger un post-mortem blameless de **1 page maximum** structuré ainsi :
   - **Résumé** (3 lignes max)
   - **Timeline** (chronologie factuelle, sans noms)
   - **Causes systémiques** (5 max — pas une seule personne, des conditions qui rendaient l'incident possible)
   - **Actions correctives** (3 à 5 — concrètes, mesurables)
   - **Métriques DORA touchées** (lesquelles auraient empiré, et de combien estimé)

4. Restitution croisée : 5 min par groupe, 10 min de discussion.

### Livrable
1 post-mortem blameless par groupe, partagé avec la promo.

---

## Atelier 2 : Audit Acme SaaS (≈ 1h30)

### Contexte
**Acme SaaS** — éditeur B2B, 30 devs, produit en production depuis 4 ans.

État des lieux observé :
- Déploiements tous les **3 mois**, le week-end, par un sénior qui « connaît la prod »
- **1 incident sur 3 déploiements** entraîne un rollback ou un hotfix en urgence
- Les ops accusent les devs de pousser du code « pas testé » ; les devs accusent les ops de bloquer les release pour rien
- Tests automatisés : `0` (oui, zéro)
- Build : un script bash maison sur le poste du sénior
- Monitoring : un Slack channel `#alerts-prod` que personne ne lit
- Documentation : un wiki d'il y a 3 ans, jamais à jour

### Consignes

En groupes de 2-3, produire un **rapport d'audit** structuré :

1. **Frictions identifiées** (≥ 5) — utiliser les **3 voies** (Flux / Feedback / Apprentissage) comme grille
2. **Score CALMS** estimé (Culture / Automation / Lean / Measurement / Sharing) — 1 à 5 par lettre, avec justification
3. **Niveau DORA estimé** :
   - Deployment Frequency
   - Lead Time for Changes
   - MTTR
   - Change Failure Rate
   - Classement : Elite / High / Medium / Low ?
4. **Plan d'action priorisé** :
   - 3 actions à 3 mois (quick wins)
   - 3 actions à 6 mois
   - 2 actions à 12 mois (transformations profondes)

### Contraintes
- Ne pas écrire « installer Jenkins » : décrire **les comportements** qu'on veut voir changer, pas seulement les outils
- Pour chaque action, indiquer **quelle métrique DORA** elle vise à améliorer

### Livrable
1 rapport d'audit par groupe (1 à 2 pages). Restitution : 7 min par groupe.

---

## Atelier 3 : Mesurer DORA sur un projet OSS (≈ 1h)

### Contexte
Les métriques DORA sont mesurables sur n'importe quel repo public via les données GitHub.

### Consignes

1. Choisir un repo public actif. Suggestions :
   - `vercel/next.js`
   - `nodejs/node`
   - `rust-lang/rust`
   - `kubernetes/kubernetes`
   - `microsoft/vscode`
   - Ou un repo de votre choix avec ≥ 50 stars et ≥ 10 contributeurs

2. Estimer les **4 métriques DORA** sur les **30 derniers jours** :

   - **Deployment Frequency** : nombre de releases / tags ou de merges sur `main` (`gh release list --limit 100` ou onglet Releases). Compter et diviser par 30.
   - **Lead Time for Changes** : pour 5 PRs aléatoires récemment mergées, calculer `merge_date - first_commit_date`. Médiane.
   - **MTTR** : pour les 3 dernières issues étiquetées `bug` (ou similaire) qui ont été closes, calculer `closed_at - opened_at`. Médiane.
   - **Change Failure Rate** : sur 30 jours, compter les commits/PRs avec `revert`, `hotfix`, `rollback` dans le titre, divisé par le nombre total de merges sur `main`.

3. Classer le projet : **Elite / High / Medium / Low** sur chaque métrique.

4. Comparer avec **Acme SaaS** (atelier 2) : qu'est-ce qui sépare les deux ?

### Livrable
Un tableau récapitulatif (1 page) avec les 4 métriques, leurs valeurs et le classement DORA. Quelques lignes de commentaire sur ce qui explique la différence avec Acme.

### Boîte à outils

```bash
# Releases d'un repo
gh release list --repo vercel/next.js --limit 100

# PRs récemment mergées
gh pr list --repo vercel/next.js --state merged --limit 20 \
  --json number,title,mergedAt,createdAt

# Issues bugs closes
gh issue list --repo vercel/next.js --label bug --state closed --limit 20 \
  --json number,title,closedAt,createdAt
```

## Atelier 4 : Fiche perso + QCM (≈ 30 min, individuel)

À faire seul, en fin de journée. C'est ce que vous emportez chez vous comme synthèse.

### Partie A — Fiche perso CALMS (≈ 10 min)

Notez **votre orga actuelle** (stage, alternance, projet perso, ou la dernière où vous avez bossé) sur chaque pilier CALMS, de 1 à 5. Justifiez en 1 phrase chaque score.

| Pilier | Score 1-5 | Justification (1 phrase) |
|---|---|---|
| **C**ulture (ownership partagé, blameless) |   |   |
| **A**utomation (tests, build, deploy) |   |   |
| **L**ean (petits batchs, peu de WIP) |   |   |
| **M**easurement (métriques en place) |   |   |
| **S**haring (doc, pair, post-mortems) |   |   |

→ Identifiez **le pilier le plus faible**. Quelle action concrète, faisable en 2 semaines, le ferait passer de 1 à 2, ou de 2 à 3 ?

### Partie B — Mini-QCM (≈ 10 min)

Une seule réponse par question, sauf indication contraire.

**1.** DevOps est avant tout :
- a) Un poste (DevOps engineer)
- b) Un outil (Jenkins, GitHub Actions)
- c) Une démarche culturelle, organisationnelle et technique
- d) Une variante de Scrum

**2.** Les 3 voies du Phoenix Project sont (cocher les 3) :
- [ ] Le flux (Dev → Ops)
- [ ] Le marketing (Ops → Marketing)
- [ ] Le feedback (Ops → Dev)
- [ ] L'apprentissage continu
- [ ] Le contrôle financier

**3.** Une équipe DORA *Elite* déploie en moyenne :
- a) Une fois par mois
- b) Une fois par semaine
- c) Plusieurs fois par jour
- d) Une fois par trimestre

**4.** Selon les données DORA, déployer **plus souvent** :
- a) Augmente le risque d'incident
- b) N'a pas d'effet sur le risque
- c) Diminue le risque d'incident
- d) Dépend uniquement du langage utilisé

**5.** Un post-mortem **blameless** se concentre sur :
- a) Identifier le coupable
- b) Sanctionner les ops
- c) Les conditions systémiques qui ont permis l'incident
- d) Documenter pour le rapport au CEO

**6.** La métrique DORA **Change Failure Rate** mesure :
- a) Le nombre de PRs rejetées en review
- b) Le pourcentage de déploiements qui causent un incident
- c) Le temps moyen de résolution d'un bug
- d) Le ratio dev/ops dans l'équipe

**7.** Dans CALMS, la lettre la plus souvent **oubliée** dans les transformations DevOps ratées est :
- a) C (Culture)
- b) A (Automation)
- c) L (Lean)
- d) S (Sharing)

**8.** Pour quelle raison principale on **mesure** dans une démarche DevOps ?
- a) Pour faire des reportings au management
- b) Pour piloter par la donnée plutôt que par l'opinion
- c) Pour identifier les devs les moins productifs
- d) Pour facturer les clients à l'usage

### Partie C — Action 30 jours (≈ 10 min)

Vous êtes Tech Lead chez Acme SaaS (cas de l'atelier 2). Vous avez **30 jours** et un budget temps de **1 personne 50%**. Choisissez **une seule action** parmi celles que votre groupe a proposées et écrivez :

1. **L'action en 1 phrase**
2. **Le pilier CALMS** qu'elle vise (1 lettre)
3. **La métrique DORA** qu'elle vise à améliorer (1 sur 4)
4. **Comment vous mesurerez** que c'est un succès dans 30 jours (1 phrase, chiffrée)
5. **Le risque principal** de cet effort (1 phrase)

→ À rendre en fin de J1, soit sur papier, soit en commentaire d'une issue dédiée du repo binôme.

### Solutions QCM

> Voir section "Aide" à la fin du document — disponible en mode `A` du panneau TP, ou en demandant au formateur.

---

## Aide

**QCM — réponses** : 1c · 2 [flux, feedback, apprentissage] · 3c · 4c · 5c · 6b · 7a · 8b

**Atelier 1 — sources fiables** :
- Knight Capital : SEC filing 33-9416, articles du Wall Street Journal
- GitLab : `https://about.gitlab.com/blog/2017/02/10/postmortem-of-database-outage-of-january-31/` (post-mortem officiel)
- AWS S3 2017 : `https://aws.amazon.com/message/41926/` (post-mortem officiel)
- Cloudflare 2019 : `https://blog.cloudflare.com/details-of-the-cloudflare-outage-on-july-2-2019/`

**Atelier 2 — repères DORA 2024** :
- Elite : déploie plusieurs fois par jour, lead time < 1h, MTTR < 1h, CFR 0–15 %
- High : entre 1/jour et 1/semaine, lead time < 1 semaine, MTTR < 1 jour
- Medium : entre 1/semaine et 1/mois, lead time < 1 mois, MTTR < 1 jour
- Low : moins d'1/mois, lead time > 1 mois, MTTR > 1 semaine

**Atelier 3 — `gh` CLI pas installé** : `brew install gh` ou `apt install gh`. Authentifier avec `gh auth login`.

**Atelier 3 — comment compter les revert/hotfix** :
```bash
gh search prs --repo vercel/next.js --merged \
  --merged ">=$(date -d '30 days ago' +%Y-%m-%d)" \
  --json title --jq '.[] | .title' \
  | grep -iE 'revert|hotfix|rollback' | wc -l
```
