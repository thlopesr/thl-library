import { bootstrapApplication } from '@angular/platform-browser';
import { appCadastroConfig } from './app/app-cadastro.config';
import { AppCadastro } from './app/app-cadastro';

bootstrapApplication(AppCadastro, appCadastroConfig)
  .catch((err) => console.error(err));
