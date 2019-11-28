#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "REPORT.CH"
#INCLUDE "TECR981.CH"

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECR981()
Funcionários Efetivos

@sample 	TECR981()

@return		oReport, 	Object,	Objeto do relatório de Funcionários Efetivos

@author 	Serviços
@since		27/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TECR981()
Local cPerg		:= "TECR981"
Local oReport	:= Nil

If TRepInUse() 
Pergunte(cPerg,.F.)		
	oReport := Rt981RDef(cPerg)
	oReport:SetLandScape()
	oReport:PrintDialog()
EndIf

Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Rt981RDef()
Funcionários Efetivos - monta as Sections para impressão do relatório

@sample Rt981RDef(cPerg)
@param 	cPerg 
@return oReport

@author 	Serviços
@since		29/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Rt981RDef(cPerg)
Local oReport		:= Nil				
Local oSection1 	:= Nil				
Local oSection2  	:= Nil				
Local oSection3 	:= Nil
Local oSection4 	:= Nil
Local cAlias1		:= GetNextAlias()
Local oSum1			:= Nil

oReport   := TReport():New("TECR981",STR0001,cPerg,{|oReport| Rt981Print(oReport, cPerg, cAlias1)},STR0001) //"Funcionários Efetivos"

oSection1 := TRSection():New(oReport	,FwX2Nome("TFJ") ,{"TFJ","TFL","TFF","TGY"},,,,,,,,,,,,,.T.)
DEFINE CELL NAME "TFJ_CODIGO"		OF oSection1 ALIAS "TFJ"
DEFINE CELL NAME "TFJ_CODENT"		OF oSection1 ALIAS "TFJ"
DEFINE CELL NAME "TFJ_LOJA"			OF oSection1 ALIAS "TFJ"
DEFINE CELL NAME STR0002    		OF oSection1 SIZE (TamSX3("A1_NOME")[1]) BLOCK {|| Posicione("SA1",1, xFilial("SA1")+PadR(Trim((cAlias1)->(TFJ_CODENT+TFJ_LOJA)), TamSx3("A1_NOME")[1]),"SA1->A1_NOME") } //"Nome Cli."      																	
			
oSection2 := TRSection():New(oSection1	,FwX2Nome("TFL") ,{"TFL"},,,,,,,,,,3,,,.T.)
DEFINE CELL NAME "TFL_LOCAL"	OF oSection2 ALIAS "TFL"
DEFINE CELL NAME STR0003		OF oSection2 SIZE (TamSX3("ABS_DESCRI")[1]) BLOCK {|| Posicione("ABS",1, xFilial("ABS")+PadR(Trim((cAlias1)->(TFL_LOCAL)), TamSx3("ABS_DESCRI")[1]),"ABS->ABS_DESCRI") } //"Desc. Local"		

oSection3 := TRSection():New(oSection2	,FwX2Nome("TFF") ,{"TFF"},,,,,,,,,,6,,,.T.)
DEFINE CELL NAME "TFF_COD"		OF oSection3 ALIAS "TFF"
DEFINE CELL NAME "TFF_ESCALA"	OF oSection3 ALIAS "TFF"
DEFINE CELL NAME STR0004 		OF oSection3 SIZE (TamSX3("TDW_DESC")[1]) BLOCK {|| Posicione("TDW",1, xFilial("TDW")+PadR(Trim((cAlias1)->(TFF_ESCALA)), TamSx3("TDW_DESC")[1]),"TDW->TDW_DESC") } //"Desc. Local"		
DEFINE CELL NAME "TFF_FUNCAO"	OF oSection3 ALIAS "TFF"
DEFINE CELL NAME STR0005 		OF oSection3 SIZE (TamSX3("RJ_DESC")[1]) BLOCK {|| Posicione("SRJ",1, xFilial("SRJ")+PadR(Trim((cAlias1)->(TFF_FUNCAO)), TamSx3("RJ_DESC")[1]),"SRJ->RJ_DESC") } //"Desc. Local"		
DEFINE CELL NAME "TFF_QTDVEN"	OF oSection3 ALIAS "TFF" TITLE STR0010 //"Qtd. Posto"

