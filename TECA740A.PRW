#Include "PROTHEUS.CH"
#Include "FWMVCDEF.CH"
#Include "TECA740A.CH" 

#DEFINE _TFLLOCAL		1
#DEFINE _TFLDESLOC	2
#DEFINE _TFLMUNIC		3
#DEFINE _TFLESTADO	4
#DEFINE _TFLDTINI		5	
#DEFINE _TFLDTFIM		6
#DEFINE _TFLPEDTIT	7
#DEFINE _TFJCNTREC	8
#DEFINE _TFJCONTRT  9
#DEFINE _TFJREVISA 10
#DEFINE _TFLCODPAI 11

#DEFINE _TFFITEM		1
#DEFINE _TFFPRODUT	2
#DEFINE _TFFDESCRI	3
#DEFINE _TFFUM		4
#DEFINE _TFFQTDVEN	5
#DEFINE _TFFPERINI	6
#DEFINE _TFFPERFIM	7
#DEFINE _TFFHORAIN	8
#DEFINE _TFFHORAFI	9	
#DEFINE _TFFFUNCAO	10
#DEFINE _TFFDFUNC		11	
#DEFINE _TFFTURNO		12
#DEFINE _TFFDTURNO	13
#DEFINE _TFFCARGO		14
#DEFINE _TFFDCARGO	15
#DEFINE _TFFCALCMD	16
#DEFINE _TFFNARMA		17
#DEFINE _TFFNCOLE		18
#DEFINE _TFFPRCVEN	19
#DEFINE _TFFDESCON	20
#DEFINE _TFFVALDES	21
#DEFINE _TFFPRCVEN	22
#DEFINE _TFFLUCRO		23
#DEFINE _TFFTXLUCR	24
#DEFINE _TFFADM		25
#DEFINE _TFFTXADM		26
#DEFINE _TFFSUBTOT	27	
#DEFINE _TFFTOTMI		28
#DEFINE _TFFTOTMC		29
#DEFINE _TFFTOTAL		30
#DEFINE _TFFESCALA	31
#DEFINE _TFFCALEND	32
#DEFINE _TFFSEQTRN	33
#DEFINE _TFFCNTREC 	34
#DEFINE _TFFTESPED 	35
#DEFINE _TFFINSALU 	36
#DEFINE _TFFGRAUIN 	37
#DEFINE _TFFPERICU 	38
#DEFINE _TFFPDMTMI 39
#DEFINE _TFFPRMTMI 40
#DEFINE _TFFVLMTMI 41
#DEFINE _TFFPDMTMC 42
#DEFINE _TFFPRMTMC 43
#DEFINE _TFFVLMTMC 44
#DEFINE _TFFCONTRT 45
#DEFINE _TFFCONREV 46
#DEFINE _TFFTIPORH 47
#DEFINE _TFFGRAVRH 48

#DEFINE _TFGITEM		1
#DEFINE _TFGPRODUT	2
#DEFINE _TFGDESCRI	3
#DEFINE _TFGUM		4
#DEFINE _TFGQTDVEN	5
#DEFINE _TFGPERINI	6
#DEFINE _TFGPERFIM	7
#DEFINE _TFGTES		8
#DEFINE _TFGCODPAI	9
#DEFINE _TFGPRCVEN	10
#DEFINE _TFGTOTAL		11
#DEFINE _TFGVALDES	12
#DEFINE _TFGDESCON	13
#DEFINE _TFGTOTGER	14
#DEFINE _TFGTXLUCR	15
#DEFINE _TFGLUCRO		16
#DEFINE _TFGADM		17
#DEFINE _TFGTXADM		18
#DEFINE _TFGTESPED	20
#DEFINE _TFGTIPMAT	21
#DEFINE _TFGGRVMAT	22

STATIC aLocal := {}
STATIC aRecursos := {}
Static _lGSVinc := Nil

//----------------------------------------------------------
/*/{Protheus.doc} ModelDef()
Model - Cortesia Recursos Humanos

@Return 	model
@author 	Serviços
@since 		10/04/2014
/*/
//----------------------------------------------------------
Static Function ModelDef()

Local oModel

Local oStrCabec := FWFormStruct(1,"TFL")
Local oStrGrid  := FWFormStruct(1,"TFF")
Local aAux		  := {}
Local bCommit   := { |oModel| At740ACommit(oModel) }
Local bPreVal 	:= {|oModel,nLine,cAcao,cCampo,xValor| A740aPreVld( oModel,nLine,cAcao,cCampo,xValor ) }
Local _lGSVinc 	:=  SuperGetMv("MV_GSVINC",,.F.) .AND. !SuperGetMv("MV_ORCPRC",,.F.)

_lGSVinc := SuperGetMV("MV_GSVINC",, .F.)

oStrCabec:SetProperty( "TFL_CODPAI", MODEL_FIELD_OBRIGAT, .F. )

//-- Adiciona campos de contrato recorrente.
oStrCabec:AddField(	 STR0005,;								// 	[01]  C   Titulo do campo  //"Contr. Rec."
					 STR0005,;								// 	[02]  C   ToolTip do campo //"Contr. Rec."
					 "TFJ_CNTREC",;								// 	[03]  C   Id do Field
					 "C",;										// 	[04]  C   Tipo do campo
					 TamSX3("TFJ_CNTREC")[1],;					// 	[05]  N   Tamanho do campo
					 0,;										// 	[06]  N   Decimal do campo
					 NIL,;										// 	[07]  B   Code-block de validação do campo
					 NIL,;										// 	[08]  B   Code-block de validação When do campo
					 NIL,;										//	[09]  A   Lista de valores permitido do campo
					 .F.,;										//	[10]  L   Indica se o campo tem preenchimento obrigatório
					 {|| "2"},;									//	[11]  B   Code-block de inicializacao do campo
					 NIL,;										//	[12]  L   Indica se trata-se de um campo chave
					 .T.,;										//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
					 .T.)										// 	[14]  L   Indica se o campo é virtual

oStrGrid:AddField(	 STR0006,;								// 	[01]  C   Titulo do campo //"RH Gravado"
					 STR0006,;								// 	[02]  C   ToolTip do campo //"RH Gravado"
					 "TFF_GRAVRH",;								// 	[03]  C   Id do Field
					 "C",;										// 	[04]  C   Tipo do campo
					 1,;										// 	[05]  N   Tamanho do campo
					 0,;										// 	[06]  N   Decimal do campo
					 NIL,;										// 	[07]  B   Code-block de validação do campo
					 NIL,;										// 	[08]  B   Code-block de validação When do campo
					 {STR0007,STR0008},;						//	[09]  A   Lista de valores permitido do campo '1=Sim','2=Não'
					 .F.,;										//	[10]  L   Indica se o campo tem preenchimento obrigatório
					 {|| "2"},;								//	[11]  B   Code-block de inicializacao do campo
					 NIL,;										//	[12]  L   Indica se trata-se de um campo chave
					 .T.,;										//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
					 .T.)										// 	[14]  L   Indica se o campo é virtual
					 
