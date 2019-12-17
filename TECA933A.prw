#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#Include 'TECA933A.ch'

Static nTotMark := 0
//--------------------------------------------------------------------
/*/{Protheus.doc} ModelDef	()

@author Pâmela Bernardo
@return oModel
/*/
//--------------------------------------------------------------------
Static Function ModelDef()
	Local oModel 		:= Nil
	Local oStrZZZ  		:= FWFormModelStruct():New()
	Local oStrCN9		:= FWFormStruct( 1, "CN9",{|cCampo| AllTrim(cCampo) $ "CN9_NUMERO|CN9_REVISA|CN9_DTINIC|CN9_DTFIM|CN9_VLATU|CN9_SALDO"})
	Local aCampo    	:= {}
	Local bNoInit 		:= FwBuildFeature( STRUCT_FEATURE_INIPAD, '' )
	Local lInsert 		:= IsInCallStack('A933ILote')
	
	oModel := MPFormModel():New('TECA933A',,{|oModel|A933AaVld(oModel)},{|oModel|A933AaCmt(oModel)})
	
	oStrZZZ:AddTable("ZZZ",{" "}," ")
	oStrCN9:SetProperty("*", MODEL_FIELD_INIT, bNoInit )  // remove todos os inicializadores padrão dos campos
	oStrCN9:SetProperty("*", MODEL_FIELD_OBRIGAT, .F.)
	
	aCampo := {}
	aCampo := {STR0001, STR0001,'_CRTDE','C', TamSX3('CN9_NUMERO')[1], 0,Nil,Nil, Nil, Nil , Nil, Nil, Nil, .F.}//"Contrato de"
	AddFieldMD(@oStrZZZ,aCampo)
	aCampo := {}
	aCampo := {STR0002, STR0002 ,'_CRTATE','C', TamSX3('CN9_NUMERO')[1], 0,{||A933aVldt(oModel, 'ZZZ_CRTATE')},Nil, Nil, Nil , Nil, Nil, Nil, .F.}//"Contrato até"
	AddFieldMD(@oStrZZZ,aCampo)
	
	If lInsert
		aCampo := {}
		aCampo := { STR0003,  STR0003,'_DATA','D', 8, 0,{||.T.}, Nil, Nil, Nil, {||DDATABASE}, Nil, Nil, .F.}//"Data de Faturamento"
		AddFieldMD(@oStrZZZ,aCampo)
		
		aCampo := {}
		aCampo := {STR0004,STR0004,'_PERCEN','N', 5, 2,Nil, Nil, Nil, Nil, Nil, Nil, Nil, .F.} //"% Dissídio"
		AddFieldMD(@oStrZZZ,aCampo)
		
	Else
	
		aCampo := {}
		aCampo := { STR0005,  STR0005,'_DATAINI','D', 8, 0,{||.T.}, Nil, Nil, Nil, Nil, Nil, Nil, .F.}//"Data Fat De"
		AddFieldMD(@oStrZZZ,aCampo)
		
		aCampo := {}
		aCampo := { STR0006,  STR0006,'_DATAFIM','D', 8, 0,{||A933aVldt(oModel, 'ZZZ_DATAFIM')}, Nil, Nil, Nil, Nil, Nil, Nil, .F.}//"Data Fat Até"
		AddFieldMD(@oStrZZZ,aCampo)
		
		aCampo := {}
		aCampo := {STR0007, STR0007,'_TX0COD','C', 10, 0,Nil, Nil, Nil, .F.,Nil, Nil, Nil, .T.} //'TX0Codigo'
		AddFieldMD(@oStrCN9,aCampo)
		
	
	EndIf
	
	
	aCampo := {}
	aCampo := {STR0008, STR0008,'_MARK','L', 1, 0,{||.T.}, Nil, Nil, .F.,Nil, Nil, Nil, .F.} //'Mark'
	AddFieldMD(@oStrCN9,aCampo)
	
	aCampo := {}
	aCampo := {STR0009, STR0009,'_CLIENT','C', TamSX3('A1_NREDUZ')[1], 0,Nil, Nil, Nil, .F.,Nil, Nil, Nil, .T.} //'Cliente'
	AddFieldMD(@oStrCN9,aCampo)
	
	aCampo := {}
	aCampo := {STR0010, STR0010,'_RECORR','C', 1, 0,{||.T.}, Nil, Nil, .F.,Nil, Nil, Nil, .F.} //'Recorrente'
	AddFieldMD(@oStrCN9,aCampo)

	oModel:addFields( 'ZZZMASTER', ,oStrZZZ)
	oModel:AddGrid( 'CN9DETAIL', 'ZZZMASTER',oStrCN9 ,,,,,)
	
	oModel:GetModel('ZZZMASTER'):SetOnlyQuery(.T.)
	oModel:GetModel('CN9DETAIL'):SetNoInsertLine(.T.)
	oModel:GetModel('CN9DETAIL'):SetNoDeleteLine(.T.)
	oModel:GetModel('CN9DETAIL'):SetOnlyQuery(.T.)
	
	oModel:GetModel('ZZZMASTER'):SetDescription(STR0011) //'Parâmetros'
	oModel:GetModel('CN9DETAIL'):SetDescription(STR0012)//'Contratos'
	
	oModel:SetPrimaryKey({})
	oModel:SetDescription(STR0013)//'Processamento em Lote'

