# Origem e matriz de fidelidade

Fonte primária: [manual CMON ZCD001](https://www.cmon.com/wp-content/uploads/2023/06/ZCD001_rulebook_WEB.pdf), 68 páginas; SHA-256 `a2f43007acb6cdeccc290219f6af079273f29e5bd654b1ab9e837f3e6658e9ae`.

Acervo preservado no hub: `acervo/jogos/zombicide/2e-core-en-zcd001/`. Catálogo: `catalogo/jogos/zombicide/2e-core-en-zcd001/`. Sem copiar o PDF ou ilustrações para este repositório.

## Fatos e limites

M0 p.36: 1V/3V, dois objetivos, duas caixas, saída/início a sudoeste, dois pontos de spawn a norte; um Fatty, um Runner, dois Walkers. Objetivos dão 5 adrenalina; caixas dão armas especiais; fuga só ao fim da ativação com saída livre após coleta; todos devem escapar.

Mapa desenhado manualmente como dados próprios a partir do diagrama. Zonas e portas ainda exigem revisão de paridade. Geometria e cores procedurais não são os tiles oficiais.

Baralho e elenco de laboratório devem ter identificação explícita. Não inventar 40 cartas oficiais nem atribuir árvores de skills não verificadas. Protótipo pode usar peões sem habilidades individuais para testar regras base, com essa diferença visível, mas não pode apresentar esse modo como M0 integral fiel.

## Dados efetivamente implementados nesta entrega

| Área | Estado real | Fonte/limite |
| --- | --- | --- |
| Setup e objetivos | Seis peões, dois objetivos e duas caixas; inimigos iniciais e saída | p.36, representação esquemática com paridade de topologia pendente |
| Equipamento inicial | Três pistolas, um machado, um pé de cabra e um taco, distribuídos aleatoriamente | Quantidades p.4; taco e parte dos stats ainda de teste |
| Equipamento de busca | Dez cartas de laboratório; pistola/machado/pé de cabra/escopeta/Molotov/provisões/Aaahh!! | Não reproduz quantidades/probabilidades da caixa; provisões sem efeito de consumo implementado |
| Arma especial | Duas instâncias de fixture `special` | Não é inventário das 11 cartas Pimpweapon oficiais |
| Spawn | Quatro entradas alternando dois exemplos Walker | Valores das linhas ilustradas pp.15/25; não é deck oficial, sem Rush/extra card real |
| Sobreviventes | Seis adultos anônimos sem habilidades individuais; amarelo +1 ação | Sem equivalência alegada às fichas; pausa no laranja evita árvore inventada |
| Mapa | 18 células, oito salas, quatro portas, duas salas escuras por edifício | Layout de laboratório a auditar; fronteiras reais podem atravessar tiles/células |
| Arte | Geometria e materiais procedurais próprios | Nenhuma imagem oficial em runtime, nenhum modelo de terceiros |

Essas lacunas impedem chamar a entrega de M0 integral fiel. O objetivo aprovado continua sendo preencher e validar o conteúdo oficial, sem redefinir silenciosamente o design como jogo diferente.

## Fontes técnicas

- [Godot 4.7 multiplayer](https://docs.godotengine.org/en/4.7/tutorials/networking/high_level_multiplayer.html).
- [Camera3D 4.7](https://docs.godotengine.org/en/4.7/classes/class_camera3d.html).
- [Steam lobbies](https://partner.steamgames.com/doc/features/multiplayer/matchmaking).

Versão executada e resultados em progress.md. Arte produzida por código neste repositório, sem assets externos. Não houve engenharia reversa de um aplicativo Zombicide.