oStrGrid:SetProperty("TFF_PERINI",MODEL_FIELD_VALID,{|oMdlVld|At740VldDt("TFF_GRID","TFF_PERINI","TFF_PERINI","TFF_PERFIM", Nil, .T. )})
oStrGrid:SetProperty("TFF_PERFIM",MODEL_FIELD_VALID,{|oMdlVld|At740VldDt("TFF_GRID","TFF_PERFIM","TFF_PERINI","TFF_PERFIM", NIL, .T. )})

oStrGrid:SetProperty( "TFF_PRCVEN", MODEL_FIELD_OBRIGAT, .F. )

If IsInCallStack("At870GerOrc")
	
	xAux := FwStruTrigger( 'TFF_SUBTOT', 'TFF_TOTAL', 'At740AInPad()',.F.)
	oStrGrid:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
	
	xAux := FwStruTrigger( 'TFF_TXLUCR', 'TFF_TOTAL', 'At740InPad()',.F.)
	oStrGrid:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])	
		
	xAux := FwStruTrigger( 'TFF_TXADM', 'TFF_TOTAL', 'At740InPad()',.F.)
	oStrGrid:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])

	oStrGrid:SetProperty('TFF_PRCVEN',MODEL_FIELD_VALID,{|oModel|At740VlVlr("TFF_GRID","TFF_PRCVEN",oModel)})

Else
	oStrGrid:SetProperty( "TFF_PRCVEN", MODEL_FIELD_OBRIGAT, .F. )
EndIf

oStrGrid:SetProperty( "TFF_LOCAL",	MODEL_FIELD_OBRIGAT, .F. )
oStrGrid:SetProperty( "TFF_CODPAI", MODEL_FIELD_OBRIGAT, .F. )


// Cria o objeto do Modelo de Dados
oModel := MPFormModel():New("TECA740A", /*bPreValidacao*/, /*bPosValidacao*/, bCommit, /*bCancel*/ )

