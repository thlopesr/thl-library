# Motor genérico de cadastros (`shared\crud\`)

Contrato do motor que desenha **todos** os cadastros do app `cadastro`. Nenhum cadastro tem componente próprio: cada um é uma definição `CrudResource` em `cadastros\cadastros.defs.ts`, e a rota passa a definição em `data: { def }` para o `ThlCrudPageComponent` (`cadastro.routes.ts`).

Visão geral do app e rotas em [app-web.md](app-web.md). Armadilhas do PO UI que moldaram estas decisões em [poui-licoes.md](poui-licoes.md).

## Peças

| Peça | Papel |
|---|---|
| `crud.model.ts` | `CrudResource`, `CrudField`, `CrudOption`, `CrudListResult` |
| `crud.service.ts` | `list(resource, faixa)` → `<campo>Ini/Fin`, devolve `{ items, total, hasNext }`; `create`; `update` (PATCH); `delete` com a chave no corpo |
| `thl-crud-list` | Browse, coluna "Ação", formulário em modal, Detalhar em modal, estado de erro |
| `thl-crud-children` | Card da linha expandida: chave do pai e uma aba por filho, com contador |
| `thl-crud-page` | `thl-page-header` (com contador no subtítulo) + filtro local + "Adicionar" + lista |

## `CrudResource`

| Campo | Efeito |
|---|---|
| `resource` | Rota da API: `/api/thl/integration/v1/resourcen/<resource>` |
| `title`, `subtitle`, `singular`, `feminine` | Textos da página, das abas e dos títulos de modal ("Novo ambiente", "Nova conexão") |
| `fields` | Campos (abaixo) |
| `children` | Recursos filhos, uma aba cada na linha expandida |
| `parentKeys` | Chave herdada do pai: filtro do GET e valor fixo no corpo |
| `parentFilter` | Prefixo do filtro quando difere do campo (`{ codParametro: 'parametro' }` → `parametroIni/Fin`) |
| `single` | No máximo um registro por pai: esconde "Adicionar" e o contador da aba |
| `noUpdate` | Recurso sem PATCH: só inclui e exclui |
| `titleField` | Campo usado como título do card da linha expandida |

## `CrudField`

**Chave e validação**

| Campo | Efeito |
|---|---|
| `key` | Obrigatório e bloqueado na edição |
| `required`, `maxLength` | Validação do formulário |
| `pattern` + `errorMessage` | Validação por expressão regular (formato de e-mail) |
| `default` | Valor inicial no "Adicionar" |

**Onde o campo aparece**

| Campo | Efeito |
|---|---|
| `column` | Aparece no browse; o que não aparece fica só no formulário e no Detalhar |
| `columnLabel` | Rótulo curto só no cabeçalho da coluna (o `label` continua no formulário) |
| `columnWidth` | Largura fixa — **só** em colunas curtas e previsíveis; as de texto ficam livres |
| `tab` | Aba do modal (formulário e detalhe). Sem `tab` em nenhum campo, o modal não tem abas |
| `group` | Divisor dentro da aba |
| `gridColumns` | Largura no formulário (padrão 6 de 12) |

**Aparência do campo**

| Campo | Efeito |
|---|---|
| `type` | `string`, `number`, `boolean`, `password` (mascarado: `********` reenviado mantém o valor), `textarea` |
| `icon`, `placeholder`, `clean` | Repassados ao `po-dynamic-form`. ⚠️ `icon` só funciona em `po-input`/`po-combo` |
| `options` | Domínio fixo: combo no formulário, rótulo em texto no browse |
| `tagColumn` | O domínio vira `po-tag` colorida no browse. A cor de cada opção vem do `CrudOption`: `tag` (semântica: `success`, `warning`, `danger`, `info`, `neutral`) ou `tagColor` (cor do tema, `color-01`…`color-12`). ⚠️ **Só com `tagColor` o `icon` da opção aparece** — `tag` sobrepõe cor e ícone pelos do tipo |
| `optionsFrom` / `optionsFromExtra` | Zoom: opções carregadas de outro recurso + opções fixas (`*`) |
| `richText` | No formulário, edita em `po-rich-text` em vez de textarea |
| `html` | No Detalhar, renderiza o conteúdo como HTML |
| `help` | Texto de ajuda abaixo do campo |

