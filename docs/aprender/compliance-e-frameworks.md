# Compliance e frameworks

Compliance, no sentido de segurança da informação, é demonstrar formalmente, geralmente pra um auditor externo, que um conjunto de controles de segurança está implementado e funcionando, não só prometido. Não é o mesmo que segurança de verdade (é possível passar numa auditoria e ainda assim ter uma vulnerabilidade real), mas é frequentemente um requisito contratual: empresas maiores, principalmente enterprise e no setor financeiro/saúde, exigem certificação de fornecedor antes de assinar contrato.

## Os três frameworks mais citados, e a diferença real entre eles

SOC 2 é o mais comum entre empresas SaaS americanas: cobre cinco critérios (segurança, disponibilidade, integridade de processamento, confidencialidade, privacidade), com dois tipos de relatório, Type I (retrato num instante) e Type II (efetividade dos controles ao longo de um período, geralmente 6-12 meses, o que a maioria dos clientes enterprise realmente pede). ISO 27001 é o equivalente internacional, um padrão global, com certificação de verdade por um órgão credenciado, e compartilha a maior parte dos mesmos controles que o SOC 2. NIST (o framework de cibersegurança do governo americano, não uma certificação) organiza tudo em cinco funções (Identify, Protect, Detect, Respond, Recover) e não emite certificado, é uma referência voluntária que outros frameworks (incluindo os dois acima) costumam citar como base.

## Certificação de infraestrutura, não só de profissional

SOC 2/ISO 27001/NIST certificam processo de segurança de uma organização. Existe uma categoria vizinha, certificação de infraestrutura física e de conformidade setorial, que certifica a instalação ou o setor, não a pessoa que administra ([Referências](referencias.md) cobre certificação profissional individual, LFCS/CKA/Terraform Associate, categoria diferente desta).

**Tier III**, do Uptime Institute, classifica datacenter por redundância física: um site Tier III tem manutenibilidade concorrente, dá pra fazer manutenção em qualquer componente sem derrubar o serviço, com caminho redundante de energia e refrigeração, mas ainda vulnerável a algum ponto único de falha (Tier IV remove isso também). A certificação tem duas fases: TCDD (Tier Certification of Design Documents), antes de construir, e TCCF (Tier Certification of Constructed Facility), depois de construído, com inspeção no local.

**ISO 27701** estende o modelo do ISO 27001 especificamente pra dado pessoal (PII): um Privacy Information Management System (PIMS), voltado pra quem processa dado de terceiro e precisa demonstrar isso formalmente, adjacente a LGPD/GDPR na prática, mesmo sem ser a lei em si.

**PCI DSS** é obrigatório, não voluntário como os anteriores, pra qualquer organização que armazene, processe ou transmita dado de cartão de pagamento; é imposto pelas próprias bandeiras de cartão (Visa, Mastercard, e as demais), não por um governo.

**ISAE 3402** é o padrão internacional que descreve o mesmo tipo de auditoria que gera um relatório SOC: SOC 1 e ISAE 3402 são considerados equivalentes (controles sobre relatório financeiro), enquanto SOC 2 corresponde ao ISAE 3000, mais genérico, focado nos mesmos cinco critérios já citados acima. A diferença entre os dois pares é jurisdição e formato de relatório, não o que é auditado.

**I-REC** foge completamente do escopo de segurança: certifica origem renovável de energia elétrica, um certificado por MWh gerado, rastreável desde a geração. Aparece cada vez mais em contrato de datacenter/cloud por pressão de sustentabilidade corporativa, não por exigência de segurança da informação.

Essas certificações de infraestrutura ficam aqui como mapa de vocabulário que aparece com frequência em contrato de hosting/cloud maior, mesmo quando nenhuma delas chega a se aplicar de fato numa operação pequena. Vale conhecer mesmo assim porque boa parte do vocabulário de segurança que aparece em ferramenta e processo de mercado (least privilege, trilha de auditoria, separação de ambiente) vem justamente desses frameworks, mesmo em lugares que nunca vão passar por uma auditoria formal.

## Pra ir além

A antítese de compliance formal é segurança sem certificação nenhuma, decisões de segurança guiadas só por julgamento técnico interno, sem checklist externo pra validar. Não é necessariamente pior tecnicamente (um checklist de compliance não garante boa engenharia), mas não dá pra provar pra um terceiro sem confiar na palavra de quem construiu.

Onde aprofundar: o [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework) é gratuito e, diferente de SOC 2/ISO 27001 (que exigem pagar um auditor pra ler o padrão completo em muitos casos), está inteiramente disponível pra qualquer um consultar.
