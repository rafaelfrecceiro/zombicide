# Direções de arte — Zombicide online

Estado em 17/10/2026: **B — Quadrinhos Urbanos escolhida pelo usuário, D-016; primeira amostra implementada**. Pedido: “agora eu quero ja as direções de arte do jogo, para começar a ver direito”. [Galeria](arte/direcoes/README.md) · [Progresso](progress.md) · [Decisões](decisoes.md) · [Mapa lógico](specs/MAP-001.md).

## Briefing e evidências

Escolhas aceitas: PC/Steam, mesa física 3D preferida, miniaturas rígidas, automação e rolagem acionada pelo jogador. “Pinos” descreve comportamento estático, não obriga cones abstratos. As três opções usam figuras humanas esculpidas sobre bases. Top-down 2D permanece alternativa, não prioridade desta apresentação.

FATO OBSERVADO: primeiro contato humano rejeitou a apresentação e relatou dificuldade para entender o protótipo. UX-001 tratou orientação, mas falta reteste humano. Geometria procedural existente não é direção escolhida.

Referências analisadas: [análise visual do boardgame](../../ideias/zombicide-online/analise-arte.md), com pp.9/12/16/17/36 do manual ZCD001 preservado. Observados cidade impressa em vista superior, personagens ilustrados de contorno marcado, cartas com imagem/estatísticas, painel de mãos/mochila/adrenalina e ameaças diferenciadas por volume/pose. Resina, cel shading e maquete nas opções abaixo são PROPOSTAS próprias. Não houve inspeção presencial de miniaturas nem comparação adicional de jogos digitais nesta rodada.

## Comparação visual e limites

Briefing comum: ataque com pistola na M0, rodada 1, objetivos 0/2, caixas 0/2, sobrevivente 01 ativo com duas ações e vida 3/3, seis retratos, prévia de alvo e acesso à rolagem. Câmera ortográfica inclinada, norte para cima, mesa à esquerda, ficha/ações à direita, sobreviventes embaixo. Sem animação corporal. Comparar linguagem e composição, não apenas cores.

Geração nova pela ferramenta integrada **image_gen**, uma chamada por direção. PNGs retornados em **1672×941 RGB**, próximos de 16:9; alvo de produção proposto 1920×1080. Imagens inspecionadas e arquivos verificados, com hashes no [manifesto](arte/direcoes/manifesto.json). Prompts integrais junto de cada arquivo. Não são screenshots Godot, modelos 3D nem assets oficiais incorporados.

Desvios observados: A omite o Walker junto do ativo, repete vida incorretamente e acrescenta decoração externa; A/B omitem a faixa de instrução pedida; C não associa corretamente retrato/base da peça ativa e mostra alvo entre zonas. Todas omitem parte dos limites de rua. Profundidade aparente de A/B será traduzida em ilustração plana, não arquitetura real. Esses detalhes não são decisões aprovadas. MAP-001 e estado da engine seguem como autoridade de posições, zonas, contagens e portas.

## A — Mesa de Colecionador

![A — conceito](arte/direcoes/a-mesa-colecionador/gameplay-v1.png)

**Tese:** uma caixa de boardgame bem apresentada numa mesa digital. Cidade impressa, miniaturas de resina e componentes táteis, com interface discreta.

- Pilares: presença física, organização de componentes e clareza das decisões.
- Personagens: proporção adulta, pose fixa expressiva, armas legíveis. Resina cinza fria fosca com sombreamento de cavidades; bases de jogadores coloridas e numeradas. Zumbis cinza-esverdeados, bases de ameaça e silhuetas estreita/corredora/volumosa.
- Cenário: tiles planos ilustrados, espessura de cartão, desgaste moderado, móveis impressos, borda curta de madeira. Portas e tokens destacáveis. Luz neutra ampla, sem efeitos que apaguem zonas.
- Paleta proposta: carvão `#202426` HUD; marfim `#E9E0CD` texto/cartas; concreto `#858B86`; madeira `#5A4030`; ciano `#42C8D4` seleção; âmbar `#E9AE46` alcance; vermelho `#C64E45` risco. Cores não são amostras oficiais.
- UI: títulos condensados sem serifa, corpo humanista regular, ícones lineares com rótulo. Ficha vertical, equipamento em cartão impresso, ações em coluna. Dados aparecem quando solicitados. Textura fora das áreas de texto pequeno.
- Movimento/VFX: elevar e deslizar a peça inteira, assentamento curto e base ativa contornada. Sem caminhada/idle/ataque corporal. Dados legíveis com resultado persistente, sem espetáculo obrigatório.
- Referência/princípio: tiles, cartas e painel físico do manual; resina e mesa são proposta própria.
- Custo relativo **médio**: esculturas e bases, materiais simples compartilhados, cidade ilustrada sem modelar cada móvel. Escultura/retopologia ainda exigem trabalho.
- Riscos: monocromia confunde atores em aglomeração; silhueta/número/contagem precisam compensar. Textura de piso pode competir com marcadores; resina pode parecer incompleta a quem prefere peças pintadas.

