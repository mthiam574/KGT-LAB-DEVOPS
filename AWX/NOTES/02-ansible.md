# Ansible - Fondamentaux

## Ce qu'est Ansible

Outil d'automatisation qui execute des actions sur des machines distantes,
depuis une seule machine (la mienne, ou un serveur central).

## Les 2 caracteristiques fondamentales

1. Fonctionnement par connexion SSH a la demande
   - Pas de demon installe en permanence sur la cible
   - Different de Puppet/Chef, qui necessitent un AGENT installe et resident
     sur chaque machine cible (processus qui tourne en tache de fond)
   - IMPORTANT : Python doit etre present sur la machine CIBLE, car les
     modules Ansible sont ecrits en Python et EXECUTES A DISTANCE sur la cible
     apres avoir ete envoyes via SSH

2. Idempotence
   - Executer deux fois le meme playbook donne le meme resultat final
   - Une tache verifie l'etat AVANT d'agir : si l'etat voulu est deja atteint,
     rien ne se passe (ex : "installer nginx" ne reinstalle pas si deja present)
   - Different d'un script bash classique qui rejoue betement chaque commande

## Deroule technique d'une tache Ansible

1. Connexion SSH a la cible
2. Envoi du code Python du module necessaire
3. Execution A DISTANCE sur la cible (interpreteur Python de la cible)
4. Recuperation du resultat, puis nettoyage

## Inventaire (le "ou") et Playbook (le "quoi")

Inventaire - exemple simple (INI) :
    [web]
    192.168.1.10
    192.168.1.11

    [db]
    192.168.1.20

Playbook - exemple simple (YAML) :
    - hosts: web
      tasks:
        - name: Installer nginx
          apt:
            name: nginx
            state: present

## Roles : decoupage reutilisable

Structure standard :
    roles/
      nginx/
        tasks/main.yml       -> les actions
        handlers/main.yml    -> actions declenchees par une tache
        templates/           -> fichiers de config generes dynamiquement
        vars/main.yml        -> variables du role
        defaults/main.yml    -> valeurs par defaut modifiables

Appel dans le playbook principal :
    - hosts: web
      roles:
        - nginx
        - firewall

Interet : reutilisable sur n'importe quel projet, comme une fonction en
programmation plutot que du code copie-colle partout.

## Handlers : notify + execution unique

Une tache speciale qui ne s'execute QUE si une autre tache a change quelque
chose, et SEULEMENT UNE FOIS a la fin, meme si plusieurs taches la declenchent.

Exemple :
    tasks:
      - name: Copier la config nginx
        template:
          src: nginx.conf.j2
          dest: /etc/nginx/nginx.conf
        notify: Redemarrer nginx

    handlers:
      - name: Redemarrer nginx
        service:
          name: nginx
          state: restarted

Cas verifie en exercice : meme si 3 taches declenchent notify sur le meme
handler (config nginx + vhost + certificat SSL, par exemple), nginx ne
redemarre qu'UNE SEULE FOIS a la fin du playbook -> evite les redemarrages
en cascade qui couperaient le service plusieurs fois inutilement.
