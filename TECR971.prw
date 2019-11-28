#include "Rwmake.ch"
#include "Protheus.ch"
#Include 'TOPCONN.ch'
#INCLUDE "REPORT.CH"
#INCLUDE "TECR971.CH"

//-------------------------------------------------------------------
/*/{Protheus.doc} TECR971
Imprime o "Relatório Ocorrências"
@since 13/06/2019
@version P12.1.25
@return  oReport - Objeto TRport
/*/
//-------------------------------------------------------------------------------------
Function TECR971()
	local oReport          
	Local cPerg	:= "TECR971"
 	
 	If !Pergunte(cPerg,.T.)
		Return
	EndIf   
	
	oReport := ReportDef(cPerg)
	oReport:PrintDialog()

Return

//-------------------------------------------------------------------------------------
/*/{Protheus.doc} reportDef
Monta as definiçoes do "Relatório Ocorrências"
@since 13/06/2019
@version P12.1.25
@param cPerg - Pergunta do relatório
@return  oReport - Objeto TRport
/*/
//-------------------------------------------------------------------------------------
Static Function ReportDef(cPerg)
	Local cTitulo 		:= STR0001 //"Relatório Ocorrências"
	Local oSection0 	:= NIL
	Local oSection1 	:= NIL
	Local oBreak0		:= NIL
	Local nTam 			:= TamSx3("TE4_DTOCOR")[1]
	Local nTamEve := Max(TamSx3("TIT_TEXTO1")[1]+Tamsx3("TIT_TEXTO2")[1],TamSx3("TE4_DESCRI")[1])
	
	oReport := TReport():New(cPerg, cTitulo, cPerg , {|oReport| PrintReport(oReport)},STR0001)  //"Relatório Ocorrências"

	DEFINE SECTION oSection0 OF oReport TITLE STR0001  TABLES "QRY", "AA1", "SRA" //"Relatório Ocorrências"

	oBreak0 = TRBreak():New( oSection0 , {|| QRY->AA1_CODTEC },""  , .F. , "" , .F. )  
 
 		DEFINE CELL NAME "AA1_CODTEC"	OF oSection0 ALIAS "QRY" 
		DEFINE CELL NAME "AA1_NOMTEC"	OF oSection0 ALIAS "QRY"
		DEFINE CELL NAME "RA_ADMISSA"	OF oSection0 ALIAS "QRY"
 		TRPosition():New(oSection0 , "AA1" , 1 , { || xFilial("AA1")+QRY->AA1_CODTEC} , .T. ) 	
        TRPosition():New(oSection0 , "SRA" , 1 , { || QRY->(AA1_FUNFIL+AA1_CDFUNC) },.T. ) 
	
	DEFINE SECTION oSection1 OF oSection0 TITLE STR0002 TABLE "QRY" LEFT MARGIN 5 //"Ocorrências do Funcionário"
 
 		TRCell():New( oSection1 , "DATA" , "QRY" , STR0003 , /*<cPicture>*/ , 10 , /*<lPixel>*/ , /*<bBlock>*/ , /*<cAlign>*/ , /*<lLineBreak>*/ , /*<cHeaderAlign>*/ , /*<lCellBreak>*/ , /*<nColSpace>*/ , /*<lAutoSize>*/ , /*<nClrBack>*/ , /*<nClrFore>*/ , /*<lBold>*/ )  //"Data Orcorr"
 		TRCell():New( oSection1 , "TIS_DESCRI" , "QRY" , STR0004 , /*<cPicture>*/ ,  , /*<lPixel>*/ , {|| QRY->(IIF(!Empty(TIS_DESCRI), TIS_DESCRI, IIF(ALIAS == "TIT", STR0006, STR0005))) }, /*<cAlign>*/ , /*<lLineBreak>*/ , /*<cHeaderAlign>*/ , /*<lCellBreak>*/ , /*<nColSpace>*/ , /*<lAutoSize>*/ , /*<nClrBack>*/ , /*<nClrFore>*/ , /*<lBold>*/ )  //"Motivo" //"Ocorrência" //"Disciplina"
 		TRCell():New( oSection1 , "TIT_TEXTO1" , "QRY" ,STR0005  , /*<cPicture>*/ , 40, /*<lPixel>*/ , {|| IIF(QRY->ALIAS == "TE4", TE4->TE4_DESCRI,  TIT->(TIT_TEXTO1 + TIT_TEXTO2))}, /*<cAlign>*/ ,.T. /*<lLineBreak>*/ , /*<cHeaderAlign>*/ , /*<lCellBreak>*/ , /*<nColSpace>*/ , /*<lAutoSize>*/ , /*<nClrBack>*/ , /*<nClrFore>*/ , /*<lBold>*/ )   //"Ocorrência"
 		TRCell():New( oSection1 , "TIT_PONTOS" , "QRY" ,  , /*<cPicture>*/ , , /*<lPixel>*/ , {||  QRY->PONTOS }, /*<cAlign>*/ ,  /*<lLineBreak>*/ , /*<cHeaderAlign>*/ , /*<lCellBreak>*/ , /*<nColSpace>*/ , /*<lAutoSize>*/ , /*<nClrBack>*/ , /*<nClrFore>*/ , /*<lBold>*/ ) 
 		TRCell():New( oSection1 , "TIT_DESCRI" , "QRY" , STR0007 , /*<cPicture>*/ ,  40, /*<lPixel>*/ , {|| iif(QRY->ALIAS = "TIT", TIT->TIT_DESCRI, "") }, /*<cAlign>*/ , .T., /*<cHeaderAlign>*/ , /*<lCellBreak>*/ , /*<nColSpace>*/ , /*<lAutoSize>*/ , /*<nClrBack>*/ , /*<nClrFore>*/ , /*<lBold>*/ )  //"Punição"
 		TRCell():New( oSection1 , "DTINI_AFAS" , "QRY" , STR0008 , /*<cPicture>*/ ,10  , /*<lPixel>*/ , {||  AT971PerAf(oSection1) }, /*<cAlign>*/ , .T., /*<cHeaderAlign>*/ , /*<lCellBreak>*/ , /*<nColSpace>*/ , /*<lAutoSize>*/ , /*<nClrBack>*/ , /*<nClrFore>*/ , /*<lBold>*/ )  //"Ini Afastam"
 		TRCell():New( oSection1 , "DTFIN_AFAS" , "QRY" , STR0009 , /*<cPicture>*/ ,10  , /*<lPixel>*/ , {||  }, /*<cAlign>*/ , .T., /*<cHeaderAlign>*/ , /*<lCellBreak>*/ , /*<nColSpace>*/ , /*<lAutoSize>*/ , /*<nClrBack>*/ , /*<nClrFore>*/ , /*<lBold>*/ )  //"Fim Afastam"
 		TRPosition():New(oSection1 , "TE4" , 1 , { ||  QRY->(FILIAL + TE4_COD) }, .T.) 
 		TRPosition():New(oSection1 , "TIT" , 1 , { || QRY->(FILIAL + TIT_CODIGO) } , .T. ) 	