Return oModel

//--------------------------------------------------------------------
/*/{Protheus.doc} 	ViewDef()

@author Pâmela Bernardo
@return oView
/*/
//--------------------------------------------------------------------
Static Function ViewDef()
	Local oModel   	:= ModelDef()
	Local oView    	:= FWFormView():New()		
	Local oStrZZZ  	:= FWFormStruct(2,'ZZZ')
	Local oStrCN9  	:= FWFormStruct(2,'CN9',{|cCampo| AllTrim(cCampo) $ "CN9_NUMERO|CN9_REVISA|CN9_DTINIC|CN9_DTFIM"})
	Local aCampo    := {}
	Local aCombo	:= {}
	Local lInsert := IsInCallStack('A933ILote')
	Local cMasc		:= PesqPict("TX0","TX0_PERCEN")
	
	
	If lInsert
		SX3->(dbSetOrder(2)) 
		If SX3->(dbSeek('ABX_OPERAC'))   
			aCombo  := StrTokArr(X3Cbox(),';')
		EndIf
	EndIf
	
	oStrCN9:SetProperty('*', MVC_VIEW_CANCHANGE, .F.)	
	
	aCampo 	:= {}
	aCampo 	:= {'_CRTDE', '01', STR0001,STR0001, Nil, 'C', '@!', Nil, 'TFJCTR', .T., Nil, Nil, Nil, Nil, Nil, .T.,Nil} //"Contrato De"
	AddFieldVW('ZZZ',@oStrZZZ,aCampo)
	
	aCampo 	:= {}
	aCampo 	:= {'_CRTATE', '02', STR0002,STR0002, Nil, 'C', '@!', Nil, 'TFJCTR', .T., Nil, Nil, Nil, Nil, Nil, .T.,Nil}//"Contrato Até"
	AddFieldVW('ZZZ',@oStrZZZ,aCampo)
	
	If lInsert
		aCampo 	:= {}
		aCampo 	:= {'_DATA', '03', STR0003,STR0003, Nil, 'D', '', Nil, '', .T., Nil, Nil, Nil, Nil, Nil, .T.,Nil} //"Data de Faturamento"
		AddFieldVW('ZZZ',@oStrZZZ,aCampo)
		
		aCampo 	:= {}
		aCampo 	:= {'_PERCEN', '04', STR0004,STR0004, Nil, 'N', cMasc, Nil, '', .T., Nil, Nil, Nil, Nil, Nil, .T.,Nil} //"% Dissídio"
		AddFieldVW('ZZZ',@oStrZZZ,aCampo)
	Else
		aCampo 	:= {}
		aCampo 	:= {'_DATAINI', '03', STR0005,STR0005, Nil, 'D', '', Nil, '', .T., Nil, Nil, Nil, Nil, Nil, .T.,Nil} //"Data Fat De"
		AddFieldVW('ZZZ',@oStrZZZ,aCampo)
		
		aCampo 	:= {}
		aCampo 	:= {'_DATAFIM', '04', STR0006,STR0006, Nil, 'D', '', Nil, '', .T., Nil, Nil, Nil, Nil, Nil, .T.,Nil} //"Data Fat Até"
		AddFieldVW('ZZZ',@oStrZZZ,aCampo)
	EndIf
	
	aCampo 	:= {}
	aCampo 	:= {'_MARK', '00', ' ',' ', Nil, 'L', Nil, Nil, '', .T., Nil, Nil, Nil, Nil, Nil, .T.,Nil}
	AddFieldVW('CN9',@oStrCN9,aCampo)
	
	aCampo 	:= {}
	aCampo 	:= {'_CLIENT', '08', ' ',' ', Nil, 'C', Nil, Nil, '', .F., Nil, Nil, Nil, Nil, Nil, .T.,Nil}
	AddFieldVW('CN9',@oStrCN9,aCampo)
	
	oStrCN9:SetProperty( 'CN9_NUMERO' 	, MVC_VIEW_ORDEM, '01')
	oStrCN9:SetProperty( 'CN9_REVISA' 	, MVC_VIEW_ORDEM, '02')
	oStrCN9:SetProperty( 'CN9_CLIENT' 	, MVC_VIEW_ORDEM, '03')
	oStrCN9:SetProperty( 'CN9_DTINIC' 	, MVC_VIEW_ORDEM, '04')
	oStrCN9:SetProperty( 'CN9_DTFIM' 	, MVC_VIEW_ORDEM, '05')
	
	
	oView:SetModel(oModel)  //-- Define qual o modelo de dados será utilizado
	oView:SetDescription(STR0013)//'Processamento em Lote'
	
	oView:AddField('VIEW_ZZZ' ,oStrZZZ, 'ZZZMASTER')
	oView:AddGrid('VIEW_CN9'  ,oStrCN9, 'CN9DETAIL')
	
	oView:CreateHorizontalBox('CIMA',40)
	oView:CreateHorizontalBox('MEIO',60)
	
	oView:SetOwnerView('VIEW_ZZZ','CIMA' )
	oView:SetOwnerView('VIEW_CN9','MEIO')
	
	oView:EnableTitleView('VIEW_ZZZ' , STR0011 ) //'Parâmetros'
	oView:EnableTitleView('VIEW_CN9' , STR0012 ) //'Contratos'
	
	oView:SetCloseOnOk({||.T.})
	oView:SetViewProperty("VIEW_CN9", "ENABLENEWGRID")
	oView:SetViewProperty("VIEW_CN9", "GRIDFILTER", {.T.})
	
	oView:SetFieldAction( 'CN9_MARK', { |oView, cIDView, cField, xValue| A933AaMark(xValue) } )
	oView:SetFieldAction( 'ZZZ_CRTDE', { |oView, cIDView, cField, xValue| A933AaLdCN(oView) } )
	oView:SetFieldAction( 'ZZZ_CRTATE', { |oView, cIDView, cField, xValue| A933AaLdCN(oView) } )
	If lInsert
		oView:SetFieldAction( 'ZZZ_DATA', { |oView, cIDView, cField, xValue| A933AaLdCN(oView) } )
	Else
		oView:SetFieldAction( 'ZZZ_DATAFIM', { |oView, cIDView, cField, xValue| A933AaLdCN(oView) } )
	EndIf
	
	oView:setInsertMessage(STR0013,STR0014) //'Processamento em Lote' ## 'Processamento efetuado com sucesso'
	
	oView:AddUserButton(STR0015 ,"",{|oView| A933AViewCTR()}) //"Visualizar contrato"
	oView:AddUserButton(STR0016 ,"",{|oView| A933aAll()})    //"Replicar marcação"

