#Include "Protheus.ch"
#Include "FwMVCDEF.ch"
#Include "TECA998.ch"

Static oFWSheet
Static oModel740

//------------------------------------------------------------------------------
/*/{Protheus.doc} TECA998
Planilha de cálculo no orçamento de serviços
@sample 	TECA998() 
@param		oModel -> Objeto do modelo
@since		22/10/2013       
@version	P11.9
/*/
//------------------------------------------------------------------------------
Function TECA998(oModel,oView)

Local oMdlRh	:= oModel:GetModel("TFF_RH")
Local oMdlLE	:= oModel:GetModel("TFI_LE")
Local oMdlLEa	:= oModel:GetModel("TEV_ADICIO")
Local cManip	:= ""
Local cRet		:= ""
Local cModelo	:= ""
Local oDlg
Local oOpcao
Local oBtn
Local nOpcao	:= 1
Local nOpcOk	:= 0
Local lLocEq	:= .F. 

Default oView := Nil

If oView <> Nil
	lLocEq := Upper(oView:GetFolderActive('ABAS', 2)[2]) == STR0014 // 'LOCAÇÃO DE EQUIPAMENTOS'
EndIf

If !lLocEq
	cManip		:= oMdlRh:GetValue("TFF_CALCMD")
	cRet 		:= oMdlRh:GetValue("TFF_PLACOD") + oMdlRh:GetValue("TFF_PLAREV")
Else	
	cManip		:= oMdlLE:GetValue("TFI_CALCMD")
	cRet 		:= oMdlLE:GetValue("TFI_PLACOD") + oMdlLE:GetValue("TFI_PLAREV")
EndIf

oModel740 := oModel

DEFINE DIALOG oDlg TITLE STR0001 FROM 00,00 TO 110,130 PIXEL //"Planilha"
	oDlg:LEscClose	:= .F.
	oOpcao				:= TRadMenu():New(05,05,{STR0002,STR0003,STR0004},,oDlg,,,,,,,,45,40,,,,.T.) //'Manipular'#'Executar'#'Novo Modelo'
	oOpcao:bSetGet	:= {|x|IIf(PCount()==0,nOpcao,nOpcao:=x)}
	oBtn				:= TButton():New(35,05,STR0005,oDlg,{|| nOpcOk := 1, nOpcao, oDlg:End()},60,15,,,.F.,.T.,.F.,,.F.,,,.F. ) //'Confirmar'
ACTIVATE DIALOG oDlg CENTERED

If	nOpcOk == 1
	If Empty(cManip) .OR. nOpcao == 3 .OR. nOpcao == 2
		aModPla	:= At998ConsP(cRet)
		lRet		:= aModPla[1]
		cRet		:= aModPla[2]
		If lRet
			DbSelectArea("ABW")
			DbSetOrder(1) // ABW_FILIAL+ABW_CODIGO+ABW_REVISA
			If ABW->(DbSeek(xFilial("ABW")+cRet))
				cModelo := ABW->ABW_INSTRU
				If nOpcao == 1 .OR. nOpcao == 3
					At998MdPla(cModelo,oModel,lLocEq, cRet)
				Else
					At998ExPla(cModelo,oModel,lLocEq, cRet)
				EndIf	
			EndIf
		EndIf
	Else
		If nOpcao == 1
			At998MdPla(cManip,oModel,lLocEq, cRet)
		Else
			At998ExPla(cManip,oModel,lLocEq, cRet)
		EndIf
	EndIf	
EndIf
Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At998MdPla()

Monta a Planilha de cálculo para manipulação. 

@sample 	At998MdPla() 

@param		cXml, Caracter, Conteúdo do XML
			oModel, Object, Classe do modelo de dados MpFormModel   
	
