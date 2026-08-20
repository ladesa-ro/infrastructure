# Container registry

Um container registry guarda imagem de container versionada por tag (ver [CI, CD e CD](ci-cd.md)), pronta pra ser puxada por qualquer node que precise rodar aquele container. É uma peça que fica entre "build da imagem" e "deploy": um manifesto Kubernetes ou um chart Helm sempre referencia uma tag de imagem que já existe num registry, nunca uma imagem construída localmente.

## As opções mais citadas

Docker Hub é o registry público mais conhecido, gratuito com limite de taxa pra puxar imagem, é onde a maioria das imagens base (`postgres`, `redis`, `nginx`) vive. Harbor, projeto graduado da CNCF, é a opção self-hosted mais citada quando um time precisa de controle próprio: soma scanning de vulnerabilidade (integra com Trivy, ver [Vulnerability scanning](vulnerability-scanning.md)), RBAC, assinatura de imagem, e replicação entre registries. Quay, da Red Hat, é comparável a Harbor em recurso, com plano hospedado gratuito pra repositório público. GitHub Container Registry (GHCR) é o mais simples de adotar pra quem já vive no GitHub: GitHub Actions builda e publica sem precisar configurar credencial nenhuma, usando o próprio token da Action.

## Pra ir além

A antítese de um registry dedicado é nenhum registry (rodar sempre a partir de build local, sem nunca publicar) ou depender só do registry público gratuito de terceiro, sem nenhum controle próprio sobre retenção, disponibilidade, ou scanning. Funciona bem pra projeto pequeno até o dia em que o registry público tiver uma indisponibilidade (já aconteceu, mais de uma vez, com registries grandes) e travar todo deploy que dependia dele.

Onde aprofundar: o [repositório oficial do Harbor](https://github.com/goharbor/harbor) tem a documentação de arquitetura linkada na descrição, útil pra entender os componentes internos (registry, notary, scanner) antes de decidir hospedar um.