## Regras que o motor aplica

- **Incluir e editar** — sempre em modal, no pai e nos filhos. O Salvar valida **todas** as abas (uma instância de `po-dynamic-form` por aba) e avisa quando há pendência em aba não aberta.
- **Detalhar** — usa o mesmo `po-dynamic-form` do Editar com os campos em `readonly`: mesma moldura, larguras, divisores e abas. Todo campo vira texto em leitura com o valor já traduzido por `exibir` (rótulo do domínio, `Sim`/`Não`, `********`, `—` para vazio). **`readonly`, não `disabled`** — `disabled` tiraria os campos da navegação por teclado e do leitor de tela.
- **Erro de carregamento** — mensagem do backend e botão **Tentar novamente** no lugar da tabela. Erro e lista vazia não podem se parecer. Só a mensagem do corpo da resposta é exibida; a do `HttpErrorResponse` é técnica demais. O `PoHttpInterceptorModule` ainda mostra a notificação dele, que é complementar.
- **Busca** — filtra só o que já está carregado (a API devolve até 100 registros), por isso o placeholder é "Filtrar os registros carregados". Quando a resposta traz `hasNext`/`total` maior que o carregado, aparece um aviso abaixo da tabela.
- **Contador** — o subtítulo da página mostra "N registros".
- **Valor fora do domínio** — entra como tag neutra com o valor cru (`completarTags`); sem isso o `type: 'label'` deixaria a célula vazia e esconderia dado inconsistente.
- **Gerenciador de colunas** — escondido quando a tabela tem menos de três colunas de dados.

## Decisões de layout dos formulários

- **Identificador + descrição em 4 + 8 colunas** (Ambiente, Parâmetro, Conexão, Path, Grupo; Banco + Tabela em 3 + 9). Tratar os dois como 6 + 6 dá o mesmo peso a coisas de peso diferente.
- **Campo longo ou estruturado ocupa as 12**: URL, path, classe ABL, chave primária JSON, assunto, cópia, parâmetros/headers, valor.
- **Ícone só quando comunica o formato**: `an-envelope` e-mail, `an-user` usuário, `an-globe` URL, `an-path` path, `an-code` classe ABL, `an-database` banco, `an-table` tabela, `an-buildings` estabelecimento. Código, descrição e nome de negócio ficam sem — ícone repetido que não informa vira textura.
- **Placeholder** mostra o formato esperado e funciona em todos os tipos de campo, inclusive nos que não aceitam ícone.

## Decisões de cor no browse

Tag colorida só para **estado do registro** e **escala de severidade**; atributo de configuração fica em texto.

| Coluna | Tratamento |
|---|---|
| Situação (Ativo/Inativo) | `success` / `neutral` |
| Nível de sensibilidade e de acesso | `neutral` / `warning` / `danger` |
| Sentido (Entrada/Saída) | `tagColor` do tema + seta (`an-arrow-down-left` / `an-arrow-up-right`) |
| Audita tabela, Requer token, Gera histórico | texto `Sim`/`Não` |

**Situação unifica `ind-inativo` e `ind-ativo`.** As telas usavam polaridades opostas — em Objeto lia-se "Inativo: Não" para dizer que estava ativo. O campo no banco continua o que é; muda só o domínio apresentado (`SITUACAO_POR_INATIVO` e `SITUACAO_POR_ATIVO`).

## Cadastros em uso

| Menu | Pai (`resource`, chave) | Filhos (abas) |
|---|---|---|
| Ambiente | `ambiente` (`codAmbiente`) | — (cadastro simples, por decisão do responsável) |
| Parâmetro | `parametro-ambiente` (`codParametro`) | Variáveis `parametro-variavel` (N; `codAmbiente` + `codVariavel`; Ambiente por zoom de `ambiente` + `*`) · Programas `parametro-programa` (N; sem PATCH) |
| Grupo de e-mail | `grupo-email` (`grupoEmail`) | Destinatários `grupo-email-usuario` (N; sem PATCH; chave `usuario` + `emailAlternativo`, então o mesmo usuário entra mais de uma vez com endereços diferentes) |
| E-mail | `email-parametro` (`emailParam`) | — (Grupo de e-mail por zoom de `grupo-email`) |
| Objeto | `objeto` (`aplicacao` + `objeto`) | Parâmetros `objeto-parametro` (N; `estabelecimento` + `operacao`; 16 campos em 4 blocos) · Usuários `objeto-usuario` (N; sem PATCH) |
| Conexão | `conexao-rest` (`conexao`) | Autenticação `conexao-rest-autenticacao` (única; `senha`, `headersToken`, `parametersToken` mascarados) · Header `conexao-rest-header` (único) |
| Path | `conexao-rest-path` (`endpoint`) | — (independente da conexão: o mesmo path serve a várias conexões/ambientes) |
| Rota | `inbound-rota` (`rota`) | — (zoom de Aplicação e Objeto a partir de `objeto`) |
| Auditoria | `auditoria-tabela` (`banco` + `tabela`) | Campos · Acessos · Notificações (N; Grupo de e-mail por zoom) · Expurgo (único) |

