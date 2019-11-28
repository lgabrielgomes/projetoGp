#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TECA931.CH"

STATIC lContra	:=	.F.
STATIC lSrvExt	:=	.F.
STATIC nOpcDA	:=	0

//------------------------------------------------------------------------------
/*/{Protheus.doc} TECA931
@description	Despesas Adicionais
@sample	 		TECA931()
@param			Nenhum
@return			NIL
@author			Adrianne Furtado (adrianne.andrade)
@since			21/07/2016
@version		P12   
/*/
//------------------------------------------------------------------------------
Function TECA931()

Local oMBrowse	:= FWmBrowse():New()
Local lAT931Leg	:= ExistBlock("AT931Leg")

oMBrowse:SetAlias("TWQ")			
oMBrowse:SetDescription(STR0001) //"Despesas Adicionais"		

If lAT931Leg
	ExecBlock("AT931Leg",.F.,.F.,{oMBrowse})
EndIf	

oMBrowse:AddLegend( "Empty(TWQ->TWQ_PEDIDO)" 		, "BR_VERDE"	, STR0002 ) //"Desp. Adicional não Apurada" 
oMBrowse:AddLegend( "!Empty(TWQ->TWQ_PEDIDO)" 		, "BR_VERMELHO"	, STR0003 ) //"Desp. Adicional Apurada"			



oMBrowse:Activate()

Return	NIL

//------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
@description	Define o menu funcional.
@sample	 		MenuDef()
@param			Nenhum
@return			ExpA: Opções da Rotina.
@author			Adrianne Furtado (adrianne.andrade)
@since			21/07/2016
@version		P12
/*/	
//------------------------------------------------------------------------------
Static Function MenuDef()    

Local	aRotina	:= {}
Local 	aRotAdic := {}

ADD OPTION aRotina TITLE STR0004 	ACTION "PesqBrw"         OPERATION 1                      ACCESS 0	// "Pesquisar"
ADD OPTION aRotina TITLE STR0005 	ACTION "VIEWDEF.TECA931" OPERATION MODEL_OPERATION_VIEW   ACCESS 0	// "Visualizar"
ADD OPTION aRotina TITLE STR0006	ACTION "At931GerDA" 	 OPERATION MODEL_OPERATION_INSERT ACCESS 0	// "Incluir"
ADD OPTION aRotina TITLE STR0007	ACTION "VIEWDEF.TECA931" OPERATION MODEL_OPERATION_UPDATE ACCESS 0	// "Alterar"
ADD OPTION aRotina TITLE STR0008	ACTION "VIEWDEF.TECA931" OPERATION MODEL_OPERATION_DELETE ACCESS 0	// "Excluir"

If ExistBlock("A931MNU")
	 aRotAdic := ExecBlock("A931MNU",.F.,.F.,{aRotina})
 If ValType(aRotAdic) == "A"
 	 AEval(aRotAdic,{|x| AAdd(aRotina,x)})
 EndIf
EndIf

Return(aRotina)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At931GerDA
Função para configuração de Fatura Separado
@sample 	At931GerDA()
@author		Fernando Alves Silva
@return		Nil 
@since		01/08/2017       
@version	P12  
/*/
//------------------------------------------------------------------------------
Function At931GerDA(cAlias, nReg, nOpc)
Local nOperacao  := MODEL_OPERATION_INSERT
Local lIncAlt	 := INCLUI .OR. ALTERA  

If lIncAlt 
	nOpcDA:= 	GSEscolha( 	STR0009								,;  //"Tipo de Vinculo"	
							STR0010								,;  //"Selecione o tipo de vinculo de Despesa Adicional"                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
						 	{STR0011, STR0012 }					,;  //"Contrato Normal"#"Orçamento Serv. Extra"
							1) 
Endif

Do Case
	Case nOpcDA == 1
		lContra := .T.
		lSrvExt := .F.	
	Case nOpcDA == 2
		lSrvExt := .T.		
		lContra := .F.	
