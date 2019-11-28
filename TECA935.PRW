#INCLUDE "PROTHEUS.CH" 
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TECA935.CH"

Static dVgIniCtrt		// Data inicial a ser considerada como vigência do contrato/orçamento de serviços
Static dVgFimCtrt		// Data final a ser considerada como vigência do contrato/orçamento de serviços
Static dDtGeraIni		// Data inicial da data gerada
Static dDtGeraFim		// Data final da data gerada 
Static cXML			//Variavel para o XML
Static lValido	:= .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} TECA935
@description	Regime de Caixa
@sample	 	TECA935() 
@param			Não há
@since			06/04/2017
@author	 	Luiz Gabriel Gomes de Jesus (luiz.jesus)
@version		P12.1.17  
@return		NIL
/*/
//------------------------------------------------------------------------------
Function TECA935()

Local oBrw		:= FwMBrowse():New()

dVgIniCtrt		:= CtoD(Space(08))	// Força a inicialização da variável que controlará a data inicial de vigência do contrato/orçamento de serviços
dVgFimCtrt		:= CtoD(Space(08))	// Força a inicialização da variável que controlará a data final de vigência do contrato/orçamento de serviços
cXML			:= ""					// Força a inicialização da variável que controlará a estrutura XML dos cálculos das planilhas de precificação utilizadas no regime de caixa

oBrw:SetAlias("T45")
oBrw:SetMenudef("TECA935")
oBrw:SetDescription(OemToAnsi(STR0001)) //"Regime de Caixa"

oBrw:AddLegend("T45->T45_STATUS == '1'", "GREEN", STR0002)	//"Ativo"
oBrw:AddLegend("T45->T45_STATUS == '2'", "RED",   STR0003)	//"Pedido gerado"

oBrw:Activate()
Return


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
@description	Definição do MenuDef
@sample	 	MenuDef()
@param			Não há
@since			06/04/2017
@author	 	Luiz Gabriel Gomes de Jesus (luiz.jesus)
@version		P12.1.17  
@return		aRotina
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function MenuDef()
Local nPos			:= 0
Local aRotina		:= FWMVCMenu("TECA935")

aAdd(aRotina, {STR0004, "At935Pedido()", 0, 7, 0, NIL}) //"Gerar pedido"
aAdd(aRotina, {STR0061, "At935Estorna()", 0, 7, 0, NIL}) //"Estornar pedido"

//Retira a copia do Menu
nPos := ASCAN(aRotina, { |x|  x[1] == "Copiar" })
If nPos > 0 
	Adel(aRotina,nPos)
	Asize(aRotina,Len(aRotina)-1)
EndIf

Return aRotina


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
@description	Definição do Model
@sample	 	ModelDef()
@param			Não há
@since			06/04/2017
@author	 	Luiz Gabriel Gomes de Jesus (luiz.jesus)
@version		P12.1.17  
@return		ExpO:oModel
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ModelDef()
Local oStruT45	:= FWFormStruct(1, "T45")		//Cabeçalho do Regime de Caixa
Local oStruT46	:= FWFormStruct(1, "T46")		//Atendentes
Local oStruT47	:= FWFormStruct(1, "T47")		//Item para calculo

//Instancia o cadastro de Regime de Caixa
oModel := MPFormModel():New("TECA935",;
                            /*<bPreValidacao>*/,;
                            {|| At935Valid("TUDOOK")}/*<bPosVld>*/,;
                            /*<bCommit>*/,;
                            /*<bCancel>*/)

//Instancia o cabeçalho do Regime de Caixa
oModel:AddFields("T45MASTER"/*<cId>*/,;
                 /*<cOwner>*/,;
                 oStruT45/*<oModelStruct>*/,;
                 /*<bPreValidacao>*/,;
                 /*<bPosValidacao>*/,;
                 /*<bCarga>*/,;
                 /*<bFieldAbp>*/)

//Instancia o Grid de Atendentes
oModel:AddGrid("T46ATEND"/*<cId>*/,;
               "T45MASTER"/*<cOwner>*/,;
               oStruT46/*<oModelStruct>*/,;
               /*<bLinePre>*/,;
               /*<bLinePos>t*/,;
               /*<bPreVal>*/,;
               /*<bPosVal>*/,;
               /*<bLoad>*/)

//Instancia o Grid dos Itens
oModel:AddGrid("T47ITEM"/*<cId>*/,;
               "T46ATEND"/*<cOwner>*/,;
               oStruT47/*<oModelStruct>*/,;
               {|oMdlT47, nLine, cAcao, cCampo| PrLinOkT47(oMdlT47, nLine, cAcao, cCampo)}/*<bLinePre>*/,;
               /*<bLinePos>*/,;
               /*<bPreVal>*/,;
               /*<bPosVal>*/,;
               /*<bLoad>*/)

//Realiza o relacionamento entre o cabeçalho e os atendente
oModel:SetRelation("T46ATEND", {{"T46_FILIAL","xFilial('T46')"}, {"T46_CODIGO","T45_CODIGO"}}, T46->( IndexKey(1)))

//Realiza o relacionamento entre os atendentes e os itens
oModel:SetRelation("T47ITEM", {{"T47_FILIAL","xFilial('T47')"}, {"T47_CODIGO","T45_CODIGO"}, {"T47_CODTEC","T46_CODTEC"}, {"T47_ITEM","T46_ITEM"}}, T47->( IndexKey(1)))

//Adiciona o campo para receber a imagem para o botão calcular
oStruT47:AddField(" ", "", "BTNCALC", "C", 10, 0, {||.T.}, NIL, {}, NIL, FwBuildFeature(STRUCT_FEATURE_PICTVAR, "'BTCALC_MDI'"), NIL, NIL, .F.)

//Desabilita o Grid de Atendentes para Edição
oModel:GetModel("T46ATEND"):SetNoInsertLine(.T.)
oModel:GetModel("T46ATEND"):SetNoDeleteLine(.T.)
oModel:GetModel("T46ATEND"):SetNoUpdateLine(.T.)

//Retira a obrigatoriedade do grid dos itens
oModel:GetModel("T47ITEM"):SetOptional(.T.)

oModel:SetVldActivate( {|oModel| AT935VldCt(oModel)} )

Return(oModel)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
@description	Definição da View
@sample	 	ViewDef()
@param			Não há
@since			06/04/2017
@author	 	Luiz Gabriel Gomes de Jesus (luiz.jesus)    
@version		P12.1.17  
@return		ExpO:oView
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ViewDef()

Local oView
Local oModel   	:= FWLoadModel("TECA935")
Local oStruT45 	:= FWFormStruct(2, "T45")	//Cabeçalho
Local oStruT46	:= FWFormStruct(2, "T46")	//Atendentes
Local oStruT47	:= FWFormStruct(2, "T47")	//Itens calculados

oView:= FWFormView():New()
oView:SetModel(oModel)

//Remove campos da View
oStruT45:RemoveField("T45_STATUS")
oStruT46:RemoveField("T46_CODIGO")
oStruT46:RemoveField("T46_CODTFF")
oStruT47:RemoveField("T47_CODTEC")
oStruT47:RemoveField("T47_CODIGO")
oStruT47:RemoveField("T47_ITEM")
oStruT47:RemoveField("T47_XML")

oView:AddField("VIEW_CAB",     oStruT45, "T45MASTER")
oView:AddGrid("VIEW_GRID_T46", oStruT46, "T46ATEND")
oView:AddGrid("VIEW_GRID_T47", oStruT47, "T47ITEM")

oView:AddIncrementField("VIEW_GRID_T46", "T46_ITEM")		// Item Incremental do Grid Funcionarios
oView:AddIncrementField("VIEW_GRID_T47", "T47_SBITEM")		// Item Incremental do Grid Arma

oView:CreateHorizontalBox("SUPERIOR", 15)
oView:CreateHorizontalBox("MEIO",     40)
oView:CreateHorizontalBox("INFERIOR", 45)

oView:SetOwnerView("VIEW_CAB",      "SUPERIOR")
oView:SetOwnerView("VIEW_GRID_T46", "MEIO")
oView:SetOwnerView("VIEW_GRID_T47", "INFERIOR")

//Botão na grid de atendentes
oStruT47:AddField("BTNCALC"/*<cIdField>*/,;
                  "01"/*<cOrdem>*/,;
                  STR0005/*<cTitulo>*/,;	//"Calcular"
                  " "/*<cDescric>*/,;
                  {}/*<aHelp>*/,;
                  "C"/*<cType>*/,;
                  "@BMP"/*<cPicture>*/,;
                  NIL/*<bPictVar>*/,;
                  ""/*<cLookUp>*/,;
                  .F./*<lCanChange>*/,;
                  NIL/*<cFolder>*/,;
                  NIL/*<cGroup>*/,;
                  {}/*[aComboValues]*/,;
                  NIL/*[nMaxLenCombo]*/,;
                  NIL/*<cIniBrow>*/,;
                  .T./*<lVirtual>*/,;
                  NIL/*<cPictVar>*/,;
                  /*[lInsertLine]*/,;
                  /*[nWidth]*/)

//Duplo-click da grid
oView:SetViewProperty("VIEW_GRID_T47", "GRIDDOUBLECLICK", {{|oFormulario, cFieldName, nLineGrid, nLineModel| At935DClck(oFormulario, cFieldName)}})

// Opções extras da rotina
oView:AddUserButton(STR0006, "BUDGET", {|oModel| At935GetAtd()}, , , {MODEL_OPERATION_INSERT})	//"Buscar atendentes"

