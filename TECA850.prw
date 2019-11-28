#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "FWBROWSE.CH"
#INCLUDE "TECA850.CH"
#INCLUDE "GCTXDEF.CH"

//Itens da Proposta e Orçamento
#DEFINE P_MARCA  			1
#DEFINE P_PROPOS 			2
#DEFINE P_REVISA 			3
#DEFINE P_OPORTU 			4
#DEFINE P_CLIENT 			5
#DEFINE P_LOJA   			6 
#DEFINE P_NOME   			7
#DEFINE P_DATA   			8
#DEFINE P_TIPO  			9
#DEFINE P_RECOR  			10

//Itens do browse de base de atendimento
#DEFINE B_MARCA  			1
#DEFINE B_CODPRO			2
#DEFINE B_DESCRI			3
#DEFINE B_NUMSER			4
#DEFINE B_SITE  			5
#DEFINE B_CODFAB 			6
#DEFINE B_LOJFAB 			7

//Itens Funcionarios
#DEFINE P_FILIAL			1
#DEFINE P_MAT				2
#DEFINE P_NOMEFUN			3
#DEFINE P_CARGO			4
#DEFINE P_DESCARG			5
#DEFINE P_FUNCAO			6
#DEFINE P_TURNO			7
#DEFINE P_CC				8
#DEFINE P_DESFUNC			9

//Itens de recursos humanos
#DEFINE ITEMRH_PRODUT	1
#DEFINE ITEMRH_CARGO 	2
#DEFINE ITEMRH_FUNCAO	3
#DEFINE ITEMRH_PERINI	4
#DEFINE ITEMRH_PERFIM	5
#DEFINE ITEMRH_TURNO		6
#DEFINE ITEMRH_QTD		7
#DEFINE ITEMRH_CODTFF	8
#DEFINE ITEMRH_SEQTRN	9
#DEFINE ITEMRH_RECLOC	10
#DEFINE ITEMRH_FILTFF	11
#DEFINE ITEMRH_ESCALA	12
#DEFINE ITEMRH_CALEND	13
#DEFINE ITEMRH_RISCO		14

Static lTecA870  := .F.	// Determina se o assistente foi chamado a partir do TECA870 ou não (Se sim, então é um assistente de alteração do contrato)
Static lMsmCrFi  := .F.  // Mesmo cronograma financeiro para o contrato
Static lMsmCrCt  := .F.  // Mesmo cronograma contabil para o contrato
Static cCbxMsCrF := ""  // Conteudo do combo box da config. financeira
Static cCbxMsCrC := ""  // conteudo do combo box da config. contabil
Static lSigaMdtGS:= SuperGetMv("MV_NG2GS",.F.,.F.)	//Parâmetro de integração entre o SIGAMDT x SIGATEC
Static lPedIss	:= NIL //Geração de Pedidos de Contratos por ISSQN?

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECA850
Assistente de geração ou alteração do contrato no SIGAGCT, a partir do SIGATEC.
Os parâmetros existentes somente estarão preenchidos quando o assistente for
chamado a partir da rotina de Gestão de contratos (TECA870).
@param		cTFJCodigo:	Código da tabela TFJ referente ao contrato desejado
@param		cTFJContrt:	Número do contrato desejado da tabela TFJ
@param		cTFJConRev:	Revisão do contrato desejado da tabela TFJ
@author	Serviços
@since		31/10/13
@version	P11 R9
@return	.T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TECA850(cTFJCodigo, cTFJContrt, cTFJConRev, cTFJPropos, cTFJConRec)

Local aOldAlias	:= (Alias())->(GetArea())
Local aSizeDlg	:= FWGetDialogSize(oMainWnd)
Local aPeriodo	:= {STR0001, STR0002, STR0003, STR0004}  //"1 Mês"###"3 Meses"###"6 Meses"###"1 Ano"
Local aCbxSimNao := {STR0005, STR0006}//"Sim"###"Não"
Local aCbxNaoSim := {STR0006, STR0005}//"Não"###"Sim"
Local aCbxStCtr	 := {STR0107, STR0108}//"Em Elaboração"###"Vigente"
Local aMeses	 := {1,3,6,12}
Local aProposta	:= {}
Local aBase		:= {}
Local aData		:= {}
Local aBaseAt		:= {}
Local aFuncionar	:= {}

Local nTamTpCont	:= TamSx3("CN9_TPCTO")[1]
Local nTamCnPag	:= TamSx3("E4_CODIGO")[1]
Local nTamTpPl	:= TamSx3("CNL_CODIGO")[1]
Local nTamInd		:= TamSx3("CN6_CODIGO")[1]
Local nTamNrCont	:= TamSx3("TFJ_CONTRT")[1]
Local nTamRvCont	:= TamSx3("TFJ_CONREV")[1]
Local CNA_QTDREC	:= CNA->CNA_QTDREC

Local nSaveSx8Len	:= GetSx8Len()
Local nCont		:= 0
Local nPerCau		:= 0
Local nPanelWz	:= 0
Local nInd			:= 0

Local cLblNrCont	:= Alltrim(RetTitle("CN9_NUMERO"))
Local cNrCont		:= Space(nTamNrCont)
Local cContrRev	:= Space(nTamRvCont)
Local cTpCont		:= Space(nTamTpCont)
Local cCnPag		:= Space(nTamCnPag)
Local cIndice		:= Space(nTamInd)
Local cPesq1		:= Space(40)
Local cPesq		:= Space(40) 
Local cPesq2		:= Space(40) 
Local cCbxReajCt	:= ""
Local cCbxReajPl	:= ""
Local cCbxFgCau	:= STR0006
Local cCbxStCtr	:= ""
Local cPeriodo	:= ""
Local cCliProp	:= ""
Local cLjProp		:= ""
Local cOporProp	:= ""
Local cCodProp	:= ""
Local cRevProp	:= ""
Local cTitWizard	:= ""

Local lWhenNrCont	:= GetSx3Cache("CN9_NUMERO","X3_VISUAL") <> "V" 
Local lAltNrCont	:= ExistBlock("A850WHENCT") //P.E para liberar/bloquear edição do Nr. do contrato no Assistente.
Local lGera		:= .F.
Local lCancel		:= .F.
Local lRet			:= .F.
Local lProcessa		:= .T.

Local dDtIni		:= dDataBase
Local dDtFim		:= CtoD("")
Local dDtAss		:= CtoD("")
Local dDtMaxIni	:= CtoD("")
Local dDtMaxFim	:= CtoD("")

Local oOk			:= LoadBitMap(GetResources(), "LBOK")
Local oNo			:= LoadBitMap(GetResourceS(), "LBNO")
Local oModel 		:= Nil
Local oWizard		:= Nil			// objeto para criação do assistente
Local oPanel		:= Nil			// objeto para criação do Panel que conterá o Assistente
Local oPesq		:= Nil			// objeto para criação da Pesquisa da Proposta Comercial
Local oPesq2		:= Nil			// objeto para criação da Pesquisa da Base de Atendimento
Local oLbxProp	:= Nil			// oBjeto para criação de um ListBox da Proposta Comercial
Local oLbxBase	:= Nil
Local oLbxFunc	:= Nil	
Local lCauc		:= .T.
//Contrato Reccorente
Local cContRec		:= ""
Local nQtdeRec 		:= 0
Local bFinish		:= {|| lGera	:= At850VldTd(cTpCont, cCbxReajCt, cIndice, cCnPag, cTpPl, dDtIni, dDtFim, cNrCont, dDtAss, cCbxStCtr, nQtdeRec)}
Local cSubTit		:= ""

Private aItXPl	    := {}
Private cTpPl		:= Space(nTamTpPl)
Private cTpContAnt	:= Space(nTamTpCont)

Default cTFJCodigo	:= ""
Default cTFJContrt	:= ""
Default cTFJConRev	:= ""
Default cTFJPropos	:= ""

If lPedIss == NIL
	lPedIss		:=   CNB->(TamSx3("CNB_IDPED")[1]) >=  SB1->(TamSx3("B1_CODISS")[1]) .AND. CNE->(TamSx3("CNE_IDPED")[1]) >=  SB1->(TamSx3("B1_CODISS")[1])
EndIf

lTecA870	:= IsInCallStack("TECA870")

If	lTecA870

	DbSelectArea("TFJ")
	DbSetOrder(1) //TFJ_FILIAL+TFJ_CODIGO
	If	( ! Empty(cTFJCodigo) .AND. ! Empty(cTFJContrt) .AND. Empty(cTFJConRev) .AND. ! Empty(cTFJPropos) ) .AND. TFJ->( DbSeek(xFilial("TFJ")+cTFJCodigo) )
		// Somente é permitida a execução do assistente de manutenção para os casos em que o contrato esteja EM ELABORAÇÃO e NÃO POSSUA revisão. 
		
		cNrCont	:= cTFJContrt
		cContrRev	:= cTFJConRev
		cCodProp	:= cTFJPropos
		cContRec	:= cTFJConRec

		DbSelectArea("ADY")
		DbSelectArea("CNA")
		DbSelectArea("CN9")
		ADY->( DbSetOrder(1) )	// ADY_FILIAL+ADY_PROPOS
		CNA->( DbSetOrder(1) )	// CNA_FILIAL+CNA_CONTRA+CNA_REVISA+CNA_NUMERO
		CN9->( DbSetOrder(1) )	// CN9_FILIAL+CN9_NUMERO+CN9_REVISA

		If	( CN9->( DbSeek(xFilial("CN9")+cNrCont+cContrRev) ) .AND. (CN9->CN9_SITUAC == DEF_SELAB) )	//01=Cancelado;02=Elaboracao;03=Emitido;04=Aprovacao;05=Vigente;06=Paralisa.;07=Sol. Finalizacao;08=Finalizado;09=Revisao;10=Revisado

			// Inicializa as variáveis da tela do assistente
			cTpCont		:= CN9->CN9_TPCTO
			cCnPag			:= CN9->CN9_CONDPG
			// Posiciona na planilha associada ao contrato
			If ( CNA->(DbSeek(xFilial("CNA")+cNrCont+cContrRev)) )
				cTpPl		:= CNA->CNA_TIPPLA
			EndIf
			cCbxFgCau		:= If(CN9->CN9_FLGCAU == "1", STR0005, STR0006) 	// "Sim" ## "Não"
			nPerCau		:= CN9->CN9_MINCAU
			dDtIni			:= CN9->CN9_DTINIC
			dDtFim			:= CN9->CN9_DTFIM
			cCbxStCtr		:= STR0107				// "Em elaboração"
			dDtAss			:= CN9->CN9_DTASSI
			
			ADY->(DbSeek(xFilial("ADY")+cCodProp))
			cOporProp		:= ADY->ADY_OPORTU	// Oportunidade
			cRevProp		:= ADY->ADY_PREVIS	// Revisao Proposta

			aData			:= AT850DtInFim(cCodProp, cRevProp)
			dDtMaxIni		:= StoD(aData[1]) 
			dDtMaxFim		:= StoD(aData[2]) 
			
			aBaseAt		:= {}
			aBase			:= {{.F.,"","","",""}}
			At850Base(cNrCont, "", "", @aBase)
			For nInd := 1 to Len(aBase)
				aAdd(aBaseAt, aBase[nInd,B_NUMSER])
			Next nInd

			lWhenNrCont	:= .F.
			ALTERA			:= .T.
			INCLUI			:= .F.
			oModel			:= FWLoadModel("CNTA301")
			oModel:SetOperation(MODEL_OPERATION_UPDATE)
			If	!( oModel:Activate() )
				Help( "", 1, "TECA850", , STR0121, 1, 0)  // "Falha na ativação do modelo 'CNTA301'"
				lProcessa	:= .F.
			EndIf

		Else

			Help( "", 1, "TECA850", , STR0122, 1, 0,,,,,,{STR0123})  // "Contrado selecionado não está com o status igual a 'em elaboração'" ## "Esta operação é permitida apenas para contratos 'em elaboração'"
			lProcessa	:= .F.

		EndIf

	Else

		Help( "", 1, "TECA850", , STR0124, 1, 0,,,,,,{STR0125})  //"Não foi possível identificar o contrato para o qual se deseja executar o assistente de manutenção." ## "Selecione um contrato válido" 
		lProcessa	:= .F.

	EndIf

Else

	DbSelectArea("CN9")
	CN9->( DbSetOrder(1) )	// CN9_FILIAL+CN9_NUMERO+CN9_REVISA
	ALTERA		:= .F.
	INCLUI		:= .T.
	oModel		:= FWLoadModel("CNTA301")
	oModel:SetOperation(MODEL_OPERATION_INSERT)
	If	oModel:Activate()
		cNrCont	:= oModel:GetValue("CN9MASTER","CN9_NUMERO")

		// Enquanto identificar que o número já existe na base faz confirmação e solicita um novo
		While CN9->( DbSeek(xFilial("CN9")+cNrCont) ) 
			ConfirmSX8()
			cNrCont	:= CriaVar("CN9_NUMERO", .T.)
		EndDo

		If oModel:GetValue("CN9MASTER","CN9_NUMERO") <> cNrCont
			oModel:GetModel("CN9MASTER"):SetValue("CN9_NUMERO", cNrCont)
		EndIf
	Else
		Help( "", 1, "TECA850", , STR0121, 1, 0)  // "Falha na ativação do modelo 'CNTA301'"
		lProcessa	:= .F.
	EndIf

EndIf //lTecA870

If	lProcessa

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ mv_par01 - Mostra Lancamentos   S/N                          ³
	//³ mv_par02 - Aglut Lancamentos    S/N                          ³
	//³ mv_par03 - Lancamentos Online   S/N                          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lAltNrCont
		lWhenNrCont := ExecBlock("A850WHENCT",.F.,.F.)
	Else
		lWhenNrCont := .T.
	EndIf
	
	SetKey(VK_F12,{|| Pergunte("CNT100",.T.)})

	cTitWizard		:= If( lTecA870, STR0126, STR0008)	// "Assistente para alteração de contrato integrado com GCT" ## "Assistente para geração de contrato integrado com GCT"
	cSubTit		:= cTitWizard + CRLF + STR0136			// "Necessário estar vinculado a um orçamento de serviços através de uma proposta comercial"

	oWizard		:= APWizard():New(STR0007 /*<chTitle>*/,;		// "Assistente"
					                  cTitWizard /*<chMsg>*/,;
					                  STR0007 /*<cTitle>*/,;		// "Assistente"
					                  cSubTit /*<cText>*/,;
					                  {|| .T.} /*<bNext>*/,;
					                  {|| .T.} /*<bFinish>*/,;
				    	              .T. /*<lPanel>*/,;
				       	           /*<cResHead>*/,;
				           	       /*<bExecute>*/,;
				              	    .T. /*<lNoFirst>*/,;
				                  	{aSizeDlg[1], aSizeDlg[2], aSizeDlg[3]-50, aSizeDlg[4]-12} /*<aCoord>*/)

	nPanelWz		:= 1

	If	! lTecA870

		aFuncionar		:= At850Func()
		aProposta		:= At850Prop(aMeses[1])		//Carrega informações da proposta comercial

		oWizard:NewPanel(STR0009 /*<cTitle>*/,;	// "Proposta Comercial"
		                 STR0010 /*<cMsg>*/,;		// "Selecione a Proposta Comercial para Geração de Contrato no GCT"
		                 {|| .T.} /*<bBack>*/,;
		                 {|| At850VldPr(oLbxProp, @cTFJCodigo)} /*<bNext>*/,;
		                 {|| .T.} /*<bFinish>*/,;
		                 .T. /*<lPanel>*/,;
		                 {|| .T.} /*<bExecute>*/)

		oWizard:NewPanel(STR0011 /*<cTitle>*/,;	// "Base de Atendimento"
		                 STR0012 /*<cMsg>*/,;		// "Selecione a Base de Atendimento"
		                 {|| .T.} /*<bBack>*/,;
		                 {|| At850VldBa(oLbxBase, @cNrCont, TFJ->TFJ_CODENT, TFJ->TFJ_LOJA)} /*<bNext>*/,;
		                 {|| .T.} /*<bFinish>*/,;
		                 .T. /*<lPanel>*/,;
		                 {|| At850Base("", oLbxProp, oLbxBase, @aBase)} /*<bExecute>*/)

		oWizard:NewPanel(STR0095 /*<cTitle>*/,;	// "Funcionários que não são Atendentes"
		                 STR0096 /*<cMsg>*/,;		// "Cadastre os novos funcionários como Atendentes para que sejam alocados"
		                 {|| .T.} /*<bBack>*/,;
		                 {|| .T.} /*<bNext>*/,;
		                 {|| .T.} /*<bFinish>*/,;
		                 .T. /*<lPanel>*/,;
		                 {|| .T.} /*<bExecute>*/)

		oPanel			:= oWizard:GetPanel( ++ nPanelWz )
			@ 001,005 SAY STR0009 OF oPanel PIXEL SIZE 100,9 //"Proposta Comercial"
			@ 010,007 MsGet oPesq VAR cPesq OF oPanel SIZE 105,10 PIXEL
			@ 010,115 BUTTON STR0015 SIZE 30,12 OF oPanel PIXEL Action(Tk040Busca(@oLbxProp, cPesq, @oPesq, .T.)) //"Pequisar"
			@ 010,150 BUTTON STR0016 SIZE 30,12 OF oPanel PIXEL Action(Tk040Busca(@oLbxProp, cPesq, @oPesq, .F.)) //"Proximo"
			@ 010,185 SAY STR0017 OF oPanel PIXEL SIZE 90,9 //"Proposta do(s) último(s)"
			@ 010,258 COMBOBOX oPeriodo VAR cPeriodo ITEMS aPeriodo OF oPanel SIZE 40,10 PIXEL;
											ON CHANGE (	aProposta			:= At850Prop(aMeses[oPeriodo:nAt]),;
															oLbxProp:SetArray(aProposta),;
															oLbxProp:bLine	:= {||	{ If(aProposta[oLbxProp:nAt,P_MARCA], oOk, oNo),;
																						     aProposta[oLbxProp:nAt,P_PROPOS],;
																						     aProposta[oLbxProp:nAt,P_REVISA],;
																						     aProposta[oLbxProp:nAt,P_OPORTU],;
																						     aProposta[oLbxProp:nAt,P_DATA],;
																						     X3Combo("ADY_TPCONT",aProposta[oLbxProp:nAt,P_TIPO]),;
																						     aProposta[oLbxProp:nAt,11]}},;
															oLbxProp:Refresh()	)
			@ 025,007 LISTBOX oLbxProp FIELDS HEADER	"",;
															STR0018,;		//"Numero da Proposta"
															STR0019,;		//"Revisão"
															STR0020,;		//"Oportunidade"
															STR0024,;		//"Emissão"
															STR0025,;		//"Tipo"
															"Descr. Prop.",;
															SIZE	(oPanel:nWidth/2)-20,;
																	(((oPanel:nHeight/2)*0.90)-20) OF oPanel PIXEL;
																	ON dblClick(aEval(aProposta,;
																	  					{|x| x[P_MARCA]					:= .F.}),;
																	  					aProposta[oLbxProp:nAt,P_MARCA]	:= .T.,;
																	  					cCliProp							:= aProposta[oLbxProp:nAt,P_CLIENT],;
																	  					cLjProp								:= aProposta[oLbxProp:nAt,P_LOJA],;
																	  					cOporProp							:= aProposta[oLbxProp:nAt,P_OPORTU],;
																						cCodProp							:= aProposta[oLbxProp:nAt,P_PROPOS],;
																						cRevProp							:= aProposta[oLbxProp:nAt,P_REVISA],;
																						aData								:= AT850DtInFim(cCodProp,cRevProp),;
																						cCnPag								:= aData[3],;
																						dDtIni								:= CTOD(DTOC(STOD(aData[1]))),;
																						dDtFim								:= CTOD(DTOC(STOD(aData[2]))),;
																						dDtMaxIni							:= (STOD(aData[1])),;
																						dDtMaxFim							:= (STOD(aData[2])),;
																						cContRec							:= aProposta[oLbxProp:nAt,P_RECOR],;
																						oLbxProp:Refresh())

			oLbxProp:SetArray(aProposta)
			oLbxProp:bLine	:= {|| {If( aProposta[oLbxProp:nAt,P_MARCA],oOk,oNo),;
										     aProposta[oLbxProp:nAt,P_PROPOS],;
										     aProposta[oLbxProp:nAt,P_REVISA],;
										     aProposta[oLbxProp:nAt,P_OPORTU],;	
										     aProposta[oLbxProp:nAt,P_DATA],;
										     X3Combo("ADY_TPCONT",aProposta[oLbxProp:nAt,P_TIPO]),;
										     aProposta[oLbxProp:nAt,11]}}

		oPanel			:= oWizard:GetPanel( ++ nPanelWz )	//Base de Atendimento
		aBase			:= {{.F.,"","","",""}}
			@ 001,005 SAY STR0011 OF oPanel PIXEL SIZE 120,9 //Base de Atendimento
			@ 010,007 MsGet oPesq2 VAR cPesq2 OF oPanel SIZE 105,10 PIXEL
		 	@ 010,115 BUTTON STR0015	SIZE 30,12 OF oPanel PIXEL Action(Tk040Busca(@oLbxBase, cPesq2, @oPesq2, .T.))	//"Pesquisar"
		 	@ 010,150 BUTTON STR0016	SIZE 30,12 OF oPanel PIXEL Action(Tk040Busca(@oLbxBase, cPesq2, @oPesq2, .F.))	//"Próximo"
			@ 010,185 BUTTON STR0026	SIZE 30,12 OF oPanel PIXEL Action(IIF(At850Suges(oLbxProp, aProposta, @oLbxBase, @aBase), At850Base("", oLbxProp, @oLbxBase, @aBase), Nil)) //"Sugestão"
			@ 010,247 BUTTON STR0027	SIZE 50,12 OF oPanel PIXEL Action(IIF(At850IncBA()==1, At850Base("", oLbxProp, oLbxBase, @aBase), Nil)) //"Incluir nova"
			@ 025,007 LISTBOX oLbxBase FIELDS HEADER	"",;
															STR0028,;	//"Produto"
															STR0029,;	//"Descrição"
															STR0030,;	//"Identificador"
															STR0031,;	//"Site"
															SIZE	(oPanel:nWidth/2)-20,;
																	((oPanel:nHeight/2)*0.90)-20 OF oPanel PIXEL;
																	ON dblClick(aBase[oLbxBase:nAt,B_MARCA]	:= !aBase[oLbxBase:nAt,B_MARCA],;
																	            Aadd(aBaseAt, aBase[oLbxBase:nAt,B_NUMSER]),;
																	            oLbxBase:Refresh())

			oLbxBase:SetArray(aBase)
			oLbxBase:bLine	:= {|| {If(aBase[oLbxBase:nAt,B_MARCA], oOk, oNo),;
								        aBase[oLbxBase:nAt,B_CODPRO],;
								        aBase[oLbxBase:nAt,B_DESCRI],;
								        aBase[oLbxBase:nAt,B_NUMSER],;
								        aBase[oLbxBase:nAt,B_SITE]}}
			oLbxBase:Refresh()

		oPanel			:= oWizard:GetPanel( ++ nPanelWz ) //Informações referente a funcionários que não tem atendentes relacionados.
			@ 001, 005 SAY STR0097 OF oPanel PIXEL SIZE 220,9 //"Funcionários sem relacionamento com Atendentes:"
			@ 010, 007 MsGet oPesq1 VAR cPesq1 OF oPanel SIZE 105,10 F3 "CTT" PIXEL 
			@ 010, 115 BUTTON STR0015 SIZE 30,12 OF oPanel PIXEL ACTION (At850AtFnc(aFuncionar, oLbxFunc, cPesq1)) //"Pesquisar"
			@ 010, 150 BUTTON STR0098 SIZE 70,12 OF oPanel PIXEL ACTION (At850GFunc(aFuncionar), At850AtFnc(aFuncionar, oLbxFunc, cPesq1)) //""
			@ 010, 225 BUTTON STR0099 SIZE 45,12 OF oPanel PIXEL ACTION (At850CaAtd( , 3, "INCLUIR"), At850AtFnc(aFuncionar, oLbxFunc, cPesq1)) //"Cad. Atendente"*/
			@ 025, 007 LISTBOX oLbxFunc FIELDS	HEADER	STR0100,; //"Matricula"
															STR0101,; //"Nome"	
															STR0102,; //"Cargo"
															STR0103,; //"Desc. Cargo"
															STR0104,; //"Função"
															STR0105,; //"Desc. Função"
															SIZE (oPanel:nWidth/2)-20,;
															     (((oPanel:nHeight/2)*0.9)-20) of oPanel PIXEL;
															     // Popula o listbox de acordo com os valores atribuidos a variavel "afuncionar" pela function At350Func().
															     oLbxFunc:SetArray(aFuncionar)
															     oLbxFunc:bLine	:= {|| {aFuncionar[oLbxFunc:nAt,P_MAT],;
															                             aFuncionar[oLbxFunc:nAt,P_NOMEFUN],;
															                             aFuncionar[oLbxFunc:nAt,P_CARGO],;
															                             aFuncionar[oLbxFunc:nAt,P_DESCARG],;				
										 					                             aFuncionar[oLbxFunc:nAt,P_FUNCAO],;		
															                             aFuncionar[oLbxFunc:nAt,P_DESFUNC]}}

	EndIf

	oWizard:NewPanel(STR0013 /*<cTitle>*/,;	// "Informações para o Contrato"
	                 STR0014 /*<cMsg>*/,;		// "Informe os detalhes para geração do contrato."
	                 {|| .T.} /*<bBack>*/,;
	                 {|| .T.} /*<bNext>*/,;
	                 bFinish /*<bFinish>*/,;
	                 .T. /*<lPanel>*/,;
	                 {|| .T.} /*<bExecute>*/)


	oPanel:= oWizard:GetPanel( ++ nPanelWz ) //Informações do Contrato
		//Número do Contrato
		@ 010,010 SAY cLblNrCont + "*"	OF oPanel SIZE 200,009 PIXEL
		@ 010,230 MsGet	cNrCont ;
							VALID VldNrCont(cNrCont) ;
							WHEN lWhenNrCont ;
							OF oPanel SIZE 080,010 PIXEL

		//Tipo de Contrato
		@ 025,010 SAY STR0032	OF oPanel SIZE 200,009 PIXEL	// "Tipo de contrato*"
		@ 025,230 MsGet	cTpCont ;
							F3 "CN1" ;
							VALID	Vazio(cTpCont) .OR.;
									( ExistCpo("CN1",cTpCont,1) .AND. At850TpCt(cTpCont) ) ;
							OF oPanel SIZE 030,010 PIXEL

		//Condição de Pagamento
		@ 040,010 SAY STR0033	OF oPanel SIZE 200,009 PIXEL	// "Condição de pagamento*"
		@ 040,230 MsGet	cCnPag ;
							F3 "SE4" ;
							VALID ( Vazio(cCnPag) .OR. ExistCpo("SE4",cCnPag,1) ) ;
							OF oPanel SIZE 030,010 PIXEL
		
		//Tipo de Planilha
		@ 055,010 SAY STR0036	OF oPanel SIZE 200,009 PIXEL	// "Tipo de planilha*"
		@ 055,230 MsGet	cTpPl ;
							F3 "CNL" ;
							VALID ( Vazio(cTpPl) .OR. ( ExistCpo("CNL",cTpPl,1) .AND. At850TpPl(cTpPl,cContRec,cOporProp)) ) ;
							OF oPanel SIZE 030,010 PIXEL

		//Reajuste da caução
		@ 070,010 SAY STR0038	OF oPanel SIZE 200,009 PIXEL	// "Caução*"
		@ 070,230 Combobox oCbxFgCau ;
							VAR cCbxFgCau ;
							ITEMS aCbxSimNao ;
							VALID IIf(cCbxFgCau == "Não", Eval({|| nPerCau := 0, lCauc := .F. ,.T.}), Eval({|| lCauc := .T., .T.})) ;
							OF oPanel SIZE 030,010 PIXEL

		//Percentual do Caução
		@ 085,010 SAY STR0074	OF oPanel SIZE 200,009 PIXEL	// "Percentual Caução*"
		@ 085,230 MsGet	nPerCau ;
							PICTURE "@R 99.99" ;
							WHEN lCauc;
							VALID If(	cCbxFgCau == "Sim",;	// "Sim"
										Eval({|| nPerCau > 0 .AND. nPerCau <= 100}),;
										Eval({|| nPerCau == 0})) ;
							OF oPanel SIZE 050,010 PIXEL

		//Data Inicial
		@ 100,010 SAY STR0039	OF oPanel SIZE 200,009 PIXEL	// "Data Inicial do contrato*"
		@ 100,230 MsGet	dDtIni ;
							VALID !( Empty(dDtIni) ) .and.( Eval({||at850ValDt(dDtIni,dDtMaxIni)}) ) ;
							OF oPanel SIZE 050,010 PIXEL

		//Data Final
		@ 115,010 SAY STR0040	OF oPanel SIZE 200,009 PIXEL	// "Data Final do contrato*"
		@ 115,230 MsGet	dDtFim ;
							WHEN !(cContRec == "1") ;	// "Contrato Reccorente"
							VALID ( !Empty(dDtFim)) .AND. (dDtFim > dDtIni) .and. ( Eval({||at850ValDt(dDtFim,dDtMaxFim,'FIM')}) ) ;
							OF oPanel SIZE 050,010 PIXEL

		//Status Contrato
		@ 130,010 SAY STR0109	OF oPanel SIZE 200,009 PIXEL	// "Status do contrato*"
		@ 130,230 Combobox oCbxStCtr ;
							VAR cCbxStCtr ;
							ITEMS aCbxStCtr ;
							VALID If(	cCbxStCtr == STR0107,;	// "Em elaboração"
										Eval({|| dDtAss := CtoD(Space(08))}),;
										Eval({|| .T.})) ;
							OF oPanel SIZE 055,010 PIXEL

		//Data Assinatura do Contrato
		@ 145,010 SAY STR0117	OF oPanel SIZE 200,009 PIXEL	// "Data Assinatura do Contrato"
		@ 145,230 MsGet	dDtAss ;
							WHEN cCbxStCtr == STR0108 ;	// "Vigente"
							OF oPanel SIZE 050,010 PIXEL
							
		//Quantidade de Recorrencia
		@ 160,010 SAY STR0169	OF oPanel SIZE 200,009 PIXEL// "Quantidade de Recorrência"
		@ 160,230 MsGet	nQtdeRec ;
							WHEN cContRec == "1" ;	// "Contrato Reccorente (1-Sim/2-Não)"
							VALID (nQtdeRec >= 1) .And. ( Eval({||CN300VlRec(,,nQtdeRec)}));
							OF oPanel SIZE 050,010 PIXEL PICTURE PesqPict("CNA","CNA_QTDREC")						
		
		//Utiliza a mesma conf. de cronograma financeiro para todos os locais?
		@ 175,010 SAY STR0159	OF oPanel SIZE 200,009 PIXEL	//Utiliza a mesma conf. de cronograma financeiro para todos os locais?
		@ 175,230 Combobox oCbxMsCrF ;
							VAR cCbxMsCrF ;
							ITEMS aCbxNaoSim ;
							WHEN lMsmCrFi;
							OF oPanel SIZE 030,010 PIXEL	
	
		//Utiliza a mesma conf. de cronograma contábil para todos os locais?
		@ 190,010 SAY STR0160	OF oPanel SIZE 200,009 PIXEL	//Utiliza a mesma conf. de cronograma contábil para todos os locais?
		@ 190,230 Combobox oCbxMsCrC ;
							VAR cCbxMsCrC ;
							ITEMS aCbxNaoSim ;
							WHEN lMsmCrCt;
							OF oPanel SIZE 030,010 PIXEL
		
	oWizard:Activate(	.T. /*<lCenter>*/,;
						{|| ( lGera .OR. (lCancel := MsgYesNo(STR0041)) )} /*<bValid>*/,;	// "Tem certeza que deseja cancelar o Assistente?"
						{|| .T.} /*<bInit>*/,;
						{|| .T.} /*<bWhen>*/)

	If lGera .AND. !lCancel

		lRet	:= At850ExcAt(	cTpCont,;									 // Tipo do contrato
									cCnPag,;								 // Condição de Pagamento
									cCbxReajCt,;							 // Determina se o contrato tem Reajuste.
									cIndice,;								 // Indice do reajuste
									At850AtDat(cOporProp, dDtIni, dDtFim),;	 // Datas, com destaque para data de vigência
									cTpPl,;									 // Tipo da planilha
									cCbxReajPl,;							 // Determina se planilha tem Reajuste.
									cCodProp,;								 // Proposta Comercial
									cRevProp,;								 // Revisão da proposta
									dDtIni,;								 // Data Inicial do Contrato
									dDtFim,;								 // Data Final do Contrato
									cCbxFgCau,;								 // Determina se caução tem Reajuste.
									aBaseAt,;								 // Bases de atendimento
									nPerCau,;								 // Percentual de caução
									cCbxStCtr,;								 // Situação do contrato
									cNrCont,;								 // Número do contrato
									dDtAss,;								 // Data da Assinatura do Contrato
									oModel,;								 // Modelo de dados do contrato (TECA301)
									nQtdeRec,;                               // Quantidade de Recorrencia
									(cCbxMsCrF == STR0005),;				 //"Sim" //Utiliza a mesma conf. de cronograma financeiro para todos os locais?
									(cCbxMsCrC == STR0005), ;				 //"Sim" //Utiliza a mesma conf. de cronograma contábil para todos os locais?
									cOporProp)              
		If	lRet

			If	! lTecA870
				While GetSx8Len() > nSaveSx8Len
					CN9->( ConfirmSX8()) 
					DbSkip()
				EndDo
			EndIf
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³SIGATEC WorkFlow # "GC - Geração do Contrato no Assistente de Contratos  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If !Empty(TFJ->TFJ_GRPCOM)
				At774Mail("TFJ",TFJ->TFJ_GRPCOM,"GC","<b>"+STR0119+"</b> "+TFJ->TFJ_PROPOS+"<b> "+STR0120+"</b>"+TFJ->TFJ_CONTRT) //"Num.Proposta: " # "Nr. Contrato: "
			Endif
			MsgInfo(STR0127)  // "Assistente de contratos processado!"
		Else
			MsgAlert(STR0133, STR0043)  // "Ocorreu uma inconsistência no momento da efetivação do assistente de contratos." ### "Atenção"
		EndIf
	Else

		If	! lTecA870
			While GetSx8Len() > nSaveSx8Len
				CN9->(RollBackSX8())
				DbSkip()
			EndDo
			FreeUsedCode()  //libera codigos reservados pela MayIUseCode()
		EndIf	
		MsgAlert(STR0128, STR0043)  // "Assistente de contratos não processado ou cancelado pelo usuário!" ### "Atenção"
	EndIf
