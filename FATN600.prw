#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "FATA600.CH"
#INCLUDE "DBTREE.CH"
#INCLUDE "MSOLE.CH"

#DEFINE FIELD_VIRTUAL 14
#DEFINE FIELD_IDFIELD  3
#DEFINE DEF_TFJ_ATIVO '1'			//TFJ_STATUS

Static _lBlqProp  	:= Ft600BlqProp()							// Define se a proposta comercial será bloqueada.
Static _lGeraOrc	:= SuperGetMv("MV_CRMGORC",,.T.)		// O pedido de vendas não será mais gerado de forma automática ao desabilitar o parâmetro. (Inicialmente criado para atender à TDI para não gravar mais CJ e CK, ao desabilitá-lo).
Static _lRoundPV	:= SuperGetMV("MV_FT600RD",,.F.)		// Aplica arredondamento no preco de venda da tabela de preco.
Static _cIniCond	:= SuperGetMV("MV_INICOND",,"")			// 1ª Sugestão de Condição de Pagamento p/os itens da Proposta Comercial
Static _lPETrigger	:= ExistBlock("FT600UTRIGGER")			// Ponto de entrada na execução das triggers das Grids da Proposta Comercial
Static _lPELoadGrid	:= ExistBlock("FT600ULGRID")			// Ponto de entrada na execução da 'carga' (Load) das grids da Proposta Comercial
Static _lFT600INI	:= ExistBlock("FT600INI")
Static _lFT600Sel	:= ExistBlock("FT600SEL")
Static _lFT600MCPrd	:= ExistBlock("FT600MCPRD")
Static _lFT600GRV	:= ExistBlock("FT600GRV") 				// Ponto de entrada acionado antes da gravacao da Proposta Comercial
Static _lFT600FGR	:= ExistBlock("FT600FGR") 				// Ponto de entrada acionado após a gravacao da Proposta Comercial e do Orçamento
Static _lFt600Tp09	:= ExistBlock("Ft600Tp09")				// P.E. para inicializar o array de tipo 09 quando não utilizar a gravação pelo orçamento(SCJ/SCK)
Static _lFt600EXC	:= ExistBlock("FT600EXC")				// Ponto de entrada para validacao do usuario
Static __cMdlDetail	:= ""

//-------------------------------------------------------------------
/*/{Protheus.doc} Ft600MdlAct

Após a ativação do Model da Proposta Comercial (MPFormModel) inicializa
alguns processos..

@author luiz.jesus
@since 18/03/2014
@version 12
/*/
//-------------------------------------------------------------------
Function Ft600MdlAct(oModel)

Local nOperation		:= oModel:GetOperation()
Local oMdlADY			:= oModel:GetModel("ADYMASTER")
Local oGridCusto		:= Nil
Local TMPGIM			:= GetNextAlias()
Local lFirst			:= .T.
Local lOrcPrc	  		:= SuperGetMv("MV_ORCPRC",,.F.)
Local lRemOrcServ		:= Nil
Local aItOrcSerRem	:= At600ARIOS()
Local aType9			:= {}
Local aCfgAlo			:= {}
Local aBenef			:= {} 

FT600MdlOport( oModel )

Ft600SetAloc( aCfgAlo )
FT600SetBen( aBenef )
FT600SetVis( .F. )
Ft600SetTipo09( aType9 )

If lOrcPrc .And. ValType(At740FGPC())=="O"
	At600STabPrc( "", "" )
	AT740FGXML(nil,nil,.T.)
EndIf

If nOperation == MODEL_OPERATION_INSERT

	If !Empty(AD1->AD1_CODCLI) //Considera Cliente
		oMdlADY:SetValue("ADY_CODIGO"	,AD1->AD1_CODCLI)
		oMdlADY:SetValue("ADY_LOJA"		,AD1->AD1_LOJCLI)
		oMdlADY:SetValue("ADY_DESENT"	,Posicione("SA1",1,xFilial("SA1")+AD1->AD1_CODCLI+AD1->AD1_LOJCLI,"A1_NOME"))
		oMdlADY:SetValue("ADY_ENTIDA"	,"1")
	Else //Considera Prospect
		oMdlADY:SetValue("ADY_CODIGO"	,AD1->AD1_PROSPE)
		oMdlADY:SetValue("ADY_LOJA"		,AD1->AD1_LOJPRO)
		oMdlADY:SetValue("ADY_DESENT"	,Posicione("SUS",1,xFilial("SUS")+AD1->AD1_PROSPE+AD1->AD1_LOJPRO,"US_NOME"))
		oMdlADY:SetValue("ADY_ENTIDA"	,"2")
	EndIf
	
	// -----------------------------------------------------+
	//  Carrega Grid Custos - Com todos default igual a SIM |
	// -----------------------------------------------------+
	If nModulo == 88 //Gestão de Transporte de Passageiros
	
		//-- Recupera objeto grid (Pasta Custpos)
		oGridCusto := oModel:GetModel("GIOCUSTOS")
	
		If oGridCusto <> NIl
	
			If Select(TMPGIM) > 0
				(TMPGIM)->(DbCloseArea())
			EndIf
		
			cQuery := " SELECT GIM.GIM_FILIAL, GIM.GIM_COD,"
			cQuery += " GIM.GIM_DESCRI, GIM.GIM_UM, GIM.GIM_CBASE"
			cQuery += " FROM " + RetSqlName("GIM") + " GIM "
			cQuery	+= " WHERE GIM_FILIAL = '"+xFilial("GIM")+"' "
			cQuery += " AND GIM_DEFAUL = '1' AND D_E_L_E_T_ = ' ' "
		
			dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),TMPGIM,.F.,.T.)
			
			(TMPGIM)->(DbGoTop())
			
			While (TMPGIM)->(!Eof() )
			
				If lFirst
					lFirst := .F.
				Else
					oGridCusto:AddLine()
				EndIf
				
				oGridCusto:SetValue("GIO_CUSTO"		, (TMPGIM)->GIM_COD )
				oGridCusto:SetValue("GIO_DCUSTO"	, (TMPGIM)->GIM_DESCRI )
				oGridCusto:SetValue("GIO_UM"		, (TMPGIM)->GIM_UM )
				oGridCusto:SetValue("GIO_DESUM"		, Posicione("SAH",1,xFilial("SAH")+(TMPGIM)->GIM_UM ,"AH_UMRES") )
				oGridCusto:SetValue("GIO_FORMUL"	, "2" )
				
				//-- Carrega campo Quantidade:
				//-- Qtdade 1 : Vlr. do custo maior que zero
				//-- Qtdade 0 : Vlr. do custo igual a zero
				If (TMPGIM)->GIM_CBASE > 0
					oGridCusto:LoadValue("GIO_QUANT"	, 1 )
				Else
					oGridCusto:LoadValue("GIO_QUANT"	, 0 )
				EndIf
				
				oGridCusto:LoadValue("GIO_CUSUNI"	, (TMPGIM)->GIM_CBASE )
				oGridCusto:SetValue("GIO_VALTOT"	, (TMPGIM)->GIM_CBASE  )
				
				(TMPGIM)->( DbSkip() )
				
			EndDo
			
			oGridCusto:GoLine(1)
			(TMPGIM)->(DbCloseArea())
		EndIf
	EndIf

ElseIf nOperation <> MODEL_OPERATION_DELETE

	//Inicializa o Array aTipo9
	IniTp09(oModel)
	A600CroFinance(oModel,.T.)	//Atualiza cronograma financeiro
	// Alteração na propriedade lModify do modelo, pois ao carregar as tabelas virtuais do cronograma financeiro
	// com loadvalue o modelo entende que houve alteração, e apresenta a mensagem de "deseja abandonar alteração
	// sem salvar", caso seja acionado o botão "Fechar".	
	oModel:lModify := .F.

EndIf

If _lFT600INI
	ExecBlock( "FT600INI", .F.,.F., {oModel} )
EndIf

lRemOrcServ := .F.
At600ARROS(lRemOrcServ)
aItOrcSerRem := {}
At600ARIOS(AClone(aItOrcSerRem))

Return(.T.)

//-------------------------------------------------------------------
/*/{Protheus.doc} FT600Cat
Aciona rotina de categoria e selecao de produto (FATA610 e
preenche a proposta com os produtos selecionados

@author CRM Vendas

@since 18/03/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function FT600Cat( oModel )
	
Local oMdlPrd		:= Nil
Local oMdlAce		:= Nil
Local aProduct 		:= {}
Local aPrdDetail	:= {}
Local nX			:= 0

Default oModel		:= FwModelActive()

If oModel <> Nil

	oMdlPrd := oModel:GetModel("ADZPRODUTO")
	oMdlAce := oModel:GetModel("ADZACESSOR")
		
	If ! _lFT600MCPrd
		aProdSel := FATA610() //Rotina de selecao de categoria e produtos
	Else
		aProdSel := ExecBlock("FT600MCPRD", .F.,.F., { oMdlPrd, oMdlAce } )
		If ValType(aProdSel) <> "A"
			aProdSel := {}
		EndIf
	EndIf
	
	For nX := 1 To Len(aProdSel)
		If aProdSel[nX][5] == "P"
			aAdd(aProduct ,{"ADZ_PRODUT", aProdSel[nX][1]})	//Codigo do produto
			aAdd(aProduct ,{"ADZ_QTDVEN", aProdSel[nX][6]}) //Quantidade
		EndIf
		aAdd(aPrdDetail, {aProduct, {}, .F., .F.})
		aProduct := {}
	Next nX
	
	If !Empty(aPrdDetail)
		FT600LoadGrid(oMdlPrd, aPrdDetail)
	EndIf
	
	If _lFT600Sel
		ExecBlock("FT600SEL", .F.,.F., {oMdlPrd, oMdlAce})
	EndIf
	
	If !oMdlPrd:IsEmpty()
		oMdlPrd:GoLine(1)
	EndIf
	
	If !oMdlAce:IsEmpty()
		oMdlAce:GoLine(1)
	EndIf
	
EndIf
	
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} A600TabPreco
@description	Retorna o preço de venda do produto
@author		Vendas CRM
@since			18/03/2014
@version		12
/*/
//-------------------------------------------------------------------
Function A600TabPreco(cTabPrc,cCodPro,nMoeda)

Local aAreaAtu	:= GetArea()   						//Guarda a area atual
Local nNumPRC 	:= 0 								//Preco do produto
Local nDcPrcVen	:= GetSX3Cache("ADZ_PRCVEN","X3_DECIMAL")

DEFAULT nMoeda	:= 1

DA1->(DbSetOrder(1))
If	DA1->(DbSeek(xFilial("DA1") + cTabPrc + cCodPro)) .AND. DA1->DA1_PRCVEN > 0
	nNumPRC := xMoeda(DA1->DA1_PRCVEN, DA1->DA1_MOEDA, nMoeda, dDataBase)
Else
	SB1->(DbSetOrder(1))
	If	SB1->(DbSeek(xFilial("SB1") + cCodPro))	.AND. SB1->B1_PRV1 > 0
		nNumPRC	:= xMoeda(SB1->B1_PRV1, val(SB1->B1_MCUSTD), nMoeda, dDataBase)
	Endif
Endif

If _lRoundPV
	nNumPRC := Round(nNumPRC, nDcPrcVen)
Endif
RestArea(aAreaAtu)
Return(nNumPRC)

//-------------------------------------------------------------------
/*/{Protheus.doc} At600Commit
Encapsula a gravação da proposta.

@author luiz.jesus
@since 18/03/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function At600Commit(oModel)

Local nOpcx			:= oModel:GetOperation()
Local lIntECM 		:= SuperGetMv("MV_CRMXECM",,.F.)
Local oMdlOpor		:= FT600MdlOport()
Local oMdlAD1		:= oMdlOpor:GetModel("AD1MASTER")
Local oMdlADY 		:= oModel:GetModel("ADYMASTER")
Local cPropos		:= oMdlADY:GetValue("ADY_PROPOS")
Local cPRevisa		:= oMdlADY:GetValue("ADY_PREVIS")
Local oMdlGridADZ	:= oModel:GetModel("ADZPRODUTO") 
Local nTmFolder		:= GetSX3Cache("ADZ_FOLDER","X3_TAMANHO")	// Variável para ajustar tamanho do campo Folder da proposta
Local nRecEst		:= 0
Local nX			:= 0
Local nLinha		:= 0
Local nY			:= 0
Local nDelTFJ		:= 0
Local nAba			:= 0
Local nCntFor		:= 0
Local cFolder		:= ""
Local cFilADZ		:= xFilial("ADZ")
Local lGrava		:= .T.
Local lRetorno		:= .F.

If nOpcx == MODEL_OPERATION_INSERT .Or. nOpcx == MODEL_OPERATION_UPDATE
	
	// Caso seja a cópia deverá ser limpado alguns campos do formulário, para tirar a relação com a proposta que está sendo copiada..
	If nOpcx == MODEL_OPERATION_INSERT .AND. AllTrim(oMdlGridADZ:GetValue("ADZ_ORCAME")) <> ""
		//Sendo a operação Cópia, limpar o orçamento de todos os itens para tirar a relção com a porposta que está sendo copiada.
		nLinha := 	oMdlGridADZ:GetLine() // guardando linha inicial
		For nX := 1 to oMdlGridADZ:Length()
			oMdlGridADZ:GoLine(nX)
			oMdlGridADZ:SetValue("ADZ_ORCAME","")
		Next nX
		oMdlGridADZ:GoLine(nLinha)
	EndIf
	
	//Ponto de entrada acionado antes da gravacao da Proposta Comercial e do Orçamento
	If _lFT600GRV
		lGrava := ExecBlock("FT600GRV", .F., .F., {oModel})
		If (ValType(lGrava) <> 'L')
			lGrava := .T.
		EndIf
	EndIf
	
	If lGrava
		
		Begin Transaction
			If At600RunProp(oModel)
				lRetorno := FWFormCommit(oModel)
			EndIf
		End Transaction
		
		If lRetorno

			ADZ->(DbSetOrder(3))	//ADZ_FILIAL+ADZ_PROPOS+ADZ_REVISA+ADZ_FOLDER+ADZ_ITEM
			For nAba := 1 to 2
				If nAba == 1
					cFolder := 'ADZPRODUTO'
				Else
					cFolder := 'ADZACESSOR'
				EndIf

				If !( oModel:GetModel(cFolder):IsEmpty() )

					//Atualização dos dados do orçamento
					For nCntFor := 1 To oModel:GetModel(cFolder):Length()

						oModel:GetModel(cFolder):GoLine(nCntFor)
						If !( oModel:GetModel(cFolder):IsDeleted() ) .And. !( Empty(oModel:GetModel(cFolder):GetValue("ADZ_PRODUT")) )
							If	ADZ->(DbSeek(cFilADZ +;
								             oModel:GetValue("ADYMASTER","ADY_PROPOS") +;
								             oModel:GetValue("ADYMASTER","ADY_PREVIS") +;
								             PadR(AllTrim(Str(nAba)), nTmFolder) +;
								             oModel:GetModel(cFolder):GetValue("ADZ_ITEM")))
								RecLock("ADZ",.F.)
								ADZ->ADZ_ORCAME := oModel:GetModel(cFolder):GetValue("ADZ_ORCAME")
								ADZ->ADZ_ITEMOR := oModel:GetModel(cFolder):GetValue("ADZ_ITEMOR")
								ADZ->(MsUnLock())
							EndIf
						EndIf

					Next nCntFor

				EndIf
			Next nAba

			//Calcula receita estimada da oportunidade a partir da proposta sincronizada
			If oModel:GetModel("ADYMASTER"):GetValue("ADY_SINCPR")
				nRecEst := Ft300REstPro(oModel:GetModel("ADYMASTER"):GetValue("ADY_PROPOS"))
				If nRecEst > 0
					oMdlAD1:LoadValue("AD1_VERBA",nRecEst)
					DbSelectArea("AD1")
					DbSetOrder(1)
					If DbSeek(xFilial("AD1")+oMdlAD1:GetValue("AD1_NROPOR")+oMdlAD1:GetValue("AD1_REVISA"))
						RecLock("AD1",.F.)
						AD1->AD1_VERBA := nRecEst
						AD1->(MsUnLock())
					EndIf
				EndIf
			EndIf

			//Ponto de entrada acionado após a gravacao da Proposta Comercial e do Orçamento
			If _lFT600FGR
				ExecBlock("FT600FGR", .F., .F., {oModel})
			EndIf
		EndIf
	EndIf
	
ElseIf nOpcx == MODEL_OPERATION_DELETE

	Begin Transaction
		// Existe orçamento de serviços do GS vinculado?
		TFJ->( DbSetOrder( 2 ) )
		// quando TFJ associada a proposta comercial guarda o recno para excluir o orçamento depois
		If TFJ->( DbSeek( xFilial("TFJ")+cPropos+cPRevisa ) )
			nDelTFJ := TFJ->(Recno())
		EndIf

		lRetorno := TFJ->( FWFormCommit(oModel,Nil,{|oModel,cId| A600EXCORC(oModel,cId)}) ) //Salvando os Dados do Formulario.

		// chama a exclusão do orçamento de serviços
		If lRetorno .And. nDelTFJ > 0
			lRetorno := TFJ->( At740Del(nDelTFJ) )
		EndIf

		If !lRetorno
			DisarmTransaction()
		EndIf
	End Transaction

EndIf

Return(.T.)

//-------------------------------------------------------------------
/*/{Protheus.doc} At600RunProp

Processa a Proposta Comercial.

@author luiz.jesus
@since 18/03/2014
@version 12
/*/
//-------------------------------------------------------------------
Static Function At600RunProp(oModel)

Local aArea			:= GetArea()
Local aAreaADZ		:= ADZ->(GetArea())
Local aOldArea		:= {}
Local cRevisAtu 		:= ""											// Numero da revisão atual
Local cNomeOrigem 	:= ""											// Nome do campo de origem
Local cNomeDest   	:= ""											// Nome do campo de destino
Local cFolder			:= ""			 								// Folder atual.
Local nCntFor 		:= 1
Local nPosDest    	:= 0											// Posição dos campos do AGP
Local nLoop       	:= 0								 			// Contador
Local nTmRevis		:= GetSX3Cache("ADY_PREVIS","X3_TAMANHO")	// Variável para ajustar tamanho do campo Revisao da prosposta
Local nX		  		:= 0											// Incremento utilizado para gravar a configuracao da alocacao de recurso.
Local nAba				:= 0
Local lRet				:= .T.
Local nOpcx			:= oModel:GetOperation()
Local aCamposADZ		:= {}
Local oStructADZ		:= Nil
Local oGetDadA		:= Nil
Local oGetDadP		:= Nil
Local lOrcPrc			:= SuperGetMv("MV_ORCPRC",,.F.)
Local lRemOrcServ		:= At600ARROS()
Local aAreaADY		:= {}
Local cFilADZ			:= xFilial("ADZ")
Local cFilAGP			:= xFilial("AGP")
Local cFilADY			:= xFilial("ADY")

// Verificar se essa proposta é a primeira da oportunidade, se for ela deve ser sincronizada
aAreaADY := ADY->( GetArea() )
ADY->(DbSetOrder(2))	//Filial + Nro da Oportunidade
If ADY->(! DbSeek(xFilial("ADY") + AD1->AD1_NROPOR)) //Busca todas as propostas da oportunidade
	oModel:LoadValue("ADYMASTER","ADY_SINCPR",.T.)
EndIf
RestArea(aAreaADY)

oModel:LoadValue("ADYMASTER","ADY_DTREVI",dDataBase)

//Incrementa a revisao da Proposta           
If nOpcx == MODEL_OPERATION_UPDATE .AND. !Empty(ADY->ADY_PREVIS)

	cRevisAtu := oModel:GetValue("ADYMASTER","ADY_PREVIS")
	oModel:LoadValue("ADYMASTER","ADY_PREVIS",Soma1(cRevisAtu, nTmRevis))
	
	//Efetua a gravacao na tabela espelho a partir da 2o. Revisao.
	DbSelectArea("AGP")
	AGP->(DbSetOrder(1))
	
	//Gravação dos Itens, atribui valores para a revisão e proposta
	If oModel:GetValue("ADYMASTER","ADY_PREVIS") >= "02"
		
		oModel:GetModel('ADZPRODUTO'):SetOnlyQuery(.T.)
		oModel:GetModel('ADZACESSOR'):SetOnlyQuery(.T.)
		
		//Pega a Estrutura da ADZ para realizar a gravação
		oStructADZ		:= oModel:GetModel('ADZPRODUTO'):GetStruct()
		aCamposADZ		:= oStructADZ:GetFields()
		
		For nAba := 1 to 2
			If nAba == 1
				cFolder := 'ADZPRODUTO'
			Else
				cFolder := 'ADZACESSOR'
			EndIf

			If !( oModel:GetModel(cFolder):IsEmpty() )

				//Gravacao dos Itens
				For nCntFor := 1 To oModel:GetModel(cFolder):Length()

					oModel:GetModel(cFolder):GoLine(nCntFor)
					If !( oModel:GetModel(cFolder):IsDeleted() ) .And. !( Empty(oModel:GetModel(cFolder):GetValue("ADZ_PRODUT")) )
						RecLock("ADZ",.T.)
						For nX := 1 To Len(aCamposADZ)
							If !( aCamposADZ[nX][MODEL_FIELD_VIRTUAL] )
								FieldPut( FieldPos( aCamposADZ[nX][MODEL_FIELD_IDFIELD] ), oModel:GetModel(cFolder):GetValue(aCamposADZ[nX][MODEL_FIELD_IDFIELD]) )
							EndIf
						Next nX
						ADZ->ADZ_REVISA := oModel:GetValue("ADYMASTER","ADY_PREVIS")
						ADZ->ADZ_PROPOS := oModel:GetValue("ADYMASTER","ADY_PROPOS")
						ADZ->ADZ_FOLDER := AllTrim(Str(nAba))	//Folder 1 = Produtos ## Folder 2 = Acessórios
						ADZ->ADZ_FILIAL := cFilADZ
						ADZ->(MsUnLock())
					EndIf

				Next nCntFor

			EndIf
		Next nAba
		
		RecLock("AGP", .T.)
		For nLoop := 1 To ADY->(FCount())
			cNomeOrigem := ADY->(FieldName(nLoop))
			cNomeDest   := "AGP" + SubStr(cNomeOrigem, 4, 7)
			If AllTrim(cNomeDest) == "AGP_FILIAL"
				AGP->AGP_FILIAL := cFilAGP
			Else
				If !Empty(nPosDest := AGP->(FieldPos(cNomeDest)))
					AGP->(FieldPut(nPosDest, ADY->(FieldGet(nLoop))))
				EndIf
			EndIf
		Next nLoop
		AGP->(MsUnLock())
		
	EndIf
	
EndIf

//Informa se a Proposta será Bloqueada
If ( _lBlqProp := Ft600BlqProp() )
	oModel:LoadValue("ADYMASTER","ADY_STATUS","F")
Else
	oModel:LoadValue("ADYMASTER","ADY_STATUS","A")
EndIf

If !Empty(oGetDadP)
	A600GrvAloc(oModel:GetValue("ADYMASTER","ADY_PREVIS"), oGetDadP)
Else
	oGetDadP := oModel:GetModel("ADZPRODUTO")
	oGetDadA := oModel:GetModel("ADZACESSOR")
	A600GrvAloc(oModel:GetValue("ADYMASTER","ADY_PREVIS"), oGetDadP, oGetDadA)
EndIf

//Sicroniza a proposta, caso seja para sincronizar.
If oModel:GetValue("ADYMASTER","ADY_SINCPR")
	
	aOldArea	:= GetArea()
	ADY->(DbSetOrder(2))    //Filial + Nro da Oportunidade
	ADY->(DbGoTop())
	If ADY->(DbSeek(cFilADY + AD1->AD1_NROPOR)) //Busca todas as propostas da oportunidade
		While ADY->(! Eof()) .AND. ADY->ADY_FILIAL == cFilADY .AND. AD1->AD1_NROPOR == ADY->ADY_OPORTU

			If ADY->ADY_PROPOS <> FWFldGet("ADY_PROPOS")
				RecLock("ADY",.F.)
				ADY->ADY_SINCPR := .F. //Atualiza todas as propostas como não sincronizadas
				ADY->(MsUnlock())
			EndIf

			ADY->(DbSkip())
		EndDo
	EndIf
	RestArea(aOldArea)

EndIf

If !lRemOrcServ
	//Atualização do número da revisão
	DbSelectArea('TFJ')
	TFJ->( DbSetOrder( 4 ) ) //TFJ_FILIAL+TFJ_STATUS+TFJ_PROPOS+TFJ_PREVIS
		
	If TFJ->( DbSeek( xFilial('TFJ')+DEF_TFJ_ATIVO+oModel:GetValue("ADYMASTER","ADY_PROPOS")+cRevisAtu ) )
		RecLock("TFJ",.F.)
		TFJ->TFJ_PREVIS	:= oModel:GetValue("ADYMASTER","ADY_PREVIS") 
		MsUnLock()
	EndIf
Else
	// Remove o orçamento de serviços
	DbSelectArea('TFJ')
	TFJ->( DbSetOrder( 4 ) ) //TFJ_FILIAL+TFJ_STATUS+TFJ_PROPOS+TFJ_PREVIS
		
	If TFJ->( DbSeek( xFilial('TFJ')+DEF_TFJ_ATIVO + oModel:GetValue("ADYMASTER","ADY_PROPOS")+cRevisAtu ) )
		lRet := lRet .And. At740Del( TFJ->(Recno()) )
	EndIf	
EndIf // -> condição de remoção do orçamento de serviço

If lOrcPrc // Zera a tabela de precificação
	At600STabPrc( "", "" )
	AT740FGXML(,,.T.) // elimina as referências de memória do TECA740F
EndIf

//Grava o orcamento de vendas (SCJ/SCK)
If _lGeraOrc
	lRet	:= At600Orc(oModel:GetValue("ADYMASTER","ADY_PROPOS"), oModel:GetValue("ADYMASTER","ADY_OPORTU"), oModel:GetValue("ADYMASTER","ADY_REVISA"),;
	    	            oModel:GetValue("ADYMASTER","ADY_ENTIDA"), oModel:GetValue("ADYMASTER","ADY_CODIGO"), oModel:GetValue("ADYMASTER","ADY_LOJA"),;
	    	            oModel:GetValue("ADYMASTER","ADY_DESENT"), nOpcx,                                     oModel:GetValue("ADYMASTER","ADY_TABELA"),;
	    	            oModel)
EndIf

RestArea(aAreaADZ)
RestArea(aArea)
Return(lRet)

//-------------------------------------------------------------------
/*/{Protheus.doc} A600VdOp
Verifica se tem itens da Proposta Comercial para atualizar na
Oportunidade e atualiza o cabacalho da oportunidade

