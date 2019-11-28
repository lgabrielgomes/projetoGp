#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TECA580.CH"

STATIC lLegend := .T.
STATIC oMdlEsc

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECA580()
Cadastro de Escalas 

@Return 	nil
@author	Serviços
@since 		16/05/2014
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TECA580()
Local oBrowse
Local aLCfg := {}

oBrowse := FwMBrowse():New()

oBrowse:SetAlias("TDW")

oBrowse:SetDescription(STR0001) // Cadastro de Escalas
oBrowse:DisableDetails()

// Legendas
oBrowse:AddLegend( "TDW_STATUS=='1'", "BR_VERDE"   , STR0002 ) // Escala Ativa
oBrowse:AddLegend( "TDW_STATUS=='2'", "BR_VERMELHO", STR0003 ) // Escala Inativa
	
aLCfg := {"",{|| At580LCFBr() },"C","@BMP",0,1,0,.F.,{||.T.},.T.,{|| At580LCfg() },,,,.F.}
oBrowse:AddColumn(aLCfg)

oBrowse:Activate()

Return(Nil)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef()
MenuDef - Cadastro de Escalas

@Return	MenuDef
@author 	Serviços
@since 		16/05/2014
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function MenuDef()

Local aRotina := {}
	
ADD OPTION aRotina TITLE STR0004 	ACTION "PesqBrw" 				OPERATION 1	ACCESS 0	// "Pesquisar"
ADD OPTION aRotina TITLE STR0005 	ACTION "VIEWDEF.TECA580"		OPERATION 2 	ACCESS 0	// "Visualizar"
ADD OPTION aRotina TITLE STR0006 	ACTION "VIEWDEF.TECA580" 	OPERATION 3	ACCESS 0 	// "Incluir"
ADD OPTION aRotina TITLE STR0007	ACTION "VIEWDEF.TECA580"		OPERATION 4	ACCESS 0 	// "Alterar"
	
Return(aRotina)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef()
Model - Cadastro de Escalas

@Return 	model
@author 	Serviços
@since 		16/05/2014
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ModelDef()

Local oModel	
Local oStruTDW 	:= FWFormStruct(1,"TDW")
Local oStruTDX 	:= FWFormStruct(1,"TDX") 
Local oStruTGX 	:= FWFormStruct(1,"TGX")
Local oStrSTDY 	:= FWFormStruct(1,"TDY")
Local oStrFTDY 	:= FWFormStruct(1,"TDY")
Local oStruTGW 	:= FWFormStruct(1,"TGW")
Local bLinePost	:= { |oMdlG,nLine,cAcao,cCampo| PosLinTDX(oMdlG, nLine, cAcao, cCampo) }
Local bLinePre   	:= { |oMdlG,nLine,cAcao,cCampo| PreLinTGW(oMdlG, nLine, cAcao, cCampo) }
Local aAux			:= {}
Local aLoadFilter	:= {}
Local bCommit		:= { |oModel| At580Cmt(oModel) }

lLegend := .T.

aAux := FwStruTrigger("TDX_TURNO","TDX_DESTUR","Posicione('SR6',1,xFilial('SR6')+FwFldGet('TDX_TURNO'),'R6_DESC')",.F.,Nil,Nil,Nil) 				
oStruTDX:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TGW_COBTDX","TGW_COBTIP","At580CobTip(FwFldGet('TGW_COBTDX'),.F.)",.F.,Nil,Nil,Nil) 				
oStruTGW:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

// Legenda do Efetivo
oStruTDX:AddField(STR0008,STR0008,"TDX_SIT","BT",1,0,{||At580GetLE()}/*bValid*/,/*bWhen*/, /*aValues*/,.F.,{||At580LgEfe()},/*lKey*/,/*lNoUpd*/,.T./*lVirtual*/,/*cValid*/) //"Status"

oStruTDX:SetProperty( "TDX_CODTDW", MODEL_FIELD_OBRIGAT, .F. )
oStruTDX:SetProperty( "TDX_QUANT" , MODEL_FIELD_OBRIGAT, .F. )
oStruTGX:SetProperty( "TGX_CODTDW", MODEL_FIELD_OBRIGAT, .F. )
oStruTGX:SetProperty( "TGX_QUANT" , MODEL_FIELD_OBRIGAT, .F. )
oStrSTDY:SetProperty( "TDY_CODTDX", MODEL_FIELD_OBRIGAT, .F. )
oStrFTDY:SetProperty( "TDY_CODTDX", MODEL_FIELD_OBRIGAT, .F. )
oStruTGW:SetProperty( "TGW_EFETDX", MODEL_FIELD_OBRIGAT, .F. )

oStruTDX:SetProperty( "TDX_TURNO", MODEL_FIELD_VALID, { || At580SeqVld( FwFldGet("TDX_TURNO"), FwFldGet("TDX_SEQTUR"), .T. ) } )
oStruTDX:SetProperty( "TDX_SEQTUR", MODEL_FIELD_VALID, { || At580SeqVld( FwFldGet("TDX_TURNO"), FwFldGet("TDX_SEQTUR") ) } )
oStruTGW:SetProperty( "TGW_COBTDX", MODEL_FIELD_VALID, { || At580CobTip( FwFldGet("TGW_COBTDX"), .T. ) } )

oModel := MPFormModel():New( "TECA580", /*bPreValidacao*/, /*bPosValidacao*/, bCommit, /*bCancel*/ )

