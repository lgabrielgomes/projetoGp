#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "REPORT.CH"
#INCLUDE "TECR991.CH"

//-------------------------------------------------------------------
/*/{Protheus.doc} TECR030
Imprime o relatorio de Sobra de Plantão
@since 15/05/2019
@version P12.1.25
@return  oReport - Objeto TRport
/*/
//-------------------------------------------------------------------------------------
Function TECR991()
	local oReport          

	Local cPerg	:= "TECR991"

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
 	//³ PARAMETROS                                                             	³
 	//³ MV_PAR01 : Turno de ?                                                   ³
 	//³ MV_PAR02 : Turno ate?                                                   ³
 	//³ MV_PAR03 : Escala de ?                                              	³
 	//³ MV_PAR04 : Escala ate ?                                             	³
  	//³ MV_PAR05 : Data de ?                                      		   		³
    //³ MV_PAR06 : Data ate ?                                      	     	  	³
 	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ 
 	
 	If !Pergunte(cPerg,.T.)
		Return
	EndIf   
	
	oReport := ReportDef(cPerg)
	oReport:PrintDialog()

Return

//-------------------------------------------------------------------------------------
/*/{Protheus.doc} reportDef
Monta as definiçoes do relatorio de Sobra de Plantão.
@since 15/05/2019
@version P12.1.25
@param cPerg - Pergunta do relatório
@return  oReport - Objeto TRport
/*/
//-------------------------------------------------------------------------------------
Static Function ReportDef(cPerg)
	Local cTitulo 		:= STR0001 //"Relatório Sobra de Plantão"
	Local oReport		:= NIL
	Local oSection0 	:= NIL
	Local oSection1 	:= NIL
	Local oSection2 	:= NIL
	Local oBreak1		:= NIL
	Local oBreak0		:= NIL
	Local oBreak2		:= NIL
	Local nX 			:= 0
	Local nTam 			:= 0
	Local cCodTecAnt	:= "" 
	Local dDiaAnt		:= sTod("")
	Local nDias			:= 0
	Local nTam2 		:= 0
	Local cDescEmp 		:= FwFilName(cEmpAnt, cFilAnt)
	
	oReport := TReport():New(cPerg, cTitulo, cPerg , {|oReport| PrintReport(oReport)},STR0001) //"Relatório Sobra de Plantão"

	DEFINE SECTION oSection0 OF oReport TITLE STR0001 TABLE "QRY" LINE STYLE COLUMNS 2 //""Relatório Sobra de Plantão"

	oBreak0 = TRBreak():New( oSection0 , {|| QRY->TDV_DTREF },STR0002 , .F. , "" , .t. )  //"Total Atendentes Data
 
 		DEFINE CELL NAME "FILIAL"		OF oSection0 ALIAS "QRY" Title STR0003 SIZE Len(cDescEmp) BLOCK {|| cDescEmp } //"Filial"
		DEFINE CELL NAME "TDV_DTREF"	OF oSection0 ALIAS "QRY"
	
	DEFINE SECTION oSection1 OF oSection0 TITLE STR0004 TABLE "QRY" LINE STYLE COLUMNS 2 LEFT MARGIN 5 //"Turno"
 		DEFINE CELL NAME "TDV_TURNO"	OF oSection1 ALIAS "QRY"
		DEFINE CELL NAME "R6_DESC"		OF oSection1 ALIAS "QRY"
		
 		DEFINE CELL NAME "TFF_ESCALA"	OF oSection1 ALIAS "QRY"
		DEFINE CELL NAME "TDW_DESC"		OF oSection1 ALIAS "QRY" Title STR0005 //"Descrição Escala"

 		DEFINE CELL NAME "TFF_CARGO"	OF oSection1 ALIAS "QRY"
		DEFINE CELL NAME "Q3_DESCSUM"	OF oSection1 ALIAS "QRY"  Title STR0006 //"Descrição Cargo"

 		DEFINE CELL NAME "ABS_CODIGO"	OF oSection1 ALIAS "QRY"  title "Cliente" Size TamSx3("A1_COD")[1]+TamSx3("A1_LOJA")[1]  BLOCK {|| ABS_CODIGO+ABS_LOJA } //"Cliente"
		DEFINE CELL NAME "A1_NOME"		OF oSection1 ALIAS "QRY"
		
 		DEFINE CELL NAME "ABS_LOCAL"	OF oSection1 ALIAS "QRY"
		DEFINE CELL NAME "ABS_DESCRI"	OF oSection1 ALIAS "QRY"

	
	oBreak1 = TRBreak():New( oSection1 , {|| QRY->( Dtos(QRY->TDV_DTREF) + TDV_TURNO + TFF_ESCALA + TFF_CARGO + ABS_CODIGO+ ABS_LOJA +ABS_LOCAL)},""  , .F. ,  , .F. )  
	
	DEFINE SECTION oSection2 OF oSection1 TITLE STR0007 TABLE "QRY" LEFT MARGIN 10 //"Atendentes"
		
 		DEFINE CELL NAME "AA1_CODTEC"	OF oSection2 ALIAS "QRY"
		DEFINE CELL NAME "AA1_NOMTEC"	OF oSection2 ALIAS "QRY"	
 		DEFINE CELL NAME "ABB_HRTOT"	OF oSection2 ALIAS "QRY" title STR0008 //"Jornada"
		DEFINE CELL NAME "ABB_CHEGOU"	OF oSection2 ALIAS "QRY"		
		DEFINE CELL NAME "ABS_MUNIC"	OF oSection2 ALIAS "QRY"

	oBreak2 = TRBreak():New( oSection2 , {|| QRY->(  Dtos(QRY->TDV_DTREF) + TDV_TURNO + TFF_ESCALA + TFF_CARGO + ABS_CODIGO+ ABS_LOJA +ABS_LOCAL)},""  , .T. ,  , .F. )  
    TRFunction():New( oSection2:Cell("AA1_CODTEC"), "TOT_CODTEC" , "COUNT" , oBreak1 , "Total Atendentes Turno" , "@ 999.999.999" ,  , .T. , .T. , .F. , oSection1 , /*<bCondition>*/ , /*<lDisable>*/ , /*<bCanPrint>*/ ) //"Total Atendentes Turno"
    TRFunction():New( oSection2:Cell("AA1_CODTEC"), "TOT_CODTEC" , "COUNT" , oBreak0 , "Total Geral Atendentes Turno", "@ 999.999.999" ,  , .T. , .t. , .f. , oSection0 , /*<bCondition>*/ , /*<lDisable>*/ , /*<bCanPrint>*/ ) //"Total Geral Atendentes Turno"


