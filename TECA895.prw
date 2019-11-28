#Include 'Protheus.ch'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TECA895.CH'

Static oModel		:= nil
Static lGrava		:= .F.
Static cCodAtivo	:= ""

//-----------------------------------------------------------------
/*/{Protheus.doc} TECA895()
Itens Intercambiaveis
@sample 	TECA895()
@since		02/09/2016
@author	Francisco Oliveira
@version 	P12
@return 	cRet, Caractere
/*/
//-----------------------------------------------------------------
Function TECA895()
	
	Local oBrowse := FWmBrowse():New()
	
	oBrowse:SetAlias('TWY')
	oBrowse:SetDescription(STR0001)
	oBrowse:Activate()
	
Return Nil

//-----------------------------------------------------------------
/*/{Protheus.doc} MenuDef()
Rotina para construção do menu
@sample 	MenuDef()
@author	Francisco Oliveira
@since		02/09/2016
@version	P12
@Return	aRotina: Objeto com todas as opções inseridas no menu.
/*/
//-----------------------------------------------------------------
Static Function MenuDef()
	
	Local aRotina := {}
	
	ADD OPTION aRotina TITLE STR0002 ACTION 'VIEWDEF.TECA895' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE STR0003 ACTION 'VIEWDEF.TECA895' OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE STR0004 ACTION 'VIEWDEF.TECA895' OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE STR0005 ACTION 'VIEWDEF.TECA895' OPERATION 5 ACCESS 0
	
Return aRotina

//-----------------------------------------------------------------
/*/{Protheus.doc} ModelDef()
Rotina para construção da Model
@sample 	ModelDef()
@author	Francisco Oliveira
@since		02/09/2016
@version	P12
@Return	Objeto com a Model em execução
/*/
//-----------------------------------------------------------------
Static Function ModelDef()
	
	Local oStruTWY	:= FWFormStruct( 1, 'TWY', {|cCampo|  ( Alltrim( cCampo )$"|TWY_CODPRO|TWY_DESPRO|TWY_ATIVO|")})
	Local oStruDET	:= FWFormStruct( 1, 'TWY', {|cCampo| !( Alltrim( cCampo )$"|TWY_CODPRO|TWY_DESPRO|TWY_ATIVO|")})
	Local bPos 		:= {|oModel| AT895VldPos(oModel)} //bPosValidacao
	Local bPreVal 	:= {|oMdlG,nLine,cAcao,cCampo,xValor| At895PreVl( oMdlG,nLine,cAcao,cCampo,xValor ) }
	Local bTudoOk 	:= {|oModel| At895TdOk( oModel ) }
	Local bCommit 	:= {|oModel| At895Cmt(oModel)}
	
	oModel := MPFormModel():New( 'TECA895',/*bPreValidacao*/, bTudoOk/*bPosValidacao*/, bCommit, /*bCancel*/ )
	
	oModel:AddFields( 'TWYMASTER', /*cOwner*/, oStruTWY )
	oModel:AddGrid( 'TWYDETAIL', 'TWYMASTER', oStruDET, bPreVal, bPos )
	
	oModel:SetRelation('TWYDETAIL',{{"TWY_FILIAL","xFilial('TWY')"},{"TWY_CODPRO", "TWY_CODPRO"}},TWY->(IndexKey(1)))
	
	oModel:GetModel("TWYDETAIL"):SetUniqueLine({"TWY_CODINT"})
	
	oModel:GetModel("TWYDETAIL"):SetOptional(.T.)
	
	oModel:SetDescription(STR0006)
	
	oModel:SetPrimaryKey( { "TWY_FILIAL", "TWY_CODPRO", "TWY_CODINT" } )
	
Return oModel

//-----------------------------------------------------------------
/*/{Protheus.doc} Viewdef()
Rotina para construção da Model
@sample 	Viewdef()
@author	Francisco Oliveira
@since		02/09/2016
@version	P12
@Return	oView: Objeto com todos os campos para a criação da tela
/*/
//-----------------------------------------------------------------
Static Function Viewdef()

	Local oModel   := ModelDef()
	Local oStruTWY := FWFormStruct( 2, 'TWY', {|cCampo|  ( Alltrim( cCampo )$"|TWY_CODPRO|TWY_DESPRO|TWY_ATIVO|")})
	Local oStruDET := FWFormStruct( 2, 'TWY', {|cCampo| !( Alltrim( cCampo )$"|TWY_CODPRO|TWY_DESPRO|TWY_ATIVO|")})
	Local oView    := FWFormView():New()
	
	oView:SetModel( oModel )
	
	oView:AddField('VIEW_TWY',oStruTWY,'TWYMASTER')
	oView:AddGrid('VIEW_DET',oStruDET,'TWYDETAIL' )
	
	oView:CreateHorizontalBox('SUPERIOR',25)
	oView:CreateHorizontalBox('INFERIOR',75)
	
	oView:SetOwnerView('VIEW_TWY','SUPERIOR')
	oView:SetOwnerView('VIEW_DET','INFERIOR')
	
	oView:AddIncrementField( 'VIEW_DET', 'TWY_ITEM' )
	
Return oView

//-----------------------------------------------------------------
/*/{Protheus.doc} AT895VldPos(oModel)
Função que valida se o produto do cabeçalho não esta na Grid.
@sample 	Viewdef()
@author	Francisco Oliveira
@since		02/09/2016
@version	P12
@Return	lRet: Retorna se o registro do código atual foi localizado na tabela SE1 para alteração.
/*/
//-----------------------------------------------------------------
Static Function AT895VldPos(oModel)

	Local lRet			:= .T.
	Local cCodProd	:= FwFldGet("TWY_CODPRO")
	
	If Alltrim(FwFldGet("TWY_CODINT")) == Alltrim(cCodProd)
		Aviso(STR0007,STR0008,{"Ok"}, 3)
		lRet	:= .F.
	Endif
	
