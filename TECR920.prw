#Include "TECR920.ch"
#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "REPORT.CH"

//-------------------------------------------------------------------
/*/{Protheus.doc} TECR030
Imprime o relatorio de Ficha de Presença
@since 15/05/2019
@version P12.1.25
@return  oReport - Objeto TRport
/*/
//-------------------------------------------------------------------------------------
Function TECR920()
	local oReport          

	Local cPerg	:= "TECR920"

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
 	//³ PARAMETROS                                                             ³
 	//³ MV_PAR01 : Data de ?                                                   ³
 	//³ MV_PAR02 : Data ate?                                                   ³
 	//³ MV_PAR03 : Atendente de ?                                              ³
 	//³ MV_PAR04 : Atendente ate ?                                             ³
  	//³ MV_PAR05 : Cliente de ?                                      		   ³
    //³ MV_PAR06 : Loja de ?                                      	     	   ³
 	//³ MV_PAR07 : Cliente ate ?                                               ³
  	//³ MV_PAR08 : Loja ate ?                                               ³
 	//³ MV_PAR09 : Local de ?                                       		   ³
 	//³ MV_PAR10 : Local ate ?                                                 ³
 	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ 
 	
 	If !Pergunte(cPerg,.T.)
		Return
	EndIf   
	
	oReport := ReportDef(cPerg)
	oReport:PrintDialog()

Return

