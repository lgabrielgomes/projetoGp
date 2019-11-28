#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH" 
#INCLUDE "GPEA061.CH"

STATIC _CENTGPE_

//------------------------------------------------------------------------------
/*/{Protheus.doc} AT352ASA1()

Vinculo de beneficios

@sample 	AT352AABS() 
@param		ExpC1 Entidade
@return	ExpL	Verdadeiro / Falso
@since		04/05/2015       
@version	P12   
/*/
//------------------------------------------------------------------------------
Function AT352AABS()

Local cCodCri

_CENTGPE_ := 'ABS' 
cCodCri 	:= fRetCriter(,_CENTGPE_)	// Retorna o codigo do criterio ativo
DbSelectArea("SJS")
SJS->(DbSetOrder(1)) //JS_FILIAL, JS_CDAGRUP, JS_TABELA, JS_SEQ
SJS->(DbSeek(xFilial("SJS")+cCodCri+_CENTGPE_))

FWExecView(STR0002,"VIEWDEF.TECA352A", MODEL_OPERATION_UPDATE, /*oDlg*/, {||.T.} /*bCloseOk*/, {||.T.}/*bOk*/,/*nPercRed*/,/*aButtons*/, {||.T.}/*bCancel*/ ) //"Beneficios"

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} AT352ASA1()

Vinculo de beneficios

@sample 	AT352ASA1() 
@param		ExpC1 Entidade
@return	ExpL	Verdadeiro / Falso
@since		04/05/2015       
@version	P12   
/*/
//------------------------------------------------------------------------------
Function AT352ASA1()

Local cCodCri

_CENTGPE_ := 'SA1' 

cCodCri  	:= fRetCriter(,_CENTGPE_)	// Retorna o codigo do criterio ativo

DbSelectArea("SJS")
SJS->(DbSetOrder(1)) //JS_FILIAL, JS_CDAGRUP, JS_TABELA, JS_SEQ
SJS->(DbSeek(xFilial("SJS")+cCodCri+_CENTGPE_))

FWExecView(STR0002,"VIEWDEF.TECA352A", MODEL_OPERATION_UPDATE, /*oDlg*/, {||.T.} /*bCloseOk*/, {||.T.}/*bOk*/,/*nPercRed*/,/*aButtons*/, {||.T.}/*bCancel*/ ) //"Benefícios"

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef()
Model - Vindulo de Beneficios

@Return 	nil
@author	Serviços
@since 		03/07/2014
@history 07/11/2016, Cícero Alves, Retirado o inicializador padrão dos campos LY_DESBEN e LY_DESCTIP
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ModelDef()

Local oModel   := fwloadModel("GPEA061")
Local bLoadTMP := { |oModel| At352AFIL(1, cCodCri, cSeqAtu, '', oModel ) }
Local bLoadSLY := { |oModel| At352AFIL(2, cCodCri, cSeqAtu, cChavEnt, oModel ) }
Local oStruSJS := FWFormModelStruct():New()
Local oStruTMP := FWFormStruct(1,"SLY")
Local oStruSLY := oModel:GetModel("GPEA061_SLY"):getstruct()//FWFormStruct(1,"SLY")
Local cCodCri  := fRetCriter(,_CENTGPE_)	// Retorna o codigo do criterio ativo
Local cChavEnt := Space(TAMSX3("LY_CHVENT")[1])	// Chave do Beneficio
Local cSeqAtu  := Space(TAMSX3("JS_SEQ")[1])		// Sequencia da Criterio da Entidade
If VALTYPE(_CENTGPE_) == "U"
	_CENTGPE_ := "SA1"
EndIf
// Carrega a Chave
cChavEnt := IIF(_CENTGPE_ == 'SA1', SA1->A1_COD + SA1->A1_LOJA, ABS->ABS_LOCAL)

DbSelectArea("SJS")
SJS->(DbSetOrder(1)) //JS_FILIAL, JS_CDAGRUP, JS_TABELA, JS_SEQ
SJS->(DbSeek(xFilial("SJS")+cCodCri+_CENTGPE_))
cSeqAtu := SJS->JS_SEQ

// Carrega estrutura da entidade
oStruSJS:AddTable("ZZZ",{},STR0003) // "Entidades"
At352AStru( .F., oStruSJS, "ZZZ", .T. )

