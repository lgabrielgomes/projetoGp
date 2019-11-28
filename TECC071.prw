#INCLUDE "Protheus.ch" 
#INCLUDE "TECC070.ch"
#INCLUDE "Tecc070_Def.ch"

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071CliUrl
Funcao de pesquisa da Central do Cliente que retorna a URL de consulta do cliente
no Google Maps

@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071CliUrl(cCodCli,cLojCli)
	Local cURL 		:= "http://maps.google.com/?q="
	Local cEndCli	:= ""
	Local cNomeCli	:= ""
	Local aArea 	:= GetArea()
	
	dbSelectArea("SA1")
	SA1->(dbSetOrder(1))
	If SA1->(dbSeek(xFilial('SA1')+ Padr(cCodCli,TamSx3("A1_COD")[1]) + Padr(cLojCLi,TamSx3("A1_LOJA")[1])   ))
		cEndCli := " " + alltrim(SA1->A1_END) + " " + alltrim(SA1->A1_MUN) + " " + alltrim(SA1->A1_EST)
		
		//Se nao tiver o cliente, usa o nome do cliente como referencia.
		If Empty(cEndCli) .or. len(cEndCli) < 10 
			cEndCli := " " + alltrim(SA1->A1_NOME)
		EndIf		
	EndIf
	
	//Monta a URL final
	cURL := cUrl + cEndCli
	
	RestArea(aArea)