Abas em uso: Parâmetro do objeto (Geral · Ambiente · Persistência, com o divisor Log · Servidor), Autenticação (Acesso · Token), Path (Geral · Parâmetros · Headers) e E-mail (Geral · Mensagem).

## Domínios

Informados pelo responsável em 2026-10-01, a partir dos `&global` das telas:

- Modelo de integração: 1 REST · 2 SOAP · 3 Database · 4 File
- Forma de execução: 1 Online · 2 Agendar · 3 Batch
- Tipo de log da requisição/retorno: 1 Pendente · 2 Erro · 3 Sucesso · 4 Não aplicável
- Nível de sensibilidade e de acesso: 1 Normal · 5 Crítico · 9 Restrito
- **Tipo de autenticação**: `BASIC`, `BEARER`, `TOKEN`, `CUSTOM.BODY` — os únicos valores tratados pelo `case` do [RestConnector](../integration/connectors.md). Qualquer outro sai sem cabeçalho de autenticação, em silêncio.
- Ainda numérico, sem domínio definido: `importancia` (e-mail).

## Regras de negócio refletidas na tela

- **Cópia do e-mail** aceita lista separada por **vírgula**, que é como o `EmailParamRepository` monta os destinatários para a `utp/utapi019.p`.
- **Marcadores da mensagem** são `#1#`, `#2#`… (`EmailMessageFactory:applyPlaceholder`), não `&campo`.
- A rota **`aplicacao`** (`AplicacaoMessage`, thl0020) é usada como zoom do campo Aplicação do Objeto; ainda não tem tela própria.

## Modelo de browse pai + filhos

- Cabeçalho `thl-page-header` com `thl-search-bar` (`showAdvanced=false`) e o botão primário **"Adicionar"** ao lado, em `.thl-barra`; sem ações no `po-page-list`. O rótulo é fixo ("Adicionar", verbo, sem concordância de gênero); o nome do registro fica no título do modal, montado com `singular`/`feminine`.
- Cadastro sem `children` é lista simples, sem seta de expansão.
- Linha expandida = card (`thl-detalhe.scss`, borda esquerda `--color-brand-01-base`) com título, subtítulo e `po-tabs`. Sem botão de editar o pai no card — a edição fica no "⋯" da linha principal.
- Cada aba (`thl-vinculos.scss`): cabeçalho "… vinculadas" + "Adicionar"; lista vazia vira estado vazio tracejado com o mesmo botão.
- Estilos compartilhados em `shared\styles\`: `thl-browse.scss`, `thl-detalhe.scss`, `thl-vinculos.scss`.

## Pendências para a versão 2

Decisão do responsável:

- Zoom dos campos sem endpoint de consulta (usuário Datasul, estabelecimento) — hoje texto livre validado pelo backend.
- Paginação: os GET usam `pageSize` padrão 100 e `hasNext` sempre falso; acima de 100 registros a lista corta (o aviso da tela só acende quando o backend passar a informar).
- Domínio de `importancia`, ainda numérico.
- O zoom de Objeto na Rota não filtra pelo valor de Aplicação.

## Fontes

Campos, chaves e filtros: coleção **Nitro** do Postman (pasta THL). Grupo de e-mail veio das classes `GrupoEmail*Message`/`Service` e de [data/schema.md](../data/schema.md), por não estar na coleção. Mock de desenvolvimento em `mock\cadastro-mock.data.ts`.