@since		22/10/2013       
@version	P11.9   
/*/
//------------------------------------------------------------------------------
Function At998MdPla(cXml,oModel,lLocEq, cCodRev)

Local oFWLayer 
Local oDlg
Local aSize	 		:= FWGetDialogSize( oMainWnd ) 	
Local oWinPlanilha
Local aCelulasBlock := At998Atrib()
Local cTpModelo := ABW->ABW_TPMODP
Local aNickBloq	:= {"TOTAL_RH","TOTAL_MAT_CONS","TOTAL_MAT_IMP","LUCRO"}
Local oMdlRh		:= oModel:GetModel("TFF_RH")
Local nTotMI		:= oMdlRh:GetValue("TFF_TOTMI")
Local nTotMC		:= oMdlRh:GetValue("TFF_TOTMC")
Local bExpor		:= {|| TECA997(oFWSheet) }

Default cCodRev := ""

	DEFINE DIALOG oDlg TITLE STR0006 FROM aSize[1],aSize[2] TO aSize[3],aSize[4] PIXEL //"Planilha Preço"
	
		oFWLayer := FWLayer():New()
		oFWLayer:init( oDlg, .T. )
		oFWLayer:addLine( "Lin02", 100, .T. )
		oFWLayer:setLinSplit( "Lin02", CONTROL_ALIGN_BOTTOM, {|| } )
		oFWLayer:addCollumn("Col01", 100, .T., "Lin02" )
		oFWLayer:addWindow("Col01", "Win02", STR0001, 100,.F., .f., {|| Nil },"Lin02" ) //'Planilha'
		
		oWinPlanilha := oFWLayer:getWinPanel("Col01"	, "Win02" ,"Lin02")

	
	//---------------------------------------
	// PLANILHA
	//---------------------------------------
	oFWSheet := FWUIWorkSheet():New(oWinPlanilha)
	
	oFWSheet:AddItemMenu(STR0007,bExpor) //'Exportar para Excel'
	
	oFwSheet:SetMenuVisible(.T.,STR0008,50) //"Ações"
	
	If !Empty(cXml) 
		oFWSheet:LoadXmlModel(cXml)
	EndIf
	
	If oFWSheet:CellExists("TOTAL_MAT_IMP")
		oFWSheet:SetCellValue("TOTAL_MAT_IMP", nTotMI)
	EndIf
	
	If oFWSheet:CellExists("TOTAL_MAT_CONS")
		oFWSheet:SetCellValue("TOTAL_MAT_CONS", nTotMC)
	EndIf
	
	//.T. serão bloqueadas as celulas que NÃO estão no array passado aCells 
	//.F. serão bloqueadas as celulas que estão no array passado aCells 
	If cTpModelo == "1"
		oFWSheet:SetCellsBlock(aCelulasBlock, .T.) //'Lista Liberada'
	Else
		oFWSheet:SetCellsBlock(aCelulasBlock, .F.) //'Lista bloqueada' 
	EndIf
	
	oFwSheet:SetNamesBlock(aNickBloq)
	
	oFWSheet:Refresh(.T.)
	
	ACTIVATE DIALOG oDlg ON INIT EnchoiceBar(oDlg,{||At998Grv(oModel,lLocEq,cCodRev),oDlg:End()},{||oDlg:End()})
		
Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At998Atrib()

Atribui as células gravadas na lista do modelo da planilha 

@sample 	At998Atrib() 

@return	aCel-> Array, Contém células gravadas na lista. 

@since		22/10/2013       
@version	P11.9   
/*/
//------------------------------------------------------------------------------
Function At998Atrib()

Local aArea := GetArea()
Local aCell := {}

If DbSeek(xFilial("ABW")+ABW->(ABW_CODIGO+ABW_REVISA))
	aCell := StrTokArr(ABW->ABW_LISTA,";")
EndIf

RestArea(aArea)

Return aCell

//------------------------------------------------------------------------------
/*/{Protheus.doc} At998Grv()

Gravação do xml e do cálculo na planilha do item selecionado.

@sample 	At998Grv() 

@param		oModel, Object, Classe do modelo de dados MpFormModel  
	
@since		22/10/2013       
@version	P11.9   
/*/
//------------------------------------------------------------------------------
Function At998Grv(oModel,lLocEq, cCodRev)

Local oMdlRh		:= oModel:GetModel("TFF_RH")
Local oMdlLE		:= oModel:GetModel("TFI_LE")
Local oMdlLEa		:= oModel:GetModel("TEV_ADICIO")
Local cManip		:= ""
Local nTamCpoCod 	:= TamSX3("TFF_PLACOD")[1]
Local nTamCpoRev 	:= TamSX3("TFF_PLAREV")[1]
Local cTotRh		:= 0
Local cTotBen		:= 0

Default lLocEq := .F.
Default cCodRev := ""

Default lLocEq := .F.

cManip 	:= oFwSheet:GetXmlModel(,,,,.F.,.T.,.F.)
cTotRh 	:= oFwSheet:GetCellValue("TOTAL_RH")