Return (oReport)


//-------------------------------------------------------------------------------------
/*/{Protheus.doc} PrintReport
Pinta o Relatorio de Manutenção de Agendas
@author serviços
@since 15/05/2019
@version P12.1.25
@param - oRepot - Objeto TReport
		aTpAfast - Tipo de Afastamento
		nTam2 - Tamanho do campo Tipo de Afastamento  - Evento de RH
@return  Nil
/*/
//-------------------------------------------------------------------------------------
Static Function PrintReport(oReport, aTpAfast, nTam2)
	Local oSection0 	:= oReport:Section(1)
	Local oSection1 	:= oSection0:Section(1) 
	Local oSection2 	:= oSection1:Section(1) 
	Local cCliDe		:= MV_PAR05 + MV_PAR06
	Local cCliATe		:= MV_PAR07 + MV_PAR08
	Local cCodTEC 		:= ""
	Local cDtVazio 		:= Dtos(Ctod(""))
	Local oTemptable 	:= NIL  //Tabela temporária Afastamentos QRY2
	Local oTemptabl2  	:= NIL //Tabela temportária Atendentes QRY
	Local cCposQry 		:= ""	//Campos da Tabela de Atendentes
	Local aFields 		:= {}	//Campos da tabela temporária de Atendentes
	Local nX 			:= 0
	Local aTam 			:= {}
	Local aCposQry := { "AA1_CODTEC","TDV_DTREF","ABB_HRINI", "ABB_DTFIM", "ABB_HRFIM","TDV_TURNO","TFF_ESCALA", "TFF_CARGO","ABS_CODIGO", "ABS_LOJA",;
						"ABS_MUNIC","ABS_DESCRI", "ABS_LOCAL", "ABB_DTINI", ;
						"ABB_CHEGOU", "ABB_HRTOT","AA1_NOMTEC", ;
						 "TFF_COD", "AA1_CDFUNC", "A1_NOME", "TDW_DESC",  "R6_DESC", "Q3_DESCSUM"} //Campos da Tabela de Atendentes
	Local cAlias		:= GetNextAlias()
	Local cChave := ""
	Local nTotHoras := 0
	Local nY := 0
	Local cQbr0 := CTOD("")
	Local cQbr1 := ""
	
	
	aEval(aCposQry, { |c| aTam := TamSx3(c), ;
						aAdd(aFields, { c,GETSX3CACHE(c, "X3_TIPO") ,aTam[1], aTam[2]} ),;
						cCposQry := cCposQry + (c + ",") })
	
	cCposQry := "%"+Left(cCposQry, Len(cCposQry)-1)+"%"

	BeginSql alias cAlias
		Column ABB_DTINI as DATE
		Column ABB_DTFIM as DATE
		Column TDV_DTREF as DATE
		
		SELECT %exp:cCposQry% 
		FROM  %table:TDV% TDV 
		INNER JOIN %table:ABB% ABB ON  (ABB_FILIAL =  %xfilial:ABB% AND ABB.%notDel%  AND ABB.ABB_CODIGO = TDV.TDV_CODABB)
		INNER JOIN %table:TFF% TFF ON ( TFF.TFF_LOCAL = ABB.ABB_LOCAL AND
									TFF.TFF_ESCALA  BETWEEN %Exp:MV_PAR03% AND %Exp:MV_PAR04% AND
									TFF_FILIAL = %xfilial:TFF% AND
									TFF.%notDel%)
		INNER JOIN 	(
						SELECT 	TGY_FILIAL AS FILIAL, 
								TGY_CODTFF AS CODTFF, 
								TGY_ATEND AS ATEND, 
								TGY_ESCALA AS ESCALA,
								TGY_TURNO AS TURNO,
								'TGY' AS ALIAS
						FROM %table:TGY% TGY
						WHERE 
							TGY_DTINI <= %Exp:MV_PAR06% AND 
							(TGY_DTFIM  =  %Exp:cDtVazio%   OR TGY_DTFIM >= %Exp:MV_PAR05%) AND 
							TGY_FILIAL = %xfilial:TGY% AND
							TGY.%notDel%
						UNION 
						SELECT  TGZ_FILIAL AS FILIAL, 
								TGZ_CODTFF AS CODTFF, 
								TGZ_ATEND AS ATEND , 
								TGZ_ESCALA AS ESCALA,
								TGZ_TURNO AS TURNO,
								'TGZ' AS ALIAS
						FROM %table:TGZ% TGZ
						WHERE
							 TGZ_DTINI <= %Exp:MV_PAR06% AND 
							(TGZ_DTFIM  =  %Exp:cDtVazio%   OR TGZ_DTFIM >= %Exp:MV_PAR05%) AND 
							TGZ_FILIAL = %xfilial:TGY% AND
							TGZ.%notDel%
					)X  ON ( X.ATEND = ABB.ABB_CODTEC AND X.CODTFF = TFF.TFF_COD   )

		INNER JOIN  %table:ABS% ABS ON ( ABS.ABS_LOCAL = TFF.TFF_LOCAL AND
									ABS.ABS_FILIAL =  %xfilial:ABS% AND 
									ABS.%notDel%  AND ABS.ABS_RESTEC = '1') 
		INNER JOIN %table:SA1% SA1 ON (A1_COD = ABS.ABS_CODIGO AND A1_LOJA = ABS.ABS_LOJA AND SA1.%notDel% AND A1_FILIAL =  %xfilial:SA1%)
		INNER JOIN %table:AA1% AA1 ON (AA1_CODTEC = X.ATEND AND AA1.%notDel% AND AA1_FILIAL =  %xfilial:AA1%)		
		INNER JOIN %table:TDW% TDW ON (X.ESCALA = TDW.TDW_COD AND TDW.%notDel% AND TDW_FILIAL =  %xfilial:TDW%)		
		INNER JOIN %table:SR6% SR6 ON (TDV.TDV_TURNO = SR6.R6_TURNO AND SR6.%notDel% AND SR6.R6_FILIAL =  %xfilial:SR6%)	
		LEFT JOIN %table:SQ3% SQ3 ON (TFF.TFF_CARGO = SQ3.Q3_CARGO AND SQ3.%notDel% AND Q3_FILIAL =  %xfilial:SQ3%)				
		WHERE 			
		TDV.%notDel% AND TDV_FILIAL =  %xfilial:TDV% AND
		TDV.TDV_TURNO BETWEEN %Exp:MV_PAR01% AND %Exp:MV_PAR02% AND
		TDV.TDV_DTREF BETWEEN %Exp:MV_PAR05% AND %Exp:MV_PAR06% 
		ORDER BY  AA1_CODTEC, TDV_DTREF,ABB_DTINI, ABB_DTFIM, ABB_HRINI, TDV_TURNO, TFF_ESCALA, ABS_CODIGO, ABS_LOJA , ABS_LOCAL
	EndSql
	

	//Criação das tabelas temporárias do Relatório
	oTempTable := FWTemporaryTable():New( "QRY", aFields )	
	oTempTable:AddIndex("1", { "TDV_DTREF", "TDV_TURNO", "TFF_ESCALA", "TFF_CARGO","ABS_CODIGO", "ABS_LOJA" , "ABS_LOCAL", "AA1_CODTEC"} )
	oTempTable:Create()

	//Realiza a query de atendentes
	While (cAlias)->( !Eof())
	
		If cChave <> (cAlias)->(AA1_CODTEC + Dtos(TDV_DTREF))
			If !Empty(cChave)
				QRY->ABB_HRTOT := IntToHora(nTotHoras)
				QRY->(MsUnLock())
			EndIf
			nTotHoras := 0
			cChave := (cAlias)->(AA1_CODTEC + Dtos(TDV_DTREF))
			RecLock("QRY", .T.)
		   For nY := 1 to Len(aCposQry)
		   		QRY->(FieldPut(nY, (cAlias)->(FieldGet(nY))))
		   Next nY 
		EndIf
		
		nTotHoras += (cAlias)->(SubtHoras(ABB_DTINI,ABB_HRINI,ABB_DTFIM,ABB_HRFIM,.T.) )

		(cAlias)->( DbSkip(1) ) 
	EndDo
	
	If !Empty(cChave)
		  QRY->ABB_HRTOT := IntToHora(nTotHoras)
		 QRY->(MsUnLock())
	EndIf

	(cAlias)->(DbCloseArea())
	
	//Define tamanho da Regua
	oReport:SetMeter(QRY->(RecCount()))
	QRY->(DbGoTop())
	QRY->(DbSetOrder(1))

	oSection1:SetParentFilter({|cParam| QRY->TDV_DTREF == cParam },{|| QRY->TDV_DTREF  })
	oSection2:SetParentFilter({|cParam| QRY->(Dtos(TDV_DTREF) + TDV_TURNO + TFF_ESCALA + TFF_CARGO + ABS_CODIGO+ ABS_LOJA +ABS_LOCAL) == cParam },{|| QRY->( Dtos(TDV_DTREF) + TDV_TURNO + TFF_ESCALA + TFF_CARGO + ABS_CODIGO+ ABS_LOJA +ABS_LOCAL)  })	

	oSection0:Print()

	If Valtype(oTempTable) <> NIL
		oTempTable:Delete() 
		FreeObj(oTempTable)
	EndIf


Return
