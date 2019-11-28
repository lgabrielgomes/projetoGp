#Include "PROTHEUS.CH"
#Include "FWMVCDEF.CH" 
#Include "TECA740C.CH"

#DEFINE _TFHITEM	1
#DEFINE _TFHPRODUT	2
#DEFINE _TFHDESCRI	3
#DEFINE _TFHUM		4
#DEFINE _TFHQTDVEN	5
#DEFINE _TFHPERINI	6
#DEFINE _TFHPERFIM	7
#DEFINE _TFHTES		8
#DEFINE _TFHCODPAI	9
#DEFINE _TFHPRCVEN	10
#DEFINE _TFHTOTAL	11
#DEFINE _TFHVALDES	12
#DEFINE _TFHDESCON	13
#DEFINE _TFHTOTGER	14
#DEFINE _TFHTXLUCR	15
#DEFINE _TFHLUCRO	16
#DEFINE _TFHADM		17
#DEFINE _TFHTXADM	18
#DEFINE _TFHCOD		19
#DEFINE _TFHTESPED	20
#DEFINE _TFHTIPMAT	21
#DEFINE _TFHGRVMAT	22

STATIC aLocal 	:= {}
STATIC aRecursos	:= {}
STATIC aMateriais	:= {}

//----------------------------------------------------------
/*/{Protheus.doc} ModelDef()
Model - Cortesia Material de Consumo

@Return 	model
@author 	Serviços
@since 		11/04/2014
/*/
//----------------------------------------------------------
Static Function ModelDef()

Local oModel

Local oStrCabec := FWFormStruct(1,"TFL")
Local oStrTFF	  := FWFormStruct(1,"TFF")
Local oStrTFH	  := FWFormStruct(1,"TFH")
Local aAux		  := {}
Local bCommit   := { |oModel| At740CCommit(oModel) }
Local bLinePre	:= {|oModel,nLinha,cAction, cCampo| A740cLinPre(oModel,nLinha,cAction, cCampo)}
Local bLinePost	:= {|oModel,nLinha,cAction, cCampo| A740cLinPost(oModel,nLinha,cAction, cCampo)}
Local _lGSVinc 	:=  SuperGetMv("MV_GSVINC",,.F.) .AND. !SuperGetMv("MV_ORCPRC",,.F.)

oStrCabec:SetProperty( "TFL_CODPAI", MODEL_FIELD_OBRIGAT, .F. )

