#Include 'Protheus.ch'
#INCLUDE 'TOPCONN.CH'
#INCLUDE 'TECR890A.CH'

 //-------------------------------------------------------------------------
/*/{Protheus.doc}  TECR890

Impressão de apontamento de materiais

@sample  TECR890() 
@author  Leandro Fini
@since 	  05/07/2018
@version P12
/*/
//-------------------------------------------------------------------------
Function TECR890A()
	Local oReport := NIL
	Local cPerg:= Padr("TECR890A",10)

/*
PARAMETROS:
MV_PAR01 - CONTRATO / SERVICO EXTRA
MV_PAR02 - DATA DE
MV_PAR03 - DATA ATE
MV_PAR04 - DO ORCAMENTO
MV_PAR05 - ATE ORCAMENTO
MV_PAR06 - DO CONTRATO
MV_PAR07 - ATE CONTRATO
MV_PAR08 - DO PRODUTO
MV_PAR09 - ATE PRODUTO
*/

	Pergunte(cPerg,.F.)	          
		
	oReport := ReportDef(cPerg)
	oReport:PrintDialog()
Return
 //------------------------------------------------------------------------
/*/{Protheus.doc}  ReportDef

Definições do relatório

@sample  ReportDef() 
@author  Leandro Fini
@since 	  05/07/2018
@version P12
/*/
//-------------------------------------------------------------------------
Static Function ReportDef(cNome)
Local oReport	 := Nil
Local oSection1	 := Nil
Local oSection2	 := Nil
Local oSection3	 := Nil
Local oBreak
Local oFunction
	
	/*Sintaxe: TReport():New(cNome,cTitulo,cPerguntas,bBlocoCodigo,cDescricao)*/
	oReport := TReport():New(cNome,STR0001,cNome,{|oReport| ReportPrint(oReport)},STR0001) //"Relação de apontamentos de materiais" 
	oReport:SetPortrait()    
	oReport:SetTotalInLine(.F.)
	
	//SESSAO 1----------CABEÇALHO DOS LOCAIS--------------------------------------------//
	oSection1:= TRSection():New(oReport, STR0002, {"TFL"}, , .F., .T.)//"Dados alocaçao Material"
	TRCell():New(oSection1,"TFL_FILIAL"		,"SEC1",STR0003,,,,,"LEFT",,"LEFT")//Filial
	If MV_PAR01 = 1
		TRCell():New(oSection1,"TFL_CODPAI"  ,"SEC1",STR0004,,,,,"LEFT",,"LEFT")//"Orçamento"
	Else
		TRCell():New(oSection1,"TFL_CODPAI"  ,"SEC1",STR0005,,,,,"LEFT",,"LEFT")//Serviço Extra
	EndIf
	If MV_PAR01 = 1
		TRCell():New(oSection1,"TFL_CONTRT"  ,"SEC1",STR0006,,,,,"LEFT",,"LEFT")//Contrato
		TRCell():New(oSection1,"TFL_CONREV"  ,"SEC1",STR0007,,,,,"LEFT",,"LEFT")//Revisao
	EndIf
	TRCell():New(oSection1,"TFL_LOCAL"  ,"SEC1",STR0008,,,,,"LEFT",,"LEFT")//Local
	TRCell():New(oSection1,"ABS_DESCRI"  ,"SEC1",STR0009,,,,,"LEFT",,"LEFT")//Nome do Local
	TRCell():New(oSection1,"ABS_CODIGO"  ,"SEC1",STR0010,,,,,"LEFT",,"LEFT")//Cod. do Cliente
	TRCell():New(oSection1,"ABS_LOJA"  ,"SEC1",STR0011,,,,,"LEFT",,"LEFT")//Lj do Cliente
	TRCell():New(oSection1,"A1_NOME"  ,"SEC1",STR0012,,,,,"LEFT",,"LEFT")//Nome do Cliente
	
	//SESSAO 2----------MATERIAL DE IMPLANTACAO--------------------------------------------//
	oSection2:= TRSection():New(oReport,STR0013,{"TFS"},,,,,,,,,,10) //-->10 = move a sessao 10 caracteres para o lado --Materiais de Implantaçao
	TRCell():New(oSection2,"TFS_PRODUT" 	 ,"SEC2",STR0014,,,,,"LEFT",,"LEFT")//"Mat. de Implantaçao"
	TRCell():New(oSection2,"B1_DESC" 		 ,"SEC2",STR0015,,,,,"LEFT",,"LEFT")//Descriçao
	TRCell():New(oSection2,"TFS_QUANT"  	 ,"SEC2",STR0016,,,,,"LEFT",,"LEFT")//Quantidade
	TRCell():New(oSection2,"TFS_DTAPON" 	 ,"SEC2",STR0017,,,,,"LEFT",,"LEFT")	//Data do Apontamento
	
	//SESSAO 3----------MATERIAL DE CONSUMO--------------------------------------------//
	oSection3:= TRSection():New(oReport,STR0018,{"TFT"},,,,,,,,,,10)//-->10 = move a sessao 10 caracteres para o lado -- Materiais de Consumo
	TRCell():New(oSection3,"TFT_PRODUT"  	,"SEC3",STR0019,,,,,"LEFT",,"LEFT")//Mat. de Consumo
	TRCell():New(oSection3,"B1_DESC"  		,"SEC3",STR0015,,,,,"LEFT",,"LEFT")//Descriçao
	TRCell():New(oSection3,"TFT_QUANT"  	,"SEC3",STR0016,,,,,"LEFT",,"LEFT")//Quantidade
	TRCell():New(oSection3,"TFT_DTAPON"  	,"SEC3",STR0017,,,,,"LEFT",,"LEFT")//Data do Apontamento
       
    //Desativado quebra de pagina por sessão.
	oSection1:SetPageBreak(.F.)
	oSection1:SetTotalText(" ")				
