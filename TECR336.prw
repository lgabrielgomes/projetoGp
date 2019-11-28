#Include 'Protheus.ch'
#INCLUDE 'TOPCONN.CH'
#INCLUDE 'TECR336.CH'

 //-------------------------------------------------------------------------
/*/{Protheus.doc}  TECR336

Impressão movimentação de atendente

@sample  TECR890() 
@author  Leandro Fini
@since 	 23/07/2018
@version P12
/*/
//-------------------------------------------------------------------------
Function TECR336()
	Local oReport := NIL
	Local cPerg:= Padr("TECR336",10)

/*
PARAMETROS:
MV_PAR01 - Do atendente
MV_PAR02 - Ate atendente
MV_PAR03 - Da data
MV_PAR04 - Ate data
*/

	Pergunte(cPerg,.F.)	          
		
	oReport := ReportDef(cPerg)
	oReport:PrintDialog()
Return
 //------------------------------------------------------------------------
/*/{Protheus.doc}  ReportDef

Definições do relatório

@sample  ReportDef() 
@author  Leandro Fini
@since 	  05/07/2018
@version P12
/*/
//-------------------------------------------------------------------------
Static Function ReportDef(cNome)
Local oReport	 := Nil
Local oSection1	 := Nil
Local oSection2	 := Nil
Local oBreak
Local oFunction
	
	/*Sintaxe: TReport():New(cNome,cTitulo,cPerguntas,bBlocoCodigo,cDescricao)*/
	oReport := TReport():New(cNome,STR0001,cNome,{|oReport| ReportPrint(oReport)},STR0001) //Relação de Movimentação 
	oReport:SetPortrait()    
	oReport:SetTotalInLine(.F.)
	
	//SESSAO 1----------DADOS DO ATENDENTE--------------------------------------------//
	oSection1:= TRSection():New(oReport, STR0002, {"TW3"}, , .F., .T.)//"Dados do atendente"
	TRCell():New(oSection1,"TW3_FILIAL"	 ,"SEC1",STR0003,,TAMSX3("TW3_FILIAL")[1] + 6,,,"LEFT",,"LEFT")//Filial
	TRCell():New(oSection1,"TW3_FILATD"	 ,"SEC1",STR0004,,TAMSX3("TW3_FILATD")[1] + 6,,,"LEFT",,"LEFT") //Filial Agenda
	TRCell():New(oSection1,"TW3_ATDCOD"  ,"SEC1",STR0005,,TAMSX3("TW3_ATDCOD")[1] + 5,,,"LEFT",,"LEFT")//"Atendente"  
	TRCell():New(oSection1,"AA1_NOMTEC"  ,"SEC1",STR0006,,TAMSX3("AA1_NOMTEC")[1] + 5,,,"LEFT",,"LEFT")//"Nome Atendente"
	TRCell():New(oSection1,"AA1_FUNCAO"  ,"SEC1",STR0007,,TAMSX3("AA1_FUNCAO")[1],,,"LEFT",,"LEFT") //Cod. Funcao
	TRCell():New(oSection1,"RJ_DESC"  ,"SEC1",STR0008,,TAMSX3("RJ_DESC")[1] + 5,,,"LEFT",,"LEFT") //Desc Funcao
	
	//SESSAO 2----------DADOS DE MOVIMENTAÇAO--------------------------------------------//
	oSection2:= TRSection():New(oReport,STR0009,{"TW3"},,,,,,,,,,10) //"Dados da movimentação"
	TRCell():New(oSection2,"TW3_DTMOV"   ,"SEC2",STR0010,,TAMSX3("TW3_DTMOV")[1] + 13,,,"LEFT",,"LEFT")//"Data Mov."
	TRCell():New(oSection2,"TFF_PRODUT"  ,"SEC2",STR0011,,TAMSX3("TFF_PRODUT")[1] + 9,,,"LEFT",,"LEFT")//Posto
	TRCell():New(oSection2,"B1_DESC" 	 ,"SEC2",STR0012,,TAMSX3("B1_DESC")[1] + 5,,,"LEFT",,"LEFT")//Descriçao
	TRCell():New(oSection2,"TW3_SITCOD"  ,"SEC2",STR0013,,TAMSX3("TW3_SITCOD")[1],,,"LEFT",,"LEFT")//Situaçao
	TRCell():New(oSection2,"TW3_SITDES"  ,"SEC2",STR0014,,50,,,"LEFT",,"LEFT")//"Desc. Sit."
	TRCell():New(oSection2,"TW3_MOTCOD"  ,"SEC2",STR0015,,TAMSX3("TW3_MOTCOD")[1]+ 8,,,"LEFT",,"LEFT")//Motivo
	TRCell():New(oSection2,"TW3_MOTDES"  ,"SEC2",STR0016,,50,,,"LEFT",,"LEFT")//"Desc Motivo
	TRCell():New(oSection2,"TW3_TECSUB"  ,"SEC2",STR0017,,TAMSX3("TW3_TECSUB")[1] + 14,,,"LEFT",,"LEFT")//Atend. Subs
	TRCell():New(oSection2,"TFF_LOCAL"   ,"SEC2",STR0018,,TAMSX3("TFF_LOCAL")[1]+ 8,,,"LEFT",,"LEFT")//Local
	TRCell():New(oSection2,"ABS_DESCRI"  ,"SEC2",STR0019,,TAMSX3("ABS_DESCRI")[1]+ 5,,,"LEFT",,"LEFT")//Desc Local
	
    //Desativado quebra de pagina por sessão.
	oSection1:SetPageBreak(.F.)
	oSection1:SetTotalText(" ")	
				
