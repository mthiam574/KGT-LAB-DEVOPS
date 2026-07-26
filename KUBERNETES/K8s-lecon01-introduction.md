# K8s - Leçon 1 : Introduction générale

Source : Formation Dyma - Introduction à Kubernetes

## Définition

Kubernetes (K8s) est un **orchestrateur de conteneurs open-source**, écrit en **Go**, initialement développé par **Google**.

**Origine** : basé sur **Borg**, le système d'orchestration interne de Google. Open-sourcé en **juin 2014**, donné à la **CNCF** (Cloud Native Computing Foundation) en 2015, qui a publié la **v1.0**. Point souvent demandé en entretien : "d'où vient K8s ?"

## Fonctionnalités clés

- **Déploiement automatisé**, scaling (auto-scaling), rolling updates, rollback
- **Portabilité multi-cloud** (local, public, hybride)
- **Service discovery & Load Balancing** natif
- **Auto healing** : redémarre les conteneurs en échec
- **Gestion des secrets et des configurations**

## "Le système d'exploitation du cloud"

K8s est parfois appelé ainsi car il fait, à l'échelle d'un cluster de machines, ce qu'un OS classique fait sur une seule machine :

| OS classique | Kubernetes |
|---|---|
| Gère des processus sur 1 machine | Gère des Pods sur un cluster de machines |
| Les lance, surveille, redémarre si crash | Idem (auto-healing, restartPolicy) |
| Alloue CPU/mémoire aux processus | Alloue CPU/mémoire aux Pods |

Différence clé : un OS classique raisonne sur 1 processus / 1 machine. K8s raisonne en **désiré vs réel, sur un ensemble de machines** (boucle de réconciliation).

## Le principe central : réconciliation spec ↔ status

K8s **pilote l'état courant vers l'état désiré**, en continu :

- **spec** = ce que tu veux (déclaré dans le YAML, ex : `replicas: 3`)
- **status** = l'état observé réellement à l'instant T (ex : 2 Pods actuellement Running)
- Le **Control Plane** compare en permanence spec ↔ status, et corrige dès qu'il y a un écart

C'est un modèle **déclaratif** (je décris l'état voulu) et non **impératif** (je lance une action ponctuelle) : cette logique de réconciliation est le fil conducteur qu'on retrouve derrière tous les objets K8s (Pod, Deployment, ReplicaSet...).

## Note

L'**architecture détaillée** (Control Plane / Worker Nodes, composants kube-apiserver, etcd, scheduler, controller-manager, kubelet, kube-proxy) fait l'objet de la Leçon 2 — déjà documentée dans `K8s-seance1-resume.md` (section "Architecture du cluster").

Nuance à retenir de cette leçon : sur un cluster **managé** (EKS, GKE, AKS), le Control Plane est géré par le cloud provider et invisible pour l'utilisateur — seuls les Worker Nodes sont visibles. Sur minikube ou on-premise, les deux sont gérés/visibles.