If oFWSheet:CellExists("TOTAL_BENEF")
	cBenef := oFwSheet:GetCellValue("TOTAL_BENEF")
EndIf

If !Empty(cManip) .AND. !Empty(cTotRh) .AND. oMdlRh:GetOperation() <> MODEL_OPERATION_VIEW .And. !lLocEq
	oMdlRh:SetValue("TFF_CALCMD",cManip)
	oMdlRh:SetValue("TFF_PRCVEN",cTotRh)
	
	//Verifica se tem produto de beneficio 
	//If !Empty(oMdlRh:GetValue("TFF_PDBENE"))
		oMdlRh:SetValue("TFF_VLBENE", cTotBen * oMdlRh:GetValue("TFF_QTDVEN"))
	//EndIf
	
	oMdlRh:SetValue("TFF_PLACOD", SubString(cCodRev,1,nTamCpoCod))
	oMdlRh:SetValue("TFF_PLAREV", SubString(cCodRev,nTamCpoCod+1,nTamCpoRev))
EndIf

If !Empty(cManip) .AND. oMdlLE:GetOperation() <> MODEL_OPERATION_VIEW .And. lLocEq .And. !Empty(oMdlLE:GetValue("TFI_PRODUT"))
	oMdlLE:SetValue("TFI_CALCMD",cManip)
	oMdlLE:SetValue("TFI_PLACOD", SubString(cCodRev,1,nTamCpoCod))
	oMdlLE:SetValue("TFI_PLAREV", SubString(cCodRev,nTamCpoCod+1,nTamCpoRev))
	If oFWSheet:CellExists("TOTAL_LE_COB")
		oMdlLEa:SetValue("TEV_MODCOB",if(valtype(oFwSheet:GetCellValue("TOTAL_LE_COB")) == 'N',AllTrim(str(oFwSheet:GetCellValue("TOTAL_LE_COB"))),oFwSheet:GetCellValue("TOTAL_LE_COB")))
	EndIf
	
	If oFWSheet:CellExists("TOTAL_LE_QUANT")
		oMdlLEa:SetValue("TEV_QTDE", if(valtype(oFwSheet:GetCellValue("TOTAL_LE_QUANT")) <> 'N', 0 ,oFwSheet:GetCellValue("TOTAL_LE_QUANT")))
	EndIf
	
	If oFWSheet:CellExists("TOTAL_LE_VUNIT")
		oMdlLEa:SetValue("TEV_VLRUNI", if(valtype(oFwSheet:GetCellValue("TOTAL_LE_VUNIT")) <> 'N', 0 ,oFwSheet:GetCellValue("TOTAL_LE_VUNIT")))
	EndIf
EndIf

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At998ExPla()

Executa o cálculo do modelo da planilha sem visualizar a mesma. 

@sample 	At998ExPla() 

@param		cXml, Caracter, Conteúdo do XML
			oModel, Object, Classe do modelo de dados MpFormModel  
	
