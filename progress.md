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
| ZOM-002 | Dados e paridade de M0 | em-andamento | Mapa revisado em MAP-001; completar cartas/fichas/regras com fontes | ZOM-001 | Codex |
| ZOM-003 | Motor de regras e decisões | em-andamento | Base com 72 testes passa; completar exceções e conteúdo oficial de M0-001 | ZOM-002 | Codex |
| ZOM-004 | Base técnica da mesa 3D e UI de dados | concluida | Cena, peças rígidas e estados funcionam; compreensão humana reaberta em ZOM-009 | ZOM-003 parcial | — |
| ZOM-005 | Sessão privada e pausa do laboratório | concluida | Dois processos, propriedade, queda e reconexão com credencial do disco | ZOM-003 parcial | — |
| ZOM-006 | Save e retomada do laboratório | concluida | Roundtrip, RNG e pendências preservados; corrupção rejeitada e backup mantido | ZOM-003 parcial | — |
| ZOM-007 | Steam e teste externo | planejada | Convite e partida entre redes externas com evidência | ZOM-005 | — |
| ZOM-008 | QA e primeiro commit | concluida | Runner completo passou; commit 5010948 enviado a origin/main | ZOM-003 parcial a ZOM-006 | — |
| ZOM-009 | Orientação e legibilidade após primeiro contato | em-andamento | Revisão UX-001 implementada e testes passam; usuário consegue selecionar, mover, atacar e lançar sem instrução externa | ZOM-004 | Codex / reteste do usuário |
| ZOM-010 | Transcrição do mapa e regressões de visão | concluida | MAP-001 confronta pp.9–10/36; zonas/portas/setup revistos, distâncias/visão/clique/save cobertos | ZOM-002 parcial | — |
| ZOM-011 | Três direções de arte comparáveis | concluida | PNG por direção, HUD/peças/cenário, paleta/tipo/feedback, custos, recomendação e prompts persistidos | Pedido explícito 17/10 | — |
| ZOM-012 | Amostra B — Quadrinhos Urbanos na engine | em-andamento | Assets/UI e refinamento B-002 implementados; obter reteste humano de leitura e acabamento | D-016 / ZOM-011 | Codex / reteste do usuário |
| ZOM-013 | Implementar refinamento representativo B-002 | concluida | Quatro modelos editáveis, galeria, tipografia licenciada, prévia, faces de dados e inspeção completa; QA técnico passa | D-017 / ZOM-012 parcial | — |
| ZOM-014 | Interface fluida e hierarquia UX-002 | concluida | Layout B reorganizado, controles persistentes, transições/atalhos/redução de movimento; 31/31 checks por tamanho, sem cortes nos cenários testados | D-018 / ZOM-013 | — |
| ZOM-015 | Menus e apresentação UX-003 | concluida | Menu inicial, abas Missão/Amigos/Opções, feedback e proteção de reset; 19/19 checks por tamanho | D-019 / ZOM-014 | — |
| ZOM-016 | Lote verificável Amy/Elle e ações gratuitas | concluida | Árvores das duas fichas com fonte, pistola 3+, 27/27 regressões; save/rede preservam perfis | D-019 / ZOM-002 parcial | — |

## Entregas e evidências

