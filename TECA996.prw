#include "protheus.ch"
#include "fwmvcdef.ch"
#include "teca996.ch"

//------------------------------------------------------------------------------
/*/{Protheus.doc} TECA996
Cadastro de Configuração de Planilha 
@sample 	TECA996()
@param		Nenhum
@return	Nenhum
@since		08/10/2018
@author	Serviços
@version	12.1.17
/*/
//------------------------------------------------------------------------------
Function TECA996
Local oBrowse 	:= NIL							//Objeto Browse
Local lOrcPrc 	:= SuperGetMv("MV_ORCPRC",,.F.) //Orçamento Por tabela de Preço

	
If TableInDic( "TX8", .F. ) .AND. !lOrcPrc
	
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("TX8")
	oBrowse:SetDescription(STR0001) //"Cadastro de Configurações de Planilha"                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
	oBrowse:Activate()
Else
	Help( ,, 'TECA996Main',, STR0002, 1, 0 ) //"Para utilizar o cadastro de Configurações de Planilha, é necessário a criação da tabela TX8 e a configaração de Precificação do Orçamento para Planilha de Preços parâmetro MV_ORCPRC desabilitado"
EndIf
		
Return


//------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Define o menu funcional.
@sample 	MenuDef()
@param		Nenhum
@return	ExpA Opções da Rotina.
@since		08/10/2018
@author	Serviços
@version	12.1.17
/*/
//------------------------------------------------------------------------------
Static Function MenuDef()
Local aRotina := {} //Opções de rotina

ADD OPTION aRotina TITLE STR0003 ACTION 'VIEWDEF.TECA996' OPERATION 2 ACCESS 0 //"Visualizar"
ADD OPTION aRotina TITLE STR0004 ACTION 'VIEWDEF.TECA996' OPERATION 3 ACCESS 0 //"Incluir" 
ADD OPTION aRotina TITLE STR0005 ACTION 'VIEWDEF.TECA996' OPERATION 4 ACCESS 0 //"Alterar"
ADD OPTION aRotina TITLE STR0006 ACTION 'VIEWDEF.TECA996' OPERATION 5 ACCESS 0 //"Excluir"

Return aRotina

//------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Define o Modelo MVC
@sample 	ModelDef()
@param		Nenhum
@return	oModel, objeto, Modelo MVC
@since		08/10/2018
@author	Serviços
@version	12.1.17
/*/
//------------------------------------------------------------------------------
Static Function ModelDef()
Local oModel			:= NIL //Modelo MVC
Local oStruTX8 		:= FWFormStruct(1,"TX8") //Estrutura da Tabela
Local bPosValidacao	:= { |oMdl| Tkc996Pos( oMdl ) } //Bloco de PosValid do Modelo

	oModel := MPFormModel():New("TECA996",  ,bPosValidacao )
	oModel:SetDescription(STR0001) //"Cadastro de Configurações de Planilha"
	
	oModel:addFields('TECA996_MASTER',,oStruTX8)
	oModel:getModel('TECA996_MASTER'):SetDescription(STR0001) //'Cadastro de Configurações de Planilha'
	 
Return oModel


