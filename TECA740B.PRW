#Include "PROTHEUS.CH"
#Include "FWMVCDEF.CH" 
#Include "TECA740B.CH"

#DEFINE _TFGITEM	1
#DEFINE _TFGPRODUT	2
#DEFINE _TFGDESCRI	3
#DEFINE _TFGUM		4
#DEFINE _TFGQTDVEN	5
#DEFINE _TFGPERINI	6
#DEFINE _TFGPERFIM	7
#DEFINE _TFGTES		8
#DEFINE _TFGCODPAI	9
#DEFINE _TFGPRCVEN	10
#DEFINE _TFGTOTAL	11
#DEFINE _TFGVALDES	12
#DEFINE _TFGDESCON	13
#DEFINE _TFGTOTGER	14
#DEFINE _TFGTXLUCR	15
#DEFINE _TFGLUCRO	16
#DEFINE _TFGADM		17
#DEFINE _TFGTXADM	18
#DEFINE _TFGCOD		19
#DEFINE _TFGTESPED	20
#DEFINE _TFGTIPMAT	21
#DEFINE _TFGGRVMAT	22

STATIC aLocal 	:= {}
STATIC aRecursos	:= {}
STATIC aMateriais	:= {}

//----------------------------------------------------------
/*/{Protheus.doc} ModelDef()
Model - Cadastro de Cortesia Material de Implantação

@Return 	model
@author 	Serviços
@since 		11/04/2014
/*/
//----------------------------------------------------------
Static Function ModelDef()

Local oModel

Local oStrCabec := FWFormStruct(1,"TFL")
Local oStrTFF	  := FWFormStruct(1,"TFF")
Local oStrTFG	  := FWFormStruct(1,"TFG")
Local aAux		  := {}
Local bCommit   := { |oModel| At740BCommit(oModel) }
Local bLinePre	:= {|oModel,nLinha,cAction, cCampo| A740bLinPre(oModel,nLinha,cAction, cCampo)}
Local bLinePost	:= {|oModel,nLinha,cAction, cCampo| A740bLinPost(oModel,nLinha,cAction, cCampo)}
Local _lGSVinc 	:=  SuperGetMv("MV_GSVINC",,.F.) .AND. !SuperGetMv("MV_ORCPRC",,.F.)

oStrCabec:SetProperty( "TFL_CODPAI", MODEL_FIELD_OBRIGAT, .F. )

