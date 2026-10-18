# QA — Zombicide online

## Referência atual — CONTENT-001 / UX-003

Runner `a56d0205`, `.\qa\run-tests.ps1 -Render`, exit 0: **72/72 regras, 27/27 habilidades, 27/27 UI headless, 29/29 UI GPU; host/client aprovados**. `skills_test.gd` passa a integrar o runner. Verifica ações gratuitas/restrições, surcharge de movimento, escolhas laranja/vermelha, bônus por arma Dual, precisão modificada, Sniper, Medic, Molotov sem dados e persistência/validação. Rede verifica os perfis Amy/Elle nos snapshots e após reentrada, além do fluxo anterior.

Matriz `skills-ui-delivery-{1280x800,1920x1080}`: **31/31 layout, 17/17 refinamento, 10/10 arte** por tamanho. Menus finais `session-menu-delivery-{1280x800,1920x1080}`: **19/19** por tamanho. Dimensões reais: **1280×800 e 1920×1061**. Sem erros nos logs finais inspecionados. [Capturas e resultados](artifacts/ux-003/); [conteúdo](../specs/CONTENT-001.md) e [menus](../specs/UX-003.md).

`menu_test.gd` usa GPU e o mesmo argumento `--output=<diretorio-absoluto>` dos testes de layout. Exercita menu inicial, bloqueio de atalhos, abas, feedback de save/carga, proteção de reset, preset Amy/Elle, custo grátis pela seleção da zona, escolhas e restrição online. Usa `user://qa-menu-mission.save`, sem tocar no save da missão do usuário. Tela cheia ainda sem teste funcional dedicado.