@since		22/10/2013       
@version	P11.9   
/*/
//------------------------------------------------------------------------------
Function At998ExPla(cXml, oModel, lLocEq, cCodRev, lReplica)
Local oMdlLA		:= oModel:GetModel("TFL_LOC")
Local oMdlRh		:= oModel:GetModel("TFF_RH")
Local oMdlLE		:= oModel:GetModel("TFI_LE")
Local oMdlLEa		:= oModel:GetModel("TEV_ADICIO")
Local oMdlTWO		:= oModel:GetModel("TWODETAIL")
Local nTotMI		:= oMdlRh:GetValue("TFF_TOTMI")
Local nTotMC		:= oMdlRh:GetValue("TFF_TOTMC")
Local cTotal		:= 0
Local cBenef		:= 0
Local nX			:= 0
Local nY			:= 0
Local nTamCpoCod	:= TamSX3("TFF_PLACOD")[1]
Local nTamCpoRev	:= TamSX3("TFF_PLAREV")[1]
Local nLine		:= oMdlRh:GetLine()
Local nLineTFL	:= oMdlLA:GetLine()

Default lLocEq	:= .F.
Default cCodRev := ""
Default lReplica := .F.

oFWSheet := FWUIWorkSheet():New(,.F. ) //instancia a planilha sem exibição
oFwSheet:LoadXmlModel(cXml)

//Restaura a linha do local se houve mudança
If nLineTFL <> oMdlLA:GetLine()
	oMdlLA:GoLine(nLineTFL)
EndIf

//Restaura a linha se houve mudança
If nLine <> oMdlRh:GetLine()
	oMdlRh:GoLine(nLine)
EndIf

If oFWSheet:CellExists("TOTAL_MAT_IMP")
	oFWSheet:SetCellValue("TOTAL_MAT_IMP", nTotMI)
EndIf
If oFWSheet:CellExists("TOTAL_MAT_CONS")
	oFWSheet:SetCellValue("TOTAL_MAT_CONS", nTotMC)
EndIf

oFWSheet:Refresh(.T.)

cTotal := oFwSheet:GetCellValue("TOTAL_RH")

If oFWSheet:CellExists("TOTAL_BENEF")
	cBenef := oFwSheet:GetCellValue("TOTAL_BENEF")
EndIf

If oMdlRh:GetOperation() <> MODEL_OPERATION_VIEW
	//Executar Planilha para item de RH
	If !( lLocEq )
		//Verifica se tem um facilitador vinculado
		If !lReplica .AND. !( Empty(oMdlRh:GetValue('TFF_CHVTWO')) ) .And. oMdlLA:Length(.T.) > 1 .And. MsgYesNo(STR0015) // "Replicar a execução da Planilha para todos locais de atendimento que utilizam este mesmo facilitador? "
			For nX := 1 To oMdlLA:Length()
				oMdlLA:GoLine(nX)
				For nY := 1 To oMdlRh:Length()
					oMdlRh:GoLine(nY)
					If !( Empty(oMdlRh:GetValue('TFF_CHVTWO')) ) .And. SubStr(oMdlRh:GetValue('TFF_CHVTWO'),1,15) == oMdlTWO:GetValue('TWO_CODFAC')
						oMdlRh:SetValue("TFF_PRCVEN",cTotal)
						oMdlRh:SetValue("TFF_CALCMD",cXml)
						oMdlRh:SetValue("TFF_PLACOD", SubString(cCodRev,1,nTamCpoCod))
						oMdlRh:SetValue("TFF_PLAREV", SubString(cCodRev,nTamCpoCod+1,nTamCpoRev))
					EndIf
				Next nY
			Next nX
		Else
			oMdlRh:SetValue("TFF_PRCVEN", cTotal)
			
			//Verifica se tem produto de beneficio 
		//	If !Empty(oMdlRh:GetValue("TFF_PDBENE"))
			oMdlRh:SetValue("TFF_VLBENE", cBenef)	
		//	EndIf
			
			oMdlRh:SetValue("TFF_CALCMD", cXml)
			oMdlRh:SetValue("TFF_PLACOD", SubString(cCodRev,1,nTamCpoCod))
			oMdlRh:SetValue("TFF_PLAREV", SubString(cCodRev,nTamCpoCod+1,nTamCpoRev))
		EndIf
	//Executar Planilha para item de Locação de Equipamento
	ElseIf !( Empty(oMdlLE:GetValue("TFI_PRODUT")) )
		//Verifica se tem um facilitador vinculado
		If !( Empty(oMdlLE:GetValue('TFI_CHVTWO')) ) .AND. oMdlLA:Length(.T.) > 1 .AND. MsgYesNo(STR0015) // "Replicar a execução da Planilha para todos locais de atendimento que utilizam este mesmo facilitador? "
			For nX := 1 To oMdlLA:Length()
				oMdlLA:GoLine(nX)
				For nY := 1 To oMdlLE:Length()
					oMdlLE:GoLine(nY)
					If  !( Empty(oMdlLE:GetValue('TFI_CHVTWO')) ) .And. SubStr(oMdlLE:GetValue('TFI_CHVTWO'),1,15) == oMdlTWO:GetValue('TWO_CODFAC')
						oMdlLE:SetValue("TFI_CALCMD", cXml)
						oMdlLE:SetValue("TFI_PLACOD", SubString(cCodRev,1,nTamCpoCod))
						oMdlLE:SetValue("TFI_PLAREV", SubString(cCodRev,nTamCpoCod+1,nTamCpoRev))
						If oFWSheet:CellExists("TOTAL_LE_COB")
							oMdlLEa:SetValue("TEV_MODCOB",If(valtype(oFwSheet:GetCellValue("TOTAL_LE_COB")) == 'N',AllTrim(str(oFwSheet:GetCellValue("TOTAL_LE_COB"))),oFwSheet:GetCellValue("TOTAL_LE_COB")))
						EndIf
						If oFWSheet:CellExists("TOTAL_LE_QUANT")
							oMdlLEa:SetValue("TEV_QTDE", If(valtype(oFwSheet:GetCellValue("TOTAL_LE_QUANT")) <> 'N', 0 ,oFwSheet:GetCellValue("TOTAL_LE_QUANT")))
						EndIf
						If oFWSheet:CellExists("TOTAL_LE_VUNIT")
							oMdlLEa:SetValue("TEV_VLRUNI", If(valtype(oFwSheet:GetCellValue("TOTAL_LE_VUNIT")) <> 'N', 0 ,oFwSheet:GetCellValue("TOTAL_LE_VUNIT")))
						EndIf
					EndIf
				Next nY
			Next nX
		Else
			oMdlLE:SetValue("TFI_CALCMD", cXml)
			oMdlLE:SetValue("TFI_PLACOD", SubString(cCodRev,1,nTamCpoCod))
			oMdlLE:SetValue("TFI_PLAREV", SubString(cCodRev,nTamCpoCod+1,nTamCpoRev))
			If oFWSheet:CellExists("TOTAL_LE_COB")
				oMdlLEa:SetValue("TEV_MODCOB",If(valtype(oFwSheet:GetCellValue("TOTAL_LE_COB")) == 'N',AllTrim(str(oFwSheet:GetCellValue("TOTAL_LE_COB"))),oFwSheet:GetCellValue("TOTAL_LE_COB")))
			EndIf
			If oFWSheet:CellExists("TOTAL_LE_QUANT")
				oMdlLEa:SetValue("TEV_QTDE", If(valtype(oFwSheet:GetCellValue("TOTAL_LE_QUANT")) <> 'N', 0 ,oFwSheet:GetCellValue("TOTAL_LE_QUANT")))
			EndIf
			If oFWSheet:CellExists("TOTAL_LE_VUNIT")
				oMdlLEa:SetValue("TEV_VLRUNI", If(valtype(oFwSheet:GetCellValue("TOTAL_LE_VUNIT")) <> 'N', 0 ,oFwSheet:GetCellValue("TOTAL_LE_VUNIT")))
			EndIf
		EndIf
	EndIf
EndIf
Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At998ConsP()

Construção da consulta padrão da tabela ABW - MODELO PLANILHA PREC. SERVICOS

@sample 	At998ConsP() 

@return	lRet, Retorna qual botão foi selecionado .T. Confirmar, .F. Sair 
			cRet, Retorna o codigo+revisão do modelo selecionado

@since		23/10/2013       
@version	P11.9   
/*/
//------------------------------------------------------------------------------
Static Function At998ConsP(cCodPlan)

