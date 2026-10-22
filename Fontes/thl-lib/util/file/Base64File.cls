/*------------------------------------------------------------------------
    File        : Base64File
    Purpose     : Um arquivo recebido em base64: nome, extensao e conteudo.
    Author(s)   : Lopes
    Created     : 2026-10-21
    Notes       : Nome e extensao passam por FileUtil:sanitizeFileName (sem
                  separador de pasta, caractere invalido ou ponto no inicio).
                  Nome e conteudo sao obrigatorios (ThlError, 17006). save()
                  grava no diretorio informado e sobrescreve arquivo de mesmo
                  nome. O conjunto de arquivos e o diretorio ficam no
                  Base64Files.
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.util.file.FileUtil.
using thl-lib.util.string.StringUtil.

block-level on error undo, throw.

class thl-lib.util.file.Base64File.

    define public property fileName  as character no-undo get. private set.
    define public property extension as character no-undo get. private set.
    define public property content   as longchar  no-undo get. private set.

    constructor public Base64File( input fileName  as character,
                                   input extension as character,
                                   input content   as longchar ).

        assign this-object:fileName  = FileUtil:sanitizeFileName( fileName )
               this-object:extension = FileUtil:sanitizeFileName( extension )
               this-object:content   = content.

        if this-object:fileName = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'constructor', 'Arquivo sem nome.' ).

        if not StringUtil:hasValue( this-object:content ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'constructor',
                substitute( 'Arquivo &1 sem conteudo (conteudoBase64).', this-object:fileName ) ).

    end constructor.

    //nome.extensao (sem extensao: so o nome)
    method public character getFullName().
        return this-object:fileName + ( if this-object:extension <> '' then '.' + this-object:extension else '' ).
    end method.

    //Grava no diretorio (que precisa existir) e devolve o caminho completo
    method public character save( input directory as character ).

        define variable filePath as character no-undo.

        assign filePath = directory + '/' + this-object:getFullName().

        FileUtil:saveBase64AsFile( filePath, this-object:content ).

        return filePath.

    end method.

end class.
