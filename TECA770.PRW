#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TECA770.CH"

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECA770
Cadastro de locais internos
 
@sample	TECA770()	
@Return 	nil
@author	Serviços
@since 		23/09/2013
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TECA770
	
Local oBrowse

oBrowse := FwMBrowse():New()

oBrowse:SetAlias("TER")

oBrowse:SetDescription(STR0001) //"Cadastro de Local Interno"
oBrowse:DisableDetails()

oBrowse:Activate()	
	
Return(Nil)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
MenuDef - Cadastro de locais internos

@Return MenuDef
@author Serviços
@since 23/09/2013
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function MenuDef()
LOCAL aRotina:= FWMVCMenu( "TECA770" )

Return aRotina


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Model - Cadastro de locais internos

@Return model
@author Serviços
@since 10/09/2013
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ModelDef()

Local oModel	
Local oStruTER 	:= FWFormStruct(1,"TER")
Local oStruTFN 	:= FWFormStruct(1,"TFN")
Local aAux			:= {}
Local aAux1		:= {}
Local aAux2		:= {}

aAux := FwStruTrigger("TFN_CODIGO","TFN_NOME","At770DscAtend()",.F.,Nil,Nil,Nil)
oStruTFN:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux1 := FwStruTrigger("TER_ESTADO","TER_NOMEST","At770DscEst()",.F.,Nil,Nil,Nil)
oStruTER:AddTrigger(aAux1[1],aAux1[2],aAux1[3],aAux1[4])

aAux2 := FwStruTrigger("TER_CODMUN","TER_NOMMUN","At770DscMun()",.F.,Nil,Nil,Nil)
oStruTER:AddTrigger(aAux2[1],aAux2[2],aAux2[3],aAux2[4])

// Tira a obrigatoriedade do campo para prosseguir com o processo de gravação, 
// a prioridade de consistencia o VALID do campo vem antes da gravação.
oStruTFN:SetProperty("TFN_CODLOC", MODEL_FIELD_OBRIGAT, .F.)

oModel := MPFormModel():New("TECA770",/* bPreValidacao */,/*bPosValidacao*/,/*bCommit*/,/*bCancel*/ )
oModel:AddFields("TERMASTER",/*cOwner*/,oStruTER, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )
oModel:AddGrid( "TFNDETAIL","TERMASTER",oStruTFN,/*bLinePre*/,/*bLinePost*/, /*bPreVal*/, /*bPosVal*/)
oModel:SetRelation( "TFNDETAIL",{{"TFN_FILIAL","xFilial('TFN')"},{"TFN_CODLOC","TER_CODIGO"}} ,"TFN_FILIAL+TFN_CODLOC")
oModel:SetDescription("Cadastro de Local Interno")

// Verificação para linhas duplicadas
oModel:GetModel( "TFNDETAIL" ):SetUniqueLine( { "TFN_CODIGO" } )								  

Return(oModel)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
View - Cadastro de locais internos

@Return view
@author Serviços
@since 10/09/2013
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ViewDef()

Local oView
Local oModel   := FWLoadModel("TECA770")  
Local oStruTER := FWFormStruct(2,"TER")
Local oStruTFN := FWFormStruct(2,"TFN")

oView := FWFormView():New()
oView:SetModel(oModel)

oStruTFN:RemoveField("TFN_CODLOC")

oView:AddField("VIEW_TER",oStruTER,"TERMASTER")
oView:AddGrid( "VIEW_TFN",oStruTFN,"TFNDETAIL")
oView:CreateHorizontalBox("SUPERIOR", 30 )	// 30 = % utilizado da tela
oView:CreateHorizontalBox("INFERIOR", 70 )
oView:SetOwnerView( "VIEW_TER", "SUPERIOR" )
oView:SetOwnerView( "VIEW_TFN", "INFERIOR" )

oView:AddIncrementField( 'VIEW_TFN', 'TFN_ITEM' )

Return(oView)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At770DscAtend

Descrição do Atendente
@author Serviços
@since 17/10/13
@version P11 R9

@return cDesc, Descrição do Atendente
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At770DscAtend()
Local cDesc		:= ""
Local oModel
Local aArea		:= GetArea()

DbSelectArea("AA1")
AA1->(DbSetOrder(1))
If AA1->(DbSeek(xFilial("AA1")+FwFldGet("TFN_CODIGO")))				
	oModel := FWModelActive()
	oModel:setValue("TFNDETAIL","TFN_CODFUN",AA1->AA1_CDFUNC)
	cDesc := AA1->AA1_NOMTEC
EndIf

RestArea(aArea)

Return (cDesc)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At770DscEst

Descrição do Estado
@author Serviços
@since 17/10/13
@version P11 R9

@return cDesc, Descrição do Estado
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At770DscEst()
Local cDesc	:= ""
Local aArea		:= GetArea()

cDesc := Alltrim(POSICIONE("SX5",1,XFILIAL("SX5")+"12"+FwfldGet("TER_ESTADO"),"X5_DESCRI"))

RestArea(aArea)

Return(cDesc)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At770DscMun

Descrição do Municipio
@author Serviços
@since 17/10/13
@version P11 R9

@return cDesc, Descrição do Municipio
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At770DscMun()
Local cDesc	:= ""
Local aArea		:= GetArea()

cDesc := Alltrim(POSICIONE("CC2",1,XFILIAL("CC2")+FwfldGet("TER_ESTADO")+FwFldGet("TER_CODMUN"),"CC2->CC2_MUN"))

RestArea(aArea)

Return(cDesc)