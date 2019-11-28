#INCLUDE "CNTA130.ch"
#INCLUDE "Protheus.ch"
#INCLUDE "FWMVCDEF.CH"

//Situacoes de contrato
#DEFINE DEF_SCANC "01" //Cancelado
#DEFINE DEF_SELAB "02" //Em Elaboracao
#DEFINE DEF_SEMIT "03" //Emitido
#DEFINE DEF_SAPRO "04" //Em Aprovacao
#DEFINE DEF_SVIGE "05" //Vigente
#DEFINE DEF_SPARA "06" //Paralisado
#DEFINE DEF_SSPAR "07" //Sol Fina.
#DEFINE DEF_SFINA "08" //Finalizado
#DEFINE DEF_SREVS "09" //Revisao
#DEFINE DEF_SREVD "10" //Revisado
#DEFINE DEF_TRAVIS "035" //Visualizacao de Medicoes

STATIC lMedicao := IsInCallStack("TECA930") .or. IsInCallStack("TECA934") .or. IsInCallStack("TECA934A")

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN130Manut³ Autor ³ Marcelo Custodio      ³ Data ³09.02.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Manutencao de Medicoes                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN130Manut()                                               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 -> Alias do arquivo                                  ³±±
±±³          ³ ExpN1 -> Numero do registro                          	  ³±±
±±³          ³ ExpN2 -> Numero da opcao selecionada                       ³±±
±±³          ³ ExpX1 -> Campos do arquivo                                 ³±±
±±³          ³ ExpC2 -> Numero do contrato                            	  ³±±
±±³          ³ ExpC3 -> Numero da revisão                             	  ³±±
±±³          ³ ExpC4 -> Competencia                             		  ³±±
±±³          ³ ExpC5 -> Numero da Planilha                            	  ³±±
±±³          ³ ExpL1 -> .T. - Contrato com Medicao Eventual               ³±±
±±³          ³ ExpL2 -> .T. - Contrato com cronograma fisico              ³±±
±±³          ³ ExpC6 -> Parcela selecionada                           	  ³±±
±±³          ³ ExpN3 -> Numero do adiantamento                            ³±±
±±³          ³ ExpL3 -> .T. - Exibe Dialog                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³         ATUALIZACOES SOFRIDAS DESDE A CONSTRU€AO INICIAL.             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Programador ³ Data   ³ BOPS ³  Motivo da Alteracao                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³            ³        ³      ³                                          ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function CN130Manut(cAlias,nReg,nOpc,xParam,cContra,cRevisa,cCompet,cPlan,lMedeve,lFisico,cParcel,nTipo,lDialog,nServico,nSaveSX8)
Local aInfo
Local cFilCod
Local nA
Local nX
Local nPosCampo
Local nPosItem
Local nPosProd
Local nPosDescr
Local nPosVlUn
Local nPosPerc
Local nPosQMed
Local nPosQSol
Local nPosQtd
Local nPosPDesc
Local nPosDesc
Local nPosVlT
Local nPosNum
Local nPosItm
Local nPosVlDesc
Local nPosTpDesc
Local nPosTES
Local nPosQOri
Local nPosVOri
Local nPosCodNE
Local nPosItemNE
Local nPosArrend := 0
Local nPosCC
Local nPosConta
Local nPosItemCT
Local nPosCLVL
Local nPosPedTit
Local nOpca
Local nUsado     := 0
Local nValor     := 0

Local aCpoEnch  := {}
Local aNCpo     := {"CND_VLTOT","CND_VLPREV","CND_DTINIC","CND_VLMEAC","CND_VLSALD","CND_DATAIN","CND_DATAFI","CND_VLCONT","CND_VLADIT","CND_VLREAJ","CND_VLGER","CND_MEDRET","CND_RETIFI","CND_FLREAJ","CND_DESCME","CND_RETCAC","CND_TOTADT","CND_SITUAC","CND_VLLIQD","CND_VLMULT","CND_VLBONI","CND_ULTMED","CND_RECMED","CND_REVGER"}
Local aNalter   := {}
Local aAlter    := {}
Local cCadastro := STR0007//"Medição"
Local aCond     := {}
Local lRet      := .T.
Local aButtons  := {}
Local aDescs    := {}
Local aHeadDcs  := {}
Local aCTBEnt	  := CTBEntArr()
Local nPercCNF  := 0 //Percentual da parcela em relacao ao total da planilha
Local cFilCNP   := ""
Local lSugVal   := ((GetNewPar("MV_CNSUGME","1")=="1") .OR. lFisico)//Informa se sugere ou nao as quantidade da medicao
Local lRealMed  := (GetNewPar( "MV_CNREALM", "S" ) == "S")
Local lReajMed  := (GetNewPar( "MV_CNREAJM", "S" ) == "S")
Local lHabiExce := SuperGetMV("MV_CNBTEXC",.F.,"N") == "S" .And. Str(nOpc,1) $ '1*3*4' //-- 1: excedente med. encer
Local lContinua := .T.
Local nContaIt  := 0

Local oGetDesc
Local oGetPrev
Local oGetMultas
Local oGetBoni
Local oSize 		:= FwDefSize():New()
Local oDlg

Local lPreench
Local cAliasCNR := ""
Local cAliasCNF := ""

Local aMultParc := {}
Local aMultas   := {}

Local lCaucRet := .F.
Local lTesSB1  := .T.
Local lPosNE	:= .F.

Local aNoFields := {}

Local cSeek    := ""
Local cWhile   := ""

Local aRet     := {}
Local aUsButtons := {}
Local lCn130VRet := ExistBlock("CN130VRET")
Local nCn130VRet := 0
Local lCN130LBM  := ExistBlock("CN130LBM")
Local cCN130LBM  := ""

Local cAliasQry := ""
Local cQuery    := ""
Local cCodEd		:= ""

Local cParcela    := "123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0"
Local nParcelas   := SuperGetMv("MV_NUMPARC")
Local lNotaEmp	:= SuperGetMV("MV_NOTAEMP",.F.,.F.)
Local cNumPed     := ""
Local aRatGCT	:= {} //Array com os rateios dos itens do contrato
Local aColsCpos := {}
Local aHeadCpos	:= {}

Static aAdiants	:= {}
Static aColsAux	:= {}
Static oGetAdia
Local nArredMed:= 0
Local lCn130PrG := ExistBlock( "CN130PrG" )
Local cField	:= ""

Public aListBox   := {}
Public oList

Private lAuto := IIF(Type("lAuto") <> "L",.F.,lAuto)

aAdiants   := {}

If Type("cFilCTR") <> "C"
	cFilCtr := cFilAnt
EndIf

If !IsInCallStack("A097Visual") .And. aRotina[nOpc,4] == 2
	cFilCtr 	:= CND->CND_FILCTR
	lContinua 	:= CN240VldUsr(CND->CND_CONTRA,DEF_TRAVIS,.T.,,cFilCtr)
EndIf

cFilCNP   := xFilial("CNP",cFilCTR)

Private cEspCtr := "1"//Contrato de compra

PRIVATE aCols     := {}
PRIVATE aHeader   := {}
PRIVATE aAuxRat   := {}
DEFAULT nTipo     := 1
DEFAULT nServico  := 1 //1=Medicao de Contrato; 2=Medicao de Servico
DEFAULT nSaveSX8  := GetSX8Len()
DEFAULT lDialog   :=.T.
DEFAULT cPlan     := ""
//Desabilita na tela da medicao do contrato a tecla F4
SetKey( VK_F4, Nil )

//Autorizacao de Fornecimento
If nOpc != 3 .And. nOpc != 9 .And. nOpc != 12
	nTipo := If(CND->CND_AUTFRN=="1",1,2)
EndIf

//Medicao de Servicos
If nOpc != 3 .And. nOpc != 9 .And. nOpc != 12
	nServico := If(CND->CND_SERVIC=="1",1,2)
EndIf

