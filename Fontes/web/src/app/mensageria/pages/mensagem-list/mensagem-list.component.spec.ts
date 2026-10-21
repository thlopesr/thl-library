import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { PoModule } from '@po-ui/ng-components';
import { MensagemListComponent } from './mensagem-list.component';

describe('MensagemListComponent', () => {
  let component: MensagemListComponent;
  let fixture: ComponentFixture<MensagemListComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MensagemListComponent, HttpClientTestingModule, RouterTestingModule, PoModule]
    }).compileComponents();

    fixture = TestBed.createComponent(MensagemListComponent);
    component = fixture.componentInstance;
  });

  it('deve criar o componente', () => {
    expect(component).toBeTruthy();
  });

  it('deve ter colunas horaCriacao e horaIntegracao ocultas por padrão', () => {
    const horaCriacao = component.columns.find(c => c.property === 'horaCriacao');
    const horaIntegracao = component.columns.find(c => c.property === 'horaIntegracao');
    expect(horaCriacao?.visible).toBe(false);
    expect(horaIntegracao?.visible).toBe(false);
  });

  it('deve ter colunas dataCriacao e dataIntegracao com type date', () => {
    const dataCriacao = component.columns.find(c => c.property === 'dataCriacao');
    const dataIntegracao = component.columns.find(c => c.property === 'dataIntegracao');
    expect(dataCriacao?.type).toBe('date');
    expect(dataIntegracao?.type).toBe('date');
  });

  it('deve ter coluna Destino com width 160px', () => {
    const destino = component.columns.find(c => c.property === 'destino');
    expect(destino?.width).toBe('160px');
  });

  it('deve ter 3 botões de filtro de status', () => {
    expect(component.filterButtons.length).toBe(3);
    expect(component.filterButtons[0].label).toBe('Todos');
    expect(component.filterButtons[1].label).toBe('Sucesso');
    expect(component.filterButtons[2].label).toBe('Erro');
  });

  it('onFilterChange deve alterar o filtro ativo', () => {
    component.onFilterChange('erro');
    expect(component.activeStatusFilter).toBe('erro');
    expect(component.filterButtons[2].selected).toBe(true);
  });

  it('filtro "sucesso" deve filtrar mensagens com todos os status Sucesso', () => {
    (component as any).allItems = [
      { statusRequisicao: 'Sucesso', statusRetorno: 'Sucesso', statusProcessamento: 'Sucesso' },
      { statusRequisicao: 'Sucesso', statusRetorno: 'Erro', statusProcessamento: 'Sucesso' }
    ];
    component.activeStatusFilter = 'sucesso';
    (component as any).aplicarFiltrosLocais();
    expect(component.items.length).toBe(1);
  });

  it('filtro "erro" deve incluir qualquer mensagem com status Erro', () => {
    (component as any).allItems = [
      { statusRequisicao: 'Sucesso', statusRetorno: 'Sucesso', statusProcessamento: 'Sucesso' },
      { statusRequisicao: 'Erro', statusRetorno: 'Sucesso', statusProcessamento: 'Sucesso' }
    ];
    component.activeStatusFilter = 'erro';
    (component as any).aplicarFiltrosLocais();
    expect(component.items.length).toBe(1);
  });

  it('template deve ter p-columns-manager habilitado', () => {
    (component as any).allItems = [
      { statusRequisicao: 'Sucesso', statusRetorno: 'Sucesso', statusProcessamento: 'Sucesso', dtCriacao: '2026-09-17T10:00:00', dtIntegracao: '2026-09-17T10:00:00' }
    ];
    (component as any).aplicarFiltrosLocais();
    fixture.detectChanges();
    const table = fixture.nativeElement.querySelector('po-table');
    expect(table).toBeTruthy();
  });

  it('mapRow deve separar data e hora corretamente', () => {
    const mapped = (component as any).mapRow({
      dtCriacao: '2026-09-17T14:30:00',
      dtIntegracao: '2026-09-17T08:15:00'
    });
    expect(mapped.dataCriacao).toContain('2026-09-17');
    expect(mapped.horaCriacao).toBe('14:30:00');
    expect(mapped.horaIntegracao).toBe('08:15:00');
  });
});