@author luiz.jesus
@since 18/03/2014
@version 12
/*/
//-------------------------------------------------------------------
Function A600VdOp(cOportunida, cRevisao, cOrcamento, aItensOrc,;
                  aItemOpor,   oModel,   cProposta)

Local aArea		 	:= GetArea()
Local aAreaADZ	 	:= ADZ->(GetArea())
Local nI         	:= 0																	//Indice do laco
Local nPosProdut 	:= 0																	//Posicao do campo produto no array
Local nPosItem	 	:= 0																	//Posicao do campo Item
Local nPosNumOrc 	:= 0																	//Posicao do campo Num. Orcamento
Local nPosPropost	:= 0																	//Posicao do campo Prosposta
Local nAUTDELETA 	:= 0																	//Posicao do AUTDELETA
Local aHeadItens 	:= oModel:GetModel("ADZPRODUTO"):GetOldData()
Local aHeadAcess	:= oModel:GetModel("ADZACESSOR"):GetOldData()
Local nItItem	 	:= aScan(aHeadItens[1], {|x| AllTrim(x[2]) == "ADZ_ITEM"})		//Posicao do item (produtos da proposta)
Local nItProp	 	:= aScan(aHeadItens[1], {|x| AllTrim(x[2]) == "ADZ_PROPOS"})	//Posicao da proposta (produtos da proposta)
Local nItOrca	 	:= aScan(aHeadItens[1], {|x| AllTrim(x[2]) == "ADZ_ORCAME"})	//Posicao do orcamento(produtos da proposta)
Local nItProd	 	:= aScan(aHeadItens[1], {|x| AllTrim(x[2]) == "ADZ_PRODUT"})	//Posicao do produto (produtos da proposta)
Local nItItemFol	:= aScan(aHeadItens[1], {|x| AllTrim(x[2]) == "ADZ_FOLDER"})	//Posicao do item-Folder (Produtos ou Acessorios)
Local nPosOport	 	:= 0
Local nPItProOrc	:= 0		//Posicao do item da proposta no item do orcamento
Local nPFolder		:= 0		//Posicao do item no folder (Produtos ou Acessorios)
Local nOpAd1		:= 0
Local cFolder		:= ""
Local oMdlOpor		:= FT600MdlOport()
Local oMdlADJ		:= oMdlOpor:GetModel("ADJDETAIL")
Local oStructADJ 	:= oMdlADJ:GetStruct()
Local nOpcADJ		:= SuperGetMv("MV_FATMNTP",,1)
Local cFilADJ		:= xFilial("ADJ")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³A variavel nOpcADJ, utilizada para  pode ter 3 valores:                                ³
//³1 - Apaga registros manuais e considera somente os das propostas                       ³
//³2 - Mantem o registro lancado na ADJ manualmente e exibe os registros das propostas    ³
//³3 - Mantem os manuais e não exibe (apesar de gravar) os registros gerados por propostas³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

//Copia os produtos que estão no acols par realizar a busca
For nI := 1 to Len(aHeadItens[2])
	aAdd(aItemOpor,aClone(aHeadItens[2][nI]))
Next nI

For nI := 1 to Len(aHeadAcess[2])
	aAdd(aItemOpor,aClone(aHeadAcess[2][nI]))
Next nI

If nOpcADJ == 1
	ADJ->(DbSetOrder(3))
	ADJ->(dbSeek(cFilADJ + cOportunida + cRevisao))
	While ADJ->(! Eof()) .AND. ADJ->ADJ_FILIAL == cFilADJ .AND. ADJ->ADJ_NROPOR == cOportunida .AND. ADJ->ADJ_REVISA == cRevisao 
		If	Empty(ADJ->ADJ_PROPOS) .AND. Empty(ADJ->ADJ_NUMORC)
			RecLock("ADJ",.F.)
			ADJ->(dbDelete())
			MsUnlock()
		EndIf
		ADJ->(dbSkip())
	EndDo
EndIf

If oModel:GetModel("ADYMASTER"):GetValue("ADY_SINCPR")
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Permissao para Grid de Produtos da Oportunidade de Venda. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oStructADJ:SetProperty("*",MODEL_FIELD_WHEN,{||.T.})
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Limpa o ModelGrid de Produtos da Oportunidade de Venda. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If nOpcADJ <> 4 .And. !oMdlADJ:IsEmpty()
		If oMdlADJ:IsOnlyQuery()
			oMdlADJ:ClearData(.F.)
			oMdlADJ:InitLine()
			oMdlADJ:GoLine(1)
		Else
			For nI := 1 To oMdlADJ:Length()
				oMdlADJ:GoLine(nI)
				oMdlADJ:DeleteLine()
			Next nI
		EndIf
	EndIf
EndIf

If _lGeraOrc .AND. nOpcADJ <> 4
	For nI := 1 To Len(aItensOrc)
		
		nPosProdut		:= aScan(aItensOrc[nI], {|x| RTrim(x[1]) == "CK_PRODUTO"})
		nPosItem		:= aScan(aItensOrc[nI], {|x| RTrim(x[1]) == "CK_ITEM"})
		nPosNumOrc		:= aScan(aItensOrc[nI], {|x| RTrim(x[1]) == "CK_NUM"})
		nPosPropost	:= aScan(aItensOrc[nI], {|x| RTrim(x[1]) == "CK_PROPOST"})
		nAUTDELETA		:= aScan(aItensOrc[nI], {|x| RTrim(x[1]) == "AUTDELETA"})
		nPItProOrc		:= aScan(aItensOrc[nI], {|x| RTrim(x[1]) == "CK_ITEMPRO"})
		nPFolder		:= aScan(aItensOrc[nI], {|x| RTrim(x[1]) == "CK_FOLDER"})
		
		//Faz a busca pelo produto gravado no orçamento para atualização na proposta
		nPosOport		:= aScan(aItemOpor,{|x| (AllTrim(x[nItItem]) == AllTrim(aItensOrc[nI][nPItProOrc][2]))       .AND.;
		         		                        (AllTrim(x[nItItemFol]) == AllTrim(aItensOrc[nI][nPFolder][2]))      .AND.;
		         		                        (AllTrim(x[nItProd]) == AllTrim(aItensOrc[nI][nPosProdut][2]))       .AND.;
		         		                        (x[nItProp] == aItensOrc[nI][nPosPropost][2] .OR. Empty(x[nItProp])) .AND.;
		         		                        (x[nItOrca] == aItensOrc[nI][nPosNumOrc][2]  .OR. Empty(x[nItOrca]))})

		If nPosOport > 0
			If aItemOpor[nPosOport][nItItemFol] == "1"
				cFolder := "ADZPRODUTO"
			ElseIf aItemOpor[nPosOport][nItItemFol] == "2"
				cFolder := "ADZACESSOR"
			EndIf
			If !( Empty(cFolder) )
				oModel:GetModel(cFolder):GoLine(Val(aItemOpor[nPosOport][nItItem]))
				oModel:GetModel(cFolder):SetValue("ADZ_ORCAME", cOrcamento)
				oModel:GetModel(cFolder):SetValue("ADZ_ITEMOR", aItensOrc[nI][nPosItem][2])
			EndIf
		EndIf
		
		If	aItensOrc[nI][nAUTDELETA][2] == "S" .AND. ( nPosOport == 0 .OR. nPosOport <> 0 ) 
			nOpAd1 := 5 //Exclui
		ElseIf	nPosOport <> 0
			nOpAd1 := 4 //Altera
		Else
			nOpAd1 := 3 //Inclui
		Endif
		
		A600GrOp(nOpAd1, nI, cOportunida, cRevisao, aItensOrc, cProposta, oModel, oMdlADJ)
		
	Next nI
ElseIf nOpcADJ == 4
	nOpAd1 := 3 //Alteração
	A600GrOp(nOpAd1, 1, cOportunida, cRevisao, aItensOrc, cProposta, oModel, oMdlADJ)
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Posiciona na primeira linha dos Produtos da Oportunidade. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If oMdlADJ:Length() > 0
	oMdlADJ:GoLine(1)
EndIf

If oModel:GetModel("ADYMASTER"):GetValue("ADY_SINCPR")
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Permissao para Grid de Produtos da Oportunidade de Venda. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oStructADJ:SetProperty("*",MODEL_FIELD_WHEN,{||.F.})
EndIf

RestArea(aAreaADZ)
RestArea(aArea)
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} A600GrOp
Atualiza os itens da Proposta Comercial na Oportunidade

@author luiz.jesus

@since 18/03/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function A600GrOp(nOpcOpor, nLinha, cOportunida, cRevisao,;
                         aItensOrc, cProposta, oModel, oMdlADJ)

Local lInclui	 	:= .F.
Local nPosProdut	:= 0
Local nPosPrUnit	:= 0
Local nPosPrTab 	:= 0
Local nPosQtdVen	:= 0
Local nPosDescon	:= 0
Local nPosValdes	:= 0
Local nPosOrcame	:= 0
Local nPosItem	:= 0
Local nPosNumOrc	:= 0
Local nPosPropost	:= 0
Local nY			:= 0
Local nOpcADJ	 	:= SuperGetMv("MV_FATMNTP",,1)
Local cCategoria 	:= ""
Local lForceLin	:= .T.
Local oStructADJ	:= oMdlADJ:GetStruct()
Local aCamposADJ	:= oStructADJ:GetFields()
Local cValItem	:= ""
Local nTmADJItem	:= GetSx3Cache("ADJ_ITEM","X3_TAMANHO")
Local nTmADZItem	:= GetSx3Cache("ADZ_ITEM","X3_TAMANHO")
Local cFilACU		:= xFilial("ACU")
Local cFilADJ		:= xFilial("ADJ")

If _lGeraOrc
	nPosProdut		:= aScan(aItensOrc[nLinha], {|x| RTrim(x[1]) == "CK_PRODUTO"}) 	//Posicao do campo produto
	nPosPrUnit		:= aScan(aItensOrc[nLinha], {|x| RTrim(x[1]) == "CK_PRCVEN"})  	//Posicao do campo preco unitario
	nPosPrTab		:= aScan(aItensOrc[nLinha], {|x| RTrim(x[1]) == "CK_PRCTAB"})  	//Posicao do campo preco de tabela
	nPosQtdVen		:= aScan(aItensOrc[nLinha], {|x| RTrim(x[1]) == "CK_QTDVEN"}) 		//Posicao do campo quantidade
	nPosDescon		:= aScan(aItensOrc[nLinha], {|x| RTrim(x[1]) == "CK_DESCONT"}) 	//Posicao do campo percentual de desconto
	nPosValdes		:= aScan(aItensOrc[nLinha], {|x| RTrim(x[1]) == "CK_VALDESC"}) 	//Posicao do campo valor do desconto
	nPosOrcame		:= aScan(aItensOrc[nLinha], {|x| RTrim(x[1]) == "CK_NUM"}) 			//Posicao do campo numero do orcamento
	nPosItem		:= aScan(aItensOrc[nLinha], {|x| RTrim(x[1]) == "CK_ITEM"}) 		//Posicao do campo Item
	nPosNumOrc		:= aScan(aItensOrc[nLinha], {|x| RTrim(x[1]) == "CK_NUM"}) 			//Posicao do campo Num. Orcamento
	nPosPropost	:= aScan(aItensOrc[nLinha], {|x| RTrim(x[1]) == "CK_PROPOST"})		//Posicao do campo Prosposta
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Localiza categoria³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If 	nOpcOpor <> 5
		
		DbSelectArea("ACV")
		DbSetOrder(5)	//ACV_FILIAL+ACV_CODPRO+ACV_CATEGO
		If 	ACV->(DbSeek(xFilial("ACV") + aItensOrc[nLinha][nPosProdut][2]))

			cCategoria := ACV->ACV_CATEGO
			dbSelectArea("ACU")
			dbSetorder(1)
			If	ACU->(DbSeek(cFilACU + cCategoria))
				cCategoria		:= ACU->ACU_CODPAI
				While ACU->(! Eof() )
					ACU->(DbSeek(cFilACU + ACU->ACU_CODPAI))
					If	Empty(ACU->ACU_CODPAI)
						cCategoria		:= ACU->ACU_COD
						EXIT
					Endif
				Enddo
			Endif

		EndIf
	EndIf
EndIf

DbSelectArea("ADJ")

//-------------------------------------------------------------------------------
// Quando o ADJ for referente à agrupador grava apenas campos essenciais para
// integridade do relacionamento da ADJ e para não trazer complicações com a
// execução da ExecAuto().
//-------------------------------------------------------------------------------
If nOpcADJ == 4

	ADJ->(DbSetOrder(1))
	lInclui := ADJ->(! DbSeek(cFilADJ + cOportunida + cRevisao))
	RecLock("ADJ", lInclui)
	If nOpcOpor <> 5
		ADJ->ADJ_FILIAL    	:= cFilADJ
		ADJ->ADJ_NROPOR    	:= cOportunida
		ADJ->ADJ_REVISA    	:= cRevisao
		//Grava proposta sincronizada.
		If !( Empty(oModel:GetModel("ADYMASTER"):GetValue("ADY_SINCPR")) )
			ADJ->ADJ_PROPOS		:= cProposta
			If _lGeraOrc
				ADJ->ADJ_NUMORC	:= aItensOrc[nLinha][nPosOrcame][2]
			EndIf
		EndIf
		ADJ->ADJ_HISTOR		:= "2"
	EndIf
	ADJ->(MsUnlock())
	
Else
	
	If nTmADJItem > nTmADZItem
		cValItem := StrZero(0, nTmADJItem - nTmADZItem)
	ElseIf	nTmADJItem == nTmADZItem
		cValItem := ""	
	EndIf
	
	ADJ->(DbSetOrder(4)) //ADJ_FILIAL+ADJ_NROPOR+ADJ_REVISA+ADJ_PROPOS+ADJ_NUMORC+ADJ_ITEM
	lInclui := ADJ->(! DbSeek(cFilADJ +;
	                          cOportunida +;
	                          cRevisao +;
	                          aItensOrc[nLinha][nPosPropost][2] +;
	                          aItensOrc[nLinha][nPosNumOrc][2] +;
	                          IIf(! Empty(cValItem),;
	                              ( cValItem + aItensOrc[nLinha][nPosItem][2] ),;
	                              aItensOrc[nLinha][nPosItem][2])))
	
	RecLock("ADJ", lInclui)
	If nOpcOpor <> 5
		ADJ->ADJ_FILIAL    	:= cFilADJ
		ADJ->ADJ_NROPOR    	:= cOportunida
		ADJ->ADJ_REVISA    	:= cRevisao
		ADJ->ADJ_CATEG     	:= cCategoria
		ADJ->ADJ_PROD      	:= aItensOrc[nLinha][nPosProdut][2]
		ADJ->ADJ_QUANT     	:= aItensOrc[nLinha][nPosQtdVen][2]
		If _lGeraOrc
			If	aItensOrc[nLinha][nPosValdes][2] > 0 .OR. aItensOrc[nLinha][nPosDescon][2] > 0
				ADJ->ADJ_PRUNIT    	:= (aItensOrc[nLinha][nPosPrUnit][2]*aItensOrc[nLinha][nPosQtdVen][2]-aItensOrc[nLinha][nPosValdes][2])/aItensOrc[nLinha][nPosQtdVen][2]
				ADJ->ADJ_VALOR     	:= (aItensOrc[nLinha][nPosPrUnit][2]*aItensOrc[nLinha][nPosQtdVen][2]-aItensOrc[nLinha][nPosValdes][2])/aItensOrc[nLinha][nPosQtdVen][2]*aItensOrc[nLinha][nPosQtdVen][2]
			Else
				ADJ->ADJ_PRUNIT    	:= aItensOrc[nLinha][nPosPrUnit][2]
				ADJ->ADJ_VALOR     	:= aItensOrc[nLinha][nPosPrUnit][2]*aItensOrc[nLinha][nPosQtdVen][2]
			Endif
			//--- CRIAR PONTO DE ENTRADA OU PARAMETRO PARA A GRAVACAO DOS CAMPOS ABAIXO
			//ADJ->ADJ_TPVEND		:= cTpVend
			ADJ->ADJ_PROPOS		:= cProposta
			ADJ->ADJ_NUMORC		:= aItensOrc[nLinha][nPosOrcame][2]
			ADJ->ADJ_ITEM     	:= Iif(! Empty(cValItem), cValItem + aItensOrc[nLinha][nPosItem][2], aItensOrc[nLinha][nPosItem][2])
			ADJ->ADJ_HISTOR		:= "2"
		EndIf
	Else
		ADJ->(DbDelete())
	EndIf
	ADJ->(MsUnlock())
	
	If oModel:GetModel("ADYMASTER"):GetValue("ADY_SINCPR") .AND. nOpcOpor <> 5
		// Sempre inclui novas linhas no ModelGrid de Produtos da Oportunidade.
		If !oMdlADJ:IsEmpty() .OR. oMdlADJ:IsDeleted()
			nLinha := oMdlADJ:AddLine(lForceLin)
			oMdlADJ:GoLine(nLinha)
		EndIf
		
		For nY := 1 To Len(aCamposADJ)
			If !aCamposADJ[nY][MODEL_FIELD_VIRTUAL]
				oMdlADJ:SetValue(aCamposADJ[nY][3]	,&("ADJ->"+aCamposADJ[nY][3]))
			EndIf
		Next nY
		
		oMdlADJ:SetOnlyQuery(.T.)
		oMdlADJ:SetNoInsertLine(.T.)
		oMdlADJ:SetNoDeleteLine(.T.)
		
	EndIf
	
EndIf

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} At600Prd
Preenche a lista de produtos acessorios referentes ao item atual
( Função usada somente pelo SIGATEC TECA270 )

@author luiz.jesus

@since 18/03/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function At600Prd(cProduto)

Local aArea		:= GetArea()
Local aAreaSB1	:= SB1->(GetArea())
Local aRet		:= {}
Local cCateg	:= ""

DbSelectArea("SB1")
DbSetOrder(1)

If DbSeek(xFilial("SB1")+cProduto)

	AAdd(aRet,{SB1->B1_COD,SB1->B1_DESC,cCateg,"000000","P",1})

	//Valida a existencia de acessorios (KIT) para o produto selecionado
	A610Acessorio(SB1->B1_COD,cCateg,@aRet)

EndIf

RestArea(aAreaSB1)
RestArea(aArea)
Return aRet

//-------------------------------------------------------------------
/*/{Protheus.doc} IniTp09
Inicializa o vetor aTipo09 com as parcelas previamente salvas.

@author luiz.jesus

@since 18/03/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function IniTp09(oModel)

Local aArea			:= GetArea()
Local aAreaSCJ		:= {}
Local aAreaSCK		:= {}
Local nAba			:= 0
Local nIt			:= 0
Local aCols			:= {}
Local aHeader		:= {}
Local nPProd		:= 0
Local nPOrc			:= 0
Local nPOrcIt		:= 0
Local nPItem		:= 0
Local nPPrcVen		:= 0
Local nNumParc		:= SuperGetMv("MV_NUMPARC")
Local cProxParc		:= ""
Local nVlParc		:= 0
Local nPc			:= 0
Local oMdlPrd		:= Nil
Local aModelPrd 	:= Nil
Local oMdlAces		:= Nil
Local aModelAces 	:= Nil
Local dDtVenc		:= Nil
Local cFilSCK		:= xFilial("SCK")
Local cFilSCJ		:= xFilial("SCJ")
Local cFilSE4		:= xFilial("SE4")

If _lGeraOrc
	
	aAreaSCJ	:= SCJ->(GetArea())
	aAreaSCK	:= SCK->(GetArea())
	
	oMdlPrd	:= oModel:GetModel('ADZPRODUTO')
	aModelPrd	:= oMdlPrd:GetOldData()
	oMdlAces	:= oModel:GetModel('ADZACESSOR')
	aModelAces	:= oMdlAces:GetOldData()

	SE4->(dbSetOrder(1))	//E4_FILIAL+E4_CODIGO
	SCJ->(DbSetOrder(1))	//CJ_FILIAL+CJ_NUM+CJ_CLIENTE+CJ_LOJA
	SCK->(DbSetOrder(1)) //CK_FILIAL+CK_NUM+CK_ITEM+CK_PRODUTO
	For nAba := 1 to 2
		If nAba == 1
			aCols		:= aModelPrd[2]
			aHeader	:= aModelPrd[1]
		Else
			aCols		:= aModelAces[2]
			aHeader	:= aModelAces[1]
		EndIf

		nPProd		:= aScan(aModelPrd[1],{|x| AllTrim(x[2]) == "ADZ_PRODUT"})
		nPOrc		:= aScan(aModelPrd[1],{|x| AllTrim(x[2]) == "ADZ_ORCAME"})
		nPOrcIt		:= aScan(aModelPrd[1],{|x| AllTrim(x[2]) == "ADZ_ITEMOR"})
		nPItem		:= aScan(aModelPrd[1],{|x| AllTrim(x[2]) == "ADZ_ITEM"})
		nPPrcVen	:= aScan(aModelPrd[1],{|x| AllTrim(x[2]) == "ADZ_PRCVEN"})
               
		For nIt := 1 to Len(aCols)
			If  SCK->(DbSeek(cFilSCK + aCols[nIt][nPOrc] + aCols[nIt][nPOrcIt] + aCols[nIt][nPProd]))
				SCJ->(DbSeek(cFilSCJ + SCK->CK_NUM + SCK->CK_CLIENTE + SCK->CK_LOJA ))
				SE4->(DbSeek(cFilSE4 + SCJ->CJ_CONDPAG))

				If	SE4->E4_TIPO == "9"
					cProxParc := "0"
					For nPc := 1 To nNumParc
						cProxParc	:= Soma1(cProxParc)
						dDtVenc	:= &("SCJ->CJ_DATA"+cProxParc)
						If AllTrim(SE4->E4_COND) = "0"
							nVlParc	:= &("SCJ->CJ_PARC"+cProxParc)
						Else
							nVlParc	:= (&("SCJ->CJ_PARC"+cProxParc)/100) * aCols[nIt][nPPrcVen]
						EndIf
						If	nVlParc > 0
							aTipo09 := Ft600GetTipo09() //Get do valor da variável estática
							aAdd(aTipo09, {SCK->CK_PRODUTO,   dDtVenc,    nVlParc,   SCJ->CJ_CONDPAG, aCols[nIt][nPItem], AllTrim(Str(nAba))})
							Ft600SetTipo09(aTipo09)
						Endif
					Next nPc
				Endif
				
			EndIf
		Next nIt
	Next nAba
	RestArea(aAreaSCJ)
	RestArea(aAreaSCK)
