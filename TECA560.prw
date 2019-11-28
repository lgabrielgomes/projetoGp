#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWBROWSE.CH"
#INCLUDE "TECA560.CH"
//------------------------------------------------------------------------------
/*/{Protheus.doc} TECA560
Substituicao de atendentes atraves da manutencao da agenda.

@sample 	TECA560(aCarga,cCodAtdSub)

@param		aCarga		Carga com os periodos de substituicao.  
			cCodAtdSub	Codigo do atendente substituto (@Referencia).
			cOrigem	Origem do contrato  		
			aCargaRes	Carga com os periodos para equipe de reservas
			
@return		ExpL	Verdadeiro / Falso

@author		Anderson Silva
@since		24/01/2013
@version	P12
/*/
//------------------------------------------------------------------------------
Function TECA560(aCarga,cCodAtdSub, cOrigem, aCargaRes, cTFF_COD, cFilCob)

Local lRetorno 		:= .T.                                                                                             	// Retorno da validacao.
Local aArea			:= GetArea()		 																				// Guarda a area atual.
Local aAreaAAH		:= AAH->(GetArea()) 																				// Guarda a area da tabela AAH.
Local aAreaAA1		:= AA1->(GetArea()) 																				// Guarda a area da tabela AA1.
Local aAreaCN9		:= CN9->(GetArea())
Local oDlg 			:= Nil   												   		   									// Janela Principal.
Local aSize	 		:= FWGetDialogSize( oMainWnd ) 																		// Array com tamanho da janela.
Local oFWLayer		:= Nil															   									// Objeto FwLayer.
Local oDlgDetFil		:= Nil																								// Janela Detalhes do Atendente | Filtro.
Local oTreeDtFil		:= Nil															   									// Tree Detalhes do Atendente | Filtro.
Local lTecXRh 		:= SuperGetMv("MV_TECXRH",,.F.)	 																// Integracao Gestao de Servicos com RH?.
Local oMnuDtFil		:= Nil															  	   								// Objeto menu popup.
Local oMnuItDFil		:= {}															   									// Itens do menu popup.
Local oDlgAllAtd	 	:= Nil   														   									// Janela dos atendentes Gestao de Servicos.
Local oPnlParams	 	:= Nil	                                                            								// Panel com os parametros de alocacao.
Local oTBParmsOk	 	:= Nil   																							// Botao OK utilizado para buscar os atendente de acordo com os parametros.
Local oPnlBrwA1		:= Nil              																				// Panel com o browse atendentes Gestao de Servicos.
Local oRadio			:= Nil																								// Objeto TRadMenu.
Local nRadio			:= 1 																								// Opcao selecionada ( Default "Todos os Atendentes" )
Local oMrkAllAtd		:= Nil															   									// Objeto FwFormBrowse atendentes Gestao de Servicos.
Local aMrkAllAtd		:= {}															  									// Array atendentes alocado.
Local aPeriodos		:= {}  
Local aPerRes			:= {}                                                                                           	// Periodo para buscar os atendentes disponivel para alocacao.
Local nX				:= 0																								// Incremento utilizado no For.
Local cCodAtend		:= {}																								// Codigo do atendente.
Local cNrContrat		:= ""                                                                                               // Numero do contrato.
Local lPermFiltr		:= SuperGetMv("MV_TECPRMF",,.T.)
Local cLocalAloc		:= ""
Local cFilAtd           := ""

Default aCarga		:= {}																								// Informacoes do agendamentos selecionado pelo usuario.
Default cCodAtdSub	:= "" 																								
Default cOrigem := ""																									//Origem do contrato		
Default aCargaRes		:= {}																								// Informacoes considerando a manutenção para a equipe de reservas.																					
Default cTFF_COD	:= ""
Default cFilCob     := ""

If !Empty(cFilCob)
	cFilAtd := cFilCob
Else
	cFilAtd := cFilAnt
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Salva status das variaveis private e public.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
SaveInter()

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Limpa a variavel aRotina para nao carregar nos browses.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
aRotina	:= {}

