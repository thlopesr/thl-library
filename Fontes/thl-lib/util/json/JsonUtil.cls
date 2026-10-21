/*------------------------------------------------------------------------
    File        : JsonUtil
    Purpose     : Consultas genericas sobre JsonObject (sem mapear para
                  buffer, papel do JsonSetter, nem serializar, papel do
                  JsonWriter).
    Author(s)   : Lopes
    Created     : 2026-09-30
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.

using thl-lib.core.error.ThlError.

block-level on error undo, throw.

class thl-lib.util.json.JsonUtil.

    //indica se o JSON tem ao menos uma das propriedades da lista (separada por virgula)
    method public static final logical hasAnyProperty( input json         as JsonObject,
                                                       input propertyList as character ).

        define variable propertyIdx as integer no-undo.

        if not valid-object( json ) then
            return false.

        do propertyIdx = 1 to num-entries( propertyList ):
            if json:Has( trim( entry( propertyIdx, propertyList ) ) ) then
                return true.
        end.

        return false.

    end method.

    //Exige que o JSON traga todas as propriedades da lista (separada por virgula).
    //Confere so a presenca: conteudo e regra de negocio ficam com quem chama.
    //ownerName = nome da classe que exige (vai para a mensagem do erro, 17006).
    method public static final void requireProperties( input json         as JsonObject,
                                                       input propertyList as character ,
                                                       input ownerName    as character ).

        define variable propertyIdx  as integer   no-undo.
        define variable propertyName as character no-undo.
        define variable missingList  as character no-undo.

        do propertyIdx = 1 to num-entries( propertyList ):

            assign propertyName = trim( entry( propertyIdx, propertyList ) ).

            if not valid-object( json ) or not json:Has( propertyName ) then
                assign missingList = missingList + ( if missingList = '' then '' else ', ' ) + propertyName.

        end.

        if missingList <> '' then
            undo, throw new ThlError( ownerName, 'requireProperties',
                substitute( 'Campo obrigatorio nao informado: &1.', missingList ) ).

    end method.

    //Lista de nomes gravada no cadastro como array JSON de texto (["a","b"]).
    //Devolve os nomes separados por virgula; em branco ou [] devolve ''.
    //Texto que nao e um array de texto lanca erro (17006).
    method public static final character nameListToCsv( input jsonText as character ).

        define variable parsed   as JsonConstruct no-undo.
        define variable nameList as JsonArray     no-undo.
        define variable nameIdx  as integer       no-undo.
        define variable csv      as character     no-undo.

        if jsonText = ? or trim( jsonText ) = '' then
            return ''.

        do on error undo, throw:

            assign parsed = new ObjectModelParser():Parse( jsonText ).

            //JSON mal formado: mesma mensagem do array de tipo errado
            catch parseError as Progress.Lang.Error:
                undo, throw new ThlError( 'thl-lib.util.json.JsonUtil', 'nameListToCsv',
                    substitute( 'Lista de campos invalida: &1. Informe um array JSON de texto.', jsonText ) ).
            end catch.

        end.

        if not valid-object( parsed ) or not type-of( parsed, JsonArray ) then
            undo, throw new ThlError( 'thl-lib.util.json.JsonUtil', 'nameListToCsv',
                substitute( 'Lista de campos invalida: &1. Informe um array JSON de texto.', jsonText ) ).

        assign nameList = cast( parsed, JsonArray ).

        do nameIdx = 1 to nameList:Length:

            if nameList:GetType( nameIdx ) <> JsonDataType:STRING or
               trim( nameList:GetCharacter( nameIdx ) ) = ''     then
                undo, throw new ThlError( 'thl-lib.util.json.JsonUtil', 'nameListToCsv',
                    substitute( 'Lista de campos invalida: &1. Cada item deve ser um nome de campo.', jsonText ) ).

            assign csv = csv + ( if csv = '' then '' else ',' ) + trim( nameList:GetCharacter( nameIdx ) ).

        end.

        return csv.

    end method.

end class.
