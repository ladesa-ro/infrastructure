# Desenvolvimento

## Lint

`.yamllint` e `.ansible-lint` na raiz. `ansible-lint` ignora `argocd/` (não é Ansible). Rodar com `yamllint .` e `ansible-lint` antes de propor mudança.

## Qualidade da documentação

O workflow `quality.yml` roda em todo push e PR que toca `docs/` ou o `README.md`, com dois gates: [lychee](https://lychee.cli.rs) checa todo link externo e interno das páginas (configurado em `.lychee.toml`, aceitando `403`/`429` como respostas válidas de bot-blocking, não link quebrado de verdade), e um segundo job falha se encontrar o caractere de travessão em qualquer arquivo `.md`, a regra de estilo deste repositório (ver [Referências](../aprender/referencias.md) e o restante da seção Aprender pra exemplo do tom esperado). Rodar localmente antes de propor mudança grande:

```bash
docker run --rm -v "$PWD":/docs -w /docs lycheeverse/lychee --config .lychee.toml 'docs/**/*.md' 'README.md'
```

## Commits

Os commits aqui seguem Conventional Commits só no título, `type(scope): subject`. Sem corpo, sem Co-Authored-By.