oView:SetCloseOnOk({|| .T.})
Return(oView)

//--------------------------------------------------------------------
/*/{Protheus.doc} AT935VldCt()
@description	Função onde é verificado os dados para geração do pedido de venda
				
@sample	 	AT935VldCt(oModel)

@param			oModel, Modelo de dados

@since			06/04/2017
@author	 	Luiz Gabriel Gomes de Jesus (luiz.jesus)
@version		P12.1.17
@return		lRet, .T. para abrir a tela, .F. para não abrir a tela e apresentar help
/*/
//--------------------------------------------------------------------
Function AT935VldCt(oModel)
Local lRet			:= .T.
Local lOperation	:= oModel:GetOperation() == MODEL_OPERATION_VIEW .Or. oModel:GetOperation() == MODEL_OPERATION_INSERT		

//Verifica se está com pedido de venda gerado e se a operação é diferente de inclusão ou visualização
If T45->T45_STATUS = "2" .And. !lOperation
	Help(,, "AT935VldCt",,STR0062,1,0,,,,,,{STR0063}) //"Não é possivel alterar ou excluir um regime de caixa com pedido gerado"##"Realize o estorno do pedido para realizar a alteração ou exclusão do regime de caixa"
	lRet := .F.
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At935Valid()
@description	Validações da rotina do cadastro de Regime de Caixa 
@sample		At935Valid(cTpValid)
@param			cTpValid ("CONTRATO" = Validação do contrato selecionado para o regime de caixa;
       			           "DTVIGINICIAL" = Validação da data inicial da vigência do contrato,;
       			           "DTVIGFINAL" = Validação da data final da vigência do contrato,;
       			           "TUDOOK" = Validação geral)
@since			06/04/2017
@author 		Alexandre da Costa (a.costa)    
@version		P12.1.17  
@return		ExpL (.T.=Informação válida / .F.=Informação inválida)
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At935Valid(cTpValid)

Local oModel		:= FwModelActive()
Local oMdlT45		:= NIL
Local oMdlT46		:= NIL
Local oMdlT47		:= NIL
Local cContrt		:= NIL
Local dGetVgIni	:= NIL
Local dGetVgFim	:= NIL
Local cTabelaT47	:= NIL
Local cRevisaT47	:= NIL
Local aSaveRows	:= {}
Local nTotLin46	:= 0
Local nTotLin47	:= 0
Local nLin46		:= 0
Local nLin47		:= 0
Local lRet			:= .T.
Local cAliasTFJ		:= ""

Default cTpValid	:= ""

If	ValType(oModel) == "O" .AND. oModel:IsActive() .AND. oModel:GetId() == "TECA935"

	oMdlT45	:= oModel:GetModel("T45MASTER")
	oMdlT46	:= oModel:GetModel("T46ATEND")
	oMdlT47	:= oModel:GetModel("T47ITEM")
	cContrt	:= oMdlT45:GetValue("T45_CONTRT")
	dGetVgIni	:= oMdlT45:GetValue("T45_DTINI")
	dGetVgFim	:= oMdlT45:GetValue("T45_DTFIM")

	Do Case

		Case	cTpValid == "T45_CONTRT"
			If	Empty(cContrt)
				Help(,, "At935Valid",,STR0007,1,0,,,,,,{STR0008})	// "Contrato não informado." ## "Informe um contrato válido, e que possua itens de RH configurados."
				lRet	:= .F.
			Else
				If	ExistCpo("TFJ", cContrt, 5)
					DbSelectArea("TFJ")
					TFJ->(DbSetOrder(5))
					If TFJ->(DbSeek(xFilial("TFJ")+ cContrt))
						If	TFJ->TFJ_RGMCX == "1"	//"1"=Sim;"2"=Nao
							// Carrega a vigência válida do contrato conforme os períodos cadastrados de atendimento para os itens de RH.
							At935Vigencia(cContrt)
							
							If	Empty(dVgIniCtrt) .OR. Empty(dVgFimCtrt)
								Help(,, "At935Valid",,STR0009,1,0,,,,,,{STR0010})	// "Não é possível criar o regime de caixa para o contrato informado." ## "O contrato não possui itens de RH configurados."
								lRet	:= .F.
							Else
								cAliasTFJ := GetNextAlias()
								//Verifica se o orçamento/contrato esta em processo de revisão
							
								BeginSQL Alias cAliasTFJ
									SELECT	TFJ.TFJ_CODIGO
									FROM 	%table:TFJ% TFJ
									WHERE 	TFJ.TFJ_FILIAL = %xFilial:TFJ% AND
											TFJ.TFJ_CONTRT = %exp:cContrt% AND
											TFJ.%NotDel% AND
											TFJ.TFJ_STATUS IN ('2','4') // DEF_TFJ_EMREVISAO, DEF_TFJ_AGDAPROVA
								EndSQL
							
								If (cAliasTFJ)->(!EOF())
									Help(,, "At935Valid",,STR0074, 1, 0,,,,,,{STR0075}) //"O contrato possui revisão em andamento para efetivação ou aprovação." ## "Termine o processo de revisão para seguir com o regime de caixa."
									lRet := .F.
								EndIf
								(cAliasTFJ)->(dbCloseArea())
							EndIf
						Else
							Help(,, "At935Valid",,STR0009,1,0,,,,,,{STR0047})	// "Não é possível criar o regime de caixa para o contrato informado." ## "Selecione um contrato cujo orçamento de serviços fora criado com o tipo de apuração igual a 'Regime de caixa'."
							lRet	:= .F.
						EndIf
					Else
						Help(,, "At935Valid",,STR0009,1,0,,,,,,{STR0008})	// "Não é possível criar o regime de caixa para o contrato informado." ## "Informe um contrato válido, e que possua itens de RH configurados."
						lRet	:= .F.
					EndIf	
				Else
					lRet	:= .F.
				EndIf
			EndIf

		Case	cTpValid == "T45_DTINI"
			If	Empty(dGetVgIni)
				Help(,, "At935Valid",,STR0011,1,0,,,,,,{STR0012})	// "O período informado como vigência do regime de caixa do contrato é inválido." ## "Informe uma data inicial para que a vigência do regime de caixa do contrato seja válida."
				lRet	:= .F.
			ElseIf	dGetVgIni < dVgIniCtrt
				Help(,, "At935Valid",,STR0011,1,0,,,,,,{STR0013 + CRLF + STR0014 + DtoC(dVgIniCtrt)})	// "O período informado como vigência do regime de caixa do contrato é inválido." ## "A data inicial é anterior à vigência válida para o contrato informado." ## "Informe uma data inicial de vigência igual ou posterior a: "
				lRet	:= .F.
			ElseIf	dGetVgIni > dVgFimCtrt
				Help(,, "At935Valid",,STR0011,1,0,,,,,,{STR0015 + CRLF + STR0016 + DtoC(dVgFimCtrt)})	// "O período informado como vigência do regime de caixa do contrato é inválido." ## "A data inicial é posterior à vigência válida para o contrato informado." ## "Informe uma data inicial de vigência igual ou anterior a: " 
				lRet	:= .F.
			ElseIf	dGetVgIni > dGetVgFim
				Help(,, "At935Valid",,STR0011,1,0,,,,,,{STR0017})	// "O período informado como vigência do regime de caixa do contrato é inválido." ## "A data inicial deve ser anterior ou igual à data final."
				lRet	:= .F.
			EndIf

		Case	cTpValid == "T45_DTFIM"
			If	Empty(dGetVgFim)
				Help(,, "At935Valid",,STR0011,1,0,,,,,,{STR0018})	// "O período informado como vigência do regime de caixa do contrato é inválido." ## "Informe uma data final para que a vigência do regime de caixa do contrato seja válida."
				lRet	:= .F.
			ElseIf	dGetVgFim > dVgFimCtrt
				Help(,, "At935Valid",,STR0011,1,0,,,,,,{STR0019 + CRLF + STR0020 + DtoC(dVgFimCtrt)})	// "O período informado como vigência do regime de caixa do contrato é inválido." ## "A data final é posterior à vigência válida para o contrato informado." ## "Informe uma data final de vigência igual ou anterior a: "
				lRet	:= .F.
			ElseIf	dGetVgFim < dVgIniCtrt
				Help(,, "At935Valid",,STR0011,1,0,,,,,,{STR0021 + CRLF + STR0022 + DtoC(dVgIniCtrt)})	// "O período informado como vigência do regime de caixa do contrato é inválido." ## "A data final é anterior à vigência válida para o contrato informado." ## "Informe uma data final de vigência igual ou posterior a: "
				lRet	:= .F.
			ElseIf	dGetVgFim < dGetVgIni
				Help(,, "At935Valid",,STR0011,1,0,,,,,,{STR0023})	// "O período informado como vigência do regime de caixa do contrato é inválido." ## "A data final deve ser posterior ou igual à data inicial."
				lRet	:= .F.
			EndIf

		Case	cTpValid == "T47_TABELA"
			cTabelaT47	:= oMdlT47:GetValue("T47_TABELA")
			If	Empty(cTabelaT47)
				Help(,, "At935Valid",,STR0032,1,0,,,,,,{STR0033})	// "Tabela não informada." ## "Informe uma tabela de precificação válida."
				lRet	:= .F.
			ElseIf !ExistCpo("TV6",cTabelaT47) .or. !TV6->(DbSeek(xFilial("TV6")+cTabelaT47)) 
				Help(,, "At935Valid",,STR0032,1,0,,,,,,{STR0033})	// "Tabela não informada." ## "Informe uma tabela de precificação válida."
				lRet	:= .F.
			ElseIf TV6->TV6_TPAPUR == '1'
				Help(,, "At935Valid",,STR0033,1,0,,,,,,{STR0071})	// "Tabela não informada." ## "Informe uma tabela de precificação válida."
				lRet	:= .F.
			EndIf

		Case	cTpValid == "T47_REVISA"
			cTabelaT47	:= oMdlT47:GetValue("T47_TABELA")
			cRevisaT47	:= oMdlT47:GetValue("T47_REVISA")
			TV6->(dBSetOrder(1))	//TV6_FILIAL+TV6_NUMERO+TV6_REVISA
			If	TV6->(dBSeek(xFilial("TV6")+cTabelaT47+cRevisaT47))
				If	lRet .AND. TV6->TV6_STATUS == "2"	//"1"=Ativa;"2"=Inativa
					Help(,, "At935Valid",,STR0036,1,0,,,,,,{STR0037})	// "A tabela/revisão não pode ser selecionada para compor os cálculos do regime de caixa. A tabela/revisão informada encontra-se inativada." ## "Selecione uma tabela/revisão ativa."
					lRet	:= .F.
				EndIf
				If	lRet .AND. TV6->TV6_TPAPUR <> "2"	//"1"=Orçamento;"2"=Regime de caixa
					Help(,, "At935Valid",,STR0038,1,0,,,,,,{STR0039})	// "A tabela/revisão não pode ser selecionada para compor os cálculos do regime de caixa." ## "O tipo de apuração da tabela/revisão informada não é igual a 'Regime de caixa'."
					lRet	:= .F.
				EndIf
			Else
				lRet	:= .F.
			EndIf

		Case	cTpValid == "TUDOOK"
			If (!Empty(dDtGeraIni) .And. !Empty(dDtGeraFim)) .And. (dDtGeraIni <> dGetVgIni .Or. dDtGeraFim <> dGetVgFim)
				lRet := .F.
				Help(,, "At935Valid",,STR0072,1,0,,,,,,{STR0073})//"A data informada não foi processada"##"Realize a busca do atendente para atualizar as informações antes da gravação"	
			EndIf
			If	dGetVgIni > dGetVgFim
				Help(,, "At935Valid",,STR0011,1,0,,,,,,{STR0024})	// "O período informado como vigência do regime de caixa do contrato é inválido." ## "A data inicial deve ser anterior ou igual à data final."
				lRet	:= .F.
			EndIf
			If	lRet .AND. !( oMdlT46:IsEmpty() )
				nTotLin46	:= oMdlT46:Length()
				For nLin46 := 1 to nTotLin46
					oMdlT46:GoLine(nLin46)
					//Feito o condição, pois ao deletar a linha ao buscar novamente os atendentes, a primeira linha está sendo considerada preenchida
					If	!( oMdlT47:IsEmpty() ) .And. (!Empty(oMdlT47:GetValue("T47_TABELA")) .Or. !Empty(oMdlT47:GetValue("T47_DSCCAL")))
						nTotLin47	:= oMdlT47:Length()
						For nLin47 := 1 to nTotLin47
							oMdlT47:GoLine(nLin47)
							If	!( oMdlT47:IsDeleted() ) .AND. Empty(oMdlT47:GetValue("T47_TABELA"))
								Help(,, "At935Valid",,STR0044 + CRLF + STR0045 + AllTrim(oMdlT46:GetValue("T46_CODTEC")) + "-" + AllTrim(oMdlT46:GetValue("T46_NOME")),1,0,,,,,,{STR0046})	// "Existe ao menos um item de cálculo inválido." ## "Atendente: " ## "Verifique se todas as tabelas de precificação foram devidamente informadas para este atendente."
								lRet	:= .F.
								EXIT
							EndIf
						Next nLin47
						If	! lRet
							EXIT
						EndIf
					EndIf
				Next nLin46
			EndIf
			If	lRet
				// Caso todas as consistências foram satisfeitas, então, força a reinicialização das variáveis de controle da rotina
				dVgIniCtrt		:= CtoD(Space(08))
				dVgFimCtrt		:= CtoD(Space(08))
				cXML			:= ""
			EndIf

	EndCase
