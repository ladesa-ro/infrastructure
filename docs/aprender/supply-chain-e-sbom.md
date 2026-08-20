# Supply chain e SBOM

Supply chain security, no contexto de software, é a preocupação com tudo que entra numa aplicação sem ter sido escrito por quem a mantém: dependência de terceiro, imagem base de container, ferramenta usada no build. O incidente que mais popularizou essa preocupação foi o Log4Shell (2021), uma vulnerabilidade crítica numa biblioteca de log usada, direta ou indiretamente, por uma fração enorme do software Java do planeta; times inteiros passaram dias só tentando descobrir se usavam a biblioteca vulnerável, porque ninguém tinha um inventário confiável de dependência.

## SBOM: o inventário que resolveria isso

Um SBOM (Software Bill of Materials) é exatamente esse inventário, gerado automaticamente a partir do build: toda dependência, direta e transitiva, com versão exata. Com um SBOM em mãos, responder "eu uso a biblioteca X, versão vulnerável?" é uma busca, não uma investigação. Os dois formatos dominantes hoje resolvem o mesmo problema com ênfase diferente: SPDX, um padrão da Linux Foundation e ISO, nasceu focado em compliance de licença; CycloneDX, da OWASP, nasceu mais focado em segurança, e inclui VEX (Vulnerability Exploitability eXchange), um jeito de declarar que uma vulnerabilidade conhecida numa dependência não é explorável no seu caso específico, informação que reduz ruído de alerta real.

## Quando compensa automatizar

Fixar versão de dependência manualmente, uma por uma, com checksum, funciona enquanto o número delas é pequeno o bastante pra ser conferido por uma pessoa (ver [Ansible](ansible.md) sobre fixar versão de binário por checksum). SBOM começa a compensar o esforço de automatizar a partir do momento em que o número de dependências transitivas cresce o bastante pra checagem manual parar de ser confiável, o caso típico de uma aplicação com centenas de pacotes npm/pip, não de um punhado de binários pinados manualmente.

## Pra ir além

Trivy e Syft são as ferramentas mais citadas pra gerar SBOM a partir de uma imagem de container já pronta, sem precisar instrumentar o processo de build. Ferramentas de scanning (ver [Vulnerability scanning](vulnerability-scanning.md)) normalmente consomem o SBOM gerado, não o contrário, SBOM é o inventário, scanning é a checagem contra base de vulnerabilidade conhecida.

A antítese de SBOM automatizado é não ter inventário nenhum, ou manter um manualmente, uma planilha atualizada por alguém sempre que lembra. Funciona enquanto o número de dependência é pequeno o bastante pra caber na cabeça de uma pessoa, mas quebra silenciosamente assim que esse número cresce, porque nada avisa quando o inventário manual ficou desatualizado.

Onde aprofundar: o [guia da CycloneDX](https://cyclonedx.org/capabilities/sbom/) explica a especificação com exemplo prático de arquivo gerado, útil pra ver o formato de verdade, não só a teoria.
