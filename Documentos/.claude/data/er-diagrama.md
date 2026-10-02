# Vínculos entre as tabelas THL

> Nota criada em 2026-09-25. Mostra **só se existe vínculo** entre tabelas `thl-*` (sem cardinalidade e sem as tabelas do ERP). Campos completos, índices e divergências: [schema.md](schema.md).
>
> **Gerado** por `Utils/scripts/gerar-er-diagrama.py` a partir do `Database/thl.df` — não editar o bloco entre os marcadores à mão. Depois de mudar o `.df`, rode `python Utils/scripts/gerar-er-diagrama.py` na raiz do repositório.

## Como ler

- **Linha contínua:** há índice `fk-*` no `.df` (vínculo declarado pela convenção de índices — [convencoes.md §6](../convencoes.md)).
- **Linha tracejada:** não há índice; o vínculo existe só no código (`OF`, `where a.x = b.x`) ou **por valor** (o código de uma tabela guardado como texto em outra). Nada no banco garante que o valor exista.
- O rótulo da linha são os campos da ligação.
- Os grupos seguem as dezenas da numeração dos programas ([convencoes.md §7](../convencoes.md)).

<!-- er-diagrama:inicio -->
```mermaid
flowchart LR
    subgraph amb["Ambiente (thl000x)"]
        ambiente["thl-ambiente"]
        ambiente_param["thl-ambiente-param"]
        ambiente_param_variavel["thl-ambiente-param-variavel"]
        ambiente_param_prog["thl-ambiente-param-prog"]
    end
    subgraph mail["E-mail (thl001x)"]
        email["thl-email"]
        email_param["thl-email-param"]
        ambiente_param_grupo["thl-ambiente-param-grupo"]
        ambiente_param_grupo_usuar["thl-ambiente-param-grupo-usuar"]
    end
    subgraph obj["Objeto de integração e mensageria (thl002x)"]
        aplicacao["thl-aplicacao"]
        objeto["thl-objeto"]
        objeto_parametro["thl-objeto-parametro"]
        objeto_usuario["thl-objeto-usuario"]
        mensagem["thl-mensagem"]
        mensagem_conteudo["thl-mensagem-conteudo"]
        mensagem_historico["thl-mensagem-historico"]
        mensagem_item["thl-mensagem-item"]
        mensagem_ped_exec["thl-mensagem-ped-exec"]
    end
    subgraph rest["Conexão REST (thl003x)"]
        conexao_rest["thl-conexao-rest"]
        conexao_rest_path["thl-conexao-rest-path"]
        conexao_rest_autenticacao["thl-conexao-rest-autenticacao"]
        conexao_rest_header["thl-conexao-rest-header"]
    end
    subgraph inb["Inbound (thl004x)"]
        inbound_rota["thl-inbound-rota"]
    end
    subgraph aud["Auditoria (thl005x)"]
        audit_tabela["thl-audit-tabela"]
        audit_tabela_acesso["thl-audit-tabela-acesso"]
        audit_tabela_campo["thl-audit-tabela-campo"]
        audit_tabela_notificacao["thl-audit-tabela-notificacao"]
        audit_tabela_purge["thl-audit-tabela-purge"]
        audit_registro["thl-audit-registro"]
        audit_registro_detalhe["thl-audit-registro-detalhe"]
        audit_registro_notificar["thl-audit-registro-notificar"]
    end

    %% contínua: índice fk-* no .df
    ambiente_param_grupo_usuar ---|"cod-grp-usuar"| ambiente_param_grupo
    ambiente_param_prog ---|"cod-param-ambiente"| ambiente_param
    audit_registro ---|"banco = 'sh' + banco, tabela"| audit_tabela
    audit_registro_detalhe ---|"id-registro"| audit_registro
    audit_registro_notificar ---|"id-registro"| audit_registro
    audit_tabela_acesso ---|"banco, tabela"| audit_tabela
    audit_tabela_notificacao ---|"banco, tabela"| audit_tabela
    inbound_rota ---|"aplicacao, objeto"| objeto
    mensagem ---|"aplicacao, objeto"| objeto
    mensagem_conteudo ---|"codigo-mensagem"| mensagem
    mensagem_historico ---|"codigo-mensagem"| mensagem
    mensagem_item ---|"codigo-mensagem"| mensagem
    objeto_parametro ---|"aplicacao, objeto"| objeto

    %% tracejada: sem índice (código ou valor)
    ambiente_param_variavel -.-|"cod-ambiente"| ambiente
    ambiente_param_variavel -.-|"cod-param-ambiente"| ambiente_param
    email -.-|"cod-param-ambiente"| ambiente_param
    email_param -.-|"cod-grp-usuar"| ambiente_param_grupo
    audit_tabela_notificacao -.-|"grupo-email = cod-grp-usuar (nenhum código lê)"| ambiente_param_grupo
    objeto -.-|"aplicacao"| aplicacao
    objeto_usuario -.-|"aplicacao, objeto"| objeto
    objeto -.-|"aplicacao + '.' + objeto = cod-prog-dtsul"| ambiente_param_prog
    objeto_parametro -.-|"cod-param-ambiente / -destino = cod-variavel"| ambiente_param_variavel
    mensagem_ped_exec -.-|"codigo-mensagem"| mensagem
    conexao_rest_autenticacao -.-|"cod-conexao"| conexao_rest
    conexao_rest_header -.-|"cod-conexao"| conexao_rest
    conexao_rest -.-|"valor da variável = cod-conexao"| ambiente_param_variavel
    conexao_rest_path -.-|"valor da variável = cod-path"| ambiente_param_variavel
    audit_tabela_campo -.-|"banco, tabela"| audit_tabela
    audit_tabela_purge -.-|"banco, tabela"| audit_tabela
```
<!-- er-diagrama:fim -->