Correção do amostrador: hover/câmera intermediários do layout usam Tween real pausado + `custom_step`, depois retomam normalmente para o estado final. [API consultada](https://docs.godotengine.org/en/4.7/classes/class_tween.html#class-tween-method-custom-step). GPU readback pode consumir o tempo de parede dos timers, sem corresponder ao avanço esperado de frames; isso gerava falsas falhas intermediárias. Não é medição de fluidez/FPS. No teste de rede, aguardar snapshot com dois jogadores evita confundir a prévia local inicial com os dados do host.

As seções abaixo preservam as rodadas anteriores; esta seção e progress.md indicam a validação atual. Não somar casos repetidos como cenários únicos. Sem aprovação humana de apresentação/compreensão, partida integral, internet ou Steam.

Ambiente: Godot 4.7.2.stable.official.ed1daf0bf, Windows, renderer Compatibility. Render real observado em Intel Iris Xe / OpenGL 3.3. Sem medição de FPS ou partida humana completa. O primeiro contato humano rejeitou a apresentação inicial por dificuldade de compreensão; a revisão UX-001 ainda aguarda reteste.

## Executar

Na raiz do repositório:

```powershell
.\qa\run-tests.ps1 -Render
```

O runner cria uma pasta exclusiva em `qa/runs/`; preserva logs e resultados por execução. Requer Godot com o nome de executável acima no PATH. Não modifica firewall ou roteador. Teste de rede usa UDP localhost 28171 e convite próprio de QA; save da rede fica em arquivo de QA separado do save da missão do usuário.

## Cobertura

- `rules_test.gd`: regras/custos, turno, dados pendentes, dano, prioridade, fogo amigo, objetivos/fuga, derrota, RNG/save, incompatibilidade/corrupção/backup, transferência e pausa; MAP-001 cobre setup, portas, distâncias e visão sem curvas.
- `ui_test.gd`: cena real, botões, atlas/retrato correspondente, cartões/ações dentro da janela, projeção de clique inclusive nas áreas grandes, rejeição com motivo, save antigo preservado/rejeitado, prévia de ataque, dados, movimento da peça e câmera; captura quando há GPU.
- `art_test.gd`: frames antes/durante/depois do tween, posição final, redução de movimento, câmera e grupo de 15 zumbis com resumo visual sem perda no estado. Requer GPU e `--output=<diretorio-absoluto>`.
- `refinement_test.gd`: galeria isolada de quatro modelos, acessório equipado, prévia dual sem mutação/RNG, confirmação e rolagem manual, faces correspondentes, apresentação sem reaplicar combate, rejeição ilegal e lista completa de grupo denso; seis capturas reais. Requer GPU e `--output=<diretorio-absoluto>`.
- `layout_test.gd`: entrada sem modal, controles/peça persistentes, foco, atalhos reais por Input, cancelamento sem custo, hover/câmera amostrados, redução de movimento, duas rolagens impedidas, grupo/painel/rodapé dentro da janela, histórico e 14 alvos roláveis com escolha do último. Requer GPU e `--output=<diretorio-absoluto>`.
- `network_test.gd`: dois processos reais ENet, controle alheio rejeitado, movimento autorizado, desconexão/pausa e recriação da sessão do convidado recuperando credencial do disco.

Resultados finais e limitações em [progress.md](../progress.md). Captura de referência em [artifacts/dice-screen.png](artifacts/dice-screen.png).

Última execução completa `98855f80` em 17/10/2026: 72/72 regras/save; 27/27 UI headless; 29/29 UI GPU incluindo duas capturas; host e cliente aprovados em dois processos. Exit code 0. Após ajuste apenas de plural, UI GPU novamente 29/29 em `b-delivery-1920`. Casos se repetem entre ambientes; não somar como testes únicos de gameplay.

Amostra B: UI GPU 29/29 e arte 10/10 em `b-final-1280` e `b-final-1920`. Dimensões reais: 1280×800 e **1920×1061**; a janela solicitada em 1920×1080 foi limitada pelo desktop, inclusive na tentativa `b-exact-1920`. Não alegar Full HD exato validado. Capturas de dados, movimento amostrado, vista superior e grupo denso inspecionadas. Primeira tentativa detectou tween cancelado pela segunda atualização da UI; corrigido antes dos resultados finais. Não há medição de FPS, observação humana contínua de fluidez ou playtest de compreensão.

Capturas atuais versionadas em [B-001](artifacts/b-001/): gameplay-1280/gameplay-1920, movement-1920, motion-before/during/after, camera, dense e intro. Capturas de laboratório anteriores preservadas fora dessa subpasta. Conteúdo de regras permanece `m0-lab-v2-map12`; arte não muda a versão de save. Modelos/produção em [B-001](../arte/producao/b-001/README.md).

Exemplo efetivamente executado para arte, da raiz do repositório:

```powershell
Godot_v4.7.2-stable_win64_console.exe --path ./src --script ../qa/art_test.gd --position 16000,16000 --resolution 1280x800 --log-file C:/caminho/absoluto/art.log -- --output=C:/caminho/absoluto/art
```

Substituir caminhos pelo diretório local de QA. Execução desta rodada usou `qa/runs/b-final-1280/art` com caminho absoluto. Esses scripts geram fixtures isoladas, não alteram o save do usuário.

Isso não testa toda a caixa base, todos os exploits, partida completa com pessoas, internet ou Steam. Estado/fixtures de QA não são um playtest da missão oficial.

Ajuste final de apresentação: `window/stretch/aspect="expand"` removeu letterbox que reduzia o buffer de captura a 1697×1061. UI 29/29 e arte 10/10 repetidos em `qa/runs/b-expand-1920/`; PNG confirmado em 1920×1061. Esse ajuste não modifica regras ou save; capturas B atualizadas.

## Refinamento B-002 — execução atual

Runner `bbc4dda2`: **72/72 regras, 27/27 UI headless, 29/29 UI GPU**, host/client aprovados, exit code 0. Testes adicionais em `b002-delivery-1280x800` e `b002-delivery-1920x1080`: **17/17 refinamento e 10/10 arte por tamanho**. PNGs confirmados por leitura dos arquivos: **1280×800 e 1920×1061**, sem alegar Full HD exato. Galeria frontal/rotacionada, confirmação, dados pendentes/resultado e inspeção de 14 zumbis foram inspecionados visualmente. Resultados resumidos e capturas em [artifacts/b-002](artifacts/b-002/); logs integrais locais em `qa/runs/`.

Exemplo executado, substituindo o diretório pelo caminho absoluto desta cópia:

```powershell
Godot_v4.7.2-stable_win64_console.exe --path ./src --script ../qa/refinement_test.gd --position 16000,16000 --resolution 1280x800 -- --output=C:/caminho/absoluto/refinement
```

Uma tentativa intermediária falhou por consultar `size` no nó raiz 3D da mesa no próprio teste; corrigida para o tamanho da janela. Metadados finais usam as dimensões da imagem capturada, conferidas também com Pillow, em vez do tamanho reportado pela textura. Não houve falha de regra nessa tentativa. Sem aprovação humana, exportação standalone, benchmark, internet ou Steam.

## Interface UX-002 — execução vigente

Runner `0f3a8a15`: **72/72 regras, 27/27 UI headless, 29/29 UI GPU, host/client aprovados**. Matriz `ux003-verified-1280x800` / `ux003-verified-1920x1080`: **31/31 layout, 17/17 refinamento, 10/10 arte** por tamanho. Imagens **1280×800 e 1920×1061**; sem Full HD exato. Logs finais sem ERROR/SCRIPT ERROR. [Capturas/resultados](artifacts/ux-002/) e [detalhes](../specs/UX-002.md). Sete dos checks de layout gravam frames; não são 31 partidas ou cenários únicos.

Execução segue o comando de refinamento acima, trocando `../qa/refinement_test.gd` por `../qa/layout_test.gd`. Teste injeta teclado na fila de input do Godot; não controla o teclado global do desktop. Hover cosmético é dirigido no teste com mouse ignorado para isolar eventos externos; mede estados intermediário/final e ausência de mutação de regras. Leitura GPU pode avançar tempo de parede antes dos frames do tween; espera final é limitada a 30 frames adicionais. Câmera e movimento também são amostrados, sem alegação de FPS/latência percebida.

Falhas encontradas/corrigidas nesta rodada: retrato herdava tinta dos ícones, resultados pós-combate cortavam grupo/rodapé, redução de movimento consultava metadado inexistente. Histórico/roster fora dos cortes conferidos após correções. O teste de arte agora aguarda o fim da transição de câmera antes do frame superior. Não há novo teste de internet, Steam ou exportação.
