# Topologia declarada do cluster

**TLDR**: o diagrama abaixo mostra os recursos que `argocd/**/*.yaml` declara, gerado a partir do próprio YAML deste repositório, sem tocar no cluster. Não é o estado real de agora, é o estado pretendido no Git. Regenerado manualmente, sem check de CI que avise quando fica desatualizado (motivo na seção "Por que não tem check de CI" abaixo), então confira a data do último commit deste arquivo se precisar ter certeza de que reflete o `argocd/` atual.

## Diagrama

```mermaid
--8<-- "arquitetura/topologia-declarada.mermaid"
```

`cnpg` fica de fora, mesmo motivo já registrado nos outros checks que excluem esse diretório (ver [Pendências](../operacao/pendencias.md)): conteúdo vendorizado do próprio operador, não código deste repositório pra representar. `cert-manager` não precisa mais dessa exclusão desde a migração pro chart oficial em 2026-08-21 (`argocd/foundation/operators/cert-manager/` não existe mais, o gerador já não encontra nada ali pra excluir).

## Por que não é ao vivo

A árvore de recursos que o Argo CD mostra na própria interface parece o mesmo tipo de diagrama, mas nasce de um jeito completamente diferente: o `argocd-server` calcula ela em memória, toda vez que a tela abre, cruzando o manifest já hidratado (depois de `helm template` ou `kustomize build` resolvido) com os objetos de fato existentes no cluster, via `ownerReferences`. Esse resultado nunca é persistido em arquivo, nem em Git, some quando a aba fecha.

Reproduzir isso de verdade exigiria alguém (CI ou um script) com acesso de rede ao `kube-apiserver`, algo que não existe hoje (o cluster fica numa VM isolada, sem rota dos runners do GitHub Actions até lá). Abrir esse acesso é uma decisão de infraestrutura própria, com superfície de ataque nova pra avaliar, não algo que a documentação decide sozinha.

Quem precisa do estado real agora tem dois caminhos, nenhum deles esta página:

- A própria interface do Argo CD, é exatamente pra isso que ela existe.
- `argocd app manifests --source live`, que devolve o manifest tal como está aplicado no cluster neste momento (contra `--source git`, que mostra o que está no repositório, o mesmo dado de origem que esta página usa).

## Por que não tem check de CI

Rodar a mesma geração duas vezes seguidas, sem nenhuma mudança em `argocd/`, produz um arquivo `.mermaid` diferente: a biblioteca `diagrams` (dependência da KubeDiagrams) sorteia um identificador novo pra cada nó a cada execução, e a ordem dos blocos também varia. Um check que regenerasse e comparasse byte a byte (o design inicial cogitado aqui) ficaria permanentemente vermelho mesmo sem nenhuma mudança real, virando ruído, não sinal. Por isso o `kube-diagrams` ficou de fora do `group "default"` do bake (não constrói em todo run de `codigo-e-infra`) e esta página não tem verificação automática de desatualização, diferente dos outros 10 checks de `quality.yml`.

## Como regenerar localmente

```bash
docker buildx bake --file tools/quality/docker-bake.hcl kube-diagrams --load

docker run --rm -v "$PWD:/repo" -w /repo infra-quality/kube-diagrams:local sh -c \
  "kube-diagrams \$(find argocd -name '*.yaml' -not -path 'argocd/foundation/operators/cnpg/*') \
    -o docs/arquitetura/topologia-declarada.mermaid -f mermaid"
```

Os avisos que a ferramenta imprime durante a geração (`Secret ... undefined`, `StorageClass ... undefined`, `No workload resource matches ...`) são esperados, não indicam erro real: o `InfisicalSecret` cria o `Secret` de verdade em runtime (não existe como YAML estático pra correlacionar), o `local-path` é uma StorageClass provida pelo próprio k3s, e o CloudNativePG/`mariadb-operator` geram o `Pod` que atende ao `Service` a partir do CRD (`Cluster`/`MariaDB`), não de um `Deployment` comum.

## Referências

- [KubeDiagrams](https://github.com/philippemerle/KubeDiagrams): a ferramenta usada aqui, Apache-2.0, gera diagrama de arquitetura (inclusive em mermaid) a partir de manifest estático ou, alternativamente, direto do cluster ao vivo (não é o modo usado nesta página).
- [k8s-to-mermaid](https://github.com/sommerit/k8s-to-mermaid): alternativa mais simples considerada durante a pesquisa e descartada, só interpreta YAML pra um diagrama de classe, sem suporte a cluster ao vivo nem aos formatos adicionais que a KubeDiagrams oferece.
- [The Rendered Manifests Pattern, da Akuity](https://akuity.io/blog/the-rendered-manifests-pattern): explica por que o manifest já hidratado do Argo CD (`helm template` resolvido) nunca fica persistido em lugar nenhum, o motivo de esta página trabalhar a partir do YAML declarado em vez de tentar reconstituir o hidratado.
- [`argocd app manifests`, documentação oficial](https://argo-cd.readthedocs.io/en/latest/user-guide/commands/argocd_app_manifests/): o comando citado acima, pra quem quiser o estado live de verdade.
