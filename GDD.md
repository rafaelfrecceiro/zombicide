# GDD — Zombicide online / M0

- Estado: consolidado para iniciar o recorte M0; fidelidade integral pendente.
- Origem: [ideia](../../ideias/zombicide-online/README.md), [fontes](origem/README.md).
- Data: 17/10/2026.
- [Decisões](decisoes.md) · [Progresso](progress.md) · [Specs](specs/README.md).

## Visão e pilares

Reunir amigos em uma mesa digital, preservando o planejamento do boardgame. Regras são aplicadas pelo sistema, decisões legais pertencem aos jogadores. Ações ilegais são bloqueadas com razão; jogadas legais perigosas permanecem possíveis.

## Experiência central

Preparar grupo de seis sobreviventes, ativar um de cada vez por jogador, administrar ações/equipamento e concluir a missão antes de a horda eliminar alguém. Roll acionado manualmente na interface, resultado resolvido pelo sistema. Miniaturas rígidas se deslocam como pinos; sem animação corporal inicial.

## M0

Manual inglês ZCD001, p. 36: tiles 1V e 3V; dois objetivos, duas caixas; um Fatty, um Runner e dois Walkers nas zonas indicadas; todos precisam coletar os objetivos/caixas e fugir pela saída sem zumbis no fim de suas ativações. Objetivo dá 5 de adrenalina; caixa dá arma especial aleatória ainda disponível.

Mapa lógico, conteúdo e regras precisam de fonte por dado. Versão inicial deve identificar laboratório quando decks/fichas/topologia ainda não estejam completos. Laboratório não comprova paridade de M0 nem balanceamento.

## Sistemas

[M0-001](specs/M0-001.md): estado de regras separado da mesa, ações validadas, inventário, combate, escolhas, fase da horda, objetivos, fuga e término.

[NET-001](specs/NET-001.md): anfitrião autoritativo no laboratório, cliente por conexão privada; controle atribuído a participantes, sem aprovação de integração Steam específica.

[SAVE-001](specs/SAVE-001.md): salvar/restaurar o estado, pausa por desconexão e retomada sem rerrolar.

## Interface e controles

Candidato de engenharia: mouse seleciona zona e sobrevivente, painéis de ações e inventário, interface de dados quando necessário, log, câmera inclinada com zoom e vista superior. Teclado serve de atalho. Idioma inicial pt-BR como detalhe reversível do protótipo.

Implementação de interface vigente em [UX-002](specs/UX-002.md), D-018: controles persistentes, guia sem modal obrigatório, cabeçalho/contadores, painel contextual compacto, grupo de seis, dados e histórico. Atalhos e transições com redução de movimento; aceitação humana ainda aberta.

[UX-003](specs/UX-003.md), D-019, acrescenta menu inicial de missão, central com abas, janelas/botões da direção B e feedback visível de save/load. [CONTENT-001](specs/CONTENT-001.md) incorpora as árvores verificadas de Amy e Elle, ações gratuitas e correção da pistola; preset com duas fichas e quatro peões, baralhos ainda de laboratório. Sem material físico disponível ao usuário; os dados restantes dependem de pesquisa documental.

## Arte e áudio

[Arte](direcao-arte.md): B — Quadrinhos Urbanos escolhida em D-016. Amostra B-001 usa tabuleiro ilustrado plano, miniaturas pintadas rígidas, retratos e UI gráfica. Modelos iniciais ainda em refinamento; referência física preservada para pesquisa, sem imagens do manual no runtime. Áudio final ainda não definido.

## Plataforma

Godot 4.7.2 / GDScript / Compatibility, PC Windows disponível para validação local. PC/Steam é o alvo aprovado, não uma integração já existente. Outras plataformas de PC não estão aprovadas nem testadas. Mobile fora do recorte inicial.

## Limites

Recorte autorizado: M0, seis sobreviventes, teste com dois participantes, regras e rolagens, save/reconexão. Trabalho pode avançar em entregas técnicas parciais, sempre declarando lacunas. Missões adicionais, editor, expansão, salas públicas, campanha, rigs e animações corporais ficam fora desta primeira implementação.

## Validação

Testes de regras e transições, persistência e repetição, dois processos em localhost, importação e render real. Internet, Steam e playtest humano exigem evidências próprias. Duração/diversão não são inferidas de testes automatizados.
