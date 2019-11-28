#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "REPORT.CH"
#INCLUDE "TECR990.CH"

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECR990()
Reforço

@sample 	TECR990()

@return		oReport, 	Object,	Objeto do relatório de Reforço

@author 	Serviços
@since		27/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TECR990()
Local cPerg		:= "TECR990"
Local oReport	:= Nil

If TRepInUse() 
	Pergunte(cPerg,.F.)	
	oReport := Rt990RDef(cPerg)
	oReport:SetLandScape()
	oReport:PrintDialog()
EndIf

Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Rt990RDef()
Reforço - monta as Sections para impressão do relatório

@sample Rt990RDef(cPerg)
@param 	cPerg 
@return oReport

@author 	Serviços
@since		29/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Rt990RDef(cPerg)
Local oReport		:= Nil				
Local oSection1 	:= Nil				
Local oSection2  	:= Nil				
Local oSection3 	:= Nil
Local oSection4 	:= Nil
Local cAlias1		:= GetNextAlias()
Local oSum1			:= Nil
Local oSum2			:= Nil
Local oSum3			:= Nil

oReport   := TReport():New("TECR990",STR0001,cPerg,{|oReport| Rt990Print(oReport, cPerg, cAlias1)},STR0001) //"Reforço"

oSection1 := TRSection():New(oReport	,FwX2Nome("TFJ") ,{"TFJ"},,,,,,,,,,,,,.T.)
DEFINE CELL NAME "TFJ_CODENT"		OF oSection1 ALIAS "TFJ"
DEFINE CELL NAME "TFJ_LOJA"			OF oSection1 ALIAS "TFJ"
DEFINE CELL NAME STR0002 	 		OF oSection1 SIZE (TamSX3("A1_NOME")[1]) BLOCK {|| Posicione("SA1",1, xFilial("SA1")+PadR(Trim((cAlias1)->(TFJ_CODENT+TFJ_LOJA)), TamSx3("A1_NOME")[1]),"SA1->A1_NOME") } //"Nome Cli."      																	
			
oSection2 := TRSection():New(oSection1	,FwX2Nome("TFL") ,{"TFL"},,,,,,,,,,3,,,.T.)
DEFINE CELL NAME "TFL_LOCAL"	OF oSection2 ALIAS "TFL"
DEFINE CELL NAME STR0003		OF oSection2 SIZE (TamSX3("ABS_DESCRI")[1]) BLOCK {|| Posicione("ABS",1, xFilial("ABS")+PadR(Trim((cAlias1)->(TFL_LOCAL)), TamSx3("ABS_DESCRI")[1]),"ABS->ABS_DESCRI") } //"Desc. Local"		

oSection3 := TRSection():New(oSection2	,FwX2Nome("TFF") ,{"TFF"},,,,,,,,,,6,,,.T.)
DEFINE CELL NAME "TFF_COD"		OF oSection3 ALIAS "TFF"
DEFINE CELL NAME "TFF_ESCALA"	OF oSection3 ALIAS "TFF"
DEFINE CELL NAME STR0004		OF oSection3 SIZE (TamSX3("TDW_DESC")[1]) BLOCK {|| Posicione("TDW",1, xFilial("TDW")+PadR(Trim((cAlias1)->(TFF_ESCALA)), TamSx3("TDW_DESC")[1]),"TDW->TDW_DESC") } //"Desc. Local"		
DEFINE CELL NAME "TFF_FUNCAO"	OF oSection3 ALIAS "TFF"
DEFINE CELL NAME STR0005 		OF oSection3 SIZE (TamSX3("RJ_DESC")[1]) BLOCK {|| Posicione("SRJ",1, xFilial("SRJ")+PadR(Trim((cAlias1)->(TFF_FUNCAO)), TamSx3("RJ_DESC")[1]),"SRJ->RJ_DESC") } //"Desc. Local"		

oSection4 := TRSection():New(oSection3	,FwX2Nome("ABB") ,{"ABB"},,,,,,,,,,9,,,.T.)
DEFINE CELL NAME "ABB_CODIGO"		OF oSection4 ALIAS "ABB"
DEFINE CELL NAME "ABB_DTINI"		OF oSection4 ALIAS "ABB"
DEFINE CELL NAME "ABB_HRINI"		OF oSection4 ALIAS "ABB"
DEFINE CELL NAME "ABB_DTFIM"		OF oSection4 ALIAS "ABB"
DEFINE CELL NAME "ABB_HRFIM"		OF oSection4 ALIAS "ABB"
DEFINE CELL NAME "ABB_HRTOT"	    OF oSection4 BLOCK {|| AT580TReal(cAlias1)}	
DEFINE CELL NAME "ABB_CODTEC"		OF oSection4 ALIAS "ABB"
DEFINE CELL NAME STR0006	 		OF oSection4 SIZE (TamSX3("AA1_NOMTEC")[1]) BLOCK {|| Posicione("AA1",1, xFilial("AA1")+PadR(Trim((cAlias1)->ABB_CODTEC), TamSx3("AA1_NOMTEC")[1]),"AA1->AA1_NOMTEC") } //"Nome Atend."																

