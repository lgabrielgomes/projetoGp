#include "TECA790.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH" 

//----------------------------------------------------------
/*/{Protheus.doc} TECA790()
Cadastro de Feriados 

@Return 	nil
@author 	Serviços
@since 		14/05/2014
/*/
//----------------------------------------------------------
Function TECA790()

Local oBrowse 

oBrowse := FwMBrowse():New()
oBrowse:SetAlias("AC0")
oBrowse:SetDescription(STR0001) // STR0001//"Cadastro de Feriados"
oBrowse:DisableDetails()
oBrowse:Activate()

Return(Nil) 


//----------------------------------------------------------
/*/{Protheus.doc} MenuDef()
MenuDef - Cadastro de Feriados

@Return 	MenuDef
@author 	Serviços
@since 		14/05/2014
/*/
//----------------------------------------------------------
Static Function MenuDef()

Local aRotina := {}

ADD OPTION aRotina TITLE STR0002 	ACTION "AxPesqui" 			OPERATION 1	ACCESS 0 	// STR0002//"Pesquisar"
ADD OPTION aRotina TITLE STR0003 	ACTION "VIEWDEF.TECA790"		OPERATION 2 	ACCESS 0 	// STR0003//"Visualizar"
ADD OPTION aRotina TITLE STR0004 	ACTION "VIEWDEF.TECA790" 	OPERATION 3	ACCESS 0 	// STR0004//"Incluir"
ADD OPTION aRotina TITLE STR0005		ACTION "VIEWDEF.TECA790"		OPERATION 4	ACCESS 0 	// STR0005//"Alterar"
ADD OPTION aRotina TITLE STR0006		ACTION "VIEWDEF.TECA790"		OPERATION 5	ACCESS 0 	// STR0006//"Excluir"

Return(aRotina)


//----------------------------------------------------------
/*/{Protheus.doc} ModelDef()
Model - Cadastro de Feriados

@Return 	model
@author 	Serviços
@since 		14/05/2014
/*/
//----------------------------------------------------------
Static Function ModelDef()

Local oModel	// Modelo de dados que será construido
Local oStruAC0 		:= FWFormStruct(1,"AC0") 
Local oStruRR0		:= FwFormStruct(1,"RR0")
Local bCommit		:= {|oModel|At790Grv(oModel)}

oModel := MPFormModel():New("TECA790", /*bPreValidacao*/,/*bPosValidacao*/,bCommit,/*bCancel*/ )

oStruRR0:SetProperty('RR0_DATA',MODEL_FIELD_KEY ,.F.)
oStruRR0:SetProperty('RR0_DATA',MODEL_FIELD_INIT,{||""})
oModel:AddFields("AC0MASTER",/*cOwner*/,oStruAC0, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

oModel:AddGrid('RR0DETAIL','AC0MASTER',oStruRR0)
oModel:SetRelation('RR0DETAIL', { { 'RR0_FILIAL', 'xFilial("RR0")' }, { 'RR0_CODCAL','AC0_CODIGO' } }, RR0->(IndexKey(3)) )

oModel:SetDescription(STR0007) // Cadastro de Feriados 									  //"Cadastro de Feriados"

//Configura o Grid para não duplicar a linha do Grid
oModel:GetModel("RR0DETAIL"):SetUniqueLine({"RR0_DATA"})

Return(oModel)


//----------------------------------------------------------
/*/{Protheus.doc} ViewDef()
View - Cadastro de Feriados

@Return 	view
@author 	Serviços
@since 		15/05/2014
/*/
//----------------------------------------------------------
Static Function ViewDef()

Local oView
Local oModel   	:= FWLoadModel("TECA790")  
Local oStruAC0 	:= FWFormStruct(2,"AC0")
Local oStruRR0		:= FwFormStruct(2,"RR0", { |cCpo| !AllTrim(cCpo)$"RR0_CODCAL+RR0_MESDIA+RR0_RHEXP"})

oView := FWFormView():New()
oView:SetModel(oModel)

oView:AddField("VIEW_AC0",oStruAC0,"AC0MASTER")
oView:AddGrid("VIEW_RR0",oStruRR0,"RR0DETAIL")

oView:CreateHorizontalBox( "TELA" , 20 )
oView:CreateHorizontalBox("INFERIOR" , 80)
 
oView:SetOwnerView( "VIEW_AC0", "TELA" ) 
oView:SetOwnerView( "VIEW_RR0", "INFERIOR" ) 

Return(oView)

Function At790Grv(oModel)
Local nOpcx		:= oModel:GetOperation()
Local oMdlRR0		:= oModel:GetModel("RR0DETAIL")
Local lRet			:= .F.
Local cRR0MesDia	:= Space( TamSx3( "RR0_MESDIA" )[1] )
Local nLoop		:= 0

If nOpcx == MODEL_OPERATION_UPDATE .OR. nOpcx == MODEL_OPERATION_INSERT
	
	For nLoop := 1 To oMdlRR0:Length()
		oMdlRR0:GoLine(nLoop)
	
		If oMdlRR0:GetValue("RR0_FIXO") $ "sS"
			lRet := oMdlRR0:LoadValue("RR0_MESDIA", MesDia(oMdlRR0:GetValue("RR0_DATA")) )
		Else
			lRet := oMdlRR0:LoadValue("RR0_MESDIA", cRR0MesDia )
		EndIf
	
	Next nLoop
		
	lRet := FwFormCommit( oModel )
Else
	
	If oModel:VldData()
		lRet := FwFormCommit( oModel )
	EndIf

EndIf

Return(lRet)