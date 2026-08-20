# Mensageria e streaming

Um message broker desacopla quem produz um evento (uma aplicação que precisa avisar "isto aconteceu") de quem consome ele, sem os dois precisarem estar disponíveis ao mesmo tempo nem se conhecerem diretamente. Diferente de uma chamada HTTP direta entre dois serviços, o produtor publica numa fila ou tópico e segue em frente, e o broker garante a entrega (com graus diferentes de garantia, dependendo da ferramenta) pro consumidor, mesmo que ele esteja temporariamente fora do ar.

## As três opções mais citadas

RabbitMQ é o broker mais tradicional dos três: modelo de fila com roteamento flexível (exchanges, routing keys), décadas de uso em sistema transacional de negócio, e o mais fácil de operar pra quem está começando. RabbitMQ, Kafka e NATS resolvem o mesmo problema geral com trade-offs bem diferentes. Kafka é otimizado pra throughput altíssimo e retenção longa do histórico de eventos (um consumidor pode "rebobinar" e reprocessar tudo desde o início), o padrão de fato pra event sourcing e pipeline de dados em escala, mas exige bem mais recurso de infraestrutura pra rodar bem (a própria documentação recomenda algo como 64–128GB de RAM e discos SSD dedicados por broker numa instalação séria) e mais complexidade operacional que os outros dois. NATS é o mais leve e o mais rápido dos três, latência sub-milissegundo, pensado pra comunicação entre microsserviços e IoT; com a extensão JetStream ganha persistência e durabilidade que o NATS original não tinha. RabbitMQ fica no meio: mais simples que Kafka, mais recurso (fila com garantia de entrega configurável, suporte a cluster) que o NATS básico.

## Pra ir além

A antítese de mensageria assíncrona é chamada síncrona direta, um serviço chama o outro via HTTP/gRPC e espera a resposta na hora. Mais simples de raciocinar (não precisa de infraestrutura extra, o fluxo é linear), mas acopla a disponibilidade de um serviço à do outro: se quem responde estiver fora do ar, quem chama trava ou falha também. Mensageria assíncrona troca essa simplicidade por resiliência a essa falha específica, ao custo de mais uma peça de infraestrutura pra manter e um modelo mental mais difícil (eventual consistency, ordem de entrega nem sempre garantida).

Onde aprofundar: a comparação oficial mantida pelo próprio time do [NATS](https://docs.nats.io/nats-concepts/overview/compare-nats) é direta sobre onde NATS vence e onde perde pras alternativas, incomum numa doc oficial de projeto (a maioria só vende o próprio produto).
