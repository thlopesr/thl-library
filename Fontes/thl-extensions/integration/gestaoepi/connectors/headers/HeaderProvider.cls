 /*------------------------------------------------------------------------
    File        : HeaderProvider
    Purpose     : Calcula e injeta os headers de autenticacao HMAC-SHA256
                  exigidos pela API de callback do GestaoEPI:
                    X-Datasul-Timestamp : Unix timestamp UTC em segundos
                    X-Datasul-Signature : "sha256=" + HMAC-SHA256(ts + "." + body, secret)
                  O secret e recebido via parametro (thl-conexao-rest-caberario.valor-parametro).
    Author(s)   : Lopes
    Created     : Sun Aug 24 00:00:00 BRT 2026
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using System.Security.Cryptography.HMACSHA256.
using System.Text.Encoding.
using System.BitConverter.
using System.DateTimeOffset.

using thl-lib.integration.connectors.headers.interfaces.IHeaderProvider.
using thl-lib.core.error.ThlError.

block-level on error undo, throw.

class thl-extensions.integration.gestaoepi.connectors.headers.HeaderProvider
    implements IHeaderProvider.

    method public JsonArray getHeaders ( body       as longchar  ,
                                         parameters as character ).

        define variable timestamp    as int64           no-undo.
        define variable message_     as character        no-undo.
        define variable secretBytes  as 'System.Byte[]' no-undo.
        define variable messageBytes as 'System.Byte[]' no-undo.
        define variable hashBytes    as 'System.Byte[]' no-undo.
        define variable hmacSha256   as HMACSHA256      no-undo.
        define variable hmacHex      as character        no-undo.
        define variable headers      as JsonArray        no-undo.
        define variable headerTs     as JsonObject       no-undo.
        define variable headerSig    as JsonObject       no-undo.

        if parameters = '' or parameters = ? then
            undo, throw new ThlError(
                this-object:GetClass():TypeName,
                'getHeaders',
                'Secret HMAC nao informado. Verifique thl-conexao-rest-header.valor-parametro.'
            ).

        assign timestamp    = DateTimeOffset:UtcNow:ToUnixTimeSeconds()
               message_     = string(timestamp) + '.' + string(body)
               secretBytes  = Encoding:UTF8:GetBytes(parameters)
               messageBytes = Encoding:UTF8:GetBytes(message_)
               hmacSha256   = new HMACSHA256(secretBytes)
               hashBytes    = hmacSha256:ComputeHash(messageBytes)
               hmacHex      = lc(replace(BitConverter:ToString(hashBytes), '-', ''))
               .

        assign headers   = new JsonArray()
               headerTs  = new JsonObject()
               headerSig = new JsonObject()
               .

        headerTs:Add('key',   'X-Datasul-Timestamp').
        headerTs:Add('value', string(timestamp)).

        headerSig:Add('key',   'X-Datasul-Signature').
        headerSig:Add('value', 'sha256=' + hmacHex).

        headers:Add(headerTs).
        headers:Add(headerSig).

        return headers.

        finally:
            if valid-object(hmacSha256) then
                hmacSha256:Dispose().
        end finally.

    end method.

end class.
