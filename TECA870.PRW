#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TECA870.CH"
#INCLUDE "GCTXDEF.CH"

//Status do orçamento de serviços
#DEFINE DEF_TFJ_ATIVO     "1"			//TFJ_STATUS Ativo
#DEFINE DEF_TFJ_EMREVISAO "2"			//TFJ_STATUS Em Revisão
#DEFINE DEF_TFJ_REVISADO  "3"			//TFJ_STATUS Revisado
#DEFINE DEF_TFJ_AGDAPROVA "4"			//TFJ_STATUS Aguardando Aprovação
#DEFINE DEF_TFJ_ENCERRADO "5"			//TFJ_STATUS Encerrado
#DEFINE DEF_TFJ_CANCELADO "6"			//TFJ_STATUS Cancelado

//GESTÃO DE CONTRATOS
#DEFINE DEF_NDESC         "CNBNDESC"	//Identificacao da coluna Novo Desconto
#DEFINE DEF_NVLDESC       "CNBNVLDESC"	//Identificacao da coluna Novo Valor de Desconto
#DEFINE DEF_DESCNA        "CNBDESC"	//Nome de alteracao do campo CNB_DESC para impedir execucao do gatilho
#DEFINE DEF_VLDECNA       "CNBVLDESC"	//Nome de alteracao do campo CNB_DESC para impedir execucao do gatilho

//REVISAO
Static lViTc740 := .F. //Determina se a view do teca740 já está ativa na tela
Static lMtImp   := .T.
Static lMtCns   := .T.

//VINCULO DE BENEFICIOS
Static _aTFFCOD_     := {}	// Armazena os codigos gerados para os itens do RH
Static _aRevisao_    := {}	// Armazena se é revisao e o tipo de revisao

Static oOrcAtual	:= NIL
Static lPedISS := NIL

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECA870
Gestão do Contrato
@author Serviços
@since 30/09/2013
@version P11 R9
@return	nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TECA870()

Local oBrowse
Local aColumns	:= {}
Local cQuery		:= ""
Local cAliasPro	:= "MNTPRO"
Local oDlg			:= Nil   							// Janela Principal.
Local aSize		:= FWGetDialogSize( oMainWnd ) 	// Array com tamanho da janela.
Local aRotPE		:= {}
Local nI			:= 0								//Array P.E.


Pergunte("CNT100",.F.)

aColumns := At870Cols(cAliasPro)
cQuery   := At870Query()

//Cria a tela para o browse
DEFINE DIALOG oDlg TITLE STR0001 FROM aSize[1],aSize[2] TO aSize[3],aSize[4] PIXEL STYLE WS_DLGFRAME       // "Manutenção de Proposta"

	// Cria um Form Browse
	oBrowse := FWFormBrowse():New()
	// Atrela o browse ao Dialog form nao abre sozinho
	oBrowse:SetOwner(oDlg)
	// Indica que vai utilizar query
	oBrowse:SetDataQuery(.T.)
	oBrowse:SetAlias(cAliasPro)
	oBrowse:SetQuery(cQuery)

	//Filtros
	oBrowse:SetUseFilter( .T. )
	oBrowse:SetFieldFilter(aColumns[2])

	//Colunas
	oBrowse:AddStatusColumns({|| At870Contr((cAliasPro)->TFJ_STATUS, (cAliasPro)->TFJ_CONTRT, (cAliasPro)->TFJ_CONREV)}, {|| At870Legen()})
	oBrowse:SetColumns(aColumns[1])

	// Botao de alocação de atendentes
	oBrowse:AddButton(STR0027,; // "Visualizar"
		{|| MsgRun(STR0003,STR0004,{|| At870View((cAliasPro)->TFJ_CODIGO) } ) },,,,.F.,1)// "Montando os componentes visuais..."##"Aguarde"

	// Botao de alocação de atendentes
	oBrowse:AddButton( STR0077,; // "Visualizar Contrato"
		{|| MsgRun(STR0003,STR0004,{|| At870ViCtr((cAliasPro)->TFJ_CODIGO) } ) },,,,.F.,1)// "Montando os componentes visuais..."##"Aguarde"

	//Botao de confirmacao de entrega e coleta
	oBrowse:AddButton( STR0103,; // "Confirm. de Entrega e Coleta"
		{|| MsgRun(STR0003,STR0004,{|| At870Conf((cAliasPro)->TFJ_CODIGO,(cAliasPro)) } ) },,,,.F.,1)// "Montando os componentes visuais..."##"Aguarde"
	// Botao de alocação de atendentes
	oBrowse:AddButton(STR0002,; // "Alocação de atendentes"
		{|| MsgRun(STR0003,STR0004,{|| At870Aloca((cAliasPro)->TFJ_CONTRT,(cAliasPro)->TFJ_CONREV,(cAliasPro)->TFJ_CODIGO, (cAliasPro)) } ) },,,,.F.,1)// "Montando os componentes visuais..."##"Aguarde"

	oBrowse:AddButton(STR0034,; // "Alocação Automatica"
		{|| MsgRun(STR0003,STR0004,{|| At870AlAut((cAliasPro)->TFJ_CONTRT,(cAliasPro)->TFJ_CODIGO, (cAliasPro)) } ) },,,,.F.,1)// "Montando os componentes visuais..."##"Aguarde"

	oBrowse:AddButton(STR0006, {||;
					MsgRun(STR0003,STR0004,{|| At870PRev((cAliasPro)->TFJ_CODIGO,(cAliasPro)->TFJ_CONTRT,(cAliasPro)->TFJ_CONREV) } ),;
					MsgRun(STR0023,STR0004,{|| At870AtuBrw(oBrowse) } );  // "Atualizando informações" # "Aguarde"
				},,,,.F.,2)//"Revisão GCT"

	oBrowse:AddButton(STR0035, {|| At870VlEfR((cAliasPro)->TFJ_STATUS,(cAliasPro)->TFJ_CODIGO,(cAliasPro)->TFJ_TIPREV,oBrowse) },,,,.F.,1) //"Efetiva Revisão"

	oBrowse:AddButton(STR0036, {|| INCLUI:=.F.,ALTERA:=.T.,At870AprRv((cAliasPro)->TFJ_CONTRT,(cAliasPro)->TFJ_CONREV,(cAliasPro)->TFJ_STATUS),INCLUI:=.F.,ALTERA:=.F.,At870AtuBrw(oBrowse) },,,,.F.,1) //"Aprova Revisão"

	oBrowse:AddButton(STR0056, {|| At870GerOrc((cAliasPro)->TFJ_CODIGO,(cAliasPro) ) },,,, .F., 2 )	//'Adicionar Itens Extras'

	oBrowse:AddButton(STR0057, {|| A870EdCAlo((cAliasPro)->TFJ_STATUS,(cAliasPro)->TFJ_CONTRT) },,,, .F., 2 )	//Editar Conf. Alocação

	oBrowse:AddButton(STR0037, {|| lRet := At870ExcR((cAliasPro)->TFJ_STATUS,(cAliasPro)->TFJ_CODIGO), IIF(lRet,At870AtuBrw(oBrowse),Nil),IIf(lRet,MsgInfo(STR0038),Nil)  },,,,.F.,1) //"Excluir"#"Revisão apagada com sucesso."

	oBrowse:AddButton(STR0060, {|| At870GerMem((cAliasPro)->TFJ_CONTRT,(cAliasPro)->TFJ_CONREV,(cAliasPro)) },,,, .F., 2 )	//Memorando

	oBrowse:AddButton(STR0067, {|| At870EncPo((cAliasPro)->TFJ_CONTRT,(cAliasPro)->TFJ_CONREV,(oBrowse), (cAliasPro),(cAliasPro)->TFJ_STATUS) },,,, .F., 2 )	// "Encerramento Posto"

	oBrowse:AddButton(STR0102, {|| At870SIGCT((cAliasPro)->TFJ_CONTRT,(cAliasPro)->TFJ_CONREV),;		//'Sit. CTR GCT'
										MsgRun(STR0023,STR0004,{|| At870AtuBrw(oBrowse) } )},,,, .F., 2 )	// "Atualizando informações" # "Aguarde"

	oBrowse:AddButton(STR0147, {|| TECA850((cAliasPro)->TFJ_CODIGO, (cAliasPro)->TFJ_CONTRT, (cAliasPro)->TFJ_CONREV, (cAliasPro)->TFJ_PROPOS, (cAliasPro)->TFJ_CNTREC), ;
									MsgRun(STR0023,STR0004,{|| At870AtuBrw(oBrowse) } ) },,,, .F., 2 )	//"Manutenção do assistente"

	oBrowse:AddButton(STR0016, {|| AT870Legen()},,,, .F., 2)	//'Legenda'

	oBrowse:AddButton(STR0215, {|| At870Conh((cAliasPro)->TFJ_CODIGO)},,,, .F., 2)	//'Conhecimento'
	
	//Ponto de Entrada para inclusão de botoes na interface
	If (ExistBlock( "AT870MNU" ))
		aRotPE := ExecBlock( "AT870MNU", .F., .F., {cAliasPro,@oBrowse} )
		If ValType(aRotPE) == "A"
			For nI:=1 To Len(aRotPE)
				If ValType(aRotPE[nI]) == "A"
					oBrowse:AddButton(aRotPE[nI][1], aRotPE[nI][2],,,, .F., 2 )
				EndIf
			Next nI
		EndIf
	EndIf

	oBrowse:AddButton(STR0005, {|| oDlg:End()},,,,.F.,1) // "Sair"

	oBrowse:SetParam({|| Pergunte("CNT100",.T.)}) //F12

	SetKey(VK_F10,{|| At870Filt(oBrowse)}) //F10

	oBrowse:DisableDetails()
	oBrowse:SetDescription(STR0001)  // "Manutenção da proposta"
	oBrowse:Activate()

ACTIVATE DIALOG oDlg CENTERED

Return(Nil)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870Query
Query com os dados da proposta
@author Serviços
@since 01/10/2013
@version P11 R9
@return	nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At870Query

Local	cQuery		:= ""
Local	nTamCont	:= TamSX3("TFJ_CONTRT")[2]

If IsInCallStack('At870Filt')
	Pergunte("TECA870",.T.)
EndIf

cQuery += "SELECT TFJ.TFJ_CODIGO, TFJ.TFJ_PROPOS, TFJ.TFJ_PREVIS, TFJ_STATUS, TFJ_TIPREV, "
cQuery +=        "TFJ.TFJ_CONTRT, TFJ.TFJ_CONREV, ADY.ADY_ENTIDA, ADY.ADY_CODIGO, "
cQuery +=        "ADY.ADY_LOJA, AD1.AD1_DTINI, AD1.AD1_DTFIM, AD1.AD1_NROPOR, AD1_DESCRI, A1_NOME, TFJ_CNTREC "
cQuery += " FROM " + RetSqlName("ADY") + " ADY "
cQuery += " JOIN " + RetSqlName("TFJ") + " TFJ "
cQuery +=        " ON TFJ.TFJ_FILIAL = '" + xFilial("TFJ") + "' AND "
cQuery +=           " TFJ.TFJ_PROPOS = ADY.ADY_PROPOS AND "
cQuery +=           " TFJ.TFJ_PREVIS = ADY.ADY_PREVIS AND "
If	IsInCallStack('At870Filt') .And. MV_PAR01 <> 5
	cQuery +=       " TFJ.TFJ_STATUS = '" + Alltrim(STR(MV_PAR01)) + "' AND "
EndIf
cQuery +=           " TFJ.D_E_L_E_T_ = ' ' "

cQuery += " JOIN " + RetSqlName("AD1") + " AD1 "
cQuery +=        " ON AD1.AD1_FILIAL = '" + xFilial("AD1") + "' AND "
cQuery +=           " AD1.AD1_NROPOR = ADY.ADY_OPORTU  AND "
cQuery +=           " AD1.AD1_REVISA = ADY.ADY_REVISA  AND "
cQuery +=           " AD1.D_E_L_E_T_ = ' ' "

cQuery += " LEFT JOIN " + RetSqlName("AAH") + " AAH "
cQuery +=        " ON AAH.AAH_FILIAL = '" + xFilial("AAH") + "' AND "
cQuery +=           " AAH.AAH_CONTRT = TFJ.TFJ_CONTRT AND "
cQuery +=           " AAH.D_E_L_E_T_ = ' ' "

cQuery += " LEFT JOIN " + RetSqlName("CN9") + " CN9 "
cQuery +=        " ON CN9.CN9_FILIAL = '" + xFilial("CN9") + "' AND "
cQuery +=           " CN9.CN9_NUMERO = TFJ.TFJ_CONTRT AND "
cQuery +=           " CN9.CN9_REVISA = TFJ.TFJ_CONREV AND "
cQuery +=           " CN9.D_E_L_E_T_ = ' ' "

cQuery += " LEFT JOIN " + RetSqlName("SA1") + " SA1 "
cQuery +=        " ON SA1.A1_FILIAL = '" + xFilial("SA1") + "' AND "
cQuery +=           " SA1.A1_COD = AD1.AD1_CODCLI AND "
cQuery +=           " SA1.A1_LOJA = AD1.AD1_LOJCLI AND "
cQuery +=           " SA1.D_E_L_E_T_ = ' ' "

cQuery += "WHERE ADY.ADY_FILIAL = '" + xFilial("ADY") + "' AND "
cQuery +=      " ADY.D_E_L_E_T_ = ' ' AND "
cQuery +=      " (TFJ.TFJ_CONTRT <> '"+Space(nTamCont)+"') AND "
cQuery += 	" (AAH.AAH_CONTRT IS NULL OR AAH.AAH_STATUS = '1') "
cQuery += "ORDER BY ADY.ADY_PROPOS, ADY.ADY_REVISA"

Return(cQuery)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870Cols
Colunas para o browse com os dados da proposta
@author Serviços
@since 01/10/2013
@version P11 R9
@param		ExpC1 - Alias utilizado para o retorno das colunas
@return	nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At870Cols(cAliasPro)

Local nI			:= 0 
Local aArea		:= GetArea()
Local aColumns	:= {}
Local aFiltros	:= {}
Local aCampos 	:= {"AD1_NROPOR", "TFJ_PROPOS", "TFJ_PREVIS", "TFJ_CONTRT", "A1_NOME",   "AD1_DESCRI",;
					    "TFJ_CONREV", "ADY_ENTIDA", "ADY_CODIGO", "ADY_LOJA",   "AD1_DTINI", "AD1_DTFIM" }

DbSelectArea("SX3")
SX3->(DbSetOrder(2))

For nI:=1 To Len(aCampos)

	If SX3->(dbSeek(aCampos[nI]))
	
		cCampo := AllTrim(SX3->X3_CAMPO)
		
		AAdd(aColumns,FWBrwColumn():New())
		nLinha := Len(aColumns)
	   	aColumns[nLinha]:SetType(SX3->X3_TIPO)
	   	aColumns[nLinha]:SetTitle(X3Titulo())
		aColumns[nLinha]:SetSize(SX3->X3_TAMANHO)
		aColumns[nLinha]:SetDecimal(SX3->X3_DECIMAL)
		
		If SX3->X3_TIPO == "D"
			aColumns[nLinha]:SetData(&("{|| sTod(" + cCampo + ")}"))
		ElseIf cCampo == "ADY_ENTIDA"
			aColumns[nLinha]:SetData( &("{|| X3Combo('ADY_ENTIDA',MNTPRO->ADY_ENTIDA)}") )		
		Else
			aColumns[nLinha]:SetData(&("{||" + cCampo + "}"))	
		EndIf
		
		aAdd(aFiltros,{cCampo,X3Titulo(),SX3->X3_TIPO,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_PICTURE})
		
	EndIf
	
Next nI

SX3->(dbCloseArea())

RestArea(aArea)

Return({aColumns, aFiltros})

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870PRev
@author rogerio.souza
@since 17/10/2013
@version 11.9
@param cCodTfj, character, Código da referencia da proposta.
@param cCont, character, Código do Contrato.
@param cRevis, character, Revisão do contrato.
@description
Apresenta tela para preenchimento de informações para realização de revisão do gestão de serviços integrada ao Gestão de Contratos
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At870PRev(cCodTfj, cCont, cRevis, lSemTela, cCodCN0, lRevAssist, nPercAuto, nDiasAuto, bSemTela, cNewTFJ )

Local oDlg			:= Nil	//Dialog
Local aSize			:= FWGetDialogSize( oMainWnd )	// Array com tamanho da janela.
Local cCodTR		:= CriaVar("CN0_CODIGO", .F.)	//Space(TamSx3("CN0_CODIGO")[2])
Local cDescTR		:= CriaVar("CN0_DESCRI", .F.)
Local aArea			:= GetArea()
Local aAreaTFJ		:= TFJ->(GetArea())
Local lParamRealM	:= SuperGetMv("MV_CNREALM",,"N") == "S"
Local lWhenCN0		:= .T.
Local lATVREVI		:= SuperGetMv("MV_ATVREVI",,.F.)
Local lOrcPrc		:= SuperGetMV("MV_ORCPRC",,.F.)
Local lRet 			:= .T.
Local nRadio		:= 1
Local cWhenRad		:= Iif (ExistBlock( "AT870REF" ) , ExecBlock( "AT870REF", .F., .F., {} ) , '.T.')
Private nPerc		:= 0
Private nPrazo		:= 0
Private oPerc		:= Nil
Private oPrazo		:= Nil

Default lSemTela := .F.
Default cCodCN0 := ""
Default lRevAssist := .F.
Default nPercAuto := 0
Default nDiasAuto := 0
Default bSemTela := {||.T.}
Default cNewTFJ := ""

If lParamRealM
	lRet := .F.
	If lSemTela
		AutoGrLog( "GSMMVREALM" + " / " + STR0066 )	// "Para realizar revisões de contrato no Gestão de Serviços é necessário desabilitar o parâmetro MV_CNREALM"
	Else
		Help( ' ', 1, "GSMMVREALM", , STR0066, 1, 0 )  // "Para realizar revisões de contrato no Gestão de Serviços é necessário desabilitar o parâmetro MV_CNREALM"
	EndIf
Else
	DbSelectArea("CN9")
	DbSetOrder(1)
	If CN9->(DbSeek(xFilial("CN9")+cCont+cRevis))
		If !(CN9->CN9_SITUAC == DEF_SELAB .Or. CN9->CN9_SITUAC == DEF_SAPRO)	//01=Cancelado;02=Elaboracao;03=Emitido;04=Aprovacao;05=Vigente;06=Paralisa.;07=Sol. Finalizacao;08=Finalizado;09=Revisao;10=Revisado
			// Verfica se o parametro MV_ATVREVI obriga verificação de itens separados
			If lATVREVI 
				lRet := At870Sep(cCodTFJ, lSemTela)
			Endif
			
			If lRet .And. At870VldTFJ(cCodTFJ, lSemTela)
					
				//Recupera tipo de contrato do orçamento de serviços em revisão.
				TFJ->(DbSetOrder(1))//TFJ_FILIAL + TFJ_CODIGO
				If lSemTela .And. !Empty(cCodCN0) 
					If At870VldCN0(cCodCN0, @cDescTR, lSemTela)
						cCodTR := cCodCN0
					Else
						lRet := .F.
						AutoGrLog( "At870RevAuto" + " / " + STR0204 ) // "Parâmetros incompletos para a revisão automática. Envie o Tipo de Revisão e se usar assistente, envie também o percentual ou dias."
					EndIf
				ElseIf TFJ->(DbSeek(xFilial("TFJ")+cCodTfj)) .AND. TFJ->TFJ_STATUS == DEF_TFJ_EMREVISAO
					cCodTR := Posicione("TFJ", 1, xFilial("TFJ")+cCodTfj, "TFJ_TIPREV")
					cDescTR := If(!Empty(cCodTR), Posicione("CN0", 1, xFilial("CN0")+cCodTR, "CN0_DESCRI"), CriaVar("CN0_DESCRI", .F.))
					lWhenCN0 := .F.
				EndIf
				
				If lSemTela
					If !Empty(cCodTR) .And. ( !lRevAssist .Or. ( lRevAssist .And. ( nPercAuto > 0 .Or. nDiasAuto > 0 ) ) )
						lRet := At870Revis(cCodTfj, cCodTr, lRevAssist, nPercAuto, nDiasAuto, lSemTela, bSemTela, @cNewTFJ )
					Else
						lRet := .F.
						AutoGrLog( "At870RevAuto" + " / " + STR0204 ) // "Parâmetros incompletos para a revisão automática. Envie o Tipo de Revisão e se usar assistente, envie também o percentual ou dias."
					EndIf
				Else
					If !((!Empty(TFJ->TFJ_CODTAB) .And. !lOrcPrc) .Or. (Empty(TFJ->TFJ_CODTAB) .And. lOrcPrc)) 
					
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Assistente de Revisão						                    ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					DEFINE DIALOG oDlg TITLE STR0001 FROM  100,115 TO 400,520 PIXEL // "Manutenção de Proposta"
						oDlg:bInit :={|| EnchoiceBar(oDlg, {||( If( lRet := At870LoadRv(cCodTfj,cCodTr,nRadio <> 1,nPerc,nPrazo),oDlg:End(),Nil) )} , {||( oDlg:End() )} ,, {}) }
						
							oGrpTp := TGroup():New(035,005,057,200,"",oDlg,,,.T.)
							@ 043,008 Say STR0010 of oGrpTp PIXEL//"Código"
							@ 040,030 MsGet cCodTR Picture PesqPict("CN0","CN0_CODIGO") F3 "CN0" Valid At870VldCN0(cCodTR, @cDescTR) When lWhenCN0 of oGrpTp PIXEL
							@ 040,073 MsGet cDescTR Picture PesqPict("CN0","CN0_DESCRI") Size 120,0 When .F. of oGrpTp PIXEL
						
							// Modo de Revisão
							oGrpModo := TGroup():New(062,005,090,200,STR0154,oDlg,,,.T.) // "Modo de Revisão"
							
							If !Empty(TFJ->TFJ_CODTAB)
								oRadModo := TRadMenu():New(70,10,{STR0155,STR0156},,oDlg,,,,,,,{||!Empty(cCodTR) .And. &cWhenRad},170,80,,,,.T.) // 'Edição livre' ### 'Com assistente'
							Else
								oRadModo := TRadMenu():New(70,10,{STR0155,'Automático'},,oDlg,,,,,,,{||!Empty(cCodTR) .And. &cWhenRad},170,80,,,,.T.) // 'Edição livre' 
							EndIf	
							 
							oRadModo:bSetGet := {|u|Iif (PCount()==0,nRadio,nRadio:=u)}
							oRadModo:bChange := {|| RefreshGet(oRadModo:nOption == 2,cCodTR) }
						
							// Parametros
							oGrpAss := TGroup():New(095,005,140,200,STR0157,oDlg,,,.T.) // "Parâmetros do Assistente"
							@ 107,010 Say STR0158 of oGrpAss PIXEL // "Percentual"
							@ 105,040 MsGet oPerc VAR nPerc PICTURE '@E 999.99' VALID Positivo(nPerc) Size 25,0 of oGrpAss PIXEL
							oPerc:bWhen := {|| .F.}
							@ 107,072 Say "%" of oGrpAss PIXEL//""
												
							@ 122,010 Say STR0159 of oGrpAss PIXEL // "Prazo"
							@ 120,040 MsGet oPrazo VAR nPrazo PICTURE '@E 999'  Size 25,0 VALID Positivo(nPrazo) of oGrpAss PIXEL
							oPrazo:bWhen := {|| .F.}
							@ 122,070 Say STR0160 of oGrpAss PIXEL // "Dias"
						
						ACTIVATE DIALOG oDlg CENTERED

					Else
			
				
						If (Empty(TFJ->TFJ_CODTAB) .And. lOrcPrc) 
							Help(,,"AT870VTPC",, STR0161,1,0)  // "Orçamento gerado sem tabela de precificação, desabilite o parametro MV_ORCPRC, para abrir o orçamento desta proposta!"							
						EndIf
						If (!Empty(TFJ->TFJ_CODTAB) .And. !lOrcPrc)
							Help(" ",1,"AT870PRECF",,"Orçamento gerado com tabela de precificação, habilite o parametro MV_ORCPRC, para abrir o orçamento desta proposta!";
													,4,0)
						EndIf									

					EndIf
				EndIf	
			EndIf
		Else
			Help( ' ', 1, "At870PRev", , STR0033, 1, 0 )	//"Não é possivel realizar revisões em contratos ainda em elaboração, para realizar alteração no contrato acesse o modulo SIGAGCT e realize as alterações!"
		EndIF
	EndIf
Endif

RestArea(aAreaTFJ)
RestArea(aArea)
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} RefreshGet
@author Cesar Bianchi
@since 11/18/2016
@version 12.1.15
@return lRet
@description
Refresh dos GETs de Percentual e Dias
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function RefreshGet(lEnable,cCodTR)
	Default lEnable := .F.
	Default cCodTR	:= ""

	If ValType(oPerc) == "O" .and. Valtype(oPrazo) == "O"
		//So habilita os gets o codigo do tipo de Revisao nao for vazio
		If !(Empty(cCodTR))
			//Habilita os Gets de acordo com a opcao escolhida
			oPerc:bWhen := {|| lEnable}
			oPrazo:bWhen := {|| lEnable}

			If !lEnable
				nPrazo := 0
				nPerc := 0
			EndIf

		Else
			oPerc:bWhen := {|| .F.}
			oPrazo:bWhen := {|| .F.}

			If !lEnable
				nPrazo := 0
				nPerc := 0
			EndIf
		EndIf

		//Refresh dos componetes de GET
		oPrazo:Refresh()
		oPrazo:SetFocus()
		oPrazo:CtrlRefresh()

		oPerc:Refresh()
		oPerc:SetFocus()
		oPerc:CtrlRefresh()
	EndIf

Return .T.

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870LoadRv
@author Cesar Bianchi
@since 11/18/2016
@version 12.1.15
@param cCodTfj, character, Codigo do orçamento de serviços (TFJ)
@param cCodTr, character, Codigo do tipo de revisão
@return lRet
@description
Realiza a chamada para a funcao principal de Revisao do GS, apresentando uma dialog de Processamento.
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At870LoadRv(cCodTfj,cCodTr,lRevAuto,nPerc,nDias)
Local lRet := .F.

Processa({ || lRet := At870Revis(cCodTfj,cCodTr,lRevAuto,nPerc,nDias) } )

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870Revis
@author rogerio.souza
@since 31/10/2013
@version 11.9
@param cCodTfj, character, Codigo do orçamento de serviços (TFJ)
@param cCodTr, character, Codigo do tipo de revisão
@return lRet
@description
Realiza processo para geração de revisão do orçamento de serviços
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At870Revis(cCodTfj,cCodTr,lRevAuto,nPerc,nDias, lSemTela, bSemTela, cNewTFJ )
Local lRet 		:= .T.
Local oOrcServico	:= Nil
Local oMdlRev 	:= Nil
Local oModel	 	:= Nil
Local lConfirm 	:= .F.
Local lOk	 		:= .T.
Local cRevisao 	:= ""
Local cXmlLoad 	:= ""
Local cTpRev		:= ""
Local nI	 		:= 1
Local nY	 		:= 1
Local nZ	 		:= 1
Local oStruct 	:= Nil
Local nSaldoTFG	:= 0
Local nSaldoTFH	:= 0
Local cSubTFG		:= ""
Local cSubTFH		:= ""
Local oSaldo		:= Nil
Local lOrcPrc		:= SuperGetMv("MV_ORCPRC",,.F.)
Local cOrcMod		:= If( lOrcPrc, "TECA740F", "TECA740" )
Local aTabPrc 	:= ''
Local cTabela 	:= ''
Local cTabRev		:= ''
Local lExeOrc 	:= !lOrcPrc

Local lConPrc
	
// Variaveis Vinculo de Beneficios
Local nX			:= 0
Local nW			:= 0
Local lTecxRh		:= SuperGetMV("MV_TECXRH",,.F.)	// Define se o Gestao de Servico esta integrado com Rh do Microsiga Protheus.
Local cAliasSLY	:= ''
Local cQuerySLY	:= ''
Local aTFFCOD		:= {}
Local aRevisao	:= {}
Local lOkSly	 	:= AliasInDic('SLY')
Local cAtuProp 	:= ""
Local cValUser 	:= ""
Local bLocalVld 	:= Nil
Local oMdlAssist 	:= Nil
Local aRtRev		:= {}
Local nQtdHrf		:= 0
Local nSldHrf		:= 0
	
Default lRevAuto := .F.
Default lSemTela := .F.
Default bSemTela := {|| .T. }
Default cNewTFJ 	:= ""
	
If 	!At870VldInfo(cCodTr)//valida informações
	lOk := .F.		
EndIf

TFJ->( DbSetOrder( 1 ) ) //TFJ_FILIAL + TFJ_CODIGO
If lOk .AND. !TFJ->( DbSeek( xFilial('TFJ')+cCodTFJ ) )
	lOk := .F.
	If lSemTela
		AutoGrLog( "At870Revis" + " / " + STR0018 )	//"Orçamento de Serviços não encontrado"
	Else
		Help( ' ', 1, "At870Revis", , STR0018, 1, 0 )	//"Orçamento de Serviços não encontrado"
	EndIf
EndIf

If lOk
	At600STabPrc( TFJ->TFJ_CODTAB, TFJ->TFJ_TABREV )
	aTabPrc 	:= At600GetTab()
	cTabela 	:= If( aTabPrc[1] <> Nil, aTabPrc[1], "" )
	cTabRev	:= If( aTabPrc[2] <> Nil, aTabPrc[2], "" )
	
	// Atualiza a variavel da revisao
	Aadd(aRevisao,{.T.,At870TpCont(cCodTr)})
	At870SetRe(aRevisao)

	// Atualiza as informações para o novo modelo de precificação 
	// Informando o codigo da tabela e sua revisão
	If lOrcPrc
		If Empty(cTabela) .And. Empty(cTabRev)		
			lConPrc := Conpad1( NIL, NIL, NIL, "TV6" )				
			If lConPrc
				At600STabPrc( TV6->TV6_NUMERO, TV6->TV6_REVISA )
			EndIf		
		EndIf	
		aTabPrc := At600GetTab()
		cTabela := If( aTabPrc[1] <> Nil, aTabPrc[1], "" )
		cTabRev := If( aTabPrc[2] <> Nil, aTabPrc[2], "" )
		lExeOrc := (!Empty(cTabela) .Or. !Empty(cTabRev)) // Verifica tabela e revisao para execução
		If !lExeOrc
			If lSemTela
				AutoGrLog( "TABPRCINVLD" + " / " + STR0078 )	//"Orçamento de Serviços não encontrado"
			Else
				Help(,,"TABPRCINVLD",, STR0078,1,0) // "Tabela de precificação invalida! Não sera possivel carregar o orçamento de serviços."
			EndIf  									
		EndIf
	EndIf
	
	At740FMsg( .F. )
	If (TFJ->TFJ_STATUS == DEF_TFJ_EMREVISAO)//Atualiza Orçamento de serviços que está em revisão		
		oOrcServico 	:= FwLoadModel(cOrcMod)
		oOrcServico:SetOperation( MODEL_OPERATION_UPDATE )
		oMdlRev := FwLoadModel(cOrcMod)				
		oMdlRev:SetOperation( MODEL_OPERATION_UPDATE )
		
		lRet := (oMdlRev:Activate() .And. oOrcServico:Activate())
		If lRet
			cRevisao := oMdlRev:GetValue('TFJ_REFER', 'TFJ_PREVIS')		
		EndIf
		
	Else // Cria Revisão				
		oOrcServico := FwLoadModel(cOrcMod)				
		oOrcServico:SetOperation( MODEL_OPERATION_UPDATE )
		lRet := oOrcServico:Activate()				
		
		If lRet
			//Realiza a copia do Model
			oOrcAtual := oOrcServico
		EndIf
		
		cRevisao := oOrcServico:GetValue('TFJ_REFER', 'TFJ_PREVIS')
				
		//Cria copia do Model da TFJ
		If lRet
			oMdlRev := FwLoadModel(cOrcMod)
			oMdlRev:SetOperation( MODEL_OPERATION_INSERT )
			lRet := oMdlRev:Activate()
			
			If lRet
				If At740CpyMdl( oOrcServico, oMdlRev )
					// -----------------------------------------
					//  utiliza os dados da variável static afwsheet do fonte teca740f
					// para preencher corretamente as informações no objeto de cópia da revisão
					If lOrcPrc
						AT740FCPY(oMdlRev)
					EndIf
					
					//atualiza referencias de registro substituto TFL					
					For nI:=1 To oOrcServico:GetModel("TFL_LOC"):Length()
						oOrcServico:GetModel("TFL_LOC"):GoLine(nI)
						oMdlRev:GetModel("TFL_LOC"):GoLine(nI)						
						oMdlRev:SetValue("TFL_LOC", "TFL_CODSUB", "")																		
						oOrcServico:SetValue("TFL_LOC", "TFL_CODSUB", oMdlRev:GetValue("TFL_LOC", "TFL_CODIGO"))//tfl
												
						For nY := 1 To oOrcServico:GetModel("TFF_RH"):Length()
							oOrcServico:GetModel("TFF_RH"):GoLine(nY)
							oMdlRev:GetModel("TFF_RH"):GoLine(nY)
							
							If !Empty(oOrcServico:GetValue("TFF_RH", "TFF_PRODUT"))							
								oMdlRev:SetValue("TFF_RH", "TFF_CODSUB", "")
								oOrcServico:SetValue("TFF_RH", "TFF_CODSUB", oMdlRev:GetValue("TFF_RH", "TFF_COD"))//TFF
																
								For nZ := 1 To oOrcServico:GetModel("TFG_MI"):Length()
									oOrcServico:GetModel("TFG_MI"):GoLine(nZ)
									oMdlRev:GetModel("TFG_MI"):GoLine(nZ)	
									If !Empty(oOrcServico:GetValue("TFG_MI", "TFG_PRODUT"))
										oOrcServico:LoadValue("TFG_MI", "TFG_CODSUB", oMdlRev:GetValue("TFG_MI", "TFG_COD"))//TFG
										nSaldoTFG := oOrcServico:GetValue("TFG_MI", "TFG_QTDVEN")
										cSubTFG	:= oOrcServico:GetValue("TFG_MI", "TFG_CODSUB")
									EndIf	
								Next nZ	
								
								For nZ := 1 To oOrcServico:GetModel("TFH_MC"):Length()								 
									oOrcServico:GetModel("TFH_MC"):GoLine(nZ)
									oMdlRev:GetModel("TFH_MC"):GoLine(nZ)	
									If !Empty(oOrcServico:GetValue("TFH_MC", "TFH_PRODUT"))							
										oOrcServico:LoadValue("TFH_MC", "TFH_CODSUB", oMdlRev:GetValue("TFH_MC", "TFH_COD"))//TFH
										nSaldoTFH := oOrcServico:GetValue("TFH_MC", "TFH_QTDVEN")
										cSubTFH	:= oOrcServico:GetValue("TFH_MC", "TFH_CODSUB")
									EndIf	
								Next nZ		

								//Armazena os codigos das novas TFF's pra atualizar as rotas de coberturas.
								Aadd(aRtRev,{oOrcServico:GetValue("TFF_RH","TFF_COD"),oMdlRev:GetValue("TFF_RH","TFF_COD")})					
																
								//Atualiza referencia do reforço no modelo de revisão.
								For nW := 1 To oMdlRev:GetModel("TFF_RH"):Length()
									oMdlRev:GetModel("TFF_RH"):GoLine(nW)
									If oOrcServico:GetValue("TFF_RH", "TFF_COD") == oMdlRev:GetValue("TFF_RH", "TFF_ORIREF") .And. oMdlRev:GetValue("TFF_RH", "TFF_TIPORH") == "3" .And. !Empty(oMdlRev:GetValue("TFF_RH", "TFF_PRODUT"))
										oMdlRev:LoadValue("TFF_RH", "TFF_ORIREF", oOrcServico:GetValue("TFF_RH", "TFF_CODSUB"))
									Endif
								Next nW
							EndIf				
						Next nY
						
						For nY := 1 To oOrcServico:GetModel("TFI_LE"):Length()
								oOrcServico:GetModel("TFI_LE"):SetNoUpdateLine(.F.)
								oOrcServico:GetModel("TFI_LE"):GoLine(nY)
								oMdlRev:GetModel("TFI_LE"):GoLine(nY)
								If !Empty(oOrcServico:GetValue("TFI_LE", "TFI_PRODUT"))								
									oOrcServico:SetValue("TFI_LE", "TFI_CODSUB", oMdlRev:GetValue("TFI_LE", "TFI_COD"))//TFI							
								EndIf
								oOrcServico:GetModel("TFI_LE"):SetNoUpdateLine()
						Next nY
																												
					Next nI														
					
					// Caso Integrado utiliza o modelo de beneficios
					If lTecxRh .And. lOkSly
		
						// Replica os Beneficios Vinculados ao item do RH com o novo codigo
						For nX := 1 to oOrcServico:GetModel("TFL_LOC"):Length()
			
							oOrcServico:GetModel("TFL_LOC"):GoLine(nX)
							oMdlRev:GetModel("TFL_LOC"):GoLine(nX)
							
							For nY := 1 to oOrcServico:GetModel("TFF_RH"):Length()
								oOrcServico:GetModel("TFF_RH"):GoLine(nY)
								oMdlRev:GetModel("TFF_RH"):GoLine(nY)
								
								If ! Empty(oOrcServico:GetValue("TFF_RH", "TFF_PRODUT"))
									DbSelectArea("SLY")
									SLY->(DbSetOrder(1))//LY_FILIAL, LY_TIPO, LY_AGRUP, LY_ALIAS, LY_FILENT, LY_CHVENT, LY_CODIGO, LY_DTINI
								
									// Verifica se existe beneficio vinculado
									cAliasSLY := GetNextAlias()
									
									cQuerySLY := "SELECT *"
									cQuerySLY += "  FROM " + RetSqlName("SLY")+" SLY"
									cQuerySLY += " WHERE LY_FILIAL = '" + xFilial("SLY") + "'"
									cQuerySLY += "   AND SUBSTRING(LY_CHVENT,1," + STR(TAMSX3("TFF_COD")[1]) + ") = '" + oOrcServico:GetValue("TFF_RH","TFF_COD") + "'"
									cQuerySLY += "   AND LY_FILENT = '" + oOrcServico:GetValue("TFF_RH","TFF_FILIAL") + "'"
									cQuerySLY += "   AND LY_ALIAS = 'TDX'"
									cQuerySLY += "   AND SLY.D_E_L_E_T_ = ' '"
									cQuerySLY += " ORDER BY LY_FILIAL, LY_TIPO, LY_AGRUP, LY_ALIAS, LY_FILENT, LY_CHVENT, LY_CODIGO, LY_DTINI"
									
									cQuerySLY := ChangeQuery(cQuerySLY)
									
									dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuerySLY),cAliasSLY,.T.,.T.)
		
									While (cAliasSLY)->(!Eof())
		
										If SLY->(DbSeek((cAliasSLY)->(LY_FILIAL+LY_TIPO+LY_AGRUP+LY_ALIAS+LY_FILENT+LY_CHVENT+LY_CODIGO+LY_DTINI)))
										
											If aScan(aTFFCOD,{|x| x[1] = oOrcServico:GetValue("TFF_RH","TFF_COD")}) = 0
												Aadd(aTFFCOD,{oOrcServico:GetValue("TFF_RH","TFF_COD"),oMdlRev:GetValue("TFF_RH","TFF_COD"),'REV'})
											EndIf
		
											// Inclusao do Beneficio de acordo com o codigo gerado									
											RecLock("SLY", .T.)
												SLY->LY_FILIAL	:= (cAliasSLY)->LY_FILIAL
												SLY->LY_TIPO		:= (cAliasSLY)->LY_TIPO	
												SLY->LY_AGRUP		:= (cAliasSLY)->LY_AGRUP
												SLY->LY_ALIAS		:= (cAliasSLY)->LY_ALIAS
												SLY->LY_FILENT	:= (cAliasSLY)->LY_FILENT
												SLY->LY_CHVENT	:= oMdlRev:GetValue("TFF_RH","TFF_COD") + Substr((cAliasSLY)->LY_CHVENT, TAMSX3("TFF_COD")[1]+1, TAMSX3("R6_TURNO")[1])
												SLY->LY_CODIGO	:= (cAliasSLY)->LY_CODIGO
												SLY->LY_PGDUT		:= (cAliasSLY)->LY_PGDUT
												SLY->LY_PGSAB		:= (cAliasSLY)->LY_PGSAB
												SLY->LY_PGDOM		:= (cAliasSLY)->LY_PGDOM
												SLY->LY_PGFER		:= (cAliasSLY)->LY_PGFER
												SLY->LY_PGSUBS	:= (cAliasSLY)->LY_PGSUBS
												SLY->LY_PGFALT	:= (cAliasSLY)->LY_PGFALT
												SLY->LY_PGVAC		:= (cAliasSLY)->LY_PGVAC
												SLY->LY_DIAS		:= (cAliasSLY)->LY_DIAS	
												SLY->LY_DTINI		:= STOD((cAliasSLY)->LY_DTINI)
												SLY->LY_DTFIM		:= STOD((cAliasSLY)->LY_DTFIM)
												SLY->LY_PGAFAS	:= (cAliasSLY)->LY_PGAFAS
											SLY->(MsUnLock())										
										EndIf
										
										dbSelectArea(cAliasSLY)
										(cAliasSLY)->(dbSkip())
									EndDo
		
									// Alimenta o array com os codigos do item do RH
									If Len(aTFFCOD) > 0
										Ft600SetBen(aTFFCOD)
									EndIf
									
									DbSelectArea(cAliasSLY)
									(cAliasSLY)->(DbCloseArea())			
								EndIf				
							Next nY
								
						Next nX
					EndIf					
																			
				EndIf				
			EndIf	 							
		EndIf	
	EndIf
	//-- Aplica os percentuais de reajuste
	If lRet .And. Empty(cTabela) .And. lRevAuto 
						
		lRet := At870RAuto(oMdlRev,oOrcServico,nPerc,nDias)
		
	Else
		If lRet .And. lRevAuto
					
			
			oMdlAssist := FwLoadModel("TECA870B")
			oMdlAssist:SetOperation(MODEL_OPERATION_UPDATE)
			// atribui o percentual padrão
			At870bSet( 1, nPerc )
			// atribui a qtde de dias a prorrogar padrão
			At870bSet( 2, nDias )
			// ativa o modelo para que os dados sejam carregados corretamente utilizando os valores padrões inseridos pelo usuário
			lRet := oMdlAssist:Activate()
			// exibe a janela para o assistente de percentual para revisão quando a rotina não é automática
			If lRet .And. !lSemTela
				lRet := ( FWExecView( STR0205, "VIEWDEF.TECA870B", MODEL_OPERATION_UPDATE, /*oDlg*/,; // "Assistente Revisão"
											{||.T.}/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/,/*aEnableButtons*/,;
											/*bCancel*/, /*cOpratId*/, /*cTooBar*/, oMdlAssist /*oModelAct*/ ) == 0 )
				If !lRet
					oMdlRev:SetErrorMessage(oMdlRev:GetId(),oMdlRev:GetId(),oMdlRev:GetId(), oMdlRev:GetId(),"",; 
							STR0206, STR0207 ) // "Assistente de percentual cancelado." ### "Faça novamente o processo de revisão."
				EndIf
			EndIf
	
			// remonta o modelo de dados considerando as informações recebidas via xml
			If lRet
				// verifica se o objeto está ativo, quando não está recarrega as informações via xml
				If !oMdlAssist:IsActive()
					oMdlAssist := FwLoadModel("TECA870B")
					lRet := oMdlAssist:LoadXmlData(At870bGet( 3 )) .And. !oMdlAssist:HasErrorMessage()
				EndIf
				// avalia se aconteceu algum erro para exibir ou registrar para o usuário
				If !lRet
					AtErroMvc( oMdlAssist:GetModel() )
					If !lSemTela
						MostraErro()
					EndIf
				EndIf
			EndIf
			If lRet 
				oOrcServico:Activate()
			EndIf
			lRet := lRet .And. At870RReaj(oMdlRev,oOrcServico,lOrcPrc, oMdlAssist)
		EndIf
	EndIf
	If lRet
		cNewTFJ := oMdlRev:GetValue('TFJ_REFER', 'TFJ_CODIGO')
		oMdlRev:SetValue( 'TFJ_REFER', 'TFJ_PREVIS', cRevisao )//Atualiza revisão da proposta
		oMdlRev:SetValue( 'TFJ_REFER', 'TFJ_STATUS', DEF_TFJ_EMREVISAO )//Coloca orçamento serviço em revisão
		oMdlRev:SetValue( 'TFJ_REFER', 'TFJ_TIPREV', cCodTr) //Orçamento fica com o tipo de revisão
		oMdlRev:SetValue( 'TFJ_REFER', 'TFJ_CONDPG', CN9->CN9_CONDPG ) //Atualiza a Condição de Pagamento do orçamento
		oMdlRev:SetValue( 'TFL_LOC',   'TFL_CODSUB', "" )//Atualiza CODSUB
		oMdlRev:SetValue( 'TFF_RH',    'TFF_CODSUB', "" )//Atualiza CODSUB
		oMdlRev:SetValue( 'TFG_MI',    'TFG_CODSUB', "" )//Atualiza CODSUB
		oMdlRev:SetValue( 'TFH_MC',    'TFH_CODSUB', "" )//Atualiza CODSUB
		oMdlRev:SetValue( 'TFI_LE',    'TFI_CODSUB', "" )//Atualiza CODSUB
		
		cTpRev := At870TpCont(cCodTr)
			
		// bloqueia a alteração do local/posto ABS
		oMdlRev:GetModel("TFL_LOC"):GetStruct():SetProperty("TFL_LOCAL", MODEL_FIELD_WHEN, {|| Empty(FwFldGet("TFL_CONTRT"))})
		// monta a validação para o campo TFL_LOCAL
		cAtuProp := RTrim( GetSX3Cache("TFL_LOCAL","X3_VALID") ) + " .And. At870Nwl('TFL_LOC')"
		If !Empty( Alltrim(cValUser := GetSX3Cache("TFL_LOCAL","X3_VLDUSER") ) )
			cAtuProp += " .And. " + cValUser
		EndIf
		bLocalVld := FwBuildFeature( STRUCT_FEATURE_VALID, cAtuProp )
		oMdlRev:GetModel("TFL_LOC"):GetStruct():SetProperty("TFL_LOCAL", MODEL_FIELD_VALID, bLocalVld )
	
		// bloqueia a alteração do produtos nos itens
		oMdlRev:GetModel("TFF_RH" ):GetStruct():SetProperty("TFF_PRODUT", MODEL_FIELD_WHEN, {|| Empty(FwFldGet("TFF_CONTRT"))})
		oMdlRev:GetModel("TFG_MI" ):GetStruct():SetProperty("TFG_PRODUT", MODEL_FIELD_WHEN, {|| Empty(FwFldGet("TFG_CONTRT"))})
		oMdlRev:GetModel("TFH_MC" ):GetStruct():SetProperty("TFH_PRODUT", MODEL_FIELD_WHEN, {|| Empty(FwFldGet("TFH_CONTRT"))})
		oMdlRev:GetModel("TFI_LE" ):GetStruct():SetProperty("TFI_PRODUT", MODEL_FIELD_WHEN, {|| Empty(FwFldGet("TFI_CONTRT"))})

		oMdlRev:GetModel("TFI_LE" ):GetStruct():SetProperty("TFI_QTDVEN", MODEL_FIELD_WHEN, {|| Empty(FwFldGet("TFI_CONTRT"))})

		// bloqueia a exclusao de linhas
		oMdlRev:GetModel("TFF_RH"):SetNoDeleteLine()
		oMdlRev:GetModel("TFI_LE"):SetNoDeleteLine()
		oMdlRev:GetModel("TFG_MI"):SetNoDeleteLine()	
		oMdlRev:GetModel("TFH_MC"):SetNoDeleteLine()	
		oMdlRev:GetModel("TEV_ADICIO"):SetNoDeleteLine()
//		oMdlRev:GetModel("ABP_BENEF"):SetNoDeleteLine()
//		oMdlRev:GetModel("TFU_HE"):SetNoDeleteLine()
			
		At740SLoad( oMdlRev ) // atribui o model com o conteúdo copiado para carga na view da rotina		

	Else
		If oOrcServico:HasErrorMessage()
			ViewErroMvc( oOrcServico, !lSemTela /*lExibeErro*/ )
		EndIf
		If oMdlRev:HasErrorMessage()
			ViewErroMvc( oMdlRev, !lSemTela /*lExibeErro*/ )
		EndIf
	EndIf			

	At740FMsg( .F. )//Habilita as mensagens de erro
	At740SCmt( .T. )//habilita commit
	
	If lRet .And. lExeOrc
		AT870SETVT('1', .T.) // indica que o orçamento de serviços estará aberto na tela
		At870RestLins( oMdlRev, lOrcPrc )
		If lSemTela
			lRet := EVal( bSemTela, oMdlRev )
			lRet := lRet .And. oMdlRev:VldData() .And. At870VRes(oMdlRev,cCodTfj) .And. oMdlRev:CommitData()
			If !lRet
				ViewErroMvc( oMdlRev, !lSemTela /*lExibeErro*/ )
			EndIf
		Else
		lRet := ( FWExecView(STR0017,"VIEWDEF."+cOrcMod, MODEL_OPERATION_INSERT, /*oDlg*/, {||.T.} /*bCloseOk*/, ;  // 'Orçamento Serviços'
									{||At870VRes(oMdlRev,cCodTfj)}/*bOk*/,/*nPercRed*/,/*aButtons*/, {||.T.}/*bCancel*/ ) == 0 )	//apresenta copia do model na interface
		EndIf

		If lRet .And. oOrcServico:HasErrorMessage()
			oOrcServico:geterrormessage(.T.)
		Endif
		
		AT870SETVT('1', .F.) // indica que o orçamento de serviços não está mais aberto na tela
	Else 
		lRet := .F.									
	EndIf								
					
	At740FMsg( .F. )
	
	//Faz o Calculo do saldo atualizado nas tabelas TFG e TFH
	oSaldo := FwLoadModel(cOrcMod)				
	oSaldo:SetOperation( MODEL_OPERATION_UPDATE )
	If lRet == .T.
		lRet := oSaldo:Activate()						
	EndIf
	
	If lRet 
		//Atualiza o Saldo da TFH	
		DbSelectArea("TFH")
		TFH->(DbSetOrder(1))
		If TFH->(DbSeek(xFilial("TFH") + cSubTFH ))
			Begin Transaction
				RecLock("TFH",.F.)
					REPLACE TFH_SLD With ((oSaldo:GetValue('TFH_MC', 'TFH_QTDVEN') - nSaldoTFH ) + TFH->TFH_SLD)
				TFH->( MsUnlock() )
			End Transaction
		EndIf
		
		//Atualiza o Saldo da TFG
		DbSelectArea("TFG")
		TFG->(DbSetOrder(1))
		If TFG->(DbSeek(xFilial("TFG") + cSubTFG ))
			Begin Transaction
				RecLock("TFG",.F.)
					REPLACE TFG_SLD With ((oSaldo:GetValue('TFG_MI', 'TFG_QTDVEN') - nSaldoTFG ) + TFG->TFG_SLD)
				TFG->( MsUnlock() )
			End Transaction
		EndIf
	EndIf
	
	At740SLoad( Nil )
	If lRet	
		//Realiza commit do Model com dados de substituiçao anterior a revisão
		If oOrcServico != Nil

			At740SCmt( .T. )//habilita commit
			If oOrcServico:VldData() .And. oOrcServico:CommitData()
				If !Empty(TFJ->TFJ_GRPCOM)
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³SIGATEC WorkFlow # CT - Interações de Contratos Revisão ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					At774Mail("TFJ",TFJ->TFJ_GRPCOM,"CT","<b>"+STR0106+"</b> "+TFJ->TFJ_PROPOS+"<b> "+STR0107+"</b>"+TFJ->TFJ_CONTRT,,STR0108) //"Num. Proposta: " # "Nr. Contrato: " # "Revisão"    
				Endif

				Begin Transaction

					For nX := 1 To Len(aRtRev)
	
						//Atualiza o saldo de quantidade do almocista na TFF
						DbSelectArea("TFF")
						TFF->(DbSetOrder(1))
	
						//Posiciona na TFF original.
						If TFF->(DbSeek(xFilial("TFF") + aRtRev[nX,1] )) .And. TFF->TFF_QTDHRR > 0
							nQtdHrf := TFF->TFF_QTDHRR
							nSldHrf := TFF->TFF_SLDHRR
						Endif
	
						//Posiciona na TFF revisada.
						If TFF->(DbSeek(xFilial("TFF") + aRtRev[nX,2] )) .And. TFF->TFF_QTDHRR > 0
							RecLock("TFF",.F.)
								REPLACE TFF_SLDHRR With ((TFF->TFF_QTDHRR - nQtdHrf ) + nSldHrf)
							TFF->( MsUnlock() )
						EndIf

						nQtdHrf := 0
						nSldHrf := 0

						//Atualiza o codigo da TFF na rota de cobertura aguardando a efetivação.
						At581RtRev(aRtRev[nx,1],aRtRev[nx,2])
											
					Next nX

				End Transaction

			Else
				ViewErroMvc(oOrcServico, !lSemTela)
			EndIf
			At740SCmt( .F. )
		EndIf
		
		If !lSemTela .And. MsgYesNo(STR0039) //"Deseja efetivar a revisão do Orçamento de Serviços?"
			//efetiva revisão
			MsgRun ( STR0029, STR0004, {|| At870EftRv(cNewTFJ,cCodTr,cTpRev ) } ) // 'Processando revisão...' ### "Aguarde..."	
		EndIf
	Else
		// Verificar se foi gerado beneficio
		// Caso positivo deletar os beneficios	
		aTFFCOD := Ft600GetBen()
		// Efetua a exclusao dos benecificios
		IF lOkSly .And. Len(aTFFCOD) > 0
			DbSelectArea("SLY")
			SLY->(DbSetOrder(1))//LY_FILIAL, LY_TIPO, LY_AGRUP, LY_ALIAS, LY_FILENT, LY_CHVENT, LY_CODIGO, LY_DTINI
	
			For nW := 1 to Len(aTFFCOD)
				// Verifica se existe beneficio vinculado
				cAliasSLY := GetNextAlias()
				
				cQuerySLY := "SELECT *"
				cQuerySLY += "  FROM " + RetSqlName("SLY")+" SLY"
				cQuerySLY += " WHERE LY_FILIAL = '" + xFilial("SLY") + "'"
				cQuerySLY += "   AND SUBSTRING(LY_CHVENT,1," + STR(TAMSX3("TFF_COD")[1]) + ") = '" + aTFFCOD[nW][2] + "'"
				cQuerySLY += "   AND LY_FILENT = '" + xFilial("TFF") + "'"
				cQuerySLY += "   AND LY_ALIAS = 'TDX'"
				cQuerySLY += "   AND SLY.D_E_L_E_T_ = ' '"
				cQuerySLY += " ORDER BY LY_FILIAL, LY_TIPO, LY_AGRUP, LY_ALIAS, LY_FILENT, LY_CHVENT, LY_CODIGO, LY_DTINI"
				
				cQuerySLY := ChangeQuery(cQuerySLY)
				
				dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuerySLY),cAliasSLY,.T.,.T.)
				
				While (cAliasSLY)->(!Eof())
	
					If SLY->(DbSeek((cAliasSLY)->(LY_FILIAL+LY_TIPO+LY_AGRUP+LY_ALIAS+LY_FILENT+LY_CHVENT+LY_CODIGO+LY_DTINI)))
						RecLock("SLY", .F.)
							SLY->(DbDelete())
						SLY->(MsUnLock())
					EndIf
					
					dbSelectArea(cAliasSLY)
					(cAliasSLY)->(dbSkip())
				EndDo
		
				DbSelectArea(cAliasSLY)
				(cAliasSLY)->(DbCloseArea())			
		
			Next nW
			FT600SETBEN({}) // Limpa o Array do beneficio
		EndIf			
	EndIf	
EndIf

At870SetRe({}) // Limpa o Array da Revisao

Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870EftRv
@author rogerio.souza
@since 31/10/2013
@version 11.9
@param cCodTfj, character, Codigo do orçamento de serviços (TFJ)
@param cCodTr, character, Codigo do tipo de revisão
@return lRet
@description
Efetiva a geração da revisão do orçamento de serviço, gerando uma revisão para o contrato correspondente 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At870EftRv(cCodTfj,cCodTr,cTpRev,lSemTela, bSemTela, cJustif)

Local cContrato		:= ""	
Local cRevisa		:= ""
Local nY			:= 0
Local oModel		:= Nil
Local oMdlRev		:= Nil
Local lRet			:= .F.
Local nRec			:= 0
Local nDifDay		:= 0
Local nTotLocal 	:= 0
Local oOldModel 	:= NIL
Local lOrcPrc		:= SuperGetMv("MV_ORCPRC",,.F.)
Local cOrcMod		:= If( lOrcPrc, "TECA740F", "TECA740" )
Local dDtFimCtr 	:= CTOD('')
Local oMdlTFJ 		:= Nil
Local oMdlTFL 		:= Nil
Local oMdlTFF 		:= Nil
Local oMdlTFG 		:= Nil
Local oMdlTFH 		:= Nil
Local oMdlTFI 		:= Nil
Local oMdlTEV 		:= Nil
Local oMdlCN9 		:= Nil
Local oMdlCNA 		:= Nil
Local oMdlCNC 		:= Nil
Local oStruCNA		:= Nil
Local oStruCNC		:= Nil
Local oMdlCNB 		:= Nil
Local lAgrup 		:= .T.
Local cPedTit 		:= ""
Local lBlqRevi 		:= SuperGetMv("MV_BLQREVI",,.F.)
Local cRev 			:= ""
Local cLocCCusto 	:= ""


//Grupo de Faturamento
Local lGrpFatOrc:= .F.
Local cPlanRH	:= ""
Local cPlanMC	:= ""
Local cPlanMI	:= ""
Local cPlanLE	:= ""
Local cChaveOrc	:= ""
Local aPlanCli	:= {}
Local nPlanCont	:= 0
Local nPlanItem	:= 0
Local nX		:= 0


Private lRevisad	:= .F.  	
Private nRevRtp	:= 0 //Tipo de Alteracao: 1-Prosseguir,2-Reiniciar,3-Excluir

Default lSemTela 	:= .F.
Default bSemTela 	:= {|| .T. }
Default cJustif		:= ""

INCLUI := .T.

Begin Transaction

	TFJ->(DbSetOrder(1))//TFJ_FILIAL+TFJ_CODIGO
	ABS->(DbSetOrder(1))//ABS_FILIAL+ABS_LOCAL
	If TFJ->(DbSeek(xFilial("TFJ")+cCodTFJ))
		If TFJ->TFJ_STATUS == DEF_TFJ_EMREVISAO
			At740FMsg( .F. ) // Desabilita as mensagens de erro dos campos			
			nRec := TFJ->(Recno())
	
			At600STabPrc( TFJ->TFJ_CODTAB, TFJ->TFJ_TABREV )
	
			oModel := FWLoadModel(cOrcMod)				
			oModel:SetOperation( MODEL_OPERATION_UPDATE)
	
			cContrato 	:= TFJ->TFJ_CONTRT
			cRevisa 	:= TFJ->TFJ_CONREV
			cChaveOrc	:= TFJ->TFJ_CODGRP
	
			A300STpRev(cTpRev)
	
			//Posicionar no Contrato
			DbSelectArea("CN9")
			DbSetOrder(1) // CN9_FILIAL + CN9_NUMERO + CN9_REVISA
			If CN9->(DbSeek(xFilial("CN9")+cContrato+cRevisa))
	
				oMdlRev := FwLoadModel('CNTA301')			
				oMdlRev:SetOperation( OP_INCLUIR ) //Operação como copia para trazer os dados
				lRet := oMdlRev:Activate(.T. /*lCopia*/) // irá copiar os dados dos registros posicionados na CN9 mesmo sendo operação incluir
	
				If lRet 
	
					TFJ->(DbSetOrder(1))//TFJ_FILIAL+TFJ_CODIGO
					TFJ->(DbGoTo(nRec))
					oOldModel := FWModelActive()
					lRet := oModel:Activate()
	
					If lRet
	
						//--------------------------------------------
						// modelos Orçamento de Serviços
						oMdlTFJ := oModel:GetModel("TFJ_REFER")
						oMdlTFL := oModel:GetModel("TFL_LOC")
						oMdlTFF := oModel:GetModel("TFF_RH")
						oMdlTFG := oModel:GetModel("TFG_MI")
						oMdlTFH := oModel:GetModel("TFH_MC")
						oMdlTFI := oModel:GetModel("TFI_LE")
						oMdlTEV := oModel:GetModel("TEV_ADICIO")
	
						//--------------------------------------------
						// modelos Contrato GCT
						oMdlCN9 := oMdlRev:GetModel("CN9MASTER")
						oMdlCNA := oMdlRev:GetModel("CNADETAIL")
						oMdlCNB := oMdlRev:GetModel("CNBDETAIL")
						oMdlCNC := oMdlRev:GetModel("CNCDETAIL")
	
						// identifica como o contrato foi gerado (agrupado ou não)
						lAgrup := ( oMdlTFJ:GetValue("TFJ_DSGCN") <> "1" ) 
						lGrpFatOrc := ( oMdlTFJ:GetValue("TFJ_GRPFAT") == "1" )
					
						FWModelActive(oMdlRev)  //define model GCT como ativo
						oMdlCN9:GetStruct():SetProperty("CN9_TIPREV", MODEL_FIELD_WHEN, {||.T.})

						// atribui o tipo de revisão do contrato
						lRet := lRet .And. oMdlCN9:SetValue("CN9_TIPREV", cCodTr)
						If oMdlCN9:GetValue("CN9_CONDPG") != oMdlTFJ:GetValue("TFJ_CONDPG")
							oMdlCN9:SetValue("CN9_CONDPG", oMdlTFJ:GetValue("TFJ_CONDPG"))
						EndIf
						
						If Empty(oMdlCN9:GetValue("CN9_FILORI"))
							oMdlCN9:GetStruct():SetProperty("CN9_FILORI", MODEL_FIELD_WHEN, {||.T.})
							oMdlCN9:SetValue("CN9_FILORI", oMdlCN9:GetValue("CN9_FILCTR"))
							oMdlCN9:GetStruct():SetProperty("CN9_FILORI", MODEL_FIELD_WHEN, {||.F.})
						EndIf
						
						If lSemTela .and. !Empty(cJustif)
							oMdlCN9:SetValue("CN9_JUSTIF", cJustif)
						EndIf
										
						// captura a data máxima atual do contrato
						dDtFimCtr := oMdlRev:GetValue('CN9MASTER', 'CN9_DTFIM')
						oStruCNC:= oMdlCNC:GetStruct()
						oStruCNC:SetProperty("CNC_CLIENT" 	,MODEL_FIELD_WHEN, {||.T.} )
						oStruCNC:SetProperty("CNC_LOJACL" 	,MODEL_FIELD_WHEN, {||.T.} )
						oStruCNC:SetProperty("CNC_NOMECL" 	,MODEL_FIELD_WHEN, {||.T.} )
						//---------------------------------------------------------------------------
						// executa o primeiro loop nos locais para verificar se precisa trocar o prazo de execução do contrato
						For nY := 1 To oMdlTFL:Length()
							oMdlTFL:GoLine(nY)
							If !oMdlTFL:IsDeleted() .And. dDtFimCtr < oMdlTFL:GetValue( "TFL_DTFIM")
								dDtFimCtr := oMdlTFL:GetValue("TFL_DTFIM")
							EndIf
							If ABS->( DbSeek(xFilial("ABS") + oMdlTFL:GetValue("TFL_LOCAL") ))
								If !(oMdlCNC:SeekLine( {{"CNC_CLIENT", ABS->ABS_CLIFAT }, {"CNC_LOJACL", ABS->ABS_LJFAT }} ))
									
									oMdlCNC:Addline()
									
									oMdlCNC:SetValue("CNC_CLIENT", ABS->ABS_CLIFAT)
									oMdlCNC:SetValue("CNC_LOJACL", ABS->ABS_LJFAT )
								EndIf
							EndIf
						Next nY
	
						// avalia se a data final do contrato sofreu alguma alteração
						If oMdlCN9:GetValue('CN9_DTFIM') <> dDtFimCtr
	
							nDifday := DateDiffDay(oMdlCN9:GetValue('CN9_DTFIM'),dDtFimCtr)
	
							lRet := lRet .And. oMdlCN9:SetValue('CN9_VIGE',  oMdlCN9:GetValue('CN9_VIGE') + nDifDay)
						EndIf
	
						//----------------------------------------------------------------------------
						// executa uma segunda passagem por todos os locais para alterar as informações das planilhas e seus itens
						For nY := 1 To oMdlTFL:Length()
							oMdlTFL:GoLine(nY)
	
							// captura a configuração de geração de pedido ou nf
							cPedTit := If( oMdlTFL:GetValue("TFL_PEDTIT") == "2", "2", "1" )
							cLocCCusto := At160GetCC( oMdlTFL:GetValue("TFL_LOCAL") )
							nTotLocal := oMdlTFL:GetValue( "TFL_TOTRH" ) + oMdlTFL:GetValue( "TFL_TOTMI" ) + oMdlTFL:GetValue( "TFL_TOTMC" ) + oMdlTFL:GetValue( "TFL_TOTLE" )
							// pula os locais que não estejam com valor para o contrato
							
							If lGrpFatOrc 
								lRet := At870GrPlan( cChaveOrc, oMdlTFL:GetValue("TFL_LOCAL"), @cPlanRH, @cPlanMI, @cPlanMC, @cPlanLE )
							EndIf					
							If nTotLocal > 0 .and. lRet 
							
								If !lGrpFatOrc
									At870AtuPlan( oModel, oMdlCNA, oMdlCNB, oMdlTFL:GetValue("TFL_PLAN"), cPedTit, cLocCCusto, cContrato, lSemTela,"" )
								Else
									If oMdlTFL:GetValue( "TFL_TOTRH" ) > 0
										At870AtuPlan( oModel, oMdlCNA, oMdlCNB, cPlanRH, cPedTit, cLocCCusto, cContrato, lSemTela,"RH", nY)
									Endif
									If oMdlTFL:GetValue( "TFL_TOTMI" ) > 0
										At870AtuPlan( oModel, oMdlCNA, oMdlCNB, cPlanMI, cPedTit, cLocCCusto, cContrato, lSemTela,"MI", nY)
									Endif
									If oMdlTFL:GetValue( "TFL_TOTMC" ) > 0
										At870AtuPlan( oModel, oMdlCNA, oMdlCNB, cPlanMC, cPedTit, cLocCCusto, cContrato, lSemTela,"MC", nY)
									Endif
									If oMdlTFL:GetValue( "TFL_TOTLE" ) > 0
										At870AtuPlan(oModel, oMdlCNA, oMdlCNB, cPlanLE, cPedTit, cLocCCusto, cContrato, lSemTela,"LE", nY)
									Endif
								Endif
								If !lRet
									Exit
								EndIf
							EndIf //nTotLocal > 0	
						Next nY
						
						If lRet .and. lGrpFatOrc
							aPlanCli:= At870RetCli(TFJ->TFJ_CODGRP)//Resgata os clientes do grupo de faturamento
							oOldModel := FWModelActive()
							FWModelActive(oMdlRev)
							If (nPlanCont := Len(aPlanCli)) > 0
								oStruCNA:= oMdlCNA:GetStruct()
								oStruCNA:SetProperty("CNA_CLIENT" 	,MODEL_FIELD_WHEN, {||.T.} )
								oStruCNA:SetProperty("CNA_LOJACL" 	,MODEL_FIELD_WHEN, {||.T.} )
								For nY := 1 to nPlanCont
									nPlanItem := Len(aPlanCli[nY])
									For nX:=1 to nPlanItem
										oMdlCNA:Goline(1)
										If !Empty(aPlanCli[nY][nX][1]) .and. oMdlCNA:SeekLine( {{"CNA_NUMERO", aPlanCli[nY][nX][1] }} )
											oMdlCNA:SetValue("CNA_CLIENT", aPlanCli[nY][nX][2])
											oMdlCNA:SetValue("CNA_LOJACL", aPlanCli[nY][nX][3])
										EndIf
									Next nX
								Next nY
								oStruCNA:SetProperty("CNA_CLIENT" 	,MODEL_FIELD_WHEN, {||.F.} )
								oStruCNA:SetProperty("CNA_LOJACL" 	,MODEL_FIELD_WHEN, {||.F.} )
								FWModelActive(oOldModel)
							EndIf
						Endif
	
						If lRet
							oOldModel := FWModelActive()
							FWModelActive(oMdlRev)  //seta model GCT como ativo
	
							oMdlRev:nOperation:=3 //Foi alterado operação para que a manipulação no oMldRev seja incluido em uma nova revisão
	
							oMdlRev:GetModel("CNADETAIL"):GoLine(1)
							oMdlRev:GetModel("CNBDETAIL"):GoLine(1)
							
							If lSemTela
								lRet := lRet .And. Eval( bSemTela, oMdlRev )
								lRet := lRet .And. oMdlRev:VldData() .And. oMdlRev:CommitData()
								If !lRet
									AtErroMvc( oMdlTFL:GetModel() )
								EndIf
							Else
								// bloqueia as alterações nas planilhas, itens e pool de clientes
								oMdlRev:GetModel("CNADETAIL"):SetNoDeleteLine(.T.)
								oMdlRev:GetModel("CNADETAIL"):SetNoInsertLine(.T.)
								oMdlRev:GetModel("CNBDETAIL"):SetNoDeleteLine(.T.)
								oMdlRev:GetModel("CNBDETAIL"):SetNoInsertLine(.T.)
								oMdlRev:GetModel("CNCDETAIL"):SetNoDeleteLine(.T.)
								oMdlRev:GetModel("CNCDETAIL"):SetNoInsertLine(.T.)
								lRet := lRet .And. (FWExecView(STR0006,"CNTA301",OP_COPIA,,{|| .T.},,,,,,,oMdlRev) == 0 ) //"Revisão do Contrato"
													
							EndIf
							FWModelActive(oOldModel)//REstaura ModelActive													
						Else
							// caso tenha acontecido erro, cancela os dados do modelo do orçamento de serviços
							If oModel:HasErrorMessage()
								AtErroMvc( oModel )
								If !lSemTela
									MostraErro()
								EndIf
							EndIf
							oModel:CancelData()
							
							// cancela os dados do modelo do contrato e desativa
							If oMdlRev:HasErrorMessage()
								AtErroMvc( oMdlRev )
								If !lSemTela
									MostraErro()
								EndIf
							EndIf
							oMdlRev:CancelData()
							oMdlRev:DeActivate()
						EndIf
	
						If lRet
	
							cRev := Soma1(cRevisa)
	
							oOldModel := FWModelActive()							
							FWModelActive(oModel)  //seta model SIGATEC como ativo
							
							// alterar para realizar somente a atualização dos campos de saldo nas tabelas TFG, TFH e TEV
							At870AtuOr(oModel,cContrato,cRev)
	
							oModel:SetValue("TFJ_REFER","TFJ_CONREV",cRev)
							oModel:SetValue("TFJ_REFER","TFJ_STATUS",DEF_TFJ_AGDAPROVA)

							FWModelActive(oOldModel)  //REstaura ModelActive
		
							At740SCmt( .T. )
							// Se o dados foram validados faz-se a gravação dos dados (commit)
							If ( lRet := ( oModel:VldData() .And. oModel:CommitData() ) )
								//atualizar SLY - conforme encerramento do posto
								At352Sly(oModel)
							Else  
								aErro := oModel:GetErrorMessage()
	
								AutoGrLog( STR0047 + ' [' + AllToChar( aErro[1] ) + ']' )	//"Id do formulário de origem:"
								AutoGrLog( STR0048 + ' [' + AllToChar( aErro[2] ) + ']' )	//"Id do campo de origem: "
								AutoGrLog( STR0049 + ' [' + AllToChar( aErro[3] ) + ']' )	//"Id do formulário de erro: "
								AutoGrLog( STR0050 + ' [' + AllToChar( aErro[4] ) + ']' )	//"Id do campo de erro: "
								AutoGrLog( STR0051 + ' [' + AllToChar( aErro[5] ) + ']' )	//"Id do erro: "
								AutoGrLog( STR0052 + ' [' + AllToChar( aErro[6] ) + ']' )	//"Mensagem do erro: "
								AutoGrLog( STR0053 + ' [' + AllToChar( aErro[7] ) + ']' )	//"Mensagem da solução: "
								AutoGrLog( STR0054 + ' [' + AllToChar( aErro[8] ) + ']' )	//"Valor atribuído: "
								AutoGrLog( STR0055 + ' [' + AllToChar( aErro[9] ) + ']' )	//"Valor anterior: "
	
								If !lSemTela
									MostraErro()
								EndIf
							EndIf
							If lRet .and. lGrpFatOrc
								DbSelectArea("T42")
								DbSetOrder(3) // T42_FILIAL+ T42_CHAVE
									
								If T42->( DbSeek(xFilial("T42") + TFJ->TFJ_CODGRP) ) 
									RecLock( "T42", .F. )
										T42_STATUS:= "3" //EM APROVAÇÃO 
									T42->( MsUnlock() )
								
								EndIf
							
							EndIf
							/*If lRet .and. ExistBlock("AT870EFTRV")
								ExecBlock("AT870EFTRV",.F.,.F.,{oModel})
							EndIf*/
						EndIf
	
						oModel:DeActivate()
					EndIf
	
				EndIf
	
			EndIf
	
		Else
			Help( ' ', 1, 'At870EftRv', , STR0022, 1, 0 )	//"Efetivação de revisão permitida somente para orçamento de serviços com status 'Em Revisão'."
		EndIf		
	
	Else
		Help( ' ', 1, 'At870EftRv', , STR0018, 1, 0 )	//"Orçamento de Serviços não encontrado"
	EndIf
	
	If !lRet
		DisarmTransacation()
	Endif		
	
	If lRet .AND. !Empty(TFJ->TFJ_GRPCOM)
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³SIGATEC WorkFlow # CT - Interações de Contratos Efetivação ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		At774Mail("TFJ",TFJ->TFJ_GRPCOM,"CT","<b>"+STR0106+"</b> "+TFJ->TFJ_PROPOS+"<b> "+STR0107+"</b>"+TFJ->TFJ_CONTRT,,STR0109) //"Num. Proposta: " # "Nr. Contrato: " # "Efetivação"
	Endif
	
	If lRet
		//Atualiza a rota de cobertura com os novos codigos da TFF.
		At581AtuRt(TFJ->TFJ_CODIGO)
	Endif

	At740SCmt( .F. )
End Transaction

Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870Aprov
@author rogerio.souza
@since 31/10/2013
@version 11.9
@param cContra, character Numero do contrato
@param cRevisa, character Revisão do contrato aprovado
@description
Realiza processo de aprovação da revisão do contrato, realizando atualizações de referencias e revisões no Gestão de Serviços
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At870Aprov(cContra, cRevisa, lSemTela)
Local cAliasQry	:= GetNextAlias()	
Local cStatus		:= DEF_TFJ_AGDAPROVA//Status aguardando aprovação
Local cCodTFJ		:= ""
Local cFilTFJ		:= ""	
Local cOldRevis	:= ""//Revisão anterior
Local aItens		:= {}
Local cCodTfjAnt	:= ""
Local aArea		:= GetArea()
Local aAreaTFJ	:= TFJ->(GetArea())
Local aAreaTFI	:= TFI->(GetArea())
Local aAreaTFL	:= TFL->(GetArea())
Local aAreaTFF	:= TFF->(GetArea())
Local cGrpCom	:= ""
Local cNumProp	:= ""
Local lOrcPrc 	:= SuperGetMv("MV_ORCPRC",,.F.)

Default lSemTela := .F.

//Recupera TFJ com status em revisão referente ao contrato que está sendo aprovado
BeginSQL Alias cAliasQry       
	SELECT  TFJ_FILIAL, TFJ_CODIGO, TFJ_CONREV, TFJ_GRPCOM, TFJ_PROPOS
	FROM %Table:TFJ% TFJ		
	WHERE 
	TFJ.TFJ_FILIAL = %xFilial:TFJ% AND
	TFJ.TFJ_CONTRT = %Exp:cContra% AND
	TFJ.TFJ_STATUS = %Exp:cStatus% AND 		
	TFJ.%notDel%	
EndSql

If  (cAliasQry)->(!EOF())
	cFilTFJ := (cAliasQry)->TFJ_FILIAL
	cCodTFJ := (cAliasQry)->TFJ_CODIGO
	cOldRevis := (cAliasQry)->TFJ_CONREV
	cGrpCom	  := (cAliasQry)->TFJ_GRPCOM
	cNumProp  := (cAliasQry)->TFJ_PROPOS
EndIf

(cAliasQry)->(DbCloseArea())


BEGIN TRANSACTION
	
	//Atualiza status da TFJ para revisado.
	TFJ->(DbSetOrder(5))//TFJ_FILIAL+TFJ_CONTRT+TFJ_CONREV
	TFJ->(DbSeek(cFilTFJ+cContra/*+cOldRevis*/))
	While TFJ->(!EOF()) .AND. TFJ->TFJ_CONTRT == cContra
		If TFJ->TFJ_STATUS != DEF_TFJ_AGDAPROVA
			
			//Armazena condigo anterior da TFJ
			If TFJ->TFJ_STATUS == DEF_TFJ_ATIVO
				cCodTfjAnt := TFJ->TFJ_CODIGO
				TFJ->(RecLock("TFJ", .F.))
				TFJ->TFJ_STATUS := DEF_TFJ_REVISADO
				TFJ->(MsUnlock())
			EndIf
		EndIf
		TFJ->(DbSkip())
	EndDo
		
	//Atualiza status e revisão do orçamento que será considerado como ativo
	TFJ->(DbSetOrder(1))//TFJ_FILIAL+TFJ_CODIGO
	If TFJ->(DbSeek(cFilTFJ+cCodTFJ))
		TFJ->(RecLock("TFJ", .F.))
		TFJ->TFJ_CONREV := cRevisa
		TFJ->TFJ_STATUS := DEF_TFJ_ATIVO 
		TFJ->(MsUnlock())
	EndIf
		
	//Atualiza informações da TFL e TFI
	TFL->(DbSetOrder(2))//TFL_FILIAL+TFJ_CODPAI
	TFI->(DbSetOrder(3))//TFI_FILIAL+TFI_CODPAI
	TFF->(DbSetOrder(3))//TFF_FILIAL+TFF_CODPAI
	TFL->(DbSeek(xFilial("TFL")+cCodTFJ))
	While TFL->(!EOF()) .AND. TFL->TFL_FILIAL == cFilTFJ .AND. TFL->TFL_CODPAI == cCodTFJ
		
		//Recupera itens das planilhas que foram criados devido ao realinhamento
		aItens := atuItPL(cContra, cOldRevis, cRevisa, TFL->TFL_PLAN, {TFL->TFL_ITPLRH, TFL->TFL_ITPLMI, TFL->TFL_ITPLMC, TFL->TFL_ITPLLE })
		
		TFL->(RecLock("TFL", .F.))
		TFL->TFL_CONTRT := cContra
		TFL->TFL_CONREV := cRevisa								
		TFL->TFL_ITPLRH := aItens[1]
		TFL->TFL_ITPLMI := aItens[2]
		TFL->TFL_ITPLMC := aItens[3]
		TFL->TFL_ITPLLE := aItens[4]			
		TFL->(MsUnlock())
		
		//Atualiza TFF
		If TFF->(DbSeek(xFilial("TFF")+TFL->TFL_CODIGO))			
			While ( TFF->(!EOF()) .AND. TFF->TFF_FILIAL == xFilial("TFF") .AND. TFF->TFF_CODPAI == TFL->TFL_CODIGO)			
				TFF->(RecLock("TFF"), .F.)				
				TFF->TFF_CONTRT := cContra
				TFF->TFF_CONREV := cRevisa
				TFF->(MsUnlock())

				If !lOrcPrc
					At870MtCtr(lOrcPrc, cContra, cRevisa)
				EndIf

				TFF->(DbSkip())
			EndDo		
		EndIf
		
		If lOrcPrc
			At870MtCtr(lOrcPrc, cContra, cRevisa)
		EndIf

		//Atualiza TFI
		If TFI->(DbSeek(xFilial("TFI")+TFL->TFL_CODIGO))
			
			While ( TFI->(!EOF()) .AND. TFI->TFI_FILIAL == xFilial("TFI") .AND. TFI->TFI_CODPAI == TFL->TFL_CODIGO)					
				TFI->(RecLock("TFI"), .F.)
				If Empty(TFI->TFI_CONTRT)
					TFI->TFI_SEPARA := "2"
				EndIf
				TFI->TFI_CONTRT := cContra
				TFI->TFI_CONREV := cRevisa
				TFI->(MsUnlock())
				TFI->(DbSkip())
			EndDo
			
		EndIf					
				
		TFL->(DbSkip())
	EndDo
	
	If lSemTela
		At870AtuGrp(cRevisa) //Atualizando grupo de faturamento
	else
		MsgRun ( "Atualizando informações do grupo de faturamento", STR0004, {|| At870AtuGrp(cRevisa) } ) // "Atualizando informações do grupo de faturamento" ### "Aguarde..."
	EndIf	
	
	If lSemTela
		CopyApont(cCodTfjAnt, cCodTFJ) //realiza cópia dos dados de apontamento para a revisão atual.
	Else 
		MsgRun ( "Atualizando informações do apontamento de material", STR0004, {|| CopyApont(cCodTfjAnt, cCodTFJ) } ) // "Atualizando informações do grupo de faturamento" ### "Aguarde..."
	EndIf
	
	CopyABQ(cCodTFJ)//realiza cópia dos dados de configuração de alocação para a revisão atual.
	
	At870AtAlo(cCodTfjAnt)//Atualiza agenda do tecnico para nova configuração de alocação
	
	AtuLocEqui(cCodTFJAnt, cCodTFJ, lSemTela)//Atualiza referencias da locação de equipamentos

	At870AtGES(cCodTFJAnt, cCodTFJ)  // atualiza informação da gestão de escalas

	At870OsMont( cCodTFJAnt, cCodTFJ )
	
	At870FatAnt( cContra, cRevisa ) //Atualiza as informações do faturamento antecipado.
	
	If lSemTela
		AtuDespAd(cCodTFJAnt, cCodTFJ) // Atualiza as informações de despesas adicionais
	Else
		MsgRun ( "Atualizando informações de despesas adicionais", STR0004, {|| AtuDespAd(cCodTFJAnt, cCodTFJ)  } ) // "Atualizando informações de despesas adicionais" ### "Aguarde..."
	EndIf

	At870RvRef(cCodTFJAnt) // Atualiza as informações de reforço

	If !Empty(cGrpCom)
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³SIGATEC WorkFlow # CT - Interações de Contratos Aprovação Revisão ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		At774Mail("TFJ",TFJ->TFJ_GRPCOM,"CT","<b>"+STR0106+"</b> "+cNumProp+"<b> "+STR0107+"</b>"+cContra,,STR0110) //"Num. Proposta: " # "Nr. Contrato: " # "Aprovação da Revisão"
	Endif	
END TRANSACTION
	
RestArea(aAreaTFJ)
RestArea(aAreaTFI)
RestArea(aAreaTFL)
RestArea(aAreaTFF)
RestArea(aArea)

Return

/*/{Protheus.doc} At870MtCtr
@description 	Atualiza os dados de contrato e revisão nos materias conforme o orçamento sendo utilizado (com precificação ou não)
@author 		josimar.assuncao
@since 			23/11/2016
/*/
Static Function At870MtCtr(lOrcPrc, cContra, cRevisa)

Local cSuperior := If( lOrcPrc, TFL->TFL_CODIGO, TFF->TFF_COD )
Local cFilTFG 	:= xFilial("TFG")
Local cFilTFH 	:= xFilial("TFH")

TFG->(DbSetOrder(3))  //TFG_FILIAL+TFG_CODPAI
TFH->(DbSetOrder(3))  //TFH_FILIAL+TFH_CODPAI

If TFG->( DbSeek( xFilial("TFG")+cSuperior ) )

	While TFG->(!EOF()) .And. TFG->TFG_FILIAL == cFilTFG .And. TFG->TFG_CODPAI == cSuperior

		TFG->(RecLock("TFG"), .F.)
		TFG->TFG_CONTRT := cContra
		TFG->TFG_CONREV := cRevisa
		TFG->(MsUnlock())

		TFG->(DbSkip())
	End
EndIf

If TFH->( DbSeek( xFilial("TFH")+cSuperior ) )

	While TFH->(!EOF()) .And. TFH->TFH_FILIAL == cFilTFG .And. TFH->TFH_CODPAI == cSuperior

		TFH->(RecLock("TFH"), .F.)
		TFH->TFH_CONTRT := cContra
		TFH->TFH_CONREV := cRevisa
		TFH->(MsUnlock())

		TFH->(DbSkip())
	End
EndIf

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtuLocEqui
@author rogerio.souza
@since 31/10/2013
@version 11.9
@param cCodTFJ, character, Codigo do orçamento de serviços
@param cCodTFJNew, character, Codigo do orçamento de serviços da revisão anterior
@description
Atualiza referencias da locação de equipamentos.
Atualização das referencias entre TFI e TEW (TEW_ORCSER, TEW_CODEQU) para considerar os novos itens.
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function AtuLocEqui(cCodTFJ, cCodTFJNew, lSemTela)
Local cAliasQry	:= GetNextAlias()
Local cMsgErr		:= ""
Local lRet			:= .T.
Local aArea		:= GetArea()
Local aAreaTEW	:= TEW->(GetArea())
Local aAreaTFJ	:= TFJ->(GetArea())

Default lSemTela := .F.

//Atualiza movimentações
BeginSQL Alias cAliasQry       
	SELECT  TEW.TEW_FILIAL, TEW.TEW_CODMV, TFI.TFI_CODSUB
		FROM %Table:TEW% TEW
		
		INNER JOIN %Table:TFI% TFI ON
			TEW.TEW_FILIAL = TFI.TFI_FILIAL AND
			TEW.TEW_CODEQU = TFI.TFI_COD AND
			TFI.%notDel%
			
		INNER JOIN %Table:TFL% TFL ON
			TFI.TFI_FILIAL = TFI.TFI_FILIAL AND
			TFI.TFI_CODPAI = TFL.TFL_CODIGO AND
			TFL.TFL_CODPAI = %Exp:cCodTFJ% AND 
			TFL.%notDel%				
	WHERE 
		TEW.TEW_FILIAL = %xFilial:TEW% AND		
		TFL.TFL_CODPAI = %Exp:cCodTFJ% AND			 	
		TEW.%notDel%	
EndSql

DbSelectArea("TEW")
TEW->(DbSetOrder(1))// TEW_FILIAL+TEW_CODMV
While (cAliasQry)->(!EOF())	
	If TEW->(DbSeek((cAliasQry)->TEW_FILIAL+(cAliasQry)->TEW_CODMV))
		TEW->(RecLock("TEW", .F.))
		TEW->TEW_CODEQU := (cAliasQry)->TFI_CODSUB
		TEW->TEW_ORCSER := cCodTFJNew
		MsUnlock()	
	EndIf	
	
	(cAliasQry)->(DbSkip())
EndDo
(cAliasQry)->(DbCloseArea())

//Gera movimentação da locação de atendimento
DbSelectArea('TFJ')
TFJ->( DbSetOrder( 1 ) ) //TFJ_FILIAL+TFJ_CODIGO
If TFJ->( DbSeek( xFilial('TFJ')+cCodTFJNew ) )
	If lSemTela
		lRet := At800Start( @cMsgErr, TFJ->TFJ_CODIGO )
	Else
		MsgRun ( STR0028, STR0004, {|| lRet := At800Start( @cMsgErr, TFJ->TFJ_CODIGO ) } ) // 'Gerando movimentos para locação de equipamentos' ### "Aguarde..."
	EndIf	
EndIf

If !lRet
	Help(,,'AT870LOCEQUIP',, cMsgErr,1,0)
EndIf

RestArea(aAreaTFJ)
RestArea(aAreaTEW)
RestArea(aArea)

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} copyABQ
@author rogerio.souza
@since 31/10/2013
@version 11.9
@param cCodTFJ, character, Codigo do orçamento de serviços)
@description
Gera registros de configuração de alocação para a nova revisão do orçamento de serviços
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function copyABQ(cCodTFJ)

Local cAliasQry	:= GetNextAlias()
Local aItemRh		:= {}
Local aArea		:= GetArea()
Local aAreaTFF	:= TFF->(GetArea())
Local lSeqTrn		:= (TFF->(FieldPos("TFF_SEQTRN"))>0)
Local oDlg		:= nil
Local oSayMtr	:= nil
Local nMeter	:= 0
Local nTotal	:= 0
Local nTotLoc := 0
Local nCntLoc := 0

//Recupera locais de atendimento
BeginSQL Alias cAliasQry       
	SELECT  TFL_CONTRT, TFL_LOCAL, TFL_CODIGO
	FROM %Table:TFL% TFL		
WHERE 
	TFL.TFL_FILIAL = %xFilial:TFL% AND
	TFL.TFL_CODPAI = %Exp:cCodTFJ% AND	 	
	TFL.%notDel%	
EndSql

TFF->(DbSetOrder(3))//TFF_FILIAL+TFF_CODPAI

While (cAliasQry)->(!EOF())
	nTotLoc++
	(cAliasQry)->(DbSkip())
End

While (cAliasQry)->(!EOF())
	
	aItemRH := {}	
	TFF->(DbSeek(xFilial("TFF")+(cAliasQry)->TFL_CODIGO))
	While TFF->(!EOF()) .AND. TFF->TFF_FILIAL == xFilial("TFF") .AND. TFF->TFF_CODPAI ==  (cAliasQry)->TFL_CODIGO
		
		Aadd(aItemRH,{;
					TFF->TFF_PRODUT	,;
					TFF->TFF_CARGO	,;
					TFF->TFF_FUNCAO	,;
					TFF->TFF_PERINI	,;
					TFF->TFF_PERFIM	,;
					TFF->TFF_TURNO	,;
					TFF->TFF_QTDVEN	,;
					TFF->TFF_COD		,;
					If( lSeqTrn, TFF->TFF_SEQTRN, "" ),;
					.T.,;
					TFF->TFF_FILIAL ,;		
					TFF->TFF_ESCALA ,;		
					TFF->TFF_CALEND } )	
						
		TFF->(DbSkip())
	EndDo
	
	If isBlind()
		At850CnfAlc((cAliasQry)->TFL_CONTRT, (cAliasQry)->TFL_LOCAL, aItemRH, cCodTFJ)//Gera ABQ
	Else 
		oDlg := nil
		oSayMtr := nil
		nMeter := 0
		nTotal := LEN(aItemRH)
		DEFINE MSDIALOG oDlg FROM 0,0 TO 5,60 TITLE STR0258 + " ( " + cValToChar(++nCntLoc) + " / " + cValToChar(nTotLoc) + " )" //"Atualizando configuração de alocação..."
			oSayMtr := tSay():New(10,10,{||STR0257},oDlg,,,,,,.T.,,,220,20) //"Processando, aguarde..."
			oMeter  := tMeter():New(20,10,{|u|if(Pcount()>0,nMeter:=u,nMeter)},nTotal,oDlg,220,10,,.T.,/*uParam10*/,/*uParam11*/,.T.)
		ACTIVATE MSDIALOG oDlg CENTERED ON INIT (At850CnfAlc((cAliasQry)->TFL_CONTRT,(cAliasQry)->TFL_LOCAL,aItemRH,@oDlg,@oMeter))
	EndIf 	
	
	(cAliasQry)->(DbSkip())
EndDo

(cAliasQry)->(DbCloseArea())

RestArea(aAreaTFF)
RestArea(aArea)

Return


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870AtAlo
@sample        At870AtAlo(cTFJOrig)
@param         cTFJOrig, character, Codigo do orçamento de serviços PAI (TFJ)
@return        NIL
@author        rogerio.souza
@version       11.9
@description 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At870AtAlo(cTFJOrig)

Local cAliasABQ	:= GetNextAlias()
Local cAliasABB	:= GetNextAlias()
Local aInfo		:= {}
Local aAux			:= {}
Local cIn			:= ""
Local nPos			:= 0
Local nI			:= 0
Local aArea		:= GetArea()
Local aAreaABB	:= ABB->(GetArea())
Local aAreaABQ	:= ABQ->(GetArea())
Local nTotal 	:= 0
Local oDlg		:= nil
Local oSayMtr	:= nil
Local nMeter	:= 0

BeginSql Alias cAliasABQ
	SELECT 
        TFF.TFF_COD, 
        TFF.TFF_CODSUB, 
        ABQ.ABQ_CONTRT, 
        ABQ.ABQ_ITEM, 
        ABQ.ABQ_ORIGEM,
        ABQ.ABQ_TOTAL,
        ABQ.ABQ_SALDO,
		ABQ2.ABQ_CONTRT CONTRTSUB, 
		ABQ2.ABQ_ITEM ITEMSUB, 
		ABQ2.ABQ_ORIGEM ORIGEMSUB
		
	FROM %table:ABQ% ABQ
	
	INNER JOIN %table:TFF% TFF ON
		TFF.TFF_FILIAL = %xFilial:TFF% AND
		TFF.TFF_FILIAL = ABQ.ABQ_FILTFF AND
		TFF.TFF_COD = ABQ.ABQ_CODTFF AND
		TFF.%notdel%
	
	INNER JOIN %table:TFL% TFL ON
		TFL.TFL_FILIAL = %xFilial:TFL% AND
		TFL.TFL_CODPAI = %Exp:cTFJOrig% AND
		TFL.TFL_CODIGO = TFF.TFF_CODPAI	AND	
		TFL.%notdel%
		
	INNER JOIN %table:ABQ% ABQ2 ON
		ABQ2.ABQ_FILIAL = %xFilial:ABQ% AND
		ABQ2.ABQ_CODTFF = TFF.TFF_CODSUB AND
		ABQ2.%notdel%
		
	WHERE 
		ABQ.ABQ_FILIAL = %xFilial:ABQ% AND
		TFL.TFL_CODPAI = %Exp:cTFJOrig% AND
		ABQ.%notdel%
EndSql

While (cAliasABQ)->(!EOF())
	nTotal++
	(cAliasABQ)->(DbSkip())
End
(cAliasABQ)->(DbGoTop())

If isBlind()
	SumABQConf(cAliasABQ,@aInfo,@cIn)
Else
	DEFINE MSDIALOG oDlg FROM 0,0 TO 5,60 TITLE STR0259 //"Localizando configuração de alocação"
		oSayMtr := tSay():New(10,10,{||STR0257},oDlg,,,,,,.T.,,,220,20) //"Processando, aguarde..."
		oMeter  := tMeter():New(20,10,{|u|if(Pcount()>0,nMeter:=u,nMeter)},nTotal,oDlg,220,10,,.T.)
		
	ACTIVATE MSDIALOG oDlg CENTERED ON INIT (SumABQConf(cAliasABQ,@aInfo,@cIn,@oDlg,@oMeter))
EndIf

nTotal := 0
oDlg := nil
oSayMtr	:= nil
nMeter	:= 0

If !Empty(cIn)	
	cIn := SubStr(cIn, 1, Len(cIn)-1)//Retira ultimo caracter
	cIn := StrTran(cIn, ',', "','")//substitui virgula considerando aspas da instrução IN do SQL
	
	BeginSql Alias cAliasABB
		SELECT 
	        ABB_CODIGO, ABB_IDCFAL	
		FROM %table:ABB% ABB
			
		WHERE 
			ABB.ABB_FILIAL = %xFilial:ABB% AND
			ABB.ABB_IDCFAL IN (%Exp:cIn%)		AND	
			ABB.%notdel%
	EndSql
	
	While (cAliasABB)->(!EOF())
		nTotal++
		(cAliasABB)->(DbSkip())
	End
	(cAliasABB)->(DbGoTop())

	If isBlind()
		UpdABBIdCf(cAliasABB, aInfo)
	Else
		DEFINE MSDIALOG oDlg FROM 0,0 TO 5,60 TITLE STR0260 //"Atualizando ID das alocações"
			oSayMtr := tSay():New(10,10,{||STR0257},oDlg,,,,,,.T.,,,220,20) //"Processando, aguarde..."
			oMeter  := tMeter():New(20,10,{|u|if(Pcount()>0,nMeter:=u,nMeter)},nTotal,oDlg,220,10,,.T.)
			
		ACTIVATE MSDIALOG oDlg CENTERED ON INIT (UpdABBIdCf(cAliasABB, aInfo,@oDlg,@oMeter))
	EndIf
	
	nTotal := 0
	oDlg := nil
	oSayMtr	:= nil
	nMeter	:= 0

EndIf

nTotal := Len(aInfo)
If isBlind()
	UpdABQSald(aInfo)
Else
	DEFINE MSDIALOG oDlg FROM 0,0 TO 5,60 TITLE STR0261 //"Atualizando saldo de alocação"
		oSayMtr := tSay():New(10,10,{||STR0257},oDlg,,,,,,.T.,,,220,20) //"Processando, aguarde..."
		oMeter  := tMeter():New(20,10,{|u|if(Pcount()>0,nMeter:=u,nMeter)},nTotal,oDlg,220,10,,.T.)
		
	ACTIVATE MSDIALOG oDlg CENTERED ON INIT (UpdABQSald(aInfo,@oDlg,@oMeter))
EndIf

RestArea(aAreaABQ)
RestArea(aAreaABB)
RestArea(aArea)		

Return


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} copyApont
@author rogerio.souza
@since 31/10/2013
@version 11.9
@param @param cCodTFJFrom, character, Codigo do orçamento de serviços
@description
Realiza a copia dos apontamento de materiais realizados no orçamento de serviços para a nova revisão com base nos campos TFL_CODSUB
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function copyApont(cCodTFJFrom)

Local oModel		:= Nil
Local oModelTo	:= NIl	
Local nI			:= 0
Local nLin			:= 0
Local oAuxTo		:= Nil
Local oAuxFrom	:= Nil		
Local cAliasQry	:= GetNextAlias()	
Local aArea		:= GetArea()
Local aAreaTFL	:= TFL->(GetArea())
Local oDlg		:= nil

BeginSQL Alias cAliasQry       
	SELECT  TFL_CODIGO, TFL_CODSUB
	FROM %Table:TFL% TFL		
WHERE 
	TFL.TFL_FILIAL = %xFilial:TFL% AND
	TFL.TFL_CODPAI = %Exp:cCodTFJFrom% AND		
	TFL.%notDel%	
EndSql

While (cAliasQry)->(!EOF())

	TFL->(DbSetOrder(1))//TFL_FILIAL+TFL_CODIGO
	If TFL->(DbSeek(xFilial("TFL")+(cAliasQry)->TFL_CODIGO))
		oModel := FwLoadModel("TECA890")	
		oModel:SetOperation(MODEL_OPERATION_VIEW)	
		oModel:Activate()					
	EndIf

	TFL->(DbSetOrder(1))
	If TFL->(DbSeek(xFilial("TFL")+(cAliasQry)->TFL_CODSUB))//Posiciona no TFL substituto
		oModelTo := FwLoadModel("TECA890")
		oModelTo:SetOperation(MODEL_OPERATION_UPDATE)
		oModelTo:Activate()

		oAuxFrom := oModel:GetModel("TFTGRID")
		oAuxTo := oModelTo:GetModel("TFTGRID")			
		
		If !(oAuxFrom:IsEmpty())
			nLin := oAuxFrom:Length()			
			For nI:=1 To nLin
				If nI > oAuxTo:Length()
					oAuxTo:AddLine()
				EndIf
				oAuxTo:GoLine( nI )
				oAuxFrom:GoLine( nI )
					
				If oModelTo:SetValue("TFTGRID","TFT_CODTFH",  GetTFHSubs(oAuxFrom:GetValue("TFT_CODTFH")) )//seta o codigo novo da TFH
					lRet := AtCpyData( oAuxFrom, @oAuxTo, {"TFL_CODIGO", "TFT_CODIGO", "TFT_CODTFH", "TFT_SIT"} )//realiza copia da linha do model
				EndIf
			Next nI		
		EndIf
		
		oAuxFrom := oModel:GetModel("TFSGRID")
		oAuxTo := oModelTo:GetModel("TFSGRID")			
		
		If !(oAuxFrom:IsEmpty())
			nLin := oAuxFrom:Length()			
			For nI:=1 To nLin
				If nI > oAuxTo:Length()
					oAuxTo:AddLine()
				EndIf
				oAuxTo:GoLine( nI )
				oAuxFrom:GoLine( nI )
					
				If oModelTo:SetValue("TFSGRID","TFS_CODTFG",  GetTFGSubs(oAuxFrom:GetValue("TFS_CODTFG")) )
					lRet := AtCpyData( oAuxFrom, @oAuxTo, {"TFL_CODIGO", "TFS_CODIGO", "TFS_CODTFG", "TFS_SIT"} )//realiza copia da linha do model
				EndIf
			Next nI	
		EndIf
		
		If oModelTo:VldData()		 	 			 
 			oModelTo:CommitData()
		EndIf							
	EndIf

	(cAliasQry)->(DbSkip())
EndDo

(cAliasQry)->(DbCloseArea())

RestArea(aAreaTFL)
RestArea(aArea)	
Return


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} GetTFHSubs
@author rogerio.souza
@since 31/10/2013
@version 11.9
@param cCodTFH, character, Codigo TFH 
@return cRet, codigo do registro substituto (TFH_CODSUB))
@description
Recupera TFH_CODSUB
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function GetTFHSubs(cCodTFH)

Local aArea	:= TFH->(GetArea())
Local cRet		:= ""
	
TFH->(DbSetOrder(1))//TFH_FILIAL+TFH_CODIGO
If TFH->(DbSeek(xFilial("TFH")+cCodTFH))
	cRet := TFH->TFH_CODSUB
EndIf
	
TFH->(RestArea(aArea))

Return cRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} GetTFGSubs
@author rogerio.souza
@since 31/10/2013
@version 11.9
@param cCodTFG, character, Codigo TFG 
@return cRet, codigo do registro substituto (TFG_CODSUB))
@description
Recupera TFG_CODSUB
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function GetTFGSubs(cCodTFG)

Local aArea	:= TFG->(GetArea())
Local cRet		:= ""
	
TFG->(DbSetOrder(1))//TFG_FILIAL+TFG_CODIGO
If TFG->(DbSeek(xFilial("TFG")+cCodTFG))
	cRet := TFG->TFG_CODSUB
EndIf
	
TFG->(RestArea(aArea))

Return cRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} atuItPL
@author rogerio.souza
@since 31/10/2013
@version 1.0
@param cContra, character, Numero do contrato
@param cOldRevisa, character, Codigo da revisão anterior
@param cNewRevisa, character, Codigo da nova revisão
@param cPlan, character, Codigo da planilha
@param aItens, array, Relação de itens da planilha que serão verificados os seus substitutos
@return aRet, Estrutura com codigos dos itens substituidos baseados no parametro aItens
@description
Recupera relação de itens da planilha que foram criados devido a nova revisão de realinhamento do contrato
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function atuItPL(cContra, cOldRevisa, cNewRevisa, cPlan, aItens)

Local aRet			:= {}//Array com substitutos do aitens
Local aArea		:= CNB->(GetArea())
Local nQtdNewItem	:= 0//itens novos
Local nTotIt		:= 0//Total de itens
Local cItem		:= ""
Local aAntXNovos	:= {}//relação item Anterior vs Novo
Local nI			:= 1
Local nPos			:= 0	
		
//Verifica quantidade de itens da planilha que serão criados para a proxima revisão
CNB->(DbSetOrder(1))//CNB_FILIAL+CNB_CONTRA+CNB_REVISA+CNB_NUMERO+CNB_ITEM
CNB->(DbSeek(xFilial("CNB")+cContra+cOldRevisa+cPlan))
While CNB->(!EOF()) .AND. cContra == CNB->CNB_CONTRA .AND. cOldRevisa == CNB->CNB_REVISA .AND. cPlan == CNB->CNB_NUMERO 
	If CNB->CNB_QTDMED > 0 .AND. CNB->CNB_SLDMED > 0
			aAdd(aAntXNovos, {CNB->CNB_ITEM, CNB->CNB_ITEM})//cria estrutura para identificar item novo
		nQtdNewItem++
	EndIf
		
	nTotIt++	
	CNB->(DbSkip())	
EndDo
	
cItem := StrZero(nTotIt+1, TamSx3("CNB_ITEM")[1])
	
CNB->(DbSeek(xFilial("CNB")+cContra+cNewRevisa+cPlan+cItem))
While CNB->(!EOF()) .AND. cContra == CNB->CNB_CONTRA .AND. cNewRevisa == CNB->CNB_REVISA .AND. cPlan == CNB->CNB_NUMERO 
	If Len(aAntXNovos) >= nI
		aAntXNovos[nI][2] := CNB->CNB_ITEM
		nI++
	EndIf
	CNB->(DbSkip())	
EndDo
	
aRet := aClone(aItens)
	
For nI:=1 To Len(aAntXNovos)
	nPos:=aScan(aRet, {|x| x == aAntXNovos[nI][1]})
	If nPos > 0
		aRet[nPos] := aAntXNovos[nI][2] // sobrescreve item antigo pelo item novo de acordo com itens passados por parametro
	EndIf		
Next		
	
CNB->(RestArea(aArea))
Return aRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ExistRev
@author rogerio.souza
@since 31/10/2013
@version 11.9
@param cCodTFJ, character, (Codigo do orçamento de serviços)
@return lRet
@description
verifica se já existe revisão em aberto para a proposta
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ExistRev(cCodTFJ)

Local lRet		:= .F.
Local aArea	:= TFJ->(GetArea("TFJ"))
Local cChav	:= ""
	
TFJ->(DbSetOrder(1))//TFJ_FILIAL+TFJ_CODIGO
If TFJ->(DbSeek(xFilial("TFJ")+cCodTFJ))
	cChav := xFilial("TFJ") + DEF_TFJ_EMREVISAO + TFJ->TFJ_PROPOS + TFJ->TFJ_PREVIS

	TFJ->( DbSetOrder( 4 ) ) //TFJ_FILIAL+TFJ_STATUS+TFJ_PROPOS+TFJ_PREVIS
	If TFJ->(DbSeek(cChav))
		lRet := .T.
	EndIf	
EndIf

TFJ->(RestArea(aArea))
Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT870Legen
@author rogerio.souza
@since 17/10/2013
@version 11.9
@description
Aprensentação das Legendas disponiveis
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function AT870Legen()

Local oLegenda	:= FWLegend():New()
	
oLegenda:Add( "", "BR_VERDE",    STR0007 )		//"Ativo"
oLegenda:Add( "", "BR_BRANCO",   STR0040 )	 	//"Revisado"
oLegenda:Add( "", "BR_AMARELO",  STR0008 )		//"Em revisão"
oLegenda:Add( "", "BR_PINK",     STR0041 )		//"Aguardando aprovação"
oLegenda:Add( "", "BR_VERMELHO", STR0030 )		//"Contrato em elaboração no SIGAGCT"
oLegenda:Add( "", "BR_VIOLETA",  STR0150 )		//"Contrato emitido no SIGAGCT"
oLegenda:Add( "", "BR_LARANJA",  STR0151 )		//"Contrato em aprovação no SIGAGCT"
oLegenda:Add( "", "BR_AZUL",     STR0070 )		//"Contrato Encerrado" 
oLegenda:Add( "", "BR_PRETO",    STR0080 )		//"Cancelado" 
	
oLegenda:Activate()
oLegenda:View()
oLegenda:DeActivate()

Return Nil


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870Aloca
@author rogerio.souza
@since 17/10/2013
@version 11.9
@param cNrContrat, cNrOrcSrv, cAliasPro
@return lRet, Retorno logico
@description
Realiza consistencias e chama tela de alocação de atendentes
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At870Aloca(cNrContrat,cRevis ,cNrOrcSrv, cAliasPro)

Local lRet		:= .F.
Local aArea	:= GetArea()

DbSelectArea("CN9")
DbSetOrder(1)
If CN9->(DbSeek(xFilial("CN9")+cNrContrat+cRevis))
	If CN9->CN9_SITUAC == DEF_SVIGE	//01=Cancelado;02=Elaboracao;03=Emitido;04=Aprovacao;05=Vigente;06=Paralisa.;07=Sol. Finalizacao;08=Finalizado;09=Revisao;10=Revisado
		If (cAliasPro)->TFJ_STATUS == DEF_TFJ_ATIVO
			lRet := TECA330(cNrContrat, cNrOrcSrv)
		Elseif (cAliasPro)->TFJ_STATUS == DEF_TFJ_ENCERRADO
			Help( ' ', 1, "At870Aloca", , STR0071, 1, 0 )	//"Contrato Encerrado" 
		Else
			Help( ' ', 1, "At870Aloca", , STR0009, 1, 0 )	//"Não é possivel realizar alocação para itens em revisão"
		EndIf
	Else
		If	CN9->CN9_SITUAC == DEF_SCANC	//01=Cancelado;02=Elaboracao;03=Emitido;04=Aprovacao;05=Vigente;06=Paralisa.;07=Sol. Finalizacao;08=Finalizado;09=Revisao;10=Revisado
			Help( ' ', 1, "At870Aloca", , STR0088, 1, 0 )	//"Não é possivel realizar alocação para contratos cancelados"
		ElseIf	CN9->CN9_SITUAC == DEF_SFINA
			Help( ' ', 1, "At870Aloca", , STR0097, 1, 0)	//"Não é possivel realizar alocação para contratos encerrados"
		Else
			Help( ' ', 1, "At870Aloca", , STR0032, 1, 0 )	//"Não é possivel realizar alocação para contratos ainda em elaboração, para tornar o contrato vigente acesse o modulo SIGAGCT e realize as operações necessárias!"
		EndIf	
	EndIf
Else
	If (cAliasPro)->TFJ_STATUS == DEF_TFJ_ATIVO
		lRet := TECA330(cNrContrat, cNrOrcSrv)
	Else
		Help( ' ', 1, "At870Aloca", , STR0009, 1, 0 )	//"Não é possivel realizar alocação para itens em revisão"
	EndIf
EndIf
RestArea(aArea)
Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870View
@author rogerio.souza
@since 12/11/2013
@version 11.9
@param cCodTFJ, character
@description
Apresenta visualização do orçamento de serviço.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At870View(cCodTFJ)	

Local aArea 	:= TFJ->(GetArea())
Local oModel 	:= Nil
Local lRet 	:= .F.
Local lOrcPrc	:= SuperGetMv("MV_ORCPRC",,.F.)
Local cOrcMod	:= If( lOrcPrc, "TECA740F", "TECA740" )

TFJ->(DbSetOrder(1))//TFJ_FILIAL+TFJ_CODIGO
If TFJ->(DbSeek(xFilial("TFJ")+cCodTFJ))

	If lOrcPrc
		At600STabPrc( TFJ->TFJ_CODTAB, TFJ->TFJ_TABREV )
	EndIf

	At740FMsg( .F. ) // Desabilita as mensagens de erro
	At740SLoad( Nil )			
	FWExecView(STR0017,"VIEWDEF."+cOrcMod, MODEL_OPERATION_VIEW, /*oDlg*/, {||.T.} /*bCloseOk*/, {||.T.}/*bOk*/,/*nPercRed*/,/*aButtons*/, {||.T.}/*bCancel*/ )

	At600STabPrc( '', '' )

Else
	Help( ' ', 1, "TECA870", , STR0018, 1, 0 )	//"Orçamento de Serviços não encontrado"
EndIf

TFJ->(RestArea(aArea))
Return 


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870AlAut
@since 09/01/2014
@version 11.9
@param cNumContr, cNumOrcS, cAliasPro
@return lRet, Retorno logico
@description
Realiza consistencias e chama tela de alocação automatica
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At870AlAut(cNumContr, cNumOrcS, cAliasPro)

Local lRet		:= .F.

If (cAliasPro)->TFJ_STATUS == DEF_TFJ_ATIVO
	lRet := TECA331(cNumContr, cNumOrcS)
Elseif (cAliasPro)->TFJ_STATUS == DEF_TFJ_ENCERRADO
	Help( ' ', 1, "At870AlAut", , STR0097, 1, 0)	//"Não é possivel realizar alocação para contratos encerrados"
Elseif (cAliasPro)->TFJ_STATUS == DEF_TFJ_CANCELADO
	Help( ' ', 1, "At870AlAut", , STR0091, 1, 0 )	//"Não é possivel realizar alocação para contratos cancelados" 
Else
	Help( ' ', 1, "At870AlAut", , STR0009, 1, 0 )	//"Não é possivel realizar alocação para itens em revisão"
EndIf

Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870VldCN0
@author rogerio.souza
@since 18/10/2013
@version 1.0
@param cCod, character
@param cDesc, character - atualiza descrição do tipo de revisão por referencia
@return lRet, Boolean
@description
Valida tipo de revisão
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At870VldCN0(cCod, cDesc, lNoHelp)

Local lRet		:= .T.
Local aArea	:= GetArea("CN0")
Default lNoHelp := .F.
CN0->(DbSetOrder(1))//CN0_FILIAL+CN0_CODIGO
If CN0->(DbSeek(xFilial("CN0")+cCod))
	If CN0->CN0_TIPO!='F'
		//A partir do Release 15, apenas o novo tipo de revisao "Orcamento Servicos" é aceitavel para
		//as revisoes do SIGATEC
		lRet := .F.
		If lNoHelp
			AutoGrLog( "At870VldCN0" + " / " + STR0012 )	//"Orçamento de serviço não informado"
		Else
		Help( ' ', 1, "At870VldCN0", , STR0012, 1, 0 )	//"Tipo de revisão inválido"
		Endif
	EndIf
Else
	lRet := .F.
	If lNoHelp
		AutoGrLog( "At870VldCN0" + " / " + STR0013 )	//"Orçamento de serviço não informado"
	Else
		Help( ' ', 1, "At870VldCN0", , STR0013, 1, 0 )	//"Tipo de revisão não encontrado"
	EndIf
EndIf	

If lRet .AND. ValType(cDesc) == "C"
	cDesc := CN0->CN0_DESCRI
EndIf

CN0->(RestArea(aArea))
Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870VldInfo
@author rogerio.souza
@since 18/10/2013
@version 11.9
@param cCodTr, character, Código do tipo de revisão
@param cCodDes, character, Descrição do tipo de revisão, é realizada a atualização por referencia
@return lRet, Verdadeiro caso campos estejam OK
@description
Realiza validação das informações parageração de revisão a partir do gestão de contratos
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At870VldInfo(cCodTr)

Return At870VldCN0(cCodTr)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870VldTFJ
@version 11.9
@param cCodTFJ, character, Código do Orçamento de Serviços
@return lRet, Verdadeiro caso campos estejam OK
@description
Realiza validação geral da TFJ
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At870VldTFJ(cCodTFJ, lNoHelp)

Local	lRet	:= .T.

If Empty(cCodTFJ)
	lRet := .F.
	If lNoHelp
		AutoGrLog( "At870VldTFJ_1" + " / " + STR0020 )	//"Orçamento de serviço não informado"
	Else
		Help( ' ', 1, "At870VldTFJ_1", , STR0020, 1, 0 )	//"Orçamento de serviço não informado"
	EndIf
ElseIf !isIntegGCT(cCodTfj)//verifica proposta com tipo de contrato integrado ao GCT
	lRet := .F.
	If lNoHelp
		AutoGrLog( "At870VldTFJ_2" + " / " + STR0014 )	//"Realização de revisões permitida somente para itens integrado ao GCT"
	Else
		Help( ' ', 1, "At870VldTFJ_2", , STR0014, 1, 0 )	//"Realização de revisões permitida somente para itens integrado ao GCT"
	EndIf
ElseIf hasNewRev(cCodTFJ)//verifica proposta com tipo de contrato integrado ao GCT
	lRet := .F.
	If lNoHelp
		AutoGrLog( "At870VldTFJ_3" + " / " + STR0024 )	//"Não é possivel gerar a revisão. Existe uma revisão em aberto para o contrato no Gestão de Contratos."
	Else
		Help( ' ', 1, "At870VldTFJ_3", , STR0024, 1, 0 )	//"Não é possivel gerar a revisão. Existe uma revisão em aberto para o contrato no Gestão de Contratos."
	EndIf
Else 
	TFJ->(DbSetOrder(1))//TFJ_FILIAL+TFJ_CODIGO
	If TFJ->(DbSeek(xFilial("TFJ")+cCodTFJ))
		If 	TFJ->TFJ_STATUS == DEF_TFJ_CANCELADO
			lRet := .F.
			If lNoHelp
				AutoGrLog( "At870VldTFJ_4" + " / " + STR0090 )	//"O orçamento de serviços encontra-se cancelado"
			Else
				Help( ' ', 1, "At870VldTFJ_4", , STR0090, 1, 0 )	//"O orçamento de serviços encontra-se cancelado"
			EndIf
		ElseIf TFJ->TFJ_STATUS == DEF_TFJ_ENCERRADO
			lRet := .F.
			If lNoHelp
				AutoGrLog( "At870VldTFJ_5" + " / " + STR0085 )	//"O orçamento de serviços já encontra-se encerrado."
			Else
				Help( ' ', 1, "At870VldTFJ_5", , STR0085, 1, 0)	//"O orçamento de serviços já encontra-se encerrado."
			EndIf
		ElseIf	TFJ->TFJ_STATUS == DEF_TFJ_AGDAPROVA
			lRet := .F.
			If lNoHelp
				AutoGrLog( "At870VldTFJ_7" + " / " + STR0019 )	//"Já existe revisão em aberto para o orçamento de serviços"
			Else
				Help( ' ', 1, "At870VldTFJ_7", , STR0019, 1, 0 )	//"Já existe revisão em aberto para o orçamento de serviços"
			EndIf
		ElseIf	TFJ->TFJ_STATUS != DEF_TFJ_EMREVISAO
			If ExistRev(cCodTfj)
				lRet := .F.
				If lNoHelp
					AutoGrLog( "At870VldTFJ_6" + " / " + STR0019 )	//"Já existe revisão em aberto para o orçamento de serviços"
				Else
					Help( ' ', 1, "At870VldTFJ_6", , STR0019, 1, 0 )	//"Já existe revisão em aberto para o orçamento de serviços"
				EndIf
			EndIf
		EndIf	
	EndIf
EndIf

Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} isIntegGCT
@author rogerio.souza
@since 18/10/2013
@version 11.9
@param cCodTFJ, character
@return lRet, indica se o registro da proposta é integrado ao Gestão de Contratos (GCT)
@description
Verifica se a proposta da TFJ utiliza integração com gestão de Contratos.
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function isIntegGCT(cCodTFJ)
Local lRet			:= .F.
Local cAliasQry	:= GetNextAlias()

BeginSQL Alias cAliasQry       
	SELECT  ADY_TPCONT 
		FROM %Table:ADY% ADY		
	INNER JOIN %Table:TFJ% TFJ ON
		TFJ.TFJ_FILIAL = ADY.ADY_FILIAL AND
		TFJ.TFJ_PROPOS = ADY.ADY_PROPOS AND
		TFJ.TFJ_PREVIS = ADY.ADY_PREVIS AND
		TFJ.TFJ_CODIGO = %Exp:cCodTFJ% AND
		TFJ.%notDel%
	WHERE 
		ADY.ADY_FILIAL = %xFilial:ADY% AND
		ADY.%notDel%	
EndSql 

If (cAliasQry)->(!EOF()) .AND. (cAliasQry)->(ADY_TPCONT) == '4'//Contrato integrado GCT 
	lRet := .T.
EndIf

(cAliasQry)->(DbCloseArea())

Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} hasNewRev
@author rogerio.souza
@since 31/10/2013
@version 1.0
@param cCodTFJ, character, (DescriÃ§Ã£o do parÃ¢metro)
@return lRet
@description
verifica se já existe uma nova revisão no GCT 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function hasNewRev(cCodTFJ)
Local lRet			:= .F.
Local cAliasQry	:= GetNextAlias()

BeginSQL Alias cAliasQry       
	SELECT 
		CN9.CN9_REVATU 
	
	FROM %Table:TFJ% TFJ

	INNER JOIN %Table:CN9% CN9 ON	
		CN9.CN9_FILIAL = %xFilial:CN9% AND
		CN9.CN9_NUMERO = TFJ.TFJ_CONTRT AND
		CN9.CN9_REVISA = TFJ.TFJ_CONREV AND
		CN9.CN9_SITUAC NOT IN ('01', '08') AND
		CN9.%notDel%
		
	WHERE 
		TFJ.TFJ_FILIAL = %xFilial:TFJ% AND
		TFJ.TFJ_CODIGO = %Exp:cCodTFJ% AND
		TFJ.%notDel%
EndSql 

If (cAliasQry)->(!EOF()) .AND. !Empty((cAliasQry)->CN9_REVATU) 
	lRet := .T.
EndIf

(cAliasQry)->(DbCloseArea())

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At870AtuBrw
@author rogerio.souza
@since 31/10/2013
@version 11.9
@param oBrowse, objeto, (Browser a ser atualizado)
@description
Atualiza browse
/*/
//-------------------------------------------------------------------
Static Function At870AtuBrw(oBrowse)

Local cAlias	:= oBrowse:Alias()

If Select(cAlias) > 0
	(cAlias)->(dbCloseArea())
EndIf

oBrowse:SetDataQuery(.T.)
oBrowse:SetQuery(At870Query())
oBrowse:SetAlias( cAlias )
oBrowse:Refresh(.T.)     
oBrowse:OnChange()
Return 

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewErroMvc
@sample        ViewErroMvc( oObjMdl )
@param         oObjMdl, Objeto, Objeto Model
@return        NIL
@author        rogerio.souza
@version       11.9
@description 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ViewErroMvc( oObjMdl, lExibeErro )

Local aErro	:= {}
Default lExibeErro := .F.

aErro := oObjMdl:GetErrorMessage()

If Len(aErro) > 0
	AutoGrLog( '[' + AllToChar( aErro[MODEL_MSGERR_IDFORMERR] ) + ']' )
	AutoGrLog( '[' + AllToChar( aErro[MODEL_MSGERR_IDFIELDERR] ) + ']' )
	AutoGrLog( '[' + AllToChar( aErro[MODEL_MSGERR_ID] ) + ']' )
	AutoGrLog( '[' + AllToChar( aErro[MODEL_MSGERR_MESSAGE] ) + '|' + AllToChar( aErro[MODEL_MSGERR_SOLUCTION] ) + ']' )
	
	If lExibeErro
		MostraErro()
	EndIf
EndIf
Return 

//-------------------------------------------------------------------
/*/{Protheus.doc} At870Contr
@since 02/01/2014
@version 11.9
@param Status do contrato, contrato e revisão
@description
Atualiza browse
/*/
//-------------------------------------------------------------------
Function At870Contr(cStatus,cCont,cRevis)
Local cColor	:= "BR_AMARELO"
Local aArea	:= GetArea()

DbSelectArea("CN9")
DbSetOrder(1)
If CN9->(DbSeek(xFilial("CN9")+cCont+cRevis))
	If CN9->CN9_SITUAC == DEF_SELAB			//01=Cancelado;02=Elaboracao;03=Emitido;04=Aprovacao;05=Vigente;06=Paralisa.;07=Sol. Finalizacao;08=Finalizado;09=Revisao;10=Revisado
		cColor	:=	"BR_VERMELHO"
	ElseIf CN9->CN9_SITUAC == DEF_SEMIT	//01=Cancelado;02=Elaboracao;03=Emitido;04=Aprovacao;05=Vigente;06=Paralisa.;07=Sol. Finalizacao;08=Finalizado;09=Revisao;10=Revisado
		cColor	:=	"BR_VIOLETA"
	ElseIf CN9->CN9_SITUAC == DEF_SAPRO	//01=Cancelado;02=Elaboracao;03=Emitido;04=Aprovacao;05=Vigente;06=Paralisa.;07=Sol. Finalizacao;08=Finalizado;09=Revisao;10=Revisado
		cColor	:=	"BR_LARANJA"
	ElseIf CN9->CN9_SITUAC == DEF_SREVS	//01=Cancelado;02=Elaboracao;03=Emitido;04=Aprovacao;05=Vigente;06=Paralisa.;07=Sol. Finalizacao;08=Finalizado;09=Revisao;10=Revisado
		cColor	:=	"BR_PINK"
	ElseIf CN9->CN9_SITUAC == DEF_SSPAR	//01=Cancelado;02=Elaboracao;03=Emitido;04=Aprovacao;05=Vigente;06=Paralisa.;07=Sol. Finalizacao;08=Finalizado;09=Revisao;10=Revisado
		cColor	:=	"BR_MARROM"
	ElseIf cStatus == DEF_TFJ_ATIVO
		cColor	:=	"BR_VERDE"
	ElseIf cStatus == DEF_TFJ_REVISADO
		cColor := "BR_BRANCO"
	ElseIf cStatus == DEF_TFJ_ENCERRADO
		cColor := "BR_AZUL"
	ElseIf cStatus == DEF_TFJ_CANCELADO
		cColor := "BR_PRETO"
	Else
		cColor	:=	"BR_AMARELO"
	EndIf
ElseIf cStatus == DEF_TFJ_ATIVO
	cColor	:=	"BR_VERDE"
ElseIf cStatus == DEF_TFJ_REVISADO
	cColor := "BR_BRANCO"
ElseIf cStatus == DEF_TFJ_AGDAPROVA
	cColor := "BR_PINK"
Elseif	cStatus == DEF_TFJ_ENCERRADO
	cColor := "BR_AZUL"
ElseIf cStatus == DEF_TFJ_CANCELADO
	cColor := "BR_PRETO"
Else		
	cColor	:=	"BR_AMARELO"
EndIf
RestArea(aArea)
Return cColor


//-------------------------------------------------------------------
/*/{Protheus.doc} At870GerOrc
Consiste o contrato para a geração dos itens extras.
@sample 	At870GerOrc( nOperacao, oModel )
@param		cOrcServico	Orçamento de serviços utilizado para referencia
							dos itens extra para o contrato.
@author	Serviços
@since		17/04/2014
@version	P12
/*/
//-------------------------------------------------------------------
Function At870GerOrc( cOrcServico, cAliasPro )

Local lRet			:= .T.					// Retorno da validacao.
Local lConfirm	:= .T.
Local aArea		:= GetArea()
Local lOrcPrc		:= SuperGetMv("MV_ORCPRC",,.F.)
Local cOrcMod		:= If( lOrcPrc, "TECA740F", "TECA740" )
Local oOrcServico

If (cAliasPro)->TFJ_STATUS == DEF_TFJ_ENCERRADO
	Help( ' ', 1, "At870GerOrc", , STR0073, 1, 0 )	//"Contrato Encerrado" 
ElseIf (cAliasPro)->TFJ_STATUS == DEF_TFJ_CANCELADO
	Help( ' ', 1, "At870GerOrc", , STR0090, 1, 0 )	//"O orçamento de serviços encontra-se cancelado"
ElseIf !lOrcPrc .AND. !(At870VldItEx(cOrcServico))
	Help( ' ', 1, "At870GerOrc", , STR0152, 1, 0 )//#"Nesse contrato não foi gerado itens de RH, Por isso Não é Possivel fazer a inclusão de Itens Extra" 
Else
	dbSelectArea("TFJ")
	TFJ->(dbSetOrder(1))
	
	lRet := TFJ->(dbSeek(xFilial("TFJ")+cOrcServico))
	
	If lRet
	
		At740FMsg( .F. ) // Desabilita as mensagens de erro
		
		oOrcServico := FwLoadModel(cOrcMod)
			
		oOrcServico:SetOperation( MODEL_OPERATION_UPDATE )
		lRet := oOrcServico:Activate()		
		
		If lRet
		
			At740SLoad( oOrcServico ) 	// atribui o model com o conteúdo copiado para carga na view da rotina
			At740SCmt( .T. )				// habilita commit
			At740FMsg( .T. )				// Habilita as mensagens de erro
			
			lRet := ( FWExecView( STR0017, "VIEWDEF." + cOrcMod, MODEL_OPERATION_UPDATE, /*oDlg*/, {||.T.} /*bCloseOk*/, ;  // 'Orçamento Serviços'
									{||.T.}/*bOk*/,/*nPercRed*/,/*aButtons*/, {||.T.}/*bCancel*/ ) == 0 )
	
			At740SLoad( Nil )								
			At740SCmt( .F. )
			At740FMsg( .F. )		
									
		Else
			ViewErroMvc( oOrcServico )
		EndIf	
		
	Else
		Help(,,"AT870ORC",,STR0058,1,0) // "Orçamento de serviços invalido/inexistente para essa operação!"	 
	EndIf
Endif
RestArea(aArea)

Return( lRet )

//-------------------------------------------------------------------
/*/{Protheus.doc} At870VldItEx
Validação para Verificar se Existe RH quando Não for Utilizado tabela de Precificação

@sample 	At870VldItEx( cOrcServico )
@param		cOrcServico,Caractere,	Orçamento de serviços utilizado para referencia
									dos itens extra para o contrato.
@return		lRet, logico, .T. OK, .F. Não OK 								

@author		Joni.Carmo
@since		24/08/2016
@version	P12
/*/
//-------------------------------------------------------------------
Static Function At870VldItEx(cOrcServico)
	
	Local aArea 	:= GetArea()
	
	Local lRet  	:= .F.
	Local lOrcPrc	:= SuperGetMv("MV_ORCPRC",,.F.)
	
	Local cAlias    := GetNextAlias()
	
	If !lOrcPrc //Caso não utilize Tabela de Precificação
		
		BeginSql Alias cAlias
			
			SELECT
				TFF_COD
			
			FROM %Table:TFJ% TFJ
			
			INNER JOIN %Table:TFL% TFL
				 ON TFL_FILIAL = %xFilial:TFL%
				AND TFL_CODPAI = TFJ_CODIGO
			
			INNER JOIN %Table:TFF% TFF
				 ON TFF_FILIAL = %xFilial:TFF%
				AND TFF_CODPAI = TFL_CODIGO
			
			WHERE
				TFJ_FILIAL = %xFilial:TFJ% AND
				TFJ_CODIGO = %Exp:cOrcServico% AND
				TFJ.%NotDel% AND
				TFL.%NotDel% AND
				TFF.%NotDel%
			
		EndSql
		
		(cAlias)->(dbGoTop())
		
		While !(cAlias)->(Eof())
			
			lRet := .T.
			
			If lRet
				exit
			EndIf
			
			(cAlias)->(DbSkip())
			
		EndDo
		
		(cAlias)->(DbCloseArea())
		
	EndIf
	
	RestArea(aArea)
	
Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870ExcR
@since 17/04/2014
@version 12
@param cStatus, character status do contrato
@param cCodTFJ, character código do orçamento de serviços
@description
Realiza processo de exclusão da revisão do contrato
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At870ExcR(cStatus,cCodTFJ)

Local lRet		:= .F.
Local lOrcPrc 	:= SuperGetMv("MV_ORCPRC",, .F.)
Local cModLoad 	:= If( lOrcPrc, "TECA740F", "TECA740" )
Local oModel 	:= Nil

If cStatus == DEF_TFJ_EMREVISAO .AND. !hasNewRev(cCodTFJ)
	DbSelectArea("TFJ")
	DbSetOrder(1) //TFJ_FILIAL+TFJ_CODIGO
	If DbSeek(xFilial("TFJ")+cCodTFJ)
		If MsgYesNo(STR0042) //"Deseja excluir essa revisão?"

			oModel := FwLoadModel( cModLoad )
			oModel:SetOperation( MODEL_OPERATION_DELETE )
			lRet := oModel:Activate()
			// habilita a gravação dos dados do orçamento de serviços no banco
			At740SCmt( .T. )
			lRet := lRet .And. oModel:VldData() .And. oModel:CommitData()
			At740SCmt( .F. )

			If lRet
				At870RemSub( cCodTFJ, lOrcPrc )
			ElseIf oModel:HasErrorMessage()
				AtErroMvc( oModel )
				MostraErro()
			Else
				Help( ' ', 1, 'At870ExcR', ,STR0173, 1, 0 )  // "Não foi possível excluir o orçamento da revisão do contrato"
			Endif

			If lRet .And. !Empty(TFJ->TFJ_GRPCOM)

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³SIGATEC WorkFlow # CT - Interações de Contratos Exclusão da Revisão ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				At774Mail("TFJ",TFJ->TFJ_GRPCOM,"CT","<b>"+STR0106+"</b> "+TFJ->TFJ_PROPOS+"<b> "+STR0107+"</b>"+TFJ->TFJ_CONTRT,"RED",STR0111) //"Num. Proposta: " # "Nr. Contrato: " # "Exclusão da Revisão"
			Endif	
		EndIf
	EndIf	
Elseif cStatus == DEF_TFJ_ENCERRADO
	Help( ' ', 1, 'At870ExcR', ,STR0074, 1, 0 )	//"Contrato encerrado, não é permitida a sua exclusão"	
Elseif cStatus == DEF_TFJ_CANCELADO
	Help( ' ', 1, 'At870ExcR', ,STR0092, 1, 0 )	//"Contrato cancelado, não é permitida a sua exclusão"	
Else
	Help( ' ', 1, 'At870ExcR', ,STR0043, 1, 0 )	//"Só é possível excluir orçamento 'em revisão' e que não esteja com a revisão em andamento."	
EndIf

Return lRet

/*/{Protheus.doc} At870RemSub
	Realiza processo de exclusão da revisão do contrato dos itens que ficaram com códigos de substituto
@since 30/11/2016
@version 12
@param cCodTFJ, character, código do orçamento de serviços
@param lOrcPrc, Lógico, determina se é ou não orçamento com precificação
/*/
Static Function At870RemSub( cCodTFJ, lOrcPrc )
Local cCodTFJAnt 	:= ""
Local cQry := GetNextAlias()
Local cFilTFL := xFilial("TFL")
Local cFilTFF := xFilial("TFF")
Local cFilTFI := xFilial("TFI")

BeginSQL Alias cQry
	SELECT DISTINCT TFJ_CODIGO
	FROM %Table:TFL% TFLREV
		INNER JOIN %Table:TFL% TFLANT ON TFLANT.TFL_FILIAL = %xFilial:TFL%
								AND TFLANT.TFL_CODSUB = TFLREV.TFL_CODIGO
								AND TFLANT.%NotDel%
		INNER JOIN %Table:TFJ% TFJ ON TFJ_FILIAL = %xFilial:TFJ%
								AND TFJ_CODIGO = TFLANT.TFL_CODPAI
								AND TFJ.%NotDel%
	WHERE TFLREV.TFL_FILIAL=%xFilial:TFL%
		AND TFLREV.TFL_CODPAI = %Exp:cCodTFJ%
		AND TFLREV.%NotDel%
EndSQL

If (cQry)->(!EOF())

	DbSelectArea("TFJ")
	TFJ->( DbGoTo( (cQry)->TFJRECNO ) )
	cCodTFJAnt := TFJ->TFJ_CODIGO

	(cQry)->(DbCloseArea())

	DbSelectArea("TFL")
	TFL->(DbSetOrder( 2 )) // TFL_FILIAL + TFL_CODPAI
	DbSelectArea("TFF")
	TFF->(DbSetOrder( 3 )) // TFF_FILIAL + TFF_CODPAI
	DbSelectArea("TFI")
	TFI->(DbSetOrder( 3 )) // TFF_FILIAL + TFF_CODPAI
	DbSelectArea("TFG")
	TFG->(DbSetOrder( 3 )) // TFF_FILIAL + TFF_CODPAI
	DbSelectArea("TFH")
	TFH->(DbSetOrder( 3 )) // TFF_FILIAL + TFF_CODPAI

	TFL->( DbSeek( cFilTFL + cCodTFJAnt ) )

	While TFL->(!EOF()) .And. TFL->TFL_FILIAL == cFilTFL .And. TFL->TFL_CODPAI == cCodTFJAnt
		// percorrer os itens de recursos humanos para remover a marcaçao de item destino substituto em função da revisão
		TFF->( DbSeek( cFilTFF + TFL->TFL_CODIGO ) )
		While TFF->(!EOF()) .And. TFF_FILIAL == cFilTFF .And. TFF->TFF_CODPAI == TFL->TFL_CODIGO
			Reclock("TFF", .F.)
				TFF->TFF_CODSUB := ""
			TFF->(MsUnclok())

			If !lOrcPrc
				At870RemMats( lOrcPrc )
			EndIf
		End

		If lOrcPrc
			At870RemMats( lOrcPrc )
		EndIf

		// percorrer os itens de locação de equipamentos para remover a marcaçao de item destino substituto em função da revisão
		TFI->( DbSeek( cFilTFI + TFL->TFL_CODIGO ) )
		While TFI->(!EOF()) .And. TFI_FILIAL == cFilTFI .And. TFI->TFI_CODPAI == TFL->TFL_CODIGO
			Reclock("TFI", .F.)
				TFI->TFI_CODSUB := ""
			TFI->(MsUnclok())
		End

		TFL->(DbSkip())
	End

EndIf

Return

/*/{Protheus.doc} At870RemMats
	Realiza processo de exclusão da revisão do contrato dos itens de materiais que ficaram com códigos de substituto
@since 30/11/2016
@version 12
@param lOrcPrc, Lógico, determina se é ou não orçamento com precificação
/*/
Static Function At870RemMats( lOrcPrc )
Local cFilTFG := xFilial("TFG")
Local cFilTFH := xFilial("TFH")
Local cCodSup := If( lOrcPrc, TFL->TFL_CODIGO, TFF->TFF_COD )

// indicação do índice já aconteceu na função anterior
TFG->( DbSeek(cFilTFG + cCodSup ) )
While TFG->(!EOF()) .And. TFG->TFG_FILIAL == cFilTFG .And. TFG->TFG_CODPAI == cCodSup

	Reclock("TFG", .F.)
		TFG->TFG_CODSUB := ""
	TFG->(MsUnlock())

	TFG->( DbSkip() )
End

// indicação do índice já aconteceu na função anterior
TFH->( DbSeek(cFilTFH + cCodSup ) )
While TFH->(!EOF()) .And. TFH->TFH_FILIAL == cFilTFH .And. TFH->TFH_CODPAI == cCodSup

	Reclock("TFH", .F.)
		TFH->TFH_CODSUB := ""
	TFH->(MsUnlock())

	TFH->( DbSkip() )
End

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870VlEfR
@since 17/04/2014
@version 12
@param cStatus, character status do contrato
@description
Realiza processo de efetivação da revisão
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At870VlEfR(cStatus,cCodTFJ,cTpRev,oBrowse)

Local lRet		:= .T.

cTp := At870TpCont(cTpRev)

If cStatus == "2"	
	MsgRun ( STR0029, STR0004, {|| At870EftRv(cCodTfj,cTpRev,cTp ) } ) // 'Processando revisão...' ### "Aguarde..."
	At870AtuBrw(oBrowse)
Else
	lRet := .F.
	Help( ' ', 1, 'At870VlEfR', ,STR0044, 1, 0 )	//"Somente Orçamento de serviço que esteja 'EM REVISÃO' poderá ser efetivado"	
EndIf

Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870TpCont
@since 17/04/2014
@version 12
@param cCodTr, character Código do Tipo de revisão
@description
Busca o Tipo de revisão
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At870TpCont(cCodTr)

Local aAreaCN0	:= GetArea()
Local cTp			:= ""

DbSelectArea("CN0")
CN0->(DbSetOrder(1))//CN0_FILIAL+CN0_CODIGO
If CN0->(DbSeek(xFilial("CN0")+cCodTr))
	cTp := CN0->CN0_TIPO
EndIf	

RestArea(aAreaCN0)

Return cTp

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870Nwl
@since 17/04/2014
@version 12
@param cModel, character Modelo
@description
Validação da nova linha no orçamento de serviços
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At870Nwl(cModel)
Local lRet		:= .T.	
Local oModel	:= FWModelActive()
Local oGrid		:= oModel:GetModel(cModel)	
Local cContr	:= oModel:GetModel('TFJ_REFER'):GetValue("TFJ_CONTRT")
Local cRev		:= oModel:GetModel('TFJ_REFER'):GetValue("TFJ_CONREV")		
Local cCodCli 	:= ""
Local cLojCli 	:= ""

If At850GetCli( @cCodCli, @cLojCli, oGrid:GetValue("TFL_LOCAL"), "1" )
				DbSelectArea("CNC")
				DbSetOrder(3) //CNC_FILIAL+CNC_NUMERO+CNC_REVISA+CNC_CLIENT+CNC_LOJACL
	If CNC->(!DbSeek(xFilial("CNC")+cContr+cRev+cCodCli+cLojCli))
		oModel:GetModel():SetErrorMessage(oModel:GetId(),"TFL_LOCAL",oModel:GetModel():GetId(),	"TFL_LOCAL",'AT870NWL',; 
											STR0148, STR0149 ) //"Não é possivel incluir novos locais de atendimento com clientes diferentes"
		lRet := .F.
	EndIf
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870Filt
@since 17/04/2014
@version 12
@param oBrowse, objeto Janela
@description
Realiza o filtro das informações
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At870Filt(oBrowse)	
Return At870AtuBrw(oBrowse)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870AprRv
@since 17/04/2014
@version 12
@param cContr, character Numero do contrato
@param cRev, character Revisão do contrato
@param cStatus, character Status do contrato
@description
Realiza a aprovação do contrato com status aguardando aprovação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At870AprRv(cContr,cRev,cStatus,lSemTela)
Local nRetorno := 0
Local lRet	   := .T.

Default lSemTela := .F.

If cStatus == DEF_TFJ_AGDAPROVA
	DbSelectArea("CN9")
	DbSetOrder(1) //CN9_FILIAL+CN9_NUMERO+CN9_REVISA
	If DbSeek(xFilial("CN9")+cContr+cRev)
		nRetorno := CN300Aprov(lSemTela)
		If nRetorno == 0 //Retorna 0 se for clicado em OK e 1 em Cancelar.
		   At870Aprov(cContr,cRev,lSemTela)
		Else
			lRet	   := .F.
	    EndIf
	EndIf
Else
	Help( ' ', 1, 'At870AprRv', ,STR0046, 1, 0 )	//"Ação permitida apenas para orçamento com status revisado"
	lRet	   := .F.	
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870AtuOr
@since 17/04/2014
@version 12
@param cContra, character Numero do contrato
@param cRevisa, character Revisão do contrato
@description
Atualiza as informações do novo local no orçamento de serviços
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At870AtuOr(oModel,cContrato,cRevisa)

Local oMdlLoc := oModel:GetModel('TFL_LOC')
Local oMdlRh	:= oModel:GetModel('TFF_RH')
Local oMdlMi	:= oModel:GetModel('TFG_MI')
Local oMdlMc	:= oModel:GetModel('TFH_MC')
Local oMdlLep	:= oModel:GetModel('TFI_LE')
Local oMdlLe	:= oModel:GetModel('TEV_ADICIO')
Local nI		:= 0
Local nL		:= 0
Local nK		:= 0
Local lOrcPrc 	:= SuperGetMV("MV_ORCPRC",,.F.)

For nL := 1 To oMdlLoc:Length()

	oMdlLoc:Goline( nL )
	
	For nI := 1 To oMdlRh:Length()
	
		oMdlRH:GoLine( nI )
	
		If !oMdlRH:IsDeleted() .And. !Empty(oMdlRH:GetValue("TFF_PRODUT")) .And. oMdlRH:GetValue("TFF_COBCTR") <> "2"
				
			oMdlRH:SetValue("TFF_CONTRT",cContrato)
			oMdlRH:SetValue("TFF_CONREV",cRevisa)
				
			If !lOrcPrc
				At870MtSld( oMdlMi, oMdlMc )
			EndIf
		EndIf
	Next nI
				
	If lOrcPrc
		At870MtSld( oMdlMi, oMdlMc )
	EndIf
		
	For nI := 1 To oMdlLep:Length()
		
		oMdlLep:GoLine( nI )
		
		If !oMdlLep:IsDeleted() .AND. !Empty(oMdlLep:GetValue("TFI_PRODUT"))
			oMdlLep:SetValue("TFI_CONTRT",cContrato)
			oMdlLep:SetValue("TFI_CONREV",cRevisa)
			
			For nK := 1 To oMdlLe:Length()
			
				oMdlLe:GoLine( nK )
				
				If !oMdlLe:IsDeleted() .AND. !Empty(oMdlLe:GetValue("TEV_MODCOB"))
					nQtdLe := oMdlLe:GetValue("TEV_QTDE")	
					oMdlLe:SetValue("TEV_SLD",nQtdLe)
				EndIf
			
			Next nK
		EndIf
	Next nI
	
Next nL
			
Return
			
/*/{Protheus.doc} At870MtSld
@description 	Atualiza os saldos nas tabelas TFG e TFH
@since 		17.11.2016
@version 	12
@param 		oMdlMi, Objeto, grid do orçamento de serviços de material de implantação
@param 		oMdlMc, Objeto, grid do orçamento de serviços de material de consumo
/*/
Static Function At870MtSld( oMdlMi, oMdlMc  )
			
Local nZ := 1
Local nQtdSld := 0
				
For nZ := 1 To oMdlMi:Length()
				
	oMdlMi:GoLine(nZ)
						
	If !oMdlMi:IsDeleted() .AND. !Empty(oMdlMi:GetValue("TFG_PRODUT")) .And. oMdlMi:GetValue("TFG_COBCTR") <> "2"
		nQtdSld := oMdlMi:GetValue("TFG_QTDVEN")
		oMdlMi:SetValue("TFG_SLD",nQtdSld)
	EndIf
					
Next nZ
				
For nZ := 1 To oMdlMc:Length()
				
	oMdlMc:GoLine(nZ)
					
	If !oMdlMc:IsDeleted() .AND. !Empty(oMdlMc:GetValue("TFH_PRODUT")) .And. oMdlMc:GetValue("TFH_COBCTR") <> "2"
		nQtdSld := oMdlMc:GetValue("TFH_QTDVEN")
		oMdlMc:SetValue("TFH_SLD",nQtdSld)
	EndIf
				
Next nZ
			
Return


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870AtGES
@since 05/01/2015
@version 11.9
@param cCodTFJAnt, Codigo do orçamento de serviços anterior
@param cCodTFJ, Codigo do novo orçamento de serviços
@description Função para atualizar todos os funcionarios do local de atenidimento para a 
			 gestão de escalas.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At870AtGES( cCodTFJAnt, cCodTFJ )

Local cAliasTGY := GetNextAlias()
Local cAliasTGZ := GetNextAlias()
Local aCodTFF   := At870CodTFF(cCodTFJAnt)
Local cSqlTFF   := ""
Local nPosTFF   := 0
Local nTotal 	:= 0
Local oDlg		:= nil
Local oSayMtr	:= nil
Local nMeter	:= 0
Local nI

If Len(aCodTFF) > 0

	cSqlTFF := "%("
	
	For nI:=1 To Len(aCodTFF)
	
		cSqlTFF += "'" + aCodTFF[ nI, 1 ] + "'"	
		
		If (nI+1) <= Len(aCodTFF)
			cSqlTFF += ","
		EndIf
	
	Next nI
	
	cSqlTFF += ")%"
	
	// Verificar as configurações dos efetivos
	BeginSql Alias cAliasTGY

		SELECT 
			TGY.TGY_FILIAL, TGY.TGY_ESCALA, TGY.TGY_CODTDX, 
			TGY.TGY_CODTFF, TGY.TGY_ITEM 
		FROM 
			%table:TGY% TGY
		WHERE 
			TGY.TGY_FILIAL = %xFilial:TGY% AND 
			TGY.%notDel% AND 
			TGY.TGY_CODTFF IN %Exp:cSqlTFF%		

	EndSql
	
	While (cAliasTGY)->(!Eof())
		nTotal++
		(cAliasTGY)->(dbSkip())
	End
	(cAliasTGY)->(dbGoTop())

	dbSelectArea("TGY")	
	TGY->(DbSetOrder(1)) //TGY_FILIAL+TGY_ESCALA+TGY_CODTDX+TGY_CODTFF+TGY_ITEM
	
	If isBlind()
		UpdTGYxTFF(cAliasTGY, aCodTFF)
	Else
		DEFINE MSDIALOG oDlg FROM 0,0 TO 5,60 TITLE STR0262 //"Atualizando configuração de alocação"
			oSayMtr := tSay():New(10,10,{||STR0257},oDlg,,,,,,.T.,,,220,20) //"Processando, aguarde..."
			oMeter  := tMeter():New(20,10,{|u|if(Pcount()>0,nMeter:=u,nMeter)},nTotal,oDlg,220,10,,.T.)
			
		ACTIVATE MSDIALOG oDlg CENTERED ON INIT (UpdTGYxTFF(cAliasTGY, aCodTFF,@oDlg,@oMeter))
	EndIf
	
	nTotal := 0
	oDlg := nil
	oSayMtr := nil
	nMeter := 0
	
	// Verificar as configurações das coberturas
	BeginSql Alias cAliasTGZ
	
		SELECT 
			TGZ.TGZ_FILIAL, TGZ.TGZ_ESCALA, TGZ.TGZ_CODTDX, 
			TGZ.TGZ_CODTFF, TGZ.TGZ_ITEM 
		FROM 
			%table:TGZ% TGZ 
		WHERE 
			TGZ.TGZ_FILIAL = %xFilial:TGZ% AND 
			TGZ.%notDel% AND 
			TGZ.TGZ_CODTFF IN %Exp:cSqlTFF%	
	
	EndSql
	
	While (cAliasTGZ)->(!Eof())
		nTotal++
		(cAliasTGZ)->(dbSkip())
	End
	(cAliasTGZ)->(dbGoTop())

	dbSelectArea("TGZ")	
	TGZ->(DbSetOrder(1))//TGZ_FILIAL+TGZ_ESCALA+TGZ_CODTDX+TGZ_CODTFF+TGZ_ITEM
	
	If IsBlind()
		UpdTGZxTFF(cAliasTGZ, aCodTFF)
	Else
		DEFINE MSDIALOG oDlg FROM 0,0 TO 5,60 TITLE STR0263 //"Atualizando configuração de cobertura"
			oSayMtr := tSay():New(10,10,{||STR0257},oDlg,,,,,,.T.,,,220,20) //"Processando, aguarde..."
			oMeter  := tMeter():New(20,10,{|u|if(Pcount()>0,nMeter:=u,nMeter)},nTotal,oDlg,220,10,,.T.)
			
		ACTIVATE MSDIALOG oDlg CENTERED ON INIT (UpdTGZxTFF(cAliasTGZ, aCodTFF,@oDlg,@oMeter))
	EndIf

	(cAliasTGY)->(dbCloseArea())
	(cAliasTGZ)->(dbCloseArea())	
EndIf	

Return(Nil)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870CodTFF
@since 05/01/2015
@version 11.9
@param cCodTFJ, Codigo do orçamento de serviços
@description Função para retornar o codigo do recurso humano dentro do orçamento.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At870CodTFF( cCodTFJ )

Local aRet      := {}
Local cAliasTFJ := GetNextAlias()

BeginSql Alias cAliasTFJ

	SELECT 
		TFF.TFF_COD, TFF.TFF_CODSUB 
	FROM 
		%table:TFJ% TFJ
	JOIN %table:TFL% TFL ON 
		TFL.TFL_FILIAL = %xFilial:TFL% AND 
		TFL.TFL_CODPAI = TFJ.TFJ_CODIGO AND 
		TFL.%notDel%
	JOIN %table:TFF% TFF ON 
		TFF.TFF_FILIAL = %xFilial:TFF% AND 
		TFF.TFF_CODPAI = TFL.TFL_CODIGO AND 
		TFF.%notDel%
	WHERE 
		TFJ.TFJ_FILIAL = %xFilial:TFJ% AND 
		TFJ.TFJ_CODIGO = %Exp:cCodTFJ% AND 
		TFJ.%notDel%
	GROUP BY
		TFF.TFF_COD, TFF.TFF_CODSUB 

EndSql

While (cAliasTFJ)->(!Eof())
	aAdd( aRet, { (cAliasTFJ)->TFF_COD, (cAliasTFJ)->TFF_CODSUB } )
	(cAliasTFJ)->(DbSkip())	
EndDo

(cAliasTFJ)->(dbCloseArea())
Return(aRet)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870GerMem
@since 05/02/2015
@version 12
@sample 	At870GerMem(cNumContr, cRevContr, cAliasPro)		
@param cNumContr - Numero do Contrato
@param cRevContr - Numero da Revisao
@param cAliasPro - Temporario
@return lRet, Retorno logico
@description
Realiza consistencias e chama tela de memorando
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At870GerMem(cNumContr, cRevContr, cAliasPro)

Local lRet      := .F.
Local aAreaMe   := GetArea()
Local cAliasCN9 := GetNextAlias()
Local cMaxRev   := Space(TamSX3("CN9_REVISA")[1])
Local cSVig     := ''

If (cAliasPro)->TFJ_STATUS == DEF_TFJ_ATIVO
	
	// Verifica o Status do Contrato
	// Somente podera gerar o memorando para contratos vigentes
	IF ! Empty(cNumContr)
		DbSelectArea("CN9")
		CN9->(DbSetOrder(1)) // CN9_FILIAL, CN9_NUMERO, CN9_REVISA
		If CN9->(DbSeek(xFilial("CN9")+cNumContr+cRevContr))
		
			If CN9->CN9_SITUAC == DEF_SVIGE	//01=Cancelado;02=Elaboracao;03=Emitido;04=Aprovacao;05=Vigente;06=Paralisa.;07=Sol. Finalizacao;08=Finalizado;09=Revisao;10=Revisado
				
				cSVig := DEF_SVIGE //Necessario embedded não reconhece direto a Define 
				
				// Verifica se contrato possui revisao
				BeginSql Alias cAliasCN9
				
					SELECT 
						MAX(CN9.CN9_REVISA) AS CN9_REVISA 
					FROM 
						%table:CN9% CN9 
					WHERE 
						CN9.CN9_FILIAL = %xFilial:CN9% AND 
						CN9.%notDel% AND
						CN9.CN9_NUMERO = %Exp:cNumContr% AND
						CN9.CN9_SITUAC = %Exp:cSVig%	
				
				EndSql
						
				DbSelectArea(cAliasCN9)
		
				While (cAliasCN9)->( !Eof() )	
					cMaxRev := (cAliasCN9)-> CN9_REVISA
					(cAliasCN9)->(DbSkip())				
				EndDo
				
				(cAliasCN9)->( DbCloseArea() )
				
				If cMaxRev <> cRevContr
					Help( ' ', 1, "At870GerMem", , STR0061, 1, 0 )	//"Não é possível gerar o memorando para revisões anteriores"
				Else
					If MSGYESNO( STR0062,STR0060 ) //"Deseja realmente gerar os memorandos?" # "Memorando"
						// Chama rotina de geracao do memorando
						lRet := At330GerMem(cNumContr, cRevContr, '')
					Else
						lRet := .F.
					EndIf				
				EndIf
			Else
				Help( ' ', 1, "At870GerMem", , STR0063, 1, 0 )	//"Permitido somente para contratos vigentes"			
			EndIf
		Else
			Help( ' ', 1, "At870GerMem", , STR0064, 1, 0 )	//"Contrato não localizado"
		EndIf
	Else
		Help( ' ', 1, "At870GerMem", , STR0065, 1, 0 )	//"Não existe contrato gerado"
	EndIf
Elseif (cAliasPro)->TFJ_STATUS == DEF_TFJ_ENCERRADO
	Help( ' ', 1, "At870GerMem", , STR0099, 1, 0 )	//"Não é possível gerar memorandos para orçamentos de serviços encerrados." 
Elseif (cAliasPro)->TFJ_STATUS == DEF_TFJ_CANCELADO
	Help( ' ', 1, "At870GerMem", , STR0093, 1, 0 )	//"Não é possível gerar memorandos para orçamentos de serviços cancelados." 
Else
	Help( ' ', 1, "At870GerMem", , STR0094, 1, 0 )	//"Não é possível gerar memorandos para orçamentos de serviços em revisão."
EndIf

RestArea(aAreaMe)

Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870VRes
@since 04/03/2015
@version 12
@param oMdRes , Modelo da Revisao
@param cCodTFJ, Codigo do orçamento de serviços
@description Função que efetua o tratamento do bloqueio da revisão do contrato
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At870VRes(oMdRes,cCodTFJ)

Local lRet			:= .T.
Local aSaveRows	:= FwSaveRows( oMdRes )
Local aAreaBLQ	:= GetArea()
Local nRecTFL		:= 0 

Local oAuxTFL		:= oMdRes:GetModel("TFL_LOC")
Local oAuxTFF		:= oMdRes:GetModel("TFF_RH")
Local oAuxTFG		:= oMdRes:GetModel("TFG_MI")
Local oAuxTFH		:= oMdRes:GetModel("TFH_MC")
Local oAuxTFI		:= oMdRes:GetModel("TFI_LE")

// Totais do orcamento atual
Local nValRHOld	:= 0
Local nValMIOld	:= 0
Local nValMCOld	:= 0
Local nValLEOld	:= 0

// Totais do orcamento revisado
Local nValRHNew	:= 0
Local nValMINew	:= 0
Local nValMCNew	:= 0
Local nValLENew	:= 0

// Indices do local
Local cCdTFL		:= '' 
Local cCTRTFL		:= ''
Local cREVTFL		:= ''
Local cPLATFL		:= ''

// Grupo de Faturamento

Local lGrpFatOrc	:= ''
Local cPLANRH		:= ''
Local cPLANMI		:= ''
Local cPLANMC		:= ''
Local cPLANLE		:= ''
Local cCodGrup		:= ''


DbSelectArea("TFJ")
TFJ->(DbSetOrder(1)) // TFJ_FILIAL, TFJ_CODIGO
If TFJ->(DbSeek(xFilial("TFJ")+cCodTFJ))
	lGrpFatOrc	:= TFJ->TFJ_GRPFAT == '1'
	cCodGrup	:= TFJ->TFJ_CODGRP
EndIf

// Percorre as localizacoes do orcamento
DbSelectArea("TFL")
TFL->(DbSetOrder(2)) // TFL_FILIAL, TFL_CODPAI

If TFL->(DbSeek(xFilial("TFL")+cCodTFJ)) 

	Do While TFL->(!Eof()) .And. TFL->TFL_FILIAL == xFilial("TFL") .AND. TFL->TFL_CODPAI == cCodTFJ
	
		cCdTFL  := TFL->TFL_CODIGO 
		cCTRTFL := TFL->TFL_CONTRT
		cREVTFL := TFL->TFL_CONREV
		If !lGrpFatOrc
			cPLATFL := TFL->TFL_PLAN
			
		Else
			lRet := At870GrPlan( cCodGrup, TFL->TFL_LOCAL, @cPlanRH, @cPlanMI, @cPlanMC, @cPlanLE )
			
		EndIf
 		nRecTFL := TFL->(Recno())
		
		// Totaliza os valores totais do orcamento atual
		At870ValOld( At870LocAnt( oAuxTFL:GetValue("TFL_CODIGO") ), @nValRHold, @nValMIold, @nValMCold, @nValLEold )
		      
		// Totaliza os valores totais do orcamento revisado
		oAuxTFL:SeekLine( { {"TFL_CODIGO",cCdTFL} } )
		At870ValNew( oMdRes, oAuxTFL:GetLine(), @nValRHnew, @nValMInew, @nValMCnew, @nValLEnew )
		
		// Compara a diferenca dos totais do orcamento
		If ( nValRHOld + nValMIOld + nValMCOld + nValLEOld ) > ( nValRHNew + nValMINew + nValMCNew + nValLENew ) .and. lRet 

			//Carrega Planilhas do contrato
			DbSelectArea("CNA")
			CNA->(DbSetOrder(1))  // CNA_FILIAL+CNA_CONTRA+CNA_REVISA+CNA_NUMERO
			If !lGrpFatOrc
				If !Empty(cPLATFL) .and. CNA->(DbSeek(xFilial("CNA")+cCTRTFL+cREVTFL+cPLATFL))
					lRet := ( ( nValRHNew + nValMINew + nValMCNew + nValLENew ) > ( CNA->(CNA_VLTOT - CNA_SALDO) ) )
				Else
					lRet := .F.
				EndIf
			Else
				If !Empty(cPlanRH) .and. CNA->(DbSeek(xFilial("CNA")+cCTRTFL+cREVTFL+cPlanRH))
					lRet := ( ( nValRHNew) > ( CNA->(CNA_VLTOT - CNA_SALDO) ) )
				EndIf
			
				If lRet .and. !Empty(cPlanMI) .and. CNA->(DbSeek(xFilial("CNA")+cCTRTFL+cREVTFL+cPlanMI))
					lRet := ( ( nValMINew) > ( CNA->(CNA_VLTOT - CNA_SALDO) ) )
				EndIf
				
				If lRet .and. !Empty(cPlanMC) .and. CNA->(DbSeek(xFilial("CNA")+cCTRTFL+cREVTFL+cPlanMC))
					lRet := ( ( nValMCNew) > ( CNA->(CNA_VLTOT - CNA_SALDO) ) )
				EndIf
				
				If lRet .and. !Empty(cPlanLE) .and. CNA->(DbSeek(xFilial("CNA")+cCTRTFL+cREVTFL+cPlanLE))
					lRet := ( ( nValLENew) > ( CNA->(CNA_VLTOT - CNA_SALDO) ) )
				EndIf
			EndIf
		EndIf //!lGrpFatOrc
								
		If !lRet
			Help( ' ', 1, 'At870VRes', , STR0059, 1, 0 )	// "O total do contrato no Gestão de Serviços não pode ser inferior ao valor já medido no Gestão de Contratos."
			EXIT
		EndIf
		
		TFL->(DbSkip())  
	EndDo
EndIf

FwRestRows(aSaveRows,oMdRes)
RestArea(aAreaBLQ)
Return lRet


//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} AT870GetRE()
Busca o conteúdo da variável estática da revisao do contrato,
evitando assim, a declaração de variáveis Private.	 
@sample     AT870GetRE(_aRevisao_) 
@return     _aRevisao_: array( <lrevisao>, <tipo da revisao> ) 
@author     totvs
@since      23/06/2015
@version    P12
/*/
//-----------------------------------------------------------------------------------------
Function AT870GetRE()

Return( _aRevisao_ )


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT870SetRE
Guarda o conteúdo da variável estática da revisao do contrato,
evitando assim, a declaração de variáveis Private.	 
@sample        AT870SetRE( aRevisao )
@param         aRevisao, Array, Array da revisão
@return        NIL
@author        rogerio.souza
@since         23/06/2015
@version       11.9
@description 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function AT870SetRE( aRevisao )
_aRevisao_ := aRevisao
Return


//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} AT870GETVT()
Guarda o conteúdo da variável estática da revisao do contrato,
evitando assim, a declaração de variáveis Private.	 
@sample     AT870GETVT(cTipo) 
@return     cTipo: caracter 1=Vistoria Tecnica 2=Material de Implantacao 3=Material de Consumo 
@author     totvs
@since      23/06/2015
@version    P12
/*/
//-----------------------------------------------------------------------------------------
Function AT870GETVT(cTipo)
Local lRet := .T.

Do Case
	Case cTipo == '1'
		lRet := lViTc740
	Case cTipo == '2'
		lRet := lMtImp
	Case cTipo == '3'
		lRet := lMtCns
EndCase
Return( lRet )


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT870SetVT
@sample        AT870SetVT(cTipo,lValor)
@param         cTipo, caracter
@param         lValor, Lógico
@return        NIL
@author        rogerio.souza
@since         23/06/2015
@version       11.9
@description 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function AT870SetVT(cTipo,lValor)

Do Case
	Case cTipo == '1'
		lViTc740 := lValor
	Case cTipo == '2'
		lMtImp := lValor
	Case cTipo == '3'
		lMtCns := lValor
EndCase
Return


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870ViCtr
@since 23/11/2015
@version 12
@param cCodTFJ, Codigo do orçamento de serviços
@description Realiza a visualização do contrato do GCT
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At870ViCtr(cCodTFJ)

Local aArea 	:= {}

DbSelectArea("TFJ")
TFJ->(DbSetOrder(1))//TFJ_FILIAL+TFJ_CODIGO
aArea := TFJ->(GetArea())

DbSelectArea("CN9")
CN9->(DbSetOrder(1)) //CN9_FILIAL+CN9_NUMERO+CN9_REVISA

If TFJ->(DbSeek(xFilial("TFJ")+cCodTFJ)) .And. CN9->( DbSeek( xFilial("CN9")+TFJ->(TFJ_CONTRT+TFJ_CONREV) ) )
	Inclui := .F.
	Altera := .F.
	CN300Visua()
Else
	Help( ' ', 1, "At870ViCtr", , STR0069, 1, 0 )	// "Orçamento de Serviços ou contrato do GCT não localizado"
EndIf

TFJ->(RestArea(aArea))
Return 


//-------------------------------------------------------------------------------------
/*/{Protheus.doc} At870EncPo(cContrato, cRevisao)
Interface para encerramento do posto	 
@sample     At870EncPo(cContrato, cRevisao) 
@return      
@author     serviços
@since      25/08/2015
@version    P12
/*/
//-----------------------------------------------------------------------------------------
Function At870EncPo(cContrato,cRevisao,oBrowse,cAliasPro, cStatus, lAutomato)

Local oModel	:= Nil
Local aArea	:= GetArea()
Local lRet		:= .F.

DEFAULT lAutomato := .F.

If !cStatus $ "2|3|4" //Em Revisão#Revisado#Aguardando aprovação

	//Foi necessario abrir o SX3
	DbSelectArea("SX3")
	SX3->(DbSetOrder(1))
	
	If lAutomato                                                                                                                       
		TFJ->(dbSetOrder(5))//TFJ_FILIAL+TFJ_CONTRT+TFJ_CONREV
		If TFJ->(dbSeek(xFilial("TFJ")+cContrato+cRevisao))
			If TFJ->TFJ_STATUS == DEF_TFJ_CANCELADO
				Help( ' ', 1, "At870EncPo", , STR0090, 1, 0 )	//"O orçamento de serviços encontra-se cancelado"
			ElseIf TFJ->TFJ_STATUS == DEF_TFJ_ENCERRADO
				Help( ' ', 1, "At870EncPo", , STR0085, 1, 0)	//"O orçamento de serviços já encontra-se encerrado."
			Else
				lRet := .T.
			EndIf
		EndIf
	Else
		If (cAliasPro)->TFJ_STATUS == DEF_TFJ_CANCELADO
			Help( ' ', 1, "At870EncPo", , STR0090, 1, 0 )	//"O orçamento de serviços encontra-se cancelado"
		ElseIf (cAliasPro)->TFJ_STATUS == DEF_TFJ_ENCERRADO
			Help( ' ', 1, "At870EncPo", , STR0085, 1, 0)	//"O orçamento de serviços já encontra-se encerrado."
		Else
			DbSelectArea("TFJ")
			TFJ->(DbSetOrder(5))//TFJ_CONTRTL+TFJ_CONREV
			If TFJ->(DbSeek(xFilial("TFJ")+cContrato+cRevisao))
				If At871VldDt(,TFJ->TFJ_PROPOS,.F.)
					lRet := .T.
					FWExecView( STR0079, "VIEWDEF.TECA871", MODEL_OPERATION_UPDATE, /*oDlg*/, {||.T.} /*bCloseOk*/,	{||.T.}/*bOk*/,/*nReducao*/, /*aButtons*/, {||.T.}/*bCancel*/ )	//"Encerramento do Posto"
					//atualiza o browse com o novo status
					At870AtuBrw(oBrowse)
				Else
					Help( "", 1, "At870EncPo", , STR0211, 1, 0,,,,,,;  // "A data base está fora do(s) período(s) do contrato."
												{STR0212})  // "Realize o encerramento de posto com a data base entre o(s) período(s) do contrato."
				Endif
			Else
				MsgStop(STR0069)//"Registro não encontrado
			Endif	
		EndIf
	Endif
Else
	Help( ' ', 1, "At870EncPo", , STR0236, 1, 0)//"Ação não permitida, contrato em processo de Revisão/Aprovação"
EndIf
Return lRet


//-------------------------------------------------------------------------------------
/*/{Protheus.doc} At870Sep
@author Rogerio Melonio
@since 31/03/2016
@version 12.7
@return lRet, Verdadeiro caso campos estejam OK
@description
Realiza verificação de itens de locação separados
/*/
//-------------------------------------------------------------------------------------
Static Function At870Sep(cCodTFJ, lNoHelp)

Local lRet := .T.
Local cAliasQry := GetNextAlias()

BeginSQL Alias cAliasQry       
	SELECT  TEW.TEW_FILIAL, TEW.TEW_CODMV, TFI.TFI_CODSUB, TEW.TEW_BAATD, TFI_CODPAI 
			FROM %Table:TEW% TEW
			
			INNER JOIN %Table:TFI% TFI ON
				TEW.TEW_FILIAL = TFI.TFI_FILIAL AND
				TEW.TEW_CODEQU = TFI.TFI_COD AND
				TFI.%notDel% 
				
			INNER JOIN %Table:TFL% TFL ON
				TFI.TFI_FILIAL = TFL.TFL_FILIAL AND
				TFI.TFI_CODPAI = TFL.TFL_CODIGO AND
				TFL.TFL_CODPAI = %Exp:cCodTFJ% AND 
				TFL.%notDel% 
		WHERE 
			TEW.TEW_FILIAL = %xFilial:TEW% AND
			TEW.TEW_BAATD <> '' AND		
			TEW.%notDel% 	
EndSql

If (cAliasQry)->(!EOF()) 
	lRet := .F.
	If lNoHelp
		AutoGrLog( STR0095 + " / " + STR0096 )	// "Contrato com Separação"#"Não é possivel revisar contrato que já teve separação de equipamento."
	Else
		Help( ' ', 1, STR0095 , , STR0096, 1, 0 )	//"Contrato com Separação"#"Não é possivel revisar contrato que já teve separação de equipamento."	
	EndIf
EndIf

(cAliasQry)->(DbCloseArea())

Return lRet

//-------------------------------------------------------------------------------------
/*/{Protheus.doc} A870EdCAlo(cStatus, cNumContr)
@description 	 
@sample       A870EdCAlo(cStatus, cNumContr) 
@param        cNumContr:  Número do contrato
@return       .T.=Processado com sucesso // .F.=Processamento não ocorreu
@author       Alexandre da Costa
@since        31/03/2016
@version      P12
/*/
//-----------------------------------------------------------------------------------------
Function A870EdCAlo(cStatus, cNumContr)

Local	lRet	:= .T.

If	cStatus == DEF_TFJ_CANCELADO
	Help(,,"A870EdCAlo",, STR0084, 1, 0)	//"O orçamento de serviços já encontra-se cancelado."
	lRet	:= .F.
ElseIf	cStatus == DEF_TFJ_ENCERRADO
	Help(,,"A870EdCAlo",, STR0085, 1, 0)	//"O orçamento de serviços já encontra-se encerrado."
	lRet	:= .F.
Else
	TECA740D(cNumContr)
EndIf

Return	lRet


//-------------------------------------------------------------------------------------
/*/{Protheus.doc} At870NwSit(cNumContr, cRevContr, cNewStaGS, lConfirm)
@description Realiza a troca do status (nova situação) do orçamento de serviços	 
@sample       At870NwSit(cNumContr, cRevContr, cNewStaGS, lConfirm) 
@param        cNumContr:  Número do contrato
@param        cRevContr:  Revisão do contrato
@param        cNewStaGS:  Novo status para o orçamento de serviços
@param        lConfirm:   .T.=Solicita confirmação do usuário para efetivar a operação // .F.=Não solicita confirmação do usuário para efetivar a operação
@return       .T.=Atualização da nova situação do Orçamento de Serviços ocorreu com sucesso // .F.=A atualização da nova situação do Orçamento de Serviços não ocorreu
@author       Alexandre da Costa
@since        29/03/2016
@version      P12
/*/
//-----------------------------------------------------------------------------------------
Function At870NwSit(cNumContr, cRevContr, cNewStaGS, lConfirm, lAutomato,cOrcSrv,lSrvExt)

Local	aOldArea	:=	If(Select(Alias()) > 0, (Alias())->(GetArea()), {})
Local	aOldTFJ	:=	TFJ->(GetArea())
Local	aOldCN9	:=	CN9->(GetArea())
Local	cFilTFJ	:=	xFilial("TFJ")
Local	cFilCN9	:=	xFilial("CN9")
Local	cSituacGCT	:=	""
Local	lEfetNwSta	:=	.T.
Local	lRet		:=	.F.

Default	cNewStaGS	:= ""
Default	lConfirm	:= .T.
Default lAutomato	:= .F.
Default cOrcSrv     := ""
Default lSrvExt     := .F.

If	(!Empty(cNumContr) .or. (lSrvExt .And. !Empty(cOrcSrv))) .And. ! Empty(cNewStaGS)
	
	If lSrvExt
		TFJ->(DbSetOrder(1))	//TFJ_FILIAL+TFJ_CODIGO
		TFJ->(DbSeek(cFilTFJ+cOrcSrv))
	Else
		TFJ->(DbSetOrder(5))	//TFJ_FILIAL+TFJ_CONTRTL+TFJ_CONREV
		TFJ->(DbSeek(cFilTFJ+cNumContr+cRevContr))
		cSituacGCT := Posicione("CN9",1,cFilCN9+cNumContr+cRevContr,"CN9_SITUAC")
	EndIf

	Do	Case
		Case	cNewStaGS == DEF_TFJ_CANCELADO

			If	TFJ->TFJ_STATUS == DEF_TFJ_CANCELADO
				Help(,,"At870NwSit",, STR0084, 1, 0)	//"O orçamento de serviços já encontra-se cancelado."
				lRet	:= .F.
			ElseIf	TFJ->TFJ_STATUS == DEF_TFJ_ENCERRADO
				Help(,,"At870NwSit",, STR0085, 1, 0)	//"O orçamento de serviços já encontra-se encerrado."
				lRet	:= .F.
			Else
				If !lSrvExt .Or. cSituacGCT	== DEF_SELAB //01=Cancelado;02=Elaboracao;03=Emitido;04=Aprovacao;05=Vigente;06=Paralisa.;07=Sol. Finalizacao;08=Finalizado;09=Revisao;10=Revisado
					If	lConfirm .And. !( IIF (!lAutomato , MsgYesNo(STR0082), .T.) ) //"Deseja efetivar o cancelamento do Orçamento de Serviços?"
						lEfetNwSta	:=	.F.
						lRet		:=	.F.
					EndIf
					If	lEfetNwSta
						If lSrvExt
							lRet := .T.
						Else
							( lRet := CN100SitCh( cNumContr, cRevContr, DEF_SCANC, "" ) )	// Atualiza o status do contrato no GCT como CANCELADO
						EndIf
						If lRet
							TFJ->(RecLock("TFJ",.F.))
							TFJ->TFJ_STATUS := DEF_TFJ_CANCELADO
							TFJ->(MsUnLock())
							If !Empty(TFJ->TFJ_GRPCOM)
								//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
								//³SIGATEC WorkFlow # CT - Interações de Contratos Cancelamento		 ³
								//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
								At774Mail("TFJ",TFJ->TFJ_GRPCOM,"CT","<b>"+STR0106+"</b> "+TFJ->TFJ_PROPOS+"<b> "+STR0107+"</b>"+TFJ->TFJ_CONTRT,"RED",STR0112) //"Num. Proposta: " # "Nr. Contrato: " # "Cancelamento"
							Endif
						EndIf
					EndIf
				Else
					Help(,,"At870NwSit",, STR0083, 1, 0)	//"É permitido o cancelamento de um orçamento de serviços somente quando o contrato a ele associado estiver em elaboração"
					lRet	:= .F.
				EndIf
			EndIf

		Case	cNewStaGS == DEF_TFJ_ENCERRADO

			If	TFJ->TFJ_STATUS == DEF_TFJ_CANCELADO
				Help(,,"At870NwSit",, STR0084, 1, 0)	//"O orçamento de serviços já encontra-se cancelado."
				lRet	:= .F.
			ElseIf	TFJ->TFJ_STATUS == DEF_TFJ_ENCERRADO
				Help(,,"At870NwSit",, STR0085, 1, 0)	//"O orçamento de serviços já encontra-se encerrado."
				lRet	:= .F.
			Else
				If	lConfirm .And. !( MsgYesNo(STR0086) ) //"Deseja efetivar o encerramento do Orçamento de Serviços?"
					lEfetNwSta	:=	.F.
					lRet		:=	.F.
				EndIf
				If	lEfetNwSta
					If lSrvExt
						lRet := .T.
					Else
						( lRet := CN100SitCh( cNumContr, cRevContr, DEF_SFINA, "" ) )	// Atualiza o status do contrato no GCT como FINALIZADO
					EndIf
					If lRet
						TFJ->(RecLock("TFJ",.F.))
						TFJ->TFJ_STATUS := DEF_TFJ_ENCERRADO
						TFJ->(MsUnLock())
					EndIf
				EndIf
			EndIf

	EndCase
EndIf

RestArea(aOldCN9)
RestArea(aOldTFJ)
If	Len(aOldArea) > 0
	RestArea(aOldArea)
EndIf
Return lRet

//-------------------------------------------------------------------------------------
/*/{Protheus.doc} At870SIGCT()
@description Realiza a troca do status (nova situação) dos Contratos do GCT
@sample       At870SIGCT(cNumCTR, cRevCTR) 
@param        cNumCTR:  Número do contrato
@param        cRevCTR:  Revisão do contrato
@author       Filipe Gonçalves
@since        12/05/2016
@version      P12
/*/
//-----------------------------------------------------------------------------------------
Function At870SIGCT(cNumCTR, cRevCTR)
Local aArea		:= GetArea() 

CN9->(dbSetOrder(1))
If CN9->(dbSeek(xFilial("CN9") + cNumCTR + cRevCTR))
	CN100Situac("CN9",CN9->(Recno()),5)
Else
	Help( ' ', 1, "At870NContr", , STR0113, 1, 0)	//"Contrato não localizado no SIGAGCT, verifique!"
EndIf	
RestArea(aArea)
Return nil

//-------------------------------------------------------------------------------------
/*/{Protheus.doc} At870Conf()
@description Exibe a tela para a cofirmação da data de entrega e coleta do equipamento.
@sample       At870Conf(cCodTFJ)
@param        cCodTFJ:  Codigo do Orçamento de Serviços
@author       Kaique Schiller
@since        24/05/2016
@version      P12
/*/
//-----------------------------------------------------------------------------------------
Function At870Conf(cCodTFJ,cAliasPro,lAutomato)

Default lAutomato := .F.

If !lAutomato
	If (cAliasPro)->TFJ_STATUS == DEF_TFJ_ENCERRADO .OR. (cAliasPro)->TFJ_STATUS == DEF_TFJ_CANCELADO //Cancelado ## Encerrado
		Help(,, "At870Conf",,STR0104,1,0,,,,,,{STR0105+CRLF+STR0007+CRLF+STR0040+CRLF+STR0008+CRLF+STR0041+CRLF+STR0030})// "Não é permetido realizar a confirmação de entrega/coleta." ## "Os status permitidos são:" ## "Ativo" ## "Revisado" ## "Em revisão" ## "Aguardando aprovação" ## "Contrato em elaboração"
	Else
		DbSelectArea("TFJ")
		TFJ->(dbSetOrder(1))
		If TFJ->(dbSeek(xFilial("TFJ")+cCodTFJ))
			TECA743()
		EndIf
	EndIf
Else
	DbSelectArea("TFJ")
	TFJ->(dbSetOrder(1))
	If TFJ->(dbSeek(xFilial("TFJ")+cCodTFJ))
		If TFJ->TFJ_STATUS == DEF_TFJ_ENCERRADO .OR. TFJ->TFJ_STATUS == DEF_TFJ_CANCELADO //Cancelado ## Encerrado
			Help(,, "At870Conf",,STR0104,1,0,,,,,,{STR0105+CRLF+STR0007+CRLF+STR0040+CRLF+STR0008+CRLF+STR0041+CRLF+STR0030}) //"Não é permetido realizar a confirmação de entrega/coleta."|"Os status permitidos são:"|"Ativo"|"Revisado"|"Em revisão"|"Aguardando aprovação"|"Contrato em elaboração"
		EndIf
	EndIf
EndIf

Return

/*/{Protheus.doc} At870EspCtr
	
@since 12/05/2015
@version 12
		
@param cCodTpRev, character Código do Tipo de revisão

@description
Busca através do tipo da revisão a especie

/*/
Function At870EspCtr(cCodTpRev,cAcao,cCampo)

Local aAreaCN0	:= GetArea()
Local lRet		:= .F.

DbSelectArea("CN0")
CN0->(DbSetOrder(1))//CN0_FILIAL+CN0_CODIGO
If CN0->(DbSeek(xFilial("CN0")+cCodTpRev))
	If (cAcao == "CANSETVALUE" .Or. cAcao == "SETVALUE") .And. cCampo == "TFI_PERFIM" .And. CN0->CN0_ESPEC == "3"
		lRet := .T.
	EndIf
EndIf	

RestArea(aAreaCN0)

Return lRet

/*/{Protheus.doc} At870LocAnt
@since 21/01/2015
@version 11.9
@param cCodAtual, Codigo atual do item na tabela TFL
@description Função para retornar o recno anterior do item do local
/*/
Static Function At870LocAnt( cCodAtual )

Local nRecno := 0
Local cSqlArea := GetNextAlias()

Local aArea := GetArea()
Local aAreaTFL := TFL->(GetArea())

BeginSql Alias cSqlArea

	SELECT R_E_C_N_O_ TFLRECNO
	FROM %Table:TFL% TFL
	WHERE TFL.%NotDel% AND TFL_FILIAL = %xFilial:TFL% AND TFL_CODSUB = %Exp:cCodAtual%

EndSql

If (cSqlArea)->(!EOF())
	nRecno := (cSqlArea)->TFLRECNO
EndIf

(cSqlArea)->(DbCloSeArea())

RestArea(aAreaTFL)
RestArea(aArea)

Return nRecno

/*/{Protheus.doc} At870ValOld
@since 06/02/2015
@version 11.9
@param nRecTFL, registro da TFL a ser utilizado para identificação do conteúdo
@param nValRH, referência, valor do item de RH para retorno
@param nValMI, referência, valor do item de MI para retorno
@param nValMC, referência, valor do item de MC para retorno
@param nValLE, referência, valor do item de LE para retorno
@description Função para retornar o recno anterior do item do local
/*/
Function At870ValOld( nRecTFL, nValRH, nValMI, nValMC, nValLE )

Local cTmpTFL 		:= GetNextAlias()
Local lOrcPrc 		:= SuperGetMv("MV_ORCPRC",,.F.)
Local cOrcPrc 		:= If(lOrcPrc, "1", "0" )
Local lSomaImp 		:= SuperGetMv("MV_ATOPIMP",,.T.)

BeginSQL Alias cTmpTFL

SELECT
	TFL_CODIGO
	, TFL_TOTIMP
	, ( SELECT COALESCE( SUM ( ( TFF_QTDVEN * TFF_PRCVEN) - TFF_VALDES + TFF_ADM + TFF_LUCRO ), 0)
				FROM %Table:TFF% TFF
				WHERE TFF_FILIAL = %xFilial:TFF% AND TFF_CODPAI = TFL_CODIGO AND TFF_COBCTR <> '2' AND TFF.%NotDel%
	) TOTRH
	, ( SELECT COALESCE( SUM( (TFG_QTDVEN * TFG_PRCVEN) - TFG_VALDES + TFG_ADM + TFG_LUCRO), 0 )
				FROM %Table:TFG% TFG
					LEFT JOIN %Table:TFF% TFF ON '0' = %Exp:cOrcPrc% AND TFF_FILIAL = %xFilial:TFF% AND TFF_CODPAI = TFL_CODIGO
						AND TFF_COBCTR <> '2' AND TFF.%NotDel%
				WHERE TFG_FILIAL = %xFilial:TFG% AND ( ( '0' = %Exp:cOrcPrc% AND TFG_CODPAI = TFF_COD ) OR ( '1' = %Exp:cOrcPrc% AND TFG_CODPAI = TFL_CODIGO) )
						AND TFG_COBCTR <> '2' AND TFG.%NotDel%
	) TOTMI
	, ( SELECT COALESCE( SUM( (TFH_QTDVEN * TFH_PRCVEN) - TFH_VALDES + TFH_ADM + TFH_LUCRO), 0 )
				FROM %Table:TFH% TFH
					LEFT JOIN %Table:TFF% TFF ON '0' = %Exp:cOrcPrc% AND TFF_FILIAL = %xFilial:TFF%
						AND TFF_CODPAI = TFL_CODIGO AND TFF_COBCTR <> '2' AND TFF.%NotDel%
				WHERE TFH_FILIAL = %xFilial:TFH% AND ( ( '0' = %Exp:cOrcPrc% AND TFH_CODPAI = TFF_COD ) OR ( '1' = %Exp:cOrcPrc% AND TFH_CODPAI = TFL_CODIGO) )
						AND TFH_COBCTR <> '2' AND TFH.%NotDel%
	) TOTMC
	, ( SELECT COALESCE( SUM( TFI_TOTAL ), 0 )
				FROM %Table:TFI% TFI
				WHERE TFI_FILIAL = %xFilial:TFI% AND TFI_CODPAI = TFL_CODIGO AND TFI.%NotDel%
	) TOTLE
FROM %Table:TFL% TFL
WHERE TFL.R_E_C_N_O_ = %Exp:nRecTFL% AND TFL.%NotDel%

EndSql

If (cTmpTFL)->(!EOF())

	nValRH := (cTmpTFL)->TOTRH
	nValMI := (cTmpTFL)->TOTMI
	nValMC := (cTmpTFL)->TOTMC
	nValLE := (cTmpTFL)->TOTLE

	If lOrcPrc .And. lSomaImp
		nValRH += (cTmpTFL)->TFL_TOTIMP
	EndIf
EndIf

(cTmpTFL)->(DbCloseArea())
Return

/*/{Protheus.doc} At870ValNew
@description Função para retornar o recno anterior do item do local
@since 21/01/2015
@version 11.9
@param oMdlGeral, modelo principal do mvc para
@param nLinGrid, Codigo atual do item na tabela TFL
@param nValRH, referência, valor do item de RH para retorno
@param nValMI, referência, valor do item de MI para retorno
@param nValMC, referência, valor do item de MC para retorno
@param nValLE, referência, valor do item de LE para retorno
/*/
Function At870ValNew( oMdlGeral, nLinGrid, nValRH, nValMI, nValMC, nValLE )

Local aSaveRows := FwSaveRows( oMdlGeral )
Local oAuxTFJ 	:= oMdlGeral:GetModel("TFJ_REFER")
Local oAuxTFL 	:= oMdlGeral:GetModel("TFL_LOC")
Local oAuxTFF 	:= oMdlGeral:GetModel("TFF_RH")
Local oAuxTFG 	:= oMdlGeral:GetModel("TFG_MI")
Local oAuxTFH 	:= oMdlGeral:GetModel("TFH_MC")
Local oAuxTFI 	:= oMdlGeral:GetModel("TFI_LE")
Local nLinRH 	:= 0
Local nLinMI 	:= 0
Local nLinMC 	:= 0
Local nLinLE 	:= 0
Local lOrcPrc 	:= SuperGetMV("MV_ORCPRC",,.F.)
Local lSomaImp 	:= SuperGetMv("MV_ATOPIMP",,.T.)

nValRH := 0
nValMI := 0
nValMC := 0
nValLE := 0

oAuxTFL:GoLine(nLinGrid)
// varre os itens capturando o valor
For nLinRH := 1 To oAuxTFF:Length()
	oAuxTFF:GoLine(nLinRH)

	If oAuxTFF:GetValue("TFF_COBCTR") <> "2"
		nValRH += ( oAuxTFF:GetValue("TFF_SUBTOT") )
	EndIf

	If !lOrcPrc
		nValMI += ( oAuxTFF:GetValue("TFF_TOTMI") )
		nValMC += ( oAuxTFF:GetValue("TFF_TOTMC") )
	EndIf
Next nLinRH

If lOrcPrc
	For nLinMI := 1 To oAuxTFG:Length()
		oAuxTFG:GoLine(nLinMI)

		If oAuxTFG:GetValue("TFG_COBCTR") <> "2"
			nValMI += ( oAuxTFG:GetValue("TFG_TOTGER") )
		EndIf
	Next

	For nLinMC := 1 To oAuxTFH:Length()
		oAuxTFH:GoLine(nLinMC)

		If oAuxTFH:GetValue("TFH_COBCTR") <> "2"
			nValMC += ( oAuxTFH:GetValue("TFH_TOTGER") )
		EndIf
	Next
EndIf

For nLinLE := 1 To oAuxTFI:Length()
	oAuxTFI:GoLine(nLinLE)
	nValLE += ( oAuxTFI:GetValue("TFI_TOTAL") )
Next nLinLE

If lOrcPrc .And. lSomaImp
	nValRH += oAuxTFL:GetValue("TFL_TOTIMP")
EndIf

FwRestRows(aSaveRows,oMdlGeral)

Return

/*/{Protheus.doc} At870CNBUpd
	Atualiza os dados no item da planilha considerando a revisão do tipo Renovação
@since 			17.11.2016
@version 		12.15
@param 			oMdlCNB, Objeto, grid da revisão de contratos para atualização das informações de quantidade e valor unitário
@param 			nTotOldGS, Numérico, valor anterior do item no gestão de serviços
@param 			nTotNewGS, Numérico, valor novo do item no gestão de serviços
@return 		Lógico, determina se conseguiu realizar a atualização (verdadeiro) ou não (falso)
/*/
Static Function At870CNBUpd( oMdlCNB, nTotOldGS, nTotNewGS, nNewQtItem )
Local lRet 			:= .T.
// variáveis para alterar a qtde e refletir na qtde de saldo
Local nQtdItem 		:= oMdlCNB:GetValue("CNB_QUANT")
Local nQtdMed 		:= oMdlCNB:GetValue("CNB_QTDMED")
Local nQtSaldo 		:= ( nQtdItem - nQtdMed )
Local nValTotItem 	:= 0
Local nQtdItemNew 	:= 0
Local nDifItem 		:= 0
Local nTotLinCNB 	:= 0

Default nNewQtItem := 1

// variáveis para atualizar o valor unitário e refletir o novo valor adicionado no GS
nDifItem := nTotNewGS - nTotOldGS
If nDifItem <> 0
	nValTotItem := oMdlCNB:GetValue("CNB_VLTOT") + nDifItem // novo total para o item

	FwModelActive( oMdlCNB:GetModel() )

	If nQtdMed > 0
		// captura a quantidade de linhas nos itens da planilha
		nTotLinCNB := oMdlCNB:Length()
		// refaz o saldo quando identifica que houve alguma medição no item
		nQtdItemNew := nQtdItem + nNewQtItem - nQtSaldo
		// adiciona o valor do saldo ao novo item quebrado
		nDifItem += ( nQtSaldo * oMdlCNB:GetValue("CNB_VLUNIT") )
		// nova quantidade
	lRet := lRet .And. oMdlCNB:SetValue("CNB_QUANT", nQtdItemNew )
		// calcula o valor unitário para inserir no campo CNB_VLUNIT
		nDifItem := Round( (nDifItem / (nQtdItemNew - nQtdMed)), TamSX3( "CNB_VLUNIT" )[2] )

		// novo valor unitário
		If nDifItem == oMdlCNB:GetValue("CNB_VLUNIT")
			// quebra a linha atribuindo um valor diferente do valor atual
			lRet := lRet .And. oMdlCNB:SetValue("CNB_VLUNIT", nDifItem + 1 )
			// troca para a linha nova quando criada
			If nTotLinCNB <> oMdlCNB:Length()
				oMdlCNB:GoLine(oMdlCNB:Length())
			EndIf
			lRet := lRet .And. oMdlCNB:SetValue("CNB_VLUNIT", nDifItem )
		Else
			lRet := lRet .And. oMdlCNB:SetValue("CNB_VLUNIT", nDifItem )
			// troca para a linha nova quando criada
			If nTotLinCNB <> oMdlCNB:Length()
				oMdlCNB:GoLine(oMdlCNB:Length())
			EndIf
		EndIf

	Else
		// não refaz o saldo somente o ajusta o novo valor
		//  para isso precisa recalcular o valor unitário usando a quantidade atual

		// verifica se a quantidade sofreu alteração para considerar a geração não agrupada do contrato
		If nNewQtItem <> nQtdItem
			nQtdItemNew := nNewQtItem
			lRet := lRet .And. oMdlCNB:SetValue("CNB_QUANT", nQtdItemNew )
		Else
			nQtdItemNew :=  nQtdItem
		EndIf

		lRet := lRet .And. oMdlCNB:SetValue("CNB_VLUNIT", ( nValTotItem / nQtdItemNew ) )
	EndIf
EndIf

Return lRet

/*/{Protheus.doc} At870CNBAdd
@description 	Adiciona um item na planilha considerando a revisão do tipo Renovação
@since 			17.11.2016
@version 		12
@param 			oMdlCNB, Objeto, grid da revisão de contratos para atualização das informações de quantidade e valor unitário
@param 			nTotNewGS, Numérico, valor novo do item no gestão de serviços
@return 		Lógico, determina se conseguiu realizar a atualização (verdadeiro) ou não (falso)
/*/
Static Function At870CNBAdd( oMdlCNB, aDadosCNB  )
Local lRet := .T.
Local nTotLinCNB := oMdlCNB:Length()
Local nPosDados := 0

Default aDadosCNB := {}

FwModelActive( oMdlCNB:GetModel() )

If nTotLinCNB > 1 .Or. !Empty( oMdlCNB:GetValue("CNB_PRODUT") )
	If oMdlCNB:AddLine() <> (nTotLinCNB + 1)
		lRet := .F.
	EndIf
EndIf

If lRet
	// percorre o array para preencher os dados na CNB
	oMdlCNB:GetStruct():SetProperty("CNB_PRODSV", MODEL_FIELD_WHEN, {|| .T.})
	For nPosDados := 1 To Len(aDadosCNB)
		lRet := lRet .And. oMdlCNB:SetValue( aDadosCNB[nPosDados, 1], aDadosCNB[nPosDados, 2] )
	Next nPosDados
EndIf

Return lRet

/*/{Protheus.doc} At870AllPrds
@description 	Adiciona um item na planilha considerando a revisão do tipo Renovação
@since 			17.11.2016
@version 		12
@param 			oMdlCNB, Objeto, grid da revisão de contratos para atualização das informações de quantidade e valor unitário
@param 			nTotNewGS, Numérico, valor novo do item no gestão de serviços
@return 		Lógico, determina se conseguiu realizar a atualização (verdadeiro) ou não (falso)
/*/
Static Function At870AllPrds( oModel, lBuscaAnt, cContrt, cNumPlan )
Local aItens := {}
Local nX := 0
Local nY := 0
Local nValNew := 0
Local nValOld := 0
Local oMdlLocal := oModel:GetModel("TFL_LOC")
Local oMdlRH := oModel:GetModel("TFF_RH")
Local oMdlMI := oModel:GetModel("TFG_MI")
Local oMdlMC := oModel:GetModel("TFH_MC")
Local oMdlLE := oModel:GetModel("TFI_LE")
Local lOrcPrc := SuperGetMv("MV_ORCPRC",,.F.)
Local aSaveRows	:= FwSaveRows(oModel)
Local lGsMtMi	:= TFJ->TFJ_ISGSMT == '1' .AND. TFJ->TFJ_GSMTMI $ '2|3'
Local lGsMtMc	:= TFJ->TFJ_ISGSMT == '1' .AND. TFJ->TFJ_GSMTMC $ '2|3'

//Tratamento de Grupo de Faturamento

Local lGrpFatOrc := TFJ->TFJ_GRPFAT == "1" 
Local cChaveOrc	:= TFJ->TFJ_CODGRP
Local cPlanRH	:= oMdlLocal:GetValue("TFL_PLAN")
Local cPlanMC	:= oMdlLocal:GetValue("TFL_PLAN")
Local cPlanMI	:= oMdlLocal:GetValue("TFL_PLAN")
Local cPlanLE	:= oMdlLocal:GetValue("TFL_PLAN")

Default lBuscaAnt := .T.
Default cContrt := oMdlRh:GetValue("TFF_CONTRT")


If lGrpFatOrc 
	At870GrPlan( cChaveOrc, oMdlLocal:GetValue("TFL_LOCAL"), @cPlanRH, @cPlanMI, @cPlanMC, @cPlanLE )
EndIf	

// percorre os itens de recursos humanos
For nX := 1 To oMdlRh:Length()
	oMdlRh:GoLine(nX)

	If !Empty( oMdlRh:GetValue("TFF_PRODUT") ) .And. oMdlRh:GetValue("TFF_COBCTR") <> "2"
	
		If cNumPlan == cPlanRH

			nValNew := oMdlRh:GetValue("TFF_SUBTOT") // >>>> lembrar avaliar se o campo _codsub já foi preenchido neste momento
			nValOld := If( lBuscaAnt, At870OldValue( "TFF", cContrt, oMdlRH:GetValue("TFF_ITEM"), oMdlRH:GetValue("TFF_PRODUT"), oMdlRH:GetValue("TFF_COD") ),;
									0 )
	
			aAdd( aItens, { oMdlRh:GetValue("TFF_ITEM"), ; // 1
							oMdlRh:GetValue("TFF_PRODUT"),;// 2
							cPlanRH, ;						// 3
							oMdlRh:GetValue("TFF_ITCNB"),;// 4
							nValNew, ;						// 5
							nValOld, ;						//6
							oMdlRh:GetValue("TFF_QTDVEN"), ; // 7
							"RH",;							 //8
							Iif(oMdlRh:GetValue("TFF_ENCE") == "1" ,"2","1" ) ,; // 9
							"",;							//10
							""} )							//11
		EndIf
	EndIf
	If lGsMtMi .and. !Empty( oMdlRh:GetValue("TFF_PDMTMI") ) .And. oMdlRh:GetValue("TFF_COBCTR") <> "2"
		If cNumPlan == cPlanMI
			
			nValNew := oMdlRh:GetValue("TFF_VLMTMI") // >>>> lembrar avaliar se o campo _codsub já foi preenchido neste momento
			nValOld := If( lBuscaAnt, At870OldValue( "TFF", cContrt, oMdlRH:GetValue("TFF_ITEM"), oMdlRH:GetValue("TFF_PRODUT"), oMdlRH:GetValue("TFF_COD"), "2" ),0)
	
			aAdd( aItens, { oMdlRh:GetValue("TFF_ITEM"), ;
							oMdlRh:GetValue("TFF_PDMTMI"),;
							cPlanRH, ;
							oMdlRh:GetValue("TFF_ITICNB"),;
							nValNew, ;
							nValOld, ;
							1, ;
							"MI",;
							"1" ,;
							"",;
							oMdlRh:GetValue("TFF_PRODUT")} )
		
		EndIf
	EndIf
	
	If lGsMtMc .and. !Empty( oMdlRh:GetValue("TFF_PDMTMC") ) .And. oMdlRh:GetValue("TFF_COBCTR") <> "2"
		If cNumPlan == cPlanMC
			
			nValNew := oMdlRh:GetValue("TFF_VLMTMC") // >>>> lembrar avaliar se o campo _codsub já foi preenchido neste momento
			nValOld := If( lBuscaAnt, At870OldValue( "TFF", cContrt, oMdlRH:GetValue("TFF_ITEM"), oMdlRH:GetValue("TFF_PRODUT"), oMdlRH:GetValue("TFF_COD"), "3"  ),0)
	
			aAdd( aItens, { oMdlRh:GetValue("TFF_ITEM"), ; //1
							oMdlRh:GetValue("TFF_PDMTMC"),; //2
							cPlanRH, ;						//3
							oMdlRh:GetValue("TFF_ITCCNB"),;	//4
							nValNew, ;						//5
							nValOld, ;						//6
							1, ;							//7
							"MC",;							//8
							"1" ,;							//9
							"",;							//10
							oMdlRh:GetValue("TFF_PRODUT")} )//11
		
		EndIf
	EndIf
	
	//  pesquisa e adiciona os materiais caso não seja orçamento com precificação
	If !lOrcPrc 
		If cNumPlan == cPlanMI .AND. oMdlRh:GetValue("TFF_TOTMI")> 0 
			At870GetMats( aItens, oMdlMI, oMdlMC, lBuscaAnt, cContrt, cPlanMI, "" , oMdlRh:GetValue("TFF_ITEM"),oMdlRh:GetValue("TFF_PRODUT"))
		EndIf
		
		If cNumPlan == cPlanMC .and. oMdlRh:GetValue("TFF_TOTMC")> 0 
			At870GetMats( aItens, oMdlMI, oMdlMC, lBuscaAnt, cContrt, "", cPlanMC, oMdlRh:GetValue("TFF_ITEM"), oMdlRh:GetValue("TFF_PRODUT"))
		EndIf
	EndIf

Next nX


//  pesquisa e adiciona os materiais caso seja orçamento com precificação
If lOrcPrc 
	If cNumPlan == cPlanMI 
		At870GetMats( aItens, oMdlMI, oMdlMC, lBuscaAnt, cContrt, cPlanMI, "", "","" )
	EndIf
	
	If cNumPlan == cPlanMC 
		At870GetMats( aItens, oMdlMI, oMdlMC, lBuscaAnt, cContrt, "", cPlanMC, "","" )
	EndIf
EndIf

// percorre os itens de locação de equipamentos
If cNumPlan == cPlanLE
	For nX := 1 To oMdlLE:Length()
		oMdlLE:GoLine(nX)
	
		If !Empty( oMdlLE:GetValue("TFI_PRODUT") )
	
			nValNew := oMdlLE:GetValue("TFI_TOTAL")
			nValOld := If( lBuscaAnt, At870OldValue( "TFI", cContrt, oMdlLE:GetValue("TFI_ITEM"), oMdlLE:GetValue("TFI_PRODUT"), oMdlLE:GetValue("TFI_COD") ),;
									0 )
	
			aAdd( aItens, { oMdlLE:GetValue("TFI_ITEM"), ; //1
							oMdlLE:GetValue("TFI_PRODUT"), ; //2
							cPlanLE , ; 					//3
							oMdlLE:GetValue("TFI_ITCNB"),;//4
							nValNew, ;						//5
							nValOld,;						//6
							oMdlLE:GetValue("TFI_QTDVEN"), ;//7
							"LE", ;							//8
							Iif(oMdlLE:GetValue("TFI_ENCE") == "1" ,"2","1" ) ,;//9
							"",; //10	
							""} )//11
		EndIf
	Next nX
EndIf

FwRestRows(aSaveRows,oModel)

Return aClone(aItens)

/*/{Protheus.doc} At870GetMats
@description 	Adiciona os itens de materiais, em função separada para ter a chamado com e sem precificação
@since 			18.11.2016
@version 		12
@param 			aItens, Array, dados para uso posterior na atualização da planilha/itens do contrato
@param 			oMdlMI, Objeto, parte do modelo de dados de material de implantação do orçamento de serviços
@param 			oMdlMC, Objeto, parte do modelo de dados de material de consumo do orçamento de serviços
@param 			lBuscaAnt, Lógico, indica se deve ou não pesquisar por valores anteriores dentro
@param 			cContrt, Caracter, Número do contrato ter as informações de materiais resgatadas
/*/
Static Function At870GetMats( aItens, oMdlMI, oMdlMC, lBuscaAnt, cContrt, cPlanMI, cPlanMC, cItemRH,cProdRH )
Local nY := 0
Local nValNew := 0
Local nValOld := 0

// itens que formam o orçamento de serviços
// considerar também se o item deve ou não ser faturado dentro do contrato

// percorre os itens de materiais de implantação
If !Empty(cPlanMI)
	For nY := 1 To oMdlMI:Length()
		oMdlMI:GoLine(nY)
	
		If !Empty( oMdlMI:GetValue("TFG_PRODUT") ) .And. oMdlMI:GetValue("TFG_COBCTR") <> "2"
			nValNew := oMdlMI:GetValue("TFG_TOTGER")
			nValOld := If( lBuscaAnt, At870OldValue( "TFG", cContrt, oMdlMI:GetValue("TFG_ITEM"), oMdlMI:GetValue("TFG_PRODUT"), oMdlMI:GetValue("TFG_COD") ),;
									0 )
	
			aAdd( aItens, { oMdlMI:GetValue("TFG_ITEM"), ; //1
							oMdlMI:GetValue("TFG_PRODUT"), ; //2
							cPlanMI ,;						//3
							oMdlMI:GetValue("TFG_ITCNB"),;	//4
							nValNew, ;						//5
							nValOld,;						//6
							oMdlMI:GetValue("TFG_QTDVEN"), ; //7
							"MI", ;							//8
							"1", ;							//9
							cItemRH,;						//10
							cProdRH } )						//11
	
		EndIf
	Next nY
EndIf
// percorre os itens de materiais de consumo
If !Empty(cPlanMC)
	For nY := 1 To oMdlMC:Length()
		oMdlMC:GoLine(nY)
	
		If !Empty( oMdlMC:GetValue("TFH_PRODUT") ) .And. oMdlMC:GetValue("TFH_COBCTR") <> "2"
			nValNew := oMdlMC:GetValue("TFH_TOTGER")
			nValOld := If( lBuscaAnt, At870OldValue( "TFH", cContrt, oMdlMC:GetValue("TFH_ITEM"), oMdlMC:GetValue("TFH_PRODUT"), oMdlMC:GetValue("TFH_COD") ),;
									0 )
	
			aAdd( aItens, { oMdlMC:GetValue("TFH_ITEM"), ;
							oMdlMC:GetValue("TFH_PRODUT"), ;
							cPlanMC ,;
							oMdlMC:GetValue("TFH_ITCNB"),;
							nValNew, ;
							nValOld,;
							oMdlMc:GetValue("TFH_QTDVEN"), ;
							"MC",;
							 "1", ; 
							cItemRH,;	
							cProdRH } )		
	
		EndIf
	Next nY
EndIf

Return .T.

/*/{Protheus.doc} At870OldValue
@description 	Busca o valor anterior de um item dos conceitos de produtos RH, MI, MC e LE
@since 			18.11.2016
@version 		12
@param 			cTab, Caracter, tabela a ter o registro pesquisado
@param 			cContrato, Caracter, número do contrato que o registro está vinculado
@param 			cItem, Caracter, posição do item no aba/tabela pesquisada
@param 			cProd, Caracter, código do produto a ser pesquisado
@param 			cCodAtual, Caracter, código atual para comparar com o campo _CODSUB das tabelas
@param 			cTipoMat, Caracter, codigo para definir tipo de produto, RH, MI ou MC quando os materiais forem por valor ou percentual
@return 		Numérico, valor total do item pesquisado
/*/
Static Function At870OldValue( cTab, cContrato, cItem, cProd, cCodAtual, cTipoMat )

Local cQry := ""
Local nOldValue := 0
Local cTabTemp  := GetNextAlias()

Default cTipoMat:= "1" // RH

/*Importante o paramentro cTipoMat só deverá ser usado quando os materiais forem listados na TFF*/

cQry := "SELECT * "
cQry += "FROM "+RetSqlName(cTab)+" "+cTab+" "
cQry += "WHERE "+cTab+"_FILIAL = '"+xFilial(cTab)+"' "
cQry += 	"AND "+cTab+"_CONTRT = '"+cContrato+"' "
cQry += 	"AND "+cTab+"_ITEM = '"+cItem+"' "
cQry += 	"AND "+cTab+"_PRODUT = '"+cProd+"' "
cQry += 	"AND "+cTab+"_CODSUB = '"+cCodAtual+"' "
cQry += 	"AND "+cTab+".D_E_L_E_T_=' '"
// >>>> lembrar avaliar se o campo _codsub já foi preenchido neste momento
cQry := ChangeQuery(cQry)
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cTabTemp,.T.,.T.)

If (cTabTemp)->(!EOF())
	If cTab == "TFF"
		If cTipoMat == "1"
			nOldValue := ( (cTabTemp)->TFF_QTDVEN * (cTabTemp)->TFF_PRCVEN ) - (cTabTemp)->TFF_VALDES + (cTabTemp)->TFF_TXADM + (cTabTemp)->TFF_TXLUCR
		ElseIf cTipoMat == "2"
		 	nOldValue :=  (cTabTemp)->TFF_VLMTMI
		Else
			nOldValue :=  (cTabTemp)->TFF_VLMTMC
		Endif
	ElseIf cTab == "TFG"
		nOldValue := ( (cTabTemp)->TFG_QTDVEN * (cTabTemp)->TFG_PRCVEN ) - (cTabTemp)->TFG_VALDES + (cTabTemp)->TFG_TXADM + (cTabTemp)->TFG_TXLUCR
	ElseIf cTab == "TFH"
		nOldValue := ( (cTabTemp)->TFH_QTDVEN * (cTabTemp)->TFH_PRCVEN) - (cTabTemp)->TFH_VALDES + (cTabTemp)->TFH_TXADM + (cTabTemp)->TFH_TXLUCR
	ElseIf cTab == "TFI"
		nOldValue := (cTabTemp)->TFI_TOTAL
	EndIf
EndIf

(cTab)->(DbCloseArea())

Return nOldValue

//-------------------------------------------------------------------------------------
/*/{Protheus.doc} At870RReaj()

@author       Matheus Lando Raimundo
@version      P12
/*/
//-----------------------------------------------------------------------------------------
Function At870RReaj( oMdlRev, oMdlOrc, lOrcPrc, oMdlAssist)
Local lRet 		:= .T.
Local oTFLRev 	:= oMdlRev:GetModel('TFL_LOC')
Local oTFIRev 	:= oMdlRev:GetModel('TFI_LE')
Local oTFFRev 	:= oMdlRev:GetModel('TFF_RH')
Local oTEVRev 	:= oMdlRev:GetModel('TEV_ADICIO')
Local oTFGRev	:= oMdlRev:GetModel('TFG_MI')
Local oTFHRev	:= oMdlRev:GetModel('TFH_MC')
Local aMdlTab 	:= Nil

Local oTFLOrc 	:= oMdlOrc:GetModel('TFL_LOC')
Local oTFIOrc 	:= oMdlOrc:GetModel('TFI_LE')

Local nI		:= 0
Local nJ		:= 0
Local nX		:= 0
Local aSaveRows	:= FwSaveRows()
Local lCobCtr 	:= .F.

Local oTFLassist := oMdlAssist:GetModel("TFLDETAIL")
Local oTFFassist := oMdlAssist:GetModel("TFFDETAIL")
Local oTV7assist := oMdlAssist:GetModel("TV7DETAIL")
Local oTFIassist := oMdlAssist:GetModel("TFIDETAIL")
Local oTEVassist := oMdlAssist:GetModel("TEVDETAIL")

Local nMdlTemp	:= 0
Local nTotAbas  := 0
Local cFldTab 	:= ""
Local cModoFld	:= ""
Local aAllModels := oMdlRev:GetAllSubModels()

For nX := 1 To oTFLRev:Length()
	oTFLRev:GoLine(nX)
	oTFLOrc:GoLine(nX)
	oTFLassist:GoLine(nX)

	//-- Data do Local de atendimento
	lRet := lRet .And. oTFLRev:SetValue('TFL_DTFIM', oTFLRev:GetValue('TFL_DTFIM') + oTFLassist:GetValue("TFL_PRAZO"))

	//-- Data e valor do RH
	If  lRet .And. !oTFFRev:IsEmpty()
		For nI := 1 To oTFFRev:Length()
			oTFFRev:GoLine(nI)
			oTFFassist:GoLine(nI)

			lCobCtr := oTFFRev:GetValue("TFF_COBCTR") <> "2"
			// não atualiza itens não pertencentes ao contrato e nem itens calculados com planilha de preço
			If  lRet .And. lCobCtr .And. Empty(oTFFRev:GetValue("TFF_CALCMD"))
				If lOrcPrc
					nMdlTemp := 1
					aMdlTab := {}
					// copia os modelos de dados dos fields da precificação
					While nMdlTemp <= Len(aAllModels)
						If "RH0" $ aAllModels[nMdlTemp]:GetId()
							aAdd( aMdlTab, aAllModels[nMdlTemp])
						EndIf
						nMdlTemp += 1
					End
					
					If (( nTotAbas := Len(aMdlTab) ) >= 1 )
						// executar a atualização nos campos dentro da tabela de precificação
						For nJ := 1 To oTV7assist:Length()
							oTV7assist:GoLine(nJ)
							cFldTab := RTrim(oTV7assist:GetValue("TV7_IDENT"))
							cModoFld := RTrim(oTV7assist:GetValue("TV7_MODO"))
							nMdlTemp := 1
							While nMdlTemp <= nTotAbas
								// verifica qual modelo possui o campo para atualização do valor
								If aMdlTab[nMdlTemp]:HasField(cFldTab) // verificar coluna de nome do campo
									Exit
								Else
									nMdlTemp += 1
								EndIf
							End

							If nMdlTemp <= nTotAbas 
								If cModoFld == '1'
									lRet := lRet .And. aMdlTab[nMdlTemp]:SetValue( cFldTab, oTV7assist:GetValue("TV7_VLRNEW") )
								EndIf	
							Else
								lRet := .F.
								oMdlRev:SetErrorMessage(oMdlRev:GetId(),"TFF_COD",oMdlRev:GetId(), "TFF_COD",cFldTab,; 
											STR0208, STR0209 )  // "Campo da tabela de precificação não encontrado na estrutura do modelo de dados." ### "Verifique a tabela e revisão associada a este orçamento de serviços."
								Exit
							EndIf
						Next nJ
					Else
						lRet := .F.
						oMdlRev:SetErrorMessage(oMdlRev:GetId(),"TFF_COD",oMdlRev:GetId(), "TFF_COD", "RH***",; 
									STR0210, STR0209 ) // "Os modelos da tabela de precificação não carregaram corretamente." ### "Verifique a tabela e revisão associada a este orçamento de serviços."
						Exit
					EndIf
				Else
					lRet := lRet .And. oTFFRev:SetValue('TFF_PRCVEN', oTFFassist:GetValue("TFF_VLRNEW") )
					lRet := lRet .And. oTFFRev:SetValue('TFF_PERFIM', oTFFRev:GetValue('TFF_PERFIM') + oTFFassist:GetValue("TFF_PRAZO"))
				EndIf
			EndIf

			If lRet .And. !lOrcPrc .And. lCobCtr
				lRet := lRet .And. At870RRjMt( oTFGRev, oTFHRev, oMdlAssist, oTFJRev )
			EndIf
		Next nI
	EndIf
	// atualiza os materias de implantação e consumo
	If lRet .And. lOrcPrc
		lRet := lRet .And. At870RRjMt( oTFGRev, oTFHRev, oMdlAssist, oTFJRev )
	EndIf
	// -- Data e Valor locação de equipamentos
	If lRet .And. !oTFIRev:IsEmpty()
		For nI := 1 To oTFIRev:Length()
			oTFIRev:GoLine(nI)
			oTFIOrc:GoLine(nI)
			oTFIassist:GoLine(nI)
			//-- Não aplicar itens que ja voltaram e não aplicar em itens calculados por planilha de preço
			If At870QtRet(oTFIOrc:GetValue('TFI_COD')) < oTFIRev:GetValue('TFI_QTDVEN') .And. Empty( oTFIRev:GetValue("TFI_CALCMD") )
				lRet := lRet .And. oTFIRev:SetValue('TFI_PERFIM', oTFIRev:GetValue('TFI_PERFIM') + oTFIassist:GetValue("TFI_PRAZO"))
				For nJ := 1 To oTEVRev:Length()
					oTEVRev:GoLine(nJ)
					oTEVassist:GoLine(nJ)
					//-- Não aplicar mobilização
					If oTEVRev:GetValue('TEV_MODCOB') <> '3'
						lRet := lRet .And. oTEVRev:SetValue('TEV_VLRUNI', oTEVassist:GetValue("TEV_VLRNEW") )
					EndIf
				Next nJ
			EndIf
		Next nI
	EndIf
Next nX

FwRestRows(aSaveRows)

Return lRet

/*/{Protheus.doc} At870RRjMt
	Atualiza as informações de valores e quantidade de dias dos itens de materiais
@author       josimar.assuncao
@version      P12
@param 		oTFGRev, objeto fwformgridmodel, modelo da dados da tabela TFG
@param 		oTFHRev, objeto fwformgridmodel, modelo de dados da tabela TFH
@param 		nPerc, numérico, valor para acrescentar em percentual ao item
@param 		nDias, numérico, quantidade de dias para acrescentar ao prazo
@return 	Lógico, determina se a atualização aconteceu com sucesso ou não
/*/
Static Function At870RRjMt( oTFGRev, oTFHRev, oMdlAssist, oTFJRev )
Local lRet := .T.
Local nJ := 0
Local oTFGassist := oMdlAssist:GetModel("TFGDETAIL")
Local oTFHassist := oMdlAssist:GetModel("TFHDETAIL")

If oTFJRev:GetValue("TFJ_ISGSMT") == "1"
	If !(oTFJRev:GetValue('TFJ_GSMTMI') $ "2/3")
		If !oTFGRev:IsEmpty()
			For nJ := 1 To oTFGRev:Length()
				oTFGRev:GoLine(nJ)
				// não atualiza itens fora do contrato
				If oTFGRev:GetValue('TFG_COBCTR') <> "2"
					lRet := lRet .And. oTFGRev:SetValue('TFG_PRCVEN', oTFGassist:GetValue("TFG_VLRNEW") )
					lRet := lRet .And. oTFGRev:SetValue('TFG_PERFIM', oTFGRev:GetValue('TFG_PERFIM') + oTFGassist:GetValue("TFG_PRAZO"))
				EndIf
			Next nJ
		EndIf
	Endif
	If !(oTFJRev:GetValue('TFJ_GSMTMC') $ "2/3")
		If lRet .And. !oTFHRev:IsEmpty()
			For nJ := 1 To oTFHRev:Length()
				oTFHRev:GoLine(nJ)
				// não atualiza itens fora do contrato
				If oTFHRev:GetValue('TFH_COBCTR') <> "2"
					lRet := lRet .And. oTFHRev:SetValue('TFH_PRCVEN', oTFHassist:GetValue("TFH_VLRNEW") )
					lRet := lRet .And. oTFHRev:SetValue('TFH_PERFIM', oTFHRev:GetValue('TFH_PERFIM') + oTFHassist:GetValue("TFH_PRAZO"))
				EndIf
			Next nJ
		EndIf
	Endif
Else	
	If !(oTFJRev:GetValue('TFJ_GESMAT') $ "2/3")
		If !oTFGRev:IsEmpty()
			For nJ := 1 To oTFGRev:Length()
				oTFGRev:GoLine(nJ)
				// não atualiza itens fora do contrato
				If oTFGRev:GetValue('TFG_COBCTR') <> "2"
					lRet := lRet .And. oTFGRev:SetValue('TFG_PRCVEN', oTFGassist:GetValue("TFG_VLRNEW") )
					lRet := lRet .And. oTFGRev:SetValue('TFG_PERFIM', oTFGRev:GetValue('TFG_PERFIM') + oTFGassist:GetValue("TFG_PRAZO"))
				EndIf
			Next nJ
		EndIf
		If lRet .And. !oTFHRev:IsEmpty()
			For nJ := 1 To oTFHRev:Length()
				oTFHRev:GoLine(nJ)
				// não atualiza itens fora do contrato
				If oTFHRev:GetValue('TFH_COBCTR') <> "2"
					lRet := lRet .And. oTFHRev:SetValue('TFH_PRCVEN', oTFHassist:GetValue("TFH_VLRNEW") )
					lRet := lRet .And. oTFHRev:SetValue('TFH_PERFIM', oTFHRev:GetValue('TFH_PERFIM') + oTFHassist:GetValue("TFH_PRAZO"))
				EndIf
			Next nJ
		EndIf
	Endif
Endif

Return lRet

//-------------------------------------------------------------------------------------
/*/{Protheus.doc} At870QtRet()

@author       Matheus Lando Raimundo
@version      P12
/*/
//-----------------------------------------------------------------------------------------
Function At870QtRet(cCodTFI)
Local cAliasQry := GetNextAlias()
Local nRet		  := 0

BeginSQL Alias cAliasQry
	SELECT SUM(TWP_QTDRET) TWP_QTDRET FROM %Table:TEW% TEW
		INNER JOIN %Table:TWP% TWP ON
			TWP.TWP_FILIAL = %xFilial:TWP%
			AND TWP.%notDel%
			AND TWP.TWP_IDREG = TEW.TEW_CODMV
		WHERE  TEW.TEW_FILIAL = %xFilial:TEW%
			AND TEW.%notDel%
			AND TEW.TEW_CODEQU = %Exp:cCodTFI%
			AND TEW.TEW_TIPO = '1'
EndSql

nRet := ((cAliasQry)->TWP_QTDRET)
(cAliasQry)->(DbCloseArea())

Return nRet

/*/{Protheus.doc} At870ItAgr
@description 	Atualizar os dados na CNB quando o contrato está com a definição para gerar os itens de forma agrupada
@since 			18.11.2016
@version 		12
/*/
Static Function At870ItAgr( oMdlTFJ, oMdlTFL, oMdlCNB, cPedTit,;
							nTotRHold, nTotRHnew, nTotMIold, nTotMInew,;
							nTotMCold, nTotMCnew, nTotLEold, nTotLEnew,;
							cNumPlan, cLocCCusto )
Local lAvalTFGCNB 	:= .T.
Local lAvalTFHCNB 	:= .T.
Local lAvalTFICNB 	:= .T.
Local lRet 			:= .T.
Local aAux 			:= {}
Local nTotalOld 	:= 0
Local nTotalNew 	:= 0
Local cItemCNB 		:= ""
Local aAreaSB1		:= {}
Local cFilSB1		:=  xFilial("SB1")

If lPedISS == NIL
	lPedIss		:=  CNB->(TamSx3("CNB_IDPED")[1]) >=  SB1->(TamSx3("B1_CODISS")[1]) .AND. CNE->(TamSx3("CNE_IDPED")[1]) >=  SB1->(TamSx3("B1_CODISS")[1]) //CNB_IDPED
EndIf

If lPedISS
	aAreaSB1		:=  SB1->(GetArea())
	SB1->(DbSetOrder(1))
EndIf

// POSICIONAR NO ITEM DE RH
If !Empty(oMdlTFL:GetValue("TFL_ITPLRH"))
	If oMdlCNB:SeekLine({{"CNB_ITEM", oMdlTFL:GetValue("TFL_ITPLRH")}})

		// calcula o valor de outros conceitos de produtos que apontam para o mesmo item
		nTotalOld := nTotRHold
		nTotalNew := nTotRHnew

		// Verifica e soma o total dos materiais de implantação
		If oMdlTFL:GetValue("TFL_ITPLMI") == oMdlTFL:GetValue("TFL_ITPLRH")
			nTotalOld += nTotMIold
			nTotalNew += nTotMInew
			lAvalTFGCNB := .F.
		EndIf

		// Verifica e soma o total dos materiais de implantação
		If oMdlTFL:GetValue("TFL_ITPLMC") == oMdlTFL:GetValue("TFL_ITPLRH")
			nTotalOld += nTotMCold
			nTotalNew += nTotMCnew
			lAvalTFHCNB := .F.
		EndIf

		// Verifica e soma o total dos materiais de implantação
		If oMdlTFL:GetValue("TFL_ITPLLE") == oMdlTFL:GetValue("TFL_ITPLRH")
			nTotalOld += nTotLEold
			nTotalNew += nTotLEnew
			lAvalTFICNB := .F.
		EndIf

		// função para atualizar os dados da CNB
		lRet := lRet .And. At870CNBUpd( oMdlCNB, nTotalOld, nTotalNew )
		lRet := lRet .And. oMdlCNB:VldLineData()
		// atualiza o item da CNB caso tenha diferença entre o inicial e o novo item
		If lRet .And. oMdlTFL:GetValue("TFL_ITPLRH") <> oMdlCNB:GetValue("CNB_ITEM")
			lRet := lRet .And. oMdlTFL:SetValue("TFL_ITPLRH", oMdlCNB:GetValue("CNB_ITEM"))

			If !lAvalTFGCNB
				lRet := lRet .And. oMdlTFL:SetValue("TFL_ITPLMI", oMdlCNB:GetValue("CNB_ITEM"))
			EndIf

			If !lAvalTFHCNB
				lRet := lRet .And. oMdlTFL:SetValue("TFL_ITPLMC", oMdlCNB:GetValue("CNB_ITEM"))
			EndIf

			If !lAvalTFICNB
				lRet := lRet .And. oMdlTFL:SetValue("TFL_ITPLLE", oMdlCNB:GetValue("CNB_ITEM"))
			EndIf
		EndIf

		If !lRet
			Help( "", 1, "At870AGR_RH", , STR0174, 1, 0,,,,,,;  // "Problemas ao atualizar o item de RH na revisão."
					{STR0175})  // "Verifique os valores informados para os produtos de Recursos Humanos."
			If oMdlCNB:GetModel():HasErrorMessage()
				AtErroMvc( oMdlCNB:GetModel() )
				MostraErro()
			EndIf
			If oMdlTFL:GetModel():HasErrorMessage()
				AtErroMvc( oMdlTFL:GetModel() )
				MostraErro()
			EndIf
		EndIf

	Else
		lRet := .F.
		Help( "", 1, "At870NOITEM_RH", , STR0176, 1, 0,,,,,,;  // "Item do agrupamento de Recursos Humanos não existe no contrato."
					{STR0177})  // "Verifique se o campo TFL_ITPLRH tem conteúdo correspondente com o campo CNB_ITEM no contrato."
	EndIf
ElseIf nTotRHnew > 0

	If lPedISS
		aAreaSB1		:=  SB1->(GetArea())
		SB1->(DbSetOrder(1))
	EndIf
	
	// criar um novo item na planilha
	oMdlCNB:GoLine( oMdlCNB:Length() )
	cItemCNB := Soma1(oMdlCNB:GetValue("CNB_ITEM"))

	nTotalNew := nTotRHnew
	//----------------------------------------------------
	// Verifica se o código dos produtos são iguais para agrupar o valor em um único item
	If lAvalTFGCNB .And. oMdlTFJ:GetValue("TFJ_GRPRH") == oMdlTFJ:GetValue("TFJ_GRPMI")
		lAvalTFGCNB := .F.
		nTotalNew += nTotMInew
	EndIf

	If lAvalTFHCNB .And. oMdlTFJ:GetValue("TFJ_GRPRH") == oMdlTFJ:GetValue("TFJ_GRPMC")
		lAvalTFHCNB := .F.
		nTotalNew += nTotMCnew
	EndIf

	If lAvalTFICNB .And. oMdlTFJ:GetValue("TFJ_GRPRH") == oMdlTFJ:GetValue("TFJ_GRPLE")
		lAvalTFICNB := .F.
		nTotalNew += nTotLEnew
	EndIf
	//----------------------------------------------------
	aAux := {}
	Aadd(aAux ,{"CNB_ITEM"  , cItemCNB } )
	Aadd(aAux ,{"CNB_NUMERO", cNumPlan } )
	Aadd(aAux ,{"CNB_PRODUT", oMdlTFJ:GetValue("TFJ_GRPRH") } )
	Aadd(aAux ,{"CNB_QUANT" , 1 })
	Aadd(aAux ,{"CNB_VLUNIT", nTotalNew } )
	Aadd(aAux ,{"CNB_TS"    , oMdlTFJ:GetValue("TFJ_TES") })
	Aadd(aAux ,{"CNB_PEDTIT", cPedTit })
	If !Empty(cLocCCusto)
		Aadd(aAux ,{"CNB_CC", cLocCCusto })
	EndIf
	
	If lPedIss .AND. SB1->(DbSeek(cFilSB1 + oMdlTFJ:GetValue("TFJ_GRPRH")))
		Aadd(aAux,{"CNB_IDPED", SB1->B1_CODISS,      NIL})
	EndIf
								

	lRet := lRet .And. At870CNBAdd( oMdlCNB, aAux )
	lRet := lRet .And. oMdlCNB:VldLineData()

	lRet := lRet .And. oMdlTFL:SetValue("TFL_ITPLRH", cItemCNB)

	If !lRet
		Help( "", 1, "At870AGR_ADD_RH", , STR0178, 1, 0,,,,,,; // "Problemas ao incluir um item de RH na revisão."
				{STR0179}) // "Verifique se a revisão permite a inclusão de novas linhas no contrato."
		If oMdlCNB:GetModel():HasErrorMessage()
			AtErroMvc( oMdlCNB:GetModel() )
			MostraErro()
		EndIf
		If oMdlTFL:GetModel():HasErrorMessage()
			AtErroMvc( oMdlTFL:GetModel() )
			MostraErro()
		EndIf
	Else
		//----------------------------------------------------
		// caso não vá mais fazer avaliação do conceito de produto faz a atualização do item
		If !lAvalTFGCNB
			lRet := lRet .And. oMdlTFL:SetValue("TFL_ITPLMI", cItemCNB)
		EndIf

		If !lAvalTFHCNB
			lRet := lRet .And. oMdlTFL:SetValue("TFL_ITPLMC", cItemCNB)
		EndIf

		If !lAvalTFICNB
			lRet := lRet .And. oMdlTFL:SetValue("TFL_ITPLLE", cItemCNB)
		EndIf
		//----------------------------------------------------
	EndIf


	If lPedISS
		REstArea(aAreaSB1)
	EndIf
	aSize( aAux, 0 )
	aAux := Nil
EndIf

// POSICIONAR NO ITEM DE MI
If lRet .And. lAvalTFGCNB
	If !Empty(oMdlTFL:GetValue("TFL_ITPLMI"))
		If oMdlCNB:SeekLine({{"CNB_ITEM", oMdlTFL:GetValue("TFL_ITPLMI")}})

			// calcula o valor de outros conceitos de produtos que apontam para o mesmo item
			nTotalOld := nTotMIold
			nTotalNew := nTotMInew

			// Verifica e soma o total dos materiais de implantação
			If oMdlTFL:GetValue("TFL_ITPLMC") == oMdlTFL:GetValue("TFL_ITPLMI")
				nTotalOld += nTotMCold
				nTotalNew += nTotMCnew
				lAvalTFHCNB := .F.
			EndIf

			// Verifica e soma o total dos materiais de implantação
			If oMdlTFL:GetValue("TFL_ITPLLE") == oMdlTFL:GetValue("TFL_ITPLMI")
				nTotalOld += nTotLEold
				nTotalNew += nTotLEnew
				lAvalTFICNB := .F.
			EndIf

			// função para atualizar os dados da CNB
			lRet := lRet .And. At870CNBUpd( oMdlCNB, nTotalOld, nTotalNew )
			lRet := lRet .And. oMdlCNB:VldLineData()
			// atualiza o item da CNB caso tenha diferença entre o inicial e o novo item
			If lRet .And. oMdlTFL:GetValue("TFL_ITPLMI") <> oMdlCNB:GetValue("CNB_ITEM")
				lRet := lRet .And. oMdlTFL:SetValue("TFL_ITPLMI", oMdlCNB:GetValue("CNB_ITEM"))

				If !lAvalTFHCNB
					lRet := lRet .And. oMdlTFL:SetValue("TFL_ITPLMC", oMdlCNB:GetValue("CNB_ITEM"))
				EndIf

				If !lAvalTFICNB
					lRet := lRet .And. oMdlTFL:SetValue("TFL_ITPLLE", oMdlCNB:GetValue("CNB_ITEM"))
				EndIf
			EndIf

			If !lRet
				Help( "", 1, "At870AGR_MI", , STR0180, 1, 0,,,,,,; // "Problemas ao atualizar o item de MI na revisão."
						{STR0181}) // "Verifique os valores informados para os produtos de Materiais de Implantação."
				If oMdlCNB:GetModel():HasErrorMessage()
					AtErroMvc( oMdlCNB:GetModel() )
					MostraErro()
				EndIf
				If oMdlTFL:GetModel():HasErrorMessage()
					AtErroMvc( oMdlTFL:GetModel() )
					MostraErro()
				EndIf
			EndIf

		Else
			lRet := .F.
			Help( "", 1, "At870NOITEM_MI", , STR0182, 1, 0,,,,,,; // "Item do agrupamento de Materiais de Implantação não existe no contrato."
						{STR0183}) // "Verifique se o campo TFL_ITPLMI tem conteúdo correspondente com o campo CNB_ITEM no contrato."
		EndIf
	ElseIf nTotMInew > 0
		// criar um novo item na planilha
		oMdlCNB:GoLine( oMdlCNB:Length() )
		cItemCNB := Soma1(oMdlCNB:GetValue("CNB_ITEM"))

		nTotalNew := nTotMInew
		//----------------------------------------------------
		// Verifica se o código dos produtos são iguais para agrupar o valor em um único item
		If lAvalTFHCNB .And. oMdlTFJ:GetValue("TFJ_GRPMI") == oMdlTFJ:GetValue("TFJ_GRPMC")
			lAvalTFHCNB := .F.
			nTotalNew += nTotMCnew
		EndIf

		If lAvalTFICNB .And. oMdlTFJ:GetValue("TFJ_GRPMI") == oMdlTFJ:GetValue("TFJ_GRPLE")
			lAvalTFICNB := .F.
			nTotalNew += nTotLEnew
		EndIf
		//----------------------------------------------------

		aAux := {}
		Aadd(aAux ,{"CNB_ITEM"  , cItemCNB } )
		Aadd(aAux ,{"CNB_NUMERO", cNumPlan } )
		Aadd(aAux ,{"CNB_PRODUT", oMdlTFJ:GetValue("TFJ_GRPMI") } )
		Aadd(aAux ,{"CNB_QUANT" , 1 })
		Aadd(aAux ,{"CNB_VLUNIT", nTotalNew } )
		Aadd(aAux ,{"CNB_TS"    , oMdlTFJ:GetValue("TFJ_TESMI") })
		Aadd(aAux ,{"CNB_PEDTIT", cPedTit })
		If !Empty(cLocCCusto)
			Aadd(aAux ,{"CNB_CC", cLocCCusto })
		EndIf

		lRet := lRet .And. At870CNBAdd( oMdlCNB, aAux )
		lRet := lRet .And. oMdlCNB:VldLineData()

		lRet := lRet .And. oMdlTFL:SetValue("TFL_ITPLMI", cItemCNB)

		If !lRet
			Help( "", 1, "At870AGR_ADD_MI", , STR0184, 1, 0,,,,,,; // "Problemas ao incluir um item de MI na revisão."
					{STR0185}) // "Verifique se a revisão permite a inclusão de novas linhas no contrato."
			If oMdlCNB:GetModel():HasErrorMessage()
				AtErroMvc( oMdlCNB:GetModel() )
				MostraErro()
			EndIf
			If oMdlTFL:GetModel():HasErrorMessage()
				AtErroMvc( oMdlTFL:GetModel() )
				MostraErro()
			EndIf
		Else
			//----------------------------------------------------
			// caso não vá mais fazer avaliação do conceito de produto faz a atualização do item
			If !lAvalTFHCNB
				lRet := lRet .And. oMdlTFL:SetValue("TFL_ITPLMC", cItemCNB)
			EndIf

			If !lAvalTFICNB
				lRet := lRet .And. oMdlTFL:SetValue("TFL_ITPLLE", cItemCNB)
			EndIf
			//----------------------------------------------------
		EndIf

		aSize( aAux, 0 )
		aAux := Nil
	EndIf
EndIf

// POSICIONAR NO ITEM DE MC
If lRet .And. lAvalTFHCNB
	If !Empty(oMdlTFL:GetValue("TFL_ITPLMC"))
		If oMdlCNB:SeekLine({{"CNB_ITEM", oMdlTFL:GetValue("TFL_ITPLMC")}})

			// calcula o valor de outros conceitos de produtos que apontam para o mesmo item
			nTotalOld := nTotMCold
			nTotalNew := nTotMCnew

			// Verifica e soma o total dos materiais de consumo
			If oMdlTFL:GetValue("TFL_ITPLLE") == oMdlTFL:GetValue("TFL_ITPLMC")
				nTotalOld += nTotLEold
				nTotalNew += nTotLEnew
				lAvalTFICNB := .F.
			EndIf

			// função para atualizar os dados da CNB
			lRet := lRet .And. At870CNBUpd( oMdlCNB, nTotalOld, nTotalNew )
			lRet := lRet .And. oMdlCNB:VldLineData()
			// atualiza o item da CNB caso tenha diferença entre o inicial e o novo item
			If lRet .And. oMdlTFL:GetValue("TFL_ITPLMC") <> oMdlCNB:GetValue("CNB_ITEM")
				lRet := lRet .And. oMdlTFL:SetValue("TFL_ITPLMC", oMdlCNB:GetValue("CNB_ITEM"))

				If !lAvalTFICNB
					lRet := lRet .And. oMdlTFL:SetValue("TFL_ITPLLE", oMdlCNB:GetValue("CNB_ITEM"))
				EndIf
			EndIf

			If !lRet
				Help( "", 1, "At870AGR_MC", , STR0186, 1, 0,,,,,,;  // "Problemas ao atualizar o item de MC na revisão."
						{STR0187}) // "Verifique os valores informados para os produtos de Materiais de Consumo."
				If oMdlCNB:GetModel():HasErrorMessage()
					AtErroMvc( oMdlCNB:GetModel() )
					MostraErro()
				EndIf
				If oMdlTFL:GetModel():HasErrorMessage()
					AtErroMvc( oMdlTFL:GetModel() )
					MostraErro()
				EndIf
			EndIf

		Else
			lRet := .F.
			Help( "", 1, "At870NOITEM_MC", , STR0188, 1, 0,,,,,,; // "Item do agrupamento de Materiais de Consumo não existe no contrato."
						{STR0189}) // "Verifique se o campo TFL_ITPLMC tem conteúdo correspondente com o campo CNB_ITEM no contrato."
		EndIf
	ElseIf nTotMCnew > 0
		// criar um novo item na planilha
		oMdlCNB:GoLine( oMdlCNB:Length() )
		cItemCNB := Soma1(oMdlCNB:GetValue("CNB_ITEM"))

		nTotalNew := nTotMCnew
		//----------------------------------------------------
		// Verifica se o código dos produtos são iguais para agrupar o valor em um único item
		If lAvalTFICNB .And. oMdlTFJ:GetValue("TFJ_GRPMC") == oMdlTFJ:GetValue("TFJ_GRPLE")
			lAvalTFICNB := .F.
			nTotalNew += nTotLEnew
		EndIf
		//----------------------------------------------------

		aAux := {}
		Aadd(aAux ,{"CNB_ITEM"  , cItemCNB } )
		Aadd(aAux ,{"CNB_NUMERO", cNumPlan } )
		Aadd(aAux ,{"CNB_PRODUT", oMdlTFJ:GetValue("TFJ_GRPMC") } )
		Aadd(aAux ,{"CNB_QUANT" , 1 })
		Aadd(aAux ,{"CNB_VLUNIT", nTotalNew } )
		Aadd(aAux ,{"CNB_TS"    , oMdlTFJ:GetValue("TFJ_TESMC") })
		Aadd(aAux ,{"CNB_PEDTIT", cPedTit })
		If !Empty(cLocCCusto)
			Aadd(aAux ,{"CNB_CC", cLocCCusto })
		EndIf

		lRet := lRet .And. At870CNBAdd( oMdlCNB, aAux )
		lRet := lRet .And. oMdlCNB:VldLineData()

		lRet := lRet .And. oMdlTFL:SetValue("TFL_ITPLMC", cItemCNB)

		If !lRet
			Help( "", 1, "At870AGR_ADD_MC", , STR0190, 1, 0,,,,,,; // "Problemas ao incluir um item de MC na revisão."
					{STR0191}) // "Verifique se a revisão permite a inclusão de novas linhas no contrato."
			If oMdlCNB:GetModel():HasErrorMessage()
				AtErroMvc( oMdlCNB:GetModel() )
				MostraErro()
			EndIf
			If oMdlTFL:GetModel():HasErrorMessage()
				AtErroMvc( oMdlTFL:GetModel() )
				MostraErro()
			EndIf
		Else
			//----------------------------------------------------
			// caso não vá mais fazer avaliação do conceito de produto faz a atualização do item
			If !lAvalTFICNB
				lRet := lRet .And. oMdlTFL:SetValue("TFL_ITPLLE", cItemCNB)
			EndIf
			//----------------------------------------------------
		EndIf

		aSize( aAux, 0 )
		aAux := Nil
	EndIf
EndIf

// POSICIONAR NO TIEM DE LE
If lRet .And. lAvalTFICNB
	If !Empty(oMdlTFL:GetValue("TFL_ITPLLE"))
		If oMdlCNB:SeekLine({{"CNB_ITEM", oMdlTFL:GetValue("TFL_ITPLLE")}})

			// calcula o valor de outros conceitos de produtos que apontam para o mesmo item
			nTotalOld := nTotLEold
			nTotalNew := nTotLEnew

			// função para atualizar os dados da CNB
			lRet := lRet .And. At870CNBUpd( oMdlCNB, nTotalOld, nTotalNew )
			lRet := lRet .And. oMdlCNB:VldLineData()
			// atualiza o item da CNB caso tenha diferença entre o inicial e o novo item
			If lRet .And. oMdlTFL:GetValue("TFL_ITPLLE") <> oMdlCNB:GetValue("CNB_ITEM")
				lRet := lRet .And. oMdlTFL:SetValue("TFL_ITPLLE", oMdlCNB:GetValue("CNB_ITEM"))

			EndIf

			If !lRet
				Help( "", 1, "At870AGR_LE", , STR0192, 1, 0,,,,,,; // "Problemas ao atualizar o item de LE na revisão."
						{STR0193}) // "Verifique os valores informados para os produtos de Locação de Equipamentos."
				If oMdlCNB:GetModel():HasErrorMessage()
					AtErroMvc( oMdlCNB:GetModel() )
					MostraErro()
				EndIf
				If oMdlTFL:GetModel():HasErrorMessage()
					AtErroMvc( oMdlTFL:GetModel() )
					MostraErro()
				EndIf
			EndIf

		Else
			lRet := .F.
			Help( "", 1, "At870NOITEM_LE", , STR0194, 1, 0,,,,,,; // "Item do agrupamento de Locação de Equipamentos não existe no contrato."
						{STR0195}) // "Verifique se o campo TFL_ITPLLE tem conteúdo correspondente com o campo CNB_ITEM no contrato."
		EndIf
	ElseIf nTotLEnew > 0
		// criar um novo item na planilha
		oMdlCNB:GoLine( oMdlCNB:Length() )
		cItemCNB := Soma1(oMdlCNB:GetValue("CNB_ITEM"))

		nTotalNew := nTotLEnew

		aAux := {}
		Aadd(aAux ,{"CNB_ITEM"  , cItemCNB } )
		Aadd(aAux ,{"CNB_NUMERO", cNumPlan } )
		Aadd(aAux ,{"CNB_PRODUT", oMdlTFJ:GetValue("TFJ_GRPLE") } )
		Aadd(aAux ,{"CNB_QUANT" , 1 })
		Aadd(aAux ,{"CNB_VLUNIT", nTotalNew } )
		Aadd(aAux ,{"CNB_TS"    , oMdlTFJ:GetValue("TFJ_TESLE") })
		Aadd(aAux ,{"CNB_PEDTIT", cPedTit })
		If !Empty(cLocCCusto)
			Aadd(aAux ,{"CNB_CC", cLocCCusto })
		EndIf

		lRet := lRet .And. At870CNBAdd( oMdlCNB, aAux )
		lRet := lRet .And. oMdlCNB:VldLineData()

		lRet := lRet .And. oMdlTFL:SetValue("TFL_ITPLLE", cItemCNB)

		If !lRet
			Help( "", 1, "At870AGR_ADD_LE", , STR0196, 1, 0,,,,,,;  // "Problemas ao incluir um item de LE na revisão."
					{STR0197}) // "Verifique se a revisão permite a inclusão de novas linhas no contrato."
			If oMdlCNB:GetModel():HasErrorMessage()
				AtErroMvc( oMdlCNB:GetModel() )
				MostraErro()
			EndIf
			If oMdlTFL:GetModel():HasErrorMessage()
				AtErroMvc( oMdlTFL:GetModel() )
				MostraErro()
			EndIf
		EndIf

		aSize( aAux, 0 )
		aAux := Nil
	EndIf
EndIf

Return lRet

/*/{Protheus.doc} At870ItDsAgr
@description 	Atualizar os dados na CNB quando o contrato está com a definição para gerar os itens de forma não agrupada
@since 			18.11.2016
@version 		12
/*/
Static Function At870ItDsAgr( oModel, oMdlCNB, cContrato, lOldValues, cPedTit, cNumPlan, cLocCCusto )
Local aAux 			:= {}
Local aPrds 		:= {}
Local lRet 			:= .T.
Local nK 			:= 0
Local nTotalOld 	:= 0
Local nTotalNew 	:= 0
Local oMdlTFL 		:= oModel:GetModel("TFL_LOC")
Local oMdlTFJ 		:= oModel:GetModel("TFJ_REFER")
Local oMdlItemGS 	:= Nil
Local cCpoBusca 	:= ""
Local cCpoSet 		:= ""
Local cItemCNB 		:= ""
Local cTESCNB 		:= ""
Local cCpoTFLItem 	:= ""
Local lRecorrente	:= oMdlTFJ:GetValue("TFJ_CNTREC") == "1"
Local lGrpFatOrc	:= oMdlTFJ:GetValue("TFJ_GRPFAT") == "1"
Local cLocal		:= oMdlTFL:GetValue("TFL_LOCAL") 
Local lGsMtMi		:= TFJ->TFJ_ISGSMT == '1' .AND. TFJ->TFJ_GSMTMI $ '2|3'
Local lGsMtMc		:= TFJ->TFJ_ISGSMT == '1' .AND. TFJ->TFJ_GSMTMC $ '2|3' 
Local aAreaSB1		:= {}
Local cCodIss		:= ""
Local cFilSB1		:=  xFilial("SB1")

Default lOldValues := .T.

// quando a geração aconteceu de forma não agrupada
//   busca todos os itens com os valores anteriores e atuais
aPrds := At870AllPrds( oModel, lOldValues, cContrato, cNumPlan )

If lPedISS == NIL
	lPedISS :=  CNB->(TamSx3("CNB_IDPED")[1]) >=  SB1->(TamSx3("B1_CODISS")[1]) .AND. CNE->(TamSx3("CNE_IDPED")[1]) >=  SB1->(TamSx3("B1_CODISS")[1])
EndIf


If lPedISS
	aAreaSB1		:=  SB1->(GetArea())
	SB1->(DbSetOrder(1))
EndIf

// percorrer os itens dos conceitos de produtos Rh, Mi, Mc e Le
For nK := 1 To Len(aPrds)
	/* estrutura do array :: aPrds ::
		{
			1 = ITEM ORÇAMENTO DE SERVIÇOS,;
			2 = PRODUTO ORÇAMENTO DE SERVIÇOS,;
			3 = PLANILHA NO CONTRATO,;
			4 = ITEM NO CONTRATO,;
			5 = VALOR REVISADO (novo),;
			6 = VALOR ANTERIOR (antigo),;
			7 = QUANTIDADE DO ITEM NO ORÇAMENTO DE SERVIÇOS,;
			8 = Tipo [RH / MI / MC / LE].
		}
	*/

	oMdlCNB:GoLine( oMdlCNB:Length() )
	cItemCNB := Soma1(oMdlCNB:GetValue("CNB_ITEM"))
	cCodIss := ""

	// identifica qual a TES para usar no item
	If aPrds[nK,8] == "RH"
		oMdlItemGS 		:= oModel:GetModel("TFF_RH")
		cCpoBusca 		:= "TFF_ITEM"
		cCpoSet 		:= "TFF_ITCNB"
		cCpoTFLItem 	:= "TFL_ITPLRH"
		cTESCNB 		:= oMdlItemGS:GetValue("TFF_TESPED")
		If lPedIss .AND. SB1->(DbSeek(cFilSB1 + aPrds[nK,2]))
			cCodIss := SB1->B1_CODISS
		EndIf		
	ElseIf aPrds[nK,8] == "MI"
		If !Empty(aPrds[nK,10])
			oModel:GetModel("TFF_RH"):SeekLine( { { "TFF_ITEM", aPrds[nK,10] } } )
		EndIf
		If !lGsMtMi
			oMdlItemGS 		:= oModel:GetModel("TFG_MI")
			cCpoBusca 		:= "TFG_ITEM"
			cCpoSet 		:= "TFG_ITCNB"
			cTESCNB := oMdlItemGS:GetValue("TFG_TESPED")
		Else
			oMdlItemGS 		:= oModel:GetModel("TFF_RH")
			cCpoBusca 		:= "TFF_ITEM"
			cCpoSet 		:= "TFF_ITICNB"
			cTESCNB 		:= oMdlItemGS:GetValue("TFF_TESPED")
		EndIf
		cCpoTFLItem 	:= "TFL_ITPLMI"
		
		If lPedIss .AND. SB1->(DbSeek(cFilSB1 + aPrds[nK,11]))
			cCodIss := SB1->B1_CODISS
		EndIf

	ElseIf aPrds[nK,8] == "MC"
		If !Empty(aPrds[nK,10])
			oModel:GetModel("TFF_RH"):SeekLine( { { "TFF_ITEM", aPrds[nK,10] } } )
		EndIf
		If !lGsMtMc
			oMdlItemGS 		:= oModel:GetModel("TFH_MC")
			cCpoBusca 		:= "TFH_ITEM"
			cCpoSet 		:= "TFH_ITCNB"
			cTESCNB := oMdlItemGS:GetValue("TFH_TESPED")
		Else
			oMdlItemGS 		:= oModel:GetModel("TFF_RH")
			cCpoBusca 		:= "TFF_ITEM"
			cCpoSet 		:= "TFF_ITCCNB"
			cTESCNB 		:= oMdlItemGS:GetValue("TFF_TESPED")
		EndIf
		
		cCpoTFLItem 	:= "TFL_ITPLMC"
		
		If lPedIss .AND. SB1->(DbSeek(cFilSB1 + aPrds[nK,11]))
			cCodIss := SB1->B1_CODISS
		EndIf

	ElseIf aPrds[nK,8] == "LE"
		oMdlItemGS 		:= oModel:GetModel("TFI_LE")
		cCpoBusca 		:= "TFI_ITEM"
		cCpoSet 		:= "TFI_ITCNB"
		cCpoTFLItem 	:= "TFL_ITPLLE"
		cTESCNB 		:= oMdlItemGS:GetValue("TFI_TESPED")
	Else
		oMdlItemGS 		:= Nil
		cCpoBusca 		:= ""
		cCpoSet 		:= ""
		cCpoTFLItem 	:= ""
		cTESCNB 		:= ""
	EndIf
	// planilha já está posicionada pelo itens acima
	If !Empty( aPrds[nK,4] )
		// posicionar na linha do item no contrato
		oMdlCNB:Goline(1)
		If oMdlCNB:SeekLine( {{"CNB_ITEM", aPrds[nK,4] }} )

			// calcula o valor de outros conceitos de produtos que apontam para o mesmo item
			nTotalOld := aPrds[nK,6]
			nTotalNew := aPrds[nK,5]

			// função para atualizar os dados da CNB
			lRet := lRet .And. At870CNBUpd( oMdlCNB, nTotalOld, nTotalNew, aPrds[nK,7] )
			If lRet .And.!Empty(aPrds[nK,9]) .And. lRecorrente
				lRet := lRet .And. oMdlCNB:SetValue("CNB_ATIVO",aPrds[nK,9])
			Endif
			lRet := lRet .And. oMdlCNB:VldLineData()

			// atualiza o item da CNB caso tenha diferença entre o inicial e o novo item
			//  posicionar na linha conforme o item do orçamento de serviços e adicionar o item da CNB nele
			If aPrds[nK,4] <> oMdlCNB:GetValue( "CNB_ITEM" )
				If lRet .And. oMdlItemGS:SeekLine( { { cCpoBusca, aPrds[nK,1] } } )
					lRet := lRet .And. oMdlItemGS:SetValue( cCpoSet, cItemCNB)
					// verifica se o item no cabeçalho do orçamento já possui preenchimento
					If Empty( oMdlTFL:GetValue( cCpoTFLItem ) )
						lRet := lRet .And. oMdlTFL:SetValue( cCpoTFLItem, cItemCNB )
					EndIf
				Else
					lRet := .F.
					Help( "", 1, "At870NOAGR_05", , STR0198, 1, 0,,,,,,; // "Problemas ao atualizar o item do Contrato no Orçamento de Serviços."
							{i18n(STR0199,{ aPrds[nK,1], aPrds[nK,8] }) } ) // "Não foi possível identificar o item #1 no conceito de produto #2."
				EndIf
			EndIf

			If !lRet
				Help( "", 1, "At870NOAGR_01", , i18n(STR0200,{ aPrds[nK,4], oMdlCNB:GetValue("CNB_NUMERO") }), 1, 0,,,,,,; // "Problema na atualização do item #1 na planilha #2."
						{STR0201})  // "Verifique os valores informados para o item correspondente no orçamento de serviços."
				If oMdlCNB:GetModel():HasErrorMessage()
					AtErroMvc( oMdlCNB:GetModel() )
					MostraErro()
				EndIf
				If oModel:HasErrorMessage()
					AtErroMvc( oMdlTFL:GetModel() )
					MostraErro()
				EndIf
				Exit
			EndIf

		Else
			lRet := .F.
			Help( "", 1, "At870NOAGR_02", , i18n(STR0202,{ aPrds[nK,4], oMdlCNB:GetValue("CNB_NUMERO") }), 1, 0,,,,,,; // "O item #1 na planilha #2 não foi encontrado."
					{STR0201}) // "Verifique os valores informados para o item correspondente no orçamento de serviços."
			Exit
		EndIf
	ElseIf aPrds[nK,5] > 0
		// adicionar um novo item na CNB
		// criar um novo item na planilha
		aAux := {}
		Aadd(aAux ,{"CNB_ITEM"  , cItemCNB } )
		Aadd(aAux ,{"CNB_NUMERO", cNumPlan } )
		Aadd(aAux ,{"CNB_PRODUT", aPrds[nK,2] } )
		Aadd(aAux ,{"CNB_QUANT" , aPrds[nK,7] })
		Aadd(aAux ,{"CNB_VLUNIT", Round(NoRound(( aPrds[nK,5] / aPrds[nK,7] ),3),2) } )
		Aadd(aAux ,{"CNB_TS"    , cTESCNB })
		Aadd(aAux ,{"CNB_PEDTIT", cPedTit })
		If !Empty(aPrds[nK,11]) 
			Aadd(aAux ,{"CNB_PRODSV", aPrds[nK,11] } ) 
		EndIf
		If !Empty(cLocCCusto)
			Aadd(aAux ,{"CNB_CC", cLocCCusto })
		EndIf

		Aadd(aAux ,{"CNB_ATIVO", aPrds[nK,9] })
		
		If !Empty(cCodIss)
			Aadd(aAux,{"CNB_IDPED", SB1->B1_CODISS,      NIL})
		EndIf
		
		lRet := lRet .And. At870CNBAdd( oMdlCNB, aAux )
		lRet := lRet .And. oMdlCNB:VldLineData()

		//-------------------------------------------------
		//  posicionar na linha conforme o item do orçamento de serviços e adicionar o item da CNB nele
		If lRet.AND. oMdlItemGS:SeekLine( { { cCpoBusca, aPrds[nK,1] } } )
			lRet := lRet .And. oMdlItemGS:SetValue( cCpoSet, cItemCNB)
			// verifica se o item no cabeçalho do orçamento já possui preenchimento
			If lRet .and. lGrpFatOrc 
				lRet := At870AtuTWW( cLocal, cItemCNB, aPrds[nK,8] )
			Endif
			If lRet.AND. Empty( oMdlTFL:GetValue( cCpoTFLItem ) )
				lRet := lRet .And. oMdlTFL:SetValue( cCpoTFLItem, cItemCNB )
			EndIf
		Else
			lRet := .F.
			Help( "", 1, "At870NOAGR_04", , STR0198, 1, 0,,,,,,; // "Problemas ao atualizar o item do Contrato no Orçamento de Serviços."
					{i18n(STR0199,{ aPrds[nK,1], aPrds[nK,8] }) } ) // "Não foi possível identificar o item #1 no conceito de produto #2."
		EndIf
		If !lRet
			Help( "", 1, "At870NOAGR_03", , STR0203, 1, 0,,,,,,; // "Problemas ao incluir um item na revisão."
					{STR0197})  // "Verifique se a revisão permite a inclusão de novas linhas no contrato."
			If oMdlCNB:GetModel():HasErrorMessage()
				AtErroMvc( oMdlCNB:GetModel() )
				MostraErro()
			EndIf
			If oModel:HasErrorMessage()
				AtErroMvc( oModel )
				MostraErro()
			EndIf
			Exit
		EndIf

		aSize( aAux, 0 )
		aAux := Nil
	EndIf

Next nK

If lPedISS
	RestArea(aAreaSB1)
EndIf

Return lRet

/*/{Protheus.doc} At870RestLins
@description 	Reposiciona todos os modelos do orçamento de serviços para a primeira linha
@since 			02.12.2016
@version 		12
@param 			oMdlRev, Objeto FwFormModel/MpFormModel, objeto geral para o reposicionamento.
@param 			lOrcPrc, Lógico, define se o orçamento de serviços é com precificação ou não.
/*/
Static Function At870RestLins( oMdlRev, lOrcPrc )

Local aRhMdls := {}
Local aLeMdls := {}
Local nX := 0
Local nY := 0
Local nZ := 0
Local oMdlLocal := oMdlRev:GetModel("TFL_LOC")
Local oMdlRH := oMdlRev:GetModel("TFF_RH")
Local oMdlLE := oMdlRev:GetModel("TFI_LE")
Local oMdlFacil := oMdlRev:GetModel("TWODETAIL")
Local nQtSubRH := 0
Local nQtSubLE := 0
Local oMdlTemp1 := Nil

Default lOrcPrc := SuperGetMv("MV_ORCPRC",,.F.)

If lOrcPrc
	aRhMdls := { "ABP_BENEF", "TFU_HE", "TGV_RH", "TDS_RH", "TDT_RH" }
Else
	aRhMdls := { "ABP_BENEF", "TFG_MI", "TFH_MC", "TFU_HE", "TGV_RH", "TDS_RH", "TDT_RH" }
EndIf

aLeMdls := { "TEV_ADICIO" }

nQtSubRH := Len(aRhMdls)
nQtSubLE := Len(aLeMdls)

For nX := 1 To oMdlLocal:Length()

	oMdlLocal:GoLine( nX )
	// manda o facilitador para a primeira linha
	oMdlFacil:GoLine( 1 )
	// posiciona os submodelos de rh para a primeira linha
	For nY := 1 To oMdlRH:Length()
		oMdlRH:GoLine( nY )

		For nZ := 1 To nQtSubRH
			oMdlTemp1 := oMdlRev:GetModel(aRhMdls[nZ])
			oMdlTemp1:GoLine(1)
		Next nZ
	Next nY
	// manda o recurso humano para a primeira linha
	oMdlRH:GoLine( 1 )

	// posiciona os submodelos de locação de equipamentos para a primeira linha
	For nY := 1 To oMdlLE:Length()
		oMdlLE:GoLine( nY )

		For nZ := 1 To nQtSubLE
			oMdlTemp1 := oMdlRev:GetModel(aLEMdls[nZ])
			oMdlTemp1:GoLine(1)
		Next nZ
	Next nY
	// manda a locção de equipamentos para a primeira linha
	oMdlLE:GoLine( 1 )

Next nX
// devolve o local para a primeira linha
oMdlLocal:GoLine( 1 )

Return

/*/{Protheus.doc} At870RAuto
@description 	Aplica o percentual e o incremento de dias nos orçamentos de serviços sem precificação
@version 		12
/*/
Function At870RAuto(oMdlRev,oMdlOrc,nPerc,nDias)
Local lRet 		:= .T.
Local oTFJRev 	:= oMdlRev:GetModel('TFJ_REFER')
Local oTFLRev 	:= oMdlRev:GetModel('TFL_LOC')
Local oTFIRev 	:= oMdlRev:GetModel('TFI_LE')
Local oTFFRev 	:= oMdlRev:GetModel('TFF_RH')
Local oTEVRev 	:= oMdlRev:GetModel('TEV_ADICIO')
Local oTFGRev	:= oMdlRev:GetModel('TFG_MI')
Local oTFHRev	:= oMdlRev:GetModel('TFH_MC')

Local oTFLOrc 	:= oMdlOrc:GetModel('TFL_LOC')
Local oTFIOrc 	:= oMdlOrc:GetModel('TFI_LE')

Local nI		   	:= 0
Local nJ			:= 0
Local nX			:= 0
Local nW			:= 0
Local nZ			:= 0
Local nVlrUnit	:= 0
Local aSaveRows	:= FwSaveRows()
Local lCobCtr := oTFFRev:GetValue("TFF_COBCTR") <> "2"
Local lRecorrente	:= oTFJRev:GetValue('TFJ_CNTREC') == "1"
Local cIsGsMt	   	:= oTFJRev:GetValue('TFJ_ISGSMT')
Local lIsMatQtde := !(oTFJRev:GetValue('TFJ_GESMAT') $ "2/3")
Local lIsMatQtdeMi 	:= !(oTFJRev:GetValue('TFJ_GSMTMI') $ "2/3")
Local lIsMatQtdeMc 	:= !(oTFJRev:GetValue('TFJ_GSMTMC') $ "2/3")
Local lIncMatVal := !lIsMatQtde .And. oTFJRev:GetValue('TFJ_GESMAT') == "2"
Local lIncMatValMi  := !lIsMatQtdeMi .And. oTFJRev:GetValue('TFJ_GSMTMI') == "2"
Local lIncMatValMc  := !lIsMatQtdeMc .And. oTFJRev:GetValue('TFJ_GSMTMC') == "2"

For nX := 1 To oTFLRev:Length()
	oTFLRev:GoLine(nX)
	oTFLOrc:GoLine(nX)  
	
	//-- Data do Local de atendimento
	If !lRecorrente
		lRet := lRet .And. oTFLRev:SetValue('TFL_DTFIM',oTFLRev:GetValue('TFL_DTFIM') + nDias)
	Endif
	
	//-- Data e valor do RH se não tiver sido atualizado por planilha
	If  lRet .And. !oTFFRev:IsEmpty()
		For nI := 1 To oTFFRev:Length()
			oTFFRev:GoLine(nI)
			// não seja item fora do contrato (item extra)
			If oTFFRev:GetValue("TFF_COBCTR") <> "2"
				// só atualiza o valor quando o item não tiver sido calculado por planilha de preço
				If Empty(oTFFRev:GetValue("TFF_CALCMD"))
					nVlrUnit := oTFFRev:GetValue('TFF_PRCVEN')
					lRet := lRet .And. oTFFRev:SetValue('TFF_PRCVEN',nVlrUnit + ( nVlrUnit / 100) * nPerc )
					nVlrUnit := oTFFRev:GetValue('TFF_REFVLR')
					lRet := lRet .And. oTFFRev:SetValue('TFF_REFVLR',nVlrUnit + ( nVlrUnit / 100) * nPerc )
					// atribui o valor de material
					If cIsGsMt == "1"
						If !lIsMatQtdeMi .And. lIncMatValMi
							nVlrUnit := oTFFRev:GetValue('TFF_VLMTMI')
							lRet := lRet .And. oTFFRev:SetValue('TFF_VLMTMI',nVlrUnit + ( nVlrUnit / 100) * nPerc )
						EndIf

						If lRet .And. !lIsMatQtdeMc .And. lIncMatValMc
							nVlrUnit := oTFFRev:GetValue('TFF_VLMTMC')
							lRet := lRet .And. oTFFRev:SetValue('TFF_VLMTMC',nVlrUnit + ( nVlrUnit / 100) * nPerc )
						EndIf					
					Else
						If !lIsMatQtde .And. lIncMatVal
							nVlrUnit := oTFFRev:GetValue('TFF_VLRMAT')
							lRet := lRet .And. oTFFRev:SetValue('TFF_VLRMAT',nVlrUnit + ( nVlrUnit / 100) * nPerc )
						EndIf
					Endif
				EndIf
				If !lRecorrente
					lRet := lRet .And. oTFFRev:SetValue('TFF_PERFIM',oTFFRev:GetValue('TFF_PERFIM') + nDias)
				Endif
			EndIf

			If cIsGsMt == "1"
				If lRet .And. !oTFGRev:IsEmpty() .And. lIsMatQtdeMi
					//-- Data e valor do material de implantação
					For nJ := 1 To oTFGRev:Length() 
						oTFGRev:GoLine(nJ)
						// não seja item fora do contrato (item extra)
						If oTFGRev:GetValue("TFG_COBCTR") <> "2"
							nVlrUnit := oTFGRev:GetValue('TFG_PRCVEN')
							lRet := lRet .And. oTFGRev:SetValue('TFG_PRCVEN',nVlrUnit + ( nVlrUnit / 100) * nPerc )
							If !lRecorrente
								lRet := lRet .And. oTFGRev:SetValue('TFG_PERFIM',oTFGRev:GetValue('TFG_PERFIM') + nDias)
							Endif
						EndIf
					Next nJ	
					oTFGRev:GoLine(1)					
				EndIf
				//-- Data e valor do material de consumo
				If lRet .And. !oTFHRev:IsEmpty() .And. lIsMatQtdeMc
					For nJ := 1 To oTFHRev:Length() 
						oTFHRev:GoLine(nJ)
						// não seja item fora do contrato (item extra)
						If oTFHRev:GetValue("TFH_COBCTR") <> "2"
							nVlrUnit := oTFHRev:GetValue('TFH_PRCVEN')
							lRet := lRet .And. oTFHRev:SetValue('TFH_PRCVEN',nVlrUnit + ( nVlrUnit / 100) * nPerc )
							If !lRecorrente
								lRet := lRet .And. oTFHRev:SetValue('TFH_PERFIM',oTFHRev:GetValue('TFH_PERFIM') + nDias)
							Endif
						EndIf
					Next nJ
					oTFHRev:GoLine(1)			
				EndIf
			Else
				If lRet .And. lIsMatQtde
					//-- Data e valor do material de implantação
					If !oTFGRev:IsEmpty()
						For nJ := 1 To oTFGRev:Length() 
							oTFGRev:GoLine(nJ)
							// não seja item fora do contrato (item extra)
							If oTFGRev:GetValue("TFG_COBCTR") <> "2"
								nVlrUnit := oTFGRev:GetValue('TFG_PRCVEN')
								lRet := lRet .And. oTFGRev:SetValue('TFG_PRCVEN',nVlrUnit + ( nVlrUnit / 100) * nPerc )
								If !lRecorrente
									lRet := lRet .And. oTFGRev:SetValue('TFG_PERFIM',oTFGRev:GetValue('TFG_PERFIM') + nDias)
								Endif
							EndIf
						Next nJ	
						oTFGRev:GoLine(1)					
					EndIf
					//-- Data e valor do material de consumo
					If lRet .And. !oTFHRev:IsEmpty()
						For nJ := 1 To oTFHRev:Length() 
							oTFHRev:GoLine(nJ)
							// não seja item fora do contrato (item extra)
							If oTFHRev:GetValue("TFH_COBCTR") <> "2"
								nVlrUnit := oTFHRev:GetValue('TFH_PRCVEN')
								lRet := lRet .And. oTFHRev:SetValue('TFH_PRCVEN',nVlrUnit + ( nVlrUnit / 100) * nPerc )
								If !lRecorrente
									lRet := lRet .And. oTFHRev:SetValue('TFH_PERFIM',oTFHRev:GetValue('TFH_PERFIM') + nDias)
								Endif
							EndIf
						Next nJ
						oTFHRev:GoLine(1)			
					EndIf
				EndIf
			Endif
		Next nI	
		oTFFRev:GoLine(1)				
	EndIf
		
	If lRet .And. !oTFIRev:IsEmpty()
		For nI := 1 To oTFIRev:Length()
			oTFIRev:GoLine(nI)
			oTFIOrc:GoLine(nI)
			//-- Não aplicar itens que ja voltaram
			If At870QtRet(oTFIOrc:GetValue('TFI_COD')) < oTFIRev:GetValue('TFI_QTDVEN') .And. Empty( oTFIRev:GetValue("TFI_CALCMD") )
				If !lRecorrente
					lRet := lRet .And. oTFIRev:SetValue('TFI_PERFIM',oTFIRev:GetValue('TFI_PERFIM') + nDias)
				Endif				
				For nJ := 1 To oTEVRev:Length()
					oTEVRev:GoLine(nJ)
					//-- Não aplicar mobilização
					If oTEVRev:GetValue('TEV_MODCOB') <> '3' 
						nVlrUnit := oTEVRev:GetValue('TEV_VLRUNI')						
						lRet := lRet .And. oTEVRev:SetValue('TEV_VLRUNI',nVlrUnit + ( nVlrUnit / 100) * nPerc )						
					EndIf
				Next nJ
			EndIf				
		Next nI
		oTFIRev:GoLine(1)
	EndIf
Next nX

oTFLRev:GoLine(1)

FwRestRows(aSaveRows)

Return lRet

/*/{Protheus.doc} At870OsMont
@description 	Reposiciona todos os modelos do orçamento de serviços para a primeira linha
@since 			02.12.2016
@version 		12
@param 			oMdlRev, Objeto FwFormModel/MpFormModel, objeto geral para o reposicionamento.
@param 			lOrcPrc, Lógico, define se o orçamento de serviços é com precificação ou não.
/*/
Static Function At870OsMont( cCodTFJAnt, cCodTFJ )
Local cQryAB6Alt 	:= GetNextAlias()
Local cFilTFJ 		:= xFilial("TFJ")
Local cNewItem 		:= ""
Local aArea 		:= GetArea()
Local aAreaTFJ 		:= TFJ->(GetArea())
Local aAreaTFL 		:= TFL->(GetArea())
Local aAreaTFI 		:= TFI->(GetArea())
Local aAreaAB6 		:= AB6->(GetArea())
Local aAreaTFF 		:= TFF->(GetArea())
Local nTotal 	:= 0
Local oDlg		:= nil
Local oSayMtr	:= nil
Local nMeter	:= 0

BeginSQL Alias cQryAB6Alt
	SELECT AB6.R_E_C_N_O_ AB6RECNO
	FROM %Table:AB6% AB6 
	WHERE AB6_FIORCS = %Exp:cFilTFJ%
		AND AB6_CDORCS = %Exp:cCodTFJAnt%
		AND AB6.%NotDel%
EndSQL

While (cQryAB6Alt)->(!EOF())
	nTotal++
	(cQryAB6Alt)->(DbSkip())
End

(cQryAB6Alt)->(DbGoTop())

TFF->(DbSetOrder( 1 ))  // TFF_FILIAL + TFF_COD
TFI->(DbSetOrder( 1 ))  // TFI_FILIAL + TFI_COD

If isBlind()
	UpdAB6xTFF(cQryAB6Alt,cCodTFJ)	
Else
	DEFINE MSDIALOG oDlg FROM 0,0 TO 5,60 TITLE STR0264 //"Atualizando ordens de serviço"
		oSayMtr := tSay():New(10,10,{||STR0257},oDlg,,,,,,.T.,,,220,20) //"Processando, aguarde..."
		oMeter  := tMeter():New(20,10,{|u|if(Pcount()>0,nMeter:=u,nMeter)},nTotal,oDlg,220,10,,.T.)
		
	ACTIVATE MSDIALOG oDlg CENTERED ON INIT (UpdAB6xTFF(cQryAB6Alt,cCodTFJ,@oDlg,@oMeter))
EndIf

RestArea(aAreaTFF)
RestArea(aAreaAB6)
RestArea(aAreaTFI)
RestArea(aAreaTFL)
RestArea(aAreaTFJ)
RestArea(aArea)

Return 


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtuDespAd
@author Adrianne Furtado (adrianne.andrade)
@since 02/08/2016
@version 12.1.14
@param cCodTFJ, character, Codigo do orçamento de serviços
@param cCodTFJNew, character, Codigo do orçamento de serviços da revisão nova
@description
Atualiza referencias das despesas adicionais.
Atualização das referencias entre TFI e TEW (TEW_ORCSER, TEW_CODEQU) para considerar os novos itens.
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function AtuDespAd(cCodTFJ, cCodTFJNew)
Local cAliasQ1	:= GetNextAlias()
Local cAliasQ2	:= GetNextAlias()
Local cAliasQ3	:= GetNextAlias()
Local aArea		:= GetArea()
Local aAreaTFJ	:= TFJ->(GetArea())

/************************************************************/
/*  Identifica registro de Despesa Adicional a ser alterado */
/************************************************************/
BeginSQL Alias cAliasQ1       
	SELECT  TFJ.TFJ_FILIAL, TFJ.TFJ_CONTRT, TFJ.TFJ_CONREV, TWQ.TWQ_CODIGO
		FROM %Table:TFJ% TFJ
		
		INNER JOIN %Table:TWQ% TWQ ON
			TWQ.TWQ_FILIAL = TFJ.TFJ_FILIAL AND
			TWQ.TWQ_CONTRT = TFJ.TFJ_CONTRT AND
			TWQ.TWQ_CONREV = TFJ.TFJ_CONREV AND			
			TWQ.%notDel%
					
	WHERE 
		TFJ.TFJ_FILIAL = %xFilial:TFJ% AND		
		TFJ.TFJ_CODIGO = %Exp:cCodTFJ% AND			 	
		TFJ.%notDel%	
EndSql

/************************************************************/
/* Identifica novas informações de Contrato e Revisão a     */
/* serem gravadas na Despesa Adicional						*/
/************************************************************/
If (cAliasQ1)->(!Eof())
	BeginSQL Alias cAliasQ2       
		SELECT  TFJ.TFJ_FILIAL, TFJ.TFJ_CONTRT, TFJ.TFJ_CONREV
			FROM %Table:TFJ% TFJ
		WHERE 
			TFJ.TFJ_FILIAL = %xFilial:TFJ% AND		
			TFJ.TFJ_CODIGO = %Exp:cCodTFJNew% AND			 	
			TFJ.%notDel%	
	EndSql
	
	//Grava nova revisão no registro da Despesa Adicional
	DbSelectArea("TWQ")
	TWQ->(DbSetOrder(1))// TWQ_FILIAL+TWQ_CODIGO
	While (cAliasQ1)->(!Eof())
		If TWQ->(DbSeek((cAliasQ1)->(TFJ_FILIAL+TWQ_CODIGO)))
			RecLock("TWQ", .F.)
				TWQ->TWQ_CONTRT := (cAliasQ2)->TFJ_CONTRT
				TWQ->TWQ_CONREV := (cAliasQ2)->TFJ_CONREV
	
				If !Empty(TWQ_POSTLE)
					TFI->(DbSetOrder(1))		
					TFI->(DbSeek(xFilial("TFI")+TWQ->TWQ_POSTLE))
					
					BeginSQL Alias cAliasQ3       
						SELECT TFI.TFI_COD 
							FROM %Table:TFI% TFI
						WHERE	
							TFI.TFI_FILIAL = %xFilial:TFI% AND	
							TFI.TFI_LOCAL = %Exp:TFI->TFI_LOCAL% AND 
							TFI.TFI_ITEM = %Exp:TFI->TFI_ITEM% AND
							TFI.TFI_CONTRT = %Exp:(cAliasQ2)->TFJ_CONTRT% AND
							TFI.TFI_CONREV = %Exp:(cAliasQ2)->TFJ_CONREV% AND 
							TFI.%notDel%	
					EndSql
									
					TWQ->TWQ_POSTLE := (cAliasQ3)->TFI_COD 
	
				ElseIf !Empty(TWQ_POSTRH)
					TFF->(DbSetOrder(1))		
					TFF->(DbSeek(xFilial("TFF")+TWQ->TWQ_POSTRH))
					
					BeginSQL Alias cAliasQ3       
						SELECT TFF.TFF_COD 
							FROM %Table:TFF% TFF
						WHERE	
							TFF.TFF_FILIAL = %xFilial:TFF% AND	
							TFF.TFF_LOCAL = %Exp:TFF->TFF_LOCAL% AND 
							TFF.TFF_ITEM = %Exp:TFF->TFF_ITEM% AND
							TFF.TFF_CONTRT = %Exp:(cAliasQ2)->TFJ_CONTRT% AND
							TFF.TFF_CONREV = %Exp:(cAliasQ2)->TFJ_CONREV% AND 
							TFF.%notDel%	
					EndSql
				
					TWQ->TWQ_POSTRH	:= (cAliasQ3)->TFF_COD
				EndIf	

			TWQ->(MsUnlock())
			(cAliasQ3)->(DbCloseArea())	

		EndIf
		(cAliasQ1)->(DbSkip())	
	EndDo
	(cAliasQ2)->(DbCloseArea())
EndIf

(cAliasQ1)->(DbCloseArea())

RestArea(aAreaTFJ)
RestArea(aArea)

Return

//-------------------------------------------------------------------------------------
/*/{Protheus.doc} At870FatAnt

Altera o número de revisão no faturamento antecipado.

@sample     At870FatAnt( cNumCtr, cNewRev )
@author     Kaique Schiller
@since      22/06/2017
/*/
//-------------------------------------------------------------------------------------
Static Function At870FatAnt( cNumCtr, cNewRev )
Local aArea		:= GetArea()
Local cNewAlias	:= GetNextAlias()
Local nTotal 	:= 0
Local oDlg		:= nil
Local oSayMtr	:= nil
Local nMeter	:= 0

Default cNumCtr := ""
Default cNewRev := ""

If !Empty(cNumCtr) .And. !Empty(cNewRev)
	BeginSQL Alias cNewAlias
		SELECT ABX.ABX_CONTRT, ABX.ABX_CONREV
			FROM %Table:ABX% ABX
		WHERE
			ABX.ABX_FILIAL = %xFilial:ABX% AND		
			ABX.ABX_CONTRT = %Exp:cNumCtr% AND
			ABX.%notDel%
	EndSql

	While (cNewAlias)->(!EOF())
		nTotal++
		(cNewAlias)->(DbSkip())
	End
	
	(cNewAlias)->(DbGoTop())

	DbSelectArea("ABX")
	ABX->(DbSetOrder(2)) //ABX_FILIAL+ABX_CONTRT+ABX_CONREV+ABX_CODPLA+ABX_MESANO

	If IsBlind()
		UpdFatAnt(cNewAlias, cNewRev)
	Else
		DEFINE MSDIALOG oDlg FROM 0,0 TO 5,60 TITLE "Atualizando configuração de Faturamento Antecipado" //"Atualizando configuração de Faturamento Antecipado"
			oSayMtr := tSay():New(10,10,{||STR0257},oDlg,,,,,,.T.,,,220,20) //"Processando, aguarde..."
			oMeter  := tMeter():New(20,10,{|u|if(Pcount()>0,nMeter:=u,nMeter)},nTotal,oDlg,220,10,,.T.)
			
		ACTIVATE MSDIALOG oDlg CENTERED ON INIT (UpdFatAnt(cNewAlias, cNewRev ,@oDlg,@oMeter))
	EndIf
Endif

RestArea(aArea)

Return .T.

//-------------------------------------------------------------------------------------
/*/{Protheus.doc} At870Conh

Banco de conhecimento 

@author     Leandro Fini
@since      04/01/2018
/*/
//-------------------------------------------------------------------------------------
Static Function At870Conh(cCodigo)

Private aRotina := {}
		
	DbSelectArea("TFJ")
	TFJ->(dbSetOrder(1))
	If TFJ->(dbSeek(xFilial("TFJ")+cCodigo))	
		Aadd(aRotina,{,,,3,})
		MsDocument( "TFJ", TFJ->( Recno() ), 1 ) //Conhecimento
	EndIf
	
aRotina := {}
Return

/*/{Protheus.doc} At870GrPlan
@description Função que localiza planilha de local
@since 15/02/2018
@version 12
@param cCod, codigo do orçamento
@param cLocal, Local para localização das planilhas
@param cPlanRH, referência, planilha de RH para retorno
@param cPlanMI, referência, planilha de MI para retorno
@param cPlanMC, referência, planilha de MC para retorno
@param cPlanLE, referência, planilha de LE para retorno
/*/
Function At870GrPlan( cCod, cLocal, cPlanRH, cPlanMI, cPlanMC, cPlanLE )
	Local lRet 		:= .T.	
	Local oModelT42	:= Nil
	Local oModelTWW	:= Nil
	Local nTamTWW	:= 0
	Local cLog		:= ""
	Local aArea		:= GetArea()
	
	Default cPlanRH := ""
	Default cPlanMI := ""
	Default cPlanMC := ""
	Default cPlanLE := ""
	
		DbSelectArea("TWW")
		DbSetOrder(2)//TWW_FILIAL + TWW_CHAVE + TWW_LOCAL
		
		
		If TWW->(DbSeek(xFilial("TWW")+cCod+cLocal))
			
			cPlanRH := TWW->TWW_PLANRH
			cPlanMI := TWW->TWW_PLANMI
			cPlanMC := TWW->TWW_PLANMC
			cPlanLE := TWW->TWW_PLANLE

		Else

			cPlanRH := ""
			cPlanMI := ""
			cPlanMC := ""
			cPlanLE := ""

		EndIf
		
		RestArea(aArea)

Return lRet

/*/{Protheus.doc} At870AtuPlan
@description Função que localiza planilha de local
@since 15/02/2018
@version 12
@param oMdlCNA, Model do cabeçalho da planilha
@param oMdlCNB, Model dos itens da planilha
@param oMdlTFJ, Model do cabeçalho do Orçamento
@param oMdlTFL, Model dos locais
@param cPlanilha, numero da Planilha
@param cPedTit, 
@param cLocCCusto, centro de custo do local
@param cContrato, Numero do contrato
/*/
Static Function At870AtuPlan( oModel, oMdlCNA, oMdlCNB, cPlanilha, cPedTit, cLocCCusto, cContrato, lSemTela, cOpcApu, nPos)

	Local lRet 		:= .T.
	Local nTotRHold := 0
	Local nTotMIold := 0
	Local nTotMCold := 0
	Local nTotLEold := 0
	Local nTotRHnew := 0
	Local nTotMInew := 0
	Local nTotMCnew := 0
	Local nTotLEnew := 0
	Local nTotalOld := 0
	Local nTotalNew := 0
	Local nTotalMed := 0	
	Local lMedicaoMaior := .F.
	Local lBlqRevi 	:= .F.
	Local nK		:= 0
	Local cTipPlan	:= ""
	Local cNumPlan	:= ""
	Local cRecPagAnt:= ""
	Local cPeriodo	:= ""
	Local nPerioRec	:= 0
	Local nQuantRec	:= 0
	Local cCodCli	:= ""
	Local cLojCli	:= ""
	Local lCont		:= .T.
	Local oMdlTFJ 	:= oModel:GetModel("TFJ_REFER")					
	Local oMdlTFL 	:= oModel:GetModel("TFL_LOC")
	Local lAgrup 	:= ( oMdlTFJ:GetValue("TFJ_DSGCN") <> "1" ) 
	Local lGrpFatOrc:= ( oMdlTFJ:GetValue("TFJ_GRPFAT") == "1" )
		
	
		// já existe no contrato
	If !Empty(cPlanilha)
		FwModelActive(oMdlCNA:GetModel()) 

		If oMdlCNA:SeekLine( {{"CNA_NUMERO", cPlanilha }} )
			lRet := lRet .And. oMdlCNA:SetValue("CNA_DTFIM", oMdlTFL:GetValue("TFL_DTFIM"))
			
			If lRet
			
				// captura os valores totais de rh, materiais e locação, desconsiderando as cobranças fora do contrato
				At870ValOld( At870LocAnt( oMdlTFL:GetValue("TFL_CODIGO") ), @nTotRHold, @nTotMIold, @nTotMCold, @nTotLEold )

				// captura os valores totais de rh, materiais e locação, desconsiderando as cobranças fora do contrato
				At870ValNew( oModel, nPos, @nTotRHnew, @nTotMInew, @nTotMCnew, @nTotLEnew )

				nTotalOld := nTotRHold + nTotMIold + nTotMCold + nTotLEold
				nTotalNew := nTotRHnew + nTotMInew + nTotMCnew + nTotLEnew
				nTotalMed := oMdlCNA:GetValue("CNA_VLTOT") - oMdlCNA:GetValue("CNA_SALDO")

				// avalia se o novo valor do item é menor que o valor já medido no contrato
				lMedicaoMaior := ( nTotalOld > nTotalNew .And. nTotalNew < nTotalMed )
				lBlqRevi := lBlqRevi .And. ( nTotalOld > nTotalNew )

				If lBlqRevi 
					lRet := .F.
					Help( "", 1, "At870REVBLOQ", , STR0162, 1, 0,,,,,,; // "Parâmetro MV_BLQREVI está ativo e não pode acontecer medição para valor menor."
								{STR0163})  // "Altere novamente o orçamento de serviços e insira um valor maior que o anterior para o local."
					
				// verifica se o novo valor é maior que o valor já medido na planilha
				ElseIf lMedicaoMaior

					lRet := .F.
					Help( "", 1, "At870MEDPLAN", , STR0164, 1, 0,,,,,,;  // "Valor já medido na planilha é superior ao novo valor para ela."
								{STR0165})  // "Altere novamente o orçamento de serviços e insira um valor maior que o já medido."
					
				Else
					// usa agrupadores??
					If lAgrup

						lRet := lRet .And. At870ItAgr( oMdlTFJ, oMdlTFL, oMdlCNB, cPedTit,;
														nTotRHold, nTotRHnew, nTotMIold, nTotMInew,;
														nTotMCold, nTotMCnew, nTotLEold, nTotLEnew,;
														oMdlCNA:GetValue("CNA_NUMERO"), cLocCCusto )


					Else
				
						lRet := lRet .And. At870ItDsAgr( oModel, oMdlCNB, cContrato, .T./*lOldValues*/,;
														cPedTit, oMdlCNA:GetValue("CNA_NUMERO"), cLocCCusto )

					EndIf

				EndIf
			EndIf
		Else
			lRet := .F.
			Help( ' ', 1, 'At870NOPLAN', , STR0166, 1, 0)  // "Planilha não encontrada no contrato."
		EndIf //oMdlCNA:SeekLine( {{"CNA_NUMERO", oMdlTFL:GetValue("TFL_PLAN") }} )
	Else //!Empty( cPlanilha ) //Transferir para a função
		// planilha ainda não existe no contrato, será adicionada

		// adicionar nova linha na planilha
		nK := oMdlCNA:Length()
		oMdlCNA:GoLine( nK )

		cTipPlan := oMdlCNA:GetValue("CNA_TIPPLA")
		cNumPlan :=  Soma1( oMdlCNA:GetValue("CNA_NUMERO") )
		cRecPagAnt	:= oMdlCNA:GetValue("CNA_RPGANT")
		cPeriodo	:= oMdlCNA:GetValue("CNA_PERIOD")
		nPerioRec	:= oMdlCNA:GetValue("CNA_PERREC")
		nQuantRec	:= oMdlCNA:GetValue("CNA_QTDREC")

		FwModelActive( oMdlCNA:GetModel() )

		If oMdlCNA:AddLine() <> nK + 1
			lRet := .F.
			Help( "", 1, "At870NONEWPLA1", , STR0167, 1, 0,,,,,,;  // "Problemas ao adicionar nova planilha."
								{STR0168})  // "Verifique se a revisão do contrato deveria permitir adicionar."
			If oMdlCNA:GetModel():HasErrorMessage()
				AtErroMvc( oMdlCNA:GetModel() )
				If !lSemTela
					MostraErro()
				EndIf
			EndIf

		Else
			
			
			If lCont .and. lGrpFatOrc
				lCont := At870GrvTWW( oMdlTFL:GetValue("TFL_LOCAL"), cNumPlan, cOpcApu, lGrpFatOrc )
				lCont := lCont .and. At870GFIT(oMdlTFL:GetValue("TFL_LOCAL"), TFJ->TFJ_CODGRP, cOpcApu, @cCodCli, @cLojCli)
				
			ElseIf lCont
				lCont:=  At850GetCli( @cCodCli, @cLojCli, oMdlTFL:GetValue("TFL_LOCAL"),;
							Posicione("TFJ", 1, xFilial("TFJ")+oMdlTFL:GetValue("TFL_CODPAI"), "TFJ_AGRUP" ) )
			EndIf
			If lCont

				lRet := lRet .And. oMdlCNA:SetValue("CNA_NUMERO", cNumPlan )
				lRet := lRet .And. oMdlCNA:LoadValue("CNA_CLIENT", cCodCli )
				lRet := lRet .And. oMdlCNA:LoadValue("CNA_LOJACL", cLojCli )
				lRet := lRet .And. oMdlCNA:SetValue("CNA_TIPPLA", cTipPlan )
				lRet := lRet .And. oMdlCNA:SetValue("CNA_DTINI"	, oMdlTFL:GetValue("TFL_DTINI") )
				lRet := lRet .And. oMdlCNA:SetValue("CNA_DTFIM"	, oMdlTFL:GetValue("TFL_DTFIM") )

				If !Empty(cPeriodo) .And. nPerioRec > 0 .And. nQuantRec > 0 
					lRet := lRet .And. oMdlCNA:LoadValue("CNA_RPGANT", cRecPagAnt )
					lRet := lRet .And. oMdlCNA:SetValue("CNA_PERIOD", cPeriodo )
					lRet := lRet .And. oMdlCNA:SetValue("CNA_PERREC", nPerioRec )
					lRet := lRet .And. oMdlCNA:SetValue("CNA_QTDREC", nQuantRec )
				Endif
			Else
				lRet := .F.
				Help( "", 1, "At870CLILOC", , STR0169, 1, 0,,,,,,;  // "Problemas identificar o cliente no local de atendimento."
									{STR0170})  // "Verifique a configuração de qual cliente utilizar no orçamento de serviços e o preenchimento no local de atendimento."
			
			EndIf
		EndIf
		// adiciona 1 ao número da planilha anterior
		If !lGrpFatOrc
			lRet := lRet .And. oMdlTFL:SetValue("TFL_PLAN", cNumPlan )
		EndIf
		// usa agrupadores?
		If lRet .And. lAgrup

			// captura os valores totais de rh, materiais e locação, desconsiderando as cobranças fora do contrato
			At870ValNew( oModel, nPos, @nTotRHnew, @nTotMInew, @nTotMCnew, @nTotLEnew )
			nTotRHold := 0
			nTotMIold := 0
			nTotMCold := 0
			nTotLEold := 0

			// chama função para incluir os itens com o formato de agrupadores
			lRet := lRet .And. At870ItAgr( oMdlTFJ, oMdlTFL, oMdlCNB, cPedTit,;
											nTotRHold, nTotRHnew, nTotMIold, nTotMInew,;
											nTotMCold, nTotMCnew, nTotLEold, nTotLEnew,;
											cNumPlan, cLocCCusto )
	

		ElseIf lRet
			// chama função para incluir os itens com o formato sem agrupadores
			lRet := lRet .And. At870ItDsAgr( oModel, oMdlCNB, cContrato, .F./*lOldValues*/, cPedTit,;
											cNumPlan, cLocCCusto )

		EndIf

		// valida se a linha da CNA está ok para depois prosseguir com o processo de revisão
		FwModelActive( oMdlCNA:GetModel() )
		lRet := lRet .And. oMdlCNA:VldLineData()

		If !lRet 
			Help( "", 1, "At870NONEWPLA2", , STR0171, 1, 0,,,,,,;  // "Problemas ao adicionar nova planilha."
							{STR0172})  // "Verifique se a revisão do contrato deveria permitir adicionar."
			If oMdlCNA:GetModel():HasErrorMessage()
				AtErroMvc( oMdlCNA:GetModel() )
				If !lSemTela
					MostraErro()
				EndIf
			EndIf
			If oMdlTFL:GetModel():HasErrorMessage()
				AtErroMvc( oMdlTFL:GetModel() )
				If lSemTela
					MostraErro()
				EndIf
			EndIf
	
		EndIf

	EndIf //!Empty( cPlanilha )
						
Return lRet

/*/{Protheus.doc} At870AtuGrp
@description Função para atualizar o grupo de faturamento
@since 23/02/2018
@version 12
@param cRev, numero da revisão
/*/
Static Function At870AtuGrp( cRev)
	Local lRet 		:= .F.
	Local oModelT42	:= Nil
	Local oModelTWW	:= Nil
	Local nTamTWW	:= 0
	Local cLog		:= ""
	Local aArea		:= GetArea()
	Local nX		:= 1
	Local oStruT42	:= Nil
	Local oStruTWW	:= Nil

	
	DbSelectArea("T42")
	DbSetOrder(3) // T42_FILIAL+ T42_CHAVE
	
	If T42->( DbSeek(xFilial("T42") + TFJ->TFJ_CODGRP) )

		oModelT42  := FWLoadModel("TECA931B")						
		oModelT42:SetOperation(MODEL_OPERATION_UPDATE) //Update
		oModelT42:Activate()
		
		oStruT42	 	:= oModelT42:GetModel('T42MASTER'):GetStruct()
		oStruT42:SetProperty("T42_CODIGO" 	,MODEL_FIELD_WHEN, {||.T.} )
		oStruT42:SetProperty("T42_STATUS" 	,MODEL_FIELD_WHEN, {||.T.} )
		
		
		oModelT42:LoadValue( "T42MASTER", "T42_CODIGO", TFJ->TFJ_CODIGO )
		oModelT42:LoadValue( "T42MASTER", "T42_CONREV", cRev)
		oModelT42:LoadValue( "T42MASTER", "T42_STATUS", "1")
		
		oModelTWW:= oModelT42:GetModel("TWWDETAIL")
		oStruTWW:= oModelTWW:GetStruct()
		
		oStruTWW:SetProperty("TWW_NUMERO" 	,MODEL_FIELD_WHEN, {||.T.} )
		oStruTWW:SetProperty("TWW_REVISA" 	,MODEL_FIELD_WHEN, {||.T.} )
		
		
		nTamTWW:= oModelTWW:Length()
		
		For nX := 1 to nTamTWW
			oModelTWW:GoLine(nX)
			oModelTWW:LoadValue("TWW_NUMERO", TFJ->TFJ_CODIGO)
			oModelTWW:LoadValue("TWW_REVISA", cRev)
		Next nX
		
		If oModelT42:VldData()
			oModelT42:CommitData()	
			lRet := .T.
		Else
		    cLog := cValToChar(oModelT42:GetErrorMessage()[4]) + ' - '
		    cLog += cValToChar(oModelT42:GetErrorMessage()[5]) + ' - '
		    cLog += cValToChar(oModelT42:GetErrorMessage()[6])        	
       		Help( ,,"ATUGRFAT",,cLog, 1, 0 )
		Endif								
		oModelT42:DeActivate()
	    oModelT42:Destroy()
		oModelT42:= Nil
	
	EndIf

Return lRet

/*/{Protheus.doc} At870GrvTWW
@description Função para gravar ou atualizar a TWW quando o local é novo
@since 26/02/2018
@version 12
@param cLocal, Local para localização das planilhas
@param cPlanilha, codigo da planilha gerada
@param cOpc, identificação do campo

/*/
Function At870GrvTWW( cLocal, cPlanilha, cOpc, lGrpFatOrc )
	Local lRet 		:= .F.	
	Local oModelT42	:= Nil
	Local oModelTWW	:= Nil
	Local nTamTWW	:= 0
	Local cLog		:= ""
	Local cCampo	:= "TWW_PLAN" + cOpc
	Local aArea		:= GetArea()
	
	
		DbSelectArea("T42")
		DbSetOrder(3) // T42_FILIAL+ T42_CHAVE
			
		DbSelectArea("ABS")
		DbSetOrder(1) // ABS_FILIAL+ ABS_LOCAL
			
		If T42->( DbSeek(xFilial("T42") + TFJ->TFJ_CODGRP) ) .AND. ABS->( DbSeek(xFilial("ABS") + cLocal) )
			oModelT42  := FWLoadModel("TECA931B")						
			oModelT42:SetOperation(MODEL_OPERATION_UPDATE) //Update
			oModelT42:Activate()
		
			oModelTWW:= oModelT42:GetModel("TWWDETAIL")
			
			oModelTWW:SetNoInsertLine(.F.) 
			
			If oModelTWW:SeekLine( {{"TWW_LOCAL", cLocal }} )//TWW->(DbSeek(xFilial("TWW")+cCod+cLocal))
			
				oModelTWW:SetValue(cCampo, cPlanilha)
				
			Else
				oModelTWW:AddLine()
		
				oModelTWW:SetValue("TWW_REVISA", oModelT42:GetValue( "T42MASTER", "T42_CONREV"))
				oModelTWW:SetValue("TWW_CONTRT", oModelT42:GetValue( "T42MASTER", "T42_CONTRA"))
				oModelTWW:SetValue("TWW_LOCAL", cLocal)
				If lGrpFatOrc
					oModelTWW:SetValue("TWW_CLIERH", ABS->ABS_CLIFAT)
					oModelTWW:SetValue("TWW_LOJARH", ABS->ABS_LJFAT)
					oModelTWW:SetValue("TWW_CLIEMI", ABS->ABS_CLIFAT)
					oModelTWW:SetValue("TWW_LOJAMI", ABS->ABS_LJFAT)
					oModelTWW:SetValue("TWW_CLIEMC", ABS->ABS_CLIFAT)
					oModelTWW:SetValue("TWW_LOJAMC", ABS->ABS_LJFAT)
					oModelTWW:SetValue("TWW_CLIELE", ABS->ABS_CLIFAT)
					oModelTWW:SetValue("TWW_LOJALE", ABS->ABS_LJFAT)
					oModelTWW:SetValue(cCampo, cPlanilha)
				EndIf
				oModelTWW:SetValue("TWW_CLIEHE", ABS->ABS_CLIFAT)
				oModelTWW:SetValue("TWW_LOJAHE", ABS->ABS_LJFAT)
				oModelTWW:SetValue("TWW_CLIEAD", ABS->ABS_CLIFAT)
				oModelTWW:SetValue("TWW_LOJAAD", ABS->ABS_LJFAT)
				
				
			EndIf	
					
			If oModelT42:VldData()
				oModelT42:CommitData()	
				lRet := .T.
			Else
			    cLog := cValToChar(oModelT42:GetErrorMessage()[4]) + ' - '
			    cLog += cValToChar(oModelT42:GetErrorMessage()[5]) + ' - '
			    cLog += cValToChar(oModelT42:GetErrorMessage()[6])        	
	       		Help( ,,"INCGRFAT",,cLog, 1, 0 )
			Endif								
			oModelT42:DeActivate()
		    oModelT42:Destroy()
			oModelT42:= Nil

		EndIf
		
		RestArea(aArea)

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At870GFIT
Função Responsável por Verificar o cliente configurado no Grupo de Faturamento
de acordo com cada Tipo de Serviço (RH, MI, MC, LE , AD e HE) e em seguida 
montar a chave responsável pelo agrupamento do Pedido de Vendas.
@sample	 	At870GFIT()
@return		lRet
@since		26/02/2018
@author		Pâmela Bernardo
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At870GFIT(cLocal, cCodGrp, cOpcApu, cCliente, cLoja)

Local lRet			:= .F.

	DbSelectArea("TWW")
	TWW->(DbSetOrder(2))//TWW_FILIAL + TWW_CHAVE+TWW_LOCAL
	
		If TWW->(dbSeek(xFilial("TWW")+cCodGrp+cLocal))
			cCliente := TWW->&('TWW_CLIE' + cOpcApu)
			cLoja := TWW->&('TWW_LOJA' + cOpcApu)
			lRet := .T.
			
		EndIf

Return lRet

/*/{Protheus.doc} At870AtuTWW
@description Função para gravar ou atualizar a TWW quando o local é novo
@since 28/02/2018
@version 12
@param cLocal, Local para localização das planilhas
@param cItem, codigo item gerado
@param cOpc, identificação do campo
/*/
Function At870AtuTWW( cLocal, cItem, cOpc )
	Local lRet 		:= .F.	
	Local oModelT42	:= Nil
	Local oModelTWW	:= Nil
	Local cLog		:= ""
	Local cCampo	:= "TWW_ITEM" + cOpc
	Local aArea		:= GetArea()
	
	
		DbSelectArea("T42")
		DbSetOrder(3) // T42_FILIAL+ T42_CHAVE
			
		If T42->( DbSeek(xFilial("T42") + TFJ->TFJ_CODGRP) ) 
			oModelT42  := FWLoadModel("TECA931B")						
			oModelT42:SetOperation(MODEL_OPERATION_UPDATE) //Update
			oModelT42:Activate()
		
			oModelTWW:= oModelT42:GetModel("TWWDETAIL")
			
			If oModelTWW:SeekLine( {{"TWW_LOCAL", cLocal }} )
				oModelTWW:SetValue(cCampo, cItem)				
			EndIf	
					
			If oModelT42:VldData()
				oModelT42:CommitData()	
				lRet := .T.
			Else
			    cLog := cValToChar(oModelT42:GetErrorMessage()[4]) + ' - '
			    cLog += cValToChar(oModelT42:GetErrorMessage()[5]) + ' - '
			    cLog += cValToChar(oModelT42:GetErrorMessage()[6])        	
	       		Help( ,,"INCGRFAT",,cLog, 1, 0 )
			Endif								
			oModelT42:DeActivate()
		    oModelT42:Destroy()
			oModelT42:= Nil

		EndIf
		
		RestArea(aArea)

Return lRet

/*/{Protheus.doc} At870RetCli
@description Função retornar a gravação do cliente efetivação da revisão
@since 20/03/2018
@version 12
@param cChaveTWW, campo TFJ_CODGRP
@param aRet, Retorno do cliente/loja de cada planilha

/*/
Function At870RetCli(cChaveTWW)
	Local aRet 		:= {}	
	Local cQuery 	:= ""
	Local cAliasTWW := GetNextAlias()
	Local aArea		:= GetArea()
	
	cQuery := "SELECT * FROM "
	cQuery += RetSqlName("TWW") 
	cQuery += " WHERE "                                    
	cQuery += "TWW_FILIAL = '"+xFilial("TWW")+"' AND "
	cQuery += "TWW_CHAVE= '" + cChaveTWW + "' AND "
	cQuery += "D_E_L_E_T_ = ' ' "
	cQuery := ChangeQuery(cQuery)

	dBUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),cAliasTWW,.F.,.T.)
	
	(cAliasTWW)->(dbGoTop())

	While (cAliasTWW)->(!EOF())	
	
			Aadd(aRet, {{(cAliasTWW)->TWW_PLANRH, (cAliasTWW)->TWW_CLIERH, (cAliasTWW)->TWW_LOJARH},;
						{(cAliasTWW)->TWW_PLANMI, (cAliasTWW)->TWW_CLIEMI, (cAliasTWW)->TWW_LOJAMI},;
						{(cAliasTWW)->TWW_PLANMC, (cAliasTWW)->TWW_CLIEMC, (cAliasTWW)->TWW_LOJAMC},;
						{(cAliasTWW)->TWW_PLANLE, (cAliasTWW)->TWW_CLIELE, (cAliasTWW)->TWW_LOJALE}})			

		(cAliasTWW)->(dbSkip())
	End
	(cAliasTWW)->(dbCloseArea())	
	RestArea(aArea)

Return aRet

/*/{Protheus.doc} GetMdlRev()
@description Função retornar o modelo anterior a copia
@since 05/06/2018
@version 12

@param oOrcAtual, Modelo com os dados anteriores da Revisão

/*/
Function GetMdlRev()
Return oOrcAtual

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870RvRef
@author Kaique Schiller
@since 10/04/2019
@param cCodTFJ, character, Codigo do orçamento de serviços revisado
@description
Atualiza referencias do Reforço.
Atualização das referencias da TW4 (TW4_CODTFF) para considerar os novos itens gerados pela revisão.
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At870RvRef(cCodTFJ)
Local cQryTFFOld:= GetNextAlias()
Local aArea		:= GetArea()
Local nTotal 	:= 0
Local oDlg		:= nil
Local oSayMtr	:= nil
Local nMeter	:= 0

/************************************************************/
/*  Seleciona o orçamento revisado.							*/
/************************************************************/
BeginSql Alias cQryTFFOld
	
	SELECT TFF_COD,TFF_CODSUB
	
	FROM %Table:TFJ% TFJ
	
	INNER JOIN %Table:TFL% TFL
			ON TFL_FILIAL  = %xFilial:TFL%
			AND TFL_CODPAI = TFJ_CODIGO
	
	INNER JOIN %Table:TFF% TFF
			ON TFF_FILIAL  = %xFilial:TFF%
			AND TFF_CODPAI = TFL_CODIGO
			
	WHERE
		TFJ_FILIAL = %xFilial:TFJ% AND
		TFJ_CODIGO = %Exp:cCodTFJ% AND
		TFJ.%NotDel% AND
		TFL.%NotDel% AND
		TFF.TFF_ORIREF <> '' AND
		TFF.%NotDel%
	
EndSql

While (cQryTFFOld)->(!EOF())
	nTotal++
	(cQryTFFOld)->(DbSkip())
End

(cQryTFFOld)->(DbGoTop())

/************************************************************/
/* Atualiza o codigo de referencia TW4_CODTFF.				*/
/************************************************************/
DbSelectArea("TW4")
TW4->(DbSetOrder(3))// TW4_FILIAL+TW4_CODTFF

If IsBlind()
	UpdRvRef(cQryTFFOld)
Else
	DEFINE MSDIALOG oDlg FROM 0,0 TO 5,60 TITLE STR0263 //"Atualizando configuração de cobertura"
		oSayMtr := tSay():New(10,10,{||STR0257},oDlg,,,,,,.T.,,,220,20) //"Processando, aguarde..."
		oMeter  := tMeter():New(20,10,{|u|if(Pcount()>0,nMeter:=u,nMeter)},nTotal,oDlg,220,10,,.T.)
		
	ACTIVATE MSDIALOG oDlg CENTERED ON INIT (UpdRvRef(cQryTFFOld,@oDlg,@oMeter))
EndIf

(cQryTFFOld)->(DbCloseArea())

RestArea(aArea)

Return .T.

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} SumABQConf
@author Mateus Boiani
@since 06/11/2019

@description Realiza o processamento da função At870AtAlo com uma barra de load
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function SumABQConf(cAliasABQ,aInfo,cIn,oDlg,oMeter)
	Local aAux
	Local nCount := 0
	Local lLoadBar := .F.
	
	Default oDlg := nil
	Default oMeter := nil
	
	lLoadBar := !isBlind() .AND. oMeter != nil .AND. oDlg != nil
	
	//Busca relação entre configuração anterior e atual
	While (cAliasABQ)->(!EOF())
		aAux := Array(3)
		aAux[1] := (cAliasABQ)->ABQ_CONTRT+(cAliasABQ)->ABQ_ITEM+(cAliasABQ)->ABQ_ORIGEM
		aAux[2] := (cAliasABQ)->CONTRTSUB+(cAliasABQ)->ITEMSUB+(cAliasABQ)->ORIGEMSUB
		aAux[3] := (cAliasABQ)->ABQ_TOTAL -(cAliasABQ)->ABQ_SALDO//consumido da configuração original
	
		aAdd(aInfo, aAux)
		cIn += (cAliasABQ)->ABQ_CONTRT+(cAliasABQ)->ABQ_ITEM+(cAliasABQ)->ABQ_ORIGEM+","
		If lLoadBar
			oMeter:Set(++nCount)
			oMeter:Refresh()
		EndIf
		(cAliasABQ)->(DbSkip())
	EndDo
	If lLoadBar
		oDlg:End()
	EndIf
	
	(cAliasABQ)->(DbCloseArea())
	
	RETURN

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} UpdABBIdCf
@author Mateus Boiani
@since 06/11/2019

@description Realiza o processamento da função At870AtAlo com uma barra de load
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function UpdABBIdCf(cAliasABB, aInfo, oDlg, oMeter)
	Local nPos
	Local nCount := 0
	Local lLoadBar := .F.
	
	Default oDlg := nil
	Default oMeter := nil
	
	lLoadBar := !isBlind() .AND. oMeter != nil .AND. oDlg != nil
	
	//Realiza atuação da agenda do atendente
	While (cAliasABB)->(!EOF())
		nPos := aScan(aInfo, {|x| x[1] == (cAliasABB)->ABB_IDCFAL })//encontra registro substituido
		If nPos > 0
	
			//Atualiza ABB
			ABB->(DbSetOrder(8))//ABB_FILIAL+ABB_CODIGO
			If ABB->(DbSeek(xFilial("ABB")+(cAliasABB)->ABB_CODIGO))
				RecLock("ABB", .F.)
				ABB->ABB_IDCFAL :=  aInfo[nPos][2]//Atualiza IDCFAL
				MsUnlock()
			EndIf
		EndIf
		If lLoadBar
			oMeter:Set(++nCount)
			oMeter:Refresh()
		EndIf
		(cAliasABB)->(DbSkip())
	EndDo
	If lLoadBar
		oDlg:End()
	EndIf
	(cAliasABB)->(DbCloseArea())
	Return
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} UpdABQSald
@author Mateus Boiani
@since 06/11/2019
	
@description Realiza o processamento da função At870AtAlo com uma barra de load
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function UpdABQSald(aInfo,oDlg,oMeter)
	Local nCount := 0
	Local nI
	Local lLoadBar := .F.
	
	Default oDlg := nil
	Default oMeter := nil
	
	lLoadBar := !isBlind() .AND. oMeter != nil .AND. oDlg != nil
	
	//Atualiza saldo da configuração de alocação
	For nI:=1 To Len(aInfo)
		//Atualiza Saldo
		ABQ->(DbSetOrder(1))//ABQ_FILIAL + ABQ_CONTRT + ABQ_ITEM + ABQ_ORIGEM
		If ABQ->(DbSeek(xFilial("ABQ")+aInfo[nI][2]))
			RecLock("ABQ", .F.)
			ABQ->ABQ_SALDO := ABQ->ABQ_TOTAL - aInfo[nI][3]//Desconta o que já foi consumido na configuração anterior
			MsUnlock()
		EndIf
		If lLoadBar
			oMeter:Set(++nCount)
			oMeter:Refresh()
		EndIf
	Next nI
	If lLoadBar
		oDlg:End()
	EndIf
Return	

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} UpdTGYxTFF
@author Mateus Boiani
@since 06/11/2019

@description Realiza o processamento da função At870AtGES com uma barra de load
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function UpdTGYxTFF(cAliasTGY, aCodTFF,oDlg,oMeter)
	Local nPosTFF
	Local nCount := 0
	Local lLoadBar := .F.
	
	Default oDlg := nil
	Default oMeter := nil
	
	lLoadBar := !isBlind() .AND. oMeter != nil .AND. oDlg != nil
	
	//Realiza a atualização das configurações do efetivo
	While (cAliasTGY)->(!Eof())
		//Atualiza TGY
		If TGY->( DbSeek( xFilial("TGY")+(cAliasTGY)->TGY_ESCALA+(cAliasTGY)->TGY_CODTDX+;
						(cAliasTGY)->TGY_CODTFF+(cAliasTGY)->TGY_ITEM ) )
	
			nPosTFF := aScan( aCodTFF, { |x| x[1] == (cAliasTGY)->TGY_CODTFF } )
	
			If nPosTFF > 0
				RecLock("TGY", .F.)
				TGY->TGY_CODTFF := aCodTFF[ nPosTFF, 2 ]
				TGY->(msUnlock())
			EndIf
	
		EndIf
		If lLoadBar
			oMeter:Set(++nCount)
			oMeter:Refresh()
		EndIf
		(cAliasTGY)->(DbSkip())
	EndDo
	If lLoadBar
		oDlg:End()
	EndIf
Return
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} UpdTGZxTFF
@author Mateus Boiani
@since 06/11/2019
	
@description Realiza o processamento da função At870AtGES com uma barra de load
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function UpdTGZxTFF(cAliasTGZ, aCodTFF,oDlg,oMeter)
	Local nPosTFF
	Local nCount := 0
	Local lLoadBar := .F.
	
	Default oDlg := nil
	Default oMeter := nil
	
	lLoadBar := !isBlind() .AND. oMeter != nil .AND. oDlg != nil
	
	//Realiza a atualização das configurações do efetivo
	While (cAliasTGZ)->(!Eof())
		//Atualiza TGZ
		If TGZ->( DbSeek( xFilial("TGZ")+(cAliasTGZ)->TGZ_ESCALA+(cAliasTGZ)->TGZ_CODTDX+;
						(cAliasTGZ)->TGZ_CODTFF+(cAliasTGZ)->TGZ_ITEM ) )
	
			nPosTFF := aScan( aCodTFF, { |x| x[1] == (cAliasTGZ)->TGZ_CODTFF } )
	
			If nPosTFF > 0
				RecLock("TGZ", .F.)
				TGZ->TGZ_CODTFF := aCodTFF[ nPosTFF, 2 ]
				TGZ->(msUnlock())
			EndIf
	
		EndIf
		If lLoadBar
			oMeter:Set(++nCount)
			oMeter:Refresh()
		EndIf
		(cAliasTGZ)->(DbSkip())
	EndDo
	If lLoadBar
		oDlg:End()
	EndIf
Return
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} UpdAB6xTFF
@author Mateus Boiani
@since 06/11/2019
	
@description Realiza o processamento da função At870OsMont com uma barra de load
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function UpdAB6xTFF(cQryAB6Alt,cCodTFJ,oDlg,oMeter)
	Local cNewItem := ""
	Local nCount := 0
	Local lLoadBar := .F.
	
	Default oDlg := nil
	Default oMeter := nil
	
	lLoadBar := !isBlind() .AND. oMeter != nil .AND. oDlg != nil
	
	While (cQryAB6Alt)->(!EOF())
	
		AB6->( DbGoTo( (cQryAB6Alt)->AB6RECNO ) )
	
		If AB6->AB6_ITORCS <> " "
			If AB6->AB6_TPORCS == "2" .And. ;// item de Le
				TFI->(DbSeek( xFilial("TFI")+AB6->AB6_ITORCS ))
	
				cNewItem := TFI->TFI_CODSUB
	
			ElseIf AB6->AB6_TPORCS == "3" .And. ;// item de Rh
				TFF->(DbSeek( xFilial("TFF")+AB6->AB6_ITORCS ))
	
				cNewItem := TFF->TFF_CODSUB
			EndIf
		Else
			cNewItem := ""
		EndIf
	
		Reclock("AB6",.F.)
			AB6->AB6_CDORCS := cCodTFJ
			If !Empty(cNewItem)
				AB6->AB6_ITORCS := cNewItem
			EndIF
		AB6->(MsUnlock())
		If lLoadBar
			oMeter:Set(++nCount)
			oMeter:Refresh()
		EndIf
		(cQryAB6Alt)->(DbSkip())
	End
	If lLoadBar
		oDlg:End()
	EndIf
	
Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} UpdAB6xTFF
@author Mateus Boiani
@since 06/11/2019
	
@description Realiza o processamento da função At870OsMont com uma barra de load
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function UpdFatAnt(cNewAlias,cNewRev,oDlg,oMeter)
	Local nCount := 0
	Local lLoadBar := .F.
	
	Default oDlg := nil
	Default oMeter := nil
	
	lLoadBar := !isBlind() .AND. oMeter != nil .AND. oDlg != nil
	
	While (cNewAlias)->(!Eof())
		If ABX->(DbSeek(xFilial("ABX")+(cNewAlias)->(ABX_CONTRT+ABX_CONREV)))
			RecLock("ABX",.F.)
				ABX->ABX_CONREV	:= cNewRev
			ABX->(MsUnLock())
		Endif
		(cNewAlias)->(DbSkip())
	EndDo
	(cNewAlias)->(DbCloseArea())

	If lLoadBar
		oDlg:End()
	EndIf
	
Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} UpdAB6xTFF
@author Mateus Boiani
@since 06/11/2019
	
@description Realiza o processamento da função At870OsMont com uma barra de load
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function UpdRvRef(cQryTFFOld,oDlg,oMeter)
	Local nCount := 0
	Local lLoadBar := .F.
	
	Default oDlg := nil
	Default oMeter := nil
	
	lLoadBar := !isBlind() .AND. oMeter != nil .AND. oDlg != nil
	
	While (cQryTFFOld)->(!Eof())
		If TW4->( DbSeek( xFilial('TW4')+(cQryTFFOld)->TFF_COD ) )
			RecLock("TW4", .F.)
				TW4->TW4_CODTFF := (cQryTFFOld)->TFF_CODSUB
			TW4->(MsUnLock())
		Endif
	
		(cQryTFFOld)->(DbSkip())	
	
	EndDo

	If lLoadBar
		oDlg:End()
	EndIf
	
Return