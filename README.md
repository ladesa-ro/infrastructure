# infrastructure

Bootstrap declarativo e setup GitOps de um cluster k3s de node único.

```mermaid
flowchart LR
    Ansible[Ansible] --> K3s[k3s + firewalld]
    K3s --> ArgoCD[Argo CD]
    ArgoCD --> Apps[argocd/apps sincronizado continuamente]
```

A documentação completa (checklist, roles do Ansible, segredos, foundation, e o passo a passo do bootstrap) está em **[ladesa-ro.github.io/infrastructure](https://ladesa-ro.github.io/infrastructure/)**, gerada a partir de `docs/` com MkDocs + Material.

```mermaid
flowchart TB
    Docs[docs/] --> Aprender[Aprender: explicação]
    Docs --> Arquitetura[Arquitetura: referência]
    Docs --> Operacao[Operação: tutorial/how-to]
```

Pra editar a documentação localmente:

```bash
docker run --rm -it -p 8000:8000 -v "$PWD":/docs squidfunk/mkdocs-material:9.7.7
```
