#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TECA931A.CH"

//------------------------------------------------------------------------------
/*/{Protheus.doc} TECA931A
@description	Tipos de Ocorrencias
@sample	 		TECA931A()
@param 			Nenhum
@return			NIL
@author			Adrianne Furtado (adrianne.andrade)
@since			13/07/2016
@version		P12   
/*/
//------------------------------------------------------------------------------
Function TECA931A()

Local	oMBrowse	:= FWmBrowse():New()

oMBrowse:SetAlias("TWV")				// "TWV"-Tipos de Ocorrencia
oMBrowse:SetDescription(STR0001)		// "Tipos de Ocorrencia"
oMBrowse:Activate()
Return	NIL


//------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
@description	Define o menu funcional.
@sample	 		MenuDef()
@param			Nenhum
@return			ExpA: Opções da Rotina.
@author			Adrianne Furtado (adrianne.andrade)
@since			13/07/2016
@version		P12
/*/	
//------------------------------------------------------------------------------
Static Function MenuDef()    

Local	aRotina	:= {}

ADD OPTION aRotina TITLE STR0002 	ACTION "PesqBrw"          OPERATION 1                      ACCESS 0	// "Pesquisar"
ADD OPTION aRotina TITLE STR0003	ACTION "VIEWDEF.TECA931A" OPERATION MODEL_OPERATION_VIEW   ACCESS 0	// "Visualizar"
ADD OPTION aRotina TITLE STR0004	ACTION "VIEWDEF.TECA931A" OPERATION MODEL_OPERATION_INSERT ACCESS 0	// "Incluir"
ADD OPTION aRotina TITLE STR0005	ACTION "VIEWDEF.TECA931A" OPERATION MODEL_OPERATION_UPDATE ACCESS 0	// "Alterar"
ADD OPTION aRotina TITLE STR0006	ACTION "VIEWDEF.TECA931A" OPERATION MODEL_OPERATION_DELETE ACCESS 0	// "Excluir"
Return(aRotina)


//------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
@description	Definição do Model
@sample	 		ModelDef()
@param			Nenhum
@return			ExpO: Objeto FwFormModel
@author			Adrianne Furtado (adrianne.andrade)
@since			13/07/2016
@version		P12
/*/
//------------------------------------------------------------------------------
Static Function ModelDef()

Local	oModel		:= Nil
Local	oStrTWV 	:= FWFormStruct(1, "TWV")	// TWJ - Tipos de Ocorrencia

oModel := MPFormModel():New("TECA931A", /*bPreValid*/, /*bPostValid*/, /*bCommit*/, /*bCancel*/)				// Cria o objeto do modelo de dados principal

oModel:AddFields("TWVMASTER", /*cOwner*/ , oStrTWV)								// Cria a antiga Enchoice 

Return(oModel)


//------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
@description	Definição da View
@sample	 		ViewDef()
@param			Nenhum
@return			ExpO: Objeto FwFormView
@author			Adrianne Furtado (adrianne.andrade)
@since			13/07/2016
@version		P12
/*/
//------------------------------------------------------------------------------
Static Function ViewDef()

Local oView		:= Nil								// Interface de visualização construída	
Local oModel	:= ModelDef()						// Cria um objeto de Modelo de dados baseado no ModelDef do fonte informado
Local oStrTWV	:= FWFormStruct(2, "TWV")			// Cria a estrutura a ser usada na View

oView	:= FWFormView():New()						// Cria o objeto de View
oView:SetModel(oModel)								// Define qual modelo de dados será utilizado

oView:AddField("VIEW_TWV", oStrTWV, "TWVMASTER")	// Adiciona ao nosso View um controle do tipo formulário (antiga Enchoice)

// Identificação (Nomeação) da VIEW
oView:SetDescription(STR0001)		// "Tipos de Ocorrencia"

Return(oView)
