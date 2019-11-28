#INCLUDE 'TECA740.CH'
#INCLUDE 'PROTHEUS.CH' 
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'LOCACAO.CH' 

STATIC oCharge		:= Nil
STATIC lDoCommit	:= .F.
STATIC cXmlDados	:= ''
STATIC cXmlCalculo	:= ''
STATIC aCancReserv	:= {}
STATIC nTLuc		:= 0
STATIC nTAdm		:= 0
STATIC aObriga		:= {} 
STATIC lTotLoc		:= .F.
STATIC lDelTWO		:= .F.
STATIC lUnDel		:= .F.
STATIC aPlanData 	:= {}
STATIC cOperation 	:= NIL
Static _lGSVinc 	:= NIL

Static lSigaMdtGS:= SuperGetMv("MV_NG2GS",.F.,.F.)	//Parâmetro de integração entre o SIGAMDT x SIGATEC

//------------------------------------------------------------------------------
/*/{Protheus.doc} TECA740
Nova interface para orçamento de serviços

@sample 	TECA740() 

@since		20/08/2013       
@version	P11   
/*/
//------------------------------------------------------------------------------
Function TECA740()

Local oBrw := FwMBrowse():New()

oBrw:SetAlias( 'TFJ' )
oBrw:SetMenudef( 'TECA740' )
oBrw:SetDescription( OEmToAnsi( STR0001 ) ) //'Orçamento para Serviços' 
oBrw:Activate()

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} Menudef
	Criacao do MenuDef.

@sample 	Menudef() 
@param		Nenhum
@return	 	aMenu, Array, Opção para seleção no Menu
@since		20/00/2013       
@version	P11   
/*/
//------------------------------------------------------------------------------
Static Function Menudef()

Local aRotina := {}

ADD OPTION aRotina TITLE STR0002 ACTION 'PesqBrw'         OPERATION 1 ACCESS 0	// "Pesquisar"
ADD OPTION aRotina TITLE STR0003 ACTION 'VIEWDEF.TECA740' OPERATION 2 ACCESS 0	// "Visualizar"

Return (aRotina)


//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
	Definição do modelo de Dados

@since 10/09/2013
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function ModelDef()
Local oModel := Nil
Local oMdlCalc := Nil
Local oStrTFJ := FWFormStruct(1,'TFJ')
Local oStrTFL := FWFormStruct(1,'TFL')
Local oStrTFF := FWFormStruct(1,'TFF')
Local oStrTFG := FWFormStruct(1,'TFG')
Local oStrTFH := FWFormStruct(1,'TFH')
Local oStrTFI := FWFormStruct(1,'TFI')
Local oStrTFU := FWFormStruct(1,'TFU')
Local oStrABP := FWFormStruct(1,'ABP')
Local oStrTEV := FWFormStruct(1,'TEV')
Local xAux    := Nil
//referente fonte TECA741 - Habilidades, Características e Cursos para o item de RH
Local oStrTGV := FWFormStruct(1,'TGV')
Local oStrTDS := FWFormStruct(1,'TDS')
Local oStrTDT := FWFormStruct(1,'TDT')
//Referente aos intes do Facilitador
Local oStrTWO	:= FwFormStruct(1,'TWO')
Local xVal		:= ""					//5º parametro do Prelin - é o valor que está sendo atribuido
Local xValAtu	:= ""					//6º parametro do Prelin - é o valor que está atualmente no campo.

_lGSVinc := SuperGetMV("MV_GSVINC",, .F.)

oStrTFG:AddField(	STR0153,;									// 	[01]  C   Titulo do campo "Mat. Gravado"
					STR0153,;									// 	[02]  C   ToolTip do campo "Mat. Gravado"
					 "TFG_GRVMAT",;								// 	[03]  C   Id do Field
					 "C",;										// 	[04]  C   Tipo do campo
					 1,;										// 	[05]  N   Tamanho do campo
					 0,;										// 	[06]  N   Decimal do campo
					 NIL,;										// 	[07]  B   Code-block de validação do campo
					 NIL,;										// 	[08]  B   Code-block de validação When do campo
					 {STR0155,STR0156},;						//	[09]  A   Lista de valores permitido do campo '1=Sim'#'2=Não'
					 .F.,;										//	[10]  L   Indica se o campo tem preenchimento obrigatório
					 {|| "1"},;									//	[11]  B   Code-block de inicializacao do campo
					 NIL,;										//	[12]  L   Indica se trata-se de um campo chave
					 .T.,;										//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
					 .T.)										// 	[14]  L   Indica se o campo é virtual

oStrTFH:AddField(	STR0153,;									// 	[01]  C   Titulo do campo "Mat. Gravado"
					STR0153,;									// 	[02]  C   ToolTip do campo "Mat. Gravado"
					 "TFH_GRVMAT",;								// 	[03]  C   Id do Field
					 "C",;										// 	[04]  C   Tipo do campo
					 1,;										// 	[05]  N   Tamanho do campo
					 0,;										// 	[06]  N   Decimal do campo
					 NIL,;										// 	[07]  B   Code-block de validação do campo
					 NIL,;										// 	[08]  B   Code-block de validação When do campo
					 {STR0155,STR0156},;						//	[09]  A   Lista de valores permitido do campo '1=Sim'#'2=Não'
					 .F.,;										//	[10]  L   Indica se o campo tem preenchimento obrigatório
					 {|| "1"},;									//	[11]  B   Code-block de inicializacao do campo
					 NIL,;										//	[12]  L   Indica se trata-se de um campo chave
					 .T.,;										//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
					 .T.)										// 	[14]  L   Indica se o campo é virtual
					 
oStrTFF:AddField(	STR0154,;									// 	[01]  C   Titulo do campo "RH Gravado"
					STR0154,;									// 	[02]  C   ToolTip do campo "RH Gravado"
					 "TFF_GRAVRH",;								// 	[03]  C   Id do Field
					 "C",;										// 	[04]  C   Tipo do campo
					 1,;										// 	[05]  N   Tamanho do campo
					 0,;										// 	[06]  N   Decimal do campo
					 NIL,;										// 	[07]  B   Code-block de validação do campo
					 NIL,;										// 	[08]  B   Code-block de validação When do campo
					 {STR0155,STR0156},;						//	[09]  A   Lista de valores permitido do campo '1=Sim'#'2=Não'
					 .F.,;										//	[10]  L   Indica se o campo tem preenchimento obrigatório
					 {|| "1"},;									//	[11]  B   Code-block de inicializacao do campo
					 NIL,;										//	[12]  L   Indica se trata-se de um campo chave
					 .T.,;										//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
					 .T.)										// 	[14]  L   Indica se o campo é virtual	

//------------------------------------------------------------
//  Não cria os gatilhos para não interferir nos totalizadores e gerar valores de cobrança por fora 
// combinados a cobrança dentro do contrato
//------------------------------------------------------------
If !IsInCallStack("At870GerOrc")
	xAux := FwStruTrigger( 'TFG_TOTGER', 'TFG_TOTGER', 'At740TrgGer( "CALC_TFG", "TOT_MI", "TFF_RH", "TFF_TOTMI" )', .F. )
		oStrTFG:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
	xAux := FwStruTrigger( 'TFH_TOTGER', 'TFH_TOTGER', 'At740TrgGer( "CALC_TFH", "TOT_MC", "TFF_RH", "TFF_TOTMC" )', .F. )
		oStrTFH:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
	xAux := FwStruTrigger( 'TFF_SUBTOT', 'TFF_SUBTOT', 'At740TrgGer( "CALC_TFF", "TOT_RH", "TFL_LOC", "TFL_TOTRH" )', .F. )
		oStrTFF:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
	xAux := FwStruTrigger( 'TFF_TOTMI', 'TFF_TOTMI', 'At740TrgGer( "CALC_TFF", "TOT_RHMI", "TFL_LOC", "TFL_TOTMI" )', .F. )
		oStrTFF:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
	xAux := FwStruTrigger( 'TFF_TOTMC', 'TFF_TOTMC', 'At740TrgGer( "CALC_TFF", "TOT_RHMC", "TFL_LOC", "TFL_TOTMC" )', .F. )
		oStrTFF:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
	xAux := FwStruTrigger( 'TEV_VLTOT', 'TEV_VLTOT', 'At740TrgGer( "CALC_TEV", "TOT_ADICIO", "TFI_LE", "TFI_TOTAL", "TFI_DESCON" )', .F. )
		oStrTEV:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
	xAux := FwStruTrigger( 'TFI_TOTAL', 'TFI_TOTAL', 'At740TrgGer( "CALC_TFI", "TOT_LE", "TFL_LOC", "TFL_TOTLE" )', .F. )
		oStrTFI:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
EndIf	

xAux := FwStruTrigger( 'TFL_TOTRH', 'TFL_TOTRH', 'At740TrgGer( "TOTAIS", "TOT_RH", "TFJ_REFER", "TFJ_TOTRH" )', .F. )
	oStrTFL:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TFL_TOTMI', 'TFL_TOTMI', 'At740TrgGer( "TOTAIS", "TOT_MI", "TFJ_REFER", "TFJ_TOTMI" )', .F. )
	oStrTFL:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TFL_TOTMC', 'TFL_TOTMC', 'At740TrgGer( "TOTAIS", "TOT_MC", "TFJ_REFER", "TFJ_TOTMC" )', .F. )
	oStrTFL:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TFL_TOTLE', 'TFL_TOTLE', 'At740TrgGer( "TOTAIS", "TOT_LE", "TFJ_REFER", "TFJ_TOTLE" )', .F. )
	oStrTFL:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TFI_TOTAL', 'TFI_VALDES', 'At740LeTot( "2" )',.F.) // calcula o valor de desconto
	oStrTFI:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TFI_DESCON', 'TFI_VALDES', 'At740LeTot( "2" )',.F.)  // calcula o valor de desconto
	oStrTFI:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TFI_DESCON', 'TFI_TOTAL', 'At740LeTot( "1" )',.F.)  // calcula o valor total considerando o desconto
	oStrTFI:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
//------------------------------------------------------------
//  Não cria os gatilhos para não interferir nos totalizadores e gerar valores de cobrança por fora 
// combinados a cobrança dentro do contrato
//------------------------------------------------------------
If !IsInCallStack("At870GerOrc")
	xAux := FwStruTrigger( 'TFF_SUBTOT', 'TFF_TOTAL', 'At740InPad()',.F.)
		oStrTFF:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
	xAux := FwStruTrigger( 'TFF_TOTMI', 'TFF_TOTAL', 'At740InPad()',.F.)
		oStrTFF:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
	xAux := FwStruTrigger( 'TFF_TOTMC', 'TFF_TOTAL', 'At740InPad()',.F.)
		oStrTFF:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])		
	xAux := FwStruTrigger( 'TFF_TXLUCR', 'TFF_SUBTOT', 'At740InSub()',.F.)
		oStrTFF:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])	
	xAux := FwStruTrigger( 'TFF_TXADM', 'TFF_SUBTOT', 'At740InSub()',.F.)
		oStrTFF:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
	xAux := FwStruTrigger( 'TFH_DESCON', 'TFH_TOTAL', 'At740CDesc("TFH_MC","TFH_QTDVEN","TFH_PRCVEN","TFH_DESCON","TFH_TOTAL")',.F.)
		oStrTFH:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])	
	xAux := FwStruTrigger( 'TFG_DESCON', 'TFG_TOTAL', 'At740CDesc("TFG_MI","TFG_QTDVEN","TFG_PRCVEN","TFG_DESCON","TFG_TOTAL")',.F.)
		oStrTFG:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
	xAux := FwStruTrigger( 'TFF_DESCON', 'TFF_SUBTOT', 'At740CDesc("TFF_RH","TFF_QTDVEN","TFF_PRCVEN","TFF_DESCON","TFF_SUBTOT")',.F.)
		oStrTFF:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])	
	
	If _lGSVinc

		oStrTFF:SetProperty("TFF_ESCALA", MODEL_FIELD_VALID, {|oModel| At740InMtE(oModel:GetValue("TFF_PRODUT"), oModel:GetValue("TFF_ESCALA")) } )
		oStrTFF:SetProperty("TFF_FUNCAO", MODEL_FIELD_VALID, {|oModel| At740InFun(oModel:GetValue("TFF_PRODUT"), oModel:GetValue("TFF_FUNCAO")) } )
		oStrTFF:SetProperty("TFF_TURNO" , MODEL_FIELD_VALID, {|oModel| At740InTur(oModel:GetValue("TFF_PRODUT"), oModel:GetValue("TFF_TURNO"))  } )
	
		oStrTFG:SetProperty("TFG_PRODUT", MODEL_FIELD_VALID, {|oModel| At740Prod(oModel, oModel:GetValue("TFG_PRODUT"),"4") } )
		oStrTFH:SetProperty("TFH_PRODUT", MODEL_FIELD_VALID, {|oModel| At740Prod(oModel, oModel:GetValue("TFH_PRODUT"),"5") } )
	EndIf
EndIf
xAux := FwStruTrigger( 'TFU_CODABN', 'TFU_ABNDES', 'At740TrgABN()',.F.)	
	oStrTFU:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'ABP_BENEFI', 'ABP_DESCRI', 'At740DeBenefi()',.F.)
	oStrABP:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'ABP_VERBA', 'ABP_DSVERB', 'Posicione("SRV", 1, xFilial("SRV")+M->ABP_VERBA, "RV_DESC" )',.F.)
	oStrABP:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'ABP_VERBA', 'ABP_TPVERB', 'At740TpVerb()',.F.)
	oStrABP:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'ABP_VERBA', 'ABP_VERBA', 'At740totVrb()',.F.)
	oStrABP:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'ABP_VALOR', 'ABP_VALOR', 'At740totVrb()',.F.)
	oStrABP:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TEV_MODCOB', 'TEV_UM', 'At740TrgTEV( "TEV_MODCOB" )',.F.)
	oStrTEV:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TEV_MODCOB', 'TEV_MODCOB', 'At740SmTEV()',.F.)  // atribui zero ao valor unitário sempre que troca o modo de cobrança
	oStrTEV:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
	
xAux := FwStruTrigger( 'TEV_MODCOB', 'TEV_QTDE', 'At740TEVQt()',.F.,/*Alias*/,/*Ordem*/,/*Chave*/,"M->TEV_MODCOB=='2'")
	oStrTEV:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TFI_QTDVEN', 'TFI_QTDVEN', 'At740TEVQt(.T.)',.F.)
	oStrTFI:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TFI_PERINI', 'TFI_PERINI', 'At740TEVQt(.T.)',.F.)
	oStrTFI:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TFI_PERFIM', 'TFI_PERFIM', 'At740TEVQt(.T.)',.F.)
	oStrTFI:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TFI_APUMED', 'TFI_APUMED', 'At740TEVQt(.T.)',.F.)
	oStrTFI:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TFI_PRODUT', 'TFI_PRODUT', 'At740TEVQt(.T.)',.F.)
	oStrTFI:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TFI_ENTEQP', 'TFI_ENTEQP', 'At740TEVQt(.T.)',.F.)
	oStrTFI:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TFI_COLEQP', 'TFI_COLEQP', 'At740TEVQt(.T.)',.F.)
	oStrTFI:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
//----------------------------------------------------------------------------------------	
xAux := FwStruTrigger( 'TFJ_LUCRO', 'TFJ_LUCRO', 'At740LdLuc("1")',.F.)
	oStrTFJ:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TFJ_ADM', 'TFJ_ADM', 'At740LdLuc("2")',.F.)
	oStrTFJ:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
//------------------------------------------------------------------------------------------
// Gatilhos - Recursos Humano
//------------------------------------------------------------------------------------------
xAux := FwStruTrigger( 'TFF_LUCRO', 'TFF_TXLUCR', 'At740RhVlr("1","TFF_RH","TFF")',.F.)
	oStrTFF:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TFF_ADM', 'TFF_TXADM', 'At740RhVlr("2","TFF_RH","TFF")',.F.)
	oStrTFF:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])	
xAux := FwStrutrigger( 'TFF_QTDVEN', 'TFF_TXLUCR', 'At740RhVlr("1","TFF_RH","TFF")',.F.)
	oStrTFF:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])	
xAux := FwStrutrigger( 'TFF_QTDVEN', 'TFF_TXADM', 'At740RhVlr("2","TFF_RH","TFF")',.F.)
	oStrTFF:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TFF_QTDVEN', 'TFF_QTDVEN', 'At740totVrb()',.F.)
	oStrTFF:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])	
xAux := FwStrutrigger( 'TFF_PRCVEN', 'TFF_TXLUCR', 'At740RhVlr("1","TFF_RH","TFF")',.F.)
	oStrTFF:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStrutrigger( 'TFF_PRCVEN', 'TFF_TXADM', 'At740RhVlr("2","TFF_RH","TFF")',.F.)
	oStrTFF:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
//------------------------------------------------------------------------------------------
// Gatilhos - Cobrança Locação Equipamento
//------------------------------------------------------------------------------------------
xAux := FwStruTrigger( 'TEV_LUCRO', 'TEV_TXLUCR', 'At740VlAcr("1","TEV_ADICIO","TEV")',.F.)
	oStrTEV:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])	
xAux := FwStruTrigger( 'TEV_ADM', 'TEV_TXADM', 'At740VlAcr("2","TEV_ADICIO","TEV")',.F.)
	oStrTEV:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])	
xAux := FwStrutrigger( 'TEV_QTDE', 'TEV_TXLUCR', 'At740VlAcr("1","TEV_ADICIO","TEV")',.F.)
	oStrTEV:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])	
xAux := FwStruTrigger( 'TEV_TXLUCR', 'TEV_VLTOT', 'At740VlTEV("TEV_ADICIO")',.F.)
	oStrTEV:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStrutrigger( 'TEV_VLRUNI', 'TEV_TXLUCR', 'At740VlAcr("1","TEV_ADICIO","TEV")' ,.F.)
	oStrTEV:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])	
xAux := FwStrutrigger( 'TEV_QTDE', 'TEV_TXADM', 'At740VlAcr("2","TEV_ADICIO","TEV")',.F.)
	oStrTEV:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TEV_TXADM', 'TEV_VLTOT', 'At740VlTEV("TEV_ADICIO")',.F.)
	oStrTEV:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStrutrigger( 'TEV_VLRUNI', 'TEV_TXADM', 'At740VlAcr("2","TEV_ADICIO","TEV")',.F.)
	oStrTEV:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4]) 
//------------------------------------------------------------------------------------------
// Gatilhos - Materiais de Implantação
//------------------------------------------------------------------------------------------
xAux := FwStrutrigger( 'TFG_LUCRO', 'TFG_TXLUCR', 'At740MatAc("1","TFG_MI","TFG")',.F.)
	oStrTFG:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])	
xAux := FwStrutrigger( 'TFG_LUCRO', 'TFG_TOTGER', 'At740VlTot("TFG_MI","TFG")',.F.)
	oStrTFG:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])	
xAux := FwStrutrigger( 'TFG_TOTAL', 'TFG_TOTGER', 'At740VlTot("TFG_MI","TFG")',.F.)
	oStrTFG:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])		
xAux := FwStrutrigger( 'TFG_PRCVEN', 'TFG_TOTGER', 'At740VlTot("TFG_MI","TFG")',.F.)
	oStrTFG:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])	
xAux := FwStrutrigger( 'TFG_QTDVEN', 'TFG_TOTGER', 'At740VlTot("TFG_MI","TFG")',.F.)
	oStrTFG:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStrutrigger( 'TFG_ADM', 'TFG_TXADM', 'At740MatAc("2","TFG_MI","TFG")',.F.)
	oStrTFG:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])	
xAux := FwStrutrigger( 'TFG_ADM', 'TFG_TOTGER', 'At740VlTot("TFG_MI","TFG")',.F.)
	oStrTFG:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])	
xAux := FwStrutrigger( 'TFG_TOTGER', 'TFG_TXLUCR', 'At740MatAc("1","TFG_MI","TFG")',.F.)
	oStrTFG:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])	
xAux := FwStrutrigger( 'TFG_TOTGER', 'TFG_TXADM', 'At740MatAc("2","TFG_MI","TFG")',.F.)
	oStrTFG:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])	
//------------------------------------------------------------------------------------------
// Gatilhos - Materiais de Consumo
//------------------------------------------------------------------------------------------
xAux := FwStrutrigger( 'TFH_LUCRO', 'TFH_TXLUCR', 'At740MatAc("1","TFH_MC","TFH")',.F.)
	oStrTFH:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStrutrigger( 'TFH_LUCRO', 'TFH_TOTGER', 'At740VlTot("TFH_MC","TFH")',.F.)
	oStrTFH:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])	
xAux := FwStrutrigger( 'TFH_TOTAL', 'TFH_TOTGER', 'At740VlTot("TFH_MC","TFH")',.F.)
	oStrTFH:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])		
xAux := FwStrutrigger( 'TFH_PRCVEN', 'TFH_TOTGER', 'At740VlTot("TFH_MC","TFH")',.F.)
	oStrTFH:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStrutrigger( 'TFH_QTDVEN', 'TFH_TOTGER', 'At740VlTot("TFH_MC","TFH")',.F.)
	oStrTFH:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStrutrigger( 'TFH_ADM', 'TFH_TXADM', 'At740MatAc("2","TFH_MC","TFH")',.F.)
	oStrTFH:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStrutrigger( 'TFH_ADM', 'TFH_TOTGER', 'At740VlTot("TFH_MC","TFH")',.F.)
	oStrTFH:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])	
xAux := FwStrutrigger( 'TFH_TOTGER', 'TFH_TXLUCR', 'At740MatAc("1","TFH_MC","TFH")',.F.)
	oStrTFH:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStrutrigger( 'TFH_TOTGER', 'TFH_TXADM', 'At740MatAc("2","TFH_MC","TFH")',.F.)
	oStrTFH:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
//-----------------------------------------------------------------------------------------
// Descrição do calendario
//-----------------------------------------------------------------------------------------
xAux := FwStruTrigger('TFF_CALEND','TFF_DSCALE','ALLTRIM( POSICIONE("AC0",1,XFILIAL("AC0")+M->TFF_CALEND,"AC0_DESC") )',.F.,Nil,Nil,Nil)
oStrTFF:AddTrigger(xAux[1],xAux[2],xAux[3],xAux[4])	
//-----------------------------------------------------------------------------------------
// Descrição da escala
//-----------------------------------------------------------------------------------------
xAux := FwStruTrigger('TFF_ESCALA','TFF_NOMESC','ALLTRIM( POSICIONE("TDW",1,XFILIAL("TDW")+M->TFF_ESCALA,"TDW_DESC") )',.F.,Nil,Nil,Nil)
oStrTFF:AddTrigger(xAux[1],xAux[2],xAux[3],xAux[4])
//------------------------------------------------------------------------------------------
// Gatilhos - Caracteristicas
//------------------------------------------------------------------------------------------
xAux := FwStrutrigger( 'TDS_CODTCZ', 'TDS_DSCTCZ', 'At740TDS()',.F.)
	oStrTDS:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
//------------------------------------------------------------------------------------------
// Gatilhos - Habilidades
//------------------------------------------------------------------------------------------
xAux := FwStrutrigger( 'TDT_CODHAB', 'TDT_DSCHAB', 'At740TDT("1")',.F.)
	oStrTDT:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStrutrigger( 'TDT_ESCALA', 'TDT_DSCESC', 'At740TDT("2")',.F.)
	oStrTDT:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStrutrigger( 'TDT_ITESCA', 'TDT_DSCITE', 'At740TDT("3")',.F.)
	oStrTDT:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStrutrigger( 'TDT_HABX5' , 'TDT_DHABX5', 'At740TDT("4")',.F.)
	oStrTDT:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
//------------------------------------------------------------------------------------------
// Gatilhos - Cursos
//------------------------------------------------------------------------------------------
xAux := FwStrutrigger( 'TGV_CURSO', 'TGV_DCURSO', 'At740TGV()',.F.)
	oStrTGV:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
//-----------------------------------------------------------------------------------------
// gatilho para preencher os percentuais de lucro e tx adm quando inserido produto na linha
//-----------------------------------------------------------------------------------------
xAux := FwStruTrigger( 'TFF_PRODUT', 'TFF_LUCRO', 'At740LuTxA("TFJ_LUCRO")')
	oStrTFF:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TFF_PRODUT', 'TFF_ADM', 'At740LuTxA("TFJ_ADM")')
	oStrTFF:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TFG_PRODUT', 'TFG_LUCRO', 'At740LuTxA("TFJ_LUCRO")')
	oStrTFG:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TFG_PRODUT', 'TFG_ADM', 'At740LuTxA("TFJ_ADM")')
	oStrTFG:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TFH_PRODUT', 'TFH_LUCRO', 'At740LuTxA("TFJ_LUCRO")')
	oStrTFH:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TFH_PRODUT', 'TFH_ADM', 'At740LuTxA("TFJ_ADM")')
	oStrTFH:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TEV_MODCOB', 'TEV_LUCRO', 'At740LuTxA("TFJ_LUCRO")')
	oStrTEV:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TEV_MODCOB', 'TEV_ADM', 'At740LuTxA("TFJ_ADM")')
	oStrTEV:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])

//------------------------------------------------------------------------------------------
// Gatilho - Quantidade de horas a serem consumidas na rota de almocista
//------------------------------------------------------------------------------------------
xAux := FwStruTrigger( 'TFF_QTDHRR', 'TFF_SLDHRR', 'FwFldGet("TFF_QTDHRR")')
	oStrTFF:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
	
oStrTFL:SetProperty( "TFL_CODPAI", MODEL_FIELD_OBRIGAT, .F. )
oStrTFF:SetProperty( "TFF_CODPAI", MODEL_FIELD_OBRIGAT, .F. )
oStrTFF:SetProperty( "TFF_LOCAL", MODEL_FIELD_OBRIGAT, .F. )
oStrTFG:SetProperty( "TFG_CODPAI", MODEL_FIELD_OBRIGAT, .F. )
oStrTFG:SetProperty( "TFG_LOCAL", MODEL_FIELD_OBRIGAT, .F. )
oStrTFH:SetProperty( "TFH_CODPAI", MODEL_FIELD_OBRIGAT, .F. )
oStrTFH:SetProperty( "TFH_LOCAL", MODEL_FIELD_OBRIGAT, .F. )
oStrTFI:SetProperty( "TFI_CODPAI", MODEL_FIELD_OBRIGAT, .F. )
oStrTFI:SetProperty( "TFI_LOCAL", MODEL_FIELD_OBRIGAT, .F. )
oStrTFI:SetProperty( "TFI_TOTAL", MODEL_FIELD_OBRIGAT, .F. )
oStrTFU:SetProperty( "TFU_CODTFF", MODEL_FIELD_OBRIGAT, .F. )
oStrTFU:SetProperty( "TFU_LOCAL" , MODEL_FIELD_OBRIGAT, .F. )
oStrTDS:SetProperty( "TDS_CODTFF", MODEL_FIELD_OBRIGAT, .F. ) 
oStrTDT:SetProperty( "TDT_CODTFF", MODEL_FIELD_OBRIGAT, .F. ) 
oStrTGV:SetProperty( "TGV_CODTFF", MODEL_FIELD_OBRIGAT, .F. ) 
oStrTGV:SetProperty( "TGV_CODTFF", MODEL_FIELD_INIT,{|oMdl| oMdl:GetModel():GetModel("TFF_RH"):GetValue("TFF_COD") } )
oStrTDS:SetProperty( "TDS_CODTFF", MODEL_FIELD_INIT,{|oMdl| oMdl:GetModel():GetModel("TFF_RH"):GetValue("TFF_COD") } )
oStrTDT:SetProperty( "TDT_CODTFF", MODEL_FIELD_INIT,{|oMdl| oMdl:GetModel():GetModel("TFF_RH"):GetValue("TFF_COD") } )

oStrABP:SetProperty( "ABP_ITRH"  , MODEL_FIELD_OBRIGAT, .F. )
oStrTEV:SetProperty( "TEV_CODLOC", MODEL_FIELD_OBRIGAT, .F. )

oStrTFH:SetProperty('TFH_PERINI',MODEL_FIELD_VALID,{|oMdlVld|At740VldDt("TFH_MC","TFH_PERINI","TFH_PERINI","TFH_PERFIM")})
oStrTFH:SetProperty('TFH_PERFIM',MODEL_FIELD_VALID,{|oMdlVld|At740VldDt("TFH_MC","TFH_PERFIM","TFH_PERINI","TFH_PERFIM")})

oStrTFG:SetProperty('TFG_PERINI',MODEL_FIELD_VALID,{|oMdlVld|At740VldDt("TFG_MI","TFG_PERINI","TFG_PERINI","TFG_PERFIM")})
oStrTFG:SetProperty('TFG_PERFIM',MODEL_FIELD_VALID,{|oMdlVld|At740VldDt("TFG_MI","TFG_PERFIM","TFG_PERINI","TFG_PERFIM")})

oStrTFF:SetProperty('TFF_PERINI',MODEL_FIELD_VALID,{|oMdlVld|At740VldDt("TFF_RH","TFF_PERINI","TFF_PERINI","TFF_PERFIM")})
oStrTFF:SetProperty('TFF_PERFIM',MODEL_FIELD_VALID,{|oMdlVld|At740VldDt("TFF_RH","TFF_PERFIM","TFF_PERINI","TFF_PERFIM")})

oStrTFI:SetProperty('TFI_PERINI',MODEL_FIELD_VALID, {|oMdlVld,cCampo,xValueNew,nLine,xValueOld|;
				At740VldDt("TFI_LE","TFI_PERINI","TFI_PERINI","TFI_PERFIM") .And. ;  // valida o período selecionado
				At740Reserv(oMdlVld,cCampo,xValueNew,nLine,xValueOld) } )  // verifica se há reserva de equipamento
oStrTFI:SetProperty('TFI_PERFIM',MODEL_FIELD_VALID, {|oMdlVld,cCampo,xValueNew,nLine,xValueOld|;
				At740VldDt("TFI_LE","TFI_PERFIM","TFI_PERINI","TFI_PERFIM") .And. ;  // valida o período selecionado
				At740Reserv(oMdlVld,cCampo,xValueNew,nLine,xValueOld) } )  // verifica se há reserva de equipamento
oStrTFI:SetProperty('TFI_QTDVEN',MODEL_FIELD_VALID, {|oMdlVld,cCampo,xValueNew,nLine,xValueOld|;
				xValueNew >= 0 .And. ;
				At740Reserv(oMdlVld,cCampo,xValueNew,nLine,xValueOld) } )

oStrTFL:SetProperty('TFL_DTFIM',MODEL_FIELD_VALID,{|oModel|At740VlVig(oModel)})

oStrTFF:SetProperty('TFF_PRCVEN',MODEL_FIELD_OBRIGAT,.F.)
oStrTFF:SetProperty('TFF_PRCVEN',MODEL_FIELD_WHEN ,{|oModel|At740BlTot(oModel)})
oStrTFF:SetProperty('TFF_PRCVEN',MODEL_FIELD_VALID,{|oModel|At740VlVlr("TFF_RH","TFF_PRCVEN",oModel)})
oStrTFF:SetProperty('TFF_VLBENE',MODEL_FIELD_WHEN ,{|oModel|At740WBen(oModel,"TFF_VLBENE")})

oStrTFF:SetProperty('TFF_QTDHRR',MODEL_FIELD_VALID,{|oMdlVld,cCampo,xValueNew,nLine,xValueOld| Positivo() .And. At740LmtFe(oMdlVld,cCampo,xValueNew,nLine,xValueOld)})

oStrABP:SetProperty('ABP_TPVERB',MODEL_FIELD_INIT,{|| At740ConvTp( ATINIPADMVC("TECA740","ABP_BENEF","RV_TIPO","SRV",1, "xFilial('SRV')+ABP->ABP_VERBA") ) } )

oStrTFG:SetProperty('TFG_PRCVEN',MODEL_FIELD_OBRIGAT,.F.)
oStrTFG:SetProperty('TFG_PRCVEN',MODEL_FIELD_VALID,{|oModel|At740VlVlr("TFG_MI","TFG_PRCVEN",oModel)})
oStrTFG:SetProperty('TFG_TOTGER',MODEL_FIELD_INIT,{|| ATINIPADMVC("TECA740","TFG_MI",'TFG_TOTGER',,,,'TFG->(TFG_QTDVEN*TFG_PRCVEN)+(TFG->(TFG_QTDVEN*TFG_PRCVEN)*(TFG->TFG_LUCRO/100))+(TFG->(TFG_QTDVEN*TFG_PRCVEN)*(TFG->TFG_ADM/100))') } )

//Campos referente a periodicidade dos produtos(TFG)
oStrTFG:SetProperty('TFG_PERIOD',MODEL_FIELD_WHEN ,{|| FwFldGet("TFJ_CNTREC") == "1"})
oStrTFG:SetProperty('TFG_QTPERI',MODEL_FIELD_WHEN ,{|| FwFldGet("TFG_PERIOD") == "1"})

oStrTFH:SetProperty('TFH_PRCVEN',MODEL_FIELD_OBRIGAT,.F.)
oStrTFH:SetProperty('TFH_PRCVEN',MODEL_FIELD_VALID,{|oModel|At740VlVlr("TFH_MC","TFH_PRCVEN",oModel)})
oStrTFH:SetProperty('TFH_TOTGER',MODEL_FIELD_INIT,{|| ATINIPADMVC("TECA740","TFH_MC",'TFH_TOTGER',,,,'TFH->(TFH_QTDVEN*TFH_PRCVEN)+(TFH->(TFH_QTDVEN*TFH_PRCVEN)*(TFH->TFH_LUCRO/100))+(TFH->(TFH_QTDVEN*TFH_PRCVEN)*(TFH->TFH_ADM/100))') } )

//Campos referente a periodicidade dos produtos(TFH)
oStrTFH:SetProperty('TFH_PERIOD',MODEL_FIELD_WHEN ,{|| FwFldGet("TFJ_CNTREC") == "1"})
oStrTFH:SetProperty('TFH_QTPERI',MODEL_FIELD_WHEN ,{|| FwFldGet("TFH_PERIOD") == "1"})

oStrTEV:SetProperty('TEV_UM',MODEL_FIELD_WHEN,{|| IsInCallStack('RunTrigger') .Or. FwFldGet('TEV_MODCOB') <> '2' } )
oStrTEV:SetProperty('TEV_VLTOT',MODEL_FIELD_INIT,{|| ATINIPADMVC("TECA740", "TEV_ADICIO", "TEV_VLTOT",,,,'TEV->(TEV_VLRUNI*TEV_QTDE)+TEV->(TEV_TXADM+TEV_TXLUCR)')} )

oStrTWO:SetProperty('TWO_CODFAC', MODEL_FIELD_VALID, {|a,b,c,d,e| FWInitCpo(a,b,c,d),lValFac := Vazio() .Or. ExistCpo("TWM"),FWCloseCpo(a,b,c,lValFac,.T.),lValFac})

//oStrTFU:SetProperty('TFU_ABNDES',MODEL_FIELD_INIT,{|| ATINIPADMVC("TECA740","TFU_HE","ABN_DESC","ABN",1, "XFILIAL('TFU')+TFU->TFU_CODABN") } )
oStrTFU:SetProperty( "TFU_PORCEN", MODEL_FIELD_WHEN,{|| FwFldGet('TFU_TPCALC') == '2' })
oStrTFU:SetProperty( "TFU_VALOR", MODEL_FIELD_WHEN,{|oModel|At740BlVal(oModel)})

oModel := MPFormModel():New('TECA740',,{|oModel| At740TdOk(oModel) },{|oModel| At740Cmt( oModel ) }, {|a,b,c,d| At740Canc( a,b,c,d ) } )
oModel:SetDescription( STR0001 ) // 'Orçamento para Serviços'

oModel:addFields('TFJ_REFER',,oStrTFJ)

oModel:addGrid('TFL_LOC','TFJ_REFER',oStrTFL, {|oMdlG,nLine,cAcao,cCampo| PreLinTFL(oMdlG, nLine, cAcao, cCampo) } )
oModel:SetRelation('TFL_LOC', { { 'TFL_FILIAL', 'xFilial("TFJ")' }, { 'TFL_CODPAI', 'TFJ_CODIGO' } }, TFL->(IndexKey(1)) )

oModel:addGrid('TFF_RH','TFL_LOC',oStrTFF, {|oMdlG,nLine,cAcao,cCampo, xValue, xOldValue| PreLinTFF(oMdlG, nLine, cAcao, cCampo, xValue, xOldValue) },{|oMdlG,nLine,cAcao,cCampo| PosLinTFF(oMdlG, nLine, cAcao, cCampo)})
oModel:SetRelation('TFF_RH', { { 'TFF_FILIAL', 'xFilial("TFF")' }, { 'TFF_CODPAI', 'TFL_CODIGO' }, { 'TFF_LOCAL', 'TFL_LOCAL' } }, TFF->(IndexKey(1)) )

oModel:addGrid('ABP_BENEF','TFF_RH',oStrABP)
oModel:SetRelation('ABP_BENEF', { { 'ABP_FILIAL', 'xFilial("ABP")' }, { 'ABP_ITRH', 'TFF_COD' }, {'ABP_COD','TFJ_PROPOS'} }, ABP->(IndexKey(1)) )
oModel:GetModel( 'ABP_BENEF' ):SetUniqueLine( { 'ABP_BENEFI' } )

oModel:addGrid('TFG_MI','TFF_RH',oStrTFG, {|oMdlG,nLine,cAcao,cCampo,xVal,xValAtu| PreLinTFG(oMdlG, nLine, cAcao, cCampo,xVal,xValAtu) },{|oMdlG,nLine,cAcao,cCampo| PosLinTFG(oMdlG, nLine, cAcao, cCampo)} )
oModel:SetRelation('TFG_MI', { { 'TFG_FILIAL', 'xFilial("TFG")' }, { 'TFG_CODPAI', 'TFF_COD' }, { 'TFG_LOCAL', 'TFL_LOCAL' } }, TFG->(IndexKey(1)) )

oModel:addGrid('TFH_MC','TFF_RH',oStrTFH, {|oMdlG,nLine,cAcao,cCampo,xVal,xValAtu| PreLinTFH(oMdlG, nLine, cAcao, cCampo,xVal,xValAtu) },{|oMdlG,nLine,cAcao,cCampo| PosLinTFH(oMdlG, nLine, cAcao, cCampo)} )
oModel:SetRelation('TFH_MC', { { 'TFH_FILIAL', 'xFilial("TFH")' }, { 'TFH_CODPAI', 'TFF_COD' }, { 'TFH_LOCAL', 'TFL_LOCAL' } }, TFH->(IndexKey(1)) )

oModel:addGrid('TFU_HE','TFF_RH',oStrTFU )
oModel:SetRelation('TFU_HE', { { 'TFU_FILIAL', 'xFilial("TFU")' }, { 'TFU_CODTFF', 'TFF_COD' }, { 'TFU_LOCAL', 'TFL_LOCAL' } }, TFU->(IndexKey(1)) )

oModel:addGrid('TFI_LE','TFL_LOC',oStrTFI, {|oMdlG,nLine,cAcao,cCampo| PreLinTFI(oMdlG, nLine, cAcao, cCampo) } )
oModel:SetRelation('TFI_LE', { { 'TFI_FILIAL', 'xFilial("TFI")' }, { 'TFI_CODPAI', 'TFL_CODIGO' }, { 'TFI_LOCAL', 'TFL_LOCAL' } }, TFI->(IndexKey(1)) )

oModel:addGrid('TEV_ADICIO','TFI_LE',oStrTEV, {|oMdlG,nLine,cAcao,cCampo| PreLinTEV(oMdlG, nLine, cAcao, cCampo) } )
oModel:SetRelation('TEV_ADICIO', { { 'TEV_FILIAL', 'xFilial("TEV")' }, { 'TEV_CODLOC', 'TFI_COD' } }, TEV->(IndexKey(1)) )
oModel:GetModel( 'TEV_ADICIO' ):SetUniqueLine( { 'TEV_MODCOB' } )

//referente fonte TECA741 - Habilidades, Características e Cursos para o item de RH
oModel:AddGrid( "TGV_RH", "TFF_RH", oStrTGV,/*bLinePre*/,/*bLinePos*/,/*bPreVal*/ ,/*bPosVal*/ , /*bLoad*/)
oModel:SetRelation('TGV_RH', { { 'TGV_FILIAL', 'xFilial("TGV")' }, { 'TGV_CODTFF', 'TFF_COD' } }, TGV->(IndexKey(1)) )
oModel:GetModel( 'TGV_RH' ):SetUniqueLine( { 'TGV_CODTFF','TGV_CURSO' } )

oModel:AddGrid( "TDS_RH", "TFF_RH", oStrTDS,/*bLinePre*/,/*bLinePos*/,/*bPreVal*/ ,/*bPosVal*/ , /*bLoad*/)
oModel:SetRelation('TDS_RH', { { 'TDS_FILIAL', 'xFilial("TDS")' }, { 'TDS_CODTFF', 'TFF_COD' } }, TDS->(IndexKey(1)) )
oModel:GetModel( 'TDS_RH' ):SetUniqueLine( { 'TDS_CODTFF','TDS_CODTCZ' } )

oModel:AddGrid( "TDT_RH", "TFF_RH", oStrTDT,/*bLinePre*/,/*bLinePos*/,/*bPreVal*/ ,/*bPosVal*/ , /*bLoad*/)
oModel:SetRelation('TDT_RH', { { 'TDT_FILIAL', 'xFilial("TDT")' }, { 'TDT_CODTFF', 'TFF_COD' } }, TDT->(IndexKey(1)) )

oModel:AddGrid( "TWODETAIL", "TFL_LOC", oStrTWO, {|oModelGrid,  nLine,cAction,  cField, xValue, xOldValue|A740LoadFa(oModelGrid, nLine, cAction, cField, xValue, xOldValue)}/*bLinePre*/,/*bLinePos*/,/*bPreVal*/ ,/*bPosVal*/ , /*bLoad*/)
oModel:SetRelation('TWODETAIL', { { 'TWO_FILIAL', 'xFilial("TWO")' }, {'TWO_CODORC', 'TFJ_CODIGO'}, {'TWO_PROPOS', 'TFJ_PROPOS'}, {'TWO_LOCAL','TFL_CODIGO'} }, TWO->(IndexKey(1)) )

oModel:getModel('TFJ_REFER'):SetDescription(STR0004)	// 'Ref. Proposta'
oModel:getModel('TFL_LOC'):SetDescription(STR0005)		// 'Locais'
oModel:getModel('TFF_RH'):SetDescription(STR0006)		// 'Recursos Humanos'
oModel:getModel('TFG_MI'):SetDescription(STR0007)		// 'Materiais de Implantação'
oModel:getModel('TFH_MC'):SetDescription(STR0008)		// 'Material de Consumo'
oModel:getModel('TFU_HE'):SetDescription(STR0031)		// 'Hora Extra'
oModel:getModel('TFI_LE'):SetDescription(STR0009)		// 'Locação de Equipamentos'
oModel:getModel('ABP_BENEF'):SetDescription(STR0010)	// 'Beneficios'
oModel:getModel('TEV_ADICIO'):SetDescription(STR0011)	// 'Cobrança da Locação'
oModel:getModel('TGV_RH'):SetDescription(STR0072)		// 'Cursos' 
oModel:getModel('TDS_RH'):SetDescription(STR0073)		// 'Habilidades' 
oModel:getModel('TDT_RH'):SetDescription(STR0074)		// 'Caracteristicas' 
oModel:getModel('TWODETAIL'):SetDescription(STR0096)	// 'Facilitador' 

oModel:getModel('TEV_ADICIO'):SetOptional(.T.)
oModel:getModel('TFI_LE'):SetOptional(.T.)
oModel:getModel('TFH_MC'):SetOptional(.T.)
oModel:getModel('TFG_MI'):SetOptional(.T.)
oModel:getModel('TFU_HE'):SetOptional(.T.)
oModel:getModel('ABP_BENEF'):SetOptional(.T.)
oModel:getModel('TFF_RH'):SetOptional(.T.)
oModel:getModel('TGV_RH'):SetOptional(.T.) //ref. fonte TECA741 - Cursos
oModel:getModel('TDS_RH'):SetOptional(.T.) //ref. fonte TECA741 - Características
oModel:getModel('TDT_RH'):SetOptional(.T.) //ref. fonte TECA741 - Habilidades
oModel:getModel('TWODETAIL'):SetOptional(.T.) //Facilitador

oModel:AddCalc( 'CALC_TFI', 'TFL_LOC', 'TFI_LE', 'TFI_TOTAL', 'TOT_LE', 'SUM', /*bCondition*/, /*bInitValue*/, STR0012 /*cTitle*/, /*bFormula*/) // 'Tot. Loc. Equipamento'
oModel:AddCalc( 'CALC_TFF', 'TFL_LOC', 'TFF_RH', 'TFF_SUBTOT', 'TOT_RH', 'SUM', /*bCondition*/, /*bInitValue*/,STR0013 /*cTitle*/, /*bFormula*/)  // 'Tot. Rec. Humanos'
oModel:AddCalc( 'CALC_TFF', 'TFL_LOC', 'TFF_RH', 'TFF_TOTMI', 'TOT_RHMI', 'SUM', /*bCondition*/, /*bInitValue*/,STR0014 /*cTitle*/, /*bFormula*/)  // 'Tot. Mat. Implantação'
oModel:AddCalc( 'CALC_TFF', 'TFL_LOC', 'TFF_RH', 'TFF_TOTMC', 'TOT_RHMC', 'SUM', /*bCondition*/, /*bInitValue*/,STR0015 /*cTitle*/, /*bFormula*/)  // 'Tot. Mat. Consumo'
oModel:AddCalc( 'CALC_TFG', 'TFF_RH', 'TFG_MI', 'TFG_TOTGER', 'TOT_MI', 'SUM', /*bCondition*/, /*bInitValue*/,STR0014 /*cTitle*/, /*bFormula*/)  // 'Tot. Mat. Implantação'
oModel:AddCalc( 'CALC_TFH', 'TFF_RH', 'TFH_MC', 'TFH_TOTGER', 'TOT_MC', 'SUM', /*bCondition*/, /*bInitValue*/,STR0015 /*cTitle*/, /*bFormula*/)  // 'Tot. Mat. Consumo'
oModel:AddCalc( 'CALC_TEV', 'TFI_LE', 'TEV_ADICIO', 'TEV_VLTOT', 'TOT_ADICIO', 'SUM', {|oMdl| At740WhCob( oMdl) }/*bCondition*/, /*bInitValue*/,STR0016 /*cTitle*/, /*bFormula*/)  // 'Tot. Cobrança Loc. Equip.'
oModel:AddCalc( 'CALC_TFL', 'TFJ_REFER', 'TFL_LOC', 'TFL_TOTRH', 'TOT_RH', 'SUM', /*bCondition*/, /*bInitValue*/,STR0017 /*cTitle*/, /*bFormula*/)  // 'Geral RH'
oModel:AddCalc( 'CALC_TFL', 'TFJ_REFER', 'TFL_LOC', 'TFL_TOTMI', 'TOT_MI', 'SUM', /*bCondition*/, /*bInitValue*/,STR0018 /*cTitle*/, /*bFormula*/)  // 'Geral MI'
oModel:AddCalc( 'CALC_TFL', 'TFJ_REFER', 'TFL_LOC', 'TFL_TOTMC', 'TOT_MC', 'SUM', /*bCondition*/, /*bInitValue*/,STR0019 /*cTitle*/, /*bFormula*/)  // 'Geral MC'
oModel:AddCalc( 'CALC_TFL', 'TFJ_REFER', 'TFL_LOC', 'TFL_TOTLE', 'TOT_LE', 'SUM', /*bCondition*/, /*bInitValue*/,STR0020 /*cTitle*/, /*bFormula*/)  // 'Geral LE'
oModel:AddCalc( 'CALC_TFL', 'TFJ_REFER', 'TFL_LOC', 'TFL_TOTAL', 'TOT_GERAL', 'SUM', /*bCondition*/, /*bInitValue*/,STR0021 /*cTitle*/, /*bFormula*/) // 'Geral Proposta'
//--------------------------------------------------------------
//  Totais que são exibidos na interface
//-------------------------------------------------------------- 
oModel:AddCalc( 'TOTAIS', 'TFJ_REFER', 'TFL_LOC', 'TFL_TOTRH', 'TOT_RH', 'FORMULA',{||.T.} /*bCondition*/, /*bInitValue*/,STR0017 /*cTitle*/,{|oModel| oModel:GetValue("CALC_TFL","TOT_RH")} /*bFormula*/) // 'Geral RH'
oModel:AddCalc( 'TOTAIS', 'TFJ_REFER', 'TFL_LOC', 'TFL_TOTMI', 'TOT_MI', 'FORMULA',{||.T.} /*bCondition*/, /*bInitValue*/,STR0018 /*cTitle*/,{|oModel| oModel:GetValue("CALC_TFL","TOT_MI")} /*bFormula*/)  // 'Geral MI'
oModel:AddCalc( 'TOTAIS', 'TFJ_REFER', 'TFL_LOC', 'TFL_TOTMC', 'TOT_MC', 'FORMULA',{||.T.} /*bCondition*/, /*bInitValue*/,STR0019 /*cTitle*/,{|oModel| oModel:GetValue("CALC_TFL","TOT_MC")} /*bFormula*/)  // 'Geral MC'
oModel:AddCalc( 'TOTAIS', 'TFJ_REFER', 'TFL_LOC', 'TFL_TOTLE', 'TOT_LE', 'FORMULA',{||.T.} /*bCondition*/, /*bInitValue*/,STR0020 /*cTitle*/,{|oModel| oModel:GetValue("CALC_TFL","TOT_LE")} /*bFormula*/)  // 'Geral LE'
oModel:AddCalc( 'TOTAIS', 'TFJ_REFER', 'TFL_LOC', 'TFL_TOTAL', 'TOT_GERAL', 'FORMULA',{||.T.} /*bCondition*/, /*bInitValue*/,STR0021 /*cTitle*/, ;
	{|oModel| oModel:GetValue("TOTAIS","TOT_RH")+oModel:GetValue("TOTAIS","TOT_MI")+oModel:GetValue("TOTAIS","TOT_MC")+oModel:GetValue("TOTAIS","TOT_LE")} /*bFormula*/)  // 'Geral Proposta'
//--------------------------------------
//fim dos totais exibidos 
//--------------------------------------
oMdlCalc := oModel:GetModel("TOTAIS")
oMdlCalc:AddEvents("TOTAIS","TOT_GERAL","",{||.T.})

If _lGSVinc
	oStrTFF:SetProperty( "TFF_PERINI", MODEL_FIELD_INIT,{|oMdl| oMdl:GetModel():GetModel("TFL_LOC"):GetValue("TFL_DTINI") } )
	oStrTFF:SetProperty( "TFF_PERFIM", MODEL_FIELD_INIT,{|oMdl| oMdl:GetModel():GetModel("TFL_LOC"):GetValue("TFL_DTFIM") } )

	oStrTFH:SetProperty( "TFH_PERINI", MODEL_FIELD_INIT,{|oMdl| oMdl:GetModel():GetModel("TFF_RH"):GetValue("TFF_PERINI") } )
	oStrTFH:SetProperty( "TFH_PERFIM", MODEL_FIELD_INIT,{|oMdl| oMdl:GetModel():GetModel("TFF_RH"):GetValue("TFF_PERFIM") } )
	
	oStrTFG:SetProperty( "TFG_PERINI", MODEL_FIELD_INIT,{|oMdl| oMdl:GetModel():GetModel("TFF_RH"):GetValue("TFF_PERINI") } )
	oStrTFG:SetProperty( "TFG_PERFIM", MODEL_FIELD_INIT,{|oMdl| oMdl:GetModel():GetModel("TFF_RH"):GetValue("TFF_PERFIM") } )
EndIf
oModel:SetActivate( {|oModel| InitDados( oModel ) } )

Return oModel

//-------------------------------------------------------------------
/*/{Protheus.doc} At740GtDes
	Função para cálculo dos valores gerais da proposta

@since   	04/10/2013
@version 	P11.90
/*/
//-------------------------------------------------------------------
Function At740GtDes()

Local oModel := FwModelActive()
Local oMdlCalc := oModel:GetModel("TOTAIS")
	
oMdlCalc:LoadValue('TOT_RH',(oMdlCalc:GetValue('TOT_RH')),.T.)
oMdlCalc:LoadValue('TOT_MI',(oMdlCalc:GetValue('TOT_MI')),.T.)
oMdlCalc:LoadValue('TOT_MC',(oMdlCalc:GetValue('TOT_MC')),.T.)
oMdlCalc:LoadValue('TOT_LE',(oMdlCalc:GetValue('TOT_LE')),.T.)	

oMdlCalc:LoadValue('TOT_GERAL',oMdlCalc:GetValue('TOT_RH')+oMdlCalc:GetValue('TOT_MI')+oMdlCalc:GetValue('TOT_MC')+oMdlCalc:GetValue('TOT_LE'),.T.)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
	Definição da interface

@since   	10/09/2013
@version 	P11.90

/*/
//-------------------------------------------------------------------
Static Function ViewDef()

Local oView   := Nil
Local oModel  := If( oCharge <> NIl, oCharge, ModelDef() )
Local lConExt := IsInCallStack("At870GerOrc")
Local cMenuRH := ""
Local cMenuMI := ""
Local cMenuMC := ""
Local oStrTFJ  := FWFormStruct(2, 'TFJ', {|cCpo| At740SelFields( 'TFJ', Alltrim(cCpo) ) } )
Local oStrTFL  := FWFormStruct(2, 'TFL', {|cCpo| At740SelFields( 'TFL', Alltrim(cCpo) ) } )
Local oStrTFF  := FWFormStruct(2, 'TFF', {|cCpo| At740SelFields( 'TFF', Alltrim(cCpo) ) } )
Local oStrABP  := FWFormStruct(2, 'ABP', {|cCpo| At740SelFields( 'ABP', Alltrim(cCpo) ) } )
Local oStrTFG  := FWFormStruct(2, 'TFG', {|cCpo| At740SelFields( 'TFG', Alltrim(cCpo) ) } )
Local oStrTFH  := FWFormStruct(2, 'TFH', {|cCpo| At740SelFields( 'TFH', Alltrim(cCpo) ) } )
Local oStrTFI  := FWFormStruct(2, 'TFI', {|cCpo| At740SelFields( 'TFI', Alltrim(cCpo) ) } )
Local oStrTFU  := FWFormStruct(2, 'TFU', {|cCpo| At740SelFields( 'TFU', Alltrim(cCpo) ) } )
Local oStrTEV  := FWFormStruct(2, 'TEV', {|cCpo| At740SelFields( 'TEV', Alltrim(cCpo) ) } )
Local oStrTWO  := FwFormStruct(2, 'TWO', {|cCpo| At740SelFields( 'TWO', Alltrim(cCpo) ) } )
Local oStrCalc := FWCalcStruct( oModel:GetModel('TOTAIS') )
Local lOkSly   := AliasInDic('SLY')
Local lSrvExt  := IsInCallStack("TECA744A") // Se chamado pela rotina de efetivação de orçamento de serviços extra, não mostra os botões de ações relacionadas.
Local cGsDsGcn	:= ""
Local cIsGsMt	:= ""
_lGSVinc := SuperGetMv("MV_GSVINC",,.F.)

If IsInCallStack("At870Revis") .Or. lConExt
	oStrTFJ:SetProperty('*', MVC_VIEW_CANCHANGE, .F.)
	oStrTFJ:SetProperty('TFJ_CONDPG', MVC_VIEW_CANCHANGE, .T.)
EndIf

//ordena os campos TFI.
oStrTFI:SetProperty( "TFI_ENTEQP", MVC_VIEW_ORDEM, "13" )
oStrTFI:SetProperty( "TFI_COLEQP", MVC_VIEW_ORDEM, "14" )
oStrTFI:SetProperty( "TFI_TOTAL" , MVC_VIEW_ORDEM, "15" )
oStrTFF:SetProperty("TFF_TIPORH", MVC_VIEW_CANCHANGE, .F.)
oStrTFF:SetProperty("TFF_VLBENE", MVC_VIEW_CANCHANGE, .F.)
oStrTFF:SetProperty("TFF_TOTBEN", MVC_VIEW_CANCHANGE, .F.)
oStrTFF:SetProperty("TFF_TOTVRB", MVC_VIEW_CANCHANGE, .F.)
oStrTFG:SetProperty("TFG_TIPMAT", MVC_VIEW_CANCHANGE, .F.)
oStrTFH:SetProperty("TFH_TIPMAT", MVC_VIEW_CANCHANGE, .F.)

oView := FWFormView():New()

oView:SetModel(oModel)

oView:AddField('VIEW_REFER', oStrTFJ, 'TFJ_REFER' )
oView:AddGrid('VIEW_LOC'   , oStrTFL, 'TFL_LOC')
oView:AddGrid('VIEW_RH'    , oStrTFF, 'TFF_RH')
oView:AddGrid('VIEW_MI'    , oStrTFG, 'TFG_MI', , {|| F740LockGrd(oView:GetModel()), oView:Refresh( 'VIEW_MI' ) } )
oView:AddGrid('VIEW_MC'    , oStrTFH, 'TFH_MC', , {|| F740LockGrd(oView:GetModel()), oView:Refresh( 'VIEW_MC' ) }) 
If !lConExt
	oView:AddGrid('VIEW_BENEF' , oStrABP, 'ABP_BENEF')
	oView:AddGrid('VIEW_HE'    , oStrTFU, 'TFU_HE')	
	oView:AddGrid('VIEW_LE'    , oStrTFI, 'TFI_LE')
	oView:AddGrid('VIEW_ADICIO', oStrTEV, 'TEV_ADICIO')
EndIf
oView:AddField('VIEW_CALC' ,oStrCalc, 'TOTAIS')

oStrTFJ:RemoveField('TFJ_CODGRP')

oStrTFL:RemoveField("TFL_TOTIMP")

oStrTFF:RemoveField("TFF_CALCMD")
//oStrTFF:RemoveField( "TFF_PLACOD" )
//oStrTFF:RemoveField( "TFF_PLAREV" )

oStrTFF:RemoveField('TFF_TOTVRB')

oStrTFI:RemoveField("TFI_CALCMD")
oStrTFI:RemoveField("TFI_SEPSLD")
oStrTFI:RemoveField("TFI_CONENT")
oStrTFI:RemoveField("TFI_CONCOL")
oStrTFI:RemoveField( "TFI_PLACOD" )
oStrTFI:RemoveField( "TFI_PLAREV" )

// só executa quando não é o orçamento que não gera contrato
If !IsInCallStack("TECA744")
	If oModel:GetOperation() == MODEL_OPERATION_INSERT .And. !IsInCallStack("TECA870")
		cGsDsGcn := SuperGetMv("MV_GSDSGCN",,"2")
		cIsGsMt  := SuperGetMv("MV_ISGSMT",,"2")
	Else
		cGsDsGcn := TFJ->TFJ_DSGCN
		cIsGsMt  := TFJ->TFJ_ISGSMT
	EndIf

	If cGsDsGcn == "1"
		//Retira os campos da View
		oStrTFJ:RemoveField('TFJ_GRPRH')
		oStrTFJ:RemoveField('TFJ_GRPMI')
		oStrTFJ:RemoveField('TFJ_GRPMC')
		oStrTFJ:RemoveField('TFJ_GRPLE')
		oStrTFJ:RemoveField('TFJ_TES')
		oStrTFJ:RemoveField('TFJ_TESMI')
		oStrTFJ:RemoveField('TFJ_TESMC')
		oStrTFJ:RemoveField('TFJ_TESLE')
		oStrTFJ:RemoveField('TFJ_DSCRH')
		oStrTFJ:RemoveField('TFJ_DSCMI')
		oStrTFJ:RemoveField('TFJ_DSCMC')
		oStrTFJ:RemoveField('TFJ_DSCLE')
	Else
		oStrTFF:RemoveField('TFF_TESPED')
		oStrTFG:RemoveField('TFG_TESPED')
		oStrTFH:RemoveField('TFH_TESPED')
		oStrTFI:RemoveField('TFI_TESPED')
	EndIf

	If cIsGsMt == "1"
		oStrTFJ:RemoveField('TFJ_GESMAT')
		oStrTFF:RemoveField('TFF_PERMAT')
		oStrTFF:RemoveField('TFF_VLRMAT')
	Else
		oStrTFJ:RemoveField('TFJ_GSMTMI')
		oStrTFJ:RemoveField('TFJ_GSMTMC')
		oStrTFF:RemoveField('TFF_PRMTMI')
		oStrTFF:RemoveField('TFF_PRMTMC')
		oStrTFF:RemoveField('TFF_VLMTMI')
		oStrTFF:RemoveField('TFF_VLMTMC')
		oStrTFF:RemoveField('TFF_PDMTMI')
		oStrTFF:RemoveField('TFF_PDMTMC')
	Endif
EndIf

// Adiciona as visões na tela
oView:CreateHorizontalBox( 'TOP'   , 30 )
oView:CreateHorizontalBox( 'MIDDLE', 60 )
oView:CreateHorizontalBox( 'DOWN'  , 10 )

oView:CreateFolder( 'ABAS', 'MIDDLE')
oView:AddSheet('ABAS','ABA01',STR0022)  // 'Locais de Atendimento'
oView:AddSheet('ABAS','ABA02',STR0006)  // 'Recursos Humanos'
If !lConExt
	oView:AddSheet('ABAS','ABA03',STR0009)  // 'Locação de Equipamentos'
EndIf

// cria as abas e sheet para incluir
oView:CreateHorizontalBox( 'ID_ABA01' , 100,,, 'ABAS', 'ABA01' ) // Define a área de Locais
oView:CreateHorizontalBox( 'ID_ABA02' , 060,,, 'ABAS', 'ABA02' ) // Define a área de RH
oView:CreateHorizontalBox( 'ID_ABA02A', 040,,, 'ABAS', 'ABA02' ) // área dos acionais relacionados com RH

// cria folder e sheets para Abas de Material Consumo, Implantação e Benefícios
oView:CreateFolder( 'RH_ABAS', 'ID_ABA02A')
oView:AddSheet('RH_ABAS','RH_ABA02',STR0007) // 'Materiais de Implantação'
oView:AddSheet('RH_ABAS','RH_ABA03',STR0008) // 'Materiais de Consumo'
If !lConExt	
	oView:AddSheet('RH_ABAS','RH_ABA01',STR0023) // 'Verbas Adicionais'
	oView:AddSheet('RH_ABAS','RH_ABA04',STR0031) // 'Hora Extra'
EndIf
	
If !lConExt
	oView:CreateHorizontalBox( 'ID_RH_01' , 100,,, 'RH_ABAS', 'RH_ABA01' ) // Define a área de Benefícios item de Rh
	oView:CreateHorizontalBox( 'ID_RH_04' , 100,,, 'RH_ABAS', 'RH_ABA04' ) // Define a área da Hora Extra
EndIf

oView:CreateHorizontalBox( 'ID_RH_02' , 100,,, 'RH_ABAS', 'RH_ABA02' ) // Define a área de Materiais de Implantação
oView:CreateHorizontalBox( 'ID_RH_03' , 100,,, 'RH_ABAS', 'RH_ABA03' ) // Define a área de Materiais de Consumo

If !lConExt
	oView:CreateHorizontalBox( 'ID_ABA03' , 060,,, 'ABAS', 'ABA03' ) // Define a área de Locação de Equipamentos
	oView:CreateHorizontalBox( 'ID_ABA03A', 040,,, 'ABAS', 'ABA03' )
EndIf

// Faz a amarração das VIEWs dos modelos com as divisões na interface
oView:SetOwnerView('VIEW_REFER'	,'TOP')			// Cabeçalho
oView:SetOwnerView('VIEW_CALC'	,'DOWN')		// Totais
oView:SetOwnerView('VIEW_LOC'	,'ID_ABA01')	// Grid Locais
oView:SetOwnerView('VIEW_RH'	,'ID_ABA02')	// Grid RH
If !lConExt	
	oView:SetOwnerView( 'VIEW_BENEF', 'ID_RH_01')  // Grid Benefícios
	oView:SetOwnerView( 'VIEW_HE'   , 'ID_RH_04')  // Grid Hora Extra
EndIf
oView:SetOwnerView( 'VIEW_MI'   , 'ID_RH_02')  // Grid Materiais de Implantação
oView:SetOwnerView( 'VIEW_MC'   , 'ID_RH_03')  // Grid Materiais de Consumo
If !lConExt
	oView:SetOwnerView( 'VIEW_LE'  , 'ID_ABA03')  // Grid Locação de Equipamentos
	oView:SetOwnerView( 'VIEW_ADICIO'  , 'ID_ABA03A')
	oView:EnableTitleView('VIEW_ADICIO', STR0011)  // 'Cobrança da Locação'
EndIf
	
oView:AddIncrementField('VIEW_MC' , 'TFH_ITEM' )
oView:AddIncrementField('VIEW_MI' , 'TFG_ITEM' )
oView:AddIncrementField('VIEW_RH' , 'TFF_ITEM' )
If !lConExt 
	oView:AddIncrementField('VIEW_BENEF' , 'ABP_ITEM' )
	oView:AddIncrementField('VIEW_ADICIO' , 'TEV_ITEM' ) 
	oView:AddIncrementField('VIEW_LE' , 'TFI_ITEM' )
EndIf 

oView:SetAfterViewActivate({|oView| At740Refre(oView)}) 

SetKey( VK_F4, { || AT740F4() } )
SetKey( VK_F5, { || At740F5() })
 
If !lSrvExt 
	If TableInDic( "TX8", .F. )
		oView:AddUserButton(STR0182,"",{|oModel| At740ApP(oModel,oView)},,,) // "Apura Config Planilha"		
	EndIf
	oView:AddUserButton(STR0032,"",{|oModel| At740Pla(oModel, oView)},,,) // "Planilha Preço"
	oView:AddUserButton(STR0033,"",{|oModel| At740CpCal(oModel)},,,) //"Copiar Cálculo"
	oView:AddUserButton(STR0034,"",{|oModel| At740ClCal(oModel)},,,) //"Colar Cálculo"
	oView:AddUserButton(STR0087,"",{|| At740ConEq()},,,) //"Consulta Equipamentos"
	oView:AddUserButton(STR0096,"",{|oModel,oView| TEC740FACI(oModel)},,,)	// "Facilitador"
	oView:AddUserButton(STR0124,"",{|| At740F5()},,,)  // "Estrutura de Kit de Produtos"
EndIf

// Somente habilita o menu caso nao for vistoria
IF lOkSly .And. !lSrvExt .AND. !FT600GETVIS()
	oView:AddUserButton(STR0068,"",{|oModel| AT352TDX(oModel)},,,) //"Vinculo de Beneficios"
ENDIF

// Botões para adicionar os itens de cortesia
If !IsInCallStack("TECA270") .AND. !lSrvExt	
	
	cMenuRH := If( lConExt, STR0056, STR0057 ) //"Rec.Hum. Extra"#"Cortesia Rec.Hum."
	cMenuMI := If( lConExt, STR0058, STR0059 ) //"Mat.Imp. Extra"#"Cortesia Mat.Imp."
	cMenuMC := If( lConExt, STR0060, STR0061 ) //"Mat.Con. Extra"#"Cortesia Mat.Con."

	If IsInCallStack("At870GerOrc")
		oView:AddUserButton(cMenuRH,"",{|oModel| At740Cortesia(oModel,"033")},,,) 
		oView:AddUserButton(cMenuMI,"",{|oModel| At740Cortesia(oModel,"034")},,,) 
		oView:AddUserButton(cMenuMC,"",{|oModel| At740Cortesia(oModel,"035")},,,)
	Else
		oView:AddUserButton(cMenuRH,"",{|oModel| At740Cortesia(oModel,"002")},,,) 
		oView:AddUserButton(cMenuMI,"",{|oModel| At740Cortesia(oModel,"003")},,,) 
		oView:AddUserButton(cMenuMC,"",{|oModel| At740Cortesia(oModel,"004")},,,) 
	EndIf
EndIf 

//Se estiver habilitada a funcionalidade de configuração de vínculos, habilita o f3
If _lGSVinc
	oStrTFF:SetProperty("TFF_FUNCAO", MVC_VIEW_LOOKUP, "TFFSRJ")
	oStrTFF:SetProperty("TFF_ESCALA", MVC_VIEW_LOOKUP,"TFFTDW")
EndIf

Return oView

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740SelFields
	Filtra os campos de controle da rotina para não serem exibidos na view
@sample 	At740SelFields() 
@since		27/11/2013       
@version	P11.90
@param   	cTab, Caracter, Código da tabela a ter o campo avaliado
@param   	cCpoAval, Caracter, Código do campo a ser avaliado

@return 	lRet, Logico, define se o campo deve ser apresentado na view
/*/
//------------------------------------------------------------------------------
Function At740SelFields( cTab, cCpoAval )

Local lRet    := .T.
Local lOrcPrc := SuperGetMv("MV_ORCPRC",,.F.)

If !Empty( cTab ) .And. !Empty( cCpoAval )
	If cTab == 'TFJ'
		lRet := !( cCpoAval $ 'TFJ_PROPOS#TFJ_PREVIS#TFJ_ENTIDA#TFJ_ITEMRH#TFJ_ITEMMI#TFJ_ITEMMI#TFJ_DSGCN#TFJ_ISGSMT' )
		lRet := lRet .And. !( cCpoAval $ 'TFJ_ITEMMC#TFJ_ITEMLE#TFJ_CONTRT#TFJ_CONREV#TFJ_STATUS#TFJ_TOTRH#TFJ_TOTMI#TFJ_TOTMC#TFJ_TOTLE#TFJ_CODVIS#TFJ_TABXML' )
		If !lOrcPrc // Retirar campos para o modelo antigo de orçamento de serviços
			lRet := lRet .And. !( cCpoAval $ 'TFJ_CODTAB#TFJ_TABREV' )
		EndIf	
	ElseIf cTab == 'TFL'
		lRet := !( cCpoAval $ 'TFL_CODIGO#TFL_CONTRT#TFL_CONREV#TFL_PLAN#TFL_CODSUB' )
		lRet := lRet .And. !( cCpoAval $ 'TFL_ITPLRH#TFL_ITPLMI#TFL_ITPLMC#TFL_ITPLLE#TFL_ENCE' )
		If !lOrcPrc // Retirar campos para o modelo antigo de orçamento de serviços
			lRet := lRet .And. !( cCpoAval $ 'TFL_MESRH#TFL_MESMI#TFL_MESMC' )
		EndIf		
	ElseIf cTab == 'TFF'
		lRet := cCpoAval <> "TFF_CODPAI" .And. cCpoAval <> "TFF_CODPAI" .And. !( cCpoAval $ 'TFF_LOCAL#TFF_CONTRT#TFF_CONREV#TFF_COBCTR#TFF_CHVTWO#TFF_ENCE#TFF_PROCES#TFF_ITCNB#TFF_ORIREF#TFF_ITICNB#TFF_ITCCNB#TFF_SLDHRR' )
		
		If lOrcPrc // Retirar campos para o novo modelo de orçamento de serviços
			lRet := lRet .And. !( cCpoAval $ 'TFF_TOTMI#TFF_TOTMC' )
		Else 
			lRet := lRet .And. !( cCpoAval $ 'TFF_TOTMES' )
		EndIf				
	ElseIf cTab == 'TFI'
		lRet := !( cCpoAval $ 'TFI_COD#TFI_LOCAL#TFI_OK#TFI_SEPARA#TFI_CODPAI#TFI_CONTRT#TFI_CONREV#TFI_CODSUB#TFI_CHVTWO#TFI_ITCNB' )
		lRet := lRet .And. !( cCpoAval $ 'TFI_CODTGQ#TFI_ITTGR#TFI_CODATD#TFI_NOMATD#TFI_CONENT#TFI_CONCOL#TFI_ENCE#TFI_DTPFIM' )
	ElseIf cTab == 'ABP'
		If cCpoAval == "ABP_ITEM"
			lRet := .T.
		Else		
			lRet := !( cCpoAval $ 'ABP_COD#ABP_REVISA#ABP_CODPRO#ABP_ENTIDA#ABP_ITRH#ABP_ITEMPR' )
		EndIf			
	ElseIf cTab == 'TFG'
		lRet := !( cCpoAval $ 'TFG_COD#TFG_LOCAL#TFG_CODPAI#TFG_SLD#TFG_CODSUB#TFG_COBCTR#TFG_CHVTWO#TFG_ITCNB#TFG_CONTRT#TFG_CONREV' )
	ElseIf cTab == 'TFH'
		lRet := !( cCpoAval $ 'TFH_COD#TFH_LOCAL#TFH_CODPAI#TFH_SLD#TFH_CODSUB#TFH_COBCTR#TFH_CHVTWO#TFH_ITCNB#TFH_CONTRT#TFG_CONREV' )
	ElseIf cTab == 'TFU'
		lRet := !( cCpoAval $ 'TFU_CODIGO#TFU_CODTFF#TFU_LOCAL' )
	ElseIf cTab == 'TEV'
		lRet := !( cCpoAval $ 'TEV_CODLOC#TEV_SLD' )
	ElseIf cTab == 'TWO'
		lRet := !( cCpoAval $ 'TWO_CODORC#TWO_PROPOS#TWO_OPORTU#TWO_LOCAL' )
	Else
		lRet := .F.
	EndIf
Else
	lRet := .F.
EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740SubTot
	Inicializa o subtotal da linha
@sample 	At740SubTot() 
@since		12/09/2013       
@version	P11.90
@return 	nValor, NUMERIC, valor da multiplicação do preço unitário com a quantidade
/*/
//------------------------------------------------------------------------------
Function At740SubTot()

Local nValor     := 0
Local oMdlAtivo  := FwModelActive()
Local oMdlGrid   := Nil

If oMdlAtivo <> Nil .And. (oMdlAtivo:GetId()=="TECA740" .Or. oMdlAtivo:GetId()=="TECA740F")
	
	oMdlGrid := oMdlAtivo:GetModel( "TEV_ADICIO" )
	
	If oMdlGrid:GetLine()<>0
		
		nValor := oMdlGrid:GetValue("TEV_VLRUNI") * oMdlGrid:GetValue("TEV_QTDE")
	EndIf

EndIf

Return nValor

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740Cmt
	Realizar a gravação dos dados
@sample 	At740Cmt() 
@since		20/09/2013       
@version	P11.90
@return 	oModel, Object, instância do modelo de dados MpFormModel
/*/
//------------------------------------------------------------------------------
Function At740Cmt( oModel )

Local lRet := .T.
Local aCriaSb2 := {}
Local nLocais := 0
Local nRHs    := 0
Local nMateriais := 0
Local lSeqTrn    := (TFF->(FieldPos("TFF_SEQTRN"))>0)
Local lOrcPrc	 := SuperGetMv("MV_ORCPRC",,.F.)
Local aRows    := {}
Local aItemRH  := {}
Local lGrvOrc	 := At740GCmt()
Local nForcaCalc 	:= 1
Local nMaxRhs 		:= 0
Local oStrTFG	:= oModel:GetModel("TFG_MI"):GetStruct()
Local oStrTFH	:= oModel:GetModel("TFH_MC"):GetStruct()
Local nMatImp	:= 1
Local nMatCons	:= 1
Local nLocais	:= 1
Local nRecursos := 1
Local lFillPropVist 	:= ( IsInCallStack('FATA600') .Or. IsInCallStack('TECA270') )
Local lSrvExt   := IsInCallStack('At020VlMVC') .Or. IsInCallStack("TECA744A") //Quando for inclusão de RESERVA pelo cadastro de atendente.

// ---------------------------------------------------
// Atualiza as informações dos recursos humanos calculando conforme o preenchimento
If lOrcPrc .And. oModel:GetOperation() <> MODEL_OPERATION_DELETE
	// habilita o cálculo usando a planilha de precificação do orçamento de serviços
	At740GSC(.T.)
	
	For nLocais := 1 To oModel:GetModel('TFL_LOC'):Length()
		
		oModel:GetModel('TFL_LOC'):GoLine( nLocais )
		nMaxRhs := oModel:GetModel('TFF_RH'):Length()
		For nRHs := 1 To nMaxRhs
			
			oModel:GetModel('TFF_RH'):GoLine( nRHs )
			
			// Antes de Utilizar qualquer valor da tabela de precificação efetua o calculo
			If !oModel:GetModel('TFF_RH'):IsDeleted() .And. ; // Linhas não deletadas 
				!Empty(oModel:GetModel('TFF_RH'):GetValue('TFF_PRODUT')) .And. ; // itens preenchidos
				oModel:GetModel('TFF_RH'):GetValue('TFF_COBCTR') <> '2' // pertence ao contrato
				// verifica se é o último item para forçar atualização dos acumuladores base para impostos				
				If nRHs == nMaxRhs
					nForcaCalc := 2
				Else
					nForcaCalc := 1
				EndIf
				// Identifica o objeto conforme o array com as planilhas / FwWorkSheet
				// Captura as tabela de precificação em uso pelo orçamento de serviços
				// modelo para captura do preenchimento e dados
				Processa( {|| ( At740EEPC( At740FGSS(oModel), At740FORC(), oModel, , nForcaCalc ) ) }, STR0082, STR0083,.F.) // "Aguarde..." ### "Executando cálculo ..."
			EndIf
		Next nRHs
	Next nLocais

	oModel:GetModel('TFJ_REFER'):LoadValue('TFJ_TABXML',At740FMXML(oModel))
	// desabilita os cálculos
	At740GSC(.F.)
EndIf

If lGrvOrc
	
	If oModel:GetOperation() == MODEL_OPERATION_DELETE
		lRet := FwFormCommit( oModel )
	Else
		//----------------------------------------------------------
		//  Identifica os produtos que ainda não estão com o saldo inicial
		// criado
		aRows := FwSaveRows()
		
		DbSelectArea('SB1')
		SB1->( DbSetOrder( 1 ) ) // B1_FILIAL+B1_COD
		
		DbSelectArea('SB2')
		SB2->( DbSetOrder( 1 ) ) // B2_FILIAL+B2_COD+B2_LOCAL
		
		If !lOrcPrc
			For nLocais := 1 To oModel:GetModel('TFL_LOC'):Length()
				
				oModel:GetModel('TFL_LOC'):GoLine( nLocais )
				
				aItemRH := {}

				For nRHs := 1 To oModel:GetModel('TFF_RH'):Length()
					
					oModel:GetModel('TFF_RH'):GoLine( nRHs )
									
					// pesquisa os produtos que não possuem registro criado na tabela SB2
					At740AvSb2(aCriaSb2, oModel)
							
					If oModel:GetModel("TFF_RH"):GetValue("TFF_COBCTR") == "2" .And. (IsInCallStack("At870GerOrc") .Or. lSrvExt) // Verifica as operações dos itens extras.
					
						lRecLock := At740VldTFF(	oModel:GetModel("TFL_LOC"):GetValue("TFL_CONTRT"),;
													oModel:GetModel("TFF_RH"):GetValue("TFF_COD"),;
													xFilial("TFF", cFilAnt),;
													lSrvExt,;
													oModel:GetModel("TFL_LOC"):GetValue("TFL_CODPAI")) 		
					
						Aadd(aItemRH,{ oModel:GetModel("TFF_RH"):GetValue("TFF_PRODUT"),;
										 oModel:GetModel("TFF_RH"):GetValue("TFF_CARGO")	,;
										 oModel:GetModel("TFF_RH"):GetValue("TFF_FUNCAO"),;
										 oModel:GetModel("TFF_RH"):GetValue("TFF_PERINI"),;
										 oModel:GetModel("TFF_RH"):GetValue("TFF_PERFIM"),;
										 oModel:GetModel("TFF_RH"):GetValue("TFF_TURNO")	,;
										 oModel:GetModel("TFF_RH"):GetValue("TFF_QTDVEN"),;
										 oModel:GetModel("TFF_RH"):GetValue("TFF_COD"),;
										 If( lSeqTrn, oModel:GetModel("TFF_RH"):GetValue("TFF_SEQTRN"), "" ),;								  
										 lRecLock,;
										 xFilial("TFF", cFilAnt),;	
										 oModel:GetModel("TFF_RH"):GetValue("TFF_ESCALA"),;
										 oModel:GetModel("TFF_RH"):GetValue("TFF_CALEND"),;
										 oModel:GetModel("TFF_RH"):GetValue("TFF_RISCO") } )
										
					EndIf
				
				Next nRHs
			
				If Len(aItemRH) > 0 // Cria a configuração de alocação para os itens extras
					At850CnfAlc(	oModel:GetModel("TFL_LOC"):GetValue("TFL_CONTRT"),;
								 	oModel:GetModel("TFL_LOC"):GetValue("TFL_LOCAL"),;
								 	aItemRH,;
								 	Iif(lSrvExt,oModel:GetModel("TFL_LOC"):GetValue("TFL_CODPAI"),"") )
				
					//Cria a integração para o MDT
					If lSigaMdtGS				
						At850TarEx(oModel:GetModel("TFL_LOC"):GetValue("TFL_LOCAL"),aItemRH)
					EndIf	
				Endif
			
			Next nLocais
			
		Else // Carregar modelo novo de materiais
			
			For nLocais := 1 To oModel:GetModel('TFL_LOC'):Length()
				
				oModel:GetModel('TFL_LOC'):GoLine( nLocais )
			
				// pesquisa os produtos que não possuem registro criado na tabela SB2
				At740AvSb2(aCriaSb2, oModel)
				
			Next nLocais
		EndIf
			 
		FwRestRows( aRows )
		
		// Captura e repassa quando é atualização da vistoria
		aVistoria := N600GetVis()
		// não define a origem como vistoria quando está importando para a proposta comercial
		If aVistoria[1] .And. IsInCallStack("A600IMPVIS")
			aVistoria[1] := .F.
		EndIf
		If lFillPropVist
			SetDadosOrc( aVistoria[1], aVistoria[2], oModel )
		EndIf

		lRet := FwFormCommit( oModel )
		
		//--------------------------------------------
		//  Cria o saldo inicial dos produtos não encontrados na SB2
		For nMateriais := 1 To Len( aCriaSb2 )
			CriaSb2( aCriaSb2[nMateriais,1], aCriaSb2[nMateriais,2] )
		Next nMateriais
		
		//--------------------------------------------
		//  Chama a rotina para cancelamento das reservas
		If lRet .And. Len(aCancReserv) > 0
			At740FinRes( oModel, .T. )
		EndIf
		
		//---------------------------------------------
		//  Elimina as informações de controle do orçamento com precificação
		If lOrcPrc
			AT740FGXML(,,.T.)
			At600STabPrc( "", "" )
		EndIf
	EndIf
Else
	cXmlDados := ( oModel:GetXmlData(Nil, Nil, Nil, Nil, Nil, .T. ))
EndIf

If Type('nSaveSx8Len') <> 'U'
	While ( GetSx8Len() > nSaveSx8Len )
		ConfirmSX8()
	End	
EndIf

cXmlCalculo  := ''

Return lRet

/*/{Protheus.doc} At740AvSb2
	Verifica se os produtos indicados nos materiais possuem saldo indicado na tabela SB2
@sample 	At740AvSb2(aCriaSb2, oModel)
@since		20/10/2015       
@version	P12
@param aCriaSB2, Array, variável que conterá a lista no formato { codigo produto, código local } que deverá ter o conteúdo gerado
@param oModelGeral, Objeto, modelo do tipo TECA740 ou TECA740F para avaliação dos produtos sem o registro de saldo na tabela SB2
/*/
Static Function At740AvSb2( aCriaSb2, oModelGeral )
Local nMateriais := 0
Local oMdlParte  := Nil

oMdlParte := oModelGeral:GetModel('TFG_MI')
For nMateriais := 1 To oMdlParte:Length()
	
	oMdlParte:GoLine( nMateriais )
	
	If !oMdlParte:IsDeleted() .And. ;
		aScan( aCriaSb2, {|pos| pos[1]==oMdlParte:GetValue('TFG_PRODUT') } ) == 0 .And. ;
		SB1->( DbSeek( xFilial('SB1')+oMdlParte:GetValue('TFG_PRODUT') ) ) .And. ;
		SB2->( !DbSeek( xFilial('SB2')+SB1->(B1_COD+B1_LOCPAD) ) )
		
		aAdd( aCriaSb2, { SB1->B1_COD, SB1->B1_LOCPAD } )
	EndIf
	
Next nMateriais

oMdlParte := oModelGeral:GetModel('TFH_MC')
For nMateriais := 1 To oMdlParte:Length()
	oMdlParte:GoLine( nMateriais )
	
	If !oMdlParte:IsDeleted() .And. ;
		aScan( aCriaSb2, {|pos| pos[1]==oMdlParte:GetValue('TFH_PRODUT') } ) == 0 .And. ;
		SB1->( DbSeek( xFilial('SB1')+oMdlParte:GetValue('TFH_PRODUT') ) ) .And. ;
		SB2->( !DbSeek( xFilial('SB2')+SB1->(B1_COD+B1_LOCPAD) ) )
		
		
		aAdd( aCriaSb2, { SB1->B1_COD, SB1->B1_LOCPAD } )
	EndIf
Next nMateriais

oMdlParte := oModelGeral:GetModel('TFJ_REFER')
// produto referência de RH
If !Empty(oMdlParte:GetValue('TFJ_GRPRH')) .And. ;
	aScan( aCriaSb2, {|pos| pos[1]==oMdlParte:GetValue('TFJ_GRPRH') } ) == 0 .And. ;
	SB1->( DbSeek( xFilial('SB1')+oMdlParte:GetValue('TFJ_GRPRH') ) ) .And. ;
	SB2->( !DbSeek( xFilial('SB2')+SB1->(B1_COD+B1_LOCPAD) ) )
	
	aAdd( aCriaSb2, { SB1->B1_COD, SB1->B1_LOCPAD } )
EndIf

// produto referência de MC
If !Empty(oMdlParte:GetValue('TFJ_GRPMC')) .And. ;
	aScan( aCriaSb2, {|pos| pos[1]==oMdlParte:GetValue('TFJ_GRPMC') } ) == 0 .And. ;
	SB1->( DbSeek( xFilial('SB1')+oMdlParte:GetValue('TFJ_GRPMC') ) ) .And. ;
	SB2->( !DbSeek( xFilial('SB2')+SB1->(B1_COD+B1_LOCPAD) ) )
	
	aAdd( aCriaSb2, { SB1->B1_COD, SB1->B1_LOCPAD } )
EndIf

// produto referência de MI
If !Empty(oMdlParte:GetValue('TFJ_GRPMI')) .And. ;
	aScan( aCriaSb2, {|pos| pos[1]==oMdlParte:GetValue('TFJ_GRPMI') } ) == 0 .And. ;
	SB1->( DbSeek( xFilial('SB1')+oMdlParte:GetValue('TFJ_GRPMI') ) ) .And. ;
	SB2->( !DbSeek( xFilial('SB2')+SB1->(B1_COD+B1_LOCPAD) ) )
	
	aAdd( aCriaSb2, { SB1->B1_COD, SB1->B1_LOCPAD } )
EndIf

// produto referência de LE
If !Empty(oMdlParte:GetValue('TFJ_GRPLE')) .And. ;
	aScan( aCriaSb2, {|pos| pos[1]==oMdlParte:GetValue('TFJ_GRPLE') } ) == 0 .And. ;
	SB1->( DbSeek( xFilial('SB1')+oMdlParte:GetValue('TFJ_GRPLE') ) ) .And. ;
	SB2->( !DbSeek( xFilial('SB2')+SB1->(B1_COD+B1_LOCPAD) ) )
	
	aAdd( aCriaSb2, { SB1->B1_COD, SB1->B1_LOCPAD } )
EndIf
			
Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740Canc
	Bloco no momento de cancelamento dos dados da rotina
@sample 	At740Canc() 
@since		03/10/2013       
@version	P11.90
@return 	oModel, Object, Classo do modelo de dados MpFormModel
/*/
//------------------------------------------------------------------------------
Function At740Canc( oMdl,b,c,d )

Local lOrcPrc	 := SuperGetMv("MV_ORCPRC",,.F.)

If Type('nSaveSx8Len') <> 'U'
	While ( GetSx8Len() > nSaveSx8Len )
		RollBackSX8()
	End	
EndIf

cXmlCalculo  := ''

If Len(aCancReserv) > 0
	At740FinRes( oMdl, .F. )
EndIf
//  Só chama a limpeza das variáveis static do 740F quando não está copiando os dados 
// para o objeto sem interface ligado ao modelo da proposta comercial
If lOrcPrc .And. !IsInCallStack('At600SeAtu')
	AT740FGXML(nil,nil,.T.) 
EndIf

At740GSC(.F.)

Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} AtIniPadMvc
	Função para inicializador padrão genérico de descrição ou conteúdos relacionados
a uma chave

@sample 	AtIniPadMvc( "TECA740", "TEV_ADICIO", cTab, nInd, cKey, cCampo, cFormula )
@sample 	AtIniPadMvc( "TECA740", "TEV_ADICIO", , , , , 'FWFLDGET("TEV_VLRUNI") * FWFLDGET("TEV_QTDE")' )

@since		23/09/2013       
@version	P11.90

@return 	xConteudo, Qualquer, retorna o conteúdo conforme a pesquisa ou tipo do campo

@param  	cIdMdlMain, Objeto, id do objeto do modelo de dados principal
@param  	cIdMdlGrd, Objeto, id do objeto do modelo do grid
@param  	cCampo, Caracter, Conteúdo a ser retornado quando a pesquisa ocorrer com sucesso
				ou o campo alvo para recepção do valor (quando usado fórmula)
@param  	cTab, Caracter, nome da tabela para pesquisa
@param  	nInd, Numerico, índice para ordem na busca do registro
@param  	cKey, Caracter, chave de pesquisa do registro
@param  	cFormula, Caracter, conteúdo para ser macro executado
/*/
//------------------------------------------------------------------------------
Function AtIniPadMvc( cIdMdlMain, cIdMdlGrd, cCampo, cTab, nInd, cKey, cFormula, cTipoDefault )

Local xConteudo := Nil
Local cTipo     := ""
Local oMdlAtivo := FwModelActive()
Local lOrcPrc 	:= SuperGetMv("MV_ORCPRC",,.F.)
Local lOrcServ	:= cIdMdlMain $ "TECA740|TECA740F|TECA744"
Local lFacilit 	:= cIdMdlMain = "TECA984"
Local lExecuta 	:= .F.
Local cCodAux 	:= ""

cTipo := If( cCampo<>Nil, GetSx3Cache( PadR( cCampo, 10 ), 'X3_TIPO' ), If( cTipoDefault<>Nil, cTipoDefault, Nil ) )

If !Empty(cTipo)
	If cTipo $ 'C#M'
		xConteudo := ''		
	ElseIf cTipo == 'N'
		xConteudo := 0	
	ElseIf cTipo == 'D'
		xConteudo := CtoD('')	
	ElseIf cTipo == 'L'
		xConteudo := .F.		
	EndIf
Else 	
	xConteudo := ''
EndIf

If oMdlAtivo <> Nil .And. ;
	( oMdlAtivo:GetId() == cIdMdlMain .Or. ( lOrcPrc .And. oMdlAtivo:GetId() == "TECA740F" ) ).And. ;
	oMdlAtivo:GetModel( cIdMdlGrd ) <> Nil .And. oMdlAtivo:GetModel( cIdMdlGrd ):GetOperation() <> MODEL_OPERATION_INSERT

	If oMdlAtivo:GetModel( cIdMdlGrd ):GetLine() == 0 // a linha posicionada do grid
		If lOrcServ 
			If (Left( cIdMdlGrd, 3 ) == "TFL" .Or. !oMdlAtivo:GetModel( "TFL_LOC" ):IsInserted())
				If Left( cIdMdlGrd, 3 ) <> "TFL"
					cCodAux := oMdlAtivo:GetModel("TFL_LOC"):GetValue("TFL_CODIGO")
				Else
					cCodAux := ""
				EndIf
				lExecuta := At740IsOrc( cIdMdlGrd, TFJ->TFJ_CODIGO, cCodAux, oMdlAtivo )
			EndIf
		ElseIf lFacilit
			cCodAux := If( lOrcPrc, "", TWN->TWN_ITEMRH )
			lExecuta := At984IsFac(cIdMdlGrd, TWM->TWM_CODIGO, cCodAux)
		Else
			lExecuta := .T.
		EndIf
		
		If lExecuta
			If !Empty( cFormula )
				If !( 'FWFLDGET' $ Upper( cFormula ) )  // verifica se tem get de conteúdo da linha do model
					xConteudo := &cFormula
				EndIf
			Else
				cKey := &cKey
				xConteudo := GetAdvFVal( cTab, cCampo, cKey, nInd, xConteudo )
			EndIf
		EndIf
	ElseIf !(oMdlAtivo:GetModel( cIdMdlGrd ):IsInserted())
		If !Empty( cFormula )
			xConteudo := &cFormula
		EndIf
	EndIf
EndIf

Return xConteudo

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740TrgGer
	Função para preencher o conteúdo de grids superiores com a somatória

@sample 	At740TrgGer( "CALC_TFH", "TOT_MC", "TFF_RH", "TFF_TOTMC" )

@since		23/09/2013       
@version	P11.90

/*/
//------------------------------------------------------------------------------
Function At740TrgGer( cMdlCalc, cCpoTot, cMdlCDom, cCpoCDOM, cCpoDesc )

Local nValor := 0
Local oMdl   := FwModelActive()

Default cCpoDesc := ''

If oMdl:GetId()=='TECA740' .Or. oMdl:GetId()=='TECA740F' 
	nValor := oMdl:GetModel( cMdlCalc ):GetValue( cCpoTot )

	If !Empty( cCpoDesc )
		nValor := ( nValor * ( 1 - ( oMdl:GetModel( cMdlCDom ):GetValue( cCpoDesc ) / 100 ) ) )
	EndIf

	oMdl:GetModel( cMdlCDom ):SetValue( cCpoCDOM, nValor )

EndIf

Return 0


//------------------------------------------------------------------------------
/*/{Protheus.doc} At740TrgABN
	

@sample 	At740TrgABN()

@since		23/09/2013       
@version	P11.90

/*/
//------------------------------------------------------------------------------
Function At740TrgABN()

Local cCodAbn  := ""
Local cRetABN	 := ""
Local oMdl   	 := FwModelActive()
Local aAreaABN := ABN->(GetArea())

If oMdl:GetId()=="TECA740" .Or. oMdl:GetId()=="TECA740F" 

	cCodAbn := oMdl:GetModel( "TFU_HE" ):GetValue( "TFU_CODABN" )
	
	ABN->(dbSetOrder(1))
	If ABN->(dbSeek(xFilial("ABN")+cCodAbn))
		cRetABN := ABN->ABN_DESC
	EndIf
	
EndIf

RestArea(aAreaABN)

Return(cRetABN)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740TrgTEV
	Dispara o preenchimento do campo de unidade de medida
@sample 	At740TrgTEV()

@since		23/09/2013       
@version	P11.90

@param   	cCpoOrigem, Caracter, Id do campo que disparou o gatilho
@return  	xRet, Qualquer, conteúdo a ser inserido no contra-domínio
/*/
//------------------------------------------------------------------------------
Function At740TrgTEV( cCpoOrigem )

Local xRet := Nil

If cCpoOrigem == 'TEV_MODCOB'

	If M->TEV_MODCOB == '2'  // Modo de Cobrança igual a disponibilidade
		xRet := 'UN'
	ElseIf M->TEV_MODCOB == '4' .Or. M->TEV_MODCOB == '5'  // Modo de Cobrança igual a horimetro
		xRet := 'HR'
	Else
		xRet := '  '
	EndIf

EndIf

Return xRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740DeBenefi
	Função executada no gatilho do código do benefício para captura da descrição

@sample 	At740DeBenefi()

@since		27/11/2013       
@version	P11.90
/*/
//------------------------------------------------------------------------------
Function At740DeBenefi()

Local cRet := ' '

DbSelectArea('SX5')
SX5->( DbSetOrder( 1 ) )

If SX5->( DbSeek( xFilial("SX5")+"AZ"+M->ABP_BENEFI) )
	cRet := X5Descri()
EndIf

Return cRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} InitDados
	

@sample 	InitDados(  )

@since		23/09/2013
@version	P11.90

@param  	oMdlGer, Objeto, objeto geral do model que será alterado

/*/
//------------------------------------------------------------------------------
Static Function InitDados ( oMdlGer )
Local oMdlCab 	:= oMdlGer:GetModel('TFJ_REFER')
Local oMdlLoc	:= oMdlGer:GetModel("TFL_LOC")
Local oMdlRh	:= oMdlGer:GetModel("TFF_RH")
Local oMdlMi	:= oMdlGer:GetModel("TFG_MI")
Local oMdlMc	:= oMdlGer:GetModel("TFH_MC")
Local oMdlHe	:= oMdlGer:GetModel("TFU_HE")
Local nLinLoc	:= 0
Local nLinRh	:= 0
Local nLinHe	:= 0
Local aSaveRows := {}
Local nTotGerMI := 0
Local nTotGerMC := 0
Local nTotGerLE := 0
Local nTotGerRH := 0
Local nTotGeral := 0
Local nTotMI    := 0
Local nTotMC    := 0
Local nTotal    := 0
Local cGsDsGcn	:= ""
Local cIsGsMt	:= ""
Local cGsMtMi	:= ""
Local cGsMtMc	:= ""
Local oStrTFJ 	:= oMdlCab:GetStruct()
Local oStrTFG	:= oMdlMi:GetStruct()
Local oStrTFH	:= oMdlMc:GetStruct()
Local oView 	:= FwViewActive()
Local bWhen		:= {|| .T. }
Local oStruct 	:= Nil

If IsInCallStack("At870Revis") //Liberar alteração da data final dos itens MI e MC quando for revisão de contrato
	oStrTFG:SetProperty( "TFG_PERFIM", MODEL_FIELD_WHEN,{|| .T. })
	oStrTFH:SetProperty( "TFH_PERFIM", MODEL_FIELD_WHEN,{|| .T. })	
EndIf

If oMdlGer:GetOperation() == MODEL_OPERATION_INSERT .And. !IsInCallStack("TECA870")
	cGsDsGcn	:= SuperGetMv("MV_GSDSGCN",,"2")
	cIsGsMt		:= SuperGetMv("MV_ISGSMT",,"2")
Else
	cGsDsGcn	:= oMdlCab:GetValue("TFJ_DSGCN")
	cIsGsMt		:= oMdlCab:GetValue("TFJ_ISGSMT")
	If cIsGsMt == "1"
		cGsMtMi		:= oMdlCab:GetValue("TFJ_GSMTMI")
		cGsMtMc		:= oMdlCab:GetValue("TFJ_GSMTMC")
	Endif
EndIf

If cGsDsGcn == "1"
	//Retira a obrigatoriedade dos campos
	oStrTFJ:SetProperty('TFJ_GRPRH',MODEL_FIELD_OBRIGAT,.F.)
	oStrTFJ:SetProperty('TFJ_GRPMI',MODEL_FIELD_OBRIGAT,.F.)
	oStrTFJ:SetProperty('TFJ_GRPMC',MODEL_FIELD_OBRIGAT,.F.)
	oStrTFJ:SetProperty('TFJ_GRPLE',MODEL_FIELD_OBRIGAT,.F.)
	oStrTFJ:SetProperty('TFJ_TES',MODEL_FIELD_OBRIGAT,.F.)
	oStrTFJ:SetProperty('TFJ_TESMI',MODEL_FIELD_OBRIGAT,.F.)
	oStrTFJ:SetProperty('TFJ_TESMC',MODEL_FIELD_OBRIGAT,.F.)
	oStrTFJ:SetProperty('TFJ_TESLE',MODEL_FIELD_OBRIGAT,.F.)
	//Novos campos de TES obrigatórios
	
	oMdlGer:GetModel('TFF_RH'):GetStruct():SetProperty('TFF_TESPED',MODEL_FIELD_OBRIGAT,.T.)
	oMdlGer:GetModel('TFG_MI'):GetStruct():SetProperty('TFG_TESPED',MODEL_FIELD_OBRIGAT,.T.)
	oMdlGer:GetModel('TFH_MC'):GetStruct():SetProperty('TFH_TESPED',MODEL_FIELD_OBRIGAT,.T.)
	oMdlGer:GetModel('TFI_LE'):GetStruct():SetProperty('TFI_TESPED',MODEL_FIELD_OBRIGAT,.T.)
EndIf

aSaveRows := FwSaveRows()

nTLuc := oMdlGer:GetModel("TFJ_REFER"):GetValue("TFJ_LUCRO")
nTAdm := oMdlGer:GetModel("TFJ_REFER"):GetValue("TFJ_ADM")

If oMdlGer:GetOperation() <> MODEL_OPERATION_DELETE

	For nLinLoc := 1 To oMdlLoc:Length()
	
		oMdlLoc:GoLine( nLinLoc )
		
		If !oMdlLoc:IsDeleted()
		
			For nLinRh := 1 to oMdlRh:Length()
			
				oMdlRh:GoLine( nLinRh )
				
				If !oMdlRh:IsDeleted()

					If cGsMtMi $ "2|3"
						nTotMI := oMdlRh:GetValue("TFF_VLMTMI")
					Else
						nTotMI := At600IniTot( 'TFG_MI', 'TFG_TOTGER', oMdlGer )					
					Endif

					If cGsMtMc $ "2|3"
						nTotMC := oMdlRh:GetValue("TFF_VLMTMC")
					Else
						nTotMC := At600IniTot( 'TFH_MC', 'TFH_TOTGER', oMdlGer )					
					Endif
											
					At740Set(oMdlRh, 'TFF_TOTMI', nTotMI )
					At740Set(oMdlRh, 'TFF_TOTMC', nTotMC )
					
					nTotGerRH := oMdlRh:GetValue('TFF_PRCVEN') * oMdlRh:GetValue('TFF_QTDVEN')
					
					At740Set(oMdlRh, 'TFF_SUBTOT', ( nTotGerRH + oMdlRh:GetValue('TFF_TXLUCR') + oMdlRh:GetValue('TFF_TXADM') ) )
					
					nTotal	:= At740InPad()
					
					At740Set(oMdlRh, 'TFF_TOTAL', nTotal )	
					
					//TODO incluir for na TFU e inicializar		(oMdlHE, 'TFU_VALOR', nValor )
							
				//	DbSelectArea('TFU')
				//	TFU->(DbSetOrder(1))
				//	For nLinHe := 1 To oMdlHe:Length()
				//		If oMdlHe:GetValue('TFU_TPCALC') == '2'
				//			If TFU->(DbSeek(xFilial('TFU') + oMdlHe:GetValue('TFU_CODIGO')))							
								
								
							//	bWhen 		:= oStruct:GetProperty('TFU_TPCALC',MODEL_FIELD_WHEN)
							//	oStruct:SetProperty('TFU_VALOR',MODEL_FIELD_WHEN,{|| .T. })
								
				//				At740Set(oMdlHe, 'TFU_VALOR', TFU->TFU_VALOR )	
							//	oMdlHe:LoadValue('TFU_VALOR',TFU->TFU_VALOR )
							//	oStruct:SetProperty('TFU_TPCALC',MODEL_FIELD_WHEN,bWhen)
			
				//			EndIf
				//		EndIf
				//	Next
			///	oStruct 	:= oMdlHe:GetStruct()
					//oStruct:SetProperty( "TFU_VALOR", MODEL_FIELD_WHEN,{|| !FwFldGet('TFU_VALOR') == 0 .Or. FwFldGet('TFU_TPCALC') == '1'  })
				EndIf
				
			Next nLinRh
			oMdlRh:GoLine( 1 )
			
			nTotGerMI	:= At600IniTot( 'TFF_RH', 'TFF_TOTMI', oMdlGer )
			nTotGerMC	:= At600IniTot( 'TFF_RH', 'TFF_TOTMC', oMdlGer )
			nTotGerLE	:= At600IniTot( 'TFI_LE', 'TFI_TOTAL', oMdlGer )
			nTotGerRH 	:= At600IniTot( 'TFF_RH', 'TFF_SUBTOT', oMdlGer )
			
			At740Set(oMdlLoc, 'TFL_TOTMI', nTotGerMI )
			At740Set(oMdlLoc, 'TFL_TOTMC', nTotGerMC )
			At740Set(oMdlLoc, 'TFL_TOTLE', nTotGerLE )
			At740Set(oMdlLoc, 'TFL_TOTRH', nTotGerRH )
			
			nTotGeral := nTotGerRH + nTotGerMI + nTotGerMC + nTotGerLE
			
			At740Set(oMdlLoc, 'TFL_TOTAL', nTotGeral )
						
		EndIf
	
	Next nLinLoc
	oMdlLoc:GoLine( 1 )
	
	If  oMdlGer:GetModel('TOTAIS')<>NIL
		At740Set(oMdlGer:GetModel("TFJ_REFER"), 'TFJ_TOTRH', oMdlGer:GetModel('TOTAIS'):GetValue('TOT_RH'))
		At740Set(oMdlGer:GetModel("TFJ_REFER"), 'TFJ_TOTMI', oMdlGer:GetModel('TOTAIS'):GetValue('TOT_MI'))
		At740Set(oMdlGer:GetModel("TFJ_REFER"), 'TFJ_TOTMC', oMdlGer:GetModel('TOTAIS'):GetValue('TOT_MC'))
		At740Set(oMdlGer:GetModel("TFJ_REFER"), 'TFJ_TOTLE', oMdlGer:GetModel('TOTAIS'):GetValue('TOT_LE'))
	EndIf
	
EndIf	

FwRestRows( aSaveRows )

If IsInCallStack("At870GerOrc") // Verifica as operações dos itens extras do contrato
	
	oMdlGer:GetModel("TFL_LOC"):SetNoInsertLine(.T.)
	oMdlGer:GetModel("TFL_LOC"):SetNoDeleteLine(.T.)
	oMdlGer:GetModel("TFL_LOC"):SetNoUpdateLine(.T.)
	
	oMdlGer:GetModel("TFF_RH"):SetNoInsertLine(.T.)
	oMdlGer:GetModel("TFF_RH"):SetNoDeleteLine(.T.)
	oMdlGer:GetModel("TFF_RH"):SetNoUpdateLine(.T.)
		
	oMdlGer:GetModel("TFG_MI"):SetNoInsertLine(.T.)
	oMdlGer:GetModel("TFG_MI"):SetNoDeleteLine(.T.)
	oMdlGer:GetModel("TFG_MI"):SetNoUpdateLine(.T.)
	
	oMdlGer:GetModel("TFH_MC"):SetNoInsertLine(.T.)
	oMdlGer:GetModel("TFH_MC"):SetNoDeleteLine(.T.)
	oMdlGer:GetModel("TFH_MC"):SetNoUpdateLine(.T.)

EndIf

If oMdlGer:GetOperation() <> MODEL_OPERATION_INSERT
	oMdlGer:GetModel('TFL_LOC'):GoLine( 1 )
EndIf

If oMdlGer:GetOperation() == MODEL_OPERATION_VIEW
	oMdlGer:lModify := .F.
EndIf

Return


//------------------------------------------------------------------------------
/*/{Protheus.doc} At740Set
	

@sample 	At740Set( oModel, cField, xValue)

@since		23/09/2013
@version	P11.90

/*/
//------------------------------------------------------------------------------
Function At740Set(oModel, cField, xValue)

Local lRet := .T.

If oModel:GetOperation() == MODEL_OPERATION_VIEW .Or. ;
		oModel:GetOperation() == MODEL_OPERATION_DELETE		
	oModel:LoadValue( cField, xValue )
Else
	lRet := oModel:SetValue( cField, xValue )
EndIf
Return


//------------------------------------------------------------------------------
/*/{Protheus.doc} At600IniTot
	

@sample 	AT600INITOT( "TFH_MC", "TFH_TOTAL" )

@since		23/09/2013
@version	P11.90

@param cMdlAlvo, Caractere, Id do modelo de dados grid com o campo para soma do conteúdo
@param cCpoSoma, Caractere, Campo alvo para somar o conteúdo
@param oMdlGer, Objeto, objeto do mvc para considerar para realizar a soma do conteúdo, default: FwModelActive()
@return nValor, Numérico, valor correspondente a soma dos valores no campo nas linhas
/*/
//------------------------------------------------------------------------------
Function At600IniTot( cMdlAlvo, cCpoSoma, oMdlGer )

Local nValor    := 0
Local oMdlGrid  := Nil
Local nLinhaMdl := 0
Local aSaveRows := {}

Default oMdlGer := FwModelActive()

If oMdlGer <> Nil .And. (oMdlGer:GetId()=='TECA740' .Or. oMdlGer:GetId()=='TECA740F') 
	
	aSaveRows := FwSaveRows()
	
	oMdlGrid := oMdlGer:GetModel(cMdlAlvo)
	If !oMdlGrid:IsEmpty()
		// ----------------------------------------------------
		//   Varre as linhas do grid para capturar o conteúdo dos campos
		For nLinhaMdl := 1 To oMdlGrid:Length()
			
			oMdlGrid:GoLine( nLinhaMdl )
		
			If !oMdlGrid:IsDeleted()
				
				nValor += oMdlGrid:GetValue(cCpoSoma)
				
			EndIf
		
		Next nLinhaMdl
	EndIf
	FwRestRows( aSaveRows )

EndIf

Return nValor

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740CpyMdl
	Realiza a cópia dos dados de um modelo para outro
evitando sobrepor conteudo de alguns campos, informados na exceção

@sample 	At740CpyMdl

@since		23/09/2013
@version	P11.90

/*/
//------------------------------------------------------------------------------
Function At740CpyMdl( oObjFrom, oObjTo )

Local lRet      := .T.
Local lOrcPrecif := SuperGetMv("MV_ORCPRC",,.F.)
Local oStrTFJ := oObjTo:GetModel('TFJ_REFER'):GetStruct()
Local oStrTFF := oObjTo:GetModel('TFF_RH'):GetStruct()
Local oStrTFG := oObjTo:GetModel('TFG_MI'):GetStruct()
Local oStrTFH := oObjTo:GetModel('TFH_MC'):GetStruct()
Local oStrTFI := oObjTo:GetModel('TFI_LE'):GetStruct()

FillModel( @lRet, 'TFJ_REFER', oObjFrom, @oObjTo, lOrcPrecif )

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} FillModel
	Função para preenchimento dos dados do modelo indicado pelos parâmetros e 
identifica a necessidade de preenchimento de grid/modelos filhos

@sample 	FillModel

@since		23/09/2013
@version	P11.90

@param 		lRet, Logico, indice/define o status do processamento pela rotina (referência)
@param 		cIdMdl, Caracter, id do model a ser preenchido
@param 		oFrom, Objeto, Modelo de dados para cópia das informações
@param 		oTo, Objeto, Modelo de dados para inclusão das informações

/*/
//------------------------------------------------------------------------------
Static Function FillModel( lRet, cIdModl, oFrom, oTo, lOrcPrecif )

                      // ID_MODEL     CAMPO_CHAVE, LISTA_SUBMODELS
Local aElementos := { }
					// DEPOIS QUE DESENV BENEFICIOS TIRAR OS CAMPOS 'TFF_PDBENE', 'TFF_VLBENE', 'TFJ_TOTBE', 'TFL_TOTBE' 
Local aNoCpos  := {'TFJ_CODIGO', 'TFJ_PREVIS', 'TFL_CODIGO', 'TFL_CODPAI', 'TFF_COD', 'TFF_CODPAI', 'TFF_LOCAL', 'TFF_PROCES', 'TFG_COD', 'TFG_CODPAI', 'TFG_LOCAL', ;
						'TFH_COD', 'TFH_CODPAI', 'TFH_LOCAL','TFI_COD', 'TFI_CODPAI', 'TFI_LOCAL','ABP_ITRH', 'TEV_CODLOC', 'TFU_CODIGO', 'TFU_CODTFF',;
						'TFU_LOCAL','TGV_COD','TDT_COD','TDS_COD','TWO_CODORC','TWO_PROPOS','TWO_LOCAL' }
Local nPosElem := 0																	
Local nPosSub  := 0
Local oFromAux := 0
Local oToAux   := 0
Local nForTo   := 0
Local nSubMdls  := 0
Local aLocaisMdls := {}
Local aRhMdls 	:= {}

Default lOrcPrecif := .F.

// quando for o orçamento com precificação
// ajusta a estrutura hierárquica dos modelos deixando os materiais abaixo do local
If lOrcPrecif
	aLocaisMdls := { 'TFF_RH', 'TFG_MI', 'TFH_MC', 'TFI_LE', 'TWODETAIL' }
	aRhMdls := { 'ABP_BENEF', 'TFU_HE', 'TGV_RH', 'TDS_RH', 'TDT_RH' }
Else
	aLocaisMdls := { 'TFF_RH', 'TFI_LE', 'TWODETAIL' }
	aRhMdls := { 'ABP_BENEF', 'TFG_MI', 'TFH_MC', 'TFU_HE', 'TGV_RH', 'TDS_RH', 'TDT_RH' }
EndIf

                // ID_MODEL     CAMPO_CHAVE, LISTA_SUBMODELS
aElementos := { { 'TFJ_REFER' , ''         , { 'TFL_LOC' }} , ;
				{'TFL_LOC'   , 'TFL_LOCAL' , aLocaisMdls } , ;
					{'TFF_RH'    , 'TFF_PRODUT', aRhMdls } , ;
					{'ABP_BENEF' , 'ABP_BENEFI', {} }, ;
					{'TFG_MI'    , 'TFG_PRODUT', {} }, ;
					{'TFH_MC'    , 'TFH_PRODUT', {} }, ;
					{'TFU_HE'    , 'TFU_CODABN', {} }, ;
					{'TFI_LE'    , 'TFI_PRODUT', { 'TEV_ADICIO' } },  ;
					{'TEV_ADICIO', 'TEV_MODCOB', {} }, ; 
					{'TGV_RH'    , 'TGV_CURSO' , {} }, ;
					{'TDS_RH'    , 'TDS_CODTCZ', {} }, ;
					{'TDT_RH'    , {'TDT_CODHAB','TDT_HABX5'}, {} }, ;
					{'TWODETAIL', 'TWO_CODFAC', {} } ;
					}
/*
	ID_MODEL - identificador do model para cópia dos dados
	CAMPO_CHAVE - campo para verificar se é necessário copiar o conteúdo da linha (somente utilizado quando for grid)
	LISTA_SUBMODELS - 
*/

nPosElem := aScan( aElementos, {|x| x[1]==cIdModl} )
nPosSub  := 0

oFromAux := oFrom:GetModel( aElementos[nPosElem,1] )
oToAux   := oTo:GetModel( aElementos[nPosElem,1] )

//  caso os totalizadores estejam habilitados para a rotina
// inibe a cópia dos campos que são totalizados por gatilhos
If oToAux:ClassName()=='FWFORMGRID'

	For nForTo := 1 To oFromAux:Length()
	
		oFromAux:GoLine( nForTo )
		
		// verifica se o campo principal do grid está preenchido, ou seja
		// se há necessidade de copiar
		If !oFromAux:IsDeleted() .And. ;
			At740VlEmpty( aElementos[nPosElem,2], oFromAux )
			
			// testa quando é necessário adicionar uma nova linha
			If At740VlEmpty( aElementos[nPosElem,2], oToAux )
				oToAux:AddLine()
			EndIf
			
			lRet := AtCpyData( oFromAux, oToAux, aNoCpos )
			
			If lRet
				For nSubMdls := 1 To Len( aElementos[nPosElem,3] )
					cIdModl := aElementos[nPosElem,3,nSubMdls]
					
					FillModel( @lRet, cIdModl, oFrom, oTo, lOrcPrecif )
					
					If !lRet
						Exit
					EndIf
					
				Next nSubMdls
			
			EndIf
			
		EndIf
		
		If !lRet
			Exit
		EndIf
		
	Next nForTo

Else
	
	lRet := AtCpyData( oFromAux, oToAux, aNoCpos )
	
	If lRet
		For nSubMdls := 1 To Len( aElementos[nPosElem,3] )
			cIdModl := aElementos[nPosElem,3,nSubMdls]
			 
			FillModel( @lRet, cIdModl, oFrom, oTo, lOrcPrecif  )
			
			If !lRet
				Exit
			EndIf
			
		Next nSubMdls
	
	EndIf
	
EndIf

Return

/*/{Protheus.doc} At740VlEmpty
	Função para verificar se o campo chave de preenchimento do grid está com conteúdo válido
@sample 	At740VlEmpty( aElementos[nPosElem,2], oFromAux )
@since		11/03/2016
@version	P2

@param 		xLista, Caracter ou Array, indica o campo ou a lista de campos a terem o conteúdo verificado
@param 		oMdlAlvo, Objeto FwFormGridModel ou FwFormFieldsModel, modelo de dados a receber a verificação do campo
@return 	lRet, Logico, indica se o campo está com conteúdo (.T.) ou não (.F.)
/*/
Static Function At740VlEmpty( xLista, oMdlAlvo )

Local lPreenchido := .F.
Local nI := 0

Default xLista := ""
// verifica o conteúdo no campo quando é caracter
If ValType(xLista)=="C" .And. !Empty(xLista) .And. !Empty(oMdlAlvo:GetValue(xLista))
	lPreenchido := .T.
// verifica o conteúdo nos campos quando é array
ElseIf ValType(xLista)=="A" .And. !Empty(xLista)

	For nI := 1 To Len(xLista)
		// ao identificar algum campo preenchido (condição OU para o preenchimento dos campos)
		// já encerra o loop
		lPreenchido := !Empty(oMdlAlvo:GetValue(xLista[nI]))
		If lPreenchido
			Exit
		EndIf
	Next nI
EndIf
Return lPreenchido

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740InPad
	
Função para inicializador padrão do total 

@sample 	AtIniPadMvc()

@since		02/10/2013       
@version	P11.90

@return 	nRet, retorna o resultado do cálculo

/*/
//------------------------------------------------------------------------------
Function At740InPad(oMdl)

Local aArea	:= GetArea()
Local oModel	:= If( oMdl == nil, FwModelActive(), oMdl)
Local oMdlRh	:= nil
Local nTotRh 	:= 0
Local nTotMI	:= 0
Local nTotMC	:= 0
Local nRet		:= 0

If oModel <> nil .and. oModel:GetID() $ 'TECA740;TECA740F' 
	oMdlRh	:= oModel:GetModel("TFF_RH")
	nTotRh	:= oMdlRh:GetValue("TFF_SUBTOT")
	nTotMI	:= oMdlRh:GetValue("TFF_TOTMI")
	nTotMC	:= oMdlRh:GetValue("TFF_TOTMC")
EndIf

nRet := nTotRh+nTotMI+nTotMC
			
RestArea(aArea)

Return nRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740InSub
	
Função para calcular SubTotal da Aba Recursos Humanos

@sample 	At740InSub()

@since		02/10/2013       
@version	P12

@return 	nRet, retorna o resultado do cálculo

/*/
//------------------------------------------------------------------------------
Function At740InSub()
Local aArea	:= GetArea()
Local oModel	:= FwModelActive()
Local oMdlRh	:= oModel:GetModel("TFF_RH")
Local nQtde	:= 	oMdlRh:GetValue("TFF_QTDVEN")
Local nTotRh 	:= oMdlRh:GetValue("TFF_PRCVEN")
Local nLucro	:= oMdlRh:GetValue("TFF_TXLUCR")
Local nTxAdm	:= oMdlRh:GetValue("TFF_TXADM")
Local nRet		:= 0

//Arredondo valores conforme tamanho do campos campos
nLucro := Round(nLucro,TamSX3("TFF_TXLUCR")[2])
nTxAdm := Round(nTxAdm,TamSX3("TFF_TXADM")[2])

nRet := (nQtde*nTotRh)+nLucro+nTxAdm
			
RestArea(aArea)

Return nRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740CDesc
	
Função para cálcular o desconto do produto.

@sample 	At740CDesc(cMdlDom,cCmpQtd,cCmpVlr,cCmpDesc,cCmpAlvo)

@since		02/10/2013      
@version	P11.90

@return 	nResp, Númerico, retorna o conteúdo do cálculo. 

@param  	cMdlDom, Caracter, nome do modelo de dados principal
@param  	cCmpQtd, Caracter, nome do campo para cálculo
@param  	cCmpVlr, Caracter, nome do campo para cálculo
@param  	cCmpDesc, Caracter, nome do campo para cálculo
@param  	cCmpAlvo, Caracter, nome do campo para receber resultado
/*/
//------------------------------------------------------------------------------
Function At740CDesc(cMdlDom,cCmpQtd,cCmpVlr,cCmpDesc,cCmpAlvo)

Local oModel	:= FwModelActive()
Local oMdlPr	:= oModel:GetModel(cMdlDom)
Local nQtd		:= oMdlPr:GetValue(cCmpQtd)
Local nVlr		:= oMdlPr:GetValue(cCmpVlr)
Local nDesc	:= oMdlPr:GetValue(cCmpDesc)
Local nResp	:= 0

nResp := (nQtd*nVlr)*(1-(nDesc/100))

//Adicionar o valor das taxas de lucro e administrativas ao valor do SubTotal
If cCmpDesc == "TFF_DESCON"
	nResp := nResp+oMdlPr:GetValue("TFF_TXLUCR")+oMdlPr:GetValue("TFF_TXADM")
EndIf

oMdlPr:SetValue( cCmpAlvo, nResp )

Return nResp

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740VldDt
	
Função para validação dos períodos iniciais e finais dos materiais e alocações.

@sample 	At740VldDt(cModelo,cCpoSelec,cCpoDtIn,cCpoDtFm)

@since		02/10/2013      
@version	P11.90

@return 	lRet, Lógico, retorna .T. se data for válida.

@param  	cModelo, Caracter, nome do modelo de dados principal.
@param  	cCpoSelec, Caracter, nome do campo da data selecionada para validação.
@param  	cCpoDtIn, Caracter, nome do campo da data inicial.
@param  	cCpoDtFm, Caracter, nome do campo da data final.
/*/
//------------------------------------------------------------------------------
Function At740VldDt(cModelo,cCpoSelec,cCpoDtIn,cCpoDtFm,oModel,lExtra)

Local oMdl			:= nil
Local dDtIniLoc	:= CToD('') 
Local dDtFimLoc	:= CToD('')
Local dPrIniRh	:= CToD('') 
Local dPrFimRh	:= CToD('')
Local lRet			:= .F.
Local cMdlLoc
Local cMdlRH 
Local cCntRec := ""  

Default oModel	:= FwModelActive()
Default lExtra	:= .F.

oMdl		:= oModel:GetModel(cModelo)

If lExtra
	cMdlLoc := 'TFL_CAB'
	cMdlRH  := 'TFF_GRID'
	cCntRec := "2" //Item extra e cortesia o usuário poderá informar a data de termino do posto.
Else

	oMdl		:= oModel:GetModel(cModelo)
	cCntRec		:= oModel:GetValue('TFJ_REFER','TFJ_CNTREC')//INDICA SE O CONTRATO É RECORRENTE
	cMdlLoc := 'TFL_LOC'
	cMdlRH  := 'TFF_RH'
EndIf

dDtIniLoc := oModel:GetModel(cMdlLoc):GetValue('TFL_DTINI')
dDtFimLoc := oModel:GetModel(cMdlLoc):GetValue('TFL_DTFIM')

dPrIniRh := oModel:GetModel(cMdlRH):GetValue('TFF_PERINI')
dPrFimRh := oModel:GetModel(cMdlRH):GetValue('TFF_PERFIM')
	
If Left(cCpoSelec,3) $ "TFI#TFF" .And. SubStr(cCpoSelec,5) == "PERINI"	

	If DTOS(oMdl:GetValue(cCpoDtIn)) >= DTOS(dDtIniLoc) .AND. (DTOS(oMdl:GetValue(cCpoDtIn)) <= DTOS(dDtFimLoc) .OR. Empty(dDtFimLoc) )  		
		lRet := .T.
	EndIf

ElseIf Left(cCpoSelec,3) $ "TFI#TFF" .And. SubStr(cCpoSelec,5) == "PERFIM" 

	If !Empty(oMdl:GetValue(cCpoDtIn))		
		If DTOS(oMdl:GetValue(cCpoDtFm)) >= DTOS(oMdl:GetValue(cCpoDtIn)) .AND. (DTOS(oMdl:GetValue(cCpoDtFm)) <= DTOS(dDtFimLoc) .OR. Empty(dDtFimLoc) ) 
			lRet := .T.
		EndIf		
	EndIf
	
ElseIf SubStr(cCpoSelec,5) == "PERINI"

	If DTOS(oMdl:GetValue(cCpoDtIn)) >= DTOS(dPrIniRh) .AND. ;
	  (DTOS(oMdl:GetValue(cCpoDtIn)) <= DTOS(dPrFimRh) .OR. ;
	  Empty(oModel:GetModel(cMdlRH):GetValue("TFF_PERFIM")) )  		
		lRet := .T.
	EndIf	

ElseIf SubStr(cCpoSelec,5) == "PERFIM"

	If !Empty(oMdl:GetValue(cCpoDtIn))		
		If DTOS(oMdl:GetValue(cCpoDtFm)) >= DTOS(oMdl:GetValue(cCpoDtIn)) .AND. ;
		  (DTOS(oMdl:GetValue(cCpoDtFm)) <= DTOS(dPrFimRh) .OR. ;
		  Empty(dPrFimRh) ) .OR. cCntRec == "1"
			lRet := .T.
		EndIf		
	EndIf
EndIf

Return lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At740VldHr
	
Função para validação dos horarios do periodos iniciais e finais dos materiais e alocações.

@sample 	At740VldDt(cModelo,cCpoSelec,cCpoDtIn,cCpoDtFm)

@since		23/10/2013      
@version	P11.90

@return 	lRet, Lógico, retorna .T. se o horario for válido.

@param  	cModelo, Caracter, nome do modelo de dados principal.
@param  	cCpoSelec, Caracter, nome do campo da hora selecionada para validação.
@param  	cCpoHrIn, Caracter, nome do campo da hora inicial.
@param  	cCpoHrFm, Caracter, nome do campo da hora final.
/*/
//------------------------------------------------------------------------------
Function At740VldHr(cModelo,cCpoSelec,cCpoHrIn,cCpoHrFm)

Local oModel  := FwModelActive()
Local oMdl		:= oModel:GetModel(cModelo)
Local lRet    := (Len(Alltrim(oMdl:GetValue(cCpoSelec))) == 1)

If !lRet

	If SubStr(cCpoSelec,5) == "HORAIN" .And. ! Empty(FwFldGet("TFF_HORAIN"))
	
		If oMdl:GetValue(cCpoHrIn) >= FwFldGet("TFF_HORAIN") .And. ;
		   (oMdl:GetValue(cCpoHrIn) <= FwFldGet("TFF_HORAFI") .OR. Empty(FwFldGet("TFF_HORAFI")))  		
			lRet := .T.
		EndIf
	
	ElseIf SubStr(cCpoSelec,5) == "HORAFI" .And. ! Empty(FwFldGet("TFF_HORAFI"))
	
		If !Empty(oMdl:GetValue(cCpoHrIn))	
			If oMdl:GetValue(cCpoHrFm) >= oMdl:GetValue(cCpoHrIn) .And. ;
				(oMdl:GetValue(cCpoHrFm) >= FwFldGet("TFF_HORAIN") .Or. Empty(FwFldGet("TFF_HORAIN"))) .And. ;
				(oMdl:GetValue(cCpoHrFm) <= FwFldGet("TFF_HORAFI") .Or. Empty(FwFldGet("TFF_HORAFI"))) 
				lRet := .T.
			EndIf	
		EndIf
		
	EndIf
	
EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740VlVig
	Valida a fata de vigência em todos os grids dependentes da tabela TFL

@sample 	At740VlVig(oModel)

@since		05/10/2013      
@version	P11.90

@return 	lRet, Lógico, retorna .T. se data for válida.

@param  	oModel, Objeto, modelo de dados da tabela TFL
/*/
//------------------------------------------------------------------------------
Function At740VlVig(oModel)

Local oMdlGeral	:= oModel:GetModel()
Local oMdlRH		:= nil
Local oMdlMI		:= nil
Local oMdlMC		:= nil
Local oMdlLE		:= nil
Local nLinRh		:= 0
Local nLinMi		:= 0
Local nLinMc		:= 0
Local nLinLe		:= 0
Local aSaveRows	:= {}
Local lRet			:= .T.
Local dDtIniLoc 	:= CToD('')
Local dDtFimLoc 	:= CToD('')

If oMdlGeral == nil
	oMdlGeral := FwModelActive()
EndIf

dDtIniLoc 	:= oMdlGeral:GetModel('TFL_LOC'):GetValue('TFL_DTINI')
dDtFimLoc 	:= oMdlGeral:GetModel('TFL_LOC'):GetValue('TFL_DTFIM')

oMdlRH	:= oMdlGeral:GetModel("TFF_RH")
oMdlMI	:= oMdlGeral:GetModel("TFG_MI")
oMdlMC	:= oMdlGeral:GetModel("TFH_MC")
oMdlLE	:= oMdlGeral:GetModel("TFI_LE")

If ExistBlock("AT740VLDT")
	lRet := ExecBlock("AT740VLDT",.F.,.F.,{lRet,oModel,dDtFimLoc})
EndIf



If lRet
	aSaveRows := FwSaveRows()
	For nLinRh := 1 to oMdlRH:Length() // Aba Recursos humanos
			
		oMdlRH:GoLine( nLinRh )
				
		If !oMdlRH:IsDeleted()
		
			If DTOS(dDtFimLoc) >= DTOS(oMdlRH:GetValue("TFF_PERFIM"))
			
				For nLinMi := 1 to oMdlMI:Length() // Aba Materiais de Implantação
				
					oMdlMI:GoLine( nLinMi )
					
						If !oMdlMI:IsDeleted()
						
							If DTOS(dDtFimLoc) < DTOS(oMdlMI:GetValue("TFG_PERFIM"))
								lRet := .F.
							EndIf
							
						EndIf		
				
				Next nLinMi
				
				For nLinMc := 1 to oMdlMC:Length() // Aba Materiais de Consumo
			
					oMdlMC:GoLine( nLinMc )
					
						If !oMdlMC:IsDeleted()
						
							If DTOS(dDtFimLoc) < DTOS(oMdlMC:GetValue("TFH_PERFIM"))
								lRet := .F.
							EndIf
							
						EndIf		
				
				Next nLinMc
			
			Else
			
				lRet := .F.
				
			EndIf
		
		EndIf
	
	Next nLinRh
	
	For nLinLe := 1 to oMdlLE:Length()
	
		oMdlLE:GoLine( nLinLe )
		
		If !oMdlLE:IsDeleted()
		
			If DTOS(dDtFimLoc) < DTOS(oMdlLE:GetValue("TFI_PERFIM"))
				lRet := .F.
			EndIf
							
		EndIf	
	
	Next nLinLe

	FwRestRows( aSaveRows )
	
	If !lRet
	
		oModel:GetModel():SetErrorMessage(oModel:GetId(),"TFL_DTFIM",oModel:GetModel():GetId(),	"TFL_DTFIM",'TFL_DTFIM',; 
			STR0025, STR0026 )  // 'Data final de vigência menor que o período final dos recursos, materiais e locação' ### 'Digite uma data maior.'
	
	EndIf
	
	If 	lRet .and. (dDtFimLoc < dDtIniLoc)
		oModel:GetModel():SetErrorMessage(oModel:GetId(),"TFL_DTFIM",oModel:GetModel():GetId(),	"TFL_DTFIM",'TFL_DTFIM',; 
			STR0026,'' )  // 'Digite uma data maior.'###'Atenção!'
		lRet := .F.
	EndIf
EndIf	

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740SCmt / At740GCmt
	Altera o conteúdo da variável 

@sample 	At740CpyMdl

@since		23/09/2013
@version	P11.90

/*/
//------------------------------------------------------------------------------
Function At740SCmt( lValor )

lDoCommit := lValor

Return 

Function At740GCmt()

Return lDoCommit

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740SLoad
	Realiza a cópia dos dados de um modelo para outro
evitando sobrepor conteudo de alguns campos, informados na exceção

@sample 	At740CpyMdl

@since		23/09/2013
@version	P11.90

/*/
//------------------------------------------------------------------------------
Function At740SLoad( oObj )

oCharge := oObj

Return

Function At740GLoad()

Return( oCharge )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740GXML
	Realiza a cópia dos dados de um modelo para outro
evitando sobrepor conteudo de alguns campos, informados na exceção

@sample 	At740GXML

@since		23/09/2013
@version	P11.90

/*/
//------------------------------------------------------------------------------
Function At740GXML()

Return cXmlDados


//------------------------------------------------------------------------------
/*/{Protheus.doc} At740SLuc / At740GLuc
	Altera o conteúdo da variável 

@sample 	At740CpyMdl

@since		26/02/2015
@version	P12

/*/
//------------------------------------------------------------------------------
Function At740SLuc( nValor )

nTLuc := nValor

Return 

Function At740GLuc()

Return nTLuc


//------------------------------------------------------------------------------
/*/{Protheus.doc} At740SAdm / At740GAdm
	Altera o conteúdo da variável 

@sample 	At740CpyMdl

@since		26/02/2015
@version	P12

/*/
//------------------------------------------------------------------------------
Function At740SAdm( nValor )

nTAdm := nValor

Return 

Function At740GAdm()

Return nTAdm


//------------------------------------------------------------------------------
/*/{Protheus.doc} At740VldPrd
	Valida o produto selecionado conforme o tipo Rec. Humano, Mat. consumo, etc

@sample  	At740VldPrd

@since   	23/09/2013
@version 	P11.90

@param   	ExpN, Numerico, define qual o tipo do produto para validar sendo:
				1 - Recurso Humano
				2 - Material de Implantação
				3 - Material de Consumo
				4 - Equipamentos para Locação
				5 - Beneficio
@param   	ExpC, Caracter, código do produto a ser validado

@return  	ExpL, Logico, indica de se é valido (.T.) ou não (.F.)
/*/
//------------------------------------------------------------------------------
Function At740VldPrd( nTipo, cCodProd )
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local lRet := .F.

DEFAULT nTipo := 0
DEFAULT cCodProd := ''
//--------------------------------------------------------------------
// Posiciona na tabela SB5 para verificar a configuração do produto
// conforme cada tipo exige

DbSelectArea('SB5')
SB5->( DbSetOrder( 1 ) ) //B5_FILIAL+B5_COD

If !Empty(cCodProd) .And. SB5->( DbSeek( xFilial('SB5')+cCodProd ) )
	Do Case  
	
		CASE nTipo == 1 // Recurso Humano
			lRet := SB5->B5_TPISERV == '4'
	
		CASE nTipo == 2 // Material de Implantação
			lRet := SB5->B5_TPISERV $ '1235' .And. SB5->B5_GSMI == '1' 
			If lRet
				lRet := AT890VldTWY(cCodProd)
			EndIf	
		
		CASE nTipo == 3 // Material de Consumo
			lRet := SB5->B5_TPISERV $ '5' .And. SB5->B5_GSMC == '1'
		
		CASE nTipo == 4 // Locação de Equipamentos
			lRet := SB5->B5_TPISERV $ '5' .And. SB5->B5_GSLE == '1'
		
		CASE nTipo == 5 //Beneficio
			lRet := SB5->B5_TPISERV $ '5' .And. SB5->B5_GSBE == '1'
	End Case

EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740TdOk
	Validação geral do modelo

@sample 	At740TdOk

@since		23/09/2013
@version	P11.90

/*/
//------------------------------------------------------------------------------
Function At740TdOk( oMdlGer )
Local aArea		 := GetArea() 
Local aSaveLines := FWSaveRows()
Local aValidMat	 := {}	//Estrutura com locais e itens de RH com sem valor de materiais
Local oMdlLoc	 := oMdlGer:GetModel('TFL_LOC')
Local oMdlGrid	 := oMdlGer:GetModel('TFI_LE')
Local oMdlCobLoc := oMdlGer:GetModel('TEV_ADICIO')
Local oMdlRH	 := oMdlGer:GetModel('TFF_RH')
Local oModMI     := oMdlGer:GetModel('TFG_MI')
Local oModMC     := oMdlGer:GetModel('TFH_MC')
Local nLinGrd    := 0
Local nLinFil    := 0
Local nLinTev    := 0
Local nI         := 0
Local nJ         := 0 
Local nK         := 0
Local nPrcVenda	 := 0
Local lCobrContr := .F.  
Local lOk		 := .T.
Local lRet		 := .T.
Local lExclusao 	:= oMdlGer:GetOperation() == MODEL_OPERATION_DELETE
Local lOrcPrc 	:= SuperGetMv("MV_ORCPRC",,.F.)
Local lPermLocZero 	:= At680Perm( , __cUserId, '032' )
Local lAlgumTemValor 	:= .F.
Local lNotRhMts 		:= .F.
Local nMatImp	 := 1

// não realiza validaçaõ alguma quando é exclusão
If lExclusao
	lRet := oMdlGer:GetModel("TFJ_REFER"):GetValue("TFJ_STATUS") == "2" .Or. ; // Só permite a exclusão de orçamentos com status em revisão
				Empty( oMdlGer:GetModel("TFJ_REFER"):GetValue("TFJ_CONTRT") )  // ou que não tenha contrato ainda
	If !lRet 
		oModel:GetModel():SetErrorMessage( oMdlGer:GetId(),"TFJ_STATUS",oMdlGer:GetModel("TFJ_REFER"), "TFJ_STATUS",;
			oMdlGer:GetModel("TFJ_REFER"):GetValue("TFJ_STATUS"),; 
			STR0125,"" )  // "Não é permitido excluir orçamentos de serviços neste status"
	EndIf
Else
	// verifica se foram inseridos produtos/recursos nos Locais
	If lRet
	 	For nI := 1 To oMdlLoc:Length()
	 		oMdlLoc:GoLine( nI )
	 		If !oMdlLoc:IsDeleted()
	 			If oMdlLoc:GetValue("TFL_TOTAL") == 0 
					lNotRhMts := ( oMdlRH:IsEmpty() .And. oModMI:IsEmpty() .And. oModMC:IsEmpty() )
					If !lPermLocZero .Or. lNotRhMts
	 					lRet := .F.
	 					Exit
	 				EndIf
				Else
					lAlgumTemValor := .T.
				EndIf
 			EndIf
 		Next 
		If !lAlgumTemValor .And. lPermLocZero
			lRet := .F.
		EndIf
	EndIf

	If lRet 
	
		If IsInCallStack("At600SeAtu")//Realiza validação somente dentro da tela do TECA740
			cIsGsMt := oMdlGer:GetModel('TFJ_REFER'):GetValue('TFJ_ISGSMT')

			If cIsGsMt == "1"
				If oMdlGer:GetModel('TFJ_REFER'):GetValue('TFJ_GSMTMI') $ '23' .Or. oMdlGer:GetModel('TFJ_REFER'):GetValue('TFJ_GSMTMC') $ '23' //Material por valor ou por percentual do recurso
					For nI:=1 To oMdlLoc:Length()
						oMdlLoc:GoLine(nI)
						
						If !oMdlLoc:IsDeleted()
							For nJ:=1 To oMdlRH:Length()
								oMdlRH:GoLine(nJ)
								If !oMdlRh:IsDeleted() .AND. !Empty(oMdlRh:GetValue("TFF_PRODUT")) .AND. oMdlRh:GetValue("TFF_VLMTMI") == 0 .AND. oMdlRh:GetValue("TFF_VLMTMC") == 0
									aAdd(aValidMat, { oMdlLoc:GetValue("TFL_LOCAL"),;
										oMdlLoc:GetValue("TFL_DESLOC"),;
										oMdlRH:GetValue("TFF_ITEM"),;
										oMdlRH:GetValue("TFF_PRODUT"),;
									                  oMdlRH:GetValue("TFF_DESCRI") })
								EndIf
							Next nJ
						EndIf
					Next nI
				EndIf
			Else
				If oMdlGer:GetModel('TFJ_REFER'):GetValue('TFJ_GESMAT') $ '23'//Material por valor ou por percentual do recurso
					For nI:=1 To oMdlLoc:Length()
						oMdlLoc:GoLine(nI)
						
						If !oMdlLoc:IsDeleted()
							For nJ:=1 To oMdlRH:Length()
								oMdlRH:GoLine(nJ)
								If !oMdlRh:IsDeleted() .AND. !Empty(oMdlRh:GetValue("TFF_PRODUT")) .AND. oMdlRh:GetValue("TFF_VLRMAT") == 0
									aAdd(aValidMat, { oMdlLoc:GetValue("TFL_LOCAL"),;
										oMdlLoc:GetValue("TFL_DESLOC"),;
										oMdlRH:GetValue("TFF_ITEM"),;
										oMdlRH:GetValue("TFF_PRODUT"),;
									                  oMdlRH:GetValue("TFF_DESCRI") })
								EndIf
							Next nJ
						EndIf
					Next nI
				EndIf
			Endif

			If Len(aValidMat) > 0
				If !At740ExbIt(aValidMat)//Apresenta itens em tela
					lRet := .F.
				EndIf
			EndIf
			
		EndIf
	
		If lRet
			For nI := 1 To oMdlLoc:Length()
	
				oMdlLoc:GoLine(nI)
	
				If !oMdlLoc:IsDeleted()
					// verifica o preenchimento dos recursos humanos
					For nJ := 1 To oMdlRH:Length()
	
						oMdlRH:GoLine(nJ)
						// verifica o preenchimento dos campos de valores
						If !oMdlRH:IsDeleted() .And. !Empty( oMdlRH:GetValue("TFF_PRODUT") )
							lRet := ( oMdlRH:GetValue("TFF_PRCVEN") > 0 .Or. ;
										oMdlRH:GetValue("TFF_COBCTR") == "2" .Or. ;
										( oMdlRH:GetValue("TFF_PRCVEN") == 0 .And. lPermLocZero ) )
						EndIf
	
						If !lRet 
							Help(,,"AT740TDOKRH",,STR0126,1,0) // "O valor dos itens de recursos humanos não pode ser zero para itens pertencentes ao contrato."
						EndIf
	
						If !lOrcPrc
							// verifica o preenchimento dos valores dos materiais
							lRet := lRet .And. At740VlrMts( oModMI, "TFG", lPermLocZero )
							lRet := lRet .And. At740VlrMts( oModMC, "TFH", lPermLocZero )

							// verifica o preenchimento das datas de materiais
							lRet := lRet .And. At740DtMts( oModMI, "TFG")
							lRet := lRet .And. At740DtMts( oModMC, "TFH")

							EndIf
	
						If !lRet
							EXIT
						EndIf
					Next nJ
						
					If lOrcPrc
						// verifica o preenchimento dos valores dos materiais
						lRet := lRet .And. At740VlrMts( oModMI, "TFG", lPermLocZero )
						lRet := lRet .And. At740VlrMts( oModMC, "TFH", lPermLocZero )

						// verifica o preenchimento das datas de materiais
						lRet := lRet .And. At740DtMts( oModMI, "TFG")
						lRet := lRet .And. At740DtMts( oModMC, "TFH")

					EndIf
				EndIf
	
				If !lRet
					EXIT
				EndIf
			Next nI
		EndIf
		
		If lRet
			//--------------------------------------------------------------------------------
			//  Valida a existência de cobrança para os itens de locação de equipamentos
			For nLinGrd := 1 To oMdlLoc:Length()
		
			oMdlLoc:GoLine( nLinGrd )
			
			If !oMdlLoc:IsDeleted()
				
				// Varre as linhas da locação de equipamento
				For nLinFil := 1 To oMdlGrid:Length()
				
					oMdlGrid:GoLine( nLinFil )
					
					If !oMdlGrid:IsDeleted() .And. !Empty( oMdlGrid:GetValue('TFI_PRODUT') )
						
						// varre as linhas de cobrança da locação
						For nLinTev := 1 To oMdlCobLoc:Length()
							
							oMdlCobLoc:GoLine( nLinTev )
							
							If !oMdlCobLoc:IsDeleted() .And. oMdlCobLoc:GetValue("TEV_MODCOB") <> "5" .And. oMdlCobLoc:GetValue('TEV_VLTOT') <> 0
								lOk := .T.
								Exit
							Else
								lOk := .F.
							EndIf
						
						Next nLinTev // cobrança da locação
						
						If lOk
							//Validação dos campos de Entrega e Coleta
							If lRet
								If (!Empty(oMdlGrid:GetValue('TFI_ENTEQP')) .And. Empty(oMdlGrid:GetValue('TFI_COLEQP'))); 
								.Or. (Empty(oMdlGrid:GetValue('TFI_ENTEQP')) .And. !Empty(oMdlGrid:GetValue('TFI_COLEQP')))
									lRet := .F.
									Help(,,"AT740OPC1",,STR0095,1,0) //"Não é possivel deixar um dos campos de Entrega/Coleta preenchidos, ou os campos deve estar em branco ou os dois preenchidos! "
									Exit
								Elseif (!Empty(oMdlGrid:GetValue("TFI_ENTEQP")) .AND. !At740VldAg("TFI_ENTEQP",;
											  oMdlGrid:GetValue("TFI_PERINI"),;
											  oMdlGrid:GetValue("TFI_PERFIM"),;
											  oMdlGrid:GetValue("TFI_ENTEQP"),;
											  oMdlGrid:GetValue("TFI_COLEQP"))) .OR. (!Empty(oMdlGrid:GetValue("TFI_COLEQP")) .AND. !At740VldAg("TFI_COLEQP",;
											  oMdlGrid:GetValue("TFI_PERINI"),;
											  oMdlGrid:GetValue("TFI_PERFIM"),;
											  oMdlGrid:GetValue("TFI_ENTEQP"),;
											  oMdlGrid:GetValue("TFI_COLEQP")))
										
										lRet := .F.
										Exit
								Elseif Empty(oMdlGrid:GetValue("TFI_TES"))
									Help(,, "At740TdOk",,STR0098,1,0,,,,,,{STR0099}) //"O campo TES do grid de Locação de Equipamentos não pode ser vazio." # "Informe a TES."
									lRet := .F.
									Exit
								ElseIf (!Empty(oMdlGrid:GetValue("TFI_APUMED")) .and. oMdlGrid:GetValue("TFI_APUMED") <> '1') .And. ( Empty(oMdlGrid:GetValue('TFI_ENTEQP')) .or. Empty(oMdlGrid:GetValue('TFI_COLEQP')) )
									Help(,, "At740TdOk",,STR0112,1,0,,,,,,{STR0113})//#"Quando Tipo de Apuração for diferente de Branco ou '1' é necessario fazer o preenchimento dos campos de Entrega e Coleta"#"Favor preencher os campos de Entrega e Coleta para Processeguir" 
									lRet := .F.
									Exit
								Endif												
							EndIf
							
							//  quando identifica uma cobrança, vai para a próxima linha 
							// dos itens de locação
							Loop 
						Else
							//  quando identifica erro, sai com erro e força o preenchimento
							lRet := .F.
							Help(,,'AT740COBLOC',, STR0027 + CRLF + ;  // 'Cobrança da locação não preenchida para o item: ' 
													STR0028 + STR(nLinGrd) + CRLF + ;  // 'Item Local '
													STR0029 + STR(nLinFil) + CRLF + ;  // 'Item Locação '
													STR0030 ,1,0)  // 'Preencha a cobrança e depois confirme o Orçamento' 
							Exit
						EndIf
											
					EndIf
				
				Next nLinFil  // itens da locação
			
					If oMdlGer:GetModel('TFJ_REFER'):GetValue('TFJ_AGRUP') <> "1"
						DbSelectArea("ABS")
						DbSetOrder(1)
						If ABS->(DbSeek(xFilial("ABS")+oMdlLoc:GetValue('TFL_LOCAL')))
							If Empty(ABS->ABS_CLIFAT) .AND. Empty(ABS->ABS_LJFAT)
								lRet := .F.
								Help(,,'AT740CLIFAT',,STR0045,1,0) // "Os campos ABS_CLIFAT e ABS_LJFAT são necessarios o preenchimento devido o campo TFJ_AGRUP estar como Não"
								Exit
							EndIf
						EndIf
					EndIf	
				
				EndIf
			
			Next nLinGrd  // locais de atendimento
		EndIf
	Else
		If lPermLocZero .And. lNotRhMts
			Help(,,'AT740SEMITEM',, STR0137,1,0)  // 'Para os locais com valor zerado é necessário preencher itens de Recursos Humanos ou Materiais.'
		Else
			Help(,,'AT740VAZIO',, STR0038,1,0)  // 'Algum local de atendimento foi preenchido e seus respectivos itens não foram informados antes de confirmar!'
		EndIf
	
	EndIf
EndIf
	
FWRestRows( aSaveLines )
RestArea(aArea)
	
Return lRet
	
/*/{Protheus.doc} At740VlrMts
	Valida o preenchimento de valores nos grids de materiais
@since 		05/12/2016
@version 	12.15
@param 		oModMat, Objeto FwFormGridModel, modelo de dados de algum dos materiais (implantação ou consumo) do orçamento de serviços
@param 		cTab, caracter, tabela a ser validada e que pertence ao modelo
@return 		Lógico, indica se o processamento aconteceu ou não com sucesso
/*/
Static Function At740VlrMts( oModMat, cTab, lPermLocZero )
Local lRet := .T.
Local nK := 0
	
Default lPermLocZero := .F.
	
For nK := 1 To oModMat:Length()
	oModMat:GoLine(nK)
	If ! oModMat:IsDeleted() .And. ! Empty(oModMat:GetValue(cTab+'_PRODUT'))
		nPrcVenda	:= oModMat:GetValue(cTab+"_PRCVEN")
		If nPrcVenda < 0
			Help(,,"At740TdOk",,STR0115,1,0) //"O valor do preço de venda do material de implantação não pode ser negativo."
			lRet := .F.
			EXIT
	EndIf
		lCobrContr := (oModMat:GetValue(cTab+"_COBCTR") <> "2")
		If nPrcVenda == 0 .And. lCobrContr .And. !IsInCallStack("LoadXmlData") .And. !lPermLocZero
			Help(,,"At740TdOk",,STR0116,1,0) // "O valor do preço de venda do material de implantação deve ser maior do que zeros."
			lRet	:= .F.
			EXIT
		EndIf
	EndIf
Next nK

Return lRet


/*/{Protheus.doc} At740ExbIt
Exibe Itens em tela
@since 17/07/2015
@version 1.0
@param aItens, array, (Descrição do parâmetro)
@return lRet, Indica confirmação ou cancelamento
/*/
Static Function At740ExbIt(aItens)
	
Local aArea		:= GetArea()
Local aSaveLines	:= FWSaveRows()
Local aSize	:= FWGetDialogSize( oMainWnd ) 	// Array com tamanho da janela.
Local lRet 	:= .T.
Local cTexto 	:= ""
Local nTop 	:= aSize[1]
Local nLeft 	:= aSize[2]
Local nI 		:= 1
Local cLocOld := ""
Local cTitItem := STR0074//ITEM
	
//Monta texto a ser apresentado		
cTexto := UPPER(STR0072) + CRLF
	
For nI:=1 To Len(aItens)
		
	If cLocOld != aItens[nI][1]
		cTexto += CRLF + aItens[nI][1] + " - " + aItens[nI][2] + CRLF//Local de Atendimento
	EndIf		
	cTexto += cTitItem+": "+aItens[nI][3]+" - "//Item
	cTexto += aItens[nI][4]+ " - "+aItens[nI][5]+CRLF//Produto
	
	cLocOld := aItens[nI][1]
		
Next nI
			
DEFINE DIALOG oDlg TITLE STR0073 FROM 0,0 TO 285, 540 PIXEL
	
@ 000, 000 MsPanel oTop Of oDlg Size 000, 200 // Coordenada para o panel
oTop:Align := CONTROL_ALIGN_TOP //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
	
@ 5, 5 Get oMemo Var cTexto Memo Size 260, 100  Of oTop Pixel When .F.
oMemo:bRClicked := { || AllwaysTrue() }

Define SButton From 115, 230 Type  1 Action (lRet := .T., oDlg:End()) Enable Of oTop Pixel // OK
Define SButton From 115, 195 Type  2 Action (lRet := .F., oDlg:End()) Enable Of oTop Pixel // Cancelar
	
ACTIVATE DIALOG oDlg CENTERED
	
FWRestRows( aSaveLines )
RestArea(aArea)
Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740BlTot
	Validação da edição do campo preço de venda de recursos humanos

@sample 	At740BlTot

@since		24/10/2013
@version	P11.90

/*/
//------------------------------------------------------------------------------
Function At740BlTot(oModel)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local lBloq := SuperGetMv("MV_ATBLTOT",,.F.)
Local lRet	:= .T.

If lBloq .And. !Empty(oModel:GetValue("TFF_CALCMD"))
	lRet	:= .F.
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return lRet


/*/{Protheus.doc} At740QtdVen
	
@since 31/10/2013
@version 11.9
		
@return lRet, regra para when do campo TFI_QTDVEN 

@description
Função com regras para WHEN do campo TFI_QTDVEN

/*/
Function At740QtdVen()
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local lRet := .T.
	
If IsInCallStack("TECA870")
	lRet := .F.
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740CpCal
	Copiar a planilha de preço do item posicionado

@sample 	At740CpCal

@since		11/11/2013
@version	P11.90

/*/
//------------------------------------------------------------------------------
Function At740CpCal(oModel)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oMdlRh := oModel:GetModel("TFF_RH")

cXmlCalculo := oMdlRh:GetValue("TFF_CALCMD") 
aPlanData := { oMdlRh:GetValue("TFF_PLACOD"), oMdlRh:GetValue("TFF_PLAREV") } 

FWRestRows( aSaveLines )
RestArea(aArea)
Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740ClCal
	Colar a planilha de preço e executar cálculo no item posicionado.

@sample 	At740ClCal

@since		11/11/2013
@version	P11.90

/*/
//------------------------------------------------------------------------------
Function At740ClCal(oModel)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oMdlRh	:= oModel:GetModel("TFF_RH")
Local cPreco	:= ""
Local aCamposTFF:= oMdlRh:GetStruct():GetFields()
Local nX		:= 0
Local cAux		:= ""

//Trata os campos para utilizar variavel de memoria
If oMdlRh:GetOperation() <> MODEL_OPERATION_VIEW
	RegToMemory("TFF",.F.,.F.)
	For nX:=1 to len(aCamposTFF)
		cAux		:= aCamposTFF[nX][3]
		M->&(cAux) := oMdlRh:GetValue(cAux)
	Next nX
EndIf	

If !Empty(cXmlCalculo)
	oFWSheet := FWUIWorkSheet():New(,.F. ) //instancia a planilha sem exibição
	oFwSheet:LoadXmlModel(cXmlCalculo) 
	cPreco := oFwSheet:GetCellValue("TOTAL_RH") 
	
	If oMdlRh:GetOperation() <> MODEL_OPERATION_VIEW
		oMdlRh:SetValue("TFF_PRCVEN",cPreco)
		oMdlRh:SetValue("TFF_CALCMD",cXmlCalculo)

		If Len(aPlanData) >= 2  // caso seja necessário copiar mais dados tvz seja melhor guardar a linha original da cópia
			oMdlRh:SetValue("TFF_PLACOD", aPlanData[1])
			oMdlRh:SetValue("TFF_PLAREV", aPlanData[2])
		EndIf	
	EndIf	
Else
	Aviso(STR0035, STR0036, {STR0037}, 2)	//"Atenção!"#"Para utilizar o botão Colar Cálculo, necessário posicionar no item de recursos humanos que tenha formação de preço"{"OK"}
EndIf
	
FWRestRows( aSaveLines )
RestArea(aArea)

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740LeTot
	Função para cálculo do desconto e valor total dos itens da locação

@sample 	At740LeTot( cTipoCalc )

@since		10/12/2013
@version	P11.90

@param 		cTipoCalc, Char, Define o formato do cálculo retornado o valor total ou o valor do desconto
				'1' = deve retornar o valor Total
				'2' = deve retornar o valor de desconto
@return 	nValor, Numeric, valor para atribuição no campo
/*/
//------------------------------------------------------------------------------
Function At740LeTot( cTipoCalc )
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oMdlAtivo := FwModelActive()
Local nValor    := 0

Default cTipoCalc := '1'

If oMdlAtivo <> Nil .And. (oMdlAtivo:GetId()=='TECA740' .Or. oMdlAtivo:GetId()=='TECA740F') 

	If oMdlAtivo:GetModel('CALC_TEV') <> Nil
		nValor := oMdlAtivo:GetModel('CALC_TEV'):GetValue('TOT_ADICIO')
	Else
		nValor := IterTev( oMdlAtivo:GetModel('TEV_ADICIO') )
	EndIf
	
	If cTipoCalc == '2'
		nValor := ( nValor )*(oMdlAtivo:GetModel('TFI_LE'):GetValue('TFI_DESCON')/100)
	Else
		nValor := ( nValor )*(1-(oMdlAtivo:GetModel('TFI_LE'):GetValue('TFI_DESCON')/100))
	EndIf
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return nValor

//------------------------------------------------------------------------------
/*/{Protheus.doc} IterTev
	Soma os valores da TEV na definição de cobrança da locação

@sample 	IterTev( cTipoCalc )

@since		10/12/2013
@version	P11.90

@param 		oMdlTEV, Object, Model com as informações da cobrança da locação

@return 	nValor, Numeric, valor para atribuição no campo
/*/
//------------------------------------------------------------------------------
Function IterTev( oMdlTEV )
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local nValTev := 0
Local nLinhas := 0
Local nLinTev := oMdlTEV:GetLine()

For nLinhas := 1 To oMdlTEV:Length()
	
	oMdlTEV:GoLine( nLinhas )
	// não considera linhas deletadas e com o modo de cobrança como 5-Franquia/Excedente
	If !oMdlTEV:IsDeleted() .And. oMdlTEV:GetValue('TEV_MODCOB') <> "5"
		nValTev += oMdlTEV:GetValue('TEV_VLTOT')
	EndIf

Next nLinhas

oMdlTev:GoLine( nLinTev )

FWRestRows( aSaveLines )
RestArea(aArea)
Return nValTEV

//------------------------------------------------------------------------------
/*/{Protheus.doc} PreLin[Tab]
	Executa a atualização dos valores quando excluída linha de grid que replica informação
a grids superiores

@sample 	PreLinTEV(oMdlG, nLine, cAcao, cCampo)

@since		11/12/2013
@version	P11.90

@param 		oMdlGrid, Objeto, objeto do grid em validação
@param 		nLine, Numerico, linha em ação
@param 		cAcao, Caracter, tipo da ação (DELETE, UNDELETE, etc)
@param 		cCampo, Caracter, campo da ação

@return 	lOk, Logico, permite ou não a atualização
/*/
//------------------------------------------------------------------------------

//------------------------------------------------------
//  Atualização exclusão da cobrança da locação
Function PreLinTEV(oMdlG, nLine, cAcao, cCampo)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local lOk      := .T.
Local oMdlFull := oMdlG:GetModel()
Local nValDel  := 0
Local nTotAtual := 0
Local nTotDesc := 0
Local oMdlUse  := Nil

FWModelActive(oMdlG)//seta o model

If oMdlFull <> Nil .And. (oMdlFull:GetId()=='TECA740' .Or. oMdlFull:GetId()=='TECA740F') 
	// só realiza a atualização dos valores quando o modo de cobrança for diferente de 
	// 5-Franquia/Excedente 
	If oMdlG:GetValue('TEV_MODCOB') <> '5'
	If cAcao == 'DELETE'
		
		//-----------------------------------------------
		//  Atualiza o item da locação vinculado
		oMdlUse := oMdlFull:GetModel('TFI_LE')
		
		nValDel := oMdlG:GetValue('TEV_VLTOT')
		nTotAtual := ( oMdlUse:GetValue('TFI_TOTAL') + oMdlUse:GetValue('TFI_VALDES') )
		nTotAtual -= nValDel
		
		nTotDesc := ( nTotAtual * ( oMdlUse:GetValue('TFI_DESCON')/100 ) )
		nTotAtual := ( nTotAtual * ( 1- ( oMdlUse:GetValue('TFI_DESCON')/100 ) ) )
		
		lOk := oMdlUse:SetValue('TFI_TOTAL', nTotAtual )
		lOk := oMdlUse:SetValue('TFI_VALDES', nTotDesc )
		
	ElseIf cAcao == 'UNDELETE'
	
		//-----------------------------------------------
		//  Atualiza o item da locação vinculado
		oMdlUse := oMdlFull:GetModel('TFI_LE')
		
		nValDel := oMdlG:GetValue('TEV_VLTOT')
		nTotAtual := ( oMdlUse:GetValue('TFI_TOTAL') + oMdlUse:GetValue('TFI_VALDES') )
		nTotAtual += nValDel
		
		nTotDesc := ( nTotAtual * ( oMdlUse:GetValue('TFI_DESCON')/100 ) )
		nTotAtual := ( nTotAtual * ( 1 - ( oMdlUse:GetValue('TFI_DESCON')/100 ) ) )
		
		lOk := oMdlUse:SetValue('TFI_TOTAL', nTotAtual )
		lOk := oMdlUse:SetValue('TFI_VALDES', nTotDesc )
	
	EndIf
	EndIf
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return lOk

//-----------------------------------------------
// atualização de exclusão da TFI
Function PreLinTFI(oMdlG, nLine, cAcao, cCampo)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local lOk      := .T.
Local oMdlFull := FwModelActive()
Local nValDel  := 0
Local nTotAtual := 0
Local oMdlUse  := Nil

If oMdlFull <> Nil .And. (oMdlFull:GetId()=='TECA740' .Or. oMdlFull:GetId()=='TECA740F')
	If cAcao == 'DELETE'
		//-----------------------------------------------
		//  Atualiza o item da locação vinculado
		oMdlUse := oMdlFull:GetModel('TFL_LOC')
		
		nValDel := oMdlG:GetValue('TFI_TOTAL')
		nTotAtual := oMdlUse:GetValue('TFL_TOTLE')
		nTotAtual -= nValDel
		
		lOk := oMdlUse:SetValue('TFL_TOTLE', nTotAtual )
				
		If lOk .And. !Empty(oMdlG:GetValue('TFI_CHVTWO')) .And. !IsInCallStack('A740LoadFa') .And. !Empty(oMdlG:GetValue('TFI_PRODUT'))
			// verifica se tem permissão para a exclusão de itens importados pelo facilitador
			If !At680Perm( , __cUserId, '036' )
				lOk := .F.
				Help(,,'A740TFITWOD',, STR0100,1,0)	//"Item não pode ser desabilitado, pois o mesmo foi adicionado pelo facilitador"
			EndIf
		EndIf
		
	ElseIf cAcao == 'UNDELETE'
	
		//-----------------------------------------------
		//  Atualiza o item da locação vinculado
		oMdlUse := oMdlFull:GetModel('TFL_LOC')
		
		nValDel := oMdlG:GetValue('TFI_TOTAL')
		nTotAtual := oMdlUse:GetValue('TFL_TOTLE')
		nTotAtual += nValDel
		
		lOk := oMdlUse:SetValue('TFL_TOTLE', nTotAtual )
		
		If lOk .And. !Empty(oMdlG:GetValue('TFI_CHVTWO')) .And. !IsInCallStack('A740LoadFa') .And. !Empty(oMdlG:GetValue('TFI_PRODUT'))
			If !At680Perm( , __cUserId, '036' )
				lOk := .F.
				Help(,,'A740TFITWOH',, STR0101,1,0)	//"Item não pode ser habilitado, pois o mesmo foi adicionado pelo facilitador"
			EndIf
		EndIf
	EndIf	
EndIf

Return lOk

//-----------------------------------------------
// atualização de exclusão da TFG
Function PreLinTFG(oMdlG, nLine, cAcao, cCampo,xVal,xValAtu)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local lOk      := .T.
Local oMdlFull := oMdlG:GetModel()
Local nValDel  := 0
Local nTotAtual := 0
Local oMdlUse  := Nil
Local cTipRev 	:= ''
Local cVal		:= ""

If oMdlFull <> Nil .And. (oMdlFull:GetId()=='TECA740' .Or. oMdlFull:GetId()=='TECA740F')
	
	If cAcao == 'DELETE'			 
		If oMdlG:GetValue("TFG_COBCTR") <> "2"
			//-----------------------------------------------
			//  Atualiza o item da locação vinculado
			If oMdlFull:GetId() == 'TECA740F'
				oMdlUse	:= oMdlFull:GetModel('TFL_LOC')
				
				
				nValDel	:= oMdlG:GetValue('TFG_TOTGER')
				nTotAtual	:= oMdlUse:GetValue('TFL_TOTMI')
				nTotAtual	-= nValDel
				
				lOk			:= oMdlUse:SetValue('TFL_TOTMI', nTotAtual ) .Or. IsInCallStack('A740LoadFa')
			Else
				oMdlUse	:= oMdlFull:GetModel('TFF_RH')
				
				
				nValDel	:= oMdlG:GetValue('TFG_TOTGER')
				nTotAtual	:= oMdlUse:GetValue('TFF_TOTMI')
				nTotAtual	-= nValDel
				
				If IsInCallStack("At870GerOrc") .And. !oMdlUse:CanUpdateLine()
					oMdlUse:SetNoUpdateLine(.F.)
				Endif
				
				lOk			:= oMdlUse:SetValue('TFF_TOTMI', nTotAtual ) .Or. IsInCallStack('A740LoadFa')

				If IsInCallStack("At870GerOrc") .And. oMdlUse:CanUpdateLine()
					oMdlUse:SetNoUpdateLine(.T.)
				Endif
				
				If IsInCallStack("At870Revis") .And. oMdlG:IsUpdated()
				
					//Verifica se o item a ser deletada possui apontamento
					If At890ChkAp(GetMdlRev(),"TFG",nLine)
						lOk := .F.
						oMdlG:GetModel():SetErrorMessage(oMdlG:GetId(),cCampo,oMdlG:GetModel():GetId(),	cCampo,cCampo,; 
									STR0157, "" )//"O item possui apontamento ativo, não é possivel realizar a exclusão"	
						
					EndIf
					
					If !At740CkNew(GetMdlRev(),nLine,"TFG_MI","TFG") .And. lOk //Não pode excluir produto NORMAL e ITEM EXTRA na revisão.
						lOk := .F.
						oMdlG:GetModel():SetErrorMessage(oMdlG:GetId(),cCampo,oMdlG:GetModel():GetId(),	cCampo,cCampo,; 
									STR0158, "" )//"Não é permitido excluir itens de materiais na revisão, utilize o Período Final."
						
					EndIf
					
				EndIf
				
			EndIf
		Else
			lOk := (IsInCallStack("At740Cortesia") .Or. IsInCallStack("A600GrvOrc") .Or. IsInCallStack("At870GerOrc") )
			If !lOk 
				Help(,,"AT740OK",,STR0046,1,0) // "Operação não permitida para os itens adicionais!"
			EndIf
		EndIf
		
		If lOk .And. !Empty(oMdlG:GetValue('TFG_CHVTWO')) .And. !IsInCallStack('A740LoadFa') .And. !Empty(oMdlG:GetValue('TFG_PRODUT'))
			// verifica se tem permissão para a exclusão de itens importados pelo facilitador
			If !At680Perm( , __cUserId, '036' )
				lOk := .F.
				Help(,,'A740TFGTWOD',, STR0100,1,0)	//"Item não pode ser desabilitado, pois o mesmo foi adicionado pelo facilitador"
			EndIf
		EndIf
									
	ElseIf cAcao == 'UNDELETE'
		If oMdlG:GetValue("TFG_COBCTR") <> "2"
			//-----------------------------------------------
			//  Atualiza o item da locação vinculado
			If oMdlFull:GetId() == 'TECA740F'
				oMdlUse := oMdlFull:GetModel('TFL_LOC')
				
				
				nValDel := oMdlG:GetValue('TFG_TOTGER')
				nTotAtual := oMdlUse:GetValue('TFL_TOTMI')
				nTotAtual += nValDel
				
				lOk := oMdlUse:SetValue('TFL_TOTMI', nTotAtual ) .Or. IsInCallStack('A740LoadFa')
			Else
				oMdlUse := oMdlFull:GetModel('TFF_RH')
				
				
				nValDel := oMdlG:GetValue('TFG_TOTGER')
				nTotAtual := oMdlUse:GetValue('TFF_TOTMI')
				nTotAtual += nValDel
				
				If IsInCallStack("At870GerOrc") .And. !oMdlUse:CanUpdateLine()
					oMdlUse:SetNoUpdateLine(.F.)
				Endif
				
				lOk := oMdlUse:SetValue('TFF_TOTMI', nTotAtual ) .Or. IsInCallStack('A740LoadFa')

				If IsInCallStack("At870GerOrc") .And. oMdlUse:CanUpdateLine()
					oMdlUse:SetNoUpdateLine(.T.)
				Endif

			EndIf
		Else
			lOk := IsInCallStack("At740Cortesia")
			If !lOk 
				Help(,,"AT740OK",,STR0046,1,0) // "Operação não permitida para os itens adicionais!"
			EndIf
		EndIf									
											
		If lOk .And. !Empty(oMdlG:GetValue('TFG_CHVTWO')) .And. !IsInCallStack('A740LoadFa') .And. !Empty(oMdlG:GetValue('TFG_PRODUT'))
			// verifica se tem permissão para a exclusão de itens importados pelo facilitador
			If !At680Perm( , __cUserId, '036' )
				lOk := .F.
				Help(,,'A740TFGTWOH',, STR0101,1,0)	//"Item não pode ser habilitado, pois o mesmo foi adicionado pelo facilitador"
			EndIf
		EndIf
									
	ElseIf cAcao == "SETVALUE"	 
		If !IsInCallStack("ATCPYDATA") .And. !IsInCallStack("At740Cortesia") .And.; 
			!IsInCallStack("A600GrvOrc") .And. !IsInCallStack("At870GerOrc") .And.;
			!IsInCallStack("LoadXmlData")  
			lOk := !(oMdlG:GetValue("TFG_COBCTR")=="2")
			
			If lOk .And. oMdlFull:GetValue('TFF_RH','TFF_ENCE') == '1' .And. oMdlG:IsUpdated()
				Help( ' ' , 1 , 'AT740ENCE' , ,  STR0159, 1 , 0 ) // "Não é permitida alteração de itens encerrados."
				lOk := .F.
			Endif
		EndIf
		
		If (IsInCallStack("At870Revis") .And. oMdlG:IsUpdated()) .And. (cCampo == "TFG_QTDVEN" .And. ((xValAtu > 0 .And. !At740CkNew(GetMdlRev(),nLine,"TFG_MI","TFG")) .And. xValAtu <> xVal ))
			If At890ChkQtd(GetMdlRev(),"TFG",nLine,xVal,@cVal)
				FwClearHLP()
				lOk := .F.
					oMdlG:GetModel():SetErrorMessage(oMdlG:GetId(),cCampo,oMdlG:GetModel():GetId(),	cCampo,cCampo,; 
									STR0178, STR0179 + cVal )//"A Quantidade informada é menor do que já foi apontado"##"Informe um valor maior ou igual a "	
				
			EndIf
		EndIf
				
	ElseIf cAcao == "CANSETVALUE"
		If IsInCallStack("At870Revis") .AND. !IsInCallStack("At740Cortesia") .AND. oMdlG:GetValue("TFG_TIPMAT") <> "3" //Item Normal
			lOk := .F.
			Help( ' ' , 1 , 'AT740ALT' , ,  STR0160, 1 , 0 ) //"Não é permitida alteração de itens adicionais durante a revisão."
		EndIf
	EndIf
	
EndIf

Return lOk

//-----------------------------------------------
// atualização de exclusão da TFH
Function PreLinTFH(oMdlG, nLine, cAcao, cCampo,xVal,xValAtu)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local lOk      := .T.
Local oMdlFull := oMdlG:GetModel()
Local nValDel  := 0
Local nTotAtual := 0
Local oMdlUse  := Nil
Local cTipRev 	:= ''
Local cVal		:= ""

If oMdlFull <> Nil .And. (oMdlFull:GetId()=='TECA740' .Or. oMdlFull:GetId()=='TECA740F')

	If cAcao == 'DELETE'
		
		If oMdlG:GetValue("TFH_COBCTR") <> "2"
			//-----------------------------------------------
			//  Atualiza o item da locação vinculado
			If oMdlFull:GetId() == 'TECA740F'
				oMdlUse	:= oMdlFull:GetModel('TFL_LOC')
				
				
				nValDel	:= oMdlG:GetValue('TFH_TOTGER')
				nTotAtual	:= oMdlUse:GetValue('TFL_TOTMC')
				nTotAtual	-= nValDel
				
				lOk	:= oMdlUse:SetValue('TFL_TOTMC', nTotAtual ) .Or. IsInCallStack('A740LoadFa')
			Else
				oMdlUse	:= oMdlFull:GetModel('TFF_RH')
				
				
				nValDel	:= oMdlG:GetValue('TFH_TOTGER')
				nTotAtual	:= oMdlUse:GetValue('TFF_TOTMC')
				nTotAtual	-= nValDel
				
				If IsInCallStack("At870GerOrc") .And. !oMdlUse:CanUpdateLine()
					oMdlUse:SetNoUpdateLine(.F.)
				Endif
				
				lOk	:= oMdlUse:SetValue('TFF_TOTMC', nTotAtual ) .Or. IsInCallStack('A740LoadFa')

				If IsInCallStack("At870GerOrc") .And. oMdlUse:CanUpdateLine()
					oMdlUse:SetNoUpdateLine(.T.)
				Endif
				
				If IsInCallStack("At870Revis") .And. oMdlG:IsUpdated()
					//Verifica se o item a ser deletada possui apontamento
					If At890ChkAp(GetMdlRev(),"TFH",nLine)
						lOk := .F.
						oMdlG:GetModel():SetErrorMessage(oMdlG:GetId(),cCampo,oMdlG:GetModel():GetId(),	cCampo,cCampo,; 
									STR0161, "" )//"O item possui apontamento ativo, não é possivel realizar a exclusão"		
						
					EndIf
					
					If !At740CkNew(GetMdlRev(),nLine,"TFH_MC","TFH") .And. lOk  //Não pode excluir produto NORMAL e ITEM EXTRA na revisão.
						lOk := .F.
						oMdlG:GetModel():SetErrorMessage(oMdlG:GetId(),cCampo,oMdlG:GetModel():GetId(),	cCampo,cCampo,; 
									STR0162, "" )//"Não é permitido excluir itens de materiais na revisão, utilize o Período Final."	
						
					EndIf
				EndIf
				
			EndIf
		Else
			lOk := IsInCallStack("At740Cortesia") .Or. IsInCallStack("A600GrvOrc") .Or. IsInCallStack('A740LoadFa')
			If !lOk
				Help(,,"AT740OK",,STR0046,1,0) // "Operação não permitida para os itens adicionais!"
			EndIf
		EndIf
		
		If lOk .And. !Empty(oMdlG:GetValue('TFH_CHVTWO')) .And. !IsInCallStack('A740LoadFa') .And. !Empty(oMdlG:GetValue('TFH_PRODUT'))
			// verifica se tem permissão para a exclusão de itens importados pelo facilitador
			If !At680Perm( , __cUserId, '036' )
				lOk := .F.
				Help(,,'A740TFHTWOD',, STR0100,1,0)	//"Item não pode ser desabilitado, pois o mesmo foi adicionado pelo facilitador"
			EndIf
		EndIf
		
	ElseIf cAcao == 'UNDELETE'
	
		If oMdlG:GetValue("TFH_COBCTR") <> "2"
			//-----------------------------------------------
			//  Atualiza o item da locação vinculado
			If oMdlFull:GetId() == 'TECA740F'
				oMdlUse := oMdlFull:GetModel('TFL_LOC')
				
				
				nValDel := oMdlG:GetValue('TFH_TOTGER')
				nTotAtual := oMdlUse:GetValue('TFL_TOTMC')
				nTotAtual += nValDel
				
				lOk := oMdlUse:SetValue('TFL_TOTMC', nTotAtual ) 
			Else
				oMdlUse := oMdlFull:GetModel('TFF_RH')
				
				
				nValDel := oMdlG:GetValue('TFH_TOTGER')
				nTotAtual := oMdlUse:GetValue('TFF_TOTMC')
				nTotAtual += nValDel
				
				If IsInCallStack("At870GerOrc") .And. !oMdlUse:CanUpdateLine()
					oMdlUse:SetNoUpdateLine(.F.)
				Endif
				
				lOk := oMdlUse:SetValue('TFF_TOTMC', nTotAtual ) 

				If IsInCallStack("At870GerOrc") .And. oMdlUse:CanUpdateLine()
					oMdlUse:SetNoUpdateLine(.T.)
				Endif

			EndIf
		Else
			lOk := IsInCallStack("At740Cortesia")
			If !lOk
				Help(,,"AT740OK",,STR0046,1,0) // "Operação não permitida para os itens adicionais!"
			EndIf
		EndIf			
			
		If lOk .And. !Empty(oMdlG:GetValue('TFH_CHVTWO')) .And. !IsInCallStack('A740LoadFa') .And. !Empty(oMdlG:GetValue('TFH_PRODUT'))
			// verifica se tem permissão para a exclusão de itens importados pelo facilitador
			If !At680Perm( , __cUserId, '036' )
				lOk := .F.
				Help(,,'A740TFHTWOH',, STR0101,1,0)	//"Item não pode ser habilitado, pois o mesmo foi adicionado pelo facilitador"
			EndIf
		EndIf
			
	ElseIf cAcao == "SETVALUE"	
		If !IsInCallStack("ATCPYDATA") .And. !IsInCallStack("At740Cortesia") .And.; 
			!IsInCallStack("A600GrvOrc") .And. !IsInCallStack("At870GerOrc") .And.;
			!IsInCallStack("LoadXmlData")		
			lOk := (!oMdlG:GetValue("TFH_COBCTR")=="2")

			If lOk .And. oMdlFull:GetValue('TFF_RH','TFF_ENCE') == '1' .And. oMdlG:IsUpdated()
				Help( ' ' , 1 , 'AT740ENCE' , ,  STR0159, 1 , 0 ) // "Não é permitida alteração de itens encerrados."
				lOk := .F.
			Endif
			
			If (IsInCallStack("At870Revis") .And. oMdlG:IsUpdated()) .And. (cCampo == "TFH_QTDVEN" .And. ((xValAtu > 0 .And. !At740CkNew(GetMdlRev(),nLine,"TFH_MC","TFH")) .And. xValAtu <> xVal ))
				If At890ChkQtd(GetMdlRev(),"TFH",nLine,xVal,@cVal)
					FwClearHLP()
					lOk := .F.
					oMdlG:GetModel():SetErrorMessage(oMdlG:GetId(),cCampo,oMdlG:GetModel():GetId(),	cCampo,cCampo,; 
									STR0178, STR0179 + cVal )//"A Quantidade informada é menor do que já foi apontado"##"Informe um valor maior ou igual a "	
				
				EndIf
			EndIf
			
		EndIf		
	EndIf

EndIf

Return lOk

//-----------------------------------------------
// atualização de exclusão da TFF
Function PreLinTFF(oMdlG, nLine, cAcao, cCampo, xValue, xOldValue)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local lOk      := .T.
Local oMdlFull := oMdlG:GetModel()
Local oVwFull  := FwViewActive()
Local nValDel  := 0
Local nTotAtual := 0
Local oMdlUse  := Nil
Local lOkSly 	:= AliasInDic('SLY')
Local cTipRev 	:= ''
Local dDatIni
Local dDatFim
Local nMesVlr 	:= 0
Local nValMes	:= 0
Local lOrcPrc 	:= SuperGetMv("MV_ORCPRC",,.F.)		//Verifica se usa a tabela de precificação
Local nQtde		:= 0 //Quantidade da Grid
Local cEscala	:= "" //Escala da Grid

If oMdlFull <> Nil .And. (oMdlFull:GetId()=='TECA740' .Or. oMdlFull:GetId()=='TECA740F') .And. ; 
	!IsInCallStack('At740Cortesia') .And. !IsInCallStack('At870GerOrc')
	
	If cAcao == 'DELETE'
		
		//-----------------------------------------------
		//  Atualiza o item da locação vinculado
		oMdlUse := oMdlFull:GetModel('TFL_LOC')
		
		
		// valor do RH
		nValDel := oMdlG:GetValue('TFF_SUBTOT')
		nTotAtual := oMdlUse:GetValue('TFL_TOTRH')
		nTotAtual -= nValDel	
		
		lOk := oMdlUse:SetValue('TFL_TOTRH', nTotAtual )
		
		If lOrcPrc
			//valor mensal do RH
			dDatIni	:= oMdlG:GetValue('TFF_PERINI')
			dDatFim	:=  oMdlG:GetValue('TFF_PERFIM')	
			
			nMesVlr := At740FDDiff( dDatIni, dDatFim )
				
			If nMesVlr > 0
				nValMes := ( nValDel / nMesVlr )
			EndIf
			
			nTotAtual := oMdlUse:GetValue('TFL_MESRH')
			nTotAtual -= nValMes	
			
			lOk := oMdlUse:SetValue('TFL_MESRH', nTotAtual )
		EndIf
		
		// valor do Material de Implantação
		nValDel := oMdlG:GetValue('TFF_TOTMI')
		nTotAtual := oMdlUse:GetValue('TFL_TOTMI')
		nTotAtual -= nValDel
		
		lOk := oMdlUse:SetValue('TFL_TOTMI', nTotAtual )
		
		// valor do Material de Consumo
		nValDel := oMdlG:GetValue('TFF_TOTMC')
		nTotAtual := oMdlUse:GetValue('TFL_TOTMC')
		nTotAtual -= nValDel
		
		lOk := oMdlUse:SetValue('TFL_TOTMC', nTotAtual )
		
		If lOk .And. !Empty(oMdlG:GetValue('TFF_CHVTWO')) .And. !IsInCallStack('A740LoadFa') .And. !Empty(oMdlG:GetValue('TFF_PRODUT'))
			// verifica se tem permissão para a exclusão de itens importados pelo facilitador
			If !At680Perm( , __cUserId, '036' )
				lOk := .F.
				Help(,,'A740TFFTWOD',, STR0100,1,0)	//"Item não pode ser desabilitado, pois o mesmo foi adicionado pelo facilitador"
			EndIf
		EndIf		
		
	ElseIf cAcao == 'UNDELETE'
	
		//-----------------------------------------------
		//  Atualiza o item da locação vinculado
		oMdlUse := oMdlFull:GetModel('TFL_LOC')
		
		
		// valor do RH
		nValDel := oMdlG:GetValue('TFF_SUBTOT')
		nTotAtual := oMdlUse:GetValue('TFL_TOTRH')
		nTotAtual += nValDel
		
		lOk := oMdlUse:SetValue('TFL_TOTRH', nTotAtual )
		
		//valor mensal do RH
		dDatIni	:= oMdlG:GetValue('TFF_PERINI')
		dDatFim	:=  oMdlG:GetValue('TFF_PERFIM')	
		
		If lOrcPrc
		
			nMesVlr := At740FDDiff( dDatIni, dDatFim )
				
			If nMesVlr > 0
				nValMes := ( nValDel / nMesVlr )
			EndIf
			
			nTotAtual := oMdlUse:GetValue('TFL_MESRH')
			nTotAtual += nValMes	
			
			lOk := oMdlUse:SetValue('TFL_TOTRH', nTotAtual ) //.And. Empty(oMdlG:GetValue('TFF_CHVTWO'))
		
		EndIf
		// valor do Material de Implantação
		nValDel := oMdlG:GetValue('TFF_TOTMI')
		nTotAtual := oMdlUse:GetValue('TFL_TOTMI')
		nTotAtual += nValDel
		
		lOk := oMdlUse:SetValue('TFL_TOTMI', nTotAtual )
		
		// valor do Material de Consumo
		nValDel := oMdlG:GetValue('TFF_TOTMC')
		nTotAtual := oMdlUse:GetValue('TFL_TOTMC')
		nTotAtual += nValDel
		
		lOk := oMdlUse:SetValue('TFL_TOTMC', nTotAtual )
				
		If lOk .And. !Empty(oMdlG:GetValue('TFF_CHVTWO')) .And. !IsInCallStack('A740LoadFa') .And. !Empty(oMdlG:GetValue('TFF_PRODUT'))
			// verifica se tem permissão para a exclusão de itens importados pelo facilitador
			If !At680Perm( , __cUserId, '036' )
				lOk := .F.
				Help(,,'A740TFFTWOH',, STR0100,1,0)	//"Item não pode ser desabilitado, pois o mesmo foi adicionado pelo facilitador"
			EndIf
		EndIf
		
	ElseIf (cAcao == 'SETVALUE') .AND.  (oMdlFull:GetId()=='TECA740F')

		If cCampo == 'TFF_DESCRI'
			//  Atualiza o item da locação vinculado
			At740FGSS(oMdlFull)
		ElseIf (cCampo == 'TFF_PRCVEN') .And. !IsInCallStack('At740EEPC') .And. oMdlG:HasField('TFF_PROCES')  
			oMdlG:LoadValue('TFF_PROCES',.F.)  
		EndIf

	ElseIf cAcao == 'CANSETVALUE' .AND. IsInCallStack('At870Revis') .And. !( IsInCallStack("Initdados") .Or. IsInCallStack("AtCpyData") )
		IF oMdlG:GetValue('TFF_COBCTR') == '2' .AND. oMdlG:IsUpdated()
			Help( ' ' , 1 , 'AT740EXTRA' , ,  STR0064, 1 , 0 ) // "Não é permitida alteração de itens extras"
			lOk := .F.
		Elseif oMdlG:GetValue('TFF_ENCE') == '1' .And. oMdlG:IsUpdated() .And. ValType(oVwFull) == "O" .And. oVwFull:IsActive().And. oVwFull:GetModel():GetId() == "TECA740"
			Help( ' ' , 1 , 'AT740ENCE' , ,  STR0159, 1 , 0 ) // "Não é permitida alteração de itens encerrados."
			lOk := .F.
		ENDIF		
	ElseIf 	(cAcao == 'SETVALUE') .AND.  (RTrim(oMdlFull:GetId())=='TECA740')
	
		If lOK .AND. _lGSVinc .and. RTrim(cCampo) $ "TFF_PRODUT|TFF_QTDVEN|TFF_ESCALA" .AND.   !Empty(xValue)
		
			If RTrim(cCampo) == "TFF_PRODUT" .AND. xValue != xOldValue
			   At994DlIt(oMdlFull, xValue)
			ElseIf  (RTrim(cCampo) $ "TFF_QTDVEN"  .AND.  Max(xValue,1) != Max( xOldValue, 1)) .OR. (RTrim(cCampo) $ "TFF_ESCALA" .AND. xValue != xOldValue ) 	
					
				nQtde		:= iif(cCampo == "TFF_ESCALA",FwfldGet("TFF_QTDVEN"),xValue) //Quantidade da Grid
				cEscala		:= iif(cCampo == "TFF_ESCALA",xValue,oMdlG:GetValue('TFF_ESCALA'))
				//Recalcula as quantidades dos itens de MI/MC Inseridos no modelo
				At994RcQtd(oMdlFull, nQtde, cEscala )
			EndIf
		
		EndIf
	EndIf

	IF lOk .And. lOkSly
		// Durante a revisão do contrato não deverá ser possível realizar alteração do turno ou da escala
		// de um item de recursos humanos caso exista um benefício vinculado sem uma data final definida
		IF cAcao == 'SETVALUE' .AND. IsInCallStack('At870Revis') .And. !( IsInCallStack("Initdados") .Or. IsInCallStack("AtCpyData") )
			IF oMdlG:IsUpdated() .AND. ( cCampo $ "TFF_TURNO|TFF_ESCALA" ) 
				lOk := At740VerVB(oMdlG:GetValue('TFF_COD'))
				
				IF !lOk
					Help(,,"PreLinTFF",, STR0081,1,0) // "Existem Vínculos de Benefícios ativos, não é possível realizar a alteração do turno ou da escala"
				ENDIF
			ENDIF		
		ENDIF
	ENDIF
ElseIf !IsInCallStack('At740Cortesia') .And. !IsInCallStack('At870GerOrc')
	If cAcao == "DELETE" .Or. cAcao == "UNDELETE"
		lOk := .F.
		Help(,,"AT740OK",,STR0046,1,0) // "Operação não permitida para os itens adicionais!"
	EndIf
EndIf


FWRestRows( aSaveLines )
RestArea(aArea)
Return lOk

//------------------------------------------------------------------------------
/*/{Protheus.doc} PreLinTFL
	Função de Prevalidacao da grade de locais de atendimento
@sample 	PreLinTFL(oMdlG, nLine, cAcao, cCampo)
@param		[oMdlG],objeto,Representando o modelo de dados.
@param		[nLine],numerico,Numero da linha em edição
@param		[cAcao],Caractere,Ação sendo executada.
@param		[cCampo],Caractere,Campo onde o cursor está posicionado.

@since		17/03/2015     
@version	P12

/*/
//------------------------------------------------------------------------------
Function PreLinTFL1(oMdlG, nLine, cAcao, cCampo)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local lRet := .T.
Local oMdlFull := If(oMdlG <> nil, oMdlG:GetModel(), nil)

If lRet .And. oMdlFull <> Nil .And.;
	!IsInCallStack('At740Cortesia') .And.;
	!IsInCallStack('At870GerOrc')
	
	If cAcao == 'SETVALUE'
		If cCampo == 'TFL_DESLOC'
			//  Atualiza o item da locação vinculado
			At740fATFL( oMdlFull:GetModel('TFL_LOC') )
		EndIf
    EndIf
EndIf  

FWRestRows( aSaveLines )
RestArea(aArea)
Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} PosLinTFF
	 Permite a inclusão de valores zerados para a cortesia

@sample		PosLinTFF()

@since		15/04/2014
@version	P12

/*/
//------------------------------------------------------------------------------
Function PosLinTFF(oMdlG, nLine, cAcao, cCampo)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local lRet      := .T.
Local oMdlFull := oMdlG:GetModel()
Local cTipRev := ''

If oMdlFull <> Nil .And. (oMdlFull:GetId()=='TECA740' .Or. oMdlFull:GetId()=='TECA740F')	
	If !cAcao == "DELETE" .And. !IsInCallStack("ATCPYDATA") .And. !IsInCallStack("At740Cortesia")
		If oMdlG:GetValue("TFF_COBCTR") == "1" .And. cAcao <> Nil
			lRet := At740VlVlr("TFF_RH","TFF_PRCVEN")
		EndIf		
	EndIf
EndIf

If lRet 
	If oMdlG:GetValue("TFF_INSALU") == "1" .And. oMdlG:GetValue("TFF_GRAUIN") <> "1"
		Help(,,"TFFINSALU1",, STR0066, 1, 0) //'Atenção'#"Itens que não possuem Insalubridade não devem ter Grau preenchido"
		lRet := .F.	
	ElseIf oMdlG:GetValue("TFF_INSALU") <> "1" .And. oMdlG:GetValue("TFF_GRAUIN") == "1"
		Help(,,"TFFINSALU2",, STR0067, 1, 0) //'Atenção'#"Existem Itens que possuem Insalubridade sem o Grau preenchido"
		lRet := .F.
	ElseIf !Empty( oMdlG:GetValue("TFF_PRODUT") ) .And. Empty( oMdlG:GetValue("TFF_TURNO") ) .And. Empty( oMdlG:GetValue("TFF_ESCALA") ) .And. !IsInCallStack("A740LoadFa")
		Help(,, "RHTURNO",,STR0133,1,0,,,,,,{STR0134})  // "Campos de Turno e Escala não estão preenchidos." ###  "Preencha algum destes campos para prosseguir."
		lRet := .F.
	Elseif oMdlFull:GetValue("TFJ_REFER","TFJ_GSMTMI") $ "2|3" .And. Empty(oMdlG:GetValue("TFF_PDMTMI")) .And. oMdlG:GetValue("TFF_VLMTMI") > 0
		Help(,, "PRODMATMI",,STR0163,1,0,,,,,,{STR0164}) //"O campo de valor do material de implantação é maior que zero e o produto do material por valor não está preenchido." #"Preencha o campo de produto do material de implantação para prosseguir."
		lRet := .F.
	Elseif oMdlFull:GetValue("TFJ_REFER","TFJ_GSMTMC") $ "2|3" .And. Empty(oMdlG:GetValue("TFF_PDMTMC")) .And. oMdlG:GetValue("TFF_VLMTMC") > 0
		Help(,, "PRODMATMC",,STR0165,1,0,,,,,,{STR0166}) //"O campo de valor do material de consumo é maior que zero e o produto do material por valor não está preenchido."#"Preencha o campo de produto do material de consumo para prosseguir." 
		lRet := .F.
	Elseif oMdlFull:GetValue("TFJ_REFER","TFJ_GSMTMI") $ "2|3" .And. !Empty(oMdlG:GetValue("TFF_PDMTMI")) .And. oMdlG:GetValue("TFF_VLMTMI") == 0
		Help(,, "VALORMATMI",,STR0167,1,0,,,,,,{STR0168})  //"O campo de protudo do material de implantação está preenchido e o campo de valor do material não está preenchido."# "Preencha o campo de valor do material de implantação para prosseguir."
		lRet := .F.
	Elseif oMdlFull:GetValue("TFJ_REFER","TFJ_GSMTMC") $ "2|3" .And. !Empty(oMdlG:GetValue("TFF_PDMTMC")) .And. oMdlG:GetValue("TFF_VLMTMC") == 0
		Help(,, "VALORMATMC",,STR0169,1,0,,,,,,{STR0170}) //"O campo de protudo do material de consumo está preenchido e o campo de valor do material não está preenchido." # "Preencha o campo de valor do material de consumo para prosseguir."
		lRet := .F.
	EndIf
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return(lRet)

//------------------------------------------------------------------------------
/*/{Protheus.doc} PosLinTFG
	 Permite a inclusão de valores zerados para a cortesia

@sample		PosLinTFG()

@since		16/04/2014
@version	P12

/*/
//------------------------------------------------------------------------------
Function PosLinTFG(oMdlG, nLine, cAcao, cCampo)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local lRet      := .T.
Local oMdlFull := oMdlG:GetModel()
Local cTipRev := ''

If oMdlFull <> Nil .And. (oMdlFull:GetId()=='TECA740' .Or. oMdlFull:GetId()=='TECA740F')
	If !cAcao == "DELETE" .And. !IsInCallStack("ATCPYDATA") .And. !IsInCallStack("At740Cortesia")
		If oMdlG:GetValue("TFG_COBCTR") == "1" .And. cAcao <> Nil
			lRet := At740VlVlr("TFG_MI","TFG_PRCVEN")
		EndIf		
	EndIf	
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return(lRet)


//------------------------------------------------------------------------------
/*/{Protheus.doc} PosLinTFH
	 Permite a inclusão de valores zerados para a cortesia

@sample		PosLinTFH()

@since		16/04/2014
@version	P12

/*/
//------------------------------------------------------------------------------
Function PosLinTFH(oMdlG, nLine, cAcao, cCampo)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local lRet      := .T.
Local oMdlFull := oMdlG:GetModel()

If oMdlFull <> Nil .And. (oMdlFull:GetId()=='TECA740' .Or. oMdlFull:GetId()=='TECA740F')
	If !cAcao == "DELETE" .And. !IsInCallStack("ATCPYDATA") .And. !IsInCallStack("At740Cortesia")
		If oMdlG:GetValue("TFH_COBCTR") == "1" .And. cAcao <> Nil
			lRet := At740VlVlr("TFH_MC","TFH_PRCVEN")
		EndIf		
	EndIf
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return(lRet)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At740VldUM
	 Valida a unidade de medida digitada 

@sample		At740VldUM()

@since		19/12/2013
@version	P11.90

@return 	lValido, Logico, define se a unidade de medida é valida (.T.) ou não (.F.)
/*/
//------------------------------------------------------------------------------
Function At740VldUM()
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local lValido := .F.

lValido := Empty( M->TEV_UM )

If !lValido
	DbSelectArea('SAH')
	SAH->( DbSetOrder( 1 ) )  // AH_FILIAL+AH_UNIMED

	lValido := SAH->( DbSeek( xFilial('SAH')+M->TEV_UM ) )
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return lValido

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740Reserv
	 Valida a alteração de qtde e as datas nos itens com reserva 

@sample		At740Reserv()

@since		24/02/2014
@version	P12

@return 	lRet, Logico, define se prossegue com a alteração ou não
/*/
//------------------------------------------------------------------------------
Function At740Reserv( oMdl, cCampo, xValueNew, nLine, xValueOld )
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local lRet        := .T.

If !IsInCallStack('At740CpyMdl') .And. !Empty( oMdl:GetValue('TFI_RESERV') )

	lRet := MsgNoYes( STR0039 + CRLF + ;  // 'Esta alteração fará com que a reserva seja cancelada'
				STR0040, STR0041 )  // 'Deseja prosseguir?' #### 'Aviso' 
	
	If lRet
		aAdd( aCancReserv, { oMdl:GetValue('TFI_COD'), oMdl:GetValue('TFI_RESERV') } )
		oMdl:SetValue('TFI_RESERV', ' ' ) // remove a relação com a reserva
	EndIf
	
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740FinRes
	 Executa a finalização quando realiza a gravação do orçamento de serviços 

@sample		At740FinRes()

@since		24/02/2014
@version	P12

@param 	oMdlOrcamento, objeto, objeto principal do orçamento de serviços
@param 	lGravação, logico, define se está na gravação ou no cancelamento (fechar sem salvar)
/*/
//------------------------------------------------------------------------------
Function At740FinRes( oOrcamento, lCommit )
Local aSave         := GetArea()
Local aSaveTFI       := TFI->( GetArea() )
Local aSaveTEW       := TEW->( GetArea() )
Local aSaveLines	:= FWSaveRows()
Local nLocais       := 0
Local nItensLE      := 0
Local oReserva      := FwLoadModel('TECA825C')
Local aRows         := FwSaveRows(oOrcamento)
Local oLocais       := oOrcamento:GetModel('TFL_LOC')
Local oItensLE      := oOrcamento:GetModel('TFI_LE')
Local nPosReserv     := 0
Local nTamDados      := 0
Local xAux          := Nil
Local lOk           := .T.

DbSelectArea('TFI')
TFI->( DbSetOrder( 6 ) ) // TFI_FILIAL+TFI_RESERV

For nLocais := 1 To oLocais:Length()

	oLocais:GoLine( nLocais )
	For nItensLE := 1 To oItensLE:Length()
	
		oItensLE:GoLine( nItensLE )
		nPosReserv := aScan( aCancReserv, {|x| x[1] == oItensLE:GetValue('TFI_COD') } )
		If nPosReserv > 0
			If lCommit .And. TFI->(DbSeek(xFilial('TFI')+aCancReserv[nPosReserv,2]))
				//---------------------------------------
				//   Executa o cancelamento das reservas
				oReserva:SetOperation(MODEL_OPERATION_UPDATE)
				
				At825CText( STR0042 )  // 'Item da venda de locação alterado'
				At825CTipo( DEF_RES_CANCELADA )
				
				lOk := oReserva:Activate()  // Ativa o objeto
				lOk := oReserva:VldData()  // Valida os dados
				lOk := oReserva:CommitData()   // realiza o cancelamento
				
				If !lOk
					oReserva:CancelData()
				EndIf
				
				oReserva:DeActivate()
			EndIf
			//---------------------------------------
			//   remove do array as informações da reserva
			nTamDados := Len(aCancReserv)
			aDel( aCancReserv, nPosReserv )
			aSize( aCancReserv, nTamDados-1 ) 
		EndIf
	
	Next nItensLE

Next nLocais

oReserva:Destroy()

FwRestRows( aRows, oOrcamento )
FWRestRows( aSaveLines )
RestArea( aSaveTEW )
RestArea( aSaveTFI )
RestArea( aSave )

Return
//------------------------------------------------------------------------------
/*/{Protheus.doc} At740LdLuc
	 Atualiza a Taxa de Lucro e administrativa para os demais itens 

@sample		At740LdLuc()

@since		21/02/2013
@version	P11.90


/*/
//------------------------------------------------------------------------------
Function At740LdLuc(cTp)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oMdl   		:= FwModelActive()
Local oMdlLocal	:= oMdl:GetModel("TFL_LOC")
Local oMdlRH		:= oMdl:GetModel("TFF_RH")
Local oMdlMI		:= oMdl:GetModel("TFG_MI")
Local oMdlMC		:= oMdl:GetModel("TFH_MC")
Local oMdlLE 		:= oMdl:GetModel("TFI_LE")
Local oMdlCobLe		:= oMdl:GetModel("TEV_ADICIO")
Local nLinLocal	:= 0
Local nLinRh		:= 0
Local nLinMi		:= 0
Local nLinMc		:= 0
Local nLinLe		:= 0
Local nLinCob 		:= 0
Local nPerc		:= 0
Local lItemRh		:= .T.
Local lItemMi		:= .T.
Local lItemMc		:= .T.
Local lItemLe		:= .T.
Local aSaveRows 	:= {}
Local lValid		:= .F.
Local aValid		:= {}

aSaveRows := FwSaveRows()

If cTp == "1"
	nPerc := oMdl:GetModel( "TFJ_REFER" ):GetValue( "TFJ_LUCRO" )
Else
	nPerc := oMdl:GetModel( "TFJ_REFER" ):GetValue( "TFJ_ADM" )
EndIf

aValid := At740Valid(cTp,nPerc)

If Len(aValid) > 0
	If !IsInCallStack("u_TECA740")
		If MsgYesNo(STR0043)		//"Deseja substituir as taxas de valores já definidas para os itens?"
			lValid := .F.
		Else
			lValid := .T.
		EndIf
	Else
		lValid := .F.
	EndIf
EndIf

For nLinLocal := 1 To oMdlLocal:Length()

	oMdlLocal:GoLine( nLinLocal )
	
	If !oMdlLocal:IsDeleted()

		For nLinRh := 1 to oMdlRH:Length() //Recursos humanos
				
			oMdlRH:GoLine( nLinRh ) //Posiciona na linha
		
			If !oMdlRH:IsDeleted() //Se a linha não estiver deletada
					
				If !Empty(oMdlRH:GetValue("TFF_PRODUT"))
				
					If cTp == "1" //1 = Taxa de Lucro
					
						If !lValid
							oMdlRH:SetValue("TFF_LUCRO",nPerc)
						Else
							//Nao substituir
							nPos := Ascan(aValid,{|x| x[2] == "TFF"+Alltrim(STR(nLinRh))+"1"})
							If nPos > 0
								oMdlRH:SetValue("TFF_LUCRO",aValid[nPos,1])
							Else
								oMdlRH:SetValue("TFF_LUCRO",nPerc)	
							EndIf
						EndIf
					
					Else //2 = Taxa Administrativa
					
						If !lValid
							oMdlRH:SetValue("TFF_ADM",nPerc)
						Else
							//Nao substituir
							nPos := Ascan(aValid,{|x| x[2] == "TFF"+Alltrim(STR(nLinRh))+"2"})
							If nPos > 0
								oMdlRH:SetValue("TFF_ADM",aValid[nPos,1])
							Else
								oMdlRH:SetValue("TFF_ADM",nPerc)	
							EndIf
						EndIf		
						
					EndIf
				
				Else
				
					lItemRh := .F.
						
				EndIf	
					
					For nLinMi := 1 to oMdlMI:Length() //Materiais de Implantação
					
						oMdlMI:GoLine( nLinMi )
						
							If !oMdlMI:IsDeleted()
								
								If !Empty(oMdlMI:GetValue("TFG_PRODUT"))
								
									If cTp == "1" //1 = Taxa de Lucro
									
										If !lValid
											oMdlMI:SetValue("TFG_LUCRO",nPerc)
										Else
											//Nao substituir
											nPos := Ascan(aValid,{|x| x[2] == "TFG"+Alltrim(STR(nLinMi))+"1"})
											If nPos > 0
												oMdlMI:SetValue("TFG_LUCRO",aValid[nPos,1])
											Else
												oMdlMI:SetValue("TFG_LUCRO",nPerc)	
											EndIf
										EndIf
									
									Else //2 = Taxa Administrativa
										
										If !lValid
											oMdlMI:SetValue("TFG_ADM",nPerc)
										Else
											//Nao substituir
											nPos := Ascan(aValid,{|x| x[2] == "TFG"+Alltrim(STR(nLinMi))+"2"})
											If nPos > 0
												oMdlMI:SetValue("TFG_ADM",aValid[nPos,1])
											Else
												oMdlMI:SetValue("TFG_ADM",nPerc)	
											EndIf
										EndIf
									
									EndIf		
								
								Else
								
									lItemMi := .F.
								
								EndIf
								
							EndIf		
					
					Next nLinMi
					
					For nLinMc := 1 to oMdlMC:Length() //Materiais de Consumo
					
						oMdlMC:GoLine( nLinMc )
						
							If !oMdlMC:IsDeleted()
								
								If !Empty(oMdlMC:GetValue("TFH_PRODUT"))
								
									If cTp == "1" //1 = Taxa de Lucro
									
										If !lValid
											oMdlMC:SetValue("TFH_LUCRO",nPerc)
										Else
											//Nao substituir
											nPos := Ascan(aValid,{|x| x[2] == "TFH"+Alltrim(STR(nLinMc))+"1"})
											If nPos > 0
												oMdlMC:SetValue("TFH_LUCRO",aValid[nPos,1])
											Else
												oMdlMC:SetValue("TFH_LUCRO",nPerc)	
											EndIf
										EndIf	
									
									Else //2 = Taxa Administrativa
															
										If !lValid
											oMdlMC:SetValue("TFH_ADM",nPerc)
										Else
											//Nao substituir
											nPos := Ascan(aValid,{|x| x[2] == "TFH"+Alltrim(STR(nLinMc))+"2"})
											If nPos > 0
												oMdlMC:SetValue("TFH_ADM",aValid[nPos,1])
											Else
												oMdlMC:SetValue("TFH_ADM",nPerc)	
											EndIf
										EndIf
									
									EndIf
								
								Else
								
									lItemMc := .F.
								
								EndIf
								
							EndIf		
					
					Next nLinMc
				
			EndIf
			
		Next nLinRh
		
		For nLinLe := 1 To oMdlLE:Length()
			oMdlLE:GoLine( nLinLe )

			For nLinCob := 1 to oMdlCobLe:Length() //Cobrança de Locação
		
				oMdlCobLe:GoLine( nLinCob )
			
				If !oMdlCobLe:IsDeleted()
			
					If !Empty(oMdlCobLe:GetValue("TEV_MODCOB"))
				
						If cTp == "1" //1 = Taxa de Lucro
					
							If !lValid
								oMdlCobLe:SetValue("TEV_LUCRO",nPerc)
							Else
								//Nao substituir
								nPos := Ascan(aValid,{|x| x[2] == "TEV"+Alltrim(STR(nLinCob))+"1"})
								If nPos > 0
									oMdlCobLe:SetValue("TEV_LUCRO",aValid[nPos,1])
								Else
									oMdlCobLe:SetValue("TEV_LUCRO",nPerc)	
								EndIf
							EndIf	
					
						Else //2 = Taxa Administrativa
						
							If !lValid
								oMdlCobLe:SetValue("TEV_ADM",nPerc)
							Else
								//Nao substituir
								nPos := Ascan(aValid,{|x| x[2] == "TEV"+Alltrim(STR(nLinCob))+"2"})
								If nPos > 0
									oMdlCobLe:SetValue("TEV_ADM",aValid[nPos,1])
								Else
									oMdlCobLe:SetValue("TEV_ADM",nPerc)	
								EndIf
							EndIf	
						
						EndIf
					
					Else
					
						lItemLe := .F.
					
					EndIf
									
				EndIf	
			
			Next nLinCob
		Next nLinLe
		
	EndIf

Next nLinLocal

FwRestRows( aSaveRows )

nTLuc := oMdl:GetModel("TFJ_REFER"):GetValue("TFJ_LUCRO")
nTAdm := oMdl:GetModel("TFJ_REFER"):GetValue("TFJ_ADM")

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740VlAcr
	 Atualiza os valores de Lucro e da taxa administrativa para os demais itens 

@sample		At740VlAcr()

@since		24/02/2013
@version	P11.90


/*/
//------------------------------------------------------------------------------
Function At740VlAcr(cTp)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oMdl   	:= FwModelActive()
Local oMdlItm	:= oMdl:GetModel("TEV_ADICIO")
Local nVlAcr	:= 0

If cTp == "1"
	nVlAcr := (oMdlItm:GetValue("TEV_LUCRO")/100)*oMdlItm:GetValue("TEV_SUBTOT")
	If nVlAcr == 0
		oMdlItm:SetValue("TEV_TXLUCR", nVlAcr)	
	EndIf
Else
	nVlAcr := (oMdlItm:GetValue("TEV_ADM")/100)*oMdlItm:GetValue("TEV_SUBTOT")
	If nVlAcr == 0
		oMdlItm:SetValue("TEV_TXADM", nVlAcr)	
	EndIf
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return nVlAcr

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740LdLuc
	 Atualiza a Taxa de Lucro e administrativa para os demais itens 

@sample		At740LdLuc()

@since		21/02/2013
@version	P11.90


/*/
//------------------------------------------------------------------------------
Function At740VlTEV(cModel)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oMdl   		:= FwModelActive()
Local oMdlTEV		:= oMdl:GetModel(cModel)
Local nVlr			:= 0
Local nVlAcrLuc	:= 0
Local nVlAcrAdm	:= 0

nVlAcrLuc := (1+(oMdlTEV:GetValue("TEV_LUCRO")/100))*oMdlTEV:GetValue("TEV_SUBTOT")
nVlAcrAdm := (1+(oMdlTEV:GetValue("TEV_ADM")/100))*oMdlTEV:GetValue("TEV_SUBTOT")

nVlr := (nVlAcrLuc + nVlAcrAdm)-(oMdlTEV:GetValue("TEV_SUBTOT"))

FWRestRows( aSaveLines )
RestArea(aArea)
Return nVlr


//------------------------------------------------------------------------------
/*/{Protheus.doc} At740MatAc
	Gatilho dos valores de Lucro e da taxa administrativa para os itens de materiais 

@sample		At740MatAc()

@since		24/02/2013
@version	P11.90


/*/
//------------------------------------------------------------------------------
Function At740MatAc(cTp,cModel,cTab)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oMdl   	:= FwModelActive()
Local oMdlItm	:= oMdl:GetModel(cModel)
Local nSubTot	:= 0
Local nPerc	:= 0
Local nVlAcr	:= 0
Local nPercAux	:= 0

nSubTot	:= oMdlItm:GetValue(cTab+"_TOTAL")

If cTp == "1"
	nPerc := oMdlItm:GetValue(cTab+"_LUCRO")	
Else
	nPerc := oMdlItm:GetValue(cTab+"_ADM")
EndIf

nVlAcr := (nPerc/100)*nSubTot	

FWRestRows( aSaveLines )
RestArea(aArea)
Return nVlAcr

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740VlTot
	 Gatilho para preencher o campo total geral dos itens de materiais

@sample		At740VlTot()

@since		21/02/2013
@version	P11.90


/*/
//------------------------------------------------------------------------------
Function At740VlTot(cModel,cTab)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oMdl   	:= FwModelActive()
Local oMdlItm	:= oMdl:GetModel(cModel)
Local nVlr		:= 0
Local nVlrLuc := 0
Local nVlrAdm := 0

nVlrLuc := oMdlItm:GetValue(cTab+"_TOTAL")*(1+(oMdlItm:GetValue(cTab+"_LUCRO")/100))
nVlrAdm := oMdlItm:GetValue(cTab+"_TOTAL")*(1+(oMdlItm:GetValue(cTab+"_ADM")/100))

nVlr := (nVlrLuc + nVlrAdm)-(oMdlItm:GetValue(cTab+"_TOTAL"))

FWRestRows( aSaveLines )
RestArea(aArea)
Return nVlr

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740RhVlr
	 Gatilho para os itens de recursos humanos 

@sample		At740RhVlr()

@since		21/02/2013
@version	P11.90


/*/
//------------------------------------------------------------------------------
Function At740RhVlr(cTp)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oMdl   	:= FwModelActive()
Local oMdlItm	:= oMdl:GetModel("TFF_RH")
Local nQtde	:= oMdlItm:GetValue("TFF_QTDVEN")
Local nPrc		:= oMdlItm:GetValue("TFF_PRCVEN")
Local nVlAcr	:= 0
Local nPercAux:= 0
Local nVlrLucro	:= 0

If cTp == "1"
	nVlrLucro	:= oMdlItm:GetValue("TFF_LUCRO")/100
	nVlAcr 		:= nVlrLucro * (nQtde*nPrc)
	If nVlAcr == 0
		oMdlItm:SetValue("TFF_TXLUCR", nVlAcr)	
	EndIf
Else
	nVlAcr := (oMdlItm:GetValue("TFF_ADM")/100)*(nQtde*nPrc)
	If nVlAcr == 0
		oMdlItm:SetValue("TFF_TXADM", nVlAcr)	
	EndIf 
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return nVlAcr

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740Valid
	 Validação dos campos das Taxas de Lucro e administrativa nos itens 

@sample		At740Valid()

@since		21/02/2013
@version	P11.90


/*/
//------------------------------------------------------------------------------
Function At740Valid(cTp,nPerct)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oMdl   		:= FwModelActive()
Local oMdlLocal	:= oMdl:GetModel("TFL_LOC")
Local oMdlRH		:= oMdl:GetModel("TFF_RH")
Local oMdlMI		:= oMdl:GetModel("TFG_MI")
Local oMdlMC		:= oMdl:GetModel("TFH_MC")
Local oMdlLE		:= oMdl:GetModel("TEV_ADICIO")
Local nLinLocal	:= 0
Local nLRh			:= 0
Local nLMi			:= 0
Local nLMc			:= 0
Local nLLe			:= 0
Local aDados		:= {}

For nLinLocal := 1 To oMdlLocal:Length()

	oMdlLocal:GoLine( nLinLocal )
	
	If !oMdlLocal:IsDeleted()
	
		For nLRh := 1 to oMdlRH:Length() //Recursos humanos
				
			oMdlRH:GoLine( nLRh )
		
			If !oMdlRH:IsDeleted()
					
						If cTp == "1"
							If !Empty(oMdlRH:GetValue("TFF_LUCRO")) .AND. oMdlRH:GetValue("TFF_LUCRO") <> nPerct .AND. oMdlRH:GetValue("TFF_LUCRO") <> nTLuc
								aAdd(aDados,{oMdlRH:GetValue("TFF_LUCRO"),"TFF"+Alltrim(STR(nLRh))+cTp})	
							EndIf
						Else
							If !Empty(oMdlRH:GetValue("TFF_ADM")) .AND. oMdlRH:GetValue("TFF_ADM") <> nPerct .AND. oMdlRH:GetValue("TFF_ADM") <> nTAdm
								aAdd(aDados,{oMdlRH:GetValue("TFF_ADM"),"TFF"+Alltrim(STR(nLRh))+cTp})
							EndIf
						EndIf	
					
					For nLMi := 1 to oMdlMI:Length() //Materiais de Implantação
					
						oMdlMI:GoLine( nLMi )
						
							If !oMdlMI:IsDeleted()
							
								If cTp == "1"
									If !Empty(oMdlMI:GetValue("TFG_LUCRO")) .AND. oMdlMI:GetValue("TFG_LUCRO") <> nPerct .AND. oMdlMI:GetValue("TFG_LUCRO") <> nTLuc
										aAdd(aDados,{oMdlMI:GetValue("TFG_LUCRO"),"TFG"+Alltrim(STR(nLMi))+cTp})	
									EndIf						
								Else
									If !Empty(oMdlMI:GetValue("TFG_ADM")) .AND. oMdlMI:GetValue("TFG_ADM") <> nPerct .AND. oMdlMI:GetValue("TFG_ADM") <> nTAdm
										aAdd(aDados,{oMdlMI:GetValue("TFG_ADM"),"TFG"+Alltrim(STR(nLMi))+cTp})	
									EndIf
								EndIf
								
							EndIf		
					
					Next nLMi
					
					For nLMc := 1 to oMdlMC:Length() //Materiais de Consumo
				
						oMdlMC:GoLine( nLMc )
						
							If !oMdlMC:IsDeleted()
							
								If cTp == "1"
									If !Empty(oMdlMC:GetValue("TFH_LUCRO")) .AND. oMdlMC:GetValue("TFH_LUCRO") <> nPerct .AND. oMdlMC:GetValue("TFH_LUCRO") <> nTLuc
										aAdd(aDados,{oMdlMC:GetValue("TFH_LUCRO"),"TFH"+Alltrim(STR(nLMc))+cTp})	
									EndIf	
								Else
									If !Empty(oMdlMC:GetValue("TFH_ADM")) .AND. oMdlMC:GetValue("TFH_ADM") <> nPerct .AND. oMdlMC:GetValue("TFH_ADM") <> nTAdm
										aAdd(aDados,{oMdlMC:GetValue("TFH_ADM"),"TFH"+Alltrim(STR(nLMc))+cTp})	
									EndIf
								EndIf
								
							EndIf		
					
					Next nLMc
				
			EndIf
			
		Next nLRh
		
		
		For nLLe := 1 to oMdlLE:Length() //Cobrança de Locação
		
			oMdlLE:GoLine( nLLe )
			
			If !oMdlLE:IsDeleted()
			
				If cTp == "1"
					If !EMpty(oMdlLE:GetValue("TEV_LUCRO")) .AND. oMdlLE:GetValue("TEV_LUCRO") <> nPerct .AND. oMdlLE:GetValue("TEV_LUCRO") <> nTLuc
						aAdd(aDados,{oMdlLE:GetValue("TEV_LUCRO"),"TEV"+Alltrim(STR(nLLe))+cTp})	
					EndIf
				Else
					If !Empty(oMdlLE:GetValue("TEV_ADM")) .AND. oMdlLE:GetValue("TEV_ADM") <> nPerct .AND. oMdlLE:GetValue("TEV_ADM") <> nTAdm
						aAdd(aDados,{oMdlLE:GetValue("TEV_ADM"),"TEV"+Alltrim(STR(nLLe))+cTp})	
					EndIf
				EndIf
								
			EndIf	
		
		Next nLLe
	
	EndIf
	
Next nLinLocal

FWRestRows( aSaveLines )
RestArea(aArea)
Return aDados

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740Cortesia
	 Incluir cortesia no orçamento de serviços 

@sample	At740Cortesia()

@param 		oModel - Objeto, utilizado para o modelo de orçamento de serviços
@param		cRegra - String, regra da rotina a ser acessada

@since		10/04/2014
@version	P12

/*/
//------------------------------------------------------------------------------
Function At740Cortesia( oModl, cRegra )
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oModel	:= FwModelActive()
Local oModelOS	:= oModel:GetModel("TFJ_REFER")
Local oModelLC 	:= oModel:GetModel("TFL_LOC")
Local oModelRH 	:= oModel:GetModel("TFF_RH") 
Local oModelMI 	:= oModel:GetModel("TFG_MI")
Local oModelMC 	:= oModel:GetModel("TFH_MC")
Local lExtOrc	:= IsInCallStack("At870GerOrc") 
Local aRecHum	:= {}
Local aMatImp	:= {}
Local aMatCons	:= {}
Local nPosItem	:= 0
Local cNumItem	:= ""
Local cTitulo	:= ""
Local lConfirm	:= .T.
Local lContRH		:= .F.
Local lContMI		:= .F.
Local lContMC		:= .F.
Local lRet			:= .F.
Local nI			:= 0
Local nX			:= 0
Local cGsDsGcn		:= ""
Local cIsGsMt		:= oModelOS:GetValue("TFJ_ISGSMT")
Local lGesMat		:= oModelOS:GetValue('TFJ_GESMAT') $ "2|3"
Local lGsMtMi		:= oModelOS:GetValue('TFJ_GSMTMI') $ "2|3"
Local lGsMtMc		:= oModelOS:GetValue('TFJ_GSMTMC') $ "2|3"
Local lDesBloq		:= .F.

cOperation := oModel:GetOperation()

If oModel:GetOperation() == MODEL_OPERATION_INSERT
	cGsDsGcn	:= SuperGetMv("MV_GSDSGCN",,"2")
Else
	cGsDsGcn	:= TFJ->TFJ_DSGCN
EndIf

dbSelectArea("ABQ")
ABQ->(dbSetOrder(3))

If lExtOrc
	If cRegra == "033" .And. At680Perm(Nil, __cUserID, cRegra)
		lContRH := .T.
	ElseIf cRegra == "034" .And. At680Perm(Nil, __cUserID, cRegra)
		lContMI := .T.
	ElseIf cRegra == "035" .And. At680Perm(Nil, __cUserID, cRegra)
		lContMC := .T.
	Else
		lRet := .T.
	EndIf
Else
	If cRegra == "002" .And. At680Perm(Nil, __cUserID, cRegra)
		lContRH := .T.
	Elseif cRegra == "003" .And. At680Perm(Nil, __cUserID, cRegra) .And. !lGsMtMi
		lContMI := .T.
	ElseIf cRegra == "004" .And. At680Perm(Nil, __cUserID, cRegra) .And. !lGsMtMc
		lContMC := .T.
	Else
		lRet := .T.
	EndIf
EndIf
		
If	lContRH// Cortesia ou It. Extra RH
	
	// Atualiza os dados de local da cortesia
	At740ASetLoc( oModelLC, .T., oModelLC:GetValue("TFL_LOCAL") )
	At740ASetRec( oModel  , .T., oModelLC:GetValue("TFL_LOCAL") )		
	
	cTitulo := If( lExtOrc, STR0047, STR0048 ) // "Recursos Humanos Extra"#"Cortesia Recursos Humanos"
	
	lConfirm := ( FWExecView( cTitulo,"VIEWDEF.TECA740A", MODEL_OPERATION_INSERT, /*oDlg*/, {||.T.} /*bCloseOk*/, ;  //  "Cortesia Recursos Humanos" 
							{||.T.}/*bOk*/,30,/*aButtons*/, {||.T.}/*bCancel*/ ) == 0 )
										
	If lConfirm .AND. cOperation <> 1
		
		If lExtOrc
			oModelRH:SetNoInsertLine(.F.)
			oModelRH:SetNoDeleteLine(.F.)
			oModelRH:SetNoUpdateLine(.F.)
		EndIf
		aRecHum := At740AGet()
		
		// Remove os itens que foram não fazem mais parte da cortesia	
		For nI := 1 To oModelRH:Length()
			oModelRH:GoLine(nI)							
			If oModelRH:GetValue("TFF_COBCTR") == "1" .Or. Empty(oModelRH:GetValue("TFF_COBCTR"))
				Loop
			EndIf
			nPosItem := aScan( aRecHum, { |x| 	x[1] == oModelRH:GetValue("TFF_ITEM") .And. x[2] == oModelRH:GetValue("TFF_PRODUT")})
			If nPosItem == 0	
				If At740AVerABB( oModelRH:GetValue("TFF_COD") )
					If ABQ->( dbSeek( xFilial("ABQ") + oModelRH:GetValue("TFF_COD") ) )
						RecLock( "ABQ", .F. )
						ABQ->( dbDelete() )
						ABQ->( MsUnlock() )					
					EndIf
					oModelRH:DeleteLine()
				Else 
					Help(,,STR0035,, STR0062, 1, 0) //'Atenção'#"Não é possivel remover o item extra, pois existe agendamento para o atendente!"
				EndIf					
			EndIf				
		Next nI
			
		// Adiciona ou atualiza os itens de cortesia
		If Len(aRecHum) > 0
			For nI := 1 To Len(aRecHum)
				If !oModelRH:SeekLine({{"TFF_ITEM",aRecHum[nI][1]},	{"TFF_PRODUT",aRecHum[nI][2]},{"TFF_COBCTR", "2"}})
					If oModelRH:Length() > 1 .Or. ! Empty(oModelRH:GetValue("TFF_PRODUT"))
						oModelRH:Goline(oModelRH:Length())
						cNumItem := Soma1(oModelRH:GetValue("TFF_ITEM"))
						oModelRH:AddLine()							
						oModelRH:LoadValue( "TFF_ITEM", cNumItem  )							
						oModelRH:SetValue("TFF_CONTRT",oModelLC:GetValue("TFL_CONTRT"))
						oModelRH:SetValue("TFF_CONREV",oModelLC:GetValue("TFL_CONREV"))
					EndIf						
				EndIf
				
				//Verifica se o campo está bloqueado
				If !oModelRH:CanSetValue("TFF_PRODUT")
					oModel:GetModel("TFF_RH"):GetStruct():SetProperty("TFF_PRODUT", MODEL_FIELD_WHEN, {|| .T. })
					oModelRH:SetValue( "TFF_PRODUT", aRecHum[nI][2]  )
					
					//Bloqueia o campo Novamente
					oModel:GetModel("TFF_RH"):GetStruct():SetProperty("TFF_PRODUT", MODEL_FIELD_WHEN, {|| .F. })
				Else
					oModelRH:SetValue( "TFF_PRODUT", aRecHum[nI][2]  )
				EndIf
					
				oModelRH:SetValue( "TFF_DESCRI", aRecHum[nI][3]  )
				oModelRH:SetValue( "TFF_UM",     aRecHum[nI][4]  )
				oModelRH:SetValue( "TFF_QTDVEN", aRecHum[nI][5]  )
				oModelRH:SetValue( "TFF_PERINI", aRecHum[nI][6]  )
				oModelRH:SetValue( "TFF_PERFIM", aRecHum[nI][7]  )
				oModelRH:SetValue( "TFF_HORAIN", aRecHum[nI][8]  )
				oModelRH:SetValue( "TFF_HORAFI", aRecHum[nI][9]  )
				oModelRH:SetValue( "TFF_FUNCAO", aRecHum[nI][10] )
				oModelRH:SetValue( "TFF_DFUNC",  aRecHum[nI][11] )
				oModelRH:SetValue( "TFF_TURNO",  aRecHum[nI][12] )
				oModelRH:SetValue( "TFF_DTURNO", aRecHum[nI][13] )
				oModelRH:SetValue( "TFF_CARGO",  aRecHum[nI][14] )
				oModelRH:SetValue( "TFF_DCARGO", aRecHum[nI][15] )
				oModelRH:SetValue( "TFF_CALCMD", aRecHum[nI][16] )
				oModelRH:SetValue( "TFF_NARMA",  aRecHum[nI][17] )
				oModelRH:SetValue( "TFF_NCOLE",  aRecHum[nI][18] )
				oModelRH:SetValue( "TFF_COBCTR", "2" )
				oModelRH:SetValue( "TFF_ESCALA", aRecHum[nI][31] )
				oModelRH:SetValue( "TFF_CALEND", aRecHum[nI][32] )
				oModelRH:SetValue( "TFF_SEQTRN", aRecHum[nI][33] )
					
				If lExtOrc
					oModelRH:SetValue( "TFF_PRCVEN", aRecHum[nI][19] )
					oModelRH:SetValue( "TFF_DESCON", aRecHum[nI][20] )
					oModelRH:SetValue( "TFF_VALDES", aRecHum[nI][21] )
					oModelRH:SetValue( "TFF_PRCVEN", aRecHum[nI][22] )
					oModelRH:SetValue( "TFF_LUCRO",  aRecHum[nI][23] )
					oModelRH:SetValue( "TFF_TXLUCR", aRecHum[nI][24] )
					oModelRH:SetValue( "TFF_ADM",    aRecHum[nI][25] )
					oModelRH:SetValue( "TFF_TXADM",  aRecHum[nI][26] )
					oModelRH:SetValue( "TFF_SUBTOT", aRecHum[nI][27] )
					oModelRH:SetValue( "TFF_TOTMI",  aRecHum[nI][28] )
					oModelRH:SetValue( "TFF_TOTMC",  aRecHum[nI][29] )
					oModelRH:SetValue( "TFF_TOTAL",  aRecHum[nI][30] )
				Else
					oModelRH:SetValue( "TFF_PRCVEN", 0 )   // Determina valor Preço de Venda R$ 0 quando Cortesia de Recursos Humanos
				EndIf													

				If cGsDsGcn == "1"
					oModelRH:SetValue( "TFF_TESPED", aRecHum[nI][35] )
				Endif

				oModelRH:SetValue( "TFF_INSALU", aRecHum[nI][36] )
				oModelRH:SetValue( "TFF_GRAUIN", aRecHum[nI][37] )
				oModelRH:SetValue( "TFF_PERICU", aRecHum[nI][38] )
				If !Empty(aRecHum[nI][39])
					oModelRH:SetValue( "TFF_PDMTMI", aRecHum[nI][39] )
				Endif
				
				If !Empty(aRecHum[nI][40])				
					oModelRH:SetValue( "TFF_PRMTMI", aRecHum[nI][40] )
				Endif
				
				If aRecHum[nI][41] > 0
					oModelRH:SetValue( "TFF_VLMTMI", aRecHum[nI][41] )
				Endif

				If !Empty(aRecHum[nI][42])
					oModelRH:SetValue( "TFF_PDMTMC", aRecHum[nI][42] )
				Endif

				If !Empty(aRecHum[nI][43])
					oModelRH:SetValue( "TFF_PRMTMC", aRecHum[nI][43] )
				Endif

				If aRecHum[nI][44] > 0
					oModelRH:SetValue( "TFF_VLMTMC", aRecHum[nI][44] )
				Endif
				oModelRH:SetValue( "TFF_TIPORH", aRecHum[nI][47] )
				oModelRH:SetValue( "TFF_GRAVRH", aRecHum[nI][48] )
				
			Next nI						
		EndIf			
			
		If lExtOrc
			oModelRH:SetNoInsertLine(.T.)
			oModelRH:SetNoDeleteLine(.T.)
			oModelRH:SetNoUpdateLine(.T.)
		EndIf					
		oModelRH:GoLine(1)
	EndIf	
	
ElseIf lContMI // Cortesia ou It. Extra MI
			
	// Atualiza os dados de local da cortesia
	At740BSetLoc( oModelLC, oModelLC:GetValue("TFL_LOCAL") )
	At740BSetRec( oModel  , oModelLC:GetValue("TFL_LOCAL") )
	At740BSetMat( oModel, .T., oModelLC:GetValue("TFL_LOCAL")) 			
	
	cTitulo := If( lExtOrc, STR0049, STR0050 ) // "Material de Implantação Extra"#"Cortesia Material de Implantação"
	
	If FwFldGet("TFJ_GSMTMI") $ "23"
		Help(,,"MATEXT",,STR0171,1,0) //"Opção disponível apenas para configuração de material por quantidade."
		lConfirm := .F. 
	Else
		lConfirm := ( FWExecView( cTitulo,'VIEWDEF.TECA740B', MODEL_OPERATION_INSERT, /*oDlg*/, {||.T.} /*bCloseOk*/, ;  //  "Cortesia Material de Implantação" 
								{||.T.}/*bOk*/,30,/*aButtons*/, {||.T.}/*bCancel*/ ) == 0 )
	EndIf	
	
	If lConfirm .AND. cOperation <> 1
	
		If cIsGsMt == "1"
			lDesBloq := lGsMtMi
		Else
			lDesBloq := lGesMat
		Endif
	
		If lExtOrc .Or. lDesBloq
			oModelMI:SetNoInsertLine(.F.)
			oModelMI:SetNoDeleteLine(.F.)
			oModelMI:SetNoUpdateLine(.F.)
		EndIf
		aMatImp := At740BGet()			
		
		// Adiciona ou atualiza os itens de cortesia
		If Len(aMatImp) > 0

			// Remove os itens que foram não fazem mais parte da cortesia	
			For nI := 1 To Len(aMatImp)
				If oModelRH:SeekLine( { { "TFF_ITEM", aMatImp[nI][1] }, { "TFF_PRODUT", aMatImp[nI][2] } } )	
					For nX := 1 To oModelMI:Length()
						oModelMI:GoLine(nX)							
						If oModelMI:GetValue("TFG_COBCTR") == "1" .Or. Empty(oModelMI:GetValue("TFG_COBCTR")) 
							Loop
						EndIf
						
						nPosItem := aScan(aMatImp[nI][3], {|x| x[1] == oModelMI:GetValue("TFG_ITEM") .And. x[2] == oModelMI:GetValue("TFG_PRODUT")})
						
						If nPosItem == 0	
							oModelMI:DeleteLine()
						EndIf				
					Next nI
				EndIf
			Next nI	
		
			For nI := 1 To Len(aMatImp)
				If oModelRH:SeekLine( { { "TFF_ITEM", aMatImp[nI][1] }, { "TFF_PRODUT", aMatImp[nI][2] } } )		
					For nX := 1 To Len(aMatImp[nI][3])
						If Empty(aMatImp[nI][3][nX][2]) 
							Loop
						EndIf
						//Abaixo tratamento para na inserção da cortesia via Revisão, não substituir os valores de item extras existentes.
						If aMatImp[nI][3][nX][21] <> "1" .AND. !IsInCallStack("At870GerOrc") .AND. IsInCallStack("At740Cortesia") .AND. IsInCallStack("At870Revis") 
							Loop
						EndIf						
						If !oModelMI:SeekLine({{"TFG_ITEM", aMatImp[nI][3][nX][1] },{"TFG_PRODUT",aMatImp[nI][3][nX][2] }, {"TFG_TIPMAT",aMatImp[nI][3][nX][21] }})
							If oModelMI:Length() > 1 .Or. ! Empty(oModelMI:GetValue("TFG_PRODUT"))
								oModelMI:Goline(oModelMI:Length())
								cNumItem := Soma1(oModelMI:GetValue("TFG_ITEM"))
								oModelMI:AddLine()							
								oModelMI:LoadValue( "TFG_ITEM", cNumItem  )							
							EndIf					
						EndIf							
						
						//Verifica se o campo está bloqueado
						If !oModelMI:CanSetValue("TFG_PRODUT")
							oModel:GetModel("TFG_MI"):GetStruct():SetProperty("TFG_PRODUT", MODEL_FIELD_WHEN, {|| .T. })
							oModelMI:SetValue( "TFG_PRODUT"	, aMatImp[nI][3][nX][2] )
					
							//Bloqueia o campo Novamente
							oModel:GetModel("TFG_MI"):GetStruct():SetProperty("TFG_PRODUT", MODEL_FIELD_WHEN, {|| .F. })
						Else
							oModelMI:SetValue( "TFG_PRODUT"	, aMatImp[nI][3][nX][2] )
						EndIf	
						
						oModelMI:SetValue( "TFG_DESCRI"	, aMatImp[nI][3][nX][3] )
						oModelMI:SetValue( "TFG_UM"		, aMatImp[nI][3][nX][4] )
						oModelMI:SetValue( "TFG_QTDVEN"	, aMatImp[nI][3][nX][5] )
						oModelMI:SetValue( "TFG_PERINI"	, aMatImp[nI][3][nX][6] )
						oModelMI:SetValue( "TFG_PERFIM"	, aMatImp[nI][3][nX][7] )
						oModelMI:SetValue( "TFG_TES"	, aMatImp[nI][3][nX][8] )
						oModelMI:SetValue( "TFG_CODPAI"	, aMatImp[nI][3][nX][9] )
						oModelMI:SetValue( "TFG_GRVMAT"	, "2" )//Não gravado
						
						If aMatImp[nI][3][nX][21] <> "1" //Cortesia
							oModelMI:SetValue( "TFG_COBCTR"	, "1" )	//Cobrado
						Else
							oModelMI:SetValue( "TFG_COBCTR"	, "2" ) //Não cobrado
						EndIf
						
						oModelMI:SetValue( "TFG_TIPMAT", aMatImp[nI][3][nX][21] )
						oModelMI:SetValue( "TFG_GRVMAT", aMatImp[nI][3][nX][22] )
						
						If lExtOrc
							oModelMI:SetValue( "TFG_PRCVEN", aMatImp[nI][3][nX][10] )
							oModelMI:SetValue( "TFG_TOTAL", aMatImp[nI][3][nX][11] )
							oModelMI:SetValue( "TFG_VALDES", aMatImp[nI][3][nX][12] )
							oModelMI:SetValue( "TFG_DESCON", aMatImp[nI][3][nX][13] )
							oModelMI:SetValue( "TFG_TOTGER", aMatImp[nI][3][nX][14] )
							oModelMI:SetValue( "TFG_TXLUCR", aMatImp[nI][3][nX][15] )
							oModelMI:SetValue( "TFG_LUCRO", aMatImp[nI][3][nX][16] )
							oModelMI:SetValue( "TFG_ADM", aMatImp[nI][3][nX][17] )
							oModelMI:SetValue( "TFG_TXADM", aMatImp[nI][3][nX][18] )
							
							If Empty( oModelMI:GetValue( "TFG_COD" ) )
								oModelMI:SetValue( "TFG_COD", aMatImp[nI][3][nX][19] )
							EndIf
						Else
							oModelMI:SetValue( "TFG_PRCVEN", 0 )   // Determina valor Preço de Venda R$ 0 quando Cortesia de Material de Implantação
				    	EndIf													
						If cGsDsGcn == "1"
							oModelMI:SetValue( "TFG_TESPED", aMatImp[nI][3][nX][20] )
						Endif
					Next nX
				EndIf
			Next nI
		EndIf				
		
		If lExtOrc	.Or. lDesBloq
			oModelMI:SetNoInsertLine(.T.)
			oModelMI:SetNoDeleteLine(.T.)
			oModelMI:SetNoUpdateLine(.T.)
		EndIf			
		oModelRH:GoLine(1)
	EndIf 
	
ElseIf lContMC // Cortesia ou It. Extra MC

	// Atualiza os dados de local da cortesia
	At740CSetLoc( oModelLC, oModelLC:GetValue("TFL_LOCAL") )
	At740CSetRec( oModel  , oModelLC:GetValue("TFL_LOCAL") )
	At740CSetMat( oModel	 , oModelLC:GetValue("TFL_LOCAL") )		
	
	cTitulo := If( lExtOrc, STR0051, STR0052 ) // "Material de Consumo Extra"#"Cortesia Material de Consumo"
	
	If FwFldGet("TFJ_GSMTMC") $ "23"
		Help(,,"MATEXT",,STR0171,1,0) //"Opção disponível apenas para configuração de material por quantidade."
		lConfirm := .F. 
	Else
		lConfirm := ( FWExecView( cTitulo,'VIEWDEF.TECA740C', MODEL_OPERATION_INSERT, /*oDlg*/, {||.T.} /*bCloseOk*/, ;  //  "Cortesia Material de Consumo" 
							{||.T.}/*bOk*/,30,/*aButtons*/, {||.T.}/*bCancel*/ ) == 0 )
	EndIf
	
	If lConfirm .AND. cOperation <> 1

		If cIsGsMt == "1"
			lDesBloq := lGsMtMc
		Else
			lDesBloq := lGesMat
		Endif
	
		If lExtOrc .Or. lDesBloq
			oModelMC:SetNoInsertLine(.F.)
			oModelMC:SetNoDeleteLine(.F.)
			oModelMC:SetNoUpdateLine(.F.)
		EndIf		
	
		aMatCons := At740CGet()		
	
		If Len(aMatCons) > 0	

			// Remove os itens que foram não fazem mais parte da cortesia	
			For nI := 1 To Len(aMatCons)
				If oModelRH:SeekLine( { { "TFF_ITEM", aMatCons[nI][1] }, { "TFF_PRODUT", aMatCons[nI][2] } } )	
					For nX := 1 To oModelMC:Length()
						oModelMC:GoLine(nX)							
						If oModelMC:GetValue("TFH_COBCTR") == "1" .Or. Empty(oModelMC:GetValue("TFH_COBCTR"))
							Loop
						EndIf
						
						nPosItem := aScan( aMatCons[nI][3], {|x| x[1] == oModelMC:GetValue("TFH_ITEM") .And. x[2] == oModelMC:GetValue("TFH_PRODUT")})
						
						If nPosItem == 0	
							oModelMC:DeleteLine()
						EndIf			
					Next nI
				EndIf
			Next nI				
		
			For nI := 1 To Len(aMatCons)
				If oModelRH:SeekLine( { { "TFF_ITEM", aMatCons[nI][1] }, { "TFF_PRODUT", aMatCons[nI][2] } } )		
					For nX := 1 To Len(aMatCons[nI][3])
						If Empty(aMatCons[nI][3][nX][2]) 
							Loop
						EndIf
						//Abaixo tratamento para na inserção da cortesia via Revisão, não substituir os valores de item extras existentes.
						If aMatCons[nI][3][nX][21] <> "1" .AND. !IsInCallStack("At870GerOrc") .AND. IsInCallStack("At740Cortesia") .AND. IsInCallStack("At870Revis") 
							Loop
						EndIf	
													
						If !oModelMC:SeekLine({{"TFH_ITEM", aMatCons[nI][3][nX][1] },{ "TFH_PRODUT", aMatCons[nI][3][nX][2] }, { "TFH_TIPMAT", aMatCons[nI][3][nX][21] }})
							If oModelMC:Length() > 1 .Or. ! Empty(oModelMC:GetValue("TFH_PRODUT"))
								oModelMC:Goline(oModelMC:Length())
								cNumItem := Soma1(oModelMC:GetValue("TFH_ITEM"))
								oModelMC:AddLine()							
								oModelMC:LoadValue( "TFH_ITEM", cNumItem  )							
							EndIf					
						EndIf							
						
						//Verifica se o campo está bloqueado
						If !oModelMC:CanSetValue("TFH_PRODUT")
							oModel:GetModel("TFH_MC"):GetStruct():SetProperty("TFH_PRODUT", MODEL_FIELD_WHEN, {|| .T. })
							oModelMC:SetValue( "TFH_PRODUT"	, aMatCons[nI][3][nX][2] )
					
							//Bloqueia o campo Novamente
							oModel:GetModel("TFH_MC"):GetStruct():SetProperty("TFF_PRODUT", MODEL_FIELD_WHEN, {|| .F. })
						Else
							oModelMC:SetValue( "TFH_PRODUT"	, aMatCons[nI][3][nX][2] )
						EndIf
							
						oModelMC:SetValue( "TFH_DESCRI"	, aMatCons[nI][3][nX][3] )
						oModelMC:SetValue( "TFH_UM"		, aMatCons[nI][3][nX][4] )
						oModelMC:SetValue( "TFH_QTDVEN"	, aMatCons[nI][3][nX][5] )
						oModelMC:SetValue( "TFH_PERINI"	, aMatCons[nI][3][nX][6] )
						oModelMC:SetValue( "TFH_PERFIM"	, aMatCons[nI][3][nX][7] )
						oModelMC:SetValue( "TFH_TES"	, aMatCons[nI][3][nX][8] )
						oModelMC:SetValue( "TFH_CODPAI"	, aMatCons[nI][3][nX][9] )
						
						If aMatCons[nI][3][nX][21] <> "1"
							oModelMC:SetValue( "TFH_COBCTR"	, "1" ) //Cobrado
						Else
							oModelMC:SetValue( "TFH_COBCTR"	, "2" ) //Não cobrado
						EndIf
						
						oModelMC:SetValue( "TFH_TIPMAT"	, aMatCons[nI][3][nX][21] )
						oModelMC:SetValue( "TFH_GRVMAT"	, aMatCons[nI][3][nX][22] )
						
						If lExtOrc
							oModelMC:SetValue( "TFH_PRCVEN", aMatCons[nI][3][nX][10] )
							oModelMC:SetValue( "TFH_TOTAL", aMatCons[nI][3][nX][11] )
							oModelMC:SetValue( "TFH_VALDES", aMatCons[nI][3][nX][12] )
							oModelMC:SetValue( "TFH_DESCON", aMatCons[nI][3][nX][13] )
							oModelMC:SetValue( "TFH_TOTGER", aMatCons[nI][3][nX][14] )
							oModelMC:SetValue( "TFH_TXLUCR", aMatCons[nI][3][nX][15] )
							oModelMC:SetValue( "TFH_LUCRO", aMatCons[nI][3][nX][16] )
							oModelMC:SetValue( "TFH_ADM", aMatCons[nI][3][nX][17] )
							oModelMC:SetValue( "TFH_TXADM", aMatCons[nI][3][nX][18] )
							
							
							If Empty( oModelMC:GetValue( "TFH_COD" ) )
								oModelMC:SetValue( "TFH_COD", aMatCons[nI][3][nX][19] )
							EndIf
						Else
							oModelMC:SetValue( "TFH_PRCVEN", 0 )   // Determina valor Preço de Venda R$ 0 quando Cortesia de Material de Consumo
						EndIf														
						If cGsDsGcn == "1"
							oModelMC:SetValue( "TFH_TESPED", aMatCons[nI][3][nX][20] )
						Endif
					Next nX
				EndIf
			Next nI				
		EndIf	
		
		If lExtOrc .Or. lDesBloq
			oModelMC:SetNoInsertLine(.T.)
			oModelMC:SetNoDeleteLine(.T.)
			oModelMC:SetNoUpdateLine(.T.)
		EndIf			
		oModelRH:GoLine(1)			
	EndIf

EndIf

If lRet
	If !lGsMtMi .And. !lGsMtMc
		Help(,,"AT740CORTE",,STR0053,1,0) // "Usuario não possui acesso para essa rotina de cortesia ou It. Extra"
	ElseIf lGsMtMi .Or. lGsMtMc
		Help( "", 1, "AT740GesMat", , STR0143, 1, 0,,,,,,{STR0144}) //"Não é possivel incluir item de cortesia quando a gestão de material estiver por valor ou percentual"
	EndIf	
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return(Nil)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At740VlVlr
Função para validação dos valores para os recursos humanos
@sample 	At740VlVlr(oModel,cCpoSelec)
@since		15/04/2014      
@version	P12
@return 	lRet, Lógico, retorna .T. se data for válida.
@param  	cModelo, Caracter, nome do modelo de dados principal.
@param  	cCpoSelec, Caracter, nome do campo da data selecionada para validação.
/*/
//------------------------------------------------------------------------------
Function At740VlVlr(cModel,cCpoSelec,oModel)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oMdl   := Nil
Local nPrcVenda	:= 0
Local lCobrContr	:= .F.
Local lRet   := .T.
Local lPermLocZero 	:= At680Perm( , __cUserId, '032' )

Default oModel	:= FwModelActive()
  
If oModel != Nil
	If (oModel:GetId() == "TECA740" .Or. oModel:GetId() == "TECA740F")
		oMdl := oModel:GetModel(cModel)
	Else
		oMdl := oModel
	EndIf
	If oMdl != Nil

		nPrcVenda	:= oMdl:GetValue(cCpoSelec)

		If nPrcVenda < 0
			Help(,,"At740VlVlr",,STR0114,1,0) //"O valor do preço de venda não pode ser negativo."
			lRet := .F.
		Else
		If Left(cCpoSelec,3) == "TFF"
				lCobrContr := (oMdl:GetValue("TFF_COBCTR") <> "2")
		ElseIf Left(cCpoSelec,3) == "TFG" 
				lCobrContr := (oMdl:GetValue("TFG_COBCTR") <> "2")
		ElseIf Left(cCpoSelec,3) == "TFH"
				lCobrContr := (oMdl:GetValue("TFH_COBCTR") <> "2")
		EndIf
		
			If	nPrcVenda == 0 .And. lCobrContr .And. !IsInCallStack("LoadXmlData") .And.;
				!IsInCallStack("ATCPYDATA") .And. !IsInCallStack("At740Cortesia") .And.; 
				!IsInCallStack("A600GrvOrc") .And. !IsInCallStack("At870GerOrc") .And.;
				!IsInCallStack("At740FTrgG") .And. !lPermLocZero
				Help(,,"At740VlVlr",,STR0054,1,0) // "O valor do preço de venda deve ser maior do que zeros."
				lRet	:= .F.
			ElseIf  IsInCallStack("At740Cortesia") .AND. Left(cCpoSelec,3) == "TFG"
				If oMdl:GetValue("TFG_TIPMAT") == "2" .AND. nPrcVenda <= 0
					Help(,,"At740VlVlr",,STR0054,1,0) // "O valor do preço de venda deve ser maior do que zeros."
					lRet	:= .F.
				ElseIf oMdl:GetValue("TFG_TIPMAT") == "1" .AND. nPrcVenda > 0
					Help(,,"At740VlVlr",,"Não é permitido informar valor para item de cortesia.",1,0)
					lRet	:= .F.
				EndIf
			ElseIf IsInCallStack("At740Cortesia") .AND. IsInCallStack("At870Revis") .AND.;
				   Left(cCpoSelec,3) == "TFF" .AND. nPrcVenda = 0  .AND. oMdl:GetValue("TFF_TIPORH") == "2"
					lRet := .F.				
			ElseIf IsInCallStack("At740Cortesia") .AND. !IsInCallStack("At870Revis") .AND. Left(cCpoSelec,3) == "TFF"
				If oMdl:GetValue("TFF_TIPORH") == "2" .AND. nPrcVenda <= 0
					Help(,,"At740VlVlr",,STR0054,1,0) // "O valor do preço de venda deve ser maior do que zeros."
					lRet	:= .F.
				EndIf
			EndIf	
		EndIf
		
	EndIf
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740VldTFF
	
Valida se existe o recurso ja criado na configuração de alocação do atendente

@sample 	At740VldTFF(cContrato,cCodTFF,cFilTFF)

@since		24/04/2014      
@version	P12

@return 	lRet, Lógico, retorna .T. se data for válida.

@param  	cContrato, Caracter, Numero do contrato para a consistencia.
@param  	cCodTFF, Caracter, codigo do recurso para a consistencia.
@param  	cFilTFF, Caracter, filial do recurso para a consistencia.

/*/
//------------------------------------------------------------------------------
Function At740VldTFF( cContrato, cCodTFF, cFilTFF, lSrvExt, cCodOrc )
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local lRet  := .T.

Default cFilTFF := xFilial("TFF", cFilAnt)

dbSelectArea("ABQ")

If lSrvExt
	ABQ->(dbSetOrder(4))	
	If ABQ->(dbSeek(xFilial("ABQ")+cCodOrc))
			
		While ABQ->(!Eof()) .And. ABQ->ABQ_FILIAL == xFilial("ABQ") .And. ;
			  	ABQ->ABQ_CODTFJ == cCodOrc .And. ABQ->ABQ_ORIGEM = "TFJ"
		
			If (ABQ->ABQ_CODTFF == cCodTFF) .AND. (ABQ->ABQ_FILTFF == cFilTFF)
				lRet := .F.
				Exit
			EndIf
		
			ABQ->(dbSkip())
		EndDo
	Endif
Else
	ABQ->(dbSetOrder(2))
	If ABQ->(dbSeek(xFilial("ABQ")+cContrato+"CN9"))
			
		While ABQ->(!Eof()) .And. ABQ->ABQ_FILIAL == xFilial("ABQ") .And. ;
			  	ABQ->ABQ_CONTRT == cContrato .And. ABQ->ABQ_ORIGEM == "CN9"
		
			If (ABQ->ABQ_CODTFF == cCodTFF) .AND. (ABQ->ABQ_FILTFF == cFilTFF)
				lRet := .F.
				Exit
			EndIf
		
			ABQ->(dbSkip())
		EndDo
	EndIf	
Endif


FWRestRows( aSaveLines )
RestArea(aArea)
Return(lRet) 	


//------------------------------------------------------------------------------
/*/{Protheus.doc} AT740F4()
Rotina consulta estoque através do último produto SB1 que está posicionado


@author arthur.colado
@since 07/04/2014
@version 1.0
/*/
//------------------------------------------------------------------------------
Function AT740F4()
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local cFilBkp := cFilAnt
Local cReadVar := ReadVar()
Local cConsulta := ""
Local oMdl := FwModelActive()

Set Key VK_F4 TO

If FWModeAccess("SB1")=="E"
	cFilAnt := SB1->B1_FILIAL
EndIf	

If cReadVar == "M->TFG_QTDVEN"
	cConsulta := oMdl:getModel("TFG_MI"):GetValue("TFG_PRODUT")
EndIf

If cReadVar == "M->TFH_QTDVEN"
	cConsulta := oMdl:getModel("TFH_MC"):GetValue("TFH_PRODUT")
EndIf

If !Empty(cConsulta)
	MaViewSB2(cConsulta)
EndIf

cFilAnt := cFilBkp
Set Key VK_F4 TO AT740F4()

FWRestRows( aSaveLines )
RestArea(aArea)
Return Nil

/*/{Protheus.doc} At740Refre
Reposiciona grid do local de atendimento
@since 20/08/2014
@version 11.9
@param oView, objeto, View Orçamento de Serviços

/*/
Function At740Refre(oView)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local aIdsModels := oView:GetModelsIds()
Local aFolder	:= {}

If oView:GetOperation() <> MODEL_OPERATION_VIEW
	
	oView:GoLine('TFL_LOC',1) 	//VIEW_LOC
	If aScan( aIdsModels, {|x| x=='TFF_RH' } ) > 0
		oView:GoLine('TFF_RH',1) 	//VIEW_RH
	EndIf
	If aScan( aIdsModels, {|x| x=='TFI_LE' } ) > 0
		oView:GoLine('TFI_LE',1) 	//VIEW_LE
	EndIf
EndIf

//Controle dos totais do recorrente
If oView:GetModel():GetId() == "TECA740F"
	aFolder := oView:GetFolderActive("ABAS", 2)

	If oView:GetOperation() == MODEL_OPERATION_INSERT
		oView:HideFolder("ABAS", STR0138,2) // "Resumo Geral Recorrente"
	Else
		If TFJ->TFJ_CNTREC == '1'
			oView:HideFolder("ABAS", STR0139,2) // "Resumo Geral
		Else
			oView:HideFolder("ABAS", STR0138,2) // "Resumo Geral Recorrente"
		EndIf
	EndIf

	oView:SelectFolder("ABAS", aFolder[2],2) // "Locais de Atendimento"

Endif
FWRestRows( aSaveLines )
RestArea(aArea)
Return

/*/{Protheus.doc} At740VlSeq
Valida a Sequencia do Turno
@since 20/08/2014
@version 11.9
@param oModel, objeto, MOdel do Orçamento de Serviços
@return lRet, Sequencia do turno existente

/*/
Function At740VlSeq(oModel)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local lRet	:= .T.
Local cFil := ""
Local cSeq := ""
Local cTno := ""
Local oTFF := Nil
Local aAreaSPJ := SPJ->(GetArea())

Default oModel := FwModelActive()

oTFF := oModel:GetModel("TFF_RH")

If oTFF == Nil .And. IsInCallStack("At740Cortesia")
	oTFF := oModel:GetModel("TFF_GRID") 
EndIf

If oTFF <> Nil

	cTno := oTFF:GetValue("TFF_TURNO")
	cSeq := oTFF:GetValue("TFF_SEQTRN")
	
	If !Empty(cSeq)
		cFil	:= xFilial( "SPJ" , xFilial("SRA") )
		lRet := SPJ->( MsSeek( cFil + cTno + cSeq , .F. ) )
			
		If !( lRet )
			Help( ' ' , 1 , 'SEQTURNINV' , , OemToAnsi( STR0055 ) , 1 , 0 ) //Sequencia Nao Cadastrada Para o Turno
		EndIf
	EndIf
EndIf

RestArea(aAreaSPJ)
FWRestRows( aSaveLines )
RestArea(aArea)
Return( lRet )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740VerVB
	
Função para validar se existe um vinculo de beneficio que ainda esta ativo, isto é,
com a data final não preenchida - LY_DTFIM para o item do RH.

@sample 	At740VerVB(cCodTFF)

@since		24/06/2015      
@version	P12

@return 	lRet, Lógico

@param  	cCodTFF, Caracter, codigo do item do RH

/*/
//------------------------------------------------------------------------------
Function At740VerVB(cCodTFF)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local lRet			:= .T.
Local cAliasSLY	:= GetNextAlias()

IF !Empty(cCodTFF)
	// Filtra os Beneficios
	BeginSql Alias cAliasSLY
		COLUMN LY_DTFIM AS DATE
		SELECT	LY_DTFIM
		FROM %table:SLY% SLY 
		WHERE 
			SLY.LY_FILIAL = %xFilial:SLY% AND 
			SUBSTRING(SLY.LY_CHVENT,1,6) = %Exp:cCodTFF% AND
			SLY.LY_DTFIM = ' ' AND
			SLY.%NotDel%
 	EndSql

	DO WHILE !(cAliasSLY)->(Eof())
		lRet := .F.
		EXIT
		(cAliasSLY)->(DbSkip())
	END

	DbSelectArea(cAliasSLY)
	(cAliasSLY)->(DbCloseArea())
ENDIF

FWRestRows( aSaveLines )
RestArea(aArea)
RETURN lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} F740LockGrd

Verifica se as Grids filhas poderão ser alteradas ou não de acordo com a escolha do campo
TFJ_GESMAT no cabeçalho
 
@author Serviços
@since 22/06/2015
@version P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function F740LockGrd(oMdlGer)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local lRet := .T.
Local cIsGsMt 		:= FwFldGet("TFJ_ISGSMT") // M->TFJ_ISGSMT
Local cGesMat 		:= FwFldGet("TFJ_GESMAT") // M->TFJ_GESMAT
Local cGsMtMi 		:= FwFldGet("TFJ_GSMTMI") // M->TFJ_GSMTMI
Local cGsMtMc 		:= FwFldGet("TFJ_GSMTMC") // M->TFJ_GSMTMC
Local lExtOrc		:= IsInCallStack("At870GerOrc")
Default oMdlGer	:= FWModelActive() //Recuperando o model ativo da interface 

If cIsGsMt == "1"
	If cGsMtMi == '2' .Or. cGsMtMi == '3' .Or. lExtOrc	 
		oMdlGer:GetModel('TFG_MI'):SetNoInsertLine(.T.)
		oMdlGer:GetModel('TFG_MI'):SetNoUpdateLine(.T.)
		oMdlGer:GetModel('TFG_MI'):SetNoDeleteLine(.T.)
	Else
		oMdlGer:GetModel('TFG_MI'):SetNoInsertLine(.F.)
		oMdlGer:GetModel('TFG_MI'):SetNoUpdateLine(.F.)
		oMdlGer:GetModel('TFG_MI'):SetNoDeleteLine(.F.)	
	Endif

	If cGsMtMc == '2' .Or. cGsMtMc == '3' .Or. lExtOrc	
		oMdlGer:GetModel('TFH_MC'):SetNoInsertLine(.T.)
		oMdlGer:GetModel('TFH_MC'):SetNoUpdateLine(.T.)
		oMdlGer:GetModel('TFH_MC'):SetNoDeleteLine(.T.)
	Else
		oMdlGer:GetModel('TFH_MC'):SetNoInsertLine(.F.)
		oMdlGer:GetModel('TFH_MC'):SetNoUpdateLine(.F.)
		oMdlGer:GetModel('TFH_MC'):SetNoDeleteLine(.F.)
	Endif
Else
	//Quando o campo gestão de materiais for Material por valor ou percentual do recurso
	//eu não permito manutenções nas Grids de Material de Implantação e Material de Consumo 	
	If cGesMat == '2' .Or. cGesMat == '3' .Or. lExtOrc
		oMdlGer:GetModel('TFG_MI'):SetNoInsertLine(.T.)
		oMdlGer:GetModel('TFG_MI'):SetNoUpdateLine(.T.)
		oMdlGer:GetModel('TFG_MI'):SetNoDeleteLine(.T.)
			
		oMdlGer:GetModel('TFH_MC'):SetNoInsertLine(.T.)
		oMdlGer:GetModel('TFH_MC'):SetNoUpdateLine(.T.)
		oMdlGer:GetModel('TFH_MC'):SetNoDeleteLine(.T.)
	Else
		oMdlGer:GetModel('TFG_MI'):SetNoInsertLine(.F.)
		oMdlGer:GetModel('TFG_MI'):SetNoUpdateLine(.F.)
		oMdlGer:GetModel('TFG_MI'):SetNoDeleteLine(.F.)
			
		oMdlGer:GetModel('TFH_MC'):SetNoInsertLine(.F.)
		oMdlGer:GetModel('TFH_MC'):SetNoUpdateLine(.F.)
		oMdlGer:GetModel('TFH_MC'):SetNoDeleteLine(.F.)
			
	Endif
Endif

FWRestRows( aSaveLines )
RestArea(aArea)
Return ( lRet )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} F740VldCmp

Verifica se o campo pode ser alterado de acordo com o tipo de gestão de material selecionado
 
@author Serviços
@since 22/06/2015
@version P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At740VlMat()
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local lRet    := .T. 
Local cCmp    := Readvar()
Local oModel	:= FWModelActive() //Recuperando o model ativo da interface
Local oMdlVld	:= oModel:GetModel("TFF_RH")
Local cGesMat 		:= ""
Local cGsMtMi		:= ""
Local cGsMtMc		:= ""

Local nVlrAnt := 0 
Local nVlrAtu := 0 

If !IsInCallStack("At740Cortesia") //Se passar pelo item extra, não é necessário pois é validado pelo WHEN.
	//Tratamento pois o gatilho executa a validação quando outros campos são alimentados
	If 'TFF_VLRMAT' $ cCmp
		cGesMat := oModel:GetModel('TFJ_REFER'):GetValue('TFJ_GESMAT')
		nVlrAnt := ( ( oMdlVld:GetValue('TFF_QTDVEN') * oMdlVld:GetValue('TFF_PRCVEN') ) * (oMdlVld:GetValue('TFF_PERMAT')/100 ) )               
		nVlrAtu := oMdlVld:GetValue('TFF_VLRMAT')
		
		If ( Empty( cGesMat ) .Or. cGesMat == '1' .Or. cGesMat == '3' ) 
			If  nVlrAnt <> nVlrAtu
				Help(,,'At740VlMat',,STR0069,1, 0 ) //"Este campo somente pode ser editado quando a Gestão de Materiais for igual a 'Material Por Valor'"
				lRet := .F.
			EndIf
		EndIf
	ElseIf 'TFF_VLMTMI' $ cCmp
		cGsMtMi	:= oModel:GetModel('TFJ_REFER'):GetValue('TFJ_GSMTMI')
		nVlrAnt := oMdlVld:GetValue('TFF_SUBTOT') * (oMdlVld:GetValue('TFF_PRMTMI')/100 )                
		nVlrAtu := oMdlVld:GetValue('TFF_VLMTMI')
		
		If ( Empty( cGsMtMi ) .Or. cGsMtMi == '1' .Or. cGsMtMi == '3' ) 
			If  nVlrAnt <> nVlrAtu
				Help(,,'At740VlMat',,STR0172,1, 0 ) //"Este campo somente pode ser editado quando a Gestão de Materiais de Implantação for igual a 'Material Por Valor'"
				lRet := .F.
			EndIf
		EndIf
		If lRet
			oMdlVld:SetValue("TFF_TOTMI",nVlrAtu)
		Endif
	Elseif 'TFF_VLMTMC' $ cCmp

			cGsMtMc	:= oModel:GetModel('TFJ_REFER'):GetValue('TFJ_GSMTMC')
		
		nVlrAnt := oMdlVld:GetValue('TFF_SUBTOT') * (oMdlVld:GetValue('TFF_PRMTMC')/100 )               
		nVlrAtu := oMdlVld:GetValue('TFF_VLMTMC')
		
		If ( Empty( cGsMtMc ) .Or. cGsMtMc == '1' .Or. cGsMtMc == '3' )
			If  nVlrAnt <> nVlrAtu
				Help(,,'At740VlMat',,STR0173,1, 0 ) //"Este campo somente pode ser editado quando a Gestão de Materiais de Consumo for igual a 'Material Por Valor'"
				lRet := .F.
			EndIf
		EndIf
		If lRet
			oMdlVld:SetValue("TFF_TOTMC",nVlrAtu)
		Endif
	EndIf
EndIf //If IsInCallStack("At740Cortesia") 
FWRestRows( aSaveLines )
RestArea(aArea)
Return ( lRet )

/*/
At740TDS
	

@sample 	At740TDS()

@since		20/07/2015       
@version	P12

/*/
//------------------------------------------------------------------------------
Function At740TDS()
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local cCodTCZ  := ""
Local cDescTCZ := ""
Local oMdl   	 := FwModelActive()

If oMdl:GetId()=="TECA740" .Or. oMdl:GetId()=="TECA740F" 

	cCodTCZ := oMdl:GetModel( "TDS_RH" ):GetValue( "TDS_CODTCZ" )
	cDescTCZ:= Posicione("TCZ",1,xFilial("TCZ") + cCodTCZ ,"TCZ->TCZ_DESC")
	
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return(cDescTCZ)

/*/
At740VlGMat
@sample 	At740VlGMat()
@since		20/07/2015       
@version	P12
/*/
//------------------------------------------------------------------------------
Function At740VlGMat(cCmpGsMt,cCmpVlr,cCmpPer,cCmpPdMt)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oModel := FwModelActive()
Local oView := FwViewActive() 
Local nI := 0
Local nJ := 0
Local nZ := 0	
Local oMdlTFL :=	oModel:GetModel("TFL_LOC")
Local oMdlTFF :=	oModel:GetModel("TFF_RH")
Local oMdlTFJ := oModel:GetModel("TFJ_REFER")
Local oMdlTFG := oModel:GetModel("TFG_MI")
Local oMdlTFH := oModel:GetModel("TFH_MC")
Local nOldTFL := oMdlTFL:GetLine()
Local nOldTFF := oMdlTFF:GetLine()
Local lRet := .T.
Local lZera := .F.
Default cCmpPdMt 	:= ""
	
//Verifica se há valores de materiais	
For nI:=1 To oMdlTFL:Length()
	oMdlTFL:GoLine(nI)
	For nJ:=1 To oMdlTFF:Length()
		oMdlTFF:GoLine(nJ)
		If oMdlTFF:GetValue(cCmpVlr) != 0 .OR. oMdlTFF:GetValue(cCmpPer) != 0
			lZera := .T.
			Exit
		EndIf							
	Next nJ
	If lZera 
		Exit
	EndIf	
Next nI
	
//Interação com usuário para zerar valores
If lZera
	lRet := MsgYesNo(STR0174)//"Os valores referente materias serão zerados. Deseja Continuar?"
EndIf	
	
//Zera Valores de materiais
If lRet .AND. lZera
	For nI:=1 To oMdlTFL:Length()
		oMdlTFL:GoLine(nI)
		For nJ:=1 To oMdlTFF:Length()
			oMdlTFF:GoLine(nJ)
			oMdlTFF:LoadValue(cCmpVlr, 0)
			oMdlTFF:LoadValue(cCmpPer, 0)								
			If !Empty(cCmpPdMt)
				oMdlTFF:LoadValue(cCmpPdMt, "")
			Endif
		Next nJ
	Next nI
		
	oMdlTFL:GoLine(nOldTFL)
	oMdlTFF:GoLine(nOldTFF)			
	If oView:IsActive()
		oView:Refresh("VIEW_RH")//Atualiza grid para que seja apresentado os valores alterados	
	Endif
EndIf 

If !lRet
	oMdlTFJ:LoadValue(cCmpGsMt, "2")
Endif

//Deleta as linhas de material de implantação ao trocar o tipo de gestão
//Percorre as linhas do local para posicionar na TFF e apagar todos os itens
If cCmpGsMt == "TFJ_GSMTMI" .AND. oMdlTFJ:GetValue(cCmpGsMt) $ "23"
	For nZ:=1 To oMdlTFL:Length()
		oMdlTFL:GoLine(nZ)
		For nI:=1 To oMdlTFF:Length()
			oMdlTFF:GoLine(nI)
			For nJ:=1 To oMdlTFG:Length()
				oMdlTFG:GoLine(nJ)
				If !oMdlTFG:IsEmpty() .And. !oMdlTFG:IsDeleted() 
					oMdlTFG:DeleteLine()
				EndIf						
			Next nJ
		Next nI	
	Next nZ	
	oMdlTFL:GoLine(nOldTFL)
	oMdlTFF:GoLine(nOldTFF)	
	If oView:IsActive()
		oView:Refresh("VIEW_MI")//Atualiza grid para que seja apresentado os valores alterados	
	Endif
EndIf

//Deleta as linhas de material de consumo ao trocar o tipo de gestão
If cCmpGsMt == "TFJ_GSMTMC" .AND. oMdlTFJ:GetValue(cCmpGsMt) $ "23"
	For nZ:=1 To oMdlTFL:Length()
		oMdlTFL:GoLine(nZ)
		For nI:=1 To oMdlTFF:Length()
			oMdlTFF:GoLine(nI)	
			For nJ:=1 To oMdlTFH:Length()
				oMdlTFH:GoLine(nJ)
				If !oMdlTFH:IsEmpty() .And. !oMdlTFH:IsDeleted() 
					oMdlTFH:DeleteLine()
				EndIf						
			Next nJ
		Next nI
	Next nZ	
	oMdlTFL:GoLine(nOldTFL)
	oMdlTFF:GoLine(nOldTFF)		
	If oView:IsActive()
		oView:Refresh("VIEW_MC")//Atualiza grid para que seja apresentado os valores alterados	
	Endif
EndIf

If oView:IsActive()
	oView:Refresh("VIEW_REFER")
Endif

FWRestRows( aSaveLines )
RestArea(aArea)
Return lRet

//------------------------------------------------------------------------------
/*/
At740TDT
@sample 	At740TDT()
@since		20/07/2015       
@version	P12
/*/
//------------------------------------------------------------------------------
Function At740TDT(cSeq)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local cCodRBG  := ""
Local cCodEsc  := ""
Local cItEsc   := ""
Local cDesc    := ""
Local oMdl   	 := FwModelActive()

If oMdl:GetId()=="TECA740" .Or. oMdl:GetId()=="TECA740F" 
	
	Do Case 
	
	Case cSeq == '1'
		//codigo da habilidade
		cCodRBG := oMdl:GetModel( "TDT_RH" ):GetValue( "TDT_CODHAB" )
		cDesc   := Posicione("RBG",1,xFilial("RBG") + cCodRBG ,"RBG->RBG_DESC")
	Case cSeq == '2'	
		//codigo escala
		cCodEsc := oMdl:GetModel( "TDT_RH" ):GetValue( "TDT_ESCALA" )
		cDesc   := Posicione("RBK",1,xFilial("RBK") + cCodEsc ,"RBK->RBK_DESCRI")
	Case cSeq == '3'	
		//codigo item escala
		cCodEsc := oMdl:GetModel( "TDT_RH" ):GetValue( "TDT_ESCALA" )
		cItEsc  := oMdl:GetModel( "TDT_RH" ):GetValue( "TDT_ITESCA" )
		cDesc   := Posicione("RBL",1,xFilial("RBL") + cCodEsc + cItEsc ,"RBL->RBL_DESCRI")
	Case cSeq == '4'	
		//codigo da habilidade X5
		cCodX5  := oMdl:GetModel( "TDT_RH" ):GetValue( "TDT_HABX5" )
		cDesc   := Posicione("SX5",1,xFilial("SX5")+"A4"+cCodX5,"X5_DESCRI")
	ENDCASE	
	
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return(cDesc)

//------------------------------------------------------------------------------
/*/
At740TGV
	

@sample 	At740TGV()

@since		20/07/2015       
@version	P12

/*/
//------------------------------------------------------------------------------
Function At740TGV()
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local cCodTGV  := ""
Local cDesc    := ""
Local oMdl   	 := FwModelActive()

If oMdl:GetId()=="TECA740" .Or. oMdl:GetId()=="TECA740F" 
	
		//codigo da curso
		cCodTGV := oMdl:GetModel( "TGV_RH" ):GetValue( "TGV_CURSO" )
		cDesc   := Posicione("RA1",1,xFilial("RA1") + cCodTGV ,"RA1->RA1_DESC")

EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return(cDesc)

/*/{Protheus.doc} At740LuTxA
	Copia o conteúdo preenchido nos campos de percentual de lucro e taxa administrativa
@return 	nValor, Numérico, percentual da tx adm ou do lucro
@param  	cCpoValor, Caracter, campo para ter o conteúdo copiado
/*/
Function At740LuTxA( cCpoValor )
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local nValor := 0
Local oMdlFull := FwModelActive()

If oMdlFull <> Nil .And. ( oMdlFull:GetId()=='TECA740' .Or. oMdlFull:GetId()=='TECA740F' )
	nValor := oMdlFull:GetValue('TFJ_REFER', cCpoValor)
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return nValor

//-------------------------------------------------------------------
/*/{Protheus.doc} At740ConEq
Rotina para consulta de equipamentos

@author filipe.goncalves
@since 27/01/2016
@version P12.1.11
/*/
//-------------------------------------------------------------------
Function At740ConEq()
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oModel	:= FwModelActive()
Local oModConsu := FWLoadModel('TECA742')
Local dDtIni	:= oModel:GetValue('TFI_LE','TFI_PERINI')
Local dDtFim	:= oModel:GetValue('TFI_LE','TFI_PERFIM')
Local aButtons := {{.F.,Nil},{.F.,Nil},{.F.,Nil},{.T.,Nil},{.T.,Nil},{.T.,Nil},{.F.,Nil},{.T.,"Cancelar"},{.T.,Nil},{.T.,Nil},{.T.,Nil},{.T.,Nil},{.T.,Nil},{.T.,Nil}}
		
If !(Empty(dDtIni)) .And. !(Empty(dDtFim))
	oModConsu:SetOperation(3)
	oModConsu:Activate()
	FWExecView (STR0087, "TECA742"	,MODEL_OPERATION_INSERT,, {||.T.},,,aButtons,{||.T.},,, AT742LOAD(oModel, oModConsu))
Else
	Help(,,"AT740CON",,STR0088,1,0) //"Digite as datas de periodo do produto para utilizar a consulta de equipamentos" 
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} At740ValAM
Função para validar o tipo escolhido da apuração de medição

@author filipe.goncalves
@since 27/01/2016
@version P12.1.11
/*/
//-------------------------------------------------------------------
Function At740ValAM()
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oModel	:= FwModelActive()
Local lRet		:= .T.
Local lIniFim 	:= Empty(oModel:GetValue('TFI_LE','TFI_PERINI')) .And. Empty(oModel:GetValue('TFI_LE','TFI_PERFIM'))
Local lEntCo	:= Empty(oModel:GetValue('TFI_LE','TFI_ENTEQP')) .And. Empty(oModel:GetValue('TFI_LE','TFI_COLEQP'))
	
If !lIniFim .And. lEntCo
	If oModel:GetValue('TFI_LE','TFI_APUMED') <> "1"
		lRet := .F. 
		Help(,,"AT740OPC1",,STR0102,1,0)	//"Quando somente os períodos inicial e final estão preenchidos, é possivel selecionar apenas a opção '1' deste campo."
	Endif
Endif

FWRestRows( aSaveLines )
RestArea(aArea)
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At740VldAg
Validação para as dadtas de agendamento de entrega e coleta do equipamento.

@author Kaique Schiller
@since 13/05/2016
@version P12
/*/
//-------------------------------------------------------------------
Function At740VldAg(cCampo,dDtIni,dDtFim,dDtEnt,dDtCol)

Local aArea		:= GetArea() 
Local aSaveLines:= FWSaveRows()
Local lRet 		:= .F.
Local cVldAgd 	:= SuperGetMv("MV_VLDAGD",,"1")
Local lCont		:= .T.

Default cCampo	:= ""
Default dDtIni	:= sTod("")
Default dDtFim	:= sTod("")
Default dDtEnt	:= sTod("")
Default dDtCol	:= sTod("")

If !Empty(dDtCol) .and. !Empty(dDtEnt)  
	lCont := dDtCol >= dDtEnt 
	If !lCont
		Help(,, "At740VldAg",,STR0108,1,0,,,,,,{STR0109})//#"Data Entrega/Coleta." #"Data Coleta deve ser maior que a data de entrega"
	EndIf
EndIf

If lCont .and. !Empty(dDtIni) .and. !Empty(dDtFim)
	lCont := dDtFim >= dDtIni 
	If !lCont
		Help(,, "At740VldAg",,STR0110,1,0,,,,,,{STR0111})//#"Data Inicio/Fim."#"Data Fim deve ser maior que a Data Inicial"
	EndIf
EndIf

If lCont
	//Quando a data de entrega e coleta estiver igual ou fora do período.
	If cVldAgd == "1"
		If cCampo == "TFI_ENTEQP"
			If dDtEnt <= dDtIni
				lRet := .T.
			Else 
				Help(,, "At740VldAg",,STR0089,1,0,,,,,,{STR0090}) //"Data de entrega do equipamento." ## "A data de entrega tem que estar menor ou igual a data de inicio da alocação."			
			Endif
		Endif
		If cCampo == "TFI_COLEQP"
			If dDtCol >= dDtFim
				lRet := .T.
			Else
				Help(,, "At740VldAg",,STR0091,1,0,,,,,,{STR0092}) //"Data de coleta do equipamento." ## "A data de coleta tem que estar maior ou igual a data de fim da alocação."		
			Endif
		Endif
	//Quando a data de entrega e coleta estiver igual ou dentro do período.	
	Elseif cVldAgd == "2"
		If cCampo == "TFI_ENTEQP"
			If dDtEnt >= dDtIni
				lRet := .T.
			Else
				Help(,, "At740VldAg",,STR0089,1,0,,,,,,{STR0093}) //"Data de entrega do equipamento." ## "A data de entrega tem que estar maior ou igual a data de inicio da alocação." 
			Endif
		Endif
		If cCampo == "TFI_COLEQP"
			If dDtCol <= dDtFim .And. dDtCol >= dDtEnt
				lRet := .T.
			Else
				Help(,, "At740VldAg",,STR0091,1,0,,,,,,{STR0094}) //"Data de coleta do equipamento." ## "A data de coleta tem que estar menor ou igual a data de fim da alocação."
			Endif
		Endif
	//Quando a data de entrega estiver igual ou maior que a data de inicio / quando a data de coleta estiver igual ou maior que a data final.
	Elseif cVldAgd == "3"
		If cCampo == "TFI_ENTEQP"
			If dDtEnt >= dDtIni
				lRet := .T.
			Else
				Help(,, "At740VldAg",,STR0089,1,0,,,,,,{STR0093}) //"Data de entrega do equipamento." ## "A data de entrega tem que estar maior ou igual a data de inicio da alocação."	
			Endif
		Endif
		If cCampo == "TFI_COLEQP"
			If dDtCol >= dDtFim
				lRet := .T.
			Else
				Help(,, "At740VldAg",,STR0091,1,0,,,,,,{STR0092}) //"Data de coleta do equipamento." ## "A data de coleta tem que estar maior ou igual a data de fim da alocação."
			Endif
		Endif
	//Quando a data de entrega estiver igual ou menor que a data de inicio / quando a data de coleta estiver igual ou menor que a data final.
	Elseif cVldAgd == "4"
		If cCampo == "TFI_ENTEQP"
			If dDtEnt <= dDtIni
				lRet := .T.
			Else
				Help(,, "At740VldAg",,STR0089,1,0,,,,,,{STR0090}) //"Data de entrega do equipamento." ## "A data de entrega tem que estar menor ou igual a data de inicio da alocação."
			Endif
		Endif
		If cCampo == "TFI_COLEQP"
			If dDtCol <= dDtFim
				lRet := .T.
			Else
				Help(,, "At740VldAg",,STR0091,1,0,,,,,,{STR0094}) //"Data de coleta do equipamento." ## "A data de coleta tem que estar estar menor ou igual a data de fim da alocação."	
			Endif
		Endif
	Endif
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At740CpoOb
Função para pegar os campos obrigatórios de determinados modelos da rotina e retirar o obrigatório deles por conta do facilitador de orçamento.

@author Filipe Gonçalves
@since 07/06/2016
@version P12
/*/
//-------------------------------------------------------------------
Function At740CpoOb(oModel)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local cRet	:= ""
Local aCpos	:= {{"TFF_RH",{}},{"TFG_MI",{}},{"TFH_MC",{}},{"TFI_LE",{}}}
Local nX	:= 0
Local nY	:= 0
Local nPos  := 0

For nX := 1 to len(oModel:GetAllSubModels())
	If  oModel:GetAllSubModels()[nX]:CID $ "TFF_RH|TFG_MI|TFH_MC|TFI_LE"
		cRet   := AllTrim(oModel:GetAllSubModels()[nX]:CID)
		nPos   := aScan(aCpos,{|x| AllTrim(x[1]) == cRet})
		oModNx := oModel:GetModel(cRet)
		aHead  := oModNx:GetStruct():GetFields()
		For nY := 1 To Len(aHead)
			If aHead[nY][MODEL_FIELD_OBRIGAT]
				Aadd(aCpos[nPos,2],aHead[nY][3])
			EndIf
		Next nY
		oModNx:GetStruct():SetProperty("*",MODEL_FIELD_OBRIGAT,.F.)
	EndIf
Next nX

FWRestRows( aSaveLines )
RestArea(aArea)
Return aCpos


//-------------------------------------------------------------------
/*/{Protheus.doc} At740Obriga
Função para tornar os campos obrigatórios novamente, após a função At740CpoOb() retirar a obrigatoriedade.

@author Totvs 
@since 29/06/2016
@version P12
/*/
//-------------------------------------------------------------------
Function At740Obriga()
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oModel    := FwModelActive()
Local oModNx    := Nil
Local nX        := 0
Local nY        := 0
Local aCposObrg := {}

aCposObrg := aObriga
aObriga   := {}
For nX := 1 To Len(aCposObrg)
	oModNx := oModel:GetModel(aCposObrg[nX,1])
	For nY := 1 To Len(aCposObrg[nX,2])
		oModNx:GetStruct():SetProperty(aCposObrg[nX,2,nY],MODEL_FIELD_OBRIGAT,.T.)
	Next nY
Next nX

FWRestRows( aSaveLines )
RestArea(aArea)
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} A740LoadFa
Função de validação para realizar a caraga dos dados nas abas

@author Filipe Gonçalves
@since 01/06/2016
@version P12
/*/
//-------------------------------------------------------------------
Function A740LoadFa(oModelGrid, nLine, cAction, cField, xValue, xOldValue)
Local aArea			:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oModel		:= oModelGrid:GetModel()
Local oModLC		:= oModel:GetModel('TFL_LOC')
Local oModRH		:= oModel:GetModel('TFF_RH')
Local oModMI		:= oModel:GetModel('TFG_MI')
Local oModMC		:= oModel:GetModel('TFH_MC')
Local oModLE		:= oModel:GetModel('TFI_LE')
Local oModTWO		:= oModel:GetModel('TWODETAIL')
Local oMdlFac 		:= Nil
Local oMdlFacRH 	:= Nil
Local oMdlFacMC 	:= Nil
Local oMdlFacMI 	:= Nil
Local oMdlFacLE 	:= Nil
Local cRet			:= ""
Local cChvItem 		:= ""
Local cCodFac		:= ""
Local cItemFc		:= ""
Local lOrcPrc 		:= SuperGetMv("MV_ORCPRC",.F., .F.)
Local cGsDsGcn		:= oModel:GetValue('TFJ_REFER','TFJ_DSGCN')
Local lMatPorValor 	:= .F. 
Local lRet			:= .T.
Local cItem 		:= Replicate("0", TamSx3("TFF_ITEM")[1]  )
Local nTotal 		:= IF(lTotLoc,oModLC:Length(.T.),1)
Local nValItem 		:= 0
Local nDifItem 		:= 0
Local nMulItem 		:= 0
Local nNumItem 		:= 0
Local nQtdFc		:= 0
Local nX			:= 0
Local nY			:= 0
Local cIsGsMt 		:= ""

//Validação ao atribuir valores na tela do facilitador
If !IsInCallStack("LoadXmlData") 
	cIsGsMt := oModel:GetValue('TFJ_REFER','TFJ_ISGSMT')
	If cIsGsMt == "1"
		lMatPorValor := ( oModel:GetValue('TFJ_REFER','TFJ_GSMTMI') $ "23" ) .Or.;
					    ( oModel:GetValue('TFJ_REFER','TFJ_GSMTMC') $ "23" )	
	Else
		lMatPorValor := ( oModel:GetValue('TFJ_REFER','TFJ_GESMAT') $ "23" )
	Endif

	If cAction == 'SETVALUE'
		//Tratativa na mudanção do facilitador zerar o campo de quantidade
		If cField == "TWO_CODFAC"
			TWM->(dbSetOrder(1))//TWN_FILIAL+TWN_CODTWM 
			If TWM->(dbSeek(xFilial("TWM") + xValue))
				If TWM->TWM_DTVALI <= dDataBase
					lRet := .F.
					Help(,,"AT740VLDLOC",,STR0127,1,0) // "Validade do facilitador foi expirada, selecione outro facilitador"
				EndIf
			EndIf
	
			If (!Empty(xOldValue) .And. xValue <> xOldValue) .And. lRet
				//Posiciona no primeiro Local
				If lTotLoc
					oModLC:GoLine(1)
				EndIf
				For nX := 1 To nTotal
					If lTotLoc
						oModLC:GoLine(nX)
					EndIf
					oModTWO:LoadValue("TWO_QUANT", 0)
					//Fazer a deleção dos itens quando zerar a quantidade do facilitador
					TWN->(dbSetOrder(2))//TWN_FILIAL+TWN_CODTWM 
					TWN->(dbSeek(xFilial("TWN") + xOldValue))
					For nY := 1 To oModRH:Length()
						oModRH:GoLine(nY)
						If !Empty(oModRH:GetValue('TFF_CHVTWO')) .And. TWN->TWN_CODTWM == SubStr(oModRH:GetValue('TFF_CHVTWO'), 1, 15)
							oModRH:DeleteLine()
							If !lOrcPrc
								// chama função para excluir as linhas de materiais
								At740FaExMt(oModMC, oModMI, .T.)
							EndIf
						EndIf
					Next nY
					If lOrcPrc
						// chama função para excluir as linhas de materiais
						At740FaExMt(oModMC, oModMI, .T.)
					EndIf
					//Itens Do LE
					For nY := 1 To oModLE:Length()
						oModLE:GoLine(nY)
						If !Empty(oModLE:GetValue('TFI_CHVTWO')) .And. TWN->TWN_CODTWM == SubStr(oModLE:GetValue('TFI_CHVTWO'), 1, 15)
							oModLE:DeleteLine()
						EndIf			
					Next nY
				Next nX
			EndIf
		EndIf
		
		//Verifica se o código e a quantidade estão preenchidos para fazer a carga do SETVALUE
		If !Empty(oModTWO:GetValue('TWO_CODFAC')) .And. (cField == "TWO_QUANT" .And. xValue > 0 ) .And. lRet
			If !Empty(oModTWO:GetValue('TWO_CODFAC'))
				cCodFac := oModTWO:GetValue('TWO_CODFAC')
			EndIf
			//Posiciona no primeiro Local
			If lTotLoc
				oModLC:GoLine(1)
			EndIf
			For nX := 1 To nTotal
				If lTotLoc
					oModLC:GoLine(nX)
	
					If !Empty(oModTWO:GetValue('TWO_CODFAC'))
						cItemFc	:= oModTWO:GetValue('TWO_ITEM')
						nQtdFc	:= xValue
					EndIf
				EndIf
				TWN->(dbSetOrder(2))//TWN_FILIAL+TWN_CODTWM 
				If TWN->(dbSeek(xFilial("TWN") + cCodFac))
					oMdlFac := FwLoadModel("TECA984")
					oMdlFac:SetOperation(MODEL_OPERATION_VIEW)
					oMdlFac:Activate()
					oMdlFacRH := oMdlFac:GetModel("RHDETAIL")
					oMdlFacMC := oMdlFac:GetModel("MCDETAIL")
					oMdlFacMI := oMdlFac:GetModel("MIDETAIL")
					oMdlFacLE := oMdlFac:GetModel("LEDETAIL")
					
					FwModelActive( oModTWO:GetModel() )
					
					For nY := 1 To oMdlFacRH:Length()
						oMdlFacRH:GoLine( nY )
						cItem := Soma1(cItem)
						If !Empty( oMdlFacRH:GetValue("TWN_CODPRO") )
						//Percorrer o modelo para ver se já adicionou aquele facilitador
							If !oModRH:SeekLine( { { 'TFF_CHVTWO', cCodFac + oMdlFacRH:GetValue("TWN_ITEM") + oModTWO:GetValue('TWO_ITEM')}})
								If oModRH:Length() > 1 .Or. !Empty( oModRH:GetValue("TFF_PRODUT") )
									oModRH:AddLine()
								EndIf
							EndIf	
						EndIf
						// atribui os conteúdos relacionados ao controle de associação do facilitador
						nValItem	:= xOldValue
						nDifItem	:= xValue - nValItem
						nMulItem	:= nDifItem * oMdlFacRH:GetValue("TWN_QUANTS")
						nNumItem	:= oModRH:GetValue('TFF_QTDVEN') + nMulItem
						cChvItem	:= cCodFac + oMdlFacRH:GetValue("TWN_ITEM") + oModTWO:GetValue('TWO_ITEM')
	
						oModRH:SetValue('TFF_ITEM', cItem)
						oModRH:SetValue('TFF_CHVTWO', cChvItem)
						oModRH:SetValue('TFF_PRODUT', oMdlFacRH:GetValue("TWN_CODPRO"))
						oModRH:SetValue('TFF_QTDVEN', nNumItem)
						If oMdlFacRH:GetValue("TWN_VLUNIT") > 0
							oModRH:SetValue('TFF_PRCVEN', oMdlFacRH:GetValue("TWN_VLUNIT"))
						EndIf
						oModRH:SetValue('TFF_FUNCAO', oMdlFacRH:GetValue("TWN_FUNCAO"))
						oModRH:SetValue('TFF_TURNO'	, oMdlFacRH:GetValue("TWN_TURNO"))
						oModRH:SetValue('TFF_CARGO'	, oMdlFacRH:GetValue("TWN_CARGO"))
						If cGsDsGcn == "1"
							oModRH:SetValue('TFF_TESPED', oMdlFacRH:GetValue("TWN_TESPED"))
						EndIf
							//Informa o produto e valor do beneficio
						
						//oModRH:SetValue('TFF_VLBENE'	, oMdlFacRH:GetValue("TWN_VLBENE"))
						
						If !Empty(oMdlFacRH:GetValue("TWN_ESCALA"))
							oModRH:SetValue('TFF_ESCALA'	, oMdlFacRH:GetValue("TWN_ESCALA"))
						Endif
						
						If !lOrcPrc .And. !lMatPorValor
							// atualiza materia de implantação
							At740FaMat( oModTWO, oMdlFacMI, oModMI, xValue, xOldValue, "TFG", cCodFac )
							// atualiza materia de consumo
							At740FaMat( oModTWO, oMdlFacMC, oModMC, xValue, xOldValue, "TFH", cCodFac )
						EndIf
					Next nY
					oModRH:GoLine(1)
					
					If lOrcPrc .And. !lMatPorValor
						// atualiza materia de implantação
						At740FaMat( oModTWO, oMdlFacMI, oModMI, xValue, xOldValue, "TFG", cCodFac )
						// atualiza materia de consumo
						At740FaMat( oModTWO, oMdlFacMC, oModMC, xValue, xOldValue, "TFH", cCodFac )
					EndIf
					
					//Zera a variável para utilizar na grid de LE
					cItem := Replicate("0", TamSx3("TFI_ITEM")[1]  )
	
					For nY := 1 To oMdlFacLE:Length()
						oMdlFacLE:GoLine( nY )
						cItem := Soma1(cItem)
						If !Empty(oMdlFacLE:GetValue("TWN_CODPRO"))
							If !oModLE:SeekLine( { { 'TFI_CHVTWO',cCodFac + oMdlFacLE:GetValue("TWN_ITEM") + oModTWO:GetValue('TWO_ITEM') } } )
							//Verificar se não encontrou o facilitardor adicionar uma linha nova com as informações
								If oModLE:Length() > 1 .Or. !Empty( oModLE:GetValue("TFI_PRODUT") )						
									oModLE:AddLine()
								EndIf
							EndIf
							nValItem	:= xOldValue
							nDifItem	:= xValue - nValItem
							nMulItem	:= nDifItem * oMdlFacLE:GetValue("TWN_QUANTS")
							nNumItem	:= oModLE:GetValue('TFI_QTDVEN') + nMulItem
							cChvItem :=  cCodFac + oMdlFacLE:GetValue("TWN_ITEM") + oModTWO:GetValue('TWO_ITEM')
							oModLE:SetValue('TFI_ITEM', cItem)
							oModLE:SetValue('TFI_CHVTWO', cChvItem)
							oModLE:SetValue('TFI_PRODUT', oMdlFacLE:GetValue("TWN_CODPRO"))
							oModLE:SetValue('TFI_QTDVEN', nNumItem)
							oModLE:SetValue('TFI_TES', oMdlFacLE:GetValue("TWN_TES"))
							If cGsDsGcn == "1"
								oModLE:SetValue('TFI_TESPED', oMdlFacLE:GetValue("TWN_TESPED"))
							EndIf
						EndIf
					Next nY
					
					cItem := Replicate("0", TamSx3("TFF_ITEM")[1]  )
	
					oModLE:GoLine(1)
					oMdlFac:DeActivate()
					oMdlFac:Destroy()
					oMdlFac := Nil
					FwModelActive( oModTWO:GetModel() )
				EndIf
			Next nX
	
			//Tratativa para duplicar o registro na TWO para os demais locais 
			If lTotLoc
				For nY := 1 To oModLC:Length()
					oModLC:GoLine(nY)
					If Empty(oModTWO:GetValue('TWO_CODFAC'))
						If !(Empty(oModTWO:GetValue('TWO_ITEM')))
							oModLC:AddLine()
						EndIF
						oModTWO:LoadValue('TWO_ITEM'	,cItemFc)
						oModTWO:LoadValue('TWO_CODFAC'	,cCodFac)
						oModTWO:LoadValue('TWO_DESCRI'	,Posicione("TWM",1,xFilial("TWM") + cCodFac ,"TWM_DESCRI"))
						oModTWO:LoadValue('TWO_QUANT'	,nQtdFc)
					EndIf
				Next nY
			EndIf
		EndIf
	
	//Validação ao deletar a linha do facilitador
	ElseIf cAction == 'DELETE'
		If lTotLoc
			lDelTWO := .T.
		EndIf
		//Itens Do RH
		TWN->(dbSetOrder(2))//TWN_FILIAL+TWN_CODTWM 
		TWN->(dbSeek(xFilial("TWN") + oModTWO:GetValue('TWO_CODFAC')))
		For nY := 1 To oModRH:Length()
			oModRH:GoLine(nY)
			cChavTWO := SubStr(oModRH:GetValue('TFF_CHVTWO'), 1, 15) + SubStr(oModRH:GetValue('TFF_CHVTWO'), 19, 3)
			If !Empty(oModRH:GetValue('TFF_CHVTWO')) .And. TWN->TWN_CODTWM + oModTWO:GetValue('TWO_ITEM') == cChavTWO
				oModRH:DeleteLine()
				If !lOrcPrc
					// chama função para excluir as linhas de materiais
					At740FaExMt(oModMC, oModMI, .T., oModTWO)
				EndIf
			EndIf
		Next nY
			
		If lOrcPrc
			// chama função para excluir as linhas de materiais
			At740FaExMt(oModMC, oModMI, .T., oModTWO)
		EndIf
			
		//Itens Do LE
		For nY := 1 To oModLE:Length()
			oModLE:GoLine(nY)
			cChavTWO := SubStr(oModLE:GetValue('TFI_CHVTWO'), 1, 15) + SubStr(oModLE:GetValue('TFI_CHVTWO'), 19, 3)
			If !Empty(oModLE:GetValue('TFI_CHVTWO')) .And. TWN->TWN_CODTWM + oModTWO:GetValue('TWO_ITEM') == cChavTWO
				oModLE:DeleteLine()
			EndIf			
		Next nY
	
	//Validação para habilitar a linha deletada
	ElseIf cAction == 'UNDELETE'
		If lTotLoc
			lUnDel := .T.
		EndIf
		//Verifica se existe um registro duplicado ao habilitar a linha
		If lRet 
			TWN->(dbSetOrder(2))//TWN_FILIAL+TWN_CODTWM 
			TWN->(dbSeek(xFilial("TWN") + oModTWO:GetValue('TWO_CODFAC')))
			For nY := 1 To oModRH:Length()
				oModRH:GoLine(nY)
				cChavTWO := SubStr(oModRH:GetValue('TFF_CHVTWO'), 1, 15) + SubStr(oModRH:GetValue('TFF_CHVTWO'), 19, 3)
				If !Empty(oModRH:GetValue('TFF_CHVTWO')) .And. TWN->TWN_CODTWM + oModTWO:GetValue('TWO_ITEM') == cChavTWO
					oModRH:UnDeleteLine()
					If !lOrcPrc
						// chama função para excluir as linhas de materiais
					At740FaExMt(oModMC, oModMI, .F., oModTWO)
					EndIf
				EndIf
			Next nY
				If lOrcPrc
					// chama função para excluir as linhas de materiais
				At740FaExMt(oModMC, oModMI, .F., oModTWO)
				EndIf
			//Itens Do LE	
			For nY := 1 To oModLE:Length()
				oModLE:GoLine(nY)
				cChavTWO := SubStr(oModLE:GetValue('TFI_CHVTWO'), 1, 15) + SubStr(oModLE:GetValue('TFI_CHVTWO'), 19, 3)
				If !Empty(oModLE:GetValue('TFI_CHVTWO')) .And. TWN->TWN_CODTWM + oModTWO:GetValue('TWO_ITEM') == cChavTWO
					oModLE:UnDeleteLine()
				EndIf			
			Next nY
		EndIf
	
	//Validação para habilitar edição na linha quando o Local e as datas de inicio e fim estiverem informadas
	ElseIf cAction == 'CANSETVALUE'
		If !Empty(oModTWO:GetValue('TWO_CODFAC'))
			cCodFac := oModTWO:GetValue('TWO_CODFAC')
		EndIf 
	
		If cField = 'TWO_CODFAC' 
			If Empty(oModLC:GetValue('TFL_LOCAL')) .Or. Empty(oModLC:GetValue('TFL_DTINI')) .Or. Empty(oModLC:GetValue('TFL_DTFIM'))
				lRet := .F.
			EndIf
		ElseIf cField = 'TWO_QUANT'
			If Empty(cCodFac)
				lRet := .F.
			Else
				lRet := .T.
			EndIf
		EndIf
	EndIf
EndIf	

FWRestRows( aSaveLines )
RestArea(aArea)
	
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} TEC740FACI
Função de validação para realizar a caraga dos dados nas abas

@author Filipe Gonçalves
@since 01/06/2016
@version P12
/*/
//-------------------------------------------------------------------
Function TEC740FACI(oModLoc)
	
Local aArea			:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oModel		:= FwModelActive()
Local oStruTWO		:= FwFormStruct(2, 'TWO', {|cCpo| At740SelFields( 'TWO', Alltrim(cCpo) )})
Local oSubView		:= FwFormView():New(oModel)
Local oModelTFL	    := oModel:GetModel('TFL_LOC')
Local oModelTWO	    := oModel:GetModel('TWODETAIL')
Local lRet			:= .T.
Local nX		:= 0
Local nY		:= 0

If oModelTFL:Length(.T.) > 1
	lTotLoc := MsgYesNo(STR0128) // "Deseja replicar o facilitador para todos os Locais de atendimento deste orçamento? "
EndIf

If lRet := 	!Empty(oModelTFL:GetValue('TFL_LOCAL'))
	
	//Função para pegar os campos obrigatórios de determinados modelos da rotina
	If Len(aObriga) == 0
		aObriga := At740CpoOb(oModel)
	EndIf
	
	//Cria uma subView para chamar na tela flutuante
	oSubView:SetModel(oModel)
	oSubView:CreateHorizontalBox('POPBOX',100)
	oSubView:AddGrid('VIEW_TWO',oStruTWO,'TWODETAIL')
	oSubView:AddIncrementField('VIEW_TWO', 'TWO_ITEM')
	oSubView:SetOwnerView('VIEW_TWO','POPBOX')

	TECXFPOPUP(oModel,oSubView, STR0096, MODEL_OPERATION_UPDATE, 70 )
	
	If lTotLoc .And. lDelTWO
		For nY := 1 To oModelTFL:Length()
			oModelTFL:Goline(nY)
			For nX := 1 to oModelTWO:Length()
				oModelTWO:GoLine(nX)
				If !Empty(oModelTWO:GetValue('TWO_CODFAC')) .And. !oModelTWO:IsDeleted()
					oModelTWO:Deleteline()
				EndIf	
			next nX
		Next nY
		lDelTWO := .F.
	ElseIf lTotLoc .And. lUnDel
		For nY := 1 To oModelTFL:Length()
			oModelTFL:Goline(nY)
			For nX := 1 to oModelTWO:Length()
				oModelTWO:GoLine(nX)
				If !Empty(oModelTWO:GetValue('TWO_CODFAC')) .And. oModelTWO:IsDeleted()
					oModelTWO:UnDeleteLine()
				EndIf	
			next nX
		Next nY
		lUnDel := .F.
	EndIf
		
	// Função que torna todos os campos obrigatórios novamente, após ter a obrigatoriedade retirada pela função At740CpoOb().
	At740Obriga()
Else
	Help(,,"AT740VLDLOC",,STR0097,1,0) //- "Para utilizar o facilitador por favor informe um Local de Atendimento e suas datas de vigência." 
EndIf
FWRestRows( aSaveLines )
RestArea(aArea)
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At740TEVQt
	Calcula a qtde de dias do item qdo preenchido o campo de modo de cobrança
@return 	nValor, Numérico, qtde de dias a ser utilizado como "diária" para o período e quantidade de itens indicado pelo usuário
@param 		lAtribui, Lógico, indica se deve acontecer a atribuição do conteúdo ao campo (por vir do gatilho de um modelo diferente) 
								ou simplesmente retornar o conteúdo
/*/
//-------------------------------------------------------------------
Function At740TEVQt( lAtribui )
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local nQtde := 0
Local nDias := 0
Local oModel := FwModelActive()
Local oMdlTFI := Nil
Local cCodProd := ""
Local lIdUnico := .T.
Local oMdlTEV := Nil
Local oMdlTFJ := Nil
Default lAtribui := .F.

If oModel:GetId() == "TECA740" .Or. oModel:GetId() == "TECA740F" 
	oMdlTFJ := oModel:GetModel("TFJ_REFER")
	oMdlTFI := oModel:GetModel("TFI_LE")
	oMdlTEV := oModel:GetModel("TEV_ADICIO")

	If oMdlTFJ:GetValue("TFJ_CNTREC") == "2" //Quando for contrato reccorente.
	
		If Alltrim(oMdlTFI:GetValue("TFI_APUMED")) == '2' //Entrega e coleta
			nDias := oMdlTFI:GetValue("TFI_COLEQP") - oMdlTFI:GetValue("TFI_ENTEQP") + 1
		ElseIf Alltrim(oMdlTFI:GetValue("TFI_APUMED")) == '3' //Inicio e Coleta
			nDias := oMdlTFI:GetValue("TFI_COLEQP") - oMdlTFI:GetValue("TFI_PERINI") + 1
		ElseIf Alltrim(oMdlTFI:GetValue("TFI_APUMED")) == '4' //Entrega e Fim	 
			nDias := oMdlTFI:GetValue("TFI_PERFIM") - oMdlTFI:GetValue("TFI_ENTEQP") + 1
		Else 
			// ' ' OR '1' = Início e Fim
			// '5' = Nota remessa(sera usado o Inicio como não temos a Nota nesse momento) e Fim
			nDias := oMdlTFI:GetValue("TFI_PERFIM") - oMdlTFI:GetValue("TFI_PERINI") + 1
		EndIf
	Else
		nDias := 30
	Endif
	
	cCodProd := oMdlTFI:GetValue("TFI_PRODUT")
	// verifica se o produto é Id Único
	If !Empty( cCodProd )
		lIdUnico :=	Posicione("SB5",1,xFilial("SB5")+cCodProd,"B5_ISIDUNI") $ " |1"
	EndIf
	
	// quando é Id Único a qtde é só a diferença de dias
	If lIdUnico
		nQtde := nDias * oMdlTFI:GetValue("TFI_QTDVEN")
	Else
		nQtde := nDias 
	EndIf
	
	If lAtribui .And. nQtde > 0 .And. oMdlTEV:SeekLine({{"TEV_MODCOB","2"}})
		oMdlTEV:SetValue("TEV_QTDE", nQtde)
	EndIf
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return nQtde

//-------------------------------------------------------------------
/*/{Protheus.doc} At740TEVMC
	Consiste o tipo de cobrança x modo de cobrança para a locação de um equipamento
@param 		NIL
@return 	.T.=Tipo de cobrança x Modo de cobrança válido // .F.=Tipo de cobrança x Modo de cobrança inválido 
@since		15/07/2016
@version	P12
/*/
//-------------------------------------------------------------------
Function At740TEVMC()
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oMdl   	:= FwModelActive()
Local cTpCobr	:= FwFldGet("TFI_TPCOBR")	//1=Dias;2=Horas
Local cMdCobr	:= FwFldGet("TEV_MODCOB")	//1=Uso;2=Disponibilidade;3=Mobilização;4=Horas;5=Franquia/Excedente
Local lRet		:= .T.
Local cMdOposto := ""
Local nI 		:= 0
Local oMdlModCob := Nil

If cTpCobr == "1" .AND. ( cMdCobr == "4" .Or. cMdCobr == "5" )
	lRet	:= .F.
	Help(,,"AT740TEVMC",,STR0129,; // "Não é permitido utilizar o modo de cobrança por horas com o tipo de cobrança na locação igual a 1-Dias."
							1,0,,,,,,{STR0130}) // "Selecione outro modo de cobrança ou altere o tipo da locação para horímetro."

ElseIf cTpCobr == "2" .AND. ( cMdCobr == "4" .Or. cMdCobr == "5" )
	cMdOposto := If( cMdCobr == "4", "5", "4" )
	
	oMdlModCob := oMdl:GetModel("TEV_ADICIO")
	
	For nI := 1 To oMdlModCob:Length()
		If oMdlModCob:GetValue("TEV_MODCOB",nI) == cMdOposto
	lRet	:= .F.
			Help(,,"AT740TEVMC",,STR0131,; // "Não é permitido utilizar os dois modos de cobrança por horas."
									1,0,,,,,,{STR0132}) // "Escolha somente uma das opções entre 4-Horas ou 5-Franquia/Excedente."
			Exit
		EndIf
	Next
	
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At740WhCob
	Verifica se a linha deve ter seu valor atualizado para o total do orçamento/contrato
	Utilizado no bloco bCond do totalizador do MVC do grid de modo de cobrança de locação
@author 	Inovação Gestão de Serviços
@since		14/09/2016
@version	P12
@param 		oModel, Objeto FwFormModel/MpFormModel, objeto principal do cadastro MVC
@return 	Lógico, .T. soma, .F. não soma
/*/
//-------------------------------------------------------------------
Function At740WhCob( oModel )
// não soma os itens do tipo 5-Franquia/Excedente
Local lSoma := ( oModel:GetModel("TEV_ADICIO"):GetValue("TEV_MODCOB") <> '5' )

Return lSoma

//-------------------------------------------------------------------
/*/{Protheus.doc} At740SmTEV
	Zera os valores da linha quando identificar 
	Executado a partir de gatilho do campo de modo de cobrança
@author 	Inovação Gestão de Serviços
@since		14/09/2016
@version	P12
/*/
//-------------------------------------------------------------------
Function At740SmTEV()
Local oMdl := FwModelActive()
Local oMdlTEV := Nil
Local cModSelec := ""

If ((cModSelec := FwFldGet("TEV_MODCOB")) == '5') .And. FwFldGet("TEV_VLRUNI") > 0
	oMdlTEV := oMdl:GetModel("TEV_ADICIO")
	oMdlTEV:LoadValue("TEV_VLRUNI",0) // faz por load por causa da validação no campo
	oMdlTEV:SetValue("TEV_SUBTOT",0)  // faz via set para disparar as demais atualizações
	oMdlTEV:SetValue("TEV_VLTOT",0)   // faz via set para disparar as demais atualizações
EndIf

Return cModSelec

//-------------------------------------------------------------------
/*/{Protheus.doc} At740FaMat
	Função para adicionar valores nas Grids de Materiais 
@param 		NIL
@return 	.T.
@since		15/08/2016
@version	P12
/*/
//-------------------------------------------------------------------
Static Function At740FaMat( oModTWO, oMdoFacMat, oModGridOrc, xValue, xOldValue, cTab, cCodFac)

Local nX := 0
Local nY := 0
Local nValItem := 0
Local nDifItem := 0
Local nMulItem := 0
Local nNumItem := 0
Local cChvItem := ""
Local cItem		:= Replicate("0", TamSx3(cTab +"_ITEM")[1]  ) 
Local cGsDsGcn	:= oModGridOrc:GetModel():GetValue('TFJ_REFER','TFJ_DSGCN')

For nY := 1 To oMdoFacMat:Length()
	oMdoFacMat:GoLine( nY )
	cItem := Soma1(cItem)
	If !Empty(oMdoFacMat:GetValue("TWN_CODPRO"))
		If !oModGridOrc:SeekLine( { { cTab+'_CHVTWO' , ;
				oModTWO:GetValue('TWO_CODFAC') + oMdoFacMat:GetValue("TWN_ITEM") + oModTWO:GetValue('TWO_ITEM') } } )
			//Verificar se não encontrou o facilitardor adicionar uma linha nova com as informações
			If oModGridOrc:Length() > 1 .Or. !Empty( oModGridOrc:GetValue(cTab+"_PRODUT") )
				oModGridOrc:AddLine()
			EndIf
		EndIf
		nValItem	:= xOldValue
		nDifItem	:= xValue - nValItem
		nMulItem	:= nDifItem * oMdoFacMat:GetValue("TWN_QUANTS")
		nNumItem	:= oModGridOrc:GetValue(cTab+'_QTDVEN') + nMulItem
		cChvItem	:= cCodFac + oMdoFacMat:GetValue("TWN_ITEM") + oModTWO:GetValue('TWO_ITEM')
		oModGridOrc:SetValue(cTab+'_ITEM', cItem)
		oModGridOrc:SetValue(cTab+'_CHVTWO', cChvItem)
		oModGridOrc:SetValue(cTab+'_PRODUT', oMdoFacMat:GetValue("TWN_CODPRO"))
		oModGridOrc:SetValue(cTab+'_QTDVEN', nNumItem)
		If oMdoFacMat:GetValue("TWN_VLUNIT") > 0
			oModGridOrc:SetValue(cTab+'_PRCVEN', oMdoFacMat:GetValue("TWN_VLUNIT"))
		EndIf
		If !Empty(oMdoFacMat:GetValue("TWN_TES"))
			oModGridOrc:SetValue(cTab+'_TES', oMdoFacMat:GetValue("TWN_TES"))
		EndIf
		If cGsDsGcn == "1" .And. !Empty(oMdoFacMat:GetValue("TWN_TESPED"))
			oModGridOrc:SetValue(cTab+'_TESPED', oMdoFacMat:GetValue("TWN_TESPED"))
		EndIf
	EndIf
Next nY

oModGridOrc:GoLine(1)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} At740FaExMt
	Função para deletar as informações nas Grids MC e MI
@param 		NIL
@return 	.T.
@since		15/08/2016
@version	P12
/*/
//-------------------------------------------------------------------
Static Function At740FaExMt(oModMC, oModMI, lDelete, oModTWO)

Local nX := 0
Local cChavTWO	:= ""

Default lDelete := .T.

If lDelete
	//Itens Do MC	
	For nX := 1 To oModMC:Length()
		oModMC:GoLine(nX)
		cChavTWO := SubStr(oModMC:GetValue('TFH_CHVTWO'), 1, 15) + SubStr(oModMC:GetValue('TFH_CHVTWO'), 19, 3)
		If !Empty(oModMC:GetValue('TFH_CHVTWO')) .And. TWN->TWN_CODTWM + oModTWO:GetValue('TWO_ITEM') == cChavTWO
			oModMC:DeleteLine()
		EndIf
	Next nX
	//Itens Do MI
	For nX := 1 To oModMI:Length()
		oModMI:GoLine(nX)
		cChavTWO := SubStr(oModMI:GetValue('TFG_CHVTWO'), 1, 15) + SubStr(oModMI:GetValue('TFG_CHVTWO'), 19, 3)
		If !Empty(oModMI:GetValue('TFG_CHVTWO')) .And. TWN->TWN_CODTWM + oModTWO:GetValue('TWO_ITEM') == cChavTWO 
			oModMI:DeleteLine()
		EndIf
	Next nX

Else
	//Itens Do MC	
	For nX := 1 To oModMC:Length()
		oModMC:GoLine(nX)
		cChavTWO := SubStr(oModMC:GetValue('TFH_CHVTWO'), 1, 15) + SubStr(oModMC:GetValue('TFH_CHVTWO'), 19, 3)
		If !Empty(oModMC:GetValue('TFH_CHVTWO')) .And. TWN->TWN_CODTWM + oModTWO:GetValue('TWO_ITEM') == cChavTWO 
			oModMC:UnDeleteLine()
		EndIf
	Next nX
	//Itens Do MI
	For nX := 1 To oModMI:Length()
		oModMI:GoLine(nX)
		cChavTWO := SubStr(oModMC:GetValue('TFG_CHVTWO'), 1, 15) + SubStr(oModMC:GetValue('TFG_CHVTWO'), 19, 3)
		If !Empty(oModMI:GetValue('TFG_CHVTWO')) .And. TWN->TWN_CODTWM + oModTWO:GetValue('TWO_ITEM') == cChavTWO 
			oModMI:UnDeleteLine()
		EndIf
	Next nX

EndIf

Return 

/*/{Protheus.doc} At740Del
	Função para excluir um orçamento de serviços
@param 		nDelTFJ, numérico, indica o recno do cabeçalho do orçamento de serviços
@return 	Lógico, determina se a exclusão aconteceu com sucesso ou não
@since		29/12/16
@version	P12
/*/
Function At740Del( nDelTFJ )
Local lRet := .T.
Local lOrcPrc := SuperGetMV("MV_ORCPRC",,.F.)
Local oModel := If( lOrcPrc, FwLoadModel("TECA740F"), FwLoadModel("TECA740") )

TFJ->( DbGoTo( nDelTFJ ) )
oModel:SetOperation(MODEL_OPERATION_DELETE)

lRet := lRet .And. oModel:Activate()
At740SCmt( .T. )
lRet := lRet .And. oModel:VldData()
lRet := lRet .And. oModel:CommitData()

At740SCmt( .F. )

If !lRet
	AtErroMvc( oModel )
	MostraErro()
EndIf

Return lRet

/*/{Protheus.doc} At740IsOrc
@description 	Verifica se o registro posicionado é do orçamento de serviços 
@param 			cModItem, caracter, modelo de origem do item a ser avaliado
@param 			cCodItemEval, caracter, código do item que precisa ser avaliado
@param 			cCodTFJ, caracter, código do orçamento de serviços a ser avaliado
@return 		Lógico, indica se o item pertence ao orçamento de serviços ou não
@since			19/01/17
@version		P12
/*/
Function At740IsOrc( cModItem, cCodTFJ, cCodTFL, oMdlAtivo )
Local lFound 		:= .F.
Local cEvalQuery 	:= ""
Local cTabTemp 		:= ""
Local nOrcPrc 		:= 0
Local cCodItemEval 	:= ""
Local cExpCodTFL 	:= ""

Default cCodTFL 	:= ""

// executa as avaliações conforme o modelo que entrou e a tabela relacionada a entidade | geralmente orçamento de serviços
If cModItem == "TFF_RH" .Or. cModItem == "TGV_RH" .Or. cModItem == "ABP_BENEF"
	If cModItem == "TGV_RH"
		cCodItemEval := TGV->TGV_CODTFF
	ElseIf cModItem == "ABP_BENEF"
		cCodItemEval := ABP->ABP_ITRH
	Else
		cCodItemEval := TFF->TFF_COD
	EndIf

	If Empty(cCodTFL)
		cExpCodTFL := "% TFF_FILIAL = '"+xFilial("TFF")+"' "
		cExpCodTFL += "AND TFF_COD = '"+cCodItemEval+"' "
		cExpCodTFL += "AND TFF.D_E_L_E_T_=' '%"
	Else
		cExpCodTFL := "% TFF_FILIAL = '"+xFilial("TFF")+"' "
		cExpCodTFL += "AND TFF_COD = '"+cCodItemEval+"' "
		cExpCodTFL += "AND TFL_CODIGO = '"+cCodTFL+"' "
		cExpCodTFL += "AND TFF.D_E_L_E_T_=' ' %"
	EndIf

	cTabTemp := GetNextAlias()

	BeginSql Alias cTabTemp
		SELECT TFJ_CODIGO
		FROM %Table:TFF% TFF
			INNER JOIN %Table:TFL% TFL ON TFL_FILIAL = %xFilial:TFL%
									AND TFL_CODIGO = TFF_CODPAI
									AND TFL.%NotDel%
			INNER JOIN %Table:TFJ% TFJ ON TFJ_FILIAL = %xFilial:TFJ%
									AND TFJ_CODIGO = TFL_CODPAI
									AND TFJ.%NotDel%
		WHERE 
			%Exp:cExpCodTFL%
			
	EndSql

	If (cTabTemp)->(!EOF()) .And. (cTabTemp)->TFJ_CODIGO == cCodTFJ
		lFound := .T.
	EndIf

	(cTabTemp)->(DbCloseArea())

ElseIf cModItem == "TFG_MI"
	nOrcPrc := If( SuperGetMV("MV_ORCPRC",,.F.), 1, 0)
	// executa a avaliação quando é orçamento com precificação
	// ou quando o item não é filho de um novo item de Rh
	If nOrcPrc == 1 .Or. ;
		!oMdlAtivo:GetModel("TFF_RH"):IsInserted()

		cCodItemEval := TFG->TFG_COD

		If Empty(cCodTFL)
			cExpCodTFL := "% TFG_FILIAL = '"+xFilial("TFG")+"' "
			cExpCodTFL += "AND TFG_COD = '"+cCodItemEval+"' "
			cExpCodTFL += "AND TFG.D_E_L_E_T_=' '%"
		Else
			cExpCodTFL := "% TFG_FILIAL = '"+xFilial("TFG")+"' "
			cExpCodTFL += "AND TFG_COD = '"+cCodItemEval+"' "
			cExpCodTFL += "AND TFL_CODIGO = '"+cCodTFL+"' "
			cExpCodTFL += "AND TFG.D_E_L_E_T_=' ' %"
		EndIf

		cTabTemp := GetNextAlias()

		BeginSql Alias cTabTemp
			SELECT TFJ_CODIGO
			FROM %Table:TFG% TFG
				LEFT JOIN %Table:TFF% TFF ON 0 = %Exp:nOrcPrc%
										AND TFF_FILIAL = %xFilial:TFF%
										AND TFF_COD = TFG_CODPAI
										AND TFF.%NotDel%
				INNER JOIN %Table:TFL% TFL ON TFL_FILIAL = %xFilial:TFL%
										AND (
												(0 = %Exp:nOrcPrc% AND TFL_CODIGO = TFF_CODPAI)
												OR (1 = %Exp:nOrcPrc% AND TFL_CODIGO = TFG_CODPAI)
											)
										AND TFL.%NotDel%
				INNER JOIN %Table:TFJ% TFJ ON TFJ_FILIAL = %xFilial:TFJ%
										AND TFJ_CODIGO = TFL_CODPAI
										AND TFJ.%NotDel%
			WHERE 
				%Exp:cExpCodTFL%
		EndSql

		If (cTabTemp)->(!EOF()) .And. (cTabTemp)->TFJ_CODIGO == cCodTFJ
			lFound := .T.
		EndIf

		(cTabTemp)->(DbCloseArea())
	EndIf
ElseIf cModItem == "TFH_MC"
	nOrcPrc := If( SuperGetMV("MV_ORCPRC",,.F.), 1, 0)
	// executa a avaliação quando é orçamento com precificação
	// ou quando o item não é filho de um novo item de Rh
	If nOrcPrc == 1 .Or. ;
		!oMdlAtivo:GetModel("TFF_RH"):IsInserted()
		
		cCodItemEval := TFH->TFH_COD

		If Empty(cCodTFL)
			cExpCodTFL := "% TFH_FILIAL = '"+xFilial("TFH")+"' "
			cExpCodTFL += "AND TFH_COD = '"+cCodItemEval+"' "
			cExpCodTFL += "AND TFH.D_E_L_E_T_=' ' %"
		Else
			cExpCodTFL := "% TFH_FILIAL = '"+xFilial("TFH")+"' "
			cExpCodTFL += "AND TFH_COD = '"+cCodItemEval+"' "
			cExpCodTFL += "AND TFL_CODIGO = '"+cCodTFL+"' "
			cExpCodTFL += "AND TFH.D_E_L_E_T_=' ' %"
		EndIf

		cTabTemp := GetNextAlias()

		BeginSql Alias cTabTemp
			SELECT TFJ_CODIGO
			FROM %Table:TFH% TFH
				LEFT JOIN %Table:TFF% TFF ON 0 = %Exp:nOrcPrc%
										AND TFF_FILIAL = %xFilial:TFF%
										AND TFF_COD = TFH_CODPAI
										AND TFF.%NotDel%
				INNER JOIN %Table:TFL% TFL ON TFL_FILIAL = %xFilial:TFL%
										AND (
												(0 = %Exp:nOrcPrc% AND TFL_CODIGO = TFF_CODPAI)
												OR (1 = %Exp:nOrcPrc% AND TFL_CODIGO = TFH_CODPAI)
											)
										AND TFL.%NotDel%
				INNER JOIN %Table:TFJ% TFJ ON TFJ_FILIAL = %xFilial:TFJ%
										AND TFJ_CODIGO = TFL_CODPAI
										AND TFJ.%NotDel%
			WHERE 
				%Exp:cExpCodTFL%
		EndSql

		If (cTabTemp)->(!EOF()) .And. (cTabTemp)->TFJ_CODIGO == cCodTFJ
			lFound := .T.
		EndIf

		(cTabTemp)->(DbCloseArea())
	EndIf
ElseIf cModItem == "TFI_LE"
	cCodItemEval := TFI->TFI_COD
	If Empty(cCodTFL)
		cExpCodTFL := "% TFI_FILIAL = '"+xFilial("TFI")+"' "
		cExpCodTFL += "AND TFI_COD = '"+cCodItemEval+"' "
		cExpCodTFL += "AND TFI.D_E_L_E_T_=' ' %"
	Else
		cExpCodTFL := "% TFI_FILIAL = '"+xFilial("TFI")+"' "
		cExpCodTFL += "AND TFI_COD = '"+cCodItemEval+"' "
		cExpCodTFL += "AND TFL_CODIGO = '"+cCodTFL+"' "
		cExpCodTFL += "AND TFI.D_E_L_E_T_=' ' %"
	EndIf
	cTabTemp := GetNextAlias()

	BeginSql Alias cTabTemp
		SELECT TFJ_CODIGO
		FROM %Table:TFI% TFI
			INNER JOIN %Table:TFL% TFL ON TFL_FILIAL = %xFilial:TFL%
									AND TFL_CODIGO = TFI_CODPAI
									AND TFL.%NotDel%
			INNER JOIN %Table:TFJ% TFJ ON TFJ_FILIAL = %xFilial:TFJ%
									AND TFJ_CODIGO = TFL_CODPAI
									AND TFJ.%NotDel%
		WHERE 
			%Exp:cExpCodTFL%
	EndSql

	If (cTabTemp)->(!EOF()) .And. (cTabTemp)->TFJ_CODIGO == cCodTFJ
		lFound := .T.
	EndIf

	(cTabTemp)->(DbCloseArea())

Else 
	// qlq caso diferente da lista não é avaliado
	lFound := .T.
EndIf

Return lFound

/*/{Protheus.doc} At740VldCC
	Função para validar o centro de custo do local de atendimento

@return 	Lógico, Determina se o centro de custo do local é o mesmo do sitema
@since		13/02/2017
@version	P12
/*/
Function At740VldCC(oMdlTFL)
Local lRet		:= .T.
Local oModel	:= FwModelActive()
Local oMdlTFL 	:= Nil
Local cLocal 	:= ""
Local lIsOrcServ 	:= oModel:GetId() $ "TECA740/TECA740F"
Local aArea		:= GetArea()

//Verifica se o centro de custo do local é o mesmo que está logado
DbSelectArea("ABS")
ABS->(DbSetOrder(1))
If lIsOrcServ 
	oMdlTFL	:= oModel:GetModel('TFL_LOC')
	cLocal	:= oMdlTFL:GetValue("TFL_LOCAL")
	If ABS->(MsSeek(xFilial("ABS")+ cLocal)) .And. !Empty(ABS->ABS_FILCC) .And. (cFilAnt <> ABS->ABS_FILCC)
		lRet	:= .F.
		oModel:GetModel():SetErrorMessage(oModel:GetId(),"TFL_LOCAL",oModel:GetModel():GetId(),	"TFL_LOCAL",'TFL_LOCAL',; 
			STR0135, STR0136 )//"A filial do centro de custo do local de atendimento selecionado é diferente da filial do sistema"##"Selecione um local de atendimento onde a filial do centro de custo configurado seja o mesmo do sistema"	
	EndIf
EndIf

RestArea(aArea)

Return lRet
//-------------------------------------------------------------------
/*/{Protheus.doc} At740GatRc
	Gatilho para inserir a data no campo de data fim.
@author 	Kaique Schiller
@param 		NIL
@return 	cCod
@since		04/04/2017
@version	P12.1.16
/*/
//-------------------------------------------------------------------
Function At740GatRc(cCod,cCamp,cDetail,oMdl)
Local dDtFim 		:= SuperGetMv("MV_CNVIGCP",,cTod("31/12/2049"))
Local oModel		:= Nil
Local oDetail		:= Nil
Local oStruct 		:= Nil
Local bWhen			:= {|| .T. }
Local bValid		:= {|| .T. }
Local aDtl			:= {}

Default cCod 		:= ""
Default cCamp 		:= ""
Default cDetail		:= ""
Default oMdl		:= Nil

If !Empty(cCamp) .And. !Empty(cDetail) .and. !IsInCallStack("At740Cortesia")
	If ValType(oMdl) == "O"
		oModel		:= oMdl
	Else
		oModel		:= FwModelActive()
	Endif

	If oModel:GetId() $ "TECA740|TECA740F|TECA740A|TECA740B"
		aDtl	 	:= Separa(cDetail,"|")

		If oModel:GetId() $ "TECA740|TECA740F"
			cDetail := aDtl[1]
		Elseif oModel:GetId() $ "TECA740A|TECA740B|TECA740C"
			cDetail := aDtl[2]
		Endif

		oDetail		:= oModel:GetModel(cDetail)
		oStruct 	:= oDetail:GetStruct()

		bWhen := oStruct:GetProperty(cCamp,MODEL_FIELD_WHEN)
		oStruct:SetProperty(cCamp,MODEL_FIELD_WHEN,{|| .T. })
		If cCamp $ "TFF_PERFIM|TFH_PERFIM|TFG_PERFIM|TFI_PERFIM"
			bValid := oStruct:GetProperty(cCamp,MODEL_FIELD_VALID)
			oStruct:SetProperty(cCamp,MODEL_FIELD_VALID,{|| .T. })
		Endif
		
		oDetail:SetValue(cCamp,dDtFim)
		oStruct:SetProperty(cCamp,MODEL_FIELD_WHEN,bWhen)
		If cCamp $ "TFF_PERFIM|TFH_PERFIM|TFG_PERFIM|TFI_PERFIM"
			oStruct:SetProperty(cCamp,MODEL_FIELD_VALID,bValid)
		Endif
	Endif
Endif

Return cCod

//-------------------------------------------------------------------
/*/{Protheus.doc} At740GRec
	Gatilho para inserir as datas nos campos de data fim quando houver registros nas grid's.
@author 	Kaique Schiller
@param 		NIL
@return 	cCod
@since		04/04/2017
@version	P12.1.16
/*/
//------------------------------------------------------------------
Function At740GRec(cCodRec)
Local nX			:= 0
Local nY			:= 0
Local nZ			:= 0
Local nW			:= 0
Local nDias			:= 30
Local aSaveLines	:= {}
Local oModel		:= Nil
Local oView			:= Nil
Local oDtlTFL		:= Nil
Local oDtlTFF		:= Nil
Local oDtlTFG		:= Nil
Local oDtlTFH		:= Nil
Local oDtlTFI		:= Nil

Default cCodRec := "2"

If cCodRec == "1"
	oModel := FwModelActive()
	oView  := FwViewActive()
	If oModel:GetId() $ "TECA740|TECA740F"
		aSaveLines	:= FWSaveRows()
		oDtlTFL		:= oModel:GetModel("TFL_LOC")
		oDtlTFF		:= oModel:GetModel("TFF_RH")
		oDtlTFG		:= oModel:GetModel("TFG_MI")
		oDtlTFH		:= oModel:GetModel("TFH_MC")
		oDtlTFI		:= oModel:GetModel("TFI_LE")
		oDtlTEV		:= oModel:GetModel("TEV_ADICIO")

		For nX := 1 To oDtlTFL:Length()
			If !oDtlTFL:IsEmpty()
				oDtlTFL:GoLine(nX)
				If !(oDtlTFL:IsDeleted())
					At740GatRc(,"TFL_DTFIM","TFL_LOC",oModel)
					For nZ := 1 To oDtlTFF:Length()
						If !oDtlTFF:IsEmpty()
							oDtlTFF:GoLine(nZ)
							At740GatRc(,"TFF_PERFIM","TFF_RH",oModel)
							For nY := 1 To oDtlTFG:Length()
								If !oDtlTFG:IsEmpty()
									oDtlTFG:GoLine(nY)
									If !(oDtlTFG:IsDeleted())
										At740GatRc(,"TFG_PERFIM","TFG_MI",oModel)
									Endif
								Endif
							Next nY
	
							For nY := 1 To oDtlTFH:Length()
								If !oDtlTFH:IsEmpty()
									oDtlTFH:GoLine(nY)
									If !(oDtlTFH:IsDeleted())
										At740GatRc(,"TFH_PERFIM","TFH_MC",oModel)
									Endif
								Endif
							Next nY									
						Endif
					Next nZ
					For nY := 1 To oDtlTFI:Length()
						If !oDtlTFI:IsEmpty()
							oDtlTFI:GoLine(nY)
							nQuant	:= oDtlTFI:GetValue("TFI_QTDVEN")
							At740GatRc(,"TFI_PERFIM","TFI_LE",oModel)
							For nW := 1 To oDtlTEV:Length()
								If !oDtlTEV:IsEmpty() 
									oDtlTEV:GoLine(nW)
									If oDtlTEV:GetValue("TEV_MODCOB") == "2" .And. !(oDtlTEV:IsDeleted())
										oDtlTEV:SetValue("TEV_QTDE",(nQuant*nDias))
									Endif
								Endif
							Next nW
						Endif
					Next nY
				Endif
			Endif
		Next nX
		FWRestRows(aSaveLines)
		If ValType(oView) == "O" .And. oView:GetModel():GetId() $ "TECA740|TECA740F"
			oView:Refresh()
		Endif
	Endif
Endif

Return cCodRec

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740Recor
	Se o contrato não for recorrente retorna .T.

@sample 	At740Recor(cNumCtr)
@param		ExpC1	Codigo do contrato

@author		Kaique Schiller
@since		10/04/2017
@version	P12
/*/
//------------------------------------------------------------------------------
Function At740Recor(cNumCtr)
Local aArea		:= GetArea()
Local lRet		:= .T.
Local cRevis	:= ""
Default cNumCtr := ""

If !Empty(cNumCtr)
	cRevis := Posicione("CN9",7,xFilial("CN9")+cNumCtr+"05","CN9_REVISA")
	DbSelectArea("TFJ")
	TFJ->(DbSetOrder(5)) //TFJ_FILIAL+TFJ_CONTRT+TFJ_CONREV
	If TFJ->(DbSeek(xFilial("TFJ")+cNumCtr+cRevis))
		If TFJ->TFJ_CNTREC == "1"
			lRet := .F.
		Endif
	Endif
Endif

RestArea(aArea)

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740Recor
	Se o contrato for recorrente bloqueia os campos de data fim.

@sample 	At740WhenR()

@author		Kaique Schiller
@since		17/04/2017
@version	P12
/*/
//------------------------------------------------------------------------------
Function At740WhenR()
Local lRet := .T.

If (!IsInCallStack("TECA580B") .And. !IsInCallStack("TECA934") .And. !IsInCallStack("TECA825") .And. !IsInCallStack("FillModel");
	.And. !IsInCallStack("At740Cortesia") .AND. !IsInCallStack("TECA740G")) 
	If ValType(FwFldGet("TFJ_CNTREC")) <> "U" 
		lRet := FwFldGet("TFJ_CNTREC") $ " |2" .Or. IsInCallStack("At740CpyMdl") 
	EndIf
Endif

Return lRet

/*/{Protheus.doc} At740TpVerb
@description 	Função para o gatilho do tipo de verba convertendo entre H, V e D para 1, 2 e 3 respectivamente.
@sample 		At740TpVerb()
@author			josimar.assuncao
@since			30/05/2017
@version		P12
@return 		Caracter, devolve o tipo da verba convertida de H, V e D para 1, 2 e 3.
/*/
Function At740TpVerb()
Local cTpVerba := Posicione("SRV", 1, xFilial("SRV")+M->ABP_VERBA, "RV_TIPO" )
Return At740ConvTp( cTpVerba )

/*/{Protheus.doc} At740ConvTp
@description 	Função para conversão do conteúdo de H, V e D dos tipos de verba para 1, 2 e 3.
@sample 		At740ConvTp( "H" ) ==> "1"
@author			josimar.assuncao
@since			02.06.2017
@version		P12
@param 			cTipoLetra, caracter, tipo da verba como H, V ou D.
@return 		Caracter, devolve o tipo da verba convertida de H, V e D para 1, 2 e 3.
/*/
Function At740ConvTp( cTipoLetra )
Local cRetorno := ""

If cTipoLetra == "H"
	cRetorno := "1"
ElseIf cTipoLetra == "V"
	cRetorno := "2"
ElseIf cTipoLetra == "D"
	cRetorno := "3"
EndIf

Return cRetorno

//-------------------------------------------------------------------
/*/{Protheus.doc} At740F5
Função atribuída à tecla de atalho F5, exibindo detalhes do kit de materiais.
	
@author 	Leandro Dourado - Totvs Ibirapuera
@since		03/10/2016
@version	P12
/*/
//-------------------------------------------------------------------
Function At740F5()
Local aArea     := GetArea()
Local aAreaSB1  := SB1->(GetArea())
Local aAreaTWX  := TWX->(GetArea())
Local oView     := FwViewActive()
Local oModelMat := Nil
Local cCodProd  := ""
Local lKit      := .F.
Local lOrcPrc   := SuperGetMv("MV_ORCPRC",,.F.)
Local aButtons  := {{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.T.,STR0123},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil}} //"Fechar"
Local lExibe    := .F.
Local lMatImp   := .F.
Local lMatCons  := .F.
Local cAba      := ""

Set Key VK_F5 TO

If lOrcPrc
	lExibe   := oView:GetFolderActive("ABAS"   ,2)[1] == 3
	lMatImp  := oView:GetFolderActive("MT_ABAS",2)[1] == 1
	lMatCons := oView:GetFolderActive("MT_ABAS",2)[1] == 2
	cAba     := oView:GetFolderActive("MT_ABAS",2)[2]
Else
	lExibe   := oView:GetFolderActive("ABAS"   ,2)[1] == 2
	lMatImp  := oView:GetFolderActive("RH_ABAS",2)[1] == 1
	lMatCons := oView:GetFolderActive("RH_ABAS",2)[1] == 2
	cAba     := oView:GetFolderActive("RH_ABAS",2)[2]
EndIf

/*/
	Quando estiver posicionado nas abas Material de Implantação e Material de Consumo, dentro da aba Recursos Humanos,
	verificará se o produto posicionado é um kit e exibirá uma tela com todos os seus componentes.
/*/

If lExibe // Recursos Humanos
	If     lMatImp  // Material de Implantação
		oModelMat := oView:GetModel("TFG_MI")
		cCodProd  := oModelMat:GetValue("TFG_PRODUT")
	ElseIf lMatCons // Material de Consumo
		oModelMat := oView:GetModel("TFH_MC")
		cCodProd  := oModelMat:GetValue("TFH_PRODUT")
	EndIf
	
	If !Empty(cCodProd)
		lKit := AllTrim(Posicione("SB1",1,FwxFilial("SB1")+cCodProd,"B1_TIPO")) == "KT"
		If lKit
			DbSelectArea("TWX")
			TWX->(DbSetOrder())
			If TWX->(DbSeek(FwxFilial("TWX")+cCodProd))
				FWExecView(STR0119,"VIEWDEF.TECA892", MODEL_OPERATION_VIEW, /*oDlg*/, {||.T.} /*bCloseOk*/, /*bOk*/,30,aButtons, {||.T.}/*bCancel*/ ) //"Kit de Materiais" 
			Else
				Help( ,, 'Help',, STR0120, 1, 0 ) //"Este produto de tipo kit não possui componentes cadastrados!"
			EndIf
		Else
			Help( ,, 'Help',, STR0121+ AllTrim(cAba) + STR0122, 1, 0 ) //"O produto posicionado na aba '"#####"' não é um kit de material"
		EndIf
	EndIf
EndIf

Set Key VK_F5 TO At740F5()

RestArea( aAreaTWX )
RestArea( aAreaSB1 )
RestArea( aArea )

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} At740RefVl
Gatilho para preenchimento do campo TFF_REFVLR.
Identificar o valor hora do preço de venda e acrescer 50% para o valor do reforço.
@sample		At740RefVl()

@param 		Nil

@return 	.T.

@author 	Ana Maria Utsumi
@since		10/01/2017
@version	P12
/*/
//-------------------------------------------------------------------
Function At740RefVl()
Local oMdlCompleto 	:= FwModelActive()
Local oMdlTFF		:= oMdlCompleto:GetModel("TFF_RH")
Local oMdlTFJ		:= oMdlCompleto:GetModel("TFJ_REFER")
Local oMdlTFL 		:= oMdlCompleto:GetModel("TFL_LOC")
Local nRefVlr		:= 0
Local nContHoras	:= 1
Local nContTurno	:= 1
Local nTotHoras		:= 0
Local nHsPorDia		:= 0
Local nDiasContr	:= 0
Local lRetCalend	:= .F.
Local aTabPadrao	:= {}
Local aTabCalend	:= {}
Local aTurnosSeq 	:= {}
Local dDiaIni 		:= dDataBase
Local dDiaFim 		:= dDataBase
Local aAreaTDX		:= TDX->(GetArea())	
Local aArea			:= GetArea()
Local cReserva		:= ""

If !IsInCallStack("TECA740G") .AND. !IsInCallStack("At740Cortesia") 
	cReserva := Posicione("ABS",1,xFilial("ABS") + oMdlTFL:GetValue("TFL_LOCAL"),"ABS_RESTEC")
EndIf

If oMdlCompleto <> Nil .And. (oMdlCompleto:GetId()=="TECA740" .Or. oMdlCompleto:GetId()=="TECA740F") .AND. cReserva == "2" //NÃO É RESERVA TECNICA

	dDiaIni := oMdlTFF:GetValue("TFF_PERINI")
	dDiaFim := oMdlTFF:GetValue("TFF_PERFIM")
	
	//Se data inicial e final preenchidas, valor unitário preenchido
	If !Empty(dDiaIni) .And. !Empty(dDiaFim)  .And. !Empty(oMdlTFF:GetValue("TFF_PRCVEN"))
		
		//Verifica se contrato recorrente para considerar período de 30 dias para o valor do recurso humano
		If oMdlTFJ:GetValue("TFJ_CNTREC")=="1"
			dDiaFim 	:= oMdlTFF:GetValue("TFF_PERINI")+29
			nDiasContr 	:= 30
		Else
			nDiasContr 	:= (oMdlTFF:GetValue("TFF_PERFIM") - oMdlTFF:GetValue("TFF_PERINI")+1)
		EndIf
		
		If ExistBlock( "PNMTABC01" ) .And. !Empty(oMdlTFF:GetValue("TFF_ESCALA")) 
			//Atribui variável estática _cEscala para usar em função CriaCalend()
			U_PNMSEsc(oMdlTFF:GetValue("TFF_ESCALA"))
			
			//Atribui variável estática _cCalend para usar em função CriaCalend()
			U_PNMSCal(oMdlTFF:GetValue("TFF_CALEND"))  
			
			DbSelectArea('TDX')
			TDX->( DbSetOrder(2)) //TDX_FILIAL+TDX_CODTDX+TDX_TURNO
			TDX->( DbSeek(xFilial("TDX")+oMdlTFF:GetValue("TFF_ESCALA")))
	
			Do While TDX->(!Eof()) .And. TDX->TDX_FILIAL==xFilial("TDX") .And. TDX->TDX_CODTDW==oMdlTFF:GetValue("TFF_ESCALA")  
				AAdd(aTurnosSeq, {TDX->TDX_TURNO, TDX->TDX_SEQTUR})
				TDX->(DbSkip())
			EndDo	
		Else
			AAdd(aTurnosSeq, { oMdlTFF:GetValue("TFF_TURNO"), oMdlTFF:GetValue("TFF_SEQTRN")} )
		EndIf
		
		nTotHoras 	:= 0
	
		//Executa a função CriaCalend para receber o número de horas da escala do período
		For nContTurno :=1 To Len(aTurnosSeq)
			
			Processa( {|lRetCalend| lRetCalend:= CriaCalend(dDiaIni			,;	//01 -> Data Inicial do Periodo
		                           							dDiaFim			,;	//02 -> Data Final do Periodo
		                            						aTurnosSeq[1,1]	,;	//03 -> Turno Para a Montagem do Calendario
		                            						aTurnosSeq[1,2]	,;	//04 -> Sequencia Inicial para a Montagem Calendario
		                            						@aTabPadrao		,;  //05 -> Array Tabela de Horario Padrao
		                            						@aTabCalend		,;  //06 -> Array com o Calendario de Marcacoes  
		                            						xFilial("SRA")	,;  //07 -> Filial para a Montagem da Tabela de Horario
		                            						Nil, Nil );
		              }, STR0082, STR0083,.F.) // "Aguarde..." ### "Executando cálculo ..."
		
			//Soma o total de horas trabalhadas da escala
			For nContHoras := 1 To Len(aTabCalend)
				nTotHoras += aTabCalend[nContHoras,7]
			Next nContHoras
			
		Next nContTurno
		
		//Número de horas por dia
		nHsPorDia 	:= nTotHoras / nDiasContr
			
		//Calcula o valor sugerido de reforço
		If nHsPorDia <> 0	
			nRefVlr := (((oMdlTFF:GetValue("TFF_PRCVEN") / nDiasContr) / nHsPorDia) * 1.5)
		EndIf	
		
		oMdlTFF:SetValue("TFF_REFVLR", nRefVlr)
		
	EndIf

EndIf

RestArea(aAreaTDX)
RestArea(aArea)

Return nRefVlr


/*/{Protheus.doc} At740DtMts
	Valida o preenchimento das datas de materiais.
@since 		14/08/2017
@param 		oModMat, Objeto FwFormGridModel, modelo de dados de algum dos materiais (implantação ou consumo) do orçamento de serviços
@param 		cTab, caracter, tabela a ser validada e que pertence ao modelo
@return 	Lógico, indica se existe prechimento nas tadas, .F. indica não preenchido.
/*/
Static Function At740DtMts( oModMat, cTab )
Local lRet := .T.
Local nK := 0
	
If !IsInCallStack("LoadXmlData")
	For nK := 1 To oModMat:Length()
		oModMat:GoLine(nK)
		If !oModMat:IsDeleted() .And. !Empty(oModMat:GetValue(cTab+'_PRODUT'))
			If Empty(oModMat:GetValue(cTab+"_PERINI"))				
				Help(,,"At740TdOk",,STR0175,1,0,,,,,,{STR0176}) //"A data inicial do período dos materiais de implantação e consumo não pode ser em branco." ## "Preencha o campo"
				lRet := .F.
				Exit
			EndIf
			If lRet .And. Empty(oModMat:GetValue(cTab+"_PERFIM"))
				Help(,,"At740TdOk",,STR0177,1,0,,,,,,{STR0176}) //"A data final do período dos materiais de implantação e consumo não pode ser em branco." ## "Preencha o campo"
				lRet	:= .F.
				Exit
			EndIf
		EndIf
	Next nK
Endif

Return lRet



/*/{Protheus.doc} At740GtPrc
atualiza o campo TFU_VALOR
@author Rodolfo
@since 14/03/2018
@version 1.0
@param nPrc, numérico, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Function At740GtPrc(nPrc)
Local oModel		:= Nil
Local oDetail		:= Nil
Local oStruct 		:= Nil
Local nPrcVen		:= 0
Local oMdl			:= Nil
Local oView 		:= FwViewActive() 	
Local lRet			:= .F.

oModel		:= FwModelActive()
nPrcVen		:= oModel:GetValue('TFF_RH','TFF_PRCVEN')

If oModel:GetId() $ "TECA740|TECA740F|TECA740A|TECA740B"
	If nPrcVen > 0
		oDetail		:= oModel:GetModel("TFU_HE")
		oDetail:LoadValue("TFU_VALOR", nPrcVen * (nPrc/100))
		lRet	:= .T.
		If ValType(oView) == 'O'
			If oView:IsActive()
				oView:Refresh("VIEW_HE")//Atualiza grid para que seja apresentado os valores alterados	
			Endif		
		EndIf	
	Else
		oModel:GetModel():SetErrorMessage(oModel:GetId(),"TFF_PRCVEN",oModel:GetModel():GetId(),	"TFF_PRCVEN",'TFF_PRCVEN',; 
		STR0145, STR0146 )  // "Não existe valor de RH para este recurso humano.", "Verifique o valor de recurso humano"
	EndIf
Endif

Return lRet


/*/{Protheus.doc} At740VlPrc
Zera o campo TFU_PORCEN
@author Rodolfo
@since 19/03/2018
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Function At740VlPrc()
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oModel := FwModelActive()
Local oView := FwViewActive() 	
Local oMdlTFU := oModel:GetModel("TFU_HE")
Local lRet := .T.
			
If oMdlTFU:GetValue('TFU_TPCALC') == '1'
	oMdlTFU:LoadValue('TFU_PORCEN', 0)
EndIf
			
oMdlTFU:LoadValue('TFU_VALOR', 0)			

If ValType(oView) == 'O'			
	If oView:IsActive()
		oView:Refresh("VIEW_HE")//Atualiza grid para que seja apresentado os valores alterados	
	Endif
EndIf

Return lRet


/*/{Protheus.doc} At740AtHe
Função utilizada no gatilho para atualizar o TFU_VALOR
@author Rodolfo
@since 27/03/2018
@version 1.0
@param nPrcVen, numérico, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Function At740AtHe(nPrcVen)
Local aSaveLines	:= FWSaveRows()
Local oModel 		:= FwModelActive()
Local oView 		:= FwViewActive() 	
Local oMdlTFU 		:= oModel:GetModel("TFU_HE")
Local n				:= 0
Local nPrc			:= 0			

If !IsInCallStack("TECA870") .AND. !IsInCallStack("At740Cortesia")
	For n:=1 To oMdlTFU:Length()
		oMdlTFU:GoLine(n)
		If oMdlTFU:GetValue('TFU_TPCALC') == '2' .And. !oMdlTFU:IsDeleted()
			nPrc := oMdlTFU:GetValue('TFU_PORCEN')
			oMdlTFU:LoadValue("TFU_VALOR", nPrcVen * (nPrc/100))
		EndIf								
	Next n	
					
	If oView:IsActive()
		oView:Refresh()//Atualiza grid para que seja apresentado os valores alterados	
	Endif
EndIf	

FWRestRows(aSaveLines)

Return nPrcVen


/*/{Protheus.doc} At740BlVal
Validação do When do campo TFU_VALOR
@author Rodolfo Novaes de Sousa
@since 02/04/2018
@version 1.0
@param oModel, objeto, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Function At740BlVal(oModel)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local lRet	:= .T.

If oModel:GetValue("TFU_VALOR") <> 0 .And.  oModel:GetValue("TFU_TPCALC") == '2'
	lRet	:= .F.
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} A740LibCpo

Validação de liberação de campo.

@author Leandro Fini
@since 03/04/2018
@version 12
/*/
//-------------------------------------------------------------------
Function A740LibCpo(cMat,cOpcao)
//At740Cortesia -> Adicional de item extra.
//cMat = MI -> //Material de Implantação - TFJ_GSMTMI
//cMat = MC -> //Material de Consumo - TFJ_GSMTMC
//cOpcao = "23" -> Material por valor
//cOpcao = "3" -> Material por porcentagem

Local lRet := .F.

If cMat == "MI" 
	If cOpcao == "23" 
		If IsInCallStack("At740Cortesia") 
			If M->TFJ_GSMTMI $ "23"
				lRet := .T.			
			EndIf
		ElseIf FwFldGet("TFJ_GSMTMI") $ "23"
			lRet := .T.			
		EndIf
	ElseIf cOpcao == "3" 
		If IsInCallStack("At740Cortesia")
			If M->TFJ_GSMTMI == "3"
				lRet := .T.			
			EndIf
		ElseIf FwFldGet("TFJ_GSMTMI") == "3"
			lRet := .T.			
		EndIf
	EndIf
ElseIf cMat == "MC" 
	If cOpcao == "23" 
		If IsInCallStack("At740Cortesia") 
			If M->TFJ_GSMTMC $ "23"
				lRet := .T.
			EndIf			
		ElseIf FwFldGet("TFJ_GSMTMC") $ "23"
			lRet := .T.			
		EndIf
	ElseIf cOpcao == "3" 
		If IsInCallStack("At740Cortesia")
			If M->TFJ_GSMTMC == "3"
				lRet := .T.
			EndIf			
		ElseIf FwFldGet("TFJ_GSMTMC") == "3"
			lRet := .T.			
		EndIf
	EndIf
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} A740InitMat

Inicializador padrão do campo TFG_TIPMAT, indicador de cortesia
ou item extra.

@author Leandro Fini
@since 04/04/2018
@version P12
/*/
//-------------------------------------------------------------------

Function A740InitMat(cTipo)
Local oModel		:= FwModelActive()
Local oModelTFG		:= IIF((oModel <> NIL),oModel:GetModel("TFG_MI"), NIL)
Local cRet := "3"
//A740InitMat("TFF")                                                                                                              

If cTipo == "TFG" .OR. cTipo == "TFH" //TFG_TIPMAT ou TFH_TIPMAT
	If IsInCallStack("At870GerOrc")
		cRet := "2" //Item Extra
	ElseIf IsInCallStack("At740Cortesia") 
		If oModelTFG <> NIL .AND. oModelTFG:GetLine() == 0
			cRet := "3"
		Else
			cRet := "1" //Cortesia
		EndIf
		
	Else
		cRet := "3" //Normal
	EndIf
ElseIf cTipo == "TFF" //TFF_TIPORH
	If IsInCallStack("At870GerOrc") .AND. IsInCallStack("At740Cortesia")
		cRet := "2" //Item Extra
	ElseIf IsInCallStack("At740Cortesia") 
		cRet := "1" //Cortesia
	Else
		cRet := "3" //Normal
	EndIf

EndIf

Return cRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At740Num

Função de inicializador padrão de auto numeração com confirmação de gravação

@author Luiz.Jesus
@since 09/04/2018
@version P12
/*/
//-------------------------------------------------------------------

Function At740Num(cAlias, cCampo, nQualndex)

Local aArea  := GetArea()
Local aAreaTmp := (cAlias)->(GetArea())
Local cProxNum
Local cFilter  := (cAlias)->(DbFilter())

Default nQualndex := 1

(cAlias)->(dbClearFilter())
         
cProxNum  := GetSxeNum(cAlias, cCampo,, nQualndex)

dbSelectArea(cAlias)
dbSetOrder(nQualndex)
  
While dbSeek( xFilial( cAlias ) + cProxNum )
 ConfirmSX8()
 cProxNum := GetSx8Num(cAlias, cCampo,, nQualndex)
End

If !Empty(cFilter)
 (cAlias)->(DbSetFilter({||&cFilter},cFilter))
Endif

RestArea(aAreaTmp)
RestArea(aArea)

Return(cProxNum)

//-------------------------------------------------------------------
/*/{Protheus.doc} A740GETOPER

Funçao para retornar a operação do TECA740, para ser usado no
TECA740A, TECA740B, TECA740C

@author Leandro Fini
@since 08/06/2018
@version P12
/*/
//-------------------------------------------------------------------

Function A740GetOper()

Return cOperation


//-------------------------------------------------------------------
/*/{Protheus.doc} At740Pla
Função para carregar TFF em memória antes de chamar a planilha de preço

@author Pâmela Bernardo
@since 09/04/2018
@version P12
/*/
//-------------------------------------------------------------------
Function At740Pla(oModel, oView)
Local aArea		:= GetArea() 
Local aSaveLines:= FWSaveRows()
Local oMdlRh	:= oModel:GetModel("TFF_RH")
Local aCamposTFF:= oMdlRh:GetStruct():GetFields()
Local nX		:= 0
Local cAux		:= ""

If oMdlRh:GetOperation() <> MODEL_OPERATION_VIEW
	RegToMemory("TFF",.F.,.F.)
	For nX:=1 to len(aCamposTFF)
		cAux		:= aCamposTFF[nX][3]
		M->&(cAux) := oMdlRh:GetValue(cAux)
	Next nX
EndIf	
TECA998(oModel,oView)
FWRestRows( aSaveLines )
RestArea(aArea)
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} At740CkNew
Função para verificar se é um item novo na revisão

@param oMdlRev - Modelo de dados anterior
@param nLine - Numero da linha a ser verificado
@param cSubModel - Nome do submodelo que será verificado

@author Luiz Gabriel
@since 03/08/2017
@version P12
/*/
//-------------------------------------------------------------------
Static Function At740CkNew(oMdlRev,nLine,cSubModel,cTab)
Local lRet 	:= .T.
Local oMdlAp	:= Nil

If oMdlRev <> Nil .And. ValType(oMdlRev) == 'O'
	oMdlAp 	:= oMdlRev:GetModel(cSubModel)
	If oMdlAp <> Nil .And. (nLine > 0 .And. oMdlAp:Length() >= nLine)
		oMdlAp:GoLine(nLine)
			cProd 	:= oMdlAp:GetValue(cTab+'_PRODUT')		
			If !Empty(cProd)
				lRet := .F.
			EndIf
	EndIf
EndIf
	

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} A740TotTFL
	
Função para inicializador padrão do total 

@sample 	A740TotTFL()

@since		02/10/2013       
@version	P11.90

@return 	nRet, retorna o resultado do cálculo

/*/
//------------------------------------------------------------------------------

Function A740TotTFL(oMdl)

Local aArea	:= GetArea()
Local oModel	:= If( oMdl == nil, FwModelActive(), oMdl)
Local oMdlLoc	:= nil
Local nTotRh	:= 0
Local nTotLE 	:= 0
Local nTotMI	:= 0
Local nTotMC	:= 0

Local nRet		:= 0

If oModel <> nil .and. oModel:GetID() $ 'TECA740;TECA740F' 
	oMdlLoc	:= oModel:GetModel("TFL_LOC")
	nTotRh		:= oMdlLoc:GetValue("TFL_TOTRH")
	nTotMI		:= oMdlLoc:GetValue("TFL_TOTMI")
	nTotMC		:= oMdlLoc:GetValue("TFL_TOTMC")
	nTotLE		:= oMdlLoc:GetValue("TFL_TOTLE")
	//nTotBE 	:= oMdlLoc:GetValue("TFL_TOTBE")
EndIf

nRet := nTotRh+nTotMI+nTotMC+nTotLE
			
RestArea(aArea)

Return nRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At740WBen
Função para verificar o When dos campos de beneficio

@param oModel - Modelo de dados

@author Luiz Gabriel
@since 04/09/2018
@version P12
/*/
//-------------------------------------------------------------------
Function At740WBen(oModel,cCampo)
Local lRet	:= .F.
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()

If cCampo == "TFF_VLBENE" .and. oModel:GetValue("TFF_TIPORH") <> "1"
	lRet := .T.
EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740ApP
Função de Apuração de Planilha 
@sample 	At740ApP(oModel)
@param		oModel, objeto, modelo MVC
@return	Nenhum
@since		08/10/2018
@author	Serviços
@version	12.1.17
/*/
//------------------------------------------------------------------------------

Static Function At740ApP(oModel)

Default oModel := NIL

If oModel <> NIL
	MsgRun( STR0183, STR0082, { || At740ApG(oModel)} )  //"Apurando automaticamente a planilha#"Aguarde... #
EndIf

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740ApG
Função de Apuração Automática da Planilha
@sample 	At740ApG(oModel)
@param		oModel, objeto, modelo MVC
@return	Nenhu,
@since		08/10/2018
@author	Serviços
@version	12.1.17
/*/
//------------------------------------------------------------------------------
Static Function At740ApG(oModel)
Local oMdlRh		:= oModel:GetModel("TFF_RH")    	//Modelo de Recursos Humanos
Local oMdlTFJ		:= oModel:GetModel("TFJ_REFER") 	//Modelo do cabeçalho do orçamento
Local oMdlLoc		:= oModel:GetModel("TFL_LOC") 		//Modelo dos locais de atendimento
Local nY 			:= 0 									//Contador de Linhas do Model de RH
Local nX			:= 0 									//Contador de Linhas do Local de Atendimento
Local aPlanilha 	:= {} 									//Planilha Retornada
Local cRegCx		:= oMdlTFJ:GetValue("TFJ_RGMCX")
Local cOrcEx		:= oMdlTFJ:GetValue("TFJ_SRVEXT")
Local lReplica	:= oMdlLoc:Length(.T.) > 1 .And. MsgYesNo(STR0184) //"Replicar a execução da Planilha para todos locais de atendimento 

If lReplica
	For nX := 1 To oMdlLoc:Length()
		oMdlLoc:GoLine(nX)
		For nY := 1 To oMdlRh:Length()
			oMdlRh:GoLine(nY)
			If  Empty(oMdlRh:GetValue('TFF_PLACOD') ) .And. Empty(oMdlRh:GetValue('TFF_PLAREV') )
				
				aPlanilha := At740AR(oMdlRh:GetValue('TFF_PRODUT'), oMdlRh:GetValue('TFF_FUNCAO'),oMdlRh:GetValue('TFF_TURNO'),oMdlRh:GetValue('TFF_SEQTRN'), oMdlRh:GetValue('TFF_CARGO'), oMdlRh:GetValue('TFF_ESCALA'),cRegCx, cOrcEx )
				If Len(aPlanilha) > 1
					At998ExPla(aPlanilha[2],oModel,.F., aPlanilha[1], .T.)
				EndIf
			EndIf
		Next nY
	Next nX	
Else
	For nY := 1 To oMdlRh:Length()
		oMdlRh:GoLine(nY)
		If  Empty(oMdlRh:GetValue('TFF_PLACOD') ) .And. Empty(oMdlRh:GetValue('TFF_PLAREV') )
			
			aPlanilha := At740AR(oMdlRh:GetValue('TFF_PRODUT'), oMdlRh:GetValue('TFF_FUNCAO'),oMdlRh:GetValue('TFF_TURNO'),oMdlRh:GetValue('TFF_SEQTRN'), oMdlRh:GetValue('TFF_CARGO'), oMdlRh:GetValue('TFF_ESCALA'),cRegCx, cOrcEx )
			If Len(aPlanilha) > 1
				At998ExPla(aPlanilha[2],oModel,.F., aPlanilha[1], .T.)
			EndIf
		EndIf
	Next nY
EndIf

Return


//------------------------------------------------------------------------------
/*/{Protheus.doc} At740AR
Função de Seleção de Planilha
@sample 	At740AR(cProduto, cFuncao, cTurno, cSeqTrn, cCargo, cEscala)
@param		cProduto, Caractere, Código do Produto
@param		cFuncao, Caractere, Código da Função
@param		cTurno, Caractere, Código do Turno
@param		cSeqTrn, Caractere, Código da Seq do Turno
@param		cCargo, Caractere, Código do Cargo
@param		cEscala, Caractere, Código da Escala
@param		cRegCX, Caractere, Indica se o orçamento é de regime de caixa
@param		cOrcEx, Caractere, Indica se o orçamento é um Serviço Extra
@return	aRetorno, Array, dados da planilha retornada onde
					[1] - XML da Planilha
					[2] - Código da Planilha + Revisão
@since		08/10/2018
@author	Serviços
@version	12.1.17
/*/
//------------------------------------------------------------------------------
Static Function At740AR(cProduto, 	cFuncao, cTurno, cSeqTrn, ;
						 cCargo, 	cEscala, cRegCX, cOrcEx)

Local cPrdVazio 	:= Space(TamSX3("TX8_PRODUT")[1]) 	//Código do Produto Vazio
Local cFuncVazio 	:= Space(TamSX3("TX8_FUNCAO")[1]) 	//Código da Função
Local cTurnVazio 	:= Space(TamSX3("TX8_TURNO")[1]) 	//Turno Vazio
Local cSeqVazio 	:= Space(TamSX3("TX8_SEQTRN")[1]) 	//Sequencia Vazia
Local cCargVazio 	:= Space(TamSX3("TX8_CARGO")[1]) 	//Cargo Vazio
Local cEscVazio 	:= Space(TamSX3("TX8_ESCALA")[1]) 	//Escala Vazia
Local cWhere 		:= "" 									//Filtros da Query
Local cWhere2 	:= "" 									//Expressão temporária
Local cAliasQry 	:= GetNextAlias() 					//Alias da Query
Local aRetorno 	:= {} 									//Retorno da rotina
Local aAreaABW	:= {}

If cRegCX == "1"
	cWhere := "AND TX8.TX8_REGCX = '" + cRegCX  + "'"
EndIf

If cOrcEx == "1"
	cWhere := "AND TX8.TX8_ORCEX = '" + cOrcEx  + "'"
EndIf

cWhere2 := "TX8.TX8_PRODUT = '" +cPrdVazio  + "'"
If !Empty(cProduto)
	cWhere += " AND (TX8.TX8_PRODUT = '" +cProduto  + "' OR "  + cWhere2 + " )"
Else
	cWhere += " AND "  + cWhere2
EndIf

cWhere2 := "TX8.TX8_FUNCAO = '" +cFuncVazio  + "'"
If !Empty(cFuncao)
	cWhere += " AND (TX8.TX8_FUNCAO = '" +cFuncao  + "' OR "  + cWhere2 + " )"
Else
	cWhere += " AND " + cWhere2
EndIf

cWhere2 := "TX8.TX8_TURNO = '" +cTurnVazio  + "'"
If !Empty(cTurno)
	cWhere += " AND (TX8.TX8_TURNO = '" +cTurno  + "' OR "  + cWhere2 + " )"
Else
	cWhere += " AND " + cWhere2
EndIf

cWhere2 := "TX8.TX8_SEQTRN = '" +cSeqVazio  + "'"
If !Empty(cSeqTrn)
	cWhere += " AND (TX8.TX8_SEQTRN = '" +cSeqTrn  + "' OR "  + cWhere2 + " )"
Else
	cWhere += " AND " + cWhere2
EndIf
  
cWhere2 := "TX8.TX8_CARGO = '" +cCargVazio  + "'"
If !Empty(cCargo)
	cWhere += " AND (TX8.TX8_CARGO = '" +cCargo  + "' OR "  + cWhere2 + " )"
Else
	cWhere += " AND " + cWhere2
EndIf

cWhere2 := "TX8.TX8_ESCALA = '" +cEscVazio  + "'"
If !Empty(cEscala)
	cWhere += " AND (TX8.TX8_ESCALA = '" +cEscala  + "' OR "  + cWhere2 + " )"
Else
	cWhere += " AND " + cWhere2
EndIf

cWhere := "%" + cWhere + "%"

BeginSql Alias cAliasQry

	SELECT TX8.TX8_REGCX, TX8.TX8_ORCEX, TX8.TX8_PRODUT, TX8.TX8_FUNCAO, TX8.TX8_TURNO, TX8.TX8_SEQTRN, TX8.TX8_CARGO, TX8.TX8_ESCALA, TX8.TX8_PLANIL, ABW.ABW_REVISA, TX8.TX8_PRIORI
	  FROM %table:TX8% TX8
	       INNER JOIN %table:ABW% ABW ON ABW.ABW_FILIAL  = %xFilial:ABW%
	                                 AND ABW.%NotDel%
	                                 AND ABW.ABW_ULTIMA = '1'
	                                 AND ABW.ABW_CODIGO = TX8.TX8_PLANIL
	 WHERE TX8.TX8_FILIAL = %xFilial:TX8%
	   AND TX8.%NotDel%
	   %exp:cWhere%
	 ORDER BY TX8.TX8_PRIORI ASC
EndSql

If !(cAliasQry)->(Eof())
		aAreaABW := ABW->(GetArea())
		ABW->(DbSetOrder(1)) // ABW_FILIAL+ABW_CODIGO+ABW_REVISA
		If ABW->(DbSeek(xFilial("ABW")+(cAliasQry)->(TX8_PLANIL+ABW_REVISA)))
			aRetorno := {  (cAliasQry)->(TX8_PLANIL+ABW_REVISA), ;
							ABW->ABW_INSTRU }
		EndIf
		RestArea(aAreaABW)
EndIf

(cAliasQry)->(DbCloseArea())

Return aRetorno 

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740LmtFe
Função de validação de limite de cobertura do ferista para a revisão de contratos.
@sample At740LmtFe()
@return	lRet
@since	22/02/2019
@author	Kaique Schiller
/*/
//------------------------------------------------------------------------------
Function At740LmtFe(oMdlVld,cCampo,xValueNew,nLine,xValueOld)
Local lRet 		:= .T.
Local nSldHrF 	:= oMdlVld:GetValue("TFF_SLDHRR")

If IsInCallStack("At870Revis") .And. xValueNew <= nSldHrF
	Help(,, "At740LmtFe",,"Quantidade menor ou igual o saldo de quantidade de coberturas de rota do Almocista/Jantista.",1,0,,,,,,{"Informe o valor maior que "+cValToChar(nSldHrF) })//"Quantidade menor ou igual o saldo de quantidade de coberturas de rota do ferista."#"Informe o valor maior que: "
	lRet := .F.
Endif

Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At740AtVc

Habilita o gatilho do cadastro de produtos
@author Serviços
@since 15/03/2019
@version P12117
@retunr lRet - Campos cadastrados
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At740AtVc()
Local lRet := .F.
Local lGSVinc := SuperGetMv("MV_GSVINC",,.F.) .AND. !SuperGetMv("MV_ORCPRC",,.F.)
Local oModel := NIL

If lGSVinc
	lRet := .T.
	oModel := FWModelActive() //Modelo Ativo
	If RTrim(oModel:GetId()) == "TECA740" //Se for item extra so habilita se for o model do item-extra  
		lRet := !IsInCallStack("At870GerOrc")
	EndIf
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At994InMtE

Valid da escala cadastrada
@author Serviços
@since 15/03/2019
@version P12117
@return .t.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At740InMtE(cPrdMat, cEscala )
Local lRet := .T.

Default cPrdMat := ""
Default cEscala := ""

lRet := Vazio() .OR. ExistCpo("TDW",cEscala)

If lRet
	If !Empty(cPrdMat)
		If !Empty(cEscala) .AND. ExistFunc("At994InsRH")
			//At994InsMat(cPrdMat,.T.)
			If !At994InsRH(cPrdMat,cEscala,2)
				Help(,,"At740Escala",,STR0199,1,0,,,,,,{STR0200})//"Escala não permitida no vinculo de Produto"##"Informe outra escala"
				lRet := .F.
			Else
				At994InsMat(cPrdMat,.T.)
			EndIf
		EndIf
	EndIf	
EndIf

//Verifica se permite a alteração da escala na revisão, se não existe atendentes alocados.
lRet := lRet .And. At740RvEsc()

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At740InTur

Valid do turno cadastrado
@author Serviços
@since 15/03/2019
@version P12117
@return .t.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At740InTur(cPrdMat, cTurno)
Local lRet := .T.

Default cPrdMat := ""
Default cTurno := ""

lRet := Vazio() .OR. ExistCpo('SR6',cTurno)

If lRet
	If !Empty(cPrdMat)
		If !Empty(cTurno) .AND. ExistFunc("At994InsRH")
			If !At994InsRH(cPrdMat,cTurno,3)
				Help(,,"At740Turno",,STR0201,1,0,,,,,,{STR0202})//"Turno não permitido no vinculo de Produto"##"Informe outro Turno"
				lRet := .F.
			EndIf
		EndIf
	EndIf	
EndIf


Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At740InFun

Valid da Função cadastrada
@author Serviços
@since 15/03/2019
@version P12117
@return .t.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At740InFun(cPrdMat,cFuncao)
Local lRet := .T.

Default cPrdMat := ""
Default cFuncao := ""

lRet := Vazio() .OR. ExistCpo('SRJ',cFuncao)

If lRet
	If !Empty(cPrdMat)
		If !Empty(cFuncao) .AND. ExistFunc("At994InsRH")
			If !At994InsRH(cPrdMat,cFuncao,1)
				Help(,,"At740Funcao",,STR0203,1,0,,,,,,{STR0204})//"Função não permitida no vinculo de Produto"##"Informe outra Função"
				lRet := .F.
			EndIf
		EndIf
	EndIf	
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At740Prod

Valid do produto cadastrada
@author Serviços
@since 15/03/2019
@version P12117
@return .t.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At740Prod(oModel,cProd,cTipo)
Local lRet 		:= .T.
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oMdl   		:= FwModelActive()
Local cPrdMat		:= "" //oMdl:GetModel("TFF_RH"):GetValue("TFF_PRODUT")
 
Default cPrdMat 	:= ""
Default cProd 	:= ""
Default cTipo 	:= ""

If IsInCallStack("At740Cortesia") 
	cPrdMat		:= oMdl:GetModel("TFF_GRID"):GetValue("TFF_PRODUT")
Else
	cPrdMat		:=oMdl:GetModel("TFF_RH"):GetValue("TFF_PRODUT")
EndIf

If cTipo == "4"
	lRet := ExistCpo('SB1',cProd) .AND. ExistCpo('SB5',cProd) .And. At740VldPrd(2, cProd)
ElseIf cTipo == "5"
	lRet := ExistCpo('SB1',cProd) .AND. ExistCpo('SB5',cProd) .And. At740VldPrd(3, cProd)
EndIf

If lRet
	If !Empty(cPrdMat)
		If !Empty(cProd) .AND. ExistFunc("At994InsRH")
			If !At994InsRH(cPrdMat,cProd,Val(cTipo))
				Help(,,"At740Prod",,STR0205,1,0,,,,,,{STR0206})//"Produto não permitido no vinculo"##"Informe outro Produto"
				lRet := .F.
			EndIf
		EndIf
	EndIf	
EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740totVrb
	Função para preencher o conteúdo o campo TFF_TOTVRB

@sample 	At740totVrb()

@since		11/04/2019       
@version	P12

/*/
//------------------------------------------------------------------------------
Function At740totVrb()

	Local nValor 	:= 0
	Local oMdl   	:= FwModelActive()
	Local oMdlTFF   := oMdl:GetModel( "TFF_RH" )
	Local oMdlABP   := oMdl:Getmodel("ABP_BENEF")
	Local nx		:= 1
	Local nTamABP	:= oMdlABP:Length()
	Local aSaveRows := FwSaveRows()
	
	If oMdl:GetId()=='TECA740' .Or. oMdl:GetId()=='TECA740F' 
	
		For nx:= 1 to nTamABP
			oMdlABP:Goline(nx)
			If oMdlABP:GetValue( "ABP_BASINS" ) <> "1"
				nValor += oMdlABP:GetValue( "ABP_VALOR" )* oMdlTFF:GetValue( "TFF_QTDVEN" )
			EndIf
		Next 
		
		//Atualiza o total de verba da TFF
		oMdlTFF:SetValue( "TFF_TOTVRB", nValor )
		
	EndIf
	
	FwRestRows(aSaveRows)

Return 0

//------------------------------------------------------------------------------
/*/{Protheus.doc} At740RvEsc
	Função para validar a troca de escala na revisão de contratos.

@sample 	At740RvEsc()
@since		23/05/2019       

/*/
//------------------------------------------------------------------------------
Function At740RvEsc()
Local lRet 		 := .T.
Local cMsgAtends := ""
Local cAliasQry  := ""
Local oMdlRev	 := Nil
Local oMdlRevTFL := Nil
Local oMdlRevTFF := Nil
Local oMdlAntRev := Nil
Local oMdlAntTFL := Nil
Local oMdlAntTFF := Nil
Local nLineTFL	 := 0
Local nLineTFF	 := 0
Local cCodTFF	 := ""
Default cCodTFF	 := ""

//Quando for revisão
If IsInCallStack("At870Revis")

	//Modelo atual da revisão
	oMdlRev    := FwModelActive()
	oMdlRevTFL := oMdlRev:GetModel("TFL_LOC")
	oMdlRevTFF := oMdlRev:GetModel("TFF_RH")
	
	//Modelo original antes da revisão
	oMdlAntRev := GetMdlRev()
	oMdlAntTFL := oMdlAntRev:GetModel("TFL_LOC")
	oMdlAntTFF := oMdlAntRev:GetModel("TFF_RH")
	
	//Linha atual.
	nLineTFL := oMdlRevTFL:GetLine()
	nLineTFF := oMdlRevTFF:GetLine()

	//Posiciona no modelo antigo para pegar o codigo da TFF
	oMdlAntTFL:GoLine(nLineTFL)
	oMdlAntTFF:GoLine(nLineTFF)

	cCodTFF := oMdlAntTFF:GetValue("TFF_COD")
	
	If !Empty(cCodTFF)
		
		cAliasQry := GetNextAlias()

		//Seleciona os atendentes alocados naquele posto
		BeginSql Alias cAliasQry
			SELECT TGY.TGY_ATEND, AA1.AA1_NOMTEC, TGY.TGY_CODTFF
			FROM %table:TGY% TGY
			INNER JOIN %table:AA1% AA1 ON 
				AA1.AA1_FILIAL     = %xFilial:AA1%
				AND AA1.AA1_CODTEC = TGY.TGY_ATEND
				AND AA1.%NotDel%
			WHERE TGY.TGY_FILIAL = %xFilial:TGY%
				AND TGY.TGY_CODTFF = %Exp:cCodTFF%
				AND %Exp:dDataBase% BETWEEN TGY.TGY_DTINI AND TGY.TGY_DTFIM
				AND TGY.%NotDel%
			ORDER BY TGY.TGY_ATEND
		EndSql

		//Preenche a a variavel da menssagem
		While (cAliasQry)->(!Eof())
			cMsgAtends += CRLF+(cAliasQry)->TGY_ATEND+" - "+(cAliasQry)->AA1_NOMTEC
			(cAliasQry)->(dbSkip())
		EndDo
		
		(cAliasQry)->(DbCloseArea())
		
		If !Empty(cMsgAtends)
			Help(,, "At740RvEsc",,"Não é possível alterar a escala.",1,0,,,,,,{"Realize o recolhimento dos atendente(s) : "+cMsgAtends })//"Não é possível alterar a escala."##"Realize o recolhimento dos atendente(s): "
			lRet := .F.
		Endif
	Endif
Endif

Return lRet