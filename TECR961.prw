#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "REPORT.CH"
#INCLUDE "TECR961.CH"

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECR961()
Escalas de Serviço de Atendentes

@sample 	TECR961()

@return		oReport, 	Object,	Objeto do relatório de Escalas de Serviço de Atendentes

@author 	Serviços
@since		27/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TECR961()
Local cPerg		:= "TECR961"
Local oReport	:= Nil

If TRepInUse() 
Pergunte(cPerg,.F.)		
	oReport := Rt961RDef(cPerg)
	oReport:SetLandScape()
	oReport:PrintDialog()
EndIf

Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Rt961RDef()
Escalas de Serviço de Atendentes - monta as Sections para impressão do relatório

@sample Rt961RDef(cPerg)
@param 	cPerg 
@return oReport

@author 	Serviços
@since		29/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Rt961RDef(cPerg)
Local oReport		:= Nil				
Local oSection1 	:= Nil				
Local oSection2  	:= Nil				
Local oSection3 	:= Nil
Local oSection4 	:= Nil
Local cAlias1		:= GetNextAlias()
Local oSum1			:= Nil

oReport   := TReport():New("TECR961",STR0001,cPerg,{|oReport| Rt961Print(oReport, cPerg, cAlias1)},STR0001) //"Escalas de Serviço de Atendentes"

oSection1 := TRSection():New(oReport	,FwX2Nome("TFJ") ,{"TFJ","TFL","TFF","TGY"},,,,,,,,,,,,,.T.)
DEFINE CELL NAME "TFJ_CODIGO"		OF oSection1 ALIAS "TFJ"
DEFINE CELL NAME "TFJ_CODENT"		OF oSection1 ALIAS "TFJ"
DEFINE CELL NAME "TFJ_LOJA"			OF oSection1 ALIAS "TFJ"
DEFINE CELL NAME STR0002			OF oSection1 SIZE (TamSX3("A1_NOME")[1]) BLOCK {|| Posicione("SA1",1, xFilial("SA1")+PadR(Trim((cAlias1)->(TFJ_CODENT+TFJ_LOJA)), TamSx3("A1_NOME")[1]),"SA1->A1_NOME") } //"Nome Cli."      																	
			
oSection2 := TRSection():New(oSection1	,FwX2Nome("TFL") ,{"TFL"},,,,,,,,,,3,,,.T.)
DEFINE CELL NAME "TFL_LOCAL"	OF oSection2 ALIAS "TFL"
DEFINE CELL NAME STR0003		OF oSection2 SIZE (TamSX3("ABS_DESCRI")[1]) BLOCK {|| Posicione("ABS",1, xFilial("ABS")+PadR(Trim((cAlias1)->(TFL_LOCAL)), TamSx3("ABS_DESCRI")[1]),"ABS->ABS_DESCRI") } //"Desc. Local"		

oSection3 := TRSection():New(oSection2	,FwX2Nome("TFF") ,{"TFF"},,,,,,,,,,6,,,.T.)
DEFINE CELL NAME "TFF_COD"		OF oSection3 ALIAS "TFF"
DEFINE CELL NAME "TFF_ESCALA"	OF oSection3 ALIAS "TFF"
DEFINE CELL NAME STR0004		OF oSection3 SIZE (TamSX3("TDW_DESC")[1]) BLOCK {|| Posicione("TDW",1, xFilial("TDW")+PadR(Trim((cAlias1)->(TFF_ESCALA)), TamSx3("TDW_DESC")[1]),"TDW->TDW_DESC") } //"Desc. Esc."	
DEFINE CELL NAME "TFF_FUNCAO"	OF oSection3 ALIAS "TFF"
DEFINE CELL NAME STR0005		OF oSection3 SIZE (TamSX3("RJ_DESC")[1]) BLOCK {|| Posicione("SRJ",1, xFilial("SRJ")+PadR(Trim((cAlias1)->(TFF_FUNCAO)), TamSx3("RJ_DESC")[1]),"SRJ->RJ_DESC") } //"Desc. Local"		