## O que o diagrama mostra (achados de 2026-09-25)

- **`thl-conexao-rest-path` não pertence a uma conexão.** O `ConnectorConfig` lê `cod-conexao` e `cod-path` como valores de **duas variáveis de ambiente distintas**; o mesmo path pode ser usado com qualquer conexão. (Guia corrigido em 2026-09-25.)
- **Conexão REST só se liga ao resto por valor**, através de `thl-ambiente-param-variavel`. Caminho completo: `thl-objeto` → `thl-ambiente-param-prog` (programa `aplicacao.objeto`) dá o parâmetro; `thl-objeto-parametro.cod-param-ambiente` e `-destino` são **códigos de variável** desse parâmetro (apesar do nome); o **valor** das variáveis é o `cod-conexao` e o `cod-path`. Passo a passo em `Documentos/tecnico/guia-configuracao-conector-rest.md` §3.
- **`thl-aplicacao`** só está ligada a `thl-objeto` (zoom no thl0021). As demais tabelas carregam `aplicacao` como parte da chave do objeto (`aplicacao, objeto`); nada valida o valor contra o cadastro.
- **`thl-audit-registro.banco` tem o prefixo `sh`** (nome do banco na sessão, gravado pelo `AuditLogService`); a configuração (`thl-audit-tabela*`) guarda sem ele. O índice `fk-audit-tabela` existe, mas a ligação é `registro.banco = 'sh' + tabela.banco`.
- **`thl-audit-tabela-notificacao.grupo-email`** aponta para o grupo de e-mail só pela descrição do `.df`: nenhum código lê o campo (a notificação por grupo ainda não existe).
- **Sem índice `fk-*`** em vínculos usados no código: `thl-objeto-usuario` → `thl-objeto`, `thl-mensagem-ped-exec` → `thl-mensagem`, `thl-audit-tabela-campo`/`-purge` → `thl-audit-tabela`, `thl-ambiente-param-variavel` → ambiente/parâmetro. Em parte deles a própria `pk-` cobre a busca (os campos do pai vêm primeiro), por isso não há problema de desempenho — é só o vínculo que não fica declarado.

## Fora do diagrama (ERP)

`cod-usuario` (usuário Datasul em `thl-objeto-usuario`, `thl-ambiente-param-grupo-usuar`, `thl-audit-tabela-acesso`), `cod-prog-dtsul` (programa Datasul), `num-ped-exec` (pedido RPW) e `banco`/`tabela` da auditoria (a tabela auditada do ERP).