Return oView

//--------------------------------------------------------------------
/*/{Protheus.doc} 	A933AALoad()
Carga de dados na Grid conforme preenchimento dos dados de contrato
@author Pâmela Bernardo
@return lRet
/*/
//--------------------------------------------------------------------
Function A933AALoad(oView)
	Local oModel := FwModelActive()
	Local cAliasTemp := GetNextAlias()
	Local oCN9Detail := oModel:GetModel('CN9DETAIL') 
	Local oStrCN9	 := oCN9Detail:GetStruct()
	Local cContrde   := oModel:GetValue('ZZZMASTER','ZZZ_CRTDE')
	Local cContrate  := oModel:GetValue('ZZZMASTER','ZZZ_CRTATE')
	Local dIniFat   := FirstDay(dDataBase)
	Local dFimFat    := LastDay(dDataBase)
	Local lEstorna	 := IsInCallStack('A933ELote')
	
	nTotMark := 0
	oCN9Detail:ClearData()
	
	oStrCN9:SetProperty('*', MVC_VIEW_CANCHANGE, .T.)
	oStrCN9:SetProperty('*', MODEL_FIELD_OBRIGAT , .F.)	
	
	If lEstorna
	
		dIniFat  :=  oModel:GetValue('ZZZMASTER','ZZZ_DATAINI')
		dFimFat   := oModel:GetValue('ZZZMASTER','ZZZ_DATAFIM')
		BeginSQL Alias cAliasTemp
				
				SELECT CN9_NUMERO, CN9_REVISA, CN9_DTINIC, CN9_DTFIM, CN9_VLINI, CN9_VLATU, CN9_SALDO,  TX0_CLIENT, TX0_LOJA,TX0_CODIGO, TX0_TPCONT
				FROM %Table:CN9% CN9			 
				INNER JOIN %Table:TX0% TX0 ON TX0_FILIAL = %xFilial:TX0%
															AND TX0_CONTRT = CN9_NUMERO
															AND TX0_REVISA = CN9_REVISA
															AND TX0_DATA >= %Exp:dIniFat%
															AND TX0_DATA <= %Exp:dFimFat%		
															AND TX0.%NotDel%	
																																													
				WHERE CN9.CN9_FILIAL = %xFilial:CN9%	
					AND CN9.CN9_SITUAC = '05'
					AND CN9.CN9_NUMERO>= %Exp:cContrde%
					AND CN9.CN9_NUMERO<= %Exp:cContrate%
					AND CN9.%NotDel%
			ORDER BY %Order:CN9%
	    EndSQL
	Else 
	
		dIniFat    :=  FirstDay(oModel:GetValue('ZZZMASTER','ZZZ_DATA'))
		dFimFat   := LastDay(oModel:GetValue('ZZZMASTER','ZZZ_DATA'))
		BeginSQL Alias cAliasTemp	
				
				SELECT CN9_NUMERO, CN9_REVISA, CN9_DTINIC, CN9_DTFIM, CN9_VLINI, CN9_VLATU, CN9_SALDO,TFJ_CODENT, TFJ_LOJA, TFJ_CNTREC 
				FROM %Table:CN9% CN9			 
				INNER JOIN %Table:TFJ% TFJ ON TFJ_FILIAL = %xFilial:TFJ%
															AND TFJ_CONTRT = CN9_NUMERO
															AND TFJ_CONREV = CN9_REVISA
															AND TFJ_STATUS = '1' 
															AND TFJ.%NotDel%
				WHERE CN9.CN9_FILIAL = %xFilial:CN9%	
					AND CN9.CN9_SITUAC = '05'
					AND CN9.CN9_NUMERO>= %Exp:cContrde%
					AND CN9.CN9_NUMERO<= %Exp:cContrate%
					AND CN9.CN9_DTFIM > %Exp:dIniFat%
					AND CN9.%NotDel%
					AND NOT EXISTS (
									SELECT TFV_CONTRT
									FROM %Table:TFV% TFV
										WHERE TFV.TFV_FILIAL = %xFilial:TFV%														
										AND TFV.TFV_CONTRT = CN9.CN9_NUMERO
										AND TFV.TFV_REVISA = CN9.CN9_REVISA
										AND TFV.TFV_DTINI >=  %Exp:dIniFat%										
										AND TFV.%NotDel%
									)
				AND NOT EXISTS (
									SELECT TX0_CONTRT
									FROM %Table:TX0% TX0
										WHERE TX0.TX0_FILIAL = %xFilial:TX0%														
										AND TX0.TX0_CONTRT = CN9.CN9_NUMERO
										AND TX0.TX0_DATA >=  %Exp:dIniFat%	
										AND TX0.TX0_DATA <=  %Exp:dFimFat%									
										AND TX0.%NotDel%
									)
			ORDER BY %Order:CN9%
			EndSQL 
	
	EndIf
	
	While (cAliasTemp)->(!EOF())
		
			oCN9Detail:SetNoInsertLine(.F.)
			If !oCN9Detail:IsEmpty()
				oCN9Detail:AddLine()
			EndIf
	
			oCN9Detail:LoadValue('CN9_NUMERO',(cAliasTemp)->(CN9_NUMERO))
			oCN9Detail:LoadValue('CN9_REVISA',(cAliasTemp)->(CN9_REVISA))
			oCN9Detail:LoadValue('CN9_DTINIC',SToD((cAliasTemp)->(CN9_DTINIC)))
			oCN9Detail:LoadValue('CN9_DTFIM',SToD((cAliasTemp)->(CN9_DTFIM)))
			
			
			If lEstorna
				oCN9Detail:LoadValue('CN9_TX0COD',(cAliasTemp)->(TX0_CODIGO))
				oCN9Detail:LoadValue('CN9_CLIENT',POSICIONE("SA1",1,xFilial("SA1") + (cAliasTemp)->(TX0_CLIENTE) + (cAliasTemp)->(TX0_LOJA), "A1_NREDUZ" ))
				oCN9Detail:LoadValue('CN9_RECORR',(cAliasTemp)->(TX0_TPCONTR))
			Else
				oCN9Detail:LoadValue('CN9_RECORR',(cAliasTemp)->(TFJ_CNTREC))
				oCN9Detail:LoadValue('CN9_CLIENT',POSICIONE("SA1",1,xFilial("SA1") + (cAliasTemp)->(TFJ_CODENT) + (cAliasTemp)->(TFJ_LOJA), "A1_NREDUZ" ))
			Endif
	
		(cAliasTemp)->(DbSkip())
	EndDo
	oCN9Detail:SetNoInsertLine(.T.)
	
	(cAliasTemp)->(DbCloseArea())
	oStrCN9:SetProperty('*', MVC_VIEW_CANCHANGE, .F.)
	
		
	oCN9Detail:GoLine(1) 	
		
	oStrCN9:SetProperty('CN9_MARK', MVC_VIEW_CANCHANGE, .T.)
	oStrCN9:SetProperty('*', MODEL_FIELD_OBRIGAT , .F.)	
		
	oView:Refresh()
	
