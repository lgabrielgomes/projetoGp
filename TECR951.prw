#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "REPORT.CH"
#INCLUDE "TECR951.CH"

Static nTotGer1   := 0
Static nTotGer2   := 0
Static nTotGer3   := 0
Static nTotCob 	  := 0
Static nTotFal 	  := 0
Static nTotRef 	  := 0
Static nTotFt 	  := 0
Static nTotFol 	  := 0
Static nTotTrab   := 0
Static nTotPlan   := 0
Static nTotTrei   := 0
Static nTotExed   := 0
Static nTotDobra  := 0

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECR951()
Produtividade do Plantão

@sample 	TECR951()

@return		oReport, 	Object,	Objeto do relatório Produtividade do Plantão

@author 	Serviços
@since		27/05/2019

Periodo
Cargo
Turno

/*/
//--------------------------------------------------------------------------------------------------------------------
Function TECR951()
Local cPerg		:= "TECR951"
Local oReport	:= Nil //Objeto relatorio TReport

If TRepInUse() 
	Pergunte(cPerg,.F.)	
	oReport := Rt951RDef(cPerg)
	oReport:PrintDialog()	
EndIf

Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Rt951RDef()
Produtividade do Plantão - monta as Sections para impressão do relatório

@sample Rt951RDef(cPerg)
@param 	cPerg 
@return oReport

@author 	Serviços
@since		29/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Rt951RDef(cPerg)
Local oReport		:= Nil				
Local oSection1 	:= Nil			 
Local oSection2 	:= Nil			 
Local oSection3 	:= Nil			 
Local oSection4 	:= Nil
Local oSection5 	:= Nil
Local oSection6		:= Nil

oReport   := TReport():New("TECR951",STR0001,cPerg,{|oReport| Rt951Print(oReport, cPerg )},STR0001) //"Produtividade do Plantão"

oSection1 := TRSection():New(oReport	,STR0002 ,{"TGY"}) //"Efetivos"

DEFINE CELL NAME "COBEFET"	 OF oSection1 TITLE STR0003 	 	 BLOCK {|| Atr951Tot("COBEFET"	,"1") } //"Cobertura"
DEFINE CELL NAME "FALTPEFET" OF oSection1 TITLE STR0004 	  	 BLOCK {|| Atr951Tot("FALTPEFET","1") } //"Falta"
DEFINE CELL NAME "REFEFET"	 OF oSection1 TITLE STR0005   	 	 BLOCK {|| Atr951Tot("REFEFET"	,"1") } //"Reforço"
DEFINE CELL NAME "FTEFET"  	 OF oSection1 TITLE STR0006 		 BLOCK {|| Atr951Tot("FTEFET"	,"1") } //"FT"
DEFINE CELL NAME "DOBRAEFET" OF oSection1 TITLE "Dobra" 	 	 BLOCK {|| Atr951Tot("DOBRAEFET","1") } //"Dobra"
DEFINE CELL NAME "FOLGEFET"  OF oSection1 TITLE STR0007 		 BLOCK {|| Atr951Tot("FOLGEFET"	,"1") } //"Folga Aplicada"
DEFINE CELL NAME "TRABEFET"  OF oSection1 TITLE STR0008 	 	 BLOCK {|| Atr951Tot("TRABEFET"	,"1") } //"Trabalhado"
DEFINE CELL NAME "CBALMEFET" OF oSection1 TITLE STR0009 	 	 BLOCK {|| Atr951Tot("CBALMEFET","1") } //"Cob. Almoço"
DEFINE CELL NAME "TOTEFET"   OF oSection1 TITLE STR0010		 	 BLOCK {|| nTotGer1 } //"Total"

oSection2 := TRSection():New(oReport	,STR0016 ,{"TGY"}) //"Plantão"

DEFINE CELL NAME "COBPLAN"	 OF oSection2 TITLE STR0003		 	BLOCK {|| Atr951Tot("COBPLAN"	,"2") } //"Cobertura"
DEFINE CELL NAME "FALTPPLAN" OF oSection2 TITLE STR0004	  	 	BLOCK {|| Atr951Tot("FALTPPLAN" ,"2") } //"Falta"
DEFINE CELL NAME "REFPLAN"	 OF oSection2 TITLE STR0005   	 	BLOCK {|| Atr951Tot("REFPLAN"	,"2") } //"Reforço"
DEFINE CELL NAME "FTPLAN"  	 OF oSection2 TITLE STR0006 		BLOCK {|| Atr951Tot("FTPLAN"	,"2") } //"FT"
DEFINE CELL NAME "DOBRAPLAN" OF oSection2 TITLE "Dobra" 		BLOCK {|| Atr951Tot("DOBRAPLAN"	,"2") } //"Dobra"
DEFINE CELL NAME "FOLGPLAN"  OF oSection2 TITLE STR0007			BLOCK {|| Atr951Tot("FOLGPLAN"	,"2") } //"Folga Aplicada"
DEFINE CELL NAME "SOBRPLAN"  OF oSection2 TITLE STR0011  		BLOCK {|| Atr951Tot("SOBRPLAN"	,"2") } //"Sobra Plant."
DEFINE CELL NAME "TREIPLAN"  OF oSection2 TITLE STR0012 		BLOCK {|| Atr951Tot("TREIPLAN"	,"2") } //"Treinamento"
DEFINE CELL NAME "EXCEPLAN"  OF oSection2 TITLE STR0013  		BLOCK {|| Atr951Tot("EXCEPLAN"	,"2") } //"Excedente"
DEFINE CELL NAME "TOTPLAN"   OF oSection2 TITLE STR0010       	BLOCK {|| nTotGer2 } //"Total"

oSection3 := TRSection():New(oReport	,STR0017 ,{"TGY"}) //"Geral" 

DEFINE CELL NAME "COBGERAL"	 	OF oSection3 TITLE STR0003	   		BLOCK {|| nTotCob  } //"Cobertura" 
DEFINE CELL NAME "FALTPGERAL" 	OF oSection3 TITLE STR0004	  	   	BLOCK {|| nTotFal  } //"Falta"
DEFINE CELL NAME "REFGERAL"	 	OF oSection3 TITLE STR0005   	   	BLOCK {|| nTotRef  } //"Reforço"
DEFINE CELL NAME "FTGERAL"  	OF oSection3 TITLE STR0006 		  	BLOCK {|| nTotFt   } //"FT"
DEFINE CELL NAME "DOBRAGERL"  	OF oSection3 TITLE "Dobra"		  	BLOCK {|| nTotDobra} //"Dobra"
DEFINE CELL NAME "FOLGGERAL"  	OF oSection3 TITLE STR0007	  	   	BLOCK {|| nTotFol  } //"Folga Aplicada" 
DEFINE CELL NAME "TRABGERAL"  	OF oSection3 TITLE STR0008		 	BLOCK {|| nTotTrab } //"Trabalhado"
DEFINE CELL NAME "SOBRGERAL"  	OF oSection3 TITLE STR0011  		BLOCK {|| nTotPlan } //"Sobra Plantão"
DEFINE CELL NAME "EXDTREIGERAL" OF oSection3 TITLE STR0014 			BLOCK {|| nTotTrei+nTotExed } //"Exed./Treinam."
DEFINE CELL NAME "RECIGERAL"  	OF oSection3 TITLE STR0015 			BLOCK {|| Atr951Tot("RECIGERAL") } //"Reciclagem"
DEFINE CELL NAME "TOTGERAL"  	OF oSection3 TITLE STR0010	   	   	BLOCK {|| nTotGer3 := (nTotGer1+nTotGer2) } //"Total"

oSection4 := TRSection():New(oReport	,"Resumo Plantão"  ,{"TGY"}) //"Resumo Plantão"

DEFINE CELL NAME "12X36"	OF oSection4 TITLE "12X36"	   		BLOCK {|| Atr951Tot("12X36","2")  } //"12X36"
DEFINE CELL NAME "2X1"	 	OF oSection4 TITLE "2X1"	   		BLOCK {|| Atr951Tot("2X1","2")    } //"2X1"
DEFINE CELL NAME "4X2"	 	OF oSection4 TITLE "4X2"	   		BLOCK {|| Atr951Tot("4X2","2")    } //"4X2"
DEFINE CELL NAME "4X3"	 	OF oSection4 TITLE "4X3"	   		BLOCK {|| Atr951Tot("4X3","2")    } //"4X3"
DEFINE CELL NAME "5X1"	 	OF oSection4 TITLE "5X1"	   		BLOCK {|| Atr951Tot("5X1","2")    } //"5X1"
DEFINE CELL NAME "5X2"	 	OF oSection4 TITLE "5X2"	   		BLOCK {|| Atr951Tot("5X2","2")    } //"5X2"
DEFINE CELL NAME "6X1"	 	OF oSection4 TITLE "6X1"	   		BLOCK {|| Atr951Tot("6X1","2")    } //"6X1"

oSection5 	:= TRSection():New(oReport	,"Total RH"  ,{"TGY"}) //"Total"
DEFINE CELL NAME "TOTADEMI"	 	OF oSection5 TITLE "Total Admissão"				BLOCK {|| Atr951Tot("TOTADEMI")  } //"Terceiro Turno"
DEFINE CELL NAME "TOTDEMI"	 	OF oSection5 TITLE "Total Demissão"				BLOCK {|| Atr951Tot("TOTDEMI")   } //"Terceiro Turno"

oSection6 	:= TRSection():New(oReport	,"Percentual"  ,{"TGY"}) //"Percentual"
DEFINE CELL NAME "PERCEFET"	 	 OF oSection6 TITLE "Efetivos/Geral"			BLOCK {|| cValtoChar(NoRound(nTotGer1/nTotGer3,2))+"%" } //"Efetivos/Geral"
DEFINE CELL NAME "PERCEPLANEFET" OF oSection6 TITLE "Plantão/Efetivos"			BLOCK {|| cValtoChar(NoRound(nTotGer2/nTotGer1,2))+"%"  } //"Plantão/Efetivos"

Return oReport

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Rt951Print()
Produtividade do Plantão - monta a Query e imprime o relatorio de acordo com os parametros

@sample 	Rt951Print(oReport, cPerg, cAlias1)

@param		oReport, 	Object,	Objeto do relatório de postos vagos
			cPerg, 		String,	Nome do grupo de perguntas
			cAlias1,	String,	Nome do alias da Query do relatório 
			
@return 	Nenhum

@author 	Serviços
@since		29/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Rt951Print(oReport, cPerg)
Local oSection1	:= oReport:Section(1)		
Local oSection2	:= oReport:Section(2) 	
Local oSection3	:= oReport:Section(3)
Local oSection4	:= oReport:Section(4)	
Local oSection5	:= oReport:Section(5)
Local oSection6	:= oReport:Section(6)

Local cAlias1	:= GetNextAlias()
Local cAlias2	:= GetNextAlias()
Local cAlias3	:= GetNextAlias()
Local cAlias4	:= GetNextAlias()
Local cAlias5	:= GetNextAlias()
Local cAlias6	:= GetNextAlias()

BEGIN REPORT QUERY oSection1

BeginSQL Alias cAlias1

	SELECT TGY_FILIAL
	FROM %table:TGY% TGY
	WHERE TGY.TGY_FILIAL=%xFilial:TGY%
  	  AND TGY.%NotDel% 
  	GROUP BY TGY_FILIAL
	
EndSql

END REPORT QUERY oSection1

BEGIN REPORT QUERY oSection2

BeginSQL Alias cAlias2

	SELECT TGY_FILIAL
	FROM %table:TGY% TGY
	WHERE TGY.TGY_FILIAL=%xFilial:TGY%
  	  AND TGY.%NotDel% 
  	GROUP BY TGY_FILIAL
	
EndSql

END REPORT QUERY oSection2


BEGIN REPORT QUERY oSection3

BeginSQL Alias cAlias3

	SELECT TGY_FILIAL
	FROM %table:TGY% TGY
	WHERE TGY.TGY_FILIAL=%xFilial:TGY%
  	  AND TGY.%NotDel% 
  	GROUP BY TGY_FILIAL
	
EndSql

END REPORT QUERY oSection3

BEGIN REPORT QUERY oSection4

BeginSQL Alias cAlias4

	SELECT TGY_FILIAL
	FROM %table:TGY% TGY
	WHERE TGY.TGY_FILIAL=%xFilial:TGY%
  	  AND TGY.%NotDel% 
  	GROUP BY TGY_FILIAL
	
EndSql

END REPORT QUERY oSection4

BEGIN REPORT QUERY oSection5

BeginSQL Alias cAlias5

	SELECT TGY_FILIAL
	FROM %table:TGY% TGY
	WHERE TGY.TGY_FILIAL=%xFilial:TGY%
  	  AND TGY.%NotDel% 
  	GROUP BY TGY_FILIAL
	
EndSql

END REPORT QUERY oSection5


BEGIN REPORT QUERY oSection6

BeginSQL Alias cAlias6

	SELECT TGY_FILIAL
	FROM %table:TGY% TGY
	WHERE TGY.TGY_FILIAL=%xFilial:TGY%
  	  AND TGY.%NotDel% 
  	GROUP BY TGY_FILIAL
	
EndSql

END REPORT QUERY oSection6

oSection1:Print()
oSection2:Print()
oSection3:Print()
oSection4:Print()
oSection5:Print()
oSection6:Print()

(cAlias1)->(DbCloseArea())
(cAlias2)->(DbCloseArea())
(cAlias3)->(DbCloseArea())
(cAlias4)->(DbCloseArea())
(cAlias5)->(DbCloseArea())
(cAlias6)->(DbCloseArea())
          
Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Atr951Tot()
Calcula o total de todos os tipos.

@sample 	Rt951Print(oReport, cPerg, cAlias1)

@param		oReport, 	Object,	Objeto do relatório de postos vagos
			cPerg, 		String,	Nome do grupo de perguntas
			cAlias1,	String,	Nome do alias da Query do relatório 
			
@return 	Nenhum

@author 	Serviços
@since		29/05/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Atr951Tot(cCmpRpt,cTip)
Local nTotRet 	:= 0
Local cAliasTot := ""
Local cTpMov	:= ""
Local cMotivo   := ""
Local cWhere	:= "%%"
Local cCodTFF	:= ""
Local cXEscal	:= ""
Local cMvpar01	:= MV_PAR01
Local cMvpar02	:= MV_PAR02
Local cMvpar03	:= MV_PAR03
Local cMvpar04	:= MV_PAR04
Local cMvpar05	:= MV_PAR05
Local cMvpar06	:= MV_PAR06

Default cCmpRpt := ""
Default cTip	:= ""

If cTip == "1"
	cTpMov := "001"
Elseif cTip == "2"
	cTpMov := "RES"
Endif

If cCmpRpt $ "REFEFET|REFPLAN" 
	If cTip == "1"
		cTpMov := "015"
	Elseif cTip == "2"
		cTpMov := ""
	Endif
Endif

If cCmpRpt $ "FTEFET|FTPLAN" 
	If cTip == "1"
		cTpMov := "011"
	Elseif cTip == "2"
		cTpMov := ""
	Endif
Endif

If cTip == "2" 
	If cCmpRpt == "TREIPLAN"
		cTpMov := "005"
	Elseif cCmpRpt == "EXCEPLAN"
		cTpMov := "004"
	Endif
Endif

If cCmpRpt == "CBALMEFET"
	cTpMov := "002"
Endif

If cCmpRpt == "RECIGERAL"

	cCodTFF := SuperGetMv("MV_GSRHREC",,"")

	cAliasTot := GetNextAlias()

	BeginSQL Alias cAliasTot
		
		SELECT COUNT(*) QTDTOTAL
		FROM %table:ABB% ABB
			INNER JOIN %table:TFF% TFF
				ON  TFF.TFF_FILIAL = %xFilial:TFF%
				AND TFF.TFF_COD    = ABB.ABB_CODTFF
				AND TFF.%NotDel%
		WHERE ABB.ABB_FILIAL  = %xFilial:ABB%
			AND ABB.ABB_CODTFF = %Exp:cCodTFF%
			AND ABB.%NotDel%
			AND (ABB.ABB_DTINI 	BETWEEN %Exp:cMvpar01% AND %Exp:cMvpar02%  
			OR ABB.ABB_DTFIM  	BETWEEN %Exp:cMvpar01% AND %Exp:cMvpar02%) 
			AND TFF.TFF_FUNCAO 	BETWEEN %Exp:cMvpar03% AND %Exp:cMvpar04%
			AND TFF.TFF_ESCALA  BETWEEN %Exp:cMvpar05% AND %Exp:cMvpar06%
		GROUP BY ABB.ABB_DTINI,ABB.ABB_TIPOMV,ABB.ABB_IDCFAL,ABB.ABB_CODTFF,ABB.ABB_CODTEC

	EndSql

	(cAliasTot)->(DbGoTop())

	While (cAliasTot)->(!Eof())
	
		nTotRet++
		
		(cAliasTot)->(DbSkip())

	EndDo

	(cAliasTot)->(DbCloseArea())

Endif

If cCmpRpt $ "DOBRAEFET|DOBRAPLAN"

	cWhere := "	AND EXISTS ("
	cWhere += "	 SELECT 1 FROM " + RetSQLName('TW3') +" TW3 "
	cWhere += "	 	WHERE  TW3.TW3_FILIAL = '" +  xFilial("TW3") + "'"
	cWhere += "  		AND TW3.TW3_ITRHCT = ABB_CODTEC "
	cWhere += "  		AND TW3.TW3_ITRHCT = ABB_CODTFF "
	cWhere += "  		AND TW3.TW3_DTMOV >= ABB_DTINI "
	cWhere += "  		AND TW3.TW3_DTMOV <= ABB_DTFIM "
	cWhere += "  		AND TW3.TW3_SITCOD = 'A5' "
	cWhere += "			AND TW3.D_E_L_E_T_ = ' ')"

	cWhere  := "%"+cWhere+"%"

Endif

If cCmpRpt $ "TOTADEMI|TOTDEMI"

	cWhere := "	AND EXISTS ("
	cWhere += "	 SELECT 1 FROM " + RetSQLName('SRA') +" SRA "
	cWhere += " 	INNER JOIN "+RetSqlName("AA1") + " AA1"
	cWhere += " 		ON AA1.AA1_CDFUNC = SRA.RA_MAT "
  	cWhere += " 		AND AA1.D_E_L_E_T_ = ' ' "
	cWhere += "	 WHERE SRA.RA_FILIAL = '" +  xFilial("SRA") + "'"
	If cCmpRpt == "TOTADEMI"
		cWhere += "	AND SRA.RA_ADMISSA >= '" +  dTos(cMvpar01) + "'"
		cWhere += "	AND SRA.RA_ADMISSA <= '" +  dTos(cMvpar02) + "'"
	Elseif cCmpRpt == "TOTDEMI"
		cWhere += "	AND SRA.RA_DEMISSA >= '" +  dTos(cMvpar01) + "'"
		cWhere += "	AND SRA.RA_DEMISSA <= '" +  dTos(cMvpar02) + "'"
	Endif
	cWhere += " AND AA1.AA1_CODTEC = ABB.ABB_CODTEC "
  	cWhere += " AND SRA.D_E_L_E_T_ = ' ' )"
	
	cWhere  := "%"+cWhere+"%"

Endif

If cCmpRpt $ "COBEFET|COBPLAN" 
	
	cAliasTot := GetNextAlias()
	
	BeginSQL Alias cAliasTot
		
		SELECT COUNT(*) QTDTOTAL
		FROM %table:ABR% ABR
			INNER JOIN %table:ABB% ABB 
				ON  ABB.ABB_FILIAL = %xFilial:ABB%
				AND ABB.ABB_CODIGO = ABR.ABR_AGENDA
				AND ABB.%NotDel%
			INNER JOIN %table:TFF% TFF
				ON  TFF.TFF_FILIAL = %xFilial:TFF%
				AND TFF.TFF_COD    = ABB.ABB_CODTFF
				AND TFF.%NotDel%
		WHERE ABR.ABR_FILIAL  = %xFilial:ABR%
			AND ABR.%NotDel%
			AND ABR.ABR_CODSUB <> ''
			AND ABB.ABB_TIPOMV = %Exp:cTpMov%
			AND (ABB.ABB_DTINI 	BETWEEN %Exp:cMvpar01% AND %Exp:cMvpar02%  
			OR ABB.ABB_DTFIM  	BETWEEN %Exp:cMvpar01% AND %Exp:cMvpar02%) 
			AND TFF.TFF_FUNCAO 	BETWEEN %Exp:cMvpar03% AND %Exp:cMvpar04%
			AND TFF.TFF_ESCALA  BETWEEN %Exp:cMvpar05% AND %Exp:cMvpar06%

		GROUP BY ABR.ABR_DTMAN,ABR.ABR_MOTIVO,ABB.ABB_IDCFAL,ABB.ABB_CODTFF

	EndSql

	(cAliasTot)->(DbGoTop())

	While (cAliasTot)->(!Eof())
	
		nTotRet++
		
		(cAliasTot)->(DbSkip())

	EndDo

	(cAliasTot)->(DbCloseArea())

Elseif cCmpRpt $ "FALTPEFET|FALTPPLAN|FOLGPLAN|FOLGEFET" 

	If cCmpRpt $ "FALTPEFET|FALTPPLAN"
		cMotivo := SuperGetMv("MV_ATMTFAL",,"")
	Elseif cCmpRpt $ "FOLGPLAN|FOLGEFET"
		cMotivo := SuperGetMv("MV_ATMTFOL",,"")
	Endif

	If !Empty(cMotivo)

		cAliasTot := GetNextAlias()
	
		BeginSql Alias cAliasTot
	
			SELECT COUNT(*) QTDTOTAL
			FROM %table:ABR% ABR
				INNER JOIN %table:ABB% ABB 
					ON  ABB.ABB_FILIAL = %xFilial:ABB%
					AND ABB.ABB_CODIGO = ABR.ABR_AGENDA
					AND ABB.%NotDel%
				INNER JOIN %table:TFF% TFF
					ON  TFF.TFF_FILIAL = %xFilial:TFF%
					AND TFF.TFF_COD    = ABB.ABB_CODTFF
					AND TFF.%NotDel%
			WHERE ABR.ABR_FILIAL  = %xFilial:ABR%
				AND ABR.%NotDel%
				AND ABR.ABR_MOTIVO = %Exp:cMotivo%
				AND ABB.ABB_TIPOMV = %Exp:cTpMov%
				AND (ABB.ABB_DTINI 	BETWEEN %Exp:cMvpar01% AND %Exp:cMvpar02%  
				OR ABB.ABB_DTFIM  	BETWEEN %Exp:cMvpar01% AND %Exp:cMvpar02%) 
				AND TFF.TFF_FUNCAO 	BETWEEN %Exp:cMvpar03% AND %Exp:cMvpar04%
				AND TFF.TFF_ESCALA  BETWEEN %Exp:cMvpar05% AND %Exp:cMvpar06%
				
			GROUP BY ABR.ABR_DTMAN,ABR.ABR_MOTIVO,ABB.ABB_IDCFAL,ABB.ABB_CODTFF,ABB.ABB_CODTEC
		EndSql
	
		(cAliasTot)->(DbGoTop())

		While (cAliasTot)->(!Eof())
		
			nTotRet++
			(cAliasTot)->(DbSkip())
	
		EndDo
		
		(cAliasTot)->(DbCloseArea())

	Endif

Elseif cCmpRpt $ "REFEFET|REFPLAN|FTEFET|DOBRAEFET|TRABEFET|FTPLAN||SOBRPLAN|TREIPLAN|EXCEPLAN|DOBRAPLAN" .And. !Empty(cTpMov)
	
	cAliasTot := GetNextAlias()
	
	BeginSQL Alias cAliasTot
		
		SELECT COUNT(*) QTDTOTAL
		FROM %table:ABB% ABB
			INNER JOIN %table:TFF% TFF
				ON  TFF.TFF_FILIAL = %xFilial:TFF%
				AND TFF.TFF_COD    = ABB.ABB_CODTFF
				AND TFF.%NotDel%
		WHERE ABB.ABB_FILIAL  = %xFilial:ABB%
			AND ABB.ABB_TIPOMV = %Exp:cTpMov%
			AND ABB.%NotDel%
			%Exp:cWhere%
			AND (ABB.ABB_DTINI 	BETWEEN %Exp:cMvpar01% AND %Exp:cMvpar02%  
			OR ABB.ABB_DTFIM  	BETWEEN %Exp:cMvpar01% AND %Exp:cMvpar02%) 
			AND TFF.TFF_FUNCAO 	BETWEEN %Exp:cMvpar03% AND %Exp:cMvpar04%
			AND TFF.TFF_ESCALA  BETWEEN %Exp:cMvpar05% AND %Exp:cMvpar06%

		GROUP BY ABB.ABB_DTINI,ABB.ABB_TIPOMV,ABB.ABB_IDCFAL,ABB.ABB_CODTFF,ABB.ABB_CODTEC

	EndSql

	(cAliasTot)->(DbGoTop())

	While (cAliasTot)->(!Eof())
	
		nTotRet++
		
		(cAliasTot)->(DbSkip())

	EndDo

	(cAliasTot)->(DbCloseArea())

Elseif cCmpRpt == "CBALMEFET"

	cAliasTot := GetNextAlias()
	
	BeginSQL Alias cAliasTot
		
		SELECT 1
		FROM %table:ABB% ABB
			INNER JOIN %table:TFF% TFF
				ON  TFF.TFF_FILIAL = %xFilial:TFF%
				AND TFF.TFF_COD    = ABB.ABB_CODTFF
				AND TFF.%NotDel%
		WHERE ABB.ABB_FILIAL  = %xFilial:ABB%
			AND ABB.ABB_TIPOMV = %Exp:cTpMov%
			AND ABB.%NotDel%
			%Exp:cWhere%
			AND (ABB.ABB_DTINI 	BETWEEN %Exp:cMvpar01% AND %Exp:cMvpar02% 
			OR ABB.ABB_DTFIM  	BETWEEN %Exp:cMvpar01% AND %Exp:cMvpar02%) 
			AND TFF.TFF_FUNCAO 	BETWEEN %Exp:cMvpar03% AND %Exp:cMvpar04%
			AND TFF.TFF_ESCALA  BETWEEN %Exp:cMvpar05% AND %Exp:cMvpar06%

			AND EXISTS( SELECT 1 FROM %table:TGZ% TGZ WHERE TGZ.TGZ_FILIAL  = %xFilial:TGZ%
														AND TGZ.TGZ_CODTFF 	= ABB.ABB_CODTFF
														AND TGZ.TGZ_CODTW0  <> ''
														AND TGZ.%NotDel% )

			AND EXISTS( SELECT 1 FROM %table:TW0% TW0 WHERE TW0.TW0_FILIAL  = %xFilial:TW0%
														AND TW0.TW0_ATEND 	= ABB.ABB_CODTEC
														AND (TW0.TW0_TIPO 	= '2' OR TW0.TW0_TIPO 	= '2')
														AND TW0.%NotDel% )

			AND EXISTS( SELECT 1 FROM %table:TW1% TW1 WHERE TW1.TW1_FILIAL  = %xFilial:TW1%
														AND TW1.TW1_CODTFF 	= ABB.ABB_CODTFF
														AND TW1.%NotDel% )
	EndSql
	
	(cAliasTot)->(DbGoTop())

	While (cAliasTot)->(!Eof())
		
		nTotRet++
		
		(cAliasTot)->(DbSkip())

	EndDo

	(cAliasTot)->(DbCloseArea())

Endif

If cTip == "1"
	nTotGer1 += nTotRet
ELseif cTip == "2"
	nTotGer2 += nTotRet
Endif

If cCmpRpt $ "COBEFET|COBPLAN"
	nTotCob += nTotRet
Elseif cCmpRpt $ "FALTPEFET|FALTPPLAN"
	nTotFal += nTotRet
Elseif cCmpRpt $ "REFEFET|REFPLAN"
	nTotRef += nTotRet
Elseif cCmpRpt $ "FTEFET|FTPLAN"
	nTotFt += nTotRet
Elseif cCmpRpt $ "FOLGEFET|FOLGPLAN"
	nTotFol += nTotRet
Elseif cCmpRpt == "TRABEFET"
	nTotTrab += nTotRet
Elseif cCmpRpt == "SOBRPLAN"
	nTotPlan += nTotRet
Elseif cCmpRpt == "TREIPLAN"
	nTotTrei += nTotRet
Elseif cCmpRpt == "EXCEPLAN"
	nTotExed += nTotRet
Elseif cCmpRpt $ "DOBRAEFET|DOBRAPLAN"
	nTotDobra += nTotRet
Endif

If cCmpRpt $ "12X36|2X1|4X2|4X3|5X1|5X2|6X1"
	
	If cCmpRpt == "12X36"
		cXEscal	:= "1"	
	ElseIf cCmpRpt == "2X1"
		cXEscal	:= "2"
	ElseIf cCmpRpt == "4X2"
		cXEscal	:= "3"		
	ElseIf cCmpRpt == "4X3"
		cXEscal	:= "4"		
	ElseIf cCmpRpt == "5X1"
		cXEscal	:= "5"
	ElseIf cCmpRpt == "5X2"
		cXEscal	:= "6"
	Elseif cCmpRpt == "6X1"
		cXEscal	:= "7" 
	Endif	

	cAliasTot := GetNextAlias()

	BeginSQL Alias cAliasTot
		
		SELECT COUNT(*) QTDTOTAL
		FROM %table:ABB% ABB
			INNER JOIN %table:TFF% TFF
				ON  TFF.TFF_FILIAL = %xFilial:TFF%
				AND TFF.TFF_COD    = ABB.ABB_CODTFF
				AND TFF.%NotDel%
			INNER JOIN %table:TDW% TDW
				ON  TDW.TDW_FILIAL = %xFilial:TDW%
				AND TDW.TDW_COD    = TFF.TFF_ESCALA
				AND TDW.%NotDel%

		WHERE ABB.ABB_FILIAL  = %xFilial:ABB%
			AND ABB.ABB_TIPOMV = %Exp:cTpMov%
			AND ABB.%NotDel%
			%Exp:cWhere%
			AND (ABB.ABB_DTINI 	BETWEEN %Exp:cMvpar01% AND %Exp:cMvpar02%  
			OR ABB.ABB_DTFIM  	BETWEEN %Exp:cMvpar01% AND %Exp:cMvpar02%) 
			AND TFF.TFF_FUNCAO 	BETWEEN %Exp:cMvpar03% AND %Exp:cMvpar04%
			AND TFF.TFF_ESCALA  BETWEEN %Exp:cMvpar05% AND %Exp:cMvpar06%
			AND TDW.TDW_XESCAL = %Exp:cXEscal%
		GROUP BY ABB.ABB_DTINI,ABB.ABB_TIPOMV,ABB.ABB_IDCFAL,ABB.ABB_CODTFF,ABB.ABB_CODTEC

	EndSql

	(cAliasTot)->(DbGoTop())

	While (cAliasTot)->(!Eof())
	
		nTotRet++
		
		(cAliasTot)->(DbSkip())

	EndDo

	(cAliasTot)->(DbCloseArea())

Endif

If cCmpRpt $ "TOTDEMI|TOTADEMI"

	cAliasTot := GetNextAlias()
	
	BeginSQL Alias cAliasTot
		
		SELECT COUNT(*) QTDTOTAL
		FROM %table:ABB% ABB
			INNER JOIN %table:TFF% TFF
				ON  TFF.TFF_FILIAL = %xFilial:TFF%
				AND TFF.TFF_COD    = ABB.ABB_CODTFF
				AND TFF.%NotDel%
		WHERE ABB.ABB_FILIAL  = %xFilial:ABB%
			AND ABB.%NotDel%
			%Exp:cWhere%
			AND (ABB.ABB_DTINI 	BETWEEN %Exp:cMvpar01% AND %Exp:cMvpar02%  
			OR ABB.ABB_DTFIM  	BETWEEN %Exp:cMvpar01% AND %Exp:cMvpar02%) 
			AND TFF.TFF_FUNCAO 	BETWEEN %Exp:cMvpar03% AND %Exp:cMvpar04%
			AND TFF.TFF_ESCALA  BETWEEN %Exp:cMvpar05% AND %Exp:cMvpar06%

		GROUP BY ABB.ABB_CODTEC

	EndSql

	(cAliasTot)->(DbGoTop())

	While (cAliasTot)->(!Eof())
	
		nTotRet++
		
		(cAliasTot)->(DbSkip())

	EndDo

	(cAliasTot)->(DbCloseArea())

Endif

Return nTotRet