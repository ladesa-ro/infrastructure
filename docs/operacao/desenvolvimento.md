# Desenvolvimento

**TLDR**: três modos, três vozes (Aprender impessoal, Arquitetura fatual, Operação imperativa). Linha editorial consolidada de sete style guides externos, com a regra exata de cada um, não só o link. Dois gates de CI da documentação (lychee + travessão), oito checks de código e infraestrutura não bloqueantes rodando numa imagem thin com hermit, e dois gates de segurança bloqueantes (gitleaks + trivy). Commits Conventional Commits só no título.

| Termo | Vá pra |
|---|---|
| Modo e voz por seção | [Estrutura de conteúdo](#estrutura-de-conteudo-modo-e-voz-por-secao) |
| Regras de redação adotadas | [Linha editorial](#linha-editorial) |
| Por que nenhum arquivo de código tem comentário | [Comentários em código](#comentarios-em-codigo) |
| Lint de Ansible/YAML | [Lint](#lint) |
| Gates de CI da documentação | [Qualidade da documentação](#qualidade-da-documentacao) |
| Duplicação, schema, shellcheck e lint dos próprios workflows | [Qualidade de código e infraestrutura](#qualidade-de-codigo-e-infraestrutura) |
| Quando vale testar um role contra um sistema real, não só lint | [Testar um role com Molecule](#testar-um-role-com-molecule) |
| Secret scanning e misconfig de IaC | [Segurança](#seguranca) |
| CODEOWNERS e cooldown do Dependabot | [Donos de código e atualização de dependências](#donos-de-codigo-e-atualizacao-de-dependencias) |
| Convenção de commit | [Commits](#commits) |

## Estrutura de conteúdo: modo e voz por seção

As três trilhas ([Aprender](../aprender/index.md), [Arquitetura](../arquitetura/index.md), [Operação](checklist.md)) seguem [Diátaxis](../aprender/diataxis.md), não são só uma divisão temática. Cada seção corresponde a um modo diferente, e o modo determina tanto o que entra em cada página quanto a voz usada pra escrever ela:

**Aprender é explicação**: terceira pessoa, impessoal ("um Operator é", não "você vai usar um Operator"), sem instrução nenhuma ("faça X"), sem fato específico de um cluster real (ver a regra completa em [Referências](../aprender/referencias.md) e no restante da seção). O teste rápido: se a frase começa a soar como comando ou como "isto aqui, especificamente, faz assim", ela não pertence ao Aprender.

**Arquitetura é referência**: fato sobre este cluster específico, organizado pra consulta rápida, com o porquê de cada decisão registrado ao lado do fato (não uma explicação de conceito geral, isso já está no Aprender, só o raciocínio da escolha feita aqui). Terceira pessoa também, mas fatual, não instrucional.

**Operação é tutorial e how-to guide**: segunda pessoa, voz ativa, modo imperativo ("copie a chave", "rode o comando"), assumindo que quem lê já sabe o básico (isso está no Aprender) e só precisa do passo concreto. `bootstrap.md`, guiado do início ao fim pra quem nunca fez, é mais tutorial. `checklist.md`, pra quem já sabe e só quer confirmar onde parou, é mais how-to guide.

Misturar um modo com outro é o erro mais comum que Diátaxis nomeia: uma página do Aprender que menciona um fato real deste cluster, ou uma página de Operação que para pra explicar teoria em vez de instruir, confunde as duas pessoas que estavam lendo por motivos diferentes.

```mermaid
flowchart TB
    Aprender["Aprender: explicação, 3ª pessoa, sem fato de cluster"]
    Arquitetura["Arquitetura: referência, 3ª pessoa, fato + porquê"]
    Operacao["Operação: tutorial/how-to, 2ª pessoa, imperativo"]
    Aprender -.->|erro comum| Mistura[fato de cluster infiltrado]
    Operacao -.->|erro comum| Teoria[teoria em vez de instrução]
```

## Linha editorial

As regras de redação abaixo vêm de ler sete style guides de documentação técnica, os mais citados do mercado, e ficam aqui consolidadas com a regra exata de cada um, não só o link: se o guia original sair do ar ou mudar de conteúdo, esta seção continua completa por conta própria. Nem toda regra de cada guia se aplica aqui, cada um foi escrito pro contexto de quem o mantém. O que segue é o subconjunto adotado, o rejeitado, e o porquê de cada decisão.

**O que cada guia diz, na fonte:**

- **[Google Developer Documentation Style Guide](https://developers.google.com/style/)**: sentence case em título e heading, capitalizando só a primeira palavra, a primeira depois de dois-pontos, e nome próprio (página `/style/capitalization`). Link deve fazer sentido sem o texto ao redor, nunca "clique aqui" ou "este documento" (`/style/link-text`). Sobre travessão, a posição de Google é a **oposta** da adotada aqui: recomenda travessão sem espaço ao redor pra indicar quebra ou interrupção na frase (`/style/dashes`), o inverso exato da regra do GitLab abaixo.
- **[Microsoft Writing Style Guide](https://learn.microsoft.com/en-us/style-guide/welcome/)**: voz "quente e relaxada, nítida e clara", killer feature é escrever pra quem não é nativo do inglês nem especialista técnico. O guia completo (dashes, bias-free language) fica atrás de páginas específicas de terminologia que este repositório não reproduz aqui por não se aplicarem a prosa em português.
- **[GitHub Docs Style Guide](https://docs.github.com/en/contributing/style-guide-and-content-model/style-guide)**: voz ativa sempre que possível, voz passiva só quando o objeto da ação importa mais que quem age. Sentence case em heading e título. Link introduzido por frase completa ("para mais informação, veja X"), nunca embutido cru no meio da frase, e o mesmo link não deve se repetir mais de uma vez no mesmo artigo.
- **[GitLab Documentation Style Guide](https://docs.gitlab.com/development/documentation/styleguide/)**: proíbe explicitamente o caractere travessão longo e a meia-risca, "use frases separadas, ou vírgula, em vez disso", a regra adotada neste repositório. Proíbe também ponto e vírgula ("use duas frases em vez disso"). Contração é incentivada pro tom conversacional, exceto com nome próprio, pra enfatizar negativa, em documentação de referência, e em mensagem de erro. Proíbe "saiba mais sobre" e "veja a página X". Exige o formato `"para mais informação, veja [texto descritivo]"`. Sentence case em título e cabeçalho de tabela. Proíbe autorreferência de preenchimento ("esta página mostra"), pede ir direto ao ponto. Proíbe palavra que sugere facilidade ("simplesmente", "facilmente") e alegação de marketing não verificável.
- **[Red Hat Supplementary Style Guide](https://redhat-documentation.github.io/supplementary-style-guide/)**: título de procedimento no imperativo, nunca gerúndio ("Install the CLI", não "Installing the CLI"). Um comando por bloco de código por passo, saída do comando em bloco separado. Placeholder em `<nome_do_valor>`, itálico, minúsculo, `_` separando palavra composta. Sentence case em heading, alvo de 3 a 11 palavras por heading pra facilitar busca.
- **[MDN Writing Guidelines](https://developer.mozilla.org/en-US/docs/MDN/Writing_guidelines)**: tom casual, as "três Cs" (clear, concise, consistent). Contração incentivada pro tom casual. Pronome de gênero neutro, "they/them" no singular em vez de "he/she". Sentence case em heading, só primeira palavra e nome próprio capitalizados.
- **[Docker Docs Style Guide](https://github.com/docker/docs/blob/main/STYLE.md)**: vírgula de Oxford em lista. Proíbe ponto e vírgula ("escreva duas frases"). Permite travessão, com espaço em volta (posição intermediária entre Google, sem espaço, e GitLab, que proíbe). Heading de até oito palavras, sem artigo inicial, ação primeiro. Proíbe palavra de facilitação ("simplesmente", "só", "facilmente") e superlativo ("poderoso", "robusto", "revolucionário"), e meta-comentário ("vale notar que"). "Você", nunca "nós". Evita "atualmente"/"neste momento" (data a prosa).

```mermaid
mindmap
  root((Linha editorial))
    Google
      sentence case
      link autoexplicativo
      travessão permitido, sem espaço
    Microsoft
      voz quente e relaxada
      pra não nativo do inglês
    GitHub
      voz ativa
      link introduzido por frase
      sem link repetido
    GitLab
      travessão proibido
      ponto e vírgula proibido
      sem autorreferência de preenchimento
      sem palavra de facilidade
    Red Hat
      título no imperativo
      um comando por bloco
      placeholder em underscore
    MDN
      tom casual, três Cs
      pronome neutro they them
    Docker
      vírgula de Oxford
      travessão com espaço
      sem superlativo
```

**Adotado:**

- Título em sentence case, nunca Title Case: convenção idêntica em Google, GitHub, GitLab, Red Hat, MDN e Docker (seis dos sete concordam), já natural em português, onde Title Case nem é gramatical.
- Sem travessão em texto corrido, regra do GitLab, apesar de Google recomendar o oposto e Docker permitir com espaço: poluição visual sem ganho de clareza foi o critério decisivo, não o consenso entre os guias (que não existe aqui).
- Sem ponto e vírgula, regra de GitLab e Docker: duas frases separadas em vez de uma frase composta. Revisado em 2026-08-20, depois de ter ficado do lado de "considerado e descartado" logo abaixo, quando a legibilidade de frase curta passou a valer mais que a densidade de prosa já estabelecida.
- Sem abuso de crase (`` ` ``) marcando termo como código: cada nome de arquivo, comando ou identificador continua entre crases, mas frase que vira uma sequência de termos crasados um atrás do outro deve ser reescrita, prosa não é lista de código.
- Texto de link sempre descritivo (`ver [Argo CD](argocd.md)`), nunca genérico (`clique aqui`), regra idêntica em Google, GitHub e GitLab, os três mais explícitos nisso.
- Sem linguagem de marketing nem superlativo não verificável ("a melhor ferramenta", "simplesmente resolve tudo"), regra combinada de GitLab e Docker: toda comparação entre ferramentas nesta doc vem acompanhada do trade-off real, não só da vantagem.
- Sem autorreferência de preenchimento ("esta página explica", "neste guia vamos ver"), regra explícita do GitLab. A frase de modo Diátaxis que abre cada seção (ver acima) é a exceção deliberada: não é preenchimento, é sinalização estrutural do que o leitor está prestes a ler.
- Título de procedimento no imperativo, não no gerúndio ("Instalar as dependências", não "Instalando as dependências"), regra do Red Hat, já seguida em `bootstrap.md`.
- Um comando por bloco de código quando o passo precisa ser copiado isoladamente, regra do Red Hat, já seguida em `bootstrap.md`.
- Valor que quem lê precisa substituir sempre em `<algo>`, nunca em texto solto sem marcação, mesmo princípio do placeholder do Red Hat, adaptado sem itálico forçado (Markdown puro já diferencia `` `código` `` visualmente).

**Considerado e descartado:**

- Proibição de ponto e vírgula, regra explícita de GitLab e Docker. Rejeitada na primeira versão desta seção, com o argumento de que o ponto e vírgula une duas orações relacionadas em português sem quebrar o parágrafo em frases curtas demais. Depois adotada mesmo assim (ver "Sem ponto e vírgula" em Adotado, acima), decisão editorial explícita do mantenedor, não um argumento técnico que reverteu o anterior.
- Uso de contração como sinal de tom amigável, regra de GitLab, MDN e Docker. Não se aplica: contração é um mecanismo do inglês (`don't`, `it's`) sem equivalente direto em português.
- Travessão permitido com espaço (posição do Docker) ou sem espaço (posição do Google), as duas descartadas em favor da proibição total do GitLab, único dos sete a proibir por completo.
- Vírgula de Oxford, regra do Docker: não existe em português (a língua não tem essa ambiguidade de lista que a vírgula de Oxford resolve em inglês).
- Heading limitado a 3-11 palavras (Red Hat) ou 8 palavras (Docker): não adotado como regra rígida, títulos desta documentação priorizam ser descritivos sobre caber num limite de palavra, mesmo quando passam de oito.

## Comentários em código

**TLDR**: zero comentário em qualquer arquivo de código deste repositório, `.yaml`, `.hcl`, `.yml` de workflow, shell script, task de Ansible, unit de systemd, tudo. Contexto que justificaria um comentário vai pra um `.md`, nunca inline.

Regra do mantenedor, não de nenhum dos sete style guides acima (que são só sobre prosa em Markdown, não sobre código): nenhum arquivo de código deste repositório leva comentário explicativo, nem `#` em YAML/HCL/shell, nem justificativa de decisão de versão, nem aviso de risco operacional embutido na task. Isso vale pra todo o inventário de formatos usado aqui: `.yml`/`.yaml` (Ansible, Argo CD, GitHub Actions), `.hcl` (Hermit, Docker Bake), `Containerfile`, shell script em `scripts/`.

Duas exceções, ambas mecânicas, não narrativas: a diretiva de supressão de linter que o próprio ansible-lint exige inline (`# noqa: regra`, quando funciona, ver [Qualidade de código e infraestrutura](#qualidade-de-codigo-e-infraestrutura) pro caso em que não funciona), e o cabeçalho de licença de arquivo vendorizado de terceiro (o `cert-manager`/`cnpg` trazem o próprio comentário de copyright, que não é deste repositório pra remover). Fora essas duas, todo contexto que pareceria justificar um comentário (por que essa versão está pinada, por que essa exclusão existe, o raciocínio por trás de uma decisão) vai pra este mesmo arquivo, pra `estrutura.md`, ou pra outra página de Arquitetura/Operação, nunca inline no código.

```mermaid
flowchart LR
    Contexto[contexto pareceria justificar um comentário] --> Onde{onde documentar?}
    Onde -->|SEMPRE| Doc[.md em Arquitetura ou Operação]
    Onde -.->|NUNCA| Inline[comentário inline no código]
```

## Lint

**TLDR**: `.yamllint` cobre sintaxe e estilo de todo YAML do repositório, `.ansible-lint` cobre convenção específica de Ansible por cima disso, os dois rodam automaticamente desde que `codigo-e-infra` existe.

```mermaid
mindmap
  root((Lint))
    yamllint
      sintaxe YAML
      indentação
      document-start
      truthy
    ansible-lint
      convenção Ansible
      nome de variável com prefixo do role
      nome de handler e play
      role-name
```

`.yamllint` e `.ansible-lint` na raiz. `ansible-lint` ignora `argocd/` (não é Ansible). Desde que o job `codigo-e-infra` de `quality.yml` existe, os dois rodam automaticamente em todo push e PR que toca `ansible/`, `argocd/`, `scripts/` ou os próprios workflows, não bloqueante ainda (ver [Qualidade de código e infraestrutura](#qualidade-de-codigo-e-infraestrutura)). Rodar local antes de propor mudança grande, com a mesma imagem usada em CI:

```bash
docker buildx bake --file tools/quality/docker-bake.hcl --load
docker run --rm -v "$PWD":/repo -w /repo infra-quality/python-lint:local uvx yamllint .
docker run --rm -v "$PWD":/repo -w /repo infra-quality/python-lint:local uvx --from ansible-lint ansible-lint
```

O repositório monta em `/repo`, não em `/workspace`: `/workspace` é onde a própria imagem guarda o `.config/hermit/` já instalado, montar o checkout ali por cima apagaria os binários que o hermit materializou durante o build.

## Qualidade da documentação

**TLDR**: dois gates bloqueantes só pra `docs/`/`README.md`, lychee (link quebrado) e um grep de travessão (estilo), os dois rodando desde bem antes deste registro existir.

O workflow `quality.yml` roda em todo push e PR que toca `docs/` ou o `README.md`, com dois gates: [lychee](https://lychee.cli.rs), um link checker assíncrono escrito em Rust, resolve cada link markdown, HTML e `mailto:` da página (link interno é resolvido contra o arquivo real no repositório, não só sintaxe), faz a requisição HTTP de verdade contra link externo, e cacheia o resultado entre execuções (`cache = true`, `max_cache_age = "1d"` em `.lychee.toml`) pra não martelar o mesmo host a cada push. Aceita `403`/`429` como resposta válida de bot-blocking, não link quebrado de verdade. Um segundo job falha se encontrar o caractere de travessão em qualquer arquivo `.md`, a regra de estilo deste repositório (ver [Referências](../aprender/referencias.md) e o restante da seção Aprender pra exemplo do tom esperado). O princípio por trás dos dois gates é o mesmo que a [documentação da Stripe](https://docs.stripe.com), citada como referência de qualidade em documentação de API, aplica: link quebrado ou inconsistência de estilo falha o build, não aparece publicado pra quem lê. Rodar localmente antes de propor mudança grande:

```mermaid
flowchart LR
    Push[push ou PR toca docs/] --> Lychee[gate: lychee, links quebrados]
    Push --> Travessao[gate: grep de travessão]
    Lychee --> Falha1{falhou?}
    Travessao --> Falha2{falhou?}
    Falha1 -->|sim| Bloqueia[build falha, não publica]
    Falha2 -->|sim| Bloqueia
```

```bash
docker run --rm -v "$PWD":/docs -w /docs lycheeverse/lychee --config .lychee.toml 'docs/**/*.md' 'README.md'
```

## Qualidade de código e infraestrutura

**TLDR**: oito checks não bloqueantes (yamllint, ansible-lint, jscpd, kubeconform, shellcheck, actionlint, zizmor, cspell), cada um rodando na sua própria imagem, todas nascidas de um stage `base` compartilhado via `docker buildx bake`.

O job `codigo-e-infra` de `quality.yml` roda em todo push e PR que toca `docs/`, `ansible/`, `argocd/`, `scripts/`, `.ansible-lint`, `.yamllint`, `.cspell.config.yaml`, `tools/quality/` ou `.github/workflows/`. Todos os seus oito checks são não bloqueantes por enquanto (`continue-on-error: true`), até o time revisar o baseline de cada um e decidir quando promover a bloqueante:

- `yamllint` e `ansible-lint`: os dois lints já descritos em [Lint](#lint).
- `jscpd`: duplicação de bloco entre roles do Ansible e manifests do `argocd/`, mesmo padrão do task `infra-duplication` do portfólio (formato yaml, limiar de 65 tokens ou 5 linhas). Por baixo, tokeniza cada arquivo e usa Rabin-Karp (um algoritmo de hash de janela deslizante, o mesmo usado por ferramenta de detecção de plágio) pra achar trecho tokenizado igual em lugares diferentes, rápido o suficiente pra rodar em todo push mesmo num repositório grande. O manifesto vendorizado do cert-manager já passa hoje de 60% de duplicação sozinho, por isso este check começa não bloqueante.
- `kubeconform`: valida cada manifesto de `argocd/**/*.yaml` contra o schema OpenAPI oficial do Kubernetes (convertido pra JSON Schema, servido por um fork do `kubernetes-json-schema` mantido atualizado pra toda versão recente do Kubernetes). `-ignore-missing-schemas` pula recurso sem schema conhecido (CRD de terceiro, por exemplo) em vez de falhar. `-strict` rejeita propriedade extra não declarada no schema ou chave duplicada. Como não há Helm chart aqui (diferente do `bondspot-server`, que renderiza um chart antes de validar), roda direto contra o YAML cru.
- `shellcheck`: lint de `scripts/*.sh`. Cobre desde sintaxe incompatível com o shell declarado no shebang até bug real de quoting (variável sem aspas que quebra em espaço, glob que expande sem querer) e lógica inalcançável, cada categoria de aviso identificada por um código `SC` seguido de número (`SC2086`, por exemplo).
- `actionlint` e `zizmor`: lint e análise de segurança dos próprios arquivos em `.github/workflows/`. `actionlint` faz checagem de tipo de verdade nas expressões `${{ }}` (acessar propriedade que não existe, comparar tipo incompatível), confere que os `with:`/`outputs:` batem com o que a action de terceiro realmente declara, e roda `shellcheck`/`pyflakes` dentro de todo bloco `run:`. `zizmor` foca no lado de segurança: ação sem pin por hash (`unpinned-uses`, o achado que motivou a política de pin deste repositório), `checkout` sem `persist-credentials: false` que deixa credencial de push disponível pra um step seguinte não confiável (`artipacked`), e permissão declarada mais ampla que o job precisa (`excessive-permissions`).
- `cspell`: ortografia de `docs/`, `README.md` e dos nomes de step dos workflows. Entende identificador de código (separa `camelCase`/`snake_case` em palavras antes de checar cada uma), o que evita falso positivo em nome de variável mas também é o motivo de identificador sem acento em diagrama mermaid (`Seguranca`, `Operacao`) precisar entrar no dicionário próprio de `tools/quality/cspell-dictionary.txt`, junto com dicionário pt-BR e nome de ferramenta/sigla.

Os oito não rodam numa imagem só: `tools/quality/Containerfile` é multi-stage, com um stage `base` (bootstrap mínimo de apt, mais `.config/hermit/` copiado) e um stage final por ferramenta (`actionlint`, `shellcheck`, `zizmor`, `python-lint`, `kubeconform`, `node-tools`), cada um só com o `hermit install` da sua própria ferramenta. `tools/quality/docker-bake.hcl` declara um target por stage, e um `docker buildx bake` só builda as seis imagens em paralelo, reaproveitando a camada `base` entre todas (o bootstrap de apt não repete por ferramenta, só o download de cada binário). O job `codigo-e-infra` builda tudo de uma vez com `docker/bake-action` e depois roda cada check contra a imagem certa: `python-lint` pro `uvx`/`yamllint`/`ansible-lint`, `node-tools` pro `jscpd`/`cspell`, uma imagem dedicada pra `kubeconform`, `shellcheck`, `actionlint` e `zizmor`.

Os seis stages finais compartilham o mesmo `base` (mesma relação de um `FROM base AS <stage>` no Dockerfile), o que um diagrama de classe representa melhor que um flowchart, porque a relação entre eles é literalmente herança de imagem, não sequência de passo:

```mermaid
classDiagram
    class base {
        +aptBootstrap minimo
        +hermitConfig copiado
    }
    class actionlint {
        +hermitInstall actionlint_1_7_12
    }
    class shellcheck {
        +hermitInstall shellcheck_0_11_0
    }
    class zizmor {
        +hermitInstall zizmor_1_29_0
    }
    class pythonLint["python-lint"] {
        +hermitInstall uv_0_12_1
    }
    class kubeconform {
        +hermitInstall kubeconform_0_8_0
    }
    class nodeTools["node-tools"] {
        +hermitInstall node_24_18_0
        +npmInstall jscpd_cspell
    }
    base <|-- actionlint
    base <|-- shellcheck
    base <|-- zizmor
    base <|-- pythonLint
    base <|-- kubeconform
    base <|-- nodeTools
```

`actionlint`, `shellcheck`, `zizmor`, `uv` e `kubeconform` vêm do [Hermit](https://cashapp.github.io/hermit/) em versão pinada (pacotes `.hcl` em `.config/hermit/hermit-packages/`, os três primeiros copiados do portfólio, `kubeconform.hcl` e `node.hcl` escritos no mesmo formato). `uv`/`uvx` por sua vez materializa `yamllint` e `ansible-lint` como ferramentas Python isoladas. `jscpd` e `cspell` são os dois únicos que só existem no registro do npm, sem binário solto pra virar pacote hermit: por isso o stage `node-tools` hermitiza só o `node`, e usa o `npm` dele pra instalar os dois. Cada `hermit install` roda dentro de `script -qefc "..." /dev/null`: sem isso, o prompt de confirmação de plataforma do próprio hermit trava o build com `sync /dev/stdout: invalid argument` num `RUN` sem TTY.

```mermaid
flowchart LR
    Push[push ou PR toca docs, ansible, argocd, scripts, workflows] --> Bake[docker buildx bake: base compartilhada + 6 imagens]
    Bake --> YamlLint[python-lint: yamllint]
    Bake --> AnsibleLint[python-lint: ansible-lint]
    Bake --> Jscpd[node-tools: jscpd]
    Bake --> Cspell[node-tools: cspell]
    Bake --> Kubeconform[kubeconform: schema]
    Bake --> Shellcheck[shellcheck: scripts]
    Bake --> Actionlint[actionlint: sintaxe dos workflows]
    Bake --> Zizmor[zizmor: segurança dos workflows]
```

Toda ação de terceiro nos três workflows (`quality.yml`, `security.yml`, `docs.yml`) é referenciada por hash de commit, nunca por tag (`@v4`), e o hash escolhido é sempre de um release com pelo menos 7 dias publicado, não o mais recente disponível: um release comprometido costuma ser detectado e removido nesse intervalo, então esperar a janela reduz a chance de fixar exatamente a versão maliciosa. `zizmor` é quem verifica a primeira parte (hash, não tag). A janela de 7 dias é checada manualmente contra a data de publicação de cada release antes de trocar o pin.

Todo check novo deste job nasce não bloqueante e segue o mesmo ciclo de vida antes de virar gate de verdade:

```mermaid
stateDiagram-v2
    [*] --> NaoBloqueante: check novo adicionado
    NaoBloqueante --> Revisado: baseline de achado analisado
    Revisado --> Bloqueante: achado real corrigido ou config ajustada (warn_list, ignore, exclude)
    Revisado --> NaoBloqueante: achado é falso positivo, documentado como limitação conhecida
    Bloqueante --> [*]
```

## Testar um role com Molecule

`yamllint` e `ansible-lint` (ver [Lint](#lint)) checam sintaxe e convenção, não se o role de fato converge um sistema real pro estado esperado. Pra isso existe [Molecule](../aprender/ansible.md#molecule): cria um alvo efêmero (normalmente um container Docker), roda o role de verdade contra ele, confere idempotência rodando de novo, e destrói o alvo no final. Nenhum scenario Molecule roda hoje em CI neste repositório, é uma ferramenta de uso local, sob demanda, não outro gate automático.

Nem todo role justifica o peso de manter um scenario: pra role simples, que só copia arquivo ou garante pacote instalado, `--check` (ver [Modo `--check`](../aprender/ansible.md#modo-check)) mais os lints já cobrem a maior parte do risco real. Vale escrever um scenario Molecule quando o role gerencia algo que só se comprova rodando de verdade (um serviço systemd, uma regra de rede) e o custo de um erro em produção é alto.

Mesmo assim, "vale a pena" não é garantia de que o teste vai ser confiável: um scenario Molecule foi tentado pro role [`firewalld`](../arquitetura/roles/firewalld.md), a mudança de maior risco deste bootstrap, e descartado depois de expor uma race real de D-Bus/polkit dentro do container aninhado (documentada pelo [próprio Ansible](https://github.com/ansible/ansible/issues/36483) e pelo [systemd](https://github.com/systemd/systemd/issues/13955), ver a seção completa em [Molecule](../aprender/ansible.md#molecule)) que tornava o tempo de execução do teste inconsistente. A correção da race em si (esperar o firewalld ficar de fato pronto antes do primeiro comando real) foi mantida no role, só o scenario de teste foi abandonado. Ver [Por que este role não tem um scenario Molecule](../arquitetura/roles/firewalld.md#por-que-este-role-nao-tem-um-scenario-molecule) pro raciocínio completo. Esse é o exemplo concreto do trade-off: nem toda mudança de alto risco se beneficia de automação de teste, às vezes a verificação manual supervisionada (já em uso pro `firewalld`, ver [passo 8 do bootstrap](bootstrap.md#8-ligar-o-firewalld)) é a opção mais confiável disponível.

```mermaid
flowchart TD
    Role{role simples ou de alto risco?} -->|simples| Lint[--check + lint já cobre]
    Role -->|alto risco| Confiavel{Docker reproduz o ambiente real de forma confiável?}
    Confiavel -->|sim| Scenario[vale o scenario Molecule]
    Confiavel -->|não, ex.: D-Bus/polkit| Manual[verificação manual supervisionada]
```

## Segurança

**TLDR**: `security.yml` roda gitleaks (segredo commitado, bloqueante) e trivy (misconfig de IaC, hoje consultivo) em três gatilhos diferentes (push, PR, e um cron semanal de rede de segurança).

```mermaid
timeline
    title Quando security.yml roda
    Push em main : roda gitleaks + trivy
    Todo PR : roda gitleaks + trivy
    Segunda 06:00 UTC : roda gitleaks + trivy, sem mudança de código
```

`security.yml` roda em todo push pra `main`, todo PR, e semanalmente às segundas-feiras às 06:00 UTC como rede de segurança, sem filtro de `paths`: segredo vazado ou misconfig importa mesmo sem mudança de código naquele push.

- [Gitleaks](https://github.com/gitleaks/gitleaks) varre o histórico inteiro de commit (equivalente a `git log -p`, não só o estado atual do checkout) atrás de credencial commitada, usando um conjunto de regras regex prontas pra formato conhecido de segredo (chave da AWS, chave privada PEM, padrão genérico de API key) mais detecção por entropia pra string que parece segredo mesmo sem bater um padrão nomeado. Bloqueante, mesmo padrão de segurança usado no `bondspot-server` desde o início do projeto (mesmo em fase MVP, quando outros checks foram desligados por velocidade de iteração). Roda direto via `docker run zricethezav/gitleaks`, não pelo `gitleaks/gitleaks-action` (o wrapper oficial da Action passou a exigir licença paga pra conta de organização a partir da v2, a CLI `gitleaks` em si continua livre).
- [Trivy](https://trivy.dev) roda com `scan-type: fs` e `scanners: misconfig`, avaliando Dockerfile, manifesto Kubernetes, Terraform e CloudFormation (os quatro formatos que o scanner de misconfig do Trivy entende) contra um conjunto de políticas prontas (porta exposta sem necessidade, container sem limite de recurso, permissão excessiva), severidade `HIGH` ou `CRITICAL` pra cima. Consultivo por enquanto (`continue-on-error: true`): os achados reais que já apareceram (`securityContext` ausente nas Deployments de `dados`/`rabbitmq`/`redis`, ver [débito técnico conhecido](../arquitetura/foundation.md#debito-tecnico-conhecido-securitycontext-ausente)) exigem uma varredura dedicada, UID por UID, pra não quebrar nenhum serviço de produção antes de virar bloqueante. `skip-dirs` exclui `argocd/foundation/cert-manager` e `argocd/foundation/cnpg`, os dois manifestos vendorizados sem modificação: o RBAC amplo que o Trivy reclama neles é exigido pelo próprio operador pra funcionar, não é código deste repositório pra ajustar, o mesmo tratamento que `jscpd`/`yamllint` já dão a esses dois caminhos.

```mermaid
sequenceDiagram
    participant Gatilho as push, PR, ou cron
    participant Secrets as job secrets
    participant Misconfig as job misconfig

    Gatilho->>Secrets: checkout com histórico completo
    Secrets->>Secrets: gitleaks varre todo o git log
    Gatilho->>Misconfig: checkout raso
    Misconfig->>Misconfig: trivy varre Dockerfile, K8s, Terraform, CloudFormation (menos cert-manager e cnpg)
    Secrets-->>Gatilho: falha o build se achar segredo
    Misconfig-->>Gatilho: reporta misconfig HIGH/CRITICAL, não bloqueia o build ainda
```

Ver [Vulnerability scanning](../aprender/vulnerability-scanning.md) pra entender secret scanning e SCA/misconfig como categoria, sem depender deste cluster específico.

## Donos de código e atualização de dependências

**TLDR**: `CODEOWNERS` marca `@ladesa-ro/security`/`@ladesa-ro/devops` em todo caminho sensível a CI e infraestrutura, `dependabot.yml` atualiza os três tipos de dependência reais deste repositório, sempre com 7 dias de espera antes de propor a versão nova.

```mermaid
mindmap
  root((CODEOWNERS))
    security
      .github
      ansible
      argocd
      tools/quality
      .config/hermit
      scripts *.sh
      configs de lint
    devops
      ansible
      argocd
```

`CODEOWNERS` na raiz segue o mesmo padrão do `management-service`: `@ladesa-ro/security` em todo caminho sensível a CI e segurança (`.github/`, `ansible/`, `argocd/`, `tools/quality/`, `.config/hermit/`, os scripts `.sh`, os arquivos de config dos linters), `@ladesa-ro/devops` também nos caminhos de infraestrutura de fato (`ansible/`, `argocd/`).

`.github/dependabot.yml` cobre as três coisas que este repositório de fato declara como dependência: as próprias actions dos workflows (`github-actions`), a imagem base do `tools/quality/Containerfile` (`docker`), e os pacotes Python do `requirements-docs.txt` que buildam a doc (`pip`). Todos os três usam `cooldown: default-days: 7`, a mesma janela de 7 dias usada pro pin manual de hash das actions (ver [Qualidade de código e infraestrutura](#qualidade-de-codigo-e-infraestrutura)): o Dependabot não abre PR pra uma versão nova até ela ter pelo menos 7 dias publicada, pelo mesmo motivo, dar tempo de um release comprometido ser detectado antes de chegar aqui.

```mermaid
flowchart LR
    Release[release novo de uma dependência] --> Espera{7 dias desde a publicação?}
    Espera -->|não| Aguarda[dependabot aguarda, não abre PR ainda]
    Espera -->|sim| PR[dependabot abre PR de atualização]
    Aguarda -.->|passa o tempo| Espera
```

## Commits

Os commits aqui seguem [Conventional Commits](../aprender/git.md#conventional-commits) só no título, `type(scope): subject`. Sem corpo, sem Co-Authored-By.