EndCase

If !(lIncAlt .And. nOpcDA == 0) .Or. !lIncAlt  
	MsgRun( STR0013, STR0014, {|| FWExecView(STR0015,"VIEWDEF.TECA931",nOperacao,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/) } )  //"Processando Despesas Adicionais" # "Aguarde..." # "Geração"
EndIf

Return(Nil)

//------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
@description	Definição do Model
@sample	 		ModelDef()
@param			Nenhum
@return			ExpO: Objeto FwFormModel
@author			Adrianne Furtado (adrianne.andrade)
@since			21/07/2016
@version		P12
/*/
//------------------------------------------------------------------------------
Static Function ModelDef()

Local	oModel		:= Nil
Local	oStrTWQ 	:= FWFormStruct(1, "TWQ")	// TWQ - "Despesas Adicionais"
Local 	aAux	:=	{}

aAux := FwStruTrigger("TWQ_CONTRT","TWQ_POSTRH","''",.F.,Nil,Nil,Nil)
oStrTWQ:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TWQ_CONTRT","TWQ_POSTLE","''",.F.,Nil,Nil,Nil)
oStrTWQ:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TWQ_ORCEXT","TWQ_POSTRH","''",.F.,Nil,Nil,Nil)
oStrTWQ:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TWQ_ORCEXT","TWQ_POSTLE","''",.F.,Nil,Nil,Nil)
oStrTWQ:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

oModel := MPFormModel():New("TECA931A", , {|oModel| At931TdOk(oModel)}, /*bCommit*/, /*bCancel*/)				// Cria o objeto do modelo de dados principal

oModel:AddFields("TWQMASTER", /*cOwner*/ , oStrTWQ )							

oStrTWQ:SetProperty("TWQ_TIPO" ,MODEL_FIELD_WHEN, {||.F.} )

oStrTWQ:SetProperty("TWQ_ORCEXT"	,MODEL_FIELD_OBRIGAT, .F.)
oStrTWQ:SetProperty("TWQ_CONTRT"	,MODEL_FIELD_OBRIGAT, .F.)
oStrTWQ:SetProperty("TWQ_CATEND"	,MODEL_FIELD_OBRIGAT, .F.)
oStrTWQ:SetProperty("TWQ_NATEND"	,MODEL_FIELD_OBRIGAT, .F.)
		
oModel:SetVldActivate( {|oModel,cAction| At931PrVal(oModel)} )

Return(oModel)



