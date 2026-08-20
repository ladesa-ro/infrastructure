# Rede interna do cluster

Distribuições Kubernetes leves como [k3s](k3s.md) costumam trazer embutidas, por padrão, três peças de rede que em outras instalações precisariam ser escolhidas e instaladas à parte.

## CNI: como um pod fala com outro

O CNI (Container Network Interface) é o plugin responsável por dar IP a cada pod e rotear tráfego entre eles. Um CNI leve típico (Flannel é o exemplo mais citado) usa VXLAN como backend, encapsulando tráfego de pod dentro de pacote UDP normal, o que funciona mesmo sem controle sobre a rede física do datacenter. É esse tipo de CNI quem cria as faixas internas de IP de pod e de service (ver [firewalld](firewalld.md) sobre por que um firewall precisa tratar essas faixas por origem, não por interface): o CNI cria uma interface de rede nova (`veth*`) pra cada pod, dinamicamente, não dá pra listar uma por uma numa regra estática.

## CoreDNS: como um serviço acha outro pelo nome

Dentro de um cluster, um pod nunca precisa saber o IP de outro: um nome como `servico.namespace.svc.cluster.local` (ou só `servico`, dentro do mesmo namespace) resolve pro `ClusterIP` certo, via CoreDNS, o servidor DNS interno padrão de um cluster Kubernetes moderno. Sem isso, qualquer mudança de IP de um pod (que acontece o tempo todo, pods são recriados) quebraria toda referência direta por IP.

## `LoadBalancer` sem nenhuma cloud por trás

Um Service tipo `LoadBalancer` normalmente depende do provedor cloud provisionar um balanceador de verdade (um ELB da AWS, por exemplo). Fora de uma cloud, algumas distribuições leves resolvem isso com um ServiceLB embutido (no k3s, esse componente existia antes sob o nome Klipper LoadBalancer): um pod `svclb-*` por Service `LoadBalancer` por node, que abre a porta do serviço direto no host via `iptables` e encaminha o tráfego pro `ClusterIP` de verdade. O "IP externo" que `kubectl get svc` mostra nesse modelo é só o IP do próprio node, não um balanceador dedicado. Funciona bem pra um node só; não distribui carga entre múltiplos nodes do jeito que um balanceador de cloud faria, o que é o motivo mais comum de trocar por MetalLB a partir de mais de um node.

## Pra ir além

A antítese de ter um CNI de verdade é host networking, um pod compartilha a pilha de rede do próprio node em vez de ganhar IP e interface própria, sem overlay nenhum no meio. Mais rápido (sem hop extra de rede) e mais simples de depurar, mas sem isolamento nenhum entre pods do mesmo node, e sem a IP própria por pod que o Kubernetes assume como padrão pra praticamente tudo mais, então só faz sentido pra caso bem específico (agente de monitoramento que precisa ver a rede do host, por exemplo), nunca como política geral do cluster.

MetalLB é a alternativa mais citada pra quando um ServiceLB embutido não é suficiente: em vez de abrir porta no host, o MetalLB anuncia um IP virtual de verdade na rede local (via ARP ou BGP), mais próximo do comportamento de um balanceador de cloud. Cilium e Calico são as alternativas de CNI mais citadas ao Flannel, ambas com recursos que o Flannel não tem (Network Policies mais expressivas, e no caso do Cilium, capacidade de service mesh sem sidecar, ver [Service mesh](service-mesh.md)); a troca só compensa quando as faixas de IP fixas ou a ausência de Network Policy própria de um CNI mais simples virarem um problema real.

Onde aprofundar: a documentação oficial de [rede do k3s](https://docs.k3s.io/networking/networking-services) explica ServiceLB, o Ingress Controller e as opções de CNI num só lugar, é a referência mais direta pra esse conjunto específico de componentes.