//-- Adiciona campos de contrato recorrente.
oStrCabec:AddField(	 STR0006,;									// 	[01]  C   Titulo do campo  //"Contr. Rec."
					 STR0006,;									// 	[02]  C   ToolTip do campo //"Contr. Rec."
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
					 
oStrTFG:AddField(	 STR0007,;									// 	[01]  C   Titulo do campo  //"Mat. Gravado"
					 STR0007,;									// 	[02]  C   ToolTip do campo //"Mat. Gravado"
					 "TFG_GRVMAT",;								// 	[03]  C   Id do Field
					 "C",;										// 	[04]  C   Tipo do campo
					 1,;										// 	[05]  N   Tamanho do campo
					 0,;										// 	[06]  N   Decimal do campo
					 NIL,;										// 	[07]  B   Code-block de validação do campo
					 NIL,;										// 	[08]  B   Code-block de validação When do campo
					 {STR0009,STR0010},;						//	[09]  A   Lista de valores permitido do campo //'1=Sim'#'2=Não'
					 .F.,;										//	[10]  L   Indica se o campo tem preenchimento obrigatório
					 {|| "2"},;									//	[11]  B   Code-block de inicializacao do campo
					 NIL,;										//	[12]  L   Indica se trata-se de um campo chave
					 .T.,;										//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
					 .T.)										// 	[14]  L   Indica se o campo é virtual
					 
oStrTFF:AddField(	 STR0008,;									// 	[01]  C   Titulo do campo  //"RH Gravado"
					 STR0008,;									// 	[02]  C   ToolTip do campo //"RH Gravado"
					 "TFF_GRAVRH",;								// 	[03]  C   Id do Field
					 "C",;										// 	[04]  C   Tipo do campo
					 1,;										// 	[05]  N   Tamanho do campo
					 0,;										// 	[06]  N   Decimal do campo
					 NIL,;										// 	[07]  B   Code-block de validação do campo
					 NIL,;										// 	[08]  B   Code-block de validação When do campo
					 {STR0009,STR0010},;						//	[09]  A   Lista de valores permitido do campo //'1=Sim'#'2=Não'
					 .F.,;										//	[10]  L   Indica se o campo tem preenchimento obrigatório
					 {|| "2"},;								//	[11]  B   Code-block de inicializacao do campo
					 NIL,;										//	[12]  L   Indica se trata-se de um campo chave
					 .T.,;										//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
					 .T.)										// 	[14]  L   Indica se o campo é virtual					 					 

oStrTFF:SetProperty( "TFF_PRCVEN", MODEL_FIELD_OBRIGAT, .F. )
oStrTFF:SetProperty( "TFF_LOCAL",	MODEL_FIELD_OBRIGAT, .F. )
oStrTFF:SetProperty( "TFF_CODPAI", MODEL_FIELD_OBRIGAT, .F. )

oStrTFF:SetProperty( "TFF_PRCVEN", MODEL_FIELD_VALID, { || .T. } )

oStrTFG:SetProperty( "TFG_LOCAL", MODEL_FIELD_OBRIGAT, .F. )
oStrTFG:SetProperty( "TFG_CODPAI", MODEL_FIELD_OBRIGAT, .F. )
oStrTFG:SetProperty( "TFG_PRCVEN", MODEL_FIELD_OBRIGAT, .F. )

oStrTFG:SetProperty("TFG_PERINI",MODEL_FIELD_VALID,{|oMdlVld|At740VldDt("TFG_GRID","TFG_PERINI","TFG_PERINI","TFG_PERFIM", Nil, .T. )})
oStrTFG:SetProperty("TFG_PERFIM",MODEL_FIELD_VALID,{|oMdlVld|At740VldDt("TFG_GRID","TFG_PERFIM","TFG_PERINI","TFG_PERFIM", Nil, .T. )})

If IsInCallStack("At870GerOrc")
	//oStrTFG:SetProperty( "TFG_PRCVEN", MODEL_FIELD_OBRIGAT, .T. )
	oStrTFG:SetProperty("TFG_PRCVEN",MODEL_FIELD_VALID,{|oModel|At740VlVlr("TFG_GRID","TFG_PRCVEN",oModel)})
EndIf

// Cria o objeto do Modelo de Dados
oModel := MPFormModel():New("TECA740B", /*bPreValidacao*/, /*bPosValidacao*/, bCommit, /*bCancel*/ )

oModel:AddFields("TFL_CAB",/*cOwner*/,oStrCabec, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

oModel:AddGrid( "TFF_GRID", "TFL_CAB", oStrTFF,/*bLinePre*/,/*bLinePost*/, /*bPreVal*/, /*bPosVal*/)
oModel:SetRelation( "TFF_GRID", { { "TFF_FILIAL", "xFilial('TFF')" }, { "TFF_CODPAI", "TFL_CODIGO" } }, TFF->(IndexKey(3)) )

oModel:AddGrid( "TFG_GRID", "TFF_GRID", oStrTFG,bLinePre, bLinePost, /*bPreVal*/, /*bPosVal*/)
oModel:SetRelation("TFG_GRID", { { "TFG_FILIAL", "xFilial('TFG')" }, { "TFG_CODPAI", "TFF_COD" }, { "TFG_LOCAL", "TFL_LOCAL" } }, TFG->(IndexKey(1)) )

If _lGSVinc
	oStrTFG:SetProperty( "TFG_PERINI", MODEL_FIELD_INIT,{|oMdl| oMdl:GetModel():GetModel("TFF_GRID"):GetValue("TFF_PERINI") } )
	oStrTFG:SetProperty( "TFG_PERFIM", MODEL_FIELD_INIT,{|oMdl| oMdl:GetModel():GetModel("TFF_GRID"):GetValue("TFF_PERFIM") } )

	oStrTFG:SetProperty("TFG_PRODUT", MODEL_FIELD_VALID, {|oModel| At740Prod(oModel, oModel:GetValue("TFG_PRODUT"),"4") } )

EndIf

oModel:SetPrimaryKey( {} )
oModel:SetDescription(STR0001) // "Cortesia de Material de Implantanção"

oModel:GetModel("TFG_GRID"):SetOptional(.T.)

oModel:SetActivate( {|oModel| InitDados( oModel ) } )

Return(oModel) 


//----------------------------------------------------------
/*/{Protheus.doc} ViewDef()
View - Cortesia Material de Implantação

@Return 	view
@author 	Serviços
@since 		11/04/2014
/*/
//----------------------------------------------------------
Static Function ViewDef()

Local oView
Local oModel := FWLoadModel("TECA740B")
Local cOperation := A740GetOper()

Local oStrCabec := FWFormStruct( 2, "TFL", {|cCpo| At740SelFields( "TFL", Alltrim(cCpo) ) .And. ;
														  At740ASelFlds( "TFL", Alltrim(cCpo) ) } )
Local oStrTFF   := FWFormStruct( 2, "TFF", {|cCpo| At740SelFields( "TFF", Alltrim(cCpo) )  .And. ;
														  At740ASelFlds( "TFF", Alltrim(cCpo) ) } )												    
Local oStrTFG   := FWFormStruct( 2, "TFG", {|cCpo| At740SelFields( "TFG", Alltrim(cCpo) ) .And. ;
														  At740ASelFlds( "TFG", Alltrim(cCpo) ) } )	
														  												    
If cOperation <> 1 //Alteração do orçamento - Revisão - Item extra													    
	oStrCabec:SetProperty("*",MVC_VIEW_CANCHANGE, .F.)
	oStrTFF:SetProperty("*",MVC_VIEW_CANCHANGE, .F.)
	oStrTFG:SetProperty("TFG_TIPMAT", MVC_VIEW_CANCHANGE, .F.)
Else
	oStrCabec:SetProperty("*",MVC_VIEW_CANCHANGE, .F.)
	oStrTFF:SetProperty("*",MVC_VIEW_CANCHANGE, .F.)
	oStrTFG:SetProperty("*", MVC_VIEW_CANCHANGE, .F.)
EndIf

oView := FWFormView():New()
oView:SetModel( oModel )

oView:SetDescription(STR0001) // "Cortesia de Material de Implantanção"
oView:SetCloseOnOk({|| .T. } )

oView:AddField( "VIEW_CAB" , oStrCabec , "TFL_CAB"  )
oView:AddGrid( "VIEW_TFF"  , oStrTFF   , "TFF_GRID" )
oView:AddGrid( "VIEW_TFG"  , oStrTFG   , "TFG_GRID" )

//--------------------------------------
//		Cria os Box's
//--------------------------------------
oView:CreateHorizontalBox( "TOP"   , 15 )
oView:CreateHorizontalBox( "MIDDLE", 45 )
oView:CreateHorizontalBox( "DOWN"  , 40 )  

//--------------------------------------
//		Associa os componentes ao Box
//--------------------------------------
oView:SetOwnerView( "VIEW_CAB" , "TOP"   )
oView:SetOwnerView( "VIEW_TFF", "MIDDLE" )
oView:SetOwnerView( "VIEW_TFG", "DOWN"	   )

oView:EnableTitleView( "VIEW_TFF", STR0002 )  // "Recursos Humanos"
oView:EnableTitleView( "VIEW_TFG", STR0003 )  // "Material de Implantação"

// Incrementa automaticamente o campo ao incluir uma nova linha
oView:AddIncrementField( "TFG_GRID", "TFG_ITEM" )

Return(oView)


//----------------------------------------------------------
/*/{Protheus.doc} At740BSetLoc()
Alimenta as informações do array de locais para o carregamento do grid

@sample 	At740BSetLoc()

@param  	oMdlLocal, Objeto, objeto geral do model que será utilizado
			para popular o array
@param  	cLocal, String, local utilizado para a pesquisa

@author 	Serviços
@since 		14/04/2013
/*/
//----------------------------------------------------------
Function At740BSetLoc( oMdlLocal, cLocal )

aLocal := At740ASetLoc( oMdlLocal, .F., cLocal )

Return(Nil)


//----------------------------------------------------------
/*/{Protheus.doc} At740BSetRec()
Alimenta as informações do array de locais para o carregamento do grid

@sample 	At740BSetLoc()

@param  	oMdlLocal, Objeto, objeto geral do model que será utilizado
			para popular o array
@param  	cLocal, String, local utilizado para a pesquisa

@author 	Serviços
@since 		14/04/2013
/*/
//----------------------------------------------------------
Function At740BSetRec( oModel, cLocal )

aRecursos := At740ASetRec( oModel, .F., cLocal )

Return(Nil)


//----------------------------------------------------------
/*/{Protheus.doc} InitDados()
Inicializa as informações da Cortesia Material de Implantação

@sample 	InitDados()

@param  	oModel, Objeto, objeto geral do model que será alterado

@author 	Serviços
@since 		14/04/2013
/*/
//----------------------------------------------------------
Static Function InitDados(oModel)

Local aSaveRows := {}
Local oModelRH  := oModel:GetModel("TFF_GRID")
Local oModelMI	:= oModel:GetModel("TFG_GRID")
Local cGsDsGcn 	:= ""
Local cOperation := A740GetOper()

If oModel:GetOperation() == MODEL_OPERATION_INSERT 
	cGsDsGcn	:= SuperGetMv("MV_GSDSGCN",,"2")
Else
	cGsDsGcn	:= TFJ->TFJ_DSGCN
EndIf

At740ASetModel( oModel, aLocal, aRecursos, aMateriais )

If cGsDsGcn == "1"
	oModel:GetModel('TFG_GRID'):GetStruct():SetProperty('TFG_TESPED',MODEL_FIELD_OBRIGAT,.T.)	
Endif

If cOperation <> 1	//Quando não for visualização do orçamento.
	oModelRH:SetNoInsertLine(.T.)
	oModelRH:SetNoDeleteLine(.T.)
Else //Visualização do orçamento
	oModelRH:SetNoInsertLine(.T.)
	oModelRH:SetNoDeleteLine(.T.)
	oModelMI:SetNoInsertLine(.T.)
	oModelMI:SetNoDeleteLine(.T.)
EndIf

FwRestRows( aSaveRows )

Return(Nil)


//----------------------------------------------------------
/*/{Protheus.doc} At740BSetMat()
Alimenta as informações do array de locais para o carregamento do grid

@sample 	At740BSetMat()

@param  	oModel, Objeto, objeto geral do model que será utilizado
			para popular o array
@param 		lRot704A, Boolean, verifica se esta sendo executado pela 
			cortesia de RH.			
@param		lExtOrc, Boolean, indica se é para Item extra
@param  	cLocal, String, local utilizado para a pesquisa

@author 	Serviços
@since 		14/04/2013
/*/
//----------------------------------------------------------
Function At740BSetMat( oModel, lRot704B, cLocal )

Local oModelLC := oModel:GetModel("TFL_LOC")
Local oModelRH := oModel:GetModel("TFF_RH")

Local oModelMI
Local oModelMC

Local aMat704B := {}

Local nI, nX

Local cGsDsGcn 	:= ""

If oModel:GetOperation() == MODEL_OPERATION_INSERT 
	cGsDsGcn	:= SuperGetMv("MV_GSDSGCN",,"2")
Else
	cGsDsGcn	:= TFJ->TFJ_DSGCN
EndIf

If oModelLC:SeekLine({{ "TFL_LOCAL", cLocal }})

	For nI:=1 To oModelRH:Length()
		
		oModelRH:GoLine(nI)
		
		aAdd( aMat704B, { oModelRH:GetValue("TFF_ITEM"), oModelRH:GetValue("TFF_PRODUT"), {} } )
		
		If lRot704B
		
			oModelMI := oModel:GetModel("TFG_MI")
		
			For nX:=1 To oModelMI:Length() 
			
				oModelMI:GoLine(nX)		
			//aquileandro
				If oModelMI:GetValue("TFG_TIPMAT") == "3" .OR. Empty(oModelMI:GetValue("TFG_PRODUT"))		
					Loop
				EndIf			
						
				aAdd( aMat704B[nI][3], Array(_TFGGRVMAT) )

				aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGITEM ] := oModelMI:GetValue("TFG_ITEM")
				aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGPRODUT ] := oModelMI:GetValue("TFG_PRODUT")
				aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGDESCRI ] := oModelMI:GetValue("TFG_DESCRI")
				aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGUM ] := oModelMI:GetValue("TFG_UM")
				aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGQTDVEN ] := oModelMI:GetValue("TFG_QTDVEN")
				aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGPERINI ] := oModelMI:GetValue("TFG_PERINI")
				aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGPERFIM ] := oModelMI:GetValue("TFG_PERFIM")
				aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGTES ] := oModelMI:GetValue("TFG_TES")
				aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGCODPAI ] := oModelMI:GetValue("TFG_CODPAI")
				aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGTIPMAT ] := oModelMI:GetValue("TFG_TIPMAT")
				aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGGRVMAT ] := oModelMI:GetValue("TFG_GRVMAT")
				
				If IsInCallStack("At870GerOrc")
				
					aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGPRCVEN ] := oModelMI:GetValue("TFG_PRCVEN")
					aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGTOTAL ] := oModelMI:GetValue("TFG_TOTAL")
					aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGVALDES ] := oModelMI:GetValue("TFG_VALDES")
					aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGDESCON ] := oModelMI:GetValue("TFG_DESCON")
					aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGTOTGER ] := oModelMI:GetValue("TFG_TOTGER")
					aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGTXLUCR ] := oModelMI:GetValue("TFG_TXLUCR")
					aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGLUCRO ] := oModelMI:GetValue("TFG_LUCRO")
					aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGADM ] := oModelMI:GetValue("TFG_ADM")
					aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGTXADM ] := oModelMI:GetValue("TFG_TXADM")

				EndIf					
				If cGsDsGcn == "1"
					aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGTESPED ] := oModelMI:GetValue("TFG_TESPED")	
				Endif
			Next nX
			
		Else
		
			oModelMC := oModel:GetModel("TFH_MC")
			
			For nX:=1 To oModelMC:Length()
			
				oModelMC:GoLine(nX) 
				
				If oModelMC:GetValue("TFH_TIPMAT") == "3" .OR. Empty(oModelMC:GetValue("TFH_PRODUT"))				
					Loop
				EndIf

				aAdd( aMat704B[nI][3], Array(_TFGGRVMAT) )

				aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGITEM ] := oModelMC:GetValue("TFH_ITEM")
				aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGPRODUT ] := oModelMC:GetValue("TFH_PRODUT")
				aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGDESCRI ] := oModelMC:GetValue("TFH_DESCRI")
				aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGUM ] := oModelMC:GetValue("TFH_UM")
				aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGQTDVEN ] := oModelMC:GetValue("TFH_QTDVEN")
				aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGPERINI ] := oModelMC:GetValue("TFH_PERINI")
				aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGPERFIM ] := oModelMC:GetValue("TFH_PERFIM")
				aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGTES ] := oModelMC:GetValue("TFH_TES")	
				aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGCODPAI ] := oModelMC:GetValue("TFH_CODPAI")
				aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGTIPMAT ] := oModelMC:GetValue("TFH_TIPMAT")
				aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGGRVMAT ] := oModelMC:GetValue("TFH_GRVMAT")
				
				If IsInCallStack("At870GerOrc")
				
					aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGPRCVEN ] := oModelMC:GetValue("TFH_PRCVEN")		
					aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGTOTAL ] := oModelMC:GetValue("TFH_TOTAL")
					aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGVALDES ] := oModelMC:GetValue("TFH_VALDES")
					aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGDESCON ] := oModelMC:GetValue("TFH_DESCON")
					aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGTOTGER ] := oModelMC:GetValue("TFH_TOTGER")
					aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGTXLUCR ] := oModelMC:GetValue("TFH_TXLUCR")
					aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGLUCRO ] := oModelMC:GetValue("TFH_LUCRO")
					aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGADM ] := oModelMC:GetValue("TFH_ADM")
					aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGTXADM ] := oModelMC:GetValue("TFH_TXADM")					
									
				EndIf				
				If cGsDsGcn == "1"
					aMat704B[nI][3][Len(aMat704B[nI][3])][ _TFGTESPED ] := oModelMC:GetValue("TFH_TESPED")
				Endif				
			Next nX		
		
		EndIf
	
	Next nI

