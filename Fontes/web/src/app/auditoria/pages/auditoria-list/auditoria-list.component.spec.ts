import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { PoModule } from '@po-ui/ng-components';
import { AuditoriaListComponent } from './auditoria-list.component';

describe('AuditoriaListComponent', () => {
  let component: AuditoriaListComponent;
  let fixture: ComponentFixture<AuditoriaListComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AuditoriaListComponent, HttpClientTestingModule, RouterTestingModule, PoModule]
    }).compileComponents();

    fixture = TestBed.createComponent(AuditoriaListComponent);
    component = fixture.componentInstance;
  });

  it('deve criar o componente', () => {
    expect(component).toBeTruthy();
  });

  it('deve ter coluna Banco oculta por padrão', () => {
    const banco = component.columns.find(c => c.property === 'banco');
    expect(banco?.visible).toBe(false);
  });

  it('deve ter coluna Campos com width 200px', () => {
    const campos = component.columns.find(c => c.property === 'campos');
    expect(campos?.width).toBe('200px');
  });

  it('deve ter tooltip de referência definido', () => {
    expect(component.referenciaTooltip).toContain('Chave do registro auditado');
  });

  it('coluna Referência deve ter tooltip configurado', () => {
    const col = component.columns.find(c => c.property === 'referencia');
    expect((col as any)?.tooltip).toContain('Chave do registro auditado');
  });

  it('deve ter 4 botões de filtro de operação', () => {
    expect(component.filterButtons.length).toBe(4);
    expect(component.filterButtons[0].label).toBe('Todos');
    expect(component.filterButtons[1].label).toBe('Criação');
    expect(component.filterButtons[2].label).toBe('Atualização');
    expect(component.filterButtons[3].label).toBe('Deleção');
  });

  it('onFilterChange("criacao") deve filtrar por operação Criacao', () => {
    (component as any).allItems = [
      { operacao: 'Criacao', tabela: 'T', banco: '', usuario: '', campos: '', referencia: '' },
      { operacao: 'Atualizacao', tabela: 'T', banco: '', usuario: '', campos: '', referencia: '' },
      { operacao: 'Delecao', tabela: 'T', banco: '', usuario: '', campos: '', referencia: '' }
    ];
    component.onFilterChange('criacao');
    expect(component.items.length).toBe(1);
    expect(component.items[0].operacao).toBe('Criacao');
  });

  it('filtro "todos" deve exibir todos os registros', () => {
    (component as any).allItems = [
      { operacao: 'Criacao', tabela: 'T', banco: '', usuario: '', campos: '', referencia: '' },
      { operacao: 'Atualizacao', tabela: 'T', banco: '', usuario: '', campos: '', referencia: '' }
    ];
    component.onFilterChange('todos');
    expect(component.items.length).toBe(2);
  });

  it('activeOperacaoFilter deve iniciar com "todos"', () => {
    expect(component.activeOperacaoFilter).toBe('todos');
  });
});