//-------------------------------------------------------------------------------------
/*/{Protheus.doc} reportDef
Monta as definiçoes do relatorio de Ficha de Presença.
@since 15/05/2019
@version P12.1.25
@param cPerg - Pergunta do relatório
@return  oReport - Objeto TRport
/*/
//-------------------------------------------------------------------------------------
Static Function ReportDef(cPerg)
	Local cTitulo 		:= STR0001 //"Ficha de Presenca"
	Local oReport		:= NIL
	Local oSection0 	:= NIL
	Local oSection1 	:= NIL
	Local oSection2 	:= NIL
	Local oBreak		:= NIL
	Local oBreak0		:= NIL
	Local nX 			:= 0
	Local nTam 			:= 0
	Local cCodTecAnt	:= "" 
	Local dDiaAnt		:= sTod("")
	Local nDias			:= 0
	Local nTam2 		:= 0
	Local nTamData 		:= Len(Dtoc(date()))
	
	Local aTpAfast := {STR0002, STR0004, STR0003 } 	 //"Afastado" //"Demitido" //"Férias"
	aEval(aTpAfast , { |a| nTam2 := Max(Len(a), nTam2)})

	For nX := 1 to 7 
		nTam := Max(Len(TECCdow(Dow(sTod('20190511')+nX))), nTam)
	Next Nx

	oReport := TReport():New(cPerg, cTitulo, cPerg , {|oReport| PrintReport(oReport, aTpAfast, nTam2)},STR0005) //"Ficha de Presença"
	DEFINE SECTION oSection0 OF oReport TITLE STR0005 TABLE "QR3","AA1","SRA" LINE STYLE COLUMNS 2 //"Ficha de Presença"
	oSection0:SetTotalInLine(.T.)
	oBreak0 = TRBreak():New( oSection0 , {|| QRY3->ATEND },""  , .F. ,  , .T. )  
 
 		DEFINE CELL NAME "AA1_CDFUNC"	OF oSection0 ALIAS "AA1"
		DEFINE CELL NAME "AA1_NOMTEC"	OF oSection0 ALIAS "AA1"
		DEFINE CELL NAME "DATADE"		OF oSection0 ALIAS "QRY" TITLE STR0007 SIZE 10 Block{|| MV_PAR01 } //"Início"
		DEFINE CELL NAME "DATAATE"		OF oSection0 ALIAS "QRY" TITLE STR0008 SIZE 10 Block{|| MV_PAR02 } //"Final"
		DEFINE CELL NAME "AA1_CODTEC"	OF oSection0 ALIAS "AA1"
		
		TRPosition():New(oSection0,"AA1", 1,{|| xFilial("AA1")+QRY3->ATEND})  
		TRPosition():New(oSection0,"SRA", 1,{|| QRY3->AA1_FUNFIL+QRY3->AA1_CDFUNC})  
		
		oSection1 := TRSection():New(oSection0,STR0009,{"QRY"}) //"Detalhes"
		oBreak = TRBreak():New( oSection1 , {|| QRY->ABB_CODTEC }, STR0006 , .T. ,  , .F. )  //"Total por Atendente"
			DEFINE CELL NAME "TDV_DTREF"	OF oSection1 ALIAS "TDV" Block {|| QRY->TDV_DTREF }
			DEFINE CELL NAME "DIASEM"		OF oSection1 ALIAS "QRY" TITLE STR0010 SIZE nTam Block {|| TECCdow(Dow(QRY->TDV_DTREF))} // Dia da Semana //"Dia da Semana"
			DEFINE CELL NAME "ABB_HRINI"	OF oSection1 ALIAS "ABB" Block {|| QRY->ABB_HRINI }
			DEFINE CELL NAME "ABB_HRFIM"	OF oSection1 ALIAS "ABB" Block {|| QRY->ABB_HRFIM }
			DEFINE CELL NAME "ABS_LOCAL"	OF oSection1 ALIAS "ABS" Block {|| QRY->ABS_LOCAL }
			DEFINE CELL NAME "ABS_DESCRI"	OF oSection1 ALIAS "ABS" Block {|| QRY->ABS_DESCRI }
			//tipo de manutenção
			DEFINE CELL NAME "ABN_DESC"		OF oSection1 ALIAS "ABN" TITLE STR0011 Block {|| QRY->ABN_DESC }  //"Manutenção"
			DEFINE CELL NAME "HORASTRAB" 	OF oSection1 ALIAS "QRY" TITLE "" SIZE 10 Block {|| SubtHoras(QRY->ABB_DTINI,QRY->ABB_HRINI,QRY->ABB_DTFIM,QRY->ABB_HRFIM,.T.) }
 			DEFINE CELL NAME "ABR_TEMPO"	OF oSection1 ALIAS "ABR" TITLE STR0012 Block {|| 	Iif(QRY->ABN_TIPO $ '01#05',IntToHora(Val(oSection1:Cell("HORASTRAB"):GetText())), QRY->ABR_TEMPO ) } //"Tot. Manut"
			DEFINE CELL NAME "DIATRAB"	   	OF oSection1 ALIAS "QRY" TITLE "" SIZE 4 Block {|| At920DiaTr(@cCodTecAnt, @dDiaAnt, QRY->TDV_DTREF, QRY->ABB_CODTEC, QRY->ABN_TIPO)}
			oSection1:Cell("DIATRAB"):Hide()
			oSection1:Cell("HORASTRAB"):Hide()
			//horas de manutenção
			DEFINE CELL NAME "ABB_HRTOT"	OF oSection1 ALIAS "ABB" Block {|| 	IntToHora(Iif(QRY->ABN_TIPO $ '01#05',0,Val(oSection1:Cell("HORASTRAB"):GetText()))) }

		oSection2 := TRSection():New(oSection0,STR0013, { "QRY2", "ABB"} ) //"Eventos de RH "
			DEFINE CELL NAME "DATAINI" 		OF oSection2 ALIAS "QRY2" SIZE nTamData TITLE STR0014 Block { ||  QRY2->DATAINI  } //"Inicio"
			DEFINE CELL NAME "DATAFIM" 		OF oSection2 ALIAS "QRY2" SIZE nTamData	TITLE STR0008  Block { || QRY2->DATAFIM } //"Final"
			DEFINE CELL NAME "EVENTORH" 	OF oSection2 ALIAS "QRY2" SIZE nTam2 TITLE STR0015 block { || QRY2->EVENTO } //"Evento RH"


	oSection0:SetLineCondition( {|| QRY->(DbSeek(QRY3->ATEND)) .OR. QRY2->(DbSeek(QRY3->ATEND))  })

	DEFINE FUNCTION NAME "TOTREAL" FROM oSection1:Cell("ABB_HRTOT");
	OF oSection0 FUNCTION TIMESUM PICTURE "@ 999999999:99" TITLE STR0016 BREAK oBreak NO END SECTION NO END REPORT  //"Total de Atendimentos Realizados" //"Horas trabalhadas do atendente"
	
	DEFINE FUNCTION NAME "TOTDIATRAB" FROM oSection1:Cell("DIATRAB") ;
	OF oSection0 FUNCTION SUM PICTURE "@R 9999" TITLE STR0017 BREAK oBreak  NO END REPORT NO END SECTION  //"Dias trabalhados do atendente"

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
	Local oSection2 	:= oSection0:Section(2) 
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
	Local aCposQry := {"ABS_DESCRI", "ABS_LOCAL", "ABS_CCUSTO", "ABB_DTINI", ;
						"ABB_HRINI", "ABB_DTFIM", "ABB_HRFIM","AA1_NOMTEC", ;
						"ABR_MOTIVO", "ABR_CODSUB", "ABR_DTMAN", "ABR_TEMPO", ;
						"RA_CIC", "ABB_CODTEC", "ABQ_CODTFF", "AA1_CDFUNC", ;
						"ABN_DESC", "ABN_TIPO", "TDV_DTREF"} //Campos da Tabela de Atendentes
	
	aEval(aCposQry, { |c| aTam := TamSx3(c), ;
						aAdd(aFields, { c,GETSX3CACHE(c, "X3_TIPO") ,aTam[1], aTam[2]} ),;
						cCposQry := cCposQry + (c + ",") })
	
	cCposQry := "%"+Left(cCposQry, Len(cCposQry)-1)+"%"

	BEGIN REPORT QUERY oSection0

		BeginSql alias "QRY3"
		
			SELECT DISTINCT FILIAL, ATEND, AA1.AA1_CDFUNC, AA1.AA1_NOMTEC, AA1.AA1_FUNFIL, SRA.RA_DEMISSA, ' ' AS NOAGD
			FROM
						(
							SELECT 	TGY_FILIAL AS FILIAL, 
									TGY_CODTFF AS CODTFF, 
									TGY_ATEND AS ATEND, 
									'TGY' AS ALIAS
							FROM %table:TGY% TGY
							WHERE 
								TGY_DTINI <= %Exp:MV_PAR02% AND 
								(TGY_DTFIM  =  %Exp:cDtVazio%   OR TGY_DTFIM >= %Exp:MV_PAR01%) AND 
								TGY_ATEND BETWEEN %Exp:MV_PAR03% AND %Exp:MV_PAR04% AND
								TGY_FILIAL = %xfilial:TGY% AND
								TGY.%notDel%
							UNION 
							SELECT  TGZ_FILIAL AS FILIAL, 
									TGZ_CODTFF AS CODTFF, 
									TGZ_ATEND AS ATEND , 
									'TGZ' AS ALIAS
							FROM %table:TGZ% TGZ
							WHERE
								 TGZ_DTINI <= %Exp:MV_PAR02% AND 
								(TGZ_DTFIM  =  %Exp:cDtVazio%   OR TGZ_DTFIM >= %Exp:MV_PAR01%) AND 
								TGZ_ATEND BETWEEN %Exp:MV_PAR03% AND %Exp:MV_PAR04% AND
								TGZ_FILIAL = %xfilial:TGY% AND
								TGZ.%notDel%
						) X
			INNER JOIN %table:TFF% TFF ON ( X.CODTFF = TFF_COD AND 
										TFF_LOCAL BETWEEN %Exp:MV_PAR09% AND %Exp:MV_PAR10% AND
										TFF_FILIAL = %xfilial:TFF%  AND 
										TFF.%notDel%)
			INNER JOIN  %table:ABS% ABS ON ( ABS.ABS_CODIGO||ABS.ABS_LOJA BETWEEN %Exp:cCliDe% AND %Exp:ccliAte% AND 
										ABS.ABS_LOCAL BETWEEN %Exp:MV_PAR09% AND %Exp:MV_PAR10% AND 
										ABS_LOCAL = TFF.TFF_LOCAL AND 
										ABS_FILIAL =  %xfilial:ABS% AND 
										ABS.%notDel% ) 
			INNER JOIN %table:AA1% AA1 ON AA1_CODTEC = X.ATEND AND AA1.%notDel% AND AA1_FILIAL =  %xfilial:AA1%
			LEFT JOIN %table:SRA% SRA ON RA_MAT = AA1_CDFUNC  AND RA_FILIAL =  AA1_FUNFIL AND SRA.%notDel%
			ORDER BY FILIAL, ATEND
		EndSql
	END REPORT QUERY oSection0

	BeginSql alias "TMP"
	
		SELECT %exp:cCposQry% 
		
		FROM %table:ABB% ABB
			INNER JOIN %table:ABS% ABS ON ABS_LOCAL = ABB_LOCAL AND ABS_FILIAL =  %xfilial:ABS% AND ABS.%notDel%  
			INNER JOIN %table:ABQ% ABQ ON ABB_IDCFAL = ABQ_CONTRT||ABQ_ITEM||ABQ_ORIGEM AND ABQ_FILIAL =  %xfilial:ABQ% AND ABQ.%notDel% 
			INNER JOIN %table:AA1% AA1 ON AA1_CODTEC = ABB_CODTEC AND AA1.%notDel% AND AA1_FILIAL =  %xfilial:AA1%
			LEFT JOIN (SELECT ABN.ABN_DESC, ABN.ABN_TIPO, ABR.ABR_CODSUB, ABR.ABR_MOTIVO, ABR.ABR_DTMAN, ABR.ABR_TEMPO, ABR.ABR_AGENDA FROM
			 						%table:ABN% ABN, %table:ABR% ABR WHERE 
			 							ABR_FILIAL =  %xfilial:ABR% AND ABR.%notDel% 
			 							AND ABN_FILIAL = %xfilial:ABN% AND ABN.%notDel%
			 							AND ABN_CODIGO = ABR_MOTIVO)  Z 
			 								ON (Z.ABR_AGENDA = ABB_CODIGO)
			 							 
			LEFT JOIN %table:SRA% SRA ON RA_MAT = AA1_CDFUNC  AND SRA.%notDel% AND RA_FILIAL =  %xfilial:SRA%
			INNER JOIN %table:TDV% TDV ON (TDV.TDV_FILIAL = %xFilial:TDV% AND TDV.TDV_CODABB = ABB.ABB_CODIGO AND 
											TDV.TDV_DTREF BETWEEN %Exp:MV_PAR01% AND %Exp:MV_PAR02% AND TDV.%NotDel%) 
		WHERE   		
			ABB_FILIAL =  %xfilial:ABB% 
			AND ABB.%notDel% 
			AND ABB.ABB_LOCAL BETWEEN %Exp:MV_PAR09% AND %Exp:MV_PAR10%
			AND ABB.ABB_CODTEC BETWEEN %Exp:MV_PAR03% AND %Exp:MV_PAR04%
			AND ABS.ABS_CODIGO||ABS.ABS_LOJA BETWEEN %Exp:cCliDe% AND %Exp:ccliAte%
		ORDER BY ABB_CODTEC, TDV_DTREF, ABB_DTINI, ABB_HRINI

	EndSql


	//Criação das tabelas temporárias do Relatório
	oTempTable := FWTemporaryTable():New( "QRY", aFields )	
	oTempTable:AddIndex("1", { "ABB_CODTEC", "TDV_DTREF", "ABB_DTINI", "ABB_HRINI"} )
	oTempTable:Create()

	oTemptabl2 := At920CrTb("QRY2", nTam2)
	
	//Copia a tabela da query de agenda para tabela temporária
	//If !TMP->(Eof())
	DBTblCopy( "TMP", "QRY" )
	//EndIf
	
	QRY->(DbSetOrder(1))
	TMP->(DbCloseArea())
	
	//Realiza a query de atendentes
	While QRY3->( !Eof())
		
		At920InEv("QRY2", QRY3->ATEND, MV_PAR01, MV_PAR02, QRY3->AA1_FUNFIL, QRY3->AA1_CDFUNC, QRY3->RA_DEMISSA ,aTpAfast) //.AND. !QRY->(DbSeek(QRY3->ATEND))
		QRY3->(DbSkip(1))
	EndDo
	QRY2->(DbSetOrder(1))
	QRY2->(DbGotop())
	
	QRY3->(DbGoTop())

	//Define tamanho da Regua
	oReport:SetMeter(QRY3->(RecCount()))
	
	QRY->(DbGoTop())
	oSection1:SetParentQuery(.f.)
	oSection1:SetRelation({|| QRY3->ATEND }, "QRY" ,1,.T.)
	oSection1:SetParentFilter({|cParam| QRY->ABB_CODTEC == cParam },{|| QRY3->ATEND })
	
	oSection2:SetParentQuery(.F.)
	oSection2:SetRelation({|| QRY3->ATEND }, "QRY2" ,1,.T.)
	oSection2:SetParentFilter({|cParam| QRY2->CODTEC == cParam },{|| QRY3->ATEND })	
	

	oSection0:Print()
	QRY->(DbCloseArea())
	QRY2->(DbCloseArea())
	If Valtype(oTempTable) <> NIL
		oTempTable:Delete() 
		FreeObj(oTempTable)
	EndIf

	If Valtype(oTempTabl2) <> NIL
		oTempTabl2:Delete() 
		FreeObj(oTempTabl2)
	EndIf