EndIf

If lRot704B
	aMateriais := aMat704B
EndIf  

Return(aMat704B)


//----------------------------------------------------------
/*/{Protheus.doc} At740BGet()
Retorna as informações do array de locais para o carregamento do grid

@sample 	At740BGet()


@author 	Serviços
@since 		15/04/2013
/*/
//----------------------------------------------------------
Function At740BGet()
Return(aMateriais)


//----------------------------------------------------------
/*/{Protheus.doc} At740BCommit()
Atualiza os models com as informações de local e material de implantação

@sample 	At740BCommit()

@author 	Serviços
@since 		15/04/2013
/*/
//----------------------------------------------------------
Static Function At740BCommit(oModel)

Local oModelRH := oModel:GetModel("TFF_GRID")
Local oModelMI := oModel:GetModel("TFG_GRID")
Local aMatImp  := {}
Local nLenMat  := 0
Local cGsDsGcn 	:= ""

Local nI, nX

If oModel:GetOperation() == MODEL_OPERATION_INSERT 
	cGsDsGcn	:= SuperGetMv("MV_GSDSGCN",,"2")
Else
	cGsDsGcn	:= TFJ->TFJ_DSGCN
EndIf

For nI:=1 To oModelRH:Length()
	
	oModelRH:GoLine(nI)
	
	aAdd( aMatImp, { oModelRH:GetValue("TFF_ITEM"), oModelRH:GetValue("TFF_PRODUT"), {} } )	
			
	For nX:=1 To oModelMI:Length()
	
		oModelMI:GoLine(nX) 
	
		If !oModelMI:IsDeleted()	

			aAdd( aMatImp[nI][3], Array(_TFGGRVMAT) )			
			
			nLenMat := Len(aMatImp[nI][3])
						
			aMatImp[nI][3][nLenMat][ _TFGITEM ] := oModelMI:GetValue("TFG_ITEM")
			aMatImp[nI][3][nLenMat][ _TFGPRODUT ] := oModelMI:GetValue("TFG_PRODUT")
			aMatImp[nI][3][nLenMat][ _TFGDESCRI ] := oModelMI:GetValue("TFG_DESCRI")
			aMatImp[nI][3][nLenMat][ _TFGUM ] 	  := oModelMI:GetValue("TFG_UM")
			aMatImp[nI][3][nLenMat][ _TFGQTDVEN ] := oModelMI:GetValue("TFG_QTDVEN")
			aMatImp[nI][3][nLenMat][ _TFGPERINI ] := oModelMI:GetValue("TFG_PERINI")
			aMatImp[nI][3][nLenMat][ _TFGPERFIM ] := oModelMI:GetValue("TFG_PERFIM")
			aMatImp[nI][3][nLenMat][ _TFGTES ] := oModelMI:GetValue("TFG_TES")
			aMatImp[nI][3][nLenMat][ _TFGCODPAI ] := oModelMI:GetValue("TFG_CODPAI")
			aMatImp[nI][3][nLenMat][ _TFGTIPMAT ] := oModelMI:GetValue("TFG_TIPMAT")
			aMatImp[nI][3][nLenMat][ _TFGGRVMAT ] := oModelMI:GetValue("TFG_GRVMAT")
			
			If IsInCallStack("At870GerOrc")
			
				aMatImp[nI][3][nLenMat][ _TFGPRCVEN ] := oModelMI:GetValue("TFG_PRCVEN")
				aMatImp[nI][3][nLenMat][ _TFGTOTAL ] := oModelMI:GetValue("TFG_TOTAL")
				aMatImp[nI][3][nLenMat][ _TFGVALDES ] := oModelMI:GetValue("TFG_VALDES")
				aMatImp[nI][3][nLenMat][ _TFGDESCON ] := oModelMI:GetValue("TFG_DESCON")
				aMatImp[nI][3][nLenMat][ _TFGTOTGER ] := oModelMI:GetValue("TFG_TOTGER")
				aMatImp[nI][3][nLenMat][ _TFGTXLUCR ] := oModelMI:GetValue("TFG_TXLUCR")
				aMatImp[nI][3][nLenMat][ _TFGLUCRO ] := oModelMI:GetValue("TFG_LUCRO")
				aMatImp[nI][3][nLenMat][ _TFGADM ] := oModelMI:GetValue("TFG_ADM")
				aMatImp[nI][3][nLenMat][ _TFGTXADM ] := oModelMI:GetValue("TFG_TXADM")
				aMatImp[nI][3][nLenMat][ _TFGCOD ] := oModelMI:GetValue("TFG_COD")
			
			EndIf

			If cGsDsGcn == "1"
				aMatImp[nI][3][nLenMat][ _TFGTESPED ] := oModelMI:GetValue("TFG_TESPED")
			Endif
					
		EndIf					
		
	Next nX
	
	