If !Empty(cContra) .And. !Empty(cRevisa)
	CND->(dbSetOrder(1))
	If CND->(dbSeek(xFilial("CND",cFilCTR)+cContra+cRevisa))
		//Verifica se está posicionado corretamente no contrato
		If !(CN9->(CN9_NUMERO+CN9_REVISA) == CND->(CND_CONTRA+CND_REVISA)) 
			CN9->(dbSetOrder(1))
			CN9->(dbSeek(xFilial("CN9",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA))
		EndIf
	EndIf
	CND->(dbGoTo(nReg))
EndIf

If nServico == 1

	If Cn300RetSt("FIXO",0,cPlan,,cFilCtr,.F.)
 		aNalter   := {"CNE_PRODUT","CNE_VLUNIT","CNE_PDESC"}
 		If CNE->( ColumnPos( "CNE_ARREND" ) ) > 0
 			aAdd( aNalter,  "CNE_ARREND" )
 		EndIf
 	EndIf

 	aNoFields := {"CNE_FILIAL","CNE_TIPO","CNE_DTANIV","CNE_CONTRA","CNE_REVISA","CNE_NUMERO","CNE_NUMMED","CNE_ITSOMA","CNE_QTRETI","CNE_QTDORI","CNE_VUNORI","CNE_15ANOS","CNE_20ANOS","CNE_25ANOS"}

 	cCadastro :=  STR0007

Else

	If Cn300RetSt("FIXO",0,cPlan,,,.F.)
 		aNalter   := {"CNE_PRODUT","CNE_QUANT ","CNE_PDESC","CNE_QTDORI","CNE_VUNORI","CNE_VLTOT"}
 		If CNE->( ColumnPos( "CNE_ARREND" ) ) > 0
 			aAdd( aNalter,  "CNE_ARREND" )
 		EndIf
 	Else
 		aNalter   := {"CNE_QUANT ","CNE_QTDORI","CNE_VLTOT"}
	EndIf

	aNoFields := {"CNE_FILIAL","CNE_TIPO","CNE_DTANIV","CNE_CONTRA","CNE_REVISA","CNE_NUMERO","CNE_NUMMED","CNE_ITSOMA","CNE_QTRETI","CNE_15ANOS","CNE_20ANOS","CNE_25ANOS"}

 	cCadastro := STR0105

EndIf

// Monta texto descritivo da operação para a Medição, Ex: Medição - Incluir, etc
If nOpc == 2 // Visualizar
	cCadastro := cCadastro+" - "+STR0003
Elseif nOpc == 3 // Incluir
	cCadastro := cCadastro+" - "+STR0004
Elseif nOpc == 4 // Alterar
	cCadastro := cCadastro+" - "+STR0005
Elseif nOpc == 5 // Excluir
	cCadastro := cCadastro+" - "+STR0006
Elseif nOpc == 12 // Med. Serviços
	cCadastro := cCadastro+" - "+STR0004
Endif

If lContinua
	DEFAULT cParcel := ""
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Inicializa lancamento do PCO  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	PcoIniLan("000355")

	PRIVATE M->CND_VLTOT  := 0
	PRIVATE M->CND_DESCME := 0
	PRIVATE M->CND_VLPREV := 0
	PRIVATE M->CND_TOTADT := 0
	PRIVATE nTotAdia2 := 0
	PRIVATE nTotBoni  := 0
	PRIVATE nTotMultas:= 0
	PRIVATE lTodos    := .F.
	PRIVATE lFixo     := .T.
	PRIVATE lServico  := (nServico == 2)


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica tipo do contrato                          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lFisico == Nil
		dbSelectArea("CN9")
		dbSetOrder(1)
		If dbSeek(xFilial("CN9",cFilCTR)+If(cContra!=NIL,cContra+cRevisa,CND->CND_CONTRA+CND->CND_REVISA))
			lFisico := (Posicione("CN1",1,xFilial("CN1",cFilCTR)+CN9->CN9_TPCTO,"CN1_CROFIS") == "1")
		Else
			lFisico := .F.
		EndIf
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica especie do contrato             ³
	//³ 1 - Compra           s                    ³
	//³ 2 - Venda                                ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cEspCtr 	:= CN9->CN9_ESPCTR
	//cCodEd		:=	CN9->CN9_CODED

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica se o contrato possui planilha      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea("CN9")
	dbSetOrder(1)
	If dbSeek(xFilial("CN9",cFilCTR)+If(cContra!=NIL,cContra+cRevisa,CND->CND_CONTRA+CND->CND_REVISA))
		If cFilCtr  <> CN9->CN9_FILCTR .and. ! Empty(CN9->CN9_FILCTR)
			cFilCtr:=CN9->CN9_FILCTR
		EndIf
		If nOpc == 3 .Or. nOpc == 4
			dbSelectArea("CNA")
			CNA->(dbSetOrder(1))
			CNA->(MsSeek(xFilial("CNA",cFilCTR)+cContra+cRevisa+cPlan))
			lFixo := Cn300RetSt("FIXO",0,cPlan,CN9->CN9_NUMERO,CN9->CN9_FILCTR,.F.)
		EndIf
	EndIf

	If !lFixo
		aAdd(aNoFields,"CNE_QTDSOL")
		aAdd(aNoFields,"CNE_QTAMED")
		aAdd(aNoFields,"CNE_PERC")
	EndIf

	dbSelectArea("SX3")
	dbSetOrder(1)
	MsSeek("CND")

	If cEspCtr == "1"
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Nao exibe campos do cliente para contrato de compra ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		aAdd(aNCpo,"CND_CLIENT")
		aAdd(aNCpo,"CND_LOJACL")

		For nX:=1 to nParcelas
			If !Empty(CND->(FieldPos("CND_PARC"+Substr(cParcela,nx,1)))) .And. !Empty(CND->(FieldPos("CND_DATA"+Substr(cParcela,nx,1))))
				aAdd(aNCpo,"CND_PARC"+Substr(cParcela,nx,1))
				aAdd(aNCpo,"CND_DATA"+Substr(cParcela,nx,1))
			EndIf
		Next nX
		aAdd(aNoFields,"CNE_TS")
	Else
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Nao exibe campos do fornecedor para contrato de venda ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		aAdd(aNCpo,"CND_FORNEC")
		aAdd(aNCpo,"CND_LJFORN")
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Nao exibe campos se condição de pagamento for diferente do tipo 9 ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea("SE4")
		dbSetOrder(1)
		MsSeek(xFilial("SE4")+CN9->CN9_CONDPG)
		If SE4->E4_TIPO<>'9'
			For nX:=1 to nParcelas
				If !Empty(CND->(FieldPos("CND_PARC"+Substr(cParcela,nx,1)))) .And. !Empty(CND->(FieldPos("CND_DATA"+Substr(cParcela,nx,1))))
					aAdd(aNCpo,"CND_PARC"+Substr(cParcela,nx,1))
					aAdd(aNCpo,"CND_DATA"+Substr(cParcela,nx,1))
				EndIf
			Next nX
		EndIf

		aAdd(aNoFields,"CNE_TE")

	EndIf
	
	If CND->( ColumnPos( "CND_TXMOED" ) ) > 0
		aAdd( aNCpo, "CND_TXMOED" )
	EndIf
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Seleciona os campos do cabecalho da medicao        ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	While SX3->(!Eof()) .And. SX3->X3_ARQUIVO == "CND"
		cField := SX3->X3_CAMPO
		If X3Uso( GetSX3Cache( cField, "X3_USADO" ) ) .And. cNivel >= GetSX3Cache( cField, "X3_NIVEL" ) .And. cField != "CND_FILIAL" .And. aScan(aNCpo,{|x| x == AllTrim( cField )}) == 0
			Aadd( aCpoEnch, cField )
		EndIF

		If	( GetSX3Cache( cField, "X3_CONTEXT" ) == "V"  .Or. nOpc == 3 .Or. nOpc == 9 .Or. nOpc == 12 )
			If cField == "CND_NUMMED" .And. lAuto .And. (nPosNum := aScan(aAutoCab,{|x| x[1]=="CND_NUMMED"})) > 0
				M->CND_NUMMED := aAutoCab[nPosNum,2]
			Else
				Do Case
					Case AllTrim( cField ) == "CND_CONTRA"
						M->CND_CONTRA := cContra
					Case AllTrim( cField ) == "CND_REVISA"
						M->CND_REVISA := cRevisa
					Case AllTrim( cField ) == "CND_COMPET"
						M->CND_COMPET := cCompet
					Case AllTrim( cField ) == "CND_FILCTR"
						M->CND_FILCTR := cFilCTR
					Otherwise
						If lAuto .And. (nPosNum := aScan(aAutoCab,{|x| x[1]== cField })) > 0
					  		M->&( cField ):= aAutoCab[nPosNum,2]
						Else
					 		M->&( cField ) := CriaVar( cField )
						EndIf
				End Case
			EndIf
		ElseIf lAuto .And. nOpc == 4 .And.  cField $ "CND_FORNEC|CND_LJFORN|CND_CLIENT|CND_LOJACL" .And. (nPosNum := aScan(aAutoCab,{|x| x[1]== cField })) > 0
			M->&( cField ):= aAutoCab[nPosNum,2]
		Else
			M->&( cField ) := CND->(FieldGet(FieldPos( cField )))
		EndIf

		dbSelectArea("SX3")
		SX3->(dbSkip())
	EndDo

	//- Preenche o cliente/fornecedor
	If !lAuto
		If cEspCtr == "2"
		    If nOPC == 3 .Or. nOpc==12
				M->CND_CLIENT := CNA->CNA_CLIENT
				M->CND_LOJACL := CNA->CNA_LOJACL
			Else
				M->CND_CLIENT := CND->CND_CLIENT
				M->CND_LOJACL := CND->CND_LOJACL
			EndIf
		Else
			If nOPC == 3 .Or. nOpc==12
				M->CND_FORNEC := CNA->CNA_FORNEC
				M->CND_LJFORN := CNA->CNA_LJFORN
			Else
				M->CND_FORNEC := CND->CND_FORNEC
				M->CND_LJFORN := CND->CND_LJFORN
			EndIf
		EndIf
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Preenche moeda da medicao ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If cPaisLoc = 'RUS'
       M->CND_MOEDA :=Posicione("CN9",1,xFilial("CN9",cFilCTR)+If(cContra!=NIL,cContra+cRevisa,CND->CND_CONTRA+CND->CND_REVISA),"CN9_MOEDA")
       M->CND_CONUNI :=Posicione("CN9",1,xFilial("CN9",cFilCTR)+If(cContra!=NIL,cContra+cRevisa,CND->CND_CONTRA+CND->CND_REVISA),"CN9_CONUNI")
       M->CND_MOEDES :=Posicione("CTO",1,xFilial("CTO")+StrZero(M->CND_MOEDA,TamSX3("CTO_MOEDA")[1]),"CTO_SIMB")     
	else
	M->CND_MOEDA := If(nOpc!=3 .And. nOpc!=9.And. nOpc!=12,M->CND_MOEDA,If(!Empty(CN9->CN9_MOEDA),CN9->CN9_MOEDA,1))
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Preenche parcela do cronograma ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If (nOpc == 3 .Or. nOpc == 9 .Or. nOpc==12)
		M->CND_PARCEL := cParcel
	EndIf

	//- Preenche grupo de aprovadores
	If Empty(M->CND_APROV) .And. (GetNewPar("MV_CNMDALC","N") == "S" ) 
		M->CND_APROV := If(!Empty(CN9->CN9_GRPAPR),CN9->CN9_GRPAPR,CN1->CN1_GRPAPR)
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Definicao de variaveis Privates.  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Private aTela := {}
	Private aGets := {}

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Total da medicao             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Private oGetTot
	Private oGetVlMed
	Private oGetCauc
	Private nCaucRet   := Nil
	Private nCaucVlr   := Nil
	Private nTotMedDsc := 0//Valor total dos descontos aplicados na medicao
	Private nTotMedMlt := 0//Valor total das multas aplicadas na medicao
	Private nTotMedBnf := 0//Valor total das bonificaoes aplicadas na medicao
	Private nTotVlMed  := 0//Valor total da medicao

	oSize:AddObject("CABECALHO",100,50,.T.,.T.)
	oSize:AddObject("GETDADOS" ,100,38,.T.,.T.)
	oSize:AddObject("RODAPE"   ,100,50,.T.,.F.)

	oSize:lProp 	:= .T. // Proporcional
	oSize:aMargins := {3,3,3,3} // Espaco ao lado dos objetos 0, entre eles 3

	oSize:Process() 	   // Dispara os calculos

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica campos editaveis                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea("SX3")
	dbSetOrder(1)
	MsSeek("CNE")
	While !EOF() .And. (SX3->X3_ARQUIVO == "CNE")
		cField := SX3->X3_CAMPO
		If X3Uso( GetSX3Cache( cField, "X3_USADO" ) ) .And. cNivel >= GetSX3Cache( cField, "X3_NIVEL" ) .And. Ascan(aNoFields,{|x| x == alltrim( cField )}) == 0

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Impede alteracao dos campos no array aNAlter     ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If GetSX3Cache( cField, "X3_VISUAL" ) == "A" .And. aScan(aNAlter,AllTrim(SX3->X3_CAMPO)) == 0
				aAdd( aAlter, cField )
			EndIf
		EndIf
		dbSelectArea("SX3")
		dbSkip()
	EndDo

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica se a caucao de retencao esta disponivel ³
	//³ para contrato e para o ambiente                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If (lCaucRet := (CN9->CN9_FLGCAU == "1" .And. CN9->CN9_TPCAUC == "2"))
		nCaucRet := CN9->CN9_MINCAU
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Ponto de Entrada desenvolvido para Queiroz Galvao para   ³
		//³ permitir alteracao no percentual de retencao baseando-se ³
		//³ em um campo de usuario criado no cadastro de planilhas   ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
    	If lCn130VRet
	    	nCaucRet := If(Valtype(nCn130VRet:=ExecBlock("CN130VRET",.F.,.F.,{cContra,cRevisa,cPlan}))=="N",nCn130VRet,nCaucRet)
    	EndIf
	EndIf

	if nOpc == 3 .Or. nOpc == 9 .Or. nOpc == 12//Inclusao
		FillGetDados(nOpc,"CNE",1,,,,aNoFields,,,,,.T.,aHeader)
		aCols:={}

		nUsado := len(aHeader)

		M->CND_SERVIC := If(nServico==1,"1","2")

		M->CND_NUMERO := cPlan

		If lFixo
			dbSelectArea("CNA")
			dbSetOrder(1)
			cFilCod := xFilial('CNA',cFilCTR)
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Seleciona planilha                                 ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If dbSeek(cFilCod+cContra+cRevisa+cPlan)

				If !lAuto .Or. (lAuto .And. (Empty(M->CND_FORNEC) .Or. Empty(M->CND_LJFORN)))
					M->CND_FORNEC := CNA->CNA_FORNEC
					M->CND_LJFORN := CNA->CNA_LJFORN
				EndIf

				If !lAuto .Or. (lAuto .And. (Empty(M->CND_CLIENT) .Or. Empty(M->CND_LOJACL)))
					M->CND_CLIENT := CNA->CNA_CLIENT
					M->CND_LOJACL := CNA->CNA_LOJACL
				EndIf

				M->CND_TIPPLA := CNA->CNA_TIPPLA
				M->CND_DESCTP := Posicione("CNL",1,xFilial("CNL",cFilCTR)+M->CND_TIPPLA,"CNL_DESCRI")

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Quando o contrato nao estiver configurado para     ³
				//³ medicao eventual, seleciona o valor previsto do    ³
				//³ cronograma                                         ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If !lMedeve
					If !Empty(cParcel)
						dbSelectArea("CNF")
						dbSetOrder(3)
						dbSeek(xFilial("CNF",cFilCTR)+cContra+cRevisa+CNA->CNA_CRONOG+cParcel)
					Else
						dbSelectArea("CNF")
						dbSetOrder(2)
						dbSeek(xFilial("CNF",cFilCTR)+cContra+cRevisa+CNA->CNA_CRONOG+cCompet)
					EndIf
					If CNF->CNF_SALDO > 0
						M->CND_VLPREV := CNF->CNF_SALDO
						If lSugVal .Or. lServico
							nPercCNF := ((CNF->CNF_SALDO*100)/CNA->CNA_SALDO)//Calcula percentual da parcela
						EndIf
					Else
						lContinua := .F.
						If lAuto
							AutoGrLog("Parcela sem saldo")
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf

		If lContinua
			dbSelectArea("CN9")
			dbSetOrder(1)
			cFilCod := xFilial('CN9',cFilCTR)
			If dbSeek(cFilCod+cContra+cRevisa)
				M->CND_CONDPG := CN9->CN9_CONDPG
				M->CND_DESCCP := Posicione("SE4",1,xFilial("SE4")+M->CND_CONDPG,"E4_DESCRI")
				M->CND_VLCONT := CN9->CN9_VLATU
				M->CND_VLADIT := CN9->CN9_VLADIT
				M->CND_VLREAJ := CN9->CN9_VLREAJ

				If !lMedeve
					M->CND_DTVENC := CNF->CNF_DTVENC
				else
					aCond := Condicao(0,M->CND_CONDPG,,dDataBase)
					If len(aCond) > 0
						M->CND_DTVENC := aCond[1][1]
					Else
						M->CND_DTVENC := dDataBase
					EndIf
				EndIf
			EndIf

			If lFixo
				nPosItem  	:= GDFIELDPOS("CNE_ITEM  ")
				nPosProd  	:= GDFIELDPOS("CNE_PRODUT")
				nPosDescr 	:= GDFIELDPOS("CNE_DESCRI")
				nPosVlUn  	:= GDFIELDPOS("CNE_VLUNIT")
				nPosPerc  	:= GDFIELDPOS("CNE_PERC  ")
				nPosQMed  	:= GDFIELDPOS("CNE_QTAMED")
				nPosQSol  	:= GDFIELDPOS("CNE_QTDSOL")
				nPosQtd   	:= GDFIELDPOS("CNE_QUANT ")
				nPosPDesc 	:= GDFIELDPOS("CNE_PDESC ")
				nPosDesc  	:= GDFIELDPOS("CNE_VLDESC")
				nPosVlT   	:= GDFIELDPOS("CNE_VLTOT ")
				nPosDEnt  	:= GDFIELDPOS("CNE_DTENT ")
				nPosCms  	:= GDFIELDPOS("CNE_FLGCMS")
				nPosQOri  	:= GDFIELDPOS("CNE_QTDORI")
				nPosVOri  	:= GDFIELDPOS("CNE_VUNORI")
				nPosCC		:= GDFIELDPOS("CNE_CC")
				nPosConta	:= GDFIELDPOS("CNE_CONTA")
				nPosItemCT	:= GDFIELDPOS("CNE_ITEMCT")
				nPosCLVL  	:= GDFIELDPOS("CNE_CLVL")
				nPosPedTit	:= GDFIELDPOS("CNE_PEDTIT")
				nPosCodNE	:= GDFIELDPOS("CNE_CODNE")
				nPosItemNE	:= GDFIELDPOS("CNE_ITEMNE")
				If CNE->( ColumnPos( "CNE_ARREND" ) ) > 0
					nPosArrend := GDFIELDPOS("CNE_ARREND")
				EndIf
				
				If cEspCtr == "1"
					nPosTES  := aScan(aHeader,{|x| x[2] == "CNE_TE    "})
				Else
					nPosTES  := aScan(aHeader,{|x| x[2] == "CNE_TS    "})
				EndIf

				cFilCod := xFilial("CNB",cFilCTR)

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Monta o aCols.                                 ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				dbSelectArea("CNB")
				dbSetOrder(1)
				DbSeek(cFilCod + cContra + cRevisa + cPlan)

				While CNB->CNB_FILIAL == cFilCod .And. CNB->CNB_CONTRA == cContra .And. CNB->CNB_REVISA == cRevisa .And. CNB->CNB_NUMERO == cPlan 
					if CNB->CNB_SLDMED > 0 

						Aadd(aCols, Array(nUsado + 1))

						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Inicializa campos da getdados                  ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						For nA:=1 to len(aHeader)
							If !(IsHeadRec(aHeader[nA,2]) .OR. IsHeadAlias(aHeader[nA,2]))
								aCols[len(aCols),nA] := CriaVar(aHeader[nA,2])
							EndIf
						Next

						aCols[len(aCols),nPosItem] 	:= CNB->CNB_ITEM
						aCols[len(aCols),nPosProd] 	:= CNB->CNB_PRODUT
						aCols[len(aCols),nPosDescr]	:= CNB->CNB_DESCRI
						aCols[len(aCols),nPosVlUn] 	:= CNB->CNB_VLUNIT
						aCols[len(aCols),nPosQSol]  := CNB->CNB_QUANT
						aCols[len(aCols),nPosQtd] 	:= CNB->CNB_SLDMED

						If (!Empty(aAutoItens) .And. AScan(aAutoItens, {|x| ChkProd(x, CNB->CNB_PRODUT)}) == 0)
							lMedeve := .T. //Zera quantidades do item
						EndIf	
					
						aCols[len(aCols),nPosQMed] 	:= CNB->CNB_SLDMED
						aCols[len(aCols),nPosPDesc]	:= CNB->CNB_DESC
						aCols[len(aCols),nPosCodNE]	:= CNB->CNB_CODNE
						aCols[len(aCols),nPosItemNE]:= CNB->CNB_ITEMNE

						If nPosArrend > 0
							aCols[len(aCols),nPosArrend] := CNB->CNB_ARREND
						EndIf
						
						If nPosCC > 0
							aCols[len(aCols),nPosCC]     := CNB->CNB_CC
							aCols[len(aCols),nPosConta]  := CNB->CNB_CONTA
							aCols[len(aCols),nPosItemCT] := CNB->CNB_ITEMCT
							aCols[len(aCols),nPosCLVL]   := CNB->CNB_CLVL
						EndIf

						If nPosPedTit > 0
							aCols[len(aCols),nPosPedTit]   := CNB->CNB_PEDTIT
						EndIf
						
						For nX := 1 To Len(aCTBEnt)
							If GDFieldPos("CNE_EC"+aCTBEnt[nX]+"CR") > 0.And. CNB->(FieldPos("CNB_EC"+aCTBEnt[nX]+"CR")) > 0
			  					aCols[Len(aCols),GDFieldPos("CNE_EC"+aCTBEnt[nX]+"CR")] := CNB->&("CNB_EC"+aCTBEnt[nX]+"CR")
			 					aCols[Len(aCols),GDFieldPos("CNE_EC"+aCTBEnt[nX]+"DB")] := CNB->&("CNB_EC"+aCTBEnt[nX]+"DB")
							EndIf
						Next nX

						If nPosCms > 0
							aCols[len(aCols),nPosCms]  := CNB->CNB_FLGCMS
						EndIf
						
						If nPosTES > 0
							If !Empty(CNB->CNB_TE) .Or. !Empty(CNB->CNB_TS)
								aCols[len(aCols),nPosTES]  := iIf(cEspCtr=="1",CNB->CNB_TE,CNB->CNB_TS)
								lTesSB1 := .F.
							EndIf
						EndIf
						

						If nPosTES > 0 .And. lTesSB1
							SB1->(dbSetOrder( 1 ))
							dbSelectArea("SB1")
							If MSSeek(xFilial("SB1")+aCols[len(aCols),nPosProd])
								If !Empty(SB1->B1_TE) .Or. !Empty(SB1->B1_TS)
							   		aCols[len(aCols),nPosTES]  := iIf(cEspCtr=="1",SB1->B1_TE,SB1->B1_TS)
								EndIf
							EndIf
						EndIf

						If (lMedeve .OR. !lSugVal) .And. !lServico
							aCols[len(aCols),nPosQtd] := 0.00
							aCols[len(aCols),nPosVlT] := 0.00
							aCols[len(aCols),nPosPerc]:= 0.00
							aCols[len(aCols),nPosDesc]:= 0.00
						Else
							If !lFisico
								If nServico == 1
									aCols[len(aCols),nPosQtd] := A410Arred( CNB->CNB_SLDMED * nPercCNF , "CNE_QUANT" )
									If CNB->CNB_SLDMED < aCols[len(aCols),nPosQtd] .And. (aCols[len(aCols),nPosQtd]-CNB->CNB_SLDMED) > 0.0001
										aCols[len(aCols),nPosQtd] := CNB->CNB_SLDMED
									EndIf
								Else
									aCols[len(aCols),nPosQtd] := 1
									aCols[len(aCols),nPosQOri] := If( lMedeve , CNB->CNB_SLDMED , A410Arred( CNB->CNB_SLDMED * nPercCNF , "CNE_QUANT" ) )
									aCols[len(aCols),nPosVOri]:= CNB->CNB_VLUNIT
									If CNB->CNB_SLDMED < aCols[len(aCols),nPosQOri] .And. (aCols[len(aCols),nPosQOri]-CNB->CNB_SLDMED) > 0.0001
										aCols[len(aCols),nPosQOri] := CNB->CNB_SLDMED
									EndIf
								EndIf
							Else
								dbSelectArea("CNS")
								dbSetOrder(1)

								If dbSeek(xFilial("CNS",cFilCTR)+cContra+cRevisa+CNF->CNF_NUMERO+CNF->CNF_PARCEL+CNB->CNB_ITEM)
									aCols[len(aCols),nPosQtd] := If((CNS->CNS_SLDQTD > 0),CNS->CNS_SLDQTD,0)
									If CNB->CNB_SLDMED < CNS->CNS_SLDQTD
										aCols[len(aCols),nPosQtd] := CNB->CNB_SLDMED
									EndIf
								EndIf
							EndIF

							If nServico == 1
								aCols[len(aCols),nPosVlT] := A410Arred(aCols[len(aCols),nPosQtd]*CNB->CNB_VLUNIT,"CNE_VLTOT")
								aCols[len(aCols),nPosPerc]:= A410Arred((aCols[len(aCols),nPosQtd]*100)/CNB->CNB_QUANT,"CNE_PERC")

								If cEspCtr == "2"
									If aCols[len(aCols),nPosPDesc] > 0
										FtDescItem(0,@aCols[len(aCols),nPosVlUn],@aCols[len(aCols),nPosQtd],0,CNB->CNB_DESC,@aCols[len(aCols),nPosDesc],0,1,,)
									Endif
									nTotUnt := A410Arred(aCols[len(aCols),nPosVlT]-(aCols[len(aCols),nPosQMed]*CNB->CNB_VLUNIT),"CNE_VLTOT")
	        		            Else
									aCols[len(aCols),nPosDesc]:= A410Arred((aCols[len(aCols),nPosVlT]*CNB->CNB_DESC)/100,"CNE_VLDESC")
								EndIF
							Else
								aCols[len(aCols),nPosVlT] := aCols[len(aCols),nPosQOri]*CNB->CNB_VLUNIT
								aCols[len(aCols),nPosVlUn]:= aCols[len(aCols),nPosVlT]
								aCols[len(aCols),nPosPerc]:= (aCols[len(aCols),nPosQOri]*100)/CNB->CNB_QUANT

								If cEspCtr == "2"
									If aCols[len(aCols),nPosPDesc] > 0
										FtDescItem(0,@aCols[len(aCols),nPosVOri],@aCols[len(aCols),nPosQOri],0,CNB->CNB_DESC,@aCols[len(aCols),nPosDesc],0,1,,)
									Endif
						        Else
									aCols[len(aCols),nPosDesc]:= A410Arred((aCols[len(aCols),nPosVlT]*CNB->CNB_DESC)/100,"CNE_VLDESC")
								EndIf
							EndIf
							M->CND_VLTOT += Round(aCols[len(aCols),nPosVlT]-aCols[len(aCols),nPosDesc],TamSx3("CNE_VLTOT")[2])
						EndIf

						aCols[len(aCols),nPosDEnt] := dDataBase

						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Atribui .F. p/ a coluna que determina se a linha do aCols esta deletada.³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						aCols[Len(aCols)][nUsado + 1] := .F.
						nContaIt++
					EndIf

					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Efetua a copia do rateio para a medicao ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

					C130CpyCNZ({CNB->CNB_CONTRA,CNB->CNB_REVISA,CNB->CNB_NUMERO,CNB->CNB_ITEM},aRatGCT)


					dbSelectArea("CNB")
					dbSkip()
				EndDo

				If M->CND_VLTOT > CNA->CNA_SALDO // Verifica se o valor da medição irá ultrapassar o saldo do contrato
					nArredMed := Round(M->CND_VLTOT,TamSX3("CND_VLTOT")[2]) - CNA->CNA_SALDO
					If nArredMed <= 0.02 // Verifica se a diferença é de até 2 centavos
						M->CND_VLTOT -= nArredMed
					Endif
				Endif
			EndIf

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Ponto de entrada executado na inclusao da medicao ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If ExistBlock("CN130Inc")
				aRet := ExecBlock("CN130Inc",.f.,.f.,{aHeader,aCols,aHeadDcs,aDescs})

				If Valtype(aRet) == "A"
					If Len(aRet)>=1 .And. Valtype(aRet[1]) == "A"
						aHeader := aClone(aRet[1])
					EndIf
					If Len(aRet)>=2 .And. Valtype(aRet[2]) == "A"
						aCols   := aClone(aRet[2])
					EndIf
					If Len(aRet)>=3 .And. Valtype(aRet[3]) == "A"
						aHeadDcs:= aClone(aRet[3])
					EndIf
					If Len(aRet)>=4 .And. Valtype(aRet[4]) == "A"
						aDescs  := aClone(aRet[4])
					EndIf
				EndIf
			EndIf

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Verifica se contrato possui saldo              ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If nContaIt==0 .And. lFixo
				Help (" ",1,"CN130NOIT")
				lContinua := .F.
			EndIf

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Calcula valor da retencao                      ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If lContinua
				If lCaucRet
					nCaucVlr:=((M->CND_VLTOT*nCaucRet)/100)
				EndIf

				If CN300RetSt("TPMULT",0,cPlan,,cFilCtr,.F.) == "2"
					CN130ReprMT(,,,@aMultas)
				EndIf

				If cEspCtr == "1"
					nTotVlMed := M->CND_VLTOT - M->CND_DESCME - M->CND_TOTADT - nTotMultas + nTotBoni - (If(nCaucVlr!=Nil,nCaucVlr,0))
				Else
					nTotVlMed := M->CND_VLTOT - M->CND_DESCME - M->CND_TOTADT + nTotMultas - nTotBoni - (If(nCaucVlr!=Nil,nCaucVlr,0))
				EndIf
			EndIf
		EndIf
	Else//Alteracao,Visualizacao,Exclusao
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Monta aCols e aHeader                          ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea("CNE")					
		cFilCod := CND->CND_FILIAL
		
		cSeek	 := cFilCod+CND->CND_CONTRA+CND->CND_REVISA+CND->CND_NUMERO+CND->CND_NUMMED
		cWhile := "CNE_FILIAL+CNE_CONTRA+CNE_REVISA+CNE_NUMERO+CNE_NUMMED"
 	 	FillGetDados(nOPc,"CNE",1,cSeek,{|| &cWhile },{|| .T. },aNoFields,,,,,,aHeader,aCols)

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Carrega valor total do desconto    ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		M->CND_DESCME:=CND->CND_DESCME
		M->CND_VLTOT :=CND->CND_VLTOT
		M->CND_VLPREV:=CND->CND_VLPREV
		M->CND_TOTADT:=CND->CND_TOTADT
		nTotAdia2:=CND->CND_TOTADT //armazenando valor para futuros recalculos

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Ponto de entrada executado na alteração, exclusão e visualização da medicao ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If ExistBlock("CN130Alt")
			ExecBlock("CN130Alt",.F.,.F.,{nOpc})
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Carrega valor de retencao                   ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If !Empty(CND->CND_RETCAC)
			nCaucVlr:=CND->CND_RETCAC
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Carrega o array de multas / bonificacoes ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

		cAliasCNR := GetNextAlias()

		dbSelectArea("CNR")

		cQuery := " SELECT * "
		cQuery += " FROM "+RetSqlName("CNR")
		cQuery += " WHERE CNR_FILIAL = '"+xFilial("CNR")+"'"
		cQuery += " AND CNR_NUMMED = '"+CND->CND_NUMMED+"'"
		cQuery += " AND D_E_L_E_T_ = ' ' "

		cQuery := ChangeQuery( cQuery )
		dbUseArea( .T., "TOPCONN", TcGenQry( ,, cQuery ), cAliasCNR, .F., .T. )

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Acerta o campo numerico                  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		TcSetField( cAliasCNR, "CNR_VALOR", "N", 14, 2 )

		While !( cAliasCNR )->( Eof() )

			If !Empty(( cAliasCNR )->CNR_CONTRA) .And. (( cAliasCNR )->CNR_CONTRA) <> CND->CND_CONTRA
				( cAliasCNR )->( dbSkip() )
				Loop
			EndIf

			aMultParc := Array( 6 )

			aMultParc[ 1 ] := ( cAliasCNR )->CNR_TIPO
			aMultParc[ 2 ] := ( cAliasCNR )->CNR_DESCRI
			aMultParc[ 3 ] := ( cAliasCNR )->CNR_VALOR
			aMultParc[ 4 ] := ( cAliasCNR )->CNR_MODO
			aMultParc[ 5 ] := ( cAliasCNR )->CNR_FLGPED
			aMultParc[ 6 ] := ( cAliasCNR )->CNR_CODIGO

			AAdd( aMultas, aMultParc )

			If ( cAliasCNR )->CNR_TIPO == "1"
				nTotMultas += ( cAliasCNR )->CNR_VALOR
				//Soma as multas que interferem pedido
				If  ( cAliasCNR )->CNR_FLGPED == "1"
					nTotMedMlt += ( cAliasCNR )->CNR_VALOR
				EndIf
			ElseIf ( cAliasCNR )->CNR_TIPO == "2"
				nTotBoni   += ( cAliasCNR )->CNR_VALOR
				//Soma as bonificacoes que interferem pedido
				If  ( cAliasCNR )->CNR_FLGPED == "1"
					nTotMedBnf += ( cAliasCNR )->CNR_VALOR
				EndIf
			EndIf

			( cAliasCNR )->( dbSkip() )

		EndDo

		( cAliasCNR )->( dbCloseArea() )
			dbSelectArea( "CNR" )

		//Carrega Descontos
		CN130PrcDesc(nOpc,aHeadDcs,aDescs)
		//Encontra posicoes
		nPosVlDesc:=aScan(aHeadDcs,{|x| x[2] == "CNQ_VALOR "})
		nPosTpDesc:=aScan(aHeadDcs,{|x| x[2] == "CNQ_TPDESC"})

		dbSelectArea("CNP")
		If nPosVlDesc > 0 .And. nPosTpDesc > 0
			For nx:=1 to len(aDescs)
				//Soma os valores apenas dos descontos que afetam o pedido
				If dbSeek(cFilCNP+aDescs[nx,nPosTpDesc]) .And. CNP->CNP_FLGPED == "1"
					nTotMedDsc += aDescs[nx,nPosVlDesc]
				EndIf
			Next
        EndIf
	EndIf


	If lContinua
		// Tratamento para calculo do desconto na rotina automatica
		// Essencial para MATA410
		If INCLUI .And. lAuto .And. (nX := aScan(aAutoCab,{|x| AllTrim(x[1]) == "CND_DESCME"})) > 0
			//Carrega estrutura dos arrays de descontos
			CN130PrcDesc(nOpc,aHeadDcs,aDescs)

			M->CND_DESCME := aAutoCab[nX,2]
			For nX := 1 To Len(aHeadDcs)-2
				Do Case
					Case AllTrim(aHeadDcs[nX,2]) == "CNQ_TPDESC"
						aTail(aDescs)[nX] := CN130DesPV()
					Case AllTrim(aHeadDcs[nX,2]) == "CNQ_VALOR"
						aTail(aDescs)[nX] := M->CND_DESCME
					OtherWise
						aTail(aDescs)[nX] := CriaVar(AllTrim(aHeadDcs[nX,2]))
				EndCase
			Next nX
		EndIf

		// Carrega OBS ja que nao ha tratamento para memo
		If INCLUI .And. lAuto .And. (nX := aScan(aAutoCab,{|x| AllTrim(x[1]) == "CND_OBS"})) > 0
			M->CND_OBS := aAutoCab[nX,2]
		EndIf

		If INCLUI .And. lAuto .And. Len(aMultasGCT) > 0
			aMultas := aMultasGCT
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Atualiza valor total da medicao          ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If cEspCtr == "1"
			nTotVlMed := M->CND_VLTOT - M->CND_DESCME - M->CND_TOTADT - nTotMultas + nTotBoni - (If(nCaucVlr!=Nil,nCaucVlr,0))
		Else
			nTotVlMed := M->CND_VLTOT - M->CND_DESCME - M->CND_TOTADT + nTotMultas - nTotBoni - (If(nCaucVlr!=Nil,nCaucVlr,0))
		EndIf

		If lAuto
			//-- Carrega excedentes no aCols
			If cEspCtr == '2' .And. lHabiExce .And. Type("aAutoExced") # "U"
				CN130Exce(nOpc)
			EndIf

			aAuxRat:= aClone(aRatGCT)

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Executa rotina automatica para os itens quando ³
			//³o usuario informar os itens, caso contrario    ³
			//³aceita o valor sugerido pela medicao se o      ³
			//³parametro MV_CNSUGME estiver ativo             ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If len(aAutoItens) > 0
				If MsGetDAuto(aAutoItens,,{|| CN130TudOk(aCols)},aAutoCab,aRotina[nOpc][4])
				 	nOpca := 1
				Else
					nOpca := 0
				EndIf
			Else
				nOpca := 1
			EndIf
		Else
			aAuxRat:= aClone(aRatGCT)
			If lDialog
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Botao do Tracker                                        ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If nOpc # 1 // Excedentes
					If aRotina[ nOpc, 4 ] == 2
						aAdd(aButtons, { "bmpord1", { || CN130Track(aHeader,aCols) }, STR0012, STR0011 } ) //"System Tracker", "Tracker"
						If (GetNewPar("MV_CNMDALC","N") == "S" ) .And. !Empty(CND->CND_APROV)
							If MtExistDBM('IM',CND->CND_NUMMED)
                        		aAdd(aButtons,{"BUDGET",   {|| a120Posic(cAlias,nReg,nOpc,"IM",.F.)},STR0076,STR0077 }) //"Consulta Aprovacao por Item de Medição"
                  			Else
                        		aAdd(aButtons,{"BUDGET",   {|| a120Posic(cAlias,nReg,nOpc,"MD",.F.)},STR0076,STR0077 }) //"Consulta Aprovacao por Medição"
                 			EndIf
						EndIf
					EndIf

					Aadd(aButtons,{ "BAIXATIT",{|| CN130Desc(nOpc,aDescs,aHeadDcs),oGetDesc:Refresh(),CN130TotMed(5)},OemToAnsi(STR0014),OemtoAnsi(STR0013)})//"Descontos"

					If lFisico
						Aadd(aButtons,{ "note",{|| (If(CN110VisFis(M->CND_CONTRA,M->CND_REVISA,M->CND_NUMERO,M->CND_COMPET,oGetDados,(aRotina[ nOpc, 4 ] == 2),M->CND_PARCEL),(M->CND_VLTOT:=M->CND_VLPREV,CN130TotMed(5)),))},OemToAnsi(STR0065),OemtoAnsi(STR0064)})//Cronograma Físico
					EndIf

					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Botao das multas / bonificacoes                         ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

					AAdd( aButtons,{ "checked", {|| CN130Multas( aMultas, oGetDados:aCols, oGetDados:aHeader, aRotina[ nOpc, 4 ], @nTotMultas, @nTotBoni, M->CND_CONTRA, M->CND_REVISA,@oGetMultas,@oGetBoni, cPlan ), CN130TotMed(5) }, STR0021, STR0022 } ) // "Seleciona Multas / Bonificacoes", "Multas"


			   	    //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Botao dos Adiatamentos                                  ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					Aadd(aButtons,{ "BUDGET",{|| If(nOpc=3 .or. nOpc=4 .or. nOpc=9 .or. nOpc=12,CN130Adiant(M->CND_CONTRA,M->CND_NUMERO, oGetDados:aCols, oGetDados:aHeader, aRotina[ nOpc, 4 ],M->CND_CONTRA, M->CND_REVISA,nOpc,@aHeadCpos,@aColsCpos ),), CN130TotMed(5)}, "Selecione os Adiantamentos", "Adiantam." } )
					Aadd(aButtons,{'S4WB013N',{|| oGetDados:oBrowse:lDisablePaint := .T. , GCTRateio(oGetDados,aRatGCT,nOpc,{M->CND_CONTRA,M->CND_REVISA,M->CND_NUMMED},@aAuxRat), oGetDados:oBrowse:lDisablePaint := .F. },STR0090,STR0091})//"Rateio por Item do pedido"##"Rateio "

				EndIf

		   	    //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Botao para inclusao de excedente						³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If cEspCtr == '2' .And. lHabiExce
					aAdd(aButtons,{ "SOLICITA",{|| CN130Exce(nOpc)},OemToAnsi(STR0095),OemtoAnsi(STR0092)}) //"Excedente"
				EndIf

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Avalia botoes do usuario                                     ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If ExistBlock( "CN130BUT" )
					If ValType( aUsButtons := ExecBlock( "CN130BUT", .F., .F. ) ) == "A"
						AEval( aUsButtons, { |x| AAdd( aButtons, x ) } )
					EndIf
				EndIf

				// Monta texto descritivo da operação para a Medição, Ex: Medição - Incluir, etc
				If nOpc == 3 .and. IsInCallStack("CN120Serv") // Serviços
					cCadastro := cCadastro+" (Serviços)"
				Endif

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Dialog.                                                                 ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				DEFINE MSDIALOG oDlg TITLE cCadastro From oSize:aWindSize[1],oSize:aWindSize[2] to oSize:aWindSize[3],oSize:aWindSize[4] of oMainWnd PIXEL

				EnChoice( cAlias, nReg, nOpc,,,,aCpoEnch,{oSize:GetDimension("CABECALHO","LININI"),oSize:GetDimension("CABECALHO","COLINI"),oSize:GetDimension("CABECALHO","LINEND"),oSize:GetDimension("CABECALHO","COLEND")}, , , , , , , , .T.)

				If ValType(xParam) == "C" .And. xParam == "EXCEDE"
					oGetDados:=MsNewGetDados():New(oSize:GetDimension("GETDADOS","LININI"),oSize:GetDimension("GETDADOS","COLINI"),oSize:GetDimension("GETDADOS","LINEND"),oSize:GetDimension("GETDADOS","COLEND"),GD_DELETE,"CN130LinOk()","CN130TudOk()",,,,999,,,"CN130DelOk(.T.)",oDlg,aHeader,aCols)
				ElseIf lFixo
					oGetDados:=MsNewGetDados():New(oSize:GetDimension("GETDADOS","LININI"),oSize:GetDimension("GETDADOS","COLINI"),oSize:GetDimension("GETDADOS","LINEND"),oSize:GetDimension("GETDADOS","COLEND"),IIF(nOpc!=3 .And. nOpc!=4 .And. nOpc!=9.And. nOpc!=12,0,GD_UPDATE+GD_DELETE),"CN130LinOk()","CN130TudOk()",,aAlter,,len(aCols),,,"CN130DelOk(.T.)",oDlg,aHeader,aCols)
				Else
					oGetDados:=MsNewGetDados():New(oSize:GetDimension("GETDADOS","LININI"),oSize:GetDimension("GETDADOS","COLINI"),oSize:GetDimension("GETDADOS","LINEND"),oSize:GetDimension("GETDADOS","COLEND"),IIF(nOpc!=3 .And. nOpc!=4 .And. nOpc!=9,0,GD_INSERT+GD_UPDATE+GD_DELETE),"CN130LinOk()","CN130TudOk()",'+CNE_ITEM',,,999,"CN130FldOk",,"CN130DelOk(.F.)",oDlg,aHeader,aCols)
				EndIf

				oFolder := TFolder():New(oSize:GetDimension("RODAPE","LININI"),oSize:GetDimension("RODAPE","COLINI"),{OemToAnsi(STR0015)},,oDlg,,,, .T., .F.,oSize:GetDimension("RODAPE","XSIZE"),oSize:GetDimension("RODAPE","YSIZE"))

				@ 003,003 Say OemToAnsi(STR0018) Of oFolder:aDialogs[1] PIXEL //Total itens
				@ 002,037 MsGet oGetTot Var M->CND_VLTOT Picture PesqPict("CND","CND_VLTOT") PIXEL When .F. Size 65,5 Of oFolder:aDialogs[1]

				@ 019,003 Say OemToAnsi(STR0079) Of oFolder:aDialogs[1] PIXEL//Total Medicao
				@ 018,037 MsGet oGetVlMed Var NoRound(nTotVlMed,TamSx3("CND_VLTOT")[2]) Picture PesqPict("CND","CND_VLTOT") PIXEL When .F. Size 65,5 Of oFolder:aDialogs[1]

				@ 003,117 Say OemToAnsi(STR0019) Of oFolder:aDialogs[1] PIXEL //Valor previsto
				@ 002,151 MsGet oGetPrev Var M->CND_VLPREV Picture PesqPict("CND","CND_VLTOT") PIXEL When .F. Size 65,5 Of oFolder:aDialogs[1]

				@ 003,231 Say OemToAnsi(STR0013) Of oFolder:aDialogs[1] PIXEL //Total do desconto
				@ 002,275 MsGet oGetDesc Var M->CND_DESCME Picture PesqPict("CND","CND_VLTOT") PIXEL When .F. Size 65,5 Of oFolder:aDialogs[1]


				@ 019,117 Say  If(lCN130LBM,(If(ValType(cCN130LBM:= ExecBlock("CN130LBM",.F.,.F.))=="C",cCN130LBM, OemToAnsi(STR0054))),OemToAnsi(STR0054))  Of oFolder:aDialogs[1] PIXEL //Multas
				@ 018,151 MsGet oGetMultas Var nTotMultas Picture PesqPict("CND","CND_VLTOT") PIXEL When .F. Size 65,5 Of oFolder:aDialogs[1]

				@ 019,231 Say OemToAnsi(STR0055)   Of oFolder:aDialogs[1] PIXEL //Bonificacoes
				@ 018,275 MsGet oGetBoni Var nTotBoni   Picture PesqPict("CND","CND_VLTOT") PIXEL When .F. Size 65,5 Of oFolder:aDialogs[1]



				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Valor Total do Aditamento                   ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				@ 003,355 Say OemToAnsi(STR0066) Of oFolder:aDialogs[1] PIXEL //Adiantamento
				@ 002,402 MsGet oGetAdia Var M->CND_TOTADT Picture PesqPict("CND","CND_TOTADT") PIXEL When .F. Size 65,5 Of oFolder:aDialogs[1]
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Valor retido da caucao                      ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If lCaucRet
					@ 019,355 Say OemToAnsi(STR0063) Of oFolder:aDialogs[1] PIXEL//"Ret. Caução"
					@ 018,402 MsGet oGetCauc Var nCaucVlr Picture PesqPict("CND","CND_RETCAC") PIXEL When .F. Size 65,5 Of oFolder:aDialogs[1]
				EndIf

				If Len(aRatGCT) == 0
					aRatGCT := GetRatInBase(oGetDados,"CND")
				Endif
				ACTIVATE MSDIALOG oDlg ON INIT EnchoiceBar(oDlg,{|| If(Obrigatorio(aGets,aTela) .And. oGetDados:TudoOk() .And.  If( nOpc == 3 .Or. nOpc == 4,CN130VldMed(cContra,cRevisa,cPlan,cCompet,lMedeve,aMultas),.T.),{nOpca:=1,oDlg:End()},nOpca:=0)},{||(nOpca:=2,oDlg:End())},,aButtons)
			EndIf
		EndIf

		If nOpca == 1

			If lCn130PrG
				lContinua := ExecBlock( "CN130PrG", .F., .F., { cAlias, nReg, nOpc } )
			EndIf

			If lContinua
				If ValType(xParam) == "C" .And. xParam == "EXCEDE"
					nOpc := 13
				EndIf

				CN130Grv(nOpc,lMedeve,cCompet,@nSaveSX8,aDescs,aHeadDcs,aMultas,aHeader,aCols,nTipo,aRatGCT,nServico)

				If ValType(xParam) == "C" .And. xParam == "EXCEDE" .And. lRet
					Processa({|| CN120GrvPeD(CND->CND_NUMMED,CND->CND_REVISA,@cNumPed,NIL,CND->CND_CONTRA,NIL,.T.)},,STR0097) //-- Gerando Pedido de Venda
					If !Empty(cNumPed)
						Aviso("CNTA120",STR0096 +cNumPed,{STR0046}) //Gerado pedido de venda número ###
					EndIf
				EndIf
			EndIf

		Else
		   If nOpc == 3
		   		lRet := .F.
		   		While ( GetSX8Len() >= nSaveSX8 )
				   RollBackSX8()
				EndDo
			Else
			   While ( GetSX8Len() > nSaveSX8 )
				   RollBackSX8()
				EndDo
			EndIf
		EndIf

		aListBox   := {}

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Finaliza lancamentos do PCO  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		PcoFinLan("000355")
		PcoFreeBlq("000355",,,,,(nOpc == 4 .And. nOpca!=1))
	EndIf
EndIf

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN130Desc ³ Autor ³ Marcelo Custodio      ³ Data ³20.05.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Rotina de manutencao dos descontos                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN130Desc(nExp01,aExp03,aExp04)                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³  nExp01 - Opcao Atual                                      ³±±
±±³          ³  lExp02 - Descontos aplicados - acols                      ³±±
±±³          ³  cExp03 - Cabecalho da getdados de desconto                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function CN130Desc(nOpc,aDescs,aHeadDcs)

Local oGetDados

Local cFilCNP   := xFilial("CNP",cFilCTR)
Local cQuery
Local cCampo

Local nUsado
Local nPosTp
Local nx
Local nOpca:=2
Local nPosVl
Local oDlgDesc

Local aStrucCNQ

If len(aHeadDcs) == 0
	CN130PrcDesc(nOpc,aHeadDcs,aDescs)
EndIf

DEFINE MSDIALOG oDlgDesc TITLE OemToAnsi(STR0061) From 165,115 TO 450,600 PIXEL//"Descontos"

@ 07,05 GROUP oGrp To __DlgHeight(oDlgDesc)-30,__DlgWidth(oDlgDesc)-5 Label OemToAnsi(STR0062) Of oDlgDesc PIXEL//"Descontos Aplicados"

oGetDadDe:=MsNewGetDados():New(15,10,__DlgHeight(oDlgDesc)-35,__DlgWidth(oDlgDesc)-10,IIF(nOpc==2,0,GD_UPDATE+GD_INSERT+GD_DELETE),"CN130VldDes(oGetDadDe)",,,,,,,,,oDlgDesc,aHeadDcs,aDescs)

DEFINE SBUTTON FROM __DlgHeight(oDlgDesc)-25, __DlgWidth(oDlgDesc)-60 TYPE 1 ACTION (If((CN130VldDes(oGetDadDe)),(nOpca:=1,oDlgDesc:End()),)) ENABLE OF oDlgDesc PIXEL
DEFINE SBUTTON FROM __DlgHeight(oDlgDesc)-25, __DlgWidth(oDlgDesc)-30 TYPE 2 ACTION (nOpca:=2,oDlgDesc:End()) ENABLE OF oDlgDesc PIXEL

ACTIVATE MSDIALOG oDlgDesc CENTERED

If nOpca==1
	nUsado := len(aHeadDcs)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Atualiza descontos                          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aDescs:=oGetDadDe:aCols
	nPosVl:=aScan(aHeadDcs,{|x| x[2] == "CNQ_VALOR "})
	nPosTp:=aScan(aHeadDcs,{|x| x[2] == "CNQ_TPDESC"})
	M->CND_DESCME:=0
	nTotMedDsc:=0

	dbSelectArea("CNP")
	dbSetOrder(1)

	For nx:=1 to len(aDescs)
		If !aDescs[nx,nUsado+1]
			M->CND_DESCME+=aDescs[nx,nPosVl]

			//Soma os valores apenas dos descontos que afetam o pedido
			If dbSeek(cFilCNP+aDescs[nx,nPosTp]) .And. CNP->CNP_FLGPED == "1"
				nTotMedDsc += aDescs[nx,nPosVl]
			EndIf
		EndIf
	Next
EndIf

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN130PrcDesc³ Autor ³ Marcelo Custodio      ³ Data ³20.05.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Preenche aCols e aHeader para o controle de descontos        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN130PrcDesc(nExp1,aExp2,aExp3)                              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³  nExp01 - Opcao Atual                                        ³±±
±±³          ³  aExp02 - aHeader - Descontos                                ³±±
±±³          ³  aExp03 - aCols - Descontos                                  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function CN130PrcDesc(nOpc,aHeadDcs,aDescs)
Local nUsado    := 0
Local nX
Local nPosTp

Local aNoFields := {"CNQ_NUMMED","CNQ_CONTRA","CNQ_NUMPLA","CNQ_FILIAL"}
Local aHeadBck  := aClone(aHeader)
Local aColsBck  := aClone(aCols)

Local cQuery    := ""
Local cSeek     := ""
Local cWhile    := ""

aHeadDcs := {}
aDescs   := {}

If nUsado == 0
	If nOpc != 3 .And. nOpc != 9 .And. nOpc!=12
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Carrega descontos na edicao                 ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

		cQuery := "SELECT CNQ.* "
		cQuery += "  FROM "+RetSQLName("CNQ")+" CNQ "
		cQuery += " WHERE CNQ.CNQ_FILIAL = '"+xFilial("CNQ")+"'"
		cQuery += "   AND CNQ.CNQ_NUMMED = '"+CND->CND_NUMMED+"'"
		cQuery += "   AND CNQ.D_E_L_E_T_ = '' "
		cQuery += " ORDER BY CNQ.CNQ_TPDESC"

		cSeek  := xFilial("CNQ") + CND->CND_NUMMED
		cWhile := "CNQ_FILIAL+CNQ_NUMMED"

		FillGetDados(nOpc,"CNQ",1,cSeek,{|| &cWhile},{|| .T. },aNoFields,,,,,,aHeadDcs,aDescs)
	Else
		FillGetDados(nOpc,"CNQ",1,,,,aNoFields,,,,,.T.,aHeadDcs,aDescs)
	EndIf

	nUsado := len(aHeadDcs)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Carrega item vazio                          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If len(aDescs) == 0
		aAdd(aDescs,Array(nUsado+1))
		For nX := 1 To nUsado
			aDescs[1, nX] := CriaVar(aHeadDcs[nX, 2])
		Next nX
		aDescs[1,nUsado+1] := .F.
	EndIf
EndIf

aHeader  := aClone(aHeadBck)
aCols    := aClone(aColsBck)

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN130Grv  ³ Autor ³ Marcelo Custodio      ³ Data ³09.02.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Grava Medicao                                              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN130Grv(nExp01,lExp03,cExp04,cExp04)                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³  nExp01 - Opcao Atual                                      ³±±
±±³          ³  lExp02 - Medicao Eventual                                 ³±±
±±³          ³  cExp03 - Competencia                                      ³±±
±±³          ³  cExp04 - ncSX8                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³         ATUALIZACOES SOFRIDAS DESDE A CONSTRU€AO INICIAL.             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Programador ³ Data   ³ BOPS ³  Motivo da Alteracao                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³            ³        ³      ³                                          ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function CN130Grv(nOpc,lMedeve,cCompet,nSaveSX8,aDescs,aHeadDcs,aMultas,aHeader,aCols,nTipo,aRatGCT,nServico)

Local nPosIt      := aScan(aHeader,{|x| x[2] == "CNE_ITEM  "})
Local nLoop       := 0
Local nCntFor     := 0
Local nCntFor2    := 0
Local nX          := 0
Local nY		  := 0
Local nA          := 0
Local nUsado      := 0

Local cFilCod     := ""
Local cCronog     := ""
Local cQuery      := ""

Local lAlc        := .T.
Local lRet        := .T.
Local aListEnce   := {}
Local aCampos			:={}
Local nPosiItem   := aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_ITEM"})

Default aRatGCT	:= {}
Default nServico:= 1

nTotMultas	:= Iif(Type("nTotMultas")=='N',nTotMultas,0)
nTotBoni	:= Iif(Type("nTotBoni")=='N',nTotBoni,0)

nSaveSX8 	 :=  GetSX8Len()

If !lAuto
	aCols := oGetDados:aCols
Endif

If ExistBlock("MD130GRV")
	ExecBlock("MD130GRV",.F.,.F.,{nOpc})
EndIf

//-Trata aRatGCT para remover linhas em branco.
For nX := Len(aRatGCT) To 1 Step -1
	For nY := Len(aRatGCT[nX,5]) To 1 Step -1
		If aRatGCT[nX,5,nY,2] == 0 .And. Empty(aRatGCT[nX,5,nY,3])
			ADel(aRatGCT[nX,5],nY)
			aSize(aRatGCT[nx,5],Len(aRatGCT[nX,5]) - 1)
		EndIf
	Next nY
Next nX

Do Case
	Case nOpc == 3 .OR. nOpc == 9 .Or. nOpc=12//Inclusao
		Begin Transaction
		dbSelectArea("CND")
		cFilCod := xFilial("CND")

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Grava cabecalho da medicao                     ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		Reclock("CND",.T.)
			For nCntFor := 1 To FCount()
				If (FieldName(nCntFor)!="CND_FILIAL")
					If (FieldName(nCntFor)!="CND_RETCAC" )
						FieldPut(nCntFor,M->&(FieldName(nCntFor)))
					EndIf
				Else
					CND->CND_FILIAL := cFilCod
				EndIf
			Next nCntFor
			CND->CND_VLPREV:= M->CND_VLPREV
			CND->CND_VLTOT := M->CND_VLTOT
			CND->CND_DESCME:= M->CND_DESCME
			CND->CND_TOTADT:= M->CND_TOTADT
			CND->CND_VLMULT:= nTotMultas
			CND->CND_VLBONI:= nTotBoni

			//Filial do contrato
			CND->CND_FILCTR	 := cFilCTR

			//Define situação em Aberto/Forn. Aberto.
			CND->CND_SITUAC  := Iif(nTipo == 1,"A","FA")

	        //Numero da Parcela
			If !Empty(M->CND_PARCEL)
				CND->CND_PARCEL	 := M->CND_PARCEL
			EndIf

			//Autorizacao de Fornecimento
	       CND->CND_AUTFRN := If(nTipo == 1,"1","2")


			//Medição de Servicos
	       CND->CND_SERVIC := M->CND_SERVIC


			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Preenche o valor retido na medicao             ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			CND->CND_RETCAC:= If(nCaucVlr!=Nil,nCaucVlr,0)

		MsUnlock()

		CND->(FKCommit())

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Executa lancamento do PCO ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		PcoDetLan("000355","01","CNTA120")

		dbSelectArea("CNE")
		nUsado := Len(aHeader)
		cFilCod := xFilial("CNE")

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Grava itens da medicao                         ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		For nCntFor := 1 To Len(aCols)
			If ( !aCols[nCntFor][len(aCols[nCntFor])] )
				dbSelectArea("CNE")
				Reclock("CNE",.T.)
					For nCntFor2 := 1 To nUsado
						If ( aHeader[nCntFor2][10] != "V" ) .And. aHeader[nCntFor2,2] # "CNE_PEDIDO"
							FieldPut(FieldPos(aHeader[nCntFor2][2]),aCols[nCntFor][nCntFor2])
							If Alltrim(aHeader[nCntFor2,2]) == "CNE_VLTOT"
								CNE->CNE_VLTOT := A410Arred(aCols[nCntFor][nCntFor2],If(cEspCtr=="1","C7_TOTAL","C6_VALOR"))
							EndIf
						EndIf
					Next nCntFor2

					CNE->CNE_FILIAL := cFilCod
					CNE->CNE_NUMERO := CND->CND_NUMERO
					CNE->CNE_NUMMED := CND->CND_NUMMED
					CNE->CNE_REVISA := CND->CND_REVISA
					CNE->CNE_CONTRA := CND->CND_CONTRA

					If CNE->(Columnpos('CNE_VLLIQD')) > 0
						If CNE->CNE_EXCEDE == '1'
							CNE->CNE_VLLIQD := CNE->CNE_VLTOT
						Else
							CNE->CNE_VLLIQD := CN130Liq(cEspCtr, CNE->CNE_VLTOT, CNE->CNE_VLDESC, CND->CND_VLTOT, nTotMultas, nTotBoni, CND->CND_DESCME, CND->CND_RETCAC, CND->CND_TOTADT)
						EndIf
					EndIf

				MsUnlock()

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Executa lancamento do PCO ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				PcoDetLan("000355","02","CNTA120")
			EndIf
		Next

		CN130GrvDesc(aDescs,aHeadDcs,nOpc)

		If Len(aRatGCT) > 0
			GravaCNZ(aRatGCT,iif(!lAuto,oGetDados,),nOpc,,,,aHeader,aCols,,,cFilCTR)
		Endif

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Efetua a gravacao das multas / bonificacoes associadas ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		For nLoop := 1 to Len( aMultas )
			RecLock( "CNR", .T. )
				CNR->CNR_FILIAL := xFilial( "CNR" )
				CNR->CNR_NUMMED := CND->CND_NUMMED
				CNR->CNR_CONTRA := CND->CND_CONTRA
				CNR->CNR_TIPO   := aMultas[ nLoop, 1 ]
				CNR->CNR_DESCRI := aMultas[ nLoop, 2 ]
				CNR->CNR_VALOR  := aMultas[ nLoop, 3 ]
				CNR->CNR_MODO   := aMultas[ nLoop, 4 ]
				CNR->CNR_FLGPED := aMultas[ nLoop, 5 ]
				CNR->CNR_CODIGO := aMultas[ nLoop, 6 ]
			CNR->( MsUnlock() )
		Next nLoop

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Processa os Adiantamentos                              ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If Len(aAdiants) > 0
			CnGrvAdia(aAdiants, nOpc)
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Filtra itens gravados no banco                 ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
      	While ( GetSX8Len() > nSaveSX8 )
		   ConfirmSX8()
		EndDo

		End Transaction

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Valida controle de alcada                      ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If (GetNewPar("MV_CNMDALC","N") == "S" )
			If Len(aRatGCT) > 0
				aRatGCT := {}
			Endif
			aAdd(aCampos, {CND->CND_NUMMED,"MD",CND->CND_VLTOT,"","",CND->CND_APROV,"",CND->CND_MOEDA,0,CND->CND_DTINIC})
			lAlc := GCTAlcEnt(,,1,"MD",CND->CND_NUMMED,CND->CND_REVISA,aCampos)
			If !lAlc
			RecLock("CND",.F.)
				CND->CND_ALCAPR := Iif(lAlc,"L","B")
			    CND->CND_SITUAC := Iif(lAlc,CND->CND_SITUAC,"B")
			MsUnlock("CND")
			EndIf
		EndIf

		If nTipo == 2
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Gera pedido de compra   ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			Processa( {|| CN120MedEnc( CND->( RECNO() ),.T.,.T. ) } )
		EndIf
	Case nOpc == 4 .Or. nOpc == 13 //Alteracao ou Excedente pos encerramento
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Exclui documento de alcada                     ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If (GetNewPar("MV_CNMDALC","N") == "S" )
       	aAdd(aCampos,{CND->CND_NUMMED,"MD",CND->CND_VLTOT,,,CND->CND_APROV,,CND->CND_MOEDA,,CND->CND_DTINIC})
			GCTAlcEnt(,,3,"MD",CND->CND_NUMMED,CND->CND_REVISA,aCampos)
		End

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Filtra itens gravados no banco                 ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cQuery := "SELECT CNE.CNE_ITEM, CNE.CNE_PEDIDO, CNE.R_E_C_N_O_ as RECNO "
		cQuery += "  FROM "+RetSQLName("CNE")+" CNE "
		cQuery += " WHERE CNE.CNE_FILIAL = '"+xFilial("CNE")+"'"
		cQuery += "   AND CNE.CNE_NUMMED = '"+CND->CND_NUMMED+"'"
		cQuery += "   AND CNE.CNE_REVISA = '"+CND->CND_REVISA+"'"
		cQuery += "   AND CNE.D_E_L_E_T_ = ''"

		cQuery := ChangeQuery(cQuery)
		dbUseArea( .t., "TOPCONN", TcGenQry( ,,cQuery ), "TRBCNE", .f., .t. )

		cFilCod := xFilial("CND")
		dbSelectArea("CND")
		dbSetorder(1)
		dbSeek(cFilCod+CND->CND_CONTRA+CND->CND_REVISA+CND->CND_NUMERO+CND->CND_NUMMED)

		If nTipo == 2
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Estorna pedido de compra   ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If !Empty(CND->CND_PEDIDO)
				Processa( {|| lRet := CN120MedEst( CND->( RECNO() ) , 2 , .F.,.T. ) } )
			EndIf
	    EndIf

		If lRet
			Begin Transaction
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Altera cabecalho                               ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			Reclock("CND",.F.)
				For nCntFor := 1 To FCount()
					If (FieldName(nCntFor)!="CND_FILIAL")
						If (FieldName(nCntFor)!="CND_RETCAC" )
							FieldPut(nCntFor,M->&(FieldName(nCntFor)))
						EndIf
					Else
						CND->CND_FILIAL := cFilCod
					EndIf
				Next nCntFor
				CND->CND_VLPREV:= M->CND_VLPREV
				CND->CND_VLTOT := M->CND_VLTOT
				CND->CND_DESCME:= M->CND_DESCME
				CND->CND_TOTADT:= M->CND_TOTADT
			   	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Preenche o valor retido na medicao             ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				CND->CND_RETCAC:= If(nCaucVlr!=Nil,nCaucVlr,0)
			MsUnlock()

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Executa lancamento do PCO ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			PcoDetLan("000355","01","CNTA120")

			dbSelectArea("CNE")
			nUsado := Len(aHeader)
			cFilCod := xFilial("CNE")

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Altera itens                                   ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			While !TRBCNE->(Eof())
				dbSelectArea("CNE")
				CNE->( dbGoTo(TRBCNE->RECNO) )

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Grava itens ja encerrados em um vetor para que nao     ³
				//³sejam atualizados quando da utilizacao da rotina de    ³
				//³excedente.                                             ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If nOpc == 13 .And. !Empty(TRBCNE->CNE_PEDIDO) .And. !Empty(CND->CND_DTFIM)
					aAdd(aListEnce,TRBCNE->CNE_ITEM)
				Else
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Exclui lancamento do PCO  ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					PcoDetLan("000355","02","CNTA120",.T.)

					RecLock("CNE",.F.)
					dbDelete()
					MsUnlock()
				EndIf
				TRBCNE->(dbSkip())
			EndDo

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Grava itens da medicao                         ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			For nCntFor := 1 To Len(aCols)
				If ( !aCols[nCntFor][nUsado+1] ) .And. aScan(aListEnce,aCols[nCntFor,nPosiItem]) == 0
					dbSelectArea("CNE")

					Reclock("CNE",.T.)
						For nCntFor2 := 1 To nUsado
							If ( aHeader[nCntFor2][10] != "V" ) .And. aHeader[nCntFor2,2] # "CNE_PEDIDO"
								FieldPut(FieldPos(aHeader[nCntFor2][2]),aCols[nCntFor][nCntFor2])
							EndIf
						Next nCntFor2
						CNE->CNE_FILIAL := cFilCod
						CNE->CNE_NUMERO := CND->CND_NUMERO
						CNE->CNE_NUMMED := CND->CND_NUMMED
						CNE->CNE_REVISA := CND->CND_REVISA
						CNE->CNE_CONTRA := CND->CND_CONTRA

						If CNE->(Columnpos('CNE_VLLIQD')) > 0
							If CNE->CNE_EXCEDE == '1'
								CNE->CNE_VLLIQD := CNE->CNE_VLTOT
							Else
								CNE->CNE_VLLIQD := CN130Liq(cEspCtr, CNE->CNE_VLTOT, CNE->CNE_VLDESC, CND->CND_VLTOT, nTotMultas, nTotBoni, CND->CND_DESCME, CND->CND_RETCAC, CND->CND_TOTADT)
							EndIf
						EndIf
					MsUnlock()

					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Executa lancamento do PCO ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					PcoDetLan("000355","02","CNTA120")
				EndIf
			Next

			CN130GrvDesc(aDescs,aHeadDcs,nOpc)
			GravaCNZ(aRatGCT,iif(!lAuto,oGetDados,),nOpc,,,,aHeader,aCols,,,cFilCTR)

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Filtra multas / bonificacoes                   ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

			cAliasCNR := GetNextAlias()

			cQuery := "SELECT CNR.R_E_C_N_O_ RECNO "
			cQuery += "  ,CNR.CNR_CONTRA "
			cQuery += "  FROM "+RetSQLName("CNR")+" CNR "
			cQuery += " WHERE CNR.CNR_FILIAL = '"+xFilial("CNR")+"'"
			cQuery += "   AND CNR.CNR_NUMMED = '"+CND->CND_NUMMED+"'"
			cQuery += "   AND CNR.D_E_L_E_T_ = ''"

			cQuery := ChangeQuery(cQuery)
			dbUseArea( .t., "TOPCONN", TcGenQry( ,,cQuery ), cAliasCNR, .f., .t. )

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Exclui multas / bonificacoes                   ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

			While !( cAliasCNR )->(Eof())
				CNR->( dbGoto( ( cAliasCNR )->RECNO ) )
				If !Empty(( cAliasCNR )->CNR_CONTRA) .And. (( cAliasCNR )->CNR_CONTRA) <> CND->CND_CONTRA
					( cAliasCNR )->( dbSkip() )
					Loop
				EndIf
				RecLock("CNR", .F.)
				CNR->( dbDelete() )
				CNR->( MsUnlock() )
				( cAliasCNR )->(dbSkip())
			EndDo

			CNR->( FKCommit() )

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Efetua a gravacao das multas / bonificacoes associadas ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

			For nLoop := 1 to Len( aMultas )
				RecLock( "CNR", .T. )
					CNR->CNR_FILIAL := xFilial( "CNR" )
					CNR->CNR_NUMMED := CND->CND_NUMMED
					CNR->CNR_CONTRA := CND->CND_CONTRA
					CNR->CNR_TIPO   := aMultas[ nLoop, 1 ]
					CNR->CNR_DESCRI := aMultas[ nLoop, 2 ]
					CNR->CNR_VALOR  := aMultas[ nLoop, 3 ]
					CNR->CNR_MODO   := aMultas[ nLoop, 4 ]
					CNR->CNR_FLGPED := aMultas[ nLoop, 5 ]
					CNR->CNR_CODIGO := aMultas[ nLoop, 6 ]
					CNR->( MsUnlock() )
			Next nLoop

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Processa os Adiantamentos                              ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If Len(aAdiants) > 0
				CnGrvAdia(aAdiants, nOpc)
			EndIf

			End Transaction

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Valida controle de alcada                      ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If (GetNewPar("MV_CNMDALC","N") == "S" )
				lAlc := MaAlcDoc({CND->CND_NUMMED,"MD",CND->CND_VLTOT,,,CND->CND_APROV,,CND->CND_MOEDA,,CND->CND_DTINIC},,1)

				RecLock("CND",.F.)
					CND->CND_ALCAPR := Iif(lAlc,"L","B")
				    CND->CND_SITUAC := Iif(lAlc,CND->CND_SITUAC, "B")
				MsUnlock("CND")
			EndIf

			If nTipo == 2
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Limpa o codigo do pedido   ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				RecLock("CND",.F.)
					CND->CND_PEDIDO := CriaVar("CND_PEDIDO")
				MsUnlock()
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Gera pedido de compra   ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				Processa( {|| CN120MedEnc( CND->( RECNO() ),.T.,.T. ) } )
			EndIf


		Else
			Aviso( "CNTA130", STR0083, { STR0046 }, 2 )//"Não foi possível estornar o pedido de compra, as alterações não foram salvas"
		EndIf

		TRBCNE->(dbCloseArea())//Fecha arquivo de trabalho
	Case nOpc == 5 //Exclusao
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Exclui documento de alcada                     ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If (GetNewPar("MV_CNMDALC","N") == "S" )
       		aAdd(aCampos,{CND->CND_NUMMED,"MD",CND->CND_VLTOT,,,CND->CND_APROV,,CND->CND_MOEDA,,CND->CND_DTINIC})
			GCTAlcEnt(,,3,"MD",CND->CND_NUMMED,CND->CND_REVISA,aCampos)
		End

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Filtra itens gravados no banco                 ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cQuery := "SELECT CNE.CNE_ITEM,CNE.R_E_C_N_O_ as RECNO "
		cQuery += "  FROM "+RetSQLName("CNE")+" CNE "
		cQuery += " WHERE CNE.CNE_FILIAL = '"+xFilial("CNE")+"'"
		cQuery += "   AND CNE.CNE_NUMMED = '"+CND->CND_NUMMED+"'"
		cQuery += "   AND CNE.CNE_REVISA = '"+CND->CND_REVISA+"'"
		cQuery += "   AND CNE.D_E_L_E_T_ = ''"

		cQuery := ChangeQuery(cQuery)
		dbUseArea( .t., "TOPCONN", TcGenQry( ,,cQuery ), "TRBCNE", .f., .t. )

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Filtra planilhas			                 ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cQuery := "SELECT CXN.CXN_NUMPLA,CXN.R_E_C_N_O_ as RECNO "
		cQuery += "  FROM "+RetSQLName("CXN")+" CXN "
		cQuery += " WHERE CXN.CXN_FILIAL = '"+xFilial("CXN")+"'"
		cQuery += "   AND CXN.CXN_NUMMED = '"+CND->CND_NUMMED+"'"
		cQuery += "   AND CXN.D_E_L_E_T_ = ''"
		cQuery := ChangeQuery(cQuery)
		dbUseArea( .t., "TOPCONN", TcGenQry( ,,cQuery ), "TRBCXN", .f., .t. )

		dbSelectArea("CNQ")
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Filtra descontos                               ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cQuery := "SELECT CNQ.R_E_C_N_O_ as RECNO "
		cQuery += "  FROM "+RetSQLName("CNQ")+" CNQ "
		cQuery += " WHERE CNQ.CNQ_FILIAL = '"+xFilial("CNQ")+"'"
		cQuery += "   AND CNQ.CNQ_NUMMED = '"+CND->CND_NUMMED+"'"
		cQuery += "   AND CNQ.D_E_L_E_T_ = ''"

		cQuery := ChangeQuery(cQuery)
		dbUseArea( .t., "TOPCONN", TcGenQry( ,,cQuery ), "TRBCNQ", .f., .t. )

		If nTipo == 2
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Estorna pedido de compra   ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If !Empty(CND->CND_PEDIDO)
				Processa( {|| lRet := CN120MedEst( CND->( RECNO() ) , 2 , .F., .T. ) } )
			EndIf
		EndIf


		If lRet
			Begin Transaction

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Exclui descontos                               ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			dbSelectArea("CNQ")
			While !TRBCNQ->(Eof())
				dbGoto(TRBCNQ->RECNO)
				RecLock("CNQ", .F.)
					dbDelete()
				MsUnlock()
				TRBCNQ->(dbSkip())
			EndDo


			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Filtra multas / bonificacoes                   ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

			cAliasCNR := GetNextAlias()

			cQuery := "SELECT CNR.R_E_C_N_O_ RECNO "
			cQuery += "  ,CNR.CNR_CONTRA "
			cQuery += "  FROM "+RetSQLName("CNR")+" CNR "
			cQuery += " WHERE CNR.CNR_FILIAL = '"+xFilial("CNR")+"'"
			cQuery += "   AND CNR.CNR_NUMMED = '"+CND->CND_NUMMED+"'"
			cQuery += "   AND CNR.D_E_L_E_T_ = ''"

			cQuery := ChangeQuery(cQuery)
			dbUseArea( .t., "TOPCONN", TcGenQry( ,,cQuery ), cAliasCNR, .f., .t. )

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Exclui multas / bonificacoes                   ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

			While !( cAliasCNR )->(Eof())
				CNR->( dbGoto( ( cAliasCNR )->RECNO ) )
				If !Empty(( cAliasCNR )->CNR_CONTRA) .And. (( cAliasCNR )->CNR_CONTRA) <> CND->CND_CONTRA
					( cAliasCNR )->( dbSkip() )
					Loop
				EndIf
				RecLock("CNR", .F.)
				CNR->( dbDelete() )
				CNR->( MsUnlock() )
				( cAliasCNR )->(dbSkip())
			EndDo

			CNR->( FkCommit() )

			//- Exclui Planilhas
			dbSelectArea("CXN")
			While !TRBCXN->(Eof())
				dbGoto(TRBCXN->RECNO)
				RecLock("CXN", .F.)
					dbDelete()
				MsUnlock()
				TRBCXN->(dbSkip())
			EndDo

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Exclui itens                                   ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			dbSelectArea("CNE")
			While !TRBCNE->(Eof())
				dbGoto(TRBCNE->RECNO)
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Executa lancamento do PCO ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				PcoDetLan("000355","02","CNTA120",.T.)
				RecLock("CNE", .F.)
					dbDelete()
				MsUnlock()
				TRBCNE->(dbSkip())
			EndDo

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Atualiza os Descontos                          ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			CnGrvAdia(,nOpc)

			GravaCNZ(aRatGCT,iif(!lAuto,oGetDados,),nOpc,,,,aHeader,aCols,,,cFilCTR)

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Executa lancamento do PCO ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			PcoDetLan("000355","01","CNTA120",.T.)

			RecLock("CND", .F.)
				dbDelete()
			MsUnLock()
			End Transaction
		Else
			Aviso( "CNTA130", STR0083, { STR0046 }, 2 )//"Não foi possível estornar o pedido de compra, as alterações não foram salvas"
		EndIf

		//Finaliza arquivos de trabalho
		TRBCNE->(dbCloseArea())
		TRBCNQ->(dbCloseArea())
		TRBCXN->(dbCloseArea())
		aListBox:={}
End Case

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Ponto de entrada executado após a gravação da Medição ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If ExistBlock("CN130PGRV")
	ExecBlock("CN130PGRV",.F.,.F.,{nOpc})
EndIf
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN130TotMed³ Autor ³ Marcelo Custodio      ³ Data ³09.02.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Atualiza total da medicao                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN130TotMed(nExp01)                                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ nExp01 - Informa campo atual do usuario 1 - quantidade      ³±±
±±³          ³                                         2 - percentual      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                             ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function CN130TotMed(nField,lDelete)
Local nPosVu:= 0
Local nPosDc:= 0
Local nPosDv:= 0
Local nPosQt:= 0
Local nPosQl:= 0
Local nPosQo:= 0
Local nPosVo:= 0
Local nPosTo:= 0
Local nDcTot:= TamSx3("CND_VLTOT")[2]
Local nx    := 0
Local ny    := If(lAuto,n,oGetDados:nAt)
Local nTotal:= 0
Local nTamVlTot := TamSx3("CNE_VLTOT")[2]
Local lFixo := .T.

Local cReadVar := ""
Local xConteudo:= ""
Local nArredMed:= 0

Default lDelete := .F.

If !(nField==5)
	 cReadVar := ReadVar()
	 xConteudo:= &(cReadVar)
Else
	If lDelete
		aCols[ny,Len(aCols[ny])]:=!aCols[ny,Len(aCols[ny])]
	EndIf
EndIf


lServico := Iif(Type("lServico")=='L',lServico,.F.)

If !lAuto
	aCols   := oGetDados:aCols
	aHeader := oGetDados:aHeader
EndIf

nPosVu:= aScan(aHeader,{|x| x[2] == "CNE_VLUNIT"})
nPosDc:= aScan(aHeader,{|x| x[2] == "CNE_PDESC "})
nPosDv:= aScan(aHeader,{|x| x[2] == "CNE_VLDESC"})
nPosQt:= aScan(aHeader,{|x| x[2] == "CNE_QUANT "})
nPosQl:= aScan(aHeader,{|x| x[2] == "CNE_QTDSOL"})
nPosTo:= aScan(aHeader,{|x| x[2] == "CNE_VLTOT "})

M->CND_VLTOT := 0

If lServico
	nPosVo:= aScan(aHeader,{|x| x[2] == "CNE_VUNORI"})
	nPosQo:= aScan(aHeader,{|x| x[2] == "CNE_QTDORI"})
EndIf

For nX:=1 to len(aCols)
	If !aCols[nx,len(aHeader)+1]
		If nx==ny
			Do Case
				Case nField == 1//Campo quantidade
					If cEspCtr == "2"
						FtDescItem(0,@aCols[nX,nPosVu],@xConteudo,@aCols[nX,nPosTo],@aCols[nX,nPosDc],@aCols[nX,nPosDv],0,1,,)
						M->CND_VLTOT += Round(aCols[nX,nPosTo],nTamVlTot)
					Else
						M->CND_VLTOT += Round(((M->CNE_QUANT* aCols[nx,nPosVu])-NoRound((M->CNE_QUANT*aCols[nx,nPosVu])*(aCols[nx,nPosDc]/100),TamSx3("CNE_VLDESC")[2])),nTamVlTot)
					EndIf

				Case nField == 2//Campo percentual
					If cEspCtr == "2"
						If !lServico
							FtDescItem(0,@aCols[nX,nPosVu],(aCols[nX,nPosQl]*@xConteudo)/100,@aCols[nX,nPosTo],@aCols[nX,nPosDc],@aCols[nX,nPosDv],0,1,,)
						Else
							FtDescItem(0,@aCols[nX,nPosVo],(aCols[nX,nPosQl]*@xConteudo)/100,@aCols[nX,nPosTo],@aCols[nX,nPosDc],@aCols[nX,nPosDv],0,1,,)
						EndIf
						M->CND_VLTOT += aCols[nX,nPosTo]
					Else
						If !lServico
							M->CND_VLTOT += Round((((M->CNE_PERC*aCols[nx,nPosQl])/100)*aCols[nx,nPosVu])-Iif((((M->CNE_PERC*aCols[nx,nPosQl])/100)*aCols[nx,nPosVu])>0,NoRound((((aCols[nx,nPosQl]*M->CNE_PERC)/100)*aCols[nx,nPosVu])*(aCols[nx,nPosDc]/100),TamSx3("CNE_VLDESC")[2]),0),nTamVlTot)
						Else
							M->CND_VLTOT += Round((((M->CNE_PERC*aCols[nx,nPosQl])/100)*aCols[nx,nPosVo])-Iif((((M->CNE_PERC*aCols[nx,nPosQl])/100)*aCols[nx,nPosVo])>0,NoRound((((aCols[nx,nPosQl]*M->CNE_PERC)/100)*aCols[nx,nPosVo])*(aCols[nx,nPosDc]/100),TamSx3("CNE_VLDESC")[2]),0),nTamVlTot)
						EndIf
					EndIf

				Case nField == 3//Campo vlunit
					If cEspCtr == "2"
						If !lServico
							FtDescItem(0,@xConteudo,@aCols[nX,nPosQt],@nTotal,@aCols[nX,nPosDc],@aCols[nX,nPosDv],0,1,,)
						Else
							FtDescItem(0,@aCols[nx,nPosVo],(@xConteudo/@aCols[nX,nPosVo]),@nTotal,@aCols[nX,nPosDc],@aCols[nX,nPosDv],0,1,,)
						EndIf

						M->CND_VLTOT += nTotal
					Else
						M->CND_VLTOT += Round((aCols[nx,nPosQt]*M->CNE_VLUNIT)-NoRound((M->CNE_VLUNIT*aCols[nx,nPosQt])*(aCols[nx,nPosDc]/100),TamSx3("CNE_VLDESC")[2]),nTamVlTot)
					EndIf

				Case nField == 4//Desconto
					If cEspCtr == "2"
						FtDescItem(0,@aCols[nX,nPosVu],@aCols[nX,nPosQt],@nTotal,@xConteudo,@aCols[nX,nPosDv],0,1,,)

						M->CND_VLTOT += nTotal
					Else
						M->CND_VLTOT += Round((aCols[nx,nPosQt]*aCols[nx,nPosVu])-NoRound((aCols[nx,nPosqt]*aCols[nx,nPosVu])*(M->CNE_PDESC/100),TamSx3("CNE_VLDESC")[2]),nTamVlTot)
					EndIf

				Case nField == 5//Excluido
						M->CND_VLTOT += Round((aCols[nx,nPosQt]*aCols[nx,nPosVu])-NoRound((aCols[nx,nPosqt]*aCols[nx,nPosVu])*(aCols[nx,nPosDc]/100),TamSx3("CNE_VLDESC")[2]),nTamVlTot)

				Case nField == 6//Campo vltotal
					If cEspCtr == "2"
						If !lServico
							FtDescItem(0,@aCols[nX,nPosVu],(@xConteudo/@aCols[nX,nPosVu]),@nTotal,@aCols[nX,nPosDc],@aCols[nX,nPosDv],0,1,,)
						Else
							FtDescItem(0,@aCols[nX,nPosVo],(@xConteudo/@aCols[nX,nPosVo]),@nTotal,@aCols[nX,nPosDc],@aCols[nX,nPosDv],0,1,,)
						EndIf
						M->CND_VLTOT += nTotal
					Else
						M->CND_VLTOT += Round(M->CNE_VLTOT-NoRound((aCols[nx,nPosqt]*aCols[nx,nPosVu])*(aCols[nx,nPosDc]/100),TamSx3("CNE_VLDESC")[2]),nTamVlTot)
					EndIf

			End Case
		Else
			If cEspCtr == "2"
				If !lServico
					FtDescItem(0,@aCols[nx,nPosVu],@aCols[nX,nPosQt],0,@aCols[nX,nPosDc],@nTotal,0,1,,)
				Else
					FtDescItem(0,@aCols[nx,nPosVo],@aCols[nX,nPosQo],0,@aCols[nX,nPosDc],@nTotal,0,1,,)
				EndIf

				M->CND_VLTOT += Round((aCols[nx,nPosQt]*aCols[nx,nPosVu])-NoRound(nTotal,TamSx3("CNE_VLDESC")[2]),nTamVlTot)
			Else
				M->CND_VLTOT += Round((aCols[nx,nPosQt]*aCols[nx,nPosVu])-NoRound((aCols[nx,nPosqt]*aCols[nx,nPosVu])*(aCols[nx,nPosDc]/100),TamSx3("CNE_VLDESC")[2]),nTamVlTot)
			EndIf

		EndIf
	EndIf
Next

// Verifica se contrato e planilha é Fixo
lFixo := Cn300RetSt("FIXO",0,CNA->CNA_NUMERO,,,.F.)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Arredonda valor da medição de acordo com saldo do contrato ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
// Verifica se o valor da medição irá ultrapassar o saldo do contrato
If M->CND_VLTOT > CN9->CN9_SALDO .And. lFixo //Se o contrato for Flexivel, não tem saldo... Logo, o saldo do contrato sempre será zero
	nArredMed := Round(M->CND_VLTOT,2) - CN9->CN9_SALDO
	If nArredMed <= 0.02 // Verifica se a diferença é de até 2 centavos
		M->CND_VLTOT -= nArredMed
	Endif
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Atualiza valor da caucao     ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If nCaucVlr != Nil
	If cEspCtr == "1"
		nCaucVlr:=(((M->CND_VLTOT-nTotMedDsc-nTotMedMlt+nTotMedBnf)*nCaucRet)/100)
	Else
		nCaucVlr:=(((M->CND_VLTOT-nTotMedDsc+nTotMedMlt-nTotMedBnf)*nCaucRet)/100)
	EndIf

	If !lAuto
		oGetCauc:Refresh()
	EndIf
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Atualiza valor total da medicao          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If cEspCtr == "1"
		nTotVlMed := M->CND_VLTOT - M->CND_DESCME - M->CND_TOTADT - nTotMultas + nTotBoni - (If(nCaucVlr!=Nil,nCaucVlr,0))
	Else
		nTotVlMed := M->CND_VLTOT - M->CND_DESCME - M->CND_TOTADT + nTotMultas - nTotBoni - (If(nCaucVlr!=Nil,nCaucVlr,0))
	EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Altera componente visual     ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If !lAuto
	oGetTot:Refresh()
	oGetVlMed:Refresh()
EndIf

//Tratamento especifico na exclusao da Medicao de Contrato Flexivel
If (nField==5) .And. lDelete
	aCols[ny,Len(aCols[ny])]:=!aCols[ny,Len(aCols[ny])]
EndIf


Return .T.

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ CN130LinOk³ Autor ³ Marcelo Custodio      ³ Data ³ 28.11.2005 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Valida item da planilha                                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN130LinOK(oExp01)                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ oExp01 - Estrutura da linha                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ CNTA130                                                       ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function CN130LinOk()

Local lRet       := .T.
Local lRet1      := .T.
Local lAtualiza    := .F.
Local lCN130VTOT := ExistBlock("CN130VTOT")
Local lCN130VLIN := ExistBlock("CN130VLIN")

Local uRet       := .T.

Local aCols      := If(lAuto,aCols,ogetDados:aCols)

Local nX         := 0
Local nCont      := 1
Local nPosQtde   := aScan(If(lAuto,aHeader,ogetDados:aHeader),{|x| x[2] == "CNE_QUANT "})
Local nPosVUni   := aScan(If(lAuto,aHeader,ogetDados:aHeader),{|x| x[2] == "CNE_VLUNIT"})
Local nPosVTot   := aScan(If(lAuto,aHeader,ogetDados:aHeader),{|x| x[2] == "CNE_VLTOT "})
Local nPosTE     := aScan(If(lAuto,aHeader,ogetDados:aHeader),{|x| x[2] == "CNE_TE    "})
Local nPosTS     := aScan(If(lAuto,aHeader,ogetDados:aHeader),{|x| x[2] == "CNE_TS    "})
Local nPosProd   := aScan(If(lAuto,aHeader,ogetDados:aHeader),{|x| x[2] == "CNE_PRODUT"})
Local nPosPedTit := aScan(If(lAuto,aHeader,ogetDados:aHeader),{|x| x[2] == "CNE_PEDTIT"})

Local nPosConta	 := aScan(If(lAuto,aHeader,ogetDados:aHeader),{|x| x[2] == "CNE_CONTA "})
Local nPosItemCt := aScan(If(lAuto,aHeader,ogetDados:aHeader),{|x| x[2] == "CNE_ITEMCT"})
Local nPosCLVL   := aScan(If(lAuto,aHeader,ogetDados:aHeader),{|x| x[2] == "CNE_CLVL  "})
Local nPosCC   	 := aScan(If(lAuto,aHeader,ogetDados:aHeader),{|x| x[2] == "CNE_CC    "})

Local nTamTot    := TamSX3("CNE_VLTOT")[2]
Local nDif       := 10**(-nTamTot)
Local nDiferenca := 0

//Valida Alteração de nQtde
If Altera
	M->CNE_QUANT := aCols[N,nPosQtde]
	lRet := CN130VldQtd(.T.)
EndIf

If(lRet)	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Valida linha dos itens   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	For nX := 1 to len(aCols)
	
	    If lCN130VTOT
		    uRet := ExecBlock("CN130VTOT",.F.,.F.,{})
			lRet1:=	If(Valtype(uRet)=="L",uRet,.T.)
			//Se não existir o PE: CN130VLIN a validação padrão de total será executada mesmo que o PE: CN130VTOT
			//esteje com .F. para não validar.
			If !lRet1 .And. !lCN130VLIN
				lRet1:= .T.
			EndIf
		EndIf
	
	    //Valida amarração contábil
	    lRet := CtbAmarra(IIF(nPosConta > 0 ,aCols[nX][nPosConta],""),IIF(nPosCC > 0 ,aCols[nX][nPosCC],""),IIF(nPosItemCt > 0 ,aCols[nX][nPosItemCt],""),IIF(nPosCLVL > 0 ,aCols[nX][nPosCLVL],""))
	    If !lRet
	    	Exit
	    EndIf
	
	    If lRet1
			nDiferenca := (Round(aCols[nX][nPosQtde]*aCols[nX][nPosVUni],nTamTot) - Round(aCols[nX][nPosVTot],nTamTot))
			If  nDiferenca <> 0 .And. (nDiferenca < nDif .Or. nDiferenca > nDif )
				Aviso("CNTA130",STR0080,{STR0046})//"Valor total inválido!"
				lRet := .F.
				Exit
			EndIf
		EndIf
	Next
	
	//Valida a medicao de contrato Flexivel
	If !lFixo
		If !Empty(M->CND_CLIENT)
			//Valida Tipo Saida
			If lRet .And. ((nPosPedTit > 0 .And. aCols[n][nPosPedTit] == "1" .And. Empty(aCols[n][nPosTS])).Or. Empty(aCols[n][nPosProd])  )
				Help (" ",1,"CNTA130TS3")//"Os campos Produto, Quantidade, Valor Unitário, Un. Medida ou TES estão em Branco.  "
				lRet := .F.
			EndIf
		Else
			//Valida Produto
			If lRet .And. Empty(aCols[n][nPosProd])
				Help (" ",1,"CNTA130TE2")//"Os campos Produto, Quantidade, Valor Unitário, Un. Medida ou TES estão em Branco.  "
				lRet := .F.
			EndIf
		EndIF
	
	EndIf
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Chama ponto de entrada para validacoes especificas ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lRet .And. ExistBlock("CN130VLIN")
		uRet := ExecBlock("CN130VLIN",.F.,.F.,{aCols[n],aHeader})
		lRet :=	If(Valtype(uRet)=="L",uRet,lRet)
	EndIf
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Atualiza componente visual     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	While nCont <= Len(aCols) .And. !lAtualiza
		If aCols[nCont][Len(aHeader)+1]
			CN130TotMed(5)
			lAtualiza := .T.
		EndIf
		nCont++
	End
EndIf

Return lRet


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN130TudOk³ Autor ³ Marcelo Custodio      ³ Data ³09.02.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Valida Getdados                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN130TudOk()                                               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³         ATUALIZACOES SOFRIDAS DESDE A CONSTRU€AO INICIAL.             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Programador ³ Data   ³ BOPS ³  Motivo da Alteracao                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³            ³        ³      ³                                          ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function CN130TudOk(aCols)

Local lRet		:= .T.
Local aCols		:= If(lAuto,aCols,ogetDados:aCols)
Local aRatGCT	:= Iif(Type("aAuxRat")=='A',aAuxRat,{})

Local nX
Local nPosQt	:= aScan(If(lAuto,aHeader,ogetDados:aHeader),{|x| x[2] == "CNE_QUANT "})
Local nPosIt	:= aScan(If(lAuto,aHeader,ogetDados:aHeader),{|x| x[2] == "CNE_ITEM  "})
Local nPosProd	:= aScan(If(lAuto,aHeader,ogetDados:aHeader),{|x| x[2] == "CNE_PRODUT"})
Local nPosVUni	:= aScan(If(lAuto,aHeader,ogetDados:aHeader),{|x| x[2] == "CNE_VLUNIT"})
Local nPosVTot	:= aScan(If(lAuto,aHeader,ogetDados:aHeader),{|x| x[2] == "CNE_VLTOT "})
Local nPPedTit	:= aScan(If(lAuto,aHeader,ogetDados:aHeader),{|x| x[2] == "CNE_PEDTIT"})
Local nCodNe	:= aScan(If(lAuto,aHeader,ogetDados:aHeader),{|x| Trim(x[2]) == "CNE_CODNE"})
Local nItenNe	:= aScan(If(lAuto,aHeader,ogetDados:aHeader),{|x| Trim(x[2]) == "CNE_ITEMNE"})
Local nPosTES 	:= 0
Local lZerad  	:= (M->CND_ZERO == "1")
Local lVldPrd 	:= ( GetNewPar("MV_CNVLAMR","N") == "S" )
Local cFilSA5 	:= xFilial("SA5")
Local cFilSB1 	:= xFilial("SB1")
Local cFilSAD 	:= xFilial("SAD")
Local aMedEmp	:= {}
Local lNotaEmp	:= SuperGetMV("MV_NOTAEMP",.F.,.F.)

If !lAuto
	aCols := oGetDados:aCols
Endif


If cEspCtr=="2"  //Valida se for contrato do Tipo Vendas
	nPosTES := aScan(If(lAuto,aHeader,ogetDados:aHeader),{|x| x[2] == "CNE_TS    "})
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Valida itens de acordo com a opcao zerada da medicao³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
For nX := 1 to len(aCols)
	If !aCols[Len(aCols)][Len(aHeader)+ 1]

		If (lZerad .And. aCols[nX][nPosQt]>0)// .Or. (!lZerad .And. aCols[nX][nPosQt]==0)
			Aviso("CNTA130",STR0010+aCols[nX][nPosIt],{STR0046})//"Quantidade inválida no item "
			lRet := .F.
			Exit
		EndIf

		If lRet .AND. !Cn300RetSt("FIXO",0,M->CND_NUMERO,M->CND_CONTRA,cFilCTR,.F.) .And. !lZerad .And. (aCols[nX][nPosQt] == 0 .Or. aCols[nX][nPosVUni] == 0 .Or. aCols[nX][nPosVTot] == 0)
			Aviso("CNTA130",STR0109+cValToChar(nX))
			lRet := .F.
			Exit
		EndIf

		If lRet .And. !lZerad .And. M->CND_VLTOT == 0
			lRet := .F.
			MsgAlert(STR0008)//"Medição zerada!"
		EndIf

		 //Valida se for contrato do Tipo Vendas e possui TES Vinculado ao produto
		If lRet .And. nPPedTit > 0 .And. aCols[nX,nPPedTit] == '1'
			If nPosTES > 0
				If Empty(aCols[nX][nPosTES]) .AND. aCols[nX][nPosQt] > 0 //Valida se a quantidade do item é maior que 0 para inclusão da TES
					If lFixo
						Do Case
						Case INCLUI
							Aviso("CNTA130",STR0088,{STR0046})//Produto não possui TES vinculada. Vincule o Produto a TES através do Cadastro de Produtos."
							lRet := .F.
							Exit
						Case ALTERA
							Aviso("CNTA130",STR0089,{STR0046})//"Produto não possui TES vinculada. Exclui essa medição, vincule o Produto a TES através do Cadastro de Produtos e inclua essa medição novamente."
							lRet := .F.
							Exit
						EndCase
					Else
						Help (" ",1,"A410NOTES")
						lRet := .F.
						Exit
					EndIf
				EndIf
			Else
				If cEspCtr=="2"
					SB1->( dbSetOrder( 1 ) )
					dbSelectArea("SB1")
					If MSSeek(xFilial("SB1")+aCols[nX][nPosProd])
					   If Empty(SB1->B1_TS)
						   	Aviso("CNTA130",STR0088,{STR0046})
					   		lRet := .F.
					   		Exit
					   EndIf
					EndIf
				EndIf
			EndIf
		EndIf

		If lRet .And. lVldPrd .And. !Empty(M->CND_FORNEC+M->CND_LJFORN)
			dbSelectArea("SA5")
			dbSetOrder(1)
			dbGoTop()

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Valida amarração Fornecedor X Produto ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			lProdFr := dbSeek(cFilSA5+M->CND_FORNEC+M->CND_LJFORN+aCols[nX][nPosProd])
			If !lProdFr
				dbSelectArea("SB1")
				dbSetOrder(1)
				If dbSeek(cFilSB1+aCols[nX][nPosProd])
					dbSelectArea("SAD")
					dbSetOrder(1)
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Valida amarração Fornecedor X Grupo de Produto ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					lProdFr := dbSeek(cFilSAD+M->CND_FORNEC+M->CND_LJFORN+SB1->B1_GRUPO)
				EndIf
			EndIf

			If !lProdFr
				Aviso(STR0056,STR0074+AllTrim(aCols[nX][nPosIt])+STR0075,{ STR0046 },2)//"O produto informado no item "###" não está amarrado ao fornecedor informado. Verifique a amarração produto X fornecedor."
				lRet := .F.
				Exit
			EndIf
		EndIf

		If lRet
			n := nX
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Valida lancamento do PCO ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If !(lRet := PcoVldLan('000355','02','CNTA120',/*lUsaLote*/,/*lDeleta*/, .T./*lVldLinGrade*/))
				Exit
			EndIf
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Verifica se o usuario tem permissao. 				 ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If lRet
			If !(lRet := MaAvalPerm(1,{aCols[nX][nPosProd],"CNT120",If(INCLUI,3,If(ALTERA,4,5))}))
				Help(,,1,'SEMPERM')
			EndIf
		EndIf
	EndIf

	If lRet .And. !(Empty(CN9->CN9_CODED)) .And. lNotaEmp .And. (Empty(Acols[nX][nCodNe]) .Or. Empty(Acols[nX][nItenNe]))
		dbSelectArea("CX0")
		dbSetOrder(2)
		If dbseek(xFilial("CX0")+CN9->CN9_CODED+CN9->CN9_NUMPR)
			Help("",1,STR0044,,STR0108,4,1)
			lRet := .F.
			Exit
		EndIf
	EndIf

Next

If cEspCtr=="2" .And. lRet
	dbSelectArea("SE4")
	dbSetOrder(1)
	MsSeek(xFilial("SE4")+M->CND_CONDPG)

	If SE4->E4_TIPO=='9'
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Verifica a Condicao de Pagamento Tipo 9                                 ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If !cn130VldCnd9()
			lRet  := .F.
		EndIf
	EndIf
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Valida lancamento do PCO ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lRet
	lRet := PcoVldLan('000355','01','CNTA120',/*lUsaLote*/,/*lDeleta*/, .F./*lVldLinGrade*/)
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Verifica a revisao atual do contrato se a situacao e revisao            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lRet
	CN9->(dbSeek(xFilial("CN9")+M->CND_CONTRA+"ZZZ",.T.))
	CN9->(dbSkip(-1))

	If CN9->CN9_SITUAC==DEF_SREVS
		lRet := .F.
		Help( " ", 1, "CNTA120_02" )//"Apenas contratos em vigência podem ser medidos"
	EndIf

EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Executa ponto de entrada para validacao ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lRet .And. ExistBlock("CN130TOK")
	uRet := ExecBlock("CN130TOK",.F.,.F.,{aRatGCT})

	If valtype(uRet) == "L"
		lRet := uRet
	EndIf
EndIf

If lRet .and. lNotaEmp
	CN130MdEmp(aCols,@aMedEmp)
	lRet := ShowDivNe(aMedEmp,.F.)
EndIf

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN130VldMed³ Autor ³ Marcelo Custodio      ³ Data ³09.02.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Manutencao de Medicoes                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN130VldMed(cExp01,cExp02,cExp03,cExp04,lExp05,aExp06)      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ cExp01 - Codigo do Contrato                                 ³±±
±±³          ³ cExp02 - Codigo da Revisao                                  ³±±
±±³          ³ cExp03 - Codigo da Planilha                                 ³±±
±±³          ³ cExp03 - Competencia                                        ³±±
±±³          ³ lExp04 - Medicao Eventual                                   ³±±
±±³          ³ aExp05 - Multas                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³         ATUALIZACOES SOFRIDAS DESDE A CONSTRU€AO INICIAL.              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Programador ³ Data   ³ BOPS ³  Motivo da Alteracao                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³            ³        ³      ³                                           ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function CN130VldMed(cContra,cRevisa,cPlan,cCompet,lMedeve,aMultas)

Local nX
Local nVlMultas := 0

Local lRet       := .T.
Local lZerMed    := (M->CND_ZERO == "1")//Medicao Zerada
Local lCn130VAD  := ExistBlock("CN130VAD")
Local lRetVAD    := .T.

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Obtem o valor de multa das medicoes           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
nVlMultas := 0
AEval( aMultas, { |x| nVlMultas += ( x[3] * If( x[1] == "1", 1, -1 ) ) } )

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Valida total do desconto                      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If Empty(M->CND_FORNEC) //Contrato de venda
	If lRet .And. (M->CND_VLTOT + nVlMultas ) < M->CND_DESCME
		lRet := .F.
		Aviso( STR0051, STR0052, { STR0053 }, 2 ) // "Atencao","O valor resultante de descontos nao pode ultrapassar o total de medicoes !","Ok"
	EndIf
Else //Contrato de compra
	If lRet .And. M->CND_VLTOT < ( M->CND_DESCME + nVlMultas )
		lRet := .F.
		Aviso( STR0051, STR0052, { STR0053 }, 2 ) // "Atencao","O valor resultante de descontos nao pode ultrapassar o total de medicoes !","Ok"
	EndIf
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Ponto de entrada na validação no Adiantamento do Contrato ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lCn130VAD
	lRetVAD := If(Valtype(lRetVAD:=ExecBlock("CN130VAD",.F.,.F.))=="L",lRetVAD,.T.)
EndIf

If lRet .And. lRetVAD .And. (M->CND_VLTOT < (M->CND_TOTADT))
	lRet := .F.
	Aviso (STR0056, STR0072, { STR0058 }, 2 ) // "Atencao!", "Os Adiantamentos não podem ultrapassar o total das medições/entregas", { "Ok" }
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Valida se a medicao nao possui itens preenchidos³
//³ quando nao for zerada                           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lRet .And. lZerMed .And. M->CND_VLTOT > 0
	lRet := .F.
	MsgAlert(STR0008)//"Medição zerada!"
EndIf

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN130VldQtd³ Autor ³ Marcelo Custodio      ³ Data ³09.02.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Valida quantidade informada na medicao                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN130VldQtd()                                               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³         ATUALIZACOES SOFRIDAS DESDE A CONSTRU€AO INICIAL.              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Programador ³ Data   ³ BOPS ³  Motivo da Alteracao                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³            ³        ³      ³                                           ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function CN130VldQtd(lLinhaok)

Local nx       := If(lAuto,n,oGetDados:nAt)
Local nPosQSol := aScan(aHeader,{|x| x[2] == "CNE_QTDSOL"})
Local nPosQMed := aScan(aHeader,{|x| x[2] == "CNE_QTAMED"})
Local nPosMExc := aScan(aHeader,{|x| x[2] == "CNE_EXCEDE"})
Local nTotal   := 0
Local nPosItem := aScan(aHeader,{|x| Alltrim(x[2]) == "CNE_ITEM"})
Local lArrefat := (SuperGetMv("MV_ARREFAT",.F.,"S")== "S")
Local lRet := .T.
Default lLinhaok := .F.

If M->CND_ZERO == "1"
	//-- Verifica se a quantidade e igual a zero quando a medicao for zerada
	If !(lRet := (M->CNE_QUANT == 0))
		Help(" ",1,"CN130VLQTD",,STR0115,1,1) //- 'Medições zeradas não possuem quantidade.'
	EndIf
ElseIf nPosQMed > 0 	//-- Verifica se a quantidade e menor que o saldo disponivel
	lRet := aCols[nx,nPosMExc] == '1' 
	If !lRet
		If Altera
			If CNB->(MsSeek(xFilial("CNB",cFilCTR)+M->CND_CONTRA+M->CND_REVISA+M->CND_NUMERO+aCols[nx,nPositem]) )
				If  aCols[nx,nPosQMed] > CNB->CNB_SLDMED
					aCols[nx,nPosQMed] := CNB->CNB_SLDMED
				EndIf
			EndIf
		EndIf
	
		lRet := (M->CNE_QUANT <= aCols[nx,nPosQMed])
	EndIf
	
	If !lRet
  		nTotal := M->CNE_QUANT- aCols[nx,nPosQMed]
		If nTotal <= (1/10 ^ TamSX3(aHeader[nPosQMed,2])[2]) .And. !lArrefat
		   lRet := .T.
		Else
			Help(" ",1,"CN130VLQTD",,STR0116,1,1) //- 'Quantidade informada ultrapassa o saldo disponivel.'
		EndIf
	EndIf
EndIf

If lRet .And. !lLinhaok
	CN130TotMed(1)
EndIf

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN130VlTot ³ Autor ³ Felipe Bittar         ³ Data ³13.01.2009³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Valida valor total informado na medicao                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN130VlTot()                                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³         ATUALIZACOES SOFRIDAS DESDE A CONSTRU€AO INICIAL.              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Programador ³ Data   ³ BOPS ³  Motivo da Alteracao                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³            ³        ³      ³                                           ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function CN130VlTot()

Local lRet     := .T.
Local lArrefat := (SuperGetMv("MV_ARREFAT",.F.,"S")== "S")
Local nx   := If(lAuto,n,oGetDados:nAt)
Local nPosQMed := aScan(aHeader,{|x| x[2] == "CNE_QTAMED"})
Local nPosVlUn := aScan(aHeader,{|x| x[2] == "CNE_VLUNIT"})
Local nPosQOri := aScan(aHeader,{|x| x[2] == "CNE_QTDORI"})
Local nPosVOri := aScan(aHeader,{|x| x[2] == "CNE_VUNORI"})
Local nPosVlTt := aScan(aHeader,{|x| x[2] == "CNE_VLTOT "})
Local nPosMExc := aScan(aHeader,{|x| x[2] == "CNE_EXCEDE"})

Local nQuant   := 0
Local nTotal   := 0

If M->CND_ZERO == "1"
	//-- Verifica se o total e igual a zero quando a medicao for zerada
	If !(lRet := (M->CNE_VLTOT == 0))
		Help(" ",1,"CN130VLTOT",,STR0117,1,1) //- 'Medições zeradas não possuem valor.'
	EndIf
Else
	//-- Verifica se a quantidade e menor que o saldo disponivel                                      ³
	If nPosQMed > 0
		If M->CND_SERVIC == '2'
			nQuant := M->CNE_VLTOT / aCols[nx,nPosVOri]
			lRet   := (nQuant <= aCols[nx,nPosQMed])
		Else
			nQuant := Round(M->CNE_VLTOT/aCols[nx,nPosVlUn],TamSX3("CNE_QUANT")[2])
			lRet   := aCols[nx,nPosMExc] == '1' .Or. (nQuant <= aCols[nx,nPosQMed])
		EndIf

		If !lRet
			nTotal := nQuant - aCols[nx,nPosQMed]

			If nTotal<=(1/10 ^ TamSX3(aHeader[nPosQMed,2])[2]) .And. !lArrefat
				lRet := .T.
			Else
				Help(" ",1,"CN130VLTOT",,STR0118,1,1) //- 'O valor informado ultrapassa o saldo disponivel.'
			EndIf
		EndIf
	EndIf

EndIf

If lRet
	CN130TotMed(6)
EndIf

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN130VldPerc³ Autor ³ Marcelo Custodio      ³ Data ³09.02.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Valida percentual informado nas medicoes                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CNTA120()                                                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³         ATUALIZACOES SOFRIDAS DESDE A CONSTRU€AO INICIAL.               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Programador ³ Data   ³ BOPS ³  Motivo da Alteracao                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³            ³        ³      ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function CN130VldPerc()

Local lRet     := .T.
Local lArrefat := (SuperGetMv("MV_ARREFAT",.F.,"S")== "S")

Local nPosQSol := aScan(aHeader,{|x| x[2] == "CNE_QTDSOL"})
Local nPosQMed := aScan(aHeader,{|x| x[2] == "CNE_QTAMED"})
Local nPosQExc := aScan(aHeader,{|x| x[2] == "CNE_EXCEDE"})
Local nx 	   := If(lAuto,n,oGetDados:nAt)
Local nTotal   := 0

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Calcula percentual disponivel                   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Local nPercMed := (aCols[nx,nPosQSol]-aCols[nx,nPosQMed])*100/aCols[nx,nPosQSol]

//-- Se excedente não permite digitar percentual
If nPosQExc > 0 .And. aCols[nX,nPosQExc] == '1'
	Aviso(STR0051,STR0093,{STR0046}) //"Este campo não deve ser utilizado para itens classificados como excedente."
	lRet := .F.
ElseIf M->CND_ZERO == "1"
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Quando a medicao for zerada o percentual deve   ³
	//³ ser igual a zero                                ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	lRet := (M->CNE_PERC == 0)
Else
	lRet := (M->CNE_PERC <= (100-nPercMed))
	If !lRet
		nTotal := M->CNE_PERC -(100-nPercMed)

		If nTotal<=0.001 .And. !lArrefat
		   lRet := .T.
		EndIf
	EndIf
EndIf

If lRet
	CN130TotMed(2)
EndIf

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN130VldDtEnt³ Autor ³ Marcelo Custodio      ³ Data ³09.02.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Valida data de entrada informada nas medicoes                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN130VldDtEnt()                                               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³         ATUALIZACOES SOFRIDAS DESDE A CONSTRU€AO INICIAL.                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Programador ³ Data   ³ BOPS ³  Motivo da Alteracao                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³            ³        ³      ³                                             ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function CN130VldDtEnt()
Local lRet := .T.

lRet := (M->CNE_DTENT >= dDataBase) .And. (M->CNE_DTENT <= CN9->CN9_DTFIM)

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao    ³CN130Track³ Autor ³ Sergio Silveira       ³ Data ³22/03/2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Faz o tratamento da chamada do System Tracker              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T.                                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function CN130Track(aHeader,aCols)

Local aEnt     := {}
Local aAreaCND := CND->(GetArea())
Local aAreaCNE := CNE->(GetArea())
Local cKey     := M->CND_FILCTR + M->CND_CONTRA + M->CND_REVISA + M->CND_NUMMED

Local nLoop    := 0
If !Empty(xFilial("CNE"))
	cKey     := M->CND_FILCTR + M->CND_CONTRA + M->CND_REVISA + M->CND_NUMMED
Else
 	cKey     := M->CND_CONTRA + M->CND_REVISA + M->CND_NUMMED
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Percorre o acols                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
For nLoop := 1 To Len( aCols )
	AAdd( aEnt, { "CND20", cKey} )
Next nLoop

MaTrkShow( aEnt )

RestArea( aAreaCND )
RestArea( aAreaCNE )

CN130Manut("CND",aAreaCND[3],2,,CND->CND_CONTRA,CND->CND_REVISA,,,,,,,.F.)

Return( .T. )

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao    ³CN130GrvDesc³ Autor ³ Marcelo Custodio      ³ Data ³06/07/2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Executa a gravacao dos descontos informados na revisao       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T.                                                          ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function CN130GrvDesc(aDescs,aHeadDcs,nOpc)

Local cFilCod:=xFilial("CNQ")

Local nx
Local ny
Local nPosTpD	:= aScan(aHeadDcs,{|x| x[2]=="CNQ_TPDESC"})
Local nPosVal 	:= aScan(aHeadDcs,{|x| AllTrim(x[2])=="CNQ_VALOR"})
Local nPosRec 	:= aScan(aHeadDcs,{|x| AllTrim(x[2])=="CNQ_REC_WT"})
Local nUsado 	:= len(aHeadDcs)

dbSelectArea("CNQ")
dbSetOrder(1)

For nx:=1 to len(aDescs)
	If !aDescs[nx,nUsado+1] .And. !Empty(aDescs[nx,nPosTpD]) .And. aDescs[nx,nPosVal] > 0
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Verifica se existe desconto                 ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If nOpc!=3 .And. nOpc!=9 .And. nOpc!=12 .And. nPosRec > 0 .And. !Empty(aDescs[nX][nPosRec])
			CNQ->(dbGoTo(aDescs[nX][nPosRec]))
			RecLock("CNQ",.F.)
		Else
			RecLock("CNQ",.T.)
		EndIf

		For ny:=1 to nUsado
			If ( aHeadDcs[ny][10] != "V" )
				FieldPut(FieldPos(aHeadDcs[ny,2]),aDescs[nx,ny])
			EndIf
		Next
		CNQ->CNQ_CONTRA := M->CND_CONTRA
		CNQ->CNQ_NUMMED := M->CND_NUMMED
		CNQ->CNQ_FILIAL := cFilCod
		CNQ->CNQ_NUMPLA := M->CND_NUMERO
		msUnlock()
	ElseIf aDescs[nx,nUsado+1]
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Apaga desconto                              ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If nOpc!=3 .And. nOpc!=9 .And. nOpc!=12 .And. dbSeek(cFilCod+M->CND_NUMMED+aDescs[nx,nPosTpD])
			RecLock("CNQ",.F.)
				dbDelete()
			MsUnlock()
		EndIf
	EndIf
Next

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao    ³CN130VldDes ³ Autor ³ Marcelo Custodio      ³ Data ³06/07/2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Rotina de validacao dos descontos                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T.                                                          ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function CN130VldDes(oGetDadDe)

Local lRet   	:= .T.
Local lRetU	 	:= .T.
Local lEmpty 	:= .F.
Local lRepetido := .F.

Local aColDE	:= oGetDadDe:aCols
Local aHeaDE 	:= oGetDadDe:aHeader

Local nPosDc 	:= aScan(aHeaDE,{|x| x[2]=="CNQ_TPDESC"})
Local nPosVl 	:= aScan(aHeaDE,{|x| x[2]=="CNQ_VALOR "})
Local nPos   	:= oGetDadDe:nAt
Local nI	 	:= 0

if !Empty(aColDE[nPos,nPosDc])
	If !aColDE[nPos][len(aHeaDE) + 1]
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Varre descontos                             ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		For nI:= 1 To Len( aColDE )
			If ( nI != nPos ) .and. !aColDE[nI][len(aHeaDE) + 1]
				If aColDE[nI,nPosDc] == aColDE[nPos,nPosDc]
					lRepetido := .T.
					Exit
				Endif
			Endif
			If Empty(aColDE[nI,nPosVl])
				lEmpty:=.T.
				Exit
			EndIf
		Next nI

		If lRepetido
			lRet:=.F.
			Help(" ",1,"JAGRAVADO")
		End
		If lEmpty
			lRet:=.F.
			Aviso("CNTA130",STR0016,{STR0046})
		EndIf
	Endif
EndIf

//-- Executa ponto de entrada para validação do usuário
If lRet .And. (ExistBlock("CN130USRVD"))
	lRetU := ExecBlock("CN130USRVD",.F.,.F.,{aHeadDE,aColsDE})
	If ValType(lRetU) == "L"
		lRet := lRetU
	EndIf
EndIf

Return lRet


/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³CN130Multas³ Autor ³ Sergio Silveira      ³ Data ³11/04/2006 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³Selecao e aplicacao de multas do modulo SIGAGCT              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³A103Multas( ExpD1, ExpC2, ExpC3, ExpA4 )                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpD1 -> Data de emissao                                    ³±±
±±³          ³ ExpC2 -> Codigo do fornecedor                               ³±±
±±³          ³ ExpC3 -> Loja do fornecedor                                 ³±±
±±³          ³ ExpA4 -> Array de multas do documento de entrada            ³±±
±±³          ³ ExpN5 -> Total de multas                                    ³±±
±±³          ³ ExpN6 -> Total de bonificacoes                              ³±±
±±³          ³ ExpC7 -> Numero do contrato                                 ³±±
±±³          ³ ExpC8 -> Revisao do contrato                                ³±±
±±³          ³ ExpO9 -> Objeto Multas		                               ³±±
±±³          ³ ExpOA -> Objeto Bonificações                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T.                                                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ Materiais                                                   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function CN130Multas( aMultas, aCols, aHeader, nOpc, nTotMultas, nTotBoni, cContrato, cRevisao, oGetMultas, oGetBoni, cPlan)

Local aArea      := GetArea()
Local aListBox   := {}
Local aMedicoes  := {}

Local cQuery     := ""
Local cAliasQry  := ""
Local cMulManual := CN300RETST("MULMAN",0,cPlan,,cFilCTR,.F.)

Local nOpca      := 0
Local nLoop      := 0

Local lProcessa  := .F.
Local lAltera    := ( nOpc == 3 .or. nOpc == 4 .or. nOpc == 9 .or. nOpc=12)
Local lMultaBoni := CN300RETST("TPMULT",0,cPlan,,cFilCTR,.F.) == '2'
Local lPermMulta := .F.
Local lCn130Vld  := 	ExistBlock("CN130VLDMT")
Local lRet

Local oOk        := LoadBitmap( GetResources(), "LBOK" )
Local oNOk       := LoadBitmap( GetResources(), "LBNO" )
Local oDlgMult
Local oList
Local oBold
Local oBmp
Local oBut1
Local oBut2

If lMultaBoni
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Monta o array de medicoes. Retira a ultima coluna do acols             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	For nLoop := 1 to Len( aCols )
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Verifica se a linha esta excluida                                      ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If !ATail( aCols[ nLoop ] )
			aLinhaACols := AClone( aCols[ nLoop ] )
			ASize( aLinhaACols, Len( aLinhaACols ) - 1 )
			AAdd( aMedicoes, aLinhaACols )
		EndIf
	Next nLoop

	If Empty( aMultas ) .And. lAltera
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Processa as multas                                                     ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		CN130ProcMul( aMedicoes, @aListBox, aHeader )
	Else
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Carrega as multas do array                                             ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		AEval( aMultas, { |x| AAdd( aListBox,  { .T., x[1], x[2], x[3], x[4], x[5] , x[6] } ) } )
	EndIf

    If Empty( aListBox )
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Se estiver vazio, preenche uma linha em branco                         ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		AAdd( aListBox, { .F., "", "", 0, "", "" , ""/* Codigo CN4 */ } )
	EndIf

	DEFINE MSDIALOG oDlgMult TITLE STR0050 FROM 0,0 TO 400, 700 OF oMainWnd PIXEL // "Selecao de multas / bonificacoes"
	DEFINE FONT oBold NAME "Arial" SIZE 0, -13 BOLD

	@  0, -25 BITMAP oBmp RESNAME STR0114 oF oDlgMult SIZE 55, 1000 NOBORDER WHEN .F. PIXEL
	@ 03, 40 SAY STR0050 FONT oBold PIXEL // "Selecao de multas / bonificacoes"
	@ 14, 30 TO 16 ,400 LABEL '' OF oDlgMult PIXEL

	If lAltera
		@ 24, 223 BUTTON STR0023 SIZE 35,11 ACTION CN130RepMult( oList, @aListBox, aMedicoes , aHeader ) OF oDlgMult PIXEL // "Reprocessar"
		@ 24, 265 BUTTON STR0024 SIZE 35,11 ACTION CN130AltMul(  oList, @aListBox, cMulManual ) OF oDlgMult PIXEL // "Alterar"
		@ 24, 307 BUTTON STR0025 SIZE 35,11 ACTION CN130AdMult(  oList, @aListBox, cMulManual ) OF oDlgMult PIXEL // "Adicionar"
	EndIf

	oList := TWBrowse():New( If( lAltera, 43, 30 ), 40, 303, If( lAltera, 125, 138 ),,{ "", STR0026, STR0027, STR0028, STR0029, STR0073 },,oDlgMult,,,,,,,,,,,,.F.,,.T.,,.F.,,,) // "Tipo", "Descricao", "Valor", "Insercao", "Interf. Ped."
	oList:SetArray(aListBox)
	oList:bLine := { || { If( aListBox[oList:nAT,1], oOk, oNOK ), If( aListBox[oList:nAt,2] == "1", STR0030, STR0031 ), aListBox[oList:nAT,3], Transform( aListBox[oList:nAT,4],"@E 999,999,999.99" ), If( aListBox[oList:nAT,5] == "1",STR0032,If( aListBox[oList:nAT,5] == "2", STR0033 ,"" ) ),If( aListBox[oList:nAT,6] == "1", OemToAnsi(STR0048) , OemToAnsi(STR0049) ) } } // "Multa","Bonificacao","Automatica","Manual"

	If lAltera
		oList:bLDblClick := { || aListBox[oList:nAt,1] := If( Empty( aListBox[ oList:nAt,3 ]), aListBox[oList:nAt,1],!aListBox[oList:nAt,1] ) }
	EndIf

	DEFINE SBUTTON oBut2 FROM 178, If( lAltera, 280, 312 ) TYPE 1 ACTION ( nOpca := 1, If(!lCn130Vld,oDlgMult:End(),(lRet:=ExecBlock("CN130VLDMT",.F.,.F.),If((valtype(lRet)=="L" .And. lRet),oDlgMult:End(),nOpca := 0))) )  ENABLE of oDlgMult

	If lAltera
		DEFINE SBUTTON oBut3 FROM 178, 312 TYPE 2 ACTION ( nOpca := 0, oDlgMult:End() )  ENABLE of oDlgMult
	EndIf

	ACTIVATE MSDIALOG oDlgMult CENTERED

	If nOpca == 1
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Carrega as multas no array aMultas                                     ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		aMultas    := {}
		nTotMultas := 0
		nTotBoni   := 0
		nTotMedMlt := 0
		nTotMedBnf := 0

		For nLoop := 1 to Len( aListBox )
			If aListBox[ nLoop, 1 ]
				AAdd( aMultas, { aListBox[nLoop,2],aListBox[nLoop,3], aListBox[nLoop,4], aListBox[nLoop,5], aListBox[nLoop,6] , aListBox[nLoop,7] } )

				If aListBox[ nLoop, 2 ] == "1"
					nTotMultas += aListBox[ nLoop, 4 ]
					//Soma as multas que interferem pedido
					If  aListBox[ nLoop, 6 ] == "1"
						nTotMedMlt += aListBox[ nLoop, 4 ]
					EndIf
				ElseIf aListBox[ nLoop, 2 ] == "2"
					nTotBoni   += aListBox[ nLoop, 4 ]
					//Soma as bonificacoes que interferem pedido
					If  aListBox[ nLoop, 6 ] == "1"
						nTotMedBnf += aListBox[ nLoop, 4 ]
					EndIf
				EndIf
			EndIf
		Next nLoop
	EndIf
Else
	If !lMultaBoni
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Restaura a integridade dos dados de entrada                            ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		Aviso( STR0056, STR0060, { STR0058 }, 2 ) // "Atencao!", "O tipo de contrato desta medicao nao permite o apontamento de multas ou bonificacoes neste momento !", { "Ok" }
	EndIf
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Restaura a integridade dos dados de entrada                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
RestArea( aArea )

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Refresh Objetos      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oGetMultas:Refresh()
oGetBoni:Refresh()

Return( .T. )

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³CN130AdMult³ Autor ³ Sergio Silveira      ³ Data ³11/04/2006 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³ Inclusao de multa avulsa - SIGAGCT                          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpO1 -> Objeto listbox                                     ³±±
±±³          ³ ExpA2 -> Array da listbox ( alimentado por referencia )     ³±±
±±³          ³ ExpC3 -> Configuracao de acesso para multas manuais         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T.                                                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ Materiais                                                   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function CN130AdMult( oList, aListBox, cMulManual )

Local cDescri   := Space( GetSx3Cache("CNR_DESCRI","X3_TAMANHO") )
Local cContrato := ""
Local cTipo     := ""
Local cPedFlag  := "1"
Local aPedFlag  := {STR0048, STR0049}//"Sim"##"Não"
Local aCN130TPC := {}

Local nValor    := 0
Local nOpca     := 0

Local oBut1
Local oBut2
Local oBmp
Local oBold
Local oDlgMult
Local oTipo
Local oPedFlag
Local oContrato

If cMulManual <> "1"

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ponto de entrada para alterar a descrição dos Tipos                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If ( ExistBlock("CN130TPC") )
		aCN130TPC := ExecBlock("CN130TPC",.F.,.F.,{cMulManual})
		If ( ValType(aCN130TPC) == "A" )
			aTipos := aClone(aCN130TPC)
		EndIf
	EndIf
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica a permissao de acesso para manipulacao manual                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Do Case
	Case cMulManual == "2"
		aTipos := iIf(Len(aCN130TPC) > 0, aClone(aCN130TPC),{ STR0034 }) // "Multa"
	Case cMulManual == "3"
		aTipos := iIf(Len(aCN130TPC) > 0, aClone(aCN130TPC),{ STR0035 }) // "Bonificacao"
	Case cMulManual == "4"
		aTipos := iIf(Len(aCN130TPC) > 0, aClone(aCN130TPC),{ STR0034, STR0035 }) // "Multa", "Bonificacao"
	EndCase

	DEFINE MSDIALOG oDlgMult TITLE STR0036 FROM 0,0 TO 280, 550 OF oMainWnd PIXEL // "Inclusao de multas / bonificacoes"

	DEFINE FONT oBold NAME "Arial" SIZE 0, -13 BOLD

	@  0, -25 BITMAP oBmp RESNAME STR0114 oF oDlgMult SIZE 55, 1000 NOBORDER WHEN .F. PIXEL

	@ 03, 40 SAY STR0037 FONT oBold PIXEL // "Inclusao de multas / bonificacoes avulsas"

	@ 14, 30 TO 16 ,400 LABEL '' OF oDlgMult   PIXEL

	@  30, 40 SAY STR0038 OF oDlgMult PIXEL // "Descricao"
	@  40, 40 GET cDescri SIZE 200, 11 VALID NaoVazio( cDescri ).And.cn130MulDesc(@cDescri,@nValor,@cTipo,@cPedFlag,1) PICTURE "@!" OF oDlgMult PIXEL

	@  60, 40 SAY STR0039 OF oDlgMult PIXEL // "Valor"
	@  70, 40 GET nValor SIZE 70, 11   VALID NaoVazio( nValor ) .And. Positivo( nValor ) PICTURE "@E 999,999,999.99" OF oDlgMult PIXEL

	@  90, 40 SAY STR0040 OF oDlgMult PIXEL // "Tipo"
	@ 100, 40 MSCOMBOBOX oTipo VAR cTipo ITEMS aTipos SIZE 100, 36 OF oDlgMult PIXEL

	@  90,145 SAY OemToAnsi(STR0073) OF oDlgMult PIXEL // "Interf. Ped."
	@ 100,145 MSCOMBOBOX oPedFlag VAR cPedFlag ITEMS aPedFlag SIZE 50, 36 OF oDlgMult PIXEL

	DEFINE SBUTTON oBut1 FROM 120, 207 TYPE 1 ACTION ( If( CN130VldMult( cDescri, nValor, aListBox, oList:nAt, 1 ),( nOpca := 1, cTipo := Str(oTipo:nAt,1), cPedFlag := Str(oPedFlag:nAt,1) , oDlgMult:End()), ) )  ENABLE of oDlgMult
	DEFINE SBUTTON oBut2 FROM 120, 239 TYPE 2 ACTION ( nOpca := 0, oDlgMult:End() )  ENABLE of oDlgMult

	ACTIVATE MSDIALOG oDlgMult CENTERED

	If nOpca == 1

		Do Case
		Case cMulManual == "2"
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ So permite multa                                                       ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			cTipo := "1"
		Case cMulManual == "3"
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ So permite bonificacao                                                 ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			cTipo := "2"
		EndCase

		If Len( aListBox ) == 1 .And. Empty( aListBox[ 1, 2 ] )
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Se tiver uma linha em branco, apaga                                    ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			aListBox := {}
		EndIf
		AAdd( aListBox, { .T., cTipo, cDescri, nValor, "2", cPedFlag ,""/*Campo CN4 */} )

		bLine := oList:bLine
		oList:SetArray(aListBox)
		oList:bLine := bLine

	EndIf

Else
	Aviso( STR0056, STR0059, { STR0058 }, 2 ) // "Atencao!", "A configuracao deste contrato nao permite a manipulacao manual de multas !", { "Ok"
EndIf

Return( .T. )

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³CN130AltMul³ Autor ³ Sergio Silveira      ³ Data ³05/05/2006 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³ Alterecao de multa - SIGAGCT                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpO1 -> Objeto listbox                                     ³±±
±±³          ³ ExpA2 -> Array da listbox ( alimentado por referencia )     ³±±
±±³          ³ ExpC3 -> Configuracao de acesso para multas manuais         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T.                                                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ Materiais                                                   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function CN130AltMul( oList, aListBox, cMulManual )

Local cDescri   := Space( 50 )
Local cContrato := ""
Local cTipo     := aListBox[ oList:nAt, 2 ]
Local aPedFlag  := {OemToAnsi(STR0048),OemToAnsi(STR0049)}//"Sim"##"Não"
Local cPedFlag  := ""
Local oPedFlag

Local nValor    := 0
Local nOpca     := 0

Local oBut1
Local oBut2
Local oBmp
Local oBold
Local oDlgMult
Local oContrato

If ( cMulManual == "4" ) .Or. ( cMulManual == "2" .And. cTipo == "1" ) .Or. ( cMulManual == "3" .And. cTipo == "2" )
	If !( Len( aListBox ) == 1 .And. Empty( aListBox[ 1, 2 ] ) )

		cDescri   := aListBox[ oList:nAt, 3 ]
		nValor    := aListBox[ oList:nAt, 4 ]

		DEFINE MSDIALOG oDlgMult TITLE STR0041 FROM 0,0 TO 240, 550 OF oMainWnd PIXEL // "Alteracao de multas / bonificacoes"

		DEFINE FONT oBold NAME "Arial" SIZE 0, -13 BOLD

		@  0, -25 BITMAP oBmp RESNAME STR0114 oF oDlgMult SIZE 55, 1000 NOBORDER WHEN .F. PIXEL

		@ 03, 40 SAY STR0041 FONT oBold PIXEL // "Alteracao de multas / bonificacoes"

		@ 14, 30 TO 16 ,400 LABEL '' OF oDlgMult   PIXEL

		@  30, 40 SAY STR0042 OF oDlgMult PIXEL // "Descricao"
		@  40, 40 GET cDescri SIZE 200, 11 VALID NaoVazio( cDescri ).And.cn130MulDesc(@cDescri,@nValor,@cTipo,@cPedFlag,2)  PICTURE "@!" OF oDlgMult PIXEL

		@  60, 40 SAY STR0043 OF oDlgMult PIXEL // "Valor"
		@  70, 40 GET nValor SIZE 70, 11   VALID NaoVazio( nValor ) .And. Positivo( nValor ) PICTURE "@E 999,999,999.99" OF oDlgMult PIXEL

		@ 60,145 SAY OemToAnsi(STR0073) OF oDlgMult PIXEL // "Afeta Pedido"
		@ 70,145 MSCOMBOBOX oPedFlag VAR cPedFlag ITEMS aPedFlag SIZE 50, 36 OF oDlgMult PIXEL

		oPedFlag:nAt := Val(aListBox[ oList:nAt, 6 ])

		DEFINE SBUTTON oBut1 FROM 100, 207 TYPE 1 ACTION ( If( CN130VldMult( cDescri, nValor, aListBox, oList:nAt, 2 ),( nOpca := 1, cPedFlag := Str(oPedFlag:nAt,1), oDlgMult:End()), ) )  ENABLE of oDlgMult
		DEFINE SBUTTON oBut2 FROM 100, 239 TYPE 2 ACTION ( nOpca := 0, oDlgMult:End() )  ENABLE of oDlgMult

		ACTIVATE MSDIALOG oDlgMult CENTERED

		If nOpca == 1
			aListBox[ oList:nAt, 3 ] := cDescri
			aListBox[ oList:nAt, 4 ] := nValor
			aListBox[ oList:nAt, 6 ] := cPedFlag

			bLine := oList:bLine
			oList:SetArray(aListBox)
			oList:bLine := bLine
		EndIf
	Else
		Aviso( STR0044, STR0045, { STR0046 } ) // "Atencao", "Este item nao pode ser alterado !", "Ok"
	EndIf
Else
	Aviso( STR0056, STR0057, { STR0058 }, 2 ) // "Atencao!", "O contrato vinculado a esta medicao nao permite a manipulacao deste movimento !", "Ok"
EndIf

Return( .T. )


/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³CN130VldMult³ Autor ³ Sergio Silveira     ³ Data ³11/04/2006 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³Validacao dos campos de descricao e valor - Inclusao de multa³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ExpL1 :=  CN130VldMult( ExpC2, ExpN3 )                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC2 -> Descricao da multa                                 ³±±
±±³          ³ ExpN3 -> Valor da multa                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ ExpL1 -> Validacao                                          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ Materiais                                                   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function CN130VldMult( cDescri, nValor, aListBox, nItem, nAcao )
Local uRet

lRet := !Empty( cDescri )

If lRet
	lRet := !Empty( nValor )
EndIf

If !lRet
	Help( " ", 1, "NVAZIO" )
EndIf

If lRet .And. ExistBlock("CN130MTINC")
	uRet := ExecBlock("CN130MTINC",.F.,.F.,{cDescri,nValor,aListBox,nItem,nAcao})

	If valtype(uRet) == "L"
		lRet := uRet
	EndIf
EndIf

Return( lRet )

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³CN130RepMult³ Autor ³ Sergio Silveira     ³ Data ³11/04/2006 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpO1 -> Objeto listbox                                     ³±±
±±³          ³ ExpA2 -> Array de multas do listbox                         ³±±
±±³          ³ ExpA3 -> Array de medicoes                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³                                                             ³±±
±±³          ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³Efetua o reprocessamento de multas das medicoes              ³±±
±±³          ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ Materiais                                                   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function CN130RepMult( oList, aListBox, aMedicoes, aHeader )

Local bLine := { || .T. }

If Aviso( STR0044, STR0047, { STR0048, STR0049 }, 2 ) == 1 // "Atencao !", "Os dados informados serao sobrepostos. Confirma o reprocessamento das multas / bonificacoes desta medicao ?", "Sim","Nao"

	aListBox := {}
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Efetua o reprocessamento                                               ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	CN130ProcMul( aMedicoes, @aListBox, aHeader )

   If Empty( aListBox )
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Se estiver vazio, preenche uma linha em branco                         ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		AAdd( aListBox, { .F., "", "", 0, "", "" , ""} )
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Reinicializa o listBox                                                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	bLine := oList:bLine
	oList:SetArray(aListBox)
	oList:bLine := bLine

EndIf

Return( Nil )

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³CN130ProcMul³ Autor ³ Sergio Silveira     ³ Data ³11/04/2006 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Efetua o processamento de multas                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ A103ProcMul( ExpA1, ExpA2 )                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpA1 -> Array contendo as medicoes                         ³±±
±±³          ³ ExpA2 -> Array do listbox de multas a ser preenchido        ³±±
±±³          ³          ( passado por referencia )                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ Nenhum                                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ Gestão de Contratos                                         ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function CN130ProcMul( aMedicoes, aListBox, aHeader )

Local cCronog    := ""

Local aListBoxAux:= {}
Local lFormula   := .F.

Local nLoop      := 0
Local nLoop2     := 0
Local nPos       := 0

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Percorre os itens das medicoes                                         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
For nLoop := 1 to Len( aMedicoes )
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Posiciona no contrato                                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	CN9->( dbSetOrder( 1 ) )
	CN9->( MsSeek( xFilial( "CN9" ,cFilCTR) + M->CND_CONTRA + M->CND_REVISA ) )

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Cria as variaveis de memoria dos itens das medicoes                    ³
	//³ as variaveis vao ser utilizadas na interpretacao das multas            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	For nLoop2 := 1 To Len( aHeader )
		M->&( aHeader[nLoop2, 2 ] ) := aMedicoes[ nLoop, nLoop2 ]
	Next nLoop2

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Posiciona o cabecalho da planilha                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	CNA->( dbSetOrder( 1 ) )
	CNA->( MsSeek( xFilial( "CNA" ,cFilCTR) + M->CND_CONTRA + M->CND_REVISA + M->CND_NUMERO ) )

    cCronog := CNA->CNA_CRONOG

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Posiciona no cronograma / competencia                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !Empty(M->CND_PARCEL)
		CNF->( dbSetOrder( 3 ) )
		CNF->( MsSeek( xFilial( "CNF" ,cFilCTR) + M->CND_CONTRA + M->CND_REVISA + cCronog + M->CND_PARCEL ) )
	Else
		CNF->( dbSetOrder( 2 ) )
		CNF->( MsSeek( xFilial( "CNF" ,cFilCTR) + M->CND_CONTRA + M->CND_REVISA + cCronog + M->CND_COMPET ) )
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Percorre as multas / bonificacoes deste contrato                       ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	CN130ReprMT(.F.,nLoop,@aListBox)
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Reposiciona tabela de Trabalho para demais itens da medição    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea( "CN4" )

Next nLoop

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Elimina Posição de trabalho do array - aListBox                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If Len(aListBox)>0
    For nLoop:=1 to len(aListBox)
    	AAdd(aListBoxAux,{aListbox[nLoop,1],aListbox[nLoop,2],aListbox[nLoop,3],aListbox[nLoop,4],aListbox[nLoop,5],aListbox[nLoop,6],aListbox[nLoop,7]})
    Next nLoop
    aListBox:= aListBoxAux
EndIf

Return


/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³CN130Adiant³ Autor ³ Robson Nayland       ³ Data ³20/10/2006 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³Selecao doa adiantamenentos do modulo SIGAGCT                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³CN130Adiant( ExpC1, ExpC2)                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 -> Numero do contrato                                 ³±±
±±³          ³ ExpC2 -> Numero do adiantamento                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T.                                                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ Gestão de Contratos                                         ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function CN130Adiant(cContra,cNumero,aCols,aHeader,nRotina,cContra2,cRevisa,nOper,aHeadCpos,aColsCpos)

Local aArea      := GetArea()

Local cQuery     := ""
Local cAliasQry  := ""

Local nOpca      := 0
Local nLoop      := 0
Local nX

Local lProcessa  := .F.
Local oOk        := LoadBitmap( GetResources(), "LBOK" )
Local oNOk       := LoadBitmap( GetResources(), "LBNO" )
Local oBold
Local oBmp
Local oBut1
Local oDlgMult

aHeadCpos := {}
CnRetAhd('CNX_NUMERO', @aHeadCpos)
CnRetAhd('CNX_DTADT', @aHeadCpos)
CnRetAhd('CNX_VLADT', @aHeadCpos)
CnRetAhd('CNX_SALDO', @aHeadCpos)
Aadd(aHeadCpos,{ 'Vlr Compensar', 'CNX_VLCOMP', '@E 9,999,999,999,999.99', 16, 2, 'CnVlComp()', '€€€€€€€€€€€€€€ ', 'N', 'CNX','R'} )

CN9->( dbSetOrder(1) )
CN9->( dbSeek(xFilial("CN9",cFilCTR)+M->CND_CONTRA+M->CND_REVISA ))

cEspCtr := CN9->CN9_ESPCTR


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica os adiantamentos do Contrato        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
cAliasQry := GetNextAlias()
cQuery := "SELECT CNX_FILIAL, CNX_CONTRA, CNX_NUMERO, CNX_DTADT, CNX_VLADT, CNX_NUMMED, CNX_SALDO + ISNULL(CZY.CZY_VALOR, 0) CNX_SLDATU ,CNX_SALDO, ISNULL(CZY.CZY_VALOR, 0) CNX_VLCOMP"
cQuery += "  FROM "+RetSqlName("CNX")+" CNX "
cQuery += "  LEFT JOIN " +  RetSqlName("CZY") +  " CZY ON  CZY.CZY_FILIAL = CNX.CNX_FILIAL AND CZY.CZY_CONTRA =  CNX.CNX_CONTRA  AND CZY.CZY_NUMERO = CNX.CNX_NUMERO  AND CZY.D_E_L_E_T_=' ' "
cQuery += "  AND CZY.CZY_NUMMED = '" + M->CND_NUMMED + "'"


cQuery += " WHERE CNX_FILIAL ='"+xFilial("CNX",cFilCTR)+"'"
cQuery += "   AND CNX_CONTRA ='"+M->CND_CONTRA+ "'"
cQuery += "   AND CNX_SALDO > 0 "
If nOper == 4
	cQuery += " OR CNX_NUMMED = '" + M->CND_NUMMED + "' AND "
Else
	cQuery += " AND "
EndIf

If cEspCtr == "1"
	cQuery += "CNX_FORNEC = '"+M->CND_FORNEC+"' AND "
	cQuery += "CNX_LJFORN = '"+M->CND_LJFORN+"' AND "
Else
	cQuery += "CNX_CLIENT = '"+M->CND_CLIENT+"' AND "
	cQuery += "CNX_LOJACL = '"+M->CND_LOJACL+"' AND "
EndIf
cQuery += " CNX.D_E_L_E_T_=' ' "
cQuery += " ORDER BY CNX_DTADT "

cQuery := ChangeQuery( cQuery )
dbUseArea( .T., "TOPCONN", TcGenQry( ,, cQuery ), cAliasQry, .F., .T. )

TCSetField(cAliasQry,"CNX_DTADT","D",08,0)
TCSetField(cAliasQry,"CNX_VLADT","N",TamSX3("CNX_VLADT")[1],TamSX3("CNX_VLADT")[2])

If  (cAliasQry )->( Eof())
     Aviso( STR0056, STR0071, { STR0058 }, 2 ) // "Atencao!", "Não ha Adiantamentos para esse Contrato" , { "Ok" }
     RestArea( aArea )
     Return( .T. )
Endif

If Len(aAdiants) == 0

	aColsAux := {}
	aColsCpos := {}

	While !( cAliasQry )->( Eof() )

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Avalia a aplicacao da multa                                            ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

		Aadd(aColsCpos, {( cAliasQRY )->CNX_NUMERO, ( cAliasQRY )->CNX_DTADT, ( cAliasQRY )->CNX_VLADT, ( cAliasQRY )->CNX_SALDO, ( cAliasQRY )->CNX_VLCOMP,.F.})
		Aadd(aColsAux, {( cAliasQRY )->CNX_SLDATU})

		( cAliasQry )->( dbSkip() )

	EndDo

EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Fecha a area de trabalho da query                                      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
( cAliasQRY )->( dbCloseArea() )

DEFINE MSDIALOG oDlgMult TITLE STR0066 FROM 0,0 TO 300, 700 OF oMainWnd PIXEL // "Adiantamento"
DEFINE FONT oBold NAME "Arial" SIZE 0, -13 BOLD
oSize := FwDefSize():New(.F.,,,oDlgMult)
oSize:AddObject( "GETDADOS",  100, 90, .T., .T. ) // Totalmente dimensionavel
oSize:AddObject( "BUTTONS",  100, 10, .T., .T. ) // Totalmente dimensionavel

oSize:lProp 	:= .T. // Proporcional
oSize:aMargins 	:= { 3, 3, 3, 3 } // Espaco ao lado dos objetos 0, entre eles 3

oSize:Process() 	   // Dispara os calculos

oGetAdia := MsNewGetDados():New(oSize:GetDimension("GETDADOS","LININI"),;
								oSize:GetDimension("GETDADOS","COLINI"),;
	     						oSize:GetDimension("GETDADOS","LINEND"),;
	     						oSize:GetDimension("GETDADOS","COLEND"),;
    							GD_UPDATE,;
    							,;
    							'CNAdTdOk',;
    							,;
    							{'CNX_VLCOMP'},;
    							,;
    							999,;
    							,;
    							,;
    							,;
    							oDlgMult,;
    							@aHeadCpos,;
    							@aColsCpos)

oDlgMult:Refresh()
DEFINE SBUTTON oBut1 FROM 135, 280  TYPE 1 ACTION ( nOpca := 1,If(oGetAdia:TudoOk(), (M->CND_TOTADT:=CnGetTotad(),oDlgMult:End()), .F.) )  ENABLE of oDlgMult
DEFINE SBUTTON oBut2 FROM 135, 310  TYPE 2 ACTION ( nOpca := 2,oDlgMult:End() )  ENABLE of oDlgMult
ACTIVATE MSDIALOG oDlgMult CENTERED

If nOpca == 1
	aAdiants 	:= aClone(CnRetTotAd())
	aColsCpos  := aClone(oGetAdia:aCols)
ElseIf nOpca == 2
	aColsCpos  := {}
	aAdiants 	:= {}
	aColsAux	:= {}
	If nOper == 3
		M->CND_TOTADT := 0
	EndIf
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Restaura a integridade dos dados de entrada                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
RestArea( aArea )

Return( .T. )

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³CN130MkCron  ºAutor  ³Robson Nayland      º Data ³  23/10/06º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Marca/Desmarca itens na TwBrowse .                          º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Gestão de Contratos                                        º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Function CN130MkCron()

Local nX         := 0
Local lCn130VCK  := ExistBlock("CN130VCK")
Local lRetVCK    := .T.

IF aListBox[oList:nAT,1]==.T.
   aListBox[oList:nAT,1]:=.F.
Else
   aListBox[oList:nAT,1]:=.T.
Endif

M->CND_TOTADT:=0
For nX := 1 to Len(aListBox)
	If aListBox[nX,1]
		M->CND_TOTADT += aListBox[nX,3]
	EndIf
Next nX

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Ponto de entrada na validação no Adiantamento do Contrato ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lCn130VCK
	lRetVCK := If(Valtype(lRetVCK:=ExecBlock("CN130VCK",.F.,.F.))=="L",lRetVCK,.T.)
EndIf

If lRetVCK
	If M->CND_TOTADT>M->CND_VLTOT
	    Aviso (STR0056, STR0072, { STR0058 }, 2 ) // "Atencao!", "Os Adiantamentos não podem ultrapassar o total das medições/entregas", { "Ok" }

	    If (!altera,M->CND_TOTADT:=0,M->CND_TOTADT:=nTotAdia2)
	    For nX := 1 to Len(aListBox)
			aListBox[nX,1] := .F.
	    Next nX
	    oList:Refresh()
	Endif
EndIf


oGetAdia:Refresh()

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³MarcDesm     ºAutor  ³Robson Nayland      º Data ³  23/10/06º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Marca/Desmarca todos os itens na TwBrowse .                 º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Gestão de Contratos                                        º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function MarcDesm( lTodos )

Local nX 		:= 0

For nX := 1 to Len(aListBox)
	If lTodos
		aListBox[nX,1] := .T.
	Else
		aListBox[nX,1] := .F.
	EndIf
Next nX

M->CND_TOTADT:=0

For nX := 1 to Len(aListBox)
	If aListBox[nX,1]
		M->CND_TOTADT += aListBox[nX,3]
	EndIf
Next nX
If M->CND_TOTADT>M->CND_VLTOT
    Aviso (STR0056, STR0072, { STR0058 }, 2 ) // "Atencao!", "Os Adiantamentos não podem ultrapassar o total das medições/entregas", { "Ok" }
    If (!altera,M->CND_TOTADT:=0,M->CND_TOTADT:=nTotAdia2)
    For nX := 1 to Len(aListBox)
		aListBox[nX,1] := .F.
    Next nX
    lTodos     := .F.
    oTodos:Refresh()
Endif

oGetAdia:Refresh()
oList:Refresh()

Return Nil

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³CN130RetDcr ³ Autor ³ Sergio Silveira     ³ Data ³27/04/2007 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Retorna descricao do produto                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN130RetDcr()                                               ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function CN130RetDcr()
Local cRet := ""

If !INCLUI
	cRet := Posicione("SB1",1,xFilial("SB1",CND->CND_FILCTR)+CNE->CNE_PRODUT,"B1_DESC")
EndIf

Return cRet

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³CN130RetGrp ³ Autor ³ Marcelo Custodio    ³ Data ³10/12/2007 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Retorna grupo de aprovacao do tipo de contrato              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN130RetGrp()                                               ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function CN130RetGrp()
Local cGrupo := Space(len(CND->CND_APROV))
Local cFilCtr := cFilAnt

If (GetNewPar("MV_CNMDALC","N") == "S" )
	dbSelectArea("CN9")
	CN9->(dbSetOrder(1))

	If CN9->(MsSeek(xFilial("CN9",cFilCTR)+M->CND_CONTRA+M->CND_REVISA))
		If !Empty(CN9->CN9_GRPAPR)
			cGrupo := CN9->CN9_GRPAPR
		ElseIf CN1->(dbSeek(xFilial("CN1")+alltrim(CN9->CN9_TPCTO)))
			cGrupo := CN1->CN1_GRPAPR
		EndIf
	EndIf
EndIf

Return cGrupo

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³CN130Moeda  ³ Autor ³ Felipe Bittar       ³ Data ³29/08/2008 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Atualiza os valores da medicao com base na moeda selecionada³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN130Moeda()                                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ X3_VALID do campo CND_MOEDA                                 ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function CN130Moeda()

Local cCronog	:= ""

Local nPosItem	:= 0
Local nPosVuni	:= 0
Local nPosQtde	:= 0
Local nPosVtot	:= 0
Local nPosDesc	:= 0
Local nPosPdes	:= 0
Local nDecPrv	:= 0
Local nDecVuni	:= 0
Local nX		:= 0
Local nTaxa

nPosItem := aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_ITEM"})
nPosVuni := aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_VLUNIT"})
nDecVuni := TamSX3("CNE_VLUNIT")[2]
nPosQtde := aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_QUANT"})
nPosVtot := aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_VLTOT"})
nPosDesc := aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_VLDESC"})
nPosPdes := aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_PDESC"})
nDecPrev := TamSX3("CND_VLPREV")[2]

dbSelectArea("CNA")
dbSetOrder(1)
If MsSeek(xFilial("CNA",cFilCTR)+CN9->CN9_NUMERO+CN9->CN9_REVISA+M->CND_NUMERO)
	cCronog := CNA_CRONOG
	dbSelectArea("CNF")
	dbSetOrder(3)
	If MsSeek(xFilial("CNF",cFilCTR)+CN9->CN9_NUMERO+CN9->CN9_REVISA+cCronog+M->CND_PARCEL)
		nTaxa := CNF_TXMOED
		M->CND_VLPREV := xMoeda(CNF_VLPREV-CNF_VLREAL,CN9->CN9_MOEDA,M->CND_MOEDA,dDataBase,nDecPrev,nTaxa)
	EndIf
EndIf

dbSelectArea("CNB")
dbSetOrder(1)
For nx:=1 to len(oGetDados:aCols)
	If MsSeek(xFilial("CNB",cFilCTR)+CN9->CN9_NUMERO+CN9->CN9_REVISA+M->CND_NUMERO+oGetDados:aCols[nx,nPosItem])
		oGetDados:aCols[nx,nPosVuni] := xMoeda(CNB_VLUNIT,CN9->CN9_MOEDA,M->CND_MOEDA,dDataBase,nDecVuni,nTaxa)
		oGetDados:aCols[nx,nPosVtot] := oGetDados:aCols[nx,nPosVuni] * oGetDados:aCols[nx,nPosQtde]
		oGetDados:aCols[nx,nPosDesc] := oGetDados:aCols[nx,nPosVtot] * oGetDados:aCols[nx,nPosPdes] / 100
	EndIf
Next

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Atualiza valor total da medicao          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
CN130TotMed(5)

oGetDados:Refresh()

Return .T.

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³CN130VldForn³ Autor ³ Felipe Bittar       ³ Data ³11/09/2008 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³Validacao dos fornecedores do Contrato                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ Logico                                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ CNTA130						                               ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function CN130VldForn()
Local lRet		:= .T.
Local cContra	:= M->CND_CONTRA
Local cRevisa	:= M->CND_REVISA
Local cFornec	:= M->CND_FORNEC
Local cLoja	:= If(Empty(M->CND_LJFORN),"",M->CND_LJFORN)

lRet := ExistCpo("SA2",cFornec+cLoja)

CNC->(dbSetOrder(1))
If lRet .And. !CNC->(dbSeek(xFilial("CNC",cFilCTR)+cContra+cRevisa+cFornec+cLoja))
	Aviso(STR0056,STR0078,{STR0046})//"O fornecedor informado não pertence ao Contrato."
	lRet := .F.
Endif

Return lRet

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³CN130VldCli ³ Autor ³ Andre Anjos			³ Data ³02/12/2013 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³Validacao dos fornecedores do Contrato                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ Logico                                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ CNTA130						                               ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function CN130VldCli()
Local lRet		:= .F.
Local cContra	:= M->CND_CONTRA
Local cRevisa	:= M->CND_REVISA
Local cClient	:= M->CND_CLIENT
Local cLoja	:= If(Empty(M->CND_LOJACL),"",M->CND_LOJACL)

lRet := ExistCpo("SA1",cClient+cLoja)

CNC->(dbSetOrder(3))
If lRet .And. !CNC->(dbSeek(xFilial("CNC",cFilCTR)+cContra+cRevisa+cClient+cLoja))
	//Aviso(STR0056,STR0106,{"OK"})//"O cliente informado não pertence ao Contrato."
	lRet := .F.
Endif

Return lRet

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³CN130NumMd  ³ Autor ³ Felipe Bittar       ³ Data ³24/09/2008 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³Validacao da numeracao da Medicao do Contrato                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ Logico                                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ CNTA130						                               ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function CN130NumMd()

Local aArea		:= GetArea()
Local aAreaCND	:= CND->(GetArea())
Local cNumMed   := ""

cNumMed:=GetSxENum("CND","CND_NUMMED")
nSaveSX8  := 1

dbSelectArea("CND")
dbSetOrder(4)
dbGoTop()

While CND->( msSeek(xFilial("CND")+cNumMed) )
	If ( __lSx8 )
		ConfirmSX8()
	EndIf
	cNumMed:=GetSxENum("CND","CND_NUMMED")
EndDo

RestArea(aAreaCND)
RestArea(aArea)

Return( cNumMed )

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³CN130DesPVºAutor  ³Andre Anjos         º Data ³  25/11/09   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Funcao para buscar um tipo de desconte que influencie o PV.º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºRetorno   ³ cRet: Codigo do primeiro tipo de desconto encontrado.	  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ CNTA130                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function CN130DesPV()
Local aArea  := GetArea()
Local cRet   := CriaVar("CNQ_TPDESC")
Local cRetPE := ""
Local cQry   := ""

cQry := "SELECT CNP_CODIGO "
cQry += "  FROM "+RetSQLName("CNP")
cQry += " WHERE D_E_L_E_T_ = ' ' "
cQry += "   AND CNP_FILIAL = '"+xFilial("CNP")+"'"
cQry += "   AND CNP_FLGPED = '1'"

cQry := ChangeQuery(cQry)
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"TMPCNP",.T.,.T.)