//------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
@description	Definição da View
@sample	 		ViewDef()
@param			Nenhum
@return			ExpO: Objeto FwFormView
@author			Adrianne Furtado (adrianne.andrade)
@since			21/07/2016
@version		P12
/*/
//------------------------------------------------------------------------------
Static Function ViewDef()

Local oView		:= Nil								// Interface de visualização construída	
Local oModel	:= ModelDef()						// Cria um objeto de Modelo de dados baseado no ModelDef do fonte informado
Local oStrTWQ	:= FWFormStruct(2, "TWQ")			// Cria a estrutura a ser usada na View

oView	:= FWFormView():New()						// Cria o objeto de View
oView:SetModel(oModel)								// Define qual modelo de dados será utilizado

oView:AddField("VIEW_TWQ", oStrTWQ, "TWQMASTER")	// Adiciona ao nosso View um controle do tipo formulário (antiga Enchoice)

// Identificação (Nomeação) da VIEW
oView:SetDescription(STR0001)		// "Despesas Adicionais"

oView:SetAfterViewActivate({|oView| oView:Refresh() }) 


Return(oView)


//-------------------------------------------------------------------
/*/{Protheus.doc} At931TdOk
@description	Validação final do Model, antes da gravação
@sample	 		At931TdOk(oModel)
@param			oModel		Model
@return			ExpL	.T.=Gravação permitida, .F.=Gravação não permitida
@author			Adrianne Furtado   
@since			25/07/2016
@version		P12
/*/
//------------------------------------------------------------------
Function At931TdOk(oModel)

Local aOldAlias	:= If( !( Empty(Alias()) ), (Alias())->(GetArea()), {})
Local oTWQMASTER	:= oModel:GetModel("TWQMASTER")
Local lRet			:= .T.
Local dDataIni		:= ""
Local dDataFin		:= ""

If Empty(oTWQMASTER:GetValue("TWQ_POSTRH")) .AND. Empty(oTWQMASTER:GetValue("TWQ_POSTLE"))
	Help(" ",1,"HELP", , STR0016, 3, 1 ) // "É necessario informar o posto."
	lRet := .F.
EndIf

If lRet 
	If oTWQMASTER:GetValue("TWQ_TIPO") == '1' 
		If Empty(oTWQMASTER:GetValue("TWQ_CONTRT"))
			Help(" ",1,"HELP", , STR0018, 3, 1 ) //"É necessário informar o Contrato."
			lRet := .F.
		ElseIf  !Empty(oTWQMASTER:GetValue("TWQ_ORCEXT"))
			Help(" ",1,"HELP", , STR0019, 3, 1 ) //"Para este tipo de vínculo não permitido informar um número de contrato."
			lRet := .F.
		//Elseif !At931VlMd(oTWQMASTER:GetValue("TWQ_TIPO"),oTWQMASTER:GetValue("TWQ_CONTRT"),oTWQMASTER:GetValue("TWQ_DATA"))
			//Help(" ",1,"HELP", , STR0020, 3, 1 ) //"A medição do contrato já foi realizada, não é possível prosseguir com a operação."
			//lRet := .F.
		Elseif !Empty(oTWQMASTER:GetValue("TWQ_DATA"))
			If !Empty(oTWQMASTER:GetValue("TWQ_POSTRH"))
				dDataIni := POSICIONE("TFF",1,xFilial("TFF") + M->TWQ_POSTRH, "TFF_PERINI" )
				dDataFin := POSICIONE("TFF",1,xFilial("TFF") + M->TWQ_POSTRH, "TFF_PERFIM" )
				 If oTWQMASTER:GetValue("TWQ_DATA") < dDataIni 
					Help(" ",1,"HELP", , STR0021, 3, 1 ) //"A data inserida é menor do que a data de vigencia do recurso humano."
					lRet := .F.
				 Elseif oTWQMASTER:GetValue("TWQ_DATA") > dDataFin
				 	Help(" ",1,"HELP", , STR0022, 3, 1 ) //"A data inserida é maior do que a data de vigencia do recurso humano."
					lRet := .F.
				 Endif
			Elseif !Empty(oTWQMASTER:GetValue("TWQ_POSTLE"))	
				dDataIni := POSICIONE("TFI",1,xFilial("TFI") + M->TWQ_POSTLE, "TFI_PERINI" )
				dDataFin := POSICIONE("TFI",1,xFilial("TFI") + M->TWQ_POSTLE, "TFI_PERFIM" )
				 If oTWQMASTER:GetValue("TWQ_DATA") < dDataIni
					Help(" ",1,"HELP", , STR0023, 3, 1 ) //"A data inserida é menor do que a data de vigencia da locação de equipamento."
					lRet := .F.
				 Elseif oTWQMASTER:GetValue("TWQ_DATA") > dDataFin
				 	Help(" ",1,"HELP", , STR0024, 3, 1 ) //"A data inserida é maior do que a data de vigencia da locação de equipamento."
					lRet := .F.
				 Endif
			Endif
		EndIf 
	Else
		If Empty(oTWQMASTER:GetValue("TWQ_ORCEXT"))
			Help(" ",1,"HELP", , STR0025, 3, 1 ) //"É necessário informar o número do Orçamento de Serviço Extra."
			lRet := .F.
		ElseIf  !Empty(oTWQMASTER:GetValue("TWQ_CONTRT"))
			Help(" ",1,"HELP", , STR0026, 3, 1 ) //"Para este tipo de vínculo não permitido informar um número de Orçamento de Serviço Extra."
			lRet := .F.
		//Elseif !At931VlMd(oTWQMASTER:GetValue("TWQ_TIPO"),oTWQMASTER:GetValue("TWQ_ORCEXT"),oTWQMASTER:GetValue("TWQ_DATA"))
			//Help(" ",1,"HELP", , STR0027, 3, 1 ) //"A medição do orçamento de serviço extra já foi realizada, não é possível prosseguir com a operação."
			//lRet := .F.
		EndIf
		If !Empty(oTWQMASTER:GetValue("TWQ_POSTRH"))
			dDataIni := POSICIONE("TFF",1,xFilial("TFF") + M->TWQ_POSTRH, "TFF_PERINI" )
			dDataFin := POSICIONE("TFF",1,xFilial("TFF") + M->TWQ_POSTRH, "TFF_PERFIM" )
			 If oTWQMASTER:GetValue("TWQ_DATA") < dDataIni 
				Help(" ",1,"HELP", , STR0028, 3, 1 ) //"A data inserida é menor do que a data de vigencia do recurso humano."
				lRet := .F.
			 Elseif oTWQMASTER:GetValue("TWQ_DATA") > dDataFin
			 	Help(" ",1,"HELP", , STR0029, 3, 1 ) //"A data inserida é maior do que a data de vigencia do recurso humano."
				lRet := .F.
			 Endif
		Elseif !Empty(oTWQMASTER:GetValue("TWQ_POSTLE"))	
			dDataIni := POSICIONE("TFI",1,xFilial("TFI") + M->TWQ_POSTLE, "TFI_PERINI" )
			dDataFin := POSICIONE("TFI",1,xFilial("TFI") + M->TWQ_POSTLE, "TFI_PERFIM" )
			 If oTWQMASTER:GetValue("TWQ_DATA") < dDataIni
				Help(" ",1,"HELP", , STR0030, 3, 1 ) //"A data inserida é menor do que a data de vigencia da locação de equipamento."
				lRet := .F.
			 Elseif oTWQMASTER:GetValue("TWQ_DATA") > dDataFin
			 	Help(" ",1,"HELP", , STR0031, 3, 1 ) //"A data inserida é maior do que a data de vigencia da locação de equipamento."
				lRet := .F.
			 Endif
		 Endif
	EndIf
EndIf 

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At931PrVal
@description	Pré Validação de Ativação do Modelo
@sample	 		At931PrVal()
@author			Fernando Alves Silva
@since			03/02/2016
@version		P12   
/*/
//------------------------------------------------------------------------------

