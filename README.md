# Root project 

Project voor testen en runnen van EKS demo omgeving. Gebruikte technieken:

## Gebruiken

Voorbereiding: toevoegen van demo.sh als alias in shell

- demo start
- demo stop
- demo restart

## EKSCTL

Project gebruikt EKSCTL.io. Zie config in start.sh

## service accounts

Service accounts aangemaakt op AWS en gebruikt door K8S services

- aws-load-balancer-controller
- bitnami-external-dns-controller
- cluster-autoscaler

## Packages

(zie uitgebreiden beschrijving in het package)

- dashboard. Kubernetes dashboard. Showcase dat een app geen eigen repo nodig heeft. Niet meer nodig, want k9s. 
- networktools-efs. Aanroepen van stateful EFS/NFS partitie op AWS. Werkt matig.

## IPv6 overwegingen

IPv6 kan op 2 plekken onafhankelijke van elkaar gebruikt worden

- Extern, vanaf het Internet naar de LB's
- Intern, vanaf de LB's naar binnen

### IPv6 extern

Er is een IPv6-enabled VPC met dito subnetten noodzakelijk. In de subnetten zijn de volgende settings noodzakelijk:

- Auto-assign public IPv4 address
- Auto-assign IPv6 address

De VPC en subnetten moeten gebruikt worden in eksctl:

    vpc:
      id: "vpc-0b7384f37844f8fcc"
      subnets:
        private:
          us-west-2a:
            id: "subnet-043c77679e9ad65f9"
        public:
          us-west-2a:
            id: "subnet-0fc025155115d3ca9"

De LB's moeten geactiveerd worden voor IPv6 in de ingress descriptor:

    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
        name: eks-demo-app-ingress
        labels:
            app: eks-demo-app
        annotations:
            alb.ingress.kubernetes.io/ip-address-type: dualstack
            alb.ingress.kubernetes.io/subnets: subnet-0fc025155115d3ca9, subnet-0f1f930cfb2b3909d, subnet-08991736d58ec2e49

### IPv6 intern

Ook hier zijn IPv6 enabled subnetten noodzakelijk. In de eksctl config zijn de volgende settings nodig

    kubernetesNetworkConfig:
      ipFamily: IPv6
    
    addons: 
      - name: vpc-cni
      - name: coredns
      - name: kube-proxy

Let op, iedere add-on kost extra tijd bij initialisatie en decomissioning van het cluster

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