("TMPCNP")->(dbGoTop())
If !("TMPCNP")->(EOF())
	cRet := ("TMPCNP")->CNP_CODIGO
EndIf
("TMPCNP")->(dbCloseArea())

//-- Ponto de entrada para troca do tp. de desconto a ser usado
If ExistBlock("CN130TPD")
	cRetPE := ExecBlock("CN130TPD",.F.,.F.)
	If ValType(cRetPE) == "C" .And. !Empty(cRetPE) .And. CNP->(dbSeek(xFilial("CNP")+cRetPE))
		cRet := cRetPE
	EndIf
EndIf

RestArea(aArea)
Return cRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³C130CpyCNZ ºAutor  ³TOTVS              º Data ³  23/11/09   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Funcao para copiar os registro da tabela CNZ ref. a        º±±
±±º          ³ planilha selecionada para medicao. 						  º±±
±±º          ³ nos registros copiados o campo CNZ_CODPLA ficará em branco º±±
±±º          ³ e o campo CNZ_NUMMED conterá o numero da medicao           º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºRetorno   ³ cRet: Codigo do primeiro tipo de desconto encontrado.	  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ CNTA130                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function C130CpyCNZ(aDadosCNB,aRatGCT)
Local aArray	:= {}
Local aAreaCNZ	:= CNZ->(GetArea())
Local aHeadCNZ	:= GCTHeadCNZ()
Local nI 		:= 0
Local cBusca	:= xFilial("CNZ",cFilCTR)+aDadosCNB[1]+aDadosCNB[2]+aDadosCNB[3]+aDadosCNB[4]