// Legenda Vistoria Tecnica        
oStruTMP:AddField(	AllTrim("")			,;  	// [01] C Titulo do campo
						AllTrim(STR0003)		,;   	// [02] C ToolTip do campo "Legenda"
						"LY_LEGEND" 			,;    	// [03] C identificador (ID) do Field
						"C" 					,;    	// [04] C Tipo do campo
						15 						,;    	// [05] N Tamanho do campo
						0 						,;    	// [06] N Decimal do campo
						Nil 					,;    	// [07] B Code-block de validação do campo
						Nil						,;    	// [08] B Code-block de validação When do campo
						Nil 					,;    	// [09] A Lista de valores permitido do campo
                  	Nil 					,;  	// [10] L Indica se o campo tem preenchimento obrigatório
						{|| "BR_VERMELHO"}	,;   	// [11] B Code-block de inicializacao do campo
						Nil 					,;  	// [12] L Indica se trata de um campo chave
						Nil 					,;    	// [13] L Indica se o campo pode receber valor em uma operação de update.
						.T. )              			// [14] L Indica se o campo é virtual
					
// Cria o inicializador padrao dos beneficios (VINCULO)
oStruSLY:SetProperty("LY_FILIAL",MODEL_FIELD_INIT,{||At352ACPL("LY_FILIAL") })
oStruSLY:SetProperty("LY_AGRUP",MODEL_FIELD_INIT,{||At352ACPL("LY_AGRUP") })
oStruSLY:SetProperty("LY_ALIAS",MODEL_FIELD_INIT,{||At352ACPL("LY_ALIAS") })
oStruSLY:SetProperty("LY_CHVENT",MODEL_FIELD_INIT,{||At352ACPL("LY_CHVENT") })
oStruSLY:SetProperty("LY_FILENT",MODEL_FIELD_INIT,{||At352ACPL("LY_FILENT") })

//-- Retira o inicializador padrão dos campos de descrição
oStruTMP:SetProperty("LY_DESBEN" , MODEL_FIELD_INIT, {|| "" })
oStruTMP:SetProperty("LY_DESCTIP", MODEL_FIELD_INIT, {|| "" })

oModel := MPFormModel():New("TECA352A", /*bPreValid*/, /*bTudoOK*/, /*bCommiM040*/, /*bCancel*/ )
oModel:SetDescription(STR0012) // "Beneficios"

oModel:AddFields("SJSMASTER", /*cOwner*/, oStruSJS , /*Pre-Validacao*/,/*Pos-Validacao*/,{||})

//GRIDS - Beneficios Vinculados
oModel:AddGrid("TMPDETAIL", "SJSMASTER" , oStruTMP,/*bLinePre*/, /* bLinePost*/, /*bPre*/,  /*bPost*/,bLoadTMP/*bLoad*/)
oModel:GetModel("TMPDETAIL"):SetDescription(STR0030)// "Beneficios Vinculados"
oModel:GetModel("TMPDETAIL"):SetOptional(.T.)

//GRIDS - Beneficios
oModel:AddGrid("GPEA061_SLY", "SJSMASTER" , oStruSLY,/*bLinePre*/, { |oModel| SLY_LinhaOK(oModel) }/* bLinePost*/, /*bPre*/,  /*bPost*/,bLoadSLY/*bLoad*/)
oModel:GetModel("GPEA061_SLY"):SetDescription(STR0012)// "Beneficios"
oModel:GetModel("GPEA061_SLY"):SetOptional(.T.)

oModel:SetPrimaryKey({})
oModel:SetVldActivate( {|oModel| At352AVld(oModel)} ) 
oModel:SetActivate( {|oModel| InitDados(oModel) } )

Return(oModel)

//-------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
	Definição da interface

@since   	04/05/2015
@version 	P12

