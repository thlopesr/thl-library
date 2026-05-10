/*------------------------------------------------------------------------
  File        . EmailMessageFactory.cls
  Purpose     . Builds email message data from centralized parameters
  Author(s)   . Lopes
  Notes       . Datasul/TOTVS specific parameter tables.
                - int-param-email
                - thl-ambiente-param-grupo-usuar
                - thl-ambiente-param-grupo-usuar
                - usuar_mestre
                - param_email
------------------------------------------------------------------------*/

using Progress.Lang.*.
using thl-lib.core.environment.EnvironmentResource.

routine-level on error undo, throw.

class thl-lib.communication.email.EmailMessageFactory.

    define public property sender               as character no-undo get. set.
    define public property toRecipients         as character no-undo get. set. 
    define public property ccRecipients         as character no-undo get. set.
    define public property subject              as character no-undo get. set.
    define public property attachmentPath       as character no-undo get. set.
    define public property body                 as character no-undo get. set.
    define public property importance           as integer   no-undo initial 0 get. set.
    define public property programName          as character no-undo get. set.
    define public property envirommentParameter as character no-undo get. set.

    define public property saveReturn       as logical   no-undo get. set.
    define public property smtpServer       as character no-undo get. set.
    define public property smtpPort         as integer   no-undo get. set.
    define public property useTLS           as logical   no-undo get. set.
    define public property useSSL           as logical   no-undo get. set.
    define public property debug            as logical   no-undo get. set.

    //Constructors
    constructor public EmailMessageFactory().
    
        define variable importanceParameter as character no-undo.
        
        EnvironmentResource:initializeEnvironmentParameter().

        this-object:loadRecipients().
        this-object:loadConnectionParameters().

        assign importanceParameter  = EnvironmentResource:getEnvironmentVariable('importancia' )
               saveReturn           = EnvironmentResource:getEnvironmentVariable('monitorar'   ) = 'Sim'
               sender               = EnvironmentResource:getEnvironmentVariable('remetente'   )
               subject              = EnvironmentResource:getEnvironmentVariable('assunto'     )
               body                 = EnvironmentResource:getEnvironmentVariable('corpo'       )
               ccRecipients         = EnvironmentResource:getEnvironmentVariable('cc'          )
               importance           = if importanceParameter = '' then 0 else integer( importanceParameter )
               envirommentParameter = EnvironmentResource:getEnvirommentParameter()
               programName          = EnvironmentResource:getProgramName()
               .
               
    end constructor.

    //Public API
    //Replace placeholders/tokens inside sender/subject/body
    method public void applyPlaceholder( input pField      as character ,
                                         input pToken      as character ,
                                         input pValue      as character ).
        case pField.
            when 'sender'  then sender  = replace(sender,  pToken, pValue).
            when 'subject' then subject = replace(subject, pToken, pValue).
            when 'body'    then body    = replace(body,    pToken, pValue).
        end case.
        
    end method.

    //Internals 
    method private void loadConnectionParameters().

        find first param_email no-lock no-error.

        if not available param_email then
            undo, throw new Progress.Lang.AppError('Email connection parameters (param_email) not found.', 17006).

        assign smtpServer = param_email.cod_servid_e_mail
               smtpPort   = param_email.num_port
               useSSL     = logical(entry(1, param_email.cod_livre_2, '|'))
               useTLS     = logical(entry(2, param_email.cod_livre_2, '|'))
               debug      = logical(entry(3, param_email.cod_livre_2, '|')).
               
    end method.

    method private void loadRecipients().
    
        define variable  cod-grp-usuar as character no-undo.
        
        assign cod-grp-usuar = EnvironmentResource:getEnvironmentVariable('codigoGrupoUsuario').
    
        if can-find(first thl-ambiente-param-grupo-usuar no-lock
                        where thl-ambiente-param-grupo-usuar.cod-grp-usuar = cod-grp-usuar ) then do.

            for each thl-ambiente-param-grupo-usuar no-lock
                where thl-ambiente-param-grupo-usuar.cod-grp-usuar = cod-grp-usuar.
                
                if thl-ambiente-param-grupo-usuar.email-alternativo <> '' then
                    toRecipients = toRecipients + ',' + thl-ambiente-param-grupo-usuar.email-alternativo.

                find first usuar_mestre no-lock
                    where usuar_mestre.cod_usuario = thl-ambiente-param-grupo-usuar.cod-usuario
                    no-error.

                if available usuar_mestre then
                    toRecipients = toRecipients + ',' + usuar_mestre.cod_e_mail_local.

            end.

            if toRecipients <> '' then 
                assign toRecipients = substring(toRecipients, 2, length(toRecipients) - 1).

        end.

    end method.

end class.