Return lRet

/*/{Protheus.doc} At895PreVl
	Valida o tipo de produto inserido no cadastro

@author		josimar.assuncao
@since		16.11.2016
@version	P12
@param 		oMdlG, Objeto FwFormGridModel, grid sendo validado
@param 		nLine, Numérico, número da linha sendo validada 
@param 		cAcao, Caracter, ação em operação no campo/linha
@param 		cCampo, Caracter, campo sendo validado
@return		Lógico, determina se a operação deve prosseguir ou não
/*/
Static Function At895PreVl(oMdlG,nLine,cAcao,cCampo,cConteudo)
Local lRet := .T.
Local lMatImplant := .F.
Local lMatConsumo := .F.

Default cAcao := ""
Default cCampo := ""

DbSelectArea("SB1")
SB1->( DbSetOrder( 1 ) ) // B1_FILIAL + B1_COD

If cAcao == "SETVALUE" .And. cCampo == "TWY_CODINT" .And. SB1->( DbSeek(xFilial("SB1")+cConteudo) )
	
	lMatImplant := Posicione("SB5", 1, xFilial("SB5")+cConteudo,"B5_GSMI" ) == "1"
	lMatConsumo := Posicione("SB5", 1, xFilial("SB5")+cConteudo,"B5_GSMC" ) == "1"
	
	If (!lMatImplant .And. !lMatConsumo)
		lRet := .F.
		Help( , , "AT895PREVL_01", ,STR0009, 1, 0,,,,,,;  // "Produto não pode ser selecionado pois não está definido como material de implantação ou consumo."
		 			{STR0010})  // "Selecione um produto que esteja definido como Material de Implantação ou Material de Consumo no cadastro de Complemento de Produtos."
	EndIf
EndIf

Return lRet

/*/{Protheus.doc} At895TdOk
	Valida se o produto inserido no cabeçalho corresponde a um produto com configuração para material de implantação ou consumo

@author		josimar.assuncao
@since		16.11.2016
@version	P12
@param 		oModel, Objeto FwFormModel/MpFormModel, objeto principal do modelo de dados MVC
@return		Lógico, determina se a operação deve prosseguir ou não
/*/
Static Function At895TdOk( oModel )
Local lRet := .T.
Local oMdlCab := oModel:GetModel("TWYMASTER")
Local cPrdCab := oMdlCab:GetValue("TWY_CODPRO")
Local lMatImplant := .F.
Local lMatConsumo := .F.

If !Empty( cPrdCab )
	
	lMatImplant := Posicione("SB5", 1, xFilial("SB5")+cPrdCab,"B5_GSMI" ) == "1"
	lMatConsumo := Posicione("SB5", 1, xFilial("SB5")+cPrdCab,"B5_GSMC" ) == "1"
	
	If (!lMatImplant .And. !lMatConsumo)
		lRet := .F.
		Help( , , "AT895TDOK_01", ,STR0009, 1, 0,,,,,,;  // "Produto não pode ser selecionado pois não está definido como material de implantação ou consumo."
		 			{STR0010} )  // "Selecione um produto que esteja definido como Material de Implantação ou Material de Consumo no cadastro de Complemento de Produtos."
	EndIf	
EndIf

Return lRet

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At895Cmt
Commit do modelo de dados

@return lRetorno, Logico, Retorna .T. se o modelo foi gravado corretamente

@author Luiz Gabriel Gomes de Jesus
@since 11/10/2018
/*/
//------------------------------------------------------------------------------------------
Function At895Cmt(oModel)
Local oMdlMaster	:= oModel:GetModel("TWYMASTER")
Local aCampos 	:= At890FldUpd(oMdlMaster)
Local bAfterSTTS	:= {|oModel|At895Grava(oModel)} //Realiza a gravação dos campos de Ativo
Local nX			:= 0

For nX := 1 To Len(aCampos)
	If aCampos[nX] == "TWY_ATIVO"
		lGrava := .T.
	EndIf
	cCodAtivo	:= oMdlMaster:GetValue("TWY_ATIVO")
Next nX

lRetorno := FWFormCommit(oModel,/*bBefore*/, /*bAfter*/, bAfterSTTS , /*bInTTS*/, /*bABeforeTTS*/, /*bIntegEAI*/)
	
Return( lRetorno )

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At895Grava
Realiza a gravação do campo ativo nos itens

@return lRetorno, Logico, Retorna .T. se o modelo foi gravado corretamente

@author Luiz Gabriel Gomes de Jesus
@since 11/10/2018
/*/
//------------------------------------------------------------------------------------------
Function At895Grava(oModel)
Local lRet		:= .T.
Local aArea	:= GetArea()
Local oMdl		:= oModel:GetModel("TWYDETAIL")
Local nY		:= 0

DbSelectArea("TWY")
TWY->(DbSetOrder(1))

If lGrava
	For nY := 1 To oMdl:Length()
		oMdl:GoLine(nY)
		If TWY->(DbSeek(xFilial("TWY")+FwFldGet("TWY_CODPRO")+FwFldGet("TWY_CODINT")+FwFldGet("TWY_ITEM")))
			Reclock("TWY",.F.)
				TWY->TWY_ATIVO := cCodAtivo
			TWY->(MsUnlock())
		EndIf
	Next nY
EndIf

lGrava := .F.
RestArea(aArea)

Return lRet