EndIf
RestArea(aOldAlias)
Return (.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} VldNrCont

Valid número do contrato
@author Serviços
@since 17/09/14
@version P12
@param cNrCont: Número do contrato a ser validado
@return  lRet -> .T., Validou, .F. -> Não validou 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function VldNrCont(cNrCont)

Local lRet	:= ExistChav("CN9",cNrCont)

//verifica se esta na memoria, sendo usado busca o proximo numero disponivel 
If lRet .And. !MayIUseCode("CN9_NUMERO"+xFilial("CN9")+cNrCont)
	Aviso(STR0111,STR0112, {STR0055}, 2) //"Nr. Contrato"###"O contrato já existe"###"OK"
	lRet := .F.	
EndIf
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850Prop

Carrega propostas comerciais que sejam do tipo Integração com GCT
@author Serviços
@since 31/10/13
@version P11 R9
@param nQtdMeses: Quantidade de meses para pesquisa
@return  .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At850Prop(nQtdMeses)
Local aArea		:= GetArea()
Local dCorte		:= dDataBase - (nQtdMeses * 30)
Local cAliasAD1	:= GetNextAlias()
Local cFilAD1		:= xFilial("AD1")
Local cFilADY		:= xFilial("ADY")
Local cQuery		:= ""
Local aProp		:= {}
Local cNome 	:= ""

DbSelectArea("ADY")
DbSetOrder(1) //ADY_FILIAL+ADY_PROPOS

cQuery :=	"SELECT AD1_FILIAL, AD1_DESCRI, AD1_DATA, AD1_STATUS, AD1_PROPOS, AD1_REVISA, AD1_CODCLI, AD1_LOJCLI, TFJ_CNTREC "
cQuery +=   "FROM " + RetSqlName("AD1") + " AD1 "
cQuery	+=         "INNER JOIN " + RetSqlName("ADY") + " ADY "
cQuery +=                       "ON ADY.ADY_FILIAL = AD1.AD1_FILIAL "
cQuery +=                      "AND ADY.D_E_L_E_T_ = '' "
cQuery	+=                      "AND ADY.ADY_PROPOS = AD1.AD1_PROPOS "
cQuery	+=                      "AND ADY.ADY_REVISA = AD1.AD1_REVISA "
cQuery +=         "INNER JOIN " + RetSqlName("TFJ") + " TFJ "
cQuery +=                       "ON TFJ.TFJ_FILIAL = ADY.ADY_FILIAL "
cQuery +=                      "AND TFJ.D_E_L_E_T_ = '' "
cQuery	+=                      "AND TFJ.TFJ_PROPOS = ADY.ADY_PROPOS "
cQuery	+=                      "AND TFJ.TFJ_PREVIS = ADY.ADY_PREVIS "
cQuery +=  "WHERE AD1.AD1_FILIAL = '" + cFilAD1 + "' "
cQuery +=    "AND AD1.D_E_L_E_T_ = '' "
cQuery +=    "AND AD1.AD1_DATA >= '" + DtoS(dCorte) + "' "
cQuery +=    "AND AD1.AD1_DATA <= '" + DtoS(dDataBase) + "' "
cQuery +=    "AND AD1.AD1_STATUS = '9' "
cQuery +=    "AND AD1.AD1_PROPOS <> ' ' "
cQuery +=    "AND TFJ.TFJ_CONTRT = ' ' "
cQuery +=  "ORDER BY AD1.AD1_FILIAL, AD1.AD1_DATA, AD1.AD1_NROPOR, AD1.AD1_REVISA "

cQuery := ChangeQuery(cQuery)
DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasAD1,.T.,.T.)
TCSetField(cAliasAD1,"AD1_DATA","D")

While (cAliasAD1)->(! Eof())
	If ADY->(DbSeek(cFilADY + (cAliasAD1)->AD1_PROPOS)) .AND. Empty(ADY->ADY_PROCES) .AND. ADY->ADY_TPCONT $ "4"		
		cNome := Posicione("SA1",1,xFilial("SA1")+ADY->ADY_CODIGO+ADY->ADY_LOJA,"A1_NOME")	
		//Considerar os DEFINES no inicio do fonte
		aAdd(aProp, { .F.,;							// Marca
						ADY->ADY_PROPOS,;				// Proposta
						ADY->ADY_PREVIS,;				// Revisao Proposta
						ADY->ADY_OPORTU,;				// Oportunidade
						(cAliasAD1)->AD1_CODCLI,;	// Codigo
						(cAliasAD1)->AD1_LOJCLI,;	// Loja
						cNome,;						// Nome do cliente
						ADY->ADY_DATA,;				// Emissao
						ADY->ADY_TPCONT,;			// Tipo de contrato
						(cAliasAD1)->TFJ_CNTREC,;	// Contrato Reccorente (1-Sim/2-Não)
						(cAliasAD1)->AD1_DESCRI})	// Descrição da proposta
	EndIf
	(cAliasAD1)->(DbSkip())
EndDo
(cAliasAD1)->(DbCloseArea())

//Se nao encontrou propostas, inicializa um array vazio
If Len(aProp) == 0
	aProp :={{.F.,"","","","","","","","","",""}}
EndIf
RestArea(aArea)
Return aProp

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850Base

Carrega Base de Atendimento
@param		oLbxProp: proposta Selecionada
@param		oLbxBase: Base selecionada
@param		aBase:array para bases
@return	.T. 
@author	Serviços
@since		31/10/13
@version	P11 R9
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At850Base(cNrCont, oLbxProp, oLbxBase, aBase)

Local aArea		:= GetArea()
Local cAliasAA3	:= GetNextAlias()
Local cFilAA3		:= xFilial("AA3")
Local nTamNrCont	:= TamSx3("TFJ_CONTRT")[1]
Local nItSel 		:= 0
Local cQuery		:= "" 
Local cCodCli		:= ""
Local cLojCli		:= ""
Local cDescPro	:= ""
Local oOk			:= NIL
Local oNo			:= NIL

Default cNrCont	:= Space(nTamNrCont)

aBase := {}

cQuery := "SELECT AA3_FILIAL, AA3_CODCLI, AA3_LOJA, AA3_NUMSER, AA3_CODPRO, AA3_SITE, AA3_CODFAB, AA3_LOJAFA, AA3_CONTRT "
cQuery +=   "FROM " + RetSqlName("AA3") + " AA3 "
cQuery +=  "WHERE AA3.AA3_FILIAL = '" + cFilAA3 + "' "
cQuery +=    "AND AA3.D_E_L_E_T_ = '' "

If	!(lTecA870)

	nItSel 	:= aScan(oLbxProp:aArray,{|x| x[P_MARCA] })
	cCodCli	:= oLbxProp:aArray[nItSel][P_CLIENT]
	cLojCli	:= oLbxProp:aArray[nItSel][P_LOJA]
	oOk			:= LoadBitMap(GetResources(), "LBOK")
	oNo			:= LoadBitMap(GetResources(), "LBNO")

	cQuery +=    "AND AA3.AA3_CODCLI = '" + cCodCli + "' "
	cQuery +=    "AND AA3.AA3_LOJA = '" + cLojCli + "' "
Else
	cQuery +=    "AND AA3.AA3_ORIGEM = 'CN9' "
EndIf

cQuery +=    "AND AA3.AA3_CONTRT = '" + cNrCont + "' "
cQuery +=    "AND AA3.AA3_EQALOC = '2' "
cQuery +=  "ORDER BY AA3.AA3_FILIAL, AA3.AA3_CODCLI, AA3.AA3_LOJA, AA3.AA3_CODPRO, AA3.AA3_NUMSER"

cQuery := ChangeQuery(cQuery)
DbUseArea(.T., "TOPCONN", TcGenQry(,,cQuery), cAliasAA3, .T., .T.)
While	&(cAliasAA3)->(! Eof())	
	aAdd(aBase, {	.F.	,;																			//Marca
					(cAliasAA3)->AA3_CODPRO,;													//Cod. Produto
					Posicione("SB1",1,xFilial("SB1")+(cAliasAA3)->AA3_CODPRO,"B1_DESC"),;	//Descricao
					(cAliasAA3)->AA3_NUMSER,;													//Id. Unico
					(cAliasAA3)->AA3_SITE,;														//Site
					(cAliasAA3)->AA3_CODFAB,;													//Cod. Fabricante
					(cAliasAA3)->AA3_LOJAFA})													//Loja Fabricante
	&(cAliasAA3)->(DbSkip())
EndDo
&(cAliasAA3)->(DbCloseArea())

If Len(aBase) == 0
	aBase := {{.F.,"","","",""}}
EndIf

If	!(lTecA870)
	oLbxBase:SetArray(aBase)
	oLbxBase:bLine	:= {||	{If(aBase[oLbxBase:nAt,1],oOk,oNo),;
								aBase[oLbxBase:nAt,2],;
								aBase[oLbxBase:nAt,3],;
								aBase[oLbxBase:nAt,4],;
								aBase[oLbxBase:nAt,5]}}
	oLbxBase:Refresh()
EndIf

RestArea(aArea)
Return .T.

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850Suges

Sugere uma base de atendimento para a proposta.
@author Serviços
@since 31/10/13
@version P11 R9
@param oLbxProp: proposta Selecionada
@return  .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At850Suges(oLbxProp,aProposta,oLbxBase)

Local aAreaADZ	:= ADZ->(GetArea())					// Area da tabela ADZ.
Local lRetorno	:= .T.								// Retorno da rotina.
Local nPos			:= 0								// Posicao da marca.
Local cCodProp	:= ""								// Codigo da proposta comercial.
Local cRevProp	:= ""								// Revisao da proposta comercial.
Local cIdUnico	:= ""								// Identificador da base.
Local aLocais 	:= {}								// Locais de atendimento.
Local oDlg			:= Nil								// Dialog principal.
Local aSize	 	:= FWGetDialogSize( oMainWnd ) 		// Array com tamanho da janela.
Local oColSugest	:= Nil								// Coluna sugestao de base de atendimento.
Local oBrwSugest	:= Nil								// Browse sugestao de base de atendimento.
Local cOportunid	:= ""
Local cIDNovo		:= ""
Local nTamNumSer	:= TAMSX3("AA3_NUMSER")[1] 
Local cProBase 		:= ""
Local lTFF 			:= .F.

//Codigo da proposta selecionada
nPos 		:= 	aScan(oLbxProp:aArray,{|x| x[P_MARCA]})
cCodProp 	:= 	oLbxProp:aArray[nPos,P_PROPOS]
cRevProp 	:= 	oLbxProp:aArray[nPos,P_REVISA]
cOportunid	:=	oLbxProp:aArray[nPos,P_OPORTU]
cIDNovo	:= SUBSTR(cOportunid+cCodProp,1,nTamNumSer)+REPLICATE("0",nTamNumSer-Len(SUBSTR(cOportunid+cCodProp,1,nTamNumSer))-1)+"1"

DbSelectArea("ADY")
DbSetOrder(1) //ADY_FILIAL+ADY_PROPOS

If DbSeek(xFilial("ADY")+cCodProp)

	// ADZ_FILIAL+ADZ_PROPOS+ADZ_REVISA+ADZ_FOLDER+ADZ_ITEM
	DbSelectArea("ADZ")
	ADZ->(DbSetOrder(3))
	
	DbSelectArea("TFJ")
	TFJ->(DbSetOrder(2)) // TFJ_FILIAL+TFJ_PROPOS+TFJ_PREVIS
	
	DbSelectArea("TFL")
	TFL->(DbSetOrder(2)) // TFL_FILIAL + TFL_CODPAI

	DbSelectArea("TFF")
	TFF->(DbSetOrder(3))  // TFF_FILIAL + TFF_CODPAI

	DbSelectArea("TFI")
	TFI->(DbSetOrder(3))  // TFI_FILIAL + TFI_CODPAI
	
	If ADZ->(DbSeek(xFilial("ADZ")+cCodProp+cRevProp)) .And. ;
		TFJ->( DbSeek( xFilial("TFJ")+cCodProp+cRevProp ) ) .And. ;
		TFL->( DbSeek( xFilial("TFL")+TFJ->TFJ_CODIGO ) ) .And. ;
		( ( lTFF := TFF->( DbSeek( xFilial("TFF")+TFL->TFL_CODIGO ) ) ) .Or.; 
		TFI->( DbSeek( xFilial("TFI")+TFL->TFL_CODIGO ) ) )
		
		If TFJ->TFJ_DSGCN == '1'
			// quando não é agrupado pega o primeiro produto de rh da TFF
			If lTFF
				cProBase := TFF->TFF_PRODUT
			Else
				cProBase := TFI->TFI_PRODUT
			EndIf
		Else
			// quando agrupado pega o produto de rh do cabeçalho
			cProBase := TFJ->TFJ_GRPRH
		EndIf
		
			aAdd(aLocais, {ADY->ADY_CODIGO,;
			               ADY->ADY_LOJA,;
						cProBase,;
						Posicione("SB1",1,xFilial("SB1")+cProBase,"B1_DESC"),;
			               cIDNovo,;
			               ADZ->ADZ_LOCAL,;
			               Posicione("ABS",1,xFilial("ABS")+ADZ->ADZ_LOCAL,"ABS_DESCRI")})
	EndIf

	If Len(aLocais) > 0

		DEFINE DIALOG oDlg TITLE STR0044 FROM aSize[1]*0.07,aSize[2]*0.75 TO aSize[3]*0.47,aSize[4]*0.75 PIXEL  // "Sugestão de Bases de Atendimento"

		DEFINE FWBROWSE oBrwSugest DATA ARRAY ARRAY aLocais LINE BEGIN 1 EDITCELL { |lCancel,oBrowse| At850VdEdt(lCancel,oBrowse,aLocais) } OF oDlg

		ADD COLUMN oColSugest DATA &("{ || aLocais[oBrwSugest:At()][3] }")  TITLE TxDadosCpo("AA3_CODPRO")[1] SIZE TamSX3("AA3_CODPRO")[1] OF oBrwSugest   											// "Produto/Eqto"
		ADD COLUMN oColSugest DATA &("{ || aLocais[oBrwSugest:At()][4] }")  TITLE TxDadosCpo("AA3_DESPRO")[1] SIZE TamSX3("AA3_DESPRO")[1] OF oBrwSugest   											// "Desc.Produto"
		ADD COLUMN oColSugest DATA &("{ || aLocais[oBrwSugest:At()][5] }")  TITLE TxDadosCpo("AA3_NUMSER")[1] SIZE TamSX3("AA3_NUMSER")[1] PICTURE "@!" EDIT  READVAR "cIdUnico" OF oBrwSugest  	// "Id.Unico"
		ADD COLUMN oColSugest DATA &("{ || aLocais[oBrwSugest:At()][6] }")  TITLE TxDadosCpo("AA3_CODLOC")[1] SIZE TamSX3("AA3_CODLOC")[1] OF oBrwSugest   											// "Cod. Local"
		ADD COLUMN oColSugest DATA &("{ || aLocais[oBrwSugest:At()][7] }")  TITLE TxDadosCpo("ABS_DESCRI")[1] SIZE TamSX3("ABS_DESCRI")[1] OF oBrwSugest    											// "Descrição."

		ACTIVATE FWBROWSE oBrwSugest

		ACTIVATE DIALOG oDlg ON INIT EnchoiceBar(oDlg,{|| IIF(At850VdGvb(aLocais),MsgRun(STR0071,STR0068,{|| At850GvBse(aLocais),oDlg:End()}),lRetorno := .F. )},{|| lRetorno := .F.,oDlg:End()}) CENTERED // "Gerando as bases de atendimento..."###"Aguarde"
	Else
		MsgAlert(STR0042,STR0043)  // "Não há sugestão de bases de atendimento para esta proposta comercial."###"Atenção"
		lRetorno := .F.
	EndIf

