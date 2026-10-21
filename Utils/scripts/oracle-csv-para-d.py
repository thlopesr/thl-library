"""Converte os CSV extraidos do Oracle (extrair-thl-cadastros-oracle.sql) em .d do OpenEdge.

Uso:
    python -I oracle-csv-para-d.py <pasta-csv> <pasta-saida-d> <thl.df> [--relatorio arquivo.md]

- Ordem e tipos dos campos vem do thl.df (POSITION); o .d recebe o DUMP-NAME da tabela.
- CSV do SQL Developer em Windows-1252; o .d sai em ISO-8859-1 com CRLF.
- Aplica a inversao de chave nome.aplicacao -> aplicacao.nome em cod-conexao
  (thl-conexao-rest, -autenticacao, -header) e em valor-variavel das variaveis de conexao
  (thl-ambiente-param-variavel), e corrige/preenche descricoes (ver DESCRICOES).
"""
import csv
import io
import re
import sys
from datetime import datetime
from pathlib import Path

TABELAS = [
    'thl-ambiente', 'thl-ambiente-param', 'thl-ambiente-param-variavel', 'thl-ambiente-param-prog',
    'thl-ambiente-param-grupo', 'thl-ambiente-param-grupo-usuar',
    'thl-aplicacao', 'thl-objeto', 'thl-objeto-parametro', 'thl-objeto-parametro-rest',
    'thl-objeto-usuario', 'thl-objeto-rota',
    'thl-conexao-rest', 'thl-conexao-rest-path', 'thl-conexao-rest-autenticacao', 'thl-conexao-rest-header',
    'thl-email-param',
    'thl-audit-tabela', 'thl-audit-tabela-campo', 'thl-audit-tabela-acesso',
    'thl-audit-tabela-notificacao', 'thl-audit-tabela-purge',
]
APLICACOES = ['loog.ai', 'automatizacao', 'ninahub', 'logsmart', 'totvs', 'thl']
TABELAS_CONEXAO = ('thl-conexao-rest', 'thl-conexao-rest-autenticacao', 'thl-conexao-rest-header')

# Correcoes de texto (so em campos de descricao). Ordem importa.
TEXTO = [
    ('Autentificação', 'Autenticação'), ('Abrtura', 'Abertura'), ('Nunahub', 'Ninahub'),
    ('Automarizacao', 'Automatização'), ('bloquei ', 'bloqueio '), ('roterizador', 'roteirizador'),
    ('Parametrôs', 'Parâmetros'), ('Paramêtro', 'Parâmetro'), ('Parametro', 'Parâmetro'),
    ('parametro', 'parâmetro'), ('Codigo', 'Código'), ('Usuario', 'Usuário'),
    ('Automatizacao', 'Automatização'), ('Conteudo', 'Conteúdo'), ('conexao', 'conexão'),
    ('loog.ai', 'Loog.ai'),
]


def corrige_texto(s):
    for a, b in TEXTO:
        s = s.replace(a, b)
    return s


# (tabela, campo-descricao): {chave: nova descricao}. Preenche descricao em branco ou melhora a existente.
DESCR_CONEXAO = {
    'logsmart.mmcm.hml': 'Parâmetro de conexão MMCM - Homologação',
    'logsmart.mmcm': 'Parâmetro de conexão MMCM - Produção',
    'loog.ai.roteirizador': 'Parâmetro de conexão do roteirizador Loog.ai - Produção',
    'loog.ai': 'Parâmetro de conexão Loog.ai - Produção',
    'loog.ai.hom': 'Parâmetro de conexão Loog.ai - Homologação',
    'loog.ai.hom.roteirizador': 'Parâmetro de conexão do roteirizador Loog.ai - Homologação',
    'automatizacao.lpco': 'Parâmetro de conexão da automatização de LPCO',
    'ninahub': 'Parâmetro de conexão com a Ninahub',
}
DESCR_PATH = {
    'logsmart.mmcm.pedido': 'Envio do Pedido com MMCM',
    'nfe': 'Envio da nota fiscal (endpoint /nfe)',
    'lpco': 'Criação de LPCO na automatização',
    'AbrirChamado': 'Abertura de chamado na Ninahub',
}
# (cod-param-ambiente, cod-variavel) -> descricao, so quando a atual esta em branco
DESCR_VARIAVEL = {
    ('Ninihub', 'abrirChamado'): 'Código do destino para abertura de chamado',
    ('smartlog.mmcm', 'Documento'): 'Código do destino para envio de documento',
    ('Loog.ai.notafis', 'routeParameterCode'): 'Código do path de envio da nota fiscal',
    ('smartlog.mmcm', 'Conexao'): 'Código da conexão REST (THL0007)',
    ('smartlog.mmcm', 'PrePedido'): 'Código do destino para criação de pré-pedido',
    ('Ninihub', 'conn.ninahub'): 'Código da conexão REST com a Ninahub',
    ('Ninihub', 'codigoParametro'): 'Código do parâmetro de ambiente da Ninahub',
}


