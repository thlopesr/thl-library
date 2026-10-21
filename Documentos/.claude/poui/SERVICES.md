---
tipo: guia
camada: ambos
status: referencia
tags: [po-ui, referencia, web]
updated: 2026-10-13
---

# SEÇÃO 10 — SERVIÇOS E UTILITÁRIOS (SERVICES.md)

## 10.1 Serviços nativos do PO-UI

- **PoNotificationService** — ver 9.1.
- **PoDialogService** — ver 8.2.
- **PoI18nService** — ver Seção 13.
- **PoHttpInterceptorModule / po-http-interceptor** — "tem a finalidade de exibir notificações com mensagens na tela, baseado nas respostas das requisições HTTP". Constantes internas: `X-PO-No-Error` (não mostra notificações de erro `4xx`/`5xx`) e `X-PO-No-Message` (não exibe notificações de erro e/ou sucesso). Requer `BrowserAnimationsModule`/`provideAnimations()`.

**Configuração (standalone):**

```typescript
import { ApplicationConfig, importProvidersFrom } from '@angular/core';
import { provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';
import { provideAnimations } from '@angular/platform-browser/animations';
import { PoHttpInterceptorModule } from '@po-ui/ng-components';

export const appConfig: ApplicationConfig = {
  providers: [
    provideAnimations(),
    provideHttpClient(withInterceptorsFromDi()),
    importProvidersFrom([PoHttpInterceptorModule])
  ]
};
```

**Payload de mensagem TOTVS:** `code`, `message`, `detailedMessage`, `type` (`error`/`warning`/`information` — default `error`), `details` (lista recursiva) e `detailTitle` (título dos detalhes; o CHANGELOG do po-angular registra "interceptor: adiciona a propriedade detailTitle para permitir definir o titulo da mensagem retornada"). Se houver apenas uma mensagem de retorno, o interceptor "exibe a mensagem principal na modal". Loading automático é ativado por `X-PO-Screen-Lock: true` no header da requisição.

📚 https://po-ui.io/documentation/po-http-interceptor

## 10.2 Serviços do dts-backoffice-util (Datasul)

**Módulo Angular:** `DtsBackofficeUtilsModule` (alguns componentes exigem `.forRoot()`). Descrição oficial: "Biblioteca que engloba diversos componentes e serviços utilizados no desenvolvimento HTML/Angular com PO-UI." Versão mais recente: **19.3.0** (NPM). Os nomes das versões acompanham PO-UI/Angular (ex.: linha 15 = PO-UI v15/Angular 15; linha 19 = PO-UI v19/Angular 19).

Serviços da primeira versão (verbatim do CHANGELOG): `breadcrumb-control.service`, `cache-params.service`, `menu-datasul.service`, `profile.service`, `report.service`, `session-info.service`, `date.util`, `disclaimer.util`, `field-validation.util`, `filter-range.util`, `generic-functions.utils`.

### MenuDatasulService — interagir com o Menu do Datasul

```typescript
import { MenuDatasulService } from 'dts-backoffice-util';
constructor(public menuDatasulService: MenuDatasulService) { }

// callProgress — executar programa Progress
program = {
  prg: 'bas_lote_liquidac_acr',
  params: [
    { type: 'character', value: 'ABC' },
    { type: 'integer', value: '345' }
  ]
};
this.menuDatasulService.callProgress(program);

// openTHF — abrir tela THF1 cadastrada no menu do Datasul
this.menuDatasulService.openTHF('dts/mab/activities', '', true);

// openPath — abrir tela (PO-UI) em nova aba do Datasul
this.menuDatasulService.openPath('html.creditCardOperator', '1509;10;1', true);

// sendNotification — notificação do Datasul
notification = {
  type: 'success',
  title: 'Operação executada com Sucesso.',
  detail: 'A Operação 4343 finalizou conforme parametrizado.'
};
this.menuDatasulService.sendNotification(notification);

// programSecurity — verificar segurança do menu para o usuário
this.menuDatasulService.programSecurity('html.cashControl')
  .subscribe((response: Array<Object>) => {
    // Ex.: { programName: "html.cashControl", hasAccess: true }
  });
// Aceita também uma lista de programas.
```

**Navegar entre telas THL pelo menu Datasul:** use `openPath()` (telas PO-UI/HTML), `openTHF()` (telas THF1) e `callProgress()` (programas Progress puros), passando os parâmetros no formato esperado pelo menu.

### ReportService — integração com datasul-report

```typescript
import { ReportService, IReportServiceParams, ReportFormats } from 'dts-backoffice-util';
constructor(public reportService: ReportService) { }

// enum ReportFormats: XLSX="xlsx", PDF="pdf", DOCX="docx", HTML="html"

const params: IReportServiceParams = {
  reportName: 'crm/rel_campaign_export',
  programName: '/report/crm/crm0010',
  properties: [{ name: 'custom.quick_search', value: '186' }], // Array<IProperty> { name, value }
  dialect: 'pt',
  download: true,
  downloadName: '2020-1-10_CRM_CAMPANHAS',
  format: ReportFormats.XLSX
};

this.reportService.generate(params).subscribe(
  () => this.notification.success('Arquivo baixado com sucesso!'),
  () => this.notification.error('Não foi possível baixar o arquivo')
);
```

