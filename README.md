# Root project 

Project voor testen en runnen van EKS demo omgeving. Gebruikte technieken:

Gerelateerde documentatie:

- [k9s](documentation/K9S.md)


## Gebruik

Voorbereiding: toevoegen van demo.sh als alias in shell
Voorbereiding: toevoegen EKS_DEMO_FORGEROCK env var die wijst naar FR infra repo

- demo start _alias demo start eks_
- demo start fr
- demo start all
- demo stop _alias demo stop eks_ 
- demo stop fr 
- demo stop all 
- demo restart

## EKSCTL

Project gebruikt EKSCTL.io. Zie config in start.sh

Trivia:
- Heel veel configuratie voorbeelden op https://github.com/eksctl-io/eksctl/tree/main/examples
- Formeel configuratie schema op https://eksctl.io/usage/schema/

### Service accounts

Service accounts aangemaakt op AWS en gebruikt door K8S services

- aws-load-balancer-controller
- bitnami-external-dns-controller
- cluster-autoscaler

### Add-ons

- EBS add-on maakt gebruik van een Elastic Block device (harde schijf) mogelijk
- EFS add-on maakt gebruik van een NFS device mogelijk

Add-ons kosten (veel) extra tijd nodig bij opstarten

### IPv6

IPv6 kan op 2 plekken onafhankelijke van elkaar gebruikt worden

- Extern, vanaf het Internet naar de LB's
- Intern, vanaf de LB's naar binnen

#### IPv6 extern

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

#### IPv6 intern

Ook hier zijn IPv6 enabled subnetten noodzakelijk. In de eksctl config zijn de volgende settings nodig

    kubernetesNetworkConfig:
      ipFamily: IPv6
    
    addons: 
      - name: vpc-cni
      - name: coredns
      - name: kube-proxy

Let op, iedere add-on kost extra tijd bij initialisatie en decomissioning van het cluster

## VPC overwegingen

Een aantal AWS diensten zitten in een AWS zone (bijv. us-west-2a). Dit geldt bijv. voor EBS. Om EBS aan te kunnen spreken moet de pod die de service aanroept in dezelfde zone zitten.
Om dit te laten werken zijn een aantal zaken noodzakelijk.

- Er moet een node in de betreffende zone draaien.
  - Zorg dat er altijd minimaal evenveel nodes zijn als zones. Dus bij 3 zones minimaal 3 nodes.
  - Beperk evt. het aantal zones (bijv. zone c) de huur van veel ijzer te voorkomen.
- Zorg de affinity in de deployment ingesteld op de juiste node.

