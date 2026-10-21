import { ComponentFixture, TestBed } from '@angular/core/testing';
import { CommonModule } from '@angular/common';
import { PoModule, PoNotificationService } from '@po-ui/ng-components';
import { EmailDetailModalComponent } from './email-detail-modal.component';
import { Email } from '../../models/email.model';

describe('EmailDetailModalComponent', () => {
  let component: EmailDetailModalComponent;
  let fixture: ComponentFixture<EmailDetailModalComponent>;
  let notificationSpy: jasmine.SpyObj<PoNotificationService>;

  const mockEmail: Email = {
    id: 'db29c9ec-7ac1-05b7-f614-2c2a3c424ce3',
    assunto: 'Geração de Garantias',
    remetente: 'sistema@empresa.com.br',
    destino: 'cliente@agrobio.com.br',
    codProgDtsul: 'tkn4001e',
    codParamAmbiente: 'process.credito',
    dtEnvio: '2026-09-17T10:30:00',
    logEnvio: 'Sucesso',
    arqAnexo: '',
    mensagem: '{"tt-mensagem":[{"mensagem":"E-mail enviado com sucesso"}]}',
    informacao: '{"codParamAmbiente":"process.credito","codProgDtsul":"tkn4001e","servidorSmtp":"smtp.nitroquimica.com.br","porta":"587","tls":"true","timeout":"30000"}',
    retorno: '{"status":"250 OK","code":250}'
  };

  beforeEach(async () => {
    notificationSpy = jasmine.createSpyObj('PoNotificationService', ['success', 'information']);

    await TestBed.configureTestingModule({
      imports: [CommonModule, PoModule, EmailDetailModalComponent],
      providers: [
        { provide: PoNotificationService, useValue: notificationSpy }
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(EmailDetailModalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('deve criar o componente', () => {
    expect(component).toBeTruthy();
  });

  it('deve retornar titulo padrao sem email', () => {
    component.email = null;
    expect(component.modalTitle).toBe('Detalhes E-mail');
  });

  it('deve retornar titulo com assunto quando email definido', () => {
    component.email = mockEmail;
    expect(component.modalTitle).toContain('Geração de Garantias');
  });

  it('deve mapear logEnvio Sucesso para tag type success', () => {
    component.email = mockEmail;
    expect(component.statusTagType).toBeTruthy();
  });

  it('deve emitir closed ao fechar', () => {
    spyOn(component.closed, 'emit');
    component.onClose();
    expect(component.closed.emit).toHaveBeenCalled();
  });

  it('deve emitir reenviar com id do email', () => {
    spyOn(component.reenviar, 'emit');
    component.email = mockEmail;
    component.onReenviar();
    expect(component.reenviar.emit).toHaveBeenCalledWith(mockEmail.id);
    expect(component.isResending).toBeTrue();
  });

  it('deve copiar id para clipboard', async () => {
    spyOn(navigator.clipboard, 'writeText').and.returnValue(Promise.resolve());
    component.email = mockEmail;
    await component.copyId();
    expect(navigator.clipboard.writeText).toHaveBeenCalledWith(mockEmail.id);
  });

  it('deve formatar retorno como JSON', () => {
    component.email = mockEmail;
    const formatted = component.retornoFormatted;
    expect(formatted).toContain('"status": "250 OK"');
  });

  it('deve parsear parametros do campo informacao', () => {
    component.email = mockEmail;
    const params = component.parametros;
    expect(params.length).toBeGreaterThan(0);
    expect(params.find(p => p.label === 'Servidor SMTP')?.valor).toBe('smtp.nitroquimica.com.br');
  });

  it('nao deve exibir secondaryAction quando logEnvio nao eh Erro', () => {
    component.email = mockEmail;
    expect(component.secondaryAction).toBeUndefined();
  });

  it('deve exibir secondaryAction quando logEnvio eh Erro', () => {
    component.email = { ...mockEmail, logEnvio: 'Erro' };
    expect(component.secondaryAction).toBeDefined();
    expect(component.secondaryAction!.label).toBe('Reenviar');
  });
});
