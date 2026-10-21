# Funcionalidade Integração — troca de mensagens com sistemas externos

A Integração é a parte da THL que **recebe** dados de sistemas externos no Datasul (entrada) e **envia** dados do Datasul para sistemas externos (saída), de forma padronizada, configurável e rastreável. Cada troca vira uma **mensagem** que pode ser consultada, investigada e reprocessada.

Este guia explica a funcionalidade e os cadastros que a configuram, em linguagem de negócio. O detalhe campo a campo está em [guia-telas-web.md](guia-telas-web.md); os fluxos técnicos, em [fluxo-entrada](../.claude/fluxos/fluxo-entrada.md) e [fluxo-saida](../.claude/fluxos/fluxo-saida.md).

> Verificado por leitura do código e das notas do projeto. Nada foi executado contra o Datasul para escrever este guia.

## Conceitos

| Termo | O que é |
|---|---|
| **Aplicação** | O sistema externo que conversa com o Datasul (por exemplo, um sistema de logística) |
| **Objeto** | O que é trocado com essa aplicação (nota fiscal, pedido, item, embarque) |
| **Operação / método** | O que se faz com o objeto: criar (POST), alterar (PATCH ou PUT), eliminar (DELETE) ou consultar (GET) |
| **Mensagem** | O registro de uma troca. Guarda situação, conteúdo e histórico |
| **Entrada** | O sistema externo chama o Datasul |
| **Saída** | O Datasul chama o sistema externo |

Toda mensagem passa por **três fases**: **Requisição** (o pedido chegou ou foi montado), **Processamento** (o ERP executou) e **Retorno** (a resposta foi entregue). Cada fase tem a sua situação: Pendente, Sucesso, Erro ou Não aplicável.

## Como funciona a entrada

1. O sistema externo chama o endereço público do Datasul. O endereço final tem a forma `…/api/thl/integration/v1/resourcen/<rota-pública>`.
2. A THL procura a **rota pública** no cadastro e descobre qual objeto atende. Rota inativa não é encontrada.
3. Pelo **método** (POST, PATCH, GET…) e pela **operação** da URL, a THL escolhe a linha de configuração do objeto. Ela define qual classe processa a mensagem e como (na hora ou agendado).
4. A mensagem é gravada, processada e a resposta volta ao sistema externo. Em caso de erro, a mensagem fica registrada com a causa.
5. Se a linha estiver configurada como **agendada**, o processamento acontece depois, por uma tarefa do Datasul (thl0221).

Só usuários cadastrados no objeto acompanham as mensagens dele nos monitores.

## Como funciona a saída

1. O programa do ERP monta a mensagem com os dados do objeto e pede o envio.
2. A THL descobre **para onde enviar** pela configuração do ambiente: o objeto aponta para uma variável de ambiente, e o valor dela no ambiente atual é o código de uma **Conexão** (endereço) e de um **Path** (caminho). A URL final é o endereço da Conexão mais o caminho do Path.
3. Se a conexão exigir, a THL se **autentica** no sistema externo (usuário e senha, token ou cabeçalho calculado) antes de enviar.
4. A resposta é gravada na mensagem: situação, código de retorno e descrição. Se a chamada falhar antes da resposta (rede, tempo esgotado), a mensagem registra o erro, e nunca fica sem rastro.
5. Mensagens com erro podem ser **reenviadas** pelo monitor de mensageria (thl0120) ou pela tarefa de reprocessamento (thl0220). A THL recusa reprocessar uma mensagem que está agendada, para evitar envio duplicado.

Por usar variável de ambiente, o mesmo objeto envia para produção em um ambiente e para homologação em outro, sem mexer no programa. Veja [funcionalidade-variavel-ambiente.md](funcionalidade-variavel-ambiente.md).

## Formas de execução

| Forma | Quando processa |
|---|---|
| **Online** | Na hora em que a mensagem chega ou é montada |
| **Agendar** | Depois, por uma tarefa do Datasul (RPW) |
| **Batch** | Em lote; nenhuma ação imediata |

Os campos de frequência e de tentativas existem no cadastro, mas **hoje não geram reenvio automático**: o reenvio é feito pelo monitor ou pela tarefa de reprocessamento.

## Rastreio: histórico e conteúdo

- **Gera histórico:** guarda uma linha por tentativa de cada mensagem. Serve para investigar reprocessamentos.
- **Gravação do conteúdo:** define quando o conteúdo trocado é guardado (sempre, só em erro ou nunca). Com "nunca", a mensagem aparece nos monitores, mas **sem o conteúdo**. Esse campo afeta o volume do banco.
- Mensagens processadas com sucesso são **expurgadas após 21 dias** pela tarefa de expurgo (thl0222).

## Paginação das consultas (entrada)

