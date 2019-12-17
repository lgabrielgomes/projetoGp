#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"
#Include 'TECA933.ch'

//-------------------------------------------------------------------
/*/{Protheus.doc} TECA933()
Rotina para faturamento do dissidio antes de efetuar a revisão para ajuste de valores.

@author Pâmela Bernardo
@since 17/05/2018
@version 1.0
/*/
//-------------------------------------------------------------------
Function TECA933 ()
	Local oMBrowse := NIL
	
	Private aRotina			:= MenuDef()
	Private lMsErroAuto    	:= .F.
	Private lMsHelpAuto    	:= .T.
	Private lAutoErrNoFile 	:= .F.
		
	oMBrowse:= FWMBrowse():New()	
	oMBrowse:SetAlias('TX0')
	oMBrowse:SetDescription(STR0001)//'Faturamento de Dissidio'
	oMBrowse:Activate()
	
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} MenuDef()
Menu Funcional da Rotina 

@author Pâmela Bernardo
@since 17/05/2018
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function MenuDef()   

	Local aRotina := {}
	Local aLote := {}
	
	ADD OPTION aLote TITLE STR0002 	ACTION "A933ILote" OPERATION 3 ACCESS 0   // "Incluir"
	ADD OPTION aLote TITLE STR0003 	ACTION "A933ELote" OPERATION 5 ACCESS 0   // 'Excluir'
	
	ADD OPTION aRotina Title STR0004	Action 'VIEWDEF.TECA933' OPERATION 2 ACCESS 0 //'Visualizar'
	ADD OPTION aRotina Title STR0002   	Action 'A933Incl()' 	OPERATION 3 ACCESS 0 //'Incluir'
	ADD OPTION aRotina Title STR0003   	Action 'VIEWDEF.TECA933' OPERATION 5 ACCESS 0 //'Excluir'
	ADD OPTION aRotina Title STR0005   	Action 'VIEWDEF.TECA933' OPERATION 8 ACCESS 0 //'Imprimir'
	ADD OPTION aRotina TITLE STR0006	Action aLote 			OPERATION 3 ACCESS 0   //"Op. Em Lotes"
	
Return(aRotina) 