def inverte_chave(cod):
    """nome.aplicacao -> aplicacao.nome; ja no padrao ou sem nome, mantem."""
    low = cod.lower()
    for app in APLICACOES:
        if low == app or low.startswith(app + '.'):
            return cod
    for app in sorted(APLICACOES, key=len, reverse=True):
        if low.endswith('.' + app):
            return cod[-len(app):] + '.' + cod[:-len(app) - 1]
    return cod


def le_df(caminho):
    s = Path(caminho).read_bytes().decode('latin-1').replace('\r', '')
    tab, campos = {}, {}
    for b in re.split(r'\n\n+', s):
        m = re.match(r'ADD TABLE "([^"]+)"', b)
        if m:
            tab[m.group(1)] = re.search(r'DUMP-NAME "([^"]+)"', b).group(1)
        m = re.match(r'ADD FIELD "([^"]+)" OF "([^"]+)" AS ([\w-]+)', b)
        if m:
            pos = int(re.search(r'POSITION (\d+)', b).group(1))
            ini = re.search(r'INITIAL ([^\n]*)', b).group(1).strip()
            campos.setdefault(m.group(2), []).append((pos, m.group(1), m.group(3), ini))
    for t in campos:
        campos[t].sort()
    return tab, campos


def col_oracle(nome):
    return nome.upper().replace('-', '_')[:30]


