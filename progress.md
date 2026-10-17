# Progresso — Zombicide online

- Fase: desenvolvimento
- Última atualização: 17/10/2026.
- Recorte autorizado: M0, seis sobreviventes, mesa 3D, automação, rolagens pelo jogador, dois participantes, save e reconexão.
- Código: `C:/Users/rafaf/Documents/Projects/Pessoal/Hub/GamesCodex/projetos/zombicide-online/src/`.
- Stack conferida: Godot 4.7.2.stable.official.ed1daf0bf / GDScript / Compatibility.
- [GDD](GDD.md) · [Specs](specs/README.md) · [Decisões](decisoes.md).

## Tarefas

| ID | Entrega | Estado | Critério de aceite | Dependências | Responsável ativo |
| --- | --- | --- | --- | --- | --- |
| ZOM-001 | Formalização e checkout GitHub | concluida | Documentos e índices ligados; repo isolado, origem preservada | D-014 | — |
| ZOM-002 | Dados e paridade de M0 | em-andamento | Mapa, cartas, fichas e regras necessárias conferidos por fonte | ZOM-001 | Codex |
| ZOM-003 | Motor de regras e decisões | em-andamento | Base com 60 testes passa; completar exceções e conteúdo oficial de M0-001 | ZOM-002 | Codex |
| ZOM-004 | Base técnica da mesa 3D e UI de dados | concluida | Cena, peças rígidas e estados funcionam; compreensão humana reaberta em ZOM-009 | ZOM-003 parcial | — |
| ZOM-005 | Sessão privada e pausa do laboratório | concluida | Dois processos, propriedade, queda e reconexão com credencial do disco | ZOM-003 parcial | — |
| ZOM-006 | Save e retomada do laboratório | concluida | Roundtrip, RNG e pendências preservados; corrupção rejeitada e backup mantido | ZOM-003 parcial | — |
| ZOM-007 | Steam e teste externo | planejada | Convite e partida entre redes externas com evidência | ZOM-005 | — |
| ZOM-008 | QA e primeiro commit | concluida | Runner completo passou; commit 5010948 enviado a origin/main | ZOM-003 parcial a ZOM-006 | — |
| ZOM-009 | Orientação e legibilidade após primeiro contato | em-andamento | Revisão UX-001 implementada e testes passam; usuário consegue selecionar, mover, atacar e lançar sem instrução externa | ZOM-004 | Codex / reteste do usuário |

## Entregas e evidências

| Tarefa | Artefatos | Verificação real | Limite |
| --- | --- | --- | --- |
| ZOM-001 | README, GDD, specs, AGENTS, decisões e índices do hub | Checkout vazio clonado; versão retorna 4.7.2.stable.official.ed1daf0bf | Não é código recuperado do jogo |
| ZOM-003 | src/core/rules.gd, content.gd | rules_test.gd: **60/60**; turno/custos, dados, combate, dano, objetivos/fuga, persistência e decisões | Fichas/decks/topologia parciais |
| ZOM-004 / ZOM-009 | src/ui/table.gd, board_hints.gd, main.tscn | ui_test.gd: **20/20 headless**, **21/21 GPU** em 1440×900; primeira tela e ajuda em 1280×800, capturas inspecionadas | Primeiro layout rejeitado pelo usuário; nova versão aguarda reteste humano |
| ZOM-005 | src/net/session.gd | Dois processos ENet localhost: host/client aprovados; comando alheio rejeitado; pausa, sessão cliente recriada e reconectada | Internet e Steam não testados |
| ZOM-006 | src/core/storage.gd, session.gd | Save em disco conserva números inteiros, RNG, decisões e ordem; backup e validação de schema/conteúdo | Migração de host, Cloud e recuperação de falha de hardware não testados |

Último runner completo: `qa/runs/6cbf28a7/`, comando `.\qa\run-tests.ps1 -Render`, exit code 0. Execução anterior preservada em `338ecca4`. Logs individuais e JSON nessas pastas, ignorados no Git; scripts e [resumo QA](qa/README.md) são versionáveis. Capturas preservadas: [dados](qa/artifacts/dice-screen.png), [primeiros passos](qa/artifacts/first-steps.png) e [ajuda inicial](qa/artifacts/intro.png).

