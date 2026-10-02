# PO-UI para TOTVS Datasul 12 — Documentação Técnica de Referência

## TL;DR
- O PO-UI é a biblioteca Angular open-source (licença MIT) da TOTVS; no Datasul 12 uma tela PO-UI é uma SPA Angular servida pelo Tomcat (Datasul for THF) e cadastrada no menu como "Programa THF", consumindo APIs REST em Progress executadas no PASOE via contexto `/dts/datasul-rest/resources/prg` (menu/interno) ou `/api` (externo, Basic Authentication).
- As técnicas oficiais de baixo código — Customização (12.1.29) e Personalização (12.1.31), consolidadas no "novo conceito" a partir de 12.1.2411 — usam componentes dinâmicos (po-page-dynamic-table, po-dynamic-form, po-dynamic-view) alimentados por endpoints `/metadata`, com intervenção no back-end via UPC cadastrada no MEN012AA.
- O ecossistema ModernizaDatasul (dts-backoffice-util, dts-backoffice-kendo-grid) fornece serviços prontos (MenuDatasulService, ReportService, TotvsScheduleExecutionComponent, ProfileService, TranslateService) essenciais para integrar telas PO-UI com menu, segurança, RPW e relatórios do Datasul.

## Key Findings

1. **Arquitetura**: front Angular/PO-UI (Tomcat/webapps) + back Progress (PASOE), comunicação REST JSON, CORS resolvido pelo TotvsCorsValve/DatasulValve no server.xml do Tomcat. O contexto `/prg` é interno (via menu, sessão SSO/josso); `/api` é externo (Basic Authentication, guia de APIs TOTVS).
2. **Pacotes**: `@po-ui/ng-components` é o núcleo — na versão **21.3.0**, publicada por volta de 06/09/2026 ("Latest version: 21.3.0, last published: 4 days ago", per npm registry) — acompanhado de `@po-ui/ng-templates`, `@po-ui/ng-code-editor`, `@po-ui/ng-sync`, `@po-ui/ng-storage`, `@po-ui/ng-schematics`. Pré-requisito **Node.js 20.11.x ou acima** (verbatim do README oficial po-ui/po-angular). Compatibilidade homologada por versão de Angular (tabela na wiki do po-angular).
3. **API REST Datasul**: padrão de includes `utp/ut-api.i` + `utp/ut-api-action.i` + `utp/ut-api-notfound.i`; retorno JSON no padrão TOTVS com `items`/`hasNext`; classe `JsonAPIResponseBuilder`/`JsonAPIResponse` para montar a resposta.
4. **Customização vs Personalização**: Customização = intervenção via API/UPC no back-end Progress (dev externo/interno); Personalização = cadastro low-code de campos (tela html.personalization-metadata) sem programar.
5. **Deploy**: `ng build --base-href /PROJETO/`, copiar dist para webapps do Tomcat, cadastrar no BAS_PROG_DTSUL/MEN012AA (Nome Externo = pasta, Template = "Programa THF", Interface = WEB), rodar efetivação de segurança.
6. **ModernizaDatasul**: dts-backoffice-util na versão **19.3.0** ("Latest version: 19.3.0, last published: a month ago", per npm) reúne MenuDatasulService, ReportService, FileUtil, ProfileService, TranslateService, DisclaimerUtil, TotvsScheduleExecutionComponent/Service; dts-backoffice-kendo-grid na versão **19.0.1** ("Latest version: 19.0.1, last published: 2 months ago", per npm) para grids de alto volume.

## Details

### 1. Arquitetura Geral

**Arquitetura de referência.** Uma aplicação PO-UI no Datasul 12 é uma Single Page Application Angular. O front-end (HTML/CSS/JS compilados) é hospedado como aplicação estática dentro do servidor **Apache Tomcat** do "Datasul for THF" (na pasta `webapps`). O back-end é regra de negócio em **Progress OpenEdge ABL (Progress 12)**, exposta como **API REST** e executada no **PASOE (Progress Application Server for OpenEdge)**. A comunicação entre as camadas é feita por HTTP/JSON.

**Papel do Tomcat vs PASOE** (fonte oficial — Central de Atendimento TOTVS): o Tomcat do Datasul for THF armazena suas configurações em banco e usa um **AppServer Progress configurado diretamente na instância do Tomcat** (arquivo `conf/context.xml`) para comunicação HTML↔banco. Em resumo:
- **Tomcat** = servidor de aplicação web/HTTP; serve o SPA Angular, faz o roteamento dos contextos (`/dts`, `/api`, `/totvs-login`), aplica filtros de SSO e CORS (Valve).
- **PASOE** = onde os programas Progress (`.p`/`.r`), incluindo APIs REST e UPCs, efetivamente executam. Na release 12 substituiu o AppServer clássico do Progress 11 (e o JBoss da arquitetura antiga).

