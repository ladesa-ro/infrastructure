# firewalld

**TLDR**: gerenciador de firewall por zonas, sobre `nftables`/`iptables`; mudança `--permanent` só entra em vigor no próximo `--reload`, o que permite trocar a política inteira atomicamente, sem nunca deixar a porta de administração descoberta no meio do caminho.

| Termo | Vá pra |
|---|---|
| `--permanent` vs. efeito imediato | [Permanente vs. runtime](#permanente-vs-runtime) |
| Não travar o próprio SSH | [Por que isso importa](#por-que-isso-importa-pra-nao-travar-o-proprio-ssh) |

firewalld é o gerenciador de firewall padrão em distribuições como Debian/RHEL, uma camada sobre `nftables`/`iptables` organizada em **zonas**: cada zona tem seu próprio conjunto de serviços e portas liberadas, e cada interface de rede (ou faixa de IP de origem) pertence a uma zona. Tráfego de uma interface na zona `public` segue as regras da `public`; tráfego de uma interface na zona `trusted` segue regras mais permissivas.

```mermaid
flowchart LR
    IF1[interface pública] -->|pertence a| Z1[zona public]
    IF2[interface administrativa] -->|pertence a| Z2[zona trusted]
    Z1 -->|regras restritas| P1[portas/serviços liberados]
    Z2 -->|regras permissivas| P2[portas/serviços liberados]
```

## Permanente vs. runtime

Toda mudança em firewalld pode ser aplicada de dois jeitos: **runtime** (efeito imediato, mas some no próximo reload ou reboot) ou **`--permanent`** (só entra em vigor no próximo `firewall-cmd --reload`, mas sobrevive a reboot). Um padrão comum, quando várias mudanças precisam acontecer juntas (abrir porta, trocar zona, remover serviço padrão), é aplicar tudo só com `--permanent` e reservar um único `--reload` pro fim, fazendo tudo entrar em vigor **atomicamente**, em vez de uma mudança de cada vez, cada uma abrindo uma janela onde o sistema fica num estado intermediário e potencialmente inseguro.

```mermaid
flowchart TD
    A[trocar zona padrão pra public] -->|só --permanent| B[remover serviços default da zona]
    B -->|só --permanent| C[abrir portas declaradas]
    C -->|só --permanent| D[colocar interfaces nas zonas certas]
    D --> E[firewall-cmd --reload]
    E --> F[tudo entra em vigor de uma vez]
```

## Por que isso importa pra não travar o próprio SSH

Enquanto nenhum `--reload` rodou, a configuração **ao vivo** continua sendo a de antes da mudança começar. Isso é o que sustenta a técnica acima: mesmo removendo (só via `--permanent`) o serviço `ssh` que a zona `public` já vem com liberado por padrão de fábrica, a sessão atual continua protegida por esse mesmo default até o único reload no fim, momento em que a porta explícita já declarada entra em vigor junto. É esse desencontro deliberado entre "declarado" e "ao vivo" que permite reorganizar a política inteira sem nunca existir um instante em que a porta de administração fique descoberta.

```mermaid
sequenceDiagram
    participant D as declarado (--permanent)
    participant V as ao vivo (runtime)
    participant S as sessão SSH atual

    D->>D: remove regra ssh da zona public
    Note over V: ainda reflete o estado anterior
    S->>V: continua protegida pelo default antigo
    D->>D: adiciona porta explícita
    D->>V: firewall-cmd --reload
    V->>V: declarado e ao vivo convergem de uma vez
    S->>V: porta administrativa nunca ficou descoberta
```

## Pra ir além

firewalld é uma camada de abstração sobre [`nftables`](https://en.wikipedia.org/wiki/Nftables) (ou [`iptables`](https://en.wikipedia.org/wiki/Iptables), em sistemas mais antigos), organizada em zonas nomeadas. `ufw`, comum em distros baseadas em Ubuntu, resolve o mesmo problema com uma sintaxe mais simples e menos conceito de zona. Mexer direto em `nftables`/`iptables`, sem nenhuma abstração, dá mais controle mas exige gerenciar a ordem das regras manualmente, algo que essas ferramentas escondem.

O princípio "negar por padrão, liberar só o declarado" não é exclusivo de firewall de sistema operacional: provedores cloud aplicam a mesma ideia em outra camada, security groups (AWS) ou firewall rules (GCP), que filtram tráfego antes mesmo de chegar na VM. Dentro de um cluster Kubernetes, [service mesh](https://en.wikipedia.org/wiki/Service_mesh) com mTLS (Istio, Linkerd, ver [Service mesh](service-mesh.md)) estende esse princípio pra comunicação entre pods, criptografando e autenticando tráfego interno.

A antítese completa de "negar por padrão" é allow-all, todo tráfego passa a menos que uma regra explícita bloqueie, o comportamento de fábrica de muita distro Linux antes de qualquer firewall ser configurado. Mais simples de não travar nada por engano, mas expõe qualquer serviço que suba numa porta nova por padrão, sem ninguém precisar declarar essa exposição de propósito.

```mermaid
flowchart LR
    subgraph DenyByDefault["Negar por padrão"]
        T1[tráfego novo] -->|bloqueado, a menos que declarado| X1[precisa de regra explícita pra passar]
    end
    subgraph AllowAll["Allow-all"]
        T2[tráfego novo] -->|passa livre| X2[precisa de regra explícita pra bloquear]
    end
```

## Uma pegadinha real com orquestrador de container já em execução

`firewall-cmd --reload` não é tão inofensivo quanto parece quando outro processo já gerencia suas próprias regras de `iptables`/`nftables` no mesmo host, um orquestrador de container como k3s/Kubernetes é o caso mais comum. O reload recarrega a configuração do próprio firewalld, mas o efeito colateral em sistemas mais antigos de nftables é recriar as chains do zero, o que pode flushar regras que outro processo tinha inserido por fora do firewalld (rede de pod via CNI, `hostPort` de um Ingress Controller). A recuperação depende de esse outro processo perceber a mudança e reaplicar sozinho; em alguns casos isso é parcial ou não acontece automaticamente, exigindo reiniciar o serviço afetado (ou, em último caso, reboot) pra normalizar. Ativar firewalld pela primeira vez num host que já roda esse tipo de orquestrador há tempo, em vez de configurar os dois juntos desde o início, é o cenário onde isso mais aparece.

## `firewalld` não protege tráfego roteado pro Kubernetes, achado real em 2026-08-21

Depois de restringir a zona `public` pra só aceitar 80/443 das faixas de IP do [Cloudflare](cloudflare.md) (ver [Pendências](../operacao/pendencias.md)), o teste real (conectar direto no IP público do node, sem passar pelo Cloudflare) continuou funcionando, como se a regra não existisse. Não era bug na regra: `iptables -t filter -L FORWARD -n` mostrou que o tráfego destinado a uma `Service` do tipo `LoadBalancer` (o Traefik, via `svclb-traefik`, mecanismo `ServiceLB`/klipper-lb do k3s) nunca passa pela chain `INPUT`, que é a única que o `firewalld` controla por zona.

O motivo é estrutural, não uma configuração errada: `svclb-traefik` expõe a porta 80/443 do host via `hostPort` (não `hostNetwork`), então o `kubelet` programa um DNAT (`nat`/`PREROUTING`) do IP do node pra o IP do pod. Depois do DNAT, o pacote já tem destino diferente do próprio host, então é avaliado pela chain `FORWARD`, não `INPUT`. A `FORWARD`, neste cluster, tem **política padrão `ACCEPT`**, e o primeiro alvo é `KUBE-ROUTER-FORWARD` (o k3s aqui roda com kube-router como network policy controller). O `firewalld` nem aparece na lista de chains consultadas pra esse tráfego.

```mermaid
flowchart LR
    Ext[Cliente externo] -->|porta 80/443| Node[IP do node]
    Node -->|PREROUTING, DNAT do hostPort| Pod[pod svclb-traefik]
    Pod -.->|chain FORWARD, kube-router ACCEPT| Pod
    Node -.->|chain INPUT, zona public do firewalld| SSH[só afeta processos que escutam direto no host, ex. SSH]
```

Isso **não é peculiaridade deste cluster**: é um problema conhecido e sem solução oficial na comunidade k3s, confirmado numa [discussão aberta e sem resposta no repositório oficial](https://github.com/k3s-io/k3s/discussions/12449), relatando exatamente o mesmo sintoma (kube-proxy/kube-router reposicionam as próprias regras no topo da chain, por cima de qualquer regra customizada). Tentar inserir uma regra manual à frente do `KUBE-ROUTER-FORWARD` não é uma correção estável: o kube-router reconcilia e reposiciona as próprias regras periodicamente, então a regra manual perderia a corrida de novo depois de qualquer resync.

**Caminhos reais pra restringir esse tráfego** (nenhum aplicado ainda, ver [Pendências](../operacao/pendencias.md)):

1. **Firewall externo ao node** (security group da nuvem, ACL de rede do provedor, firewall de um roteador na frente): a única camada garantidamente avaliada antes do pacote sequer chegar nas chains do node, não compete com o kube-router porque nem está no mesmo host. Caminho recomendado, mas depende de saber quem hospeda a VM e se esse recurso existe.
2. **Kubernetes `NetworkPolicy`**, restringindo a origem aceita pelo Traefik/`svclb-traefik` por `ipBlock`: como o kube-router é ao mesmo tempo quem esmaga as regras do `firewalld` **e** o controller que aplica `NetworkPolicy` neste cluster (confirmado, `KUBE-ROUTER-FORWARD` existe e está ativo), uma `NetworkPolicy` não compete com ele, é implementada pelo próprio kube-router como parte do mecanismo que já vence a corrida. Não testado ainda neste cluster; comportamento de `NetworkPolicy` sobre tráfego que chega via `hostPort` (em vez de endereço de pod normal) varia por CNI/controller e precisa de validação antes de confiar nele.
3. **Regra manual na chain `FORWARD`, reaplicada a cada resync do kube-router**: tecnicamente possível (um serviço systemd que reinsere a regra), mas frágil por natureza (corrida contra um processo que se reconcilia sozinho), não é a solução recomendada.

A restrição de `firewalld` que foi aplicada (ipset `cloudflare4`/`cloudflare6` + rich rules na zona `public`) continua correta e foi mantida: protege a chain `INPUT`, ou seja, qualquer processo que escute direto no host fora do Kubernetes (hoje só o SSH se encaixa nisso). Só não fecha o problema original (bypass do Cloudflare pra tráfego web, que é `Service` do Kubernetes).

## Cheatsheet

| Comando | O que faz |
|---|---|
| `firewall-cmd --get-active-zones` | Lista zonas ativas e suas interfaces |
| `firewall-cmd --zone=public --list-all` | Mostra tudo liberado numa zona |
| `firewall-cmd --permanent --add-port=X/tcp` | Adiciona porta, só entra em vigor no reload |
| `firewall-cmd --reload` | Aplica tudo que está `--permanent` de uma vez |
| `firewall-cmd --query-port=X/tcp` | Confere se uma porta já está liberada |

Onde aprofundar: a documentação oficial em [firewalld.org](https://firewalld.org) cobre a ferramenta em si; pra entender o que está por baixo dela, a página man `nft(8)` (`man nft`, já instalada em qualquer sistema com `nftables`) é a referência mais direta pra sintaxe de regras sem passar por abstração nenhuma.