//------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
@description	Definição do Model
@sample	 		ModelDef()
@author 		Pâmela Bernardo
@since 			17/05/2018
@version		1.0
/*/
//------------------------------------------------------------------------------
Static Function ModelDef() 

	Local oStrTX0 := FWFormStruct( 1, 'TX0' )
	Local oStrTX1 := FWFormStruct( 1, 'TX1' )
	Local oModel 	 := Nil  
	Local aAux		:= {}
	
	oStrTX0:AddField(	STR0007,;								// 	[01]  C   Titulo do campo //Nome Cliente"
						STR0008,;								// 	[02]  C   ToolTip do campo //"Nome Cli."
						 "TX0_XDESCL",;								// 	[03]  C   Id do Field
						 "C",;										// 	[04]  C   Tipo do campo
						 TamSX3("A1_NOME")[1],;					// 	[05]  N   Tamanho do campo
						 0,;										// 	[06]  N   Decimal do campo
						 NIL,;										// 	[07]  B   Code-block de validação do campo
						 NIL,;										// 	[08]  B   Code-block de validação When do campo
						 NIL,;										//	[09]  A   Lista de valores permitido do campo
						 .F.,;										//	[10]  L   Indica se o campo tem preenchimento obrigatório
						 {||A933InPad("TX0_XDESCL")},;									//	[11]  B   Code-block de inicializacao do campo
						 NIL,;										//	[12]  L   Indica se trata-se de um campo chave
						 .T.,;										//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
						 .T.)										// 	[14]  L   Indica se o campo é virtual
						 
						 
	oStrTX1:AddField(	STR0009,;								// 	[01]  C   Titulo do campo //"Municipio"
						STR0009,;								// 	[02]  C   ToolTip do campo //"Municipio"
						 "TX1_XMUNIC",;								// 	[03]  C   Id do Field
						 "C",;										// 	[04]  C   Tipo do campo
						 TamSX3("ABS_MUNIC")[1],;					// 	[05]  N   Tamanho do campo
						 0,;										// 	[06]  N   Decimal do campo
						 NIL,;										// 	[07]  B   Code-block de validação do campo
						 NIL,;										// 	[08]  B   Code-block de validação When do campo
						 NIL,;										//	[09]  A   Lista de valores permitido do campo
						 .F.,;										//	[10]  L   Indica se o campo tem preenchimento obrigatório
						 {||A933InPad("TX1_XMUNIC")},;									//	[11]  B   Code-block de inicializacao do campo
						 NIL,;										//	[12]  L   Indica se trata-se de um campo chave
						 .T.,;										//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
						 .T.)										// 	[14]  L   Indica se o campo é virtual
						 

	oStrTX1:AddField(	RetTitle("ABS_RECISS"),;								// 	[01]  C   Titulo do campo //"ABS_RECISS"
						RetTitle("ABS_RECISS"),;								// 	[02]  C   ToolTip do campo //"ABS_RECISS"
						 "TX1_XRCISS",;								// 	[03]  C   Id do Field
						 GetSX3Cache( "ABS_RECISS", "X3_TIPO" ),;										// 	[04]  C   Tipo do campo
						 TamSX3("ABS_RECISS")[1],;					// 	[05]  N   Tamanho do campo
						 0,;										// 	[06]  N   Decimal do campo
						 NIL,;										// 	[07]  B   Code-block de validação do campo
						 NIL,;										// 	[08]  B   Code-block de validação When do campo
						 NIL,;										//	[09]  A   Lista de valores permitido do campo
						 .F.,;										//	[10]  L   Indica se o campo tem preenchimento obrigatório
						 {||A933InPad("TX1_XRCISS")},;									//	[11]  B   Code-block de inicializacao do campo
						 NIL,;										//	[12]  L   Indica se trata-se de um campo chave
						 .T.,;										//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
						 .T.)	

	oStrTX1:AddField(	RetTitle("ABS_CODMUN"),;								// 	[01]  C   Titulo do campo //"ABS_CODMUN"
						RetTitle("ABS_CODMUN"),;								// 	[02]  C   ToolTip do campo //"ABS_CODMUN"
						 "TX1_XCDNUM",;								// 	[03]  C   Id do Field
						 GetSX3Cache( "ABS_CODMUN", "X3_TIPO" ),;										// 	[04]  C   Tipo do campo
						 TamSX3("ABS_CODMUN")[1],;					// 	[05]  N   Tamanho do campo
						 0,;										// 	[06]  N   Decimal do campo
						 NIL,;										// 	[07]  B   Code-block de validação do campo
						 NIL,;										// 	[08]  B   Code-block de validação When do campo
						 NIL,;										//	[09]  A   Lista de valores permitido do campo
						 .F.,;										//	[10]  L   Indica se o campo tem preenchimento obrigatório
						 {||A933InPad("TX1_XCDNUM")},;									//	[11]  B   Code-block de inicializacao do campo
						 NIL,;										//	[12]  L   Indica se trata-se de um campo chave
						 .T.,;										//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
						 .T.)
	oStrTX1:AddField(	RetTitle("ABS_ESTADO"),;								// 	[01]  C   Titulo do campo //"ABS_ESTADO"
						RetTitle("ABS_ESTADO"),;								// 	[02]  C   ToolTip do campo //"ABS_ESTADO"
						 "TX1_XESTAD",;								// 	[03]  C   Id do Field
						 GetSX3Cache( "ABS_ESTADO", "X3_TIPO" ),;										// 	[04]  C   Tipo do campo
						 TamSX3("ABS_ESTADO")[1],;					// 	[05]  N   Tamanho do campo
						 0,;										// 	[06]  N   Decimal do campo
						 NIL,;										// 	[07]  B   Code-block de validação do campo
						 NIL,;										// 	[08]  B   Code-block de validação When do campo
						 NIL,;										//	[09]  A   Lista de valores permitido do campo
						 .F.,;										//	[10]  L   Indica se o campo tem preenchimento obrigatório
						 {||A933InPad("TX1_XESTAD")},;									//	[11]  B   Code-block de inicializacao do campo
						 NIL,;										//	[12]  L   Indica se trata-se de um campo chave
						 .T.,;										//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
						 .T.)
							 
	oStrTX1:AddField(	STR0010,;								// 	[01]  C   Titulo do campo //"Descrição"
						STR0010,;								// 	[02]  C   ToolTip do campo //"Descrição"
						 "TX1_XDESLO",;								// 	[03]  C   Id do Field
						 "C",;										// 	[04]  C   Tipo do campo
						 TamSX3("ABS_DESCRI")[1],;					// 	[05]  N   Tamanho do campo
						 0,;										// 	[06]  N   Decimal do campo
						 NIL,;										// 	[07]  B   Code-block de validação do campo
						 NIL,;										// 	[08]  B   Code-block de validação When do campo
						 NIL,;										//	[09]  A   Lista de valores permitido do campo
						 .F.,;										//	[10]  L   Indica se o campo tem preenchimento obrigatório
						 {|| A933InPad("TX1_XDESLO")},;									//	[11]  B   Code-block de inicializacao do campo
						 NIL,;										//	[12]  L   Indica se trata-se de um campo chave
						 .T.,;										//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
						 .T.)										// 	[14]  L   Indica se o campo é virtual
	
	oStrTX1:AddField(	STR0011,;								// 	[01]  C   Titulo do campo //"Desc Produto"
						STR0011,;								// 	[02]  C   ToolTip do campo //"Desc Produto"
						 "TX1_XDESPR",;								// 	[03]  C   Id do Field
						 "C",;										// 	[04]  C   Tipo do campo
						 TamSX3("B1_DESC")[1],;					// 	[05]  N   Tamanho do campo
						 0,;										// 	[06]  N   Decimal do campo
						 NIL,;										// 	[07]  B   Code-block de validação do campo
						 NIL,;										// 	[08]  B   Code-block de validação When do campo
						 NIL,;										//	[09]  A   Lista de valores permitido do campo
						 .F.,;										//	[10]  L   Indica se o campo tem preenchimento obrigatório
						 {||A933InPad("TX1_XDESPR")},;									//	[11]  B   Code-block de inicializacao do campo
						 NIL,;										//	[12]  L   Indica se trata-se de um campo chave
						 .T.,;										//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
						 .T.)										// 	[14]  L   Indica se o campo é virtual



	oStrTX1:AddField(	RetTitle("B1_CODISS"),;								// 	[01]  C   Titulo do campo //"B1_CODISS"
						RetTitle("B1_CODISS"),;								// 	[02]  C   ToolTip do campo //"B1_CODISS"
						 "TX1_XCDISS",;								// 	[03]  C   Id do Field
						 GetSX3Cache( "B1_CODISS", "X3_TIPO" ),;										// 	[04]  C   Tipo do campo
						 SB1->( TamSX3("B1_CODISS")[1]),;					// 	[05]  N   Tamanho do campo
						 0,;										// 	[06]  N   Decimal do campo
						 NIL,;										// 	[07]  B   Code-block de validação do campo
						 NIL,;										// 	[08]  B   Code-block de validação When do campo
						 NIL,;										//	[09]  A   Lista de valores permitido do campo
						 .F.,;										//	[10]  L   Indica se o campo tem preenchimento obrigatório
						 {||A933InPad("TX1_XCDISS")},;									//	[11]  B   Code-block de inicializacao do campo
						 NIL,;										//	[12]  L   Indica se trata-se de um campo chave
						 .T.,;										//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
						 .T.)										// 	[14]  L   Indica se o campo é virtual						 
						 
	aAux := FwStruTrigger( "TX0_CONTRT", "TX0_XDESCL", "POSICIONE('SA1',1,XFILIAL('SA1')+ TFJ->TFJ_CODENT+TFJ->TFJ_LOJA,'A1_NOME')", .F. )
	oStrTX0:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])
	
	//FUNÇÃO PARA A CARGA TX1
	aAux := FwStruTrigger( "TX0_CONTRT", "TX0_CONTRT", "A933Load()", .F. )
	oStrTX0:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])
	
	aAux := FwStruTrigger( "TX0_DATA", "TX0_DATA", "A933Load()", .F. )
	oStrTX0:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])
	
	aAux := FwStruTrigger( "TX0_PERCEN", "TX0_PERCEN", "A933Diss()", .F. )
	oStrTX0:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])
	
	aAux := FwStruTrigger( "TX1_PERCEN", "TX1_PERCEN", "A933Vlr()", .F. )
	oStrTX1:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])
	//aqui pam
	aAux := FwStruTrigger( "TX1_VLDISS", "TX1_VLDISS", "A933Per()", .F. )
	oStrTX1:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])
		
	oModel := MPFormModel():New('TECA933M',/*bPreVld*/, /*bPosVld*/,{|oModel| A933Comt(oModel)} ) 
	
	oModel:AddFields( 'TX0MASTER', /*cOwner*/ , oStrTX0) 
	oModel:AddGrid  ( 'TX1DETAIL', 'TX0MASTER', oStrTX1,,,,, )
	oModel:SetRelation('TX1DETAIL', { { 'TX1_FILIAL', 'xFilial("TX0")' }, { 'TX1_CODIGO', 'TX0_CODIGO' } }, TX1->(IndexKey(1)) )
	oModel:SetPrimaryKey({"TX1_FILIAL","TX1_CODIGO","TX1_ITEM"})
	
	
	// --------------------------------------------
	// Desabilita todos os campos obrigatórios
	// Exceção do campo de supervisor.
	// --------------------------------------------
	oModel:GetModel('TX1DETAIL'):SetOptional(.T.)
	// --------------------------------------------
	// Não permite apagar linhas do grid
	// --------------------------------------------
	oModel:GetModel('TX1DETAIL'):SetNoDeleteLine(.T.)
	
	oModel:SetDescription( STR0001 ) // 'Faturamento de Dissidio'
	oModel:GetModel( 'TX0MASTER' ):SetDescription( STR0012) // "Orçamento"
	
	
	oModel:SetVldActivate( {|| .T. } )