Next nI

aMateriais := aMatImp

Return(.T.)  

//------------------------------------------------------------------------------
/*/{Protheus.doc} A740bLinPre
	
Função para validar a alteração de Cortesia/Item Extra já confirmados. 

@sample 	A740bLinPre(oModel,nLinha,cAction, cCampo)

@since		18/04/2018       
@version	P12

@return 	lRet, retorna permissão de alteração.

/*/
//------------------------------------------------------------------------------
Function A740bLinPre(oModel,nLinha,cAction, cCampo)

Local oModel		:= FwModelActive()
Local oModelMI		:= IIF((oModel <> NIL),oModel:GetModel("TFG_GRID"), NIL)
Local lRet 			:= .T.
Local cOperation 	:= A740GetOper()

If oModelMI <> NIL 
	If cAction == "CANSETVALUE" .AND. oModelMI:GetValue("TFG_GRVMAT") == "1" //Gravado
		If cCampo == "TFG_PERINI" .OR. cCampo == "TFG_PERFIM"
			lRet := .T.
		Else
			lRet := .F.
		EndIf
	ElseIf cAction == "DELETE"
		If oModelMI:GetValue("TFG_GRVMAT") == "1" //Gravado 
			Help(,,"A740bLinPre",,STR0004,1,0)
			lRet := .F.
		EndIf
	EndIf
EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} A740bLinPost
	
Função para validar preenchimento do preço dos produtos.

@sample 	A740bLinPost(oModel,nLinha,cAction, cCampo)

@since		07/05/2018       
@version	P12

@return 	lRet, retorna permissão de alteração.

/*/
//------------------------------------------------------------------------------
Function A740bLinPost(oModel,nLinha,cAction, cCampo)

Local oModel		:= FwModelActive()
Local oModelMI		:= IIF((oModel <> NIL),oModel:GetModel("TFG_GRID"), NIL)
Local lRet := .T.

If IsInCallStack("At870GerOrc") .AND. IsInCallStack("At740Cortesia") .AND. oModelMI:GetValue("TFG_TIPMAT") <> "1"
	If oModelMI <> NIL .AND. oModelMI:IsUpdated()
		If Empty(oModelMI:GetValue("TFG_PRCVEN")) 
			Help(,,"A740bLinPost",,STR0005 + Str(nLinha),1,0)
			lRet := .F.
		EndIf
	EndIf
EndIf

Return lRet