Return (oReport)


//-------------------------------------------------------------------------------------
/*/{Protheus.doc} PrintReport
Imprime o "Relatório Ocorrências"
@author serviços
@since 13/06/2019
@version P12.1.25
@param - oRepot - Objeto TReport
@return  Nil
/*/
//-------------------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection0 	:= oReport:Section(1)
	Local oSection1 	:= oSection0:Section(1) 
	Local cTamTE4Cod    :=  Space(TamSX3("TE4_COD")[1])
	Local cTamTITCod    :=  Space(TamSX3("TIT_CODIGO")[1])
	
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
 	//³ PARAMETROS                                                             ³
 	//³ MV_PAR01 : Atendente de ?                                              ³
 	//³ MV_PAR02 : Atendente ate ?                                             ³
 	//³ MV_PAR03 : Data de ?                                                   ³
 	//³ MV_PAR04 : Data ate?                                                   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ 
	
	
	BEGIN REPORT QUERY oSection0
		
		BeginSql alias "QRY"
			COLUMN DATA AS DATE
			SELECT
			X.FILIAL,
			X.TE4_COD,
			X.TIT_CODIGO,
			X.DATA, 
			X.TIT_CODTIS,
			X.PONTOS,
			X.AFASTA,
			X.QTDDIA,
			X.ALIAS,
			AA1_CODTEC,
			AA1_CDFUNC,
			AA1_FUNFIL,
			AA1_NOMTEC,
			TIS_DESCRI,
			SRA.RA_ADMISSA
			FROM
			(
				SELECT TE4_DTOCOR AS DATA, 
				TE4.TE4_FILIAL AS FILIAL,
				TE4.TE4_COD ,
				%exp:cTamTITCod% AS TIT_CODIGO,
				TE4_CODTIX AS TIT_CODTIS,
				TE5_ATEND AS CODTEC ,
				0 AS PONTOS,
				'2' AS AFASTA,
				0 AS QTDDIA,
				'TE4' AS ALIAS				
				From 
					%table:TE4% TE4, 
					%table:TE5%  TE5
				WHERE 
					TE4_TPOCOR = '2' AND
					TE5_ATEND BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%  AND
					TE4_DTOCOR BETWEEN %exp:MV_PAR03%  AND %exp:MV_PAR04% AND
					TE5_CDOCOR = TE4_COD AND 
					TE4_FILIAL = %xfilial:TE4% AND  TE4.%notDel% AND 
					TE5_FILIAL = %xfilial:TE5% AND  TE5.%notDel% 
				UNION 
				SELECT 
				TIT_DATA AS DATA, 
				TIT_FILIAL AS FILIAL,
				%exp:cTamTE4Cod% AS TE4_COD ,
				TIT_CODIGO,
				TIT_CODTIS AS TIT_CODTIS,
				TIT_CODTEC AS CODTEC,
				TIT_PONTOS AS PONTOS,
				TIT_AFASTA AS AFASTA,
				TIT_QTDDIA AS QTDDIA,
				'TIT' AS ALIAS
				FROM 
					%table:TIT% TIT
				WHERE 
					TIT_TIPO = '1' AND 
					TIT_CODTEC BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%  AND
					TIT_DATA BETWEEN  %exp:MV_PAR03%  AND %exp:MV_PAR04% AND
					TIT_FILIAL = %xfilial:TIT% AND  TIT.%notDel%
			 )X 
			 LEFT JOIN %table:TIS% TIS ON ( TIS.TIS_CODIGO = X.TIT_CODTIS AND TIS_FILIAL = %xfilial:TIS% AND  TIS.%notDel%  )
			INNER JOIN %table:AA1%  AA1 ON ( X.CODTEC = AA1.AA1_CODTEC AND AA1_FILIAL = %xfilial:AA1% AND AA1.%notDel% )
			LEFT JOIN %table:SRA%  SRA ON ( RA_FILIAL = AA1.AA1_FUNFIL AND RA_MAT = AA1.AA1_CDFUNC AND SRA.%notDel% )
			ORDER BY AA1.AA1_CODTEC, X.DATA
	EndSql

	END REPORT QUERY oSection0	

	oSection1:SetParentFilter({|cParam|  QRY->AA1_CODTEC == cParam },{|| QRY->AA1_CODTEC  })

	oSection0:Print()

