# SAVE-001 — Persistência e retomada

Compatibilidade vigente: `m0-lab-v3-skills`, com perfil, habilidades escolhidas, níveis, reservas de ações gratuitas e desbloqueios na fila. Saves `m0-lab-v1` e `m0-lab-v2-map12` são recusados com explicação, mantendo o arquivo e o estado atual; não existe migração automática. V2 preservava o mapa de 12 zonas, mas não os novos campos de habilidades.

Data: 17/10/2026. Requisitos: D-012/D-013.

Save versionado contém missão/conteúdo, jogadores e donos, turno, posições, inventários, ferimentos, adrenalina, decks/descarte, RNG, ruído, reservas e decisão/rolagem pendente. Escrita em temporário e substituição segura, backup da gravação anterior; schema e invariantes verificados antes de substituir estado vivo.

Snapshot público é diferente do save completo: próximos resultados/decks não são enviados aos clientes.

Desconexão pausa; sem transferência automática. Retomada exige reentrada validada. Save pode ser reaberto em outra sessão; o caso de queda do host não promete migração transparente.

Aceite: roundtrip conserva estado, cartas e RNG; rolagem pendente continua pendente; resultado existente não muda; save inválido não corrompe partida; backup recuperável; dois processos preservam estado após reentrada.