Return

//-------------------------------------------------------------------------------------
/*/{Protheus.doc} At920CrTb
Cria a estrutura da tabela de Eventos do RH
@author serviços
@since 15/05/2019
@version P12.1.25
@param - cTblAlias - Alias da Tabela QRY2
		nTam2 - Tamanho do campo Tipo de Afastamento  - Evento de RH
@return  oTempTable  - Objeto tabela
/*/
//-------------------------------------------------------------------------------------
Static Function At920CrTb( cTblAlias, nTam2)
	Local oTempTable 	:= NIL
	Local aFields 		:= {}
	Local nTam 			:= Len(DtoC(Date())) //Tamanho do campo Data
	
	
	aadd(aFields,{"CODTEC","C", GETSX3CACHE("ABB_CODTEC", "X3_TAMANHO"),0})
	aadd(aFields,{"DATAINI","D", nTam,0})
	aadd(aFields,{"DATAFIM","D", nTam,0})
	aadd(aFields,{"EVENTO","C", nTam2,0})


	oTempTable := FWTemporaryTable():New( cTblAlias, aFields )	
	oTempTable:AddIndex("1", { "CODTEC", "DATAINI", "DATAFIM", "EVENTO"} )
	oTempTable:Create()

Return oTempTable 

//-------------------------------------------------------------------------------------
/*/{Protheus.doc} At920InEv
Insere na tabela os eventos de RH
@since 15/05/2019
@version P12.1.25
@param 	cAlias - Tabela temporária aonde serão inseridos os afastamentos
		cCodTec - Atendente
		dDataDe - Data Inicial do Relatório
		dDataAte - Data Final do Relatório
		cFilFun - Filial do Funcionário
		cMatric - Matrícula do Funcionário
		dDtDeslig - Data de Desligamento
		aTpAfast - Array contendo o tipo do dia de Afastamento
@return  lRet // tem afastamento?
/*/
//-------------------------------------------------------------------------------------
Static Function At920InEv(	cAlias, 	cCodTec, 	dDataDe, 	dDataAte, ;
							cFilFun, 	cMatric, 	dDtDeslig ,	aTpAfast)