Else
	If _lFt600Tp09 .And. !_lGeraOrc
		aTipo09	:= ExecBlock("Ft600Tp09", .F., .F., {oModel})
		Ft600SetTipo09(aTipo09)
	EndIf
EndIf

RestArea(aArea)
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} A600Pack
Remove os itens nao selecionados do array(aCols ou nao)

@author SQUAD CRM/Faturamento

@since   12/12/2017
@version 2.0
/*/
//-------------------------------------------------------------------
Function A600Pack(oModel)
	Local aRet		:= {}	
	Local nLength	:= 0
	Local nLoop		:= 0
	Local oMdlPrd	:= Nil 
	Local oMdlAces	:= Nil 
	Local nLnProd	:= 0
	Local nLnAces	:= 0
	
	Default oModel	:= Nil 
	
	If oModel <> Nil 
		oMdlPrd	:= oModel:GetModel('ADZPRODUTO')
		oMdlAces	:= oModel:GetModel('ADZACESSOR')
		nLnProd	:= oMdlPrd:GetLine()
		nLnAces := oMdlAces:GetLine()
		
		If !oMdlPrd:IsEmpty()
			nLength := oMdlPrd:Length()	
			For nLoop := 1 to nLength
				oMdlPrd:GoLine(nLoop)
				If !oMdlPrd:Isdeleted()
					aAdd(aRet,oMdlPrd:Acols[nLoop] )
				EndIf
			Next nLoop
		EndIf
		
		If !oMdlAces:IsEmpty()
			nLength := oMdlAces:Length()
			For nLoop := 1 to nLength
				oMdlAces:GoLine(nLoop)
				If !oMdlAces:Isdeleted()
					aAdd(aRet,oMdlAces:Acols[nLoop] )
				EndIf
			Next nLoop
		EndIf
		
		oMdlPrd:GoLine(nLnProd)
		oMdlAces:GoLine(nLnAces)
	EndIf
	
Return aRet

//-------------------------------------------------------------------
/*/{Protheus.doc} A600Del
Delecao de itens

@author luiz.jesus

@since 18/03/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function A600Del(nGetNum, oModelPar)

Local lRet			:= .T.
Local oModel		:= If( ValType(oModelPar) == "O", oModelPar, FwModelActive() )
Local oMdlProd	:= oModel:GetModel("ADZPRODUTO")
Local oMdlAces	:= oModel:GetModel("ADZACESSOR")
Local nPItem		:= aScan(aHeader,{|x| AllTrim(x[2]) == "ADZ_ITEM"})
Local cCodVis		:= ""
Local cItemVi		:= ""
Local nX			:= 0
Local lCtrlDel	:= SuperGetMv("MV_PROPDEL",,.T.)
Local cFolder		:= If(nGetNum == 1,"ADZPRODUTO","ADZACESSOR")
Local lIsOrc		:= .T.
Local lRemOrcServ	:= .T.

If oModel <> Nil

	lIsOrc			:= IsItOrcServ( oMdlProd:GetValue("ADZ_ITEM") )
	lRemOrcServ	:= At600ARROS()
	                   
	If (lRemOrcServ .Or. ( nGetNum == 1 .And. lIsOrc )) .And.;
		!oMdlProd:IsDeleted() .And. ! IsInCallStack("At600SeExc")
		lRet := .F.
		Help(,,'DELORCSER',, STR0204,1,0) // 'Não é possível excluir diretamente um orçamento de serviços, realize pela opção no ações relacionadas'
	ElseIf oMdlProd:IsDeleted() .And. lIsOrc
		lRet := .F.
		Help(,,'DELLINSERV',, STR0211,1,0) // 'Não é permitido reativar uma linha deletada pela importação dos produtos referência'
	EndIf
	
	If lRet
		
		If !Empty(oModel:GetModel(cFolder):GetValue("ADZ_CODVIS")) .AND. !Empty(oModel:GetModel(cFolder):GetValue("ADZ_ITEMVI"))
			cCodVis		:= oModel:GetModel(cFolder):GetValue("ADZ_CODVIS")
			cItemVi		:= oModel:GetModel(cFolder):GetValue("ADZ_ITEMVI")
			dbSelectArea("AAU")
			dbSetOrder(1)
			If dbSeek(xFilial("AAU")+cCodVis+cItemVi)
				If AllTrim(AAU->AAU_OBRIG) == "1"
					lRet := .F.
					Help("",1,"A600Del",,STR0096 + " " + STR0179,1) //"Atenção!" ## "Este Item não pode ser Deletado pois é um produto Obrigatório"
				EndIf
			EndIf
		EndIf
		
		If lRet .AND. lCtrlDel
			//Caso o ponto de entrada seja criado pelo usuario o tratamento de
			//exclusao feita pela rotina FATA600 nao sera considerado, apenas
			//o ponto de entrada.
			If	_lFt600EXC

				lRet	:= ExecBlock("FT600EXC", .F.,.F., {oModel})
  				If	ValType(lRet) <> "L"
  					lRet := .F.
				EndIf

			Else
				
				If nGetNum == 1 //Aba de produtos
					For nX := 1 to oMdlAces:Length()
						oMdlAces:GoLine(nX)
						//Produto pai sendo deletado / acessorios sendo excluidos
						If (oMdlAces:GetValue("ADZ_ITPAI") == oMdlProd:GetValue("ADZ_ITEM")) .AND. !oMdlProd:IsDeleted()
							oMdlAces:DeleteLine()
						EndIf
						//Produto pai sendo restaurado / acessorios sendo restaurados
						If (oMdlAces:GetValue("ADZ_ITPAI") == oMdlProd:GetValue("ADZ_ITEM")) .AND. oModel:GetModel('ADZPRODUTO'):IsDeleted()
							oMdlAces:UnDeleteLine()
						EndIf
					Next nX
					oMdlAces:GoLine(1)
				EndIf
				
			Endif
		Endif
		
	EndIf

	If oMdlProd <> NIL .AND. nModulo = 28 // Gestão de Serviços
		If !IsInCallStack("SETDADOSORC") //Função que leva Orçamento para Proposta - FATN600A.prw
			lRet := .F.
			Help(" ",1,"A600Del", , "Não é permitido deletar/recuperar itens diretamente pela proposta.", 3, 1 )
			Return (lRet)
		EndIf	
	EndIf
	
	
	If	lRet
		A600CroFinance(oModel, .T.)	//Atualiza cronograma financeiro
	EndIf
EndIf
Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} A600EntNm
Retorna o nome da entidade para os parametros informados

@sample		A600EntNm(cEnt,cCod,cLoja)

@since		02/04/2014
@version	P12

@param 		cEnt,cCod,cLoja, código das entidades

@return 	cRet, Caracter, Descrição da entidade
/*/
//------------------------------------------------------------------------------
Function A600EntNm( cEnt, cCod, cLoja )

Local cRet		:= ""
Local aArea		:= GetArea()
Local cCpoRet   := ""

Do case
	Case cEnt == "SA1"
		cCpoRet	:= "A1_NOME"
	Case cEnt == "SUS"
		cCpoRet	:= "US_NOME"
	Case cEnt == "ACH"
		cCpoRet	:= "ACH_RAZAO"
EndCase

If !Empty(cCpoRet)
	cRet := Posicione(cEnt,1,xFilial(cEnt)+cCod+cLoja,cCpoRet)
EndIf

RestArea(aArea)

Return cRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} A600DescEnt
Retorna o nome da entidade para os parametros informados

@sample		A600DescEnt(cTipoEnt, cCodEnt, cLojEnt)

@since		02/04/2014
@version	P12

@param 		cTipoEnt,cCodEnt,cLojEnt, código das entidades

@return 	cRet, Caracter, Descrição da entidade
/*/
//------------------------------------------------------------------------------
Function A600DescEnt(cTipoEnt, cCodEnt, cLojEnt)

Local aArea	 	:= GetArea()
Local cNomeEnt	:= Space(GetSX3Cache("ADY_DESENT","X3_TAMANHO"))
Local cEntida		:= If(cTipoEnt == "1", "SA1", "SUS")			//1=Cliente
Local cGetField	:= If(cTipoEnt == "1", "A1_NOME", "US_NOME")	//1=Cliente

cNomeEnt			:= Posicione(cEntida, 1, xFilial(cEntida) + cCodEnt + cLojEnt, cGetField)
RestArea(aArea)
Return (cNomeEnt)

//------------------------------------------------------------------------------
/*/{Protheus.doc} A600ReplcAlt
Replica as alterações para o Acols, utilizado no valid dos campos ADY_CONDPG/ADY_TES/ADY_DESCON
ADY_TPPROD/ADY_LOCAL

@sample		A600ReplcAlt(nPos)

@since		02/04/2014
@version	P12

@return 	lRet, Logico, .T. se houve sucesso
/*/
//------------------------------------------------------------------------------
Function A600ReplcAlt(nPos)

Local lRet 		:= .T.
Local nX			:= 0
Local nY			:= 0
Local oModel		:= FwModelActive()
Local oMdlADY		:= oModel:GetModel("ADYMASTER")
Local oMdlPrd		:= oModel:GetModel("ADZPRODUTO")
Local oMdlAce		:= oModel:GetModel("ADZACESSOR")
Local bCondition	:= {|x| x:GetValue(cField) <> uValue }
Local uValue 		:= Nil
Local cField	 	:= ""
Local oView		:= FWViewActive()
Local nLenPrd		:= 0
Local nLenAce		:= 0

Default nPos		:= Nil

Do Case
	
	//Alteração da forma de pagamento
	Case nPos == 1
		cField		:= "ADZ_CONDPG"
		uValue		:= oMdlADY:GetValue("ADY_CONDPG")
		
	//Alteração da porcentagem de desconto
	Case nPos == 2
		cField		:= "ADZ_DESCON"
		If oMdlADY:GetValue("ADY_DESCON") > 0
			If ( oMdlADY:GetValue("ADY_DESCON") < 0 .Or. oMdlADY:GetValue("ADY_DESCON") > 100 )
				lRet := .F.
				Help("",1,"A600ReplcAlt",,STR0345,1) //"Informe um percentual de desconte de até 100%"
			Else
				uValue		:= oMdlADY:GetValue("ADY_DESCON")
			EndIf
		Else
				uValue	:= 0
		EndIf
		
	//Alteração da TES
	Case nPos == 3
		cField		:= "ADZ_TES"
		uValue		:= oMdlADY:GetValue("ADY_TES")
		
	//Alteração do tipo do Produto
	Case nPos == 4
		cField		:= "ADZ_TPPROD"
		uValue		:= oMdlADY:GetValue("ADY_TPPROD")
		
	//Alteração do tipo do Produto
	Case nPos == 5
		cField		:= "ADZ_LOCAL"
		uValue		:= oMdlADY:GetValue("ADY_LOCAL")
		bCondition	:= {|x| x:GetValue(cField) <> uValue }
		
	//Alteração da tabela de preço
	Case nPos == 6
		cField		:= "ADZ_PRCTAB"
		uValue		:= oMdlADY:GetValue("ADY_TABELA")
	
EndCase

If lRet

	nLenPrd 	:= oMdlPrd:Length()
	nLenAce 	:= oMdlAce:Length()

	If	!( oMdlPrd:IsEmpty() )
		For nX := 1 To nLenPrd
			oMdlPrd:GoLine(nX)
			If ( !( oMdlPrd:IsDeleted() ) .AND. !( IsItOrcServ(oMdlPrd:GetValue("ADZ_ITEM")) ) )
				If	nPos <> 6
					If	Eval(bCondition, oMdlPrd)
						lRet	:= oMdlPrd:SetValue(cField, uValue)
					EndIf
				Else
					nValor	:= A600TabPreco(uValue,oMdlPrd:GetValue("ADZ_PRODUT"))
					lRet	:= oMdlPrd:SetValue("ADZ_PRCTAB", nValor)
					If lRet
						lRet	:= oMdlPrd:SetValue("ADZ_PRCVEN", nValor)
					EndIf
				EndIf
				If	!lRet
					EXIT
				EndIf
			EndIf
		Next nX
	EndIf

	If	lRet .AND. !( oMdlAce:IsEmpty() )
		For nY := 1 To nLenAce
			oMdlAce:GoLine(nY)
			If ( !( oMdlAce:IsDeleted() ) .AND. !( IsItOrcServ(oMdlPrd:GetValue("ADZ_ITEM")) ) )
				If	nPos <> 6
					If	Eval(bCondition, oMdlAce)
						lRet := oMdlAce:SetValue(cField, uValue)
					EndIf
				Else
					nValor	:= A600TabPreco(uValue,oMdlAce:GetValue("ADZ_PRODUT"))
					lRet	:= oMdlAce:SetValue("ADZ_PRCTAB", nValor)
					If lRet
						lRet	:= oMdlAce:SetValue("ADZ_PRCVEN", nValor)
					EndIf
				EndIf
			EndIf
			If	!lRet
				EXIT
			EndIf
		Next nY
	EndIf

	//------------------------------------------
	// Reposiciona registro na primeira linha
	//------------------------------------------
	If nLenPrd > 0
		oMdlPrd:GoLine(1)
	EndIf
	If nLenAce > 0
		oMdlAce:GoLine(1)
	EndIf
	If !( oMdlPrd:IsEmpty() ) .AND. !IsBlind()
		oView:Refresh('ADZPRODUTO')
		oView:Refresh('ADZACESSOR')
		oView:Refresh('CRONOFIN')
	EndIf

EndIf
Return( lRet )

//------------------------------------------------------------------------------
/*/{Protheus.doc} A600Servicos
Aciona o Simulador de Serviços

@sample 	A600Servicos(cProposta, cOportunida, cTabPrc)

@param		oModel - Modelo de Dados da Proposta Comercial.

@author	Vendas CRM
@since		25/02/2008
@version	P12
/*/
//------------------------------------------------------------------------------
Function A600Servicos(oModel)

Local aArea			:= GetArea()
Local aAreaSB1		:= SB1->(GetArea())
Local aAreaDA1		:= DA1->(GetArea())
Local aAreaAF1		:= AF1->(GetArea())
Local aHeadSrv		:= {}
Local aColsSrv 		:= {}
Local aPrdDetail	:= {}
Local aProduct	    := {}
Local aRetSimula	:= {}
Local aCposObrig	:= { "ADY_TABELA", "ADY_TES", "ADY_CONDPG" }		//Campos necessários para adicionar uma linha na grid de produtos
Local oMdlADY		:= oModel:GetModel("ADYMASTER")
Local oMdlPrd		:= Nil
Local cProposta	    := oMdlADY:GetValue("ADY_PROPOS")
Local cOportunida	:= oMdlADY:GetValue("ADY_OPORTU")
Local cTabPrc		:= oMdlADY:GetValue("ADY_TABELA")
Local cPms			:= ""
Local cPmsVer		:= ""
Local nDcQtdVen	    := GetSX3Cache("ADZ_QTDVEN","X3_DECIMAL")
Local nX			:= 0
Local nQtdTask		:= 1
Local nLenColSrv 	:= 0
Local nLenPrd		:= 0
Local lFT600Srv	    := FindFunction("U_FT600SRV")
Local lRet			:= .T.
Local lMult		:= SuperGetMv("MV_PMSCUST",.F.,"1") == "2"

If lFT600Srv
	lRet := ExecBlock("FT600SRV",.T.,.T.,{ cProposta, cOportunida, cTabPrc, oModel } )
	If ValType(lRet) <> "L"
		lRet := .T.
	EndIf
EndIf

If lRet
	
	DbSelectArea("AF1")		//Orçamentos
	AF1->(DbSetOrder(4))	//AF1_FILIAL + AF1_CODORC + AF1_TIPO
	
	If Ft600VdFCpo( aCposObrig )
		
		aRetSimula := FATA530B(3, cProposta)
		
		If 	Len(aRetSimula) > 0
			
			If	aRetSimula[1]
				
				AF1->( DbSetOrder(9) )	//AF1_FILIAL+AF1_CODORC+AF1_ORCAME+AF1_VERSAO
				cAF1Seek := cProposta + aRetSimula[2] + aRetSimula[3]
				
				//Verifica se há orçamento para a proposta
				If ( AF1->( DbSeek( xFilial("AF1") + cAF1Seek ) ) )
				
					Ft530Prod(@aHeadSrv, @aColsSrv, AF1->AF1_ORCAME, , AF1->AF1_VERSAO)
					
					nLenColSrv := Len(aColsSrv) 
					
					If	nLenColSrv > 0
						If lMult //Se a quantidade informada for a total não deve multiplicar pela quantidade da tarefa. 
							nQtdTask := AF2->AF2_QUANT
						EndIf
						//---------------------------------------------------------
						// Inclui os produtos contidos no simulador de horas
						//---------------------------------------------------------
						For nX := 1 To nLenColSrv
							aAdd( aProduct ,{"ADZ_PRODUT"	,aColsSrv[nX,1]}	)	//Codigo do produto
							aAdd( aProduct ,{"ADZ_DESCRI"	,aColsSrv[nX,2]}	)	//Descricao
							aAdd( aProduct ,{"ADZ_UM"		,aColsSrv[nX,3]}	)	//Unidade de medida
							aAdd( aProduct ,{"ADZ_QTDVEN"	,nQtdTask * (Round(aColsSrv[nX,4], nDcQtdVen))})	//Quantidade # Arredonda a quantidade, pois há 4 casas decimais no PMS
							aAdd( aProduct ,{"ADZ_PMS"		,AF1->AF1_ORCAME}	)	//ORCAMENTO PMS
							aAdd( aProduct ,{"ADZ_PMSVER"	,AF1->AF1_VERSAO}	)	//VERSAO PMS
							
							aAdd( aPrdDetail, { aProduct, {{ "ADZ_PRODUT", AllTrim( aColsSrv[nX][1] ) }, { "ADZ_PMS", AllTrim( AF1->AF1_ORCAME ) }}, .F., .F. })
							aProduct 	:= {}
						Next nX
						
						oMdlPrd := oModel:GetModel("ADZPRODUTO")
						nLenPrd := oMdlPrd:Length()
						
						For nX := 1 To nLenPrd
							oMdlPrd:GoLine( nX )
							
							If  !oMdlPrd:IsDeleted() 
								cPms		:= oMdlPrd:GetValue("ADZ_PMS")
								cPmsVer		:= oMdlPrd:GetValue("ADZ_PMSVER")
								If !Empty( cPms ) .And. !Empty( cPmsVer ) 
									If cPms != AF1->AF1_ORCAME .Or. cPmsVer != AF1->AF1_VERSAO
										oMdlPrd:DeleteLine() 
									Else
										If aScan( aColsSrv,  {|x| x[1] == oMdlPrd:GetValue("ADZ_PRODUT")} ) == 0
											oMdlPrd:DeleteLine() 
										EndIf
									EndIf
								EndIf	
							EndIf
						Next nX
						
						FT600LoadGrid(oMdlPrd, aPrdDetail)
						
					EndIf
					
				EndIf
				
			EndIf
			
		EndIf
		
	EndIf
	
EndIf

RestArea(aAreaDA1)
RestArea(aAreaSB1)
RestArea(aAreaAF1)
RestArea(aArea)

Return Nil

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} FT600DefEnt
Define o tipo da entidade da oportunidade

@sample	FA600DefEnt()

@return 	cEntidade	Tipo da entidade. 1=Cliente e 2=Prospect

@author	Danilo Dias
@since		29/04/2014
@version	12
/*/
//-----------------------------------------------------------------------------------------
Function FT600DefEnt()

Local cEntidade := '1'

If ( !Empty( AD1->AD1_CODCLI ) )
	cEntidade := '1'
Else
	cEntidade := '2'
EndIf

Return cEntidade

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} A600Impr
Impressao de proposta comercial.

@sample	A600Impr()

@author	Vendas CRM
@since		15/10/2008
@version	11
/*/
//-----------------------------------------------------------------------------------------
Function A600Impr()

Local lFT600IMP	:= FindFunction("U_FT600IMP")	//Ponto de entrada para customizar a impressao da proposta
Local aInfo		:= GetApoInfo("FT600IMP.PRW")

//----------------------------------------------------------------------------------
// Caso o ponto de entrada FT600IMP exista a impressao da proposta
// comercial sera feita atraves dele caso contrario sera usada a rotina padrao
// FATR600
//----------------------------------------------------------------------------------
If (lFT600IMP .And. Len(aInfo) > 0 .And. aInfo[4] <> CtoD("26/07/2016") .And. aInfo[5] <> "14:07:26") .Or.;
	(lFT600IMP .And. Len(aInfo) == 0)
	lRetorno := U_FT600IMP()
	If	ValType(lRetorno) == "L"
		lRetorno := .T.
	EndIf
Else
	FATR600()
EndIf

Return()

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} A600LProp

Localiza proposta bloqueada.

@sample  A600LProp(cCodVSup)

@Param   cCodVSup - Codigo do supervisor
@Param   lMSG     - Indica se deverá mostras mensagens

@return  lAchou -  Variavel lógica com flag informando se achou ou não

@author  Serviços/CRM
@since   29/04/2014
@version P12
/*/
//-----------------------------------------------------------------------------------------

Function A600LProp(cCodVSup,lMSG)

Local aArea		:= GetArea()														//Guarda area atual.
Local cQuery		:= ""																//Armazena a query.
Local cCodInt  	:= ""					 	//Codigo inteligente.
Local aVendSub 	:= {}              							//Array com vendedores subordinados.
Local cVendSub	:= ""																//Vendedores superiores.
Local cAlias		:= "LCPBLQ"														//Tabela temporaria.
Local lAchou		:= .F.
Local nX			:= 0																//Incremento utilizado no laco For.

Default lMSG   := .F. 

If !Empty( cCodVSup )
	
	If nModulo == 73
		
		cCodInt	:= Posicione("AO3",1,xFilial("AO3")+cCodVSup,"AO3_IDESTN")
		aVendSub	:= Ft520Sub(cCodInt)
		
	Else
		
		DbSelectArea("SA3")
		SA3->(DbSetOrder(1))
		If SA3->(DbSeek(xFilial("SA3") + cCodVSup))
			cCodInt	:= SA3->A3_NVLSTR
			If ! Empty(cCodInt)
				aVendSub	:= Ft520Sub(cCodInt)
			EndIf
		EndIf
		
	EndIf
	
EndIf

If Len(aVendSub) > 0
	
	For nX := 1 to Len(aVendSub)
		cVendSub += "'"+aVendSub[nX]+"',"
	Next nX
	
	cVendSub := Substr(cVendSub,1,Len(cVendSub)-1)
	
	cQuery := "SELECT 1 RETORNO "
	
	If Alltrim(TcGetDB()) == "DB2"
		cQuery += " FROM TABLE (VALUES 1) AS TBX "
	ElseIf Alltrim(TcGetDB()) == "ORACLE"
		cQuery += " FROM DUAL "
	Else
		cQuery += " FROM "+ RetSqlName('ADY') + " TBX "
	EndIf
	
	cQuery	+= " WHERE EXISTS(SELECT ADY_STATUS FROM " + RetSqlName("ADY")
	cQuery	+= " WHERE ADY_FILIAL = '"+xFilial("ADY")+"' AND ADY_VEND IN ("+cVendSub+")  AND  ADY_STATUS = 'F' AND D_E_L_E_T_ = ' ')"
	
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAlias,.F.,.T.)
	
	If (cAlias)->(!EOF())  .AND. (cAlias)->RETORNO > 0
		lAchou := .T.
	Else
		If lMSG
			AVISO(STR0096,STR0098,{STR0099},1)  //"Não há proposta(s) bloqueada(s) para aprovação"//"Fechar"
		EndIf
	EndIf
	
	(cAlias)->(dbclosearea())
	
Else
	If lMSG
		AVISO(STR0096,STR0315,{STR0099},1)  //"Não possui permissão para acessar está rotina !"
	EndIf
EndIf

RestArea(aArea)

Return(lAchou)

//------------------------------------------------------------------------------
/*/{Protheus.doc} FT600RetProp