/*/
//-------------------------------------------------------------------
Static Function ViewDef()

Local oView   := Nil
Local oModel  := ModelDef()
Local oStruSJS
Local oStruTMP
Local oStruSLY

// Carrega estrutura da Entidade
oStruSJS := FWFormViewStruct():New()
At352AStru( .F., oStruSJS, "ZZZ", .F. )

oStruTMP := FWFormStruct(2, 'SLY', {|cCpo| AllTrim(cCpo)$"LY_TIPO+LY_DESCTIP+LY_CODIGO+LY_DESBEN+LY_PGDUT+LY_PGSAB+LY_PGDOM+LY_PGFER+LY_SUBS+LY_PGFALT+LY_PGAFAS+LY_PGVAC+LY_DIAS+LY_DTINI+LY_DTFIM+LY_PGSUBS" } )
oStruSLY := FWFormStruct(2, 'SLY', {|cCpo| AllTrim(cCpo)$"LY_TIPO+LY_DESCTIP+LY_CODIGO+LY_DESBEN+LY_PGDUT+LY_PGSAB+LY_PGDOM+LY_PGFER+LY_SUBS+LY_PGFALT+LY_PGAFAS+LY_PGVAC+LY_DIAS+LY_DTINI+LY_DTFIM+LY_PGSUBS" } )

// Organiza a Ordem dos campos
oStruSLY:SetProperty("LY_TIPO"		,MVC_VIEW_ORDEM, "01" )
oStruSLY:SetProperty("LY_DESCTIP"	,MVC_VIEW_ORDEM, "02" )
oStruSLY:SetProperty("LY_CODIGO"	,MVC_VIEW_ORDEM, "03" )
oStruSLY:SetProperty("LY_DESBEN"	,MVC_VIEW_ORDEM, "04" )
oStruSLY:SetProperty("LY_PGDUT"		,MVC_VIEW_ORDEM, "05" )
oStruSLY:SetProperty("LY_PGSAB"		,MVC_VIEW_ORDEM, "06" )
oStruSLY:SetProperty("LY_PGDOM"		,MVC_VIEW_ORDEM, "07" )
oStruSLY:SetProperty("LY_PGFER"		,MVC_VIEW_ORDEM, "08" )
oStruSLY:SetProperty("LY_PGSUBS"	,MVC_VIEW_ORDEM, "09" )
oStruSLY:SetProperty("LY_PGFALT"	,MVC_VIEW_ORDEM, "10" )
oStruSLY:SetProperty("LY_PGAFAS"	,MVC_VIEW_ORDEM, "11" )
oStruSLY:SetProperty("LY_PGVAC"		,MVC_VIEW_ORDEM, "12" )
oStruSLY:SetProperty("LY_DIAS"		,MVC_VIEW_ORDEM, "13" )
oStruSLY:SetProperty("LY_DTINI"		,MVC_VIEW_ORDEM, "14" )
oStruSLY:SetProperty("LY_DTFIM"		,MVC_VIEW_ORDEM, "15" )

oStruSLY:SetProperty('LY_TIPO' , MVC_VIEW_CANCHANGE,.t. )
// Legenda Vistoria Tecnica
oStruTMP:AddField(	"LY_LEGEND" 			,;	// [01] C Nome do Campo
						"01" 					,; 	// [02] C Ordem
						AllTrim("")			,; 	// [03] C Titulo do campo
						AllTrim(STR0031)		,; 	// [04] C Descrição do campo "Legenda"
						{STR0031} 	   			,; 	// [05] A Array com Help
						"C" 					,; 	// [06] C Tipo do campo
						"@BMP" 				,; 	// [07] C Picture
						Nil 					,; 	// [08] B Bloco de Picture Var
						"" 						,; 	// [09] C Consulta F3
						.F. 					,;	// [10] L Indica se o campo é evitável
                  	Nil 					,; 	// [11] C Pasta do campo
                   	Nil 					,;	// [12] C Agrupamento do campo
						Nil 					,; 	// [13] A Lista de valores permitido do campo (Combo)
						Nil 					,;	// [14] N Tamanho Maximo da maior opção do combo
						Nil 					,;	// [15] C Inicializador de Browse
						.T. 					,;	// [16] L Indica se o campo é virtual
						Nil )               		// [17] C Picture Variável 
                    
oStruSLY:RemoveField("LY_DESC")	
oView := FWFormView():New()

oView:SetModel(oModel)

oView:AddField('VIEW_SJS', oStruSJS, 'SJSMASTER')
oView:AddGrid('VIEW_TMP' , oStruTMP, 'TMPDETAIL')
oView:AddGrid('VIEW_SLY' , oStruSLY, 'GPEA061_SLY')

//Legenda
oView:AddUserButton(STR0031,"",{ || At352ALeg()}) //"Legenda"

// Adiciona as visões na tela
oView:CreateHorizontalBox( 'TOP'   , 20 )
oView:CreateHorizontalBox( 'MIDDLE', 40 )
oView:CreateHorizontalBox( 'DOWN'  , 40 )

// Faz a amarração das VIEWs dos modelos com as divisões na interface
oView:SetOwnerView('VIEW_SJS', 'TOP'    )
oView:SetOwnerView('VIEW_TMP', 'MIDDLE')
oView:SetOwnerView('VIEW_SLY', 'DOWN')

oView:EnableTitleView( "VIEW_TMP", STR0032 )	// "Benefícios Superiores"
oView:EnableTitleView( "VIEW_SLY", STR0030 ) 	// "Benefícios Vinculados"

Return oView

//------------------------------------------------------------------------------
/*/{Protheus.doc} Menudef
	Criacao do MenuDef.