[Prompt integral A](arte/direcoes/a-mesa-colecionador/prompt.md).

## B — Quadrinhos Urbanos

![B — conceito](arte/direcoes/b-quadrinhos-urbanos/gameplay-v1.png)

**Tese:** energia de quadrinhos em miniaturas pintadas e cartões gráficos, mantendo tabuleiro plano.

- Pilares: personalidade, leitura por silhueta e contraste imediato das ações.
- Personagens: cabeças/mãos/armas levemente ampliadas, poses fixas distintas, pintura em massas de cor e duas sombras, contorno escuro. Retratos expressivos; sem chibi. Runner inclinado, Fatty largo/triangular, Walker vertical/irregular.
- Cenário: tile ilustrado com contornos, mobiliário simplificado e contraste baixo; textura de papel restrita. Volume nas peças e tokens. Mesa preta fosca com bordas gráficas, sem arquitetura alta.
- Paleta proposta: tinta `#191C1D`, creme `#EFE3CB`, vermelho `#D44234`, petróleo `#277E86`, ocre `#C99A4B`, zumbi `#889581`. Seleção ciano e alvo âmbar mantêm função. Ícones separam perigo de identidade.
- UI: cabeçalhos pesados condensados e corpo regular; cartões creme/texto preto; abas angulares só em títulos. Ações 2×2 com ícones grandes e rótulos. Retícula nas ilustrações, nunca sob números. Retrato recolhe para liberar decisão/dados.
- Movimento/VFX: elevação da peça e carimbo breve de comando aceito, traço de alvo e flash de impacto contido. Sem onomatopeias gigantes ou tremor obrigatório. Acertos de dados contornados com legenda.
- Referência/princípio: contornos, expressão e sinalização editorial do manual; cel shading/cartões digitais são proposta própria.
- Custo relativo **médio**: esculturas simplificadas, mas exige consistência de pintura, retratos e shader de contorno em Compatibility. Cenário continua ilustrado.
- Riscos: abas/retículas/cores podem saturar a tela, cores de roupa podem se confundir com perigo; armas exageradas não devem sugerir regra inexistente. Vantagem de leitura ainda precisa teste.

[Prompt integral B](arte/direcoes/b-quadrinhos-urbanos/prompt.md).

## C — Diorama Urbano

![C — conceito](arte/direcoes/c-diorama-urbano/gameplay-v1.png)

**Tese:** cidade em miniatura com arquitetura baixa e objetos em volume, peças pintadas e HUD tático sóbrio.

- Pilares: maquete física, detalhe inspecionável e interface contida.
- Personagens: proporções adultas, pintura com desgaste moderado, roupa/arma reconhecíveis, poses rígidas e bases numeradas. Perfil de volume distingue ameaças; detalhe facial pertence ao retrato e ao zoom.
- Cenário: paredes modulares baixas, calçadas rasas e poucos móveis 3D. Concreto/madeira/metal foscos, luz superior suave. Paredes até 20–30% da altura da miniatura, com opção de ocultar. Não depender de neblina, escuridão ou pós-processamento.
- Paleta proposta: ardósia `#24323D`, concreto `#7C8585`, oliva `#73745B`, madeira `#876C50`, marfim `#E0DDD4`. Seleção `#42C8D4`, alvo `#E9AE46`, dano `#C64E45`. Separação por valor e contorno, não só cor.
- UI: sans neutra, painéis escuros sólidos, bordas finas, cartas compactas. Retrato/nome/base precisam corresponder. Ações em coluna, bandeja escura e consequência textual ao lado das faces.
- Movimento/VFX: levantamento/assentamento físicos, sombras moderadas e contorno da base. Foco de câmera opcional, sem mudança automática a cada ação. Dados 3D e horda sequencial com velocidade ajustável.
- Referência/princípio: disposição física do manual; maquete volumétrica e HUD tático são propostas próprias, não características observadas do tabuleiro.
- Custo relativo **alto**: miniaturas mais kit modular de cenário, materiais, ocultação, agrupamento/LOD e seleção sob oclusão. Sem prazo ou FPS medido. Retornar a piso plano permite simplificar sem mudar regras.
- Riscos: objetos sugerem cobertura/colisão inexistentes, paredes escondem atores e custo aumenta em GPU integrada. Conferir aglomeração, câmera em movimento e vista superior.

