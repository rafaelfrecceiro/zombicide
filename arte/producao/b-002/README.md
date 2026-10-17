# B-002 — Refinamento da amostra Quadrinhos Urbanos

Recorte autorizado em D-017, mantendo a direção B escolhida em D-016. Entrega de implementação e revisão técnica; qualidade artística e compreensão humana continuam em validação.

## Miniaturas editáveis

Quatro modelos próprios substituem os equivalentes B-001 no runtime: Sobrevivente 01, Walker, Runner e Fatty. Fontes independentes em `blender/*.blend`, GLBs em `src/assets/b/refined/`. Os outros cinco sobreviventes conservam os modelos B-001; não são seis esculturas refinadas nem fichas oficiais.

`build_refined.py` constrói troncos/cabeças por anéis conectados, membros afunilados, dobras, bolsos, lapelas, cabelo, mochila e detalhes de rosto. Walker inclinado, Runner em passada assimétrica e Fatty largo têm poses rígidas distintas. O sobrevivente tem quatro acessórios separados, visíveis conforme a mão selecionada: pistola, machado, pé de cabra e taco. Armas sem acessório correspondente ficam sem arma esculpida; a carta sempre determina a regra. Sem rigs ou animação corporal.

Blender **5.2.2 LTS**, Godot **4.7.2**, Compatibility. Relatório real: sobrevivente 8.520 triângulos incluindo acessórios ocultos; Walker/Runner 6.920 cada; Fatty 7.508. Normalização de importação 0,66 antes da escala de cada peça. Contagens não são benchmark. Materiais/contorno usam o pipeline B-001. Os modelos ainda têm geometria angular e acabamento de estudo, inferior ao conceito B; ampliar esculturas depende da revisão desta amostra.

O botão **Miniaturas** abre os quatro GLBs reais numa galeria giratória, em um mundo 3D isolado atualizado somente enquanto visível. Nomes em UI evitam oclusão pelos pedestais. Não são imagens conceituais fundidas ao jogo.

## Combate e leitura

- Prévia e execução consultam `rules.attack_info`: arma, alcance/visão, compatibilidade dual, custo, quantidade de dados, precisão e dano. A prévia não altera estado/RNG; confirmar prepara a decisão de rolagem.
- Bandeja desenha faces que correspondem aos resultados autoritativos. O jogador continua acionando LANÇAR; movimento visual não sorteia novamente nem decide acertos.
- Resumo de acertos vem do evento real de regras. Escolhas adicionais de alocação continuam no fluxo existente. Não foi implementado um relatório completo de todas as consequências por inimigo.
- **Inspecionar zona** lista todos os sobreviventes e zumbis da zona selecionada, incluindo figuras resumidas na mesa. Conteúdo rolável; IDs permitem distinguir atores.
- Títulos/botões usam Barlow Condensed Bold; janelas claras e foco têm texto escuro. Corpo conserva fonte de leitura do Godot. Navegação completa por teclado, escala configurável e contraste medido continuam pendentes.

Tabuleiro ilustrado e retratos B-001 preservados. Esta rodada não repinta o piso nem completa cartas, skills ou integração Steam.

## Fonte externa e procedência

**Barlow Condensed Bold**, Copyright 2017 The Barlow Project Authors, [projeto original](https://github.com/jpt/barlow), **SIL Open Font License 1.1**. Binário e licença incluídos em `src/assets/b/fonts/`. Obtidos sem modificação do [arquivo Google Fonts](https://raw.githubusercontent.com/google/fonts/main/ofl/barlowcondensed/BarlowCondensed-Bold.ttf) e da [licença correspondente](https://raw.githubusercontent.com/google/fonts/main/ofl/barlowcondensed/OFL.txt). Sem instalação global. Manifesto registra SHA-256 e bytes.

Modelos/scripts novos são próprios, produzidos por código Blender, sem modelos oficiais ou externos como entrada. Nenhuma geração de imagem nova nesta rodada. PNGs anteriores e sua procedência continuam em B-001. Nenhuma dependência do acervo em runtime.

## Reproduzir e verificar

Na raiz do repositório:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python-exit-code 1 --python arte/producao/b-002/build_refined.py
Godot_v4.7.2-stable_win64_console.exe --headless --editor --path ./src --import --quit
.\qa\run-tests.ps1 -Render
```

Construção executada com exit code 0, `REFINED_COMPLETE 4`. O script importa utilitários B-001; o bloco de execução antigo agora tem proteção `__main__`, evitando regenerar assets anteriores ao importar. Fontes B-001 preservadas.

`qa/refinement_test.gd` exercita os quatro modelos/arma, mundo isolado, prévia dual sem mutação, confirmação, rolagem, correspondência das faces, ausência de nova aplicação de combate pela apresentação, rejeição de alvo ilegal e lista completa da horda. Capturas de galeria, rolagem pendente/resultado, prévia e inspeção em [qa/artifacts/b-002](../../../qa/artifacts/b-002/). Resultados consolidados no único [progress.md](../../../progress.md). Frames de movimento são amostrados por `art_test.gd`; não houve playtest humano ou medição de FPS.

Referências técnicas consultadas: [AcceptDialog 4.7](https://docs.godotengine.org/en/4.7/classes/class_acceptdialog.html), [Control 4.7](https://docs.godotengine.org/en/4.7/classes/class_control.html), [BaseButton 4.7](https://docs.godotengine.org/en/4.7/classes/class_basebutton.html).
