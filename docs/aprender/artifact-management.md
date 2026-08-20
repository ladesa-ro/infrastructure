# Artifact management

Um repositório de artefato guarda o resultado de um build, um pacote pronto pra ser instalado ou consumido, versionado. É uma categoria mais ampla que container registry (ver [Container registry](container-registry.md)): um artefato pode ser uma imagem de container, mas também um pacote npm, uma biblioteca Maven/Java, um pacote Python (PyPI), um pacote Debian/RPM, ou um arquivo genérico qualquer. Essa categoria só aparece nomeada explicitamente assim no roteiro de DevOps do [roadmap.sh](https://roadmap.sh/devops), nenhuma das listas curadas do GitHub usa esse termo específico, o que sugere que é uma categoria mais reconhecida no vocabulário do dia a dia de quem opera pipeline do que no vocabulário de curadoria de ferramenta open source.

## Artifactory vs. Nexus

Os dois nomes mais citados resolvem o mesmo problema com filosofia de origem diferente: Nexus nasceu como companion do Maven (o gerenciador de dependência do ecossistema Java) e foi ganhando suporte a outros formatos depois, com foco em simplicidade; Artifactory nasceu já pensado pra suportar múltiplos formatos de pacote desde o início (Maven, npm, Docker, Debian, RubyGems, PyPI, e mais de uma dúzia de outros), com mais recurso enterprise (segurança avançada, escala maior), ao custo de mais complexidade pra operar.

## Pra ir além

A antítese de um repositório de artefato dedicado é publicar direto num registry público genérico (npm público, Docker Hub público) sem controle de acesso nem retenção própria, ou pior, sem repositório nenhum, artefato só vive no ambiente onde foi gerado, e some se aquele ambiente for recriado. Times pequenos costumam usar registries públicos gratuitos até o volume ou a necessidade de controle de acesso justificar hospedar o próprio.

Onde aprofundar: o [whitepaper comparativo da JFrog](https://jfrog.com/whitepaper/comparing-artifactory-to-other-binary-repository-managers-8/) é obviamente parcial (é o fabricante do Artifactory comparando a própria ferramenta), mas cobre bem o espectro de formatos suportados por diferentes soluções, útil como mapa mesmo com o viés.