Else
	MsgStop(STR0045,STR0043)// "Proposta comercial não localizada."###"Atenção"
	lRetorno := .F.
EndIf

RestArea(aAreaADZ)
oLbxBase:Refresh()
Return( lRetorno )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850VdEdt

Validação na sugestão da Base de atendimento
@author Serviços
@since 31/10/13
@version P11 R9
@param lCancel: Cancelamento
@param oBrowse: Browse
@param aLocais: Locais de atendimento
@return  .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At850VdEdt(lCancel,oBrowse,aLocais)

Local lRetorno	:= .T.						// Retorno da rotina.
Local nX			:= 0						// Incremento utilizado no For.
Local cConteudo	:= &(ReadVar())			// Conteudo em memoria do campo.
Local cChvPos		:= ""						// Chave posicionada.
Local cChvAtu		:= ""						// Chave atual.
Local nAux			:= 0						// Variavel auxiliar da linha do aCols.

If Type("n") <> "U"
	nAux := n
	n := Nil
EndIf

If !lCancel

	cChvPos := aLocais[oBrowse:nAt][1]+aLocais[oBrowse:nAt][2]+aLocais[oBrowse:nAt][3]+cConteudo

	RegToMemory("AA3",.T.,.F.,.F.)

	For nX := 1 To Len(aLocais)

		cChvAtu := aLocais[nX][1]+aLocais[nX][2]+aLocais[nX][3]+aLocais[nX][5]

		If nX <> oBrowse:nAt .AND. !Empty(cConteudo) .AND. cChvAtu == cChvPos
			MsgStop(STR0046,STR0043)	// "Identificador já informado para este produto."###"Atenção"
			lRetorno := .F.
			Exit
		EndIf

		If lRetorno

			M->AA3_CODCLI	:= aLocais[nX][1]
			M->AA3_LOJA 	:= aLocais[nX][2]
			M->AA3_CODPRO	:= aLocais[nX][3]
			M->AA3_NUMSER	:= cConteudo

			If !( At040SkSer() .AND. ExistChav("AA3",M->AA3_CODCLI+M->AA3_LOJA+M->AA3_CODPRO+M->AA3_NUMSER) )
				lRetorno := .F.
				Exit
			EndIf

		EndIf

	Next nX

	If lRetorno
		aLocais[oBrowse:nAt][5] := cConteudo
	EndIf

EndIf

If nAux <> 0
	n := nAux
EndIf

Return( lRetorno )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850IncBA

Inclusão de Base de Atendimento
@author Serviços
@since 31/10/13
@version P11 R9
@return  .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At850IncBA()

Local aArea		:= GetArea()
Local nOpcA		:= 0  

SaveInter()

Private aRotina := {	{ STR0015	,"AxPesqui"  	,0	,1	,0	,.F.},;//"Pesquisar"
						{ STR0047	,"At040Visua"	,0	,2	,0	,.T.},;	//"Visualizar"
						{ STR0048	,"At040Inclu"	,0	,3	,0	,.T.}} 	//"Incluir"

Private cCadastro := STR0049 // "INCLUSÃO - Base de Atendimento"    

ALTERA	:= .F.
INCLUI	:= .T.

nOpcA := At040Inclu("AA3",0,3)

RestInter()
RestArea(aArea)
Return nOpcA

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850VdGvb

Validação Browse sugestão
@author Serviços
@since 31/10/13
@version P11 R9
@param aLocais:locais de atencimento
@return  .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At850VdGvb(aLocais)

Local lRetorno := .T.	// Retorno da rotina.

aEval(aLocais,{|x| IIF(Empty(x[5]),lRetorno := .F., Nil)})

If !lRetorno
	MsgStop(STR0050,STR0043) // "Identificador não informado."##"Atenção"
EndIf

Return( lRetorno )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850GvBse

Grava Base de atendimento atraves dos locais de atendimento
@author Serviços
@since 31/10/13
@version P11 R9
@param aLocais:locais de atencimento
@return  .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At850GvBse(aLocais)

Local lRetorno	:= .T.			// Retorno da rotina.
Local nX		:= 0			// Incremento utilizado no For.
Local aCabec	:= {}			// Array que contem o cabeçalho da tabela AA3.
Local aItens	:= {}			// Array itens da base de atendimento.

Private lMsErroAuto	:= .F.

For nX := 1 To Len(aLocais)

	Aadd(aCabec,{"AA3_FILIAL"	,xFilial("AA3")	,Nil})
	Aadd(aCabec,{"AA3_CODCLI"	,aLocais[nX][1]	,Nil})
	Aadd(aCabec,{"AA3_LOJA"  	,aLocais[nX][2]	,Nil})
	Aadd(aCabec,{"AA3_CODPRO"	,aLocais[nX][3]	,Nil})
	Aadd(aCabec,{"AA3_NUMSER"	,aLocais[nX][5]	,Nil})
	Aadd(aCabec,{"AA3_DTVEN"	,Date()			,Nil})
	Aadd(aCabec,{"AA3_CODLOC"	,aLocais[nX][6]	,Nil})

	MsExecAuto( {|w,x,y,z| TECA040(w,x,y,z)},Nil,aCabec,aItens, 3)

	If lMsErroAuto
		MostraErro()
	EndIf

	aCabec	:= {}
	aItens	:= {}

Next nX

Return( lRetorno )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850VldPr

Valida seleção da Proposta Comercial
@author Serviços
@since 31/10/13
@version P11 R9
@param oLbxProp:Informações da proposta comercial
@return  .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At850VldPr(oLbxProp, cTFJCodigo) 

Local lRet		:= .T.
Local nItSel	:= 0

Default cTFJCodigo := ""

nItSel := aScan(oLbxProp:aArray,{|x| x[P_MARCA] })

If nItSel == 0
	MsgInfo(STR0051) //"Selecione a oportunidade / proposta para geração dos contratos"
	lRet := .F.
ElseIf Empty(oLbxProp:aArray[nItSel][P_PROPOS])
	MsgInfo(STR0052) //"Não há nenhuma oportunidade encerrada com propostas para geração de contratos no período selecionado"
	lRet := .F.
EndIf

If lRet
	DbSelectArea("TFJ")
	TFJ->( DbSetOrder( 2 ) ) // TFJ_FILIAL + TFJ_PROPOS + TFJ_PREVIS
	TFJ->( DbSeek( xFilial("TFJ") + oLbxProp:aArray[nItSel,P_PROPOS] + oLbxProp:aArray[nItSel,P_REVISA] ) )
	cTFJCodigo := TFJ->TFJ_CODIGO
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850TpCt

Verifica o tipo do contrato
@author Serviços
@since 31/10/13
@version P11 R9
@param cTContr:Tipo do Contrato
@return  .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At850TpCt(cTContr) // Verifica o tipo do contrato

Local lRet		 := .F.
Local aArea 	 := GetArea()

Default cTContr := ""

DbSelectArea("CN1")
DbSetOrder(1)

If CN1->(DbSeek(xFilial("CN1") + cTContr))
	If CN1->CN1_MEDEVE == "1"
		Aviso(STR0053, STR0054, {STR0055}, 2)//"Tipo do Contrato"###"O Tipo de Contrato Selecionado possui medição eventual, em contratos com medição eventual não será possível à realização de medições de serviços."###"OK"
		lRet	:=	.T.
	Else
		lRet	:= .T.
	EndIf
	If CN1->CN1_ESPCTR == "1" .OR. CN1->CN1_CTRFIX == "2"
		lRet	:= .F.
		Do Case
			Case CN1->CN1_ESPCTR == "1"
				Aviso(STR0053, STR0057, {STR0055}, 2) //"Tipo do Contrato"###"A espécie do contrato deve ser de Venda!"###"OK"
			Case CN1->CN1_CTRFIX == "2"
				Aviso(STR0053, STR0059, {STR0055}, 2) //"Tipo do Contrato"###"O tipo do contrato deve ser do tipo fixo!"###"OK"
		EndCase
	EndIf
	If CN1->CN1_CROFIS <> "2"
		Aviso(STR0053, STR0116, {STR0055}, 2)//"O Tipo de Contrato Selecionado deve ser com configurado para não gerar cronograma fisico." ### "OK"
		lRet	:=	.F.
	EndIf
EndIf

//Apago o conteúdo do tipo de planilha e bloqueio os campos de replica de configuração sempre que o usuario alterar o tipo de contrato
If cTContr <> cTpContAnt
	cTpPl 		:= Space(TamSx3("CNL_CODIGO")[1])
	cCbxMsCrF 	:= STR0006
	cCbxMsCrC 	:= STR0006
	lMsmCrCt	:= .F.
	lMsmCrFi	:= .F.
	cTpContAnt	:= cTContr
EndIf

RestArea(aArea)
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850VldBa

Verifica se foi selecionado bases de atendimento
@author Serviços
@since 31/10/13
@version P11 R9
@param oLbxBase:Informações da base de atendimento
@return  .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function	At850VldBa(oLbxBase, cNrCont, cCliente, cLoja)

Local lRet 		:= .T.
Local nItSel	:= 0

nItSel := aScan(oLbxBase:aArray,{|x| x[B_MARCA] })

If nItSel == 0
	MsgInfo(STR0060) //"Selecione a base de atendimento para geração dos contratos."
	lRet := .F.
ElseIf Empty(oLbxBase:aArray[nItSel][B_NUMSER])
	MsgInfo(STR0061) //"A base de atendimento selecionada é inválida."
	lRet := .F.
EndIf

If ExistBlock("A850NRCNT") //Ponto de entrada para alterar o número de contrato de acordo com a política do cliente.
	cNrCont := ExecBlock("A850NRCNT",.F.,.F.)
Endif

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850VldTd

Validações das informações do contrato.
@param		cTpCont:		Tipo do contrato
@param		cCbxReajCt:	Determina se o contrato tem reajuste
@param		cIndice:		Indice do reajuste
@param		cCnPag:		Condição de pagamento
@param		cTpPl:			Tipo da planilha
@param		dDtIni:		Data inicial do contrato
@param		dDtFim:		Data final do contrato
@param		cNrCont:		Número do contrato
@param		dDtAss:		Data da assinatura do contrato
@param		cCbxStCtr:		Situação para o contrato
@return	.T. = Informações do assistente válidas // .F. = Informações do assistente inválidas
@author	Serviços
@since		31/10/13
@version	P11 R9
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At850VldTd(cTpCont, cCbxReajCt, cIndice, cCnPag, cTpPl, dDtIni, dDtFim, cNrCont, dDtAss, cCbxStCtr, nQtdRec)

Local lRet	:= .T.
Local lGeraCronFin := .F.
Local lPlanRecorrente := .F.
Local lIsFatAntecip := TFJ->TFJ_ANTECI == "1"  // verificar o posicionamento da TFJ
Local lIsRecorrente := TFJ->TFJ_CNTREC == "1"  // verificar o posicionamento da TFJ

Do Case
	Case Empty(cTpCont)
		MsgAlert(STR0062, STR0043)  // "Tipo de Contrato é obrigatório!" ### "Atenção"
		lRet	:=	.F.
	Case Empty(cCnPag)
		MsgAlert(STR0063, STR0043)  // "Condição de Pagamento é obrigatório!" ### "Atenção"
		lRet	:= .F.
	Case cCbxReajCt == STR0005 .AND. Empty(cIndice)	// "Sim"
		MsgAlert(STR0064, STR0043)  // "Todo contrato com possibilidade de Reajuste deve ter preenchido um Índice!" ### "Atenção"
		lRet	:= .F.
	Case Empty(cTpPl)
		MsgAlert(STR0065, STR0043)  // "Tipo da planilha é obrigatório!" ### "Atenção"
		lRet	:=	.F.
	Case Empty(DtoS(dDtIni))
		MsgAlert(STR0072, STR0043)  // "Data não pode ser vazia." ### "Atenção"
		lRet	:=	.F.
	Case Empty(DtoS(dDtFim))
		MsgAlert(STR0072, STR0043)  // "Data não pode ser vazia." ### "Atenção"
		lRet	:=	.F.
	Case dDtIni > dDtFim
		MsgAlert(STR0130, STR0043)  // "Data inicial deve ser anterior à data final." ### "Atenção"
		lRet	:=	.F.
	Case cCbxStCtr == STR0108 .and. Empty(dDtAss)	// "Vigente" 
		MsgAlert(STR0131, STR0043)  // "É obrigatório informar a data da assinatura do contrato para que seja possível torná-lo vigente." ### "Atenção"
		lRet	:=	.F.
	Case !lTecA870	.AND. !VldNrCont(cNrCont)
		lRet	:= .F.
End Case
// valida se a o tipo de planilha ou contrato estão exigindo cronograma financeiro
If lRet
    DbSelectArea("CNL")
    CNL->(DbSetOrder(1)) // CNL_FILIAL + CNL_CODIGO
    CNL->( DbSeek( xFilial("CNL")+cTpPl ) )
 
    DbSelectArea("CN1")
    CN1->( DbSetOrder(1) ) // CN1_FILIAL + CN1_CODIGO
    CN1->( DbSeek( xFilial("CN1")+cTpCont ) )
    
    // Avalia pelos tipos de planilha/contrato se deve gerar cronograma financeiro
    lGeraCronFin := ( ( CNL->CNL_MEDEVE $ "2/3" ) .Or. ;  // tipo de planilha define | 2-Tem Cronog (não há medição eventual)/3-Recorrente
                    ( CNL->CNL_MEDEVE $ " /0" .And. CN1->CN1_MEDEVE == "2" ) )  // tipo de planilha respeita tipo de contrato | 2-Tem cronog (não há medição eventual)
    // define se a planilha é recorrente
    lPlanRecorrente := ( CNL->CNL_MEDEVE == "3" )
 
    If lIsRecorrente .And. !lPlanRecorrente
        lRet := .F.
        MsgAlert(STR0161, STR0043)  // "É obrigatório utilizar um tipo de planilha com medição eventual igual a 3-Recorrente." ### "Atenção"        
	Elseif lIsRecorrente .And. nQtdRec <= 0
        lRet := .F.
        MsgAlert(STR0165, STR0043)  // "É obrigatório que a quantidade de recorrência seja maior que zero" ### "Atenção"	
    EndIf

	If lRet .And. lIsFatAntecip .And. !lGeraCronFin
		lRet := .F.
		MsgAlert(STR0162, STR0043)  // "É obrigatório o uso de cronograma financeiro para o processo de faturamento antecipado." ### "Atenção"
	EndIf
EndIf

If lRet
	If	lTecA870
		lRet := MsgYesNo(STR0132)	//"Ao finalizar o assistente de manutenção do contrato, será iníciado o processo de alteração do contrato no módulo Gestão de Contrato. Tem certeza que deseja dar inicío à manutenção do contrato?"
	Else
		lRet := MsgYesNo(STR0066)	//"Ao finalizar o assistente de geração do contrato, será iníciado o processo de geração do contrato no módulo Gestão de Contrato. Tem certeza que deseja dar inicío a geração do contrato?"
	EndIf
EndIf
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850ExcAt
Cria estrutura do Contrato com status "Em Elaboração"
@param	cTpCont:		Tipo do contrato
@param	cCnPag:		Condição de Pagamento
@param	cCbxReajCt:	Determina se o contrato tem reajuste.
@param	cIndice:		Indice do reajuste do contrato
@param	aDatas:		Datas, com destaque para data de vigência
@param	cTpPl:			Tipo da planilha
@param	cCbxReajPl:	Determina se planilha tem reajuste.
@param	cProposta:		Proposta Comercial
@param	cRevisao:		Revisão da proposta
@param	dDtIni:		Data Inicial do Contrato
@param	dDtFim:		Data Final do Contrato
@param	cCbxFgCau:		Determina se caução tem reajuste.
@param	aBaseAt:		Bases de atendimento
@param	nPerCau:		Percentual de caução
@param	cCbxStCtr:		Situação do contrato
@param	cNrCont:		Número do contrato
@param	dDtAss:		Data da assinatura do Contrato
@param	oModel:		Modelo de dados do contrato (TECA301)
@return				.T.
@author				Serviços
@since					31/10/2013
@version				P11 R9
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At850ExcAt(cTpCont,    cCnPag,    cCbxReajCt, cIndice, aDatas, cTpPl    ,;
                           cCbxReajPl, cProposta, cRevisao,   dDtIni,  dDtFim, cCbxFgCau,;
                           aBaseAt,    nPerCau,   cCbxStCtr,  cNrCont, dDtAss, oModel   ,; 
                           nQtdRec,    lMsmCrF   ,lMsmCrC,    cOporProp )                                        

Local aArea			:= GetArea()
Local aLinha			:= {}
Local aLocais			:= {}
Local cAliasCNA		:= "CNA"
Local cRev1			:= ""
Local cMsgErr 		:= ""
Local nCont			:= 0
Local lCronog			:= .T.
Local lOKFin	 		:= .T.
Local lOkCont 		:= .T.
Local lPlnCrn			:= .F.
Local lVigente 			:= (cCbxStCtr == STR0108 ) 	//"Vigente"
Local lRet				:= .T.

Private cCadastro		:= OemToAnsi(STR0082)										//"Manutenção de Cronograma"
Private aRotina		:= {{ OemToAnsi(STR0002), "AxPesqui",   0, 1, 0, .F.},;	//"Pesquisar"
						    { OemToAnsi(STR0003), "CN110Manut", 0, 2, 0, nil},;	//"Visualizar"
						    { OemToAnsi(STR0004), "CN110Manut", 0, 3, 0, nil},;	//"Incluir"
						    { OemToAnsi(STR0005), "CN110Manut", 0, 4, 0, nil},;	//"Alterar"
						    { OemToAnsi(STR0006), "CN110Manut", 0, 5, 0, nil}}	//"Excluir"

If	lTecA870
	INCLUI 	:= .F.
	ALTERA 	:= .T.
Else
	INCLUI 	:= .T.
	ALTERA 	:= .F.
EndIf
Private VISUAL	:= .T.

Default nQtdRec := 0


BEGIN TRANSACTION 

aAdd(aLinha, {"CN9_TPCTO",  cTpCont,   NIL})
aAdd(aLinha, {"CN9_DTINIC", dDtIni,    NIL})
aAdd(aLinha, {"CN9_UNVIGE", "1",       NIL})
aAdd(aLinha, {"CN9_VIGE",   aDatas[1], NIL})
aAdd(aLinha, {"CN9_CONDPG", cCnPag,    NIL})
If cCbxReajCt == STR0005	// "Sim"
	aAdd(aLinha, {"CN9_FLGREJ", "1", NIL})
Else
	aAdd(aLinha, {"CN9_FLGREJ", "2", NIL})
EndIf

If !Empty(cIndice)
	aAdd(aLinha, {"CN9_INDICE", cIndice, NIL})
EndIf

aAdd(aLinha, {"CN9_DTFIM",  dDtFim,  NIL})
aAdd(aLinha, {"CN9_MOEDA",  1,       NIL})
If	! lTecA870
	aAdd(aLinha, {"CN9_NUMERO", cNrCont, NIL})
EndIf
aAdd(aLinha, {"CN9_SITUAC", "02",    NIL})
aAdd(aLinha, {"CN9_REVISA", " ",     NIL})
aAdd(aLinha, {"CN9_ESPCTR", "2",     NIL})
If cCbxFgCau == STR0005	// "Sim"
	aAdd(aLinha,{"CN9_FLGCAU", "1",     NIL})
	aAdd(aLinha,{"CN9_TPCAUC", "1",     NIL})
	aAdd(aLinha,{"CN9_MINCAU", nPerCau, NIL})
Else
	aAdd(aLinha,{"CN9_FLGCAU", "2",     NIL})
EndIf
aAdd(aLinha,{"CN9_DTASSI", dDtAss,               NIL})
aAdd(aLinha,{"CN9_DTPROP", GetDtProp(cProposta), NIL})
//adiconado para prever se o usuario pode selecionar mesma competência nas medições de contratos de serviços
aAdd(aLinha,{"CN9_UTMSCF", IIf(lMsmCrF,"1","2"), NIL})

If ExistBlock("AT850FCtr")
	lRet := ExecBlock("AT850FCtr",.F.,.F.,{aLinha})
EndIf

If lRet
	MsgRun ( STR0067, STR0068, {|| lRet	:=	At850CrPlan(aLinha, cTpPl, cCbxReajPl, cProposta, cRevisao, oModel, , nQtdRec, lMsmCrF, lMsmCrC, cOporProp)} )//"Criando planilhas do Contrato", "Aguarde"
EndIf

If lRet
	If	lTecA870
		MsgInfo(STR0129, "")	//"Contrato alterado no módulo da Gestão de Contratos"
	Else
		MsgInfo(STR0080 + cNrCont + STR0081, "")	//"Foi gerado o Contrato "#" no Modulo Gestão de Contratos"
	EndIf

	For nCont := 1 to Len(aBaseAt)
		DbSelectArea("AA3")
		DbSetOrder(6)
		If AA3->(DbSeek(xFilial("AA3")+aBaseAt[nCont]))
			AA3->(RecLock("AA3"))
			AA3->AA3_CONTRT := cNrCont
			AA3->AA3_ORIGEM := "CN9"
			AA3->(MsUnlock())
		EndIf
	Next nCont

	Pergunte("CNT100",.F.)
	If lVigente	//"Vigente?"
		//tornar contrato vigente 
		MsgRun ( STR0070, STR0068, {|| lRet := CN100SitCh(cNrCont, cRev1, "05")} )  //"Tornando o contrato Vigente"###"Aguarde"
	EndIf
	
	If lRet
		aLocais	:=	At850PropLoc(xFilial("CN9"), cProposta, cRevisao, .F. /*lFilLocZero*/) //recebe locais de atendimento.
		At850AtvLocAtnd(cNrCont, cRev1, aLocais, cProposta, cRevisao)//Ativa locais de atendimento
		//----------------------------------------------------------------
		//  Verifica se há e atualiza as reservas de equipamentos
		// para o status de efetivadas
		DbSelectArea('ADY')
		ADY->( DbSetOrder( 1 ) ) // ADY_FILIAL+ADY_PROPOS+ADY_PREVIS
		If ADY->( DbSeek( xFilial('ADY')+cProposta+cRevisao ) )
			At825Ctr()
		EndIf

		//----------------------------------------------------------------
		//  Gera o movimento inicial dos equipamentos para locação
		DbSelectArea('TFJ')
		TFJ->( DbSetOrder( 2 ) ) //TFJ_FILIAL+TFJ_PROPOS+TFJ_PREVIS
		If TFJ->( DbSeek( xFilial('TFJ')+cProposta+cRevisao ) )
			If TFJ->TFJ_ITEMLE != Space(TamSx3("TFJ_ITEMLE")[1]) .Or. TFJ->TFJ_DSGCN == "1"
				MsgRun ( STR0072, STR0068, {|| lRet := At800Start( @cMsgErr, TFJ->TFJ_CODIGO ) } ) // 'Gerando movimentos para locação de equipamentos' ### "Aguarde..."
				If !lRet
					Help(,,'AT850ERRO01',, cMsgErr,1,0)
				EndIf
			Else
				lRet := .T.
			EndIf	
		EndIf
	EndIf
EndIf

If	lRet .AND. lSigaMdtGS
	MsgRun ( STR0173 , STR0068 , {|| At850CrTar(cNrCont,cRev1) } )  //"Analisando/Criando tarefas de funcionários"###"Aguarde"
Endif
If lRet
	ConfirmSX8()
Else
	DisarmTransaction()
	RollBackSXE()
EndIf

END TRANSACTION

RestArea(aArea)
Return	lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850CrPlan

