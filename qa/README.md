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
- `ui_test.gd`: cena real, botões, projeção de clique inclusive nas áreas grandes, rejeição com motivo, save do mapa antigo preservado/rejeitado, prévia de ataque, botão de lançar e câmera superior; captura de movimento legal e dados quando há GPU.
- `network_test.gd`: dois processos reais ENet, controle alheio rejeitado, movimento autorizado, desconexão/pausa e recriação da sessão do convidado recuperando credencial do disco.

Resultados finais e limitações em [progress.md](../progress.md). Captura de referência em [artifacts/dice-screen.png](artifacts/dice-screen.png).

Última execução completa `d3a0cc4d` em 17/10/2026: 72/72 regras/save; 22/22 UI headless; 24/24 UI GPU incluindo duas capturas; host e cliente aprovados em dois processos. Runner retornou exit code 0. Inclui os ajustes finais de espaçamento/rótulos e verificações explícitas de porta fechada e aviso de save antigo. Os testes de UI repetem o mesmo fluxo em ambientes distintos; esses totais não são casos únicos de gameplay somáveis. Frames de dados e movimento em 1440×900 inspecionados; primeira tela e ajuda atualizadas também renderizadas e inspecionadas em 1280×800. Execuções anteriores preservadas em `27b80cc2`, `map-labels`, `6cbf28a7` e `338ecca4`.

Capturas versionadas: [movimento](artifacts/legal-movement.png), [dados](artifacts/dice-screen.png), [início](artifacts/first-steps.png), [ajuda](artifacts/intro.png). Conteúdo atual `m0-lab-v2-map12`; iniciar missão nova ao retestar o mapa.

Isso não testa toda a caixa base, todos os exploits, partida completa com pessoas, internet ou Steam. Estado/fixtures de QA não são um playtest da missão oficial.
