
## 18-19/08/2026 - Premier deploiement AWX reussi

- Theorie complete VMware (ESXi/vCenter/vSphere), Ansible (idempotence, roles, handlers),
  AWX (Credentials, Inventory dynamique, Projects, Job Templates)
- Scenario patching canary modelise (audit drift -> snapshot -> canary -> validation ->
  workflow conditionnel -> rollback)
- Installation AWX sur Minikube (deja present sur la Debian, utilise pour formation Dyma K8s)
- Incident rencontre et resolu (avec assistance ciblee) : image
  gcr.io/kubebuilder/kube-rbac-proxy:v0.15.0 introuvable (registre retire) -> correctif
  par surcouche Kustomize plutot que modification du repo officiel
- AWX accessible, connexion reussie sur http://192.168.49.2:30080

Bon retour d'experience a valoriser en entretien : troubleshooting reel d'un
ImagePullBackOff, lecture d'events Kubernetes, correction propre sans bricoler la source.