Cria planilha para o contrato.
@param		aInfo:			Informações do contrato
@param		cTpPl:			Tipo da planilha
@param		cCbxReajPl:	Determina se planilha tem Reajuste.
@param		cProposta:		Proposta Comercial
@param		cRevisao:		Revisão da proposta
@param		oModel:		Modelo de dados do contrato (TECA301)
@return	.T. 
@author	Serviços
@since		31/10/13
@version	P11 R9
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At850CrPlan(aInfo, cTpPl, cCbxReajPl, cProposta, ;
							cRevisao, oModel, lVigente, nQuantRec, ;
							lMsmCrF, lMsmCrC, cOporProp)

Local aArea			:= GetArea()
Local aHeader			:= {}
Local aItemPl			:= {}
Local aItensPl		:= {}
Local aClien			:= {}
Local aLocal			:= {}
Local aItemRH			:= {}
Local aItRhPl			:= {} //itens do RH e seus respectivos na planilha.
Local aItLcPl			:= {} //itens de Locação de equipamento e seus respectivos na planilha.
Local aItMtImp		:= {} //itens material de implantação e seus respectivos na planilha.
Local aItMtCns		:= {} //itens material de consumo e seus respectivos na planilha.
Local aItLocal		:= {} //local de atendimento e sua respectiva planilha [1]-Local [2]-Array ref. itens (TFF, TFG, TFH, TFI)
Local aTdClient 		:= {}
Local aTdHeader 		:= {}
Local aTdItem			:= {}
Local aTdVend			:= {}
Local aVend			:= {}
Local lParamImp 		:= SuperGetMv("MV_ATOPIMP",,.T.)
Local lOrcPrc 		:= SuperGetMv("MV_ORCPRC",,.F.)
Local lSeqTrn 		:= (TFF->(FieldPos("TFF_SEQTRN")) > 0)
Local lSomaImp 		:= .F.
Local l850GRVPL		:= .F.
Local lRetorno		:= .T.
Local nCont			:= 0
Local nX				:= 0
Local nItSoma 		:= 0
Local nLinAItensPl	:= 0
Local nItSomar 		:= 0
Local cAliasTFF		:= "TFF"
Local cAliasTFG		:= "TFG"
Local cAliasTFH		:= "TFH"
Local cItem			:= "000"
Local cPedTit 		:= "1"
Local cNumero			:= ""
Local cCodLocal		:= ""
Local cCodCli			:= ""
Local cLjCli			:= ""
Local cItemTFI		:= NIL
Local cItemTFF		:= NIL
Local cItemTFG		:= NIL
Local cItemTFH		:= NIL
Local lComisPorTime 	:= SuperGetMv("MV_ATTPCOM",,"1")=="2"
Local aPrdsLE			:= {}
Local aPrdsMC			:= {}
Local aPrdsMI			:= {}
Local aPrdsRH			:= {}
Local nPrd				:= 1
Local lDsgCN 			:=	.F.
Local cABSCusto 		:= ""
Local lInsereCC 		:= .F.
Local cCodTFJ 		:= ""
Local aAreaTFL0 		:= {}
Local aAreaTFF0 		:= {}
Local cFilTFL 			:= xFilial("TFL")
Local cFilTFF 			:= xFilial("TFF")
Local cFilTFG 			:= xFilial("TFG")
Local cFilTFH 			:= xFilial("TFH")
Local cFilTFI 			:= xFilial("TFI")
Local nPosNumero 		:= aScan( aInfo, {|x| x[1] == "CN9_NUMERO" } )
Local nPosRevisao 		:= aScan( aInfo, {|x| x[1] == "CN9_REVISA" } )
Local lIsGsMt			:= .F.
Local lGsMtMi			:= .F.
Local lGsMtMc			:= .F.
//Tratamento do grupo de Faturamento
Local lGrpFat		 	:= SuperGetMv("MV_GSGRFAT",,"2")=="1"
Local cChaveQbr			:= ""
Local lGrpFatOrc		:= .F. //Tratamento do legado
Local aItTWW			:= {} //itens do RH e seus respectivos na planilha.
Local aItLocAux			:= {}
Local bValid 			:= {||  .T. }
Local cB1_CODISS		:= "" //Codigo do Serviço
Local cFilSB1			:= xFilial("SB1")
Local aAreaSB1			:= {}

Private lMsErroAuto	:= .F.

Default nQuantRec 	:= 0


cNumero	:= "000001"

aLocal		:= At850PropLoc(xFilial("TFJ"), cProposta, cRevisao, .T./*lFilLocZero*/) //Recebe os locais de atendimento que existem no orçamento.


SB1->(DbSetOrder(1)) //B1_FILIAL + B1_COD

If lGrpFat

	lRetorno:= At850GrvFat(cOporProp, cProposta, cRevisao)

EndIf

If lRetorno
	If ExistBlock("AT850GRVPL")
		l850GRVPL := ExecBlock("AT850GRVPL",.F.,.F.,{cCbxReajPl, cProposta, cRevisao, cCodCli, cLjCli, aLocal, aInfo, cTpPl})
	Else
		DbSelectArea("TFJ")
		DbSetOrder(2) // TFJ_FILIAL+ TFJ_PROPOS + TFJ_PREVIS
		If TFJ->( DbSeek(xFilial("TFJ") + cProposta + cRevisao) )
			cCodTFJ := TFJ->TFJ_CODIGO
			lDsgCN := TFJ->TFJ_DSGCN == '1' 			
			lIsGsMt := TFJ->TFJ_ISGSMT == '1'
			lGrpFatOrc	:= TFJ->TFJ_GRPFAT == '1'
			If lIsGsMt
				lGsMtMi	:= TFJ->TFJ_GSMTMI $ '2|3'
				lGsMtMc	:= TFJ->TFJ_GSMTMC $ '2|3'
			Endif
			If	! lTecA870
				lSomaImp := lParamImp .And. !Empty( TFJ->TFJ_TABXML )
	
				// adiciona todos os clientes possíveis como opções dentro da CNC
				// Cliente da Proposta Comercial
				If TFJ->TFJ_ENTIDA == "1"
					If aScan(aTdClient, {|x| x[4][2]==TFJ->TFJ_CODENT .AND. x[5][2]==TFJ->TFJ_LOJA}) == 0 //Adiciona cliente somente se não existir no aTdClient
						Aadd(aClien,{"CNC_FILIAL", xFilial("CNC"), NIL})
						Aadd(aClien,{"CNC_NUMERO", aInfo[nPosNumero][2],   NIL})
						Aadd(aClien,{"CNC_REVISA", aInfo[nPosRevisao][2],   NIL})
						Aadd(aClien,{"CNC_CLIENT", TFJ->TFJ_CODENT,NIL})
						Aadd(aClien,{"CNC_LOJACL", TFJ->TFJ_LOJA,  NIL})
						Aadd(aTdClient, aClone(aClien))
						aSize( aClien, 0 )
					EndIf
				EndIf
				// Clientes Principais do Local de Atendimento
				// Clientes de Faturamento do Local de Atendimento
				For nCont := 1 To Len(aLocal) 
					// Posiciona na ABS - Local de Atendimento
					ABS->( DbGoTo( aLocal[nCont][4] ) )
					
					// Clientes Principais do Local de Atendimento
					If !Empty( ABS->ABS_CODIGO ) .And. !Empty( ABS->ABS_LOJA )
						If aScan(aTdClient, {|x| x[4][2]==ABS->ABS_CODIGO .AND. x[5][2]==ABS->ABS_LOJA}) == 0 //Adiciona cliente somente se não existir no aTdClient
							Aadd(aClien,{"CNC_FILIAL", xFilial("CNC"), NIL})
							Aadd(aClien,{"CNC_NUMERO", aInfo[nPosNumero][2],   NIL})
							Aadd(aClien,{"CNC_REVISA", aInfo[nPosRevisao][2],   NIL})
							Aadd(aClien,{"CNC_CLIENT", ABS->ABS_CODIGO,NIL})
							Aadd(aClien,{"CNC_LOJACL", ABS->ABS_LOJA,  NIL})
							Aadd(aTdClient, aClone(aClien))
							aSize( aClien, 0 )
						EndIf
					EndIf
	
					// Clientes de Faturamento do Local de Atendimento
					If !Empty( ABS->ABS_CLIFAT ) .And. !Empty( ABS->ABS_LJFAT )
						If aScan(aTdClient, {|x| x[4][2]==ABS->ABS_CLIFAT .AND. x[5][2]==ABS->ABS_LJFAT}) == 0 //Adiciona cliente somente se não existir no aTdClient
							Aadd(aClien,{"CNC_FILIAL", xFilial("CNC"), NIL})
							Aadd(aClien,{"CNC_NUMERO", aInfo[nPosNumero][2],   NIL})
							Aadd(aClien,{"CNC_REVISA", aInfo[nPosRevisao][2],   NIL})
							Aadd(aClien,{"CNC_CLIENT", ABS->ABS_CLIFAT,NIL})
							Aadd(aClien,{"CNC_LOJACL", ABS->ABS_LJFAT,  NIL})
							Aadd(aTdClient, aClone(aClien))
							aSize( aClien, 0 )
						EndIf
					EndIf
				Next nCont 
	
				//Para criação das planilhas de acordo com a quantidade de locais de atendimento.
				For nCont := 1 To Len(aLocal)
					aHeader	:=	{}
					aItemPl	:=	{}
					aClien		:=	{}
					aItensPl	:=	{}
					cCodLocal	:= aLocal[nCont][1]
					cItem		:= "000"
					cItemTFI 	:= ""
					cItemTFF 	:= ""
					cItemTFG 	:= ""
					cItemTFH 	:= ""
					cABSCusto  	:= aLocal[nCont][3]
					lInsereCC 	:= !Empty(cABSCusto)
					
					// busca os dados de código e loja do cliente conforme a definição no orçamento de serviços
					If !lGrpFatOrc
						At850GetCli( @cCodCli, @cLjCli, aLocal[nCont][2], TFJ->TFJ_AGRUP ) 
		
						//Informação para criação da planilha.
						Aadd(aHeader,{"CNA_FILIAL", xFilial("CNA"), NIL})
						Aadd(aHeader,{"CNA_NUMERO", cNumero,        NIL})
						Aadd(aHeader,{"CNA_TIPPLA", cTpPl,          NIL})
						Aadd(aHeader,{"CNA_CLIENT", cCodCli, NIL})
						Aadd(aHeader,{"CNA_LOJACL", cLjCli,  NIL})
						Aadd(aHeader,{"CNA_DTINI",  aLocal[nCont][5],    NIL})
						Aadd(aHeader,{"CNA_DTFIM",  aLocal[nCont][6],    NIL})
						If nQuantRec > 0
							Aadd(aHeader,{"CNA_RPGANT",	"1" 		,	NIL})
							Aadd(aHeader,{"CNA_PERIOD",	"3"			,	NIL})								
							Aadd(aHeader,{"CNA_PERREC",	1			,	NIL})
							Aadd(aHeader,{"CNA_QTDREC", nQuantRec ,  NIL})
						Endif				
						Aadd(aTdHeader,aHeader)
					EndIf
	
					DbSelectArea("TFL")
					TFL-> ( DbSetOrder(1) )	//TFL_FILIAL+TFL_CODIGO
					If TFL->( DbSeek(xFilial("TFL")+cCodLocal) )
						cPedTit := If( TFL->TFL_PEDTIT == "2", "2", "1" )
						If TFL->TFL_TOTRH > 0
							If lGrpFatOrc
								cChaveQbr	:= At930GFIT(TFL->TFL_LOCAL, TFL->TFL_CODPAI, "RH", @cCodCli, @cLjCli)
								//Informação para criação da planilha.
								Aadd(aHeader,{"CNA_FILIAL", xFilial("CNA"), NIL})
								Aadd(aHeader,{"CNA_NUMERO", cNumero,        NIL})
								Aadd(aHeader,{"CNA_TIPPLA", cTpPl,          NIL})
								Aadd(aHeader,{"CNA_CLIENT", cCodCli, NIL})
								Aadd(aHeader,{"CNA_LOJACL", cLjCli,  NIL})
								Aadd(aHeader,{"CNA_DTINI",  aLocal[nCont][5],    NIL})
								Aadd(aHeader,{"CNA_DTFIM",  aLocal[nCont][6],    NIL})
								If nQuantRec > 0
									Aadd(aHeader,{"CNA_RPGANT",	"1" 		,	NIL})
									Aadd(aHeader,{"CNA_PERIOD",	"3"			,	NIL})								
									Aadd(aHeader,{"CNA_PERREC",	1			,	NIL})
									Aadd(aHeader,{"CNA_QTDREC", nQuantRec ,  NIL})
								Endif				
								Aadd(aTdHeader,aHeader)
								aHeader	:=	{}	
							
							EndIf
							If !lDsgCN
								aItemPl	:= {}
								cItem		:= SOMA1(cItem)
								Aadd(aItemPl,{"CNB_FILIAL", xFilial("CNB"),  NIL})
								Aadd(aItemPl,{"CNB_NUMERO", cNumero,         NIL})
								Aadd(aItemPl,{"CNB_ITEM",   cItem,           NIL})
								Aadd(aItemPl,{"CNB_PRODUT", TFJ->TFJ_GRPRH, NIL})
								Aadd(aItemPl,{"CNB_QUANT",  1,              NIL})
								Aadd(aItemPl,{"CNB_VLUNIT", TFL->TFL_TOTRH, NIL})
								Aadd(aItemPl,{"CNB_TS",     TFJ->TFJ_TES,    NIL})
								Aadd(aItemPl,{"CNB_PEDTIT", cPedTit,         NIL})
								If lInsereCC
									Aadd(aItemPl,{"CNB_CC", cABSCusto,      NIL})
								EndIf
								
								If lPedIss .AND. SB1->(DbSeek(cFilSB1 + TFJ->TFJ_GRPRH))
									Aadd(aItemPl,{"CNB_IDPED", SB1->B1_CODISS,      NIL})
								EndIf
								
								Aadd(aItensPl, aItemPl)
								cItemTFF	:= cItem
							Else
								aPrdsRH := GetPrdCTR(aLocal[nCont,1],aLocal[nCont,2	], "RH", lGsMtMi, lGsMtMc)
	
								For nPrd := 1 To Len(aPrdsRH)
									If aPrdsRH[nPrd,3] > 0 .and. aPrdsRH[nPrd,6] == "1"
										aItemPl	:=	{}
										cItem		:=	SOMA1(cItem)
										Aadd(aItemPl,{"CNB_FILIAL", xFilial("CNB"), NIL})
										Aadd(aItemPl,{"CNB_NUMERO", cNumero,        NIL})
										Aadd(aItemPl,{"CNB_ITEM",   cItem,          NIL})
										Aadd(aItemPl,{"CNB_PRODUT", aPrdsRH[nPrd,1], NIL})
										Aadd(aItemPl,{"CNB_QUANT",  aPrdsRH[nPrd,2],NIL})
										Aadd(aItemPl,{"CNB_VLUNIT", aPrdsRH[nPrd,3], NIL})
										Aadd(aItemPl,{"CNB_TS",     aPrdsRH[nPrd,5],   NIL})
										Aadd(aItemPl,{"CNB_PEDTIT", cPedTit,        NIL})
										Aadd(aItemPl,{"CNB_PRODSV", aPrdsRH[nPrd,7],      NIL})
										If lInsereCC
											Aadd(aItemPl,{"CNB_CC", cABSCusto,      NIL})
										EndIf
										
										If lPedIss .AND. SB1->(DbSeek(cFilSB1 + aPrdsRH[nPrd,1]))
											Aadd(aItemPl,{"CNB_IDPED", SB1->B1_CODISS,      NIL})
										EndIf
										Aadd(aItensPl, aItemPl)
	
										If aPrdsRH[nPrd,6] == "1" //Quando for Recursos Humanos.
											A850AtItCNB('TFF',aPrdsRH[nPrd,4],'TFF_ITCNB',cItem) //Item da CNB
										Endif
	
										cItemTFF	:= cItem																
									EndIf
								Next nPrd
							EndIf	//!lDsgCN	
							If lGrpFatOrc
								Aadd(aTdItem,aItensPl)
								aItensPl	:=	{}	
								Aadd(aItTWW,{cCodLocal+"RH", cNumero, cItemTFF})
							EndIf			
						EndIf //TFL->TFL_TOTRH > 0													
						If TFL->TFL_TOTMI > 0
						
							If lGrpFatOrc
								cChaveQbr	:= At930GFIT(TFL->TFL_LOCAL, TFL->TFL_CODPAI, "MI", @cCodCli, @cLjCli)
								cNumero	:= SOMA1(cNumero)
								cItem	:= "000"
								//Informação para criação da planilha.
								Aadd(aHeader,{"CNA_FILIAL", xFilial("CNA"), NIL})
								Aadd(aHeader,{"CNA_NUMERO", cNumero,        NIL})
								Aadd(aHeader,{"CNA_TIPPLA", cTpPl,          NIL})
								Aadd(aHeader,{"CNA_CLIENT", cCodCli, NIL})
								Aadd(aHeader,{"CNA_LOJACL", cLjCli,  NIL})
								Aadd(aHeader,{"CNA_DTINI",  aLocal[nCont][5],    NIL})
								Aadd(aHeader,{"CNA_DTFIM",  aLocal[nCont][6],    NIL})
								If nQuantRec > 0
									Aadd(aHeader,{"CNA_RPGANT",	"1" 		,	NIL})
									Aadd(aHeader,{"CNA_PERIOD",	"3"			,	NIL})								
									Aadd(aHeader,{"CNA_PERREC",	1			,	NIL})
									Aadd(aHeader,{"CNA_QTDREC", nQuantRec ,  NIL})
								Endif				
								Aadd(aTdHeader,aHeader)
								aHeader	:=	{}
							EndIf
							// verifica se é o mesmo produto, quando não for irá adicionar nova linha
							If ( nItSomar := aScan( aItensPl, {|x| x[4][2]==TFJ->TFJ_GRPMI } ) ) > 0
								aItensPl[nItSomar][6][2] += TFL->TFL_TOTMI
							Else
								If !lDsgCN
									aItemPl	:=	{}
									cItem		:=	SOMA1(cItem)
									Aadd(aItemPl,{"CNB_FILIAL", xFilial("CNB"),  NIL})
									Aadd(aItemPl,{"CNB_NUMERO", cNumero,         NIL})
									Aadd(aItemPl,{"CNB_ITEM",   cItem,           NIL})
									Aadd(aItemPl,{"CNB_PRODUT", TFJ->TFJ_GRPMI, NIL})
									Aadd(aItemPl,{"CNB_QUANT",  1,              NIL})
									Aadd(aItemPl,{"CNB_VLUNIT", TFL->TFL_TOTMI, NIL})
									Aadd(aItemPl,{"CNB_TS",     TFJ->TFJ_TESMI,  NIL})
									Aadd(aItemPl,{"CNB_PEDTIT", cPedTit,         NIL})
									If lInsereCC
										Aadd(aItemPl,{"CNB_CC", cABSCusto,      NIL})
									EndIf
									Aadd(aItensPl, aItemPl)
								Else
									If !lGsMtMi
										aPrdsMI := GetPrdCTR(aLocal[nCont,1],aLocal[nCont,2	], "MI")
										bValid := {|| .T.}
									Else
										aPrdsMI := GetPrdCTR(aLocal[nCont,1],aLocal[nCont,2	], "RH", lGsMtMi, lGsMtMc)
										bValid := {|| aPrdsMI[nPrd,6] == "2"}
									EndIf
									For nPrd := 1 To Len(aPrdsMI)
										If aPrdsMI[nPrd,3] > 0 .and. Eval(bValid)
											aItemPl	:=	{}
											cItem		:=	SOMA1(cItem)
											Aadd(aItemPl,{"CNB_FILIAL", xFilial("CNB"), NIL})
											Aadd(aItemPl,{"CNB_NUMERO", cNumero,        NIL})
											Aadd(aItemPl,{"CNB_ITEM",   cItem,          NIL})
											Aadd(aItemPl,{"CNB_PRODUT", aPrdsMI[nPrd,1], NIL})
											Aadd(aItemPl,{"CNB_QUANT",  aPrdsMI[nPrd,2],NIL})
											Aadd(aItemPl,{"CNB_VLUNIT", aPrdsMI[nPrd,3], NIL})
											Aadd(aItemPl,{"CNB_TS",     aPrdsMI[nPrd,5], NIL})
											Aadd(aItemPl,{"CNB_PEDTIT", cPedTit,        NIL})
											Aadd(aItemPl,{"CNB_PRODSV", aPrdsMI[nPrd,7], NIL})
											If lInsereCC
												Aadd(aItemPl,{"CNB_CC", cABSCusto,      NIL})
											EndIf
											If lPedIss .AND. SB1->(DbSeek(cFilSB1 + aPrdsMI[nPrd,7]))
												Aadd(aItemPl,{"CNB_IDPED", SB1->B1_CODISS,      NIL})
											EndIf
											
											If !lGsMtMi
												A850AtItCNB('TFG',aPrdsMI[nPrd,4],'TFG_ITCNB',cItem)
											Else
												A850AtItCNB('TFF',aPrdsMI[nPrd,4],'TFF_ITICNB',cItem) //Item da CNB para Material de Implantação por valor
											EndIf
											Aadd(aItensPl, aItemPl)
										EndIf
									Next nI
								EndIf //!lDsgCN
								If lGrpFatOrc
									Aadd(aTdItem,aItensPl)
									aItensPl	:=	{}	
									Aadd(aItTWW,{cCodLocal+"MI", cNumero, cItem})
								EndIf
							EndIf // ( nItSomar := aScan( aItensPl, {|x| x[4][2]==TFJ->TFJ_GRPMI } ) ) > 0
							cItemTFG	:= cItem
							// caso não tenha valor mas o produto referência para o conceito de produto seja o mesmo usa o item para vincular
							// e permitir adicionar os itens posteriormente
						ElseIf ( nItSomar := aScan( aItensPl, {|x| x[4][2]==TFJ->TFJ_GRPMI } ) ) > 0
							cItemTFG	:= aItensPl[nItSomar][3][2]
						EndIf //TFL->TFL_TOTMI > 0
						If TFL->TFL_TOTMC > 0
							If lGrpFatOrc
								cChaveQbr	:= At930GFIT(TFL->TFL_LOCAL, TFL->TFL_CODPAI, "MC", @cCodCli, @cLjCli)
								cNumero	:= SOMA1(cNumero)
								cItem	:= "000"
								//Informação para criação da planilha.
								Aadd(aHeader,{"CNA_FILIAL", xFilial("CNA"), NIL})
								Aadd(aHeader,{"CNA_NUMERO", cNumero,        NIL})
								Aadd(aHeader,{"CNA_TIPPLA", cTpPl,          NIL})
								Aadd(aHeader,{"CNA_CLIENT", cCodCli, NIL})
								Aadd(aHeader,{"CNA_LOJACL", cLjCli,  NIL})
								Aadd(aHeader,{"CNA_DTINI",  aLocal[nCont][5],    NIL})
								Aadd(aHeader,{"CNA_DTFIM",  aLocal[nCont][6],    NIL})
								If nQuantRec > 0
									Aadd(aHeader,{"CNA_RPGANT",	"1" 		,	NIL})
									Aadd(aHeader,{"CNA_PERIOD",	"3"			,	NIL})								
									Aadd(aHeader,{"CNA_PERREC",	1			,	NIL})
									Aadd(aHeader,{"CNA_QTDREC", nQuantRec ,  NIL})
								Endif				
								Aadd(aTdHeader,aHeader)
								aHeader	:=	{}
							EndIf
							// verifica se é o mesmo produto, quando não for irá adicionar nova linha
							If ( nItSomar := aScan( aItensPl, {|x| x[4][2]==TFJ->TFJ_GRPMC } ) ) > 0
								aItensPl[nItSomar][6][2] += TFL->TFL_TOTMC
							Else
								aItemPl	:= {}
								If !lDsgCN
									cItem	:=	SOMA1(cItem)
									Aadd(aItemPl,{"CNB_FILIAL", xFilial("CNB"), NIL})
									Aadd(aItemPl,{"CNB_NUMERO", cNumero,        NIL})
									Aadd(aItemPl,{"CNB_ITEM",   cItem,          NIL})
									Aadd(aItemPl,{"CNB_PRODUT", TFJ->TFJ_GRPMC, NIL})
									Aadd(aItemPl,{"CNB_QUANT",  1,              NIL})
									Aadd(aItemPl,{"CNB_VLUNIT", TFL->TFL_TOTMC, NIL})
									Aadd(aItemPl,{"CNB_TS",     TFJ->TFJ_TESMC, NIL})
									Aadd(aItemPl,{"CNB_PEDTIT", cPedTit,        NIL})
									If lInsereCC
										Aadd(aItemPl,{"CNB_CC", cABSCusto,      NIL})
									EndIf
									Aadd(aItensPl, aItemPl)
								Else
									If !lGsMtMc
										aPrdsMC := GetPrdCTR(aLocal[nCont,1],aLocal[nCont,2	], "MC")
										bValid := {|| .T.}
									Else
										aPrdsMC := GetPrdCTR(aLocal[nCont,1],aLocal[nCont,2	], "RH", lGsMtMi, lGsMtMc)
										bValid := {|| aPrdsMC[nPrd,6] == "3"}
									EndIf
									
									For nPrd := 1 To Len(aPrdsMC)
										If aPrdsMC[nPrd,3] > 0 .AND. Eval(bValid)
											cItem	:=	SOMA1(cItem)
											aItemPl	:=	{}			
											Aadd(aItemPl,{"CNB_FILIAL", xFilial("CNB"), NIL})
											Aadd(aItemPl,{"CNB_NUMERO", cNumero,        NIL})
											Aadd(aItemPl,{"CNB_ITEM",   cItem,          NIL})
											Aadd(aItemPl,{"CNB_PRODUT", aPrdsMC[nPrd,1], NIL})
											Aadd(aItemPl,{"CNB_QUANT",  aPrdsMC[nPrd,2], NIL})
											Aadd(aItemPl,{"CNB_VLUNIT", aPrdsMC[nPrd,3], NIL})
											Aadd(aItemPl,{"CNB_TS",     aPrdsMC[nPrd,5], NIL})
											Aadd(aItemPl,{"CNB_PEDTIT", cPedTit,        NIL})
											Aadd(aItemPl,{"CNB_PRODSV", aPrdsMC[nPrd,7], NIL})
											If lInsereCC
												Aadd(aItemPl,{"CNB_CC", cABSCusto,      NIL})
											EndIf
											If lPedIss .AND. SB1->(DbSeek(cFilSB1 + aPrdsMC[nPrd,7]))
												Aadd(aItemPl,{"CNB_IDPED", SB1->B1_CODISS,      NIL})
											EndIf
											
											If !lGsMtMc
												A850AtItCNB('TFH',aPrdsMC[nPrd,4],'TFH_ITCNB',cItem)
											Else
												A850AtItCNB('TFF',aPrdsMC[nPrd,4],'TFF_ITCCNB',cItem) //Item da CNB para Material de Implantação por valor
											EndIf
											
											Aadd(aItensPl, aItemPl)
										EndIf
									Next nProd
								EndIf
							EndIf
							If lGrpFatOrc
								Aadd(aTdItem,aItensPl)
								aItensPl	:=	{}	
								Aadd(aItTWW,{cCodLocal+"MC", cNumero, cItem})
							EndIf
							cItemTFH	:= cItem
							// caso não tenha valor mas o produto referência para o conceito de produto seja o mesmo usa o item para vincular
							// e permitir adicionar os itens posteriormente
						ElseIf ( nItSomar := aScan( aItensPl, {|x| x[4][2]==TFJ->TFJ_GRPMC } ) ) > 0
							cItemTFH	:= aItensPl[nItSomar][3][2]
						EndIf
						If TFL->TFL_TOTLE > 0
							If lGrpFatOrc
								cChaveQbr	:= At930GFIT(TFL->TFL_LOCAL, TFL->TFL_CODPAI, "LE", @cCodCli, @cLjCli)
								cNumero	:= SOMA1(cNumero)
								//Informação para criação da planilha.
								Aadd(aHeader,{"CNA_FILIAL", xFilial("CNA"), NIL})
								Aadd(aHeader,{"CNA_NUMERO", cNumero,        NIL})
								Aadd(aHeader,{"CNA_TIPPLA", cTpPl,          NIL})
								Aadd(aHeader,{"CNA_CLIENT", cCodCli, NIL})
								Aadd(aHeader,{"CNA_LOJACL", cLjCli,  NIL})
								Aadd(aHeader,{"CNA_DTINI",  aLocal[nCont][5],    NIL})
								Aadd(aHeader,{"CNA_DTFIM",  aLocal[nCont][6],    NIL})
								If nQuantRec > 0
									Aadd(aHeader,{"CNA_RPGANT",	"1" 		,	NIL})
									Aadd(aHeader,{"CNA_PERIOD",	"3"			,	NIL})								
									Aadd(aHeader,{"CNA_PERREC",	1			,	NIL})
									Aadd(aHeader,{"CNA_QTDREC", nQuantRec ,  NIL})
								Endif				
								Aadd(aTdHeader,aHeader)
								aHeader	:=	{}
							EndIf
							// verifica se é o mesmo produto, quando não for irá adicionar nova linha
							If ( nItSomar := aScan( aItensPl, {|x| x[4][2]==TFJ->TFJ_GRPLE } ) ) > 0
								aItensPl[nItSomar][6][2] += TFL->TFL_TOTLE
							Else
								aItemPl	:=	{}
								If !lDsgCN
									cItem		:= SOMA1(cItem)
									Aadd(aItemPl,{"CNB_FILIAL", xFilial("CNB"),  NIL})
									Aadd(aItemPl,{"CNB_NUMERO", cNumero,         NIL})
									Aadd(aItemPl,{"CNB_ITEM",   cItem,           NIL})
									Aadd(aItemPl,{"CNB_PRODUT", TFJ->TFJ_GRPLE, NIL})
									Aadd(aItemPl,{"CNB_QUANT",  1,              NIL})
									Aadd(aItemPl,{"CNB_VLUNIT", TFL->TFL_TOTLE, NIL})
									Aadd(aItemPl,{"CNB_TS",     TFJ->TFJ_TESLE,  NIL})
									Aadd(aItemPl,{"CNB_PEDTIT", cPedTit,         NIL})
									If lInsereCC
										Aadd(aItemPl,{"CNB_CC", cABSCusto,      NIL})
									EndIf
									Aadd(aItensPl, aItemPl)
								Else							
									aPrdsLE := GetPrdCTR(aLocal[nCont,1],aLocal[nCont,2	], "LE")
									For nPrd := 1 To Len(aPrdsLE)
										If aPrdsLE[nPrd,3] > 0
											cItem	:=	SOMA1(cItem)
											aItemPl	:=	{}			
											Aadd(aItemPl,{"CNB_FILIAL", xFilial("CNB"), NIL})
											Aadd(aItemPl,{"CNB_NUMERO", cNumero,        NIL})
											Aadd(aItemPl,{"CNB_ITEM",   cItem,          NIL})
											Aadd(aItemPl,{"CNB_PRODUT", aPrdsLE[nPrd,1], NIL})
											Aadd(aItemPl,{"CNB_QUANT",  aPrdsLE[nPrd,2], NIL})
											Aadd(aItemPl,{"CNB_VLUNIT", aPrdsLE[nPrd,3], NIL})
											Aadd(aItemPl,{"CNB_TS",     aPrdsLE[nPrd,5], NIL})
											Aadd(aItemPl,{"CNB_PEDTIT", cPedTit,        NIL})
											If lInsereCC
												Aadd(aItemPl,{"CNB_CC", cABSCusto,      NIL})
											EndIf
											Aadd(aItensPl, aItemPl)
											A850AtItCNB('TFI',aPrdsLE[nPrd,4],'TFI_ITCNB',cItem)
										EndIF
									Next nProd
									
								EndIf
							EndIf
							If lGrpFatOrc
								Aadd(aTdItem,aItensPl)
								aItensPl	:=	{}	
								Aadd(aItTWW,{cCodLocal+"LE", cNumero, cItem})
							EndIf
							cItemTFI	:= cItem
							// caso não tenha valor mas o produto referência para o conceito de produto seja o mesmo usa o item para vincular
							// e permitir adicionar os itens posteriormente
						ElseIf ( nItSomar := aScan( aItensPl, {|x| x[4][2]==TFJ->TFJ_GRPLE } ) ) > 0
							cItemTFI	:= aItensPl[nItSomar][3][2]
						EndIf
	
						If lSomaImp
							aItensPl[1,6,2] += TFL->TFL_TOTIMP // adiciona o valor ao total unitário do item
						EndIf
						If !lGrpFatOrc
							Aadd(aTdItem,aItensPl)
						EndIf
						// se a geração deve acontecer com os itens agrupados no contrato
						If !lDsgCN .And. ( Empty(cItemTFF) .Or. Empty(cItemTFG) .Or. Empty(cItemTFH) .Or. Empty(cItemTFI) )
							// quando existir algum item não preenchido, verifica se o produto referência no cabeçalho é o mesmo
							// isso é importante pois se o item não estiver preenchido na TFL e o produto for o mesmo
							//  terá problemas na revisão, pois uma linha na CNB deveria ser alterada e não criada
							// RH
							If !Empty(cItemTFF)
								If Empty(cItemTFG) .And. TFJ->TFJ_GRPRH == TFJ->TFJ_GRPMI
									cItemTFG := cItemTFF
								EndIf
								If Empty(cItemTFH) .And. TFJ->TFJ_GRPRH == TFJ->TFJ_GRPMC
									cItemTFH := cItemTFF
								EndIf
								If Empty(cItemTFI) .And. TFJ->TFJ_GRPRH == TFJ->TFJ_GRPLE
									cItemTFI := cItemTFF
								EndIf
							EndIf
							// MC
							If !Empty(cItemTFG)
								If Empty(cItemTFF) .And. TFJ->TFJ_GRPMI == TFJ->TFJ_GRPRH
									cItemTFF := cItemTFG
								EndIf
								If Empty(cItemTFH) .And. TFJ->TFJ_GRPMI == TFJ->TFJ_GRPMC
									cItemTFH := cItemTFG
								EndIf
								If Empty(cItemTFI) .And. TFJ->TFJ_GRPMI == TFJ->TFJ_GRPLE
									cItemTFI := cItemTFG
								EndIf
							EndIf
							// MI
							If !Empty(cItemTFH)
								If Empty(cItemTFF) .And. TFJ->TFJ_GRPMC == TFJ->TFJ_GRPRH
									cItemTFF := cItemTFH
								EndIf
								If Empty(cItemTFG) .And. TFJ->TFJ_GRPMC == TFJ->TFJ_GRPMI
									cItemTFG := cItemTFH
								EndIf
								If Empty(cItemTFI) .And. TFJ->TFJ_GRPMC == TFJ->TFJ_GRPLE
									cItemTFI := cItemTFH
								EndIf
							EndIf
							// LE
							If !Empty(cItemTFI)
								If Empty(cItemTFF) .And. TFJ->TFJ_GRPLE == TFJ->TFJ_GRPRH
									cItemTFF := cItemTFI
								EndIf
								If Empty(cItemTFG) .And. TFJ->TFJ_GRPLE == TFJ->TFJ_GRPMI
									cItemTFG := cItemTFI
							EndIf
								If Empty(cItemTFH) .And. TFJ->TFJ_GRPLE == TFJ->TFJ_GRPMC
									cItemTFH := cItemTFI
								EndIf
							EndIf
	
						EndIf
	
					EndIf
					aAdd(aItLocal, {cCodLocal, cNumero, {cItemTFF, cItemTFG, cItemTFH, cItemTFI} })//inclui referencia para o local
	
					cNumero	:= SOMA1(cNumero)
				Next nCont
	
				//Informa o Vendedor configurado na oportunidade para fins de comissão
				aTdVend := At850Comiss(ADY->ADY_VEND, cCodCli, cLjCli, lComisPorTime)	
	
			EndIf
	
			lRetorno := At850GCTCr(aInfo, aTdClient, aTdHeader, aTdItem, aTdVend, oModel, cTpPl, lVigente, lMsmCrF, lMsmCrC, nQuantRec)
		Else
	
			lRetorno := .F.
	
		EndIf
	EndIf
