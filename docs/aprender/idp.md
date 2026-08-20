# Internal Developer Platform

Uma Internal Developer Platform (IDP) é a materialização concreta do que a disciplina de Platform Engineering constrói (ver [Papéis](papeis.md)): uma superfície única, geralmente com uma interface própria, onde quem desenvolve consegue ver o que existe (quais serviços, quem é dono, o que está rodando onde), e pedir coisas novas (um banco, um ambiente, um namespace) sem precisar abrir um YAML de infraestrutura nem entender [Ansible](ansible.md) ou [Argo CD](argocd.md). A lista [awesome-devops](https://github.com/wmariuss/awesome-devops) tem uma categoria dedicada a isso, "Internal Developer Platforms", separada de "Applications Platforms" (Kubernetes em si).

## Duas abordagens bem diferentes dentro da mesma categoria

Backstage, criado pelo Spotify e hoje projeto da CNCF, é um framework pra construir um **portal**: um catálogo central de serviços, documentação, e templates, forte em ambiente grande e customizado, mas que dá trabalho real de configurar e manter. Port é a versão SaaS da mesma ideia, mais rápida de colocar no ar, com menos customização. Kratix segue uma filosofia diferente: em vez de portal, é uma **camada de API** que padroniza como infraestrutura é criada e entregue a quem desenvolve, mais próxima de Crossplane (ver [IaC e provisionamento](iac-provisionamento.md)) do que de um catálogo visual. Muitos setups combinam as duas coisas: um portal (Backstage ou Port) por cima de uma camada de orquestração (Kratix ou Crossplane) por baixo.

## Pra ir além

A antítese de uma IDP formal é o que a maioria das organizações pequenas faz sem perceber que é uma antítese: documentação solta (READMEs, wikis) e convenção não imposta por ferramenta nenhuma, só por hábito e revisão de código. Funciona até o hábito quebrar, alguém não seguir a convenção, e não ter nada que force ou avise sobre isso, diferente de uma IDP que formaliza o caminho padrão como o único caminho fácil.

Onde aprofundar: [backstage.io](https://backstage.io/docs/overview/what-is-backstage) explica o modelo de catálogo de software (software catalog) que virou vocabulário comum mesmo em quem não usa o Backstage especificamente.