Local oDlg
Local aBrowse	:= {}   
Local lRet		:= .F. 
Local cRet		:= ""
Local cFilABW 	:= xFilial("ABW")
Local nPos 		:= 0

Default cCodPlan := ""

DEFINE MSDIALOG oDlg FROM 180,180 TO 550,700 PIXEL TITLE STR0009 //'Consulta Padrão'

oBrowse := TWBrowse():New( 01 , 01,261, 160,,{STR0010,STR0011,STR0012},{30,40,10}, oDlg, ,,,,{||},,,,,,,.F.,,.T.,,.F.,,, ) //"Código"#"Descrição"#"Revisão"

DbSelectArea("ABW")
DbSetOrder(1) //ABW_FILIAL+ABW_CODIGO+ABW_REVISA
ABW->( DbSeek( cFilABW ) ) // posiciona no primeiro registro da filial

While ABW->(!EOF()) .And. ABW->ABW_FILIAL == cFilABW
	If ABW->(FieldPos("ABW_MSBLQL")) <= 0 .OR. ABW->ABW_MSBLQL != "1"
		aAdd(aBrowse,{ABW->ABW_CODIGO,ABW->ABW_DESC,ABW->ABW_REVISA})
		If !Empty(cCodPlan) .AND. cCodPlan  == ABW->ABW_CODIGO+ABW->ABW_REVISA
			nPos := Len(aBrowse)
		EndIf
	EndIf
	ABW->(DbSkip())
End

