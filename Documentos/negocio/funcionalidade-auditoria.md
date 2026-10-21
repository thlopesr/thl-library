# Funcionalidade Auditoria — quem alterou o quê, quando e como

A auditoria registra as **alterações feitas em tabelas do ERP** que você escolher: quem mexeu, quando, por qual programa e quais valores havia antes e depois. A THL guarda os registros, controla **quem pode vê-los** e limpa os mais antigos conforme a retenção definida.

Este guia explica a funcionalidade e os cadastros em linguagem de negócio. O detalhe campo a campo está em [guia-telas-web.md](guia-telas-web.md); a análise técnica, em [logging/auditoria](../.claude/logging/auditoria.md).

> Verificado por leitura do código e das notas do projeto (análise de 02/10/2026). Nada foi executado contra o Datasul para escrever este guia.

## Como funciona

1. Uma tabela do ERP precisa estar **cadastrada na auditoria** e ter, no banco, um gatilho (trigger) de gravação ou eliminação que chama a THL. Os exemplos desse gatilho estão em `Utils/example/exampleAuditTriggerWrite.p` e `exampleAuditTriggerDelete.p`; não há gatilho pronto no repositório. Isso é trabalho da TI.
2. Ao gravar ou eliminar um registro, a THL confere o cadastro: a tabela é auditada? A operação (inclusão, alteração ou eliminação) está habilitada? Numa alteração, um campo monitorado mudou?
3. Se sim, ela grava um **registro de auditoria** com o usuário, a data e a pilha de programas, e o **conteúdo do registro** (snapshot): um na inclusão e na eliminação, e dois na alteração (antes e depois).
4. Tabela não cadastrada, operação desabilitada ou nenhum campo monitorado alterado: nada é gravado.

## Níveis de sensibilidade

Tabelas e campos têm um **nível**: **Normal**, **Crítico** ou **Restrito**. Cada usuário tem um **nível de acesso**. O monitor de auditoria mostra só o que o nível do usuário permite, e campos restritos ficam ocultos para quem não tem acesso.

## Cadastros

Tudo é configurado em **Auditoria**, com duas telas no Datasul (thl0050 e thl0051) e uma na web.

| Cadastro | Programa Datasul | Para que serve |
|---|---|---|
| **Tabela auditada** | thl0050 | Define o banco e a tabela, os campos da chave primária (para saber **qual registro** foi alterado), o nível de sensibilidade e quais operações geram registro: inclusão, alteração e eliminação. O campo **Audita tabela** audita todos os campos |
| **Campos** | thl0051 | Quando a auditoria não é da tabela inteira, lista os campos a acompanhar, cada um com seu nível e situação |
| **Acessos** | thl0051 | Quais usuários podem ver os registros e até que nível de sensibilidade |
| **Notificações** | thl0051 | A partir de qual nível um **grupo de e-mail** deve ser avisado |
| **Expurgo** | thl0051 | Por quantos dias guardar os registros da tabela. **Zero significa sem expurgo**: os registros ficam indefinidamente |

Pontos de atenção:

- **Eliminar uma tabela auditada** elimina também os campos, acessos, notificações e o expurgo dela.
- O banco é identificado pelo **nome lógico na sessão**. Se o nome lógico for diferente entre ambientes, a auditoria deixa de gravar, sem erro.
- Auditoria registra, não falha: por isso as métricas não têm "erro".

## Como configurar a auditoria de uma tabela

1. Cadastre a **Tabela auditada**: banco, tabela, chave primária, nível e quais operações auditar.
2. Escolha auditar a **tabela inteira** ou cadastre os **campos** a acompanhar.
3. Cadastre os **Acessos** dos usuários que devem consultar.
4. Informe a **Retenção** em dias, ou deixe zero para não expurgar.
5. Peça à TI para criar o gatilho da tabela no banco.
6. Faça uma alteração de teste e confirme no monitor de auditoria.

## Acompanhamento

| Para… | Use |
|---|---|
| Ver quem alterou um registro, quando e o que mudou | Consulta de auditoria (thl0150, ou tela web) |
| Ver o volume por tabela e por tipo de operação | Métricas de auditoria (web) |
| Limpar registros antigos pela retenção | Tarefa thl0250 |

O monitor mostra banco, tabela, operação, data, usuário, programa, a **referência** do registro (montada a partir da chave primária), os campos alterados e o conteúdo antes e depois.

## Limitações conhecidas (por leitura do código, a confirmar)

- **Notificação:** o cadastro existe, mas **nenhum código envia o aviso por e-mail** hoje. Cadastrar a notificação ainda não gera e-mail.
- **Expurgo:** em 02/10/2026, a tarefa thl0250 comparava o banco sem o prefixo usado na gravação e tentava gravar um registro lido só para consulta. Pela leitura, ela **podia não apagar nada**. Confirme com a TI antes de contar com a limpeza.
- **Inclusão:** com a inclusão desabilitada e a tabela inteira auditada, um registro novo podia ser gravado como alteração.
- **Chave primária:** sem ela cadastrada corretamente, a referência do registro não consegue identificar qual registro foi alterado.
