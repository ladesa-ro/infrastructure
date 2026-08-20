# Service mesh

Um service mesh é uma camada de infraestrutura dedicada à comunicação entre serviços dentro de um cluster: cada pod ganha um proxy sidecar (um segundo container, invisível pra aplicação), e todo tráfego entre serviços passa por esses proxies em vez de ir direto. Isso centraliza, fora do código de cada aplicação, coisas como criptografia automática entre serviços (mTLS), retry, circuit breaker, roteamento de tráfego por porcentagem (base do canary deployment citado em [CI, CD e CD](ci-cd.md)), e observabilidade de rede (quem fala com quem, com que latência).

## Como se relaciona com um Ingress Controller

Um Ingress Controller (ver [API gateway](api-gateway.md)) resolve um problema vizinho mas diferente: tráfego entrando no cluster vindo de fora. Um service mesh cuida do tráfego entre serviços já dentro do cluster, depois que a requisição já entrou. Adotar um mesh tem custo real, mais um componente pra operar, overhead de CPU/memória por causa do sidecar em cada pod, complexidade de debug quando algo dá errado no proxy em vez de na aplicação, e só compensa a partir de um número de serviços que se comunicam entre si com frequência suficiente pra as garantias do mesh (mTLS automático, retry padronizado) valerem o custo.

## As opções mais citadas

Na categoria "Service Mesh" tanto do [awesome-devops](https://github.com/wmariuss/awesome-devops) quanto do [awesome-cloud-native](https://github.com/rootsongjc/awesome-cloud-native), três nomes dominam: Istio (o mais completo e o mais citado, mas historicamente com reputação de complexo de operar), Linkerd (foco explícito em simplicidade e baixo overhead, geralmente a recomendação pra quem está adotando mesh pela primeira vez), e Cilium (que começou como plugin de rede baseado em eBPF, ver [rede interna do cluster](rede-interna-do-cluster.md), e expandiu pra oferecer capacidade de mesh sem sidecar nenhum, interceptando tráfego no nível do kernel em vez de via proxy por pod, uma abordagem mais nova e mais eficiente, mas com adoção ainda menor). Consul, da HashiCorp, é outra opção, historicamente mais forte como service discovery (a categoria adjacente de "como um serviço acha o endereço de outro") do que como mesh completo.

## Pra ir além

A antítese de service mesh não é "nenhuma segurança de rede", é resolver o mesmo problema em camadas mais baixas ou mais simples: firewall no nível de host (ver [firewalld](firewalld.md)), TLS configurado manualmente aplicação por aplicação em vez de automático via sidecar, e Network Policies nativas do Kubernetes (mais granulares que uma zona de firewall, mas sem criptografia nem retry automático). É um degrau intermediário real entre "nada" e "service mesh completo" que muitos clusters desse tamanho usam antes de justificar um mesh.

Onde aprofundar: [Linkerd](https://linkerd.io/2/overview/) e [Istio](https://istio.io/latest/docs/) têm ambos um "getting started" guiado que já demonstra mTLS automático em poucos minutos, o jeito mais rápido de entender o que um mesh de fato adiciona.