EndIf

//Variavel para controlar a busca de atendentes quando as datas estão invalidas
If !lRet .And. (cTpValid == "T45_DTFIM" .Or. cTpValid == "T45_DTINI")
	lValido := .F.
Else
	lValido := .T.
EndIf

Return	lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At935Trg()
@description	Executa gatilhos da rotina
@sample		At935Trg(cDominio, cCDominio)
@param			cDominio
@param			cCDominio
@since			06/04/2017
@author 		Alexandre da Costa (a.costa)    
@version		P12.1.17  
@return		xExp (Conteúdo a ser considerado como retorno do gatilho executado)
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At935Trg(cDominio, cCDominio)

Local aOldArea	:= GetArea()
Local oModel		:= FwModelActive()
Local oMdlT45		:= oModel:GetModel("T45MASTER")
Local dGetVgIni	:= oMdlT45:GetValue("T45_DTINI")
Local dGetVgFim	:= oMdlT45:GetValue("T45_DTFIM")
Local cAliasTV6	:= GetNextAlias()
Local cTabelaT47	:= ""
Local xRet			:= ""

Default cDominio	:= ""
Default cCDominio	:= ""

If	cDominio == "T45_CONTRT"
	Do Case
		Case	cCDominio == "T45_DTINI"
			xRet	:= dVgIniCtrt
			// Numa eventual "troca" de contrato realizada pelo usuário, enquanto ele está incluindo o regime de caixa e o processamento da carga dos
			// atendentes ainda não ocorreu, o valor inicial do período é recarregado novamente, conforme o novo contrato. Porém, apenas nesta situação,
			// os gatilhos/validações do campo da data inicial do contrato não podem ser disparados pela utilização do método SetValue.
			// Isto porque, a data inicial da vigência do novo contrato informado é válida perante a sua respectiva data final de vigência, porém pode
			// acontecer de ser inválida em relação ao contrato anteriormente informado no campo. E, desta forma, se forem executados os gatilhos e 
			// validações previstas para o campo, uma mensagem de advertência seria exibida erroneamente ao usuário. E, utilizando-se do método Loadvalue
			// esta situação não ocorre.
			If	!( Empty(dGetVgIni) ) .AND. dGetVgIni <> dVgIniCtrt
				oMdlT45:LoadValue("T45_DTINI", dVgIniCtrt)
			EndIf

		Case	cCDominio == "T45_DTFIM"
			xRet	:= dVgFimCtrt
			// Numa eventual "troca" de contrato realizada pelo usuário, enquanto ele está incluindo o regime de caixa e o processamento da carga dos
			// atendentes ainda não ocorreu, o valor final do período é recarregado novamente, conforme o novo contrato. Porém, apenas nesta situação,
			// os gatilhos/validações do campo da data final do contrato não podem ser disparados pela utilização do método SetValue.
			// Isto porque, a data final da vigência do novo contrato informado é válida perante a sua respectiva data inicial de vigência, porém pode
			// acontecer de ser inválida em relação ao contrato anteriormente informado no campo. E, desta forma, se forem executados os gatilhos e 
			// validações previstas para o campo, uma mensagem de advertência seria exibida erroneamente ao usuário. E, utilizando-se do método Loadvalue
			// esta situação não ocorre.
			If	!( Empty(dGetVgFim) ) .AND. dGetVgFim <> dVgFimCtrt
				oMdlT45:LoadValue("T45_DTFIM", dVgFimCtrt)
			EndIf

	EndCase

ElseIf	cDominio == "T47_TABELA"
	If	cCDominio == "T47_REVISA"
		cTabelaT47	:= oModel:GetModel("T47ITEM"):GetValue("T47_TABELA")
		xRet		:= Space(Len(T47->T47_REVISA))
		If !( Empty(cTabelaT47) )
			BeginSql Alias cAliasTV6
				SELECT TV6.TV6_NUMERO, MAX(TV6.TV6_REVISA) TV6_REVISA
				  FROM %Table:TV6% TV6
				 WHERE TV6.TV6_FILIAL = %xFilial:TV6%
				   AND TV6.%NotDel%
				   AND TV6.TV6_NUMERO = %Exp:cTabelaT47%
				   AND TV6.TV6_STATUS = '1'
				 GROUP BY TV6.TV6_NUMERO
			EndSql
			If	(cAliasTV6)->( ! Eof() )
				xRet	:= (cAliasTV6)->TV6_REVISA
			EndIf
			(cAliasTV6)->(dBCloseArea())
		EndIf
	EndIf

EndIf
RestArea(aOldArea)
Return xRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At935When()
@description	Verifica se o campo está ativo ou não para edição
@sample		At935When(cCampo)
@param			cCampo
@since			06/04/2017
@author 		Alexandre da Costa (a.costa)    
@version		P12.1.17  
@return		lExp (.T. = O campo pode ser editado / .F. = O campo não pode ser editado)
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At935When(cCampo)

Local lRet			:= ""

Default cCampo	:= ""

Do Case
	Case	cCampo == "T45_CONTRT"
		lRet	:=	INCLUI // O contrato só pode ser alterado na inclusão, desde que não tenha sido processada a carga dos atendentes.
	Case	cCampo == "T45_DTINI"
		lRet	:=	INCLUI  // A data inicial do período da vigência só pode ser alterada na inclusão, desde que não tenha sido processada a carga dos atendentes.
	Case	cCampo == "T45_DTFIM"
		lRet	:=	INCLUI // A data final do período da vigência só pode ser alterada na inclusão, desde que não tenha sido processada a carga dos atendentes.