Função para retornar as propostas marcadas

@sample			FT600RetProp( aRet, aListBox )

@param1			aRet
@param2			aListBox

@author		CRM e Serviços
@since			17/06/2013
@version		P1180
/*/
//------------------------------------------------------------------------------
Function FT600RetProp( aRet,aListBox )

Local nI			:= 0
Local lRetorno	:= .F.

aRet := {}

For nI := 1 To Len( aListBox )
	If aListBox[nI][1]
		aAdd( aRet, { aListBox[nI][2] } )
		lRetorno := .T.
	EndIf
Next nI

Return lRetorno

//------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600Marca

Função para marcar as propostas comerciais para comparação

@sample			Ft600Marca( lMarca, aListBox, oLbx )

@param1			lMarca
@param2			aListBox
@param3			oLbx

@author		CRM e Serviços
@since			17/06/2013
@version		P1180
/*/
//------------------------------------------------------------------------------
Function Ft600Marca( lMarca, aListBox, oLbx )

Local  nI := 0

For nI := 1 To Len( aListBox )
	aListBox[nI][1] := lMarca
Next nI

oLbx:Refresh()

Return NIL

//------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600VerTodos

Função para verficar se a proposta está marcada ou não

@sample			Ft600VerTodos( aListBox, lChk, oChkMar )

@param1		aListBox
@param2		lChk
@param3		oChkMar

@author		CRM e Serviços
@since		29/04/2014
@version	P12
/*/
//------------------------------------------------------------------------------
Function Ft600VerTodos( aListBox, lChk, oChkMar )

Local lTTrue := .T.
Local nI     := 0

For nI := 1 To Len( aListBox )
	lTTrue := IIf( !aListBox[nI][1], .F., lTTrue )
Next nI

lChk := IIf( lTTrue, .T., .F. )
oChkMar:Refresh()

Return NIL

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600Vis

Visualizacao da Oportunidade de Venda do comparador.

@sample  Ft600Vis

@author  Serviços/CRM
@since   29/04/2014
@version P12
/*/
//-----------------------------------------------------------------------------------------
Function Ft600Vis(aRevisoes,nLinha)

DbSelectArea(aRevisoes[nLinha,Len(aRevisoes[nLinha])-1])
MsGoTo(aRevisoes[nLinha,Len(aRevisoes[nLinha])])

VisualProp(Recno())

Return Nil

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600Tree

Funcao que monta o Tree da Prosposta Comercial.

@sample  Ft600Tree

@author  Serviços/CRM
@since   29/04/2014
@version P12
/*/
//-----------------------------------------------------------------------------------------
Function Ft600Tree(aCmp)

Local aTree		:= {}
Local aArea		:= GetArea()
Local aStru		:= {}
Local bCampo		:= {|cCampo|(aCmp[1])->(FieldGet((aCmp[1])->(FieldPos(aCmp[1]+"_"+cCampo))))}
Local cCargoPai	:= ""
Local cCargo		:= ""
Local cPropor		:= ""
Local cAliasADZ	:= "ADZ"
Local cAliasAUX	:= "ADZ"
Local cQuery		:= ""
Local nStru		:= 1
Local cFilADZ		:= xFilial("ADZ")

//Insere a Proposta Comercial
DbSelectArea(aCmp[1])
dbGoTo(aCmp[2])

cPropor	:= Eval(bCampo,"PROPOS")
cPrevis	:= Eval(bCampo,"PREVIS")

cCargoPai:= Pad("ADYAGP"+Eval(bCampo,"FILIAL")+cPropor,50)
aAdd(aTree,{aCmp[1],Eval(bCampo,"FILIAL")+cPropor+cPrevis,STR0078+"  "+ cPropor+" - "+STR0079+cPrevis,cCargoPai,StrZero(0,50),"N",.F.,"",""})//"Proposta"##"Revisão "

DbSelectArea("ADZ")
DbSetOrder(3)

cAliasADZ := GetNextAlias()
aStru		 := ADZ->(dbStruct())

cQuery := "SELECT * "
cQuery += "FROM "+RetSqlName("ADZ")+" ADZ "
cQuery += "WHERE ADZ.ADZ_FILIAL='"+cFilADZ+"' AND "
cQuery +=       "ADZ.ADZ_PROPOS='"+cPropor+"' AND "
cQuery +=       "ADZ.ADZ_FOLDER='1'           AND "
cQuery +=       "ADZ.ADZ_REVISA='"+cPrevis+"' AND "
cQuery +=       "ADZ.D_E_L_E_T_='' "
cQuery += "ORDER BY "+SqlOrder(ADZ->(IndexKey()))

cQuery := ChangeQuery(cQuery)

DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasADZ,.T.,.T.)
For nStru := 1 To Len(aStru)
	If aStru[nStru,2] <> "C"
		TcSetField(cAliasADZ,aStru[nStru,1],aStru[nStru,2],aStru[nStru,3],aStru[nStru,4])
	EndIf
Next nStru

While !Eof() .AND. (cAliasADZ)->ADZ_FILIAL+(cAliasADZ)->ADZ_PROPOS+(cAliasADZ)->ADZ_REVISA == cFilADZ+cPropor+cPrevis
	If !Empty((cAliasADZ)->ADZ_PRODUT).AND.(cAliasADZ)->ADZ_FOLDER == "1" //Produto
		cCargo	:= Pad("ADZ"+(cAliasADZ)->ADZ_FILIAL+(cAliasADZ)->ADZ_PROPOS +(cAliasADZ)->ADZ_FOLDER+(cAliasADZ)->ADZ_ITEM,50)
		aAdd(aTree,{"ADZ",(cAliasADZ)->ADZ_FILIAL+(cAliasADZ)->ADZ_PROPOS+(cAliasADZ)->ADZ_REVISA+(cAliasADZ)->ADZ_FOLDER+(cAliasADZ)->ADZ_ITEM,(cAliasADZ)->ADZ_DESCRI,cCargo,cCargoPai,"N",.F.,"1",(cAliasADZ)->ADZ_PRODUT+(cAliasADZ)->ADZ_FOLDER})
	EndIf
	dbSkip()
End

DbSelectArea("ADZ")
DbSetOrder(3)

cAliasAUX := GetNextAlias()
aStru		 := ADZ->(dbStruct())

cQuery := "SELECT * "
cQuery += "FROM "+RetSqlName("ADZ")+" ADZ "
cQuery += "WHERE ADZ.ADZ_FILIAL='"+cFilADZ+"' AND "
cQuery +=       "ADZ.ADZ_PROPOS='"+cPropor+"' AND "
cQuery +=       "ADZ.ADZ_FOLDER='2'           AND "
cQuery +=       "ADZ.ADZ_REVISA='"+cPrevis+"' AND "
cQuery +=       "ADZ.D_E_L_E_T_='' "
cQuery += "ORDER BY "+SqlOrder(ADZ->(IndexKey()))

cQuery := ChangeQuery(cQuery)

DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasAUX,.T.,.T.)
For nStru := 1 To Len(aStru)
	If aStru[nStru,2] <> "C"
		TcSetField(cAliasAUX,aStru[nStru,1],aStru[nStru,2],aStru[nStru,3],aStru[nStru,4])
	EndIf
Next nStru

While !Eof() .AND. (cAliasAUX)->ADZ_FILIAL+(cAliasAUX)->ADZ_PROPOS+(cAliasAUX)->ADZ_REVISA == cFilADZ+cPropor+cPrevis
	If !Empty((cAliasAUX)->ADZ_PRODUT).AND.(cAliasAUX)->ADZ_FOLDER == "2" //Acessorios
		cCargo	:= Pad("ADZ"+(cAliasAUX)->ADZ_FILIAL+(cAliasAUX)->ADZ_PROPOS+(cAliasAUX)->ADZ_FOLDER+(cAliasAUX)->ADZ_ITEM,50)
		aAdd(aTree,{"ADZ",(cAliasAUX)->ADZ_FILIAL+(cAliasAUX)->ADZ_PROPOS+(cAliasAUX)->ADZ_REVISA+(cAliasAUX)->ADZ_FOLDER+(cAliasAUX)->ADZ_ITEM,(cAliasAUX)->ADZ_DESCRI,cCargo,cCargoPai,"N",.F.,"2",(cAliasADZ)->ADZ_PRODUT+(cAliasADZ)->ADZ_FOLDER})
	EndIf
	ADZ->(DbSkip())
EndDo

DbSelectArea(cAliasADZ)
DbCloseArea()
DbSelectArea("ADZ")
DbSelectArea(cAliasAUX)
DbCloseArea()

RestArea(aArea)
Return(aTree)

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600Rev

Retorna as revisoes das Propostas de Vendas.

@sample  Ft600Rev

@author  Serviços/CRM
@since   29/04/2014
@version P12
/*/
//-----------------------------------------------------------------------------------------
Function Ft600Rev(cNrPro, aLstHeader, aLstCols, cLine,cNrOpr,aPropos)

Local aArea			:= GetArea()
Local aAreaSX3		:= SX3->(GetArea())
Local aAreaADY		:= ADY->(GetArea())
Local aRevisoes		:= {}
Local nConta		:= 0
Local cAliasAGP 	:= "AGP"
Local lQuery		:= .F.
Local aCampos   	:= {}
Local aCamposUsu	:= {}
Local cPropos		:= ""
Local nI			:= 0
Local aStru		:= {}
Local cQuery		:= ""
Local nStru		:= 1
Local cFilAGP		:= xFilial("AGP")
Local cFilADY		:= xFilial("ADY")

Default aPropos	:= {}
Default cNrOpr		:= ""

aCampos	:= {"ADY_PROPOS",;
       	    "ADY_PREVIS",;
       	    "ADY_ENTIDA",;
       	    "ADY_CODIGO",;
       	    "ADY_LOJA",;
       	    "ADY_TABELA",;
       	    "ADY_DATA"}

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Adiciona campos do usuário.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
For nConta := 1 To Len(aCamposUsu)
	aAdd(aCampos, "")
	aIns(aCampos, aCamposUsu[nConta][2])
	aCampos[aCamposUsu[nConta][2]] := aCamposUsu[nConta][1]
Next nConta

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Carrega todas as revisoes da oportunidade de venda.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
DbSelectArea("AGP")
DbSetOrder(1)

If Len(aPropos) > 0
	For nI := 1 To Len(aPropos)
		If Empty(cPropos)
			cPropos += "'"+aPropos[nI][1]+"'"
		Else
			cPropos += "," + "'"+aPropos[nI][1]+"'"
		EndIf
	Next nI
EndIf

lQuery    := .T.
cAliasAGP := GetNextAlias()
aStru	  := AGP->(dbStruct())

cQuery := "SELECT AGP.*, AGP.R_E_C_N_O_ AGPRECNO "
cQuery += "FROM "+RetSqlName("AGP")+" AGP "
cQuery += "WHERE AGP.AGP_FILIAL='"+cFilAGP+"' AND "
If !Empty(cPropos)
	cQuery +=       "AGP.AGP_PROPOS IN("+cPropos+") AND "
Else
	cQuery +=       "AGP.AGP_PROPOS='"+cNrPro+"' AND "
EndIf
cQuery +=       "AGP.D_E_L_E_T_='' "
cQuery += "ORDER BY "+SqlOrder(AGP->(IndexKey()))

cQuery := ChangeQuery(cQuery)

DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasAGP,.T.,.T.)
For nStru := 1 To Len(aStru)
	If aStru[nStru,2] <> "C"
		TcSetField(cAliasAGP,aStru[nStru,1],aStru[nStru,2],aStru[nStru,3],aStru[nStru,4])
	EndIf
Next nStru

While !Eof() .AND. (cFilAGP + cNrOpr == (cAliasAGP)->AGP_FILIAL + (cAliasAGP)->AGP_OPORTU)
	aAdd(aRevisoes,{})
	aAdd(aRevisoes[Len(aRevisoes)], .F.)
	For nConta := 1 To Len(aCampos)
		aAdd(aRevisoes[Len(aRevisoes)], (cAliasAGP)->&(StrTran(aCampos[nConta], "ADY", "AGP")))
	Next
	
	If aRevisoes[Len(aRevisoes)][4] == '1'
		aRevisoes[Len(aRevisoes)][4] := STR0071 //"Cliente"
	Else
		aRevisoes[Len(aRevisoes)][4] := STR0072 //"Prospect"
	EndIf
	
	aAdd(aRevisoes[Len(aRevisoes)], "AGP")
	aAdd(aRevisoes[Len(aRevisoes)], If(lQuery,(cAliasAGP)->AGPRECNO,(cAliasAGP)->(Recno())))
	dbSkip()
End

DbSelectArea("ADY")
ADY->(DbSetOrder(1))

For nI := 1 To Len(aPropos)
	If ADY->(DbSeek(cFilADY+aPropos[nI][1]))
		If ADY->ADY_PREVIS > "01"
			aAdd(aRevisoes,{})
			aAdd(aRevisoes[Len(aRevisoes)], .F.)
			For nConta := 1 To Len(aCampos)
				aAdd(aRevisoes[Len(aRevisoes)], &("ADY->" + aCampos[nConta]))
			Next nConta
			If aRevisoes[Len(aRevisoes)][4] == '1'
				aRevisoes[Len(aRevisoes)][4] := STR0071 //"Cliente"
			Else
				aRevisoes[Len(aRevisoes)][4] := STR0072 //"Prospect"
			EndIf

			aAdd(aRevisoes[Len(aRevisoes)], "ADY")
			aAdd(aRevisoes[Len(aRevisoes)], ADY->(Recno()))
		EndIf
	EndIf
Next nI

aSort(aRevisoes,,,{ |x,y| X[2]+X[3] < Y[2]+Y[3] } )

If lQuery
	DbSelectArea(cAliasAGP)
	DbCloseArea()
	DbSelectArea("AGP")
EndIf

//Monta o Header e o Cols do LISTBOX.
SX3->(DbSetOrder(2))

aLstHeader	:= {""}
aLstCols	:= aRevisoes
cLine		:= "{||{ If(aLstCols[oList:nAt,1],oOk,oNo),"
For nConta := 1 To Len(aCampos)
	SX3->(DbSeek(aCampos[nConta]))
	aAdd(aLstHeader, RetTitle(aCampos[nConta]))
	If SX3->X3_TIPO == "N"
		cLine += "PadL(AllTrim(Transform(aLstCols[oList:nAt,"+LTrim(Str((nConta+1)))+"],'"+Trim(SX3->X3_PICTURE)+"')),"+cValToChar(SX3->X3_TAMANHO)+"),"
	Else
		cLine += "aLstCols[oList:nAt," + AllTrim(Str((nConta+1))) + "],"
	EndIf
Next nConta
cLine := SubStr(cLine, 0, Len(cLine)-1) + "}}"

RestArea(aAreaSX3)
RestArea(aAreaADY)
RestArea(aArea)

Return(.T.)

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600Click

Verifica se seleciona ou nao a revisao da oportunidade de venda.

@sample  Ft600Click

@author  Serviços/CRM
@since   29/04/2014
@version P12
/*/
//-----------------------------------------------------------------------------------------

Function Ft600Click(aRevisoes,nLinha)

Local nRevisoes := 0

If aRevisoes[nLinha,1]
	aRevisoes[nLinha,1]:=.F.
Else
	aEval(aRevisoes,{|x| If(x[1],nRevisoes++,)})
	If nRevisoes < 2
		aRevisoes[nLinha,1]:=.T.
	EndIf
EndIf

Return Nil

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600Compara

Compara as revisoes da Proposta de venda em forma de array.

@sample  Ft600Compara

@author  Serviços/CRM
@since   29/04/2014
@version P12
/*/
//-----------------------------------------------------------------------------------------
Function Ft600Compara(aOrigem,aDestino)

Local aArea    	:= GetArea()
Local aOpVComp 	:= {}
Local nItem    	:= 0
Local nPos     	:= 0
Local cFilADY		:= xFilial("ADY")
Local nTmPropos	:= GetSx3Cache("ADY_PROPOS","X3_TAMANHO")

//Realiza a comparacao de todos os itens das revisoes da Proposta
//e informa se existem modificacoes ou nao.

//Analisa a estrutura da revisao base.
For nItem := 1 To Len(aOrigem)
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Verifica se existe o item da Proposta comercial a ser comparada.   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	nPos := Ascan(aDestino,{|x| x[4] == aOrigem[nItem,4]})
	If (nPos > 0)
		If Ft600Check(aOrigem[nItem,1],aDestino[nPos,1],aOrigem[nItem,2],aDestino[nPos,2])
			Aadd(aOpVComp,{aDestino[nPos,1],aDestino[nPos,2],aDestino[nPos,3],;
							aDestino[nPos,4],aDestino[nPos,5],aDestino[nPos,6],aDestino[nPos,7],aDestino[nPos,8]})
		Else
			Aadd(aOpVComp,{aDestino[nPos,1],aDestino[nPos,2],Alltrim(aDestino[nPos,3]) + STR0080,; //" - Modificado"
							aDestino[nPos,4],aDestino[nPos,5],"M",aDestino[nPos,7],aDestino[nPos,8]})
		EndIf
	Else
		If SubStr(aOrigem[1][2], Len(cFilADY) + 1, nTmPropos) == SubStr(aDestino[1][2], Len(cFilADY) + 1, nTmPropos)
			Aadd(aOpVComp,{aOrigem[nItem,1],aOrigem[nItem,2],AllTrim(aOrigem[nItem,3]) + STR0081,; //" - Excluido"
							aOrigem[nItem,4],aOrigem[nItem,5],"E",aOrigem[nItem,7],aOrigem[nItem,8]})
		EndIf
	EndIf
Next nItem

//Analisa a existencia de novos itens na estrutura.
For nItem:= 1 To Len(aDestino)
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Verifica se existe o item no projeto a ser comparado.³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	nPos:= Ascan(aOrigem,{|x| x[4] == aDestino[nItem,4]})
	If (nPos == 0)
		If SubStr(aOrigem[1][2], Len(cFilADY) + 1, nTmPropos) == SubStr(aDestino[1][2], Len(cFilADY) + 1, nTmPropos)
			Aadd(aOpVComp,{aDestino[nItem,1],AllTrim(aDestino[nItem,2]),AllTrim(aDestino[nItem,3]) + STR0082,; //" - Incluido"
							aDestino[nItem,4],aDestino[nItem,5],"I",aDestino[nItem,7],aDestino[nItem,8]})
		Else
			If Len(aOrigem) >= nItem
				nPos:= Ascan(aDestino,{|x| x[9] == aOrigem[nItem,9]})
			Else
				nPos := 0
			EndIf
			If (nPos > 0)
				If Ft600Check(aOrigem[nItem,1],aDestino[nPos,1],aOrigem[nItem,2],aDestino[nPos,2],.T.)
					Aadd(aOpVComp,{aDestino[nPos,1],aDestino[nPos,2],aDestino[nPos,3],;
							aDestino[nPos,4],aDestino[nPos,5],aDestino[nPos,6],aDestino[nPos,7],aDestino[nPos,8]})
				Else
					Aadd(aOpVComp,{aDestino[nPos,1],aDestino[nPos,2],Alltrim(aDestino[nPos,3]) + STR0080,; //" - Modificado"
							aDestino[nPos,4],aDestino[nPos,5],"M",aDestino[nPos,7],aDestino[nPos,8]})
				EndIf
			Else
				Aadd(aOpVComp,{aDestino[nItem,1],AllTrim(aDestino[nItem,2]),AllTrim(aDestino[nItem,3]),; //" - Incluido"
							aDestino[nItem,4],aDestino[nItem,5],"I",aDestino[nItem,7],aDestino[nItem,8]})
			EndIf
		EndIf
	EndIf
Next nItem

RestArea(aArea)

Return(aOpVComp)

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600Check

Verifica os dados das revisoes da Proposta de venda.

@sample  Ft600Check

@author  Serviços/CRM
@since   29/04/2014
@version P12
/*/
//-----------------------------------------------------------------------------------------

Static Function Ft600Check(cAliasOrig,cAliasDest,cOrigem,cDestino,lPropos)

Local lRet  	:= .T.
Local aStrut	:= {}
Local aDados	:= {}
Local nCampo	:= 0
Local cCampo	:= ""
Local cPrefx	:= ""

Default lPropos	:= .F.

//Analisa cada item das versoes do projeto para identificar as alteracoes.
DbSelectArea(cAliasOrig)
If cAliasOrig == "ADZ"
	DbsetOrder(3)
Else
	DbSetOrder(1)
EndIf
If DbSeek(cOrigem,.T.)
	aStrut	:= &(cAliasOrig + "->(dbStruct())")
	aDados	:= Array(1,Len(aStrut))

	aEval(aStrut,{|cValue,nIndex| aDados[1,nIndex]:= {aStrut[nIndex,1],FieldGet(FieldPos(aStrut[nIndex,1]))}})
	
	DbSelectArea(cAliasDest)
	If cAliasDest == "ADZ"
		DbsetOrder(3)
	Else
		DbSetOrder(1)
	EndIf
	
	If DbSeek(cDestino,.T.)
		cPrefx := PrefixoCpo(cAliasDest)
		For	nCampo := 1 To Len(aDados[1])
			cCampo := cPrefx + SUBSTRING(aDados[1,nCampo,1],AT("_",aDados[1,nCampo,1]),Len(aDados[1,nCampo,1]))
			If !("REVISA" $ aDados[1,nCampo,1]) .AND. !("PREVIS" $ aDados[1,nCampo,1]) .AND. !("HISTOR" $ aDados[1,nCampo,1]) .AND. (aDados[1,nCampo,2] <> (cAliasDest)->&(cCampo)  )
				If lPropos .And. !((cCampo) == "ADZ_ITEMOR" .Or. (cCampo) == "ADZ_ORCAME" .Or. (cCampo) == "ADZ_PROPOS" .Or. (cCampo) == "ADZ_ITEM" .Or. (cCampo) == "ADZ_REVISA")
					lRet:= .F.
					Exit
				ElseIf !lPropos
					lRet:= .F.
					Exit
				EndIf
			EndIf
		Next
	EndIf
EndIf

Return(lRet)

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600MontaTree

Cria o tree a partir do array.

@sample  Ft600MontaTree

@author  Serviços/CRM
@since   29/04/2014
@version P12
/*/
//-----------------------------------------------------------------------------------------
Function Ft600MontaTree(oTree,aTree)

Local nItem := 0
Local cRes  := ""
Local cTipo := ""

//Monta um tree a partir do array com a estrutura informados.
ProcRegua(Len(aTree))

oTree:Reset()
oTree:BeginUpdate()

For nItem:= 1 To Len(aTree)
	cTipo:= aTree[nItem,6]

	Do Case
		//Verifica os bitmaps da Proposta Comercial.
	Case (aTree[nItem,1] $ "AGPADY")
		If (cTipo == "N")
			cRes:= "BPMSEDT4"
		Else
			cRes:= "BPMSEDT1"
		EndIf
		
		//Verifica os bitmaps do Produto.
	Case (aTree[nItem,8] == "1")
		If (cTipo == "N")
			cRes:= "PMSTASK4"
		ElseIf (cTipo == "I")
			cRes:= "BMPINCLUIR"
		ElseIf (cTipo == "E")
			cRes:= "EXCLUIR"
		ElseIf (cTipo == "P")
			cRes:= "BPMSTSK4A_MDI"
		Else
			cRes:= "NOTE"
		EndIf
		
		//Verifica os bitmaps do Acessorio.
	Case (aTree[nItem,8] == "2")
		If (cTipo == "N")
			cRes:= "PMSTASK2"
		ElseIf (cTipo == "I")
			cRes:= "SDUSETDEL"
		ElseIf (cTipo == "E")
			cRes:= "SDUDRPTBL"
		ElseIf (cTipo == "P")
			cRes:= "BPMSTSK2A_MDI"
		Else
			cRes:= "S4WB005N"
		EndIf
	End Case
	
	oTree:TreeSeek(aTree[nItem,5])
	If nItem == 1
		oTree:AddItem(aTree[nItem,3]+Space(100),aTree[nItem,4],cRes,cRes,,,2)
	Else
		oTree:AddItem(aTree[nItem,3],aTree[nItem,4],cRes,cRes,,,2)
	EndIf
	IncProc()

