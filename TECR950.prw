#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "REPORT.CH"
#INCLUDE "TECR950.CH"

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECR950()
Atendentes na Experiência

@sample 	TECR950()

@return		oReport, 	Object,	Objeto do relatório Atendentes na Experiência

@author 	Serviços
@since		27/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TECR950()
Local cPerg		:= "TECR950"
Local oReport	:= Nil //Objeto relatorio TReport

If TRepInUse() 
	Pergunte(cPerg,.F.)	
	oReport := Rt950RDef(cPerg)
	oReport:SetLandScape()
	oReport:PrintDialog()	
EndIf

Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Rt950RDef()
Atendentes na Experiência - monta as Sections para impressão do relatório

@sample Rt950RDef(cPerg)
@param 	cPerg 
@return oReport

@author 	Serviços
@since		29/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Rt950RDef(cPerg)
Local oReport		:= Nil				
Local oSection1 	:= Nil			 
Local oCount		:= Nil
Local cAlias1		:= GetNextAlias()

oReport   := TReport():New("TECR950",STR0001,cPerg,{|oReport| Rt950Print(oReport, cPerg, cAlias1)},STR0001) //"Atendentes na Experiência"

oSection1 := TRSection():New(oReport	,FwX2Nome("TGY") ,{"TGY","ABS"},,,,,,,,,,,,,.T.) //Posto x Funcinário

DEFINE CELL NAME "TGY_ATEND"		OF oSection1 ALIAS "TGY"
DEFINE CELL NAME STR0002 			OF oSection1 SIZE (TamSX3("AA1_NOMTEC")[1]) BLOCK {|| Posicione("AA1",1, xFilial("AA1")+PadR(Trim((cAlias1)->TGY_ATEND), TamSx3("AA1_NOMTEC")[1]),"AA1->AA1_NOMTEC") } 	//"Nome Atend."																
DEFINE CELL NAME "TGY_ESCALA"		OF oSection1 ALIAS "TGY"  				 
DEFINE CELL NAME "TGY_TURNO"		OF oSection1 ALIAS "TGY"
DEFINE CELL NAME "ABS_CODIGO"		OF oSection1 ALIAS "ABS"
DEFINE CELL NAME "ABS_LOJA"			OF oSection1 ALIAS "ABS"
DEFINE CELL NAME STR0003 			OF oSection1 SIZE (TamSX3("A1_NOME")[1]) BLOCK {|| Posicione("SA1",1, xFilial("SA1")+PadR(Trim((cAlias1)->(ABS_CODIGO+ABS_LOJA)), TamSx3("A1_NOME")[1]),"SA1->A1_NOME") } //"Nome Cli."      																	
DEFINE CELL NAME "ABS_LOCAL"		OF oSection1 ALIAS "ABS"
DEFINE CELL NAME "ABS_DESCRI"		OF oSection1 ALIAS "ABS"
DEFINE CELL NAME "TGY_CODTFF"		OF oSection1 ALIAS "TGY" TITLE STR0004 //"Posto"
DEFINE CELL NAME "TGY_DTINI"		OF oSection1 ALIAS "TGY"
DEFINE CELL NAME "TGY_DTINI"		OF oSection1 ALIAS "TGY" BLOCK {|| (cAlias1)->TGY_DTINI+MV_PAR11 } TITLE STR0005 //"Conclusão"
DEFINE CELL NAME "TGY_ULTALO"		OF oSection1 ALIAS "TGY"

//Totalizador
TRFunction():New(oSection1:Cell("TGY_ATEND" ),,"COUNT",,STR0006,,,.F.,)

Return oReport

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Rt950Print()
Atendentes na Experiência - monta a Query e imprime o relatorio de acordo com os parametros

@sample 	Rt950Print(oReport, cPerg, cAlias1)

@param		oReport, 	Object,	Objeto do relatório de postos vagos
			cPerg, 		String,	Nome do grupo de perguntas
			cAlias1,	String,	Nome do alias da Query do relatório 
			
@return 	Nenhum

@author 	Serviços
@since		29/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Rt950Print(oReport, cPerg, cAlias1)
Local oSection1	:= oReport:Section(1)		
Local cMvpar01	:= MV_PAR01
Local cMvpar02	:= MV_PAR02
Local cMvpar03	:= MV_PAR03
Local cMvpar04	:= MV_PAR04
Local cMvpar05	:= MV_PAR05
Local cMvpar06	:= MV_PAR06
Local cMvpar07	:= MV_PAR07
Local cMvpar08	:= MV_PAR08
Local cMvpar09	:= MV_PAR09
Local cMvpar10	:= MV_PAR10
Local cMvpar11	:= MV_PAR11

BEGIN REPORT QUERY oSection1

BeginSQL Alias cAlias1

	COLUMN TGY_DTINI AS DATE
	COLUMN TGY_DTFIM AS DATE
	COLUMN TGY_ULTALO AS DATE
	
	SELECT TGY_ATEND,
		   TGY_ESCALA,
		   TGY_TURNO,
		   ABS_CODIGO,
		   ABS_LOJA,
		   ABS_LOCAL,
		   ABS_DESCRI,
		   TGY_DTINI,
		   TGY_ULTALO,
		   TGY_DTFIM,
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
	 							  ABS.ABS_RESTEC <> "1" 		  AND
	 							  ABS.%NotDel% 

	WHERE TGY.TGY_FILIAL=%xFilial:TGY%
  	  AND TGY.%NotDel% 
 	  AND ABS.ABS_CODIGO BETWEEN %Exp:cMvpar01% AND %Exp:cMvpar03% 
  	  AND ABS.ABS_LOJA 	 BETWEEN %Exp:cMvpar02% AND %Exp:cMvpar04% 
  	  AND TGY.TGY_ESCALA BETWEEN %Exp:cMvpar05% AND %Exp:cMvpar06% 
  	  AND TGY.TGY_TURNO	 BETWEEN %Exp:cMvpar07% AND %Exp:cMvpar08% 
  	  AND (TGY.TGY_DTINI BETWEEN %Exp:cMvpar09% AND %Exp:cMvpar10%
  	  OR   TGY.TGY_DTFIM BETWEEN %Exp:cMvpar09% AND %Exp:cMvpar10%)
   	ORDER BY TGY_ATEND
	
EndSql

END REPORT QUERY oSection1

(cAlias1)->(DbGoTop())

oSection1:SetParentQuery(.F.)
oSection1:Init()

While (cAlias1)->(!Eof())

	//Verifica se o tempo do atendente no posto passou da experiência informada no parâmetro.
	If (((cAlias1)->TGY_DTINI+cMvpar11) <= (cAlias1)->TGY_ULTALO)
		oSection1:PrintLine()
 	Endif
 	(cAlias1)->(dbSkip())
EndDo	

oSection1:Finish()

(cAlias1)->(DbCloseArea())
          
Return(.T.)