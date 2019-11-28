#INCLUDE "CNTA010.CH"
#INCLUDE "PARMTYPE.CH"
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE "FWEVENTVIEWCONSTS.CH"
#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "MSOLE.CH"
#INCLUDE "GCTXDEF.CH"

Static cRetChave := ""

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ CNTA010  ³ Autor ³ Marcelo Custodio      ³ Data ³22.11.2005³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Manutencao dos tipos de revisoes de contratos              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CNTA010()                                                  ³±±
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
Function CNTA010() 
Local aCores:= {{	'CN0_TIPO=="1"', 'BR_VERDE'		},;
				 {	'CN0_TIPO=="2"', 'BR_VERMELHO'	},;
				 {	'CN0_TIPO=="3"', 'BR_AZUL'  	},;
				 {	'CN0_TIPO=="4"', 'BR_LARANJA'	},;
				 {	'CN0_TIPO=="5"', 'BR_MARROM' 	},;
				 {	'CN0_TIPO=="6"', 'BR_PRETO' 	},;
				 {	'CN0_TIPO=="7"', 'BR_PINK'   	},;
				 {	'CN0_TIPO=="8"', 'BR_AMARELO'	},;
				 {	'CN0_TIPO=="9"', 'BR_AZUL_CLARO'	},;
				 {	'CN0_TIPO=="A"', 'BR_BRANCO'      	},;
				 {	'CN0_TIPO=="B"', 'BR_CINZA'		},;
				 {	'CN0_TIPO=="C"', 'BR_VIOLETA'		},;
				 {	'CN0_TIPO=="D"', 'BR_VERDE_ESCURO'	},;
				 {	'CN0_TIPO=="E"', 'BR_MARRON_OCEAN'	},;
				 {	'CN0_TIPO=="F"', 'BR_CANCEL'}}

Private cCadastro	:= STR0001 //Tipos de Revisoes de Contrato
Private aRotina 	:= MenuDef()

mBrowse(6,1,22,75,"CN0",,,,,,aCores)

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ CN010Esp  ³ Autor ³ Marcelo Custodio      ³ Data ³22.11.2005³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Validacao da especie do contrato                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN010Esp()                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ CNTA010                                                     ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function CN010Esp()
Local lRet := .T.

Do Case
	Case(M->CN0_TIPO = DEF_REV_ADITI)
		lRet := (M->CN0_ESPEC = "1" .or. M->CN0_ESPEC = "3" .or. M->CN0_ESPEC = "4")
		if(!lRet)
			Help( " ", 1, "CNTA010_03" )
		EndIF
	Case(M->CN0_TIPO = DEF_REV_REAJU)
		lRet := !Empty(M->CN0_RETRO)
		If !lRet
			Help( " ", 1, "CNTA010RETRO" )
		Endif	
	Case(M->CN0_TIPO = DEF_REV_REALI)
		lRet := (M->CN0_ESPEC = "2")
		IF(!lRet)
			Help( " ", 1, "CNTA010_04" )
		EndIF
	Case(M->CN0_TIPO = DEF_REV_READE)
		lRet := (M->CN0_ESPEC = "1")
		IF(!lRet)
			Help( " ", 1, "CNTA010_05" )
		EndIF
	Case(M->CN0_TIPO <> DEF_REV_RENOV .And. M->CN0_TIPO <> DEF_REV_ORCGS) .AND. M->CN0_ESPEC == "5"
		lRet := .F.
		If(!lRet)
			Help( " ", 1, "CNTA010_07" ) // Tipo de revisão inválida para a espécie selecionada. ###Para o Espécie 5-Todos, o campo Tipo aceita apenas a opção: C-Renovação.
		EndIf
EndCase

If	lRet .And. Empty(M->CN0_MODO) .And.;
	(M->CN0_TIPO == DEF_REV_ADITI .Or. M->CN0_TIPO == DEF_REV_REALI .Or. M->CN0_TIPO == DEF_REV_READE .Or. M->CN0_TIPO == DEF_REV_CONTA)
	lRet := .F.
	Aviso( OemToAnsi(STR0001), OemToAnsi(STR0016), { "OK" } )
EndIf

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ CN010DEL ³ Autor ³ Marcelo Custodio      ³ Data ³22.11.2005³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Validacao da exclusao do tipo de revisao                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN010DEL(ExpC1,ExpN1,ExpN2)                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 = Alias do arquivo                                   ³±±
±±³          ³ ExpN1 = Numero do registro                                 ³±±
±±³          ³ ExpN2 = Numero da opcao selecionada                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ CNTA010                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function CN010DEL(cAlias,nReg,nOpc)
Local lRet	:= .T.
Local aArea := GetArea()

dbSelectArea("CN9")
dbSetOrder(4) //Tipo de Revisao

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Valida a existencia do registro no cadastro de contratos                 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If MsSeek(xFilial('CN9')+CN0->CN0_CODIGO, .F.)
	lRet := .F.
	Help( " ", 1, "CNTA010_01" )
EndIf