oSection4 := TRSection():New(oSection3	,FwX2Nome("TGY") ,{"TGY"},,,,,,,,,,9,,,.T.)
DEFINE CELL NAME "TGY_ATEND"		OF oSection4 ALIAS "TGY"
DEFINE CELL NAME STR0006	 		OF oSection4 SIZE (TamSX3("AA1_NOMTEC")[1])  BLOCK {|| Posicione("AA1",1, xFilial("AA1")+PadR(Trim((cAlias1)->TGY_ATEND), TamSx3("AA1_NOMTEC")[1]),"AA1->AA1_NOMTEC") } //"Nome Atend."																
DEFINE CELL NAME "TGY_TURNO"		OF oSection4 ALIAS "TGY" 
DEFINE CELL NAME "TGY_SEQ"			OF oSection4 ALIAS "TGY"
DEFINE CELL NAME "TGY_ENTRA1"		OF oSection4 ALIAS "TGY" TITLE STR0008 BLOCK {|| At960HrAlc("E",cAlias1) } //"Hr. Entrada"
DEFINE CELL NAME "TGY_SAIDA1"		OF oSection4 ALIAS "TGY" TITLE STR0009 BLOCK {|| At960HrAlc("S",cAlias1) } //"Hr. Saída"   

oSum1 := TRFunction():New(oSection4:Cell("TGY_TURNO"),"Tot1","COUNT",,STR0007,,,.T.,,,,{|| .T. }) //"Total Turno"
oSum1:SetEndSection(.T.)
oSum1:SetEndReport(.F.)

Return oReport

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Rt331Print()
Funcionários Efetivos - monta a Query e imprime o relatorio de acordo com os parametros

@sample 	Rt331Print(oReport, cPerg, cAlias1)

@param		oReport, 	Object,	Objeto do relatório de postos vagos
			cPerg, 		String,	Nome do grupo de perguntas
			cAlias1,	String,	Nome do alias da Query do relatório 
			
@return 	Nenhum

@author 	Serviços
@since		29/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Rt981Print(oReport, cPerg, cAlias1)
Local oSection1	:= oReport:Section(1)		
Local oSection2	:= oSection1:Section(1) 	
Local oSection3	:= oSection2:Section(1) 	
Local oSection4	:= oSection3:Section(1) 	
Local cMvpar01	:= MV_PAR01
Local cMvpar02	:= MV_PAR02
Local cMvpar03	:= MV_PAR03
Local cMvpar04	:= MV_PAR04
Local cMvpar05	:= MV_PAR05
Local cMvpar06	:= MV_PAR06
Local cMvpar07	:= MV_PAR07
Local cMvpar08	:= MV_PAR08

BEGIN REPORT QUERY oSection1

BeginSQL Alias cAlias1

	SELECT *
		   
	FROM %table:TGY% TGY

	INNER JOIN %table:TFF% TFF ON (TFF.TFF_FILIAL=%xFilial:TFF% AND TFF.TFF_COD=TGY.TGY_CODTFF AND TFF.%NotDel%)

	INNER JOIN %table:TFL% TFL ON (TFL.TFL_FILIAL=%xFilial:TFL% AND TFL.TFL_CODIGO=TFF_CODPAI AND TFL.%NotDel%)
	
	INNER JOIN %table:TFJ% TFJ ON (TFJ.TFJ_FILIAL=%xFilial:TFJ% AND TFJ.TFJ_CODIGO=TFL.TFL_CODPAI AND TFJ.%NotDel%)
	
	WHERE TGY.TGY_FILIAL=%xFilial:TGY%     AND
		  TGY.%NotDel%				       AND
		  TGY.TGY_TIPALO = '001'		   AND
		  %Exp:dTos(dDatabase)% BETWEEN TGY.TGY_DTINI AND TGY.TGY_DTFIM AND
		  TFJ.TFJ_CODENT 		BETWEEN %Exp:cMvpar01% AND %Exp:cMvpar03%  AND
		  TFJ.TFJ_LOJA   		BETWEEN %Exp:cMvpar02% AND %Exp:cMvpar04%  AND
		  TFL.TFL_LOCAL  		BETWEEN %Exp:cMvpar05% AND %Exp:cMvpar06%  AND
		  TFF.TFF_ESCALA 		BETWEEN %Exp:cMvpar07% AND %Exp:cMvpar08%
EndSql

END REPORT QUERY oSection1

(cAlias1)->(DbGoTop())

oSection2:SetParentQuery()
oSection2:SetParentFilter({|cParam| (cAlias1)->TFJ_CODIGO == cParam},{|| (cAlias1)->TFL_CODPAI })

oSection3:SetParentQuery()
oSection3:SetParentFilter({|cParam| (cAlias1)->TFL_CODIGO == cParam},{|| (cAlias1)->TFF_CODPAI })

oSection4:SetParentQuery()
oSection4:SetParentFilter({|cParam| (cAlias1)->TFF_COD == cParam},{|| (cAlias1)->TGY_CODTFF })

oSection1:Print()

(cAlias1)->(DbCloseArea())
          
Return(.T.)