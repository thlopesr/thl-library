 
 /*------------------------------------------------------------------------
    File        : ConnectorService
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Tue Mar 10 16:56:15 BRT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using thl-lib.integration.connectors.types.RestConnector.
using thl-lib.integration.connectors.types.IntegrationConnector.
using thl-lib.integration.connectors.enum.ConnectorTypeEnum.

class thl-lib.integration.connectors.factory.ConnectorFactory.

    method public IntegrationConnector createConnector( connectorType as integer ).
        
        case connectorType.
            when ConnectorTypeEnum:REST:GetValue()  then return new RestConnector().
            //when 2 then return new SoapConnector().
            //when 3 then return new DatabaseConnector().
            //when 4 then return new FileConnector().
            
            otherwise 
                undo, throw new AppError( substitute('Unsupported connector type: &1.', connectorType ), 17006 ).

        end case.

    end method.

end class.