Return

//-------------------------------------------------------------------------------------
/*/{Protheus.doc} AT971PerAf
Calcula o período de Afastamento
@author serviços
@since 13/06/2019
@version P12.1.25
@param - oSection1 - Seção do relatorio
@return  Nil
/*/
//-------------------------------------------------------------------------------------
Static Function AT971PerAf(oSection1)

Local dDtFinal := Ctod("")
Local dDtInicio := Ctod("")

If QRY->AFASTA = '1' .AND. QRY->QTDDIA > 0 
	
	If ExistFunc("At440RFlt")

		dDtFinal := At440RFlt(.F., QRY->DATA, QRY->AA1_CODTEC, QRY->QTDDIA)
	Else
		dDtFinal := AT971RFlt(QRY->DATA, QRY->AA1_CODTEC, QRY->QTDDIA)
	EndIf
	
	If !Empty(dDtFinal)
		dDtInicio := QRY->DATA
		
	EndIf

EndIf

oSection1:Cell("DTFIN_AFAS"):SetValue(dDtFinal)

Return dDtInicio

//-----------------------------------------------------------------------------
/*/{Protheus.doc} AT971RFlt
AT440Falta  - Atribuição de falta baseado nos parametros código do atendente, data, quantidade de dias

@param   	AT971RFlt	
@owner   	fabiana.silva
@version 	12.1.23
@since   	13/06/2019
/*/
//-----------------------------------------------------------------------------

Static Function AT971RFlt(dDtIni, cFunc, nDias)
Local dFinal 	:= Ctod("")
Local cAlias	:= GetNextAlias()
Local aArea		:= GetArea()
Local nConta	:= 1
Local cDtFim	:= ""

BeginSql alias cAlias 					
	SELECT ABB.ABB_CODTEC, ABB.ABB_DTINI, ABB.ABB_DTFIM
	FROM %table:ABB% ABB
	Where ABB.ABB_CODTEC =  %exp:cFunc%
	AND ABB.ABB_DTINI >= %exp:dDtIni%
	AND ABB.%notDel% 
	GROUP BY ABB.ABB_DTINI, ABB.ABB_DTFIM, ABB.ABB_CODTEC 
EndSql

DbSelectArea(cAlias)

While ( cAlias )->( !Eof() )				
	
	If nConta <= nDias	
		cDtFim := ( cAlias )-> ABB_DTFIM
		
		nConta := nConta + 1
	EndIf
				
	( cAlias )->(DbSkip())		
End

(cAlias)->( DbCloseArea() )

dFinal := SToD(cDtFim)

RestArea(aArea)

Return dFinal