//------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Define a View MVC
@sample 	ViewDef()
@param		Nenhum
@return	oModel, objeto, View MVC
@since		08/10/2018
@author	Serviços
@version	12.1.17
/*/
//------------------------------------------------------------------------------
Static Function ViewDef()

Local oModel 		:= ModelDef() //Modelo MVC
Local oView		:= NIL //View MVC
Local oStruTX8	:= FWFormStruct(2, "TX8") //Estrutura da Tabela
	
	oView := FWFormView():New()
	oView:SetModel(oModel)

	oView:AddField('VIEW_TECA996' , oStruTX8,'TECA996_MASTER' ) 
	oView:CreateHorizontalBox( 'BOX_FORM_996', 100)
	oView:SetOwnerView('VIEW_TECA996','BOX_FORM_996')	
	
	oStruTX8:AddGroup( 'GRP_TECA996_001', 'Planilha', '', 2 )
	oStruTX8:AddGroup( 'GRP_TECA996_002', 'Configuração', '', 2 )
	oStruTX8:SetProperty( '*'         , MVC_VIEW_GROUP_NUMBER, 'GRP_TECA996_002' )
	oStruTX8:SetProperty( 'TX8_PLANIL' , MVC_VIEW_GROUP_NUMBER, 'GRP_TECA996_001' )
	oStruTX8:SetProperty( 'TX8_DPLAN' , MVC_VIEW_GROUP_NUMBER, 'GRP_TECA996_001' )
	oStruTX8:SetProperty( 'TX8_REGCX' , MVC_VIEW_GROUP_NUMBER, 'GRP_TECA996_001' )
	oStruTX8:SetProperty( 'TX8_ORCEX' , MVC_VIEW_GROUP_NUMBER, 'GRP_TECA996_001' )
	
Return oView


//------------------------------------------------------------------------------
/*/{Protheus.doc} Tkc996Pos
Função de Pós Validação do Modelo
@sample 	Tkc996Pos(oModel)
@param		oModel, objeto, modelo MVC
@return	lRet, Lógico, Modelo Válido
@since		08/10/2018
@author	Serviços
@version	12.1.17
/*/
//------------------------------------------------------------------------------
Static Function Tkc996Pos(oModel)

Local lRet 			:= .T. //Retorno Modelo válido
Local nOperacao 		:= oModel:GetOperation() //Operaco do Model
Local cMdlMaster 		:= "TECA996_MASTER" //Modelo Master
Local cProduto 		:= "" //Produto
Local cFuncao 		:= "" //Função
Local cTurno 			:= "" //Turno
Local cSeqTurno 		:= "" //Seq do Turno
Local cCargo 			:= "" //Cargo
Local cEscala 		:= "" //Escala
Local cPlanilha 		:= "" //Planilha
Local aAreaTX8 		:= {} //Workarea TX8
Local cChave 			:= "" //Chave de configuração

If nOperacao != MODEL_OPERATION_DELETE

	cProduto := oModel:GetValue( cMdlMaster, "TX8_PRODUT"  )
	cFuncao := oModel:GetValue( cMdlMaster, "TX8_FUNCAO"  )
	cTurno := oModel:GetValue( cMdlMaster, "TX8_TURNO"  )
	cSeqTurno := oModel:GetValue( cMdlMaster, "TX8_SEQTRN"  )
	cCargo := oModel:GetValue( cMdlMaster, "TX8_CARGO"  ) 
	cEscala := oModel:GetValue( cMdlMaster, "TX8_ESCALA"  )
	cPlanilha := oModel:GetValue( cMdlMaster, "TX8_PLANIL"  )
	cChave := cPlanilha + cProduto + cFuncao + cTurno + cSeqTurno + cCargo + cEscala
	
	/*If Empty(cChave)
		Help( ,, STR0007,, STR0008, 1, 0 ) //"Atenção"#"Pelo menos um campo de configuração da planilha deve ser informado"
		lRet := .F.		
	
	Else*/
		
		aAreaTX8 := TX8->(GetArea())	 
	
		//Valida se já existe a configuração de planilha
		If !ExistChav("TX8", cChave, 1)  //TX8_FILIAL + TX8_PRODUT + TX8_FUNCAO + TX8_TURNO + TX8_SEQTRN + TX8_CARGO + TX8_ESCALA
			Help( ,, STR0007,, STR0009, 1, 0 ) //"Atenção"##"Já existe a configuração de planilha"
			lRet := .F. 
	
		EndIf
		
		RestArea(aAreaTX8)
	//EndIf
EndIf
Return lRet 

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tkc996VlSeq
Valida a Sequencia do Turno
@since 08/10/2018
@version 12.1.17
@param oModel, objeto, MOdel do Orçamento de Serviços
@param cTurno, Caractere, Turno
@param cSeq , Caractere Sequencia
@return lRet, Sequencia do turno existente
/*/
//------------------------------------------------------------------------------

Function Tkc996VlSeq(cTno, cSeq)
Local lRet			:= .T. //Retorno da Rotina

Default cTno := ""
Default cSeq := ""

If  !Empty(cTno) .AND.  !Empty(cSeq) 

	
	If !Empty(cSeq)
		cFil	:= xFilial( "SPJ" , xFilial("SRA") )
		lRet := SPJ->( MsSeek( cFil + cTno + cSeq , .F. ) )
			
		If !lRet 
			Help( ' ' , 1 , 'SEQTURNINV' , , OemToAnsi( STR0010 ) , 1 , 0 ) //"Sequência não cadastrada para o turno"
		EndIf
	EndIf
EndIf

Return lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} Tkc996VlPr(cProduto)
Valida o Produto para que seja RH
@since 17/10/2018
@version 12.1.17
@param cProduto - Codigo do produto
@return lRet Produto válido
/*/
//------------------------------------------------------------------------------

Function Tkc996VlPr(cProduto)
Local aArea		:= NIL 
Local aAreaSB5	:= NIL
Local lRet			:= .T. //Retorno da Rotina

Default cProduto := M->TX8_PRODUT 
			
If !Empty(cProduto) 
 	aArea		:= GetArea() 
 	aAreaSB5	:= SB5->(GetArea() )
 	DbSelectArea('SB5')
 	SB5->( DbSetOrder( 1 ) ) //B5_FILIAL+B5_COD
 	If SB5->( DbSeek( xFilial('SB5')+cProduto ) .AND.  FIELD->B5_TPISERV != '4')
 		Help( ' ' , 1 , 'TKC996VLPR' , , OemToAnsi( STR0011 ) , 1 , 0 ) //"Produto deve ser do tipo Recurso Humano"
 		lRet := .F.
 	EndIf
	RestArea(aAreaSB5)
	RestArea(aArea)
EndIf


Return lRet