If lRet
	dbSelectArea("CN0")
	dbgoto(nReg)
	Begin Transaction
		AxDeleta(cAlias,nReg,nOpc)
	End Transaction
Endif

RestArea(aArea)
Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ CN010INC ³ Autor ³ Marcelo Custodio      ³ Data ³22.11.2005³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Inclusao do tipo de revisao  				                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN010INC(ExpC1,ExpN1,ExpN2)                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 = Alias do arquivo                                   ³±±
±±³          ³ ExpN1 = Numero do registro                                 ³±±
±±³          ³ ExpN2 = Numero da opcao selecionada                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ CNTA010                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function CN010INC(cAlias,nReg,nOpc)

AxInclui(cAlias,nReg,nOpc,,,,"CN010Esp()")

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ CN010ALT ³ Autor ³ Marcelo Custodio      ³ Data ³22.11.2005³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Alteracao do tipo de revisao 			                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN010ALT(ExpC1,ExpN1,ExpN2)                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 = Alias do arquivo                                   ³±±
±±³          ³ ExpN1 = Numero do registro                                 ³±±
±±³          ³ ExpN2 = Numero da opcao selecionada                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ CNTA010                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function CN010ALT(cAlias,nReg,nOpc)

AxAltera( cAlias,nReg,nOpc,,,,,"CN010Esp()" )

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ CN010LEG ³ Autor ³ Marcos V. Ferreira    ³ Data ³02/03/2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Cria uma janela contendo a legenda da mBrowse              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ CN010LEG()                                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ CNTA010                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function CN010lEG()
Local lRevCauc	:= SuperGetMV("MV_CNRVCAU",.F.,.F.)

Local aLegenda := {}
aAdd(aLegenda,{"BR_VERDE"			,STR0008})	//Aditivo
aAdd(aLegenda,{"BR_VERMELHO"		,STR0009})	//Reajuste
aAdd(aLegenda,{"BR_AZUL"			,STR0010})	//Realinhamento
aAdd(aLegenda,{"BR_LARANJA"			,STR0011})	//Readequacao
aAdd(aLegenda,{"BR_MARROM"			,STR0012})	//Paralisacao
aAdd(aLegenda,{"BR_PRETO"			,STR0013})	//Reinicio
aAdd(aLegenda,{"BR_PINK"			,STR0014})	//Alteracao de Clausulas
aAdd(aLegenda,{"BR_AMARELO"			,STR0015})	//Alteracao Cronograma contábil
aAdd(aLegenda,{"BR_AZUL_CLARO"		,STR0017})	//Indice
aAdd(aLegenda,{"BR_BRANCO"     		,STR0018})	//Fornecedor
aAdd(aLegenda,{"BR_CINZA"			,STR0032})	//Grupos de Aprovação
aAdd(aLegenda,{"BR_VIOLETA"			,STR0031})	//Renovação
aAdd(aLegenda,{"BR_VERDE_ESCURO",STR0033})  //Multa/Bonificação

If lRevCauc
	aAdd(aLegenda,{"BR_MARRON_OCEAN"	,STR0038})	//Caução
EndIf

aAdd(aLegenda,{"BR_CANCEL",STR0039})//Integração GS

BrwLegenda(cCadastro,OemToAnsi(STR0007),aLegenda) //"Legenda"
Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³MenuDef   ³ Autor ³ Fabio Alves Silva     ³ Data ³27/10/2006³±±
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
±±³          ³		1 - Pesquisa e Posiciona em um Banco de Dados           ³±±
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
PRIVATE aRotina	:= { 	{ OemToAnsi(STR0002), "AxPesqui"	, 0, 1, 0, .F.},; 	 //"Pesquisar"
					   	{ OemToAnsi(STR0003), "AxVisual"	, 0, 2, 0, nil},;	 //"Visualizar"
			  	  		{ OemToAnsi(STR0004), "CN010INC"	, 0, 3, 0, nil},; 	 //"Incluir"
			  	  		{ OemToAnsi(STR0005), "CN010ALT"	, 0, 4, 0, nil},; 	 //"Alterar"
		  		  		{ OemToAnsi(STR0006), "CN010DEL"	, 0, 5, 0, nil},; 	 //"Excluir"
		  	  			{ OemToAnsi(STR0007), "CN010LEG"	, 0, 5, 0, .F.}} 	 //"Legenda"

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Ponto de entrada utilizado para inserir novas opcoes no array aRotina  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If ExistBlock("CTA010MNU")
	ExecBlock("CTA010MNU",.F.,.F.)
EndIf
Return(aRotina)

//===================================================================================================
/*/{Protheus.doc} Cn010F3Tip()
Construção de consulta especifica para tipo de revisão (CN0_TIPO), que deverá mostrar o tipo
caução somente se o parametro MV_CNRVCAU estiver ativo.

@author Israel.Escorizza
@since 13/06/2016
@version P12.1.12
@return lRet
/*/
//===================================================================================================
Function Cn010F3Tip()
Local lRet 		:= .F.
Local aArea		:= GetArea()
Local aSaveLines	:= FwSaveRows()

