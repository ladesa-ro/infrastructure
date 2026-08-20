# infrastructure

Bootstrap declarativo e setup GitOps de um cluster k3s de node único. Os dados de conexão não ficam neste repositório; quem administra usa um alias próprio já configurado no `~/.ssh/config`.

O Ansible instala o k3s, configura o firewalld, clona os segredos de bootstrap do [`infrastructure-vault`](https://github.com/ladesa-ro/infrastructure-vault), instala o release do Argo CD, e aplica um único arquivo, o `root.yaml`. O Argo CD sincroniza tudo que descobre a partir dali, em `argocd/apps`. Nenhum segredo, em texto puro ou cifrado, fica neste repositório: todos vivem em `infrastructure-vault`.

Esta documentação está dividida em três trilhas, que se referenciam entre si mas podem ser lidas de forma independente:

## [Aprender](aprender/index.md)

SSH, git, Ansible, k3s, firewalld, Argo CD: o que cada peça é e faz, de forma geral, sem depender deste cluster específico. Comece aqui se algum desses nomes não é familiar.

## [Arquitetura](arquitetura/index.md)

Como este cluster específico usa cada peça: a estrutura do repositório, o que cada role do Ansible faz e por quê, onde os segredos vivem, o que já roda hoje em produção, e os diagramas de fluxo do sistema inteiro.

## [Operação](operacao/checklist.md)

O roteiro executável: checklist, o passo a passo do bootstrap na VM, os scripts de manutenção, o que fica fora do git, e as convenções de desenvolvimento (lint, commits).
