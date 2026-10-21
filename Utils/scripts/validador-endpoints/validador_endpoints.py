"""Validador dos endpoints da collection Postman (pasta THL-Library > THL).

Lê a collection no Postman (API key) ou em um JSON exportado, executa os requests
e mostra o resultado em uma tela HTML local.

Regras de execução (por pasta/recurso):
- Pasta com os 4 métodos (GET, POST, PATCH, DELETE): GET, POST, subpastas, PATCH e
  DELETE, nessa ordem. O DELETE roda sempre que o POST foi tentado, para não deixar
  o registro de teste. Antes do POST há uma pré-limpeza (DELETE) de sobra de rodada anterior.
- Pasta sem os 4 métodos: só os GET; os demais ficam IGNORADO.
- Escrita (POST/PATCH/DELETE) é bloqueada no ambiente de produção.
- Resultado esperado vem dos testes do próprio request (status, success, items, hasNext).

Uso (a partir da raiz do repositório):
    python Utils/scripts/validador-endpoints/validador_endpoints.py --ambiente PROJETO-INTERNO
    python Utils/scripts/validador-endpoints/validador_endpoints.py --ambiente PROJETO-INTERNO --cli
Configuração em .env (ao lado deste arquivo; ver env.exemplo). Só biblioteca padrão.
"""
import argparse
import base64
import json
import os
import re
import ssl
import sys
import threading
import time
import urllib.error
import urllib.request
import uuid
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PASTA = os.path.dirname(os.path.abspath(__file__))
API_POSTMAN = "https://api.getpostman.com/collections/"
ESCOPO_PADRAO = "TOTVS/Projeto/THL-Library/THL"
METODOS_CRUD = {"GET", "POST", "PATCH", "DELETE"}
LIMITE_CORPO = 20000


def carregar_env():
    """Lê KEY=VALUE do .env ao lado do script; variáveis do sistema têm prioridade."""
    cfg = {}
    caminho = os.path.join(PASTA, ".env")
    if os.path.isfile(caminho):
        with open(caminho, encoding="utf-8-sig") as f:
            for linha in f:
                linha = linha.strip()
                if not linha or linha.startswith("#") or "=" not in linha:
                    continue
                k, v = linha.split("=", 1)
                cfg[k.strip()] = v.strip().strip('"').strip("'")
    for k, v in os.environ.items():
        if k.startswith(("POSTMAN_", "THL_")):
            cfg[k] = v
    return cfg


# ---------------------------------------------------------------- collection

def baixar_collection(cfg):
    uid = cfg.get("POSTMAN_COLLECTION_UID")
    chave = cfg.get("POSTMAN_API_KEY")
    if not uid or not chave:
        raise RuntimeError("Informe POSTMAN_API_KEY e POSTMAN_COLLECTION_UID no .env (ou use --arquivo).")
    req = urllib.request.Request(API_POSTMAN + uid, headers={"X-API-Key": chave})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.loads(r.read().decode("utf-8"))["collection"]
    except urllib.error.HTTPError as e:
        raise RuntimeError("Postman respondeu HTTP %s ao buscar a collection." % e.code)


def achar_pasta(itens, caminho):
    """Desce pelos nomes do caminho (comparação sem diferenciar maiúsculas)."""
    no = {"item": itens}
    for nome in [p for p in caminho.split("/") if p]:
        prox = None
        for it in no.get("item", []):
            if "item" in it and it.get("name", "").lower() == nome.lower():
                prox = it
                break
        if prox is None:
            raise RuntimeError("Pasta '%s' não encontrada na collection (caminho %s)." % (nome, caminho))
        no = prox
    return no


# ---------------------------------------------------------------- plano

def url_bruta(req):
    u = req.get("url", "")
    if isinstance(u, dict):
        raw = u.get("raw", "")
        base = raw.split("?", 1)[0]
        consultas = [q for q in u.get("query", []) if not q.get("disabled")]
        if consultas:
            base += "?" + "&".join("%s=%s" % (q["key"], q.get("value") or "") for q in consultas)
        return base
    return u


