# Origem e matriz de fidelidade

Fonte primária: [manual CMON ZCD001](https://www.cmon.com/wp-content/uploads/2023/06/ZCD001_rulebook_WEB.pdf), 68 páginas; SHA-256 `a2f43007acb6cdeccc290219f6af079273f29e5bd654b1ab9e837f3e6658e9ae`.

Acervo preservado no hub: `acervo/jogos/zombicide/2e-core-en-zcd001/`. Catálogo: `catalogo/jogos/zombicide/2e-core-en-zcd001/`. Sem copiar o PDF ou ilustrações para este repositório.

## Fatos e limites

M0 p.36: 1V/3V, dois objetivos, duas caixas, saída/início a sudoeste, dois pontos de spawn a norte; um Fatty, um Runner, dois Walkers. Objetivos dão 5 adrenalina; caixas dão armas especiais; fuga só ao fim da ativação com saída livre após coleta; todos devem escapar.

Mapa desenhado manualmente como dados próprios a partir do diagrama. [MAP-001](../specs/MAP-001.md) registra revisão visual de zonas, aberturas, portas e setup, confrontando pp.9–10/36. Geometria e cores procedurais não são os tiles oficiais. Revisão independente e partida completa ainda pendentes.

Baralho e elenco de laboratório devem ter identificação explícita. Não inventar 40 cartas oficiais nem atribuir árvores de skills não verificadas. Protótipo pode usar peões sem habilidades individuais para testar regras base, com essa diferença visível, mas não pode apresentar esse modo como M0 integral fiel.

## Dados efetivamente implementados nesta entrega

| Área | Estado real | Fonte/limite |
| --- | --- | --- |
| Setup e objetivos | Seis peões, dois objetivos e duas caixas; Runner e Fatty juntos no norte, Walkers no centro e sul | p.36; transcrição visual revisada em MAP-001 |
| Equipamento inicial | Três pistolas, um machado, um pé de cabra e um taco, distribuídos aleatoriamente | Quantidades p.4; taco e parte dos stats ainda de teste |
| Equipamento de busca | Dez cartas de laboratório; pistola/machado/pé de cabra/escopeta/Molotov/provisões/Aaahh!! | Não reproduz quantidades/probabilidades da caixa; provisões sem efeito de consumo implementado |
| Arma especial | Duas instâncias de fixture `special` | Não é inventário das 11 cartas Pimpweapon oficiais |
| Spawn | Quatro entradas alternando dois exemplos Walker | Valores das linhas ilustradas pp.15/25; não é deck oficial, sem Rush/extra card real |
| Sobreviventes | Preset Amy e Elle, com árvores conferidas; quatro peões adultos genéricos. Opção de seis genéricos | Amy p.7, Elle p.15, efeitos pp.63/65; genéricos continuam pausando no laranja. Retratos/modelos não são a aparência oficial |
| Mapa | 12 zonas: sete salas e cinco ruas; três portas externas; duas salas escuras por edifício | pp.9–10/36, MAP-001; substitui 18 células, preserva ruas sobre a emenda e sala alongada; arte ainda esquemática |
| Arte | Direção B escolhida: PNGs image_gen, ícones próprios, nove miniaturas estáticas Blender/GLB e UI de cartões | [Procedência B-001](../arte/producao/b-001/README.md); nenhuma imagem/modelo oficial ou de terceiros no runtime; modelos são estudos, não fichas oficiais |

Essas lacunas impedem chamar a entrega de M0 integral fiel. O objetivo aprovado continua sendo preencher e validar o conteúdo oficial, sem redefinir silenciosamente o design como jogo diferente. [CONTENT-001](../specs/CONTENT-001.md) registra a cobertura mecânica atual e a pistola corrigida para 3+ conforme p.13. [Inventário documental](inventario-caixa.md) transcreve as quantidades da p.4, sem alegar todos os atributos ou baralhos implementados. O usuário não tem acesso ao material físico; pesquisa pública continua necessária para os dados restantes.

## Fontes técnicas

- [Godot 4.7 multiplayer](https://docs.godotengine.org/en/4.7/tutorials/networking/high_level_multiplayer.html).
- [Camera3D 4.7](https://docs.godotengine.org/en/4.7/classes/class_camera3d.html).
- [Steam lobbies](https://partner.steamgames.com/doc/features/multiplayer/matchmaking).

Versões e resultados em progress.md. Arte própria produzida por código e image_gen; prompts, blueprint, scripts, fontes .blend e manifesto em arte/producao/b-001. Não houve engenharia reversa de aplicativo Zombicide ou incorporação de assets oficiais de referência.

Refinamento [B-002](../arte/producao/b-002/README.md): quatro novas miniaturas próprias Blender substituem as equivalentes B-001; fontes `.blend`, relatório e hashes preservados. Fonte externa **Barlow Condensed Bold**, Copyright 2017 The Barlow Project Authors, distribuída sob **SIL OFL 1.1**, com licença em `src/assets/b/fonts/OFL.txt` e URL/arquivo/hash no manifesto B-002. A declaração de ausência de imagens/modelos externos não inclui essa fonte tipográfica licenciada. B-002 não alterou regras/save; a rodada posterior CONTENT-001 passa a `m0-lab-v3-skills`.