`IReportServiceParams` (campos observados): `reportName`, `programName`, `properties: Array<IProperty>`, `dialect`, `download`, `downloadName`, `format`.

### TotvsScheduleExecutionComponent / TotvsScheduleExecutionService — integração RPW

Busca do servidor RPW usa o endpoint oficial `/dts/datasul-rest/resources/prg/btb/v1/servidoresExecucao`.

**Propriedades:** `programName`, `externalName`, `programEMS5`, `programStyle`, `programVersion`, `parameters`, `paramSelections`, `paramDigitDef`, `paramDigitData`, `disabledParams` (habilita/desabilita infos do agendamento: data, servidor, repetição etc.). **Métodos:** `setScheduleParameters()` (enviar as informações do agendamento, ex.: última configuração do usuário), `getScheduleParameters()`. **Evento:** `(endExecution)` — dispara com as informações do agendamento; a interface `IScheduleParameters` retorna `listExecutionID` (número da agenda criada no RPW). Consulta de status: `getExecutionByJobScheduleID()` e `getExecutionByExecutionID()`.

```html
<!-- EMS5 -->
<app-totvs-schedule-execution #schParam
  programName="rpt_grp_repres" externalName="rpt_grp_repres"
  programEMS5="true" programStyle="40" programVersion="1.00.00.004"
  [parameters]="parametersRpw" [paramSelections]="paramSelectionsRpw"
  (endExecution)="endExecutionSchedule($event)">
</app-totvs-schedule-execution>

<!-- EMS2 -->
<app-totvs-schedule-execution #schParam
  programName="pdapi701" externalName="pdp/pdapi701.p"
  [parameters]="parametersRpw" [paramDigitDef]="paramDigitDefRpw"
  [paramDigitData]="paramDigitDataRpw"
  (endExecution)="endExecutionSchedule($event)">
</app-totvs-schedule-execution>
```

```typescript
@ViewChild('schParam', { static: true }) schParam: TotvsScheduleExecutionComponent;
scheduleParams: IScheduleParameters;
parametersRpw = new Array<any>();

ngOnInit() {
  this.loadLocalStorage();
  this.schParam.setScheduleParameters(this.scheduleParams);
}
endExecutionSchedule(params: IScheduleParameters) {
  // salvar params digitados; params.listExecutionID = número da agenda
}
```

Parâmetros são passados via temp-table através dos arrays `parameters`/`paramSelections` (EMS5) ou `paramDigitDef`/`paramDigitData` (EMS2).

### TranslateService — controle de idioma

"Realizar o controle do idioma corrente, considerando o que estiver parametrizado no Cadastro de Usuários do Datasul, e caso não esteja informado, será considerado o idioma informado no Browser."

```typescript
import { TranslateService } from 'dts-backoffice-util';
```

*(Nomes/assinaturas exatos dos métodos: a confirmar no README/raw do repo; não assuma métodos do ngx-translate.)*

### ProfileService — preferências do usuário no Datasul

```typescript
import { ProfileService, IProfile } from 'dts-backoffice-util';
constructor(public preferenceService: ProfileService) { }

// IProfile: { dataCode, pageId, dataValue, userCode }
const profile: IProfile = {
  dataCode: 'preference',
  pageId: 'clientes-list',
  dataValue: this.colunasConfiguradas, // ex.: config de colunas da tabela
  userCode: 'super'
};

this.preferenceService.setProfile(profile).subscribe(
  () => this.notification.success('Preferência salva com sucesso!'),
  () => this.notification.error('Não foi possível salvar a preferência')
);
```

`setProfile` aceita um parâmetro adicional opcional (boolean) para exibir tela de loading. `getProfile()` carrega a preferência salva. Uso típico: salvar configuração de colunas/filtros por tela.

### FileUtil — manipulação de arquivos (métodos estáticos)

```typescript
import { FileUtil, DownloadDataParams } from 'dts-backoffice-util';

// downloadFile — conteúdo do backend
FileUtil.downloadFile(response['content'], response['filename']);

// downloadFile — Blob (4º parâmetro base64 = false)
FileUtil.downloadFile(response, 'qrCode.png', '', false);

// downloadData — exportar CSV
const p = new DownloadDataParams();
p.fileName = 'clientes.csv';
p.columnDelimiter = ';';
p.columnList = ['codigo', 'nome']; // respeita a ordem informada
p.literals = this.literals;
FileUtil.downloadData(p, dados);
```

**Métodos:** `downloadFile()` (parâmetro `base64: boolean` indica formato base64 ou Blob), `b64toBlob()` (Base64 → Blob), `fileToB64()` (arquivo → Base64), `downloadData()` (gera e baixa CSV). Interface `IDownloadDataParams`/classe `DownloadDataParams`: `fileName`, `columnDelimiter`, `literals`, `columnList`.