oModel:AddFields( "TDWMASTER", /*cOwner*/, oStruTDW, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

// Grid de Efetivos
oModel:AddGrid("TDXDETAIL","TDWMASTER",oStruTDX,/*bLinePre*/, bLinePost, /*bPreVal*/, /*bPosVal*/)
oModel:SetRelation("TDXDETAIL",{{"TDX_FILIAL","xFilial('TDX')"},{"TDX_CODTDW","TDW_COD"}},TDX->(IndexKey(2)))

// Grid de Cobertura
oModel:AddGrid("TGXDETAIL","TDWMASTER",oStruTGX,/*bLinePre*/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/)
oModel:SetRelation("TGXDETAIL",{{"TGX_FILIAL","xFilial('TGX')"},{"TGX_CODTDW","TDW_COD"}},TGX->(IndexKey(2)))

// Grid de Configuração
oModel:AddGrid("TGWDETAIL","TDXDETAIL",oStruTGW, bLinePre, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/)
oModel:SetRelation("TGWDETAIL",{{"TGW_FILIAL","xFilial('TGW')"},{"TGW_EFETDX","TDX_COD"}},TGW->(IndexKey(1)))

// Grid de Exceções
oModel:AddGrid("STDYDETAIL","TDXDETAIL",oStrSTDY,/*bLinePre*/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/)
oModel:SetRelation("STDYDETAIL",{{"TDY_FILIAL","xFilial('TDY')"},{"TDY_CODTDX","TDX_COD"}},TDY->(IndexKey(2)))

// Grid de Exceções de Feriados
oModel:AddGrid("FTDYDETAIL","TDXDETAIL",oStrFTDY,/*bLinePre*/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/)
oModel:SetRelation("FTDYDETAIL",{{"TDY_FILIAL","xFilial('TDY')"},{"TDY_CODTDX","TDX_COD"}},TDY->(IndexKey(2)))

oModel:SetDescription( STR0001 ) // "Cadastro de Escalas"

/* --------------- FILTROS -------------------- */

// Grid somente dos dias normais
aLoadFilter := { { "TDY_FERIAD", "2", MVC_LOADFILTER_EQUAL } }
oModel:GetModel("STDYDETAIL"):SetLoadFilter( aLoadFilter, /*cLoadFilter*/ )

// Grid somente dos feriados
aLoadFilter := { { "TDY_FERIAD", "1", MVC_LOADFILTER_EQUAL } }
oModel:GetModel("FTDYDETAIL"):SetLoadFilter( aLoadFilter, /*cLoadFilter*/ )

/* -------------------------------------------- */

oModel:GetModel("TGXDETAIL"):SetOptional(.T.)
oModel:GetModel("STDYDETAIL"):SetOptional(.T.)
oModel:GetModel("FTDYDETAIL"):SetOptional(.T.)
oModel:GetModel("TGWDETAIL"):SetOptional(.T.)

// Para não repetir linhas nos grids de exceção
oModel:GetModel("STDYDETAIL"):SetUniqueLine( { "TDY_DIASEM" } )
oModel:GetModel("FTDYDETAIL"):SetUniqueLine( { "TDY_DIASEM" } )

Return(oModel)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef()
View - Log de Eventos dos alertas

@Return 	view
@author 	Serviços
@since 		20/09/2013
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ViewDef()

Local oView
Local oModel   := FWLoadModel("TECA580")  
Local oStruTDW := FWFormStruct( 2, "TDW", {|cCpo| !( Alltrim(cCpo)$"TDW_STACFG" ) } )
Local oStruTGW := FWFormStruct( 2, "TGW", {|cCpo| !( Alltrim(cCpo)$"TGW_COD#TGW_EFETDX" ) } )
Local oStruTDX := FWFormStruct( 2, "TDX", {|cCpo| !( Alltrim(cCpo)$"TDX_COD#TDX_CODTDW#TDX_TIPO#TDX_STATUS#TDX_QUANT" ) } )
Local oStruTGX := FWFormStruct( 2, "TGX", {|cCpo| !( Alltrim(cCpo)$"TGX_COD#TGX_CODTDW#TGX_QUANT" ) } )
Local oStrSTDY := FWFormStruct( 2, "TDY", {|cCpo| !( Alltrim(cCpo)$"TDY_COD#TDY_CODTDX#TDY_FERIAD#TDY_TROSEQ" ) } )
Local oStrFTDY := FWFormStruct( 2, "TDY", {|cCpo| !( Alltrim(cCpo)$"TDY_COD#TDY_CODTDX#TDY_FERIAD" ) } )

oView := FWFormView():New()
oView:SetModel(oModel)

//Campo virtual que indicará se o apontamento do material de consumo foi ou não apurado. 
oStruTDX:AddField("TDX_SIT","01",STR0008,STR0008,{},"BT","",Nil,Nil,.F.,"",Nil,Nil,Nil,Nil,.T.,Nil) // "Status"

// Ordena a visualização correta do grid de efetivos
oStruTDX:SetProperty( "TDX_TURNO"	, MVC_VIEW_ORDEM, "02" )
oStruTDX:SetProperty( "TDX_DESTUR"	, MVC_VIEW_ORDEM, "03" )
oStruTDX:SetProperty( "TDX_SEQTUR"	, MVC_VIEW_ORDEM, "04" )

// Ordena a visualização correta do grid de cobertura
oStruTGX:SetProperty( "TGX_ITEM"	, MVC_VIEW_ORDEM, "01" )
oStruTGX:SetProperty( "TGX_TIPO"	, MVC_VIEW_ORDEM, "02" )

oView:AddField("VIEW_TDW" , oStruTDW, "TDWMASTER"  )
oView:AddGrid( "VIEW_TDX", oStruTDX, "TDXDETAIL" )
oView:AddGrid( "VIEW_TGX", oStruTGX, "TGXDETAIL" )
oView:AddGrid( "VIEW_STDY", oStrSTDY, "STDYDETAIL" )
oView:AddGrid( "VIEW_FTDY", oStrFTDY, "FTDYDETAIL" )
oView:AddGrid( "VIEW_TGW" , oStruTGW, "TGWDETAIL"  )

oView:AddIncrementField( "VIEW_TGX", "TGX_ITEM" )		// Item Incremental do Grid

// Area tela principal 
oView:CreateHorizontalBox("SUPERIOR" , 20 )	
oView:CreateHorizontalBox("GRID_TDX" , 30 )
oView:CreateHorizontalBox("INFERIOR" , 50 )

// Area do grid de configuração
oView:CreateVerticalBox( "EFETIVOS" , 046, "GRID_TDX" )
oView:CreateVerticalBox( "ESPACO"   , 001, "GRID_TDX" ) 
oView:CreateVerticalBox( "COBERTURA", 053, "GRID_TDX" ) 

// Area do Grid de Efetivos
oView:CreateHorizontalBox( "EFEGRID" , 088, "EFETIVOS" ) 
oView:CreateHorizontalBox( "ESPGRID" , 002, "EFETIVOS" )
oView:CreateHorizontalBox( "BTNGRID" , 010, "EFETIVOS" ) 

// Criação das abas
oView:CreateFolder( "ABAS", "INFERIOR" )
oView:AddSheet( "ABAS", "ABA01", STR0009 )  // "Configuração"
oView:AddSheet( "ABAS", "ABA02", STR0010 )  // "Exceções"

// Area das abas
oView:CreateHorizontalBox( "ID_ABA01" , 100,,, "ABAS", "ABA01" ) // Define a área da configuração
oView:CreateHorizontalBox( "ID_ABA02" , 050,,, "ABAS", "ABA02" ) // Define a área de exceções
oView:CreateHorizontalBox( "ID_ABA03" , 050,,, "ABAS", "ABA02" ) // Define a área de exceções de feriados

// Botão de Configuração do Turno
oView:AddOtherObject("BTN_ETDX", {|oPanel| At580BtnCfg(oPanel)	})

oView:SetOwnerView( "VIEW_TDW", "SUPERIOR" )
oView:SetOwnerView( "VIEW_TDX", "EFEGRID" )
oView:SetOwnerView( "BTN_ETDX", "BTNGRID" )
oView:SetOwnerView( "VIEW_TGX", "COBERTURA" )
oView:SetOwnerView( "VIEW_TGW" , "ID_ABA01" )
oView:SetOwnerView( "VIEW_STDY", "ID_ABA02" )
oView:SetOwnerView( "VIEW_FTDY", "ID_ABA03" )

oView:EnableTitleView( "VIEW_TDX" , STR0011 )		// "Efetivos"
oView:EnableTitleView( "VIEW_TGX" , STR0012 ) 	// "Cobertura"
oView:EnableTitleView( "VIEW_STDY", STR0013 )		// "Gerais"
oView:EnableTitleView( "VIEW_FTDY", STR0014 ) 	// "Feriados"

oView:AddUserButton(STR0015,"",{|| At580Turno()},,,) // "Inc. Turno Comp."
oView:AddUserButton(STR0016,"",{|| At580VisTur()},,,) // "Visualizar Turno"
oView:AddUserButton(STR0017,"",{|| At580VisEsc()},,,) // "Visualizar Escala"

oView:SetCloseOnOK( {|| .T. } )

Return(oView)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580Turno()
Inclusão completa de todas as sequencias do turno

@Return 	Nil
@author 	Serviços
@since 		16/05/2014
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580Turno()

Local oModel 	  := FwModelActive()
Local oMdlGes	  := oModel:GetModel("TDXDETAIL")
Local oMdlTDW	  := oModel:GetModel("TDWMASTER")
Local aArea	  	  := GetArea()
Local cTurno	  := ""
Local lRet		  := !Empty(oMdlTDW:GetValue("TDW_DESC")) .And. !Empty(oMdlTDW:GetValue("TDW_STATUS"))
Local aSeqs	  	  := {}
 
Local nI

If lRet 

	lRet := ConPad1( Nil, Nil, Nil, "SR6", Nil, Nil, .F. ) // Abre a consulta padrão de turno e retorna o turno selecionado

	If lRet
	 
		cTurno := SR6->R6_TURNO
	
		If MsgYesNo( STR0018 ) // "Deseja realmente incluir o turno com todas as suas sequências ?"
		
			aSeqs := At580GtSeq(cTurno)
			
			For nI:=1 To LEn(aSeqs)
				If ! oMdlGes:SeekLine({{"TDX_TURNO",aSeqs[nI][1]},{"TDX_SEQTUR",aSeqs[nI][2]}})
				
					If	oMdlGes:Length() > 1 .Or. ! Empty(oMdlGes:GetValue("TDX_TURNO")) 
						oMdlGes:AddLine()
					EndIf
					
					oMdlGes:SetValue( "TDX_TURNO" , aSeqs[nI][1]  )
					oMdlGes:SetValue( "TDX_SEQTUR", aSeqs[nI][2] )
					oMdlGes:SetValue( "TDX_QUANT" , 1   )
					oMdlGes:SetValue( "TDX_TIPO"  , "1" )
					oMdlGes:SetValue( "TDX_DESTUR", aSeqs[nI][3] )			
				
				EndIf
			Next nI						
			
		EndIf
	
	EndIf
	
Else

	Help( " ", 1, STR0019, Nil, STR0020, 1 )  //"Atenção"#"Descrição/Status da Escala não preenchido. Preencha os campos obrigatorios!" 

EndIf	
	
RestArea( aArea ) 

Return(Nil)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580Init()

Inicializa a descrição do turno

@author 	Serviços 
@since		19/05/2014
@return 	cDescricao, CHARACTER, conteúdo da descrição 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580Init(cTurno)
	cRet := ALLTRIM(POSICIONE("SR6",1,XFILIAL("SR6") + cTurno,"R6_DESC"))
Return(cRet)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580SeqVld()

Valida a sequencia do turno informada

@author 	Serviços 
@since		19/05/2014
@return 	lRet, Retorna se é uma sequencia valida. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580SeqVld( cTurno, cSequencia, lTurno )

Local oModel    := FwModelActive()
Local oModelTDX := oModel:GetModel("TDXDETAIL")
Local nLinha    := oModelTDX:Getline()
Local aSaveLine := FwSaveRows()
Local cFilTurno := xFilial( "SPJ" , xFilial("SRA") )
Local lRet		  := .T.

Local nI
Local oView

Default lTurno := .F.

If !Empty(cTurno) .And. !Empty(cSequencia) 

	dbSelectArea("SPJ")
	SPJ->(dbSetOrder(1))
	
	lRet := SPJ->( dbSeek( cFilTurno + cTurno + cSequencia ) )
		
	If lRet	
				
		For nI:=1 To oModelTDX:Length()
		
			oModelTDX:GoLine(nI)
			
			If nI <> nLinha .And. !oModelTDX:IsDeleted() 		
				If oModelTDX:GetValue( "TDX_TURNO" ) == cTurno .And. ;
				   oModelTDX:GetValue( "TDX_SEQTUR" ) == cSequencia
				   lRet := .F.
				   Exit		   
				EndIf		
			EndIf
		
		Next nI
		
		If !lRet
			Help( ' ' , 1 , STR0019, , STR0021, 1 , 0 ) // "Sequencia ja cadastrada para a escala!"	
		EndIf
		
	Else
	 		
		Help( ' ' , 1 , 'SEQTURNINV' , , STR0022 , 1 , 0 ) // "Sequencia nao cadastrada para o turno"
				
	EndIf

EndIf

FWRestRows( aSaveLine )

// Valida a obrigatoriedade do turno
If lRet .And. lTurno
	If !Empty( cTurno )	
		lRet := ExistCpo( "SR6", cTurno )		
	EndIf
EndIf

// Valida a obrigatoriedade da sequencia do turno
If lRet .And. !lTurno
	If oModelTDX:GetValue( "TDX_TIPO" ) == "1"
		lRet := !Empty( cSequencia )
	Else 
		lRet := Empty( cSequencia ) .Or. !Empty( cTurno ) 		
	EndIf	
EndIf

If lRet .And. !Empty(cTurno) .And. !Empty(cSequencia)
	
	lLegend := .F.
	
	oModelTDX:SetValue("TDX_STATUS", "3")
	oModelTDX:SetValue("TDX_SIT", At580LgEfe())		
	
	oView := FwViewActive()	
	If oView <> Nil .And. oView:GetModel():GetId()=="TECA580"		
		oView:Refresh("VIEW_TDX")			       	
	EndIf
       
	lLegend := .T.
	        
EndIf

Return( lRet )


//------------------------------------------------------------------------------
/*/{Protheus.doc} PosLinTDX
	 Valida a obrigatoriedade do turno e sequencia

@sample	PosLinTDX()

@since		20/05/2014
@version	P12

/*/
//------------------------------------------------------------------------------
Static Function PosLinTDX(oMdlG, nLine, cAcao, cCampo)

Local lRet      := .T.
Local oMdlFull  := FwModelActive()
Local cMsgVld	  := ""

If oMdlFull <> Nil .And. oMdlFull:GetId()=='TECA580'
	
	If !cAcao == "DELETE" 
	
		If oMdlG:GetValue( "TDX_TIPO" ) == "1"
		
			lRet := !Empty( oMdlG:GetValue( "TDX_TURNO" ) ) .And. ;
					 !Empty( oMdlG:GetValue( "TDX_SEQTUR" ) )
					 					 
			cMsgVld := STR0023	//"Turno e sequência obrigatorios para o tipo de escala efetivo!"
			 					 
		Else 
		
			lRet := Empty( oMdlG:GetValue( "TDX_SEQTUR" ) ) .Or. ;
					 !Empty( oMdlG:GetValue( "TDX_TURNO" ) )
					 
			cMsgVld := STR0024 	//"Sequência informada sem turno!"					 		
					 			 					 		
		EndIf
		
	EndIf	
	
EndIf

If !lRet
	Help(,,"AT580OK",,cMsgVld,1,0) // "Turno e sequência obrigatorios para o tipo de escala efetivo!"
EndIf

Return(lRet)


//------------------------------------------------------------------------------
/*/{Protheus.doc} PreLinTGW
	 Valida a edição das linhas do grid

@sample	PosLinTDX()

@since		23/06/2014
@version	P12

/*/
//------------------------------------------------------------------------------
Static Function PreLinTGW(oMdlG, nLine, cAcao, cCampo)

Local lRet     := .T.
Local oMdlFull := FwModelActive()

If oMdlFull <> Nil .And. oMdlFull:GetId()=="TECA580"	 
	If !IsInCallStack("At580CfgEfe")
		If cAcao == "DELETE" .Or. cAcao == "UNDELETE" .Or. cAcao == "SETVALUE" 
			If cCampo <> Nil .And. !(cCampo $ "TGW_COBTDX|TGW_COBTIP")
				lRet := oMdlG:GetValue("TGW_STATUS") <> "1"					 		
			Endif
		EndIf				
	EndIf
EndIf

If !lRet
	Help(,,"AT580OK",,STR0025,1,0) // "Não é possivel editar/deletar esse tipo de periodo!"
EndIf

Return(lRet)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At580Cmt
	 Realiza a gravação do dados

@sample	At580Cmt(oModel)
@param 		oModel - Model a ser utilizado para a gravação dos dados

@since		21/05/2014
@version	P12

/*/
//------------------------------------------------------------------------------
Function At580Cmt(oModel)

Local lRet    := .T.
Local oMdlTDW := oModel:GetModel("TDWMASTER")
Local oMdlEFE := oModel:GetModel("TDXDETAIL")
Local oMdlTGX := oModel:GetModel("TGXDETAIL")
Local oMdlSEM := oModel:GetModel("STDYDETAIL")
Local oMdlFER := oModel:GetModel("FTDYDETAIL")

Local nI, nJ, lOk

lOk := .T.

For nI:=1 To oMdlEFE:Length()

	oMdlEFE:GoLine(nI)
	
	// Atualiza os campos dos dias normais
	For nJ:=1 To oMdlSEM:Length()
		
		oMdlSEM:GoLine(nJ)
	
		If	Empty(oMdlSEM:GetValue("TDY_DIASEM"))
			Loop
		EndIf
		
		oMdlSEM:SetValue("TDY_FERIAD", "2" )
	
	Next nJ
	
	// Atualiza os campos dos feriados
	For nJ:=1 To oMdlFER:Length()
	
		oMdlFER:GoLine(nJ)
		
		If	Empty(oMdlFER:GetValue("TDY_DIASEM"))
			Loop
		EndIf 		
		
		oMdlFER:SetValue("TDY_FERIAD", "1" )			
	
	Next nJ
	
	oMdlEFE:SetValue("TDX_TIPO" , "1" )
	oMdlEFE:SetValue("TDX_QUANT", 1   )
	
	If Empty(oMdlEFE:GetValue("TDX_STATUS")) .Or. ;
		oMdlEFE:GetValue("TDX_STATUS") == "2" .Or. ;
		oMdlEFE:GetValue("TDX_STATUS") == "3"
		lOk := .F.
	EndIf		

Next nI

// Grid de cobertura
For nI:=1 To oMdlTGX:Length()
	oMdlTGX:GoLine(nI)
	oMdlTGX:SetValue("TGX_QUANT",1)
Next nI

lLegend := .F.
				
If lOk				  
	oMdlTDW:SetValue("TDW_STACFG", "1")
Else
	oMdlTDW:SetValue("TDW_STACFG", "2")
EndIf

lRet 	 := FwFormCommit( oModel )
lLegend := .T.

Return(lRet)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At580VisTur
	 Visualização do horario padrao do turno para a configuração selecionada
	 

@sample	At580VisTur()

@since		23/05/2014
@version	P12

/*/
//------------------------------------------------------------------------------
Function At580VisTur()

Local aArea := GetArea()
Local lRet  := .T.
Local nReg  

Private aDias :=	{ ;	
						{ STR0026, "S", "1", "5", "2" },;	// "Segunda"
						{ STR0027, "S", "1", "5", "3" },;	// "Terca"
						{ STR0028, "S", "1", "5", "4" },;	// "Quarta"
						{ STR0029, "S", "1", "5", "5" },;	// "Quinta"
						{ STR0030, "S", "1", "5", "6" },;	// "Sexta"
						{ STR0031, "C", "3", "7", "7" },;	// "Sabado"
						{ STR0032, "D", "2", "6", "1" } ;	// "Domingo"
					}	
	
Private nLenaDias    := Len( aDias )
Private cSemana		:= Space( GetSx3Cache( "PJ_SEMANA" , "X3_TAMANHO" ) )
Private cLstSemana	:= cSemana
Private cCalc			:= "SPJ"
Private aRotina 	    := { { STR0004, "PesqBrw"   , 0 , 1,,.F.},;  // "Pesquisar"
	                       { STR0005, "Pona080Vis", 0 , 2 } }  // "Visualizar"

dbSelectArea("SR6")
SR6->(dbSetOrder(1))

lRet := SR6->( dbSeek( xFilial("SR6") + FwFldGet("TDX_TURNO") ) )

If lRet
	nReg := SR6->(Recno())
	Pona080Vis( "SR6", nReg , 2 )
Else 
	Help(,,STR0019,,STR0033,1,0) // "Atenção"#"Turno invalido para a consulta!"	
EndIf 

RestArea( aArea )

Return(lRet)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At580GtSeq
	 Retorna a sequencia correta do turno 
	 

@sample	At580VisEsc()

@since		13/06/2014
@version	P12

/*/
//------------------------------------------------------------------------------
Function At580GtSeq(cTurno)

Local cAliasSPJ := GetNextAlias()
Local aSeq		  := {}

BeginSql Alias cAliasSPJ
			
	SELECT  
		SPJ.PJ_TURNO, SPJ.PJ_SEMANA, SR6.R6_DESC
	FROM 
		%Table:SPJ% SPJ 
	LEFT JOIN %Table:SR6% SR6 ON
		SR6.R6_FILIAL = %xFilial:SR6% AND
		SR6.R6_TURNO = SPJ.PJ_TURNO AND 
		SR6.%NotDel%
	WHERE 
		SPJ.PJ_FILIAL = %xFilial:SPJ% AND 
		SPJ.PJ_TURNO = %Exp:cTurno% AND 
		SPJ.%NotDel%
	GROUP BY 
		SPJ.PJ_TURNO, SPJ.PJ_SEMANA, SR6.R6_DESC

EndSql

While (cAliasSPJ)->(!Eof())
		
	aAdd(aSeq, {(cAliasSPJ)->PJ_TURNO,(cAliasSPJ)->PJ_SEMANA, (cAliasSPJ)->R6_DESC })			
				
	(cAliasSPJ)->(dbSkip())
	
End

(cAliasSPJ)->(dbCloseArea())

Return(aSeq)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At580VisEsc
	 Visualização da escala para simulação 
	 

@sample	At580VisEsc()

@since		09/06/2014
@version	P12

/*/
//------------------------------------------------------------------------------
Function At580VisEsc()

Local aArea := GetArea()
Local aButtons := {	{.F.,Nil},;			// 1 - Copiar
					  	{.F.,Nil},;			// 2 - Recortar
					  	{.F.,Nil},;			// 3 - Colar
					  	{.F.,Nil},;			// 4 - Calculadora
					  	{.F.,Nil},;			// 5 - Spool
					  	{.F.,Nil},;			// 6 - Imprimir
					  	{.F.,STR0034},;		// 7 - Confirmar # Salvar
					  	{.T.,STR0035},;		// 8 - Cancelar	# Fechar
					  	{.F.,Nil},;			// 9 - WalkTrhough
					  	{.F.,Nil},;			// 10 - Ambiente
					  	{.F.,Nil},;			// 11 - Mashup
					  	{.F.,Nil},;			// 12 - Help
					  	{.F.,Nil},;			// 13 - Formulário HTML
					  	{.F.,Nil} }			// 14 - ECM

Local lConfirm

If Pergunte("TECA580", .T.)

	oMdlEsc := FwModelActive()

	dbSelectArea("TDW")
	TDW->(dbSetOrder(1)) //TDW_FILIAL+TDW_COD
	
	If TDW->(dbSeek(xFilial("TDW")+FwFldGet("TDW_COD")))	
		lConfirm := ( FWExecView( STR0036,"VIEWDEF.TECA580A", MODEL_OPERATION_UPDATE, /*oDlg*/, {||.T.} /*bCloseOk*/, ;  //  "Visualização da Escala" 
									{||.T.}/*bOk*/,/*nReducao*/, aButtons, {||.T.}/*bCancel*/ ) == 0 )
	Else 
		Help( " ", 1, STR0019, Nil, STR0037, 1 )	// "Atenção" | "Escala não cadastrada, salve a escala para simular a visualização!"		
	EndIf								

EndIf

RestArea(aArea)

Return(Nil)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At580GetMdl
	 Retorna o objeto com o model da escala 
	 

@sample	At580GetMdl()

@since		10/06/2014
@version	P12

/*/
//------------------------------------------------------------------------------
Function At580GetMdl()
Return(oMdlEsc)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At580CfgEfe()
	 Carrega as configurações do Efetivo para a lista de cobertura 
	 
@sample	At580CfgEfe()

@since		20/06/2014
@version	P12

/*/
//------------------------------------------------------------------------------
Function At580CfgEfe()
		  
Local aArea 	 := GetArea()
Local oModel	 := FwModelActive()
Local oMdlTDX  := oModel:GetModel("TDXDETAIL")
Local oMdlTGW  := oModel:GetModel("TGWDETAIL")
Local nOper    := oModel:GetOperation()
Local aHorario := {}

Local oView

Local nI

If nOper <> MODEL_OPERATION_VIEW

	aHorario := At580HorTur( oMdlTDX:GetValue("TDX_TURNO"), oMdlTDX:GetValue("TDX_SEQTUR") )
	
	If Len(aHorario) > 0
	
		If MsgYesNo(STR0038) // "Deseja realmente gerar/substituir as configurações do efetivo ?"		
													 
			If oMdlTGW:Length() > 1 .Or. ; 
			   ( oMdlTGW:GetValue("TGW_HORINI") + oMdlTGW:GetValue("TGW_HORFIM") ) > 0
				
				For nI:=1 To oMdlTGW:Length()			
					oMdlTGW:GoLine(nI)
					oMdlTGW:DeleteLine()
				Next nI		
						
			EndIf
						
			For nI:=1 To Len(aHorario)
			
				If oMdlTGW:Length() > 1 .Or. ; 
			   	   ( oMdlTGW:GetValue("TGW_HORINI") + oMdlTGW:GetValue("TGW_HORFIM") ) > 0
					oMdlTGW:AddLine()
				EndIf 
				
				oMdlTGW:SetValue("TGW_DIASEM", aHorario[nI,1] )
				oMdlTGW:SetValue("TGW_HORINI", aHorario[nI,2] )
				oMdlTGW:SetValue("TGW_HORFIM", aHorario[nI,3] )
				oMdlTGW:SetValue("TGW_STATUS", aHorario[nI,4] )					
							
			Next nI		
					
			lLegend := .F.
			
			oMdlTDX:SetValue("TDX_STATUS", "1")
			oMdlTDX:SetValue("TDX_SIT", At580LgEfe())		
							
			// Atualiza o grid com as informações adicionadas
			oMdlTGW:GoLine(1)
			oView := FwViewActive()
			
			If oView <> Nil .And. oView:GetModel():GetId()=="TECA580"
				oView:Refresh("VIEW_TGW")
				oView:Refresh("VIEW_TDX")			       	
	       EndIf
	       
	       lLegend := .T.             
	       							
		EndIf
		
	Else
		Help( " ", 1, STR0019, Nil, STR0039, 1 )	// "Atenção" | "Não existem horarios cadastrados para esse turno e sequência, na tabela de horarios padrão!"
	EndIf		

Else

	Help( " ", 1, STR0019, Nil, STR0048, 1 )	// "Atenção" | "Processo invalido para essa operação!"

EndIf		

RestArea( aArea )

Return(Nil)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At580HorTur()
	 Retorna todos os periodos e intervalos da tabela de horario padrao 
	 

@sample	At580HorTur( cTurno, cSequencia )

@param  	cTurno, String, turno qual devera ser localizado a tabela
@param  	cSequencia, String, sequencia do turno que devera ser localizado a tabela

@since		16/06/2014
@version	P12

/*/
//------------------------------------------------------------------------------
Function At580HorTur( cTurno, cSequencia )

Local aRet      := {}
Local aDomingo  := {} 
Local aArea  	  := GetArea()

Local nI

dbSelectArea("SPJ")
SPJ->(dbSetOrder(1)) // PJ_FILIAL+PJ_TURNO+PJ_SEMANA 

If SPJ->(dbSeek(xFilial("SPJ")+cTurno+cSequencia))

	While SPJ->(!Eof()) .And. SPJ->PJ_TURNO == cTurno .And. ;
			SPJ->PJ_SEMANA == cSequencia
			
		If (SPJ->PJ_ENTRA1+SPJ->PJ_SAIDA1+;
			SPJ->PJ_ENTRA2+SPJ->PJ_SAIDA2+;
			SPJ->PJ_ENTRA3+SPJ->PJ_SAIDA3+;
			SPJ->PJ_ENTRA4+SPJ->PJ_SAIDA4) > 0
		
			If SPJ->PJ_DIA == "1" // Domingo
				aAdd( aDomingo, SPJ->(Recno()) )			
				SPJ->(dbSkip())	
				Loop		
			EndIf			
			
			At580IntHor( @aRet )
		
		EndIf		
		
		SPJ->(dbSkip())			
	
	EndDo	
	
EndIf

// Adiciona o domingo na ultima posição
If Len(aDomingo) > 0
	For nI:=1 To Len(aDomingo)	
		SPJ->(dbGoTo(aDomingo[nI]))		
		At580IntHor( @aRet )		 
	Next nI
EndIf

RestArea( aArea )

Return(aRet) 


//------------------------------------------------------------------------------
/*/{Protheus.doc} At580IntHor()
	 Adiciona os intervalos da tabela de horario padrao do registro posicionado 
	 da tabela SPJ.
	 

@sample	At580IntHor( @aHorario )

@param  	aHorario, Array, Array qual deseja alimentar com os periodos da tabela 
								de horario padrao

@since		18/06/2014
@version	P12

/*/
//------------------------------------------------------------------------------
Function At580IntHor( aHorario )

Local nHorInt := 0

// Primeiro periodo
If	(SPJ->PJ_ENTRA1 + SPJ->PJ_SAIDA1) > 0

	aAdd( aHorario, { SPJ->PJ_DIA, SPJ->PJ_ENTRA1, SPJ->PJ_SAIDA1,; 
				  	If( SPJ->PJ_TPDIA == "S", "1", "2" ) } )
				  	
	// Segundo periodo
	If	(SPJ->PJ_ENTRA2 + SPJ->PJ_SAIDA2) > 0

		nHorInt := At580Intervalo( SPJ->PJ_ENTRA1, SPJ->PJ_SAIDA1,; 
										 SPJ->PJ_ENTRA2, SPJ->PJ_SAIDA2 )
											
		// Intervalo
		If nHorInt > 0		
			//nHorIni := If( SPJ->PJ_SAIDA1 == 0, SPJ->PJ_ENTRA1, SPJ->PJ_SAIDA1 )
			//nHorFim := If( SPJ->PJ_ENTRA2 == 0, SPJ->PJ_SAIDA2, SPJ->PJ_ENTRA2 )					
			aAdd( aHorario, { SPJ->PJ_DIA, SPJ->PJ_SAIDA1, SPJ->PJ_ENTRA2, "3" } )							
		EndIf											
		
		aAdd( aHorario, { SPJ->PJ_DIA, SPJ->PJ_ENTRA2, SPJ->PJ_SAIDA2,; 
				  		If( SPJ->PJ_TPDIA == "S", "1", "2" ) } )
				  		
		// Terceiro periodo
		If	(SPJ->PJ_ENTRA3 + SPJ->PJ_SAIDA3) > 0
		
			nHorInt := At580Intervalo( SPJ->PJ_ENTRA2, SPJ->PJ_SAIDA2,; 
											 SPJ->PJ_ENTRA3, SPJ->PJ_SAIDA3 )
												
			// Intervalo
			If nHorInt > 0
				aAdd( aHorario, { SPJ->PJ_DIA, SPJ->PJ_SAIDA2, SPJ->PJ_ENTRA3, "3" } )				
			EndIf						
			
			aAdd( aHorario, { SPJ->PJ_DIA, SPJ->PJ_ENTRA3, SPJ->PJ_SAIDA3,; 
				  			If( SPJ->PJ_TPDIA == "S", "1", "2" ) } )
				  			
			// Quarto periodo
			If	(SPJ->PJ_ENTRA4 + SPJ->PJ_SAIDA4) > 0
			
				nHorInt := At580Intervalo( SPJ->PJ_ENTRA3, SPJ->PJ_SAIDA3,; 
												 SPJ->PJ_ENTRA4, SPJ->PJ_SAIDA4 )
													
				// Intervalo
				If nHorInt > 0									
					aAdd( aHorario, { SPJ->PJ_DIA, SPJ->PJ_SAIDA3, SPJ->PJ_ENTRA4, "3" } )				
				EndIf					
			
				aAdd( aHorario, { SPJ->PJ_DIA, SPJ->PJ_ENTRA4, SPJ->PJ_SAIDA4,; 
				  				If( SPJ->PJ_TPDIA == "S", "1", "2" ) } )						  						
	
			EndIf

		EndIf	

	EndIf 						  	

Else 

	// Adiciona itens não configurados
	aAdd( aHorario, { SPJ->PJ_DIA, SPJ->PJ_ENTRA1, SPJ->PJ_SAIDA1,; 
				  	If( SPJ->PJ_TPDIA == "S", "1", "2" ) } )
				  	
EndIf		

Return(Nil)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At580Intervalo()
	 Retorna o intervalo entre periodos da tabela de horario padrao
	 

@sample	At580Intervalo( nEnt1, nSaida1, nEnt2, nSaida2 )

@param  	nEnt1, Double, Horario da primeira entrada
@param  	nSaida1, Double, Horario da primeira saida
@param  	nEnt2, Double, Horario da segunda entrada
@param  	nSaida2, Double, Horario da segunda saida
@param  	aHorario, Array, Array qual deseja alimentar com os periodos da tabela 
								de horario padrao

@since		18/06/2014
@version	P12

/*/
//------------------------------------------------------------------------------
Function At580Intervalo( nEnt1, nSaida1, nEnt2, nSaida2, aHorario )

Local nHoras 	  := 0
Local nHorasNot := 0
Local nHorIni   := 0
Local nHorFim   := 0
Local nRet      := 0
Local dDataHI   := Date()

Local dDataHF

//nHorIni := If( nSaida1 == 0, nEnt1  , nSaida1 )
//nHorFim := If( nEnt2 == 0  , nSaida2, nEnt2   )

nHorIni := nSaida1
nHorFim := nEnt2

dDataHF := If( nHorFim < nHorIni, Date()+1, Date() )		
										
nRet := fCalHoras(dDataHI	,;	//01 -> Data 1
					nHorIni	,;	//02 -> Hora 1
					dDataHF	,;	//03 -> Data 2
					nHorFim	,;	//04 -> Hora 2
					@nHoras	,;	//05 -> <@>Horas Normais Apontadas
					@nHorasNot	,;	//06 -> <@>Horas Noturnas Apontadas
					.F. )			//07 -> Apontar Horas Noturnas

Return(nRet)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At580LCfg()
	 Legenda da Configuração da Escala (Interface).

@sample	At580LCfg()

@since		20/06/2014
@version	P12

/*/
//------------------------------------------------------------------------------
Function At580LCfg()

Local oLegenda := FWLegend():New()

oLegenda:Add( "", "BR_VERDE"   , STR0040 ) 		// Escala configurada
oLegenda:Add( "", "BR_VERMELHO", STR0041 ) 		// Escala inconsistente 
                                              
oLegenda:Activate()
oLegenda:View()
oLegenda:DeActivate()

Return(Nil)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At580LCFBr()
	 Legenda da Configuração da Escala no Browse.

@sample	At580LCFBr()

@return	ExpC - Legenda da Configuração da Escala

@since		20/06/2014
@version	P12

/*/
//------------------------------------------------------------------------------
Function At580LCFBr()

Local cLegenda := "BR_VERDE"			// Cor da legenda

If TDW->TDW_STACFG == "2"
	cLegenda := "BR_VERMELHO"
EndIf

Return(cLegenda)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At580GetLE			   
Cria as informações referentes a legenda do grid de efetivos.

@author  	Serviços
@since 	  	20/06/2014
@version 	P12

@return 	lRet: Retorna .T. quando a criação foi bem sucedida.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580GetLE()

Local	oLegenda := FwLegend():New()

If	lLegend         
	oLegenda:Add( "", "BR_VERDE"   , STR0042 )		//"Configurado"
	oLegenda:Add( "", "BR_AMARELO" , STR0043 )		//"Não Configurado"
	oLegenda:Add( "", "BR_VERMELHO", STR0044	)		//"Configuração Inconsistente"
	oLegenda:View()
	DelClassIntf()
EndIf
                                                                                                                                          
Return(.T.)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At580LgEfe
Atribui a cor na legenda dos efetivos, conforme a necessidade.

@author  	Serviços
@since 	  	20/06/2014
@version	P12

@return 	cRet: Cor da legenda conforme a configuração do efetivo
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580LgEfe()

Local oModel	:= FWModelActive()
Local cStatus := ""

Local cRet
Local oMdlEFE

If oModel:GetId()== "TECA580"

	oMdlEFE := oModel:GetModel("TDXDETAIL")

	If oMdlEFE:GetLine() == 0
		cStatus := TDX->TDX_STATUS 
	Else
		cStatus := oMdlEFE:GetValue("TDX_STATUS") 
	EndIf
	If cStatus == "1" // Configurado
		cRet := "BR_VERDE"
	ElseIf cStatus == "3" // Configuração Inconsistente
		cRet := "BR_VERMELHO"
	Else 	// Nao Configurado
		cRet := "BR_AMARELO" 	
	EndIf
	
EndIf	

Return(cRet)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At580BtnCfg

Criação do botão para a configuração do efetivo referente ao turno

@sample 	At580BtnCfg(oPanel)

@param		oPanel - Painel onde deverá ser criado e exibido o botão
	
@return	Nil 
@author	Serviços
@since		20/06/2014       
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At580BtnCfg( oPanel )

Local oButton

// Ancoramos os objetos no oPanel passado
@ 000, 000 Button oButton Prompt STR0045 Of oPanel Size 065, 012 Pixel //Gerar Configuração
oButton:Align := CONTROL_ALIGN_RIGHT // Alinhamento do botao referente ao panel
oButton:bAction := { || At580CfgEfe() }

Return(Nil)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At580CobEfe

Consulta padrão para selecionar a cobertura disponivel para o efetivo

@sample 	At580CobEfe()

@return	Nil 
@author	Serviços
@since		23/06/2014       
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At580CobEfe()

Local lRet := .F.

oMdlEsc := FwModelActive()

lRet := ( FWExecView( STR0046,"VIEWDEF.TECA580F", MODEL_OPERATION_UPDATE, /*oDlg*/, {||.T.} /*bCloseOk*/, ;  //  "Cobertura do efetivo" 
						{||.T.}/*bOk*/,60,/*aButtons*/, {||.T.}/*bCancel*/ ) == 0 )				

Return(lRet)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At580CobEfe

Consulta padrão para selecionar a cobertura disponivel para o efetivo

@sample 	At580CobEfe()

@return	Nil 
@author	Serviços
@since		23/06/2014       
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At580RetCob()
Local cRet := At580FGetCob()
Return(cRet)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At580CobTip
	Retorna o tipo da cobertura selecionada

@sample 	At580CobTip(cCobertura)

@param		cCobertura, String, Item da cobertura
@return	cRet, String, Tipo da cobrança 

@author	Serviços
@since		23/06/2014       
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At580CobTip(cCobertura, lValid)

Local xRet    

Local aArea   := GetArea()
Local oModel  := FwModelActive()
Local oMdlTGX := oModel:GetModel("TGXDETAIL")
Local oMdlTGW := oModel:GetModel("TGWDETAIL")

If lValid
	
	If !Empty(cCobertura)
	
		xRet := oMdlTGX:SeekLine({{"TGX_ITEM", cCobertura}})
		
		If xRet
			If oMdlTGW:GetValue("TGW_STATUS") == "2" // Folga
				xRet := (oMdlTGX:GetValue("TGX_TIPO") == "1" .Or. oMdlTGX:GetValue("TGX_TIPO") == "4")
			ElseIf oMdlTGW:GetValue("TGW_STATUS") == "3" // Intervalo
				xRet := (oMdlTGX:GetValue("TGX_TIPO") == "2" .Or. oMdlTGX:GetValue("TGX_TIPO") == "3")
			EndIf
		EndIf
		
		If !xRet
			Help( " ", 1, STR0019, Nil, STR0047, 1 )  //"Atenção"#"Tipo de cobertura invalida para a configuração do efetivo!" 
		EndIf
		
	Else
		xRet := .T.	
	EndIf
	 
Else
	If	oMdlTGX:SeekLine({{"TGX_ITEM", cCobertura}})
		xRet := oMdlTGX:GetValue("TGX_TIPO")
	EndIf
EndIf

RestArea(aArea)

Return(xRet)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At580VlEsc
  Valida se a escala está ativa

@sample 	At580VlEsc(cEscala)

@param 		cEscala, Caracter, define qual a escala será validada
@return 	Logico, .F. se a escala for Inativa

@author	Serviços
@since		25/09/2017       
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At580VlEsc(cEscala,lGravado)
Local lRet 		:= .T.
Local aArea		:= GetArea()
Local oModel  	:= Nil
Local oMdlEsc 	:= Nil
Local cAliasTDW	:= GetNextAlias()

Default cEscala		:= ""
Default lGravado	:= .F.

If !lGravado
	oModel  	:= FwModelActive()
	oMdlEsc 	:= oModel:GetModel("TFF_RH")
	cEscala		:= oMdlEsc:GetValue("TFF_ESCALA")
EndIf

If !Empty(cEscala)
	//A query foi feita pois no ambiente GP está dando erro ao utilizar a Area da tabela TDW
	BeginSql Alias cAliasTDW			
		SELECT  
			TDW.TDW_COD, TDW.TDW_STATUS
		FROM 
			%Table:TDW% TDW 
		WHERE 
			TDW.TDW_FILIAL = %xFilial:TDW% AND 
			TDW.TDW_COD = %Exp:cEscala% AND 
			TDW.%NotDel%
	EndSql

	If (cAliasTDW)->(!Eof())
		If (cAliasTDW)->TDW_STATUS == "2"
			lRet := .F.
				If ValType(oModel) == "O"
					oModel:GetModel():SetErrorMessage(oModel:GetId(),"TFF_RH",oModel:GetModel():GetId(),STR0049,STR0049,; 
							STR0050, STR0051 )//"A escala selecionada não está ativa"##"Selecione uma escala ativa"
				Else
					Help( " ", 1, STR0019, Nil, STR0050, 1 )
				EndIf
		EndIf			
	EndIf
Else
	Help( " ", 1, STR0019, Nil, STR0052, 1 ) //"O contrato selecionado não possui escala, campo TFF_ESCALA"
EndIf

RestArea(aArea)

Return lRet