@sample 	Menudef() 
@param		Nenhum
@return	 	aMenu, Array, Opção para seleção no Menu
@since		04/05/2015       
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function Menudef()

Local aRotina := {}

ADD OPTION aRotina TITLE STR0006 ACTION 'PesqBrw'        OPERATION 1 ACCESS 0	// "Pesquisar"
ADD OPTION aRotina TITLE STR0033 ACTION 'VIEWDEF.TECA352A' OPERATION 4 ACCESS 0	// "Alterar"

Return (aRotina)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At352AStru
Carrega as estruturas para os grids da alocação

@sample 	At352AStru( oStruct, cTipo, lView )

@param		oStruct - Estrutura a ser alterada com os novos campos
@param		oPanel - Painel onde deverá ser criado e exibido o botão
@param		oPanel - Painel onde deverá ser criado e exibido o botão
	
@return	Nil 
@author	Serviços
@since		05/05/2015       
@version	P12   admin	
/*/
//------------------------------------------------------------------------------
Static Function At352AStru( lEstr, oStruct, cTipo, lModel )
 
Local aCols := {}

Local nI, xRet

Default oStruct := Nil
Default lModel  := .T.

If lEstr

	xRet := {}	
	For nI:=1 To 1
		aAdd( aCols, Nil )
	Next nI	
	aAdd( xRet, { 1, aCols } )
		 
Else 

	If lModel
		
		/* Estutura para a criação de campos no model
	
			[01] C Titulo do campo
			[02] C ToolTip do campo
			[03] C identificador (ID) do Field
			[04] C Tipo do campo
			[05] N Tamanho do campo
			[06] N Decimal do campo
			[07] B Code-block de validação do campo
			[08] B Code-block de validação When do campo
			[09] A Lista de valores permitido do campo
			[10] L Indica se o campo tem preenchimento obrigatório
			[11] B Code-block de inicializacao do campo
			[12] L Indica se trata de um campo chave
			[13] L Indica se o campo pode receber valor em uma operação de update.
			[14] L Indica se o campo é virtual
	                    	
		*/  
	
		If cTipo == "ZZZ"
			oStruct:AddField( STR0020, STR0020, "ZZZ_ENTID", "C", 30, 0, Nil, Nil, Nil, Nil,;  // "Entidade"
								Nil, Nil, .F., .T. )
		EndIf	                    		
	Else
	
		/* Estutura para a criação de campos na view	
		
			[01] C Nome do Campo
			[02] C Ordem
			[03] C Titulo do campo  
			[04] C Descrição do campo  
			[05] A Array com Help
			[06] C Tipo do campo
			[07] C Picture
			[08] B Bloco de Picture Var
			[09] C Consulta F3
			[10] L Indica se o campo é editável
			[11] C Pasta do campo
			[12] C Agrupamento do campo
			[13] A Lista de valores permitido do campo (Combo)
			[14] N Tamanho Maximo da maior opção do combo
			[15] C Inicializador de Browse
			[16] L Indica se o campo é virtual
			[17] C Picture Variável
	
		*/
	
		If cTipo == "ZZZ"
			oStruct:AddField( "ZZZ_ENTID", "01", STR0020, STR0020, Nil, "C", "", NIL, "", .F.,;	// "Entidade" 
								NIL	, NIL, Nil, NIL, NIL, .T., NIL )									
		EndIf
		
	EndIf	
		
