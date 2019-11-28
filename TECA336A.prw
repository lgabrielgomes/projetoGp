#Include 'Protheus.ch'
#INCLUDE 'FWMVCDEF.CH' 
#INCLUDE 'TECA336A.CH'

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Definição do modelo de dados da tabela TW5 - Ausências.
Esse modelo de dados não possui interface, ele é alimentado de acordo com o que for preenchido na interface do TECA336.

@author Leandro F. Dourado 
@version 12.1.15
@since 02/12/2016
@return oModel
/*/
//--------------------------------------------------------------------------------------------------------
Static Function ModelDef()
Local oStruTW5 := FWFormStruct( 1, 'TW5' )
Local oModel   := MPFormModel():New('TECA336A')

oModel:AddFields( 'TW5MASTER', /*cOwner*/, oStruTW5)
oModel:SetDescription( STR0001 ) //"Ausências"
oModel:SetPrimaryKey( {"TW5_FILIAL","TW5_COD"} )

Return oModel