| Tarefa | Artefatos | Verificação real | Limite |
| --- | --- | --- | --- |
| ZOM-001 | README, GDD, specs, AGENTS, decisões e índices do hub | Checkout vazio clonado; versão retorna 4.7.2.stable.official.ed1daf0bf | Não é código recuperado do jogo |
| ZOM-003 / ZOM-010 | src/core/rules.gd, content.gd, specs/MAP-001.md | rules_test.gd: **72/72**; 12 regressões adicionais de zonas, visão, distâncias, setup e versão de save | Fichas/decks incompletos; transcrição visual sem revisão independente |
| ZOM-004 / ZOM-009 / ZOM-012 | src/ui/table.gd, board_hints.gd, comic_art.gd e assets/b | ui_test.gd: **27/27 headless**, **29/29 GPU**; assets reais, atlas correspondente ao ator, ações/dados visíveis, movimento amostrado | Direção B aceita; primeira execução na engine ainda aguarda reteste humano |
| ZOM-005 | src/net/session.gd | Dois processos ENet localhost: host/client aprovados; comando alheio rejeitado; pausa, sessão cliente recriada e reconectada | Internet e Steam não testados |
| ZOM-006 | src/core/storage.gd, session.gd | Save em disco conserva números inteiros, RNG, decisões e ordem; backup e validação de schema/conteúdo | Migração de host, Cloud e recuperação de falha de hardware não testados |
| ZOM-011 | direcao-arte.md; arte/direcoes/{a-mesa-colecionador,b-quadrinhos-urbanos,c-diorama-urbano}/gameplay-v1.png e prompt.md; manifesto.json | Três PNGs 1672×941; B escolhida pelo usuário em D-016 | São conceitos estáticos; não confundir com captura da amostra |
| ZOM-012 | arte/producao/b-001; nove .blend editáveis e GLBs; board/portraits/icons; QA em qa/artifacts/b-001 | Blender 5.2.2 concluiu 9 modelos; Godot importou; art_test.gd **10/10** em cada tamanho; frames antes/durante/depois, câmera e 15 zumbis inspecionados | Modelos procedurais simples abaixo do mockup; sem fichas oficiais, benchmark ou playtest humano |
| ZOM-013 | arte/producao/b-002; quatro .blend/GLB novos; miniature_gallery.gd, dice_tray.gd, attack_info; fonte/OFL | Blender `REFINED_COMPLETE 4`, importação exit 0; **17/17 refinamento, 10/10 arte** em cada janela; seis capturas por tamanho inspecionadas; runner geral aprovado | Só Sobrevivente 01 refinado; estudo angular, sem aceitação humana; sem novas cartas/skills |
| ZOM-014 | specs/UX-002.md; table_layout, ui_kit, table_button, table/board_hints/dice_tray; qa/layout_test.gd | **31/31 layout, 17/17 refinamento, 10/10 arte** por tamanho; runner 0f3a8a15 aprovado; snapshots e movimento amostrados | Qualidade percebida, acessibilidade completa e desempenho sem aprovação/medição; não é M0 integral |
| ZOM-015 | specs/UX-003.md; src/ui/game_menu.gd, table/ui_kit; qa/menu_test.gd | **19/19 menu** em 1280×800 e 1920×1061; confirma save/load com feedback, preset, bloqueios e cancelamento | Tela cheia ainda sem teste dedicado; não comprova beleza/compreensão humana |
| ZOM-016 | specs/CONTENT-001.md; origem/inventario-caixa.md; src/core/survivors.gd, rules/content/session; qa/skills_test.gd | **27/27 habilidades**, além de 72/72 regras e rede real localhost com perfis após reentrada | Duas fichas, quatro peões genéricos; cartas/spawns oficiais completos e exceções ainda pendentes |

Último runner completo: `qa/runs/98855f80/`, comando `.\qa\run-tests.ps1 -Render`, exit code 0: regras 72/72, UI 27/27 headless e 29/29 GPU, host/client aprovados. Rodadas de arte: `b-final-1280` e `b-final-1920`, UI 29/29 e arte 10/10 cada; após ajuste exclusivo de plural, UI 29/29 repetida em `b-delivery-1920`. Tentativa `b-exact-1920` confirmou o mesmo limite da janela: **1920×1061 reais**, apesar do pedido 1920×1080; 1280×800 real confirmado. Capturas e inspeção são desses tamanhos reais, sem alegar Full HD exato validado. Scripts/QA versionados; logs/JSON em qa/runs ignorados. Capturas B atuais em [qa/artifacts/b-001](qa/artifacts/b-001/); capturas antigas preservadas como histórico.

**Execução mais recente — B-002:** runner `qa/runs/bbc4dda2/`, `.\qa\run-tests.ps1 -Render`, exit 0, **72/72 regras, 27/27 UI headless, 29/29 UI GPU, host/client aprovados**. Refinamento em `b002-delivery-1280x800` e `b002-delivery-1920x1080`: **17/17**, arte **10/10** por tamanho. PNGs confirmados em **1280×800 e 1920×1061**, segunda janela limitada pelo desktop. Capturas e resumo versionados em [qa/artifacts/b-002](qa/artifacts/b-002/). A referência ao runner B-001 acima fica como histórico, substituída por esta execução atual.