**Contextos `/prg` vs `/api`** (fonte oficial: TDN "Desenvolvimento de APIs para o produto Datasul"):
- Existem 2 contextos que se aplicam tanto à arquitetura antiga (JBoss) quanto ao DTS4THF (Tomcat).
- `/dts/datasul-rest/resources/prg` → **acessos internos** (via menu). URL final ex.: `/dts/datasul-rest/resources/prg/sec/v1/users`.
- `/api` → **acessos externos** (por apps, integrações). Criado com **Basic Authentication** para atender o guia de API TOTVS. Ex.: `/api/sec/v1/users`. Citação oficial: *"O contexto /api foi criado com autenticação via 'Basic Authentication', para atender o guia de API TOTVS, sendo possível conexão com qualquer API que anteriormente era 'dts/datasul-rest/resources/prg'."*
- Para publicar a funcionalidade ABL, cria-se o `.p` no caminho `<módulo>/api/<versão API>/<recurso>.p` — exemplo oficial `sec/api/v1/users.p`.

**Autenticação e sessão.** No acesso interno (`/prg`), a sessão do usuário é resolvida via SSO (na arquitetura JBoss era o josso; no Tomcat via filtros `SSOFilter`/`DtsFilter`). No acesso externo (`/api`) usa-se Basic Authentication (`Authorization: Basic <base64(usuario:senha)>`), como se vê nos exemplos de service Angular da comunidade (TempTable). O interceptor da lib `totvs/gps-components` (totvs-gps-services) mostra as URLs base padrão (`URL_TTALK = '/dts/datasul-rest/resources/prg/'`, `URL_DATASUL = '/dts'`).

**CORS.** Resolvido por uma **Valve** no `server.xml` do Tomcat (fonte oficial TDN):
```xml
<Valve className="com.totvs.valve.TotvsCorsValve"
  allowHeaders="Content-Type,Accept,Accept-Language,Content-Language,Authorization,tenantId,userId,companyId,authorization,returnformatversion,x-totvs-app"
  contextsToValidate="/totvs-login,/totvs-rest,/dts,/api,/webexecbo,/html-hcm,/totvs-login-oauth2"
  allowOrigin="http://localhost ionic://localhost capacitor://localhost"
  allowMethods="GET, POST, DELETE, PUT, PATCH, HEAD, OPTIONS"
  allowCredential="true" />
```
Requer o JAR `totvs-valve-1.0.jar` (ou `datasul-framework-valve.jar` com `com.datasul.framework.valve.DatasulValve` no JBoss antigo) na pasta `lib` da instância. A tag Valve deve ser o último elemento filho de `<Host>`. Em produção o CORS normalmente não é necessário porque front e back são servidos pela mesma origem (mesmo Tomcat); o CORS é sobretudo para desenvolvimento local (`ng serve` em localhost:4200) e apps móveis (ionic/capacitor).

### 2. Componentes e Pacotes NPM