If Len(aBrowse) > 0
	oBrowse:SetArray(aBrowse)
	If nPos > 0
		//Posiciona na planilha selecionada
		oBrowse:GoPosition(nPos)
	EndIf
	oBrowse:bLine := {||{aBrowse[oBrowse:nAt,01],aBrowse[oBrowse:nAt,02],aBrowse[oBrowse:nAt,03]} }
	oBrowse:bLDblClick := {|| lRet := .T., cRet := aBrowse[oBrowse:nAt,01]+aBrowse[oBrowse:nAt,03] ,oDlg:End()}

	TButton():New(168,150,STR0005,oDlg,{|| lRet := .T., cRet := aBrowse[oBrowse:nAt,01]+aBrowse[oBrowse:nAt,03] ,oDlg:End() },50,13,,,,.T.) //'Confirmar'
EndIf
	
TButton():New(168,205,STR0013,oDlg,{|| lRet := .F. ,oDlg:End() },50,13,,,,.T.) //'Sair'

ACTIVATE MSDIALOG oDlg CENTERED 

Return {lRet,cRet}
//------------------------------------------------------------------------------
/*/{Protheus.doc} TECGetValue()

Função para retornar qualquer valor do Orçamento de serviços, com o modelo instanciado


@return	xValue

@since		10/10/2016       
@version	P12   
/*/
//------------------------------------------------------------------------------
Function TECGetValue(cAba,cCampo,nLinha,cErro)
Local aSaveLines	:= FWSaveRows()
Local xRet			:= Nil
Default nLinha := 0
Default cErro := ""

If Valtype(oModel740) == 'O'
	cAba := Upper(Alltrim(cAba)) 
	
	Do Case
		Case cAba == 'OR' //-- Cabeçalho Orçamento
			xRet := oModel740:GetValue('TFJ_REFER',cCampo) 
				
			
		Case cAba == 'LA' //-- Local de atendimento
			nlinha := If(nLinha == 0,oModel740:GetModel('TFL_LOC'):GetLine(),nLinha)
			If nLinha > oModel740:GetModel('TFL_LOC'):Length()
				cErro := 'Aba: LA ' + CRLF +  'Linha ' + Str(nLinha) + ' inválida'
			Else
				xRet 	:= oModel740:GetValue('TFL_LOC',cCampo,nLinha)
			EndIf			
			
		
		Case cAba == 'RH' //-- Recursos humanos
			nlinha := If(nLinha == 0,oModel740:GetModel('TFF_RH'):GetLine(),nLinha)
			If nLinha > oModel740:GetModel('TFF_RH'):Length()
				cErro := 'Aba: RH ' + CRLF +  'Linha ' + Str(nLinha) + ' inválida' 
			Else
				xRet 	:= oModel740:GetValue('TFF_RH',cCampo,nLinha)
			EndIf			
		
		Case cAba == 'MI' //-- Material de implantação
			nLinha := If(nLinha == 0,oModel740:GetModel('TFG_MI'):GetLine(),nLinha)
			If nLinha > oModel740:GetModel('TFG_MI'):Length()
				cErro := 'Aba: MI ' + CRLF +  'Linha ' + Str(nLinha) + ' inválida' 
			Else
				xRet 	:= oModel740:GetValue('TFG_MI',cCampo,nLinha)
			EndIf			
		
		Case cAba == 'MC' //-- Material de consumo
			nlinha := If(nLinha == 0,oModel740:GetModel('TFH_MC'):GetLine(),nLinha)
			If nLinha > oModel740:GetModel('TFH_MC'):Length()
				cErro := 'Aba: MC ' + CRLF +  'Linha ' + Str(nLinha) + ' inválida' 
			Else
				xRet 	:= oModel740:GetValue('TFH_MC',cCampo,nLinha)
			EndIf			
		
		Case cAba == 'LE' //-- Locação de equipamento
			nlinha := If(nLinha == 0,oModel740:GetModel('TFI_LE'):GetLine(),nLinha)
			If nLinha > oModel740:GetModel('TFI_LE'):Length()
				cErro := 'Aba: LE ' + CRLF +  'Linha ' + Str(nLinha) + ' inválida' 
			Else
				xRet 	:= oModel740:GetValue('TFI_LE',cCampo,nLinha)
			EndIf			
		
	EndCase
EndIf
FwRestRows( aSaveLines )
Return xRet


