/*------------------------------------------------------------------------
    File        : SchemaUtil
    Purpose     : Consulta o Data Dictionary via handles dinamicos de schema
                  para localizar os campos do indice PRIMARY de uma tabela
                  e para retornar todas as propriedades de campos de uma tabela.
    Author(s)   : Lopes
    Created     : 2026-08-15
    Notes       : Classe pura de consulta — sem efeitos colaterais.
                  getPrimaryIndex*: nao propaga excecao em nenhuma hipotese.
                  getFieldSchema: lanca ThlError para input invalido
                  ou tabela nao encontrada; retorna JsonArray.
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

using Progress.Json.ObjectModel.JsonArray.
using thl-lib.core.error.ThlError.

class thl-lib.util.schema.SchemaUtil.

    define static temp-table ttFieldSchema no-undo
        field field-name    as character
        field data-type_    as character
        field field-format  as character
        field label_        as character
        field column-label_ as character
        field mandatory_    as logical
        field extent_       as integer   initial 0
        field initial-value as character
        field description_  as character
        field field-order   as integer   initial 0
        index ix-order is primary unique field-order.

    method public static final longchar getPrimaryIndexFieldsAsJson ( input databaseName as character,
                                                                      input tableName    as character ).

        define variable fileBuffer       as handle    no-undo.
        define variable indexBuffer      as handle    no-undo.
        define variable indexFieldBuffer as handle    no-undo.
        define variable fieldBuffer      as handle    no-undo.
        define variable fieldOrder       as integer   no-undo.
        define variable maxFields        as integer   no-undo.
        define variable fieldName        as character no-undo.
        define variable jsonArray        as JsonArray no-undo.

        do on error undo, return '[]':u:

            if databaseName = '':u or databaseName = ? or
               tableName    = '':u or tableName    = ? then return '[]':u.

            /* 1. Localiza _File */
            create buffer fileBuffer for table
                substitute( '&1._File', databaseName ) no-error.

            if not valid-handle( fileBuffer ) then return '[]':u.

            fileBuffer:find-first(
                substitute( 'where _File._File-name = "&1"', tableName ),
                no-lock ) no-error.

            if not fileBuffer:available then return '[]':u.

            /* 2. Localiza o primeiro indice unico (PRIMARY) */
            create buffer indexBuffer for table
                substitute( '&1._Index', databaseName ) no-error.

            if not valid-handle( indexBuffer ) then return '[]':u.

            indexBuffer:find-first(
                substitute( 'where _Index._File-recid = &1 and _Index._Unique = true',
                    fileBuffer:recid ),
                no-lock ) no-error.

            if not indexBuffer:available then return '[]':u.

            /* 3. Itera _Index-field em ordem e monta JsonArray */
            create buffer indexFieldBuffer for table
                substitute( '&1._Index-field', databaseName ) no-error.

            create buffer fieldBuffer for table
                substitute( '&1._Field', databaseName ) no-error.

            if not valid-handle( indexFieldBuffer ) or
               not valid-handle( fieldBuffer )      then return '[]':u.

            assign maxFields = integer( indexBuffer:buffer-field( '_Num-comp' ):buffer-value )
                   jsonArray  = new JsonArray().

            do fieldOrder = 1 to maxFields:

                indexFieldBuffer:find-first(
                    substitute(
                        'where _Index-field._Index-recid = &1 and _Index-field._Index-seq = &2',
                        indexBuffer:recid,
                        fieldOrder ),
                    no-lock ) no-error.

                if not indexFieldBuffer:available then next.

                fieldBuffer:find-first(
                    substitute( 'where recid( _Field ) = &1',
                        indexFieldBuffer:buffer-field( '_Field-recid' ):buffer-value ),
                    no-lock ) no-error.

                if not fieldBuffer:available then next.

                assign fieldName = string( fieldBuffer:buffer-field( '_Field-name' ):buffer-value ).
                jsonArray:Add( fieldName ).

            end. /* do fieldOrder */

            return jsonArray:GetJsonText().

        end. /* do on error */

        finally.
            delete object fileBuffer       no-error.
            delete object indexBuffer      no-error.
            delete object indexFieldBuffer no-error.
            delete object fieldBuffer      no-error.
            delete object jsonArray        no-error.
        end finally.

    end method.

    /*  Compatibilidade: retorna lista separada por virgula (uso interno/legado).
        Prefira getPrimaryIndexFieldsAsJson para qualquer output serializado.  */
    method public static final character getPrimaryIndexfieldsName ( input databaseName as character,
                                                                     input tableName    as character ).

        define variable fileBuffer       as handle    no-undo.
        define variable indexBuffer      as handle    no-undo.
        define variable indexFieldBuffer as handle    no-undo.
        define variable fieldBuffer      as handle    no-undo.
        define variable fieldsName       as character no-undo initial '':u.
        define variable fieldOrder       as integer   no-undo.
        define variable maxFields        as integer   no-undo.
        define variable fieldName        as character no-undo.

        do on error undo, return '':u:

            if databaseName = '':u or databaseName = ? or
               tableName    = '':u or tableName    = ? then return '':u.

            create buffer fileBuffer for table
                substitute( '&1._File', databaseName ) no-error.

            if not valid-handle( fileBuffer ) then return '':u.

            fileBuffer:find-first(
                substitute( 'where _File._File-name = "&1"', tableName ),
                no-lock ) no-error.

            if not fileBuffer:available then return '':u.

            create buffer indexBuffer for table
                substitute( '&1._Index', databaseName ) no-error.

            if not valid-handle( indexBuffer ) then return '':u.

            indexBuffer:find-first(
                substitute( 'where _Index._File-recid = &1 and _Index._Unique = true',
                    fileBuffer:recid ),
                no-lock ) no-error.

            if not indexBuffer:available then return '':u.

            create buffer indexFieldBuffer for table
                substitute( '&1._Index-field', databaseName ) no-error.

            create buffer fieldBuffer for table
                substitute( '&1._Field', databaseName ) no-error.

            if not valid-handle( indexFieldBuffer ) or
               not valid-handle( fieldBuffer )      then return '':u.

            assign maxFields = integer( indexBuffer:buffer-field( '_Num-comp' ):buffer-value ).

            do fieldOrder = 1 to maxFields:

                indexFieldBuffer:find-first(
                    substitute(
                        'where _Index-field._Index-recid = &1 and _Index-field._Index-seq = &2',
                        indexBuffer:recid,
                        fieldOrder ),
                    no-lock ) no-error.

                if not indexFieldBuffer:available then next.

                fieldBuffer:find-first(
                    substitute( 'where recid( _Field ) = &1',
                        indexFieldBuffer:buffer-field( '_Field-recid' ):buffer-value ),
                    no-lock ) no-error.

                if not fieldBuffer:available then next.

                assign fieldName  = string( fieldBuffer:buffer-field( '_Field-name' ):buffer-value )
                       fieldsName = if fieldsName = '':u then fieldName
                                                         else fieldsName + ',':u + fieldName.

            end. /* do fieldOrder */

            return fieldsName.

        end. /* do on error */

        finally.
            delete object fileBuffer       no-error.
            delete object indexBuffer      no-error.
            delete object indexFieldBuffer no-error.
            delete object fieldBuffer      no-error.
        end finally.

    end method.


    method public static final void getFieldSchema( input  databaseName as character,
                                                    input  tableName    as character,
                                                    output table for ttFieldSchema  ).

        define variable fileBuffer  as handle no-undo.
        define variable fieldBuffer as handle no-undo.
        define variable queryBuffer as handle no-undo.

        temp-table ttFieldSchema:empty-temp-table() no-error.

        if databaseName = '':u or databaseName = ? or
           tableName    = '':u or tableName    = ? then
            undo, throw new ThlError( 'thl-lib.util.schema.SchemaUtil', 'getFieldSchema',
                substitute('databaseName e tableName sao obrigatorios — recebido: "&1" / "&2"',
                    string(databaseName), string(tableName)) ).

        create buffer fileBuffer for table
            substitute('&1._File', databaseName) no-error.

        if not valid-handle(fileBuffer) then
            undo, throw new ThlError( 'thl-lib.util.schema.SchemaUtil', 'getFieldSchema',
                substitute('Banco "&1" nao esta conectado nesta sessao PASOE', databaseName) ).

        fileBuffer:find-first(
            substitute('where _File._File-name = "&1"', tableName),
            no-lock) no-error.

        if not fileBuffer:available then
            undo, throw new ThlError( 'thl-lib.util.schema.SchemaUtil', 'getFieldSchema',
                substitute('Tabela "&1" nao encontrada no banco "&2"', tableName, databaseName) ).

        create buffer fieldBuffer for table
            substitute('&1._Field', databaseName) no-error.

        if not valid-handle(fieldBuffer) then
            undo, throw new ThlError( 'thl-lib.util.schema.SchemaUtil', 'getFieldSchema',
                substitute('Nao foi possivel criar buffer _Field para o banco "&1"', databaseName) ).

        create query queryBuffer.
        queryBuffer:set-buffers(fieldBuffer).
        queryBuffer:query-prepare(
            substitute('for each _Field where _Field._File-recid = &1 no-lock by _Field._Order',
                fileBuffer:recid)).
        queryBuffer:query-open().
        queryBuffer:get-first().

        do while not queryBuffer:query-off-end.

            create ttFieldSchema.
            assign ttFieldSchema.field-name    = fieldBuffer:buffer-field('_Field-name'):buffer-value
                   ttFieldSchema.data-type_    = fieldBuffer:buffer-field('_Data-type'):buffer-value
                   ttFieldSchema.field-format  = fieldBuffer:buffer-field('_Format'):buffer-value
                   ttFieldSchema.label_        = fieldBuffer:buffer-field('_Label'):buffer-value
                   ttFieldSchema.column-label_ = fieldBuffer:buffer-field('_Col-label'):buffer-value
                   ttFieldSchema.mandatory_    = logical(fieldBuffer:buffer-field('_Mandatory'):buffer-value)
                   ttFieldSchema.extent_       = integer(fieldBuffer:buffer-field('_Extent'):buffer-value)
                   ttFieldSchema.initial-value = fieldBuffer:buffer-field('_Initial'):buffer-value
                   ttFieldSchema.description_  = fieldBuffer:buffer-field('_Desc'):buffer-value
                   ttFieldSchema.field-order   = integer(fieldBuffer:buffer-field('_Order'):buffer-value).

            queryBuffer:get-next().

        end. /* do while queryBuffer:query-off-end */

        finally:
            if valid-handle(queryBuffer) then
            do:
                if queryBuffer:is-open then
                    queryBuffer:query-close() no-error.
                delete object queryBuffer no-error.
            end.
            delete object fileBuffer  no-error.
            delete object fieldBuffer no-error.
        end finally.

    end method.

end class.