dbSelectArea("CNZ")
dbSetOrder(1)

If CNZ->(dbSeek(cBusca))
	aAdd(aRatGCT,{	AllTrim(CNZ->CNZ_CONTRA),;
					AllTrim(CNZ->CNZ_REVISA),;
					AllTrim(M->CND_NUMMED),;
					AllTrim(CNZ->CNZ_ITCONT),;
					Nil } )

	While CNZ->(!EOF()) .And. cBusca == xFilial("CNZ",cFilCTR)+CNZ->(CNZ_CONTRA+CNZ_REVISA+CNZ_CODPLA+CNZ_ITCONT)
		aAdd(aArray, Array(len(aHeadCNZ)+1))

		For nI := 1 to len(aHeadCNZ)
		    aArray[len(aArray),nI] := CNZ->&(aHeadCNZ[nI,2])
		Next nI

		aArray[len(aArray),len(aHeadCNZ)+1] := .F.

		CNZ->(DbSkip())
	EndDo

	If Len(aArray) > 0
		aRatGCT[len(aRatGCT),5] := aClone(aArray)
	Endif

Endif

RestArea(aAreaCNZ)
Return()


/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³cn130MulDesc³ Autor ³ Aline Sebrian       ³ Data ³04/07/2011 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³Validacao do campo de descricao-Inclusao e alteracao de multa³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³cn130MulDesc(ExpC1,ExpN1,ExpC2,ExpC3,ExpN2)                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 -> Descricao da multa                                 ³±±
±±³          ³ ExpN1 -> Valor da multa                                     ³±±
±±³          ³ ExpC2 -> Tipo multa/bonificacao                             ³±±
±±³          ³ ExpC3 -> Interfere pedido                                   ³±±
±±³          ³ ExpN2 -> 1-Adiciona; 2-Altera                               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ Materiais                                                   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function cn130MulDesc(cDescri,nValor,cTipo,cPedFlag,nOpcao)
Local aRet:= {}
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Ponto de entrada executado na inclusao ou alteracao da multa/bonificacao      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If ExistBlock("CN130MLD")
	aRet := ExecBlock("CN130MLD",.f.,.f.,{cDescri,nValor,cTipo,cPedFlag,nOpcao})

	If Valtype(aRet) == "A"
		If Len(aRet)>=1 .And. Valtype(aRet[1]) == "C"
			cDescri :=  aRet[1]
		EndIf
		If Len(aRet)>=2 .And. Valtype(aRet[2]) == "N"
			nValor  := aRet[2]
		EndIf
		If Len(aRet)>=3 .And. Valtype(aRet[3]) == "C"
			cTipo   := aRet[3]
		EndIf
		If Len(aRet)>=4 .And. Valtype(aRet[4]) == "C"
			cPedFlag:= aRet[4]
		EndIf
	EndIf
