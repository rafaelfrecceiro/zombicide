# Decisões — Zombicide online / projeto

## Aceitas

| ID | Data | Decisão | Origem e consequência |
| --- | --- | --- | --- |
| D-001 | 17/10/2026 | Criar uma sessão de ideias e documentar a análise em Markdown | Pedido do usuário; manter exploração em `ideias/zombicide-online/` |
| D-002 | 17/10/2026 | Usar Zombicide 2ª edição, moderno, como base | Resposta explícita do usuário à pergunta de edição; não misturar Black Plague, Invader ou 1ª edição |
| D-003 | 17/10/2026 | Preparar uma futura adaptação/clone online em Godot | Objetivo expresso pelo usuário; não fixa versão, plataforma, câmera ou hospedagem |
| D-004 | 17/10/2026 | Priorizar bastante fidelidade ao boardgame Zombicide 2ª edição moderna | Usuário respondeu “queria com bastante fidelidade”; preservar regras e experiência como referência, sem aprovar mudanças de regras ou definir a apresentação visual |
| D-005 | 17/10/2026 | Usar o repositório GitHub informado como destino dos commits do jogo | Usuário indicou [rafaelfrecceiro/zombicide](https://github.com/rafaelfrecceiro/zombicide.git); a memória de incubação continua neste hub até formalização |
| D-006 | 17/10/2026 | Preferência por mesa física com miniaturas 3D; tabuleiro top-down 2D como alternativa se a complexidade não compensar | Preferência explícita do usuário, que informa ter Blender disponível. Não fixa estilo, câmera, modelos ou início de desenvolvimento |
| D-007 | 17/10/2026 | Miniaturas inicialmente rígidas, em pose fixa, funcionando como pinos de boardgame | Usuário confirmou “paradas inicialmente, como se fossem pinos”; movimento da peça inteira entre posições, sem animação corporal de caminhada ou ataque. Formato dos modelos e transição visual ainda abertos |
| D-008 | 17/10/2026 | Priorizar PC/Steam na versão inicial; estudar possível adaptação mobile posteriormente | Escolha explícita do usuário. Mobile não é requisito do primeiro recorte; sistemas operacionais de PC, controle e integrações específicas Steam ainda não definidos |
| D-009 | 17/10/2026 | Automatizar integralmente a aplicação das regras e impedir ações ilegais; preservar decisões dos jogadores previstas nas regras | Escolha explícita do usuário. Sistema valida turno, recursos, equipamento, alcance, condições e exceções, aplica consequências e solicita escolhas humanas quando cabíveis |
| D-010 | 17/10/2026 | Rolagens que cabem ao jogador são iniciadas por ele numa interface de dados | Usuário quer “jogar manualmente”, por exemplo abrindo uma tela de dados. O sistema calcula os dados aplicáveis, gera o resultado e aplica as regras. Não implica digitar resultados, escolher faces ou rerrolar livremente; física e gesto de lançamento ainda abertos |
| D-011 | 17/10/2026 | Online inicial somente entre amigos convidados, em salas privadas | Escolha explícita do usuário. Não incluir lista pública de salas nem busca de desconhecidos no escopo inicial. Método de convite e hospedagem ainda em aberto |
| D-012 | 17/10/2026 | Permitir salvar uma missão e continuar em outro dia | Usuário aceitou a proposta; preservar estado da missão, peças, equipamentos, ferimentos, baralhos e vez dos jogadores. Local de armazenamento e política de gravação ainda abertos |
| D-013 | 17/10/2026 | Pausar a partida quando um participante desconectar e aguardar seu retorno, sem transferir controle automaticamente | Usuário aceitou a proposta; retomada deve preservar estado e decisões pendentes. Tratamento da perda do anfitrião, timeout e retomada após fechar o jogo ainda precisam ser especificados |

| D-014 | 17/10/2026 | Formalizar e iniciar o recorte M0 | Usuário autorizou “pode seguir pra esse M0” após a proposta de primeiro recorte jogável; inclui seis sobreviventes, dois participantes, regras, dados, save e retomada |
| D-015 | 17/10/2026 | Priorizar a apresentação de direções de arte agora | Usuário pediu “agora eu quero ja as direções de arte do jogo, para começar a ver direito”; autoriza produzir alternativas, não consolida uma delas |
| D-016 | 17/10/2026 | Escolher B — Quadrinhos Urbanos | Usuário respondeu “a B” às três direções; miniaturas pintadas rígidas, tabuleiro ilustrado de contorno forte e interface de cartões claros. A/C preservadas como alternativas históricas; desenvolver amostra na engine antes de ampliar produção |

## Propostas de origem e situação atual

| ID | Proposta | Razão | Documento |
| --- | --- | --- | --- |
| P-001 | Recorte M0 com seis sobreviventes e dois clientes | Aceito como recorte em D-014; paridade de conteúdo ainda em andamento | [Recorte](specs/M0-001.md) |
| P-002 | Estado de regras separado da apresentação, com autoridade única | Evitar que animações e clientes discordem sobre o tabuleiro | [Online/Godot](specs/NET-001.md) |
| P-003 | Preservar o tabuleiro top-down 2D como alternativa de menor complexidade de apresentação | Recomendação inicial de 2D deixa de ser a principal após D-006; alternativa permanece disponível | [Arte](direcao-arte.md) |
| P-004 | Usar placeholders próprios no experimento | Validar regras antes da produção visual; não define redesign | [Arte](direcao-arte.md) |
| P-005 | Testar uma amostra de mesa 3D antes de produzir todo o conteúdo | Poses fixas aceitas em D-007; execução do experimento, tabuleiro plano e câmera continuam propostas para avaliar seleção, aglomeração e custo real | [Arte](direcao-arte.md) |
| P-006 | Preparar missão e distribuir os seis sobreviventes antes de abrir a mesa | Salas privadas por convite aceitas em D-011; sequência de preparação, integração de convites e hospedagem continuam propostas | [Online/Godot](specs/NET-001.md) |
| P-007 | A — Mesa de Colecionador | Recomendada: tile plano ilustrado e miniaturas de resina; esforço médio | [Arte e mockups](direcao-arte.md) |
| P-008 | B — Quadrinhos Urbanos | Escolhida em D-016; miniaturas pintadas, contornos e cartões gráficos; esforço médio | [Arte e mockups](direcao-arte.md) |
| P-009 | C — Diorama Urbano | Cenário em volume, miniaturas pintadas e HUD tático; esforço alto | [Arte e mockups](direcao-arte.md) |

Início de desenvolvimento autorizado em D-014, direção visual B escolhida em D-016. Não há decisão aceita sobre mudanças de regras, comercialização, expansões ou multiplayer assíncrono. Salas públicas ficam fora do escopo inicial por D-011.

## Escolhas técnicas reversíveis desta rodada

- T-001: Godot 4.7.2 disponível, GDScript e Compatibility; Windows para validação local.
- T-002: regras em RefCounted separadas da cena; host autoritativo ENet como primeiro laboratório. Integração Steam posterior.
- T-003: peças/mesa procedurais próprias, sem arte final; dados parciais explicitamente laboratório. Não substitui o objetivo de M0 fiel.
- T-004: MAP-001 usa áreas de tamanhos diferentes, não uma ação por célula. Versão de conteúdo `m0-lab-v2-map12` rejeita saves antigos, preservando arquivo e estado atual. É uma correção reversível da implementação, não alteração aprovada das regras físicas.

## Feedback observado — 17/10/2026

O usuário disse: “essas artes e layout são totalmente prototipos, certo? pois está horrivel, mal conseguir jogar algo, pois não entendi nada”. Isso registra rejeição da apresentação inicial e dificuldade de compreensão. Não é aprovação de nova arte nem de mudanças nas regras.

Resposta de implementação reversível: [UX-001](specs/UX-001.md), com guia de primeiros passos, contexto da ação e destinos legais. Naquele momento a direção final continuava em aberto. Depois, B foi escolhida em D-016; a nova apresentação na engine ainda depende de reteste humano.