oModel:AddFields("TFL_CAB",/*cOwner*/,oStrCabec, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

oModel:AddGrid( "TFF_GRID", "TFL_CAB", oStrGrid, /* bLinePre */ ,/*bLinePost*/, bPreVal , /*bPosVal*/)
oModel:SetRelation( "TFF_GRID", { { "TFF_FILIAL", "xFilial('TFF')" }, { "TFF_CODPAI", "TFL_CODIGO" } }, TFF->(IndexKey(3)) )

oModel:GetModel("TFF_GRID"):SetOptional(.T.)

oModel:SetPrimaryKey( {} )
oModel:SetDescription(STR0001) // "Cortesia de Recursos Humanos"

If _lGSVinc
	oStrGrid:SetProperty( "TFF_PERINI", MODEL_FIELD_INIT,{|oMdl| oMdl:GetModel():GetModel("TFL_CAB"):GetValue("TFL_DTINI") } )
	oStrGrid:SetProperty( "TFF_PERFIM", MODEL_FIELD_INIT,{|oMdl| oMdl:GetModel():GetModel("TFL_CAB"):GetValue("TFL_DTFIM") } )
	
	oStrGrid:SetProperty("TFF_ESCALA", MODEL_FIELD_VALID, {|oModel| At740InMtE(oModel:GetValue("TFF_PRODUT"), oModel:GetValue("TFF_ESCALA")) } )
	oStrGrid:SetProperty("TFF_FUNCAO", MODEL_FIELD_VALID, {|oModel| At740InFun(oModel:GetValue("TFF_PRODUT"), oModel:GetValue("TFF_FUNCAO")) } )
	oStrGrid:SetProperty("TFF_TURNO", MODEL_FIELD_VALID, {|oModel| At740InTur(oModel:GetValue("TFF_PRODUT"), oModel:GetValue("TFF_TURNO")) } )
	
EndIf

oModel:SetActivate( {|oModel| InitDados( oModel ) } )
 									  
Return(oModel)


//----------------------------------------------------------
/*/{Protheus.doc} ViewDef()
View - Cortesia Recursos Humanos

@Return 	view
@author 	Serviços
@since 		10/04/2014
/*/
//----------------------------------------------------------
Static Function ViewDef()

Local oView
Local oModel := FWLoadModel("TECA740A")
Local cOperation := A740GetOper()

Local oStrCabec := FWFormStruct( 2, "TFL", {|cCpo| At740SelFields( "TFL", Alltrim(cCpo) ) .And. ;
														  At740ASelFlds( "TFL", Alltrim(cCpo) ) } )
Local oStrGrid  := FWFormStruct( 2, "TFF", {|cCpo| At740SelFields( "TFF", Alltrim(cCpo) ) .And. ;
														  At740ASelFlds( "TFF", Alltrim(cCpo) ) } )
														
Local _lGSVinc 	:=  SuperGetMv("MV_GSVINC",,.F.) .AND. !SuperGetMv("MV_ORCPRC",,.F.)
														  
If cOperation <> 1 //Alteração do orçamento - Revisão - Item extra													    
	oStrCabec:SetProperty("*",MVC_VIEW_CANCHANGE, .F.)
	oStrGrid:SetProperty("TFF_TIPORH", MVC_VIEW_CANCHANGE, .F.)
Else
	oStrCabec:SetProperty("*",MVC_VIEW_CANCHANGE, .F.)
	oStrGrid:SetProperty("*", MVC_VIEW_CANCHANGE, .F.)
EndIf

oView := FWFormView():New()
oView:SetModel( oModel )

oView:SetDescription(STR0001) // "Cortesia de Recursos Humanos"
oView:SetCloseOnOk({|| .T. } )

If _lGSVinc
	oStrGrid:SetProperty("TFF_FUNCAO", MVC_VIEW_LOOKUP, "TFFSRJ")
	oStrGrid:SetProperty("TFF_ESCALA", MVC_VIEW_LOOKUP,"TFFTDW")
EndIf

oView:AddField( "VIEW_CAB"  , oStrCabec , "TFL_CAB"  )
oView:AddGrid( "VIEW_GRID" , oStrGrid  , "TFF_GRID" )

oStrGrid:RemoveField("TFF_REFVLR")


//--------------------------------------
//		Cria os Box's
//--------------------------------------
oView:CreateHorizontalBox( "TOP"   , 25 )
oView:CreateHorizontalBox( "DOWN"	, 75 )  

//--------------------------------------
//		Associa os componentes ao Box
//--------------------------------------
oView:SetOwnerView( "VIEW_CAB" , "TOP" 	)
oView:SetOwnerView( "VIEW_GRID", "DOWN" 	)

oView:EnableTitleView( "VIEW_GRID", STR0002 )  // "Recursos Humanos"

// Incrementa automaticamente o campo ao incluir uma nova linha
oView:AddIncrementField( "TFF_GRID", "TFF_ITEM" )

Return(oView)


//----------------------------------------------------------
/*/{Protheus.doc} InitDados()
Inicializa as informações da Cortesia Recursos Humanos

@sample 	InitDados()

@param  	oModel, Objeto, objeto geral do model que será alterado

@author 	Serviços
@since 		14/04/2013
/*/
//----------------------------------------------------------
Static Function InitDados(oModel)

Local oModelRH	:= oModel:GetModel("TFF_GRID")
Local aSaveRows := {}
Local cGsDsGcn 	:= ""
Local cOperation := A740GetOper()

If oModel:GetOperation() == MODEL_OPERATION_INSERT 
	cGsDsGcn	:= SuperGetMv("MV_GSDSGCN",,"2")
Else
	cGsDsGcn	:= TFJ->TFJ_DSGCN
EndIf

At740ASetModel( oModel, aLocal, aRecursos )

If cGsDsGcn == "1"
	oModel:GetModel('TFF_GRID'):GetStruct():SetProperty('TFF_TESPED',MODEL_FIELD_OBRIGAT,.T.)	
Endif

If cOperation == 1	//Modo de visualização do orçamento
	oModelRH:SetNoInsertLine(.T.)
	oModelRH:SetNoDeleteLine(.T.)
EndIf

FwRestRows( aSaveRows )

Return(Nil)


//----------------------------------------------------------
/*/{Protheus.doc} At740ASetLoc()
Alimenta as informações do array de locais para o carregamento do grid

@sample 	At740ASetLoc()

@param  	oMdlLocal, Objeto, objeto geral do model que será utilizado
			para popular o array
@param 		lRot704A, Boolean, verifica se esta sendo executado pela 
			cortesia de RH.			
@param  	cLocal, String, local utilizado para a pesquisa

@author 	Serviços
@since 		14/04/2013
/*/
//----------------------------------------------------------
Function At740ASetLoc( oMdlLocal, lRot704A, cLocal )

Local aLocal704A := {}
Local aLenLocal	:= 0

If oMdlLocal:SeekLine({{ "TFL_LOCAL", cLocal }})

	aAdd( aLocal704A, Array(_TFLCODPAI) )	
	
	aLenLocal := Len(aLocal704A)
		
	aLocal704A[aLenLocal][_TFLLOCAL ]  := oMdlLocal:GetValue("TFL_LOCAL") 
	aLocal704A[aLenLocal][_TFLDESLOC ] := oMdlLocal:GetValue("TFL_DESLOC") 
	aLocal704A[aLenLocal][_TFLMUNIC ]  := oMdlLocal:GetValue("TFL_MUNIC") 
	aLocal704A[aLenLocal][_TFLESTADO ] := oMdlLocal:GetValue("TFL_ESTADO") 
	aLocal704A[aLenLocal][_TFLDTINI ]  := oMdlLocal:GetValue("TFL_DTINI") 
	aLocal704A[aLenLocal][_TFLDTFIM ]  := oMdlLocal:GetValue("TFL_DTFIM") 
	aLocal704A[aLenLocal][_TFLPEDTIT]  := oMdlLocal:GetValue("TFL_PEDTIT")
	aLocal704A[aLenLocal][_TFJCNTREC]  := oMdlLocal:GetModel():GetModel("TFJ_REFER"):GetValue("TFJ_CNTREC")
	aLocal704A[aLenLocal][_TFJCONTRT]  := oMdlLocal:GetValue("TFL_CONTRT")
	aLocal704A[aLenLocal][_TFJREVISA]  := oMdlLocal:GetValue("TFL_CONREV")
	aLocal704A[aLenLocal][_TFLCODPAI]  := oMdlLocal:GetValue("TFL_CODPAI")
	
EndIf

If lRot704A
	aLocal := aLocal704A
EndIf		  

Return(aLocal704A)


//----------------------------------------------------------
/*/{Protheus.doc} At740ASetRec()
Alimenta as informações do array de locais para o carregamento do grid

@sample 	At740ASetRec()

@param  	oModel, Objeto, objeto geral do model que será utilizado
			para popular o array
@param 		lRot704A, Boolean, verifica se esta sendo executado pela 
			cortesia de RH.			
@param  	cLocal, String, local utilizado para a pesquisa

@author 	Serviços
@since 		14/04/2013
/*/
//----------------------------------------------------------
Function At740ASetRec( oModel, lRot704A, cLocal )

Local oModelLC := oModel:GetModel("TFL_LOC")
Local oModelRH := oModel:GetModel("TFF_RH")
Local aRec704A := {}
Local nLenRec  := 0
Local cGsDsGcn := ""
Local nI

If oModel:GetOperation() == MODEL_OPERATION_INSERT 
	cGsDsGcn	:= SuperGetMv("MV_GSDSGCN",,"2")
Else
	cGsDsGcn	:= TFJ->TFJ_DSGCN
EndIf

If oModelLC:SeekLine({{ "TFL_LOCAL", cLocal }})

	For nI:=1 To oModelRH:Length()
		
		oModelRH:GoLine(nI)
		
		If oModelRH:IsDeleted()
			Loop
		EndIf
		
		If lRot704A
			If oModelRH:GetValue("TFF_COBCTR") <> "2"				
				Loop
			EndIf
		EndIf
		
		aAdd( aRec704A, Array(_TFFGRAVRH) )		
		
		nLenRec := Len(aRec704A) 
					
		aRec704A[nLenRec][_TFFITEM ] := oModelRH:GetValue("TFF_ITEM")
		aRec704A[nLenRec][_TFFPRODUT ] := oModelRH:GetValue("TFF_PRODUT")
		aRec704A[nLenRec][_TFFDESCRI ] := oModelRH:GetValue("TFF_DESCRI")
		aRec704A[nLenRec][_TFFUM ] := oModelRH:GetValue("TFF_UM")
		aRec704A[nLenRec][_TFFQTDVEN ] := oModelRH:GetValue("TFF_QTDVEN")
		aRec704A[nLenRec][_TFFPERINI ] := oModelRH:GetValue("TFF_PERINI")
		aRec704A[nLenRec][_TFFPERFIM ] := oModelRH:GetValue("TFF_PERFIM")
		aRec704A[nLenRec][_TFFHORAIN ] := oModelRH:GetValue("TFF_HORAIN")
		aRec704A[nLenRec][_TFFHORAFI ] := oModelRH:GetValue("TFF_HORAFI")
		aRec704A[nLenRec][_TFFFUNCAO ] := oModelRH:GetValue("TFF_FUNCAO")
		aRec704A[nLenRec][_TFFDFUNC ] := oModelRH:GetValue("TFF_DFUNC")
		aRec704A[nLenRec][_TFFTURNO ] := oModelRH:GetValue("TFF_TURNO")
		aRec704A[nLenRec][_TFFDTURNO ] := oModelRH:GetValue("TFF_DTURNO")
		aRec704A[nLenRec][_TFFCARGO ] := oModelRH:GetValue("TFF_CARGO")
		aRec704A[nLenRec][_TFFDCARGO ] := oModelRH:GetValue("TFF_DCARGO")
		aRec704A[nLenRec][_TFFCALCMD ] := oModelRH:GetValue("TFF_CALCMD")
		aRec704A[nLenRec][_TFFNARMA ] := oModelRH:GetValue("TFF_NARMA")
		aRec704A[nLenRec][_TFFNCOLE ] := oModelRH:GetValue("TFF_NCOLE")
		aRec704A[nLenRec][_TFFESCALA ] := oModelRH:GetValue("TFF_ESCALA")
		aRec704A[nLenRec][_TFFCALEND ] := oModelRH:GetValue("TFF_CALEND")
		aRec704A[nLenRec][_TFFSEQTRN ] := oModelRH:GetValue("TFF_SEQTRN")
		aRec704A[nLenRec][_TFFCNTREC ] := oModelRH:GetModel():GetModel("TFJ_REFER"):GetValue("TFJ_CNTREC")

		
		If IsInCallStack("At870GerOrc")
			aRec704A[nLenRec][_TFFPRCVEN ] := oModelRH:GetValue("TFF_PRCVEN")
			aRec704A[nLenRec][_TFFDESCON ] := oModelRH:GetValue("TFF_DESCON")
			aRec704A[nLenRec][_TFFVALDES ] := oModelRH:GetValue("TFF_VALDES")
			aRec704A[nLenRec][_TFFPRCVEN ] := oModelRH:GetValue("TFF_PRCVEN")
			aRec704A[nLenRec][_TFFLUCRO ] := oModelRH:GetValue("TFF_LUCRO")
			aRec704A[nLenRec][_TFFTXLUCR ] := oModelRH:GetValue("TFF_TXLUCR")
			aRec704A[nLenRec][_TFFADM ] := oModelRH:GetValue("TFF_ADM")
			aRec704A[nLenRec][_TFFTXADM ] := oModelRH:GetValue("TFF_TXADM")
			aRec704A[nLenRec][_TFFSUBTOT ] := oModelRH:GetValue("TFF_SUBTOT")
			aRec704A[nLenRec][_TFFTOTMI ] := oModelRH:GetValue("TFF_TOTMI")
			aRec704A[nLenRec][_TFFTOTMC ] := oModelRH:GetValue("TFF_TOTMC")
			aRec704A[nLenRec][_TFFTOTAL ] := oModelRH:GetValue("TFF_TOTAL")
		EndIf	
	
		If cGsDsGcn == "1"
			aRec704A[nLenRec][_TFFTESPED ] := oModelRH:GetValue("TFF_TESPED")
		Endif
	
		aRec704A[nLenRec][_TFFINSALU ] := oModelRH:GetValue("TFF_INSALU")
		aRec704A[nLenRec][_TFFGRAUIN ] := oModelRH:GetValue("TFF_GRAUIN")
		aRec704A[nLenRec][_TFFPERICU ] := oModelRH:GetValue("TFF_PERICU")
		aRec704A[nLenRec][_TFFPDMTMI ] := oModelRH:GetValue("TFF_PDMTMI")
		aRec704A[nLenRec][_TFFPRMTMI ] := oModelRH:GetValue("TFF_PRMTMI")
		aRec704A[nLenRec][_TFFVLMTMI ] := oModelRH:GetValue("TFF_VLMTMI")
		aRec704A[nLenRec][_TFFPDMTMC ] := oModelRH:GetValue("TFF_PDMTMC")
		aRec704A[nLenRec][_TFFPRMTMC ] := oModelRH:GetValue("TFF_PRMTMC")
		aRec704A[nLenRec][_TFFVLMTMC ] := oModelRH:GetValue("TFF_VLMTMC")
		aRec704A[nLenRec][_TFFCONTRT ] := oModelRH:GetValue("TFF_CONTRT")
		aRec704A[nLenRec][_TFFCONREV ] := oModelRH:GetValue("TFF_CONREV")
		aRec704A[nLenRec][_TFFTIPORH ] := oModelRH:GetValue("TFF_TIPORH")
		aRec704A[nLenRec][_TFFGRAVRH ] := oModelRH:GetValue("TFF_GRAVRH")
	
	Next nI

EndIf

If lRot704A
	aRecursos := aRec704A
EndIf		  

Return(aRec704A)


//----------------------------------------------------------
/*/{Protheus.doc} At740AGet()
Retorna as informações do array de locais para o carregamento do grid

@sample 	At740AGet()


@author 	Serviços
@since 		14/04/2013
/*/
//----------------------------------------------------------
Function At740AGet()
Return(aRecursos)


//----------------------------------------------------------
/*/{Protheus.doc} At740ASetModel()
Atualiza os models com as informações de local e recursos humanos

@sample 	At740ASetModel()

@param  	oMdlLocal, Objeto, objeto geral do model que será utilizado
			para popular o array
@param 		lRot704A, Boolean, verifica se esta sendo executado pela 
			cortesia de RH.			
@param  	cLocal, String, local utilizado para a pesquisa

@author 	Serviços
@since 		14/04/2013
/*/
//----------------------------------------------------------
Function At740ASetModel( oMdlPri, aLocGrid, aRecHumano, aMatImp, aMatCons )

Local oMdlLocal := oMdlPri:GetModel("TFL_CAB")
Local oModelRH  := oMdlPri:GetModel("TFF_GRID")
Local nPosMat	  := 0
Local oStruct	:= Nil
Local bWhen		:= {|| }
Local cGsDsGcn 	:= ""
Local cContrt	:= aLocGrid[1][9]
Local cRevisa	:= aLocGrid[1][10]
Local cGsMtMi  := IIF(Empty(Posicione( "TFJ", 5, xFilial("TFJ") + cContrt + cRevisa, "TFJ_GSMTMI")),M->TFJ_GSMTMI,Posicione( "TFJ", 5, xFilial("TFJ") + cContrt + cRevisa, "TFJ_GSMTMI"))
Local cGsMtMc  := IIF(Empty(Posicione( "TFJ", 5, xFilial("TFJ") + cContrt + cRevisa, "TFJ_GSMTMC")),M->TFJ_GSMTMC,Posicione( "TFJ", 5, xFilial("TFJ") + cContrt + cRevisa, "TFJ_GSMTMC"))

Local nI, nX, nY

Local oModelMI
Local oModelMC

Default aRecHumano	:= {}
Default aMatImp	  	:= {}
Default aMatCons		:= {}

If oMdlPri:GetOperation() == MODEL_OPERATION_INSERT 
	cGsDsGcn	:= SuperGetMv("MV_GSDSGCN",,"2")
Else
	cGsDsGcn	:= TFJ->TFJ_DSGCN
EndIf

If Len(aLocGrid) > 0

	For nI:=1 To Len(aLocGrid)
		
		If nI > 1
			oMdlLocal:AddLine()
		EndIf
		
		oMdlLocal:SetValue( "TFL_LOCAL", aLocGrid[nI][_TFLLOCAL ] )   
		oMdlLocal:SetValue( "TFL_DESLOC", aLocGrid[nI][_TFLDESLOC ] )
		oMdlLocal:SetValue( "TFL_MUNIC", aLocGrid[nI][_TFLMUNIC ] )
		oMdlLocal:SetValue( "TFL_ESTADO", aLocGrid[nI][_TFLESTADO ] )  
		oMdlLocal:SetValue( "TFL_DTINI", aLocGrid[nI][_TFLDTINI ] )   
		oMdlLocal:SetValue( "TFL_DTFIM", aLocGrid[nI][_TFLDTFIM ] )   
		oMdlLocal:SetValue( "TFL_PEDTIT", aLocGrid[nI][_TFLPEDTIT] )
		oMdlLocal:SetValue( "TFJ_CNTREC", aLocGrid[nI][_TFJCNTREC] )
		oMdlLocal:LoadValue( "TFL_CODPAI", aLocGrid[nI][_TFLCODPAI] )
		
		If Len(aRecHumano) > 0
		
			For nX:=1 To Len(aRecHumano)
		
				If nX > 1
					oModelRH:AddLine()
				EndIf
				
				oModelRH:GoLine(nX)
				oModelRH:SetValue( "TFF_ITEM", aRecHumano[nX][_TFFITEM ] )
				oModelRH:SetValue( "TFF_PRODUT", aRecHumano[nX][_TFFPRODUT ] )
				oModelRH:SetValue( "TFF_DESCRI", aRecHumano[nX][_TFFDESCRI ] )
				oModelRH:SetValue( "TFF_UM", aRecHumano[nX][_TFFUM ] )
				oModelRH:LoadValue( "TFF_QTDVEN", aRecHumano[nX][_TFFQTDVEN ] )
				oModelRH:SetValue( "TFF_PERINI", aRecHumano[nX][_TFFPERINI ]  )
				
				oStruct := oModelRH:GetStruct()
				bWhen 	:= oStruct:GetProperty("TFF_PERFIM",MODEL_FIELD_WHEN)
				oStruct:SetProperty("TFF_PERFIM",MODEL_FIELD_WHEN,{|| .T. })
				oModelRH:SetValue( "TFF_PERFIM", aRecHumano[nX][_TFFPERFIM ] ) 
				oStruct:SetProperty("TFF_PERFIM",MODEL_FIELD_WHEN,bWhen)

				oModelRH:SetValue( "TFF_HORAIN", aRecHumano[nX][_TFFHORAIN ] )
				oModelRH:SetValue( "TFF_HORAFI", aRecHumano[nX][_TFFHORAFI ] )
				oModelRH:SetValue( "TFF_FUNCAO", aRecHumano[nX][_TFFFUNCAO ] )
				oModelRH:SetValue( "TFF_DFUNC", aRecHumano[nX][_TFFDFUNC ] )
				oModelRH:SetValue( "TFF_TURNO", aRecHumano[nX][_TFFTURNO ] )
				oModelRH:SetValue( "TFF_DTURNO", aRecHumano[nX][_TFFDTURNO ] )
				oModelRH:SetValue( "TFF_CARGO", aRecHumano[nX][_TFFCARGO ] )
				oModelRH:SetValue( "TFF_DCARGO", aRecHumano[nX][_TFFDCARGO ] )
				oModelRH:SetValue( "TFF_CALCMD", aRecHumano[nX][_TFFCALCMD ] )
				oModelRH:SetValue( "TFF_NARMA", aRecHumano[nX][_TFFNARMA ] )
				oModelRH:SetValue( "TFF_NCOLE", aRecHumano[nX][_TFFNCOLE ] )
				oModelRH:SetValue( "TFF_COBCTR", "2" )
				oModelRH:SetValue( "TFF_ESCALA", aRecHumano[nX][_TFFESCALA ] )				
				oModelRH:SetValue( "TFF_CALEND", aRecHumano[nX][_TFFCALEND ] )
				oModelRH:SetValue( "TFF_SEQTRN", aRecHumano[nX][_TFFSEQTRN ] )
								
				If IsInCallStack("At870GerOrc")
					 oModelRH:SetValue( "TFF_DESCON", aRecHumano[nX][_TFFDESCON ] )
					 oModelRH:SetValue( "TFF_VALDES", aRecHumano[nX][_TFFVALDES ] )
					 oModelRH:LoadValue( "TFF_PRCVEN", aRecHumano[nX][_TFFPRCVEN ] )
					 oModelRH:SetValue( "TFF_LUCRO", aRecHumano[nX][_TFFLUCRO ] )
					 oModelRH:SetValue( "TFF_TXLUCR", aRecHumano[nX][_TFFTXLUCR ] )
					 oModelRH:SetValue( "TFF_ADM", aRecHumano[nX][_TFFADM ] )
					 oModelRH:SetValue( "TFF_TXADM", aRecHumano[nX][_TFFTXADM ] )
					 oModelRH:LoadValue( "TFF_SUBTOT", aRecHumano[nX][_TFFSUBTOT ] )
					 oModelRH:SetValue( "TFF_TOTMI", aRecHumano[nX][_TFFTOTMI ] )
					 oModelRH:SetValue( "TFF_TOTMC", aRecHumano[nX][_TFFTOTMC ] )
					 oModelRH:SetValue( "TFF_TOTAL", aRecHumano[nX][_TFFTOTAL ] )
				EndIf							
				
				If cGsMtMi == "3" //Material por percentual
						 oModelRH:SetValue( "TFF_PDMTMI", aRecHumano[nX][_TFFPDMTMI ] )
						 oModelRH:SetValue( "TFF_PRMTMI", aRecHumano[nX][_TFFPRMTMI ] )
						 oModelRH:SetValue( "TFF_VLMTMI", aRecHumano[nX][_TFFVLMTMI ] )
					 ElseIf cGsMtMi == "2" //Material por valor
						 oModelRH:SetValue( "TFF_PDMTMI", aRecHumano[nX][_TFFPDMTMI ] )
						 oModelRH:SetValue( "TFF_VLMTMI", aRecHumano[nX][_TFFVLMTMI ] )
					 Endif
					 If cGsMtMc == "3" //Material por percentual
						 oModelRH:SetValue( "TFF_PDMTMC", aRecHumano[nX][_TFFPDMTMC ] )
						 oModelRH:SetValue( "TFF_PRMTMC", aRecHumano[nX][_TFFPRMTMC ] )
						 oModelRH:SetValue( "TFF_VLMTMC", aRecHumano[nX][_TFFVLMTMC ] )
					 ElseIf cGsMtMc == "2" //Material por valor
					 	 oModelRH:SetValue( "TFF_PDMTMC", aRecHumano[nX][_TFFPDMTMC ] )
						 oModelRH:SetValue( "TFF_VLMTMC", aRecHumano[nX][_TFFVLMTMC ] )
				EndIf
				
				If cGsDsGcn == "1"
					oModelRH:SetValue( "TFF_TESPED", aRecHumano[nX][_TFFTESPED ] )
				Endif						
				
				oModelRH:SetValue( "TFF_INSALU", aRecHumano[nX][_TFFINSALU ] )
				oModelRH:SetValue( "TFF_GRAUIN", aRecHumano[nX][_TFFGRAUIN ] )
				oModelRH:SetValue( "TFF_PERICU", aRecHumano[nX][_TFFPERICU ] )
				oModelRH:SetValue( "TFF_CONTRT", aRecHumano[nX][_TFFCONTRT ] )
				oModelRH:SetValue( "TFF_CONREV", aRecHumano[nX][_TFFCONREV ] )
				oModelRH:SetValue( "TFF_TIPORH", aRecHumano[nX][_TFFTIPORH ] )
				oModelRH:SetValue( "TFF_GRAVRH", aRecHumano[nX][_TFFGRAVRH ] )

				If Len(aMatImp) > 0
				
					oModelMI := oMdlPri:GetModel("TFG_GRID")

					nPosMat := aScan( aMatImp, { |x| x[1] == aRecHumano[nX][_TFFITEM ] .And. ;
														 x[2] == aRecHumano[nX][_TFFPRODUT ] } )
														 
					If nPosMat > 0
					
						For nY:=1 To Len(aMatImp[nPosMat][3])
						
							If nY > 1
								oModelMI:AddLine()
							EndIf
							
							oModelMI:GoLine(nY)
							oModelMI:SetValue( "TFG_ITEM", aMatImp[nPosMat][3][nY][ _TFGITEM ] )
							oModelMI:SetValue( "TFG_PRODUT", aMatImp[nPosMat][3][nY][ _TFGPRODUT ] )
							oModelMI:SetValue( "TFG_DESCRI", aMatImp[nPosMat][3][nY][ _TFGDESCRI ] )
							oModelMI:SetValue( "TFG_UM", aMatImp[nPosMat][3][nY][ _TFGUM ] )
							oModelMI:LoadValue( "TFG_QTDVEN", aMatImp[nPosMat][3][nY][ _TFGQTDVEN ] )
							oModelMI:SetValue( "TFG_PERINI", aMatImp[nPosMat][3][nY][ _TFGPERINI ] )

							oStruct := oModelMI:GetStruct()
							bWhen 	:= oStruct:GetProperty("TFG_PERFIM",MODEL_FIELD_WHEN)
							oStruct:SetProperty("TFG_PERFIM",MODEL_FIELD_WHEN,{|| .T. })
							oModelMI:SetValue( "TFG_PERFIM", aMatImp[nPosMat][3][nY][ _TFGPERFIM ] )
							oStruct:SetProperty("TFG_PERFIM",MODEL_FIELD_WHEN,bWhen)

							oModelMI:SetValue( "TFG_TES", aMatImp[nPosMat][3][nY][ _TFGTES ] )
							oModelMI:SetValue( "TFG_CODPAI", aMatImp[nPosMat][3][nY][ _TFGCODPAI ] )
							
							If aMatImp[nPosMat][3][nY][ _TFGTIPMAT ] <> "1"
								oModelMI:SetValue( "TFG_COBCTR", "2" )	
							Else
								oModelMI:SetValue( "TFG_COBCTR", "1" )	
							Endif
							
							oModelMI:SetValue( "TFG_CODPAI", aMatImp[nPosMat][3][nY][ _TFGCODPAI ] )
							oModelMI:SetValue( "TFG_TIPMAT", aMatImp[nPosMat][3][nY][ _TFGTIPMAT ] )
							oModelMI:SetValue( "TFG_GRVMAT", aMatImp[nPosMat][3][nY][ _TFGGRVMAT] ) //Campo já gravado 
												
							If IsInCallStack("At870GerOrc")

								oModelMI:SetValue( "TFG_PRCVEN", aMatImp[nPosMat][3][nY][ _TFGPRCVEN ] )
								oModelMI:SetValue( "TFG_TOTAL", aMatImp[nPosMat][3][nY][ _TFGTOTAL ] )
								oModelMI:SetValue( "TFG_VALDES", aMatImp[nPosMat][3][nY][ _TFGVALDES ] )
								oModelMI:SetValue( "TFG_DESCON", aMatImp[nPosMat][3][nY][ _TFGDESCON ] )
								oModelMI:SetValue( "TFG_TOTGER", aMatImp[nPosMat][3][nY][ _TFGTOTGER ] )
								oModelMI:SetValue( "TFG_TXLUCR", aMatImp[nPosMat][3][nY][ _TFGTXLUCR ] )
								oModelMI:SetValue( "TFG_LUCRO", aMatImp[nPosMat][3][nY][ _TFGLUCRO ] )
								oModelMI:SetValue( "TFG_ADM", aMatImp[nPosMat][3][nY][ _TFGADM ] )
								
							EndIf													
						
							If cGsDsGcn == "1"			
								oModelMI:SetValue( "TFG_TESPED", aMatImp[nPosMat][3][nY][ _TFGTESPED ] )
							Endif
																				
							
						Next nY					

					EndIf
				
				EndIf
				
				If Len(aMatCons) > 0
				
					oModelMC := oMdlPri:GetModel("TFH_GRID")
				
					nPosMat := aScan( aMatCons, { |x| x[1] == aRecHumano[nX][_TFFITEM ] .And. ;
														 x[2] == aRecHumano[nX][_TFFPRODUT ] } )
														 
					If nPosMat > 0
					
						For nY:=1 To Len(aMatCons[nPosMat][3])
						
							If nY > 1
								oModelMC:AddLine()
							EndIf
							
							oModelMC:GoLine(nY)
							oModelMC:SetValue( "TFH_ITEM", aMatCons[nPosMat][3][nY][ _TFGITEM ] )
							oModelMC:SetValue( "TFH_PRODUT", aMatCons[nPosMat][3][nY][ _TFGPRODUT ] )
							oModelMC:SetValue( "TFH_DESCRI", aMatCons[nPosMat][3][nY][ _TFGDESCRI ] )
							oModelMC:SetValue( "TFH_UM", aMatCons[nPosMat][3][nY][ _TFGUM ] )
							oModelMC:LoadValue( "TFH_QTDVEN", aMatCons[nPosMat][3][nY][ _TFGQTDVEN ] )
							oModelMC:SetValue( "TFH_PERINI", aMatCons[nPosMat][3][nY][ _TFGPERINI ] )

							oStruct := oModelMC:GetStruct()
							bWhen 	:= oStruct:GetProperty("TFH_PERFIM",MODEL_FIELD_WHEN)
							oStruct:SetProperty("TFH_PERFIM",MODEL_FIELD_WHEN,{|| .T. })
							oModelMC:SetValue( "TFH_PERFIM", aMatCons[nPosMat][3][nY][ _TFGPERFIM ] )
							oStruct:SetProperty("TFH_PERFIM",MODEL_FIELD_WHEN,bWhen)

							oModelMC:SetValue( "TFH_TES", aMatCons[nPosMat][3][nY][ _TFGTES ] )	
							oModelMC:SetValue( "TFH_CODPAI", aMatCons[nPosMat][3][nY][ _TFGCODPAI ] )
							If aMatCons[nPosMat][3][nY][ _TFGTIPMAT ] <> "1" 
								oModelMC:SetValue( "TFH_COBCTR", "2" )
							Else
								oModelMC:SetValue( "TFH_COBCTR", "1" )
							EndIf
							oModelMC:SetValue( "TFH_TIPMAT", aMatCons[nPosMat][3][nY][ _TFGTIPMAT ] )
							oModelMC:SetValue( "TFH_GRVMAT", aMatCons[nPosMat][3][nY][ _TFGGRVMAT] )
							
							If IsInCallStack("At870GerOrc")
								oModelMC:SetValue( "TFH_PRCVEN", aMatCons[nPosMat][3][nY][ _TFGPRCVEN ] )
								oModelMC:SetValue( "TFH_TOTAL", aMatCons[nPosMat][3][nY][ _TFGTOTAL ] )
								oModelMC:SetValue( "TFH_VALDES", aMatCons[nPosMat][3][nY][ _TFGVALDES ] )
								oModelMC:SetValue( "TFH_DESCON", aMatCons[nPosMat][3][nY][ _TFGDESCON ] )
								oModelMC:SetValue( "TFH_TOTGER", aMatCons[nPosMat][3][nY][ _TFGTOTGER ] )
								oModelMC:SetValue( "TFH_TXLUCR", aMatCons[nPosMat][3][nY][ _TFGTXLUCR ] )
								oModelMC:SetValue( "TFH_LUCRO", aMatCons[nPosMat][3][nY][ _TFGLUCRO ] )
								oModelMC:SetValue( "TFH_ADM", aMatCons[nPosMat][3][nY][ _TFGADM ] )
								oModelMC:SetValue( "TFH_TXADM", aMatCons[nPosMat][3][nY][ _TFGTXADM ] )
							EndIf
						
							If cGsDsGcn == "1"
								oModelMC:SetValue( "TFH_TESPED", aMatCons[nPosMat][3][nY][ _TFGTESPED ] )
							Endif						
						
						Next nY
					
					EndIf
									
				EndIf  
				
			Next nX

			
		EndIf
	
	Next nI	

EndIf

oModelRH:GoLine(1)

Return(Nil)


//----------------------------------------------------------
/*/{Protheus.doc} At740ACommit()
Atualiza os models com as informações de local e recursos humanos

@sample 	At740ACommit()

@author 	Serviços
@since 		14/04/2013
/*/
//----------------------------------------------------------
Static Function At740ACommit(oModel)

Local oModelRH := oModel:GetModel("TFF_GRID")
Local aRecHum  := {}
Local nLenRec  := 0
Local cGsDsGcn 	:= ""

Local nI

If oModel:GetOperation() == MODEL_OPERATION_INSERT 
	cGsDsGcn	:= SuperGetMv("MV_GSDSGCN",,"2")
Else
	cGsDsGcn	:= TFJ->TFJ_DSGCN
EndIf

For nI:=1 To oModelRH:Length()
	
	oModelRH:GoLine(nI)
			
	If !oModelRH:IsDeleted()
	
		//aAdd( aRecHum, Array(_TFFPERICU) )
		aAdd( aRecHum, Array(_TFFGRAVRH) )
		
		nLenRec := Len(aRecHum)

		aRecHum[nLenRec][_TFFITEM ] := oModelRH:GetValue("TFF_ITEM")
		aRecHum[nLenRec][_TFFPRODUT ] := oModelRH:GetValue("TFF_PRODUT")
		aRecHum[nLenRec][_TFFDESCRI ] := oModelRH:GetValue("TFF_DESCRI")
		aRecHum[nLenRec][_TFFUM ] := oModelRH:GetValue("TFF_UM")
		aRecHum[nLenRec][_TFFQTDVEN ] := oModelRH:GetValue("TFF_QTDVEN")
		aRecHum[nLenRec][_TFFPERINI ] := oModelRH:GetValue("TFF_PERINI")
		aRecHum[nLenRec][_TFFPERFIM ] := oModelRH:GetValue("TFF_PERFIM")
		aRecHum[nLenRec][_TFFHORAIN ] := oModelRH:GetValue("TFF_HORAIN")
		aRecHum[nLenRec][_TFFHORAFI ] := oModelRH:GetValue("TFF_HORAFI")
		aRecHum[nLenRec][_TFFFUNCAO ] := oModelRH:GetValue("TFF_FUNCAO")
		aRecHum[nLenRec][_TFFDFUNC ] := oModelRH:GetValue("TFF_DFUNC")
		aRecHum[nLenRec][_TFFTURNO ] := oModelRH:GetValue("TFF_TURNO")
		aRecHum[nLenRec][_TFFDTURNO ] := oModelRH:GetValue("TFF_DTURNO")
		aRecHum[nLenRec][_TFFCARGO ] := oModelRH:GetValue("TFF_CARGO")
		aRecHum[nLenRec][_TFFDCARGO ] := oModelRH:GetValue("TFF_DCARGO")
		aRecHum[nLenRec][_TFFCALCMD ] := oModelRH:GetValue("TFF_CALCMD")
		aRecHum[nLenRec][_TFFNARMA ] := oModelRH:GetValue("TFF_NARMA")
		aRecHum[nLenRec][_TFFNCOLE ] := oModelRH:GetValue("TFF_NCOLE")
		aRecHum[nLenRec][_TFFESCALA ] := oModelRH:GetValue("TFF_ESCALA")
		aRecHum[nLenRec][_TFFCALEND ] := oModelRH:GetValue("TFF_CALEND")
		aRecHum[nLenRec][_TFFSEQTRN ] := oModelRH:GetValue("TFF_SEQTRN")
		
		If IsInCallStack("At870GerOrc")
			aRecHum[nLenRec][_TFFPRCVEN ] := oModelRH:GetValue("TFF_PRCVEN")
			aRecHum[nLenRec][_TFFDESCON ] := oModelRH:GetValue("TFF_DESCON")
			aRecHum[nLenRec][_TFFVALDES ] := oModelRH:GetValue("TFF_VALDES")
			aRecHum[nLenRec][_TFFPRCVEN ] := oModelRH:GetValue("TFF_PRCVEN")
			aRecHum[nLenRec][_TFFLUCRO ] := oModelRH:GetValue("TFF_LUCRO")
			aRecHum[nLenRec][_TFFTXLUCR ] := oModelRH:GetValue("TFF_TXLUCR")
			aRecHum[nLenRec][_TFFADM ] := oModelRH:GetValue("TFF_ADM")
			aRecHum[nLenRec][_TFFTXADM ] := oModelRH:GetValue("TFF_TXADM")
			aRecHum[nLenRec][_TFFSUBTOT ] := oModelRH:GetValue("TFF_SUBTOT")
			aRecHum[nLenRec][_TFFTOTMI ] := oModelRH:GetValue("TFF_TOTMI")
			aRecHum[nLenRec][_TFFTOTMC ] := oModelRH:GetValue("TFF_TOTMC")
			aRecHum[nLenRec][_TFFTOTAL ] := oModelRH:GetValue("TFF_TOTAL")
		EndIf		
	   	
		If cGsDsGcn == "1"
			aRecHum[nLenRec][_TFFTESPED ] := oModelRH:GetValue("TFF_TESPED")
		Endif	   	

		aRecHum[nLenRec][_TFFINSALU ] := oModelRH:GetValue("TFF_INSALU")
		aRecHum[nLenRec][_TFFGRAUIN ] := oModelRH:GetValue("TFF_GRAUIN")
		aRecHum[nLenRec][_TFFPERICU ] := oModelRH:GetValue("TFF_PERICU")
		aRecHum[nLenRec][_TFFPDMTMI ] := oModelRH:GetValue("TFF_PDMTMI")
		aRecHum[nLenRec][_TFFPRMTMI ] := oModelRH:GetValue("TFF_PRMTMI")
		aRecHum[nLenRec][_TFFVLMTMI ] := oModelRH:GetValue("TFF_VLMTMI")
		aRecHum[nLenRec][_TFFPDMTMC ] := oModelRH:GetValue("TFF_PDMTMC")
		aRecHum[nLenRec][_TFFPRMTMC ] := oModelRH:GetValue("TFF_PRMTMC")
		aRecHum[nLenRec][_TFFVLMTMC ] := oModelRH:GetValue("TFF_VLMTMC")
		aRecHum[nLenRec][_TFFTIPORH ] := oModelRH:GetValue("TFF_TIPORH")
		aRecHum[nLenRec][_TFFGRAVRH ] := oModelRH:GetValue("TFF_GRAVRH")

	EndIf	

Next nI

aRecursos := aRecHum
	  
Return( .T. )


//------------------------------------------------------------------------------
/*/{Protheus.doc} At740ASelFlds
	Filtra os campos de controle da rotina para não serem exibidos na view
	
@sample 	At740ASelFlds()
 
@since		27/11/2013       

@param   	cTab, Caracter, Código da tabela a ter o campo avaliado
@param   	cCpoAval, Caracter, Código do campo a ser avaliado

@version	P12

@return 	lRet, Logico, define se o campo deve ser apresentado na view
/*/
//------------------------------------------------------------------------------
Function At740ASelFlds( cTab, cCpoAval )

Local lRet  := .T.

If ! IsInCallStack("At870GerOrc")
	If !Empty( cTab ) .And. !Empty( cCpoAval )
		
		If cTab == 'TFL'
		
			lRet := !( cCpoAval $ "TFL_TOTRH+TFL_TOTMI+TFL_TOTMC+TFL_TOTLE+TFL_TOTAL" )			
		
		ElseIf cTab == 'TFF'
		
			lRet := !( cCpoAval $ "TFF_PRCVEN+TFF_DESCON+TFF_VALDES+TFF_PRCVEN+TFF_LUCRO+TFF_TXLUCR" )
			lRet := lRet .And. !( cCpoAval $ "TFF_ADM+TFF_TXADM+TFF_COBCTR+TFF_SUBTOT+TFF_TOTMI+TFF_TOTMC+TFF_TOTAL+TFF_VLRMAT+TFF_PERMAT+TFF_VLBENE+TFF_TOTBEN" )		
					
		ElseIf cTab == 'TFG'	
						
			lRet := !( cCpoAval $ "TFG_PRCVEN+TFG_TOTAL+TFG_VALDES+TFG_DESCON+TFG_TOTGER+TFG_TXLUCR" )
			lRet := lRet .And. !( cCpoAval $ "TFG_LUCRO+TFG_ADM+TFG_TXADM+TFG_COBCTR+TFG_DPRMES+TFG_RESRET+TFG_VLATIV+TFG_VIDMES" )
		
		ElseIf cTab == 'TFH'	
							
			lRet := !( cCpoAval $ "TFH_PRCVEN+TFH_TOTAL+TFH_VALDES+TFH_DESCON+TFH_TOTGER+TFH_TXLUCR" )
			lRet := lRet .And. !( cCpoAval $ "TFH_LUCRO+TFH_ADM+TFH_TXADM+TFH_COBCTR+TFH_VIDMES+TFH_DPRMES"	)				

		Else
		
			lRet := .F.
			
		EndIf
	
	Else
		lRet := .F.
	EndIf
EndIf	
	
Return lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At740InPad
	
Função para inicializador padrão do total 

@sample 	AtIniPadMvc()

@since		02/10/2013       
@version	P11.90

@return 	nRet, retorna o resultado do cálculo

/*/
//------------------------------------------------------------------------------
Function At740AInPad()

Local aArea	:= GetArea()
Local oModel	:= FwModelActive()
Local oMdlRh	:= oModel:GetModel("TFF_GRID")
Local nTotRh 	:= oMdlRh:GetValue("TFF_SUBTOT")
Local nTotMI	:= oMdlRh:GetValue("TFF_TOTMI")
Local nTotMC	:= oMdlRh:GetValue("TFF_TOTMC")
Local nLucro	:= oMdlRh:GetValue("TFF_TXLUCR")
Local nTxAdm	:= oMdlRh:GetValue("TFF_TXADM")
Local nRet		:= 0

nRet := nTotRh+nTotMI+nTotMC+nLucro+nTxAdm
			
RestArea(aArea)

Return nRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At740AVerABB
	
Verifica se existe agendamento para o recurso do contrato

@sample 	At740AVerABB( cCodTFF )

@param 		cCodTFF - Codigo do recurso humano do contrato
		
@since		02/10/2013       
@version	P11.90

@return 	nRet, retorna o resultado do cálculo

/*/
//------------------------------------------------------------------------------
Function At740AVerABB( cCodTFF )

Local cRet 	  := .F.
Local cAliasABB := GetNextAlias()

BeginSql Alias cAliasABB

	SELECT 
		ABB.ABB_CODIGO 
	FROM 
		%Table:ABQ% ABQ
	JOIN %Table:ABB% ABB ON 
		ABB.ABB_FILIAL = %xFilial:ABB% AND 
		ABB.ABB_IDCFAL = ABQ.ABQ_CONTRT || ABQ.ABQ_ITEM || ABQ.ABQ_ORIGEM AND
		ABB.%NotDel%
	WHERE 
		ABQ.ABQ_FILIAL = %xFilial:ABQ% AND 
		ABQ.ABQ_CODTFF = %Exp:cCodTFF% AND 
		ABQ.%NotDel%

EndSql

If ((cAliasABB)->(Eof()) .And. (cAliasABB)->(Bof()))	
	lRet := .T. 
EndIf 

(cAliasABB)->(dbCloseArea())

Return(lRet)
//------------------------------------------------------------------------------
/*/{Protheus.doc} A740aPreVld
	
Função para validar a alteração de Cortesia/Item Extra já confirmados. 

@sample 	A740aPreVld( oModel,nLine,cAcao,cCampo,xValor )

@since		18/04/2018       
@version	P12

@return 	lRet, retorna permissão de alteração.

/*/
//------------------------------------------------------------------------------
Function A740aPreVld( oModel,nLine,cAcao,cCampo,xValor )

Local oModel		:= FwModelActive()
Local oModelRH		:= IIF((oModel <> NIL),oModel:GetModel("TFF_GRID"), NIL)
Local lRet := .T.

If oModelRH <> NIL 
	If cAcao == "CANSETVALUE" .AND. oModelRH:GetValue("TFF_GRAVRH") == "1"
		If cCampo == "TFF_PERINI" .OR. cCampo == "TFF_PERFIM"
			lRet := .T.
		Else
			Help(,,"A740aPreVld",,STR0003,1,0)
			lRet := .F.
		EndIf
	ElseIf cAcao == "DELETE" 
		If oModelRH:GetValue("TFF_GRAVRH") == "1" //Gravado
			Help(,,"A740aPreVld",,STR0004,1,0)
			lRet := .F.
		EndIf
	EndIf
EndIf

Return lRet