Next nItem

DBENDTREE oTree
oTree:TreeSeek(aTree[1,4])
oTree:EndUpdate()
oTree:Refresh()

Return(.T.)

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600VisDet

Visualiza Oportunidade de Venda comparada.

@sample  Ft600VisDet

@author  Serviços/CRM
@since   29/04/2014
@version P12
/*/
//-----------------------------------------------------------------------------------------
Function Ft600VisDet(oTree,aTree)

Local cCargo:= oTree:GetCargo()
Local aArea := {}
Local nPos  := Ascan(aTree,{|x| x[4] == cCargo})
Local cAlias:= aTree[nPos,1]
Local cSeek := aTree[nPos,2]

If !Empty(cSeek)
	aArea := GetArea()
	DbSelectArea(cAlias)

	If cAlias == "ADZ"
		(cAlias)->(DbsetOrder(3))
	Else
		(cAlias)->(DbSetOrder(1))
	EndIf

	If (cAlias)->(DbSeek(cSeek))
		If cAlias == "AGP"
			FwExecView(STR0023, "VIEWDEF.FATA600C", MODEL_OPERATION_VIEW) //"Visualizar"
		Else
			FwExecView(STR0023, "VIEWDEF.FATA600", MODEL_OPERATION_VIEW) //"Visualizar"
		EndIf
	EndIf

	RestArea(aArea)
	aSize( aArea, 0 )

EndIf

Return(.T.)

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600Item

Funcao que exibe os dados a serem comparados.

@sample  Ft600Item

@author  Serviços/CRM
@since   29/04/2014
@version P12
/*/
//-----------------------------------------------------------------------------------------
Function Ft600Item(oTree, oTree2, aOrigem, aOpVComp,;
                   aCmp1, aCmp2)

Local aArea		:= GetArea()
Local aDados		:= {}
Local aStrut		:= {}
Local nPosComp	:= 0
Local nPosOrig	:= 0
Local cAlias		:= ""
Local cSeekComp	:= ""
Local cSeekOrig	:= ""
Local cRevisa1	:= ""
Local cRevisa2	:= ""
Local bCampo1		:= {|cCampo|(aCmp1[1])->(FieldGet((aCmp1[1])->(FieldPos(aCmp1[1]+"_"+cCampo))))}
Local bCampo2		:= {|cCampo|(aCmp2[1])->(FieldGet((aCmp2[1])->(FieldPos(aCmp2[1]+"_"+cCampo))))}
Local nTmPropos	:= GetSX3Cache("ADY_PROPOS","X3_TAMANHO")
Local cPosOrig	:= ""

DbSelectArea(aCmp1[1])
dbGoTo(aCmp1[2])
cRevisa1	:= Eval(bCampo1,"PREVIS")

DbSelectArea(aCmp2[1])
dbGoTo(aCmp2[2])
cRevisa2	:= Eval(bCampo2,"PREVIS")

Aadd(aDados,{"",{STR0079 +cRevisa1,CLR_BLACK},{STR0079+cRevisa2,CLR_BLACK},"_PREVIS"}) //"Revisão "

//Verifica as informacoes do item que se deseja comparar.
nPosComp := Ascan(aOpVComp,{|x| x[4] == oTree2:GetCargo()})
If (nPosComp > 0)
	cAlias   := aOpVComp[nPosComp,1]
	cSeekComp:= aOpVComp[nPosComp,2]
	oTree:TreeSeek(aOpVComp[nPosComp,4])

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Posiciona e armazena os dados do item a ser comparado.³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	DbSelectArea(cAlias)
	If cAlias == "ADZ"
		DbsetOrder(3)
	Else
		DbSetOrder(1)
	EndIf
	If DbSeek(cSeekComp)
		aStrut:= Ft600Strut(cAlias)
	
		aEval(aStrut,{|cValue,nIndex| Aadd(aDados,{ aStrut[nIndex,1],;
													{"",CLR_BLACK}	 ,;
													{If(aOpVComp[nPosComp,6] <> "E",If(Empty(aStrut[nIndex,3]).AND. aStrut[nIndex][8]=="C",FieldGet(FieldPos(aStrut[nIndex,2])),Transform(FieldGet(FieldPos(aStrut[nIndex,2])),aStrut[nIndex,3])),;
													""),;
													CLR_BLACK},;
													SubStr(aStrut[nIndex][2],at("_",aStrut[nIndex][2]),Len(aStrut[nIndex][2]))})})
	EndIf
EndIf

//Verifica os dados dos itens a serem comparados.
nPosOrig:= Ascan(aOrigem,{|x| x[4] == oTree2:GetCargo()})
If (nPosOrig > 0)
	cAlias   := aOrigem[nPosOrig,1]
	cSeekOrig:= aOrigem[nPosOrig,2]
	oTree2:TreeSeek(aOrigem[nPosOrig,4])

	//Posiciona e armazena os dados do item comparado.
	DbSelectArea(cAlias)
	If cAlias == "ADZ"
		DbsetOrder(3)
	Else
		DbSetOrder(1)
	EndIf
	If DbSeek(cSeekOrig)
		aStrut:= Ft600Strut(cAlias)
		Ft600MtDad(aStrut,@aDados,cAlias)
	EndIf
ElseIf nPosComp == 1
	cAlias   := aOrigem[nPosComp,1]
	cSeekOrig:= aOrigem[nPosComp,2]
	oTree2:TreeSeek(aOrigem[nPosComp,4])
	
	//Posiciona e armazena os dados do item comparado.
	DbSelectArea(cAlias)
	If cAlias == "ADZ"
		DbsetOrder(3)
	Else
		DbSetOrder(1)
	EndIf
	
	If DbSeek(cSeekOrig)
		aStrut:= Ft600Strut(cAlias)
		Ft600MtDad(aStrut,@aDados,cAlias)
	EndIf
	
ElseIf nPosComp > 1 .And. SubStr(oTree:GetCargo(), Len(aCmp1[1]) + Len(xFilial(aCmp1[1])) + 1, nTmPropos) <> SubStr(oTree2:GetCargo(), Len(aCmp1[1]) + Len(xFilial(aCmp1[1])) + 1, nTmPropos)
	cPosOrig:= SubStr(oTree2:GetCargo(),Len(aCmp1[1]) + Len(xFilial(aCmp1[1])) + 1 + nTmPropos,3)
	If cPosOrig > "0"
		cAlias   := SubStr(oTree2:GetCargo(),1,Len(aCmp1[1]))
		cSeekOrig:= aOrigem[1][2] + cPosOrig
		oTree2:TreeSeek(cAlias + SubStr(aOrigem[1][2], 1, Len(xFilial(aCmp1[1])) + nTmPropos) + cPosOrig)
	
		//Posiciona e armazena os dados do item comparado.
		DbSelectArea(cAlias)
		If cAlias == "ADZ"
			DbsetOrder(3)
		Else
			DbSetOrder(1)
		EndIf
		If DbSeek(cSeekOrig)
			aStrut:= Ft600Strut(cAlias)
			Ft600MtDad(aStrut,@aDados,cAlias)
		EndIf
	Else
		aEval(aStrut,{|cValue,nIndex| (aDados[nIndex+1,2,2]:= aDados[nIndex+1,3,2]:=If(aDados[nIndex+1,2,1] == aDados[nIndex+1,3,1],CLR_BLACK,CLR_HRED)) })
	EndIf
Else
	aEval(aStrut,{|cValue,nIndex| (aDados[nIndex+1,2,2]:= aDados[nIndex+1,3,2]:=If(aDados[nIndex+1,2,1] == aDados[nIndex+1,3,1],CLR_BLACK,CLR_HRED)) })
EndIf

PmsDispBox(aDados,3,"",{40,120,120},,3,,RGB(250,250,250))

Return(.T.)

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600Strut

Funcao que retorna a estrutura do alias selecionado.

@sample  Ft600Strut

@author  Serviços/CRM
@since   29/04/2014
@version P12
/*/
//-----------------------------------------------------------------------------------------
Function Ft600Strut(cAlias)

Local aArea:= GetArea()
Local aRet := {}

DbSelectArea("SX3")
DbSetOrder(1)
DbSeek(cAlias)
While !EOF() .AND. (X3_ARQUIVO == cAlias)
	If X3Uso(X3_USADO) .AND. cNivel >= X3_NIVEL .AND. (!TRIM(SX3->X3_CAMPO) $ "_FILIAL") .AND.;
		(X3_CONTEXT <> "V") .AND. (X3_TIPO <> "M")
		AADD(aRet,{	TRIM(X3TITULO()),;
						X3_CAMPO,;
						X3_PICTURE,;
						X3_TAMANHO,;
						X3_DECIMAL,;
						X3_VALID,;
						X3_USADO,;
						X3_TIPO,;
						X3_ARQUIVO,;
						X3_CONTEXT 	} )
	EndIf
	dbSkip()
End

RestArea(aArea)

Return(aRet)

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600MtDad

Preenche os dados da tabela de origem na estrutura de comparação.

@sample  Ft600MtDad

@author  Serviços/CRM
@since   29/04/2014
@version P12
/*/
//-----------------------------------------------------------------------------------------
Static Function Ft600MtDad(aStrut,aDados,cAlias)

Local nLin	:= 0
Local cPref	:= PrefixoCpo(cAlias)
Local cCampo:= ""
Local nCpo	:= 0

For nLin := 2 to Len(aDados)
	
	cCampo	:= AllTrim(cPref + aDados[nLin,4])
	nCpo	:= aScan(aStrut,{|x| AllTrim(x[2]) == cCampo })
	
	If nCpo > 0
		If Empty(aStrut[nCpo,3]) .AND. aStrut[nCpo][8]=="C"
			aDados[nLin,2,1]:= FieldGet(FieldPos(aStrut[nCpo,2]))
		Else
			aDados[nLin,2,1]:= Transform(FieldGet(FieldPos(aStrut[nCpo,2])), aStrut[nCpo,3] )
		EndIf
		
		If	(ValType(aDados[nLin,2,1]) == "C" .AND. AllTrim(aDados[nLin,2,1]) == AllTrim(aDados[nLin,3,1]) ) .OR.;
			(aDados[nLin,2,1] == aDados[nLin,3,1])
			
			aDados[nLin,2,2]:= CLR_BLACK
			aDados[nLin,3,2]:= CLR_BLACK
			
		Else
		
			aDados[nLin,2,2]:= CLR_HRED
			aDados[nLin,3,2]:= CLR_HRED
		
		EndIf
	EndIf
Next nLin

Return Nil

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600CtrMenu

Funcao que controla as propriedades do Menu PopUp.

@sample  Ft600CtrMenu

@author  Serviços/CRM
@since   29/04/2014
@version P12
/*/
//-----------------------------------------------------------------------------------------
Function Ft600CtrMenu(nTree,oMenu,oTree)

Local cAlias	:= SubStr(oTree:GetCargo(),1,3)

If (cAlias $ "ADYAGP")
	oMenu:aItems[1]:Enable()
	If (nTree == 2)
		oMenu:aItems[2]:Enable()
	EndIf
Else
	oMenu:aItems[1]:Disable()
	If (nTree == 2)
		oMenu:aItems[2]:Enable()
	EndIf
EndIf

Return(.T.)

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} A600LdPROD
Prepara array de produtos para load no beneficio

@sample     A600LdPROD( oModel )

@param             oModel             Modelo de dados.

@author     Serviços/CRM
@since       01/08/2013
@version    P12
/*/
//-----------------------------------------------------------------------------------------
Function A600LdPROD( oModel )

Local aRet               := {}
Local oMdlProd           := oModel:GetModel('ADZPRODUTO')
Local nI                 := 0

For nI := 1 to oMdlProd:Length()
	oMdlProd:GoLine(nI)
	
	If ( !oMdlProd:IsDeleted() )
		AAdd( aRet, { PadR( FwFldGet('ADY_PROPOS'), 15 ), '1', FwFldGet('ADY_PREVIS'), oMdlProd:GetValue('ADZ_PRODUT'), oMdlProd:GetValue('ADZ_DESCRI'), oMdlProd:GetValue('ADZ_ITEM') } )
	EndIf
Next nI

Return (aRet)

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600IncItem
Prepara array de itens para load no beneficio

@sample     A600LdPROD( oModel )

@param             oModel             Modelo de dados.

@author     Serviços/CRM
@since       01/08/2013
@version    P12
/*/
//-----------------------------------------------------------------------------------------
Function Ft600IncItem( oMdl, cCampo )

Local cRet          := '01'
Local nUltLinha     := oMdl:Length()
Local cTemp         := oMdl:GetValue(cCampo,nUltLinha)

If !Empty(cTemp)
	cRet := Soma1(cTemp)
EndIf

Return cRet

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} A600ATProp
Atualiza o status da proposta

@sample     A600ATProp()

@author     Serviços/CRM
@since       31/01/2011
@version    P12
/*/
//-----------------------------------------------------------------------------------------
Function A600ATProp(cProposta,cParams,cIdECM)

Local aAreaADY := ADY->(GetArea())  //Guarda a area atual
Local cStatus  := Substr(cParams,Len(cParams),1)  //Retorna o status de aprovacao da proposta.
Local cUsuario := Substr(cParams,1,At("|",cParams)-1)

If cStatus == "S"
	
	DbSelectArea("ADY")
	DbSetOrder(1)
	
	If DbSeek(xFilial("ADY")+cProposta)
		
		If 	ADY->ADY_STATUS == "F"
			RecLock("ADY",.F.)
			ADY->ADY_STATUS := "A"
			MsUnlock()
		EndIf
		
	EndIf
	
	DbSelectArea("AGY")
	DbSetOrder(1)
	
	If AGY->(DbSeek(xFilial("AGY")+PADR(cIdECM,AGY->(TAMSX3("AGY_IDECM")[1]))+PADR(AllTrim(UsrRetName(cUsuario)),AGY->(TAMSX3("AGY_CODUSR")[1]))))
		
		If Empty(AGY->AGY_STATUS) .AND. Empty(AGY->AGY_TPAPV)
			RecLock("AGY",.F.)
			AGY->AGY_STATUS := cStatus
			AGY->AGY_TPAPV  := "U"
			AGY->AGY_DTFIM  := DDATABASE
			MsUnLock()
			
			StartJob("A600ATECM",GetEnvServer(),.F.,cEmpAnt,cFilAnt,cProposta,cIdECM,cStatus,.T.)
			
		EndIf
	EndIf
	
ElseIf cStatus == "N"
	
	DbSelectArea("AGY")
	DbSetOrder(1)
	
	If AGY->(DbSeek(xFilial("AGY")+PADR(cIdECM,AGY->(TAMSX3("AGY_IDECM")[1]))+PADR(AllTrim(UsrRetName(cUsuario)),AGY->(TAMSX3("AGY_CODUSR")[1]))))
		
		If Empty(AGY->AGY_STATUS) .AND. Empty(AGY->AGY_TPAPV)
			RecLock("AGY",.F.)
			AGY->AGY_STATUS := cStatus
			AGY->AGY_TPAPV  := "U"
			AGY->AGY_DTFIM  := DDATABASE
			MsUnLock()
			
			StartJob("A600ATECM",GetEnvServer(),.F.,cEmpAnt,cFilAnt,cProposta,cIdECM,cStatus,.T.)
			
		EndIf
	EndIf
EndIf

RestArea(aAreaADY) //Restaura a area

Return(.T.)

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} A600PXML
Cria XML com os dados da proposta

@sample     A600PXML()

@author     Serviços/CRM
@since       31/01/2011
@version    P12
/*/
//-----------------------------------------------------------------------------------------
Function A600PXML(cProposta)

Local aAreaADY  := ADY->(GetArea())						   						//Guarda a area atual
Local aAreaACA  := ACA->(GetArea())						   						//Guarda a area atual
Local aAreaAD1  := AD1->(GetArea())                           						//Guarda a area atual
Local aAreaADZ  := ADZ->(GetArea()) 						   						//Guarda a area atual
Local cSimb 	:= Alltrim(SuperGetMv("MV_SIMB1"))+Space(1)   						//Moeda padrao
Local cCodRepr  := ""															    //Codigo do grupo representante
Local cNomVend  := ""															    //Nome do vendedor
Local cEntidad  := ""
Local cNome 	:= ""
Local cXml 		:= ""  										   						//Armazena XML com os dados da proposta
Local cSimbVar  := ""               												//Moeda variavel
Local cDscOp    := ""               						 					    //Descricao da oportunidade
Local cDescRep  := ""                                        					    //Descricao do representante
Local dDtCad    := ""              							   						//Data de cadastro da oportunidade
Local nTotProp 	:= 0                 						 						//Valor total da proposta
Local nPMxDesc  := 0 			     						   						//Percentual maximo de desconto.
Local nVMxDesc  := 0 		         						   						//Valor maximo de desconto.
Local nPMxAcr   := 0 				 						   						//Percentual maximo para acrescimo.
Local nVMxAcr   := 0 		        						  						//Valor maximo para acrescimo.
Local cFilADZ		:= xFilial("ADZ")
Local cFilSE4		:= xFilial("SE4")

DbSelectArea("ADY")
DbSetOrder(1)

If DbSeek(xFilial("ADY")+cProposta)
	
	cCodRepr  := POSICIONE("SA3",1,xFilial("SA3")+ADY->ADY_VEND,"A3_GRPREP")    //Codigo do grupo representante
	cNomVend  := POSICIONE("SA3",1,xFilial("SA3")+ADY->ADY_VEND,"A3_NOME")      //Nome do vendedor
	
	DbSelectArea("AD1")
	DbSetOrder(1)
	
	If DbSeek(xFilial("AD1")+ADY->ADY_OPORTU)
		cDscOp   := Alltrim(AD1->AD1_DESCRI)
		dDtCad	 := AD1->AD1_DATA
	EndIf
	
	DbSelectArea("ACA")
	DbSetOrder(1)
	
	If DbSeek(xFilial("ACA")+cCodRepr)
		
		cDescRep := Alltrim(ACA->ACA_DESCRI)
		nPMxAcr  := ACA->ACA_PACRMX
		nVMxAcr  := ACA->ACA_VACRMX
		nPMxDesc := ACA->ACA_PDSCMX
		nVMxDesc := ACA->ACA_VDSCMX
		
	EndIf
	
	If ADY->ADY_ENTIDA == "1"
		cEntidad := Upper(STR0122) //"Cliente"
		cNome := POSICIONE("SA1",1,xFilial("SA1")+ADY->ADY_CODIGO+ADY->ADY_LOJA,"A1_NOME")
	Else
		cEntidad := Upper(STR0123)   //"Prospect"
		cNome := POSICIONE("SUS",1,xFilial("SUS")+ADY->ADY_CODIGO+ADY->ADY_LOJA,"US_NOME")
	EndIf
	
	cXml += '<?xml version="1.0" encoding="ISO-8859-1"?>'
	cXml += '<?xml-stylesheet type="text/xsl" href="proposta.xsl"?>'
	cXml += '<FATA600>'
	cXml += '<ADY_PROPOS>'
	cXml += '<value>'+ADY->ADY_PROPOS+'</value>'
	cXml += '</ADY_PROPOS>'
	cXml += '<ADY_OPORTU>'
	cXml += '<value>'+ADY->ADY_OPORTU+'</value>'
	cXml += '</ADY_OPORTU>'
	cXml += '<AD1_DESCRI>'
	cXml += '<value>'+AllTrim(cDscOp)+'</value>'
	cXml += '</AD1_DESCRI>'
	cXml += '<ADY_ENTIDA>'
	cXml += '<value>'+cEntidad+'</value>'
	cXml += '</ADY_ENTIDA>'
	cXml += '<ADY_CODIGO>'
	cXml += '<value>'+AllTrim(cNome)+'</value>'
	cXml += '</ADY_CODIGO>'
	cXml += '<A3_COD>'
	cXml += '<value>'+AllTrim(ADY->ADY_VEND)+'</value>'
	cXml += '</A3_COD>'
	cXml += '<A3_NOME>'
	cXml += '<value>'+AllTrim(cNomVend)+'</value>'
	cXml += '</A3_NOME>'
	cXml += '<AD1_DATA>'
	cXml += '<value>'+DToc(dDtCad)+'</value>'
	cXml += '</AD1_DATA>'
	cXml += '<ACA_GRPREP>'
	cXml += '<value>'+cCodRepr+'</value>'
	cXml += '</ACA_GRPREP>'
	cXml += '<ACA_DESCRI>'
	cXml += '<value>'+Alltrim(cDescRep)+'</value>'
	cXml += '</ACA_DESCRI>'
	cXml += '<ACA_PACRMX>'
	cXml += '<value>'+Alltrim(cValToChar(nPMxAcr))+" %"+'</value>'
	cXml += '</ACA_PACRMX>'
	cXml += '<ACA_VACRMX>'
	cXml += '<value>'+cSimb+Alltrim(cValToChar(Transform(nVMxAcr,"@E 999,999,999.99")))+'</value>'
	cXml += '</ACA_VACRMX>'
	cXml += '<ACA_PDSCMX>'
	cXml += '<value>'+Alltrim(cValToChar(nPMxDesc))+" %"+'</value>'
	cXml += '</ACA_PDSCMX>'
	cXml += '<ACA_VDSCMX>'
	cXml += '<value>'+cSimb+Alltrim(cValToChar(Transform(nVMxDesc,"@E 999,999,999.99")))+'</value>'
	cXml += '</ACA_VDSCMX>'
	cXml += '<STATUS>'
	cXml += '<value>'+Upper(STR0128)+'</value>' //Em aprovacao
	cXml += '</STATUS>'
	
	cXml += '<itens>'
	
	DbSelectArea("ADZ")
	DbSetOrder(3)
	
	If DbSeek(cFilADZ+ADY->ADY_PROPOS+ADY->ADY_PREVIS)
		
		While ADZ->(!EOF()) .AND. ADZ->ADZ_FILIAL == cFilADZ .AND.  ADZ->ADZ_PROPOS == ADY->ADY_PROPOS .AND. ADZ->ADZ_REVISA == ADY->ADY_PREVIS
			
			cSimbVar := Alltrim(SuperGetMv("MV_SIMB"+ADZ->ADZ_MOEDA))+Space(1) // Moeda selecionada pelo usuario
			
			cXml += '<item>'
			cXml += '<ADZ_ITEM>'
			cXml += '<value>'+ADZ->ADZ_ITEM+'</value>'
			cXml += '</ADZ_ITEM>'
			cXml += '<ADZ_PRODUT>'
			cXml += '<value>'+AllTrim(ADZ->ADZ_PRODUT)+'</value>'
			cXml += '</ADZ_PRODUT>'
			cXml += '<ADZ_DESCRI>'
			cXml += '<value>'+AllTrim(ADZ->ADZ_DESCRI)+'</value>'
			cXml += '</ADZ_DESCRI>'
			cXml += '<ADZ_UM>'
			cXml += '<value>'+ADZ->ADZ_UM+'</value>'
			cXml += '</ADZ_UM>'
			cXml += '<ADZ_CONDPG>'
			cXml += '<value>'+AllTrim(POSICIONE("SE4",1,cFilSE4+ADZ->ADZ_CONDPG,"E4_DESCRI"))+'</value>'
			cXml += '</ADZ_CONDPG>'
			cXml += '<ADZ_QTDVEN>'
			cXml += '<value>'+cValToChar(ADZ->ADZ_QTDVEN)+'</value>'
			cXml += '</ADZ_QTDVEN>'
			cXml += '<ADZ_PRCVEN>'
			cXml += '<value>'+cSimbVar+AllTrim(cValToChar(Transform(ADZ->ADZ_PRCVEN,"@E 999,999,999.99")))+'</value>'
			cXml += '</ADZ_PRCVEN>'
			cXml += '<ADZ_PRCTAB>'
			cXml += '<value>'+cSimbVar+AllTrim(cValToChar(Transform(ADZ->ADZ_PRCTAB,"@E 999,999,999.99")))+'</value>'
			cXml += '</ADZ_PRCTAB>'
			cXml += '<ADZ_DESCON>'
			cXml += '<value>'+cSimbVar+AllTrim(cValToChar(Transform(ADZ->ADZ_DESCON,"@E 999,999,999.99")))+'</value>'
			cXml += '</ADZ_DESCON>'
			cXml += '<ADZ_VALDES>'
			cXml += '<value>'+cSimbVar+AllTrim(cValToChar(Transform(ADZ->ADZ_VALDES,"@E 999,999,999.99")))+'</value>'
			cXml += '</ADZ_VALDES>'
			cXml += '<ADZ_TOTAL>'
			cXml += '<value>'+cSimbVar+AllTrim(cValToChar(Transform(ADZ->ADZ_TOTAL,"@E 999,999,999.99")))+'</value>'
			cXml += '</ADZ_TOTAL>'
			cXml += '</item>'
			
			nTotProp += ADZ->ADZ_TOTAL
			
			ADZ->(DbSkip())
			
		End
	EndIf
	
	cXml += '</itens>'
	cXml += '<ADZ_NTOTP>'
	cXml += '<value>'+Alltrim(SuperGetMv("MV_SIMB1"))+Space(1)+AllTrim(cValToChar(Transform(nTotProp,"@E 999,999,999.99")))+'</value>'
	cXml += '</ADZ_NTOTP>'
	cXml += '</FATA600>'
	
EndIf

RestArea(aAreaADY) //Restaura area
RestArea(aAreaACA) //Restaura area
RestArea(aAreaAD1) //Restaura area
RestArea(aAreaADZ) //Restaura area

Return(cXML)

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} A600AProp

Aprova proposta bloqueada.

@sample     A600AProp(  )

@param		 ExpO1 - Objeto Browse

@return     ExpL: Verdadeiro/Falso

@author     Victor Bitencourt
@since      08/09/2014
@version    P12
/*/
//-----------------------------------------------------------------------------------------
Function A600AProp(oBrwPBlq)

