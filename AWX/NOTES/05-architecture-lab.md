# Architecture du lab - repartition Debian / Proxmox

## Principe directeur

Repartir chaque brique technique sur la machine la plus adaptee, en
reproduisant la logique reelle "orchestrateur separe des cibles" (AWX
ne tourne jamais sur les memes machines qu'il administre).

## Debian (poste de travail) - "orchestrateur + lab lourd"

RAM totale : 15 Go

Contenu :
- Lab KGT-LAB-DEVOPS existant (KVM/libvirt) - inchange
- Minikube + AWX (installe et fonctionnel, voir README.md)
- Futur K3s + Rancher (a faire, cote SUSE - voir plus bas)
- Usage quotidien (candidatures, mails, Dolibarr...)

## Proxmox (192.168.1.252) - "parc de cibles + infra reseau"

Materiel : ASUS N550JV (laptop reconverti), CPU i7-4700HQ (8 threads)
RAM actuelle : 7,6 Go (8 Go installes : 2x4Go DDR3 SODIMM 1600MHz)
RAM max supportee par la carte mere : 32 Go (4 slots, 2 libres)
Disque : 500 Go (698 Go reels, 566 Go encore libres dans le pool LVM-thin)

Upgrade RAM en cours :
- Kit commande : Timetec 16 Go (2x8Go) DDR3L/DDR3 1600MHz, 1.35V, SODIMM
  204 broches - 39,99 EUR, livraison prevue lundi 24/08/2026
- Une fois installe : 8 Go -> 24 Go de RAM disponible
- Point de vigilance CONFIRME (retour terrain forum) : le N550JV necessite
  imperativement du DDR3L 1.35V, pas du DDR3 1.5V standard, sinon le
  systeme ne demarre pas
- Acces physique : trappe de service dediee sous le chassis (pas de
  demontage complet necessaire), niveau de difficulte faible

VMs / CT existants sur ce Proxmox :

| VMID | Nom             | RAM     | Disque | Etat     | Notes                        |
|------|-----------------|---------|--------|----------|-------------------------------|
| 100  | debian13-test   | 2048 Mo | 32 Go  | stopped  | ISO Debian 13 monte, semble avoir servi a un test PXE |
| 101  | VM-Client-UEFI  | 1024 Mo | 32 Go  | stopped  | Pas d'OS visible dans la config |
| 102  | ubuntu-serveur  | 2048 Mo | 12 Go  | stopped  | Creation la plus recente      |
| 103  | pihole (LXC)    | 512 Mo  | 8 Go   | running  | 192.168.1.200                 |
| 104  | wireguard (LXC) | 512 Mo  | 4 Go   | running  | 192.168.1.201, kgtwireguard.duckdns.org |

Calcul verifie : total RAM allouee si tout tourne en meme temps =
512+512+2048+1024+2048 = 6144 Mo (6 Go) sur 7,6 Go totaux -> tres juste
AVANT upgrade RAM (Proxmox lui-meme a aussi besoin de RAM pour fonctionner).
Apres upgrade a 24 Go : large marge.

Usage prevu (une fois RAM disponible) :
- 100/101/102 reutilisees comme cibles reelles pour AWX (patching canary
  en pratique), potentiellement redimensionnees a la baisse (pas besoin
  de 2 Go chacune pour de simples cibles de test)
- Future VM legere iSCSI/NFS pour lab SAN (concept vu en theorie VMware,
  ~1 Go suffit)

## Ce qui reste explicitement EN ATTENTE (sujets identifies, pas commences)

1. K3s + Rancher (equivalent SUSE de OpenShift/Red Hat) - prevu sur Debian
   - Rancher = plateforme de gestion Kubernetes de SUSE (equivalent
     positionnement a OpenShift cote Red Hat), generalement posee par-dessus
     K3s ou RKE2
   - Plus leger que OpenShift Local/CRC (qui demande 16 Go RAM minimum,
     inadapte a la config actuelle)

2. OpenShift theorique - concepts a connaitre sans forcement installer :
   - "Project" au lieu de namespace
   - commande "oc" au lieu de "kubectl"
   - "Routes" au lieu d'Ingress
   - SecurityContextConstraints (contraintes de securite plus strictes
     par defaut que K8s vanilla)
   - CRC (CodeReady Containers) = outil officiel equivalent Minikube pour
     OpenShift, mais gourmand (16 Go RAM min, 32 Go recommande si usage
     en parallele d'autre chose)

3. SAN iSCSI/NFS en pratique legere sur Proxmox (une fois RAM upgradee)

## Prochaine etape immediate (des que RAM Proxmox disponible)

Construire le scenario patching canary AVEC de vraies cibles (VMs
100/101/102), directement dans l'interface AWX :
1. Creer un Credential SSH pointant vers ces VMs
2. Creer un Inventory (statique dans un premier temps)
3. Creer un Job Template de test (ping/uptime)
4. Construire le Workflow Template complet (canary -> validation ->
   rollout/rollback)
