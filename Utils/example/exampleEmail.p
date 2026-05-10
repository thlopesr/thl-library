
/*------------------------------------------------------------------------
    File        : exampleEmail.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : Lopes
    Created     : Thu Apr 23 11:02:40 BRT 2026
    Notes       :
  ----------------------------------------------------------------------*/

using thl-lib.communication.email.EmailSerivce.
using thl-lib.communication.email.EmailMessageFactory.

/* ***************************  Main Block  *************************** */
define variable emailMessageFactory as EmailMessageFactory no-undo.

assign emailMessageFactory                = new EmailMessageFactory()
       //emailMessageFactory:sender         = ''
       emailMessageFactory:toRecipients   = 'lopesrth@gmail.com'
       //emailMessageFactory:ccRecipients   = ''
       //emailMessageFactory:subject        = 'Teste novo assunto'
       emailMessageFactory:attachmentPath = '\\tsclient\c\temp\thl-mensagem-conteudo.txt'
       emailMessageFactory:body           = 'Teste novo corpo'.
           
emailMessageFactory:applyPlaceholder('subject', '#1#', 'Novo valor E-mail').
//new EmailSerivce(emailMessageFactory):sender().
new EmailSerivce():sender().