Local aAreaADY	:= ADY->(GetArea())     		   	 //Guarda area atual
Local cProposta	:= oBrwPBlq:aArray[oBrwPBlq:nAt,1] //Codigo da proposta
Local lFecha		:= .F.         						 //Fecha a tela proposta(s) bloqueada(s)
Local lIntECM		:= SuperGetMv("MV_CRMXECM",,.F.)
Local cIdECM		:= ""
Local cChave		:= ''
Local cMsg			:= ''
Local aAlcada		:= {}
Local lAlcada		:= .T. 

DbSelectArea("ADY")
DbSetOrder(1)

If DbSeek(xFilial("ADY")+cProposta)
	
	cChave 	:= ADY->ADY_PROPOS+ADY->ADY_PREVIS
	aAlcada	:= FT600GtAlc(cChave)
	lAlcada	:= FT600VlDc(aAlcada)
	If ADY->ADY_STATUS == "F" .And. lAlcada
		
		If MsgNoYes(STR0095,STR0096) //"&Aprovar" //"Deseja fazer aprovação desta proposta?"//"Atenção!"
			
			RecLock("ADY",.F.)
			ADY->ADY_STATUS := "A"
			MsUnlock()
			
			If lIntECM
				
				DbSelectArea("AGY")
				DbSetOrder(2)
				
				If DbSeek(xFilial("AGY")+cChave)
					cIdECM := AllTrim(AGY->AGY_IDECM)
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³Atualiza o status da proposta no ECM.³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					If Empty(AGY->AGY_STATUS) .AND. Empty(AGY->AGY_TPAPV)
						MsgRun(STR0129,,{|| A600ATECM(cEmpAnt,cFilAnt,cProposta,cIdECM,"S")}) //"Aprovando a proposta no By You ECM..."
					EndIf
					
				EndIf
				
			EndIf
			
			aDel(oBrwPBlq:aArray,oBrwPBlq:nAt)
			aSize(oBrwPBlq:aArray,Len(oBrwPBlq:aArray)-1)
			
		EndIf
		
	ElseIf !lAlcada
		cMsg := FT600AlcMg(aAlcada)
		Help( , ,"ft600AProp", ,STR0380,1,1,,,,,,{cMsg} ) //'Usuário não possui limite para liberar a proposta'
		
	ElseIf ADY->ADY_STATUS == "A"
		AVISO(STR0096,STR0124,{STR0099},1) //"Atenção!"//"Proposta já foi aprovada por outro usuário!"//"Fechar"
		aDel(oBrwPBlq:aArray,oBrwPBlq:nAt)
		aSize(oBrwPBlq:aArray,Len(oBrwPBlq:aArray)-1)
	EndIf
	
	If Len(oBrwPBlq:aArray) == 0
		lFecha := .T.
	Else
		oBrwPBlq:Refresh()
	EndIf
	
EndIf

RestArea(aAreaADY)

Return(lFecha)

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} A600RProp
Atualiza o Browse

@sample     A600RProp(  )

@param		 ExpO1 - Objeto Browse
@param		 ExpC1 - Codigo do Vendendor

@return     ExpL: Verdadeiro/Falso

@author     Victor Bitencourt
@since      08/09/2014
@version    P12
/*/
//-----------------------------------------------------------------------------------------
Function A600RProp(oBrwPBlq,cCodVSup)

Local aBrwRProp	:= A600BProp(cCodVSup)
Local lFecha		:= .F.

oBrwPBlq:SetArray(aBrwRProp)

oBrwPBlq:bLine := {|| {aBrwRProp[oBrwPBlq:nAt,1],;
                       aBrwRProp[oBrwPBlq:nAt,2],;
                       aBrwRProp[oBrwPBlq:nAt,3],;
                       aBrwRProp[oBrwPBlq:nAt,4]}}

If Len(oBrwPBlq:aArray) == 0
	lFecha := .T.
	AVISO(STR0096,STR0098,{STR0099},1)  //"Não há proposta(s) bloqueada(s) para aprovação"//"Fechar"
	aBrwRProp := {}
Else
	oBrwPBlq:Refresh()
EndIf

oBrwPBlq:Refresh()

Return(lFecha)

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} A600BProp
Busca propostas bloqueadas.

@sample     A600BProp(  )

@param		 ExpC - Codigo do Vendedor superior

@return     ExpA1: Propostas Bloqueadas

@author     Victor Bitencourt
@since      08/09/2014
@version    P12
/*/
//-----------------------------------------------------------------------------------------
Function A600BProp(cCodVSup)

Local aArea		:= GetArea()  											//Guarda area atual.
Local cQuery		:= ""     							   						//Armazena a query.
Local cEntidad	:= ""       												//Entidade Cliente ou  Prospect.
Local cNome		:= ""                 									//Nome.
Local cCodInt   	:= "" 							//Codigo inteligente.
Local aVendSub  	:= {}             							//Array com vendedores subordinados.
Local cVendSub	:= ""														//Vendedores superiores.
Local cAlias		:= "TMPBLQ"												//Tabela temporaria.
Local aRet			:= {}
Local nX			:= 0														//Incremento utilizado no laco For.
Local cFilSA1		:= xFilial("SA1")
Local cFilSSU		:= xFilial("SSU")

If ! Empty(cCodVSup)
	
	If nModulo == 73
		cCodInt	:= Posicione("AO3",1,xFilial("AO3")+cCodVSup,"AO3_IDESTN")
		aVendSub	:= Ft520Sub(cCodInt)
	Else
		DbSelectArea("SA3")
		SA3->(DbSetOrder(1))
		If SA3->(DbSeek(xFilial("SA3") + cCodVSup))
			cCodInt	:= SA3->A3_NVLSTR
			If ! Empty(cCodInt)
				aVendSub	:= Ft520Sub(cCodInt)
			EndIf
		EndIf
	EndIf
EndIf

If Len(aVendSub) > 0
	
	For nX := 1 to Len(aVendSub)
		cVendSub += "'"+aVendSub[nX]+"',"
	Next nX
	
	cVendSub := Substr(cVendSub,1,Len(cVendSub)-1)
	
	cQuery	:= "SELECT ADY_PROPOS,ADY_DATA,ADY_ENTIDA,ADY_CODIGO,ADY_LOJA,R_E_C_N_O_ FROM " + RetSqlName("ADY")
	cQuery	+= " WHERE ADY_FILIAL = '"+xFilial("ADY")+"' AND ADY_VEND IN ("+cVendSub+")  AND  ADY_STATUS = 'F' AND D_E_L_E_T_ = ' '"
	
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAlias,.F.,.T.)
	
	While (cAlias)->(!EOF())
		
		If (cAlias)->ADY_ENTIDA == "1"
			cEntidad := STR0122 //"Cliente"
			cNome := POSICIONE("SA1",1,cFilSA1+(cAlias)->ADY_CODIGO+(cAlias)->ADY_LOJA,"A1_NOME")
		Else
			cEntidad := STR0123 //"Prospect"
			cNome := POSICIONE("SUS",1,cFilSSU+(cAlias)->ADY_CODIGO+(cAlias)->ADY_LOJA,"US_NOME")
		EndIf
		
		aAdd(aRet,{(cAlias)->ADY_PROPOS,STOD((cAlias)->ADY_DATA),cEntidad,cNome,(cAlias)->R_E_C_N_O_})
		
		(cAlias)->(DbSkip())
	End
	
	(cAlias)->(dbclosearea())
	
EndIf

RestArea(aArea)

Return(aRet)

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} A600CRMDPC

Desbloqueia proposta comercial - Chamado somente da Area de Trabalho do CRM

@sample     A600CRMDPC( )

@param		 ExpC - Codigo do Vendedor superior

@return     Nenhum

@author     Victor Bitencourt
@since      08/09/2014
@version    P12
/*/
//-----------------------------------------------------------------------------------------
Function A600CRMDPC(cCodVSup)

Local lPermissao := .F.
Local aArea      := GetArea()

Default cCodVSup := ""

If !Empty(cCodVSup)
	lPermissao := A600LProp(cCodVSup,.T.)
	If lPermissao
		A600DesbP(cCodVSup)
	EndIf
EndIf

RestArea(aArea)

Return

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} A600Pesq

Localiza as propostas bloqueadas no objeto browse

@sample     A600Pesq( )

@param		 ExpO1 - Objeto Browse
@param		 ExpC1 - String a ser localizada
@param		 ExpL1 - Procura desde o inicio

@return     ExpL: Verdadeiro/Falso

@author     Victor Bitencourt
@since      08/09/2014
@version    P12
/*/
//-----------------------------------------------------------------------------------------
Function A600Pesq(oBrowse,cString,lInicio)

Static nStartLine                // Controle de proxima procura
Static nStartCol                 // Coluna inicial

Local nCount 	:= 0                // Contador temporário
Local nCount2 	:= 0               // Contador temporário
Local lAchou 	:= .F.              // Se encontrou a informacao desejada

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Inicializa a variável da linha inicial de procura.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If ValType(nStartLine) <> "N"
	nStartLine := 1
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Inicializa a variável da coluna inicial de procura.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If ValType(nStartCol) <> "N"
	nStartCol := 1
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Se é para procurar desde o início.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lInicio
	nStartLine   := 1
	nStartCol    := 1
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Procura em todas as linhas e colunas pelo conteúdo solicitado.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
For nCount := nStartLine To Len(oBrowse:aArray)
	For nCount2 := nStartCol To Len(oBrowse:aArray[nCount])
		If ValType(oBrowse:aArray[nCount][nCount2]) $('C,D')
			If Upper(AllTrim(cString)) $ Upper(AllTrim(oBrowse:aArray[nCount][nCount2]))
				oBrowse:nAt := nCount
				oBrowse:Refresh()
				nStartLine   := nCount
				nStartCol    := nCount2 + 1
				lAchou := .T.
				Exit
			EndIf
		EndIf
	Next

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Se já encontrou um resultado, saia.³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lAchou
		Exit
	Else
		nStartCol := 1
	EndIf
Next

Return lAchou

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} VisualProp

Responsavel pela visualizacao

@sample     VisualProp( )

@param		 ExpN1 - Posicao do registro

@return     ExpL: Verdadeiro/Falso

@author     Victor Bitencourt
@since      08/09/2014
@version    P12
/*/
//-----------------------------------------------------------------------------------------
Function VisualProp(nReg)

Local aArea 	 := GetArea()
Local aAdyArea	 := {}

Default nReg := 0

If nReg > 0
	
	If Select("ADY") > 0
		aAdyArea := ADY->(GetArea())
	Else
		DbSelectArea("ADY")//Proposta Comercial
	EndIf
	ADY->(DbGoTo(nReg))
	FWExecView(Upper(STR0023),"VIEWDEF.FATA600",MODEL_OPERATION_VIEW,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/)
	If Len( aAdyArea ) > 0
		RestArea(aAdyArea)
	EndIf
	RestArea(aArea)

EndIf

Return

//-----------------------------------------------------------------------
/*/{Protheus.doc} Ft600ImpCo()
Imprime o contrato de locação

@sample Ft600ImpCo()

@param oModel ( Modelo Ativo)

@return lNenhum

@author Gestão de Transporte de Passageiros
@since  08/10/2014
@version P12
/*/
//-----------------------------------------------------------------------
Function Ft600ImpCo(oModel)

Local cItinerario		:= ""
Local hWord			:= 0
Local cPath			:= Alltrim(SuperGetMv( "MV_DIRDOC", .F., "\DIRDOC\" ) )
Local cArqDot			:= Alltrim(SuperGetMv( "MV_MODCON", .F., "CONTRATOGTP.DOT" )  )
Local aDados  		:= {}
Local nCont	 		:= 0
Local nInd    		:= 0
Local nTotProd 		:= 0
Local aParc			:= {}
Local cFilSB1			:= xFilial("SB1")

If SubStr(cPath,-1) <> "\"
	cPath += "\"
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Criando link de comunicacao com o word                                ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
hWord := OLE_CreateLink()
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Exibe ou oculta a janela principal da aplicacao Word                  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
OLE_SetProperty( hWord, oleWdVisible, .T. )

If hWord == "-1"
	MsgBox(STR0311, ProcName()) // "Impossível estabelecer comunicação com o Microsoft Word."
Else
	nTotProd := 0
	SB1->(DbSetOrder(1))
	For nCont := 1 To oModel:GetModel("ADZPRODUTO"):Length()
		oModel:GetModel("ADZPRODUTO"):GoLine(nCont)
		SB1->(MsSeek(cFilSB1+oModel:GetModel("ADZPRODUTO"):GetValue("ADZ_PRODUT")))
		If Alltrim(SB1->B1_TIPO) == "SV" // Soma apenas os produtos tipo Serviço
			nTotProd += oModel:GetModel("ADZPRODUTO"):GetValue("ADZ_TOTAL")
		Endif
	Next
	// Posiciona no cliente e na TES
	SA1->(MsSeek(xFilial("SA1")+oModel:GetModel("ADYMASTER"):GetValue("ADY_CLIENT")+oModel:GetModel("ADYMASTER"):GetValue("ADY_LOJA")))
	SF4->(MsSeek(xFilial("SF4")+oModel:GetModel("ADZPRODUTO"):GetValue("ADZ_TES")))
	
	Aadd(aDados, {"nrcontrato", oModel:GetModel("ADYMASTER"):GetValue("ADY_PROPOS")})
	Aadd(aDados, {"nomecontratante", SA1->A1_NOME })
	Aadd(aDados, {"CPFCNPJContrate", Transform(SA1->A1_CGC, If(Len(Alltrim(SA1->A1_CGC))==14, "@R 99.999.999/999-99", "@R 999.999.999-99")) })
	Aadd(aDados, {"IEContratante", SA1->A1_INSCR })
	Aadd(aDados, {"Endcontratante", SA1->A1_END })
	Aadd(aDados, {"Bairrocontratante", SA1->A1_BAIRRO })
	Aadd(aDados, {"Cidadecontratante", SA1->A1_MUN })
	Aadd(aDados, {"UFcontratante", SA1->A1_EST })
	Aadd(aDados, {"Telcontratante", SA1->A1_TEL })
	Aadd(aDados, {"RGcontratante", SA1->A1_RG })
	
	Aadd(aDados, {"nomecontratada", SM0->M0_NOMECOM })
	Aadd(aDados, {"CFOPcontratada", SF4->F4_CF })
	Aadd(aDados, {"Endcontratada", SM0->M0_ENDCOB })
	Aadd(aDados, {"Bairrocontratada", SM0->M0_BAIRCOB })
	Aadd(aDados, {"Cidadecontratada", SM0->M0_CIDCOB })
	Aadd(aDados, {"UFcontratada", SM0->M0_ESTCOB })
	Aadd(aDados, {"CNPJcontratada", Transform(SM0->M0_CGC, "@R 99.999.999/999-99" ) })
	Aadd(aDados, {"IEcontratada", SM0->M0_INSC })
	Aadd(aDados, {"agencia", SM0->M0_CIDCOB })
	Aadd(aDados, {"QtdePassageiros", oModel:GetModel("GIPVEICULO"):GetValue("GIP_POLTR") })
	Aadd(aDados, {"QtdeCarro", oModel:GetModel("GIPVEICULO"):GetValue("GIP_QUANT") })
	
	// Primeira linha
	oModel:GetModel("GINVIAESP"):Goline(1)
	Aadd(aDados, {"horaini", Transform(oModel:GetModel("GINVIAESP"):GetValue("GIN_HSAIDA"), PesqPict("GIN","GIN_HSAIDA")) })
	Aadd(aDados, {"dataini", oModel:GetModel("GINVIAESP"):GetValue("GIN_DSAIDA") })
	cItinerario := Alltrim(oModel:GetModel("GINVIAESP"):GetValue("GIN_DESLO")) + " - " + Alltrim(oModel:GetModel("GINVIAESP"):GetValue("GIN_DESLD"))
	
	Aadd(aDados, {"localembraque", oModel:GetModel("GINVIAESP"):GetValue("GIN_ENDEM") })
	
	// Ultima linha
	//oModel:GetModel("GINVIAESP"):Goline(oModel:GetModel("GINVIAESP"):Length())
	Aadd(aDados, {"horafim", Transform(oModel:GetModel("GINVIAESP"):GetValue("GIN_HVOLTA"), PesqPict("GIN","GIN_HVOLTA")) })
	Aadd(aDados, {"datafim", oModel:GetModel("GINVIAESP"):GetValue("GIN_DVOLTA") })
	cItinerario += " - " + Alltrim(oModel:GetModel("GINVIAESP"):GetValue("GIN_DESLD"))
	
	Aadd(aDados, {"itinerario", cItinerario })
	
	Aadd(aDados, {"valor", Transform(nTotProd, PesqPict("ADZ", "ADZ_TOTAL"))+ " ("+Extenso(nTotProd)+" )"  })
	Aadd(aDados, {"kmrodados", Transform(oModel:GetModel("GIPVEICULO"):GetValue("GIP_KMCONT"), PesqPict("GIP","GIP_KMCONT")) })
	Aadd(aDados, {"kmexcedente", Transform(oModel:GetModel("GIPVEICULO"):GetValue("GIP_KMEXCE"), PesqPict("GIP","GIP_KMEXCE")) })
	
	// -----------------------------+
	// -- Define numero de parcelas |
	// -----------------------------+
	aParc := Condicao(nTotProd,oModel:GetModel("ADYMASTER"):GetValue("ADY_CONDPG"), ,  )
	If Len(aParc) > 0
		Aadd(aDados, {"condpag", Str( Len(aParc) ) + "X" })
	Else
		Aadd(aDados, {"condpag", "" })
	EndIf
	
	
	Aadd(aDados, {"cidade", SM0->M0_CIDCOB })
	
	Aadd(aDados, {"disponibilidade", If(Empty(oModel:GetModel("GIPVEICULO"):GetValue("GIP_DISPVE")),"Sim",oModel:GetModel("GIPVEICULO"):GetValue("GIP_DISPVE")) } )
	
	If !Empty(ADY->ADY_OBS)
		Aadd(aDados, {"claususaadicional", "DÉCIMA QUINTA: " + ADY->ADY_OBS } )
	Else
		Aadd(aDados, {"claususaadicional", "" } )
	Endif
	//Local HandleWord (onde sera criado o arquivo local)
	MontaDir("C:\")
	// Caso encontre arquivo ja gerado na estacao
	//com o mesmo nome apaga primeiramente antes de gerar a nova impressao
	If File( Alltrim( "C:\" + cArqDot ) )
		Ferase( Alltrim( "C:\" + cArqDot ) )
	Endif
	//
	//Copia do Server para o Remote, eh necessario para que o wordview e o
	//proprio word possam preparar o arquivo para impressao e ou visualizacao
	//Copia o DOT que esta no ROOTPATH Protheus para o PATH da estacao,
	// por exemplo C:\WORDTMP
	//
	CpyS2T( cPath+cArqDot, "C:\", .T. )
	//
	//Gerando novo documento do Word na estacao                             ³
	//
	OLE_NewFile( hWord, Alltrim( "C:\"+cArqDot ) )
	
	//
	// Deixa a janela do documento visivel ou nao. .T. ou .F. (opcional)
	//
	OLE_SetProperty( hWord, oleWdVisible, .T. )
	//
	// Ativa ou desativa impressao em segundo plano. (opcional)
	//
	OLE_SetProperty( hWord, oleWdPrintBack, .T. )
	//
	// Essa eh a parte mais importante.
	// Gerando variaveis do documento
	//
	For nInd := 1 to Len( aDados )
		OLE_SetDocumentVar(hWord, aDados[nInd,1], aDados[nInd,2] )
	Next nInd
	For nInd := 1 To 4
		OLE_SetDocumentVar(hWord, 'via', nInd)
		//
		// Atualizando a exibicao das variaveis do documento
		//
		OLE_UpdateFields(hWord)
		//
		//Imprime o documento.
		//
		OLE_PrintFile( hWord, "ALL",,, 1 )
		Sleep(2000)	// Espera 2 segundos pra dar tempo de imprimir.
	Next
	//
	// Fecha o documento.
	//
	OLE_CloseFile( hWord )
	//
	// Fecha a comunicacao com o Word.
	//
	OLE_CloseLink( hWord )
	//
	// Apaga o arquivo de trabalho
	//
	If File( Alltrim( "C:\" + cArqDot ) )
		Ferase( Alltrim( "C:\" + cArqDot ) )
	Endif
EndIf

Return Nil

//-----------------------------------------------------------------------
/*/{Protheus.doc} FtV600Pedag()

Atualiza valor do custo (pedagio) Custo unitario/Custo total (aba custos) com a
soma dos valores do pedagio ida/volta (aba Percurso).

@sample FtV600Pedag()

@param oModel - Modelo de dados

@return lNenhum

@author Lucas.brustolin
@since  21/10/2014
@version P12
/*/
//-----------------------------------------------------------------------
Function FtV600Pedag(oModel)

Local oGridPerc	:= Nil
Local oGridCusto	:= Nil
Local aSaveLines	:= Nil

Local nVlrPedag	:= 0
Local nI			:= 0

oModel		:= FwModelActive()
oGridPerc	:= oModel:GetModel("GINVIAESP") --// Aba Percurso
oGridCusto	:= oModel:GetModel("GIOCUSTOS") --// Aba Custos


If oGridPerc <> Nil .And. oGridCusto <> Nil
	
	//-- Soma Valor Pedagio Ida/Volta
	nVlrPedag := oGridPerc:GetValue('GIN_PEDIDA') + oGridPerc:GetValue('GIN_PEDVOL')
	
	//---------------------------------------------+
	// Atualiza Valor do pedágio da Grid Custos    |
	//---------------------------------------------+
	
	aSaveLines  := FWSaveRows()
	
	For nI := 1 To oGridCusto:Length()
		oGridCusto:GoLine(nI)
		
		//-- Procura Custo do tipo  Pedágio
		If oGridCusto:SeekLine( {{ "GIO_UM", "PD" }} )

			//-- Atualiza valor Custo unitario
			oGridCusto:LoadValue('GIO_CUSUNI', nVlrPedag  )
			
			//-- Atualiza quantidade:
			//-- Qtdade 1 : Vlr. do pegagio maior que zero
			//-- Qtdade 0 : Vlr. do pedagio igual a zero
			If nVlrPedag > 0
				oGridCusto:LoadValue("GIO_QUANT"	, 1 )
			Else
				oGridCusto:LoadValue("GIO_QUANT"	, 0 )
			EndIf
			
			//-- Atualiza Valor Total
			oGridCusto:SetValue("GIO_VALTOT"	, 1 * nVlrPedag )
		EndIf
		
	Next
	
	FWRestRows( aSaveLines )
	
EndIf

Return

//-----------------------------------------------------------------------
/*/{Protheus.doc} A600GIOCUSTO()
Proposta Comercial - Aba Custos (SIGAGTP)
Rotina executada pelo gatilho interno GIO_CUSTO, tem como objetivo
gatilhar os seguintes campos:
1. Descrição do custo
2. Unidade de Medida
3. Descricao Unidade Medida
4. Quantidade ou Quilometragem. (Inicializa com zero)
5. Custo Unitario
6. Valor Total. (Inicializa com zero)

