# QA da primeira entrega técnica

Ambiente: Godot 4.7.2.stable.official.ed1daf0bf, Windows, renderer Compatibility. Render real observado em Intel Iris Xe / OpenGL 3.3. Sem medição de FPS ou partida humana completa. O primeiro contato humano rejeitou a apresentação inicial por dificuldade de compreensão; a revisão UX-001 ainda aguarda reteste.

## Executar

Na raiz do repositório:

```powershell
.\qa\run-tests.ps1 -Render
```

O runner cria uma pasta exclusiva em `qa/runs/`; preserva logs e resultados por execução. Requer Godot com o nome de executável acima no PATH. Não modifica firewall ou roteador. Teste de rede usa UDP localhost 28171 e convite próprio de QA; save da rede fica em arquivo de QA separado do save da missão do usuário.

## Cobertura

- `rules_test.gd`: regras/custos, turno, dados pendentes, dano, prioridade, fogo amigo, objetivos/fuga, derrota, RNG/save, incompatibilidade/corrupção/backup, transferência e pausa.
- `ui_test.gd`: cena real, botões, projeção de clique na zona, rejeição com motivo, prévia de ataque, botão de lançar e câmera superior; captura quando há GPU.
- `network_test.gd`: dois processos reais ENet, controle alheio rejeitado, movimento autorizado, desconexão/pausa e recriação da sessão do convidado recuperando credencial do disco.

Resultados finais e limitações em [progress.md](../progress.md). Captura de referência em [artifacts/dice-screen.png](artifacts/dice-screen.png).

Última execução completa `6cbf28a7` em 17/10/2026: 60/60 regras/save; 20/20 UI headless; 21/21 UI GPU incluindo captura; host e cliente aprovados em dois processos. Runner retornou exit code 0. Os testes de UI repetem o mesmo fluxo em ambientes distintos; esses totais não são casos únicos de gameplay somáveis. O frame de dados inspecionado mede 1440×900; primeira tela e ajuda também foram renderizadas e inspecionadas em 1280×800. A revisão cobre guia inicial, destino permitido, ação ativa, visibilidade da rolagem e transição para decisão pendente. Execução anterior preservada em `338ecca4`.

Isso não testa toda a caixa base, todos os exploits, partida completa com pessoas, internet ou Steam. Estado/fixtures de QA não são um playtest da missão oficial.