//Totalizador de Horas
oSum1 := TRFunction():New(oSection4:Cell("ABB_HRTOT" ),"Tot1","SUM",,STR0007,,,.T.,,,,{|| .T. }) //"Total de Horas de Reforço"
oSum1:SetEndSection(.T.)
oSum1:SetEndReport(.F.)

Return oReport

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Rt331Print()
Reforço - monta a Query e imprime o relatorio de acordo com os parametros

@sample 	Rt331Print(oReport, cPerg, cAlias1)

@param		oReport, 	Object,	Objeto do relatório de postos vagos
			cPerg, 		String,	Nome do grupo de perguntas
			cAlias1,	String,	Nome do alias da Query do relatório 
			
@return 	Nenhum

@author 	Serviços
@since		29/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Rt990Print(oReport, cPerg, cAlias1)
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
		   TFF_FUNCAO,
		   ABB_CODIGO,
		   ABB_DTINI,
		   ABB_HRINI,
		   ABB_DTFIM,
		   ABB_HRFIM,
		   ABB_HRTOT,
		   ABB_CODTEC,
		   ABB_TIPOMV,
		   TFL_CODPAI,
		   TFJ_CODIGO,
		   ABQ_CODTFF,
		   TFF_CODPAI,
		   TFL_CODIGO
		   
	FROM %table:ABB% ABB

	INNER JOIN %table:ABQ% ABQ ON (ABQ.ABQ_FILIAL=%xFilial:ABQ% AND ABQ.ABQ_CONTRT||ABQ.ABQ_ITEM||ABQ.ABQ_ORIGEM=ABB.ABB_IDCFAL AND ABQ.ABQ_LOCAL=ABB.ABB_LOCAL AND ABQ.%NotDel%) 

	INNER JOIN %table:TFF% TFF ON (TFF.TFF_FILIAL=%xFilial:TFF% AND TFF.TFF_COD=ABQ.ABQ_CODTFF AND TFF.%NotDel%)

	INNER JOIN %table:TFL% TFL ON (TFL.TFL_FILIAL=%xFilial:TFL% AND TFL.TFL_CODIGO=TFF_CODPAI AND TFL.%NotDel%)

	INNER JOIN %table:TDV% TDV ON (TDV.TDV_FILIAL=%xFilial:TDV% AND TDV.TDV_CODABB=ABB.ABB_CODIGO AND TDV.%NotDel%)
	
	INNER JOIN %table:TFJ% TFJ ON (TFJ.TFJ_FILIAL=%xFilial:TFJ% AND TFJ.TFJ_CODIGO=TFL.TFL_CODPAI AND TFJ.%NotDel%)
	
	WHERE ABB.ABB_FILIAL=%xFilial:ABB%     AND
		  ABB.%NotDel%				       AND
		  ABB.ABB_ATENDE = '1'		   	   AND
		  TFF.TFF_ORIREF <> ''			   AND
		  TFJ.TFJ_CODENT BETWEEN %Exp:cMvpar01% AND %Exp:cMvpar03%  AND
		  TFJ.TFJ_LOJA   BETWEEN %Exp:cMvpar02% AND %Exp:cMvpar04%  AND
		  TFL.TFL_LOCAL  BETWEEN %Exp:cMvpar05% AND %Exp:cMvpar06%  AND
		  (ABB.ABB_DTINI BETWEEN %Exp:cMvpar07% AND %Exp:cMvpar08%  OR 
		  ABB.ABB_DTFIM  BETWEEN %Exp:cMvpar07% AND %Exp:cMvpar08%)

EndSql

END REPORT QUERY oSection1

(cAlias1)->(DbGoTop())

oSection2:SetParentQuery()
oSection2:SetParentFilter({|cParam| (cAlias1)->TFJ_CODIGO == cParam},{|| (cAlias1)->TFL_CODPAI })

oSection3:SetParentQuery()
oSection3:SetParentFilter({|cParam| (cAlias1)->TFL_CODIGO == cParam},{|| (cAlias1)->TFF_CODPAI })

oSection4:SetParentQuery()
oSection4:SetParentFilter({|cParam| (cAlias1)->TFF_COD == cParam},{|| (cAlias1)->ABQ_CODTFF })

//Executa impressão
oSection1:Print()

(cAlias1)->(DbCloseArea())
          
Return(.T.)