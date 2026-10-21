 
 /*------------------------------------------------------------------------
    File        : EmailLog
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Thu Jan 09 09:47:05 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using thl-lib.Communication.Email.EmailMessageFactory.

routine-level on error undo, throw.

class thl-lib.communication.email.repository.EmailLogger. 

    define public property messageText   as longchar no-undo get. set. 
    define public property sendInfo      as longchar no-undo get. set.
    define public property returnPayload as longchar no-undo get. set.     

    method public void save( emailMessageFactory as EmailMessageFactory, success as logical).
    
        create thl-email.
        assign thl-email.id                 = guid( generate-uuid )
               thl-email.data-envio         = now
               thl-email.cod-prog-dtsul     = emailMessageFactory:programName
               thl-email.cod-param-ambiente = emailMessageFactory:environmentParameter
               thl-email.remetente          = emailMessageFactory:sender
               thl-email.destino            = emailMessageFactory:toRecipients
               thl-email.assunto            = emailMessageFactory:subject 
               thl-email.arq-anexo          = emailMessageFactory:attachmentPath
               thl-email.log-envio          = if success then 2 else 3 
               thl-email.mensagem           = if length ( this-object:messageText ) > 4000 then 'Corpo do e-mail maior que 4000 caracter'
                                                                                           else this-object:messageText 
               thl-email.info-envio         = this-object:sendInfo
               thl-email.retorno            = this-object:returnPayload
               .

    end method.

end class.