EndCase
Return lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} PrLinOkT47
@description  Pré-validação da GRID dos itens (tabelas) do regime de caixa
@sample        PrLinOkT47(oMdlT47, nT47LinGrd, cT47Acao, cT47FldName)
@param         oMdlT47:      Modelo ativo
@param         nT47LinGrd:  Linha do GRID
@param         cT47Acao:    Ação
@param         cT47FldName: Campo
@return        ExpL:        .T.=Ação válida // .F.=Ação inválida
@author        Alexandre da Costa (a.costa)
@since         11/04/2017       
@version       P12   
/*/
//------------------------------------------------------------------------------
Static Function PrLinOkT47(oMdlT47, nT47LinGrd, cT47Acao, cT47FldName)

Local aSaveRows	:= FWSaveRows()
Local nTotLin47	:= oMdlT47:Length()
Local cTabelaT47	:= ""
Local cRevisaT47	:= ""
Local nLin47		:= 0
Local lRet			:= .T.

If	cT47Acao == "UNDELETE"
	cTabelaT47	:= oMdlT47:GetValue("T47_TABELA", nT47LinGrd)
	cRevisaT47	:= oMdlT47:GetValue("T47_REVISA", nT47LinGrd)
	For nLin47 := 1 to nTotLin47
		If	nLin47 <> nT47LinGrd
			oMdlT47:GoLine(nLin47)
			If	!( oMdlT47:IsDeleted() )
				If	oMdlT47:GetValue("T47_TABELA") == cTabelaT47 .AND. oMdlT47:GetValue("T47_REVISA") == cRevisaT47
					Help(,, "TECA935-PrLinOkT47",,STR0040,1,0,,,,,,{STR0041})	//"Operação não permitida." ## "A tabela de precificação que se deseja reativar já está sendo utilizada para o atendente."
					lRet	:= .F.
					EXIT
				EndIf
			EndIf
		EndIf
	Next nLin47
EndIf
FWRestRows(aSaveRows)
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At935GetAtd()
@description	Função para realizar a busca dos atendentes
@sample		At935GetAtd()
@param			Não há
@since			06/04/2017
@author 		Alexandre da Costa (a.costa)    
@version		P12.1.17  
@return		lExp (.T.=Sucesso na carga dos atendentes / .F.=Carga dos atendentes não foi possível) 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At935GetAtd()

Local aOldArea		:= GetArea()
Local oModel		:= FwModelActive()
Local oView			:= FWViewActive() 
Local oMdlT45		:= oModel:GetModel("T45MASTER")
Local oMdlT46		:= oModel:GetModel("T46ATEND")
Local oMdlT47		:= oModel:GetModel("T47ITEM")
Local cContrt		:= oMdlT45:GetValue("T45_CONTRT")
Local dDtIni		:= oMdlT45:GetValue("T45_DTINI")
Local dDtFim		:= oMdlT45:GetValue("T45_DTFIM")		
Local cAliasAA1		:= GetNextAlias()
Local aAtend		:= {}
Local lRet			:= .T.
Local nX			:= 0

If !lValido
	Help(,, "At935GetAtd",,STR0027,1,0,,,,,,{STR0028})	// "Não é possível realizar a busca por atendentes que satisfaçam ao contrato / período de vigência." ## "Informe o contrato e o período de vigência desejado para liberar o processamento da carga dos atendentes."	
	Return .F.
EndIf

If !oMdlT46:IsEmpty()
	If IsBlind() .Or. MsgYesNo(STR0068 +CRLF+ STR0069) //"Ao realizar a busca novamente todos os dados serão perdidos"##"Deseja Continuar?"
		
		//Habilito a Edição
		oMdlT46:SetNoInsertLine( .F. )
		oMdlT46:SetNoDeleteLine( .F. )
		oMdlT46:SetNoUpdateLine( .F. )
		
		//Deleta todas as linhas para evitar duplicação
		For nX := oMdlT46:Length() To 1 Step -1
			If nX > 1
				oMdlT46:GoLine(nX)
				lRet := oMdlT46:DeleteLine(.T.,.T.)
			Else
				oMdlT46:LoadValue("T46_CODTEC", " ")
				oMdlT46:LoadValue("T46_NOME", " ")
				oMdlT46:LoadValue("T46_LOCAL",  " ")
				oMdlT46:LoadValue("T46_DSCLOC",  " ")
				oMdlT46:LoadValue("T46_CODTFF", " ")
			EndIf	
		Next nX
		
		//Desabilita o Grid de Atendentes para Edição
		oMdlT46:SetNoInsertLine(.T.)
		oMdlT46:SetNoDeleteLine(.T.)
		oMdlT46:SetNoUpdateLine(.T.)
		
		//Habilito a Edição
		oMdlT47:SetNoInsertLine( .F. )
		oMdlT47:SetNoDeleteLine( .F. )
		oMdlT47:SetNoUpdateLine( .F. )
		
		//Deleta todas as linhas para evitar duplicação
		For nX := oMdlT47:Length() To 1 Step -1
			If nX > 1
				oMdlT47:GoLine(nX)
				lRet := oMdlT47:DeleteLine(.T.,.T.)
			Else
				oMdlT47:LoadValue("T47_DSCCAL", " ")
				oMdlT47:LoadValue("T47_TABELA",  " ")
				oMdlT47:LoadValue("T47_REVISA", " ")
				oMdlT47:LoadValue("T47_XML", " ")
				oMdlT47:LoadValue("T47_VALOR", 0)
			EndIf
		Next nX
		
		//Desabilito a Edição
		oMdlT47:SetNoInsertLine( .T. )
		oMdlT47:SetNoDeleteLine( .T. )
		oMdlT47:SetNoUpdateLine( .T. )
		
	EndIf	
EndIf

//Verifica se todos os campos estão preenchidos
If	!( Empty(cContrt) ) .AND. !( Empty(dDtIni) ) .AND. !( Empty(dDtFim) )
	// Carrega os atendentes alocados dentro da vigência do contrato.
	BeginSql Alias cAliasAA1
		SELECT DISTINCT AA1.AA1_CODTEC, AA1.AA1_NOMTEC, TFF.TFF_LOCAL, ABS.ABS_DESCRI, TFF.TFF_COD
			 FROM %Table:TFF% TFF
		       INNER JOIN %Table:ABQ% ABQ ON ABQ.ABQ_FILIAL = %xFilial:ABQ%
		                                 AND ABQ.ABQ_FILTFF = TFF.TFF_FILIAL
			                                 AND ABQ.ABQ_CODTFF = TFF.TFF_COD
		                                 AND ABQ.ABQ_CONTRT = TFF.TFF_CONTRT
		                                 AND ABQ.ABQ_ORIGEM = 'CN9'
		                                 AND ABQ.%NotDel%
		       INNER JOIN %Table:ABB% ABB ON ABB.ABB_FILIAL = %xFilial:ABB%
		                                 AND ABB.ABB_IDCFAL = ABQ.ABQ_CONTRT || ABQ.ABQ_ITEM || ABQ.ABQ_ORIGEM
		                                 AND ABB.ABB_DTINI >= %Exp:DtoS(dDtIni)%
                                 		 AND ABB.ABB_DTFIM <= %Exp:DtoS(dDtFim)%
		                                 AND ABB.%NotDel%
		       INNER JOIN %Table:AA1% AA1 ON AA1.AA1_FILIAL = %xFilial:AA1%
		                                 AND AA1.AA1_CODTEC = ABB.ABB_CODTEC
		                                 AND AA1.%NotDel%
		       INNER JOIN %Table:ABS% ABS ON ABS.ABS_FILIAL = %xFilial:ABS%
		                                 AND ABS.ABS_LOCAL  = TFF.TFF_LOCAL
		                                 AND ABS.%NotDel%
		 WHERE TFF.TFF_FILIAL = %xFilial:TFF%
		   AND TFF.TFF_CONTRT = %Exp:cContrt%
		   AND TFF.TFF_PERINI >= %Exp:DtoS(dVgIniCtrt)%
		   AND TFF.TFF_PERFIM <= %Exp:DtoS(dVgFimCtrt)%
		   AND TFF.%NotDel%
		 ORDER BY AA1.AA1_NOMTEC, ABS.ABS_DESCRI
	EndSql

	If	(cAliasAA1)->( ! Eof() )
		
		//Habilito a Edição
		oMdlT47:SetNoInsertLine( .F. )
		oMdlT47:SetNoDeleteLine( .F. )
		oMdlT47:SetNoUpdateLine( .F. )
		
		While (cAliasAA1)->( ! Eof() )
			aAdd(aAtend, {(cAliasAA1)->AA1_CODTEC, (cAliasAA1)->TFF_LOCAL, (cAliasAA1)->TFF_COD})
			(cAliasAA1)->(dBSkip())
		EndDo
		(cAliasAA1)->(dBCloseArea())	
		RestArea(aOldArea)
		// Chama função para preencher o grid de atendentes
		At935Atend(oModel, aAtend)		
	Else
		Help(,, "At935GetAtd",,STR0025,1,0,,,,,,{STR0070})	// "Não é possível criar o regime de caixa para o contrato informado." ## "Não foi encontrado nenhuma alocação de Atendente dentro do periodo informado."
		lRet	:= .F.
	EndIf
Else
	Help(,, "At935GetAtd",,STR0027,1,0,,,,,,{STR0028})	// "Não é possível realizar a busca por atendentes que satisfaçam ao contrato / período de vigência." ## "Informe o contrato e o período de vigência desejado para liberar o processamento da carga dos atendentes."
	lRet	:= .F.
EndIf

//Guardo as datas geradas para controle na gravação
dDtGeraIni := oMdlT45:GetValue("T45_DTINI")
dDtGeraFim := oMdlT45:GetValue("T45_DTFIM")

//Atualiza a tela
If !IsBlind()
	oView:Refresh()
EndIf

RestArea(aOldArea)
Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At935Atend()
@description	Função para realizar a busca dos atendentes
@sample		At935Atend(oModel, aAtend)
@param			oModel
@param			aAtend
@since			06/04/2017
@author 		Luiz Gabriel Gomes de Jesus (luiz.jesus) / Alexandre da Costa (a.costa)    
@version		P12.1.17  
@return		NIL
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At935Atend(oModel, aAtend)

Local oMdlT46		:= oModel:GetModel("T46ATEND")
Local nX			:= 0
Local nQtdAtend	:= 0

Default aAtend	:= {}

nQtdAtend	:= Len(aAtend)

//Destrava o grid de atendentes para atualização
oMdlT46:SetNoInsertLine(.F.)
oMdlT46:SetNoDeleteLine(.F.)
oMdlT46:SetNoUpdateLine(.F.)

For nX := 1 to nQtdAtend
	If	nX > 1
		oMdlT46:AddLine()
	EndIf
	oMdlT46:SetValue("T46_CODTEC", aAtend[nX][01])
	oMdlT46:SetValue("T46_LOCAL",  aAtend[nX][02])
	oMdlT46:SetValue("T46_CODTFF", aAtend[nX][03])
Next nX
oMdlT46:GoLine(1)

//Trava o grid de atendentes
oMdlT46:SetNoInsertLine(.T.)
oMdlT46:SetNoDeleteLine(.T.)
oMdlT46:SetNoUpdateLine(.T.)
Return NIL


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At935Vigencia()
@description	Busca o período de vigência completa para o contrato
@sample		At935Vigencia(cContrt)
@param			cContrt
@since			06/04/2017
@author 		Alexandre da Costa (a.costa)    
@version		P12.1.17  
@return		NIL
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At935Vigencia(cContrt)

Local aOldArea	:= GetArea()
Local cAliasTRB	:= GetNextAlias()

Default cContrt	:= ""

// Busca a menor data inicial e a maior data final de vigência do contrato 
BeginSql Alias cAliasTRB

	COLUMN TFF_PERINI AS DATE
	COLUMN TFF_PERFIM AS DATE
	
	SELECT TFF.TFF_CONTRT, MIN(TFF.TFF_PERINI) TFF_PERINI, MAX(TFF.TFF_PERFIM) TFF_PERFIM
	  FROM %Table:TFF% TFF
	 WHERE TFF.TFF_FILIAL = %xFilial:TFF%
	   AND TFF.%NotDel%
	   AND TFF.TFF_CONTRT = %Exp:cContrt%
	 GROUP BY TFF.TFF_CONTRT
EndSql

If	(cAliasTRB)->( ! Eof() )
	// Carrega as variáveis de controle da rotina.
	dVgIniCtrt		:= (cAliasTRB)->TFF_PERINI
	dVgFimCtrt		:= (cAliasTRB)->TFF_PERFIM
	//
EndIf

(cAliasTRB)->(dBCloseArea())
RestArea(aOldArea)
Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} At935DClck()
@description	Função de duplo-click para chamar o cálculo da planilha
@sample	 	At935DClck(oFormulario,cField)
@param			oFormulario
@param			cField
@since			06/04/2017
@author	 	Luiz Gabriel Gomes de Jesus (luiz.jesus)    
@version		P12.1.17  
@return		lExp (.T.=Ação válida / .F.=Ação inválida)
/*/
//--------------------------------------------------------------------
Static Function At935DClck(oFormulario, cField)

