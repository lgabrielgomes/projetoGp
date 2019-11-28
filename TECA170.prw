#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#Include 'TECA170.ch'

Function TECA170()

Local oBrw := FwMBrowse():New()

oBrw:SetAlias( 'TIX' )
oBrw:SetMenudef( "TECA170" )
oBrw:SetDescription( OEmToAnsi( STR0001 ) ) //"Cadastro de Motivos de Ocorrências"

oBrw:Activate()

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} Menudef
	Rotina para construção do menu
@sample 	Menudef() 
@since		06/09/2013  
@version 	P11.90
/*/
//------------------------------------------------------------------------------
Static Function Menudef()

Local aMenu := FWMVCMenu("TECA170")

Return aMenu

//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Definição do modelo de Dados

@author arthur.colado

@since 18/03/2014
@version 1.0
/*/
//-------------------------------------------------------------------

Static Function ModelDef()
Local oModel

 
Local oStr1:= FWFormStruct(1,'TIX')
oModel := MPFormModel():New('TECA170')
oModel:SetDescription('TECA170')
oModel:addFields('Cad.Motivos',,oStr1)
oModel:SetPrimaryKey({ 'TIX_FILIAL', 'TIX_CODIGO' })
oModel:getModel('Cad.Motivos'):SetDescription(STR0001)//"Cadastro de Motivos de Ocorrências"

Return oModel
//-------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Definição do interface

@author arthur.colado

@since 18/03/2014
@version 1.0
/*/
//-------------------------------------------------------------------

Static Function ViewDef()
Local oView
Local oModel := ModelDef()

 
Local oStr1:= FWFormStruct(2, 'TIX')
oView := FWFormView():New()

oView:SetModel(oModel)
oView:AddField('Cad.Motivos' , oStr1,'Cad.Motivos' ) 
oView:CreateHorizontalBox( 'BOXFORM1', 100)
oView:SetOwnerView('Cad.Motivos','BOXFORM1')

Return oView