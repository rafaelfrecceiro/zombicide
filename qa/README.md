# QA da primeira entrega técnica

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