cLocalAloc := Posicione("TFF",1,xFilial("TFF")+cTFF_COD,"TFF_LOCAL")

If Len(aCarga) > 0
	
	cCodAtend	:= aCarga[1][1]
	cNrContrat	:= aCarga[1][2]
	
	For nX := 1 To Len(aCarga)
		aAdd(aPeriodos,{sTod(aCarga[nX][4]),aCarga[nX][5],sTod(aCarga[nX][6]),aCarga[nX][7]})
	Next nX
	
	If Len(aCargaRes) > 0
		For nX := 1 To Len(aCargaRes)		
			aAdd(aPerRes,{aCargaRes[nX][4],aCargaRes[nX][5],aCargaRes[nX][6],aCargaRes[nX][7]})		
		Next nX
	EndIf

Else
	lRetorno := .F.
	MsgStop(STR0026,STR0017)    // "Problemas para carregar os agendamentos que será utilizado na substituição."#"Atenção"
EndIf

If lRetorno
	// Chamado para seleção do atendente TECA580E
	IF ! Empty(cCodAtend)
		If Empty(cOrigem)
			DbSelectArea("AAH")
			DbSetOrder(1)
  		
			If !DbSeek(xFilial("AAH")+cNrContrat)
				lRetorno := .F.
				MsgStop(STR0027,STR0017)   // "Problemas para localizar o contrato."
			EndIf
		Else
			If cOrigem == "CN9"
			DbSelectArea("CN9")
			DbSetOrder(1)
  		
			If !DbSeek(xFilial("CN9")+cNrContrat)
				lRetorno := .F.
				MsgStop(STR0027,STR0017)   // "Problemas para localizar o contrato."
			EndIf
			ElseIf cOrigem == "TFJ"
  				DbSelectArea("TFJ")
				DbSetOrder(1)
  		
				If !DbSeek(xFilial("TFJ")+cNrContrat)
					lRetorno := .F.
					MsgStop(STR0040,STR0017)   // "Problemas para localizar orçamento de serviço extra!"
				EndIf
  			EndIf
		EndIf
	ENDIF
EndIf

IF ! Empty(cCodAtend)
	If lRetorno
		DbSelectArea("AA1")
		DbSetOrder(1)
		
		If !lRetorno .AND. !DbSeek(xFilial("AA1",cFilAtd)+cCodAtend)
			lRetorno := .F.
			MsgStop(STR0016,STR0017)    // "Atendente que será substituido não foi localizado."#"Atenção"
		EndIf
	EndIf
ENDIF

