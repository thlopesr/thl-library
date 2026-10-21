/*------------------------------------------------------------------------
  File        : EmailParamRepository.cls
  Purpose     : Loads email configuration data from parameter tables
                (thl-email-param, param_email,
                 thl-ambiente-param-grupo-usuar, usuar_mestre).
  Author(s)   : Lopes
------------------------------------------------------------------------*/

using Progress.Lang.*.
using thl-lib.util.string.StringUtil.
using thl-lib.core.error.ThlError.

block-level on error undo, throw.

class thl-lib.communication.email.repository.EmailParamRepository.

    define public property saveReturn    as logical   no-undo get. private set.
    define public property sender        as character no-undo get. private set.
    define public property subject       as character no-undo get. private set.
    define public property body          as character no-undo get. private set.
    define public property ccRecipients  as character no-undo get. private set.
    define public property importance    as integer   no-undo initial 0 get. private set.
    define public property userGroupCode as character no-undo get. private set.

    define public property smtpServer as character no-undo get. private set.
    define public property smtpPort   as integer   no-undo get. private set.
    define public property useTLS     as logical   no-undo get. private set.
    define public property useSSL     as logical   no-undo get. private set.
    define public property debug      as logical   no-undo get. private set.

    method public void loadEmailParameters( input emailParamCode as character ).

        if not StringUtil:hasValue( emailParamCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'loadEmailParameters', 'Codigo do parametro de email (codigoEmail) nao informado.' ).

        find first thl-email-param no-lock
            where thl-email-param.cod-email-param = emailParamCode no-error.

        if not available thl-email-param then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'loadEmailParameters', 'Parametros de conexao de email thl-email-param nao encontrados.' ).

        assign saveReturn    = thl-email-param.log-gerar
               sender        = thl-email-param.remetente
               subject       = thl-email-param.assunto
               body          = thl-email-param.mensagem
               ccRecipients  = thl-email-param.copia
               importance    = thl-email-param.importancia
               userGroupCode = thl-email-param.cod-grp-usuar.

    end method.

    method public void loadConnectionParameters().

        find first param_email no-lock no-error.

        if not available param_email then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'loadConnectionParameters', 'Parametros de conexao de email (param_email) nao encontrados.' ).

        assign smtpServer = param_email.cod_servid_e_mail
               smtpPort   = param_email.num_port
               useSSL     = logical(entry(1, param_email.cod_livre_2, '|'))
               useTLS     = logical(entry(2, param_email.cod_livre_2, '|'))
               debug      = logical(entry(3, param_email.cod_livre_2, '|')).

    end method.

    method public character loadRecipients( input groupCode as character ).

        define variable recipients as character no-undo.

        if not StringUtil:hasValue( groupCode ) then
            return ''.

        for each thl-ambiente-param-grupo-usuar no-lock
            where thl-ambiente-param-grupo-usuar.cod-grp-usuar = groupCode.

            if StringUtil:hasValue( thl-ambiente-param-grupo-usuar.email-alternativo ) then
                assign recipients = recipients + ',' + thl-ambiente-param-grupo-usuar.email-alternativo.

            find first usuar_mestre no-lock
                where usuar_mestre.cod_usuario = thl-ambiente-param-grupo-usuar.cod-usuario no-error.

            if available usuar_mestre                               and
               StringUtil:hasValue( usuar_mestre.cod_e_mail_local ) then
                assign recipients = recipients + ',' + usuar_mestre.cod_e_mail_local.

        end.

        return trim( recipients, ',' ).

    end method.

end class.