Local aPeriodos 	:= {} //Retorno dos Períodos de Afastamento
Local nC 			:= 0 //Contador
Local lRet			:= .F.
	
//Verifica se atendente afastado
If (lRet	:=  At570ChkAf(cFilFun, cMatric, dDataDe, dDataAte, .T., @aPeriodos))
	For nC := 1 to len(aPeriodos)
		RecLock(cAlias, .T.)
		(cAlias)->CODTEC := cCodTec
		(cAlias)->DATAINI := StoD(aPeriodos[nC][01])
		(cAlias)->DATAFIM := StoD(aPeriodos[nC][02])
		(cAlias)->EVENTO  := aTpAfast[01]
		(cAlias)->(MsUnLock())		
	Next nC
EndIf

//Retorna o período de férias do funcionário
 aPeriodos := At920FerChk(cFilFun, cMatric, dDataDe, dDataAte)


	For nC := 1 to Len(aPeriodos)
		RecLock(cAlias, .T.)
		(cAlias)->CODTEC := cCodTec
		(cAlias)->DATAINI := aPeriodos[nC][01]
		(cAlias)->DATAFIM := aPeriodos[nC][02]
		(cAlias)->EVENTO  := aTpAfast[02]
		(cAlias)->(MsUnLock())		
	Next nC
	lRet := lRet .OR. nC > 1
	
