# K8s - Leçon 2 : Architecture

Source : Formation Dyma - Architecture Kubernetes

## Le cluster

Un **cluster** K8s est un ensemble de **nodes** (nœuds) qui exécutent des applications conteneurisées.

Il existe deux types de nodes :
- **Control Plane** (master node) : orchestre et gère le cluster
- **Worker nodes** : exécutent les applications (Pods)

## Composants du Control Plane

| Composant | Rôle |
|---|---|
| `kube-apiserver` | Point d'entrée unique de l'API K8s — toute communication passe par lui |
| `etcd` | Base de données clé/valeur, sauvegarde l'état du cluster (source de vérité) |
| `kube-scheduler` | Assigne les Pods aux nodes |
| `kube-controller-manager` | Ensemble de controllers avec responsabilité précise (Node, Replication, Endpoints, ServiceAccount controllers) — réconcilie l'état réel vers l'état désiré |
| `cloud-controller-manager` | Intégration avec l'API du cloud provider |

## Composants du Worker Node

| Composant | Rôle |
|---|---|
| `kubelet` | S'assure que les conteneurs tournent dans les Pods |
| `kube-proxy` | Gère les règles réseau des nodes (iptables/IPVS) |
| Container runtime | Exécute les conteneurs (containerd, CRI-O) |

## Flux d'une commande `kubectl apply`

```
kubectl → API Server → etcd (stockage)
                     → Scheduler (assigne le node)
                     → Controller Manager (réconcilie)
                     → kubelet sur le node (lance le container)
```

## Point important : cluster managé vs local

- **Cluster managé** (EKS, GKE, AKS) : le Control Plane est géré par le cloud provider, invisible pour l'utilisateur — on ne voit que les Worker Nodes
- **Cluster local/on-premise** (minikube, ton cas) : tu gères ou vois les deux types de nodes

Bon réflexe en entretien si on te demande "combien de nodes control plane as-tu ?" — la réponse dépend du type de cluster.

## Kubeconfig

Fichier `~/.kube/config` — 3 sections clés :
- **clusters** → adresses des API servers connus
- **users** → credentials (certificats, tokens)
- **contexts** → association cluster + user + namespace

```bash
kubectl config current-context     # contexte actif
kubectl config get-contexts        # liste tous les contextes
kubectl config use-context <nom>   # switcher de contexte
```

## Lien avec la Leçon 1

Le Control Plane est la brique qui exécute concrètement le principe de réconciliation spec ↔ status vu en Leçon 1 : `kube-scheduler` place les Pods, `kube-controller-manager` corrige les écarts entre l'état réel et l'état désiré.