Return cURL

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071OpNoProp
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Oportunidades sem Proposta"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071OpNoProp(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias()
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"AD1_NROPOR",Nil})
	aAdd(aColumns,{"AD1_REVISA",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aAdd(aColumns,{"AD1_DATA",Nil})
	aAdd(aColumns,{"AD1_HORA",Nil})
	aAdd(aColumns,{"AD1_VEND",Nil})
	aAdd(aColumns,{"AD1_NOMVEN",STR0052})
	aAdd(aColumns,{"AD1_DTINI",Nil})
	aAdd(aColumns,{"AD1_DTFIM",Nil})
	aAdd(aColumns,{"AD1_PROVEN",STR0054})
	aAdd(aColumns,{"AC2_DESCRI",STR0053})
	aAdd(aColumns,{"AD1_PERCEN",Nil})
	aAdd(aColumns,{"AD1_VERBA",Nil})
	aAdd(aColumns,{"AD1_RCREAL",Nil})
	aAdd(aColumns,{"AD1_FEELIN",Nil})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa
	cQuery := "SELECT AD1.AD1_NROPOR , AD1.AD1_REVISA, AD1.AD1_DESCRI,AD1.AD1_DATA,AD1.AD1_HORA, "
	cQuery += " AD1.AD1_VEND, AD1.AD1_DTINI, AD1.AD1_DTFIM, SA3.A3_NOME, AD1.AD1_PROVEN, AC2.AC2_DESCRI, "
	cQuery += " AD1.AD1_STAGE, AD1.AD1_VERBA, AD1.AD1_RCREAL, AD1.AD1_FEELIN FROM "	
	cQuery += RetSqlName('AD1') + " AD1 "
	cQuery += " LEFT JOIN " + RetSqlName('SA3') + " SA3 "
	cQuery += " 	ON SA3.A3_FILIAL = '" + xFilial('SA3') + "' "
	cQuery += "		AND SA3.A3_COD = AD1.AD1_VEND "
	cQuery += " 	AND SA3.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('AC2') + " AC2 "
	cQuery += " 	ON AC2.AC2_FILIAL = '" + xFilial('AC2') + "' "
	cQuery += "		AND AC2.AC2_PROVEN = AD1.AD1_PROVEN "
	cQuery += "		AND AC2.AC2_STAGE = AD1.AD1_STAGE "
	cQuery += " 	AND AC2.D_E_L_E_T_ = ' ' "	
	cQuery += " WHERE AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "	
	cQuery += "		AND AD1.AD1_CODCLI = '" + cCodCli + "' "
	cQuery += "		AND AD1.AD1_LOJCLI = '" + cLojCli + "' "	
	cQuery += "		AND AD1.AD1_VEND = SA3.A3_COD "
	cQuery += " 	AND AD1.AD1_NROPOR NOT IN 
	cQuery += " 		(SELECT ADY.ADY_OPORTU FROM " 
	cQuery += 			RetSqlName('ADY') + " ADY "
	cQuery += " 		WHERE ADY.ADY_FILIAL = AD1.AD1_FILIAL "
	cQuery += " 		AND ADY.ADY_OPORTU = AD1_NROPOR "
	cQuery += " 		AND ADY.D_E_L_E_T_ = ' ') "
	cQuery += "		AND AD1.AD1_STATUS = '1' "
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "
	
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}	
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->AD1_NROPOR,;
						(cAlias)->AD1_REVISA,;
						(cAlias)->AD1_DESCRI,;
						StoD((cAlias)->AD1_DATA),;
						(cAlias)->AD1_HORA,;
						(cAlias)->AD1_VEND,;
						(cAlias)->A3_NOME,;
						StoD((cAlias)->AD1_DTINI),;
						StoD((cAlias)->AD1_DTFIM),;							
						(cAlias)->AD1_PROVEN,;
						(cAlias)->AC2_DESCRI,;
						FT300PERC((cAlias)->AD1_PROVEN,(cAlias)->AD1_STAGE),;
						(cAlias)->AD1_VERBA,;
						(cAlias)->AD1_RCREAL,;
						(cAlias)->AD1_FEELIN,;
						.F.;	//Linha nao deletada
		  				})
		
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071OpAberta
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Oportunidades em Aberto"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071OpAberta(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"AD1_NROPOR",Nil})
	aAdd(aColumns,{"AD1_REVISA",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aAdd(aColumns,{"AD1_DATA",Nil})
	aAdd(aColumns,{"AD1_HORA",Nil})
	aAdd(aColumns,{"AD1_VEND",Nil})
	aAdd(aColumns,{"AD1_NOMVEN",STR0052})
	aAdd(aColumns,{"AD1_DTINI",Nil})
	aAdd(aColumns,{"AD1_DTFIM",Nil})
	aAdd(aColumns,{"AD1_PROVEN",STR0054})
	aAdd(aColumns,{"AC2_DESCRI",STR0053})
	aAdd(aColumns,{"AD1_PERCEN",Nil})
	aAdd(aColumns,{"AD1_VERBA",Nil})
	aAdd(aColumns,{"AD1_RCREAL",Nil})
	aAdd(aColumns,{"AD1_FEELIN",Nil})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa
	cQuery := "SELECT AD1.AD1_NROPOR , AD1.AD1_REVISA, AD1.AD1_DESCRI,AD1.AD1_DATA,AD1.AD1_HORA, "
	cQuery += "AD1.AD1_VEND, AD1.AD1_DTINI, AD1.AD1_DTFIM, SA3.A3_NOME, AD1.AD1_PROVEN, AC2.AC2_DESCRI, ""
	cQuery += " AD1.AD1_STAGE, AD1.AD1_VERBA, AD1.AD1_RCREAL, AD1.AD1_FEELIN FROM "
	cQuery += RetSqlName('AD1') + " AD1 "	
	cQuery += " LEFT JOIN " + RetSqlName('SA3') + " SA3 "
	cQuery += " 	ON SA3.A3_FILIAL = '" + xFilial('SA3') + "' "
	cQuery += "		AND SA3.A3_COD = AD1.AD1_VEND "
	cQuery += " 	AND SA3.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('AC2') + " AC2 "
	cQuery += " 	ON AC2.AC2_FILIAL = '" + xFilial('AC2') + "' "
	cQuery += "		AND AC2.AC2_PROVEN = AD1.AD1_PROVEN "
	cQuery += "		AND AC2.AC2_STAGE = AD1.AD1_STAGE "
	cQuery += " 	AND AC2.D_E_L_E_T_ = ' ' "	
	cQuery += " WHERE AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += "		AND AD1.AD1_CODCLI = '" + cCodCli + "' "
	cQuery += "		AND AD1.AD1_LOJCLI = '" + cLojCli + "' "	
	cQuery += "		AND AD1.AD1_VEND = SA3.A3_COD "
	cQuery += " 	AND AD1.AD1_NROPOR IN ""
	cQuery += " 		(SELECT ADY.ADY_OPORTU FROM " 
	cQuery += 			RetSqlName('ADY') + " ADY "
	cQuery += " 		WHERE ADY.ADY_FILIAL = AD1.AD1_FILIAL "
	cQuery += " 		AND ADY.ADY_OPORTU = AD1_NROPOR "
	cQuery += " 		AND ADY.D_E_L_E_T_ = ' ') "
	cQuery += "		AND AD1.AD1_STATUS = '1' "
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}	
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->AD1_NROPOR,;
						(cAlias)->AD1_REVISA,;
						(cAlias)->AD1_DESCRI,;
						StoD((cAlias)->AD1_DATA),;
						(cAlias)->AD1_HORA,;
						(cAlias)->AD1_VEND,;
						(cAlias)->A3_NOME,;
						StoD((cAlias)->AD1_DTINI),;
						StoD((cAlias)->AD1_DTFIM),;
						(cAlias)->AD1_PROVEN,;
						(cAlias)->AC2_DESCRI,;
						FT300PERC((cAlias)->AD1_PROVEN,(cAlias)->AD1_STAGE),;
						(cAlias)->AD1_VERBA,;
						(cAlias)->AD1_RCREAL,;
						(cAlias)->AD1_FEELIN,;
						.F.;	//Linha nao deletada
		  				})
		
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071OpEncerr
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Oportunidades Encerradas" (SOMENTE GANHAS)
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071OpEncerr(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"AD1_NROPOR",Nil})
	aAdd(aColumns,{"AD1_REVISA",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aAdd(aColumns,{"AD1_DATA",Nil})
	aAdd(aColumns,{"AD1_HORA",Nil})
	aAdd(aColumns,{"AD1_VEND",Nil})
	aAdd(aColumns,{"AD1_NOMVEN",STR0052})
	aAdd(aColumns,{"AD1_DTINI",Nil})
	aAdd(aColumns,{"AD1_DTFIM",Nil})
	aAdd(aColumns,{"AD1_FCS",Nil})
	aAdd(aColumns,{"AD1_DESFCS",Nil})
	aAdd(aColumns,{"AD1_PROVEN",STR0054})
	aAdd(aColumns,{"AC2_DESCRI",STR0053})
	aAdd(aColumns,{"AD1_PERCEN",Nil})
	aAdd(aColumns,{"AD1_VERBA",Nil})
	aAdd(aColumns,{"AD1_RCREAL",Nil})
	aAdd(aColumns,{"AD1_DTASSI",Nil})
	aAdd(aColumns,{"AD1_CNTPRO",Nil})
	aAdd(aColumns,{"AD1_NOMCNT",Nil})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa
	cQuery := "SELECT AD1.AD1_NROPOR , AD1.AD1_REVISA, AD1.AD1_DESCRI,AD1.AD1_DATA,AD1.AD1_HORA, "
	cQuery += "AD1.AD1_VEND, AD1.AD1_DTINI, AD1.AD1_DTFIM, AD1.AD1_FCS, SA3.A3_NOME, SX5.X5_DESCRI, AD1.AD1_PROVEN, AC2.AC2_DESCRI, "
	cQuery += " AD1.AD1_STAGE, AD1.AD1_VERBA, AD1.AD1_RCREAL, AD1.AD1_FEELIN, AD1.AD1_DTASSI, AD1.AD1_CNTPRO,
	cQuery += " SU5.U5_CONTAT FROM "
	cQuery += RetSqlName('AD1') + " AD1 "
	cQuery += " LEFT JOIN " + RetSqlName('SA3') + " SA3 "
	cQuery += " 	ON SA3.A3_FILIAL = '" + xFilial('SA3') + "' "
	cQuery += "		AND SA3.A3_COD = AD1.AD1_VEND "
	cQuery += " 	AND SA3.D_E_L_E_T_ = ' ' "
	cQuery += " LEFT JOIN " + RetSqlName('AC2') + " AC2 "
	cQuery += " 	ON AC2.AC2_FILIAL = '" + xFilial('AC2') + "' "
	cQuery += "		AND AC2.AC2_PROVEN = AD1.AD1_PROVEN "
	cQuery += "		AND AC2.AC2_STAGE = AD1.AD1_STAGE "
	cQuery += " 	AND AC2.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('SX5') + " SX5 "
	cQuery += " 	ON SX5.X5_FILIAL = '" + xFilial('SX5') + "' "
	cQuery += "		AND SX5.X5_TABELA = 'A6'"
	cQuery += "		AND SX5.X5_CHAVE = AD1.AD1_FCS "
	cQuery += " 	AND SX5.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('SU5') + " SU5 "
	cQuery += " 	ON SU5.U5_FILIAL = '" + xFilial('SU5') + "' "
	cQuery += "		AND SU5.U5_CODCONT = AD1.AD1_CNTPRO "
	cQuery += " 	AND SU5.D_E_L_E_T_ = ' ' "
	cQuery += " WHERE AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "	
	cQuery += "		AND AD1.AD1_CODCLI = '" + cCodCli + "' "
	cQuery += "		AND AD1.AD1_LOJCLI = '" + cLojCli + "' "		
	cQuery += " 	AND AD1.AD1_NROPOR IN ""
	cQuery += " 		(SELECT ADY.ADY_OPORTU FROM " 
	cQuery += 			RetSqlName('ADY') + " ADY "
	cQuery += " 		WHERE ADY.ADY_FILIAL = AD1.AD1_FILIAL "
	cQuery += " 		AND ADY.ADY_OPORTU = AD1_NROPOR "
	cQuery += " 		AND ADY.D_E_L_E_T_ = ' ') "
	cQuery += "		AND AD1.AD1_STATUS = '9' "
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "	
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->AD1_NROPOR,;
						(cAlias)->AD1_REVISA,;
						(cAlias)->AD1_DESCRI,;
						StoD((cAlias)->AD1_DATA),;
						(cAlias)->AD1_HORA,;
						(cAlias)->AD1_VEND,;
						(cAlias)->A3_NOME,;
						StoD((cAlias)->AD1_DTINI),;
						StoD((cAlias)->AD1_DTFIM),;
						(cAlias)->AD1_FCS,;
						(cAlias)->X5_DESCRI,;
						(cAlias)->AD1_PROVEN,;
						(cAlias)->AC2_DESCRI,;
						FT300PERC((cAlias)->AD1_PROVEN,(cAlias)->AD1_STAGE),;
						(cAlias)->AD1_VERBA,;
						(cAlias)->AD1_RCREAL,;
						Stod((cAlias)->AD1_DTASSI),;
						(cAlias)->AD1_CNTPRO,;
						(cAlias)->U5_CONTAT,;
						.F.;	//Linha nao deletada
		  				})
		
		(cAlias)->(dbSkip())
	End
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071OpCancel
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Oportunidades Canceladas" (SUSPENSAS OU PERDIDAS)
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071OpCancel(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"AD1_NROPOR",Nil})
	aAdd(aColumns,{"AD1_REVISA",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aAdd(aColumns,{"AD1_DATA",Nil})
	aAdd(aColumns,{"AD1_HORA",Nil})
	aAdd(aColumns,{"AD1_VEND",Nil})
	aAdd(aColumns,{"AD1_NOMVEN",STR0052})
	aAdd(aColumns,{"AD1_DTINI",Nil})
	aAdd(aColumns,{"AD1_DTFIM",Nil})
	aAdd(aColumns,{"AD1_FCI",Nil})
	aAdd(aColumns,{"AD1_DESFCI",Nil})
	aAdd(aColumns,{"AD1_PROVEN",STR0054})
	aAdd(aColumns,{"AC2_DESCRI",STR0053})
	aAdd(aColumns,{"AD1_PERCEN",Nil})
	aAdd(aColumns,{"AD1_VERBA",Nil})
	aAdd(aColumns,{"AD1_RCREAL",Nil})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa
	cQuery := "SELECT AD1.AD1_NROPOR , AD1.AD1_REVISA, AD1.AD1_DESCRI,AD1.AD1_DATA,AD1.AD1_HORA, "
	cQuery += "AD1.AD1_VEND, AD1.AD1_DTINI, AD1.AD1_DTFIM, AD1.AD1_FCI, SA3.A3_NOME, AD1.AD1_PROVEN, AC2.AC2_DESCRI, "
	cQuery += " AD1.AD1_STAGE, SX5.X5_DESCRI, AD1.AD1_VERBA, AD1.AD1_RCREAL, AD1.AD1_FEELIN  FROM "
	cQuery += RetSqlName('AD1') + " AD1 "		
	cQuery += " LEFT JOIN " + RetSqlName('ADY') + " ADY "
	cQuery += " 	ON ADY.ADY_FILIAL = AD1.AD1_FILIAL "
	cQuery += " 	AND ADY.ADY_OPORTU = AD1.AD1_NROPOR "
	cQuery += " 	AND ADY.ADY_REVISA = AD1.AD1_REVISA "
	cQuery += " 	AND ADY.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('SA3') + " SA3 "
	cQuery += " 	ON SA3.A3_FILIAL = '" + xFilial('SA3') + "' "
	cQuery += "		AND SA3.A3_COD = AD1.AD1_VEND "
	cQuery += " 	AND SA3.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('SX5') + " SX5 "
	cQuery += " 	ON SX5.X5_FILIAL = '" + xFilial('SX5') + "' "
	cQuery += "		AND SX5.X5_TABELA = 'A6'"
	cQuery += "		AND SX5.X5_CHAVE = AD1.AD1_FCI "
	cQuery += " 	AND SX5.D_E_L_E_T_ = ' ' "
	cQuery += " LEFT JOIN " + RetSqlName('AC2') + " AC2 "
	cQuery += " 	ON AC2.AC2_FILIAL = '" + xFilial('AC2') + "' "
	cQuery += "		AND AC2.AC2_PROVEN = AD1.AD1_PROVEN "
	cQuery += "		AND AC2.AC2_STAGE = AD1.AD1_STAGE "
	cQuery += " 	AND AC2.D_E_L_E_T_ = ' ' "		
	cQuery += " WHERE AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += "		AND AD1.AD1_CODCLI = '" + cCodCli + "' "
	cQuery += "		AND AD1.AD1_LOJCLI = '" + cLojCli + "' "	
	cQuery += "		AND ( AD1.AD1_STATUS = '2' "
	cQuery += "			OR  AD1.AD1_STATUS = '3') "
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->AD1_NROPOR,;
						(cAlias)->AD1_REVISA,;
						(cAlias)->AD1_DESCRI,;
						StoD((cAlias)->AD1_DATA),;
						(cAlias)->AD1_HORA,;
						(cAlias)->AD1_VEND,;
						(cAlias)->A3_NOME,;
						StoD((cAlias)->AD1_DTINI),;
						StoD((cAlias)->AD1_DTFIM),;
						(cAlias)->AD1_FCI,;
						(cAlias)->X5_DESCRI,;
						(cAlias)->AD1_PROVEN,;
						(cAlias)->AC2_DESCRI,;
						FT300PERC((cAlias)->AD1_PROVEN,(cAlias)->AD1_STAGE),;
						(cAlias)->AD1_VERBA,;
						(cAlias)->AD1_RCREAL,;
						.F.;	//Linha nao deletada
		  				})
		(cAlias)->(dbSkip())
	End
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071PropAb
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Propostas em Aberto"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071PropAb(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"AD1_NROPOR",Nil})
	aAdd(aColumns,{"AD1_REVISA",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"ADY_VISTEC",Nil})
	aAdd(aColumns,{"ADZ_TOTAL",Nil})
	aAdd(aColumns,{"AD1_DATA",Nil})
	aAdd(aColumns,{"AD1_VEND",Nil})
	aAdd(aColumns,{"AD1_NOMVEN",STR0052})
	aAdd(aColumns,{"AD1_PROVEN",STR0054})
	aAdd(aColumns,{"AC2_DESCRI",STR0053})
	aAdd(aColumns,{"AD1_PERCEN",Nil})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa
	cQuery := "SELECT AD1.AD1_NROPOR,AD1.AD1_REVISA,AD1.AD1_DESCRI,ADY.ADY_PROPOS,ADY.ADY_VISTEC, "
	cQuery += " AD1.AD1_VEND,SA3.A3_NOME,AD1.AD1_DATA, " 
	cQuery += "		(SELECT SUM(ADZ.ADZ_TOTAL) FROM "
	cQuery += 		RetSqlName("ADZ") + " ADZ " 
	cQuery += " 	WHERE ADZ.ADZ_FILIAL = ADY.ADY_FILIAL "
	cQuery += " 		AND ADZ.ADZ_PROPOS = ADY.ADY_PROPOS "
	cQuery += " 		AND ADZ.ADZ_REVISA = ADY.ADY_REVISA "
	cQuery += " 		AND ADZ.D_E_L_E_T_ = ' ') TOTAL, "
	cQuery += " AD1.AD1_PROVEN, AC2.AC2_DESCRI, AD1.AD1_STAGE FROM "  
	cQuery += RetSqlName("AD1") + " AD1 " 
	cQuery += " JOIN " + RetSqlName('ADY') + " ADY "
	cQuery += " 	ON ADY.ADY_FILIAL = '" + xFilial('ADY') + "' "
	cQuery += " 	AND ADY.ADY_STATUS = 'A' "
	cQuery += " 	AND ADY.ADY_OPORTU = AD1.AD1_NROPOR "
	cQuery += " 	AND ADY.ADY_REVISA = AD1.AD1_REVISA "
	cQuery += " 	AND ADY.D_E_L_E_T_ = ' ' "
	cQuery += " LEFT JOIN " + RetSqlName('SA3') + " SA3 "
	cQuery += " 	ON SA3.A3_FILIAL = '" + xFilial('SA3') + "' "
	cQuery += "		AND SA3.A3_COD = AD1.AD1_VEND "
	cQuery += " 	AND SA3.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('AC2') + " AC2 "
	cQuery += " 	ON AC2.AC2_FILIAL = '" + xFilial('AC2') + "' "
	cQuery += "		AND AC2.AC2_PROVEN = AD1.AD1_PROVEN "
	cQuery += "		AND AC2.AC2_STAGE = AD1.AD1_STAGE "
	cQuery += " 	AND AC2.D_E_L_E_T_ = ' ' "
	cQuery += " WHERE AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += " 	AND AD1.AD1_CODCLI = '" + cCodCli + "' "
	cQuery += " 	AND AD1.AD1_LOJCLI = '" + cLojCli + "' "	 	
	cQuery += " 	AND AD1.AD1_STATUS = '1' "
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "	
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->AD1_NROPOR,;
						(cAlias)->AD1_REVISA,;
						(cAlias)->AD1_DESCRI,;							
						(cAlias)->ADY_PROPOS,;
						(cAlias)->ADY_VISTEC,;
						(cAlias)->TOTAL,;
						StoD((cAlias)->AD1_DATA),;
						(cAlias)->AD1_VEND,;
						(cAlias)->A3_NOME,;
						(cAlias)->AD1_PROVEN,;
						(cAlias)->AC2_DESCRI,;
						FT300PERC((cAlias)->AD1_PROVEN,(cAlias)->AD1_STAGE),;
						.F.;	//Linha nao deletada
		  				})
		
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071PropEn
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Propostas Encerradas"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071PropEn(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"AD1_NROPOR",Nil})
	aAdd(aColumns,{"AD1_REVISA",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"ADY_VISTEC",Nil})
	aAdd(aColumns,{"ADZ_TOTAL",Nil})
	aAdd(aColumns,{"AD1_DATA",Nil})
	aAdd(aColumns,{"AD1_VEND",Nil})
	aAdd(aColumns,{"AD1_NOMVEN",STR0052})
	aAdd(aColumns,{"AD1_FCS",Nil})
	aAdd(aColumns,{"AD1_DESFCS",Nil})
	aAdd(aColumns,{"AD1_PROVEN",STR0054})
	aAdd(aColumns,{"AC2_DESCRI",STR0053})
	aAdd(aColumns,{"AD1_PERCEN",Nil})
	aAdd(aColumns,{"AD1_DTASSI",Nil})
	aAdd(aColumns,{"AD1_CNTPRO",Nil})
	aAdd(aColumns,{"AD1_NOMCNT",Nil})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa
	cQuery := "SELECT AD1.AD1_NROPOR,AD1.AD1_REVISA,AD1.AD1_DESCRI,ADY.ADY_PROPOS, ADY.ADY_VISTEC, "
	cQuery += " AD1.AD1_VEND,SA3.A3_NOME,AD1.AD1_DATA, AD1.AD1_FCS, SX5.X5_DESCRI, " 
	cQuery += "		(SELECT SUM(ADZ.ADZ_TOTAL) FROM "
	cQuery += 		RetSqlName("ADZ") + " ADZ " 
	cQuery += " 	WHERE ADZ.ADZ_FILIAL = ADY.ADY_FILIAL "
	cQuery += " 		AND ADZ.ADZ_PROPOS = ADY.ADY_PROPOS "
	cQuery += " 		AND ADZ.ADZ_REVISA = ADY.ADY_REVISA "
	cQuery += " 		AND ADZ.D_E_L_E_T_ = ' ') TOTAL, "
	cQuery += " AD1.AD1_PROVEN, AC2.AC2_DESCRI, AD1.AD1_STAGE, AD1.AD1_DTASSI, AD1.AD1_CNTPRO, SU5.U5_CONTAT FROM "  
	cQuery += RetSqlName("AD1") + " AD1 " 
	cQuery += " JOIN " + RetSqlName('ADY') + " ADY "
	cQuery += " 	ON ADY.ADY_FILIAL = '" + xFilial('ADY') + "' "
	cQuery += " 	AND ADY.ADY_STATUS = 'B' "
	cQuery += " 	AND ADY.ADY_OPORTU = AD1.AD1_NROPOR "
	cQuery += " 	AND ADY.ADY_REVISA = AD1.AD1_REVISA "
	cQuery += " 	AND ADY.D_E_L_E_T_ = ' ' "
	cQuery += " LEFT JOIN " + RetSqlName('SA3') + " SA3 "
	cQuery += " 	ON SA3.A3_FILIAL = '" + xFilial('SA3') + "' "
	cQuery += "		AND SA3.A3_COD = AD1.AD1_VEND "
	cQuery += " 	AND SA3.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('AC2') + " AC2 "
	cQuery += " 	ON AC2.AC2_FILIAL = '" + xFilial('AC2') + "' "
	cQuery += "		AND AC2.AC2_PROVEN = AD1.AD1_PROVEN "
	cQuery += "		AND AC2.AC2_STAGE = AD1.AD1_STAGE "
	cQuery += " 	AND AC2.D_E_L_E_T_ = ' ' "
	cQuery += " LEFT JOIN " + RetSqlName('SX5') + " SX5 "
	cQuery += " 	ON SX5.X5_FILIAL = '" + xFilial('SX5') + "' "
	cQuery += "		AND SX5.X5_TABELA = 'A6'"
	cQuery += "		AND SX5.X5_CHAVE = AD1.AD1_FCS "
	cQuery += " 	AND SX5.D_E_L_E_T_ = ' ' "
	cQuery += " LEFT JOIN " + RetSqlName('SU5') + " SU5 "
	cQuery += " 	ON SU5.U5_FILIAL = '" + xFilial('SU5') + "' "
	cQuery += "		AND SU5.U5_CODCONT = AD1.AD1_CNTPRO "
	cQuery += " 	AND SU5.D_E_L_E_T_ = ' ' "
	cQuery += " WHERE AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += " 	AND AD1.AD1_CODCLI = '" + cCodCli + "' "
	cQuery += " 	AND AD1.AD1_LOJCLI = '" + cLojCli + "' "	 	
	cQuery += " 	AND AD1.AD1_STATUS = '9' "
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "	
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->AD1_NROPOR,;
						(cAlias)->AD1_REVISA,;
						(cAlias)->AD1_DESCRI,;							
						(cAlias)->ADY_PROPOS,;
						(cAlias)->ADY_VISTEC,;
						(cAlias)->TOTAL,;
						StoD((cAlias)->AD1_DATA),;
						(cAlias)->AD1_VEND,;
						(cAlias)->A3_NOME,;
						(cAlias)->AD1_FCS,;
						(cAlias)->X5_DESCRI,;
						(cAlias)->AD1_PROVEN,;
						(cAlias)->AC2_DESCRI,;
						FT300PERC((cAlias)->AD1_PROVEN,(cAlias)->AD1_STAGE),;
						Stod((cAlias)->AD1_DTASSI),;
						(cAlias)->AD1_CNTPRO,;
						(cAlias)->U5_CONTAT,;
						.F.;	//Linha nao deletada
		  				})
		
		(cAlias)->(dbSkip())
	End
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071PropVT
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Vistorias Tecnicas"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071PropVT(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"AD1_NROPOR",Nil})
	aAdd(aColumns,{"AD1_REVISA",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AAT_CODVIS",Nil})
	aAdd(aColumns,{"AAT_NOMVIS",Nil})
	aAdd(aColumns,{"AAT_DTINI",Nil})
	aAdd(aColumns,{"AAT_HRINI",Nil})
	aAdd(aColumns,{"AAT_DTFIM",Nil})
	aAdd(aColumns,{"AAT_HRFIM",Nil})
	aAdd(aColumns,{"AAT_CODABT",Nil})
	aAdd(aColumns,{"ABT_DESCRI",Nil})
	aAdd(aColumns,{"AAT_STATUS",Nil})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa
	cQuery := "SELECT AD1.AD1_NROPOR, AD1.AD1_REVISA, AD1.AD1_DESCRI, ADY.ADY_PROPOS, "
	cQuery += " AAT.AAT_CODVIS, AAT.AAT_VISTOR, AA1.AA1_NOMTEC, AAT.AAT_CODABT, ABT.ABT_DESCRI, "
	cQuery += " AAT.AAT_DTINI, AAT.AAT_HRINI, AAT.AAT_DTFIM, AAT.AAT_HRFIM, AAT.AAT_STATUS "	
	cQuery += " FROM " 
	cQuery += RetSqlName("AD1") + " AD1 "
	cQuery += " JOIN " + RetSqlName('ADY') + " ADY "
	cQuery += " 	ON ADY.ADY_FILIAL = '" + xFilial('ADY') + "' "
	cQuery += " 	AND ADY.ADY_OPORTU = AD1.AD1_NROPOR "
	cQuery += " 	AND ADY.ADY_REVISA = AD1.AD1_REVISA "
	cQuery += " 	AND ADY.D_E_L_E_T_ = ' ' "
	cQuery += " JOIN " + RetSqlName('AAT') + " AAT "
	cQuery += "		ON AAT.AAT_FILIAL = '"  + xFilial("AAT") + "' "
	cQuery += " 	AND AAT.AAT_CODVIS = ADY.ADY_CODVIS "
	cQuery += " 	AND AAT.D_E_L_E_T_ = ' ' " 	
	cQuery += " LEFT JOIN " + RetSqlName('SA3') + " SA3 "
	cQuery += " 	ON SA3.A3_FILIAL = '" + xFilial('SA3') + "' "
	cQuery += "		AND SA3.A3_COD = AD1.AD1_VEND "
	cQuery += " 	AND SA3.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('AA1') + " AA1 "
	cQuery += " 	ON AA1.AA1_FILIAL = '"  + xFilial("AA1") + "' "
	cQuery += " 	AND AA1.AA1_CODTEC = AAT.AAT_VISTOR "
	cQuery += " LEFT JOIN " + RetSqlName('ABT') + " ABT "
	cQuery += " 	ON ABT.ABT_FILIAL = '"  + xFilial("ABT") + "' "
	cQuery += " 	AND ABT.ABT_CODTPV = AAT.AAT_CODABT "
	cQuery += " 	AND ABT.D_E_L_E_T_ = ' ' "
	cQuery += " WHERE AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += " 	AND AD1.AD1_CODCLI = '" + cCodCli + "' "
	cQuery += " 	AND AD1.AD1_LOJCLI = '" + cLojCli + "' "
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "	
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	//3* Monta aCols de Retorno
	aGrid[2] := {}	
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->AD1_NROPOR,;
						(cAlias)->AD1_REVISA,;
						(cAlias)->AD1_DESCRI,;							
						(cAlias)->ADY_PROPOS,;
						(cAlias)->AAT_CODVIS,;
						(cAlias)->AA1_NOMTEC,;
						StoD((cAlias)->AAT_DTINI),;
						(cAlias)->AAT_HRINI,;
						StoD((cAlias)->AAT_DTFIM),;
						(cAlias)->AAT_HRFIM,;
						(cAlias)->AAT_CODABT,;
						(cAlias)->ABT_DESCRI,;							
						(cAlias)->AAT_STATUS,;
						.F.;	//Linha nao deletada
		  				})
		
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071CtrVig
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Contratos Vigentes"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071CtrVig(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"CN9_NUMERO",Nil})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aAdd(aColumns,{"CN9_DTINIC",Nil})
	aAdd(aColumns,{"CN9_DTFIM",Nil})
	aAdd(aColumns,{"CN9_VLINI",Nil})
	aAdd(aColumns,{"CN9_VLATU",Nil})
	aAdd(aColumns,{"CN9_SALDO",Nil})
	aAdd(aColumns,{"CN9_DTREV",Nil})
	aAdd(aColumns,{"CN9_VLADIT",Nil})
	aAdd(aColumns,{"CN9_TPCTO",Nil})
	aAdd(aColumns,{"CN1_DESCRI",Nil})
	aAdd(aColumns,{"CN9_FLGCAU",Nil})
	aAdd(aColumns,{"CN9_MINCAU",Nil})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa
	cQuery := "SELECT ADY.ADY_PROPOS,AD1.AD1_DESCRI,CN9.CN9_NUMERO,"
	cQuery += " CN9.CN9_DTINIC,CN9.CN9_DTFIM,CN9.CN9_VLINI,CN9.CN9_VLATU,CN9.CN9_SALDO, CN9.CN9_DTREV, "
	cQuery += " CN9.CN9_VLADIT, CN9.CN9_TPCTO, CN1.CN1_DESCRI, CN9.CN9_FLGCAU, CN9.CN9_MINCAU "
	cQuery += " FROM " 
	cQuery += RetSqlName("CN9") + " CN9 "	
	cQuery += " JOIN " + RetSqlName('CN1') + " CN1 "
	cQuery += " 	ON CN1.CN1_FILIAL = '" + xFilial('CN1') + "' "
	cQuery += "		AND CN1.CN1_CODIGO = CN9.CN9_TPCTO "
	cQuery += " 	AND CN1.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('TFJ') + " TFJ "
	cQuery += " 	ON TFJ.TFJ_FILIAL = '" + xFilial("TFJ") + "' "
	cQuery += " 	AND TFJ.TFJ_CONTRT = CN9.CN9_NUMERO "
	cQuery += " 	AND TFJ.TFJ_CONREV = CN9.CN9_REVISA "
	cQuery += " 	AND TFJ.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('ADY') + " ADY "
	cQuery += " 	ON ADY.ADY_FILIAL = '" + xFilial('ADY') + "' "
	cQuery += " 	AND ADY.ADY_STATUS = 'B' "
	cQuery += " 	AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += " 	AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += " 	AND ADY.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('AD1') + " AD1 "
	cQuery += " 	ON  AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += " 	AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += " 	AND AD1.AD1_REVISA = ADY.ADY_REVISA "
	cQuery += " 	AND AD1.AD1_STATUS = '9' "
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "			
	cQuery += " LEFT JOIN " + RetSqlName('SA3') + " SA3 "
	cQuery += " 	ON SA3.A3_FILIAL = '" + xFilial('SA3') + "' "
	cQuery += "		AND SA3.A3_COD = AD1.AD1_VEND "
	cQuery += " 	AND SA3.D_E_L_E_T_ = ' ' "	
	cQuery += " WHERE CN9.CN9_FILIAL = '" + xFilial('CN9') + "' "
	cQuery += "		AND CN9.CN9_REVATU = ' ' " 
	cQuery += " 	AND CN9.CN9_SITUAC = '05' "
	cQuery += " 	AND EXISTS ( "
	cQuery += " 			SELECT 1 FROM "
	cQuery += 				RetSqlName("CNA") + " CNA "
	cQuery += " 			WHERE CNA.CNA_FILIAL = '" + xFilial('CNA') + "' "
	cQuery += " 				AND CNA.CNA_CONTRA = CN9.CN9_NUMERO "
	cQuery += " 				AND CNA.CNA_REVISA = CN9.CN9_REVISA "
	cQuery += "				 	AND CNA.CNA_CLIENT = '" + cCodCli + "' "
	cQuery += " 				AND CNA.CNA_LOJACL = '" + cLojCli + "' "
	cQuery += " 				AND CNA.D_E_L_E_T_ = ' ' )
	cQuery += " 	AND CN9.D_E_L_E_T_ = ' ' "			 		
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}	
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->CN9_NUMERO,;
						(cAlias)->ADY_PROPOS,;
						(cAlias)->AD1_DESCRI,;
						StoD((cAlias)->CN9_DTINIC),;
						Stod((cAlias)->CN9_DTFIM),;
						(cAlias)->CN9_VLINI,;
						(cAlias)->CN9_VLATU,;
						(cAlias)->CN9_SALDO,;
						(cAlias)->CN9_DTREV,;
						(cAlias)->CN9_VLADIT,;
						(cAlias)->CN9_TPCTO,;
						(cAlias)->CN1_DESCRI,;
						(cAlias)->CN9_FLGCAU,;
						(cAlias)->CN9_MINCAU,;
						.F.;	//Linha nao deletada
		  				})
		
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071CtrEnc
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Contratos Encerradas"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071CtrEnc(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aAdd(aColumns,{"CN9_NUMERO",Nil})
	aAdd(aColumns,{"CN9_DTINIC",Nil})
	aAdd(aColumns,{"CN9_DTFIM",Nil})
	aAdd(aColumns,{"CN9_VLINI",Nil})
	aAdd(aColumns,{"CN9_VLATU",Nil})
	aAdd(aColumns,{"CN9_SALDO",Nil})
	aAdd(aColumns,{"CN9_DTREV",Nil})
	aAdd(aColumns,{"CN9_VLADIT",Nil})
	aAdd(aColumns,{"CN9_TPCTO",Nil})
	aAdd(aColumns,{"CN1_DESCRI",Nil})
	aAdd(aColumns,{"CN9_FLGCAU",Nil})
	aAdd(aColumns,{"CN9_MINCAU",Nil})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa
	cQuery := "SELECT ADY.ADY_PROPOS,AD1.AD1_DESCRI,CN9.CN9_NUMERO,"
	cQuery += " CN9.CN9_DTINIC,CN9.CN9_DTFIM,CN9.CN9_VLINI,CN9.CN9_VLATU,CN9.CN9_SALDO, CN9.CN9_DTREV, "
	cQuery += " CN9.CN9_VLADIT, CN9.CN9_TPCTO, CN1.CN1_DESCRI, CN9.CN9_FLGCAU, CN9.CN9_MINCAU "
	cQuery += " FROM " 
	cQuery += RetSqlName("CN9") + " CN9 "	
	cQuery += " JOIN " + RetSqlName('CN1') + " CN1 "
	cQuery += " 	ON CN1.CN1_FILIAL = '" + xFilial('CN1') + "' "
	cQuery += "		AND CN1.CN1_CODIGO = CN9.CN9_TPCTO "
	cQuery += " 	AND CN1.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('TFJ') + " TFJ "
	cQuery += " 	ON TFJ.TFJ_FILIAL = '" + xFilial("TFJ") + "' "
	cQuery += " 	AND TFJ.TFJ_CONTRT = CN9.CN9_NUMERO "
	cQuery += " 	AND TFJ.TFJ_CONREV = CN9.CN9_REVISA "
	cQuery += " 	AND TFJ.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('ADY') + " ADY "
	cQuery += " 	ON ADY.ADY_FILIAL = '" + xFilial('ADY') + "' "
	cQuery += " 	AND ADY.ADY_STATUS = 'B' "
	cQuery += " 	AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += " 	AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += " 	AND ADY.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('AD1') + " AD1 "
	cQuery += " 	ON  AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += " 	AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += " 	AND AD1.AD1_REVISA = ADY.ADY_REVISA "
	cQuery += " 	AND AD1.AD1_STATUS = '9' "
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "			
	cQuery += " LEFT JOIN " + RetSqlName('SA3') + " SA3 "
	cQuery += " 	ON SA3.A3_FILIAL = '" + xFilial('SA3') + "' "
	cQuery += "		AND SA3.A3_COD = AD1.AD1_VEND "
	cQuery += " 	AND SA3.D_E_L_E_T_ = ' ' "	
	cQuery += " WHERE CN9.CN9_FILIAL = '" + xFilial('CN9') + "' "
	cQuery += "		AND CN9.CN9_REVATU = ' ' " 
	cQuery += " 	AND CN9.CN9_SITUAC = '08' "
	cQuery += " 	AND EXISTS ( "
	cQuery += " 			SELECT 1 FROM "
	cQuery += 				RetSqlName("CNA") + " CNA "
	cQuery += " 			WHERE CNA.CNA_FILIAL = '" + xFilial('CNA') + "' "
	cQuery += " 				AND CNA.CNA_CONTRA = CN9.CN9_NUMERO "
	cQuery += " 				AND CNA.CNA_REVISA = CN9.CN9_REVISA "
	cQuery += "				 	AND CNA.CNA_CLIENT = '" + cCodCli + "' "
	cQuery += " 				AND CNA.CNA_LOJACL = '" + cLojCli + "' "
	cQuery += " 				AND CNA.D_E_L_E_T_ = ' ' )
	cQuery += " 	AND CN9.D_E_L_E_T_ = ' ' "			 		
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}	
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->ADY_PROPOS,;
						(cAlias)->AD1_DESCRI,;
						(cAlias)->CN9_NUMERO,;							
						StoD((cAlias)->CN9_DTINIC),;
						Stod((cAlias)->CN9_DTFIM),;
						(cAlias)->CN9_VLINI,;
						(cAlias)->CN9_VLATU,;
						(cAlias)->CN9_SALDO,;
						(cAlias)->CN9_DTREV,;
						(cAlias)->CN9_VLADIT,;
						(cAlias)->CN9_TPCTO,;
						(cAlias)->CN1_DESCRI,;
						(cAlias)->CN9_FLGCAU,;
						(cAlias)->CN9_MINCAU,;
						.F.;	//Linha nao deletada
		  				})
		
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071CtrMed
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Contratos Medicoes"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071CtrMed(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aAdd(aColumns,{"CN9_NUMERO",Nil})
	aAdd(aColumns,{"CND_COMPET",Nil})
	aAdd(aColumns,{"TFV_CODIGO",Nil})
	aAdd(aColumns,{"CND_NUMMED",Nil})
	aAdd(aColumns,{"CND_DTINIC",Nil})
	aAdd(aColumns,{"CND_VLTOT",Nil})
	aAdd(aColumns,{"CND_DESCME",Nil})
	aAdd(aColumns,{"CND_PEDIDO",Nil})
	aAdd(aColumns,{"CND_NUMTIT",Nil})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa
	cQuery := "SELECT ADY.ADY_PROPOS,AD1.AD1_DESCRI,CN9.CN9_NUMERO,"
	cQuery += " CN9.CN9_DTINIC,CN9.CN9_DTFIM,CN9.CN9_VLINI,CN9.CN9_VLATU,CN9.CN9_SALDO, "
	cQuery += " CND.CND_COMPET, CND.CND_NUMMED, CND.CND_DTINIC, CND.CND_VLTOT,CND.CND_DESCME,"
	cQuery += " CND.CND_PEDIDO, CND.CND_NUMTIT, TFV.TFV_CODIGO " 
	cQuery += " FROM " 
	cQuery += RetSqlName("CND") + " CND "	
	cQuery += "  JOIN " + RetSqlName('CN9') + " CN9 "
	cQuery += " 	ON CN9.CN9_FILIAL = '" + xFilial("CN9") + "' "	
	cQuery += " 	AND CN9.CN9_NUMERO = CND.CND_CONTRA "
	cQuery += " 	AND CN9.CN9_REVISA = CND.CND_REVISA "
	cQuery += "		AND CN9.CN9_REVATU = ' ' " 	
	cQuery += " 	AND CN9.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('TFJ') + " TFJ "
	cQuery += " 	ON TFJ.TFJ_FILIAL = '" + xFilial("TFJ") + "' "
	cQuery += " 	AND TFJ.TFJ_CONTRT = CN9.CN9_NUMERO "
	cQuery += " 	AND TFJ.TFJ_CONREV = CN9.CN9_REVISA "
	cQuery += " 	AND TFJ.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('ADY') + " ADY "
	cQuery += " 	ON ADY.ADY_FILIAL = '" + xFilial('ADY') + "' "
	cQuery += " 	AND ADY.ADY_STATUS = 'B' "
	cQuery += " 	AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += " 	AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += " 	AND ADY.D_E_L_E_T_ = ' ' "		
	cQuery += " LEFT JOIN " + RetSqlName('AD1') + " AD1 "
	cQuery += " 	ON  AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += " 	AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += " 	AND AD1.AD1_REVISA = ADY.ADY_REVISA "
	cQuery += " 	AND AD1.AD1_CODCLI = CND.CND_CLIENT "
	cQuery += " 	AND AD1.AD1_LOJCLI = CND.CND_LOJACL "
	cQuery += " 	AND AD1.AD1_STATUS = '9' "
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName("TFV") + " TFV " 
	cQuery += " 	ON TFV.TFV_FILIAL = '" + xFilial('TFV') + "' " 
	cQuery += " 	AND TFV.TFV_CONTRT = CND.CND_CONTRA "
	cQuery += " 	AND TFV.TFV_REVISA = CND.CND_REVISA "
	cQuery += " 	AND TFV.D_E_L_E_T_ = ' ' "
	cQuery += " 	AND ( "
	cQuery += " 		EXISTS ( "
	cQuery += " 			SELECT 1 FROM "
	cQuery += 				RetSqlName("TFY") + " TFY "
	cQuery += " 			WHERE TFY.TFY_FILIAL = '" + xFilial('TFY') + "' "
	cQuery += " 				AND TFY.TFY_APURAC = TFV.TFV_CODIGO "
	cQuery += " 				AND TFY.TFY_NUMMED = CND.CND_NUMMED " 
	cQuery += " 				AND TFY.D_E_L_E_T_ = ' ' )
	cQuery += " 		OR EXISTS ( "
	cQuery += " 			SELECT 1 FROM "
	cQuery += 				RetSqlName("TFX") + " TFX "
	cQuery += " 			WHERE TFX.TFX_FILIAL = '" + xFilial('TFX') + "' "
	cQuery += " 				AND TFX.TFX_APURAC = TFV.TFV_CODIGO "
	cQuery += " 				AND TFX.TFX_NUMMED = CND.CND_NUMMED "
	cQuery += " 				AND TFX.D_E_L_E_T_ = ' ' ) "
	cQuery += " 		OR EXISTS ( "
	cQuery += " 			SELECT 1 FROM "
	cQuery += 				RetSqlName("TFW") + " TFW "
	cQuery += " 			WHERE TFW.TFW_FILIAL = '" + xFilial('TFW') + "' "					
	cQuery += " 				AND TFW.TFW_APURAC = TFV.TFV_CODIGO "
	cQuery += " 				AND TFW.TFW_NUMMED = CND.CND_NUMMED " 
	cQuery += " 				AND TFW.D_E_L_E_T_ = ' ' ) "
	cQuery += " 		OR EXISTS ( "
	cQuery += " 			SELECT 1 FROM "
	cQuery += 				RetSqlName("TFZ") + " TFZ "
	cQuery += " 			WHERE TFZ.TFZ_FILIAL = '" + xFilial('TFZ') + "' "					
	cQuery += " 				AND TFZ.TFZ_APURAC = TFV.TFV_CODIGO "
	cQuery += " 				AND TFZ.TFZ_NUMMED = CND.CND_NUMMED " 
	cQuery += " 				AND TFZ.D_E_L_E_T_ = ' ' ) "
	cQuery += " 		) "
	cQuery += " WHERE CND.CND_FILIAL = '" + xFilial("CND") + "' "
	cQuery += " 	AND CND.CND_CLIENT = '" + cCodCli + "' "
	cQuery += " 	AND CND.CND_LOJACL = '" + cLojCli + "' " 	 	
	cQuery += " 	AND CND.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY CN9.CN9_NUMERO, CN9.CN9_REVISA, CND.CND_NUMMED ASC "
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}	
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->ADY_PROPOS,;
						(cAlias)->AD1_DESCRI,;
						(cAlias)->CN9_NUMERO,;							
						(cAlias)->CND_COMPET,;
						(cAlias)->TFV_CODIGO,;							
						(cAlias)->CND_NUMMED,;
						Stod((cAlias)->CND_DTINIC),;
						(cAlias)->CND_VLTOT,;
						(cAlias)->CND_DESCME,;
						(cAlias)->CND_PEDIDO,;
						(cAlias)->CND_NUMTIT,;
						.F.;	//Linha nao deletada
		  				})
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())

Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071TitPAb
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Provisorios em Dia"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071TitPAb(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"E1_PREFIXO",Nil})
	aAdd(aColumns,{"E1_NUM",Nil})
	aAdd(aColumns,{"E1_PARCELA",Nil})
	aAdd(aColumns,{"E1_TIPO",Nil})
	aAdd(aColumns,{"E1_VALOR",Nil})
	aAdd(aColumns,{"E1_VENCREA",Nil})
	aAdd(aColumns,{"E1_SALDO",Nil})
	aAdd(aColumns,{"E1_MDCONTR",Nil})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa
	cQuery := " SELECT SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_TIPO, SE1.E1_VALOR, SE1.E1_SALDO, "	
	cQuery += " CN9.CN9_NUMERO, SE1.E1_VENCREA, SE1.E1_MDCONTR, ADY.ADY_PROPOS, AD1.AD1_DESCRI "
	cQuery += " FROM "
	cQuery += RetSqlName('SE1') + " SE1 "	
	cQuery += "	LEFT JOIN " + RetSqlName("CN9") + " CN9 "
    cQuery += "		ON CN9.CN9_FILIAL = '"  + xFilial('CN9') + "'"
    cQuery += "		AND CN9.CN9_NUMERO = SE1.E1_MDCONTR "
    cQuery += "		AND CN9.CN9_REVATU = ' ' "
    cQuery += "		AND CN9.D_E_L_E_T_ = ' ' "	
    cQuery += "	LEFT JOIN " + RetSqlName("TFJ") + " TFJ "
    cQuery += "		ON TFJ.TFJ_FILIAL = '" + xFilial('TFJ') + "'"
    cQuery += "		AND TFJ.TFJ_CONTRT = CN9.CN9_NUMERO "
    cQuery += "		AND TFJ.TFJ_CONREV = CN9.CN9_REVISA "
    cQuery += "		AND TFJ.D_E_L_E_T_ = ' ' "
	cQuery += "	LEFT JOIN " + RetSqlName("ADY") + " ADY "
	cQuery += "		ON ADY.ADY_FILIAL = '" + xFilial('ADY') + "'"
	cQuery += "		AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += "		AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += "		AND ADY.ADY_STATUS = 'B' "
	cQuery += "		AND ADY.D_E_L_E_T_ = ' ' "   
	cQuery += "	LEFT JOIN " + RetSqlName("AD1") + " AD1 "
	cQuery += "		ON AD1.AD1_FILIAL = '" + xFilial('AD1') + "'"
	cQuery += "		AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += "		AND AD1.AD1_REVISA = ADY.ADY_REVISA "
	cQuery += "		AND AD1.AD1_STATUS = '9' "
	cQuery += "		AND AD1.AD1_CODCLI = SE1.E1_CLIENTE "
	cQuery += "		AND AD1.AD1_LOJCLI = SE1.E1_LOJA "
	cQuery += "		AND AD1.D_E_L_E_T_ = ' ' "
	cQuery += "	LEFT JOIN " + RetSqlName("SA3") + " SA3 "
	cQuery += "		ON SA3.A3_FILIAL = '" + xFilial('SA3') + "'"
	cQuery += "		AND SA3.A3_COD = AD1.AD1_VEND "
	cQuery += "		AND SA3.D_E_L_E_T_ = ' ' "                 
	cQuery += " WHERE SE1.E1_FILIAL = '"  + xFilial("SE1") + "' "
	cQuery += " 	AND SE1.E1_CLIENTE = '" + cCodCli + "' "
	cQuery += " 	AND SE1.E1_LOJA = '" + cLojCli + "' "
	cQuery += " 	AND SE1.E1_STATUS = 'A' "
	cQuery += " 	AND SE1.E1_VENCREA >= '" + dtos(dDataBase) + "' "
	cQuery += " 	AND SE1.E1_TIPO = 'PR' "		//Nao listar os provisorios
	cQuery += " 	AND SE1.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_TIPO "
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}	
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->E1_PREFIXO,;
						(cAlias)->E1_NUM,;
						(cAlias)->E1_PARCELA,;							
						(cAlias)->E1_TIPO,;
						(cAlias)->E1_VALOR,;
						StoD((cAlias)->E1_VENCREA),;
						(cAlias)->E1_SALDO,;
						(cAlias)->E1_MDCONTR,;
						(cAlias)->ADY_PROPOS,;
						(cAlias)->AD1_DESCRI,;							
						.F.;	//Linha nao deletada
		  				})
		
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071TitPVc
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Provisorios Vencidos"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071TitPVc(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"E1_PREFIXO",Nil})
	aAdd(aColumns,{"E1_NUM",Nil})
	aAdd(aColumns,{"E1_PARCELA",Nil})
	aAdd(aColumns,{"E1_TIPO",Nil})
	aAdd(aColumns,{"E1_VALOR",Nil})
	aAdd(aColumns,{"E1_VENCREA",Nil})
	aAdd(aColumns,{"E1_SALDO",Nil})
	aAdd(aColumns,{"E1_MDCONTR",Nil})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa
	cQuery := " SELECT SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_TIPO, SE1.E1_VALOR, SE1.E1_SALDO, "	
	cQuery += " CN9.CN9_NUMERO, SE1.E1_VENCREA, SE1.E1_MDCONTR, ADY.ADY_PROPOS, AD1.AD1_DESCRI "
	cQuery += " FROM " 
	cQuery += RetSqlName('SE1') + " SE1 "
	cQuery += "		LEFT JOIN " + RetSqlName("CN9") + " CN9 "
    cQuery += "			ON CN9.CN9_FILIAL = '"  + xFilial('CN9') + "'"
    cQuery += "			AND CN9.CN9_NUMERO = SE1.E1_MDCONTR "
    cQuery += "			AND CN9.CN9_REVATU = ' ' "
    cQuery += "			AND CN9.D_E_L_E_T_ = ' ' "
    cQuery += "		LEFT JOIN " + RetSqlName("TFJ") + " TFJ "
    cQuery += "			ON TFJ.TFJ_FILIAL = '" + xFilial('TFJ') + "'"
    cQuery += "			AND TFJ.TFJ_CONTRT = CN9.CN9_NUMERO "
    cQuery += "			AND TFJ.TFJ_CONREV = CN9.CN9_REVISA "
    cQuery += "			AND TFJ.D_E_L_E_T_ = ' ' "	
	cQuery += "		LEFT JOIN " + RetSqlName("ADY") + " ADY "
	cQuery += "			ON ADY.ADY_FILIAL = '" + xFilial('ADY') + "'"
	cQuery += "			AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += "			AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += "			AND ADY.ADY_STATUS = 'B' "
	cQuery += "			AND ADY.D_E_L_E_T_ = ' ' "   	
	cQuery += "		LEFT JOIN " + RetSqlName("AD1") + " AD1 "
	cQuery += "			ON AD1.AD1_FILIAL = '" + xFilial('AD1') + "'"
	cQuery += "			AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += "			AND AD1.AD1_REVISA = ADY.ADY_REVISA "
	cQuery += "			AND AD1.AD1_STATUS = '9' "
	cQuery += "			AND AD1.AD1_CODCLI = SE1.E1_CLIENTE "
	cQuery += "			AND AD1.AD1_LOJCLI = SE1.E1_LOJA "
	cQuery += "			AND AD1.D_E_L_E_T_ = ' ' "	
	cQuery += "		LEFT JOIN " + RetSqlName("SA3") + " SA3 "
	cQuery += "			ON SA3.A3_FILIAL = '" + xFilial('SA3') + "'"
	cQuery += "			AND SA3.A3_COD = AD1.AD1_VEND "
	cQuery += "			AND SA3.D_E_L_E_T_ = ' ' "                 	
	cQuery += " WHERE SE1.E1_FILIAL = '"  + xFilial("SE1") + "' "
	cQuery += " 	AND SE1.E1_CLIENTE = '" + cCodCli + "' "
	cQuery += " 	AND SE1.E1_LOJA = '" + cLojCli + "' "
	cQuery += " 	AND SE1.E1_STATUS = 'A' "
	cQuery += " 	AND SE1.E1_VENCREA < '" + dtos(dDataBase) + "' "
	cQuery += " 	AND SE1.E1_TIPO = 'PR' "		//Nao listar os provisorios
	cQuery += " 	AND SE1.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_TIPO "
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}	
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->E1_PREFIXO,;
						(cAlias)->E1_NUM,;
						(cAlias)->E1_PARCELA,;							
						(cAlias)->E1_TIPO,;
						(cAlias)->E1_VALOR,;
						Stod((cAlias)->E1_VENCREA),;
						(cAlias)->E1_SALDO,;
						(cAlias)->E1_MDCONTR,;
						(cAlias)->ADY_PROPOS,;
						(cAlias)->AD1_DESCRI,;							
						.F.;	//Linha nao deletada
		  				})
		
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071TitAbr
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Titulos em Aberto"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071TitAbr(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"E1_PREFIXO",Nil})
	aAdd(aColumns,{"E1_NUM",Nil})
	aAdd(aColumns,{"E1_PARCELA",Nil})
	aAdd(aColumns,{"E1_TIPO",Nil})
	aAdd(aColumns,{"E1_VALOR",Nil})
	aAdd(aColumns,{"E1_VENCREA",Nil})
	aAdd(aColumns,{"E1_SALDO",Nil})
	aAdd(aColumns,{"C5_MDCONTR",Nil})
	aAdd(aColumns,{"C5_NUM",STR0050})
	aAdd(aColumns,{"C5_MDNUMED",Nil})
	aAdd(aColumns,{"C5_MDPLANI",Nil})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa
	cQuery := " SELECT SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_TIPO, SE1.E1_VALOR, SE1.E1_SALDO, "	
	cQuery += " SC5.C5_NUM, SC5.C5_MDNUMED, SC5.C5_MDPLANI, CN9.CN9_NUMERO, SE1.E1_VENCREA, "
	cQuery += " ADY.ADY_PROPOS, AD1.AD1_DESCRI "	
	cQuery += " FROM " 
	cQuery += RetSqlName('SE1') + " SE1 "	
	cQuery += " LEFT JOIN " + RetSqlName("SC5") + " SC5 "
	cQuery += " 	ON SC5.C5_FILIAL = '" + xFilial("SC5") + "' "
    cQuery += "		AND SC5.C5_NUM = SE1.E1_PEDIDO "
	cQuery += "		AND SC5.C5_CLIENTE = SE1.E1_CLIENTE "
	cQuery += "		AND SC5.C5_LOJACLI = SE1.E1_LOJA "
    cQuery += "		AND SC5.D_E_L_E_T_ = ' ' "	     
	cQuery += "	LEFT JOIN " + RetSqlName("CN9") + " CN9 "
    cQuery += "		ON CN9.CN9_FILIAL = '"  + xFilial('CN9') + "'"
    cQuery += "		AND CN9.CN9_NUMERO = SC5.C5_MDCONTR "
    cQuery += "		AND CN9.CN9_REVATU = ' ' "
    cQuery += "		AND CN9.D_E_L_E_T_ = ' ' "		      
    cQuery += "	LEFT JOIN " + RetSqlName("TFJ") + " TFJ "
    cQuery += "		ON TFJ.TFJ_FILIAL = '" + xFilial('TFJ') + "'"
    cQuery += "		AND TFJ.TFJ_CONTRT = CN9.CN9_NUMERO "
    cQuery += "		AND TFJ.TFJ_CONREV = CN9.CN9_REVISA "
    cQuery += "		AND TFJ.D_E_L_E_T_ = ' ' "
	cQuery += "	LEFT JOIN " + RetSqlName("ADY") + " ADY "
	cQuery += "		ON ADY.ADY_FILIAL = '" + xFilial('ADY') + "'"
	cQuery += "		AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += "		AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += "		AND ADY.ADY_STATUS = 'B' "
	cQuery += "		AND ADY.D_E_L_E_T_ = ' ' "   
	cQuery += "	LEFT JOIN " + RetSqlName("AD1") + " AD1 "
	cQuery += "		ON AD1.AD1_FILIAL = '" + xFilial('AD1') + "'"
	cQuery += "		AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += "		AND AD1.AD1_REVISA = ADY.ADY_REVISA "
	cQuery += "		AND AD1.AD1_STATUS = '9' "
	cQuery += "		AND AD1.AD1_CODCLI = SE1.E1_CLIENTE "
	cQuery += "		AND AD1.AD1_LOJCLI = SE1.E1_LOJA "
	cQuery += "		AND AD1.D_E_L_E_T_ = ' ' "
	cQuery += "	LEFT JOIN " + RetSqlName("SA3") + " SA3 "
	cQuery += "		ON SA3.A3_FILIAL = '" + xFilial('SA3') + "'"
	cQuery += "		AND SA3.A3_COD = AD1.AD1_VEND "
	cQuery += "		AND SA3.D_E_L_E_T_ = ' ' "                 
	cQuery += " WHERE SE1.E1_FILIAL = '"  + xFilial("SE1") + "' "
	cQuery += " 	AND SE1.E1_CLIENTE = '" + cCodCli + "' "
	cQuery += " 	AND SE1.E1_LOJA = '" + cLojCli + "' "
	cQuery += " 	AND SE1.E1_STATUS = 'A' "
	cQuery += " 	AND SE1.E1_VENCREA >= '" + dtos(dDataBase) + "' "
	cQuery += " 	AND SE1.E1_TIPO <> 'PR' "		//Nao listar os provisorios
	cQuery += " 	AND SE1.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_TIPO "
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}	
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->E1_PREFIXO,;
						(cAlias)->E1_NUM,;
						(cAlias)->E1_PARCELA,;							
						(cAlias)->E1_TIPO,;
						(cAlias)->E1_VALOR,;
						StoD((cAlias)->E1_VENCREA),;
						(cAlias)->E1_SALDO,;
						(cAlias)->CN9_NUMERO,;
						(cAlias)->C5_NUM,;
						(cAlias)->C5_MDNUMED,;
						(cAlias)->C5_MDPLANI,;
						(cAlias)->ADY_PROPOS,;
						(cAlias)->AD1_DESCRI,;							
						.F.;	//Linha nao deletada
		  				})
		
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid


