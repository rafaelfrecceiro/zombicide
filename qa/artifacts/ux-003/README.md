# CONTENT-001 / UX-003 — capturas reais

Godot 4.7.2.stable.official.ed1daf0bf, Compatibility/OpenGL 3.3, Intel Iris Xe, Windows. Execução em 17/10/2026; não são conceitos image_gen. [Progresso único](../../../progress.md), [conteúdo](../../../specs/CONTENT-001.md), [menus](../../../specs/UX-003.md).

| Execução local preservada | Resultado |
| --- | --- |
| `qa/runs/a56d0205/` | 72/72 regras, 27/27 habilidades, 27/27 UI headless, 29/29 UI GPU; dois processos host/client aprovados |
| `qa/runs/skills-ui-delivery-1280x800/` e `...-1920x1080/` | 31/31 layout, 17/17 refinamento, 10/10 arte por tamanho |
| `qa/runs/session-menu-delivery-1280x800/` e `...-1920x1080/` | 19/19 menu por tamanho, incluindo feedback de save/carga |

Logs completos permanecem em qa/runs ignorado; `results.json` versiona os resultados e caminhos. Logs finais conferidos sem SCRIPT ERROR/ERROR. Dimensões dos PNGs lidas nos arquivos: **1280×800 / 1920×1061**. A janela solicitada em 1920×1080 foi limitada pelo desktop; não afirmar Full HD exato testado.

- `menu-1280.png`, `menu-1920.png`: entrada na M0, preset parcial explícito.
- `options-1280.png`, `friends-1280.png`: Central da Missão com abas/janelas próprias.
- `amy-ready-1280.png`: ações com movimento gratuito.
- `skill-choice-1280.png`, `skill-choice-1920.png`: decisão laranja; fixture injeta adrenalina para verificar apresentação. Não representa partida completa até esse nível.

Frames/estados intermediários e finais de peça/câmera foram exercitados na matriz de regressões. Hover/câmera do layout usam Tween real pausado/custom_step para amostrar o intermediário e depois retomam. Não há benchmark, observação humana contínua de fluidez, aprovação de beleza/compreensão, internet ou Steam. Modelos/retratos continuam estudos originais, sem alegação de aparência oficial de Amy/Elle. Preset tem outras quatro fichas genéricas e decks parciais.