Render: OpenGL 3.3 / Compatibility / Intel Iris Xe. Nenhuma métrica de performance medida. A interface de rolagem foi movida para o topo depois de a captura mostrar que ficava fora da área visível.

Primeiro commit de código enviado ao GitHub: [5010948](https://github.com/rafaelfrecceiro/zombicide/commit/5010948ab3351ceb346969d3a2a94fec08a72bf0). Push de `main` a `origin/main` concluído. Identidade de commit configurada somente neste repositório a partir da conta GitHub autenticada, usando endereço noreply; configuração global não foi alterada.

## Limitações

1. **Fidelidade de conteúdo pendente:** seis peões adultos anônimos, sem skills azuis individuais; não são seis fichas oficiais completas. Pausa explícita ao atingir laranja, evitando inventar a árvore de habilidades. Dois exemplos de spawn do manual repetidos formam deck de laboratório; não são as 40 cartas. Arma especial e parte do equipamento são fixtures identificadas. Ver [origem](origem/README.md).
2. **Mapa provisório:** representação em células com 18 zonas, oito salas e quatro portas; posicionamento de objetivos/caixas/inimigos segue leitura da p.36, mas fronteiras de zonas, portas e visão precisam de auditoria de paridade. Não é reprodução validada dos tiles 1V/3V.
3. **Regras ainda parciais:** sem habilidades individuais, árvores laranja/vermelha, Rush oficial, abominações especiais, todas as formas de reorganização/troca numa única ação e exceções de inventário fora de decisões pendentes. Eventos de reserva e fluxos centrais têm implementação, mas não toda combinação foi testada.
4. **Online inicial de laboratório:** sala para host+convidado por endereço/convite; não é lobby Steam nem sistema de até seis conexões pronto. Reconexão conserva identidade local por credencial, não autenticação Steam. Queda do host exige nova sala e restauração, sem migração automática.
5. **Distribuição/visual:** sem exportação Windows standalone (templates não encontrados no diretório padrão consultado), publicação Steam, arte final ou modelos Blender produzidos. O jogo executou no editor/runtime Godot com GPU real. Não houve partida humana completa de M0.

Nenhuma tarefa de paridade integral está marcada concluída. A primeira entrega é a base técnica editável, identificada como laboratório na própria tela.

## Como executar

Na raiz deste repositório:

```powershell
& 'Godot_v4.7.2-stable_win64_console.exe' --path ./src
.\qa\run-tests.ps1 -Render
```

Ambos os caminhos de execução Godot e QA foram usados. Também é possível abrir `src/project.godot` no editor. `Iniciar-Jogo.ps1` fornece um launcher; seu parse foi conferido, sem execução interativa manual nesta rodada.

Solo local permite testar os seis peões. Para duas pessoas: host cria mesa com convite de ao menos seis caracteres; convidado usa endereço/mesmo convite. Ao retornar, manter endereço/convite e credencial local. Para restaurar missão online, host cria sala e carrega o save antes da reentrada do convidado. Save solo é carregado em modo solo. Não confundir teste localhost com acesso externo.

## Próxima ação

ZOM-009: retestar a nova orientação com o usuário antes de considerar a interface compreensível. Depois, ZOM-002/ZOM-003: conferir topologia real de 1V/3V, inventariar as seis fichas escolhidas e cartas oficiais aplicáveis, substituir dados de laboratório por conteúdo com evidência e implementar/testar as exceções. Manter peões provisórios até direção final. ZOM-007 deve tratar Steam e teste externo em rodada própria.

## Histórico — 17/10/2026

Usuário autorizou M0, ideia promovida, projeto clonado e criado em Godot 4.7.2. Implementados motor, mesa, dados, persistência e host/cliente privado. Testes detectaram diferença int/float após JSON e divisão desigual de sobras; correções cobertas. Captura identificou enquadramento distante e rolagem fora da área visível; ajustados. Estado de fidelidade parcial explicitado em UI, origem e tarefas.

Primeiro contato humano: usuário considerou arte/layout ruins e mal conseguiu jogar por não entender a interface. Testes técnicos anteriores não validavam compreensão. Revisão UX-001 adicionou guia inicial, instruções por etapa, peças ativas e destinos legais destacados, painel de decisão sem rolagem fora da tela e janelas separadas para inventário/conexão/save. Testes técnicos e capturas passam; reteste humano permanece pendente. Nenhuma direção de arte foi aprovada.