oSection4 := TRSection():New(oSection3	,FwX2Nome("TGY") ,{"TGY"},,,,,,,,,,9,,,.T.)
DEFINE CELL NAME "TGY_ATEND"		OF oSection4 ALIAS "TGY"
DEFINE CELL NAME STR0006	 		OF oSection4 SIZE (TamSX3("AA1_NOMTEC")[1])  BLOCK {|| Posicione("AA1",1, xFilial("AA1")+PadR(Trim((cAlias1)->TGY_ATEND), TamSx3("AA1_NOMTEC")[1]),"AA1->AA1_NOMTEC") } //"Nome Atend."																
DEFINE CELL NAME "TGY_TURNO"		OF oSection4 ALIAS "TGY" 
DEFINE CELL NAME "TGY_SEQ"			OF oSection4 ALIAS "TGY"
DEFINE CELL NAME "TGY_ENTRA1"		OF oSection4 ALIAS "TGY" TITLE STR0007 BLOCK {|| At960HrAlc("E",cAlias1) } //"Hr. Entrada"
DEFINE CELL NAME "TGY_SAIDA1"		OF oSection4 ALIAS "TGY" TITLE STR0008 BLOCK {|| At960HrAlc("S",cAlias1) } //"Hr. Saída"   
DEFINE CELL NAME "DIASTRAB"			OF oSection4 ALIAS "TGY" TITLE STR0009 LINE BREAK SIZE 170 BLOCK {|| Atr961DTrb((cAlias1)->TGY_CODTDX,MV_PAR05,MV_PAR06) } //"Dias Trab."

oSection4:SetLineBreak()

Return oReport

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Rt331Print()
Escalas de Serviço de Atendentes - monta a Query e imprime o relatorio de acordo com os parametros

@sample 	Rt331Print(oReport, cPerg, cAlias1)

@param		oReport, 	Object,	Objeto do relatório de postos vagos
			cPerg, 		String,	Nome do grupo de perguntas
			cAlias1,	String,	Nome do alias da Query do relatório 
			
@return 	Nenhum

@author 	Serviços
@since		29/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Rt961Print(oReport, cPerg, cAlias1)
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

BEGIN REPORT QUERY oSection1

BeginSQL Alias cAlias1

	SELECT *
		   
	FROM %table:TGY% TGY

	INNER JOIN %table:TFF% TFF ON (TFF.TFF_FILIAL=%xFilial:TFF% AND TFF.TFF_COD=TGY.TGY_CODTFF AND TFF.%NotDel%)

	INNER JOIN %table:TFL% TFL ON (TFL.TFL_FILIAL=%xFilial:TFL% AND TFL.TFL_CODIGO=TFF_CODPAI AND TFL.%NotDel%)
	
	INNER JOIN %table:TFJ% TFJ ON (TFJ.TFJ_FILIAL=%xFilial:TFJ% AND TFJ.TFJ_CODIGO=TFL.TFL_CODPAI AND TFJ.%NotDel%)
	
	WHERE TGY.TGY_FILIAL=%xFilial:TGY%     
		  AND TGY.%NotDel%
		  AND TGY.TGY_ESCALA BETWEEN %Exp:cMvpar01% AND %Exp:cMvpar02% 
		  AND TGY.TGY_TURNO  BETWEEN %Exp:cMvpar03% AND %Exp:cMvpar04%
		  AND TGY.TGY_TURNO  BETWEEN %Exp:cMvpar03% AND %Exp:cMvpar04%
		  AND (TGY.TGY_DTINI BETWEEN %Exp:cMvpar05% AND %Exp:cMvpar06%
		  OR   TGY.TGY_DTFIM BETWEEN %Exp:cMvpar05% AND %Exp:cMvpar06%)

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

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Atr961DTrb()

@sample 	Atr961DTrb(cAlias1)

@param		cAlias1, 	Alias,	Alias da Query
			
@return 	Nenhum

@author 	Serviços
@since		29/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Atr961DTrb(cCodTDX,dDtaIni,dDtaFim)
Local cAliasTGW := GetNextAlias()
Local cDiasRet 	:= ""
Local dDtAux	:= cTod("")
Default cCodTDX	:= ""
Default dDtaIni := cTod("")
Default dDtaFim := cTod("")

If !Empty(cCodTDX)
	
	dDtAux := dDtaIni
	
	BeginSQL Alias cAliasTGW
	
		SELECT TGW.TGW_DIASEM
		FROM %table:TGW% TGW
		WHERE TGW.TGW_FILIAL = %xFilial:TGW% 
			AND TGW.TGW_STATUS = '1'
			AND TGW.TGW_EFETDX = %Exp:cCodTDX%
			AND TGW.%NotDel%
		GROUP BY TGW.TGW_DIASEM
		ORDER BY TGW.TGW_DIASEM
	EndSql
	
	While dDtAux < dDtaFim
		
		(cAliasTGW)->(DbGoTop())

		While (cAliasTGW)->(!Eof())
		
			If (cAliasTGW)->TGW_DIASEM == cValToChar(Dow(dDtAux))
				cDiasRet += SubStr(cValtoChar(dDtAux),1,2)+" "
			Endif
		
			(cAliasTGW)->(DbSkip())
		
		EndDo
	
		dDtAux++
	
	EndDo
Endif

(cAliasTGW)->(DbCloseArea())

Return cDiasRet