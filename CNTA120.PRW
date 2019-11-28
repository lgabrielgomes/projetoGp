#INCLUDE "CNTA120.CH" 
#INCLUDE "PROTHEUS.CH"
#INCLUDE "ApWizard.ch"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "GCTXDEF.CH"

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

//Transacoes
#DEFINE DEF_TRAINC "021"//Inclusao de Medicoes
#DEFINE DEF_TRAEDT "022"//Edicao de Medicoes
#DEFINE DEF_TRAEXC "023"//Exclusao de Medicoes
#DEFINE DEF_TRAENC "024"//Encerramento de Medicoes
#DEFINE DEF_TRAEST "025"//Estorno de Medicoes

STATIC lMedicao := IsInCallStack("TECA930") .or. IsInCallStack("TECA934") .or. IsInCallStack("TECA934A")

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ CNTA120  ³ Autor ³ Marcelo Custodio      ³ Data ³09.02.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Manutencao de Medicoes                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CNTA120()                                                  ³±±
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
Function CNTA120(xAutoCab,xAutoItens,nOpcAuto,cRotina,xOrigem,xShow,xExcede,aMltsGCT,aDescMed,lRetAut)
Local aCores 	:= {}
Local aIndexCND	:= {}
Local aCoresUsr := {}

Local cRoda     := ""
Local cFiltro	:= ""
Local cCn120Fil := ""
Local cContra	:= ""
Local cPlan		:= ""

Local nx		:= 0
Local nLinPos	:= 0
Local nScan     := 0

Local xRet      := NIL
Local lFixo     := .T.

Default xOrigem		:= FUNNAME()
Default xShow   	:= .F.
Default aMltsGCT	:= {}
Default aDescMed	:= {}
Default lRetAut		:= .T.
Default nOpcAuto 	:= 3

Private bFiltraBrw	:= {|| Nil }
Private lAuto 		:= (valType(xAutoCab) == "A" .And. valType(xAutoItens) == "A")
Private aAutoCab	:= xAutoCab
Private aAutoItens	:= xAutoItens
Private aAutoExced  := xExcede
Private aMultasGCT  := aMltsGCT
Private cCadastro 	:= STR0001//"Manutenção das Medições"

Private aRotina 	:= MenuDef()
Private cOrigem		:= Alltrim(xOrigem)
Private lShow		:= xShow
Private cFilCTR   	:= cFilAnt

//Desabilita na tela da medicao do contrato a tecla F4
SetKey( VK_F4, Nil )

aCores :=  {	{"!Empty(CND->CND_DTFIM) .AND. !Empty(CND->CND_PEDIDO) 	.AND. CND->CND_ALCAPR == 'T'", 	"BR_PINK"},;			//"Medição Totalmente Devolvida "
   				{"!Empty(CND->CND_DTFIM) .AND. !Empty(CND->CND_PEDIDO) 	.AND. CND->CND_ALCAPR == 'P'", 	"BR_VERDE_ESCURO"},;	// "Medição Parcialmente Devolvida "
				{ "Empty(CND->CND_DTFIM) .AND. CND->CND_ALCAPR = 'L'  	.AND. CND->CND_AUTFRN == '1'	.AND. CND->CND_SERVIC == '1'", 	"BR_VERMELHO"},; 			//"Medicao em aberto"
  				{ "Empty(CND->CND_DTFIM) .AND. CND->CND_ALCAPR = 'B'  	.AND. CND->CND_AUTFRN == '1'" , "BR_PRETO"     },;		//"Medicao Bloqueada"
   				{ "!Empty(CND->CND_DTFIM).AND. CND->CND_AUTFRN == '1' 	.AND. CND->CND_SERVIC == '1'" , "BR_VERDE"},;			//"Medicao Encerrada"
   				{ "Empty(CND->CND_DTFIM) .AND. Empty(CND->CND_PEDIDO) 	.AND. CND->CND_AUTFRN == '2'" , "BR_LARANJA"   },;		//"Aut. Fornec. Sem Pedido"
   				{ "Empty(CND->CND_DTFIM) .AND. !Empty(CND->CND_PEDIDO)	.AND. CND->CND_AUTFRN == '2'" , "BR_AZUL"      },;		//"Aut. Fornec. Aberta"
   				{"!Empty(CND->CND_DTFIM) .AND. !Empty(CND->CND_PEDIDO)	.AND. CND->CND_AUTFRN == '2'" , "BR_CINZA"     },; 		//"Aut. Fornec. Encerrada"
   				{ "Empty(CND->CND_DTFIM) .AND. CND->CND_SERVIC == '2'" , "BR_AMARELO"   },;										//"Med. Servic. Aberta"
   				{"!Empty(CND->CND_DTFIM) .AND. CND->CND_SERVIC == '2'" , "BR_VIOLETA"   }; 										//"Med. Servic. Encerrada"
   			}

If !lAuto
	If ValType( cRotina ) == "C"
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Faz tratamento para chamada por outra rotina             ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If !Empty( nScan := AScan( aRotina, { |x| Upper( x[2] ) == Upper( cRotina ) .And. x[4] == nOpcAuto } ) )
			cRoda := cRotina + "( 'CND', CND->( Recno() ), " + Str(nScan,2) + ")"
			xRet  := Eval( { || &( cRoda ) } )
		EndIf
	Else
		If ExistBlock("CN120FIL")
			cCn120Fil := ExecBlock("CN120FIL",.F.,.F.)
			If ( ValType(cCn120Fil) == "C" ) .And. !Empty(cCn120Fil)
				cFiltro := cCn120Fil
			EndIf
		EndIf

		cFiltro := "!Empty(CND_NUMERO) " + IIf(!Empty(cFiltro), " .And. ", "") + cFiltro

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Ponto de entrada para personalizar as cores X situacoes da legenda   ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If ( ExistBlock("CN120COR") )
			aCoresUsr := ExecBlock("CN120COR",.F.,.F.,{aCores})
			If ( ValType(aCoresUsr) == "A" )
				aCores := aClone(aCoresUsr)
			EndIf
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ mv_par01 - Mostra Lancamentos   S/N                          ³
		//³ mv_par02 - Aglut Lancamentos    S/N                          ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		SetKey(VK_F12,{|| Pergunte("CNT120",.T.)})

		mBrowse(6,1,22,75,"CND",,,,,,aCores,,,,,,,,,,,,cFiltro)

		FWSetShowKeys(.T.)
		SetKey( VK_F12 , Nil )

		If ( Len(aIndexCND)>0 )
			EndFilBrw("CND",aIndexCND)
		EndIf
	EndIf
Else
	If (nPos := aScan(aAutoCab,{|x| x[1]=="CND_CONTRA"})) > 0
		cContra := aAutoCab[nPos,2]
	EndIf

	If (nPos := aScan(aAutoCab,{|x| x[1]=="CND_NUMERO"})) > 0
		cPlan   := aAutoCab[nPos,2]
	EndIf

	If (nPos := aScan(aAutoCab,{|x| x[1]=="CND_FILCTR"})) > 0
		cFilCTR := aAutoCab[nPos,2]
	EndIf

	lFixo  := CN300RetSt("FIXO",0,cPlan,cContra,cFilCTR)

	If lFixo
		For nx:=1 to len(aAutoItens)
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Verifica campo LINPOS dos itens da rotina automatica ³
			//³pois a inclusao de medicao implica em alterar o acols³
			//³gerado com base na estrutura da planilha             ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If (nLinPos:=aScan(aAutoItens[nx],{|x| AllTrim(x[1])=="LINPOS"}))>0
				aAutoItens[nx,nLinPos,3] := aAutoItens[nx,aScan(aAutoItens[nx],{|x| AllTrim(x[1])=="CNE_ITEM"}),2]
			Else
				aadd(aAutoItens[nx],{"LINPOS","CNE_ITEM",aAutoItens[nx,aScan(aAutoItens[nx],{|x| AllTrim(x[1])=="CNE_ITEM"}),2]})
			EndIf
		Next
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Executa rotina automatica               ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lMedicao .OR. ( FindFunction("TEC930Test") .AND. TEC930Test() )
		lRetAut := CN121Auto(xAutoCab,xAutoItens,nOpcAuto,aAutoExced,aMltsGCT,aDescMed)
	Else
		MBrowseAuto(nOpcAuto,Aclone(aAutoCab),"CND")
	Endif

	aAutoExced := {}
	aMultasGCT := {}

EndIf

Return( xRet )

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN120Manut³ Autor ³ Marcelo Custodio      ³ Data ³09.02.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Verifica situacao da medicao antes de alterar/excluir      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN120Manut(cExp01,nExp02,nExp03)                           ³±±
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
Function CN120Manut(cAlias,nReg,nOpc)
Local lContinua := .T.
Local aValidGet := {}
Local nPosNum
Local cChave    := ""
Local dDataBloq	:= GetNewPar("MV_ATFBLQM",CTOD("")) //Data de Bloqueio da Movimentação - MV_ATFBLQM

If Type('lAuto') == 'U'
	lAuto := IsBlind()
EndIf

nPosPln         := 0
cFilCtr := CND->CND_FILCTR

If lAuto
	//Verifica se existe bloqueio contábil
	If lContinua := CtbValiDt(Nil, dDataBase,/*.T.*/ ,Nil ,Nil ,{"GCT001"}/*,"Data de apuração bloqueada pelo calendário contábil."*/)
		If!Empty(dDataBloq) .AND. ( dDataBase <= dDataBloq)
			//Help(" ",1,"AF012ABLQM",,"Processo bloqueado pelo Calendário Contábil nesta data ou período. Caso possível altere a data de referência do processo ou contate o responsável pelo Módulo Contábil.",1,0) //"Processo bloqueado pelo Calendário Contábil nesta data ou período. Caso possível altere a data de referência do processo ou contate o responsável pelo Módulo Contábil."
			Help(" ",1,"ATFCTBBLQ") //P: Processo bloqueado pelo Calendário Contábil ou parâmetro de bloqueio nesta data ou período. S: Caso possível altere a data de referência do processo, verifique o parâmetro ou contate o responsável pelo Módulo Contábil.)
			lContinua := .F.
		EndIf
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Verifica se o numero da medicao foi fornecido      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If (nPosNum:=aScan(aAutoCab,{|x| x[1]=="CND_NUMMED"})) > 0
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Valida numero da medicao                           ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		AADD(aValidGet,{"cNumMed" ,aAutoCab[nPosNum,2],"CN120NumAuto(cNumMed,.F.)",.T.})

		If (lContinua := MsVldGAuto(aValidGet))
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Posiciona na medicao                               ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			dbSelectArea("CND")
			If (nPosPln:=aScan(aAutoCab,{|x| x[1]=="CND_NUMERO"})) > 0
				CND->(dbSetOrder(1))

				CND->(dbSeek( xFilial("CND")							+ ;
				aAutoCab[aScan(aAutoCab,{|x| x[1]=="CND_CONTRA"}),2]	+ ;
				aAutoCab[aScan(aAutoCab,{|x| x[1]=="CND_REVISA"}),2]	+ ;
				aAutoCab[nPosPln,2]										+ ;
				aAutoCab[nPosNum,2]))

			Else
				CND->(dbSetOrder(4))
				CND->(dbSeek(xFilial("CND")+aAutoCab[nPosNum,2]))
			Endif
			nReg := CND->(Recno())
		EndIf
	else
		lContinua:=.F.
	EndIf
EndIf


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Verifica se o usuario tem permissao de delecao. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lContinua .And. nOpc == 5
	
	lContinua := cn120vldMov(cFilCtr,CND->CND_CONTRA,CND->CND_REVISA)

	If lContinua
		aArea2 := GetArea()
		CNE->(dbSeek(xFilial("CNE")+CND->(CND_CONTRA+CND_REVISA+CND_NUMERO+CND_NUMMED)))
		While !CNE->(Eof()) .And. lContinua .And. ;
			xFilial("CNE")+CNE->(CNE_CONTRA+CNE_REVISA+CNE_NUMERO+CNE_NUMMED)==CND->(CND_FILIAL+CND_CONTRA+CND_REVISA+CND_NUMERO+CND_NUMMED)
			lContinua := MaAvalPerm(1,{CNE->CNE_PRODUT,"CNT120",5})
			CNE->(dbSkip())
		End
		RestArea(aArea2)
		If !lContinua
			Help(,,1,'SEMPERM')
		EndIf
	EndIf

	//Verifica se existe bloqueio contábil
	If lContinua .And. (lContinua := CtbValiDt(Nil, dDataBase,/*.T.*/ ,Nil ,Nil ,{"GCT001"}/*,"Data de apuração bloqueada pelo calendário contábil."*/))
		If!Empty(dDataBloq) .AND. ( dDataBase <= dDataBloq)
			//Help(" ",1,"AF012ABLQM",,"Processo bloqueado pelo Calendário Contábil nesta data ou período. Caso possível altere a data de referência do processo ou contate o responsável pelo Módulo Contábil.",1,0) //"Processo bloqueado pelo Calendário Contábil nesta data ou período. Caso possível altere a data de referência do processo ou contate o responsável pelo Módulo Contábil."
			Help(" ",1,"ATFCTBBLQ") //P: Processo bloqueado pelo Calendário Contábil ou parâmetro de bloqueio nesta data ou período. S: Caso possível altere a data de referência do processo, verifique o parâmetro ou contate o responsável pelo Módulo Contábil.)
			lContinua := .F.
		EndIf
	EndIf
EndIf

dbSelectArea("CND")
dbSetOrder(1)
MsGoTo(nReg)

If lContinua
	lContinua := CN240VldUsr(CND->CND_CONTRA,If(aRotina[nOpc,4]==4,DEF_TRAEDT,DEF_TRAEXC),.T.,,cFilCtr)
EndIf

//Verifica se existe bloqueio contábil
If lContinua .And. (lContinua := CtbValiDt(Nil, dDataBase,/*.T.*/ ,Nil ,Nil ,{"GCT001"}/*,"Data de apuração bloqueada pelo calendário contábil."*/))
	If!Empty(dDataBloq) .AND. ( dDataBase <= dDataBloq)
		//Help(" ",1,"AF012ABLQM",,"Processo bloqueado pelo Calendário Contábil nesta data ou período. Caso possível altere a data de referência do processo ou contate o responsável pelo Módulo Contábil.",1,0) //"Processo bloqueado pelo Calendário Contábil nesta data ou período. Caso possível altere a data de referência do processo ou contate o responsável pelo Módulo Contábil."
		Help(" ",1,"ATFCTBBLQ") //P: Processo bloqueado pelo Calendário Contábil ou parâmetro de bloqueio nesta data ou período. S: Caso possível altere a data de referência do processo, verifique o parâmetro ou contate o responsável pelo Módulo Contábil.)
		lContinua := .F.
	End
EndIf

If lContinua
	cChave := CND->CND_CONTRA+CND->CND_REVISA+CND->CND_NUMERO+CND->CND_NUMMED
	If LockByName("CN120"+xFilial("CND")+cChave,.T.,!Empty(xFilial("CND")),.T.)
		If Cn300RetSt("VENDA",,,CND->CND_CONTRA) .And. (CND->CND_LJFORN == ',' .Or. CND->CND_LJFORN == '.')
			lContinua := .F.
			HELP(" ",1,STR0152) //"Medições que sofreram devolução não podem ser alteradas!"
		EndIf
	
		If lContinua
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Adiciona valor previsao a estrutura da planilha    ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If Empty(CND->CND_DTFIM)
				CN130Manut(cAlias,nReg,nOpc,Nil,CND->CND_CONTRA,CND->CND_REVISA,,CND->CND_NUMERO)
			Else
				Help( " ", 1, "CNTA120_03" )//"Medição ja encerrada"
			EndIf
		EndIf
	Else
		// Nao permite processamento concorrente
		Aviso(STR0068,OemtoAnsi(STR0069),{STR0155},2) // ##"Concorrência"##"Esta Medição está em uso por outra estação."
	EndIf
	UnLockByName("CN120"+xFilial("CND")+cChave,.T.,!Empty(xFilial("CND")),.T.)
EndIf

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN120Leg    ³ Autor ³ Fabio Alves Silva     ³ Data ³26.12.2005³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Rotina de legenda da Medicao                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN120Legenda(nExp01,nExp02)                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ CNTA120                                                      ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function CN120Leg()

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Array com as cores que representam a situacao de cada Medicao na mBrowse.   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Local aLegenda := 		{	{"BR_VERMELHO", OemtoAnsi(STR0040)	},; // "Medicao em aberto"
							{"BR_PRETO"   , OemtoAnsi(STR0048)	},; // "Medicao bloqueada por Alçada"
							{"BR_VERDE"   , OemtoAnsi(STR0041)	}} 	// "Medicao encerrada"
Local aLegeUsr := {}

//Autorizacao de Fornecimento
aAdd(aLegenda,{"BR_AZUL"    	, OemtoAnsi(STR0052)})  						// "Autorização de Fornecimento Aberta"
aAdd(aLegenda,{"BR_CINZA"   	, OemtoAnsi(STR0053)}) 			 				// "Autorização de Fornecimento Encerrada"
aAdd(aLegenda,{"BR_LARANJA"    	, OemtoAnsi(STR0055)})  						// "Autorização de Fornecimento Sem Pedido"

aAdd(aLegenda,{"BR_AMARELO"   	, OemtoAnsi(STR0177)})  // "Medição de Serviço Aberta"
aAdd(aLegenda,{"BR_VIOLETA"   	, OemtoAnsi(STR0178)})  // "Medição de Serviço  Encerrada"
aAdd(aLegenda,{"BR_PINK"		, OemtoAnsi(STR0179)})	// "Medição Totalmente Devolvida"
aAdd(aLegenda,{"BR_VERDE_ESCURO", OemtoAnsi(STR0180)})	// "Medição Parcialmente Devolvida"

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Ponto de entrada para personalizar as cores da legenda      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If ( ExistBlock("CN120LEG") )
	aLegeUsr := ExecBlock("CN120LEG",.F.,.F.,{aLegenda})
	If ( ValType(aLegeUsr) == "A" )
		aLegenda := aClone(aLegeUsr)
	EndIf
EndIf

BrwLegenda(cCadastro, OemtoAnsi(STR0042), aLegenda)//"Legendas"

Return .T.

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN120Inc  ³ Autor ³ Marcelo Custodio      ³ Data ³09.02.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Inclui Medicao - Exibe tela para selecao de contrato,      ³±±
±±³          ³ competencia e planilha                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CNTA120Inc(cExp01,nExp02,nExp03)                           ³±±
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
Function CN120Inc(cAlias,nReg,nOpc,aVar,nTipo,nServico)
Local aValidGet   := {}
Local aRet        := {}
Local aTitle      := {}
Local aCampos	  := {}
Local aCn120ctaut := {}

Local cArqCNA     := ""
Local cLine       := ""
Local cCn120Sxb   := ""
Local cConsSxb    := "CN9003"

Local oDlg	      := NIL
Local oGet01	  := NIL
Local oOk         := LoadBitmap( GetResources(), "LBTIK" )
Local oNo  		  := LoadBitmap( GetResources(), "LBNO" )
Local oSize

Local nOpca       := 0
Local nPos	      := 0
Local nSaveSX8   	:= 1

Local lRet		  := .T.
Local lFisico     := .F.
Local lCn120ctaut := ExistBlock("CN120CTAUT")
Local lCn120Sxb   := ExistBlock("CN120SXB")
Local lCn120BOk   := ExistBlock("CN120BOK")
Local lCN120SEMED	:= ExistBlock("CN120SEMED")

DEFAULT nTipo     := 1
DEFAULT nServico  := 1

Private cNumMed   := ""
Private cPlan     := ""
Private cParcel   := ""
Private cContra   := Space(TamSX3("CN9_NUMERO")[1])
Private cRevisa   := Space(TamSX3("CN9_REVISA")[1])
Private cCompet   := Space(TamSX3("CNF_COMPET")[1])

Private oBrowse
Private oCbx

Private lMedEve := .F.//medicao Eventual
Private lFixo   := .T.//Contrato Fixo
Private oTempCNA	:= Nil

cFilCtr := cFilAnt

If !lAuto
	//-- Monta variaveis da montagem do browse de planilhas
	CN120Plans(@oTempCNA,@aTitle,@aCampos,@cLine)

	If lCn120ctaut
		aCn120ctaut := ExecBlock("CN120CTAUT",.F.,.F.)
  		If ValType(aCn120ctaut) == "A"
  			cContra := aCn120ctaut[1]
	  		If !Empty(aCn120ctaut[2])
	  			cRevisa := aCn120ctaut[2]
	  		EndIf
	  		If !Empty(aCn120ctaut[3])
				cCompet := aCn120ctaut[3]
			EndIf
		EndIf
	EndIf

	If lCn120Sxb
		cConsSxb := If(Valtype(cCn120Sxb:=ExecBlock("CN120SXB",.F.,.F.))=="C",cCn120Sxb,"CN9003")
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Cria Dialog para selecao de planilha               ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cCadastro := If(nTipo==1.And.nServico==1,STR0001,iIf(nTipo==2,STR0056,STR0083))//"Manutenção Das Medições/entregas"#"Autorização de Fornecimento"

	oSize := FwDefSize():New(.F.)
	oSize:AddObject( "LABEL"    ,  100, 10, .T., .F. ) // Nao dimensiona Y
	oSize:AddObject( "GRID"  	,  100, 70, .T., .T. ) // Totalmente dimensionavel
	oSize:AddObject( "BUTTONS"  ,  100, 10, .T., .F. ) // Nao dimensiona Y

	oSize:lProp := .T. // Proporcional
	oSize:aMargins := { 3, 3, 3, 3 } // Espaco ao lado dos objetos 0, entre eles 3

	oSize:Process() // Dispara os calculos

	DEFINE MSDIALOG oDlg TITLE cCadastro;
						FROM oSize:aWindSize[1],oSize:aWindSize[2] TO oSize:aWindSize[3],oSize:aWindSize[4] OF oMainWnd PIXEL

	@ oSize:GetDimension("LABEL","LININI")  , oSize:GetDimension("LABEL","COLINI")  		SAY OemToansi(RetTitle("CN9_NUMERO")) SIZE 73, 8 OF oDlg PIXEL
	@ oSize:GetDimension("LABEL","LININI")  , oSize:GetDimension("LABEL","COLINI")+34  	MSGET oGet01 VAR cContra PICTURE PesqPict("CN9","CN9_NUMERO") F3 cConsSxb SIZE 60,9 VALID CN120VlCon(nTipo,,@cFilCTR) OF oDlg PIXEL

	@ oSize:GetDimension("LABEL","LININI")  , oSize:GetDimension("LABEL","COLINI")+101  SAY OemToansi(RetTitle("CNF_COMPET")) SIZE 73, 8 OF oDlg PIXEL
	@ oSize:GetDimension("LABEL","LININI")  , oSize:GetDimension("LABEL","COLINI")+134 ComboBox oCbx Var cCompet ON CHANGE CN120Compet(,cFilCTR) SIZE 50,9 OF oDlg PIXEL

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Configura browse    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	oBrowse := TWBrowse():New( oSize:GetDimension('GRID','LININI'),oSize:GetDimension('GRID','COLINI'),;
					 			oSize:GetDimension('GRID','XSIZE'),oSize:GetDimension('GRID','YSIZE'),;
					 			{|| {aCampos} },aTitle,{030,090},oDlg,,,,,,,,,,,,,"TRBCNA", .T. )
	oBrowse:bLine := &( "{ || " + cLine + " }" )
	oBrowse:bLDblClick := {|| If(!Empty(TRBCNA->CNA_NUMERO),((cPlan:= TRBCNA->CNA_NUMERO,cParcel:=TRBCNA->CNF_PARCEL), oBrowse:Refresh()),) }

	DEFINE SBUTTON FROM oSize:GetDimension("BUTTONS","LININI")	, oSize:GetDimension("BUTTONS","COLINI")  	When .T. TYPE 1 ACTION (If(CNTVldPlan(cContra,cRevisa,cPlan),(oDlg:End(),nOpca:=1),nOpca:=0)) ENABLE OF oDlg
	DEFINE SBUTTON FROM oSize:GetDimension("BUTTONS","LININI")	, oSize:GetDimension("BUTTONS","COLINI")+40	When .T. TYPE 2 ACTION (oDlg:End(),nOpca:=2) ENABLE OF oDlg

	If lCn120ctaut .and. ValType(aCn120ctaut) == "A"
		dbSelectArea("CN9")
		dbSetOrder(1)
		dbSeek(xFilial("CN9",cFilCTR)+cContra+cRevisa)
		CN120VlCon(nTipo,,cFilCTR)
		oBrowse:SetFocus()
	EndIf

	ACTIVATE MSDIALOG oDlg CENTERED

	// Ponto de Entrada após a confirmação da tela de seleção de Contrato e Planilha
	If lCn120BOk
		ExecBlock("CN120BOK",.F.,.F.,{cContra,cRevisa,cPlan,cParcel})
	Endif

	//- Apaga arquivo temporario
	oTempCNA:Close()
	TecDestroy(oTempCNA)
Else

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Verifica se o cabecalho contem os campos CND_CONTRA,³
	//³CND_REVISA,CND_COMPET,CND_NUMERO essenciais para a  ³
	//³criacao da medicao                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If (nPos := aScan(aAutoCab,{|x| x[1]=="CND_CONTRA"})) > 0
		cContra := aAutoCab[nPos,2]
	Else
		lRet := .F.
	EndIf

	If lRet .And. ((nPos := aScan(aAutoCab,{|x| x[1]=="CND_REVISA"})) > 0)
		cRevisa := aAutoCab[nPos,2]
	Else
		lRet := .F.
	EndIf

	If lRet .And. ((nPos := aScan(aAutoCab,{|x| x[1]=="CND_COMPET"})) > 0)
		cCompet := aAutoCab[nPos,2]
	Else
		lRet := .F.
	EndIf

	If lRet .And. ((nPos := aScan(aAutoCab,{|x| x[1]=="CND_NUMERO"})) > 0)
		cPlan   := aAutoCab[nPos,2]
	Else
		lRet := .F.
	EndIf

	If lRet .And. ((nPos := aScan(aAutoCab,{|x| x[1]=="CND_PARCEL"})) > 0)
		cParcel := aAutoCab[nPos,2]
	Else
		lRet := .F.
	EndIf

	If lRet .And. ((nPos := aScan(aAutoCab,{|x| x[1]=="CND_FILCTR"})) > 0)
		cFilCTR := aAutoCab[nPos,2]
	EndIf

	If lRet .And. (nPos := aScan(aAutoCab,{|x| x[1]=="CND_SERVIC"})) > 0
		nServico := IIF(aAutoCab[nPos,2] == "2",2,1)
	EndIf

	If lRet
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Valida os campos do cabecalho da medicao            ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		AADD(aValidGet,{"cContra" ,aAutoCab[aScan(aAutoCab,{|x| x[1]=="CND_CONTRA"}),2],"CN120VlCon()",.T.})
		AADD(aValidGet,{"cRevisa" ,aAutoCab[aScan(aAutoCab,{|x| x[1]=="CND_REVISA"}),2],"CheckSX3('CND_REVISA',cRevisa) .And. CN120CtrAuto(cContra,cRevisa)",.T.})
		AADD(aValidGet,{"cPlan"   ,aAutoCab[aScan(aAutoCab,{|x| x[1]=="CND_NUMERO"}),2],"CheckSX3('CND_NUMERO',cPlan)",.T.})
		AADD(aValidGet,{"cParcel" ,aAutoCab[aScan(aAutoCab,{|x| x[1]=="CND_PARCEL"}),2],"CheckSX3('CND_PARCEL',cParcel)",.T.})
		AADD(aValidGet,{"cCompet" ,aAutoCab[aScan(aAutoCab,{|x| x[1]=="CND_COMPET"}),2],"CheckSX3('CND_COMPET',cCompet) .And. CN120VldCpt()",.T.})

		If (nPosNum := aScan(aAutoCab,{|x| x[1]=="CND_NUMMED"})) > 0
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Valida campo CND_NUMMED quando fornecido atraves    ³
			//³da rotina automatica                                ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			cNumMed := aAutoCab[nPosNum,2]
			AADD(aValidGet,{"cNumMed" ,aAutoCab[nPosNum,2],"CN120NumAuto(cNumMed,.T.)",.T.})
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³PE para permitir alterar a validacao da rotina automatica ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If ExistBlock("CN120AutVl")
			aRet := ExecBlock("CN120AutVl",.F.,.F.,{aValidGet})

			If valtype(aRet) == "A"
				aValidGet := aRet
			EndIf
		EndIf

		lRet := MsVldGAuto(aValidGet)
		If lRet
			If !lCN120SEMED .Or. (lCN120SEMED .And. !ExecBlock("CN120SEMED",.F.,.F.,{cContra,cRevisa}))
				lRet := !Cn120MedAb(cFilCtr,cContra,cRevisa,cPlan)
				If !lRet
					Help("",1,"CNTA120MAB",,STR0150,4,1,,,,,,{STR0151})
				EndIf
			EndIf
		EndIf
	EndIf
EndIf

dbSelectArea("CN9")
dbSetOrder(1)
dbSeek(xFilial("CN9",cFilCTR)+cContra+cRevisa)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Verifica se o contrato possui cronograma fisico     ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
lFisico := CN300RetSt("FISICO",0,cPlan,cContra,CN9->CN9_FILCTR,.F.)
lMedEve := CN300RetSt("MEDEVE",0,cPlan,cContra,CN9->CN9_FILCTR,.F.)

If nServico == 2 .And. (lFisico .Or. !lFixo .Or. lMedEve)
    Aviso("CNTA120",STR0089,{STR0155},2)
    nOpca:= 2
EndIf

//Se planilha possuir apenas itens de serviço e não possuir cronograma físico a medição será de serviços.
If !lFisico .And. ExistFunc("CnTpProd") .And. CnTpProd("CNTA120", cPlan, cContra, cRevisa) == 2
	nServico = 2
EndIf

If nOpca == 1 .OR. (lAuto .And. lRet)

	If lAuto //se não for lAuto
		//Bloqueia o registro do contrato na tabela CN9
		lRet := SoftLock('CN9',.F.)
		If lRet
			CN9->(msUnlock())
		EndIf
	EndIf

	//Rotina de manutencao de medicoes
	If lRet .And. CN130Manut(cAlias,nReg,nOpc,,cContra,cRevisa,cCompet,cPlan,CN300RetSt("MEDEVE",0,cPlan,cContra,CN9->CN9_FILCTR,.F.),lFisico,cParcel,nTipo,,nServico,@nSaveSX8)
		While ( GetSX8Len() > nSaveSX8 )
			ConfirmSX8()
		EndDo
		EvalTrigger()
		msUnlockAll()
	Else
		While ( GetSX8Len() >= nSaveSX8 )
			RollBackSX8()
		EndDo
	EndIf
Else
	While ( GetSX8Len() >= nSaveSX8 )
		RollBackSX8()
	EndDo
EndIf

Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN120NumAuto³ Autor ³ Marcelo Custodio      ³ Data ³09.02.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Valida numero da medicao na execucao da rotina automatica    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN120NumAuto(cExp01,lExp02)                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ cExp01 - Numero da Medicao                                   ³±±
±±³          ³ lExp02 - Indica se e inclusao                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                              ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function CN120NumAuto(cNumMed,lInc)
Local lRet
Local aArea := GetArea()

dbSelectArea("CND")
dbSetOrder(4)
dbSeek(xFilial("CND")+cNumMed)

lRet := If(lInc,!(Found()),Found())

RestArea(aArea)
Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN120CtrAuto³ Autor ³ Marcelo Custodio      ³ Data ³09.02.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Valida contrato+revisao durante a execucao da rotina         ³±±
±±³          ³ automatica                                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN120CtrAuto(cExp01,cExp02)                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ cExp01 - Codigo do Contrato                                  ³±±
±±³          ³ cExp02 - Codigo da revisao                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                              ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function CN120CtrAuto(cContra,cRevisa,lExcede)
Local lRet      := .T.
Local lCN120CTU := .T.

Default lExcede := .F.

dbSelectArea("CN9")
CN9->(dbSetOrder(1))

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Posiciona no contrato                              ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
lRet := dbSeek(xFilial("CN9",cFilCTR)+cContra+cRevisa)

If lRet
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Verifica a situacao do contrato                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	lRet := (CN9->CN9_SITUAC == DEF_SVIGE)

	If lRet
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Verifica o acesso do usuario                       ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		lRet := CN240VldUsr(cContra,DEF_TRAINC,.T.,,cFilCtr)

		If lRet .And. lExcede
			If CN9->CN9_ESPCTR == "1"
				Aviso("CNTA120",STR0090,{STR0155}) //-- Funcionalidade indisponível para contratos de compra.
				lRet := .F.
			ElseIf Empty(CN9->CN9_CLIENT)
				Aviso("CNTA120",STR0090,{STR0155}) //-- Funcionalidade indisponível para contratos de compra.
				lRet := .F.
			EndIf

		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Executa ponto de entrada após validação do acesso ao usuário  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If ExistBlock("CN120CTU")
		   lCN120CTU := ExecBlock("CN120CTU",.F.,.F.,{lRet})
		  	If ValType(lCN120CTU) == "L"
				lRet := lCN120CTU
			EndIf
  		EndIf
	EndIf
EndIf

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN120VlCon³ Autor ³ Marcelo Custodio      ³ Data ³09.02.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Valida contrato e preenche competencias                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN120VlCon()                                               ³±±
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
Function CN120VlCon(nTipo,lExcede,cFilCTR)
Local cFilCod	  := ""
Local cCompetbck  := ""
Local cQuery      := ""
Local cCompExce   := ""
Local cProxMed 	  := ""
Local nMes		  := 0
Local nAno		  := 0
Local nMesF		  := 0
Local nAnoF		  := 0
Local nPosProMed  := 0
Local nX		  := 0
Local aDtFim	  := {}
Local aCompets    := {}
Local aCompSemN   := {}
Local aCompExce   := {}
Local lMVC		  := .F.
Local lRecorre 	  := .F.
Local lRecoAdd 	  := .F.
Local lRet        := .T.
Local lCN120DTCON := .T.
Local lIsGs		  := lMedicao .OR. ( FindFunction("TEC930Test") .AND. TEC930Test() )
Local lCn120ctaut := ExistBlock("CN120CTAUT")
Local lVldVige    := GetNewPar("MV_CNFVIGE","N") == "N"
Local lMVCNFCOMP  := SuperGetMv("MV_CNFCOMP",.F.,.F.) //-- Filtra competencias a exibir de acordo com a database
Local bValAno 	  := {|| Val(Subs(CNF->CNF_COMPET,4,4)) <= Year(dDataBase)}
Local bValMes 	  := {|| Val(Subs(CNF->CNF_COMPET,1,2)) <= Month(dDataBase)}
Local oModel	  := Nil
Local oModelCND	  := Nil
Local oModelCXN	  := Nil
Local oModelCNE	  := Nil
Local lPims		  := .F.

DEFAULT nTipo	:= 1
DEFAULT lExcede	:= Iif( ExistFunc('IsExced') , IsExced() , IsInCallStack("CN121ExceC") )
DEFAULT cFilCTR := Iif(!Empty(CN9->CN9_FILCTR),CN9->CN9_FILCTR,cFilAnt)

If Type("cContra") == "U"
	cContra := ""
EndIf

If Type("cCompet") == "U" 
	cCompet := ""
EndIf
If Type('lAuto') == 'U'
   PRIVATE lAuto := (IsInCallStack('MsExecAuto') .Or. IsInCallStack('CNTA260'))
EndIf

If Type('lBack') == 'L' .And. lBack == .T.
	Return .T.
EndIf

If !lAuto .Or. lIsGs
	If (!IsInCallStack('CNTA120') .And. ValType(FWModelActive()) <> "U") .Or. lIsGs
		oModel := FWModelActive()
		lMVC	:= oModel:GetId() == "CNTA121" .And. oModel:IsActive()

		If lMVC
			oModelCND	:= oModel:GetModel("CNDMASTER")
			cContra 	:= oModelCND:GetValue("CND_CONTRA")
		EndIf
	EndIf

	dbSelectArea("CN9")
	CN9->(dbSetOrder(1))
	CN9->(dbSeek(xFilial("CN9",cFilCTR)+cContra))
	
	If !IsBlind() .And. !(CNTVldCTR(cContra,@cFilCtr) .And. CN240VldUsr(cContra,DEF_TRAINC,.T.,,cFilCTR))
		Return .F.
	EndIf

	If !CN9->(dbSeek(xFilial("CN9",cFilCTR)+cContra))
		lRet := .F.
	Else
		//- Valida se o contrato esta em vigencia
		//-- busca revisão vigente
		CN9->(DbSetOrder(7)) // CN9_FILIAL + CN9_NUMERO + CN9_SITUAC
		If CN9->(DbSeek(xFilial("CN9",cFilCtr) + cContra + DEF_SVIGE))
			If !Empty(CN9->CN9_REVATU)
				lRet := .F.
				Help( " ", 1, "CNTA120_REV",,STR0166 ) //
			Else
				cRevisa := CN9->CN9_REVISA
				If lMvc
					oModelCND:LoadValue("CND_REVISA",cRevisa)
					oModelCND:LoadValue("CND_FILCTR",CN9->CN9_FILCTR)
					Cn121Carga(cContra,cRevisa)
				EndIf
			EndIf
		Else
			lRet := .F.
			Help( " ", 1, "CNTA120_02" ) //"Apenas contratos em vigência podem ser medidos"
		Endif

		If lVldVige .and. (CN9->CN9_DTINIC > dDataBase .Or. CN9->CN9_DTFIM < dDataBase)
			lRet := .F.
			Help( " ", 1, "CNTA120_07" ) //Contrato fora do periodo de vigencia
		EndIf
		CN9->(dbSetOrder(1))
	EndIf

	//Bloqueia o registro do contrato na tabela CN9
	If lRet
		lRet := SoftLock('CN9',.F.)
		If lRet
			CN9->(msUnlock())
		EndIf
	EndIf

	If lRet
		//- Verifica Medicao eventual
		dbSelectArea("CN1")
		CN1->(dbSetOrder(1))
		If CN1->(dbSeek(xFilial("CN1",cFilCTR)+CN9->CN9_TPCTO))
			lMedEve := CN300RetSt("MEDEVE",2,,cContra,cFilCTR,.F.) 		//- Verifica Medicao eventual
			lFixo := CN300RetSt("FIXO",2,,cContra,cFilCTR,.F.)			//- Verifica Contrato Fixo
			lRecorre := Cn300RetSt("RECORRENTE",1,,cContra,cFilCTR,.F.)	//- Verifica Contrato Recorrente
			lPims := Cn300RetSt("INTPIMS",1,,cContra,cFilCTR,.F.)
		EndIf
		
		If lPims .And. !IsInCallStack("CN121V2000")
			Help( " ", 1, "CN121PIMS" )//"O contrato possui integração com o PIMS e, por isso, não pode ter a medição inclusa manualmente."
			lRet := .F.
		EndIf

		If AllTrim(CN9->CN9_NUMERO) <> AllTrim(cContra)
			Help(" ",1,STR0114,, CN9->CN9_NUMERO + STR0156 + CHR(13) + STR0157 + cContra ,1,1)
			lRet := .F.
		Endif

		If nTipo == 2 .And. CN1->CN1_ESPCTR == "2"
			Help(" ",1,STR0114,, OemToAnsi(STR0054) ,1,1)
			lRet := .F.
		EndIf

		If lRet .And. lExcede .And. CN1->CN1_ESPCTR == "1"
			Help(" ",1,STR0114,, STR0090 ,1,1)
			lRet := .F.
		EndIf
	Endif

	If lRet
		If !lExcede
			cPlan := ""
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Limpa arquivo temporario                           ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If !lMVC
				dbSelectArea("TRBCNA")
				If RecCount() > 0
					Zap
					oBrowse:Refresh()
				Endif
			EndIf

			nMes := Month(CN9->CN9_DTINIC)
			nAno := Year(CN9->CN9_DTINIC)
			aDtFim := C120CptFim(CN9->CN9_NUMERO, CN9->CN9_REVISA,cValToChar(Month(CN9->CN9_DTFIM))+"/"+cValToChar(Year(CN9->CN9_DTFIM)))
			nMesF:= Val(aDtFim[1])
			nAnoF:= Val(aDtFim[2])

			If !lMedEve .And. lFixo .And. !lRecorre
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Quando o contrato nao tiver medicao eventual       ³
				//³seleciona competencias de acordo com os cronogramas³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				dbSelectArea("CNF")
				cFilCod := xFilial("CNF",cFilCTR)
				CNF->(dbSetOrder(2))
				CNF->(dbSeek(cFilCod+cContra+cRevisa))
				While CNF->CNF_FILIAL = cFilCod .And. CNF->CNF_CONTRA = cContra .And. CNF->CNF_REVISA = cRevisa
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³Exclui parcelas pagas e verifica competencia       ³
					//³contra database                                    ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					If CNF->CNF_SALDO > 0 .And. (!lVldVige .Or. (lVldVige .And. (nAno < Val(Subs(CNF->CNF_COMPET,4,4)) .OR. (nAno = Val(Subs(CNF->CNF_COMPET,4,4)) .And. nMes <= Val(Subs(CNF->CNF_COMPET,1,2)))) .And. aScan(aCompets,CNF->CNF_COMPET) == 0))
						If lMVCNFCOMP
							If CNF->CNF_PERIOD == "1" .And.; 	//-- Periodicidade mensal
									Eval(bValAno) .And.; 		//-- Valida ano
									Eval(bValMes) 				//-- Valida mes
								aAdd(aCompets,CNF->CNF_COMPET)

							ElseIf CNF->CNF_PERIOD == "2" .And.; 	//-- Periodicidade quinzenal
									Eval(bValAno) .And.; 			//-- Valida ano
									Eval(bValMes) .And.; 			//-- Valida mes
									Iif((Day(dDataBase)-15) > 0,Day(CNF->CNF_PRUMED) > 15,Day(CNF->CNF_PRUMED) <= 15) //-- Valida quinzena
								aAdd(aCompets,CNF->CNF_COMPET)

							ElseIf CNF->CNF_PERIOD == "3" .And.;	//-- Periodicidade diaria
									Eval(bValAno) .And.; 			//-- Valida ano
									Eval(bValMes) .And.;			//-- Valida mes
								 	CNF->CNF_PRUMED <= dDataBase  	//-- Valida dia
								aAdd(aCompets,CNF->CNF_COMPET)
							EndIf
						ElseIf !aScan(aCompets,CNF->CNF_COMPET)
							aAdd(aCompets,CNF->CNF_COMPET)
						EndIf
					EndIf
					dbSkip()
				EndDo

				lRecoAdd := Cn300RetSt("RECORRENTE",2)
				// verifica se tem planilhas recorrentes para acrescentar competencias que possam ter sido ignoradas pelo processamento da CNF
				If lRecoAdd
					BeginSQL Alias "CNATMP"
						SELECT CNA.CNA_PROMED
						FROM 	%Table:CNA% CNA
						WHERE	CNA.CNA_FILIAL = %xFilial:CNA% AND CNA.CNA_CONTRA = %Exp:CN9->CN9_NUMERO% AND CNA.CNA_REVISA = %Exp:CN9->CN9_REVISA% AND
								CNA.CNA_PERIOD <> ' ' AND CNA.%NotDel%
					EndSQL

					While !CNATMP->(EOF())
						cProxMed := Dtoc(Stod(CNATMP->CNA_PROMED))
						cProxMed := Substr(cProxMed,4)
						nPosProMed := aScan(aCompets,{ |x| x == cProxMed })
						If nPosProMed == 0
							aAdd(aCompets,cProxMed)
						Endif
						CNATMP->(dbSkip())
					EndDo
					CNATMP->(dbCloseArea())
				Endif
			Else
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Quando o contrato tiver medicao eventual seleciona ³
				//³competencias de acordo com a vigencia do mesmo     ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				While nMes <= nMesF .Or. nAno < nAnoF
					If nMes > 12
						nMes := 1
						nAno++
					EndIf
					If !lMVCNFCOMP .Or. StrZero(nMes,2) +"/" +Str(nAno,4) < StrZero(Month(dDataBase),2) +"/" +Str(Year(dDataBase),4)
						aAdd(aCompets,StrZero(nMes,2) +"/" +Str(nAno,4))
					Else
						Exit
					EndIf
					nMes++
				EndDo
			EndIf

		//Ordena por data
		If !lMVC
			If lCn120ctaut .and. cCompet<>Space(TamSX3("CNF_COMPET")[1])
				cCompetbck := cCompet
				oCbx:aItems := ASort(aCompets,,,{|x,y|  CTOD("01/"+x) < CTOD("01/"+y)  })
				cCompet := cCompetbck
				oCbx:nAT := aScan(oCbx:aItems,cCompet)
				oCbx:Refresh()
			Else
				oCbx:aItems := ASort(aCompets,,,{|x,y|  CTOD("01/"+x) < CTOD("01/"+y)  })
			EndIf
		Else
			aCompets := ASort(aCompets,,,{|x,y|  CTOD("01/"+x) < CTOD("01/"+y)  }) ; aCompSemN := aClone(aCompets)
			For nX := 1 to Len(aCompets)
				aCompets[nX] := CVALTOCHAR(nX)+'='+aCompets[nX]
				aCompSemN[nX] := CVALTOCHAR(nX)
			Next nX
			CN121Cbox(aCompets,aCompSemN,cFilCTR)
		EndIf
	EndIf
EndIf

If lRet
	If lExcede .And. !lRecorre
		cEspCtr := '2'
		cCompExce := Substr(DToS(CN9->CN9_DTINIC),1,6)

		cQuery := "SELECT DISTINCT(CNF.CNF_COMPET) AS CNF_COMPET FROM " +RetSQLName("CNF") +" CNF WHERE "
		cQuery += "CNF.D_E_L_E_T_ <> '*' AND CNF.CNF_FILIAL = '" +xFilial("CNF",cFilCTR) +"' AND "
		cQuery += "CNF.CNF_CONTRA = '" +cContra +"' AND CNF.CNF_REVISA = '" +cRevisa +"' "
		cQuery += "UNION "
		cQuery += "SELECT DISTINCT(CND.CND_COMPET) FROM " +RetSQLName("CND") +" CND WHERE CND.D_E_L_E_T_ <> '*' AND "
		cQuery += "CND.CND_FILCTR = '" + xFilial("CNF",cFilCTR) +"' AND "
		cQuery += "CND.CND_CONTRA = '" +cContra +"' AND "
		cQuery += "CND.CND_REVISA = '" +cRevisa +"' AND CND.CND_COMPET NOT IN ("
		cQuery += "SELECT DISTINCT(CNFTMP.CNF_COMPET) FROM " +RetSQLName("CNF") +" CNFTMP WHERE CNFTMP.D_E_L_E_T_ <> '*' AND "
		cQuery += "CNFTMP.CNF_FILIAL = '" +xFilial("CNF",cFilCTR) +"' AND CNFTMP.CNF_CONTRA = '" +cContra +"' AND "
		cQuery += "CNFTMP.CNF_REVISA = '" +cRevisa +"'"
		cQuery += ")"

		cQuery := ChangeQuery(cQuery)
		dbUseArea(.T.,"TOPCONN",TcGenQry( ,, cQuery ),"QRYTRB",.F.,.T.)

		QRYTRB->(dbEval({|| aAdd(aCompets, Substr(QRYTRB->CNF_COMPET,4,4) + Substr(QRYTRB->CNF_COMPET,1,2))}))
		QRYTRB->(dbCloseArea())

		//-- Monta competencias nao previstas no cronograma.
		While cCompExce <= Substr(DToS(CN9->CN9_DTFIM),1,6)
			If aScan(aCompets, {|x| x == cCompExce}) == 0
				aAdd(aCompExce,Substr(cCompExce,5,2) +"/" +Substr(cCompExce,1,4))
			EndIf

			//-- Incrementa cCompExce
			If Substr(cCompExce,5,2) == '12'
				cCompExce := StrZero(Val(Substr(cCompExce,1,4)) + 1,4) + "01"
			Else
				cCompExce := Substr(cCompExce,1,4) + StrZero(Val(Substr(cCompExce,5,2)) + 1,2)
			EndIf
		EndDo

		If !Empty(aCompExce)
			If !lMVC
				oCbx:aItems := aClone(aCompExce)
				cCompet := oCbx:aItems[1]
			Else
				aCompSemN := aClone(aCompExce)
				For nX := 1 to Len(aCompExce)
					aCompExce[nX] := CVALTOCHAR(nX)+'='+aCompExce[nX]
					aCompSemN[nX] := CVALTOCHAR(nX)
				Next nX
				CN121Cbox(aCompExce,aCompSemN,cFilCTR)
			EndIf
		Else
			Aviso(STR0114,STR0115,{STR0155}) //-- Não há competências não previstas para este contrato.
			lRet := .F.
		EndIf
	EndIf
EndIf

	If lRet .And. !lMVC
		CN120Compet(lExcede,cFilCTR)
	EndIf

ElseIf IsInCallStack('CN260Exc121')
	oModel  	:= FWModelActive()
	oModelCND	:= oModel:GetModel("CNDMASTER")
	cContra 	:= oModelCND:GetValue("CND_CONTRA")

	If (lRet := (CNTVldCTR(cContra,cFilCTR) .And. CN240VldUsr(cContra,DEF_TRAINC,.T.,,cFilCTR)))
		CN9->(DbSetOrder(7)) // CN9_FILIAL + CN9_NUMERO + CN9_SITUAC

		If CN9->(DbSeek(xFilial("CN9") + cContra + DEF_SVIGE))
			cRevisa := CN9->CN9_REVISA
			oModelCND:LoadValue("CND_REVISA",cRevisa)
			Cn121Carga(cContra,cRevisa)
		Else
			lRet := .F.
		Endif

		If lRet
			cCompet := A260GComp()
			aAdd(aCompets,cCompet)
			aCompSemN := aClone(aCompets)
			nX := 1
			aCompets[nX] := CVALTOCHAR(nX)+'='+aCompets[nX]
			aCompSemN[nX] := CVALTOCHAR(nX)
			CN121Cbox(aCompets,aCompSemN,cFilCTR)
		Endif
	EndIf

Else
	lRet := .T.
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Executa ponto de entrada após validação  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If ExistBlock("CN120DTCON")
	lCN120DTCON:= ExecBlock("CN120DTCON",.F.,.F.,{lRet})
	If ValType(lCN120DTCON) == "L"
	   lRet := lCN120DTCON
	EndIf
EndIf

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN120Compet³ Autor ³ Marcelo Custodio      ³ Data ³09.02.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Valida Competencia e carrega planilhas de acordo com a      ³±±
±±³          ³ competencia selecionada                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN120Compet()                                               ³±±
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
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function CN120Compet(lExcede,cFilCTR)
Local oModel		:= FWModelActive()
Local lMVC			:= ValType(oModel) <> "U" .And. oModel:GetId()=='CNTA121'
Local oModelCXN		:= NIL
Local oStruCXN		:= NIL
Local aCn120Cpo  	:= {}
Local dData			:= dDatabase
Local cQuery     	:= ""
Local cParcela		:= ""
Local nCpo		   	:= 0
Local cFilCNL		:= xFilial('CNL')
Local lCN120GTR  	:= ExistBlock("CN120GTR")
Local lCN120QRY  	:= ExistBlock("CN120QRY")
Local lCn120ctaut	:= ExistBlock("CN120CTAUT")
Local lCN120SeMed	:= ExistBlock("CN120SEMED")
Local lCn120Cpo  	:= Iif(ExistBlock("CN120CPO"),.T.,.F.)
Local lCompetenci	:= SuperGetMv("MV_CNFCOMP",.F.,.F.) // Filtra cronograma
Local lRet       	:= .T.
Local lCont			:= .F.
Local lSemMed		:= .F.
Local lFisico		:= .F.
Local lEventual 	:= .F.
Local lRecorre  	:= .F.
Local lSemifixo		:= .F.
Local lServico		:= .F.
Local lNewPlan		:= .F.
Local lMedHe930		:= IsInCallStack("At930Grv") .and. lMedHE

DEFAULT lExcede	:= IsInCallStack("CN121ExceC")
DEFAULT cFilCTR	:= Iif(!Empty(CN9->CN9_FILCTR),CN9->CN9_FILCTR,cFilAnt)

cPlan := ""
If lMVC
	oModel 		:= FWModelActive()
	oModelCXN 	:= oModel:GetModel("CXNDETAIL")
	oStruCXN	:= oModelCXN:GetStruct()
	cContra		:= oModel:GetValue("CNDMASTER","CND_CONTRA")
	cRevisa 	:= oModel:GetValue("CNDMASTER","CND_REVISA")
	cCompet 	:= oModel:GetValue("CNDMASTER","CND_COMPET")

	oModel:GetModel('CXNDETAIL'):SetNoInsertLine(.F.)
	oModel:GetModel('CXNDETAIL'):SetNoDeleteLine(.F.)
	oStruCXN:SetProperty('*',MODEL_FIELD_WHEN,{|| .T. })
Endif

CursorWait()

If lCn120Cpo
	aCn120Cpo := ExecBlock("CN120CPO",.F.,.F.)
	If ValType(aCn120cpo) <> "A"
		aCn120Cpo := {}
	EndIf
EndIf

//-- Verifica se há planilha para o contrato
lCont:= VerPlan(xFilial("CN9",cFilCTR),cContra,cRevisa)
If !lCont
	Return .F.
Endif

//-- Filtra contrato
dbSelectArea("CN9")
CN9->(dbSetOrder(1))
CN9->(dbSeek(xFilial("CN9",cFilCTR)+cContra+cRevisa))

dbSelectArea("CNF")
CNF->(dbSetOrder(2))
CNF->(dbSeek(xFilial("CNF",cFilCTR)+cContra+cRevisa))

lFixo 		:= CN300RetSt("FIXO"      ,2,,cContra,cFilCTR,.F.)
lEventual 	:= CN300RetSt("MEDEVE"    ,2,,cContra,cFilCTR,.F.)
lRecorre  	:= CN300RetSt("RECORRENTE",2,,cContra,cFilCTR,.F.)
lServico	:= CN300RetSt("SERVIÇO"	  ,2,,cContra,cFilCTR,.F.)

//Ponto de entrada para ignorar as medições em aberto, deve ser utilizado junto com o CN120VENC para validar o saldo
If lCN120SeMed //implementado para contrato flexivel
	lSemMed := ExecBlock("CN120SEMED",.F.,.F.,{cContra,cRevisa})
	If ValType(lSemMed) <> "L"
		lSemMed := .F.
	EndIf
EndIf

If lFixo
	If lExcede
		cQuery := " SELECT "
		cQuery += " CNA.R_E_C_N_O_ AS PLANREC, "
		cQuery += " CNA.CNA_CONTRA, "
		cQuery += " CNA.CNA_REVISA, "
		cQuery += " CNA.CNA_NUMERO, "
		cQuery += " CNA.CNA_DTINI, 	"
		cQuery += " CNA.CNA_VLTOT, 	"
		cQuery += " CNA.CNA_DTFIM, 	"
		cQuery += " CNA.CNA_FORNEC, "
		cQuery += " CNA.CNA_LJFORN, "
		cQuery += " CNA.CNA_CLIENT, "
		cQuery += " CNA.CNA_LOJACL, "
		cQuery += " CNA.CNA_CRONOG, "
		cQuery += " 0 AS CNF_VLPREV,"
		cQuery += " '' AS CNF_PARCEL, "
		cQuery += " CNA.CNA_TIPPLA, "
		cQuery += " CNA_SALDO "

		If Len(aCn120Cpo) > 0 .And. lCn120Cpo
			For nCpo:=1 To Len(aCn120Cpo)
				cQuery += ","+aCn120Cpo[nCpo]
			Next nCpo
		EndIf

		cQuery += " FROM "
		cQuery += RetSQLName("CNA") +" CNA, "
		cQuery += RetSQLName("CN9") +" CN9, "
		cQuery += RetSQLName("CPD") +" CPD  "
		cQuery += " WHERE "
		cQuery += " CNA.CNA_FILIAL = '" +xFilial("CNA",cFilCTR) +"'"
		cQuery += " AND CN9.CN9_FILIAL = '" +xFilial("CN9",cFilCTR) +"'"
		cQuery += " AND CNA.CNA_CONTRA = CN9.CN9_NUMERO  "
		cQuery += " AND CNA.CNA_REVISA = CN9.CN9_REVISA "
		cQuery += " AND CPD.CPD_FILIAL = '"+xFilial("CN9",cFilCTR) +"'"
		cQuery += " AND CPD.CPD_CONTRA = CN9.CN9_NUMERO "
		cQuery += " AND CPD.CPD_NUMPLA = CNA.CNA_NUMERO "
		cQuery += " AND CPD.CPD_FILAUT = '" + cFilAnt +"'"
		cQuery += " AND CNA.CNA_CONTRA = '" +cContra +"'"
		cQuery += " AND CNA.CNA_REVISA = '" +cRevisa +"'"
		cQuery += " AND SUBSTRING(CNA.CNA_DTFIM,1,6) >= '" +Substr(cCompet,4,4) +Substr(cCompet,1,2) +"'"
		cQuery += " AND CPD.D_E_L_E_T_ = '' "
		cQuery += " AND CNA.D_E_L_E_T_ <> '*' AND CN9.D_E_L_E_T_ <> '*'"
	Else
		//-- Filtra planilhas de acordo com os cronogramas
		cQuery := " SELECT DISTINCT "
		cQuery += " CNA.R_E_C_N_O_ as PLANREC, "
		cQuery += " CNA.CNA_CONTRA, "
		cQuery += " CNA.CNA_REVISA, "
		cQuery += " CNA.CNA_NUMERO, "
		cQuery += " CNA.CNA_DTINI,  "
		cQuery += " CNA.CNA_VLTOT, 	"
		cQuery += " CNA.CNA_DTFIM, 	"
		cQuery += " CNA.CNA_FORNEC, "
		cQuery += " CNA.CNA_LJFORN, "
		cQuery += " CNA.CNA_CLIENT, "
		cQuery += " CNA.CNA_LOJACL, "
		cQuery += " CNA.CNA_CRONOG, "
		cQuery += " CASE WHEN CNA.CNA_CRONOG = '"+Space(TamSX3("CNA_CRONOG")[1])+"'  THEN 0  ELSE CNF.CNF_SALDO  END AS CNF_VLPREV, "
		cQuery += " CASE WHEN CNA.CNA_CRONOG <> '"+Space(TamSX3("CNA_CRONOG")[1])+"'  THEN CNF.CNF_PARCEL ELSE CNA.CNA_PROPAR END AS CNF_PARCEL, "
		cQuery += " CNA.CNA_TIPPLA, "
		cQuery += " CNA_SALDO "

		If Len(aCn120Cpo) > 0 .And. lCn120Cpo
			For nCpo:=1 To Len(aCn120Cpo)
				cQuery += ","+aCn120Cpo[nCpo]
			Next nCpo
		EndIf

		cQuery += " FROM "

		cQuery += RetSQLName("CNA") + " CNA "
		If lEventual
			cQuery += " LEFT "
		EndIf
		cQuery += " JOIN " + RetSQLName("CNF") + " CNF ON "
		cQuery += "		CNA.CNA_FILIAL = CNF.CNF_FILIAL	"
		cQuery += "	AND CNA.CNA_CONTRA = CNF.CNF_CONTRA	"
		cQuery += "	AND CNA.CNA_REVISA = CNF.CNF_REVISA	"
		cQuery += "	AND CNA.CNA_CRONOG = CNF.CNF_NUMERO	"

		If lCompetenci .And. CNF->CNF_PERIOD <> "1" .And. Substr(DToS(dDataBase),1,6) <= Substr(cCompet,4,4)+Substr(cCompet,1,2)
			cQuery += " AND CNF.CNF_PRUMED <= '"+Dtos(dDataBase)+"'"
		EndIf

		cQuery += " AND CNF.CNF_COMPET = '"+cCompet+"'"

		If !lMedHe930
			cQuery += " AND CNF.CNF_SALDO > 0 "
		Endif

		cQuery += "	AND CNF.D_E_L_E_T_ = ' ', "

		cQuery += RetSQLName("CN9") + " CN9, "
		cQuery += RetSQLName("CPD") + " CPD  "
		cQuery += " WHERE "
		cQuery += " CNA.CNA_FILIAL = '"+xFilial("CNA",cFilCTR)+"' "
		cQuery += " AND CN9.CN9_FILIAL = '"+ xFilial("CN9",cFilCTR) +"'"
		cQuery += " AND CPD.CPD_FILIAL = '"+xFilial("CN9",cFilCTR) +"'"
		cQuery += " AND CPD.CPD_CONTRA = CN9.CN9_NUMERO "
		cQuery += " AND CPD.CPD_NUMPLA = CNA.CNA_NUMERO "
		cQuery += " AND CPD.CPD_FILAUT = '" + cFilAnt + "'"
		cQuery += " AND CNA.CNA_CONTRA = CN9.CN9_NUMERO "
		cQuery += " AND CNA.CNA_REVISA = CN9.CN9_REVISA "
		cQuery += " AND CNA.CNA_CONTRA = '" +cContra+ "'"
		cQuery += " AND CNA.CNA_REVISA = '" +cRevisa+ "'"

		If lEventual
			cQuery += " AND ((CNA.CNA_SALDO > 0 AND CNF.CNF_SALDO > 0 AND CNF.CNF_COMPET = '"+cCompet+"')"
			cQuery += " OR (CNA.CNA_CRONOG = '"+Space(TamSX3("CNA_CRONOG")[1])+"' AND CNA.CNA_VLTOT = 0 AND CNA.CNA_SALDO = 0)"
			cQuery += " OR (CNA.CNA_CRONOG = '"+Space(TamSX3("CNA_CRONOG")[1])+"' AND CNA.CNA_VLTOT > 0 AND CNA.CNA_SALDO > 0))"
		Else
			cQuery += " AND CNA.CNA_SALDO > 0"
		EndIf

		cQuery += " AND"

		If !lSemMed

			cQuery += " (SELECT COUNT(*) "
			cQuery += " FROM "+ RetSQLName("CND") + " CND WHERE "
			cQuery += " CND.CND_FILCTR = '"+ cFilCTR +"' AND "
			cQuery += " CND.CND_CONTRA =  '"+ cContra +"' AND "
			cQuery += " CND.CND_REVISA   = '"+ cRevisa +"' AND "
			cQuery += " CND.CND_NUMERO   = CNA.CNA_NUMERO AND "
			If lMVC
				cQuery += "	CND.CND_COMPET = '"+cCompet+"'	AND "
			EndIf
			cQuery += " (
			cQuery += " (CND.CND_AUTFRN='1' AND CND.CND_DTFIM  = '') OR "
			cQuery += " (CND.CND_AUTFRN='2' AND CND.CND_PEDIDO = '"+Space(TamSX3("CND_PEDIDO")[1])+"') "
			cQuery += " OR  (CND.CND_SITUAC='A') OR (CND.CND_SITUAC='FA')) AND "
			cQuery += " CND.D_E_L_E_T_ = ''
			cQuery += " ) = 0  AND "
			
			//Verifico se já consta medição em aberto inclusa pela rotina CNTA121
			cQuery += " (
			cQuery += " SELECT COUNT(*) "
			cQuery += " FROM "
			cQuery += RetSQLName("CND") + " CND "
			cQuery += ", "+ RetSQLName("CXN") + " CXN  "
			cQuery += " WHERE "
			cQuery += " CND.D_E_L_E_T_ = '' AND "
			cQuery += " CND.CND_FILCTR = '"+ cFilCTR +"' AND "
			cQuery += " CND.CND_CONTRA = '"+ cContra +"' AND "
			cQuery += " CND.CND_REVISA = '"+ cRevisa +"' AND "
			cQuery += " CXN.D_E_L_E_T_ = '' AND "
			cQuery += " CXN.CXN_FILIAL = CND.CND_FILCTR  AND "
			cQuery += " CXN.CXN_CONTRA = CND.CND_CONTRA  AND "
			cQuery += " CXN.CXN_REVISA = CND.CND_REVISA  AND "
			cQuery += " CXN.CXN_NUMMED = CND.CND_NUMMED  AND "
			cQuery += " CXN.CXN_CHECK  = 'T'  AND "
			cQuery += " ( CND.CND_NUMERO = CNA.CNA_NUMERO
			cQuery += " OR CXN.CXN_NUMPLA = CNA.CNA_NUMERO ) AND "
			cQuery += " (
			cQuery += " (CND.CND_AUTFRN='1' AND CND.CND_DTFIM  = '') OR "
			cQuery += " (CND.CND_AUTFRN='2' AND CND.CND_PEDIDO = '"+Space(TamSX3("CND_PEDIDO")[1])+"' AND (SELECT COUNT(*) FROM "+RetSQLName("CXN")+"WHERE CXN_NUMMED = CND_NUMMED AND CXN_CHECK = 'T') = 0) "
			cQuery += " OR  (CND.CND_SITUAC='A') OR (CND.CND_SITUAC='FA') "
			cQuery += " ) "
			cQuery += " ) = 0  AND "

		EndIf

		cQuery += " CPD.D_E_L_E_T_ = '' AND "
		cQuery += " CNA.D_E_L_E_T_ = '' AND "
		cQuery += " CN9.D_E_L_E_T_ = ''"

	EndIf

	If lCN120QRY
		cCN120QRY := ExecBlock("CN120QRY",.F.,.F.,{cQuery})
		If ValType(cCN120QRY) == "C"
			cQuery := cCN120QRY
		EndIf
	EndIf
EndIf

If lRecorre .Or. ( !lFixo .And. lEventual .And. !IsInCallStack('CN260EXC') )
	If !Empty(cQuery)
		cQuery += " UNION "
	EndIf

	cQuery += " SELECT CNA.R_E_C_N_O_ AS PLANREC, "
	cQuery += " CNA.CNA_CONTRA, "
	cQuery += " CNA.CNA_REVISA, "
	cQuery += " CNA.CNA_NUMERO, "
	cQuery += " CNA.CNA_DTINI, "
	cQuery += " CNA.CNA_VLTOT, "
	cQuery += " CNA.CNA_DTFIM, "
	cQuery += " CNA.CNA_FORNEC, "
	cQuery += " CNA.CNA_LJFORN, "
	cQuery += " CNA.CNA_CLIENT, "
	cQuery += " CNA.CNA_LOJACL, "
	cQuery += " CNA.CNA_CRONOG, "
	cQuery += " 0 as CNF_VLPREV, "

	If lRecorre
		cQuery += " CNA_PROPAR AS CNF_PARCEL, "
	Else
		cQuery += " '' AS CNF_PARCEL, "
	EndIf

	cQuery += " CNA.CNA_TIPPLA, "
	cQuery += " CNA.CNA_SALDO "
	cQuery += " FROM "
	cQuery += RetSQLName("CNA") + " CNA, "
	cQuery += RetSQLName("CPD") + " CPD  "
	cQuery += " WHERE "
	cQuery += " CNA.CNA_FILIAL = '"+ xFilial("CNA",cFilCTR) +"' AND "
	cQuery += " CNA.CNA_CONTRA = '"+ cContra +"' AND "
	cQuery += " CNA.CNA_REVISA = '"+ cRevisa +"' AND "
	cQuery += " CPD.CPD_FILIAL = '"+xFilial("CN9",cFilCTR) +"' AND"
	cQuery += " CPD.CPD_CONTRA = '"+ cContra +"' AND "
	cQuery += " CPD.CPD_NUMPLA = CNA.CNA_NUMERO  AND "
	cQuery += " CPD.CPD_FILAUT = '"+cFilAnt+"'	 AND "

	If lRecorre
		cQuery += " CNA.CNA_PERIOD <> '' AND "
	Else
		cQuery += " CNA.CNA_PERIOD = '' AND "
	EndIf

	cQuery += " CNA.CNA_CRONOG = '"+Space(TamSX3("CNA_CRONOG")[1])+"' AND "

	If !lSemMed

		cQuery += " (SELECT COUNT(*) "
		cQuery += " FROM "+ RetSQLName("CND") + " CND WHERE "
		cQuery += " CND.CND_FILCTR = '"+ xFilial("CND",cFilCTR) +"' AND "
		cQuery += " CND.CND_CONTRA =  '"+ cContra +"' AND "
		cQuery += " CND.CND_REVISA   = '"+ cRevisa +"' AND "
		cQuery += " CND.CND_NUMERO   = CNA.CNA_NUMERO AND "
		If lMVC
			cQuery += "	CND.CND_COMPET = '"+cCompet+"'	AND "
		EndIf
		cQuery += " (
		cQuery += " (CND.CND_AUTFRN='1' AND CND.CND_DTFIM  = '') OR "
		cQuery += " (CND.CND_AUTFRN='2' AND CND.CND_PEDIDO = '"+Space(TamSX3("CND_PEDIDO")[1])+"') "
		cQuery += " OR  (CND.CND_SITUAC='A') OR (CND.CND_SITUAC='FA')) AND "
		cQuery += " CND.D_E_L_E_T_ = ''
		cQuery += " ) = 0  AND "

		If lMVC
			cQuery += " (
			cQuery += " SELECT COUNT(*) "
			cQuery += " FROM "
			cQuery += RetSQLName("CND") + " CND "
			cQuery += ", "+ RetSQLName("CXN") + " CXN  "
			cQuery += " WHERE "
			cQuery += " CND.D_E_L_E_T_ = '' AND "
			cQuery += " CND.CND_FILCTR = '"+ cFilCTR +"' AND "
			cQuery += " CND.CND_CONTRA = '"+ cContra +"' AND "
			cQuery += " CND.CND_REVISA = '"+ cRevisa +"' AND "
			//cQuery += "	CND.CND_COMPET = '"+cCompet+"'	AND "
			cQuery += " CXN.D_E_L_E_T_ = '' AND "
			cQuery += " CXN.CXN_FILIAL = CND.CND_FILCTR  AND "
			cQuery += " CXN.CXN_CONTRA = CND.CND_CONTRA  AND "
			cQuery += " CXN.CXN_REVISA = CND.CND_REVISA  AND "
			cQuery += " CXN.CXN_NUMMED = CND.CND_NUMMED  AND "
			cQuery += " CXN.CXN_CHECK  = 'T'  AND "
			cQuery += " ( CND.CND_NUMERO = CNA.CNA_NUMERO
			cQuery += " OR CXN.CXN_NUMPLA = CNA.CNA_NUMERO ) AND "
			cQuery += " (
			cQuery += " (CND.CND_AUTFRN='1' AND CND.CND_DTFIM  = '') OR "
			cQuery += " (CND.CND_AUTFRN='2' AND CND.CND_PEDIDO = '"+Space(TamSX3("CND_PEDIDO")[1])+"' AND (SELECT COUNT(*) FROM "+RetSQLName("CXN")+"WHERE CXN_NUMMED = CND_NUMMED AND CXN_CHECK = 'T') = 0) "
			cQuery += " OR  (CND.CND_SITUAC='A') OR (CND.CND_SITUAC='FA') "
			cQuery += " ) "
			cQuery += " ) = 0  AND "
		EndIf
	EndIf

	cQuery += " CPD.D_E_L_E_T_ = '' AND "
	cQuery += " CNA.D_E_L_E_T_ = '' "
EndIf
cQuery += " ORDER BY CNA_NUMERO, CNF_PARCEL ASC"

If ! Empty(cQuery)
	cQuery := ChangeQuery(cQuery)
	dbUseArea( .T., "TOPCONN", TcGenQry( ,, cQuery ), "TRB", .F., .T. )

    //-- Configura estrutura
	TCSetField("TRB","CNA_DTINI","D")
	TCSetField("TRB","CNA_DTFIM","D")
	TCSetField("TRB","CNA_VLTOT","N",TamSX3("CNA_VLTOT")[1],TamSX3("CNA_VLTOT")[2])
	TCSetField("TRB","CNF_VLPREV","N",TamSX3("CNF_VLPREV")[1],TamSX3("CNF_VLPREV")[2])

    //-- Limpa arquivo temporario
    If !lMVC
    	dbSelectArea("TRBCNA")
    	If RecCount() > 0
    		Zap
    	Endif
    Else
	    CNTA300DlMd(oModelCXN,"CXN_NUMPLA",.F.)
    Endif

    If lFixo .And. TRB->(Eof()) .And. !lCn120ctaut .and. !lMedHe930

    	Aviso("CNTA120",OemToAnsi(STR0034),{STR0155})//"Não existe planilha disponível no contrato e competência selecionados. Verifique o saldo e a existência de medições em aberto para o contrato"
    EndIf
    
    If lMVC
    	oModel:LoadValue( "CNDMASTER", "CND_FILCTR", CN9->CN9_FILCTR )
    EndIf
    
    //-- Copia planilhas filtradas para arquivo temporario
	While TRB->(!Eof())
	    If !lMVC
			lRecorre	:= Cn300RetSt( "RECORRENTE"	,0	,TRB->CNA_NUMERO	,cContra	,cFilCtr	,.F. )
		  	lSemifixo	:= Cn300RetSt( "SEMIFIXO"	,0	,TRB->CNA_NUMERO	,cContra	,cFilCtr	,.F. )
		  	lServico	:= Cn300RetSt( "SERVIÇO"	,0	,TRB->CNA_NUMERO	,cContra	,cFilCtr	,.F. )

		   	If !lRecorre .And. !lSemifixo .And. !lServico
			  	RecLock("TRBCNA",.T.)
				TRBCNA->CNA_NUMERO := TRB->CNA_NUMERO
				TRBCNA->CNA_DTINI  := TRB->CNA_DTINI
				TRBCNA->CNA_VLTOT  := TRB->CNA_VLTOT
				TRBCNA->CNA_DTFIM  := TRB->CNA_DTFIM
				TRBCNA->CNA_FORNEC := TRB->CNA_FORNEC
				TRBCNA->CNA_LJFORN := TRB->CNA_LJFORN
			   	TRBCNA->CNA_CLIENT := TRB->CNA_CLIENT
			   	TRBCNA->CNA_LOJACL := TRB->CNA_LOJACL
				TRBCNA->CNA_CRONOG := TRB->CNA_CRONOG

			    If !lEventual
			    	TRBCNA->CNF_VLPREV := TRB->CNF_VLPREV
			    Else
			    	TRBCNA->CNF_VLPREV := 0
			    EndIf

				TRBCNA->CNF_PARCEL := TRB->CNF_PARCEL

				If Len(aCn120Cpo) > 0 .And. lCn120Cpo
					For nCpo:=1 To Len(aCn120Cpo)
						TRBCNA->&(aCn120Cpo[nCpo]) := TRB->&(aCn120Cpo[nCpo])
					Next nCpo
				EndIf

				If lCN120GTR
					ExecBlock("CN120GTR",.F.,.F.,{lFixo,TRB->PLANREC})
				EndIf

				TRBCNA->(MsUnlock())
			ElseIf !lNewPlan
				lNewPlan := .T.
			EndIf

	    Else
	    	lEventual := Cn300RetSt("MEDEVE",0,TRB->CNA_NUMERO)
		    lFisico := Cn300RetSt("FISICO",0, TRB->CNA_NUMERO)
		    lRecorre := Cn300RetSt("RECORRENTE",0,TRB->CNA_NUMERO)
		    lSemifixo := Cn300RetSt("SEMIFIXO",0,TRB->CNA_NUMERO)
			
		    IF !oModelCXN:SeekLine( {{ 'CXN_NUMPLA' , TRB->CNA_NUMERO }} ) //-Permite apenas uma parcela por planilha na medição.
		    	oModelCXN:SetNoInsertLine(.F.)
	
			    If !Empty(oModelCXN:GetValue("CXN_NUMPLA"))
				    oModelCXN:AddLine()
			    EndIf
	
				oModelCXN:LoadValue("CXN_CONTRA", TRB->CNA_CONTRA )
			    oModelCXN:LoadValue("CXN_NUMPLA", TRB->CNA_NUMERO )
			    oModelCXN:LoadValue("CXN_DTINI ", TRB->CNA_DTINI  )
			    oModelCXN:LoadValue("CXN_VLTOT ", 0)
			    oModelCXN:LoadValue("CXN_DTFIM ", TRB->CNA_DTFIM  )
			    oModelCXN:LoadValue("CXN_CRONOG", TRB->CNA_CRONOG )
			    oModelCXN:LoadValue("CXN_TIPPLA", TRB->CNA_TIPPLA )
			    oModelCXN:LoadValue("CXN_DESCRI", Posicione( "CNL" , 1 , cFilCNL + TRB->CNA_TIPPLA , "CNL_DESCRI" ) )
			    
			    If CXN->( Columnpos('CXN_ZERO') ) > 0	//- Proteção para medição zerada.
			    	oModelCXN:LoadValue("CXN_ZERO"	, "0")
			    EndIf
	
			    If !lExcede
				    If lSemifixo
				    	oModelCXN:LoadValue("CXN_VLSALD", TRB->CNA_SALDO - CN121VLDSF(TRB->CNA_CONTRA,TRB->CNA_REVISA,TRB->CNA_NUMERO))
				    Else
				    	oModelCXN:LoadValue("CXN_VLSALD", TRB->CNA_SALDO )
				    EndIf
			    EndIf
	
		        If Empty(TRB->CNA_CLIENT)
				    oModelCXN:LoadValue("CXN_FORCLI", TRB->CNA_FORNEC )
				    oModelCXN:LoadValue("CXN_LOJA", TRB->CNA_LJFORN )
			    Else
				    oModelCXN:LoadValue("CXN_FORCLI", TRB->CNA_CLIENT )
				    oModelCXN:LoadValue("CXN_LOJA", TRB->CNA_LOJACL )
			    EndIf
	
			    If !lEventual .And. !lRecorre
				    oModelCXN:LoadValue("CXN_VLPREV", TRB->CNF_VLPREV )
			    ElseIf lRecorre
				    oModelCXN:LoadValue("CXN_VLPREV", TRB->CNA_VLTOT )
			    Else
				    oModelCXN:LoadValue("CXN_VLPREV", 0/*TRB->CNA_SALDO*/ )
			    EndIf
	
			    If !lEventual .And. !lRecorre
				    CNF->(dbSetOrder(2)) //-- CNF_FILIAL+CNF_CONTRA+CNF_REVISA+CNF_NUMERO+CNF_COMPET
				    CNF->(MsSeek(xFilial("CNF",cFilCtr)+cContra+cRevisa+oModelCXN:GetValue("CXN_CRONOG")+cCompet))
				    oModelCXN:LoadValue("CXN_DTVENC", CNF->CNF_DTVENC)
			    Else
				    CN9->(dbSetOrder(1))
				    If CN9->(MsSeek(xFilial("CN9",cFilCtr)+cContra+cRevisa))
					    aCond := Condicao(0,CN9->CN9_CONDPG,,dDataBase)
					    If Len(aCond) > 0
						    oModelCXN:LoadValue("CXN_DTVENC", aCond[1][1] )
					    Else
						    oModelCXN:LoadValue("CXN_DTVENC", dDataBase )
					    EndIf
				    Else
					    oModelCXN:LoadValue("CXN_DTVENC", dDataBase )
				    EndIf
			    EndIf
	
			    //-- Atualiza Parcela do cronograma
			    If !lEventual .And. !lRecorre .And. Empty(TRB->CNF_PARCEL)
				    oModelCXN:LoadValue("CXN_PARCEL",CNF->CNF_PARCEL)
				    oModelCXN:LoadValue("CXN_VLPREV",CNF->CNF_VLPREV)
			    Else
				    oModelCXN:LoadValue("CXN_PARCEL",Left(TRB->CNF_PARCEL,TamSX3("CXN_PARCEL")[1]))
			    EndIf
			EndIf
	    EndIf
		TRB->(dbSkip())
	EndDo
	TRB->(dbCloseArea())
EndIf

CursorArrow()

If !lMVC
	If	TRBCNA->(EOF()) .And. lNewPlan
		Aviso("CNTA120",STR0153,{STR0155})
		lRet := .F.
	Else
		TRBCNA->(dbGoTop())
		oBrowse:Refresh()
	EndIf
Else
	oModel:GetModel('CXNDETAIL'):SetNoInsertLine(.T.)
	oModel:GetModel('CXNDETAIL'):SetNoDeleteLine(.T.)
	oStruCXN:SetProperty('*',MODEL_FIELD_WHEN,{|| .F. })
	oStruCXN:SetProperty('CXN_CHECK',	MODEL_FIELD_WHEN,{|| .T. })
	oStruCXN:SetProperty('CXN_DTVENC',	MODEL_FIELD_WHEN,{|| .T. })
	oStruCXN:SetProperty('CXN_FORCLI',	MODEL_FIELD_WHEN,{|| .T. })
	oStruCXN:SetProperty('CXN_LOJA',	MODEL_FIELD_WHEN,{|| .T. })
	oStruCXN:SetProperty('CXN_PARCEL',	MODEL_FIELD_WHEN,{|| .T. })
	
	If CXN->( Columnpos('CXN_ZERO') ) > 0	//- Proteção para medição zerada.
		oStruCXN:SetProperty('CXN_ZERO'		,MODEL_FIELD_WHEN,{|| CxnZeroWhe() })
	EndIf

	oModelCXN:GoLine(1)

EndIf

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN120VldCpt ³ Autor ³ Marcelo Custodio      ³ Data ³09.02.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Valida competencia durante a execucao da rotina automatica   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN120VldCpt(cExp01,cExp02)                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                              ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function CN120VldCpt(lExcede)

Local cQuery    := ""
Local lRet      := .T.
Local lCN120CPT := .T.

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Filtra contrato                                    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lExcede
	//-- Verifica se formato da competencia e valido
	lRet := Val(Substr(cCompet,1,2)) > 0 .And. Val(Substr(cCompet,1,2)) <= 12 .And. Substr(cCompet,3,1) == "/"

	//-- Valida competencia com data de inicio e fim da planilha
	If lRet
		CNA->(dbSetOrder(1))
		CNA->(dbSeek(xFilial("CNA",cFilCTR)+cContra+cRevisa+cPlan))

		lRet := Substr(cCompet,4,4)+Substr(cCompet,1,2) >= Substr(DToS(CNA->CNA_DTINI),1,6) .And.;
				Substr(cCompet,4,4)+Substr(cCompet,1,2) <= Substr(DToS(CNA->CNA_DTFIM),1,6)
	EndIf

	//-- Verifica se competencia e prevista
	If lRet
		cQuery := "SELECT DISTINCT(CNF.CNF_COMPET) AS CNF_COMPET FROM " +RetSQLName("CNF") +" CNF WHERE "
		cQuery += "CNF.D_E_L_E_T_ <> '*' AND CNF.CNF_FILIAL = '" +xFilial("CNF",cFilCTR) +"' AND "
		cQuery += "CNF.CNF_CONTRA = '" +cContra +"' AND CNF.CNF_REVISA = '" +cRevisa +"' AND "
		cQuery += "CNF.CNF_COMPET = '" +cCompet +"' "

		cQuery += "UNION "

		//-- Verifica se ja foi gerada medicao
		cQuery += "SELECT DISTINCT(CND.CND_COMPET) FROM " +RetSQLName("CND") +" CND WHERE CND.D_E_L_E_T_ <> '*' AND "
		cQuery += "CND.CND_FILCTR = '" +cFilCTR +"' AND "
		cQuery += "CND.CND_CONTRA = '" +cContra +"' AND "
		cQuery += "CND.CND_REVISA = '" +cRevisa +"' AND CND.CND_COMPET = '" +cCompet +"'"

		cQuery := ChangeQuery(cQuery)
		dbUseArea(.T.,"TOPCONN",TcGenQry( ,, cQuery ),"TRB",.F.,.T.)

		//-- So valida se nao existir nenhum dos dois casos
		lRet := Empty(TRB->CNF_COMPET)

		TRB->(dbCloseArea())
	EndIf
ElseIf !lFixo
	dbSelectArea("CN9")
	dbSetOrder(1)
	dbSeek(xFilial("CN9",cFilCTR)+cContra+cRevisa)

	lMedEve := (Posicione("CN1",1,xFilial("CN1",cFilCTR)+CN9->CN9_TPCTO,"CN1_MEDEVE") == "1")

	If !lMedEve
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Filtra planilhas de acordo com os cronogramas      ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cQuery := "SELECT COUNT(*) QTD "
		cQuery += "  FROM "+RetSQLName("CNA") + " CNA ," + RetSQLName("CNF") + " CNF "
		cQuery += " WHERE CNA.CNA_FILIAL = '"+ xFilial("CNA",cFilCTR) +"' AND CNF.CNF_FILIAL = '"+ xFilial("CNF",cFilCTR) +"'"
		cQuery += "   AND CNA.CNA_CONTRA = CNF.CNF_CONTRA "
		cQuery += "   AND CNA.CNA_REVISA = CNF.CNF_REVISA "
		cQuery += "   AND CNF.CNF_NUMERO = CNA.CNA_CRONOG "
		cQuery += "   AND CNF.CNF_COMPET = '"+ cCompet +"'"
		cQuery += "   AND CNA.CNA_CONTRA = '" + cContra + "'"
		cQuery += "   AND CNA.CNA_REVISA = '" + cRevisa + "'"
		cQuery += "   AND CNA.CNA_NUMERO = '" + cPlan   + "'"
		cQuery += "	AND CNA.CNA_SALDO > 0 " //Filtra planilhas com saldo
		cQuery += "   AND CNF.CNF_SALDO  > 0  " //Filtra parcelas nao medidas
		cQuery += "   AND (SELECT COUNT(*) FROM " + RetSQLName("CND")+" CND WHERE "
		cQuery += "         CND.CND_FILCTR = '"+ cFilCTR +"'"
		cQuery += "           AND CND.CND_CONTRA = '"+ cContra +"'"
		cQuery += "           AND CND.CND_REVISA = '"+ cRevisa +"'"
		cQuery += "           AND CND.CND_NUMERO = CNA.CNA_NUMERO "
		cQuery += "           AND CND.CND_DTFIM  = '' "
		cQuery += "           AND CND.D_E_L_E_T_ = '') = 0 "//Filtra planilhas sem medicoes em aberto
		cQuery += "   AND CNA.D_E_L_E_T_ = '' "
		cQuery += "   AND CNF.D_E_L_E_T_ = '' "
	Else
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Filtra planilhas                   ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cQuery := "SELECT COUNT(*) QTD "
		cQuery += "  FROM " + RetSQLName("CNA") + " CNA "
		cQuery += " WHERE CNA.CNA_FILIAL = '"+ xFilial("CNA",cFilCTR) +"'"
		cQuery += "   AND CNA.CNA_CONTRA = '" + cContra + "'"
		cQuery += "   AND CNA.CNA_REVISA = '" + cRevisa + "'"
		cQuery += "   AND CNA.CNA_NUMERO = '" + cPlan   + "'"
		cQuery += "   AND CNA.D_E_L_E_T_ = ''"
	EndIf

	cQuery := ChangeQuery(cQuery)
	dbUseArea( .T., "TOPCONN", TcGenQry( ,, cQuery ), "TRB", .F., .T. )

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Verifica o acesso do usuario                       ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	lRet := (TRB->QTD > 0)

	TRB->(dbCloseArea())
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Executa ponto de entrada após validação da competência  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If ExistBlock("CN120CPT")
	lCN120CPT := ExecBlock("CN120CPT",.F.,.F.,{lRet})
  	If ValType(lCN120CPT) == "L"
		lRet := lCN120CPT
	EndIf
EndIf

Return lRet


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN120RetTip³ Autor ³ Marcelo Custodio      ³ Data ³09.02.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Retorna descricao do tipo de planilha                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN120RetTip()                                               ³±±
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
Function CN120RetTip()
Local cTipPlan
Local cRet := ""

If Type("cFilCTR") == "U"
	cFilCTR = cFilAnt
Endif

If !INCLUI
	cTipPlan := Posicione( "CNA", 1, xFilial("CNA",cFilCTR) + CND->CND_CONTRA + CND->CND_REVISA + CND->CND_NUMERO,"CNA_TIPPLA")
	cRet     := Posicione( "CNL", 1, xFilial("CNL",cFilCTR) + cTipPlan, "CNL_DESCRI" )
EndIf

Return cRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN120MedEnc³ Autor ³ Marcelo Custodio      ³ Data ³09.02.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Encerra medicao, valida cronograma, medicoes zeradas        ³±±
±±³          ³ e saldo do contrato e planilhas                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³  CN120MedEnc(nExp01)                                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³  nExp01 - Registro atual                                    ³±±
±±³          ³  lExp01 - Aviso de confirmacao de encerramento              ³±±
±±³          ³  lExp02 - Autorizacao de Fornecimento                       ³±±
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
Function CN120MedEnc(nReg,lAviso,lAutoFor,lMedServ,lAprRev)

Local aAreaSX3    := ""

Local lRet	   := .T.
Local lMedEve  := .F.
Local lFscLmt  := .F.
Local lContab  := .F.
Local lFixo    := .T.
Local lValor   := .T.
Local lPeSld   := ExistBlock("CN120ENSLD")
Local lPeGrP   := ExistBlock("CN120GRPED")
Local lGrped   := .T.
Local lPeVlPar := ExistBlock("CN120VLPAR")
Local lRetVlPar:=.T.
Local lFisico  := .F.
Local lVldVige := GetNewPar("MV_CNFVIGE","N") == "N"
Local lBloqSE2 := .F.
Local lGCTBloq := (SE2->(FieldPos("E2_MSBLQL")) > 0)
Local lAtuSld  := .T.
Local lCN120VMP:= .T.
Local lPeVdSld := ExistBlock("CN120VDSD")
Local lSldFlex := .T.
Local lUsaFlag	:= SuperGetMV( "MV_CTBFLAG" , .T. /*lHelp*/, .F. /*cPadrao*/)
Local lCtbCNE	:= .F.
Local lCtbOnLine := .F.
Local aFlagCTB := {}

Local cFilCod  := ""
Local cCronog  := ""
Local cParcel	 := ""
Local cAliasQry:= ""
Local cAliasSD1:= ""
Local cAliasSE2:= ""
Local cFilCND  := xFilial("CND")
Local cFilSC7  := xFilial("SC7")
Local cNumPed  := ""
Local cNumTit  := ""
Local cTexto	 := ""
Local cFilCNS  := ""
Local cAlias   := ""
Local cEspCtr  := ""
Local cAliasCNE:= ""
Local cChave   := ""
Local cParcela := "123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0"
Local cChave1  := ""
Local cChave2  := ""
Local cTes     := ""

Local nMedLmt   := 0 //Limite de medicao do contrato
Local nTaxa
Local nTipo     := 1 //1 - Medicao;2 - Autorizacao de Fornecimento
Local nAcao     := 1 //1 - Encerra;2 - Gera Pedido;3 - Somente Encerra
Local nServico  := 1 //1 - Medicao;2 - Medicao de Servico;
Local nParcelas := SuperGetMv("MV_NUMPARC")
Local nTpDoc	  := CN120VerDoc(CND->CND_NUMMED) //Verifica quais documentos foram gerados Pedidos/Titulos
Local nTamContra := TamSx3("CNZ_CONTRA")[1]
Local nTamRevisa := TamSx3("CNZ_REVISA")[1]
Local nTamNummed := TamSX3("CNZ_NUMMED")[1]
Local nTamItem   := TamSx3("CNZ_ITCONT")[1]
Local nLp69A	:= 0
Local nLp69H	:= 0

Local uRet

//Variaveis para contabilizacao
Local nHead			:= 0 						//Retorno da funcao HeadProva
Local nDet  			:= 0     					//Retorno da funcao DetProva
Local cArqGCT 		:= ""                       //Arquivo contabilizacao
Local cLancCont		:= ""						// Numero da LP
Local lDigita 		:= .F.    	 				//Mostra lancamento?
Local lAglutina		:= .F.    	 				//Aglutina
Local cLoteGCT  		:= LoteCont("COM")  		//Numero do Lote

Local nI				:= 0
Local cBusca			:= ""
Local cSeqPCOLan		:= ""	//Sequencia de Lancamento do PCO - 000355t
Local lMedComPlan 	:= .F.

Local oModel			:= Nil

Local aLPGCT		:= {	{"697",VerPadrao("697")},; //LP Gestão de Contratos - Encerramento da Medição
							{"698",VerPadrao("698")},; //LP Gestão de Contratos - Encerramento da Medição/Automatico
							{"699",VerPadrao("699")},; //LP Gestão de Contratos - Encer. Medicao: Itens do Contrato
							{"69A",VerPadrao("69A")},; //LP Gestão de Contratos - Est. Medicao: Itens do Contrato
							{"69B",VerPadrao("69B")},; //LP Gestão de Contratos - Incl. Rateio Itens Contrato s/ Planilha
							{"69C",VerPadrao("69C")},; //LP Gestão de Contratos - Excl. Rateio Itens Contrato s/ Planilha
							{"69D",VerPadrao("69D")},; //LP Gestão de Contratos - Incl. Rateio Itens Contrato c/ Planilha
							{"69E",VerPadrao("69E")},;
							{"69F",VerPadrao("69F")},; //LP Gestão de Contratos - Excl. Rateio Itens Contrato c/ Planilha
							{"69H",VerPadrao("69H")},; //LP Gestão de Contratos - Encerramento da medição por item norma IFRS 15 (bens e serviços)
							{"69I",VerPadrao("69I")}; //LP Gestão de Contratos - Estorno da medição por item norma IFRS 15 (bens e serviços)
						}
DEFAULT lAviso   := .T.
DEFAULT lAutoFor := .F.
DEFAULT lMedServ := .F.
DEFAULT lAprRev	 := .F.

If Type('cOrigem') == 'U'
	cOrigem = 'CNTA120'
EndIf

//Estabelece passos
ProcRegua(5)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Posiciona na medicao                              ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
dbSelectArea("CND")
CND->(MsGoTo(nReg))

If ( !lAutoFor .Or. !lMedServ ) .And. (!FWIsInCallStack('MATA094') .Or. !GetNewPar("MV_CNMDEAT",.F.) )
	lRet := CN240VldUsr(CND->CND_CONTRA,DEF_TRAENC,.T.,,cFilCtr)
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Ponto de entrada para validar o encerramento da   ³
//³medicao                                           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If ExistBlock("CN120VENC")
	uRet := ExecBlock("CN120VENC", .F., .F., {lRet})
	If ValType(uRet) == "L"
		lRet := uRet
	EndIf
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Ponto de entrada para indicar se atualiza ou nao  ³
//³saldo da medicao                                  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If ExistBlock("CN120ATSLD")
	lAtuSld := ExecBlock("CN120ATSLD",.F.,.F.)
	If ValType(lAtuSld) <> "L"
		lAtuSld:=.T.
	EndIf
EndIf

cChave := CND->CND_CONTRA+CND->CND_REVISA+CND->CND_NUMERO+CND->CND_NUMMED

If LockByName("CN120"+xFilial("CND")+cChave,.T.,!Empty(xFilial("CND")),.T.)
	Pergunte("CNT120",.F.)	//carrega as variaveis

	If Type("cOrigem") == "C"
		cLancCont:= IiF(ALLTRIM(cOrigem) == "CNTA120",cLancCont:= "697",cLancCont:= "698")

		If cOrigem == "CNTA260" .and. GetRemoteType() != -1 .And. lShow
	   		Pergunte("CNT120",.T.)
	   	ElseIf (cOrigem == "CNTA260" .and. GetRemoteType() == -1) .Or. lAprRev
	   		MV_PAR01 := 1
	   		MV_PAR02 := 2
	   		MV_PAR03 := 2
		EndIf
	Else
		cLancCont:= "697"
	EndIf


	If (lCtbOnLine := (MV_PAR01 == 1)) //SE CONTABILIZA, atraves da escolha do usuario
		//Percorre os lancamentos contabeis do GCT, se algum deles existir, a contabilizacao podera ter continuidade
		For nI := 1 to len(aLPGCT)
			If aLPGCT[nI,2]
				lCtbOnline := .t.
				Exit
			Else
				lCtbOnline := .f.
			Endif
		Next nI

		If lCtbOnLine
			lDigita	 	:= IIF(VAlTYPE(MV_PAR02)=="N" ,MV_PAR02 == 1,.F.)
			lAglutina	:= IIF(VAlTYPE(MV_PAR03)=="N" ,MV_PAR03 == 1,.F.)

			nHead	:= HeadProva(cLoteGCT,cOrigem,Subs(cUsuario,7,6),@cArqGCT)
			If nHead <= 0
				If GetRemoteType() != -1
					HELP(" ",1,STR0081) //"SEM_LANC"
				Else
					ConOut(STR0081) //"SEM_LANC"
				EndIf
				lCtbOnLine := .F.
			EndIf
		EndIf
	Endif

	If lRet
		nTipo := If(CND->CND_AUTFRN=="2",2,1)
		If nTipo == 2
			If Empty(CND->CND_PEDIDO)
				nAcao := 2
			Else
				nAcao := 3
			EndIf
		EndIf

		nServico := If(CND->CND_SERVIC=="1",1,2)

		//-- Verifica se a medicao ja se encontra encerrada
		If !Empty(CND->CND_DTFIM)
			lRet := .F.
			Help( " ", 1, "CNTA120_03" )//"Medição já encerrada"
		ElseIf (GetNewPar("MV_CNMDALC","N") == "S" ) .AND. CND->CND_ALCAPR == "B"
			lRet := .F.
			Help( " ", 1, "CNTA120_09" )//"Medição bloqueada por alçada"
		EndIf

		dbSelectArea("CN9")
		CN9->(dbSetOrder(1))
		If lRet .And. CN9->(MsSeek(xFilial("CN9",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA))
			If (CN9->CN9_SITUAC==DEF_SFINA .OR. CN9->CN9_SITUAC==DEF_SCANC) //Contrato finalizado ou cancelado
				lRet := .F.
				Help( " ", 1, "CNTA120_02" )//"Apenas contratos em vigência podem ser medidos"
			EndIf
		EndIf

		//- Verifica se os campos CND_DATA e CND_PARC estão criados conforme parametro MV_NUMPARC
		dbSelectArea("SE4")
		SE4->(dbSetOrder(1))
		SE4->(MsSeek(xFilial("SE4")+CND->CND_CONDPG))
		If SE4->E4_TIPO=='9'
			If nParcelas > 4
				cChave1  := "CND_DATA"+Subs(cParcela,nParcelas,1)
				cChave2  := "CND_PARC"+Subs(cParcela,nParcelas,1)

				aAreaSX3 := SX3->(GetArea())
				DbSelectArea("SX3")
				SX3->(dbSetOrder(2))
				If lRet .And. (!DbSeek(cChave1) .or. !DbSeek(cChave2))
					Help(" ",1,"TMKTIP905") //"A quantidade de parcelas nao esta compativel. Verificar junto ao administrador do sistema relacao entre parametro MV_NUMPARC e dicionario de dados"
					lRet:= .F.
				EndIf
				Restarea(aAreaSX3)
			EndIf
		EndIf

		If lRet
			If !Empty(CND->CND_CLIENT)
				lRet := ExistCpo("SA1",CND->CND_CLIENT+CND->CND_LOJACL)   //Verifica se cliente e loja existe
			Else
			    lRet :=	ExistCpo("SA2",CND->CND_FORNEC+CND->CND_LJFORN)
			EndIf
		EndIf

		If nAcao != 3
			If lRet
				dbSelectArea("CN9")
				CN9->(dbSetOrder(1))
				If CN9->(MsSeek(xFilial("CN9",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA))
					//- Identifica especie do contrato 1:Compra|2:Venda
					cEspCtr 	:= CN9->CN9_ESPCTR

					CN1->(dbSetOrder(1))
					CN1->(MsSeek(xFilial("CN1",cFilCTR)+CN9->CN9_TPCTO))

					lMedEve := Cn300RetSt("MEDEVE",0,CND->CND_NUMERO,CN9->CN9_NUMERO,CN9->CN9_FILCTR,.F.)
					lContab := Cn300RetSt("CONTABIL",0,CND->CND_NUMERO,CN9->CN9_NUMERO,CN9->CN9_FILCTR,.F.)
					lFixo  := Cn300RetSt("FIXO",0,CND->CND_NUMERO,CN9->CN9_NUMERO,CN9->CN9_FILCTR,.F.)
					lValor := Cn300RetSt("PREVFINANC",0,CND->CND_NUMERO,CN9->CN9_NUMERO,CN9->CN9_FILCTR,.F.)
					lFisico := Cn300RetSt("FISICO",0,CND->CND_NUMERO,CN9->CN9_NUMERO,CN9->CN9_FILCTR,.F.)
					nMedLmt:= CN1->CN1_LMTMED		//- Limite da medição
					lFscLmt:= CN1->CN1_TPLMT == "2"
				EndIf

				If lFixo
					cCronog := Posicione("CNA",1,xFilial("CNA",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA+CND->CND_NUMERO,"CNA_CRONOG")
					If !lMedEve
						IncProc( STR0013 )//"Validando Cronograma X Planilhas"
						//- Quando nao for medicao eventual valida valor previsto do cronograma com valor realizado
						dbSelectArea("CNF")
						If !Empty(CND->CND_PARCEL)
							CNF->(dbSetOrder(3))
							CNF->(dbSeek(xFilial("CNF",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA+cCronog+CND->CND_PARCEL))
						Else
							dbSetOrder(2)
							dbSeek(xFilial("CNF",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA+cCronog+CND->CND_COMPET)
						EndIf

						If Found()
							cParcel := CNF->CNF_PARCEL
							If lPeVlPar
								lRetVlPar := If(Valtype(lRetVlPar:=ExecBlock("CN120VLPAR",.F.,.F.))=="L",lRetVlPar,.T.)
							EndIf

							If lRetVlPar
								If !lFscLmt //- Soma o limite de medicao ao saldo da parcela

									nTaxa := CNF->CNF_TXMOED
									If lRet .And. ((CNF->CNF_SALDO+((CNF->CNF_VLPREV*nMedLmt)/100)) < xMoeda(CND->CND_VLTOT - CN120VlExc(),CND->CND_MOEDA,CN9->CN9_MOEDA,dDataBase,TamSX3("CND_VLTOT")[2],,nTaxa))
										Aviso("CNTA120",STR0011+CRLF+STR0012,{STR0155})//"Valor total de medição não previsto no cronograma."+CRLF+"O mesmo deve ser reestruturado."
										lRet := .F.
									EndIf
								Else
									//- Valida a quantidade medida contra a quantidade prevista no cronograma
									cQuery := "SELECT CNE.CNE_ITEM,CNE.CNE_QUANT,CNS.CNS_PRVQTD "
									cQuery += "  FROM "+RetSQLName("CNE")+" CNE, "+RetSQLName("CNS")+" CNS, "+RetSQLName("CNF")+" CNF "
									cQuery += " WHERE CNE.CNE_FILIAL = '"+xFilial("CNE")+"'"
									cQuery += "   AND CNS.CNS_FILIAL = '"+xFilial("CNS",cFilCTR)+"'"
									cQuery += "   AND CNF.CNF_FILIAL = '"+xFilial("CNF",cFilCTR)+"'"
									cQuery += "   AND CNE.CNE_NUMMED = '"+CND->CND_NUMMED+"' AND "
									If !Empty(CND->CND_PARCEL)
										cQuery += "CNF.CNF_PARCEL = '"+CND->CND_PARCEL+"' AND "
									Else
										cQuery += "CNF.CNF_COMPET = '"+CND->CND_COMPET+"' AND "
									EndIf
									cQuery += "     CNS.CNS_CONTRA = CNE.CNE_CONTRA "
									cQuery += " AND CNS.CNS_REVISA = CNE.CNE_REVISA "
									cQuery += " AND CNS.CNS_PLANI  = CNE.CNE_NUMERO "
									cQuery += " AND CNS.CNS_ITEM   = CNE.CNE_ITEM   "
									cQuery += " AND CNS.CNS_CONTRA = CNF.CNF_CONTRA "
									cQuery += " AND CNS.CNS_REVISA = CNF.CNF_REVISA "
									cQuery += " AND CNS.CNS_CRONOG = CNF.CNF_NUMERO "
									cQuery += " AND CNS.CNS_PARCEL = CNF.CNF_PARCEL "
									cQuery += " AND CNS.D_E_L_E_T_ = ' ' "
									cQuery += " AND CNE.D_E_L_E_T_ = ' ' "
									cQuery += " AND CNF.D_E_L_E_T_ = ' ' "

									cAlias := GetNextAlias()
									cQuery := ChangeQuery( cQuery )
									dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQuery ), cAlias, .F., .T. )

									nMedLmt += 100

									While !(cAlias)->(Eof())
										If ((cAlias)->CNS_PRVQTD = 0 .And. (cAlias)->CNE_QUANT > 0) .OR. ((((cAlias)->CNE_QUANT*100)/(cAlias)->CNS_PRVQTD) > nMedLmt)
											Aviso("CNTA120",OemToAnsi(STR0035)+(cAlias)->CNE_ITEM+OemToAnsi(STR0036),{STR0155})//"Não é possível encerrar a medição.O item "##" ultrapassou o limite de medição do cronograma físico"
											lRet := .F.
											Exit
										EndIf
										(cAlias)->(dbSkip())
									EndDo

									(cAlias)->(dbCloseArea())
								EndIf
							EndIf
						EndIf
					EndIf
		   		Else
					//- Ponto de entrada permite ou não validar o saldo do contrato do tipo flexível com o valor da medição a ser encerrada
					If lPeVdSld
						lSldFlex := ExecBlock("CN120VDSD",.F.,.F.)
					EndIf

					If lSldFlex
						CNA->(dbSetOrder(1))
						If CNA->(dbSeek(xFilial("CNA",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA+CND->CND_NUMERO))
							If lValor .And. CNA->CNA_SALDO < xMoeda(CND-> CND_VLTOT - CN120VlExc(),CND->CND_MOEDA,CN9->CN9_MOEDA,dDataBase,TamSX3("CND_VLTOT")[2])
								If nTipo==1 .And. nServico ==1
									Aviso("CNTA120",STR0049,{STR0155})//"Não foi possível encerrar a medição. O saldo do contrato nao equivale ao valor da medicao."
								Else
									Aviso("CNTA120",STR0057,{STR0155})//"Não foi possível gerar o pedido. O saldo do contrato nao equivale ao valor da medicao."
								EndIf
								lRet := .F.
							EndIf
						EndIf
					EndIf
				EndIf

				//- Executa ponto de entrada após validação do valor previsto com realizado
				If ExistBlock("CN120VMP")
				   lCN120VMP := ExecBlock("CN120VMP",.F.,.F.,{lRet})
				  	If ValType(lCN120VMP) == "L"
						lRet := lCN120VMP
					EndIf
				EndIf

					//³Verifica se houveram itens medidos quando a  medicao nao for zerada
				If(CND->CND_ZERO == "2" .And. CND->CND_VLTOT == 0)
					Help( " ", 1, "CNTA120_04")// "Não existem itens medidos no registro atual"
					lRet := .F.
				EndIf
			EndIf

			If lRet
				IncProc( STR0015 )//"Atualizando Medicao e Itens"
				PcoIniLan("000355")
				Begin Transaction
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³Chama ponto de entrada para verificar se gera pedido. ³
					//³Podera ser utilizado para aglutinar varias medicoes e |
					//³somente apos realizar a geracao do pedido.            |
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					If lPeGrP
						lGrped := ExecBlock("CN120GRPED",.f.,.f.)
					EndIf

					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Gera pedido de compra                 ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			        If lGrPed
						If CND->CND_ZERO == "2"
							IncProc( OemToAnsi( If(cEspCtr=="1",STR0017,STR0039) ) )//"Gerando Pedido de Compras"##"Gerando Pedido de Vendas"
							lRet := CN120GrvPed(CND->CND_NUMMED,CND->CND_REVISA,@cNumPed,nTaxa,CND->CND_CONTRA,@cTes,.F.,@cNumTit)
						EndIf
					Else
						lRet := .T. //Retorna .T. para continuar o processo normal
					EndIf

					If lRet
						//- Atualiza data fim da medicao
						If nAcao == 1
							RecLock("CND",.F.)
								CND->CND_DTFIM := dDataBase
								CND->CND_SITUAC := IIf(CND->CND_AUTFRN == '1','E','FE')
								CND->CND_FILMED := cFilAnt
							MsUnlock()
						EndIf

					   		//- Ponto lancamento contabil e orcamentario para encerramento da medicao
						PcoDetLan("000355","03","CNTA120")
						If lCtbOnLine
					    	nDet += DetProva(nHead,cLancCont,cOrigem,cLoteGCT,,,,,,,,,{"CND",CND->(RECNO())})
						EndIf

						DbSelectArea("CNE")
						CNE->(dbSetOrder(1))
						cFilCod := xFilial()
						CNE->(MsSeek(cFilCod+CND->CND_CONTRA+CND->CND_REVISA+CND->CND_NUMERO+CND->CND_NUMMED))

						If lFisico
							cFilCNS := xFilial("CNS",cFilCTR)
						EndIf

						If lAtuSld .And. !lPeSld
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³ Atualiza itens da planilha                      ³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							While CNE->CNE_FILIAL = cFilCod .And. CNE->CNE_CONTRA = CND->CND_CONTRA .And. CNE->CNE_REVISA = CND->CND_REVISA .And.;
								CNE->CNE_NUMERO = CND->CND_NUMERO .And. CNE->CNE_NUMMED = CND->CND_NUMMED

								lMedComPlan := .f.

								If lFixo
									//-- Itens excedentes nao atualizam saldos
									If CNE->CNE_EXCEDE == '2'
										dbSelectArea("CNB")
										CNB->(dbSetOrder(1))
										If CNB->(MsSeek(xFilial("CNB",cFilCTR)+CNE->(CNE_CONTRA+CNE_REVISA+CNE_NUMERO+CNE_ITEM)))
											RecLock("CNB",.F.)
												If nServico == 1
													CNB->CNB_QTDMED += CNE->CNE_QUANT
													CNB->CNB_SLDMED -= IIf(Cn300RetSt("SEMIFIXO",0,CNE->CNE_NUMERO),0,CNE->CNE_QUANT)
												Else
													CNB->CNB_QTDMED += ( ( CNE->CNE_VLTOT / CNB->CNB_VLTOT ) * CNB->CNB_QUANT )
													CNB->CNB_SLDMED -= IIf(Cn300RetSt("SEMIFIXO",0,CNE->CNE_NUMERO),0,( ( CNE->CNE_VLTOT / CNB->CNB_VLTOT ) * CNB->CNB_QUANT ))
												EndIf
											MsUnlock()
												//- CAPTURO A VARIAVEL FLAG DE ITENS COM PLANILHA
											lMedComPlan := .T.
										EndIf

										If lFisico
											dbSelectArea("CNS")
											CNS->(dbSetOrder(1))
											If CNS->(MsSeek(cFilCNS+CND->(CND_CONTRA+CND_REVISA)+cCronog+cParcel+CNB->CNB_ITEM))
												RecLock("CNS",.F.)
												CNS->CNS_RLZQTD += CNE->CNE_QUANT
												CNS->CNS_SLDQTD -= CNE->CNE_QUANT
												MsUnlock()
											EndIf
										EndIf
									EndIf
								EndIf

								PcoDetLan("000355","04","CNTA120")

								If lCtbOnLine //- CONTABILIZA ENCERRAMENTO DA MEDICAO - ITENS DO CONTRATO

									nLp69A	:= aScan(aLPGCT,{|x| x[1]=="69A"})
									nLp69H := aScan(aLPGCT,{|x| x[1]=="69H"})

									If lUsaFlag
										aAdd( aFlagCTB, {"CNE_DTLANC", dDataBase, "CNE", CNE->( Recno() ), 0, 0, 0} )
									EndIf

									If aLPGCT[nLp69H,2] .And. cEspCtr == '2' .And. CN9->CN9_DTINIC >= CTOD("01/01/2018") // - Ponto de lançamento padrão IFRS15
										nDet += DetProva(nHead,'69H',cOrigem,cLoteGCT,,,,,,,,@aFlagCTB,{"CNE",CNE->(Recno())})
										lCtbCNE	:= .T.
									ElseIf aLPGCT[nLp69A,2]
										nDet += DetProva(nHead,"69A",cOrigem,cLoteGCT,,,,,,,,@aFlagCTB,{"CNE",CNE->(Recno())})
										lCtbCNE	:= .T.
									EndIf

									If !lUsaFlag .And. lCtbCNE
										If CNE->(Columnpos('CNE_DTLANC')) > 0
											dbSelectArea("CNE")
											RecLock("CNE",.F.)
											CNE->CNE_DTLANC := dDataBase
											MsUnlock()
										EndIf
									EndIf

								EndIf

								If lMedComPlan
									cLancCont 	:= "69E"
									cSeqPCOLanc	:= "06"
								Else
									cLancCont := "69C"
									cSeqPCOLanc	:= "05"
								Endif

                        	  	cBusca :=	xFilial("CNZ",cFilCTR) +;
								Padr(CNE->CNE_CONTRA	,nTamContra )+;
								Padr(CNE->CNE_REVISA	,nTamRevisa )+;
								Padr(CNE->CNE_NUMMED	,nTamNummed )+;
								Padr(CNE->CNE_ITEM	,nTamItem )

								CNZ->(dbSetOrder(2)) //CNZ_FILIAL+CNZ_CONTRA+CNZ_REVISA+CNZ_NUMMED+CNZ_ITCONT+CNZ_ITEM

								If CNZ->(dbSeek( cBusca ))
									While CNZ->(!Eof()) .and. cBusca == xFilial("CNZ",cFilCTR) +;
										Padr(CNZ->CNZ_CONTRA	,nTamContra) +;
										Padr(CNZ->CNZ_REVISA	,nTamRevisa) +;
										Padr(CNZ->CNZ_NUMMED	,nTamNummed) +;
										Padr(CNZ->CNZ_ITCONT 	,nTamItem)
						  		     	If !Empty(CNZ->CNZ_CC)
						  		     		PcoDetLan("000355",cSeqPCOLan,"CNTA120")

											//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
											//³ Contabiliza os rateios do item do contrato com planilha. 												  ³
											//³ Se ha planilha, entao nao podera contabilizar o rateio sem planilha, abaixo (controlar com variavel flag) ³
											//³ efetua a contabilizacao dos rateios do item do contrato sem planilha, 									  ³
											//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
											If lCtbOnLine
												nDet += DetProva(nHead,cLancCont,"CNTA120",cLoteGCT,,,,,,,,,{"CNZ",CNZ->(Recno())})
			  								EndIf
			  							EndIf
										CNZ->(DbSkip())
									EndDo
								Endif
								CNE->(dbSkip())
							EndDo
					 	EndIf

						//- Atualiza saldo da planilha
						If lFixo .Or. (!lFixo .And. lValor)
	    					IncProc( STR0016 )
							dbSelectArea("CNA")
							CNA->(dbSetOrder(1))
							If CNA->(MsSeek(xFilial("CNA",cFilCTR)+CND->(CND_CONTRA+CND_REVISA+CND_NUMERO))) .And. lAtuSld .And. !lPeSld//Nao atualiza saldo quando o ponto de entrada CN120SLDCTR estiver ativo
								RecLock("CNA",.F.)
								CNA->CNA_SALDO -= xMoeda(CND->CND_VLTOT - CN120VlExc(),CND->CND_MOEDA,CN9->CN9_MOEDA,dDataBase,TamSX3("CND_VLTOT")[2],,nTaxa)
								CNA->(MsUnlock())
							EndIf
						EndIf

						//- Atualiza saldo do contrato
						CN9->(dbSetorder(1))
						If CN9->(MsSeek(xFilial("CN9",cFilCTR)+CND->(CND_CONTRA+CND_REVISA)))
							If lAtuSld .And. !lPeSld//Nao atualiza saldo quando o ponto de entrada CN120SLDCTR estiver ativo
								RecLock("CN9",.F.)
								If lFixo .Or. lValor
									CN9->CN9_SALDO -= xMoeda(CND->CND_VLTOT - CN120VlExc(),CND->CND_MOEDA,CN9->CN9_MOEDA,dDataBase,TamSX3("CND_VLTOT")[2],,nTaxa)
								Else
									CN9->CN9_VLATU += xMoeda(CND->CND_VLTOT - CN120VlExc(),CND->CND_MOEDA,CN9->CN9_MOEDA,dDataBase,TamSX3("CND_VLTOT")[2],,nTaxa)//Atualiza valor do contrato
									If Empty(CN9->CN9_REVISA)//Se contrato original atualiza valor inicial
										CN9->CN9_VLINI += xMoeda(CND->CND_VLTOT - CN120VlExc(),CND->CND_MOEDA,CN9->CN9_MOEDA,dDataBase,TamSX3("CND_VLTOT")[2],,nTaxa)
									EndIf
								EndIf
								CN9->(MsUnlock())
							EndIf
						EndIf

						If !lMedEve .And. lFixo
							//- Atualiza saldo do cronograma quando nao houver medicao eventual
							dbSelectArea("CNF")
							If !Empty(CND->CND_PARCEL)
								CNF->(dbSetorder(3))
								CNF->(MsSeek(xFilial("CNF",cFilCTR)+CND->(CND_CONTRA+CND_REVISA)+cCronog+CND->CND_PARCEL))
							Else
								CNF->(dbSetorder(2))
								CNF->(MsSeek(xFilial("CNF",cFilCTR)+CND->(CND_CONTRA+CND_REVISA)+cCronog+CND->CND_COMPET))
							EndIf

							If Found()
								If lAtuSld .And. !lPeSld//Nao atualiza saldo quando o ponto de entrada CN120SLDCTR estiver ativo
									RecLock("CNF")
									CNF->CNF_VLREAL += xMoeda(CND->CND_VLTOT - CN120VlExc(),CND->CND_MOEDA,CN9->CN9_MOEDA,dDataBase,TamSX3("CND_VLTOT")[2],,nTaxa)
									CNF->CNF_SALDO  -= xMoeda(CND->CND_VLTOT - CN120VlExc(),CND->CND_MOEDA,CN9->CN9_MOEDA,dDataBase,TamSX3("CND_VLTOT")[2],,nTaxa)
									CNF->CNF_DTREAL := dDataBase
									MsUnlock()

									If (GetNewPar( "MV_CNPROVI" ,  "S" ) == "S")
										IncProc( STR0021 )//"Processando títulos provisórios"
										CN100ETit(CND->CND_CONTRA,CND->CND_REVISA,cCronog,CNF->CNF_PARCEL,cFilCtr)
										If CNF->CNF_SALDO > 0
											CN100CTit(CND->CND_CONTRA,CND->CND_REVISA,cCronog,CNF->CNF_PARCEL,CNF->CNF_SALDO)
										EndIf
									EndIf
								EndIf
							EndIf
						EndIf

						If lContab
							dbSelectArea("CNV")
							CNV->(dbSetOrder(2))

							If CNV->(MsSeek(xFilial("CNV",cFilCTR)+CND->(CND_CONTRA+CND_REVISA+CND_NUMERO)))
								nVlOr := xMoeda(CND->CND_VLTOT - CN120VlExc(),CN9->CN9_MOEDA,1,dDataBase,TamSX3("CNV_VRCAMB")[2],CNV->CNV_TXMOED)
								nVlAtu:= xMoeda(CND->CND_VLTOT - CN120VlExc(),CN9->CN9_MOEDA,1,dDataBase,TamSX3("CNV_VRCAMB")[2])
								RecLock("CNV",.F.)
								CNV->CNV_VRCAMB += nVlAtu-nVlOr
								MsUnlock()
							EndIf
						EndIf

						If lPeSld//Chama ponto de entrada para atualizacao do saldo
							ExecBlock("CN120ENSLD",.F.,.F.,{lMedEve,lFisico,cCronog,lFixo,lValor})
						EndIf

						//- Executa ponto de entrada para encerramento da medicao
						If ExistBlock("CN120ENCMD")
							ExecBlock("CN120ENCMD",.F.,.F.)
						EndIf
					EndIf
				End Transaction

				//- Executa ponto de entrada para encerramento da medicao
				If lRet .And. ExistBlock("CN120ENMED")
					ExecBlock("CN120ENMED",.F.,.F.)
				EndIf

				If lRet
					PcoFinLan("000355")
				EndIf

				If !lAuto
					If lAviso .And. !lAprRev
						If lRet
							If Empty(cNumPed) .And. Empty(cNumTit)
								If nTipo == 1 .And. nServico == 1
									Aviso("CNTA120",OemToAnsi(STR0050),{STR0155})//"Medição/entrega encerrada com sucesso"
								ElseIf nTipo == 2
									Aviso("CNTA120",OemToAnsi(STR0065),{STR0155})//"Autorização de fornecimento encerrada com sucesso"
								Else
									Aviso("CNTA120",OemToAnsi(STR0084),{STR0155})//"Medição de Serviços encerrada com sucesso"
								EndIf
							Else
								If !Empty(cNumTit)
									cTexto := OemToAnsi(If(cEspCtr=="1",STR0118,STR0119))+cNumTit //Gerado titulo à pagar/receber número "
									cTexto += CRLF
								EndIf
								If !Empty(cNumPed)
									cTexto += OemToAnsi(If(cEspCtr=="1",STR0026,STR0044))+cNumPed//"Gerado pedido de compra/venda número "
								EndIf
								Aviso("CNTA120",cTexto,{STR0155})//"Gerado pedido de compra número "
							EndIf
						ElseIf Empty(cNumTit)
							If Empty(cTes).And.cEspCtr=="2"
								Aviso("CNTA120",STR0080,{STR0155})//Produto não possui TES vinculada. Vincule o Produto a TES através do Cadastro de Produtos antes de Encerrar a Medição.
							Else
								Aviso("CNTA120",OemToAnsi(If(cEspCtr=="1",STR0027,STR0045))+" "+OemToAnsi(STR0028),{STR0155})//"O pedido de compra não pode ser gerado."##"Para mais informações consulte o log gerado no diretório \SYSTEM do sistema"
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		Else
			Begin Transaction
			//- Atualiza data fim da medicao
			RecLock("CND",.F.)
				CND->CND_DTFIM := dDataBase
				CND->CND_SITUAC := IIf(CND->CND_AUTFRN == '1','E','FE')
			MsUnlock()

			//- Desbloqueia titulos
			lBloqSE2 := .F.

			//- Seleciona a nota
			cQuery := "SELECT DISTINCT SF1.F1_DOC, SF1.F1_SERIE, SF1.F1_TIPO, SF1.F1_DUPL, SF1.F1_PREFIXO, F1_FORNECE, F1_LOJA "
			cQuery += "  FROM " + RetSQLName("SF1") + " SF1, " + RetSQLName("SD1") + " SD1 "
			cQuery += " WHERE SF1.F1_FILIAL  = '" + xFilial("SF1") + "'"
			cQuery += "   AND SD1.D1_FILIAL  = '" + xFilial("SD1") + "'"
			cQuery += "   AND SF1.F1_DOC     = SD1.D1_DOC     "
			cQuery += "   AND SF1.F1_SERIE   = SD1.D1_SERIE   "
			cQuery += "   AND SF1.F1_TIPO    = SD1.D1_TIPO    "
			cQuery += "   AND SF1.F1_FORNECE = SD1.D1_FORNECE "
			cQuery += "   AND SF1.F1_LOJA    = SD1.D1_LOJA    "
			cQuery += "   AND SD1.D1_PEDIDO  = '" + CND->CND_PEDIDO + "'"
			cQuery += "   AND SF1.D_E_L_E_T_ = ' ' "
			cQuery += "   AND SD1.D_E_L_E_T_ = ' '"

			cQuery    := ChangeQuery( cQuery )
			cAliasQry := GetNextAlias()
			dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQuery ), cAliasQry, .F., .T. )

			If !(cAliasQry)->(Eof())
				//³ Seleciona os pedidos relacionados na mesma nota   ³
				cQuery := "SELECT DISTINCT SD1.D1_PEDIDO "
				cQuery += "  FROM " + RetSQLName("SD1") + " SD1 "
				cQuery += " WHERE SD1.D1_FILIAL   = '" + xFilial("SD1") + "'"
				cQuery += "   AND SD1.D1_DOC      = '" + (cAliasQry)->F1_DOC + "'"
				cQuery += "   AND SD1.D1_SERIE    = '" + (cAliasQry)->F1_SERIE + "'"
				cQuery += "   AND SD1.D1_TIPO     = '" + (cAliasQry)->F1_TIPO + "'"
				cQuery += "   AND SD1.D1_PEDIDO  <> '" + CND->CND_PEDIDO + "'"
				cQuery += "   AND SD1.D_E_L_E_T_  = ' '"

				cQuery    := ChangeQuery( cQuery )
				cAliasSD1 := GetNextAlias()
				dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQuery ), cAliasSD1, .F., .T. )

				While !(cAliasSD1)->(Eof())
					dbSelectArea("SC7")
					SC7->(dbSetOrder(1))
					If SC7->(MsSeek(cFilSC7+(cAliasSD1)->D1_PEDIDO))
						//³ Verifica se o pedido foi originado por uma medicao³
						If !Empty(SC7->C7_CONTRA)
							dbSelectArea("CND")
							CND->(dbSetOrder(1))
							//³ Posiciona na Medicao ³
							If CND->(MsSeek(cFilCND+SC7->(C7_CONTRA+C7_CONTREV+C7_PLANILH+C7_MEDICAO)))
								//³ Quando houver alguma medicao NAO encerrada impede o desbloqueio dos titulos ³
								If Empty(CND->CND_DTFIM)
									lBloqSE2 := .T.
									Exit
								EndIf
							EndIf
						EndIf
					EndIf
					(cAliasSD1)->(dbSkip())
				EndDo
				(cAliasSD1)->(dbCloseArea())

				//³ Desbloqueia os titulos ³
				If !lBloqSE2 .And. lGCTBloq
					//³ Seleciona os titulos ³
					cQuery := "SELECT SE2.R_E_C_N_O_ AS RECNO "
					cQuery += "  FROM " + RetSQLName("SE2") + " SE2 "
					cQuery += " WHERE SE2.E2_FILIAL  = '" + xFilial("SE2") + "'"
					cQuery += "   AND SE2.E2_NUM     = '" + (cAliasQry)->F1_DUPL + "'"
					cQuery += "   AND SE2.E2_PREFIXO = '" + IIf(Empty((cAliasQry)->F1_PREFIXO),&(SuperGetMV("MV_2DUPREF")),(cAliasQry)->F1_PREFIXO) + "'"
					cQuery += "   AND SE2.E2_FORNECE = '" + (cAliasQry)->F1_FORNECE + "'"
					cQuery += "   AND SE2.E2_LOJA    = '" + (cAliasQry)->F1_LOJA + "'"
					cQuery += "   AND SE2.E2_TIPO    = 'NF '"
					cQuery += "   AND SE2.D_E_L_E_T_ = ' ' "

					cQuery    := ChangeQuery( cQuery )
					cAliasSE2 := GetNextAlias()
					dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQuery ), cAliasSE2, .F., .T. )

					//³ Desbloqueia os titulos ³
					While !(cAliasSE2)->(Eof())
						SE2->( MsGoTo( (cAliasSE2)->RECNO ) )
						RecLock("SE2",.F.)
							SE2->E2_MSBLQL := "2"
						MsUnlock()
						(cAliasSE2)->(dbSkip())
					EndDo
					(cAliasSE2)->(dbCloseArea())
				EndIf
			EndIf
			(cAliasQry)->(dbCloseArea())

			End Transaction

			If !lAuto .And. !lAprRev .And. lAviso
				If nTipo == 2
					Aviso("CNTA120",OemToAnsi(STR0065),{STR0155})//"Autorização de Fornecimento encerrada com sucesso"
				Else
					Aviso("CNTA120",OemToAnsi(STR0084),{STR0155})//"Autorização de Fornecimento encerrada com sucesso"
				EndIf
			EndIf
		EndIf
	EndIf
Else
	// Nao permite processamento concorrente
	Aviso(STR0068,OemtoAnsi(STR0069),{STR0155},2) // ##"Concorrência"##"Esta Medição está em uso por outra estação."
EndIf

If lCtbOnLine
	RodaProva(nHead,nDet)
	If nDet > 0
		cA100Incl(cArqGCT,nHead,1,cLoteGCT,lDigita,lAglutina,,,,@aFlagCTB)
		aFlagCTB := {}
	EndIf
EndIf

UnLockByName("CN120"+xFilial("CND")+cChave,.T.,!Empty(xFilial("CND")),.T.)
Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN120Ence ³ Autor ³ Marcelo Custodio      ³ Data ³09.02.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Encerra medicao                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN120Ence(cExp01,nExp02,nExp03)                            ³±±
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
Function CN120Ence(cAlias,nReg,nOpc,lAprRev)
Local aValidGet := {}
Local nPosNum
Local lCanEnce  := ExistBlock("CN120ENVL")
Local lContinua := .T.
Local dDataBloq	:= GetNewPar("MV_ATFBLQM",CTOD("")) //Data de Bloqueio da Movimentação - MV_ATFBLQM
Local cAliasTmp := GetNextAlias()
Local aEntDist	:= {}

Default lAprRev := .F.

If Type('lAuto') == 'U'
	lAuto := IsBlind()
EndIf

cFilCtr := CND->CND_FILCTR

If !lAuto
	If !lAprRev
	If CND->CND_AUTFRN == "2"
		lContinua := (Aviso("CNTA120",OemtoAnsi(STR0062),{STR0022,STR0023}) == 1)//"Confirma encerramento da autorização de fornecimento?"
	ElseIf CND->CND_SERVIC == "2"
		lContinua := (Aviso("CNTA120",OemtoAnsi(STR0085),{STR0022,STR0023}) == 1)//"Confirma encerramento da Medicao de Servico?"
	Else
		lContinua := (Aviso("CNTA120",OemtoAnsi(STR0024),{STR0022,STR0023}) == 1)//"Confirma encerramento da medição?"##"Sim"##"Não"
	EndIf
	EndIf
Else
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Verifica se o numero da medicao foi fornecido      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If (nPosNum:=aScan(aAutoCab,{|x| x[1]=="CND_NUMMED"})) > 0
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Valida numero da medicao                           ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		AADD(aValidGet,{"cNumMed" ,aAutoCab[nPosNum,2],"CN120NumAuto(cNumMed,.F.)",.T.})

		If (lContinua := MsVldGAuto(aValidGet))
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Posiciona na medicao                               ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			dbSelectArea("CND")
			dbSetOrder(4)
			dbSeek(xFilial("CND")+aAutoCab[nPosNum,2])
			nReg:=CND->(RECNO())
		EndIf
	else
		lContinua:=.F.
	EndIf
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Ponto de Entrada permite encerrar a medição ou não.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lContinua .And. lCanEnce
	lContinua:=ExecBlock("CN120ENVL",.F.,.F.)
	If ValType(lContinua) <> "L"
		lContinua:=.T.
	EndIf
EndIf

If lContinua
//Verifica se existe bloqueio contábil
	If (lContinua := CtbValiDt(Nil, dDataBase,/*.T.*/ ,Nil ,Nil ,{"GCT001"}/*,"Data de apuração bloqueada pelo calendário contábil."*/) )
		If !Empty(dDataBloq) .AND. ( dDataBase <= dDataBloq)
		//Help(" ",1,"AF012ABLQM",,"Processo bloqueado pelo Calendário Contábil nesta data ou período. Caso possível altere a data de referência do processo ou contate o responsável pelo Módulo Contábil.",1,0) //"Processo bloqueado pelo Calendário Contábil nesta data ou período. Caso possível altere a data de referência do processo ou contate o responsável pelo Módulo Contábil."
			Help(" ",1,"ATFCTBBLQ") //P: Processo bloqueado pelo Calendário Contábil ou parâmetro de bloqueio nesta data ou período. S: Caso possível altere a data de referência do processo, verifique o parâmetro ou contate o responsável pelo Módulo Contábil.)
			lContinua := .F.
		Else
			BeginSQL Alias cAliasTmp
				SELECT 	CNZ.R_E_C_N_O_ AS CNZRECNO
						,CNZ_CONTRA
						,CNZ_NUMMED
						,CNZ_REVISA
						,CNZ_CC
						,CNZ_CONTA
						,CNZ_ITEMCT
						,CNZ_CLVL

				FROM 	%Table:CND% CND
				JOIN 	%Table:CNE% CNE
			    ON 		CND_FILIAL=CNE_FILIAL
			        	AND CND_CONTRA=CNE_CONTRA
			        	AND CND_NUMERO=CNE_NUMERO
			        	AND CND_REVISA=CNE_REVISA
			        	AND CND_NUMMED=CNE_NUMMED
			        	AND CNE.%NotDel%
			    JOIN 	%Table:CNZ% CNZ
			    ON 		CND_FILIAL=CNZ_FILIAL
			        	AND CND_CONTRA=CNZ_CONTRA
			        	AND CND_REVISA=CNZ_REVISA
			        	AND CND_NUMMED=CNZ_NUMMED
			        	AND CNZ_PERC > 0
			        	AND CNZ.%NotDel%
			     WHERE 	CND.%NotDel%
			        	AND CND.R_E_C_N_O_ = %Exp:nReg%
			EndSql
			While !(cAliasTmp)->( Eof() )
				If !Empty( (cAliasTmp)->CNZ_CC ) .And. aScan( aEntDist, { |a| a[1]+a[2] == (cAliasTmp)->CNZ_CC + "CTT" } ) == 0
					aAdd( aEntDist, { (cAliasTmp)->CNZ_CC	, "CTT" } )
				EndIf
				If !Empty( (cAliasTmp)->CNZ_CONTA ) .And. aScan( aEntDist, { |a| a[1]+a[2] == (cAliasTmp)->CNZ_CONTA + "CT1" } ) == 0
					aAdd( aEntDist, { (cAliasTmp)->CNZ_CONTA	, "CT1" } )
				EndIf
				If !Empty( (cAliasTmp)->CNZ_ITEMCT ) .And. aScan( aEntDist, { |a| a[1]+a[2] == (cAliasTmp)->CNZ_ITEMCT + "CTD" } ) == 0
					aAdd( aEntDist, { (cAliasTmp)->CNZ_ITEMCT, "CTD" } )
				EndIf
				If !Empty( (cAliasTmp)->CNZ_CLVL ) .And. aScan( aEntDist, { |a| a[1]+a[2] == (cAliasTmp)->CNZ_CLVL + "CTH" } )  == 0
					aAdd( aEntDist, { (cAliasTmp)->CNZ_CLVL	, "CTH" } )
				EndIf
				(cAliasTmp)->( DbSkip() )
			EndDo
			aEval(aEntDist, { |a| Iif( !ValidaBloq( a[1], dDataBase, a[2], !lAuto ), lContinua := .F., ) } )
		EndIf
	EndIf
EndIf

If lContinua
	//Chama rotina de encerramento por meio de processo
	Processa( {|| CN120MedEnc(nReg,,,,lAprRev) } )

	dbSelectArea("CNA")
	dbSetOrder(1)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica alerta de saldo das planilhas            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If dbSeek(xFilial("CNA",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA+CND->CND_NUMERO)
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Calcula percentual do saldo da planilha           ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cPrcSld := (CNA->CNA_SALDO*100)/CNA->CNA_VLTOT

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Seleciona tipo de planilha                        ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea("CNL")
		dbSetOrder(1)

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Verifica se a planilha alcancou o limite percentual³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If dbSeek(xFilial("CNL",cFilCTR)+CNA->CNA_TIPPLA) .And. cPrcSld <= CNL->CNL_LMTAVS
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Emite alerta de saldo do contrato ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			MEnviaMail("040",{CND->CND_NUMERO,CND->CND_CONTRA,CND->CND_REVISA,CNA->CNA_VLTOT,CNA->CNA_SALDO,CND->CND_FILIAL})
		EndIf
	EndIf
EndIf
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN120Estor³ Autor ³ Marcelo Custodio      ³ Data ³09.02.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Estorna medicao                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN120Estor(cExp01,nExp02,nExp03)                           ³±±
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
Function CN120Estor(cAlias,nReg,nOpc,lAprRev)
Local aSaveLines	:= FwSaveRows()
Local aArea			:= GetArea()
Local aAreaCND		:= CND->(GetArea())

Local aValidGet := {}
Local nPosNum
Local nPosPln
Local cChave    := ""
Local lCanEstor :=ExistBlock("CN120VLEST")
Local lContinua := .T.
Local dDataBloq	:= GetNewPar("MV_ATFBLQM",CTOD("")) //Data de Bloqueio da Movimentação - MV_ATFBLQM
Local lCN120MAb	:= ExistBlock("CN120MAB")

If Type('lAuto') == 'U'
	lAuto := .F.
EndIf

cFilCtr := CND->CND_FILCTR

lContinua := cn120vldMov(cFilCtr,CND->CND_CONTRA,CND->CND_REVISA)

If lContinua .And. !lCN120MAb .Or. (lCN120MAb .And. ExecBlock("CN120MAB",.F.,.F.) )
	//- Verifica se existe medição em aberto
	If !lCanEstor .And. Cn120MedAb(cFilCtr,CND->CND_CONTRA,CND->CND_REVISA,CND->CND_NUMERO)
		Help(" ",1,"CN120MEDAB") //P: Não é possivel realizar o estorno. Existem medições em aberto para este contrato S: Encerre ou exclua a medição em aberto antes de realizar o estorno.)
		lContinua := .F.
	EndIf
EndIf

//Verifica se existe bloqueio contábil
If lContinua .And. CtbValiDt(Nil, dDataBase,/*.T.*/ ,Nil ,Nil ,{"GCT001"}/*,"Data de apuração bloqueada pelo calendário contábil."*/)
	If!Empty(dDataBloq) .AND. ( dDataBase <= dDataBloq)
		//Help(" ",1,"AF012ABLQM",,"Processo bloqueado pelo Calendário Contábil nesta data ou período. Caso possível altere a data de referência do processo ou contate o responsável pelo Módulo Contábil.",1,0) //"Processo bloqueado pelo Calendário Contábil nesta data ou período. Caso possível altere a data de referência do processo ou contate o responsável pelo Módulo Contábil."
		Help(" ",1,"ATFCTBBLQ") //P: Processo bloqueado pelo Calendário Contábil ou parâmetro de bloqueio nesta data ou período. S: Caso possível altere a data de referência do processo, verifique o parâmetro ou contate o responsável pelo Módulo Contábil.)
		lContinua := .F.
	End
EndIf

If lContinua
	If !lAuto
		If !lAprRev
			If CND->CND_AUTFRN == "2"
				lContinua := (Aviso("CNTA120",OemtoAnsi(STR0063),{STR0022,STR0023}) == 1)//"Confirma encerramento da autorização de fornecimento?"
			Else
				lContinua := (Aviso("CNTA120",OemtoAnsi(STR0025),{STR0022,STR0023}) == 1)//"Confirma estorno da medição?"##"Sim"##"Não"
			EndIf
		Else
			lContinua := .T.
		EndIf
	Else
		//³Verifica se o numero da medicao foi fornecido      ³
		If (nPosNum:=aScan(aAutoCab,{|x| x[1]=="CND_NUMMED"})) > 0
			//³Valida numero da medicao                           ³
			AADD(aValidGet,{"cNumMed" ,aAutoCab[nPosNum,2],"CN120NumAuto(cNumMed,.F.)",.T.})
	
			If (lContinua := MsVldGAuto(aValidGet))
				//³Posiciona na medicao                               ³
				dbSelectArea("CND")
				If (nPosPln:=aScan(aAutoCab,{|x| x[1]=="CND_NUMERO"})) > 0
					CND->(dbSetOrder(1))
					CND->(dbSeek( xFilial("CND")							+ ;
					aAutoCab[aScan(aAutoCab,{|x| x[1]=="CND_CONTRA"}),2]	+ ;
					aAutoCab[aScan(aAutoCab,{|x| x[1]=="CND_REVISA"}),2]	+ ;
					aAutoCab[nPosPln,2]										+ ;
					aAutoCab[nPosNum,2]))
				Else
					CND->(dbSetOrder(4))
					CND->(dbSeek(xFilial("CND")+aAutoCab[nPosNum,2]))
				Endif
				nReg := CND->(Recno())
			EndIf
		Else
			lContinua:=.F.
		EndIf
	EndIf
EndIf

//³Ponto de entrada permite estornar a medição ou não.³
If lContinua .And. lCanEstor
	lContinua:=ExecBlock("CN120VLEST",.F.,.F.)
	If ValType(lContinua) <> "L"
		lContinua:=.T.
	EndIf
EndIf

If lContinua
	cChave := CND->CND_CONTRA+CND->CND_REVISA+CND->CND_NUMERO+CND->CND_NUMMED
	If LockByName("CN120"+xFilial("CND")+cChave,.T.,!Empty(xFilial("CND")),.T.)
		//Chama rotina de estorno por meio de processo
		Processa( {|| CN120MedEst(nReg,,,,,lAprRev) } )
		UnLockByName("CN120"+xFilial("CND")+cChave,.T.,!Empty(xFilial("CND")),.T.)
	Else
		// Nao permite processamento concorrente
		Aviso(STR0068,OemtoAnsi(STR0069),{STR0155},2) // ##"Concorrência"##"Esta Medição está em uso por outra estação."
	EndIf
EndIf

RestArea(aAreaCND)
RestArea(aArea)
FWRestRows( aSaveLines )
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN120GrvPed³ Autor ³ Marcelo Custodio      ³ Data ³09.02.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Gera pedido de compra por rotina automatica                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN120GrvPed(cExp01,cExp02)                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ cExp01 - Numero da medicao                                  ³±±
±±³          ³ cExp02 - Codigo da nova revisao,usado na aprovacao CNTA150  ³±±
±±³          ³          pois o CND traz o codigo da revisao original       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³         ATUALIZACOES SOFRIDAS DESDE A CONSTRU€AO INICIAL.              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Programador ³ Data   ³ BOPS ³  Motivo da Alteracao                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³            ³        ³      ³                                           ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function CN120GrvPeD(cNumMed,cNRevisa,cNumPed,nTaxa,cContra,cTes,lExcede,cNumTit)

Local aRet			:= {}
Local aCab			:= {}
Local aItem		:= {}
Local aArea		:= GetArea()
Local aVend		:= {}//Array de vendedores
Local aStrCNE		:= CNE->(dbStruct())
Local aCN120ITM	:= {}
Local aCTBEnt	  	:= CTBEntArr()
Local aRatGCT		:= {}
Local aRatPedGCT	:= {}
Local aPedCom		:= {}
Local aPedCXJ		:= {}

Local cFilCod		:= xFilial("CNE")
Local cFilCNB		:= If (IsInCallStack('CN300REVPD'),xFilial("CNB"),xFilial("CNB",cFilCTR))
Local cQuery		:= ""
Local cAliasQry	:= ""
Local cAliasCNR	:= ""
Local cAliasCNQ	:= ""
Local cAliasCND	:= ""
Local cEspCtr		:= "" //Tipo do contrato
Local cNumSC5		:= ""
Local cNumSC7		:= ""
Local cItemSC6	:= ""
Local cVend		:= "1"
Local cParcela	:= "123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0"
Local cC7Item		:= ""
Local cAlc			:= "N"
Local cTipoFrete	:= ""

Local nVlrTitulo	:= 0
Local nAcres		:= 0
Local nDecres		:= 0
Local nDescTit		:= 0
Local nCaucTit		:= 0
Local nMultTit		:= 0
Local nBoniTit		:= 0
Local nTpDoc		:= CN120VerDoc(cNumMed) //Verifica quais documentos foram gerados Pedidos/Titulos
Local nDesc		:= 0
Local nDecrUn		:= 0
Local nDecrUnBon	:= 0
Local nDecrUnMul	:= 0
Local nDecrUnCau	:= 0
Local nDecrUnDes	:= 0
Local nX			:= 0
Local nY			:= 0
Local nZ			:= 0
Local nRateio		:= 0
Local nRatBoni	:= 0
Local nRatMult	:= 0
Local nRatCauc		:= 0
Local nRatDesc		:= 0
Local nPosCpo		:= 0
Local nPosTotCpo	:= 0
Local nPosUniCpo	:= 0
Local nPosVenCpo	:= 0
Local nTotMedic	:= 0
Local nQuantArred	:= 0
Local nPrecoArred	:= 0
Local nValorArred	:= 0
Local nValTot		:= 0
Local nAuxTot		:= 0
Local nValUni		:= 0
Local nValQuant	:= 0
Local nDifValor	:= 0
Local nMult		:= 0
Local nBoni		:= 0
Local nCauc		:= 0
Local nAdia		:= 0
Local nDescMed	:= 0
Local nParcelas	:= SuperGetMv("MV_NUMPARC")
Local nPosItemed	:= 0
Local nVlItDesc	:= 0
Local nPDesconto	:= 0
Local nPDespesa	:= 0
Local nSaveSX8	:= If(Type('nSaveSx8')=='U', GetSX8Len(), nSaveSX8)
Local nGCTDPcAl	:= GetNewPar("MV_CNDPCAL",2)
Local lCnnoped := SuperGetMV("MV_CNNOPED",.F.,.T.)

Local lDesc
Local lRet			:= .T.
Local lGCTRet1	:= (GetNewPar( "MV_CNRETNF", "N" ) == "S")
Local lGCTRet2	:= (GetNewPar( "MV_CNRETNF", "N" ) == "S")
Local lGCTAdia	:= GetNewPar("MV_CNADIA","N") == "S"
Local lGCTMdAlc	:= (GetNewPar("MV_CNMDALC","N") == "S")
Local lCN120ITM	:= ExistBlock("CN120ITM")
Local cCodEdt		:= ""
Local cNumPro		:= ""
Local lLog  		:= GetNewPar("MV_HABLOG",.F.)
Local cPlan			:= ""
Local lCTA120FN	:= ExistBlock("CTA120FN")
Local lCTA120FV	:= ExistBlock("CTA120FV")
Local lCN120IT7	:= ExistBlock("CN120IT7")
Local lCN120PED	:= ExistBlock("CN120PED")
Local lCN120AEP	:= ExistBlock("CN120AEP")
Local lCN120PDM	:= ExistBlock("CN120PDM")
Local lCN120GSC	:= ExistBlock("CN120GSC")
Local lCN120ADP	:= ExistBlock("CN120ADP")
Local lCN120GPM	:= ExistBlock("CN120GPM")
Local cMdcron  	:= ""
Local cMdparce 	:= ""

Local cTipoMulta:= SuperGetMV("MV_MULTMED",.F.,"2") //1=Valor Unitario, 2=Despesa
Local cTpRatMult:= SuperGetMV("MV_CNRATE",.F., "1") //Rateio da Multa(apenas qnd cTipoMulta=1)
Local nValCheio:= 0
Local nPrecoCalc:= 0
Local nValorOri	:= 0
Local nDifDesc	:= 0
Local nTotDesc	:= 0
Local nPosDesc	:= 0

Default cNRevisa	:= ""
Default cContra	:= ""
Default cNumMed	:= ""
Default cTes		:= ""
Default cNumTit	:= ""
Default cNumPed	:= ""
Default lExcede	:= .F.

Private cXFil 	:= "" // Para ser utilizado no ponto de entrada antes de apos o processamento da exclusão do pedido de compra - FSW

lMsErroAuto := Iif(Type("lMsErroAuto")=='L',lMsErroAuto,.F.)
cFilCTR 	:= CND->CND_FILCTR
cFilCNB		:= If (IsInCallStack('CN300REVPD'),xFilial("CNB"),xFilial("CNB",cFilCTR))

If Type("lAuto") == "L"
	If lAuto .And. (nPosCpo := aScan(aAutoCab,{|x| AllTrim(x[1]) == "NUMPED"})) > 0
		cNumPed := aAutoCab[nPosCpo,2]
	EndIf
EndIf

Pergunte("CNT120",.F.)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Filtra da medicao do contrato      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
cQuery := "SELECT CND.R_E_C_N_O_ as CNDRECNO "
cQuery += "  FROM "+ RetSQLName("CND") +" CND "
cQuery += " WHERE CND.CND_FILIAL = '"+ xFilial("CND") +"'"
cQuery += "   AND CND.CND_CONTRA = '" + cContra + "'"
cQuery += "   AND CND.CND_REVISA = '" + cNRevisa+ "'"
cQuery += "   AND CND.CND_NUMMED = '" + cNumMed + "'"
cQuery += "   AND CND.D_E_L_E_T_ <> '*'"

cQuery    := ChangeQuery(cQuery)
cAliasCND := GetNextAlias()

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasCND,.F.,.F.)

While !(cAliasCND)->(Eof())
	nVlrTitulo := 0 //-- Inicializa variavel de soma de titulos a serem gerados

	CND->(MsGoto((cAliasCND)->CNDRECNO))
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Identifica o uso de controle de alçada no PC     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If nGCTDPcAl == 1
		cAlc := "N" //Ativa o uso do controle de alçada.
	ElseIf	nGCTDPcAl == 2
		cAlc :=  "S" //Desativa o uso do controle de alçada.
    ElseIf nGCTDPcAl == 3
		cAlc := IIf( lGCTMdAlc .And. !Empty(CND->CND_APROV),"S","N") //Se medição possuir alçada, desativa.
	EndIf

	//Inicializa váriavel cFilCTR
	cFilCTR := CND->CND_FILCTR

	CN9->(dbSetOrder(1))
	CN9->(dbSeek(xFilial("CN9",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA))

	cCodEdt:=CN9->CN9_CODED
	cNumPro:=CN9->CN9_NUMPR

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica especie do contrato             ³
	//³ 1 - Compra                               ³
	//³ 2 - Venda                                ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cEspCtr 	:= CN9->CN9_ESPCTR
	// Apura o valor total da medicao sem considerar descontos
	cAliasQry := GetNextAlias()

	cQuery := "SELECT SUM(CNE_VLTOT) VLTOT, SUM(CNE_VLDESC) VLDESC "
	cQuery += "  FROM " + RetSqlName( "CNE" )
	cQuery += " WHERE CNE_FILIAL = '" + xFilial( "CNE" ) + "'"
	cQuery += "   AND CNE_CONTRA = '" + cContra + "'"
	cQuery += "   AND CNE_REVISA = '" + cNRevisa+ "'"
	cQuery += "   AND CNE_NUMMED = '" + cNumMed + "'"
	cQuery += "   AND D_E_L_E_T_ = ' '"
	If lExcede
		cQuery += "   AND CNE_EXCEDE = '1' AND CNE_PEDIDO = ' '"
	EndIf

	cQuery := ChangeQuery( cQuery )
	dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQuery ), cAliasQry, .F., .T. )

	nTotMedic   := ( cAliasQry )->VLTOT
	( cAliasQry )->( dbCloseArea() )

	dbSelectArea( "CNE" )

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica se o recurso de multa / bonificacao esta disponivel para a medicao ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !lExcede

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Obtem o valor de multa e/ou bonificacao da medicao ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea("CNR")
		cAliasCNR := GetNextAlias()

		cQuery := "SELECT CNR.CNR_VALOR  AS VALOR, CNR.CNR_TIPO "
		cQuery += "  ,CNR.CNR_CONTRA "
		cQuery += "  FROM " + RetSqlName("CNR" ) + " CNR "
		cQuery += " WHERE CNR.CNR_FILIAL = '"+xFilial("CNR")+"'"
		cQuery += "   AND CNR.CNR_NUMMED = '" + cNumMed + "'"
		If nTpDoc <> 2 //Caso a medição não gere pedido, as multas e bonificações deverão ser contabilizadas no título
		   cQuery += "   AND CNR.CNR_FLGPED = '1'"
		EndIf
		cQuery += "   AND CNR.D_E_L_E_T_ = ' '"

		cQuery := ChangeQuery( cQuery )
		dbUseArea( .T., "TOPCONN", TcGenQry( ,, cQuery ), cAliasCNR, .F., .T. )

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Acerta o campo numerico                  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		TcSetField( cAliasCNR, "VALOR", "N", 18, 2 )

		While !( cAliasCNR )->( Eof() )
			If !Empty(( cAliasCNR )->CNR_CONTRA) .And. (( cAliasCNR )->CNR_CONTRA) <> CND->CND_CONTRA
				( cAliasCNR )->( dbSkip() )
				Loop
			EndIf

			If ( cAliasCNR )->CNR_TIPO == "1"
				nMult += ( cAliasCNR )->VALOR
			ElseIf ( cAliasCNR )->CNR_TIPO == "2"
				nBoni += ( cAliasCNR )->VALOR
			EndIf
			( cAliasCNR )->( dbSkip() )
		EndDo

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Fecha a area de trabalho                 ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		( cAliasCNR )->( dbCloseArea() )
		dbSelectArea( "CNR" )

	EndIf

	If !lExcede .And. CND->CND_DESCME > 0
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Obtem o valor dos descontos de contrato ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea("CNQ")

		cAliasCNQ := GetNextAlias()

		cQuery := "SELECT SUM( CNQ.CNQ_VALOR ) AS VALOR "
		cQuery += "  FROM " + RetSqlName("CNQ" ) + " CNQ, "+ RetSQLName("CNP") +" CNP "
		cQuery += " WHERE CNQ.CNQ_FILIAL = '"+ xFilial("CNQ") +"'"
		cQuery += "   AND CNP.CNP_FILIAL = '"+ xFilial("CNP",cFilCTR) +"'"
		cQuery += "   AND CNQ.CNQ_TPDESC = CNP.CNP_CODIGO "
		cQuery += "   AND CNQ.CNQ_NUMMED = '" + cNumMed + "'"
		If nTpDoc <> 2 //Caso a medição não gere pedido, os descontos deverão ser contabilizados no título
		   cQuery += "   AND CNP.CNP_FLGPED = '1'"
		EndIf
		cQuery += "   AND CNQ.D_E_L_E_T_ = ' '"
		cQuery += "   AND CNP.D_E_L_E_T_ = ' '"

		cQuery := ChangeQuery( cQuery )
		dbUseArea( .T., "TOPCONN", TcGenQry( ,, cQuery ), cAliasCNQ, .F., .T. )

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Acerta o campo numerico                  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		TcSetField( cAliasCNQ, "VALOR", "N", 18, 2 )

		nDescMed := If((!( cAliasCNQ )->(Eof())),( cAliasCNQ )->VALOR,0)

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Fecha a area de trabalho                 ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		( cAliasCNQ )->( dbCloseArea() )
		dbSelectArea( "CNQ" )
	EndIf

	dbSelectArea("CN9")
	dbSetOrder(1)
	dbSeek(xFilial("CN9",cFilCTR)+cContra+cNRevisa)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Filtra itens da medicao e da planilha           ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	cQuery := "SELECT DISTINCT  CNE.R_E_C_N_O_ as RECNO "
	cQuery += "  FROM "+ RetSQLName("CNE") +" CNE "
	cQuery += " WHERE CNE.CNE_FILIAL = '"+ xFilial("CNE") +"'"
	cQuery += "   AND CNE_CONTRA     = '" + cContra + "'"
	cQuery += "   AND CNE_REVISA     = '" + cNRevisa+ "'"
	cQuery += "   AND CNE.CNE_NUMMED = '"+ CND->CND_NUMMED +"'"
	cQuery += "   AND CNE.D_E_L_E_T_ <> '*'"
	If lExcede
		cQuery += "   AND CNE.CNE_EXCEDE = '1' AND CNE.CNE_PEDIDO = '"+Space(TamSX3("CNE_PEDIDO")[1])+" '"
	EndIf

	cQuery    := ChangeQuery(cQuery)
	cAliasCNE := GetNextAlias()

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasCNE,.F.,.F.)

	For nx:=1 to len(aStrCNE)
		if (cAliasCNE)->(FieldPos(aStrCNE[nx,1])) > 0 .And. aStrCNE[nx,2] <> "C"
			TCSetField( cAliasCNE, aStrCNE[nx,1], aStrCNE[nx,2], aStrCNE[nx,3], aStrCNE[nx,4] )
		endif
	Next
	// Gera PC/PV somente quando cNumPed e cNumTit vazio,
	// pois caso esteja preenchido significa que
	// o mesmo ja foi gerado.
	If Empty(cNumPed) .And. Empty(cNumTit)
		If !lExcede
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Obtem o valor de retencao de caucao     ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			nCauc := If(!(If((cEspCtr=="1"),lGCTRet2,lGCTRet1)),CND->CND_RETCAC,0)

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Obtem o valor dos adiantamentos         ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			nAdia := If(lGCTAdia,CND->CND_TOTADT,0)

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Soma descontos, multas, bonificacoes, caucoes retidas e adiantamentos        ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			nDesc := nDescMed + nCauc + nAdia
			nRateio := ( nDesc *100 ) / nTotMedic
			nRatMult:= (nMult * 100 ) / nTotMedic
			nRatBoni:= (nBoni * 100 ) / nTotMedic
			nRatCauc:= ( nCauc * 100 ) / nTotMedic
			nRatDesc:= ( nDescMed * 100 ) / nTotMedic
			lDesc   := !Empty( nDesc )
		EndIf
		
		cMdcron  := ""
		cMdparce := ""
			
		dbSelectArea("CNA")
		CNA->(dbSetOrder(1))
		If	CNA->(MsSeek(xFilial("CNA",cFilCTR)+CND->(CND_CONTRA+CND_REVISA+CND_NUMERO)))
			dbSelectArea("CNF")
			CNF->(dbSetOrder(3))
			If	CNF->(MsSeek(xFilial("CNF",cFilCTR) + CND->CND_CONTRA + CND->CND_REVISA + CNA->CNA_CRONOG + CND->CND_PARCEL))
				cMdcron		:= CNF_NUMERO
				cMdparce	:= CNF_PARCEL
			EndIf
		EndIf		
	
		//Contrato de compra
		If cEspCtr=="1"
			If nTpDoc # 2  //-- Se gera pedido monta cabeçalho
				If lCTA120FN
					 ExecBlock("CTA120FN",.F.,.F.)
				EndIf
				cNumSC7  := Criavar("C7_NUM",.T.)//Gera numero do pedido de compra
				While ( GetSX8Len() > nSaveSX8 )
					ConFirmSX8()
				EndDo
				If lCTA120FV
					 ExecBlock("CTA120FV",.F.,.F.)
				EndIf
				//Efetua montagem do aCab usado para geração de pedido de compra
				aCab:={	{"C7_NUM"		,	cNumSC7				  		,NIL},; // Numero do Pedido
							{"C7_EMISSAO"	,	dDataBase						,NIL},; // Data de Emissao
							{"C7_FORNECE"	,	CND->CND_FORNEC				,NIL},; // Fornecedor
							{"C7_LOJA"		,	CND->CND_LJFORN				,NIL},; // Loja do Fornecedor
							{"C7_CONTATO"	,	CriaVar("C7_CONTATO"	,.F.)	,NIL},; // Contato
							{"C7_COND"		,	CND->CND_CONDPG				,NIL},; // Condicao de Pagamento
							{"C7_FILENT"	,	CriaVar("C7_FILENT",.F.)		,NIL},; // Filial de Entrega
							{"C7_FRETE"	,	CriaVar("C7_FRETE",.F.)		,NIL},; // Frete
							{"C7_SEGURO"	,	CriaVar("C7_SEGURO",.F.)		,NIL},; // Seguro
							{"C7_MSG"		,	CriaVar("C7_MSG",.F.)		,NIL},; // Mensagem
							{"C7_REAJUST"	,	CriaVar("C7_REAJUST",.F.)	,NIL},; // Reajuste
							{"ALCADA"		,	cAlc							,NIL},; // Alcada
							{"MED_GCT"		,	"GCT"							,NIL},; // Reajuste
							{"C7_MOEDA"	,	CND->CND_MOEDA				,NIL}}  // Moeda
				If CN9->CN9_MOEDA == 1
					aAdd(aCab,{"C7_TXMOEDA",If(CND->CND_MOEDA!=1,xMoeda(1,CND->CND_MOEDA,1,dDataBase,TamSx3("C7_TXMOEDA")[2],,nTaxa),1),NIL}) // Taxa de Conversao
				Else
					aAdd(aCab,{"C7_TXMOEDA",If(CND->CND_MOEDA!=1,xMoeda(1,CND->CND_MOEDA,1,dDataBase,TamSx3("C7_TXMOEDA")[2],nTaxa),1),NIL}) // Taxa de Conversao
				EndIf
				
				If cPaisLoc = 'RUS'
				   aAdd(aCab,{"C7_CONUNI",CND->CND_CONUNI,NIL}) // Conventional unit
				EndIf
				
			EndIf
			
			If nTpDoc # 1 //-- Se gera titulo, prepara array pra ExecAuto
			
				aTitulo :={		{"E2_FILORIG"	,	CND->CND_FILIAL  			,NIL},; // Filial de Origem
								{"E2_FORNECE"	,	CND->CND_FORNEC  			,NIL},; // Fornecedor
								{"E2_LOJA"		,	CND->CND_LJFORN				,NIL},; // Loja do Fornecedor
								{"E2_ORIGEM"	,	"CNTA120"					,NIL},; // Origem
								{"E2_EMISSAO"	,	dDataBase					,NIL},; // Emissão
								{"E2_VENCTO" 	,	IIf (CND->CND_DTVENC > dDataBase,	DataValida( CND->CND_DTVENC ), dDataBase),NIL},; // Vencimento
								{"E2_VENCREA"	,	IIf (CND->CND_DTVENC > dDataBase,	DataValida( CND->CND_DTVENC ), dDataBase),NIL},; // Vencimento Real
								{"E2_VENCORI"	,	IIf (CND->CND_DTVENC > dDataBase,	DataValida( CND->CND_DTVENC ), dDataBase),NIL},; // Vencimento Origem
								{"E2_MOEDA"  	,	CND->CND_MOEDA				,NIL},; // Moeda
								{"E2_MDCONTR"	,	CND->CND_CONTRA				,NIL},; // Numero do Contrato
								{"E2_MDREVIS"	,	CND->CND_REVISA				,NIL},; // Revisão do Contrato
								{"E2_MEDNUME"	,	CND->CND_NUMMED				,NIL},; // Numero da Medição
								{"E2_MDPLANI"	,	CND->CND_NUMERO				,NIL},; // Numero da planilha
								{"E2_MDCRON"	,	cMdcron						,NIL},;	// Numero do Cronograma
								{"E2_MDPARCE"	,	cMdparce					,NIL}}	// Numero da Parcela
			EndIf
		Else
			If nTpDoc # 2 //-- Se gera pedido monta cabeçalho
				aVend := CtaVend(CND->CND_CONTRA, cFilCTR) //Carrega vendedores do contrato

				aCab:={			{"C5_TIPO"   	,	"N"				,Nil},; 	// Tipo de pedido
							{"C5_CLIENTE"	,	CND->CND_CLIENT	,Nil},; 	// Codigo do cliente
							{"C5_LOJAENT"	,	CND->CND_LOJACL	,Nil},; 	// Loja para entrada
							{"C5_LOJACLI"	,	CND->CND_LOJACL	,Nil},; 	// Loja do cliente
							{"C5_EMISSAO"	,	dDatabase		,Nil},; 	// Data de emissao
							{"C5_CONDPAG"	,	CND->CND_CONDPG	,Nil},; 	// Codigo da condicao de pagamanto*
							{"C5_MOEDA"  	,	CND->CND_MOEDA	,Nil},; 	// Moeda
							{"C5_MDCONTR"	,	CND->CND_CONTRA	,Nil},;		// Cod. do Contrato
							{"C5_MDNUMED"	,	CND->CND_NUMMED	,Nil},;		// Codigo da Medicao
							{"C5_MDPLANI"	,	CND->CND_NUMERO	,Nil},;		// Numero da Planilha
							{"C5_NATUREZ"	,	CN9->CN9_NATURE ,Nil}} 		// Natureza do Contrato

				cTipoFrete := Posicione("TFJ",5,xFilial("TFJ")+CN9->CN9_NUMERO+CN9->CN9_REVISA,"TFJ_TPFRET")

				If !Empty(cTipoFrete)
					cTipoFrete := Iif(TFJ->TFJ_TPFRET=="1","C","F")
					aAdd( aCab , { "C5_TPFRETE" , cTipoFrete , Nil } )
				Endif

				If CN9->CN9_MOEDA == 1
					aAdd(aCab,{"C5_TXMOEDA",If(CND->CND_MOEDA!=1,xMoeda(1,CND->CND_MOEDA,1,dDataBase,TamSx3("C5_TXMOEDA")[2],,nTaxa),1),NIL}) // Taxa de Conversao
				Else
					aAdd(aCab,{"C5_TXMOEDA",If(CND->CND_MOEDA!=1,xMoeda(1,CND->CND_MOEDA,1,dDataBase,TamSx3("C5_TXMOEDA")[2],nTaxa),1),NIL}) // Taxa de Conversao
				EndIf
				
				If cPaisLoc = 'RUS'
				   aAdd(aCab,{"C5_CONUNI",CND->CND_CONUNI,NIL}) // Conventional unit
				   aAdd(aCab,{"C5_TIPO","N",NIL}) // Order type
				EndIf
				
				cVend := "1"
				For nx:=1 to Len(aVend) //Preenche os vendedores de acordo com o contrato
					aAdd(aCab,{"C5_VEND"+cVend,aVend[nx,1],NIL})
					aAdd(aCab,{"C5_COMIS"+cVend,aVend[nx,2],NIL})
					cVend:=Soma1(cVend)
				Next
				dbSelectArea("SE4")
				dbSetOrder(1)
				MsSeek(xFilial("SE4")+CND->CND_CONDPG)
				If SE4->E4_TIPO=='9' //Preenche as Parcelas e Vencimentos  se condição de pagamento for do tipo 9
					For nX:=1 to nParcelas
						aAdd(aCab,{"C5_PARC"+Substr(cParcela,nx,1),&("CND->CND_PARC"+Substr(cParcela,nx,1)),NIL})
						aAdd(aCab,{"C5_DATA"+Substr(cParcela,nx,1),&("CND->CND_DATA"+Substr(cParcela,nx,1)),NIL})
					Next nX
				EndIf
			EndIf
			If nTpDoc # 1 //-- Se gera titulo prepara array para ExecAuto
			
				aTitulo :={	{"E1_CLIENTE"	,	CND->CND_CLIENT  				,NIL},; // Cliente
								{"E1_LOJA"		,	CND->CND_LOJACL				,NIL},; // Loja do Cliente
								{"E1_ORIGEM"	,	"CNTA120"					,NIL},; // Origem
								{"E1_EMISSAO"	,	dDataBase					,NIL},; // Emissão
								{"E1_VENCTO" 	,	IIf (CND->CND_DTVENC > dDataBase,	DataValida( CND->CND_DTVENC ), dDataBase),NIL},; // Vencimento
								{"E1_VENCREA"	,	IIf (CND->CND_DTVENC > dDataBase,	DataValida( CND->CND_DTVENC ), dDataBase),NIL},; // Vencimento Real
								{"E1_VENCORI"	,	IIf (CND->CND_DTVENC > dDataBase,	DataValida( CND->CND_DTVENC ), dDataBase),NIL},; // Vencimento Origem
								{"E1_MOEDA"  	,	CND->CND_MOEDA				,NIL},; // Moeda
								{"E1_MDCONTR"	,	CND->CND_CONTRA				,NIL},; // Numero do Contrato
								{"E1_MDREVIS"	,	CND->CND_REVISA				,NIL},; // Revisão do Contrato
								{"E1_MEDNUME"	,	CND->CND_NUMMED				,NIL},; // Numero da Medição
								{"E1_MDPLANI"	,	CND->CND_NUMERO				,NIL},;  // Numero da planilha
								{"E1_MDCRON"	,	cMdcron						,NIL},;	// Numero do Cronograma
								{"E1_MDPARCE"	,	cMdparce					,NIL}}	// Numero da Parcela
								
			EndIf
		EndIf
		nDifPreco := 0
		nDifValor := 0

		CN9->(dbSetOrder(1))
		CN9->(dbSeek(xFilial("CN9",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA))

		While !(cAliasCNE)->(Eof()) //Itens da Medição
			CNE->(MsGoTo((cAliasCNE)->RECNO))
			cPlan	:= CNE->CNE_NUMERO
			dbSelectArea("SB1")
			SB1->(dbSetOrder(1))
			//Regras de aplicação de multa, desconto e bonificação
			//Contratos de Compra:
			//Multas		(Desconto)
			//Bonificação	(Acréscimo)
			//Desconto		(Desconto)
			//Adiantamento	(Desconto)

			//Contratos de Venda:
			//Multas		(Acréscimo)
			//Bonificação	(Desconto)
			//Desconto		(Desconto)
			//Adiantamento	(Desconto)
			If SB1->(MSSeek(xFilial("SB1")+CNE->CNE_PRODUT))
				If CNE->CNE_VLTOT > 0
					
					nDecrUn     := (CNE->CNE_VLUNIT * nRateio)/100
					nDecrUnBon  := ((CNE->CNE_VLUNIT * nRatBoni)/100)
					nDecrUnMul  := ((CNE->CNE_VLUNIT * nRatMult)/100)
					nDecrUnCau  := ((CNE->CNE_VLUNIT * nRatCauc)/100)
					nDecrUnDes  := ((CNE->CNE_VLUNIT * nRatDesc)/100)					
					
					If(cTipoMulta == "1")//Valor Unitario
						nValCheio := CNE->CNE_VLUNIT * CNE->CNE_QUANT
						//Tipo de rateio dos descontos da medicao.
						If cTpRatMult == "1" //1	= Subtrai do valor unitario.
							nQuantArred := A410Arred( CNE->CNE_QUANT, If(cEspCtr=="1","C7_QUANT","C6_QTDVEN") )
							If(cEspCtr=="1")
								nPrecoCalc  := CNE->CNE_VLUNIT - nDecrUn + nDecrUnBon - nDecrUnMul
							Else
								nPrecoCalc  := CNE->CNE_VLUNIT  - nDecrUn - nDecrUnBon + nDecrUnMul
							EndIf
	
							nPrecoArred := A410Arred( nPrecoCalc, If(cEspCtr=="1","C7_PRECO","C6_PRCVEN") )
	
							nValorOri   := If( Empty(nDecrUn) .And. Empty(nDecrUnBon) .And. Empty(nDecrUnMul) , CNE->CNE_VLTOT , nPrecoCalc * CNE->CNE_QUANT )
							nValorArred := A410Arred( nPrecoArred * nQuantArred,  If(cEspCtr=="1","C7_TOTAL","C6_VALOR") )
							nDifValor   += ( nValorArred - nValorOri )
	
							nVlItDesc   := A410Arred(CNE->CNE_VLDESC,  If(cEspCtr=="1","C7_TOTAL","C6_VALOR"))
						Else //2	= Soma no valor de descontos do item.
							nQuantArred := A410Arred( CNE->CNE_QUANT, If(cEspCtr=="1","C7_QUANT","C6_QTDVEN") )
							If(cEspCtr=="1")
								nPrecoCalc  := CNE->CNE_VLUNIT + nDecrUnBon - nDecrUnMul
							Else
								nPrecoCalc  := CNE->CNE_VLUNIT - nDecrUnBon + nDecrUnMul
							EndIf
	
							If lExcede
								nPrecoArred := A410Arred(CNE->CNE_VLUNIT, If(cEspCtr=="1","C7_PRECO","C6_PRCVEN") )
								nValorOri   := CNE->CNE_VLUNIT * CNE->CNE_QUANT
							Else
								nPrecoArred := A410Arred( nPrecoCalc, If(cEspCtr=="1","C7_PRECO","C6_PRCVEN") )
								nValorOri   := If( Empty(nDecrUnBon) .And. Empty(nDecrUnMul) , CNE->CNE_VLTOT , nPrecoCalc * CNE->CNE_QUANT )
							EndIf
	
							nValorArred := A410Arred( nPrecoArred * nQuantArred,  If(cEspCtr=="1","C7_TOTAL","C6_VALOR") )
							nDifValor   += (nValorArred - nValorOri)
	
							nVlItDesc   := A410Arred(CNE->CNE_VLDESC+(nDecrUn*CNE->CNE_QUANT),  If(cEspCtr=="1","C7_TOTAL","C6_VALOR"))
							nDifDesc	+= CNE->CNE_VLDESC+(nDecrUn*CNE->CNE_QUANT) - nVlItDesc
	
							If ABS(nDifDesc) >= 1/10^(TAMSX3(If(cEspCtr=="1","C7_TOTAL","C6_VALOR"))[2])
								nVlItDesc += A410Arred(nDifDesc,If(cEspCtr=="1","C7_TOTAL","C6_VALOR"))
								nDifDesc  -= A410Arred(nDifDesc,If(cEspCtr=="1","C7_TOTAL","C6_VALOR"))
						    EndIf
						EndIf
					
					Else //Despesa
						nQuantArred := A410Arred( CNE->CNE_QUANT, If(cEspCtr=="1","C7_QUANT","C6_QTDVEN") )
						nPrecoArred := A410Arred( CNE->CNE_VLUNIT , If(cEspCtr=="1","C7_PRECO","C6_PRCVEN") )
						nValorArred := A410Arred( nPrecoArred * nQuantArred,  If(cEspCtr=="1","C7_TOTAL","C6_VALOR") )
						nDifValor   += ( nValorArred - CNE->CNE_VLTOT )
						nVlItDesc   := A410Arred(CNE->CNE_VLDESC,  If(cEspCtr=="1","C7_VLDESC","C6_VALDESC"))
						
						If CNE->CNE_PEDTIT == "1" 	
							If(cEspCtr=="1")
								nPDesconto	+= CNE->CNE_QUANT * ( nDecrUn + nDecrUnMul )
								nPDespesa	+= CNE->CNE_QUANT * nDecrUnBon
							Else
								nPDesconto	+= CNE->CNE_QUANT * ( nDecrUn + nDecrUnBon )
								nPDespesa	+= CNE->CNE_QUANT * nDecrUnMul
							EndIf
						EndIf						
					EndIf					
					
					CNB->(dbSetOrder(1)) //Posiciona CNB para leitura de campos
					CNB->(dbSeek(cFilCNB+CNE->(CNE_CONTRA+CNE_REVISA+CNE_NUMERO+CNE_ITEM)))

					If cEspCtr=="1" .And. ( (cTipoMulta != "1") .Or. (cTipoMulta == "1" .And. nVlItDesc < nValCheio .and. nVlItDesc < nValorArred) )// --- COMPRA
						If CNE->CNE_PEDTIT == "1" //Se o item está marcado para gerar pedido
							aAdd(aItem,{}) //Gera item do pedido de compra

							cC7Item := If(Empty(cC7Item),strZero(1,TamSX3("C7_ITEM")[1]),Soma1(cC7Item))//Atualiza sequencia do item

							aAdd(aTail(aItem)	,{"C7_ITEM"		,cC7Item												,NIL})	//Item
							aAdd(aTail(aItem)	,{"C7_PRODUTO"	,CNE->CNE_PRODUT										,NIL}) //Produto

							If (xFilial("SC1")<> CNB->CNB_FILORI)
								aAdd(aTail(aItem),{"C7_FISCORI",xFilial("SC1"),NIL}) 			//Filial de origem da SC
							Else
								aAdd(aTail(aItem),{"C7_FISCORI",CNB->CNB_FILORI,NIL}) 			//Filial de origem da SC
							EndIf

							If !Empty(CNB->CNB_NUMSC)
								aAdd(aTail(aItem)	,{"C7_NUMSC"		,CNB->CNB_NUMSC					,NIL}) //Solicitacao
								aAdd(aTail(aItem)	,{"C7_ITEMSC"		,CNB->CNB_ITEMSC				,NIL})	//Item solicitacao
							EndIf
							If !Empty(CNB->CNB_DESCRI)
								aAdd(aTail(aItem)	,{"C7_DESCRI"		,CNB->CNB_DESCRI				,NIL}) //Descricao
							Else
								aAdd(aTail(aItem)	,{"C7_DESCRI"		,SB1->B1_DESC					,NIL}) //Descricao
							EndIf
							aAdd(aTail(aItem)	,{"C7_QUANT"	,nQuantArred							,NIL}) //Quantidade
							aAdd(aTail(aItem)	,{"C7_QTDSOL"	,nQuantArred							,NIL})	//Quantidade solicitada
							aAdd(aTail(aItem)	,{"C7_UM"		,SB1->B1_UM								,NIL}) //Unidade de Medida
							aAdd(aTail(aItem)	,{"C7_QTSEGUM"	,ConvUm(SB1->B1_COD,nQuantArred,0,2)	,NIL})	//Segunda unidade de medida
							aAdd(aTail(aItem)	,{"C7_PRECO"	,nPrecoArred							,NIL}) //Preco unitario
							aAdd(aTail(aItem)	,{"C7_TOTAL"	,nValorArred							,NIL}) //Valor total
							aAdd(aTail(aItem)	,{"C7_IPI"		,SB1->B1_IPI							,NIL}) //IPI
							aAdd(aTail(aItem)	,{"C7_REAJUST"	,CriaVar("C7_REAJUST",.F.)				,NIL})	//Reajuste
							aAdd(aTail(aItem)	,{"C7_FRETE"	,CriaVar("C7_FRETE",.F.)				,NIL}) //Frete
							aAdd(aTail(aItem)	,{"C7_DATPRF"	,CNE->CNE_DTENT							,NIL}) //Data de entrega
							aAdd(aTail(aItem)	,{"C7_LOCAL"	,SB1->B1_LOCPAD							,NIL}) //Local
							aAdd(aTail(aItem)	,{"C7_MSG"		,CriaVar("C7_MSG",.F.)					,NIL}) //Mensagem
							aAdd(aTail(aItem)	,{"C7_TPFRETE"	,CriaVar("C7_TPFRETE",.F.)				,NIL}) //Tipo de frete
							aAdd(aTail(aItem)	,{"C7_OBS"		,CriaVar("C7_OBS",.F.)					,NIL}) //Observacao
							aAdd(aTail(aItem)	,{"C7_SEQMRP"	,CriaVar("C7_SEQMRP",.F.)				,Nil}) //Sequencia MRP
							aAdd(aTail(aItem)	,{"C7_TES"		,CNE->CNE_TE							,Nil}) // TES
							aAdd(aTail(aItem)	,{"C7_ITEMED"	,CNE->CNE_ITEM							,Nil}) //Item da Medicao
							aAdd(aTail(aItem)	,{"C7_VLDESC"	,nVlItDesc								,NIL}) //Desconto Item
							aAdd(aTail(aItem)	,{"C7_CC"		,CNE->CNE_CC							,NIL}) //Centro de custo
							aAdd(aTail(aItem)	,{"C7_CONTA"	,CNE->CNE_CONTA							,NIL}) //Conta
							aAdd(aTail(aItem)	,{"C7_ITEMCTA"	,CNE->CNE_ITEMCT						,NIL}) //Item de conta
							aAdd(aTail(aItem)	,{"C7_CLVL"		,CNE->CNE_CLVL							,NIL})	//Classe de valor
							aAdd(aTail(aItem)	,{"C7_CODNE"	,CNE->CNE_CODNE							,NIL}) //Código da nota de empenho
							aAdd(aTail(aItem)	,{"C7_ITEMNE" 	,CNE->CNE_ITEMNE						,NIL}) //Item da Nota de empenho

							For nX := 1 To Len(aCTBEnt) //Entidades Contabeis
								If SC7->(FieldPos("C7_EC"+aCTBEnt[nX]+"CR")) > 0
									If CNE->(FieldPos("CNE_EC"+aCTBEnt[nX]+"CR")) > 0
										aAdd(aTail(aItem)	,{"C7_EC"+aCTBEnt[nX]+"CR"	,CNE->&("CNE_EC"+aCTBEnt[nX]+"CR")	,NIL}) //Entidades Contabeis Credito
										aAdd(aTail(aItem)	,{"C7_EC"+aCTBEnt[nX]+"DB"	,CNE->&("CNE_EC"+aCTBEnt[nX]+"DB")	,NIL}) //Entidades Contabeis Debito
									Else
										aAdd(aTail(aItem),{"C7_EC"+aCTBEnt[nX]+"CR"	,SB1->&("B1_EC"+aCTBEnt[nX]+"CR")		,NIL}) //Entidades Contabeis Credito
										aAdd(aTail(aItem),{"C7_EC"+aCTBEnt[nX]+"DB"	,SB1->&("B1_EC"+aCTBEnt[nX]+"DB")		,NIL}) //Entidades Contabeis Debito
									EndIf
								EndIf
							Next nX

							//-- Rateio do PC
							Aadd(aRatGCT,CN120GetRa(CNE->CNE_CONTRA,CNE->CNE_NUMMED,CNE->CNE_REVISA,CNE->CNE_ITEM,{"Fornecedor",CND->CND_FORNEC,CND->CND_LJFORN},cC7Item))
							//------------------------------------------------------
							//-- Adiciona Campos para gravação na tabela auxiliar CXJ
							//-- Esses campos são ignorados pela rotina automática, portanto
							//-- é necessário mante-los no final do array.

							aAdd(aTail(aItem)	,{"CONTRA",CNE->CNE_CONTRA,Nil}) // Id do Pedido (Agrupamento)
							aAdd(aTail(aItem)	,{"REV",CNE->CNE_REVISA,Nil}) // Id do Pedido (Agrupamento)
							aAdd(aTail(aItem)	,{"NUMMED",CNE->CNE_NUMMED,Nil}) // Id do Pedido (Agrupamento)
							aAdd(aTail(aItem)	,{"NUMPLA",CNE->CNE_NUMERO,Nil}) // Id do Pedido (Agrupamento)
							aAdd(aTail(aItem)	,{"ITEMPL",CNE->CNE_ITEM,Nil}) // Id do Pedido (Agrupamento)
							aAdd(aTail(aItem)	,{"IDPED",CNE->CNE_IDPED,Nil}) // Id do Pedido (Agrupamento)

						Else
							nAcres += nDecrUnBon * CNE->CNE_QUANT //-- Computa acrescimo no titulo
							nDecres += ((nDecrUn + nDecrUnMul) * CNE->CNE_QUANT) + CNE->CNE_VLDESC //-- Computa decrescimo no valor do titulo
							nDescTit	+= CNE->CNE_VLDESC + (nDecrUnDes * CNE->CNE_QUANT)
							nCaucTit	+= nDecrUnCau * CNE->CNE_QUANT
							nMultTit	+= nDecrUnMul * CNE->CNE_QUANT
							nBoniTit	+= nDecrUnBon * CNE->CNE_QUANT
							nVlrTitulo += CNE->CNE_VLTOT //-- Soma valores dos itens da medição
						EndIf

						If lCN120IT7 //PE para adicionar campos no item da SC7
							aPedCom:= ExecBlock("CN120IT7",.F.,.F.,{aItem})
							If  (Valtype(aPedCom) == "A" .And. Len(aItem)>0)
								aItem := aPedCom
							Endif
						EndIf

					Else //-- VENDA
						If CNE->CNE_PEDTIT == "1"
							cItemSC6 := If(Empty(cItemSC6),strZero(1,TamSX3("C6_ITEM")[1]),Soma1(cItemSC6))//Atualiza sequencia do item

							If !Empty(CNE->CNE_TS) //Atualiza o campo TS dos itens da medição
								cTes := CNE->CNE_TS
							Else
							   	cTes := SB1->B1_TS
						   	EndIf

							If Empty(cTes)
							   lRet := .F.
							   Exit
							ElseIf !SF4->(dbSeek(xFilial('SF4') + cTes))
								Help( " ", 1, 'NOTESFILIAL' )
								lRet:= .F.
								Exit
							EndIf

							aAdd(aItem,{}) //Gera item do pedido de venda
							aAdd(aTail(aItem)	,{"C6_NUM"			,cNumSC5												,Nil}) // Numero do Pedido
							aAdd(aTail(aItem)	,{"C6_ITEM"		,cItemSC6												,Nil}) // Numero do Item no Pedido
							aAdd(aTail(aItem)	,{"C6_PRODUTO"	,CNE->CNE_PRODUT										,Nil}) // Codigo do Produto
							If !Empty(CNB->CNB_DESCRI)
								aAdd(aTail(aItem)	,{"C6_DESCRI"		,CNB->CNB_DESCRI										,NIL})	// Descricao
							Else
								aAdd(aTail(aItem)	,{"C6_DESCRI"		,SB1->B1_DESC											,Nil}) // Descricao
							EndIf
							aAdd(aTail(aItem)	,{"C6_QTDVEN"		,nQuantArred											,Nil}) // Quantidade Vendida
							aAdd(aTail(aItem)	,{"C6_PRUNIT"		,nPrecoArred											,Nil}) // PRECO DE LISTA
							aAdd(aTail(aItem)	,{"C6_PRCVEN"		,nPrecoArred											,Nil}) // Preco Unitario Liquido
							aAdd(aTail(aItem)	,{"C6_VALOR"		,nValorArred											,Nil}) // Valor Total do Item
							aAdd(aTail(aItem)	,{"C6_ENTREG"		,CNE->CNE_DTENT										,Nil}) // Data da Entrega
							aAdd(aTail(aItem)	,{"C6_UM"			,SB1->B1_UM											,Nil}) // Unidade de Medida Primar.
							aAdd(aTail(aItem)	,{"C6_CLI"			,CND->CND_CLIENT										,Nil}) // Cliente
							aAdd(aTail(aItem)	,{"C6_LOJA"		,CND->CND_LOJACL										,Nil}) // Loja do Cliente
						 	aAdd(aTail(aItem)	,{"C6_TES"			,cTes													,Nil}) // TES
							aAdd(aTail(aItem)	,{"C6_LOCAL"		,SB1->B1_LOCPAD										,Nil}) // Local
							aAdd(aTail(aItem)	,{"C6_ITEMED"		,CNE->CNE_ITEM										,Nil}) // Item da Medicao
							aAdd(aTail(aItem)	,{"C6_VALDESC"	,nVlItDesc												,Nil}) // Desconto Item
							aAdd(aTail(aItem)	,{"C6_CC"			,CNE->CNE_CC											,Nil}) // Desconto Item
							aAdd(aTail(aItem)	,{"C6_CONTA"		,CNE->CNE_CONTA										,NIL}) //Conta
							aAdd(aTail(aItem)	,{"C6_ITEMCTA"		,CNE->CNE_ITEMCT									,NIL}) //Item de conta
							aAdd(aTail(aItem)	,{"C6_CLVL"			,CNE->CNE_CLVL										,NIL})	//Classe de valor

							aADD(aRatGCT	,Array(2))
							aRatGCT[len(aRatGCT)][1] := cItemSC6
							aRatGCT[len(aRatGCT)][2] := {}
							aRatGCT[len(aRatGCT)][2] := CN120GetRa(CNE->CNE_CONTRA,CNE->CNE_NUMMED,CNE->CNE_REVISA,CNE->CNE_ITEM,{STR0082,CNA->CNA_CLIENT,CNA->CNA_LOJACL},cItemSC6) //"cliente"
							If Empty(aRatGCT[len(aRatGCT)][2]) //Limpa o array se o centro de custo estiver vazio
								aDel(aRatGCT,Len(aRatGCT))
								aSize(aRatGCT,Len(aRatGCT)-1)
							EndIf

							If CNE->CNE_FLGCMS == "1" //Verifica se o item e comissionado
								cVend:="1"
								For nx:=1 to len(aVend) //Complementa as comissoes de acordo com os contratos
									aAdd(aItem[len(aItem)],{"C6_COMIS"+cVend,aVend[nx,2],NIL})
									cVend:=Soma1(cVend)
								Next
							EndIf
						Else
							nAcres += nDecrUnMul * CNE->CNE_QUANT //-- Computa acrescimo no titulo
							nDecres += ((nDecrUn + nDecrUnBon) * CNE->CNE_QUANT) + CNE->CNE_VLDESC //-- Computa desconto no titulo
							nDescTit	+= CNE->CNE_VLDESC + (nDecrUnDes * CNE->CNE_QUANT)
							nCaucTit	+= nDecrUnCau * CNE->CNE_QUANT
							nMultTit	+= nDecrUnMul * CNE->CNE_QUANT
							nBoniTit	+= nDecrUnBon * CNE->CNE_QUANT
							nVlrTitulo += CNE->CNE_VLTOT //-- Soma valores dos itens da medição
						EndIf
						//------------------------------------------------------
						//-- Adiciona Campos para gravação na tabela auxiliar CXJ
						//-- Esses campos são ignorados pela rotina automática, portanto
						//-- é necessário mante-los no final do array.

						If Len(aItem) > 0
							aAdd(aTail(aItem)	,{"CONTRA",CNE->CNE_CONTRA,Nil}) // Id do Pedido (Agrupamento)
							aAdd(aTail(aItem)	,{"REV",CNE->CNE_REVISA,Nil}) // Id do Pedido (Agrupamento)
							aAdd(aTail(aItem)	,{"NUMMED",CNE->CNE_NUMMED,Nil}) // Id do Pedido (Agrupamento)
							aAdd(aTail(aItem)	,{"NUMPLA",CNE->CNE_NUMERO,Nil}) // Id do Pedido (Agrupamento)
							aAdd(aTail(aItem)	,{"ITEMPL",CNE->CNE_ITEM,Nil}) // Id do Pedido (Agrupamento)
							aAdd(aTail(aItem)	,{"IDPED",CNE->CNE_IDPED,Nil}) // Id do Pedido (Agrupamento)
							aAdd(aTail(aItem)	,{"PARENV","",Nil}) // Id do Pedido (Agrupamento)
						EndIf
					EndIf
				EndIf
	   			//Chama ponto de entrada para tratamento de campos
				//especificos por item na geracao do pedido de compra
				//ou vendas
				If lCN120ITM
					aCN120ITM := ExecBlock("CN120ITM",.f.,.f.,{aCab,aItem,cAliasCNE})
					If Valtype(aCN120ITM) == "A"
						aCab := aCN120ITM[1]
						aItem:= aCN120ITM[2]
					EndIf
				EndIf
				(cAliasCNE)->(dbskip())
			Else
				(cAliasCNE)->(dbskip())
			EndIf
			//Transfere a diferenca dos arredondamentos quando houver
			If (cAliasCNE)->(Eof()) .And. (ABS(nDifValor) >= 0.01)
				If (ValType(aItem)=="A" .And. Len(aItem)>0)
					//Ajusta o valor total e valor unitario do ultimo item
					nPosTotCpo := aScan(aItem[len(aItem)],{|x| x[1] == If((cEspCtr=="1"),"C7_TOTAL","C6_VALOR")})
					nPosUniCpo := aScan(aItem[len(aItem)],{|x| x[1] == If((cEspCtr=="1"),"C7_PRECO","C6_PRUNIT")})
					nPosVenCpo := aScan(aItem[len(aItem)],{|x| x[1] == "C6_PRCVEN"})
					nValQuant  := aItem[ Len( aItem ), aScan(aItem[len(aItem)],{|x| x[1] == If((cEspCtr=="1"),"C7_QUANT","C6_QTDVEN")} ), 2 ]
					If nPosTotCpo > 0 .And. nPosUniCpo > 0
						nAuxTot := aItem[len(aItem),nPosTotCpo,2]
						nValTot := A410Arred( nAuxTot - nDifValor , If(cEspCtr=="1","C7_TOTAL","C6_VALOR") )
						nValUni := A410Arred(nValTot / nValQuant,If(cEspCtr=="1","C7_PRECO","C6_PRUNIT"))
						aItem[len(aItem),nPosUniCpo,2] := nValUni
						aItem[len(aItem),nPosTotCpo,2] := A410Arred(nValUni * nValQuant,If(cEspCtr=="1","C7_TOTAL","C6_VALOR"))
						If cEspCtr=="2"
							If nPosVenCpo > 0
								aItem[len(aItem),nPosVenCpo,2] := nValUni
							EndIf
						EndIf
						nDifValor := nValTot - (nAuxTot - nDifValor)
					EndIf
				EndIf
			EndIf
		EndDo
		If !lRet
			Exit
		EndIf
		//Chama ponto de entrada para tratamento de campos
		//especificos na geracao do pedido de compra
		If lCN120PED
			aRet := ExecBlock("CN120PED",.f.,.f.,{aCab,aItem,cAliasCNE})
			If Valtype(aRet) == "A"
				aCab := aRet[1]
				aItem:= aRet[2]
			EndIf
		EndIf
		//Executa rotina automatica para geracao dos documentos
		If (ValType(aCab)=="A" .And. Len(aCab)>0) .And. (ValType(aItem)=="A" .And. Len(aItem)>0)
			If cEspCtr=="1" //Gera pedido de compra
				//Ajusta array do rateio por Centro de Custo
				//para rotina automática do Pedido de Compras
				For nX:= 1 to Len(aRatGCT)
					For nY := 1 to Len(aRatGCT[nX])
						nZ++
						aAdd(aRatPedGCT,{})
						aRatPedGCT[nZ] := aRatGCT[nX,nY]
					Next nY
				Next nX
				nX := 0
				nY := 0
				If lCN120AEP //// Ponto de Entrada para alterar filial antes de processar o pedido de compra
					 ExecBlock("CN120AEP",.F.,.F.)
				EndIf				
				
				If(cTipoMulta != "1")
					If((nPosDesc := aScan(ATail(aItem), {|x| x[1] == 'C7_VLDESC'})) > 0)
						nTotDesc := 0
						aEval(aItem,{|x| nTotDesc += x[nPosDesc, 2]})
					EndIf
					AAdd( aCab , { "C7_VLDESC"  , A410Arred(nPDesconto + nTotDesc, "C7_VLDESC"), NIL } )
				Else
					nPDespesa := CriaVar("C7_DESPESA",.F.)
				EndIf
				AAdd( aCab , { "C7_DESPESA"	, nPDespesa	, NIL } )				

				cNumPed := cNumSC7
				MSExecAuto({|v,x,y,z,w,a| MATA120(v,x,y,z,w,a)},1,aCab,aItem,3,.F.,aRatPedGCT)
				
			Else //Gera pedido de venda
							
				If(cTipoMulta != "1")
					If((nPosDesc := aScan(ATail(aItem), {|x| x[1] == 'C6_VALDESC'})) > 0)
						nTotDesc := 0
						aEval(aItem,{|x| nTotDesc += x[nPosDesc, 2]})
						nTotDesc := A410Arred(nTotDesc, "C6_VALDESC")
					EndIf					
					AAdd( aCab , { "C5_DESCONT" , A410Arred(nPDesconto + nTotDesc, "C5_DESCONT"), NIL } )				
					
					AAdd( aCab , { "C5_DESPESA"	, nPDespesa	, NIL } )
				EndIf
				
				MSExecAuto({|x,y,z,w| Mata410(x,y,z,,,,,w)},aCab,aItem,3,aRatGCT)
				cNumPed := SC5->C5_NUM				
			EndIf

			lRet := !lMsErroAuto
			If lMsErroAuto .And. !IsBlind()
				MostraErro()
			Endif
		ElseIf (Len(aItem) == 0) .And. (Str(nTpDoc,1) $ '1;3') .AND. !lCnnoped  //gera pedido ou pedido+titulo
			Help (" ",1,"CN120DESC",,STR0049,1,1) //Não foi possível encerrar a medição. O saldo da planilha não equivale ao valor da medição.
			lMsErroAuto := .T.
			lRet := .F.
		EndIf

		If lRet .And. nTpDoc # 1 .AND. nVlrTitulo > 0 //-- Se gera titulo
			If cEspCtr=="1" //-- Gera titulo a pagar (SE2)
				aAdd(aTitulo,{"E2_VALOR",nVlrTitulo,Nil})
				aAdd(aTitulo,{"E2_MDDESC"	,nDescTit		,Nil})
				aAdd(aTitulo,{"E2_RETCNTR"	,nCaucTit		,Nil})
				aAdd(aTitulo,{"E2_MDMULT"	,nMultTit		,Nil})
				aAdd(aTitulo,{"E2_MDBONI"	,nBoniTit		,Nil})

				If (nAcres - nDecres) > 0
					aAdd(aTitulo,{"E2_ACRESC",nAcres - nDecres,Nil})
				ElseIf (nDecres - nAcres) > 0
					aAdd(aTitulo,{"E2_DECRESC",nDecres - nAcres,Nil})
				EndIf

				lRet := C120TitSE2(aTitulo,@cNumTit)

			Else //-- Gera titulo a receber (SE1)
				aAdd(aTitulo,{"E1_VALOR",nVlrTitulo,Nil})
				aAdd(aTitulo,{"E1_MDDESC"	,nDescTit		,Nil})
				aAdd(aTitulo,{"E1_RETCNTR"	,nCaucTit		,Nil})
				aAdd(aTitulo,{"E1_MDMULT"	,nMultTit		,Nil})
				aAdd(aTitulo,{"E1_MDBONI"	,nBoniTit		,Nil})

				If (nAcres - nDecres) > 0
					aAdd(aTitulo,{"E1_ACRESC",nAcres - nDecres	,Nil})
				ElseIf (nDecres - nAcres) > 0
					aAdd(aTitulo,{"E1_DECRESC",nDecres - nAcres,Nil})
				EndIf

				lRet := C120TitSE1(aTitulo,@cNumTit)
			EndIf
		EndIf
		If lCN120PDM //Executa ponto de entrada após execução do MSExecAuto
		   lCN120PDM := ExecBlock("CN120PDM",.F.,.F.,{lRet})
		  	If ValType(lCN120PDM) == "L"
				lRet := lCN120PDM
			EndIf
		EndIf
		//-- Grava tabela auxiliar CXJ
		If lRet
			Cn120GCXJ(aPedCXJ,1)
		Endif
	EndIf

	If lRet
		If ValType(aItem)=="A" .And. Len(aItem)>0
			If cEspCtr == "1" //Seleciona pedido de compra criado
				CNB->(dbSetOrder(1))				
				dbSelectArea("SC7")
				// Verifica se o número do Pedido Mudou
				If SC7->C7_NUM <> cNumSC7
					cNumSC7 	:= SC7->C7_NUM
					cNumPed 	:= cNumSC7
				Endif
				nPosItemed := aScan(aItem[len(aItem)],{|x| x[1] == "C7_ITEMED"})
				cQuery := "SELECT SC7.R_E_C_N_O_ as RECNO,SC7.C7_ITEM "
				cQuery += "  FROM "+ RetSQLName("SC7") +" SC7 "
				cQuery += " WHERE SC7.C7_FILIAL  = '"+ xFilial("SC7") +"'"
				cQuery += "   AND SC7.C7_NUM     = '"+ cNumSC7 +"'"
				cQuery += "   AND SC7.D_E_L_E_T_ = ''"
				cQuery := ChangeQuery(cQuery)
				dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TRBSC7",.F.,.F.)
				While !TRBSC7->(Eof()) //Preenche campos especificos do SIGAGCT
					nY++
					SC7->(MsGoTo(TRBSC7->RECNO))
					RecLock("SC7",.F.)
						SC7->C7_CONTRA  := CND->CND_CONTRA
						SC7->C7_CONTREV := cNRevisa
						SC7->C7_PLANILH := CND->CND_NUMERO
						SC7->C7_MEDICAO := CND->CND_NUMMED
						SC7->C7_ITEMED  := aItem[nY,nPosItemed,2]
						If	!Empty(cCodEdt) .And. !Empty(cNumPro)
							SC7->C7_CODED := cCodEdt
							SC7->C7_NUMPR := cNumPro
						EndIf
					MsUnlock()

					If !Empty(CN9->CN9_NUMCOT) //-- Se gerado por cotacao, atualiza relacionamento com SCs
						CNB->(dbSeek(xFilial("CNB")+CND->(CND_CONTRA+CND_REVISA+CND->CND_NUMERO)+aItem[nY,nPosItemed,2]))
						SC1->(dbSetOrder(5))
						SC1->(dbSeek(xFilial("SC1")+CN9->CN9_NUMCOT+CNB->(CNB_PRODUT+CNB_IDENT)))
						While !SC1->(EOF()) .And. SC1->(C1_FILIAL+C1_COTACAO+C1_PRODUTO+C1_IDENT) == xFilial("SC1")+CN9->CN9_NUMCOT+CNB->(CNB_PRODUT+CNB_IDENT)
							//-- Atualiza acumulado das SCs atendidas pelo pedido da medicao
							MaAvalSC("SC1",6,,"SC7")

							SC1->(dbSkip())
						EndDo	
						
					ElseIf !Empty( SC7->C7_NUMSC ) .And. !Empty(SC7->C7_CODED) .And. !Empty(SC7->C7_NUMPR) //-- Se possui SC e vindo do edital, atualiza relacionamento com SCs				
						CNB->(dbSeek(xFilial("CNB")+CND->(CND_CONTRA+CND_REVISA+CND->CND_NUMERO)+aItem[nY,nPosItemed,2]))
						SC1->(dbSetOrder(8)) //C1_FILIAL+C1_CODED+C1_NUMPR+C1_PRODUTO+C1_NUM+C1_ITEM                                                                                                           
						SC1->(dbSeek(xFilial("SC1")+CN9->(CN9_CODED+CN9_NUMPR)+CNB->(CNB_PRODUT+CNB_NUMSC+CNB_ITEMSC)))
						While !SC1->(EOF()) .And. SC1->(C1_FILIAL+C1_CODED+C1_NUMPR+C1_PRODUTO+C1_NUM+C1_ITEM ) == xFilial("SC1")+CN9->(CN9_CODED+CN9_NUMPR)+CNB->(CNB_PRODUT+CNB_NUMSC+CNB_ITEMSC)
							//-- Atualiza acumulado das SCs atendidas pelo pedido da medicao
							MaAvalSC("SC1",6,,"SC7")
							SC1->(dbSkip())
						EndDo				
					
					ElseIf !Empty(SC7->C7_NUMSC) //-- Se possui SC, atualiza relacionamento com SCs
						CNB->(dbSeek(xFilial("CNB")+CND->(CND_CONTRA+CND_REVISA+CND->CND_NUMERO)+aItem[nY,nPosItemed,2]))
						SC1->(dbSetOrder(2))
						SC1->(dbSeek(xFilial("SC1")+CNB->(CNB_PRODUT+CNB_NUMSC+CNB_ITEMSC)))
						While !SC1->(EOF()) .And. SC1->(C1_FILIAL+C1_PRODUTO+C1_NUM+C1_ITEM) == xFilial("SC1")+CNB->(CNB_PRODUT+CNB_NUMSC+CNB_ITEMSC)
							//-- Atualiza acumulado das SCs atendidas pelo pedido da medicao
							MaAvalSC("SC1",6,,"SC7")
							SC1->(dbSkip())
						EndDo									
									
					EndIf
					
					If lLog //Na Inclusão do Pedido o Log ja e gravado
						RSTSCLOG("PED",5,/*cUser */,SC7->(C7_NUM+C7_ITEM))
					EndIf
					TRBSC7->(dbSkip())
				EndDo

				If lCN120GSC //PE para gravar informações na SC7
					ExecBlock("CN120GSC",.F.,.F.)
				EndIf

				TRBSC7->(dbCloseArea())

			EndIf
		EndIf

		// FSW - PE para alterar filial depois de processar o pedido de compra
		If lCN120ADP
			ExecBlock("CN120ADP",.F.,.F.)
		EndIf

		// Atualiza codigo do pedido e titulo que foram gerados
		If !lExcede
			RecLock("CND",.F.)
				CND->CND_PEDIDO := cNumPed
				CND->CND_NUMTIT := cNumTit
				CND->CND_REVGER	:= cNRevisa
			MsUnlock()
		EndIf
		//Atualiza o campo CNE_PEDIDO dos itens da medicao
		//com o codigo do pedido gerado
		(cAliasCNE)->(dbGoTop())
		While !(cAliasCNE)->(Eof())
			CNE->(MsGoto( ( cAliasCNE)->RECNO ) )
			If !lExcede .Or. (CNE->CNE_EXCEDE == '1' .And. Empty(CNE->CNE_PEDIDO))
				If CNE->CNE_PEDTIT == '2' //Baixa o saldo a receber da planilha
					CtaAvalGCT(1,{},CNE->CNE_CONTRA,CNE->CNE_NUMERO,CNE->CNE_ITEM,CNE->CNE_QUANT,,CNE->CNE_NUMMED,CNE->CNE_VLTOT,CNE->CNE_REVISA)
				Else
					RecLock("CNE",.F.)
					CNE->CNE_PEDIDO := cNumPED
					MsUnlock()
				EndIf
			EndIf
			(cAliasCNE)->(dbSkip())
		EndDo

		// FSW - Criação de Ponto de Entrada para gravar o número do pedido na medição
		// Somente para pedidos de compra
		If lCN120GPM .And. cEspCtr=="1" .And. lRet
			ExecBlock("CN120GPM",.F.,.F.,{cNumSC7,cNumPed})
		EndIf

		//Verifica se o recurso de multa / bonificacao esta disponivel para a medicao
		If !lExcede
			//Obtem o valor de multa e/ou bonificacao da medicao
			cAliasCNR := GetNextAlias()
			cQuery := "SELECT CNR_VALOR, CNR_DESCRI, CNR_TIPO "
			cQuery += "  ,CNR_CONTRA "
			cQuery += "  FROM " + RetSqlName("CNR")
			cQuery += " WHERE CNR_NUMMED='" + cNumMed + "'"
			cQuery += "   AND D_E_L_E_T_=' '"

			cQuery := ChangeQuery( cQuery )
			dbUseArea( .T., "TOPCONN", TcGenQry( ,, cQuery ), cAliasCNR, .F., .T. )
			TcSetField( cAliasCNR, "CNR_VALOR", "N", 18, 2 ) //Acerta o campo numerico

			aMultas := {}
			While !( cAliasCNR )->( Eof() )

				If !Empty(( cAliasCNR )->CNR_CONTRA) .And. (( cAliasCNR )->CNR_CONTRA) <> CND->CND_CONTRA
					( cAliasCNR )->( dbSkip() )
					Loop
				EndIf


				AAdd( aMultas, { ( cAliasCNR )->CNR_VALOR,( cAliasCNR )->CNR_DESCRI,( cAliasCNR )->CNR_TIPO } )
				( cAliasCNR )->( dbSkip() )
			EndDo
			( cAliasCNR )->( dbCloseArea() )
			dbSelectArea( "CNR" )
			//armaz. historico
			CN120HistMul( 1, aMultas, CND->CND_CONTRA, CND->CND_NUMMED )
		EndIf

		If !lExcede .And. !Empty(CND->CND_RETCAC) //Grava retencao da caucao
			CN120CaucRet(CND->CND_CONTRA,CND->CND_NUMMED,1,CND->CND_RETCAC)
		EndIf
	EndIf
	(cAliasCNE)->(dbCloseArea())
	(cAliasCND)->(dbSkip())
EndDo

(cAliasCND)->(dbCloseArea())
RestArea(aArea)

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN120CaucRet³ Autor ³ Marcelo Custodio      ³ Data ³20.09.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Grava o valor retido da caucao com base no valor da medicao  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³  CN120CaucRet(cExp01,cExp02,nExp03,nExp04)                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³  cExp01 - Codigo do contrato                                ³±±
±±³          ³  cExp02 - Codigo do medicao                                 ³±±
±±³          ³  nExp03 - (1-Incluir,2-Excluir)                             ³±±
±±³          ³  nExp04 - Valor retido                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                             ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function CN120CaucRet(cContra,cMedicao,nOpc,nVlRet)
Local cQuery      := ""
Local cAliasCNT   := ""
Local cLctoRet    := "695"
Local lCn120IncCa := ExistBlock("CN120INCCA")
Local lGrvCau     := .T.

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Ponto de entrada para indicar se grava ou não a   ³
//³retencao de caucao                                ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If ExistBlock("CN120GRVCA")
	lGrvCau := ExecBlock("CN120GRVCA",.F.,.F.)
	If ValType(lGrvCau) <> "L"
		lGrvCau:=.T.
	EndIf
EndIf

If lGrvCau
	If nOpc==1//Inclusao
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Grava retencao da caucao                 ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea("CNT")
		RecLock("CNT",.T.)
			CNT->CNT_FILIAL := xFilial("CNT",cFilCTR)
			CNT->CNT_CONTRA := cContra
			CNT->CNT_NUMMED := cMedicao
			CNT->CNT_VLRET  := Round(nVlRet,TamSX3("CNT_VLRET")[2])
			CNT->CNT_DTMED  := dDataBase
			CNT->CNT_FORNEC := CND->CND_FORNEC
			CNT->CNT_LJFORN := CND->CND_LJFORN
			CNT->CNT_CLIENT := CND->CND_CLIENT
			CNT->CNT_LOJACL := CND->CND_LOJACL
			If lCn120IncCa
				ExecBlock("CN120INCCA",.F.,.F.)
			Endif
		MsUnlock()
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Executa contabilizacao da retencao do contrato ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		CN120Contab(cLctoRet)
	Else
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Seleciona retencao da medicao            ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cQuery := "SELECT CNT.R_E_C_N_O_ AS RECNO "
		cQuery += "  FROM "+RetSQLName("CNT")+" CNT "
		cQuery += " WHERE CNT.CNT_FILIAL = '"+xFilial("CNT",cFilCTR)+"'"
		cQuery += "   AND CNT.CNT_CONTRA = '"+cContra+"'"
		cQuery += "   AND CNT.CNT_NUMMED = '"+cMedicao+"'"
		cQuery += "   AND CNT.D_E_L_E_T_ = ' '"

		cAliasCNT := GetNextAlias()

		cQuery := ChangeQuery(cQuery)
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasCNT,.F.,.T.)

		dbSelectArea("CNT")
		While !(cAliasCNT)->(Eof())
			CNT->( MsGoTo( (cAliasCNT)->RECNO ) )

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Exclui retencao        ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			RecLock("CNT",.F.)
				CNT->( dbDelete() )
			CNT->( MsUnlock() )
			(cAliasCNT)->(dbSkip())
		EndDo

		(cAliasCNT)->(dbCloseArea())
	EndIf
EndIf
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN120MedEst³ Autor ³ Marcelo Custodio      ³ Data ³09.02.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Estorna medicao, valida pedido de compra, medicoes zeradas  ³±±
±±³          ³ e saldo do contrato, planilhas e cronogramas                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³  CN120MedEst(nExp01)                                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³  nExp01 - Registro atual                                    ³±±
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
Function CN120MedEst(nReg,nAcao,lAviso,lAutoFor,lMedServ,lAprRev)
Local cQuery   	:= ""
Local cNumSC7  	:= ""
Local cNumSC5  	:= ""
Local cCronog  	:= ""
Local cFilCod  	:= ""
Local cEspCtr  	:= ""
Local cAliasPed	:= ""
Local cParcel  	:= ""
Local cAliasCNT	:= ""
Local cAliasQry	:= ""
Local cAliasSD1	:= ""
Local cAliasSE1	:= ""
Local cAliasSE2	:= ""
Local cFilCND  	:= xFilial("CND")
Local cFilSC7  	:= xFilial("SC7")
Local cRetPrf	:= PadR(SuperGetMV("MV_CNPREMD",.F.,"MED"),Len(SE2->E2_PREFIXO))
Local cTpTit	:= PadR(SuperGetMV("MV_CNTPTMD",.F.,"BOL"),Len(SE2->E2_TIPO))
Local cNumTit 	:= ""
Local cFilMed	:= ""
Local cPrefixo	:= ""
Local cCN120PRE := ""

Local lMedEve  	:= .F.
Local lContinua	:= .T.
Local lEstSld  	:= .T.
Local lEstPed  	:= .F.
Local lEstExce 	:= .T.
Local lFisico  	:= .F.
Local lFixo    	:= .T.
Local lValor   	:= .T.
Local lPeSld   	:= ExistBlock("CN120ESSLD")
Local lVldVige 	:= GetNewPar("MV_CNFVIGE","N") == "N"
Local lBloqSE2 	:= .F.
Local lRet     	:= .F.
Local lGCTBloq 	:= (SE2->(FieldPos("E2_MSBLQL")) > 0)
Local lUsaFlag	:= SuperGetMV( "MV_CTBFLAG" , .T. /*lHelp*/, .F. /*cPadrao*/)
Local lCtbCNE	:= .F.
Local aFlagCTB := {}

Local nTipo    	:= 1 //1 - Medicao;2 - Autorizacao de Fornecimento
Local nTaxa
Local nServico 	:= 1 //1 - Medicao;2 - Medicao de Servico
Local nTpDoc	:= CN120VerDoc(CND->CND_NUMMED) //Verifica quais documentos foram gerados Pedidos/Titulos
Local nTamContra	:= TamSx3("CNZ_CONTRA")[1]
Local nTamRevisa	:= TamSx3("CNZ_REVISA")[1]
Local nTamNumMed	:= TamSX3("CNZ_NUMMED")[1]
Local nTamItem	:= TamSx3("CNZ_ITCONT")[1]
Local nLp69B	:= 0
Local nLp69I	:= 0

Local uRet
Local dDtFim
Local aPVExce  := {}

//Variaveis da contabilizacao
Local nHead			:= 0
Local nDet  		:= 0     							//Retorno da funcao DetProva
Local nI			:= 0

Local cArqGCT 		:= ""
Local cLoteGCT  	:= LoteCont("COM")  				//Numero do Lote
Local cLancCont		:= ""
Local cBusca		:= ""

Local lDigita 		:= .F.    	 						//Mostra lancamento?
Local lAglutina		:= .F.    	 						//Aglutina
Local lMedComPlan 	:= .F.

Local aLPGCT		:= {	{"697",VerPadrao("697")},; //LP Gestão de Contratos - Encerramento da Medição
							{"698",VerPadrao("698")},; //LP Gestão de Contratos - Encerramento da Medição/Automatico
							{"699",VerPadrao("699")},; //LP Gestão de Contratos - Encer. Medicao: Itens do Contrato
							{"69A",VerPadrao("69A")},; //LP Gestão de Contratos - Est. Medicao: Itens do Contrato
							{"69B",VerPadrao("69B")},; //LP Gestão de Contratos - Incl. Rateio Itens Contrato s/ Planilha
							{"69C",VerPadrao("69C")},; //LP Gestão de Contratos - Excl. Rateio Itens Contrato s/ Planilha
							{"69D",VerPadrao("69D")},; //LP Gestão de Contratos - Incl. Rateio Itens Contrato c/ Planilha
							{"69E",VerPadrao("69E")},;
							{"69F",VerPadrao("69F")},; //LP Gestão de Contratos - Excl. Rateio Itens Contrato c/ Planilha
							{"69H",VerPadrao("69H")},; //LP Gestão de Contratos - Encerramento da medição por item norma IFRS 15 (bens e serviços)
							{"69I",VerPadrao("69I")}; //LP Gestão de Contratos - Estorno da medição por item norma IFRS 15 (bens e serviços)
						}

Private cXFil := "" // Para ser utilizado no ponto de entrada antes de após o processamento da exclusão do pedido de compra - FSW

DEFAULT nAcao  := 1//1 - Estorna;2 - Exclui Pedido;3 - Somente Estorna
DEFAULT lAviso := .T.
DEFAULT lAutoFor:= .F.
DEFAULT lMedServ:= .F.
DEFAULT lAprRev := .F.

//³Ponto de entrada para indicar se atualiza ou nao  saldo da medicao no estorno                       ³


If ExistBlock("CN120ATESL")
	lEstSld := ExecBlock("CN120ATESL",.F.,.F.)
	If ValType(lEstSld) <> "L"
		lEstSld:=.T.
	EndIf
EndIf

dbSelectArea("CND")
CND->(MsGoTo(nReg))

//Estabelece passos
ProcRegua(6)

If !lAutoFor .Or. !lMedServ
	lContinua := CN240VldUsr(CND->CND_CONTRA,DEF_TRAEST,.T.,,cFilCtr)
EndIf

If Type('cOrigem') == 'U'
	cOrigem = 'CNTA120'
EndIf

//³Ponto de entrada para validar o estorno da medicao
If ExistBlock("CN120VEST")
	uRet := ExecBlock("CN120VEST", .F., .F., {lContinua})
	If ValType(uRet) == "L"
		lContinua := uRet
	EndIf
EndIf

Pergunte("CNT120",.F.)	//carrega as variaveis
If lAprRev
	MV_PAR01 := 1
	MV_PAR02 := 2
	MV_PAR03 := 2
EndIf

If (lCtbOnLine := (MV_PAR01 == 1)) //SE CONTABILIZA, atraves da escolha do usuario
	//Percorre os lancamentos contabeis do GCT, se algum deles existir, a contabilizacao podera ter continuidade
	For nI := 1 to len(aLPGCT)
		If aLPGCT[nI,2]
			lCtbOnline := .T.
			Exit
		Else
			lCtbOnline := .F.
		Endif
	Next nI

	If lCtbOnLine
		lDigita	  := If(ValType(MV_PAR02)=="N",MV_PAR02 == 1,.F.)
		lAglutina := If(ValType(MV_PAR03)=="N",MV_PAR03 == 1,.F.)
		nHead	  := HeadProva(cLoteGCT,"CNTA120",Subs(cUsuario,7,6),@cArqGCT)
		If nHead <= 0
			Help(" ",1,"SEM_LANC")
			lCtbOnLine := .F.
		EndIf
	EndIf
Endif

If lContinua
	If !Empty(CND->CND_DTFIM) .Or. nAcao != 1
		nTipo := IIf(CND->CND_AUTFRN=="2",2,1)
		If nTipo == 2 .And. nAcao == 1
			nAcao := 3
		EndIf

		nServico := IIf(CND->CND_SERVIC=="1",1,2)
		If nAcao != 3
			dbSelectArea("CN9")
			CN9->(dbSetOrder(1))

			//-- Posiciona na revisao atual do contrato
			If IsInCallStack("CN300REVPD")
				CN9->(dbSeek(xFilial("CN9",cFilCTR)+CND->CND_CONTRA+CnGetRevAt(CND->CND_CONTRA, cFilCtr),.T.))
				lVldVige := .F.
			Else
				CN9->(dbSeek(xFilial("CN9",cFilCTR)+CND->CND_CONTRA+CnGetRevVg(CND->CND_CONTRA, cFilCtr),.T.))
			EndIf
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Identifica especie do contrato ³
			//³ 1 - Compra                     ³
			//³ 2 - Venda                      ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			cEspCtr := CN9->CN9_ESPCTR
			//So permite o estorno se o contrato estiver fora das seguintes situacoes
			If lVldVige .And.((CN9->CN9_SITUAC==DEF_SFINA) .Or. (CN9->CN9_DTINIC > dDataBase .Or. CN9->CN9_DTFIM < dDataBase))  //Contrato finalizado ou fora do período da vigência
				lContinua := .F.
				Help( " ", 1, "CNTA120_07" )//Contrato fora do periodo de vigencia
			EndIf

			If lContinua .And. CN9->CN9_SITUAC==DEF_SFINA
			  lContinua := .F.
			  Aviso("CNTA120",STR0117,{STR0155})//Ação não disponível para contrato Finalizado
		 	EndIF

			If lContinua .And. CN9->CN9_SITUAC==DEF_SCANC
				lContinua := .F.
				Help( " ", 1, "CNTA120_10" )//Ação não disponível para contrato Cancelado
			EndIf

			If lContinua .And. CN9->CN9_SITUAC==DEF_SREVS .And. !IsInCallStack("CN300REVPD")
				lContinua := .F.
				Help( " ", 1, "CNTA120_11" )//Ação não disponível para contrato com Revisão em Aberto
			EndIf

			If lContinua .And. (CN9->CN9_REVISA <> CND->CND_REVISA) //Verifica se a revisao da medição é a revisão atual
				lContinua := .F.
				Help( " ", 1, "CNTA120_12" )//Estorno não permitido para revisões anteriores.
			EndIf

			If lContinua .And. nModulo <> 28
				dbSelectArea("TFJ")
				TFJ->(dbSetOrder(5))
				If TFJ->(MsSeek(xFilial("TFJ")+CN9->CN9_NUMERO+CN9->CN9_REVISA)) .And. Cn120IsMdGS( CND->CND_NUMMED )
					lContinua := .F.
					Help(" ",1,"CNTA120TEC")	//-- Acao disponivel apenas para contratos sem vinculos com Gestão de Serviços
				EndIf
			EndIf

			dbSelectArea("CNA")
			CNA->(dbSetOrder(1))
			If CNA->(MsSeek(xFilial("CNA",cFilCTR)+CND->(CND_CONTRA+CND_REVISA+CND_NUMERO)))
				cCronog := CNA->CNA_CRONOG
				dbSelectArea("CNF")
				CNF->(dbSetOrder(3))
				If CNF->(MsSeek(xFilial("CNF",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA+cCronog+CND->CND_PARCEL))
					nTaxa := CNF_TXMOED
				EndIf
			EndIf

			If lContinua .And.!Empty(CND->CND_RETCAC)
				//³ Verifica se existe retencao para a medicao e se a mesma se encontra baixada                     ³
				cQuery := " SELECT COUNT(*) AS RETQTD "
				cQuery += " FROM "+RetSQLName("CNT")+" CNT"
				cQuery += " WHERE CNT.CNT_FILIAL = '"+xFilial("CNT",cFilCTR)+"'"
				cQuery += " AND CNT.CNT_CONTRA = '"+CND->CND_CONTRA+"'"
				cQuery += " AND CNT.CNT_NUMMED = '"+CND->CND_NUMMED+"'"
				cQuery += " AND CNT.CNT_VLBX   > 0"
				cQuery += " AND D_E_L_E_T_ = ' '"

				cAliasCNT := GetNextAlias()
				cQuery := ChangeQuery(cQuery)
				dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasCNT,.F.,.T.)

				lContinua := ((cAliasCNT)->RETQTD == 0)
				(cAliasCNT)->(dbCloseArea())

				If !lContinua
					Help( " ", 1, "CNTA120_05")//"A medição não pode ser estornada, pois o valor de retenção da caução já foi baixado"
				EndIf
			EndIf

			If lContinua
				dbSelectArea("CNE")
				CNE->(dbSetOrder(1))
				// Seleciona pedido gerado
				If CNE->(MsSeek(xFilial("CNE")+CND->(CND_CONTRA+CND_REVISA+CND_NUMERO+CND_NUMMED)))
					If cEspCtr == "1"
						cNumSC7 := CNE->CNE_PEDIDO
						If Empty(cNumSC7)//Carrega o pedido do cabecalho
							cNumSC7 := CND->CND_PEDIDO
						EndIf
					Else
						cNumSC5 := CNE->CNE_PEDIDO
						If Empty(cNumSC5)//Carrega o pedido do cabecalho
							cNumSC5 := CND->CND_PEDIDO
						Endif
					EndIf

					cNumTit := CND->CND_NUMTIT //Recupera numero do titulo seja à pagar ou receber
					
					If Empty(CND->CND_FILMED)
						cFilMed := CND->CND_FILIAL //Recupera a filial do titulo gerado.
					Else
						cFilMed := CND->CND_FILMED
					EndIf

				EndIf

				PcoIniLan("000355")
				lMsErroAuto := Iif(Type("lMsErroAuto")=='L',lMsErroAuto,.F.)

				Begin Transaction
					// Exclui pedidos de venda de excedentes
					IncProc(If(cEspCtr == '2',STR0043,""))
					If cEspCtr == '2'
						cQuery := " SELECT CNE.CNE_PEDIDO AS PVNUM, CNE.R_E_C_N_O_ AS RECNO  "
						cQuery += " FROM " +RetSQLName("CNE") +" CNE WHERE "
						cQuery += " CNE.D_E_L_E_T_ <> '*' AND CNE.CNE_FILIAL = '" +xFilial("CNE",cFilCtr) +"' AND "
						cQuery += " CNE.CNE_CONTRA = '" +CND->CND_CONTRA +"' AND CNE.CNE_NUMMED = '" +CND->CND_NUMMED +"' AND "
						cQuery += " CNE.CNE_EXCEDE = '1' AND CNE.CNE_PEDIDO NOT IN('" +CND->CND_PEDIDO +"','"+Space(TamSx3("CND_PEDIDO")[1])+"')"

						cQuery := ChangeQuery(cQuery)
						dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"PVEXCE",.F.,.T.)

						While !PVEXCE->(EOF())
							If aScan(aPVExce,PVEXCE->PVNUM) == 0
								aAdd(aPVExce,PVEXCE->PVNUM)
								MSExecAuto({|x,y,z| Mata410(x,y,z)},{{"C5_NUM",PVEXCE->PVNUM,NIL}},{},5)

								If lMsErroAuto
									lEstExce := .F.
									MostraErro()
									Exit
								Endif
							EndIf

							CNE->(dbGoTo(PVEXCE->RECNO))
							RecLock("CNE",.F.)
							CNE->CNE_PEDIDO := ""
							CNE->(MsUnlock())
							PVEXCE->(dbSkip())
						EndDo
						PVEXCE->(dbCloseArea())
					EndIf

					If CND->CND_ZERO == "2" .And. lEstExce //Verifica se a medicao e zerada
						If cEspCtr == "1"
							If !Empty(cNumSC7)
								IncProc( STR0020 )//"Verificando pedido de compras"

								// PE para alterar filial antes de processar a exclusão do pedido de compra
								If ExistBlock("CN120EPM")
									ExecBlock("CN120EPM",.F.,.F.)
								EndIf

								MSExecAuto({|v,x,y,z,w| MATA120(v,x,y,z,w)},1,{{"C7_NUM",cNumSC7,NIL}},{},5,.F.) //Exclui pedido de compras

								// PE para alterar filial depois de processar a exclusão do pedido de compra
								If ExistBlock("CN120EPE")
									ExecBlock("CN120EPE",.F.,.F.)
								EndIf

								lEstPed := !lMsErroAuto
								If lMsErroAuto
									MostraErro()
								EndIf
							EndIf

							If !Empty(cNumTit)
								IncProc(STR0120)//"Verificando título a pagar"

								If ExistBlock("CN120PRE") // PE utilizado para alterar o prefixo do título financeiro
									cCN120PRE := ExecBlock("CN120PRE",.F.,.F.,{cRetPrf,"2"})
									If ValType(cCN120PRE) == "C"
										cRetPrf := cCN120PRE
									EndIf
								EndIf

								cAliasSE2 := GetNextAlias()
								//E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
								BeginSql Alias cAliasSE2
									SELECT 	E2_FILIAL,
											E2_FILORIG,
											E2_PREFIXO,
											E2_NUM,
											E2_PARCELA,
											E2_TIPO,
											E2_FORNECE,
											E2_LOJA,
											E2_ORIGEM
									
									FROM 	%Table:SE2% SE2
									
									WHERE	SE2.E2_FILORIG = %exp:cFilMed% AND
											SE2.E2_PREFIXO = %exp:cRetPrf% AND
											SE2.E2_NUM = %exp:cNumTit% AND
											SE2.E2_TIPO = %exp:cTpTit% AND
											SE2.E2_MDCONTR = %exp:CND->CND_CONTRA% AND
											SE2.E2_ORIGEM = 'CNTA120' AND
											SE2.%NotDel%
								EndSql

								
								While !lMsErroAuto .And. (cAliasSE2)->(!Eof())
									aTitulo := {}
									//E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
									
									aAdd(aTitulo,{"E2_FILIAL"	, (cAliasSE2)->E2_FILIAL		,NIL})
									aAdd(aTitulo,{"E2_FILORIG"	, (cAliasSE2)->E2_FILORIG		,NIL})
									aAdd(aTitulo,{"E2_PREFIXO"	, (cAliasSE2)->E2_PREFIXO		,NIL})
									aAdd(aTitulo,{"E2_NUM"		, (cAliasSE2)->E2_NUM	  		,NIL})
									aAdd(aTitulo,{"E2_PARCELA"	, (cAliasSE2)->E2_PARCELA	  	,NIL})
									aAdd(aTitulo,{"E2_TIPO"		, (cAliasSE2)->E2_TIPO			,NIL})
									aAdd(aTitulo,{"E2_FORNECE"	, (cAliasSE2)->E2_FORNECE	  	,NIL})
									aAdd(aTitulo,{"E2_LOJA"		, (cAliasSE2)->E2_LOJA			,NIL})
									aAdd(aTitulo,{"E2_ORIGEM"	, (cAliasSE2)->E2_ORIGEM		,NIL})
									
									MSExecAuto({|x,y,z| FINA050(x,y,z)},aTitulo,,5)	//Exclui títulos à pagar
									lEstPed := !lMsErroAuto
									If lMsErroAuto
										MOSTRAERRO()
									Else
										lEstPed := .T.
										CN120EstSld(CND->CND_NUMMED)
									Endif
									
									(cAliasSE2)->(dbSkip())
								End
								(cAliasSE2)->(dbClosearea())
							EndIf

							//Tratamento para estorno de títulos antigos, gerados com o numero da medição e prefixo CTC
							If Empty(cNumTit) .And. Empty(cNumSC7) .And. CND->(FieldPos("CND_CTRMED")) > 0 .And. CND->CND_CTRMED == "2"
								cFilMed	 := PadR(CND->CND_FILIAL, TAMSx3("E2_FILORI")[1])
								cNumTit	 := PadR(CND->CND_NUMMED , TamSx3("E2_NUM")[1])
								cPrefixo := PadR("CTC" , TamSx3("E2_PREFIXO")[1])

								cAliasSE2 := GetNextAlias()
								BeginSql Alias cAliasSE2
									SELECT 	E2_FILIAL,
											E2_FILORIG,
											E2_PREFIXO,
											E2_NUM,
											E2_PARCELA,
											E2_TIPO,
											E2_FORNECE,
											E2_LOJA,
											E2_ORIGEM
									
									FROM 	%Table:SE2% SE2
									
									WHERE	SE2.E2_FILIAL	= %xFilial:SE2%	AND
											SE2.E2_FILORIG	= %exp:cFilMed%	AND
											SE2.E2_PREFIXO	= %exp:cPrefixo%	AND
											SE2.E2_NUM		= %exp:cNumTit%	AND
											SE2.%NotDel%
								EndSql

								While !lMsErroAuto .And. (cAliasSE2)->(!Eof())
									aTitulo := {}
									aAdd(aTitulo,{"E2_FILIAL"	, (cAliasSE2)->E2_FILIAL		,NIL})
									aAdd(aTitulo,{"E2_FILORIG"	, (cAliasSE2)->E2_FILORIG		,NIL})
									aAdd(aTitulo,{"E2_PREFIXO"	, (cAliasSE2)->E2_PREFIXO		,NIL})
									aAdd(aTitulo,{"E2_NUM"		, (cAliasSE2)->E2_NUM	  		,NIL})
									aAdd(aTitulo,{"E2_PARCELA"	, (cAliasSE2)->E2_PARCELA	  	,NIL})
									aAdd(aTitulo,{"E2_TIPO"		, (cAliasSE2)->E2_TIPO			,NIL})
									aAdd(aTitulo,{"E2_FORNECE"	, (cAliasSE2)->E2_FORNECE	  	,NIL})
									aAdd(aTitulo,{"E2_LOJA"		, (cAliasSE2)->E2_LOJA			,NIL})
									aAdd(aTitulo,{"E2_ORIGEM"	, (cAliasSE2)->E2_ORIGEM		,NIL})
									
									MSExecAuto({|x,y,z| FINA050(x,y,z)},aTitulo,,5)	//Exclui títulos à pagar
									lEstPed := !lMsErroAuto
									If lMsErroAuto
										MOSTRAERRO()
									Else
										lEstPed := .T.
										CN120EstSld(CND->CND_NUMMED)
									Endif
									
									(cAliasSE2)->(dbSkip())
								End
								(cAliasSE2)->(dbClosearea())
							EndIf
					
						Else
							If !Empty(cNumSC5)
								IncProc( STR0043 )//"Verificando pedido de venda"

								// PE para alterar filial antes de processar a exclusão do pedido de venda
								If ExistBlock("CN120PVA")
									ExecBlock("CN120PVA",.F.,.F.)
								EndIf

								MSExecAuto({|x,y,z| Mata410(x,y,z)},{{"C5_NUM",cNumSC5,NIL}},{},5) //Exclui pedido de venda

								// PE para alterar filial depois de processar a exclusão do pedido de venda
								If ExistBlock("CN120PVE")
									ExecBlock("CN120PVE",.F.,.F.)
								EndIf

								lEstPed := !lMsErroAuto
								If lMsErroAuto
									MostraErro()
								Endif
							EndIf

							If !Empty(cNumTit)
								IncProc(STR0121)//"Verificando título a receber"

								If ExistBlock("CN120PRE") // PE utilizado para alterar o prefixo do título financeiro
									cCN120PRE := ExecBlock("CN120PRE",.F.,.F.,{cRetPrf,"2"})
									If ValType(cCN120PRE) == "C"
										cRetPrf := cCN120PRE
									EndIf
								EndIf

								aTitulo := {}
								aAdd(aTitulo,{"E1_FILIAL"	, xFilial("SE1")	,NIL})
								aAdd(aTitulo,{"E1_FILORIG"	, cFilMed			,NIL})
								aAdd(aTitulo,{"E1_PREFIXO"	, cRetPrf			,NIL})
								aAdd(aTitulo,{"E1_NUM"		, cNumTit	  		,NIL})
								aAdd(aTitulo,{"E1_TIPO"		, cTpTit			,NIL})
								aAdd(aTitulo,{"E1_ORIGEM"	, "CNTA120"		,NIL})
								MSExecAuto({|x,y| FINA040(x,y)},aTitulo,5)

								lEstPed := !lMsErroAuto
								If lMsErroAuto
									MOSTRAERRO()
								Else
									CN120EstSld(CND->CND_NUMMED)
								EndIf
							EndIf

							//Tratamento para estorno de títulos antigos, gerados com o numero da medição e prefixo CTV
							If Empty(cNumTit) .And. Empty(cNumSC5) .And. CND->(FieldPos("CND_CTRMED")) > 0 .And. CND->CND_CTRMED == "2"
								cPrefixo 	:= Padr("CTV",TamSx3("E1_PREFIXO")[1])
								cNumTit	:= Padr(CND->CND_NUMMED , TamSx3("E1_NUM")[1])

								DbSelectArea("SE1")
								DbSetOrder(1)

								If dbSeek(xFilial("SE1")+cPrefixo+cNumTit)
									While SE1->(!Eof()) .And. Rtrim(SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM)) == Rtrim(CND->(CND_FILIAL+cPrefixo+cNumTit))
										aTitulo := {}
										aAdd(aTitulo,{"E1_FILIAL"	, xFilial("SE1")	,NIL})
										aAdd(aTitulo,{"E1_FILORIG"	, cFilMed			,NIL})
										aAdd(aTitulo,{"E1_PREFIXO"	, SE1->E1_PREFIXO	,NIL})
										aAdd(aTitulo,{"E1_NUM"		, SE1->E1_NUM	  	,NIL})
										aAdd(aTitulo,{"E1_TIPO"		, SE1->E1_TIPO	,NIL})
										aAdd(aTitulo,{"E1_PARCELA"	, SE1->E1_PARCELA	,NIL})

										MSExecAuto({|x,y| FINA040(x,y)},aTitulo,5)
										If lMsErroAuto
											Exit
										EndIf
										SE1->(dbSkip())
									EndDo

									lEstPed := !lMsErroAuto
									If lMsErroAuto
										MOSTRAERRO()
									Else
										lEstPed := .T.
										CN120EstSld(CND->CND_NUMMED)
									Endif
								EndIf
							EndIf
						EndIf
					Else
						lEstPed := .T.
						CN120EstSld(CND->CND_NUMMED)
					EndIf

					lEstPed := lEstPed .And. lEstExce

					If Empty(cNumTit) .AND. Empty(cNumSC7) .AND. Empty(cNumSC5)
						lEstPed := .T.
					EndIf

					If lEstPed
						CN9->(DbSetOrder(1))
						If CN9->(MsSeek(xFilial("CN9",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA))

							Cn120GCXJ(,2,CND->CND_CONTRA,CND->CND_NUMMED)

							lFixo  := Cn300RetSt("FIXO",0,CND->CND_NUMERO,,cFilCTR,.F.)
							lValor := Cn300RetSt("PREVFINANC",0,CND->CND_NUMERO,,cFilCTR,.F.)

							// Atualiza data fim da medicao
							dDtFim := CND->CND_DTFIM
							If nAcao == 1
								RecLock("CND",.F.)
								CND->CND_DTFIM := CTOD("")
								CND->CND_SITUAC := IIf(CND->CND_AUTFRN == '1','A','FA')
								CND->(MsUnlock())
							EndIf

						   	//³Ponto de lancamento contabil e orcamentario para estorno da medicao                ³
							PcoDetLan("000355","03","CNTA120",.T.)
							If lCtbOnLine
						    	nDet += DetProva(nHead,"699","CNTA120",cLoteGCT,,,,,,,,,{"CND",CND->(RECNO())})
							EndIf

							dbSelectArea("CNE")
							CNE->(dbSetOrder(1))
							cFilCod := xFilial("CNE")
							CNE->(MsSeek(cFilCod+CND->(CND_CONTRA+CND_REVISA+CND_NUMERO+CND_NUMMED)))
							IncProc( STR0015 )//"Atualizando Medição e Itens"

							If lFixo .Or. (!lFixo .And. lValor)
								//³ Atualiza saldo da planilha
								dbSelectArea("CNA")
								CNA->(dbSetOrder(1))
								If CNA->(MsSeek(xFilial("CNA",cFilCTR)+CND->(CND_CONTRA+CND_REVISA+CND_NUMERO)))
									If lEstSld .And. !lPeSld//Nao atualiza saldo quando o ponto de entrada CN120SLDCTR estiver ativo
										RecLock("CNA",.F.)
										CNA->CNA_SALDO += xMoeda(CND->CND_VLTOT - CN120VlExc(),CND->CND_MOEDA,CN9->CN9_MOEDA,dDtFim,TamSX3("CND_VLTOT")[2],,nTaxa)
										MsUnlock()
									EndIf

									If !Empty(CNA->CNA_CRONOG)
										cCronog := CNA->CNA_CRONOG
									EndIf
								EndIf
							EndIf

							//³ Atualiza saldo do contrato
							dbSelectArea("CN9")
							CN9->(dbSetorder(1))
							If CN9->(MsSeek(xFilial("CN9",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA))
								If lEstSld .And. !lPeSld//Nao atualiza saldo quando o ponto de entrada CN120SLDCTR estiver ativo
									RecLock("CN9",.F.)
									If lFixo .Or. lValor
										CN9->CN9_SALDO += xMoeda(CND->CND_VLTOT - CN120VlExc(),CND->CND_MOEDA,CN9->CN9_MOEDA,dDtFim,TamSX3("CND_VLTOT")[2],,nTaxa)
									Else
										CN9->CN9_VLATU -= xMoeda(CND->CND_VLTOT - CN120VlExc(),CND->CND_MOEDA,CN9->CN9_MOEDA,dDtFim,TamSX3("CND_VLTOT")[2],,nTaxa)//Atualiza valor do contrato
										If Empty(CN9->CN9_REVISA)//Se contrato original atualiza valor inicial
											CN9->CN9_VLINI -= xMoeda(CND->CND_VLTOT - CN120VlExc(),CND->CND_MOEDA,CN9->CN9_MOEDA,dDtFim,TamSX3("CND_VLTOT")[2],,nTaxa)
										EndIf
									EndIf
									MsUnlock()
								EndIf
								lMedeve := Cn300RetSt("MEDEVE",0,CND->CND_NUMERO,,,.F.)
								lFisico := (!lMedeve .And.Cn300RetSt("FISICO",0,CND->CND_NUMERO,,,.F.))
							EndIf

							If lFisico
								cFilCNS := xFilial("CNS",cFilCTR)
							EndIf

							If !lMedEve
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
								//- Atualiza saldo do cronograma quando nao houver medicao eventual                                ³
								dbSelectArea("CNF")
								If !Empty(CND->CND_PARCEL)
									CNF->(dbSetorder(3))
									CNF->(MsSeek(xFilial("CNF",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA+cCronog+CND->CND_PARCEL))
								Else
									CNF->(dbSetorder(2))
									CNF->(MsSeek(xFilial("CNF",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA+cCronog+CND->CND_COMPET))
								EndIf

								If Found()
									cParcel := CNF->CNF_PARCEL
									If lEstSld .And. !lPeSld//Nao atualiza saldo quando o ponto de entrada CN120SLDCTR estiver ativo
										RecLock("CNF")
										CNF->CNF_VLREAL -= xMoeda(CND->CND_VLTOT - CN120VlExc(),CND->CND_MOEDA,CN9->CN9_MOEDA,dDtFim,TamSX3("CND_VLTOT")[2],,nTaxa)
										CNF->CNF_SALDO  += xMoeda(CND->CND_VLTOT - CN120VlExc(),CND->CND_MOEDA,CN9->CN9_MOEDA,dDtFim,TamSX3("CND_VLTOT")[2],,nTaxa)
										If CNF->CNF_VLREAL == 0
											CNF->CNF_DTREAL := CTOD("")
										Else
											// Atualiza a data de realizacao do Cronograma quando estornar medição parcial
											aAreaCND := CND->(GetArea())
											CNF->CNF_DTREAL := CTOD("")
											CND->(dbSkip(-1))
											While !CND->(Bof())
												If CND->(CND_CONTRA+CND_REVISA) = CNF->(CNF_CONTRA+CNF_REVISA) .And. Empty(CNF->CNF_DTREAL)
													If 	!Empty(CND->CND_DTFIM) .And. CND->CND_PARCEL = CNF->CNF_PARCEL .And. ;
														(Empty(CNF->CNF_DTREAL) .Or. CND->CND_DTFIM > CNF->CNF_DTREAL)
														CNF->CNF_DTREAL := CND->CND_DTFIM
													Endif
												EndIf
												CND->(dbSkip(-1))
											EndDo
											RestArea(aAreaCND)
										EndIf
										MsUnlock()

										If (GetNewPar( "MV_CNPROVI" ,  "S" ) == "S")
											IncProc( STR0021 )//"Processando títulos provisórios"

											CN100ETit(CND->CND_CONTRA,CND->CND_REVISA,cCronog,CNF->CNF_PARCEL,cFilCtr)
											If CNF->CNF_SALDO > 0
												CN100CTit(CND->CND_CONTRA,CND->CND_REVISA,cCronog,CNF->CNF_PARCEL,CNF->CNF_SALDO,cFilCtr)
											EndIf
										EndIf
									EndIf
								EndIf
							EndIf

							If lEstSld .And. !lPeSld // Atualiza itens da planilha
								RecLock("CND",.F.) //Limpa codigo do titulo e pedido
								CND->CND_PEDIDO := CriaVar("CND_PEDIDO",.F.)
								CND->CND_NUMTIT := CriaVar("CND_NUMTIT",.F.)
								MsUnlock()

								While !CNE->(Eof()) .And. CNE->(CNE_FILIAL+CNE_CONTRA+CNE_REVISA+CNE_NUMERO+CNE_NUMMED) == cFilCod+CND->(CND_CONTRA+CND_REVISA+CND_NUMERO+CND_NUMMED)
									lMedComPlan := .F.
									RecLock("CNE") //Limpa o pedido do item de medicao
									CNE->CNE_PEDIDO := ""
									MsUnlock()

									//- Atualiza saldo dos itens da planilha itens excedentes nao atualizam saldos
									If CNE->CNE_EXCEDE == '2'
										dbSelectArea("CNB")
										CNB->(dbSetOrder(1))
										If CNB->(MsSeek(xFilial("CNB",cFilCTR)+CNE->(CNE_CONTRA+CNE_REVISA+CNE_NUMERO+CNE_ITEM)))
											RecLock("CNB",.F.)
										 	If nServico == 1
												CNB->CNB_QTDMED -= CNE->CNE_QUANT
												CNB->CNB_SLDMED += IIf(Cn300RetSt("SEMIFIXO",0,CNE->CNE_NUMERO),0,CNE->CNE_QUANT)
											Else
												CNB->CNB_QTDMED -= ( ( CNE->CNE_VLTOT / CNB->CNB_VLTOT ) * CNB->CNB_QUANT )
												CNB->CNB_SLDMED += IIf(Cn300RetSt("SEMIFIXO",0,CNE->CNE_NUMERO),0,( ( CNE->CNE_VLTOT / CNB->CNB_VLTOT ) * CNB->CNB_QUANT ))
											EndIf
											MsUnlock()

											//CAPTURO A VARIAVEL FLAG DE ITENS COM PLANILHA
											lMedComPlan := .T.
										EndIf

										If lFisico
											dbSelectArea("CNS")
											CNS->(dbSetOrder(1))
											If CNS->(MsSeek(cFilCNS+CND->CND_CONTRA+CND->CND_REVISA+cCronog+cParcel+CNE->CNE_ITEM))
												RecLock("CNS",.F.)
												CNS->CNS_RLZQTD -= CNE->CNE_QUANT
												CNS->CNS_SLDQTD += CNE->CNE_QUANT
												MsUnlock()
											EndIf
										EndIf
									EndIf

									PcoDetLan("000355","04","CNTA120",.T.)

									If lCtbOnLine //CONTABILIZA ESTORNO DA MEDICAO - ITENS DO CONTRATO

										nLp69B := aScan(aLPGCT,{|x| x[1]=="69B"})
										nLp69I := aScan(aLPGCT,{|x| x[1]=="69I"})

										If lUsaFlag
											aAdd( aFlagCTB, {"CNE_DTLANC", dDataBase, "CNE", CNE->( Recno() ), 0, 0, 0} )
										EndIf

										If aLPGCT[nLp69I,2]  .And. cEspCtr == '2' .And. CN9->CN9_DTINIC >= CTOD("01/01/2018") // - Ponto de lançamento padrão IFRS15
											nDet += DetProva(nHead,'69I',cOrigem,cLoteGCT,,,,,,,,@aFlagCTB,{"CNE",CNE->(Recno())})
											lCtbCNE := .T.
										ElseIf aLPGCT[nLp69B,2]
											nDet += DetProva(nHead,"69B","CNTA120",cLoteGCT,,,,,,,,,{"CNE",CNE->(Recno())})
											lCtbCNE := .T.
										EndIf

										If !lUsaFlag .And. lCtbCNE
											If CNE->(Columnpos('CNE_DTLANC')) > 0
												dbSelectArea("CNE")
												RecLock("CNE",.F.)
												CNE->CNE_DTLANC := dDataBase
												MsUnlock()
											EndIf
										EndIf

									EndIf

									If lMedComPlan
										cLancCont := "69F"
										cSeqPCOLan:= "06"
									Else
										cLancCont := "69D"
										cSeqPCOLan:= "05"
									Endif

									cBusca :=  xFilial( "CNE" , cFilCTR) +;
												Padr( CNE->CNE_CONTRA	, nTamContra )	+;
												Padr( CNE->CNE_REVISA	, nTamRevisa )	+;
												Padr( CNE->CNE_NUMMED	, nTamNumMed )	+;
												Padr( CNE->CNE_ITEM		, nTamItem )

									CNZ->(dbSetOrder(2)) //CNZ_FILIAL+CNZ_CONTRA+CNZ_REVISA+CNZ_NUMMED+CNZ_ITCONT+CNZ_ITEM

									If CNZ->( dbSeek( cBusca ) )
				                     	While CNZ->( !Eof() ) .and. cBusca == 	xFilial( "CNZ" , cFilCTR ) +;
				                            										Padr( CNZ->CNZ_CONTRA	, nTamContra )	+;
																					Padr( CNZ->CNZ_REVISA	, nTamRevisa )	+;
																					Padr( CNZ->CNZ_NUMMED	, nTamNumMed )	+;
																					Padr( CNZ->CNZ_ITCONT	, nTamItem )

											PcoDetLan("000355",cSeqPCOLan,"CNTA120",.T.)
											If lCtbOnLine
												//CONTABILIZA OS RATEIOS DO ITEM DO CONTRATO COM PLANILHA.
												//SE HA PLANILHA, ENTAO NAO PODERA CONTABILIZAR O RATEIO SEM PLANILHA, ABAIXO (CONTROLAR COM VARIAVEL FLAG)
												//EFETUA A CONTABILIZACAO DOS RATEIOS DO ITEM DO CONTRATO SEM PLANILHA,
												nDet	+= DetProva(nHead,cLancCont,"CNTA120",cLoteGCT,,,,,,,,,{"CNZ",CNZ->(RECNO())})
											Endif
											CNZ->(DbSkip())
										EndDo
									EndIf
									dbSelectArea("CNE")
									CNE->(dbSkip())
								EndDo
							EndIf
							IncProc( STR0016 )//"Atualizando Saldos"
							If lPeSld//Chama ponto de entrada para atualizacao do saldo
								ExecBlock("CN120ESSLD",.f.,.f.,{lMedEve,lFisico,cCronog,lFixo,lValor})
							EndIf

							//- Estorna o historico de multas / bonificacoes do contrato
							CN120HistMul( 2, NIL, CND->CND_CONTRA, CND->CND_NUMMED )//estor. historico

							//- Executa ponto de entrada para estorno da medicao ³
							If ExistBlock("CN120ESTMD")
								If cEspCtr == "1"
									ExecBlock("CN120ESTMD",.F.,.F.,{cNumSC7})
								Else
									ExecBlock("CN120ESTMD",.F.,.F.,{cNumSC5})
								EndIf
							EndIf
						EndIf

						//³ Estorna o valor retido da caucao ³
						If !Empty(CND->CND_RETCAC)
							CN120CaucRet(CND->CND_CONTRA,CND->CND_NUMMED,2,CND->CND_RETCAC)
						EndIf
					EndIf
				End Transaction

			     //³ Executa ponto de entrada para estorno da medicao ³
				If ExistBlock("CN120ESMED")
					If cEspCtr == "1"
						ExecBlock("CN120ESMED",.F.,.F.,{cNumSC7})
					Else
						ExecBlock("CN120ESMED",.F.,.F.,{cNumSC5})
					EndIf
				EndIf

				PcoFinLan("000355")
				If !lAuto
					If lAviso
						If !lEstPed
							If !Empty(cNumSC7) .Or. !Empty(cNumSC5)
								Aviso("CNTA120",OemToAnsi(STR0031)+If(!Empty(cNumSC7),cNumSC7,cNumSC5)+OemToAnsi(STR0032),{STR0155})//"O pedido "##" não pode ser estornado"
							ElseIf !Empty(cNumTit)
							    Aviso("CNTA120",OemToAnsi(STR0145)+cNumTit+OemToAnsi(STR0032),{STR0155})//"O titulo "##" não pode ser estornado"
							EndIf
						Else
							If !lAprRev
						     If nTipo == 1  .And. nServico == 1
						        Aviso("CNTA120",OemToAnsi(STR0033),{STR0155})//"Medição/entrega estornada com sucesso"
						     ElseIf nTipo == 2
						        Aviso("CNTA120",OemToAnsi(STR0064),{STR0155})//"Autorização de fornecimento estornada com sucesso"
						     Else
						        Aviso("CNTA120",OemToAnsi(STR0086),{STR0155})//"Autorização de fornecimento estornada com sucesso"
						     EndIf
						EndIf
					EndIf
				EndIf
				EndIf
				lRet := lEstPed
			EndIf
		Else
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Seleciona a nota        ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			cQuery := "SELECT DISTINCT SF1.F1_DOC,  SF1.F1_SERIE,   SF1.F1_TIPO, "
			cQuery += "                SF1.F1_DUPL, SF1.F1_PREFIXO, F1_FORNECE, F1_LOJA "
			cQuery += "  FROM " + RetSQLName("SF1") + " SF1, " + RetSQLName("SD1") + " SD1 "
			cQuery += " WHERE SF1.F1_FILIAL  = '" + xFilial("SF1") + "'"
			cQuery += "   AND SD1.D1_FILIAL  = '" + xFilial("SD1") + "'"
			cQuery += "   AND SF1.F1_DOC     = SD1.D1_DOC     "
			cQuery += "   AND SF1.F1_SERIE   = SD1.D1_SERIE   "
			cQuery += "   AND SF1.F1_TIPO    = SD1.D1_TIPO    "
			cQuery += "   AND SF1.F1_FORNECE = SD1.D1_FORNECE "
			cQuery += "   AND SF1.F1_LOJA    = SD1.D1_LOJA    "
			cQuery += "   AND SD1.D1_PEDIDO  = '" + CND->CND_PEDIDO + "'"
			cQuery += "   AND SF1.D_E_L_E_T_ = ' ' "
			cQuery += "   AND SD1.D_E_L_E_T_ = ' ' "

			cQuery    := ChangeQuery( cQuery )
			cAliasQry := GetNextAlias()
			dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQuery ), cAliasQry, .F., .T. )

			If !(cAliasQry)->(Eof())
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Verifica os valores dos titulos ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				cQuery := "SELECT SUM(E2_VALOR) AS E2_VALOR,SUM(E2_SALDO) AS E2_SALDO "
				cQuery += "  FROM " + RetSQLName("SE2") + " SE2 "
				cQuery += " WHERE SE2.E2_FILIAL  = '" + xFilial("SE2") + "'"
				cQuery += "   AND SE2.E2_NUM     = '" + (cAliasQry)->F1_DUPL + "'"
				cQuery += "   AND SE2.E2_PREFIXO = '" + IIf(Empty((cAliasQry)->F1_PREFIXO),&(SuperGetMV("MV_2DUPREF")),(cAliasQry)->F1_PREFIXO) + "'"
				cQuery += "   AND SE2.E2_FORNECE = '" + (cAliasQry)->F1_FORNECE + "'"
				cQuery += "   AND SE2.E2_LOJA    = '" + (cAliasQry)->F1_LOJA + "'"
				cQuery += "   AND SE2.E2_TIPO    = 'NF '"
				cQuery += "   AND SE2.D_E_L_E_T_ = ' '"

				cQuery    := ChangeQuery( cQuery )
				cAliasSE2 := GetNextAlias()
				dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQuery ), cAliasSE2, .F., .T. )

				TCSetField( cAliasSE2, "E2_VALOR", "N", TamSX3("E2_VALOR")[1], TamSX3("E2_VALOR")[2] )
				TCSetField( cAliasSE2, "E2_SALDO", "N", TamSX3("E2_SALDO")[1], TamSX3("E2_SALDO")[2] )

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Verifica se houve movimentacoes nos titulos ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If (cAliasSE2)->E2_VALOR > (cAliasSE2)->E2_SALDO
					Aviso("CNTA120",OemToAnsi(STR0058)+(cAliasQry)->F1_DOC+"/"+ SerieNfID("SF1", 2, "F1_SERIE") +OemToAnsi(STR0059),{STR0155})//STR0058"Não foi possível estornar a autorização de fornecimento, pois a NFE: "##" possui movimentações financeiras."
					lBloqSE2 := .T.
				EndIf

				(cAliasSE2)->(dbCloseArea())

				If !lBloqSE2 .And. lGCTBloq
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Seleciona os titulos ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					cQuery := "SELECT SE2.R_E_C_N_O_ AS RECNO "
					cQuery += "  FROM " + RetSQLName("SE2") + " SE2 "
					cQuery += " WHERE SE2.E2_FILIAL  = '" + xFilial("SE2") + "'"
					cQuery += "   AND SE2.E2_NUM     = '" + (cAliasQry)->F1_DUPL + "'"
					cQuery += "   AND SE2.E2_PREFIXO = '" + IIf(Empty((cAliasQry)->F1_PREFIXO),&(SuperGetMV("MV_2DUPREF")),(cAliasQry)->F1_PREFIXO) + "'"
					cQuery += "   AND SE2.E2_FORNECE = '" + (cAliasQry)->F1_FORNECE + "'"
					cQuery += "   AND SE2.E2_LOJA    = '" + (cAliasQry)->F1_LOJA + "'"
					cQuery += "   AND SE2.E2_TIPO    = 'NF '"
					cQuery += "   AND SE2.D_E_L_E_T_ = ' '"

					cQuery    := ChangeQuery( cQuery )
					cAliasSE2 := GetNextAlias()
					dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQuery ), cAliasSE2, .F., .T. )

					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Bloqueia os titulos ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					While !(cAliasSE2)->(Eof())
						SE2->(MsGoTo((cAliasSE2)->RECNO))

						RecLock("SE2",.F.)
							SE2->E2_MSBLQL := "1"
						MsUnlock()

						(cAliasSE2)->(dbSkip())
					EndDo

					(cAliasSE2)->(dbCloseArea())
				EndIf
			EndIf

			(cAliasQry)->(dbCloseArea())

			If !lBloqSE2
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Atualiza data fim da medicao                    ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				RecLock("CND",.F.)
					CND->CND_DTFIM := CTOD("")
					CND->CND_SITUAC := IIf(CND->CND_AUTFRN == '1','A','FA')
				MsUnlock()

				lRet := .T.
			EndIf
		EndIf
	Else
		Help( " ", 1, "CNTA120_06")//Nao encerrada
	EndIf
EndIf

If lCtbOnLine
	RodaProva(nHead,nDet)
	If nDet > 0
		cA100Incl(cArqGCT,nHead,1,cLoteGCT,lDigita,lAglutina,,,,@aFlagCTB)
		aFlagCTB := {}
	Endif
EndIf

Return lRet

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³CN120HistMul³ Autor ³ Sergio Silveira     ³ Data ³04/08/2006 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Efetua a manutencao do historico das multas nas medicoes    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ A103HistMul( ExpN1,ExpA2,ExpC3,ExpC4,ExpC5,ExpC6)           ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpN1 -> Tipo : 1 - Inclusao / 2 - Exclusao                 ³±±
±±³          ³ ExpA2 -> Array de multas                                    ³±±
±±³          ³ ExpC3 -> Documento                                          ³±±
±±³          ³ ExpC4 -> Serie                                              ³±±
±±³          ³ ExpC5 -> Fornecedor                                         ³±±
±±³          ³ ExpC6 -> Loja                                               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T.                                                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ Materiais                                                   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Function CN120HistMul( nTipo, aMultas, cContra, cNumMed )

Local cHora     := ""
Local cAliasQry := ""
Local cQuery    := ""

Local nLoop     := 0

If nTipo == 1
	cHora := Time()

	For nLoop := 1 to Len( aMultas )
		RecLock( "CNG", .T. )
			CNG->CNG_FILIAL  := xFilial( "CNG" )
			CNG->CNG_CONTRA  := cContra
			CNG->CNG_DATA    := dDataBase
			CNG->CNG_HORA    := cHora
			CNG->CNG_VALOR   := aMultas[ nLoop, 1 ]
			CNG->CNG_DESCRI  := aMultas[ nLoop, 2 ]
			CNG->CNG_TIPO    := aMultas[ nLoop, 3 ]
			CNG->CNG_NUMMED  := cNumMed
		CNG->( MsUnlock() )
	Next nLoop

Else

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Exclui o historico desta NF no contrato                                ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	cAliasQry := GetNextAlias()

	cQuery := "SELECT R_E_C_N_O_ CNGRECNO "
	cQuery += "  FROM " + RetSqlName( "CNG" )
	cQuery += " WHERE CNG_NUMMED = '"  + cNumMed + "'"
	cQuery += "   AND D_E_L_E_T_ = ' '"

	cQuery := ChangeQuery( cQuery )
	dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQuery ), cAliasQry, .F., .T. )

	While !( cAliasQry )->( Eof() )

		CNG->( MsGoto( ( cAliasQry )->CNGRECNO ) )

		RecLock( "CNG", .F. )
			CNG->( dbDelete())
		CNG->( MsUnlock())

		( cAliasQry )->( dbSkip() )

	EndDo

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Exclui a area de trabalho da query                                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	( cAliasQry )->( dbCloseArea() )

EndIf

Return( .t. )


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³CN120Impr ºAutor  ³Fabio Alves         º Data ³  28/09/06   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Efetua a impressao da medicao dentro da rotina             º±±
±±º          ³ Medicoes/Entregas.                                         º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³CNTA120                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function CN120Impr(cAlias,nReg)
dbSelectArea("CND")
CND->(dbSetOrder(1))
CND->(MsGoTo(nReg))
CNTR030(CND->CND_NUMMED)

Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³MenuDef   ³ Autor ³ Fabio Alves Silva     ³ Data ³24/10/2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Utilizacao de menu Funcional                               ³±±
±±³          ³                                                            ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Array com opcoes da rotina.                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³Parametros do array a Rotina:                               ³±±
±±³          ³1. Nome a aparecer no cabecalho                             ³±±
±±³          ³2. Nome da Rotina associada                                 ³±±
±±³          ³3. Reservado                                                ³±±
±±³          ³4. Tipo de Transa‡„o a ser efetuada:                        ³±±
±±³          ³		1 - Pesquisa e Posiciona em um Banco de Dados         ³±±
±±³          ³    2 - Simplesmente Mostra os Campos                       ³±±
±±³          ³    3 - Inclui registros no Bancos de Dados                 ³±±
±±³          ³    4 - Altera o registro corrente                          ³±±
±±³          ³    5 - Remove o registro corrente do Banco de Dados        ³±±
±±³          ³5. Nivel de acesso                                          ³±±
±±³          ³6. Habilita Menu Funcional                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   DATA   ³ Programador   ³Manutencao efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

Static Function MenuDef()
Local aExcede := {	{STR0091, "CN120ExceM" , 0, 13, 0, NIL},; //-- "p / medição encerrada"
					{STR0092, "CN120ExceC" , 0, 14, 0, NIL}	} //-- "p / competência não prevista"

PRIVATE aRotina	:= { 	{ STR0002, "AxPesqui"  	, 0, 1, 0,.F.},;//"Pesquisar"
								{ STR0003, "CN130Manut"	, 0, 2, 0, nil},;//"Visualizar"
								{ STR0004, "CN120Inc"   , 0, 3, 0, nil},;//"Incluir"
								{ STR0005, "CN120Manut" , 0, 4, 0, nil},;//"Alterar"
								{ STR0006, "CN120Manut"	, 0, 5, 0, nil},;//"Excluir"
								{ STR0007, "CN120Ence"	, 0, 6, 0, nil},;//"Encerrar"
								{ STR0018, "CN120Estor"	, 0, 7, 0, nil},; //"Estornar"
								{ STR0042, "CN120Leg"	, 0, 8, 0, .F.},; //"Legendas"
								{ STR0051, "CN120Aut"	, 0, 3, 0, .F.},; //"Aut. Fornec."
								{ STR0038, "CN120Impr"	, 0, 9, 0, nil},;//"Imprimir"
		    					{ STR0067, "MsDocument" , 0, 4, 0, nil},; //"Conhecimento"
		    					{ STR0087, "CN120Serv" , 0, 3, 0, .F.}}  //"Med. Serviços."

If SuperGetMV("MV_CNBTEXC",.F.,"N") == "S"
	If Type("lAuto") == "L" .And. lAuto
		aEval(aExcede,{|x| aAdd(aRotina, x)})
	Else
		aAdd(aRotina,{ STR0093, aExcede	, 0, 13, 0, nil}) //Excedente
	EndIf
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Ponto de entrada utilizado para inserir novas opcoes no array aRotina  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If ExistBlock("CTA120MNU")
	ExecBlock("CTA120MNU",.F.,.F.)
EndIf
Return(aRotina)




/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³CN120Aut  ³ Autor ³ Marcelo Custodio   ³ Data ³06/01/2009³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Inclusao da Autorizacao de fornecimento                 ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function CN120Aut(cAlias,nReg,nOpc)

CN120Inc(cAlias,nReg,nOpc,,2)

Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³CN120Serv ³ Autor ³ Aline Sebrian      ³ Data ³30/07/2011³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Inclusao da Medicao de Servicos                         ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function CN120Serv(cAlias,nReg,nOpc)

CN120Inc(cAlias,nReg,nOpc,,,2)

Return


/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³CNDMedEsp ³ Autor ³ Aline Sebrian         ³ Data ³07/10/2009 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Gera consulta especifica do contrato à Medição              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ CNTA090                                                     ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function CNDMedEsp()
Local aArea     := GetArea()
Local aGrp   	:= {}
Local aTamCab	:= {}
Local aButtons	:= {}
Local aCN120CMP := {}

Local cGrps     := ""
Local cQuery    := ""
Local cQuery1   := ""
Local cQuery2   := ""
Local cQuery3   := ""
Local cQuery4   := ""
Local cQuery5   := ""
Local cCod      := RetCodUsr()
Local cQueryPE  := ""

Local lVldVige  := GetNewPar("MV_CNFVIGE","N") == "N"
Local lRet      := .F.
Local lPedVenda := IsInCallStack('A410KeyF9') .And. !Empty(M->C5_CLIENTE)
Local lPIMS		:= SuperGetMV('MV_CNXPIMS',.F.,.F.)

Local nSavQual  := 0
Local nX        := 0
Local nOpca		:= 0
Local nNovaOrd	:= 0
Local oQual
Local oDlg
Local oSize

Local lAutForn	:= Cn121GAutF()

PRIVATE aCab	   := {}
PRIVATE aCampos	   := {}
PRIVATE aArrayF4   := {}

dbSelectArea("CNN")
dbSetOrder(1)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Carrega Grupos do usuario                    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
aGrp := UsrRetGrp(UsrRetName(cCod))

For nX:=1 to len(aGrp)
	cGrps += "'"+aGrp[nX]+"',"
Next
cGrps := SubStr(cGrps,1,len(cGrps)-1)

cQuery1 := " SELECT "
cQuery1 += " CN9_NUMERO,"
cQuery1 += " MAX(CN9_REVISA) AS CN9_REVISA,"
cQuery1 += " CN9_FILCTR "
cQuery1 += " FROM "
cQuery1 += RetSqlName("CN9") + " CN9, "
cQuery1 += RetSqlName("CN1") + " CN1, "
cQuery1 += RetSqlName("CNN") + " CNN, "
cQuery1 += RetSqlName("CPD") + " CPD  "

If lPedVenda
	cQuery1 += ", "+ RetSqlName("CNC") + " CNC "
EndIf

cQuery1 += " WHERE "
If IsInCallStack('CNTVldCTR')
	cQuery1 += " CN9.CN9_NUMERO = '" + cContra + "' AND "
EndIf
cQuery1 += " CN9.CN9_SITUAC =  '05' AND "
cQuery1 += " CN9.CN9_FILCTR <> '"+Space(TamSX3("CN9_FILCTR")[1])+"'   AND "
cQuery1 += " CN9.CN9_REVATU   = '"+Space(TamSX3("CN9_REVATU")[1])+"' AND "

If (IsInCallStack('CNTA121') .And. lAutForn) .OR. (lPIMS) 
	cQuery1 += " CN1.CN1_FILIAL = CN9.CN9_FILCTR AND "
	cQuery1 += " CN1.CN1_CODIGO = CN9.CN9_TPCTO  AND "
	cQuery1 += " CN1.D_E_L_E_T_ = ' ' 			 AND "
	If lPIMS .And. CN1->(Columnpos('CN1_INTEGR')) > 0
		cQuery1 += " CN1.CN1_INTEGR = 'F' AND"
	EndIf
	If (IsInCallStack('CNTA121') .And. lAutForn)
		cQuery1 += " CN1.CN1_ESPCTR = 1 AND "			
	EndIf
EndIF

cQuery1 += " CPD.CPD_FILAUT = '"+cFilAnt+"' AND "
cQuery1 += " CPD.CPD_FILIAL = CN9.CN9_FILIAL AND "
cQuery1 += " CPD.CPD_CONTRA = CN9.CN9_NUMERO AND "

If lVldVige
	cQuery1 += " ('"+DToS(dDataBase)+"' BETWEEN CN9_DTINIC AND CN9_DTFIM )  AND "
EndIf

cQuery1+= " CNN.CNN_FILIAL = CN9_FILIAL AND "
cQuery1+= " CNN.CNN_CONTRA = CN9_NUMERO AND "

cQuery2 := " CN9_VLDCTR ='2' "
cQuery3 := " CN9_VLDCTR IN(' ','1') AND (CNN.CNN_USRCOD   = '"+ cCod +"'"

If len(aGrp) > 0
	cQuery3 += " OR CNN.CNN_GRPCOD IN ("+ cGrps +"))"
Else
    cQuery3 += ")"
EndIf

If lPedVenda
	cQuery4 += " AND CNC.CNC_FILIAL = CN9_FILIAL "
	cQuery4 += " AND CNC.CNC_NUMERO = CN9_NUMERO "
	cQuery4 += " AND CNC.CNC_CLIENT = '"+M->C5_CLIENTE+"'"
	If !Empty(M->C5_LOJACLI)
		cQuery4 += " AND CNC.CNC_LOJACL = '"+M->C5_LOJACLI+"'"
	EndIf
	cQuery4 += " AND CNC.D_E_L_E_T_	= '' "
EndIf

cQuery4 := " AND CNN.D_E_L_E_T_	= '' "
cQuery4 += " AND CN9.D_E_L_E_T_	= '' "
cQuery4 += " AND CPD.D_E_L_E_T_	= '' "
cQuery4 += " GROUP BY CN9_NUMERO"

cQuery4 += ", CN9_FILCTR "

cQuery5 := " ORDER BY CN9_NUMERO,CN9_REVISA"

cQuery5 += ", CN9_FILCTR "

cQuery := cQuery1
cQuery += cQuery2+" "+cQuery4
cQuery += " UNION "
cQuery += cQuery1
cQuery += cQuery3+" "+cQuery4+" "+cQuery5

// FSW - Ponto de entrada para refazer a query retirando os contratos compartilhados
If Existblock('CN120QCC')
	cQueryPE := Execblock('CN120QCC', .F., .F., {cQuery1, cQuery2, cQuery3, cQuery4, cQuery5})
	cQuery   := If(ValType(cQueryPE)=='C', cQueryPE, cQuery)
Endif

If Existblock('CN120ESY')
	cQueryPE := Execblock('CN120ESY', .F., .F., {cQuery})
	cQuery   := If(ValType(cQueryPE)=='C', cQueryPE, cQuery)
Endif

cQuery := ChangeQuery(cQuery)
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TRBCN9",.F.,.T.)

If !TRBCN9->(Eof())
	
	AAdd( aCab, GetSx3Cache( "CN9_NUMERO", "X3_TITULO" ) )
	Aadd( aCampos, { "CN9_NUMERO", GetSx3Cache( "CN9_NUMERO", "X3_TIPO" ), GetSx3Cache( "CN9_NUMERO", "X3_CONTEXT" ),GetSx3Cache( "CN9_NUMERO", "X3_PICTURE" ) } )
	
	AAdd( aCab, GetSx3Cache( "CN9_REVISA", "X3_TITULO" ) )
	Aadd( aCampos, { "CN9_REVISA", GetSx3Cache( "CN9_REVISA", "X3_TIPO" ), GetSx3Cache( "CN9_REVISA", "X3_CONTEXT" ),GetSx3Cache( "CN9_REVISA", "X3_PICTURE" ) } )

	AAdd( aCab, GetSx3Cache( "CN9_FILCTR", "X3_TITULO" ) )
	Aadd( aCampos, { "CN9_FILCTR", GetSx3Cache( "CN9_FILCTR", "X3_TIPO" ), GetSx3Cache( "CN9_FILCTR", "X3_CONTEXT" ),GetSx3Cache( "CN9_FILCTR", "X3_PICTURE" ) } )

	If Existblock('CN120CMP')
		aCN120CMP :=	Execblock('CN120CMP', .F., .F., {aCab,aCampos})

		If Valtype(aCN120CMP) == "A"
			If Len(aCN120CMP)>=1 .And. Valtype(aCN120CMP[1]) == "A"
				aCab   := aClone(aCN120CMP[1])
			EndIf

			If Len(aCN120CMP)>=2 .And. Valtype(aCN120CMP[2]) == "A"
				aCampos:= aClone(aCN120CMP[2])
			EndIf
		Endif
	EndIf
EndIf

While !TRBCN9->(Eof())
	Aadd(aArrayF4,Array(Len(aCampos)))

	For nX := 1 to Len(aCampos)
		aArrayF4[Len(aArrayF4)][nX] := TRBCN9->(FieldGet(FieldPos(aCampos[nX][1])))
	Next
	dbSelectArea("TRBCN9")
	dbSkip()
EndDo

TRBCN9->(dbCloseArea())

If !Empty(aArrayF4)
	aButtons		:= {{'pesquisa',{||C120PesqP(aCab,aCampos,aArrayF4,oQual)},OemToAnsi(STR0079),OemToAnsi(STR0002)} } //"Pesquisar"

	SetKey( VK_F4, { ||C120PesqP(aCab,aCampos,aArrayF4,oQual) } )
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Monta dinamicamente o bline do CodeBlock                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	DEFINE MSDIALOG oDlg FROM 000,000  TO 340,540 TITLE OemToAnsi(STR0073) Of oMainWnd PIXEL

	oSize := FwDefSize():New(.T.,,,oDlg)

	oSize:AddObject( "LABEL"    ,  100, 10, .T., .F. ) // Nao dimensiona Y
	oSize:AddObject( "GRID"  	,  100, 90, .T., .T. ) // Totalmente dimensionavel

	oSize:lProp := .T. // Proporcional
	oSize:aMargins := { 3, 3, 3, 3 } // Espaco ao lado dos objetos 0, entre eles 3

	oSize:Process() // Dispara os calculos

	@ oSize:GetDimension('LABEL','LININI'),oSize:GetDimension('LABEL','COLINI')  SAY OemToAnsi(STR0074) Of oDlg PIXEL SIZE 120 ,9 //"Selecione o Contrato"

	oQual := TWBrowse():New( oSize:GetDimension('GRID','LININI'),oSize:GetDimension('GRID','COLINI'),;
					 			oSize:GetDimension('GRID','XSIZE'),oSize:GetDimension('GRID','YSIZE'),;
					 			,aCab,aTamCab,oDlg,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
	oQual:SetArray(aArrayF4)
	oQual:bLine      := { || aArrayF4[oQual:nAT] }
	oQual:blDblClick := {|| nSavQual:=oQual:nAT,nOpcA := 1,oDlg:End()}


	ACTIVATE MSDIALOG oDlg CENTERED ON INIT EnchoiceBar(oDlg,{|| nSavQual:=oQual:nAT,nOpca:=1,oDlg:End()},{||oDlg:End()},,aButtons)

	If nOpcA == 1
		dbSelectArea("CN9")
		CN9->(dbSetOrder(1))

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Posiciona no registro da CN9 selecionado        ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cFilCTR := If(Len(aArrayF4[nSavQual]) >= 3,aArrayF4[nSavQual,3],cFilAnt)
		lRet := CN9->(dbSeek(xFilial("CN9",cFilCTR)+aArrayF4[ nSavQual, 1 ]+aArrayF4[ nSavQual,2 ]))

	EndIF
	//Desabilita na tela da medicao do contrato a tecla F4
	SetKey( VK_F4, Nil )
EndIf

If aArea[1] <> 'CN9' 
	RestArea(aArea)
EndIf

Return lRet


/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³cn120VTip9 ³  Autor³ Aline Sebrian         ³ Data ³ 17.12.09 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³Verifica se os vencimentos digitados na medicao  sao menores ³±±
±±³          ³que a data de emissao da medicao.                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ Cnta120                                                     ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function cn120VTip9()
Local cVar := &(ReadVar())
Local cAlias := Alias()
Local lRet   := .T.

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Somente obriga a digita‡ao da data do vencimento      ³
//³quando a condi‡„o de pagamento for tipo 9.            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
dbSelectArea("SE4")
dbSetOrder(1)
If MsSeek(xFilial("SE4")+M->CND_CONDPG)
	If SE4->E4_TIPO == "9"
		If DtoS(cVar) < DtoS(M->CND_DTINIC) .And. !Empty(cVar)
			Aviso("CNTA120",OemToAnsi(STR0071),{STR0155}) //"Data de Vencimento da parcela deve ser maior ou igual a data de emissão da Medição."
			lRet := .F.
		Endif
	Endif
Endif
dbSelectArea(cAlias)
Return lRet

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³c120PesqP ³ Autor ³ Aline Sebrian         ³ Data ³07.05.2010 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³Seek no browse de itens de pedidos de compra                 ³±±
±±³          ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ExpA1 : Array das descricoes dos cabecalhos                  ³±±
±±³          ³ExpA2 : Array com os campos                                  ³±±
±±³          ³ExpA3 : Array com os conteudos                               ³±±
±±³          ³ExpO4 : Objeto do listbox                                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Nenhum                                                       ³±±
±±³          ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³Esta rotina tem como objetivo abrir uma janela de pesquisa   ³±±
±±³          ³em browses de getdados poisicionando na llinha caso encontre ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ Generico                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function c120PesqP(aCab,aCampos,aArrayF4,oQual)

Local aCpoBusca	:= {}
Local aCpoPict	:= {}
Local aComboBox	:= { AllTrim( STR0075) , AllTrim( STR0076 ) , AllTrim( STR0077 ) } //"Exata"###"Parcial"###"Contem"

Local bAscan	:= { || .F. }

Local cPesq		:= Space(30)
Local cBusca	:= ""
Local cTitulo	:= OemtoAnsi(STR0002)  //"Pesquisar"
Local cOpcAsc	:= aComboBox[1]	//"Exata"
Local cAscan	:= ""

Local nOpca		:= 0
Local nPos		:= 0
Local nx		:= 0
Local nTipo		:= 1
Local nBusca	:= Iif(oQual:nAt == Len(aArrayF4) .Or. oQual:nAt == 1, oQual:nAt, oQual:nAt+1 )
Local cGetF3 	:= ""

Local oDlg
Local oBusca
Local oPesq1
Local oPesq2
Local oPesq3
Local oPesq4
Local oComboBox

For nX := 1 to Len(aCampos)
	AAdd(aCpoBusca,aCab[nX])
	If (Empty(aCampos[nX][4]))
		AAdd(aCpoPict,"@!")
		aCampos[nX][4] := "@!"
	Else
	AAdd(aCpoPict,aCampos[nX][4])
	EndIf
Next

If Len(aCampos) > 0 .And. Len(aArrayF4) > 0

	DEFINE MSDIALOG oDlg TITLE OemtoAnsi(cTitulo)  FROM 00,0 TO 100,490 OF oMainWnd PIXEL

	@ 05,05 MSCOMBOBOX oBusca VAR cBusca ITEMS aCpoBusca SIZE 206, 36 OF oDlg PIXEL ON CHANGE (nTipo := oBusca:nAt,C120ChgPic(nTipo,aCampos,@cPesq,@oPesq1,@oPesq2,@oPesq3,@oPesq4))

	@ 022,005 MSGET oPesq1 VAR cPesq Picture "@!" SIZE 206, 10 Of oDlg PIXEL

	@ 022,005 MSGET oPesq2 VAR cPesq Picture "@!" SIZE 206, 10 Of oDlg PIXEL

	@ 022,005 MSGET oPesq3 VAR cPesq Picture "@!" SIZE 206, 10 Of oDlg PIXEL

	@ 022,005 MSGET oPesq4 VAR cPesq Picture "@!" SIZE 206, 10 Of oDlg PIXEL

	oPesq1:Hide()
	oPesq2:Hide()
	oPesq3:Hide()
	oPesq4:Hide()

	Do Case
	Case aCampos[1][2] == "C"

		cGetF3 := GetSx3Cache( aCampos[1][1], "X3_F3" )
		If !Empty( cGetF3  )
			oPesq2:cF3 := cGetF3 
			oPesq1:Hide()
			oPesq2:Show()
			oPesq3:Hide()
			oPesq4:Hide()
		Else
			oPesq1:Show()
			oPesq2:Hide()
			oPesq3:Hide()
			oPesq4:Hide()
		Endif

	Case aCampos[1][2] == "D"
		oPesq1:Hide()
		oPesq2:Hide()
		oPesq3:Show()
		oPesq4:Hide()
	Case aCampos[1][2] == "N"
		oPesq1:Hide()
		oPesq2:Hide()
		oPesq3:Hide()
		oPesq4:Show()
	EndCase

	cPesq := CriaVar(aCampos[1][1],.F.)
	cPict := aCampos[1][4]

	DEFINE SBUTTON oBut1 FROM 05, 215 TYPE 1 ACTION ( nOpca := 1, oDlg:End() ) ENABLE of oDlg
	DEFINE SBUTTON oBut1 FROM 20, 215 TYPE 2 ACTION ( nOpca := 0, oDlg:End() )  ENABLE of oDlg

	@ 037,005 SAY OemtoAnsi(STR0078) SIZE 050,10 OF oDlg PIXEL //Tipo
	@ 037,030 MSCOMBOBOX oComboBox VAR cOpcAsc ITEMS aComboBox SIZE 050,10 OF oDlg PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED

	If nOpca == 1

		Do Case

		Case aCampos[nTipo][2] == "C"
			IF ( cOpcAsc == aComboBox[1] )	//Exata
				cAscan := Padr( Upper( cPesq ) , TamSx3(aCampos[nTipo][1])[1] )
				bAscan := { |x| cAscan == Upper( x[ nTipo ] ) }
			ElseIF ( cOpcAsc == aComboBox[2] )	//Parcial
				cAscan := Upper( AllTrim( cPesq ) )
				bAscan := { |x| cAscan == Upper( SubStr( Alltrim( x[nTipo] ) , 1 , Len( cAscan ) ) ) }
			ElseIF ( cOpcAsc == aComboBox[3] )	//Contem
				cAscan := Upper( AllTrim( cPesq ) )
				bAscan := { |x| cAscan $ Upper( Alltrim( x[nTipo] ) ) }
			EndIF

			nPos := Ascan( aArrayF4 , bAscan )
		Case aCampos[nTipo][2] == "N"
			nPos := Ascan(aArrayF4,{|x| Transform(cPesq,PesqPict("SC7",aCampos[nTipo][1])) == x[nTipo]},nBusca)
		Case aCampos[nTipo][2] == "D"
			nPos := Ascan(aArrayF4,{|x| Dtos(cPesq) == Dtos(x[nTipo])},nBusca)
		EndCase

		If nPos > 0
			If Existblock("CN120PSQ")
				aCn120Psq := Execblock("CN120PSQ",.F.,.F.,{aArrayF4,cPesq,cOpcAsc,cAscan,bAscan,nPos,aCampos,nTipo,nBusca})
				If Valtype(aCn120Psq) == 'A'
					aArrayF4	:= aClone(aCn120Psq[1])
					nPos		:= aCn120Psq[2]
				Endif
			Endif
			oQual:bLine := { || aArrayF4[oQual:nAT] }
			oQual:nFreeze := 1
			oQual:nAt := nPos
			oQual:Refresh()
			oQual:SetFocus()
		Else
			Help(" ",1,"REGNOIS")
		Endif

	EndIf
Endif
Return

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³C120ChgPic³ Autor ³ Aline Sebrian         ³ Data ³07.05.2010 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³Atualiza picture na funcao C120PespP                         ³±±
±±³          ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ExpN1 : Posicao do campo no Array                            ³±±
±±³          ³ExpA2 : Array com os dados dos campos                        ³±±
±±³          ³ExpX3 : Pesquisa                                             ³±±
±±³          ³ExpO4 : Objeto de pesquisa                                   ³±±
±±³          ³ExpO5 : Objeto de pesquisa                                   ³±±
±±³          ³ExpO6 : Objeto de pesquisa                                   ³±±
±±³          ³ExpO7 : Objeto de pesquisa                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Nenhum                                                       ³±±
±±³          ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³Esta rotina tem como objetivo tratar a picture do campo sele ³±±
±±³          ³cionado na funcao GdSeek                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ Generico                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function C120ChgPic(nTipo,aCampos,cPesq,oPesq1,oPesq2,oPesq3,oPesq4)

Local cPict   := ""
Local aArea   := GetArea()
Local bRefresh
Local cX3F3	  := ""

Do case

Case aCampos[nTipo][2] == "C"
	cX3F3 := GetSx3Cache( aCampos[nTipo][1], "X3_F3" )
	If !Empty( cX3F3 )
		oPesq2:cF3 := cX3F3
		oPesq1:Hide()
		oPesq2:Show()
		oPesq3:Hide()
		oPesq4:Hide()
		bRefresh := { || oPesq2:oGet:Picture := cPict,oPesq2:Refresh() }
	Else
		oPesq1:Show()
		oPesq2:Hide()
		oPesq3:Hide()
		oPesq4:Hide()
		bRefresh := { || oPesq1:oGet:Picture := cPict,oPesq1:Refresh() }
	Endif

Case aCampos[nTipo][2] == "D"
	oPesq1:Hide()
	oPesq2:Hide()
	oPesq3:Show()
	oPesq4:Hide()
	bRefresh := { || oPesq3:oGet:Picture := cPict,oPesq3:Refresh() }
Case aCampos[nTipo][2] == "N"
	oPesq1:Hide()
	oPesq2:Hide()
	oPesq3:Hide()
	oPesq4:Show()
	bRefresh := { || oPesq4:oGet:Picture := cPict,oPesq4:Refresh() }
EndCase

If nTipo > 0
	cPesq := CriaVar(aCampos[nTipo][1],.F.)
	cPict := aCampos[nTipo][4]
EndIf

Eval(bRefresh)

RestArea(aArea)

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ CN120VldProd³ Autor ³ Allyson Freitas       ³ Data ³ 11.01.2012 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Valida permissao de Produto                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ cProd: Produto                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ CNTA120                                                         ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function CN120VldProd()
Local lRet	 	:= .T.
Local oModel 	:= Nil
Local oModelCNE	:= Nil
Local cFilOri	:= ""
Local cContra	:= ""
Local cNumero	:= ""
Local cProd		:= ""
Local lExceRot	:= .F.
Local lExceCom	:= .F.

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Verifica se o usuario tem permissao de inclusao. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If IsInCallStack('CNTA120')
	cProd := M->CNE_PRODUT
Else
	cProd := FwFldGet('CNE_PRODUT')
EndIf

If Inclui
	If !(lRet := MaAvalPerm(1,{cProd,"CNT120",3}))
		Help(,,1,'SEMPERM')
	EndIf
EndIf

If IsInCallStack('CNTA121')
	oModel 		:= FWModelActive()
	oModelCNE	:= oModel:GetModel("CNEDETAIL")
	lExceRot	:= IsInCallStack('CN121Exced')
	lExceCom	:= IsInCallStack("CN121ExceC")

	If lRet
		If Cn300RetSt("SEMIAGRUP",0,oModel:GetValue('CXNDETAIL','CXN_NUMPLA'))
			If (lRet := CN121VlAgr(cProd))
				Help(" ",1,"CN121INGRP",,STR0158,1,0)
			EndIf
		EndIf
	EndIf

	If lExceRot .Or. lExceCom
		cFilOri	:= oModel:GetValue('CNDMASTER','CND_FILCTR')
		If lExceRot
			cContra := oModelCNE:GetValue("CNE_CONTRA")
			cNumero := oModelCNE:GetValue("CNE_NUMERO")
		Else
			cContra := oModel:GetValue('CNDMASTER','CND_CONTRA')
			cNumero := oModel:GetValue('CXNDETAIL','CXN_NUMPLA')
		EndIf

		If Cn121RetSt("MEDEVE",0)
			MsgAlert(STR0147) // "Funcionalidade indisponível para planilhas com medição eventual."
			lRet := .F.
		Endif
		dbSelectArea("CNB")
		dbSetOrder(4)
		If lRet .AND. !CNB->(MsSeek(cFilOri+cContra+cNumero+cProd))
			lRet := .F.
			Help(" ",1,"CN121EXCED",,STR0159,1,0)
		EndIf
	EndIf
EndIf
Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³CN120GetRaºAutor  ³Microsiga           º Data ³  01/03/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Funcao que obtem o rateio de pedidos de compra ou venda.   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ CNTA120                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function CN120GetRa(cContrato,cNumMed,cRevisao,cItemPlan,aDadoEnt,cPedItem)
Local aRet		:= {}
Local aAux		:= {}
Local nSetOrder	:= If(Upper(aDadoEnt[1]) == "FORNECEDOR",3,4)
Local cCodEnt	:= If(Upper(aDadoEnt[1]) == "FORNECEDOR","CNZ_FORNEC","CNZ_CLIENT")
Local cLjEnt	:= If(Upper(aDadoEnt[1]) == "FORNECEDOR","CNZ_LJFORN","CNZ_LOJACL")
Local cBusca	:= xFilial("CNZ",cFilCTR)+cContrato+cRevisao+cNumMed+aDadoEnt[2]+aDadoEnt[3]+cItemPlan
Local aEntidades := CtbEntArr()
Local nX		:= 0
Local nY		:= 0
Local cCpoCNZ	:= ""
Local cCpoSCH	:= ""
Local cCpoAGG	:= ""
Local cTipo		:= If(Upper(aDadoEnt[1]) == "FORNECEDOR","1","2")
Local aCN120Rat	:= {}

Default cPedItem := ''

CNZ->(dbSetOrder(nSetOrder))
If CNZ->(dbSeek(cBusca))
	While CNZ->(!Eof()) .And. cBusca == xFilial("CNZ",cFilCTR)+CNZ->(CNZ_CONTRA+CNZ_REVISA+CNZ_NUMMED+&(cCodEnt)+&(cLjEnt)+CNZ_ITCONT)
		If CNZ->CNZ_PERC == 0
			aRet := {}
			Exit
		EndIf

		If Upper(aDadoEnt[1]) == "FORNECEDOR"
			aAux := {}
			aAdd(aAux,{"CH_ITEMPD"		, cPedItem           , nil}) //Nro do Item do Pedido de Compras
			aAdd(aAux,{"CH_ITEM"		, CNZ->CNZ_ITEM		, nil})
			aAdd(aAux,{"CH_PERC"		, CNZ->CNZ_PERC		, nil})
			aAdd(aAux,{"CH_CC"			, CNZ->CNZ_CC		, nil})
			aAdd(aAux,{"CH_CONTA"		, CNZ->CNZ_CONTA	, nil})
			aAdd(aAux,{"CH_ITEMCTA"		, CNZ->CNZ_ITEMCT	, nil})
			aAdd(aAux,{"CH_CLVL"		, CNZ->CNZ_CLVL		, nil})

			//Tratamento para entidades contabeis adicionais
			For nX := 1 To Len(aEntidades)
				For nY := 1 To 2

					cCpoCNZ := "CNZ_EC" + aEntidades[nX]
					cCpoSCH := "CH_EC" + aEntidades[nX]

					If nY == 1
						cCpoCNZ += "DB"
						cCpoSCH += "DB"
					Else
						cCpoCNZ += "CR"
						cCpoSCH += "CR"
					EndIf

					aAdd( aAux , { cCpoSCH , CNZ->(&(cCpoCNZ)) , nil } )

				Next nY
			Next nX

			aadd(aRet,aAux)
		Else
			aAdd(aAux,{"AGG_ITEMPD"		, cItemPlan			, nil})
			aAdd(aAux,{"AGG_ITEM"		, CNZ->CNZ_ITEM		, nil})
			aAdd(aAux,{"AGG_PERC"		, CNZ->CNZ_PERC		, nil})
			aAdd(aAux,{"AGG_CC"			, CNZ->CNZ_CC		, nil})
			aAdd(aAux,{"AGG_CONTA"		, CNZ->CNZ_CONTA	, nil})
			aAdd(aAux,{"AGG_ITEMCT"	, CNZ->CNZ_ITEMCT	, nil})
			aAdd(aAux,{"AGG_CLVL"		, CNZ->CNZ_CLVL		, nil})

			//Tratamento para entidades contabeis adicionais
			For nX := 1 To Len(aEntidades)
				For nY := 1 To 2

					cCpoCNZ := "CNZ_EC" + aEntidades[nX]
					cCpoAGG := "AGG_EC" + aEntidades[nX]

					If nY == 1
						cCpoCNZ += "DB"
						cCpoAGG += "DB"
					Else
						cCpoCNZ += "CR"
						cCpoAGG += "CR"
					EndIf

					aAdd( aAux , { cCpoAGG , CNZ->(&(cCpoCNZ)) , nil } )

				Next nY
			Next nX

			aadd(aRet,aAux)
			aAux := {}
		Endif

		CNZ->(DbSkip())
	EndDo

	//Ponto de Entrada para manipulação do rateio do pedido
	If ExistBlock("CN120RAT")
		aCN120Rat := ExecBlock("CN120RAT",.F.,.F.,{aRet,cTipo})
		If ValType(aCN120Rat) == "A"
			aRet := aCN120Rat
		EndIf
	EndIf
Endif
Return(aRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³CN120VlExcºAutor  ³Microsiga           º Data ³  08/11/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Funcao que retorna o valor total correspondente aos        º±±
±±º          ³ excedentes de uma medicao.                                 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³ cContra: numero do contrato								  º±±
±±º			 ³ cRevisa: numero da revisao								  º±±
±±º          ³ cNumMed: numero da medicao								  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºRetorno   ³ nRet: valor total dos excedentes da medicao				  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ CNTA120                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function CN120VlExc(cContra,cRevisa,cNumMed,cPlan)
Local aArea  := GetArea()
Local nRet   := 0
Local cQuery := ""

Default cContra := CND->CND_CONTRA
Default cRevisa := CND->CND_REVISA
Default cNumMed := CND->CND_NUMMED
Default cPlan	:= ""

cQuery := " SELECT SUM(CNE.CNE_VLTOT) - SUM(CNE.CNE_VLDESC) AS TOTAL "
cQuery += " FROM "
cQuery +=  RetSQLName("CNE") +" CNE "
cQuery += " WHERE"
cQuery += " CNE.D_E_L_E_T_ <> '*' AND "
cQuery += " CNE.CNE_FILIAL = '" +xFilial("CNE") +"' AND "
cQuery += " CNE.CNE_CONTRA = '" +cContra +"' AND "
cQuery += " CNE.CNE_REVISA = '" +cRevisa +"' AND "
cQuery += " CNE.CNE_NUMMED = '" +cNumMed +"' AND "
If !Empty(cPlan)
	cQuery += " CNE.CNE_NUMERO = '" +cPlan +"' AND  "
EndIf
cQuery += " CNE.CNE_EXCEDE = '1'"

cQuery := ChangeQuery(cQuery)
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TRB",.F.,.T.)
nRet := TRB->TOTAL

TRB->(dbCloseArea())

RestArea(aArea)
Return nRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN120ExceM³ Autor ³Joao Goncalves de Oliveira   ³Data ³08/07/2011³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Inclui excedente na medicao apos encerramento                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN120ExceM(cExp01,nExp02,nExp03)                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 - Alias do Arquivo                                        ³±±
±±³          ³ ExpN2 - Numero do Registro                                      ³±±
±±³          ³ ExpN3 - Opcao de Atualizacao                                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Retorno  ³ Nenhum                       						   		   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function CN120ExceM(cAlias,nReg,nOpc)
Local lContinua := CN240VldUsr(CND->CND_CONTRA,DEF_TRAEDT,.T.,,cFilCtr)
Local aValidGet := {}
Local aCN130CEX := {}
Local aEditCamp := {"CNE_QUANT","CNE_DTENT","CNE_FLGCMS","CNE_PEDTIT"}
Local cChave    := ""
Local cNumPed   := ""
Local cTes      := ""
Local cQuery    := ""
Local cTabPrc   := ""
Local cItem		:= ""
Local nX		:= 0
Local nY		:= 0
Local nPNUMMED  := 0
Local nPPRODUT  := 0
Local nPQUANT   := 0
Local nPITEM	:= 0
Local nSumMed   := 0

If Type('lAuto') == 'U'
	lAuto := IsBlind()
EndIf

//-- Valida o tipo do contrato
CN9->(dbSetOrder(1))
If lContinua .And. CN9->(dbSeek(xFilial("CN9",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA))
	If Cn300RetSt('COMPRA',,,,CN9->CN9_FILCTR,.F.)
		Aviso(STR0094,STR0090,{STR0155}) //-- Funcionalidade indisponível para contratos de compra.
		lContinua := .F.
	EndIf
EndIf

//-- Valida se e medicao encerrada
If Empty(CND->CND_DTFIM)
	Help(" ",1,"CNTA120_13")
	lContinua := .F.
EndIf

//-- Ponto de entrada para permitir alterar mais campos
If ExistBlock("CN130CEX")
	aCN130CEX := ExecBlock("CN130CEX",.F.,.F.,{aEditCamp})
	If ValType(aCN130CEX) == "A"
		aEditCamp := aClone(aCN130CEX)
	EndIf
EndIf

If lContinua .And. lAuto .And. !Empty(aAutoItens) .And. (nPNUMMED := aScan(aAutoCab,{|x| AllTrim(x[1]) == "CND_NUMMED"})) > 0
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Valida numero da medicao                           ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aAdd(aValidGet,{"cNumMed",aAutoCab[nPNUMMED,2],"CN120NumAuto(cNumMed,.F.)",.T.})
	If (lContinua := MsVldGAuto(aValidGet))
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Verifica se o produto excedente esta gravado na medicao      ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		For nX := 1 To Len(aAutoItens)
			If (nPITEM	 := aScan(aAutoItens[nX],{|x| AllTrim(x[1]) == "CNE_ITEM"})) > 0 .And.;
			   (nPQUANT	 := aScan(aAutoItens[nX],{|x| AllTrim(x[1]) == "CNE_QUANT"})) > 0

				cQuery := "SELECT CNE.CNE_PRODUT, CNE.CNE_DTENT, CNE.CNE_FLGCMS, CNE.CNE_TS "
				cQuery += ", CNE.CNE_PEDTIT "
				cQuery += "FROM " +RetSQLName("CNE") +" CNE "
				cQuery += "JOIN " +RetSQLName("CNB") +" CNB "
				cQuery += "ON CNB.D_E_L_E_T_ <> '*' AND "
				cQuery += "CNB.CNB_FILIAL = '" +xFilial("CNB",cFilCTR) +"' AND "
				cQuery += "CNB.CNB_ITEM = CNE.CNE_ITEM AND "
				cQuery += "CNB.CNB_PRODUT = CNE.CNE_PRODUT AND "
				cQuery += "CNB.CNB_NUMERO = '" +CND->CND_NUMERO +"' AND "
				cQuery += "CNB.CNB_TABPRC <> '"+Space(TamSX3("CNB_TABPRC")[1])+"' "
				cQuery += "WHERE CNE.D_E_L_E_T_ <> '*' AND "
				cQuery += "CNE.CNE_FILIAL = '" +xFilial("CNE") + "' AND "
				cQuery += "CNE.CNE_NUMMED = '" +CND->CND_NUMMED + "' AND "
				cQuery += "CNE.CNE_ITEM = '" +aAutoItens[nX,nPITEM,2] +"' AND "
				cQuery += "CNE.CNE_EXCEDE <> '1'"
				cQuery := ChangeQuery(cQuery)
				dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TRBCNE",.F.,.T.)
				If TRBCNE->(EOF())
					Aviso(STR0114,STR0095 +aCols[nAux,nPITEM] +STR0096) //-- O item ### não possui preço para a quantidade excedente.
					lContinua := .F.
				Else
					If Empty(aScan(aAutoItens[nX],{|x| AllTrim(x[1]) == "CNE_PRODUT"}))
						aAdd(aAutoItens[nX],{"CNE_PRODUT",TRBCNE->CNE_PRODUT,NIL})
						nPPRODUT := Len(aAutoItens[nX])
					EndIf
					If Empty(aScan(aAutoItens[nX],{|x| AllTrim(x[1]) == "CNE_DTENT"}))
						aAdd(aAutoItens[nX],{"CNE_DTENT",TRBCNE->CNE_DTENT,NIL})
					EndIf
					If Empty(aScan(aAutoItens[nX],{|x| AllTrim(x[1]) == "CNE_FLGCMS"}))
						aAdd(aAutoItens[nX],{"CNE_FLGCMS",TRBCNE->CNE_FLGCMS,NIL})
					EndIf
					If Empty(aScan(aAutoItens[nX],{|x| AllTrim(x[1]) == "CNE_TS"}))
						aAdd(aAutoItens[nX],{"CNE_TS",TRBCNE->CNE_TS,NIL})
					EndIf
					If Empty(aScan(aAutoItens[nX],{|x| AllTrim(x[1]) == "CNE_PEDTIT"}))
						aAdd(aAutoItens[nX],{"CNE_PEDTIT",TRBCNE->CNE_PEDTIT,NIL})
					EndIf
				EndIf
				TRBCNE->(dbCloseArea())
			Else
				Aviso(STR0094,STR0095,{STR0155}) //-- Campo item ou quantidade ausente para geração do excedente.
				lContinua := .F.
			EndIf
		Next nX
	EndIf
EndIf

cChave := CND->CND_CONTRA+CND->CND_REVISA+CND->CND_NUMERO+CND->CND_NUMMED
If lContinua .And. LockByName("CN120"+xFilial("CND")+cChave,.T.,!Empty(xFilial("CND")),.T.)
	If lAuto
		//-- Pega maior item da medicao
		cQuery := "SELECT MAX(CNE_ITEM) AS CNE_ITEM FROM " +RetSQLName("CNE") +" WHERE "
		cQuery += "D_E_L_E_T_ <> '*' AND CNE_FILIAL = '" + xFilial("CNE") + "' AND "
		cQuery += "CNE_NUMMED = '" +CND->CND_NUMMED + "'"
		cQuery := ChangeQuery(cQuery)
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TRBCNE",.F.,.T.)
		cItem := TRBCNE->CNE_ITEM
		TRBCNE->(dbCloseArea())

		Begin Transaction

		For nX := 1 To Len(aAutoItens)
			cItem   := Soma1(cItem)
			cTabPrc := Posicione("CNB",1,xFilial("CNB",cFilCTR)+CND->(CND_CONTRA+CND_REVISA+CND_NUMERO)+aAutoItens[nX,nPITEM,2],"CNB_TABPRC")

			If Empty(nPrcUnit := MaTabPrVen(cTabPrc,aAutoItens[nX,nPPRODUT,2],aAutoItens[nX,nPQUANT,2],CND->CND_CLIENT,CND->CND_LOJACL,1,dDataBase))
				Aviso(STR0094,STR0096 +aCols[nAux,nPITEM] +STR0097,{STR0155}) //-- O item ### " não possui preço para a quantidade excedente.
				DisarmTransaction()
				lContinua := .F.
				Exit
			EndIf

			Reclock("CNE",.T.)
			For nY := 1 to Len(aAutoItens[nX])
				If aScan(aEditCamp,{|x| AllTrim(x) == AllTrim(aAutoItens[nX,nY,1])}) > 0
					CNE->(FieldPut(FieldPos(aAutoItens[nX,nY,1]),aAutoItens[nX,nY,2]))
				ElseIf aAutoItens[nX,nY,1] # "LINPOS"
					CNE->(FieldPut(FieldPos(aAutoItens[nX,nY,1]),CriaVar(aAutoItens[nX,nY,1])))
				EndIf
			Next nY

			//-- Campos de controle do sistema
			CNE->CNE_FILIAL := xFilial("CNE")
			CNE->CNE_NUMERO := CND->CND_NUMERO
			CNE->CNE_NUMMED := CND->CND_NUMMED
			CNE->CNE_REVISA := CND->CND_REVISA
			CNE->CNE_CONTRA := CND->CND_CONTRA
			CNE->CNE_ITEM   := cItem
			CNE->CNE_PRODUT := aAutoItens[nX,nPPRODUT,2]
			CNE->CNE_TS     := Posicione("CNB",1,xFilial("CNB",cFilCTR)+CND->(CND_CONTRA+CND_REVISA+CND_NUMERO)+aAutoItens[nX,nPITEM,2],"CNB_TS")
			CNE->CNE_PEDTIT := Posicione("CNB",1,xFilial("CNB",cFilCTR)+CND->(CND_CONTRA+CND_REVISA+CND_NUMERO)+aAutoItens[nX,nPITEM,2],"CNE_PEDTIT")
			CNE->CNE_EXCEDE := '1'
			CNE->CNE_VLUNIT := nPrcUnit
			CNE->CNE_VLTOT  := Round(nPrcUnit * aAutoItens[nX,nPQUANT,2],TamSX3('CNE_VLTOT')[2])
			CNE->(MsUnlock())

			nSumMed += CNE->CNE_VLTOT
		Next nX

		End Transaction

		//-- Processa geracao do pedido excedente
		If lContinua
			RecLock("CND",.F.)
			CND->CND_VLTOT += nSumMed
			CND->(MsUnLock())

			Processa({|| CN120GrvPeD(CND->CND_NUMMED,CND->CND_REVISA,@cNumPed,NIL,CND->CND_CONTRA,@cTes,.T.)},,STR0039) //"Gerando Pedido de Vendas"
		EndIf
	Else
		CN130Manut(cAlias,nReg,nOpc,"EXCEDE",CND->CND_CONTRA,CND->CND_REVISA)
	EndIf
ElseIf lContinua //Nao permite processamento concorrente
	Aviso(STR0068,OemtoAnsi(STR0069),{STR0155},2) // ##"Concorrência"##"Esta Medição está em uso por outra estação."
EndIf
UnLockByName("CN120"+xFilial("CND")+cChave,.T.,!Empty(xFilial("CND")),.T.)

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³CN120PlansºAutor  ³ Andre Anjos	     º Data ³  24/11/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Monta variaveis utilizadas na montagem do browse da selecaoº±±
±±º          ³ das planilhas a medir e o arquivo temporario.              º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ CNTA120                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function CN120Plans(oTempCNA,aTitle,aCampos,cLine)
Local aStruCNA  	:= CNA->(dbStruct())
Local aCn120cpo 	:= {}
Local aNewFld		:= {}
Local nX			:= 0

//- Adiciona parcela e valor previsao a estrutura da planilha
aAdd(aStruCNA,{"CNF_PARCEL","C",TamSX3("CNF_PARCEL")[1],TamSX3("CNF_PARCEL")[2]})
aAdd(aStruCNA,{"CNF_VLPREV","N",TamSX3("CNF_VLPREV")[1],TamSX3("CNF_VLPREV")[2]})

//- Cria arquivo temporario
oTempCNA := GSTmpTable():New("TRBCNA",aStruCNA,{{'ID1',{'CNA_FILIAL','CNA_CONTRA','CNA_REVISA','CNA_NUMERO'}}})
If !oTempCNA:CreateTMPTable()
	oTempCNA:ShowErro()
Else
	//- Configura campos exibidos na inclusao de medicoes
	aTitle		:= {"",RetTitle("CNA_NUMERO"),RetTitle("CNF_PARCEL"),RetTitle("CNA_DTINI"),RetTitle("CNA_DTFIM"),RetTitle("CNA_VLTOT"),RetTitle("CNF_VLPREV"),RetTitle("CNA_FORNEC"),RetTitle("CNA_LJFORN"),RetTitle("CNA_CLIENT"),RetTitle("CNA_LOJACL"),RetTitle("CNA_CRONOG")}
	aCampos	:= {"",TRBCNA->CNA_NUMERO,TRBCNA->CNF_PARCEL,TRBCNA->CNA_DTINI,TRBCNA->CNA_DTFIM,TRBCNA->CNA_VLTOT,TRBCNA->CNF_VLPREV,TRBCNA->CNA_FORNEC,TRBCNA->CNA_LJFORN,TRBCNA->CNA_CLIENT,TRBCNA->CNA_LOJACL,TRBCNA->CNA_CRONOG}
	cLine 		:= "{If((cPlan+cParcel==(TRBCNA->CNA_NUMERO+TRBCNA->CNF_PARCEL)),oOk,oNo),TRBCNA->CNA_NUMERO,TRBCNA->CNF_PARCEL,TRBCNA->CNA_DTINI,TRBCNA->CNA_DTFIM,Transform(TRBCNA->CNA_VLTOT,PesqPict('CNA','CNA_VLTOT')),Transform(TRBCNA->CNF_VLPREV,PesqPict('CNF','CNF_VLPREV')),TRBCNA->CNA_FORNEC,TRBCNA->CNA_LJFORN,TRBCNA->CNA_CLIENT,TRBCNA->CNA_LOJACL,TRBCNA->CNA_CRONOG,"

	If ExistBlock("CN120CPO")
		aCn120cpo := ExecBlock("CN120CPO",.F.,.F.)
		If ValType(aCn120cpo) == "A"
			aNewFld := aCn120cpo
		EndIf
	EndIf

	//- Varre os campos especificos
	For nX := 1 To Len(aNewFld)
		If GetSx3Cache( aNewFld[nx], "X3_TIPO" ) == "N"//Monta cLine para campos numericos
			cLine += "Transform(TRBCNA->"+aNewFld[nx]+",PesqPict('CNA','"+aNewFld[nx]+"')),"
		Else
			cLine += "TRBCNA->"+aNewFld[nx]+","
		EndIf
		aAdd(aTitle,RetTitle(aNewFld[nx]))
		aAdd(aCampos,TRBCNA->(&(aNewFld[nx])))
	Next nX

	//- Finaliza construcao do cLine
	cLine := substr(cLine,1,len(cLine)-1)+"}"
EndIf

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³CN120ExceCºAutor  ³ Andre Anjos 		 º Data ³  21/11/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Realiza a inclusao de medicao excedente para uma compet.   º±±
±±º          ³ inexistente na CNF.                                        º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ CNTA120                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function CN120ExceC(cAlias,nReg,nOpc)
Local oOk       := LoadBitmap(GetResources(),"LBTIK")
Local oNo  	    := LoadBitmap(GetResources(),"LBNO")
Local aStruCNA  := CNA->(dbStruct())
Local aTitle    := {}
Local aCampos   := {}
Local aAlter    := {"UCNE_QUANT","CNE_DTENT","CNE_FLGCMS","CNE_PEDTIT"}
Local aValidGet := {}
Local aRetPE	:= {}
Local cLine    	:= ""
Local cConsSxb 	:= "CN9003"
Local nX	   	:= 0
Local nPQUANT   := 0

Private cContra   := CriaVar("CND_CONTRA",.F.)
Private cRevisa   := CriaVar("CND_REVISA",.F.)
Private cCompet   := CriaVar("CNF_COMPET",.F.)
Private cPlan     := CriaVar("CND_NUMERO",.F.)
Private cParcel   := ""
Private cNumMed   := ""
Private lFixo	  := .T.
Private lMedEve   := .F.
Private lEncerra  := .F.
Private aListBox  := {}
Private nTotMed   := 0
Private nCaucVlr  := 0
Private oBrowse   := NIL
Private oCbx      := NIL
Private oGetDados := NIL
Private oGetTot   := NIL
Private cEspCtr   := '1'
Private oTempCNA	:= Nil
Private aHeader := {}
Private aCols   := {}
Private oWizard	:= NIL
Private lBack	:= .F.
Private lCancel	:= .F.

If Type('lAuto') == 'U'
	lAuto := IsBlind()
EndIf

cTexto := STR0097 //-- Assistente responsável pela inclusão de medição de excedentes contratuais para uma competência
cTexto += STR0098 //-- não prevista no contrato. Nesta medição, apenas itens excedentes poderão ser lançados.
cTexto += CRLF + CRLF
cTexto += STR0099 //-- Clique em avançar e inicie o processo

If ExistBlock("CN120SXB")
	cConsSxb := If(Valtype(cCn120Sxb:=ExecBlock("CN120SXB",.F.,.F.))=="C",cCn120Sxb,"CN9003")
EndIf

aAdd(aHeader,{ GetSx3Cache( "CNE_ITEM", "X3_TITULO" ) ,;
			   "CNE_ITEM"							  ,;
			   GetSx3Cache( "CNE_ITEM", "X3_PICTURE" ),;
			   GetSx3Cache( "CNE_ITEM", "X3_TAMANHO" ),;
			   GetSx3Cache( "CNE_ITEM", "X3_DECIMAL" ),;
			   GetSx3Cache( "CNE_ITEM", "X3_VALID" 	 ),;
			   GetSx3Cache( "CNE_ITEM", "X3_USADO"   ),;
			   GetSx3Cache( "CNE_ITEM", "X3_TIPO"	 ),;
			   GetSx3Cache( "CNE_ITEM", "X3_F3"		 ),;
			   GetSx3Cache( "CNE_ITEM", "X3_CONTEXT" ) } )
			   
aAdd(aHeader,{ GetSx3Cache( "CNE_PRODUT", "X3_TITULO" ) ,;
			   "CNE_PRODUT"							    ,;
			   GetSx3Cache( "CNE_PRODUT", "X3_PICTURE" ),;
			   GetSx3Cache( "CNE_PRODUT", "X3_TAMANHO" ),;
			   GetSx3Cache( "CNE_PRODUT", "X3_DECIMAL" ),;
			   GetSx3Cache( "CNE_PRODUT", "X3_VALID"   ),;
			   GetSx3Cache( "CNE_PRODUT", "X3_USADO"   ),;
			   GetSx3Cache( "CNE_PRODUT", "X3_TIPO"	   ),;
			   GetSx3Cache( "CNE_PRODUT", "X3_F3"	   ),;
			   GetSx3Cache( "CNE_PRODUT", "X3_CONTEXT" ) } )

aAdd(aHeader,{ GetSx3Cache( "CNE_DESCRI", "X3_TITULO" ) ,;
			   "CNE_DESCRI"							    ,;
			   GetSx3Cache( "CNE_DESCRI", "X3_PICTURE" ),;
			   GetSx3Cache( "CNE_DESCRI", "X3_TAMANHO" ),;
			   GetSx3Cache( "CNE_DESCRI", "X3_DECIMAL" ),;
			   GetSx3Cache( "CNE_DESCRI", "X3_VALID"   ),;
			   GetSx3Cache( "CNE_DESCRI", "X3_USADO"   ),;
			   GetSx3Cache( "CNE_DESCRI", "X3_TIPO"	   ),;
			   GetSx3Cache( "CNE_DESCRI", "X3_F3"	   ),;
			   GetSx3Cache( "CNE_DESCRI", "X3_CONTEXT" ) } )

aAdd(aHeader,{ GetSx3Cache( "CNE_QUANT", "X3_TITULO" ) ,;
			   "UCNE_QUANT"							    ,;
			   GetSx3Cache( "CNE_QUANT", "X3_PICTURE" ),;
			   GetSx3Cache( "CNE_QUANT", "X3_TAMANHO" ),;
			   GetSx3Cache( "CNE_QUANT", "X3_DECIMAL" ),;
			   "CN120VlQEx()"						   ,;
			   GetSx3Cache( "CNE_QUANT", "X3_USADO"   ),;
			   GetSx3Cache( "CNE_QUANT", "X3_TIPO"	  ),;
			   GetSx3Cache( "CNE_QUANT", "X3_F3"	  ),;
			   GetSx3Cache( "CNE_QUANT", "X3_CONTEXT" ) } )

aAdd(aHeader,{ GetSx3Cache( "CNE_VLUNIT", "X3_TITULO"  ),;
			   "CNE_VLUNIT"							    ,;
			   GetSx3Cache( "CNE_VLUNIT", "X3_PICTURE" ),;
			   GetSx3Cache( "CNE_VLUNIT", "X3_TAMANHO" ),;
			   GetSx3Cache( "CNE_VLUNIT", "X3_DECIMAL" ),;
			   GetSx3Cache( "CNE_VLUNIT", "X3_VALID"   ),;
			   GetSx3Cache( "CNE_VLUNIT", "X3_USADO"   ),;
			   GetSx3Cache( "CNE_VLUNIT", "X3_TIPO"	   ),;
			   GetSx3Cache( "CNE_VLUNIT", "X3_F3"	   ),;
			   GetSx3Cache( "CNE_VLUNIT", "X3_CONTEXT" ) } )

aAdd(aHeader,{ GetSx3Cache( "CNE_VLTOT", "X3_TITULO"  ),;
			   "CNE_VLTOT"							    ,;
			   GetSx3Cache( "CNE_VLTOT", "X3_PICTURE" ),;
			   GetSx3Cache( "CNE_VLTOT", "X3_TAMANHO" ),;
			   GetSx3Cache( "CNE_VLTOT", "X3_DECIMAL" ),;
			   GetSx3Cache( "CNE_VLTOT", "X3_VALID"   ),;
			   GetSx3Cache( "CNE_VLTOT", "X3_USADO"   ),;
			   GetSx3Cache( "CNE_VLTOT", "X3_TIPO"	  ),;
			   GetSx3Cache( "CNE_VLTOT", "X3_F3"	  ),;
			   GetSx3Cache( "CNE_VLTOT", "X3_CONTEXT" ) } )

aAdd(aHeader,{ GetSx3Cache( "CNE_DTENT", "X3_TITULO"  ),;
			   "CNE_DTENT"							    ,;
			   GetSx3Cache( "CNE_DTENT", "X3_PICTURE" ),;
			   GetSx3Cache( "CNE_DTENT", "X3_TAMANHO" ),;
			   GetSx3Cache( "CNE_DTENT", "X3_DECIMAL" ),;
			   GetSx3Cache( "CNE_DTENT", "X3_VALID"   ),;
			   GetSx3Cache( "CNE_DTENT", "X3_USADO"   ),;
			   GetSx3Cache( "CNE_DTENT", "X3_TIPO"	  ),;
			   GetSx3Cache( "CNE_DTENT", "X3_F3"	  ),;
			   GetSx3Cache( "CNE_DTENT", "X3_CONTEXT" ) } )

aAdd(aHeader,{ GetSx3Cache( "CNE_FLGCMS", "X3_TITULO"  ),;
			   "CNE_FLGCMS"							    ,;
			   GetSx3Cache( "CNE_FLGCMS", "X3_PICTURE" ),;
			   GetSx3Cache( "CNE_FLGCMS", "X3_TAMANHO" ),;
			   GetSx3Cache( "CNE_FLGCMS", "X3_DECIMAL" ),;
			   GetSx3Cache( "CNE_FLGCMS", "X3_VALID"   ),;
			   GetSx3Cache( "CNE_FLGCMS", "X3_USADO"   ),;
			   GetSx3Cache( "CNE_FLGCMS", "X3_TIPO"	   ),;
			   GetSx3Cache( "CNE_FLGCMS", "X3_F3"	   ),;
			   GetSx3Cache( "CNE_FLGCMS", "X3_CONTEXT" ) } )

aAdd(aHeader,{ GetSx3Cache( "CNE_TS", "X3_TITULO"  ),;
			   "CNE_TS"							    ,;
			   GetSx3Cache( "CNE_TS", "X3_PICTURE" ),;
			   GetSx3Cache( "CNE_TS", "X3_TAMANHO" ),;
			   GetSx3Cache( "CNE_TS", "X3_DECIMAL" ),;
			   GetSx3Cache( "CNE_TS", "X3_VALID"   ),;
			   GetSx3Cache( "CNE_TS", "X3_USADO"   ),;
			   GetSx3Cache( "CNE_TS", "X3_TIPO"	   ),;
			   GetSx3Cache( "CNE_TS", "X3_F3"	   ),;
			   GetSx3Cache( "CNE_TS", "X3_CONTEXT" ) } )

aAdd(aHeader,{ GetSx3Cache( "CNE_TABPRC", "X3_TITULO"  ),;
			   "CNE_TABPRC"							    ,;
			   GetSx3Cache( "CNE_TABPRC", "X3_PICTURE" ),;
			   GetSx3Cache( "CNE_TABPRC", "X3_TAMANHO" ),;
			   GetSx3Cache( "CNE_TABPRC", "X3_DECIMAL" ),;
			   GetSx3Cache( "CNE_TABPRC", "X3_VALID"   ),;
			   GetSx3Cache( "CNE_TABPRC", "X3_USADO"   ),;
			   GetSx3Cache( "CNE_TABPRC", "X3_TIPO"	   ),;
			   GetSx3Cache( "CNE_TABPRC", "X3_F3"	   ),;
			   GetSx3Cache( "CNE_TABPRC", "X3_CONTEXT" ) } )

aAdd(aHeader,{ GetSx3Cache( "CNE_EXCEDE", "X3_TITULO"  ),;
			   "CNE_EXCEDE"							    ,;
			   GetSx3Cache( "CNE_EXCEDE", "X3_PICTURE" ),;
			   GetSx3Cache( "CNE_EXCEDE", "X3_TAMANHO" ),;
			   GetSx3Cache( "CNE_EXCEDE", "X3_DECIMAL" ),;
			   GetSx3Cache( "CNE_EXCEDE", "X3_VALID"   ),;
			   GetSx3Cache( "CNE_EXCEDE", "X3_USADO"   ),;
			   GetSx3Cache( "CNE_EXCEDE", "X3_TIPO"	   ),;
			   GetSx3Cache( "CNE_EXCEDE", "X3_F3"	   ),;
			   GetSx3Cache( "CNE_EXCEDE", "X3_CONTEXT" ) } )

aAdd(aHeader,{ GetSx3Cache( "CNE_PEDTIT", "X3_TITULO"  ),;
			   "CNE_PEDTIT"							    ,;
			   GetSx3Cache( "CNE_PEDTIT", "X3_PICTURE" ),;
			   GetSx3Cache( "CNE_PEDTIT", "X3_TAMANHO" ),;
			   GetSx3Cache( "CNE_PEDTIT", "X3_DECIMAL" ),;
			   GetSx3Cache( "CNE_PEDTIT", "X3_VALID"   ),;
			   GetSx3Cache( "CNE_PEDTIT", "X3_USADO"   ),;
			   GetSx3Cache( "CNE_PEDTIT", "X3_TIPO"	   ),;
			   GetSx3Cache( "CNE_PEDTIT", "X3_F3"	   ),;
			   GetSx3Cache( "CNE_PEDTIT", "X3_CONTEXT" ) } )

If lAuto
    //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Valida os campos do cabecalho da medicao            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aAdd(aValidGet,{"cContra",aAutoCab[aScan(aAutoCab,{|x| x[1]=="CND_CONTRA"}),2],"CheckSX3('CND_CONTRA',cContra)",.T.})
	aAdd(aValidGet,{"cRevisa",aAutoCab[aScan(aAutoCab,{|x| x[1]=="CND_REVISA"}),2],"CheckSX3('CND_REVISA',cRevisa) .And. CN120CtrAuto(cContra,cRevisa,.T.)",.T.})
	aAdd(aValidGet,{"cPlan",aAutoCab[aScan(aAutoCab,{|x| x[1]=="CND_NUMERO"}),2],"CheckSX3('CND_NUMERO',cPlan)",.T.})
	If aScan(aAutoCab,{|x| x[1]=="CND_PARCEL"}) > 0
	  	aAdd(aValidGet,{"cParcel",aAutoCab[aScan(aAutoCab,{|x| x[1]=="CND_PARCEL"}),2],"CheckSX3('CND_PARCEL',cParcel)",.T.})
	EndIf
	aAdd(aValidGet,{"cCompet",aAutoCab[aScan(aAutoCab,{|x| x[1]=="CND_COMPET"}),2],"CheckSX3('CND_COMPET',cCompet) .And. CN120VldCpt(.T.)",.T.})

	If (nPosNum := aScan(aAutoCab,{|x| x[1] == "CND_NUMMED"})) > 0
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Valida campo CND_NUMMED quando fornecido atraves    ³
		//³da rotina automatica                                ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cNumMed := aAutoCab[nPosNum,2]
		aAdd(aValidGet,{"cNumMed",aAutoCab[nPosNum,2],"CN120NumAuto(cNumMed,.T.)",.T.})
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³PE para permitir alterar a validacao da rotina automatica ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If ExistBlock("CN120AutVl")
		aRetPE := ExecBlock("CN120AutVl",.F.,.F.,{aValidGet})

		If ValType(aRetPE) == "A"
			aValidGet := aClone(aRetPE)
		EndIf
	EndIf

	If MsVldGAuto(aValidGet)
		//-- Prepara memoria para gravacao
		RegToMemory("CND",.T.,.F.,.T.)

		//-- Joga do array para memoria
		For nX := 1 To Len(aAutoCab)
			If Substr(aAutoCab[nX,1],1,4) == "CND_"
				&("M->" +aAutoCab[nX,1]) := aAutoCab[nX,2]
			EndIf
		Next nX

		//-- Verifica chave de encerramento da medicao
		lEncerra := aScan(aAutoCab,{|x| AllTrim(x[1]) == "ENCERRA" .And. x[2] == "S"}) > 0

		//-- Se validou, carrega aCols
		CN120VldPn(1,@aHeader,@aCols)

		//-- Ajusta o nome do campo de quantidade e coloca valid
		If Len(aAutoItens) > 0 .And. (nPQUANT := aScan(aAutoItens[1],{|x| AllTrim(x[1]) = "CNE_QUANT"})) > 0
			For nX := 1 To Len(aAutoItens)
				aAutoItens[nX,nPQUANT,1] := "UCNE_QUANT"
				If ValType(aAutoItens[nX,nPQUANT,3]) == "C" .And. !Empty(aAutoItens[nX,nPQUANT,3])
					aAutoItens[nX,nPQUANT,3] += ".And.CN120VlQEx()"
				Else
					aAutoItens[nX,nPQUANT,3] := "CN120VlQEx()"
				EndIf
			Next nX
		EndIf

		//-- Se tudo valido, chama gravacao
		If Len(aAutoItens) > 0 .And. MsGetDAuto(aAutoItens,{|| CN120LiOKE()},{|| CN120TdOKE()},aAutoCab,aRotina[nOpc][4])
		 	CN120VldPn(3,aHeader,aCols)
		EndIf
	EndIf
Else
	//-- Monta variaveis para montagem do browse de planilhas
	CN120Plans(@oTempCNA,@aTitle,@aCampos,@cLine)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Painel de apresentacao                               ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	DEFINE WIZARD oWizard;
	TITLE STR0100; //-- Assitente - Excedente
	HEADER STR0101; //-- Excedente para competência não prevista
	TEXT cTexto;
	PANEL NEXT {||CN120VldPn(0,@oGetDados:aHeader,@oGetDados:aCols) };
	FINISH {|| .T. }

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Selecao do contrato e competencia                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	CREATE PANEL oWizard;
	HEADER STR0101; //-- Excedente para competência não prevista
	MESSAGE STR0102; //-- Selecione o contrato, competência e planilha
	BACK {||CN120VldBc(1)};
	PANEL NEXT {|| CN120VldPn(1,@oGetDados:aHeader,@oGetDados:aCols)};
	FINISH {|| .T. }

	TSay():New(07,10,{|| STR0103},oWizard:oMPanel[2],,,,,,.T.,,,60,10) //-- Contrato
	@05,040 MSGET cContra PICTURE PesqPict("CN9","CN9_NUMERO") F3 cConsSxb SIZE 60,9 VALID Empty(cContra) .Or. CN120VlCon(1,.T.,cFilCTR) OF oWizard:oMPanel[2] PIXEL

	TSay():New(07,130,{|| STR0104},oWizard:oMPanel[2],,,,,,.T.,,,100,10) //-- Competência
	oCbx := TComboBox():New(05,170,{|u| If(PCount()>0,cCompet:=u,cCompet)},,50,10,oWizard:oMPanel[2],,{|| CN120Compet(.T.,cFilCTR)},,,,.T.,,,,,,,,,cCompet)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Monta browse de planilhas   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oBrowse := TWBrowse():New(23,4,__DlgWidth(oWizard:oMPanel[2])-5,__DlgHeight(oWizard:oMPanel[2])-35,{|| {aCampos}},aTitle,{030,090},oWizard:oMPanel[2],,,,,,,,,,,,,"TRBCNA",.T.)
	oBrowse:bLine := &("{ || " +cLine +" }")
	oBrowse:bLDblClick := {|| If(!Empty(TRBCNA->CNA_NUMERO),((cPlan:= TRBCNA->CNA_NUMERO,cParcel:=TRBCNA->CNF_PARCEL),oBrowse:Refresh()),)}


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Selecao do contrato e competencia                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	CREATE PANEL oWizard;
	HEADER STR0101; //-- Excedente para competência não prevista
	MESSAGE STR0105; //-- Preencha os itens com as quantidades excedentes
	BACK{||CN120VldBc(2)};
	PANEL NEXT {|| CN120VldPn(2,@oGetDados:aHeader,@oGetDados:aCols)};
	FINISH {|| .T. }

	oGetDados := MsNewGetDados():New(05,10,__DlgHeight(oWizard:oMPanel[3])-30,__DlgWidth(oWizard:oMPanel[3])-5,GD_UPDATE,"CN120LiOKE","CN120TdOKE",,aAlter,,,,,,oWizard:oMPanel[3],aHeader,aCols)
	TSay():New(__DlgHeight(oWizard:oMPanel[3])-23,10,{|| STR0106},oWizard:oMPanel[3],,,,,,.T.,,,60,10) //-- Total da medição
	@__DlgHeight(oWizard:oMPanel[3])-25,60 MSGET oGetTot VAR nTotMed PICTURE PesqPict("CND","CND_VLTOT") PIXEL WHEN .F. SIZE 50,5 OF oWizard:oMPanel[3]

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Finalizacao da inclusão.           			        ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	CREATE PANEL oWizard;
	HEADER STR0101; //-- Excedente para competência não prevista
	MESSAGE STR0107; //-- Confirme a gravação da medição excedente
	FINISH {|| CN120VldPn(3,@oGetDados:aHeader,@oGetDados:aCols)}

	TCheckBox():New(30,10,STR0108,{|u| If(PCount()>0,lEncerra:=u,lEncerra)},oWizard:oMPanel[4],150,10,,,,,,,,.T.) //-- Processar encerramento da medição após gravação

	ACTIVATE WIZARD oWizard CENTERED

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Apaga arquivo temporario                           ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oTempCNA:Close()
	TecDestroy(oTempCNA)
EndIf

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³CN120VldPnºAutor  ³ Andre Anjos		 º Data ³  24/11/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Valida preenchimento dos paineis da medicao excedente para º±±
±±º          ³ competencia nao prevista.                                  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ CNTA120                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function CN120VldPn(nPainel,aHeader,aCols)
Local lRet     := .T.
Local cItem    := StrZero(1,TamSX3("CNE_ITEM")[1])
Local nSaveSX8 := GetSX8Len()

Do Case
	Case nPainel == 0
		oWizard:oCancel:lActive := .F.
		lBack := .F.
	Case nPainel == 1

		lRet := CNTVldCTR(cContra, CN9->CN9_FILCTR)

		//-- Verifica se escolheu a planilha
		If lRet .And. Empty(cPlan)
			Help(" ",1,"CNTA120_01")
			lRet := .F.
		EndIf

		If lRet .And. CN300RetSt('MEDEVE',0,cPlan,,,.F.)
			Help("",1,"CNTA120NEV",,STR0147,4,1)
			lRet := .F.
		EndIf

		//-- Preenche aHeader e aCols para proxima tela
		If lRet
			aCols := {}

			CNB->(dbSetOrder(1))
			CNB->(dbSeek(xFilial("CNB",cFilCTR)+cContra+cRevisa+cPlan))
			While !CNB->(EOF()) .And. CNB->(CNB_FILIAL+CNB_CONTRA+CNB_REVISA+CNB_NUMERO) == xFilial("CNB",cFilCTR)+cContra+cRevisa+cPlan
				aAdd(aCols,Array(Len(aHeader)+1))
				aTail(aCols)[GDFieldPos("CNE_ITEM",aHeader)] := cItem
				aTail(aCols)[GDFieldPos("CNE_PRODUT",aHeader)] := CNB->CNB_PRODUT
				aTail(aCols)[GDFieldPos("CNE_DESCRI",aHeader)] := Posicione("SB1",1,xFilial("SB1")+CNB->CNB_PRODUT,"B1_DESC")
				aTail(aCols)[GDFieldPos("UCNE_QUANT",aHeader)] := 0
				aTail(aCols)[GDFieldPos("CNE_VLUNIT",aHeader)] := 0
				aTail(aCols)[GDFieldPos("CNE_VLTOT",aHeader)] := 0
				aTail(aCols)[GDFieldPos("CNE_DTENT",aHeader)] := dDataBase
				aTail(aCols)[GDFieldPos("CNE_FLGCMS",aHeader)] := CriaVar("CNE_FLGCMS",.T.)
				aTail(aCols)[GDFieldPos("CNE_TS",aHeader)] := CNB->CNB_TS
				aTail(aCols)[GDFieldPos("CNE_TABPRC",aHeader)] := CNB->CNB_TABPRC
				aTail(aCols)[GDFieldPos("CNE_EXCEDE",aHeader)] := '1'
				aTail(aCols)[GDFieldPos("CNE_PEDTIT",aHeader)] := CNB->CNB_PEDTIT
				aTail(aCols)[Len(aHeader)+1] := .F.
				cItem := Soma1(cItem)
				CNB->(dbSkip())
			End

			nTotMed := 0

			oWizard:oCancel:lActive := .T.
		EndIf
	Case nPainel == 2
		If !lAuto
			lRet := oGetDados:LinhaOk() .And. oGetDados:TudoOk()
		EndIf
	Case nPainel == 3
		If lAuto .Or. (lRet := MsgYesNo(STR0109 +cCompet +STR0110)) //-- Confirma a geração de medição excedente para a competência ###, não prevista no cronograma deste contrato?

			//-- Prepara valores de memoria para gravacao
			If !lAuto
				RegToMemory("CND",.T.,.F.,.T.)
			EndIf
			
			CN9->(dbSetOrder(1))
			CN9->(dbSeek(xFilial("CN9",cFilCTR)+cContra+cRevisa))

			CNA->(dbSetOrder(1))
			CNA->(dbSeek(xFilial("CNA",cFilCTR)+cContra+cRevisa+cPlan))

			M->CND_CONTRA := CN9->CN9_NUMERO
			M->CND_REVISA := CN9->CN9_REVISA
			M->CND_CLIENT := CNA->CNA_CLIENT
			M->CND_LOJACL := CNA->CNA_LOJACL
			M->CND_CONDPG := CN9->CN9_CONDPG
			M->CND_VLCONT := CN9->CN9_VLATU
			M->CND_VLADIT := CN9->CN9_VLADIT
			M->CND_VLREAJ := CN9->CN9_VLREAJ
			M->CND_NUMERO := cPlan
			M->CND_COMPET := cCompet
			M->CND_PARCEL := cParcel
			M->CND_VLTOT  := nTotMed
			M->CND_MOEDA  := 1
			M->CND_DTVENC := dDataBase
			M->CND_SERVIC := '1'

			cNumMed := M->CND_NUMMED

			//-- Ajusta nome do campo de quantidade
			aHeader[GDFieldPos("UCNE_QUANT",aHeader),2] := "CNE_QUANT"

			//-- Grava medicao
			MsAguarde({|| CN130Grv(3,.F.,cCompet,nSaveSX8,{},{},{},aHeader,aCols,1)},STR0111) //-- Gravando medição

			If lEncerra
				Processa({|| CN120MedEnc(CND->(Recno()))})
			ElseIf !lAuto
				Aviso("CNTA120",STR0112 +cNumMed +".",{STR0155}) //-- Gerada medição número ###
			EndIf
		EndIf
EndCase

Return lRet

//-------------------------------------
/*/{Protheus.doc}  CN120VldBc()
Tratamento do botão voltar do Wizard de medições excedentes

@author jose.delmondes
@since  	09/12/2016
@version	P12
@param 		nPainel (Numero do painel)
@return 	Lógico, determina se realiza a volta
/*/
//-------------------------------------
Static Function CN120VldBc(nPainel)
Local lRet := .T.

Do Case
	Case nPainel == 1
		oWizard:oCancel:lActive := .T.
		lBack := .T.
	Case nPainel == 2
		oWizard:oCancel:lActive := .F.
		lBack := .F.
EndCase

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³CN120VlQExºAutor  ³ Andre Anjos		 º Data ³  24/11/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Valida a quantidade digitada como excedente em competencia º±±
±±º          ³ nao prevista e gatilha o preco conforme tabela.            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ CNTA120                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function CN120VlQEx()
Local lRet     := .T.
Local nPrcUnit := 0

lRet := Positivo()

//-- Gatilha preco unitario e valor total
If lRet
	CN9->(dbSetOrder(1))
	CN9->(dbSeek(xFilial("CN9",cFilCTR)+cContra+cRevisa))

	//-- Obtem preco unitario pela tabela de preco
	nPrcUnit := MaTabPrVen(aCols[n,GDFieldPos("CNE_TABPRC")],aCols[n,GDFieldPos("CNE_PRODUT")],M->UCNE_QUANT,CN9->CN9_CLIENT,CN9->CN9_LOJACL,1,dDataBase)

	aCols[n,GDFieldPos("CNE_VLUNIT")] := nPrcUnit
	nTotMed += (M->UCNE_QUANT * nPrcUnit) - aCols[n,GDFieldPos("CNE_VLTOT")]
	aCols[n,GDFieldPos("CNE_VLTOT")] := M->UCNE_QUANT * aCols[n,GDFieldPos("CNE_VLUNIT")]

	If !lAuto
		oGetTot:Refresh()
	EndIf
EndIf

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³CN120LiOKEºAutor  ³ Andre Anjos        º Data ³  29/11/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Valida linha da medicao excedente para competencia nao     º±±
±±º          ³ prevista.                                                  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ CNTA120													  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function CN120LiOKE()
Local lRet := .T.

//-- Verifica se ha item com quantidade sem preco
If aCols[n,GDFieldPos("UCNE_QUANT")] > 0 .And. aCols[n,GDFieldPos("CNE_VLUNIT")] == 0
	Help(1," ","OBRIGAT2",,RetTitle("CNE_VLUNIT"),3,0)
	lRet := .F.
EndIf

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³CN120TdOkEºAutor  ³ Andre Anjos		 º Data ³  29/11/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Valida GetDados da medicao excedente para competencia nao  º±±
±±º          ³ prevista.                                                  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ CNTA120													  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function CN120TdOkE()
Local lRet := .T.

If Empty(nTotMed)
	Aviso(STR0114,STR0113,{STR0155}) //-- Não há quantidade para geração de medição.
	lRet := .F.
EndIf

Return lRet
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³CN120Contab³ Autor ³ Aline Sebrian         ³ Data ³24/06/2013³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Contabiliza a Retencao do Contrato                          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN120Contab()                                               ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function CN120Contab(cPadrao)

LOCAL aArea     := GetArea()

LOCAL cLoteCtb  := ""

LOCAL lDigita   := If(MV_PAR02==1,.T.,.F.)
LOCAL lPadrao   := .F.

LOCAL nHdlPrv   := 0
LOCAL nTotal    := 0

Private cArquivo := " "

dbSelectArea("CND")
dbSetOrder(1)

lPadrao := VerPadrao(cPadrao)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Lancamento Contabil³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If ( lPadrao .and. MV_PAR01 == 1 )

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica o numero do lote contabil                        ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea("SX5")
	dbSetOrder(1)
	If MsSeek(xFilial()+"09GCT")
		cLoteCtb := AllTrim(X5Descri())
	Else
		cLoteCtb := "GCT "
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Executa o execblock                                       ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If At(UPPER("EXEC"),X5Descri()) > 0
		cLoteCtb := &(X5Descri())
	EndIf

	nHdlPrv := HeadProva(cLoteCtb,"CNTA120",Substr(cUsuario,7,6),@cArquivo)
	nTotal  += DetProva(nHdlPrv,cPadrao,"CNTA120",cLoteCtb)
	RodaProva(nHdlPrv,nTotal)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Envia para Lancamento Contabil³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cA100Incl(cArquivo,nHdlPrv,3,cLoteCtb,lDigita,.F.)
EndIf

RestArea(aArea)
Return(.T.)

//-------------------------------------------------------------------
/*{Protheus.doc} CNTVldCTR
Realiza a validação de contratos com base na tabela CPD

@author leonardo.quintania
@since 09/10/2013
@version P11.90
*/
//-------------------------------------------------------------------
Function CNTVldCTR(cContrato,cFilCtr)
Local cCod		:= RetCodUsr()
Local aGrp 		:= UsrRetGrp(UsrRetName(cCod)) //Carrega Grupos do usuario
Local lVldVige	:= GetNewPar("MV_CNFVIGE","N") == "N"
Local lRet		:= .F.
Local nX		:= 0
Local nRecCount	:= 0
Local cGrps		:= ''
Local cQuery1	:= ''
Local cQuery2	:= ''
Local cQuery3	:= ''
Local cQuery4	:= ''
Local cQuery5	:= ''
Local cQuery	:= ''
Local cAliasCN9 := ''
Local cCn120Sxb := ''
Local cConsPad	:= ''
Local aArea 	:= GetArea()
Local lJob      := GetRemoteType() == -1

Default cContrato 	:= ""
Default cFilCtr 	:= ""

If !IsInCallStack('GetlkRet') .And. !IsBlind()
	//Executa Query para carregar produtos da planilha
	cAliasCN9 := GetNextAlias()

	BeginSQL Alias cAliasCN9
		SELECT	DISTINCT CN9.R_E_C_N_O_,
						 CN9.CN9_FILCTR,
						 CN9.CN9_NUMERO,
						 CN9.CN9_REVISA,

						 (	SELECT COUNT(DISTINCT CN9.R_E_C_N_O_)
						 	FROM	%Table:CN9% CN9

						 	JOIN	%Table:CPD% CPD ON
						 	CPD.CPD_FILIAL = CN9.CN9_FILIAL AND
						 	CPD.CPD_CONTRA = CN9.CN9_NUMERO AND
						 	CPD.CPD_FILAUT = %exp:cFilAnt% 	AND
						 	CPD.%NotDel%

						 	WHERE
						 	CN9.CN9_NUMERO = %exp:cContrato%  AND
						 	CN9.CN9_SITUAC = '05' AND
						 	CN9.%NotDel%
						 ) AS CN9_COUNT

		FROM	%Table:CN9% CN9

		JOIN	%Table:CPD% CPD ON
		CPD.CPD_FILIAL = CN9.CN9_FILIAL AND
		CPD.CPD_CONTRA = CN9.CN9_NUMERO AND
		CPD.CPD_FILAUT = %exp:cFilAnt% 	AND
		CPD.%NotDel%

		WHERE
		CN9.CN9_NUMERO = %exp:cContrato%  AND
		CN9.CN9_SITUAC = '05' AND
		CN9.%NotDel%
	EndSQL

	nRecCount := (cAliasCN9)->CN9_COUNT

	If nRecCount > 1
		If ExistBlock("CN120SXB")
			cConsPad := If(Valtype(cCn120Sxb:=ExecBlock("CN120SXB",.F.,.F.))=="C",cCn120Sxb,"CN9003")
		Else
			cConsPad := "CN9003"
		EndIf
		lRet := !ConPad1(,,,cConsPad,,,.F.,,) // Chama a consulta padrao

		cFilCtr := CN9->CN9_FILCTR
	ElseIf nRecCount != 0
		cFilCtr := (cAliasCN9)->CN9_FILCTR
	End

	(cAliasCN9)->(dbCloseArea())
EndIf

If !lRet //- Condição negativa para retrocompatibilidade.
	For nX:=1 to len(aGrp)
		cGrps += "'"+aGrp[nX]+"',"
	Next

	cGrps := SubStr(cGrps,1,len(cGrps)-1)

	cQuery1 := " SELECT CN9_NUMERO, MAX(CN9_REVISA) AS CN9_REVISA,CN9_FILCTR "
	cQuery1 += " FROM " + RetSqlName("CN9") + " CN9 , "+ RetSqlName("CNN") + " CNN, "+ RetSqlName("CPD") + " CPD "
	cQuery1 += " WHERE CN9_SITUAC   = '05' AND "
	cQuery1 += " CN9.CN9_NUMERO = '"+PADR(cContrato,Len(CN9->CN9_NUMERO))+"' AND "
	cQuery1 += " CN9.CN9_FILCTR = '"+cFilCTR+"' AND "
	cQuery1 += " CPD.CPD_FILAUT = '"+cFilAnt+"' AND "
	cQuery1 += " CPD.CPD_FILIAL = CN9.CN9_FILIAL AND "
	cQuery1 += " CPD.CPD_CONTRA = CN9.CN9_NUMERO AND "

	If lVldVige
		cQuery1 += " ('"+DToS(dDataBase)+"' BETWEEN CN9_DTINIC AND CN9_DTFIM )  AND "
	EndIf
	cQuery1+= " CNN.CNN_FILIAL = '"+ xFilial("CNN", cFilCTR)+ "' AND "
	cQuery1+= " CPD.CPD_FILIAL = CN9_FILIAL AND "
	cQuery1+= " CNN.CNN_CONTRA = CN9_NUMERO AND "

	cQuery2 := " CN9_VLDCTR ='2' "
	
	cQuery3 := " CN9_VLDCTR IN(' ','1') "
	
	If !lJob //Se for via Job, não valida usuário	
		cQuery3 += " AND (CNN.CNN_USRCOD   = '"+ cCod +"'"
				
		If len(aGrp) > 0
			cQuery3 += " OR CNN.CNN_GRPCOD IN ("+ cGrps +"))"
		Else
		    cQuery3 += ")"
		EndIf
	EndIf
	
	cQuery4 := " AND CNN.D_E_L_E_T_	= '' "
	cQuery4 += " AND CN9.D_E_L_E_T_	= '' "
	cQuery4 += " AND CPD.D_E_L_E_T_	= '' "
	cQuery4 += " GROUP BY CN9_NUMERO,CN9_FILCTR "
	cQuery5 := " ORDER BY CN9_NUMERO,CN9_REVISA "


	cQuery := cQuery1
	cQuery += cQuery2+" "+cQuery4
	cQuery += " UNION "
	cQuery += cQuery1
	cQuery += cQuery3+" "+cQuery4+" "+cQuery5

	cQuery := ChangeQuery(cQuery)
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TRBCN9",.F.,.T.)

	While !TRBCN9->(Eof())
		If AllTrim(TRBCN9->CN9_NUMERO)== AllTrim(cContrato)
			lRet:= .T.

			If !Empty(TRBCN9->CN9_FILCTR) .And. !(cFilCTR == TRBCN9->CN9_FILCTR)
				cFilCTR := TRBCN9->CN9_FILCTR
			EndIf

			Exit
		EndIf
		TRBCN9->(dbSkip())
	EndDo

	If !lRet
		dbSelectArea("CN9")
		CN9->(dbSetOrder(1))
		If MsSeek(xFilial("CN9")+cContrato+CnGetRevVg(cContrato))
			If lVldVige .And. (dDataBase < CN9->CN9_DTINIC  .Or. dDataBase > CN9->CN9_DTFIM)
				Help(" ",1,"CNNOVIG")
			Else
				Help(" ",1,"CNNOTRANS")
			EndIf
		Else
			Help(" ",1,"REGNOIS")
		EndIf
	EndIf

	TRBCN9->(dbCloseArea())
EndIf
RestArea(aArea)

Return lRet

//-------------------------------------------------------------------
/*{Protheus.doc} CNTVldPlan
Valida condições necessarias para realizar medições em outra filial

@author leonardo.quintania
@since 09/10/2013
@version P11.90
*/
//-------------------------------------------------------------------
Function CNTVldPlan(cContra,cRevisa,cPlan)
Local lRet		:= .T.
Local aArea := GetArea()

If Empty(cPlan)
	Help( " ", 1, 'CNTA120_01' )
	lRet:= .F.
Else
	If CNB->(dbSeek(xFilial('CNB',cFilCTR) +  cContra + cRevisa + cPlan  )) //Cadastro de produtos
		While !CNB->(Eof()) .And. CNB->(CNB_FILIAL+CNB_CONTRA+CNB_REVISA+CNB_NUMERO) == xFilial('CNB',cFilCTR)+cContra+cRevisa+cPlan
			If !SB1->(dbSeek(xFilial('SB1') + CNB->CNB_PRODUT))
				Help( " ", 1, 'NOPRODFILIAL' )
				lRet:= .F.
				Exit
			EndIf

			If lRet .And. !Empty(CNB->CNB_TE)
				If !SF4->(dbSeek(xFilial('SF4') + CNB->CNB_TE))
					Help( " ", 1, 'NOTESFILIAL' )
					lRet:= .F.
					Exit
				EndIf
			EndIf

			If lRet .And. !Empty(CNB->CNB_TS)
				If !SF4->(dbSeek(xFilial('SF4') + CNB->CNB_TS))
					Help( " ", 1, 'NOTESFILIAL' )
					lRet:= .F.
					Exit
				EndIf
			EndIf

			CNB->(dbSkip())
		EndDo
	EndIf

	If lRet .And. !SE4->(dbSeek(xFilial('SE4')+CN9->CN9_CONDPG)) //Condição de Pagamento
		Help( " ", 1, 'NOCONDFILIAL' )
		lRet:= .F.
	EndIf


EndIf

RestArea(aArea)

Return lRet

//-------------------------------------------------------------------
/*{Protheus.doc} CN120VerDoc
Verifica quais documentos devem ser gerados no Gestão de Contratos e Serviços
1 - Pedido
2 - Titulo
3 - Pedido/Titulo
@author leonardo.quintania
@since 22/11/2013
@version P11.90
*/
//-------------------------------------------------------------------
Function CN120VerDoc(cMedicao)
Local nRet		:= 1
Local aArea	:= GetArea()


BeginSql Alias "CNETMP"

SELECT * FROM
	(SELECT COUNT(*) PEDTIT1
	FROM %Table:CNE% CNE
	WHERE CNE.CNE_FILIAL = %xFilial:CNE%
		AND CNE.CNE_NUMMED = %Exp:cMedicao%
		AND CNE.CNE_PEDTIT = '1'
		AND CNE.%NotDel% ) PEDTIT1,
	(SELECT COUNT(*) PEDTIT2
	FROM %Table:CNE% CNE
	WHERE CNE.CNE_FILIAL = %xFilial:CNE%
		AND CNE.CNE_NUMMED = %Exp:cMedicao%
		AND CNE.CNE_PEDTIT = '2'
		AND CNE.%NotDel% ) PEDTIT2

EndSql

If CNETMP->PEDTIT1 > 0 .And. CNETMP->PEDTIT2 > 0
	nRet := 3	//-- Medicao com pedido e titulo
ElseIf CNETMP->PEDTIT1 > 0
	nRet:= 1	//-- Medicao com pedido, somente
Else
	nRet:= 2	//-- Medicao com titulo, somente
EndIf

CNETMP->(dbCloseArea())


RestArea(aArea)
Return nRet

//-------------------------------------------------------------------
/*{Protheus.doc} CN120TitSE1
Executa ExecAuto do FINA040 contas a receber
@author leonardo.quintania
@since 22/11/2013
@version P11.90
*/
//-------------------------------------------------------------------
Function C120TitSE1(aRotAuto,cNumTit)

Local aArea	:= GetArea()
Local aCond	:= {{aRotAuto[ProcH(aRotAuto,"E1_VENCTO"),2],aRotAuto[ProcH(aRotAuto,"E1_VALOR"),2]}}
Local aVend	:= CtaVend(CND->CND_CONTRA, CND->CND_FILCTR)
Local aTitUser := {}

Local cRetPrf	:= PadR(SuperGetMV("MV_CNPREMD",.F.,"MED"),Len(SE1->E1_PREFIXO))
Local cTpTit	:= PadR(SuperGetMV("MV_CNTPTMD",.F.,"BOL"),Len(SE1->E1_TIPO))
Local cRetNat	:= PadR(SuperGetMv("MV_CNNATMD",.F.,""),Len(SE1->E1_NATUREZ))
Local cParcela:= StrZero(1,Len(SE1->E1_PARCELA))

Local lRet		:= .T.
Local lGeraCP	:= SuperGetMV("MV_CNPROCP",.F.,"N") == "S"
Local lNMedTit	:= SuperGetMV("MV_NMEDTIT",.F., '1') == '2'
Local lCN120ALT	:= ExistBlock("CN120ALT")

Local nX		:= 0
Local nY		:= 0
Local nQtdVend	:= Min( Fa440CntVen() , Len(aVend) )

Private lMsErroAuto := .F.

CN9->(dbSetOrder(1))
If CN9->(MsSeek(xFilial("CN9")+CND->CND_CONTRA+CND->CND_REVISA)).And. !Empty(CN9->CN9_NATURE)
	cRetNat:=	CN9->CN9_NATURE
EndIf

If lNMedTit
	cNumTit := CND->CND_NUMMED
Else
	BeginSql Alias "SE1TMP"
		SELECT MAX(SE1.E1_NUM) AS E1_NUM
		FROM %Table:SE1% SE1
		WHERE SE1.E1_FILIAL  = %xFilial:SE1%
			AND SE1.E1_PREFIXO =%Exp:cRetPrf%
			AND SE1.%NotDel%
	EndSql

	cNumTit := Soma1(SE1TMP->E1_NUM)
	SE1TMP->(dbCloseArea())
EndIf

//-- Verifica se o codigo está disponivel
SE1->(dbSetOrder(1))
While SE1->(dbSeek(xFilial("SE1")+cRetPrf+cNumTit))
	cNumTit += Soma1(cNumTit)
End

If ( ExistBlock("CN120NAT") )
	cRetNat := ExecBlock("CN120NAT",.F.,.F.,{CND->CND_FILIAL, CND->CND_NUMMED})
EndIf

dbSelectArea("SED")
dbsetOrder(1)

If !SED->(dbSeek(xFilial("SED")+cRetNat))
	Help("",1,"CNTA120NAT",,STR0148,4,1,,,,,,{STR0149})
	lRet := .F.
EndIf

If lRet
	If lGeraCP
		aCond := Condicao(aCond[1,2],CND->CND_CONDPG,,aRotAuto[ProcH(aRotAuto,"E1_EMISSAO"),2]) 
   	EndIf

	For nX := 1 To Len(aCond)

		If nX == 1
			//-- Preenchimento de array para execauto FINA040
		  	aAdd(aRotAuto,{"E1_NUM",cNumTit,NIL})
		  	aAdd(aRotAuto,{"E1_PREFIXO",cRetPrf,NIL})
		  	aAdd(aRotAuto,{"E1_NATUREZ",cRetNat,NIL})
		  	aAdd(aRotAuto,{"E1_PARCELA",cParcela,NIL})
		  	aAdd(aRotAuto,{"E1_TIPO",cTpTit,NIL})		  	
		Else
			aRotAuto[ProcH(aRotAuto,"E1_PARCELA"),2] := cParcela
		EndIf

	  	For nY := 1 To nQtdVend
		  aAdd(aRotAuto,{ "E1_VEND" + Str(nY,1) 	, aVend[nY][1] , NIL })
		  aAdd(aRotAuto,{ "E1_COMIS" + Str(nY,1)	, aVend[nY][2] , NIL })
	  	Next nY

  		aRotAuto[ProcH(aRotAuto,"E1_VENCTO"),2] := aCond[nX,1]
  		aRotAuto[ProcH(aRotAuto,"E1_VENCREA"),2] := DataValida(aCond[nX,1],.T.)
 	 	aRotAuto[ProcH(aRotAuto,"E1_VENCORI"),2] := aCond[nX,1]
  		aRotAuto[ProcH(aRotAuto,"E1_VALOR"),2] := aCond[nX,2]

  		If lCN120ALT //PE que permite alterar o Array do titulo financeiro ao encerrar a medição.
			aTitUser:= ExecBlock("CN120ALT",.F.,.F.,{aRotAuto,"2"})
			If ( ValType(aTitUser) == "A" )
				aRotAuto := aTitUser
			EndIf
		EndIf

	  	MSExecAuto({|x,y| FINA040(x,y)},aRotAuto,3)

		lRet := !lMsErroAuto

	  	If lMsErroAuto
	    	MostraErro()
	 		Exit
	  	EndIf

	  	cParcela := Soma1(cParcela)

 	Next nX
EndIf

RestArea(aArea)
Return lRet

//-------------------------------------------------------------------
/*{Protheus.doc} C120TitSE2
Executa ExecAuto do FINA050 Contas a Pagar
@author leonardo.quintania
@since 22/11/2013
@version P11.90
*/
//-------------------------------------------------------------------
Function C120TitSE2(aRotAuto,cNumTit)
Local aAreas	:= {CN9->(GetArea()),SED->(GetArea()),SE2->(GetArea()),SA2->(GetArea()),GetArea()}
Local lRet		:= .T.
Local lGeraCP	:= SuperGetMV("MV_CNPROCP",.F.,"N") == "S"
Local lNMedTit	:= SuperGetMV("MV_NMEDTIT",.F., '1') == '2'
Local lCN120ALT	:= ExistBlock("CN120ALT")
Local cRetPrf	:= PadR(SuperGetMV("MV_CNPREMD",.F.,"MED"),Len(SE2->E2_PREFIXO))
Local cTpTit	:= PadR(SuperGetMV("MV_CNTPTMD",.F.,"BOL"),Len(SE2->E2_TIPO))
Local cRetNat	:= PadR(SuperGetMv("MV_CNNATMD",.F.,""),Len(SE2->E2_NATUREZ))
Local cParcela	:= StrZero(1,Len(SE2->E2_PARCELA))
Local aCond		:= {{aRotAuto[ProcH(aRotAuto,"E2_VENCTO"),2],aRotAuto[ProcH(aRotAuto,"E2_VALOR"),2]}}
Local aTitUser := {}
Local nX		:= 0

SA2->(dbSetOrder(1))//A2_FILIAL+A2_COD+A2_LOJA
CN9->(dbSetOrder(1))
If CN9->(MsSeek(CND->(xFilial("CN9", CND_FILCTR) + CND_CONTRA + CND_REVISA))).And. !Empty(CN9->CN9_NATURE)
	cRetNat:=	CN9->CN9_NATURE
ElseIf(SA2->(DbSeek(CND->(xFilial("SA2", CND_FILCTR) + CND_FORNEC + CND_LJFORN))) .And. !Empty(SA2->A2_NATUREZ))
	cRetNat:=	SA2->A2_NATUREZ
EndIf

Private lMsErroAuto := .F.

If lNMedTit
	cNumTit := CND->CND_NUMMED
Else
	BeginSql Alias "SE2TMP"
		SELECT MAX(SE2.E2_NUM) AS E2_NUM
		FROM %Table:SE2% SE2
		WHERE SE2.E2_FILIAL  = %xFilial:SE2%
			AND SE2.E2_PREFIXO =%Exp:cRetPrf%
			AND SE2.%NotDel%
	EndSql

	cNumTit := Soma1(SE2TMP->E2_NUM)
	SE2TMP->(dbCloseArea())
EndIf

//-- Verifica se o codigo está disponivel
SE2->(dbSetOrder(1))
While SE2->(dbSeek(xFilial("SE2")+cRetPrf+cNumTit))
	cNumTit += Soma1(cNumTit)
End

If ( ExistBlock("CN120NAT") )
	cRetNat := ExecBlock("CN120NAT",.F.,.F.,{CND->CND_FILIAL, CND->CND_NUMMED})
EndIf

dbSelectArea("SED")
dbsetOrder(1)

If !SED->(dbSeek(xFilial("SED")+cRetNat))
	Help("",1,"CNTA120NAT",,STR0148,4,1,,,,,,{STR0149})
	lRet := .F.
EndIf

If lRet	
	If lGeraCP			
		aCond	:= Condicao(aCond[1,2],CND->CND_CONDPG,,aRotAuto[ProcH(aRotAuto,"E2_EMISSAO"),2])	
	EndIf

   For nX := 1 To Len(aCond)
   		//-- Preenchimento de array para execauto FINA040
   		If nX == 1
		  	aAdd(aRotAuto,{"E2_NUM",cNumTit,NIL})
		  	aAdd(aRotAuto,{"E2_PREFIXO",cRetPrf,NIL})
		  	aAdd(aRotAuto,{"E2_NATUREZ",cRetNat,NIL})
			aAdd(aRotAuto,{"E2_PARCELA",cParcela,NIL})
			aAdd(aRotAuto,{"E2_TIPO",cTpTit,NIL})
		Else
			aRotAuto[ProcH(aRotAuto,"E2_PARCELA"),2] := cParcela
		EndIf

		aRotAuto[ProcH(aRotAuto,"E2_VENCTO"),2] := aCond[nX,1]
		aRotAuto[ProcH(aRotAuto,"E2_VALOR"),2] := aCond[nX,2]
		aRotAuto[ProcH(aRotAuto,"E2_VENCREA"),2] := DataValida(aCond[nX,1],.T.)
		aRotAuto[ProcH(aRotAuto,"E2_VENCORI"),2] := aCond[nX,1]

	  	If lCN120ALT //PE que permite alterar o Array do titulo financeiro ao encerrar a medição.
			aTitUser:= ExecBlock("CN120ALT",.F.,.F.,{aRotAuto,"1"})
			If ( ValType(aTitUser) == "A" )
				aRotAuto := aTitUser
			EndIf
		EndIf

	  	MSExecAuto({|x,y| FINA050(x, y)},aRotAuto,3)

	  	lRet := !lMsErroAuto

	  	If lMsErroAuto
			MostraErro()
		 	Exit
	  	EndIf

	  	cParcela := Soma1(cParcela)

  	Next nX
EndIf

aEval(aAreas,{|x|RestArea(x)})
Return lRet

//-------------------------------------------------------------------
/*{Protheus.doc} Cn120VlTES(cTipo)
Validação do tipo de entrada ou saida da medição
@author israel.escorizza
@since 12/04/2016
@version P12
*/
//-------------------------------------------------------------------
Function Cn120VlTES(cTipo)
Local lRet			:= .T.
Local aArea		:= GetArea()
Local aRows		:= FWSaveRows()
Local cReadVar	:= ReadVar()
Local xConteudo	:= &(cReadVar)
Local cPedTit		:= aCols[n][aScan(aHeader,{|x| x[2] == "CNE_PEDTIT"})]

Default cTipo := ""

If !Empty(xConteudo) .And. ((cTipo == 'TE' .And. xConteudo > "500") .Or. (cTipo == 'TS' .And. xConteudo < "500"))
	lRet := .F.
	Help (" ",1,"CN120TES01",,STR0160,1,1)
EndIf

If lRet .And. !Empty(cTipo) .And. cPedTit != "2" .And. Empty(xConteudo)
	lRet := .F.
	Help(" ",1,"CN120TES02",,STR0161,1,1)  //"É obrigatório informar uma "
EndIf

FWRestRows(aRows)
RestArea(aArea)
Return lRet

//-------------------------------------------------------------------
/*{Protheus.doc} CN120EstSld
Estorna Saldo do titulo na planilha
1 - Pedido
2 - Titulo
3 - Pedido/Titulo
@author leonardo.quintania
@since 22/11/2013
@version P11.90
*/
//-------------------------------------------------------------------
Function CN120EstSld(cMedicao)
Local aArea := GetArea()

BeginSql Alias "CNETMP"
	SELECT *
	FROM	%Table:CNE% CNE
	WHERE CNE.CNE_FILIAL = %xFilial:CNE%
		AND CNE.CNE_NUMMED = %Exp:cMedicao%
		AND CNE.CNE_PEDTIT = '2'
		AND CNE.%NotDel%
EndSql

While !CNETMP->(EOF())
	CtaAvalGCT(2,{},CNETMP->CNE_CONTRA,CNETMP->CNE_NUMERO,CNETMP->CNE_ITEM,CNETMP->CNE_QUANT,,CNETMP->CNE_NUMMED,CNETMP->CNE_VLTOT,CNETMP->CNE_REVISA)
	CNETMP->(dbSkip())
End
CNETMP->(dbCloseArea())

RestArea(aArea)
Return

//-------------------------------------------------------------------
/*{Protheus.doc} ProcH
Pesquisa em array de execauto
*/
//-------------------------------------------------------------------
Static Function ProcH(aArray,cValor)
Return aScan(aArray,{|x| Trim(x[1]) == cValor })

//-------------------------------------------------------------------
/*{Protheus.doc} CN120EstSld
Valida campo CNE-CODNE
@author
@since 13/07/2015
@version P12.1.6
*/
//-------------------------------------------------------------------
Function ValidCODED()
Local lRet 		:= .T.
Local aArea		:= GetArea()
Local aSaveLines  := FWSaveRows()
Local oModel      := FwModelActive()
Local lMVC        := ValType(oModel) <> "U"
Local oModelCND   := Nil
Local oModelCNE   := Nil

//Tratativas para tela antiga de MVC
If !lMVC
DbSelectArea("CN9")
CN9->(dbSetOrder(1))
If CN9->(dbSeek(xFilial("CN9")+ M->CND_CONTRA + M->CND_REVISA))
	//Tratativa para validar o Código da NE
	If !Empty(M->CNE_CODNE)
		//Posiciona na CX0
		DbSelectArea("CX0")
		CX0->(dbSetOrder(2))
		If CX0->(dbSeek(xFilial("CX0")+ CN9->CN9_CODED + CN9->CN9_NUMPR))
			While CX0->(CX0_FILIAL+CX0_CODEDT+CX0_NUMPRO) == xFilial("CX0")+ CN9->CN9_CODED + CN9->CN9_NUMPR
				If (CX0->CX0_CODNE == M->CNE_CODNE)
					lFound := .T.
					If CX0->CX0_PRZEXC < M->CND_DTINIC
				Help(" ",1,'ValidCODED',,STR0144,4,1) //O prazo de execução da nota de empenho encontra-se vencido.
						lRet := .F.
					Endif
					Exit
			EndIf
				CX0->(dbSkip())
			Enddo

			If ! lFound
				lRet := .F.
				Help(" ",1,'ValidCODED',,STR0162,4,1)
			EndIf
		Else
			Help(" ",1,'ValidCODED',,STR0163,4,1)
			lRet := .F.
		EndIf
	EndIf

	//Tratativa para validar Item da NE
	If 	!Empty(M->CNE_ITEMNE)
		//Posiciona na CX1
		DbSelectArea("CX1")
		CX1->(dbSetOrder(2))
		If CX1->(dbSeek(xFilial("CX1")+ CX0->CX0_CODNE + M->CNE_ITEMNE))
			If (CX1->CX1_CODNE <> M->CNE_CODNE) .And. (CX1->CX1_ITEM <> M->CNE_ITEMNE)
				lRet := .F.
				Help(" ",1,'ValidCODED',,STR0164,4,1)
			EndIf
		Else
			Help(" ",1,'ValidCODED',,STR0165,4,1)
			lRet := .F.
		EndIf
	EndIf
EndIf
//Tratativa para usar com a nova tela de medição CNTA121
Else
	oModelCND   := oModel:GetModel("CNDMASTER")
  	oModelCNE   := oModel:GetModel("CNEDETAIL")
  	DbSelectArea("CN9")
  	CN9->(dbSetOrder(1))
  	If CN9->(dbSeek(xFilial("CN9")+ oModelCND:GetValue("CND_CONTRA") + oModelCND:GetValue("CND_REVISA")))
		//Tratativa para validar o Código da NE
		If !Empty(oModelCNE:GetValue("CNE_CODNE"))
  			//Posiciona na CX0
  			DbSelectArea("CX0")
  			CX0->(dbSetOrder(2))
  			If CX0->(dbSeek(xFilial("CX0")+ CN9->CN9_CODED + CN9->CN9_NUMPR))
				If (CX0->CX0_CODNE <> oModelCNE:GetValue("CNE_CODNE"))
 					lRet := .F.
 					Help(" ",1,'ValidCODED',,STR0162,4,1)
        		EndIf
  			Else
        		Help(" ",1,'ValidCODED',,STR0163,4,1)
              lRet := .F.
           EndIf
    	EndIf

       //Tratativa para validar Item da NE
		If !Empty(oModelCNE:GetValue("CNE_ITEMNE"))
  			//Posiciona na CX1
  			DbSelectArea("CX1")
  			CX1->(dbSetOrder(2))
  			If CX1->(dbSeek(xFilial("CX1")+ CX0->CX0_CODNE + oModelCNE:GetValue("CNE_ITEMNE")))
				If (CX1->CX1_CODNE <> oModelCNE:GetValue("CNE_CODNE")) .And. (CX1->CX1_ITEM <> oModelCNE:GetValue("CNE_ITEMNE"))
 					lRet := .F.
 					Help(" ",1,'ValidCODED',,STR0164,4,1)
        		EndIf
  			Else
        		Help(" ",1,'ValidCODED',,STR0165,4,1)
        		lRet := .F.
  			EndIf
		EndIf
	EndIf
EndIf

RestArea(aArea)
FWRestRows( aSaveLines )
Return lRet
//-------------------------------------------------------------------
/*/{Protheus.doc} Cn120GCXJ()
Grava tabela auxiliar

@author Flavio Lopes Rasta
@since 27/07/2014
@version 1.0
@Param 	nOpc:	1-Inclusao
				2-Exclusao
/*/
//-------------------------------------------------------------------
Function Cn120GCXJ(aPedCXJ,nOpc,cContra,cNumMed)
Local nX	:= 1
Local aAreaCXJ	:= CXJ->(GetArea())

Do Case
	Case nOpc == 1 .And. !Empty(aPedCXJ)	//Inclusão

		For nX:=1 To Len(aPedCXJ)
			RecLock("CXJ",.T.)

			CXJ->CXJ_FILIAL	:= xFilial("CXJ")
			CXJ->CXJ_NUMPED	:= aPedCXJ[nX][1]
			CXJ->CXJ_ITEMPE	:= aPedCXJ[nX][2]
			CXJ->CXJ_CONTRA	:= aPedCXJ[nX][3]
			CXJ->CXJ_REVGER	:= aPedCXJ[nX][4]
			CXJ->CXJ_NUMMED	:= aPedCXJ[nX][5]
			CXJ->CXJ_NUMPLA	:= aPedCXJ[nX][6]
			CXJ->CXJ_ITEMPL	:= aPedCXJ[nX][7]
			CXJ->CXJ_ID		:= aPedCXJ[nX][8]
			CXJ->CXJ_PRTENV	:= aPedCXJ[nX][9]

			MsUnlock()
		Next nX

	Case nOpc == 2	//Exclusão

		dbSelectArea("CXJ")
		dbSetOrder(1)
		If(dbSeek(xFilial("CXJ")+cContra+cNumMed))
			While !CXJ->(Eof()) .And. CXJ->(CXJ_FILIAL+CXJ_CONTRA+CXJ_NUMMED) == xFilial('CXJ')+cContra+cNumMed
				RecLock("CXJ",.F.)
				CXJ->(dbDelete())
				CXJ->(MsUnlock())
				CXJ->(dbSkip())
			EndDo
		EndIf
EndCase

RestArea(aAreaCXJ)

Return

//-------------------------------------------------------------------
/*{Protheus.doc} C120CptFim
Função para verificar maior data de competência disponivel para medição.
@author israel.escorizza
@since 03/11/2016
@version V12.1.7
*/
//-------------------------------------------------------------------
Function  C120CptFim(cContra,cRevisa,cDataFim)
Local aArea		:= GetArea()
Local aSaveLines	:= FwSaveRows()
Local aDataFim	:= {}
Local aDataQry	:= {}
Local cQuery		:= ""
Local cAliasTmp	:= ""

Default cContra 	:= CN9->CN9_NUMERO
Default cRevisa 	:= CN9->CN9_REVISA
Default cDataFim	:= cValToChar(Month(CN9->CN9_DTFIM)) +"/"+ cValToChar(Year(CN9->CN9_DTFIM))

cQuery += " SELECT DISTINCT CNF.CNF_COMPET"
cQuery += " FROM "
cQuery += RetSqlName("CNA")+" CNA, "
cQuery += RetSqlName("CPD")+" CPD, "
cQuery += RetSqlName("CNF")+" CNF  "
cQuery += " WHERE "
cQuery += "     CNA.CNA_CONTRA = '" + cContra +"' "
cQuery += " AND CNA.CNA_REVISA = '" + cRevisa +"' "
cQuery += " AND CNA.CNA_CRONOG <> '"+Space(TamSX3("CNA_CRONOG")[1])+"' "
cQuery += " AND CNA.CNA_SALDO > 0 "
cQuery += " AND CNA.D_E_L_E_T_ = ' ' "
cQuery += " AND CPD.CPD_FILIAL = CNA.CNA_FILIAL"
cQuery += " AND CPD.CPD_CONTRA = CNA.CNA_CONTRA "
cQuery += " AND CPD.CPD_NUMPLA = CNA.CNA_NUMERO "
cQuery += " AND CPD.CPD_FILAUT = '" + cFilAnt  +"' "
cQuery += " AND CNF.CNF_NUMERO = CNA.CNA_CRONOG "
cQuery += " AND CNF.CNF_CONTRA = CNA.CNA_CONTRA "
cQuery += " AND CNF.CNF_REVISA = CNA.CNA_REVISA "
//cQuery += " AND REVERSE(CNF.CNF_COMPET) > REVERSE('"+cDataFim+"')"
cQuery += " ORDER BY CNF_COMPET DESC "

cQuery  	:= ChangeQuery( cQuery )
cAliasTmp	:= GetNextAlias()
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery), cAliasTmp,.T.,.T.)

While !(cAliasTmp)->(Eof())
	aDataFim := STRTOKARR(cDataFim,'/')
	aDataQry := STRTOKARR((cAliasTmp)->CNF_COMPET,'/')

	If 	aDataQry[2] > aDataFim[2] .Or. (aDataQry[2] == aDataFim[2] .And. aDataQry[1] > aDataFim[1])
		cDataFim := (cAliasTmp)->CNF_COMPET
	EndIf
	(cAliasTmp)->(dbSkip())
EndDo

FWRestRows(aSaveLines)
RestArea(aArea)
Return (StrTokArr( cDataFim, '/' ))
//-------------------------------------------------------------------
/*{Protheus.doc} VerPlan
@objetivo: Verifica se contrato tem planilha e caso não tenha cria
@parametro Filial
           Contrato
           Revisão
@author Fernando Amorim(Cafu)
@since 21/12/2015
@version P12.1.7
*/
//-------------------------------------------------------------------

Function VerPlan(cFilCN9,cContra,cRevisa)

Local cQuery 	:= " "
Local lRet 		:= .T.
Local lFixo		:= .T.
Local nTamCli	:= 0
Local nTamForn	:= 0
Local nTamTIP 	:= 0
Local aParamBox := {}
Local cTitulo	:= STR0182 //"Planilha"
Local aPergRet	:= {}

CN9->(dbSetOrder(1))
If CN9->(dbSeek(cFilCN9+cContra+cRevisa)) .AND. AllTrim(CN9->CN9_SITUAC) = '05'

	cQuery := " SELECT * "
	cQuery += " FROM " + RetSQLName("CNA") + " CNA "
	cQuery += " Where CNA.CNA_FILIAL = '" + cFilCN9 + "' "
	cQuery += " AND CNA.CNA_CONTRA = '" + cContra + "' "
	cQuery += " AND CNA.CNA_REVISA = '" + cRevisa + "' "
	cQuery += " AND CNA.D_E_L_E_T_ <> '*' "

	cQuery := ChangeQuery(cQuery)

	If Select("TRBVER") > 0
		TRBVER->( dbCloseArea() )
	Endif

	dbUseArea(.T.,"TOPCONN",TcGenQry( ,, cQuery ),"TRBVER",.F.,.T.)

	If TRBVER->(EOF())
		lFixo	:= Cn300RetSt("FIXO",,,,,.F.)
		If !lFixo
			lret:= MSGNOYES(STR0141)//"Devido atualização do sistema para Versão 12.1.7 os contratos não fixo devem ter planilha cadastrada para realização da medição, deseja criar neste momento"
			If lRet
				nTamCli		:= TamSX3("A1_COD")[1]
    			nTamForn	:= TamSX3("A2_COD")[1]
    			nTamTIP 	:= TamSX3("CNL_CODIGO")[1]

				aAdd(aParamBox, {1, STR0183 			, Space(nTamCli) , "@!" ,, "SA2",, 50, .F.} ) 		// "Fornecedor"
				aAdd(aParamBox, {1, STR0184				, Space(nTamForn), "@!" ,, "SA1",, 50, .F.} )		// "Cliente "		
				aAdd(aParamBox, {1, STR0185				, 0, '@E 99,999,999,999.9999' ,, ""	,, 50, .F.} )	// "VL. Planilha" 
				aAdd(aParamBox, {1, STR0186				, Space(nTamTIP), '@!' ,, "CNL",, 50, .F.} )		// "tipo de Planilha"

				If ParamBox(aParamBox, cTitulo, aPergRet)
					If (!Empty(aPergRet[1]) .Or. !Empty(aPergRet[2])) .AND. !Empty(aPergRet[3]) .AND. !Empty(aPergRet[4])
						GrvPlan(aPergRet,cFilCN9,cContra,cRevisa)
					Else

						Aviso(STR0142,STR0143,{STR0155},2) //"Parametro","Os parametros devem ser preenchidos"
						lRet := .F.
					EndIf
				Endif
			Endif
		Else
			Aviso(STR0139,STR0140,{STR0155},2) //"Sem Planilha","Este contrato é fixo e requer planilha, faça uma revisão deste contrato"
			lRet := .F.
		Endif
	Endif
	If Select("TRBVER") > 0
		TRBVER->( dbCloseArea() )
	Endif
EndIf
Return lRet

//-------------------------------------------------------------------
/*{Protheus.doc} GrvPlan
@objetivo: Grava  planilha em contratos antigos que não tem planilha
@parametro Pergunte
		   Filial
           Contrato
           Revisão
@author Fernando Amorim(Cafu)
@since 21/12/2015
@version P12.1.7
*/
//-------------------------------------------------------------------
Function GrvPlan(aPergRet,cFilCN9,cContra,cRevisa)

Local cPPlan	:= '000001'

Reclock("CNA",.T.)
CNA->CNA_FILIAL 	:= cFilCN9
CNA->CNA_CONTRA 	:= cContra
CNA->CNA_NUMERO		:= cPPlan
CNA->CNA_REVISA		:= cRevisa
CNA->CNA_FORNEC		:= aPergRet[1]
CNA->CNA_LJFORN		:= If(!Empty(MV_PAR01),SA2->A2_LOJA,"")
CNA->CNA_CLIENT		:= aPergRet[2]
CNA->CNA_LOJACL		:= If(!Empty(MV_PAR02),SA1->A1_LOJA,"")
CNA->CNA_DTINI		:= CN9->CN9_DTINIC
CNA->CNA_VLTOT		:= aPergRet[3]
CNA->CNA_SALDO		:= aPergRet[3]
CNA->CNA_TIPPLA		:= aPergRet[4]
CNA->CNA_DTFIM		:= CN9->CN9_DTFIM
CNA->(MsUnLock())

Return


//=======================================================================================
/*/{Protheus.doc} Cn120MedAb(cFilMed,cCtrNum,cCtrRev)
Função que retorna se existe medição em aberto para determinado contrato/revisão
@return	lRet
@author 	Israel Escorizza
@since 		28/04/2016
@version 	1.0
/*/
//=======================================================================================
Function Cn120MedAb(cFilMed,cCtrNum,cCtrRev,cPlan)
Local aArea		:= GetArea()
Local aRows		:= FWSaveRows()
Local cAliasMd	:= GetNextAlias()

Default cFilMed 	:= xFilial('CND',cFilAnt)
Default cCtrNum 	:= ""
Default cCtrRev 	:= ""


BeginSQL Alias cAliasMd
	SELECT COUNT(CND_CONTRA) AS CND_ABERTO
	FROM %Table:CND% CND
	WHERE
		CND.CND_FILIAL = 	%Exp:cFilMed%	AND
	 	CND.CND_CONTRA = 	%Exp:cCtrNum%	AND
	 	CND.CND_REVISA = 	%Exp:cCtrRev%	AND
	 	CND.CND_NUMERO =	%Exp:cplan% 	AND
	 	CND.CND_DTFIM  =	'' 				AND
	 	CND.%NotDel%
EndSQL

lRet := (cAliasMd)->CND_ABERTO > 0

(cAliasMd)->(dbCloseArea())

FWRestRows(aRows)
RestArea(aArea)
Return lRet

//-------------------------------------
/*/{Protheus.doc}  Cn120IsMdGS()
	Verifica se uma determinada medição teve origem no Gestão de Serviços
@since  	21/09/2016
@version	P12
@param 		cNumMed, Caracter, número da medição a ser avaliada
@return 	Lógico, determina se pode ou não estornar/excluir a medição
/*/
//-------------------------------------
Function Cn120IsMdGS( cNumMed )
Local lIsMedGS := .T.
Local cQryAlias := GetNextAlias()

BeginSQL Alias cQryAlias
	SELECT CND_NUMMED
	FROM %Table:CND% CND
	WHERE CND_FILIAL = %xFilial:CND%
		AND CND_NUMMED = %Exp:cNumMed%
		AND CND.%NotDel%
		AND ( EXISTS (
			SELECT 1
			FROM %Table:TFY% TFY
			WHERE TFY_FILIAL = %xFilial:TFY%
				AND TFY.%NotDel%
				AND TFY.TFY_NUMMED = CND_NUMMED )
			OR EXISTS (
				SELECT 1
				FROM %Table:TFX% TFX
				WHERE TFX_FILIAL = %xFilial:TFX%
					AND TFX.%NotDel%
					AND TFX.TFX_NUMMED = CND_NUMMED )
			OR EXISTS (
				SELECT 1
				FROM %Table:TFW% TFW
				WHERE TFW_FILIAL = %xFilial:TFW%
					AND TFW.%NotDel%
					AND TFW.TFW_NUMMED = CND_NUMMED )
			OR EXISTS (
				SELECT 1
				FROM %Table:TFZ% TFZ
				WHERE TFZ_FILIAL = %xFilial:TFZ%
					AND TFZ.%NotDel%
					AND TFZ.TFZ_NUMMED = CND_NUMMED )
			)

EndSQL

lIsMedGS := (cQryAlias)->(!EOF())

(cQryAlias)->(DbCloseArea())

Return lIsMedGS

/*/{Protheus.doc} cn120VldMov
Valida a manutenção da medição Atual. A revisão da medição deve ser a atual do contrato e o contrato precisa estar vigente
@author vitor.pires
@since 05/04/2018
@version 1.0
@return ${return}, ${return_description}
@param cFilCtr, characters, Filial do Contrato
@param cContra, characters, Numero do Contrato da Medição atual
@param cRevisa, characters, Revisão do contrato da medição atual
@type function
/*/
Static Function cn120VldMov(cFilCtr,cContra,cRevisa)
CN9->(dbSetOrder(1))
//Localiza o Contrato
If (lRet := CN9->(dbSeek(xFilial("CN9",cFilCTR)+cContra+cRevisa)))
	//Valida se o contrato está na ultima revisão e vigente
	If !( (CN9->CN9_SITUAC == DEF_SVIGE) .And. CND->CND_REVISA == CnUltRev(CND->CND_CONTRA, cFilCtr))
		Help('', 1, 'CNT120ESTOR', NIL, STR0166, 1, 0, NIL, NIL, NIL, NIL, NIL, {OemtoAnsi(STR0166)})
		lRet := .F.
	EndIf	
EndIf	
Return(lRet)
