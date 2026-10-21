import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { of } from 'rxjs';
import { MetricasComponent } from './metricas.component';
import { MetricasService } from '../../services/metricas.service';
import { MetricasResumo } from '../../models/metricas.model';

const resumo: MetricasResumo = {
  mensagem: { total: 10, sucesso: 7, erro: 2, pendente: 1 },
  email: { total: 4, sucesso: 3, erro: 1 },
  auditoria: { total: 6, criacao: 3, atualizacao: 2, delecao: 1 },
  errosNoPeriodo: 2
};

describe('MetricasComponent', () => {
  let fixture: ComponentFixture<MetricasComponent>;
  let component: MetricasComponent;

  beforeEach(async () => {
    const service = jasmine.createSpyObj('MetricasService', ['getMetricas']);
    service.getMetricas.and.returnValue(of(resumo));

    await TestBed.configureTestingModule({
      imports: [MetricasComponent],
      providers: [provideRouter([]), { provide: MetricasService, useValue: service }]
    }).compileComponents();

    fixture = TestBed.createComponent(MetricasComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('monta um cartão por assunto, na ordem do menu', () => {
    expect(component.cards.map(c => c.id)).toEqual(['mensageria', 'email', 'auditoria']);
  });

  it('o id do cartão é a rota do assunto, para abrir `<assunto>/metricas`', () => {
    expect(component.cards.every(c => !!c.id && !c.id.includes('/'))).toBeTrue();
  });

  it('soma o total dos três assuntos', () => {
    expect(component.totalGeral).toBe(20);
  });
});