EndIf

If !lRetorno
	aItLocal := {}
EndIf

DbSelectArea("TFI")
DbSetOrder(3)	//TFI_FILIAL+TFI_CODPAI

DbSelectArea("TFF")
DbSetOrder(3)	//TFF_FILIAL+TFF_CODPAI

DbSelectArea("TFG")
DbSetOrder(3)	//TFG_FILIAL+TFG_CODPAI

DbSelectArea("TFH")
DbSetOrder(3)	//TFH_FILIAL+TFH_CODPAI

For nX := 1 to Len(aItLocal)

	aItemRH	:=	{}

	// Guarda os valores de cada produto e sua relação com a planilha e o item da planilha, que será utilizado para ativação do local de atendimento
	If TFI->(DbSeek(xFilial("TFI") + aItLocal[nX][1]))
		While TFI->(! Eof()) .and. TFI->TFI_FILIAL == cFilTFI .And. TFI->TFI_CODPAI == aItLocal[nX][1]
			Aadd(aItLcPl,{TFI->TFI_COD, aItLocal[nX][2]}) //guarda o valor da planilha e item da planilha referente ao produtorh
			TFI->(DbSkip())
		EndDo
	EndIf

	If TFF->(DbSeek(xFilial("TFF") + aItLocal[nX][1]))
		While TFF->(! Eof()) .And. TFF->TFF_FILIAL == cFilTFF .And. TFF->TFF_CODPAI == aItLocal[nX][1]
			Aadd(aItRhPl,{(cAliasTFF)->TFF_COD, aItLocal[nX][2]}) //guarda o valor da planilha e item da planilha referente ao produtorh
			
			Aadd(aItemRH,{ (cAliasTFF)->TFF_PRODUT	,; //ITEMRH_PRODUT
							(cAliasTFF)->TFF_CARGO	,;	//ITEMRH_CARGO
							(cAliasTFF)->TFF_FUNCAO	,; 	//ITEMRH_FUNCAO
							(cAliasTFF)->TFF_PERINI	,; 	//ITEMRH_PERINI
							(cAliasTFF)->TFF_PERFIM	,;	//ITEMRH_PERFIM
							(cAliasTFF)->TFF_TURNO	,; 	//ITEMRH_TURNO
							(cAliasTFF)->TFF_QTDVEN	,; 	//ITEMRH_QTD
							(cAliasTFF)->TFF_COD,; 		//ITEMRH_CODTFF
							If( lSeqTrn, (cAliasTFF)->TFF_SEQTRN, ""),;//	ITEMRH_SEQTRN
							.T. ,; // ITEMRH_RECLOC
							(cAliasTFF)->TFF_FILIAL	,; 	//ITEMRH_FILTFF
							(cAliasTFF)->TFF_ESCALA	,; 	//ITEMRH_ESCALA
							(cAliasTFF)->TFF_CALEND	}) 	//ITEMRH_CALEND

			If !lOrcPrc
				If TFG->(DbSeek(xFilial("TFG") + (cAliasTFF)->TFF_COD))
					While TFG->(! Eof())  .And. TFG->TFG_FILIAL == cFilTFG .And. TFG->TFG_CODPAI == (cAliasTFF)->TFF_COD
						Aadd(aItMtImp,{(cAliasTFG)->TFG_COD, aItLocal[nX][2]}) //guarda o valor da planilha e item da planilha referente ao produtorh
						TFG->(DbSkip())
					EndDo
				EndIf

				If TFH->(DbSeek(xFilial("TFH") + (cAliasTFF)->TFF_COD))
					While TFH->(! Eof()) .And. TFH->TFH_FILIAL == cFilTFH .And. TFH->TFH_CODPAI == (cAliasTFF)->TFF_COD
						Aadd(aItMtCns,{(cAliasTFH)->TFH_COD, aItLocal[nX][2]}) //guarda o valor da planilha e item da planilha referente ao produtorh
						TFH->(DbSkip())
					EndDo
				EndIf
			EndIf

			TFF->(DbSkip())
		EndDo

		If lOrcPrc
			If TFG->(DbSeek(xFilial("TFG") + aItLocal[nX][1]))
				While TFG->(! Eof())  .And. TFG->TFG_FILIAL == cFilTFG .And. TFG->TFG_CODPAI == aItLocal[nX][1]
					Aadd(aItMtImp,{(cAliasTFG)->TFG_COD, aItLocal[nX][2]}) //guarda o valor da planilha e item da planilha referente ao produtorh
	
					TFG->(DbSkip())
				EndDo
			EndIf

			If TFH->(DbSeek(xFilial("TFH") + aItLocal[nX][1]))
				While TFH->(! Eof()) .And. TFH->TFH_FILIAL == cFilTFH .And. TFH->TFH_CODPAI == aItLocal[nX][1]
					Aadd(aItMtCns,{(cAliasTFH)->TFH_COD, aItLocal[nX][2]}) //guarda o valor da planilha e item da planilha referente ao produtorh
						
					TFH->(DbSkip())
				EndDo
			EndIf
		EndIf

	EndIf

	At850CnfAlc( aInfo[nPosNumero][2], aLocal[nX][2], aItemRH, cCodTFJ )

Next nX

// Verifica se existem locais com valor zero dentro do orçamento para criar a ABQ
aAreaTFL0 := TFL->(GetArea())
aAreaTFF0 := TFF->(GetArea())

TFL->( DbSetOrder( 2 ) ) // TFL_FILIAL + TFL_CODPAI
TFL->( DbSeek( xFilial("TFL") + cCodTFJ ) )

TFF->( DbSetOrder( 3 ) )  // TFF_FILIAL + TFF_CODPAI

TFG->(DbSetOrder(3)) // TFG_FILIAL+TFG_CODPAI

TFH->(DbSetOrder(3)) // TFH_FILIAL+TFH_CODPAI

While !lTeca870 .And. TFL->(!EOF()) .And. TFL->TFL_FILIAL == xFilial("TFL") .And. TFL->TFL_CODPAI == cCodTFJ
	aSize( aItemRH, 0 )
	// avalia se o local não tem valor informado
	If ( TFL->TFL_TOTRH + TFL->TFL_TOTMI + TFL->TFL_TOTMC + TFL->TFL_TOTLE ) == 0	
		// verifica se existe itens de recursos humanos informados
		If TFF->( DbSeek( xFilial("TFF")+TFL->TFL_CODIGO ) )
			While TFF->(!EOF()) .And. TFF->TFF_FILIAL == cFilTFF .And. TFF->TFF_CODPAI == TFL->TFL_CODIGO
				//guarda o valor da planilha e item da planilha referente ao produtorh
				Aadd( aItRhPl,{ TFF->TFF_COD, "" } ) 
			
				Aadd( aItemRH, { TFF->TFF_PRODUT	,; //ITEMRH_PRODUT
								TFF->TFF_CARGO	,;	//ITEMRH_CARGO
								TFF->TFF_FUNCAO	,; 	//ITEMRH_FUNCAO
								TFF->TFF_PERINI	,; 	//ITEMRH_PERINI
								TFF->TFF_PERFIM	,;	//ITEMRH_PERFIM
								TFF->TFF_TURNO	,; 	//ITEMRH_TURNO
								TFF->TFF_QTDVEN	,; 	//ITEMRH_QTD
								TFF->TFF_COD,; 		//ITEMRH_CODTFF
								IIf( lSeqTrn, TFF->TFF_SEQTRN, ""),;//	ITEMRH_SEQTRN
								.T. ,; // ITEMRH_RECLOC
								TFF->TFF_FILIAL	,; 	//ITEMRH_FILTFF
								TFF->TFF_ESCALA	,; 	//ITEMRH_ESCALA
								TFF->TFF_CALEND	}) 	//ITEMRH_CALEND
				
				If !lOrcPrc
					If TFG->(DbSeek(xFilial("TFG") + TFF->TFF_COD))
						While TFG->(! EOF()) .And. TFG->TFG_FILIAL == cFilTFG .And. TFG->TFG_CODPAI == TFF->TFF_COD
							Aadd( aItMtImp, { TFG->TFG_COD, "" } ) //guarda o valor da planilha e item da planilha referente ao produtorh
							TFG->(DbSkip())
						EndDo
					EndIf

					If TFH->(DbSeek(xFilial("TFH") + TFF->TFF_COD))
						While TFH->(! EOF()) .And. TFH->TFH_FILIAL == cFilTFH .And. TFH->TFH_CODPAI == TFF->TFF_COD
							Aadd( aItMtCns, { TFH->TFH_COD, "" } ) //guarda o valor da planilha e item da planilha referente ao produtorh
							TFH->(DbSkip())
						EndDo
					EndIf
				EndIf

				TFF->(DbSkip())
			End
		EndIf
		
		If lOrcPrc
			If TFG->(DbSeek(xFilial("TFG") + TFL->TFL_CODIGO))
				While TFG->(! EOF()) .And. TFG->TFG_FILIAL == cFilTFG .And. TFG->TFG_CODPAI == TFL->TFL_CODIGO
					Aadd( aItMtImp, { TFG->TFG_COD, "" } ) //guarda o valor da planilha e item da planilha referente ao produtorh
					TFG->(DbSkip())
				EndDo
			EndIf

			If TFH->(DbSeek(xFilial("TFH") + TFL->TFL_CODIGO))
				While TFH->(! EOF()) .And. TFH->TFH_FILIAL == cFilTFH .And. TFH->TFH_CODPAI == TFL->TFL_CODIGO
					Aadd( aItMtCns, { TFH->TFH_COD, "" } ) //guarda o valor da planilha e item da planilha referente ao produtorh
					TFH->(DbSkip())
				EndDo
			EndIf
		EndIf
	EndIf

	If !Empty(aItemRH)
		At850CnfAlc( aInfo[nPosNumero][2], TFL->TFL_LOCAL, aItemRH, cCodTFJ )
	EndIf
	TFL->(DbSkip())
End

RestArea(aAreaTFF0)
RestArea(aAreaTFL0)

Aadd(aItXPl,{aItLcPl, aItRhPl, aItMtImp, aItMtCns, aItLocal, aItTWW}) //adicionar informações das planilhas  por local

RestArea(aArea)
Return lRetorno

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850AtDat