def formata(valor, tipo, ini, aviso, ctx):
    nulo = valor is None or valor == ''
    if tipo == 'character':
        if nulo:
            aviso.append(f'{ctx}: texto nulo -> ?')
            return '?'
        if valor.strip() == '':
            return '""'
        return '"' + valor.replace('"', '""') + '"'
    if tipo == 'logical':
        if nulo:
            aviso.append(f'{ctx}: logico nulo -> no')
            return 'no'
        return 'yes' if valor.strip() in ('1', 'yes', 'true') else 'no'
    if tipo in ('integer', 'int64'):
        if nulo:
            aviso.append(f'{ctx}: inteiro nulo -> {ini.strip(chr(34)) or 0}')
            return ini.strip('"') or '0'
        return str(int(valor))
    if tipo == 'decimal':
        return '?' if nulo else valor.replace(',', '.')
    if tipo == 'datetime':
        if nulo:
            return '?'
        m = re.match(r'(\d\d)-([A-Z]{3})-(\d\d) (\d\d)\.(\d\d)\.(\d\d)\.\d+ (AM|PM)', valor.strip())
        dt = datetime.strptime(f'{m.group(1)}-{m.group(2)}-{m.group(3)} {m.group(4)}:{m.group(5)}:{m.group(6)} {m.group(7)}',
                               '%d-%b-%y %I:%M:%S %p')
        return dt.strftime('%Y-%m-%dT%H:%M:%S.000')
    raise ValueError(f'tipo nao tratado: {tipo} ({ctx})')


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    pasta_csv, pasta_d, df = Path(args[0]), Path(args[1]), args[2]
    relatorio = sys.argv[sys.argv.index('--relatorio') + 1] if '--relatorio' in sys.argv else None
    pasta_d.mkdir(parents=True, exist_ok=True)
    dump, campos = le_df(df)
    agora = datetime.now().strftime('%Y/%m/%d-%H:%M:%S')

    mapa_chaves, valor_var, descr_alt, avisos, resumo = {}, [], [], [], []
    # o mapa de chaves precisa existir antes de tratar thl-ambiente-param-variavel
    txt = (pasta_csv / 'thl-conexao-rest.txt').read_bytes().decode('cp1252')
    for l in list(csv.reader(io.StringIO(txt, newline='')))[1:]:
        if l and inverte_chave(l[0]) != l[0]:
            mapa_chaves[l[0]] = inverte_chave(l[0])
    for tabela in TABELAS:
        texto = (pasta_csv / f'{tabela}.txt').read_bytes().decode('cp1252')
        linhas = list(csv.reader(io.StringIO(texto, newline='')))
        cab = linhas[0] if linhas else []
        regs = [dict(zip(cab, l)) for l in linhas[1:] if l]
        regs = [{k: (v if v != '' else None) for k, v in r.items()} for r in regs]
        # colunas do df que nao existem no Oracle
        falta = [c[1] for c in campos[tabela] if col_oracle(c[1]) not in cab]
        if falta:
            avisos.append(f'{tabela}: campos do .df ausentes no Oracle (valor inicial): {", ".join(falta)}')

        saida = []
        for i, r in enumerate(regs, 1):
            # --- transformacoes ---
            if tabela in TABELAS_CONEXAO:
                antigo = r['COD_CONEXAO']
                novo = inverte_chave(antigo)
                if novo != antigo:
                    mapa_chaves[antigo] = novo
                r['COD_CONEXAO'] = novo
            if tabela == 'thl-ambiente-param-variavel':
                pass  # aplicado na segunda passada (precisa do mapa completo)
            vals = []
            for pos, nome, tipo, ini in campos[tabela]:
                col = col_oracle(nome)
                v = r.get(col)
                vals.append((nome, tipo, ini, v))
            r['_vals'] = vals
            r['_n'] = i
        if tabela == 'thl-ambiente-param-variavel':
            for r in regs:
                v = r.get('VALOR_VARIAVEL')
                if v in mapa_chaves:
                    valor_var.append((r['COD_PARAM_AMBIENTE'], r['COD_VARIAVEL'], r['COD_AMBIENTE'], v, mapa_chaves[v]))
                    r['VALOR_VARIAVEL'] = mapa_chaves[v]
        # descricoes
        campo_desc = {'thl-conexao-rest': 'DES_CONEXAO', 'thl-conexao-rest-path': 'DES_PATH',
                      'thl-ambiente-param-variavel': 'DESCR_VARIAVEL', 'thl-ambiente-param': 'DESCR_PARAM_AMBIENTE'}.get(tabela)
        if campo_desc:
            for r in regs:
                antes = r.get(campo_desc) or ''
                depois = antes
                if tabela == 'thl-conexao-rest':
                    depois = DESCR_CONEXAO.get(r['COD_CONEXAO'], corrige_texto(antes))
                elif tabela == 'thl-conexao-rest-path':
                    depois = DESCR_PATH.get(r['COD_PATH'], corrige_texto(antes))
                elif tabela == 'thl-ambiente-param-variavel':
                    chave = (r['COD_PARAM_AMBIENTE'], r['COD_VARIAVEL'])
                    depois = DESCR_VARIAVEL[chave] if (antes.strip() == '' and chave in DESCR_VARIAVEL) else corrige_texto(antes)
                else:
                    depois = corrige_texto(antes)
                if depois != antes:
                    r[campo_desc] = depois
                    ident = r.get('COD_CONEXAO') or r.get('COD_PATH') or r.get('COD_PARAM_AMBIENTE')
                    if tabela == 'thl-ambiente-param-variavel':
                        ident = f"{r['COD_AMBIENTE']}/{r['COD_PARAM_AMBIENTE']}/{r['COD_VARIAVEL']}"
                    descr_alt.append((tabela, ident, antes, depois))

        for r in regs:
            partes = []
            for pos, nome, tipo, ini in campos[tabela]:
                v = r.get(col_oracle(nome))
                partes.append(formata(v, tipo, ini, avisos, f'{tabela}#{r["_n"]}.{nome}'))
            saida.append(' '.join(partes))

        corpo = ''.join(l + '\r\n' for l in saida).encode('latin-1')
        tam = len(corpo) + 3
        trailer = (f'.\r\nPSC\r\nfilename={tabela}\r\nrecords={len(saida):013d}\r\nldbname=mgnitro\r\n'
                   f'timestamp={agora}\r\nnumformat=46,44\r\ndateformat=dmy-1950\r\nmap=NO-MAP\r\n'
                   f'cpstream=ISO8859-1\r\n.\r\n{tam:010d}\r\n').encode('latin-1')
        (pasta_d / f'{dump[tabela]}.d').write_bytes(corpo + trailer)
        resumo.append((tabela, dump[tabela], len(saida)))

    print('Tabela                              dump      registros')
    for t, d, n in resumo:
        print(f'{t:35s} {d:9s} {n}')
    print('\nChaves invertidas:')
    for a, b in mapa_chaves.items():
        print(f'  {a} -> {b}')
    print('\nvalor-variavel atualizado:')
    for x in valor_var:
        print('  ', x)
    print('\nAvisos:')
    resumo_av = {}
    for a in avisos:
        k = re.sub(r'#\d+', '', a)
        resumo_av[k] = resumo_av.get(k, 0) + 1
    for k, n in resumo_av.items():
        print(f'  {k} (x{n})')
    print(f'\nDescricoes alteradas: {len(descr_alt)}')
    for t, i, a, d in descr_alt:
        print(f'  [{t}] {i}: "{a.strip()}" -> "{d}"')
    if relatorio:
        import json
        Path(relatorio).write_text(json.dumps({'chaves': mapa_chaves, 'valor': valor_var, 'descr': descr_alt,
                                              'avisos': resumo_av, 'resumo': resumo}, ensure_ascii=False, indent=1),
                                   encoding='utf-8')


if __name__ == '__main__':
    main()
