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

## Modernização de Applications do `argocd/foundation`

Levantamento feito em 2026-08-21, pesquisando estado atual de cada tecnologia antes de propor qualquer mudança (mesmo cuidado da migração do Postgres pro CloudNativePG, que já está concluída, ver [Foundation](../arquitetura/foundation.md)). Cada item precisa do mesmo processo cuidadoso (pesquisa, plano, cluster descartável, dead man switch) antes de ir pra produção, nenhum aqui é "só trocar o YAML".

- [ ] **`argocd/foundation/dados/minio.yaml` (crítico)**: MinIO Inc. moveu os recursos abertos (WebUI, LDAP/OIDC, erasure coding distribuído) pro produto proprietário AIStor, e a Community Edition original parou de receber release binário mantido. Em resposta, existe **[Silo](https://github.com/pgsty/silo)** (renomeado de `pgsty/minio` em 2026-08-06), um fork mantido pela comunidade (projeto Pigsty) que preserva o MinIO 100% aberto (AGPLv3), compatível na API/config/Helm chart com o que já está rodando aqui, com release binário e backport de segurança contínuos: é provavelmente o caminho de menor esforço, drop-in, sem precisar reescrever configuração nem migrar formato de dado. Alternativas com migração de verdade (API compatível mas armazenamento diferente): Garage (self-hosted leve), SeaweedFS (muitos objetos pequenos), RustFS.
- [ ] **`argocd/foundation/dados/mariadb.yaml`**: Deployment simples, sem HA, sem operador. `mariadb-operator` é o mais citado hoje pra MariaDB em Kubernetes (clone/snapshot ainda limitado na versão atual), Percona Operator for MySQL como alternativa mais madura/enterprise se preferir. Mesma classe de mudança já feita no Postgres.
- [ ] **`argocd/foundation/rabbitmq/deployment.yaml`**: Deployment simples, uma réplica só, sem HA de verdade. O [RabbitMQ Cluster Operator](https://www.rabbitmq.com/kubernetes/operator/operator-overview) é oficial (mantido pela Broadcom/VMware), padrão de fato pra RabbitMQ em Kubernetes hoje, cuida de peer discovery, rolling upgrade, quorum queues.
- [ ] **`argocd/foundation/cert-manager/cert-manager-v1.16.2.yaml`**: versão vendorizada está bem atrás da atual estável (v1.20.1, com suporte ativo só em 1.20/1.19). Atualização de baixo risco: baixar o novo release manifest oficial, substituir o arquivo, validar com `kubectl diff` antes de sincronizar (mesmo processo já documentado em [Foundation](../arquitetura/foundation.md)).
- [ ] **`argocd/foundation/redis/deployment.yaml`**: Deployment simples, uma réplica. Antes de decidir por um operador (Sentinel/Cluster), confirmar o uso real: se for só cache, sem necessidade de sobreviver a um restart sem perda, single instance continua uma escolha aceitável, não é dívida técnica por si só.
- [ ] **`argocd/foundation/dados/adminer.yaml`**: ferramenta de debug simples, não precisa de operador, só entra no débito técnico de `securityContext` já registrado acima.

## Versões desatualizadas das ferramentas de bootstrap

Levantado em 2026-08-21, contra o que está fixado em `ansible/inventory/host_vars/ldsa.yml`. **Ordem deliberada**: upgrade de versão só depois de todo o resto ao redor já modernizado e validado (os itens acima), nunca como primeiro passo, e sempre com o mesmo processo de contingência já usado na migração do Postgres (cluster/ambiente descartável, dead man switch, backup confirmado antes de aplicar em produção).

- [ ] **k3s**: `v1.33.3+k3s1` em uso, atual é `v1.36.3+k3s1` (3 minors de distância). Conferir changelog de cada minor entre as duas antes de pular direto pra mais recente.
- [ ] **Helm**: `v3.18.6` em uso, atual é `v4.2.4`, **major version**. Historicamente uma virada de major do Helm já teve mudança de ruptura grande (v2 pra v3 removeu o Tiller inteiro). Precisa de pesquisa dedicada sobre o que muda de v3 pra v4 antes de sequer considerar, não é upgrade de rotina.
- [ ] **Argo CD (chart `argo/argo-cd`)**: `10.3.3` em uso, atual é `10.4.0`, minor. Risco mais baixo que os outros dois, mas ainda precisa da mesma validação antes de aplicar (é o próprio Argo CD, erro aqui afeta a reconciliação de tudo).