//Verifica se o funcionário está demitido
If At570ChkDm(cFilFun, cMatric, dDataDe, dDataAte) 
	RecLock(cAlias, .T.)
	(cAlias)->CODTEC := cCodTec
	(cAlias)->DATAINI := dDtDeslig
	(cAlias)->EVENTO  := aTpAfast[03]
	(cAlias)->(MsUnLock())
	lRet := .T.
	
EndIf

Return lRet

//-------------------------------------------------------------------------------------
/*/{Protheus.doc} At920DiaTr
Retorna se o dia é trabalhado ou não
@author serviços
@since 15/05/2019
@version P12.1.25
@param 	cAlias - Tabela temporária aonde serão inseridos os afastamentos
		cCodTecAnt - Atendente Processado Anteriormente
		dDataAnt - Data Anterior
		dData - Data Atual
		cCodTec - Atendente Atual
		cTipoDia - Tipo da Manutenção do dia
@return  nDia - 0 - Dia já computado como trabalhado, 1 - Dia não computado como trabalhado
/*/
//-------------------------------------------------------------------------------------
Static Function At920DiaTr(cCodTecAnt, dDataAnt, dData, cCodTec, ;
							cTipoDia)
Local nDia := 0 //Dia Trabalhado contabiliado

If !(cTipoDia $ '01#05')
	If cCodTecAnt == cCodTec
		If dDataAnt != dData
			nDia := 1
			dDataAnt := dData
		EndIf
 	Else							 
 		nDia := 1 
 		cCodTecAnt := cCodTec 
 		dDataAnt := dData
 	EndIf