EndIf	
	
Return(xRet)

/*/{Protheus.doc} At352AVld
Pre validação para a ativação do model

@since 05/05/2015
@version 12
@param oModel, objeto, Model
@return lRet

/*/
Static Function At352AVld(oModel)

Local lRet    := .T.
Local lTecxRh := SuperGetMV("MV_TECXRH",,.F.)	// Define se o Gestao de Servico esta integrado com Rh do Microsiga Protheus.
Local cCodCri := fRetCriter(,_CENTGPE_)		// Retorna o codigo do criterio ativo

IF !lTecxRh
	Help(,,'TECA352A',,STR0034,1,0)//"O parâmetro de sistema de integração com o módulo de RH (MV_TECXRH) deverá estar habilitado."
	lRet := .F.
ENDIF

IF lRet .AND. Empty(cCodCri)
	Help(,,'TECA352A',,STR0035,1,0)//"Não existe um critério de benefícios ativo no módulo SIGAGPE."
	lRet := .F.
ENDIF

IF lRet
	DbSelectArea("SJS")
	SJS->(DbSetOrder(1)) //JS_FILIAL, JS_CDAGRUP, JS_TABELA, JS_SEQ
	IF !SJS->(DbSeek(xFilial("SJS")+cCodCri+_CENTGPE_))
	   Help(,,'TECA352A',, I18N( STR0020 + ' #1 ' + STR0036,{_CENTGPE_}),1,0) //'Entidade #1[Entidade]# não cadastrada no sequenciamento de critério de benefícios do módulo SIGAGPE.'
		lRet := .F.	
	ENDIF
ENDIF

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} InitDados()
Inicializa as informações da visualização da escala

@sample 	InitDados()

@param  	oModel, Objeto, objeto geral do model que será alterado

@author 	Serviços
@since 		09/06/2014
@history 26/10/2016, Cícero Alves, TVYVMK - Ajuste para não carregar as descrições quando não tem nenhum registro
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function InitDados(oModel)

Local oMdlSJS := oModel:GetModel("SJSMASTER")
Local oMdlTMP := oModel:GetModel("TMPDETAIL")
Local oMdlSLY := oModel:GetModel("GPEA061_SLY")
Local nI      := 0

// Cabecalho da alocacao 
oMdlSJS:SetValue( "ZZZ_ENTID", IIF(_CENTGPE_ == 'SA1',STR0037,STR0038)) //"CLIENTE"#"LOCAL DE ATENDIMENTO"
oMdlSJS:SetOnlyQuery(.T.)

// Atualiza a legenda dos beneficios e campos obrigatorios
FOR nI := 1 To oMdlTMP:Length()
	oMdlTMP:GoLine(nI)
	DO CASE
		CASE oMdlTMP:GetValue("LY_ALIAS") == 'SM0'
			oMdlTMP:LoadValue( "LY_LEGEND"	, "BR_VERMELHO" )
		CASE oMdlTMP:GetValue("LY_ALIAS") == 'SA1'
			oMdlTMP:LoadValue( "LY_LEGEND"	, "BR_VERDE" )
	ENDCASE
	
	If ! Empty(oMdlTMP:GetValue("LY_CODIGO"))
		oMdlTMP:LoadValue("LY_DESBEN" , fInitBen(oMdlTMP))
		oMdlTMP:LoadValue("LY_DESCTIP", fInitTip(oMdlTMP))
	EndIf
	
NEXT nI

FOR nI := 1 To oMdlSLY:Length()
	
	oMdlSLY:GoLine(nI)
	
	If ! Empty(oMdlSLY:GetValue("LY_CODIGO"))
		oMdlSLY:SetValue("LY_DESBEN" , fInitBen(oMdlSLY))
		oMdlSLY:SetValue("LY_DESCTIP", fInitTip(oMdlSLY))
	EndIf
	
Next nI

// Beneficios Superior somente para visualizacao
oMdlTMP:SetNoInsertLine(.T.)
oMdlTMP:SetNoUpdateLine(.T.)
oMdlTMP:SetNoDeleteLine(.T.)


Return(Nil)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At352AFIL
Retorna a lista de beneficios

@sample 	At352AFIL( nTipo, cCdAgrup, cSeqCri, cChvCri )

