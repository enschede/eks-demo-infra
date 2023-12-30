# Root project 

Project voor testen en runnen van EKS demo omgeving. Gebruikte technieken:

## Gebruiken

Voorbereiding: toevoegen van demo.sh als alias in shell

- demo start
- demo stop
- demo restart

## EKSCTL

Project gebruikt EKSCTL.io. Zie config in start.sh

## Nuttige k9s keywords

- :nodes
- :pods
- :context (ctx)
- :namespace (ns)
- :secret
- :configmap
- :crds
- :pv
- :pvc

- :kustomization
- :dbinstances.rds.aws.crossplane.io
- :quit

## service accounts

Service accounts aangemaakt op AWS en gebruikt door K8S services

- aws-load-balancer-controller
- bitnami-external-dns-controller
- cluster-autoscaler

## Packages

(zie uitgebreiden beschrijving in het package)

- networktools-efs. Aanroepen van stateful EFS/NFS partitie op AWS. Werkt matig.