Function At931PrVal(oModel)

Local oTWQMASTER	:= oModel:GetModel("TWQMASTER")
Local oStruTWQ	 	:= oModel:GetModel('TWQMASTER'):GetStruct()
Local lRet			:= .T.

If oModel:GetOperation() == MODEL_OPERATION_UPDATE .or. oModel:GetOperation() == MODEL_OPERATION_DELETE  
	If !Empty(TWQ->TWQ_PEDIDO)
		Help(" ",1,"AT931PRVAL", ,STR0032, 3, 1 ) //"Não é possóvel Alterar\Excluir esta despesa, pois a mesma já foi apurada. "
		lRet := .F.		
	EndIf
EndIf

If oModel:GetOperation() == MODEL_OPERATION_INSERT

	If lSrvExt
		oStruTWQ:SetProperty("TWQ_ORCEXT" 	,MODEL_FIELD_WHEN, {||.T.} )
		oStruTWQ:SetProperty("TWQ_CONTRT" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruTWQ:SetProperty("TWQ_CONREV" 	,MODEL_FIELD_WHEN, {||.F.} )
		
		oStruTWQ:SetProperty("TWQ_ORCEXT", MODEL_FIELD_OBRIGAT, .T.)
		oStruTWQ:SetProperty("TWQ_CONTRT", MODEL_FIELD_OBRIGAT, .F.)

	Else
		oStruTWQ:SetProperty("TWQ_ORCEXT" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruTWQ:SetProperty("TWQ_CONTRT" 	,MODEL_FIELD_WHEN, {||.T.} )
		oStruTWQ:SetProperty("TWQ_CONREV" 	,MODEL_FIELD_WHEN, {||.T.} )
		
		oStruTWQ:SetProperty("TWQ_ORCEXT", MODEL_FIELD_OBRIGAT, .F.)
		oStruTWQ:SetProperty("TWQ_CONTRT", MODEL_FIELD_OBRIGAT, .T.)

	Endif
	
	oStruTWQ:SetProperty("TWQ_TIPO"	,MODEL_FIELD_INIT,{|| nOpcDA })

Elseif oModel:GetOperation() == MODEL_OPERATION_UPDATE

	If !Empty(TWQ->TWQ_ORCEXT)
		oStruTWQ:SetProperty("TWQ_ORCEXT" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruTWQ:SetProperty("TWQ_CONTRT" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruTWQ:SetProperty("TWQ_CONREV" 	,MODEL_FIELD_WHEN, {||.F.} )
		
		oStruTWQ:SetProperty("TWQ_ORCEXT", MODEL_FIELD_OBRIGAT, .T.)
		oStruTWQ:SetProperty("TWQ_CONTRT", MODEL_FIELD_OBRIGAT, .F.)

	ElseIf !Empty(TWQ->TWQ_CONTRT)
		oStruTWQ:SetProperty("TWQ_ORCEXT" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruTWQ:SetProperty("TWQ_CONTRT" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruTWQ:SetProperty("TWQ_CONREV" 	,MODEL_FIELD_WHEN, {||.F.} )
		
		oStruTWQ:SetProperty("TWQ_ORCEXT", MODEL_FIELD_OBRIGAT, .F.)
		oStruTWQ:SetProperty("TWQ_CONTRT", MODEL_FIELD_OBRIGAT, .T.)

	Endif	
	oStruTWQ:SetProperty("TWQ_TIPO"	,MODEL_FIELD_INIT,{|| nOpcDA })
EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At931Fil
@description	Função utilizada pela consulta padrão TFF para condicionar o 
				filtro de acordo com o tipo de Despesa Adicional 
@sample	 		At931Fil()
@author			Fernando Alves Silva
@since			15/02/2016
@version		P12   
/*/
//------------------------------------------------------------------------------
Function At931Fil()

Local cFilter	:= ""
Local cTFF		:= ""
Local aTFL		:= {}
Local aSaveTFL	:= TFL->(GetArea())
Local aSaveTFF	:= TFF->(GetArea())
Local i			:= 0

If M->(TWQ_TIPO) == '1'
	cFilter:= "@#TFF->(TFF_CONTRT) == '" + M->(TWQ_CONTRT) + "' .AND. TFF->(TFF_CONREV) == '" + M->(TWQ_CONREV) + "'@#"
Else
	DbSelectArea("TFL")
	TFL->(DbGotop())
	DbSetOrder(2)
	If DbSeek(xFilial("TFL")+M->(TWQ_ORCEXT))
		While TFL->(!Eof()) .And. TFL->TFL_CODPAI == M->(TWQ_ORCEXT)
			aAdd(aTFL,TFL->TFL_CODIGO)	
		TFL->(DbSkip())
		Enddo
	EndIf
	
	For i := 1 to Len(aTFL)
		DbSelectArea("TFF")
		TFF->(DbGotop())
		DbSetOrder(3)
		If DbSeek(xFilial("TFF")+aTFL[i])
			While TFF->(!Eof()) .And. TFF->TFF_CODPAI == aTFL[i]
				cTFF+= TFF->TFF_COD + "|"
				TFF->(DbSkip())
			EndDo
		EndIf
	Next i  
	cFilter:= "@#TFF->(TFF_COD) $ '" + cTFF + "'@#" 
EndIf

RestArea(aSaveTFL)
RestArea(aSaveTFF)

Return(cFilter) 

//------------------------------------------------------------------------------
/*/{Protheus.doc} At931VlMd
@description	Validação para verificar se a medição já foi realizada.

@sample	 		At931VlMd()
@author			Kaique Schiller
@since			07/11/2017
@version		P12   
/*/
//------------------------------------------------------------------------------
Static Function At931VlMd(cTipo,cNum,dData)
Local lRet 			:= .T.
Local cAliasTFV 	:= GetNextAlias()

If cTipo == "1"
	cWhere := "% TFV.TFV_CONTRT ='" + cNum + "' %"
Elseif cTipo == "2"
	cWhere := "% TFV.TFV_ORCSRV ='" + cNum + "' %"
Endif

BeginSQL Alias cAliasTFV
	COLUMN TFV_DTINI AS DATE
	COLUMN TFV_DTFIM AS DATE
	SELECT TFV.R_E_C_N_O_ TFVRECNO, TFV_ANTECI, TFV_CODIGO
	FROM %Table:TFV% TFV 
	WHERE TFV_FILIAL = %xFilial:TFV%
		AND TFV_DTINI <= %Exp:dData%
		AND TFV_DTFIM >= %Exp:dData%
		AND %Exp:cWhere%
		AND TFV.%NotDel%
EndSQL

If (cAliasTFV)->(!Eof())
	If (cAliasTFV)->TFV_ANTECI == "1"	
      	lRet := A931VlABX((cAliasTFV)->TFV_CODIGO ,dData)
	Else
		lRet := .F.
	EndIf
Endif

(cAliasTFV)->(DbCloseArea())

Return lRet
//------------------------------------------------------------------------------
/*/{Protheus.doc} At931When
@description	Validação nos campos TWQ_POSTRH e TWQ_POSTLE para liberar edição.

@sample	 		At931When()
@author			Leandro Fini
@since			16/11/2017
@version		P12   
/*/
//------------------------------------------------------------------------------
Function At931When()
Local lRet := .F.

If !Empty(M->TWQ_CONTRT) .OR. !Empty(M->TWQ_ORCEXT) 
	lRet := .T.
Endif

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} Gt931Rev
@description	Gatilho para revisão do contrato.

@sample	 		At931When()
@author			Leandro Fini
@since			24/11/2017
@version		P12   
/*/
//------------------------------------------------------------------------------
Function Gt931Rev()
Local cRet := ""
Local cAliasCN9 := GetNextAlias()

	BeginSql alias cAliasCN9
	
		SELECT MAX(CN9_REVISA) REVISAO
		FROM %Table:CN9% CN9
		WHERE CN9_NUMERO = %exp:M->TWQ_CONTRT%
		AND CN9_FILIAL = %exp:xFilial("TWQ")%
		AND CN9.%NotDel% 

	EndSql
	
If !Empty((cAliasCN9)->REVISAO)
	cRet := (cAliasCN9)->REVISAO
Endif
(cAliasCN9)->(DbCloseArea())
Return cRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} A931VlABX
@description	Validação a data da ultima apuração do faturamento antecipado

@sample	 		A931VlABX()
@author			Pâmela Bernardo
@since			11/04/18
@version		P12   
/*/
//------------------------------------------------------------------------------
Static Function A931VlABX(cNumTFV,dData)
	Local lRet 			:= .T.
	Local cAliasABX		:= GetNextAlias()

	BeginSql alias cAliasABX
	
		SELECT MAX(ABX_CODIGO) CODIGO
		FROM %Table:ABX% ABX
		WHERE ABX_DTINAP <= %exp:dData%
		AND ABX_DTFMAP >= %exp:dData%
		AND ABX.%NotDel% 

	EndSql
	
	If !Empty((cAliasABX)->CODIGO)
		lRet := .F.
	Endif
	(cAliasABX)->(DbCloseArea())

Return lRet