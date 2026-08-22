# AWX sur Minikube - Lab KGT

## Objectif
Deployer AWX (orchestrateur Ansible open source) sur un cluster Kubernetes local (Minikube),
dans le cadre de la preparation au poste Legrand (Senior Infrastructure Administrator, Hosting EMEA).

## Architecture

    Debian (mthiam)
      -> Docker (pilote Minikube)
            -> Minikube (cluster Kubernetes local, 1 noeud)
                  -> Namespace "awx"
                        - awx-operator-controller-manager (2/2) : l'Operator
                        - awx-postgres-15-0 (1/1) : base de donnees
                        - awx-web (3/3) : interface web + API
                        - awx-task (4/4) : moteur d'execution des jobs

## Prerequis
- Minikube installe (deja present, servait a la formation Dyma Kubernetes)
- Docker comme driver Minikube
- Au moins 8 Go RAM / 4 CPU alloues a Minikube

## Emplacement des fichiers
- SCRIPTS/awx-operator/ : clone officiel du repo ansible/awx-operator (tag 2.19.1), NE PAS MODIFIER
- SCRIPTS/deploy/ : notre surcouche Kustomize (kustomization.yaml + awx-instance.yaml)

## Deploiement - etapes realisees

1. Demarrage Minikube :
   minikube start --cpus=4 --memory=8000 --addons=ingress

2. Clone du repo officiel, checkout sur tag stable :
   git clone https://github.com/ansible/awx-operator.git
   git checkout 2.19.1

3. Creation de notre surcouche deploy/kustomization.yaml (voir Incident #1 ci-dessous)

4. Creation de deploy/awx-instance.yaml (declare l'objet AWX, service NodePort port 30080)

5. Deploiement complet :
   kubectl apply -k deploy

## Acces a l'interface

   minikube service awx-service -n awx --url

- Utilisateur : admin
- Mot de passe :
   kubectl get secret awx-admin-password -n awx -o jsonpath="{.data.password}" | base64 --decode

## Incident #1 - image kube-rbac-proxy cassee (resolu)

Symptome : pod awx-operator-controller-manager en ErrImagePull / ImagePullBackOff
sur le conteneur kube-rbac-proxy.

Cause : l'image gcr.io/kubebuilder/kube-rbac-proxy:v0.15.0 referencee dans le manifest
officiel a ete retiree du registre (projet discontinue par l'equipe kubebuilder, dernier
tag publie en 2023). Confirme par issue GitHub ansible/awx#16335 et ansible/awx-operator#2107.

Correctif : surcharge de l'image via Kustomize, sans modifier le repo officiel clone.

Contenu de SCRIPTS/deploy/kustomization.yaml :

   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   namespace: awx
   resources:
     - ../awx-operator/config/default
     - awx-instance.yaml
   images:
     - name: quay.io/ansible/awx-operator
       newTag: 2.19.1
     - name: gcr.io/kubebuilder/kube-rbac-proxy
       newName: quay.io/brancz/kube-rbac-proxy
       newTag: v0.18.1

Bonne pratique retenue : ne jamais modifier le repo officiel clone directement ;
toujours surcharger via une couche Kustomize separee (meme logique que "ne jamais
editer un role Ansible tiers, l'etendre ou le surcharger via des variables").

## Concepts cles valides pendant ce deploiement

- CRD (CustomResourceDefinition) : apprend a Kubernetes le type d'objet "AWX"
- Operator pattern : un pod qui execute en interne un playbook Ansible pour construire/
  maintenir l'etat declare (mecanisme visible dans les logs : TASK [installer : ...])
- NodePort : exposition simple d'un service hors du cluster (utilise ici plutot que
  l'Ingress, car ingress-nginx est en fin de vie - controller archive le 24/03/2026,
  successeur = Gateway API)

## Prochaines etapes
- Creer un vrai Credential SSH pointant vers une VM du lab KGT-LAB-DEVOPS
- Creer un Inventory (statique dans un premier temps, dynamique vCenter plus tard si acces Legrand)
- Creer un Job Template de test (ping / uptime)
- Construire le scenario patching canary complet dans l'interface