Local oModel		:= FwModelActive()
Local cTabelaT47	:= ""
Local cRevisaT47	:= ""
Local lRet			:= .T.
Local lOperation	:= oModel:GetOperation() == MODEL_OPERATION_UPDATE .Or. oModel:GetOperation() == MODEL_OPERATION_INSERT
Local oMdlT47		:= oModel:GetModel("T47ITEM")

Default oFormulario	:= NIL
Default cField		:= NIL

//Somente executa a ação do botão quando a operação for inclusão ou alteração e a linha não estiver deletada
If lOperation .And. !oMdlT47:IsDeleted()
	If	!( oModel:GetModel("T46ATEND"):IsEmpty() )
		If	cField == "BTNCALC"
			//Antes de chamar atribiu valor para a variavel do XML
			cTabelaT47	:= oModel:GetModel("T47ITEM"):GetValue("T47_TABELA")
			cRevisaT47	:= oModel:GetModel('T47ITEM'):GetValue("T47_REVISA")
			cXML		:= oModel:GetModel('T47ITEM'):GetValue("T47_XML")
			If	!( Empty(cTabelaT47) )
				Processa({|| At935Tab(cTabelaT47, cRevisaT47, oModel:GetModel('T47ITEM'))}, STR0057, STR0058, .F.)	//"Aguarde..." ## "Criando a estrutura da tabela de precificação" 
				oFormulario:oControl:Refresh()
			Else
				Help(,, "At935DClck",,STR0040,1,0,,,,,,{STR0042})	//"Operação não permitida." ## "Não foi informada uma tabela/revisão para a execução do cálculo."
				lRet		:= .F.
			EndIf
		EndIf
	Else
		Help(,, "At935DClck",,STR0040,1,0,,,,,,{STR0043})	//"Operação não permitida." ## "Não há atendentes selecionados para a configuração do cálculo do regime de caixa."
		lRet		:= .F.
	EndIf
EndIf
	
Return lRet


//--------------------------------------------------------------------
/*/{Protheus.doc} At935Tab()
@description	Função para abertura da tabela de precificação
@sample	 	At935Tab(cTabelaT47, cRevisaT47)
@param			cTabelaT47
@param			cRevisaT47
@since			06/04/2017
@author	 	Luiz Gabriel Gomes de Jesus (luiz.jesus)
@version		P12.1.17
@return		lExp (.T.)
/*/
//--------------------------------------------------------------------
Function At935Tab(cTabelaT47, cRevisaT47,oModelT47,lAutomato)

Local aOldArea	:= GetArea()
Local aButtons	:= {{.F.,Nil},;
              	    {.F.,Nil},;
              	    {.F.,Nil},;
              	    {.F.,Nil},;
              	    {.F.,Nil},;
              	    {.F.,Nil},;
              	    {.T.,STR0005},;	//"Calcular"
              	    {.T.,STR0048},;	//"Cancelar"
              	    {.T.,Nil},;
              	    {.T.,Nil},;
              	    {.T.,Nil},;
              	    {.T.,Nil},;
              	    {.T.,Nil},;
              	    {.T.,Nil}}
Local aValor		:= {}
Local bOk			:= {|| A935ACalc(@aValor)}

Default lAutomato 	:= .F.		//Variavel para automatização do teste

//Deixar a tabela de precificação posicionada para uso na rotina TECA935A
DbSelectArea("TV6")
TV6->(DbSetOrder(1))	//TV6_FILIAL+TV6_NUMERO+TV6_REVISA
TV6->(MsSeek(xFilial("TV6")+cTabelaT47+cRevisaT47))

If !lAutomato
	FWExecView(STR0031, "VIEWDEF.TECA935A", MODEL_OPERATION_UPDATE, /*oDlg*/, /*bCloseOnOk*/, bOk, 50/*nPercReducao*/,aButtons)	//"Cálculo da tabela de precificação"
Else
	A935ACalc(@aValor)	
EndIf

If !Empty(aValor)
	//Atribiu na valor para a varaivel cXML
	cXML := aValor[1]
	oModelT47:SetValue("T47_XML",cXML)
	oModelT47:SetValue("T47_VALOR",aValor[2])
EndIf

RestArea(aOldArea)
Return 


//--------------------------------------------------------------------
/*/{Protheus.doc} Get935XML()
@description	Função para recuperar o XML
@sample	 	Get935XML()
@param			Não há
@since			06/04/2017
@author	 	Luiz Gabriel Gomes de Jesus (luiz.jesus)
@version		P12.1.17
@return		cXML - XML da tabela de precificação
/*/
//--------------------------------------------------------------------
Function Get935XML()
Return cXML

//-------------------------------------------------------------------
/*/{Protheus.doc} At935Estorna
@description	Função para realizar o estorno do pedido de venda

@sample	 	At935Estorna()

@since			06/04/2017
@author	 	Luiz Gabriel Gomes de Jesus (luiz.jesus)
@version	P12.1.17
@return		.T.
/*/
//------------------------------------------------------------------
Function At935Estorna()
	Processa( {|| (At935EstPd()) }, STR0055, STR0064,.F.) //"Aguarde..."##"Realizando estorno do Pedido"
Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} At935Pedido
@description	Função para realizar o Pedido de venda

@sample	 	At935Pedido()

@since		06/04/2017
@author	 	Luiz Gabriel Gomes de Jesus (luiz.jesus)
@version	P12.1.17
@return		.T.
/*/
//------------------------------------------------------------------
Function At935Pedido()
	Processa( {|| (At935GerPd()) }, STR0055, STR0065,.F.) //"Aguarde..."##"Gerando Pedido de Venda"
Return .T.

//--------------------------------------------------------------------
/*/{Protheus.doc} At935EstPd()

@description	Função para Estornar o pedido de venda(Exclusão)