Return .T.


//--------------------------------------------------------------------
/*/{Protheus.doc} 	A933AViewCTR()
Visualização do contrato
@author Pâmela Bernardo
@return 
/*/
//--------------------------------------------------------------------
Function A933AViewCTR()
	Local aArea	:= GetArea()
	Local oModel	:= FwModelActive()
	Local oCN9Detail := oModel:GetModel('CN9DETAIL')
	
	CN9->(DbSetOrder(1))
	If CN9->(DbSeek(xFilial('CN9')+ oCN9Detail:GetValue('CN9_NUMERO') + oCN9Detail:GetValue('CN9_REVISA')))
		FwExecView(STR0017,'VIEWDEF.CNTA301',MODEL_OPERATION_VIEW)  //"Visualizar"
	EndIf
	
	RestArea(aArea)
Return

//--------------------------------------------------------------------
/*/{Protheus.doc} 	A933AaVld()
Validação de campos
@author Pâmela Bernardo
@return lRet
/*/
//--------------------------------------------------------------------
Function A933AaVld(oModel)
	Local lRet := .T.
	Local lEstorna := IsInCallStack('A933ELote')
	
	If !lEstorna .AND. Empty(oModel:GetValue("ZZZMASTER","ZZZ_PERCEN"))
	  lRet := .F.
	  Help(" ",1,"A933ADISSI",,STR0018,4,1)//"Informar o Percentual de dissídio"
	EndIf
	
	If lRet .And. nTotMark == 0 
		lRet := .F.
		Help(" ",1,"A933ACONTR",,STR0019,4,1)//"Necessário informar ao menos um contrato para processamento"
	EndIf
 
