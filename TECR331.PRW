#INCLUDE "PROTHEUS.CH"  
#INCLUDE "REPORT.CH"
#INCLUDE "TECR331.CH"

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECR331()
Relação de Postos Vagos

@sample 	TECR331(dDtRef)

@param		dDtRef, 	Date, 	Data da movimentação

@return		oReport, 	Object,	Objeto do relatório de postos vagos

@author 	Ana Maria Utsumi
@since		15/12/2016
@version 	P12
/*/

//--------------------------------------------------------------------------------------------------------------------
Function TECR331(dDtRef)

Local cPerg		:= "TECR331"
Local oReport					//Objeto relatorio TReport

Default dDtRef := dDataBase
 
Pergunte(cPerg, .F.,,,, .F.)

// Atribui os valores da data da movimentação ao primeiro parametro do relatório
aKeySX1 := {{cPerg, '01', DToC(dDtRef)}}
HS_PosSX1(aKeySX1)
MV_PAR01 := dDtRef

oReport := Rt331RDef(cPerg)
oReport:PrintDialog()

Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Rt331RDef()
Postos Vagos - monta as Sections para impressão do relatório

@sample 	Rt331RDef(cPerg)
@param cPerg 
@return oReport

@author 	Ana Maria Utsumi
@since		15/12/2016
@version	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Rt331RDef(cPerg)

Local oReport		:= Nil				//Objeto relatorio TReport
Local oSection1 	:= Nil				//Objeto secao 1 do relatorio (Cabecalho, campos da tabela SA1) 
Local oSection2  	:= Nil				//Objeto secao 2 do relatorio (detalhes, campos das tabelas "ABS") 
Local oSection3  	:= Nil				//Objeto secao 3 do relatorio (detalhes, campos das tabelas "CN9")
Local oSection4		:= Nil 				//Objeto secao 4 do relatorio (detalhes, campos das tabelas "TFF")
Local cAlias1		:= GetNextAlias()

DEFINE REPORT oReport NAME "TECR331";
TITLE STR0001 PARAMETER "TECR331";							//"Postos Vagos"
ACTION {|oReport| Rt331Print( oReport, cPerg, cAlias1)};
DESCRIPTION STR0001				 							//"Postos Vagos"

//Section 1 - SA1 - Clientes
DEFINE SECTION oSection1 OF oReport TITLE FwX2Nome("SA1") TABLES "SA1"

DEFINE CELL NAME "A1_COD"		OF oSection1 Size(TamSX3("A1_COD")[1])  Block {|| (cAlias1)->A1_COD} ALIAS cAlias1
DEFINE CELL NAME "A1_LOJA"		OF oSection1 Size(TamSX3("A1_LOJA")[1]) 
DEFINE CELL NAME "A1_NOME"		OF oSection1 Size(TamSX3("A1_NOME")[1]) 

//Section 2 - ABS - Local de Atendimento
DEFINE SECTION oSection2 OF oSection1 TITLE FwX2Nome("ABS") TABLES "ABS" LEFT MARGIN 3
DEFINE CELL NAME "TFL_LOCAL"	OF oSection2 Size(TamSX3("TFL_LOCAL")[1]) 
DEFINE CELL NAME "ABS_DESCRI"	OF oSection2 Size(TamSX3("ABS_DESCRI")[1]) 	Block { ||Posicione("ABS",1,xFilial("ABS")+(cAlias1)->TFL_LOCAL,"ABS->ABS_DESCRI")}	//Descrição de Local

//Section 3 - CN9 - Contratos
DEFINE SECTION oSection3 OF oSection2 TITLE FwX2Nome("CN9") TABLES "CN9" LEFT MARGIN 6

DEFINE CELL NAME "CN9_NUMERO"	OF oSection3 Size(TamSX3("CN9_NUMERO")[1]) 
DEFINE CELL NAME "CN9_DTINIC"	OF oSection3 Size(TamSX3("CN9_DTINIC")[1]) 
DEFINE CELL NAME "CN9_DTFIM"	OF oSection3 Size(TamSX3("CN9_DTFIM")[1]) 
DEFINE CELL NAME "TFJ_SRVEXT"   OF oSection3 Size(TamSX3("TFJ_SRVEXT")[1]) 

//Section 4 - TFF - Recurso Humano
DEFINE SECTION oSection4 OF oSection3 TITLE FwX2Nome("TFF") TABLES "TFF" LEFT MARGIN 9

DEFINE CELL NAME "TFF_FUNCAO"	OF oSection4 Size(TamSX3("TFF_FUNCAO")[1])
DEFINE CELL NAME "RJ_DESC"		OF oSection4 Size(TamSX3("RJ_DESC")[1])    	Block { ||Posicione("SRJ",1,xFilial("SRJ")+(cAlias1)->TFF_FUNCAO,"SRJ->RJ_DESC")}	//Descrição de Função
DEFINE CELL NAME "TFF_ESCALA"	OF oSection4 Size(TamSX3("TFF_ESCALA")[1])
DEFINE CELL NAME "TDW_DESC"		OF oSection4 Size(TamSX3("TDW_DESC")[1])	Block { ||Posicione("TDW",1,xFilial("TDW")+(cAlias1)->TFF_ESCALA,"TDW->TDW_DESC")}	//Descrição de Escala
DEFINE CELL NAME "TFF_QTDVEN"	OF oSection4 Size(TamSX3("TFF_QTDVEN")[1]) 	TITLE "Qt.Vendida"
DEFINE CELL NAME "QTD_AGENDA"	OF oSection4 Size(8) PICTURE "@E 99,999,999"	TITLE "Alocados"
DEFINE CELL NAME "QTD_VAGOS"    OF oSection4 Size(8) PICTURE "@E 99,999,999"	TITLE "Qt.Vagos"

oSection1:SetTotalInLine(.T.)
oSection2:SetTotalInLine(.T.)
oSection3:SetTotalInLine(.T.)
oSection4:SetTotalInLine(.F.)
oReport:SetTotalInLine(.T.)


// Totalizadores
DEFINE FUNCTION FROM oSection4:Cell("QTD_VAGOS") OF oSection1 FUNCTION SUM PICTURE "@E 99,999,999" TITLE STR0002 NO END REPORT	//"Total de Postos Vagos"
			
Return oReport

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Rt331Print()
Postos Vagos  - monta a Query e imprime o relatorio de acordo com os parametros

@sample 	Rt331Print(oReport, cPerg, cAlias1)

@param		oReport, 	Object,	Objeto do relatório de postos vagos
			cPerg, 		String,	Nome do grupo de perguntas
			cAlias1,	String,	Nome do alias da Query do relatório 
			
@return 	Nenhum

@author 	Ana Maria Utsumi
@since		15/12/2016
@version	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Rt331Print(oReport, cPerg, cAlias1)

Local oSection1	:= oReport:Section(1)		//Objeto secao 1 do relatorio (Cabecalho, campos da tabela "SA1")
Local oSection2	:= oSection1:Section(1) 	//Objeto secao 2 do relatorio (detalhes, campos das tabelas "ABS")
Local oSection3	:= oSection2:Section(1) 	//Objeto secao 3 do relatorio (detalhes, campos das tabelas "CN9")
Local oSection4	:= oSection3:Section(1) 	//Objeto secao 4 do relatorio (detalhes, campos das tabelas "CN9")
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
Local nCount	:= 0

BEGIN REPORT QUERY oSection1
//Verifica alocações ativas e não atendidas
BeginSQL Alias cAlias1
	SELECT SA1.A1_FILIAL, SA1.A1_COD, SA1.A1_LOJA, SA1.A1_NOME, 
	      (CASE WHEN TFJ.TFJ_SRVEXT=1 THEN TFJ.TFJ_CODIGO ELSE CN9.CN9_NUMERO END) CN9_NUMERO,
          (CASE WHEN TFJ.TFJ_SRVEXT=1 THEN TFF.TFF_PERINI ELSE CN9.CN9_DTINIC END) CN9_DTINIC,
          (CASE WHEN TFJ.TFJ_SRVEXT=1 THEN TFF.TFF_PERFIM ELSE CN9.CN9_DTFIM  END) CN9_DTFIM,
          (CASE WHEN TFJ.TFJ_SRVEXT=1 THEN TFJ.TFJ_CODIGO ELSE TFL.TFL_CONTRT END) TFL_CONTRT,
	       TFL.TFL_LOCAL, TFF.TFF_PRODUT, TFF_QTDVEN,
	       COALESCE(QTD_AGENDA,0) QTD_AGENDA, TFF_QTDVEN - COALESCE(QTD_AGENDA,0) QTD_VAGOS,
	       TFF_COD, TFF_LOCAL, TFF_PERINI, TFF_PERFIM, TFF_FUNCAO, TFF_ESCALA, TFJ.TFJ_CODENT, TFJ.TFJ_SRVEXT
	FROM %table:TFJ% TFJ
	JOIN %table:TFL% TFL ON (TFL.TFL_FILIAL=%xFilial:TFL% AND TFL.TFL_CODPAI=TFJ.TFJ_CODIGO AND TFL.%NotDel%)
	JOIN %table:TFF% TFF ON (TFF.TFF_FILIAL=%xFilial:TFF% AND TFF.TFF_CODPAI=TFL_CODIGO AND TFF.%NotDel%)
	JOIN %table:SA1% SA1 ON (SA1.A1_FILIAL=%xFilial:SA1% AND SA1.A1_COD=TFJ_CODENT AND SA1.A1_LOJA=TFJ_LOJA AND SA1.%NotDel%)
	LEFT JOIN %table:CN9% CN9 ON (CN9.CN9_FILIAL=%xFilial:CN9% AND CN9.CN9_NUMERO=TFL.TFL_CONTRT AND CN9.CN9_REVATU=TFL.TFL_CONREV AND CN9.%NotDel% AND CN9.CN9_SITUAC='05' /*Contrato vigente*/)
    LEFT JOIN %table:ABQ% ABQ ON (ABQ.ABQ_FILIAL=%xFilial:ABQ% AND ABQ.ABQ_CODTFF=TFF.TFF_COD)
	LEFT JOIN (SELECT ABB_FILIAL, ABB_IDCFAL, ABB_LOCAL, COUNT(*) AS QTD_AGENDA
			   FROM (SELECT ABB.ABB_FILIAL, ABB.ABB_IDCFAL, ABB.ABB_LOCAL, TDV.TDV_GRUPO 
    	        	 FROM %table:ABB% ABB 
		        	 JOIN %table:TDV% TDV ON (TDV.TDV_FILIAL=%xFilial:TDV% AND ABB.ABB_CODIGO=TDV_CODABB AND TDV.%NotDel%) 
		             WHERE ABB.ABB_FILIAL=%xFilial:ABB%
		               AND ABB.%NotDel%
			           AND ABB.ABB_ATIVO='1'	//Agenda ativa	
			           AND ABB.ABB_DTINI=%Exp:cMvpar01% 
			           AND ABB.ABB_LOCAL BETWEEN %Exp:cMvpar06% AND %Exp:cMvpar07%
		             GROUP BY ABB.ABB_FILIAL, ABB.ABB_IDCFAL, ABB.ABB_LOCAL, TDV.TDV_GRUPO) A
		       GROUP BY ABB_FILIAL, ABB_IDCFAL, ABB_LOCAL         
		       ) ABB ON (ABB.ABB_FILIAL=%xFilial:ABB% AND ABB.ABB_IDCFAL=ABQ.ABQ_CONTRT||ABQ.ABQ_ITEM||ABQ.ABQ_ORIGEM AND ABB.ABB_LOCAL=ABQ.ABQ_LOCAL) 
	WHERE TFJ.TFJ_FILIAL=%xFilial:TFJ%
  	  AND TFJ.%NotDel% 
  	  AND (TFJ.TFJ_CONTRT<>'' OR TFJ.TFJ_SRVEXT='1')
  	  AND %Exp:cMvpar01% BETWEEN TFF.TFF_PERINI AND TFF.TFF_PERFIM
  	  AND TFJ.TFJ_CODENT BETWEEN %Exp:cMvpar02% AND %Exp:cMvpar03% 
  	  AND TFJ.TFJ_LOJA   BETWEEN %Exp:cMvpar04% AND %Exp:cMvpar05%
  	  AND TFF.TFF_LOCAL  BETWEEN %Exp:cMvpar06% AND %Exp:cMvpar07%
 	  AND TFF.TFF_CONTRT BETWEEN %Exp:cMvpar08% AND %Exp:cMvpar09%
 	  AND TFF.TFF_FUNCAO BETWEEN %Exp:cMvpar10% AND %Exp:cMvpar11%
 	  AND (TFF_QTDVEN - COALESCE(QTD_AGENDA,0))<>0
	ORDER BY SA1.A1_COD, SA1.A1_LOJA, TFL.TFL_LOCAL, CN9.CN9_NUMERO
EndSql

END REPORT QUERY oSection1

Count To nCount
(cAlias1)->(DbGoTop())

//Section 2 - TFL - Locais
oSection2:SetParentQuery()
oSection2:SetParentFilter({|cParam| (cAlias1)->CN9_NUMERO == cParam},{|| (cAlias1)->TFL_CONTRT })

//Section 3 - CN9 - Contratos
oSection3:SetParentQuery()
oSection3:SetParentFilter({|cParam| (cAlias1)->TFJ_CODENT == cParam },{|| (cAlias1)->A1_COD })

//Section 4 - TFF - Recurso Humano
oSection4:SetParentQuery()
oSection4:SetParentFilter({|cParam| (cAlias1)->TFF_COD == cParam },{|| (cAlias1)->TFF_COD })

//Executa impressão
oSection1:Print()

(cAlias1)->(DbCloseArea())
                                                                                                                                           
Return(.T.)
