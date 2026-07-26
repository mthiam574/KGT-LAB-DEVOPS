# K8s - Objets fondamentaux (Pod, Deployment, Service, Namespace)

Source : Formation Dyma - "03 - Les fondamentaux sur les objets Kubernetes"

## Objets Kubernetes - généralités

- Un objet K8s est une **entité persistante** = un enregistrement d'intention
- Le Control Plane réconcilie en permanence **spec** (état voulu) ↔ **status** (état réel)

## Pod

- Plus petite unité déployable, jamais un conteneur seul
- Un ou plusieurs conteneurs partageant réseau (même IP) et stockage (Volumes)
- Cas d'usage multi-conteneurs : pattern **sidecar** (ex: appli + collecteur de logs)

### Cycle de vie du Pod

**Phases** :
- Pending → Running → Succeeded / Failed / Unknown
- "Terminating" n'est **pas** une phase officielle, juste un affichage kubectl
- Grace period 30s : SIGTERM (arrêt propre demandé) puis SIGKILL (arrêt forcé) si le conteneur ne s'est pas arrêté

**États des conteneurs** (utile pour diagnostiquer) :
- Waiting (ex: `ImagePullBackOff`, `CrashLoopBackOff`)
- Running
- Terminated (avec exit code, ex: 137 = tué par SIGKILL, souvent OOM)

**RestartPolicy** (définie dans le `template` du Pod) :
- `Always` (défaut) - pour un Deployment (appli continue)
- `OnFailure` - pour un Job (tâche ponctuelle, retry si erreur)
- `Never` - tâche ponctuelle sans retry automatique
- Backoff exponentiel : 10s → 20s → 40s... plafonné à 5 min. Reset après 10 min de fonctionnement stable.

**Conditions** (séquentielles) :
```
PodScheduled → Initialized → ContainersReady → Ready
```
- Le Service se base sur `Ready` pour décider si le Pod reçoit du trafic

**Diagnostic principal** : `kubectl describe pod <nom>`

## Labels et sélecteurs

- **Labels** = paires clé/valeur sur les objets, pour identifier/grouper/sélectionner → couplage lâche entre objets (Service ↔ Pods, Deployment ↔ Pods)
- Convention standard : `app.kubernetes.io/*` (name, instance, version, component, part-of, managed-by) → reconnue par les outils tiers (Helm, Prometheus, Grafana)
- Labels définis dans `metadata` du Pod (ou du `template.metadata` si géré par un Deployment)
- Sélecteurs définis sur l'objet qui cible ces Pods (Service, Deployment...)

### Types de sélecteurs

- **matchLabels** : égalité stricte, ET logique
```yaml
selector:
  matchLabels:
    app: nginx
    environment: production
```
- **matchExpressions** : opérateurs In / NotIn / Exists / DoesNotExist
```yaml
selector:
  matchExpressions:
    - {key: app, operator: In, values: [nginx, mysql]}
```
- Utile quand on a besoin de plusieurs valeurs possibles pour une même clé, ou juste vérifier présence/absence d'un label

### Commandes
```bash
kubectl get pods --show-labels
kubectl get pods -l app=nginx
kubectl get pods -l 'app in (nginx, mysql)'
kubectl get pods -l environment=production,tier!=frontend
```

## ReplicaSet

- Garantit un nombre X de replicas de Pods (**auto-healing**)
- Identifie ses Pods via labels (`ownerReferences`)
- **Jamais utilisé directement** : le Deployment le pilote pour ajouter rolling updates, rollback, pause/resume

### Commandes
```bash
kubectl describe replicaset
kubectl get pods
kubectl delete pod <nom-pod>   # le RS recrée un Pod automatiquement
```

## Deployment

- Gère un ReplicaSet qui gère des Pods
- Chaque changement d'image → nouveau ReplicaSet créé → rolling update progressif, l'ancien conservé pour permettre le rollback

### Stratégies
```yaml
spec:
  replicas: 3
  strategy:
    type: RollingUpdate           # ou Recreate
    rollingUpdate:
      maxUnavailable: 1           # Pods indisponibles max pendant update
      maxSurge: 1                 # Pods supplémentaires max pendant update
```

- **RollingUpdate** : mise à jour progressive, sans coupure (défaut)
- **Recreate** : supprime tout puis recrée - utilisé quand deux versions ne peuvent pas cohabiter (migration DB incompatible, stockage exclusif)

