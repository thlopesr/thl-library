"""Gera o diagrama de vínculos entre as tabelas THL (Mermaid flowchart).

Lê Database/Definition/thl.df e reescreve o bloco entre os marcadores
<!-- er-diagrama:inicio --> e <!-- er-diagrama:fim --> em
Documentos/.claude/data/er-diagrama.md.

- Linha contínua: vínculo com índice fk-* no .df (tabela pai = tabela cuja
  chave pk-* tem os mesmos campos do fk-*).
- Linha tracejada: vínculo sem índice, só no código ou por valor
  (lista IMPLICITOS abaixo, conferida no código em 2026-09-25).

Uso (na raiz do repositório):  python Utils/scripts/gerar-er-diagrama.py
"""
import os
import re
import sys

RAIZ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
DF = os.path.join(RAIZ, "Database", "Definition", "thl.df")
NOTA = os.path.join(RAIZ, "Documentos", ".claude", "data", "er-diagrama.md")
INICIO, FIM = "<!-- er-diagrama:inicio -->", "<!-- er-diagrama:fim -->"

# Agrupamento por assunto (mesmas dezenas da numeração dos programas)
DOMINIOS = [
    ("amb", "Ambiente (thl000x)", ["thl-ambiente", "thl-ambiente-param", "thl-ambiente-param-variavel",
                                    "thl-ambiente-param-prog"]),
    ("mail", "E-mail (thl001x)", ["thl-email", "thl-email-param", "thl-ambiente-param-grupo",
                                   "thl-ambiente-param-grupo-usuar"]),
    ("obj", "Objeto de integração e mensageria (thl002x)", ["thl-aplicacao", "thl-objeto", "thl-objeto-parametro",
                                                           "thl-objeto-parametro-rest", "thl-objeto-usuario", "thl-mensagem", "thl-mensagem-conteudo",
                                                           "thl-mensagem-historico", "thl-mensagem-item",
                                                           "thl-mensagem-ped-exec"]),
    ("rest", "Conexão REST (thl003x)", ["thl-conexao-rest", "thl-conexao-rest-path", "thl-conexao-rest-autenticacao",
                                        "thl-conexao-rest-header"]),
    ("inb", "Rota inbound (thl004x)", ["thl-objeto-rota"]),
    ("aud", "Auditoria (thl005x)", ["thl-audit-tabela", "thl-audit-tabela-acesso", "thl-audit-tabela-campo",
                                    "thl-audit-tabela-notificacao", "thl-audit-tabela-purge", "thl-audit-registro",
                                    "thl-audit-registro-detalhe", "thl-audit-registro-notificar"]),
]

# Rótulo próprio para vínculo fk-* cujo valor não bate direto com o do pai
ROTULOS = {
    ("thl-audit-registro", "thl-audit-tabela"): "banco = 'sh' + banco, tabela",
}

# Vínculos sem índice fk-*: (filha, pai, rótulo, onde foi conferido)
IMPLICITOS = [
    ("thl-ambiente-param-variavel", "thl-ambiente", "cod-ambiente", "EnvironmentRepository"),
    ("thl-ambiente-param-variavel", "thl-ambiente-param", "cod-param-ambiente", "EnvironmentRepository"),
    ("thl-email", "thl-ambiente-param", "cod-param-ambiente", "EmailLogger"),
    ("thl-email-param", "thl-ambiente-param-grupo", "cod-grp-usuar", "EmailParamRepository"),
    ("thl-audit-tabela-notificacao", "thl-ambiente-param-grupo", "grupo-email = cod-grp-usuar (nenhum código lê)", ".df"),
    ("thl-objeto", "thl-aplicacao", "aplicacao", "thl0021-v01 (zoom)"),
    ("thl-objeto-usuario", "thl-objeto", "aplicacao, objeto", "thl0022-b02 (OF)"),
    ("thl-objeto", "thl-ambiente-param-prog", "aplicacao + '.' + objeto = cod-prog-dtsul", "MessageExecutionService, EnvironmentResource"),
    ("thl-objeto-parametro", "thl-ambiente-param-variavel", "cod-param-ambiente / -destino = cod-variavel", "ConnectorConfig"),
    ("thl-mensagem-ped-exec", "thl-mensagem", "codigo-mensagem", "thl0220z.p, thl0222rp.p"),
    ("thl-conexao-rest-autenticacao", "thl-conexao-rest", "cod-conexao", "AuthenticationRepository"),
    ("thl-conexao-rest-header", "thl-conexao-rest", "cod-conexao", "ConnectorConfig"),
    ("thl-conexao-rest", "thl-ambiente-param-variavel", "valor da variável = cod-conexao", "ConnectorConfig"),
    ("thl-conexao-rest-path", "thl-ambiente-param-variavel", "valor da variável = cod-path", "ConnectorConfig"),
    ("thl-audit-tabela-campo", "thl-audit-tabela", "banco, tabela", "thl0051-b02 (OF)"),
    ("thl-audit-tabela-purge", "thl-audit-tabela", "banco, tabela", "thl0051-b04 (OF)"),
]


