import { HttpInterceptorFn } from '@angular/common/http';
import { cadastroMockInterceptor } from './cadastro-mock.interceptor';

export const mockInterceptors: HttpInterceptorFn[] = [cadastroMockInterceptor];