Return(oReport)
  //------------------------------------------------------------------------
/*/{Protheus.doc}  ReportPrint

Impressão do relatório

@sample  ReportPrint() 
@author  Leandro Fini
@since 	  05/07/2018
@version P12
/*/
//-------------------------------------------------------------------------
Static Function ReportPrint(oReport)

Local oSection1 := oReport:Section(1)
Local oSection2 := oReport:Section(2)
Local cAliasSec1	:= GetNextAlias()
Local cDataTFS		:= ""
Local cDataTFT		:= ""
Local cQrySec1      := ""		
Local cCodAtend		:= ""	        

cQrySec1 := " SELECT TW3_FILIAL, TW3_COD, TW3_ATDCOD, AA1_NOMTEC, AA1_FUNCAO, TFF_PRODUT, B1_DESC, TW3_DTMOV, TW3_USEXEC, TW3_SITCOD, "
cQrySec1 += " TW3_TECSUB, TW3_TECFIL, TW3_FILATD, TW3_MOTCOD, TW3_ITRHCT, TFF_COD, TFF_LOCAL, ABS_DESCRI, ABS_CODIGO, ABS_LOJA, A1_NOME " 
cQrySec1 += " FROM "+RETSQLNAME("TW3")+" TW3 "
cQrySec1 += " LEFT JOIN "+RETSQLNAME("TFF")+" TFF "
cQrySec1 += " ON TFF_FILIAL = TW3_FILIAL 	 "
cQrySec1 += " AND TFF_COD = TW3_ITRHCT 		 "
cQrySec1 += " JOIN "+RETSQLNAME("ABS")+" ABS "
cQrySec1 += " ON ABS_LOCAL = TFF_LOCAL		 "
cQrySec1 += " JOIN "+RETSQLNAME("AA1")+" AA1 "
cQrySec1 += " ON AA1_CODTEC = TW3_ATDCOD     "
cQrySec1 += " JOIN "+RETSQLNAME("SA1")+" SA1 "
cQrySec1 += " ON A1_COD = ABS_CODIGO		 "
cQrySec1 += " AND A1_LOJA = ABS_LOJA		 "
cQrySec1 += " JOIN "+RETSQLNAME("SB1")+" SB1 "
cQrySec1 += " ON B1_COD = TFF_PRODUT		 "
cQrySec1 += " AND TW3.D_E_L_E_T_ = ''		 "
cQrySec1 += " AND TFF.D_E_L_E_T_ = ' '		 "
cQrySec1 += " AND ABS.D_E_L_E_T_ = ' '		 "
cQrySec1 += " AND AA1.D_E_L_E_T_ = ' '		 "
cQrySec1 += " AND SA1.D_E_L_E_T_ = ' '		 "
cQrySec1 += " AND SB1.D_E_L_E_T_ = ' '		 "
cQrySec1 += " AND TW3_ATDCOD BETWEEN '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"' "
cQrySec1 += " AND TW3_DTMOV BETWEEN '"+ DtoS(MV_PAR03) +"' AND '"+ DtoS(MV_PAR04) +"' "
cQrySec1 += " ORDER BY TW3_ATDCOD, TW3_COD, TW3_DTMOV "
	
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQrySec1),cAliasSec1,.T.,.T.)

