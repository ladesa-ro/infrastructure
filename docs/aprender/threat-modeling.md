# Threat modeling

Threat modeling é o exercício de, antes de construir (ou revisando algo já construído), perguntar sistematicamente "o que pode dar errado aqui, de propósito, por causa de alguém mal-intencionado" e listar isso de forma estruturada, em vez de confiar só na intuição de quem revisa. A diferença pra uma revisão de segurança comum é o "sistemático": um framework guia a busca por categoria de ameaça, em vez de depender inteiramente da experiência prévia de quem está revisando.

## Os dois frameworks mais citados

STRIDE, criado pela Microsoft nos anos 90, classifica ameaça em seis categorias (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege), aplicadas componente por componente sobre um diagrama de fluxo de dado do sistema. É técnico e direto, pensado pra quem já está no nível de arquitetura/engenharia. PASTA (Process for Attack Simulation & Threat Analysis) parte de um lugar diferente: risco de negócio primeiro, simulação de ataque realista depois, e junta gente de fora da engenharia (decisão de negócio) no processo, o que STRIDE não faz. Na prática, muitos times usam STRIDE pra identificar ameaça técnica e PASTA (ou algo inspirado nele) pra decidir prioridade de investimento.

## Um exemplo informal do mesmo raciocínio

Separar AppProjects do Argo CD por nível de confiança (ver [Argo CD](argocd.md)) é, na essência, um exercício de threat modeling não formalizado: "o que aconteceria se uma dessas aplicações fosse comprometida" é a mesma pergunta que STRIDE ou PASTA fariam de forma estruturada, só que sem documentar como um dos dois frameworks.

## Pra ir além

A antítese de threat modeling estruturado é revisão de segurança ad-hoc, alguém olha o design e aponta o que parece arriscado, sem checklist nem categoria. Funciona quando quem revisa já tem muita experiência acumulada especificamente no tipo de sistema em questão, mas não transfere esse conhecimento pra quem revisa depois, e tende a deixar categorias inteiras de ameaça de fora sem perceber.

Onde aprofundar: o [Threat Modeling Manifesto](https://www.threatmodelingmanifesto.org), assinado por vários praticantes influentes da área, é curto e resume princípios em vez de prescrever um processo único, bom ponto de partida antes de escolher STRIDE, PASTA, ou outro framework específico.