@sample A600GIOCUSTO()

@param oModel - Modelo de dados

@return nValTot = Inicializa o valor total (ZERO)

@author Lucas.brustolin
@since  27/10/2014
@version P12
/*/
//-----------------------------------------------------------------------
Function A600GIOCUSTO(oModel)

Local aArea		:= GetArea()
Local oGridCusto	:= Nil
Local cDescri		:= ""
Local cCodCusto	:= ""
Local cCodUM		:= ""
Local cUmRes		:= ""
Local nQtd			:= 0
Local nCustoUnit	:= 0
Local nValTot		:= 0

oModel	 	:= FwViewActive()
oGridCusto	:= oModel:GetModel("GIOCUSTOS") --// Aba Custos

If oGridCusto <> Nil

	cCodCusto := oGridCusto:GetValue("GIO_CUSTO")

	If !Empty(cCodCusto)

		//-- Gatilha campo descrição do custo
		cDescri := Posicione("GIM",1, xFilial("GIM") + cCodCusto, "GIM_DESCRI")
		oGridCusto:SetValue("GIO_DCUSTO", cDescri )

   		//-- Gatilha campo Unidade de Medida
		cCodUM := Posicione("GIM", 1, xFilial("GIM") + cCodCusto, "GIM_UM" )
		oGridCusto:SetValue("GIO_UM", cCodUM)

   		//-- Gatilha campo Descricao Unidade Medida
		cUmRes := Posicione("SAH", 1, xFilial("SAH")+ cCodUM, "AH_UMRES" )
		oGridCusto:SetValue("GIO_DESUM", cUmRes )

   		//-- Gatilha Quantidade ou Quilometragem
		oGridCusto:LoadValue("GIO_QUANT", nQtd )

   		//-- Gatilha campo Custo Unitario do custo
		nCustoUnit := Posicione("GIM",1, xFilial("GIM")+ cCodCusto, "GIM_CBASE")
		oGridCusto:LoadValue("GIO_CUSUNI", nCustoUnit  )

	EndIf

EndIf

RestArea(aArea)
Return (nValTot)

//---------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} FT600VlDc

Analisa o array de valores de Desconto / Acrescimo da proposta bloqueada, retorna se o usuário tem alçada suficiente
para liberar a proposta.

@sample	FT600VlDc(aArray)

@param	aAlcValues, Array, Valores e % de acrescimo / Desconto da proposta e do time de venda (ACA):
{ % Desc., Vlr. Desc. , % Acre., Vlr. Acre, Alçada % Desc., Alçada Vlr. Desc. , Alçada % Acre., Alçada Vlr. Acre }
@return	lRet, lógico, Retorna se o usuário tem alçada para liberar a Proposta 

@author 	Squad CRM/Faturamento
@since		25/10/2017
@version	12.1.17
/*/
//---------------------------------------------------------------------------------------------------------------
Static Function FT600VlDc( aAlcValues)

Local lRet			:= .T.
Local cCodRepr 	:= ''
Local cUser		:= RetCodUsr()
Local aAreaACA	:= ACA->( GetArea() )
Local aAreaAO3	:= AO3->( GetArea() )

Default aAlcValues := {}

If !Empty(cUser) .And. !Empty(aAlcValues)

	DbSelectArea('AO3')
	AO3->(DbSetOrder(1))

	If AO3->( DBSeek( xFilial('AO3')+cUser) )
		cCodRepr := AO3->AO3_CODEQP
	EndIf

	If !Empty(cCodRepr)
		DbSelectArea('ACA')
		ACA->(DbSetOrder(1))

		If ACA->(DbSeek(xFilial('ACA')+cCodRepr))

			aAlcValues[1][5] := ACA->ACA_PDSCMX
			aAlcValues[1][6] := ACA->ACA_VDSCMX
			aAlcValues[1][7] := ACA->ACA_PACRMX
			aAlcValues[1][8] := ACA->ACA_VACRMX

			If  (  aAlcValues[1][5] > 0 .And. aAlcValues[1][1] > aAlcValues[1][5]) .Or. ;
					(  aAlcValues[1][7] > 0 .And. aAlcValues[1][3] > aAlcValues[1][7] )
				lRet	:= .F.
			EndIf

			If lRet .And. ( ( aAlcValues[1][6] > 0 .And. aAlcValues[1][2] > aAlcValues[1][6] ) .Or. ;
					( aAlcValues[1][8] > 0 .And. aAlcValues[1][4] > aAlcValues[1][8] ) )
				lRet	:= .F.
			EndIf
		EndIf
	EndIf
EndIf

RestArea( aAreaACA )
RestArea( aAreaAO3 )
Return lRet

//---------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} FT600GtAlc

Obtem os valores envolvidos na alçada sendo:
[1 % de Desconto Proposta][2 valor de Desconto Proposta][3 % de Acrescimo Proposta][4 Valor de Acrescimo Proposta ]
[5 % Desconto Alçada ][6 Valor Desconto Alçada ][7 % Acrescimo Alçada ][8 Valor Acrescimo Alçada ] 

@sample	FT600GtAlc(aValues)

@param	cChave, Caracter, Chave para pesquisa na ADZ

@return	aValues, Array, Valores e % de acrescimo / Desconto da proposta e do time de venda (ACA)

@author 	Squad CRM/Faturamento
@since		25/10/2017
@version	12.1.17
/*/
//---------------------------------------------------------------------------------------------------------------
Static Function FT600GtAlc(cChave)

Local aAreaADZ	:= ADZ->(GetArea())
Local aValues		:= {}
Local nPerDesc	:= 0
Local nValDesc	:= 0
Local nPecAcre	:= 0
Local nValAcre	:= 0
Local nValProd	:= 0
Local nLastVal	:= 0
Local nLastPer	:= 0

Default cChave	:= ''

If !Empty(cChave)
	DbSelectArea('ADZ')
	ADZ->(DbSetOrder(3))
	If ADZ->( MsSeek( xFilial('ADZ') + cChave ) )
		While ADZ->(!Eof()) .And. ADZ->(ADZ_FILIAL+ADZ_PROPOS+ADZ_REVISA) == xFilial('ADZ')+cChave

			nValProd := ADZ->ADZ_PRCTAB

			If nVAlProd == 0
				nVAlProd := Ft600SkPrd(ADZ->ADZ_PRODUT)
			EndIf

			If  ADZ->ADZ_DESCON > 0
				If ADZ->ADZ_DESCON > nPerDesc
					nPerDesc := ADZ->ADZ_DESCON
				EndIf

				If ADZ->ADZ_VALDES > nValDesc
					nValDesc := ADZ->ADZ_VALDES
				EndIf

			ElseIf  nValProd > 0
				nLastPer := FT600VNACR( ADZ_PRCVEN, nValProd, 'P'  ) // ( (Preço Venda. - Preço Tabela) / Preço Tabela ) *100
				nLastVal := FT600VNACR( ADZ_PRCVEN, nValProd, 'V'  ) // (Preço Venda. - Preço Tabela)

				If nLastPer > 0 .And. nLastPer > nPecAcre
					nPecAcre := nLastPer
					nValAcre := nLastVal
				EndIf
			EndIf

			ADZ->(dbSkip())

		EndDo
	EndIf
EndIf

AADD(aValues, {nPerDesc, nValDesc, nPecAcre, nValAcre, 0, 0, 0, 0 } )
RestArea(aAreaADZ)
Return aValues

//---------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600SkPrd

Procura o produto buscando seu preço de venda.

@sample	Ft600SkPrd(cProduct)

@param	cProduct, Caracter, código do produto

@return	nSalesVal, numérico, preço de venda do produto

@author 	Squad CRM/Faturamento
@since		25/10/2017
@version	12.1.17
/*/
//---------------------------------------------------------------------------------------------------------------
Static Function Ft600SkPrd(cProduct)

Local aAreaSB1	:= SB1->(GetArea())
Local nSalesVal	:= 0

Default cProduct	:= ''

DbSelectArea('SB1')
DbSetOrder(1)
If DbSeek( (xFilial('SB1')+cProduct) )
	nSalesVal := SB1->B1_PRV1
EndIf

RestArea(aAreaSB1)
Return nSalesVal

//---------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} FT600VNACR

Calcula o acréscimo de valor de um produto, retornando o valor ou percentual. 

@sample	FT600VNACR(nSalesVal, nValTab, cType )

@param	nSalesVal, numérico, preço de venda do produto
@param	nValTab,numérico, preço 'base para calculo do acréscimo
@param	cType, Caracter, tipo de retorno, 'V' - Valor ou 'P' %

@return	nValue, numérico, valor do acrescimo ou % do acréscimo

@author 	Squad CRM/Faturamento
@since		25/10/2017
@version	12.1.17
/*/
//---------------------------------------------------------------------------------------------------------------
Static Function FT600VNACR(nSalesVal, nValTab, cType )

Local 	nValue 		:= 0

Default nSalesVal		:= 0
Default nValTab		:= 0
Default cType			:= 'P'

cType := Upper( Alltrim( cType  ) )

If nSalesVal > nValTab
	Do Case
		Case cType == 'P'
			nValue:= ( ( (nSalesVal - nValTab )/nValTab ) *100 )
		Case cType == 'V'
			nValue := nSalesVal - nValTab
	EndCase
EndIf
Return nValue


//---------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} FT600AlcMg

Monta a mensagem de Help apresentando os valores que impedem o desbloquei. 

@sample	FT600AlcMg( aAlçada )

@param	aAlçada, array,array contendo os dados da alçada da proposta:
{% Desc., Vlr. Desc. , % Acre., Vlr. Acre, Alçada % Desc., Alçada Vlr. Desc. , Alçada % Acre., Alçada Vlr. Acre  }

@return	cMsg, caracter, mensagem composta dos valores e alçadas que impediram a liberação da proposta

@author 	Squad CRM/Faturamento
@since		25/10/2017
@version	12.1.17
/*/
//---------------------------------------------------------------------------------------------------------------
Static Function FT600AlcMg(aAlcada)

Local cMsg			:= ''
Local cMaskPerc	:= PesqPict('ACA','ACA_PDSCMX')
Local cMaskVal	:= PesqPict('ACA','ACA_VDSCMX')
Local cNoEsp		:= STR0381 //'Não Especificado'
Local cPerDescon	:= ''
Local cPerAcresc	:= ''
Local cVlrDescon	:= ''
Local cVlrAcresc	:= ''

Default	aAlcada := {}

If !Empty( aAlcada )
	If aAlcada[1][5] > 0
		cPerDescon := Transform(  aAlcada[1][5], cMaskPerc )
	Else
		cPerDescon := cNoEsp
	EndIf

	If aAlcada[1][6] > 0
		cVlrDescon := Transform(  aAlcada[1][6], cMaskVal )
	Else
		cVlrDescon := cNoEsp
	EndIf

	If aAlcada[1][7] > 0
		cPerAcresc := Transform(  aAlcada[1][7], cMaskVal )
	Else
		cPerAcresc := cNoEsp
	EndIf

	If aAlcada[1][8] > 0
		cVlrAcresc := Transform(  aAlcada[1][8], cMaskVal )
	Else
		cVlrAcresc := cNoEsp
	EndIf

	cMsg += ' ' + Chr(13) + Chr(10)

	cMsg += STR0382 + Chr(13) + Chr(10) //' Alçada da Proposta:  '
	cMsg += STR0383 + Transform( aAlcada[1][1], cMaskPerc ) + '%' + Chr(13) + Chr(10) + STR0384 + Transform( aAlcada[1][2] , cMaskVal ) + Chr(13) + Chr(10) //'% de Desconto: ' # ' Valor de Desconto: ' #
	cMsg += STR0385 + Transform( aAlcada[1][3], cMaskPerc ) + '%' + Chr(13) + Chr(10) + STR0386 + Transform( aAlcada[1][4] , cMaskVal ) + Chr(13) + Chr(10) // '% de Acréscimo: ' # ' Valor do Acréscimo: '

	cMsg += ' ' + Chr(13) + Chr(10)

	cMsg += STR0387 + Chr(13) + Chr(10)	//' Seus limites para Aprovação: '
	cMsg += STR0388 + cPerDescon + '%'  + Chr(13) + Chr(10) + STR0389 + cVlrDescon  + Chr(13) + Chr(10) //'% Máximo de Desconto: ' # ' Valor máximo de Desconto: '
	cMsg += STR0390 + cPerAcresc + '%'  + Chr(13) + Chr(10) + STR0391 + cVlrAcresc  //'% Máximo de Acréscimo: ' # ' Valor máximo de Acrescimo: '
EndIf
Return cMsg

//------------------------------------------------------------------------------
/*/{Protheus.doc} FT600AGrup

Carrega os produtos do agrupador nos itens da proposta.

@sample	FT600AGrup

@return	ExpA - Produtos da Proposta Comercial Sincronizada

@author	Cleyton F.Alves
@since		30/01/2014
@version	12.5.6
/*/
//------------------------------------------------------------------------------
Function FT600AGrup(oModel)

Local oMdlADY			:= oModel:GetModel("ADYMASTER")
Local oMdlPrd			:= oModel:GetModel("ADZPRODUTO")
Local oMdlAces		:= oModel:GetModel("ADZACESSOR")
Local lAddProduct		:= SuperGetMv("MV_CRMINCP",,.F.)
Local nX				:= 0
Local lContinua		:= .T.
Local lDeleteLine		:= .F.
Local aProdSel		:= {}
Local aPrdDetail		:= {}
Local aProduct		:= {}

//Verifica se Oportunidade de Vendas possui Agrupador relacionado
ADJ->(DbSetOrder(1))
If (ADJ->(DbSeek(xFilial("ADJ")+oMdlADY:GetValue("ADY_OPORTU")+oMdlADY:GetValue("ADY_REVISA"))))
	If Empty(ADJ->ADJ_CODAGR) .And. Empty(ADJ->ADJ_CODNIV)
		lContinua	:= .F.
		Help("",1,"FT600SELP",,STR0321,1) //"Não há agrupadores comerciais associados a Oportunidade de Venda amarrada a esta Proposta Comercial."
	EndIf
EndIf

If lContinua

	FwMsgRun(Nil,{|| aProdSel := CRMA910B()}, Nil, STR0344) //"Aguarde, carregando os agrupadores..."

	If !(Empty(aProdSel))

		If (oModel:GetOperation() == MODEL_OPERATION_UPDATE)
			//-------------------------------------------------------------------
			// Identifica se os produtos são incrementados por padrão.
			//-------------------------------------------------------------------
			If !(lAddProduct)
				If !oMdlPrd:IsEmpty() .And. MsgYesNo(STR0322) //"Deseja remover os itens existentes na pasta de produtos?"
					lDeleteLine := .T.
				EndIf
			EndIf
		EndIf

		For nX := 1 To Len(aProdSel)

			aAdd(aProduct, {"ADZ_PRODUT", aProdSel[nX][1]})	//Codigo do produto
			aAdd(aProduct, {"ADZ_CODAGR", aProdSel[nX][2]})	//Código do Agrupador
			aAdd(aProduct, {"ADZ_CODNIV", aProdSel[nX][3]})	//Código do Nivel do Agrupador

			aAdd(aPrdDetail, {aProduct, {{"ADZ_PRODUT", aProdSel[nX][1]},;
			                             {"ADZ_CODAGR", aProdSel[nX][2]},;
			                             {"ADZ_CODNIV", aProdSel[nX][3]}}, lDeleteLine, .F.})
			aProduct 	:= {}
		Next nX

		If !(Empty(aPrdDetail))
			FT600LoadGrid(oMdlPrd, aPrdDetail)
		EndIf

		If !oMdlPrd:IsEmpty()
			oMdlPrd:GoLine(1)
		EndIf

	EndIf
EndIf
Return Nil

//------------------------------------------------------------------------------
/*/{Protheus.doc} FT600Accessory
Retorna os acessorios de um produto preenchido no grid de produtos.
@sample 	FT600Accessory( cItemFather ,cIdProduct, oMdlAce )
@param		cItemFather 	, Caracter 	,Item do produto.
			cIdProduct 	, Caracter  	,Codigo do produto.
			oMdlAce 		, Objeto  		,ModelGrid de Acessorios
@Return   	lRet		 	, Logico	 	,Verdadeiro se a atualização dos acessorios no grid foi concluída com sucesso.
@author	Anderson Silva
@since		09/03/2016
@version	12.1.7
/*/
//------------------------------------------------------------------------------
Function FT600Accessory( cItemFather ,cIdProduct, oMdlAce )

Local aAceDetail		:= {}
Local aAccessory		:= {}
Local aProdXAce		:= {}
Local nX				:= 0
Local lRet				:= .T.

Default cItemFather	:= ""
Default cIdProduct 	:= ""
Default oMdlAce		:= Nil

If !Empty(cItemFather) .And. !Empty(cIdProduct) .And. oMdlAce <> Nil
	SB1->(DBSetOrder(1))
	If SB1->(DBSeek(xFilial("SB1") + cIdProduct))
		
		//Valida a existencia de acessorios (KIT) para o produto selecionado
		A610Acessorio(SB1->B1_COD,"",@aProdXAce)
		
		For nX := 1 To Len(aProdXAce)
			If aProdXAce[nX][5] == "A"
				aAdd(aAccessory,	{"ADZ_PRODUT",	aProdXAce[nX][1]})	//Codigo do produto
				aAdd(aAccessory,	{"ADZ_QTDVEN",	aProdXAce[nX][6]})	//Quantidade
				aAdd(aAccessory,	{"ADZ_ITPAI",		cItemFather})			//Item do produto relacionado a este acessorio.
				
				aAdd(aAceDetail,	{aAccessory,	{{"ADZ_PRODUT",	AllTrim(aProdXAce[nX][1])},	{"ADZ_ITPAI",	AllTrim(cItemFather)}}, .F., .F.})
				aAccessory	:= {}
			EndIf
		Next nX
		
		If !Empty(aAceDetail)
			lRet := FT600LoadGrid(oMdlAce, aAceDetail)
		EndIf
		
	EndIf
EndIf
Return	(lRet)

//------------------------------------------------------------------------------
/*/{Protheus.doc} FT600LoadGrid()
Ponto unico para atualizar os Produtos / Acessorios da Proposta Comercial
@sample 	FT600LoadGrid( oMdlGrid, aGridDetail )
@param		oMdlGrid 		, Objeto	, ModelGrid Produtos / Acessorios
			aGridDetail	, Array		, Array com detalhes para atualização do grid.
			Formato:
			aGridDetail -> { aData -> { {cField, uValue } },;
			aSeekLine ( Chave de Pesquisa )-> { {cField, uValue }, { {cField, uValue } } },;
			lDeleteLine -> .T. deletar / .F. Atualizar a linha caso SeekLine encontre. Default .F.,;
			lForceLine -> .T. para forcar a inserção de linha caso o valid não permita. Default .F. }
@Return   	lRet		 	, Logico	 ,Verdadeiro se a atualização do grid foi concluída com sucesso.
@author	Anderson Silva
@since		10/03/2016
@version	12.1.7
/*/
//------------------------------------------------------------------------------
Function FT600LoadGrid(oMdlGrid, aGridDetail)

Local lRet 			:= .T.
Local cDescription	:= ""
Local cMdlDetBkp		:= __cMdlDetail

//Atualiza a variavel estatica para indicar o modelgrid que está em edicao no momento
__cMdlDetail	:= oMdlGrid:GetId()

If __cMdlDetail == "ADZPRODUTO"
	cDescription := STR0346  //"Aguarde, atualizando os produtos..."
Else
	cDescription := STR0347 //"Aguarde, atualizando os acessórios..."
EndIf

FwMsgRun(Nil,{|| lRet := FT600RLGrid(oMdlGrid, aGridDetail)},Nil,cDescription)

__cMdlDetail	:= cMdlDetBkp

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} FT600RLGrid
Ponto unico para atualizar os Produtos / Acessorios da Proposta Comercial
@sample 	FT600RLGrid( oMdlGrid, aGridDetail )
@param		oMdlGrid 		, Objeto	, ModelGrid Produtos / Acessorios
			aGridDetail	, Array		, Array com detalhes para atualização do grid.
			Formato:
			aGridDetail -> { aData -> { {cField, uValue } },;
			aSeekLine ( Chave de Pesquisa )-> { {cField, uValue }, { {cField, uValue } } },;
			lDeleteLine -> .T. deletar / .F. Atualizar a linha caso SeekLine encontre. Default .F.,;
			lForceLine -> .T. para forcar a inserção de linha caso o valid não permita. Default .F. }
@Return   	lRet		 	, Logico	 ,Verdadeiro se a atualização do grid foi concluída com sucesso.
@author	Anderson Silva
@since		10/03/2016
@version	12.1.7
/*/
//------------------------------------------------------------------------------
Static Function FT600RLGrid(oMdlGrid, aGridDetail)

Local nX				:= 0
Local nY				:= 0
Local nLinPos			:= 0
Local lSeekLine		:= .F.
Local lRet				:= .T.
Local oModel			:= Nil
Local cAction			:= ""
Local cItem			:= ""
Local aParam			:= {}
Local aRet				:= {}

Default oMdlGrid		:= Nil
Default aGridDetail	:= {}

If ( oMdlGrid <> Nil .And. !Empty(aGridDetail) .And. !Empty(__cMdlDetail) )

	oModel := oMdlGrid:GetModel()

	If _lPELoadGrid
		cAction	:= "GRID_BEFORE"
		aParam		:= {cAction, oMdlGrid, aGridDetail, __cMdlDetail}
		aRet		:= ExecBlock("FT600ULGRID", .F., .F., aParam)
		If ValType(aRet) == "A"
			aGridDetail := aRet
		EndIf
	EndIf

	For nX := 1 To Len(aGridDetail)

		If _lPELoadGrid
			cAction	:= "LINE_BEFORE"
			aParam		:= {cAction, oMdlGrid, aGridDetail[nX], __cMdlDetail}
			aRet		:= ExecBlock("FT600ULGRID", .F.,.F.,aParam)
			If ValType(aRet) == "A"
				aGridDetail[nX] := aRet
			EndIf
		EndIf

		If !Empty(aGridDetail[nX][2])
			lSeekLine := oMdlGrid:SeekLine(aGridDetail[nX][2])
			If lSeekLine .And. aGridDetail[nX][3]
				oMdlGrid:DeleteLine()
				Loop
			EndIf
		EndIf

		If !lSeekLine
			nLinPos := oMdlGrid:Length()
			oMdlGrid:GoLine(nLinPos)
			If oMdlGrid:IsDeleted() .Or. !oMdlGrid:IsEmpty()
				cItem := oMdlGrid:GetValue("ADZ_ITEM")
				If oMdlGrid:AddLine(aGridDetail[nX][4]) > nLinPos
					oMdlGrid:LoadValue("ADZ_ITEM", Soma1(cItem))
				Else
					lRet := .F.
					aError := oModel:GetErrorMessage()
					If !Empty(aError)
						Help("",1,"FT600LGRID",,aError[6],1)
					EndIf
					Exit
				EndIf
			EndIf
		EndIf

		For nY := 1 To Len(aGridDetail[nX][1])
			lRet := oMdlGrid:SetValue(aGridDetail[nX][1][nY][1], aGridDetail[nX][1][nY][2])
			If !lRet
				aError := oModel:GetErrorMessage()
				If !Empty(aError)
					Help("",1,"FT600LGRID",,aError[6],1)
				EndIf
				Exit
			EndIf
		Next nY

		If _lPELoadGrid
			cAction	:= "LINE_AFTER"
			aParam		:= {cAction, oMdlGrid, aGridDetail[nX], __cMdlDetail}
			lRet		:= ExecBlock("FT600ULGRID", .F.,.F., aParam)
			If ValType(lRet) <> "L"
				lRet := .T.
			EndIf
		EndIf

		If !lRet
			Exit
		EndIf
		lSeekLine := .F.
	Next nX

	If _lPELoadGrid
		cAction	:= "GRID_AFTER"
		aParam		:= {cAction, oMdlGrid, aGridDetail, __cMdlDetail}
		ExecBlock("FT600ULGRID", .F., .F., aParam)
	EndIf
EndIf
Return	(lRet)

//------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600Trigger
Centraliza as regras de negocios que sao disparadas pelos gatilhos.
@sample 	Ft600Trigger( cFieldDom, cFieldCDom, cMdlDetail )
@param		cFieldDom		, Caracter	, Campo que disparou o gatilho
			cFieldCDom		, Array		, Campo que recebera o conteudo
			cMdlDetail		, Caracter	, Nome do ModelGrid que o gatilho foi disparado.
@Return   	uValue		 	, Qualquer	 ,Conteudo que sera retornado no campo de contra dominio.
@author	Anderson Silva
@since		10/03/2016
@version	12.1.7
/*/
//------------------------------------------------------------------------------
Function Ft600Trigger(cFieldDom, cFieldCDom, cMdlDetail)

