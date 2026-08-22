# Scenario patching canary - modelisation

## Contexte type

Parc de N serveurs web en production (VMs VMware sur cluster ESXi).
Objectif : appliquer un patch de securite SANS risquer de tout casser
d'un coup si le patch pose probleme.

Principe canary : commencer par un PETIT sous-ensemble ("canaris"), verifier,
PUIS seulement etendre au reste. Nom venant des canaris dans les mines,
qui alertent avant que le danger touche tout le monde.

## Etapes detaillees

### 1. Audit / drift-check (en amont, AVANT tout patch)
- Job Template en mode --check (dry-run)
- Compare l'etat reel des VMs a l'etat attendu, SANS rien modifier
- Objectif : s'assurer que le parc est homogene avant de commencer
- Pourquoi c'est indispensable : si les VMs canary ont deja derive par
  rapport au reste du parc, la validation canary devient FAUSSE (le patch
  peut reussir sur les canaris a cause de leur config particuliere, et
  echouer sur le reste - ou l'inverse)
- Le drift se traite structurellement via l'idempotence : si TOUT passe
  par Ansible/AWX (jamais de modification manuelle en SSH), la derive ne
  peut pas apparaitre, chaque run corrige les ecarts automatiquement

### 2. Inventaire dynamique (AWX + vCenter)
- AWX interroge vCenter, recupere les VMs groupees par tags
  (ex : env=prod, role=web)
- Pas de liste statique a maintenir : une VM ajoutee dans vCenter apparait
  automatiquement dans le bon groupe

### 3. Decoupage canary
- Sous-groupe canary defini sur 5-10% du parc, via :
  - un tag dedie dans vCenter (patch_wave=canary), OU
  - une limite Ansible directe : serial: 2 dans le playbook

### 4. Snapshot des VMs canary (avant le patch)
- Photo de l'etat exact (disque + memoire) juste avant l'operation
- C'est le filet de securite qui permet le rollback ensuite
- Rejoint directement le concept HA vu en VMware : necessite un stockage
  qui permette cette restauration rapide

### 5. Job Template #1 : Patch canary
- Playbook de patching lance UNIQUEMENT sur le groupe canary (2-3 VMs)
- Credential utilise : compte de service avec acces sudo (jamais visible
  par l'utilisateur qui lance le job)

### 6. Job Template #2 : Verification
- Healthchecks, services up, pas d'erreurs dans les logs
- Peut etre automatise (playbook de verification) ou une etape manuelle
  d'observation avant de continuer

### 7. Workflow Template : logique conditionnelle
Enchainement complet :
    Patch canary -> Verification
                      |
          +-----------+-----------+
          | SUCCES                | ECHEC
          v                        v
    Patch reste du parc      Rollback (restauration snapshot)
    (47 autres VMs)          + Alerte equipe (mail/Slack, logs joints)

Point cle : le reste du parc n'est JAMAIS touche si l'etape precedente
a echoue - le Workflow Template ne declenche l'etape suivante QUE si la
precedente a reussi.

## A valoriser en entretien

- Logique universelle en gestion de risque (petit perimetre -> validation
  -> extension), transferable depuis les cas BUILD/CAB / patching UBS
  meme si le tooling y etait different (Autosys, scripts maison)
- Le drift-check en amont est ce qui distingue une vraie strategie canary
  fiable d'un simple "on teste sur 2 machines et on espere"