- **maxUnavailable** : combien de Pods peuvent être absents pendant l'update
- **maxSurge** : combien de Pods en plus du nombre voulu peuvent être créés temporairement
- `maxUnavailable: 0` + `maxSurge: 1` = zéro interruption, capacité garantie à 100%, coûte des ressources en plus
- `maxUnavailable: 1` + `maxSurge: 0` = économise des ressources, capacité réduite pendant l'update

### Commandes
```bash
kubectl rollout status deployment/mon-deployment
kubectl rollout history deployment/mon-deployment
kubectl rollout undo deployment/mon-deployment
kubectl rollout undo deployment/mon-deployment --to-revision=2
kubectl rollout pause deployment/mon-deployment
kubectl rollout resume deployment/mon-deployment
kubectl scale deployment mon-deployment --replicas=5
```

- `rollout undo` fonctionne car le Deployment garde en mémoire les anciens ReplicaSets (`revisionHistoryLimit`)

## Service

- IP stable + nom DNS fixe pour un groupe de Pods, load balancing, routage via sélecteurs de labels
- Ne fait pas que "réseau" : exposition + load balancing, ce n'est pas le réseau global du cluster (géré par CNI + kube-proxy)

### Mécanisme interne

**Endpoints / EndpointSlice** : liste des IP réelles des Pods qui matchent le selector, mise à jour en continu
```bash
kubectl get endpoints mon-service
```
- Un Pod qui passe `Ready: false` est retiré des Endpoints → plus de trafic, même si le Pod est toujours Running

**kube-proxy** : tourne sur chaque node, surveille l'API server, traduit les Endpoints en règles de routage réseau local
- Modes : **iptables** (courant, mais problème de scalabilité à grande échelle - verrou d'écriture global), **IPVS** (plus performant), **userspace** (obsolète)

**Chemin réel d'une requête** :
1. En amont (préparation, pas à chaque requête) : kube-proxy surveille l'API server → détecte Endpoints → écrit règles iptables/IPVS sur le node
2. Requête réelle : Client → IP du Service → règles déjà en place interceptent → redirection directe vers un Pod
- **L'API server n'est jamais sur le chemin du trafic applicatif**

### Types de Service

- **ClusterIP** (défaut) : interne au cluster uniquement
- **NodePort** : port fixe (30000-32767) sur chaque node, accessible de l'extérieur
- **LoadBalancer** : IP publique via load balancer cloud - nécessite un cloud provider compatible (sinon reste `pending`, sauf MetalLB/minikube tunnel en local)
- **ExternalName** : mapping DNS vers une ressource externe, pas de routage vers des Pods

### Commandes
```bash
kubectl get svc
kubectl get endpoints mon-service
kubectl describe svc mon-service
kubectl port-forward svc/mon-service 8080:80
```
- Si un Service ne route vers aucun Pod → vérifier avec `describe svc` que le selector correspond aux labels réels des Pods

## Namespace

- Division virtuelle du cluster (cloisonnement logique, pas physique)

### Ce qu'un Namespace isole
- Les noms d'objets (pas de conflit entre namespaces différents)
- Le scope RBAC (Role/RoleBinding)
- Les quotas de ressources (ResourceQuota)

### Ce qu'un Namespace N'isole PAS (piège fréquent)
- **Le réseau** : par défaut, tout Pod peut communiquer avec tout autre Pod, peu importe le Namespace, sauf **NetworkPolicy** explicite
- Les objets cluster-wide (Node, PersistentVolume, Namespace lui-même) n'appartiennent à aucun Namespace

### Namespaces par défaut
```
default          # objets sans namespace précisé
kube-system      # composants internes (kube-proxy, CoreDNS...)
kube-public      # infos publiques
kube-node-lease  # heartbeats des nodes
```

### Commandes
```bash
kubectl get namespaces
kubectl create namespace mon-ns
kubectl get pods -n mon-ns
kubectl get pods --all-namespaces
kubectl config set-context --current --namespace=mon-ns
```

## Fil logique à retenir

Pod (l'unité) → Deployment (la maintient et la fait évoluer via ReplicaSet) → Service (l'expose de façon stable via Endpoints + kube-proxy) → le tout organisé dans un Namespace (isolation logique, pas réseau).