If lRetorno
	
	DEFINE DIALOG oDlg TITLE IIF(! Empty(cCodAtend),STR0001,STR0032) FROM aSize[1],aSize[2] TO aSize[3],aSize[4] PIXEL	// "Substituição de Atendentes" ## "Seleção de Atendentes"
	
	oFWLayer := FWLayer():New()
	oFWLayer:Init(oDlg,.F.)
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Janela Detalhes do Atendente | Filtro. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oFWLayer:AddLine("LINETOP",48,.F.)
	oFWLayer:AddCollumn("DETFIL",100,.F.,"LINETOP")
	oFWLayer:AddWindow("DETFIL","oDlgDetFil",STR0002,100,.F.,.F.,,"LINETOP",{||})  // "Detalhes do Atendente | Filtro"
	oDlgDetFil	:= oFWLayer:GetWinPanel("DETFIL","oDlgDetFil","LINETOP")
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Inicializa Tree Detalhes do Atendente | Filtro. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oTreeDtFil := At330MTree(oDlgDetFil,lTecXRh,.T.)
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Define o filtro padrao. Obs. O filtro padrao sera a mesma caracteristicas do atendente que sera substituido. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	At560FilPd(oTreeDtFil,lTecXRh,cCodAtend,cTFF_COD)
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Cria o Menu POP-UP  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	MENU oMnuDtFil POPUP OF oTreeDtFil
	aAdd(oMnuItDFil,MenuAddItem(STR0003,,,.T.,,,,oMnuDtFil,{|| At330AddIt(oTreeDtFil,lTecXRh) },,,,,{ || .T. } ))      		// "Adicionar"
	aAdd(oMnuItDFil,MenuAddItem(STR0004,,,.T.,,,,oMnuDtFil,{|| At330RemIt(oTreeDtFil,lTecXRh) },,,,,{ || .T. } ))      		// "Remover"
	aAdd(oMnuItDFil,MenuAddItem(STR0005,,,.T.,,,,oMnuDtFil,{|| At330ClrPt(oTreeDtFil) },,,,,{ || .T. }))      				// "Limpar Pasta"
	aAdd(oMnuItDFil,MenuAddItem(STR0006,,,.T.,,,,oMnuDtFil,{|| IIF(lPermFiltr,At330ClrFl(oTreeDtFil,lTecXRh,.T.),MsgAlert(STR0028)) },,,,,{ || .T. }))      	// "Limpar Filtro"#"Usuário não tem permissão para limpar o filtro"
	aAdd(oMnuItDFil,MenuAddItem(STR0007,,,.T.,,,,oMnuDtFil,{|| IIF(lPermFiltr,At330RFilt(oTreeDtFil,lTecXRh,cCodAtend,cTFF_COD),MsgAlert(STR0029))  },,,,,{ || .T. }))	// "Restaurar Filtro"#"Usuário não tem permissão para restaurar o filtro"
	aAdd(oMnuItDFil,MenuAddItem(STR0008,,,.T.,,,,oMnuDtFil,{|| MsgRun(STR0014,STR0015,{|| At330ClrDt(oTreeDtFil),;
	ApagarTemp(oMrkAllAtd:Alias()),aMrkAllAtd := ListarApoio(/*dAlocDe*/,/*dAlocAte*/,At330GTree(oTreeDtFil,"FILCAR"),;
	At330GTree(oTreeDtFil,"FILFUN"),At330GTree(oTreeDtFil,"FILHAB"),/*cDisponib*/,/*cContIni*/,/*cContFim*/,AAH->AAH_CCUSTO,;
	cValToChar(nRadio),/*nLegenda*/,/*cItemOS*/,At330GTree(oTreeDtFil,"FILTUR"),At330GTree(oTreeDtFil,"FILREG"),;
	/*lEstrut*/,aPeriodos, /*cIdCfAbq*/,/* cLocOrc*/, At330GTree(oTreeDtFil,"FILSEQ"), aPerRes,;
	cLocalAloc,At330GTree(oTreeDtFil,"FILCRC"),At330GTree(oTreeDtFil,"FILCUR"),cFilAtd),At330AtBrw(oMrkAllAtd,aMrkAllAtd[1])})},,,,,{ || .T. }))											// "Executar Filtrar"
	ENDMENU
	
	oTreeDtFil:bRClicked := {|oTreeDtFil,x,y| oMnuDtFil:Activate(x-40,y-160,oTreeDtFil) } // Posição x,y em relação a Dialog
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Janela Atendentes do Gestao de Servicos. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oFWLayer:AddLine("LINEBOTTOM",49,.F.)
	oFWLayer:AddCollumn("ALLATEND",80,.T.,"LINEBOTTOM")
	oDlgAllAtd := oFWLayer:GetColPanel("ALLATEND","LINEBOTTOM")
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Browse Atendentes do Gestao de Servicos. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aMrkAllAtd := ListarApoio(/*dAlocDe*/,/*dAlocAte*/,At330GTree(oTreeDtFil,"FILCAR"),At330GTree(oTreeDtFil,"FILFUN"),;
	At330GTree(oTreeDtFil,"FILHAB"),/*cDisponib*/,/*cContIni*/,/*cContFim*/,AAH->AAH_CCUSTO,cValToChar(nRadio),;
	/*nLegenda*/,/*cItemOS*/,At330GTree(oTreeDtFil,"FILTUR"),At330GTree(oTreeDtFil,"FILREG"),/*lEstrut*/,aPeriodos, /*cIdCfAbq*/,/* cLocOrc*/, At330GTree(oTreeDtFil,"FILSEQ"), aPerRes,;
	cLocalAloc,At330GTree(oTreeDtFil,"FILCRC"),At330GTree(oTreeDtFil,"FILCUR"),cFilAtd)
	
	
	At560BrwAtd(oDlgAllAtd,@oMrkAllAtd,aMrkAllAtd,lTecXRh, aPeriodos)
	
	oMrkAllAtd:SetChange({|| At330TStDt(oTreeDtFil,(oMrkAllAtd:Alias())->TMP_CODTEC,aMrkAllAtd[4],aMrkAllAtd[5],lTecXRh,aMrkAllAtd[6],aMrkAllAtd[7])})
	
	At330AtBrw(oMrkAllAtd,aMrkAllAtd[1])
	
	oDlgRdoLoc := Nil
	oFWLayer:AddCollumn("RDOLOC",20,.T.,"LINEBOTTOM")
	oFWLayer:AddWindow("RDOLOC","oDlgRdoLoc",STR0009,100,.F.,.F.,,"LINEBOTTOM",{||})  // "Localizar por:"
	oDlgRdoLoc := oFWLayer:GetWinPanel("RDOLOC","oDlgRdoLoc","LINEBOTTOM")
	
	//Opcoes: "Banco de Apoio","Reserva Técnica","Todos Atendentes"
	@ 000,000 RADIO oRadio VAR nRadio ITEMS STR0010,STR0011,STR0013 OF oDlgRdoLoc;
	ON CHANGE {|| MsgRun(STR0014,STR0015,{|| At330ClrDt(oTreeDtFil),ApagarTemp(oMrkAllAtd:Alias()),aMrkAllAtd := ListarApoio(/*dAlocDe*/,/*dAlocAte*/,;
	At330GTree(oTreeDtFil,"FILCAR"),At330GTree(oTreeDtFil,"FILFUN"),At330GTree(oTreeDtFil,"FILHAB"),/*cDisponib*/,/*cContIni*/,/*cContFim*/,AAH->AAH_CCUSTO,;
	cValToChar(nRadio),/*nLegenda*/,/*cItemOS*/,At330GTree(oTreeDtFil,"FILTUR"),At330GTree(oTreeDtFil,"FILREG"),/*lEstrut*/,aPeriodos, /*cIdCfAbq*/,/* cLocOrc*/, At330GTree(oTreeDtFil,"FILSEQ"), aPerRes,;
	cLocalAloc,At330GTree(oTreeDtFil,"FILCRC"),At330GTree(oTreeDtFil,"FILCUR"),cFilAtd),At330AtBrw(oMrkAllAtd,aMrkAllAtd[1])})}  SIZE 110,10 PIXEL  // "Localizando os atendentes..."#"Aguarde"
	
	ACTIVATE DIALOG oDlg ON INIT (EnchoiceBar(oDlg,{|| IIF(At560VldSub(oMrkAllAtd,cCodAtend),( cCodAtdSub := AllTrim((oMrkAllAtd:Alias())->TMP_CODTEC),lRetorno := .T., oDlg:End() ),(cCodAtdSub := "",lRetorno := .F.) ) },{|| lRetorno := .F.,oDlg:End()}),lRetorno := .F. ) CENTERED
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Apaga a tabela temporaria. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	ApagarTemp(aMrkAllAtd[1])
	
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Restaura o status das variaveis private e public.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
RestInter()