oReport:SetMeter((cAliasSec1)->(RecCount()))	

(cAliasSec1)->(DbGoTop())

While (cAliasSec1)->(!Eof())

	cCodAtend := Alltrim((cAliasSec1)->TW3_ATDCOD)
	
	If oReport:Cancel()
		Exit
	EndIf

 //	---------------- --------- ---------------------//		
 //	---------------- SECTION 1 ---------------------//
 //	------------------------------------------------//
	oSection1:Init()
 
	oReport:IncMeter()
	IncProc(STR0020 +(cAliasSec1)->TW3_ATDCOD)//"Imprimindo Movimento do Atendente"   
	oReport:SkipLine()

	//Imprimo a primeira sessão			
	oSection1:Cell("TW3_FILIAL"):SetValue((cAliasSec1)->TW3_FILIAL)
	oSection1:Cell("TW3_FILATD"):SetValue((cAliasSec1)->TW3_FILATD)
	oSection1:Cell("TW3_ATDCOD"):SetValue((cAliasSec1)->TW3_ATDCOD)	
	oSection1:Cell("AA1_NOMTEC"):SetValue(Alltrim((cAliasSec1)->AA1_NOMTEC))
	oSection1:Cell("AA1_FUNCAO"):SetValue(Alltrim((cAliasSec1)->AA1_FUNCAO))
	oSection1:Cell("RJ_DESC"):SetValue(Alltrim(Posicione( "SRJ", 1, xFilial("SRJ") + Alltrim((cAliasSec1)->AA1_FUNCAO) , "RJ_DESC")))
	oSection1:Printline()
	
		//	---------------- --------- ---------------------//		
	//	---------------- SECTION 2 ---------------------//
	//	------------------------------------------------//
	oSection2:init()
	
	While cCodAtend == Alltrim((cAliasSec1)->TW3_ATDCOD)
	
		oReport:IncMeter()	
		
		oSection2:Cell("TW3_DTMOV"):SetValue(StoD((cAliasSec1)->TW3_DTMOV))
		oSection2:Cell("TFF_PRODUT"):SetValue((cAliasSec1)->TFF_PRODUT)		
		oSection2:Cell("B1_DESC"):SetValue(Alltrim((cAliasSec1)->B1_DESC))		
		oSection2:Cell("TW3_SITCOD"):SetValue(Alltrim((cAliasSec1)->TW3_SITCOD))
		oSection2:Cell("TW3_SITDES"):SetValue(Alltrim(Posicione( "SX5", 1, xFilial("SX5") + "I6" + Alltrim((cAliasSec1)->TW3_SITCOD), "X5_DESCRI")))
		oSection2:Cell("TW3_MOTCOD"):SetValue(Alltrim((cAliasSec1)->TW3_MOTCOD))
		oSection2:Cell("TW3_MOTDES"):SetValue(Alltrim(Posicione( "SX5", 1, xFilial("SX5") + "I7" + Alltrim((cAliasSec1)->TW3_MOTCOD), "X5_DESCRI")))
		oSection2:Cell("TW3_TECSUB"):SetValue((cAliasSec1)->TW3_TECSUB)
		oSection2:Cell("TFF_LOCAL"):SetValue(Alltrim((cAliasSec1)->TFF_LOCAL))
		oSection2:Cell("ABS_DESCRI"):SetValue(Alltrim((cAliasSec1)->ABS_DESCRI))
		oSection2:Printline()
		
		(cAliasSec1)->(DbSkip())
		
	Enddo
	
	oReport:SkipLine(3) //pula 3 linhas
	//Finalizo a segunda sessão
	oSection2:Finish()
	
	//Finalizo a primeira sessão
	oSection1:Finish()
	
	//Passa para o próximo Local
	(cAliasSec1)->(DbSkip())
	
Enddo //(cAliasSec1)->(!Eof())
	
	(cAliasSec1)->(DbCloseArea())
	//oReport:Finish()

Return