### DisclaimerUtil — sincronização filtros ↔ disclaimers

Padrão de nomes: `make*` cria o disclaimer a partir do valor do filtro; `atz*` (de "atualiza") atualiza o valor do filtro a partir do disclaimer. **Atenção:** os nomes no código-fonte usam a grafia "Disclamer" (sem o "i") em `atzBooleanFromDisclamer` e `atzDatepickerRangeFromDisclamer`.

**Métodos (do CHANGELOG):**
- `makeDisclaimerFromDatepickerRange()` / `atzDatepickerRangeFromDisclamer()` — cria/atualiza o objeto Disclaimer para o `PoDatepickerRange`.
- `atzBooleanFromDisclamer()` — retorna valor verdadeiramente boolean (necessário para o `po-switch` funcionar corretamente).
- `makeDisclaimerFromNumber(..., options)` — 5º parâmetro `options` é uma lista de-para (valor × label); se informado, exibe o label no disclaimer mantendo o valor numérico.
- `makeDisclaimerFromMultiSelect(..., tradValue)` — `tradValue` indica se o value deve ser traduzido (via literals enviados ao serviço).
- `makeDisclaimerFromMultiSelectNumber()` — label String com valor numérico interno.

### GenericFunctionsUtils

`focusInternalInput()` — dá foco a um campo PO-UI dentro de um Modal ou quando o campo não está disponível na abertura da tela (casos em que não é possível usar `@ViewChild`).

### UserLoginService

"Retorna o login do usuário tanto no framework atual quanto no novo framework."

```typescript
import { UserLoginService } from 'dts-backoffice-util';
constructor(public sessionService: UserLoginService) { }

this.sessionService.getUserLogin().subscribe(user => {
  this.notification.success(`O usuário logado é ${user}`);
});
```

### BreadcrumbControlService

"Realiza a criação e controle do breadcrumb das telas." Inclui o método `delBreadcrumb` para excluir um item do breadcrumb. *(Assinatura do método de criação: a confirmar no README.)*

### Pipe dtsDateFormat

"PIPE para formatar datas, ele foi criado pois o PIPE date do angular não consegue formatar datas inferiores a 1901." Requer importar `DtsBackofficeUtilsModule`.

```html
<po-info p-label="Data" [p-value]="date | dtsDateFormat : 'dd/MM/yyyy'"></po-info>
<po-info p-label="Data" [p-value]="date | dtsDateFormat : 'MM/dd/yyyy'"></po-info>
```

📚 https://github.com/ModernizaDatasul/dts-backoffice-util · https://www.npmjs.com/package/dts-backoffice-util

## 10.3 Padrão de Service Angular para CRUD

APIs REST Datasul retornam o padrão `{ items, hasNext }` com paginação `page`/`pageSize` (o tipo `TotvsResponse<T>` do dts-backoffice-util encapsula isso).

```typescript
export interface TotvsResponse<T> { items: T[]; hasNext: boolean; }

@Injectable({ providedIn: 'root' })
export class CadastroService {
  private url = '/dts/datasul-rest/resources/prg/api/v1/clientes';
  constructor(private http: HttpClient) {}

  query(page = 1, pageSize = 20): Observable<TotvsResponse<ICliente>> {
    return this.http.get<TotvsResponse<ICliente>>(
      `${this.url}?page=${page}&pageSize=${pageSize}`
    );
  }
  get(id: string): Observable<ICliente> { return this.http.get<ICliente>(`${this.url}/${id}`); }
  create(item: ICliente): Observable<ICliente> { return this.http.post<ICliente>(this.url, item); }
  update(id: string, item: ICliente): Observable<ICliente> { return this.http.put<ICliente>(`${this.url}/${id}`, item); }
  delete(id: string): Observable<void> { return this.http.delete<void>(`${this.url}/${id}`); }
}
```

Tratamento de erros: deixe o `PoHttpInterceptorModule` exibir o payload TOTVS automaticamente; para casos específicos, use `catchError` e trate localmente (enviando `X-PO-No-Message`/`X-PO-No-Error` quando quiser suprimir a notificação automática).

## 10.4 HttpClient e Interceptors

Configure via `provideHttpClient(withInterceptorsFromDi())` (standalone) ou `HttpClientModule` (NgModule). Em **desenvolvimento**, use um interceptor para injetar Basic Auth; em **produção** o framework Datasul gerencia a sessão. Payload de erro TOTVS: `code`, `message`, `detailedMessage`.

```typescript
@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    const cloned = req.clone({
      setHeaders: { Authorization: 'Basic ' + btoa('usuario:senha') } // apenas DEV
    });
    return next.handle(cloned).pipe(
      catchError((err: HttpErrorResponse) => {
        // err.error: { code, message, detailedMessage }
        return throwError(() => err);
      })
    );
  }
}
```

```typescript
providers: [
  { provide: HTTP_INTERCEPTORS, useClass: AuthInterceptor, multi: true }
]
```

O loading automático e as mensagens de erro globais são melhor delegados ao interceptor nativo do PO (Seção 10.1), evitando duplicar lógica.

---