//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071TitBxa
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Titulos Baixados"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071TitBxa(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"E1_PREFIXO",Nil})
	aAdd(aColumns,{"E1_NUM",Nil})
	aAdd(aColumns,{"E1_PARCELA",Nil})
	aAdd(aColumns,{"E1_TIPO",Nil})
	aAdd(aColumns,{"E1_VALOR",Nil})
	aAdd(aColumns,{"E1_VENCREA",Nil})
	aAdd(aColumns,{"E1_BAIXA",Nil})
	aAdd(aColumns,{"E1_SALDO",Nil})
	aAdd(aColumns,{"C5_MDCONTR",Nil})
	aAdd(aColumns,{"C5_NUM",STR0050})
	aAdd(aColumns,{"C5_MDNUMED",Nil})
	aAdd(aColumns,{"C5_MDPLANI",Nil})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa
	cQuery := " SELECT SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_TIPO, SE1.E1_VALOR, SE1.E1_SALDO, "	
	cQuery += " SC5.C5_NUM, SC5.C5_MDNUMED, SC5.C5_MDPLANI, CN9.CN9_NUMERO, SE1.E1_VENCREA, SE1.E1_BAIXA, "
	cQuery += " ADY.ADY_PROPOS, AD1.AD1_DESCRI "	
	cQuery += " FROM " 
	cQuery += RetSqlName('SE1') + " SE1 "
	cQuery += " LEFT JOIN " + RetSqlName("SC5") + " SC5 "
	cQuery += " 	ON SC5.C5_FILIAL = '" + xFilial("SC5") + "' "
    cQuery += "		AND SC5.C5_NUM = SE1.E1_PEDIDO "
	cQuery += "		AND SC5.C5_CLIENTE = SE1.E1_CLIENTE "
	cQuery += "		AND SC5.C5_LOJACLI = SE1.E1_LOJA "
    cQuery += "		AND SC5.D_E_L_E_T_ = ' ' "	       
    cQuery += "	LEFT JOIN " + RetSqlName("CN9") + " CN9 "
    cQuery += "		ON CN9.CN9_FILIAL = '"  + xFilial('CN9') + "'"
    cQuery += "		AND CN9.CN9_NUMERO = SC5.C5_MDCONTR "
    cQuery += "		AND CN9.CN9_REVATU = ' ' "
    cQuery += "		AND CN9.D_E_L_E_T_ = ' ' "    
    cQuery += "	LEFT JOIN " + RetSqlName("TFJ") + " TFJ "
    cQuery += "		ON TFJ.TFJ_FILIAL = '" + xFilial('TFJ') + "'"
    cQuery += "		AND TFJ.TFJ_CONTRT = CN9.CN9_NUMERO "
    cQuery += "		AND TFJ.TFJ_CONREV = CN9.CN9_REVISA "
    cQuery += "		AND TFJ.D_E_L_E_T_ = ' ' "	
	cQuery += "	LEFT JOIN " + RetSqlName("ADY") + " ADY "
	cQuery += "		ON ADY.ADY_FILIAL = '" + xFilial('ADY') + "'"
	cQuery += "		AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += "		AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += "		AND ADY.ADY_STATUS = 'B' "
	cQuery += "		AND ADY.D_E_L_E_T_ = ' ' "   	
	cQuery += "	LEFT JOIN " + RetSqlName("AD1") + " AD1 "
	cQuery += "		ON AD1.AD1_FILIAL = '" + xFilial('AD1') + "'"
	cQuery += "		AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += "		AND AD1.AD1_REVISA = ADY.ADY_REVISA "
	cQuery += "		AND AD1.AD1_STATUS = '9' "
	cQuery += "		AND AD1.AD1_CODCLI = SE1.E1_CLIENTE "
	cQuery += "		AND AD1.AD1_LOJCLI = SE1.E1_LOJA "
	cQuery += "		AND AD1.D_E_L_E_T_ = ' ' "
	cQuery += "	LEFT JOIN " + RetSqlName("SA3") + " SA3 "
	cQuery += "		ON SA3.A3_FILIAL = '" + xFilial('SA3') + "'"
	cQuery += "		AND SA3.A3_COD = AD1.AD1_VEND "
	cQuery += "		AND SA3.D_E_L_E_T_ = ' ' "                 
	cQuery += " WHERE SE1.E1_FILIAL = '"  + xFilial("SE1") + "' "
	cQuery += " 	AND SE1.E1_CLIENTE = '" + cCodCli + "' "
	cQuery += " 	AND SE1.E1_LOJA = '" + cLojCli + "' "
	cQuery += " 	AND SE1.E1_STATUS = 'B' "
	cQuery += " 	AND SE1.E1_TIPO <> 'PR' "		//Nao listar os provisorios
	cQuery += " 	AND SE1.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_TIPO "
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}	
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->E1_PREFIXO,;
						(cAlias)->E1_NUM,;
						(cAlias)->E1_PARCELA,;							
						(cAlias)->E1_TIPO,;
						(cAlias)->E1_VALOR,;
						Stod((cAlias)->E1_VENCREA),;
						Stod((cAlias)->E1_BAIXA),;
						(cAlias)->E1_SALDO,;
						(cAlias)->CN9_NUMERO,;
						(cAlias)->C5_NUM,;
						(cAlias)->C5_MDNUMED,;
						(cAlias)->C5_MDPLANI,;
						(cAlias)->ADY_PROPOS,;
						(cAlias)->AD1_DESCRI,;							
						.F.;	//Linha nao deletada
		  				})
		
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071TitVnc
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Titulos Vencidos"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071TitVnc(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"E1_PREFIXO",Nil})
	aAdd(aColumns,{"E1_NUM",Nil})
	aAdd(aColumns,{"E1_PARCELA",Nil})
	aAdd(aColumns,{"E1_TIPO",Nil})
	aAdd(aColumns,{"E1_VALOR",Nil})
	aAdd(aColumns,{"E1_VENCREA",Nil})
	aAdd(aColumns,{"E1_SALDO",Nil})
	aAdd(aColumns,{"C5_MDCONTR",Nil})
	aAdd(aColumns,{"C5_NUM",STR0050})
	aAdd(aColumns,{"C5_MDNUMED",Nil})
	aAdd(aColumns,{"C5_MDPLANI",Nil})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa
	cQuery := " SELECT SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_TIPO, SE1.E1_VALOR, SE1.E1_SALDO, "	
	cQuery += " SC5.C5_NUM, SC5.C5_MDNUMED, SC5.C5_MDPLANI, CN9.CN9_NUMERO, SE1.E1_VENCREA, "
	cQuery += " ADY.ADY_PROPOS, AD1.AD1_DESCRI "	
	cQuery += " FROM " 
	cQuery += RetSqlName('SE1') + " SE1 "
	cQuery += " 	LEFT JOIN " + RetSqlName("SC5") + " SC5 "
	cQuery += " 		ON SC5.C5_FILIAL = '" + xFilial("SC5") + "' "
    cQuery += "			AND SC5.C5_NUM = SE1.E1_PEDIDO "
	cQuery += "			AND SC5.C5_CLIENTE = SE1.E1_CLIENTE "
	cQuery += "			AND SC5.C5_LOJACLI = SE1.E1_LOJA "
    cQuery += "			AND SC5.D_E_L_E_T_ = ' ' "	       
    cQuery += "		LEFT JOIN " + RetSqlName("CN9") + " CN9 "
    cQuery += "			ON CN9.CN9_FILIAL = '"  + xFilial('CN9') + "'"
    cQuery += "			AND CN9.CN9_NUMERO = SC5.C5_MDCONTR "
    cQuery += "			AND CN9.CN9_REVATU = ' ' "
    cQuery += "			AND CN9.D_E_L_E_T_ = ' ' "    
    cQuery += "		LEFT JOIN " + RetSqlName("TFJ") + " TFJ "
    cQuery += "			ON TFJ.TFJ_FILIAL = '" + xFilial('TFJ') + "'"
    cQuery += "			AND TFJ.TFJ_CONTRT = CN9.CN9_NUMERO "
    cQuery += "			AND TFJ.TFJ_CONREV = CN9.CN9_REVISA "
    cQuery += "			AND TFJ.D_E_L_E_T_ = ' ' "	
	cQuery += "		LEFT JOIN " + RetSqlName("ADY") + " ADY "
	cQuery += "			ON ADY.ADY_FILIAL = '" + xFilial('ADY') + "'"
	cQuery += "			AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += "			AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += "			AND ADY.ADY_STATUS = 'B' "
	cQuery += "			AND ADY.D_E_L_E_T_ = ' ' "   	
	cQuery += "		LEFT JOIN " + RetSqlName("AD1") + " AD1 "
	cQuery += "			ON AD1.AD1_FILIAL = '" + xFilial('AD1') + "'"
	cQuery += "			AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += "			AND AD1.AD1_REVISA = ADY.ADY_REVISA "
	cQuery += "			AND AD1.AD1_STATUS = '9' "
	cQuery += "			AND AD1.AD1_CODCLI = SE1.E1_CLIENTE "
	cQuery += "			AND AD1.AD1_LOJCLI = SE1.E1_LOJA "
	cQuery += "			AND AD1.D_E_L_E_T_ = ' ' "	
	cQuery += "		LEFT JOIN " + RetSqlName("SA3") + " SA3 "
	cQuery += "			ON SA3.A3_FILIAL = '" + xFilial('SA3') + "'"
	cQuery += "			AND SA3.A3_COD = AD1.AD1_VEND "
	cQuery += "			AND SA3.D_E_L_E_T_ = ' ' "                 	
	cQuery += " WHERE SE1.E1_FILIAL = '"  + xFilial("SE1") + "' "
	cQuery += " 	AND SE1.E1_CLIENTE = '" + cCodCli + "' "
	cQuery += " 	AND SE1.E1_LOJA = '" + cLojCli + "' "
	cQuery += " 	AND SE1.E1_STATUS = 'A' "
	cQuery += " 	AND SE1.E1_VENCREA < '" + dtos(dDataBase) + "' "
	cQuery += " 	AND SE1.E1_TIPO <> 'PR' "		//Nao listar os provisorios
	cQuery += " 	AND SE1.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_TIPO "
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}	
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->E1_PREFIXO,;
						(cAlias)->E1_NUM,;
						(cAlias)->E1_PARCELA,;							
						(cAlias)->E1_TIPO,;
						(cAlias)->E1_VALOR,;
						Stod((cAlias)->E1_VENCREA),;
						(cAlias)->E1_SALDO,;
						(cAlias)->CN9_NUMERO,;
						(cAlias)->C5_NUM,;
						(cAlias)->C5_MDNUMED,;
						(cAlias)->C5_MDPLANI,;
						(cAlias)->ADY_PROPOS,;
						(cAlias)->AD1_DESCRI,;							
						.F.;	//Linha nao deletada
		  				})
		
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071PedAbr
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Pedidos em Aberto"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071PedAbr(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"C5_NUM",STR0050})
	aAdd(aColumns,{"C5_EMISSAO",Nil})
	aAdd(aColumns,{"C5_NATUREZ",Nil})
	aAdd(aColumns,{"ED_DESCRIC",Nil})
	aAdd(aColumns,{"C5_CONDPAG",Nil})
	aAdd(aColumns,{"E4_DESCRI",Nil})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aAdd(aColumns,{"CN9_NUMERO",Nil})
	aAdd(aColumns,{"C5_MDNUMED",Nil})
	aAdd(aColumns,{"C5_MDPLANI",Nil})
	aAdd(aColumns,{"C5_ESTPRES",Nil})
	aAdd(aColumns,{"C5_MUNPRES",Nil})
	aAdd(aColumns,{"C5_DESCMUN",Nil})

	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa
	cQuery := " SELECT SC5.C5_NUM, SC5.C5_EMISSAO, SC5.C5_NATUREZ, SC5.C5_CONDPAG, "
	cQuery += " SC5.C5_ESTPRES, SC5.C5_MUNPRES, SC5.C5_DESCMUN, SC5.C5_MDNUMED, SC5.C5_MDPLANI, " 	
	cQuery += " SE4.E4_DESCRI, CN9.CN9_NUMERO, "
	cQuery += " ADY.ADY_PROPOS, AD1.AD1_DESCRI, SED.ED_DESCRIC "	
	cQuery += " FROM " 
	cQuery += RetSqlName('SC5') + " SC5 "
    cQuery += "		LEFT JOIN " + RetSqlName("CN9") + " CN9 "
    cQuery += "			ON CN9.CN9_FILIAL = '"  + xFilial('CN9') + "'"
    cQuery += "			AND CN9.CN9_NUMERO = SC5.C5_MDCONTR "
    cQuery += "			AND CN9.CN9_REVATU = ' ' "
    cQuery += "			AND CN9.D_E_L_E_T_ = ' ' "    
    cQuery += "		LEFT JOIN " + RetSqlName("TFJ") + " TFJ "
    cQuery += "			ON TFJ.TFJ_FILIAL = '" + xFilial('TFJ') + "'"
    cQuery += "			AND TFJ.TFJ_CONTRT = CN9.CN9_NUMERO "
    cQuery += "			AND TFJ.TFJ_CONREV = CN9.CN9_REVISA "
    cQuery += "			AND TFJ.D_E_L_E_T_ = ' ' "	
	cQuery += "		LEFT JOIN " + RetSqlName("ADY") + " ADY "
	cQuery += "			ON ADY.ADY_FILIAL = '" + xFilial('ADY') + "'"
	cQuery += "			AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += "			AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += "			AND ADY.ADY_STATUS = 'B' "
	cQuery += "			AND ADY.D_E_L_E_T_ = ' ' "   	
	cQuery += "		LEFT JOIN " + RetSqlName("AD1") + " AD1 "
	cQuery += "			ON AD1.AD1_FILIAL = '" + xFilial('AD1') + "'"
	cQuery += "			AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += "			AND AD1.AD1_REVISA = ADY.ADY_REVISA "
	cQuery += "			AND AD1.AD1_STATUS = '9' "
	cQuery += "			AND AD1.AD1_CODCLI = SC5.C5_CLIENTE "
	cQuery += "			AND AD1.AD1_LOJCLI = SC5.C5_LOJACLI "
	cQuery += "			AND AD1.D_E_L_E_T_ = ' ' "	
	cQuery += "		LEFT JOIN " + RetSqlName("SE4") + " SE4 "
	cQuery += "			ON SE4.E4_FILIAL = '" + xFilial('SE4') + "'"
	cQuery += "			AND SE4.E4_CODIGO = SC5.C5_CONDPAG "
	cQuery += "			AND SE4.D_E_L_E_T_ = ' ' "                 	
	cQuery += "		LEFT JOIN " + RetSqlName("SED") + " SED "
	cQuery += "			ON SED.ED_FILIAL = '" + xFilial('SED') + "'"
	cQuery += "			AND SED.ED_CODIGO = SC5.C5_NATUREZ "
	cQuery += "			AND SED.D_E_L_E_T_ = ' ' "	
	cQuery += " WHERE SC5.C5_FILIAL = '"  + xFilial("SC5") + "' "
	cQuery += "		AND SC5.C5_CLIENTE = '" + cCodCli + "' "
	cQuery += "		AND SC5.C5_LOJACLI = '" + cLojCli + "' "
	cQuery += "		AND SC5.C5_NOTA = ' ' "	
	cQuery += " 	AND SC5.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY SC5.C5_EMISSAO, SC5.C5_NUM "
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}	
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->C5_NUM,;
						StoD((cAlias)->C5_EMISSAO),;
						(cAlias)->C5_NATUREZ,;							
						(cAlias)->ED_DESCRIC,;
						(cAlias)->C5_CONDPAG,;
						(cAlias)->E4_DESCRI,;
						(cAlias)->ADY_PROPOS,;
						(cAlias)->AD1_DESCRI,;
						(cAlias)->CN9_NUMERO,;
						(cAlias)->C5_MDNUMED,;
						(cAlias)->C5_MDPLANI,;
						(cAlias)->C5_ESTPRES,;
						(cAlias)->C5_MUNPRES,;
						(cAlias)->C5_DESCMUN,;							
						.F.;	//Linha nao deletada
		  				})
		
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071PedFat
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Pedidos Faturados"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071PedFat(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"C5_NUM",STR0050})
	aAdd(aColumns,{"C5_EMISSAO",Nil})
	aAdd(aColumns,{"C5_NOTA",Nil})
	aAdd(aColumns,{"C5_SERIE",Nil})
	aAdd(aColumns,{"C5_NATUREZ",Nil})
	aAdd(aColumns,{"ED_DESCRIC",Nil})
	aAdd(aColumns,{"C5_CONDPAG",Nil})
	aAdd(aColumns,{"E4_DESCRI",Nil})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aAdd(aColumns,{"CN9_NUMERO",Nil})
	aAdd(aColumns,{"C5_MDNUMED",Nil})
	aAdd(aColumns,{"C5_MDPLANI",Nil})
	aAdd(aColumns,{"C5_ESTPRES",Nil})
	aAdd(aColumns,{"C5_MUNPRES",Nil})
	aAdd(aColumns,{"C5_DESCMUN",Nil})

	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa
	cQuery := " SELECT SC5.C5_NUM, SC5.C5_EMISSAO, SC5.C5_NATUREZ, SC5.C5_CONDPAG, SC5.C5_NOTA, SC5.C5_SERIE, "
	cQuery += " SC5.C5_ESTPRES, SC5.C5_MUNPRES, SC5.C5_DESCMUN, SC5.C5_MDNUMED, SC5.C5_MDPLANI, " 	
	cQuery += " SE4.E4_DESCRI, CN9.CN9_NUMERO, "
	cQuery += " ADY.ADY_PROPOS, AD1.AD1_DESCRI, SED.ED_DESCRIC "	
	cQuery += " FROM " 
	cQuery += RetSqlName('SC5') + " SC5 "
    cQuery += "		LEFT JOIN " + RetSqlName("CN9") + " CN9 "
    cQuery += "			ON CN9.CN9_FILIAL = '"  + xFilial('CN9') + "'"
    cQuery += "			AND CN9.CN9_NUMERO = SC5.C5_MDCONTR "
    cQuery += "			AND CN9.CN9_REVATU = ' ' "
    cQuery += "			AND CN9.D_E_L_E_T_ = ' ' "    
    cQuery += "		LEFT JOIN " + RetSqlName("TFJ") + " TFJ "
    cQuery += "			ON TFJ.TFJ_FILIAL = '" + xFilial('TFJ') + "'"
    cQuery += "			AND TFJ.TFJ_CONTRT = CN9.CN9_NUMERO "
    cQuery += "			AND TFJ.TFJ_CONREV = CN9.CN9_REVISA "
    cQuery += "			AND TFJ.D_E_L_E_T_ = ' ' "	
	cQuery += "		LEFT JOIN " + RetSqlName("ADY") + " ADY "
	cQuery += "			ON ADY.ADY_FILIAL = '" + xFilial('ADY') + "'"
	cQuery += "			AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += "			AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += "			AND ADY.ADY_STATUS = 'B' "
	cQuery += "			AND ADY.D_E_L_E_T_ = ' ' "   	
	cQuery += "		LEFT JOIN " + RetSqlName("AD1") + " AD1 "
	cQuery += "			ON AD1.AD1_FILIAL = '" + xFilial('AD1') + "'"
	cQuery += "			AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += "			AND AD1.AD1_REVISA = ADY.ADY_REVISA "
	cQuery += "			AND AD1.AD1_STATUS = '9' "
	cQuery += "			AND AD1.AD1_CODCLI = SC5.C5_CLIENTE "
	cQuery += "			AND AD1.AD1_LOJCLI = SC5.C5_LOJACLI "
	cQuery += "			AND AD1.D_E_L_E_T_ = ' ' "
	cQuery += "		LEFT JOIN " + RetSqlName("SE4") + " SE4 "
	cQuery += "			ON SE4.E4_FILIAL = '" + xFilial('SE4') + "'"
	cQuery += "			AND SE4.E4_CODIGO = SC5.C5_CONDPAG "
	cQuery += "			AND SE4.D_E_L_E_T_ = ' ' "                 
	cQuery += "		LEFT JOIN " + RetSqlName("SED") + " SED "
	cQuery += "			ON SED.ED_FILIAL = '" + xFilial('SED') + "'"
	cQuery += "			AND SED.ED_CODIGO = SC5.C5_NATUREZ "
	cQuery += "			AND SED.D_E_L_E_T_ = ' ' "
	cQuery += " WHERE SC5.C5_FILIAL = '"  + xFilial("SC5") + "' "
	cQuery += "		AND SC5.C5_CLIENTE = '" + cCodCli + "' "
	cQuery += "		AND SC5.C5_LOJACLI = '" + cLojCli + "' "
	cQuery += "		AND SC5.C5_NOTA <> ' ' "	
	cQuery += " 	AND SC5.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY SC5.C5_EMISSAO, SC5.C5_NUM "
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}	
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->C5_NUM,;
						StoD((cAlias)->C5_EMISSAO),;
						(cAlias)->C5_NOTA,;
						(cAlias)->C5_SERIE,;
						(cAlias)->C5_NATUREZ,;							
						(cAlias)->ED_DESCRIC,;
						(cAlias)->C5_CONDPAG,;
						(cAlias)->E4_DESCRI,;
						(cAlias)->ADY_PROPOS,;
						(cAlias)->AD1_DESCRI,;
						(cAlias)->CN9_NUMERO,;
						(cAlias)->C5_MDNUMED,;
						(cAlias)->C5_MDPLANI,;
						(cAlias)->C5_ESTPRES,;
						(cAlias)->C5_MUNPRES,;
						(cAlias)->C5_DESCMUN,;							
						.F.;	//Linha nao deletada
		  				})
		
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071NFSrv
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"NF (Servicos)"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071NFSrv(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"F2_SERIE",Nil})
	aAdd(aColumns,{"F2_DOC",STR0049})
	aAdd(aColumns,{"F2_COND",Nil})
	aAdd(aColumns,{"E4_DESCRI",Nil})
	aAdd(aColumns,{"F2_EMISSAO",Nil})
	aAdd(aColumns,{"F2_VALBRUT",Nil})
	aAdd(aColumns,{"F2_BASEISS",Nil})
	aAdd(aColumns,{"F2_VALISS",Nil})
	aAdd(aColumns,{"C5_NUM",STR0050})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aAdd(aColumns,{"CN9_NUMERO",Nil})
	aAdd(aColumns,{"C5_MDNUMED",Nil})
	aAdd(aColumns,{"C5_MDPLANI",Nil})
	aAdd(aColumns,{"C5_ESTPRES",Nil})
	aAdd(aColumns,{"C5_MUNPRES",Nil})
	aAdd(aColumns,{"C5_DESCMUN",Nil})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa		
	cQuery := " SELECT SF2.F2_DOC, SF2.F2_SERIE, SF2.F2_COND, SE4.E4_DESCRI, SF2.F2_EMISSAO, "
	cQuery += " SF2.F2_VALBRUT, SF2.F2_BASEISS, SF2.F2_VALISS, SF2.F2_VALFAT, "
	cQuery += " SC5.C5_NUM, SC5.C5_NATUREZ, ADY.ADY_PROPOS, AD1.AD1_DESCRI, "
	cQuery += " CN9.CN9_NUMERO, SC5.C5_MDNUMED, SC5.C5_MDPLANI, SC5.C5_ESTPRES, SC5.C5_MUNPRES, SC5.C5_DESCMUN "
	cQuery += " FROM "	
	cQuery += RetSqlName('SF2') + " SF2, "
	cQuery += RetSqlName('SC5') + " SC5, "
	cQuery += RetSqlName('SE4') + " SE4, "
	cQuery += RetSqlName('CN9') + " CN9, "
	cQuery += RetSqlName('TFJ') + " TFJ, "
	cQuery += RetSqlName('ADY') + " ADY, "
	cQuery += RetSqlName('AD1') + " AD1 "
	cQuery += " WHERE SF2.F2_FILIAL = '" + xFilial('SF2') + "' "
	cQuery += "		AND SC5.C5_FILIAL = '" + xFilial('SC5') + "' "
	cQuery += "		AND SE4.E4_FILIAL = '" + xFilial('SE4') + "' "
	cQuery += "		AND CN9.CN9_FILIAL = '" + xFilial('CN9') + "' "
	cQuery += "		AND TFJ.TFJ_FILIAL = '" + xFilial('TFJ') + "' "
	cQuery += "		AND ADY.ADY_FILIAL = '" + xFilial('ADY') + "' "
	cQuery += "		AND AD1.AD1_FILIAL = '" + xFilial('AD1') + "' "	
	cQuery += " 	AND SF2.F2_CLIENTE = '" + cCodCli + "' "
	cQuery += " 	AND SF2.F2_LOJA = '" + cLojCli + "' "	
	cQuery += " 	AND SC5.C5_NOTA = SF2.F2_DOC "
	cQuery += "		AND SC5.C5_SERIE = SF2.F2_SERIE "	
	cQuery += "		AND SC5.C5_CLIENTE = SF2.F2_CLIENTE "
	cQuery += "		AND SC5.C5_LOJACLI = SF2.F2_LOJA "
	cQuery += "		AND CN9.CN9_NUMERO = SC5.C5_MDCONTR "
	cQuery += "		AND CN9.CN9_REVATU = ' ' " 
    cQuery += "		AND TFJ.TFJ_CONTRT = CN9.CN9_NUMERO "
    cQuery += "		AND TFJ.TFJ_CONREV = CN9.CN9_REVISA "
    cQuery += "		AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += "		AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += "		AND ADY.ADY_STATUS = 'B' "
	cQuery += "		AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += "		AND AD1.AD1_REVISA = ADY.ADY_REVISA "
	cQuery += "		AND AD1.AD1_STATUS = '9' "
	cQuery += "		AND AD1.AD1_CODCLI = SC5.C5_CLIENTE "
	cQuery += "		AND AD1.AD1_LOJCLI = SC5.C5_LOJACLI "
	cQuery += "		AND SE4.E4_CODIGO = SC5.C5_CONDPAG "
	cQuery += "		AND SF2.D_E_L_E_T_ = ' ' "
	cQuery += "		AND SC5.D_E_L_E_T_ = ' ' "
	cQuery += "		AND SE4.D_E_L_E_T_ = ' ' "	
	cQuery += "		AND CN9.D_E_L_E_T_ = ' ' "
	cQuery += "		AND TFJ.D_E_L_E_T_ = ' ' "
	cQuery += "		AND ADY.D_E_L_E_T_ = ' ' "
	cQuery += "		AND AD1.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY SF2.F2_EMISSAO, SF2.F2_SERIE, SF2.F2_DOC "
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->F2_SERIE,;
						(cAlias)->F2_DOC,;							
						(cAlias)->F2_COND,;
						(cAlias)->E4_DESCRI,;
						Stod((cAlias)->F2_EMISSAO),;							
						(cAlias)->F2_VALBRUT,;
						(cAlias)->F2_BASEISS,;
						(cAlias)->F2_VALISS,;
						(cAlias)->C5_NUM,;
						(cAlias)->ADY_PROPOS,;
						(cAlias)->AD1_DESCRI,;
						(cAlias)->CN9_NUMERO,;
						(cAlias)->C5_MDNUMED,;
						(cAlias)->C5_MDPLANI,;							
						(cAlias)->C5_ESTPRES,;
						(cAlias)->C5_MUNPRES,;
						(cAlias)->C5_DESCMUN,;
						.F.;	//Linha nao deletada
		  				})
		
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071NFRms
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"NF (Remessa)"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071NFRms(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"TEW_SERSAI",Nil})
	aAdd(aColumns,{"TEW_NFSAI",Nil})
	aAdd(aColumns,{"F2_EMISSAO",Nil})
	aAdd(aColumns,{"F2_VALBRUT",Nil})
	aAdd(aColumns,{"TEW_NUMPED",Nil})
	aAdd(aColumns,{"CN9_NUMERO",Nil})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})	
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa		
	cQuery := " SELECT SF2.F2_DOC, SF2.F2_SERIE, SF2.F2_EMISSAO, "
	cQuery += " SF2.F2_VALBRUT, SF2.F2_VALFAT, "
	cQuery += " SC5.C5_NUM, SC5.C5_NATUREZ, ADY.ADY_PROPOS, AD1.AD1_DESCRI, "
	cQuery += " CN9.CN9_NUMERO "
	cQuery += " FROM "	
	cQuery += RetSqlName('SF2') + " SF2, "
	cQuery += RetSqlName('SC5') + " SC5, "
	cQuery += RetSqlName('TEW') + " TEW, "
	cQuery += RetSqlName('CN9') + " CN9, "
	cQuery += RetSqlName('TFJ') + " TFJ, "
	cQuery += RetSqlName('ADY') + " ADY, "
	cQuery += RetSqlName('AD1') + " AD1 "	
	cQuery += " WHERE SF2.F2_FILIAL = '" + xFilial('SF2') + "' "
	cQuery += "		AND SC5.C5_FILIAL = '" + xFilial('SC5') + "' "
	cQuery += "		AND TEW.TEW_FILIAL = '" + xFilial('TEW') + "' "
	cQuery += "		AND CN9.CN9_FILIAL = '" + xFilial('CN9') + "' "
	cQuery += "		AND TFJ.TFJ_FILIAL = '" + xFilial('TFJ') + "' "
	cQuery += "		AND ADY.ADY_FILIAL = '" + xFilial('ADY') + "' "
	cQuery += "		AND AD1.AD1_FILIAL = '" + xFilial('AD1') + "' "
	cQuery += " 	AND SF2.F2_CLIENTE = '" + cCodCli + "' "
	cQuery += " 	AND SF2.F2_LOJA = '" + cLojCli + "' "
	cQuery += " 	AND SC5.C5_NOTA = SF2.F2_DOC "
	cQuery += "		AND SC5.C5_SERIE = SF2.F2_SERIE "	
	cQuery += "		AND SC5.C5_CLIENTE = SF2.F2_CLIENTE "
	cQuery += "		AND SC5.C5_LOJACLI = SF2.F2_LOJA "
	cQuery += " 	AND TEW.TEW_NUMPED = SC5.C5_NUM "
	cQuery += "		AND TEW.TEW_SERSAI = SF2.F2_SERIE "
	cQuery += " 	AND TEW.TEW_NFSAI = SF2.F2_DOC "
	cQuery += " 	AND TFJ.TFJ_CODIGO = TEW.TEW_ORCSER "
    cQuery += "		AND TFJ.TFJ_CONTRT = CN9.CN9_NUMERO "
    cQuery += "		AND TFJ.TFJ_CONREV = CN9.CN9_REVISA "
    cQuery += "		AND CN9.CN9_REVATU = ' ' "
    cQuery += "		AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += "		AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += "		AND ADY.ADY_STATUS = 'B' "
	cQuery += "		AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += "		AND AD1.AD1_REVISA = ADY.ADY_REVISA "
	cQuery += "		AND AD1.AD1_STATUS = '9' "
	cQuery += "		AND AD1.AD1_CODCLI = SC5.C5_CLIENTE "
	cQuery += "		AND AD1.AD1_LOJCLI = SC5.C5_LOJACLI "
	cQuery += "		AND SF2.D_E_L_E_T_ = ' ' "
	cQuery += "		AND SC5.D_E_L_E_T_ = ' ' "
	cQuery += "		AND TEW.D_E_L_E_T_ = ' ' "	
	cQuery += "		AND CN9.D_E_L_E_T_ = ' ' "
	cQuery += "		AND TFJ.D_E_L_E_T_ = ' ' "
	cQuery += "		AND ADY.D_E_L_E_T_ = ' ' "
	cQuery += "		AND AD1.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY SF2.F2_EMISSAO, SF2.F2_SERIE, SF2.F2_DOC "
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->F2_SERIE,;
						(cAlias)->F2_DOC,;
						Stod((cAlias)->F2_EMISSAO),;							
						(cAlias)->F2_VALBRUT,;
						(cAlias)->C5_NUM,;
						(cAlias)->CN9_NUMERO,;
						(cAlias)->ADY_PROPOS,;
						(cAlias)->AD1_DESCRI,;
						.F.;	//Linha nao deletada
		  				})
		
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071NFRet
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"NF (Retorno)"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071NFRet(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"TEW_SERENT",Nil})
	aAdd(aColumns,{"TEW_NFENT",Nil})
	aAdd(aColumns,{"F1_EMISSAO",Nil})
	aAdd(aColumns,{"F1_VALBRUT",Nil})
	aAdd(aColumns,{"TEW_SERSAI",Nil})
	aAdd(aColumns,{"TEW_NFSAI",Nil})
	aAdd(aColumns,{"TEW_NUMPED",Nil})
	aAdd(aColumns,{"CN9_NUMERO",Nil})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa		
	cQuery := " SELECT SF1.F1_DOC, SF1.F1_SERIE, SF1.F1_EMISSAO, CN9.CN9_NUMERO, "
	cQuery += " SF1.F1_VALBRUT, ADY.ADY_PROPOS, AD1.AD1_DESCRI, "	
	cQuery += " TEW.TEW_SERSAI, TEW.TEW_NFSAI, TEW.TEW_NUMPED "	
	cQuery += " FROM "	
	cQuery += RetSqlName('SF1') + " SF1, "
	cQuery += RetSqlName('TEW') + " TEW, "
	cQuery += RetSqlName('CN9') + " CN9, "
	cQuery += RetSqlName('TFJ') + " TFJ, "
	cQuery += RetSqlName('ADY') + " ADY, "
	cQuery += RetSqlName('AD1') + " AD1 "	
	cQuery += " WHERE SF1.F1_FILIAL = '" + xFilial('SF1') + "' "
	cQuery += "		AND TEW.TEW_FILIAL = '" + xFilial('TEW') + "' "
	cQuery += "		AND CN9.CN9_FILIAL = '" + xFilial('CN9') + "' "
	cQuery += "		AND TFJ.TFJ_FILIAL = '" + xFilial('TFJ') + "' "
	cQuery += "		AND ADY.ADY_FILIAL = '" + xFilial('ADY') + "' "
	cQuery += "		AND AD1.AD1_FILIAL = '" + xFilial('AD1') + "' "
	cQuery += "		AND SF1.F1_FORNECE = '" + cCodCli + "'"
	cQuery += "		AND SF1.F1_LOJA = '" + cLojCli + "'"
	cQuery += "		AND SF1.F1_SERIE = TEW.TEW_SERENT "
	cQuery += " 	AND SF1.F1_DOC = TEW.TEW_NFENT "
	cQuery += " 	AND TFJ.TFJ_CODIGO = TEW.TEW_ORCSER "
    cQuery += "		AND TFJ.TFJ_CONTRT = CN9.CN9_NUMERO "
    cQuery += "		AND TFJ.TFJ_CONREV = CN9.CN9_REVISA "
    cQuery += "		AND CN9.CN9_REVATU = ' ' "
    cQuery += "		AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += "		AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += "		AND ADY.ADY_STATUS = 'B' "
	cQuery += "		AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += "		AND AD1.AD1_REVISA = ADY.ADY_REVISA "
	cQuery += "		AND AD1.AD1_STATUS = '9' "
	cQuery += "		AND AD1.AD1_CODCLI = SF1.F1_FORNECE "
	cQuery += "		AND AD1.AD1_LOJCLI = SF1.F1_LOJA "
	cQuery += "		AND SF1.D_E_L_E_T_ = ' ' "
	cQuery += "		AND TEW.D_E_L_E_T_ = ' ' "	
	cQuery += "		AND CN9.D_E_L_E_T_ = ' ' "
	cQuery += "		AND TFJ.D_E_L_E_T_ = ' ' "
	cQuery += "		AND ADY.D_E_L_E_T_ = ' ' "
	cQuery += "		AND AD1.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY SF1.F1_EMISSAO, SF1.F1_SERIE, SF1.F1_DOC "
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}	
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->F1_SERIE,;
						(cAlias)->F1_DOC,;
						Stod((cAlias)->F1_EMISSAO),;							
						(cAlias)->F1_VALBRUT,;							
						(cAlias)->TEW_SERSAI,;
						(cAlias)->TEW_NFSAI,;
						(cAlias)->TEW_NUMPED,;
						(cAlias)->CN9_NUMERO,;
						(cAlias)->ADY_PROPOS,;
						(cAlias)->AD1_DESCRI,;
						.F.;	//Linha nao deletada
		  				})
		
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071NFOut
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"NF (Outros)"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071NFOut(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"F2_SERIE",Nil})
	aAdd(aColumns,{"F2_DOC",STR0049})	
	aAdd(aColumns,{"F2_EMISSAO",Nil})
	aAdd(aColumns,{"F2_VALBRUT",Nil})
	aAdd(aColumns,{"C5_NUM",STR0050})
	aAdd(aColumns,{"C5_ESTPRES",Nil})
	aAdd(aColumns,{"C5_MUNPRES",Nil})
	aAdd(aColumns,{"C5_DESCMUN",Nil})
	aAdd(aColumns,{"C5_MENNOTA",Nil})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa		
	cQuery := " SELECT SF2.F2_DOC, SF2.F2_SERIE, SF2.F2_EMISSAO, SF2.F2_VALBRUT, "
	cQuery += " SC5.C5_NUM, SC5.C5_ESTPRES, SC5.C5_MUNPRES, SC5.C5_DESCMUN, SC5.C5_MENNOTA "
	cQuery += " FROM "	
	cQuery += RetSqlName('SF2') + " SF2 "
	cQuery += " LEFT JOIN " + RetSqlName("SC5") + " SC5 "
	cQuery += " 	ON SC5.C5_FILIAL = '" + xFilial("SC5") + "' "
    cQuery += "		AND SC5.C5_NOTA = SF2.F2_DOC "
	cQuery += "		AND SC5.C5_SERIE = SF2.F2_SERIE "
	cQuery += "     AND SC5.C5_CLIENTE = SF2.F2_CLIENTE"
	cQuery += "		AND SC5.C5_LOJACLI = SF2.F2_LOJA "
	cQuery += "		AND SC5.C5_MDCONTR = ' ' "
	cQuery += "		AND SC5.C5_MDNUMED = ' ' "
	cQuery += "		AND SC5.C5_MDPLANI = ' ' "
    cQuery += "		AND SC5.D_E_L_E_T_ = ' ' "	   
    cQuery += " WHERE SF2.F2_FILIAL = '" + xFilial('SF2') + "' "
    cQuery += " 	AND SF2.F2_CLIENTE = '" + cCodCli + "'"
    cQuery += " 	AND SF2.F2_LOJA = '" + cLojCli + "'"    
    cQuery += " 	AND F2_DOC NOT IN "
    cQuery += "			(SELECT SC5B.C5_NOTA "
    cQuery += "			FROM " + RetSqlName('SC5') + " SC5B "
    cQuery += "			WHERE SC5B.C5_FILIAL = '" + xFilial('SC5') + "' "			
    cQuery += "				AND SC5B.C5_NOTA = SF2.F2_DOC "
	cQuery += "				AND SC5B.C5_SERIE = SF2.F2_SERIE "
	cQuery += "     		AND SC5B.C5_CLIENTE = SF2.F2_CLIENTE"
	cQuery += "				AND SC5B.C5_LOJACLI = SF2.F2_LOJA "
	cQuery += "				AND SC5B.C5_MDCONTR <> ' ' "
	cQuery += "				AND SC5B.C5_MDNUMED <> ' ' "
	cQuery += "				AND SC5B.C5_MDPLANI <> ' ' "
    cQuery += "				AND SC5B.D_E_L_E_T_ = ' ') "
    cQuery += " 	AND SF2.F2_DOC NOT IN "
    cQuery += " 		(SELECT TEW.TEW_NFSAI "
    cQuery += " 		FROM " + RetSqlName("TEW") + " TEW, " + RetSqlName("TFJ") + " TFJ "
    cQuery += "			WHERE TEW.TEW_FILIAL = '" + xFilial('TEW') + "' "
    cQuery += "				AND TFJ.TFJ_FILIAL = '" + xFilial('TFJ') + "' "
    cQuery += " 			AND TFJ.TFJ_CODIGO = TEW.TEW_ORCSER "
    cQuery += " 			AND TFJ.TFJ_CODENT = SF2.F2_CLIENTE "
    cQuery += " 			AND TFJ.TFJ_LOJA = SF2.F2_LOJA "
    cQuery += "				AND TEW.TEW_SERSAI = SF2.F2_SERIE "
	cQuery += " 			AND TEW.TEW_NFSAI = SF2.F2_DOC "
	cQuery += "				AND TFJ.D_E_L_E_T_ = ' ' "
	cQuery += "				AND TEW.D_E_L_E_T_ = ' ') "
	cQuery += "		AND SF2.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY SF2.F2_EMISSAO, SF2.F2_SERIE, SF2.F2_DOC "
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->F2_SERIE,;
						(cAlias)->F2_DOC,;
						Stod((cAlias)->F2_EMISSAO),;							
						(cAlias)->F2_VALBRUT,;							
						(cAlias)->C5_NUM,;
						(cAlias)->C5_ESTPRES,;
						(cAlias)->C5_MUNPRES,;
						(cAlias)->C5_DESCMUN,;
						(cAlias)->C5_MENNOTA,;
						.F.;	//Linha nao deletada
		  				})
		
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071LACtr
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Locais de Atendimento com Contrato ativo"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071LACtr(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"ABS_LOCAL",Nil})
	aAdd(aColumns,{"ABS_DESCRI",STR0062})
	aAdd(aColumns,{"TFL_DTINI",Nil})
	aAdd(aColumns,{"TFL_DTFIM",Nil})
	aAdd(aColumns,{"CN9_NUMERO",Nil})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})	
	aAdd(aColumns,{"ABS_RECISS",Nil})
	aAdd(aColumns,{"ABS_CCUSTO",Nil})
	aAdd(aColumns,{"CTT_DESC01",Nil})
	aAdd(aColumns,{"ABS_END",Nil})
	aAdd(aColumns,{"ABS_BAIRRO",Nil})
	aAdd(aColumns,{"ABS_MUNIC",Nil})
	aAdd(aColumns,{"ABS_ESTADO",Nil})	
	aAdd(aColumns,{"ABS_CLIFAT",Nil})
	aAdd(aColumns,{"ABS_LJFAT",Nil})
	aAdd(aColumns,{"A1_NOME",Nil})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa		
	cQuery := " SELECT ABS.ABS_CODIGO, ABS.ABS_LOCAL, ABS.ABS_DESCRI, ABS.ABS_CCUSTO, CTT.CTT_DESC01, " 
	cQuery += " ABS.ABS_END, ABS.ABS_BAIRRO, ABS.ABS_MUNIC, ABS.ABS_ESTADO, TFL.TFL_DTINI, "
	cQuery += " TFL.TFL_DTFIM, ABS.ABS_CLIFAT, ABS.ABS_LJFAT, SA1.A1_NOME, ABS.ABS_RECISS, "
	cQuery += " CN9.CN9_NUMERO, ADY.ADY_PROPOS, AD1.AD1_DESCRI"
	cQuery += " FROM " + RetSqlName('ABS') + " ABS "
	cQuery += " JOIN " + RetSqlName('AD1') + " AD1 "
	cQuery += "		ON AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += " 	AND AD1.AD1_CODCLI = ABS.ABS_CODIGO "
	cQuery += " 	AND AD1.AD1_LOJCLI = ABS.ABS_LOJA "
	cQuery += " 	AND AD1.AD1_STATUS = '9' "
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('ADY') + " ADY "
	cQuery += "		ON ADY.ADY_FILIAL = '"  + xFilial("ADY") + "' "
	cQuery += " 	AND ADY.ADY_STATUS = 'B' "
	cQuery += " 	AND ADY.ADY_OPORTU = AD1.AD1_NROPOR "
	cQuery += " 	AND ADY.ADY_REVISA = AD1.AD1_REVISA "
	cQuery += " 	AND ADY.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('TFJ') + " TFJ "
	cQuery += "		ON TFJ.TFJ_FILIAL = '"  + xFilial("TFJ") + "' "	
	cQuery += " 	AND TFJ.TFJ_PROPOS = ADY.ADY_PROPOS "
	cQuery += " 	AND TFJ.TFJ_PREVIS = ADY.ADY_PREVIS "
	cQuery += " 	AND TFJ.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('TFL') + " TFL "
	cQuery += " 	ON TFL.TFL_FILIAL = '" + xFilial('TFL') + "' "
	cQuery += "		AND TFL.TFL_CODPAI = TFJ.TFJ_CODIGO "
	cQuery += "		AND TFL.TFL_LOCAL = ABS.ABS_LOCAL "
	cQuery += "		AND TFL.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('CN9') + " CN9 "
	cQuery += " 	ON CN9.CN9_FILIAL = '" + xFilial('CN9') + "'"
	cQuery += " 	AND CN9.CN9_NUMERO = TFJ.TFJ_CONTRT "
	cQuery += " 	AND CN9.CN9_REVISA = TFJ.TFJ_CONREV "
	cQuery += "		AND CN9.CN9_REVATU = ' ' " 
	cQuery += " 	AND CN9.CN9_SITUAC = '05' "
	cQuery += "		AND CN9.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('CTT') + " CTT "
	cQuery += " 	ON CTT.CTT_FILIAL = '" + xFilial('CTT') + "'"
	cQuery += " 	AND CTT.CTT_CUSTO = ABS.ABS_CCUSTO "
	cQuery += "		AND CTT.D_E_L_E_T_ = ' ' "
	cQuery += " LEFT JOIN " + RetSqlName('SA1') + " SA1 "
	cQuery += "		ON SA1.A1_FILIAL = '" + xFilial("SA1") + "' "
	cQuery += " 	AND SA1.A1_COD = ABS.ABS_CLIFAT "
	cQuery += " 	AND SA1.A1_LOJA = ABS.ABS_LJFAT "
	cQuery += " 	AND SA1.D_E_L_E_T_ = ' ' "	
	cQuery += " WHERE ABS.ABS_FILIAL = '" + xFilial('ABS') + "' "
	cQuery += " 	AND ABS.ABS_CODIGO = '" + cCodCli + "' "
	cQuery += " 	AND ABS.ABS_LOJA = '" + cLojCli + "' "
	cQuery += " 	AND ABS.ABS_ENTIDA = '1' "
	cQuery += "		AND ABS.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY ABS.ABS_LOCAL, CN9.CN9_NUMERO "
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}	
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->ABS_LOCAL,;
						(cAlias)->ABS_DESCRI,;
						Stod((cAlias)->TFL_DTINI),;
						Stod((cAlias)->TFL_DTFIM),;
						(cAlias)->CN9_NUMERO,;
						(cAlias)->ADY_PROPOS,;
						(cAlias)->AD1_DESCRI,;							
						(cAlias)->ABS_RECISS,;
						(cAlias)->ABS_CCUSTO,;							
						(cAlias)->CTT_DESC01,;							
						(cAlias)->ABS_END,;
						(cAlias)->ABS_BAIRRO,;
						(cAlias)->ABS_MUNIC,;
						(cAlias)->ABS_ESTADO,;
						(cAlias)->ABS_CLIFAT,;
						(cAlias)->ABS_LJFAT,;
						(cAlias)->A1_NOME,;							
						.F.;	//Linha nao deletada
		  				})

		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071LAVzo
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Locais de Atendimento Sem Contrato"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071LAVzo(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"ABS_LOCAL",Nil})
	aAdd(aColumns,{"ABS_DESCRI",STR0062})
	aAdd(aColumns,{"ABS_RECISS",Nil})
	aAdd(aColumns,{"ABS_CCUSTO",Nil})
	aAdd(aColumns,{"CTT_DESC01",Nil})
	aAdd(aColumns,{"ABS_END",Nil})
	aAdd(aColumns,{"ABS_BAIRRO",Nil})
	aAdd(aColumns,{"ABS_MUNIC",Nil})
	aAdd(aColumns,{"ABS_ESTADO",Nil})	
	aAdd(aColumns,{"ABS_CLIFAT",Nil})
	aAdd(aColumns,{"ABS_LJFAT",Nil})
	aAdd(aColumns,{"A1_NOME",Nil})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa		
	cQuery := " SELECT ABS.ABS_CODIGO, ABS.ABS_LOCAL, ABS.ABS_DESCRI, ABS.ABS_CCUSTO, CTT.CTT_DESC01, " 
	cQuery += " ABS.ABS_END, ABS.ABS_BAIRRO, ABS.ABS_MUNIC, ABS.ABS_ESTADO, "
	cQuery += " ABS.ABS_CLIFAT, ABS.ABS_LJFAT, SA1.A1_NOME, ABS.ABS_RECISS "
	cQuery += " FROM " + RetSqlName('ABS') + " ABS "
	cQuery += " LEFT JOIN " + RetSqlName('CTT') + " CTT "
	cQuery += " 	ON CTT.CTT_FILIAL = '" + xFilial('CTT') + "'"
	cQuery += " 	AND CTT.CTT_CUSTO = ABS.ABS_CCUSTO "
	cQuery += "		AND CTT.D_E_L_E_T_ = ' ' "
	cQuery += " LEFT JOIN " + RetSqlName('SA1') + " SA1 "
	cQuery += "		ON SA1.A1_FILIAL = '" + xFilial("SA1") + "' "
	cQuery += " 	AND SA1.A1_COD = ABS.ABS_CLIFAT "
	cQuery += " 	AND SA1.A1_LOJA = ABS.ABS_LJFAT "
	cQuery += " 	AND SA1.D_E_L_E_T_ = ' ' "	
	cQuery += " WHERE ABS.ABS_FILIAL = '" + xFilial('ABS') + "' "
	cQuery += " 	AND ABS.ABS_CODIGO = '" + cCodCli + "' "
	cQuery += " 	AND ABS.ABS_LOJA = '" + cLojCli + "' "
	cQuery += " 	AND ABS.ABS_ENTIDA = '1' "	
	cQuery += "		AND ABS.ABS_LOCAL NOT IN "	
	cQuery += "			(SELECT ABSB.ABS_LOCAL "  
	cQuery += "			FROM " + RetSqlName('ABS') + " ABSB "
	cQuery += "			JOIN " + RetSqlName('AD1') + " AD1 "
	cQuery += "				ON AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += " 			AND AD1.AD1_CODCLI = ABSB.ABS_CODIGO "
	cQuery += " 			AND AD1.AD1_LOJCLI = ABSB.ABS_LOJA "
	cQuery += " 			AND AD1.AD1_STATUS = '9' "
	cQuery += " 			AND AD1.D_E_L_E_T_ = ' ' "	
	cQuery += " 		JOIN " + RetSqlName('ADY') + " ADY "
	cQuery += "				ON ADY.ADY_FILIAL = '"  + xFilial("ADY") + "' "
	cQuery += " 			AND ADY.ADY_STATUS = 'B' "
	cQuery += " 			AND ADY.ADY_OPORTU = AD1.AD1_NROPOR "
	cQuery += " 			AND ADY.ADY_REVISA = AD1.AD1_REVISA "
	cQuery += " 			AND ADY.D_E_L_E_T_ = ' ' "	
	cQuery += " 		JOIN " + RetSqlName('TFJ') + " TFJ "
	cQuery += "				ON TFJ.TFJ_FILIAL = '"  + xFilial("TFJ") + "' "	
	cQuery += " 			AND TFJ.TFJ_PROPOS = ADY.ADY_PROPOS "
	cQuery += " 			AND TFJ.TFJ_PREVIS = ADY.ADY_PREVIS "
	cQuery += " 			AND TFJ.D_E_L_E_T_ = ' ' "	
	cQuery += " 		JOIN " + RetSqlName('TFL') + " TFL "
	cQuery += " 			ON TFL.TFL_FILIAL = '" + xFilial('TFL') + "' "
	cQuery += "				AND TFL.TFL_CODPAI = TFJ.TFJ_CODIGO "
	cQuery += "				AND TFL.TFL_LOCAL = ABS.ABS_LOCAL "
	cQuery += "				AND TFL.D_E_L_E_T_ = ' ' "	
	cQuery += " 		JOIN " + RetSqlName('CN9') + " CN9 "
	cQuery += " 			ON CN9.CN9_FILIAL = '" + xFilial('CN9') + "'"
	cQuery += " 			AND CN9.CN9_NUMERO = TFJ.TFJ_CONTRT "
	cQuery += " 			AND CN9.CN9_REVISA = TFJ.TFJ_CONREV "
	cQuery += "				AND CN9.CN9_REVATU = ' ' " 
	cQuery += " 			AND CN9.CN9_SITUAC = '05' "
	cQuery += "				AND CN9.D_E_L_E_T_ = ' ' "
	cQuery += "			WHERE ABSB.ABS_FILIAL = '" + xFilial('ABS') + "' "
	cQuery += "				AND ABSB.ABS_LOCAL = ABS.ABS_LOCAL "
	cQuery += "				AND ABSB.D_E_L_E_T_ = ' ') " 
	cQuery += "		AND ABS.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY ABS.ABS_LOCAL "
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}	
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->ABS_LOCAL,;
						(cAlias)->ABS_DESCRI,;
						(cAlias)->ABS_RECISS,;
						(cAlias)->ABS_CCUSTO,;							
						(cAlias)->CTT_DESC01,;							
						(cAlias)->ABS_END,;
						(cAlias)->ABS_BAIRRO,;
						(cAlias)->ABS_MUNIC,;
						(cAlias)->ABS_ESTADO,;
						(cAlias)->ABS_CLIFAT,;
						(cAlias)->ABS_LJFAT,;
						(cAlias)->A1_NOME,;							
						.F.;	//Linha nao deletada
		  				})

		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071EqRes
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Equipamentos Reservados"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071EqRes(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"TEW_BAATD",Nil})
	aAdd(aColumns,{"TEW_PRODUT",Nil})
	aAdd(aColumns,{"B1_DESC",Nil})
	aAdd(aColumns,{"TEW_RESCOD",Nil})
	aAdd(aColumns,{"TEW_QTDRES",STR0055})
	aAdd(aColumns,{"TFI_PERINI",Nil})
	aAdd(aColumns,{"TFI_PERFIM",Nil})
	aAdd(aColumns,{"CN9_NUMERO",Nil})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_NROPOR",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aAdd(aColumns,{"TFL_LOCAL",Nil})
	aAdd(aColumns,{"ABS_DESCRI",STR0062})
	aAdd(aColumns,{"TFI_ENTEQP",Nil})
	aAdd(aColumns,{"TFI_COLEQP",Nil})
	aAdd(aColumns,{"TFI_OSMONT",Nil})
	aAdd(aColumns,{"TFJ_TPFRET",Nil})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa		
	cQuery := " SELECT TEW.TEW_BAATD, TEW.TEW_PRODUT, SB1.B1_DESC, TEW.TEW_RESCOD, TFI.TFI_PERINI, " 
	cQuery += " TFI.TFI_PERFIM, TFJ.TFJ_CODIGO, TEW.TEW_QTDRES, TFL.TFL_LOCAL, CN9.CN9_NUMERO, "
	cQuery += " ADY.ADY_PROPOS, AD1.AD1_NROPOR, AD1.AD1_DESCRI, TFL.TFL_LOCAL, ABS.ABS_DESCRI, "
	cQuery += " TFI.TFI_ENTEQP, TFI.TFI_COLEQP, TFI.TFI_OSMONT, TFJ.TFJ_TPFRET " 
	cQuery += " FROM " + RetSqlName('TEW') + " TEW "		
	cQuery += " JOIN " + RetSqlName('TFI') + " TFI "
	cQuery += "		ON TFI.TFI_FILIAL = '"  + xFilial("TFI") + "' "	
	cQuery += " 	AND TFI.TFI_RESERV = TEW.TEW_RESCOD "
	cQuery += " 	AND TFI.TFI_PRODUT = TEW.TEW_PRODUT "
	cQuery += " 	AND TFI.D_E_L_E_T_ = ' ' "
	cQuery += " JOIN " + RetSqlName('TFL') + " TFL "
	cQuery += "		ON TFL.TFL_FILIAL = '"  + xFilial("TFL") + "' "	
	cQuery += " 	AND TFL.TFL_CODIGO = TFI.TFI_CODPAI "
	cQuery += " 	AND TFL.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('TFJ') + " TFJ "
	cQuery += "		ON TFJ.TFJ_FILIAL = '"  + xFilial("TFJ") + "' "
	cQuery += " 	AND TFJ.TFJ_CODIGO = TFL.TFL_CODPAI "
	cQuery += " 	AND TFJ.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('ADY') + " ADY "
	cQuery += "		ON ADY.ADY_FILIAL = '"  + xFilial("ADY") + "' "
	cQuery += " 	AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += " 	AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += " 	AND ADY.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('AD1') + " AD1 "
	cQuery += "		ON AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += " 	AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += " 	AND AD1.AD1_CODCLI = '" + cCodCli + "'"	
	cQuery += " 	AND AD1.AD1_LOJCLI = '" + cLojCli + "'"
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('ABS') + " ABS "
	cQuery += "		ON ABS.ABS_FILIAL = '" + xFilial("ABS") + "' "
	cQuery += "		AND ABS.ABS_LOCAL = TFL.TFL_LOCAL "	
	cQuery += " 	AND ABS.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('SB1') + " SB1 "
	cQuery += "		ON SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
	cQuery += "		AND SB1.B1_COD = TEW.TEW_PRODUT "	
	cQuery += " 	AND SB1.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('CN9') + " CN9 "
	cQuery += " 	ON CN9.CN9_FILIAL = '" + xFilial('CN9') + "'"
	cQuery += " 	AND CN9.CN9_NUMERO = TFJ.TFJ_CONTRT "
	cQuery += " 	AND CN9.CN9_REVISA = TFJ.TFJ_CONREV "
	cQuery += "		AND CN9.CN9_REVATU = ' ' " 
	//cQuery += " 	AND CN9.CN9_SITUAC = '05'"
	cQuery += "		AND CN9.D_E_L_E_T_ = ' ' "			
	cQuery += " WHERE TEW.TEW_FILIAL = '" + xFilial('TEW') + "' "
	cQuery += " 	AND TEW.TEW_RESCOD <> ' ' "
	cQuery += " 	AND TEW.TEW_TIPO = '2' "
	cQuery += " 	AND (TEW.TEW_MOTIVO = '4' OR TEW.TEW_MOTIVO = '5') 
	cQuery += "     AND TEW.TEW_NUMPED = ' '"
	cQuery += "     AND TEW.TEW_NFSAI = ' ' "
	cQuery += "     AND TEW.TEW_SERSAI = ' ' "
	cQuery += "		AND TEW.D_E_L_E_T_ = ' ' "	
	cQuery += " ORDER BY TEW.TEW_BAATD, CN9.CN9_NUMERO "
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}	
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->TEW_BAATD,;
						(cAlias)->TEW_PRODUT,;
						(cAlias)->B1_DESC,;
						(cAlias)->TEW_RESCOD,;
						(cAlias)->TEW_QTDRES,;
						StoD((cAlias)->TFI_PERINI),;
						StoD((cAlias)->TFI_PERFIM),;
						(cAlias)->CN9_NUMERO,;							
						(cAlias)->ADY_PROPOS,;
						(cAlias)->AD1_NROPOR,;							
						(cAlias)->AD1_DESCRI,;
						(cAlias)->TFL_LOCAL,;
						(cAlias)->ABS_DESCRI,;
						Stod((cAlias)->TFI_ENTEQP),;
						Stod((cAlias)->TFI_COLEQP),;
						(cAlias)->TFI_OSMONT,;
						(cAlias)->TFJ_TPFRET,;							
						.F.;	//Linha nao deletada
		  				})

		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071EqLoc
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Equipamentos Locados"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071EqLoc(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"TEW_BAATD",Nil})
	aAdd(aColumns,{"TEW_PRODUT",Nil})
	aAdd(aColumns,{"B1_DESC",Nil})
	aAdd(aColumns,{"TEW_RESCOD",Nil})
	aAdd(aColumns,{"TEW_QTDRES",STR0060})
	aAdd(aColumns,{"TEW_QTDVEN",STR0056})
	aAdd(aColumns,{"TEW_QTDRET",STR0061})
	aAdd(aColumns,{"TEW_DTRINI",Nil})
	aAdd(aColumns,{"TEW_DTRFIM",Nil})
	aAdd(aColumns,{"TEW_DTSEPA",Nil})
	aAdd(aColumns,{"TEW_NUMPED",Nil})
	aAdd(aColumns,{"TEW_ITEMPV",Nil})
	aAdd(aColumns,{"TEW_SERSAI",Nil})
	aAdd(aColumns,{"TEW_NFSAI",Nil})
	aAdd(aColumns,{"TEW_ITSAI",Nil})
	aAdd(aColumns,{"TEW_CODKIT",Nil})
	aAdd(aColumns,{"TEW_KITSEQ",Nil})
	aAdd(aColumns,{"CN9_NUMERO",Nil})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_NROPOR",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aAdd(aColumns,{"TFL_LOCAL",Nil})
	aAdd(aColumns,{"ABS_DESCRI",STR0062})
	aAdd(aColumns,{"TFI_ENTEQP",Nil})
	aAdd(aColumns,{"TFI_COLEQP",Nil})
	aAdd(aColumns,{"TFI_OSMONT",Nil})
	aAdd(aColumns,{"TFJ_TPFRET",Nil})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa		
	cQuery := " SELECT TEW.TEW_BAATD, TEW.TEW_PRODUT, TEW.TEW_RESCOD, TEW.TEW_QTDRES, TEW.TEW_QTDVEN, TEW.TEW_QTDRET, " 
	cQuery += " TEW.TEW_DTRINI, TEW.TEW_DTRFIM, TEW.TEW_DTSEPA, TEW.TEW_NUMPED, TEW.TEW_ITEMPV, TEW.TEW_SERSAI, "
	cQuery += " TEW.TEW_NFSAI, TEW.TEW_ITSAI, TEW.TEW_CODKIT, TEW.TEW_KITSEQ, "
	cQuery += " SB1.B1_DESC, CN9.CN9_NUMERO, ADY.ADY_PROPOS, AD1.AD1_NROPOR, AD1.AD1_DESCRI, TFL.TFL_LOCAL, "	
	cQuery += " ABS.ABS_DESCRI, TFI.TFI_ENTEQP, TFI.TFI_OSMONT, TFJ.TFJ_TPFRET, TFI.TFI_COLEQP " 
	cQuery += " FROM " + RetSqlName('TEW') + " TEW "
	cQuery += " JOIN " + RetSqlName('TFI') + " TFI "
	cQuery += "		ON TFI.TFI_FILIAL = '"  + xFilial("TFI") + "' "	
	cQuery += " 	AND TFI.TFI_COD = TEW.TEW_CODEQU "
	cQuery += " 	AND TFI.TFI_PRODUT = TEW.TEW_PRODUT "
	cQuery += " 	AND TFI.D_E_L_E_T_ = ' ' "
	cQuery += " JOIN " + RetSqlName('TFL') + " TFL "
	cQuery += "		ON TFL.TFL_FILIAL = '"  + xFilial("TFL") + "' "	
	cQuery += " 	AND TFL.TFL_CODIGO = TFI.TFI_CODPAI "
	cQuery += " 	AND TFL.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('TFJ') + " TFJ "
	cQuery += "		ON TFJ.TFJ_FILIAL = '"  + xFilial("TFJ") + "' "
	cQuery += " 	AND TFJ.TFJ_CODIGO = TFL.TFL_CODPAI "
	cQuery += " 	AND TFJ.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('ADY') + " ADY "
	cQuery += "		ON ADY.ADY_FILIAL = '"  + xFilial("ADY") + "' "
	cQuery += " 	AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += " 	AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += " 	AND ADY.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('AD1') + " AD1 "
	cQuery += "		ON AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += " 	AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += " 	AND AD1.AD1_CODCLI = '" + cCodCli + "'"	
	cQuery += " 	AND AD1.AD1_LOJCLI = '" + cLojCli + "'"
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('ABS') + " ABS "
	cQuery += "		ON ABS.ABS_FILIAL = '" + xFilial("ABS") + "' "
	cQuery += "		AND ABS.ABS_LOCAL = TFL.TFL_LOCAL "	
	cQuery += " 	AND ABS.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('SB1') + " SB1 "
	cQuery += "		ON SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
	cQuery += "		AND SB1.B1_COD = TEW.TEW_PRODUT "	
	cQuery += " 	AND SB1.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('CN9') + " CN9 "
	cQuery += " 	ON CN9.CN9_FILIAL = '" + xFilial('CN9') + "'"
	cQuery += " 	AND CN9.CN9_NUMERO = TFJ.TFJ_CONTRT "
	cQuery += " 	AND CN9.CN9_REVISA = TFJ.TFJ_CONREV "
	cQuery += "		AND CN9.CN9_REVATU = ' ' " 
	//cQuery += " 	AND CN9.CN9_SITUAC = '05'"
	cQuery += "		AND CN9.D_E_L_E_T_ = ' ' "				
	cQuery += " WHERE TEW.TEW_FILIAL = '" + xFilial('TEW') + "' "
	cQuery += " 	AND TEW.TEW_TIPO = '1' "
	cQuery += " 	AND TEW.TEW_MOTIVO NOT IN ('4','5') 
	cQuery += " 	AND TEW.TEW_DTSEPA <> ' '"
	cQuery += " 	AND TEW.TEW_DTRINI <> ' '"
	cQuery += " 	AND TEW.TEW_DTRFIM = ' ' "
	cQuery += "     AND TEW.TEW_BAATD <> ' ' "
	cQuery += "		AND TEW.D_E_L_E_T_ = ' ' "	
	cQuery += " ORDER BY TEW.TEW_BAATD, CN9.CN9_NUMERO "	
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->TEW_BAATD,;
						(cAlias)->TEW_PRODUT,;
						(cAlias)->B1_DESC,;
						(cAlias)->TEW_RESCOD,;
						(cAlias)->TEW_QTDRES,;
						(cAlias)->TEW_QTDVEN,;
						(cAlias)->TEW_QTDRET,;
						StoD((cAlias)->TEW_DTRINI),;
						StoD((cAlias)->TEW_DTRFIM),;
						StoD((cAlias)->TEW_DTSEPA),;
						(cAlias)->TEW_NUMPED,;
						(cAlias)->TEW_ITEMPV,;
						(cAlias)->TEW_SERSAI,;
						(cAlias)->TEW_NFSAI,;
						(cAlias)->TEW_ITSAI,;
						(cAlias)->TEW_CODKIT,;
						(cAlias)->TEW_KITSEQ,;
						(cAlias)->CN9_NUMERO,;
						(cAlias)->ADY_PROPOS,;
						(cAlias)->AD1_NROPOR,;
						(cAlias)->AD1_DESCRI,;
						(cAlias)->TFL_LOCAL,;
						(cAlias)->ABS_DESCRI,;
						Stod((cAlias)->TFI_ENTEQP),;
						Stod((cAlias)->TFI_COLEQP),;
						(cAlias)->TFI_OSMONT,;
						(cAlias)->TFJ_TPFRET,;
						.F.;	//Linha nao deletada
		  				})

		(cAlias)->(dbSkip())
	End
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071EqDev
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Equipamentos Devolvidos"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071EqDev(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"TEW_BAATD",Nil})
	aAdd(aColumns,{"TEW_PRODUT",Nil})
	aAdd(aColumns,{"B1_DESC",Nil})
	aAdd(aColumns,{"TEW_RESCOD",Nil})
	aAdd(aColumns,{"TEW_QTDVEN",STR0056})
	aAdd(aColumns,{"TEW_QTDRET",STR0061})
	aAdd(aColumns,{"TEW_DTRINI",Nil})
	aAdd(aColumns,{"TEW_DTRFIM",Nil})
	aAdd(aColumns,{"TEW_DTSEPA",Nil})
	aAdd(aColumns,{"TEW_NUMPED",Nil})
	aAdd(aColumns,{"TEW_ITEMPV",Nil})
	aAdd(aColumns,{"TEW_SERSAI",Nil})
	aAdd(aColumns,{"TEW_NFSAI",Nil})
	aAdd(aColumns,{"TEW_ITSAI",Nil})
	aAdd(aColumns,{"TEW_SERENT",Nil})
	aAdd(aColumns,{"TEW_NFENT",Nil})
	aAdd(aColumns,{"TEW_ITENT",Nil})
	aAdd(aColumns,{"TEW_CODKIT",Nil})
	aAdd(aColumns,{"TEW_KITSEQ",Nil})
	aAdd(aColumns,{"CN9_NUMERO",Nil})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_NROPOR",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aAdd(aColumns,{"TFL_LOCAL",Nil})
	aAdd(aColumns,{"ABS_DESCRI",STR0062})
	aAdd(aColumns,{"TFI_ENTEQP",Nil})
	aAdd(aColumns,{"TFI_COLEQP",Nil})
	aAdd(aColumns,{"TFI_OSMONT",Nil})
	aAdd(aColumns,{"TFJ_TPFRET",Nil})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa		
	cQuery := " SELECT TEW.TEW_BAATD, TEW.TEW_PRODUT, TEW.TEW_RESCOD, TEW.TEW_QTDRES, TEW.TEW_QTDVEN, TEW.TEW_QTDRET, " 
	cQuery += " TEW.TEW_DTRINI, TEW.TEW_DTRFIM, TEW.TEW_DTSEPA, TEW.TEW_NUMPED, TEW.TEW_ITEMPV, TEW.TEW_SERSAI, "
	cQuery += " TEW.TEW_SERENT, TEW.TEW_NFENT, TEW.TEW_ITENT, "
	cQuery += " TEW.TEW_NFSAI, TEW.TEW_ITSAI, TEW.TEW_CODKIT, TEW.TEW_KITSEQ, "
	cQuery += " SB1.B1_DESC, CN9.CN9_NUMERO, ADY.ADY_PROPOS, AD1.AD1_NROPOR, AD1.AD1_DESCRI, TFL.TFL_LOCAL, "	
	cQuery += " ABS.ABS_DESCRI, TFI.TFI_ENTEQP, TFI.TFI_OSMONT, TFJ.TFJ_TPFRET, TFI.TFI_COLEQP " 
	cQuery += " FROM " + RetSqlName('TEW') + " TEW "
	cQuery += " JOIN " + RetSqlName('TFI') + " TFI "
	cQuery += "		ON TFI.TFI_FILIAL = '"  + xFilial("TFI") + "' "	
	cQuery += " 	AND TFI.TFI_COD = TEW.TEW_CODEQU "
	cQuery += " 	AND TFI.TFI_PRODUT = TEW.TEW_PRODUT "
	cQuery += " 	AND TFI.D_E_L_E_T_ = ' ' "
	cQuery += " JOIN " + RetSqlName('TFL') + " TFL "
	cQuery += "		ON TFL.TFL_FILIAL = '"  + xFilial("TFL") + "' "	
	cQuery += " 	AND TFL.TFL_CODIGO = TFI.TFI_CODPAI "
	cQuery += " 	AND TFL.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('TFJ') + " TFJ "
	cQuery += "		ON TFJ.TFJ_FILIAL = '"  + xFilial("TFJ") + "' "
	cQuery += " 	AND TFJ.TFJ_CODIGO = TFL.TFL_CODPAI "
	cQuery += " 	AND TFJ.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('ADY') + " ADY "
	cQuery += "		ON ADY.ADY_FILIAL = '"  + xFilial("ADY") + "' "
	cQuery += " 	AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += " 	AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += " 	AND ADY.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('AD1') + " AD1 "
	cQuery += "		ON AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += " 	AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += " 	AND AD1.AD1_CODCLI = '" + cCodCli + "'"	
	cQuery += " 	AND AD1.AD1_LOJCLI = '" + cLojCli + "'"
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('ABS') + " ABS "
	cQuery += "		ON ABS.ABS_FILIAL = '" + xFilial("ABS") + "' "
	cQuery += "		AND ABS.ABS_LOCAL = TFL.TFL_LOCAL "	
	cQuery += " 	AND ABS.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('SB1') + " SB1 "
	cQuery += "		ON SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
	cQuery += "		AND SB1.B1_COD = TEW.TEW_PRODUT "	
	cQuery += " 	AND SB1.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('CN9') + " CN9 "
	cQuery += " 	ON CN9.CN9_FILIAL = '" + xFilial('CN9') + "'"
	cQuery += " 	AND CN9.CN9_NUMERO = TFJ.TFJ_CONTRT "
	cQuery += " 	AND CN9.CN9_REVISA = TFJ.TFJ_CONREV "
	cQuery += "		AND CN9.CN9_REVATU = ' ' " 
	//cQuery += " 	AND CN9.CN9_SITUAC = '05'"
	cQuery += "		AND CN9.D_E_L_E_T_ = ' ' "				
	cQuery += " WHERE TEW.TEW_FILIAL = '" + xFilial('TEW') + "' "
	cQuery += " 	AND TEW.TEW_TIPO = '1' "
	cQuery += " 	AND TEW.TEW_MOTIVO NOT IN ('4','5') 
	cQuery += " 	AND TEW.TEW_DTSEPA <> ' ' "
	cQuery += " 	AND TEW.TEW_DTRFIM <> ' ' "
	cQuery += "     AND TEW.TEW_BAATD <> ' ' "
	cQuery += "		AND TEW.D_E_L_E_T_ = ' ' "	
	cQuery += " ORDER BY TEW.TEW_BAATD, CN9.CN9_NUMERO "	
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}	
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->TEW_BAATD,;
						(cAlias)->TEW_PRODUT,;
						(cAlias)->B1_DESC,;
						(cAlias)->TEW_RESCOD,;							
						(cAlias)->TEW_QTDVEN,;
						(cAlias)->TEW_QTDRET,;
						StoD((cAlias)->TEW_DTRINI),;
						StoD((cAlias)->TEW_DTRFIM),;
						StoD((cAlias)->TEW_DTSEPA),;
						(cAlias)->TEW_NUMPED,;
						(cAlias)->TEW_ITEMPV,;
						(cAlias)->TEW_SERSAI,;
						(cAlias)->TEW_NFSAI,;
						(cAlias)->TEW_ITSAI,;							
						(cAlias)->TEW_SERENT,;
						(cAlias)->TEW_NFENT,;
						(cAlias)->TEW_ITENT,;							
						(cAlias)->TEW_CODKIT,;
						(cAlias)->TEW_KITSEQ,;
						(cAlias)->CN9_NUMERO,;
						(cAlias)->ADY_PROPOS,;
						(cAlias)->AD1_NROPOR,;
						(cAlias)->AD1_DESCRI,;
						(cAlias)->TFL_LOCAL,;
						(cAlias)->ABS_DESCRI,;
						Stod((cAlias)->TFI_ENTEQP),;
						Stod((cAlias)->TFI_COLEQP),;
						(cAlias)->TFI_OSMONT,;
						(cAlias)->TFJ_TPFRET,;
						.F.;	//Linha nao deletada
		  				})

		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071EqASp
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Equipamentos A Separar"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071EqASp(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"TEW_PRODUT",Nil})
	aAdd(aColumns,{"B1_DESC",Nil})
	aAdd(aColumns,{"TFI_QTDVEN",STR0058})
	aAdd(aColumns,{"TFI_SEPSLD",STR0057})
	aAdd(aColumns,{"TEW_QTDRES",STR0055})
	aAdd(aColumns,{"TEW_RESCOD",Nil})
	aAdd(aColumns,{"TFI_PERINI",Nil})
	aAdd(aColumns,{"TFI_PERFIM",Nil})
	aAdd(aColumns,{"TFI_ENTEQP",Nil})
	aAdd(aColumns,{"TEW_BAATD",Nil})	
	aAdd(aColumns,{"CN9_NUMERO",Nil})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_NROPOR",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aAdd(aColumns,{"TFL_LOCAL",Nil})
	aAdd(aColumns,{"ABS_DESCRI",STR0062})
	aAdd(aColumns,{"TFJ_TPFRET",Nil})
	aAdd(aColumns,{"TFI_OSMONT",Nil})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa		
	cQuery := " SELECT DISTINCT TEW.TEW_PRODUT, TEW.TEW_RESCOD, TEW.TEW_QTDRES, TEW.TEW_BAATD, "	 
	cQuery += " SB1.B1_DESC, TFI.TFI_PERINI, TFI.TFI_PERFIM, TFI.TFI_ENTEQP, TFI.TFI_OSMONT, "
	cQuery += " CN9.CN9_NUMERO, ADY.ADY_PROPOS, AD1.AD1_NROPOR, AD1.AD1_DESCRI, TFL.TFL_LOCAL, "
	cQuery += " ABS.ABS_DESCRI, TFJ.TFJ_TPFRET, TFI.TFI_QTDVEN, TFI.TFI_SEPSLD "
	cQuery += " FROM " + RetSqlName('TEW') + " TEW "
	cQuery += " JOIN " + RetSqlName('TFI') + " TFI "
	cQuery += "		ON TFI.TFI_FILIAL = '"  + xFilial("TFI") + "' "	
	cQuery += " 	AND TFI.TFI_COD = TEW.TEW_CODEQU "
	cQuery += " 	AND TFI.TFI_PRODUT = TEW.TEW_PRODUT "
	cQuery += " 	AND TFI.D_E_L_E_T_ = ' ' "
	cQuery += " JOIN " + RetSqlName('TFL') + " TFL "
	cQuery += "		ON TFL.TFL_FILIAL = '"  + xFilial("TFL") + "' "	
	cQuery += " 	AND TFL.TFL_CODIGO = TFI.TFI_CODPAI "
	cQuery += " 	AND TFL.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('TFJ') + " TFJ "
	cQuery += "		ON TFJ.TFJ_FILIAL = '"  + xFilial("TFJ") + "' "
	cQuery += " 	AND TFJ.TFJ_CODIGO = TFL.TFL_CODPAI "
	cQuery += " 	AND TFJ.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('ADY') + " ADY "
	cQuery += "		ON ADY.ADY_FILIAL = '"  + xFilial("ADY") + "' "
	cQuery += " 	AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += " 	AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += " 	AND ADY.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('AD1') + " AD1 "
	cQuery += "		ON AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += " 	AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += " 	AND AD1.AD1_CODCLI = '" + cCodCli + "'"	
	cQuery += " 	AND AD1.AD1_LOJCLI = '" + cLojCli + "'"
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('ABS') + " ABS "
	cQuery += "		ON ABS.ABS_FILIAL = '" + xFilial("ABS") + "' "
	cQuery += "		AND ABS.ABS_LOCAL = TFL.TFL_LOCAL "	
	cQuery += " 	AND ABS.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('SB1') + " SB1 "
	cQuery += "		ON SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
	cQuery += "		AND SB1.B1_COD = TEW.TEW_PRODUT "	
	cQuery += " 	AND SB1.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('CN9') + " CN9 "
	cQuery += " 	ON CN9.CN9_FILIAL = '" + xFilial('CN9') + "'"
	cQuery += " 	AND CN9.CN9_NUMERO = TFJ.TFJ_CONTRT "
	cQuery += " 	AND CN9.CN9_REVISA = TFJ.TFJ_CONREV "
	cQuery += "		AND CN9.CN9_REVATU = ' ' " 
	cQuery += " 	AND CN9.CN9_SITUAC = '05'"
	cQuery += "		AND CN9.D_E_L_E_T_ = ' ' "				
	cQuery += " WHERE TEW.TEW_FILIAL = '" + xFilial('TEW') + "' "
	cQuery += " 	AND TEW.TEW_TIPO = '1' "
	cQuery += " 	AND TEW.TEW_MOTIVO NOT IN ('4','5') 
	cQuery += " 	AND TEW.TEW_DTRINI = ' ' "
	cQuery += " 	AND TEW.TEW_DTRFIM = ' ' "
	cQuery += " 	AND TEW.TEW_DTSEPA = ' ' "
	cQuery += "		AND TEW.D_E_L_E_T_ = ' ' "	
	cQuery += " ORDER BY TEW.TEW_BAATD, CN9.CN9_NUMERO "	
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->TEW_PRODUT,;
						(cAlias)->B1_DESC,;
						(cAlias)->TFI_QTDVEN,;
						(cAlias)->TFI_SEPSLD,;
						(cAlias)->TEW_QTDRES,;
						(cAlias)->TEW_RESCOD,;
						StoD((cAlias)->TFI_PERINI),;
						StoD((cAlias)->TFI_PERFIM),;
						(cAlias)->TFI_ENTEQP,;
						(cAlias)->TEW_BAATD,;						
						(cAlias)->CN9_NUMERO,;
						(cAlias)->ADY_PROPOS,;
						(cAlias)->AD1_NROPOR,;							
						(cAlias)->AD1_DESCRI,;
						(cAlias)->TFL_LOCAL,;
						(cAlias)->ABS_DESCRI,;							
						(cAlias)->TFJ_TPFRET,;
						(cAlias)->TFI_OSMONT,;
						.F.;	//Linha nao deletada
		  				})
		  				
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071EqSep
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Equipamentos Separados"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071EqSep(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"TEW_PRODUT",Nil})
	aAdd(aColumns,{"B1_DESC",Nil})
	aAdd(aColumns,{"TEW_DTSEPA",Nil})	
	aAdd(aColumns,{"TEW_QTDVEN",STR0056})
	aAdd(aColumns,{"TFI_SEPSLD",STR0057})
	aAdd(aColumns,{"TEW_RESCOD",Nil})
	aAdd(aColumns,{"TFI_PERINI",Nil})
	aAdd(aColumns,{"TFI_PERFIM",Nil})
	aAdd(aColumns,{"TFI_ENTEQP",Nil})
	aAdd(aColumns,{"TEW_BAATD",Nil})
	aAdd(aColumns,{"CN9_NUMERO",Nil})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_NROPOR",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aAdd(aColumns,{"TFL_LOCAL",Nil})
	aAdd(aColumns,{"ABS_DESCRI",STR0062})
	aAdd(aColumns,{"TFJ_TPFRET",Nil})
	aAdd(aColumns,{"TFI_OSMONT",Nil})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa		
	cQuery := " SELECT DISTINCT TEW.TEW_PRODUT, TEW.TEW_RESCOD, TEW.TEW_QTDRES, TEW.TEW_BAATD, "	 
	cQuery += " SB1.B1_DESC, TFI.TFI_PERINI, TFI.TFI_PERFIM, TFI.TFI_ENTEQP, TFI.TFI_OSMONT, "
	cQuery += " CN9.CN9_NUMERO, ADY.ADY_PROPOS, AD1.AD1_NROPOR, AD1.AD1_DESCRI, TFL.TFL_LOCAL, "
	cQuery += " ABS.ABS_DESCRI, TFJ.TFJ_TPFRET, TFI.TFI_SEPSLD, TEW.TEW_QTDVEN, TEW.TEW_DTSEPA "
	cQuery += " FROM " + RetSqlName('TEW') + " TEW "
	cQuery += " JOIN " + RetSqlName('TFI') + " TFI "
	cQuery += "		ON TFI.TFI_FILIAL = '"  + xFilial("TFI") + "' "	
	cQuery += " 	AND TFI.TFI_COD = TEW.TEW_CODEQU "
	cQuery += " 	AND TFI.TFI_PRODUT = TEW.TEW_PRODUT "
	cQuery += " 	AND TFI.D_E_L_E_T_ = ' ' "
	cQuery += " JOIN " + RetSqlName('TFL') + " TFL "
	cQuery += "		ON TFL.TFL_FILIAL = '"  + xFilial("TFL") + "' "	
	cQuery += " 	AND TFL.TFL_CODIGO = TFI.TFI_CODPAI "
	cQuery += " 	AND TFL.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('TFJ') + " TFJ "
	cQuery += "		ON TFJ.TFJ_FILIAL = '"  + xFilial("TFJ") + "' "
	cQuery += " 	AND TFJ.TFJ_CODIGO = TFL.TFL_CODPAI "
	cQuery += " 	AND TFJ.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('ADY') + " ADY "
	cQuery += "		ON ADY.ADY_FILIAL = '"  + xFilial("ADY") + "' "
	cQuery += " 	AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += " 	AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += " 	AND ADY.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('AD1') + " AD1 "
	cQuery += "		ON AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += " 	AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += " 	AND AD1.AD1_CODCLI = '" + cCodCli + "'"	
	cQuery += " 	AND AD1.AD1_LOJCLI = '" + cLojCli + "'"
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('ABS') + " ABS "
	cQuery += "		ON ABS.ABS_FILIAL = '" + xFilial("ABS") + "' "
	cQuery += "		AND ABS.ABS_LOCAL = TFL.TFL_LOCAL "	
	cQuery += " 	AND ABS.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('SB1') + " SB1 "
	cQuery += "		ON SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
	cQuery += "		AND SB1.B1_COD = TEW.TEW_PRODUT "	
	cQuery += " 	AND SB1.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('CN9') + " CN9 "
	cQuery += " 	ON CN9.CN9_FILIAL = '" + xFilial('CN9') + "'"
	cQuery += " 	AND CN9.CN9_NUMERO = TFJ.TFJ_CONTRT "
	cQuery += " 	AND CN9.CN9_REVISA = TFJ.TFJ_CONREV "
	cQuery += "		AND CN9.CN9_REVATU = ' ' " 
	//cQuery += " 	AND CN9.CN9_SITUAC = '05'"
	cQuery += "		AND CN9.D_E_L_E_T_ = ' ' "				
	cQuery += " WHERE TEW.TEW_FILIAL = '" + xFilial('TEW') + "' "
	cQuery += " 	AND TEW.TEW_TIPO = '1' "
	cQuery += " 	AND TEW.TEW_MOTIVO NOT IN ('4','5') 
	cQuery += " 	AND TEW.TEW_DTRINI = ' ' "
	cQuery += " 	AND TEW.TEW_DTRFIM = ' ' "
	cQuery += " 	AND TEW.TEW_DTSEPA <>' ' "
	cQuery += "		AND TEW.D_E_L_E_T_ = ' ' "	
	cQuery += " ORDER BY TEW.TEW_BAATD, CN9.CN9_NUMERO "	
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->TEW_PRODUT,;
						(cAlias)->B1_DESC,;
						Stod((cAlias)->TEW_DTSEPA),;
						(cAlias)->TEW_QTDVEN,;
						(cAlias)->TFI_SEPSLD,;
						(cAlias)->TEW_RESCOD,;
						StoD((cAlias)->TFI_PERINI),;
						StoD((cAlias)->TFI_PERFIM),;
						(cAlias)->TFI_ENTEQP,;
						(cAlias)->TEW_BAATD,;						
						(cAlias)->CN9_NUMERO,;
						(cAlias)->ADY_PROPOS,;
						(cAlias)->AD1_NROPOR,;							
						(cAlias)->AD1_DESCRI,;
						(cAlias)->TFL_LOCAL,;
						(cAlias)->ABS_DESCRI,;							
						(cAlias)->TFJ_TPFRET,;
						(cAlias)->TFI_OSMONT,;
						.F.;	//Linha nao deletada
		  				})
		  				
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071RHPos
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Recursos Humanos - Postos RH"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071RHPos(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"TFF_LOCAL",Nil})
	aAdd(aColumns,{"ABS_DESCRI",STR0062})
	aAdd(aColumns,{"TFF_PRODUT",Nil})
	aAdd(aColumns,{"B1_DESC",Nil})
	aAdd(aColumns,{"TFF_FUNCAO",Nil})	
	aAdd(aColumns,{"RJ_DESC",Nil})
	aAdd(aColumns,{"TFF_CARGO",Nil})
	aAdd(aColumns,{"Q3_DESCSUM",Nil})
	aAdd(aColumns,{"TFF_TURNO",Nil})
	aAdd(aColumns,{"R6_DESC",Nil})
	aAdd(aColumns,{"TFF_QTDVEN",Nil})
	aAdd(aColumns,{"TFF_PERINI",Nil})
	aAdd(aColumns,{"TFF_PERFIM",Nil})
	aAdd(aColumns,{"TFF_HORAIN",Nil})
	aAdd(aColumns,{"TFF_HORAFI",Nil})
	aAdd(aColumns,{"TFF_ESCALA",Nil})
	aAdd(aColumns,{"TDW_DESC",Nil})
	aAdd(aColumns,{"TFF_CALEND",Nil})
	aAdd(aColumns,{"AC0_DESC",Nil})
	aAdd(aColumns,{"CN9_NUMERO",Nil})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_NROPOR",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa		
	cQuery := " SELECT TFF.TFF_LOCAL, ABS.ABS_DESCRI, TFF.TFF_PRODUT, SB1.B1_DESC, "
	cQuery += " TFF.TFF_FUNCAO, SRJ.RJ_DESC, TFF.TFF_CARGO, SQ3.Q3_DESCSUM, TFF.TFF_QTDVEN, "
	cQuery += " TFF.TFF_PERINI, TFF.TFF_PERFIM, TFF.TFF_HORAIN, TFF.TFF_HORAFI, "
	cQuery += " TFF.TFF_ESCALA, TDW.TDW_DESC, TFF.TFF_CALEND, AC0.AC0_DESC, "
	cQuery += " CN9.CN9_NUMERO, ADY.ADY_PROPOS, AD1.AD1_NROPOR, AD1.AD1_DESCRI, TFF.TFF_TURNO, SR6.R6_DESC "	
	cQuery += " FROM " + RetSqlName('TFF') + " TFF "
	cQuery += " JOIN " + RetSqlName('TFL') + " TFL "
	cQuery += "		ON TFL.TFL_FILIAL = '"  + xFilial("TFL") + "' "	
	cQuery += " 	AND TFL.TFL_CODIGO = TFF.TFF_CODPAI "
	cQuery += " 	AND TFL.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('TFJ') + " TFJ "
	cQuery += "		ON TFJ.TFJ_FILIAL = '"  + xFilial("TFJ") + "' "
	cQuery += " 	AND TFJ.TFJ_CODIGO = TFL.TFL_CODPAI "
	cQuery += " 	AND TFJ.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('ADY') + " ADY "
	cQuery += "		ON ADY.ADY_FILIAL = '"  + xFilial("ADY") + "' "
	cQuery += " 	AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += " 	AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += " 	AND ADY.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('AD1') + " AD1 "
	cQuery += "		ON AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += " 	AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += " 	AND AD1.AD1_CODCLI = '" + cCodCli + "'"	
	cQuery += " 	AND AD1.AD1_LOJCLI = '" + cLojCli + "'"
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "
	cQuery += " JOIN " + RetSqlName('ABS') + " ABS "
	cQuery += "		ON ABS.ABS_FILIAL = '" + xFilial("ABS") + "' "
	cQuery += "		AND ABS.ABS_LOCAL = TFF.TFF_LOCAL "	
	cQuery += " 	AND ABS.D_E_L_E_T_ = ' ' "
	cQuery += " JOIN " + RetSqlName('SB1') + " SB1 "
	cQuery += "		ON SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
	cQuery += "		AND SB1.B1_COD = TFF.TFF_PRODUT "	
	cQuery += " 	AND SB1.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('CN9') + " CN9 "
	cQuery += " 	ON CN9.CN9_FILIAL = '" + xFilial('CN9') + "'"
	cQuery += " 	AND CN9.CN9_NUMERO = TFJ.TFJ_CONTRT "
	cQuery += " 	AND CN9.CN9_REVISA = TFJ.TFJ_CONREV "
	cQuery += "		AND CN9.CN9_REVATU = ' ' " 
	cQuery += " 	AND CN9.CN9_SITUAC = '05'"
	cQuery += "		AND CN9.D_E_L_E_T_ = ' ' "				
	cQuery += " JOIN " + RetSqlName('SRJ') + " SRJ "
	cQuery += " 	ON SRJ.RJ_FILIAL = '" + xFilial('SRJ') + "'"
	cQuery += " 	AND SRJ.RJ_FUNCAO = TFF.TFF_FUNCAO "
	cQuery += "		AND SRJ.D_E_L_E_T_ = ' ' "				
	cQuery += " LEFT JOIN " + RetSqlName('SQ3') + " SQ3 "
	cQuery += " 	ON SQ3.Q3_FILIAL = '" + xFilial('SQ3') + "'"
	cQuery += " 	AND SQ3.Q3_CARGO = TFF.TFF_CARGO "
	cQuery += "		AND SQ3.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('TDW') + " TDW "
	cQuery += " 	ON TDW.TDW_FILIAL = '" + xFilial('TDW') + "'"
	cQuery += " 	AND TDW.TDW_COD = TFF.TFF_ESCALA "
	cQuery += "		AND TDW.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('AC0') + " AC0 "
	cQuery += " 	ON AC0.AC0_FILIAL = '" + xFilial('AC0') + "'"
	cQuery += " 	AND AC0.AC0_CODIGO = TFF.TFF_CALEND "
	cQuery += "		AND AC0.D_E_L_E_T_ = ' ' "		
	cQuery += " LEFT JOIN " + RetSqlName('SR6') + " SR6 "
	cQuery += " 	ON SR6.R6_FILIAL = '" + xFilial('SR6') + "'"
	cQuery += " 	AND SR6.R6_TURNO = TFF.TFF_TURNO "
	cQuery += "		AND SR6.D_E_L_E_T_ = ' ' "	
	cQuery += " WHERE TFF.TFF_FILIAL = '" + xFilial('TFF') + "' "
	cQuery += "		AND TFF.D_E_L_E_T_ = ' ' "	
	cQuery += " ORDER BY TFF.TFF_LOCAL, CN9.CN9_NUMERO "	
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->TFF_LOCAL,;
						(cAlias)->ABS_DESCRI,;
						(cAlias)->TFF_PRODUT,;							
						(cAlias)->B1_DESC,;							
						(cAlias)->TFF_FUNCAO,;
						(cAlias)->RJ_DESC,;
						(cAlias)->TFF_CARGO,;
						(cAlias)->Q3_DESCSUM,; 
						(cAlias)->TFF_TURNO,;
						(cAlias)->R6_DESC,;
						(cAlias)->TFF_QTDVEN,;
						StoD((cAlias)->TFF_PERINI),;
						StoD((cAlias)->TFF_PERFIM),;
						(cAlias)->TFF_HORAIN,;							
						(cAlias)->TFF_HORAFI,;
						(cAlias)->TFF_ESCALA,;
						(cAlias)->TDW_DESC,;							
						(cAlias)->TFF_CALEND,;
						(cAlias)->AC0_DESC,;
						(cAlias)->CN9_NUMERO,;
						(cAlias)->ADY_PROPOS,;
						(cAlias)->AD1_NROPOR,;
						(cAlias)->AD1_DESCRI,;
						.F.;	//Linha nao deletada
		  				})
		  				
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071RHAHs
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Recursos Humanos Atendentes (Historico) "
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071RHAHs(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"ABB_CODTEC",Nil})
	aAdd(aColumns,{"AA1_CDFUNC",Nil})
	aAdd(aColumns,{"AA1_NOMTEC",Nil})	
	aAdd(aColumns,{"AA1_FUNCAO",Nil})
	aAdd(aColumns,{"RJ_DESC",Nil})
	aAdd(aColumns,{"TFF_LOCAL",Nil})
	aAdd(aColumns,{"ABS_DESCRI",STR0062})
	aAdd(aColumns,{"AD1_NROPOR",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"CN9_NUMERO",Nil})	
	aAdd(aColumns,{"TFF_PRODUT",Nil})
	aAdd(aColumns,{"B1_DESC",Nil})
	aAdd(aColumns,{"TFF_FUNCAO",Nil})
	aAdd(aColumns,{"RJ_DESC",Nil})
	aAdd(aColumns,{"TFF_CARGO",Nil})
	aAdd(aColumns,{"Q3_DESCSUM",Nil})	
	aAdd(aColumns,{"TFF_TURNO",Nil})
	aAdd(aColumns,{"R6_DESC",Nil})	
	aAdd(aColumns,{"TFF_ESCALA",Nil})
	aAdd(aColumns,{"TDW_DESC",Nil})
	aAdd(aColumns,{"TFF_CALEND",Nil})
	aAdd(aColumns,{"AC0_DESC",Nil})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa		
	cQuery := " SELECT DISTINCT ABB.ABB_CODTEC, AA1.AA1_CDFUNC, AA1.AA1_NOMTEC, AA1.AA1_FUNCAO, SRJF.RJ_DESC DES_FUN_FUN, "
	cQuery += " TFF.TFF_LOCAL, ABS.ABS_DESCRI, AD1.AD1_NROPOR, AD1.AD1_DESCRI, ADY.ADY_PROPOS, CN9.CN9_NUMERO, "
	cQuery += " TFF.TFF_PRODUT, SB1.B1_DESC, TFF.TFF_FUNCAO, SRJP.RJ_DESC DES_FUN_ORC, TFF.TFF_CARGO, SQ3.Q3_DESCSUM, "
	cQuery += " TFF.TFF_TURNO, SR6.R6_DESC, TFF.TFF_ESCALA, TDW.TDW_DESC, TFF.TFF_CALEND, AC0.AC0_DESC " 
	cQuery += " FROM " + RetSqlName('ABB') + " ABB "
	cQuery += " JOIN " + RetSqlName('AA1') + " AA1 "
	cQuery += " 	ON AA1.AA1_FILIAL = '"  + xFilial("AA1") + "' "
	cQuery += "     AND AA1.AA1_CODTEC = ABB.ABB_CODTEC "
	cQuery += " 	AND AA1.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('ABQ') + " ABQ "
	cQuery += " 	ON ABQ.ABQ_FILIAL = '"  + xFilial("ABQ") + "' "
	cQuery += "     AND (ABQ.ABQ_CONTRT || ABQ.ABQ_ITEM || ABQ.ABQ_ORIGEM) = ABB.ABB_IDCFAL "
	cQuery += " 	AND ABQ.D_E_L_E_T_ = ' ' "
	cQuery += " JOIN " + RetSqlName('TFF') + " TFF "
	cQuery += " 	ON TFF.TFF_FILIAL = ABQ.ABQ_FILTFF "
	cQuery += "     AND TFF.TFF_COD = ABQ.ABQ_CODTFF "
	cQuery += "		AND TFF.TFF_CONTRT = ABQ.ABQ_CONTRT "
	cQuery += " 	AND TFF.D_E_L_E_T_ = ' ' "
	cQuery += " JOIN " + RetSqlName('TFL') + " TFL "
	cQuery += "		ON TFL.TFL_FILIAL = '"  + xFilial("TFL") + "' "	
	cQuery += " 	AND TFL.TFL_CODIGO = TFF.TFF_CODPAI "
	cQuery += " 	AND TFL.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('TFJ') + " TFJ "
	cQuery += "		ON TFJ.TFJ_FILIAL = '"  + xFilial("TFJ") + "' "
	cQuery += " 	AND TFJ.TFJ_CODIGO = TFL.TFL_CODPAI "
	cQuery += " 	AND TFJ.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('ADY') + " ADY "
	cQuery += "		ON ADY.ADY_FILIAL = '"  + xFilial("ADY") + "' "
	cQuery += " 	AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += " 	AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += " 	AND ADY.D_E_L_E_T_ = ' ' "
	cQuery += " JOIN " + RetSqlName('AD1') + " AD1 "
	cQuery += "		ON AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += " 	AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += " 	AND AD1.AD1_CODCLI = '" + cCodCli + "'"	
	cQuery += " 	AND AD1.AD1_LOJCLI = '" + cLojCli + "'"
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "
	cQuery += " JOIN " + RetSqlName('ABS') + " ABS "
	cQuery += "		ON ABS.ABS_FILIAL = '" + xFilial("ABS") + "' "
	cQuery += "		AND ABS.ABS_LOCAL = TFF.TFF_LOCAL "	
	cQuery += " 	AND ABS.D_E_L_E_T_ = ' ' "		
	cQuery += " JOIN " + RetSqlName('SB1') + " SB1 "
	cQuery += "		ON SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
	cQuery += "		AND SB1.B1_COD = TFF.TFF_PRODUT "	
	cQuery += " 	AND SB1.D_E_L_E_T_ = ' ' "			
	cQuery += " JOIN " + RetSqlName('CN9') + " CN9 "
	cQuery += " 	ON CN9.CN9_FILIAL = '" + xFilial('CN9') + "'"
	cQuery += " 	AND CN9.CN9_NUMERO = TFJ.TFJ_CONTRT "
	cQuery += " 	AND CN9.CN9_REVISA = TFJ.TFJ_CONREV "
	cQuery += "		AND CN9.CN9_REVATU = ' ' " 
	cQuery += "		AND CN9.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('SRJ') + " SRJP "
	cQuery += " 	ON SRJP.RJ_FILIAL = '" + xFilial('SRJ') + "'"
	cQuery += " 	AND SRJP.RJ_FUNCAO = TFF.TFF_FUNCAO "
	cQuery += "		AND SRJP.D_E_L_E_T_ = ' ' "		
	cQuery += " JOIN " + RetSqlName('SRJ') + " SRJF "
	cQuery += " 	ON SRJF.RJ_FILIAL = '" + xFilial('SRJ') + "'"
	cQuery += " 	AND SRJF.RJ_FUNCAO = AA1.AA1_FUNCAO "
	cQuery += "		AND SRJF.D_E_L_E_T_ = ' ' "				
	cQuery += " LEFT JOIN " + RetSqlName('SQ3') + " SQ3 "
	cQuery += " 	ON SQ3.Q3_FILIAL = '" + xFilial('SQ3') + "'"
	cQuery += " 	AND SQ3.Q3_CARGO = TFF.TFF_CARGO "
	cQuery += "		AND SQ3.D_E_L_E_T_ = ' ' "		
	cQuery += " LEFT JOIN " + RetSqlName('TDW') + " TDW "
	cQuery += " 	ON TDW.TDW_FILIAL = '" + xFilial('TDW') + "'"
	cQuery += " 	AND TDW.TDW_COD = TFF.TFF_ESCALA "
	cQuery += "		AND TDW.D_E_L_E_T_ = ' ' "		
	cQuery += " LEFT JOIN " + RetSqlName('AC0') + " AC0 "
	cQuery += " 	ON AC0.AC0_FILIAL = '" + xFilial('AC0') + "'"
	cQuery += " 	AND AC0.AC0_CODIGO = TFF.TFF_CALEND "
	cQuery += "		AND AC0.D_E_L_E_T_ = ' ' "
	cQuery += " LEFT JOIN " + RetSqlName('SR6') + " SR6 "
	cQuery += " 	ON SR6.R6_FILIAL = '" + xFilial('SR6') + "'"
	cQuery += " 	AND SR6.R6_TURNO = TFF.TFF_TURNO "
	cQuery += "		AND SR6.D_E_L_E_T_ = ' ' "
	cQuery += " WHERE ABB.ABB_FILIAL = '" + xFilial('ABB') + "' "
	cQuery += "		AND ABB.ABB_DTINI < '" + dtos(dDataBase) + "' "
	cQuery += "		AND ABB.ABB_ATIVO = '1' "	
	cQuery += "		AND ABB.D_E_L_E_T_ = ' ' "	
	cQuery += " ORDER BY AA1_NOMTEC, TFF.TFF_LOCAL, CN9.CN9_NUMERO "
	cQuery := ChangeQuery(cQuery)	
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->ABB_CODTEC,;
						(cAlias)->AA1_CDFUNC,;
						(cAlias)->AA1_NOMTEC,;							
						(cAlias)->AA1_FUNCAO,;							
						(cAlias)->DES_FUN_FUN,;
						(cAlias)->TFF_LOCAL,;
						(cAlias)->ABS_DESCRI,;
						(cAlias)->AD1_NROPOR,; 
						(cAlias)->AD1_DESCRI,;
						(cAlias)->ADY_PROPOS,;
						(cAlias)->CN9_NUMERO,;
						(cAlias)->TFF_PRODUT,;
						(cAlias)->B1_DESC,;
						(cAlias)->TFF_FUNCAO,;							
						(cAlias)->DES_FUN_ORC,;
						(cAlias)->TFF_CARGO,;
						(cAlias)->Q3_DESCSUM,;							
						(cAlias)->TFF_TURNO,;
						(cAlias)->R6_DESC,;
						(cAlias)->TFF_ESCALA,;
						(cAlias)->TDW_DESC,;
						(cAlias)->TFF_CALEND,;
						(cAlias)->AC0_DESC,;
						.F.;	//Linha nao deletada
		  				})
		  				
		(cAlias)->(dbSkip())
	End
		
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071RHAFt
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Recursos Humanos Atendentes (Alocados) "
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071RHAFt(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"ABB_CODTEC",Nil})
	aAdd(aColumns,{"AA1_CDFUNC",Nil})
	aAdd(aColumns,{"AA1_NOMTEC",Nil})	
	aAdd(aColumns,{"AA1_FUNCAO",Nil})
	aAdd(aColumns,{"RJ_DESC",Nil})
	aAdd(aColumns,{"TFF_LOCAL",Nil})
	aAdd(aColumns,{"ABS_DESCRI",STR0062})
	aAdd(aColumns,{"AD1_NROPOR",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"CN9_NUMERO",Nil})	
	aAdd(aColumns,{"TFF_PRODUT",Nil})
	aAdd(aColumns,{"B1_DESC",Nil})	
	aAdd(aColumns,{"TFF_FUNCAO",Nil})
	aAdd(aColumns,{"RJ_DESC",Nil})
	aAdd(aColumns,{"TFF_CARGO",Nil})
	aAdd(aColumns,{"Q3_DESCSUM",Nil})	
	aAdd(aColumns,{"TFF_TURNO",Nil})
	aAdd(aColumns,{"R6_DESC",Nil})	
	aAdd(aColumns,{"TFF_ESCALA",Nil})
	aAdd(aColumns,{"TDW_DESC",Nil})
	aAdd(aColumns,{"TFF_CALEND",Nil})
	aAdd(aColumns,{"AC0_DESC",Nil})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa		
	cQuery := " SELECT DISTINCT ABB.ABB_CODTEC, AA1.AA1_CDFUNC, AA1.AA1_NOMTEC, AA1.AA1_FUNCAO, SRJF.RJ_DESC DES_FUN_FUN, "
	cQuery += " TFF.TFF_LOCAL, ABS.ABS_DESCRI, AD1.AD1_NROPOR, AD1.AD1_DESCRI, ADY.ADY_PROPOS, CN9.CN9_NUMERO, "
	cQuery += " TFF.TFF_PRODUT, SB1.B1_DESC, TFF.TFF_FUNCAO, SRJP.RJ_DESC DES_FUN_ORC, TFF.TFF_CARGO, SQ3.Q3_DESCSUM, "
	cQuery += " TFF.TFF_TURNO, SR6.R6_DESC, TFF.TFF_ESCALA, TDW.TDW_DESC, TFF.TFF_CALEND, AC0.AC0_DESC " 
	cQuery += " FROM " + RetSqlName('ABB') + " ABB "
	cQuery += " JOIN " + RetSqlName('AA1') + " AA1 "
	cQuery += " 	ON AA1.AA1_FILIAL = '"  + xFilial("AA1") + "' "
	cQuery += "     AND AA1.AA1_CODTEC = ABB.ABB_CODTEC "
	cQuery += " 	AND AA1.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('ABQ') + " ABQ "
	cQuery += " 	ON ABQ.ABQ_FILIAL = '"  + xFilial("ABQ") + "' "
	cQuery += "     AND (ABQ.ABQ_CONTRT || ABQ.ABQ_ITEM || ABQ.ABQ_ORIGEM) = ABB.ABB_IDCFAL "
	cQuery += " 	AND ABQ.D_E_L_E_T_ = ' ' "
	cQuery += " JOIN " + RetSqlName('TFF') + " TFF "
	//cQuery += " 	ON TFF.TFF_FILIAL = '"  + xFilial("TFF") + "' "
	cQuery += " 	ON TFF.TFF_FILIAL = ABQ.ABQ_FILTFF "
	cQuery += "     AND TFF.TFF_COD = ABQ.ABQ_CODTFF "
	cQuery += "		AND TFF.TFF_CONTRT = ABQ.ABQ_CONTRT "
	cQuery += " 	AND TFF.D_E_L_E_T_ = ' ' "
	cQuery += " JOIN " + RetSqlName('TFL') + " TFL "
	cQuery += "		ON TFL.TFL_FILIAL = '"  + xFilial("TFL") + "' "	
	cQuery += " 	AND TFL.TFL_CODIGO = TFF.TFF_CODPAI "
	cQuery += " 	AND TFL.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('TFJ') + " TFJ "
	cQuery += "		ON TFJ.TFJ_FILIAL = '"  + xFilial("TFJ") + "' "
	cQuery += " 	AND TFJ.TFJ_CODIGO = TFL.TFL_CODPAI "
	cQuery += " 	AND TFJ.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('ADY') + " ADY "
	cQuery += "		ON ADY.ADY_FILIAL = '"  + xFilial("ADY") + "' "
	cQuery += " 	AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += " 	AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += " 	AND ADY.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('AD1') + " AD1 "
	cQuery += "		ON AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += " 	AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += " 	AND AD1.AD1_CODCLI = '" + cCodCli + "'"	
	cQuery += " 	AND AD1.AD1_LOJCLI = '" + cLojCli + "'"
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "
	cQuery += " JOIN " + RetSqlName('ABS') + " ABS "
	cQuery += "		ON ABS.ABS_FILIAL = '" + xFilial("ABS") + "' "
	cQuery += "		AND ABS.ABS_LOCAL = TFF.TFF_LOCAL "	
	cQuery += " 	AND ABS.D_E_L_E_T_ = ' ' "
	cQuery += " JOIN " + RetSqlName('SB1') + " SB1 "
	cQuery += "		ON SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
	cQuery += "		AND SB1.B1_COD = TFF.TFF_PRODUT "	
	cQuery += " 	AND SB1.D_E_L_E_T_ = ' ' "		
	cQuery += " JOIN " + RetSqlName('CN9') + " CN9 "
	cQuery += " 	ON CN9.CN9_FILIAL = '" + xFilial('CN9') + "'"
	cQuery += " 	AND CN9.CN9_NUMERO = TFJ.TFJ_CONTRT "
	cQuery += " 	AND CN9.CN9_REVISA = TFJ.TFJ_CONREV "
	cQuery += "		AND CN9.CN9_REVATU = ' ' " 
	//cQuery += " 	AND CN9.CN9_SITUAC = '05'"
	cQuery += "		AND CN9.D_E_L_E_T_ = ' ' "
	cQuery += " JOIN " + RetSqlName('SRJ') + " SRJP "
	cQuery += " 	ON SRJP.RJ_FILIAL = '" + xFilial('SRJ') + "'"
	cQuery += " 	AND SRJP.RJ_FUNCAO = TFF.TFF_FUNCAO "
	cQuery += "		AND SRJP.D_E_L_E_T_ = ' ' "		
	cQuery += " JOIN " + RetSqlName('SRJ') + " SRJF "
	cQuery += " 	ON SRJF.RJ_FILIAL = '" + xFilial('SRJ') + "'"
	cQuery += " 	AND SRJF.RJ_FUNCAO = AA1.AA1_FUNCAO "
	cQuery += "		AND SRJF.D_E_L_E_T_ = ' ' "			
	cQuery += " LEFT JOIN " + RetSqlName('SQ3') + " SQ3 "
	cQuery += " 	ON SQ3.Q3_FILIAL = '" + xFilial('SQ3') + "'"
	cQuery += " 	AND SQ3.Q3_CARGO = TFF.TFF_CARGO "
	cQuery += "		AND SQ3.D_E_L_E_T_ = ' ' "		
	cQuery += " LEFT JOIN " + RetSqlName('TDW') + " TDW "
	cQuery += " 	ON TDW.TDW_FILIAL = '" + xFilial('TDW') + "'"
	cQuery += " 	AND TDW.TDW_COD = TFF.TFF_ESCALA "
	cQuery += "		AND TDW.D_E_L_E_T_ = ' ' "		
	cQuery += " LEFT JOIN " + RetSqlName('AC0') + " AC0 "
	cQuery += " 	ON AC0.AC0_FILIAL = '" + xFilial('AC0') + "'"
	cQuery += " 	AND AC0.AC0_CODIGO = TFF.TFF_CALEND "
	cQuery += "		AND AC0.D_E_L_E_T_ = ' ' "			
	cQuery += " LEFT JOIN " + RetSqlName('SR6') + " SR6 "
	cQuery += " 	ON SR6.R6_FILIAL = '" + xFilial('SR6') + "'"
	cQuery += " 	AND SR6.R6_TURNO = TFF.TFF_TURNO "
	cQuery += "		AND SR6.D_E_L_E_T_ = ' ' "
	cQuery += " WHERE ABB.ABB_FILIAL = '" + xFilial('ABB') + "' "
	cQuery += "		AND ABB.ABB_DTINI >= '" + dtos(dDataBase) + "' "
	cQuery += "		AND ABB.ABB_ATIVO = '1' "
	cQuery += "		AND ABB.D_E_L_E_T_ = ' ' "	
	cQuery += " ORDER BY AA1_NOMTEC, TFF.TFF_LOCAL, CN9.CN9_NUMERO "	
	cQuery := ChangeQuery(cQuery)
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->ABB_CODTEC,;
						(cAlias)->AA1_CDFUNC,;
						(cAlias)->AA1_NOMTEC,;							
						(cAlias)->AA1_FUNCAO,;							
						(cAlias)->DES_FUN_FUN,;
						(cAlias)->TFF_LOCAL,;
						(cAlias)->ABS_DESCRI,;
						(cAlias)->AD1_NROPOR,; 
						(cAlias)->AD1_DESCRI,;
						(cAlias)->ADY_PROPOS,;
						(cAlias)->CN9_NUMERO,;
						(cAlias)->TFF_PRODUT,;
						(cAlias)->B1_DESC,;
						(cAlias)->TFF_FUNCAO,;							
						(cAlias)->DES_FUN_ORC,;
						(cAlias)->TFF_CARGO,;
						(cAlias)->Q3_DESCSUM,;							
						(cAlias)->TFF_TURNO,;
						(cAlias)->R6_DESC,;
						(cAlias)->TFF_ESCALA,;
						(cAlias)->TDW_DESC,;
						(cAlias)->TFF_CALEND,;
						(cAlias)->AC0_DESC,;
						.F.;	//Linha nao deletada
		  				})
		  				
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071OSTec
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Ordens de Serviço - SIGATEC "
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071OSTec(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"AB7_NUMOS",Nil})
	aAdd(aColumns,{"AB7_ITEM",Nil})
	aAdd(aColumns,{"AB7_CODPRO",Nil})	
	aAdd(aColumns,{"AB7_NUMSER",Nil})
	aAdd(aColumns,{"B1_DESC",Nil})
	aAdd(aColumns,{"AB6_EMISSA",Nil})
	aAdd(aColumns,{"AB6_STATUS",Nil})
	aAdd(aColumns,{"TFI_LOCAL",Nil})
	aAdd(aColumns,{"ABS_DESCRI",STR0062})
	aAdd(aColumns,{"TFJ_CONTRT",Nil})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_NROPOR",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa		
	cQuery := " SELECT DISTINCT AB7.AB7_NUMOS, AB7.AB7_ITEM, AB7.AB7_CODPRO, AB7.AB7_NUMSER, SB1.B1_DESC, "
	cQuery += " AB6.AB6_EMISSA, AB6.AB6_STATUS, TFI.TFI_LOCAL, ABS.ABS_DESCRI, TFJ.TFJ_CONTRT, "
	cQuery += " ADY.ADY_PROPOS, AD1.AD1_NROPOR, AD1.AD1_DESCRI  "
	cQuery += " FROM " + RetSqlName('AB7') + " AB7 "	
	cQuery += " JOIN " + RetSqlName('AB6') + " AB6 "
	cQuery += "		ON AB6.AB6_FILIAL = '"  + xFilial("AB6") + "' "	
	cQuery += " 	AND AB6.AB6_NUMOS = AB7.AB7_NUMOS "
	cQuery += "		AND AB6.AB6_CODCLI = '" + cCodCli + "' "
	cQuery += "		AND AB6.AB6_LOJA  = '" + cLojCli +  "' "
	cQuery += "		AND AB6.AB6_TPORCS <> '3' "
	cQuery += " 	AND AB6.D_E_L_E_T_ = ' ' "
	cQuery += " JOIN " + RetSqlName('SB1') + " SB1 "
	cQuery += "		ON SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
	cQuery += "		AND SB1.B1_COD = AB7.AB7_CODPRO "	
	cQuery += " 	AND SB1.D_E_L_E_T_ = ' ' "
	cQuery += " LEFT JOIN " + RetSqlName('TFJ') + " TFJ "
	cQuery += "		ON TFJ.TFJ_FILIAL = AB6.AB6_FIORCS "
	cQuery += " 	AND TFJ.TFJ_CODIGO = AB6.AB6_CDORCS "
	cQuery += " 	AND TFJ.D_E_L_E_T_ = ' ' "				
	cQuery += " LEFT JOIN " + RetSqlName('TFL') + " TFL "
	cQuery += "		ON TFL.TFL_FILIAL = TFJ.TFJ_FILIAL "	
	cQuery += " 	AND TFL.TFL_CODPAI = TFJ.TFJ_CODIGO "
	cQuery += " 	AND TFL.D_E_L_E_T_ = ' ' "
	cQuery += " LEFT JOIN " + RetSqlName('TFI') + " TFI "
	cQuery += "		ON TFI.TFI_FILIAL = TFJ.TFJ_FILIAL "	
	cQuery += " 	AND TFI.TFI_COD = AB6.AB6_ITORCS "
	cQuery += "		AND TFI.TFI_CODPAI = TFL.TFL_CODIGO "
	cQuery += " 	AND TFI.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('ADY') + " ADY "
	cQuery += "		ON ADY.ADY_FILIAL = '"  + xFilial("ADY") + "' "
	cQuery += " 	AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += " 	AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += " 	AND ADY.D_E_L_E_T_ = ' ' "		
	cQuery += " LEFT JOIN " + RetSqlName('AD1') + " AD1 "
	cQuery += "		ON AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += " 	AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += " 	AND AD1.AD1_CODCLI = AB6.AB6_CODCLI "	
	cQuery += " 	AND AD1.AD1_LOJCLI = AB6.AB6_LOJA "
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('CN9') + " CN9 "
	cQuery += " 	ON CN9.CN9_FILIAL = '" + xFilial('CN9') + "'"
	cQuery += " 	AND CN9.CN9_NUMERO = TFJ.TFJ_CONTRT "
	cQuery += " 	AND CN9.CN9_REVISA = TFJ.TFJ_CONREV "
	cQuery += "		AND CN9.CN9_REVATU = ' ' "
	cQuery += "		AND CN9.D_E_L_E_T_ = ' ' "	
	cQuery += " LEFT JOIN " + RetSqlName('ABS') + " ABS "
	cQuery += "		ON ABS.ABS_FILIAL = '" + xFilial("ABS") + "' "
	cQuery += "		AND ABS.ABS_LOCAL = TFI.TFI_LOCAL "	
	cQuery += " 	AND ABS.D_E_L_E_T_ = ' ' "	
	cQuery += " WHERE AB7.AB7_FILIAL = '" + xFilial('AB7') + "' "
	cQuery += "		AND AB7.D_E_L_E_T_ = ' ' "	
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}	
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->AB7_NUMOS,;
						(cAlias)->AB7_ITEM,;
						(cAlias)->AB7_CODPRO,;							
						(cAlias)->AB7_NUMSER,;							
						(cAlias)->B1_DESC,;
						stod((cAlias)->AB6_EMISSA),;
						(cAlias)->AB6_STATUS,;
						(cAlias)->TFI_LOCAL,; 
						(cAlias)->ABS_DESCRI,;
						(cAlias)->TFJ_CONTRT,;
						(cAlias)->ADY_PROPOS,;
						(cAlias)->AD1_NROPOR,;
						(cAlias)->AD1_DESCRI,;
						.F.;	//Linha nao deletada
		  				})
		  				
		(cAlias)->(dbSkip())
	End
	
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid


//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071OSMnt
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Ordens de Serviço - SIGAMNT "
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071OSMnt(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"TJ_ORDEM",Nil})
	aAdd(aColumns,{"TJ_PLANO",Nil})
	aAdd(aColumns,{"TJ_DTORIGI",Nil})	
	aAdd(aColumns,{"TJ_TIPOOS",Nil})
	aAdd(aColumns,{"TJ_CODBEM",Nil})
	aAdd(aColumns,{"T9_NOME",Nil})
	aAdd(aColumns,{"TJ_POSCONT",Nil})
	aAdd(aColumns,{"TJ_DTPPINI",Nil})
	aAdd(aColumns,{"TJ_DTPPFIM",Nil})
	aAdd(aColumns,{"TJ_DTULTMA",Nil})
	aAdd(aColumns,{"TJ_SERVICO",Nil})
	aAdd(aColumns,{"T4_NOME",Nil})
	aAdd(aColumns,{"TEW_CODEQU",Nil})
	aAdd(aColumns,{"TEW_PRODUT",Nil})
	aAdd(aColumns,{"B1_DESC",Nil})
	aAdd(aColumns,{"TEW_CODMV",Nil})
	aAdd(aColumns,{"TFJ_CONTRT",Nil})
	aAdd(aColumns,{"TFI_LOCAL",Nil})
	aAdd(aColumns,{"ABS_DESCRI",STR0062})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_NROPOR",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa		
	cQuery := " SELECT STJ.TJ_ORDEM, STJ.TJ_PLANO, STJ.TJ_DTORIGI, STJ.TJ_TIPOOS, STJ.TJ_CODBEM, SB1.B1_DESC, "
	cQuery += " STJ.TJ_SERVICO, ST9.T9_NOME, ST4.T4_NOME, TEW.TEW_CODEQU, TEW.TEW_PRODUT, SB1.B1_DESC, TEW.TEW_CODMV, "
	cQuery += " STJ.TJ_POSCONT, STJ.TJ_DTPPINI, STJ.TJ_DTPPFIM, STJ.TJ_DTULTMA, STJ.TJ_CUSTMDO, STJ.TJ_CUSTMAT, "
	cQuery += " TFJ.TFJ_CONTRT, TFI.TFI_LOCAL, ABS.ABS_DESCRI, TFJ.TFJ_CONTRT, "
	cQuery += " ADY.ADY_PROPOS, AD1.AD1_NROPOR, AD1.AD1_DESCRI "	
	cQuery += " FROM " + RetSqlName('STJ') + " STJ "
	cQuery += " JOIN " + RetSqlName('ST9') + " ST9 "
	cQuery += "		ON ST9.T9_FILIAL = '"  + xFilial("ST9") + "' "	
	cQuery += " 	AND ST9.T9_CODBEM = STJ.TJ_CODBEM "
	cQuery += " 	AND ST9.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('ST4') + " ST4 "
	cQuery += "		ON ST4.T4_FILIAL = '"  + xFilial("ST4") + "' "	
	cQuery += " 	AND ST4.T4_SERVICO = STJ.TJ_SERVICO "
	cQuery += " 	AND ST4.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('TEW') + " TEW "
	cQuery += "		ON TEW.TEW_FILIAL = '" + xFilial("TEW") + "' "
	cQuery += "		AND TEW.TEW_NUMOS = STJ.TJ_ORDEM "
	cQuery += "		AND TEW.TEW_TPOS = '2' "	
	cQuery += " 	AND TEW.D_E_L_E_T_ = ' ' "		
	cQuery += " JOIN " + RetSqlName('SB1') + " SB1 "
	cQuery += "		ON SB1.B1_FILIAL = '" + xFilial("SB1") + "' "	
	cQuery += " 	AND SB1.B1_COD = TEW.TEW_PRODUT "
	cQuery += " 	AND SB1.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('TFJ') + " TFJ "
	cQuery += "		ON TFJ.TFJ_FILIAL = '" + xFilial("TFJ") + "' "	
	cQuery += " 	AND TFJ.TFJ_CODIGO = TEW.TEW_ORCSER "
	cQuery += " 	AND TFJ.D_E_L_E_T_ = ' ' "	
	cQuery += " JOIN " + RetSqlName('TFL') + " TFL "
	cQuery += "		ON TFL.TFL_FILIAL = '" + xFilial("TFL") + "'"	
	cQuery += " 	AND TFL.TFL_CODPAI = TFJ.TFJ_CODIGO "
	cQuery += " 	AND TFL.D_E_L_E_T_ = ' ' "
	cQuery += " JOIN " + RetSqlName('TFI') + " TFI "
	cQuery += "		ON TFI.TFI_FILIAL = '" + xFilial("TFI") + "'"	
	cQuery += " 	AND TFI.TFI_PRODUT = TEW.TEW_PRODUT "
	cQuery += "		AND TFI.TFI_CODPAI = TFL.TFL_CODIGO "
	cQuery += " 	AND TFI.D_E_L_E_T_ = ' ' "
	cQuery += " JOIN " + RetSqlName('ADY') + " ADY "
	cQuery += "		ON ADY.ADY_FILIAL = '"  + xFilial("ADY") + "' "
	cQuery += " 	AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += " 	AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += " 	AND ADY.D_E_L_E_T_ = ' ' "			
	cQuery += " JOIN " + RetSqlName('AD1') + " AD1 "
	cQuery += "		ON AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += " 	AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += " 	AND AD1.AD1_CODCLI = '" + cCodCli + "'"	
	cQuery += " 	AND AD1.AD1_LOJCLI = '" + cLojCli + "'"
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "		
	cQuery += " JOIN " + RetSqlName('CN9') + " CN9 "
	cQuery += " 	ON CN9.CN9_FILIAL = '" + xFilial('CN9') + "'"
	cQuery += " 	AND CN9.CN9_NUMERO = TFJ.TFJ_CONTRT "
	cQuery += " 	AND CN9.CN9_REVISA = TFJ.TFJ_CONREV "
	cQuery += "		AND CN9.CN9_REVATU = ' ' " 
	cQuery += "		AND CN9.D_E_L_E_T_ = ' ' "		
	cQuery += " JOIN " + RetSqlName('ABS') + " ABS "
	cQuery += "		ON ABS.ABS_FILIAL = '" + xFilial("ABS") + "' "
	cQuery += "		AND ABS.ABS_LOCAL = TFI.TFI_LOCAL "
	cQuery += " 	AND ABS.D_E_L_E_T_ = ' ' "	
	cQuery += " WHERE STJ.TJ_FILIAL = '" + xFilial('STJ') + "' "
	cQuery += "		AND STJ.D_E_L_E_T_ = ' ' "		
	cQuery += " ORDER BY STJ.R_E_C_N_O_ "		
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->TJ_ORDEM,;
						(cAlias)->TJ_PLANO,;
						stod((cAlias)->TJ_DTORIGI),;							
						(cAlias)->TJ_TIPOOS,;							
						(cAlias)->TJ_CODBEM,;
						(cAlias)->T9_NOME,;
						(cAlias)->TJ_POSCONT,;
						stod((cAlias)->TJ_DTPPINI),;							
						stod((cAlias)->TJ_DTPPFIM),;
						stod((cAlias)->TJ_DTULTMA),;
						(cAlias)->TJ_SERVICO,;
						(cAlias)->T4_NOME,; 
						(cAlias)->TEW_CODEQU,;
						(cAlias)->TEW_PRODUT,;
						(cAlias)->B1_DESC,;
						(cAlias)->TEW_CODMV,;
						(cAlias)->TFJ_CONTRT,;							
						(cAlias)->TFI_LOCAL,;
						(cAlias)->ABS_DESCRI,;							
						(cAlias)->ADY_PROPOS,;
						(cAlias)->AD1_NROPOR,;
						(cAlias)->AD1_DESCRI,;							
						.F.;	//Linha nao deletada
		  				})
		  				
		(cAlias)->(dbSkip())
	End
		
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071GAArm
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Armamentos - Armas"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071GAArm(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"TFQ_ORIGEM",Nil})	
	aAdd(aColumns,{"TER_DESCRI",Nil})
	aAdd(aColumns,{"TFQ_MOTIVO",Nil})	
	aAdd(aColumns,{"TFQ_DESTIN",Nil})
	aAdd(aColumns,{"ABS_DESCRI",STR0062})
	aAdd(aColumns,{"TFQ_DMOVIM",Nil})
	aAdd(aColumns,{"TFQ_RESTRA",STR0065})
	aAdd(aColumns,{"AA1_NOMTEC",STR0066})
	aAdd(aColumns,{"TFQ_STATUS",Nil})
	aAdd(aColumns,{"TFR_CODTEC",STR0067})
	aAdd(aColumns,{"AA1_NOMTEC",STR0068})
	aAdd(aColumns,{"TFO_ITCOD",Nil})
	aAdd(aColumns,{"TE0_CODPRO",Nil})
	aAdd(aColumns,{"B1_DESC",Nil})
	aAdd(aColumns,{"TE0_MARCA",STR0069})
	aAdd(aColumns,{"A2_NOME",STR0070})
	aAdd(aColumns,{"TE0_ESPEC",Nil})
	aAdd(aColumns,{"TE0_CALIBR",Nil})
	aAdd(aColumns,{"TE0_CANO",Nil})
	aAdd(aColumns,{"TE0_QTDCAN",Nil})
	aAdd(aColumns,{"TE0_CAPMUN",Nil})
	aAdd(aColumns,{"TE0_VALIDA",Nil})
	aAdd(aColumns,{"TE0_NUMREG",Nil})
	aAdd(aColumns,{"TFQ_CONTRT",Nil})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_NROPOR",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa		
	cQuery := "SELECT TFQ.TFQ_ORIGEM, TER.TER_DESCRI, TFQ.TFQ_MOTIVO, TFQ.TFQ_DESTIN, ABS.ABS_DESCRI, TFQ.TFQ_DMOVIM, "
	cQuery += " TFQ.TFQ_RESTRA, AA1RES.AA1_NOMTEC ATEN_TRA, TFQ.TFQ_STATUS, TFR.TFR_CODTEC, AA1DES.AA1_NOMTEC ATEN_DES, TFO.TFO_ITCOD, "
	cQuery += " TE0.TE0_CODPRO, SB1.B1_DESC, TE0.TE0_MARCA, SX5.X5_DESCRI,TE0.TE0_ESPEC, TE0.TE0_CALIBR, TE0.TE0_CANO, "
	cQuery += " TE0.TE0_QTDCAN, TE0.TE0_CAPMUN, TE0.TE0_VALIDA, TE0.TE0_NUMREG, TFQ.TFQ_CONTRT, ADY.ADY_PROPOS, "
	cQuery += " AD1.AD1_NROPOR, AD1.AD1_DESCRI "  	
	cQuery += " FROM " + RetSqlName("TFO") + " TFO "	
	cQuery += " JOIN " + RetSqlName("TFQ") + " TFQ "
	cQuery += " 	ON TFQ.TFQ_FILIAL = TFO.TFO_FILIAL "
	cQuery += "		AND TFQ.TFQ_CODIGO = TFO.TFO_CDMOV "
	cQuery += "		AND TFQ.TFQ_ENTORI = '1' "
	cQuery += "		AND TFQ.D_E_L_E_T_ = ' ' "		
	cQuery += " JOIN " + RetSqlName('TFR') + " TFR "
	cQuery += "		ON TFR.TFR_FILIAL = '"  + xFilial("TFR") + "' "
	cQuery += " 	AND TFR.TFR_CODMOV = TFQ.TFQ_CODIGO "
	cQuery += " 	AND TFR.D_E_L_E_T_ = ' ' "					
	cQuery += " JOIN " + RetSqlName('TER') + " TER "
	cQuery += "		ON TER.TER_FILIAL = '"  + xFilial("TER") + "' "
	cQuery += " 	AND TER.TER_CODIGO = TFQ.TFQ_ORIGEM "
	cQuery += " 	AND TER.D_E_L_E_T_ = ' ' "					
	cQuery += " JOIN " + RetSqlName('ABS') + " ABS "
	cQuery += "		ON ABS.ABS_FILIAL = '"  + xFilial("ABS") + "' "
	cQuery += " 	AND ABS.ABS_LOCAL = TFQ.TFQ_DESTIN "	
	cQuery += " 	AND ABS.ABS_ENTIDA = '1' "
	cQuery += " 	AND ABS.ABS_CODIGO = '" + cCodCli + "'"
	cQuery += " 	AND ABS.ABS_LOJA = '" + cLojCli + "'"
	cQuery += " 	AND ABS.D_E_L_E_T_ = ' ' "			
	cQuery += " JOIN " + RetSqlName('AA1') + " AA1RES "
	cQuery += "		ON AA1RES.AA1_FILIAL = '"  + xFilial("AA1") + "' "
	cQuery += " 	AND AA1RES.AA1_CODTEC = TFQ.TFQ_RESTRA "
	cQuery += " 	AND AA1RES.D_E_L_E_T_ = ' ' "			
	cQuery += " JOIN " + RetSqlName('AA1') + " AA1DES "
	cQuery += "		ON AA1DES.AA1_FILIAL = '"  + xFilial("AA1") + "' "
	cQuery += " 	AND AA1DES.AA1_CODTEC = TFR.TFR_CODTEC "
	cQuery += " 	AND AA1DES.D_E_L_E_T_ = ' ' "			
	cQuery += " JOIN " + RetSqlName('TE0') + " TE0 "
	cQuery += "		ON TE0.TE0_FILIAL = '"  + xFilial("TE0") + "' "
	cQuery += " 	AND TE0.TE0_COD = TFO.TFO_ITCOD "
	cQuery += " 	AND TE0.D_E_L_E_T_ = ' ' "			
	cQuery += " JOIN " + RetSqlName('SB1') + " SB1 "
	cQuery += "		ON SB1.B1_FILIAL = '"  + xFilial("SB1") + "' "
	cQuery += " 	AND SB1.B1_COD = TE0.TE0_CODPRO "
	cQuery += " 	AND SB1.D_E_L_E_T_ = ' ' "			
	cQuery += " LEFT JOIN " + RetSqlName('SX5') + " SX5 "
	cQuery += "		ON SX5.X5_FILIAL = '"  + xFilial("SX5") + "' "
	cQuery += " 	AND SX5.X5_TABELA = '79' "
	cQuery += " 	AND SX5.X5_CHAVE = TE0.TE0_MARCA "
	cQuery += " 	AND SX5.D_E_L_E_T_ = ' ' "			
	cQuery += " LEFT JOIN " + RetSqlName('CN9') + " CN9 "
	cQuery += " 	ON CN9.CN9_FILIAL = '" + xFilial('CN9') + "'"
	cQuery += " 	AND CN9.CN9_NUMERO = TFQ.TFQ_CONTRT "
	cQuery += "		AND CN9.CN9_REVATU = ' ' " 
	cQuery += "		AND CN9.D_E_L_E_T_ = ' ' "			
	cQuery += " LEFT JOIN " + RetSqlName('TFJ') + " TFJ "
	cQuery += "		ON TFJ.TFJ_FILIAL = '"  + xFilial("TFJ") + "' "
	cQuery += " 	AND TFJ.TFJ_CONTRT = CN9.CN9_NUMERO "
	cQuery += " 	AND TFJ.TFJ_CONREV = CN9.CN9_REVISA "
	cQuery += " 	AND TFJ.D_E_L_E_T_ = ' ' "			
	cQuery += " LEFT JOIN " + RetSqlName('ADY') + " ADY "
	cQuery += "		ON ADY.ADY_FILIAL = '"  + xFilial("ADY") + "' "
	cQuery += " 	AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += " 	AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += " 	AND ADY.D_E_L_E_T_ = ' ' "				
	cQuery += " LEFT JOIN " + RetSqlName('AD1') + " AD1 "
	cQuery += "		ON AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += " 	AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += " 	AND AD1.AD1_CODCLI = ABS.ABS_CODIGO "	
	cQuery += " 	AND AD1.AD1_LOJCLI = ABS.ABS_LOJA "
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "	
	cQuery += " WHERE TFO.TFO_FILIAL = '" + xFilial('TFO') + "' "
	cQuery += "		AND TFO.TFO_ITMOV = '1' "
	cQuery += "		AND TFO.TFO_ITCOD NOT IN  "
	cQuery += "		( "
	cQuery += "			SELECT TFOV.TFO_ITCOD "
	cQuery += " 		FROM " + RetSqlName("TFO") + " TFOV "	
	cQuery += "			JOIN " + RetSqlName("TFQ") + " TFQV "
	cQuery += "				ON TFQV.TFQ_FILIAL = TFOV.TFO_FILIAL "
	cQuery += "				AND TFQV.TFQ_CODIGO = TFOV.TFO_CDMOV "
	cQuery += "				AND TFQV.TFQ_ENTORI = '2' "
	cQuery += "				AND TFOV.TFO_ITMOV = '1' "
	cQuery += "				AND TFQV.TFQ_ORIGEM = TFQ.TFQ_DESTIN "
	cQuery += "				AND TFOV.TFO_ITCOD = TFO.TFO_ITCOD "
	cQuery += "				AND TFQV.TFQ_DMOVIM > TFQ.TFQ_DMOVIM "			
	cQuery += "				AND TFQV.D_E_L_E_T_ = ' ' "
	cQuery += "			AND TFOV.D_E_L_E_T_ = ' ' "
	cQuery += "			) "
	cQuery += "		AND TFO.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY TFO.R_E_C_N_O_ "		
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}	
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->TFQ_ORIGEM,;
						(cAlias)->TER_DESCRI,;
						(cAlias)->TFQ_MOTIVO,;							
						(cAlias)->TFQ_DESTIN,;							
						(cAlias)->ABS_DESCRI,;
						Stod((cAlias)->TFQ_DMOVIM),;
						(cAlias)->TFQ_RESTRA,;
						(cAlias)->ATEN_TRA,;							
						(cAlias)->TFQ_STATUS,;
						(cAlias)->TFR_CODTEC,;
						(cAlias)->ATEN_DES,;
						(cAlias)->TFO_ITCOD,; 
						(cAlias)->TE0_CODPRO,;
						(cAlias)->B1_DESC,;
						(cAlias)->TE0_MARCA,;
						(cAlias)->X5_DESCRI,;
						(cAlias)->TE0_ESPEC,;							
						(cAlias)->TE0_CALIBR,;
						(cAlias)->TE0_CANO,;							
						(cAlias)->TE0_QTDCAN,;
						(cAlias)->TE0_CAPMUN,;
						Stod((cAlias)->TE0_VALIDA),;
						(cAlias)->TE0_NUMREG,;							
						(cAlias)->TFQ_CONTRT,;
						(cAlias)->ADY_PROPOS,;							
						(cAlias)->AD1_NROPOR,;
						(cAlias)->AD1_DESCRI,;
						.F.;	//Linha nao deletada
		  				})
		  				
		(cAlias)->(dbSkip())
	End
		
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071GACol
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Armamentos - Coletes"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071GACol(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"TFQ_ORIGEM",Nil})	
	aAdd(aColumns,{"TER_DESCRI",Nil})
	aAdd(aColumns,{"TFQ_MOTIVO",Nil})	
	aAdd(aColumns,{"TFQ_DESTIN",Nil})
	aAdd(aColumns,{"ABS_DESCRI",STR0062})
	aAdd(aColumns,{"TFQ_DMOVIM",Nil})
	aAdd(aColumns,{"TFQ_RESTRA",STR0065})
	aAdd(aColumns,{"AA1_NOMTEC",STR0066})
	aAdd(aColumns,{"TFQ_STATUS",Nil})
	aAdd(aColumns,{"TFR_CODTEC",STR0067})
	aAdd(aColumns,{"AA1_NOMTEC",STR0068})
	aAdd(aColumns,{"TFO_ITCOD",Nil})
	aAdd(aColumns,{"TE1_CODPRO",Nil})
	aAdd(aColumns,{"B1_DESC",Nil})
	aAdd(aColumns,{"TE1_MARCA",Nil})
	aAdd(aColumns,{"TE1_TIPO",Nil})
	aAdd(aColumns,{"TE1_MODELO",Nil})
	aAdd(aColumns,{"TE1_PLCDIA",Nil})
	aAdd(aColumns,{"TE1_PLCTRA",Nil})
	aAdd(aColumns,{"TE1_VALIDA",Nil})
	aAdd(aColumns,{"TFQ_CONTRT",Nil})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_NROPOR",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa		
	cQuery := "SELECT TFQ.TFQ_ORIGEM, TER.TER_DESCRI, TFQ.TFQ_MOTIVO, TFQ.TFQ_DESTIN, ABS.ABS_DESCRI, TFQ.TFQ_DMOVIM, "
	cQuery += " TFQ.TFQ_RESTRA, AA1RES.AA1_NOMTEC ATEN_TRA, TFQ.TFQ_STATUS, TFR.TFR_CODTEC, AA1DES.AA1_NOMTEC ATEN_DES, TFO.TFO_ITCOD, "
	cQuery += " TE1.TE1_CODPRO, SB1.B1_DESC, TE1.TE1_MARCA, TE1.TE1_TIPO, TE1.TE1_MODELO, TE1.TE1_PLCDIA, TE1.TE1_PLCTRA, "
	cQuery += " TE1.TE1_VALIDA, TFQ.TFQ_CONTRT, ADY.ADY_PROPOS, "
	cQuery += " AD1.AD1_NROPOR, AD1.AD1_DESCRI "  	
	cQuery += " FROM " + RetSqlName("TFO") + " TFO "	
	cQuery += " JOIN " + RetSqlName("TFQ") + " TFQ "
	cQuery += " 	ON TFQ.TFQ_FILIAL = TFO.TFO_FILIAL "
	cQuery += "		AND TFQ.TFQ_CODIGO = TFO.TFO_CDMOV "
	cQuery += "		AND TFQ.TFQ_ENTORI = '1' "
	cQuery += "		AND TFQ.D_E_L_E_T_ = ' ' "		
	cQuery += " JOIN " + RetSqlName('TFR') + " TFR "
	cQuery += "		ON TFR.TFR_FILIAL = '"  + xFilial("TFR") + "' "
	cQuery += " 	AND TFR.TFR_CODMOV = TFQ.TFQ_CODIGO "
	cQuery += " 	AND TFR.D_E_L_E_T_ = ' ' "					
	cQuery += " JOIN " + RetSqlName('TER') + " TER "
	cQuery += "		ON TER.TER_FILIAL = '"  + xFilial("TER") + "' "
	cQuery += " 	AND TER.TER_CODIGO = TFQ.TFQ_ORIGEM "
	cQuery += " 	AND TER.D_E_L_E_T_ = ' ' "					
	cQuery += " JOIN " + RetSqlName('ABS') + " ABS "
	cQuery += "		ON ABS.ABS_FILIAL = '"  + xFilial("ABS") + "' "
	cQuery += " 	AND ABS.ABS_LOCAL = TFQ.TFQ_DESTIN "	
	cQuery += " 	AND ABS.ABS_ENTIDA = '1' "
	cQuery += " 	AND ABS.ABS_CODIGO = '" + cCodCli + "'"
	cQuery += " 	AND ABS.ABS_LOJA = '" + cLojCli + "'"
	cQuery += " 	AND ABS.D_E_L_E_T_ = ' ' "			
	cQuery += " JOIN " + RetSqlName('AA1') + " AA1RES "
	cQuery += "		ON AA1RES.AA1_FILIAL = '"  + xFilial("AA1") + "' "
	cQuery += " 	AND AA1RES.AA1_CODTEC = TFQ.TFQ_RESTRA "
	cQuery += " 	AND AA1RES.D_E_L_E_T_ = ' ' "			
	cQuery += " JOIN " + RetSqlName('AA1') + " AA1DES "
	cQuery += "		ON AA1DES.AA1_FILIAL = '"  + xFilial("AA1") + "' "
	cQuery += " 	AND AA1DES.AA1_CODTEC = TFR.TFR_CODTEC "
	cQuery += " 	AND AA1DES.D_E_L_E_T_ = ' ' "				
	cQuery += " JOIN " + RetSqlName('TE1') + " TE1 "
	cQuery += "		ON TE1.TE1_FILIAL = '"  + xFilial("TE1") + "' "
	cQuery += " 	AND TE1.TE1_CODCOL = TFO.TFO_ITCOD "
	cQuery += " 	AND TE1.D_E_L_E_T_ = ' ' "				
	cQuery += " JOIN " + RetSqlName('SB1') + " SB1 "
	cQuery += "		ON SB1.B1_FILIAL = '"  + xFilial("SB1") + "' "
	cQuery += " 	AND SB1.B1_COD = TE1.TE1_CODPRO "
	cQuery += " 	AND SB1.D_E_L_E_T_ = ' ' "			
	cQuery += " LEFT JOIN " + RetSqlName('CN9') + " CN9 "
	cQuery += " 	ON CN9.CN9_FILIAL = '" + xFilial('CN9') + "'"
	cQuery += " 	AND CN9.CN9_NUMERO = TFQ.TFQ_CONTRT "
	cQuery += "		AND CN9.CN9_REVATU = ' ' " 
	cQuery += "		AND CN9.D_E_L_E_T_ = ' ' "			
	cQuery += " LEFT JOIN " + RetSqlName('TFJ') + " TFJ "
	cQuery += "		ON TFJ.TFJ_FILIAL = '"  + xFilial("TFJ") + "' "
	cQuery += " 	AND TFJ.TFJ_CONTRT = CN9.CN9_NUMERO "
	cQuery += " 	AND TFJ.TFJ_CONREV = CN9.CN9_REVISA "
	cQuery += " 	AND TFJ.D_E_L_E_T_ = ' ' "			
	cQuery += " LEFT JOIN " + RetSqlName('ADY') + " ADY "
	cQuery += "		ON ADY.ADY_FILIAL = '"  + xFilial("ADY") + "' "
	cQuery += " 	AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += " 	AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += " 	AND ADY.D_E_L_E_T_ = ' ' "				
	cQuery += " LEFT JOIN " + RetSqlName('AD1') + " AD1 "
	cQuery += "		ON AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += " 	AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += " 	AND AD1.AD1_CODCLI = ABS.ABS_CODIGO "	
	cQuery += " 	AND AD1.AD1_LOJCLI = ABS.ABS_LOJA "
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "	
	cQuery += " WHERE TFO.TFO_FILIAL = '" + xFilial('TFO') + "' "
	cQuery += "		AND TFO.TFO_ITMOV = '2' "
	cQuery += "		AND TFO.TFO_ITCOD NOT IN  "
	cQuery += "		( "
	cQuery += "			SELECT TFOV.TFO_ITCOD "
	cQuery += " 		FROM " + RetSqlName("TFO") + " TFOV "	
	cQuery += "			JOIN " + RetSqlName("TFQ") + " TFQV "
	cQuery += "				ON TFQV.TFQ_FILIAL = TFOV.TFO_FILIAL "
	cQuery += "				AND TFQV.TFQ_CODIGO = TFOV.TFO_CDMOV "
	cQuery += "				AND TFQV.TFQ_ENTORI = '2' "
	cQuery += "				AND TFOV.TFO_ITMOV = '2' "
	cQuery += "				AND TFQV.TFQ_ORIGEM = TFQ.TFQ_DESTIN "
	cQuery += "				AND TFOV.TFO_ITCOD = TFO.TFO_ITCOD "
	cQuery += "				AND TFQV.TFQ_DMOVIM > TFQ.TFQ_DMOVIM "			
	cQuery += "				AND TFQV.D_E_L_E_T_ = ' ' "
	cQuery += "			AND TFOV.D_E_L_E_T_ = ' ' "
	cQuery += "			) "
	cQuery += "		AND TFO.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY TFO.R_E_C_N_O_ "		
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}	
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->TFQ_ORIGEM,;
						(cAlias)->TER_DESCRI,;
						(cAlias)->TFQ_MOTIVO,;							
						(cAlias)->TFQ_DESTIN,;							
						(cAlias)->ABS_DESCRI,;
						Stod((cAlias)->TFQ_DMOVIM),;
						(cAlias)->TFQ_RESTRA,;
						(cAlias)->ATEN_TRA,;							
						(cAlias)->TFQ_STATUS,;
						(cAlias)->TFR_CODTEC,;
						(cAlias)->ATEN_DES,;
						(cAlias)->TFO_ITCOD,; 
						(cAlias)->TE1_CODPRO,;
						(cAlias)->B1_DESC,;
						(cAlias)->TE1_MARCA,;
						(cAlias)->TE1_TIPO,;
						(cAlias)->TE1_MODELO,;
						(cAlias)->TE1_PLCDIA,;
						(cAlias)->TE1_PLCTRA,;
						Stod((cAlias)->TE1_VALIDA),;
						(cAlias)->TFQ_CONTRT,;
						(cAlias)->ADY_PROPOS,;							
						(cAlias)->AD1_NROPOR,;
						(cAlias)->AD1_DESCRI,;
						.F.;	//Linha nao deletada
		  				})
		  				
		(cAlias)->(dbSkip())
	End
		
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc071GAMun
Funcao de pesquisa da Central do Cliente que retorna aHeader e aCols da opcao 
"Armamentos - Municoes"
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc071GAMun(cCodCli,cLojCli,dDataDe,dDataAte) 
	Local aGrid 	:= Array(3)
	Local cQuery 	:= ""
	Local aColumns 	:= {}
	Local cAlias	:= GetNextAlias() 
	
	//1* - Monta o aHeader, com os campos necessarios
	aAdd(aColumns,{"TFQ_ORIGEM",Nil})	
	aAdd(aColumns,{"TER_DESCRI",Nil})
	aAdd(aColumns,{"TFQ_MOTIVO",Nil})	
	aAdd(aColumns,{"TFQ_DESTIN",Nil})
	aAdd(aColumns,{"ABS_DESCRI",STR0062})
	aAdd(aColumns,{"TFQ_DMOVIM",Nil})
	aAdd(aColumns,{"TFQ_RESTRA",STR0065})
	aAdd(aColumns,{"AA1_NOMTEC",STR0066})
	aAdd(aColumns,{"TFQ_STATUS",Nil})
	aAdd(aColumns,{"TFR_CODTEC",STR0067})
	aAdd(aColumns,{"AA1_NOMTEC",STR0068})
	aAdd(aColumns,{"TFO_ITCOD",Nil})
	aAdd(aColumns,{"TE2_CODPRO",Nil})
	aAdd(aColumns,{"B1_DESC",Nil})
	aAdd(aColumns,{"TE2_MARCA",Nil})
	aAdd(aColumns,{"TE2_CALIBR",Nil})
	aAdd(aColumns,{"TE2_MODELO",Nil})
	aAdd(aColumns,{"TE2_ESPEC",Nil})
	aAdd(aColumns,{"TE2_QTDMUN",Nil})
	aAdd(aColumns,{"TE2_LOTE",Nil})
	aAdd(aColumns,{"TE2_VALIDA",Nil})
	aAdd(aColumns,{"TFQ_CONTRT",Nil})
	aAdd(aColumns,{"ADY_PROPOS",Nil})
	aAdd(aColumns,{"AD1_NROPOR",Nil})
	aAdd(aColumns,{"AD1_DESCRI",STR0051})
	aGrid[1] := BuildHeader(aColumns)
	
	//2* - Monta a Query de Pesquisa		
	cQuery := "SELECT TFQ.TFQ_ORIGEM, TER.TER_DESCRI, TFQ.TFQ_MOTIVO, TFQ.TFQ_DESTIN, ABS.ABS_DESCRI, TFQ.TFQ_DMOVIM, "
	cQuery += " TFQ.TFQ_RESTRA, AA1RES.AA1_NOMTEC ATEN_TRA, TFQ.TFQ_STATUS, TFR.TFR_CODTEC, AA1DES.AA1_NOMTEC ATEN_DES, TFO.TFO_ITCOD, "
	cQuery += " TE2.TE2_CODPRO, SB1.B1_DESC, TE2.TE2_MARCA, TE2.TE2_MODELO, TE2.TE2_CALIBR, TE2.TE2_ESPEC, TE2.TE2_QTDMUN, TE2.TE2_LOTE, "
	cQuery += " TE2.TE2_VALIDA, TFQ.TFQ_CONTRT, ADY.ADY_PROPOS, "
	cQuery += " AD1.AD1_NROPOR, AD1.AD1_DESCRI "  	
	cQuery += " FROM " + RetSqlName("TFO") + " TFO "	
	cQuery += " JOIN " + RetSqlName("TFQ") + " TFQ "
	cQuery += " 	ON TFQ.TFQ_FILIAL = TFO.TFO_FILIAL "
	cQuery += "		AND TFQ.TFQ_CODIGO = TFO.TFO_CDMOV "
	cQuery += "		AND TFQ.TFQ_ENTORI = '1' "
	cQuery += "		AND TFQ.D_E_L_E_T_ = ' ' "		
	cQuery += " JOIN " + RetSqlName('TFR') + " TFR "
	cQuery += "		ON TFR.TFR_FILIAL = '"  + xFilial("TFR") + "' "
	cQuery += " 	AND TFR.TFR_CODMOV = TFQ.TFQ_CODIGO "
	cQuery += " 	AND TFR.D_E_L_E_T_ = ' ' "					
	cQuery += " JOIN " + RetSqlName('TER') + " TER "
	cQuery += "		ON TER.TER_FILIAL = '"  + xFilial("TER") + "' "
	cQuery += " 	AND TER.TER_CODIGO = TFQ.TFQ_ORIGEM "
	cQuery += " 	AND TER.D_E_L_E_T_ = ' ' "					
	cQuery += " JOIN " + RetSqlName('ABS') + " ABS "
	cQuery += "		ON ABS.ABS_FILIAL = '"  + xFilial("ABS") + "' "
	cQuery += " 	AND ABS.ABS_LOCAL = TFQ.TFQ_DESTIN "	
	cQuery += " 	AND ABS.ABS_ENTIDA = '1' "
	cQuery += " 	AND ABS.ABS_CODIGO = '" + cCodCli + "'"
	cQuery += " 	AND ABS.ABS_LOJA = '" + cLojCli + "'"
	cQuery += " 	AND ABS.D_E_L_E_T_ = ' ' "			
	cQuery += " JOIN " + RetSqlName('AA1') + " AA1RES "
	cQuery += "		ON AA1RES.AA1_FILIAL = '"  + xFilial("AA1") + "' "
	cQuery += " 	AND AA1RES.AA1_CODTEC = TFQ.TFQ_RESTRA "
	cQuery += " 	AND AA1RES.D_E_L_E_T_ = ' ' "			
	cQuery += " JOIN " + RetSqlName('AA1') + " AA1DES "
	cQuery += "		ON AA1DES.AA1_FILIAL = '"  + xFilial("AA1") + "' "
	cQuery += " 	AND AA1DES.AA1_CODTEC = TFR.TFR_CODTEC "
	cQuery += " 	AND AA1DES.D_E_L_E_T_ = ' ' "				
	cQuery += " JOIN " + RetSqlName('TE2') + " TE2 "
	cQuery += "		ON TE2.TE2_FILIAL = '"  + xFilial("TE2") + "' "
	cQuery += " 	AND TE2.TE2_CODMUN = TFO.TFO_ITCOD "
	cQuery += " 	AND TE2.D_E_L_E_T_ = ' ' "				
	cQuery += " JOIN " + RetSqlName('SB1') + " SB1 "
	cQuery += "		ON SB1.B1_FILIAL = '"  + xFilial("SB1") + "' "
	cQuery += " 	AND SB1.B1_COD = TE2.TE2_CODPRO "
	cQuery += " 	AND SB1.D_E_L_E_T_ = ' ' "			
	cQuery += " LEFT JOIN " + RetSqlName('CN9') + " CN9 "
	cQuery += " 	ON CN9.CN9_FILIAL = '" + xFilial('CN9') + "'"
	cQuery += " 	AND CN9.CN9_NUMERO = TFQ.TFQ_CONTRT "
	cQuery += "		AND CN9.CN9_REVATU = ' ' " 
	cQuery += "		AND CN9.D_E_L_E_T_ = ' ' "			
	cQuery += " LEFT JOIN " + RetSqlName('TFJ') + " TFJ "
	cQuery += "		ON TFJ.TFJ_FILIAL = '"  + xFilial("TFJ") + "' "
	cQuery += " 	AND TFJ.TFJ_CONTRT = CN9.CN9_NUMERO "
	cQuery += " 	AND TFJ.TFJ_CONREV = CN9.CN9_REVISA "
	cQuery += " 	AND TFJ.D_E_L_E_T_ = ' ' "			
	cQuery += " LEFT JOIN " + RetSqlName('ADY') + " ADY "
	cQuery += "		ON ADY.ADY_FILIAL = '"  + xFilial("ADY") + "' "
	cQuery += " 	AND ADY.ADY_PROPOS = TFJ.TFJ_PROPOS "
	cQuery += " 	AND ADY.ADY_PREVIS = TFJ.TFJ_PREVIS "
	cQuery += " 	AND ADY.D_E_L_E_T_ = ' ' "				
	cQuery += " LEFT JOIN " + RetSqlName('AD1') + " AD1 "
	cQuery += "		ON AD1.AD1_FILIAL = '" + xFilial("AD1") + "' "
	cQuery += " 	AND AD1.AD1_NROPOR = ADY.ADY_OPORTU "
	cQuery += " 	AND AD1.AD1_CODCLI = ABS.ABS_CODIGO "	
	cQuery += " 	AND AD1.AD1_LOJCLI = ABS.ABS_LOJA "
	cQuery += " 	AND AD1.D_E_L_E_T_ = ' ' "	
	cQuery += " WHERE TFO.TFO_FILIAL = '" + xFilial('TFO') + "' "
	cQuery += "		AND TFO.TFO_ITMOV = '3' "
	cQuery += "		AND TFO.TFO_ITCOD NOT IN  "
	cQuery += "		( "
	cQuery += "			SELECT TFOV.TFO_ITCOD "
	cQuery += " 		FROM " + RetSqlName("TFO") + " TFOV "	
	cQuery += "			JOIN " + RetSqlName("TFQ") + " TFQV "
	cQuery += "				ON TFQV.TFQ_FILIAL = TFOV.TFO_FILIAL "
	cQuery += "				AND TFQV.TFQ_CODIGO = TFOV.TFO_CDMOV "
	cQuery += "				AND TFQV.TFQ_ENTORI = '2' "
	cQuery += "				AND TFOV.TFO_ITMOV = '3' "
	cQuery += "				AND TFQV.TFQ_ORIGEM = TFQ.TFQ_DESTIN "
	cQuery += "				AND TFOV.TFO_ITCOD = TFO.TFO_ITCOD "
	cQuery += "				AND TFQV.TFQ_DMOVIM > TFQ.TFQ_DMOVIM "			
	cQuery += "				AND TFQV.D_E_L_E_T_ = ' ' "
	cQuery += "			AND TFOV.D_E_L_E_T_ = ' ' "
	cQuery += "			) "
	cQuery += "		AND TFO.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY TFO.R_E_C_N_O_ "		
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.)
	
	//3* Monta aCols de Retorno
	aGrid[2] := {}	
	While (!(cAlias)->(Eof()))
		aAdd(aGrid[2],{(cAlias)->TFQ_ORIGEM,;
						(cAlias)->TER_DESCRI,;
						(cAlias)->TFQ_MOTIVO,;							
						(cAlias)->TFQ_DESTIN,;							
						(cAlias)->ABS_DESCRI,;
						Stod((cAlias)->TFQ_DMOVIM),;
						(cAlias)->TFQ_RESTRA,;
						(cAlias)->ATEN_TRA,;							
						(cAlias)->TFQ_STATUS,;
						(cAlias)->TFR_CODTEC,;
						(cAlias)->ATEN_DES,;
						(cAlias)->TFO_ITCOD,; 
						(cAlias)->TE2_CODPRO,;
						(cAlias)->B1_DESC,;
						(cAlias)->TE2_MARCA,;
						(cAlias)->TE2_CALIBR,;
						(cAlias)->TE2_MODELO,;
						(cAlias)->TE2_ESPEC,;
						(cAlias)->TE2_QTDMUN,;
						(cAlias)->TE2_LOTE,;
						Stod((cAlias)->TE2_VALIDA),;
						(cAlias)->TFQ_CONTRT,;
						(cAlias)->ADY_PROPOS,;							
						(cAlias)->AD1_NROPOR,;
						(cAlias)->AD1_DESCRI,;
						.F.;	//Linha nao deletada
		  				})
		  						  				
		(cAlias)->(dbSkip())
	End
		
	//4* Coloca a query no aGrid para uso futuro na impressao do relatorio
	aGrid[3] := cQuery
	(cAlias)->(dbCloseArea())
	