Captura os valores das datas
@author Serviços
@since 31/10/13
@version P11 R9
@param cOport:Oportunidade de Venda do Contrato
@param dDtIni:Data Inicial do Contrato
@param dDtFim:Data Final do Contrato
@return  .T. 
/*/
//-------------------------------------------------------------------------------------------------------------------- 
Static Function At850AtDat(cOport, dDtIni, dDtFim)

Local aArea	:= GetArea()
Local aDatas	:= {}
Local dDatVig

dDatVig := (dDtFim - dDtIni+1)
Aadd(aDatas,	dDatVig)

RestArea(aArea)
Return aDatas

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850PropLoc
Verifica quantos Locais de atendimento tem para a proposta comercial, para definir a quantidade de planilhas que devem ser criadas e os valores que deve ter atribuido ao produto na planilha.
@param		cFilProp:Filial da Proposta
@param		cPropCont:Proposta Comercial do Contrato
@param		cRevisao:Revisão da proposta
@return	.T. 
@author	Serviços
@since		31/10/13
@version	P11 R9
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At850PropLoc(cFilProp, cPropCont, cRevisao, lFilLocZero)

Local aArea		:= GetArea()
Local aLocais		:= {}
Local cQuery		:= ""
Local cAliasTFJ	:= GetNextAlias() 

Default lFilLocZero := .T.

cQuery	:= "SELECT TFL_CODIGO, TFL_LOCAL, TFL.TFL_TOTRH, TFL.TFL_TOTMI, TFL.TFL_TOTMC,"
cQuery	+= 		" TFL.TFL_TOTLE, ABS1.ABS_CCUSTO, ABS1.R_E_C_N_O_ ABSRECNO, TFL.TFL_DTINI, TFL.TFL_DTFIM "
cQuery	+= "FROM " + RetSQLName("TFJ") + " TFJ " 
cQuery	+= 	"INNER JOIN " + RetSQLName("TFL") + " TFL ON TFL.TFL_FILIAL = '"+xFilial("TFL")+"' "
cQuery	+=                                          "AND TFL.TFL_CODPAI = TFJ.TFJ_CODIGO "
cQuery	+=                                          "AND TFL.D_E_L_E_T_ = ' ' "
cQuery	+=	"INNER JOIN "+RetSQLName("ABS")+" ABS1 ON ABS_FILIAL = '"+xFilial("ABS")+"' "
cQuery	+=								"AND ABS_LOCAL = TFL_LOCAL "
cQuery	+=								"AND ABS1.D_E_L_E_T_=' ' "
cQuery	+=  "WHERE TFJ.TFJ_FILIAL = '" + cFilProp + "' "
cQuery	+=    "AND TFJ.TFJ_PROPOS = '" + cPropCont + "' "
cQuery	+=    "AND TFJ.TFJ_PREVIS = '" + cRevisao + "' "
cQuery	+=    "AND TFJ.D_E_L_E_T_ = ' ' "
If lFilLocZero
	cQuery	+=  "GROUP BY TFL_CODIGO, TFL_LOCAL, TFL.TFL_TOTRH, TFL.TFL_TOTMI, TFL.TFL_TOTMC, TFL.TFL_TOTLE, ABS1.ABS_CCUSTO, ABS1.R_E_C_N_O_,"
	cQuery	+=  		" TFL.TFL_DTINI, TFL.TFL_DTFIM "
	cQuery	+=  "HAVING ( TFL_TOTRH + TFL_TOTMI + TFL_TOTMC + TFL_TOTLE ) > 0 "
EndIf

cQuery	:= ChangeQuery(cQuery)
DbUseArea(.T., "TOPCONN",TcGenQry(,,cQuery), cAliasTFJ, .T., .T.)

TCSetField(cAliasTFJ,"TFL_DTINI","D")
TCSetField(cAliasTFJ,"TFL_DTFIM","D")

While (cAliasTFJ)->(! Eof())					 
	aAdd( aLocais, { (cAliasTFJ)->TFL_CODIGO, (cAliasTFJ)->TFL_LOCAL, (cAliasTFJ)->ABS_CCUSTO, (cAliasTFJ)->ABSRECNO, (cAliasTFJ)->TFL_DTINI, (cAliasTFJ)->TFL_DTFIM } )	
	(cAliasTFJ)->(DbSkip())	
EndDo
(cAliasTFJ)->(DbCloseArea())

RestArea(aArea)
Return aLocais

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850CnfAlc
Configuração da alocação
@author Serviços
@since 31/10/13
@version P11 R9
@param cContr:Número do Contrato
@param cLocal:Local de Atendimento
@param aItemRH:Itens de recursos humanos, material operacional e material de consumo
@return  .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At850CnfAlc(cContr,cLocal,aItemRH, cOrcSrv,,oDlg,oMeter)

Local lRet			:= .T. 
Local lReturn		:= .T.
Local lRecLock	:= .T.
Local aArea		:= GetArea()
Local aTabPadrao	:= {}
Local aTabCalend	:=	{}
Local aExcePer	:=	{}
Local cAliasABQ	:= "ABQ"
Local cItem		:= "00"
Local cTurno		:= ""
Local cEscala		:= ""
Local cCalend		:= ""
Local nCont		:= 0
Local nX			:= 0 
Local nTotHrsEst	:= 0  									
Local dDataIni	
Local dDataFim
Local lFilTFF		:= FindFunction("ExistFilTFF") .And. ExistFilTFF()
Local lSrvExt       := .F.
Local cChvPesq      := ""
Local lCntRec		:= .F.
Local aTurnosSeq	:= {}
Local nContTurno	:= 0

Default cOrcSrv		:= ""
Default oDlg := nil
Default oMeter := nil

If !Empty(cOrcSrv)
	DbSelectArea("TFJ")
	TFJ->(DbSetOrder(1))
	If TFJ->(DbSeek(xFilial("TFJ")+cOrcSrv))
		If IsInCallStack("TECA744A") .Or. FindFunction("TECA744")
			lSrvExt := TFJ->TFJ_SRVEXT == "1"
EndIf
		lCntRec := TFJ->TFJ_CNTREC == "1"
	Endif
EndIf

DbSelectArea(cAliasABQ)
DbSetOrder(1)

For nCont	:= 1 To Len(aItemRH) 
	
	aTurnosSeq := {}
	
	dDataIni	:= aItemRH[nCont][ITEMRH_PERINI]

	If !lCntRec .And. (YearSum(dDataIni,1) > aItemRH[nCont][ITEMRH_PERFIM])
 		dDataFim	:= aItemRH[nCont][ITEMRH_PERFIM]
	Else
 		dDataFim	:= YearSum(dDataIni,1)
	Endif

 	cTurno		:= aItemRH[nCont][ITEMRH_TURNO]
 	cSeqTrn	    := If(Empty(aItemRH[nCont][ITEMRH_SEQTRN]), "01", aItemRH[nCont][ITEMRH_SEQTRN]) 	
	cEscala		:= aItemRH[nCont][ITEMRH_ESCALA]
	cCalend		:= aItemRH[nCont][ITEMRH_CALEND]
	aTabPadrao	:= {}
	aTabCalend	:= {}
	aExcePer	:= {}
	nTotHrsEst	:= 0
	lRecLock	:= .T.

	If Len(aItemRH[nCont]) >= ITEMRH_RECLOC .And. ValType(aItemRH[nCont,ITEMRH_RECLOC]) == "L"  
		lRecLock := aItemRH[nCont,ITEMRH_RECLOC]
	EndIf	
	
	If lSrvExt
		ABQ->(DbSetOrder(4))//ABQ_FILIAL+ABQ_CODTFJ
		ABQ->(DbSeek(xFilial("ABQ")+cOrcSrv))
		cChvPesq := 'FWxFilial("ABQ")+"'+cOrcSrv+'" == ABQ->(ABQ_FILIAL+ABQ_CODTFJ)'
	Else
		ABQ->(DbSetOrder(1))//ABQ_FILIAL+ABQ_CONTRT+ABQ_ITEM
		ABQ->(DbSeek(xFilial("ABQ")+cContr))
		cChvPesq := 'FWxFilial("ABQ")+"'+cContr+'" == ABQ->(ABQ_FILIAL+ABQ_CONTRT)'
	EndIf
	
	If lRecLock
		While !ABQ->(Eof()) .AND. &(cChvPesq)
			cItem := ABQ->ABQ_ITEM
			ABQ->(DbSkip())
		EndDo
		cItem:=SOMA1(cItem)
	Else 

		While !ABQ->(Eof()) .AND. &(cChvPesq)

			If !lFilTFF
				If ABQ->ABQ_CODTFF == aItemRH[nCont][8]
					Exit
				EndIf
			Else
				If (ABQ->ABQ_CODTFF == aItemRH[nCont][8]) .AND. (ABQ->ABQ_FILTFF == aItemRH[nCont][ITEMRH_FILTFF])
					Exit
				EndIf
			EndIf

			ABQ->(DbSkip())
		EndDo

	EndIf

	If !Empty(cEscala)
		DbSelectArea("TDX")
		TDX->( DbSetOrder(2)) //TDX_FILIAL+TDX_CODTDX+TDX_TURNO
		TDX->( DbSeek(xFilial("TDX")+cEscala))

		While TDX->(!Eof()) .And. TDX->TDX_FILIAL==xFilial("TDX") .And. TDX->TDX_CODTDW==cEscala
			AAdd(aTurnosSeq, {TDX->TDX_TURNO, TDX->TDX_SEQTUR})
			TDX->(DbSkip())
		EndDo
	Else
		AAdd(aTurnosSeq,{cTurno,cSeqTrn})
	EndIf

	//Executa a função CriaCalend para receber o número de horas da escala do período
	For nContTurno :=1 To Len(aTurnosSeq)
	
		U_PNMSEsc(cEscala)
		U_PNMSCal(cCalend)
		lReturn := CriaCalend(dDataIni,dDataFim,aTurnosSeq[nContTurno,1],aTurnosSeq[nContTurno,2],@aTabPadrao,@aTabCalend,xFilial("SRA"),,,,aExcePer)
	
		//Soma o total de horas trabalhadas
		If lReturn
			For nX := 1 To Len(aTabCalend)
				If aTabCalend[nX][6] == "S"
					If Substr(aTabCalend[nX][4],2,1) == "E"
						nTotHrsEst += TxAjtHoras(aTabCalend[nX][7])
					ElseIf Substr(aTabCalend[nX][4],2,1) == "S"  
						nTotHrsEst += TxAjtHoras(aTabCalend[nX][9])	
					EndIf
				EndIf	
			Next nX
		EndIf 
	Next nContTurno	

	If lCntRec
		nTotHrsEst := (nTotHrsEst/12)
	Endif

	RecLock( cAliasABQ, lRecLock )
	ABQ->ABQ_FILIAL	:=	xFilial("ABQ")
	If lSrvExt
		ABQ->ABQ_CONTRT	:= cOrcSrv
		ABQ->ABQ_ORIGEM	:= "TFJ"
		ABQ->ABQ_CODTFJ	:= cOrcSrv
	Else
		ABQ->ABQ_CONTRT	:= cContr
		ABQ->ABQ_ORIGEM	:= "CN9"
	EndIf
	If lRecLock
		ABQ->ABQ_ITEM	:= cItem
	EndIf
	ABQ->ABQ_PRODUT	:=	aItemRH[nCont][ITEMRH_PRODUT]
	ABQ->ABQ_TPPROD	:=	"2"
	ABQ->ABQ_TPREC	:=	"1"
	ABQ->ABQ_CARGO	:= aItemRH[nCont][ITEMRH_CARGO]
	ABQ->ABQ_FUNCAO	:= aItemRH[nCont][ITEMRH_FUNCAO]
	ABQ->ABQ_PERINI	:= aItemRH[nCont][ITEMRH_PERINI]
	ABQ->ABQ_PERFIM	:= aItemRH[nCont][ITEMRH_PERFIM]
	If Empty(aItemRH[nCont][ITEMRH_ESCALA])
		ABQ->ABQ_TURNO	:= aItemRH[nCont][ITEMRH_TURNO]
	Endif
	ABQ->ABQ_HRSEST	:=	nTotHrsEst
	ABQ->ABQ_FATOR	:= aItemRH[nCont][ITEMRH_QTD]
	ABQ->ABQ_TOTAL	:= ABQ->ABQ_HRSEST*aItemRH[nCont][ITEMRH_QTD]
	ABQ->ABQ_SALDO	:= ABQ->ABQ_HRSEST*aItemRH[nCont][ITEMRH_QTD]
	ABQ->ABQ_CODTFF	:= aItemRH[nCont][ITEMRH_CODTFF]
	ABQ->ABQ_LOCAL	:= cLocal
	If lFilTFF
		ABQ->ABQ_FILTFF	:= aItemRH[nCont][ITEMRH_FILTFF]
	EndIf
	ABQ->(MsUnlock())

	If isInCallStack("copyABQ") .AND. !isBlind() .AND. oMeter != nil .AND. oDlg != nil
		oMeter:Set(nCont)
		oMeter:Refresh()
	EndIf
		
Next nCont

If isInCallStack("copyABQ") .AND. !isBlind() .AND. oMeter != nil .AND. oDlg != nil
	oDlg:End()
EndIf

RestArea(aArea)
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850AtvLocAtnd
Ativa Locais de Atendimento
@author Serviços
@since 31/10/13
@version P11 R9
@param cContr:Número do Contrato
@param cRevis:Revisão do Contrato
@param aLocais:Locais de Atendimento
@param cProp:Proposta Comercial
@param cReviPr:Revisão da Proposta
@return  .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At850AtvLocAtnd(cContr, cRevis, aLocais, cProp, cReviPr)

Local aArea		:= GetArea()
Local lRet			:= .T.
Local cAliasTFL	:= "TFL"
Local cAliasTFF	:= "TFF"
Local cAliasTFI	:= "TFI"
Local cAliasTFG	:= "TFG"
Local cAliasTFH	:= "TFH"
Local cAliasTEV	:= "TEV"
Local cAliasTFJ	:= "TFJ"
Local nPos 		:= 0
Local nCont		:= 0
Local lGrpFatOrc:= .F.//TFJ->TFJ_GRPFAT == '1'

DbSelectArea("T42")
DbSetOrder(1)//T42_FILIAL + T42_CODIGO

DbSelectArea("TWW")
DbSetOrder(1)//TWW_FILIAL + TWW_NUMERO + TWW_LOCAL

DbSelectArea("TFJ")
DbSetOrder(1)//TFJ_FILIAL + TFJ_CODIGO

For nCont	:= 1 to Len(aLocais)   //Atribui à TFL o contrato e revisão a qual ele pertence
	DbSelectArea(cAliasTFL)
	DbSetOrder(1)//TFL_FILIAL + TFL_CODIGO
	If DbSeek(xFilial(cAliasTFL) + aLocais[nCont][1]) //adicionar tratamento para gravar TWW, adicionar os campos TWW_CONTRT/TWW_CONREV
	
		If TFJ->(DbSeek(xFilial("TFJ")+TFL->TFL_CODPAI))
			lGrpFatOrc:= TFJ->TFJ_GRPFAT == '1'
		EndIf

		RecLock(cAliasTFL,.F.)
		(cAliasTFL)->TFL_CONTRT	:= cContr
		(cAliasTFL)->TFL_CONREV	:= cRevis
		If !lGrpFatOrc
			//Atribui referencias as planilhas
			nPos := aScan(aItXPl[1][5], {|x|x[1]==aLocais[nCont][1]})
			If nPos > 0					
				(cAliasTFL)->TFL_PLAN := aItXPl[1][5][nPos][2]//Planilha							
				(cAliasTFL)->TFL_ITPLRH := aItXPl[1][5][nPos][3][1]//Item RH		
				(cAliasTFL)->TFL_ITPLMI := aItXPl[1][5][nPos][3][2]//Item material implantação
				(cAliasTFL)->TFL_ITPLMC := aItXPl[1][5][nPos][3][3]//Item Material de Consumo					
				(cAliasTFL)->TFL_ITPLLE := aItXPl[1][5][nPos][3][4]//Item Locação de equipamentos						
			EndIf
		Endif

		MsUnlock()	
		
		//If lGrpFatOrc
		If T42->(DbSeek(xFilial("T42")+TFL->TFL_CODPAI))
			RecLock("T42",.F.)
				T42->T42_CONTRA := cContr
				T42->T42_CONREV := cRevis
			MsUnlock()
		EndIf
		
		If TWW->(DbSeek(xFilial("TWW")+TFL->TFL_CODPAI+TFL->TFL_LOCAL))
			RecLock("TWW",.F.)
				TWW->TWW_CONTRT := cContr
				TWW->TWW_REVISA := cRevis
				If lGrpFatOrc
					nPos := aScan(aItXPl[1][6], {|x|x[1]==aLocais[nCont][1]+"RH"})
					If nPos > 0
						TWW->TWW_PLANRH := aItXPl[1][6][nPos][2]
						TWW->TWW_ITEMRH := aItXPl[1][6][nPos][3]
					EndIf
					nPos := aScan(aItXPl[1][6], {|x|x[1]==aLocais[nCont][1]+"MI"}) 
					If nPos > 0
						TWW->TWW_PLANMI := aItXPl[1][6][nPos][2]
						TWW->TWW_ITEMMI := aItXPl[1][6][nPos][3]
					EndIf
					nPos := aScan(aItXPl[1][6], {|x|x[1]==aLocais[nCont][1]+"MC"}) 
					If nPos > 0
						TWW->TWW_PLANMC := aItXPl[1][6][nPos][2]
						TWW->TWW_ITEMMC := aItXPl[1][6][nPos][3]
					EndIf
					nPos := aScan(aItXPl[1][6], {|x|x[1]==aLocais[nCont][1]+"LE"}) 
					If nPos > 0
						TWW->TWW_PLANLE := aItXPl[1][6][nPos][2]
						TWW->TWW_ITEMLE := aItXPl[1][6][nPos][3]
					EndIf
				
			EndIf//lGrpFatOrc
			MsUnlock()
		EndIf 
	EndIf
Next nCont

//Atualiza Numero de Contrato TFF
TFF->(DbSetOrder(1))//TFF_FILIAL+TFF_CODIGO
For nCont	:= 1 to Len(aItXPl[1][2])
	If TFF->(DbSeek(xFilial(cAliasTFF)+aItXPl[1][2][nCont][1]))
		RecLock(cAliasTFF,.F.)
		(cAliasTFF)->TFF_CONTRT	:= cContr
		(cAliasTFF)->TFF_CONREV	:= cRevis
		MsUnlock()	
	EndIf
Next nCont

//Atualiza Numero de Contrato TFI
(cAliasTFI)->(DbSetOrder(1))//TFI_FILIAL+TFI_CODIGO
For nCont	:= 1 to Len(aItXPl[1][1])		//Atribui à TFI referente ao contrato a planilha e o item que eles estão associados.
	If (cAliasTFI)->(DbSeek(xFilial(cAliasTFI)+aItXPl[1][1][nCont][1]))	
		RecLock(cAliasTFI,.F.)
		(cAliasTFI)->TFI_CONTRT	:= cContr
		(cAliasTFI)->TFI_CONREV	:= cRevis
		MsUnlock()
	EndIf	
Next nCont	

DbSelectArea(cAliasTFJ)		//Atribui à TFJ o contrato e revisão a qual ele está relacionado.
DbSetOrder(2)
If DbSeek(xFilial(cAliasTFJ) + cProp + cReviPr)
	RecLock(cAliasTFJ,.F.)
	(cAliasTFJ)->TFJ_CONTRT	:= cContr
	(cAliasTFJ)->TFJ_CONREV	:= cRevis
	MsUnlock()
EndIf

For nCont := 1 to Len(aItXPl[1][1])		//Atribui à TFI referente ao contrato a planilha e o item que eles estão associados.	
	DbSelectArea(cAliasTEV)
	DbSetOrder(1)
	DbSeek(xFilial(cAliasTEV) + aItXPl[1][1][nCont][1])
	While (cAliasTEV)->(! Eof())
		If (cAliasTEV)->TEV_CODLOC == aItXPl[1][1][nCont][1]
			RecLock(cAliasTEV,.F.)
			(cAliasTEV)->TEV_SLD	:= (cAliasTEV)->TEV_QTDE
			MsUnlock()
		EndIf
		(cAliasTEV)->(DbSkip())
	EndDo
Next nCont	

For nCont	:= 1 to Len(aItXPl[1][3])	//Atribui à TFI referente ao contrato a planilha e o item que eles estão associados.
	DbSelectArea(cAliasTFG)
	DbSetOrder(1)
	If DbSeek(xFilial(cAliasTFG) + aItXPl[1][3][nCont][1])
		RecLock(cAliasTFG,.F.)
		(cAliasTFG)->TFG_SLD	:= (cAliasTFG)->TFG_QTDVEN	
		(cAliasTFG)->TFG_CONTRT	:= cContr
		(cAliasTFG)->TFG_CONREV	:= cRevis
		MsUnlock()
	EndIf
Next nCont	

For nCont	:= 1 to Len(aItXPl[1][4]) //Atribui à TFI referente ao contrato a planilha e o item que eles estão associados.
	DbSelectArea(cAliasTFH)
	DbSetOrder(1)
	If DbSeek(xFilial(cAliasTFH) + aItXPl[1][4][nCont][1])
		RecLock(cAliasTFH,.F.)	
		(cAliasTFH)->TFH_SLD	:= (cAliasTFH)->TFH_QTDVEN
		(cAliasTFH)->TFH_CONTRT	:= cContr
		(cAliasTFH)->TFH_CONREV	:= cRevis
		MsUnlock()	
	EndIf
Next nCont

RestArea(aArea)
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT850DtInFim
Determina a data inicial e final do contrato de acordo com a menor data de início e a maior data final dos locais da 
proposta comercial.
@author Serviços
@since 28/11/13
@version P11 R9
@return  aRet: Array com o valor da data inicial e final. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function AT850DtInFim(cCodProp,cRevProp)

Local aArea     	:= GetArea()
Local aAreaTFL	:= TFL->(GetArea())
Local cAliasTFL	:= GetNextAlias()
Local cQuery		:=""
Local aRet			:={}
Local dDtIni
Local dDtFim
Local cCnPag 		:=""

DbSelectArea("TFL")
TFL->(DbsetOrder(1))
	
cQuery	:=	"SELECT * " + CRLF
cQuery	+=	" FROM " + RetSqlName("TFL") + " TFL " + CRLF 
cQuery	+=	" INNER JOIN " + RetSqlName("TFJ") + " TFJ " + CRLF 
cQuery +=	" 	 ON TFJ_FILIAL = '" + xFilial("TFJ") + "' " + CRLF
cQuery +=	"   AND TFJ_CODIGO = TFL_CODPAI " + CRLF
cQuery	+=	" WHERE " + CRLF 
cQuery	+=	"	TFL_FILIAL = '" + xFilial("TFL") + "' AND " + CRLF   
cQuery	+=	" 	TFJ_PROPOS = '" + cCodProp + "' AND " + CRLF
cQuery	+=	" 	TFJ_PREVIS = '" + cRevProp + "' AND " + CRLF
cQuery	+=	" 	TFJ.D_E_L_E_T_ = '' AND " + CRLF
cQuery	+=	" 	TFL.D_E_L_E_T_ = ' '"

cQuery		:= ChangeQuery(cQuery)
DbUseArea(.T., "TOPCONN",TcGenQry(,,cQuery), cAliasTFL, .T., .T.)

dDtIni:= (cAliasTFL)->TFL_DTINI
dDtFim:= (cAliasTFL)->TFL_DTFIM

While (cAliasTFL)->(! Eof())
	If (cAliasTFL)->TFL_DTINI < dDtIni
		dDtIni	:= (cAliasTFL)->TFL_DTINI
	EndIf
	If (cAliasTFL)->TFL_DTFIM > dDtFim
		dDtFim	:= (cAliasTFL)->TFL_DTFIM
	EndIf
	cCnPag:= (cAliasTFL)->TFJ_CONDPG
	(cAliasTFL)->(DbSkip())
EndDo	
(cAliasTFL)->(DbCloseArea())

aadd(aRet, dDtIni)
aadd(aRet, dDtFim)
aadd(aRet, cCnPag)
RestArea(aAreaTFL)
RestArea(aArea)
Return aRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850ValCau
Valida o campo do percentual de caução.
@author Serviços
@since 26/12/13
@version P11 R9
@return  aRet: Array com o valor da data inicial e final. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At850ValCau(cCbxFgCau)

Local lRet := (cCbxFgCau == STR0005)	// "Sim"
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850GCTCr
Gera planilha do contrato e cronogramas financeiros e contábeis.
@param		aMaster:	Contrato
@param		aDetCli:	Clientes
@param		aDetCab:	Planilhas
@param		aDetItem:	Itens Planilhas
@return	lRet, lógico 
@author	Bruno.Rosa
@since		10/02/14
@version	P11 R9
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At850GCTCr(aMaster, aDetCli, aDetCab, aDetItem, aDetVend, oModel, cTpPl, lVigente, lMsmCrF, lMsmCrC, nQtdRec)

Local oAux
Local oStruct
Local nI				:= 0
Local nJ				:= 0
Local nL				:= 0
Local nK				:= 0
Local nW				:= 0
Local nX				:= 0
Local nZ				:= 0
Local nPos				:= 0
Local nCount			:= 0
Local nPlan				:= 0
Local nItErro			:= 0
Local cMaster			:= "CN9"
Local cDetItm			:= "CNB"
Local aDetail			:= {"CNC", "CNA", "CNU"}
Local aAux				:= {}
Local aCposCab			:= {}
Local aCposDet			:= {}
Local lIniContrato		:= ( ValType(oModel) == "U" )
Local lAux				:= .T.
Local lRet				:= .T.
Local lCronF			:= .F.
Local lCronC			:= .F.
Local cMedEve			:= ""
Local cCroCTB			:= ""
Local cCodCNL			:= ""
Local nTipoGerCron 		:= 0
Local cMsgErro 			:= ""
Local bWhen				:= Nil
Local lMsgCronF			:= .T.
Local lMsgCronC			:= .T.
Local lExistCrF			:= .F.
Local lExistCrC			:= .F.

Default lVigente := .F.
Default oModel := FwLoadModel("CNTA301")
Default nQtdRec := 0

If lIniContrato
	oModel:SetOperation( 3 )
	oModel:Activate()
EndIf

aCposCab := aClone(aMaster)
If	Len(aDetCli) > 0
	aAdd( aCposDet, aDetCli )
EndIf
If	Len(aDetCab) > 0
	aAdd( aCposDet, aDetCab )
EndIf
If	Len(aDetVend) > 0
	aAdd( aCposDet, aDetVend )
EndIf

DbSelectArea( "CNC" )
DbSetOrder( 1 )	//CNC_FILIAL+CNC_NUMERO+CNC_REVISA+CNC_CODIGO+CNC_LOJA

DbSelectArea( "CNU" )
DbSetOrder( 1 )	//CNU_FILIAL+CNU_CONTRA+CNU_CODVD

DbSelectArea( "CNA" )
DbSetOrder( 1 )	//CNA_FILIAL+CNA_CONTRA+CNA_REVISA+CNA_NUMERO

DbSelectArea( "CNB" )
DbSetOrder( 1 )	//CNB_FILIAL+CNB_CONTRA+CNB_REVISA+CNB_NUMERO+CNB_ITEM

DbSelectArea( cMaster )
DbSetOrder( 1 )

// Instanciamos apenas a parte do modelo referente aos dados de cabeçalho
oAux := oModel:GetModel( cMaster + 'MASTER' )

// Obtemos a estrutura de dados do cabeçalho
oStruct := oAux:GetStruct()
aAux := oStruct:GetFields()

If lRet
	For nI := 1 To Len( aCposCab )
		// Verifica se os campos passados existem na estrutura do cabeçalho
		If ( nPos := aScan( aAux, { |x| AllTrim( x[3] ) == AllTrim( aCposCab[nI][1] ) } ) ) > 0
			If !( lAux := oModel:SetValue( cMaster + 'MASTER', aCposCab[nI][1],aCposCab[nI][2] ) )
				lRet := .F.
				Exit
			EndIf
		EndIf
	Next
EndIf

If lRet

	For nI := 1 To Len( aCposDet )

		// Instanciamos apenas a parte do modelo referente aos dados do item
		oAux := oModel:GetModel( aDetail[nI] + 'DETAIL' )

		// Obtemos a estrutura de dados do item
		oStruct := oAux:GetStruct()
		aAux := oStruct:GetFields()

		For nJ := 1 To Len( aCposDet[nI] )			
			nItErro := 0  //Pensar caso tenha mais itens para um mesmo detalhe do model				
			If nJ > 1
				If ( nItErro := oAux:AddLine() ) <> nJ
					lRet := .F.
					Exit
				EndIf
			EndIf

			oModel:GetModel(aDetail[nI]+'DETAIL'):GoLine(nJ)

			For nL := 1 To Len(aCposDet[nI][nJ])	

				If ( nPos := aScan( aAux, { |x| AllTrim( x[3] ) == AllTrim( aCposDet[nI][nJ][nL][1] ) } ) ) > 0
					If aCposDet[nI][nJ][nL][1] $ "CNA_FLREAJ|CNA_UNPERI"
						bWhen := oStruct:GetProperty(Alltrim(aCposDet[nI][nJ][nL][1]),MODEL_FIELD_WHEN)
						oStruct:SetProperty(Alltrim(aCposDet[nI][nJ][nL][1]),MODEL_FIELD_WHEN,{||.T.})				
					Endif
					If !( lAux := oModel:SetValue( aDetail[nI] + 'DETAIL', aCposDet[nI][nJ][nL][1], aCposDet[nI][nJ][nL][2] ) )
						lRet := .F.
						nItErro := nJ
						Exit
					EndIf
					If aCposDet[nI][nJ][nL][1] $ "CNA_FLREAJ|CNA_UNPERI"
						oStruct:SetProperty(Alltrim(aCposDet[nI][nJ][nL][1]),MODEL_FIELD_WHEN, bWhen )
					Endif
				EndIf

			Next nL

			If lRet .and. nI == 2 

				// Instanciamos apenas a parte do modelo referente aos dados do item
				oAux := oModel:GetModel( cDetItm + 'DETAIL' )

				// Obtemos a estrutura de dados do item
				oStruct := oAux:GetStruct()
				aAux := oStruct:GetFields()

				For nk := 1 To Len(aDetItem) //Itens da planilha

					For nX := 1 To Len(aDetItem[nk])

						If ( nPlan := aScan(aDetItem[nK],{ || aDetItem[nK][nX][2][2] == aCposDet[nI][nJ][2][2] } ) ) > 0

							nItErro := 0  				
							If nX > 1
								If ( nItErro := oAux:AddLine() ) <> nX
									lRet := .F.
									Exit
								EndIf
							EndIf

							For nW := 1 To Len(aDetItem[nK][nX])		
								If ( nPos := aScan( aAux, { |x| AllTrim( x[3] ) == AllTrim( aDetItem[nk][nX][nW][1] ) } ) ) > 0								
										If !( lAux := oModel:SetValue( cDetItm + 'DETAIL', aDetItem[nk][nX][nW][1], aDetItem[nk][nX][nW][2] ) )
											lRet := .F.
											nItErro := nX
											Exit
										EndIf
								EndIf
							Next nW

							If !lRet
								Exit
							EndIf
						EndIf

					Next nX
					// posiciona na primeira linha
					oAux:GoLine(1)

					If !lRet
						Exit
					EndIf
				Next nk

				If !lRet
					Exit
				EndIf

				// Instanciamos apenas a parte do modelo referente aos dados do item
				oAux := oModel:GetModel( aDetail[nI] + 'DETAIL' )
				// posiciona na primeira linha do grid

				oAux:GoLine(1)
				// Obtemos a estrutura de dados do item
				oStruct := oAux:GetStruct()
				aAux := oStruct:GetFields()

			EndIf

		Next nJ

		If !lRet
			Exit
		EndIf
	Next nI
EndIf

If lRet
	While ( ( nTipoGerCron := GSEscolha( STR0144,; // "Cronogramas financeiros"
								STR0145,;  // "Selecione como deseja definir os cronogramas financeiros."
								{ STR0146, STR0147 },;  // "Sem Interface/Processo Antigo" ##  "Visualizando Contrato"
								1) ) == 0 )
	End 

	If nTipoGerCron == 1
		If !lTecA870
			cCodCNL := aDetCab[1][3][2]
		Else 
			cCodCNL := cTpPl
		EndIf
		
		DbSelectArea("CNL")
		CNL->(DbSetOrder(1))	
		
		DbSelectArea("CN1")
		CN1->(DbSetOrder(1))
		CN1->(DbSeek(xFilial("CN1")+aCposCab[1][2]))
	
		If CNL->(DbSeek(xFilial("CNL")+cCodCNL))
			//Tratativas para validar quando o tipo de planilha estiver como conforme o contrato
			If ( CNL->CNL_MEDEVE == "0" .And. CNL->CNL_CROCTB == "0" ) .Or. ;
				( CNL->CNL_MEDEVE == " " .And. CNL->CNL_CROCTB == " " )
				
				cMedEve	:= CN1->CN1_MEDEVE
				cCroCTB	:= CN1->CN1_CROCTB
			ElseIf CNL->CNL_MEDEVE == "0" .And. CNL->CNL_CROCTB <> "0"
				cMedEve	:= CN1->CN1_MEDEVE
				cCroCTB	:= CNL->CNL_CROCTB
			ElseIf CNL->CNL_MEDEVE <> "0" .And. CNL->CNL_CROCTB == "0"
				cMedEve	:= CNL->CNL_MEDEVE
				cCroCTB	:= CN1->CN1_CROCTB
			Else
				cMedEve	:= CNL->CNL_MEDEVE
				cCroCTB	:= CNL->CNL_CROCTB
			EndIf
		
			If lTecA870
				For nZ := 1 To oModel:GetModel("CNADETAIL"):Length()
					oModel:GetModel("CNADETAIL"):GoLine(nZ)
					oModel:GetModel("CNADETAIL"):SetValue("CNA_TIPPLA",cTpPl)
					CN300TpPla()
					//Se for contrato recorrente atualiza a quantidade de recorrências
					If nQtdRec > 0 .And. !(lRet := oModel:GetModel("CNADETAIL"):SetValue("CNA_QTDREC",nQtdRec))
						Exit
					Endif
					If cMedEve == "2"
						For nCount := 1 to oModel:GetModel("CNFDETAIL"):Length()
							oModel:GetModel("CNFDETAIL"):GoLine(nCount)
							If !oModel:GetModel("CNFDETAIL"):IsDeleted() .And. !Empty(oModel:GetModel("CNFDETAIL"):GetValue("CNF_COMPET"))
								If lMsgCronF
									lCronF := MsgYesNo(STR0171)//"Gostaria de excluir o(s) cronograma(s) financeiro(s) e gerar outro(s) conforme os parâmetros do assistente?"
									lMsgCronF := .F.
								Endif
								lExistCrF := .T.
								Exit
							EndIf

						Next nCount
						If lCronF .And. lExistCrF
							CN300DelCrg(.T.) //Exclui cronograma financeiro atual
							lRet := CN300AddCrg(,IIf(nZ == 1, .F.,lMsmCrF))  //Cria um novo cronograma financeiro
						EndIf
					EndIf
					If cCroCTB == "1" 
						For nCount := 1 to oModel:GetModel("CNVDETAIL"):Length()
							oModel:GetModel("CNVDETAIL"):GoLine(nCount)
							If !oModel:GetModel("CNVDETAIL"):IsDeleted() .And. !Empty(oModel:GetModel("CNVDETAIL"):GetValue("CNV_NUMERO"))
								If lMsgCronC
									lCronC  := MsgYesNo(STR0170) //"Gostaria de excluir o(s) cronograma(s) contábel(is) e gerar outro(s) conforme os parâmetros do assistente?"
									lMsgCronC := .F. 
								Endif
								lExistCrC := .T.
								Exit
							EndIf
						Next nCount
						If lCronC .And. lExistCrC
							oModel:GetModel("CNWDETAIL"):SetNoUpdateLine(.F.)
							oModel:GetModel("CNWDETAIL"):SetNoInsertLine(.F.)							
							oModel:GetModel("CNVDETAIL"):SetNoUpdateLine(.F.)
							oModel:GetModel("CNVDETAIL"):SetNoInsertLine(.F.)

							CN300DelCtb(.T.) //Exclui cronograma contabil atual
							lRet := CN300AddCtb(IIf(nZ == 1, .F.,lMsmCrC))	 //Cria cronograma contábil
						EndIf
					EndIf
					lExistCrF := .F.
					lExistCrC := .F.
				Next nZ
			Else
				For nZ := 1 To Len(aCposDet[2])
					oModel:GetModel(aDetail[2]+'DETAIL'):GoLine(nZ)
					If lRet .And. cMedEve == "2"
						
						lRet := CN300AddCrg(,IIf(nZ == 1, .F.,lMsmCrF))  //Cria cronograma financeiro
					EndIf
					If lRet .And. cCroCTB == "1"
						oModel:GetModel("CNWDETAIL"):SetNoUpdateLine(.F.)
						oModel:GetModel("CNWDETAIL"):SetNoInsertLine(.F.)
						
						oModel:GetModel("CNVDETAIL"):SetNoUpdateLine(.F.)
						oModel:GetModel("CNVDETAIL"):SetNoInsertLine(.F.)
						lRet := CN300AddCtb(IIf(nZ == 1, .F.,lMsmCrC))	 //Cria cronograma contábil
					EndIf
				Next nZ
			EndIf		
		EndIf

		lRet := lRet .And. oModel:VldData() .And. oModel:CommitData()

	Else
		// bloqueia as alterações nas planilhas, itens e pool de clientes
		oModel:GetModel("CNADETAIL"):SetNoDeleteLine(.T.)
		oModel:GetModel("CNADETAIL"):SetNoInsertLine(.T.)
		oModel:GetModel("CNBDETAIL"):SetNoDeleteLine(.T.)
		oModel:GetModel("CNBDETAIL"):SetNoInsertLine(.T.)
		oModel:GetModel("CNCDETAIL"):SetNoDeleteLine(.T.)
		oModel:GetModel("CNCDETAIL"):SetNoInsertLine(.T.)
		// Realiza a exibição do contrato de venda utilizando o modelo populado
		lRet := (FWExecView(STR0148,"CNTA301", OP_INCLUIR,,{|| .T.},{|oModel|At850Ok301(oModel, lVigente)}/*bOk*/,,,;
							{|oModel|At850Cn301(oModel, lVigente)}/*bCancel*/,,,oModel) == 0 )  // "Geração do Contrato GS"
		If !lRet 
			cMsgErro := STR0149
		EndIf
	EndIf
