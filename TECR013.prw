#include 'protheus.ch'
#include 'parmtype.ch'

Static cPerg := "TECR013"

Function TECR013()
	U_TECR013()
Return

//-------------------------------------------------------------------------------------
/*/{Protheus.doc} PrintReport

@author  Matheus Lando Raimundo
@version P12
@since 	 16/02/2017
@return 
/*/
//-------------------------------------------------------------------------------------
user function TECR013()
	Local oReport
        
	If TRepInUse() 
		Pergunte(cPerg,.F.)	
		oReport := RepInit() 
		oReport:SetLandScape()
		oReport:PrintDialog()	
	EndIf
	
return

//-------------------------------------------------------------------------------------
/*/{Protheus.doc} RepInit
Função responsavel por elaborar o layout do relatorio a ser impresso

@version P12
/*/
//-------------------------------------------------------------------------------------
Static Function RepInit()
Local oReport
Local oSection1
Local oSection2		
Local oBreak1	:= Nil
Local oBreak2	:= Nil
Local cPict := PesqPict("ABX","ABX_VLMEDI")
Local aTamTot := TamSx3("ABX_VLMEDI")
Local nTam	:= aTamTot[1]



oReport := TReport():New("TECR013","Faturamento Antecipado",cPerg,{|oReport| PrintReport(oReport)},"Faturamento Antecipado")
oSection1 := TRSection():New(oReport	,"Competencia",{"ABX"},,,,,,,.T.)	
oSection2 := TRSection():New(oSection1	,"Faturamento" ,{"TFJ","ABX"},,,,,,,.T.)


/*[ <oSection> := ] TRSection():New(<oParent>, [ <cTitle> ], [ \{<cTable>\} ], [ <aOrder> ] ,;
							 [ <.lLoadCells.> ], 6, [ <cTotalText> ], [ !<.lTotalInCol.> ], [ <.lHeaderPage.> ],;
							 [ <.lHeaderBreak.> ], [ <.lPageBreak.> ], [ <.lLineBreak.> ], [ <nLeftMargin> ],;
							 [ <.lLineStyle.> ], [ <nColSpace> ], [<.lAutoSize.>], [<cSeparator>],;
							 [ <nLinesBefore> ], [ <nCols> ], [ <nClrBack> ], [ <nClrFore> ])
							 */

TRCell():New(oSection1,"ABX_MESANO"		,"ABX"	,"Competencia")
TRCell():New(oSection2,"ABX_CONTRT"		,"ABX"	,"Contrato")
TRCell():New(oSection2,"ABX_CONREV"		,"ABX"	,"Revisao")
TRCell():New(oSection2,"ABX_CODPLA"		,"ABX"	,"Nr Planilha")
TRCell():New(oSection2,"ABX_VLORMD"		,"ABX"	,"Vlr Md. Ant.")
TRCell():New(oSection2,"ABX_DIFANT"		,"ABX"	,"Dif. Ap. Mes Ant.")
TRCell():New(oSection2,"ABX_VLTOT"		,""	,"Vlr Total",cPict,nTam,,,"RIGHT",,"RIGHT")	
TRCell():New(oSection2,"ABX_PEDMD"		,"ABX"	,"Ped Medicao")
TRCell():New(oSection2,"ABX_NOTAMD"		,""	,"NF Medicao")
TRCell():New(oSection2,"ABX_SERIEMD"	,""	,"Serie Medicao")
TRCell():New(oSection2,"ABX_PEDAPU"		,""	,"Pedido Apuracao")
TRCell():New(oSection2,"ABX_NOTAAPU"	,""	,"NF Apuracao")
TRCell():New(oSection2,"ABX_SERIEAPU"	,""	,"Serie Apuracao")

oBreak1 := TRBreak():New( oSection1,{|| QRY_COM->ABX_MESANO} )
oBreak2 := TRBreak():New( oSection2,{|| QRY_COM->ABX_MESANO} )

Return oReport


