#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "REPORT.CH"
#INCLUDE "TECR970.CH"

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECR970()
Presen�a no Posto

@sample 	TECR970()

@return		oReport, 	Object,	Objeto do relat�rio de Presen�a no Posto

@author 	Servi�os
@since		27/05/2019
/*/

//--------------------------------------------------------------------------------------------------------------------
Function TECR970()
Local cPerg		:= "TECR970"
Local oReport	:= Nil

If TRepInUse() 
	Pergunte(cPerg,.F.)	
	oReport := Rt970RDef(cPerg)
	oReport:SetLandScape()
	oReport:PrintDialog()	
EndIf

Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Rt970RDef()
Presen�a no Posto - monta as Sections para impress�o do relat�rio

@sample Rt970RDef(cPerg)
@param 	cPerg 
@return oReport

@author 	Servi�os
@since		29/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Rt970RDef(cPerg)
Local oReport		:= Nil			
Local oSection1 	:= Nil				
Local oSection2  	:= Nil				 
Local oSection3 	:= Nil
Local oSection4 	:= Nil
Local cAlias1		:= GetNextAlias()
Local oSum1			:= Nil
Local oSum2			:= Nil
Local oSum3			:= Nil

oReport   := TReport():New("TECR970",STR0001,cPerg,{|oReport| Rt970Print(oReport, cPerg, cAlias1)},STR0001,,,.T.) //"Presen�a no Posto"

oSection1 := TRSection():New(oReport	,FwX2Nome("TFJ") ,{"TFJ"},,,,,,,,,,,,,.T.)
DEFINE CELL NAME "TFJ_CODENT"		OF oSection1 ALIAS "TFJ"
DEFINE CELL NAME "TFJ_LOJA"			OF oSection1 ALIAS "TFJ"
DEFINE CELL NAME STR0002	 		OF oSection1 SIZE (TamSX3("A1_NOME")[1]) BLOCK {|| Posicione("SA1",1, xFilial("SA1")+PadR(Trim((cAlias1)->(TFJ_CODENT+TFJ_LOJA)), TamSx3("A1_NOME")[1]),"SA1->A1_NOME") } //"Nome Cli."      																	
			
oSection2 := TRSection():New(oSection1	,FwX2Nome("TFL") ,{"TFL"},,,,,,,,,,3,,,.T.)
DEFINE CELL NAME "TFL_LOCAL"	OF oSection2 ALIAS "TFL"
DEFINE CELL NAME STR0003		OF oSection2 SIZE (TamSX3("ABS_DESCRI")[1]) BLOCK {|| Posicione("ABS",1, xFilial("ABS")+PadR(Trim((cAlias1)->(TFL_LOCAL)), TamSx3("ABS_DESCRI")[1]),"ABS->ABS_DESCRI") } //"Desc. Local"		

oSection3 := TRSection():New(oSection2	,FwX2Nome("TFF") ,{"TFF"},,,,,,,,,,6,,,.T.)
DEFINE CELL NAME "TFF_COD"		OF oSection3 ALIAS "TFF"
DEFINE CELL NAME "TFF_ESCALA"	OF oSection3 ALIAS "TFF"
DEFINE CELL NAME STR0004 		OF oSection3 SIZE (TamSX3("TDW_DESC")[1]) BLOCK {|| Posicione("TDW",1, xFilial("TDW")+PadR(Trim((cAlias1)->(TFF_ESCALA)), TamSx3("TDW_DESC")[1]),"TDW->TDW_DESC") } //"Desc. Local"		

oSection4 := TRSection():New(oSection3	,FwX2Nome("ABB") ,{"ABB"},,,,,,,,,,9,,,.T.)
DEFINE CELL NAME "ABB_CODIGO"		OF oSection4 ALIAS "ABB"
DEFINE CELL NAME "ABB_DTINI"		OF oSection4 ALIAS "ABB"
DEFINE CELL NAME "ABB_HRINI"		OF oSection4 ALIAS "ABB"
DEFINE CELL NAME "ABB_DTFIM"		OF oSection4 ALIAS "ABB"
DEFINE CELL NAME "ABB_HRFIM"		OF oSection4 ALIAS "ABB"
DEFINE CELL NAME "ABB_HRTOT"	    OF oSection4 BLOCK {|| AT580TReal(cAlias1)}	
DEFINE CELL NAME "ABB_CODTEC"		OF oSection4 ALIAS "ABB"
DEFINE CELL NAME STR0005	 		OF oSection4 SIZE (TamSX3("AA1_NOMTEC")[1]) BLOCK {|| Posicione("AA1",1, xFilial("AA1")+PadR(Trim((cAlias1)->ABB_CODTEC), TamSx3("AA1_NOMTEC")[1]),"AA1->AA1_NOMTEC") } //"Nome Atend."																
DEFINE CELL NAME "ABB_TIPOMV"		OF oSection4 ALIAS "ABB"
DEFINE CELL NAME STR0006		 	OF oSection4 SIZE (TamSX3("TCU_DESC")[1]) BLOCK {|| UPPER(Posicione("TCU",1, xFilial("TCU")+PadR(Trim((cAlias1)->ABB_TIPOMV), TamSx3("TCU_DESC")[1]),"TCU->TCU_DESC")) } //"Desc. Tp. Mov."

DEFINE CELL NAME "HRREFOR"	    	OF oSection4 ALIAS "QRY" BLOCK {|| Atr970Tot(cAlias1,"2")} TITLE STR0007 //"Hr. de Ref."
DEFINE CELL NAME "HREXTRA"	    	OF oSection4 ALIAS "QRY" BLOCK {|| Atr970Tot(cAlias1,"3")} TITLE STR0008 //"Hr. Extra"   

//Totalizador de Horas
oSum1 := TRFunction():New(oSection4:Cell("ABB_HRTOT"),"Tot1","TIMESUM",,STR0009,,,.T.) //"Total Geral"
oSum1:SetEndSection(.T.)
oSum1:SetEndReport(.F.)

//Totalizador Horas Extras
oSum2 := TRFunction():New(oSection4:Cell("HREXTRA"),"Tot2","TIMESUM",,STR0010,,,.T.) //"Total Horas Extras"
oSum2:SetEndSection(.T.)
oSum2:SetEndReport(.F.)

//Totalizador Horas Refor�o
oSum3 := TRFunction():New(oSection4:Cell("HRREFOR" ),"Tot3","TIMESUM",,STR0011,,,.T.) //"Total Horas Refor�o"
oSum3:SetEndSection(.T.)
oSum3:SetEndReport(.F.)

Return oReport

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Rt331Print()
Presen�a no Posto - monta a Query e imprime o relatorio de acordo com os parametros

@sample 	Rt331Print(oReport, cPerg, cAlias1)

@param		oReport, 	Object,	Objeto do relat�rio de postos vagos
			cPerg, 		String,	Nome do grupo de perguntas
			cAlias1,	String,	Nome do alias da Query do relat�rio 
			
@return 	Nenhum

@author 	Servi�os
@since		29/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Rt970Print(oReport, cPerg, cAlias1)
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

	SELECT TFJ_CODENT,
		   TFJ_LOJA,
		   TFL_LOCAL,
		   TFF_COD,
		   TFF_ESCALA,
		   ABB_CODIGO,
		   ABB_DTINI,
		   ABB_HRINI,
		   ABB_DTFIM,
		   ABB_HRFIM,
		   ABB_HRTOT,
		   ABB_CODTEC,
		   ABB_TIPOMV,
		   ABB_CODTFF,		   
		   TFJ_CODIGO,
		   TFL_CODPAI,
		   TFL_CODIGO,
		   TFF_CODPAI,
		   TFF_COD

	FROM %table:ABB% ABB

	INNER JOIN %table:TFF% TFF ON (TFF.TFF_FILIAL=%xFilial:TFF% AND TFF.TFF_COD=ABB.ABB_CODTFF AND TFF.%NotDel%)

	INNER JOIN %table:TFL% TFL ON (TFL.TFL_FILIAL=%xFilial:TFL% AND TFL.TFL_CODIGO=TFF_CODPAI AND TFL.%NotDel%)

	INNER JOIN %table:TFJ% TFJ ON (TFJ.TFJ_FILIAL=%xFilial:TFJ% AND TFJ.TFJ_CODIGO=TFL.TFL_CODPAI AND TFJ.%NotDel%)
	
	WHERE ABB.ABB_FILIAL=%xFilial:ABB%     AND
		  ABB.%NotDel%				       AND
		  ABB.ABB_ATENDE = '1'		   	   AND
		  (ABB.ABB_DTINI BETWEEN %Exp:cMvpar01% AND %Exp:cMvpar02%  OR 
		  ABB.ABB_DTFIM  BETWEEN %Exp:cMvpar01% AND %Exp:cMvpar02%) AND
		  TFJ.TFJ_CODENT BETWEEN %Exp:cMvpar03% AND %Exp:cMvpar05%  AND
		  TFJ.TFJ_LOJA   BETWEEN %Exp:cMvpar04% AND %Exp:cMvpar06%  AND
		  TFF.TFF_ESCALA BETWEEN %Exp:cMvpar07% AND %Exp:cMvpar08%
		   
	ORDER BY TFJ.TFJ_CODIGO,TFL.TFL_CODIGO,TFF.TFF_COD,ABB.ABB_CODIGO

EndSql

END REPORT QUERY oSection1

(cAlias1)->(DbGoTop())

oSection2:SetParentQuery()
oSection2:SetParentFilter({|cParam| (cAlias1)->TFJ_CODIGO == cParam},{|| (cAlias1)->TFL_CODPAI })

oSection3:SetParentQuery()
oSection3:SetParentFilter({|cParam| (cAlias1)->TFL_CODIGO == cParam},{|| (cAlias1)->TFF_CODPAI })

oSection4:SetParentQuery()
oSection4:SetParentFilter({|cParam| (cAlias1)->TFF_COD == cParam},{|| (cAlias1)->ABB_CODTFF })

//Executa impress�o
oSection1:Print()

(cAlias1)->(DbCloseArea())
          
Return(.T.)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Atr970Tot()
Verifica se preenche a coluna conforme o tipo de aloca��o

@sample 	Atr970Tot(cAlias1)

@param		cAlias1,	String,	Nome do alias da Query do relat�rio 
			cTip,		String,	Qual � o tipo do campo
			
@return 	cHrRet

@author 	Servi�os
@since		29/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Atr970Tot(cAlias1,cTip)
Local cHrRet := "00:00"

If cTip == "2" .And. (cAlias1)->ABB_TIPOMV == "015"
	cHrRet := AT580TReal(cAlias1)
Elseif cTip == "3"
	cHrRet := Atr970Ext((cAlias1)->ABB_CODIGO)
Endif

Return cHrRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Atr970Ext()
Verifica se existe hora extra

@sample 	Rt331Print(oReport, cPerg, cAlias1)

@param		cCodAbb, 	String, Codigo da agenda
			
@return 	cHrRet

@author 	Servi�os
@since		11/06/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Atr970Ext(cCodAbb)
Local cHrRet := "00:00"

DbSelectArea("ABR")
ABR->(DbSetOrder(1))

DbSelectArea("ABN")
ABN->(DbSetOrder(1))

If ABR->(dbSeek(xFilial("ABR")+cCodAbb)) .And. ABN->(dbSeek(xFilial("ABN")+ABR->ABR_MOTIVO)) .And. ABN->ABN_TIPO == "04"
	cHrRet := ABR->ABR_TEMPO
Endif

Return cHrRet