Return aGrid

//------------------------------------------------------------------------------
/*/{Protheus.doc} BuildHeader
Devolve um array no layout da aHeader para uso na MsNewGetDados
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function BuildHeader(aFields)
	Local aArea	     := GetArea()
	Local aRet       := {}
	Local nI 		 := 0
	Local cTitle	 := ""

	dbSelectArea('SX3')
	SX3->(dbSetOrder(2))
	For nI := 1 to len(aFields)
		If SX3->(dbSeek(aFields[nI,1]))
			
			//Identifica o titulo na GetDados
			If !Empty(aFields[nI,2])
				cTitle := aFields[nI,2]
			Else
				cTitle := alltrim(X3Titulo())
			EndIf
			
			//Monta o retorno de acordo com o padrão da MsNewGetDados
			aAdd( aRet,{ cTitle,;
					SX3->X3_CAMPO	,;
					SX3->X3_PICTURE	,;
					SX3->X3_TAMANHO	,;
					SX3->X3_DECIMAL	,;
					".T."			,;
					SX3->X3_USADO	,;
					SX3->X3_TIPO	,;
					SX3->X3_F3		,;
					SX3->X3_CONTEXT	,;
					SX3->X3_CBOX	,;
					" "				,;	//SX3->X3_RELACAO  
					".T."			,;
					SX3->X3_VISUAL	,;
					SX3->X3_VLDUSER	,;
					SX3->X3_PICTVAR	})
			
		EndIf
	Next nI

	RestArea(aArea)

Return aRet