//-- Adiciona campos de contrato recorrente.
oStrCabec:AddField(	 STR0006,;								// 	[01]  C   Titulo do campo  //"Contr. Rec." 
					 STR0006,;								// 	[02]  C   ToolTip do campo //"Contr. Rec."
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
					 
oStrTFH:AddField(	 STR0007,;									// 	[01]  C   Titulo do campo //"Mat. Gravado"
					 STR0007,;									// 	[02]  C   ToolTip do campo //"Mat. Gravado"
					 "TFH_GRVMAT",;								// 	[03]  C   Id do Field
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
					 
oStrTFF:AddField(	 STR0008,;									// 	[01]  C   Titulo do campo //"RH Gravado"
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

oStrTFH:SetProperty( "TFH_LOCAL", MODEL_FIELD_OBRIGAT, .F. )
oStrTFH:SetProperty( "TFH_CODPAI", MODEL_FIELD_OBRIGAT, .F. )
oStrTFH:SetProperty( "TFH_PRCVEN", MODEL_FIELD_OBRIGAT, .F. )

oStrTFH:SetProperty("TFH_PERINI",MODEL_FIELD_VALID,{|oMdlVld|At740VldDt("TFH_GRID","TFH_PERINI","TFH_PERINI","TFH_PERFIM",Nil, .T.)})
oStrTFH:SetProperty("TFH_PERFIM",MODEL_FIELD_VALID,{|oMdlVld|At740VldDt("TFH_GRID","TFH_PERFIM","TFH_PERINI","TFH_PERFIM",NiL, .T.)})

If IsInCallStack("At870GerOrc")
	oStrTFH:SetProperty("TFH_PRCVEN",MODEL_FIELD_VALID,{|oModel|At740VlVlr("TFH_GRID","TFH_PRCVEN",oModel)})
EndIf

// Cria o objeto do Modelo de Dados
oModel := MPFormModel():New("TECA740B", /*bPreValidacao*/, /*bPosValidacao*/, bCommit, /*bCancel*/ )

oModel:AddFields("TFL_CAB",/*cOwner*/,oStrCabec, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

oModel:AddGrid( "TFF_GRID", "TFL_CAB", oStrTFF,/*bLinePre*/,/*bLinePost*/, /*bPreVal*/, /*bPosVal*/)
oModel:SetRelation( "TFF_GRID", { { "TFF_FILIAL", "xFilial('TFF')" }, { "TFF_CODPAI", "TFL_CODIGO" } }, TFF->(IndexKey(3)) )

oModel:AddGrid( "TFH_GRID", "TFF_GRID", oStrTFH, bLinePre , bLinePost, /*bPreVal*/, /*bPosVal*/)
oModel:SetRelation("TFH_GRID", { { "TFH_FILIAL", "xFilial('TFH')" }, { "TFH_CODPAI", "TFF_COD" }, { "TFH_LOCAL", "TFL_LOCAL" } }, TFH->(IndexKey(1)) )

If _lGSVinc
	oStrTFH:SetProperty( "TFH_PERINI", MODEL_FIELD_INIT,{|oMdl| oMdl:GetModel():GetModel("TFF_GRID"):GetValue("TFF_PERINI") } )
	oStrTFH:SetProperty( "TFH_PERFIM", MODEL_FIELD_INIT,{|oMdl| oMdl:GetModel():GetModel("TFF_GRID"):GetValue("TFF_PERFIM") } )
	
	oStrTFH:SetProperty("TFH_PRODUT", MODEL_FIELD_VALID, {|oModel| At740Prod(oModel, oModel:GetValue("TFH_PRODUT"),"5") } )	
EndIf

oModel:SetPrimaryKey( {} )
oModel:SetDescription(STR0001) // "Cortesia de Material de Consumo"

oModel:GetModel("TFH_GRID"):SetOptional(.T.)

oModel:SetActivate( {|oModel| InitDados( oModel ) } )

Return(oModel) 


//----------------------------------------------------------
/*/{Protheus.doc} ViewDef()
View - Cortesia Material de Consumo

@Return 	view
@author 	Serviços
@since 		11/04/2014
/*/
//----------------------------------------------------------
Static Function ViewDef()

Local oView
Local oModel := FWLoadModel("TECA740C")
Local cOperation := A740GetOper()

Local oStrCabec := FWFormStruct( 2, "TFL", {|cCpo| At740SelFields( "TFL", Alltrim(cCpo) ) .And. ;
														  At740ASelFlds( "TFL", Alltrim(cCpo) ) } )
Local oStrTFF   := FWFormStruct( 2, "TFF", {|cCpo| At740SelFields( "TFF", Alltrim(cCpo) )   .And. ;
														  At740ASelFlds( "TFF", Alltrim(cCpo) ) } )												    
Local oStrTFH   := FWFormStruct( 2, "TFH", {|cCpo| At740SelFields( "TFH", Alltrim(cCpo) ) .And. ;
														  At740ASelFlds( "TFH", Alltrim(cCpo) ) } )
If cOperation <> 1 //Alteração do orçamento - Revisão - Item extra														    
	oStrCabec:SetProperty("*",MVC_VIEW_CANCHANGE, .F.)
	oStrTFF:SetProperty("*",MVC_VIEW_CANCHANGE, .F.)
	oStrTFH:SetProperty("TFH_TIPMAT", MVC_VIEW_CANCHANGE, .F.)
Else
	oStrCabec:SetProperty("*",MVC_VIEW_CANCHANGE, .F.)
	oStrTFF:SetProperty("*",MVC_VIEW_CANCHANGE, .F.)
	oStrTFH:SetProperty("*", MVC_VIEW_CANCHANGE, .F.)
EndIf

oView := FWFormView():New()
oView:SetModel( oModel )

oView:SetDescription(STR0001) // "Cortesia de Material de Consumo"
oView:SetCloseOnOk({|| .T. } )

oView:AddField( "VIEW_CAB" , oStrCabec , "TFL_CAB"  )
oView:AddGrid( "VIEW_TFF"  , oStrTFF   , "TFF_GRID" )
oView:AddGrid( "VIEW_TFH"  , oStrTFH   , "TFH_GRID" )

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
oView:SetOwnerView( "VIEW_TFH", "DOWN"	   )

oView:EnableTitleView( "VIEW_TFF", STR0002 )  // "Recursos Humanos"
oView:EnableTitleView( "VIEW_TFH", STR0003 )  // "Materiais de Consumo"

// Incrementa automaticamente o campo ao incluir uma nova linha
oView:AddIncrementField( "TFH_GRID", "TFH_ITEM" )

Return(oView)


//----------------------------------------------------------
/*/{Protheus.doc} At740CSetLoc()
Alimenta as informações do array de locais para o carregamento do grid

@sample 	At740CSetLoc()

@param  	oMdlLocal, Objeto, objeto geral do model que será utilizado
			para popular o array
@param  	cLocal, String, local utilizado para a pesquisa

@author 	Serviços
@since 		14/04/2013
/*/
//----------------------------------------------------------
Function At740CSetLoc( oMdlLocal, cLocal )

aLocal := At740ASetLoc( oMdlLocal, .F., cLocal )

Return(Nil)


//----------------------------------------------------------
/*/{Protheus.doc} At740CSetRec()
Alimenta as informações do array de locais para o carregamento do grid

@sample 	At740BSetLoc()

@param  	oMdlLocal, Objeto, objeto geral do model que será utilizado
			para popular o array
@param  	cLocal, String, local utilizado para a pesquisa

@author 	Serviços
@since 		14/04/2013
/*/
//----------------------------------------------------------
Function At740CSetRec( oModel, cLocal )

aRecursos := At740ASetRec( oModel, .F., cLocal )

Return(Nil)


//----------------------------------------------------------
/*/{Protheus.doc} At740CSetMat()
Alimenta as informações do array de locais para o carregamento do grid

@sample 	At740CSetMat()

@param  	oModel, Objeto, objeto geral do model que será utilizado
			para popular o array			
@param  	cLocal, String, local utilizado para a pesquisa

@author 	Serviços
@since 		14/04/2013
/*/
//----------------------------------------------------------
Function At740CSetMat( oModel, cLocal )

aMateriais := At740BSetMat( oModel, .F., cLocal )

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
Local oModelMC	:= oModel:GetModel("TFH_GRID")
Local cGsDsGcn 	:= ""
Local cOperation := A740GetOper()

If oModel:GetOperation() == MODEL_OPERATION_INSERT 
	cGsDsGcn	:= SuperGetMv("MV_GSDSGCN",,"2")
Else
	cGsDsGcn	:= TFJ->TFJ_DSGCN
EndIf

At740ASetModel( oModel, aLocal, aRecursos, Nil, aMateriais )

If cGsDsGcn == "1"
	oModel:GetModel('TFH_GRID'):GetStruct():SetProperty('TFH_TESPED',MODEL_FIELD_OBRIGAT,.T.)	
Endif

If cOperation <> 1	//Quando não for visualização do orçamento.
	oModelRH:SetNoInsertLine(.T.)
	oModelRH:SetNoDeleteLine(.T.)
Else //Visualização do orçamento
	oModelRH:SetNoInsertLine(.T.)
	oModelRH:SetNoDeleteLine(.T.)
	oModelMC:SetNoInsertLine(.T.)
	oModelMC:SetNoDeleteLine(.T.)
EndIf

FwRestRows( aSaveRows )

Return(Nil)


//----------------------------------------------------------
/*/{Protheus.doc} At740CGet()
Retorna as informações do array de locais para o carregamento do grid

@sample 	At740CGet()


@author 	Serviços
@since 		15/04/2013
/*/
//----------------------------------------------------------
Function At740CGet()
Return(aMateriais)


//----------------------------------------------------------
/*/{Protheus.doc} At740CCommit()
Atualiza os models com as informações de local e material de implantação

@sample 	At740CCommit()

@author 	Serviços
@since 		15/04/2013
/*/
//----------------------------------------------------------
Static Function At740CCommit(oModel)

Local oModelRH := oModel:GetModel("TFF_GRID")
Local oModelMC := oModel:GetModel("TFH_GRID")
Local aMatCons := {}
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
	
	aAdd( aMatCons, { oModelRH:GetValue("TFF_ITEM"), oModelRH:GetValue("TFF_PRODUT"), {} } )	
					
	For nX:=1 To oModelMC:Length()
	
		oModelMC:GoLine(nX)
		
		If !oModelMC:IsDeleted()				
								
			aAdd( aMatCons[nI][3], Array(_TFHGRVMAT) )
			
			nLenMat := Len(aMatCons[nI][3])
			
			aMatCons[nI][3][nLenMat][ _TFHITEM ] := oModelMC:GetValue("TFH_ITEM")
			aMatCons[nI][3][nLenMat][ _TFHPRODUT ] := oModelMC:GetValue("TFH_PRODUT")
			aMatCons[nI][3][nLenMat][ _TFHDESCRI ] := oModelMC:GetValue("TFH_DESCRI")
			aMatCons[nI][3][nLenMat][ _TFHUM ] := oModelMC:GetValue("TFH_UM")
			aMatCons[nI][3][nLenMat][ _TFHQTDVEN ] := oModelMC:GetValue("TFH_QTDVEN")
			aMatCons[nI][3][nLenMat][ _TFHPERINI ] := oModelMC:GetValue("TFH_PERINI")
			aMatCons[nI][3][nLenMat][ _TFHPERFIM ] := oModelMC:GetValue("TFH_PERFIM")
			aMatCons[nI][3][nLenMat][ _TFHTES ] := oModelMC:GetValue("TFH_TES")	
			aMatCons[nI][3][nLenMat][ _TFHCODPAI ] := oModelMC:GetValue("TFH_CODPAI")
			aMatCons[nI][3][nLenMat][ _TFHTIPMAT ] := oModelMC:GetValue("TFH_TIPMAT")
			aMatCons[nI][3][nLenMat][ _TFHGRVMAT ] := oModelMC:GetValue("TFH_GRVMAT")
						
			If IsInCallStack("At870GerOrc")
			
				aMatCons[nI][3][nLenMat][ _TFHPRCVEN ] := oModelMC:GetValue("TFH_PRCVEN")
				aMatCons[nI][3][nLenMat][ _TFHTOTAL ] := oModelMC:GetValue("TFH_TOTAL")
				aMatCons[nI][3][nLenMat][ _TFHVALDES ] := oModelMC:GetValue("TFH_VALDES")
				aMatCons[nI][3][nLenMat][ _TFHDESCON ] := oModelMC:GetValue("TFH_DESCON")
				aMatCons[nI][3][nLenMat][ _TFHTOTGER ] := oModelMC:GetValue("TFH_TOTGER")
				aMatCons[nI][3][nLenMat][ _TFHTXLUCR ] := oModelMC:GetValue("TFH_TXLUCR")
				aMatCons[nI][3][nLenMat][ _TFHLUCRO ] := oModelMC:GetValue("TFH_LUCRO")
				aMatCons[nI][3][nLenMat][ _TFHADM ] := oModelMC:GetValue("TFH_ADM")
				aMatCons[nI][3][nLenMat][ _TFHTXADM ] := oModelMC:GetValue("TFH_TXADM")
				aMatCons[nI][3][nLenMat][ _TFHCOD ] := oModelMC:GetValue("TFH_COD")				
			
			EndIf
			
			If cGsDsGcn == "1"
				aMatCons[nI][3][nLenMat][ _TFHTESPED ] := oModelMC:GetValue("TFH_TESPED")
			Endif
		EndIf				
		
	Next nX	
	
Next nI

aMateriais := aMatCons

Return(.T.)

//------------------------------------------------------------------------------
/*/{Protheus.doc} A740bLinPre
	
Função para validar a alteração de Cortesia/Item Extra já confirmados. 

@sample 	A740bLinPre(oModel,nLinha,cAction, cCampo)

@since		07/05/2018       
@version	P12

@return 	lRet, retorna permissão de alteração.

/*/
//------------------------------------------------------------------------------
Function A740cLinPre(oModel,nLinha,cAction, cCampo)

Local oModel		:= FwModelActive()
Local oModelMC		:= IIF((oModel <> NIL),oModel:GetModel("TFH_GRID"), NIL)
Local lRet := .T.

If oModelMC <> NIL 
	If cAction == "CANSETVALUE" .AND. oModelMC:GetValue("TFH_GRVMAT") == "1" //Gravado
		If cCampo == "TFH_PERINI" .OR. cCampo == "TFH_PERFIM"
			lRet := .T.
		Else
			lRet := .F.
		EndIf
	ElseIf cAction == "DELETE" 
		If oModelMC:GetValue("TFH_GRVMAT") == "1" //Gravado 
			Help(,,"A740bLinPre",,STR0004,1,0)
			lRet := .F.
		EndIf
	EndIf
EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} A740cLinPost
	
Função para validar preenchimento do preço dos produtos.

@sample 	A740cLinPost(oModel,nLinha,cAction, cCampo)

@since		07/05/2018       
@version	P12

@return 	lRet, retorna permissão de alteração.

/*/
//------------------------------------------------------------------------------
Function A740cLinPost(oModel,nLinha,cAction, cCampo)

Local oModel		:= FwModelActive()
Local oModelMC		:= IIF((oModel <> NIL),oModel:GetModel("TFH_GRID"), NIL)
Local lRet := .T.

If IsInCallStack("At870GerOrc") .AND. IsInCallStack("At740Cortesia") .AND. oModelMC:GetValue("TFH_TIPMAT") <> "1"
	If oModelMC <> NIL .AND. oModelMC:IsUpdated()
		If Empty(oModelMC:GetValue("TFH_PRCVEN")) 
			Help(,,"A740cLinPost",,STR0005 + Str(nLinha),1,0)
			lRet := .F.
		EndIf
	EndIf
EndIf

Return lRet