EndIf

If !lRet

	If oModel:HasErrorMessage()
		aErro := oModel:GetErrorMessage()
	
		AutoGrLog( STR0083 + ' [' + AllToChar( aErro[1] ) + ']' )	//"Id do formulário de origem:"
		AutoGrLog( STR0084 + ' [' + AllToChar( aErro[2] ) + ']' )	//"Id do campo de origem: "
		AutoGrLog( STR0085 + ' [' + AllToChar( aErro[3] ) + ']' )	//"Id do formulário de erro: "
		AutoGrLog( STR0086 + ' [' + AllToChar( aErro[4] ) + ']' )	//"Id do campo de erro: "
		AutoGrLog( STR0087 + ' [' + AllToChar( aErro[5] ) + ']' )	//"Id do erro: "
		AutoGrLog( STR0088 + ' [' + AllToChar( aErro[6] ) + ']' )	//"Mensagem do erro: "
		AutoGrLog( STR0089 + ' [' + AllToChar( aErro[7] ) + ']' )	//"Mensagem da solução: "
		AutoGrLog( STR0090 + ' [' + AllToChar( aErro[8] ) + ']' )	//"Valor atribuído: "
		AutoGrLog( STR0091 + ' [' + AllToChar( aErro[9] ) + ']' )	//"Valor anterior: "
		If nItErro > 0
			AutoGrLog( STR0092 + ' [' + AllTrim( AllToChar( nItErro ) ) + ']' )	//"Erro no Item: "
		EndIf
		MostraErro()
	ElseIf !Empty(cMsgErro)
		MsgAlert( cMsgErro, STR0150 ) // "Problemas na geração do contrato"
	Else
		MsgAlert( STR0151, STR0150 ) // "Contrato não pôde ser gerado!" ### "Problemas na geração do contrato"
	EndIf
EndIf

oModel:DeActivate()
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850Func
Consulta funcionários que não tenham atendentes relacionados.
@since 21/02/14
@version P12
@param cCusto:Centro de Custo a ser pesquisado
@return aFunc: Funcionários do centro de custo informado que não tenham atendentes relacionados.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At850Func(cCcusto)

Local aArea		:= GetArea()
Local cAliasSRA	:= GetNextAlias()
Local aFunc		:= {}
Local cQuery		:= ""

Default cCCusto := ""  

cQuery		:= "SELECT RA_FILIAL, RA_TNOTRAB, RA_CC, RA_MAT, RA_NOME, RA_CARGO, RA_CODFUNC "
cQuery		+=   "FROM " + RetSqlName("SRA")+" SRA "
// Where para selecionar funcionários que não estejam cadastrados como atendente
cQuery		+=  "WHERE SRA.RA_FILIAL = '" + xFilial("SRA") + "' "
cQuery		+=    "AND SRA.D_E_L_E_T_ = '' "
If SuperGetMv("MV_MSBLQL",,.F.)
	cQuery	+=    "AND SRA.RA_MSBLQL = '2' "	
EndIf
If AllTrim(cCCusto) <> ""
	cQuery	+=    "AND SRA.RA_CC = '" + cCcusto + "' "
EndIf
cQuery		+=    "AND NOT EXISTS(SELECT AA1_CDFUNC, AA1_FILIAL FROM " + RetSqlName("AA1") + " AA1 WHERE AA1.AA1_CDFUNC = SRA.RA_MAT AND AA1.AA1_FILIAL = '" + xFilial("AA1") + "' AND AA1.D_E_L_E_T_ = '' ) "   

cQuery := ChangeQuery(cQuery)
DbUseArea(.T., "TOPCONN", TcGenQry(,,cQuery), cAliasSRA, .T., .T. )
//	Preenche o array com as informações de funcionários que não são atendentes.
While &(cAliasSRA)->(! Eof())
	aAdd(aFunc,{ (cAliasSRA)->RA_FILIAL,;
	             (cAliasSRA)->RA_MAT,;
	             (cAliasSRA)->RA_NOME,;
	             (cAliasSRA)->RA_CARGO,;
	             Posicione("SQ3", 1, xFilial("SQ3") + (cAliasSRA)->RA_CARGO, "Q3_DESCSUM"),;
	             (cAliasSRA)->RA_CODFUNC,;
	             (cAliasSRA)->RA_TNOTRAB,;
	             (cAliasSRA)->RA_CC,;
	             Posicione("SRJ", 1, xFilial("SRJ") + (cAliasSRA)->RA_CODFUNC, "RJ_DESC") })
	&(cAliasSRA)->(DbSkip())
EndDo
&(cAliasSRA)->(DbCloseArea())

If Len(aFunc)==0
	aFunc :={{"","","","","","","","",""}}
EndIf
RestArea(aArea)	
Return ( aFunc )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850GFunc
Gera atendentes com os funcionários do centro de custo informado que não possuem relacionamento com atendentes.
@since 21/02/14
@version P12
@param cCusto:Centro de Custo a ser pesquisado
@return lMsErroAuto: Caso nãotenha conseguido gravar os atendentes
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At850GFunc(aFuncionar)

Local aRotAuto := {}
Local nCont	:= 0 
Private lMsErroAuto := .F.

If aFuncionar[1][1]<>""
		Begin Transaction
	For nCont := 1 To Len(aFuncionar)

		aAdd(aRotAuto,{"AA1_NOMTEC",aFuncionar[nCont,P_NOMEFUN],Nil})
		aAdd(aRotAuto,{"AA1_FUNCAO",aFuncionar[nCont,P_FUNCAO],Nil})
		aAdd(aRotAuto,{"AA1_CDFUNC",aFuncionar[nCont,P_MAT],Nil})
		aAdd(aRotAuto,{"AA1_FUNFIL",aFuncionar[nCont,P_FILIAL],Nil})
		aAdd(aRotAuto,{"AA1_CC",aFuncionar[nCont,P_CC],Nil})
		aAdd(aRotAuto,{"AA1_TURNO",aFuncionar[nCont,P_TURNO],Nil})

				MsgRun( STR0043,STR0068,{|| MsExecAuto( {|a,b| TECA020(a,b)},3,aRotAuto)})// 'Atenção' ### "Aguarde..."]

		If lMsErroAuto
			MostraErro()
			DisarmTransacation()
			Exit
		EndIf

				//limpa o array
				aRotAuto := {}
				
	Next nCont
		End Transaction
Else
	Help(,,'AT850VAZIO',, STR0106,1,0)//"Sem funcionários com este centro de custo que não tenham relacionamento com um Atendente!"
EndIf

Return lMsErroAuto


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850CaAtd
Abre tela para cadastro de atendente
@since 21/02/14
@version P12
@param cCodAtend:Código do atendente
@param nOperation:Número da Operação a ser realizada
@param cOperation:String com ação a realizar 
@return .T.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At850CaAtd(cCodAtend, nOperation, cOperation)						

Default cCodAtend := ""

If nOperation=3
	FwExecView(cOperation, "VIEWDEF.TECA020", nOperation, /*oDlg*/, {|| .T.}, /*bOK */,/*nPercReducao*/)
Else
	DbSelectArea("AA1")
	DbsetOrder(1)
	DbSeek(xFilial("AA1")+cCodAtend)
	FwExecView(cOperation, "VIEWDEF.TECA020", nOperation, /*oDlg*/, {|| .T.}, /*bOK */,/*nPercReducao*/)
EndIf
Return ( .T. )


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850AtFnc
Atualiza grid de funcionários
@since 21/02/14
@version P12
@param aFuncionar:Funcionários
@param oLbxFunc:objeto do listbox
@param cCcusto:Centro de Custo 
@return .T.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At850AtFnc(aFuncionar, oLbxFunc, cCcusto)  	

aFuncionar := At850Func(cCcusto)
oLbxFunc:SetArray(aFuncionar)
	oLbxFunc:bLine	:= {|| {aFuncionar[oLbxFunc:nAt,P_MAT],;
						        aFuncionar[oLbxFunc:nAt,P_NOMEFUN],;
						        aFuncionar[oLbxFunc:nAt,P_CARGO],;
						        aFuncionar[oLbxFunc:nAt,P_DESCARG],;				
						        aFuncionar[oLbxFunc:nAt,P_FUNCAO],;		
						        aFuncionar[oLbxFunc:nAt,P_DESFUNC]}}
oLbxFunc:Refresh()
Return( .T. )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850Comiss
Retorna a Comissão a ser utilizada no contrato de acordo com a configuração
do cliente ou do vendedor.
@since 15/12/15
@version P12
@param cVend : Codigo do Vendedor
@param cCli : Codigo do Cliente
@param cLoja : Codigo da Loja do Cliente
@return aRet
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At850Comiss(cVend,cCli,cLoja, lComisPorTime)

Local aRet	:= {}
Local aAreaSA1	:= SA1->(GetArea())
Local aAreaSA3	:= SA3->(GetArea())
Local nComis	:= 0
Local aVend := {}
Local aTime := {}
Local cFilAD2 := xFilial("AD2")
Local nI := 0

Default lComisPorTime 	:= .F.

//Verifica se tem comissão para o cliente
DbSelectArea("SA1")
SA1->(DbSetOrder(1))

// se for comissão por time troca o cliente para o cliente da oprtunidade de venda
If lComisPorTime .And. ADY->ADY_ENTIDA == "1"
	cCli := ADY->ADY_CODIGO
	cLoja := ADY->ADY_LOJA
EndIf

// 	Procura o percentual de comissão do cliente
// quando comissão por time utiliza o cliente da oportunidade de venda
// quando comissão pelo vendedor da oportunidade de venda, utiliza o cliente do último local do orçamento de serviços
If SA1->( DbSeek(xFilial("SA1") + cCli + cLoja) )
	nComis := SA1->A1_COMIS
EndIf

If lComisPorTime

	DbSelectArea("AD2")
	AD2->( DbSetOrder( 1 ) ) // AD2_FILIAL+AD2_NROPOR+AD2_REVISA+AD2_VEND
	If AD2->( DbSeek( cFilAD2 + ADY->ADY_OPORTU + ADY->ADY_REVISA ) )
		// procura no time de vendas pelos percentuais para os vendedores
		While AD2->( !EOF() ) .And. AD2->AD2_FILIAL == cFIlAD2 .And. ;
			AD2->AD2_NROPOR == ADY->ADY_OPORTU .And. AD2->AD2_REVISA == ADY->ADY_REVISA
		
			aAdd( aTime, { AD2->AD2_VEND, AD2->AD2_PERC, 0 } )
			
			AD2->( DbSkip() )
		End
		// 	Converte os valores de percentuais encontrados no time de vendas
		// conforme o percentual encontrado para o cliente ou vendedores
		//   Por exemplo: 
		/* 	Primeira situação: Cliente com 5% na comissão e dois vendedores no time de vendas com 60% um e 40% outro
						primeiro vendedor ficará com 3% <= [ 5% * (60/100) ]
						segundo vendedor ficará com 2% <= [ 5% * (40/100) ]
			Segunda situação: Cliente com 0% na comissão e dois vendedores no time de vendas com 60% um e 40% outro, 
				mas o percentual de comissão para cada vendedor em seus cadastros são 4 e 7 respectivamente.
						primeiro vendedor ficará com 2,4% <= [ 4% * (60/100) ]
						segundo vendedor ficará com 2,8% <= [ 7% * (40/100) ]
		*/
		If nComis > 0
			aEval( aTime, {|x| x[3] := ( nComis * ( x[2]/100 ) ) } )
		Else
			DbSelectArea("SA3")
			SA3->(DbSetOrder(1))
			
			For nI := 1 To Len( aTime )
			
				If SA3->( DbSeek(xFilial("SA3") + aTime[nI,1]) )
					aTime[nI,3] := ( SA3->A3_COMIS * ( aTime[nI,2]/100 ) )
				EndIf
			Next nI
		EndIf
		// adiciona ao array de retorno a ser utilizado na criação do contrato
		For nI := 1 To Len( aTime )
			If aTime[nI,3] > 0
				aSize( aVend, 0 )
				Aadd(aVend,{"CNU_CODVD"	, aTime[nI,1], NIL })
				Aadd(aVend,{"CNU_PERCCM", aTime[nI,3], NIL })
				
				Aadd(aRet,aClone(aVend))
			EndIf
		Next nI
		
	EndIf
Else
//Verifica se tem comissão com vendedor.
	If nComis == 0
	DbSelectArea("SA3")
	SA3->(DbSetOrder(1))

	If SA3->( DbSeek(xFilial("SA3") + cVend) )
		nComis := SA3->A3_COMIS
		EndIf
	EndIf
	
	If nComis > 0
		Aadd(aVend,{"CNU_CODVD"		, cVend		, NIL })
		Aadd(aVend,{"CNU_PERCCM"	, nComis	, NIL })

		Aadd(aRet,aClone(aVend))
	EndIf
EndIf

RestArea(aAreaSA1)
RestArea(aAreaSA3)
Return aRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} GetDtProp
Retorna a data de assinatura da proposta comercial
@param		cProposta : Codigo da proposta comercial sendo convertida em contrato
@return	dRet
@since		12/05/16
@version	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function GetDtProp(cProposta)

Local aArea	:= GetArea()
Local dData	:= CtoD(Space(08))

DbSelectArea("ADY")
ADY->(dbSetOrder(1))
If	ADY->(DbSeek(xFilial("ADY") + Padr(cProposta,TamSx3("ADY_PROPOS")[1])))
	DbSelectArea('AD1')
	AD1->(dbSetOrder(1))
	If	AD1->(DbSeek(xFilial("AD1") + ADY->ADY_OPORTU))
		dData	:= AD1->AD1_DTASSI
	EndIf
EndIf

RestArea(aArea)
Return dData

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} at850ValDt

Valid Data do Contrato
@author Serviços
@since 11/08/16
@version P12
@param cDt: Data digitada pelo Usuario
@param cDtMax: Data Maior da Localidade
@param cTp: String que Informa qual o Tipo INI ou FIM