@sample	 	At935EstPd()
@param			Não há
@since			06/04/2017
@author	 	Luiz Gabriel Gomes de Jesus (luiz.jesus)
@version		P12.1.17
@return		lRet - .T. Se o pedido foi excluido com sucesso, .F. Não excluiu
/*/
//--------------------------------------------------------------------
Static Function At935EstPd()
Local lRet 			:= .T.
Local aAreaSC5		:= SC5->(GetArea())
Local cAliasTRB		:= GetNextAlias()
Local cCodigoT45	:= T45->T45_CODIGO	// Código único do registro. O contrato não é chave única da tabela T45, podendo o mesmo estar em mais de um registro. 
Local aNumPed		:= {}				
Local nX			:= 0
Local nNumPed		:= 0
Local aPedCab		:= {}
Local xAux			:= {}
Local cFil			:= ""
Local lA935FilEst	:=  ExistBlock("A935FilEst")
Local cCodCtt		:= ""

Private lMsErroAuto	:= .F.

If T45->T45_STATUS == "2"	//"1"=Ativo;"2"=Pedido gerado
	BeginSql Alias cAliasTRB
		SELECT DISTINCT T46.T46_NUMPED 
				FROM %Table:T46% T46
				WHERE T46.T46_FILIAL = %xFilial:T46%
				      AND T46.T46_CODIGO = %Exp:cCodigoT45%
				      AND T46.%NotDel%
	EndSql
	
	// Monta o array com os locais encontrados para o contrato/revisão vigente
	While (cAliasTRB)->( ! Eof() )
		aAdd(aNumPed,(cAliasTRB)->T46_NUMPED)
		(cAliasTRB)->( dBSkip() )
	EndDo
	
	nNumPed := Len(aNumPed)
	
	If nNumPed > 0
		Begin Transaction
			DbSelectArea("SC5")
			SC5->( DbSetOrder( 1 ) ) // C5_FILIAL+C5_NUM
			If lA935FilEst
				cFil := ExecBlock("A935FilEst",.F.,.F.,{aNumPed})
			Else
				cFil := xFilial("SC5")
			EndIf	
			For nX := 1 To nNumPed
				lMsErroAuto	:= .F.
				
				If SC5->( DbSeek(cFil+aNumPed[nX] ) )
					cCodCtt :=	SC5->C5_MDCONTR
					Reclock("SC5", .F.)
					SC5->C5_MDCONTR	:= "" //Apaga o vinculo com o numero do CTT
					SC5->(MsUnLock())				
					// monta o array com as informações para a exclusão do pedido
					aAdd( aPedCab, { "C5_FILIAL", cFil, Nil } )
					aAdd( aPedCab, { "C5_NUM", aNumPed[nX], Nil } )
					
					MSExecAuto({|x,y,z| Mata410(x,y,z)}, aPedCab,{},5)
					
					If lMsErroAuto
						lRet	:= .F.
						xAux	:= GetAutoGrLog()
						MostraErro()
						DisarmTransaction()
						If SC5->( DbSeek(cFil+aNumPed[nX] ) )
							Reclock("SC5", .F.)
							SC5->C5_MDCONTR	:= cCodCtt //Volta o vinculo com o numero do CTT
							SC5->(MsUnLock())	
						EndIf						
						EXIT
					Else
						aPedCab := {}
					EndIf							
				EndIf
			Next nX
			
			//Restaura o campo T46_NUMPED e volta o status para Ativo
			If lRet
				If !At935Rest(cCodigoT45)
					DisarmTransaction()	
				EndIf	
			EndIf
			
		End Transaction	
	EndIf
	(cAliasTRB)->(dBCloseArea())		
Else
	Help(,, "At935EstPd",,STR0066,1,0,,,,,,{STR0067})//"Pedido de Venda não pode ser estornado"##"Verifique se o pedido está gerado para realizar o estorno"
	lRet	:= .F.	
EndIf

RestArea(aAreaSC5)

Return (lRet)

//-------------------------------------------------------------------
/*/{Protheus.doc} At935Rest
@description	Função restaura os itens da T46 para retirar os numeros do pedidos gravados
				e volta o campo T45_STATUS para 1=Ativo.
