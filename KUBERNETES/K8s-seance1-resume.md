# Kubernetes — Séance 1 : Architecture & RBAC
**Date :** 07 juin 2026  
**Cluster :** minikube v1.38.1 / Kubernetes v1.35.1

---

## 1. Architecture du cluster

Un cluster K8s est composé de deux types de nodes :

### Control Plane
| Composant | Rôle |
|-----------|------|
| `kube-apiserver` | Point d'entrée unique — toute communication passe par lui |
| `etcd` | Base de données clé/valeur — source de vérité du cluster |
| `kube-scheduler` | Décide sur quel node placer les Pods |
| `kube-controller-manager` | Réconcilie l'état réel vers l'état désiré |

### Worker Node
| Composant | Rôle |
|-----------|------|
| `kubelet` | Agent sur chaque node — fait tourner les containers |
| `kube-proxy` | Gère les règles réseau (iptables/IPVS) |
| Container Runtime | Exécute les containers (`containerd`) |

### Flux d'une commande `kubectl apply`
```
kubectl → API Server → etcd (stockage)
                     → Scheduler (assigne le node)
                     → Controller Manager (réconcilie)
                     → kubelet sur le node (lance le container)
```

---

## 2. Kubeconfig

Fichier `~/.kube/config` — 3 sections clés :

- **clusters** → adresses des API servers connus
- **users** → credentials (certificats, tokens)
- **contexts** → association cluster + user + namespace

```bash
kubectl config current-context     # contexte actif
kubectl config get-contexts        # liste tous les contextes
kubectl config use-context <nom>   # switcher de contexte
```

---

## 3. Authentification vs Autorisation

### Authentification — "Qui es-tu ?"
- Mécanisme minikube : **certificat TLS client**
- Le CN du certificat = username K8s
- Le O du certificat = groupe K8s

```bash
openssl x509 -in ~/.minikube/profiles/minikube/client.crt -noout -subject
# subject=O=system:masters, CN=minikube-user
```

### Autorisation — "Qu'as-tu le droit de faire ?"
- Mécanisme : **RBAC** (Role-Based Access Control)
- Deux étapes : définir les permissions → les attacher à un utilisateur

---

## 4. RBAC

### Les verbes K8s
| Verbe | Action |
|-------|--------|
| `get` | lire un objet |
| `list` | lister les objets |
| `watch` | surveiller en temps réel |
| `create` | créer |
| `update` | modifier |
| `delete` | supprimer |
| `*` | tout faire |

### Les 4 objets RBAC
| Objet | Scope | Rôle |
|-------|-------|------|
| `Role` | namespace | définit des permissions dans un namespace |
| `ClusterRole` | cluster | définit des permissions à l'échelle cluster |
| `RoleBinding` | namespace | attache un Role à un utilisateur |
| `ClusterRoleBinding` | cluster | attache un ClusterRole à l'échelle cluster |

### ClusterRoles par défaut
| Nom | Niveau d'accès |
|-----|---------------|
| `cluster-admin` | tout faire sur tout le cluster |
| `admin` | tout faire dans un namespace |
| `edit` | créer/modifier/supprimer dans un namespace |
| `view` | lecture seule dans un namespace |

---

## 5. Mise en oeuvre — Créer un utilisateur dev1

### Étape 1 — Créer l'identité (certificat)
```bash
mkdir -p ~/k8s-users/dev1 && cd ~/k8s-users/dev1

# Clé privée
openssl genrsa -out dev1.key 2048

# Demande de signature (CSR)
openssl req -new -key dev1.key -out dev1.csr -subj "/CN=dev1/O=developers"

# Signature par la CA minikube
openssl x509 -req -in dev1.csr \
  -CA ~/.minikube/ca.crt \
  -CAkey ~/.minikube/ca.key \
  -CAcreateserial \
  -out dev1.crt \
  -days 365
```

### Étape 2 — Ajouter au kubeconfig
```bash
kubectl config set-credentials dev1 \
  --client-certificate=/home/mthiam/k8s-users/dev1/dev1.crt \
  --client-key=/home/mthiam/k8s-users/dev1/dev1.key

kubectl config set-context dev1-context \
  --cluster=minikube \
  --namespace=default \
  --user=dev1
```

### Étape 3 — Créer le RoleBinding
```bash
kubectl create rolebinding dev1-view \
  --clusterrole=view \
  --user=dev1 \
  --namespace=default
```

### Étape 4 — Tester
```bash
kubectl config use-context dev1-context
kubectl get pods        # ✅ OK — lecture autorisée
kubectl run test-pod --image=nginx  # ❌ Forbidden — création interdite
kubectl get nodes       # ❌ Forbidden — ressource cluster scope

# Revenir en admin
kubectl config use-context minikube
```

---

## Points clés à retenir pour un entretien

> *"kubectl est juste un client HTTP qui sérialise mes commandes en appels REST vers l'API server."*

> *"Dans K8s il n'y a pas d'objet User — l'identité est portée par le certificat TLS. Le CN devient le username, le O devient le groupe."*

> *"RBAC sépare explicitement la définition des droits (Role) de leur attribution (RoleBinding)."*

> *"Un RoleBinding est limité à un namespace. Pour les ressources cluster (nodes, PV), il faut un ClusterRoleBinding."*

---

## Prochaine séance
- Workloads : Pod, Deployment, ReplicaSet
- ServiceAccount (comment les Pods s'authentifient à l'API server)
