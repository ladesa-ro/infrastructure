# Pendências

**TLDR**: bypass de CI pra desfazer depois, débito técnico real (não gambiarra descartável), rotação de senha planejada, e a rotina de operação contínua ainda por criar. Cada item tem uma condição clara de quando resolver, não fica em aberto pra sempre sem critério.

Esta página existe pelo mesmo motivo de [Estado fora do git](estado-fora-do-git.md): decisão deliberada de adiar algo é diferente de esquecer que ela existe. Toda vez que um bypass, gate desligado, ou solução temporária entrar no repositório, uma linha entra aqui antes de considerar o trabalho terminado.

## Bypasses de CI a desfazer

- [ ] **`misconfig` (trivy) em `security.yml` está `continue-on-error: true`** desde 2026-08-21. Motivo: a primeira varredura real achou `securityContext` ausente em `postgres`, `mariadb`, `minio`, `adminer` (namespace `dados`), `rabbitmq` e `redis-server`, achado real, mas cada imagem tem UID/GID próprio, corrigir errado quebra o container. Condição pra reverter pra bloqueante: cada Deployment listado abaixo, em "Débito técnico: `securityContext`", corrigido e validado contra o serviço real.
- [ ] **Todos os checks de `codigo-e-infra` em `quality.yml`** (`yamllint`, `ansible-lint`, `jscpd`, `kubeconform`, `shellcheck`, `actionlint`, `zizmor`, `cspell`) são `continue-on-error: true` desde que o job foi criado, nunca foram bloqueantes. Condição pra promover cada um: revisar o baseline de achados daquele check especificamente, zerar o que for real, só então tirar o `continue-on-error` (ver [Qualidade de código e infraestrutura](desenvolvimento.md#qualidade-de-codigo-e-infraestrutura)).
- [ ] **`skip-dirs` de `argocd/foundation/cert-manager` e `argocd/foundation/cnpg` no trivy** não é bem um bypass a desfazer, é permanente por natureza (RBAC exigido pelo próprio operador vendorizado, ver [Foundation](../arquitetura/foundation.md#debito-tecnico-conhecido-securitycontext-ausente)). Mantido aqui só pra registro, não some sozinho de uma auditoria futura sem essa nota.

## Débito técnico: `securityContext` ausente

Acompanha o item acima. Um item por serviço, porque a correção de cada um é independente (UID diferente, risco de quebrar não é o mesmo):

- [x] `argocd/foundation/dados/postgres.yaml`: resolvido pela migração pro CloudNativePG em 2026-08-21 (o operador roda com usuário fixo não-root por padrão), arquivo removido do repositório, ver [Foundation](../arquitetura/foundation.md).
- [ ] `argocd/foundation/dados/mariadb.yaml`
- [ ] `argocd/foundation/dados/minio.yaml`
- [ ] `argocd/foundation/dados/adminer.yaml`
- [ ] `argocd/foundation/rabbitmq/deployment.yaml`
- [ ] `argocd/foundation/redis/deployment.yaml`

## Rotação de senha planejada

Ver [Estado fora do git, rotação preventiva](estado-fora-do-git.md#rotacao-preventiva) pro procedimento de cada item. Itens específicos que valem rotação assim que a condição bater, não só "algum dia":

- [ ] **As 4 roles do Postgres** (`ladesa`, `infisical`, `api-dev`, `sso-production`): depois que a migração pro CloudNativePG estiver concluída e confirmada (o processo de import descriptografa a senha de cada role em memória volátil no node, mesmo nunca gravando em disco ou git, defesa em profundidade justifica rotacionar depois, não só confiar que não vazou).
- [ ] **Senha do Ansible Vault**: sem condição de gatilho específica ainda, cadência a definir pela equipe (ver rotação preventiva).
- [ ] **As duas deploy keys** (`infrastructure`, `infrastructure-vault`): mesma cadência a definir, ou imediatamente se alguém que teve acesso ao node sair da equipe (ver [ciclo de vida de acesso](estado-fora-do-git.md#d-ciclo-de-vida-de-acesso)).

## Rotina de operação contínua a criar

Hoje só existe documentação de **bootstrap** (rodar uma vez, do zero até o cluster de pé, ver [Bootstrap mínimo na VM](bootstrap.md)). Falta a contraparte de **manutenção contínua**: uma seção própria, separada do bootstrap, cobrindo o que se repete depois que o cluster já está rodando.

- [ ] **Rotação de senha recorrente**, cobrindo os dois universos de segredo deste repositório, não só um: os de bootstrap (Ansible Vault, ver acima) **e** os gerenciados pelo [Infisical](../aprender/infisical.md) (`mariadb-env`, `minio-env`, `rabbitmq-config`, os próprios segredos internos do Infisical). Definir cadência, quem executa, e o procedimento exato pra cada categoria (os dois não se resolvem do mesmo jeito: um é `ansible-vault` + `scripts/create-from-cluster`, o outro é a UI/API do Infisical).
- [ ] **Acompanhamento de saúde** do cluster (o que checar, com que frequência, o que fazer se algo estiver fora do esperado) ainda não tem escopo definido, precisa ser desenhado antes de virar documentação.
- [ ] Decidir onde essa seção mora: `docs/operacao/` ganha uma página nova (ex.: `manutencao.md`), ou vira parte de [Checklist](checklist.md) com uma segunda tabela, separada da de bootstrap.
