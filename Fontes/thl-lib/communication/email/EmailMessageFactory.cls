/*------------------------------------------------------------------------
  File        : EmailMessageFactory.cls
  Purpose     : Builds email message data from centralized parameters
  Author(s)   : Lopes
  Notes       : Datasul/TOTVS specific parameter tables delegated to
                EmailParamRepository.
------------------------------------------------------------------------*/

using Progress.Lang.*.
using thl-lib.core.environment.EnvironmentContext.
using thl-lib.core.environment.EnvironmentResource.
using thl-lib.communication.email.repository.EmailParamRepository.

block-level on error undo, throw.

class thl-lib.communication.email.EmailMessageFactory.

    define public property sender               as character no-undo get. set.
    define public property toRecipients         as character no-undo get. set.
    define public property ccRecipients         as character no-undo get. set.
    define public property subject              as character no-undo get. set.
    define public property attachmentPath       as character no-undo get. set.
    define public property body                 as character no-undo get. set.
    define public property importance           as integer   no-undo initial 0 get. set.
    define public property programName          as character no-undo get. set.
    define public property environmentParameter as character no-undo get. set.

    define public property saveReturn           as logical   no-undo get. set.
    define public property smtpServer           as character no-undo get. set.
    define public property smtpPort             as integer   no-undo get. set.
    define public property useTLS               as logical   no-undo get. set.
    define public property useSSL               as logical   no-undo get. set.
    define public property debug                as logical   no-undo get. set.

    constructor public EmailMessageFactory().

        define variable emailParamRepository as EmailParamRepository no-undo.

        assign emailParamRepository = new EmailParamRepository().

        emailParamRepository:loadEmailParameters( new EnvironmentResource():getEnvironmentVariable( 'codigo.email' ) ).
        emailParamRepository:loadConnectionParameters().

        assign saveReturn           = emailParamRepository:saveReturn
               sender               = emailParamRepository:sender
               subject              = emailParamRepository:subject
               body                 = emailParamRepository:body
               ccRecipients         = emailParamRepository:ccRecipients
               importance           = emailParamRepository:importance
               toRecipients         = emailParamRepository:loadRecipients( emailParamRepository:userGroupCode )
               smtpServer           = emailParamRepository:smtpServer
               smtpPort             = emailParamRepository:smtpPort
               useSSL               = emailParamRepository:useSSL
               useTLS               = emailParamRepository:useTLS
               debug                = emailParamRepository:debug
               environmentParameter = EnvironmentContext:environmentParameter
               programName          = EnvironmentContext:programName
               .

    end constructor.

    method public void applyPlaceholder( input pField      as character ,
                                         input pToken      as character ,
                                         input pValue      as character ).
        case pField.
            when 'sender'  then sender  = replace(sender,  pToken, pValue).
            when 'subject' then subject = replace(subject, pToken, pValue).
            when 'body'    then body    = replace(body,    pToken, pValue).
        end case.

    end method.

end class.