Quando um sistema externo **consulta** uma lista (GET) pela integração de entrada, o resultado pode ser grande. A THL devolve a lista **por páginas**: o consultante informa o tamanho da página e qual página quer, e a THL pula os registros anteriores e para quando a página está completa. Essa lógica é feita pelo `PaginationHelper`.

Ela é **restrita à integração de entrada**: serve às consultas de lpco, item, centro de custo, e-mail, mensageria e auditoria. Por isso não faz parte do [Utils](funcionalidade-utils.md). Não há uso avulso em outros programas.

> Cuidado: contagens confiáveis vêm das telas de métricas, que somam o período inteiro. As listas são paginadas.

## Cadastros da integração

Os cadastros formam uma cadeia: **Aplicação → Objeto → (Parâmetros, Rota, Usuários)** descreve **o que** é trocado; **Conexão → (Autenticação, Header) → Path** descreve **para onde** a saída vai. Eles existem nos programas do Datasul e nas telas web.

| Cadastro | Programa Datasul | Para que serve |
|---|---|---|
| **Aplicação** | thl0020 | Registra o sistema externo. Toda mensagem pertence a uma aplicação. O campo **Origem** (Interna ou Externa) separa o tráfego do próprio THL, que fica oculto por padrão nas métricas |
| **Objeto** | thl0021 | O centro da configuração: o que é integrado, qual classe processa a mensagem, o sentido (entrada ou saída), se está ativo e se gera histórico |
| **Objeto — parâmetros** | thl0022 | Uma linha por operação, método e estabelecimento: forma de execução, quando guardar conteúdo, qual variável de ambiente traz a Conexão e o Path |
| **Objeto — rota** | thl0040 | O trecho público da URL que leva ao objeto. Precisa ser único entre todas as rotas |
| **Objeto — usuários** | thl0022 (aba) | Quem pode acompanhar as mensagens do objeto |
| **Conexão** | thl0030 | O endereço base do sistema externo, usado na saída |
| **Autenticação** | thl0032 | Como o Datasul se identifica na API externa (usuário e senha, token ou cabeçalho). É uma por conexão |
| **Header** | thl0033 | Cabeçalho calculado por classe, para APIs que exigem assinatura. Normalmente é preenchido pela TI |
| **Path** | thl0031 | O caminho de cada endpoint, separado da conexão: o mesmo endpoint pode servir a mais de uma conexão (produção e homologação) |

Pontos de atenção:

- **A classe do objeto é um vínculo com o código-fonte.** Renomear ou mover a classe exige atualizar este cadastro, senão a integração para. O mesmo vale para a classe da autenticação e do header.
- **Eliminar em cascata:** apagar um objeto apaga também as operações, os usuários e a rota (as mensagens já trocadas ficam). Apagar uma conexão apaga a autenticação e o header. Uma aplicação com objetos não pode ser eliminada.
- O parâmetro de ambiente do objeto guarda o **nome de uma variável**, não o endereço. O endereço fica na variável de ambiente.

## Como configurar uma nova integração

**Entrada (um sistema externo chama o Datasul)**
1. Cadastre a **Aplicação**, se ainda não existir.
2. Cadastre o **Objeto**, com sentido **Entrada** e a classe que o processa (trabalho da TI).
3. Cadastre as **linhas de parâmetros** para cada método usado e defina a forma de execução.
4. Cadastre a **Rota** do objeto e os **Usuários** que acompanham.
5. Informe ao sistema externo o endereço final com a rota pública.

**Saída (o Datasul chama um sistema externo)**
1. Cadastre a **Aplicação** e o **Objeto**, com sentido **Saída**.
2. Cadastre a **Conexão** (endereço base), a **Autenticação** e o **Path**.
3. Cadastre o **Parâmetro** de ambiente com as variáveis que apontam para a Conexão e o Path, e vincule o programa `APLICACAO.OBJETO` (veja [funcionalidade-variavel-ambiente.md](funcionalidade-variavel-ambiente.md)).
4. Na linha de parâmetros do objeto, informe os nomes das duas variáveis.
5. Teste e acompanhe no monitor de mensageria.

## Acompanhamento

| Para… | Use |
|---|---|
| Investigar uma mensagem (entrada, saída, retorno, erro) | Monitor de mensageria (thl0120, ou tela web) |
| Ver onde está o volume e onde está o erro | Métricas da mensageria (web) |
| Reprocessar mensagens de saída | Tarefa thl0220 |
| Processar mensagens de entrada agendadas | Tarefa thl0221 |
| Limpar mensagens antigas | Tarefa thl0222 |

Passo a passo de uso: [guia-monitoramento-mensageria.md](guia-monitoramento-mensageria.md).

## Limitações a conhecer

- Frequência e tentativas do cadastro ainda não disparam reenvio automático.
- URL errada na entrada não gera "não encontrado": a THL tenta um objeto com aquele nome e falha adiante como objeto inexistente.
- Mensagens sem conteúdo gravado aparecem nos monitores sem o conteúdo trocado.