**Execução anterior — UX-002:** runner `qa/runs/0f3a8a15/`, mesmo comando, exit 0: **72/72 regras, 27/27 UI headless, 29/29 UI GPU, host/client aprovados**. Matriz `ux003-verified-1280x800` / `ux003-verified-1920x1080`: **31/31 layout, 17/17 refinamento, 10/10 arte por tamanho**, sem erros nos logs finais. PNGs **1280×800 / 1920×1061**. [Capturas/resultados](qa/artifacts/ux-002/) e [especificação](specs/UX-002.md). Contagens incluem gravação de frames; não somar execuções repetidas como cenários de gameplay distintos. Substitui B-002 como referência atual da interface.

Render: OpenGL 3.3 / Compatibility / Intel Iris Xe. Nenhuma métrica de performance medida. A interface de rolagem foi movida para o topo depois de a captura mostrar que ficava fora da área visível.

Primeiro commit de código enviado ao GitHub: [5010948](https://github.com/rafaelfrecceiro/zombicide/commit/5010948ab3351ceb346969d3a2a94fec08a72bf0). Push de `main` a `origin/main` concluído. Identidade de commit configurada somente neste repositório a partir da conta GitHub autenticada, usando endereço noreply; configuração global não foi alterada.

## Execução vigente — CONTENT-001 / UX-003

Runner `qa/runs/a56d0205/`, `.\qa\run-tests.ps1 -Render`, exit 0: **72/72 regras, 27/27 habilidades, 27/27 UI headless, 29/29 UI GPU e host/client aprovados**. Perfis Amy/Elle conferidos no snapshot autoritativo e após reconexão por credencial. Matriz `skills-ui-delivery-1280x800` / `skills-ui-delivery-1920x1080`: **31/31 layout, 17/17 refinamento e 10/10 arte** por tamanho. Menus finais em `session-menu-delivery-1280x800` / `session-menu-delivery-1920x1080`: **19/19** por tamanho, sem erros nos logs finais.

Capturas reais **1280×800 / 1920×1061**, segunda janela limitada pelo desktop. Menu/opções/amigos/escolhas inspecionados; [capturas e resultados versionados](qa/artifacts/ux-003/). Contagens incluem gravação de frames; não somar execuções repetidas como cenários únicos. Hover/câmera intermediários do QA usam Tween real pausado e `custom_step`, retomando para conferir o estado final; não é benchmark de fluidez.

Pesquisa: PDF preservado com hash reconferido, pp.7/13/14/15 inspecionadas, efeitos pp.63/65 lidos. Pistola 3+ corrigida; árvores Amy/Elle, ações gratuitas, Sniper, bônus e Medic implementados. [Cobertura exata](specs/CONTENT-001.md). Usuário informou não ter material físico. Os nomes/quantidades da p.4 estão no inventário documental; atributos faltantes não foram inventados. Conteúdo **m0-lab-v3-skills**, saves v1/v2 rejeitados preservando arquivos e estado, sem migração automática.

Falhas intermediárias corrigidas: texto de botões do cabeçalho cortado por configuração global; feedback de save escondido atrás da Central; abertura de menu após carga bem-sucedida; amostras de Tween dependentes de timers/custo de leitura GPU. No novo teste de rede, a primeira prévia local do cliente foi confundida com snapshot autoritativo; corrigido o teste para aguardar os dois participantes. Rodadas finais acima passam. Não houve alteração de regra para acomodar esses testes.

## Limitações

1. **Fidelidade de conteúdo pendente:** preset com Amy/Elle verificadas e quatro peões genéricos, que continuam pausando no laranja. Árvores das outras quatro fichas ainda pendentes. Dois exemplos de spawn repetidos formam deck de laboratório; não são as 40 cartas. Arma especial e parte do equipamento são fixtures identificadas. Usuário não tem acesso à caixa física. Ver [origem](origem/README.md) e [CONTENT-001](specs/CONTENT-001.md).
2. **Mapa revisado, arte esquemática:** transcrição visual de pp.9–10/36 com 12 zonas (sete salas/cinco ruas), três portas, quatro salas escuras e inimigos iniciais corrigidos. MAP-001 e testes substituem a grade de 18 células. Revisão independente e partida humana completa ainda pendentes. Saves `m0-lab-v1` são incompatíveis; arquivos preservados no carregamento, sem migração automática.
3. **Regras ainda parciais:** somente as habilidades individuais de Amy/Elle; faltam Rush oficial, abominações especiais, primeiro jogador pelo dono do Fire Axe, todas as formas de reorganização/troca numa única ação e exceções de equipamento. Eventos de reserva e fluxos centrais têm implementação, mas não toda combinação foi testada.
4. **Online inicial de laboratório:** sala para host+convidado por endereço/convite; não é lobby Steam nem sistema de até seis conexões pronto. Reconexão conserva identidade local por credencial, não autenticação Steam. Queda do host exige nova sala e restauração, sem migração automática.
5. **Distribuição/visual:** B escolhida e B-002 implementada; quatro modelos refinados substituem os equivalentes B-001, cinco sobreviventes ainda anteriores. Acabamento angular de estudo abaixo do conceito; lista de grupo denso, fonte condensada licenciada e foco nas janelas implementados. Sem exportação standalone (templates não encontrados no local padrão), Steam ou partida humana completa. Faltam áudio, navegação completa por teclado, escala configurável e medida de performance. Full HD exato não validado: janela solicitada 1920×1080 ficou 1920×1061 neste desktop; teste em 1280×800 confirmado.

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

Retestar **UX-003** com o usuário: Iniciar missão, selecionar Amy, gastar movimento gratuito, mover/cancelar, conferir ataque e lançar. Avaliar menus, leitura e continuidade. ZOM-012/ZOM-009 seguem abertos para aceitação humana. Continuar ZOM-002/ZOM-003 com fontes públicas legíveis das outras quatro fichas/cartas, exceções, revisão independente e partida completa. Conferir Full HD exato em configuração sem limite de janela. Steam/teste externo em ZOM-007 posteriormente.

## Histórico — 17/10/2026

Usuário autorizou M0, ideia promovida, projeto clonado e criado em Godot 4.7.2. Implementados motor, mesa, dados, persistência e host/cliente privado. Testes detectaram diferença int/float após JSON e divisão desigual de sobras; correções cobertas. Captura identificou enquadramento distante e rolagem fora da área visível; ajustados. Estado de fidelidade parcial explicitado em UI, origem e tarefas.

Primeiro contato humano: usuário considerou arte/layout ruins e mal conseguiu jogar por não entender a interface. Testes técnicos anteriores não validavam compreensão. Revisão UX-001 adicionou guia inicial, instruções por etapa, peças ativas e destinos legais destacados, painel de decisão sem rolagem fora da tela e janelas separadas para inventário/conexão/save. Testes técnicos e capturas passam; reteste humano permanece pendente. Nenhuma direção de arte foi aprovada.

Usuário pediu “vamos seguir”, sem confirmar aprovação da arte ou reteste. ZOM-010 corrigiu a aproximação de mapa: ruas passam a cruzar a emenda, sala oeste alongada é uma zona, três entradas externas, Runner/Fatty juntos no norte. Visão usa a direção das aberturas e não vira esquinas. Piso, destaque e clique compartilham limites; peões foram mais espaçados, com número e base ativa destacados. Conteúdo passa a `m0-lab-v2-map12`; saves antigos são rejeitados sem alteração da missão/arquivo. Regras 72/72, UI 22/22 headless e 24/24 GPU, rede host/cliente aprovados. Nenhuma alegação de M0 integral ou arte final.

Nova versão aberta no runtime Godot para reteste, PID 8924, janela “Zombicide — M0 em construção (DEBUG)” respondendo; `qa/playtest-map.log` confirma Compatibility/Intel Iris Xe, sem erros no início. Isso confirma abertura, não conclusão de playtest humano.

Pedido de direções de arte: produzidas três propostas com mesma situação de ataque e organização de HUD, variando resina/mesa física, quadrinhos pintados e diorama volumétrico. Imagens, prompts integrais, produção e riscos preservados; inspeção constatou desvios de mapa/contadores/identidade, explicitados como limites dos conceitos. Recomendação A; usuário ainda escolhe ou combina. Código do jogo não alterado, não houve novo teste runtime nesta rodada documental/visual. As contagens QA acima são da implementação anterior.

Usuário escolheu “a B” (D-016), substituindo a recomendação A como direção vigente. Integrados tabuleiro/atlas image_gen, nove figuras estáticas originais Blender/GLB, ícones SVG próprios, cartões creme, ação vermelha, retrato correspondente e tween de peça inteira com redução de movimento. Material Toon/cores iniciais ficaram claros demais na captura; corrigidos espaço de cor e Lambert/contorno. Atualização dupla cancelava tween; regressão capturada e corrigida. Câmera agora ajusta limites projetados; grupos acima de 4/8 figuras são resumidos sem perder atores no estado. Testes finais acima aprovados, acabamento e playtest humano pendentes. Prompts, procedência, scripts e fontes editáveis preservados; nenhuma imagem do manual no runtime.

Ajuste final de apresentação: `window/stretch/aspect="expand"` removeu letterbox que reduzia o buffer de captura a 1697×1061. UI 29/29 e arte 10/10 repetidos em `qa/runs/b-expand-1920/`; PNG confirmado em 1920×1061. Esse ajuste não modifica regras ou save; capturas B atualizadas.

Amostra B aberta para reteste no runtime Godot, PID 35832, janela “Zombicide — M0 em construção (DEBUG)” respondendo; log `qa/playtest-b.log` sem erros no início. Confirma abertura, não aprovação humana da amostra.

Usuário autorizou o próximo refinamento (“pode seguir”, D-017). B-002 substitui quatro miniaturas por malhas conectadas, detalhes de roupa/rosto e silhuetas diferentes; acessórios do Sobrevivente 01 seguem a mão equipada nos quatro tipos suportados. Galeria 3D própria, Barlow Condensed Bold/OFL, prévia compartilhada com validação de regras, bandeja de faces autoritativas e lista rolável de todos os atores implementadas. Piso/retratos preservados. Capturas detectaram figuras pequenas, nomes ocultos pelo pedestal e foco sem contraste; corrigidos. Tentativa de QA intermediária falhou por propriedade errada no nó de teste; corrigida, resultados finais acima. B-001 permanece preservada, utilitários agora importáveis sem regenerar assets. Qualidade visual ainda de estudo; decisão B não equivale à aprovação da execução.

A tentativa de abrir a nova sessão interativa ao entregar B-002 foi rejeitada pela revisão automática de aprovação: retorno `blocked by policy`, sem motivo específico. O comando inteiro não executou; manifesto e resultados foram gravados depois em ação separada. Não alegar sessão B-002 aberta para reteste humano. Launcher e `src/project.godot` disponíveis para execução local; as sessões GPU de QA foram executadas e encerradas normalmente.

B-002 enviada a `origin/main`: implementação [0838372](https://github.com/rafaelfrecceiro/zombicide/commit/0838372) e preservação dos bytes da licença [80a7f1e](https://github.com/rafaelfrecceiro/zombicide/commit/80a7f1e). Push confirmado de b6142ab até 80a7f1e. `git diff --check` passa; whitespace original da licença externa preservado por atributo específico, sem modificar seu texto.

Pedido de UI/layout fluido, intuitivo e bonito (D-018): UX-002 implementada na direção B. Cabeçalho e contadores curtos, guia contextual, ficha compacta, retratos em cores, ícones próprios, grupo persistente, histórico em janela e atalhos. Controles e miniaturas deixam de ser recriados por mudanças cosméticas; foco e deslocamentos são preservados. Tweens de hover/pressão/guia/ficha/câmera e redução de movimento integrados. QA encontrou corte do grupo/rodapé ao restaurar ações após rolagem, tingimento indevido de retrato e metadado ausente; corrigidos. Bandeja final compacta e listas extensas roláveis. Espera de tween no teste passou a respeitar frames processados após leitura GPU, com limite, pois timer de parede não comprovava fim da transição na janela maior. Resultados finais e limites acima. Nenhuma nova alegação de partida humana, benchmark ou paridade oficial.

UX-002 enviada a `origin/main`: [4cbba68](https://github.com/rafaelfrecceiro/zombicide/commit/4cbba68), push confirmado a partir de d787966. Fontes, testes, especificação e capturas reais versionados; `git diff --cached --check` passou. Nenhuma tentativa nova de abrir uma sessão interativa nesta rodada; execução real ocorreu nos processos GPU de QA.