EndIf
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³cn130VldTS ³ Autor ³ Aline Sebrian         ³ Data ³ 14.01.2010 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Valida Tipo Saida na Planilha                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ CNTA130                                                       ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function cn130VldTS(cValor)
Local aArea		:= GetArea()
Local aSaveLines:= FWSaveRows()
Local lRet      := .T.
Local oModel	:= Nil
Local cCtrNum	:= ""
Local cReadVar  := ReadVar()
Local xConteudo := &(cReadVar)
Local lnotTEC930 := IIF( FindFunction("TEC930Test") .AND. TEC930Test() , .F. , !lMedicao)

Default cValor := ""

If Empty(cValor)
	cValor := xConteudo
EndIf

If IsInCallStack('CNTA120') .And. lnotTEC930
	cCtrNum	:= Iif(INCLUI,cContra,CND->CND_CONTRA)
Else
	oModel	:= FwModelActive()
	cCtrNum	:= oModel:GetValue("CNDMASTER","CND_CONTRA")
	If Empty(cValor)
		cValor := oModel:GetValue("CNEDETAIL","CNE_TES")
	EndIf
EndIf

dbSelectArea("SF4")
SF4->(dbSetOrder(1))
If  SF4->(MsSeek(xFilial("SF4") + cValor))
	If cValor < "500"
		Help (" ",1,"A410NOTES")
		lRet := .F.
	EndIf
	If lRet .And. CN300RetSt("COMPRA",/**/,/**/,cCtrNum)
		Help (" ",1,"CNTA130TS1")//"Tipo Saida somente para Contratos do Tipo Vendas"
		lRet := .F.
	EndIf
