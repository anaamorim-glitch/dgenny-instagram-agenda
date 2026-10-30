#!/bin/bash
# Publica no Instagram @dgenny.ai o próximo item vencido de nov-dez/agenda.json (cronograma do zero, nov-dez/2026).
# Chamado pelo cron a cada 15 min. Só aciona o Claude quando há algo para publicar.
cd "$(dirname "$0")"
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
git -C .. pull -q --rebase 2>/dev/null
ITEM=$(python3 proximo.py)
[ -z "$ITEM" ] && exit 0
mkdir -p logs; LOG="logs/$(date +%F).log"
BASE="https://raw.githubusercontent.com/anaamorim-glitch/dgenny-instagram-agenda/main"
{
echo "== $(date '+%F %T') $ITEM"
claude -p --permission-mode bypassPermissions "Publique no Instagram @dgenny.ai este item da agenda (JSON): $ITEM

Regras:
1. Use só o Composio MCP, conta instagram_soler-betted, ig_user_id 27715421478059942. Nunca publique no LinkedIn nem em outra conta.
2. URLs públicas dos arquivos: $BASE/<caminho do arquivo>.
3. tipo post: INSTAGRAM_POST_IG_USER_MEDIA com image_url, caption = legenda, alt_text = titulo.
   tipo carrossel: um container por imagem (image_url, is_carousel_item true, alt_text = titulo), depois um container media_type CAROUSEL com children = ids na ordem e caption = legenda.
   tipo reels: INSTAGRAM_POST_IG_USER_MEDIA com video_url, media_type REELS, cover_url = capa, share_to_feed true, caption = legenda.
4. Depois INSTAGRAM_POST_IG_USER_MEDIA_PUBLISH com o creation_id (reels: max_wait_seconds 300).
5. Se publicou, acrescente {\"id\",\"media_id\",\"publicado_em\"} em publicados.json (nesta pasta) e rode: git add publicados.json && git commit -m 'Publicado <id>' && git push.
6. Termine com a linha PUBLICADO_OK <id> ou ERRO <motivo>. Em caso de erro, não tente de novo: o cron tenta em 15 minutos."
} >> "$LOG" 2>&1
