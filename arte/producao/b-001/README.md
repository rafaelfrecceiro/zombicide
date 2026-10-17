# B-001 — Primeira amostra implementada

Direção escolhida pelo usuário: **B — Quadrinhos Urbanos**, D-016 (“a B”), 17/10/2026. É a direção vigente; A/C e a recomendação anterior ficam preservadas como histórico. Esta amostra não encerra produção/qualidade visual nem paridade de regras.

## Conteúdo real

- Tabuleiro original ilustrado `src/assets/b/board-v1.png`, criado com image_gen integrada a partir de blueprint próprio e mockup B como referência de estilo. Guia editável em `blueprint.py`, prompts integrais nesta pasta. O plano usa 12×6 unidades no Godot; MAP-001 continua a fonte de zonas/portas. A ilustração não define colisão, movimento ou cobertura.
- Retratos originais `src/assets/b/portraits-v1.png`, atlas 3×2 com seis adultos anônimos de estudo, não transcrição de fichas oficiais. [AtlasTexture 4.7](https://docs.godotengine.org/en/4.7/classes/class_atlastexture.html) recorta regiões no runtime, preservando PNG fonte. O cartão e a ficha ativa compartilham o mesmo índice.
- Nove modelos rígidos originais: seis variantes de sobrevivente e Walker/Runner/Fatty. Modelagem procedural composta no Blender **5.2.2 LTS**, exportada a GLB e importada no Godot **4.7.2**. `.blend` editáveis em `blender/`; script reproduzível `build_miniatures.py`; GLBs independentes em `src/assets/b/models/`. Nenhum rig/animação corporal.
- Materiais foscos com cores pintadas e contorno por segunda passagem. Fonte inicial das cores é sRGB, convertida para linear no Blender; corrigido após captura mostrar materiais claros demais. Sombreamento Lambert foi preferido ao Toon após inspeção em Compatibility. [Spatial shaders 4.7](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/spatial_shader.html) consultados; nenhuma alegação de cel shading final.
- UI: cartões creme, texto escuro, seleção ciano, ação ativa vermelha, retrato correspondente, ações/vida/adrenalina e decisão em destaque. Ícones SVG próprios para objetivo/caixa/saída/spawn. Fonte fallback do Godot; tipografia condensada e sistema gráfico completos ainda pendentes.
- Peça inteira se desloca em 300 ms; reduzir movimento nas opções torna a mudança instantânea. Estado/regras independentes. Atualização dupla da interface inicialmente cancelava o tween; corrigida preservando posição visual antes de reconstruir os nós.
- Câmera enquadra limites projetados para vista inclinada/superior/rotação. Grupo denso limita exibição a 4 peças em zona estreita ou 8 em larga e mostra contagem total; os demais atores continuam no estado e nas decisões de combate.

## Reproduzir os modelos

Da raiz do repositório, após editar o script:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python-exit-code 1 --python arte/producao/b-001/build_miniatures.py
& Godot_v4.7.2-stable_win64_console.exe --headless --editor --path ./src --import --quit
```

Comandos executados nesta rodada. Primeiro comando gera novamente fontes/GLBs da amostra; backups `.blend1` ficam ignorados. Blender emitiu depreciação de `Material.use_nodes` para versão futura; execução 5.2.2 concluiu `MINIATURES_COMPLETE 9`. Contagens efetivas de triângulos em `model-report.json`: 6.952–8.144 por modelo, 11–12 materiais, sem rig. São contagens geométricas, não medidas de FPS.

## Evidência e limites

QA atual e caminhos de execução no [progress.md](../../../progress.md) e [qa/README.md](../../../qa/README.md). Capturas reais versionadas em `qa/artifacts/b-001/`; cobrem 1280×800 e 1920×1061 reais (pedido 1920×1080 limitado pela janela do desktop), dados, movimento amostrado antes/durante/depois, câmera e grupo denso de 15 zumbis. Posições e frames foram amostrados durante execução real; isso não é playtest humano nem avaliação contínua de fluidez/performance.

Limites materiais: miniaturas ainda são estudo procedural de formas simples, abaixo do acabamento do mockup. A arma esculpida é detalhe genérico da amostra, sem trocar conforme inventário; regra consulta a carta equipada. Não são seis sobreviventes oficiais nem skills validadas. Abominação reutiliza silhueta de Fatty como fallback de laboratório; conteúdo oficial dessa ameaça não é alegado completo.

Piso gerado contém marcações rodoviárias e pequenas divergências de aberturas; conexões visuais em cima corrigem passagens do modelo lógico. Ilustração completa ainda precisa revisão de acabamento; SVG/mapa lógico/fontes editáveis não tornam o PNG gerado uma pintura em camadas. Lista de inspeção individual de grupo denso, áudio, seleção por teclado completa, tipografia final, retrabalho artístico e medição de GPU continuam pendentes.

Procedência: image_gen integrada para PNGs; blueprint/código/modelos/ícones próprios desta rodada; sem imagens/modelos oficiais incorporados. Os estudos de retrato são identidades visuais provisórias, sem decisões de design de habilidades. Manifesto de arquivos com dimensões/hashes acompanha esta pasta. Assets de produção não dependem do acervo ou do diretório de imagens geradas do Codex.
