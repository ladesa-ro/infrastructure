# Checklist

Cada item corresponde a um passo em [Bootstrap mínimo na VM](bootstrap.md). Serve pra saber onde você está e o que ainda falta, não pra marcar sem conferir de verdade o resultado de cada comando.

- [ ] Acesso SSH ao node configurado (`~/.ssh/config`, alias próprio) (*sua máquina*): [configurar e validar](bootstrap.md#0-antes-de-tudo)
- [ ] `ansible-core`, `jq` e o CLI do `argocd` instalados no node, checksum do `argocd` conferido pelo próprio Ansible (*sua máquina, via `bootstrap.yml`*): [configurar e validar](bootstrap.md#1-instalar-as-dependencias-no-node)
- [ ] Senha do Ansible Vault gerada em `/root/infrastructure-vault-pass` (*node, via SSH*): [configurar e validar](bootstrap.md#2-gerar-a-senha-do-ansible-vault)
- [ ] Deploy key SSH do `infrastructure` gerada (*node, via SSH*): [configurar e validar](bootstrap.md#3-gerar-e-registrar-a-deploy-key-ssh-do-infrastructure)
- [ ] Deploy key do `infrastructure` registrada como leitura em `github.com/ladesa-ro/infrastructure` (*GitHub, no navegador*): [configurar e validar](bootstrap.md#3-gerar-e-registrar-a-deploy-key-ssh-do-infrastructure)
- [ ] Deploy key SSH do `infrastructure-vault` gerada e registrada como leitura em `github.com/ladesa-ro/infrastructure-vault` (*node, via SSH* e *GitHub, no navegador*): [configurar e validar](bootstrap.md#4-gerar-e-registrar-a-deploy-key-ssh-do-infrastructure-vault)
- [ ] Repositório `infrastructure` clonado no node com sua deploy key (*sua máquina, via `bootstrap.yml`*): [configurar e validar](bootstrap.md#5-clonar-o-repositorio-no-node)
- [ ] Primeira execução (`k3s` + `vault-repo` + `argocd-bootstrap`) rodada com `--check` e depois de verdade, sem erro (*node, via SSH*): [configurar e validar](bootstrap.md#6-primeira-execucao-k3s-vault-repo-e-o-release-do-argo-cd)
- [ ] Gate de drift zero: `argocd app diff --core` vazio em **todas** as Applications, não só nas óbvias (*node, via SSH*): [configurar e validar](bootstrap.md#7-gate-de-drift-zero)
- [ ] Firewalld ligado, e uma segunda conexão SSH testada com sucesso antes de fechar a primeira (*a segunda conexão é da sua máquina, o resto é no node*): [configurar e validar](bootstrap.md#8-ligar-o-firewalld)
- [ ] Timer do `ansible-pull` habilitado (`systemctl status ansible-pull.timer` mostra `active`) (*node, via SSH*): [configurar e validar](bootstrap.md#9-ligar-a-reconciliacao-automatica)

Se algum item não estiver limpo, não segue pro próximo. É a mesma regra do [gate de drift zero](../arquitetura/gate-de-drift-zero.md), só que pro bootstrap inteiro.