Return(oReport)
  //------------------------------------------------------------------------
/*/{Protheus.doc}  ReportPrint

Impressão do relatório

@sample  ReportPrint() 
@author  Leandro Fini
@since 	  05/07/2018
@version P12
/*/
//-------------------------------------------------------------------------
Static Function ReportPrint(oReport)

Local oSection1 := oReport:Section(1)
Local oSection2 := oReport:Section(2)	 
Local oSection3 := oReport:Section(3)
Local cAliasSec1	:= GetNextAlias()
Local cAliasSec2	:= GetNextAlias()
Local cAliasSec3	:= GetNextAlias()
Local cDataTFS		:= ""
Local cDataTFT		:= ""
Local cQrySec1      := ""	
Local cQrySec2    	:= ""	
Local cQrySec3    	:= ""	
Local cLocal		:= ""	        

cQrySec1 := "SELECT TFL_FILIAL, TFL_CODIGO, TFL_LOCAL, TFL_CODPAI, TFL_CONTRT, TFL_CONREV, ABS_DESCRI, ABS_CODIGO, ABS_LOJA, A1_NOME"
cQrySec1 += "	FROM "+RETSQLNAME("TFL")+" TFL "
cQrySec1 += "	JOIN "+RETSQLNAME("ABS")+" ABS "
cQrySec1 += "	ON ABS_LOCAL = TFL_LOCAL "
cQrySec1 += "	JOIN "+RETSQLNAME("SA1")+" SA1 "
cQrySec1 += "	ON ABS_CODIGO = A1_COD "
cQrySec1 += "	AND ABS_LOJA = A1_LOJA "
cQrySec1 += "	AND ABS.D_E_L_E_T_ = ' ' "
cQrySec1 += " AND TFL.D_E_L_E_T_ = ' ' "
cQrySec1 += " AND SA1.D_E_L_E_T_ = ' ' "
If MV_PAR01 = 2 
	cQrySec1 += " AND TFL.TFL_CODPAI BETWEEN '"+ MV_PAR04 +"' AND '"+ MV_PAR05 +"' "
	cQrySec1 += " AND TFL.TFL_CONTRT = ' '
Else
	 cQrySec1 += " AND TFL.TFL_CODPAI <> ' '
EndIf
If MV_PAR01 = 1
	cQrySec1 += " AND TFL.TFL_CONTRT BETWEEN '"+ MV_PAR06 +"' AND '"+ MV_PAR07 +"' "
	cQrySec1 += " AND TFL.TFL_CONTRT <> ' '
Else
	cQrySec1 += " AND TFL.TFL_CONTRT <> ' '
EndIf
	
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQrySec1),cAliasSec1,.T.,.T.)

oReport:SetMeter((cAliasSec1)->(RecCount()))	

