# SAVE-001 — Persistência e retomada

Data: 17/10/2026. Requisitos: D-012/D-013.

Save versionado contém missão/conteúdo, jogadores e donos, turno, posições, inventários, ferimentos, adrenalina, decks/descarte, RNG, ruído, reservas e decisão/rolagem pendente. Escrita em temporário e substituição segura, backup da gravação anterior; schema e invariantes verificados antes de substituir estado vivo.

Snapshot público é diferente do save completo: próximos resultados/decks não são enviados aos clientes.

Desconexão pausa; sem transferência automática. Retomada exige reentrada validada. Save pode ser reaberto em outra sessão; o caso de queda do host não promete migração transparente.

Aceite: roundtrip conserva estado, cartas e RNG; rolagem pendente continua pendente; resultado existente não muda; save inválido não corrompe partida; backup recuperável; dois processos preservam estado após reentrada.
