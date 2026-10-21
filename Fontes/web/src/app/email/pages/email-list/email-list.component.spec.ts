import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { PoModule } from '@po-ui/ng-components';
import { EmailListComponent } from './email-list.component';

describe('EmailListComponent', () => {
  let component: EmailListComponent;
  let fixture: ComponentFixture<EmailListComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [
        EmailListComponent,
        HttpClientTestingModule,
        RouterTestingModule,
        PoModule
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(EmailListComponent);
    component = fixture.componentInstance;
  });

  it('deve criar o componente', () => {
    expect(component).toBeTruthy();
  });

  it('deve iniciar com filtro de status "todos"', () => {
    expect(component.activeStatusFilter).toBe('todos');
  });

  it('deve ter 3 botões de filtro de status', () => {
    expect(component.filterButtons.length).toBe(3);
    expect(component.filterButtons[0].label).toBe('Todos');
    expect(component.filterButtons[1].label).toBe('Sucesso');
    expect(component.filterButtons[2].label).toBe('Erro');
  });

  it('deve separar data e hora do envio', () => {
    const row = (component as any).mapEmailRow({
      id: '1', assunto: 'Teste', remetente: 'a@b.com', destino: 'c@d.com',
      dtEnvio: '2026-09-17T10:30:00', codParamAmbiente: '', mensagem: '',
      informacao: '', retorno: '', codProgDtsul: '', logEnvio: 'Sucesso', arqAnexo: ''
    });
    expect(row.dataEnvio).toContain('2026-09-17');
    expect(row.horaEnvio).toBe('10:30:00');
  });

  it('deve filtrar apenas erros quando filtro "erro" ativo', () => {
    (component as any).allItems = [
      { id: '1', logEnvio: 'Sucesso', assunto: '', remetente: '', destino: '', dtEnvio: '', codParamAmbiente: '', mensagem: '', informacao: '', retorno: '', codProgDtsul: '', arqAnexo: '' },
      { id: '2', logEnvio: 'Erro', assunto: '', remetente: '', destino: '', dtEnvio: '', codParamAmbiente: '', mensagem: '', informacao: '', retorno: '', codProgDtsul: '', arqAnexo: '' }
    ];
    component.onFilterChange('erro');
    expect(component.items.length).toBe(1);
  });

  it('deve exibir todos quando filtro "todos" ativo', () => {
    (component as any).allItems = [
      { id: '1', logEnvio: 'Sucesso', assunto: '', remetente: '', destino: '', dtEnvio: '', codParamAmbiente: '', mensagem: '', informacao: '', retorno: '', codProgDtsul: '', arqAnexo: '' },
      { id: '2', logEnvio: 'Erro', assunto: '', remetente: '', destino: '', dtEnvio: '', codParamAmbiente: '', mensagem: '', informacao: '', retorno: '', codProgDtsul: '', arqAnexo: '' }
    ];
    component.onFilterChange('todos');
    expect(component.items.length).toBe(2);
  });

  it('deve ter coluna "Ambiente" (não "Param. Ambiente")', () => {
    const col = component.columns.find(c => c.property === 'codParamAmbiente');
    expect(col?.label).toBe('Ambiente');
  });

  it('deve ter coluna horaEnvio oculta por padrão', () => {
    const col = component.columns.find(c => c.property === 'horaEnvio');
    expect(col).toBeTruthy();
    expect(col?.visible).toBe(false);
  });

  it('deve indicar hasNext quando há mais itens que o pageSize', () => {
    const mockItems = Array.from({ length: 25 }, (_, i) => ({
      id: String(i), logEnvio: 'Sucesso', assunto: '', remetente: '', destino: '',
      dtEnvio: '', codParamAmbiente: '', mensagem: '', informacao: '', retorno: '',
      codProgDtsul: '', arqAnexo: ''
    }));
    (component as any).allItems = mockItems;
    (component as any).aplicarFiltrosLocais();
    expect(component.hasNext).toBe(true);
    expect(component.items.length).toBe(20);
  });
});
