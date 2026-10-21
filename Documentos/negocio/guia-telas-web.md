# Guia das telas web da THL — programa a programa

> Escrito em 2026-10-09 a partir do código em `Fontes/web`, do dicionário do banco (`Database/Definition/thl.df`) e do mapa de programas em [`../.claude/thl/camada-datasul.md`](../.claude/thl/camada-datasul.md). Cobre **apenas as telas web**; os programas `.w` do Datasul estão em [`guia-cadastros-thl.md`](guia-cadastros-thl.md).

A THL tem **duas interfaces para a mesma configuração**: os programas `.w` dentro do Datasul e os dois aplicativos web (`thl-html-cadastro` e `thl-html-consulta`). Os dados são os mesmos — as tabelas do banco THL. Muda só por onde se mexe.

Cada seção abaixo responde quatro perguntas na mesma ordem: **o que é a tela**, **para que serve**, **quais tabelas usa** e **o que cada campo faz**.

## Como ler as tabelas de campos

| Coluna | O que significa |
|---|---|
| **Campo** | O rótulo como aparece na tela |
| **Preenchimento** | *Chave* identifica o registro e não muda depois de salvo · *Obrigatório* impede gravar em branco · *Opcional* pode ficar vazio. O limite de caracteres vem do dicionário do banco |
| **O que faz** | O efeito do campo no funcionamento da integração, não apenas o nome repetido |

## Índice

**Cadastro** — define como a integração funciona

