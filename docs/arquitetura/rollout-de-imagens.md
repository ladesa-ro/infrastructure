# Rollout de imagens

Como um build novo de um satélite chega de fato a rodar no cluster, e por que isso não acontecia sozinho até 2026-08-28.

## O problema

O padrão descrito em [Repositórios satélite](satelites.md) resolve *onde* a configuração de deploy mora (no git, não numa VM), mas não resolve sozinho *quando* o Argo CD percebe que precisa agir. `docs` e `management-service` publicavam a imagem nova em `ghcr.io/.../<serviço>:development` a cada push em `main`, mas `gitops/apps/<serviço>/values-development.yaml` continuava com o texto `tag: development`, idêntico antes e depois do build. O Argo CD compara manifesto renderizado, não conteúdo de registry — sem diff no texto, `selfHeal` não tem o que corrigir, e o pod antigo continua de pé até alguém reiniciar na mão.

Achado ao vivo duas vezes (ver [pendências](../operacao/pendencias.md#gitops-com-tag-mutavel-nao-reinicia-o-pod-sozinho-achado-real-em-2026-08-22)): uma migração de conteúdo do `docs` que não apareceu no site, e o `management-service` com o pod da API dois dias e vinte e duas horas atrás da imagem publicada, durante a migração da mensageria.

## As opções levantadas

**Tag ou digest imutável por build**, escrito de volta no `values-development.yaml` pelo próprio CI depois do push. É a correção mais direta: o texto muda de verdade a cada build, o Argo CD vê o diff, `selfHeal` age sozinho. Não precisa de nenhum componente novo no cluster. É a opção escolhida agora.

**Argo CD Image Updater**: um controller que observa o registry e escreve a atualização ele mesmo (via commit no git ou patch direto na `Application`), tirando esse passo do workflow de CI de cada satélite. É a opção escolhida.

**Kargo**: promove um artefato ("freight") através de estágios — dev → staging → prod —, cada estágio uma `Application` do Argo CD, com verificação antes de cada promoção. É a ferramenta certa para o problema de *promover entre ambientes*, que hoje não existe aqui: cada satélite tem um ambiente só (`development`). Instalar Kargo agora resolveria um problema que ainda não temos — mas é o rumo declarado: no dia em que existir de fato `staging`/`production` por satélite, é pra Kargo que este mecanismo migra, não pra uma segunda geração do Image Updater.

**Argo Rollouts**: canary, blue-green, análise automática de métricas antes de liberar 100% do tráfego. Categoria diferente de problema — não decide *que* uma imagem nova existe, decide *como* a troca acontece depois que alguém (CI, Image Updater ou Kargo) já disparou o rollout. Com 1 réplica por satélite num node único, não há tráfego pra fatiar entre canary e estável — vale revisitar quando houver mais de uma réplica.

## A decisão

### Primeira tentativa (2026-08-28, manhã): digest via PR automático

A primeira correção implementada foi digest `sha256` imutável, escrito de volta no `values-development.yaml` por um step novo no fim de `build-push.dev.yml` de cada satélite, usando `secrets.GITHUB_TOKEN`. Como `main` é protegida por PR obrigatório com aprovação de code owner em todos os satélites, o step não commitava direto: abria um PR numa branch fixa por satélite, reaproveitando o mesmo PR a cada push (`git push --force`, que também derruba aprovações antigas via `dismiss_stale_reviews_on_push` — correto, um digest novo merece revisão nova).

Funcionou, mas trouxe um atrito real: toda imagem nova de `development` — o ambiente onde ninguém deveria precisar de aprovação humana pra ver o próprio código rodando — parava esperando alguém clicar em "Approve". Isso não é o tipo de fricção que vale a pena carregar por muito tempo, então o mecanismo foi trocado no mesmo dia.

### Decisão final (2026-08-28, tarde): Argo CD Image Updater

Argo CD Image Updater observa o registry diretamente e aplica a atualização como patch na própria `Application` (`write-back-method: argocd`) — sem commit, sem PR, sem ruleset envolvido. Instalado como componente de foundation (`argocd/apps/operators/image-updater`), chart oficial `argo/argocd-image-updater` vendorizado como dependência, mesmo padrão de wrapper local que `cert-manager`/`cnpg` já usam.

A versão do chart instalada (1.2.4, app v1.2.2) mudou de modelo de configuração em relação a versões anteriores da ferramenta: em vez de só anotação na `Application`, ela introduz um CRD próprio, `ImageUpdater`, com dois modos — configuração nativa explícita (`spec.applicationRefs[].images`), ou `useAnnotations: true`, que volta a ler as anotações clássicas `argocd-image-updater.argoproj.io/*` na `Application`, mudando só a seleção de quais Applications processar. Foi escolhido `useAnnotations: true` com um único `ImageUpdater` cobrindo `namePattern: "ladesa-ro-*"` — qualquer satélite novo que seguir a convenção de nome já existente é coberto automaticamente, sem precisar editar esse CR de novo.

Cada satélite ganha 4 anotações na sua `Application`, por exemplo (`docs`):

```yaml
argocd-image-updater.argoproj.io/image-list: docs=ghcr.io/ladesa-ro/docs/docs
argocd-image-updater.argoproj.io/docs.update-strategy: digest
argocd-image-updater.argoproj.io/docs.helm.image-tag: application.deployment.image.digest
argocd-image-updater.argoproj.io/write-back-method: argocd
```

`update-strategy: digest` faz o controller observar a tag `:development` e reagir quando o digest por trás dela muda — a tag continua mutável no registry (isso não muda), só que agora é o Image Updater, não o Argo CD, quem faz esse diff, e ele escreve o valor real e atual do digest como parâmetro Helm sobrepondo `application.deployment.image.digest` (o mesmo campo que o chart `stakater/application` já suportava nativamente, confirmado por `helm template` antes de depender disso). O `values-development.yaml` de cada satélite continua com `tag: development` como valor inicial — nunca é reescrito, só sobreposto em memória pelo Argo CD.

### Webhook do GHCR — reduzindo o delay do polling

Sem webhook, o Image Updater só percebe a imagem nova no próximo ciclo de polling (padrão de mercado ~2min, configurável). Configurado o endpoint nativo `/webhook?type=ghcr.io` do próprio Image Updater (não precisou de nenhum relay como `adnanh/webhook` — GHCR é um dos registries com suporte nativo), exposto via `Ingress` (Traefik, TLS via cert-manager, host `image-updater.ladesa.com.br`, só o path `/webhook`) e um webhook de organização no GitHub pro evento `package`.

Analisado o código-fonte do handler (`pkg/webhook/ghcr.go`, `pkg/webhook/server.go` do `argoproj-labs/argocd-image-updater`) antes de expor isso publicamente: o payload do GitHub carrega só `{repositório, tag}`, nunca um digest — o handler usa isso só pra saber *qual* imagem recheckar agora, e quem resolve o digest de verdade continua sendo uma consulta direta ao registry, no mesmo caminho de reconciliação do polling normal. Não existe campo no payload que vire o digest aplicado, então um payload forjado não tem como injetar imagem nenhuma — na pior hipótese, força uma checagem antecipada de uma imagem que já é real. Ainda assim, o secret HMAC (`X-Hub-Signature-256`, obrigatório por padrão nessa versão — `--webhook-require-secret=true`) segue configurado, com o valor guardado no Infisical (projeto `foundation-image-updater-w0cw`, chave `webhook.ghcr-secret` — nome de chave e de `Secret` (`argocd-image-updater-secret`) fixos pelo próprio controller, não é convenção nossa).

## Estado atual

Implementado em `docs` e `management-service` (2026-08-28), incluindo o webhook. `web` e `authentication-service` continuam sem cobertura — mesmo mecanismo a replicar (anotações na `Application` + confiar no `namePattern` já genérico do `ImageUpdater` CR, nenhuma mudança de infraestrutura nova precisa entrar). O `authentication-service` tem um `promote.yml` de uma abordagem anterior (troca `tag:` por `digest:` em `values-production.yaml` via commit direto), nunca confirmadamente testado — com o Image Updater em produção, esse workflow fica obsoleto, não precisa mais ser "consertado", só removido quando o satélite migrar.

## Hardening futuro

- **Kargo** é o rumo declarado, não uma opção em aberto: no dia em que existir de fato `staging`/`production` por satélite, a promoção entre eles migra pra Kargo. O Image Updater continua fazendo sentido dentro de cada estágio (imagem nova chega automaticamente naquele ambiente); Kargo entra pra decidir quando e como um digest promove de um estágio pro próximo.
- **Replicar as anotações pro `web` e pro `authentication-service`** — mecânico, sem decisão de arquitetura nova; o `ImageUpdater` CR já cobre qualquer satélite `ladesa-ro-*` novo.
- **Argo Rollouts**, quando houver mais de uma réplica por satélite e valer a pena fatiar tráfego entre canary e estável — categoria de problema diferente da que este documento resolve (decide *como* a troca acontece, não *quando* ela é detectada).
- Se o volume de imagens/satélites crescer a ponto de `namePattern: "ladesa-ro-*"` genérico não bastar mais, migrar aquele `ImageUpdater` CR de `useAnnotations: true` pra configuração nativa (`spec.applicationRefs[].images`) — tira a configuração da `Application` de cada satélite e centraliza tudo num único lugar, ao custo de deixar de usar o padrão de anotação mais simples de ler.
