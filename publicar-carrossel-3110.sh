#!/bin/bash
# Publicação única: carrossel "Do pedido ao ERP" no Instagram @dgenny.ai em 31/10/2026 às 08:00.
# Chamado pelo cron a cada 30 min das 08:00 às 12:30 de 31/10; para quando o log tem PUBLICADO_OK.
cd "$(dirname "$0")"
mkdir -p logs
LOG="logs/carrossel-2026-10-31.log"
[ "$(date +%F)" = "2026-10-31" ] || exit 0
grep -q "PUBLICADO_OK" "$LOG" 2>/dev/null && exit 0
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"
BASE="https://raw.githubusercontent.com/anaamorim-glitch/dgenny-instagram-agenda/main/avulsos/carrossel-pedido-erp"
{
echo "== $(date '+%F %T') =="
claude -p --permission-mode bypassPermissions "Publique no Instagram @dgenny.ai um CARROSSEL de 5 imagens.
1. Leia publicados.json nesta pasta. Se já houver item com n = \"C01\", responda PUBLICADO_OK C01 e pare.
2. Use o Composio MCP (conta instagram_soler-betted, ig_user_id 27715421478059942).
   a) Para cada imagem, nesta ordem, crie um container com INSTAGRAM_POST_IG_USER_MEDIA, image_url e is_carousel_item = true:
      $BASE/carrossel-01.jpg
      $BASE/carrossel-02.jpg
      $BASE/carrossel-03.jpg
      $BASE/carrossel-04.jpg
      $BASE/carrossel-05.jpg
   b) Crie o container pai com INSTAGRAM_POST_IG_USER_MEDIA: media_type CAROUSEL, children = os 5 ids na mesma ordem, caption = o conteúdo exato do arquivo avulsos/carrossel-pedido-erp/legenda.txt.
   c) Publique com INSTAGRAM_POST_IG_USER_MEDIA_PUBLISH usando o id do container pai (se der erro de mídia não pronta, espere 20s e tente de novo, até 5 vezes).
3. Nunca publique no LinkedIn nem em outra conta. Publique uma única vez.
4. Acrescente em publicados.json {\"n\":\"C01\",\"data\":\"2026-10-31\",\"tipo\":\"carrossel\",\"media_id\",\"publicado_em\",\"titulo\":\"Do pedido ao ERP (carrossel v2)\"} e rode: git add publicados.json && git commit -m 'Publicado C01' && git push.
5. Termine com a linha PUBLICADO_OK C01 ou ERRO <motivo>."
} >> "$LOG" 2>&1
