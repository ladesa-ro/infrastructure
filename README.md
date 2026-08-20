# infrastructure

Bootstrap declarativo e setup GitOps do cluster ldsa, um node único de k3s. Os dados de conexão não ficam neste repositório; quem administra usa o alias `ldsa` já configurado no próprio `~/.ssh/config`.

O Ansible instala o k3s, configura o firewalld, clona os segredos de bootstrap do [`infrastructure-vault`](https://github.com/ladesa-ro/infrastructure-vault), instala o release do Argo CD, e aplica um único arquivo, o `root.yaml`. O Argo CD sincroniza tudo que descobre a partir dali, em `argocd/apps`. Nenhum segredo, em texto puro ou cifrado, fica neste repositório: todos vivem em `infrastructure-vault`.

## Checklist

Cada item corresponde a um passo em [Bootstrap mínimo na VM](#bootstrap-mínimo-na-vm). Serve pra saber onde você está e o que ainda falta, não pra marcar sem conferir de verdade o resultado de cada comando.

- [ ] Acesso SSH ao node configurado (`~/.ssh/config`, alias `ldsa`) (*sua máquina*): [configurar e validar](#0-antes-de-tudo)
- [ ] `ansible-core`, `jq` e o CLI do `argocd` instalados no node, checksum do `argocd` conferido pelo próprio Ansible (*sua máquina, via `bootstrap.yml`*): [configurar e validar](#1-instalar-as-dependências-no-node)
- [ ] Senha do Ansible Vault gerada em `/root/infrastructure-vault-pass` (*node, via SSH*): [configurar e validar](#2-gerar-a-senha-do-ansible-vault)
- [ ] Deploy key SSH do `infrastructure` gerada (*node, via SSH*): [configurar e validar](#3-gerar-e-registrar-a-deploy-key-ssh-do-infrastructure)
- [ ] Deploy key do `infrastructure` registrada como leitura em `github.com/ladesa-ro/infrastructure` (*GitHub, no navegador*): [configurar e validar](#3-gerar-e-registrar-a-deploy-key-ssh-do-infrastructure)
- [ ] Deploy key SSH do `infrastructure-vault` gerada e registrada como leitura em `github.com/ladesa-ro/infrastructure-vault` (*node, via SSH* e *GitHub, no navegador*): [configurar e validar](#4-gerar-e-registrar-a-deploy-key-ssh-do-infrastructure-vault)
- [ ] Repositório `infrastructure` clonado no node com sua deploy key (*sua máquina, via `bootstrap.yml`*): [configurar e validar](#5-clonar-o-repositório-no-node)
- [ ] Primeira execução (`k3s` + `vault-repo` + `argocd-bootstrap`) rodada com `--check` e depois de verdade, sem erro (*node, via SSH*): [configurar e validar](#6-primeira-execução-k3s-vault-repo-e-o-release-do-argo-cd)
- [ ] Gate de drift zero: `argocd app diff --core` vazio em **todas** as Applications, não só nas óbvias (*node, via SSH*): [configurar e validar](#7-gate-de-drift-zero)
- [ ] Firewalld ligado, e uma segunda conexão SSH testada com sucesso antes de fechar a primeira (*a segunda conexão é da sua máquina, o resto é no node*): [configurar e validar](#8-ligar-o-firewalld)
- [ ] Timer do `ansible-pull` habilitado (`systemctl status ansible-pull.timer` mostra `active`) (*node, via SSH*): [configurar e validar](#9-ligar-a-reconciliação-automática)

Se algum item não estiver limpo, não segue pro próximo. É a mesma regra do gate de drift zero, só que pro bootstrap inteiro.

## Estrutura

```
ansible/
  bootstrap.yml                playbook rodado da sua máquina, via push, só na primeira vez (ver passo 1)
  site.yml, local.yml         playbooks: local.yml é o entrypoint do ansible-pull
  inventory/                  host ldsa (conexão local, os comandos abaixo rodam de dentro do próprio node), versões pinadas
  roles/
    k3s/                      instala o k3s
    firewalld/                liga o firewall (tag separada, não roda pelo ansible-pull sem supervisão)
    vault-repo/               clona o infrastructure-vault no node
    argocd-bootstrap/         release do Argo CD e o apply do root.yaml
      files/                  values do Helm que o role consome
    self-pull-timer/          instala e habilita o timer do ansible-pull (tag separada, roda por último)
  systemd/                    unit e timer do ansible-pull

argocd/
  root/                       AppProjects "ladesa" e "ladesa-satellites", e a Application "root" (app-of-apps)
  apps/                       uma Application por peça de foundation, e uma por repositório satélite
  foundation/                 manifests dos core services, trazidos como já rodam hoje

scripts/                      freeze-manifest.sh
```

As Applications `foundation-*.yaml` já estão mapeadas a partir do que roda de verdade no cluster hoje. Os arquivos `app-*.yaml` dos repositórios satélite (`web`, `docs`, `management-service`, `timetable-generator`, `authentication-service`) ainda não existem aqui. Dependem de cada um desses repositórios ganhar sua própria pasta `gitops` primeiro, o que é trabalho separado.

`bootstrap.yml` é a exceção ao resto do Ansible deste repositório: roda via push, da máquina de quem administra contra o node por SSH, em vez de via `ansible-pull` local. Existe só porque o node não tem `ansible-core` instalado antes da primeira execução, então nada aqui pode depender do próprio `ansible-pull` pra se instalar. Não é um role, não entra em `site.yml`, e nunca roda de novo depois do bootstrap inicial (ver passos 1 e 5 do [Bootstrap mínimo na VM](#bootstrap-mínimo-na-vm)).

## Roles do Ansible

### k3s

Instala e mantém o k3s fixado por versão e checksum. Só reinstala se a versão instalada divergir de `k3s_versao`.

A configuração do servidor, hoje só `node-name`, vai em `/etc/rancher/k3s/config.yaml`, o mecanismo declarativo nativo do k3s, em vez de flag solta no `ExecStart`. É o jeito de escalar isso pra qualquer config futura (`disable`, `tls-san`, etc.) virar uma linha no template em vez de mais uma variável de ambiente espalhada. Toda mudança nesse arquivo reinicia o k3s, via handler, e o role força esse handler a rodar imediatamente (`meta: flush_handlers`) em vez de deixar pro fim da play. Sem isso, o restart só aconteceria depois do `argocd-bootstrap` já ter instalado o Argo CD e aplicado o `root.yaml`, um reinício de controle-plane fora de hora e sem relação com o que causou ele.

Na primeira vez que este role rodar contra um node que ainda não tem `/etc/rancher/k3s/config.yaml` (é o caso do node de produção hoje, mesmo sem trocar nenhum valor), o arquivo é criado do zero, o que conta como mudança, e o k3s reinicia. Esperado, coberto pelo `meta: flush_handlers` acima, mas é um reinício de controle-plane de verdade, vale saber antes de rodar.

`k3s_node_name` existe porque o node já rodava com `--node-name=srv-1692732206` antes deste repositório existir, um nome escolhido manualmente, não o que o instalador geraria sozinho a partir do hostname. Conferido direto no node antes de migrar pra cá. O `ExecStart` antigo, gerado da vez em que o k3s foi instalado sem este role, ainda carrega essa flag; como o valor bate com o que `config.yaml` declara agora, não há conflito, só uma redundância inofensiva que só some numa próxima instalação do zero.

### firewalld

Liga um firewall pela primeira vez num node de produção que hoje não tem nenhum. Confirmei isso direto no node: `firewalld` não está instalado nem ativo em `ldsa`. É a mudança de maior risco de todo o bootstrap, uma regra errada pode cortar o próprio SSH ou quebrar o tráfego entre pods.

Por isso este role fica na tag `firewalld`, pulada por padrão pelo timer do ansible-pull. Só roda manualmente, com `--check` primeiro, com alguém acompanhando. Depois da primeira execução supervisionada, o role é idempotente e pode voltar pro caminho automático.

As tasks usam `firewall-cmd` direto via `ansible.builtin.command`, com um `--query-*` antes de cada mudança pra decidir se aplica ou não, em vez do módulo `ansible.posix.firewalld`. Essa collection não vem com `ansible-core` (o pacote que instalamos, de propósito, é o mínimo, não o meta-pacote `ansible` que traz collections junto), e não faz sentido instalar uma collection nova só pra este role quando dá pra ficar só com o que já está no node.

`firewalld_portas_publicas` é só o que precisa estar aberto pra qualquer origem: a porta do SSH e o Traefik do k3s. `firewalld_porta_ssh` tem default `22`, comitado normalmente: não é segredo, é a porta padrão de qualquer instalação SSH, diferente da porta externa usada pra administrar o node (essa sim fica de fora do git, é NAT feito antes de chegar na VM, provavelmente no provedor ou roteador).

Atenção a essa pegadinha, conferida de verdade no node: o `sshd` da própria VM escuta na porta 22 padrão (`ss -tlnp` confirma, `0.0.0.0:22`), sem nenhum `Port` customizado no `sshd_config`, mesmo quem administra acessando por uma porta diferente de fora. O firewalld roda depois que o NAT já traduziu a porta, então a regra tem que liberar a porta que a VM enxerga, 22, não a porta externa usada em `~/.ssh/config`. Usar a porta externa aqui bloquearia o próprio SSH ao ligar o firewalld.

`firewalld_interface_admin` é a interface da malha ZeroTier já em uso neste node. O nome real foi conferido com `ip -o link show`; como o ZeroTier nomeia por rede, vale reconferir se o node for reprovisionado ou entrar em outra network. Administração, API do k3s e afins, fica restrita a essa interface, nunca exposta na interface pública.

`firewalld_redes_k3s` são as duas faixas internas do k3s, pods em 10.42.0.0/16 e services em 10.43.0.0/16, conferidas de verdade no cluster com `kubectl get nodes -o jsonpath='{.items[0].spec.podCIDR}'` e o clusterIP do Service `kubernetes`. Elas vão pra zona confiável por origem, não por nome de interface, porque cada pod cria sua própria interface `veth*` dinamicamente e não daria pra manter uma lista fixa. Sem isso, o firewalld aplicaria a política padrão da zona pública também ao tráfego interno entre pods, derrubando a rede do cluster inteiro. Esse era o risco real por trás do aviso genérico de que a mudança "pode quebrar o tráfego entre pods".

### vault-repo

Clona ou atualiza o [`infrastructure-vault`](https://github.com/ladesa-ro/infrastructure-vault) em `/opt/infrastructure-vault`, com sua própria deploy key, só leitura. Roda antes do `argocd-bootstrap`, que consome os arquivos cifrados de lá.

Falha cedo, com mensagem clara, se a deploy key ainda não existir no node, em vez de deixar o `ansible.builtin.git` estourar um erro genérico de permissão SSH.

Tem sua própria tag, `vault-repo`, mas não é pulado pelo `ansible-pull`: precisa rodar em toda execução periódica pra puxar segredos novos capturados depois do bootstrap inicial, do mesmo jeito que o próprio `infrastructure` se atualiza sozinho a cada ciclo.

### argocd-bootstrap

Bootstrap do Argo CD: o release Helm, os AppProjects `ladesa` e `ladesa-satellites`, e a Application `root`. Os values do release ficam em `files/argocd-values.yaml`, dentro deste mesmo role, não no root do repositório.

Fronteira de posse: este role é dono só do release Helm do Argo CD e dos manifests em `argocd/root`, os dois AppProjects e a Application root. Tudo que o `root` descobre em `argocd/apps`, recursivamente, é do próprio Argo CD, que sincroniza sozinho a partir daí. O Ansible nunca aplica nada dentro de `argocd/foundation` ou `argocd/apps` diretamente, só o que está em `argocd/root`. Isso evita Helm e Argo CD disputando o mesmo recurso depois.

Dois AppProjects, não um só, por escopo de risco: `ladesa` cobre só `infrastructure.git` e os charts Helm que os serviços de foundation já usam hoje (Infisical, Portainer), com `clusterResourceWhitelist` largo (`ClusterRole`, `ClusterRoleBinding`, `CustomResourceDefinition`, os dois tipos de webhook), porque cert-manager e o Infisical Operator legitimamente precisam disso. `ladesa-satellites` cobre os cinco repositórios de time (`web`, `docs`, `management-service`, `timetable-generator`, `authentication-service`) mais o chart da Stakater, sem nenhum recurso cluster-wide além de `Namespace`. Sem essa separação, um commit malicioso ou uma credencial de CI comprometida em qualquer um desses cinco repositórios de time poderia criar um `ClusterRoleBinding` de cluster-admin ou um `MutatingWebhookConfiguration` interceptando qualquer pod do cluster, não só afetar o próprio namespace. Nenhum `app-*.yaml` desses repositórios existe ainda (ver Estrutura), então quando forem criados, devem declarar `project: ladesa-satellites`, nunca `project: ladesa`.

O role nunca faz `helm upgrade --install` cego. Antes de tocar no release, lê o que já está instalado e compara com o que este repositório declara, e só aplica se houver divergência real. Isso importa porque o ansible-pull roda sozinho, sem ninguém olhando: sem essa checagem, um ajuste manual feito pra debugar em produção seria desfeito na próxima execução sem aviso. O mesmo vale pro root.yaml, sempre com kubectl diff antes de kubectl apply.

A versão do chart, 10.3.3, entrega o Argo CD v3.5.1. Confirmei contra a documentação oficial de versões testadas do Argo CD que essa linha (v3.5.x) é testada contra Kubernetes v1.33, que é a versão do k3s deste cluster.

`files/argocd-values.yaml` declara ingress em `argocd.ladesa.com.br`, seguindo o mesmo padrão de `infisical.ladesa.com.br` e `portainer.ladesa.com.br`. Esse hostname específico não veio de nenhum values já capturado do cluster, foi proposto por analogia. Conferi via `dig` que já resolve pros mesmos IPs dos outros dois, então é provável que exista um wildcard na zona DNS, mas vale confirmar visualmente que o Argo CD abre em `https://argocd.ladesa.com.br` depois do primeiro apply, já que essa parte específica não foi validada contra o estado real do cluster como o resto deste role foi.

### self-pull-timer

Instala e habilita o timer do systemd que faz o node reconciliar este repositório sozinho, sem depender de ninguém rodando `ansible-playbook` na mão depois disso.

Falha cedo, com mensagem clara, se a deploy key SSH do `infrastructure`, a deploy key do `infrastructure-vault` ou a senha do vault ainda não existirem no node, em vez de habilitar um timer que ia falhar sozinho na primeira execução automática.

Fica na tag `self-pull-timer`, fora tanto da primeira passada quanto da ativação do firewalld. É a última etapa do bootstrap, roda só depois que o gate de drift zero confirmou que tudo mais está limpo, com sua própria invocação.

Uma vez habilitado, o próprio `ansible-pull` volta a rodar este role a cada execução periódica (a tag não é pulada nele), o que mantém o unit e o timer sincronizados com o que este repositório declarar no futuro.

## Segredos

A maioria dos segredos de aplicação, senha de banco, token de app e assim por diante, passa pelo Infisical e chega ao cluster via recursos `InfisicalSecret` (ver os arquivos `infisicalsecret-*.yaml` em `argocd/foundation`). Cada um aponta pro projeto correspondente no Infisical, ambiente `prod`. A identidade de máquina que autentica esses recursos (`universal-auth-credentials`) precisa ter acesso de leitura concedido em cada projeto novo, isso é feito pela própria UI do Infisical, não por este repositório.

Cinco arquivos ficam fora desse caminho, cifrados com Ansible Vault, num repositório separado, [`infrastructure-vault`](https://github.com/ladesa-ro/infrastructure-vault), pra não misturar segredo, nem cifrado, com o resto deste repositório. Os quatro manifestos Kubernetes ficam em `secrets/k8s/<namespace>/`, um por namespace de destino; `k3s-token`, que não é um manifesto Kubernetes, fica em `secrets/node/`. O role `vault-repo` clona esse repositório no node, em `/opt/infrastructure-vault`, e é de lá que o `argocd-bootstrap` lê os quatro manifestos:

`secrets/k8s/default/universal-auth-credentials.yaml`: a credencial de machine identity que o Infisical Kubernetes Operator usa pra se autenticar no Infisical. Não pode viver dentro do próprio Infisical, já que é o que autentica nele.

`secrets/k8s/infisical/infisical-secrets.yaml`, referenciado por `kubeSecretRef` em `foundation-infisical.yaml`: os segredos internos do próprio servidor Infisical, incluindo `DB_CONNECTION_URI` e `REDIS_URL`. Mesmo motivo: o Infisical não pode guardar os próprios segredos de bootstrap.

`secrets/k8s/dados/pg-env.yaml`: a `DB_CONNECTION_URI` de `infisical-secrets` aponta pro `db-postgres` compartilhado, então o Infisical depende do Postgres pra subir. Se `pg-env` viesse de um `InfisicalSecret`, seria uma dependência circular: o Postgres não sobe sem a credencial, a credencial não chega sem o Infisical, o Infisical não sobe sem o Postgres. O projeto `foundation-postgres-fw7-t`, criado no Infisical antes dessa correção, foi apagado por ficar sem uso.

`secrets/k8s/redis-server/redis-secret.yaml`: mesmo motivo do `pg-env`. `REDIS_URL` em `infisical-secrets` aponta pro Redis compartilhado, não pra um Redis embutido no chart do Infisical (os values capturados têm `redis.enabled: false`). O projeto `foundation-redis-nkal`, criado antes dessa correção, também foi apagado.

`secrets/node/k3s-token`, de natureza diferente dos outros quatro: não é um `Secret` do Kubernetes, é o conteúdo cru de `/var/lib/rancher/k3s/server/token` no node, cifrado com `ansible-vault encrypt --output`. Guardado só como registro pra disaster recovery (é o que permitiria um segundo node se juntar a este cluster no futuro), não é reconciliado automaticamente por nenhuma task, já que sobrescrever o token de um node que já está rodando com ele não tem propósito.

Os quatro primeiros foram capturados direto do cluster já rodando com `scripts/create-from-cluster`, dentro do `infrastructure-vault`, que busca o `Secret` e o `Namespace`, limpa campos de runtime, e cifra o resultado com `ansible-vault`, sem nenhum passo intermediário que imprima o valor em texto puro. A senha usada foi gerada no próprio node com `openssl rand -base64 32`, redirecionada direto pro arquivo, nunca exibida em tela nenhuma.

Formato de cada arquivo: um manifesto Kubernetes normal (`kind: Secret`), cifrado com `ansible-vault`, com o `Namespace` de destino bundlado como um segundo documento no mesmo arquivo, separados por `---`. Isso importa porque na primeira execução `kubectl diff` faz dry-run e pode não encontrar um namespace que ainda não existe, então o `Namespace` precisa ir junto pra a task de reconciliação (`ansible/roles/argocd-bootstrap/tasks/kubernetes-manifest-vault.yml`) aplicar os dois na mesma chamada.

Pra capturar um segredo novo do cluster no mesmo formato, dentro do clone local de `infrastructure-vault`:

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
scripts/create-from-cluster <secret> <namespace> secrets/k8s/<namespace>/<nome>.yaml /root/infrastructure-vault-pass
```

Depois, no repositório `infrastructure`, adicionar o caminho em `argocd_kubernetes_manifests_vault` no `host_vars/ldsa.yml`, apontando pra `{{ vault_repo_dir }}/secrets/k8s/<namespace>/<nome>.yaml`.

A senha do vault não fica em nenhum dos dois repositórios. Vive em `/root/infrastructure-vault-pass` no próprio node, `0600`, gerada com `openssl rand`, nunca commitada nem exibida. `ansible/systemd/ansible-pull.service` já referencia esse caminho via `--vault-password-file`.

## Foundation

Manifests dos core services em `argocd/foundation`, trazidos como já rodam hoje no cluster, sem trocar tecnologia nenhuma.

`cert-manager`: `cert-manager-v1.16.2.yaml` é o manifesto oficial vendorizado, não algo gerado a partir de `kubectl get -o yaml`. O cert-manager no cluster hoje foi instalado via `kubectl apply -f` do release manifest oficial da Jetstack, não via Helm. A representação mais fiel disso em GitOps é o próprio arquivo que foi aplicado, não uma reconstrução a partir do estado ao vivo, que perderia CRDs e RBAC e ganharia ruído de runtime. Foi baixado de `https://github.com/cert-manager/cert-manager/releases/download/v1.16.2/cert-manager.yaml`, e a versão da imagem foi conferida contra o Deployment ao vivo antes de commitar. Pra atualizar a versão: baixar o novo release manifest, substituir o arquivo, e validar com `kubectl diff` antes de deixar o Argo CD sincronizar.

`dados`: `postgres.yaml`, `mariadb.yaml`, `minio.yaml` e `adminer.yaml` foram copiados como estão de `/root/dados/k8s/stacks/` no node, sem segredo nenhum, só referenciam Secrets por nome. `mariadb-env` e `minio-env` chegam via `InfisicalSecret` (projetos `foundation-mariadb-6s-ji` e `foundation-minio-z-hvh`). `pg-env` vai pelo Ansible Vault, pelo motivo já explicado em Segredos. Estes serviços têm mapeamento de porta externo, provavelmente NAT de algum roteador ou proxy fora do cluster: Postgres na 30989, MinIO S3 na 30900, MinIO console na 30901, MariaDB na 30996, Adminer na 30001. Esse mapeamento não está documentado neste repositório; confirmar com quem administra a rede antes de mudar qualquer uma dessas portas.

`redis`: o manifesto originalmente aplicado no cluster, visível na annotation `kubectl.kubernetes.io/last-applied-configuration`, declarava o Service `redis-server` como `LoadBalancer`. O que está rodando hoje é `ClusterIP`, um drift real entre o que foi aplicado uma vez e o estado atual. `service.yaml` congela o estado atual, `ClusterIP`, pra não mudar comportamento ao adotar. Se o `LoadBalancer` for necessário, é uma mudança deliberada, feita à parte. `redis-secret` vai pelo Ansible Vault, mesmo motivo do `pg-env`.

## Scripts

`scripts/freeze-manifest.sh <tipo> <nome> <namespace>` congela o manifesto atual de um recurso já rodando no cluster, via `kubectl get -o json` limpo de campos de runtime com `jq`, pra virar fonte de verdade em `argocd/foundation`. Precisa de `jq` na máquina que rodar, não `yq`: a versão do Debian tem uma sintaxe de CLI diferente da que este script assume, `jq` evita essa ambiguidade.

Usa o estado ao vivo, não a annotation `kubectl.kubernetes.io/last-applied-configuration`. Já apareceu um caso real neste cluster, o Service `redis-server` (ver Foundation acima), onde o que foi aplicado uma vez diverge do que está rodando hoje. Congelar o `last-applied` reintroduziria essa mudança sem ninguém pedir.

Exemplo: `./freeze-manifest.sh deployment rabbitmq ladesa-ro-production`

## Gate de drift zero

Este cluster já tem dado real de produção. Nada sincroniza automaticamente, nem pelo Ansible nem pelo Argo CD, até que todo manifesto em `argocd/foundation` mostre diff vazio contra o cluster ao vivo, conferido app por app com o Argo CD ainda em modo manual. Isso vale pra esta adoção inicial e pra qualquer mudança futura nesses manifests.

Depois que os diffs baterem limpos, `foundation` entra primeiro por ser menor risco. Depois `web` e `docs`. `management-service` e `timetable-generator` por último, por terem a maior superfície.

## Bootstrap mínimo na VM

Passo a passo completo, do zero até o Ansible e o Argo CD assumirem sozinhos a reconciliação do que já está em `argocd/foundation`. Isso **não** inclui subir as aplicações (`web`, `docs`, `management-service`, `timetable-generator`, `authentication-service`) via Argo CD, isso depende de cada um desses repositórios ganhar sua própria pasta `gitops`, trabalho que ainda não começou em nenhum deles. Quando começar, vira sua própria documentação, não uma extensão desta.

Cada bloco de comando abaixo é pra copiar e colar, na ordem. A maioria roda direto numa sessão SSH no node; os passos 1 e a primeira parte do 5 são exceção, e rodam da sua própria máquina, marcados explicitamente onde isso muda. Todos assumem `bash` (funcionam em `zsh`/`dash`/`sh` também, a sintaxe é POSIX). Não funcionam em `fish`: usam `export VAR=valor` (em `fish` seria `set -x VAR valor`) e um laço `for ... do ... done` (em `fish` seria `for ... ; ... ; end`, com substituição de comando via `(...)` em vez de `$(...)`). Se a sessão SSH abrir num shell diferente, rodar `bash` primeiro pra entrar num subshell compatível antes de colar qualquer bloco.

### 0. Antes de tudo

Precisa de acesso SSH configurado ao node (o alias, endereço e porta reais não estão neste repositório, ver [Estado fora do git](#estado-fora-do-git)). Sem isso nenhum dos passos abaixo é possível.

### 1. Instalar as dependências no node

Diferente do resto deste guia, este passo roda da sua própria máquina, não numa sessão SSH no node: o node ainda não tem `ansible-core`, então não dá pra usar o `ansible-pull` pra instalar o próprio `ansible-core`. `ansible/bootstrap.yml` resolve isso via push, com `ansible.builtin.raw` (que não depende de Python já existir no destino), e de passagem já deixa `jq` (pros scripts de captura de segredo) e o CLI do `argocd` (pro gate de drift zero mais adiante, fixado por versão e checksum, a mesma versão que o chart do Argo CD deste repositório instala) prontos. Precisa ter `ansible-core` instalado na sua própria máquina antes de rodar isso, a partir do seu clone local deste repositório:

```bash
cd ansible
ansible-playbook -i ldsa, bootstrap.yml --tags prereqs
```

Se algum download falhar checksum, o próprio Ansible para com erro, o binário baixado não é o esperado.

### 2. Gerar a senha do Ansible Vault

Sem exibir o valor em tela nenhuma, redirecionado direto pro arquivo:

```bash
umask 077
openssl rand -base64 32 > /root/infrastructure-vault-pass
chmod 600 /root/infrastructure-vault-pass
```

### 3. Gerar e registrar a deploy key SSH do infrastructure

O node precisa de uma chave própria, só leitura, pra clonar este repositório:

```bash
ssh-keygen -t ed25519 -f /root/.ssh/infrastructure-deploy-key -N ""
cat /root/.ssh/infrastructure-deploy-key.pub
```

Copiar a saída do último comando e adicionar em `github.com/ladesa-ro/infrastructure` → Settings → Deploy keys → Add deploy key, sem marcar "Allow write access".

### 4. Gerar e registrar a deploy key SSH do infrastructure-vault

O `infrastructure-vault` precisa da mesma coisa, com sua própria chave, separada da anterior:

```bash
ssh-keygen -t ed25519 -f /root/.ssh/infrastructure-vault-deploy-key -N ""
cat /root/.ssh/infrastructure-vault-deploy-key.pub
```

Copiar a saída do último comando e adicionar em `github.com/ladesa-ro/infrastructure-vault` → Settings → Deploy keys → Add deploy key, sem marcar "Allow write access".

### 5. Clonar o repositório no node

Só o `infrastructure`. O `infrastructure-vault` é clonado automaticamente pelo role `vault-repo`, no próximo passo, não precisa fazer isso na mão. De novo da sua própria máquina, mesmo `bootstrap.yml` do passo 1, agora com a deploy key já registrada:

```bash
ansible-playbook -i ldsa, bootstrap.yml --tags clone
```

A partir daqui, os comandos voltam a ser numa sessão SSH no node, dentro de `/opt/infrastructure`.

```bash
ssh ldsa
cd /opt/infrastructure
```

### 6. Primeira execução: k3s, vault-repo e o release do Argo CD

Pulando o firewalld e o timer de propósito, os dois só entram depois. Rodar `--check` primeiro, ler a saída, só depois rodar de verdade.

Nesta primeira vez, `--check` não tem muito o que prever: k3s, o binário do helm e o clone do `infrastructure-vault` ainda não existem de verdade nesse node, e nada que dependa deles (release do Argo CD, diff do `root.yaml`, segredos) consegue ser conferido ainda, só confirma que a sintaxe e a ordem das tasks estão corretas. Cada role avisa isso explicitamente na saída. O `--check` volta a ser um preview de verdade a partir da segunda execução em diante.

Atenção: essa execução reinicia o k3s. O node ainda não tem `/etc/rancher/k3s/config.yaml`, o role cria esse arquivo agora, e a criação conta como mudança, então o k3s reinicia pra aplicar. É esperado, é um reinício de controle-plane real, não algo que só aparece no `--check`. Pods continuam rodando, é só o control plane que pisca.

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml --skip-tags firewalld,self-pull-timer --vault-password-file /root/infrastructure-vault-pass --check
```

```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml --skip-tags firewalld,self-pull-timer --vault-password-file /root/infrastructure-vault-pass
```

### 7. Gate de drift zero

Antes de qualquer sync automático, todo `Application` precisa mostrar diff vazio contra o cluster real. O `--core` faz o `argocd` falar direto com a API do Kubernetes, sem precisar logar no servidor nem saber a senha de admin:

```bash
for app in $(kubectl get applications -n argocd -o jsonpath='{.items[*].metadata.name}'); do
  echo "=== $app ==="
  argocd app diff "$app" --core
done
```

Só segue pro próximo passo depois que isso rodar limpo, sem diff nenhum, em todas.

### 8. Ligar o firewalld

Atenção: quem administra acessa o node por uma porta externa não-padrão, mas isso é NAT feito antes de chegar na VM. O `sshd` da própria VM escuta na porta 22 padrão (confira com `ss -tlnp | grep sshd`), e é essa porta, 22, que o firewalld precisa liberar, já comitada como default. Usar a porta externa por engano bloquearia o próprio SSH.

```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml --tags firewalld --vault-password-file /root/infrastructure-vault-pass --check
```

```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml --tags firewalld --vault-password-file /root/infrastructure-vault-pass
```

Depois de rodar, testar uma nova conexão SSH numa aba separada antes de fechar a sessão atual, pra confirmar que o acesso não quebrou.

### 9. Ligar a reconciliação automática

Só depois de tudo confirmado acima:

```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml --tags self-pull-timer --vault-password-file /root/infrastructure-vault-pass --check
```

```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml --tags self-pull-timer --vault-password-file /root/infrastructure-vault-pass
```

Confirmar que o timer ficou ativo:

```bash
systemctl status ansible-pull.timer
```

A saída precisa mostrar `active`. A partir daqui o node reaplica este repositório sozinho, num intervalo, e o Argo CD mantém tudo em `argocd/apps` sincronizado sozinho a partir da Application root. É esse o ponto real em que o Ansible e o Argo CD assumem.

### O que não está aqui

Subir `web`, `docs`, `management-service`, `timetable-generator` e `authentication-service` via Argo CD. Depende de cada repositório ganhar sua própria pasta `gitops`, ainda não começou.

## Estado fora do git

Este repositório não guarda tudo. Não pode: senha e chave privada, por definição, não vão pra um repositório em texto puro nem cifrado sem necessidade. O risco disso não é o valor estar fora do git, é o quê está fora do git virar conhecimento tribal que ninguém mais lembra. Esta tabela existe pra isso não acontecer: cada linha aponta pra uma coisa que não está versionada, mas o fato dela existir, onde ela vive, e como recriar, está.

| O quê | Onde | Arquivo ou local exato | Por que não pode estar no git | Como recriar se perder |
|---|---|---|---|---|
| Acesso SSH ao node | *sua máquina* | `~/.ssh/config`, alias `ldsa` | endereço e porta reais de um servidor de produção não devem ficar públicos num repositório | Pedir o endereço e a porta a quem já tem acesso, configurar o alias localmente |
| Senha do Ansible Vault | *node* | `/root/infrastructure-vault-pass`, `0600` | decripta os cinco arquivos cifrados em `infrastructure-vault` | Gerar senha nova (`openssl rand -base64 32 > ...`), depois rodar `scripts/create-from-cluster` de novo pros quatro Secrets (eles ainda existem no cluster) e recapturar `k3s-token` a partir de `/var/lib/rancher/k3s/server/token`, sobrescrevendo os arquivos cifrados em `infrastructure-vault` |
| Deploy key SSH do `infrastructure`, metade privada | *node* | `/root/.ssh/infrastructure-deploy-key` | dá acesso de clone ao repositório `infrastructure` | Gerar par novo (isso também invalida a metade pública já registrada, ver linha abaixo) |
| Deploy key SSH do `infrastructure`, metade pública | *GitHub* | Settings → Deploy keys, do repositório `infrastructure` | é o que autoriza a chave privada acima | Registrar a nova chave pública gerada ao lado |
| Deploy key SSH do `infrastructure-vault`, metade privada | *node* | `/root/.ssh/infrastructure-vault-deploy-key` | dá acesso de clone ao repositório `infrastructure-vault` | Gerar par novo (isso também invalida a metade pública já registrada, ver linha abaixo) |
| Deploy key SSH do `infrastructure-vault`, metade pública | *GitHub* | Settings → Deploy keys, do repositório `infrastructure-vault` | é o que autoriza a chave privada acima | Registrar a nova chave pública gerada ao lado |
| `ansible-core`, `jq` e o CLI do `argocd` | *node* | pacotes `apt` e binário em `/usr/local/bin` | pré-requisito que o `ansible-pull` não consegue instalar sozinho, é o que roda antes dele existir | Ver passo 1 do bootstrap acima |
| Projetos e valores no Infisical | *Infisical* | `infisical.ladesa.com.br`: `foundation-mariadb-6s-ji`, `foundation-minio-z-hvh` | senha de app/banco tem sistema próprio pra isso, o Infisical, não faz sentido duplicar em outro cofre | Recriar o projeto, colar o valor, conceder acesso de leitura à machine identity `universal-auth-credentials`, atualizar o `projectSlug` no `infisicalsecret-*.yaml` correspondente |
| Acesso da machine identity aos projetos | *Infisical* | dentro de cada projeto, Access Control | é permissão, não segredo, mas só existe na configuração do Infisical, não em arquivo nenhum | Conceder de novo, projeto por projeto, pela UI |

Regra pra manter esta lista útil: toda vez que alguma coisa nova precisar viver fora do git, uma linha entra aqui antes de considerar o trabalho terminado.

## Lint

`.yamllint` e `.ansible-lint` na raiz. `ansible-lint` ignora `argocd/` (não é Ansible). Rodar com `yamllint .` e `ansible-lint` antes de propor mudança.

## Commits

Os commits aqui seguem Conventional Commits só no título, `type(scope): subject`. Sem corpo, sem Co-Authored-By.
