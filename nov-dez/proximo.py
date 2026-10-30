"""Imprime (JSON) o item da agenda que já venceu hoje e ainda não foi publicado; nada se não houver."""
import datetime as dt, json, pathlib, sys
aqui = pathlib.Path(__file__).parent
agora = dt.datetime.now(dt.timezone(dt.timedelta(hours=-3)))
feitos = {p["id"] for p in json.loads((aqui / "publicados.json").read_text())}
for item in json.loads((aqui / "agenda.json").read_text()):
    if item["id"] in feitos or item["data"] != agora.strftime("%Y-%m-%d"):
        continue
    if item["hora"] <= agora.strftime("%H:%M"):
        print(json.dumps(item, ensure_ascii=False))
        sys.exit(0)