Else
	Help (" ",1,"CNTA130TS2")//"Tipo Saida não cadastrada"
	lRet := .F.
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³cn130VldTe ³ Autor ³ Aline Sebrian         ³ Data ³ 14.01.2010 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Valida Tipo Entrada na Planilha                               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ CNTA1300                                                      ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function cn130VldTE()
Local cReadVar  := ReadVar()
Local xConteudo := &(cReadVar)
Local lRet      := .T.
Local oModel	:= Nil
Local cCtrNum	:= ""

dbSelectArea("SF4")
dbSetOrder(1)
MsSeek(xFilial("SF4")+xConteudo)

If IsInCallStack('CNTA120')
	cCtrNum	:= Iif(INCLUI,cContra,CND->CND_CONTRA)
Else
	oModel	:= FwModelActive()
	cCtrNum	:= oModel:GetValue("CNDMASTER","CND_CONTRA")
EndIf

If  SF4->(Found())
	If xConteudo > "500"
		Help (" ",1,"A410NOTES")
		lRet := .F.
	EndIf

	If lRet
		If CN300RetSt("VENDA",/**/,/**/,cCtrNum)
			Help (" ",1,"CNTA130TE1")//"Tipo Entrada somente para Contratos do Tipo Compras"
			lRet := .F.
		EndIf
	EndIf
EndIf

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN130VlUnt ³ Autor ³ Aline Sebrian         ³ Data ³19.10.2011³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Valida valor unitario informado na medicao                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN130VlUnt()                                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³         ATUALIZACOES SOFRIDAS DESDE A CONSTRU€AO INICIAL.              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Programador ³ Data   ³ BOPS ³  Motivo da Alteracao                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³            ³        ³      ³                                           ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function CN130VlUnt()

Local lRet := .T.
Local lArrefat := (SuperGetMv("MV_ARREFAT",.F.,"S")== "S")

