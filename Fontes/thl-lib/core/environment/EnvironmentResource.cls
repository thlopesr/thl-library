
 /*------------------------------------------------------------------------
    File        : EnvironmentResource
    Purpose     : Fachada para resolucao de variaveis de ambiente.
                  Instanciar uma vez por escopo; o construtor resolve
                  environment + parameterCode e os armazena na instancia.
    Author(s)   : Lopes
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

using thl-lib.core.environment.EnvironmentContext.
using thl-lib.core.environment.EnvironmentUtil.
using thl-lib.core.environment.repository.EnvironmentRepository.
using thl-lib.util.string.StringUtil.
using thl-lib.core.error.ThlError.

class thl-lib.core.environment.EnvironmentResource.

    define private property environment   as character no-undo get. set. //Ambiente
    define private property parameterCode as character no-undo get. set. //Parametro do ambiente

    constructor public EnvironmentResource( programName as character ).

        assign this-object:environment   = EnvironmentUtil:getEnvironment()
               this-object:parameterCode = EnvironmentRepository:findParameterCodeByProgram( programName ).

        if not StringUtil:hasValue( this-object:parameterCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'constructor',
                substitute( 'Parametro nao encontrado para o programa: &1', programName ) ).

    end constructor.

    constructor public EnvironmentResource().
        assign this-object:environment   = EnvironmentUtil:getEnvironment()
               this-object:parameterCode = EnvironmentContext:setParameterCode().
    end constructor.

    method public character getEnvironmentVariable().
        return EnvironmentRepository:findVariableValue( this-object:environment, this-object:parameterCode, '' ).
    end method.

    method public character getEnvironmentVariable( variableCode as character ).
        return EnvironmentRepository:findVariableValue( this-object:environment, this-object:parameterCode, variableCode ).
    end method.

    // Variavel indicada por um enum: o codigo e o nome do membro em minusculas, com '_' virando
    // '.' (MENSAGEM_ENTRADA -> mensagem.entrada). O parametro vem do programa (como nos demais
    // metodos de instancia); ambiente atual e, se nao achar, *; sem espacos nas pontas; ausente
    // devolve em branco.
    method public character getEnvironmentVariable( variable as Progress.Lang.Enum ).
        return trim( EnvironmentRepository:findVariableValue( this-object:environment, this-object:parameterCode, StringUtil:enumToCode( variable ) ) ).
    end method.

    // Mesma variavel, como logico (yes ou no) ou inteiro, com valor padrao: variavel ausente ou em
    // branco devolve o padrao; valor que nao converte lanca ThlError com o nome da variavel.
    method public logical getEnvironmentVariable( variable as Progress.Lang.Enum, defaultValue as logical ).

        define variable valueText as character no-undo.

        assign valueText = this-object:getEnvironmentVariable( variable ).

        if valueText = '' then
            return defaultValue.

        return logical( valueText ).

        catch invalidValue as Progress.Lang.Error:
            undo, throw new ThlError( this-object:GetClass():TypeName, 'getEnvironmentVariable',
                substitute( 'Valor invalido no thl0002 para &1: "&2" (informe yes ou no).', variable:toString(), valueText ) ).
        end catch.

    end method.

    // Mesma variavel, como texto, com valor padrao: variavel ausente ou em branco devolve o padrao.
    method public character getEnvironmentVariable( variable as Progress.Lang.Enum, defaultValue as character ).

        define variable valueText as character no-undo.

        assign valueText = this-object:getEnvironmentVariable( variable ).

        if valueText = '' then
            return defaultValue.

        return valueText.

    end method.

    method public integer getEnvironmentVariable( variable as Progress.Lang.Enum, defaultValue as integer ).

        define variable valueText as character no-undo.

        assign valueText = this-object:getEnvironmentVariable( variable ).

        if valueText = '' then
            return defaultValue.

        return integer( valueText ).

        catch invalidValue as Progress.Lang.Error.
            undo, throw new ThlError( this-object:GetClass():TypeName, 'getEnvironmentVariable',
                substitute( 'Valor invalido no thl0002 para &1: "&2" (informe um numero inteiro).', variable:toString(), valueText ) ).
        end catch.

    end method.

    // Utilitarios estaticos: consulta direta sem necessidade de instancia
    method public static character getEnvironmentVariable( codeParameter as character ,
                                                           variableCode  as character ).
        return EnvironmentRepository:findVariableValue( EnvironmentUtil:getEnvironment(), codeParameter, variableCode ).
    end method.

    method public static character getEnvironmentVariable( environment   as character ,
                                                           codeParameter as character ,
                                                           variableCode  as character ).
        return EnvironmentRepository:findVariableValue( environment, codeParameter, variableCode ).
    end method.


end class.