Local aAreaSB1	:= SB1->(GetArea())
Local oModel		:= FwModelActive()
Local oMdlADY		:= Nil
Local oMdlPos		:= Nil
Local uValue		:= Nil
Local aVctTp9		:= {}
Local cPriceList	:= ""
Local cCodEnt 	:= ""
Local cLojEnt		:= ""
Local cIdProduct	:= ""
Local cCodAgrup	:= ""
Local cCodLevel	:= ""
Local cTabAgrup	:= ""
Local cAba			:= ""
Local nQuant		:= 0
Local nCurrency	:= 0
Local nSalePrice	:= 0
Local nPriceList	:= 0
Local nDisPerc	:= 0
Local nDisVlr		:= 0
Local nTabCurren	:= 0
Local nAux			:= 0
Local lPriceList	:= .F.
Local lProspect	:= .F.

Default cFieldDom 	:= ""
Default cFieldCDom	:= ""
Default cMdlDetail	:= ""

If oModel <> Nil .And. !Empty(cMdlDetail)
	
	uValue 		:= CriaVar(cFieldCDom, .F.)
	oMdlADY 		:= oModel:GetModel("ADYMASTER")
	cAba			:= IIf(cMdlDetail == "ADZPRODUTO", "1", "2")
	oMdlPos		:= oModel:GetModel(cMdlDetail)
	cPriceList		:= oMdlADY:GetValue("ADY_TABELA")
	cCodEnt 		:= oMdlADY:GetValue("ADY_CODIGO")
	cLojEnt		:= oMdlADY:GetValue("ADY_LOJA")
	lProspect		:= ( oMdlADY:GetValue("ADY_ENTIDA") == "2" )
	cIdProduct		:= oMdlPos:GetValue("ADZ_PRODUT")
	nQuant			:= oMdlPos:GetValue("ADZ_QTDVEN")
	nCurrency		:= Val(oMdlPos:GetValue("ADZ_MOEDA"))
	nSalePrice		:= oMdlPos:GetValue("ADZ_PRCVEN")
	nPriceList		:= oMdlPos:GetValue("ADZ_PRCTAB")
	nDisPerc		:= oMdlPos:GetValue("ADZ_DESCON")
	nDisVlr		:= oMdlPos:GetValue("ADZ_VALDES")
	cCodAgrup		:= oMdlPos:GetValue("ADZ_CODAGR")
	cCodLevel		:= oMdlPos:GetValue("ADZ_CODNIV")
	If	ADZ->(ColumnPos("ADZ_TABAGR")) > 0
		// Quanto o campo ADZ_TABAGR existir no dicionário de dados
		cTabAgrup		:= oMdlPos:GetValue("ADZ_TABAGR")
	EndIf
	
	If !Empty(cIdProduct)

		SB1->(DBSetOrder(1))
		If SB1->(MsSeek(xFilial("SB1") + cIdProduct))
			
			DA1->(DBSetOrder(1))
			lPriceList := DA1->(MsSeek(xFilial("DA1") + cPriceList + cIdProduct))
			If lPriceList
				nTabCurren := DA1->DA1_MOEDA
			EndIf
				
			Do Case
				Case cFieldDom == "ADZ_PRODUT"
					
					Do Case
						Case cFieldCDom == "ADZ_DESCRI"
							
							uValue := AllTrim(SB1->B1_DESC)
							
						Case cFieldCDom == "ADZ_UM"
							
							uValue := SB1->B1_UM
							
						Case cFieldCDom == "ADZ_MOEDA"
							
							If lPriceList .And. DA1->DA1_MOEDA <> 0
								uValue := Str(DA1->DA1_MOEDA,1)
							ElseIf !Empty(SB1->B1_MCUSTD)
								uValue := SB1->B1_MCUSTD
							Else
								uValue := "1"
							EndIf
							
						Case cFieldCDom == "ADZ_CONDPG"
							
							uValue := _cIniCond
							If Empty(uValue)
								uValue := oMdlADY:GetValue("ADY_CONDPG")
								If Empty(uValue)
									DA0->(DbSetOrder(1))
									If DA0->(MsSeek(xFilial("DA0") + cPriceList))
										uValue := DA0->DA0_CONDPG
									EndIf
									If Empty(uValue)
										If !lProspect
											SA1->(DbSetOrder(1))
											If SA1->(MsSeek(xFilial("SA1") + cCodEnt + cLojEnt))
												uValue := SA1->A1_COND
											EndIf
										EndIf
										If Empty(uValue)
											uValue := CriaVar("ADZ_CONDPG", .T.)
										EndIf
									EndIf
								EndIf
							EndIf
							
						Case cFieldCDom == "ADZ_TES"
							
							uValue := oMdlADY:GetValue("ADY_TES")
							If Empty(uValue)
								uValue := SB1->B1_TS
							EndIf
							
						Case cFieldCDom == "ADZ_QTDVEN"
							
							uValue := 1
						
						Case cFieldCDom == "ADZ_PRCVEN" .Or. cFieldCDom == "ADZ_PRCTAB"
							
							If Empty(uValue) // Preço via tabela de preço
								uValue		:= MaTabPrVen(cPriceList, cIdProduct, nQuant, cCodEnt, cLojEnt, nCurrency, /*dDataVld*/, /*nTipo*/, /*lExec*/, /*lAtuEstado*/, lProspect)
								If uValue == 0 .AND. SB1->B1_PRV1 > 0 // Preço via Cadastro de Produto
									uValue := xMoeda(SB1->B1_PRV1, val(SB1->B1_MCUSTD), nCurrency, dDataBase)
								EndIf
								If	uValue == 0
									// Se o produto informado não possuir um preço de tabela ou um preço de venda em seu cadastro,
									// então o usuário deverá informar um valor de venda para o mesmo. 
									If	cFieldCDom == "ADZ_PRCVEN"
										nSalePrice	:= uValue
										oMdlPos:LoadValue("ADZ_VALDES", 0)
										oMdlPos:LoadValue("ADZ_DESCON", 0)
										// Realiza o teste de verificação do array com as parcelas do tipo 9 da Proposta Comercial. Caso o produto/acessório possua parcelas do tipo 9
										// então, como o seu 'novo' valor é ZERO, então as parcelas devem ser eliminadas do cronograma, para que reflita a situação correta.
										// Esta avaliação e ajuste das parcelas do tipo 9 ocorre independentemente da condição de pagamento do produto/acessório.
										aVctTp9	:= Ft600GetTipo09()
										While ( nAux := aScan(aVctTp9, {|x| x[05] == oMdlPos:GetValue('ADZ_ITEM') .AND. x[06] == cAba}) ) > 0
											aDel(aVctTp9, nAux)
											aSize(aVctTp9,Len(aVctTp9) - 1)
										EndDo
										Ft600SetTipo09(aVctTp9)
									Else
										nPriceList	:= uValue
										oMdlPos:LoadValue("ADZ_PRCTAB", nPriceList)
									EndIf
								EndIf
							EndIf

						Case cFieldCDom == "ADZ_TPPROD"
							
							uValue := oMdlADY:GetValue("ADY_TPPROD")
							
					EndCase
				
				Case cFieldDom == "ADZ_MOEDA"
					
					If cFieldCDom == "ADZ_PRCVEN" .Or. cFieldCDom == "ADZ_PRCTAB"
					
						If Empty(uValue)// Preço via tabela de preço
							uValue	:= MaTabPrVen(cPriceList, cIdProduct, nQuant, cCodEnt, cLojEnt, nCurrency, /*dDataVld*/, /*nTipo*/, /*lExec*/, /*lAtuEstado*/, lProspect)
							If uValue == 0 .AND. SB1->B1_PRV1 > 0 // Preço via Cadastro de Produto
								uValue := xMoeda(SB1->B1_PRV1, val(SB1->B1_MCUSTD), nCurrency, dDataBase)
							EndIf
							If	uValue == 0 // Preço via Valor atual do Grid
								uValue := nSalePrice
							EndIf
						EndIf
						
					EndIf
					
				Case cFieldDom == "ADZ_QTDVEN"
					
					If cFieldCDom == "ADZ_TOTAL"
						uValue := nQuant * nSalePrice
					ElseIf cFieldCDom == "ADZ_VALDES" .And. nPriceList > 0
						uValue := (nPriceList - nSalePrice) * nQuant 
					EndIf

				Case cFieldDom == "ADZ_TABAGR"
					
					Do Case
						Case cFieldCDom == "ADZ_PRCVEN" .Or. cFieldCDom == "ADZ_PRCTAB"
							
							If Empty(uValue) // Preço via tabela de preço
								uValue	:= MaTabPrVen(cPriceList, cIdProduct, nQuant, cCodEnt, cLojEnt, nCurrency, /*dDataVld*/, /*nTipo*/, /*lExec*/, /*lAtuEstado*/, lProspect)
								If uValue == 0 .AND. SB1->B1_PRV1 > 0 // Preço via Cadastro de Produto
									uValue := xMoeda(SB1->B1_PRV1, val(SB1->B1_MCUSTD), nCurrency, dDataBase)
								EndIf
								If	uValue == 0 // Preço via Valor atual do Grid
									uValue := nSalePrice
								EndIf
							EndIf
							
						Case cFieldCDom == "ADZ_TOTAL"
							
							uValue := nQuant * nSalePrice
							
					EndCase
					
				Case cFieldDom == "ADZ_PRCVEN"
					
					If cFieldCDom == "ADZ_TOTAL"
						uValue := nQuant * nSalePrice
						If nSalePrice < nPriceList
							If  nTabCurren == nCurrency // Só avalia Preço x Preço lista se ambos estiverem na mesma moeda
								oMdlPos:LoadValue("ADZ_VALDES", Round(((nPriceList - nSalePrice) * nQuant),                             GetSX3Cache("ADZ_VALDES","X3_DECIMAL")))
								oMdlPos:LoadValue("ADZ_DESCON", Round(((oMdlPos:GetValue("ADZ_VALDES") / (nPriceList * nQuant)) * 100), GetSX3Cache("ADZ_DESCON","X3_DECIMAL")))
							EndIf
						Else
							oMdlPos:LoadValue("ADZ_VALDES", 0)
							oMdlPos:LoadValue("ADZ_DESCON", 0)
						EndIf
					EndIf
					
				Case cFieldDom == "ADZ_DESCON" .Or. cFieldDom == "ADZ_VALDES"
					
					//Atualiza o preço de venda caso o usuario aplicar o desconto por % ou por valor.
					//Uso do loadvalue é necessario para o gatilho não ficar recursivo.
					If cFieldCDom == "ADZ_DESCON"
						If nPriceList == 0
							//Se o item não possuir um preço de tabela, não existirá a aplicação de desconto para o mesmo.
							oMdlPos:LoadValue("ADZ_VALDES", 0)
							oMdlPos:LoadValue("ADZ_DESCON", 0)
							nDisPerc	:= 0
						Else
							nAux	:= NoRound(( nPriceList * (1 - (nDisPerc/100)) ), GetSX3Cache("ADZ_PRCVEN","X3_DECIMAL"))
							oMdlPos:SetValue("ADZ_PRCVEN",  nAux)
							oMdlPos:SetValue("ADZ_TOTAL",   (nQuant * oMdlPos:GetValue("ADZ_PRCVEN")))
							oMdlPos:LoadValue("ADZ_VALDES", Round(((nPriceList - oMdlPos:GetValue("ADZ_PRCVEN")) * nQuant), GetSX3Cache("ADZ_VALDES","X3_DECIMAL")))
						EndIf
						uValue := nDisPerc
					ElseIf cFieldCDom == "ADZ_VALDES"
						If nPriceList == 0						//Se o item não possuir um preço de tabela, não existirá desconto.
							oMdlPos:LoadValue("ADZ_VALDES", 0)
							oMdlPos:LoadValue("ADZ_DESCON", 0)
							nDisVlr	:= 0
						Else
							nAux	:= NoRound(( ( (nPriceList * nQuant) - nDisVlr ) / nQuant ), GetSX3Cache("ADZ_PRCVEN","X3_DECIMAL"))
							oMdlPos:SetValue("ADZ_PRCVEN",	nAux)
							oMdlPos:SetValue("ADZ_TOTAL",	(nQuant * oMdlPos:GetValue("ADZ_PRCVEN")))
							oMdlPos:LoadValue("ADZ_DESCON",	Round(((oMdlPos:GetValue("ADZ_VALDES") / (nPriceList * nQuant)) * 100), GetSX3Cache("ADZ_DESCON","X3_DECIMAL")))
						EndIf
						uValue := nDisVlr
					EndIf
					
			EndCase
			
		EndIf
		
	EndIf
	
	If _lPETrigger
		uValue := ExecBlock("FT600UTRIGGER", .F.,.F., {cFieldDom, cFieldCDom, cMdlDetail, uValue})
	EndIf
	
EndIf

Return	(uValue)

//------------------------------------------------------------------------------
/*/{Protheus.doc} FT600CdTrg
Centraliza as condições (validações) para liberar a execução dos gatilhos
@sample 	FT600CdTrg( cFieldDom, cFieldCDom, cMdlDetail )
@param		cFieldDom		, Caracter	, Campo que disparou o gatilho
			cFieldCDom		, Array		, Campo que recebera o conteudo
			cMdlDetail		, Caracter	, Nome do ModelGrid que o gatilho foi disparado.
@Return   	lValue		 	, Lógico   , .T.=Gatilho pode ser executado, .F.=Gatilho não pode ser executado.
@author	Alexandre da Costa
@since		27/10/2017
@version	12.1.17
/*/
//------------------------------------------------------------------------------
Function FT600CdTrg(cFieldDom, cFieldCDom, cMdlDetail)

Local oModel			:= FwModelActive()
Local aAreas			:= SaveArea1({"SE4"})
Local oMdlADY			:= Nil
Local oMdlPos			:= Nil
Local uValue			:= Nil
Local cPriceList		:= ""
Local cCodEnt 		:= ""
Local cLojEnt			:= ""
Local lProspect		:= .T.
Local lRet				:= .T.

Default cFieldDom 	:= ""
Default cFieldCDom	:= ""
Default cMdlDetail	:= ""

If oModel <> Nil .And. !Empty(cMdlDetail)
	
	oMdlADY 		:= oModel:GetModel("ADYMASTER")
	oMdlPos		:= oModel:GetModel(cMdlDetail)
	lProspect		:= ( oMdlADY:GetValue("ADY_ENTIDA") == "2" )
	cCodEnt 		:= oMdlADY:GetValue("ADY_CODIGO")
	cLojEnt		:= oMdlADY:GetValue("ADY_LOJA")
	cPriceList		:= oMdlADY:GetValue("ADY_TABELA")
	
	Do Case
		Case cFieldDom == "ADZ_PRODUT"
					
			Do Case
				Case cFieldCDom == "ADZ_CONDPG"

					uValue := _cIniCond
					If Empty(uValue)
						uValue := oMdlADY:GetValue("ADY_CONDPG")
						If Empty(uValue)
							DA0->(DbSetOrder(1))
							If DA0->(MsSeek(xFilial("DA0") + cPriceList))
								uValue := DA0->DA0_CONDPG
							EndIf
							If Empty(uValue)
								If !lProspect
									SA1->(DbSetOrder(1))
									If SA1->(MsSeek(xFilial("SA1") + cCodEnt + cLojEnt))
										uValue := SA1->A1_COND
									EndIf
								EndIf
							EndIf
						EndIf
					EndIf
					If	!( Empty(uValue) )
						If	SE4->(DbSeek(xFilial("SE4")+uValue))
							If	SE4->E4_TIPO == "9"
								If	oMdlPos:GetValue("ADZ_PRCVEN") == 0
									// Quando um produto é informado e o mesmo não possuir um preço de tabela, e a condição de pagamento a ser gatilhada for
									// do tipo 9, então, o gatilho para preenchimento da condição de pagamento do produto não pode ser executado.  Pois caso
									// contrário, é exibida a mensagem pedindo para que o usuário informe um valor para o produto.
									// Para esta situação, o usuário deverá informar um valor unitário para o produto, e somente depois, informar a condição
									// de pagamento para o mesmo (manualmente, e não via gatilho automático). 
									lRet	:= .F.
								EndIf
							EndIf
						EndIf
					EndIf

			EndCase

	EndCase
EndIf
RestArea1(aAreas)
Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} FT600MdlDetail

Retorna o model da tabela ADZ em edição no momento

@sample 	FT600MdlDetail()

@Return   	__cMdlDetail, Caracter, Retorna "ADZPRODUTO" ou "ADZACESSOR", de acordo com o model em edição
@author	Anderson Silva
@since		10/03/2016
@version	12.1.7
/*/
//------------------------------------------------------------------------------
Function FT600MdlDetail()

Return( __cMdlDetail )

//-----------------------------------------------------------------------
/*/{Protheus.doc} A600Reprov(oBrwPBlq)
  	 
Realiza a reprovação da proposta.

@param oBrwPBlq, Objeto, Objeto contendo dados da Tela.

@author Squad CRM/Faturamento
@since  04/06/2018

@version 12.1.07+
/*/
//-----------------------------------------------------------------------
Function A600Reprov(oBrwPBlq)
	Local oDlgSide	:= Nil
	Local oDlg		:= Nil
	Local oPanel	:= Nil
	Local oFWLayer 	:= Nil
	Local oColDown 	:= Nil
	Local oLayDown 	:= Nil
	Local oMemo	 	:= Nil
	Local oMotiv	:= Nil 
	Local oMotDesc	:= Nil 
	Local cMemo	 	:= ""
	Local lRet      := .T.
	Local cReason	:= Space(2)
	Local cReasonDsc:= Space(50)
	
	DEFAULT oBrwPBlq := Nil
	
	If oBrwPBlq <> Nil 
		oDlg := FWDialogModal():New()
			oDlg:SetBackground( .T. )
			oDlg:SetEscClose( .T. )
			oDlg:SetSize( 230, 350 )
			oDlg:EnableFormBar( .T. )
				
			oDlg:CreateDialog()
			
			oDlg:AddButton( STR0046,{|| lRet := A600ExcRep(oBrwPBlq:AARRAY[1][1],cReason, cMemo) , IIF( lRet, oDlg:DeActivate(),NIL ) },STR0046,,.T.,.F.,.T., {|| .T.}) //Reprovar																								//"Limpar" ## "Limpar"
			oDlg:AddButton(STR0066,{|| oDlg:DeActivate()},STR0066,,.T.,.F.,.T.)	//Cancelar
			
			oPanel := oDlg:GetPanelMain()
			
			//-------------------------------------------------
			// Cria o painel superior do motivo
			//-------------------------------------------------
			oFWLayer := FWLayer():New()
			oFWLayer:Init( oPanel, .F. )
			oFWLayer:AddLine( "DOWN_BOX", 90, .T.  )
			oFWLayer:AddCollumn( "COLLDOWN_BOX", 100, .T., "DOWN_BOX" )
			
			oColDown := oFWLayer:GetColPanel( "COLLDOWN_BOX", "DOWN_BOX" )

			oLayDown := FWLayer():New()
			oLayDown:Init( oColDown, .F. )
			oLayDown:AddCollumn( "COLL1", 100, .T., "LINE1" )
			oLayDown:AddWindow( "COLL1", "WIN1", STR0413, 25, .F., .F.,,"LINE1" ) //Motivo da Reprovação
			oLayDown:AddWindow( "COLL1", "WIN2", STR0414, 75, .F., .F.,,"LINE1" ) //"Obs. da Reprovação"
		
			oDlgDown := oLayDown:GetWinPanel( "COLL1", "WIN2", "LINE1" )
			oDlgSide := oLayDown:GetWinPanel( "COLL1", "WIN1", "LINE1" )
			//Motivo
			@ 000,000 MSGET oMotiv VAR cReason  OF oDlgSide SIZE 0,0 PIXEL F3 "RZ" VALID A600FReson(cReason, @cReasonDsc) WHEN .T.
			@ 000,025 MSGET oMotDesc VAR cReasonDsc OF oDlgSide SIZE 0,0 PIXEL WHEN .F.
			
			//-------------------------------------------------
			// Adiciona campo memo
			//-------------------------------------------------
			@ 000,000 GET oMemo VAR cMemo  OF oDlgDown MEMO SIZE 0,0 PIXEL WHEN .T.
			oMemo:Align := CONTROL_ALIGN_ALLCLIENT 

		oDlg:Activate()
		
	EndIf
Return .T. 		

//-----------------------------------------------------------------------
/*/{Protheus.doc} A600ExcRep('000001','01', 'string')
  	 
Atualiza campos da ADY

@param	cKey	, Char	, Código da Proposta
		cReason	, Char	, Código da razão da reprovação
		cMemo	, Char	, Cadeia de caracteres com observações da reprovação;
@Return lRet 	, Bool	, Sucesso na reprovação
@author Squad CRM/Faturamento
@since  05/06/2018

@version 12.1.07+
/*/
//-----------------------------------------------------------------------
Static Function A600ExcRep( cKey, cReason, cMemo)		
	Local aArea 	:= {}
	Local aAreaADY	:= {}
	Local lRet		:= .F. 
	Default	cKey	:= ''
	Default cReason := ' '
	Default cMemo	:= ' '
	
	If !Empty(cKey)
		If !A600FReson(cReason)
			MsgAlert(STR0415) //"Caso informe um motivo, seu código deve ser válido"
		Else
			If MsgNoYes(STR0416, STR0096) //"Confirma a Reprovação da Proposta?" #Atenção
				aArea 		:= GetArea()
				aAreaADY	:= ADY->( GetArea() )
				Dbselectarea("ADY")
				ADY->( Dbsetorder(1) ) //ADY_FILIAL+ADY_PROPOS
				IF MsSeek(xFilial("ADY")+ cKey )
					//Não é possivel fazer o update via MVC por causa da validação do modelo que impede ADY_STATUS = Y de ser alterado. 
					ADY->(Reclock( "ADY",.F.) )
						ADY->ADY_STATUS := 'D'
						ADY->ADY_HRREPR := Time()
						ADY->ADY_DTREPR := dDataBase
						ADY->ADY_USREPR := RetCodUsr()
						ADY->ADY_OBSREP := cMemo
						ADY->ADY_MTREPR := cReason
					ADY->(MsUnlock())
					lRet := .T.
					MsgInfo( STR0417 ) // #Proposta comercial reprovada com sucesso
								
				EndIf
				RestArea(aAreaADY)
				RestArea(aArea)
				
				aSize(aArea, 0)
				aSize(aAreaADY,0)
			EndIf
		EndIf
	EndIf

 Return lRet

//-----------------------------------------------------------------------
/*/{Protheus.doc} A600FReson(cReason,cReasonDsc)
Válida o código digitado, atualiza a descrição apresentada na tela

@param	cReason		, Char	, Código do Motivo de reprovação
		cReasonDsc	, Char	, Descrição do Motivo
@Return lRet 	, Bool	, Código do Motivo de reprovação Válido

@author Squad CRM/Faturamento
@since  06/06/2018

@version 12.1.07+
/*/
//-----------------------------------------------------------------------
 Static Function A600FReson( cReason, cReasonDsc)
	Local lRet 			:= .T.
	Local cX5Branch		:= ''
	Default cReason 	:= ''
	Default cReasonDsc	:= ''

	If !Empty(cReason)
		cX5Branch := xFilial("SX5")
		If	!SX5->(MsSeek(cX5Branch+"RZ"+ cReason))
			cReasonDsc := ' '
			lRet := .F.
			MsgAlert(STR0418) //'Motivo Não encontrado!'
		Else
			cReasonDsc :=  Alltrim ( X5Descri() )
		EndIf
	Else
		cReasonDsc := ' '
	EndIf
 Return lRet