def montar_plano(pasta):
    """Árvore de execução: recursos de nível 1 -> pastas -> requests."""
    def no_pasta(item, caminho):
        reqs = [i for i in item.get("item", []) if "request" in i]
        subs = [i for i in item.get("item", []) if "item" in i]
        metodos = {r["request"].get("method", "GET").upper() for r in reqs}
        return {
            "nome": item.get("name", ""),
            "caminho": caminho,
            "completo": METODOS_CRUD <= metodos,
            "requests": [novo_passo(r, caminho) for r in reqs],
            "filhos": [no_pasta(s, caminho + " / " + s.get("name", "")) for s in subs],
        }

    def novo_passo(item, caminho):
        r = item["request"]
        return {
            "id": uuid.uuid4().hex[:10],
            "nome": item.get("name", ""),
            "metodo": r.get("method", "GET").upper(),
            "caminho": caminho,
            "item": item,
            "status": "PENDENTE",
        }

    raiz = no_pasta(pasta, pasta.get("name", ""))
    recursos = raiz["filhos"]
    if raiz["requests"]:
        recursos = [dict(raiz, filhos=[])] + recursos
    return recursos


def todos_passos(no):
    for p in no["requests"]:
        yield p
    for f in no["filhos"]:
        yield from todos_passos(f)


# ---------------------------------------------------------------- execução

