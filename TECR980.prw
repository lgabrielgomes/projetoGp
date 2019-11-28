#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "REPORT.CH"
#INCLUDE "TECR980.CH"

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECR980()
SDF Convocação de Atendente 

@sample 	TECR980()

@return		oReport, 	Object,	Objeto do relatório de SDF Convocação de Atendente 

@author 	Serviços
@since		27/05/2019
/*/

//--------------------------------------------------------------------------------------------------------------------
Function TECR980()
Local cPerg		:= "TECR980"
Local oReport	:= Nil

If TRepInUse() 
	Pergunte(cPerg,.F.)	
	oReport := Rt980RDef(cPerg)
	oReport:SetLandScape()
	oReport:PrintDialog()	
EndIf

Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Rt980RDef()
SDF Convocação de Atendente  - monta as Sections para impressão do relatório

@sample Rt980RDef(cPerg)
@param 	cPerg 
@return oReport

@author 	Serviços
@since		29/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Rt980RDef(cPerg)
Local oReport		:= Nil	
Local cAlias1		:= GetNextAlias()

oReport   := TReport():New("TECR980",STR0001,cPerg,{|oReport| Rt980Print(oReport, cPerg, cAlias1)},STR0001) //"SDF Convocação de Atendente"

oSection1 := TRSection():New(oReport	,FwX2Nome("TFF") ,{"TFJ","TFL","TFF"},,,,,,,,,,,,,.T.)

DEFINE CELL NAME "TFJ_CODENT"		OF oSection1 ALIAS "TFJ"
DEFINE CELL NAME "TFJ_LOJA"			OF oSection1 ALIAS "TFJ"
DEFINE CELL NAME STR0002	 		OF oSection1 SIZE (TamSX3("A1_NOME")[1]) BLOCK {|| Posicione("SA1",1, xFilial("SA1")+PadR(Trim((cAlias1)->(TFJ_CODENT+TFJ_LOJA)), TamSx3("A1_NOME")[1]),"SA1->A1_NOME") } //"Nome Cli."      																	
DEFINE CELL NAME STR0003			OF oSection1 SIZE (TamSX3("A1_TEL")[1]) BLOCK {|| Posicione("SA1",1, xFilial("SA1")+PadR(Trim((cAlias1)->(TFJ_CODENT+TFJ_LOJA)), TamSx3("A1_NOME")[1]),"SA1->A1_NOME") }  //"Num. Tel."      																	
DEFINE CELL NAME "TFL_LOCAL"		OF oSection1 ALIAS "TFL"
DEFINE CELL NAME STR0004 			OF oSection1 SIZE (TamSX3("ABS_DESCRI")[1]) BLOCK {|| Posicione("ABS",1, xFilial("ABS")+PadR(Trim((cAlias1)->(TFL_LOCAL)), TamSx3("ABS_DESCRI")[1]),"ABS->ABS_DESCRI") }  //"Desc. Local"		
DEFINE CELL NAME "TFF_COD"			OF oSection1 SIZE 10 ALIAS "TFF" TITLE STR0013 //"Posto"
DEFINE CELL NAME STR0005			OF oSection1 SIZE 18 BLOCK {|| Atr980Hora((cAlias1)->TFF_COD,"1")} //"Sex. Hr. Ini."		
DEFINE CELL NAME STR0006		 	OF oSection1 SIZE 18 BLOCK {|| Atr980Hora((cAlias1)->TFF_COD,"2")} //"Sex. Hr. Fin."
DEFINE CELL NAME STR0007			OF oSection1 SIZE 18 BLOCK {|| Atr980Hora((cAlias1)->TFF_COD,"3")} //"Sáb. Hr. Ini." 		
DEFINE CELL NAME STR0008			OF oSection1 SIZE 18 BLOCK {|| Atr980Hora((cAlias1)->TFF_COD,"4")} //"Sáb. Hr. Fin."
DEFINE CELL NAME STR0009			OF oSection1 SIZE 18 BLOCK {|| Atr980Hora((cAlias1)->TFF_COD,"5")} //"Dom. Hr. Ini."
DEFINE CELL NAME STR0010			OF oSection1 SIZE 18 BLOCK {|| Atr980Hora((cAlias1)->TFF_COD,"6")} //"Dom. Hr. Fin."
DEFINE CELL NAME STR0011			OF oSection1 SIZE 18 BLOCK {|| Atr980Hora((cAlias1)->TFF_COD,"7")} //"Fer. Hr. Ini."
DEFINE CELL NAME STR0012			OF oSection1 SIZE 18 BLOCK {|| Atr980Hora((cAlias1)->TFF_COD,"8")} //"Fer. Hr. Fin."

Return oReport

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Rt331Print()
SDF Convocação de Atendente  - monta a Query e imprime o relatorio de acordo com os parametros

@sample 	Rt331Print(oReport, cPerg, cAlias1)

@param		oReport, 	Object,	Objeto do relatório de postos vagos
			cPerg, 		String,	Nome do grupo de perguntas
			cAlias1,	String,	Nome do alias da Query do relatório 
			
@return 	Nenhum

@author 	Serviços
@since		29/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Rt980Print(oReport, cPerg, cAlias1)
Local oSection1	:= oReport:Section(1)
Local cMvpar01	:= MV_PAR01
Local cMvpar02	:= MV_PAR02
Local cMvpar03	:= MV_PAR03
Local cMvpar04	:= MV_PAR04
Local cMvpar05	:= MV_PAR05
Local cMvpar06	:= MV_PAR06

BEGIN REPORT QUERY oSection1

BeginSQL Alias cAlias1

	SELECT TFJ_CODENT,
		   TFJ_LOJA,
		   TFL_LOCAL,
		   TFF_COD
		   
	FROM %table:TFF% TFF

	INNER JOIN %table:TFL% TFL ON (TFL.TFL_FILIAL=%xFilial:TFL% AND TFL.TFL_CODIGO=TFF_CODPAI AND TFL.%NotDel%)

	INNER JOIN %table:TFJ% TFJ ON (TFJ.TFJ_FILIAL=%xFilial:TFJ% AND TFJ.TFJ_CODIGO=TFL.TFL_CODPAI AND TFJ.%NotDel%)
	
	WHERE TFF.TFF_FILIAL=%xFilial:TFF% AND
		  TFF.%NotDel%				   AND
		  TFJ.TFJ_CODENT BETWEEN %Exp:cMvpar01% AND %Exp:cMvpar03% AND
		  TFJ.TFJ_LOJA 	 BETWEEN %Exp:cMvpar02% AND %Exp:cMvpar04% AND
		  TFL.TFL_LOCAL  BETWEEN %Exp:cMvpar05% AND %Exp:cMvpar06%

EndSql

END REPORT QUERY oSection1

(cAlias1)->(DbGoTop())

//Executa impressão
oSection1:Print()

(cAlias1)->(DbCloseArea())
          
Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Atr980Hora()
Seleciona o horario de entrada e saida de sexta, sabado, domingo e feriado.

@sample 	Rt331Print(oReport, cPerg, cAlias1)

@param		oReport, 	Object,	Objeto do relatório de postos vagos
			cPerg, 		String,	Nome do grupo de perguntas
			cAlias1,	String,	Nome do alias da Query do relatório 
			
@return 	Nenhum

@author 	Serviços
@since		29/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Atr980Hora(cCodTFF,cTip)
Local nHora		:= 0
Local cHrRet 	:= ""
Local cWhere 	:= ""
Local cAliasTGW	:= GetNextAlias()
Local cCodEfetv	:= ""

If cTip $ "1|2"
	cWhere  := "TGW_DIASEM = '6'"
Elseif cTip $ "3|4"
	cWhere  := "TGW_DIASEM = '7'"
Elseif cTip $ "5|6"
	cWhere  := "TGW_DIASEM = '1'"
Elseif cTip $ "5|6" //Quando for feriado busca a tabela de calendário.
	DbSelectArea("TFF")
	TFF->(DbSetOrder(1))
	If TFF->(dbSeek(xFilial("TFF")+cCodTFF ))
		DbSelectArea("RR0")
		RR0->(DbSetOrder(1))
		If RR0->(DbSeek(xFilial("RR0") + TFF->TFF_CALEND ))
			While RR0->(!EOF()) .And. xFilial("RR0") == RR0->RR0_FILIAL .And. TFF->TFF_CALEND == RR0->RR0_CODCAL .And. Empty(cWhere)
				If dDataBase >= RR0->RR0_DATA  
					cWhere :=  "TGW.TGW_DIASEM = '" + Str(Dow(RR0->RR0_DATA),1) + "'"
				Endif
				RR0->(dbSkip())
			EndDo
		Endif
	Endif
Endif

If !Empty(cWhere)

	cWhere := "%"+cWhere+"%" 
	
	BeginSQL Alias cAliasTGW
	
		SELECT TGW.TGW_EFETDX,TGW_HORINI,TGW_HORFIM
	
		FROM %table:TFF% TFF
	
		INNER JOIN %table:TDX% TDX ON (TDX.TDX_FILIAL=%xFilial:TDX% AND TDX.TDX_CODTDW=TFF_ESCALA AND TDX.%NotDel%)
	
		INNER JOIN %table:TGW% TGW ON (TGW.TGW_FILIAL=%xFilial:TGW% AND TGW.TGW_EFETDX=TDX.TDX_COD AND TGW.%NotDel%)
		
		WHERE TFF.TFF_FILIAL=%xFilial:TFF% AND
			  TFF.%NotDel%				   AND
			  TGW.TGW_STATUS = '1'  	   AND
			  %Exp:cWhere% 			       
	    ORDER BY TGW.TGW_EFETDX,TGW.TGW_HORINI
	
	EndSql
	
	(cAliasTGW)->(DbGoTop())

	If (cAliasTGW)->(!EOF())
		
		cCodEfetv := (cAliasTGW)->TGW_EFETDX
		
		While (cAliasTGW)->(!EOF()) .And. cCodEfetv == (cAliasTGW)->TGW_EFETDX
			
			If cTip $ "1|3|5|7"
				nHora := (cAliasTGW)->TGW_HORINI
				Exit
			Elseif cTip $ "2|4|6|8"
				nHora := (cAliasTGW)->TGW_HORFIM
			Endif

			(cAliasTGW)->(dbSkip())

		EndDo
	Endif
	
	(cAliasTGW)->(DbCloseArea())

Endif

cHrRet := Atr980CvHr(nHora)

Return cHrRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Atr980CvHr
Realiza conversão de hora para formato utilizado pela rotina

@since 03/06/2019

@author 	Serviços

@param nHora, numérico, Hora no formato Inteiro

@return String, Hora em String no formato utilizado pela rotina
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Atr980CvHr(nHoras)
Local nHora := Int(nHoras)//recupera somente a hora
Local nMinuto := (nHoras - nHora)*100//recupera somento os minutos	

Return(StrZero(nHora, 2) + ":" + StrZero(nMinuto, 2))