Return lRet

//--------------------------------------------------------------------
/*/{Protheus.doc} 	A933AaCmt()

Bloco de gravação do faturamento do dissidio em lote

@author Pâmela Bernardo
@return lRet
/*/
//--------------------------------------------------------------------
Function A933AaCmt(oModel)
	Local lRet := .T.
	Local nI   := 1
	Local oZZZMaster := oModel:GetModel('ZZZMASTER')
	Local oCN9Detail := oModel:GetModel('CN9DETAIL')
	Local nProc		 := 0
	Local aError	 :=  {}
	Local nRefCNA	 :=  oCN9Detail:Length()
	Local lInsert 	 := IsInCallStack('A933ILote')
	
	Local cCodTX0	 := ""
	
	Begin Transaction
	
		For nI := 1 To nRefCNA
			oCN9Detail:GoLine(nI)
		
			If oCN9Detail:GetValue('CN9_MARK')		
				nProc += 1
				If !lInsert
					cCodTX0	 := oCN9Detail:GetValue('CN9_TX0COD')
				EndIf
				MsgRun(STR0020 + Alltrim(Str(nProc)) + ' '+ STR0021 + Alltrim(Str(nTotMark)), STR0022,{|| lRet := A933AaProc(oModel,oCN9Detail:GetValue('CN9_NUMERO'),oCN9Detail:GetValue('CN9_REVISA'),oCN9Detail:GetValue('CN9_RECORR'),cCodTX0, @aError)})//"Processando Fat. Dissídio..."//"Processando contrato "//"de "
				If !lRet
					Exit
					DisarmTransacation()
				Else
					oCN9Detail:LoadValue('CN9_MARK',.F.)
				EndIf
			EndIf	
		Next nI
		
		If !lRet
			AtShowLog(Alltrim(aError[MODEL_MSGERR_MESSAGE] + CRLF + CRLF + aError[MODEL_MSGERR_SOLUCTION] ), STR0023, .T., .T., .T.,.F.)  // "Processamento não concluído"
		EndIf
	
	End Transaction
	
	FwModelActive(oModel)