@param		nTipo		- Tipo da Sequencia
@param		cCdAgrup	- Codigo do Agrupamento
@param		cSeqCri	- Sequencia Atual da Entidade
@param		cChvCri	- Chave da Entidade
	
@return	aRet - Array com as informacoes dos beneficios
 
@author	Serviços
@since		06/05/2015       
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At352AFIL( nTipo, cCdAgrup, cSeqCri, cChvCri, oMdl )

Local aRet 	  := {}
Local aBenef    := {}
Local cAliasSLY := GetNextAlias()
Local cTabela   := _CENTGPE_

IF nTipo = 1 // Sequencia Superior

	// Filtra os Beneficios da Sequencia Superior
	BeginSql Alias cAliasSLY
		COLUMN LY_DTINI AS DATE
		COLUMN LY_DTFIM AS DATE
		SELECT	*
		FROM %table:SLY% SLY 
		JOIN %table:SJS% SJS ON
			SJS.JS_FILIAL = %xFilial:SJS% AND 
			SJS.JS_CDAGRUP = %Exp:cCdAgrup% AND
			SJS.JS_TABELA = SLY.LY_ALIAS AND
			SJS.JS_SEQ < %Exp:cSeqCri% AND
			SJS.%NotDel%
		WHERE 
			SLY.LY_FILIAL = %xFilial:SLY% AND 
			SLY.LY_AGRUP = %Exp:cCdAgrup% AND
			SLY.%NotDel%
		ORDER BY 
			SJS.JS_SEQ
 	EndSql
ELSE
	// Filtra os Beneficios da Sequencia Atual
	BeginSql Alias cAliasSLY
		COLUMN LY_DTINI AS DATE
		COLUMN LY_DTFIM AS DATE
		SELECT	*
		FROM %table:SLY% SLY 
		JOIN %table:SJS% SJS ON
			SJS.JS_FILIAL = %xFilial:SJS% AND 
			SJS.JS_CDAGRUP = %Exp:cCdAgrup% AND
			SJS.JS_SEQ = %Exp:cSeqCri% AND
			SJS.JS_TABELA = %Exp:cTabela% AND
			SJS.%NotDel%
		WHERE 
			SLY.LY_FILIAL = %xFilial:SLY% AND 
			SLY.LY_AGRUP = %Exp:cCdAgrup% AND
			SLY.LY_ALIAS = %Exp:cTabela% AND
			SLY.LY_CHVENT = %Exp:cChvCri% AND
			SLY.%NotDel%
		ORDER BY 
			LY_ALIAS
 	EndSql
ENDIF

aBenef := FwLoadByAlias( oMdl, cAliasSLY )

DbSelectArea(cAliasSLY)
(cAliasSLY)->(DbCloseArea())

Return aBenef 

//------------------------------------------------------------------------------
/*/{Protheus.doc} At352ALEG
Legenda

@sample 	At352ALEG()
@author	Serviços
@since		08/05/2015       
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At352ALeg()

Local oLegenda  :=  FWLegend():New()

oLegenda:Add("","BR_VERMELHO"	,STR0039)	// "Filial"

IF _CENTGPE_ <> 'SA1'
	oLegenda:Add("","BR_VERDE"		,STR0040)	// "Cliente"
ENDIF

oLegenda:Activate()
oLegenda:View()
oLegenda:DeActivate()

Return Nil

Static Function At352ACPL(cCampo)

Local cCodCri := fRetCriter(,_CENTGPE_)
Local cCodEnt := ''
Local cFilEnt := ''
Local cRet    := ''

IF _CENTGPE_ == 'SA1'
	cFilEnt := xFilial("SA1")
	cCodEnt := SA1->A1_COD + SA1->A1_LOJA
ELSE
	cFilEnt := xFilial("ABS")
	cCodEnt := ABS->ABS_LOCAL
ENDIF

DO CASE
	CASE cCampo == "LY_FILIAL"
		cRet := xFilial("SLY")
	CASE cCampo == "LY_AGRUP"
		cRet := cCodCri
	CASE cCampo == "LY_ALIAS"
		cRet := _CENTGPE_
	CASE cCampo == "LY_FILENT"
		cRet := cFilEnt	
	CASE cCampo == "LY_CHVENT"
		cRet := cCodEnt
ENDCASE

RETURN cRet

