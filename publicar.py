"""Publica no Instagram da dgenny a peça do dia, conforme agenda.json, via API do Composio.

Uso:
  python publicar.py teste     -> confere conexão, conta e imagens (não publica nada)
  python publicar.py publicar  -> publica o que estiver vencido hoje (horário de Brasília)
"""
import datetime as dt
import json
import os
import sys
import urllib.error
import urllib.request

API = "https://backend.composio.dev/api/v3"
CHAVE = os.environ["COMPOSIO_API_KEY"]
REPO = os.environ.get("GITHUB_REPOSITORY", "anaamorim-glitch/dgenny-instagram-agenda")
BASE_IMG = f"https://raw.githubusercontent.com/{REPO}/main/"
BRT = dt.timezone(dt.timedelta(hours=-3))


def chamar(metodo, caminho, corpo=None):
    req = urllib.request.Request(
        API + caminho, method=metodo,
        data=json.dumps(corpo).encode() if corpo is not None else None,
        headers={"x-api-key": CHAVE, "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        sys.exit(f"Erro {e.code} em {caminho}: {e.read().decode()[:500]}")


def conta_instagram():
    contas = chamar("GET", "/connected_accounts?toolkit_slugs=instagram&statuses=ACTIVE")["items"]
    if not contas:
        sys.exit("Nenhuma conta do Instagram ativa nesta chave do Composio.")
    return contas[0]


def executar(conta, ferramenta, argumentos):
    r = chamar("POST", f"/tools/execute/{ferramenta}", {
        "connected_account_id": conta["id"], "user_id": conta.get("user_id"), "arguments": argumentos})
    if not r.get("successful"):
        sys.exit(f"{ferramenta} falhou: {r.get('error')}")
    return r["data"]


def imagem_ok(url):
    try:
        with urllib.request.urlopen(urllib.request.Request(url, method="HEAD"), timeout=30) as r:
            return r.status == 200 and r.headers.get("Content-Type", "").startswith("image/jpeg")
    except Exception:
        return False


def main(modo):
    agenda = json.load(open("agenda.json"))
    publicados = json.load(open("publicados.json"))
    feitos = {p["n"] for p in publicados}
    agora = dt.datetime.now(BRT)
    hoje, hora = agora.date().isoformat(), agora.strftime("%H:%M")

    conta = conta_instagram()
    perfil = executar(conta, "INSTAGRAM_GET_USER_INFO", {"ig_user_id": "me"})
    ig_id = str(perfil.get("id") or perfil.get("data", {}).get("id"))
    usuario = perfil.get("username") or perfil.get("data", {}).get("username")
    print(f"Conta: @{usuario} (id {ig_id}) · agora {agora:%d/%m %H:%M} BRT")
    if usuario != "dgenny.ai":
        sys.exit("A conta conectada não é a @dgenny.ai — nada foi publicado.")

    if modo == "teste":
        ruins = [a["imagem"] for a in agenda if not imagem_ok(BASE_IMG + a["imagem"])]
        print(f"Imagens acessíveis: {len(agenda) - len(ruins)}/{len(agenda)}", ruins[:5])
        prox = [a for a in agenda if a["n"] not in feitos and (a["data"], a["hora"]) >= (hoje, hora)][:3]
        for a in prox:
            print(f"Próxima: {a['data']} {a['hora']} · {a['tipo']} · {a['titulo']}")
        return

    vencidos = [a for a in agenda if a["data"] == hoje and a["hora"] <= hora and a["n"] not in feitos]
    if not vencidos:
        print("Nada para publicar agora.")
        return
    for a in vencidos:
        args = {"ig_user_id": ig_id, "image_url": BASE_IMG + a["imagem"]}
        if a["tipo"] == "story":
            args["media_type"] = "STORIES"
        else:
            args["caption"] = a["legenda"]
            args["alt_text"] = a["titulo"]
        container = executar(conta, "INSTAGRAM_POST_IG_USER_MEDIA", args)
        cid = str(container.get("id") or container.get("data", {}).get("id"))
        pub = executar(conta, "INSTAGRAM_POST_IG_USER_MEDIA_PUBLISH",
                       {"ig_user_id": ig_id, "creation_id": cid, "max_wait_seconds": 120})
        mid = str(pub.get("id") or pub.get("data", {}).get("id"))
        print(f"Publicado {a['n']} ({a['tipo']}): media {mid}")
        publicados.append({"n": a["n"], "data": a["data"], "tipo": a["tipo"], "media_id": mid,
                           "publicado_em": dt.datetime.now(BRT).isoformat(timespec="minutes")})
        json.dump(publicados, open("publicados.json", "w"), ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "teste")
