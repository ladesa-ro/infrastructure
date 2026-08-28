# Rollout de imagens

Como um build novo de um satélite chega de fato a rodar no cluster, e por que isso não acontecia sozinho até 2026-08-28.

## O problema

O padrão descrito em [Repositórios satélite](satelites.md) resolve *onde* a configuração de deploy mora (no git, não numa VM), mas não resolve sozinho *quando* o Argo CD percebe que precisa agir. `docs` e `management-service` publicavam a imagem nova em `ghcr.io/.../<serviço>:development` a cada push em `main`, mas `gitops/apps/<serviço>/values-development.yaml` continuava com o texto `tag: development`, idêntico antes e depois do build. O Argo CD compara manifesto renderizado, não conteúdo de registry — sem diff no texto, `selfHeal` não tem o que corrigir, e o pod antigo continua de pé até alguém reiniciar na mão.

Achado ao vivo duas vezes (ver [pendências](../operacao/pendencias.md#gitops-com-tag-mutavel-nao-reinicia-o-pod-sozinho-achado-real-em-2026-08-22)): uma migração de conteúdo do `docs` que não apareceu no site, e o `management-service` com o pod da API dois dias e vinte e duas horas atrás da imagem publicada, durante a migração da mensageria.

## As opções levantadas

**Tag ou digest imutável por build**, escrito de volta no `values-development.yaml` pelo próprio CI depois do push. É a correção mais direta: o texto muda de verdade a cada build, o Argo CD vê o diff, `selfHeal` age sozinho. Não precisa de nenhum componente novo no cluster. É a opção escolhida agora.

**Argo CD Image Updater**: um controller que observa o registry e escreve a atualização ele mesmo (via commit no git ou patch direto na `Application`), tirando esse passo do workflow de CI de cada satélite. Resolve o mesmo problema de um jeito mais centralizado, mas é mais um componente pra operar. Guardado como próximo passo natural se o step de bump no CI de cada satélite começar a incomodar.

**Kargo**: promove um artefato ("freight") através de estágios — dev → staging → prod —, cada estágio uma `Application` do Argo CD, com verificação antes de cada promoção. É a ferramenta certa para o problema de *promover entre ambientes*, que hoje não existe aqui: cada satélite tem um ambiente só (`development`). Instalar Kargo agora resolveria um problema que ainda não temos. Fica para quando existir de fato um `staging`/`production` por satélite pra promover entre eles.

**Argo Rollouts**: canary, blue-green, análise automática de métricas antes de liberar 100% do tráfego. Categoria diferente de problema — não decide *que* uma imagem nova existe, decide *como* a troca acontece depois que alguém (CI, Image Updater ou Kargo) já disparou o rollout. Com 1 réplica por satélite num node único, não há tráfego pra fatiar entre canary e estável — vale revisitar quando houver mais de uma réplica.

## A decisão

Digest `sha256` imutável, escrito de volta no `values-development.yaml` por um step novo no fim de `build-push.dev.yml` de cada satélite, usando o próprio `secrets.GITHUB_TOKEN` do workflow (sem PAT dedicado).

Como `main` é protegida por PR obrigatório com aprovação de code owner (confirmado no `web`, tratado como padrão nos demais satélites), o step não commita direto: abre um PR numa branch fixa por satélite (`chore/bump-image-<satélite>-development`), reaproveitando o mesmo PR a cada push em vez de acumular um novo — `git push --force` na mesma branch atualiza o PR existente e derruba aprovações antigas via `dismiss_stale_reviews_on_push` do ruleset, o que é o comportamento certo (um digest novo merece revisão nova).

```yaml
- name: "[CI] Publicação da imagem"
  id: build
  uses: docker/build-push-action@...
  with: { push: true, tags: "...:development" }

- name: "[CD] Abrir/atualizar PR de bump do digest no gitops"
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    DIGEST: ${{ steps.build.outputs.digest }}
  run: |
    BRANCH="chore/bump-image-<satelite>-development"
    git checkout -B "$BRANCH" origin/main
    sed -i -E "s#^(\s*)(tag|digest): .*#\1digest: ${DIGEST}#" gitops/apps/<app>/values-development.yaml
    git diff --quiet && exit 0   # nada mudou, não abre PR vazio
    git commit -am "chore(gitops): bump <satelite> para ${DIGEST}"
    git push --force origin "$BRANCH"
    # reaproveita PR aberto, ou cria um novo
```

Trade-off aceito conscientemente: PRs abertos com `secrets.GITHUB_TOKEN` não disparam outros workflows (regra anti-loop do GitHub Actions), então `gitops-lint.yml` — o gate que valida "toda imagem tem tag ou digest" — não roda sozinho nesse PR específico. Quem aprova vê o diff, não um check verde automático confirmando que o digest é válido. Aceitável para o volume atual (poucos PRs desse tipo, revisão manual rápida); ver hardening abaixo pra quando isso começar a incomodar.

O chart `stakater/application` (usado em `docs`, `management-service`, `authentication-service`) já suporta `image.digest` nativamente — confirmado via `helm template` local antes de depender disso: `deployment.yaml`/`job.yaml`/`cronjob.yaml` do chart montam `repositório@digest` quando o campo está presente, sem precisar de `tag`.

## Estado atual

Implementado em `docs` e `management-service` (2026-08-28). `web` e `authentication-service` continuam no padrão antigo — mesmo mecanismo a replicar, sem decisão nova a tomar. O `authentication-service` já tem um `promote.yml` fazendo algo parecido (troca `tag:` por `digest:` em `values-production.yaml`), mas nunca confirmadamente testado — vale entender por que não está em uso antes de tomá-lo como base, em vez de escrever o mesmo mecanismo do zero.

## Hardening futuro

- **Trocar `GITHUB_TOKEN` por um PAT dedicado** quando o gate mudo (`gitops-lint.yml` não rodando no PR de bump) começar a doer de verdade — reabilita o check automático no PR, ao custo de gerenciar um segredo novo em cada satélite.
- **Reavaliar Argo CD Image Updater** pra tirar o step de bump do CI de cada satélite e centralizar num único controller, se o número de satélites crescer o suficiente pra essa duplicação de step incomodar.
- **Reavaliar Kargo** no dia em que existir mais de um ambiente por satélite pra promover entre eles — é a ferramenta certa para esse problema específico, só não pra este.
- **Replicar o padrão pro `web` e pro `authentication-service`** — mecânico, mesma receita, sem decisão de arquitetura nova.
- **Argo Rollouts**, quando houver mais de uma réplica por satélite e valer a pena fatiar tráfego entre canary e estável.