//-------------------------------------------------------------------------------------
/*/{Protheus.doc} PrintReport

@author  Matheus Lando Raimundo
@version P12
@since 	 16/02/2017
@return 
/*/
//-------------------------------------------------/------------------------------------
Static Function PrintReport(oReport)
Local oSection1 := oReport:Section(1)
Local oSection2 := oReport:Section(1):Section(1)
Local cCodOrc	:= ""
Local cCodLocal	:= ""
Local cPict     := PesqPict("TFL","TFL_TOTRH")	
Local nVlDif	:= 0
Local nQtd		:= 0		
Local cItem		:= ""
Local nTotal	:= 0	
Local nVlrUnit  := 0	
Local cContrDe	:= MV_PAR01
Local cContrAte	:= MV_PAR02
Local cCompDe   := MV_PAR03     
Local cCompAte  := MV_PAR04
	
		
//Busca os dados da Secao principal
oSection1:BeginQuery()
BeginSql alias "QRY_COM"			 		 				
	SELECT  ABX_PRIMED, ABX_MESANO, ABX_CONTRT, ABX_CODPLA, ABX_CONREV,ABX_VLORMD,ABX_VLORMD - ABX_VLMEDI ABX_DIFANT,
		C5.C5_NUM ABX_PEDMD, C5.C5_NOTA ABX_NOTAMD, C5.C5_SERIE ABX_SERIEMD,
		CASE 
			WHEN ABX_CODTFV <> '' THEN ABX_PEDIDO
			ELSE ''
		END	ABX_PEDAPU, 
		D2.D2_DOC ABX_NOTAAPU, D2.D2_SERIE ABX_SERIEAPU	
	FROM %table:ABX% ABX
		LEFT JOIN %table:SD2% D2 ON D2.D2_FILIAL = %xfilial:SD2% AND D2.%notDel% AND ABX_CODTFV <> '' AND D2.D2_PEDIDO = ABX_PEDIDO AND D2.D2_ITEMPV = ABX_PEDITE
		LEFT JOIN %table:SC5% C5 ON C5.C5_FILIAL = %xfilial:SC5% AND C5.%notDel% AND ABX.ABX_NUMMED <> '' AND C5_MDCONTR = ABX.ABX_CONTRT AND C5_MDNUMED = ABX.ABX_NUMMED
													AND C5_MDPLANI = ABX.ABX_CODPLA

	WHERE ABX_FILIAL = 	%xfilial:ABX%
	AND ABX.%notDel% 
	AND ABX.ABX_CONTRT BETWEEN %Exp:cContrDe% AND %Exp:cContrAte%
	AND ABX.ABX_MESANO BETWEEN %Exp:cCompDe% AND %Exp:cCompAte%
	AND ABX.ABX_CODPLA <> ''
	ORDER BY ABX_MESANO, ABX_CONTRT
EndSql

oSection1:EndQuery()
oSection1:SetParentQuery(.F.)
	
oSection1:Init()
While QRY_COM->(!Eof())
	
 	cCompet := QRY_COM->(ABX_MESANO)
 	oSection1:PrintLine()
 	
 	oSection2:SetParentQuery(.F.)				
 	oSection2:Init()
 	While cCompet == QRY_COM->(ABX_MESANO)	 		 				
		oSection2:Cell("ABX_CONTRT"):SetBlock( {||QRY_COM->(ABX_CONTRT) } )
		oSection2:Cell("ABX_CONREV"):SetBlock( {||QRY_COM->(ABX_CONREV) } )
		oSection2:Cell("ABX_CODPLA"):SetBlock( {||QRY_COM->(ABX_CODPLA) } )
		oSection2:Cell("ABX_VLORMD"):SetBlock( {||QRY_COM->(ABX_VLORMD) } )
		oSection2:Cell("ABX_DIFANT"):SetBlock( {||QRY_COM->(ABX_DIFANT) } )
		
		If QRY_COM->(ABX_PRIMED)
			oSection2:Cell("ABX_VLTOT"):SetBlock( {|| (QRY_COM->(ABX_VLORMD) - QRY_COM->(ABX_DIFANT)) } )
		Else
			oSection2:Cell("ABX_VLTOT"):SetBlock( {|| Iif ( QRY_COM->(ABX_DIFANT) > 0 , QRY_COM->(ABX_VLORMD) - QRY_COM->(ABX_DIFANT) , 0 ) } )		
		Endif

		oSection2:Cell("ABX_PEDMD"):SetBlock( {||QRY_COM->(ABX_PEDMD) } )
		oSection2:Cell("ABX_NOTAMD"):SetBlock( {||QRY_COM->(ABX_NOTAMD) } )
		oSection2:Cell("ABX_SERIEMD"):SetBlock( {||QRY_COM->(ABX_SERIEMD) } )
		oSection2:Cell("ABX_PEDAPU"):SetBlock( {||QRY_COM->(ABX_PEDAPU) } )
		oSection2:Cell("ABX_NOTAAPU"):SetBlock( {||QRY_COM->(ABX_NOTAAPU) } )
		oSection2:Cell("ABX_SERIEAPU"):SetBlock( {||QRY_COM->(ABX_SERIEAPU) } )
		oSection2:PrintLine()		
		QRY_COM->(dbSkip())			
	EndDo						
EndDo	
Return