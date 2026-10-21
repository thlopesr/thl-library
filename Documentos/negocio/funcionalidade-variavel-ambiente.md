# Funcionalidade Variável de ambiente — configuração por ambiente

A THL guarda **valores que mudam de um ambiente para outro** (produção, homologação, desenvolvimento) fora do programa. O código pede a variável pelo nome e recebe o valor do ambiente onde está rodando. Assim, o mesmo programa funciona em qualquer ambiente, sem endereço, usuário ou senha escritos dentro do código.

Este guia explica a funcionalidade e os cadastros em linguagem de negócio. O detalhe campo a campo está em [guia-telas-web.md](guia-telas-web.md); o fluxo técnico, em [fluxo-ambiente](../.claude/fluxos/fluxo-ambiente.md).

> Verificado por leitura do código e das notas do projeto. Nada foi executado contra o Datasul para escrever este guia.

## Como funciona

1. **A THL descobre em que ambiente está.** Cada ambiente cadastrado tem um **IP** (na prática, um texto). A THL procura esse texto **dentro do PROPATH** da sessão. O primeiro ambiente que casar vale.
2. **A THL descobre qual parâmetro atende o programa.** Cada programa é vinculado a um **parâmetro** no cadastro. O vínculo é funcional: sem ele, a THL não acha a configuração e o fluxo para.
3. **A THL entrega o valor da variável.** Procura primeiro o valor do ambiente atual. Se não houver, procura o valor cadastrado para **todos os ambientes** (`*`). Se também não houver, devolve vazio, sem erro, e o problema aparece em quem usou o valor.

Exemplo: o parâmetro `INTEGRACAO-X` tem a variável `URL-BASE`. Em produção vale o endereço de produção, em homologação o de homologação. O programa pede só `URL-BASE`.

## Quem usa a variável de ambiente

| Funcionalidade | Uso |
|---|---|
| [Integração de saída](funcionalidade-integracao.md) | A variável diz qual **Conexão** e qual **Path** usar. O vínculo do programa é `APLICACAO.OBJETO` |
| [E-mail](funcionalidade-email.md) | A variável `codigo.email` diz qual parâmetro de e-mail o programa usa, e pode mudar por ambiente |

## Cadastros

| Cadastro | Programa Datasul | Para que serve |
|---|---|---|
| **Ambiente** | thl0001 | Declara os ambientes do cliente. Campos: código, nome e IP (o texto procurado no PROPATH) |
| **Parâmetro** | thl0002 | Agrupa as variáveis de um assunto. Tem duas abas: **Variáveis** (o valor em cada ambiente) e **Programas** (quais programas usam o parâmetro) |

**Variáveis (aba do parâmetro)**

- Cada linha tem **ambiente**, **variável** e **valor**.
- Ambiente `*` vale para todos. Use para o que não muda entre ambientes: reduz o número de linhas e o risco de esquecer uma na promoção.
- Valores sensíveis (senhas, chaves) aparecem **mascarados**. Deixe como está para não sobrescrever o valor real.
- Em integração, o valor costuma ser o **código de outro cadastro** (uma Conexão ou um Path), e não o endereço em si.

**Programas (aba do parâmetro)**

- Liga o parâmetro a um programa Datasul. Em integração de saída o nome é `APLICACAO.OBJETO`.

Pontos de atenção:

- **Identificador do ambiente:** um texto curto demais pode casar com o PROPATH de outro ambiente, e um texto que não está no PROPATH nunca é reconhecido. O ambiente fica guardado na sessão: ao alterar o cadastro, é preciso **nova sessão** para valer.
- **Eliminar:** apagar um ambiente apaga as variáveis dele. Um parâmetro com variáveis ou programas vinculados não pode ser eliminado.
- Se o ambiente não for identificado, a THL para com a mensagem "Ambiente nao identificado".

## Como configurar

1. Cadastre os **Ambientes** (código, nome e IP).
2. Cadastre o **Parâmetro** do assunto.
3. Na aba **Variáveis**, cadastre cada variável por ambiente, ou uma só com `*` quando o valor é o mesmo em todos.
4. Na aba **Programas**, vincule o programa que vai usar o parâmetro.
5. Em nova sessão, confira se o programa recebe o valor esperado.

## Limitações a conhecer

- Variável sem valor devolve vazio, sem aviso. Se uma integração falha dizendo que a conexão ou o caminho não foram informados, confira primeiro a variável e o vínculo do programa.
- O reconhecimento do ambiente depende do PROPATH. Mudança de PROPATH pode mudar o ambiente reconhecido.
