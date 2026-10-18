# CONTENT-001 — Fichas verificadas e lacunas da M0

Data: 17/10/2026. Requisitos: D-004, D-009, D-019. Execução e evidências somente em [progress.md](../progress.md).

## Fonte e confiança

**FATO OBSERVADO:** manual oficial inglês [CMON ZCD001](https://www.cmon.com/wp-content/uploads/2023/06/ZCD001_rulebook_WEB.pdf), 68 páginas, SHA-256 `a2f43007acb6cdeccc290219f6af079273f29e5bd654b1ab9e837f3e6658e9ae`. Fonte preservada no acervo do hub. Inspeção visual ampliada nesta rodada: pp.7, 13, 14 e 15. Glossário pp.63/65 consultado no texto extraído. Não misturar fichas da 1ª edição encontradas em pesquisas com a caixa moderna da 2ª edição.

**FATO INFORMADO PELO USUÁRIO:** não tem acesso à caixa/cartas físicas. A continuidade da pesquisa depende de fontes documentais públicas legíveis; essa ausência não autoriza preencher valores por suposição.

## Transcrição mecânica implementada

| Ficha | Azul | Amarelo | Escolha laranja | Escolha vermelha | Fonte |
| --- | --- | --- | --- | --- | --- |
| Amy | +1 movimento gratuito | +1 ação | Corpo a corpo gratuito OU ataque à distância gratuito | +1 dado em combate OU +1 no resultado dos dados de combate OU Médica | p.7; efeitos pp.63/65 |
| Elle | Sniper | +1 ação | +1 dado em combate OU ataque à distância gratuito | +1 dado à distância OU combate gratuito OU +1 no resultado dos dados à distância | p.15; efeitos pp.63/65 |

Adultas com 3 de vida. O preset do menu usa Amy no cartão 1 e Elle no cartão 4; os outros quatro são peões de laboratório. Desmarcar o preset mantém os seis peões genéricos. A aparência dos retratos/modelos continua sendo estudo original B-001/B-002; não corresponde às ilustrações oficiais dessas fichas.

Implementação: `src/core/survivors.gd` contém perfis, páginas e rótulos; `rules.gd` contém os efeitos. Habilidades são escolhidas ao cruzar os limiares e interrompem a fila com decisão do dono da ficha. Escolha ilegal não gasta recursos. Nova ação gratuita fica disponível imediatamente; o motor consome primeiro a reserva mais restrita. Movimento gratuito paga a ação base, mas sair de zona ocupada ainda cobra ações gerais adicionais.

Bônus de dado aplicam-se por arma no Dual. Prévia e decisão de rolagem usam precisão modificada, mantendo as faces sorteadas visíveis. Sniper permite selecionar alvos válidos sem prioridade de disparo e evita fogo amigo. Médica cura um ferimento por sobrevivente da zona ao fim da rodada, ganhando adrenalina por ferimento tratado. Molotov continua sem rolagem, mesmo com bônus de dados.

**Correção verificada:** pistola passa de 4+ para **3+**, conforme carta ampliada da p.13. Alcance 0–1, um dado, dano 1; demais atributos não foram redefinidos por inferência. A ilustração de Chainsaw da p.14 foi examinada, mas a arma não foi adicionada ao deck de runtime nesta rodada.

## Inventário documental e conteúdo ainda ausente

[Inventário da caixa](../origem/inventario-caixa.md) registra as quantidades listadas na p.4. Conhecer os nomes/quantidades não verifica os valores de cada carta. O runtime continua com dez cartas de busca, quatro entradas de spawn de laboratório e duas armas especiais de teste; probabilidades não equivalem à caixa base.

| Pendência | Consequência |
| --- | --- |
| Quatro outras fichas da caixa base, conferidas individualmente | Continuam peões genéricos; pausa ao chegar ao laranja |
| Valores de todas as cartas e 40 linhas/cartas de zumbis | Não há baralhos oficiais completos nem balanceamento validado |
| Rush, cartas reais de ativação extra, quatro abominações e exceções de equipamentos | Motor ainda parcial; amostras não comprovam os casos oficiais |
| Primeiro jogador definido pelo dono do Fire Axe, p.7 | O laboratório ainda inicia pelo anfitrião; regra identificada e pendente |
| Todas as combinações de reorganização/troca em uma ação | Fluxo atual é limitado |
| Revisão independente, erratas e partida M0 completa | Não declarar paridade integral |

**INFERÊNCIA:** o principal custo de completar M0 agora está na verificação dos dados e exceções. **PROPOSTA de continuidade:** adquirir primeiro uma fonte pública legível das fichas/cartas restantes; incorporar por lote com regressões, mantendo as lacunas expostas. Isso não é aprovação de outra edição ou alteração de regras.

## Persistência e rede

Conteúdo `m0-lab-v3-skills`: perfis, habilidades escolhidas, níveis desbloqueados, ações gratuitas, fila e rolagem pendente persistem com o RNG. Validação rejeita habilidades incompatíveis, reservas de ações forjadas e ator inválido em desbloqueio. Saves v1/v2 são recusados preservando arquivo e estado atual; não há migração automática. Ver [SAVE-001](SAVE-001.md).

Dois processos ENet verificam Amy/Elle no snapshot inicial e após reconexão. Essa evidência é localhost, não Steam/internet. QA das habilidades usa cenários controlados e não constitui uma partida humana da M0.