class Executor:
    def __init__(self, colecao, cfg, ambiente, so_get=False):
        self.cfg = cfg
        self.so_get = so_get
        self.ambiente = ambiente.upper()
        self.producao = "PRODUCAO" in self.ambiente
        self.vars = {v["key"]: v.get("value", "") for v in colecao.get("variable", []) if v.get("key")}
        for k, v in cfg.items():
            if k.startswith("THL_VAR_"):
                self.vars[k[8:]] = v
        self.base = self.vars.get("URI-BASE-" + self.ambiente) or cfg.get("THL_BASE_URL", "")
        if not self.base:
            raise RuntimeError("Ambiente '%s' sem valor: variável URI-BASE-%s vazia na collection "
                               "(ou defina THL_BASE_URL)." % (self.ambiente, self.ambiente))
        if not re.match(r"^https?://", self.base):
            self.base = "http://" + self.base
        self.auth_colecao = colecao.get("auth")
        self.ctx = ssl.create_default_context()
        if cfg.get("THL_VERIFY_TLS", "true").lower() == "false":
            self.ctx.check_hostname = False
            self.ctx.verify_mode = ssl.CERT_NONE

    # variáveis
    def resolver(self, texto):
        def sub(m):
            nome = m.group(1)
            if nome.startswith("URI-BASE-"):
                return self.base
            if nome == "$timestamp":
                return str(int(time.time()))
            if nome == "$guid":
                return str(uuid.uuid4())
            if nome == "$randomInt":
                return str(int(time.time() * 1000) % 1000)
            return str(self.vars.get(nome, m.group(0)))
        return re.sub(r"\{\{([^{}]+)\}\}", sub, texto or "")

    def cabecalho_auth(self, request):
        auth = request.get("auth") or self.auth_colecao or {}
        usuario = self.cfg.get("THL_USER")
        senha = self.cfg.get("THL_PASSWORD")
        if not usuario and auth.get("type") == "basic":
            dados = {x["key"]: x.get("value", "") for x in auth.get("basic", [])}
            usuario, senha = self.resolver(dados.get("username")), self.resolver(dados.get("password"))
        if usuario:
            tok = base64.b64encode(("%s:%s" % (usuario, senha or "")).encode("utf-8")).decode("ascii")
            return "Basic " + tok
        return None

    def enviar(self, passo):
        """Executa um request; devolve dict com http, ms, corpo, request e erro."""
        r = passo["item"]["request"]
        url = self.resolver(url_bruta(r))
        corpo = None
        body = r.get("body") or {}
        if body.get("mode") == "raw" and body.get("raw"):
            corpo = self.resolver(body["raw"])
        faltando = re.findall(r"\{\{[^{}]+\}\}", url + (corpo or ""))
        res = {"url": url, "corpo_enviado": corpo, "http": None, "ms": 0, "resposta": "", "erro": None,
               "json": None}
        if faltando:
            res["erro"] = "variável não resolvida: " + ", ".join(sorted(set(faltando)))
            return res
        cab = {"Accept": "application/json"}
        for h in r.get("header", []):
            if not h.get("disabled") and h.get("key"):
                cab[h["key"]] = self.resolver(h.get("value", ""))
        if corpo is not None and not any(k.lower() == "content-type" for k in cab):
            cab["Content-Type"] = "application/json"
        auth = self.cabecalho_auth(r)
        if auth:
            cab["Authorization"] = auth
        req = urllib.request.Request(url, method=passo["metodo"], headers=cab,
                                     data=corpo.encode("utf-8") if corpo is not None else None)
        t0 = time.time()
        try:
            with urllib.request.urlopen(req, timeout=60, context=self.ctx) as resp:
                res["http"] = resp.status
                bruto = resp.read()
        except urllib.error.HTTPError as e:
            res["http"] = e.code
            bruto = e.read()
        except Exception as e:  # rede, TLS, timeout
            res["erro"] = "%s: %s" % (type(e).__name__, e)
            bruto = b""
        res["ms"] = int((time.time() - t0) * 1000)
        res["resposta"] = bruto.decode("utf-8", errors="replace")
        try:
            res["json"] = json.loads(res["resposta"])
        except ValueError:
            pass
        cab_vis = {k: ("***" if k.lower() == "authorization" else v) for k, v in cab.items()}
        res["cabecalhos"] = cab_vis
        return res

    def avaliar(self, passo, res):
        """Aplica as expectativas dos testes do request; devolve (ok, motivos)."""
        if res["erro"]:
            return False, [res["erro"]]
        texto = "\n".join(
            "\n".join(e.get("script", {}).get("exec", []))
            for e in passo["item"].get("event", []) if e.get("listen") == "test")
        motivos = []
        status_esp = [int(x) for x in re.findall(r"have\.status\((\d+)\)", texto)]
        if status_esp:
            if res["http"] not in status_esp:
                motivos.append("HTTP %s, esperado %s" % (res["http"], status_esp[0]))
        elif not (res["http"] and 200 <= res["http"] < 300):
            motivos.append("HTTP %s fora de 2xx" % res["http"])
        corpo = res["json"]
        nao_avaliado = []
        for caminho, valor in re.findall(r"(?:pm\.response\.json\(\)|body)\.([\w.]+)\)\.to\.eql\((.+?)\)", texto):
            esperado = json.loads(valor.replace("'", '"'))
            atual = self.caminho_json(corpo, caminho)
            if atual != esperado:
                motivos.append("%s = %s, esperado %s" % (caminho, json.dumps(atual, ensure_ascii=False), valor))
        for caminho in re.findall(r"(?:pm\.response\.json\(\)|body)\.([\w.]+)\)\.to\.be\.an\('array'\)", texto):
            if not isinstance(self.caminho_json(corpo, caminho), list):
                motivos.append("%s não é lista" % caminho)
        for prop in re.findall(r"to\.have\.property\('([\w.]+)'\)", texto):
            if not (isinstance(corpo, dict) and prop in corpo):
                motivos.append("propriedade '%s' ausente" % prop)
        if texto and not (status_esp or re.search(r"\.to\.(eql|be\.an|have\.property)", texto)):
            nao_avaliado.append("testes do request não interpretados")
        if corpo is None and res["resposta"].strip() and not motivos:
            motivos.append("resposta não é JSON")
        return (not motivos), motivos + nao_avaliado if motivos else []

    @staticmethod
    def caminho_json(corpo, caminho):
        atual = corpo
        for parte in caminho.split("."):
            if isinstance(atual, dict) and parte in atual:
                atual = atual[parte]
            else:
                return None
        return atual

    def rodar_passo(self, passo, publicar):
        passo["status"] = "EXECUTANDO"
        publicar()
        res = self.enviar(passo)
        ok, motivos = self.avaliar(passo, res)
        passo["status"] = "OK" if ok else "FALHA"
        passo["motivo"] = "; ".join(motivos)
        passo["http"] = res["http"]
        passo["ms"] = res["ms"]
        passo["detalhe"] = {
            "url": res["url"],
            "cabecalhos": res.get("cabecalhos", {}),
            "corpo_enviado": res["corpo_enviado"],
            "resposta": res["resposta"][:LIMITE_CORPO],
        }
        publicar()
        return ok

    def ignorar(self, passo, motivo, publicar):
        passo["status"] = "IGNORADO"
        passo["motivo"] = motivo
        publicar()

    # pasta
    def rodar_no(self, no, publicar, pai_ok=True):
        por_metodo = {}
        for p in no["requests"]:
            por_metodo.setdefault(p["metodo"], []).append(p)
        completo = no["completo"]
        escrita_bloqueada = None
        if self.so_get:
            escrita_bloqueada = "modo só GET"
        elif self.producao:
            escrita_bloqueada = "escrita bloqueada em produção"
        elif not completo:
            escrita_bloqueada = "recurso sem os 4 métodos"
        elif not pai_ok:
            escrita_bloqueada = "POST da pasta pai falhou"

        for p in por_metodo.get("GET", []):
            self.rodar_passo(p, publicar)
        outros = [p for p in no["requests"] if p["metodo"] != "GET"]

        post_ok = True
        if escrita_bloqueada:
            for p in outros:
                self.ignorar(p, escrita_bloqueada, publicar)
            for f in no["filhos"]:
                self.rodar_no(f, publicar, pai_ok=pai_ok)
            return post_ok

        delete = por_metodo.get("DELETE", [])
        if delete and por_metodo.get("POST"):
            pre = self.enviar(dict(delete[0]))  # pré-limpeza silenciosa
            por_metodo["POST"][0]["pre_limpeza"] = pre["http"]
        for p in por_metodo.get("POST", []):
            post_ok = self.rodar_passo(p, publicar) and post_ok
            if p.get("pre_limpeza") is not None:
                p["detalhe"]["pre_limpeza_http"] = p["pre_limpeza"]
        for f in no["filhos"]:
            self.rodar_no(f, publicar, pai_ok=post_ok)
        for p in por_metodo.get("PATCH", []):
            if post_ok:
                self.rodar_passo(p, publicar)
            else:
                self.ignorar(p, "POST falhou", publicar)
        for p in delete:
            self.rodar_passo(p, publicar)
        for p in outros:
            if p["status"] == "PENDENTE":
                self.ignorar(p, "método não previsto no ciclo", publicar)
        return post_ok


