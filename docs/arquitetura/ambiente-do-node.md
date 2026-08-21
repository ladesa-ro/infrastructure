# Ambiente do node

Nem tudo que existe no node é decisão deste projeto. Uma parte vem do hipervisor, outra do cloud image, outra do cloud-init, e o Ansible não declara nenhuma delas. Esta página registra o que são, de onde vieram, e por que ficam de fora, pra que "não está no git" não signifique "ninguém sabe que existe".

É a contraparte de [Estado fora do git](../operacao/estado-fora-do-git.md), que trata de segredo e de acesso. Aqui o assunto é configuração e software que existem no node sem terem sido escolhidos aqui.

## Por que não declarar

Declarar um recurso da plataforma no Ansible cria dois problemas. O primeiro é que o repositório passa a afirmar posse sobre algo que não controla, e a documentação vira mentira no dia em que a plataforma mudar. O segundo é que o Ansible passa a disputar o arquivo com quem realmente o gerencia, e o resultado é reconciliação em loop, cada lado desfazendo o outro.

O caso mais direto é o `/etc/netplan/50-cloud-init.yaml`. O cloud-init reescreve esse arquivo a cada boot a partir dos metadados que o hipervisor entrega. Um role que também escrevesse ali produziria um node cuja rede depende de quem escreveu por último.

```mermaid
flowchart TD
    Recurso{quem decide se isso existe?} -->|este projeto| Declara[role do Ansible]
    Recurso -->|hipervisor, imagem ou cloud-init| Registra[registrado aqui, não declarado]
    Declara --> Git[git é a fonte da verdade]
    Registra --> Plataforma[a plataforma é a fonte da verdade]
```

## O que vem do hipervisor

| Item | Observação |
|---|---|
| `qemu-guest-agent` | agente de integração com o hipervisor. Foi instalado à mão no primeiro dia da VM, mas quem decide se ele deve existir é quem administra o hipervisor, não este repositório |
| Endereçamento de rede, gateway e DNS | entregues por metadados. Também é o motivo de não ficarem no git, coerente com a decisão de manter endereço e porta fora deste repositório |

## O que vem do cloud image

| Item | Observação |
|---|---|
| `cloud-init`, `cloud-guest-utils`, `cloud-initramfs-growroot` e `/etc/cloud/**` | inicialização da instância |
| `grub-cloud-amd64`, `linux-image-cloud-amd64` e `/etc/default/grub.d/10_cloud.cfg` | kernel e boot da variante cloud |
| `netplan.io`, `systemd-resolved`, `systemd-timesyncd` | rede e tempo, gerenciados pelo cloud-init |
| `/etc/apt/mirrors/*.list` e `/etc/apt/sources.list.d/debian.sources` | espelhos escolhidos pela imagem |
| Conta `apalrd`, uid 1000 | usuário padrão da imagem base, ver abaixo |
| Cerca de 60 pacotes de biblioteca e essenciais | aparecem em `apt-mark showmanual` por serem imagem mínima, e é o motivo de [`pacotes-base`](roles/pacotes-base.md) não usar essa lista como fonte |

A conta `apalrd` é o único item desta seção com ação recomendada. Ela vem da imagem, tem sudo sem senha, e o `authorized_keys` dela está vazio, ou seja, é um acesso privilegiado que ninguém consegue usar e ninguém pediu. Não declarar não é o mesmo que aceitar.

## Performance Co-Pilot

Os quatro daemons do Performance Co-Pilot (`pmcd`, `pmie`, `pmlogger` e `pmproxy`) estão habilitados e ativos no node. Nenhum `apt install pcp` aparece no `history.log`, então vieram com a imagem.

Ficam exatamente como estão, por decisão registrada em 2026-08-21. O Ansible não declara, não desabilita e não remove.

Dois fatos justificam revisitar essa decisão mais pra frente, e por isso ficam anotados em vez de só na cabeça de alguém. O primeiro é que o `pmlogger` escreve arquivo de métrica continuamente em `/var/log/pcp`, o que participa do consumo de disco que o role [`sistema`](roles/sistema.md) passou a limitar do lado do journal. O segundo está registrado no inventário privado apontado por [Estado fora do git](../operacao/estado-fora-do-git.md).

O ponto de decisão é este: hoje o Performance Co-Pilot é o único coletor de métrica do node, num cluster que ainda faz [observabilidade](../aprender/observabilidade.md) por inspeção manual. Adotar de verdade ou remover são as duas saídas coerentes. Continuar de pé por acidente é a única que não é.

## A regra pra manter esta página útil

Toda vez que alguém encontrar no node algo que este repositório não declara, a pergunta é uma só: quem decide se isso existe. Se a resposta for este projeto, vira role. Se for a plataforma, vira uma linha aqui.