Local nx       := If(lAuto,n,oGetDados:nAt)
Local nPosQMed := aScan(aHeader,{|x| x[2] == "CNE_QTAMED"})
Local nPosVlUn := aScan(aHeader,{|x| x[2] == "CNE_VLUNIT"})
Local nPosQOri := aScan(aHeader,{|x| x[2] == "CNE_QTDORI"})
Local nPosVOri := aScan(aHeader,{|x| x[2] == "CNE_VUNORI"})
Local nPosVlTt := aScan(aHeader,{|x| x[2] == "CNE_VLTOT "})
Local nQuant   := 0
Local nTotal   := 0

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se a quantidade e menor que o saldo    ³
//³ disponivel                                      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If nPosQMed > 0
	If M->CND_SERVIC == '2'
		nQuant := M->CNE_VLUNIT / aCols[nx,nPosVOri]
		lRet   := (nQuant <= aCols[nx,nPosQMed])
	EndIf
EndIf

If !lRet
	nTotal := nQuant - aCols[nx,nPosQMed]
	If nTotal<=0.001 .And. !lArrefat
	   lRet := .T.
	EndIf
EndIf

If lRet
	CN130TotMed(3)
EndIf

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ CN130FldOk  ³ Autor ³ Allyson Freitas       ³ Data ³ 11.01.2012 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Valida permissao de Produto                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ CNTA130                                                         ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function CN130FldOk()
Local lRet := .T.
Local cFieldCNE	:= ReadVar()
Local cFieldEdit	:= SubStr(cFieldCNE,4,Len(cFieldCNE))
Local cMenVar	:= &(ReadVar())
Local nPProduto	:= aScan(aHeader,{|x| AllTrim(x[2])== "CNE_PRODUT"})

If Altera
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Verifica se o usuario tem permissao de alteracao. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If cFieldEdit $ "CNE_PRODUT"
		If !(lRet := MaAvalPerm(1,{cMenVar,"CNT120",If(oGetDados:lNewLine,3,4)}))
			Help(,,1,'SEMPERM')
		EndIf
	Else
		If !(lRet := MaAvalPerm(1,{aCols[n][nPProduto],"CNT120",If(oGetDados:lNewLine,3,4)}))
			Help(,,1,'SEMPERM')
		EndIf
	EndIf
EndIf

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ CN130DelOk  ³ Autor ³ Allyson Freitas       ³ Data ³ 11.01.2012 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Valida permissao de Produto                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ CNTA130                                                         ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function CN130DelOk(lExcedente)
Local lRet		:= .T.
Local nPProduto	:= aScan(aHeader,{|x| AllTrim(x[2])== "CNE_PRODUT"})
Local nPExced	:= aScan(aHeader,{|x| AllTrim(x[2])== "CNE_EXCEDE"})
local nPPedido	:= aScan(aHeader,{|x| AllTrim(x[2])== "CNE_PEDIDO"})
Local uRet		:= .T.

DEFAULT lExcedente := .F.

//Valida a exclusão de itens excedentes
If lExcedente
	If INCLUI .Or. nPExced == 0 .Or. nPPedido == 0
		Return .F.
	ElseIf aCols[n][nPExced] <> '1' .Or. !Empty(aCols[n][nPPedido])
		Help(" ",1,"CN130EXCED",,STR0110,4,0)
		Return .F.
	EndIf
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Verifica se o usuario tem permissao de exclusao. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If !(lRet := MaAvalPerm(1,{aCols[n][nPProduto],"CNT120",5}))
	Help(,,1,'SEMPERM')
EndIf

CN130TotMed(5,.T.)

If lRet .And. ExistBlock("C130KDEL")
	uRet := ExecBlock("C130KDEL",.F.,.F.)
	lRet :=	If(Valtype(uRet)=="L",uRet,lRet)
EndIf

Return lRet

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao    ³cn130MultT ³ Autor ³ Aline S Damasceno    ³ Data ³ 03/02/12 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Efetua a Validacao dos campos digitados quanto a quantidade³±±
±±³          ³,preco, desconto e quantidade liberada.                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ Logico                                                     ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function cn130MultT()

Local aArea     := GetArea()
Local cEspecie  := ""

Local nPVlUnit  := aScan(aHeader,{|x| AllTrim(x[2])=="CNE_VLUNIT"})
Local nPVlTot   := aScan(aHeader,{|x| AllTrim(x[2])=="CNE_VLTOT"})
Local nPVlDesc  := aScan(aHeader,{|x| AllTrim(x[2])=="CNE_VLDESC"})
Local nPDescont := aScan(aHeader,{|x| AllTrim(x[2])=="CNE_PDESC"})
Local nPQuant   := aScan(aHeader,{|x| AllTrim(x[2])=="CNE_QUANT"})
Local nPPerc    := aScan(aHeader,{|x| AllTrim(x[2])=="CNE_PERC"})
Local nPQtdSol  := aScan(aHeader,{|x| AllTrim(x[2])=="CNE_QTDSOL"})

Local nPVlrOri	:= aScan(aHeader,{|x| AllTrim(x[2])=="CNE_VUNORI"})
Local nPQtdOri	:= aScan(aHeader,{|x| AllTrim(x[2])=="CNE_QTDORI"})

Local nValorUn  := 0

Local cReadVar  := ReadVar()
Local xConteudo := &(cReadVar)

Local nx       := If(lAuto,n,oGetDados:nAt)

If Type("cEspCtr") == "C"
	cEspecie := cEspCtr
Else
	cEspecie := CN9->CN9_ESPCTR
EndIf

//Tratamento para contrato do tipo vendas
If  !( Type("lAuto") != "U" .And. lAuto ) .And. !IsInCallStack("CN130EXCE")
  
	If cEspecie=="2"
	   If ( Type("lFixo") != "U" .And. lFixo )
			Do Case
			Case "CNE_VLUNIT"$cReadVar
				If ( Type("lServico") != "U" .And. !lServico )
					FtDescItem(0,@xConteudo,@aCols[nx,nPQuant],@aCols[nx,nPVlTot],@aCols[nx,nPDescont],@aCols[nx,nPVlDesc],0,1,,)
				Else
					FtDescItem(0,@aCols[nx,nPVlrOri],@xConteudo/@aCols[nx,nPVlrOri],@aCols[nx,nPVlTot],@aCols[nx,nPDescont],@aCols[nx,nPVlDesc],0,1,,)
				EndIf
	
			Case "CNE_QUANT"$cReadVar
				FtDescItem(0,@aCols[nx,nPVlUnit],@xConteudo,@aCols[nx,nPVlTot],@aCols[nx,nPDescont],@aCols[nx,nPVlDesc],0,1,,)
	
			Case "CNE_PDESC"$cReadVar
				FtDescItem(0,@aCols[nx,nPVlUnit],@aCols[nx,nPQuant],@aCols[nx,nPVlTot],@xConteudo,@aCols[nx,nPVlDesc],0,1,,)
	
			Case "CNE_VLTOT"$cReadVar
	
				If ( Type("lServico") != "U" .And. !lServico )
					FtDescItem(0,@aCols[nx,nPVlUnit],(@xConteudo/@aCols[nx,nPVlUnit]) ,@xConteudo,@aCols[nx,nPDescont],@aCols[nx,nPVlDesc],0,1,,)
				Else
					FtDescItem(0,@aCols[nx,nPVlrOri],(@xConteudo/@aCols[nx,nPVlrOri]),@xConteudo,@aCols[nx,nPDescont],@aCols[nx,nPVlDesc],0,1,,)
	
				EndIf
	
			Case "CNE_PERC"$cReadVar
				If ( Type("lServico") != "U" .And. !lServico )
					FtDescItem(0,@aCols[nx,nPVlUnit],(@aCols[nx,nPQtdSol]*@xConteudo)/100,@aCols[nx,nPVlTot],@aCols[nx,nPDescont],@aCols[nx,nPVlDesc],0,1,,)
				Else
					FtDescItem(0,@aCols[nx,nPVlrOri],(@aCols[nx,nPQtdSol]*@xConteudo)/100,@aCols[nx,nPVlTot],@aCols[nx,nPDescont],@aCols[nx,nPVlDesc],0,1,,)
				EndIf
	
			EndCase
	 	EndIf
	
		If ( Type("lFixo") != "U" .And. !lFixo )
			Do Case
				Case "CNE_VLUNIT"$cReadVar
					aCols[nx,nPVlDesc] := 0
					aCols[nx,nPDescont]:= 0
	
				Case "CNE_QUANT"$cReadVar
					aCols[nx,nPVlDesc] := 0
					aCols[nx,nPDescont]:= 0
	
				Case "CNE_PDESC"$cReadVar
					FtDescItem(0,@aCols[nx,nPVlUnit],@aCols[nx,nPQuant],@aCols[nx,nPVlTot],@xConteudo,@aCols[nx,nPVlDesc],0,1,,)
			EndCase
		EndIf
	EndIf
	
	If "CNE_VLUNIT"$cReadVar .And. Type("lServico") != "U" .And. lServico .And. !Empty(nPPerc) .And. !Empty(nPVlrOri) .And. !Empty(nPQtdSol)
		aCols[nX,nPPerc] := ( xConteudo / (aCols[nX,nPVlrOri] * aCols[nX,nPQtdSol]) ) * 100
	EndIf
	
EndIf

RestArea(aArea)
Return .t.
/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao    ³cn130VldCnd9  ³ Autor ³ Aline S Damasceno ³ Data ³ 03/04/12 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Validacao da Condicao de Pagamento Tipo 9                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ExpL1: Logico                                               ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function cn130VldCnd9()
Local nx        := 0
Local nParcelas := SuperGetMv("MV_NUMPARC")
Local nParc     := 0
Local nAux      := 0
Local nTotal    := M->CND_VLTOT

Local dParc     :=  Ctod("")

Local lParc     := .T.
Local lRet      := .T.
Local lPerc	:= Alltrim(SE4->E4_COND) == "%"

Local cParcela  := "123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0"
Local cChave    := ""
Local cChave1   := ""
Local OpcQW     := ""

If nParcelas > 4
	cChave := "CND_DATA"+Substr(cParcela,nParcelas,1)
	cChave1:= "CND_PARC"+Substr(cParcela,nParcelas,1)
	aAreaSX3 := SX3->(GetArea())

	DbSelectArea("SX3")
	DbSetOrder(2)
	If !DbSeek(cChave) .or. !DbSeek(cChave1) .Or. ( nParcelas > 26)
		Help(" ",1,"TMKTIP905") //"A quantidade de parcelas nao esta compativel. Verificar junto ao administrador do sistema relacao entre parametro MV_NUMPARC e dicionario de dados"
		Return(.F.)
	EndIf

	Restarea(aAreaSX3)
EndIf

For nX:=1 to nParcelas
	nParc := &("M->CND_PARC"+Substr(cParcela,nx,1))
	dParc := &("M->CND_DATA"+Substr(cParcela,nx,1))
	If nParc > 0 .And. Empty(dParc)
		lParc := .F.
	EndIf
	nAux  += nParc
Next nX

If !lParc
	Help(" ",1,"A410TIPO9")
	lRet := .F.
Else
	If (!lPerc .And. NoRound(nTotal,2) <> NoRound(nAux,2)) .Or. (lPerc .And. nAux <> 100)

		Help(" ",1,"A410TIPO9")
		If SuperGetMV("MV_TIPO9SP",,.T.)	// Tipo 9 Sem Parcela informada
			If lRet
				If ( Type("lAuto") == "U" .or. ! lAuto )
					OpcQW:=MsgYesNo(OemToAnsi(STR0104),OemToAnsi(STR0056))  //"Confirma a Inclusao da Medição do Contrato ?"###"Aten‡„o"
					If !OpcQW 				// Abandona
						lRet := .F.
					EndIf
				EndIf
			EndIf
		Else
			lRet := .F.
		EndIf
	EndIf

EndIf
Return lRet

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao	 ³ CN130Exce³ Autor ³ Joao Goncalves de Oliveira ³ Data ³ 22/02/11 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Executa tela para que sejam informados dados para inclusão de   ³±±
±±³          ³ excedente                                                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ CN130Exce()                    			        		       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum                                                          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Retorno  ³ Nenhum                       						   		   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function CN130Exce(nOpc)

Local lRet 		:= .T.

Local aExibCamp := {"CNE_ITEM","CNE_PRODUT","CNE_DESCRI","CNE_TABPRC","CNE_QUANT","CNE_VLUNIT","CNE_DTENT","CNE_FLGCMS","CNE_PEDTIT","CNE_CC","CNE_CONTA","CNE_ITEMCT","CNE_CLVL"}
Local aEditCamp := {"CNE_QUANT","CNE_DTENT","CNE_FLGCMS","CNE_PEDTIT"}
Local aCampEnch := {}
Local aCN130CEX := {}
Local aEntidades := CtbEntArr()
Local aEntCamp	:= {}

Local cCadastro := STR0094 //Incluisão de Excedente"
Local cMaxiItem := ""
Local cPesqTab  := ""

Local oDlgExced := NIL

Local nX 		:= 0
Local nY		:= 0
Local nAux	 	:= 0
Local nTotLGetD := 0
Local nPrcUnit  := 0
Local nPosiItem := aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_ITEM"})
Local nPosiProd := aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_PRODUT"})
Local nPosiDesc := aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_DESCRI"})
Local nPosiVlUn := aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_VLUNIT"})
Local nPosiQtde := aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_QUANT"})
Local nPosiVlTo := aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_VLTOT"})
Local nPosiDEnt := aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_DTENT"})
Local nPosiFCms := aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_FLGCMS"})
Local nPosiExce := aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_EXCEDE"})
Local nPosiTPrc := aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_TABPRC"})
Local nPosiCTES := aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_TS"})
Local nPosiPdTi := aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_PEDTIT"})
Local nPosiCC	:= aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_CC"})
Local nPosiCta	:= aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_CONTA"})
Local nPosiItCt := aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_ITEMCT"})
Local nPosiClVl := aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_CLVL"})
Local nPosEnt	:= 0
Local cField	:= ""
Local cWhen		:= ""
Local cValid	:= ""

Private aTELA[0][0]
Private aGETS[0]

For nY:=1 To Len(aEntidades)
	aAdd(aEntCamp	, "CNE_EC"+aEntidades[nY]+"DB")
	aAdd(aEntCamp	, "CNE_EC"+aEntidades[nY]+"CR")
	aAdd(aExibCamp, "CNE_EC"+aEntidades[nY]+"DB")
	aAdd(aExibCamp, "CNE_EC"+aEntidades[nY]+"CR")
Next nY

If ExistBlock("CN130CEX")
	aCN130CEX := ExecBlock("CN130CEX",.F.,.F.,{aEditCamp})
	If ValType(aCN130CEX) == "A"
		aEditCamp := aClone(aCN130CEX)
	EndIf
EndIf

If !lAuto .And. oGetDados:aCols[oGetDados:nAt,nPosiExce] # '1'
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Monta a tela para digitação do excedente     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	SX3->(dbSetOrder(2))  // X3_CAMPO
	For nX := 1 to Len(aExibCamp)
		If SX3->(dbSeek(PadR(aExibCamp[nX],10)))
			cField := aExibCamp[nX]
			If X3Uso( GetSX3Cache( cField, "X3_USADO" ) ) .And. cNivel >= GetSX3Cache( cField, "X3_NIVEL" )
				
				aAdd(aCampEnch,{ X3Titulo()							,;
								 cField								,;
								 GetSX3Cache( cField, "X3_TIPO" )	,;
								 GetSX3Cache( cField, "X3_TAMANHO" ),;
								 GetSX3Cache( cField, "X3_DECIMAL" ),;
								 PesqPict( "CNE", cField ),,		 ;
								 .F.								,;
								 GetSX3Cache( cField, "X3_NIVEL" )	,;
								 GetSX3Cache( cField, "X3_RELACAO" ),;
								 GetSX3Cache( cField, "X3_F3" ),,	 ;
								 .F.,								 ;
								 .F.,								 ;
								 GetSX3Cache( cField, "X3_CBOX" )	,;
								 GetSX3Cache( cField, "X3_FOLDER" )	,;
								 .F.								,;
								 GetSX3Cache( cField, "X3_PICTVAR" ),;
								 GetSX3Cache( cField, "X3_TRIGGER" ) } )
				
				cValid := GetSX3Cache( cField, "X3_VALID" )
				If !Empty( cValid )
					aCampEnch[Len(aCampEnch),7] := &("{||" +RTrim( cValid ) +"}")
				EndIf

				cWhen := GetSX3Cache( cField, "X3_WHEN" )
				If !Empty( cWhen )
					aCampEnch[Len(aCampEnch),12] := &("{||" +RTrim( cWhen ) +"}")
				EndIf

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Define a validacao do campo                                             ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If AllTrim( cField ) $ "CNE_TABPRC"
					aCampEnch[Len(aCampEnch)][7] := &( "{ || CN130ExVl('T')}" )
				ElseIf AllTrim( cField ) $ "CNE_QUANT"
					aCampEnch[Len(aCampEnch)][7] := &( "{ || CN130ExVl('Q')}" )
					aCampEnch[Len(aCampEnch)][19] := "N"
				EndIf

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Checa se o campo eh visual                                              ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If AllTrim( cField ) $ "CNE_ITEM,CNE_PRODUT,CNE_DESCRI"
					aCampEnch[Len(aCampEnch)][13] := .T.
				EndIf

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Checa se o campo eh obrigatorio                                         ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If ((SubStr(BIN2STR( GetSX3Cache( cField, "X3_OBRIGAT " ) ),1,1) == "x" .Or. VerByte( GetSX3Cache( cField, "X3_RESERV" ), 7 ) ) .Or.;
				 AllTrim( cField ) $ "CNE_TABPRC,CNE_QUANT,CNE_VLUNIT,CNE_FLGCMS")
					aCampEnch[Len(aCampEnch)][8] := .T.
				Endif
			Endif
		Endif
	Next nX

	cPesqTab := Posicione("CNB",1,xFilial("CNB",cFilCTR)+M->CND_CONTRA+M->CND_REVISA+M->CND_NUMERO+oGetDados:aCols[oGetDados:nAt,nPosiItem],"CNB_TABPRC")

	M->CNE_ITEM   := oGetDados:aCols[oGetDados:nAt,nPosiItem]
	M->CNE_PRODUT := oGetDados:aCols[oGetDados:nAt,nPosiProd]
	M->CNE_DESCRI := oGetDados:aCols[oGetDados:nAt,nPosiDesc]
	M->CNE_TABPRC := cPesqTab

	If (nOpc == 3 .Or. nOpc == 4)
		nX := aScan(oGetDados:aCols, {|x| x[nPosiProd] == oGetDados:aCols[oGetDados:nAt,nPosiProd] .And.;
													x[nPosiTprc] == cPesqTab .And.;
												  	x[nPosiExce] == '1'})
	Else
		nX := aScan(oGetDados:aCols, {|x| x[nPosiProd] == oGetDados:aCols[oGetDados:nAt,nPosiProd] .And.;
													x[nPosiTprc] == cPesqTab .And.;
												  	x[nPosiExce] == '1' .And. Empty(x[Len(oGetDados:aHeader)])})
	EndIf

	If !Empty(nX)

		M->CNE_QUANT  := oGetDados:aCols[nX,nPosiQtde]
		M->CNE_VLUNIT := oGetDados:aCols[nX,nPosiVlUn]
		M->CNE_DTENT  := oGetDados:aCols[nX,nPosiDEnt]

		If nPosiFCms > 0
			M->CNE_FLGCMS := oGetDados:aCols[nX,nPosiFCms]
		EndIf

		If nPosiCTES > 0
			M->CNE_TS := oGetDados:aCols[nX,nPosiCTES]
		EndIf

		If nPosiPdTi > 0
			M->CNE_PEDTIT := oGetDados:aCols[nX,nPosiPdTi]
		EndIf

		If nPosiCC > 0
			M->CNE_CC := oGetDados:aCols[nX,nPosiCC]
		EndIf

		If nPosiCta > 0
			M->CNE_CONTA := oGetDados:aCols[nX,nPosiCta]
		EndIf

		If nPosiItCt > 0
			M->CNE_ITEMCT := oGetDados:aCols[nX,nPosiItCt]
		EndIf

		If nPosiClVl > 0
			M->CNE_CLVL := oGetDados:aCols[nX,nPosiClVl]
		EndIf

		For nY:=1 To Len(aEntCamp)
			nPosEnt := aScan(aHeader,{|x| AllTrim(x[2]) == aEntCamp[nY]})

			If nPosEnt > 0
				M->&(aEntCamp[nY]) := oGetDados:aCols[nX,nPosEnt]
			EndIf
		Next nY

	Else

		M->CNE_ITEM   := oGetDados:aCols[oGetDados:nAt,nPosiItem]
		M->CNE_QUANT  := CriaVar("CNE_QUANT")
		M->CNE_VLUNIT := CriaVar("CNE_VLUNIT")
		M->CNE_DTENT  := oGetDados:aCols[oGetDados:nAt,nPosiDEnt]

		If nPosiFCms > 0
			M->CNE_FLGCMS := oGetDados:aCols[oGetDados:nAt,nPosiFCms]
		EndIf

		If nPosiCTES > 0
			M->CNE_TS := oGetDados:aCols[oGetDados:nAt,nPosiCTES]
		EndIf

		If nPosiPdTi > 0
			M->CNE_PEDTIT := oGetDados:aCols[oGetDados:nAt,nPosiPdTi]
		EndIf

		If nPosiCC > 0
			M->CNE_CC := oGetDados:aCols[oGetDados:nAt,nPosiCC]
		EndIf

		If nPosiCta > 0
			M->CNE_CONTA := oGetDados:aCols[oGetDados:nAt,nPosiCta]
		EndIf

		If nPosiItCt > 0
			M->CNE_ITEMCT := oGetDados:aCols[oGetDados:nAt,nPosiItCt]
		EndIf

		If nPosiClVl > 0
			M->CNE_CLVL := oGetDados:aCols[oGetDados:nAt,nPosiClVl]
		EndIf

		For nY:=1 To Len(aEntCamp)
			nPosEnt := aScan(aHeader,{|x| AllTrim(x[2]) == aEntCamp[nY]})

			If nPosEnt > 0
				M->&(aEntCamp[nY]) := oGetDados:aCols[oGetDados:nAt,nPosEnt]
			EndIf
		Next nY

	EndIf

	//-- Tratamento no aRotina pois como chamara MsMGet com nOpc precisa de tres opcoes no aRotina
	aAdd(aRotina,aClone(aRotina[1]))
	aRotina[3,4] := 3

	Define MsDialog oDlgExced Title cCadastro From 09,0 To 28,80
	oDlgExced:lEscClose := .F.
	oEnchExce := MsMGet():New("CNE",0,3,,,,aExibCamp,,aEditCamp,1,,,,oDlgExced,.F.,.F.,.F.,"",.F.,.F.,aCampEnch)
	oEnchExce:oBox:Align := CONTROL_ALIGN_ALLCLIENT
	Activate Msdialog oDlgExced On Init EnchoiceBar(oDlgExced, {|| If(Obrigatorio(aGets,aTela),(nAux:=1,oDlgExced:End()),NIL)}, {|| oDlgExced:End()})

	//-- Retorna aRotina ao formato original
	aSize(aRotina,Len(aRotina)-1)

	If nAux == 1
		If Empty(nX)
			cMaxiItem := Soma1(oGetDados:aCols[Len(oGetDados:aCols),nPosiItem])
			aAdd(oGetDados:aCols, Array(Len(aHeader) + 1))
			nTotLGetD := Len(oGetDados:aCols)
		Else
			nTotLGetD := nX
			cMaxiItem := oGetDados:aCols[nX,nPosiItem]
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Inicializa campos da getdados                  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		For nX := 1 to Len(aHeader)
			If IsHeadRec(aHeader[nX,2])
				If Empty(oGetDados:aCols[nTotLGetD,nX])
					oGetDados:aCols[nTotLGetD,nX] := 0
				EndIf
			ElseIf IsHeadAlias(aHeader[nX,2])
				oGetDados:aCols[nTotLGetD,nX] := "CNE"
			ElseIf AllTrim(aHeader[nX,2]) # "CNE_DESCRI"
				oGetDados:aCols[nTotLGetD,nX] := CriaVar(aHeader[nX,2],.F.)
			EndIf
		Next nX

		oGetDados:aCols[nTotLGetD,nPosiItem] := cMaxiItem
		oGetDados:aCols[nTotLGetD,nPosiProd] := M->CNE_PRODUT
		oGetDados:aCols[nTotLGetD,nPosiDesc] := M->CNE_DESCRI
		oGetDados:aCols[nTotLGetD,nPosiVlUn] := M->CNE_VLUNIT
		oGetDados:aCols[nTotLGetD,nPosiQtde] := M->CNE_QUANT
		oGetDados:aCols[nTotLGetD,nPosiExce] := "1"
		oGetDados:aCols[nTotLGetD,nPosiTPrc] := M->CNE_TABPRC
		oGetDados:aCols[nTotLGetD,nPosiVlTo] := oGetDados:aCols[nTotLGetD,nPosiQtde] * oGetDAdos:aCols[nTotLGetD,nPosiVlUn]
		oGetDados:aCols[nTotLGetD,nPosiDEnt] := M->CNE_DTENT

		If nPosiFCms > 0
			oGetDados:aCols[nTotLGetD,nPosiFCms] := M->CNE_FLGCMS
		EndIf

		If nPosiCTES > 0
			oGetDados:aCols[nTotLGetD,nPosiCTES] := M->CNE_TS
		EndIf

		If nPosiPdTi > 0
			oGetDados:aCols[nTotLGetD,nPosiPdTi] := M->CNE_PEDTIT
		EndIf

		If nPosiCC > 0
			oGetDados:aCols[nTotLGetD,nPosiCC] := M->CNE_CC
		EndIf

		If nPosiCta > 0
			oGetDados:aCols[nTotLGetD,nPosiCta] := M->CNE_CONTA
		EndIf

		If nPosiItCt > 0
			oGetDados:aCols[nTotLGetD,nPosiItCt] := M->CNE_ITEMCT
		EndIf

		If nPosiClVl > 0
			oGetDados:aCols[nTotLGetD,nPosiClVl] := M->CNE_CLVL
		EndIf

		For nY:=1 To Len(aEntCamp)
			nPosEnt := aScan(aHeader,{|x| AllTrim(x[2]) == aEntCamp[nY]})

			If nPosEnt > 0
				oGetDados:aCols[nTotLGetD,nPosEnt] := M->&(aEntCamp[nY])
			EndIf
		Next nY

		oGetDados:aCols[nTotLGetD,Len(aHeader)+1] := .F.

		CN130TotMed(5)

	EndIf

	oGetDados:Refresh()