Return lRet 

//--------------------------------------------------------------------
/*/{Protheus.doc} 	A933AaProc()
Processamento do faturamento de dissidio
@author Pâmela Bernardo
@return lRet
/*/
//--------------------------------------------------------------------
Function A933AaProc(oModel,cContrato, cRevisa,cRecorre, cCodTX0 ,aError)
	Local lRet 			:= .T.
	Local oMdlA933   	:= Nil
	Local lInsert 		:= IsInCallStack('A933ILote')
	Local lEncontrou	:= .T.
	Local nX			:= 0
	Local oZZZMaster 	:= oModel:GetModel('ZZZMASTER')
	
	If lInsert
			
		oMdlA933 := FwLoadModel('TECA933')
		oMdlA933:SetOperation(MODEL_OPERATION_INSERT)
		oMdlA933:Activate()	
		
		oMdlA933:SetValue( "TX0MASTER", "TX0_CONTRT", cContrato  )
		oMdlA933:SetValue( "TX0MASTER", "TX0_REVISA", cRevisa  )  
		oMdlA933:SetValue( "TX0MASTER", "TX0_PERCEN", oZZZMaster:GetValue('ZZZ_PERCEN')  ) 
		oMdlA933:SetValue( "TX0MASTER", "TX0_TPCONT", cRecorre  )
		oMdlA933:SetValue( "TX0MASTER", "TX0_DATA", oZZZMaster:GetValue("ZZZ_DATA") ) 
			
	Else
		TX0->(dbSetOrder(1)) 
		If TX0->(dbSeek(xFilial('TX0')+cCodTX0))
			oMdlA933 := FwLoadModel('TECA933')
			oMdlA933:SetOperation(MODEL_OPERATION_DELETE)
			oMdlA933:Activate()	
		Else
			lEncontrou := .F.
		EndIf		
	EndIf
	
	If lEncontrou
				
		If oMdlA933:VldData() .And. oMdlA933:CommitData()
			lRet := .T.
		Else
			lRet := .F.
			aError := oMdlA933:GetErrorMessage()
		EndIf
	
		oMdlA933:DeActivate()
	    oMdlA933:Destroy()
		oMdlA933:= Nil
	
	EndIf	