(cAliasSec1)->(DbGoTop())

		
While (cAliasSec1)->(!Eof())
	
	//PEGA CODIGO DO LOCAL
	cCodLocal 	:= (cAliasSec1)->TFL_CODIGO
	
	//QUERY SESSAO 2------------MATERIAL DE IMPLANTACAO----------------------------//
	cQrySec2 := "SELECT TFS_PRODUT, B1_DESC, TFS_QUANT, TFS_DTAPON, TFS_CODTFL"
	cQrySec2 += "	FROM "+RETSQLNAME("TFS")+" TFS "
	cQrySec2 += "	JOIN "+RETSQLNAME("SB1")+" SB1 "
	cQrySec2 += "	ON B1_COD = TFS_PRODUT "
	cQrySec2 += "	AND SB1.D_E_L_E_T_ = ' ' "
	cQrySec2 += " AND TFS.D_E_L_E_T_ = ' ' "
	cQrySec2 += " AND TFS.TFS_CODTFL = '"+ cCodLocal +"' "
	If !EMPTY(MV_PAR03)
		cQrySec2 += " AND TFS.TFS_DTAPON BETWEEN '"+ DtoS(MV_PAR02) +"' AND '"+ DtoS(MV_PAR03) +"' "
	Else
		 cQrySec2 += " AND TFS.TFS_DTAPON <> ' '
	EndIf
	If !EMPTY(MV_PAR09)
		cQrySec2 += " AND TFS.TFS_PRODUT BETWEEN '"+ MV_PAR08 +"' AND '"+ MV_PAR09 +"' "
	Else
		cQrySec2 += " AND TFS.TFS_PRODUT <> ' '
	EndIf
	
	//QUERY SESSAO 3------------MATERIAL DE CONSUMO-------------------------------//
	cQrySec3 := "SELECT TFT_PRODUT, B1_DESC, TFT_QUANT, TFT_DTAPON, TFT_CODTFL"
	cQrySec3 += "	FROM "+RETSQLNAME("TFT")+" TFT "
	cQrySec3 += "	JOIN "+RETSQLNAME("SB1")+" SB1 "
	cQrySec3 += "	ON B1_COD = TFT_PRODUT "
	cQrySec3 += "	AND SB1.D_E_L_E_T_ = ' ' "
	cQrySec3 += " AND TFT.D_E_L_E_T_ = ' ' "
	cQrySec3 += " AND TFT.TFT_CODTFL = '"+ cCodLocal +"' "
	If !EMPTY(MV_PAR03)
		cQrySec3 += " AND TFT.TFT_DTAPON BETWEEN '"+ DtoS(MV_PAR02) +"' AND '"+ DtoS(MV_PAR03) +"' "
	Else
		 cQrySec3 += " AND TFT.TFT_DTAPON <> ' '
	EndIf
	If !EMPTY(MV_PAR09)
		cQrySec3 += " AND TFT.TFT_PRODUT BETWEEN '"+ MV_PAR08 +"' AND '"+ MV_PAR09 +"' "
	Else
		cQrySec3 += " AND TFT.TFT_PRODUT <> ' '
	EndIf
	
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQrySec2),cAliasSec2,.T.,.T.)
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQrySec3),cAliasSec3,.T.,.T.)
	
	If Empty((cAliasSec2)->TFS_PRODUT) .AND. Empty((cAliasSec3)->TFT_PRODUT)
		(cAliasSec2)->(DbCloseArea())
		(cAliasSec3)->(DbCloseArea())
		(cAliasSec1)->(DbSkip())
		Loop
	EndIf
	
	If oReport:Cancel()
		Exit
	EndIf

 //	---------------- --------- ---------------------//		
 //	---------------- SECTION 1 ---------------------//
 //	------------------------------------------------//
	oSection1:Init()
 
	oReport:IncMeter()
	IncProc(STR0020 + cCodLocal)//Imprimindo Local

	//Imprimo a primeira sessão			
	oSection1:Cell("TFL_FILIAL"):SetValue((cAliasSec1)->TFL_FILIAL)
	oSection1:Cell("TFL_CODPAI"):SetValue((cAliasSec1)->TFL_CODPAI)
	If MV_PAR01 = 1	
		oSection1:Cell("TFL_CONTRT"):SetValue((cAliasSec1)->TFL_CONTRT)	
		oSection1:Cell("TFL_CONREV"):SetValue((cAliasSec1)->TFL_CONREV)	
	EndIf
	oSection1:Cell("TFL_LOCAL"):SetValue((cAliasSec1)->TFL_LOCAL)		
	oSection1:Cell("ABS_DESCRI"):SetValue(Alltrim((cAliasSec1)->ABS_DESCRI))		
	oSection1:Cell("ABS_CODIGO"):SetValue(Alltrim((cAliasSec1)->ABS_CODIGO))
	oSection1:Cell("ABS_LOJA"):SetValue(Alltrim((cAliasSec1)->ABS_LOJA))
	oSection1:Cell("A1_NOME"):SetValue(Alltrim((cAliasSec1)->A1_NOME))
	oSection1:Printline()


	//	---------------- --------- ---------------------//		
	//	---------------- SECTION 2 ---------------------//
	//	------------------------------------------------//
	oSection2:init()
		
	oReport:SetMeter((cAliasSec2)->(RecCount()))	
	
	//Codigo do Local deve ser o mesmo
	While (cAliasSec2)->TFS_CODTFL == cCodLocal
		oReport:IncMeter()		
	
		//Imprimo a segunda sessão	
		oSection2:Cell("TFS_PRODUT"):SetValue(Alltrim((cAliasSec2)->TFS_PRODUT))	
		oSection2:Cell("B1_DESC"):SetValue(Alltrim((cAliasSec2)->B1_DESC))	
		oSection2:Cell("TFS_QUANT"):SetValue((cAliasSec2)->TFS_QUANT)	
		oSection2:Cell("TFS_DTAPON"):SetValue(StoD((cAliasSec2)->TFS_DTAPON))						
		oSection2:Printline()

		(cAliasSec2)->(DbSkip())
	EndDo		
	//---------------- --------- ---------------------//		
	//---------------- SECTION 3 ---------------------//
	//------------------------------------------------//
	oSection3:init()
	
	oReport:SetMeter((cAliasSec3)->(RecCount()))	
	
	//Verifico se o codigo do local é o mesmo
	While (cAliasSec3)->TFT_CODTFL == cCodLocal
		oReport:IncMeter()		
		
		//Imprimo a terceira sessão	
		oSection3:Cell("TFT_PRODUT"):SetValue((cAliasSec3)->TFT_PRODUT)	
		oSection3:Cell("B1_DESC"):SetValue(Alltrim((cAliasSec3)->B1_DESC))	
		oSection3:Cell("TFT_QUANT"):SetValue((cAliasSec3)->TFT_QUANT)	
		oSection3:Cell("TFT_DTAPON"):SetValue(StoD((cAliasSec3)->TFT_DTAPON))					
		oSection3:Printline()

		(cAliasSec3)->(DbSkip())
	EndDo		
	
	
	//Finalizo a segunda sessão
	oSection2:Finish()
	(cAliasSec2)->(DbCloseArea())
	
	//Finalizo a terceira sessão
	oSection3:Finish()
	(cAliasSec3)->(DbCloseArea())
	
	//Imprimo a linha para separar
	oReport:ThinLine()
	
	//Finalizo a primeira sessão
	oSection1:Finish()
	
	//Passa para o próximo Local
	(cAliasSec1)->(DbSkip())
	
Enddo //(cAliasSec1)->(!Eof())
	
	(cAliasSec1)->(DbCloseArea())

Return

 //-------------------------------------------------------------------------
/*/{Protheus.doc}  TR890VLD()

Validação do pergunte TECR890A

@sample  TR890VLD() 
@author  Leandro Fini
@since 	  10/07/2018
@version P12
/*/
//-------------------------------------------------------------------------

Function TR890VLD(cOpcao)

//cOpcao = 1 -> Contrato / 2 -> Servico Extra
Local lRet := .T.

If cOpcao == 1 
	MV_PAR04 := Space(TamSX3("TFL_CODPAI")[1]) //Do Sv Extra
	MV_PAR05 := Space(TamSX3("TFL_CODPAI")[1]) //Ate Sv Extra
Else
	MV_PAR06 := Space(TamSX3("TFL_CONTRT")[1])//Do Contrato
	MV_PAR07 := Space(TamSX3("TFL_CONTRT")[1])//Ate Contrato
EndIf

Return lRet