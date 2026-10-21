import { ComponentFixture, TestBed } from '@angular/core/testing';
import { CommonModule } from '@angular/common';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { PoModule, PoNotificationService } from '@po-ui/ng-components';
import { MessageDetailModalComponent } from './message-detail-modal.component';
import { Mensagem } from '../../models/mensagem.model';

describe('MessageDetailModalComponent', () => {
  let component: MessageDetailModalComponent;
  let fixture: ComponentFixture<MessageDetailModalComponent>;
  let notificationSpy: jasmine.SpyObj<PoNotificationService>;

  const mockMessage: Mensagem = {
    id: '1',
    codMsg: 'fa8bbfba-27ef-2791-f714-d84418c8b9a1',
    objeto: 'CentroCusto',
    operacao: 'Obtecao',
    aplicacao: 'TOTVS',
    modelo: 'REST',
    metodo: 'GET',
    dispositivo: 'Entrada',
    dtIntegracao: '2026-09-14T15:39:23.513',
    dtCriacao: '2026-09-14T15:39:23.081',
    statusRequisicao: 'Sucesso',
    statusRetorno: 'Sucesso',
    statusProcessamento: 'Sucesso',
    destino: 'centrocusto.totvs.com.br',
    codStatusRetorno: 200,
    descrRetorno: 'Mensagem processada com sucesso.',
    conteudo: { temRequisicao: true, temResposta: true }
  };

  beforeEach(async () => {
    notificationSpy = jasmine.createSpyObj('PoNotificationService', ['success', 'error']);

    await TestBed.configureTestingModule({
      imports: [CommonModule, PoModule, HttpClientTestingModule, MessageDetailModalComponent],
      providers: [
        { provide: PoNotificationService, useValue: notificationSpy }
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(MessageDetailModalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('deve criar o componente', () => {
    expect(component).toBeTruthy();
  });

  it('deve retornar titulo padrao sem message', () => {
    component.message = null;
    expect(component.modalTitle).toBe('Detalhes Mensagem');
  });

  it('deve retornar titulo com codMsg quando message definido', () => {
    component.message = mockMessage;
    expect(component.modalTitle).toContain('fa8bbfba');
  });

  it('deve emitir closed ao fechar', () => {
    spyOn(component.closed, 'emit');
    component.onClose();
    expect(component.closed.emit).toHaveBeenCalled();
  });

  it('deve emitir reprocessar com id da message', () => {
    spyOn(component.reprocessar, 'emit');
    component.message = mockMessage;
    component.onReprocessar();
    expect(component.reprocessar.emit).toHaveBeenCalledWith(mockMessage.id);
    expect(component.isResending).toBeTrue();
  });

  it('nao deve exibir secondaryAction quando nao ha erro', () => {
    component.message = mockMessage;
    expect(component.secondaryAction).toBeUndefined();
  });

  it('deve exibir secondaryAction quando ha erro', () => {
    component.message = { ...mockMessage, statusRetorno: 'Erro' };
    expect(component.secondaryAction).toBeDefined();
    expect(component.secondaryAction!.label).toBe('Reprocessar');
  });

  it('deve retornar OK para status 200', () => {
    component.message = mockMessage;
    expect(component.httpStatusLabel).toBe('OK');
  });

  it('deve retornar header class ok para Sucesso', () => {
    component.message = mockMessage;
    expect(component.retornoHeaderClass).toBe('ok');
  });

  it('deve retornar header class err para Erro', () => {
    component.message = { ...mockMessage, statusRetorno: 'Erro' };
    expect(component.retornoHeaderClass).toBe('err');
  });
});