EndIf

Return nDia


//-------------------------------------------------------------------------------------
/*/{Protheus.doc} At920CrTb
Retorna as férias programadas no período
@author serviços
@since 15/05/2019
@version P12.1.25
@param - cFilFun - Filial do Funcionário
		cMat - Matrícula do Funcionário
		dDataIni - Data Inicial de Férias
		dDataFim - Data Final de Férias
@return  aFerias  - Array com o dia de Férias
/*/
//-------------------------------------------------------------------------------------

Static Function At920FerChk(cFilFun, cMat, dDataIni, dDataFim)
	Local aArea := GetArea()
	Local cAliasSRF := GetNextAlias() 
	Local aFerias := {}
		
	BeginSQL alias cAliasSRF
	    Column RF_DATAINI As Date
	    Column RF_DATINI2 As Date
	    Column RF_DATINI3 As Date
	    
		SELECT 	
			SRF.RF_DATAINI, 
			SRF.RF_DFEPRO1,
			SRF.RF_DATINI2,
			SRF.RF_DFEPRO2,
			SRF.RF_DATINI3,
			SRF.RF_DFEPRO3
			
 		FROM %table:SRF% SRF 
 		WHERE 
			SRF.%notDel%
 			AND SRF.RF_FILIAL = %exp:cFilFun% 				
 			AND SRF.RF_MAT = %exp:cMat%
 			AND ( 	
 					(
 						%exp:dDataIni% >= SRF.RF_DATAINI OR
						%exp:dDataFim% <= SRF.RF_DATAINI 				
					) OR (					
						%exp:dDataIni% >= SRF.RF_DATINI2 OR	
						%exp:dDataFim% <= SRF.RF_DATINI2  					
					) OR ( 	
						%exp:dDataIni% >= SRF.RF_DATINI3 OR
						%exp:dDataFim% <= SRF.RF_DATINI3 
 					)
 				) 	 			
	EndSQL	

	While (cAliasSRF)->(!Eof())
	
		If !Empty((cAliasSRF)->RF_DATAINI) .AND.;
			dDataIni >= (cAliasSRF)->RF_DATAINI .AND. dDataIni <= ( (cAliasSRF)->RF_DATAINI + (cAliasSRF)->RF_DFEPRO1-1 ) .OR.;
			dDataFim >= (cAliasSRF)->RF_DATAINI .AND. dDataFim <= ( (cAliasSRF)->RF_DATAINI + (cAliasSRF)->RF_DFEPRO1-1 ) .OR.;
			dDataIni <= (cAliasSRF)->RF_DATAINI .AND. dDataFim >= ( (cAliasSRF)->RF_DATAINI + (cAliasSRF)->RF_DFEPRO1-1 )
			
			aAdd(aFerias, {(cAliasSRF)->RF_DATAINI ,(cAliasSRF)->RF_DATAINI + (cAliasSRF)->RF_DFEPRO1-1 } )
								
		ElseIf  !Empty((cAliasSRF)->RF_DATINI2) .AND.;
			dDataIni >= (cAliasSRF)->RF_DATINI2 .AND. dDataIni <= ( (cAliasSRF)->RF_DATINI2 + (cAliasSRF)->RF_DFEPRO2-1) .OR.;
			dDataFim >= (cAliasSRF)->RF_DATINI2 .AND. dDataFim <= ( (cAliasSRF)->RF_DATINI2 + (cAliasSRF)->RF_DFEPRO2-1) .OR.;
			dDataIni <= (cAliasSRF)->RF_DATINI2 .AND. dDataFim >= ( (cAliasSRF)->RF_DATINI2 + (cAliasSRF)->RF_DFEPRO2-1)
			
			aAdd(aFerias, {(cAliasSRF)->RF_DATINI2 ,(cAliasSRF)->RF_DATINI2 + (cAliasSRF)->RF_DFEPRO2-1 })
						
		ElseIf  !Empty((cAliasSRF)->RF_DATINI3) .AND.;
			dDataIni >= (cAliasSRF)->RF_DATINI3 .AND. dDataIni <= ( (cAliasSRF)->RF_DATINI3 + (cAliasSRF)->RF_DFEPRO3-1) .OR.;
			dDataFim >= (cAliasSRF)->RF_DATINI3 .AND. dDataFim <= ( (cAliasSRF)->RF_DATINI3 + (cAliasSRF)->RF_DFEPRO3-1) .OR.;
			dDataIni <= (cAliasSRF)->RF_DATINI3 .AND. dDataFim >= ( (cAliasSRF)->RF_DATINI3 + (cAliasSRF)->RF_DFEPRO3-1)
			
			aAdd(aFerias, {(cAliasSRF)->RF_DATINI2 ,(cAliasSRF)->RF_DATINI3 + (cAliasSRF)->RF_DFEPRO3-1 })
						
		EndIf

		(cAliasSRF)->(DbSkip())
	EndDo

	(cAliasSRF)->(DbCloseArea())
			
	RestArea(aArea)		

Return aFerias