Return oModel


//-------------------------------------------------------------------
/*/{Protheus.doc} ViewDef()
Estrutura de Visualização

@author Pâmela Bernardo
@since 17/05/2018
@version 1.0
/*/
//-------------------------------------------------------------------

Static Function ViewDef() 

	Local oModel 	:= FWLoadModel('TECA933')
	Local oStrTX0 	:= FWFormStruct( 2, 'TX0')  
	Local oStrTX1 	:= FWFormStruct( 2, 'TX1')
	
	Private oView := Nil
	
	oStrTX0:AddField( ;									// Ord. Tipo Desc.
							"TX0_XDESCL",;					// [01] C Nome do Campo
							"6",;							// [02] C Ordem
							STR0007,;						// [03] C Titulo do campo # "Nome Cliente" 
							STR0008,;						// [04] C Descrição do campo #"Nome Cli."
							Nil,;							// [05] A Array com Help
							"C",;							// [06] C Tipo do campo
							"@!",;							// [07] C Picture
							NIL,;							// [08] B Bloco de Picture Var
							"",;							// [09] C Consulta F3
							.F.,;							// [10] L Indica se o campo é editável
							NIL,;							// [11] C Pasta do campo
							NIL,;							// [12] C Agrupamento do campo
							NIL,;							// [13] A Lista de valores permitido do campo (Combo)
							NIL,;							// [14] N Tamanho Maximo da maior opção do combo
							NIL,;							// [15] C Inicializador de Browse
							.T.,;							// [16] L Indica se o campo é virtual
							NIL )							// [17] C Picture Variável
	oStrTX1:AddField( ;									// Ord. Tipo Desc.
							"TX1_XMUNIC",;					// [01] C Nome do Campo
							"4",;							// [02] C Ordem
							STR0009,;						// [03] C Titulo do campo # "Municipio"
							STR0009,;						// [04] C Descrição do campo # "Municipio" 
							Nil,;							// [05] A Array com Help
							"C",;							// [06] C Tipo do campo
							"@!",;							// [07] C Picture
							NIL,;							// [08] B Bloco de Picture Var
							"",;							// [09] C Consulta F3
							.F.,;							// [10] L Indica se o campo é editável
							NIL,;							// [11] C Pasta do campo
							NIL,;							// [12] C Agrupamento do campo
							NIL,;							// [13] A Lista de valores permitido do campo (Combo)
							NIL,;							// [14] N Tamanho Maximo da maior opção do combo
							NIL,;							// [15] C Inicializador de Browse
							.T.,;							// [16] L Indica se o campo é virtual
							NIL )							// [17] C Picture Variável
							
	oStrTX1:AddField( ;									// Ord. Tipo Desc.
							"TX1_XDESLO",;					// [01] C Nome do Campo
							"4",;							// [02] C Ordem
							STR0010,;						// [03] C Titulo do campo #"Descrição"
							STR0010,;						// [04] C Descrição do campo # "Descrição" 
							Nil,;							// [05] A Array com Help
							"C",;							// [06] C Tipo do campo
							"@!",;							// [07] C Picture
							NIL,;							// [08] B Bloco de Picture Var
							"",;							// [09] C Consulta F3
							.F.,;							// [10] L Indica se o campo é editável
							NIL,;							// [11] C Pasta do campo
							NIL,;							// [12] C Agrupamento do campo
							NIL,;							// [13] A Lista de valores permitido do campo (Combo)
							NIL,;							// [14] N Tamanho Maximo da maior opção do combo
							NIL,;							// [15] C Inicializador de Browse
							.T.,;							// [16] L Indica se o campo é virtual
							NIL )							// [17] C Picture Variável
							
	oStrTX1:AddField( ;									// Ord. Tipo Desc.
							"TX1_XDESPR",;					// [01] C Nome do Campo
							"4",;							// [02] C Ordem
							STR0011,;						// [03] C Titulo do campo #"Desc Produto" 
							STR0011,;						// [04] C Descrição do campo #"Desc Produto"
							Nil,;							// [05] A Array com Help
							"C",;							// [06] C Tipo do campo
							"@!",;							// [07] C Picture
							NIL,;							// [08] B Bloco de Picture Var
							"",;							// [09] C Consulta F3
							.F.,;							// [10] L Indica se o campo é editável
							NIL,;							// [11] C Pasta do campo
							NIL,;							// [12] C Agrupamento do campo
							NIL,;							// [13] A Lista de valores permitido do campo (Combo)
							NIL,;							// [14] N Tamanho Maximo da maior opção do combo
							NIL,;							// [15] C Inicializador de Browse
							.T.,;							// [16] L Indica se o campo é virtual
							NIL )							// [17] C Picture Variável
				
	
	//Ordenação dos campos
	
	oStrTX0:SetProperty("TX0_CODIGO"	, MVC_VIEW_ORDEM, "01")
	oStrTX0:SetProperty("TX0_CONTRT"	, MVC_VIEW_ORDEM, "02")
	oStrTX0:SetProperty("TX0_REVISA"	, MVC_VIEW_ORDEM, "03")
	oStrTX0:SetProperty("TX0_TPCONT"	, MVC_VIEW_ORDEM, "04")
	oStrTX0:SetProperty("TX0_DATA"		, MVC_VIEW_ORDEM, "05")
	oStrTX0:SetProperty("TX0_PERCEN"	, MVC_VIEW_ORDEM, "06")
	oStrTX0:SetProperty("TX0_CLIENT"	, MVC_VIEW_ORDEM, "07")
	oStrTX0:SetProperty("TX0_LOJA"		, MVC_VIEW_ORDEM, "08")
	oStrTX0:SetProperty("TX0_XDESCL"	, MVC_VIEW_ORDEM, "09")
	
	oStrTX1:SetProperty("TX1_ITEM"		, MVC_VIEW_ORDEM, "02")
	oStrTX1:SetProperty("TX1_LOCAL"		, MVC_VIEW_ORDEM, "03")
	oStrTX1:SetProperty("TX1_XDESLO"	, MVC_VIEW_ORDEM, "04")
	oStrTX1:SetProperty("TX1_XMUNIC"	, MVC_VIEW_ORDEM, "05")
	oStrTX1:SetProperty("TX1_RECHUM"	, MVC_VIEW_ORDEM, "06")
	oStrTX1:SetProperty("TX1_PRODUT"	, MVC_VIEW_ORDEM, "07")
	oStrTX1:SetProperty("TX1_XDESPR"	, MVC_VIEW_ORDEM, "08")
	oStrTX1:SetProperty("TX1_VLCONT"	, MVC_VIEW_ORDEM, "09")
	oStrTX1:SetProperty("TX1_PERCEN"	, MVC_VIEW_ORDEM, "10")
	oStrTX1:SetProperty("TX1_VLDISS"	, MVC_VIEW_ORDEM, "11")
	
	//Trava dos campos de cabeçalho
	oStrTX0:SetProperty("TX0_CODIGO"	,MVC_VIEW_CANCHANGE, .F.)
	oStrTX0:SetProperty("TX0_REVISA"	,MVC_VIEW_CANCHANGE, .F.)
	oStrTX0:SetProperty("TX0_CLIENT"	,MVC_VIEW_CANCHANGE, .F.)
	oStrTX0:SetProperty("TX0_LOJA"		,MVC_VIEW_CANCHANGE, .F.)
	oStrTX0:SetProperty("TX0_TPCONT"	,MVC_VIEW_CANCHANGE, .F.)
	
	//trava dos campos itens
	oStrTX1:SetProperty("TX1_ITEM"		,MVC_VIEW_CANCHANGE, .F.)
	oStrTX1:SetProperty("TX1_LOCAL"		,MVC_VIEW_CANCHANGE, .F.)
	oStrTX1:SetProperty("TX1_RECHUM"	,MVC_VIEW_CANCHANGE, .F.)
	oStrTX1:SetProperty("TX1_PRODUT"	,MVC_VIEW_CANCHANGE, .F.)
	oStrTX1:SetProperty("TX1_VLCONT"	,MVC_VIEW_CANCHANGE, .F.)
	
	oView:= FWFormView():New() 
	
	oView:SetModel( oModel )
	
	// ----------------------------------------------------------
	// DEFINIÇÃO VISUAL DE LAYOUT     
	// ----------------------------------------------------------
	oView:AddField( 'VIEW_TX0' , oStrTX0, 'TX0MASTER' ) 
	oView:AddGrid ( 'VIEW_TX1' , oStrTX1, 'TX1DETAIL' )
	
	oView:CreateHorizontalBox	( 'SUPERIOR'   , 030 )   
	oView:CreateHorizontalBox	( 'INFERIOR1'  , 070 ) 
	
	oView:SetOwnerView( 'VIEW_TX0', 'SUPERIOR'	)
	oView:SetOwnerView( 'VIEW_TX1', 'INFERIOR1'	)  
	
	oView:EnableTitleView('VIEW_TX1',STR0013	)//'Recursos Humanos'	
	
	oStrTX1:RemoveField("TX1_CODIGO")
	oStrTX1:RemoveField("TX1_PEDIDO")