1. [Ambiente](#ambiente) · 2. [Parâmetro](#parâmetro) · 3. [Grupo de e-mail](#grupo-de-e-mail) · 4. [E-mail](#e-mail) · 5. [Aplicação](#aplicação) · 6. [Objeto](#objeto) · 7. [Conexão](#conexão) · 8. [Path](#path) · 9. [Auditoria](#auditoria)

**Consulta** — mostra o que a integração fez

10. [Métricas](#métricas) · 11. [Métricas por assunto](#métricas-por-assunto) · 12. [Monitor de mensageria](#monitor-de-mensageria) · 13. [Monitor de e-mail](#monitor-de-e-mail) · 14. [Monitor de auditoria](#monitor-de-auditoria)

---

# Parte 1 — Cadastro

---

## Ambiente

| | |
|---|---|
| **Tela** | `#/ambiente` no menu Cadastro |
| **Programa Datasul equivalente** | `thl0001` |
| **Rota da API** | `resourcen/ambiente` |
| **Tabela** | `thl-ambiente` |

**Para que serve.** Declara os ambientes do cliente — produção, homologação, desenvolvimento. É o cadastro que permite ao mesmo código rodar em lugares diferentes sem alteração: o framework descobre em qual ambiente está pelo IP e, a partir daí, resolve os valores dos parâmetros.

| Campo | Preenchimento | O que faz |
|---|---|---|
| **Código** | Chave, até 20 caracteres | Identifica o ambiente nas variáveis de parâmetro. Ex.: `PRODUCAO`, `HOMOLOGACAO` |
| **Nome** | Obrigatório, até 60 caracteres | Nome por extenso, usado nas telas e mensagens |
| **IP** | Opcional, até 40 caracteres | Texto procurado **dentro do PROPATH** da sessão para reconhecer o ambiente — não é comparado com o IP da máquina. Sem ele, o ambiente nunca é escolhido; um valor curto demais pode casar com outro ambiente por acidente |

> **Exclusão em cascata:** eliminar o ambiente elimina junto as variáveis de parâmetro dele.

---

## Parâmetro

| | |
|---|---|
| **Tela** | `#/parametro` |
| **Programa Datasul equivalente** | `thl0002` (+ abas `a`, `b`, `c`) |
| **Rota da API** | `resourcen/parametro-ambiente`, com as operações `variavel` e `programa` |
| **Tabelas** | `thl-ambiente-param`, `thl-ambiente-param-variavel`, `thl-ambiente-param-prog` |

**Para que serve.** Guarda os valores que mudam de um ambiente para outro — URLs, credenciais, chaves, caminhos. O código pede o parâmetro pelo nome e recebe o valor do ambiente onde está rodando. É o que evita ter endereço de produção escrito dentro do programa.

**Formulário principal**

| Campo | Preenchimento | O que faz |
|---|---|---|
| **Código** | Chave, até 20 caracteres | Nome pelo qual o código pede o parâmetro |
| **Descrição** | Obrigatório, até 60 caracteres | Descrição do parâmetro |

**Aba Variáveis** — o valor em cada ambiente

| Campo | Preenchimento | O que faz |
|---|---|---|
| **Ambiente** | Chave | A qual ambiente este valor se aplica. `*` vale para todos os ambientes e é consultado quando não há linha para o ambiente atual |
| **Variável** | Chave, até 40 caracteres | Nome da variável dentro do parâmetro |
| **Descrição** | Opcional, até 60 caracteres | Descrição da variável |
| **Valor** | Opcional | O valor propriamente dito. **Valor sensível volta mascarado com asteriscos** — deixe como está para não sobrescrever a senha real |

**Aba Programas** — quais programas usam o parâmetro

| Campo | Preenchimento | O que faz |
|---|---|---|
| **Programa** | Chave, até 40 caracteres | Programa Datasul vinculado ao parâmetro. **É por esta linha que o framework descobre qual parâmetro atende cada programa** — cadastro obrigatório, não documentação de uso. Em integração de saída, o nome é `APLICACAO.OBJETO` |

> **Exclusão:** o parâmetro não é eliminado enquanto tiver variáveis ou programas vinculados.

---

## Grupo de e-mail

| | |
|---|---|
| **Tela** | `#/grupo-email` |
| **Programa Datasul equivalente** | `thl0011` |
| **Rota da API** | `resourcen/grupo-email`, operação `usuario` |
| **Tabelas** | `thl-ambiente-param-grupo`, `thl-ambiente-param-grupo-usuar` |

**Para que serve.** Define listas de destinatários reutilizáveis. Em vez de repetir endereços em cada parâmetro de e-mail e em cada notificação de auditoria, aponta-se para o grupo.

| Campo | Preenchimento | O que faz |
|---|---|---|
| **Grupo** | Chave, até 20 caracteres | Código referenciado pelos parâmetros de e-mail e pelas notificações de auditoria |
| **Descrição** | Opcional, até 60 caracteres | Descrição do grupo |

**Aba Destinatários**

| Campo | Preenchimento | O que faz |
|---|---|---|
| **Usuário** | Chave, obrigatório | Usuário do Datasul. O e-mail sai para o endereço cadastrado nele |
| **E-mail alternativo** | Chave | **Acrescenta** um endereço — não substitui: se o usuário tiver e-mail no cadastro do ERP, recebe nos dois. Em branco, vale só o do ERP. Faz parte da chave, então o mesmo usuário pode constar mais de uma vez |

> **Exclusão:** o grupo não é eliminado enquanto estiver em uso por um parâmetro de e-mail ou por uma notificação de auditoria. Sem esses vínculos, eliminar o grupo elimina junto os destinatários.

---

## E-mail

| | |
|---|---|
| **Tela** | `#/email` no menu Cadastro |
| **Programa Datasul equivalente** | `thl0010` |
| **Rota da API** | `resourcen/email-parametro` |
| **Tabela** | `thl-email-param` |

**Para que serve.** Define o conteúdo de cada e-mail que o framework dispara: assunto, corpo, quem recebe. O programa que envia informa só o código do parâmetro e os valores variáveis — texto e destinatários vêm daqui, e podem mudar sem tocar em código.

| Campo | Preenchimento | O que faz |
|---|---|---|
| **Código** | Chave, até 40 caracteres | Código do parâmetro. O programa chega até ele pela variável de ambiente `codigo.email`, e não informando o código diretamente |
| **Grupo de e-mail** | Obrigatório | Grupo que recebe a mensagem |
| **Assunto** | Obrigatório | Assunto do e-mail. Aceita marcadores |
| **Remetente** | Opcional | Endereço de quem envia. Em branco, usa o remetente padrão do ambiente |
| **Cópia** | Opcional | Endereços em cópia, **separados por vírgula** |
| **Importância** | Opcional | Importância da mensagem. ⚠️ O domínio deste campo ainda não está definido — confirme os valores aceitos antes de usar |
| **Gera log** | Opcional | Sim registra cada envio, o que alimenta o monitor de e-mail |
| **Mensagem** | Opcional | Corpo do e-mail, com editor visual e suporte a HTML |

> **Marcadores:** escreva `#1#`, `#2#` e assim por diante no assunto ou na mensagem. O programa que dispara substitui cada marcador pelo valor correspondente, na ordem. Quais valores existem depende do programa.

---

## Aplicação

| | |
|---|---|
| **Tela** | `#/aplicacao` |
| **Programa Datasul equivalente** | `thl0020` |
| **Rota da API** | `resourcen/aplicacao` |
| **Tabela** | `thl-aplicacao` |

**Para que serve.** Registra cada sistema que troca mensagens com o Datasul. Toda mensagem pertence a uma aplicação, e é por ela que o tráfego é separado nas métricas e nos monitores.

| Campo | Preenchimento | O que faz |
|---|---|---|
| **Aplicação** | Chave, até 40 caracteres | Código do sistema externo |
| **Descrição** | Obrigatório | Descrição da aplicação |
| **Origem** | Interna ou Externa | **Interna** marca o tráfego do próprio THL — inclusive as chamadas dos cadastros web. Esse tráfego fica oculto por padrão nas métricas da mensageria, para não se misturar ao volume de negócio |

> **Exclusão:** a aplicação não é eliminada enquanto tiver objetos.

---

## Objeto

| | |
|---|---|
| **Tela** | `#/objeto` |
| **Programas Datasul equivalentes** | `thl0021` (objeto), `thl0022` (parâmetros e usuários), `thl0040` (rota) |
| **Rota da API** | `resourcen/objeto`, com as operações `parametro`, `rota` e `usuario` |
| **Tabelas** | `thl-objeto`, `thl-objeto-parametro`, `thl-objeto-rota`, `thl-objeto-usuario` |

**Para que serve.** É o centro da configuração: define **o que** é integrado (nota fiscal, pedido, item) e **como**. Reúne num só lugar a classe que processa a mensagem, o sentido do fluxo, a rota pela qual ela entra e quem pode usá-la. É o cadastro com mais campos, e o que mais exige entendimento técnico.

**Formulário principal** — `thl-objeto`

| Campo | Preenchimento | O que faz |
|---|---|---|
| **Aplicação** | Chave, até 40 caracteres | Aplicação dona do objeto |
| **Objeto** | Chave, até 40 caracteres | Nome do objeto de integração |
| **Classe da mensagem** | Obrigatório | Nome completo da classe ABL que processa a mensagem, com o pacote em minúsculas |
| **Modelo de integração** | REST · SOAP · Database · File | Por qual meio a integração acontece. Padrão: REST |
| **Sentido** | Entrada ou Saída | **Entrada**: o sistema externo chama o Datasul. **Saída**: o Datasul chama o externo |
| **Situação** | Ativo ou Inativo | Inativo suspende o objeto inteiro sem apagar a configuração |
| **Gera histórico** | Opcional | Sim grava o histórico de tentativas de cada mensagem, usado para investigar reprocessamento |
| **Programa de consulta** | Opcional | Programa Datasul que consulta o objeto, por exemplo `thl0101` |

> ⚠️ **Classe da mensagem é um vínculo com o código-fonte.** O framework carrega a classe pelo nome gravado aqui. Renomear ou mover a classe exige atualizar este cadastro — senão a integração para, e o erro aparece só na execução.

**Aba Parâmetros** — `thl-objeto-parametro`, uma linha por operação e estabelecimento

| Campo | Preenchimento | O que faz |
|---|---|---|
| **Estabelecimento** | Chave | A qual estabelecimento a configuração se aplica. Asterisco vale para todos |
| **Operação** | Chave | Operação da integração. Compõe a chave junto com o método |
| **Método** | POST · PUT · PATCH · DELETE · GET | Verbo HTTP da operação. Padrão: GET |
| **Forma de execução** | Online · Agendar · Batch | Quando roda: na hora, por agendamento ou em lote |
| **Situação** | Ativo ou Inativo | Suspende apenas esta operação, não o objeto inteiro |
| **Gera histórico** | Opcional | Histórico de tentativas desta operação |
| **Mensagem simples** | Opcional | Sim: um registro por mensagem. Não: vários registros na mesma mensagem |
| **Parâmetro de ambiente** | Opcional | Nome da **variável** (não do parâmetro) que devolve o código da Conexão, por exemplo `URL-BASE`. O parâmetro vem do vínculo `APLICACAO.OBJETO` na aba Programas |
| **Parâmetro de ambiente (destino)** | Opcional | Nome da **variável** que devolve o código do Path |
| **Persistente** | Opcional | Indica se a mensagem fica gravada para reprocessamento posterior |
| **Frequência de execução** | Opcional | Intervalo entre execuções, nas formas agendada e batch |
| **Tentativas** | Opcional | Quantas vezes reprocessar antes de desistir |
| **Dias de persistência** | Opcional | Por quantos dias a mensagem fica guardada |
| **Tipo de log da requisição** | Pendente · Erro · Sucesso · Não aplicável | Em que situação registrar o log da entrada |
| **Tipo de log do retorno** | Pendente · Erro · Sucesso · Não aplicável | O mesmo, para a resposta |
| **Gravação do conteúdo** | Sempre · Somente em erro · Nunca | Quando guardar o conteúdo trocado. **Afeta o volume do banco e o que o monitor consegue mostrar**: com "Nunca", a mensagem aparece na lista mas sem o conteúdo |
| **Servidor de execução** | Opcional | Servidor RPW que executa a integração agendada |

**Aba Rota** — `thl-objeto-rota`, uma por objeto

| Campo | Preenchimento | O que faz |
|---|---|---|
| **Rota pública** | Obrigatório | Trecho da URL depois de `/resourcen/`. Precisa ser **único entre todas as rotas** — é o que o roteador usa para achar o objeto |
| **Situação** | Ativo ou Inativo | Inativo bloqueia o acesso pela rota |
| **Início da operação** | Opcional, número | `0` significa que a operação é o último segmento da URL. Em rota de vários níveis, informe o segmento onde a operação começa, de 2 em diante |

**Aba Usuários** — `thl-objeto-usuario`

| Campo | Preenchimento | O que faz |
|---|---|---|
| **Usuário** | Chave | Usuário do Datasul autorizado a usar a rota |

> **Exclusão em cascata:** eliminar o objeto elimina junto as operações, os usuários e a rota. As mensagens já trocadas (`thl-mensagem`) não são tocadas.

---

## Conexão

| | |
|---|---|
| **Tela** | `#/conexao` |
| **Programas Datasul equivalentes** | `thl0030` (conexão), `thl0032` (autenticação), `thl0033` (header) |
| **Rota da API** | `resourcen/conexao-rest`, com as operações `autenticacao` e `header` |
| **Tabelas** | `thl-conexao-rest`, `thl-conexao-rest-autenticacao`, `thl-conexao-rest-header` |

**Para que serve.** Descreve como alcançar uma API externa: o endereço base e como se autenticar nela. É usada pelas integrações de saída, quando o Datasul é quem chama.

**Formulário principal** — `thl-conexao-rest`

| Campo | Preenchimento | O que faz |
|---|---|---|
| **Conexão** | Chave, até 40 caracteres | Código da conexão |
| **Descrição** | Opcional | Descrição da conexão |
| **URL base** | Obrigatório | Endereço base da API, sem o caminho do endpoint — o caminho vem do cadastro de Path |
| **Requer autenticação** | Opcional | Sim habilita a aba Autenticação |
| **Requer header** | Opcional | Sim habilita a aba Header, para cabeçalho calculado por classe |

**Aba Autenticação** — `thl-conexao-rest-autenticacao`, uma por conexão

| Campo | Preenchimento | O que faz |
|---|---|---|
| **Tipo** | Obrigatório · BASIC · BEARER · TOKEN · CUSTOM.BODY | BASIC usa usuário e senha; BEARER e TOKEN enviam o token no cabeçalho Authorization; CUSTOM.BODY envia o token no corpo da requisição |
| **Usuário** | Opcional | Usuário da autenticação **na API externa** — não é usuário do Datasul |
| **Senha** | Opcional | Senha ou credencial correspondente |
| **Requer token** | Opcional | Sim faz o framework obter um token antes das requisições |
| **URL do token** | Opcional | Endereço do serviço que emite o token |
| **Content-Type** e **Accept** | Opcional | Cabeçalhos da requisição de token. Normalmente `application/json` |
| **Headers do token** | Opcional | Cabeçalhos extras da requisição de token, em JSON |
| **Parâmetros do token** | Opcional | Parâmetros do corpo da requisição de token, em JSON |
| **Classe do parser de token** | Opcional | Classe ABL que interpreta a resposta do token. **Mesma regra da classe da mensagem**: mover ou renomear exige atualizar aqui |

**Aba Header** — `thl-conexao-rest-header`

| Campo | Preenchimento | O que faz |
|---|---|---|
| **Classe do header** | Obrigatório | Classe ABL que monta o cabeçalho em tempo de execução, para APIs que exigem assinatura ou valor calculado |
| **Parâmetros** | Opcional | Parâmetros da classe, em JSON |

> **Exclusão em cascata:** eliminar a conexão elimina junto a autenticação e o header dela.

---

## Path

| | |
|---|---|
| **Tela** | `#/path` |
| **Programa Datasul equivalente** | `thl0031` |
| **Rota da API** | `resourcen/conexao-rest-path` |
| **Tabela** | `thl-conexao-rest-path` |

**Para que serve.** Guarda os endpoints — o caminho relativo à URL base e os cabeçalhos de cada chamada. Ficam separados da conexão porque **o mesmo endpoint pode ser usado por mais de uma conexão**, por exemplo a mesma API em produção e em homologação.

| Campo | Preenchimento | O que faz |
|---|---|---|
| **Endpoint** | Chave, até 40 caracteres | Código do endpoint |
| **Descrição** | Opcional | Descrição do endpoint |
| **Path** | Opcional | Caminho relativo, concatenado à URL base da conexão |
| **Content-Type** e **Accept** | Opcional | Cabeçalhos da chamada. Normalmente `application/json` |
| **Timeout (s)** | Opcional | Tempo limite da chamada, em segundos |
| **Parâmetros** | Opcional | Parâmetros fixos do endpoint, em JSON |
| **Headers** | Opcional | Cabeçalhos fixos do endpoint, em JSON |

---

## Auditoria

| | |
|---|---|
| **Tela** | `#/auditoria` no menu Cadastro |
| **Programas Datasul equivalentes** | `thl0050` (tabelas), `thl0051` (campos, acessos, notificações, expurgo) |
| **Rota da API** | `resourcen/auditoria-tabela`, com as operações `campo`, `acesso`, `notificacao` e `expurgo` |
| **Tabelas** | `thl-audit-tabela`, `thl-audit-tabela-campo`, `thl-audit-tabela-acesso`, `thl-audit-tabela-notificacao`, `thl-audit-tabela-purge` |

**Para que serve.** Define **quais tabelas do ERP são auditadas** e o que acontece quando alguém as altera: o que registrar, quem pode ver, quem é avisado e por quanto tempo guardar. É a configuração; os registros gerados aparecem no monitor de auditoria.

**Formulário principal** — `thl-audit-tabela`

| Campo | Preenchimento | O que faz |
|---|---|---|
| **Banco** | Chave | Banco da tabela auditada |
| **Tabela** | Chave | Tabela auditada |
| **Chave primária** | Opcional, JSON | Lista dos campos que formam a chave, em formato de lista JSON. É o que permite identificar qual registro foi alterado |
| **Nível de sensibilidade** | Normal · Crítico · Restrito | Severidade da tabela. Governa as notificações e o controle de acesso |
| **Audita tabela** | Opcional | Sim audita **todos** os campos, dispensando a aba Campos |
| **Audita inclusão / alteração / eliminação** | Opcional, um para cada | Quais operações geram registro de auditoria |

**Aba Campos** — `thl-audit-tabela-campo`, quando a auditoria não é da tabela inteira

| Campo | Preenchimento | O que faz |
|---|---|---|
| **Campo** | Chave | Nome do campo a auditar |
| **Nível de sensibilidade** | Normal · Crítico · Restrito | Severidade do campo, que pode ser maior que a da tabela |
| **Situação** | Ativo ou Inativo | Suspende a auditoria do campo sem apagar a configuração |

**Aba Acessos** — `thl-audit-tabela-acesso`

| Campo | Preenchimento | O que faz |
|---|---|---|
| **Usuário** | Chave | Usuário do Datasul |
| **Nível de acesso** | Normal · Crítico · Restrito | Até que nível de sensibilidade este usuário enxerga no monitor |
| **Situação** | Ativo ou Inativo | Suspende o acesso sem apagar o cadastro |

**Aba Notificações** — `thl-audit-tabela-notificacao`

| Campo | Preenchimento | O que faz |
|---|---|---|
| **Nível de sensibilidade** | Chave · Normal · Crítico · Restrito | A partir de qual severidade notificar |
| **Grupo de e-mail** | Obrigatório | Grupo que recebe o aviso |
| **Situação** | Ativo ou Inativo | Suspende a notificação |

**Aba Expurgo** — `thl-audit-tabela-purge`

| Campo | Preenchimento | O que faz |
|---|---|---|
| **Retenção (dias)** | Opcional, número | Por quantos dias guardar os registros de auditoria desta tabela. **Zero significa sem expurgo** — os registros ficam indefinidamente |

> **Exclusão em cascata:** eliminar a tabela auditada elimina junto os campos, acessos, notificações e a configuração de expurgo dela.

---

# Parte 2 — Consulta

As telas de consulta **não gravam nada**: leem as tabelas de movimento e mostram o que a integração fez. Todas partem do mesmo seletor de período — 1h · 24h · 7 dias · 21 dias · Personalizado com data e hora.

O menu lateral agrupa cada assunto com a sua métrica:

```text
Métricas
────────────────────
Mensageria
Métrica Mensageria
────────────────────
E-mail
Métrica E-mail
────────────────────
Auditoria
Métrica Auditoria
```

---

## Métricas

| | |
|---|---|
| **Tela** | `#/` — primeira tela do menu Consulta |
| **Programa Datasul equivalente** | não há; é exclusiva da web |
| **Rotas da API** | `mensageria/metricas`, `email/metricas`, `auditoria/metricas` |
| **Tabelas lidas** | `thl-mensagem`, `thl-email`, `thl-audit-registro` |

**Para que serve.** Responde "está tudo bem agora?" em um olhar. Três cartões, um por assunto, com o total do período, a quebra por situação e um atalho para a tela de métricas daquele assunto. Não detalha nada — é ponto de partida.

| Bloco | O que mostra |
|---|---|
| **Mensageria** | Total de mensagens, quantas em Sucesso, Erro e Pendente, e a proporção processada sem erro |
| **E-mail** | Total de envios, entregues e com erro, e a proporção entregue |
| **Auditoria** | Total de registros, separados em Criação, Alteração e Deleção. Não tem "erro": auditoria não falha, apenas registra |
| **Alerta de erro** | Aparece quando há mensagens com erro em alguma fase no período, com atalho para o monitor já filtrado |

---

## Métricas por assunto

| | |
|---|---|
| **Telas** | `#/mensageria/metricas`, `#/email/metricas`, `#/auditoria/metricas` — no menu como **Métrica Mensageria**, **Métrica E-mail** e **Métrica Auditoria** |
| **Programa Datasul equivalente** | não há; são exclusivas da web |
| **Rotas da API** | `<assunto>/metricas` |
| **Tabelas lidas** | `thl-mensagem`, `thl-email`, `thl-audit-registro` |

**Para que serve.** Responde "onde está concentrado o volume, e onde está o erro". As três têm o mesmo formato: um cartão por unidade, com total, quebra por situação, uma barra e o atalho que abre a listagem **já filtrada** por aquela unidade e período.

| Tela | A unidade do cartão | A barra mostra |
|---|---|---|
| **Métrica Mensageria** | aplicação + objeto | % processado sem erro |
| **Métrica E-mail** | programa | % entregue |
| **Métrica Auditoria** | banco + tabela | proporção entre criação, alteração e deleção |

Diferenças que valem saber:

- A de **mensageria** esconde o **tráfego interno** (aplicações marcadas como Interna) por padrão, com botão para mostrar.
- A de **auditoria** não tem "erro": auditoria registra, não falha. O chip de **Deleções** isola o evento raro e irreversível.
- A de **e-mail** agrupa por **programa**, não por parâmetro de e-mail — o registro de envio não guarda o parâmetro.
- As três contam o período inteiro, **sem limite de página**: é delas que se tira número confiável.
- A grade mostra os 12 cartões de maior volume, com **Ver todos** para o restante.

---

## Monitor de mensageria

| | |
|---|---|
| **Tela** | `#/mensageria` |
| **Programa Datasul equivalente** | `thl0120` |
| **Rota da API** | `resourcen/mensageria` |
| **Tabelas lidas** | `thl-mensagem`, `thl-mensagem-conteudo`, `thl-mensagem-historico`, `thl-mensagem-item` |

**Para que serve.** É onde se investiga uma mensagem específica: o que entrou, o que o ERP fez e o que foi devolvido. Abre com as **últimas 24 horas**.

| Coluna | O que mostra |
|---|---|
| **Aplicação · Objeto · Operação · Método** | Identificam a origem e o que foi pedido |
| **Dispositivo** | Entrada ou Saída |
| **Requisição · Processamento · Retorno** | A situação de cada uma das três fases, com cor |
| **Dt. Criação · Dt. Integração** | Quando a mensagem chegou e quando foi integrada |
| **Destino · Código do status · Descrição do retorno** | Para onde foi e o que respondeu — a descrição é a primeira pista em caso de erro |
| **Conteúdo Entrada / Saída** | O conteúdo trocado, no detalhe. **Só existe se o objeto estiver configurado para gravar conteúdo** |

---

## Monitor de e-mail

| | |
|---|---|
| **Tela** | `#/email` no menu Consulta |
| **Programa Datasul equivalente** | `thl0110` |
| **Rota da API** | `resourcen/email` |
| **Tabela lida** | `thl-email` |

**Para que serve.** Confirma se um e-mail saiu, para quem e com qual resultado. Abre com as **últimas 24 horas**. Só registra envios de parâmetros com **Gera log** marcado.

| Coluna | O que mostra |
|---|---|
| **Assunto · Remetente · Destino** | O cabeçalho do e-mail como foi enviado |
| **Programa** | Programa Datasul que disparou o envio |
| **Ambiente** | Parâmetro de ambiente usado |
| **Status** | Sucesso ou Erro no envio |
| **Dt. Envio** | Quando saiu |
| **Anexo** | Arquivo anexado, quando houver |
| **Mensagem · Retorno** | Corpo enviado e resposta do servidor de e-mail, no detalhe |

---

## Monitor de auditoria

| | |
|---|---|
| **Tela** | `#/auditoria` no menu Consulta |
| **Programa Datasul equivalente** | `thl0150` |
| **Rota da API** | `resourcen/auditoria` |
| **Tabelas lidas** | `thl-audit-registro`, `thl-audit-registro-detalhe` |

**Para que serve.** Responde "quem alterou este registro, quando e o quê". Abre com as **últimas 24 horas**. O que aparece aqui depende do que foi configurado no cadastro de Auditoria — e do nível de acesso do usuário.

| Coluna | O que mostra |
|---|---|
| **Banco · Tabela** | Qual tabela foi alterada |
| **Operação** | Criação, Alteração ou Deleção |
| **Dt. Criação** | Quando a alteração aconteceu |
| **Usuário** | Quem alterou |
| **Programa** | Por qual programa |
| **Referência** | A chave do registro alterado, montada a partir da chave primária configurada |
| **Campos · Snapshot** | Os campos alterados e o conteúdo antes e depois, no detalhe |

---

## Onde cada coisa é configurada

| Se você quer… | Vá em |
|---|---|
| Incluir um sistema externo | Aplicação |
| Integrar um novo documento | Objeto (e a aba Rota dele) |
| Mudar o endereço de uma API | Conexão, ou Parâmetro, se o endereço vier de variável |
| Mudar o texto de um e-mail | E-mail |
| Mudar quem recebe um e-mail | Grupo de e-mail |
| Passar a auditar uma tabela | Auditoria |
| Saber se uma integração funcionou | Monitor de mensageria |
| Saber por que caiu o volume | Métricas, e depois a tela de métricas do assunto |

---

## Limitações que valem conhecer

- **A busca rápida dos monitores filtra só o que já está carregado.** Para procurar em todo o período, use a Busca avançada, que consulta o servidor.
- **As listas vêm por página.** Conte sempre pelas telas de métricas, que somam o período inteiro sem limite.
- **Mensagens processadas com sucesso são expurgadas após 21 dias** — por isso o seletor de período para aí.
- **O conteúdo das mensagens só existe se o objeto estiver configurado para gravá-lo** (campo Gravação do conteúdo).
- As telas web e os programas `.w` gravam nas mesmas tabelas: o que você cadastrar em uma aparece na outra.