ElseIf lAuto
	For nX := 1 To Len(aAutoExced)
		nPQUANT := aScan(aAutoExced[1],{|x| AllTrim(x[1]) == "CNE_QUANT"})
		If Empty(aAutoExced[nX,nPQUANT])
			Loop
		EndIf

		nPITEM  := aScan(aAutoExced[nX],{|x| AllTrim(x[1]) == "CNE_ITEM"})
		If (nAux := aScan(aCols,{|x| x[GDFieldPos("CNE_ITEM")] == aAutoExced[nX,nPITEM,2]})) == 0
			Aviso("CNTA120",STR0098 +aCols[nAux,nPITEM] +STR0099) //-- Não foi encontrado o item ### para inclusão de excedente.
			lRet := .F.
		ElseIf aCols[nAux,GDFieldPos("CNE_EXCEDE")] == '1'
			Aviso("CNTA120",STR0100,{STR0046}) //-- Este recurso está disponível apenas para itens previstos na planilha (não excedentes).
			lRet := .F.
		EndIf

		//-- Tratamento para receber o valor unitário via ExecAuto.
		If lRet .And. (nPVLUnit := aScan(aAutoExced[1],{|x| AllTrim(x[1]) == "CNE_VLUNIT"})) > 0
			If aAutoExced[nX, nPVLUnit, 2] > 0
				nPrcUnit := aAutoExced[nX, nPVLUnit, 2]
			Else
				Aviso("CNTA120",STR0101 +aCols[nAux,nPITEM] +STR0103) //-- O item ### não possui preço para a quantidade excedente.
				lRet := .F.
			EndIf
		Else
			//-- Se nao tem tabela de preco nao processa
			If lRet .And. Empty(cPesqTab := Posicione("CNB",1,xFilial("CNB",cFilCTR)+M->CND_CONTRA+M->CND_REVISA+M->CND_NUMERO+aCols[nAux,nPITEM],"CNB_TABPRC"))
				Aviso("CNTA120",STR0101 +aCols[nAux,nPITEM] +STR0102) //-- O item ### não possui tabela de preço para inclusão de excedente.
				lRet := .F.
			Else
				If lRet .And. Empty(nPrcUnit := MaTabPrVen(cPesqTab,aCols[nAux,GDFieldPos("CNE_PRODUT")],aAutoExced[nX,nPQUANT,2],CND->CND_CLIENT,CND->CND_LOJACL,1,dDataBase))
					Aviso("CNTA120",STR0101 +aCols[nAux,nPITEM] +STR0103) //-- O item ### não possui preço para a quantidade excedente.
					lRet := .F.
				EndIf
			EndIf
		EndIf

		If lRet
			If (nTotLGetD := aScan(aCols, {|x| x[GDFieldPos("CNE_PRODUT")] == aCols[nAux,GDFieldPos("CNE_PRODUT")] .And.;
			   				 	 				x[GDFieldPos("CNE_TABPRC")] == cPesqTab .And.;
											  	x[GDFieldPos("CNE_EXCEDE")] == '1'})) == 0
				aAdd(aCols,Array(Len(aHeader) + 1))
				nTotLGetD := Len(aCols)
			EndIf

			//-- Inicializa campos da getdados
			For nY := 1 to Len(aHeader)
				If IsHeadRec(aHeader[nY,2]) .And. Empty(aCols[nTotLGetD,nY])
					aCols[nTotLGetD,nY] := 0
				ElseIf IsHeadAlias(aHeader[nY,2])
					aCols[nTotLGetD,nY] := "CNE"
				ElseIf AllTrim(aHeader[nY,2]) $ "CNE_DTENT/CNE_FLGCMS/CNE_TS"
					aCols[nTotLGetD,ny] := aCols[nAux,nY]
				Else
					aCols[nTotLGetD,nY] := CriaVar(aHeader[nY,2],.F.)
				EndIf
			Next nY

			//-- Preenche campos recebidos pela execauto
			For nY := 1 To Len(aAutoExced[nX])
				If aScan(aEditCamp,{|x| x == aAutoExced[nX,nY,1]}) > 0 .And. GDFieldPos(aAutoExced[nX,nY,1]) > 0
					If aAutoExced[nX,nY,1] # "CNE_QUANT" .And. !CheckSX3(aAutoExced[nX,nY,1],aAutoExced[nX,nY,2])
						lRet := .F.
						Exit
					Else
						aCols[nTotLGetD,GDFieldPos(aAutoExced[nX,nY,1])] := aAutoExced[nX,nY,2]
					EndIf
				EndIf
			Next nY

			//-- Preenche campos do sistema
			aCols[nTotLGetD,GDFieldPos("CNE_ITEM")]   := Soma1(aCols[Len(aCols) - 1,GDFieldPos("CNE_ITEM")])
			aCols[nTotLGetD,GDFieldPos("CNE_PRODUT")] := aCols[nAux,GDFieldPos("CNE_PRODUT")]
			aCols[nTotLGetD,GDFieldPos("CNE_VLUNIT")] := nPrcUnit
			aCols[nTotLGetD,GDFieldPos("CNE_VLTOT")]  := aCols[nTotLGetD,GDFieldPos("CNE_QUANT")] * aCols[nTotLGetD,GDFieldPos("CNE_VLUNIT")]
			aCols[nTotLGetD,GDFieldPos("CNE_EXCEDE")] := "1"
			aCols[nTotLGetD,GDFieldPos("CNE_TABPRC")] := cPesqTab
			aCols[nTotLGetD,GDFieldPos("CNE_PEDTIT")] := aCols[nAux,GDFieldPos("CNE_PEDTIT")]
			aCols[nTotLGetD,Len(aHeader)+1] := .F.

			n := nTotLGetD
			CN130TotMed(5)
		Else
			Exit
		EndIf
	Next nX
ElseIf oGetDados:aCols[oGetDados:nAt,nPosiExce] == '1'
	Aviso("CNTA120",STR0100,{STR0046}) //-- Este recurso está disponível apenas para itens previstos na planilha (não excedentes).
EndIf

Return lRet

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao	 ³ CN130ExVl³ Autor ³ Joao Goncalves de Oliveira ³ Data ³ 22/02/11 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Valida campo tabela de preço ou quantidade e atualiza           ³±±
±±³          ³ a informação do preço unitário                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ CN130ExVl(cTipoCamp)  			          		          	   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 - Tipo de Campo p/ validacao: T - Tabela de Preços ou     ³±±
±±³          ³ Q - Quantidade                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Retorno  ³ ExpL1 - Validade do campo    						   		   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function CN130ExVl(cTipoCamp)
Local lValiCamp := .F.
Local nPosiQtde := aScan(aHeader,{|x| AllTrim(x[2]) == "CNE_QUANT"})
Local nQtdeMedi := aCols[oGetDados:nAt,nPosiQtde]

If cTipoCamp == "T"
	lValiCamp := ExistCpo("DA0",M->CNE_TABPRC,1)
	If M->CNE_QUANT > 0
		M->CNE_VLUNIT := MaTabPrVen(M->CNE_TABPRC,M->CNE_PRODUT,M->CNE_QUANT,CND->CND_CLIENT,CND->CND_LOJACL,1,dDataBase)
	EndIf
ElseIf cTipoCamp == "Q"
	lValiCamp := M->CNE_QUANT > 0
	If !Empty(M->CNE_TABPRC)
		M->CNE_VLUNIT := MaTabPrVen(M->CNE_TABPRC,M->CNE_PRODUT,M->CNE_QUANT,CND->CND_CLIENT,CND->CND_LOJACL,1,dDataBase)
	EndIf
EndIf

Return(lValiCamp)


//------------------------------------------------------------------
/*/{Protheus.doc} CN130ReprMT(lAuto,nLoop,aListBox,aMultas)
Função que processa a multa vinculada ao contrato


@author taniel.silva
@since 17/07/2014
@version P12
/*/
//-------------------------------------------------------------------
Function CN130ReprMT(lAuto,nLoop,aListBox,aMultas)

Local cAliasQry  := ""
Local cQuery     := ""
local nValor     := 0
local nPos			:= 0

Default lAuto		:= .T.
Default nLoop		:= 0
Default aListBox	:= {}
Default aMultas	:= {}

If lAuto .Or. nLoop == 1
	cAliasQry := GetNextAlias()
	cQuery := ""

	cQuery += "SELECT CN4_CODIGO, CN4_DESCRI, CN4_VLDALT, CN4_VLRALT, CN4_VALID, CN4_FORMUL, CN4_TIPO, CNH_NUMERO, CN4_FLGPED "
	cQuery +="   FROM " +RetSqlName("CNH")+" CNH,"+RetSqlName("CN4")+" CN4 "
	cQuery += "  WHERE CNH_FILIAL	= '"+xFilial("CNH",cFilCTR)+"'"
	cQuery += "  AND CNH_NUMERO     = '"+M->CND_CONTRA+"' "
	cQuery += "  AND CNH_REVISA 	= '"+M->CND_REVISA+"' "
	cQuery += "  AND CNH.D_E_L_E_T_ = ' ' "
	cQuery += "  AND CNH_CODIGO     = CN4_CODIGO "
	cQuery += "  AND CN4_FILIAL     = '" +xFilial("CN4")+"'"
	cQuery += "  AND CN4.D_E_L_E_T_ = ' '"
	cQuery += "  ORDER BY CNH_NUMERO,CN4_CODIGO"

	cQuery := ChangeQuery( cQuery )
	dbUseArea( .T., "TOPCONN", TcGenQry( ,, cQuery ), cAliasQry, .F., .T. )

	While !( cAliasQry )->( Eof() )
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Avalia a aplicacao da multa                                            ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If Empty( ( cAliasQry )->CN4_VLDALT )
			lFormula := Formula(( cAliasQry )->CN4_VALID )
		Else
	   		lFormula := CNTA130Form( ( cAliasQry )->CN4_VLDALT )
	   		If ValType(lFormula) == 'U'
				lFormula := .F.
			EndIf
		EndIf

		If lFormula
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Obtem o valor da multa                                                 ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If Empty( ( cAliasQry )->CN4_VLRALT )
				nValor := Formula( ( cAliasQry )->CN4_FORMUL )
			Else
				nValor := CNTA130Form( ( cAliasQry )->CN4_VLRALT)
				If ValType(nValor) == 'U'
					nValor := 0
				EndIf
			EndIf

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Monta List Box da Medição							                   ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If !lAuto
				nPos := aScan (aListBox, {|x| x[7]==(cAliasQRY)->CN4_CODIGO})
				If nPos == 0
					AAdd( aListBox, { .F., (cAliasQRY)->CN4_TIPO, (cAliasQRY)->CN4_DESCRI, nValor, "1", (cAliasQRY)->CN4_FLGPED, (cAliasQRY)->CN4_CODIGO} )
				Else
					aListBox[nPos,4]:= aListBox[nPos,4]+nValor
				EndIf
			EndIf

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Carrega as multas do array                                             ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			aAdd(aMultas,Array(6))
			aTail(aMultas)[1] := (cAliasQRY)->CN4_TIPO
			aTail(aMultas)[2] := (cAliasQRY)->CN4_DESCRI
			aTail(aMultas)[3] := nValor
			aTail(aMultas)[4] := '1'
			aTail(aMultas)[5] := (cAliasQRY)->CN4_FLGPED
			aTail(aMultas)[6] := (cAliasQRY)->CN4_CODIGO

			//Verifica se é multa ou bonificação
			If (cAliasQRY)->CN4_TIPO == '1'
				nTotMultas += nValor
			Else
				nTotBoni += nValor
			EndIf

		EndIf
		( cAliasQry )->( dbSkip() )
	EndDo

	( cAliasQry )->( dbCloseArea() )

EndIf

Return nTotMultas


//------------------------------------------------------------------
/*/{Protheus.doc} LRDVldFormula(cExpr)
Função que retorna erro na execução da macro


@author taniel.silva
@since 17/07/2014
@version P12
/*/
//-------------------------------------------------------------------
Function CNTA130Form(cExpr)
Local oError  := ErrorBlock( { |e| ChecErro( e ) } )
Local xRet

If !Empty(cExpr)
	Begin Sequence
		xRet := &(AllTrim(cExpr))
	End Sequence
EndIf

ErrorBlock(oError)

Return xRet

//------------------------------------------------------------------
/*/{Protheus.doc} CnRetAhd(cCampo, aHeader)
Função que retorna um array para ser acrescentado em um aheader


@author Matheus Lando Raimundo
@since 19/12/2014
@version P12
/*/
//-------------------------------------------------------------------
Function CnRetAhd(cCampo, aHdr)
Local aArea 	:= GetArea()

DbSelectArea("SX3")
DbSetOrder(2)

If DbSeek(cCampo)
	AADD(aHdr,{ TRIM(X3_TITULO), X3_CAMPO, X3_PICTURE,;
			X3_TAMANHO, X3_DECIMAL,"AllwaysTrue()",;
			X3_USADO, X3_TIPO, X3_ARQUIVO, X3_CONTEXT})
EndIf
RestArea(aArea)

Return Nil

//------------------------------------------------------------------
/*/{Protheus.doc} CnRetAhd(cCampo, aHeader)
Valid do campo CNX_VLCOMP


@author Matheus Lando Raimundo
@since 19/12/2014
@version P12
/*/
//-------------------------------------------------------------------
Function CnVlComp()
Local lRet := .T.
Local nPosSldAt := aScan(oGetAdia:Aheader,{|x| AllTrim(x[2])=="CNX_SLDATU"})
Local nPosVlComp := aScan(oGetAdia:Aheader,{|x| AllTrim(x[2])=="CNX_VLCOMP"})
Local nPosSld 	:= aScan(oGetAdia:Aheader,{|x| AllTrim(x[2])=="CNX_SALDO"})

If M->CNX_VLCOMP > aColsAux[n,1]
	Help(" ",1,"CN130NVLCOMP")
	lRet := .F.
EndIf

If lRet
	oGetAdia:Acols[n,nPosSld] := aColsAux[n,1] - M->CNX_VLCOMP
	oGetAdia:Refresh()
EndIf

Return lRet

//------------------------------------------------------------------
/*/{Protheus.doc} CnRetTotAd()
Função que retorna o total dos adiantamentos


@author Matheus Lando Raimundo
@since 19/12/2014
@version P12
/*/
//-------------------------------------------------------------------
Function CnRetTotAd()
Local nI 		:= 0
Local nTotal 	:= 0
Local aAdts	:= {}
Local nNumero	:= aScan(oGetAdia:Aheader,{|x| AllTrim(x[2])=="CNX_NUMERO"})
Local nVlr		:= aScan(oGetAdia:Aheader,{|x| AllTrim(x[2])=="CNX_VLCOMP"})

For nI := 1 To Len(oGetAdia:Acols)
	If oGetAdia:Acols[nI, nVlr] > 0
		Aadd(aAdts, {oGetAdia:Acols[nI, nNumero], oGetAdia:Acols[nI, nVlr]})
	EndIf
Next nI

Return aAdts

//------------------------------------------------------------------
/*/{Protheus.doc} CnRetTotAd()
Função que retorna o total dos adiantamentos


@author Matheus Lando Raimundo
@since 19/12/2014
@version P12
/*/
//-------------------------------------------------------------------
Function CnGetTotad()
Local nI := 0
Local nTotal := 0
Local nVlr			:= aScan(oGetAdia:Aheader,{|x| AllTrim(x[2])=="CNX_VLCOMP"})

For nI := 1 To Len(oGetAdia:Acols)
	If oGetAdia:Acols[nI, nVlr] > 0
		nTotal += oGetAdia:Acols[nI, aScan(oGetAdia:Aheader,{|x| AllTrim(x[2])=="CNX_VLCOMP"})]
	EndIf
Next nI

Return nTotal

//------------------------------------------------------------------
/*/{Protheus.doc} CnGrvAdia(aAdiants,nOpc, cNumAd)


@author Matheus Lando Raimundo
@since 19/12/2014
@version P12
/*/
//-------------------------------------------------------------------
Function CnGrvAdia(aAdiants,nOpc, cNumAd)
Local aArea := GetArea()
Local oModel	:= Nil
Local cContra	:= ""
Local cRevisa	:= ""
Local cNumMed	:= ""
Local cNumPla	:= ""
Local aAdts		:= {}
Local cQuery	:= ""
Local cNumero := ""
Local nValor:= 0
Local nDif	:= 0
Local nI 		:= 0
Local lInc := .F.
Local lAltVlr	:= .F.
Local lCn121	:= IsInCallStacK('CNTA121')

Default cNumAd := ""

If lCn121
	oModel	:= FwModelActive()
	cContra	:= oModel:GetValue("CNDMASTER", "CND_CONTRA")
	cRevisa	:= oModel:GetValue("CNDMASTER", "CND_REVISA")
	cNumMed	:= oModel:GetValue("CNDMASTER", "CND_NUMMED")
	cNumPla := oModel:GetValue("CXNDETAIL", "CXN_NUMPLA")
	nOpc 	:= oModel:GetOperation()
Else
	cContra := CND->CND_CONTRA
	cRevisa := CND->CND_REVISA
	cNumMed := CND->CND_NUMMED
	cNumPla := CND->CND_NUMERO
EndIf

If nOpc <> MODEL_OPERATION_DELETE .And. Empty(cNumAd)
	For nI := 1 To Len(aAdiants)
		lInc    := .F.
		lAltVlr    := .F.
		cNumero := aAdiants[nI,1]
		nValor  := aAdiants[nI,2]

		If nOpc == MODEL_OPERATION_INSERT
			DbSelectArea("CZY")
			CZY->(DbsetOrder(2))
			If !CZY->(MsSeek(cFilCTR+cContra+cRevisa+cNumMed+cNumPla+cNumero))
				RecLock( "CZY", .T. )
				CZY->CZY_FILIAL := cFilCTR
				CZY->CZY_CONTRA := cContra
				CZY->CZY_REVISA := cRevisa
				CZY->CZY_NUMMED := cNumMed
				CZY->CZY_NUMPLA := cNumPla
				CZY->CZY_NUMERO := cNumero
				CZY->CZY_VALOR  := nValor
				CZY->( MsUnlock() )

				DbSelectArea("CNX")
				CNX->(DbsetOrder(1))
				If CNX->(MsSeek(xFilial("CNX",cFilCTR)+cContra+cNumero))
					Reclock("CNX",.F.)
					CNX->CNX_SALDO := CNX->CNX_SALDO - nValor
					CNX->(MsUnlock())
				Endif
			EndIf
		ElseIf nOpc == MODEL_OPERATION_UPDATE .Or. IIf(lCn121,IsInCallStack('CN121Encerr'),nOpc == 13)
			DbSelectArea("CZY")
			CZY->(DbsetOrder(2))
			If CZY->(MsSeek(cFilCTR+cContra+cRevisa+cNumMed+cNumPla+cNumero))
				If 	nValor <> CZY->CZY_VALOR
					lAltVlr := .T.
					nDif := nValor - CZY->CZY_VALOR
					RecLock( "CZY", .F. )
					CZY->CZY_VALOR  := nValor
					CZY->( MsUnlock() )
				EndIf
			Else
				lInc := .T.
				//-- Caso seja alteração e não encontrei o registro, inclui.
				RecLock( "CZY", .T. )
				CZY->CZY_FILIAL := cFilCTR
				CZY->CZY_CONTRA := cContra
				CZY->CZY_REVISA := cRevisa
				CZY->CZY_NUMMED := cNumMed
				CZY->CZY_NUMPLA := cNumPla
				CZY->CZY_NUMERO := cNumero
				CZY->CZY_VALOR  := nValor
				CZY->( MsUnlock() )
			EndIf

			DbSelectArea("CNX")
			CNX->(DbsetOrder(1))
			If CNX->(MsSeek(xFilial("CNX",cFilCTR)+cContra+cNumero))
				Reclock("CNX",.F.)
				If lInc
					CNX->CNX_SALDO := CNX->CNX_SALDO - nValor
				ElseIf lAltVlr
					CNX->CNX_SALDO := CNX->CNX_SALDO - nDif
				EndIf
				CNX->(MsUnlock())
			EndIf
		EndIf
	Next nI
Else
	cQuery := " SELECT CZY.R_E_C_N_O_ as RECNO,CZY_NUMERO, CZY.CZY_VALOR "
	cQuery += " FROM "+RetSQLName("CZY")+" CZY "
	cQuery += " WHERE CZY.CZY_FILIAL = '"+xFilial("CND",cFilCTR)+"'"
	cQuery += " AND CZY.CZY_CONTRA = '"+cContra+"'"
	cQuery += " AND CZY.CZY_NUMMED = '"+cNumMed+"'"
	cQuery += " AND CZY.D_E_L_E_T_ = ''"
	If !Empty(cNumAd)
		cQuery += " AND CZY.CZY_NUMERO = '"+cNumAd+"'"
	EndIf
	cQuery := ChangeQuery(cQuery)
	dbUseArea( .t., "TOPCONN", TcGenQry( ,,cQuery ), "TRBCZY", .f., .t. )
	dbSelectArea("CZY")
	While !TRBCZY->(Eof())
		dbGoto(TRBCZY->RECNO)
		Aadd(aAdts, {TRBCZY->CZY_NUMERO, TRBCZY->CZY_VALOR})
		RecLock("CZY", .F.)
		dbDelete()
		CZY->(MsUnlock())
		TRBCZY->(dbSkip())
	EndDo

	//Se não encontrar adiantamento na medição, não é necessário atualizar saldos.
	If Len(aAdts) == 0
		TRBCZY->(dbCloseArea())
		Return
	EndIf

	cQuery := ""
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Filtra Adiantamentos                           ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cQuery := "SELECT CNX.R_E_C_N_O_ as RECNO "
	cQuery += "  FROM "+RetSQLName("CNX")+" CNX "
	cQuery += " WHERE CNX.CNX_FILIAL = '"+xFilial("CNX",cFilCTR)+"'"
	cQuery += "   AND CNX.CNX_CONTRA = '"+cContra+"'"
	cQuery += "   AND CNX.D_E_L_E_T_ = ''"
	If !Empty(cNumAd)
		cQuery += " AND CNX.CNX_NUMERO = '"+cNumAd+"'"
	EndIf

	cQuery := ChangeQuery(cQuery)
	dbUseArea( .t., "TOPCONN", TcGenQry( ,,cQuery ), "TRBCNX", .f., .t. )

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Atualiza os Descontos                          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	dbSelectArea("CNX")
	While !TRBCNX->(Eof())
		dbGoto(TRBCNX->RECNO)
		nPos := aScan( aAdts, {|x| AllTrim(x[1]) == CNX->CNX_NUMERO  } )
		If nPos > 0
			RecLock("CNX", .F.)
			CNX->CNX_SALDO := CNX->CNX_SALDO + aAdts[nPos, 2]
			CNX->(MsUnlock())
		Endif
		TRBCNX->(dbSkip())
	EndDo

	TRBCZY->(dbCloseArea())
	TRBCNX->(dbCloseArea())
EndIf

RestArea(aArea)

Return

//------------------------------------------------------------------
/*/{Protheus.doc} CNAdTdOk()
TudoOk da GetDados de Adiantamentos


@author Matheus Lando Raimundo
@since 19/12/2014
@version P12
/*/
//-------------------------------------------------------------------
Function CNAdTdOk()
Local oModel	:= NIL
Local oModelCXN	:= NIL
Local lRet		:= .T.
Local nNum		:= 0
Local nTotPla	:= 0

If IsInCallStack("CNTA121")
	oModel := FwModelActive()
	oModelCXN := oModel:GetModel("CXNDETAIL")
	nTotPla := oModelCXN:GetValue("CXN_VLTOT")
	nNum := Cn121TotAd()

	If nNum > nTotPla
		Aviso (STR0056, STR0072, { STR0058 }, 2 ) // "Atencao!", "Os Adiantamentos não podem ultrapassar o total das medições/entregas", { "Ok" }
		lRet := .F.
	EndIf
Else
	nNum := CnGetTotad()

	If nNum > M->CND_VLTOT
		Aviso (STR0056, STR0072, { STR0058 }, 2 ) // "Atencao!", "Os Adiantamentos não podem ultrapassar o total das medições/entregas", { "Ok" }
		lRet := .F.
	EndIf
Endif

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc}CN130MdEmp
Função que retorna os itens vinculado a nota de empenho.

@author taniel.silva
@since 22/01/2015
@version P12
/*/
//-------------------------------------------------------------------
Function CN130MdEmp(aCols,aMedEmp)
Local nPosCodNE		:= GDFIELDPOS("CNE_CODNE")
Local nPosItemNE	:= GDFIELDPOS("CNE_ITEMNE")
Local nPosProd  	:= GDFIELDPOS("CNE_PRODUT")
Local nPosVlT   	:= GDFIELDPOS("CNE_VLTOT ")
Local nPos			:= 0
Local nX			:= 0

If !Empty(aCols)
	For nX := 1 To Len(aCols)
		If !Empty(aCols[nX][nPosCodNE]) .And. !GdDeleted(nX)
			If !Empty(aMedEmp)
				nPos := aScan(aMedEmp,{|x| AllTrim(x[1]) + AllTrim(x[2]) + AllTrim(x[3]) == AllTrim(aCols[nX][nPosProd]) + AllTrim(aCols[nX][nPosCodNE]) + AllTrim(aCols[nX][nPosItemNE])})
				If nPos > 0
					aMedEmp[nPos][4] += aCols[nX][nPosVlT]
				Else
					Aadd(aMedEmp,{aCols[nX][nPosProd],aCols[nX][nPosCodNE],aCols[nX][nPosItemNE],aCols[nX][nPosVlT]})
				EndIf
			Else
				Aadd(aMedEmp,{aCols[nX][nPosProd],aCols[nX][nPosCodNE],aCols[nX][nPosItemNE],aCols[nX][nPosVlT]})
			EndIf
		EndIf
	Next nX
EndIf

Return nil
//------------------------------------------------------------------
/*/{Protheus.doc} CN130VlNE()
Funcao para Verificar se a nota de empenho informada possui relacao com o Edital.

@author Bruno Amate Schmidt
@since 20/07/2015
@version P12
/*/
//-------------------------------------------------------------------
Function CN130VlNE()

Local aArea		:= GetArea()
Local cCodEdt		:= ""
Local cNumProc	:= ""
Local cNumAta		:= ""
Local lRet		:= .T.
Local nCodNe 		:= 0
Local nCodPrd		:= 0

CN9->(DbSetOrder(1))
CN9->(DbSeek(xFilial("CN9")+M->CND_CONTRA+M->CND_REVISA))

cCodEdt	:= CN9->CN9_CODED
cNumProc	:= CN9->CN9_NUMPR
cNumAta	:= CN9->CN9_NUMATA

nCodNe		:=	aScan(aHeader,{|x| Trim(x[2])=="CNE_CODNE"})
nCodPrd	:= aScan(aHeader,{|x| Trim(x[2])=="CNE_PRODUT"})

If !Empty(cCodEdt)
	If !Empty(M->CNE_CODNE)
		//-- Verifica se a nota de empenho informada existe
		CX0->(DbSetOrder(1))
		If !CX0->(DbSeek(xFilial("CX0")+M->CNE_CODNE))
			Help("",1,"A300SNEED",,STR0111,4,1)
			lRet := .F.
		EndIf
		//-- Verifica se a nota de empenho informada tem relacao com o Edital informado
		CX0->(DbSetOrder(2))
		If lRet .and. CX0->(DbSeek(xFilial("CX0")+cCodEdt+cNumProc+cNumAta))
			If M->CNE_CODNE = CX0->CX0_CODNE
				lRet := .T.
			Else
				Help("",1,"A300SNEED",,STR0112,4,1)
				lRet := .F.
			EndIf
		EndIf
	EndIf
	//-- Verifica se o Item informado realmente existe para o produto do aCols
	If lRet .and. !Empty(M->CNE_ITEMNE) .and. !Empty(Acols[n][nCodNe])
		CX1->(DbSetOrder(2))
		If !CX1->(DbSeek(xFilial("CX1")+Acols[n][nCodNe]+M->CNE_ITEMNE+Acols[n][nCodPrd]))
			Help("",1,"A300SLDITNE",,STR0113,4,1)
			lRet := .F.
		EndIf
	EndIf
EndIf

RestArea(aArea)

Return lRet

//Função para avaliar se o gatilho da CNE_VLUNIT será executado ou não
Function CN130GATCNE(nSec)
Local lRet := .F.

//Verifica a sequencia e se os campos utilizados estão preenchidos
Do Case
	Case nSec == 3
		If !Empty(M->CNE_VLTOT) .And. !Empty(M->CNE_VUNORI)
			lRet := .T.
		EndIf
	Case nSec == 4
		If !Empty(M->CNE_QTDORI) .And. !Empty(M->CNE_QTDSOL)
			lRet := .T.
		EndIf
End Case

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc}CN130Liq
Calcula o valor liquido dos itens

@author jose.delmondes
@since 21/11/2017
@version P12
/*/
//-------------------------------------------------------------------
Function CN130Liq(cEspCtr, nTotItem, nDescItem, nTotMed, nTotMulta, nTotBoni, nTotDesc, nTotCauc, nTotAdi)
Local nValLiq	:= 0	//-- Valor liquido do item
Local nPercent	:= 0	//-- Percentual que o valor total do item representa sobre o valor total da medicao
Local nMulta	:= 0	//-- Valor proporcional de multa
Local nBonifi	:= 0	//-- Valor proporcional de bonificacao
Local nDescMed	:= 0	//-- Valor proporcional do desconto da medicao
Local nCaucao	:= 0	//-- Valor proporcional do caucao retido
Local nAdiant	:= 0	//-- Valor proporcional do adiantamento

nPercent	:= (nTotItem - nDescItem) / nTotMed
nMulta		:= nTotMulta * nPercent
nBonifi		:= nTotBoni * nPercent
nDescMed	:= nTotDesc * nPercent
nCaucao		:= nTotCauc * nPercent
nAdiant		:= nTotAdi * nPercent

nValLiq := nTotItem - nDescItem - nDescMed - nCaucao - nAdiant

If cEspCtr == '1'
	nValLiq +=  nBonifi - nMulta	//-- Para contratos de compra, soma a bonificacao e subtrai a multa
Else
	nValLiq +=  nMulta - nBonifi 	//-- Para contratos de venda, soma a multa e subtrai a bonificacao
EndIf

Return nValLiq

//-------------------------------------------------------------------
/*/{Protheus.doc} ChkProd
Verifica se o produto existe no Array

@author juan.felipe
@since 20/02/2019
@version P12
@return lReturn, lógico, .T. caso encontre o produto
@param aLinha, array, contém os produtos da planilha
@param cProduto, string, produto validado no array
@type function
/*/
//-------------------------------------------------------------------
Static Function ChkProd(aLinha As Array, cProduto As Char) As Logical
	Local lReturn As Logical
	Local nPosProd As Numeric
	
	nPosProd := aScan(aLinha,{|x| AllTrim(x[1]) == 'CNE_PRODUT'})
	
	If (nPosProd > 0)
		lReturn := AllTrim(aLinha[nPosProd,2]) == AllTrim(cProduto)
	Else
		lReturn := .F.
	EndIf
	
Return lReturn