def ler_df():
    texto = open(DF, encoding="latin-1").read().replace("\r\n", "\n")
    tabelas, indices = [], {}
    for bloco in texto.split("\n\n"):
        m = re.match(r'ADD TABLE "([^"]+)"', bloco)
        if m:
            tabelas.append(m.group(1))
            indices.setdefault(m.group(1), [])
            continue
        m = re.match(r'ADD INDEX "([^"]+)" ON "([^"]+)"', bloco)
        if m:
            indices[m.group(2)].append((m.group(1), re.findall(r'INDEX-FIELD "([^"]+)"', bloco)))
    return tabelas, indices


def vinculos_fk(tabelas, indices):
    pk = {t: next(c for n, c in indices[t] if n.startswith("pk-")) for t in tabelas}
    saida = []
    for t in tabelas:
        for nome, campos in indices[t]:
            if not nome.startswith("fk-"):
                continue
            pais = [p for p in tabelas if p != t and pk[p] == campos]
            # tabelas irmãs com a mesma chave (ex.: thl-mensagem-ped-exec): vale a do nome do índice
            pais = [p for p in pais if p.endswith(nome[3:])] or pais
            if len(pais) != 1:
                sys.exit(f"fk sem pai único: {t}.{nome} -> {pais}")
            saida.append((t, pais[0], ROTULOS.get((t, pais[0]), ", ".join(campos))))
    return saida


def no(t):
    return re.sub(r"[^a-z0-9]", "_", t.replace("thl-", ""))


def mermaid(tabelas, fks):
    usadas = {t for _, _, ts in DOMINIOS for t in ts}
    faltando = set(tabelas) - usadas
    if faltando:
        sys.exit(f"tabelas sem domínio em DOMINIOS: {sorted(faltando)}")
    linhas = ["```mermaid", "flowchart LR"]
    for cod, titulo, ts in DOMINIOS:
        linhas.append(f'    subgraph {cod}["{titulo}"]')
        linhas += [f'        {no(t)}["{t}"]' for t in ts]
        linhas.append("    end")
    linhas.append("")
    linhas.append("    %% contínua: índice fk-* no .df")
    linhas += [f'    {no(f)} ---|"{r}"| {no(p)}' for f, p, r in fks]
    linhas.append("")
    linhas.append("    %% tracejada: sem índice (código ou valor)")
    for f, p, r, _ in IMPLICITOS:
        for x in (f, p):
            if x not in tabelas:
                sys.exit(f"tabela inexistente em IMPLICITOS: {x}")
        linhas.append(f'    {no(f)} -.-|"{r}"| {no(p)}')
    linhas.append("```")
    return "\n".join(linhas)


def main():
    tabelas, indices = ler_df()
    fks = vinculos_fk(tabelas, indices)
    bloco = mermaid(tabelas, fks)
    nota = open(NOTA, encoding="utf-8").read()
    if INICIO not in nota or FIM not in nota:
        sys.exit("marcadores não encontrados na nota")
    antes, resto = nota.split(INICIO, 1)
    _, depois = resto.split(FIM, 1)
    nota = f"{antes}{INICIO}\n{bloco}\n{FIM}{depois}"
    open(NOTA, "w", encoding="utf-8", newline="\n").write(nota)
    print(f"{len(tabelas)} tabelas, {len(fks)} vínculos fk-*, {len(IMPLICITOS)} implícitos -> {NOTA}")


if __name__ == "__main__":
    main()
