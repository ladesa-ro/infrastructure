# NixOS

NixOS é uma distribuição Linux inteira construída ao redor de um princípio radical: o sistema operacional inteiro, todo pacote instalado, todo serviço, toda configuração, é declarado num único arquivo (`/etc/nixos/configuration.nix`), e aplicar essa configuração constrói um sistema novo do zero a partir dela, em vez de editar o sistema existente incrementalmente. Cada geração do sistema fica guardada; se uma atualização quebrar algo, o rollback é instantâneo, volta pra geração anterior, que continua existindo intacta, não foi sobrescrita.

## A diferença real de filosofia contra configuration management tradicional

Ansible (ver [Ansible](ansible.md)) é declarativo dentro de cada task, mas o sistema final é resultado de aplicar uma sequência de tasks sobre uma máquina que já existia antes, e só administra o que as tasks efetivamente tocam, o resto do sistema fica fora do controle declarado. NixOS não tem esse ponto cego: a configuração descreve o sistema inteiro, não um subconjunto dele, então não existe "deriva" possível entre o que está declarado e o que existe de verdade, o próprio mecanismo de build garante isso.

## O custo de adotar

Migrar de um setup tradicional pra NixOS significa reconstruir a máquina do zero numa distro completamente diferente, reaprender uma linguagem de configuração própria (Nix, uma linguagem funcional, não YAML), e abrir mão de rodar tudo em cima de pacote da distro padrão que já era usada antes. O ganho (zero drift garantido pelo próprio SO) é real, mas o custo de migração só se paga a partir de um tamanho e criticidade que justifiquem reescrever tudo numa ferramenta nova.

## Pra ir além

A antítese completa de NixOS é o modelo mutável tradicional: a mesma máquina reconfigurada repetidamente in-place, sem garantia estrutural contra drift, só disciplina de ferramenta (idempotência do [Ansible](ansible.md), por exemplo) pra minimizar o risco.

Onde aprofundar: o [NixOS Wiki](https://wiki.nixos.org/wiki/NixOS) é mantido pela própria comunidade e é mais acessível como primeira leitura do que a documentação de referência da linguagem Nix em si, que tem curva de aprendizado real.