**Pacotes @po-ui/* (verificado no NPM/GitHub):**
- **`@po-ui/ng-components`** — núcleo: todos os componentes de UI (po-table, po-field, po-page, po-dynamic-*, PoNotificationService, PoDialogService, PoI18nService etc.). Versão **21.3.0** (last published ~06/09/2026).
- **`@po-ui/ng-templates`** — templates de alto nível: po-page-login, po-modal-password-recovery, po-page-blocked-user, **po-page-dynamic-table, po-page-dynamic-edit, po-page-dynamic-detail, po-page-dynamic-search**, po-page-job-scheduler, po-page-slide.
- **`@po-ui/ng-code-editor`** — editor de código-fonte baseado no Monaco (v21.7.0). Requer asset do Monaco no angular.json (`input: node_modules/monaco-editor/min`, `output: /assets/monaco/`).
- **`@po-ui/ng-sync`** — sincronização de dados offline (mobile/Ionic).
- **`@po-ui/ng-storage`** — armazenamento local.
- **`@po-ui/ng-schematics`** — schematics compartilhados (ng-add, ng-generate, ng-update).
- Tema: `@totvs/po-theme` (tema TOTVS) e `@po-ui/style` (tema padrão PO).

**Compatibilidade Angular.** Pré-requisito **Node.js 20.11.x ou acima** (verbatim do README oficial po-ui/po-angular). As versões PO são homologadas por versão de Angular (a "matriz de compatibilidade" fica na wiki do po-angular: *"As versões das bibliotecas do PO são homologadas com o Angular conforme a tabela abaixo, podendo funcionar com alguma versão mais antiga ou nova do Angular mas não há suporte e garantia deste funcionamento."*). O major do PO acompanha o major do Angular (ex.: PO v15 ↔ Angular v15; PO v19 ↔ Angular v19; releases recentes já em Angular 21 — `~21.2.17`). **Pegadinha:** com npm 7+ pode ocorrer erro de peer dependencies — usar `npm install --legacy-peer-deps`. Issues #856, #1226 e #2408 no GitHub documentam falhas de instalação por incompatibilidade de Node/Angular (na #2408 a tela abre em branco no Angular 19).

**Componentes dinâmicos (metadata-driven).** Os `po-page-dynamic-*` montam a tela a partir de uma lista de `fields`, que pode vir hardcoded no TS ou de um endpoint de metadados. Contrato JSON básico:
```json
{
  "version": 1,
  "title": "Person Table",
  "fields": [
    { "property": "id", "key": true, "disabled": true },
    { "property": "name", "label": "Nome", "type": "string", "visible": true }
  ],
  "keepFilters": true
}
```

### 3. API REST — Padrão Datasul

**Estrutura do programa ABL.** O padrão oficial de includes (skeleton do `.p`, fonte: TDN "Documentação APIs com Swagger"):
```progress
{utp/ut-api.i}
{utp/ut-api-action.i pi-get    GET    /~*             }
{utp/ut-api-action.i pi-post   POST   /~* oi=1}
{utp/ut-api-action.i pi-put    PUT    /~*             }
{utp/ut-api-action.i pi-delete DELETE /~*             }
{utp/ut-api-notfound.i}
```
- `utp/ut-api.i` — include master (bootstrap da API, parsing de request/response). Colocada primeiro. Também identifica se a API tem **UPC** cadastrada (usada na customização).
- `utp/ut-api-action.i <procedure> <MÉTODO-HTTP> <rota> [params]` — mapeia verbo+rota para uma internal procedure (`pi-get`, `pi-post`, `pi-put`, `pi-delete`, ações customizadas). `/~*` = catch-all; params extras como `oi=1` ou `by=email,address=~*`.
- `utp/ut-api-notfound.i` — fallback padrão "não encontrado", colocado por último.
- Template mais nova (DFWKDATASUL-8779, "Oficialização nova Template de API-REST", release 12.1.2503) inclui `utp/ut-api-pi-vld-field.i` (controle de eventos ValidateField). *Observação: a sintaxe verbatim das anotações `@openapi.definitions`/`@program.action` do template novo não pôde ser confirmada em fonte oficial acessível — verificar diretamente no TDN (pageId=899189459) ou nos repositórios GitHub `totvs/fwk-tools-jille` / `totvs/fwk-jille`.*

**Documentação Swagger.** APIs podem ser documentadas via YAML que referencia o `.p` (chave `program: pedido.p`, `basePath`), importável em editor.swagger.io. Arquivos `apipublic<módulo>.json` (ex.: `apipublicfin.json`, `apipublicpdp.json`) ficam nas pastas `EMS2/<módulo>/API/V..` no servidor.

**Formato de retorno (padrão TOTVS API):**
- Lista: objeto com `hasNext` (booleano, indica se há mais páginas) e `items` (array de registros). Ex.: `{ "hasNext": true, "items": [ {...}, {...} ] }`. Citação oficial: *"O HasNext indica se há mais algum recurso na base fora da paginação e o Items, a resposta da requisição."*
- Paginação: parâmetros `page` (default 1) e `pageSize` (default 10/20); semântica de multiplicador (`page=2&pageSize=20` → registros 21–40). Nunca retorna coleção completa sem paginação.
- Mensagens de erro padronizadas: `{ "code": "...", "message": "...", "type": "error|warning", "detailedMessage": "...", "details": [ ... ] }`.
- Classe `JsonAPIResponseBuilder`/`JsonAPIResponse` (TDN): monta o JSON com `status`, `payload`, `_messages`, `total`, `items`, `hasNext`. Ex.: `JsonAPIResponseBuilder:asWarning(...)`, `JsonAPIResponseBuilder:empty(500)`. Erro retorna `{ "status":500, "payload":{ "code","message","type","detailedMessage","details":[...] } }`.
- Campos `_expandables`: campos suprimidos por performance, exibidos via parâmetro `expand=campo1,campo2`.

**Endpoints de metadata** (para componentes dinâmicos). Se o `serviceMetadataApi` não for especificado nas rotas, o componente faz `GET {endpoint}/metadata?type=list&version={version}` (type = list/detail/edit conforme o componente). A API de customização deve conter **no mínimo dois endpoints**: um de metadados (definição dos campos) e um de dados/valores.

**Registro no MEN012AA.** A API-REST é cadastrada no cadastro de programas (MEN012AA), aba Opções com Template = "API REST", e configuração de Grupo de Segurança. O nome externo do endpoint **não deve ter extensão**.

### 4. Customização e Personalização

**Diferença conceitual:**
- **Customização** (a partir de **12.1.29**): intervenção no resultado da tela via **API-REST + UPC** no back-end Progress. Permite alterar dinamicamente o metadado/valores em tempo de renderização. Voltada a desenvolvedores (internos ou externos que criam customizações nas telas HTML padrão).
- **Personalização** (a partir de **12.1.31**): técnica **low-code** — o cliente apenas **cadastra campos** na tela "Campos personalizados" (`html.personalization-metadata`), sem programar. O back-end usa o endpoint Progress `/api/btb/v1/personalizationView/metadata/{código_do_programa}` (ex.: `/api/btb/v1/personalizationView/metadata/pedido-execucao-monitor`).

**Técnica de Customização (12.1.29).** A tela HTML em PO-UI precisa que o back-end retorne metadado + valores via API-REST (mínimo 2 endpoints). A API é cadastrada no MEN012AA com a UPC. A include `utp/ut-api.i` detecta se há UPC cadastrada. Os componentes PO-UI usados são **po-dynamic-form, po-dynamic-view** e, quando necessário, **po-page-dynamic-table**. Temp-table de personalização (exemplo TDN):
```progress
DEFINE TEMP-TABLE ttPersonalization NO-UNDO
  FIELD codProgDtsul AS CHARACTER
  FIELD codField     AS CHARACTER
  FIELD codType      AS CHARACTER
  FIELD codLabel     AS CHARACTER
  FIELD codValid     AS CHARACTER
  FIELD logReadOnly  AS LOGICAL INITIAL FALSE
  FIELD logEnable    AS LOGICAL INITIAL TRUE
  INDEX codigo IS PRIMARY codProgDtsul codField.
```

**UPC (User Program Call) em APIs HTML.** Cadastra-se a UPC no MEN012AA ao registrar a API. Pegadinhas oficiais:
- O nome externo da API/ENDPOINT **não deve possuir extensão**.
- Em **PASOE Linux**, no campo "Programa UPC" usar **"/"** (barra) entre diretórios, não "\" (contrabarra), ou o programa não é encontrado (erro na execução).
- Caminho relativo (ex.: `upc/nome_upc.p`) exige ajustar o **propath do PASOE** para conter o diretório raiz, pois a UPC executa no PASOE.

**Fluxo completo:** PO-UI (componente dinâmico) → GET metadata + GET dados na API REST → a API, via `ut-api.i`, verifica UPC cadastrada → UPC intervém no metadado/valores → retorno customizado renderizado dinamicamente.

**Novidades 12.1.2411 ("novo conceito de customização em telas PO-UI", ou patch 12.1.2407.1):** programa deve estar no MEN012AA com flags "Visualiza Menu" e "Permite Personalização"; back-end preparado com técnica de EPC/UPC REST. Visões de dados no Smart View: `vdProgramasDatasulUPC` (programas customizados) e "De-Para Programa HTML x Progress". Para telas de inclusão de campos específicos na parte inferior, os fontes específicos ficam em `<módulo>/custom/<nome_da_tela>` (ex.: `hgp/custom/...`), com diretório no padrão `<módulo>.<nome técnico cadastrado no menu>` (ex.: `hfp.benefMultiplierFactor`). Consultar F1/ajuda da tela para saber se ela está preparada para personalização/customização.

### 5. Deploy e Configuração

**Passo a passo (verificado em TempTable + DevForum + Central TOTVS):**
1. Build Angular com base-href = nome do programa: `ng build --prod --base-href /PROJETO/` (ex.: `/CSTCIDADES/`). O base-href correto é crítico para o roteamento funcionar sob o contexto do Tomcat.
2. Copiar a pasta gerada (dist) para `webapps` do Tomcat (ex.: `apache-tomcat-9.0.31/webapps`).
3. Cadastrar no Datasul via **BAS_PROG_DTSUL / MEN012AA**:
   - Aba Detalhes: **Nome Externo** = nome da pasta do projeto.
   - Aba Opções: **Template = "Programa THF"** (não "Programa HTML"!), **Interface = WEB**.
   - Botão Grupos de Segurança: conceder acesso.
4. Cadastrar procedimento em MEN011AA (BAS_PROCEDIMENTO) e relacionar o programa (Programa Base), com "Visualiza Menu".
5. Executar a **rotina de efetivação de segurança** e refazer login — sem isso o programa cadastrado não aparece no menu (problema comum documentado na Central TOTVS).

**Pegadinha importante:** selecionar "Programa HTML" em vez de "Programa THF" é erro comum (DevForum #2322) — causa falha ao abrir via menu. Erros `HTTP 500 StringIndexOutOfBoundsException` no `DtsFilter.doFilter`/`SSOFilter` aparecem quando o cadastro/base-href estão inconsistentes.

**proxy.conf.js (dev local).** Para desenvolvimento com `ng serve` apontando ao PASOE, configura-se um proxy com `target` (servidor Datasul) e header `Authorization` (Basic). O projeto `dts-backoffice-util-test` usa exatamente esse padrão em `thf2/proxy.conf.js` para entidades não mockadas (ex.: servidores RPW do agendamento).

**Windows vs Linux.** A principal diferença prática é o separador de caminho na UPC ("\" no Windows, "/" no Linux) e o propath do PASOE. Serviço do Tomcat criado/registrado via `bin/service.bat` no Windows.

### 6. Bibliotecas Complementares (ModernizaDatasul)

**`dts-backoffice-util`** (versão **19.3.0** atual; versões acompanham PO-UI/Angular — ex.: v15.4.0 ↔ PO/Angular 15). "Biblioteca que engloba diversos componentes e serviços utilizados no desenvolvimento HTML/Angular com PO-UI." Serviços/utils confirmados:
- **MenuDatasulService** — integração com o menu Datasul:
  - `callProgress(program)` — executa tela/programa Progress (ex.: `{ prg: 'bas_lote_liquidac_acr', params: [{type:'character', value:'ABC'}, {type:'integer', value:'345'}] }`).
  - `openTHF('dts/mab/activities', '', true)` — abre telas THF1 cadastradas no menu.
  - `openPath('html.creditCardOperator', '1509;10;1', true)` — abre tela PO-UI em nova aba.
  - `sendNotification(notification)` — dispara notificação.
  - `programSecurity('html.cashControl')` — verifica segurança/acesso do usuário a um ou mais programas (retorna Observable<Array<Object>>).
- **ReportService** — chama o `datasul-report` e faz download do arquivo (interfaces `IReportServiceParams`, `ReportFormats`).
- **TotvsScheduleExecutionComponent / TotvsScheduleExecutionService** — agendamento/execução RPW (detalhado na seção 10).
- **FileUtil** — `downloadFile`, `b64toBlob`, `fileToB64`, `downloadData` (gera/baixa CSV de uma listagem, ex.: exportar grid).
- **TranslateService** — controle do idioma corrente conforme o Cadastro de Usuários do Datasul.
- **DisclaimerUtil** — helpers para PoDisclaimer (`makeDisclaimerFromMultiSelect`, `makeDisclaimerFromNumber`, `makeDisclaimerFromDatepickerRange`, `atzDatepickerRangeFromDisclamer`).
- **ProfileService** — salva/recupera preferências do usuário (`setProfile`/`getProfile`; interface `IProfile` com pageId, userCode, dataCode, dataValue).
- **UserLoginService** — `getUserLogin()` retorna o login do usuário (framework atual e novo).
- **BreadcrumbControlService** — `delBreadcrumb` e controle de breadcrumb.
- **dtsDateFormat** (pipe) — formata datas, inclusive anteriores a 1901 (que o pipe `date` do Angular não trata).
- **GenericFunctionsUtils** — utilitários genéricos.

**`dts-backoffice-kendo-grid`** (versão **19.0.1**). "Componente que encapsula o Kendo Grid, facilitando o desenvolvimento (similar ao PO-UI) e agregando novas funcionalidades." **Quando usar em vez do po-table:** grids com alto volume de dados e necessidade de recursos avançados (gerenciador de colunas com persistência via `d-show-column-manager`/`d-save-column-manager`, agrupamento, edição inline complexa) que o po-table não cobre. A persistência de configuração pode usar localStorage ou o ProfileService do dts-backoffice-util. Requer CSS do Kendo no angular.json (`node_modules/@progress/kendo-theme-default/dist/all.css` + `node_modules/dts-backoffice-util/lib/css/kendo.min.css`).

**`totvs-log-web-foundation`** — *não foi possível confirmar detalhes/funcionalidades em fonte acessível nesta pesquisa; recomenda-se validar no NPM/GitHub da TOTVS antes de adotar.*

### 7. Telas Dinâmicas (Metadata-Driven)

**Contrato de campo (interface `PoDynamicField` e derivadas: `PoDynamicFormField`, `PoDynamicViewField`, `PoTableColumn`/`PoPageDynamicTableField`).** Propriedades confirmadas em fonte oficial (po-ui.io / po-angular):

| Propriedade | Significado |
|---|---|
| `property` | chave do campo, ligada ao objeto de dados (obrigatória) |
| `label` | texto de exibição (default: property capitalizada) |
| `type` | tipo: `string`, `number`, `date`, `time`, `dateTime`, `currency`, `boolean`, `label`, `subtitle`, `link`, `columnTemplate` |
| `key` | marca o campo como identificador do registro |
| `visible` | controla exibição da coluna (se false, ainda acessível via gerenciador de colunas) |
| `required` | obrigatório (form) |
| `disabled` | desabilitado/não editável |
| `gridColumns` | nº de colunas do grid que o campo ocupa (1–12) |
| `gridSmColumns` | colunas em telas pequenas |
| `options` | lista estática de valores |
| `optionsService` | serviço/URL de opções → renderiza `po-combo` |
| `searchService` | serviço/URL de lookup → renderiza `po-lookup` |
| `fieldLabel` / `fieldValue` | qual propriedade da opção é label / valor |
| `format` | formato (date/time: padrões do DatePipe) |
| `mask` | máscara de input (time default `99:99`) |
| `minLength` / `maxLength` | validação de comprimento |
| `filter` | habilita o campo como filtro/busca |
| `sortable` | controla se a coluna é ordenável |
| `width` | largura da coluna |
| `validate` | serviço/função de validação do campo |
| `errorMessage` | mensagem de erro de validação |
| `duplicate` | campo copiado ao duplicar registro |

Extras confirmados: `container`/`divider` (agrupam campos em seção), `range` (input de intervalo, ex.: data), `help`/`additionalHelpTooltip`, `decimalsLength`/`thousandMaxlength` (currency/number), `icon`, `rows` (≥3 → textarea), `labels` (array `{value,label,color}` para type `label`), `tag`/`color` (só PoDynamicViewField). **Pegadinha (Issue #1038):** a propriedade `labels` chegou a não existir na interface TypeScript `PoPageDynamicTableFilters`, gerando erro de compilação.

**Componentes:** `po-page-dynamic-table` (lista), `po-page-dynamic-edit` (form de edição/criação), `po-page-dynamic-detail` (visualização), `po-page-dynamic-search` (busca avançada), `po-dynamic-form` (form standalone), `po-dynamic-view` (view standalone). Rotas configuram `serviceApi` (dados), `serviceMetadataApi` (metadados via GET) e `serviceLoadApi` (customização de metadados via POST). Exemplo:
```typescript
const routes: Routes = [{
  path: 'people',
  component: PoPageDynamicTableComponent,
  data: {
    serviceApi: 'http://localhost:3000/v1/people',
    serviceMetadataApi: 'http://localhost:3000/v1/metadata',
    serviceLoadApi: 'http://localhost:3000/load-metadata'
  }
}];
```

**Lookup/combo/multiselect via metadata:** `searchService` → po-lookup; `optionsService` → po-combo; `options` + type apropriado → combo/multiselect/radio. **Validações customizadas:** propriedade `validate` (endpoint que valida on-blur/on-change) e `p-validate` no form. **Ações customizadas:** interfaces `PoPageDynamicTableActions` (new, edit, remove, detail, duplicate, e ações customizadas com URL ou função) e ações de linha/em lote (bulk/row actions).

### 8. Internacionalização (i18n)

- **PO-UI:** serviço `PoI18nService` + módulo `PoI18nModule`, "possibilita utilizar múltiplos idiomas e contextos na aplicação". Literais podem vir de arquivo estático (`getLiteralsDefault`) ou de serviço HTTP. A partir da v19 houve ajustes para evitar conflitos entre literais.
- **TranslateService (dts-backoffice-util):** resolve o idioma corrente conforme o parametrizado no **Cadastro de Usuários do Datasul**; se não informado, usa o idioma do browser.
- No back-end Progress, literais traduzíveis devem estar cadastradas no Datasul (o mecanismo de tradução de recursos do Smart View, por exemplo, "só traduz literais devidamente cadastradas no Datasul").

### 9. Segurança e Permissões

- **Integração com segurança do menu:** o programa PO-UI é cadastrado no MEN012AA com Grupos de Segurança; a efetivação de segurança é obrigatória.
- **`programSecurity` (MenuDatasulService):** verifica se o usuário corrente tem acesso a um ou mais programas — usado para habilitar/desabilitar ações de CRUD (criar/editar/excluir) na tela conforme o perfil. Retorna Observable com array de resultados.
- **Propagação de sessão/token:** no acesso interno via menu, o Tomcat aplica os filtros SSO e a sessão é propagada às APIs no contexto `/dts`; no acesso externo usa-se Basic Authentication no header `Authorization`.

### 10. Integração com RPW (Relatórios e Processos)

**TotvsScheduleExecutionComponent (dts-backoffice-util):** componente para agendamento/execução RPW a partir de tela PO-UI. Detalhes confirmados no CHANGELOG:
- Busca o Servidor RPW no endpoint oficial `/dts/datasul-rest/resources/prg/btb/v1/servidoresExecucao`.
- Parâmetro `disabledParams` — habilita/desabilita campos do agendamento (Data Execução, Servidor, Repetir ocorrência).
- Método `setScheduleParameters` — envia informações do agendamento para exibir na tela (ex.: última configuração do usuário); interface `IScheduleParameters`.
- Método `getScheduleParameters` — devolve os parâmetros atuais informados pelo usuário.
- Evento/parâmetro `endExecution` — dispara método ao final, enviando as informações do agendamento (para salvar o que o usuário digitou).
- **TotvsScheduleExecutionService** — cria agendamentos que executam "agora" no RPW via código (sem tela) e permite **monitorar** a execução verificando o status até finalizar.

**Fluxo:** a tela PO-UI coleta parâmetros → o componente/serviço cria o pedido de execução (tabela `ped_exec`) no servidor RPW → parâmetros são passados à temp-table do programa RPW → monitora-se via status (ou pela tela `pedido-execucao-monitor`). Pré-requisitos: servidor RPW ativo, relatório cadastrado no bas_prog_dtsul com nome externo no padrão de diretórios correto (ex.: `<MODULO>/reportview/<NOME_RELATORIO>.treports` para relatórios Smart View).

### 11. Boas Práticas e Padrões

- **Estrutura de projeto:** organização por feature module, com `services/` (acesso a dados/REST), `models/` (interfaces), `components/`. Todo acesso a dados delegado a Services (padrão Angular).
- **Rotas:** padrão list/detail/edit/create, aproveitando o `p-auto-router` dos po-page-dynamic-* (gera automaticamente as rotas de detalhe/edição/duplicação).
- **Erros:** interceptor HTTP + `PoNotificationService` (`.error()`). No back-end, usar `JsonAPIResponse`/`JsonAPIResponseBuilder` para padronizar mensagens.
- **Notificações:** `PoNotificationService` (`success`, `error`, `warning`, `information`).
- **Loading:** `p-loading` nos componentes ou `PoLoadingOverlay`/`p-loading-overlay` para bloquear a tela durante requisições.
- **Confirmação de exclusão:** `PoDialogService.confirm({...})` antes de chamar o DELETE.

### 12. Migração e Evolução

**Histórico:** THF (TOTVS HTML Framework) → **Portinari** (nome do projeto open-source) → **PO UI**. Confirmado verbatim pelo Portal THF oficial (thf.totvs.com.br): *"Nos dias 25 e 26 de junho de 2019 durante o Universo TOTVS, aconteceu um marco histórico do TOTVS HTML FRAMEWORK, onde passamos a ter uma nova identidade visual para nossa biblioteca e também, um novo nome: PO UI... agora somos uma biblioteca open-source com licença MIT."* Os pacotes THF ficaram **congelados na versão 4.0.x**; novos componentes/manutenções só no PO UI.

**Migração THF → PO UI:** guia oficial em `po-ui.io/guides/migration-thf-to-po-ui`; há `ng update` para `@po-ui/ng-components` e `@po-ui/ng-sync` que trata a maioria dos BREAKING CHANGES e depreciações.

**AnimaliaDS (Animalia Design System):** é o **Design System** da TOTVS (não substitui o PO UI). Fonte oficial (doc.animaliads.io): *"Faz parte desse ecossistema o PO-UI, que é uma biblioteca instalável baseada em Angular. Seu nome homenageia a onça-pintada (Panthera Onca)..."*. O AnimaliaDS provê design tokens, brand e **Web Components** (`@animaliads/web-components`, framework-agnósticos), afetando o PO-UI ao fornecer a base de tokens/tema. Requer `CUSTOM_ELEMENTS_SCHEMA` para uso dos web components em Angular. A TOTVS foi explícita de que "o PODS não seria desenvolvido para substituir o PO UI" — cada um tem função definida.

**Context7 / IA:** **A integração PO-UI ↔ Context7 é oficial** — o README do repositório po-ui/po-angular anuncia: *"Temos uma ótima notícia para a comunidade de desenvolvedores! Nossa biblioteca Angular agora faz parte do Context7, uma plataforma que fornece documentação e trechos de código sempre atualizados para LLMs e editores de código."* O Context7 é um MCP server (Model Context Protocol) da Upstash que injeta documentação atualizada e específica de versão no contexto de LLMs/editores IA (Cursor, Claude Code, VS Code). Usa as tools `resolve-library-id` + `get-library-docs`. Adicionar "use context7" ao prompt busca docs específicas do PO-UI, reduzindo APIs alucinadas/desatualizadas — recomendável dado o ritmo de breaking changes por major.

### 13. Limitações e Problemas Conhecidos

- **Instalação/versões:** conflitos de peer dependencies (npm 7+) exigem `--legacy-peer-deps`; incompatibilidade de Node/Angular gera tela branca ou falha no `ng add` (Issues #856, #1226, #2408 — a #2408 reporta tela em branco no Angular 19).
- **Deploy no menu:** selecionar "Programa THF" (não "HTML"); base-href incorreto quebra rotas; falta de efetivação de segurança faz o programa não aparecer; erros 500 no `DtsFilter`/`SSOFilter` por cadastro inconsistente.
- **CORS:** ausência/ordem errada da Valve no server.xml bloqueia requisições em dev local (a Valve precisa ser o último elemento de `<Host>`).
- **UPC em Linux:** separador de caminho e propath do PASOE (seção 4).
- **Typing gaps:** propriedades de metadata ausentes de interfaces TS (Issue #1038, `labels`); o gerenciador de colunas do po-page-dynamic-table falha ao montar campos quando `searchService` recebe um objeto `PoLookupFilter` em vez de uma URL (Issue #1104).
- **Documentação em evolução:** nem toda tela padrão tem customização/personalização disponível — depende da equipe de negócio ter aplicado a técnica (verificar F1 da tela).

## Recommendations

1. **Padronize a camada de acesso na THL-Lib** encapsulando as URLs base (`/dts/datasul-rest/resources/prg` interno, `/api` externo) e um HTTP interceptor que injete idioma e trate o formato `{items, hasNext}` — espelhe o interceptor da `totvs/gps-components`. Benchmark para mudar de estratégia: se a maioria das integrações passar a ser externa/mobile, priorize o contexto `/api` com Basic Auth.
2. **Adote os componentes dinâmicos + endpoints /metadata** como padrão de CRUD, com back-end no template oficial (`ut-api.i`/`ut-api-action.i`/`ut-api-notfound.i`) e retorno via `JsonAPIResponse`. Isso alinha a THL-Lib às técnicas de Customização (12.1.29) e Personalização (12.1.31) — pré-requisito para clientes personalizarem telas sem código. Se seu ambiente já estiver em ≥12.1.2503, migre para a template nova (com `ut-api-pi-vld-field.i`).
3. **Incorpore o dts-backoffice-util (19.3.0) como dependência da THL-Lib** para MenuDatasulService (navegação/segurança), ReportService (relatórios) e TotvsScheduleExecutionComponent (RPW), evitando reimplementar essas integrações. Fixe a versão ao major de PO-UI/Angular do seu projeto (regra: major da lib = major do Angular).
4. **Automatize o deploy** (script de `ng build --base-href` + cópia para webapps + checklist de cadastro MEN012AA com Template THF/Interface WEB + efetivação de segurança). Trate Windows vs Linux (separador de UPC). Um erro de "Programa HTML" vs "Programa THF" ou base-href é a causa nº 1 de falha ao subir a tela no menu.
5. **Só use dts-backoffice-kendo-grid (19.0.1)** quando o po-table não atender (volume/recursos avançados de grid) — caso contrário mantenha po-table para consistência visual e menor peso de bundle.
6. **Configure o Context7 MCP** (integração oficial do PO-UI) nos assistentes de IA da equipe para reduzir alucinação de API, dado o ritmo de breaking changes por major do Angular/PO.
7. **Valide sempre no F1/ajuda da tela** se ela suporta personalização/customização antes de prometer ao cliente; a cobertura é parcial e evolui por release (visões `vdProgramasDatasulUPC` e "De-Para Programa HTML x Progress" no Smart View ajudam a mapear).

## Caveats
- **Fontes oficiais bloqueadas a bots:** as páginas do TDN (tdn.totvs.com) e do npmjs.com bloquearam a leitura automática integral; o conteúdo foi obtido via snippets de busca e fontes espelho (GitHub, jsDelivr, blogs) e via subagente. Os trechos verbatim citados são confiáveis, mas a leitura integral das páginas TDN deve ser feita manualmente para detalhes finos.
- **Anotações do template novo de API (`@openapi.definitions`, `@program.action`):** não confirmadas verbatim; verificar no TDN (pageId=899189459) ou nos repos `totvs/fwk-tools-jille` / `totvs/fwk-jille`.
- **`totvs-log-web-foundation`:** não foi possível confirmar funcionalidades — tratado como não verificado.
- **Versões numéricas** (PO-UI 21.3.0, dts-backoffice-util 19.3.0, dts-backoffice-kendo-grid 19.0.1, @po-ui/ng-code-editor 21.7.0) refletem o publicado no NPM por volta de setembro/2026 e evoluem rápido; confirme a versão exata compatível com o Angular do seu projeto na wiki do po-angular antes de fixar.
- **Distinção fonte oficial vs comunidade:** contextos, MEN012AA, UPC, CORS Valve, formato de API, técnicas de customização/personalização, releases (12.1.29/12.1.31/12.1.2411/12.1.2503) e o contrato de metadata são de **fonte oficial TOTVS/po-ui.io**. Os passos de deploy detalhados (base-href, dist→webapps) e as pegadinhas de menu vêm de **fontes de comunidade** (TempTable, DevForum #2322, 4Each) corroboradas entre si.