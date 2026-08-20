# Papéis

Um projeto de infraestrutura pequeno costuma viver na intersecção de vários papéis que, em times maiores, seriam pessoas ou squads diferentes; uma pessoa só cobre pedaços de todos eles. Vale saber nomear cada um, o que cada um prioriza, e onde as prioridades tensionam entre si, mesmo que você nunca venha a se especializar em só um. [roadmap.sh](https://roadmap.sh) tem roteiros visuais e gratuitos, nó por nó, pra cada um dos papéis abaixo, útil como checklist de "o que ainda falta" pra quem já está no meio do caminho.

## SRE (Site Reliability Engineering)

Disciplina criada no Google, formalizada no livro *Site Reliability Engineering*, disponível de graça em [sre.google/books](https://sre.google/books). O foco é confiabilidade tratada como engenharia, não como heroísmo: SLOs (objetivos de nível de serviço), orçamento de erro (error budget), post-mortems sem culpa, automação do trabalho repetitivo ("toil"). Ver também [Site reliability engineering](https://en.wikipedia.org/wiki/Site_reliability_engineering) na Wikipédia.

## DevOps

Um movimento cultural, não um cargo com definição única: encurtar a distância entre quem escreve código e quem opera em produção, geralmente via automação, CI/CD e responsabilidade compartilhada. Ver [DevOps](https://en.wikipedia.org/wiki/DevOps) na Wikipédia. Na prática, muitas empresas usam "DevOps Engineer" como sinônimo de alguém que cuida de CI/CD e infraestrutura, o que gera bastante confusão de nomenclatura no mercado, vale estar ciente disso em entrevista e em vaga.

## Platform Engineering

Mais recente que DevOps (ver [Platform engineering](https://en.wikipedia.org/wiki/Platform_engineering) na Wikipédia): em vez de cada time de produto reinventar sua própria esteira de deploy, um time de plataforma constrói ferramentas e "golden paths" (caminhos prontos, com boas práticas embutidas) que os outros times consomem como produto interno, geralmente chamado de Internal Developer Platform, ver [IDP](idp.md).

## DevSecOps

DevOps com segurança tratada como parte do fluxo, não como um portão no fim (revisão de segurança só antes do deploy). A Wikipédia ainda não tem um artigo próprio pra "DevSecOps" (o termo redireciona pro artigo de [DevOps](https://en.wikipedia.org/wiki/DevOps)), sinal de que é um termo mais recente e ainda em consolidação, mas a prática já é bem estabelecida na indústria: segredo nunca em texto puro (ver [Segredos](../arquitetura/segredos.md)), least privilege (ver o raciocínio dos dois AppProjects em [`argocd-bootstrap`](../arquitetura/roles/argocd-bootstrap.md)), scan de dependência e imagem automatizado, infraestrutura como código revisável em PR. A lista [awesome-devsecops](https://github.com/devsecops/awesome-devsecops) organiza o ferramental típico dessa prática por fase: testing (OWASP ZAP pra varredura de vulnerabilidade em aplicação web, Snyk pra dependência, Checkov, já citado em [Policy as Code](policy-as-code.md), pra infraestrutura), hunting (osquery, pra investigar o estado real de uma máquina como se fosse um banco de dados), e gestão de segredo (Vault, já citado em [SSH](ssh.md) e [Infisical](infisical.md)).

## GitOps

Um princípio mais estreito que os anteriores, específico de como aplicar mudança em Kubernetes (ou qualquer sistema): Git como única fonte da verdade, um agente dentro do sistema que reconcilia continuamente contra o que o Git declara, em vez de alguém rodar comandos manualmente contra produção. [opengitops.dev](https://opengitops.dev) documenta os quatro princípios formais. É o que o Argo CD implementa, ver [Argo CD](argocd.md).

## Onde esses papéis tensionam entre si

Velocidade de entrega (o que Platform Engineering geralmente otimiza) e confiabilidade (o que SRE geralmente otimiza) competem por atenção o tempo todo: automatizar rápido demais sem gate de segurança é o oposto de DevSecOps; travar tudo atrás de aprovação manual é o oposto de DevOps. Reconhecer esse tipo de tensão, e escolher deliberadamente onde ceder, é boa parte do trabalho real desses papéis, mais do que decorar qual ferramenta usar.

Um framework útil pra pensar em como times e plataformas se organizam ao redor desses papéis: *Team Topologies*, de Matthew Skelton e Manuel Pais ([teamtopologies.com](https://teamtopologies.com)), que nomeia o "platform team" como um dos quatro tipos fundamentais de time em engenharia de software.