Local lRevCauc	:= SuperGetMV("MV_CNRVCAU",.F.,.F.)
Local cAliasX5	:= GetNextAlias()
Local cQuery		:= ""

Local oBrowse		:= NIL
Local oDlgTela	:= NIL
Local oView		:= NIL

Local aIndex		:= {"X5_CHAVE"}
Local aSeek 		:= {{"Chave", {{"Chave","C",TamSX3("X5_CHAVE")[1],0,"",,}} }}

cQuery +=	" SELECT "
cQuery +=	" X5_CHAVE, X5_DESCRI "
cQuery += 	" FROM "+RetSqlName('SX5')+" "
cQuery += 	" WHERE "
cQuery += 	" X5_FILIAL = '"+xFilial('SX5')+"' "
cQuery += 	" AND "
cQuery += 	" X5_TABELA = 'GC' "
If !lRevCauc
	cQuery +=	" AND "
	cQuery +=	" X5_CHAVE <> 'E' "
EndIf
cQuery	+=	" ORDER BY X5_CHAVE "

DEFINE MSDIALOG oDlgTela TITLE STR0001 FROM 0,0 TO 460,800 PIXEL

oBrowse := FWFormBrowse():New()
oBrowse:SetAlias(cAliasX5)
oBrowse:SetDataQuery()
oBrowse:SetQuery(cQuery)
oBrowse:SetOwner(oDlgTela)
oBrowse:SetDoubleClick({|| cRetChave := (oBrowse:Alias())->X5_CHAVE, lRet := .T., oDlgTela:End()})

oBrowse:AddButton( OemTOAnsi(STR0034), {|| cRetChave  := (oBrowse:Alias())->X5_CHAVE, lRet := .T., oDlgTela:End() } ,, 2 ) //"Confirmar"
oBrowse:AddButton( OemTOAnsi(STR0035), {|| cRetChave  := "", oDlgTela:End() } ,, 2 ) //"Cancelar"
oBrowse:DisableDetails()

oBrowse:SetQueryIndex(aIndex)
oBrowse:SetSeek({||.T.},aSeek)

ADD COLUMN oColumn DATA {|| X5_CHAVE 	} TITLE OemTOAnsi(STR0036)	SIZE TamSX3('X5_CHAVE')[1]  OF oBrowse //"Chave"
ADD COLUMN oColumn DATA {|| X5_DESCRI	} TITLE OemTOAnsi(STR0037) 	SIZE TamSX3('X5_DESCRI')[1] OF oBrowse //"Descrição"

oBrowse:Activate()
ACTIVATE MSDIALOG oDlgTela CENTERED

FWRestRows(aSaveLines)
RestArea(aArea)
Return lRet

//===================================================================================================
/*/{Protheus.doc} C010RetTip()
Retorno da consulta especifica Cn010F3Tip.

@author Israel.Escorizza
@since 13/06/2016
@version P12.1.12
@return lRet
/*/
//===================================================================================================
Function C010RetTip()
Return cRetChave

//-------------------------------------------------------------------
/*/{Protheus.doc} A010RetrW()

Função When do campo Retroativo

@author alexandre.gimenez
@since 24/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function A010RetrW()
Local lRet:= .F.
If M->CN0_TIPO == "2"
	lRet := .T.
Else
	M->CN0_RETRO := ""
Endif

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} A010VldEsp()
Valid do campo Espécie (CN0_ESPEC)
@author israel.escorizza
@since 24/11/2015
@version 1.0
/*/
//-------------------------------------------------------------------
Function A010VldEsp()
Local lRet := .T.
//1=Quantidade;2=Preco;3=Prazo;4=Quant/Prazo;5=Todos
If  M->CN0_TIPO == "1" .AND. !(M->CN0_ESPEC $ "1|3|4")
	lRet = .F.
	Help(" ",1,"A010VLDESP")//"Especie invalida para o tipo de revisão selecionado."
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} A010SetEsp()
When do campo Espécie (CN0_ESPEC)
@author israel.escorizza
@since 24/11/2015
@version 1.0
/*/
//-------------------------------------------------------------------
Function A010SetEsp()
Local lRet  := .F.
Local nTipo := M->CN0_TIPO

DO CASE
   CASE nTipo == DEF_REV_ADITI //-Aditivo;
   		 If Empty(M->CN0_ESPEC)
   		 	M->CN0_ESPEC	:= "1"
   		 EndIf
   		 lRet 	:= .T.

   CASE nTipo == DEF_REV_REALI //- Realinhamento (Preço)
   		 M->CN0_ESPEC := "2"
   		 lRet	:= .F.

   CASE nTipo == DEF_REV_READE //- Readequação (Quantidade)
   		 M->CN0_ESPEC := "1"
   		 lRet	:= .F.

   CASE nTipo == DEF_REV_RENOV //- Renovação (Todos)
   	   	 M->CN0_ESPEC := "5"
   		 lRet	:= .F.

  	CASE nTipo == DEF_REV_ORCGS	//- Orçamento de Serviços (Todos)
   	   	 M->CN0_ESPEC := "5"
   		 lRet	:= .F.
ENDCASE

Return lRet
