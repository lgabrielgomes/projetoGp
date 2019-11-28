#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "REPORT.CH"
#INCLUDE "TECR960.CH"

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECR960()
Endereço de Cliente

@sample 	TECR960()

@return		oReport, 	Object,	Objeto do relatório de Ficha de Localização

@author 	Serviços
@since		27/05/2019
/*/

//--------------------------------------------------------------------------------------------------------------------
Function TECR960()
Local cPerg		:= "TECR960"
Local oReport	:= Nil

If TRepInUse() 
	Pergunte(cPerg,.F.)	
	oReport := Rt960RDef(cPerg)
	oReport:SetLandScape()
	oReport:PrintDialog()	
EndIf

Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Rt960RDef()
Ficha de Localização - monta as Sections para impressão do relatório

@sample Rt960RDef(cPerg)
@param 	cPerg 
@return oReport

@author 	Serviços
@since		29/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Rt960RDef(cPerg)
Local oReport		:= Nil				
Local oSection1 	:= Nil				
Local cAlias1		:= GetNextAlias()

oReport   := TReport():New("TECR960",STR0001,cPerg,{|oReport| Rt960Print(oReport, cPerg, cAlias1)},STR0001) //"Ficha de Localização"

//Section 1 - SA1 - Clientes
oSection1 := TRSection():New(oReport	,FwX2Nome("TGY") ,{"TGY","ABS","AA1"},,,,,,,,,,,,,.T.)
DEFINE CELL NAME "TGY_ATEND"		OF oSection1 ALIAS "TGY"
DEFINE CELL NAME "Nome Atend."	 	OF oSection1 SIZE (TamSX3("AA1_NOMTEC")[1]) BLOCK {|| Posicione("AA1",1, xFilial("AA1")+PadR(Trim((cAlias1)->TGY_ATEND), TamSx3("AA1_NOMTEC")[1]),"AA1->AA1_NOMTEC") } 	//"Nome Atend."																
DEFINE CELL NAME "TGY_ESCALA"		OF oSection1 ALIAS "TGY"  				 
DEFINE CELL NAME "TGY_TURNO"		OF oSection1 ALIAS "TGY"
DEFINE CELL NAME "ABS_CODIGO"		OF oSection1 ALIAS "ABS"
DEFINE CELL NAME "ABS_LOJA"			OF oSection1 ALIAS "ABS"
DEFINE CELL NAME "Nome Cli."  		OF oSection1 SIZE (TamSX3("A1_NOME")[1]) BLOCK {|| Posicione("SA1",1, xFilial("SA1")+PadR(Trim((cAlias1)->(ABS_CODIGO+ABS_LOJA)), TamSx3("A1_NOME")[1]),"SA1->A1_NOME") } //"Nome Cli."      																	
DEFINE CELL NAME "ABS_LOCAL"		OF oSection1 ALIAS "ABS"
DEFINE CELL NAME "ABS_DESCRI"		OF oSection1 ALIAS "ABS"
DEFINE CELL NAME "TGY_CODTFF"		OF oSection1 ALIAS "TGY" TITLE STR0004			 
DEFINE CELL NAME "AA1_FUNCAO"		OF oSection1 ALIAS "AA1"
DEFINE CELL NAME "Desc. Func."  	OF oSection1 SIZE (TamSX3("RJ_DESC")[1]) BLOCK {|| Posicione("SRJ",1, xFilial("SRJ")+PadR(Trim((cAlias1)->(AA1_FUNCAO)), TamSx3("RJ_DESC")[1]),"SRJ->RJ_DESC") } //"Desc. Func."      																	
DEFINE CELL NAME "TGY_DTINI"		OF oSection1 ALIAS "TGY"
DEFINE CELL NAME "TGY_ULTALO"		OF oSection1 ALIAS "TGY"
DEFINE CELL NAME "TGY_ENTRA1"		OF oSection1 ALIAS "TGY" TITLE STR0002 BLOCK {|| At960HrAlc("E",cAlias1) } //"Hr. Entrada"
DEFINE CELL NAME "TGY_SAIDA1"		OF oSection1 ALIAS "TGY" TITLE STR0003 BLOCK {|| At960HrAlc("S",cAlias1) } //"Hr. Saída"   

Return oReport

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Rt331Print()
Endereço de Cliente - monta a Query e imprime o relatorio de acordo com os parametros

@sample 	Rt331Print(oReport, cPerg, cAlias1)

@param		oReport, 	Object,	Objeto do relatório de postos vagos
			cPerg, 		String,	Nome do grupo de perguntas
			cAlias1,	String,	Nome do alias da Query do relatório 
			
@return 	Nenhum

@author 	Serviços
@since		29/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Rt960Print(oReport, cPerg, cAlias1)
Local oSection1	:= oReport:Section(1)	
Local cMvpar01	:= MV_PAR01
Local cMvpar02	:= MV_PAR02
Local cMvpar03	:= MV_PAR03
Local cMvpar04	:= MV_PAR04

BEGIN REPORT QUERY oSection1

BeginSQL Alias cAlias1

	SELECT TGY_ATEND,
		   TGY_ESCALA,
		   TGY_TURNO,
		   TGY_SEQ,
		   ABS_CODIGO,
		   ABS_LOJA,
		   ABS_LOCAL,
		   ABS_DESCRI,
		   TGY_DTINI,
		   TGY_ULTALO,
		   TGY_DTFIM,
		   TGY_ENTRA1,
		   TGY_SAIDA1,
		   TGY_ENTRA2,
		   TGY_SAIDA2,
		   TGY_ENTRA3,
		   TGY_SAIDA3,
		   TGY_ENTRA4,
		   TGY_SAIDA4,
		   AA1_FUNCAO,
		   TGY_CODTFF
	
	FROM %table:TGY% TGY

	INNER JOIN %table:TFF% TFF ON TFF.TFF_FILIAL = %xFilial:TFF% AND
								  TFF.TFF_COD 	 = TGY_CODTFF    AND
								  TFF.%NotDel% 
								  
	INNER JOIN %table:TFL% TFL ON TFL.TFL_FILIAL = %xFilial:TFL%  AND
	 							  TFL.TFL_CODIGO = TFF.TFF_CODPAI AND 
	 							  TFL.%NotDel% 

	INNER JOIN %table:ABS% ABS ON ABS.ABS_FILIAL = %xFilial:ABS%  AND
	 							  ABS.ABS_LOCAL  = TFL.TFL_LOCAL  AND 
	 							  ABS.%NotDel% 

	INNER JOIN %table:AA1% AA1 ON AA1.AA1_FILIAL = %xFilial:AA1%  AND
	 							  AA1.AA1_CODTEC = TGY.TGY_ATEND  AND 
	 							  AA1.%NotDel% 
    
	WHERE TGY.TGY_FILIAL=%xFilial:TGY%
  	  AND TGY.%NotDel% 
 	  AND TGY.TGY_ATEND  BETWEEN %Exp:cMvpar01% AND %Exp:cMvpar02% 
 	  AND AA1.AA1_FUNCAO BETWEEN %Exp:cMvpar03% AND %Exp:cMvpar04% 
 	  ORDER BY TGY_DTINI
   	
EndSql

END REPORT QUERY oSection1

(cAlias1)->(DbGoTop())

//Executa impressão
oSection1:Print()

(cAlias1)->(DbCloseArea())
          
Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At960HrAlc()
Seleciona o horário de entrada e saida do posto.

@sample 	At960HrAlc(cTip,cAlias1)

@param		cTip, 		String,	E = Entrada, S = Saida.
			cAlias1,	String,	Nome do alias da Query do relatório 
			
@return 	Nenhum

@author 	Serviços
@since		29/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At960HrAlc(cTip,cAlias1)
Local nX	   := 0
Local cEscala  := ""
Local cTurno   := ""
Local cSeq	   := ""
Local xHrRet   := ""
Local nHrAux   := 0
Local cDiaSem  := ""
Local cCodEftv := ""

//Verifica se existe horário flexivel na TGY caracter.
If cTip == "E" .And. !Empty((cAlias1)->TGY_ENTRA1)
	xHrRet := (cAlias1)->TGY_ENTRA1

Elseif cTip == "S"
	For nX := 1 to 4
		If !Empty(&("(cAlias1)->TGY_SAIDA" + cValToChar(nX)))
			xHrRet := &("(cAlias1)->TGY_SAIDA" + cValToChar(nX))
		EndIf
	Next nX
Endif

If Empty(xHrRet)
	//Verifica qual é o primeiro horário da escala conforme o turno e a sequencia.
	cEscala := (cAlias1)->TGY_ESCALA
	cTurno  := (cAlias1)->TGY_TURNO
	cSeq	:= (cAlias1)->TGY_SEQ

	cAliasTGW := GetNextAlias()

	BeginSql Alias cAliasTGW

		SELECT 	TGW.TGW_HORINI,
				TGW.TGW_HORFIM,
				TGW.TGW_DIASEM,
				TGW.TGW_EFETDX
		FROM 
			%table:TGW% TGW
		INNER JOIN %table:TDX% TDX ON TDX.TDX_FILIAL = %xFilial:TDX% AND
			TDX.TDX_CODTDW = %Exp:cEscala%  AND
			TDX.TDX_TURNO  = %Exp:cTurno%   AND
			TDX.TDX_SEQTUR = %Exp:cSeq%     AND
			TDX.TDX_COD    = TGW.TGW_EFETDX AND
			TDX.%NotDel%

		WHERE TGW.TGW_FILIAL = %xFilial:TGW% AND
			  TGW.TGW_STATUS = '1' 		     AND
			  TGW.%NotDel%

		ORDER BY TGW.TGW_FILIAL,TGW.TGW_EFETDX,TGW.TGW_DIASEM,TGW_HORINI

	EndSql

	(cAliasTGW)->(DbGoTop())

	cDiaSem  := (cAliasTGW)->TGW_DIASEM
	cCodEftv := (cAliasTGW)->TGW_EFETDX

	While (cAliasTGW)->(!EOF()) .And. cDiaSem == (cAliasTGW)->TGW_DIASEM .And. cCodEftv == (cAliasTGW)->TGW_EFETDX
		If cTip == "E"
			xHrRet :=  (cAliasTGW)->TGW_HORINI
			Exit

		Elseif cTip == "S"
			xHrRet :=  (cAliasTGW)->TGW_HORFIM
		Endif
	
		(cAliasTGW)->(dbSkip())
	EndDo

	(cAliasTGW)->(dbCloseArea())
Endif

If Valtype(xHrRet) == "C"
	xHrRet := Val(xHrRet)
Endif

xHrRet := Atr960CvHr(xHrRet)

Return xHrRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Atr960CvHr
Realiza conversão de hora para formato utilizado pela rotina

@since 03/06/2019

@author 	Serviços

@param nHora, numérico, Hora no formato Inteiro

@return String, Hora em String no formato utilizado pela rotina
/*/
//--------------------------------------------------------------------------------------------------------------------
Function Atr960CvHr(nHoras)
Local nHora := Int(nHoras)//recupera somente a hora
Local nMinuto := (nHoras - nHora)*100//recupera somento os minutos	

Return(StrZero(nHora, 2) + ":" + StrZero(nMinuto, 2))