RestArea(aArea)
RestArea(aAreaAAH)
RestArea(aAreaAA1)

Return( lRetorno )


//------------------------------------------------------------------------------
/*/{Protheus.doc} At560BrwAtd
Browse atendentes do Gestao de Servicos.

@sample 	At560BrwAtd(oDlgAllAtd,oMrkAllAtd,aMrkAllAtd,lTecXRh)

@param		ExpO1	Objeto Panel atendentes.
			ExpO2 	Objeto FwMarkBrowse atendentes.
			ExpA3 	Array com as informacoes para popular o browse.
			ExpL4	Integracao Gestao de Servicos com RH?
			ExpA5	Array com periodos a serem considerados

@return		ExpL 	Verdadeiro

@author		Anderson Silva
@since		30/10/2012
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function At560BrwAtd(oDlgAllAtd,oMrkAllAtd,aMrkAllAtd,lTecXRh, aPeriodos)

Local lRetorno	:= .T.					// Retorno da rotina.
Local aSeek		:= {}					// Array com a chaves para busca.
Local aIndex	:= {}					// Array com indice.
Local cAliasTmp	:= aMrkAllAtd[1]		// Alias temporario.
Local cAliasIdx	:= aMrkAllAtd[2] 		// Index temporario.
Local aColumns	:= aMrkAllAtd[3]		// Colunas que serao exibidas no browse.


If !lTecXRh
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Remove os campos TMP_CARGO / TMP_SITFOL / TMP_DESC . ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	ADel(aColumns,8)
	ADel(aColumns,11)
	ADel(aColumns,12)
	ASize(aColumns,Len(aColumns)-3)
EndIf

DbSelectArea(cAliasTmp)
(cAliasTmp)->( DbGoTop() )

aAdd(aSeek,{TxDadosCpo("AA1_CODTEC")[1],{{"","C",TamSX3("AA1_CODTEC")[1],TamSX3("AA1_CODTEC")[2],;
TxDadosCpo("AA1_CODTEC")[1],PesqPict("AA1","AA1_CODTEC")}} } )

oMrkAllAtd := FWFormBrowse():New()
oMrkAllAtd:SetOwner(oDlgAllAtd)
oMrkAllAtd:SetDataQuery(.F.)
oMrkAllAtd:SetDataTable(.T.)
oMrkAllAtd:SetAlias(cAliasTmp)
oMrkAllAtd:SetSeek(,aSeek)
oMrkAllAtd:SetTemporary()
oMrkAllAtd:SetDescription(STR0018)  // "Atendentes"
oMrkAllAtd:SetMenuDef("")
oMrkAllAtd:DisableDetails()
oMrkAllAtd:AddButton(STR0019,{|| At330VsAtd((oMrkAllAtd:Alias())->TMP_CODTEC)},,,,.F.,1) 	// "Visualizar Atendente"

//-----------------------------------------------------------
//  Não permite a exibição da grade de alocação
// quando ela já está na pilha de chamadas.
If !IsInCallStack('TECA510')
	oMrkAllAtd:AddButton(STR0020,{|| At330CAloc((oMrkAllAtd:Alias())->TMP_CODTEC)},,,,.F.,1) 	// "Controle de Alocação"
EndIf

If lTecXRh 
	oMrkAllAtd:AddButton(STR0031,{|| At570Detal((oMrkAllAtd:Alias())->TMP_CODTEC, aPeriodos)},,,,.F.,1) 	// "Detalhes no RH"
EndIf
oMrkAllAtd:AddButton(STR0021,{|| At330LMkA1() },,,,.F.,2)                      		  	// "Legenda"

oMrkAllAtd:SetColumns(aColumns)
oMrkAllAtd:Activate()

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At560VldSub
Valida se o atendente selecionado podera substituir o atendente selecionado na
manutencao da agenda.

@sample 	At560VldSub(oMrkAllAtd,cCodAtend)

@param		ExpO1 	Objeto FwFormBrowse atendentes.
			ExpC2	Codigo do atendente.

@return		ExpL	Verdadeiro / Falso

@author		Anderson Silva
@since		24/01/2013
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function At560VldSub(oMrkAllAtd,cCodAtend)

Local lRetorno 	:= .T.		// Retorno da rotina.
Local cSim		:= STR0025	// Disponibilidade do atendente.
Local lTecXRh	:= SuperGetMV( 'MV_TECXRH',, .F. )	//Indica se há integração com o RH

If !Empty((oMrkAllAtd:Alias())->TMP_CODTEC)
	If (oMrkAllAtd:Alias())->TMP_CODTEC <> cCodAtend
		If (oMrkAllAtd:Alias())->TMP_FILIAL <> xFilial("AA1")
			lRetorno := .F.
			Help("",1,"At560FilSub",, STR0039,2,0) // "Filial do atendente substituto precisa ser da mesma filial do contrato."
		ElseIf lTecXRh .AND. (oMrkAllAtd:Alias())->(FieldPos("TMP_DISPRH")) > 0 .AND. !AllTrim((oMrkAllAtd:Alias())->TMP_DISPRH) == AllTrim(cSim)
			lRetorno := .F.
			Help("",1,"At560VldSub",,STR0030,2,0) //"Atendente possui bloqueio no RH."
		ElseIf !AllTrim((oMrkAllAtd:Alias())->TMP_DISP) == AllTrim(cSim)
			lRetorno := .F.
			MsgStop(STR0022,STR0017)	// "Atendente não disponível para substituição."#"Atenção"
		Elseif  ((oMrkAllAtd:Alias())->TMP_LEGEN == ("BR_LARANJA     "))
			If MsgYesNo(STR0036,STR0037) //"Atendente com restrição operacional de aviso."##"Deseja Continuar?" 
				lRetorno := .T.
			Else
				lRetorno := .F.
			Endif
		Elseif ((oMrkAllAtd:Alias())->TMP_LEGEN == ("BR_PRETO       "))
			Help("",1,"At560VldSub",,STR0038,2,0) //"Atendente com restrição operacional para o local/cliente"	
			lRetorno := .F.
		EndIf
	Else
		lRetorno := .F.
		MsgStop(STR0023,STR0017)		// "Não será possível substituir o mesmo atendente."#"Atenção"
	EndIf
Else
	lRetorno := .F.
	MsgStop(STR0024,STR0017)      		// "Selecione um atendente para substituição."#"Atenção"  //mecher o str
EndIf

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330RFilt
Restaura o filtro padrao.

@sample 	At330RFilt(oTreeDtFil,lTecXRh,cCodAtend)

@param		ExpO1	Objeto DBTree Detalhes do Atendente / Filtro.
			ExpL2	Integracao Gestao de Servicos com RH?
			ExpC3	Codigo do atendente.

@return		ExpL	Verdadeiro

@author		Anderson Silva
@since		30/01/2012
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function At330RFilt(oTreeDtFil,lTecXRh,cCodAtend,cTFF_COD)

Local lRetorno := .T. 	// Retorno da rotina.

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Limpa o filtro atual. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
At330ClrFl(oTreeDtFil,lTecXRh,.T.)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Define o filtro padrao. Obs. O filtro padrao sera a mesma caracteristicas do atendente que sera substituido. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
At560FilPd(oTreeDtFil,lTecXRh,cCodAtend,cTFF_COD)

Return( lRetorno )

//-----------------------------------------------------------------------------------
/*/{Protheus.doc} At560FilPd
Define o filtro padrao.
Obs. O filtro padrao sera a mesma caracteristicas do atendente que sera substituido.

