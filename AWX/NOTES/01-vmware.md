# VMware - ESXi / vCenter / vSphere

## Les 3 termes

- ESXi : hyperviseur bare-metal, installe directement sur UN serveur physique.
  Equivalent conceptuel : un Proxmox tout seul (un noeud isole).

- vCenter : pilote plusieurs ESXi ensemble depuis une seule interface.
  Equivalent conceptuel : un cluster Proxmox, ou un control-plane Kubernetes.
  C'est un logiciel a part (souvent une VM/appliance dediee), pas integre nativement
  comme peut l'etre un cluster Proxmox.

- vSphere : PAS un logiciel en soi. C'est le nom commercial de toute la suite
  (ESXi + vCenter + fonctionnalites : vMotion, DRS, HA).

## Fonctionnalites cluster (vCenter)

- vMotion : migration d'une VM a chaud, d'un ESXi a un autre du meme cluster,
  sans coupure de service.

- DRS (Distributed Resource Scheduler) : repartition automatique des VMs entre
  les ESXi du cluster selon la charge. Comparable au scheduler Kubernetes, mais
  pour des VMs entieres plutot que des Pods.

- HA (High Availability) : si un ESXi tombe, ses VMs redemarrent automatiquement
  sur un autre ESXi du cluster.

## Point cle : le stockage partage (condition de la HA)

Un ESXi = un seul serveur physique, jamais mutualise entre plusieurs machines.

Deux disques differents a distinguer :
1. Disque de boot ESXi : installe localement sur le serveur (petit SSD/carte SD/USB)
2. Datastore des VMs : DOIT etre sur un stockage partage externe (SAN/NAS),
   accessible par TOUS les ESXi du cluster en meme temps

Pourquoi c'est indispensable : si le disque d'une VM etait stocke localement sur
l'ESXi, il mourrait avec le serveur en cas de panne -> HA impossible.
Avec un stockage partage : seul le calcul (CPU/RAM) disparait avec l'ESXi en panne,
le disque de la VM reste accessible sur le SAN -> vCenter redemarre la MEME VM
(pas une copie) sur un autre ESXi, a partir de ce disque partage.

Difference avec Kubernetes : K8s recree un NOUVEAU Pod ailleurs (etat declaratif).
VMware HA redemarre la MEME VM originale a partir de son disque partage.

## Equivalences avec ce que je connais (KVM/Proxmox)

| VMware          | Equivalent KVM/Proxmox                          |
|-----------------|--------------------------------------------------|
| ESXi            | KVM/QEMU sur ma Debian, ou un Proxmox seul       |
| vCenter         | Un cluster Proxmox (plusieurs noeuds relies)     |
| vSphere         | "Proxmox VE" dans son ensemble (le nom de suite) |
| vSphere Client  | L'interface web Proxmox                          |

## A retenir pour l'entretien

Question piege classique : "Comment la HA fonctionne-t-elle si le disque etait sur
le serveur qui vient de tomber ?" -> Reponse : il ne doit JAMAIS etre la, c'est
pour ca que le stockage partage est une condition absolue de la HA.
