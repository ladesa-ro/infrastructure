# Aprender

Esta seção ensina conceitos e ferramentas de infraestrutura de forma geral, sem depender de nenhuma decisão específica de nenhum projeto. Se você já sabe o que é SSH, Ansible, Argo CD, k3s, firewalld e git, pule direto pra [Arquitetura](../arquitetura/index.md) ou [Operação](../operacao/checklist.md). Se está chegando agora, comece por aqui: cada página cobre uma peça, o que ela faz, por que existe, e como as peças costumam se encaixar num setup desse tipo. As decisões específicas de um cluster real (o que ele de fato usa, e por quê) ficam inteiramente em [Arquitetura](../arquitetura/index.md).

| Se você precisa entender | Vá pra |
|---|---|
| Como conectar num servidor remoto e o que cada chave SSH autoriza | [SSH](ssh.md) |
| Como Conventional Commits e proteção de branch mantêm o histórico legível | [Git](git.md) |
| O que "modo `--check`" significa de verdade, e por que ele não quebra nada | [Ansible](ansible.md) |
| O que o k3s é, e como ele difere de um Kubernetes "completo" | [k3s](k3s.md) |
| Como o firewall decide o que entra e o que sai | [firewalld](firewalld.md) |
| Como o Argo CD descobre e aplica tudo sozinho, sem o Ansible | [Argo CD](argocd.md) |
| O que é uma plataforma de gestão de segredos, e como o Infisical se encaixa | [Infisical](infisical.md) |
| A diferença real entre integração contínua, entrega contínua e deploy contínuo | [CI, CD e CD](ci-cd.md) |
| O padrão que o Infisical Kubernetes Operator implementa, e onde mais ele aparece | [Operators](kubernetes-operators.md) |
| Como um pod acha outro pelo nome, e como `LoadBalancer` funciona sem cloud nenhuma | [Rede interna do cluster](rede-interna-do-cluster.md) |
| Como nome vira IP, e como uma máquina nova descobre o próprio IP na rede | [DNS e DHCP](dns-e-dhcp.md) |
| Bancos e storage S3 rodando dentro do próprio cluster, e o trade-off disso | [Dados no cluster](dados-no-cluster.md) |
| Como HTTPS acontece automaticamente, sem ninguém colar certificado na mão | [TLS automático](tls-automatico.md) |
| Quais papéis (SRE, DevOps, DevSecOps, Platform Engineering, GitOps) envolvem manter algo assim, e como se relacionam | [Papéis](papeis.md) |
| Onde continuar aprendendo além desta seção: livros, blogs de engenharia, comunidades | [Referências](referencias.md) |

Depois de entender essas peças, [Arquitetura](../arquitetura/index.md) mostra como um cluster real as usa na prática, e [Operação](../operacao/checklist.md) é o roteiro executável. Nenhuma página acima é exaustiva de propósito: cada uma termina com "Pra ir além", apontando pra outras ferramentas, abordagens e literatura além do que foi escolhido em qualquer projeto específico.

## Também relevante

As páginas acima cobrem o núcleo mais comum desse tipo de stack. As páginas abaixo cobrem categorias inteiras do ecossistema de infraestrutura que apareceram com força nas listas curadas em [Referências](referencias.md), mais periféricas ou específicas de escala/setor. Estão organizadas em quatro grupos, servem pra você conhecer o mapa completo, não só o núcleo.

### Entrega e plataforma

| Categoria | Vá pra |
|---|---|
| A camada que cria a VM/rede/disco, antes do Ansible entrar em cena | [IaC e provisionamento](iac-provisionamento.md) |
| Regra de governança verificada automaticamente, em vez de revisão manual | [Policy as code](policy-as-code.md) |
| A superfície única onde quem desenvolve vê e pede infraestrutura | [Internal Developer Platform](idp.md) |
| O ponto único por onde requisição externa entra num conjunto de serviços | [API gateway](api-gateway.md) |
| Desacoplar quem produz um evento de quem consome | [Mensageria e streaming](mensageria.md) |
| Onde um pacote/binário publicado vive, versionado | [Artifact management](artifact-management.md) |
| Onde uma imagem de container publicada vive, versionada | [Container registry](container-registry.md) |

### Confiabilidade

| Categoria | Vá pra |
|---|---|
| Métrica, log e trace: como saber o que está acontecendo dentro do cluster | [Observabilidade](observabilidade.md) |
| Criptografia e roteamento automático entre serviços dentro do cluster | [Service mesh](service-mesh.md) |
| Injetar falha de propósito pra descobrir problema antes que ele aconteça sozinho | [Chaos engineering](chaos-engineering.md) |
| Ter cópia recuperável de dado, e um roteiro real pra voltar a operar depois de perder algo | [Backup e disaster recovery](backup-e-disaster-recovery.md) |

### Segurança e compliance

| Categoria | Vá pra |
|---|---|
| Inventário de dependência de um build, e por que isso importa depois de um incidente como o Log4Shell | [Supply chain e SBOM](supply-chain-e-sbom.md) |
| Perguntar sistematicamente "o que pode dar errado aqui, de propósito" antes de construir | [Threat modeling](threat-modeling.md) |
| Eliminar confiança implícita baseada em localização de rede | [Zero Trust](zero-trust.md) |
| Detectar comportamento anômalo depois que algo já está rodando | [Runtime security](runtime-security.md) |
| Checar código/dependência/imagem contra vulnerabilidade conhecida | [Vulnerability scanning](vulnerability-scanning.md) |
| SOC 2, ISO 27001, NIST: o que são e por que aparecem em contrato enterprise | [Compliance e frameworks](compliance-e-frameworks.md) |
| Kerberos, FreeIPA, Kanidm: como um diretório central de identidade funciona | [Identidade e diretório](identidade-e-diretorio.md) |

### Fundamentos alternativos

| Categoria | Vá pra |
|---|---|
| O sistema operacional inteiro declarado, não só o que o Ansible toca | [NixOS](nixos.md) |
| Documentação versionada e revisada como código, em vez de wiki solto | [Documentação como código](documentacao-como-codigo.md) |