@return  lRet -> .T., Validou, .F. -> Não validou 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function at850ValDt(dDt,dDtMax,cTp)

Local lRet := .F.
	
Default cTp := 'INI'
	
If cTp == 'INI'
	lRet := dDt <= dDtMax
ElseIf cTp == 'FIM' 
	lRet := (dDt >= dDtMax)
EndIf

If !lRet
	MsgAlert(STR0135,STR0134)//#"Data não pode estar dentro do periodo de vigencia desse orçamento"  #"Verificar Data"
EndIf 
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850TpPl

Verifica o tipo de Planilha
@author Joni.carmo
@since 21/09/2016
@version P12
@param cTPlan:Tipo de Planilha
@return  .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At850TpPl(cTpPl,cRecor, cOporProp ) // Verifica o tipo do contrato

Local lRet		 := .T.
Local aArea 	 := GetArea()
Local aAreaCNL	 := CNL->(GetArea())
Local nItSel	 := 0	
	
Default cTpPl  := ""
Default cRecor := ""
Default cOporProp	:= ""	
	
DbSelectArea("CNL")
CNL->(DbSetOrder(1))
	
If CNL->(DbSeek(xFilial("CNL") + cTpPl))
		
	If CNL->CNL_MEDEVE == "1"
		Aviso(STR0137, STR0138, {STR0055}, 2)//"Tipo de Planilha"###"O Tipo de Planilha Selecionado possui medição eventual, em contratos com medição eventual não é possível realizr medições de serviços."###"OK"
		lRet	:=	.F.
	EndIf
	
	If CNL->CNL_CTRFIX == "2"
		Aviso(STR0137, STR0139, {STR0055}, 2) //"Tipo de Planilha"###"O Tipo de Planilha deve ser do tipo fixo!"###"OK"
		lRet	:= .F.
	EndIf
	
	If CNL->CNL_CROFIS == "1"
		Aviso(STR0137, STR0140, {STR0055}, 2)//"Tipo de Planilha"##"Selecionado deve ser configurado para não gerar cronograma fisico." ### "OK"
		lRet	:=	.F.
	EndIf
	
	If CNL->CNL_MEDEVE <> "3" .And. cRecor == "1"
		Aviso(STR0137, STR0166, {STR0055}, 2)//"Tipo de Planilha"##"O Tipo de Planilha selecionado não possui Medição Recorrente, informe um Tipo de Planilha com Medição Recorrente."" ### "OK"
		lRet	:=	.F.
	Elseif CNL->CNL_MEDEVE == "3" .And. cRecor == "2"
		Aviso(STR0137, STR0167, {STR0055}, 2)//"Tipo de Planilha"##"O Orçamento de Serviços não esta configurado para gerar Contrato Recorrente, informe um Tipo de Planilha que não esteja configurado com Medição Recorrente." ### "OK"
		lRet	:=	.F.	
	Endif
		
	If (CN1->CN1_CROCTB == "1") .AND. CNL->CNL_MEDEVE == "0"
		lMsmCrCt := VldMsmCrng(cOporProp) //Valida se permite utilizar mesmo cronograma para todos os locais
	Else
		lMsmCrCt := .F.
	EndIF
	
	If (CN1->CN1_MEDEVE == "2") .AND. (CN1->CN1_VLRPRV == "1") .AND. CNL->CNL_MEDEVE == "0"
		lMsmCrFi := VldMsmCrng(cOporProp) //Valida se permite utilizar mesmo cronograma para todos os locais
	Else
		lMsmCrFi := .F.
	EndIf
	
EndIf
	
RestArea(aAreaCNL)
RestArea(aArea)
	
Return lRet	  

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} A850AtItCNB

/*/
//--------------------------------------------------------------------------------------------------------------------
Function A850AtItCNB(cTabela,nRecno,cCampo,cValor)
Local aArea	:= GetArea()	

(cTabela)->(dbGoto(nRecno))
RecLock( cTabela,.F.)
(cTabela)->&(cCampo) = cValor
(cTabela)->(MsUnlock())    

RestArea(aArea)
	
Return 

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850GetCli
	Busca o cliente do local de atendimento conforme o preenchimento no orçamento de serviços
@author 	josimar.assuncao
@since		12/05/16
@version	P12
@param 		cCodCli, Caracter, Referência, variável para retorno do código cliente 
@param 		cLojCli, Caracter, Referência, variável para retorno da loja do cliente
@param 		cCodigoLoc, Caracter, código do local a ser avaliado o cliente 
@param 		cTFJAGrupa, Caracter, definição no orçamento de serviços de qual cliente dos locais de atendimento deverá ser utilizado
@return		Lógico, não encontrou o cliente para retornar
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At850GetCli( cCodCli, cLojCli, cCodigoLoc, cTFJAgrupa )
Local lCliOk := .F. 

cCodCli := ""
cLojCli := ""

DbSelectArea("ABS")
ABS->( DbSetOrder(1) )	//ABS_FILIAL+ABS_LOCAL

If ABS->( DbSeek(xFilial("ABS") + cCodigoLoc ))

	If cTFJAgrupa == "2"
		cCodCli := ABS->ABS_CLIFAT
		cLojCli	 := ABS->ABS_LJFAT
		lCliOk := .T.
	ElseIf cTFJAgrupa == "1" .AND. ABS->ABS_ENTIDA == "1"
		cCodCli := ABS->ABS_CODIGO
		cLojCli	 := ABS->ABS_LOJA
		lCliOk := .T.
	ElseIf cTFJAgrupa == "1" .AND. ABS->ABS_ENTIDA == "2"
		If !Empty(Posicione("SUS",1,xFilial("SUS")+ABS->ABS_CODIGO,"US_CODCLI"))
			cCodCli := Posicione("SUS",1,xFilial("SUS")+ABS->ABS_CODIGO,"US_CODCLI")
			cLojCli	 := Posicione("SUS",1,xFilial("SUS")+ABS->ABS_CODIGO,"US_LOJACLI")
			lCliOk := .T.
		Else
			lCliOk := .F.
			Help(,,'AT850LOCXCLI',, STR0110,3,0)//"Não será possível realizar a Geração do Contrato porque o Local de Atendimento do Orçamento de Serviços da Proposta Comercial não pode estar relacionado a um Prospect que ainda não seja um Cliente!"
		EndIf
	EndIf
EndIf

Return lCliOk

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} GetPrdCTR

Faz a carga dos produtos quando o parametro MV_GSDSGCN está como 1-SIM
@author Filipe Gonçalves
@since 27/12/2016
@version P12
@param cCodPai:Código Pai do orçamento
@param cLocal:Local de Atendimento
@return  aProds:Array com os produtos para criação dos itens da planilha 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function GetPrdCTR(cCodPai, cLocal, cOrc, lGesMatMi, lGesMatMc)
Local cAliasRH	:= GetNextAlias()
Local cAliasMC	:= GetNextAlias()
Local cAliasMI	:= GetNextAlias()
Local cAliasLE	:= GetNextAlias()
Local aProds	:= {}
Local lOrcPrc := SuperGetMv("MV_ORCPRC",,.F.)
Local aArea 	:= GetArea()
Local aAreaTFJ 	:= TFJ->(GetArea())
Local aAreaTFF 	:= TFF->(GetArea())
Local aAreaTFG 	:= TFG->(GetArea())
Local aAreaTFH 	:= TFH->(GetArea())
Local aAreaTFI 	:= TFI->(GetArea())
Local nValor	:= 0

Default lGesMatMi := .F.
Default lGesMatMc := .F.

If cOrc == "RH"
	BeginSql Alias cAliasRH
		SELECT TFF_PRODUT,TFF_QTDVEN,TFF_PRCVEN,TFF.R_E_C_N_O_, TFF_TESPED, TFF_PDMTMI, TFF_VLMTMI, TFF_PDMTMC, TFF_VLMTMC, TFF_TXLUCR, TFF_TXADM
		FROM %Table:TFF% TFF
		WHERE TFF.TFF_FILIAL = %xfilial:TFF% 
			AND TFF.%NotDel%
		  	AND TFF.TFF_CODPAI = %exp:cCodPai%
	EndSql
	
	While (cAliasRH)->(!EOF())
	  nValor := (cAliasRH)->TFF_PRCVEN + (cAliasRH)->TFF_TXLUCR + (cAliasRH)->TFF_TXADM
	  aAdd(aProds,{(cAliasRH)->TFF_PRODUT,(cAliasRH)->TFF_QTDVEN,nValor,(cAliasRH)->R_E_C_N_O_,(cAliasRH)->TFF_TESPED , "1","" }) //Quando for Recursos Humanos.
	  	
	  If lGesMatMi .And. !Empty((cAliasRH)->TFF_PDMTMI)
		  aAdd(aProds,{(cAliasRH)->TFF_PDMTMI, 1,(cAliasRH)->TFF_VLMTMI,(cAliasRH)->R_E_C_N_O_,(cAliasRH)->TFF_TESPED, "2",(cAliasRH)->TFF_PRODUT }) //Quando for Material de Implantação por valor.
	  Endif

	  If lGesMatMc .And. !Empty((cAliasRH)->TFF_PDMTMC)
		  aAdd(aProds,{(cAliasRH)->TFF_PDMTMC, 1,(cAliasRH)->TFF_VLMTMC,(cAliasRH)->R_E_C_N_O_,(cAliasRH)->TFF_TESPED, "3",(cAliasRH)->TFF_PRODUT }) //Quando for Material de cosumo por valor.		  
	  Endif
	
	  (cAliasRH)->(dbSkip())
	EndDo

	(cAliasRH)->(DbCloseArea())
EndIf

If lOrcPrc
	If cOrc == "MI"
		BeginSql Alias cAliasMI
			SELECT TFG_PRODUT,TFG_QTDVEN,TFG_PRCVEN,TFG.R_E_C_N_O_, TFG_TESPED, TFG_TXLUCR, TFG_TXADM
			FROM %Table:TFG% TFG
			WHERE TFG.TFG_FILIAL = %xfilial:TFG% 			
				AND TFG.%NotDel%
		  		AND TFG.TFG_CODPAI = %exp:cCodPai%
		EndSql
		
		While (cAliasMI)->(!EOF())
			 nValor := (cAliasMI)->TFG_PRCVEN + (cAliasMI)->TFG_TXLUCR + (cAliasMI)->TFG_TXADM
			aAdd(aProds,{(cAliasMI)->TFG_PRODUT,(cAliasMI)->TFG_QTDVEN,nValor,(cAliasMI)->R_E_C_N_O_, (cAliasMI)->TFG_TESPED, "", ""})
			(cAliasMI)->(dbSkip())
		EndDo
		(cAliasMI)->(DbCloseArea())
	ElseIf cOrc == "MC"
		BeginSql Alias cAliasMC
			SELECT TFH_PRODUT,TFH_QTDVEN,TFH_PRCVEN,TFH.R_E_C_N_O_, TFH_TESPED, TFH_TXLUCR, TFH_TXADM 
			FROM %Table:TFH% TFH
			WHERE TFH.TFH_FILIAL = %xfilial:TFH% 
				AND TFH.%NotDel%
			  	AND TFH.TFH_CODPAI = %exp:cCodPai%
		EndSql
		
		While (cAliasMC)->(!EOF())
		 	nValor := (cAliasMC)->TFH_PRCVEN + (cAliasMC)->TFH_TXLUCR + (cAliasMC)->TFH_TXADM 
			aAdd(aProds,{(cAliasMC)->TFH_PRODUT,(cAliasMC)->TFH_QTDVEN,nValor,(cAliasMC)->R_E_C_N_O_, (cAliasMC)->TFH_TESPED, "", ""})
			(cAliasMC)->(dbSkip())
		EndDo
		(cAliasMC)->(DbCloseArea())
	EndIf
Else
	If cOrc == "MI"
		BeginSql Alias cAliasMI
			SELECT TFG_PRODUT,TFG_QTDVEN,TFG_PRCVEN,TFG.R_E_C_N_O_, TFG_TESPED, TFG_TXLUCR, TFG_TXADM, TFF_PRODUT
			FROM %Table:TFG% TFG
			INNER JOIN %Table:TFF% TFF ON TFF.TFF_FILIAL = %xfilial:TFF% AND TFG.TFG_CODPAI = TFF.TFF_COD
			WHERE TFG.TFG_FILIAL = %xfilial:TFG% 
				AND TFF.%NotDel% 
				AND TFG.%NotDel%
		  		AND TFF.TFF_CODPAI = %exp:cCodPai%
		EndSql
		
		While (cAliasMI)->(!EOF())
			nValor := (cAliasMI)->TFG_PRCVEN + (cAliasMI)->TFG_TXLUCR + (cAliasMI)->TFG_TXADM
			aAdd(aProds,{(cAliasMI)->TFG_PRODUT,(cAliasMI)->TFG_QTDVEN,nValor,(cAliasMI)->R_E_C_N_O_,(cAliasMI)->TFG_TESPED,"",(cAliasMI)->TFF_PRODUT})
			(cAliasMI)->(dbSkip())
		EndDo
		(cAliasMI)->(DbCloseArea())
	ElseIf cOrc == "MC"
		BeginSql Alias cAliasMC
			SELECT TFH_PRODUT,TFH_QTDVEN,TFH_PRCVEN,TFH.R_E_C_N_O_, TFH_TESPED, TFH_TXLUCR, TFH_TXADM, TFF_PRODUT 
			FROM %Table:TFH% TFH
			INNER JOIN %Table:TFF% TFF ON TFF.TFF_FILIAL = %xfilial:TFF% AND TFH.TFH_CODPAI = TFF.TFF_COD 
			WHERE TFH.TFH_FILIAL = %xfilial:TFH%		 
				AND TFH.%NotDel%
			  	AND TFF.%NotDel% 			
		  		AND TFF.TFF_CODPAI = %exp:cCodPai%
		EndSql
		
		While (cAliasMC)->(!EOF())
			nValor := (cAliasMC)->TFH_PRCVEN + (cAliasMC)->TFH_TXLUCR + (cAliasMC)->TFH_TXADM
			aAdd(aProds,{(cAliasMC)->TFH_PRODUT,(cAliasMC)->TFH_QTDVEN,nValor,(cAliasMC)->R_E_C_N_O_, (cAliasMC)->TFH_TESPED, "",(cAliasMC)->TFF_PRODUT})
			(cAliasMC)->(dbSkip())
		EndDo
		(cAliasMC)->(DbCloseArea())
	EndIf
EndIf	

If cOrc == "LE"
	BeginSql Alias cAliasLE
		SELECT TFI_PRODUT,TFI_QTDVEN,TFI_TOTAL / TFI_QTDVEN  TFI_PRCUN,TFI.R_E_C_N_O_, TFI_TESPED
		FROM %Table:TFI% TFI 
		WHERE TFI.TFI_FILIAL = %xfilial:TFI% 
			AND TFI.%NotDel%
			AND TFI.TFI_CODPAI = %exp:cCodPai%
	EndSql
	
	While (cAliasLE)->(!EOF())
	  aAdd(aProds,{(cAliasLE)->TFI_PRODUT,(cAliasLE)->TFI_QTDVEN,(cAliasLE)->TFI_PRCUN,(cAliasLE)->R_E_C_N_O_, (cAliasLE)->TFI_TESPED,"","",})
	  (cAliasLE)->(dbSkip())
	EndDo
	(cAliasLE)->(DbCloseArea())
EndIf

RestArea(aAreaTFI)
RestArea(aAreaTFH)
RestArea(aAreaTFG)
RestArea(aAreaTFF)
RestArea(aAreaTFJ)
RestArea(aArea)

Return aProds

/*/{Protheus.doc} At850Cn301
@description 	Confirma se o usuário realmente deseja abortar a operação de geração do contrato
@since 			03.01.2017
@version 		12
@param 			oModel, Objeto FwFormModel/MpFormModel, objeto geral do contrato CNTA301
@return 		Lógico, define se deve fechar e continuar com o cancelamento ou voltar para a interface do contrato
/*/
Static Function At850Cn301(oModel, lVigente)
Local lCancela := .F.

lCancela := MsgNoYes( STR0152, STR0153 )  // "Deseja realmente desistir da geração do contrato?" ###  "Confirma operação?"

Return lCancela

/*/{Protheus.doc} At850Ok301
@description 	Confirma se o usuário realmente deseja continuar com o processo de geração do contrato
@since 			03.01.2017
@version 		12
@param 			oModel, Objeto FwFormModel/MpFormModel, objeto geral do contrato CNTA301
@return 		Lógico, define se deve fechar e continuar com o cancelamento ou voltar para a interface do contrato
/*/
Static Function At850Ok301(oModel, lVigente)
Local lContinua 	:= .F.

If lVigente
	lContinua := MsgNoYes( STR0154 + CRLF + ;  // "Caso os cronogramas não estejam definidos o processo será abortado."
			STR0155, STR0153 ) // "Deseja realmente prosseguir com a operação?" ### "Confirma operação?" 
Else
	lContinua := .T.
EndIf

Return lContinua


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} VldMsmCrng
Verificar se os locais do orçamento possuem a mesma vigência, caso não, não permite habilitar mesmo cronograma para estes
@author Heimdall.Castro
@since 17/02/2012
@version P12
@param cCntrt - Numero do Contrato
@return  Logico 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function VldMsmCrng(cPropos)  

Local aArea   := GetArea()
Local lRetVld := .T.
Local cQryVld := ""
Local cAlQVld := GetNextAlias()
Local cDtIni  := ""
Local cDtFin  := ""

cQryVld := " SELECT TFL.TFL_CODIGO, TFL.TFL_DTINI, TFL.TFL_DTFIM " 
cQryVld += " FROM " + RetSqlName("TFL") + " TFL "
cQryVld += " JOIN " + RetSqlName("TFJ") + " TFJ ON TFJ.TFJ_CODIGO = TFL.TFL_CODPAI AND TFJ.D_E_L_E_T_ != '*' AND TFJ.TFJ_FILIAL = '" + xFilial("TFL") + "' " 
cQryVld += " WHERE TFJ.TFJ_PROPOS = '" + cPropos        + "' "
cQryVld += "   AND TFL.TFL_FILIAL = '" + xFilial("TFL") + "' "
cQryVld += "   AND TFL.D_E_L_E_T_ != '*' "

cQryVld := ChangeQuery(cQryVld)

DbUseArea(.T., "TOPCONN",TcGenQry(,,cQryVld), cAlQVld, .T., .T.)

cDtIni := (cAlQVld)->TFL_DTINI
cDtFim := (cAlQVld)->TFL_DTFIM

While (!(cAlQVld)->(EOF()))

	If ((cDtIni != (cAlQVld)->TFL_DTINI) .OR. (cDtFim != (cAlQVld)->TFL_DTFIM))
		lRetVld := .F.		
	EndIf
	
	(cAlQVld)->(DBSkip())

EndDo

RestArea(aArea)

Return lRetVld

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850GrvFat
Gravação das configurações de faturamento
@author Pâmela Bernardo
@since 02/02/2018
@version P12
@param cProposta,  cRevisao
@return  Logico 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At850GrvFat(cOporProp, cProposta, cRevisao)  

	Local lRet 		:= .F.
	Local oModelT42	:= Nil
	Local cLog		:= ""
	Local aArea		:= GetArea()

	DbSelectArea("TFJ")
	DbSetOrder(2) // TFJ_FILIAL+ TFJ_PROPOS + TFJ_PREVIS
	
	DbSelectArea("T42")
	DbSetOrder(1) // T42_FILIAL+ T42_CODIGO
	
	If TFJ->( DbSeek(xFilial("TFJ") + cProposta + cRevisao) )
		If !(T42->( DbSeek(xFilial("T42") + TFJ->TFJ_CODIGO) ))
		
			oModelT42  := FWLoadModel("TECA931B")						
			oModelT42:SetOperation(MODEL_OPERATION_INSERT) //Inclusão
			oModelT42:Activate()
			
			
			oModelT42:SetValue( "T42MASTER", "T42_NROPOR", cOporProp )
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
		Else
			lRet := .T.
		EndIf
	
	EndIf
	RestArea(aArea)
Return lRet

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850CrTar
Analisa recurso humano informado no contrato, caso o mesmo possua risco (1-SIM) cria automaticamente uma tarefa de funcionário (TN5). 
A tarefa será criada com um sequencia automática e será considerado o campo LOCAL e FUNÇÃO informada no contrato.  
@param  cNrCont, Caracter, Número do contrato
@param  cRev1, Caracter, Revisão do contrato
@return Nenhum
@author Eduardo Gomes Júnior
@since 09/01/20178
/*/
//------------------------------------------------------------------------------------------	
Function At850CrTar(cNrCont,cRev1)

Local aArea		:= GetArea()
Local nCont		:= 1
Local cQueryTFF	:= GetNextAlias()
Local cQueryTN5	:= GetNextAlias()
Local cProxTN5	:= ""

BeginSql Alias cQueryTN5
	SELECT MAX(TN5_CODTAR) ULTTAREFA  	
	FROM %Table:TN5% TN5
	WHERE TN5.%NotDel%
EndSql

cProxTN5 := Soma1( (cQueryTN5)->ULTTAREFA )

BeginSql Alias cQueryTFF
	SELECT	TFF_FILIAL, TFF_COD, TFF_ITEM, TFF_PRODUT, TFF_LOCAL, TFF_FUNCAO  	
	FROM %Table:TFF% TFF
	WHERE 
	TFF.TFF_FILIAL			= %exp:xFilial('TFF')%
	AND TFF.TFF_CONTRT		= %exp:cNrCont%  
	AND TFF.TFF_CONREV		= %exp:cRev1%
	AND TFF.TFF_RISCO		= '1'
	AND TFF.%NotDel%
EndSql

TN5->(DbSetOrder(3))	
(cQueryTFF)->(dbGoTop())

While (cQueryTFF)->(!Eof())

	If	!TN5->(DbSeek(xFilial("TN5")+(cQueryTFF)->TFF_LOCAL+(cQueryTFF)->TFF_FUNCAO))
		RecLock("TN5",.T.)
		TN5_FILIAL 	:= xFilial("TN5")
		TN5_CODTAR 	:= cProxTN5
		TN5_NOMTAR 	:= (cQueryTFF)->TFF_LOCAL + " - " + (cQueryTFF)->TFF_FUNCAO
		TN5_LOCAL	:= (cQueryTFF)->TFF_LOCAL
		TN5_POSTO	:= (cQueryTFF)->TFF_FUNCAO
		TN5->(MsUnlock())	
	Endif 	

	cProxTN5 := Soma1( cProxTN5 )

	(cQueryTFF)->(dbSkip())
	
End

IF Select( cQueryTN5 ) > 0
	(cQueryTN5)->(dbCloseArea())
EndIf

IF Select( cQueryTFF ) > 0
	(cQueryTFF)->(dbCloseArea())
EndIf

RestArea(aArea)

Return

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At850TarEx
Analisa recurso humano informado na TFF para serviço extra, caso o mesmo possua risco (1-SIM) cria automaticamente uma tarefa de funcionário (TN5). 
A tarefa será criada com um sequencia automática e será considerado o campo LOCAL e FUNÇÃO informada no contrato.  

@param  cLocal, Caracter, Codigo do Local
@param  aTFF, Array, Array contendo a TFF de cada local

@return Nenhum
@author Luiz Gabriel
@since 14/03/2019
/*/
//------------------------------------------------------------------------------------------	
Function At850TarEx(cLocal,aItemRH)

Local aArea		:= GetArea()
Local nCont		:= 0
Local cQueryTN5	:= GetNextAlias()
Local cProxTN5	:= ""
Local cFil			:= ""

BeginSql Alias cQueryTN5
	SELECT MAX(TN5_CODTAR) ULTTAREFA  	
	FROM %Table:TN5% TN5
	WHERE TN5.%NotDel%
EndSql

cProxTN5 := Soma1( (cQueryTN5)->ULTTAREFA )

TN5->(DbSetOrder(3))
cFil	:= xFilial("TN5")

For nCont := 1 To Len(aItemRH)

	If	aItemRH[nCont][ITEMRH_RISCO] == "1" .And. !TN5->(DbSeek(xFilial("TN5") + cLocal + aItemRH[nCont][ITEMRH_FUNCAO]))
		RecLock("TN5",.T.)
		TN5_FILIAL 	:= cFil
		TN5_CODTAR 	:= cProxTN5
		TN5_NOMTAR 	:= cLocal + " - " + aItemRH[nCont][ITEMRH_FUNCAO]
		TN5_LOCAL		:= cLocal
		TN5_POSTO		:= aItemRH[nCont][ITEMRH_FUNCAO]
		TN5->(MsUnlock())	
	Endif 	

	cProxTN5 := Soma1( cProxTN5 )

Next nCont

IF Select( cQueryTN5 ) > 0
	(cQueryTN5)->(dbCloseArea())
EndIf

RestArea(aArea)

Return