Return lRet

//--------------------------------------------------------------------
/*/{Protheus.doc} 	A933AaMark()
Controle do total de mark
@author Pâmela Bernardo
@return 
/*/
//--------------------------------------------------------------------
Function A933AaMark(xValue)

	If xValue
		nTotMark := nTotMark + 1 
	Else
		nTotMark := nTotMark - 1
	EndIf 
Return .T. 


//--------------------------------------------------------------------
/*/{Protheus.doc}A933AaLdCN()
Função para chamada do Load
@author Pâmela Bernardo
@return 
/*/
//--------------------------------------------------------------------
Function A933AaLdCN(oView)
	Local oModel := FwModelActive()

	Processa({|| A933AALoad( oView), STR0024}) //"Pesquisando contratos..."

Return .T.

//--------------------------------------------------------------------
/*/{Protheus.doc}A933aAll()
Replicar a flag para todas as linhas.
@author Kaique Schiller
@return .T.
/*/
//--------------------------------------------------------------------
Function A933aAll()
	Local oModel		:= FwModelActive()
	Local oCN9Detail 	:= oModel:GetModel("CN9DETAIL")
	Local aSaveLines	:= FwSaveRows()
	Local nX			:= 0
	Local lMark			:= oCN9Detail:GetValue("CN9_MARK")
	
	nTotMark := 0
	
	For nX := 1 To oCN9Detail:Length()
		oCN9Detail:Goline(nX)
		If oCN9Detail:SetValue("CN9_MARK",lMark)
			A933AaMark(lMark)
		Endif
	Next nX
	
	FWRestRows(aSaveLines)

Return .T.

//--------------------------------------------------------------------
/*/{Protheus.doc}A933aVldt()
Valida data de medição/apuração
@author Pâmela Bernardo
/*/
//--------------------------------------------------------------------
Function A933aVldt(oModel, cCampo)
	Local lRet := .T.
	Local oModelZZZ 	:= oModel:GetModel("ZZZMASTER")
	
	If cCampo == 'ZZZ_CRTATE' .and. oModelZZZ:GetValue(cCampo) < oModelZZZ:GetValue("ZZZ_CRTDE")
	  lRet := .F.
	  Help(" ",1,"A933aCTR",,STR0025,4,1)//"O contrato Inicial não pode ser maior que o contrato final"
	EndIf
	If cCampo == 'ZZZ_DATAFIM' .and. oModelZZZ:GetValue(cCampo) < oModelZZZ:GetValue("ZZZ_DATAINI")
		lRet := .F.
	  	Help(" ",1,"A933aDat",,STR0026,4,1)//"A Data Inicial não pode ser maior que a data final"
	EndIf
Return lRet