# ---------------------------------------------------------------- estado/servidor

class Estado:
    def __init__(self, cfg, arquivo, escopo):
        self.cfg = cfg
        self.arquivo = arquivo
        self.escopo = escopo
        self.lock = threading.Lock()
        self.recursos = []
        self.ambiente = ""
        self.executando = False
        self.erro = ""
        self.inicio = None
        self.fim = None

    def carregar(self):
        if self.arquivo:
            with open(self.arquivo, encoding="utf-8") as f:
                dados = json.load(f)
            colecao = dados.get("collection", dados)
        else:
            colecao = baixar_collection(self.cfg)
        pasta = achar_pasta(colecao.get("item", []), self.escopo)
        self.colecao = colecao
        self.recursos = montar_plano(pasta)

    def executar(self, ambiente, so_get, recurso):
        with self.lock:
            if self.executando:
                return False
            self.executando = True
            self.erro = ""
            self.inicio, self.fim = time.time(), None
        try:
            ex = Executor(self.colecao, self.cfg, ambiente, so_get)
        except RuntimeError as e:
            self.erro = str(e)
            self.executando = False
            return True
        self.ambiente = ambiente.upper()
        alvo = [r for r in self.recursos if recurso in (None, "", r["nome"])]
        for r in alvo:
            for p in todos_passos(r):
                p.update(status="PENDENTE", motivo="", http=None, ms=0)
                p.pop("detalhe", None)

        def tarefa():
            try:
                for r in alvo:
                    ex.rodar_no(r, lambda: None)
            except Exception as e:
                self.erro = "%s: %s" % (type(e).__name__, e)
            finally:
                self.fim = time.time()
                self.executando = False
        threading.Thread(target=tarefa, daemon=True).start()
        return True

    def snapshot(self):
        def no(n):
            return {
                "nome": n["nome"], "caminho": n["caminho"], "completo": n["completo"],
                "passos": [{k: p.get(k) for k in ("id", "nome", "metodo", "status", "motivo", "http", "ms", "detalhe")}
                           for p in n["requests"]],
                "filhos": [no(f) for f in n["filhos"]],
            }
        todos = [p for r in self.recursos for p in todos_passos(r)]
        cont = {}
        for p in todos:
            cont[p["status"]] = cont.get(p["status"], 0) + 1
        return {
            "executando": self.executando, "erro": self.erro, "ambiente": self.ambiente,
            "escopo": self.escopo, "contagem": cont, "total": len(todos),
            "duracao": round((self.fim or time.time()) - self.inicio, 1) if self.inicio else None,
            "recursos": [no(r) for r in self.recursos],
        }