@sample 	At560FilPd(oTreeDtFil,lTecXRh,cCodAtend)

@param		ExpO1	Objeto DBTree Detalhes do Atendente / Filtro.
			ExpL2	Integracao Gestao de Servicos com RH?
			ExpC3	Codigo do atendente.

@return		ExpL	Verdadeiro

@author		Anderson Silva
@since		30/01/2012
@version	P12
/*/
//-----------------------------------------------------------------------------------
Static Function At560FilPd(oTreeDtFil,lTecXRh,cCodAtend,cTFF_COD)

Local lRetorno		:= .T.					// Retorno da rotina.
Local aHabilAtd		:= {}  					// Habilidade do atendente.
Local aRegAtend		:= {} 					// Regiao de atendimento.
Local nX			:= 0  					// Incremento utilizando no For.
Local aAreaSRA		:= SRA->(GetArea())  	// Guarda a area da tabela SRA.

IF ! Empty(cCodAtend)

	aHabilAtd := TxAHabil(cCodAtend)
	
	If Len(aHabilAtd) > 0 
		For nX := 2 To Len(aHabilAtd[1])
			At330VAddH(oTreeDtFil,aHabilAtd[1][nX][1],aHabilAtd[1][nX][4],aHabilAtd[1][nX][6],aHabilAtd[1][nX][3],lTecXRh)
		Next nX
	EndIf
	
	aRegAtend := TxARegiao(cCodAtend)
	
	If Len(aRegAtend) > 0
		For nX := 2 To Len(aRegAtend[1])
			At330VAddR(oTreeDtFil,aRegAtend[1][nX][1])
		Next nX
	EndIf
	
	If lTecXRh .AND. !Empty(AA1->AA1_CDFUNC)
		DbSelectArea("SRA")
		DbSetOrder(1)
		If DbSeek(xFilial("SRA")+AA1->AA1_CDFUNC)
			At330VAddC(oTreeDtFil,SRA->RA_CARGO)
		EndIf
	EndIf
	
	If !Empty(AA1->AA1_FUNCAO)
		At330VAddF(oTreeDtFil,AA1->AA1_FUNCAO)
	EndIf
	
	If !Empty(AA1->AA1_TURNO)
		At330VAddT(oTreeDtFil,AA1->AA1_TURNO)
	EndIf
	    
	If !Empty(AAH->AAH_CCUSTO)
		At330VAdCc(oTreeDtFil,AAH->AAH_CCUSTO)
	EndIf
	
	If !Empty(AA1->AA1_SEQTUR)
		At330VAddS(oTreeDtFil,AA1->AA1_SEQTUR)
	EndIf
ELSE
	If lTecXRh
		// Habilidade
		IF !Empty(cTFF_COD)
			DbSelectArea("TDT")
			TDT->(DbSetOrder(2)) //TDT_FILIAL, TDT_CODTFF
			TDT->(DbSeek(xFilial("TDT")+cTFF_COD))
			DO WHILE TDT->(!Eof()) .AND. TDT->TDT_FILIAL = xFilial("TDT") .AND. TDT->TDT_CODTFF == cTFF_COD
				At330VAddH(oTreeDtFil,TDT->TDT_CODHAB,TDT->TDT_ESCALA,TDT->TDT_ITESCA,0,lTecXRh)
				TDT->(DbSkip())
			END
		ENDIF
		
		// Cursos do Local de Atendimento
		IF !Empty(cTFF_COD)
			DbSelectArea("TGV")
			TGV->(DbSetOrder(2)) //TGV_FILIAL, TGV_CODTFF
			TGV->(DbSeek(xFilial("TGV")+cTFF_COD))
			DO WHILE TGV->(!Eof()) .AND. TGV->TGV_FILIAL = xFilial("TGV") .AND. TGV->TGV_CODTFF == cTFF_COD
				At330VAdCU(oTreeDtFil,TGV->TGV_CURSO)
				TGV->(DbSkip())
			END
		ENDIF
	ELSE
		// Habilidade
		IF !Empty(cTFF_COD)
			DbSelectArea("TDT")
			TDT->(DbSetOrder(2)) //TDT_FILIAL, TDT_CODTFF
			TDT->(DbSeek(xFilial("TDT")+cTFF_COD))
			DO WHILE TDT->(!Eof()) .AND. TDT->TDT_FILIAL = xFilial("TDT") .AND. TDT->TDT_CODTFF == cTFF_COD
				At330VAddH(oTreeDtFil,TDT->TDT_HABX5,'','',0,lTecXRh)
				TDT->(DbSkip())
			END
		ENDIF	
	ENDIF

	// Caracteristica do Local de Atendimento
	IF !Empty(cTFF_COD)
		DbSelectArea("TDS")
		TDS->(DbSetOrder(2)) //TDS_FILIAL, TDS_CODTFF
		TDS->(DbSeek(xFilial("TDS")+cTFF_COD))
		DO WHILE TDS->(!Eof()) .AND. TDS->TDS_FILIAL = xFilial("TDS") .AND. TDS->TDS_CODTFF == cTFF_COD
			At330VAdCR(oTreeDtFil,TDS->TDS_CODTCZ)
			TDS->(DbSkip())
		END
	ENDIF	
ENDIF
RestArea(aAreaSRA)

Return( lRetorno )