@sample	 	At935Rest(cCodigoT45)
@param			cCodigoT45, Codigo do regime de caixa
@since			06/04/2017
@author	 	Luiz Gabriel Gomes de Jesus (luiz.jesus)
@version	P12.1.17
@return		lExp, .T para sucesso na restauração do regime de caixa
/*/
//------------------------------------------------------------------
Static Function At935Rest(cCodigoT45)	
Local lRet			:= .T.
Local cAliasTRB		:= GetNextAlias()
Local aArea			:= GetArea()

Default cCodigoT45 := ""

If !Empty(cCodigoT45)
	BeginSql Alias cAliasTRB
		SELECT T46.R_E_C_N_O_ RECNOT46
				FROM %Table:T46% T46
				WHERE T46.T46_FILIAL = %xFilial:T46%
				      AND T46.T46_CODIGO = %Exp:cCodigoT45%
				      AND T46.%NotDel%
	EndSql
	
	While (cAliasTRB)->( ! Eof() )
		T46->( DbGoTo((cAliasTRB)->RECNOT46) )
		RecLock("T46",.F.)
			T46->T46_NUMPED := ""
		T46->(MsUnLock())	
		(cAliasTRB)->( dBSkip() )
	EndDo
	
	T45->(RecLock("T45",.F.))
	T45->T45_STATUS	:= "1"	//"1"=Ativo;"2"=Pedido gerado
	T45->(MsUnLock())
	
EndIf

(cAliasTRB)->(dBCloseArea())

RestArea(aArea)

Return(lRet) 

//-------------------------------------------------------------------
/*/{Protheus.doc} At935GerPd
@description	Função para a geração do pedido de venda
@sample	 	At935GerPd()
@param			Não há
@since			06/04/2017
@author	 	Alexandre da Costa (a.costa)
@version		P12.1.17
@return		lExp (.T.=Geração do pedido de venda OK, .F.=Geração do pedido de venda não ocorreu.)
/*/
//------------------------------------------------------------------
Function At935GerPd()
Local aOldArea		:= GetArea()
Local cAliasTRB		:= GetNextAlias()
Local aPedCabec		:= {}
Local aPedItens		:= {}
Local cContrt		:= ""
Local cCodigoT45	:= ""
Local cItem			:= ""
Local cLocalAnt		:= ""
Local xAux			:= ""
Local nOpcA410		:= 3
Local nPos			:= 0
Local lRet			:= .T.
Local cNum			:= ""
Local aRecno		:= {}
Local aLinha		:= {}
Local cRevCtr		:= ""
Local nItemPed		:= 0						
Local lA935NumPed	:= ExistBlock("A935NumPed")//Ponto de entrada para numeração do pedido de venda
Local cB1_CODISS	:= "" //Codigo do ISSQN
						
Private lMsErroAuto	:= .F.

If	T45->T45_STATUS == "1"	//"1"=Ativo;"2"=Pedido gerado

	cCodigoT45	:= T45->T45_CODIGO	// Código único do registro. O contrato não é chave única da tabela T45, podendo o mesmo estar em mais de um registro.
	cContrt		:= T45->T45_CONTRT
	cRevCtr 	:= Posicione("CN9",7,xFilial("CN9")+cContrt+"05","CN9_REVISA")
	
	//Verifica se há alguma pendencia
	cPendencia := At935ChkIT(cCodigoT45)
	
	If	cPendencia == "N"		// Caso não exista pendências de cálculo das tabelas relacionadas para o regime de caixa do contrato, continua a geração do pedido de venda.

		aLocais := At935GetLoc(cContrt, cRevCtr)

		// Compôe o valor total de cada atendente por local
		// A query está gerando por ordem alfabética de atendente dentro de cada local.
		cAliasTRB	:= GetNextAlias()
		BeginSql Alias cAliasTRB
			SELECT T46.T46_LOCAL,SB1.B1_CODISS, T46.T46_CODTFF, AA1.AA1_NOMTEC, T46.T46_CODTEC, T46.R_E_C_N_O_ RECNOT46, SUM(T47.T47_VALOR) T47_VALOR
			  FROM %Table:T45% T45
			       INNER JOIN %Table:T46% T46 ON T46.T46_FILIAL = %xFilial:T46%
			                                 AND T46.T46_CODIGO = T45.T45_CODIGO
			                                 AND T46.%NotDel%
			       INNER JOIN %Table:T47% T47 ON T47.T47_FILIAL = %xFilial:T47%
			                                 AND T47.T47_CODIGO = T46.T46_CODIGO
			                                 AND T47.T47_ITEM   = T46.T46_ITEM
			                                 AND T47.T47_CODTEC = T46.T46_CODTEC
			                                 AND T47.%NotDel%
			       INNER JOIN %Table:TFF% TFF ON TFF.TFF_FILIAL = %xFilial:TFF%
			                                 AND T46.T46_CODTFF = TFF.TFF_COD
			                                 AND TFF.%NotDel%	
			       INNER JOIN %Table:SB1% SB1 ON SB1.B1_FILIAL = %xFilial:SB1%
			                                 AND TFF.TFF_PRODUT = SB1.B1_COD
			                                 AND SB1.%NotDel%			                              
			       INNER JOIN %Table:AA1% AA1 ON AA1.AA1_FILIAL = %xFilial:AA1%
			                                 AND AA1.AA1_CODTEC = T46.T46_CODTEC
			                                 AND AA1.%NotDel%
			 WHERE T45.T45_FILIAL = %xFilial:T45%
			   AND T45.T45_CODIGO = %Exp:cCodigoT45%
			   AND T45.%NotDel%
			 GROUP BY T46.T46_LOCAL, SB1.B1_CODISS, T46.T46_CODTFF ,AA1.AA1_NOMTEC, T46.T46_CODTEC, T46.R_E_C_N_O_
			 ORDER BY T46.T46_LOCAL, SB1.B1_CODISS, AA1.AA1_NOMTEC
		EndSql

		// Inicia a preparação para execução do ExecAuto a fim de gerar os pedidos de venda.
		If	(cAliasTRB)->( ! Eof() )

			Begin Transaction
				While	(cAliasTRB)->( ! Eof() ) 
					
					If	( (cAliasTRB)->T46_LOCAL <> cLocalAnt )  .OR.  ( (cAliasTRB)->B1_CODISS <> cB1_CODISS  )    //Adiciona quebra por codigo de issqn
						If	Len(aPedCabec) > 0 .AND. Len(aPedItens) > 0
							// Dispara Execauto para gravação do pedido de venda do regime de caixa.
							MsExecAuto({|x,y,z| MATA410(x,y,z)}, aPedCabec, aPedItens, nOpcA410)
							If lMsErroAuto
								lRet	:= .F.
								xAux	:= GetAutoGrLog()
								MostraErro()
								DisarmTransaction()
								EXIT
							Else
								Conout("Pedido Gerado com Sucesso" + cNum)
								Reclock("SC5", .F.)
								SC5->C5_MDCONTR	:= cContrt //Se enviar pelo execauto vai vincular a uma medição e um CTT vide A410INCLUI
								SC5->(MsUnLock())								
								At935GrvPed(aRecno,cNum)
							EndIf
									
							aPedCabec	:= {}
							aPedItens	:= {}
							aRecno		:= {}
						EndIf
						nPos	:= aScan(aLocais,{|z| z[01] == (cAliasTRB)->T46_LOCAL})
						If nPos > 0
							If lA935NumPed
								cNum := ExecBlock("A935NumPed",.F.,.F.,{cContrt, cRevCtr,aLocais[nPos,08]})
							Else
								cNum := GetSxeNum("SC5","C5_NUM")
							EndIf
							//Monta o cabeçalho do pedido
							SC5->(RollBAckSx8())
							aAdd(aPedCabec,{"C5_NUM"   		,cNum				,Nil})
							
							aAdd(aPedCabec,{"C5_TIPO" 		,"N"				,Nil})
							aAdd(aPedCabec,{"C5_CLIENTE"	,aLocais[nPos,03]	,Nil})
							aAdd(aPedCabec,{"C5_LOJACLI"	,aLocais[nPos,04]	,Nil})
							aAdd(aPedCabec,{"C5_LOJAENT"	,aLocais[nPos,04]	,Nil})
							aAdd(aPedCabec,{"C5_CONDPAG"	,aLocais[nPos,02]	,Nil})
							aAdd(aPedCabec,{"C5_RECISS"	,aLocais[nPos,10]	,Nil})
							aAdd(aPedCabec,{"C5_ESTPRES"	,aLocais[nPos,11]	,Nil})
							aAdd(aPedCabec,{"C5_MUNPRES"	,aLocais[nPos,09]	,Nil})
							aAdd(aPedCabec,{"C5_ORIGEM"		,'TECA935'			,Nil})  
							
							               
							cItem		:= StrZero(0, TamSX3("C6_ITEM")[1])
							cLocalAnt	:= (cAliasTRB)->T46_LOCAL
							cB1_CODISS := (cAliasTRB)->B1_CODISS  
						Else
							Help(,, "At935GerPd",,STR0076,1,0,,,,,,{STR0077})	//"Pedido de venda não pode ser gerado." ## "Existe uma ou mais pendências de cálculo. Favor verificar!"
							lRet := .F.
							DisarmTransaction()
							EXIT
						EndIf	
					EndIf
					//Monta o item do pedido
					nItemPed++
					cItem	:= Soma1(cItem)
					aLinha := {}
					nPos	:= aScan(aLocais,{|z| z[07] == (cAliasTRB)->T46_CODTFF})
					aAdd(aLinha,{"C6_ITEM"		,cItem						,Nil})
					aAdd(aLinha,{"C6_PRODUTO"	,aLocais[nPos,05]		,Nil})
					aAdd(aLinha,{"C6_QTDVEN"	,1							,Nil})
					aAdd(aLinha,{"C6_PRCVEN"	,(cAliasTRB)->T47_VALOR		,Nil})
					aAdd(aLinha,{"C6_PRUNIT"	,(cAliasTRB)->T47_VALOR		,Nil})
					aAdd(aLinha,{"C6_VALOR"		,(cAliasTRB)->T47_VALOR		,Nil})
					aAdd(aLinha,{"C6_TES"		,aLocais[nPos,06]		,Nil})
					
					aAdd(aPedItens,aLinha)		                 
					
					aAdd(aRecno,(cAliasTRB)->RECNOT46)                 
					(cAliasTRB)->( dBSkip() )
				EndDo
				If	lRet
					If	Len(aPedCabec) > 0 .AND. Len(aPedItens) > 0

						// Dispara Execauto para gravação do pedido de venda do regime de caixa.
						MsExecAuto({|x,y,z| MATA410(x,y,z)}, aPedCabec, aPedItens, nOpcA410)
						If lMsErroAuto
							lRet	:= .F.
							xAux	:= GetAutoGrLog()
							MostraErro()
							DisarmTransaction()
						Else
							Conout(STR0078 + cNum)
							Reclock("SC5", .F.)
							SC5->C5_MDCONTR	:= cContrt //Se enviar pelo execauto vai vincular a uma medição e um CTT vide A410INCLUI
							SC5->(MsUnLock())
							At935GrvPed(aRecno,cNum)	
						EndIf

						aPedCabec	:= {}
						aPedItens	:= {}
						aRecno		:= {}
					EndIf
				EndIf
				If	lRet
					T45->(RecLock("T45",.F.))
					T45->T45_STATUS	:= "2"	//"1"=Ativo;"2"=Pedido gerado
					T45->(MsUnLock())
				EndIf
			End Transaction

		EndIf
		//
		(cAliasTRB)->(dBCloseArea())
	Else
		Help(,, "At935GerPd",,STR0051,1,0,,,,,,{STR0052})	//"Pedido de venda não pode ser gerado." ## "Existe uma ou mais pendências de cálculo. Favor verificar!"
		lRet	:= .F.
	EndIf
Else
	Help(,, "At935GerPd",,STR0049,1,0,,,,,,{STR0050})	//"Pedido de venda já foi gerado." ## "A situação atual do regime de caixa selecionado não permite a geração do pedido de venda."
	lRet	:= .F.
EndIf

RestArea(aOldArea)
Return lRet

//--------------------------------------------------------------------
/*/{Protheus.doc} At935ChkIT()
@description	Função onde é verificado se todos os itens da T47 estão calculados
				para geração do pedido
				
@sample	 	At935ChkIT(cCodigoT45)

@param			cCodigoT45, Codigo do Regime de Caixa para busca nos itens calculados

@since			06/04/2017
@author	 	Luiz Gabriel Gomes de Jesus (luiz.jesus)
@version		P12.1.17
@return		.T.
/*/
//--------------------------------------------------------------------
Static Function At935ChkIT(cCodigoT45)
Local cAliasTRB		:= GetNextAlias()
Local cPendencia		:= "N"				//Variavel onde é indicado se há algum item sem ser calculado "N" Não, "S" Sim

// Verifica se há no regime de caixa selecionado, algum valor que não foi calculado, de acordo com as tabelas de precificação utilizadas.
BeginSql Alias cAliasTRB
	SELECT 'S' PENDENCIA
		FROM %Table:T45% T45
		 WHERE T45.T45_FILIAL = %xFilial:T45%
		   AND T45.%NotDel%
		   AND T45.T45_CODIGO = %Exp:cCodigoT45%
		   AND EXISTS(SELECT T47_VALOR FROM %Table:T47% T47 
		   				WHERE  T47.T47_CODIGO = %Exp:cCodigoT45% AND
		   				T47.T47_VALOR = 0 AND
		   				T47.%NotDel%)
EndSql
	
If (cAliasTRB)->( ! Eof() )
	cPendencia	:= (cAliasTRB)->PENDENCIA
EndIf

(cAliasTRB)->(dBCloseArea())

Return(cPendencia)

//--------------------------------------------------------------------
/*/{Protheus.doc} At935GetLoc()
@description	Função onde é verificado os dados para geração do pedido de venda
				
@sample	 	At935GetLoc(cContrt,cRevCtr)

@param			cContrt, Codigo do Contrato a ser pesquisado