def criar_handler(estado, ambientes, ambiente_padrao):
    class H(BaseHTTPRequestHandler):
        def log_message(self, *a):
            pass

        def _enviar(self, codigo, tipo, dados):
            if isinstance(dados, str):
                dados = dados.encode("utf-8")
            self.send_response(codigo)
            self.send_header("Content-Type", tipo)
            self.send_header("Content-Length", str(len(dados)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(dados)

        def do_GET(self):
            if self.path == "/":
                self._enviar(200, "text/html; charset=utf-8", PAGINA)
            elif self.path == "/api/estado":
                dados = estado.snapshot()
                dados["ambientes"] = ambientes
                dados["ambientePadrao"] = ambiente_padrao
                self._enviar(200, "application/json; charset=utf-8", json.dumps(dados, ensure_ascii=False))
            else:
                self._enviar(404, "text/plain", "não encontrado")

        def do_POST(self):
            tam = int(self.headers.get("Content-Length") or 0)
            corpo = json.loads(self.rfile.read(tam) or b"{}")
            if self.path == "/api/executar":
                if corpo.get("ambiente") not in ambientes:
                    return self._enviar(400, "application/json", '{"erro":"ambiente inválido"}')
                ok = estado.executar(corpo["ambiente"], bool(corpo.get("soGet")), corpo.get("recurso"))
                self._enviar(200 if ok else 409, "application/json", json.dumps({"iniciado": ok}))
            elif self.path == "/api/recarregar":
                if estado.executando:
                    return self._enviar(409, "application/json", '{"erro":"execução em andamento"}')
                try:
                    estado.carregar()
                    self._enviar(200, "application/json", "{}")
                except Exception as e:
                    self._enviar(500, "application/json", json.dumps({"erro": str(e)}))
            else:
                self._enviar(404, "text/plain", "não encontrado")
    return H


def listar_ambientes(colecao):
    return sorted(v["key"][9:] for v in colecao.get("variable", [])
                  if v.get("key", "").startswith("URI-BASE-") and v.get("value"))


def imprimir_resumo(estado):
    snap = estado.snapshot()

    def pr(n, nivel=0):
        for p in n["passos"]:
            print("%s[%-8s] %-6s %s%s" % ("  " * nivel, p["status"], p["metodo"], n["caminho"] + " / " + p["nome"],
                                          ("  -> " + p["motivo"]) if p["motivo"] else ""))
        for f in n["filhos"]:
            pr(f, nivel + 1)
    for r in snap["recursos"]:
        pr(r)
    print("\nResumo:", snap["contagem"], "em", snap["duracao"], "s")
    return snap["contagem"].get("FALHA", 0) == 0


def main():
    ap = argparse.ArgumentParser(description="Valida os endpoints THL-Library da collection Postman.")
    ap.add_argument("--ambiente", help="sufixo de URI-BASE-<AMBIENTE> (ex.: PROJETO-INTERNO)")
    ap.add_argument("--arquivo", help="collection exportada (JSON) em vez da API do Postman")
    ap.add_argument("--escopo", default=None, help="caminho da pasta na collection (padrão %s)" % ESCOPO_PADRAO)
    ap.add_argument("--porta", type=int, default=8765)
    ap.add_argument("--sem-navegador", action="store_true", help="não abre o navegador automaticamente")
    ap.add_argument("--cli", action="store_true", help="executa no terminal, sem tela HTML")
    ap.add_argument("--so-get", action="store_true", help="só GET (com --cli)")
    ap.add_argument("--json", help="grava o resultado em arquivo JSON (com --cli)")
    a = ap.parse_args()

    cfg = carregar_env()
    estado = Estado(cfg, a.arquivo, a.escopo or cfg.get("THL_ESCOPO", ESCOPO_PADRAO))
    try:
        estado.carregar()
    except Exception as e:
        print("Erro ao carregar a collection:", e, file=sys.stderr)
        return 2
    ambientes = listar_ambientes(estado.colecao)
    padrao = (a.ambiente or cfg.get("THL_AMBIENTE", "")).upper()

    if a.cli:
        if not padrao:
            print("Informe --ambiente (opções: %s)." % ", ".join(ambientes), file=sys.stderr)
            return 2
        estado.executar(padrao, a.so_get, None)
        if estado.erro:
            print(estado.erro, file=sys.stderr)
            return 2
        while estado.executando:
            time.sleep(0.2)
        if estado.erro:
            print(estado.erro, file=sys.stderr)
        ok = imprimir_resumo(estado)
        if a.json:
            with open(a.json, "w", encoding="utf-8") as f:
                json.dump(estado.snapshot(), f, ensure_ascii=False, indent=2)
        return 0 if ok and not estado.erro else 1

    srv = ThreadingHTTPServer(("127.0.0.1", a.porta), criar_handler(estado, ambientes, padrao))
    url = "http://127.0.0.1:%d/" % a.porta
    print("Validador em", url, "(Ctrl+C para encerrar)")
    try:
        if not a.sem_navegador:
            webbrowser.open(url)
        srv.serve_forever()
    except KeyboardInterrupt:
        pass
    return 0


PAGINA = r"""<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8"><title>Validador de endpoints THL</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
:root{--bg:#f6f7f9;--fg:#1d2733;--mut:#677489;--card:#fff;--bd:#dfe3ea;--ok:#1a7f45;--okb:#e3f5ea;--ko:#b3261e;--kob:#fdeceb;--ig:#6b7280;--igb:#eef0f3;--run:#8a5a00;--runb:#fff3d6;--acc:#1f5fbf}
@media(prefers-color-scheme:dark){:root{--bg:#14181e;--fg:#e6eaf0;--mut:#9aa6b8;--card:#1c222b;--bd:#2c3542;--ok:#5fd18a;--okb:#16301f;--ko:#ff8a80;--kob:#3a1a18;--ig:#9aa6b8;--igb:#252c37;--run:#ffcf70;--runb:#3a2d10;--acc:#7aa7ff}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);font:14px/1.45 system-ui,Segoe UI,sans-serif}
header{padding:16px;border-bottom:1px solid var(--bd);background:var(--card);position:sticky;top:0;z-index:2}
h1{font-size:18px;margin:0 0 10px}.barra{display:flex;flex-wrap:wrap;gap:8px;align-items:center}
select,button{font:inherit;padding:6px 10px;border:1px solid var(--bd);border-radius:6px;background:var(--card);color:var(--fg)}
button.p{background:var(--acc);color:#fff;border-color:var(--acc)}button:disabled{opacity:.5}
.chips{display:flex;gap:6px;flex-wrap:wrap;margin-top:10px}.chip{padding:2px 10px;border-radius:12px;font-size:12px;cursor:pointer;border:1px solid transparent}
.chip.sel{border-color:var(--fg)}main{padding:16px;max-width:1100px;margin:auto}
.rec{background:var(--card);border:1px solid var(--bd);border-radius:8px;margin-bottom:12px}
.rec>h2{font-size:15px;margin:0;padding:10px 12px;display:flex;gap:8px;align-items:center;border-bottom:1px solid var(--bd)}
.rec h2 small{color:var(--mut);font-weight:400}.rec h2 button{margin-left:auto;padding:2px 8px;font-size:12px}
.sub{padding-left:14px;border-left:3px solid var(--bd);margin:6px 0 6px 10px}.sub h3{margin:6px 0;font-size:13px;color:var(--mut)}
.lin{display:grid;grid-template-columns:70px 90px 1fr 70px 60px;gap:8px;padding:6px 12px;border-bottom:1px solid var(--bd);cursor:pointer;align-items:center}
.lin:last-child{border-bottom:0}.lin:hover{background:var(--bg)}.m{font-weight:600;font-family:ui-monospace,monospace;font-size:12px}
.sel-s{padding:1px 8px;border-radius:10px;font-size:12px;text-align:center}
.OK{background:var(--okb);color:var(--ok)}.FALHA{background:var(--kob);color:var(--ko)}.IGNORADO,.PENDENTE{background:var(--igb);color:var(--ig)}.EXECUTANDO{background:var(--runb);color:var(--run)}
.mot{color:var(--ko);font-size:12px;grid-column:1/-1;padding-left:78px}.mot.i{color:var(--mut)}
.det{grid-column:1/-1;background:var(--bg);border:1px solid var(--bd);border-radius:6px;padding:8px;font:12px ui-monospace,monospace;white-space:pre-wrap;word-break:break-all;max-height:320px;overflow:auto;cursor:auto}
.erro{background:var(--kob);color:var(--ko);padding:10px;border-radius:6px;margin-bottom:12px}
@media(max-width:640px){.lin{grid-template-columns:60px 80px 1fr}.lin .h,.lin .t{display:none}.mot{padding-left:0}}
</style></head><body>
<header><h1>Validador de endpoints THL-Library <small id="esc" style="color:var(--mut);font-weight:400"></small></h1>
<div class="barra"><label>Ambiente <select id="amb"></select></label>
<button class="p" id="all">Executar tudo</button><button id="get">Executar só GET</button><button id="rel">Recarregar collection</button>
<span id="res"></span></div><div class="chips" id="chips"></div></header>
<main><div id="erro"></div><div id="lista"></div></main>
<script>
const $=s=>document.querySelector(s);let S=null,filtro=null,abertos=new Set(),timer=null;
const esc=t=>String(t??'').replace(/[&<>]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]));
async function api(u,corpo){const r=await fetch(u,corpo?{method:'POST',body:JSON.stringify(corpo)}:{});return r}
function passos(n){return [...n.passos,...n.filhos.flatMap(passos)]}
function pretty(t){try{return JSON.stringify(JSON.parse(t),null,2)}catch(e){return t}}
function linha(p){let h=`<div class="lin" data-id="${p.id}"><span class="m">${p.metodo}</span><span class="sel-s ${p.status}">${p.status}</span><span>${esc(p.nome)}</span><span class="h">${p.http??''}</span><span class="t">${p.ms?p.ms+' ms':''}</span>`;
if(p.motivo)h+=`<div class="mot ${p.status=='IGNORADO'?'i':''}">${esc(p.motivo)}</div>`;
if(abertos.has(p.id)&&p.detalhe){const d=p.detalhe;h+=`<div class="det" onclick="event.stopPropagation()"><b>${p.metodo} ${esc(d.url)}</b>\n${esc(JSON.stringify(d.cabecalhos))}\n\n<b>Corpo enviado</b>\n${esc(d.corpo_enviado?pretty(d.corpo_enviado):'(sem corpo)')}\n\n<b>Resposta (HTTP ${p.http??'-'})</b>\n${esc(pretty(d.resposta))}</div>`}
return h+'</div>'}
function bloco(n,topo){const ps=n.passos.filter(p=>!filtro||p.status==filtro);const fs=n.filhos.map(f=>bloco(f,false)).join('');
if(!ps.length&&!fs)return '';return `<div class="${topo?'':'sub'}">${topo?'':`<h3>${esc(n.nome)}</h3>`}${ps.map(linha).join('')}${fs}</div>`}
function render(){if(!S)return;$('#esc').textContent=S.escopo;$('#erro').innerHTML=S.erro?`<div class="erro">${esc(S.erro)}</div>`:'';
const sel=$('#amb');if(!sel.options.length){S.ambientes.forEach(a=>sel.add(new Option(a,a)));sel.value=S.ambientePadrao||''}
$('#all').disabled=$('#get').disabled=$('#rel').disabled=S.executando;
const c=S.contagem,ord=['OK','FALHA','IGNORADO','EXECUTANDO','PENDENTE'];
$('#chips').innerHTML=ord.filter(k=>c[k]).map(k=>`<span class="chip ${k} ${filtro==k?'sel':''}" data-f="${k}">${k}: ${c[k]}</span>`).join('')+(filtro?' <span class="chip IGNORADO" data-f="">limpar filtro</span>':'');
$('#res').textContent=(S.executando?'Executando… ':'')+(S.duracao!=null?S.duracao+' s':'')+(S.ambiente?` · ${S.ambiente}`:'');
$('#lista').innerHTML=S.recursos.map(r=>{const ps=passos(r),f=ps.filter(p=>p.status=='FALHA').length,o=ps.filter(p=>p.status=='OK').length;const corpo=bloco(r,true);if(!corpo)return '';
return `<section class="rec"><h2>${esc(r.nome)} <small>${r.completo?'CRUD completo':'só leitura/parcial'} · ${o} OK${f?` · ${f} falha(s)`:''}</small><button data-r="${esc(r.nome)}" ${S.executando?'disabled':''}>Executar</button></h2>${corpo}</section>`}).join('')}
async function atualizar(){const r=await api('/api/estado');S=await r.json();render();clearTimeout(timer);timer=setTimeout(atualizar,S.executando?800:4000)}
async function executar(soGet,recurso){const r=await api('/api/executar',{ambiente:$('#amb').value,soGet,recurso});if(r.status==409)alert('Já existe uma execução em andamento.');atualizar()}
document.addEventListener('click',async e=>{const t=e.target;
if(t.id=='all')executar(false);else if(t.id=='get')executar(true);
else if(t.id=='rel'){const r=await api('/api/recarregar',{});if(!r.ok)alert((await r.json()).erro);atualizar()}
else if(t.dataset.r!==undefined)executar(false,t.dataset.r);
else if(t.dataset.f!==undefined){filtro=t.dataset.f||null;render()}
else{const l=t.closest('.lin');if(l){const id=l.dataset.id;abertos.has(id)?abertos.delete(id):abertos.add(id);render()}}});
atualizar();
</script></body></html>"""

if __name__ == "__main__":
    sys.exit(main())
