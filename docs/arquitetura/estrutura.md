# Estrutura

```
ansible/
  bootstrap.yml                playbook rodado da sua máquina, via push, só na primeira vez (ver passo 1)
  site.yml, local.yml         playbooks: local.yml é o entrypoint do ansible-pull
  inventory/                  host único (conexão local, os comandos abaixo rodam de dentro do próprio node), versões pinadas
  roles/
    k3s/                      instala o k3s
    firewalld/                liga o firewall (tag separada, não roda pelo ansible-pull sem supervisão)
    vault-repo/                clona o infrastructure-vault no node
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

`bootstrap.yml` é a exceção ao resto do Ansible deste repositório: roda via push, da máquina de quem administra contra o node por SSH, em vez de via `ansible-pull` local. Existe só porque o node não tem `ansible-core` instalado antes da primeira execução, então nada aqui pode depender do próprio `ansible-pull` pra se instalar. Não é um role, não entra em `site.yml`, e nunca roda de novo depois do bootstrap inicial (ver passos 1 e 5 do [Bootstrap mínimo na VM](../operacao/bootstrap.md)).

## Por que o histórico deste repositório começa com um commit só

Antes deste repositório ser público, ele acumulou um histórico com várias iterações de segredo cifrado (sempre cifrado, nunca em texto puro, mas ainda assim conteúdo que não faz sentido expor publicamente). Quando o repositório passou de privado pra público, o histórico foi comprimido num único commit inicial, e o repositório antigo foi preservado, privado, até a migração estar validada. Dali pra frente, o histórico volta a crescer normalmente, commit por commit.