@since			06/04/2017
@author	 	Luiz Gabriel Gomes de Jesus (luiz.jesus)
@version		P12.1.17
@return		.T.
/*/
//--------------------------------------------------------------------
Static Function At935GetLoc(cContrt,cRevCtr)
Local cAliasTRB		:= GetNextAlias()
Local aLocais		:= {}
Local lGrpFat    	:= SuperGetMv("MV_GSGRFAT",,"2")=="1"



cAliasTRB	:= GetNextAlias()

If !lGrpFat
	// Busca a revisão do contrato vigente, com as informações de local, planilha, cliente, produto, TES, etc para a geração dos pedidos de venda 
	BeginSql Alias cAliasTRB
		SELECT TFL.TFL_LOCAL,  TFL.TFL_PLAN,   TFL.TFL_ITPLRH, CN9.CN9_NUMERO,
				CN9.CN9_REVISA, CN9.CN9_CONDPG, CNA.CNA_CLIENT, CNA.CNA_LOJACL,
				CNA.CNA_NUMERO, CNB.CNB_PRODUT, CNB.CNB_TS, TFF.TFF_COD, 
				ABS.ABS_CODMUN, ABS.ABS_RECISS, ABS.ABS_ESTADO
		FROM %Table:CN9% CN9
			INNER JOIN %Table:CNA% CNA ON CNA.CNA_FILIAL = %xFilial:CNA%
	 			                        AND CNA.CNA_CONTRA = CN9.CN9_NUMERO
	 			                       	AND CNA.CNA_REVISA = CN9.CN9_REVISA
	 			                       	AND CNA.%NotDel%
			INNER JOIN %Table:CNB% CNB ON CNB.CNB_FILIAL = %xFilial:CNB%
	 			                      	AND CNB.CNB_CONTRA = CN9.CN9_NUMERO
	 			                      	AND CNB.CNB_REVISA = CN9.CN9_REVISA
	 			                      	AND CNB.CNB_NUMERO = CNA.CNA_NUMERO
	 			                       	AND CNB.%NotDel%
			INNER JOIN %Table:TFL% TFL ON TFL.TFL_FILIAL = %xFilial:TFL%
	 			                     	AND TFL.TFL_CONTRT = CN9.CN9_NUMERO
	 			                       	AND TFL.TFL_CONREV = CN9.CN9_REVISA
	 			                       	AND TFL.TFL_PLAN   = CNB.CNB_NUMERO
	 			                      	AND TFL.%NotDel%
			INNER JOIN %Table:TFF% TFF ON TFF.TFF_FILIAL = %xFilial:TFF% 
										AND TFL.TFL_LOCAL = TFF.TFF_LOCAL 
										AND TFF.TFF_CONTRT = CN9.CN9_NUMERO 
										AND TFF.TFF_CONREV = CN9.CN9_REVISA 
										AND TFF.TFF_PRODUT = CNB.CNB_PRODUT 
										AND TFF.TFF_ITCNB = CNB.CNB_ITEM 
										AND TFF.%NotDel% 
			INNER JOIN %Table:ABS% ABS ON ABS.ABS_FILIAL = %xFilial:ABS% 
										AND ABS.ABS_LOCAL = TFF.TFF_LOCAL 
										AND ABS.%NotDel% 
			WHERE CN9.CN9_FILIAL = %xFilial:CN9%
				  AND CN9.CN9_NUMERO = %Exp:cContrt%
				  AND CN9.CN9_REVISA = %Exp:cRevCtr%
				  AND CN9.CN9_SITUAC = '05'
				  AND CN9.%NotDel%
			ORDER BY TFL.TFL_LOCAL
	EndSql

	// Monta o array com os locais encontrados para o contrato/revisão vigente
	While (cAliasTRB)->( ! Eof() )
		aAdd(aLocais,{(cAliasTRB)->TFL_LOCAL,;
				   		(cAliasTRB)->CN9_CONDPG,;
				      	(cAliasTRB)->CNA_CLIENT,;
				      	(cAliasTRB)->CNA_LOJACL,;
				      	(cAliasTRB)->CNB_PRODUT,;
				      	(cAliasTRB)->CNB_TS,;
				      	(cAliasTRB)->TFF_COD,;
				      	(cAliasTRB)->CNA_NUMERO,;
				      	 (cAliasTRB)->ABS_CODMUN,;
				      	 (cAliasTRB)->ABS_RECISS, ;
				      	 (cAliasTRB)->ABS_ESTADO})
		(cAliasTRB)->( dBSkip() )
	EndDo

	(cAliasTRB)->(dBCloseArea())
	
Else
	
	// Busca a revisão do contrato vigente, com as informações de local, planilha, cliente, produto, TES, etc para a geração dos pedidos de venda 
	BeginSql Alias cAliasTRB
		SELECT TWW.TWW_LOCAL,  TWW.TWW_CLIERH,   TWW.TWW_LOJARH, CN9.CN9_NUMERO,
				CN9.CN9_REVISA, CN9.CN9_CONDPG, CNA.CNA_CLIENT, CNA.CNA_LOJACL,
				CNA.CNA_NUMERO, CNB.CNB_PRODUT, CNB.CNB_TS, TFF.TFF_COD,
				ABS.ABS_CODMUN, ABS.ABS_RECISS, ABS.ABS_ESTADO
		FROM %Table:CN9% CN9
			INNER JOIN %Table:CNA% CNA ON CNA.CNA_FILIAL = %xFilial:CNA%
	 			                        AND CNA.CNA_CONTRA = CN9.CN9_NUMERO
	 			                       	AND CNA.CNA_REVISA = CN9.CN9_REVISA
	 			                       	AND CNA.%NotDel%
			INNER JOIN %Table:CNB% CNB ON CNB.CNB_FILIAL = %xFilial:CNB%
	 			                      	AND CNB.CNB_CONTRA = CN9.CN9_NUMERO
	 			                      	AND CNB.CNB_REVISA = CN9.CN9_REVISA
	 			                      	AND CNB.CNB_NUMERO = CNA.CNA_NUMERO
	 			                       	AND CNB.%NotDel%
			INNER JOIN %Table:TWW% TWW ON TWW.TWW_FILIAL = %xFilial:TWW%
	 			                     	AND TWW.TWW_CONTRT = CN9.CN9_NUMERO
	 			                       	AND TWW.TWW_REVISA = CN9.CN9_REVISA
	 			                       	AND TWW.TWW_PLANRH = CNB.CNB_NUMERO
	 			                      	AND TWW.%NotDel%
			INNER JOIN %Table:TFF% TFF ON TFF.TFF_FILIAL = %xFilial:TFF% 
										AND TWW.TWW_LOCAL = TFF.TFF_LOCAL 
										AND TFF.TFF_CONTRT = CN9.CN9_NUMERO 
										AND TFF.TFF_CONREV = CN9.CN9_REVISA 
										AND TFF.TFF_PRODUT = CNB.CNB_PRODUT 
										AND TFF.TFF_ITCNB = CNB.CNB_ITEM 
										AND TFF.%NotDel% 
				INNER JOIN %Table:ABS% ABS ON ABS.ABS_FILIAL = %xFilial:ABS% 
										AND ABS.ABS_LOCAL = TFF.TFF_LOCAL 
										AND ABS.%NotDel% 
			WHERE CN9.CN9_FILIAL = %xFilial:CN9%
				  AND CN9.CN9_NUMERO = %Exp:cContrt%
				  AND CN9.CN9_REVISA = %Exp:cRevCtr%
				  AND CN9.CN9_SITUAC = '05'
				  AND CN9.%NotDel%
			ORDER BY TWW.TWW_LOCAL
	EndSql
	
	// Monta o array com os locais encontrados para o contrato/revisão vigente
	While (cAliasTRB)->( ! Eof() )
		aAdd(aLocais,{(cAliasTRB)->TWW_LOCAL,;
				   		(cAliasTRB)->CN9_CONDPG,;
				      	(cAliasTRB)->TWW_CLIERH,;
				      	(cAliasTRB)->TWW_LOJARH,;
				      	(cAliasTRB)->CNB_PRODUT,;
				      	(cAliasTRB)->CNB_TS,;
				      	(cAliasTRB)->TFF_COD,;
				      	(cAliasTRB)->CNA_NUMERO,;
				      	 (cAliasTRB)->ABS_CODMUN,;
				      	 (cAliasTRB)->ABS_RECISS, ;
				      	 (cAliasTRB)->ABS_ESTADO})
		(cAliasTRB)->( dBSkip() )
	EndDo

	(cAliasTRB)->(dBCloseArea())
	
EndIf

Return(aLocais)

//--------------------------------------------------------------------
/*/{Protheus.doc} At935GrvPed()
@description	Função para gravar o numero do pedido gerado
@sample	 	At935GrvPed(aRecno,cNumPed)
@param			aRecno, Array onde está o recno dos registros a serem guardados o pedido de venda
@param			cNumPed, Numero do pedido de venda que foi gerado
@since			06/04/2017
@author	 	Luiz Gabriel Gomes de Jesus (luiz.jesus)
@version		P12.1.17
@return		.T.
/*/
//--------------------------------------------------------------------
Static Function At935GrvPed(aRecno,cNumPed)
Local nI	:= 0
Local nTam	:= Len(aRecno)

Default aRecno	:= {}

If nTam > 0
	For nI := 1 To nTam
		T46->( DbGoTo( aRecno[nI] ) )
		RecLock("T46",.F.)
			T46->T46_NUMPED := cNumPed					
		T46->(MsUnlock())	
	Next nI
EndIf

Return .T.

//--------------------------------------------------------------------
/*/{Protheus.doc} At935FilCtr()
@description	Função para realizar o filtro da consulta padrão TFJRGM
@sample	 	At935FilCtr()

@since			06/04/2017
@author	 	Luiz Gabriel Gomes de Jesus (luiz.jesus)
@version		P12.1.17
@return		.T.
/*/
//--------------------------------------------------------------------
Function At935FilCtr()
Local lFiltro	:= .F.

If TFJ->TFJ_STATUS=='1' .And. TFJ->TFJ_RGMCX =='1'  .And. !Empty(TFJ->TFJ_CONTRT)
	If Posicione("CN9",1,xFilial("CN9")+TFJ->TFJ_CONTRT+TFJ->TFJ_CONREV,"CN9_SITUAC") == '05'
		lFiltro	:= .T.
	EndIf
EndIf

Return lFiltro
