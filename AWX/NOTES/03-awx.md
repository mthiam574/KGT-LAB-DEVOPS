# AWX - Orchestrateur Ansible

## Pourquoi AWX existe

Avec Ansible CLI seul (ansible-playbook depuis mon poste), plusieurs choses
reposent sur moi seul :
- inventaire en fichier local, mis a jour a la main
- credentials geres individuellement (~/.ssh, Vault local)
- aucune trace centralisee de qui a lance quoi, quand
- personne d'autre ne peut relancer un job proprement en mon absence

AWX = surcouche web + API par-dessus Ansible qui centralise tout ca.
AWX n'execute jamais rien lui-meme directement : en dessous, c'est toujours
le meme moteur ansible-playbook qui tourne. AWX orchestre autour.

Formule retenue : "AWX est l'orchestrateur d'Ansible."

## Les 4 briques principales

### 1. Credentials
- Objet chiffre qui reference un acces (cle SSH, mot de passe...)
- JAMAIS visible en clair, meme par l'utilisateur qui l'utilise pour lancer un job
- Analogie : un badge d'acces a une porte, sans jamais montrer la cle physique
  dans la serrure. Le badge (droit d'usage) est assignable a plusieurs personnes,
  la cle reelle reste unique et geree en interne par AWX.
- Ce N'EST PAS le Credential qui trace : c'est le JOB qui trace (qui, quand,
  quoi, avec quel credential NOMME - jamais son contenu -, quel resultat)

### 2. Inventory (peut etre dynamique)
- Meme principe que l'inventaire Ansible CLI, mais peut etre GENERE
  automatiquement depuis une source externe (vCenter, AWS, Git...)
- Le regroupement se fait via des METADONNEES/TAGS lus sur la source externe
- Exemple avec vCenter : chaque VM a des attributs (dossier, tags VMware,
  cluster, OS...). Une regle definie dans AWX transforme ca en groupe :
      groups:
        web_servers: "'web' in tags"
        prod: "folder == 'Production'"
- Analogie directe : exactement le meme principe que les LABELS Kubernetes
  (app=web, env=prod) - on tague a la source, AWX retrouve les bons groupes
  automatiquement a chaque run, sans fichier a maintenir a la main

### 3. Projects
- La source des playbooks = TOUJOURS un repo Git (jamais modifie a la main
  directement dans AWX)
- AWX clone le repo, le garde synchronise automatiquement avant chaque run
- Pourquoi c'est important :
  1. Travail d'equipe (PR, reviews, historique clair de qui a change quoi)
  2. Tracabilite complete du CONTENU (en plus de la tracabilite du JOB) :
     si un playbook change, c'est visible dans l'historique Git
  3. Evite la derive : garantit que ce qui s'execute = ce qui est versionne,
     jamais une version qui aurait diverge en etant editee directement dans AWX

### 4. Job Templates (+ Workflow Templates)
- Un Job Template assemble : Project (playbook) + Inventory + Credential(s)
  + variables eventuelles = un job PRET A LANCER en un clic
- Equivalent a une commande "ansible-playbook -i inventory.ini patch.yml
  --extra-vars ..." mais PRE-CONFIGUREE et accessible a tout utilisateur
  autorise, sans qu'il ait besoin de connaitre les details techniques
- Workflow Template : enchaine PLUSIEURS Job Templates avec une logique
  CONDITIONNELLE (si succes -> etape suivante ; si echec -> rollback)
  C'est le "plus" par rapport a Ansible CLI seul, impossible a faire
  proprement sans script maison complexe

## AWX vs AAP (Ansible Automation Platform)

- AWX = projet open source (upstream), gratuit
- AAP = version commerciale Red Hat, avec support/SLA
- Sur OpenShift avec AAP : l'objet ne s'appelle plus "AWX" mais
  "AutomationController", deploiement via l'Ansible Automation Platform
  Operator (interface graphique OpenShift plutot que Kustomize en ligne
  de commande)
- Le socle conceptuel reste identique (CRD, pattern Operator, "etat
  declare -> Ansible interne qui applique") - donc transferable entre les deux