Return oView

//------------------------------------------------------------------------------
/*/{Protheus.doc} A933Load
@description	Gatilho para carregar a grid com dados do contrato
@sample	 		A933Load()
@author 		Pâmela Bernardo
@since 			17/05/2018
@version 		1.0
/*/
//------------------------------------------------------------------------------
Function A933Load()

	Local oMdl		:= FwModelActive()
	Local oView		:= FwViewActive()
	Local oMdlTX0	:= oMdl:GetModel("TX0MASTER")
	Local oMdlTX1	:= oMdl:GetModel("TX1DETAIL")
	Local cAliasQry	:= GetNextAlias()
	Local dDtIni	:= FirstDay(oMdlTX0:GetValue("TX0_DATA"))
	Local dDtFim	:= LastDay(oMdlTX0:GetValue("TX0_DATA"))
	Local cContrato	:= oMdlTX0:GetValue("TX0_CONTRT")
	Local cRevCtr	:= oMdlTX0:GetValue("TX0_REVISA")
	Local lRecorr	:= oMdlTX0:GetValue("TX0_TPCONT")== "1"
	Local nPerc		:= oMdlTX0:GetValue("TX0_PERCEN")
	Local cCodigo	:= oMdlTX0:GetValue("TX0_CODIGO")
	Local cWhereCob	:= ""
	Local cChvTFL	:= ""
	Local nLinha	:= 0
	Local cItem		:= StrZero(0,TamSX3("TX1_ITEM")[1])
	Local nAux		:= 0
	Local cMunic	:= ""
	
	oMdlTX1:SetNoInsertLine(.F.)
	oMdlTX1:ClearData()
	
	cChvTFL := "%TFL.TFL_CONTRT = '" + cContrato + "' AND "
	cChvTFL += " TFL.TFL_CONREV = '" + cRevCtr  + "'%"
	
	cWhereCob := "%TFF.TFF_CONTRT = '" + cContrato + "' AND "
	cWhereCob += "TFF.TFF_CONREV = '" + cRevCtr + "' AND " 
	cWhereCob += "TFF.TFF_COBCTR <> '2' AND TFF.TFF_PRCVEN > 0%"
	
		//Levanatamento de apontamentos dos apontamentos efetuados
		BeginSql Alias cAliasQry
			
			SELECT TFL.TFL_CODIGO, TFL.TFL_LOCAL, ABS.ABS_DESCRI,ABS.ABS_MUNIC, ABS.ABS_RECISS, ABS.ABS_CODMUN, ABS.ABS_ESTADO,TFF.TFF_COD, TFF.TFF_PRODUT, 
			       SB1.B1_DESC, SB1.B1_CODISS, TFF.TFF_QTDVEN, TFF.TFF_PRCVEN, TFF.TFF_VALDES, 
			       TFF.TFF_PERINI, TFF.TFF_PERFIM,TFF.TFF_TXLUCR, TFF.TFF_TXADM
			       
			  FROM %table:TFF% TFF
			       LEFT JOIN %table:TFL% TFL ON TFL.TFL_FILIAL = %xFilial:TFL% 
			                                AND TFL.TFL_CODIGO = TFF.TFF_CODPAI 
											AND TFL.TFL_CONTRT = %Exp:cContrato% 
											AND TFL.TFL_CONREV = %Exp:cRevCtr% 
			                                AND TFL.%NotDel%      
											AND TFL.TFL_TOTRH > 0              
											AND %Exp:cChvTFL% 
			       LEFT JOIN %table:ABS% ABS ON ABS.ABS_FILIAL = %xFilial:ABS% 
			                                AND ABS.ABS_LOCAL = TFL.TFL_LOCAL 
			                                AND ABS.%NotDel%
			       LEFT JOIN %table:SB1% SB1 ON SB1.B1_FILIAL = %xFilial:SB1% 
		  	                                AND SB1.B1_COD = TFF.TFF_PRODUT 
		  	                                AND SB1.%NotDel%
			 WHERE TFF.TFF_FILIAL = %xFilial:TFF%
			   AND TFF.%NotDel%
			   AND %Exp:cWhereCob% 		
			   AND NOT( TFF_PERINI > %Exp:dDtFim% OR TFF_PERFIM < %Exp:dDtIni% )
			 GROUP BY TFL.TFL_CODIGO, TFL.TFL_LOCAL, ABS.ABS_DESCRI,ABS.ABS_MUNIC, ABS.ABS_RECISS, ABS.ABS_CODMUN, ABS.ABS_ESTADO,TFF.TFF_COD, TFF.TFF_PRODUT, 
			          SB1.B1_DESC, SB1.B1_CODISS, TFF.TFF_QTDVEN, TFF.TFF_PRCVEN, TFF.TFF_VALDES, 
			          TFF.TFF_PERINI, TFF.TFF_PERFIM,TFF.TFF_TXLUCR, TFF.TFF_TXADM
		ORDER BY TFF_COD
	
	EndSql
	
	While (cAliasQry)->(!Eof())
	
		If nLinha > 0 
			oMdlTX1:Addline()
		EndIf 
		cItem := Soma1(cItem)
		cMunic := POSICIONE("ABS",1,xFilial("ABS")+(cAliasQry)->(TFL_LOCAL),"ABS_MUNIC")
		
		oMdlTX1:SetValue("TX1_CODIGO"	, cCodigo)
		oMdlTX1:SetValue("TX1_ITEM"		, cItem)
		oMdlTX1:SetValue("TX1_LOCAL"	, (cAliasQry)->(TFL_LOCAL))
		oMdlTX1:SetValue("TX1_XDESLO"	, (cAliasQry)->(ABS_DESCRI))
		oMdlTX1:SetValue("TX1_XRCISS"	, (cAliasQry)->(ABS_RECISS))
		oMdlTX1:SetValue("TX1_XCDNUM"	, (cAliasQry)->(ABS_CODMUN))
		oMdlTX1:SetValue("TX1_XESTAD"	, (cAliasQry)->(ABS_ESTADO))		
		oMdlTX1:SetValue("TX1_RECHUM"	, (cAliasQry)->(TFF_COD))
		oMdlTX1:SetValue("TX1_PRODUT"	, (cAliasQry)->(TFF_PRODUT))
		oMdlTX1:SetValue("TX1_XDESPR"	, (cAliasQry)->(B1_DESC))
		oMdlTX1:SetValue("TX1_XCDISS"	, (cAliasQry)->(B1_CODISS))
		oMdlTX1:SetValue("TX1_XMUNIC"	, cMunic)
		If lRecorr
			oMdlTX1:SetValue("TX1_VLCONT", (cAliasQry)->(TFF_PRCVEN)*(cAliasQry)->(TFF_QTDVEN))
		Else
			nAux := (SToD((cAliasQry)->(TFF_PERFIM)) - SToD((cAliasQry)->(TFF_PERINI)))/30 //periodo em meses
			oMdlTX1:SetValue("TX1_VLCONT", ((cAliasQry)->(TFF_PRCVEN)/INT(nAux))*(cAliasQry)->(TFF_QTDVEN))
		Endif
		oMdlTX1:SetValue("TX1_PERCEN", nPerc)
		oMdlTX1:SetValue("TX1_VLDISS", ((cAliasQry)->(TFF_PRCVEN)*nPerc)/100)
			
		(cAliasQry)->(dbSkip())
		nLinha++
	
	Enddo
	
	
	(cAliasQry)->(DbCloseArea())
	
	oMdlTX1:Goline(1)
	
	If	oView:IsActive()
		oView:Refresh()
	EndIf
	
	oMdlTX1:SetNoInsertLine(.T.)

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} A933Diss
@description	Gatilho para atualizar os campos de Percentual de dissidio
@sample	 		A933Diss()
@author 		Pâmela Bernardo
@since 			17/05/2018
@version 		1.0
/*/
//------------------------------------------------------------------------------
Function A933Diss()

	Local oMdl		:= FwModelActive()
	Local oView		:= FwViewActive()
	Local oMdlTX0	:= oMdl:GetModel("TX0MASTER")
	Local oMdlTX1	:= oMdl:GetModel("TX1DETAIL")
	Local nPerc		:= oMdlTX0:GetValue("TX0_PERCEN")
	Local nTamTX1	:= oMdlTX1:Length()
	Local nX		:= 1
	
	If !oMdlTX1:IsEmpty()
		For nX := 1 to nTamTX1
			oMdlTX1:Goline(nX)
			oMdlTX1:SetValue("TX1_PERCEN", nPerc)
		Next nX
	EndIf
	
	oMdlTX1:Goline(1)
	
	If	oView:IsActive()
		oView:Refresh()
	EndIf

Return


//------------------------------------------------------------------------------
/*/{Protheus.doc} A933Vlr
@description	Gatilho para atualizar os valores dissidio
@sample	 		A933Vlr()
@author 		Pâmela Bernardo
@since 			17/05/2018
@version 		1.0
/*/
//------------------------------------------------------------------------------
Function A933Vlr()

	Local oMdl		:= FwModelActive()
	Local oView		:= FwViewActive()
	Local oMdlTX0	:= oMdl:GetModel("TX0MASTER")
	Local oMdlTX1	:= oMdl:GetModel("TX1DETAIL")
	Local nPerc		:= oMdlTX1:GetValue("TX1_PERCEN")
	Local nVlrContr	:= oMdlTX1:GetValue("TX1_VLCONT")
	
	oMdlTX1:SetValue("TX1_VLDISS", (nVlrContr*nPerc)/100)
	
	If	oView:IsActive()
		oView:Refresh()
	EndIf

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} A933Per
@description	Gatilho para atualizar os percentuais dissidio
@sample	 		A933Per()
@author 		Pâmela Bernardo
@since 			17/05/2018
@version 		1.0
/*/
//------------------------------------------------------------------------------
Function A933Per()

	Local oMdl		:= FwModelActive()
	Local oView		:= FwViewActive()
	Local oMdlTX0	:= oMdl:GetModel("TX0MASTER")
	Local oMdlTX1	:= oMdl:GetModel("TX1DETAIL")
	Local nPerc		:= 0 //oMdlTX1:GetValue("TX1_PERCEN")
	Local nVlrContr	:= oMdlTX1:GetValue("TX1_VLCONT")
	Local nVlrDig	:= oMdlTX1:GetValue("TX1_VLDISS")
	
	oMdlTX1:SetValue("TX1_PERCEN", Round(Round((nVlrDig*100)/nVlrContr,3),2))
	
	If	oView:IsActive()
		oView:Refresh()
	EndIf

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} A933Comt
@description	Gravação dos pedidos de venda 
@sample	 		A933Comt()
@author 		Pâmela Bernardo
@since 			17/05/2018
@version 		1.0
/*/
//------------------------------------------------------------------------------
Function A933Comt(oModel)
	Local lRet := .F.
	
	MsgRun( STR0014, STR0015, {|| lRet := A933Grv(oModel) } ) //"Processamendo do Dissidio"##"Aguarde"

Return lRet
//------------------------------------------------------------------------------
/*/{Protheus.doc} A933Grv
@description	Gravação dos pedidos de venda 
@sample	 		A933Comt()
@author 		Pâmela Bernardo
@since 			17/05/2018
@version 		1.0
/*/
//------------------------------------------------------------------------------
Function A933Grv(oModel)

	Local oMdl		:= FwModelActive()
	Local oView		:= FwViewActive()
	Local oMdlTX0	:= oMdl:GetModel("TX0MASTER")
	Local oMdlTX1	:= oMdl:GetModel("TX1DETAIL")
	Local lRet		:= .T.
	Local aPedido	:= {}
	Local aItens	:= {}
	Local nX		:= 1
	Local nTamTX1	:= oMdlTX1:Length()
	Local cContrato	:= oMdlTX0:GetValue("TX0_CONTRT")
	Local cRevCtr	:= oMdlTX0:GetValue("TX0_REVISA")
	Local nPos		:= 0
	Local cCodTes	:= ""
	Local cCodCli	:= ""
	Local cLoja		:= ""
	Local cPlan		:= ""
	Local aNumPed	:= {}
	Local cCodPgto	:= ""
	Local nOper		:= oMdl:GetOperation()
	Local lA933EstPed	:=  ExistBlock("A933EstPed")//ponto de entrada validação do estorno do pedido	
	Local lCont			:= .T.
	Local nDecs		:= SC6->(TamSx3("C6_VALOR")[2])

	Begin Transaction
	
		If nOper == MODEL_OPERATION_INSERT
			For nX := 1 to nTamTX1
			
				oMdlTX1:Goline(nX)
				aItens := {}
				cCodTes:= Posicione("TFF",1,xFilial("TFF")+oMdlTX1:GetValue("TX1_RECHUM"),"TFF_TESPED")
				cCodPgto:= Posicione("TFJ",5,xFilial("TFJ")+cContrato+cRevCtr,"TFJ_CONDPG")
				
				nPos := aScan( aPedido, { |x| x[01] == oMdlTX1:GetValue("TX1_LOCAL") .and. x[09] == oMdlTX1:GetValue("TX1_XCDISS")   })
				If nPos == 0
					//A933GetCl(cContrato, cRevCtr, oMdlTX1:GetValue("TX1_LOCAL"),@cCodCli,@cLoja, @cPlan)
					At850GetCli( @cCodCli,@cLoja, oMdlTX1:GetValue("TX1_LOCAL"), TFJ->TFJ_AGRUP)
					cPlan := Posicione("TFL", 4, xFilial("TFL") + cContrato + cRevCtr + oMdlTX1:GetValue("TX1_LOCAL"), "TFL_PLAN" )
					If !Empty(cCodCli)
						aAdd(aItens, {Round(oMdlTX1:GetValue("TX1_VLDISS"),nDecs), oMdlTX1:GetValue("TX1_PRODUT"), cCodTes} )
						aAdd(aPedido, {oMdlTX1:GetValue("TX1_LOCAL") , cCodCli , cLoja,;
										aItens, cContrato, cPlan, cCodPgto, cRevCtr,;
										oMdlTX1:GetValue("TX1_XCDISS"), oMdlTX1:GetValue("TX1_XRCISS"),oMdlTX1:GetValue("TX1_XESTAD") , oMdlTX1:GetValue("TX1_XCDNUM") })
					Else
						lRet := .F.
						Help(" ",1,"A933NOCLI", , STR0026 + oMdlTX1:GetValue("TX1_LOCAL") + STR0027, 3, 1 ) //"Cliente do Local "# " Não encontrado"
						Exit
					EndIf
				Else
					aAdd(aPedido[nPos][4],{Round(oMdlTX1:GetValue("TX1_VLDISS"), nDecs), oMdlTX1:GetValue("TX1_PRODUT"), cCodTes})
				EndIf
			
			Next nX
			
			If lRet
				aNumPed := A933GerPD(aPedido)
				
				If !Empty(aNumPed)
					For nX := 1 to nTamTX1
						oMdlTX1:Goline(nX)
						nPos := aScan( aNumPed, { |x| x[01] == oMdlTX1:GetValue("TX1_LOCAL") .AND.  x[03] == oMdlTX1:GetValue("TX1_XCDISS") })
						
						If nPos > 0
							oMdlTX1:SetValue("TX1_PEDIDO", aNumPed[nPos][2])
						Else
							lRet := .F.
							Help(" ",1,"A933NOPED", , STR0016, 3, 1 )// "Pedido de venda não foi Gerado"
							Exit
						EndIf
					Next nX
				Else
					lRet := .T.
				EndIf
			EndIf 
		Else
			DbSelectArea("SC5")
			SC5->(DbSetOrder(1))

			For nX := 1 to nTamTX1
				oMdlTX1:Goline(nX)
			
				If lA933EstPed
					lCont := ExecBlock("A933EstPed",.F.,.F.,{cContrato,cRevCtr,oMdlTX1:GetValue("TX1_PEDIDO")})
				EndIf

				If lCont.and. SC5->(dbSeek(xFilial("SC5")+oMdlTX1:GetValue("TX1_PEDIDO")))
								
					Reclock("SC5", .F.)
						SC5->C5_MDCONTR	:= ""
						SC5->C5_MDPLANI := ""
					MsUnLock()
					
					lMsErroAuto := .F.
					MSExecAuto({|x,y,z| Mata410(x,y,z)},{{"C5_NUM",oMdlTX1:GetValue("TX1_PEDIDO"),NIL}},{},5)

					If lMsErroAuto
						If Empty(NomeAutoLog()) .OR. Empty(MemoRead(NomeAutoLog()))
							Help(,,'A933EXCLPED',,STR0017,1,0)//"Não foi possivel excluir pedido de venda"
						Else
							MostraErro()
						EndIf
						lRet := .F.		
						Exit
					Else
						lRet := .T.
					Endif	

				EndIf
				
			Next nX
		EndIf
		
		
		If lRet .and. oModel:VldData()
			lRet := FWFormCommit( oModel )
		Else
			DisarmTransacation()
		EndIf
		
		
	End Transaction

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} A933GetCl
@description	Busca cliente para geração do pedido de venda
@sample	 		A933GetCl()
@author 		Pâmela Bernardo
@since 			17/05/2018
@version 		1.0
/*/
//------------------------------------------------------------------------------
Function A933GetCl(cContrato, cRevCtr, cCodLocal,cCodCli,cLoja, cPlan)
	Local cChave := Posicione("T42",2,xFilial("T42")+cContrato+cRevCtr,"T42_CHAVE")
	
	Default cCodCli := ""
	Default cLoja 	:= ""
	Default cPlan 	:= ""
	
	DbSelectArea("TWW")
	TWW->(DbSetOrder(2))
	
	If TWW->(dbSeek(xFilial("TWW")+cChave+cCodLocal))
		cCodCli := TWW->TWW_CLIERH
		cLoja 	:= TWW->TWW_LOJARH
		cPlan	:= TWW->TWW_PLANRH
	Else
		cCodCli := ""
		cLoja 	:= ""
		cPlan	:= ""
	EndIf

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} A933GerPD
@description	Busca cliente para geração do pedido de venda
@sample	 		A933GerPD()
@author 		Pâmela Bernardo
@since 			17/05/2018
@version 		1.0
/*/
//------------------------------------------------------------------------------
Static Function A933GerPD(aPedido)
	Local aNumPed 	:= {}
	Local nX		:= 0
	Local nJ		:= 0
	Local aCabec	:= {}
	Local aItens	:= {}
	Local aItem 	:= {}
	Local lA933Ped	:=  ExistBlock("A933Ped")//ponto de entrada para complemento de pedido	
	Local cItem := ""
	
	For nX := 1 to len(aPedido)
	
		aCabec:= {}
		aItens := {}
			
		aAdd( aCabec, { "C5_FILIAL"  	, xFilial("SC5") 		, Nil } )
		aAdd( aCabec, { "C5_TIPO"    	, 'N'		   			, Nil } )
		aAdd( aCabec, { "C5_CLIENTE" 	, aPedido[nX][2]		, Nil } )
		aAdd( aCabec, { "C5_LOJACLI" 	, aPedido[nX][3]		, Nil } )
		aAdd( aCabec, { "C5_CONDPAG" 	, aPedido[nX][7]		, Nil } )
		aAdd( aCabec, { "C5_ORIGEM"		, 'TECA933'				, Nil } )
		aAdd( aCabec, {"C5_RECISS"		, aPedido[nX][10]		, Nil } )
		aAdd( aCabec, {	"C5_ESTPRES"	, aPedido[nX][11]		, Nil } )
		aAdd( aCabec, {	"C5_MUNPRES"	, aPedido[nX][12]		, Nil } )

		cItem := Replicate("0", SC6->(TamSx3("C6_ITEM")[1] ) )	
		For nJ := 1 to Len(aPedido[nX][4]) 
				aItem := {}
				
				cItem := Soma1(cItem)
					
				AAdd( aItem, { "C6_FILIAL"	, xFilial("SC6") 						, NIL})
				AAdd( aItem, { "C6_ITEM"	, cItem									, NIL})
				AAdd( aItem, { "C6_PRODUTO"	, aPedido[nX][4][nJ][2]   				, NIL})
				AAdd( aItem, { "C6_QTDVEN"	, 1                                 	, NIL})
				AAdd( aItem, { "C6_PRCVEN"	, aPedido[nX][4][nJ][1]            		, NIL})
				AAdd( aItem, { "C6_PRUNIT"	, aPedido[nX][4][nJ][1]            		, NIL})
				AAdd( aItem, { "C6_VALOR"	, aPedido[nX][4][nJ][1]            		, NIL})
				AAdd( aItem, { "C6_TES"		, aPedido[nX][4][nJ][3] 				, NIL})
						    
				AAdd(aItens, aItem)
		Next nJ
		
		
		If lA933Ped
			ExecBlock("A933Ped",.F.,.F.,{aPedido[nX][5],aPedido[nX][8],aPedido[nX][6], aCabec, aItens})
		EndIf
		lMsErroAuto := .F.
		MsExecAuto({|x,y,z| MATA410(x,y,z)},aCabec,aItens,3 )
		
		If lMsErroAuto
			MostraErro()
			aNumPed := {}
			Exit
		Else 
			AAdd( aNumPed, { aPedido[nX][1]	, SC5->C5_NUM, aPedido[nX][9]})
			Reclock("SC5", .F.)
				SC5->C5_MDCONTR	:= aPedido[nX][5]
				SC5->C5_MDPLANI := aPedido[nX][6]
			MsUnLock()
		EndIf
		
	Next nX
	
Return aNumPed


/*/{Protheus.doc}A933ILote
@description      Abre interface de processamento em Lote - Inclusão
@author           Pâmela Bernardo
@since                  19.04.2017
/*/
Function A933ILote()
Local aButtons    := {  {.F.,Nil},;             //- Copiar
                                         {.F.,Nil},;             //- Recortar
                                         {.F.,Nil},;             //- Colar
                                         {.F.,Nil},;             //- Calculadora
                                         {.F.,Nil},;             //- Spool
                                         {.F.,Nil},;             //- Imprimir
                                         {.T.,STR0019},;     	//- "Confirmar"
                                         {.T.,STR0020},;   		//- "Cancelar"
                                         {.F.,Nil},;             //- WalkThrough
                                         {.F.,Nil},;             //- Ambiente
                                         {.F.,Nil},;             //- Mashup
                                         {.F.,Nil},;             //- Help
                                         {.F.,Nil},;             //- Formulário HTML
                                         {.F.,Nil};                   //- ECM
                                   }

FWExecView(STR0021,"VIEWDEF.TECA933A",MODEL_OPERATION_INSERT,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,30,aButtons)//"Fat Dissídio Lote"

Return

/*/{Protheus.doc}A933ELote
@description      Abre interface de processamento em Lote - Inclusão
@author           Pâmela Bernardo
@since            21.05.2018
/*/
Function A933ELote()
Local aButtons    := {  {.F.,Nil},;             //- Copiar
                                         {.F.,Nil},;             //- Recortar
                                         {.F.,Nil},;             //- Colar
                                         {.F.,Nil},;             //- Calculadora
                                         {.F.,Nil},;             //- Spool
                                         {.F.,Nil},;             //- Imprimir
                                         {.T.,STR0019},;     //- "Confirmar"
                                         {.T.,STR0020},;   	//- "Cancelar"
                                         {.F.,Nil},;             //- WalkThrough
                                         {.F.,Nil},;             //- Ambiente
                                         {.F.,Nil},;             //- Mashup
                                         {.F.,Nil},;             //- Help
                                         {.F.,Nil},;             //- Formulário HTML
                                         {.F.,Nil};                   //- ECM
                                   }

FWExecView(STR0022,"VIEWDEF.TECA933A",MODEL_OPERATION_INSERT,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,30,aButtons)//"Est. Fat. Dissídio"

Return

/*/{Protheus.doc}A933VlDt
@description      Validação de data
@author           Pâmela Bernardo
@since            21.05.2018
/*/
Function A933VlDt()

Local lRet 		:= .T.
Local aSave		:= FWSaveRows()
Local oMdl		:= FwModelActive()
Local oMdlTX0	:= oMdl:GetModel("TX0MASTER")
Local oMdlTX1	:= oMdl:GetModel("TX1DETAIL")
Local dDtIni	:= FirstDay(oMdlTX0:GetValue("TX0_DATA"))
Local dDtFim	:= LastDay(oMdlTX0:GetValue("TX0_DATA"))
Local cContrato	:= oMdlTX0:GetValue("TX0_CONTRT")
Local cRevCtr	:= oMdlTX0:GetValue("TX0_REVISA")
Local cAliasQry	:= GetNextAlias()
Local cMes		:= STR(MONTH(dDtIni))

BeginSql Alias cAliasQry
			
	SELECT MAX (TX0_CODIGO)  TX0_CODIGO
	 	FROM %table:TX0% TX0
	 	WHERE TX0.TX0_FILIAL = %xFilial:TX0%
			 	AND TX0_CONTRT = %Exp:cContrato%
			 	AND TX0_DATA >= %Exp:dDtIni% AND  TX0_DATA <= %Exp:dDtFim% 
			   	AND TX0.%NotDel%
EndSql

If (cAliasQry)->(!Eof()) .and. !Empty((cAliasQry)->(TX0_CODIGO))
	lRet 		:= .F.
	Help(NIL, NIL, "A933NOINC", NIL, STR0023 + cMes+ STR0024, 1, 0, NIL, NIL, NIL, NIL, NIL, {STR0025+(cAliasQry)->(TX0_CODIGO)}) //"Periodo do mês "##" foi faturado "##"Estorne faturamento "
EndIf

(cAliasQry)->(DbCloseArea())
FWRestRows(aSave)

Return lRet


/*/{Protheus.doc}A933InPad
@description      Inicilizador Padrão
@author           Pâmela Bernardo
@since            21.05.2018
/*/
Function A933InPad(cCampo)
	Local cRet 	:= ""
	Local lInclui := IsInCallStack("A933Incl")
	
	If !lInclui
		If cCampo == "TX0_XDESCL"
			cRet := POSICIONE('SA1',1,XFILIAL('SA1')+ TX0->TX0_CLIENT+TX0->TX0_LOJA,'A1_NOME') 
		EndIf
		
		If cCampo == "TX1_XDESLO"
			cRet := POSICIONE("ABS",1,xFilial("ABS")+TX1->TX1_LOCAL,"ABS_MUNIC")
		Endif
		
		
		If cCampo == "TX1_XMUNIC"
			If xFilial("ABS")+TX1->TX1_LOCAL <> ABS->(ABS_FILIAL + ABS_LOCAL)
				cRet := POSICIONE("ABS",1,xFilial("ABS")+TX1->TX1_LOCAL,"ABS_DESCRI")
			Else
				cRet := ABS->ABS_DESCRI
			EndIf
		Endif

		If cCampo == "TX1_XRCISS"
			If xFilial("ABS")+TX1->TX1_LOCAL <> ABS->(ABS_FILIAL + ABS_LOCAL)
				cRet := POSICIONE("ABS",1,xFilial("ABS")+TX1->TX1_LOCAL,"ABS_RECISS")
			Else
				cRet := ABS->ABS_RECISS
			EndIf
		Endif
		If cCampo == "TX1_XCDNUM"
			If xFilial("ABS")+TX1->TX1_LOCAL <> ABS->(ABS_FILIAL + ABS_LOCAL)
				cRet := POSICIONE("ABS",1,xFilial("ABS")+TX1->TX1_LOCAL,"ABS_CODMUN")
			Else
				cRet := ABS->ABS_CODMUN
			EndIf
		Endif
		
			
		If cCampo == "TX1_XESTAD"
			If xFilial("ABS")+TX1->TX1_LOCAL <> ABS->(ABS_FILIAL + ABS_LOCAL)
				cRet := POSICIONE("ABS",1,xFilial("ABS")+TX1->TX1_LOCAL,"ABS_ESTADO")
			Else
				cRet := ABS->ABS_ESTADO
			EndIf
		Endif
		If cCampo == "TX1_XDESPR"
			cRet := POSICIONE("SB1",1,xFilial("SB1")+TX1->TX1_PRODUT,"B1_DESC")
		Endif
		
		If cCampo == "TX1_XCDISS"
			If xFilial("SB1")+TX1->TX1_PRODUT <> SB1->(B1_FILIAL + B1_COD)
				cRet := POSICIONE("SB1",1,xFilial("SB1")+TX1->TX1_PRODUT,"B1_CODISS")
			Else
				cRet := SB1->B1_CODISS
			EndIf
		Endif
	EndIf

Return cRet


/*/{Protheus.doc}A933Incl
@description      Abre interface de processamento em Lote - Inclusão
@author           Pâmela Bernardo
@since            21.05.2018
/*/
Function A933Incl()

	FWExecView(STR0001,"VIEWDEF.TECA933",MODEL_OPERATION_INSERT, /*oDlg*/, {|| .T. } ,/*bOk*/ , /*nPercReducao*/, /*aEnableButtons*/, /*bCancel*/ , /*cOperatId*/, /*cToolBar*/)//"Fat Dissídio"
 
Return


