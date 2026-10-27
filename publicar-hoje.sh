#!/bin/bash
# Publica no Instagram @dgenny.ai a peça do dia (agenda.json) usando o Claude Code + Composio.
# Chamado pelo cron às 08:00, 08:30 e 09:00 — não repete o que já está em publicados.json.
cd "$(dirname "$0")"
mkdir -p logs
LOG="logs/$(date +%F).log"
grep -q "PUBLICADO_OK" "$LOG" 2>/dev/null && exit 0
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"
{
echo "== $(date '+%F %T') =="
claude -p --permission-mode bypassPermissions "Publique no Instagram @dgenny.ai a peça de hoje ($(date +%F)).
1. Leia agenda.json e publicados.json nesta pasta. Publique só o item com data de hoje que ainda não esteja em publicados.json. Se não houver, responda NADA_A_PUBLICAR e pare.
2. Use o Composio MCP (conta instagram_soler-betted, ig_user_id 27715421478059942): INSTAGRAM_POST_IG_USER_MEDIA com image_url https://raw.githubusercontent.com/anaamorim-glitch/dgenny-instagram-agenda/main/<imagem>. Post: caption = legenda. Story: media_type STORIES, sem legenda. Depois INSTAGRAM_POST_IG_USER_MEDIA_PUBLISH com o creation_id (se der erro de mídia não pronta, espere 20s e tente de novo, até 5 vezes).
3. Nunca publique no LinkedIn nem em outra conta.
4. Acrescente em publicados.json {\"n\",\"data\",\"tipo\",\"media_id\",\"publicado_em\"} e rode: git add publicados.json && git commit -m 'Publicado <n>' && git push.
5. Termine com a linha PUBLICADO_OK <n> ou ERRO <motivo>."
} >> "$LOG" 2>&1
