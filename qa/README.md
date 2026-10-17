# QA da primeira entrega técnica

Ambiente: Godot 4.7.2.stable.official.ed1daf0bf, Windows, renderer Compatibility. Render real observado em Intel Iris Xe / OpenGL 3.3. Sem medição de FPS ou playtest humano.

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

Isso não testa toda a caixa base, todos os exploits, partida completa com pessoas, internet ou Steam. Estado/fixtures de QA não são um playtest da missão oficial.