[Prompt integral C](arte/direcoes/c-diorama-urbano/prompt.md).

## Comparação e recomendação

Avaliação de produção, não resultado de usuários ou benchmark:

| Critério | A — Colecionador | B — Quadrinhos | C — Diorama |
| --- | --- | --- | --- |
| Identidade | Mesa tátil, resina | Gráfica, pintada, expressiva | Maquete urbana pintada |
| Cenário de produção | Tile plano ilustrado | Tile plano com contornos | Paredes/móveis em volume |
| Ganho proposto | Componentes separados e menos materiais por peça | Silhuetas ampliadas e cartões contrastantes | Contexto espacial e HUD sóbrio |
| Principal risco | Monocromia e textura do piso | Ruído gráfico/cromático | Oclusão e falsa regra |
| Esforço relativo | Médio | Médio | Alto |
| Blender | Esculturas/bases | Esculturas/pintura | Esculturas/cenário/otimização |

**Recomendação apresentada antes da escolha: A**, por aproximar a mesa física pedida e concentrar modelagem nas miniaturas. Provar primeiro um tile e uma peça legível. É possível solicitar A com miniaturas pintadas de B; ajuste depende da escolha do usuário. C é um caminho mais caro se o volume do cenário for prioridade.

## UI/HUD comum proposto

- Alvos PC: 1920×1080 e 1280×800, com escala ajustável; 2560×1440 para conferência posterior. Mobile fora desta etapa.
- Em 1920: margens 24 px, topo ~72 px, coluna direita 360–400 px, sobreviventes em faixa de 120–144 px; resto para mesa. Corpo 18–20 px, títulos 26–32 px; reorganizar em 1280×800 sem encolher todo texto.
- Hierarquia: próximo passo → ator/ações → zonas/ameaças → equipamento → log. Ficha detalhada recolhível e decisão atual em destaque. Retrato e bandeja não devem ocupar espaço quando dispensáveis.
- Seleção por contorno/número/nome; perigo por ícone/texto. Zona legal por borda/textura/rótulo de custo. Porta aberta/fechada e conexão explícitas. Decoração não cria bloqueio.
- Estados: normal sólido, hover por borda, foco de teclado duplo, pressionado com deslocamento mínimo, ativo marcado com texto, desabilitado com razão consultável, erro persistente sem depender de som. Tooltips acessíveis também por foco/inspeção.
- Grupo denso: resumo por tipo/quantidade no canto da zona, lista de atores ao inspecionar; não empilhar rótulos sobre peças. Testar clique sobre decoração e minis.
- Dados: botão LANÇAR após comando legal, faces grandes, acertos/dano/consequências textuais; quantidade e resultado vêm da regra, não da física ou decoração dos mockups.
- Acessibilidade: escala de texto, redução de movimento, sem tremor/flash obrigatórios, ícones além de cor. Contraste/navegação exigem validação real.

## Produção proposta após a escolha

Parâmetros iniciais sujeitos ao teste Godot, não budgets medidos:

| Entrega | Fonte/formato/escala | Estados/observações | Prioridade |
| --- | --- | --- | --- |
| Tile de prova | Fonte editável + PNG 2048² por tile; camadas de piso/móveis/desgaste | Texto crítico e limites/alcance na engine; separado do mapa lógico | P0 |
| Sobrevivente de prova | `.blend` + `.glb`; base 0,32 unidade, figura ~0,65 acima dela; origem centro inferior, frente -Z/cima +Y | Pose fixa, base/figura com materiais separados; número na engine | P0 |
| Walker/Runner/Fatty | Mesmo pipeline e escala relativa | Perfis legíveis à distância; instâncias sem rig, material compartilhável | P0 |
| Portas e tokens | GLB/geometria simples; pivô de porta na dobradiça | Aberto/fechado/coletado, símbolo e cor | P0 |
| UI/retrato de prova | Ícones SVG, painéis Godot, retrato PNG 512² | Estados reais, não imagem fundida como interface | P0 |
| Kit C | GLBs modulares, grade do tile, materiais comuns | Somente se C escolhida; ocultação/seleção precisam teste | P1 |
| Elenco/cartas completos | Mesma linguagem da amostra aprovada | Expandir após demonstrar leitura/silhueta/custo | P1 |

GLB no runtime, fontes Blender preservadas; conceitos ficam fora de `src/`. Orçamento candidato: 8–15 mil triângulos por sobrevivente de prova e 3–8 mil por zumbi; materiais/atlas compartilhados na horda. Sombras por ator não são requisito obrigatório. Ajustar após perfil real, sem assumir FPS. A/B dispensam kit de cenário em volume.

Tempos candidatos: seleção 100–150 ms, elevar/deslizar/assentar 250–400 ms, rolagem 600–900 ms com resultado legível; opção de duração zero. Interromper apresentação não repete regra já resolvida. Sem animação corporal nesta fase.

Procedência: conceitos gerados nesta sessão com briefings originais, sem imagens oficiais como entrada. Não são alegação de exclusividade nem pacote visual recuperado do boardgame. Fontes tipográficas e demais assets externos de produção terão fonte/licença registradas antes de incorporar; nenhuma fonte externa instalada nesta rodada.

Atualização B-002: Barlow Condensed Bold incorporada ao projeto, sem instalação global, com SIL OFL 1.1 e fonte registrada no [manifesto de produção](arte/producao/b-002/manifesto.json). A nota acima descreve a rodada inicial dos conceitos.

## Escolha e validação

**Escolha aceita: B — Quadrinhos Urbanos**, resposta “a B”, D-016 em 17/10/2026. A recomendação A não foi adotada; A/C e prompts ficam preservados como histórico. Iterar na B sem reabrir a escolha para cada asset.

Recorte de validação da B: um tile, um sobrevivente, três tipos de zumbi, portas/tokens e painel funcional. Conferir seleção, alcance, dados, grupo denso e correspondência retrato/base/peça em 1920×1080/1280×800, com câmera em movimento e superior. Medir contraste/performance e retestar leitura com usuário antes de ampliar.

Rodada de apresentação: três conceitos estáticos inspecionados, sem implementação naquele momento. Após D-016, [amostra B-001](arte/producao/b-001/README.md) integrada à cena: PNG de tabuleiro, atlas de seis retratos, nove modelos estáticos Blender/GLB, cartões creme/contornos e deslocamento da peça inteira em 300 ms. Materiais usam Lambert e contorno após testes em Compatibility; cel shading e tipografia condensada finais seguem pendentes. QA real em 1280×800 e 1920×1061 (janela solicitada 1920×1080 limitada pelo desktop), com amostragem de posições/frames de movimento e câmera; sem playtest humano ou benchmark. Miniaturas ainda têm acabamento bem inferior ao mockup. Evidências atuais no progress.md; a escolha da direção não aprova automaticamente essa primeira execução.

**Iteração vigente: [B-002](arte/producao/b-002/README.md), autorizada em D-017.** Sobrevivente 01 e três zumbis usam novas malhas conectadas, detalhes de roupa/rosto e poses distintas. Galeria de GLBs reais para inspeção; arma visível correspondente à mão selecionada nos quatro acessórios suportados. Cinco sobreviventes permanecem B-001. Tipografia condensada implementada em títulos/botões; janelas claras, foco legível, bandeja de dados e prévia com valores calculados pelo motor. Lista de inspeção cobre horda resumida no tabuleiro. Capturas reais inspecionadas nas duas dimensões acima; acabamento continua de estudo e não reproduz integralmente o conceito. Reteste humano e perfil de desempenho ainda necessários antes da expansão visual.
