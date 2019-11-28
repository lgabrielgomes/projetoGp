#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "GCTXDEF.CH"
#INCLUDE "CNTA121.CH"

// -- Declaração de Variáveis Estáticas
Static oCbx		:= Nil
Static aComp 	:= {}
Static aAdiants	:= {}
Static lSugVal	:= SuperGetMV("MV_CNSUGME",.F.,"1") == "1" //Sugere Valores para Medição
Static lExced 	:= SuperGetMV("MV_CNBTEXC",.F.,"N") == "S" 	//Mostra Excedente
Static lInclui	:= .F.
Static lAltera	:= .F.
Static lEncerra	:= .F.
Static lExcedMEnc := .F.
Static lExcedNPrv := .F.
Static lAutForn	:= .F.
STATIC lMedicao := IsInCallStack("TECA930") .or. IsInCallStack("TECA934") .or. IsInCallStack("TECA934A")
STATIC lGrpFat	:= SuperGetMv("MV_GSGRFAT",,"2")=="1"

//-------------------------------------------------------------------
/*/{Protheus.doc} CNTA121()
Manutenção das Medições
@author José Eulálio
@since 22/07/2015
@version 1.0
@return NIL
/*/
//-------------------------------------------------------------------
Function CNTA121()
Local oBrowse

Private aRotina	:= Menudef()
Private lFixo	:= .F.
Private lMedEve	:= .F.
Private lServico:= .F.
Private cFilCtr := cFilAnt

oBrowse := BrowseDef()
oBrowse:Activate()

FWSetShowKeys(.T.)
SetKey( VK_F12 , Nil )

CN121Limpa()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} BrowseDef()
Browse Definition
@author Flavio Lopes Rasta
@since 05/06/2018
@version 1.0
@return NIL
/*/
//-------------------------------------------------------------------

Static Function BrowseDef()
Local oBrowse
Local aLegenda	:= {}
Local aCNT121LG	:= {}
Local nX		:= 0

oBrowse := FWMBrowse():New()
oBrowse:SetAlias("CND")
oBrowse:SetDescription(STR0001)  //"Medições de Contrato"

//- Definição de Legendas
oBrowse:AddLegend("Alltrim(CND_SITUAC) == 'A'" ,"BR_VERMELHO"	 ,STR0002)// "Medição em Aberto"
oBrowse:AddLegend("Alltrim(CND_SITUAC) == 'B'" ,"BR_PRETO"		 ,STR0003)// "Medição Bloqueada"
oBrowse:AddLegend("Alltrim(CND_SITUAC) == 'R'" ,"BR_CANCEL"		 ,STR0072)// "Medição Rejeitada"
oBrowse:AddLegend("Alltrim(CND_SITUAC) == 'C'" ,"BR_BRANCO"		 ,STR0010)// "Medição Cancelada"
oBrowse:AddLegend("Alltrim(CND_SITUAC) == 'E'" ,"BR_VERDE"		 ,STR0004)// "Medição Encerrada"
oBrowse:AddLegend("Alltrim(CND_SITUAC) == 'FA'","BR_AZUL"		 ,STR0006)// "Aut. Fornec. em Aberto"
oBrowse:AddLegend("Alltrim(CND_SITUAC) == 'FE'","BR_CINZA"		 ,STR0007)// "Aut. Fornec Encerrada"
oBrowse:AddLegend("Alltrim(CND_SITUAC) == 'DT'","BR_VIOLETA"	 ,STR0122)// "Medição Totalmente Devolvida"
oBrowse:AddLegend("Alltrim(CND_SITUAC) == 'DP'","BR_VERDE_ESCURO",STR0123)// "Medição Parcialmente Devolvida"

// Ponto de Entrada para customização da legenda
IF ExistBlock("CNT121LG")
	aCNT121LG := ExecBlock("CNT121LG",.F.,.F.,{aLegenda})
	If ValType(aCNT121LG) == "A"
		aLegenda := aCNT121LG
	EndIf
Endif

For nX := 1 to len(aLegenda)
	oBrowse:AddLegend(aLegenda[nX][1], aLegenda[nX][2], aLegenda[nX][3])
Next nX

//-- Filtra Browse
If ExistBlock("CN121FIL")
	cCn121Fil := ExecBlock("CN121FIL",.F.,.F.)

	If ValType(cCn121Fil) == "C" .And. !Empty(cCn121Fil)
		oBrowse:SetFilterDefault(cCn121Fil)
	EndIf
EndIf

// -- mv_par01 - Mostra Lancamentos   S/N
// -- mv_par02 - Aglut Lancamentos    S/N
SetKey(VK_F12,{|| Pergunte("CNT120",.T.)})

oBrowse:SetCacheView(.F.)
oBrowse:SetMainProc('CNTA121')

Return oBrowse

//-------------------------------------------------------------------
/*/{Protheus.doc} MenuDef()
Definição do Menu
@author José Eulálio
@since 22/07/2015
@version 1.0
@return aRotina
/*/
//-------------------------------------------------------------------
Static Function MenuDef()
Local aExcede 	:= {}
Private aRotina := {} //Array utilizado para controlar opcao selecionada

ADD OPTION aExcede TITLE STR0120 ACTION "CN121Exced(.F.)" OPERATION MODEL_OPERATION_UPDATE ACCESS 13 //Excedentes - Medições encerradas
ADD OPTION aExcede TITLE STR0121 ACTION "CN121ExceC"	  OPERATION MODEL_OPERATION_INSERT ACCESS 14 //Excedentes - Competências não previstas

ADD OPTION aRotina TITLE STR0053 ACTION "CN121Inc"	 		OPERATION MODEL_OPERATION_INSERT ACCESS 0 //"Incluir"
ADD OPTION aRotina TITLE STR0076 ACTION "CN121AutFor"		OPERATION MODEL_OPERATION_INSERT ACCESS 0 //"Aut. Fornecimento"
ADD OPTION aRotina TITLE STR0054 ACTION "CN121Alt"			OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //"Alterar"
ADD OPTION aRotina TITLE STR0055 ACTION "CN121Vis"			OPERATION MODEL_OPERATION_VIEW	 ACCESS 0//"Visualizar"
ADD OPTION aRotina TITLE STR0056 ACTION "CN121Excl"			OPERATION MODEL_OPERATION_DELETE ACCESS 3 //"Excluir"
ADD OPTION aRotina TITLE STR0057 ACTION "CN121Estorn(.F.)"	OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //"Estornar"
ADD OPTION aRotina TITLE STR0058 ACTION "CN121Encerr(.F.)"	OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //"Encerrar"
ADD OPTION aRotina TITLE STR0059 ACTION "MsDocument"		OPERATION MODEL_OPERATION_INSERT ACCESS 0 //"Conheimento"
ADD OPTION aRotina TITLE STR0060 ACTION "CN121Prt"			OPERATION 8 ACCESS 0//'Imprimir'

If lExced
	aAdd(aRotina,{ STR0050, aExcede	, 0, 13, 0, nil}) //Excedente
EndIf

If ExistBlock("CNT121BT")
	ExecBlock("CNT121BT",.F.,.F.)
EndIf

Return aRotina

//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef()
Definicao do Modelo
@author José Eulálio
@since 22/07/2015
@version 1.0
@return oModel
/*/
//-------------------------------------------------------------------
Static Function ModelDef()
Local oModel   		:= Nil
//- Estruturas de Medição
Local oStruCND 		:= FWFormStruct(1,'CND') //Estrutura Cabecalho
Local oStruCXN		:= FWFormStruct(1,'CXN')
Local oStruCNE		:= FWFormStruct(1,'CNE')

//- Estruturas de Consulta Contrato
Local oStruCNU		:= FWFormStruct(1,'CNU')

//- Estruturas de Multas e Bonificações
Local oStruCNR1		:= FWFormStruct(1,'CNR')
Local oStruCNR2		:= FWFormStruct(1,'CNR')
Local oStruCNF		:= FWFormStruct(1,'CNF')
Local oStruCNK		:= FWFormStruct(1,'CNK')
Local oStruCNQ		:= FWFormStruct(1,'CNQ')
Local oStruCZY		:= FWFormStruct(1,'CZY')
Local oStruCNZ		:= FWFormStruct(1,'CNZ')
Local oStruCXI		:= FWFormStruct(1,'CXI')
Local oStruCXJ		:= FWFormStruct(1,'CXJ')
Local oStruSC7		:= FWFormStruct(1,'SC7')
Local oStruSC5		:= FWFormStruct(1,'SC5')
Local oStruSE1		:= FWFormStruct(1,'SE1')
Local oStruSE2		:= FWFormStruct(1,'SE2')
Local oStruCXM		:= FWFormStruct(1,'CXM')
Local oStruCXO		:= If( AliasIndic('CXO') , FWFormStruct(1,'CXO') , Nil )
Local oStruCXP		:= If( AliasIndic('CXP') , FWFormStruct(1,'CXP') , Nil )

Local bVldCalc		:= {|oFldModel| Cn121VldCalc(oFldModel)}
Local bPreCND		:= {|oFieldModel, cAction, cIDField, xValue| CN121CNDPre(oFieldModel, cAction, cIDField, xValue)}
Local bPreVlCXO		:= If( AliasIndic('CXO') , {|oModelGrid,nLine,cAction,cField,xValue,xOldValue| MNatPreCXO("CNTA121",oModelGrid,nLine,cAction,cField,xValue,xOldValue)} , Nil )
Local bPreVlCXP		:= If( AliasIndic('CXP') , {|oModelGrid,nLine,cAction,cField,xValue,xOldValue| MNatPreCXP("CNTA121",oModelGrid,nLine,cAction,cField,xValue,xOldValue)} , NIL )

Local cBuildQtd		:= ""

Local aCamposCXP	:= {"CXP_CC","CXP_CONTA","CXP_ITEMCT","CXP_CLVL"}
Local aCTBEnt		:= CTBEntArr()

Local nX	:= 0

Local lMedHe930		:= IsInCallStack("At930Grv") .and. lMedHE

oStruCND:AddField(STR0061/*Competência*/		,;	// 	[01]  C   Titulo do campo
				 STR0061						,;	// 	[02]  C   ToolTip do campo
				 "CND_RCCOMP"					,;	// 	[03]  C   Id do Field
				 "C"							,;	// 	[04]  C   Tipo do campo
				 3								,;	// 	[05]  N   Tamanho do campo
				 0								,;	// 	[06]  N   Decimal do campo
				 {|a,b,c,d|CN121SetCp(a,b,c,d)}	,;	// 	[07]  B   Code-block de validação do campo
				 NIL							,;	// 	[08]  B   Code-block de validação When do campo
				 {"",""}						,;	//	[09]  A   Lista de valores permitido do campo
				 .F.							,;	//	[10]  L   Indica se o campo tem preenchimento obrigatório
				 NIL							,;	//	[11]  B   Code-block de inicializacao do campo
				 NIL							,;	//	[12]  L   Indica se trata-se de um campo chave
				 .T.							,;	//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
				 .T.							)	// 	[14]  L   Indica se o campo é virtual

//-- Adiciona campos na Estrutura CXN
oStruCXN:AddField(STR0062					,;	// 	[01]  C   Titulo do campo
				 STR0063					,;	// 	[02]  C   ToolTip do campo
				 "CXN_FORCLI"				,;	// 	[03]  C   Id do Field
				 "C"						,;	// 	[04]  C   Tipo do campo
				 Iif(TamSX3("CNA_FORNEC")[1] >= TamSX3("CNA_CLIENT")[1],TamSX3("CNA_FORNEC")[1],	TamSX3("CNA_CLIENT")[1])	,;	// 	[05]  N   Tamanho do campo
				 0							,;	// 	[06]  N   Decimal do campo
				 {|a,b,c|Cn121VldFC(a,b,c)}	,;			// 	[07]  B   Code-block de validação do campo
				 NIL						,;	// 	[08]  B   Code-block de validação When do campo
				 NIL						,;	//	[09]  A   Lista de valores permitido do campo
				 .F.						,;	//	[10]  L   Indica se o campo tem preenchimento obrigatório
				 { || CN121IFC('CLIFOR') }	,;	//	[11]  B   Code-block de inicializacao do campo
				 NIL						,;	//	[12]  L   Indica se trata-se de um campo chave
				 .F.						,;	//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
				 .T.						)	// 	[14]  L   Indica se o campo é virtual

oStruCXN:AddField(STR0064												,;	// 	[01]  C   Titulo do campo
				 STR0065												,;	// 	[02]  C   ToolTip do campo
				 "CXN_LOJA"												,;	// 	[03]  C   Id do Field
				 "C"													,;	// 	[04]  C   Tipo do campo
				 Max(TamSX3("CNA_LJFORN")[1],TamSX3("CNA_LOJACL")[1])	,;	// 	[05]  N   Tamanho do campo
				 0														,;	// 	[06]  N   Decimal do campo
				 {|a,b,c|Cn121VldFC(a,b,c)}								,;	// 	[07]  B   Code-block de validação do campo
				 NIL													,;	// 	[08]  B   Code-block de validação When do campo
				 NIL													,;	//	[09]  A   Lista de valores permitido do campo
				 .F.													,;	//	[10]  L   Indica se o campo tem preenchimento obrigatório
				 { || CN121IFC('LJFORN') }								,;	//	[11]  B   Code-block de inicializacao do campo
				 NIL													,;	//	[12]  L   Indica se trata-se de um campo chave
				 .F.													,;	//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
				 .T.													)	// 	[14]  L   Indica se o campo é virtual

//-- Adiciona campos na Estrutura CNE
oStruCNE:AddField(STR0066										,;	// 	[01]  C   Titulo do campo
				 STR0067										,;	// 	[02]  C   ToolTip do campo
				 "CNE_TES"										,;	// 	[03]  C   Id do Field
				 "C"											,;	// 	[04]  C   Tipo do campo
				 Max(TamSX3("CNE_TE")[1],TamSX3("CNE_TS")[1])	,;	// 	[05]  N   Tamanho do campo
				 0												,;	// 	[06]  N   Decimal do campo
				 {|| CN121VldTES() }							,;	// 	[07]  B   Code-block de validação do campo
				 NIL											,;	// 	[08]  B   Code-block de validação When do campo
				 NIL											,;	//	[09]  A   Lista de valores permitido do campo
				 .F.											,;	//	[10]  L   Indica se o campo tem preenchimento obrigatório
				 {|| CN121IniTES() }							,;	//	[11]  B   Code-block de inicializacao do campo
				 NIL											,;	//	[12]  L   Indica se trata-se de um campo chave
				 .F.											,;	//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
				 .T.											)	// 	[14]  L   Indica se o campo é virtual

oStruCNE:AddField(STR0068					,;	// 	[01]  C   Titulo do campo
				 STR0069					,;	// 	[02]  C   ToolTip do campo
				 "CNE_SDAMED"				,;	// 	[03]  C   Id do Field
				 "N"						,;	// 	[04]  C   Tipo do campo
				 TamSX3("CNE_QTAMED")[1]	,;	// 	[05]  N   Tamanho do campo
				 0							,;	// 	[06]  N   Decimal do campo
				 {|| .T. }					,;	// 	[07]  B   Code-block de validação do campo
				 NIL						,;	// 	[08]  B   Code-block de validação When do campo
				 NIL						,;	//	[09]  A   Lista de valores permitido do campo
				 .F.						,;	//	[10]  L   Indica se o campo tem preenchimento obrigatório
				{|| CN121SldDis() }			,;	//	[11]  B   Code-block de inicializacao do campo
				 NIL						,;	//	[12]  L   Indica se trata-se de um campo chave
				 .T.						,;	//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
				 .T.						)	// 	[14]  L   Indica se o campo é virtual

//-- Adiciona campos na Estrutura SC7
oStruSC7:AddField(STR0070			,;	// 	[01]  C   Titulo do campo
				 STR0070			,;	// 	[02]  C   ToolTip do campo
				 "C7_MEDPED"		,;	// 	[03]  C   Id do Field
				 "C"				,;	// 	[04]  C   Tipo do campo
				 TamSX3("C7_NUM")[1],;	// 	[05]  N   Tamanho do campo
				 0					,;	// 	[06]  N   Decimal do campo
				 NIL				,;	// 	[07]  B   Code-block de validação do campo
				 NIL				,;	// 	[08]  B   Code-block de validação When do campo
				 NIL				,;	//	[09]  A   Lista de valores permitido do campo
				 .F.				,;	//	[10]  L   Indica se o campo tem preenchimento obrigatório
				 {|| Cn121PdNum()}	,;	//	[11]  B   Code-block de inicializacao do campo
				 NIL				,;	//	[12]  L   Indica se trata-se de um campo chave
				 .F.				,;	//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
				 .T.				)	// 	[14]  L   Indica se o campo é virtual
//-- Receber o valor antigo no valid
If lMedHe930 //Permitir valores negativos quando for hora extra
	cBuildQtd := FWBuildFeature( STRUCT_FEATURE_VALID, "FWInitCpo(a,b,c,d),lRet := CN121VldQtd(a,b,c,d) .And. Cn121MultT(),FWCloseCpo(a,b,c,lRet,.T.),lRet")
	oStruCNE:SetProperty("CNE_VLTOT" ,MODEL_FIELD_VALID,FWBuildFeature( STRUCT_FEATURE_VALID, "CN121VlTot().And.cn121MultT()"))
Else
	cBuildQtd := FWBuildFeature( STRUCT_FEATURE_VALID, "FWInitCpo(a,b,c,d),lRet := Positivo() .And. CN121VldQtd(a,b,c,d) .And. Cn121MultT(),FWCloseCpo(a,b,c,lRet,.T.),lRet")
EndIf

oStruCNE:SetProperty("CNE_QUANT" ,MODEL_FIELD_VALID,cBuildQtd)

//-- Gatilho Para Preencher a CNE
oStruCND:AddTrigger('CND_RCCOMP' /*cIdField*/, 'CND_RCCOMP'	/*cTargetIdField*/, {||.T.} /*bPre*/,{||CN121Compet()}/*bSetValue*/ )
oStruCNE:AddTrigger('CNE_PRODUT' /*cIdField*/, 'CNE_TES'	/*cTargetIdField*/, {||.T.} /*bPre*/,{||CN121AtuTes()}/*bSetValue*/ )
oStruCNE:AddTrigger('CNE_TES'	 /*cIdField*/, 'CNE_TES'	/*cTargetIdField*/, {||.T.} /*bPre*/,{||CN121TES()}/*bSetValue*/ )
If cPaisloc == "RUS" 
	oStruCNE:AddTrigger('CNE_OPER'	 /*cIdField*/, 'CNE_TES'	/*cTargetIdField*/, {||.T.} /*bPre*/,{||RUSmtTio(Iif(CN300RetSt("COMPRA",0,oModel:GetModel('CXNDETAIL'):GetValue('CXN_NUMPLA'),oModel:GetModel("CNDMASTER"):GetValue("CND_CONTRA")),1,2),FwFldGet('CNE_OPER'))}/*bSetValue*/ )
	oStruCNE:AddTrigger('CNE_OPER'	 /*cIdField*/, 'CNE_CF'	/*cTargetIdField*/, {||.T.} /*bPre*/,{||RUSmtCd(Iif(CN300RetSt("COMPRA",0,oModel:GetModel('CXNDETAIL'):GetValue('CXN_NUMPLA'),oModel:GetModel("CNDMASTER"):GetValue("CND_CONTRA")),1,2),FwFldGet('CNE_OPER'))}/*bSetValue*/ )
	oStruCNE:AddTrigger('CNE_PRODUT'	 /*cIdField*/, 'CNE_OPER'	/*cTargetIdField*/, {||.T.} /*bPre*/,{||RU09XTIOTrigger()}/*bSetValue*/ ) 
EndIf
oStruCXN:AddTrigger('CXN_FORCLI' /*cIdField*/, 'CXN_LOJA'	/*cTargetIdField*/, {||.T.} /*bPre*/,{|a,b,c|CN121GatFC(a,b,c)}	/*bSetValue*/ )

oStruCND:SetProperty( "CND_MOEDA", MODEL_FIELD_WHEN, {||.F.} )

//-- Cria a estrutura basica
oModel:= MPFormModel():New("CNTA121", /*Pre-Validacao*/,{|oModel|Cn121TudOK(oModel)}/*Pos-Validacao*/,{|| CN121GRV(oModel)}/*Commit*/,/*Cancel*/)

//--	Adiciona o componente de formulario no model
oModel:AddFields("CNDMASTER",/*cOwner*/,oStruCND,bPreCND)

//-- Adiciona Grids e outros Fields Filhos
oModel:AddGrid('CXNDETAIL','CNDMASTER',oStruCXN, { |oModelGrid,  nLine,cAction,  cField, xValue, xOldValue| Cn121CXNPV(oModelGrid, nLine, cAction, cField, xValue, xOldValue) }/*bPreValidacao*/, {|| CN121VldPlan() }/*bPosValidacao*/,/*bCarga*/)
oModel:AddGrid('CNEDETAIL','CXNDETAIL',oStruCNE, { |oModelGrid,  nLine,cAction,  cField, xValue, xOldValue| Cn121CNEPV(oModelGrid, nLine, cAction, cField, xValue, xOldValue) }/*bPreValidacao*/, /*bPosValidacao*/,/*bCarga*/)
oModel:AddGrid('CXMDETAIL','CXNDETAIL',oStruCXM)
oModel:AddGrid('CNUDETAIL','CNDMASTER',oStruCNU)

//- Estrutura das multas, adiantamentos, bonificações e descontos.
oModel:AddGrid('CNRDETAIL1','CXNDETAIL',oStruCNR1,{ |oModelGrid,  nLine,cAction,  cField, xValue, xOldValue| Cn121CNR1(oModelGrid, nLine, cAction, cField, xValue, xOldValue) }/*bPreValidacao*/, /*bPosValidacao*/,/*bCarga*/)
oModel:AddGrid('CNQDETAIL' ,'CXNDETAIL',oStruCNQ, { |oModelGrid,  nLine,cAction,  cField, xValue, xOldValue| Cn121CNQPV(oModelGrid, nLine, cAction, cField, xValue, xOldValue) }/*bPreValidacao*/, /*bPosValidacao*/,/*bCarga*/)
oModel:AddGrid('CNRDETAIL2','CNEDETAIL',oStruCNR2,{ |oModelGrid,  nLine,cAction,  cField, xValue, xOldValue| Cn121CNR2(oModelGrid, nLine, cAction, cField, xValue, xOldValue) }/*bPreValidacao*/, /*bPosValidacao*/,/*bCarga*/)
oModel:AddGrid('CZYDETAIL','CXNDETAIL',oStruCZY)

oModel:AddGrid('CNKDETAIL' ,'CNDMASTER',oStruCNK)
oModel:AddGrid('SC7DETAIL' ,'CNDMASTER',oStruSC7)
oModel:AddGrid('SC5DETAIL' ,'CNDMASTER',oStruSC5)
oModel:AddGrid('SE1DETAIL' ,'CNDMASTER',oStruSE1)
oModel:AddGrid('SE2DETAIL' ,'CNDMASTER',oStruSE2)

oModel:AddGrid('CXIDETAIL' ,'CXNDETAIL',oStruCXI,{ |oModelGrid,  nLine,cAction,  cField, xValue, xOldValue| Cn121CXIPV(oModelGrid, nLine, cAction, cField, xValue, xOldValue) }/*bPreValidacao*/, /*bPosValidacao*/,/*bCarga*/)
oModel:AddGrid('CXJDETAIL' ,'CXNDETAIL',oStruCXJ)

//- Estrutura de Rateio
oModel:AddGrid('CNZDETAIL' ,'CNEDETAIL',oStruCNZ,{ |oModelGrid,  nLine,cAction,  cField, xValue, xOldValue| Cn121CNZPV(oModelGrid, nLine, cAction, cField, xValue, xOldValue) }/*bPreValidacao*/, {|| CN300VldRat(.T.) }/*bPosValidacao*/,/*bCarga*/)

//- Estrutura Multiplas Naturezas
If AliasIndic('CXO')
	oModel:AddGrid('CXODETAIL','CXNDETAIL',oStruCXO,bPreVlCXO,{|oModelGrid| MNatPosCXO(.T.,oModelGrid)})
	oModel:AddGrid('CXPDETAIL','CXODETAIL',oStruCXP,bPreVlCXP,{|oModelGrid| MNatPosCXP(.T.,oModelGrid)})
EndIf

//- Adiciona valor maximo de linhas da grid
oModel:GetModel("CNEDETAIL"):SetMaxLine(99999)

//-Adiciona Totalizadores ao modelo
oModel:AddCalc('TOTMED','CNDMASTER','CXNDETAIL','CXN_VLPREV','CND_VLPREV','FORMULA'	,bVldCalc,,NomeSX3('CND_VLPREV'),{|oModel,nVlrAtu,xValor,lSoma| Cn121VlrTt(oModel,nVlrAtu,xValor,lSoma,'CND_VLPREV')})
oModel:AddCalc('TOTMED','CNDMASTER','CXNDETAIL','CXN_VLLIQD','CND_VLLIQD','FORMULA'	,bVldCalc,,NomeSX3('CND_VLLIQD'),{|oModel,nVlrAtu,xValor,lSoma| Cn121VlrTt(oModel,nVlrAtu,xValor,lSoma,'CND_VLLIQD')})
oModel:AddCalc('TOTMED','CNDMASTER','CXNDETAIL','CXN_VLMULT','CND_VLMULT','FORMULA'	,bVldCalc,,NomeSX3('CND_VLMULT'),{|oModel,nVlrAtu,xValor,lSoma| Cn121VlrTt(oModel,nVlrAtu,xValor,lSoma,'CND_VLMULT')})
oModel:AddCalc('TOTMED','CNDMASTER','CXNDETAIL','CXN_VLBONI','CND_VLBONI','FORMULA'	,bVldCalc,,NomeSX3('CND_VLBONI'),{|oModel,nVlrAtu,xValor,lSoma| Cn121VlrTt(oModel,nVlrAtu,xValor,lSoma,'CND_VLBONI')})
oModel:AddCalc('TOTMED','CNDMASTER','CXNDETAIL','CXN_VLDESC','CND_DESCME','FORMULA'	,bVldCalc,,NomeSX3('CND_DESCME'),{|oModel,nVlrAtu,xValor,lSoma| Cn121VlrTt(oModel,nVlrAtu,xValor,lSoma,'CND_DESCME')})
oModel:AddCalc('TOTMED','CNDMASTER','CXNDETAIL','CXN_VLRADI','CND_TOTADT','FORMULA'	,bVldCalc,,NomeSX3('CND_TOTADT'),{|oModel,nVlrAtu,xValor,lSoma| Cn121VlrTt(oModel,nVlrAtu,xValor,lSoma,'CND_TOTADT')})
oModel:AddCalc('TOTMED','CNDMASTER','CXNDETAIL','CXN_VLTOT' ,'CND_RETCAC','FORMULA'	,bVldCalc,,NomeSX3('CND_RETCAC'),{|oModel,nVlrAtu,xValor,lSoma| Cn121VlrMd(oModel,nVlrAtu,xValor,lSoma,'CND_RETCAC')})
oModel:AddCalc('TOTMED','CNDMASTER','CXNDETAIL','CXN_VLTOT' ,'CND_VLTOT' ,'FORMULA'	,bVldCalc,,NomeSX3('CND_VLTOT' ),{|oModel,nVlrAtu,xValor,lSoma| Cn121VlrMd(oModel,nVlrAtu,xValor,lSoma,'CND_VLTOT' )})

//-- Seta relacao entre os grids
oModel:SetRelation('CXNDETAIL', {{'CXN_FILIAL','xFilial("CXN")'},{'CXN_CONTRA','CND_CONTRA'},{'CXN_REVISA','CND_REVISA'},{'CXN_NUMMED','CND_NUMMED'}},CXN->(IndexKey(1)))
oModel:SetRelation('CNEDETAIL', {{'CNE_FILIAL','xFilial("CNE")'},{'CNE_CONTRA','CND_CONTRA'},{'CNE_REVISA','CND_REVISA'},{'CNE_NUMERO','CXN_NUMPLA'},{'CNE_NUMMED','CND_NUMMED'}},CNE->(IndexKey(1)))
oModel:SetRelation('CNQDETAIL', {{'CNQ_FILIAL','xFilial("CNQ")'},{'CNQ_CONTRA','CND_CONTRA'},{'CNQ_NUMMED','CND_NUMMED'},{'CNQ_NUMPLA','CXN_NUMPLA'}},CNQ->(IndexKey(3)))
oModel:SetRelation('CNUDETAIL', {{'CNU_FILIAL','xFilial("CNU")'},{'CNU_CONTRA','CND_CONTRA'}},CNU->(IndexKey(1)))
oModel:SetRelation('CXMDETAIL', {{'CXM_FILIAL','xFilial("CXM")'},{'CXM_CONTRA','CND_CONTRA'},{'CXM_REVISA','CND_REVISA'},{'CXM_NUMERO','CXN_NUMPLA'}},CXM->(IndexKey(1)))
oModel:SetRelation('CNKDETAIL', {{'CNK_FILIAL','xFilial("CNK")'},{'CNK_CONTRA','CND_CONTRA'}},CNK->(IndexKey(3)))
oModel:SetRelation('CNRDETAIL1',{{'CNR_FILIAL','xFilial("CNR")'},{'CNR_CONTRA','CXN_CONTRA'},{'CNR_NUMMED','CND_NUMMED'},{'CNR_CODPLA','CXN_NUMPLA'},{'CNR_ITEM','Space(TamSX3("CNE_ITEM")[1])'}},CNR->(IndexKey(3))) //CNR_FILIAL+CNR_CONTRA+CNR_NUMMED+CNR_CODPLA+CNR_ITEM
oModel:SetRelation('CNRDETAIL2',{{'CNR_FILIAL','xFilial("CNR")'},{'CNR_CONTRA','CXN_CONTRA'},{'CNR_NUMMED','CND_NUMMED'},{'CNR_CODPLA','CXN_NUMPLA'},{'CNR_ITEM','CNE_ITEM'}},CNR->(IndexKey(3)))
oModel:SetRelation('CNZDETAIL', {{'CNZ_FILIAL','xFilial("CNE")'},{'CNZ_CONTRA','CND_CONTRA'},{'CNZ_REVISA','CND_REVISA'},{'CNZ_NUMMED','CND_NUMMED'},{'CNZ_CODPLA','CXN_NUMPLA'},{'CNZ_FORNEC','CXN_FORNEC'},{'CNZ_LJFORN','CXN_LJFORN'},{'CNZ_CLIENT','CXN_CLIENT'},{'CNZ_LOJACL','CXN_LJCLI'},{'CNZ_ITCONT','CNE_ITEM'}},CNZ->(IndexKey(5)))
oModel:SetRelation('CXIDETAIL', {{'CXI_FILIAL','xFilial("CXI")'},{'CXI_CONTRA','CND_CONTRA'},{'CXI_REVISA','CND_REVISA'},{"CXI_NUMPLA","CXN_NUMPLA"}},CXI->(IndexKey(1)))
oModel:SetRelation('CXJDETAIL', {{'CXJ_FILIAL','xFilial("CXJ")'},{'CXJ_CONTRA','CND_CONTRA'}/*,{'CXJ_REVISA','CND_REVISA'}*/,{"CXJ_NUMPLA","CXN_NUMPLA"},{"CXJ_NUMMED","CND_NUMMED"}},CXJ->(IndexKey(1)))
oModel:SetRelation('CZYDETAIL', {{'CZY_FILIAL','CND_FILIAL'},{'CZY_CONTRA','CND_CONTRA'},{'CZY_REVISA','CND_REVISA'},{'CZY_NUMMED','CND_NUMMED'},{"CZY_NUMPLA","CXN_NUMPLA"}},CZY->(IndexKey(2)))

oModel:SetRelation('SC7DETAIL',{{'C7_FILIAL','xFilial("SC7")'},{'C7_CONTRA' ,'CND_CONTRA'},{"C7_MEDICAO","CND_NUMMED"}},SC7->(IndexKey(1)))
oModel:SetRelation('SC5DETAIL',{{'C5_FILIAL','xFilial("SC5")'},{'C5_MDCONTR','CND_CONTRA'},{"C5_MDNUMED","CND_NUMMED"}},SC5->(IndexKey(1)))
oModel:SetRelation('SE1DETAIL',{{'E1_FILIAL','xFilial("SE1")'},{'E1_MDCONTR','CND_CONTRA'},{'E1_MDREVIS','CND_REVISA'},{'E1_MEDNUME','CND_NUMMED'}},SE1->(IndexKey(1)))

If !SE2->(Columnpos('E2_MEDNUME'))
	oModel:SetRelation('SE2DETAIL',{{'E2_FILIAL','xFilial("SE2")'},{'E2_MDCONTR','CND_CONTRA'},{'E2_MDREVIS','CND_REVISA'},{'E2_ORIGEM','"CNTA121"'}},SE2->(IndexKey(1)))
Else
	oModel:SetRelation('SE2DETAIL',{{'E2_FILIAL','xFilial("SE2")'},{'E2_MDCONTR','CND_CONTRA'},{'E2_MDREVIS','CND_REVISA'},{'E2_MEDNUME','CND_NUMMED'}},SE2->(IndexKey(1)))
EndIf

If AliasIndic('CXO')
	
	oModel:SetRelation('CXODETAIL', {{'CXO_FILIAL','xFilial("CXO")'},{'CXO_CONTRA','CND_CONTRA'},{'CXO_REVISA','CND_REVISA'},{'CXO_NUMMED','CND_NUMMED'},{'CXO_NUMPLA','CXN_NUMPLA'}},CXO->(IndexKey(1)))
	oModel:SetRelation('CXPDETAIL', {{'CXP_FILIAL','xFilial("CXP")'},{'CXP_CONTRA','CND_CONTRA'},{'CXP_REVISA','CND_REVISA'},{'CXP_NUMMED','CND_NUMMED'},{'CXP_NUMPLA','CXN_NUMPLA'},{'CXP_ITMNAT','CXO_ITEM'}},CXP->(IndexKey(1)))

	oModel:GetModel('CXODETAIL'):SetUniqueLine({"CXO_NATURE"})
	
	For nX := 1 To Len(aCTBEnt)
		If CXP->(FieldPos("CXP_EC" +aCTBEnt[nX] +"CR")) > 0
			aAdd(aCamposCXP,"CXP_EC" +aCTBEnt[nX] +"CR")
			aAdd(aCamposCXP,"CXP_EC" +aCTBEnt[nX] +"DB")
		EndIf
	Next nX
	
	oModel:GetModel('CXPDETAIL'):SetUniqueLine(aCamposCXP)
EndIF

//-- Configura o model
oModel:SetPrimaryKey( {} ) //Obrigatorio setar a chave primaria (mesmo que vazia)
oModel:GetModel( 'CNZDETAIL' ):SetUniqueLine( { 'CNZ_CONTRA', 'CNZ_REVISA', 'CNZ_CODPLA', 'CNZ_NUMMED', 'CNZ_ITCONT', 'CNZ_ITEM' } )

//-- Ativa Modelo somente para visualização
oModel:GetModel('CXMDETAIL'):SetOnlyQuery(.T.)
oModel:GetModel('CNKDETAIL'):SetOnlyQuery(.T.)
oModel:GetModel('CXIDETAIL'):SetOnlyQuery(.T.)
oModel:GetModel('CNUDETAIL'):SetOnlyQuery(.T.)
oModel:GetModel('SC5DETAIL'):SetOnlyQuery(.T.)
oModel:GetModel('SC7DETAIL'):SetOnlyQuery(.T.)
oModel:GetModel('SE1DETAIL'):SetOnlyQuery(.T.)
oModel:GetModel('SE2DETAIL'):SetOnlyQuery(.T.)
oModel:GetModel('CZYDETAIL'):SetOnlyQuery(.T.)

//Modelos de Preenchimento Não Obrigatorio
oModel:GetModel('CXMDETAIL'):SetOptional(.T.)
oModel:GetModel('CNEDETAIL'):SetOptional(.T.)
oModel:GetModel('CNKDETAIL'):SetOptional(.T.)
oModel:GetModel('CNQDETAIL'):SetOptional(.T.)
oModel:GetModel('CNRDETAIL1'):SetOptional(.T.)
oModel:GetModel('CNRDETAIL2'):SetOptional(.T.)
oModel:GetModel('CNZDETAIL'):SetOptional(.T.)
oModel:GetModel('CXIDETAIL'):SetOptional(.T.)
oModel:GetModel('CXJDETAIL'):SetOptional(.T.)
oModel:GetModel('SC5DETAIL'):SetOptional(.T.)
oModel:GetModel('SC7DETAIL'):SetOptional(.T.)
oModel:GetModel('SE1DETAIL'):SetOptional(.T.)
oModel:GetModel('SE2DETAIL'):SetOptional(.T.)
oModel:GetModel('CNUDETAIL'):SetOptional(.T.)
oModel:GetModel('CZYDETAIL'):SetOptional(.T.)

If AliasIndic('CXO')
	oModel:GetModel('CXODETAIL'):SetOptional(.T.)
	oModel:GetModel('CXPDETAIL'):SetOptional(.T.)
EndIf

//-- Desabilita alteracoes nas grids que são somente leitura
CNTA300BlMd(oModel:GetModel('CNKDETAIL'),.T.)
CNTA300BlMd(oModel:GetModel('SE1DETAIL'),.T.)
CNTA300BlMd(oModel:GetModel('SE2DETAIL'),.T.)
CNTA300BlMd(oModel:GetModel('SC7DETAIL'),.T.)
CNTA300BlMd(oModel:GetModel('SC5DETAIL'),.T.)
CNTA300BlMd(oModel:GetModel('CXIDETAIL'),.T.)

If lExced .And. lExcedMEnc
	CNTA300BlMd(oModel:GetModel("CXNDETAIL"),.T.)
	CNTA300BlMd(oModel:GetModel("CNEDETAIL"),.T.)
	CNTA300BlMd(oModel:GetModel("CNRDETAIL1"),.T.)
	CNTA300BlMd(oModel:GetModel("CNQDETAIL"),.T.)
	CNTA300BlMd(oModel:GetModel("CNRDETAIL2"),.T.)
EndIf

//-- Define as chaves unicas.
oModel:GetModel('CNQDETAIL'):SetUniqueLine({"CNQ_TPDESC"})

oModel:SetVldActivate({|oModel| CN121VlAct(oModel)})
oModel:SetActivate({|oModel| CN121Act(oModel)})

oModel:SetOnDemand(.T.)

Return oModel

//--------------------------------------------------------------------
/*/{Protheus.doc} ViewDef()
Definicao da View
@author Jose Eulalio
@since 27/07/2015
@version 1.0
@return oView
/*/
//--------------------------------------------------------------------
Static Function ViewDef()
Local oModel   	:= FWLoadModel( "CNTA121" )	 //Carrega model definido

//- Listagem de campos para cada modelo (Finalizar string com '|')
Local cCampoCND := CNDViewCpo()
Local cCampoCNE := "CNE_FILIAL|CNE_CONTRA|CNE_REVISA|CNE_NUMMED|CNE_NUMERO|CNE_TIPO|CNE_DTANIV|CNE_ITSOMA|CNE_QTRETI|CNE_PEDIDO|CNE_TS|CNE_TE|CNE_FLGCMS|CNE_QTDORI|CNE_VUNORI|CNE_CRONOG|CNE_QTAMED|CNE_15ANOS|CNE_20ANOS|CNE_25ANOS|CNE_TPSERV|"
Local cCampoCNR := "CNR_NUMMED|CNR_CONTRA|CNR_CODIGO|CNR_CODPLA|CNR_ITEM|"
Local cCampoCNQ := "CNQ_FILIAL|CNQ_CONTRA|CNQ_NUMMED|CNQ_NUMPLA|"
Local cCampoCNZ := "CNZ_CONTRA|CNZ_REVISA|CNZ_ITCONT|CNZ_CODPLA|CNZ_NUMMED|CNZ_FORNEC|CNZ_LJFORN|CNZ_CLIENT|CNZ_LOJACL|"
Local cCampoCNX := "CXN_CONTRA|CXN_REVISA|CXN_NUMMED|CXN_CRONCT|CXN_DTMXMD|CXN_VLCOMS|"
Local cCampoCXI	:= "CXI_CONTRA|CXI_REVISA|CXI_NUMPLA|CXI_ITEM|"
Local cCampoSC5 := "C5_FILIAL|C5_MDCONTR|C5_MDNUMED|"
Local cCampoSC7 := "C7_FILIAL|C7_CONTRA|C7_CONTREV|C7_MEDICAO|"
Local cCampoSE1 := "E1_FILIAL|E1_MDCONTR|E1_MDREVIS|E1_MEDNUME|"
Local cCampoSE2 := "E2_FILIAL|E2_MDCONTR|E1_MDREVIS|E2_MEDNUME|"
Local cCampoCXO := "CXO_CONTRA|CXO_NUMMED|CXO_REVISA|CXO_NUMPLA|"
Local cCampoCXP := "CXP_CONTRA|CXP_NUMMED|CXP_REVISA|CXP_NUMPLA|CXP_ITMNAT|"

//- Preparação de estruturas da View
Local oStruCND	:= FWFormStruct(2,'CND', {|cCampo|  AllTrim(cCampo)+'|' $ cCampoCND})
Local oStruCND2 := FWCalcStruct(oModel:GetModel('TOTMED'))

Local oStruCNE	:= FWFormStruct(2,'CNE', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCNE})
Local oStruCNK	:= FWFormStruct(2,'CNK')
Local oStruCNR1	:= FWFormStruct(2,'CNR', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCNR})
Local oStruCNR2	:= FWFormStruct(2,'CNR', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCNR})
Local oStruCNQ	:= FWFormStruct(2,'CNQ', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCNQ})
Local oStruCNZ	:= FWFormStruct(2,'CNZ', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCNZ})
Local oStruCXN	:= FWFormStruct(2,'CXN', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCNX})
Local oStruCXI	:= FWFormStruct(2,'CXI', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCXI})
Local oStruSC5	:= FWFormStruct(2,'SC5', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoSC5})
Local oStruSC7	:= FWFormStruct(2,'SC7', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoSC7})
Local oStruSE1	:= FWFormStruct(2,'SE1', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoSE1})
Local oStruSE2	:= FWFormStruct(2,'SE2', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoSE2})
Local oStruCXO	:= If( AliasIndic('CXO') , FWFormStruct(2,'CXO', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCXO}) , Nil )
Local oStruCXP	:= If( AliasIndic('CXP') , FWFormStruct(2,'CXP', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCXP}) , Nil )

Local oView		:= FWFormView():New()
Local lCompra	:= CN121RetSt( "COMPRA", 0,, CND->CND_CONTRA, .F. )
Local lMultNat	:= SuperGetMv('MV_MULNATP',.F.,.F.) .Or. SuperGetMv('MV_MULNATR',.F.,.F.)

oStruCND:AddField("CND_RCCOMP"	,;	// [01]  C   Nome do Campo
				"06"			,;	// [02]  C   Ordem
				STR0061 		,;	// [03]  C   Titulo do campo
				STR0061			,;	// [04]  C   Descricao do campo
				NIL				,;	// [05]  A   Array com Help
				"C"				,;	// [06]  C   Tipo do campo
				"@!"			,;	// [07]  C   Picture
				NIL				,;	// [08]  B   Bloco de Picture Var
				NIL				,;	// [09]  C   Consulta F3
				.T.				,;	// [10]  L   Indica se o campo é alteravel
				NIL				,;	// [11]  C   Pasta do campo
				NIL				,;	// [12]  C   Agrupamento do campo
				{"",""}			,;	// [13]  A   Lista de valores permitido do campo (Combo)
				NIL				,;	// [14]  N   Tamanho maximo da maior opção do combo
				NIL				,;	// [15]  C   Inicializador de Browse
				.T.				,;	// [16]  L   Indica se o campo é virtual
				NIL				,;	// [17]  C   Picture Variavel
				NIL				)	// [18]  L   Indica pulo de linha após o campo

oStruCXN:AddField("CXN_FORCLI"	,;	// [01]  C   Nome do Campo
				"14"			,;	// [02]  C   Ordem
				STR0062			,;	// [03]  C   Titulo do campo
				STR0063			,;	// [04]  C   Descricao do campo
				NIL				,;	// [05]  A   Array com Help
				"C"				,;	// [06]  C   Tipo do campo
				"@!"			,;	// [07]  C   Picture
				NIL				,;	// [08]  B   Bloco de Picture Var
				"CNC001"		,;	// [09]  C   Consulta F3
				.T.				,;	// [10]  L   Indica se o campo é alteravel
				NIL				,;	// [11]  C   Pasta do campo
				NIL				,;	// [12]  C   Agrupamento do campo
				NIL				,;	// [13]  A   Lista de valores permitido do campo (Combo)
				NIL				,;	// [14]  N   Tamanho maximo da maior opção do combo
				NIL				,;	// [15]  C   Inicializador de Browse
				.T.				,;	// [16]  L   Indica se o campo é virtual
				NIL				,;	// [17]  C   Picture Variavel
				NIL				)	// [18]  L   Indica pulo de linha após o campo

oStruCXN:AddField("CXN_LOJA"	,;	// [01]  C   Nome do Campo
				"15"			,;	// [02]  C   Ordem
				STR0064 		,;	// [03]  C   Titulo do campo
				STR0065			,;	// [04]  C   Descricao do campo
				NIL				,;	// [05]  A   Array com Help
				"C"				,;	// [06]  C   Tipo do campo
				"@!"			,;	// [07]  C   Picture
				NIL				,;	// [08]  B   Bloco de Picture Var
				NIL				,;	// [09]  C   Consulta F3
				.T.				,;	// [10]  L   Indica se o campo é alteravel
				NIL				,;	// [11]  C   Pasta do campo
				NIL				,;	// [12]  C   Agrupamento do campo
				NIL				,;	// [13]  A   Lista de valores permitido do campo (Combo)
				NIL				,;	// [14]  N   Tamanho maximo da maior opção do combo
				NIL				,;	// [15]  C   Inicializador de Browse
				.T.				,;	// [16]  L   Indica se o campo é virtual
				NIL				,;	// [17]  C   Picture Variavel
				NIL				)	// [18]  L   Indica pulo de linha após o campo

oStruCNE:AddField('CNE_TES'	,;	// [01]  C   Nome do Campo
				'15'		,;	// [02]  C   Ordem
				STR0066		,;	// [03]  C   Titulo do campo
				STR0067		,;	// [04]  C   Descricao do campo
				NIL			,;	// [05]  A   Array com Help
				'C'			,;	// [06]  C   Tipo do campo
				'@!'		,;	// [07]  C   Picture
				NIL			,;	// [08]  B   Bloco de Picture Var
				'SF4'		,;	// [09]  C   Consulta F3
				.T.			,;	// [10]  L   Indica se o campo é alteravel
				NIL			,;	// [11]  C   Pasta do campo
				NIL			,;	// [12]  C   Agrupamento do campo
				NIL			,;	// [13]  A   Lista de valores permitido do campo (Combo)
				NIL			,;	// [14]  N   Tamanho maximo da maior opção do combo
				NIL			,;	// [15]  C   Inicializador de Browse
				.T.			,;	// [16]  L   Indica se o campo é virtual
				NIL			,;	// [17]  C   Picture Variavel
				NIL			)	// [18]  L   Indica pulo de linha após o campo

oStruCNE:AddField("CNE_SDAMED"			,;	// [01]  C   Nome do Campo
				"07"					,;	// [02]  C   Ordem
				STR0068 				,;	// [03]  C   Titulo do campo
				STR0069					,;	// [04]  C   Descricao do campo
				NIL						,;	// [05]  A   Array com Help
				'N'						,;	// [06]  C   Tipo do campo
				'@E 9,999,999.99999999'	,;	// [07]  C   Picture
				NIL						,;	// [08]  B   Bloco de Picture Var
				NIL						,;	// [09]  C   Consulta F3
				.F.						,;	// [10]  L   Indica se o campo é alteravel
				NIL						,;	// [11]  C   Pasta do campo
				NIL						,;	// [12]  C   Agrupamento do campo
				NIL						,;	// [13]  A   Lista de valores permitido do campo (Combo)
				NIL						,;	// [14]  N   Tamanho maximo da maior opção do combo
				NIL						,;	// [15]  C   Inicializador de Browse
				.T.						,;	// [16]  L   Indica se o campo é virtual
				NIL						,;	// [17]  C   Picture Variavel
				NIL						)	// [18]  L   Indica pulo de linha após o campo

oStruSC7:AddField('C7_MEDPED'	,;	// [01]  C   Nome do Campo
				'01'			,;	// [02]  C   Ordem
				STR0070			,;	// [03]  C   Titulo do campo
				STR0071			,;	// [04]  C   Descricao do campo
				NIL				,;	// [05]  A   Array com Help
				'C'				,;	// [06]  C   Tipo do campo
				'@!'			,;	// [07]  C   Picture
				NIL				,;	// [08]  B   Bloco de Picture Var
				NIL				,;	// [09]  C   Consulta F3
				.F.				,;	// [10]  L   Indica se o campo é alteravel
				NIL				,;	// [11]  C   Pasta do campo
				NIL				,;	// [12]  C   Agrupamento do campo
				NIL				,;	// [13]  A   Lista de valores permitido do campo (Combo)
				NIL				,;	// [14]  N   Tamanho maximo da maior opção do combo
				NIL				,;	// [15]  C   Inicializador de Browse
				.T.				,;	// [16]  L   Indica se o campo é virtual
				NIL				,;	// [17]  C   Picture Variavel
				NIL				)	// [18]  L   Indica pulo de linha após o campo

oStruCXN:SetProperty( "CXN_DTINI", MVC_VIEW_ORDEM, "12" )
oStruCXN:SetProperty( "CXN_DTFIM", MVC_VIEW_ORDEM, "13" )

//-- Associa o View ao Model
oView:SetModel(oModel)  //-- Define qual o modelo de dados será utilizado

//-- Insere os componentes na View
oView:AddField('VIEW_CND'	,oStruCND	,'CNDMASTER')   //Cabecalho
oView:AddField('VIEW_CND2'	,oStruCND2	,'TOTMED')
oView:AddGrid('VIEW_CXN'	,oStruCXN	,'CXNDETAIL')
oView:AddGrid('VIEW_CNE'	,oStruCNE	,'CNEDETAIL')

oView:AddGrid('VIEW_CNK'	,oStruCNK	,'CNKDETAIL')
oView:AddGrid('VIEW_CNR1'	,oStruCNR1	,'CNRDETAIL1')
oView:AddGrid('VIEW_CNQ'	,oStruCNQ	,'CNQDETAIL')
oView:AddGrid('VIEW_CNR2'	,oStruCNR2	,'CNRDETAIL2')
oView:AddGrid('VIEW_CNZ'	,oStruCNZ	,'CNZDETAIL')
//oView:AddGrid('VIEW_CXI'	,oStruCXI	,'CXIDETAIL')

If !lInclui
	If lCompra
		oView:AddGrid('VIEW_SC7',oStruSC7,'SC7DETAIL')
		oView:AddGrid('VIEW_SE2',oStruSE2,'SE2DETAIL')
	Else
		oView:AddGrid('VIEW_SC5',oStruSC5,'SC5DETAIL')
		oView:AddGrid('VIEW_SE1',oStruSE1,'SE1DETAIL')
	EndIf
EndIf

//-- Cria os Box's
oView:CreateHorizontalBox("CABEC",30) //Cabeçalho
oView:CreateHorizontalBox("PLANI",70) //Planilhas

//-- Cria a pasta e planilhas da Manutencao de Contratos
oView:CreateFolder('FLDCND','CABEC')
oView:CreateFolder('FLDCXN','PLANI')

oView:AddSheet('FLDCND','GRDCABEC',STR0129) //- Medições
oView:CreateHorizontalBox('MEDICAO' ,100,/*owner*/,/*lUsePixel*/,'FLDCND','GRDCABEC')

oView:AddSheet('FLDCND','GRDTOTMD',STR0130) //- Totais
oView:CreateHorizontalBox('TOTMD' ,100,/*owner*/,/*lUsePixel*/,'FLDCND','GRDTOTMD')

oView:AddSheet('FLDCXN','GRDPLAN',STR0131) //- Planilhas
oView:CreateHorizontalBox('PLANILHA' ,40,/*owner*/,/*lUsePixel*/,'FLDCXN','GRDPLAN')
oView:CreateHorizontalBox('ITENS' ,60,/*owner*/,/*lUsePixel*/,'FLDCXN','GRDPLAN')
oView:CreateFolder('FLDCNE','ITENS')

oView:AddSheet('FLDCXN','GRDMULT1',STR0132) //- Multas/Bonif. da Planilha
oView:CreateHorizontalBox('MULTAS1' ,100,/*owner*/,/*lUsePixel*/,'FLDCXN','GRDMULT1')

oView:AddSheet('FLDCXN','GRDDESC',STR0133) //- Descontos
oView:CreateHorizontalBox('DESCONTOS',100,/*owner*/,/*lUsePixel*/,'FLDCXN','GRDDESC')
//oView:AddSheet('FLDCXN','GRDPART','Partes Envolvidas')
//oView:CreateHorizontalBox('PTENV' ,100,/*owner*/,/*lUsePixel*/,'FLDCXN','GRDPART')

If !Inclui
	oView:AddSheet('FLDCXN','GRDPEDS',STR0134) //- Pedidos
	oView:CreateHorizontalBox('PTPED' ,100,/*owner*/,/*lUsePixel*/,'FLDCXN','GRDPEDS')
	oView:AddSheet('FLDCXN','GRDTITS',STR0135) //- Titulos
	oView:CreateHorizontalBox('TITS' ,100,/*owner*/,/*lUsePixel*/,'FLDCXN','GRDTITS')
EndIf

oView:AddSheet('FLDCXN','GRDDOCS',STR0136) //- Documentos
oView:CreateHorizontalBox('DOCS' ,100,/*owner*/,/*lUsePixel*/,'FLDCXN','GRDDOCS')

oView:AddSheet('FLDCNE','GRDITENS',STR0137) //- Itens
oView:CreateHorizontalBox('GITENS' ,100,/*owner*/,/*lUsePixel*/,'FLDCNE','GRDITENS')

oView:AddSheet('FLDCNE','GRDRATEIO',STR0138) //- Rateio Contabil
oView:CreateHorizontalBox('RATEIO' ,100,/*owner*/,/*lUsePixel*/,'FLDCNE','GRDRATEIO')

oView:AddSheet('FLDCNE','GRDMULT2',STR0139) //- Multas/Bonif. do Item
oView:CreateHorizontalBox('MULTAS2' ,100,/*owner*/,/*lUsePixel*/,'FLDCNE','GRDMULT2')

If lMultNat .And. AliasIndic('CXO')
	oView:AddGrid('VIEW_CXO',oStruCXO,'CXODETAIL')
	oView:AddGrid('VIEW_CXP',oStruCXP,'CXPDETAIL')
	
	oView:AddSheet('FLDCXN','ABANTM',STR0165) 		//"Naturezas Multiplas"
	oView:CreateHorizontalBox('GRDNTM',40,/*owner*/,/*lUsePixel*/,'FLDCXN','ABANTM')
	oView:CreateHorizontalBox('GRDCCM',60,/*owner*/,/*lUsePixel*/,'FLDCXN','ABANTM')
	oView:SetOwnerView('VIEW_CXO','GRDNTM')
	oView:SetOwnerView('VIEW_CXP','GRDCCM')
	
	oView:AddIncrementField('VIEW_CXO','CXO_ITEM')
	oView:AddIncrementField('VIEW_CXP','CXP_ITEM')
EndIf

//-- Associa os componentes as pastas
oView:SetOwnerView("VIEW_CND"	,"MEDICAO")
oView:SetOwnerView("VIEW_CND2"	,"TOTMD")
oView:SetOwnerView("VIEW_CXN"	,"PLANILHA")
oView:SetOwnerView("VIEW_CNK"	, "DOCS")
oView:SetOwnerView("VIEW_CNR1"	,"MULTAS1")
oView:SetOwnerView("VIEW_CNQ" 	,"DESCONTOS")
oView:SetOwnerView("VIEW_CNE"	,"GITENS")
oView:SetOwnerView("VIEW_CNR2"	,"MULTAS2")
oView:SetOwnerView("VIEW_CNZ"	, "RATEIO")
//oView:SetOwnerView("VIEW_CXI"	, "PTENV")

If !lInclui
	If lCompra
		oView:SetOwnerView("VIEW_SE2"	,"TITS")
		oView:SetOwnerView("VIEW_SC7"	,"PTPED")
	Else
		oView:SetOwnerView("VIEW_SE1"	,"TITS")
		oView:SetOwnerView("VIEW_SC5"	,"PTPED")
	EndIf
EndIf

//Substituindo o Campo competencia
If lInclui .Or. lExcedNPrv
	oStruCND:RemoveField("CND_COMPET")
	oStruCXN:RemoveField("CXN_FORNEC")
	oStruCXN:RemoveField("CXN_LJFORN")
	oStruCXN:RemoveField("CXN_CLIENT")
	oStruCXN:RemoveField("CXN_LJCLI")
Else
	oStruCND:RemoveField("CND_RCCOMP")
	oStruCXN:RemoveField("CXN_FORCLI")
	oStruCXN:RemoveField("CXN_LOJA")
	If lCompra
		oStruCXN:RemoveField("CXN_CLIENT")
		oStruCXN:RemoveField("CXN_LJCLI")
	Else
		oStruCXN:RemoveField("CXN_FORNEC")
		oStruCXN:RemoveField("CXN_LJFORN")
	EndIf
EndIf

If (Iif(Type("lServico")=='L',lServico,.F.))
	oStruCNE:RemoveField("CNE_QTDORI")
	oStruCNE:RemoveField("CNE_VUNORI")
EndIf

oStruCND:SetProperty('CND_CONTRA', MVC_VIEW_CANCHANGE, .T.)

If !(INCLUI .Or. ALTERA)
	oView:AddUserButton(STR0073,'BUDGET', {|| a120Posic("CND",CND->(Recno()),2,"IM",.F.)}) //"Log de Aprovação"
	oView:AddUserButton('Tracker','BUDGET', {|| Cn121Track(oModel)}) //"Tracker"
EndIf

oView:AddUserButton(STR0074,'BUDGET', {|| CN121VFoCl(lCompra,oModel:GetValue('CXNDETAIL','CXN_FORCLI'),oModel:GetValue('CXNDETAIL','CXN_LOJA'))})	//- "Visualizar Forn./Cliente"
oView:AddUserButton(STR0163,'BUDGET', {|| CN121RatP(oModel) })	//- "Rateio Pré-Configurado"

If CNE->(Columnpos('CNE_15ANOS'))
	oView:AddUserButton(STR0166,'BUDGET', {|| CNReinf(oModel) })
EndIf

If INCLUI .Or. ALTERA
	oView:AddUserButton(STR0075,'BUDGET', {|| CN121SeAdi(oModel)})	//- "Sel. Adiatamentos"
EndIf

oView:SetViewProperty( 'CNRDETAIL1', "CHANGELINE", {{ |oView, cViewID| Cn121ChgLn(oView, cViewID,.T.) }} )
oView:SetViewProperty( 'CNRDETAIL2', "CHANGELINE", {{ |oView, cViewID| Cn121ChgLn(oView, cViewID,.F.) }} )
oView:SetViewProperty( 'CXNDETAIL' , "CHANGELINE", {{ |oView, cViewID| Cn121ChgPl( ,, oView:getModel() ) }} )

//- Adiciona campos Incrementais.
oView:AddIncrementField('VIEW_CNE','CNE_ITEM')
oView:AddIncrementField('VIEW_CNZ','CNZ_ITEM')

//PE C121VCPO para manipular campos na View
If ExistBlock("C121VCPO")
	ExecBlock("C121VCPO",.F.,.F.,{@oStruCND, @oStruCXN, @oStruCNE})
EndIf

Return oView

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121MedSer()
Função para identificação de Medições de Serviços.
@author israel.escorizza
@since 11/08/2015
@version 1.0
@Return FwExecView
/*/
//-------------------------------------------------------------------
Function CN121MedSer()
	lServico := .T.
Return FWExecView(STR0077,"CNTA121",MODEL_OPERATION_INSERT,,{|| .T.})//""Medição de Serviços""

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121MedSer()
Função para identificação de Autorização de Fornecimento.
@author israel.escorizza
@since 11/08/2015
@version 1.0
@Return FwExecView
/*/
//-------------------------------------------------------------------
Function CN121AutFor()
lAutForn := .T.
lInclui  := .T.
aComp	 := {}

FWExecView(STR0076,"CNTA121",MODEL_OPERATION_INSERT,,{|| .T.})//"Aut. Fornecimento"

lAutForn := .F.
lInclui  := .F.
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121Cbox()
Rotina para "transformar" o objeto Competências em ComboBox e
Carregar as Competências das Planilhas dos Contratos
@author miguel.santos
@since 23/07/2015
@version P12.1.7
/*/
//-------------------------------------------------------------------
Function CN121Cbox(aCompets,aCompSemN,cFilCTR)
Local oModel		:= FWModelActive()
Local oView			:= FWViewActive()
Local oModelStruct	:= NIL
Local lExistObj		:= .F.
Local lAuto			:= IsBlind()
Local lView	:= ValType(oView) == "O"

If !lAuto .And. lView
	lExistObj := oView:IsActive() .And. oView:GetModel():GetId() $ "CNTA121" 
Else
	lExistObj := .T.
EndIf

If lExistObj
	oModelStruct := oModel:GetModel('CNDMASTER'):GetStruct()

	//-- correção para permitir chamada da CNTA121 pela rotina automática CNTA260
	oModelStruct:SetProperty("CND_RCCOMP", MODEL_FIELD_VALUES,aCompSemN)

	//Tratativa para quando executar via robô, selecionar a primeira competência disponivel
	If lAuto .Or. !lView
		oModel:GetModel("CNDMASTER"):SetValue("CND_RCCOMP", Substr(aCompets[1], 1, 1))
	Else
		oView:SetFieldProperty("CNDMASTER","CND_RCCOMP","COMBOVALUES",{aCompets}) 
	EndIf

	aComp := aClone(aCompets)
Else
	aComp := aClone(aCompets)
Endif

CN121SetCp(oModel:GetModel('CNDMASTER'),,,,cFilCTR,!lExistObj) 

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121Carga()
Carrega formulário da CND com valores do contrato da CN9
@author israel.escorizza
@since 11/08/2015
@version P12
/*/
//--------------------------------------------------------------------
Function Cn121Carga(cContra,cRev,lAuto)
Local aSaveLines	:= FwSaveRows()
Local aArea			:= GetArea()
Local oModel 	:= FWModelActive()
Local oView		:= FWViewActive()
Local oModelCND	:= NIL
Local cFilCTR   := ""
Local cFilCN9	:= ""

Default cContra := ""
Default cRev	:= ""
Default lAuto	:= .F.

If ValType(oModel) == "O"
	oModelCND	:= oModel:GetModel("CNDMASTER")
	IIf (Empty(cContra), cContra := oModelCND:GetValue("CND_CONTRA"),)
	IIf (Empty(cRev), 	cRev 	 := oModelCND:GetValue("CND_REVISA"),)
	cFilCTR := oModelCND:GetValue("CND_FILCTR")
EndIf

If Empty(cFilCTR)
	cFilCTR := cFilAnt
EndIf

cFilCN9	:= xFilial( "CN9", cFilCTR )
CN9->(dbSetOrder(1)) //- CN9_FILIAL+CN9_NUMERO+CN9_REVISA
If CN9->(MsSeek(cFilCN9+cContra+cRev))
	oModelCND:SetValue("CND_FILIAL",cFilCN9)
	oModelCND:LoadValue("CND_MOEDA",CN9->CN9_MOEDA)
	oModelCND:SetValue("CND_CONDPG",CN9->CN9_CONDPG)
	oModelCND:SetValue("CND_VLCONT",CN9->CN9_VLATU )
	oModelCND:SetValue("CND_VLADIT",CN9->CN9_VLADIT)
	oModelCND:SetValue("CND_VLREAJ",CN9->CN9_VLREAJ)
	oModelCND:SetValue("CND_REVGER",CN9->CN9_REVISA)
	oModelCND:SetValue("CND_FILCTR",CN9->CN9_FILCTR)
	oModelCND:SetValue("CND_SERVIC",IIf(A121Servico(1),'2','1'))
	
	If CND->( ColumnPos( "CND_TXMOED" ) ) > 0
		oModelCND:LoadValue("CND_TXMOED",0)
	EndIf

	oModelCND:GetStruct():SetProperty("CND_APROV",MODEL_FIELD_WHEN,{||.T.})
	oModelCND:LoadValue("CND_APROV" ,CN9->CN9_GRPAPR)

	If cPaisLoc == 'RUS'
		oModelCND:SetValue("CND_CONUNI" ,CN9->CN9_CONUNI )
	EndIf

	If !Empty(oModelCND:GetValue("CND_APROV"))
		oModelCND:GetStruct():SetProperty("CND_APROV",MODEL_FIELD_WHEN,{||.F.})
	EndIf
EndIf

RestArea(aArea)
FWRestRows( aSaveLines )
Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} CnCNDTotVl()
Função para calculo do Total da planilha

@author israel.escorizza
@since 26/08/2015
@version P12
@return .T.
/*/
//--------------------------------------------------------------------
Function CnCNDTotVl()
Local lRet		:= .T.
Local oModel	:= FwModelActive()
Local oView		:= FwViewActive()
Local oModelCND	:= oModel:GetModel('CNDMASTER')
Local nMod		:= IIf(Cn121RetSt('COMPRA',0,,oModelCND:GetValue('CND_CONTRA')),1,-1)
Local nVlPrev	:= oModelCND:GetValue('CND_VLLIQD')
Local nVlDesc	:= oModelCND:GetValue('CND_DESCME')
Local nVlMult	:= oModelCND:GetValue('CND_VLMULT')
Local nVlBoni	:= oModelCND:GetValue('CND_VLBONI')
Local nVlAdit	:= oModelCND:GetValue('CND_TOTADT')
Local nTotal	:= nVlPrev - nVlDesc - nVlAdit + (nMod * (nVlBoni  - nVlMult))
Local nRetCac	:= CN121RetCa( nTotal, oModel )
Local cCurrView := ""
Local cCurrFild	:= ""
Local lAuto		:= IsBlind()

If !lAuto .And. ValType(oView) == 'O'
	cCurrView := oView:GetCurrent()[1]
	cCurrFild	:= oView:GetCurrent()[2]
EndIf

oModelCND:GetStruct():SetProperty('CND_VLTOT',MODEL_FIELD_WHEN,{||.T.})
oModelCND:SetValue('CND_VLTOT',Max(nTotal-nRetCac,0))
oModelCND:GetStruct():SetProperty('CND_VLTOT',MODEL_FIELD_WHEN,{||.F.})

If nRetCac > 0
	oModelCND:GetStruct():SetProperty("CND_RETCAC",MODEL_FIELD_WHEN,{||.T.})
	oModelCND:SetValue("CND_RETCAC",nRetCac)
	oModelCND:GetStruct():SetProperty("CND_RETCAC",MODEL_FIELD_WHEN,{||.F.})
Else
	oModelCND:GetStruct():SetProperty("CND_RETCAC",MODEL_FIELD_WHEN,{||.T.})
	oModelCND:SetValue("CND_RETCAC",0)
	oModelCND:GetStruct():SetProperty("CND_RETCAC",MODEL_FIELD_WHEN,{||.F.})
EndIf

If ValType(oView) == "O" .And. oView:GetModel():GetId() == "CNTA121"
	oView:Refresh('VIEW_CND2')
EndIf

Return lRet
//-------------------------------------------------------------------
/*/{Protheus.doc} CnCXNTotVl()
Função para calculo do Total da planilha

@author israel.escorizza
@since 26/08/2015
@version P12
@return .T.
/*/
//--------------------------------------------------------------------
Function CnCXNTotVl()
Local lRet		:= .T.
Local oModel 	:= FwModelActive()
Local oModelCXN	:= oModel:GetModel('CXNDETAIL')
Local nMod		:= Iif(Cn121RetSt('COMPRA',0,oModelCXN:GetValue('CXN_NUMPLA')),1,-1)
Local nVlLiqd	:= oModelCXN:GetValue('CXN_VLLIQD')
Local nVlDesc	:= oModelCXN:GetValue('CXN_VLDESC')
Local nVlMult	:= oModelCXN:GetValue('CXN_VLMULT')
Local nVlBoni	:= oModelCXN:GetValue('CXN_VLBONI')
Local nTotal 	:= nVlLiqd + (nMod * (nVlBoni - nVlMult)) - nVlDesc
Local cAtuFld	:= 'CXN_VLTOT'

oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.T.})
oModelCXN:SetValue(cAtuFld,Max(nTotal,0))
oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.F.})

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121CXNPV()
Pré-valid da CXN (Planilha da Medição)

@author israel.escorizza
@since 26/08/2015
@version P12
@return .T.
/*/
//--------------------------------------------------------------------
Function Cn121CXNPV(oModelCXN, nLine, cAction, cField, xValue, xOldValue)
Local lRet		:= .T.
Local lChk		:= .F.
Local lChange 	:= .F.
Local lValidCmp := SuperGetMV("MV_CNPLCPT",.F.,.T.)
Local nX		:= 0
Local nTotal	:= 0
Local cAtuFld 	:= ""
Local cVlrFld	:= ""
Local cDataIni	:= ""
Local cDataCpt	:= ""
Local aCampos	:= {}
Local cChave	:= ""
Local oModel	:= NIL
Local oModelCND := NIL
Local oModelCXO	:= NIL
Local oModelCXP	:= NIL

DO CASE
	CASE cAction == 'CANSETVALUE'
		oModel		:= oModelCXN:GetModel()
		oModelCND	:= oModel:GetModel('CNDMASTER')

		If cField == 'CXN_CHECK'
			If Empty(oModelCND:GetValue('CND_CONTRA')) .Or. (Empty(oModelCND:GetValue('CND_RCCOMP')) .And. Empty(oModelCND:GetValue('CND_COMPET')))
				lRet	:= .F.
			ElseIf lValidCmp
				cDataIni	:= SubStr(DtoC(oModelCXN:GetValue('CXN_DTINI')),7)+SubStr(DtoC(oModelCXN:GetValue('CXN_DTINI')),4,2)
				cDataCpt	:= SubStr(oModelCND:GetValue('CND_COMPET'),4)+SubStr(oModelCND:GetValue('CND_COMPET'),1,2)

				//- Valida data de inicio da planilha maior do que competência.
				If  cDataIni > cDataCpt
					Help(" ",1,"CN121CMPPL") //- "Não é possivel selecionar esta planilha pois sua data inicial posterior a competência selecionada."
					If !IsBlind()
						MsgAlert(STR0078)//"Não é possivel selecionar esta planilha pois sua data inicial é posterior a competência selecionada."
					EndIf
					lRet := .F.
				EndIf
			EndIf
		ElseIf(cField == 'CXN_PARCEL')
			lRet := (!oModelCXN:GetValue("CXN_CHECK") .And. oModelCXN:GetOperation() == MODEL_OPERATION_INSERT )			
			If(!Empty(oModelCXN:GetValue("CXN_PARCEL")))
				cChave := xFilial("CNF") + oModelCXN:GetValue("CXN_CRONOG")
				cChave += oModelCXN:GetValue("CXN_CONTRA") + oModelCXN:GetValue("CXN_REVISA")			
				CNF->(DbSetOrder(1)) //CNF_FILIAL+CNF_NUMERO+CNF_CONTRA+CNF_REVISA			
				//CXN_PARCEL eh editavel apenas quando tiver cronograma, for uma inclusao e nao estiver marcado(check)
				lRet := lRet .And. CNF->(DbSeek(cChave))				
			EndIf
		Else
			lRet := oModelCXN:GetValue("CXN_CHECK")
		EndIf

	CASE cAction == 'SETVALUE'
		DO CASE			
			CASE cField == 'CXN_CHECK'
				If lRet := Cn121VldChk(oModelCXN,cField,xValue,nLine,xOldValue)
					lChk := .T.
					aCampos := {{'CXN_VLPREV','CND_VLPREV'},{'CXN_VLLIQD','CND_VLLIQD'},{'CXN_VLMULT','CND_VLMULT'},{'CXN_VLBONI','CND_VLBONI'},;
								{'CXN_VLDESC','CND_DESCME'},{'CXN_VLRADI','CND_TOTADT'}}
								
					If AliasIndic('CXO')
						oModelCXO := oModelCXN:GetModel():GetModel('CXODETAIL')
						oModelCXP := oModelCXN:GetModel():GetModel('CXPDETAIL')
						If xValue .And. CnGatMNat()
							CNTA300BlMd(oModelCXO,.F.)
							CNTA300BlMd(oModelCXP,.F.)
						Else
							CNTA300BlMd(oModelCXO,.T.)
							CNTA300BlMd(oModelCXP,.T.)
						EndIf
					EndIf
				EndIf
		ENDCASE

		If !Empty(cAtuFld)
			oModel		:= oModelCXN:GetModel()
			oModelCND	:= oModel:GetModel('CNDMASTER')

			If oModelCXN:GetValue('CXN_CHECK') .OR. IsInCallStack('CN121Grid')
				nTotal := oModelCND:GetValue(cAtuFld)
				nTotal += (xValue - xOldValue)
				oModelCND:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.T.})
				oModelCND:SetValue(cAtuFld,nTotal)
				oModelCND:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.F.})
				lChange := .T.
			EndIf
		EndIf

		If lChk //- Delete ou Undelete
			oModel		:= oModelCXN:GetModel()
			oModelCND	:= oModel:GetModel('CNDMASTER')

			nMod := Iif(xValue,1,-1) //- Caso Ativado soma no total, caso desativado, subtrai

			For nX := 1 To Len(aCampos)
				cVlrFld := aCampos[nX][1]
				cAtuFld := aCampos[nX][2]

				nTotal := oModelCND:GetValue(cAtuFld)
				nTotal += (oModelCXN:GetValue(cVlrFld) * nMod)
				oModelCND:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.T.})
				oModelCND:SetValue(cAtuFld,nTotal)
				oModelCND:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.F.})
			Next nX
		EndIf
ENDCASE

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121CNEPV()
Pré-valid da CNE (Itens da Planilha da Medição)

@author israel.escorizza
@since 26/08/2015
@version P12
@return .T.
/*/
//--------------------------------------------------------------------
Function Cn121CNEPV(oModelCNE, nLine, cAction, cField, xValue, xOldValue)
Local oModel 		:= Nil
Local oModelCXN 	:= Nil
Local aCampos		:= {}
Local cAtuFld 		:= ""
Local cRmvFld 		:= ""
Local cAddFld 		:= ""
Local lRet			:= .T.
Local nTotal 		:= 0
Local nX			:= 0
Local nMod			:= 1
Local aBlkCpo		:= {}
Local aProp			:= {}
Local nTamDec		:= 0

DO CASE
	CASE cAction == 'CANSETVALUE'
		oModel := oModelCNE:GetModel()
		oModelCXN := oModel:GetModel("CXNDETAIL")
		
		If !oModelCXN:GetValue("CXN_CHECK") .And. !IsInCallStack('Cn121Item')
			lRet:= .F.
		EndIf

		If IsExced()
			If !oModelCNE:IsInserted() .And. !lExcedNPrv
				MtBCMod(oModel,{'CNEDETAIL'},{||.F.},'1') //- Bloqueia todos os campos
			Else
				aAdd(aBlkCpo,'CNE_PRODUT')
				aAdd(aBlkCpo,'CNE_DESCRI')
				aAdd(aBlkCpo,'CNE_QUANT')
				aAdd(aBlkCpo,'CNE_VLUNIT')
				aAdd(aBlkCpo,'CNE_TES')
				aAdd(aBlkCpo,'CNE_TS')
				If cPaisLoc == "RUS"
					aAdd(aBlkCpo,'CNE_CF') 
				EndIf
				aAdd(aBlkCpo,'CNE_PERC')
				aAdd(aBlkCpo,'CNE_VLTOT')
				aAdd(aBlkCpo,'CNE_TABPRC')
				MtBCMod(oModel,{{'CNEDETAIL',aBlkCpo}},{||.T.},'2')
			EndIf
		EndIf

	CASE cAction == 'SETVALUE'
		oModel := oModelCNE:GetModel()
		oModelCXN := oModel:GetModel("CXNDETAIL")
		
		DO CASE
			CASE cField == 'CNE_VLTOT'
				cAtuFld := 'CXN_VLLIQD'
			CASE cField == 'CNE_VLDESC'
				cAtuFld := 'CXN_VLLIQD'
				nMod	:= -1
			CASE cField == 'CNE_MULTA'
				cAtuFld := 'CXN_VLMULT'
			CASE cField == 'CNE_BONIF'
				cAtuFld := 'CXN_VLBONI'
		ENDCASE

		If lRet .And. !Empty(cAtuFld)
			nTamDec := GetSx3Cache( cField, "X3_DECIMAL" )
			nTotal := oModelCXN:GetValue(cAtuFld)
			nTotal += ( Round(xValue,nTamDec) - Round(xOldValue,nTamDec) ) * nMod

			aProp := GetPropMdl(oModelCXN)
			CNTA300BlMd(oModelCXN,,.T.)

			oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.T.})
			oModelCXN:SetValue(cAtuFld,nTotal)
			oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.F.})

			RstPropMdl(oModelCXN,aProp)
		EndIf

	CASE cAction == 'DELETE'
		oModel := oModelCNE:GetModel()
		oModelCXN := oModel:GetModel("CXNDETAIL")
		
		aCampos :={{'CNE_VLTOT','CXN_VLLIQD'},{'CNE_MULTA','CXN_VLMULT'},{'CNE_BONIF','CXN_VLBONI'},{'CNE_VLDESC','CXN_VLDESC'}}

		If !Empty(oModelCNE:GetValue("CNE_PRODUT"))
			For nX := 1 To Len(aCampos)
				cAtuFld := aCampos[nX][2]
				cRmvFld := aCampos[nX][1]

				nTotal := oModelCXN:GetValue(cAtuFld)
				nTotal -= oModelCNE:GetValue(cRmvFld)
				oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.T.})
				oModelCXN:SetValue(cAtuFld,nTotal)
				oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.F.})
			Next nX

			If !Empty(oModelCNE:GetValue("CNE_ITEMGR"))
				lRet := CN121VlAgr(oModelCNE:GetValue("CNE_PRODUT"),0,oModelCNE:GetValue("CNE_QUANT"))
			EndIf
		EndIf

	CASE cAction == 'UNDELETE'					
		If !IsExced()
			oModel := oModelCNE:GetModel()
			oModelCXN := oModel:GetModel("CXNDETAIL")
		
			aCampos :={{'CNE_VLTOT','CXN_VLLIQD'},{'CNE_MULTA','CXN_VLMULT'},{'CNE_BONIF','CXN_VLBONI'},{'CNE_VLDESC','CXN_VLDESC'}}

			For nX := 1 To Len(aCampos)
				cAtuFld := aCampos[nX][2]
				cAddFld := aCampos[nX][1]

				nTotal := oModelCXN:GetValue(cAtuFld)
				nTotal += oModelCNE:GetValue(cAddFld)
				oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.T.})
				oModelCXN:SetValue(cAtuFld,nTotal)
				oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.F.})
			Next nX

			If !Empty(oModelCNE:GetValue("CNE_ITEMGR"))
				lRet := CN121VlAgr(oModelCNE:GetValue("CNE_PRODUT"),oModelCNE:GetValue("CNE_QUANT"),0)

				If lRet
					lRet := C121CNEAgr(oModel,,,,.T.)
				EndIf
			EndIf
		Else
			//Habilita edição de campos
			CN121ChgPl()
		EndIf
ENDCASE
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121CNQPV()
Pré-valid da CNQ (Descontos da Planilha da Medição)

@author israel.escorizza
@since 09/09/2015
@version P12
@return .T.
/*/
//--------------------------------------------------------------------
Function Cn121CNQPV(oModelCNQ, nLine, cAction, cField, xValue, xOldValue)
Local lRet		:= .T.
Local oModel	:= Nil
Local oModelCNE	:= Nil
Local oModelCXN	:= Nil

DO CASE
	CASE cAction == 'CANSETVALUE'
		oModel := oModelCNQ:GetModel()
		oModelCNE := oModel:GetModel("CNEDETAIL")
		oModelCXN := oModel:GetModel("CXNDETAIL")
		
		If !oModelCXN:GetValue("CXN_CHECK") .OR. Empty(oModelCNE:GetValue("CNE_ITEM"))
			lRet:= .F.
		EndIf

	CASE cAction == 'SETVALUE'
		DO CASE
			CASE cField == 'CNQ_VALOR'
				oModel := oModelCNQ:GetModel()
				oModelCXN := oModel:GetModel("CXNDETAIL")
				
				cAtuFld := 'CXN_VLDESC'

				nTotal := oModelCXN:GetValue(cAtuFld)
				nTotal += (xValue - xOldValue)
				oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.T.})
				oModelCXN:SetValue(cAtuFld,nTotal)
				oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.F.})
		ENDCASE

	CASE cAction == 'DELETE'
		oModel := oModelCNQ:GetModel()
		oModelCXN := oModel:GetModel("CXNDETAIL")
		
		cAtuFld := 'CXN_VLDESC'

		nTotal := oModelCXN:GetValue(cAtuFld)
		nTotal -= oModelCNQ:GetValue('CNQ_VALOR')
		oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.T.})
		oModelCXN:SetValue(cAtuFld,nTotal)
		oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.F.})

	CASE cAction == 'UNDELETE'
		oModel := oModelCNQ:GetModel()
		oModelCXN := oModel:GetModel("CXNDETAIL")
		
		cAtuFld := 'CXN_VLDESC'

		nTotal := oModelCXN:GetValue(cAtuFld)
		nTotal += oModelCNQ:GetValue('CNQ_VALOR')
		oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.T.})
		oModelCXN:SetValue(cAtuFld,nTotal)
		oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.F.})
ENDCASE

Return lRet


//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121CNZPV()
Pré-valid da CNZ (Rateio dos Itens da Planilha da Medição)

@author israel.escorizza
@since 02/09/2015
@version P12
@return .T.
/*/
//--------------------------------------------------------------------
Function Cn121CNZPV(oModelCNZ, nLine, cAction, cField, xValue, xOldValue)
Local lRet		:= .T.
Local oModel	:= NIL
Local oModelCNE	:= NIL
Local oModelCXN	:= NIL

DO CASE
	CASE cAction == 'CANSETVALUE'
		oModel		:= oModelCNZ:GetModel()
		oModelCXN	:= oModel:GetModel("CXNDETAIL")
		oModelCNE	:= oModel:GetModel("CNEDETAIL")

		If !oModelCXN:GetValue("CXN_CHECK") .OR. Empty(oModelCNE:GetValue("CNE_ITEM"))
			lRet:= .F.
		EndIf

	CASE cAction == 'SETVALUE'
		If cField == 'CNZ_PERC'
			If xValue > 100
				Help(" ",1,"CN300ERAT")
				lRet := .F.
			ElseIf lRet := CN300VldRat(.T.,xValue-xOldValue)
				Cn121AtuRat(NIL,xValue)
			EndIf
		EndIf
ENDCASE
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121CXIPV()
Pré-valid da CXI (Partes envolvidas)

@author israel.escorizza
@since 02/09/2015
@version P12
@return .T.
/*/
//--------------------------------------------------------------------
Function Cn121CXIPV(oModelCXI, nLine, cAction, cField, xValue, xOldValue)
Local lRet		:= .T.
Local oModel	:= NIL
Local oModelCXN	:= NIL

DO 	CASE
	CASE cAction == 'CANSETVALUE'
		oModel := oModelCXI:GetModel()
		oModelCXN := oModel:GetModel("CXNDETAIL")

		If !oModelCXN:GetValue("CXN_CHECK")
			lRet:= .F.
		EndIf
ENDCASE

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121CNR1()
Pré-valid da CNR1 (Multas e Bonificações da planilha)
@author
@since
@version P12
@return .T.
/*/
//--------------------------------------------------------------------
Function Cn121CNR1(oModelCNR1, nLine, cAction, cField, xValue, xOldValue)
Local lRet		:= .T.
Local lBonif	:= .F.
Local nTotal	:= 0
Local cAtuFld	:= ""
Local cRmvFld	:= ""
Local cAddFld	:= ""
Local oModel	:= NIL
Local oModelCXN := NIL
Local lAuto		:= IsInCallStack("CN121Auto")

DO CASE
	CASE cAction == 'CANSETVALUE'
		oModel	   := oModelCNR1:GetModel()
		oModelCXN  := oModel:GetModel('CXNDETAIL')
		
		If !oModelCXN:GetValue("CXN_CHECK")
			lRet:= .F.
		EndIf
		If cField != 'CNR_TIPO'
			If 	(oModelCNR1:GetValue('CNR_TIPO') == '1' .AND. !Cn121RetSt('MULMAN') $ '2|4') .OR. (oModelCNR1:GetValue('CNR_TIPO') == '2' .AND. !Cn121RetSt('MULMAN') $ '3|4')
				lRet := .F.
			EndIf
		EndIf

	CASE cAction == 'SETVALUE'
		DO CASE
			CASE cField == 'CNR_VALOR'
				oModel		:= oModelCNR1:GetModel()
				oModelCXN 	:= oModel:GetModel('CXNDETAIL')

				If oModelCNR1:GetValue('CNR_TIPO') == '1' //- Verifica se é multa ou bonificação 1- Multa/2- Bonif.
					cAtuFld := 'CXN_VLMULT'
					lBonif := .F.
				Else
					cAtuFld := 'CXN_VLBONI'
					lBonif	:= .T.
				EndIf

				nTotal := oModelCXN:GetValue(cAtuFld)
				nTotal += (xValue - xOldValue)

				If CN121RetSt("VENDA",0,oModel:GetValue("CXNDETAIL","CXN_NUMPLA")) .And. lBonif .And. nTotal >= oModelCXN:GetValue("CXN_VLTOT")
					If !lAuto
						If MsgYesNo(STR0140+STR0141) //- A bonificação é igual ao total da planilha.|| Esta planilha será desconsiderada na geração do documento, deseja continuar?
							oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.T.})
							oModelCXN:SetValue(cAtuFld,nTotal)
							oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.F.})
						Else
							lRet := .F.
							Help(" ",1,"CN121MULT")
						EndIf
					Else
						oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.T.})
						oModelCXN:SetValue(cAtuFld,nTotal)
						oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.F.})
					Endif

				ElseIf CN121RetSt("COMPRA",0,oModel:GetValue("CXNDETAIL","CXN_NUMPLA")) .And. !lBonif .And. nTotal >= oModelCXN:GetValue("CXN_VLTOT")
					If !lAuto
						If MsgYesNo(STR0140+STR0141) //- A bonificação é igual ao total da planilha. || Esta planilha será desconsiderada na geração do documento, deseja continuar?
							oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.T.})
							oModelCXN:SetValue(cAtuFld,nTotal)
							oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.F.})
						Else
							lRet := .F.
							Help(" ",1,"CN121MULT")
						EndIf
					Else
						oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.T.})
						oModelCXN:SetValue(cAtuFld,nTotal)
						oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.F.})
					Endif
				Else
					oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.T.})
					oModelCXN:SetValue(cAtuFld,nTotal)
					oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.F.})
				EndIf
			CASE cField == 'CNR_TIPO'
				oModel		:= oModelCNR1:GetModel()
				oModelCXN 	:= oModel:GetModel('CXNDETAIL')
				
				If xValue == '2' .AND. xOldValue == '1'
					cRmvFld := 'CXN_VLMULT'
					cAddFld := 'CXN_VLBONI'
				ElseIf xValue == '1' .AND. xOldValue == '2'
					cRmvFld := 'CXN_VLBONI'
					cAddFld := 'CXN_VLMULT'
				Else
					lRet := .F.
				EndIf

				If lRet
					nTotal := oModelCXN:GetValue(cRmvFld)
					nTotal -= oModelCNR1:GetValue('CNR_VALOR')
					oModelCXN:GetStruct():SetProperty(cRmvFld,MODEL_FIELD_WHEN,{||.T.})
					oModelCXN:SetValue(cRmvFld,nTotal)
					oModelCXN:GetStruct():SetProperty(cRmvFld,MODEL_FIELD_WHEN,{||.F.})

					nTotal := oModelCXN:GetValue(cAddFld)
					nTotal += oModelCNR1:GetValue('CNR_VALOR')
					oModelCXN:GetStruct():SetProperty(cAddFld,MODEL_FIELD_WHEN,{||.T.})
					oModelCXN:SetValue(cAddFld,nTotal)
					oModelCXN:GetStruct():SetProperty(cAddFld,MODEL_FIELD_WHEN,{||.F.})
				EndIf
		ENDCASE

	CASE cAction == 'DELETE'
		oModel		:= oModelCNR1:GetModel()
		oModelCXN 	:= oModel:GetModel('CXNDETAIL')

		If oModelCNR1:GetValue('CNR_TIPO') == '1' //- Verifica se é multa ou bonificação 1- Multa/2- Bonif.
			cAtuFld := 'CXN_VLMULT'
		Else
			cAtuFld := 'CXN_VLBONI'
		EndIf

		nTotal := oModelCXN:GetValue(cAtuFld)
		nTotal -= oModelCNR1:GetValue('CNR_VALOR')
		oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.T.})
		oModelCXN:SetValue(cAtuFld,nTotal)
		oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.F.})

	CASE cAction == 'UNDELETE'
		oModel		:= oModelCNR1:GetModel()
		oModelCXN 	:= oModel:GetModel('CXNDETAIL')

		If oModelCNR1:GetValue('CNR_TIPO') == '1' //- Verifica se é multa ou bonificação 1- Multa/2- Bonif.
			cAtuFld := 'CXN_VLMULT'
		Else
			cAtuFld := 'CXN_VLBONI'
		EndIf
		nTotal := oModelCXN:GetValue(cAtuFld)
		nTotal += oModelCNR1:GetValue('CNR_VALOR')
		oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.T.})
		oModelCXN:SetValue(cAtuFld,nTotal)
		oModelCXN:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.F.})
ENDCASE
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121CNR2()
Pré-valid da CNR2 (Multas e Bonificações dos itens)
@author
@since
@version P12
@return .T.
/*/
//--------------------------------------------------------------------
Function Cn121CNR2(oModelCNR2, nLine, cAction, cField, xValue, xOldValue)
Local lRet		:= .T.
Local lMulta	:= .F.
Local nTotal	:= 0
Local cAtuFld	:= ""
Local cRmvFld	:= ""
Local cAddFld	:= ""
Local oModel	:= NIL
Local oModelCNE := NIL

DO CASE
	CASE cAction == 'CANSETVALUE'
		oModel := oModelCNR2:GetModel()
		oModelCXN := oModel:GetModel("CXNDETAIL")
		oModelCNE := oModel:GetModel("CNEDETAIL")

		If !oModelCXN:GetValue("CXN_CHECK") .OR. Empty(oModelCNE:GetValue("CNE_ITEM"))
			lRet:= .F.
		EndIf

		If cField != 'CNR_TIPO'
			If 	(oModelCNR2:GetValue('CNR_TIPO') == '1' .AND. !Cn121RetSt('MULMAN') $ '2|4') .OR. (oModelCNR2:GetValue('CNR_TIPO') == '2' .AND. !Cn121RetSt('MULMAN') $ '3|4')
				lRet := .F.
			EndIf
		EndIf
	CASE cAction == 'SETVALUE'
		DO CASE
			CASE cField == 'CNR_VALOR'
				oModel := oModelCNR2:GetModel()
				oModelCNE := oModel:GetModel('CNEDETAIL')

				If oModelCNR2:GetValue('CNR_TIPO') == '1' //- Verifica se é multa ou bonificação 1- Multa/2- Bonif.
					cAtuFld := 'CNE_MULTA'
					lMulta	:= .T.
				Else
					cAtuFld := 'CNE_BONIF'
					lMulta	:= .F.
				EndIf

				nTotal := oModelCNE:GetValue(cAtuFld)
				nTotal += (xValue - xOldValue)

				If CN121RetSt("COMPRA",0,oModel:GetValue("CXNDETAIL","CXN_NUMPLA")) .And. lMulta .And. nTotal >= oModelCNE:GetValue("CNE_VLTOT")
					If MsgYesNo(STR0142+STR0143) //- A multa é igual ao total do item. || Este item será desconsiderado na geração do documento, deseja continuar?
						oModelCNE:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.T.})
						oModelCNE:SetValue(cAtuFld,nTotal)
						oModelCNE:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.F.})
					Else
						lRet := .F.
						Help(" ",1,"CN121MULT")
					EndIf
				ElseIf CN121RetSt("VENDA",0,oModel:GetValue("CXNDETAIL","CXN_NUMPLA")) .And. !lMulta .And. nTotal >= oModelCNE:GetValue("CNE_VLTOT")
					If MsgYesNo(STR0142+STR0143) //- A multa é igual ao total do item. || Este item será desconsiderado na geração do documento, deseja continuar?
						oModelCNE:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.T.})
						oModelCNE:SetValue(cAtuFld,nTotal)
						oModelCNE:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.F.})
					Else
						lRet := .F.
						Help(" ",1,"CN121MULT")
					EndIf
				Else
					oModelCNE:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.T.})
					oModelCNE:SetValue(cAtuFld,nTotal)
					oModelCNE:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.F.})
				EndIf

			CASE cField == 'CNR_TIPO'
				oModel := oModelCNR2:GetModel()
				oModelCNE := oModel:GetModel('CNEDETAIL')

				If xValue == '2' .AND. xOldValue == '1'
					cRmvFld := 'CNE_MULTA'
					cAddFld := 'CNE_BONIF'
				ElseIf xValue == '1' .AND. xOldValue == '2'
					cRmvFld := 'CNE_BONIF'
					cAddFld := 'CNE_MULTA'
				Else
					lRet := .F.
				EndIf

				If lRet
					nTotal := oModelCNE:GetValue(cRmvFld)
					nTotal -= oModelCNR2:GetValue('CNR_VALOR')
					oModelCNE:GetStruct():SetProperty(cRmvFld,MODEL_FIELD_WHEN,{||.T.})
					oModelCNE:SetValue(cRmvFld,nTotal)
					oModelCNE:GetStruct():SetProperty(cRmvFld,MODEL_FIELD_WHEN,{||.F.})

					nTotal := oModelCNE:GetValue(cAddFld)
					nTotal += oModelCNR2:GetValue('CNR_VALOR')
					oModelCNE:GetStruct():SetProperty(cAddFld,MODEL_FIELD_WHEN,{||.T.})
					oModelCNE:SetValue(cAddFld,nTotal)
					oModelCNE:GetStruct():SetProperty(cAddFld,MODEL_FIELD_WHEN,{||.F.})
				EndIf
		ENDCASE

	CASE cAction == 'DELETE'
		oModel := oModelCNR2:GetModel()
		oModelCNE := oModel:GetModel('CNEDETAIL')

		If oModelCNR2:GetValue('CNR_TIPO') == '1' //- Verifica se é multa ou bonificação 1- Multa/2- Bonif.
			cAtuFld := 'CNE_MULTA'
		Else
			cAtuFld := 'CNE_BONIF'
		EndIf

		nTotal := oModelCNE:GetValue(cAtuFld)
		nTotal -= oModelCNR2:GetValue('CNR_VALOR')

		oModelCNE:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.T.})
		oModelCNE:SetValue(cAtuFld,nTotal)
		oModelCNE:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.F.})

	CASE cAction == 'UNDELETE'
		oModel := oModelCNR2:GetModel()
		oModelCNE := oModel:GetModel('CNEDETAIL')

		If oModelCNR2:GetValue('CNR_TIPO') == '1' //- Verifica se é multa ou bonificação 1- Multa/2- Bonif.
			cAtuFld := 'CNE_MULTA'
		Else
			cAtuFld := 'CNE_BONIF'
		EndIf

		nTotal := oModelCNE:GetValue(cAtuFld)
		nTotal += oModelCNR2:GetValue('CNR_VALOR')

		oModelCNE:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.T.})
		oModelCNE:SetValue(cAtuFld,nTotal)
		oModelCNE:GetStruct():SetProperty(cAtuFld,MODEL_FIELD_WHEN,{||.F.})
ENDCASE

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121SetCp()
Função para "converter" os Valores de CND_RCCOMP e setar em
CND_COMPET

@author miguel.santos
@since 27/07/2015

@version P12.1.7
/*/
//-------------------------------------------------------------------
Function CN121SetCp(oModel,cField,cValue,cOldValue,cFilCTR,lAuto)
Local 	nIndex	:= 0
DEFAULT cFilCTR	:= Iif(!Empty(CN9->CN9_FILCTR),CN9->CN9_FILCTR,cFilAnt)
DEFAULT lAuto	:= IsInCallStack('CN260EXC')

If !Empty(aComp)
	lExced	:= lExcedNPrv
	Cn121ClrTt()

	If !lAuto
		nIndex := Val(oModel:GetValue("CND_RCCOMP"))
		cValue := aComp[IIf(nIndex == 0,1,nIndex)]
	Else
		cValue := aComp[1]
	Endif

	cValue := SubStr(cValue ,At("=",cValue)+1,Len(cValue))
	oModel:SetValue("CND_COMPET", cValue)
	CN120Compet(lExced,cFilCTR)
EndIf

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121Item
Função para carregas os itens vinculados na Planilha.
@author Israel.Escorizza
@since 31/08/2015
@version P12.1.7
/*/
//-------------------------------------------------------------------
Function CN121Item( lCheck, cItemCNB, oModel, cPlan, cContra )
Local aSaveLines	:= FwSaveRows()
Local aArea			:= GetArea()
Local aAreaCNA		:= {}
Local aAreaCNB		:= {}
Local oModelCND		:= Nil
Local oModelCNE		:= Nil
Local oModelCXN		:= Nil
Local oModelCXI		:= Nil
Local oModelCNZ		:= Nil
Local cRevisa		:= ""
Local cCompet		:= ""
Local nVlPrev		:= 0
Local cCronog		:= ""
Local cParcel		:= ""
Local cCampoEc		:= ''
Local cItem			:= ''
Local cSeek			:= ''
Local cFilCtr		:= ""
Local cFilCtrAux	:= ""
Local cFilCNB 		:= ""
Local lFisico		:= .F.
Local lFixo			:= .F.
Local lMedEve		:= .F.
Local lRecorre		:= .F.
Local lCompra		:= .F.
Local lServico		:= .F.
Local aCTBEnt	  	:= CTBEntArr()
Local aECAdic		:= {}
Local aBlkCpo		:= {}
Local nX			:= 0
Local nY			:= 0
Local nQtdeItens	:= 0
Local nValUnit 		:= 0
Local nPDesc		:= 0
Default oModel		:= FwModelActive()
Default lCheck		:= oModel:GetModel('CXNDETAIL'):GetValue("CXN_CHECK")
Default cItemCNB	:= ""
Default cPlan 		:= ""
Default cContra		:= ""

lFisico := CN121RetSt( 'FISICO', 0, cPlan, cContra, .T. )
lFixo := CN121RetSt( 'FIXO', 0, cPlan, cContra, .T. )
lMedEve := CN121RetSt( 'MEDEVE', 0, cPlan, cContra, .T. )
lRecorre := CN121RetSt( 'RECORRENTE', 0, cPlan, cContra, .T. )
lCompra := CN121RetSt( "COMPRA", 0, cPlan, cContra, .T. )
lServico := CN121RetSt( "SERVIÇO", 0, cPlan, cContra, .T. )

oModelCND := oModel:GetModel('CNDMASTER')
oModelCNE := oModel:GetModel('CNEDETAIL')
oModelCXN := oModel:GetModel('CXNDETAIL')
oModelCXI := oModel:GetModel('CXIDETAIL')
oModelCNZ := oModel:GetModel('CNZDETAIL')

cRevisa := oModelCND:GetValue('CND_REVISA')
cCompet := oModelCND:GetValue('CND_COMPET')
nVlPrev := oModelCND:GetValue('CND_VLLIQD')
cCronog := oModelCXN:GetValue('CXN_CRONOG')
cParcel := oModelCXN:GetValue('CXN_PARCEL')

If !IsExced()
	//- Abre modelo para inserção de valores
	CN121ChgPl(.T.,.T.,oModel)
EndIf

If !Empty(cItemCNB)
	oModelCNE:GoLine(oModelCNE:Length())
Else
	oModelCNE:GoLine(1)
EndIf

//- Verifica se já existe informação antes de iniciar a carga
If Empty(oModelCNE:GetValue("CNE_PRODUT"))
	//- Inicio da carga
	dbSelectArea("CNB")
	CNB->(dbSetOrder(1)) //CNB_FILIAL+CNB_CONTRA+CNB_REVISA+CNB_NUMERO+CNB_ITEM
	
	cFilCtr := oModelCND:GetValue('CND_FILCTR')
	cFilCtrAux := FWxFilial( "CN9", cFilCtr )
	cFilCNB := FWxFilial( "CNB", cFilCtr ) 
	
	cSeek := cFilCNB + cContra + cRevisa + cPlan
	CNA->(dbSetOrder(1))
	CNA->(MsSeek(cSeek)) //Posiciona CNA
	cSeek += cItemCNB
	If CNB->(MsSeek(cSeek))
		
		If lServico
			nQtdeItens := PegaQtdCNB( cFilCNB, cContra, cRevisa, cPlan )
		EndIf
		
		While !CNB->(EOF()) .AND. (	CNB->(CNB_FILIAL+CNB_CONTRA+CNB_REVISA+CNB_NUMERO) == cSeek .Or. CNB->(CNB_FILIAL+CNB_CONTRA+CNB_REVISA+CNB_NUMERO+CNB_ITEM) == cSeek )
			nValUnit := 0
			nPDesc := 0
			If Empty(CNB->CNB_ITMDST)
				If nY <> 0 .And. !Empty(oModelCNE:GetValue("CNE_PRODUT"))
					aAreaCNB := CNB->(GetArea())
					oModelCNE:AddLine()
					RestArea(aAreaCNB)
				EndIf
				nY++
				If nY == oModelCNE:GetLine() .Or. !Empty(cItemCNB)
					cItem := CNB->CNB_ITEM
					//Posiciona CNF e CNS
					If !lMedEve .And. !lRecorre
						dbSelectArea("CNF")
						If !Empty(cParcel)
							CNF->(dbSetOrder(3))
							CNF->(MsSeek(xFilial("CNF",cFilCtr)+cContra+cRevisa+cCronog+cParcel))
						Else
							CNF->(dbSetOrder(2))
							CNF->(MsSeek(xFilial("CNF",cFilCtr)+cContra+cRevisa+cCronog+cCompet))
						EndIf
						If lFisico
							dbSelectArea("CNS")
							CNS->(dbSetOrder(1)) //CNS_FILIAL+CNS_CONTRA+CNS_REVISA+CNS_CRONOG+CNS_PARCEL+CNS_ITEM
							CNS->(MsSeek(xFilial("CNS",cFilCtr)+cContra+cRevisa+cCronog+cParcel+cItem))
						EndIf
					EndIf

					//Popula Modelo de Itens
					oModelCNE:LoadValue('CNE_CONTRA',CNB->CNB_CONTRA)
					oModelCNE:LoadValue('CNE_REVISA',CNB->CNB_REVISA)
					oModelCNE:LoadValue('CNE_NUMERO',CNB->CNB_NUMERO)
					oModelCNE:LoadValue('CNE_ITEM'	,CNB->CNB_ITEM)
					If IsExced()
						oModelCNE:SetValue('CNE_PRODUT',"")
					Else
						oModelCNE:SetValue('CNE_PRODUT',CNB->CNB_PRODUT)
					EndIf
					oModelCNE:LoadValue('CNE_TABPRC',CNB->CNB_TABPRC)
					oModelCNE:LoadValue('CNE_FLGCMS',CNB->CNB_FLGCMS)
					
					//Carrega as informações contábeis do item do contrato somente se a medição estiver na mesma filial do contrato ou se as tabelas tiverem comparilhamentos compatíveis
					If FWxFilial( "CTT", cFilCtrAux ) == FWxFilial( "CTT", cFilAnt ) .And. !Empty(CNB->CNB_CC)
						oModelCNE:SetValue( 'CNE_CC', CNB->CNB_CC )
					EndIf
					If FWxFilial( "CT1", cFilCtrAux ) == FWxFilial( "CT1", cFilAnt ) .And. !Empty(CNB->CNB_CONTA) 
						oModelCNE:SetValue( 'CNE_CONTA', CNB->CNB_CONTA )
					EndIf
					If FWxFilial( "CTD", cFilCtrAux ) == FWxFilial( "CTD", cFilAnt ) .And. !Empty(CNB->CNB_ITEMCT)
						oModelCNE:SetValue( 'CNE_ITEMCT', CNB->CNB_ITEMCT )
					EndIf
					If FWxFilial( "CTH", cFilCtrAux ) == FWxFilial( "CTH", cFilAnt ) .And. !Empty(CNB->CNB_CLVL)
						oModelCNE:SetValue( 'CNE_CLVL', CNB->CNB_CLVL )
					EndIF
					
					oModelCNE:LoadValue('CNE_CODNE'	,CNB->CNB_CODNE)
					oModelCNE:LoadValue('CNE_ITEMNE',CNB->CNB_ITEMNE)

					//Excedente por Competência não prevista
					If IsExced()
						nValUnit := 0
						nPDesc := 0
					Else
						If lServico
							nValUnit := Round( ( oModelCXN:GetValue('CXN_VLPREV') / nQtdeItens ), TamSx3("CNE_VLUNIT")[2] )
						Else
							nValUnit := CNB->CNB_VLUNIT
						EndIF
						nPDesc := CNB->CNB_DESC
					EndIf

					oModelCNE:LoadValue('CNE_VLUNIT',nValUnit)
					oModelCNE:LoadValue('CNE_PDESC' ,nPDesc)
					oModelCNE:LoadValue('CNE_PRODSV',CNB->CNB_PRODSV)
					oModelCNE:LoadValue('CNE_DTENT'	,dDataBase)
					oModelCNE:LoadValue('CNE_IDPED'	,CNB->CNB_IDPED)

					//Excedente por Competência não prevista
					If IsExced()
						oModelCNE:LoadValue('CNE_EXCEDE','1')
					Else
						oModelCNE:LoadValue('CNE_EXCEDE','2')
					EndIf

					If !Empty(CNB->CNB_PEDTIT)
						oModelCNE:LoadValue('CNE_PEDTIT',CNB->CNB_PEDTIT)
					EndIf

					If lCompra
						oModelCNE:SetValue('CNE_TE'		,CNB->CNB_TE)
						If cPaisLoc == "RUS"
							oModelCNE:SetValue('CNE_CF'		,CNB->CNB_CF)
						EndIf
						oModelCNE:LoadValue("CNE_TES"	,CNB->CNB_TE)
					Else
						oModelCNE:SetValue('CNE_TS'		,CNB->CNB_TS)
						If cPaisLoc == "RUS"
							oModelCNE:SetValue('CNE_CF'		,CNB->CNB_CF)
						EndIf
						oModelCNE:LoadValue("CNE_TES"	,CNB->CNB_TS)
					EndIf

					If lRecorre // Verifica contrato recorrente
						If CNB->CNB_ATIVO == "1" // verifica item ativo
							oModelCNE:LoadValue('CNE_QTAMED',CNB->CNB_SLDMED - Cn121QtdBlq(CNB->CNB_CONTRA,CNB->CNB_REVISA,CNB->CNB_NUMERO,CNB->CNB_ITEM) )
							oModelCNE:LoadValue('CNE_SDAMED',oModelCNE:GetValue('CNE_QTAMED') )
							oModelCNE:LoadValue('CNE_QTDSOL',CNB->CNB_QUANT)

							If CNB->CNB_PARPRO > 0 .And. Empty(CNB->CNB_PRIMED) // verifica se é primeira medição e se é proproporcional
								oModelCNE:SetValue('CNE_QUANT',CNB->CNB_QUANT * CNB->CNB_PARPRO /100 )
								oModelCNE:SetValue('CNE_PERC',CNB->CNB_PARPRO)
							Else
								oModelCNE:SetValue('CNE_QUANT',CNB->CNB_QUANT)
							EndIf
						Else
							oModelCNE:SetValue('CNE_QUANT',0)
						Endif
					Else
						If lFixo
							//Excedente por Competência não prevista
							If IsExced()
								oModelCNE:LoadValue('CNE_QTAMED',0)
								oModelCNE:LoadValue('CNE_SDAMED',0)
								oModelCNE:LoadValue('CNE_QTDSOL',0)
							Else
								oModelCNE:LoadValue('CNE_QTAMED',CNB->CNB_SLDMED - Cn121QtdBlq(CNB->CNB_CONTRA,CNB->CNB_REVISA,CNB->CNB_NUMERO,CNB->CNB_ITEM) )
								oModelCNE:LoadValue('CNE_SDAMED',Iif(oModelCNE:GetValue('CNE_QTAMED') < 0, 0, oModelCNE:GetValue('CNE_QTAMED')))
								oModelCNE:LoadValue('CNE_QTDSOL',CNB->CNB_QUANT)
							EndIf
						Else
							oModelCNE:SetValue('CNE_PERC',0)
						EndIf

						If !lMedEve
							If !lFisico
								If IsExced()
									oModelCNE:SetValue('CNE_QUANT',0)
								Else

									aAreaCNA := CNA->(GetArea())
									oModelCNE:SetValue('CNE_QUANT',Cn121QtdIt(CNB->CNB_SLDMED,CNA->CNA_SALDO,CNF->CNF_SALDO,lFisico,lFixo))
									RestArea(aAreaCNA)
	
									Cn121VldVlr(oModel)
								EndIf
							Else
								If IsExced()
									oModelCNE:SetValue('CNE_QUANT',0)
								Else
									oModelCNE:SetValue('CNE_QUANT',CNS->CNS_SLDQTD)// Saldo na CNS
								EndIf
							EndIf
						Else
							oModelCNE:SetValue('CNE_QUANT',0)
						EndIf
					EndIf

					If lServico
						If oModelCNE:GetValue('CNE_QUANT') == 0							
							nValUnit := 0
						Else
							nValUnit := Round( ( oModelCXN:GetValue('CXN_VLPREV') / nQtdeItens ), TamSx3("CNE_VLUNIT")[2] )
						EndIf
						
						oModelCNE:SetValue('CNE_VLUNIT',nValUnit)
					EndIf

					//Campos de entidades adicionais
					AEval( aCTBEnt,{ | x | IIf( CNE->( FieldPos( "CNE_EC"+ AllTrim( x ) +"CR" ) ) > 0 .And. CNB->( FieldPos( "CNB_EC"+ AllTrim( x ) +"CR" ) ) > 0, cCampoEc += "CNE_EC"+ AllTrim( x ) +"CR|CNE_EC"+ AllTrim( x ) +"DB|" , Nil ) } )
					aECAdic := StrTokArr(cCampoEc,'|')
					For nX := 1 To Len(aECAdic)
						If!Empty(CNB->&("CNB"+SUBSTR(aECAdic[nX],4)))
							oModelCNE:SetValue(aECAdic[nX],CNB->(&("CNB"+SUBSTR(aECAdic[nX],4))))
						EndIf
					Next nX

					If CNE->( ColumnPos( "CNE_ARREND" ) ) > 0 .And. CNB->( ColumnPos( "CNB_ARREND" ) ) > 0
						oModelCNE:LoadValue( "CNE_ARREND", CNB->CNB_ARREND )
					EndIf

					//Carrega Agregados dos itens
					CN121CNZIt(oModel, oModelCNZ)
					CN121CNRIt(oModel, oModelCNE)
				EndIf
		    EndIf
	      	CNB->(dbSkip())
		EndDo
	EndIf
EndIf

If !IsExced()
	// Reavalia Liberacao de campos
	CN121ChgPl(.F.,lCheck,oModel)
EndIf

RestArea(aArea)
FWRestRows( aSaveLines )

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121MultT()
Efetua a Validacao dos campos digitados quanto a quantidade,preco,
desconto e quantidade liberada.

@author filipe.gonçalves
@since 28/07/2015

@version P12.1.7
/*/
//-------------------------------------------------------------------
Function CN121MultT(oModelGrid,cField,cValue,cOldValue)
Local aArea     := GetArea()
Local oModel	:= Nil
Local oModelCND := Nil
Local oModelCXN := Nil
Local oModelCNE := Nil
Local cContra	:= Nil
Local cPlan		:= Nil
Local lFixo		:= Nil
Local lServico	:= Nil
Local cEspecie  := ""
Local lAuto		:= IsInCallStack("CNTA260")
Local lnotTEC930 := IIF( FindFunction("TEC930Test") .AND. TEC930Test() , .F. , !lMedicao)

If IsInCallStack('CNTA120') .And. lnotTEC930
	CN130MultT()
Else
	oModel		:= FwModelActive()
	oModelCND	:= oModel:GetModel("CNDMASTER")
	oModelCXN	:= oModel:GetModel("CXNDETAIL")
	oModelCNE	:= oModel:GetModel("CNEDETAIL")
	cContra		:= oModelCND:GetValue("CND_CONTRA")
	cPlan		:= oModelCXN:GetValue("CXN_NUMPLA")
	lFixo		:= CN121RetSt("FIXO",0,cPlan,cContra)
	lServico	:= CN121RetSt("SERVICO",0,cPlan,cContra)

	If Type("cEspCtr") == "C"
		cEspecie := cEspCtr
	Else
		cEspecie := CN9->CN9_ESPCTR
	EndIf

	If cEspecie=="2" .And. (!( Type("lAuto") != "U" .And. lAuto ))
	   If lFixo
			Do Case
			Case cField == "CNE_VLUNIT"
				If ( Type("lServico") != "U" .And. !lServico )
					FtDescItem(0,@cValue,oModelCNE:GetValue('CNE_QUANT'),oModelCNE:GetValue('CNE_VLTOT'),oModelCNE:GetValue('CNE_PDESC'),oModelCNE:GetValue('CNE_VLDESC'),0,1,,)
				Else
					FtDescItem(0,oModelCNE:GetValue('CNE_VUNORI'),@cValue/oModelCNE:GetValue('CNE_VUNORI'),oModelCNE:GetValue('CNE_VLTOT'),oModelCNE:GetValue('CNE_PDESC'),oModelCNE:GetValue('CNE_VLDESC'),0,1,,)
				EndIf

			Case cField == "CNE_QUANT"
				FtDescItem(0,oModelCNE:GetValue('CNE_VLUNIT'),@cValue,oModelCNE:GetValue('CNE_VLTOT'),oModelCNE:GetValue('CNE_PDESC'),oModelCNE:GetValue('CNE_VLDESC'),0,1,,)

			Case cField == "CNE_PDESC"
				FtDescItem(0,oModelCNE:GetValue('CNE_VLUNIT'),oModelCNE:GetValue('CNE_QUANT'),oModelCNE:GetValue('CNE_VLTOT'),@cValue,oModelCNE:GetValue('CNE_VLDESC'),0,1,,)

			Case cField == "CNE_VLTOT"

				If ( Type("lServico") != "U" .And. !lServico )
					FtDescItem(0,oModelCNE:GetValue('CNE_VLUNIT'),(@cValue/oModelCNE:GetValue('CNE_VLUNIT')) ,@cValue,oModelCNE:GetValue('CNE_PDESC'),oModelCNE:GetValue('CNE_VLDESC'),0,1,,)
				Else
					FtDescItem(0,oModelCNE:GetValue('CNE_VUNORI'),(@cValue/oModelCNE:GetValue('CNE_VUNORI')),@cValue,oModelCNE:GetValue('CNE_PDESC'),oModelCNE:GetValue('CNE_VLDESC'),0,1,,)
				EndIf

			Case cField == "CNE_PERC"
				If ( Type("lServico") != "U" .And. !lServico )
					FtDescItem(0,oModelCNE:GetValue('CNE_VLUNIT'),(oModelCNE:GetValue('CNE_QTDSOL')*@cValue)/100,oModelCNE:GetValue('CNE_VLTOT'),oModelCNE:GetValue('CNE_PDESC'),oModelCNE:GetValue('CNE_VLDESC'),0,1,,)
				Else
					FtDescItem(0,oModelCNE:GetValue('CNE_VUNORI'),(oModelCNE:GetValue('CNE_QTDSOL')*@cValue)/100,oModelCNE:GetValue('CNE_VLTOT'),oModelCNE:GetValue('CNE_PDESC'),oModelCNE:GetValue('CNE_VLDESC'),0,1,,)
				EndIf

			EndCase
	 	EndIf

		If ( Type("lFixo") != "U" .And. !lFixo )
			Do Case
				Case cField == "CNE_VLUNIT"
					oModelCNE:SetValue('CNE_VLDESC',0)
					oModelCNE:SetValue('CNE_PDESC',0)

				Case cField == "CNE_QUANT"
					oModelCNE:GetValue('CNE_VLDESC',0)
					oModelCNE:GetValue('CNE_PDESC',0)

				Case cField == "CNE_PDESC"
					FtDescItem(0,oModelCNE:GetValue('CNE_VLUNIT'),oModelCNE:GetValue('CNE_QUANT'),oModelCNE:GetValue('CNE_VLTOT'),@xConteudo,oModelCNE:GetValue('CNE_VLDESC'),0,1,,)
			EndCase
		EndIf
	EndIf
EndIf

RestArea(aArea)
Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121Mult()
Validação do campo código da multa/bonificação

@author jose.eulalio
@since 28/07/2015
@version P12
@return .T.
/*/
//--------------------------------------------------------------------
Function Cn121Mult()
Local aArea		:= GetArea()
Local lRet		:= .T.
Local lFormula	:= .F.
Local oModel	:= FwModelActive()
Local oModCNR1	:= oModel:GetModel("CNRDETAIL1")
Local cCod		:= oModCNR1:GetValue("CNR_CODIGO")
Local nValor	:= 0

DbSelectArea("CN4")
CN4->(DbSetOrder(1))

If CN4->(MsSeek(FwXFilial('CN4')+cCod))
	lFormula := IIf( Empty( CN4->CN4_VLDALT ), Formula( CN4->CN4_VALID ), CNTA130Form( CN4->CN4_VLDALT ) )
	lFormula := IIf( ValType( lFormula ) == 'L', lFormula , .F. )

	If lFormula
		nValor := IIf( Empty( CN4->CN4_VLRALT ), Formula( CN4->CN4_FORMUL ), CNTA130Form( CN4->CN4_VLRALT ) )
        nValor := IIf( ValType( nValor ) == 'N', nValor, 0 )
	EndIf

	oModCNR1:SetValue("CNR_MODO","2")
	oModCNR1:SetValue("CNR_FLGPED",CN4->CN4_FLGPED)
	oModCNR1:SetValue("CNR_TIPO",CN4->CN4_TIPO)
	oModCNR1:SetValue("CNR_VALOR",nValor)
EndIf

RestArea(aArea)

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121VldDtEnt()
Valida data de entrada informada nas medicoes

@author filipe.gonçalves
@since 29/07/2015

@version P12.1.7
/*/
//-------------------------------------------------------------------
Function CN121VldDtEnt()
Local oModel	:= Nil
Local oModelCNE	:= Nil
Local lRet 		:= .T.
Local lnotTEC930 := IIF( FindFunction("TEC930Test") .AND. TEC930Test() , .F. , !lMedicao)

If IsInCallStack('CNTA120') .And. lnotTEC930
	CN130VldDtEnt()
Else
	oModel	:= FWModelActive()
	oModelCNE	:= oModel:GetModel('CNEDETAIL')
	lRet := (FwFldGet('CNE_DTENT') >= dDataBase) .And. (FwFldGet('CNE_DTENT') <= CN9->CN9_DTFIM)
EndIf
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121VlTot()
Valida valor total informado na medicao

@author filipe.gonçalves
@since 29/07/2015

@version P12.1.7
/*/
//-------------------------------------------------------------------
Function CN121VlTot( nValue )
Local aArea		:= GetArea()
Local aSaveLines:= FWSaveRows()
Local oModel	:= Nil
Local oModelCND	:= Nil
Local oModelCXN	:= Nil
Local oModelCNE	:= Nil
Local nVlDesc	:= 0
Local nTotCNE	:= 0
Local nX		:= 0
Local nVlLimit	:= 0
Local nSaldoIt	:= 0
Local nQtdePend := 0
Local nValorUn  := 0
Local lRet      := .T.
Local lSemiFixo	:= .F.
Local lSemiAgr	:= .F.
Local lEventual := .F.
Local lVldEvent	:= .F.
Local lFixo 	:= .F.
Local lPrevFin 	:= .F.
Local lnotTEC930 := IIF( FindFunction("TEC930Test") .AND. TEC930Test() , .F. , !lMedicao)
local lFlexPrev := .F.
local lFlexSPrev := .F.

If IsInCallStack('CNTA120') .And. lnotTEC930
	lRet := CN130VlTot()
Else
	oModel		:= FWModelActive()
	oModelCND	:= oModel:GetModel('CNDMASTER')
	oModelCXN	:= oModel:GetModel('CXNDETAIL')
	oModelCNE	:= oModel:GetModel('CNEDETAIL')			

	If nValue == Nil
		nValue := oModelCNE:GetValue('CNE_VLTOT')
	EndIf

	lFixo := CN121RetSt('FIXO')
	lPrevFin := CN121RetSt("PREVFINANC")
	lEventual := CN121RetSt("EVENTUAL")
	lFlexPrev := lEventual .And. !lFixo .And. lPrevFin //Flexível com previsão financeira
	lFlexSPrev := lEventual .And. !lFixo .And. !lPrevFin //Flexível sem previsão financeira
	lSemiFixo := CN121RetSt( "SEMIFIXO", 0, oModelCXN:GetValue("CXN_NUMPLA"), oModelCXN:GetValue("CXN_CONTRA"), .T., oModel )
	
	If !IsExced()
		If oModelCND:GetValue('CND_ZERO') == "1"
			//Verifica se o total e igual a zero quando a medicao for zerada
			lRet := ( nValue == 0 )
		Else			
			If !lFlexSPrev
				If !lFlexPrev .And. !lSemiFixo
					nQtdePend := oModelCNE:GetValue('CNE_SDAMED')
					nValorUn := oModelCNE:GetValue('CNE_VLUNIT')
					nSaldoIt := nQtdePend * nValorUn
							
					//Valida se o valor informado ultrapassa o saldo do item
					If nValue > nSaldoIt
						lRet := .F.
						oModel:SetErrorMessage( "CNEDETAIL", "CNE_VLTOT", "CNEDETAIL", "CNE_VLTOT", "CNEVLTOT1", STR0187 + " (" + cValToChar(nSaldoIt) + ")" ) //"O valor Total informado é maior do que o saldo do item"
					EndIf
				EndIf

				If lRet
					For nX := 1 to oModelCNE:Length()
						oModelCNE:GoLine(nX)
						If !oModelCNE:IsDeleted()
							nTotCNE += oModelCNE:GetValue("CNE_VLTOT")
						EndIf
					Next nX
					nTotCNE := NoRound( nTotCNE, TAMSX3('CNE_VLTOT')[2] )
					
					lEventual := CN121RetSt( "EVENTUAL", 0, oModelCXN:GetValue("CXN_NUMPLA"),oModelCXN:GetValue("CXN_CONTRA") )
					lVldEvent := lEventual .And. !lFixo .And. !lPrevFin
					
					//Valida se o total informado nos itens utlrapassa o valor previsto para a medição, considerando o percentual de limite para medição, definido no tipo de contrato/planilha 
					If !lFlexPrev
						nVlLimit := Cn121LtMed( oModelCXN:GetValue("CXN_VLSALD"), oModelCXN:GetValue("CXN_CONTRA"), oModelCXN:GetValue("CXN_REVISA"), oModelCXN:GetValue("CXN_NUMPLA"), oModelCXN:GetValue("CXN_VLPREV") )
					Else
						nVlLimit := oModelCXN:GetValue("CXN_VLSALD")
					EndIf
					
					If nTotCNE > nVlLimit .And. !lVldEvent
						lRet := .F.
						oModel:SetErrorMessage( "CNEDETAIL", "CNE_VLTOT", "CNEDETAIL", "CNE_VLTOT", "CNEVLTOT2", STR0186 + cValToChar(nTotCNE) + STR0188 + cValToChar(nVlLimit) + "."  ) //"A soma dos valores informados para os itens ultrapassa o limite previsto para essa medição. Total informado: " ## ". Limite da medição: "  
					EndIf
				EndIf
							
				If lRet					
					If lSemiFixo
						If oModelCXN:GetValue("CXN_VLSALD") < nValue
							lRet := .F.
							Help(" ",1,"CXNSLDMED")
						EndIf
						
						lSemiAgr := CN121RetSt("SEMIAGRUP", 0, oModelCXN:GetValue("CXN_NUMPLA"), oModelCXN:GetValue("CXN_CONTRA") )
						If lSemiAgr
							lRet := CN121VlAgr(oModelCNE:GetValue("CNE_PRODUT"),oModelCNE:GetValue("CNE_QUANT"),0)
						EndIf
					EndIf
				EndIf
		
				If lRet
					//Regra para calcular valor do desconto.
					nVlDesc := nValue * oModelCNE:GetValue('CNE_PDESC') / 100
					oModelCNE:SetValue('CNE_VLDESC', nVlDesc)
				EndIf
			EndIf
		EndIf

		If lRet
			//Validação para preenchimento dos campos de Valor do rateio quando alterado CNE_VLTOT
			Cn121AtuRat(nValue)
		EndIf
	EndIf
EndIf

RestArea( aArea )
FWRestRows( aSaveLines )
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121VldPerc()
Valida percentual informado nas medicoes

@author filipe.gonçalves
@since 28/07/2015

@version P12.1.7
/*/
//-------------------------------------------------------------------
Function CN121VldPerc()
Local lRet     	:= .T.
Local aArea		:= GetArea()
Local aSaveLines:= FWSaveRows()
Local oModel	:= Nil
Local oModelCND	:= Nil
Local oModelCNE	:= Nil
Local lArrefat 	:= .F.
Local nTotal   	:= 0
Local nQtdSol	:= 0
Local nQtdMed	:= 0
Local cExeced	:= 0
Local nPerc		:= 0
Local nPercMed 	:= 0
Local lnotTEC930 := IIF( FindFunction("TEC930Test") .AND. TEC930Test() , .F. , !lMedicao)

If IsInCallStack('CNTA120') .And. lnotTEC930
	lRet := CN130VldPerc()
Else
	oModel		:= FWModelActive()
	oModelCND	:= oModel:GetModel('CNDMASTER')
	oModelCNE	:= oModel:GetModel('CNEDETAIL')
	lArrefat 	:= (SuperGetMv("MV_ARREFAT",.F.,"S")== "S")
	nTotal   	:= 0
	nQtdSol		:= oModelCNE:GetValue('CNE_QTDSOL')
	nQtdMed		:= oModelCNE:GetValue('CNE_SDAMED')
	cExeced		:= oModelCNE:GetValue('CNE_EXCEDE')
	nPerc		:= oModelCNE:GetValue('CNE_PERC')
	nPercMed 	:= (nQtdSol-nQtdMed)*100/nQtdSol //- Calculo do Percentual disponivel

	//-- Se excedente não permite digitar percentual
	If !Empty(cExeced) .And. cExeced == '1'
		Aviso(STR0079,STR0080,{STR0156}) //"Este campo não deve ser utilizado para itens classificados como excedente."
		lRet := .F.
	ElseIf oModelCND:GetValue('CND_ZERO') == "1" //-- Medição zerada possui percentual 0
		lRet := nPerc == 0
	Else
		lRet := nPerc <= (100-nPercMed)
		If !lRet
			nTotal := nPerc -(100-nPercMed)
			If nTotal<=0.001 .And. !lArrefat
			   lRet := .T.
			EndIf
		EndIf
	EndIf
EndIf
RestArea(aArea)
FWRestRows( aSaveLines )
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121VlUnt()
Valida valor unitario informado na medicao

@author filipe.gonçalves
@since 29/07/2015

@version P12.1.7
/*/
//-------------------------------------------------------------------
Function CN121VlUnt(oModelGrid,cField,xValue,nLine)
Local aArea		:= GetArea()
Local aSaveLines:= FWSaveRows()
Local oModel	:= Nil
Local oModelCND := Nil
Local oModelCXN	:= Nil
Local oModelCNE	:= Nil
Local cProdut	:= ""
Local cContra	:= ""
Local cRevisa	:= ""
Local cNumPla	:= ""
Local lRet 		:= .T.
Local lArrefat 	:= .F.
Local lSemiAgr	:= .F.
Local lEventual	:= .F.
Local lFixo 	:= .F.
Local lPrevFin 	:= .F.
Local nQuant  	:= 0
Local nTotal 	:= 0
Local nTotCNE	:= 0
Local nX		:= 0
Local lnotTEC930 := IIF( FindFunction("TEC930Test") .AND. TEC930Test() , .F. , !lMedicao)

If IsInCallStack('CNTA120') .And. lnotTEC930
	CN130VlUnt()
Else
	oModel		:= FWModelActive()
	oModelCND 	:= oModel:GetModel('CNDMASTER')
	oModelCXN	:= oModel:GetModel('CXNDETAIL')
	oModelCNE	:= oModel:GetModel('CNEDETAIL')
	cProdut		:= oModel:GetValue("CNEDETAIL","CNE_PRODUT")
	cContra		:= oModelCND:GetValue("CND_CONTRA")
	cRevisa		:= oModelCND:GetValue("CND_REVISA")
	cNumPla		:= oModelCXN:GetValue("CXN_NUMPLA")
	lArrefat 	:= (SuperGetMv("MV_ARREFAT",.F.,"S")== "S")
	lSemiAgr	:= CN121RetSt("SEMIAGRUP",0,cNumPla,cContra)
	lEventual	:= CN121RetSt("EVENTUAL", 0,cNumPla,cContra)
	lFixo		:= CN121RetSt("FIXO",0,cNumPla,cContra)
	lPrevFin	:= CN121RetSt("PREVFINANC",0,cNumPla,cContra)
	
	If !IsExced()
		//Verifica se a quantidade e menor que o saldo disponivel
		If oModelCNE:GetValue('CNE_SDAMED')  > 0
			If oModelCND:GetValue('CND_SERVIC') == '2'
				nQuant := oModelCNE:GetValue('CNE_VLUNIT') / oModelCNE:GetValue('CNE_VUNORI')
				lRet   := (nQuant <= oModelCNE:GetValue('CNE_SDAMED'))
			EndIf
		EndIf

		If !lRet
			nTotal := nQuant - oModelCNE:GetValue('CNE_SDAMED')
			If nTotal <= 0.001 .And. !lArrefat
			   lRet := .T.
			EndIf
		EndIf

		If lRet
			For nX := 1 to oModelCNE:Length()
				oModelCNE:GoLine(nX)
				If !oModelCNE:IsDeleted()
					If oModelCNE:GetLine() == nLine
						nTotCNE += oModelCNE:GetValue("CNE_QUANT") * xValue
					Else
						nTotCNE += oModelCNE:GetValue("CNE_VLTOT")
					EndIf
				EndIf
			Next nX
			
			lVldEvent := lEventual .And. !lFixo .And. !lPrevFin
			
			If oModelCXN:GetValue("CXN_VLSALD") < nTotCNE .And. !lVldEvent
				lRet := .F.
				Help(" ",1,"CN121VLCNE")
			EndIf
		EndIf

		//Validação do Agrupador com relação ao valor maximo da CXM
		If lRet .And. lSemiAgr
			lRet := C121CNEAgr(oModel,cField,xValue,nLine)
		EndIf
	EndIf
EndIf
RestArea(aArea)
FWRestRows( aSaveLines )
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121RetCa
Função para pegar o valor da caucao de retencao
@author filipe.gonçalves
@since 29/07/2015
@version P12.1.7
/*/
//-------------------------------------------------------------------
Function CN121RetCa( nTotMed, oModel )
Local aArea			:= GetArea()
Local aSaveLines	:= FWSaveRows()
Local oModelCND		:= Nil
Local oModelCXN		:= Nil
Local cFilCtr		:= "" 
Local cContra		:= ""
Local cRevisa		:= ""
Local cPlan			:= ""
Local cEspCtr		:= ""
Local lCn121VRet	:= ExistBlock("CN121VRE")
Local lCaucRet		:= .F.
Local nCaucRet  	:= 0
Local nCaucVlr  	:= 0
Local nCn121VRet	:= 0
Default nTotMed		:= 0
Default oModel	    := FWModelActive()

oModelCND := oModel:GetModel('CNDMASTER')
oModelCXN := oModel:GetModel('CXNDETAIL')
cFilCtr := oModelCND:GetValue("CND_FILCTR")
cContra := oModelCND:GetValue("CND_CONTRA")
cRevisa := oModelCND:GetValue("CND_REVISA")
cPlan := oModelCXN:GetValue('CXN_NUMPLA')

cEspCtr := Posicione('CN9',1,cFilCtr+cContra+cRevisa,'CN9_ESPCTR')

//-- Verifica se a caucao de retencao esta disponivel para contrato e para o ambiente
If (lCaucRet := (CN9->CN9_FLGCAU == "1" .And. CN9->CN9_TPCAUC == "2"))
	nCaucRet := CN9->CN9_MINCAU
   	If lCn121VRet //Ponto de Entrada para permitir alteracao no percentual de retencao
    	nCaucRet := If(Valtype(nCn121VRet := ExecBlock("CN121VRE",.F.,.F.,{cContra,cRevisa,cPlan}))=="N",nCn121VRet,nCaucRet)
   	EndIf
EndIf

//-- Calcula valor da retencao
If lCaucRet
	nCaucVlr := ((nTotMed*nCaucRet)/100)
EndIf

RestArea(aArea)
FWRestRows( aSaveLines )
Return nCaucVlr

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121CNRPl()
Carrega pasta de multas/bonificações

@author jose.eulalio
@since 29/07/2015
@version P12
@return .T.
/*/
//--------------------------------------------------------------------
Function CN121CNRPl(oModel,oModelCXN)
Local aArea		:= GetArea()
Local aSaveLines:= FWSaveRows()
Local lRet		:= .T.
Local oModCNR1	:= oModel:GetModel("CNRDETAIL1")
Local oModCNR2	:= oModel:GetModel("CNRDETAIL2")
Local oModTot	:= oModel:GetModel("TEMPTOT")
Local cCXNContra:= oModelCXN:GetValue("CXN_CONTRA")
Local nMult		:= 0
Local nTots		:= 0
Local nVlMult	:= 0
Local nVlBonif	:= 0

Local aPropCNR  := GetPropMdl(oModCNR1)
CNTA300BlMd(oModCNR1,.F.)
CNTA300BlMd(oModCNR2,.F.)

DbSelectArea("CNH")
CNH->(DbSetOrder(1))

If CNH->(DbSeek(xFilial("CNH")+cCXNContra))
	While CNH->CNH_NUMERO == cCXNContra
		DbSelectArea("CN4")
		CN4->(DbSetOrder(1))
		If CN4->(DbSeek(xFilial("CN4")+CNH->CNH_CODIGO))
			While CN4->CN4_CODIGO == CNH->CNH_CODIGO
				If CN4->CN4_AVALIA == "1" .And. CN121RetSt('TPMULT') == "2"
					If !Empty(oModCNR1:GetValue("CNR_VALOR"))
						oModCNR1:AddLine()
					EndIf
					oModCNR1:LoadValue("CNR_TIPO"	, CN4->CN4_TIPO)
					oModCNR1:LoadValue("CNR_DESCRI"	, CN4->CN4_DESCRI)
					oModCNR1:LoadValue("CNR_FLGPED"	, CN4->CN4_FLGPED)
					oModCNR1:LoadValue("CNR_MODO"	, "1")

					//Processa a fórmula da multa, retornando o valor
					nMult := Cn121vlMul()
					If CN4->CN4_TIPO == '1'
						nVlMult += nMult
					Else
						nVlBonif += nMult
					EndIf
					oModCNR1:SetValue("CNR_VALOR"	, nMult)
					oModCNR1:GetStruct():SetProperty('CNR_TIPO'	,MODEL_FIELD_WHEN,{||.F.})
					oModCNR1:GetStruct():SetProperty('CNR_DESCRI'	,MODEL_FIELD_WHEN,{||.F.})
					oModCNR1:GetStruct():SetProperty('CNR_VALOR'	,MODEL_FIELD_WHEN,{||.F.})
					oModCNR1:GetStruct():SetProperty('CNR_FLGPED'	,MODEL_FIELD_WHEN,{||.F.})
					oModCNR1:SetNoDeleteLine(.T.)
				EndIf
				CN4->(DbSkip())
			EndDo
		EndIf
		CNH->(DbSkip())
	EndDo
Else
	oModCNR1:LoadValue("CNR_MODO", "2")
EndIf
oModCNR1:GetStruct():SetProperty('CNR_MODO'	,MODEL_FIELD_WHEN,{||.F.})

RstPropMdl(oModCNR1,aPropCNR)
FWRestRows( aSaveLines )
RestArea(aArea)
Return lRet
//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121CNRIt()
Carrega pasta de multas/bonificações

@author jose.eulalio
@since 29/07/2015
@version P12
@return .T.
/*/
//--------------------------------------------------------------------
Function CN121CNRIt(oModel,oModelCNE)
Local aArea			:= GetArea()
Local aSaveLines	:= FWSaveRows()
Local oModCNR2		:= oModel:GetModel("CNRDETAIL2")
Local oModTot		:= oModel:GetModel("TEMPTOT")
Local cCNEContra	:= oModelCNE:GetValue("CNE_CONTRA")
Local cCNERevisa	:= oModelCNE:GetValue("CNE_REVISA")
Local nMult			:= 0
Local nTots			:= 0
Local nVlMult		:= 0
Local nVlBonif		:= 0
Local lRet			:= .T.

Local aPropCNR 		:= GetPropMdl(oModCNR2)
CNTA300BlMd(oModCNR2,.F.)

DbSelectArea("CNH")
CNH->(DbSetOrder(1))

If CNH->(DbSeek(xFilial("CNH")+cCNEContra))
	While CNH->CNH_NUMERO == cCNEContra
		If CNH->CNH_REVISA == cCNERevisa
			DbSelectArea("CN4")
			CN4->(DbSetOrder(1))
			If CN4->(DbSeek(xFilial("CN4")+CNH->CNH_CODIGO))
				While CN4->CN4_CODIGO == CNH->CNH_CODIGO
					If CN4->CN4_AVALIA == "2" .And. CN121RetSt('TPMULT') == "2"

						If !Empty(oModCNR2:GetValue("CNR_VALOR"))
							oModCNR2:AddLine()
						EndIf
						oModCNR2:LoadValue("CNR_TIPO"	, CN4->CN4_TIPO)
						oModCNR2:LoadValue("CNR_DESCRI"	, CN4->CN4_DESCRI)
						oModCNR2:LoadValue("CNR_FLGPED"	, CN4->CN4_FLGPED)
						oModCNR2:LoadValue("CNR_MODO"	, "1")

						//Processa a fórmula da multa, retornando o valor
						nMult := Cn121vlMul()
						If CN4->CN4_TIPO == '1'
							nVlMult += nMult
						Else
							nVlBonif += nMult
						EndIf
						oModCNR2:SetValue("CNR_VALOR"	, nMult)
						oModCNR2:GetStruct():SetProperty('CNR_TIPO'	,MODEL_FIELD_WHEN,{||.F.})
						oModCNR2:GetStruct():SetProperty('CNR_DESCRI'	,MODEL_FIELD_WHEN,{||.F.})
						oModCNR2:GetStruct():SetProperty('CNR_VALOR'	,MODEL_FIELD_WHEN,{||.F.})
						oModCNR2:GetStruct():SetProperty('CNR_FLGPED'	,MODEL_FIELD_WHEN,{||.F.})
						oModCNR2:SetNoDeleteLine(.T.)
					EndIf
					CN4->(DbSkip())
				EndDo
			EndIf
		EndIf
		CNH->(DbSkip())
	EndDo
Else
	oModCNR2:LoadValue("CNR_MODO"	, "2")
EndIf
oModCNR2:GetStruct():SetProperty('CNR_MODO'	,MODEL_FIELD_WHEN,{||.F.})

RstPropMdl(oModCNR2,aPropCNR)
FWRestRows( aSaveLines )
RestArea(aArea)
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121CXIIt()
Carrega pasta de Partes Envolvidas

@author Paulo V Beraldo
@since 20/08/2015
@version P12
@return .T.
/*/
//--------------------------------------------------------------------
Function CN121CXIIt(oModel)
Local oModelCXI	:= oModel:GetModel("CXIDETAIL")
Local aArea		:= GetArea()
Local aCXIArea	:= CXI->( GetArea() )
Local aSaveLines:= FWSaveRows()
Local cContrat	:= oModel:GetModel( 'CXNDETAIL' ):GetValue( 'CXN_CONTRA' )
Local cRevisa	:= oModel:GetModel( 'CXNDETAIL' ):GetValue( 'CXN_REVISA' )
Local cNumero	:= oModel:GetModel( 'CXNDETAIL' ):GetValue( 'CXN_NUMPLA' )
Local cLogError	:= ""
Local nCount	:= 0
Local nIncLine	:= 0
Local nInd		:= 0
Local lRet		:= .T.
Local lCanUpdCXI:= !(oModelCXI:CanUpdateLine())

dbSelectArea( 'CXI' )
CXI->( dbSetOrder( 1 ) ) //CXI_FILIAL+CXI_CONTRA+CXI_REVISA+CXI_NUMPLA+CXI_ITEM

If !CXI->( dbSeek( FwXFilial( 'CXI' ) + cContrat + cRevisa + cNumero ) )
	lRet := .F.
Else
	//Libera o Modelo para alteração
	oModelCXI:SetNoUpdateLine(.F.)
	CNTA300BlMd(oModelCXI,.F.) 		//- Libera o modelo
  	While CXI->( !Eof() ) .And. CXI->CXI_FILIAL == FwXFilial( 'CXI' ) .And. CXI->CXI_CONTRA == cContrat .And. CXI->CXI_REVISA == cRevisa .And. CXI->CXI_NUMPLA == cNumero
    	nCount ++
    	Do Case
    		Case ( nCount == 1 ) .And. ( nCount == oModelCXI:nLine )
      			nIncLine := nCount
    		Case ( nCount > 1 )
      			nIncLine := oModelCXI:AddLine()
      			If nCount # nIncLine
                    AEval( oModel:GetErrorMessage(), { | x |  cLogError += cValToChar( x ) + CRLF   } )
                    Help(" ",1,"CXILOAD-1",, STR0081 + CRLF + cLogError ,1,0)//"Nao Foi Possivel Criar uma Nova Linha nas Partes Envolvidas da Planilha Financeira"
        			lRet := .F.
        			Exit
      			EndIf
    	EndCase

    	If lRet
      		oModelCXI:GoLine( nIncLine )

      		For nInd := 1 To CXI->( FCount() )
      			//Proteção para o campo não usado
      			If FieldName( nInd ) <> "CXI_QUANT"
        			oModelCXI:LoadValue( CXI->( FieldName( nInd ) ), CXI->( FieldGet( nInd ) )  )
        		EndIf
      		Next nInd
      	EndIf
		CXI->( dbSkip() )
	EndDo
  	//Devolve para a posição original
	oModelCXI:SetNoUpdateLine(lCanUpdCXI)
EndIf

FwRestRows( aSaveLines )
RestArea( aCXIArea )
RestArea( aArea )
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121CNKIt()
Carrega pasta de Documentos do Contrato

@author Paulo V Beraldo
@since 20/08/2015
@version P12
@return .T.
/*/
//--------------------------------------------------------------------
Function Cn121CNKIt( oModel, oModelCNK )
Local lRet       := .T.
Local nCount     := 0
Local nLinAtu    := 0
Local nIncLine   := 0
Local nInd       := 0
Local aArea      := GetArea()
Local aCNKArea   := CNK->( GetArea() )
Local cLogError  := ""
Local aSaveLines := FWSaveRows()
Local cContrat   := oModel:GetModel( 'CXNDETAIL' ):GetValue( 'CXN_CONTRA' )

dbSelectArea( 'CNK' )
CNK->( dbSetOrder( 3 ) ) //CNK_FILIAL, CNK_CONTRA, CNK_TPDOC

CNTA300BlMd( oModelCNK ,.F.)
MtBCMod( oModel,{ 'CNKDETAIL' },{||.F.},'1' )

If !CNK->( dbSeek( FwXFilial( 'CNK' ) + cContrat  ) )
  lRet := .F.
Else
  While CNK->( !Eof() ) .And. CNK->CNK_FILIAL == FwXFilial( 'CNK' ) .And. CNK->CNK_CONTRA == cContrat
    nCount ++
    nLinAtu := MtFindMvc( oModelCNK,{ { 'CNK_CONTRA', CNK->CNK_CONTRA }, { 'CNK_CODIGO', CNK->CNK_CODIGO } } )

    If nLinAtu > 0
      nIncLine := nLinAtu
    Else
      Do Case
      Case ( nCount == 1 ) .And. ( nCount == oModelCNK:nLine )
        nIncLine := nCount
      Case ( nCount > 1 )
        nIncLine := oModelCNK:AddLine()
        If nCount # nIncLine
          AEval( oModel:GetErrorMessage(), { | x |  cLogError += cValToChar( x ) + CRLF   } )
          Help(" ",1,"CNKLOAD",, STR0082 + CRLF + cLogError ,1,0)//"Nao Foi Possivel Criar uma Nova Linha para a Inclusao dos Documentos"
          lRet := .F.
          Exit
        EndIf
      EndCase
    EndIf

    If lRet
      oModelCNK:GoLine( nIncLine )
      For nInd := 1 To CNK->( FCount() )
        oModelCNK:LoadValue( CNK->( FieldName( nInd ) ), CNK->( FieldGet( nInd ) )  )
      Next nInd
    EndIf

    CNK->( dbSkip() )
  EndDo
EndIf

CNTA300BlMd( oModelCNK ,.T.)
FwRestRows( aSaveLines )
RestArea( aCNKArea )
RestArea( aArea )
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121CNZIt()
Carrega Pasta do Rateio de Itens do Contrato

@author Paulo V Beraldo
@since 21/08/2015
@version P12
@return .T.
/*/
//--------------------------------------------------------------------
Function CN121CNZIt( oModel, oModelCNZ  )
Local lRet       := .T.
Local nCount     := 0
Local nIncLine   := 0
Local nInd       := 0
Local nYnd       := 0
Local nCpoVal    := 0
Local nPosCpo    := 0
Local cLogError  := ""
Local aCpoValor  := {'CNZ_VALOR1', 'CNZ_VALOR2', 'CNZ_VALOR3', 'CNZ_VALOR4', 'CNZ_VALOR5' }
Local aArea      := GetArea()
Local aCNZArea   := CNZ->( GetArea() )
Local aSaveLines := FWSaveRows()
Local oModelCNE  := oModel:GetModel( 'CNEDETAIL' )
Local cContrat   := oModelCNE:GetValue( 'CNE_CONTRA' )
Local cRevisa    := oModelCNE:GetValue( 'CNE_REVISA' )
Local cNumero    := oModelCNE:GetValue( 'CNE_NUMERO' )
Local cItemCt    := oModelCNE:GetValue( 'CNE_ITEM' )
Local cNumMed    := IIf( oModel:GetOperation() == MODEL_OPERATION_INSERT, CriaVar( 'CND_NUMMED', .F. ), oModel:GetModel( 'CNDMASTER' ):GetValue( 'CND_NUMMED' ) )

dbSelectArea( 'CNZ' )
CNZ->( dbSetOrder( 5 ) ) //CNZ_FILIAL+CNZ_CONTRA+CNZ_REVISA+CNZ_NUMMED+CNZ_CODPLA+CNZ_ITCONT+CNZ_ITEM

If !CNZ->( dbSeek( FwXFilial( 'CNZ' ) + cContrat + cRevisa + cNumMed + cNumero + cItemCt ) )
  lRet := .F.
Else
  While CNZ->( !Eof() ) .And. CNZ->CNZ_FILIAL == FwXFilial( 'CNZ' ) .And. CNZ->CNZ_CONTRA == cContrat .And. CNZ->CNZ_REVISA == cRevisa .And. CNZ->CNZ_NUMMED == cNumMed .And. CNZ->CNZ_CODPLA == cNumero .And. CNZ->CNZ_ITCONT == cItemCt
    nCount ++
    Do Case
    Case ( nCount == 1 ) .And. ( nCount == oModelCNZ:nLine )
      nIncLine := nCount
    Case ( nCount > 1 )
      nIncLine := oModelCNZ:AddLine()
      If nCount # nIncLine
        AEval( oModel:GetErrorMessage(), { | x | cLogError += cValToChar( x ) + CRLF } )
        Help(" ",1,"CNZLOAD",, STR0083 + CRLF + cLogError ,1,0)//"Nao Foi Possivel Criar uma Nova Linha para Incluir os Itens do Rateio "
        lRet := .F.
        Exit
      EndIf
    EndCase

    If lRet
      oModelCNZ:GoLine( nIncLine )
      For nInd := 1 To CNZ->( FCount() )
        nPosCpo := Ascan( aCpoValor, CNZ->( FieldName( nInd ) ) )

        If nPosCpo > 0
          For nYnd := 1 To oModelCNE:Length()
            oModelCNE:GoLine( nYnd )
            If !( oModelCNE:GetValue( 'CNE_NUMERO' ) == CNZ->CNZ_CODPLA .And. oModelCNE:GetValue( 'CNE_ITEM' ) == CNZ->CNZ_ITCONT )
              Loop
            Else
              If CNZ->( FieldGet( nInd ) ) > 0
                nCpoVal := Round( ( oModelCNE:GetValue( 'CNE_VLTOT' ) * CNZ->CNZ_PERC ) / 100, TamSx3( aCpoValor[ nPosCpo ] )[ 2 ] )
                oModelCNZ:LoadValue( CNZ->( FieldName( nInd ) ), xMoeda(nCpoVal,1,nPosCpo,dDatabase)  )
              EndIf
            EndIf
          Next nYnd
        Else
          oModelCNZ:LoadValue( CNZ->( FieldName( nInd ) ), CNZ->( FieldGet( nInd ) )  )
        EndIf

        oModelCNZ:SetValue( 'CNZ_NUMMED', oModel:GetModel( 'CNDMASTER' ):GetValue( 'CND_NUMMED' ) )
      Next nInd
    EndIf

    CNZ->( dbSkip() )
  EndDo
EndIf

FwRestRows( aSaveLines )
RestArea( aCNZArea )
RestArea( aArea )
Return lRet



//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121vlMul()
Processa a fórmula da multa, retornando o valor

@author jose.eulalio
@since 29/07/2015
@version P12
@return .T.
/*/
//--------------------------------------------------------------------
Function Cn121vlMul()
Local nValor	  := 0
Local lFormula := .F.

If Empty( CN4->CN4_VLDALT )
	lFormula := Formula( CN4->CN4_VALID )
Else
	lFormula := CNTA130Form( CN4->CN4_VLDALT )
	lFormula := IIf( !( ValType( lFormula ) == 'L' ) , .F. ,lFormula )
EndIf

If lFormula
	//Obtem o valor da multa
	If Empty( CN4->CN4_VLRALT )
		nValor := Formula( CN4->CN4_FORMUL )
	Else
		nValor := CNTA130Form( CN4->CN4_VLRALT)
		nValor := IIf( !( ValType( nValor ) == 'N' ), 0, nValor )
	EndIf
EndIf

Return nValor

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121ChgLn()
Libera a linha caso seja manual

@author jose.eulalio
@since 29/07/2015
@version P12
@return .T.
/*/
//--------------------------------------------------------------------
Function Cn121ChgLn(oView, cViewID,lPlan)
Local oModel 	:= FwModelActive()
Local oModCNR1	:= oModel:GetModel("CNRDETAIL1")
Local oModCNR2	:= oModel:GetModel("CNRDETAIL2")
Local oModBlq	:= Nil

Default lPlan	:= .T.

oModBlq := IIF(lPlan,oModCNR1,oModCNR2)

oModCNR1:GetStruct():SetProperty('CNR_MODO',MODEL_FIELD_WHEN,{||.F.})
oModCNR2:GetStruct():SetProperty('CNR_MODO',MODEL_FIELD_WHEN,{||.F.})

If oModBlq:GetValue("CNR_MODO") == "2"
	oModBlq:GetStruct():SetProperty('CNR_TIPO'	,MODEL_FIELD_WHEN,{||.T.})
	oModBlq:GetStruct():SetProperty('CNR_DESCRI',MODEL_FIELD_WHEN,{||.T.})
	oModBlq:GetStruct():SetProperty('CNR_VALOR'	,MODEL_FIELD_WHEN,{||.T.})
	oModBlq:GetStruct():SetProperty('CNR_FLGPED',MODEL_FIELD_WHEN,{||.T.})
	oModBlq:SetNoDeleteLine(.F.)
Else
	oModBlq:GetStruct():SetProperty('CNR_TIPO'	,MODEL_FIELD_WHEN,{||.F.})
	oModBlq:GetStruct():SetProperty('CNR_DESCRI',MODEL_FIELD_WHEN,{||.F.})
	oModBlq:GetStruct():SetProperty('CNR_VALOR'	,MODEL_FIELD_WHEN,{||.F.})
	oModBlq:GetStruct():SetProperty('CNR_FLGPED',MODEL_FIELD_WHEN,{||.F.})
	oModBlq:SetNoDeleteLine(.T.)
EndIf

Return Nil


//-------------------------------------------------------------------
/*/{Protheus.doc} CN121Act()
Pós-Ativação do modelo

@author jose.eulalio
@since 04/08/2015
@version P12
@return lRet
/*/
//--------------------------------------------------------------------
Function CN121Act(oModel)
Local oModelCND	:= oModel:GetModel("CNDMASTER")
Local oModelCNE	:= oModel:GetModel("CNEDETAIL")
Local oModelCXN	:= oModel:GetModel("CXNDETAIL")
Local oModelCNR1:= oModel:GetModel("CNRDETAIL1")
Local oModelCNR2:= oModel:GetModel("CNRDETAIL2")
Local oStruCNE	:= Nil
Local lAltera	:= oModel:GetOperation() == MODEL_OPERATION_UPDATE
Local lRet 		:= .T.
Local nX		:= 0
Local nI		:= 0
Local cIdPD		:= ""
Local cCodItem	:= ""

//Na ativação do modelo zera a variável de controle dos adiantamentos
aAdiants := {}

oModelCNR1:GetStruct():SetProperty('CNR_MODO'	,MODEL_FIELD_INIT,{||"2"})
oModelCNR2:GetStruct():SetProperty('CNR_MODO'	,MODEL_FIELD_INIT,{||"2"})
If IsExced()
	oModelCNE:GetStruct():SetProperty("CNE_EXCEDE" 	,MODEL_FIELD_INIT,{|| "1"})
EndIf


If lAltera
	oModelCND:GetStruct():SetProperty('CND_CONTRA'	,MODEL_FIELD_WHEN,{||.F.})
	oModelCND:GetStruct():SetProperty('CND_REVISA'	,MODEL_FIELD_WHEN,{||.F.})

	//- Bloqueia modelo de planilha
	If !IsExced()
		CNTA300BlMd(oModelCXN,.T.,.T.)
		MtBCMod(oModel,{"CXNDETAIL"},{||.F.},'1')
		oModelCXN:GetStruct():SetProperty("CXN_CHECK"	,MODEL_FIELD_WHEN,{||.T.})
		oModelCXN:GetStruct():SetProperty("CXN_DTVENC"	,MODEL_FIELD_WHEN,{||.T.})
		//- Bloqueia modelo de Itens pelo tipo da planilha
		CN121ChgPl()
	Else
		//Libera modelo
		oModelCNE:SetNoDeleteLine(.T.)
		oModelCNE:SetNoUpdateLine(.T.)
		oModelCNE:SetNoInsertLine(.F.)

		For nX := 1 To oModelCNE:Length()
			oModelCNE:Goline(nX)
			cIdPD := oModelCNE:GetValue("CNE_IDPED")
			If VAL(oModelCNE:GetValue("CNE_IDPED")) > VAL(cIdPD)
				cIdPD := oModelCNE:GetValue("CNE_IDPED")
			EndIf
		Next nX

		For nX := 1 To oModelCXN:Length()
			oModelCXN:Goline(nX)

			For nI := 1 To oModelCNE:Length()
				oModelCNE:Goline(nI)
				If !Empty(oModelCNE:GetValue("CNE_ITEM"))
					cCodItem := oModelCNE:GetValue("CNE_ITEM")
				Endif
			Next nI

			If oModelCXN:GetValue("CXN_CHECK")
				oStruCNE:= oModelCNE:GetStruct()
				cIdPD 	:= SOMA1(cIdPD)

				oStruCNE:SetProperty("CNE_NUMMED" 	,MODEL_FIELD_INIT,{|| oModelCND:GetValue('CND_NUMMED')})
				oStruCNE:SetProperty("CNE_NUMERO" 	,MODEL_FIELD_INIT,{|| oModelCXN:GetValue('CXN_NUMPLA')})
				oStruCNE:SetProperty("CNE_CONTRA" 	,MODEL_FIELD_INIT,{|| oModelCND:GetValue("CND_CONTRA")})
				oStruCNE:SetProperty("CNE_REVISA" 	,MODEL_FIELD_INIT,{|| oModelCND:GetValue("CND_REVISA")})
				oStruCNE:SetProperty("CNE_IDPED" 	,MODEL_FIELD_INIT,{|| cIdPD})
				oStruCNE:SetProperty("CNE_DTENT" 	,MODEL_FIELD_INIT,{|| dDataBase})
				oStruCNE:SetProperty("CNE_TES" 		,MODEL_FIELD_OBRIGAT,.T.)
				If cPaisLoc == "RUS"
					oStruCNE:SetProperty("CNE_CF" 		,MODEL_FIELD_OBRIGAT,.T.)
				EndIf
				//Adicona uma nova linha

				oModelCNE:AddLine()
				oModelCNE:SetNoDeleteLine(.T.)
				oModelCNE:SetNoUpdateLine(.F.)

				If oModelCNE:IsInserted()
					//Habilita edição de campos
					CN121ChgPl()
					Exit
				EndIf
			Endif
		Next nX
		oModelCNE:GoLine(1)
	EndIf
ElseIf AliasIndic('CXO') 
	CNTA300BlMd( oModel:GetModel('CXODETAIL') , .T. )
	CNTA300BlMd( oModel:GetModel('CXPDETAIL') , .T. )
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121VldChk()
Valid do Check box da CXN // CNA
@author jose.eulalio
@since 04/08/2015
@version P12
@return lRet
/*/
//--------------------------------------------------------------------
Function Cn121VldChk(oModelCXN,cField,xValue,nLine,xOldValue)
Local lRet		:= .T.
Local aArea     := GetArea()
Local aAreaCND  := CND->( GetArea() )
Local aAreaCXN  := CXN->( GetArea() )
Local aAreaCNA  := CNA->( GetArea() )
Local oModel	:= oModelCXN:GetModel()
Local oModelCNE	:= oModel:GetModel('CNEDETAIL')
Local oModelCND	:= oModel:GetModel('CNDMASTER')
Local cFilCXN	:= xFilial("CXN")
Local cFilCND	:= xFilial("CND")
Local cFilCNA	:= xFilial("CNA")
Local cCompet	:= ''
Local cNumPla 	:= oModelCXN:GetValue("CXN_NUMPLA")
Local cRevisa   := oModelCND:GetValue("CND_REVISA")
Local cContra   := oModelCND:GetValue("CND_CONTRA")
Local cChave	:= cFilCXN + cContra + cRevisa + cNumPla
Local cCNDCompe := ""
Local cNumMed   := ""
Local lServico	:= CN121RetSt("SERVIÇO"		, 0, cNumPla, cContra )
Local lRecorre	:= CN121RetSt("RECORRENTE"	, 0, cNumPla, cContra )
Local lEventual	:= CN121RetSt("MEDEVE"		, 0, cNumPla, cContra )
Local lSemifixo	:= CN121RetSt("SEMIFIXO"	, 0, cNumPla, cContra )

dbSelectArea( 'CND' )
CND->( dbSetOrder( 4 ) ) //CND_FILIAL+CND_NUMMED

dbSelectArea( 'CXN' )
CXN->( dbSetOrder( 2 ) ) //CXN_FILIAL+CXN_CONTRA+CXN_REVISA+CXN_NUMPLA

CursorWait()
//-----------------------------------------------
// Verifica se a planilha esta sendo utilizada em outra medição
// Contratos Recorrentes e Eventuais permitem ter mais de uma medição na mesma competência
//------------------------------------------------
If xValue

	If lAltera .And. oModelCNE:IsDeleted()
		CNTA300BlMd(oModelCNE,.F.,.F.)
		CNTA300DlMd(oModelCNE,"CNE_NUMERO",.F.)
		CNTA300BlMd(oModelCNE,.T.,.T.)
	Else

		cCNDCompe := AllTrim( oModelCND:GetValue("CND_COMPET") )
		
		If !lRecorre .And. !lEventual //Medicoes eventuais permitir na mesma competencia.
			cNumMed := oModelCND:GetValue("CND_NUMMED")
			
			CXN->( MsSeek( cChave ) )
			While cChave == cFilCXN + CXN->(CXN_CONTRA + CXN_REVISA + CXN_NUMPLA) .And. !(CXN->(Eof())) .And. lRet
				If cNumMed # CXN->CXN_NUMMED
		      		If CND->( MsSeek( cFilCND + CXN->CXN_NUMMED ) )
		      			If cCNDCompe == AllTrim( CND->CND_COMPET ) .And. oModelCXN:GetValue("CXN_PARCEL") == CXN->CXN_PARCEL .And. CXN->CXN_CHECK
							If lServico
								Help(" ",1,"CXNCHECKMED",,STR0154,1,0)//- "Não é possível realizar medições complementares em parcelas já realizadas para planilha de serviços."
								lRet := .F.
								Exit
							ElseIf !Alltrim(CND->CND_SITUAC) $ "E|FE" .And. (CXN->CXN_VLPREV - CXN->CXN_VLLIQD <= 0)
								Help(" ",1,"CXNCHECKMED",,STR0084,1,0)//"A planilha selecionada se encontra em uso por outra medição na mesma competencia."
								lRet := .F.
								Exit
				        	EndIf
				   		EndIf
					EndIf
				EndIf
				CXN->(DbSkip())
			EndDo
		
		ElseIf lRecorre
			
			cChave := cFilCNA + cContra + cRevisa + cNumPla
			dProMed := Posicione("CNA",1,cChave,"CNA_PROMED")
			cProMed := StrZero( Month( dProMed ), 2 ) + "/" + CValToChar( Year( dProMed ) )
			
			cCompet := cCNDCompe
					
			If AllTrim( cProMed ) <> cCompet
				Help("CXNPROMED",1,"CXNPROMED",, STR0085 + cProMed,1,1)//"Para marcar a planilha recorrente é necessário mudar a competência para "
				lRet := .F.
			Endif
			
		ElseIf lSemifixo
		
			If oModelCXN:GetValue("CXN_VLSALD") == 0
				Help(" ",1,"CXNSLDMED")
				lRet := .F.
			EndIf
			
		EndIf
		
		// Efetua Carga e Atualiza totalizadores
		If lRet
			oModelCNE:GoLine(1)
			If Empty(oModelCNE:GetValue("CNE_NUMERO"))
				CN121Item( xValue,, oModel, cNumPla, cContra )
				CN121Agrup(oModel)
				CN121CXIIt(oModel)
				If CnGatMNat()
					CnCrgMNat(oModel)
				EndIf
			EndIf
			CN121CNRPl(oModel,oModelCXN)
		EndIf
	EndIf
	
ElseIf !xValue .And. xOldValue //--Caso a planilha seja desmarcada devo limpar os itens
	
	CNTA300BlMd(oModelCNE,.F.,.F.)
	CNTA300DlMd(oModelCNE,"CNE_NUMERO",.F.)
	CNTA300BlMd(oModelCNE,.T.,.T.)
	
EndIf
CursorArrow()

RestArea( aAreaCXN )
RestArea( aAreaCND )
RestArea( aAreaCNA )
RestArea(aArea)
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121Limpa()
Limpa variaveis estáticas antes do final da função.
@author israel.escorizza
@since 11/08/2015
@version P12
@return .T.
/*/
//--------------------------------------------------------------------
Function CN121Limpa()
Local oModel := FwModelActive()
lServico := .F.
lAutForn := .F.
IIf( ValType( oModel ) == 'O' .And. oModel:IsActive() .And. oModel:GetId() == "CNTA121", oModel:Deactivate(), Nil )
Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121Compet
Funcao que carrega grid das planilhas após selecionar competência
@author Rogerio Melonio
@since 11/08/2015
/*/
//-------------------------------------------------------------------
Function CN121Compet()
Local oModel	:= FWModelActive()
Local cCompet	:= oModel:GetValue("CNDMASTER","CND_RCCOMP")

If( Type("nTipo")=="N", Nil, nTipo := 1)
If( Type("lExced")=="L", Nil, lExced := lExcedNPrv)
If( Type("cFilCTR")=="C", Nil, cFilCTR := cFilAnt)
If( Type("cValue")=="C", Nil, cValue := "")

If !IsInCallStack("CN121CBOX")
	CN120Compet(lExced,cFilCTR)
Endif
Return cCompet

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121VldPlan
Funcao que posiciona o grid de itens da medição na primeira linha do modelo
@author Rogerio Melonio
@since 12/08/2015
/*/
//-------------------------------------------------------------------
Static Function CN121VldPlan()
Local oModel 	:= FWModelActive()
Local lMod121	:= oModel:GetId() == "CNTA121"
Local oModelCNE	:= oModel:GetModel('CNEDETAIL')
Local oModelCXN	:= oModel:GetModel('CXNDETAIL')
Local aSaveLines:= FWSaveRows()
Local lRet 		:= .T.

If lMod121
	oModelCNE:GoLine(1)
	oModelCXN:GoLine(1)
	oModelCXN:SetNoInsertLine(.T.)
EndIf

FWRestRows( aSaveLines )

Return lRet

//------------------------------------------------------------------
/*/{Protheus.doc} CN121TudOk()
Tudo Ok do Modelo
@author jose.eulalio
@since 14/08/2015
@version P12
@return .T.
/*/
//--------------------------------------------------------------------
Function Cn121TudOk(oModel)
Local lRet       := .T.
Local oModelCND  := oModel:GetModel("CNDMASTER")
Local oModelCXN  := oModel:GetModel("CXNDETAIL")
Local oModelCNE  := oModel:GetModel("CNEDETAIL")
Local oModelCXO  := Nil
Local oModelCXP  := Nil
Local lVenda     := CN121RetSt("VENDA",,,oModelCXN:GetValue("CXN_CONTRA"),.T.,oModel)
Local lInclui    := oModel:GetOperation() == MODEL_OPERATION_INSERT
Local lAltera    := oModel:GetOperation() == MODEL_OPERATION_UPDATE
Local lExclui    := oModel:GetOperation() == MODEL_OPERATION_DELETE
Local lNotaEmp   := SuperGetMV("MV_NOTAEMP",.F.,.F.)
Local lNoTes     := .T.
Local nI         := 0
Local nX         := 0
Local nY         := 0
Local nTotPla    := 0
Local lMark      := .F.
Local aSaveLines := FWSaveRows()
Local lSemiFix   := Cn121RetSt( "SEMIFIXO",,,, .T., oModel )

If (lExclui .Or. lAltera) .And. lAutForn
	lRet := Cn121DelPed(oModel)
EndIf

// não precisa passar por aqui na exclusão, quando a CN121GRV chama a VldData() obrigatoriamente passa por aqui
If lRet .And. lExclui .And. IsInCallStack("CN121GRV")
	lRet	:= Cn121Exc()
EndIf

If lRet .And. AliasIndic('CXO') .And. !lExclui
	oModelCXO	:= oModel:GetModel("CXODETAIL")
	oModelCXP	:= oModel:GetModel("CXPDETAIL")
	lRet := CnMNPosMd(oModelCXN,oModelCXO,oModelCXP)
EndIf

If !IsExced()
	If lRet .And. !lExclui
		nI := 1
		While lRet .And. nI <= oModelCXN:Length()
			oModelCXN:GoLine(nI)
			lMark := lMark .Or. oModelCXN:GetValue('CXN_CHECK')
			lRet := CN121LimPla(oModel) .And. CN121VldRt(oModelCNE)
			nI++
		EndDo
		If !lMark
			lRet := .F.
			Help("",1,"CN121NOPL") //- "Não foram selecionadas planilhas para realizar a medição.|Selecione uma planilha"
		EndIf
	EndIf

	If lRet .And. !lExclui
		For nX := 1 To oModelCXN:Length()
			nTotPla := 0
			oModelCXN:GoLine(nX)
				If oModelCXN:GetValue("CXN_CHECK")
					For nY := 1 To oModelCNE:Length()
						oModelCNE:GoLine(nY)
						nTotPla += oModelCNE:GetValue("CNE_QUANT")
						
						If ( lVenda .And. oModelCNE:GetValue("CNE_PEDTIT") == '1' .And. Empty(oModelCNE:GetValue("CNE_TES")) )
							lRet := .F.
							lNoTes := .F.							
							Exit
						EndIf
						
					Next nY
					
					If !lRet .And. !lNoTes
						Exit
					EndIf
					
					//- Valida inclusão de medição para valores zerados com campo CXN_ZERO (Med. Zerada)
					If CXN->( Columnpos('CXN_ZERO') ) > 0	//- Proteção para medição zerada.
						If nTotPla == 0
							If oModelCXN:GetValue("CXN_ZERO") == "0"
								lRet := .F.
								Exit
							EndIf
						Else
							If !Empty(oModelCXN:GetValue("CXN_ZERO")) .And. !oModelCXN:GetValue("CXN_ZERO") == "0"
								lRet := .F.
								Exit
							EndIf
						EndIf
					Else
						If nTotPla == 0
							lRet := .F.
							Exit
						EndIf
					EndIf
				EndIf
		Next nX
		
		If !lRet
			If lVenda .And. !lNoTes
				Help("",1,'SEMTESITEM',,STR0189,1,1)//"O código do TES não foi informado. Informar o Tipo de Saída no item."
			ElseIf lSemiFix
				Help("",1,'SEMIFQTD',,STR0087,1,1) 	//- "Preencha a quantidade para a planilha Semi-fixa para poder realizar a gravação!"
			Else
				Help("",1,'CN121VLMED')	//- "Existem planilhas com quantidades invalidas. | Verifique a quantidade dos itens das planilhas selecionadas. Para planilhas de medição zerada, a quantidade dos itens deve ser obrigatoriamente 0 (zero)."
			EndIf
		EndIf
	EndIf

	If lRet .And. lNotaEmp
		CN9->(dbSetOrder(1)) //-- CN9_FILIAL+CN9_NUMERO+CN9_REVISA
		CN9->(dbSeek(xFilial("CN9")+oModelCND:GetValue("CND_CONTRA")))
		If !Empty(CN9->CN9_CODED) .And. GCPSCED(CN9->CN9_CODED, CN9->CN9_NUMPR)
			For nI := 1 To oModelCNE:Length()
				oModelCNE:GoLine(nI)
				If Empty(oModelCNE:GetValue("CNE_CODNE")) .Or. Empty(oModelCNE:GetValue("CNE_ITEMNE"))
					lRet := .F.
					Help("",1,'SEMNOTEMP ',,STR0086,1,1)//"A medição não pode ser gravada, digite o codigo ou o item da nota de empenho"
				EndIf
			Next
		EndIf
	EndIf
ElseIf (lInclui .Or. lAltera) .And. lExcedNPrv

	For nI := 1 To oModelCNE:Length()
		oModelCNE:GoLine(nI)
		If Empty(oModelCNE:GetValue("CNE_TES"))
			lRet := .F.
			Help("",1,'SEMTESITEM',,STR0067,1,1)//"O código do TES não foi informado. Informar o Tipo de Saída no item"
		EndIf
	Next

EndIf

FWRestRows(aSaveLines)
Return lRet


//-------------------------------------------------------------------
/*/{Protheus.doc} CN121Exc()
Exclui Medição
@author jose.eulalio
@since 11/08/2015
@version P12
@return .T.
/*/
//--------------------------------------------------------------------
Function Cn121Exc()
Local oModel	:= FwModelActive()
Local oModelCND	:= oModel:GetModel('CNDMASTER')
Local oModelCXN	:= oModel:GetModel('CXNDETAIL')
Local dDataBloq	:= GetNewPar("MV_ATFBLQM",CTOD("")) //Data de Bloqueio da Movimentação - MV_ATFBLQM
Local cFilCtr 	:= Iif(!Empty(CND->CND_FILCTR),CND->CND_FILCTR,xFilial("CND"))
Local aArea2 	:= GetArea()
Local nOpc		:= 5 //Exclusão
Local nReg 		:= CND->(Recno())
Local nTipo 	:= If(CND->CND_AUTFRN=="1",1,2)
Local lContinua	:= .T.
Local nX 		:= 0

//Verifica se existe bloqueio contábil
If lContinua .And. (lContinua := CtbValiDt(Nil, dDataBase,/*.T.*/ ,Nil ,Nil ,{"GCT001"}/*,"Data de apuração bloqueada pelo calendário contábil."*/))
	If!Empty(dDataBloq) .AND. ( dDataBase <= dDataBloq)
		Help(" ",1,"ATFCTBBLQ") //P: Processo bloqueado pelo Calendário Contábil ou parâmetro de bloqueio nesta data ou período. S: Caso possível altere a data de referência do processo, verifique o parâmetro ou contate o responsável pelo Módulo Contábil.)
		lContinua := .F.
	End
EndIf

If lContinua
	lContinua := CN240VldUsr(CND->CND_CONTRA,DEF_TRAEXC_MED,.T.,,cFilCtr)
EndIf

RestArea(aArea2)

If lContinua
	If Empty(CND->CND_DTFIM)
		If nTipo == 2 .And. !Empty(CND->CND_PEDIDO) //- Estorna pedido de compra
			Processa( {|| lRet := CN121MedEst( CND->( RECNO() ) , 2 , .F., .T. ) } )
		EndIf

		If oModelCND:GetValue("CND_TOTADT") > 0 //- Atualiza os Descontos
			//CnGrvAdia(,nOpc)
			Cn121GrvAd(,nOpc)
		EndIf

		PcoDetLan("000355","01","CNTA120",.T.) //- Executa lancamento do PCO ³

		//CN130Grv(nOpc,,,,,,,,,nTipo)
	Else
		lContinua	:= .F.
		Help( " ", 1, "CNTA120_03" )//"Medição ja encerrada"
	EndIf
EndIf

Return lContinua

//------------------------------------------------------------------
/*/{Protheus.doc} CN121GRV()
Função de gravação da medição
@author alexandre.gimenez
@since 20/08/2015
/*/
//-------------------------------------------------------------------
Function CN121GRV(oModel)
Local oModelCND := oModel:GetModel('CNDMASTER')
Local oModelCXN	:= oModel:GetModel('CXNDETAIL')
Local oModelCNE	:= oModel:GetModel('CNEDETAIL')
Local oModelTOT	:= oModel:GetModel('TOTMED')

Local cNumMed	:= oModelCND:GetValue("CND_NUMMED")
Local cOpc		:= oModel:GetOperation()
Local nStack 	:= 0
Local nX		:= 0
Local nY		:= 0

Local lCompra	:= CN121RetSt("COMPRA",/**/,/**/,oModelCXN:GetValue("CXN_CONTRA"),.T.,oModel)
Local lInclui	:= cOpc == MODEL_OPERATION_INSERT
Local lAltera	:= cOpc == MODEL_OPERATION_UPDATE
Local lExclui	:= cOpc == MODEL_OPERATION_DELETE
Local lEncAut	:= .F.
Local lRet	 	:= .T.
Local lPeGrP	:= ExistBlock("CN121GPD")
Local lGrPed	:= .T.

If !lExclui
	//-Carrega os Totalizadores no modelo da CND
	oModelCND:LoadValue('CND_VLPREV',oModelTOT:GetValue('CND_VLPREV'))
	oModelCND:LoadValue('CND_VLLIQD',oModelTOT:GetValue('CND_VLLIQD'))
	oModelCND:LoadValue('CND_VLMULT',oModelTOT:GetValue('CND_VLMULT'))
	oModelCND:LoadValue('CND_VLBONI',oModelTOT:GetValue('CND_VLBONI'))
	oModelCND:LoadValue('CND_DESCME',oModelTOT:GetValue('CND_DESCME'))
	oModelCND:LoadValue('CND_TOTADT',oModelTOT:GetValue('CND_TOTADT'))
	oModelCND:LoadValue('CND_RETCAC',oModelTOT:GetValue('CND_RETCAC'))
	oModelCND:LoadValue('CND_VLTOT',oModelTOT:GetValue('CND_VLTOT'))

	//-- Preenche valor liquido dos itens
	If oModelCNE:HasField('CNE_VLLIQD') .And. (lInclui .Or. lAltera) .And. !lEncerra
		Cn121Liq(oModel)
	EndIf
EndIf

Begin Transaction

	If lEncerra .Or. lExcedMEnc
	
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Chama ponto de entrada para verificar se gera pedido. ³
		//³Podera ser utilizado para aglutinar varias medicoes e |
		//³somente apos realizar a geracao do pedido.            |
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If lEncerra .And. lPeGrP
			lGrPed := ExecBlock("CN121GPD",.f.,.f.)
		EndIf
		
		If lGrPed 
			lRet := CN121GerDoc(oModel)
		EndIf

	ElseIf !lExclui
		//- Define Variaveis de Med. Serviço e Aut. Fornecimento
		oModelCND:SetValue("CND_SERVIC",'1')
		oModelCND:SetValue("CND_AUTFRN",Iif(lAutForn,'2','1'))

		oModelCNE:SetNoInsertLine( .F. )
		oModelCNE:SetNoDeleteLine( .F. )

		//- Percorre CXN relizando ações complementares antes da gravação.
		For nX := 1 to oModelCXN:Length()
			oModelCXN:GoLine(nX)
			//- Grava Campo de fornecedor ou cliente de acordo com o contrato.
			If lInclui
				If lCompra
					oModelCXN:GetStruct():SetProperty("CXN_FORNEC",MODEL_FIELD_WHEN,{||.T.})
					oModelCXN:GetStruct():SetProperty("CXN_LJFORN",MODEL_FIELD_WHEN,{||.T.})
					oModelCXN:LoadValue("CXN_FORNEC",oModelCXN:GetValue("CXN_FORCLI"))
					oModelCXN:LoadValue("CXN_LJFORN",oModelCXN:GetValue("CXN_LOJA"))
					oModelCXN:GetStruct():SetProperty("CXN_FORNEC",MODEL_FIELD_WHEN,{||.F.})
					oModelCXN:GetStruct():SetProperty("CXN_LJFORN",MODEL_FIELD_WHEN,{||.F.})
				Else
					oModelCXN:GetStruct():SetProperty("CXN_CLIENT",MODEL_FIELD_WHEN,{||.T.})
					oModelCXN:GetStruct():SetProperty("CXN_LJCLI",MODEL_FIELD_WHEN,{||.T.})
					oModelCXN:LoadValue("CXN_CLIENT",oModelCXN:GetValue("CXN_FORCLI"))
					oModelCXN:LoadValue("CXN_LJCLI",oModelCXN:GetValue("CXN_LOJA"))
					oModelCXN:GetStruct():SetProperty("CXN_CLIENT",MODEL_FIELD_WHEN,{||.F.})
					oModelCXN:GetStruct():SetProperty("CXN_LJCLI",MODEL_FIELD_WHEN,{||.F.})
				EndIf
			EndIf
			
			If !oModelCXN:GetValue("CXN_CHECK") //- Remove Planilha sem Marcação
				CN121Grids( oModel , .F. )
			EndIf
		Next Nx

		//- Define situação da Medição.
		lRet:= CN121Situa(oModel)

		//Processa os Adiantamentos
		If lRet .And. oModelCND:GetValue("CND_TOTADT") > 0
			Cn121GrvAd(aAdiants,cOpc)
		EndIf

		If lRet .And. oModelCND:GetValue('CND_AUTFRN') == '2'
			//- Autorização de fornecimento necessita do modelo gravado para poder gerar pedido.
			If lInclui .And. (lRet := (oModel:VldData() .And. FwFormCommit(oModel)))
				nStack := GetSX8Len()
				While ( GetSX8Len() > nStack )
					ConfirmSX8()
				EndDo

			ElseIf lAltera .And. (lRet := CN121MedEst(CND->(Recno()),.F.,.T.,.F.))
				lRet := (oModel:VldData() .And. FwFormCommit(oModel))
			EndIf

			If lRet
				lRet := CN121Encerr(.T.)
				lEncAut := lRet
			EndIf
		EndIf

	ElseIf lExclui
		Cn121GrvAd(aAdiants,MODEL_OPERATION_DELETE)
		If oModelCND:GetValue('CND_AUTFRN') == '2'
			lRet := CN121MedEst(CND->(Recno()),.T.,.T.,.F.)
		EndIf
	EndIf

	If lRet .And. !lEncAut .And. (lRet := FwFormCommit(oModel))
		If lInclui
			nStack := GetSX8Len()
			While ( GetSX8Len() > nStack )
				ConfirmSX8()
			EndDo
		EndIf
	EndIf

	If !lRet
		DisarmTransaction()
	EndIf
End Transaction

//- Controle de Alçadas
If lRet .And. !isInCallStack('Cn121MedEnc')
	CN121AlcMd(oModel)
EndIf

Return lRet
//------------------------------------------------------------------
/*/{Protheus.doc} Cn121AlcMd
Função de controle de Alçadas
@author israel.escorizza
@since 02/09/2015
/*/
//-------------------------------------------------------------------
Function Cn121AlcMd(oModel)
Local oModelCND	:= Nil
Local lInclui	:= .F.
Local lAltera	:= .F.
Local lExclui	:= .F.
Local lAlcada	:= Iif(SuperGetMv("MV_CNMDALC",.F.,"N")=="S",.T.,.F.)
Local cNumMed	:= ""
Local aCampos	:={}
Default oModel	:= FwModelActive()

oModelCND:= oModel:GetModel('CNDMASTER')
lInclui	:= oModel:GetOperation() == MODEL_OPERATION_INSERT
lAltera := oModel:GetOperation() == MODEL_OPERATION_UPDATE
lExclui := oModel:GetOperation() == MODEL_OPERATION_DELETE
cNumMed	:= oModelCND:GetValue("CND_NUMMED")

If lAlcada
	DO CASE
		CASE lInclui .OR. lAltera
				aAdd(aCampos,{	oModelCND:GetValue("CND_NUMMED"),;
									"MD",;
									oModelCND:GetValue("CND_VLTOT"),;
									"",;
									"",;
						 			oModelCND:GetValue("CND_APROV"),;
						 			"",;
						 			oModelCND:GetValue("CND_MOEDA"),;
						 			0,;
						 			oModelCND:GetValue("CND_DTINIC");
						 		})

				//- Na alteração deleta documentos de alçada e gera novos.
				If lAltera
					GCTAlcEnt(oModel,oModel:GetOperation(),3,"MD",cNumMed,oModelCND:GetValue("CND_REVISA"),aCampos,.T.)
				EndIf

				GCTAlcEnt(oModel,oModel:GetOperation(),1,"MD",cNumMed,oModelCND:GetValue("CND_REVISA"),aCampos,.T.)

		CASE lExclui
			aAdd(aCampos,{	cNumMed,;
								"MD",;
								oModelCND:GetValue("CND_VLTOT"),;
								"",;
								"",;
					 			oModelCND:GetValue("CND_APROV"),;
					 			"",;
					 			oModelCND:GetValue("CND_MOEDA"),;
					 			0,;
					 			oModelCND:GetValue("CND_DTINIC");
		 		})

		 		GCTAlcEnt(oModel,oModel:GetOperation(),3,"MD",cNumMed,oModelCND:GetValue("CND_REVISA"),aCampos,.T.)
		ENDCASE
EndIf

Return

//------------------------------------------------------------------
/*/{Protheus.doc} CN121Inc()
Função de Inclusão
@author alexandre.gimenez
@since 21/08/2015
/*/
//-------------------------------------------------------------------
Function CN121Inc()
Local cModel:= 'CNTA121'

lInclui := .T.
aComp	:= {}
FWExecView(STR0088,cModel,MODEL_OPERATION_INSERT,,{|| .T.})//"Inclusão de Medição"
lInclui := .F.
Return

//------------------------------------------------------------------
/*/{Protheus.doc} CN121Alt()
Função de alteração
@author Israel.Escorizza
@since 29/06/2017
/*/
//-------------------------------------------------------------------
Function CN121Alt()
Local cModel:= 'CNTA121'
lAltera	:= .T.
lAutForn:= CND->CND_AUTFRN == '2'
aComp	:= {}

//Verifica se a medição é excedente para competência não prevista
If GCTExcedNP(CND->CND_NUMMED)
	SetExcedNP(.T.)
EndIf

If Cn121OriMd('CNTA120')
 	Aviso(STR0079,STR0127+CRLF+STR0128+CRLF+CRLF+STR0125+CRLF+STR0126,{STR0156},2) //- Opção indisponivel para medições realizadas com a rotina de medições padrão.
Else
	FWExecView(STR0054,cModel,MODEL_OPERATION_UPDATE,,{|| .T.})//"Alteração de Medição"
EndIf
lAltera := .F.
lAutForn:= .F.
Return

//------------------------------------------------------------------
/*/{Protheus.doc} CN121Vis()
Função de visualização
@author Israel.Escorizza
@since 29/06/2017
/*/
//-------------------------------------------------------------------
Function CN121Vis()
Local cModel:= 'CNTA121'

aComp	:= {}
If Cn121OriMd('CNTA120')
 	Aviso(STR0079,STR0127+CRLF+STR0128+CRLF+CRLF+STR0125+CRLF+STR0126,{STR0156},2) //- Opção indisponivel para medições realizadas com a rotina de medições padrão.
Else
	FWExecView(STR0055,cModel,MODEL_OPERATION_VIEW,,{|| .T.})//"Visualização de Medição"
EndIf
Return

//------------------------------------------------------------------
/*/{Protheus.doc} CN121Exc()
Função de visualização
@author Israel.Escorizza
@since 29/06/2017
/*/
//-------------------------------------------------------------------
Function CN121Excl()
Local cModel:= 'CNTA121'
lAutForn 	:= CND->CND_AUTFRN == '2'
aComp	:= {}

If Cn121OriMd('CNTA120')
 	Aviso(STR0079,STR0127+CRLF+STR0128+CRLF+CRLF+STR0125+CRLF+STR0126,{STR0156},2) //- Opção indisponivel para medições realizadas com a rotina de medições padrão.
Else
	FWExecView(STR0056,cModel,MODEL_OPERATION_DELETE,,{|| .T.})//"Exclusão de Medição"
EndIf

lAutForn := .F.
Return

//------------------------------------------------------------------
/*/{Protheus.doc} CN121Prt()
Função de visualização
@author Israel.Escorizza
@since 29/06/2017
/*/
//-------------------------------------------------------------------
Function CN121Prt()
aComp	:= {}
If Cn121OriMd('CNTA120')
 	Aviso(STR0079,STR0127+CRLF+STR0128+CRLF+CRLF+STR0125+CRLF+STR0126,{STR0156},2) //- Opção indisponivel para medições realizadas com a rotina de medições padrão.
Else
	CNTR031(CND->CND_NUMMED)
EndIf
Return

//------------------------------------------------------------------
/*/{Protheus.doc} CN121TES()
Função que atualiza tes
@author alexandre.gimenez
@since 21/08/2015
/*/
//-------------------------------------------------------------------
Static Function CN121TES()
Local oModel 	:= FwModelActive()
Local cContra	:= oModel:GetValue('CNDMASTER','CND_CONTRA')
Local cRet 		:= ""

If CN121RetSt("COMPRA",/**/,/**/,cContra)
	oModel:SetValue('CNEDETAIL',"CNE_TE",oModel:GetValue('CNEDETAIL',"CNE_TES"))
Else
	oModel:SetValue('CNEDETAIL',"CNE_TS",oModel:GetValue('CNEDETAIL',"CNE_TES"))
EndIf

Return cRet

//------------------------------------------------------------------
/*/{Protheus.doc} CN121VldTES()
Função que Valida tes
@author alexandre.gimenez
@since 21/08/2015
/*/
//-------------------------------------------------------------------
Static Function CN121VldTES()
Local oModel 	:= FwModelActive()
Local cContra	:= oModel:GetValue('CNDMASTER','CND_CONTRA')
Local lRet		:= .T.

If ('CNE_TS' $ AllTrim(ReadVar())) .Or. ('CNE_TE' $ AllTrim(ReadVar()))
  If CN121RetSt("COMPRA",/**/,/**/,cContra)
    lRet := cn130VldTE(oModel:GetValue("CNEDETAIL","CNE_TES"))
  Else
    lRet := cn130VldTS(oModel:GetValue("CNEDETAIL","CNE_TES"))
  EndIf
EndIf

Return lRet


//------------------------------------------------------------------
/*/{Protheus.doc} CN121IniTES()
Função inicializador padrao de  tes
@author alexandre.gimenez
@since 21/08/2015
/*/
//-------------------------------------------------------------------
Static Function CN121IniTES()
Local cRet := ""

If !lInclui
	If CN121RetSt("COMPRA",/**/,/**/,CND->CND_CONTRA)
		cRet := CNE->CNE_TE
	Else
		cRet := CNE->CNE_TS
	EndIf
EndIf

Return cRet

//------------------------------------------------------------------
/*/{Protheus.doc} CN121ChgPl()
Change Line de Planilha. Libera e Bloqueia Modelo conforme tipo de planilha.
Refaz Totalizadores
@author alexandre.gimenez
@since 23/08/2015
/*/
//-------------------------------------------------------------------
Static Function CN121ChgPl( lOpenAll, lCheck, oModel )
Local oModelCXN	:= Nil
Local oModelCNE	:= Nil
Local lInclui	:= .F.
Local lAltera	:= .F.
Local cContra	:= ""
Local cPlan		:= ""
Local lFisico	:= .F.
Local lFixo		:= .F.
Local lMedEve	:= .F.
Local lSemiProd	:= .F.
Local lRecorre	:= .F.
Local lServico	:= .F.
Local lCompra	:= .F.
Local aBlkCpo	:= {}
Local nX		:= 0
Local nY		:= 0
Local lRet 		:= .T.

Default lOpenAll := .F.
Default oModel := FwModelActive()
Default lCheck := oModel:GetValue("CXNDETAIL","CXN_CHECK")

oModelCXN := oModel:GetModel("CXNDETAIL")
oModelCNE := oModel:GetModel("CNEDETAIL")
lInclui	:= oModel:GetOperation() == MODEL_OPERATION_INSERT
lAltera	:= oModel:GetOperation() == MODEL_OPERATION_UPDATE
cContra	:= oModelCXN:GetValue("CXN_CONTRA")
cPlan := oModelCXN:GetValue("CXN_NUMPLA")

lFisico	:= Cn121RetSt( 'FISICO', 0, cPlan, cContra, .T., oModel )
lFixo := Cn121RetSt( 'FIXO', 0, cPlan, cContra, .T., oModel )
lMedEve	:= Cn121RetSt( 'MEDEVE', 0, cPlan, cContra, .T., oModel )
lSemiProd := Cn121RetSt( 'SEMIPROD', 0, cPlan, cContra, .T., oModel )
lRecorre := Cn121RetSt( 'RECORRENTE', 0, cPlan, cContra, .T., oModel )
lServico := Cn121RetSt( 'SERVIÇO', 0, cPlan, cContra, .T., oModel )
lCompra	:= Cn121RetSt( "COMPRA", 0, cPlan, cContra, .T., oModel )

If !IsExced()
	If !lCheck
		CNTA300BlMd(oModel:GetModel('CNEDETAIL'),.T.) //- Bloqueia o Modelo
		MtBCMod(oModel,{'CNEDETAIL'},{||.F.},'1') //- Bloqueia todos os campos
	Else
		CNTA300BlMd(oModel:GetModel('CNEDETAIL'),.F.) //- Libera o Modelo
		MtBCMod(oModel,{'CNEDETAIL'},{||.T.},'1') //- Libera todos os campos
		If !lOpenAll
			If lInclui .Or. lAltera
				//Quando não for por excedente de competencia não prevista
				If !IsExced().And. oModelCNE:GetValue("CNE_EXCEDE") <> "1"
					If lFixo .Or. lSemiProd
						aAdd(aBlkCpo,'CNE_PRODUT')
						aAdd(aBlkCpo,'CNE_PDESC' )
						aAdd(aBlkCpo,'CNE_PRODSV' )

						If !lServico
							aAdd(aBlkCpo,'CNE_VLUNIT')
						EndIf

						If lServico
							aAdd(aBlkCpo,'CNE_QUANT')
							aAdd(aBlkCpo,'CNE_PERC' )
						EndIf

						If lFisico
							aAdd(aBlkCpo,'CNE_VLTOT')
						EndIf

						If lSemiProd
							aAdd(aBlkCpo,'CNE_PERC')
						EndIf
						
						If CNE->( ColumnPos( "CNE_ARREND" ) ) > 0
							aAdd( aBlkCpo, "CNE_ARREND" )
						EndIf
						
						If lInclui
							CNTA300BlMd(oModel:GetModel('CNEDETAIL'),.T.,.T.)
						EndIf
						MtBCMod(oModel,{{'CNEDETAIL',aBlkCpo}},{||.F.},'2')
					Else
						aAdd(aBlkCpo,'CNE_QTDSOL')
						aAdd(aBlkCpo,'CNE_SDAMED')
						aAdd(aBlkCpo,'CNE_PERC'  )
					EndIf
				Else
					MtBCMod(oModel,{'CNEDETAIL'},{||.F.},'1') //- Bloqueia todos os campos
					//Libera somente os campos para alteração
					aAdd(aBlkCpo,'CNE_PRODUT')
					aAdd(aBlkCpo,'CNE_DESCRI')
					aAdd(aBlkCpo,'CNE_QUANT')
					aAdd(aBlkCpo,'CNE_VLUNIT')
					aAdd(aBlkCpo,'CNE_TES')
					aAdd(aBlkCpo,'CNE_TS')
					If cPaisLoc == "RUS"
						aAdd(aBlkCpo,'CNE_CF')
					EndIf
					aAdd(aBlkCpo,'CNE_PERC')
					aAdd(aBlkCpo,'CNE_VLTOT')
					CNTA300BlMd(oModel:GetModel('CNEDETAIL'),.T.,.T.)
					MtBCMod(oModel,{{'CNEDETAIL',aBlkCpo}},{||.T.},'2')
				EndIf

				If CN121RetSt( 'MULMAN', 0, cPlan, cContra, .T., oModel ) == '1'
					CNTA300BlMd(oModel:GetModel('CNRDETAIL1'),.T.) //- Bloqueia o Modelo
					CNTA300BlMd(oModel:GetModel('CNRDETAIL2'),.T.) //- Bloqueia o Modelo
				EndIf

			Else
				MtBCMod(oModel,{'CNEDETAIL'},{||.F.},'1')
			EndIf
		EndIf
	EndIf
Else
	MtBCMod(oModel,{'CNEDETAIL'},{||.F.},'1') //- Bloqueia todos os campos
	aAdd(aBlkCpo,'CNE_PRODUT')
	aAdd(aBlkCpo,'CNE_DESCRI')
	aAdd(aBlkCpo,'CNE_QUANT')
	aAdd(aBlkCpo,'CNE_VLUNIT')
	aAdd(aBlkCpo,'CNE_TES')
	aAdd(aBlkCpo,'CNE_TS')
	If cPaisLoc == "RUS"
		aAdd(aBlkCpo,'CNE_CF')
	EndIf
	aAdd(aBlkCpo,'CNE_VLTOT')
	aAdd(aBlkCpo,'CNE_PEDTIT')
	aAdd(aBlkCpo,'CNE_IDPED')
	aAdd(aBlkCpo,'CNE_TABPRC')

	MtBCMod(oModel,{{'CNEDETAIL',aBlkCpo}},{||.T.},'2')
EndIf

Return lRet

//------------------------------------------------------------------
/*/{Protheus.doc} CN121Encerr()
Rotina de encerramento de medição
@author alexandre.gimenez
@since 23/08/2015
/*/
//-------------------------------------------------------------------
Function CN121Encerr(lAuto,lAprRev)
Local lRet 		:= .F.
Local lContinua	:= .T.
Local lAutFor	:= CND->CND_AUTFRN == '2'
Local dDataBloq	:= GetNewPar("MV_ATFBLQM",CTOD("")) //Data de Bloqueio da Movimentação - MV_ATFBLQM
Local cFilCTR 	:= cFilAnt
Local lReinf	:= CNE->( Columnpos('CNE_15ANOS') ) > 0 

DEFAULT lAuto 	:= IsInCallStack("CNTA260")
DEFAULT lAprRev := .F.

If Cn121OriMd('CNTA120')
 	CN120Ence('CND',CND->(Recno()))
ElseIf !(AllTrim(CND->CND_SITUAC) $ "A|FA|SA")
	If !lAuto
		Help(" ",1,"CN121JaEnc",,STR0089,1,0) //"Operação não permitida. Somente é possível encerrar Medições em Aberto."
	Endif
Else
	lEncerra := .T.
    If !lAuto
	    lContinua := (Aviso("CNTA121",OemtoAnsi(STR0090),{STR0157,STR0158}) == 1)//"Confirma encerramento da medição/Aut. Fornecimento?"
    Endif

	//Verifica se existe bloqueio contábil
	If lContinua .And. (lContinua := CtbValiDt(Nil, dDataBase,/*.T.*/ ,Nil ,Nil ,{"GCT001"}/*,"Data de apuração bloqueada pelo calendário contábil."*/) )
		If!Empty(dDataBloq) .AND. ( dDataBase <= dDataBloq)
			If !lAuto
				Help(" ",1,"ATFCTBBLQ") //P: Processo bloqueado pelo Calendário Contábil ou parâmetro de bloqueio nesta data ou período. S: Caso possível altere a data de referência do processo, verifique o parâmetro ou contate o responsável pelo Módulo Contábil.)
			Endif
			lContinua := .F.
		End
	EndIf

	If lContinua .And. lReinf .And. !CNRNFVldP( CND->CND_FILIAL , CND->CND_CONTRA , CND->CND_NUMMED )
		Help( " " , 1 , "CNREINF" )
		lContinua := .F.
	EndIf
	
	If lContinua
		//Chama rotina de encerramento por meio de processo
		If  lAutFor .And. !lInclui .And. !lAltera
			If !lAuto
				Processa( {||lRet := Cn121AutEnc(CND->(RECNO())) } )
			Else
				lRet := Cn121AutEnc(CND->(RECNO()))
			Endif
		Else
			If !lAuto
				Processa( {||lRet := CN121MedEnc(CND->(RECNO())) } )
			Else
				lRet := CN121MedEnc(CND->(RECNO()))
			Endif
		EndIf

		dbSelectArea("CNA")
		CNA->(dbSetOrder(1))
		If CNA->(MsSeek(xFilial("CNA",cFilCTR)+CND->(CND_CONTRA+CND_REVISA+CND_NUMERO)))
			cPrcSld := (CNA->CNA_SALDO*100)/CNA->CNA_VLTOT //-- Calcula percentual do saldo da planilha
			dbSelectArea("CNL")
			CNL->(dbSetOrder(1))
			//-- Verifica se a planilha alcancou o limite percentual
			If CNL->(MsSeek(xFilial("CNL",cFilCTR)+CNA->CNA_TIPPLA)) .And. cPrcSld <= CNL->CNL_LMTAVS
				//-- Emite alerta de saldo do contrato
				MEnviaMail("040",{CND->CND_NUMERO,CND->CND_CONTRA,CND->CND_REVISA,CNA->CNA_VLTOT,CNA->CNA_SALDO,CND->CND_FILIAL})
			EndIf
		EndIf
	EndIf
	lEncerra := .F.
EndIf

CN121Limpa() //--Desativa o model do CNTA121 apó finalização do processo.

Return lRet

//------------------------------------------------------------------
/*/{Protheus.doc} CN121PreDoc()
Funcao para Preparar pedidos e titulos de uma medicao
@author alexandre.gimenez
@since 26/08/2015
/*/
//-------------------------------------------------------------------
Function CN121PreDoc()
Local lRet 		:= .T.
Local oModel 	:= FwLoadModel("CNTA121")

oModel:SetOperation(MODEL_OPERATION_UPDATE)
If lRet := oModel:Active()
	If lRet := oModel:VldData()
			lRet := oModel:CommitData()
	EndIf
EndIf

Return lRet


//------------------------------------------------------------------
/*/{Protheus.doc} CN121GerDoc()
Funcao para gerar pedidos e titulos de uma medicao
@author alexandre.gimenez
@since 26/08/2015
/*/
//-------------------------------------------------------------------
Function CN121GerDoc(oModel)
Local oModelCND		:= oModel:GetModel("CNDMASTER")
Local oModelCXN		:= oModel:GetModel("CXNDETAIL")
Local oModelCNE		:= oModel:GetModel("CNEDETAIL")
Local oModelCXI		:= oModel:GetModel("CXIDETAIL")
Local oModelCXJ		:= oModel:GetModel("CXJDETAIL")
Local oModelCNQ		:= oModel:GetModel("CNQDETAIL")
Local oModelCNU		:= oModel:GetModel("CNUDETAIL")
Local oModelCNZ		:= oModel:GetModel("CNZDETAIL")
Local oModelCNR1	:= oModel:GetModel("CNRDETAIL1")
Local oModelCNR2	:= oModel:GetModel("CNRDETAIL2")
Local oModelCZY		:= oModel:GetModel('CZYDETAIL')

Local aCond			:= {}
Local aDocs			:= {}
Local aCab			:= {}
Local aItem			:= {}
Local aRateio		:= {}
Local aRatServ		:= {}
Local aQuebraIt		:= {}
Local aQuebraEnv	:= {}
Local aCTBEnt		:= CTBEntArr()
Local aCamposCNZ	:= oModelCNZ:GetStruct():GetFields()
Local aCamposCNE	:= oModelCNE:GetStruct():GetFields()
Local aLocAtend		:= {}

Local cAlc			:= "N"
Local cRetPrf		:= ""
Local cTpTit		:= ""
Local cRetNat		:= ""
Local cParcela		:= "123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0"
Local cChaveRat		:=	""
Local cNumCab		:= ""
Local cItemDetail	:= ""
Local cVend			:= ""
Local cCampoECCNZ	:= ""
Local cCampoECCNE	:= ""
Local cGrpAprov		:= oModelCND:GetValue("CND_APROV")
Local cContra		:= oModelCND:GetValue("CND_CONTRA")
Local cRevisa		:= oModelCND:GetValue("CND_REVISA")
Local cNumMed		:= oModelCND:GetValue("CND_NUMMED")
Local cMoeda		:= oModelCND:GetValue("CND_MOEDA")
Local cCondPgto		:= oModelCND:GetValue("CND_CONDPG")
Local cUserGi		:= ""
Local cUserCod		:= ""
Local cDtVencPl		:= ""
Local cNumPlan		:= ""
Local cIdPedido		:= ""
Local cPedTit		:= ""
Local cProdSv		:= ""
Local cFilRes		:= ""
Local cTipoFrete	:= ""
Local cTpRat		:= GetNewPar("MV_CNRATE", "1")
Local cCNPREMD 		:= SuperGetMV("MV_CNPREMD",.F.,"MED")
Local cCNTPTMD 		:= SuperGetMV("MV_CNTPTMD",.F.,"BOL")
Local cFilContr		:= oModelCND:GetValue("CND_FILCTR")
Local nQuantCNE		:= 0
Local nCXN			:= 0
Local nCNQ			:= 0
Local nCZY			:= 0
Local nCNE			:= 0
Local nCXI			:= 0
Local nX			:= 0
Local nY			:= 0
Local nZ			:= 0
Local nA			:= 0
Local nB			:= 0
Local nCount		:= 0
Local nCauc			:= 0
Local nAdia			:= 0
Local nParte		:= 0
Local nVlrDescPl	:= 0
Local nTitVlr		:= 0
Local nVlrDescIt    := 0
Local nDescMedPl    := 0
Local nMultMedPl	:= 0
Local nBoniMedPl	:= 0
Local nTotDecres	:= 0
Local nTotAcres		:= 0
Local nTitBoni		:= 0
Local nTitMult		:= 0
Local nPosId		:= 0
Local nPosServ		:= 0
Local nPosItem		:= 0
Local nPosEnv		:= 0
Local nPosDoc		:= 0
Local nPosRat		:= 0
Local nPosRatEv	:= 0
Local nGCTDPcAl		:= GetNewPar("MV_CNDPCAL",2)
Local nParcelas		:= SuperGetMv("MV_NUMPARC")
Local nQuantArred	:= 0
Local nPrecoArred	:= 0
Local nValorArred	:= 0
Local nQuantOri		:= 0
Local nPrecoOri		:= 0
Local nValorOri		:= 0
Local nDifValor		:= 0
Local nVlItDesc		:= 0
Local nDescPropIt	:= 0
Local nDescPropPl	:= 0
Local nAcumulado	:= 0
Local nValor		:= 0
Local nMultBonIt	:= 0
Local nMultBonPla	:= 0
Local nVlItMulBon	:= 0
Local nVlPlMulBon	:= 0
Local nCNR1			:= 0
Local nCNR2			:= 0
Local nMod			:= Iif(Cn121RetSt('COMPRA',0,oModelCXN:GetValue('CXN_NUMPLA'),oModelCXN:GetValue("CXN_CONTRA")),1,-1)

Local lCNT121PC 	:= ExistBlock("CNT121PC")
Local lCN121PED 	:= ExistBlock("CN121PED")

Local lGCTRet		:= GetNewPar("MV_CNRETNF"	,"N") == "S"
Local lGCTAdia		:= GetNewPar("MV_CNADIA"	,"N") == "S"
Local lGCTMdAlc		:= GetNewPar("MV_CNMDALC"	,"N") == "S"
Local lGeraCP		:= SuperGetMV("MV_CNPROCP"	,.F.,"N") == "S"
Local lCompra		:= CN121RetSt( "COMPRA", 0,, CND->CND_CONTRA )
Local lRet			:= .T.
Local lEnvFinan		:= .F.
Local lEnvCons		:= .F.
Local lMod			:= .F.
Local lSkipEnv		:= .F.
Local lProdServ		:= .F.
Local lEC05			:= .F.
Local lEC06			:= .F.
Local lEC07			:= .F.
Local lEC08			:= .F.
Local lEC09			:= .F.
Local lECCNE05		:= .F.
Local lECCNE06		:= .F.
Local lECCNE07		:= .F.
Local lECCNE08		:= .F.
Local lECCNE09		:= .F.
Local lTemPedido	:= .F.
Local cMdcron  		:= ""
Local cMdparce 		:= ""
Local cParCXN		:= ""
Local cCRONOG		:= ""
Local lAposEsp		:= CNE->(Columnpos('CNE_15ANOS')) > 0 .OR. CNE->(Columnpos('CNE_20ANOS')) > 0  .OR. CNE->(Columnpos('CNE_25ANOS')) > 0  
Local aItemApo		:= {}
Local aLinhApo		:= {}
Local aAposEsp		:= {}
Local nAp			:= 1
Local aSeFKF		:= {}
Local aSeFKG		:= {}
Local aItemFKG		:= {}
Local nItemFKG		:= 0
Local nSoma15a		:= 0
Local nSoma20a		:= 0
Local nSoma25a		:= 0 
Local cMDAP15		:= SuperGetMv("MV_MDAP15",,"")	//Codigo do complemento de imposto de aposentadoria para faixa de 15 anos
Local cMDAP20		:= SuperGetMv("MV_MDAP20",,"")	//Codigo do complemento de imposto de aposentadoria para faixa de 20 anos
Local cMDAP25		:= SuperGetMv("MV_MDAP25",,"")	//Codigo do complemento de imposto de aposentadoria para faixa de 25 anos 
Local lTxMoeda  	:= CND->( ColumnPos( "CND_TXMOED" ) ) > 0
//Abatimento de INSS
Local lAglutinado	:= .F.


Private lMsErroAuto := .F.

//-Inclusão de proteção para entidades contábeis na geração de pedido.
If 	FindFunction("CTB105MVC")
	CTB105MVC(.T.)
EndIf 

/* Estrutura de Arrays
aDocs
	cTipo(1-PedidoCompra,2-PedidoVenda,3-TituloPagar,4-TituloReceber)
	aCab
	aItem
	aRateio

aQuebraIt
	cChave
	cIdPed
	cTipo
	aServ
		cProdSv
		aItem
			cItem
			nQuant
			nValor

aQuebraEnv
	cTipo
	cCliente
	cLoja
	cFilial
	nPercent
	aQuebraIt
	cItem

aRatServ
	cChave
	cValor
	CC
	CONTA
	ITEMCT
	CLVL
	05CR
	05DB
	06CR
	06DB
	07CR
	07DB
	08CR
	08DB
	09CR
	09DB
*/

//Identifica o uso de controle de alçada no PC
If nGCTDPcAl == 1
	cAlc := "N" //Ativa o uso do controle de alçada.
ElseIf	nGCTDPcAl == 2
	cAlc :=  "S" //Desativa o uso do controle de alçada.
ElseIf nGCTDPcAl == 3
	cAlc := IIf( lGCTMdAlc .And. !Empty(cGrpAprov),"S","N") //Se medição possuir alçada, desativa.
EndIf

//Obtem o valor de retencao de caucao
nCauc := If(!lGCTRet,oModel:GetValue("CNDMASTER","CND_RETCAC"),0)
//Obtem o valor dos adiantamentos
nAdia := If(lGCTAdia,oModel:GetValue("CNDMASTER","CND_TOTADT"),0)

For nCXN := 1 to oModelCXN:Length()
	oModelCXN:GoLine(nCXN)
	cNumPlan	:= oModelCXN:GetValue("CXN_NUMPLA")
	cParCXN		:= oModelCXN:GetValue("CXN_PARCEL")			
	
	nDescMedPl := 0
	nMultMedPl := 0
	nBoniMedPl := 0
	
	If oModelCXN:GetValue("CXN_CHECK")
		
		nDescMedPl := oModelCXN:GetValue( "CXN_VLDESC" )
		nMultMedPl := oModelCXN:GetValue( "CXN_VLMULT" ) 
		nBoniMedPl := oModelCXN:GetValue( "CXN_VLBONI" )
		
		//-- Se planilha for zerada, não gera documentos
		If CXN->(ColumnPos('CXN_ZERO'))
			If oModelCXN:GetValue('CXN_ZERO') == '1'
				Loop
			EndIf
		EndIf
	
		cDtVencPl 	:= oModelCXN:GetValue('CXN_DTVENC')
		nVlrDescPl := 0

		lTemPedido	:= CN121TPed( oModelCNE )

		For nCNQ := 1 to oModelCNQ:Length()
			oModelCNQ:GoLine(nCNQ)
			//Contabiliza desconto apenas se o tipo do desconto estiver configurado para interferir no pedido
			//ou se a planilha gerar apenas títulos
			If !lCompra .Or. !lTemPedido .Or. CN121DcItf( oModelCNQ )
				nVlrDescPl += oModelCNQ:GetValue('CNQ_VALOR')
			EndIf
		Next nCNQ

		If lGCTAdia
			For nCZY := 1 to oModelCZY:Length()
				oModelCZY:GoLine(nCZY)
				nVlrDescPl += oModelCZY:GetValue('CZY_VALOR')
			Next nCZY
		EndIf

		If !lGCTRet
			nVlrDescPl += oModelCND:GetValue('CND_RETCAC') * (oModelCXN:GetValue('CXN_VLLIQD') / oModelCND:GetValue('CND_VLLIQD'))
		EndIf

		aSize(aQuebraIt,0)
		aSize(aQuebraEnv,0)
		aQuebraIt := {}
		aQuebraEnv := {}

		lEnvFinan	:= !Empty(oModelCXI:GetValue("CXI_CODCLI")) .And. oModelCXI:GetValue("CXI_TIPO") == "2" //Existem Finaciadores
		lEnvCons	:= !Empty(oModelCXI:GetValue("CXI_FILRES")) .And. oModelCXI:GetValue("CXI_TIPO") == "1"// Consorcio, Verificar linha

		For nCNE := 1 to oModelCNE:Length()
			oModelCNE:GoLine(nCNE)
			cIdPedido	:= oModelCNE:GetValue("CNE_IDPED")
			cPedTit 	:= oModelCNE:GetValue("CNE_PEDTIT")
			cProdSv		:= oModelCNE:GetValue("CNE_PRODSV")
			nQuantCNE 	:= oModelCNE:GetValue("CNE_QUANT")
			
			//Inclui somente itens com quantidade maior que zero
			If nQuantCNE > 0
				If !lExcedMEnc
					//Busca Id de Pedido no array
					If ( nPosId := aScan(aQuebraIt,{|x| x[1] == cIdPedido+cPedTit } ) ) == 0
						aAdd(aQuebraIt,{cIdPedido+cPedTit,cIdPedido,cPedTit,{}})
						nPosId:= Len(aQuebraIt)
						aAdd(aQuebraIt[nPosId][4],{cProdSv,{}})
						nPosServ := 1
					Else //Busca se ja existe o servico no Id
						If ( nPosServ := aScan(aQuebraIt[nPosId][4],{|x| x[1] == cProdSv } ) ) == 0
							aAdd(aQuebraIt[nPosId][4],{cProdSv,{}})
							nPosServ := Len(aQuebraIt[nPosId][4])
						EndIf
					EndIf

					//Cria um novo Item
					aAdd(aQuebraIt[nPosId][4][nPosServ][2],{})
					nPosItem := Len(aQuebraIt[nPosId][4][nPosServ][2])
					//Adiciona Itens ao Id e Servico Relacionado
					aAdd(aQuebraIt[nPosId][4][nPosServ][2][nPosItem],oModelCNE:GetValue("CNE_ITEM") )
					aAdd(aQuebraIt[nPosId][4][nPosServ][2][nPosItem],nQuantCNE )
					aAdd(aQuebraIt[nPosId][4][nPosServ][2][nPosItem],oModelCNE:GetValue("CNE_VLUNIT") - oModelCNE:GetValue("CNE_VLDESC") )
				Else
					If oModelCNE:GetValue("CNE_EXCEDE") == "1" .And. oModelCNE:IsInserted()
						//Busca Id de Pedido no array
						If ( nPosId := aScan(aQuebraIt,{|x| x[1] == cIdPedido+cPedTit } ) ) == 0
							aAdd(aQuebraIt,{cIdPedido+cPedTit,cIdPedido,cPedTit,{}})
							nPosId:= Len(aQuebraIt)
							aAdd(aQuebraIt[nPosId][4],{cProdSv,{}})
							nPosServ := 1
						Else //Busca se ja existe o servico no Id
							If ( nPosServ := aScan(aQuebraIt[nPosId][4],{|x| x[1] == cProdSv } ) ) == 0
								aAdd(aQuebraIt[nPosId][4],{cProdSv,{}})
								nPosServ := Len(aQuebraIt[nPosId][4])
							EndIf
						EndIf

						//Cria um novo Item
						aAdd(aQuebraIt[nPosId][4][nPosServ][2],{})
						nPosItem := Len(aQuebraIt[nPosId][4][nPosServ][2])
						//Adiciona Itens ao Id e Servico Relacionado
						aAdd(aQuebraIt[nPosId][4][nPosServ][2][nPosItem],oModelCNE:GetValue("CNE_ITEM") )
						aAdd(aQuebraIt[nPosId][4][nPosServ][2][nPosItem],nQuantCNE )
						aAdd(aQuebraIt[nPosId][4][nPosServ][2][nPosItem],oModelCNE:GetValue("CNE_VLUNIT") - oModelCNE:GetValue("CNE_VLDESC") )
					EndIf
				EndIf
			EndIf
		Next nCNE

		//-- Monta pedidos por Envolvidos
		If lEnvFinan .Or. lEnvCons
			For nCXI := 1 To oModelCXI:Length()
				oModelCXI:GoLine(nCXI)
				cFilRes	:= oModelCXI:GetValue("CXI_FILRES")

				lSkipEnv := .F.
				//-- Para consorcio, so gera quando for uma filial
				If lEnvCons .And. Empty(cFilRes)
					lSkipEnv := .T.
				EndIf

				If !lSkipEnv
					aAdd(aQuebraEnv,{})
					nPosEnv := Len(aQuebraEnv)

					If lEnvFinan
						aAdd(aQuebraEnv[nPosEnv],"F")
						aAdd(aQuebraEnv[nPosEnv],oModelCXI:GetValue("CXI_CODCLI"))
						aAdd(aQuebraEnv[nPosEnv],oModelCXI:GetValue("CXI_LOJACL"))
					Else
						aAdd(aQuebraEnv[nPosEnv],"C")
						aAdd(aQuebraEnv[nPosEnv],oModelCXN:GetValue("CXN_FORCLI"))
						aAdd(aQuebraEnv[nPosEnv],oModelCXN:GetValue("CXN_LOJA"))
					EndIf

					aAdd(aQuebraEnv[nPosEnv],IIF(Empty(cFilRes),cFilAnt,cFilRes))
					aAdd(aQuebraEnv[nPosEnv],oModelCXI:GetValue("CXI_PERRAT"))
					aAdd(aQuebraEnv[nPosEnv],aClone(aQuebraIt))
					aAdd(aQuebraEnv[nPosEnv],oModelCXI:GetValue("CXI_ITEM"))
				EndIf
			Next nCXI
		Else //Caso Não exista envolvidos Monta array com Cliente/ Fornecedor da planilha
			aAdd(aQuebraEnv,{})
			nPosEnv := Len(aQuebraEnv)
			aAdd(aQuebraEnv[nPosEnv],"X")

			If lCompra
				aAdd(aQuebraEnv[nPosEnv],oModelCXN:GetValue("CXN_FORNEC"))
				aAdd(aQuebraEnv[nPosEnv],oModelCXN:GetValue("CXN_LJFORN"))
			Else
				aAdd(aQuebraEnv[nPosEnv],oModelCXN:GetValue("CXN_CLIENT"))
				aAdd(aQuebraEnv[nPosEnv],oModelCXN:GetValue("CXN_LJCLI"))
			EndIf

			aAdd(aQuebraEnv[nPosEnv],cFilAnt)
			aAdd(aQuebraEnv[nPosEnv],100)
			aAdd(aQuebraEnv[nPosEnv],aClone(aQuebraIt))
			aAdd(aQuebraEnv[nPosEnv],StrZero(nPosEnv,TamSX3("CXI_ITEM")[1] ) )//-- Não tem parte envolvida
		EndIf

		If !Empty(aQuebraEnv)
			For nA := 1 To Len(aQuebraEnv)//-- Roda Clientes/Fornecedores da Planilha
				nParte := aQuebraEnv[nA][5]/100
				For nX := 1 To Len(aQuebraEnv[nA][6])//Roda os Ids
					//-- Zera Totalizadores de titulo por ID
					nTitVlr 	:= 0
					nVlrDescIt  := 0
					nTitBoni	:= 0
					nTitMult	:= 0
					nSoma15a	:= 0
					nSoma20a	:= 0 
					nSoma25a	:= 0
					nItemFKG	:= 0
					aSeFKF		:= {}
					aSeFKG		:= {}
					aItemFKG	:= {}
					aItemApo 	:= {}
					aLinhApo 	:= {}
					aAposEsp 	:= {}
					
					aAdd(aDocs, {/*Tipo*/,{/*aCab*/},{/*aItem*/},{/*aRateio*/},{/*aSeFKF*/},{/*aSeFKG*/},{/*aAposEsp*/}})
					//-- Criar documento e iniciar
					aSize(aCab,0)
					aSize(aItem,0)
					aSize(aRateio,0)
					aCab 	:= {}
					aItem 	:= {}
					aRateio	:= {}
					cItemDetail:= IIF(lCompra,StrZero(0,TamSX3("C7_ITEM")[1]),StrZero(0,TamSX3("C6_ITEM")[1]))
					nPosDoc 	:= Len(aDocs)

					//Identifica documento a ser gerado
					If lCompra
						If aQuebraEnv[nA][6][nX][3] == '2'
							aDocs[nPosDoc][1]:= '3' // Titulo a Pagar
						Else
							aDocs[nPosDoc][1]:= '1'  // Pedido de Compra
						EndIf
					Else
						If aQuebraEnv[nA][6][nX][3] == '2'
							aDocs[nPosDoc][1]:= '4' // Titulo a receber
						Else
							aDocs[nPosDoc][1]:= '2'  // Pedido de Venda
						EndIf
					EndIf
					
					cMdcron  := ""
					cMdparce := ""
					cCRONOG	 := ""
						
					cCRONOG := oModelCXN:GetValue('CXN_CRONOG')
					
					CNF->( dbSetorder( 3 ) ) //CNF_FILIAL+CNF_CONTRA+CNF_REVISA+CNF_NUMERO+CNF_PARCEL
					If CNF->( msSeek( FWxFilial("CNF") + oModelCND:GetValue('CND_CONTRA') + oModelCND:GetValue('CND_REVISA') + cCRONOG + cParCXN ) )
						cMdcron := CNF->CNF_NUMERO
						cMdparce := CNF->CNF_PARCEL
					EndIf

					//- Montagem dos aCabs conforme Documento
					Do Case
						Case aDocs[nPosDoc][1] == '1'  // Pedido de Compra
							If lCNT121PC
								ExecBlock("CNT121PC",.F.,.F.)
							EndIf

							//- Monta a Cab
							cNumCab := CriaVar('C7_NUM', .T.) //-- Incrementa a numeracao
							aCab:={{"C7_NUM"		,cNumCab				  		,NIL},; // Numero do Pedido
									{"C7_EMISSAO"	,dDataBase						,NIL},; // Data de Emissao
									{"C7_FORNECE"	,aQuebraEnv[nA][2]				,NIL},; // Fornecedor
									{"C7_LOJA"		,aQuebraEnv[nA][3]				,NIL},; // Loja do Fornecedor
									{"C7_COND"		,cCondPgto						,NIL},; // Condicao de Pagamento
									{"ALCADA"		,cAlc							,NIL},; // Alcada
									{"MED_GCT"		,"GCT"							,NIL},; // Originador
									{"C7_MOEDA"		,cMoeda							,NIL},; // Moeda
									{"C7_CONTATO"	,CriaVar("C7_CONTATO"	,.F.)	,NIL},; // Contato
									{"C7_FILENT"	,CriaVar("C7_FILENT",.F.)		,NIL},; // Filial de Entrega
									{"C7_FRETE"		,CriaVar("C7_FRETE",.F.)		,NIL},; // Frete
									{"C7_DESPESA"	,CriaVar("C7_DESPESA",.F.)		,NIL},; // Despesa
									{"C7_SEGURO"	,CriaVar("C7_SEGURO",.F.)		,NIL},; // Seguro
									{"C7_MSG"		,CriaVar("C7_MSG",.F.)			,NIL},; // Mensagem
									{"C7_REAJUST"	,CriaVar("C7_REAJUST",.F.)		,NIL}} // Reajuste
							
							If cMoeda != 1
								If lTxMoeda .And. CND->CND_TXMOED > 0
									aAdd( aCab, { "C7_TXMOEDA", CND->CND_TXMOED, NIL } )
								Else
									aAdd( aCab, { "C7_TXMOEDA", xMoeda(1,cMoeda,1,dDataBase,TamSx3("C7_TXMOEDA")[2],,), NIL } ) //Taxa de Conversao
								EndIF
							EndIf

							If cPaisLoc == 'RUS'
				   				aAdd(aCab,{"C7_CONUNI",CND->CND_CONUNI,NIL}) // Conventional unit
							EndIf

							If CND->(FieldPos('CND_USERGI')) > 0
								cUserGi := FWLeUserlg("CND_USERGI")
								PswOrder(2)
								If PswSeek(cUserGi,.T.)
									cUserCod	:= PswRet()[1][1]
									aAdd(aCab,{"C7_USER",cUserCod,NIL})
								EndIf
							Else
								aAdd(aCab,{"C7_USER",__cUserId,NIL})
							EndIf

						Case aDocs[nPosDoc][1] == '3' // Titulo a Pagar
							
							//- Monta a Cab
							
							cNumCab := CriaVar('E2_NUM',.T.)
							
							If Empty(cNumCab)
								cNumCab := A121SeqTit("SE2","E2_NUM",,cCNPREMD)
							EndIf
							
							
							aCab:={{"E2_FORNECE"	,aQuebraEnv[nA][2]					,NIL},; //[1] Fornecedor
									{"E2_LOJA"		,aQuebraEnv[nA][3]					,NIL},; //[2] Loja do Fornecedor
									{"E2_ORIGEM"	,"CNTA121"							,NIL},; //[3] Origem
									{"E2_EMISSAO"	,dDataBase							,NIL},; //[4] Emissão
									{"E2_VENCTO" 	,IIf(cDtVencPl > dDataBase, cDtVencPl , dDataBase) ,NIL},; //[5] Vencimento
									{"E2_VENCREA"	,IIf(cDtVencPl > dDataBase, cDtVencPl , dDataBase) ,NIL},; //[6] Vencimento Real
									{"E2_VENCORI"	,IIf(cDtVencPl > dDataBase, cDtVencPl , dDataBase) ,NIL},; //[7] Vencimento Origem	
									{"E2_MOEDA"  	,cMoeda								,NIL},; //[8] Moeda
									{"E2_MDCONTR"	,cContra							,NIL},; //[9] Numero do Contrato
									{"E2_MDREVIS"	,cRevisa							,NIL},; //[10]Revisão do Contrato
									{"E2_MEDNUME"	,cNumMed							,NIL},; //[11]Numero da Medição
									{"E2_MDPLANI"	,cNumPlan							,NIL},; //[12]Numero da planilha
									{"E2_VALOR"		,0									,NIL},; //[13]Acrescimos do Titulo
									{"E2_ACRESC"	,0									,NIL},; //[14]Acrescimos do Titulo
									{"E2_DECRESC"	,0                              	,NIL},; //[15]Decrescimos do Titulo
									{"E2_NUM"		,cNumCab							,NIL},; //[16]Numero do Titulo
									{"E2_MDCRON"	,cMdcron							,NIL},;	//[17]Numero do Cronograma
									{"E2_MDPARCE"	,cMdparce							,NIL},;	//[18] Numero da Parcela
									{"E2_MDDESC"	,0									,NIL},;	//[19] Desconto da medição
									{"E2_MDMULT"	,0									,NIL},;	//[20] Multa da medição
									{"E2_MDBONI"	,0									,NIL}}	//[21] Bonificação da medição							
									
							If AliasIndic( 'CXO' )
								CnGetMNat( oModel , @aCab , 'E2' ) 
							EndIf

						Case aDocs[nPosDoc][1] == '2'  // Pedido de Venda
							//- Monta a Cab
							cTipoFrete := Posicione("TFJ",5,xFilial("TFJ")+cContra+cRevisa,"TFJ_TPFRET")
							If !Empty(cTipoFrete)
								cTipoFrete := Iif(TFJ->TFJ_TPFRET=="1","C","F")
							Else
								cTipoFrete := Posicione("SA1",1, xFilial("SA1")+oModelCXN:GetValue("CXN_CLIENT")+oModelCXN:GetValue("CXN_LJCLI"),"A1_TPFRET")
							Endif

							If cPaisLoc == "BRA"
	
								If lGrpFat
									aLocAtend := Cn121GLocTWW(oModelCXN:GetValue("CXN_CONTRA"),oModelCXN:GetValue("CXN_REVISA"),oModelCXN:GetValue("CXN_NUMPLA"))
								Else
									aLocAtend := Cn121GetLoc(oModelCXN:GetValue("CXN_CONTRA"),oModelCXN:GetValue("CXN_REVISA"),oModelCXN:GetValue("CXN_NUMPLA"))
								EndIf

								aLocAtend := Cn121GetLoc(oModelCXN:GetValue("CXN_CONTRA"),oModelCXN:GetValue("CXN_NUMPLA"))
							EndIf

							aCab:={	{"C5_TIPO"   	,	"N"									,Nil},; 	// Tipo de pedido
									{"C5_CLIENTE"	,	aQuebraEnv[nA][2]					,Nil},; 	// Codigo do cliente
									{"C5_LOJAENT"	,	aQuebraEnv[nA][3]					,Nil},; 	// Loja para entrada
									{"C5_LOJACLI"	,	aQuebraEnv[nA][3]					,Nil},; 	// Loja do cliente
									{"C5_EMISSAO"	,	dDatabase							,Nil},; 	// Data de emissao
									{"C5_CONDPAG"	,	cCondPgto							,Nil},; 	// Codigo da condicao de pagamanto*
									{"C5_MOEDA"  	,	cMoeda								,Nil},; 	// Moeda
									{"C5_TPFRETE"  	,	cTipoFrete							,Nil},; 	// Tipo de Frete
									{"C5_MDCONTR"	,	cContra								,Nil},;		// Cod. do Contrato
									{"C5_MDNUMED"	,	cNumMed								,Nil},;		// Codigo da Medicao
									{"C5_MDPLANI"	,	cNumPlan							,Nil}}		// Numero da Planilha

							If cPaisLoc == "BRA"
								If !Empty(aLocAtend[1])
									aAdd(aCab,{"C5_MUNPRES",aLocAtend[1],NIL}) // Municipio de Prestacao
								EndIf

								If !Empty(aLocAtend[2])
									aAdd(aCab,{"C5_RECISS",aLocAtend[2],NIL}) // Recolhe ISS?
								EndIf

								If !Empty(aLocAtend[3])
									aAdd(aCab,{"C5_ESTPRES",aLocAtend[3],NIL}) // Estado de Prestacao
								EndIf

								If cMoeda != 1
									If lTxMoeda .And. CND->CND_TXMOED > 0
										aAdd( aCab, { "C5_TXMOEDA", CND->CND_TXMOED, NIL } )
									Else
										aAdd( aCab, { "C5_TXMOEDA", xMoeda(1,cMoeda,1,dDataBase,TamSx3("C5_TXMOEDA")[2],,), NIL } ) //Taxa de Conversao
									EndIf
								EndIf
							EndIf

							If cPaisLoc == 'RUS'
				   				aAdd(aCab,{"C5_CONUNI",CND->CND_CONUNI,NIL}) // Conventional unit
							EndIf

							//Carrega Vendedores
							cVend := "1"
							For nB := 1 To oModelCNU:Length()
								oModelCNU:GoLine(nB)
								If	!Empty(oModelCNU:GetValue("CNU_CODVD"))
									aAdd(aCab,{"C5_VEND"+cVend,oModelCNU:GetValue("CNU_CODVD"),NIL})
									aAdd(aCab,{"C5_COMIS"+cVend,oModelCNU:GetValue("CNU_PERCCM"),NIL})
									cVend:=Soma1(cVend)
								EndIf
							Next nB

							If Posicione('SE4',1,xFilial('SE4')+cCondPgto,'E4_TIPO') == '9' //Preenche as Parcelas e Vencimentos  se condição de pagamento for do tipo 9
								For nB:=1 to nParcelas
									aAdd(aCab,{"C5_PARC"+Substr(cParcela,nB,1),&("CND->CND_PARC"+Substr(cParcela,nB,1)),NIL})
									If "C5_DATA"+Substr(cParcela,nB,1) == 'C5_DATA1' .And. Empty(CND->CND_DATA1)
										aAdd(aCab,{"C5_DATA1",cDtVencPl	,Nil})
									Else
									aAdd(aCab,{"C5_DATA"+Substr(cParcela,nB,1),&("CND->CND_DATA"+Substr(cParcela,nB,1)),NIL})
									EndIf
								Next nB
							EndIf

						Case aDocs[nPosDoc][1] == '4' // Titulo a receber
							
							//- Monta a Cab
							
							cNumCab := CriaVar('E1_NUM',.T.)
							
							If Empty(cNumCab)								
								cNumCab := A121SeqTit("SE1","E1_NUM",,cCNPREMD)
							EndIf

							aCab:={{"E1_CLIENTE"	,aQuebraEnv[nA][2]					,NIL},; // [1] Cliente
									{"E1_LOJA"		,aQuebraEnv[nA][3]					,NIL},; // [2] Loja do Cliente
									{"E1_ORIGEM"	,"CNTA121"							,NIL},; // [3] Origem
									{"E1_EMISSAO"	,dDataBase							,NIL},; // [4] Emissão
									{"E1_VENCTO" 	,IIf(cDtVencPl > dDataBase, cDtVencPl , dDataBase) ,NIL},; // [5] Vencimento
									{"E1_VENCREA"	,IIf(cDtVencPl > dDataBase, cDtVencPl , dDataBase) ,NIL},; // [6] Vencimento Real
									{"E1_VENCORI"	,IIf(cDtVencPl > dDataBase, cDtVencPl , dDataBase) ,NIL},; // [7] Vencimento Origem
									{"E1_MOEDA"  	,cMoeda								,NIL},; // [8] Moeda
									{"E1_MDCONTR"	,cContra							,NIL},; // [9] Numero do Contrato
									{"E1_MDREVIS"	,cRevisa							,NIL},; // [10]Revisão do Contrato
									{"E1_MEDNUME"	,cNumMed							,NIL},; // [11]Numero da Medição
									{"E1_MDPLANI"	,cNumPlan 							,NIL},; // [12]Numero da planilha
									{"E1_VALOR"		,0									,NIL},; // [13]Valor do Titulo
									{"E1_ACRESC"	,0									,NIL},; // [14]Acrescimos do Titulo
									{"E1_DECRESC"	,0                              	,NIL},; // [15]Decrescimos do Titulo
									{"E1_NUM"		,cNumCab							,NIL},; // [16]Numero do Titulo
									{"E1_MDCRON"	,cMdcron							,NIL},;	// [17]Numero do Cronograma
									{"E1_MDPARCE"	,cMdparce							,NIL},;	// [18] Numero da Parcela
									{"E1_MDDESC"	,0									,NIL},;	// [19] Desconto da medição
									{"E1_MDMULT"	,0									,NIL},;	// [20] Multa da medição
									{"E1_MDBONI"	,0									,NIL}}	// [21] Bonificação da medição

							If AliasIndic( 'CXO' )
								CnGetMNat( oModel , @aCab , 'E1' )
							EndIf
							
					EndCase

					//Multa e Bonificação da Planilha a ser considerada zera o valor da multa para recalcular o próximo item
					nMultBonPla	:= 0
					nMultBonIt	:= 0
					nVlItMulBon	:= 0
					nVlPlMulBon	:= 0

					For nCNR1 := 1 To oModelCNR1:Length()
						oModelCNR1:GoLine(nCNR1)
						If oModelCNR1:GetValue("CNR_FLGPED") == "1"
							If oModelCNR1:GetValue("CNR_TIPO") == "1"
								nMultBonPla	-= oModelCNR1:GetValue("CNR_VALOR")
							Else
								nMultBonPla	+= oModelCNR1:GetValue("CNR_VALOR")
							EndIf
						EndIf
					Next nCNR1

					//Modifica Acréscimo ou decréscimo do valor de acordo com o contrato de compra ou venda
					nMultBonPla := nMod * nMultBonPla
					nDifValor 	:= 0

					For nY := 1 To Len(aQuebraEnv[nA][6][nX][4]) // Rodra por Produto de servico
						lProdServ := !(Empty(aQuebraEnv[nA][6][nX][4][nY][1])) // Quando preenchido tem que aglunar
						If lProdServ
							aAdd(aItem,{})
							aSize(aRatServ,0)
							aRatServ := {}
							nPosItem := Len(aItem)
							cItemDetail := Soma1(cItemDetail)
							DbSelectArea("SB1")
							SB1->(DBSetOrder(1))
							SB1->(DbSeek(xFilial("SB1")+aQuebraEnv[nA][6][nX][4][nY][1]))

							If aDocs[nPosDoc][1] == '1' // pedido de Compra

								DbSelectArea("CNB")
								CNB->(DbSetOrder(1))//CNB_FILIAL+CNB_CONTRA+CNB_REVISA+CNB_NUMERO+CNB_ITEM
								CNB->(DbSeek(xFilial("CNB"/*,cFilCtr*/)+oModelCND:GetValue("CND_CONTRA")+oModelCND:GetValue("CND_REVISA")+oModelCXN:GetValue("CXN_NUMPLA")+oModelCNE:GetValue("CNE_ITEM") ))

								aAdd(aItem[nPosItem]	,{"C7_ITEM"		,cItemDetail						,NIL})	//Item
								aAdd(aItem[nPosItem]	,{"C7_PRODUTO"	,aQuebraEnv[nA][6][nX][4][nY][1]	,NIL}) //Produto
								aAdd(aItem[nPosItem]	,{"C7_DESCRI"	,SB1->B1_DESC						,NIL}) //Descricao
								aAdd(aItem[nPosItem]	,{"C7_QUANT"	,1									,NIL}) //Quantidade
								aAdd(aItem[nPosItem]	,{"C7_QTDSOL"	,1									,NIL})	//Quantidade solicitada
								aAdd(aItem[nPosItem]	,{"C7_UM"		,SB1->B1_UM							,NIL}) //Unidade de Medida
								aAdd(aItem[nPosItem]	,{"C7_QTSEGUM"	,ConvUm(SB1->B1_COD,nQuantArred,0,2),NIL})	//Segunda unidade de medida
								aAdd(aItem[nPosItem]	,{"C7_PRECO"	,0									,NIL}) //Preco unitario
								aAdd(aItem[nPosItem]	,{"C7_IPI"		,SB1->B1_IPI						,NIL}) //IPI
								aAdd(aItem[nPosItem]	,{"C7_DATPRF"	,dDataBase							,NIL}) //Data de entrega
								aAdd(aItem[nPosItem]	,{"C7_LOCAL"	,SB1->B1_LOCPAD						,NIL}) //Local
								aAdd(aItem[nPosItem]	,{"C7_TES"		,""									,Nil}) // TES
								aAdd(aItem[nPosItem]	,{"C7_ITEMED"	,""									,Nil}) //Item da Medicao
								aAdd(aItem[nPosItem]	,{"C7_VLDESC"	,0									,NIL}) //Desconto Item
								aAdd(aItem[nPosItem]	,{"C7_CC"		,""									,NIL}) //Centro de custo
								aAdd(aItem[nPosItem]	,{"C7_CONTA"	,""									,NIL}) //Conta
								aAdd(aItem[nPosItem]	,{"C7_ITEMCTA"	,""									,NIL}) //Item de conta
								aAdd(aItem[nPosItem]	,{"C7_CLVL"		,""									,NIL})	//Classe de valor
								aAdd(aItem[nPosItem]	,{"C7_CONTRA"	,cContra							,NIL})	//
								aAdd(aItem[nPosItem]	,{"C7_CONTREV"	,cRevisa							,NIL})	//
								aAdd(aItem[nPosItem]	,{"C7_PLANILH"	,cNumPlan							,NIL})	//
								aAdd(aItem[nPosItem]	,{"C7_MEDICAO"	,cNumMed							,NIL})	//
								aAdd(aItem[nPosItem] 	,{"C7_OBS"		,oModelCND:GetValue("CND_OBS")		,Nil})	//Observação

								//Não permitir Nota de empenho e solicitações de compra para produto de servico
								aAdd(aItem[nPosItem]	,{"C7_CODNE"	,""									,NIL}) //Código da nota de empenho
								aAdd(aItem[nPosItem]	,{"C7_ITEMNE" 	,""									,NIL}) //Item da Nota de empenho
								aAdd(aItem[nPosItem]	,{"C7_FISCORI"	,""									,NIL}) //Filial de origem da SC

								For nB := 1 To Len(aCTBEnt) //Entidades Contabeis
									If SC7->(FieldPos("C7_EC"+aCTBEnt[nB]+"CR")) > 0 .And. CNE->(FieldPos("CNE_EC"+aCTBEnt[nB]+"CR")) > 0
											aAdd(aItem[nPosItem]	,{"C7_EC"+aCTBEnt[nB]+"CR"	,oModelCNE:GetValue("CNE_EC"+aCTBEnt[nB]+"CR")	,NIL}) //Entidades Contabeis Credito
											aAdd(aItem[nPosItem]	,{"C7_EC"+aCTBEnt[nB]+"DB"	,oModelCNE:GetValue("CNE_EC"+aCTBEnt[nB]+"DB")	,NIL}) //Entidades Contabeis Debito
									EndIf
								Next nB							
								
							ElseIf aDocs[nPosDoc][1] == '2' // pedido de venda
								aAdd(aItem[nPosItem]	,{"C6_NUM"		,cNumCab							,Nil}) // Numero do Pedido
								aAdd(aItem[nPosItem]	,{"C6_ITEM"		,cItemDetail						,Nil}) // Numero do Item no Pedido
								aAdd(aItem[nPosItem]	,{"C6_PRODUTO"	,aQuebraEnv[nA][6][nX][4][nY][1]	,Nil}) // Codigo do Produto
								aAdd(aItem[nPosItem]	,{"C6_DESCRI"	,SB1->B1_DESC						,Nil}) // Descricao
								aAdd(aItem[nPosItem]	,{"C6_QTDVEN"	,1									,Nil}) // Quantidade Vendida
								aAdd(aItem[nPosItem]	,{"C6_PRUNIT"	,0									,Nil}) // PRECO DE LISTA
								aAdd(aItem[nPosItem]	,{"C6_PRCVEN"	,0									,Nil}) // Preco Unitario Liquido
								aAdd(aItem[nPosItem]	,{"C6_ENTREG"	,dDataBase							,Nil}) // Data da Entrega
								aAdd(aItem[nPosItem]	,{"C6_UM"		,SB1->B1_UM							,Nil}) // Unidade de Medida Primar.
								aAdd(aItem[nPosItem]	,{"C6_CLI"		,aQuebraEnv[nA][2]					,Nil}) // Cliente
								aAdd(aItem[nPosItem]	,{"C6_LOJA"		,aQuebraEnv[nA][3]					,Nil}) // Loja do Cliente
								aAdd(aItem[nPosItem]	,{"C6_TES"		,''									,Nil}) // TES
								aAdd(aItem[nPosItem]	,{"C6_LOCAL"	,SB1->B1_LOCPAD						,Nil}) // Local
								aAdd(aItem[nPosItem]	,{"C6_ITEMED"	,''									,Nil}) // Item da Medicao
								aAdd(aItem[nPosItem]	,{"C6_VALDESC"	,nVlItDesc							,Nil}) // Desconto Item ZERADO PRODUTO DE SERVIÇO
								aAdd(aItem[nPosItem]	,{"C6_ABATINS"	,0									,Nil}) // Abatimento da base de INSS

								//Preenche ARRAYS com dados sobre aposentadoria especial REINF
								If	lAposEsp			
									aAdd(aItemApo , { cItemDetail ,oModelCNE:GetValue("CNE_15ANOS") , oModelCNE:GetValue("CNE_20ANOS") , oModelCNE:GetValue("CNE_25ANOS") })
								Endif 								
								
								If oModelCNE:GetValue("CNE_FLGCMS") == "1" //Verifica se o item e comissionado
									cVend:="1"
									For nB:=1 to oModelCNU:Length()
										oModelCNU:GoLine(nB)
										If	!(Empty(oModelCNU:GetValue("CNU_CODVD"))) //Complementa as comissoes de acordo com os contratos
											aAdd(aItem[nPosItem]	,{"C6_COMIS"+cVend,oModelCNU:GetValue("CNU_PERCCM"),NIL})
											cVend:=Soma1(cVend)
										EndIf
									Next nB
								EndIf
							EndIf
						EndIf												
						
						For nZ := 1 To Len(aQuebraEnv[nA][6][nX][4][nY][2])
							//Posiciona CNE
							oModelCNE:GoLine(MtFindMVC(oModelCNE,{{"CNE_ITEM",aQuebraEnv[nA][6][nX][4][nY][2][nZ][1]}}))
							If oModelCNE:GetValue('CNE_VLUNIT') > 0
								//Posiciona SB1
								DbSelectArea("SB1")
								SB1->(DBSetOrder(1))
								SB1->(DbSeek(xFilial("SB1")+oModelCNE:GetValue("CNE_PRODUT")))
	
								//Atualiza Valores
								nQuantOri	:= oModelCNE:GetValue("CNE_QUANT")  * nParte
								nPrecoOri	:= oModelCNE:GetValue("CNE_VLUNIT")
								nValorOri	:= oModelCNE:GetValue("CNE_VLTOT") * nParte
	
								//Multa e Bonificação do Item a ser considerado
								nMultBonIt := 0
								For nCNR2 := 1 To oModelCNR2:Length()
									oModelCNR2:GoLine(nCNR2)
									If oModelCNR2:GetValue("CNR_FLGPED") == "1"
										If oModelCNR2:GetValue("CNR_TIPO") == "1"
											nMultBonIt	-= oModelCNR2:GetValue("CNR_VALOR")
										Else
											nMultBonIt	+= oModelCNR2:GetValue("CNR_VALOR")
										EndIf
									EndIf
								Next nCNR2
								//Modifica Acréscimo ou decréscimo do valor de acordo com o contrato de compra ou venda
								nMultBonIt := nMod * nMultBonIt
	
								//-Desconto proporcional ao item aplicado ao item
								nDescPropIt	:= A410Arred( oModelCNE:GetValue("CNE_VLDESC") )
	
								//-Desconto proporcional ao item aplicado a planilha
								nDescPropPl	:= A410Arred( ((oModelCNE:GetValue("CNE_VLTOT") - nDescPropIt) / oModelCXN:GetValue("CXN_VLLIQD")) * nVlrDescPl)
								//-Multa / Bonificação proporcional ao item
								nVlPlMulBon	:= A410Arred( (oModelCNE:GetValue("CNE_VLTOT") / oModelCXN:GetValue("CXN_VLLIQD")) * nMultBonPla )
	
								If cTpRat == '1'
									nVlItDesc		:= nDescPropIt
									nPrecoOri	-= nDescPropPl / oModelCNE:GetValue("CNE_QUANT")
									nValorOri	-= nDescPropPl
								Else
									nVlItDesc 	:= nDescPropIt + nDescPropPl
								EndIf
	
								nVlItMulBon	:= nMultBonIt  + nVlPlMulBon
	
								//Proporcionaliza pela qtde de itens
								nVlItMulBon := nVlItMulBon * nParte
								nVlItUnMuB := nVlItMulBon / oModelCNE:GetValue("CNE_QUANT")
	
								//Atualiza preço com Multas e Bonificações
								nPrecoOri += nVlItUnMuB
								nValorOri += nVlItMulBon
								
								//-- Arredondamento de acordo com as casas decimais do pedido
								nQuantArred	:= A410Arred( nQuantOri , ( IIF( lCompra , "C7_QUANT" , "C6_QTDVEN") ) )
								nPrecoArred	:= A410Arred( nPrecoOri , ( IIF( lCompra , "C7_PRECO" , "C6_PRUNIT") ) )
								nValorArred	:= A410Arred( nQuantArred * nPrecoArred , ( IIF( lCompra , "C7_TOTAL" , "C6_VALOR") ) )
								
								nDifValor   += nValorArred - nValorOri 
								
								If ABS(nDifValor) >= 0.01	//--Ajusta o valor total e valor unitario do item
	
									nValorArred := A410Arred( nValorArred - nDifValor 		, IIF( lCompra , "C7_TOTAL" , "C6_VALOR" 	) )		//-- Ajusta valor total considerando a diferença de arredondamentos
									nPrecoArred	:= A410Arred( nValorArred / nQuantArred 	, IIF( lCompra , "C7_PRECO" , "C6_PRUNIT" 	) )		//-- Ajusta o valor unitario para que multiplicado pela quantidade chegue o mais próximo possível do valo total
									nValorarred := A410Arred( nQuantArred * nPrecoArred 	, IIF( lCompra , "C7_TOTAL" , "C6_VALOR"	) ) 	//-- Ajusta o valor 
									
									nDifValor   := nValorArred - nValorOri	//-- Recalcula sobra para que seja contabilizada no próximo item 
									
									If ABS(nDifValor) >= 0.01 .And. nZ == Len(aQuebraEnv[nA][6][nX][4][nY][2]) //-Quando for o último item e ainda possuir saldo, deve abater a diferença.
										nPrecoArred := nValorOri / nQuantOri
										nValorArred := A410Arred( nQuantArred * nPrecoArred , ( IIF( lCompra , "C7_TOTAL" , "C6_VALOR") ) ) 
									EndIf
	
								EndIf

								If aDocs[nPosDoc][1] $ '34' //- (3- Titulo a pagar | 4- Titulo a receber)
									//- Totalizador de Titulos
									nTitVlr	+= oModelCNE:GetValue("CNE_VLTOT") * nParte
									nVlrDescIt += oModelCNE:GetValue("CNE_VLDESC") * nParte
																		
									If	lAposEsp		
									
										If	oModelCNE:GetValue("CNE_15ANOS") > 0
											nSoma15a += oModelCNE:GetValue("CNE_15ANOS")
										Endif
								
										If	oModelCNE:GetValue("CNE_20ANOS") > 0
											nSoma20a += oModelCNE:GetValue("CNE_20ANOS")
										Endif
								
										If	oModelCNE:GetValue("CNE_25ANOS") > 0
											nSoma25a += oModelCNE:GetValue("CNE_25ANOS")
										Endif
										
									Endif 								 
									
								ElseIf !lProdServ

									If nPrecoArred > 0 //Quando o preço for zero não adiciona itens
	
										cItemDetail	:= Soma1(cItemDetail) //Adiciona um novo aItem e alimenta
										aAdd(aItem,{}) //Gera item do pedido
										nPosItem 		:= Len(aItem)
	
										If aDocs[nPosDoc][1] == '1' .AND. nPrecoArred > 0 // pedido de Compra
	
											DbSelectArea("CNB")
											CNB->(DbSetOrder(1))//CNB_FILIAL+CNB_CONTRA+CNB_REVISA+CNB_NUMERO+CNB_ITEM
											CNB->(DbSeek(xFilial("CNB"/*,cFilCtr*/)+oModelCND:GetValue("CND_CONTRA")+oModelCND:GetValue("CND_REVISA")+oModelCXN:GetValue("CXN_NUMPLA")+oModelCNE:GetValue("CNE_ITEM") ))
		
											aAdd(aItem[nPosItem],{"C7_ITEM"		,cItemDetail						,NIL}) //Item
											aAdd(aItem[nPosItem],{"C7_PRODUTO"	,oModelCNE:GetValue("CNE_PRODUT")	,NIL}) //Produto
											aAdd(aItem[nPosItem],{"C7_DESCRI"	,SB1->B1_DESC						,NIL}) //Descricao
											aAdd(aItem[nPosItem],{"C7_QUANT"	,nQuantArred						,NIL}) //Quantidade
											aAdd(aItem[nPosItem],{"C7_QTDSOL"	,nQuantArred						,NIL}) //Quantidade solicitada
											aAdd(aItem[nPosItem],{"C7_UM"		,SB1->B1_UM							,NIL}) //Unidade de Medida
											aAdd(aItem[nPosItem],{"C7_QTSEGUM"	,ConvUm(SB1->B1_COD,nQuantArred,0,2),NIL}) //Segunda unidade de medida
											aAdd(aItem[nPosItem],{"C7_PRECO"	,nPrecoArred						,NIL}) //Preco unitario
											aAdd(aItem[nPosItem],{"C7_IPI"		,SB1->B1_IPI						,NIL}) //IPI
											aAdd(aItem[nPosItem],{"C7_DATPRF"	,oModelCNE:GetValue("CNE_DTENT")	,NIL}) //Data de entrega
											aAdd(aItem[nPosItem],{"C7_LOCAL"	,SB1->B1_LOCPAD						,NIL}) //Local
											aAdd(aItem[nPosItem],{"C7_TES"		,oModelCNE:GetValue("CNE_TE")		,Nil}) // TES
											If cPaisLoc == "RUS"
												aAdd(aItem[nPosItem],{"C7_CF"		,oModelCNE:GetValue("CNE_CF")		,Nil}) // Fiscal COde
											EndIf
											aAdd(aItem[nPosItem],{"C7_OBS"		,oModelCND:GetValue("CND_OBS")		,Nil}) //Observação
											aAdd(aItem[nPosItem],{"C7_ITEMED"	,oModelCNE:GetValue("CNE_ITEM")		,Nil}) //Item da Medicao
											aAdd(aItem[nPosItem],{"C7_VLDESC"	,nVlItDesc							,NIL}) //Desconto Item
											aAdd(aItem[nPosItem],{"C7_CC"		,oModelCNE:GetValue("CNE_CC")		,NIL}) //Centro de custo
											aAdd(aItem[nPosItem],{"C7_CONTA"	,oModelCNE:GetValue("CNE_CONTA")	,NIL}) //Conta
											aAdd(aItem[nPosItem],{"C7_ITEMCTA"	,oModelCNE:GetValue("CNE_ITEMCT")	,NIL}) //Item de conta
											aAdd(aItem[nPosItem],{"C7_CLVL"		,oModelCNE:GetValue("CNE_CLVL")		,NIL}) //Classe de valor
											aAdd(aItem[nPosItem],{"C7_CONTRA"	,cContra							,NIL}) //
											aAdd(aItem[nPosItem],{"C7_CONTREV"	,cRevisa							,NIL}) //
											aAdd(aItem[nPosItem],{"C7_PLANILH"	,cNumPlan							,NIL}) //
											aAdd(aItem[nPosItem],{"C7_MEDICAO"	,cNumMed							,NIL}) //
											aAdd(aItem[nPosItem],{"C7_CODNE"	,oModelCNE:GetValue("CNE_CODNE")	,NIL}) //Código da nota de empenho
											aAdd(aItem[nPosItem],{"C7_ITEMNE" 	,oModelCNE:GetValue("CNE_ITEMNE")	,NIL}) //Item da Nota de empenho
											aAdd(aItem[nPosItem],{"C7_FISCORI"	,CNB->CNB_FILORI					,NIL}) //Filial de origem da SC
		
											If !Empty(CNB->CNB_NUMSC)
												aAdd(aItem[nPosItem],{"C7_NUMSC"	,CNB->CNB_NUMSC					,NIL}) //Solicitacao
												aAdd(aItem[nPosItem],{"C7_ITEMSC"	,CNB->CNB_ITEMSC				,NIL}) //Item solicitacao
											EndIf
		
											For nB := 1 To Len(aCTBEnt) //Entidades Contabeis
												If SC7->(FieldPos("C7_EC"+aCTBEnt[nB]+"CR")) > 0 .And. CNE->(FieldPos("CNE_EC"+aCTBEnt[nB]+"CR")) > 0
													aAdd(aItem[nPosItem],{"C7_EC"+aCTBEnt[nB]+"CR"	,oModelCNE:GetValue("CNE_EC"+aCTBEnt[nB]+"CR")	,NIL}) //Entidades Contabeis Credito
													aAdd(aItem[nPosItem],{"C7_EC"+aCTBEnt[nB]+"DB"	,oModelCNE:GetValue("CNE_EC"+aCTBEnt[nB]+"DB")	,NIL}) //Entidades Contabeis Debito
												EndIf
											Next nB
	
										ElseIf aDocs[nPosDoc][1] == '2' .AND. nPrecoArred > 0// pedido de venda
	
											aAdd(aItem[nPosItem],{"C6_NUM"		,cNumCab							,Nil}) // Numero do Pedido
											aAdd(aItem[nPosItem],{"C6_ITEM"		,cItemDetail						,Nil}) // Numero do Item no Pedido
											aAdd(aItem[nPosItem],{"C6_PRODUTO"	,oModelCNE:GetValue("CNE_PRODUT")	,Nil}) // Codigo do Produto
											aAdd(aItem[nPosItem],{"C6_DESCRI"	,SB1->B1_DESC						,Nil}) // Descricao
											aAdd(aItem[nPosItem],{"C6_QTDVEN"	,nQuantArred						,Nil}) // Quantidade Vendida
											aAdd(aItem[nPosItem],{"C6_PRUNIT"	,nPrecoArred						,Nil}) // PRECO DE LISTA
											aAdd(aItem[nPosItem],{"C6_PRCVEN"	,nPrecoArred						,Nil}) // Preco Unitario Liquido
											aAdd(aItem[nPosItem],{"C6_ENTREG"	,oModelCNE:GetValue("CNE_DTENT")	,Nil}) // Data da Entrega
											aAdd(aItem[nPosItem],{"C6_UM"		,SB1->B1_UM							,Nil}) // Unidade de Medida Primar.
											aAdd(aItem[nPosItem],{"C6_CLI"		,aQuebraEnv[nA][2]					,Nil}) // Cliente
											aAdd(aItem[nPosItem],{"C6_LOJA"		,aQuebraEnv[nA][3]					,Nil}) // Loja do Cliente
										 	aAdd(aItem[nPosItem],{"C6_TES"		,oModelCNE:GetValue("CNE_TS")		,Nil}) // TES
											If cPaisLoc == "RUS"
												aAdd(aItem[nPosItem],{"C6_CF"	,oModelCNE:GetValue("CNE_CF")		,Nil}) // Fiscal Code
											EndIf
											aAdd(aItem[nPosItem],{"C6_LOCAL"	,SB1->B1_LOCPAD						,Nil}) // Local
											aAdd(aItem[nPosItem],{"C6_ITEMED"	,oModelCNE:GetValue("CNE_ITEM")		,Nil}) // Item da Medicao
											aAdd(aItem[nPosItem],{"C6_VALDESC"	,nVlItDesc							,Nil}) // Desconto Item
											aAdd(aItem[nPosItem],{"C6_ABATINS"	,oModelCNE:GetValue("CNE_ABTINS")	,Nil}) // ABATIMENTO DE INSS
											aAdd(aItem[nPosItem],{"C6_CC"		,oModelCNE:GetValue("CNE_CC")		,Nil}) // Centro de Custo
											aAdd(aItem[nPosItem],{"C6_CONTA"	,oModelCNE:GetValue("CNE_CONTA")	,Nil}) // Conta Contábil
											aAdd(aItem[nPosItem],{"C6_ITEMCTA"	,oModelCNE:GetValue("CNE_ITEMCT")	,Nil}) // Item da Conta Contábil
											aAdd(aItem[nPosItem],{"C6_CLVL"		,oModelCNE:GetValue("CNE_CLVL")		,Nil}) // Classe valor COntabil
		
											//Preenche ARRAYS com dados sobre aposentadoria especial REINF
											If	lAposEsp	
												aAdd(aItemApo , { cItemDetail ,oModelCNE:GetValue("CNE_15ANOS") , oModelCNE:GetValue("CNE_20ANOS") , oModelCNE:GetValue("CNE_25ANOS") })
											Endif 										
											
											If oModelCNE:GetValue("CNE_FLGCMS") == "1" //Verifica se o item e comissionado
												cVend:="1"
												For nB:=1 to oModelCNU:Length()
													oModelCNU:GoLine(nB)
													If	!(Empty(oModelCNU:GetValue("CNU_CODVD"))) //Complementa as comissoes de acordo com os contratos
														aAdd(aItem[nPosItem]	,{"C6_COMIS"+cVend,oModelCNU:GetValue("CNU_PERCCM"),NIL})
														cVend:=Soma1(cVend)
													EndIf
												Next nB
											EndIf
										EndIf

										For nB := 1 to oModelCNZ:Length()
											oModelCNZ:GoLine(nB)
											If !Empty(oModelCNZ:GetValue("CNZ_PERC"))
												If nB == 1
													aAdd(aRateio,Array(2))
													aRateio[len(aRateio)][1] := cItemDetail
													aRateio[len(aRateio)][2] := {}
												EndIf
												nPosRat := len(aRateio)
												aAdd(aRateio[nPosRat][2],{})
		
												If aDocs[nPosDoc][1] == '1' // pedido de Compra
													aAdd(aRateio[nPosRat][2][nB],{"CH_ITEMPD"	,cItemDetail					 ,NIL})
													aAdd(aRateio[nPosRat][2][nB],{"CH_ITEM"		,oModelCNZ:GetValue("CNZ_ITEM")	 ,NIL})
													aAdd(aRateio[nPosRat][2][nB],{"CH_PERC"		,oModelCNZ:GetValue("CNZ_PERC")	 ,NIL})
													aAdd(aRateio[nPosRat][2][nB],{"CH_CC"		,oModelCNZ:GetValue("CNZ_CC")	 ,NIL})
													aAdd(aRateio[nPosRat][2][nB],{"CH_CONTA"	,oModelCNZ:GetValue("CNZ_CONTA") ,NIL})
													aAdd(aRateio[nPosRat][2][nB],{"CH_ITEMCTA"	,oModelCNZ:GetValue("CNZ_ITEMCT"),NIL})
													aAdd(aRateio[nPosRat][2][nB],{"CH_CLVL"		,oModelCNZ:GetValue("CNZ_CLVL")	 ,NIL})
		
													For nCount := 1 To Len(aCTBEnt)
														If SCH->(FieldPos("CH_EC" +aCTBEnt[nCount] +"CR")) > 0 .And. CNZ->(FieldPos("CNZ_EC" +aCTBEnt[nCount] +"CR")) > 0
															aAdd(aRateio[nPosRat][2][nB],{"CH_EC"+aCTBEnt[nCount] +"CR"	, oModelCNZ:GetValue("CNZ_EC"+aCTBEnt[nCount] +"CR")	, NIL})
															aAdd(aRateio[nPosRat][2][nB],{"CH_EC"+aCTBEnt[nCount] +"DB"	, oModelCNZ:GetValue("CNZ_EC"+aCTBEnt[nCount] +"DB")	, NIL})
														EndIf
													Next nCount
		
												ElseIf aDocs[nPosDoc][1] == '2' // pedido de venda
													aAdd(aRateio[nPosRat][2][nB],{"AGG_ITEMPD"	,cItemDetail					 ,NIL})
													aAdd(aRateio[nPosRat][2][nB],{"AGG_ITEM"	,oModelCNZ:GetValue("CNZ_ITEM")	 ,NIL})
													aAdd(aRateio[nPosRat][2][nB],{"AGG_PERC"	,oModelCNZ:GetValue("CNZ_PERC")	 ,NIL})
													aAdd(aRateio[nPosRat][2][nB],{"AGG_CC"		,oModelCNZ:GetValue("CNZ_CC")	 ,NIL})
													aAdd(aRateio[nPosRat][2][nB],{"AGG_CONTA"	,oModelCNZ:GetValue("CNZ_CONTA") ,NIL})
													aAdd(aRateio[nPosRat][2][nB],{"AGG_ITEMCT"	,oModelCNZ:GetValue("CNZ_ITEMCT"),NIL})
													aAdd(aRateio[nPosRat][2][nB],{"AGG_CLVL"	,oModelCNZ:GetValue("CNZ_CLVL")	 ,NIL})
		
													For nCount := 1 To Len(aCTBEnt)
														If AGG->(FieldPos("AGG_EC" +aCTBEnt[nCount] +"CR")) > 0 .And. CNZ->(FieldPos("CNZ_EC" +aCTBEnt[nCount] +"CR")) > 0
															aAdd(aRateio[nPosRat][2][nB],{"AGG_EC"+aCTBEnt[nCount] +"CR"	, oModelCNZ:GetValue("CNZ_EC"+aCTBEnt[nCount] +"CR")	, NIL})
															aAdd(aRateio[nPosRat][2][nB],{"AGG_EC"+aCTBEnt[nCount] +"DB"	, oModelCNZ:GetValue("CNZ_EC"+aCTBEnt[nCount] +"DB")	, NIL})
														EndIf
													Next nCount
												EndIf
											EndIf
										Next nB
									EndIf
								Else
									If aDocs[nPosDoc][1] == '1' // pedido de compra
										aItem[nPosItem][8][2]	+= nValorArred  //-- Preco unitario
										aItem[nPosItem][12][2] 	:= oModelCNE:GetValue("CNE_TE") //-- TES
										aItem[nPosItem][13][2] 	:= oModelCNE:GetValue("CNE_ITEM") //-- Item da Medicao
										aItem[nPosItem][14][2] 	+= nVlItDesc //-- Desconto Item
										aItem[nPosItem][15][2] 	:= oModelCNE:GetValue("CNE_CC") //-- Centro de custo
										aItem[nPosItem][16][2] 	:= oModelCNE:GetValue("CNE_CONTA") //-- Conta
										aItem[nPosItem][17][2] 	:= oModelCNE:GetValue("CNE_ITEMCT") //-- Item de conta
										aItem[nPosItem][18][2] 	:= oModelCNE:GetValue("CNE_CLVL") //-- Classe de valor
									ElseIf aDocs[nPosDoc][1] == '2' // pedido de venda
										//-- Atualiza valores para produto de servico
										lAglutinado	:= .T.
										aItem[nPosItem][6][2] 	+= nValorArred //-- PRECO DE LISTA
										aItem[nPosItem][7][2] 	+= nValorArred //-- Preco Unitario Liquido
										aItem[nPosItem][12][2] 	:= oModelCNE:GetValue("CNE_TS") //-- TES
										aItem[nPosItem][14][2] 	:= oModelCNE:GetValue("CNE_ITEM") //-- Item da Medicao
										aItem[nPosItem][15][2] 	+= nVlItDesc //-- Desconto Item
										aItem[nPosItem][16][2] 	+= oModelCNE:GetValue("CNE_ABTINS") //-- Classe de valor
									EndIf

									//-- //Rateio de Serviço
									If Empty(cCampoECCNZ)//-- Campos de entidades adicionais CNZ
										For nB := 1 To Len(aCTBEnt)
											If CNZ->(FieldPos("CNZ_EC"+aCTBEnt[nB]+"CR")) > 0 .And. CNZ->(FieldPos("CNZ_EC"+aCTBEnt[nB]+"DB")) > 0
												cCampoECCNZ += "CNZ_EC"+aCTBEnt[nB]+"CR|CNZ_EC"+aCTBEnt[nB]+"DB|"
												(lEC+aCTBEnt[nB]) := .T.
											EndIf
										Next nB
									EndIf
									If Empty(cCampoECCNE)//-- Campos de entidades adicionais CNE
										For nB := 1 To Len(aCTBEnt)
											If CNE->(FieldPos("CNE_EC"+aCTBEnt[nB]+"CR")) > 0 .And. CNZ->(FieldPos("CNE_EC"+aCTBEnt[nB]+"DB")) > 0
												cCampoECCNZ += "CNE_EC"+aCTBEnt[nB]+"CR|CNE_EC"+aCTBEnt[nB]+"DB|"
												(lEC+aCTBEnt[nB]) := .T.
											EndIf
										Next nB
									EndIf
									cChaveRat:= "" //-- Limpa a chave antes de comecar
									oModelCNZ:GoLine(1)

									If Empty(oModelCNZ:GetValue("CNZ_PERC"))// verifica rateio na CNZ, caso nao exista ver CNE
										For nCount := 1 To Len(aCamposCNE)// Monta Chave de Busca
											If (aCamposCNE[nCount][3] $ "CNE_CC|CNE_CONTA|CNE_CLVL")  .Or. (aCamposCNE[nCount][3] $ cCampoECCNE) .Or. aCamposCNE[nCount][3] == "CNE_ITEMCT"
												cChaveRat +=  oModelCNE:GetValue(aCamposCNE[nCount][3])
											EndIf
										Next nCount
		
										If ( nPosRat := aScan(aRatServ,{|x| x[1] == cChaveRat} ) ) == 0 // Procura chave Igual
											// Adiciona uma nova chave.
											aAdd(aRatServ,Array(16))//{/*cChave*/,/*cValor1*/,/*CC*/,/*CONTA*/,/*ITEMCT*/,/*CLVL*/,/*05CR*/,/*05DB*/,/*06CR*/,/*06DB*/,/*07CR*/,/*	07DB*/,/*08CR*/,/*08DB*/,/*09CR*/,/*09DB*/})
											nPosRat := Len(aRatServ)
											aRatServ[nPosRat][1]:= cChaveRat
											aRatServ[nPosRat][2]:= 0 //Valor
											aRatServ[nPosRat][3]:= oModelCNE:GetValue("CNE_CC")
											aRatServ[nPosRat][4]:= oModelCNE:GetValue("CNE_CONTA")
											aRatServ[nPosRat][5]:= oModelCNE:GetValue("CNE_ITEMCT")
											aRatServ[nPosRat][6]:= oModelCNE:GetValue("CNE_CLVL")
											aRatServ[nPosRat][7]:= IIF(lECCNE05,oModelCNE:GetValue("CNE_EC05CR"),"")
											aRatServ[nPosRat][8]:= IIF(lECCNE05,oModelCNE:GetValue("CNE_EC05DB"),"")
											aRatServ[nPosRat][9]:= IIF(lECCNE06,oModelCNE:GetValue("CNE_EC06CR"),"")
											aRatServ[nPosRat][10]:= IIF(lECCNE06,oModelCNE:GetValue("CNE_EC06DB"),"")
											aRatServ[nPosRat][11]:= IIF(lECCNE07,oModelCNE:GetValue("CNE_EC07CR"),"")
											aRatServ[nPosRat][12]:= IIF(lECCNE07,oModelCNE:GetValue("CNE_EC07DB"),"")
											aRatServ[nPosRat][13]:= IIF(lECCNE08,oModelCNE:GetValue("CNE_EC08CR"),"")
											aRatServ[nPosRat][14]:= IIF(lECCNE08,oModelCNE:GetValue("CNE_EC08DB"),"")
											aRatServ[nPosRat][15]:= IIF(lECCNE09,oModelCNE:GetValue("CNE_EC09CR"),"")
											aRatServ[nPosRat][16]:= IIF(lECCNE09,oModelCNE:GetValue("CNE_EC09DB"),"")
										EndIf
										aRatServ[nPosRat][2] += nValorArred  //Valor
									Else
										For nB := 1 to oModelCNZ:Length() // Roda tabela de rateio
											oModelCNZ:GoLine(nB)
											cChaveRat := ""
											For nCount := 1 To Len(aCamposCNZ)// Monta Chave de Busca
												If (aCamposCNZ[nCount][3] $ "CNZ_CC|CNZ_CONTA|CNZ_CLVL")  .Or. (aCamposCNZ[nCount][3] $ cCampoECCNZ) .Or. aCamposCNZ[nCount][3] == "CNZ_ITEMCT"
													cChaveRat +=  oModelCNZ:GetValue(aCamposCNZ[nCount][3])
												EndIf
											Next nCount
		
											If ( nPosRat := aScan(aRatServ,{|x| x[1] == cChaveRat} ) ) == 0 // Procura chave Igual
												// Adiciona uma nova chave.
											 	aAdd(aRatServ,Array(16))//{/*cChave*/,/*cValor1*/,/*CC*/,/*CONTA*/,/*ITEMCT*/,/*CLVL*/,/*05CR*/,/*05DB*/,/*06CR*/,/*06DB*/,/*07CR*/,/*	07DB*/,/*08CR*/,/*08DB*/,/*09CR*/,/*09DB*/})
											 	nPosRat := Len(aRatServ)
											 	aRatServ[nPosRat][1]:= cChaveRat
											 	aRatServ[nPosRat][2]:= 0 //Valor
											 	aRatServ[nPosRat][3]:= oModelCNZ:GetValue("CNZ_CC")
											 	aRatServ[nPosRat][4]:= oModelCNZ:GetValue("CNZ_CONTA")
											 	aRatServ[nPosRat][5]:= oModelCNZ:GetValue("CNZ_ITEMCT")
											 	aRatServ[nPosRat][6]:= oModelCNZ:GetValue("CNZ_CLVL")
											 	aRatServ[nPosRat][7]:= IIF(lEC05,oModelCNZ:GetValue("CNZ_EC05CR"),"")
											 	aRatServ[nPosRat][8]:= IIF(lEC05,oModelCNZ:GetValue("CNZ_EC05DB"),"")
												aRatServ[nPosRat][9]:= IIF(lEC06,oModelCNZ:GetValue("CNZ_EC06CR"),"")
												aRatServ[nPosRat][10]:= IIF(lEC06,oModelCNZ:GetValue("CNZ_EC06DB"),"")
												aRatServ[nPosRat][11]:= IIF(lEC07,oModelCNZ:GetValue("CNZ_EC07CR"),"")
												aRatServ[nPosRat][12]:= IIF(lEC07,oModelCNZ:GetValue("CNZ_EC07DB"),"")
												aRatServ[nPosRat][13]:= IIF(lEC08,oModelCNZ:GetValue("CNZ_EC08CR"),"")
												aRatServ[nPosRat][14]:= IIF(lEC08,oModelCNZ:GetValue("CNZ_EC08DB"),"")
												aRatServ[nPosRat][15]:= IIF(lEC09,oModelCNZ:GetValue("CNZ_EC09CR"),"")
												aRatServ[nPosRat][16]:= IIF(lEC09,oModelCNZ:GetValue("CNZ_EC09DB"),"")
											EndIf
											aRatServ[nPosRat][2] += (nValorArred * oModelCNZ:GetValue("CNZ_PERC") / 100) //Valor
										Next nB
									EndIf
								EndIf
								If nPrecoArred > 0 .and. !lAglutinado
									//-- Atualiza CXJ
									If IsInCallStack("CN300RevPd")
										oModelCXJ:SeekLine({{"CXJ_NUMPLA",oModelCXN:GetValue("CXN_NUMPLA")},{"CXJ_ITEMPL",oModelCNE:GetValue("CNE_ITEM")}})
									ElseIf !Empty(oModelCXJ:GetValue("CXJ_NUMPLA"))
										oModelCXJ:AddLine()
									EndIf
		
									If aDocs[nPosDoc][1]  $ '34'
										oModelCXJ:SetValue("CXJ_NUMTIT",cNumCab)
									Else
										oModelCXJ:SetValue("CXJ_NUMPED",cNumCab)
										oModelCXJ:SetValue("CXJ_ITEMPE",cItemDetail)
									EndIf
									oModelCXJ:SetValue("CXJ_NUMPLA",oModelCXN:GetValue("CXN_NUMPLA"))
									oModelCXJ:SetValue("CXJ_ITEMPL",oModelCNE:GetValue("CNE_ITEM"))
									oModelCXJ:SetValue("CXJ_ID",aQuebraEnv[nA][6][nX][2])
									oModelCXJ:SetValue("CXJ_PRTENV",aQuebraEnv[nA][7])
								EndIf
							EndIf
						Next nZ

						//-- Atualiza cabeçalho do Titulo com valores de Acrescimo ou Decrescimo.
						If aDocs[nPosDoc][1]  $ '34' //(3 = Titulo a pagar | 4 = Titulo a receber)
							aCab[13][2]	:= nTitVlr
							aCab[19][2]	:= nVlrDescIt + nDescMedPl //Desconto da medição
							aCab[20][2]	:= nMultMedPl //Multa da medição
							aCab[21][2]	:= nBoniMedPl //Bonificação da medição
							
							nTotDecres := nVlrDescIt + nDescMedPl 
							
							If aDocs[nPosDoc][1] == "3" //Se for título a pagar, gera multa como decréscimo e bonificação como acréscimo
								nTotAcres := nBoniMedPl
								nTotDecres += nMultMedPl																
							Else //Se for título a receber, gera multa como acréscimo e bonificação como decréscimo
								nTotAcres := nMultMedPl
								nTotDecres += nBoniMedPl						
							Endif
							
							//Tratamento de compensação de valores para informar os campos de decréscimo ou acréscimo do título, pois não pode ter valor nesses dois campos ao mesmo tempo
							If nTotAcres > nTotDecres
								aCab[14][2]	:= nTotAcres - nTotDecres //Acréscimo
							ElseIf nTotAcres < nTotDecres
								aCab[15][2]	:= nTotDecres - nTotAcres //Descréscimo
							Endif
						EndIf

						//-- Recria Array de Rateio de Servico
						If lProdServ
							nAcumulado := 0
							If Len(aRatServ) > 0
								aAdd(aRateio,Array(2))
								nPosRat := len(aRateio)
								aRateio[nPosRat][1] := cItemDetail
								aRateio[nPosRat][2] := {}
							EndIf
							For nB := 1 to Len(aRatServ)
								aAdd(aRateio[nPosRat][2],{})
								If nB <> Len(aRatServ)
									If lCompra
										nValor := Round(aRatServ[nB][2] / aItem[nPosItem][8][2] * 100 , TamSx3("CH_PERC")[2])
									Else
										nValor := Round(aRatServ[nB][2] / aItem[nPosItem][6][2] * 100 , TamSx3("AGG_PERC")[2] )
									Endif
									nAcumulado += nValor
								Else
									If lCompra
										nValor := Round(100 - nAcumulado , TamSx3("CH_PERC")[2])
									Else
										nValor := Round(100 - nAcumulado , TamSx3("AGG_PERC")[2])
									EndIf
								EndIf
		
								If aDocs[nPosDoc][1] == '1' // pedido de Compra
									aAdd(aRateio[nPosRat][2][nB],{"CH_ITEMPD"		, cItemDetail	, nil})
									aAdd(aRateio[nPosRat][2][nB],{"CH_ITEM"		, StrZero(nB,TamSX3("CNZ_ITEM")[1],0)				, nil})
									aAdd(aRateio[nPosRat][2][nB],{"CH_PERC"		, nValor	, nil})
									aAdd(aRateio[nPosRat][2][nB],{"CH_CC"			, aRatServ[nB][3]	, nil})
									aAdd(aRateio[nPosRat][2][nB],{"CH_CONTA"		, aRatServ[nB][4]	, nil})
									aAdd(aRateio[nPosRat][2][nB],{"CH_ITEMCTA"	, aRatServ[nB][5]	, nil})
									aAdd(aRateio[nPosRat][2][nB],{"CH_CLVL"		, aRatServ[nB][6]	, nil})
									If lEC05
										aAdd(aRateio[nPosRat][2][nB],{"CH_EC05CR"	, aRatServ[nB][7]	, nil})
										aAdd(aRateio[nPosRat][2][nB],{"CH_EC05DB"	, aRatServ[nB][8]	, nil})
									EndIf
									If lEC06
										aAdd(aRateio[nPosRat][2][nB],{"CH_EC06CR"	, aRatServ[nB][9]	, nil})
										aAdd(aRateio[nPosRat][2][nB],{"CH_EC06DB"	, aRatServ[nB][10], nil})
									EndIf
									If lEC07
										aAdd(aRateio[nPosRat][2][nB],{"CH_EC07CR"	, aRatServ[nB][11], nil})
										aAdd(aRateio[nPosRat][2][nB],{"CH_EC07DB"	, aRatServ[nB][12], nil})
									EndIf
									If lEC08
										aAdd(aRateio[nPosRat][2][nB],{"CH_EC08CR"	, aRatServ[nB][13], nil})
										aAdd(aRateio[nPosRat][2][nB],{"CH_EC08DB"	, aRatServ[nB][14], nil})
									EndIf
									If lEC09
										aAdd(aRateio[nPosRat][2][nB],{"CH_EC09CR"	, aRatServ[nB][15], nil})
										aAdd(aRateio[nPosRat][2][nB],{"CH_EC09DB"	, aRatServ[nB][16], nil})
									EndIf
								ElseIf aDocs[nPosDoc][1] == '2' // pedido de venda
									aAdd(aRateio[nPosRat][2][nB],{"AGG_ITEMPD"	, cItemDetail	, nil})
									aAdd(aRateio[nPosRat][2][nB],{"AGG_ITEM"	, StrZero(nB,TamSX3("CNZ_ITEM")[1],0)				, nil})
									aAdd(aRateio[nPosRat][2][nB],{"AGG_PERC"		, nValor 	, nil})
									aAdd(aRateio[nPosRat][2][nB],{"AGG_CC"		, aRatServ[nB][3]	, nil})
									aAdd(aRateio[nPosRat][2][nB],{"AGG_CONTA"		, aRatServ[nB][4]	, nil})
									aAdd(aRateio[nPosRat][2][nB],{"AGG_ITEMCT"	, aRatServ[nB][5]	, nil})
									aAdd(aRateio[nPosRat][2][nB],{"AGG_CLVL"		, aRatServ[nB][6]	, nil})
									If lEC05
										aAdd(aRateio[nPosRat][2][nB],{"AGG_EC05CR"	, aRatServ[nB][7]	, nil})
										aAdd(aRateio[nPosRat][2][nB],{"AGG_EC05DB"	, aRatServ[nB][8]	, nil})
									EndIf
									If lEC06
										aAdd(aRateio[nPosRat][2][nB],{"AGG_EC06CR"	, aRatServ[nB][9]	, nil})
										aAdd(aRateio[nPosRat][2][nB],{"AGG_EC06DB"	, aRatServ[nB][10], nil})
									EndIf
									If lEC07
										aAdd(aRateio[nPosRat][2][nB],{"AGG_EC07CR"	, aRatServ[nB][11], nil})
										aAdd(aRateio[nPosRat][2][nB],{"AGG_EC07DB"	, aRatServ[nB][12], nil})
									EndIf
									If lEC08
										aAdd(aRateio[nPosRat][2][nB],{"AGG_EC08CR"	, aRatServ[nB][13], nil})
										aAdd(aRateio[nPosRat][2][nB],{"AGG_EC08DB"	, aRatServ[nB][14], nil})
									EndIf
									If lEC09
										aAdd(aRateio[nPosRat][2][nB],{"AGG_EC09CR"	, aRatServ[nB][15], nil})
										aAdd(aRateio[nPosRat][2][nB],{"AGG_EC09DB"	, aRatServ[nB][16], nil})
									EndIf
								EndIf
							Next nB
						EndIf
					Next nY

					//-- Chama ponto de entrada para tratamento de campos especificos na geracao do pedido de compra / venda
					If lCN121PED
						aRet := ExecBlock("CN121PED",.f.,.f.,{aCab,aItem})
						If Valtype(aRet) == "A"
							aCab := aRet[1]
							aItem := aRet[2]
						EndIf
					EndIf
			
					//Prepara ARRAY aAposEsp (Aposentadoria Especial REINF)unificando dados do aItemApo	
				    For nAp:= 1 to Len(aItemApo)
				     
				        aLinhApo := {}
				     	 
				     	aAdd(aLinhApo , { aItemApo[nAp,1] , aItemApo[nAp,2], aItemApo[nAp,3], aItemApo[nAp,4] } ) 
				     	aAdd(aAposEsp , { aItemApo[nAp,1], aLinhApo } )
				     
				    Next nAp
		    
			
					If	( nSoma15a + nSoma20a + nSoma25a ) > 0   
						
						//Prepara ARRAY para complemento de titulo (FKF)							
						aSeFKF := { { "FKF_TPSERV", oModelCNE:GetValue("CNE_TPSERV") , NIL }} 
							
						//Prepara ARRAY para complemento de impostos x titulos (FKG)
						If	nSoma15a > 0 	
											
							nItemFKG ++
								
							aItemFKG := {{ "FKG_ITEM"  , StrZero(nItemFKG,6) 	, NIL },;
				 						 { "FKG_IDFKE" , cMDAP15			 	, NIL },; 
										 { "FKG_DESCR" , STR0167				, NIL },; 
										 { "FKG_BASECA", nSoma15a				, NIL }}
					 										 
							aAdd(aSeFKG,aItemFKG)			 										 
								
						Endif
										
						If	nSoma20a > 0 	
										
							nItemFKG ++
			
							aItemFKG := {{ "FKG_ITEM"  , StrZero(nItemFKG,6)		, NIL },;
										 { "FKG_IDFKE" , cMDAP20				 	, NIL },; 
										 { "FKG_DESCR" , STR0168					, NIL },;
										 { "FKG_BASECA", nSoma20a  					, NIL }}  
					 										 
							aAdd(aSeFKG,aItemFKG)			 										 
								
						Endif
										
						If	nSoma25a > 0 	
											
							nItemFKG ++
			
							aItemFKG := {{ "FKG_ITEM"  , StrZero(nItemFKG,6) 		, NIL },;
										 { "FKG_IDFKE" , cMDAP25				 	, NIL },; 
										 { "FKG_DESCR" , STR0169			 		, NIL },;
										 { "FKG_BASECA", nSoma25a					, NIL }}  
					 										 
							aAdd(aSeFKG,aItemFKG)			 										 
								
						Endif	
										
					Endif 				

					//-- Atualiza aDocs
					aDocs[nPosDoc][2] := aClone(aCab)
					aDocs[nPosDoc][3] := aClone(aItem)
					aDocs[nPosDoc][4] := aClone(aRateio)
					aDocs[nPosDoc][5] := aClone(aSeFKF)
					aDocs[nPosDoc][6] := aClone(aSeFKG)
					aDocs[nPosDoc][7] := aClone(aAposEsp)
					lAglutinado	:= .F.
			
				Next nX
			Next nA
		EndIf
	EndIf
Next nCXN

//- Chama as rotinas automaticas dos documentos
Begin Transaction

	For nA := 1 To Len(aDocs)
		Do Case
			Case aDocs[nA][1] == '1'  // Pedido de Compra
				//-- Mata120
				If Len(aDocs[nA][3]) > 0
					MSExecAuto({|v,x,y,z,w,a| MATA120(v,x,y,z,w,a)},1,aDocs[nA][2],aDocs[nA][3],3,.F.,aDocs[nA][4])
					If !lMsErroAuto
						C121AtuCXJ(oModel,'CXJ_NUMPED',SC7->C7_NUM,aDocs[nA])
						AtuCNEPed(oModel, aDocs[nA,3])//Atualiza CNE						
					EndIf
				EndIf
			Case aDocs[nA][1] == '2'  // Pedido de Venda
				If Len(aDocs[nA][3]) > 0
					//-- Mata410
					MSExecAuto({|x,y,z,w,a| Mata410(x,y,z,,,,,w,,,,,,,a)},aDocs[nA][2],aDocs[nA][3],3,aDocs[nA][4],aDocs[nA][7]) 
					C121AtuCXJ( oModel , 'CXJ_NUMPED' , SC5->C5_NUM , aDocs[nA] )					
				EndIf

			Case aDocs[nA][1] $ '34' // Titulos 3- Pagar [E2], 4- Receber [E1]
				//- Popula variaveis para gerar titulo
				lMod 	:= Iif (aDocs[nA][1] == '3',.T.,.F.)

				cRetPrf := PadR(cCNPREMD	,Iif(lMod	,Len(SE2->E2_PREFIXO)	,Len(SE1->E1_PREFIXO)))
				cTpTit 	:= PadR(cCNTPTMD	,Iif(lMod	,Len(SE2->E2_TIPO)		,Len(SE1->E1_TIPO)))
				cRetNat := Cn121NatTt(lMod,aDocs,cFilContr,nA)

				cParcela:= StrZero(1,Iif(lMod,Len(SE2->E2_PARCELA),Len(SE1->E1_PARCELA)))
				aCond 	:= {{aDocs[nA][2][5][2], aDocs[nA][2][13][2]}}

				If lGeraCP
					aCond := Condicao(aCond[1,2],cCondPgto,,aCond[1,1])
				EndIf

				For nB := 1 to Len(aCond)
                    aDocs[nA][2][5][2] 	:= aCond[nB,1]
                    aDocs[nA][2][6][2]   := DataValida(aCond[nB,1],.T.)
                    aDocs[nA][2][7][2] := DataValida(aCond[nB,1],.T.)
					aDocs[nA][2][13][2] := aCond[nB,2]
						
					If lMod
						if nB == 1
							aAdd( aDocs[nA][2],{"E2_PREFIXO"	,cRetPrf	,NIL})
						    aAdd( aDocs[nA][2],{"E2_NATUREZ"	,cRetNat	,NIL})
						    aAdd( aDocs[nA][2],{"E2_PARCELA"	,cParcela	,NIL})
					    	aAdd( aDocs[nA][2],{"E2_TIPO"		,cTpTit		,NIL})
				    	Else
				    		aDocs[nA][2] [ascan(aDocs[na][2],{|x| Trim(x[1]) == "E2_PARCELA" })][2] := cParcela
				        EndIF
				        If	Len(aDocs[nA][5]) > 0 .AND. Len(aDocs[nA][6]) > 0 
				        	aAdd(aDocs[nA][2],{"AUTCMTIT",aDocs[nA][5],Nil})
							aAdd(aDocs[nA][2],{"AUTCMIMP",aDocs[nA][6],Nil})
						Endif 							
						
						If lTxMoeda .And. CND->CND_TXMOED > 0
							aAdd( aDocs[nA][2], { "E2_TXMOEDA", CND->CND_TXMOED, NIL } )
						EndIf
						
						MSExecAuto({|a,b,c| FINA050(a,b,c)} ,aDocs[nA][2],,3)
						
					Else

					    If nB == 1
					    	aAdd( aDocs[nA][2],{"E1_PREFIXO"	,cRetPrf	,NIL})
						   	aAdd( aDocs[nA][2],{"E1_NATUREZ"	,cRetNat	,NIL})
						   	aAdd( aDocs[nA][2],{"E1_PARCELA"	,cParcela	,NIL})
						   	aAdd( aDocs[nA][2],{"E1_TIPO"		,cTpTit		,NIL})
						Else
							aDocs[nA][2] [ascan(aDocs[na][2],{|x| Trim(x[1]) == "E1_PARCELA" })][2] := cParcela
						Endif	
						
						If lTxMoeda .And. CND->CND_TXMOED > 0
							aAdd( aDocs[nA][2], { "E1_TXMOEDA", CND->CND_TXMOED, NIL } )
						EndIf
						
						nPosRatEv	:= aScan( aDocs[nA][2] , { |x| x[1] == 'AUTRATEEV' } )
						
						If nPosRatEv > 0
							MSExecAuto( {|a, b, c, d, e, f, g| FINA040(a,b,c,d,e,f,g)} , aDocs[nA][2] , 3 , , aDocs[nA][2][nPosRatEv][2] ,,aDocs[nA][5], aDocs[nA][6] )
						Else
							MsExecAuto({|a, b, c, d, e, f, g | FINA040(a,b,c,d,e,f,g)}, aDocs[nA][2], 3,,,,aDocs[nA][5], aDocs[nA][6]) 							
						EndIf
					EndIf

					cParcela := Soma1(cParcela)
				Next nB
		EndCase

		If lMsErroAuto
			MostraErro()
			lRet := .F.
			DisarmTransaction()
			Exit
		Endif
	Next nA

	//Grava retencao da caucao
	If !IsExced() .And. !Empty(oModelCND:GetValue('CND_RETCAC'))
		CN121InCau( oModel )
	EndIf

End Transaction

FWModelActive(oModel)

Return lRet
//------------------------------------------------------------------
/*/{Protheus.doc} CN121VlCmp()
Valid do campo competencia
@author alexandre.gimenez
@since 26/08/2015
/*/
//-------------------------------------------------------------------
Function CN121VlCmp()
Local lRet := .T.
Return lRet

//------------------------------------------------------------------
/*/{Protheus.doc} CN121Grids
Limpeza dos grids se usuário muda o contrato
@author rogerio.melonio
@since 24/08/2015
/*/
//-------------------------------------------------------------------
Function CN121Grids( oModel , lDelCXN )
Local aSaveLines:= FWSaveRows()
Local oModelCXN	:= NIL
Local oModelCNE	:= NIL
Local oModelCNR1:= NIL
Local oModelCNR2:= NIL
Local oModelCNK	:= NIL
Local oModelCNZ	:= NIL
Local oModelCXI	:= NIL
Local oModelCXO	:= NIL
Local oModelCXP	:= NIl
Local oModelCNQ	:= NIL

Default oModel := FwModelActive()
Default lDelCXN	:= .T.

oModelCXN	:= oModel:GetModel("CXNDETAIL")
oModelCNE	:= oModel:GetModel("CNEDETAIL")
oModelCNR1	:= oModel:GetModel("CNRDETAIL1")
oModelCNR2	:= oModel:GetModel("CNRDETAIL2")
oModelCNK	:= oModel:GetModel("CNKDETAIL")
oModelCNZ	:= oModel:GetModel("CNZDETAIL")
oModelCXI	:= oModel:GetModel("CXIDETAIL")
oModelCNQ	:= oModel:GetModel("CNQDETAIL")

If AliasIndic('CXO')
	oModelCXO	:= oModel:GetModel("CXODETAIL")
	oModelCXP	:= oModel:GetModel("CXPDETAIL")
EndIf

oModelCXN:SetNoDeleteLine(.F.)
oModelCNE:SetNoDeleteLine(.F.)
oModelCNR1:SetNoDeleteLine(.F.)
oModelCNR2:SetNoDeleteLine(.F.)
oModelCNK:SetNoDeleteLine(.F.)
oModelCNZ:SetNoDeleteLine(.F.)
oModelCXI:SetNoDeleteLine(.F.)
oModelCNQ:SetNoDeleteLine(.F.)

If AliasIndic('CXO')
	oModelCXO:SetNoDeleteLine(.F.)
	oModelCXP:SetNoDeleteLine(.F.)
EndIf

If lDelCXN
	CNTA300DlMd(oModelCXN,'CXN_NUMPLA')
EndIf

CNTA300DlMd(oModelCNE,'CNE_PRODUT')
CNTA300DlMd(oModelCNR1,'CNR_VALOR')
CNTA300DlMd(oModelCNR2,'CNR_VALOR')
CNTA300DlMd(oModelCNK,'CNK_CONTRA')
CNTA300DlMd(oModelCNZ,'CNZ_PERC')
CNTA300DlMd(oModelCXI,'CXI_CONTRA')
CNTA300DlMd(oModelCNQ,'CNQ_TPDESC')

If AliasIndic('CXO')
	CNTA300DlMd(oModelCXO,'CXO_NATURE')
	CNTA300DlMd(oModelCXP,'CXP_PERC')
EndIf

FWRestRows( aSaveLines )

Return Nil

//------------------------------------------------------------------
/*/{Protheus.doc} CN121PrcMd
Retorna a parcela de uma competência de contrato recorrente
Já está posicionado no CNA da planilha que se quer retornar a parcela.
@author rogerio.melonio
@since 26/08/2015
/*/
//-------------------------------------------------------------------
Function CN121PrcMd(cCompet)
Local cParcela		:= CNA->CNA_PROPAR
Local cCpoParcela	:= ""
Local aParcelas		:= {}
Local nParc			:= 0

cCpoParcela := IIf( Empty(CNA->CNA_FORNEC),"E1_PARCELA","E2_PARCELA" )
aParcelas := CN100ParRc(CNA->CNA_PERIOD,CNA->CNA_QTDREC,CNA->CNA_DIASEM,CNA->CNA_DIAMES,CNA->CNA_PROMED,CNA->CNA_DTINI,CNA->CNA_DTFIM,cCpoParcela,CNA->CNA_PERREC)

For nParc := 1 To Len(aParcelas)
	If Substr(Dtoc(aParcelas[nParc][2]),4) <> cCompet
		Loop
	Endif
	If CNA->CNA_MEDEFE = 0
		cParcela	:= aParcelas[nParc][1]
		Exit
	ElseIf nParc > CNA->CNA_MEDEFE
		cParcela	:= aParcelas[nParc][1]
		Exit
	Endif
Next nParc

Return cParcela

//------------------------------------------------------------------
/*/{Protheus.doc} CN121ClrTt
Limpa os totalizadores do cabeçalho.
@author israel.escorizza
@since 28/08/2015
/*/
//-------------------------------------------------------------------
Function CN121ClrTt()
Local oModel 	:= FwModelActive()
Local oModelCXN	:= oModel:GetModel('CXNDETAIL')
Local nX		:= 0

For nX := 1 to oModelCXN:Length()
	oModelCXN:GoLine(nX)
	oModelCXN:SetValue('CXN_CHECK',.F.)
Next nX
Return .T.

//------------------------------------------------------------------
/*/{Protheus.doc} CN121DfLeg
Define o valor da Legenda.
@author israel.escorizza
@since 28/08/2015
/*/
//-------------------------------------------------------------------
Function CN121Situa(oModel)
	Local lRet 		:= .T.
	Local oModelCND	:= Nil
	Default oModel  := FwModelActive()

	oModelCND := oModel:GetModel("CNDMASTER")

	DO CASE
		CASE	Empty(oModelCND:GetValue("CND_DTFIM"));
				.AND. oModelCND:GetValue("CND_ALCAPR") == 'L';
				.AND. oModelCND:GetValue("CND_SERVIC") == '1';
			 	.AND. oModelCND:GetValue("CND_AUTFRN") == '1'
			oModelCND:SetValue("CND_SITUAC","A") //- Medição em Aberto

		CASE 	Empty(oModelCND:GetValue("CND_DTFIM"));
				.AND. oModelCND:GetValue("CND_ALCAPR") == 'L';
				.AND. oModelCND:GetValue("CND_SERVIC") == '2';
				.AND. oModelCND:GetValue("CND_AUTFRN") == '1'
			oModelCND:SetValue("CND_SITUAC","SA") //- Med. Servic. Aberta

		CASE 	Empty(oModelCND:GetValue("CND_DTFIM"));
				.AND. oModelCND:GetValue("CND_ALCAPR") == 'L';
				.AND. oModelCND:GetValue("CND_SERVIC") == '1';
				.AND. oModelCND:GetValue("CND_AUTFRN") == '2'
			oModelCND:SetValue("CND_SITUAC","FA") //- Aut. Fornec. Aberta

		CASE 	Empty(oModelCND:GetValue("CND_DTFIM"));
				.AND. oModelCND:GetValue("CND_ALCAPR") == 'B'
			oModelCND:SetValue("CND_SITUAC","B") //- Medição Bloqueada

		CASE 	Empty(oModelCND:GetValue("CND_DTFIM"));
				.AND. oModelCND:GetValue("CND_ALCAPR") == 'B';
				.AND. !Empty(oModelCND:GetValue("CND_APROV"))
			oModelCND:SetValue("CND_SITUAC","BA") //- Medição Bloqueada por Alçada

		CASE 	!Empty(oModelCND:GetValue("CND_DTFIM"));
				.AND. oModelCND:GetValue("CND_AUTFRN") == '1';
				.AND. oModelCND:GetValue("CND_SERVIC") == '1'
			oModelCND:SetValue("CND_SITUAC","E") //- Medição Encerrada

		CASE 	!Empty(oModelCND:GetValue("CND_DTFIM"));
				.AND. oModelCND:GetValue("CND_SERVIC") == '2';
				.AND. oModelCND:GetValue("CND_AUTFRN") == '1'
			oModelCND:GetValue("CND_SITUAC","SE") //- Med. Servic. Encerrada

		CASE 	!Empty(oModelCND:GetValue("CND_DTFIM"));
				.AND. oModelCND:GetValue("CND_SERVIC") == '1';
				.AND. oModelCND:GetValue("CND_AUTFRN") == '2'
			oModelCND:SetValue("CND_SITUAC","FE") //- Aut. Fornec. Encerrada
	ENDCASE

Return lRet

//------------------------------------------------------------------
/*/{Protheus.doc} CN121MedEnc()
Rotina de processamento do encerramento de medição
@author alexandre.gimenez
@since 01/09/2015
/*/
//-------------------------------------------------------------------
Function CN121MedEnc(nReg,lAviso,lAutoFor,lMedServ)

Local oModel		:= Nil

Local aAreaSX3		:= ""
Local aLPGCT		:= {{"697",VerPadrao("697")},; //LP Gestão de Contratos - Encerramento da Medição
						{"698",VerPadrao("698")},; //LP Gestão de Contratos - Encerramento da Medição/Automatico
						{"699",VerPadrao("699")},; //LP Gestão de Contratos - Encer. Medicao: Itens do Contrato
						{"69A",VerPadrao("69A")},; //LP Gestão de Contratos - Est. Medicao: Itens do Contrato
						{"69B",VerPadrao("69B")},; //LP Gestão de Contratos - Incl. Rateio Itens Contrato s/ Planilha
						{"69C",VerPadrao("69C")},; //LP Gestão de Contratos - Excl. Rateio Itens Contrato s/ Planilha
						{"69D",VerPadrao("69D")},; //LP Gestão de Contratos - Incl. Rateio Itens Contrato c/ Planilha
						{"69E",VerPadrao("69E")},;
						{"69F",VerPadrao("69F")},; //LP Gestão de Contratos - Excl. Rateio Itens Contrato c/ Planilha
						{"69H",VerPadrao("69H")},; //LP Gestão de Contratos - Encerramento da medição por item norma IFRS 15 (bens e serviços)
						{"69I",VerPadrao("69I")}; //LP Gestão de Contratos - Estorno da medição por item norma IFRS 15 (bens e serviços)
						}

Local cFilCtr  		:= ""
Local cCronog		:= ""
Local cParcel		:= ""
Local cNumTit  		:= ""
Local cAlias   		:= ""
Local cEspCtr  		:= ""
Local cAliasCNE		:= ""
Local cChave   		:= ""
Local cParcela 		:= "123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0"
Local cChave1  		:= ""
Local cChave2  		:= ""
Local cArqGCT		:= ""                   //Arquivo contabilizacao
Local cLancCont		:= ""						// Numero da LP
Local cBusca		:= ""
Local cSeqPCOLan	:= "" 	 	//Sequencia de Lancamento do PCO - 000355t
Local cLoteGCT 		:= LoteCont("COM")  	//Numero do Lote
Local cFilCND  		:= xFilial("CND")
Local cFilCXN		:= xFilial("CXN")
Local cFilCNE		:= xFilial("CNE")
Local cFilCN9  		:= ""
Local cFilCNA  		:= ""
Local cFilCNB  		:= ""
Local cFilCNF		:= ""
Local cFilCNS		:= ""
Local cFilCNZ  		:= xFilial("CNE")
Local cFilCNV		:= ""
Local cFilSED		:= xFilial("SED")
Local cFilSE4  		:= xFilial("SE4")
Local cNatureza		:= SuperGetMv("MV_CNNATMD",.F.,"") //Informa natureza financeira usada pelos títulos gerados pela medição de itens faturados através de título.
Local cChaveCXN		:= ""
Local cProxParce	:= ""
Local cOrigem		:= FUNNAME()

Local nMedLmt   	:= 0 //Limite de medicao do contrato
Local nTipo     	:= 1 //1 - Medicao;2 - Autorizacao de Fornecimento
Local nAcao     	:= 1 //1 - Encerra;2 - Gera Pedido;3 - Somente Encerra
Local nServico  	:= 1 //1 - Medicao;2 - Medicao de Servico;
Local nHead	  		:= 0 		//Retorno da funcao HeadProva
Local nDet  		:= 0     	//Retorno da funcao DetProva
Local nTaxa			:= 0
Local nI			:= 0
Local nParcelas 	:= SuperGetMv("MV_NUMPARC")
Local nTpDoc		:= CN120VerDoc(CND->CND_NUMMED) //Verifica quais documentos foram gerados Pedidos/Titulos
Local nTamContra	:= TamSx3("CNZ_CONTRA")[1]
Local nTamRevisa	:= TamSx3("CNZ_REVISA")[1]
Local nTamNummed	:= TamSX3("CNZ_NUMMED")[1]
Local nTamItem  	:= TamSx3("CNZ_ITCONT")[1]
Local nTamVrCamb	:= TamSX3("CNV_VRCAMB")[2]
Local nTamVlTot		:= TamSX3("CND_VLTOT")[2]
Local nValExced		:= 0
Local nLp69A		:= 0
Local nLp69H		:= 0

Local lRet			:= .T.
Local lMedEve   	:= .F.
Local lFscLmt   	:= .F.
Local lContab   	:= .F.
Local lFixo     	:= .T.
Local lSemiFix		:= .T.
Local lValor    	:= .T.
Local lFisico   	:= .F.
Local lRecorre 		:= .F.
Local lAtuSld  		:= .T. // PE CN121ATS
Local lSldFlex		:= .T. // PE CN121VDS
Local lDigita 		:= .F.    	 				//Mostra lancamento?
Local lAglutina		:= .F.    	 				//Aglutina
Local lMedComPlan	:= .F.
Local lRetVlPar		:= .T.
Local lCN121VMP		:= .T.
Local lCNPROVI 		:= GetNewPar( "MV_CNPROVI" ,  "S" ) == "S"
Local lCriaProv		:= AllTrim(SuperGetMV("MV_CNTPPP" ,.F.,"0")) $ "0/1"  // define quando os contratos recorrentes serão provisionados
Local lPeSld   		:= ExistBlock("CN121ESD")
Local lPeVdSld 		:= ExistBlock("CN121VDS")
Local lUsaFlag		:= SuperGetMV( "MV_CTBFLAG" , .T. /*lHelp*/, .F. /*cPadrao*/)
Local lCtbCNE		:= .F.
Local aFlagCTB 		:= {}

DEFAULT lAviso   	:= .T.
DEFAULT lAutoFor 	:= CND->CND_AUTFRN == '2'
DEFAULT lMedServ 	:= .F.

//Estabelece passos
ProcRegua(5)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Ponto de entrada para indicar se atualiza ou nao  ³
//³saldo da medicao                                  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If ExistBlock("CN121ATS")
	lAtuSld := ExecBlock("CN121ATS",.F.,.F.)
	If ValType(lAtuSld) <> "L"
		lAtuSld := .T.
	EndIf
EndIf

dbSelectArea("CND")
CND->(MsGoTo(nReg)) //-- Posiciona na medicao

cFilCtr := CND->CND_FILCTR

cFilCN9 := FWxFilial( "CN9", cFilCTR )
cFilCNA := FWxFilial( "CNA", cFilCTR )
cFilCNB := FWxFilial( "CNB", cFilCTR )
cFilCNF := FWxFilial( "CNF", cFilCTR )
cFilCNS := FWxFilial( "CNS", cFilCTR )
cFilCNV := FWxFilial( "CNV", cFilCTR )

If ( !lAutoFor .Or. !lMedServ ) .And. (!FWIsInCallStack('MATA094') .Or. !GetNewPar("MV_CNMDEAT",.F.) )
	lRet := CN240VldUsr(CND->CND_CONTRA,DEF_TRAENC_MED,.T.,,cFilCtr)
EndIf

cChave := CND->(CND_CONTRA+CND_REVISA+CND_NUMMED)

If LockByName("CN121"+cFilCND+cChave,.T.,!Empty(cFilCND),.T.)
	Pergunte("CNT120",.F.)	//carrega as variaveis

	If ValType("cOrigem") == "C"
		cLancCont:= IiF(ALLTRIM(cOrigem) == "CNTA121",cLancCont:= "697",cLancCont:= "698")
		If cOrigem == "CNTA260" .and. GetRemoteType() != -1 //.And. lShow
	   		Pergunte("CNT120",.T.)
	   	ElseIf cOrigem == "CNTA260" .and. GetRemoteType() == -1
	   		MV_PAR01 := 1
	   		MV_PAR02 := 2
	   		MV_PAR03 := 2
		EndIf
	Else
		cLancCont:= "697"
	EndIf

	If (lCtbOnLine := IIf(ValType(MV_PAR01)=="N",MV_PAR01 == 1,.F.)) //SE CONTABILIZA, atraves da escolha do usuario
		//Percorre os lancamentos contabeis do GCT, se algum deles existir, a contabilizacao podera ter continuidade
		For nI := 1 to len(aLPGCT)
			If aLPGCT[nI,2]
				lCtbOnline := .t.
				Exit
			Else
				lCtbOnline := .f.
			Endif
		Next nI

		If lCtbOnLine
			lDigita	:= IIF(VAlTYPE(MV_PAR02)=="N",MV_PAR02 == 1,.F.)
			lAglutina	:= IIF(VAlTYPE(MV_PAR03)=="N",MV_PAR03 == 1,.F.)

			nHead	:= HeadProva(cLoteGCT,cOrigem,Subs(cUsuario,7,6),@cArqGCT)
			If nHead <= 0
				If GetRemoteType() != -1
					HELP(" ",1,"SEM_LANC") //"SEM_LANC"
				EndIf
				lCtbOnLine := .F.
			EndIf
		EndIf
	Endif

	If lRet
		If !Empty(CND->CND_DTFIM) //-- Verifica se a medicao ja se encontra encerrada
			lRet := .F.
			Help( " ", 1, "CNTA120_03" )//"Medição já encerrada"
		ElseIf (GetNewPar("MV_CNMDALC","N") == "S" ) .AND. CND->CND_ALCAPR == "B"
			lRet := .F.
			Help( " ", 1, "CNTA120_09" )//"Medição bloqueada por alçada"
		ElseIf nTpDoc # 1 .And. (Empty(cNatureza) .Or. !SED->(MsSeek(cFilSED+cNatureza)))
		 	Help( " ", 1, "NOCNNATMD" )//"A natureza informada no parâmetro MV_CNNATMD não está cadastrada.
		 	lRet := .F.
		EndIf

		dbSelectArea("CN9")
		CN9->(dbSetOrder(1))
		If lRet .And. CN9->(MsSeek(cFilCN9+CND->(CND_CONTRA+CND_REVISA))) .And. (CN9->CN9_SITUAC==DEF_SFINA .OR. CN9->CN9_SITUAC==DEF_SCANC) //Contrato finalizado ou cancelado
			lRet := .F.
			Help( " ", 1, "CNTA120_02" )//"Apenas contratos em vigência podem ser medidos"
		EndIf

		//-- Verifica se os campos CND_DATA e CND_PARC estão criados conforme parametro MV_NUMPARC
		dbSelectArea("SE4")
		SE4->(dbSetOrder(1))
		If lRet .And. SE4->(MsSeek(cFilSE4+CND->CND_CONDPG)) .And. SE4->E4_TIPO=='9' .And. nParcelas > 4
				cChave1  := "CND_DATA"+Subs(cParcela,nParcelas,1)
				cChave2  := "CND_PARC"+Subs(cParcela,nParcelas,1)
				aAreaSX3 := SX3->(GetArea())

			dbSelectArea("SX3")
			SX3->(dbSetOrder(2))
			If lRet .And. (!SX3->(MsSeek(cChave1)) .OR. !SX3->(MsSeek(cChave2)))
				Help(" ",1,"TMKTIP905") //"A quantidade de parcelas nao esta compativel. Verificar junto ao administrador do sistema relacao entre parametro MV_NUMPARC e dicionario de dados"
				lRet:= .F.
			EndIf
			Restarea(aAreaSX3)
		EndIf

		If lRet .And. nAcao != 3
			dbSelectArea("CN9")
			CN9->(dbSetOrder(1))
			CN9->(MsSeek(cFilCN9+CND->(CND_CONTRA+CND_REVISA)))

			cChaveCXN := cFilCXN+CND->(CND_CONTRA+CND_REVISA+CND_NUMMED)
			DbSelectArea("CXN")
			CXN->(DbSetOrder(1))
			CXN->(MsSeek(cFilCXN+CND->(CND_CONTRA+CND_REVISA+CND_NUMMED)))

			Begin Transaction

			While !CXN->(EOF()) .And. cChaveCXN == CXN->(CXN_FILIAL+CXN_CONTRA+CXN_REVISA+CXN_NUMMED)
				If !CXN->CXN_CHECK
					CXN->(DbSkip())
					Loop
				EndIf

				lFixo	:= CN121RetSt( "FIXO"	   , 0, CXN->CXN_NUMPLA, CXN->CXN_CONTRA, .F. )
				lValor	:= CN121RetSt( "PREVFINANC", 0, CXN->CXN_NUMPLA, CXN->CXN_CONTRA, .F. )

				//Valor total dos itens excedentes da planilha
				nValExced := CN120VlExc(CND->CND_CONTRA,CND->CND_REVISA,CND->CND_NUMMED,CXN->CXN_NUMPLA)

				cCronog := Posicione("CNA",1,cFilCNA+CND->(CND_CONTRA+CND_REVISA)+CXN->CXN_NUMPLA,"CNA_CRONOG")

				//- Ponto de entrada permite ou não validar o saldo do contrato do tipo flexível com o valor da medição a ser encerrada
				If lPeVdSld
					lSldFlex := ExecBlock("CN121VDS",.F.,.F.)
				EndIf

		   		If !lFixo .And. lSldFlex
					If lValor .And. CNA->CNA_SALDO < xMoeda(CXN->CXN_VLLIQD - nValExced ,CND->CND_MOEDA,CN9->CN9_MOEDA,dDataBase,nTamVlTot)
						If nTipo==1 .And. nServico ==1
							Aviso("CNTA121",STR0096,{STR0156})//"Não foi possível encerrar a medição. O saldo do contrato nao equivale ao valor da medicao."
						Else
							Aviso("CNTA121",STR0097,{STR0156})//"Não foi possível gerar o pedido. O saldo do contrato nao equivale ao valor da medicao."
						EndIf
						lRet := .F.
					EndIf
				EndIf
				CXN->(DbSkip())
			EndDo

			//- Executa ponto de entrada após validação do valor previsto com realizado
			If ExistBlock("CN121VMP")
			   lCN121VMP := ExecBlock("CN121VMP",.F.,.F.,{lRet})
			  	If ValType(lCN121VMP) == "L"
					lRet := lCN121VMP
				EndIf
			EndIf

			IncProc(STR0098)//"Atualizando Medicao e Itens"
			PcoIniLan("000355")

			If lRet 

				oModel := FwLoadModel('CNTA121')
				oModel:SetOperation(MODEL_OPERATION_UPDATE)
				oModel:Activate()

				If !lAutoFor
					oModel:LoadValue("CNDMASTER","CND_SITUAC","E")
					oModel:LoadValue("CNDMASTER","CND_DTFIM",dDataBase)
				EndIf

				If (lRet := oModel:VldData())
					lRet := oModel:CommitData()
				EndIf
			EndIf

			If lRet
				cChaveCXN := cFilCXN+CND->CND_CONTRA+CND->CND_REVISA+CND->CND_NUMMED
				DbSelectArea("CXN")
				CXN->(DbSetOrder(1))
				CXN->(MsSeek(cFilCXN+CND->CND_CONTRA+CND->CND_REVISA+CND->CND_NUMMED))
				While cChaveCXN == CXN->(CXN_FILIAL+CXN_CONTRA+CXN_REVISA+CXN_NUMMED) .And. !(CXN->(Eof())) .And. lRet
					If !(CXN->CXN_CHECK)
						CXN->(DbSkip())
						Loop
					EndIf
					
					//-- Encerramento de planilhas zeradas
					If CXN->(Columnpos('CXN_ZERO')) > 0
						If CXN->CXN_ZERO == '1'
							CN121ZERO( CXN->CXN_CONTRA , CXN->CXN_REVISA , CXN->CXN_NUMMED , CXN->CXN_NUMPLA , cFilCtr , '1')
							CXN->(DbSkip())
							Loop
						EndIf
					EndIf
					
					cEspCtr	:= CN121RetSt("ESPECIE"		,0,CXN->CXN_NUMPLA,CXN->CXN_CONTRA,.T.,oModel)
					lMedEve	:= CN121RetSt("MEDEVE"		,0,CXN->CXN_NUMPLA,CXN->CXN_CONTRA,.T.,oModel)
					lContab	:= CN121RetSt("CONTABIL"	,0,CXN->CXN_NUMPLA,CXN->CXN_CONTRA,.T.,oModel)
					lFixo	:= CN121RetSt("FIXO"		,0,CXN->CXN_NUMPLA,CXN->CXN_CONTRA,.T.,oModel)
					lSemiFix:= CN121RetSt("SEMIFIXO"	,0,CXN->CXN_NUMPLA,CXN->CXN_CONTRA,.T.,oModel)
					lValor	:= CN121RetSt("PREVFINANC"	,0,CXN->CXN_NUMPLA,CXN->CXN_CONTRA,.T.,oModel)
					lFisico	:= CN121RetSt("FISICO"		,0,CXN->CXN_NUMPLA,CXN->CXN_CONTRA,.T.,oModel)
					nMedLmt	:= CN121RetSt("LMTMED"		,0,CXN->CXN_NUMPLA,CXN->CXN_CONTRA,.T.,oModel)
					lFscLmt	:= CN121RetSt("LMTFISICO"	,0,CXN->CXN_NUMPLA,CXN->CXN_CONTRA,.T.,oModel)
					lRecorre:= CN121RetSt("RECORRENTE"	,0,CXN->CXN_NUMPLA,CXN->CXN_CONTRA,.T.,oModel)
					
					cParcel := CXN->CXN_PARCEL 
					
					//Valor total dos itens excedentes da planilha
					nValExced := CN120VlExc(CND->CND_CONTRA,CND->CND_REVISA,CND->CND_NUMMED,CXN->CXN_NUMPLA)

					PcoDetLan("000355","03","CNTA120") //-- Ponto lancamento contabil e orcamentario para encerramento da medicao
					If lCtbOnLine
				    	nDet += DetProva(nHead,cLancCont,cOrigem,cLoteGCT,,,,,,,,,{"CND",CND->(RECNO())})
					EndIf

					DbSelectArea("CNE")
					CNE->(dbSetOrder(1))
					CNE->(MsSeek(cFilCNE+CND->(CND_CONTRA+CND_REVISA)+CXN->CXN_NUMPLA+CND->CND_NUMMED))
					cCronog := Posicione("CNA",1,cFilCNA+CND->(CND_CONTRA+CND_REVISA)+CXN->CXN_NUMPLA,"CNA_CRONOG")

					If lAtuSld .And. !lPeSld//-- Atualiza itens da planilha
						While CNE->(CNE_FILIAL+CNE_CONTRA+CNE_REVISA+CNE_NUMERO+CNE_NUMMED) == cFilCNE+CND->(CND_CONTRA+CND_REVISA)+CXN->CXN_NUMPLA+CND->CND_NUMMED
							lMedComPlan := .F.
							//-- Itens excedentes nao atualizam saldos
							If CNE->CNE_EXCEDE == '2'
								dbSelectArea("CNB")
								CNB->(dbSetOrder(1))
								If CNB->(MsSeek(cFilCNB+CNE->(CNE_CONTRA+CNE_REVISA+CNE_NUMERO+CNE_ITEM)))
									If !lRecorre	//-- se não recorrente
										RecLock("CNB",.F.)
											If nServico == 1
												CNB->CNB_QTDMED += CNE->CNE_QUANT
											CNB->CNB_SLDMED -= Iif(lSemiFix,0,CNE->CNE_QUANT) //- Somente atualiza se não semifixo
											Else
												CNB->CNB_QTDMED += CNE->CNE_QTDORI
											CNB->CNB_SLDMED -= Iif(lSemiFix,0,CNE->CNE_QTDORI)//- Somente atualiza se não semifixo
											EndIf
										MsUnlock()
									Else //-- Se for recorrente
										//- Tratamento das planilhas de contratos recorrentes
										If CNE->CNE_QUANT > 0
											// verifica se é pro-rata
											If CNB->CNB_PARPRO > 0 .And. Empty(CNB->CNB_PRIMED)
												RecLock("CNB",.F.)
												CNB->CNB_PRIMED := CND->CND_DTINIC
												MsUnlock()
											Endif
										Endif
									Endif
									lMedComPlan := .T. //--  CAPTURO A VARIAVEL FLAG DE ITENS COM PLANILHA
								EndIf
								If lFisico
									dbSelectArea("CNS")
									CNS->(dbSetOrder(1))
									If CNS->(dbSeek(cFilCNS+CND->(CND_CONTRA+CND_REVISA)+cCronog+cParcel+CNB->CNB_ITEM))
										RecLock("CNS",.F.)
											CNS->CNS_RLZQTD += CNE->CNE_QUANT
											CNS->CNS_SLDQTD -= CNE->CNE_QUANT
										MsUnlock()
									EndIf
								EndIf
							EndIf

							PcoDetLan("000355","04","CNTA120")
							If lCtbOnLine //-- CONTABILIZA ENCERRAMENTO DA MEDICAO - ITENS DO CONTRATO

								nLp69A	:= aScan(aLPGCT,{|x| x[1]=="69A"})
								nLp69H := aScan(aLPGCT,{|x| x[1]=="69H"})

								If lUsaFlag
									aAdd( aFlagCTB, {"CNE_DTLANC", dDataBase, "CNE", CNE->( Recno() ), 0, 0, 0} )
								EndIf

								If aLPGCT[nLp69H,2] .And. cEspCtr == '2' .And. CN9->CN9_DTINIC >= CTOD("01/01/2018") // - Ponto de lançamento padrão IFRS15
									nDet += DetProva(nHead,'69H',cOrigem,cLoteGCT,,,,,,,,@aFlagCTB,{"CNE",CNE->(Recno())})
									lCtbCNE	:= .T.
								ElseIf aLPGCT[nLp69A,2]
									nDet += DetProva(nHead,"69A",cOrigem,cLoteGCT,,,,,,,,@aFlagCTB,{"CNE",CNE->(Recno())})
									lCtbCNE	:= .T.
								EndIf

								If !lUsaFlag .And. lCtbCNE
									If CNE->(Columnpos('CNE_DTLANC')) > 0
										dbSelectArea("CNE")
										RecLock("CNE",.F.)
										CNE->CNE_DTLANC := dDataBase
										MsUnlock()
									EndIf
								EndIf

							EndIf

							If lMedComPlan
								cLancCont 	:= "69E"
								cSeqPCOLanc	:= "06"
							Else
								cLancCont := "69C"
								cSeqPCOLanc	:= "05"
							Endif

	                	  	cBusca :=	cFilCNZ +;
							Padr(CNE->CNE_CONTRA	,nTamContra )+;
							Padr(CNE->CNE_REVISA	,nTamRevisa )+;
							Padr(CNE->CNE_NUMMED	,nTamNummed )+;
							Padr(CNE->CNE_ITEM	,nTamItem )

		                   	CNZ->(dbSetOrder(2)) //CNZ_FILIAL+CNZ_CONTRA+CNZ_REVISA+CNZ_NUMMED+CNZ_ITCONT+CNZ_ITEM
	
		                   	If CNZ->(MsSeek( cBusca ))
	                    		While CNZ->(!Eof()) .and. cBusca == CNZ->CNZ_FILIAL +;
												Padr(CNZ->CNZ_CONTRA	,nTamContra) +;
												Padr(CNZ->CNZ_REVISA	,nTamRevisa) +;
												Padr(CNZ->CNZ_NUMMED	,nTamNummed) +;
												Padr(CNZ->CNZ_ITCONT	,nTamItem)

					  		     	If !Empty(CNZ->CNZ_CC)
								  		 PcoDetLan("000355",cSeqPCOLan,"CNTA120")
										 //-- Contabiliza os rateios do item do contrato com planilha.
										 //-- Se ha planilha, entao nao podera contabilizar o rateio sem planilha, abaixo (controlar com variavel flag)
										 //-- efetua a contabilizacao dos rateios do item do contrato sem planilha,
										 If lCtbOnLine
											  nDet += DetProva(nHead,cLancCont,"CNTA120",cLoteGCT,,,,,,,,,{"CNZ",CNZ->(Recno())})
										 EndIf
									EndIf
									CNZ->(DbSkip())
								EndDo
							EndIf
							dbSelectArea("CNE")
							CNE->(dbSkip())
						EndDo
					EndIf
					IncProc( "Atualizando Saldos" )//"Atualizando Saldos"
					dbSelectArea("CNA")
					CNA->(dbSetOrder(1))
					If CNA->(MsSeek(xFilial("CNA",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA+CXN->CXN_NUMPLA))
						If lAtuSld .And. !lPeSld .And. !lRecorre //-- Atualiza saldo da planilha se nao recorrente
							RecLock("CNA",.F.)
								If lFixo .Or. lSemiFix .Or. lValor
									CNA->CNA_SALDO -= xMoeda(CXN->CXN_VLLIQD - nValExced,CND->CND_MOEDA,CN9->CN9_MOEDA,dDataBase,nTamVlTot,,nTaxa)
								EndIf
							MsUnlock()
						EndIf
						If lRecorre
							//-- atualiza campos de controle dos contratos recorrentes no encerramento
							If CNA->CNA_MEDEFE > 0
								RecLock("CND",.F.)
								CND->CND_RECMED := CNA->CNA_RECMED
								CND->CND_ULTMED := CNA->CNA_ULTMED
								MsUnlock()
							Endif

							RecLock("CNA",.F.)
							CNA->CNA_MEDEFE := CNA->CNA_MEDEFE + 1
							cProxParce	:= CNA->CNA_PROPAR

							If TamSx3("CNA_PROPAR")[1] = 1 .And. cProxParce == "Z"
								cProxParce := "a"
							Else
								cProxParce 	:= Soma1(cProxParce)
							Endif
							CNA->CNA_PROPAR := cProxParce
							CNA->CNA_ULTMED := CNA->CNA_PROMED
							CNA->CNA_RECMED := CND->CND_NUMMED
							dDataProMed 	:= CN300RetMed(CNA->CNA_PERIOD,CNA->CNA_PROMED,CNA->CNA_DIAMES,CNA->CNA_DIASEM,CNA->CNA_PERREC)
							CNA->CNA_PROMED := dDataProMed
							MsUnlock()
						Endif

					EndIf
					DbSelectArea("CN9")
					CN9->(dbSetorder(1))
					If CN9->(MsSeek(cFilCN9+CND->CND_CONTRA+CND->CND_REVISA))
						If lAtuSld .And. !lPeSld .And. !lRecorre //-- Atualiza saldo do contrato se nao recorrente
							RecLock("CN9",.F.)
							If lFixo .Or. lSemiFix .Or. lValor
								CN9->CN9_SALDO -= xMoeda(CXN->CXN_VLLIQD - nValExced,CND->CND_MOEDA,CN9->CN9_MOEDA,dDataBase,nTamVlTot,,nTaxa)
							Else
								CN9->CN9_VLATU += xMoeda(CXN->CXN_VLLIQD - nValExced,CND->CND_MOEDA,CN9->CN9_MOEDA,dDataBase,nTamVlTot,,nTaxa)//Atualiza valor do contrato
								If Empty(CN9->CN9_REVISA)//Se contrato original atualiza valor inicial
									CN9->CN9_VLINI += xMoeda(CXN->CXN_VLLIQD - nValExced,CND->CND_MOEDA,CN9->CN9_MOEDA,dDataBase,nTamVlTot,,nTaxa)
								EndIf
							EndIf
							MsUnlock()
						EndIf
					EndIf

					If !lMedEve .And. !lRecorre //-- Atualiza saldo do cronograma quando nao houver medicao eventual e nem recorrente
						dbSelectArea("CNF")
						If !Empty(CXN->CXN_PARCEL)
							dbSetorder(3)
							MsSeek(cFilCNF+CND->CND_CONTRA+CND->CND_REVISA+cCronog+CXN->CXN_PARCEL)
						Else
							dbSetorder(2)
							MsSeek(cFilCNF+CND->CND_CONTRA+CND->CND_REVISA+cCronog+CND->CND_COMPET)
						EndIf

						If Found()
							If lAtuSld .And. !lPeSld
								RecLock("CNF")
									CNF->CNF_VLREAL += xMoeda(CXN->CXN_VLLIQD - nValExced,CND->CND_MOEDA,CN9->CN9_MOEDA,dDataBase,nTamVlTot,,nTaxa)
									CNF->CNF_SALDO  -= xMoeda(CXN->CXN_VLLIQD - nValExced,CND->CND_MOEDA,CN9->CN9_MOEDA,dDataBase,nTamVlTot,,nTaxa)
									CNF->CNF_DTREAL := dDataBase
								MsUnlock()

								If lCNPROVI
									IncProc( STR0099 )//"Processando títulos provisórios"
									CN100ETit(CND->CND_CONTRA,CND->CND_REVISA,cCronog,CNF->CNF_PARCEL,cFilCtr)
									If CNF->CNF_SALDO > 0
										CN100CTit(CND->CND_CONTRA,CND->CND_REVISA,cCronog,CNF->CNF_PARCEL,CNF->CNF_SALDO)
									EndIf
								EndIf
							EndIf
						EndIf

						If lContab
							dbSelectArea("CNV")
							dbSetOrder(2)

							If MsSeek(cFilCNV+CND->CND_CONTRA+CND->CND_REVISA+CXN->CXN_NUMMED)
								nVlOr := xMoeda(CXN->CXN_VLLIQD - nValExced,CN9->CN9_MOEDA,1,dDataBase,nTamVrCamb,CNV->CNV_TXMOED)
								nVlAtu:= xMoeda(CXN->CXN_VLLIQD - nValExced,CN9->CN9_MOEDA,1,dDataBase,nTamVrCamb)
								RecLock("CNV",.F.)
									CNV->CNV_VRCAMB += nVlAtu-nVlOr
								MsUnlock()
							EndIf
						EndIf

					ElseIf lRecorre
						//-- Exclui titulo provisorio da parcela atual
						CN100ETit(CND->CND_CONTRA,CND->CND_REVISA,"RECORRENTE",CXN->CXN_PARCEL,cFilCtr,CXN->CXN_NUMPLA)

						// cria titulo provisorio da parcela recorrente se o parâmetro MV_GCTTPPP é 0 ou 1
						If lCriaProv
							CN100RecTi(CND->CND_CONTRA,CND->CND_REVISA,CXN->CXN_PARCEL,CXN->CXN_NUMPLA)
						Endif
					EndIf
					CXN->(DbSkip())
				EndDo

			EndIf

			If lPeSld//Chama ponto de entrada para atualizacao do saldo
				ExecBlock("CN121ESD",.F.,.F.,{lMedEve,lFisico,cCronog,lFixo,lValor})
			EndIf

			If !lRet
				DisarmTransaction()
			EndIf

			End Transaction

			PcoFinLan("000355")

		EndIf
	EndIf
Else
	// Nao permite processamento concorrente
	Aviso(STR0159,OemtoAnsi(STR0100),{STR0156},2) // ##"Concorrência"##"Esta Medição está em uso por outra estação."
EndIf

If lCtbOnLine
	RodaProva(nHead,nDet)
	If nDet > 0
		cA100Incl(cArqGCT,nHead,1,cLoteGCT,lDigita,lAglutina,,,,@aFlagCTB)
		aFlagCTB := {}
	Endif
EndIf

UnLockByName("CN121"+cFilCND+cChave,.T.,!Empty(cFilCND),.T.)

Return lRet

//------------------------------------------------------------------
/*/{Protheus.doc} Cn121RetSt
Retorna a propriedade do contrato chamado pelo gatilho dos campos da tabela CNE
quando chamada pela CNTA260
@author rogerio.melonio
@since 02/09/2015
/*/
//-------------------------------------------------------------------
Function Cn121RetSt( cProp, nModo, cPlan, cContra, lModel, oModel )
Local xRet := .F.
Local oModelCND := Nil
Local oModelCXN := Nil
Local lnotTEC930 := IIF( FindFunction("TEC930Test") .AND. TEC930Test() , .F. , !lMedicao)
Local cFilCtr := ""

Default cContra := ""
Default cPlan := ""
Default nModo := 0
Default lModel := .T.
Default oModel := Nil

If IsInCallStack("CNTA120") .And. lnotTEC930
	xRet := CN300RetSt(cProp,nModo)
Else
	If lModel
		If oModel == Nil
			oModel := FwModelActive()
		EndIf
		
		oModelCND := oModel:GetModel("CNDMASTER")				
		
		cFilCtr := oModelCND:GetValue("CND_FILCTR")
		
		If Empty(cContra)
			cContra := oModelCND:GetValue("CND_CONTRA")
		EndIF
		
		If Empty(cPlan)
			oModelCXN := oModel:GetModel("CXNDETAIL")
			cPlan := oModelCXN:GetValue("CXN_NUMPLA")
		EndIf
				
	Else		
		If Empty(cContra)
			cContra := CND->CND_CONTRA
		EndIf	
		cFilCtr := CND->CND_FILCTR
	EndIf
	
	xRet := CN300RetSt( cProp, nModo, cPlan, cContra, cFilCtr )
EndIf

Return xRet

//------------------------------------------------------------------
/*/{Protheus.doc} A121Servico
Retorna flag indicando se o contrato é de serviço
@author rogerio.melonio
@since 02/09/2015
/*/
//-------------------------------------------------------------------
Function A121Servico(nModo,cPlan,cContra)
Default nModo 	:= 0
Default cPlan 	:= ""
Default cContra := ""
Return CN121RetSt('SERVIÇO',nModo,cPlan,cContra)

//------------------------------------------------------------------
/*/{Protheus.doc} CN121Agrup
Carregamento de agrupadores por planilha

@author guilherme.pimentel
@since 02/09/2015
/*/
//-------------------------------------------------------------------
Function CN121Agrup(oModel,oModelCXM)
Local nCount	:= 0
Local nIncLine	:= 0
Local nInd		:= 0
Local aSaveLines:= FWSaveRows()
Local cContrat	:= oModel:GetModel( 'CXNDETAIL' ):GetValue( 'CXN_CONTRA' )
Local cRevisa	:= oModel:GetModel( 'CXNDETAIL' ):GetValue( 'CXN_REVISA' )
Local cNumero	:= oModel:GetModel( 'CXNDETAIL' ):GetValue( 'CXN_NUMPLA' )
Local lRet		:= .T.

Default oModelCXM := oModel:GetModel('CXMDETAIL')

If CN121RetSt('SEMIAGRUP',0,cNumero,cContrat)
	dbSelectArea('CXM')
	CXM->(dbSetOrder(1)) //CXM_FILIAL+CXM_CONTRA+CXM_REVISA+CXM_NUMERO+CXM_ITEMID

	CNTA300DlMd(oModelCXM,'CXM_ITEMID')

	If !CXM->(dbSeek(xFilial('CXM')+cContrat+cRevisa+cNumero ) )
		lRet := .F.
	Else
		While CXM->(!Eof()) .And. CXM->CXM_FILIAL == xFilial('CXM') .And. CXM->CXM_CONTRA == cContrat .And. CXM->CXM_REVISA == cRevisa .And. CXM->CXM_NUMERO == cNumero
			nCount ++
			Do Case
				Case ( nCount == 1 ) .And. ( nCount == oModelCXM:nLine )
					nIncLine := nCount
				Case ( nCount > 1 )
					nIncLine := oModelCXM:AddLine()
					If nCount # nIncLine
						//Help de Erro na Criacao da Linha
						lRet := .F.
						Exit
					EndIf
			EndCase

			If lRet
				oModelCXM:GoLine( nIncLine )
				For nInd := 1 To CXM->( FCount() )
					oModelCXM:LoadValue( CXM->( FieldName( nInd ) ), CXM->( FieldGet( nInd ) )  )
				Next nInd
			EndIf
			CXM->( dbSkip() )
	 	EndDo
	EndIf
EndIf

FwRestRows( aSaveLines )
Return lRet

//------------------------------------------------------------------
/*/{Protheus.doc} CN121VlAgr
Validação do tipo do agrupador

@author guilherme.pimentel
@since 02/09/2015
/*/
//-------------------------------------------------------------------
Function CN121VlAgr(cProd,nQAtu,nQAnt)
Local lEncontrou:= .F.
Local lSaldo	:= .T.
Local cTipo		:= ''
Local cGrupo	:= ''
Local nX		:= 0
Local oModel	:= FWModelActive()
Local oModelCXN	:= oModel:GetModel('CXNDETAIL')
Local oModelCXM := oModel:GetModel('CXMDETAIL')
Local oModelCNE := oModel:GetModel('CNEDETAIL')
Local cContra	:= oModelCXN:GetValue("CXN_CONTRA")
Local cRevisa	:= oModelCXN:GetValue("CXN_REVISA")
Local cNumPla	:= oModelCXN:GetValue("CXN_NUMPLA")
Local cItem		:= oModelCNE:GetValue("CNE_ITEMGR")
Local lInclui	:= oModel:GetOperation() == MODEL_OPERATION_INSERT
Local aArea		:= Nil

Default cProd := ''
Default nQAtu := 0
Default nQAnt := 0

If SB1->(DbSeek(xFilial("SB1")+cProd))
	cTipo	:= SB1->B1_TIPO
	cGrupo	:= SB1->B1_GRUPO

	//Se for chamado pela quantidade ou o item estiver preenchido posiciona
	If !IsInCallStack("CN120VldProd") .Or. !Empty(oModelCNE:GetValue('CNE_ITEMGR'))
		//Posiciona na CXM correspondente caso haja
		If !Empty(oModelCNE:GetValue('CNE_ITEMGR'))
			If !lInclui
			For nX := 1 To oModelCXM:Length()
				oModelCXM:Goline(nX)
				If oModelCNE:GetValue('CNE_ITEMGR') == oModelCXM:GetValue('CXM_ITEMID')
					lEncontrou := .T.
					Exit
				EndIf
			Next nX
			Else
				aArea := GetArea()
				CXM->(dbSetOrder(1))
				If CXM->(MsSeek(xFilial("CXM")+cContra+cRevisa+cNumPla+cItem))
					lEncontrou := .T.
				EndIf
				RestArea(aArea)
			EndIf
		EndIf
	EndIf

	// Se for chamado pela quantidade verifica novo valor
	If !IsInCallStack("CN120VldProd")
		If !lInclui
		//Caso seja quantidade a CXM já estará posicionada, somente faremos a comparação de valor
		If oModelCXM:GetValue('CXM_VLMAX') > 0
			If oModelCXM:GetValue('CXM_VLMAX') >= (oModelCXM:GetValue('CXM_VLMED') + (nQAtu-nQAnt))
				oModelCXM:LoadValue('CXM_VLMED',oModelCXM:GetValue('CXM_VLMED') + (nQAtu-nQAnt))
				lEncontrou := .T.
			Else
				lSaldo := .F.
			EndIf
		Else
			//Por total
			oModelCXM:LoadValue('CXM_VLMED',oModelCXM:GetValue('CXM_VLMED') + (nQAtu-nQAnt))
		EndIf
		Else
			aArea := GetArea()
			CXM->(dbSetOrder(1))
			If CXM->(MsSeek(xFilial("CXM")+cContra+cRevisa+cNumPla))
				If CXM->CXM_VLMAX > 0
					If CXM->CXM_VLMAX >= CXM->CXM_VLMED+ (nQAtu-nQAnt)
						oModelCXM:LoadValue('CXM_VLMED',oModelCXM:GetValue('CXM_VLMED') + (nQAtu-nQAnt))
						lEncontrou := .T.
					Else
						lSaldo := .F.
	EndIf
				EndIf
			EndIf
			RestArea(aArea)
		EndIf
	EndIf

	//Verifica se é alteração de produto ou se o saldo não é suficiente e se encaixa em outra categoria
	If IsInCallStack("CN120VldProd") .Or. !lSaldo .Or. IsInCallStack('CN121VlTot')
		//Se ja tiver relacionado com alguem guarda status atual da CXM
		If lEncontrou
			oModelCXM:LoadValue('CXM_VLMED',oModelCXM:GetValue('CXM_VLMED')-nQAnt)
			lEncontrou := .F.
		EndIf

		//Verifica se encontra CXM compativel
		For nX := 1 To oModelCXM:Length()
			oModelCXM:GoLine(nX)
			// Verifica se encontra
			If (!Empty(oModelCXM:GetValue('CXM_AGRTIP')) .And. oModelCXM:GetValue('CXM_AGRTIP') == cTipo) .Or. ;
				(!Empty(oModelCXM:GetValue('CXM_AGRGRP')) .And. oModelCXM:GetValue('CXM_AGRGRP') == cGrupo) //.Or.
				lEncontrou := .T.
			Else
				aArea := GetArea()
				dbSelectArea("CXM")
				CXM->(dbSetOrder(1))
				If CXM->(MsSeek(xFilial("CXM")+cContra+cRevisa+cNumPla))
					While !lEncontrou .And. CXM->(CXM_FILIAL+CXM_CONTRA+CXM_REVISA+CXM_NUMERO) == xFilial("CXM")+cContra+cRevisa+cNumPla
						If 	(!Empty(CXM->CXM_AGRTIP) .And. CXM->CXM_AGRTIP == cTipo) .OR. (!Empty(CXM->CXM_AGRGRP) .And. CXM->CXM_AGRGRP == cGrupo)
							lEncontrou := .T.
						EndIf
						CXM->(dbSkip())
					End
				Else
				lEncontrou := .F.
				EndIf
				RestArea(aArea)
			EndIf

			//Se encontrar alguem compativel verifica o saldo
			If lEncontrou
				//Verificação de saldo por item
				If oModelCXM:GetValue('CXM_VLMAX') > 0
					If (nQAtu + oModelCXM:GetValue('CXM_VLMED')) <= oModelCXM:GetValue('CXM_VLMAX')
						lSaldo := .T.
						oModelCXM:LoadValue('CXM_VLMED',oModelCXM:GetValue('CXM_VLMED')+nQAtu)
						oModelCNE:LoadValue('CNE_ITEMGR',oModelCXM:GetValue('CXM_ITEMID'))
						Exit
					EndIf
				Else
					//Por total
					oModelCXM:LoadValue('CXM_VLMED',oModelCXM:GetValue('CXM_VLMED')+nQAtu)
					oModelCNE:LoadValue('CNE_ITEMGR',oModelCXM:GetValue('CXM_ITEMID'))
					Exit
				EndIf
			EndIf

		Next nX

		//Valida Categoria
		If !lEncontrou
			lEncontrou := CN300getACV(cProd,nQAtu)
		EndIf

		//Se não encontrar ninguem compativel exibe mensagem
		If !lEncontrou
			Help(" ",1,"CN121VlAgr",,STR0101,1,0)//"Não foram encontrados agrupadores de estoque nas mesmas caracteristicas ou saldo do produto selecionado."
			// E se estivesse com alguem anteriormente reposiciona e devolve o valor
			If!Empty(oModelCNE:GetValue('CNE_ITEMGR'))
				For nX := 1 To oModelCXM:Length()
					oModelCXM:Goline(nX)
					If oModelCNE:GetValue('CNE_ITEMGR') == oModelCXM:GetValue('CXM_ITEMID')
						oModelCXM:LoadValue('CXM_VLMED',oModelCXM:GetValue('CXM_VLMED')+nQAnt)
						Exit
					EndIf
				Next nX
			EndIf
		EndIf
	EndIf
EndIf

Return (lEncontrou)

//------------------------------------------------------------------
/*/{Protheus.doc} CN300getACV
Carrega todos os níveis da tabela ACV

@author guilherme.pimentel
@since 02/09/2015
/*/
//-------------------------------------------------------------------
Function CN300getACV(cProd,nQAtu)
Local aCateg	:= {}
Local aCatCXM	:= {}
Local aRet		:= {}
Local nX		:= 0
Local nY		:= 0
Local nPos		:= 0
Local cCategoria:= ''
Local oModel	:= FWModelActive()
Local oModelCXM := oModel:GetModel('CXMDETAIL')
Local oModelCNE := oModel:GetModel('CNEDETAIL')
Local lSaldo	:= .F.

DbSelectArea("ACV")
DbSetOrder(6)//ACV_FILIAL+ACV_SEQPRD

ACV->(DbGoBottom())
While !ACV->(Bof())
	If ACV->ACV_CODPRO == cProd
		cCategoria := ACV->ACV_CATEGO
		Exit
	Else
		ACV->(DbSkip(-1))
	EndIf
End

DbSelectArea("ACV")
DbSetOrder(1)//ACV_FILIAL+ACV_CATEGO+ACV_GRUPO+ACV_CODPRO

//Verifica a arvore de categorias e ordena pela mais recomendada
If ACV->(DbSeek(xFilial("ACV")+cCategoria))
	aAdd(aCateg,cCategoria)

	dbSelectArea("ACU")
	dbSetorder(1)
	If ACU->(DbSeek(xFilial("ACU")+cCategoria))
		cCategoria := ACU->ACU_CODPAI
		aAdd(aCateg,cCategoria)
		While !EOF()
			ACU->(DbSeek(xFilial("ACU")+ACU->ACU_CODPAI))
			If Empty(ACU->ACU_CODPAI)
				cCategoria := ACU->ACU_COD
				aAdd(aCateg,cCategoria)
				Exit
			Endif
		Enddo
	Endif
EndIf

// Array com as posições esperadas
For nX := 1 To oModelCXM:Length()
	oModelCXM:GoLine(nX)
	// Verifica se encontra
	If !Empty(oModelCXM:GetValue('CXM_AGRCAT'))
		aAdd(aCatCXM,oModelCXM:GetValue('CXM_AGRCAT'))
	EndIf
next nX


//Adiciona em um array final todas as categorias que tme no original e suas posições
For nX := 1 to len(aCatCXM)
	If (nPos := AScan(aCateg,aCatCXM[nX])) > 0
		aAdd(aRet,{nPos,aCatCXM[nX]})
	EndIf
Next nX

aSort(aRet, , ,{|x,y|x[1] < y[1]})

//Verificação de saldo
//Posiciona no no CMX de acordo com o array
For nY := 1 to Len(aRet)
	If lSaldo
		Exit
	EndIf
	For nX := 1 To oModelCXM:Length()
		oModelCXM:GoLine(nX)
		// Verifica se encontra
		If oModelCXM:GetValue('CXM_AGRCAT') == aRet[nY,2]
			//Valida o Saldo
			If oModelCXM:GetValue('CXM_VLMAX') > 0
				If (nQAtu + oModelCXM:GetValue('CXM_VLMED')) <= oModelCXM:GetValue('CXM_VLMAX')
					lSaldo := .T.
					oModelCXM:LoadValue('CXM_VLMED',oModelCXM:GetValue('CXM_VLMED')+nQAtu)
					oModelCNE:LoadValue('CNE_ITEMGR',oModelCXM:GetValue('CXM_ITEMID'))
					Exit
				EndIf
			Else
				//Por total
				lSaldo := .T.
				oModelCXM:LoadValue('CXM_VLMED',oModelCXM:GetValue('CXM_VLMED')+nQAtu)
				oModelCNE:LoadValue('CNE_ITEMGR',oModelCXM:GetValue('CXM_ITEMID'))
				Exit
			EndIf
		EndIf
	Next nX
Next nY

Return lSaldo

//------------------------------------------------------------------
/*/{Protheus.doc} CN121Estorn
Estorna Medição
@author Leonardo Quintania
@since 03/09/2015
/*/
//-------------------------------------------------------------------
Function CN121Estorn(lAuto,lAprRev,cMedErro)
Local aArea     := GetArea()
Local aAreaCND  := CND->(GetArea())

Local lAutForn	:= CND->CND_AUTFRN == "2"
Local lContinua	:= .T.

Local cChave	:= ""
Local cFilCtr 	:= CND->CND_FILCTR

Local nReg		:= CND->(Recno())

Local dDataBloq	:= GetNewPar("MV_ATFBLQM",CTOD("")) //Data de Bloqueio da Movimentação - MV_ATFBLQM

Default lAuto	:= .F.
Default lAprRev := .F.
Default cMedErro:= ""

If Cn121OriMd('CNTA120')
 	Aviso(STR0079,STR0127+CRLF+STR0128+CRLF+CRLF+STR0125+CRLF+STR0126,{STR0156},2) //- Opção indisponivel para medições realizadas com a rotina de medições padrão.

ElseIf !(Alltrim(CND->CND_SITUAC) $ "E|FE|SE")
	Help(" ",1,"CN121NoEnc",,STR0102,1,0) //"Operação não permitida. Somente é possível estornar Medições que estejam encerradas"

Else
	If !lAuto
		If lAutForn
			lContinua := (Aviso("CNTA121",OemtoAnsi(STR0103),{STR0157,STR0158}) == 1)//"Confirma estorno da autorização de fornecimento?"
		Else
			lContinua := (Aviso("CNTA121",OemtoAnsi(STR0104),{STR0157,STR0158}) == 1)//"Confirma estorno da medição?"##"Sim"##"Não"
		EndIf
	Endif
	//Verifica se existe bloqueio contábil
	If lContinua .And. (lContinua := CtbValiDt(Nil, dDataBase,/*.T.*/ ,Nil ,Nil ,{"GCT001"}/*,"Data de apuração bloqueada pelo calendário contábil."*/) )
		If !Empty(dDataBloq) .AND. ( dDataBase <= dDataBloq)
			Help(" ",1,"ATFCTBBLQ") //P: Processo bloqueado pelo Calendário Contábil ou parâmetro de bloqueio nesta data ou período. S: Caso possível altere a data de referência do processo, verifique o parâmetro ou contate o responsável pelo Módulo Contábil.)
			lContinua := .F.
		EndIf
	EndIf

	//- Verifica se é contrato recorrente e se é a última medição efetuada
	CXN->(dbSetOrder(1))
	CNA->(dbSetOrder(1))
	CXN->(dbSeek(xFilial("CXN")+CND->(CND_CONTRA+CND_REVISA+CND_NUMMED)))
	While !CXN->(Eof()) .And. CXN->(CXN_FILIAL+CXN_CONTRA+CXN_REVISA+CXN_NUMMED) == xFilial("CXN")+CND->(CND_CONTRA+CND_REVISA+CND_NUMMED)
		If CXN->CXN_CHECK
			If CNA->(MsSeek(xFilial("CNA")+CND->(CND_CONTRA+CND_REVISA)+CXN->CXN_NUMPLA))
				//- Se a medição a ser excluída não é a última, não permite exclusão
				If !Empty(CNA->CNA_PERIOD) .And. !Empty(CNA->CNA_RECMED) .And. ( CNA->CNA_RECMED <> CND->CND_NUMMED  )
					lContinua := .F.
					Help(" ",1,"CN121BLQREC") // "Exclusões de medições de contratos recorrentes serão permitidas na ordem inversa da que foram incluídas, a partir da última medição.")
					Exit
				Endif
			Endif
		Endif
		CXN->(dbSkip())
	EndDo

	cChave := CND->(CND_CONTRA+CND_REVISA+CND_NUMMED)
	If LockByName("CN120"+xFilial("CND")+cChave,.T.,!Empty(xFilial("CND")),.T.)
		If lContinua .And. !lAuto
			//Chama rotina de estorno por meio de processo
			If lAutForn
				Processa( {|| lContinua := Cn121AutEst(nReg,!lAuto) } )
			Else
				Processa( {|| lContinua := CN121MedEst(nReg,!lAuto) } )
			EndIf
		ElseIf lContinua .And. lAuto
			If lAutForn
				lContinua := Cn121AutEst(nReg,!lAuto)
			Else
				lContinua := CN121MedEst(nReg,!lAuto,,,lAprRev,@cMedErro)
			EndIf
		EndIf
	Else
		// Nao permite processamento concorrente
		lContinua := .F.
		Aviso(STR0159,OemtoAnsi(STR0100),{STR0156},2) // ##"Concorrência"##"Esta Medição está em uso por outra estação."
	EndIf

	UnLockByName("CN120"+xFilial("CND")+cChave,.T.,!Empty(xFilial("CND")),.T.)
EndIf

CN121Limpa() //--Desativa o model do CNTA121 apó finalização do processo.

RestArea(aAreaCND)
RestArea(aArea)

Return lContinua

//------------------------------------------------------------------
/*/{Protheus.doc} CN121MedEst
Estorna medicao, valida pedido de compra, medicoes zeradas
e saldo do contrato, planilhas e cronogramas
@author Leonardo Quintania
@since 03/09/2015
/*/
//-------------------------------------------------------------------
Static Function CN121MedEst(nReg,lAviso,lAutoFor,lMedServ,lAprRev,cMedErro)
Local cFilCtr		:= CND->CND_FILCTR
Local cFilCND  		:= xFilial("CND")
Local cFilCNS 		:= xFilial("CNS",cFilCTR)
Local cRetPrf		:= PadR(SuperGetMV("MV_CNPREMD",.F.,"MED"),TAMSX3("E2_PREFIXO")[1])
Local cTpTit		:= PadR(SuperGetMV("MV_CNTPTMD",.F.,"BOL"),TAMSX3("E2_TIPO")[1])
Local cLoteGCT  	:= LoteCont("COM")  //-- Numero do Lote
Local cQuery   		:= ""
Local cCronog  		:= ""
Local cEspCtr  		:= ""
Local cParcel		:= ""
Local cAliasCNT		:= ""
Local cAliasQry		:= ""
Local cNumTit		:= ""
Local cArqGCT 		:= ""
Local cLancCont		:= ""
Local cBusca		:= ""
Local cChaveCXN		:= ""
Local cChaveCNE		:= ""
Local cChaveCNZ		:= ""
Local cChaveCXJ		:= ""
Local cOrigem		:= FunName()
Local cKeyCNE		:= ""
Local cKeyTmp		:= ""
Local nTpDoc		:= CN120VerDoc(CND->CND_NUMMED) //Verifica quais documentos foram gerados Pedidos/Titulos
Local nTamVlTot		:= TamSX3("CND_VLTOT")[2]
Local nTipo    		:= 1 	//-- 1 - Medicao;2 - Autorizacao de Fornecimento
Local nServico 		:= 1 	//-- 1 - Medicao;2 - Medicao de Servico
Local nDet 			:= 0    //-- Retorno da funcao DetProva
Local nTaxa			:= 0
Local nHead			:= 0
Local nX			:= 0
Local nI			:= 0
Local nValExced		:= 0
Local nLp69B		:= 0
Local nLp69I		:= 0

Local lCriaProv		:= AllTrim(SuperGetMV("MV_CNTPPP" ,.F.,"0")) $ "0/1"  // define quando os contratos recorrentes serão provisionados
Local lVldVige 		:= GetNewPar("MV_CNFVIGE","N") == "N"
Local lTitProv		:= GetNewPar("MV_CNPROVI","S") == "S"
Local lPeSld   		:= ExistBlock("CN121ELD")
Local lCN121EPM 	:= ExistBlock("CN121EPM")
Local lRecorre		:= .F.
Local lMedEve  		:= .F.
Local lFisico  		:= .F.
Local lSemiFix		:= .F.
Local lValor   		:= .T.
Local lFixo    		:= .T.
Local lRet     		:= .T.
Local lEstSld		:= .T.
Local lDigita 		:= .F.    	//-- Mostra lancamento?
Local lAglutina		:= .F.    	//-- Aglutina
Local lMedComPlan 	:= .F.
Local lUsaFlag		:= SuperGetMV( "MV_CTBFLAG" , .T. /*lHelp*/, .F. /*cPadrao*/)
Local lCtbCNE		:= .F.
Local lCtbOnLine	:= .F.
Local aFlagCTB 		:= {}

Local dDtFim		:= dDataBase

Local aDocuments	:= {}
Local aLPGCT		:= {{"697",VerPadrao("697")},; //-- LP Gestão de Contratos - Encerramento da Medição
						{"698",VerPadrao("698")},; //-- LP Gestão de Contratos - Encerramento da Medição/Automatico
						{"699",VerPadrao("699")},; //-- LP Gestão de Contratos - Encer. Medicao: Itens do Contrato
						{"69A",VerPadrao("69A")},; //-- LP Gestão de Contratos - Est. Medicao: Itens do Contrato
						{"69B",VerPadrao("69B")},; //-- LP Gestão de Contratos - Incl. Rateio Itens Contrato s/ Planilha
						{"69C",VerPadrao("69C")},; //-- LP Gestão de Contratos - Excl. Rateio Itens Contrato s/ Planilha
						{"69D",VerPadrao("69D")},; //-- LP Gestão de Contratos - Incl. Rateio Itens Contrato c/ Planilha
						{"69E",VerPadrao("69E")},;
						{"69F",VerPadrao("69F")},; //LP Gestão de Contratos - Excl. Rateio Itens Contrato c/ Planilha
						{"69H",VerPadrao("69H")},; //LP Gestão de Contratos - Encerramento da medição por item norma IFRS 15 (bens e serviços)
						{"69I",VerPadrao("69I")}; //LP Gestão de Contratos - Estorno da medição por item norma IFRS 15 (bens e serviços)
					}

DEFAULT lAviso 		:= .T.
DEFAULT lAutoFor	:= CND->CND_AUTFRN=="2"
DEFAULT lMedServ	:= CND->CND_SERVIC=="2"
DEFAULT lAprRev		:= .F.

lMsErroAuto := Iif(Type("lMsErroAuto")=='L',lMsErroAuto,.F.)

//-- Ponto de entrada para indicar se atualiza ou nao saldo da medicao no estorno
If ExistBlock("CN121ASD")
	lEstSld := ExecBlock("CN121ASD",.F.,.F.)
	If ValType(lEstSld) <> "L"
		lEstSld := .T.
	EndIf
EndIf

//-- Estabelece passos
ProcRegua(6)

If !lAutoFor .Or. !lMedServ
	lRet := CN240VldUsr(CND->CND_CONTRA,DEF_TRAEST_MED,.T.,,cFilCtr)
EndIf

Pergunte("CNT120",.F.)	//-- Carrega as variaveis

If (lCtbOnLine := IIf(ValType(MV_PAR01)=="N",MV_PAR01 == 1,.F.))//SE CONTABILIZA, atraves da escolha do usuario
	//Percorre os lancamentos contabeis do GCT, se algum deles existir, a contabilizacao podera ter continuidade
	For nI := 1 to len(aLPGCT)
		If aLPGCT[nI,2]
			lCtbOnline := .T.
			Exit
		Else
			lCtbOnline := .F.
		Endif
	Next nI

	If lRet .And. lCtbOnLine
		lDigita	  := IIf(ValType(MV_PAR02)=="N",MV_PAR02 == 1,.F.)
		lAglutina := IIf(ValType(MV_PAR03)=="N",MV_PAR03 == 1,.F.)
		nHead	  := HeadProva(cLoteGCT,"CNTA120",Subs(cUsuario,7,6),@cArqGCT)
		If nHead <= 0
			Help(" ",1,"SEM_LANC")
			lCtbOnLine := .F.
		EndIf
	EndIf
Endif

If lRet
	If !Empty(CND->CND_DTFIM) .Or. lAutoFor
		nTipo 	:= Iif(lAutoFor,2,1)
		nServico:= Iif(lMedServ,2,1)

		CN9->(dbSetOrder(1)) //-- CN9_FILIAL+CN9_NUMERO+CN9_REVISA
		CN9->(dbSeek(xFilial("CN9",cFilCTR)+CND->CND_CONTRA+"ZZZ",.T.)) //-- Posiciona na revisao atual do contrato
		CN9->(dbSkip(-1))
		//-- So permite o estorno se o contrato estiver fora das seguintes situacoe contrato finalizado ou fora do período da vigência
		If lVldVige .And.((CN9->CN9_SITUAC==DEF_SFINA) .Or. (CN9->CN9_DTINIC > dDataBase .Or. CN9->CN9_DTFIM < dDataBase))
			lRet := .F.
			Help( " ", 1, "CNTA120_07" )	//-- Contrato fora do periodo de vigencia
			cMedErro := STR0179	
		EndIf

		If lRet .And. CN9->CN9_SITUAC==DEF_SFINA
			lRet := .F.
			Help("",1,STR0079,,STR0105,4,1)		//-- Ação não disponível para contrato Finalizado
			cMedErro := STR0105					//-- Ação não disponível para contrato Finalizado
	 	EndIF

		If lRet .And. CN9->CN9_SITUAC==DEF_SCANC
			lRet := .F.
			Help('',1,"CNTA120_10")	//-- Ação não disponível para contrato Cancelado
			cMedErro := STR0178 	//-- Ação não disponível para contrato Cancelado
		EndIf

		If lRet .And. !lAprRev .And. CN9->CN9_SITUAC==DEF_SREVS
			lRet := .F.
			Help('',1,"CNTA120_11")	//-- Ação não disponível para contrato com Revisão em Aberto
			cMedErro := STR0180		//-- Ação não disponível para contrato com Revisão em Aberto
		EndIf

		If lRet .And. (CN9->CN9_REVISA <> CND->CND_REVISA) //-- Verifica se a revisao da medição é a revisão atual
			lRet := .F.
			Help('',1,"CNTA120_12")	//-- Estorno não permitido para revisões anteriores.
			cMedErro := STR0180		//-- Estorno não permitido para revisões anteriores.
		EndIf

		If lRet .And. nModulo <> 28
			DbSelectArea("TFJ")
			TFJ->(DbSetOrder(5)) //-- TFJ_FILIAL+TFJ_CONTRT+TFJ_CONREV
			If TFJ->(dbSeek(xFilial("TFJ")+CN9->(CN9_NUMERO+CN9_REVISA))) .And. Cn120IsMdGS(CND->CND_NUMMED)
				lRet := .F.
				Help(" ",1,"CNTA120TEC")	//-- Acao disponivel apenas para contratos sem vinculos com Gestão de Serviços
			EndIf
		EndIf

		If lRet .And. !Empty(CND->CND_RETCAC)
			//-- Verifica se existe retencao para a medicao e se
			//-- a mesma se encontra baixada
			cQuery := " SELECT COUNT(*) AS RETQTD "
			cQuery += " FROM "+RetSQLName("CNT")+" CNT"
			cQuery += " WHERE CNT.CNT_FILIAL = '"+xFilial("CNT",cFilCTR)+"'"
			cQuery += " AND CNT.CNT_CONTRA = '"+CND->CND_CONTRA+"'"
			cQuery += " AND CNT.CNT_NUMMED = '"+CND->CND_NUMMED+"'"
			cQuery += " AND CNT.CNT_VLBX   > 0"
			cQuery += " AND D_E_L_E_T_ = ' '"

			cAliasCNT := GetNextAlias()
			cQuery := ChangeQuery(cQuery)
			dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasCNT,.F.,.T.)
			lRet := ((cAliasCNT)->RETQTD == 0)
			(cAliasCNT)->(dbCloseArea())

			If !lRet
				Help( " ", 1, "CNTA120_05")//-- A medição não pode ser estornada, pois o valor de retenção da caução já foi baixado"
			EndIf
		EndIf

		Begin Transaction

			If lRet
				//Valida se a medição é de excedente para competência não prevista
				If GCTExcedNP(CND->CND_NUMMED)
					SetExcedNP(.T.)
				EndIf
	
				cChaveCXN := xFilial("CXN")+CND->CND_CONTRA+CND->CND_REVISA+CND->CND_NUMMED
				CXN->(DbSetOrder(1)) //-- CXN_FILIAL+CXN_CONTRA+CXN_REVISA+CXN_NUMMED+CXN_NUMPLA
				CXN->(DbSeek(xFilial("CXN")+CND->CND_CONTRA+CND->CND_REVISA+CND->CND_NUMMED))
	
					While CXN->(!EOF()) .And. cChaveCXN == CXN->(CXN_FILIAL+CXN_CONTRA+CXN_REVISA+CXN_NUMMED)
					//- Aqui processa cada registro da CXN
						If !(CXN->CXN_CHECK)
							CXN->(DbSkip())
							Loop
						EndIf
	
						//-- Encerramento de planilhas zeradas
						If CXN->(Columnpos('CXN_ZERO')) > 0
							If CXN->CXN_ZERO == '1'
								CN121ZERO( CXN->CXN_CONTRA , CXN->CXN_REVISA , CXN->CXN_NUMMED , CXN->CXN_NUMPLA , cFilCtr , '2')
								CXN->(DbSkip())
								Loop
							EndIf
						EndIf
	
						//- Caracteristicas do contrato pelo tipo de planilha
						cEspCtr := CN121RetSt("ESPECIE",	0,CXN->CXN_NUMPLA,CXN->CXN_CONTRA,.F.)
						lMedEve := CN121RetSt("MEDEVE",		0,CXN->CXN_NUMPLA,CXN->CXN_CONTRA,.F.)
						lContab := CN121RetSt("CONTABIL",	0,CXN->CXN_NUMPLA,CXN->CXN_CONTRA,.F.)
						lFixo	:= CN121RetSt("FIXO",		0,CXN->CXN_NUMPLA,CXN->CXN_CONTRA,.F.)
						lValor	:= CN121RetSt("PREVFINANC",	0,CXN->CXN_NUMPLA,CXN->CXN_CONTRA,.F.)
						lFisico := CN121RetSt("FISICO",		0,CXN->CXN_NUMPLA,CXN->CXN_CONTRA,.F.)
						lRecorre:= CN121RetSt("RECORRENTE",	0,CXN->CXN_NUMPLA,CXN->CXN_CONTRA,.F.)
						lSemiFix:= CN121RetSt("SEMIFIXO",	0,CXN->CXN_NUMPLA,CXN->CXN_CONTRA,.F.)
						lServico:= CN121RetSt('SERVIÇO',	0,CXN->CXN_NUMPLA,CXN->CXN_CONTRA,.F.)
	
						//Valor total dos itens excedentes da planilha
						nValExced := CN120VlExc(CND->CND_CONTRA,CND->CND_REVISA,CND->CND_NUMMED,CXN->CXN_NUMPLA)
	
						//- Busca parcela do cronograma
						If lRet .And. !Empty(CXN->CXN_CRONOG)
							cCronog := CXN->CXN_CRONOG
							CNF->(dbSetOrder(3)) //-- CNF_FILIAL+CNF_CONTRA+CNF_REVISA+CNF_NUMERO+CNF_PARCEL
							If CNF->(MsSeek(xFilial("CNF",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA+cCronog+CXN->CXN_PARCEL))
								nTaxa := CNF->CNF_TXMOED
							EndIf
						EndIf
	
						PcoIniLan("000355")
	
						//- Busca documentos da medição
						cChaveCXJ := xFilial("CXJ")+CND->(CND_CONTRA+CND_NUMMED)+CXN->CXN_NUMPLA
						CXJ->(DbSetOrder(1)) //-- CXJ_FILIAL+CXJ_CONTRA+CXJ_NUMMED+CXJ_NUMPLA+CXJ_ITEMPL+CXJ_PRTENV+CXJ_ID
						CXJ->(MsSeek(cChaveCXJ))
	
						IncProc(STR0155)//-- Verificando documentos da medição
						While CXJ->(!EOF()) .And. cChaveCXJ == CXJ->(CXJ_FILIAL+CXJ_CONTRA+CXJ_NUMMED+CXJ_NUMPLA)
							lFind:=  aScan(aDocuments,{|x| x[2] == CXJ->CXJ_NUMPED }) > 0  .Or.  aScan(aDocuments,{|x| x[2] == CXJ->CXJ_NUMTIT }) > 0
							If !lFind
								If cEspCtr == '1'
									If Empty(CXJ->CXJ_NUMTIT)
										aAdd(aDocuments,{"1",CXJ->CXJ_NUMPED}) //-- Pedido de Compra
									Else
										aAdd(aDocuments,{"3",CXJ->CXJ_NUMTIT}) //-- Titulo a Pagar - SE2
									EndIf
								Else
									If Empty(CXJ->CXJ_NUMTIT)
										aAdd(aDocuments,{"2",CXJ->CXJ_NUMPED}) //-- Pedido de Venda
									Else
										aAdd(aDocuments,{"4",CXJ->CXJ_NUMTIT}) //-- Titulo a Receber - SE1
									EndIf
								EndIf
							EndIf
	
							CXJ->(dbSkip())
						EndDo
	
						If lRet
							dDtFim := CND->CND_DTFIM
	
							PcoDetLan("000355","03","CNTA120",.T.)	//-- Ponto de lancamento contabil e orcamentario para estorno da medicao
	
							If lRet .And. lCtbOnLine
						    	nDet += DetProva(nHead,"699","CNTA121",cLoteGCT,,,,,,,,,{"CND",CND->(RECNO())})
							EndIf
	
							IncProc( STR0098 )//-- Atualizando Medição e Itens
	
							//- Atualiza saldo da planilha se tipo de contato/planilha é fixa
							If ( (lFixo .Or. lSemiFix) .And. !lRecorre) .Or. (lValor .And. !lRecorre)	 //-- Atualiza saldo da planilha
								CNA->(dbSetOrder(1))
								If CNA->(dbSeek(xFilial("CNA",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA+CXN->CXN_NUMPLA))
									If lEstSld .And. !lPeSld
										RecLock("CNA",.F.)
										CNA->CNA_SALDO += xMoeda(CXN->CXN_VLLIQD - nValExced ,CND->CND_MOEDA,CN9->CN9_MOEDA,dDtFim,nTamVlTot,,nTaxa)
										MsUnlock()
									EndIf
								EndIf
							EndIf
	
							//- Atualiza saldo do contrato se tipo de contrato/planilha é fixo
							CN9->(dbSetorder(1))
							If CN9->(dbSeek(xFilial("CN9",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA))
								If lEstSld .And. !lPeSld
									RecLock("CN9",.F.)
										If ( (lFixo .Or. lSemiFix) .And. !lRecorre) .Or. (lValor .And. !lRecorre)
											CN9->CN9_SALDO += xMoeda(CXN->CXN_VLLIQD - nValExced ,CND->CND_MOEDA,CN9->CN9_MOEDA,dDtFim,nTamVlTot,,nTaxa)
										ElseIf !lRecorre
											CN9->CN9_VLATU -= xMoeda(CXN->CXN_VLLIQD - nValExced ,CND->CND_MOEDA,CN9->CN9_MOEDA,dDtFim,nTamVlTot,,nTaxa)		//Atualiza valor do contrato
											If Empty(CN9->CN9_REVISA)//Se contrato original atualiza valor inicial
												CN9->CN9_VLINI -= xMoeda(CXN->CXN_VLLIQD - nValExced ,CND->CND_MOEDA,CN9->CN9_MOEDA,dDtFim,nTamVlTot,,nTaxa)
											EndIf
										EndIf
									MsUnlock()
								EndIf
							EndIf
	
							//- localiza e atualiza valores da parcela do cronograma se não é eventual
							If !lMedeve .And. !lRecorre //-- Atualiza saldo do cronograma quando nao houver  medicao eventual
								If !Empty(CXN->CXN_PARCEL)
									CNF->(dbSetorder(3)) //-- CNF_FILIAL+CNF_CONTRA+CNF_REVISA+CNF_NUMERO+CNF_PARCEL
									CNF->(dbSeek(xFilial("CNF",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA+cCronog+CXN->CXN_PARCEL))
								Else
									CNF->(dbSetorder(2)) //-- CNF_FILIAL+CNF_CONTRA+CNF_REVISA+CNF_NUMERO+CNF_COMPET
									CNF->(dbSeek(xFilial("CNF",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA+cCronog+CND->CND_COMPET))
								EndIf
	
								If CNF->(Found())
									cParcel := CNF->CNF_PARCEL
									If lEstSld .And. !lPeSld
										RecLock("CNF")
											CNF->CNF_VLREAL -= xMoeda(CXN->CXN_VLLIQD - nValExced ,CND->CND_MOEDA,CN9->CN9_MOEDA,dDtFim,nTamVlTot,,nTaxa)
											CNF->CNF_SALDO  += xMoeda(CXN->CXN_VLLIQD - nValExced ,CND->CND_MOEDA,CN9->CN9_MOEDA,dDtFim,nTamVlTot,,nTaxa)
											If CNF->CNF_VLREAL == 0
												CNF->CNF_DTREAL := CTOD("")
											Else
												//-- Atualiza a data de realizacao do Cronograma quando estornar medição parcial
												aAreaCND := CND->(GetArea())
												CNF->CNF_DTREAL := CTOD("")
												CND->(dbSkip(-1))
												While !CND->(Bof())
													If CND->CND_CONTRA+CND->CND_REVISA = CNF->CNF_CONTRA+CNF->CNF_REVISA .And. Empty(CNF->CNF_DTREAL)
														If 	!Empty(CND->CND_DTFIM) .And. CXN->CXN_PARCEL = CNF->CNF_PARCEL .And. ;
															(Empty(CNF->CNF_DTREAL) .Or. CND->CND_DTFIM > CNF->CNF_DTREAL)
															CNF->CNF_DTREAL := CND->CND_DTFIM
														Endif
													EndIf
													CND->(dbSkip(-1))
												EndDo
												RestArea(aAreaCND)
											EndIf
										MsUnlock()
									EndIf
									//- ajusta os títulos provisórios
									If lTitProv
										IncProc(STR0099)//-- Processando títulos provisórios
	
										//- Exclui título procisório gerado no encerramento da medição
										CN100ETit(CND->CND_CONTRA,CND->CND_REVISA,cCronog,CNF->CNF_PARCEL,cFilCtr)
	
										//- Inclui título provisório do saldo atualizado da parcela
										If CNF->CNF_SALDO > 0
											CN100CTit(CND->CND_CONTRA,CND->CND_REVISA,cCronog,CNF->CNF_PARCEL,CNF->CNF_SALDO,cFilCtr)
										EndIf
									EndIf
								EndIf
							EndIf
	
							//- atualiza saldos de cronogramas fisico/financeiro
							cChaveCNE := xFilial("CNE")+CND->(CND_CONTRA+CND_REVISA)+CXN->CXN_NUMPLA+CND->CND_NUMMED
							CNE->(dbSetOrder(1))
							CNE->(MsSeek(cChaveCNE))
	
							While !CNE->(Eof()) .And. cChaveCNE == CNE->(CNE_FILIAL+CNE_CONTRA+CNE_REVISA+CNE_NUMERO+CNE_NUMMED)
								lMedComPlan := .F.
								//-- Atualiza saldo dos itens da planilha, itens excedentes nao atualizam saldos
								If CNE->CNE_EXCEDE == '2' .And. !lRecorre
									CNB->(dbSetOrder(1)) //-- CNB_FILIAL+CNB_CONTRA+CNB_REVISA+CNB_NUMERO+CNB_ITEM
									If CNB->(dbSeek(xFilial("CNB",cFilCTR)+CNE->CNE_CONTRA+CNE->CNE_REVISA+CNE->CNE_NUMERO+CNE->CNE_ITEM))
										If lEstSld .And. !lPeSld
											RecLock("CNB",.F.)
												If nServico == 1
													CNB->CNB_QTDMED -= CNE->CNE_QUANT
													CNB->CNB_SLDMED += Iif(lSemiFix,0,CNE->CNE_QUANT)
												Else
													CNB->CNB_QTDMED -= CNE->CNE_QTDORI
													CNB->CNB_SLDMED += Iif(lSemiFix,0,CNE->CNE_QTDORI)
												EndIf
											MsUnlock()
										EndIf
										lMedComPlan := .T. //-- CAPTURO A VARIAVEL FLAG DE ITENS COM PLANILHA
									EndIf
	
									//- atualiza saldo do cronograma físico
									If lFisico
										CNS->(dbSetOrder(1)) //-- CNS_FILIAL+CNS_CONTRA+CNS_REVISA+CNS_CRONOG+CNS_PARCEL+CNS_ITEM
										If CNS->(dbSeek(cFilCNS+CND->CND_CONTRA+CND->CND_REVISA+cCronog+cParcel+CNE->CNE_ITEM))
											If lEstSld .And. !lPeSld
												RecLock("CNS",.F.)
													CNS->CNS_RLZQTD -= CNE->CNE_QUANT
													CNS->CNS_SLDQTD += CNE->CNE_QUANT
												MsUnlock()
											EndIf
										EndIf
									EndIf
								EndIf
	
								PcoDetLan("000355","04","CNTA120",.T.)
	
								If lRet .And. lCtbOnLine //CONTABILIZA ESTORNO DA MEDICAO - ITENS DO CONTRATO
	
									nLp69B := aScan(aLPGCT,{|x| x[1]=="69B"})
									nLp69I := aScan(aLPGCT,{|x| x[1]=="69I"})
	
									If lUsaFlag
										aAdd( aFlagCTB, {"CNE_DTLANC", dDataBase, "CNE", CNE->( Recno() ), 0, 0, 0} )
									EndIf
	
									If aLPGCT[nLp69I,2]  .And. cEspCtr == '2' .And. CN9->CN9_DTINIC >= CTOD("01/01/2018") // - Ponto de lançamento padrão IFRS15
										nDet += DetProva(nHead,'69I',cOrigem,cLoteGCT,,,,,,,,@aFlagCTB,{"CNE",CNE->(Recno())})
										lCtbCNE := .T.
									ElseIf aLPGCT[nLp69B,2]
										nDet += DetProva(nHead,"69B","CNTA120",cLoteGCT,,,,,,,,,{"CNE",CNE->(Recno())})
										lCtbCNE := .T.
									EndIf
	
									If !lUsaFlag .And. lCtbCNE
										If CNE->(Columnpos('CNE_DTLANC')) > 0
											dbSelectArea("CNE")
											RecLock("CNE",.F.)
											CNE->CNE_DTLANC := dDataBase
											MsUnlock()
										EndIf
									EndIf
	
								EndIf
	
								If lMedComPlan
									cLancCont := "69F"
									cSeqPCOLan:= "06"
								Else
									cLancCont := "69D"
									cSeqPCOLan:= "05"
								Endif
	
								cBusca := xFilial("CNZ",cFilCTR)+ CNE->(CNE_CONTRA+CNE_REVISA+CNE_NUMMED+CNE_ITEM)
								CNZ->(dbSetOrder(2)) //CNZ_FILIAL+CNZ_CONTRA+CNZ_REVISA+CNZ_NUMMED+CNZ_ITCONT+CNZ_ITEM
								If CNZ->(dbSeek( cBusca ))
									While CNZ->(!Eof()) .and. cBusca == xFilial("CNZ",cFilCTR)+CNE->(CNE_CONTRA+CNE_REVISA+CNE_NUMMED+CNE_ITEM)
										PcoDetLan("000355",cSeqPCOLan,"CNTA120",.T.)
										If lRet .And. lCtbOnLine
											//CONTABILIZA OS RATEIOS DO ITEM DO CONTRATO COM PLANILHA.
											//SE HA PLANILHA, ENTAO NAO PODERA CONTABILIZAR O RATEIO SEM PLANILHA, ABAIXO (CONTROLAR COM VARIAVEL FLAG)
											//EFETUA A CONTABILIZACAO DOS RATEIOS DO ITEM DO CONTRATO SEM PLANILHA,
											nDet	+= DetProva(nHead,cLancCont,"CNTA120",cLoteGCT,,,,,,,,,{"CNZ",CNZ->(RECNO())})
										Endif
										CNZ->(DbSkip())
									EndDo
								Endif
	
								If CNE->CNE_EXCEDE == '1' .And. !lExcedNPrv	//Exclui excedentes no estorno
									RecLock('CXN',.F.) //- Atualiza Totais da CXN
									CXN->CXN_VLLIQD -= CNE->CNE_VLTOT
									CXN->CXN_VLTOT  -= (CNE->CNE_VLTOT + CNE->CNE_MULTA - CNE->CNE_BONIF)
									CXN->(MsUnlock())
	
									RecLock('CND',.F.) //- Atualiza Totais da CND
									CND->CND_VLLIQD -= CNE->CNE_VLTOT
									CND->CND_VLTOT 	-= (CNE->CNE_VLTOT + CNE->CNE_MULTA - CNE->CNE_BONIF)
									CND->(MsUnlock())
	
									dbSelectArea('CNZ')
									cChaveCNZ := CNE->(CNE_FILIAL+CNE_CONTRA+CNE_REVISA+CNE_NUMMED+CNE_NUMERO+CNE_ITEM)
									CNZ->(dbSetOrder(5)) //CNZ_FILIAL+CNZ_CONTRA+CNZ_REVISA+CNZ_NUMMED+CNZ_CODPLA+CNZ_ITCONT+CNZ_ITEM
									CNZ->(MsSeek(cChaveCNZ))
									While CNZ->(!EOF()) .And. CNZ->(CNZ_FILIAL+CNZ_CONTRA+CNZ_REVISA+CNZ_NUMMED+CNZ_CODPLA+CNZ_ITCONT) == cChaveCNZ
										RecLock('CNZ',.F.)
										CNZ->(dbDelete())
										CNZ->(MsUnlock())
										CNZ->(dbSkip())
									End
	
									RecLock('CNE',.F.)
									CNE->(dbDelete())
									CNE->(MsUnlock())
								EndIf
	
	
								CNE->(dbSkip())
							EndDo
	
							IncProc( STR0106 )//-- Atualizando Saldos
	
							If lPeSld//Chama ponto de entrada para atualizacao do saldo
								ExecBlock("CN121ELD",.f.,.f.,{lMedEve,lFisico,cCronog,lFixo,lValor})
							EndIf
	
							CN120HistMul( 2, NIL, CND->CND_CONTRA, CND->CND_NUMMED )//-- Estorna o historico de multas / bonificacoes do contrato
							If !Empty(CND->CND_RETCAC) //-- Estorna o valor retido da caucao
								CN120CaucRet(CND->CND_CONTRA,CND->CND_NUMMED,2,CND->CND_RETCAC)
							EndIf
	
						EndIf
	
						PcoFinLan("000355")
	
						If lRet .And. lRecorre
						//- Atualiza títulos provisórios
							If lTitProv
								IncProc(STR0099) //-- Processando títulos provisórios
								// exclui a última parcela provisória se o parâmetro MV_CNTPPP é 0 ou 1
								If lCriaProv
									CN100ETit(CND->CND_CONTRA,CND->CND_REVISA,"RECORRENTE",CXN->CXN_PARCEL,cFilCtr,CXN->CXN_NUMPLA,.T.)
								Endif
								// inclui titulo provisório da parcela atual
								CN100RecTi(CND->CND_CONTRA,CND->CND_REVISA,CXN->CXN_PARCEL,CXN->CXN_NUMPLA,.T.)
							Endif
	
							CNA->(dbSetOrder(1))
							CNB->(dbSetOrder(1))
							CNE->(dbSetOrder(1)) // CNE_FILIAL, CNE_CONTRA, CNE_REVISA, CNE_NUMERO, CNE_NUMMED, CNE_ITEM
							CNE->(dbSeek( xFilial("CNE") + CXN->(CXN_CONTRA+CXN_REVISA+CXN_NUMPLA+CXN_NUMMED)))
							If lEstSld
								While !CNE->(Eof()) .AND. CNE->(CNE_FILIAL+CNE_CONTRA+CNE_REVISA+CNE_NUMERO+CNE_NUMMED) == xFilial("CNE")+CXN->(CXN_CONTRA+CXN_REVISA+CXN_NUMPLA+CXN_NUMMED)
									If 	CNE->CNE_QUANT > 0 .AND. CNA->(MsSeek(xFilial("CNA")+CNE->(CNE_CONTRA+CNE_REVISA+CNE_NUMERO)));
										.AND. !Empty(CNA->CNA_PERIOD) .AND. CNA->CNA_RECMED == CND->CND_NUMMED
	
										//- Se é primeira medição verifica se foi pro-rata e atualiza CNB
										If 	CNA->CNA_MEDEFE == 1 .AND. CNB->(MsSeek( xFilial("CNB")+CNE->(CNE_CONTRA+CNE_REVISA+CNE_NUMERO+CNE_ITEM))) ;
											.AND. CNB->CNB_PARPROR > 0 .AND. !Empty(CNB->CNB_PRIMED)
											RecLock("CNB",.F.)
												CNB->CNB_PRIMED := Ctod("")
											MsUnlock()
										Endif
	
										//- Atualiza campos de controle dos contratos recorrentes na planilha
										RecLock("CNA",.F.)
											CNA->CNA_MEDEFE := CNA->CNA_MEDEFE - 1
											CNA->CNA_PROMED := CNA->CNA_ULTMED
											CNA->CNA_ULTMED := CND->CND_ULTMED
											CNA->CNA_RECMED := CND->CND_RECMED
											CNA->CNA_PROPAR	:= CXN->CXN_PARCEL
										CNA->(MsUnlock())
									Endif
									CNE->(dbSkip())
								EndDo
							EndIf
						Endif
						CXN->(dbSkip())
					EndDo
					
					// atualiza campos de controle dos contratos recorrentes na medição
					If lRet
						RecLock("CND",.F.)
						CND->CND_RECMED := Space(TamSx3("CND_RECMED")[1])
						CND->CND_ULTMED := Ctod("")
						If !lAutForn
							CND->CND_DTFIM := CTOD("")
							CND->CND_SITUAC:= "A"
						EndIf
						CND->(MsUnlock())
					EndIf
					
					If lRet
						For nX := 1 To Len(aDocuments) //-- Documentos encontrados para serem estornados
							If cEspCtr == "1"
								//-- Verifica se o documento é Pedido de Compra
								If aDocuments[nX,1] == "1"
									// PE para tratamento específico do usuário antes da exclusão do Pedido de compras
									If lCN121EPM
										ExecBlock("CN121EPM",.F.,.F.)
									EndIf
									IncProc( STR0107 )//-- Verificando pedido de compras
									MSExecAuto({|v,x,y,z,w| MATA120(v,x,y,z,w)},1,{{"C7_NUM",aDocuments[nX,2],NIL}},{},5,.F.) //Exclui pedido de compras
									If lMsErroAuto
										MostraErro()
										lRet:= .F.
										Exit
									Else
										aAreaAux := GetArea()										
										cKeyTmp := xFilial("CXN") + CND->CND_CONTRA + CND->CND_REVISA + CND->CND_NUMMED
										CXN->(DbSetOrder(1)) //-- CXN_FILIAL+CXN_CONTRA+CXN_REVISA+CXN_NUMMED+CXN_NUMPLA
										If CXN->(DbSeek(xFilial("CXN")+CND->CND_CONTRA+CND->CND_REVISA+CND->CND_NUMMED))
											CNE->(DbSetOrder(1)) // CNE_FILIAL, CNE_CONTRA, CNE_REVISA, CNE_NUMERO, CNE_NUMMED, CNE_ITEM
											While CXN->(!EOF()) .And. (cKeyTmp == CXN->CXN_FILIAL+ CXN->CXN_CONTRA + CXN->CXN_REVISA + CXN->CXN_NUMMED)
												If CXN->CXN_CHECK
													cKeyCNE := xFilial("CNE") + CXN->CXN_CONTRA + CXN->CXN_REVISA + CXN->CXN_NUMPLA + CXN->CXN_NUMMED
													If CNE->( DbSeek(cKeyCNE))
														While !CNE->(Eof()) .And. cKeyCNE == (CNE->CNE_FILIAL + CNE->CNE_CONTRA + CNE->CNE_REVISA + CNE->CNE_NUMERO + CNE->CNE_NUMMED)
															If CNE->CNE_PEDIDO == aDocuments[nX,2]
																RecLock("CNE",.F.)
																CNE->CNE_PEDIDO := Space(TamSx3("CNE_PEDIDO")[1])
																CNE->(MsUnlock())
															EndIf
															CNE->(DbSkip())
														EndDo
													EndIf
												EndIf
												CXN->(DbSkip())
											EndDo
										EndIf
										RestArea(aAreaAux)
									EndIf
								EndIf
								//-- Verifica se o documento é Titulo a Pagar - SE2
								If lRet .And. aDocuments[nX,1] == "3"
									IncProc(STR0108)//-- Verificando título a pagar
									aTitulo := {}
									cNumTit	:= aDocuments[nX,2]
									lRet := EstTitMed(cRetPrf, cNumTit, cTpTit, .F.)  
								EndIf
							Else
								//-- Verifica se o documento é Pedido de Venda
								If aDocuments[nX,1] == "2"
									IncProc( STR0109 )//-- Verificando pedido de venda
									MSExecAuto({|x,y,z| Mata410(x,y,z)},{{"C5_NUM",aDocuments[nX,2],NIL}},{},5) //-- Exclui pedido de venda
									If lMsErroAuto
										MostraErro()
										lRet:= .F.
										Exit
									Endif
								EndIf
								//-- Verifica se o documento é Titulo a Receber - SE1
								If lRet .And. aDocuments[nX,1] == "4"
									IncProc(STR0110)//-- Verificando título a receber
									
									cNumTit	:= aDocuments[nX,2]
									lRet := EstTitMed(cRetPrf, cNumTit, cTpTit)	
								EndIf
							EndIf
						Next nX
	
						If lRet
							aAreaCND  := CND->(GetArea()) 					//Guarda a posição atual da CND
							CND->(MsGoTo(nReg)) 							//Posiciona na linha celecionada
							CN121DelCXJ(CND->CND_CONTRA,CND->CND_NUMMED) 	//Deleta registros de documentos
							RestArea(aAreaCND) 								//Devolve a posição da CND
						EndIf
					EndIf
		
				If lAviso
					If !lRet
						Aviso("CNTA121",STR0111,{STR0156})				//"O documento não pode ser estornado"
						DisarmTransaction()
					ElseIf nTipo == 1  .And. nServico == 1
						Aviso("CNTA121",OemToAnsi(STR0112),{STR0156})	//"Medição/entrega estornada com sucesso"
					EndIf
				EndIf
			EndIf
		
		End Transaction
			
	EndIf

	//Restaura valor default da variável static lExcedNPrv
	SetExcedNP(.F.)
EndIf

If lRet .And. lCtbOnLine
	RodaProva(nHead,nDet)
	If nDet > 0
		cA100Incl(cArqGCT,nHead,1,cLoteGCT,lDigita,lAglutina,,,,@aFlagCTB)
		aFlagCTB := {}
	Endif
EndIf

Return lRet
//-------------------------------------------------------------------
/*/{Protheus.doc} CN121DelCXJ
Exclui tabela CXJ
@author leonardo.quintania
@since 22/11/2013
@version P11.90
/*/
//-------------------------------------------------------------------
Static Function CN121DelCXJ(cContra,cMedicao)
Local aArea		:= GetArea()

BeginSql Alias "CXJTMP"
	SELECT CXJ.R_E_C_N_O_ AS RECNOCXJ
	FROM	%Table:CXJ% CXJ
	WHERE CXJ.CXJ_FILIAL = %xFilial:CXJ%
		AND CXJ.CXJ_CONTRA = %Exp:cContra%
		AND CXJ.CXJ_NUMMED = %Exp:cMedicao%
		AND CXJ.%NotDel%
EndSql

While !CXJTMP->(EOF())
	CXJ->(dbGoTo(CXJTMP->RECNOCXJ))
	RecLock("CXJ",.F.)
	CXJ->(dbDelete())
	CXJ->(MsUnlock())
	CXJTMP->(dbSkip())
EndDo
CXJTMP->(dbCloseArea())

RestArea(aArea)
Return NIL

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121IFC
Retorna Cliente/Fornecedor e Loja da Planilha CXN
@author rogerio.melonio
@since 04/09/15
/*/
//-------------------------------------------------------------------
Function CN121IFC(cCampo)
Local cRet := ""

If cCampo == "CLIFOR"
	cRet := Posicione("CNA",1,xFilial("CNA")+CXN->CXN_CONTRA+CXN->CXN_REVISA+CXN->CXN_NUMPLA,"CNA_CLIENT")
	If Empty(cRet)
		cRet := Posicione("CNA",1,xFilial("CNA")+CXN->CXN_CONTRA+CXN->CXN_REVISA+CXN->CXN_NUMPLA,"CNA_FORNEC")
	Endif
Else
	cRet := Posicione("CNA",1,xFilial("CNA")+CXN->CXN_CONTRA+CXN->CXN_REVISA+CXN->CXN_NUMPLA,"CNA_LOJACL")
	If Empty(cRet)
		cRet := Posicione("CNA",1,xFilial("CNA")+CXN->CXN_CONTRA+CXN->CXN_REVISA+CXN->CXN_NUMPLA,"CNA_LJFORN")
	Endif
Endif

Return cRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121VlAct()
Pré-Ativação do modelo

@author jose.eulalio
@since 07/09/2015
@version P12
@return lRet
/*/
//--------------------------------------------------------------------
Function CN121VlAct(oModel)
Local lRet 		:= .T.
Local lAltera	:= oModel:GetOperation() == MODEL_OPERATION_UPDATE
Local lExclui	:= oModel:GetOperation() == MODEL_OPERATION_DELETE
Local lAuto		:= IsBlind()

Local cTpCtr    := ""
Local lIntegra	:= .F.

If (lAltera .Or. lExclui) .And. !lExcedMEnc 
 cTpCtr    := Posicione("CN9",1,xFilial("CN9",CND->CND_FILCTR)+CND->CND_CONTRA+CND->CND_REVISA ,"CN9_TPCTO")
 lIntegra	:= Iif(CN1->(Columnpos('CN1_INTEGR')) > 0 ,Posicione("CN1",1,xFilial("CN1")+cTpCtr,"CN1_INTEGR"),.F.)
	If!IsInCallStack('CN300RevPd') .And. !(	Alltrim(CND->CND_SITUAC) == 'A' .Or. ;	// "Medição em Aberto"
											Alltrim(CND->CND_SITUAC) == 'FA'.Or. ;	// "Aut. Fornec. em Aberto"
											AllTrim(CND->CND_SITUAC) == 'B' .Or. ;	// "Bloqueio por Alçada"
											AllTrim(CND->CND_SITUAC) == 'R' .Or. ;	// "Rejeitado"
											Alltrim(CND->CND_SITUAC) == 'SA')		// "Medição de Serviço em Aberto"

		Help(" ",1,"CN121NoDel",,STR0114,1,0) //-- "Operação apenas permitida para Medições ou Aut. Fornec. em Aberto"
		lRet := .F.
	
	ElseIf lIntegra .And. !lAuto .And.	!IsInCallStack('CN121Encerr')
		Help("",1,"CN121Pims",,STR0182,1,0) //-- "Não e permitido excluir ou alterar medições de contratos integrados de forma manual."
		lRet := .F.
	EndIf
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121GatFC())
Gatilho para loja do fornecedor ou cliente
@author Israel.Escorizza
@since 23/09/2015
/*/
//-------------------------------------------------------------------
Function Cn121GatFC(oModelCXN,cCampo,cCodigo)
Local oModel 	:= oModelCXN:GetModel()
Local cContra	:= oModel:GetValue("CNDMASTER","CND_CONTRA")
Local cRevisa	:= oModel:GetValue("CNDMASTER","CND_REVISA")
Local cRet		:= ""

If CN121RetSt('COMPRA',0,,cContra, .T., oModel)
	cRet := Posicione("CNC",1,xFilial("CNC")+cContra+cRevisa+cCodigo,"CNC_LOJA")
Else
	cRet := Posicione("CNC",3,xFilial("CNC")+cContra+cRevisa+cCodigo,"CNC_LOJACL")
EndIf

Return cRet
//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121VldFC())
Função de Validação de Fornecedor ou Cliente para rotina de medição
@author Israel.Escorizza
@since 22/09/2015
/*/
//-------------------------------------------------------------------
Function Cn121VldFC(oModelCXN,cCampo,xValue)
Local lRet 		:= .T.
Local oModel 	:= oModelCXN:GetModel()
Local cFilCtr := oModel:GetValue("CNDMASTER","CND_FILCTR")
Local cFil		:= FWxFilial("CNC", cFilCtr)
Local cContra	:= oModel:GetValue("CNDMASTER","CND_CONTRA")
Local cRevisa	:= oModel:GetValue("CNDMASTER","CND_REVISA")
Local cCodigo	:= ""
Local cLoja		:= ""
Local cSeek		:= ""
Local nOrder	:= 0

nOrder := Iif(Cn121RetSt( "COMPRA",0,,, .T., oModel ),1,3)

Do Case
	//- Para os campos variaveis, é executado o order 1 e 3
	Case cCampo == "CXN_FORCLI"
		cCodigo := xValue
	Case cCampo == "CXN_LOJA"
		cCodigo := oModelCXN:GetValue("CXN_FORCLI")
		cLoja	 := xValue
	Case cCampo == "CXN_FORNEC"
		cCodigo := xValue
	Case cCampo == "CXN_LJFORN"
		cCodigo := oModelCXN:GetValue("CXN_FORNEC")
		cLoja	 := xValue
	Case cCampo == "CXN_CLIENT"
		cCodigo := xValue
	Case cCampo == "CXN_LJCLI"
		cCodigo := oModelCXN:GetValue("CXN_CLIENT")
		cLoja	 := xValue
EndCase

cSeek := cFil+cContra+cRevisa+cCodigo+cLoja
CNC->(dbSetOrder(nOrder))
lRet := IIf (CNC->(MsSeek(cSeek)),.T.,.F.)

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} A121GComp()
Função para recuperar a variavel estatica aComp
@author rogerio.melonio
@since 15/09/2015
/*/
//-------------------------------------------------------------------
Function A121GComp()
Return aComp

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121QtdIt())
Função que retorna a quantidade que deve ser utilizada no preenchimento da
medição que contenha cronograma financeiro.

@author Israel.Escorizza
@since 30/09/2015
@return nRet
/*/
//-------------------------------------------------------------------
Function Cn121QtdIt(nSldMed,nCnaSaldo,nCnfSaldo,lFisico,lFixo)
Local aArea		:= GetArea()
Local nRet		:= 0
Local cContra	:= CNB->CNB_CONTRA
Local cRevisa	:= CNB->CNB_REVISA
Local cNumPla	:= CNB->CNB_NUMERO
Local cItem		:= CNB->CNB_ITEM

Default nSldMed		:= 0
Default nCnaSaldo	:= 0
Default nCnfSaldo	:= 1

If nSldMed > 0
	//- Verificar se é serviço, se sim, verificar itens já medidos. Se item já medido, retornar 0.
	If A121Servico() .Or. !lFisico .And. !lFixo .And. CnTpProd("CNTA121", cNumPla, cContra, cRevisa) == 2
		nRet := A121QtdSrv(cContra,cRevisa,cNumPla,cItem)
	Else
		If lSugVal
			nRet := (nSldMed/nCnaSaldo)*nCnfSaldo
			nRet := Round(nRet, TamSX3("CNE_QUANT")[2])
		EndIf
	EndIf
Else
	nRet := 0
EndIf

RestArea(aArea)
Return nRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121QtdBlq(cContra,cRevisa,cNumPla,cItem)
Função que verifica a quantidade de itens utilizado em medições
em aberto para composição do saldo fisico atual valido.

É necessário informar o contrato, revisão e numero da planilha.
- O não preenchimento do Item retorna o saldo bloqueado da planilha.
- O preenchimento do Item, retorna o saldo bloqueado daquele item na planilha.

@author Israel.Escorizza
@since 30/09/2015
@return nRet
/*/
//-------------------------------------------------------------------
Function Cn121QtdBlq(cContra,cRevisa,cNumPla,cItem)
Local nRet			:= 0
Local cQuery 		:= ""
Local aArea		:= GetArea()
Local cAliasTmp	:= GetNextAlias()

Default cContra	:= ""
Default cRevisa	:= ""
Default cNumPla	:= ""
Default cItem		:= ""

cQuery += " SELECT SUM (CNE_QUANT) AS QTBLOQ FROM "+RetSQLName("CNE")+" WHERE "
cQuery += " CNE_FILIAL = '"+FWxFilial("CNE")+"' AND "
cQuery += " CNE_CONTRA = '"+cContra+"'	AND "
cQuery += " CNE_REVISA = '"+cRevisa+"'	AND "
cQuery += " CNE_NUMERO = '"+cNumPla+"'	AND "
cQuery += " CNE_ITEM   = '"+cItem+"'	AND "
cQuery += " CNE_NUMMED IN"
cQuery += " (SELECT CND_NUMMED FROM "+RetSQLName("CND")+" WHERE "
cQuery += " CND_CONTRA = '"+cContra+"'	AND "
cQuery += " CND_REVISA = '"+cRevisa+"'	AND "
cQuery += " CND_SITUAC IN ('A','B','SA')	AND "
cQuery += " D_E_L_E_T_ = ' ')			AND"
cQuery += " D_E_L_E_T_ = ' '"

cQuery := ChangeQuery(cQuery)
dbUseArea(.T.,"TOPCONN",TcGenQry( ,, cQuery ),cAliasTmp,.F.,.T.)

nRet := (cAliasTmp)->QTBLOQ
(cAliasTmp)->(dbCloseArea())
RestArea(aArea)

Return nRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121VldQtd(oModelGrid,cField,xValue,nLine)
Função que valida a quantidade informada na medição.

@author Israel.Escorizza
@since 30/09/2015
@return nRet
/*/
//-------------------------------------------------------------------
Function Cn121VldQtd(oModelGrid,cField,xValue,nLine)
Local lRet		:= .T.
Local aArea		:= GetArea()
Local aSaveLines:= FWSaveRows()
Local oModel	:= Nil
Local oModelCXN	:= Nil
Local oModelCNE	:= Nil
Local cContra	:= ""
Local cRevisa	:= ""
Local cNumPla	:= ""
Local cItem		:= ""
Local cProdut	:= ""
Local nQuant	:= 0
Local nQtaMed	:= 0
Local nLimMed	:= 0
Local nVlLimit  := 0
Local lRecorre	:= .F.
Local lFixo		:= .F.
Local lSemiFix	:= .F.
Local lSemiAgr	:= .F.
Local lLimFis	:= .F.
Local lPrevFin	:= .F.
Local lEventual	:= .F.
Local lFlex		:= .F.
Local lArrefat 	:= .F.
Local lFlexPrev := .F.
Local nX 		:= 0
Local nTotCNE	:= 0
Local lnotTEC930 := IIF( FindFunction("TEC930Test") .AND. TEC930Test() , .F. , !lMedicao)

If IsInCallStack('CNTA120') .And. lnotTEC930
	lRet := CN130VldQtd()
Else
	oModel		:= FwModelActive()
	oModelCXN	:= oModel:GetModel("CXNDETAIL")
	oModelCNE	:= oModel:GetModel("CNEDETAIL")
	cContra		:= oModel:GetValue("CNDMASTER","CND_CONTRA")
	cRevisa		:= oModel:GetValue("CNDMASTER","CND_REVISA")
	cNumPla		:= oModel:GetValue("CXNDETAIL","CXN_NUMPLA")
	cItem		:= oModel:GetValue("CNEDETAIL","CNE_ITEM")
	cProdut		:= oModel:GetValue("CNEDETAIL","CNE_PRODUT")
	nQuant		:= oModel:GetValue("CNEDETAIL","CNE_QUANT")
	nQtaMed		:= oModel:GetValue("CNEDETAIL","CNE_SDAMED")
	nLimMed		:= Cn121RetSt("LMTMED"	   	,0,cNumPla,cContra)
	lRecorre	:= CN121RetSt("RECORRENTE" 	,0,cNumPla,cContra)
	lFixo		:= CN121RetSt("FIXO"	   	,0,cNumPla,cContra)
	lSemiFix	:= CN121RetSt("SEMIFIXO"	,0,cNumPla,cContra)
	lSemiAgr	:= Cn121RetSt("SEMIAGRUP"	,0,cNumPla,cContra)
	lLimFis		:= Cn121RetSt("LMTFISICO"	,0,cNumPla,cContra)
	lPrevFin	:= CN121RetSt("PREVFINANC"	,0,cNumPla,cContra)
	lEventual	:= CN121RetSt("EVENTUAL"	,0,cNumPla,cContra)
	lFlex		:= !lFixo .And. lPrevFin
	lArrefat 	:= SuperGetMv("MV_ARREFAT",.F.,"S")== "S"
	lFlexPrev 	:= lEventual .And. !lFixo .And. lPrevFin //Flexível com previsão financeira

	If !IsExced()
		If lLimFis
			nQtaMed*=1+(nLimMed/100)
		EndIf

		If nQuant > 0 .AND. !lRecorre .AND. !lSemiFix .AND. !lFlex .And. !lEventual
			lRet := (nQuant <= nQtaMed)
			If !lRet 
				If ( ( nQuant - nQtaMed ) <= 0.001 ) .AND. !lArrefat
					lRet := .T.
				Else
					Help( ,, "CN121QTDE",, STR0183 + AllTrim(cItem) + " (" + cValToChar(nQuant) + ") " + STR0184 + " (" + cValToChar(nQtaMed) + ").", 1, 0,,,,,, {STR0185} ) //"A quantidade informada para o item " ## "é maior do que a quantidade disponível" ## "Informe uma quantidade válida para o item." 
				EndIF
		  	EndIf
		EndIf

		If lRet .And. lSemiAgr
			lRet := C121CNEAgr(oModel,cField,xValue,nLine)
		EndIf
		
		If lRet .And. (CNE->(ColumnPos('CNE_15ANOS')) > 0 .And. CNE->(ColumnPos('CNE_20ANOS')) > 0 .And. CNE->(ColumnPos('CNE_25ANOS')) > 0)
			lRet := CnrTotItem(oModelCNE:GetValue("CNE_QUANT")*oModelCNE:GetValue("CNE_VLUNIT"))
		EndIf 

		If lRet
			For nX := 1 to oModelCNE:Length()
				oModelCNE:GoLine(nX)
				If !oModelCNE:IsDeleted()
					If oModelCNE:GetLine() == nLine
						nTotCNE += xValue * oModelCNE:GetValue("CNE_VLUNIT")
					Else
						nTotCNE += oModelCNE:GetValue("CNE_VLTOT")
					EndIf
				EndIf
			Next nX
			nTotCNE := Round(nTotCNE,TamSX3("CXN_VLSALD")[2])
			
			lVldEvent := lEventual .And. !lFixo .And. !lPrevFin
			
			//Valida se o total informado nos itens utlrapassa o valor previsto para a medição, considerando o percentual de limite para medição, definido no tipo de contrato/planilha 								
			If !lFlexPrev
				nVlLimit := Cn121LtMed( oModelCXN:GetValue("CXN_VLSALD"), oModelCXN:GetValue("CXN_CONTRA"), oModelCXN:GetValue("CXN_REVISA"), oModelCXN:GetValue("CXN_NUMPLA"), oModelCXN:GetValue("CXN_VLPREV") )	
			Else
				nVlLimit := oModelCXN:GetValue("CXN_VLSALD")
			EndIf
			
			If nTotCNE > nVlLimit .And. !lVldEvent
				lRet := .F.
				oModel:SetErrorMessage( "CNEDETAIL", "CNE_VLTOT", "CNEDETAIL", "CNE_VLTOT", "CNEVLTOT3", STR0186 + cValToChar(nTotCNE) + STR0188 + cValToChar(nVlLimit) + "."  ) //"A soma dos valores informados para os itens ultrapassa o limite previsto para essa medição. Total informado: " ## ". Limite da medição: "
			EndIf
		EndIf
	EndIf
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121SldDis()
Função de inicializador padrão do saldo disponivel para medição.

@author Israel.Escorizza
@since 30/09/2015
@return nRet
/*/
//-------------------------------------------------------------------
Function CN121SldDis()
Local oModel	:= FwModelActive()
Local oModelCND	:= oModel:GetModel("CNDMASTER")
Local oModelCXN	:= oModel:GetModel("CXNDETAIL")
Local cContra	:= oModelCND:GetValue("CND_CONTRA")
Local cRevisa	:= oModelCND:GetValue("CND_REVISA")
Local cNumPla	:= oModelCXN:GetValue("CXN_NUMPLA")
Local cItem		:= CNE->CNE_ITEM
Local lInclui	:= oModel:GetOperation() == MODEL_OPERATION_INSERT
Local nQtdMed	:= 0
Local nQtdBlq 	:= 0
Local nRet		:= 0

If CNE->CNE_EXCEDE <> "1"
	If !lInclui
		CNB->(dbSetOrder(1))
		If CNB->(MsSeek(xFilial('CNB')+cContra+cRevisa+cNumPla+cItem))
			If CN121RetSt('SEMIFIXO',0,cNumPla,cContra)
				nRet := 0
			Else
				nQtdMed := Iif(lInclui,0,CNE->CNE_QUANT)
				nQtdBlq := Cn121QtdBlq(cContra,cRevisa,cNumPla,cItem)
				nRet := CNB->CNB_SLDMED - nQtdBlq	+ nQtdMed
			EndIf
		EndIf
	EndIf
EndIf
Return nRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121VlTab()
Função de gatilho do valor do produto baseado na tabela de preço.

@author Flavio Lopes Rasta
@since 07/12/2015
@return nRet
/*/
//-------------------------------------------------------------------
Function CN121VlTab()
Local oModel 	:= Nil
Local oModelCND := Nil
Local oModelCNE := Nil
Local oModelCXN := Nil

Local lFixo		:= .F.
Local lCompra	:= .F.
Local lAgrup 	:= .F.
Local lModel	:= .F.

Local dDataInic	:= sToD("")

Local cContra 	:= ""
Local cRevisa 	:= ""
Local cPlan		:= ""
Local cClieForn	:= ""
Local cLoja		:= ""
Local cProduto	:= ""
Local cCodTab	:= ""

Local nRet 		:= 0
Local nQtd		:= 0
Local nMoeda	:= 0

If IsInCallStack('CNTA121')
	lModel		:= .T.
	oModel 		:= FwModelActive()
	oModelCND 	:= oModel:GetModel('CNDMASTER')
	oModelCNE 	:= oModel:GetModel('CNEDETAIL')
	oModelCXN 	:= oModel:GetModel('CXNDETAIL')

	dDataInic	:= oModelCND:GetValue('CND_DTINIC')
	cContra 	:= oModelCND:GetValue('CND_CONTRA')
	cRevisa 	:= oModelCND:GetValue('CND_REVISA')
	nMoeda		:= oModelCND:GetValue('CND_MOEDA')

	cPlan		:= oModelCXN:GetValue('CXN_NUMPLA')
	cClieForn	:= oModelCXN:GetValue('CXN_FORCLI')
	cLoja		:= oModelCXN:GetValue('CXN_LOJA')

	cProduto	:= oModelCNE:GetValue('CNE_PRODUT')
	cCodTab		:= oModelCNE:GetValue('CNE_TABPRC')
	nQtd		:= oModelCNE:GetValue('CNE_QUANT')

ElseIf IsInCallStack('CNTA120')
	dDataInic	:= CND->CND_DTINIC
	cContra 	:= CND->CND_CONTRA
	cRevisa 	:= CND->CND_REVISA
	cPlan		:= CND->CND_NUMERO
	cClieForn	:= Iif(!Empty(CND->CND_FORNEC),CND->CND_FORNEC,CND->CND_CLIENT)
	cLoja		:= Iif(!Empty(CND->CND_LJFORN),CND->CND_LJFORN,CND->CND_LOJACL)
	nMoeda		:= CND->CND_MOEDA

	cProduto	:= aCols[IIf(lAuto,n,oGetDados:nAt),aScan(aHeader,{|x| x[2] == "CNE_PRODUT"})]
	cCodTab		:= aCols[IIf(lAuto,n,oGetDados:nAt),aScan(aHeader,{|x| x[2] == "CNE_TABPRC"})]
	nQtd		:= If( M->CNE_QUANT == NIL , CNE->CNE_QUANT , M->CNE_QUANT ) 

EndIf

lFixo	:= Cn300RetSt('FIXO'		,0,cPlan,cContra,,lModel)
lCompra	:= Cn300RetSt('COMPRA'		,0,cPlan,cContra,,lModel)
lAgrup 	:= Cn300RetSt('SEMIAGRUP'	,0,cPlan,cContra,,lModel)

nQtd := Iif(nQtd == 0,1,nQtd)

If Empty(cCodTab)
	If Empty(cCodTab := Cn121SkTbP(oModelCNE))
		cCodTab	:= Posicione("SA1",1,xFilial("SA1")+cClieForn+cLoja,"A1_TABELA")
	EndIf
	oModelCNE:LoadValue('CNE_TABPRC',cCodTab)
EndIf
nRet := MaTabPrVen(cCodTab,cProduto,nQtd,cClieForn,cLoja,nMoeda,dDataInic)

Return nRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121SkTbP
Função para buscar a tabela de preço para itens de medições excedentes

@author Israel.escorizza
@since 14/09/2017
@return cCodTbPr
/*/
//-------------------------------------------------------------------
Function Cn121SkTbP(oModelCNE)
Local cCodTbPr 	:= ""
Local cCodProd	:= oModelCNE:GetValue('CNE_PRODUT')
Local nLine	  	:= oModelCNE:GetLine()
Local nX		:= 1

While Empty(cCodTbPr) .And. nX <= oModelCNE:Length()
	oModelCNE:GoLine(nX)
	If AllTrim(oModelCNE:GetValue('CNE_PRODUT')) == AllTrim(cCodProd)
		cCodTbPr := oModelCNE:GetValue('CNE_TABPRC')
	EndIf
	nX++
End

oModelCNE:GoLine(nLine)
Return cCodTbPr

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121CondG()
Função para tratar condição de execução do gatilho do valor do
produto baseado na tabela de preço.

@author Flavio Lopes Rasta
@since 07/12/2015
@return nRet
/*/
//-------------------------------------------------------------------
Function CN121CondG()
Local oModel 	:= Nil
Local oModelCND	:= Nil
Local oModelCXN := Nil

Local lRet 		:= .F.
Local lFixo		:= .F.
Local lSemiPro	:= .F.
Local lAgrup 	:= .F.
Local lExced	:= .F.
Local lModel	:= .F.

Local cContra 	:= ""
Local cPlan		:= ""
Local cTabPrc	:= ""
Local lTECA930	:= FindFunction("TEC930autG") .AND. TEC930autG()

If IsInCallStack('CNTA121') .OR. lTECA930
	lModel		:= .T.
	oModel		:= FwModelActive()
	cContra 	:= oModel:GetValue('CNDMASTER','CND_CONTRA')
	cPlan		:= oModel:GetValue('CXNDETAIL','CXN_NUMPLA')
	cTabPrc		:= oModel:GetValue('CNEDETAIL','CNE_TABPRC')
	lExced		:= (lExcedMEnc .Or. lExcedNPrv)
ElseIf IsInCallStack('CNTA120') .and. !lMedicao
	cContra 	:= CND->CND_CONTRA
	cPlan		:= CND->CND_NUMERO
	cTabPrc		:= aCols[If(lAuto,n,oGetDados:nAt),aScan(aHeader,{|x| x[2] == "CNE_TABPRC"})]			//CNE->CNE_TABPRC
	lExced		:= aCols[If(lAuto,n,oGetDados:nAt),aScan(aHeader,{|x| x[2] == "CNE_EXCEDE"})] == '1'  	//CNE->CNE_EXCEDE == '1'
EndIF

If !Empty(cTabPrc)
	lFixo		:= Cn300RetSt('FIXO'	 ,0,cPlan,cContra,,lModel)
	lSemiPro	:= Cn300RetSt('SEMIPROD' ,0,cPlan,cContra,,lModel)
	lAgrup 		:= Cn300RetSt('SEMIAGRUP',0,cPlan,cContra,,lModel)

	If (!lFixo .And. !lSemiPro) .Or. lAgrup .Or. lExced
		lRet := .T.
	Endif
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121LimPla()
Função que verifica o percentual limite da planilha, retornando:
.T. para limite dentro do percentual ou
.F. para limite fora do percentual.

@author Israel Escorizza
@since 05/01/2016
@return lRet
/*/
//-------------------------------------------------------------------
Function CN121LimPla(oModel)

Local aArea	 	:= GetArea()
Local aSaveLines:= FWSaveRows()
Local aAreaCNF	:= {}
Local aAreaCNS	:= {}
Local oModelCND := Nil
Local oModelCXN	:= Nil
Local oModelCNE	:= Nil
Local cFilCTR 	:= Iif(Type("cFilCTR")=="U",CN9->CN9_FILCTR,cFilCTR)
Local cMedCpt	:= ""
Local cCtrNum	:= ""
Local cCtrRev	:= ""
Local cPlaNum	:= ""
Local cParcel	:= ""
Local cCronog	:= ""
Local nVlExec	:= 0
Local nTamVlTot	:= TamSX3("CND_VLTOT")[2]
Local nMedLmt 	:= ""
Local nX	    := 0
Local lUpdFrn	:= .F.
Local lMedEve 	:= .F.
Local lRecorre	:= .F.
Local lSemiAgr	:= .F.
Local lEventua	:= .F.
Local lLmtFis 	:= .F.
Local lLmtFin	:= .F.
Local lRet 		:= .T.
Default oModel  := FWModelActive()

oModelCND := oModel:GetModel('CNDMASTER')
oModelCXN := oModel:GetModel('CXNDETAIL')
oModelCNE := oModel:GetModel('CNEDETAIL')

cMedCpt	:= oModelCND:GetValue("CND_COMPET")
cCtrNum	:= oModelCND:GetValue("CND_CONTRA")
cCtrRev	:= oModelCND:GetValue("CND_REVISA")

cPlaNum	:= oModelCXN:GetValue("CXN_NUMPLA")
cParcel := oModelCXN:GetValue("CXN_PARCEL")

cCronog	:= Posicione("CNA",1,xFilial("CNA",cFilCTR)+cCtrNum+cCtrRev+cPlaNum,"CNA_CRONOG")
lUpdFrn	:= oModel:GetOperation() == MODEL_OPERATION_UPDATE .And. oModelCND:GetValue("CND_AUTFRN") == "2"

nMedLmt	:= CN121RetSt("LMTMED",0,cPlaNum,cCtrNum,.T.,oModel)
lMedEve := CN121RetSt("MEDEVE",0,cPlaNum,cCtrNum,.T.,oModel)
lRecorre := CN121RetSt("RECORRENTE",0,cPlaNum,cCtrNum,.T.,oModel)
lSemiAgr := CN121RetSt("SEMIAGRUP",0,cPlaNum,cCtrNum,.T.,oModel)
lEventua := CN121RetSt("EVENTUAL",0,cPlaNum,cCtrNum,.T.,oModel)
lLmtFis := CN121RetSt("LMTFISICO",0,cPlaNum,cCtrNum,.T.,oModel)
lLmtFin	:= CN121RetSt("LMTFINANCEIRO",0,cPlaNum,cCtrNum,.T.,oModel)

//-- Ponto de entrada para informar se deve ou não validar limites da planilha
If Existblock("CN121VPA") .And. !ExecBlock("CN121VPA",.F.,.F.)
	Return .T.
EndIf

If oModelCXN:GetValue("CXN_CHECK") .And. (lLmtFis .Or. lLmtFin)
	
	If !lMedEve .AND. !lRecorre .AND. !lSemiAgr .And. !lEventua
		
		dbSelectArea("CNF")
		
		aAreaCNF := CNF->( GetArea() )
		
		If !Empty(oModelCXN:GetValue("CXN_PARCEL"))
			CNF->(dbSetOrder(3))
			CNF->(MsSeek(xFilial("CNF",cFilCTR)+cCtrNum+cCtrRev+cCronog+cParcel))
		Else
			CNF->(dbSetOrder(2))
			CNF->(MsSeek(xFilial("CNF",cFilCTR)+cCtrNum+cCtrRev+cCronog+cMedCpt))
		EndIf

		If Found()
			
			cParcel := CNF->CNF_PARCEL
			
			If !lLmtFis
				
				//-- Soma o limite de medicao ao saldo da parcela 
				nVlExec := oModelCXN:GetValue("CXN_VLLIQD") - CN120VlExc()
				nVlExec := Round( nVlExec, nTamVlTot )

				If lRet .And. ( nVlExec > Round((CNF->CNF_VLPREV * (1+(nMedLmt/100))) - Iif(lUpdFrn,0,CNF->CNF_VLREAL), nTamVlTot))
					Help("",1,STR0079,,STR0146+cPlaNum+STR0147+CRLF+STR0148,1,1) //- Valor total da planilha | #NUMERO# | não previsto no cronograma. | O mesmo deve ser reestruturado.
					lRet := .F.
				EndIf

			Else
			
				dbSelectArea( "CNS" )
				aAreaCNS := CNS->( GetArea() )
				CNS->( dbSetOrder(1) )
				
				//-- Valida a quantidade medida contra a quantidade prevista no cronograma
				For nX := 1 To oModelCNE:Length()
					
					oModelCNE:GoLine( nX )
					
					If CNS->( dbSeek( xFilial( 'CNS' , cFilCTR ) + cCtrNum + cCtrRev + cCronog + cParcel + oModelCNE:GetValue( 'CNE_ITEM' ) ) )
						
						nLmtQtd	:= CNS->CNS_PRVQTD * ( 1 + ( nMedLmt / 100 ) )
						
						If oModelCNE:GetValue( 'CNE_QUANT' ) > nLmtQtd
							Help( "" , 1 , STR0079 , , STR0149 + oModelCNE:GetValue('CNE_ITEM') + STR0150 , 1 , 1 ) //Item #ITEM# ultrapassou o limite de medição do cronograma físico"
							lRet := .F.
							Exit
						EndIf
					
					EndIf
				
				Next nX
				
				RestArea( aAreaCNS )

			EndIf
			
		EndIf
		
		RestArea( aAreaCNF )
	
	ElseIf lLmtFin .And. !lEventua .And. !lRecorre 		//- Se Limite Financeiro.!lMedEve .AND. !lRecorre .AND. !lSemiAgr .And. !lEventua
		
		CNA->(dbSetOrder(1))
		If 	CNA->(MsSeek(xFilial("CNA",cFilCTR)+cCtrNum+cCtrRev+cPlaNum)) .And. CNA->CNA_SALDO*(1+(nMedLmt/100)) < oModelCXN:GetValue("CXN_VLLIQD") - CN120VlExc() 
			Help("",1,STR0079,,STR0146+cPlaNum+STR0151+CRLF+STR0148,1,1) //- Valor total da planilha | #NUMERO# | ultrapassa o saldo disponivel. | O mesmo deve ser reestruturado.
			lRet := .F.
		EndIf
		
	EndIf

EndIf

FWRestRows(aSaveLines)
RestArea(aArea)

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121AtuRat(nValor)
Função para preenchimento e atualização dos valores em diferentes moedas
na aba de rateio da medição

@author israel.escorizza
@since 26/02/2016
@return
/*/
//-------------------------------------------------------------------
Function Cn121AtuRat(nValor,nPerc)
Local aArea		:= GetArea()
Local aRows		:= FWSaveRows()
Local oModel 	:= FwModelActive()
Local oModelCNE	:= oModel:GetModel('CNEDETAIL')
Local oModelCNZ := oModel:GetModel('CNZDETAIL')
Local nX		:= 0
Local nVlrRat	:= 0
Local nVlrPer	:= 0
Local aCampos	:=	{{'CNZDETAIL',{'CNZ_VALOR1','CNZ_VALOR2','CNZ_VALOR3','CNZ_VALOR4','CNZ_VALOR5'}}}
Local lDelLn	:= .F.

Default nValor	:= oModelCNE:GetValue('CNE_VLTOT')

MtBCMod(oModel,aCampos,{||.T.},'2')
If nPerc == Nil
	For nX := 1 To oModelCNZ:Length()
		oModelCNZ:GoLine(nX)

		If (lDelLn := oModelCNZ:IsDeleted())
			oModelCNZ:UnDeleteLine()
		EndIf

		nVlrPer := oModelCNZ:GetValue('CNZ_PERC')
		If !Empty(nVlrPer)
			nVlrRat := nValor * (nVlrPer / 100)
			oModelCNZ:SetValue("CNZ_VALOR1",nVlrRat)
			oModelCNZ:SetValue("CNZ_VALOR2",xMoeda(nVlrRat,1,2,dDatabase))
			oModelCNZ:SetValue("CNZ_VALOR3",xMoeda(nVlrRat,1,3,dDatabase))
			oModelCNZ:SetValue("CNZ_VALOR4",xMoeda(nVlrRat,1,4,dDatabase))
			oModelCNZ:SetValue("CNZ_VALOR5",xMoeda(nVlrRat,1,5,dDatabase))
		EndIf

		If lDelLn
			oModelCNZ:DeleteLine()
			oModelCNZ:GoLine(nX)
		EndIf

	Next nX
Else
	nVlrRat := nValor * (nPerc / 100)
	oModelCNZ:SetValue("CNZ_VALOR1",nVlrRat)
	oModelCNZ:SetValue("CNZ_VALOR2",xMoeda(nVlrRat,1,2,dDatabase))
	oModelCNZ:SetValue("CNZ_VALOR3",xMoeda(nVlrRat,1,3,dDatabase))
	oModelCNZ:SetValue("CNZ_VALOR4",xMoeda(nVlrRat,1,4,dDatabase))
	oModelCNZ:SetValue("CNZ_VALOR5",xMoeda(nVlrRat,1,5,dDatabase))
EndIf
MtBCMod(oModel,aCampos,{||.F.},'2')

FWRestRows(aRows)
RestArea(aArea)
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121AtuTes()
Função para preenchimento do campo virtual CNE_TES de acordo com produto
informado.

@author israel.escorizza
@since 26/02/2016
@return
/*/
//-------------------------------------------------------------------
Function CN121AtuTes()
Local aArea		:= GetArea()
Local aSaveLines:= FwSaveRows()
Local oModel 	:= FwModelActive()
Local oModelCNE := oModel:GetModel('CNEDETAIL')
Local cContra	:= oModel:GetValue('CNDMASTER','CND_CONTRA')
Local cPlan		:= oModel:GetValue('CXNDETAIL','CXN_NUMPLA')
Local cProd		:= oModelCNE:GetValue('CNE_PRODUT')
Local cValor	:= ""

If !CN121RetSt('FIXO',,cPlan,cContra)
	If CN121RetSt('COMPRA',,,cContra)
		cValor := 	GctGatTes(cProd,.T.)
	Else
		cValor := 	GctGatTes(cProd,.F.)
	EndIf
EndIf

FWRestRows(aSaveLines)
RestArea(aArea)

Return AllTrim(cValor)

//-------------------------------------------------------------------
/*/{Protheus.doc} A121VldGat(cDomin,cCDomin,cSeq)
Função para validação de gatilho para impedir loops
@author israel.escorizza
@since 25/04/2016
@return
/*/
//-------------------------------------------------------------------
Function A121VldGat(cDomin,cCDomin,cSeq)
Local lRet 		:= .F.
Local lCanSet	:= .F.
Local lFixo 	:= .F.
Local lCompra 	:= .F.
Local lCnta120	:= IsInCallStack('CNTA120')

Local oModel	:= Nil
Local oModelCNE	:= Nil
Local cProdut	:= ""
Local nQtdOri	:= 0
Local nQtdSol	:= 0
Local nQuant	:= 0
Local nPerc		:= 0
Local nVUnOri	:= 0
Local nVlUnit	:= 0
Local nVlTot	:= 0
Local nPDesc	:= 0
Local lnotTEC930 := IIF( FindFunction("TEC930Test") .AND. TEC930Test() , .F. , !lMedicao)

Default cDomin	:= ""
Default cCDomin	:= ""
Default cSeq 	:= ""

If lCnta120 .And. lnotTEC930
	If INCLUI
		lFixo 	:= Cn300RetSt('FIXO',	0,cPlan,cContra,cFilCtr,.F.)
		lCompra := Cn300RetSt('COMPRA',	0,cPlan,cContra,cFilCtr,.F.)
	Else
		lFixo 	:= Cn300RetSt('FIXO',	0,CND->CND_NUMERO,CND->CND_CONTRA,CND->CND_FILCTR,.F.)
		lCompra := Cn300RetSt('COMPRA',	0,CND->CND_NUMERO,CND->CND_CONTRA,CND->CND_FILCTR,.F.)
	EndIf

	DO CASE
		CASE cDomin == "CNE_PRODUT" .And. cCDomin == "CNTA120" .And. !lFixo
			lRet := .T.

		CASE cDomin == "CNE_QUANT"
			If cCDomin == "CNE_PERC" .And. lFixo .And. !Empty(ACOLS[N, ASCAN(AHEADER,{|X| X[2] == "CNE_QTDSOL"})])	//-SEQ001
				lRet := .T.
			EndIf

			If cCDomin == "CNE_VLTOT"								//-SEQ002
				lRet := .T.
			EndIf

			If cCDomin == "CNE_VLDESC" .And. lCompra	//-SEQ003
				lRet := .T.
			EndIf

		CASE cDomin == "CNE_PERC"
			If cCDomin == "CNE_QUANT" .And. !A121Servico() //-SEQ001
				lRet := .T.
			EndIf

			If cCDomin == "CNE_VLTOT"  .And. !A121Servico() .And. cSeq == "2" 			 					//-SEQ002
				lRet := .T.
			EndIf

			If cCDomin == "CNE_VLDESC" .And. CN121RetSt("COMPRA")	//-SEQ003
				lRet := .T.
			EndIf

			If 	lFixo .And. A121Servico()
				If cCDomin == "CNE_QTDORI"								//-SEQ004
					lRet := .T.
				EndIf

				If cCDomin == "CNE_VLTOT" .And. cSeq == "5" 												//-SEQ005
					lRet := .T.
				EndIf

				If cCDomin == "CNE_VLUNIT"								//-SEQ006
					lRet := .T.
				EndIf
			EndIf

		CASE cDomin == "CNE_VLTOT"
			If cCDomin == "CNE_QUANT" .And. !A121Servico()			//-SEQ001
				lRet := .T.
			EndIf

			If cCDomin == "CNE_VLDESC" .And. CN121RetSt("COMPRA")   //-SEQ002
				lRet := .T.
			EndIf

			If cCDomin == "CNE_PERC" .And. lFixo .And. !A121Servico()	//-SEQ003
				nPerc := aScan(aHeader,{|x| AllTrim(x[2])=="CNE_PERC"})
				nQtd := aScan(aHeader,{|x| AllTrim(x[2])=="CNE_QUANT"})
				nQtdSol := aScan(aHeader,{|x| AllTrim(x[2])=="CNE_QTDSOL"})

				aCols[n,nPerc] := (aCols[n,nQtd]/aCols[n,nQtdSol]) * 100
				lRet := .F.
			EndIf

			If lFixo .And. A121Servico()
				If cCDomin == "CNE_QTDORI"								//-SEQ004
					lRet := .T.
				EndIf

				If cCDomin == "CNE_VLUNIT"								//-SEQ006
					lRet := .T.
				EndIf
			EndIf

		CASE cDomin == "CNE_VLUNIT"
			If cCDomin	== "CNE_VLTOT"
				If cSeq == "1"
					If !A121Servico()	//- SEQ001
						lRet := .T.
					EndIf
				ElseIf cSeq == "2"
					If lFixo .And. A121Servico()	//- SEQ002
						lRet := .T.
					EndIf
				EndIf
			EndIf

			If cCDomin == "CNE_QTDORI" .And. lFixo .And. A121Servico() .And. CN130GATCNE(3)//- SEQ003
				lRet := .T.
			EndIf

			If cCDomin == "CNE_PERC" .And. lFixo .And. A121Servico() .And. CN130GATCNE(4) 	 //- SEQ004
				lRet := .T.
			EndIf

		CASE cDomin == "CNE_PDESC"
			lRet := .T.

		ENDCASE
Else
	oModel		:= FWModelActive()
	oModelCNE	:= oModel:GetModel("CNEDETAIL")
	cProdut		:= oModelCNE:GetValue("CNE_PRODUT")
	nQtdOri		:= oModelCNE:GetValue("CNE_QTDORI")
	nQtdSol		:= oModelCNE:GetValue("CNE_QTDSOL")
	nQuant		:= oModelCNE:GetValue("CNE_QUANT")
	nPerc		:= oModelCNE:GetValue("CNE_PERC")
	nVUnOri		:= oModelCNE:GetValue("CNE_VUNORI")
	nVlUnit		:= oModelCNE:GetValue("CNE_VLUNIT")
	nVlTot		:= oModelCNE:GetValue("CNE_VLTOT")
	nPDesc		:= oModelCNE:GetValue("CNE_PDESC")

	cContra		:= oModel:GetValue('CNDMASTER','CND_CONTRA')
	cNumPla		:= oModel:GetValue('CXNDETAIL','CXN_NUMPLA')
	cFilCtr		:= oModel:GetValue('CNDMASTER','CND_FILCTR')

	lFixo 	:= Cn300RetSt('FIXO',	0,cNumPla,cContra,cFilCtr,.T.)
	lCompra := Cn300RetSt('COMPRA',	0,cNumPla,cContra,cFilCtr,.T.)

	DO CASE
		CASE cDomin == "CNE_PRODUT" .And. cCDomin == "CNTA121" .And. !lFixo
			lRet := .T.

		CASE cDomin == "CNE_QUANT"
			If cCDomin == "CNE_PERC" .And. lFixo		//-SEQ001
				oModelCNE:LoadValue(cCDomin,NoRound(nQuant / nQtdSol * 100,TAMSX3('CNE_PERC')[2]))
			EndIf

			If cCDomin == "CNE_VLTOT"								//-SEQ002
				lCanSet := oModelCNE:CanSetValue('CNE_VLTOT')
				oModelCNE:GetStruct():SetProperty('CNE_VLTOT',MODEL_FIELD_WHEN,{||.T.})
				oModelCNE:SetValue(cCDomin,nVlUnit * nQuant)
				oModelCNE:GetStruct():SetProperty('CNE_VLTOT',MODEL_FIELD_WHEN,{||lCanSet})
			EndIf

			If cCDomin == "CNE_VLDESC" .And. lCompra	//-SEQ003
				oModelCNE:LoadValue(cCDomin,NoRound((nVlTot * nPDesc /100),TamSX3('CNE_VLDESC')[2]))
			EndIf

		CASE cDomin == "CNE_PERC"
			If cCDomin == "CNE_QUANT" .And. !A121Servico() //-SEQ001
				oModelCNE:SetValue(cCDomin,NoRound((nQtdSol * nPerc)/100,TamSX3("CNE_QUANT")[2]))
			EndIf

			If cCDomin == "CNE_VLTOT"  .And. !A121Servico() .And. oModelCNE:GetValue('CNE_VLTOT') != (nVlUnit * nQuant)	//-SEQ002
				oModelCNE:SetValue(cCDomin,nVlUnit * nQuant)
			EndIf

			If cCDomin == "CNE_VLDESC" .And. lCompra	//-SEQ003
				oModelCNE:LoadValue(cCDomin,Round(nVlTot * nPDesc / 100,TamSx3("CNE_VLDESC")[2]))
			EndIf

			If 	lFixo .And. A121Servico()
				If cCDomin == "CNE_QTDORI"								//-SEQ004
					oModelCNE:LoadValue(cCDomin,nQtdSol * nPerc / 100)
				EndIf

				If cCDomin == "CNE_VLTOT"								//-SEQ005
					oModelCNE:LoadValue(cCDomin,nVUnOri * nQtdOri)
				EndIf

				If cCDomin == "CNE_VLUNIT"								//-SEQ006
					oModelCNE:LoadValue(cCDomin,nVlTot)
				EndIf
			EndIf

		CASE cDomin == "CNE_VLTOT"
			If cCDomin == "CNE_QUANT" .And. !A121Servico()			//-SEQ001
				oModelCNE:LoadValue(cCDomin,Round( nVlTot / nVlUnit, TamSX3("CNE_QUANT")[2]))
				oModelCNE:LoadValue('CNE_PERC',NoRound(oModelCNE:GetValue('CNE_QUANT') / nQtdSol * 100,TAMSX3('CNE_PERC')[2]))
			EndIf

			If cCDomin == "CNE_VLDESC" .And. lCompra   //-SEQ002
				oModelCNE:LoadValue(cCDomin,Round( nVlTot * nPDesc / 100, TamSx3("CNE_VLDESC")[2]))
			EndIf

			If cCDomin == "CNE_PERC" .And. lFixo .And. !A121Servico()	//-SEQ003
				oModelCNE:LoadValue(cCDomin,NoRound(nQuant/nQtdSol * 100,TAMSX3('CNE_PERC')[2]))
			EndIf

			If lFixo .And. A121Servico()
				If cCDomin == "CNE_QTDORI"								//-SEQ004
					oModelCNE:LoadValue(cCDomin,nVlTot / nVUnOri)
				EndIf

				If cCDomin == "CNE_PERC"									//-SEQ005
					oModelCNE:LoadValue(cCDomin,nQtdOri * 100)
				EndIf

				If cCDomin == "CNE_VLUNIT"								//-SEQ006
					oModelCNE:LoadValue(cCDomin,nVlTot)
				EndIf
			EndIf

		CASE cDomin == "CNE_VLUNIT"
			If cCDomin	== "CNE_VLTOT"
				If lFixo .And. A121Servico()	//- SEQ002
					oModelCNE:SetValue(cCDomin,FwFldGet('CNE_VLUNIT'))
				Else
					oModelCNE:SetValue(cCDomin,FwFldGet('CNE_VLUNIT') * FwFldGet('CNE_QUANT'))
				EndIf
			EndIf

			If cCDomin == "CNE_QTDORI" .And. lFixo .And. !A121Servico() //- SEQ003
				oModelCNE:LoadValue(cCDomin,FwFldGet('CNE_VLTOT')/FwFldGet('CNE_VUNORI'))
			EndIf

			If cCDomin == "CNE_PERC" .And. lFixo .And. !A121Servico()	 //- SEQ004
				oModelCNE:LoadValue(cCDomin,(FwFldGet('CNE_QTDORI')*100) / FwFldGet('CNE_QTDSOL'))
			EndIf
	ENDCASE
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} A121QtdSrv(cContra,cRevisa,cNumPla,cItem)
Função que retorna a quantidade de itens de serviço a ser medido de acordo com a
competencia da medição em comparação com medições já realizadas anteriormente.
@author israel.escorizza
@since 25/04/2016
@return
/*/
//-------------------------------------------------------------------
Function A121QtdSrv(cContra,cRevisa,cNumPla,cItem,cCompet)
Local aArea		:= GetArea()
Local aSaveLines:= FwSaveRows()
Local oModel	:= FwModelActive()
Local cAliasCNE	:= GetNextAlias()
Local cQuery	:= ""
Local nRet		:= 0
Local cNumpar	:= ""
Local cFilCtr	:= ""

Default cContra	:= ""
Default cRevisa	:= ""
Default cCompet	:= ""
Default cNumPla	:= ""
Default cItem	:= ""

If oModel:IsActive() .And. oModel:GetId() == "CNTA121"

	cContra 	:= Iif(Empty(cContra),	oModel:GetValue('CNDMASTER','CND_CONTRA'),cContra)
	cRevisa 	:= Iif(Empty(cRevisa),	oModel:GetValue('CNDMASTER','CND_REVISA'),cRevisa)
	cCompet 	:= Iif(Empty(cCompet),	oModel:GetValue('CNDMASTER','CND_COMPET'),cCompet)
	cNumPla 	:= Iif(Empty(cNumPla),	oModel:GetValue('CXNDETAIL','CXN_NUMPLA'),cNumPla)
	cNumpar		:= oModel:GetValue('CXNDETAIL','CXN_PARCEL')
	cItem 		:= Iif(Empty(cItem),		oModel:GetValue('CNEDETAIL','CNE_ITEM'),	cItem	)	
	cFilCtr		:= oModel:GetValue('CNDMASTER','CND_FILCTR')

	cQuery	+= 	" SELECT COUNT(*) AS CNE_QTDREG "
	cQuery	+= 	" FROM "
	cQuery += 	RetSQLName("CNE") + " CNE "

	cQuery	+= 	" INNER JOIN "
	cQuery += 	RetSQLName("CND") + " CND "
	cQuery	+=	" ON "
	cQuery	+=	" CNE.CNE_FILIAL = CND.CND_FILIAL AND "
	cQuery	+=	" CNE.CNE_CONTRA = CND.CND_CONTRA AND "
	cQuery	+=	" CNE.CNE_REVISA = CND.CND_REVISA AND "
	cQuery	+=	" CNE.CNE_NUMMED = CND.CND_NUMMED "
	
	cQuery	+= 	" INNER JOIN "
	cQuery += 	RetSQLName("CXN") + " CXN "
	cQuery	+=	" ON "	
	cQuery	+=	" CXN.CXN_FILIAL = CND.CND_FILIAL AND "
	cQuery	+=	" CXN.CXN_CONTRA = CND.CND_CONTRA AND "
	cQuery	+=	" CXN.CXN_REVISA = CND.CND_REVISA AND "  
	cQuery	+=	" CXN.CXN_NUMMED = CND.CND_NUMMED AND "
	cQuery	+=	" CXN.CXN_PARCEL = '"+cNumpar+"' "	
	
	cQuery	+= 	" WHERE "
	cQuery += 	" CND.CND_FILIAL = '" + xFilial("CND", cFilCtr) + "' AND "
	cQuery += 	" CND.CND_CONTRA = '" + cContra + "' AND "
	cQuery += 	" CND.CND_REVISA = '" + cRevisa + "' AND "
	cQuery += 	" CND.CND_COMPET = '" + cCompet + "' AND "
	cQuery += 	" CNE.CNE_NUMERO = '" + cNumPla + "' AND "
	cQuery += 	" CNE.CNE_ITEM   = '" + cItem   + "' AND "
	cQuery +=	" CND.D_E_L_E_T_ = ' ' AND "
	cQuery +=	" CNE.D_E_L_E_T_ = ' ' "

	cQuery  := ChangeQuery( cQuery )
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery), cAliasCNE,.T.,.T.)

	If (cAliasCNE)->CNE_QTDREG == 0
		nRet := 1
	EndIf

	(cAliasCNE)->(dbCloseArea())
EndIf

FWRestRows(aSaveLines)
RestArea(aArea)
Return nRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121VldRt(oModelCNE)
Função que valida rateio dos itens da planilha posicionada.
@author israel.escorizza
@since 23/05/2016
@return lRet
/*/
//-------------------------------------------------------------------
Function CN121VldRt(oModelCNE)
Local aArea		:= GetArea()
Local aSaveLines:= FwSaveRows()
Local oModel	:= Nil
Local lRet 		:= .T.
Local nX		:= 1

Default oModelCNE := Nil

If oModelCNE == Nil
	oModel := FwModelActive()
	If oModel:IsActive() .And. oModel:GetId() == 'CNTA121'
		oModelCNE	:= oModel:GetModel('CNEDETAIL')
	EndIf
EndIf

While lRet .And. nX <= oModelCNE:Length()
	oModelCNE:GoLine(nX)
	If !oModelCNE:IsDeleted()
		lRet := CN300VldRat(.F.)
	EndIf
	nX++
EndDo

FWRestRows(aSaveLines)
RestArea(aArea)

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121PdNum()
Função que retorna numero do pedido da SC7 (Campo não utilizado/Browse = N)
Ação deve ser realizada por query pois não traz no posicionamento.

@author israel.escorizza
@since 24/08/2016
@return cRet
/*/
//-------------------------------------------------------------------
Function Cn121PdNum()
Local aAreaSC7	:= SC7->(GetArea())
Local cAliasTemp:= GetNextAlias()
Local cRet 		:= ""

//- Query Baseada no posicionamamento
BeginSQL Alias cAliasTemp
	SELECT C7_NUM
		FROM %Table:SC7% SC7
	WHERE
		SC7.C7_FILIAL 	= %xFilial:SC7% 		AND
		SC7.C7_CONTRA 	= %Exp:SC7->C7_CONTRA%	AND
		SC7.C7_CONTREV	= %Exp:SC7->C7_CONTREV%	AND
		SC7.C7_MEDICAO	= %Exp:SC7->C7_MEDICAO%	AND
		SC7.C7_PLANILH	= %Exp:SC7->C7_PLANILH%	AND
		SC7.C7_PRODUTO	= %Exp:SC7->C7_PRODUTO%	AND
		SC7.C7_TOTAL	= %Exp:SC7->C7_TOTAL%	AND
		SC7.C7_ITEM 	= %Exp:SC7->C7_ITEM%	AND
		SC7.C7_SEQUEN	= %Exp:SC7->C7_SEQUEN%	AND
		SC7.C7_QUANT	= %Exp:SC7->C7_QUANT%	AND
		SC7.%NotDel%
EndSQL

If (cAliasTemp)->(!Eof())
	cRet := (cAliasTemp)->C7_NUM
EndIf

(cAliasTemp)->(dbClosearea())

RestArea(aAreaSC7)
Return cRet

//-------------------------------------------------------------------
/*/{Protheus.doc} C121AtuCXJ
Função que atualiza numero do pedido/titulo na CXJ após inclusão em casos que a
numeração solicitada não tenha sido valida.

@author israel.escorizza
@since 08/11/2016
@return Nil
/*/
//-------------------------------------------------------------------
Function C121AtuCXJ(oModel,cAtuCpo,cNumDoc,aDocs)
Local aSaveLines:= FwSaveRows()
Local oModelCXN	:= Nil
Local oModelCXJ	:= Nil
Local cNumOri	:= ""
Local cPlan		:= ""
Local nLinCXJ	:= 0
Local nX	:= 0

Default oModel	:= FwModelActive()
Default cAtuCpo := ""
Default cNumDoc	:= ""
Default	aDocs	:= {}

If Len(aDocs) > 0

	oModelCXN	:=	oModel:GetModel('CXNDETAIL')
	oModelCXJ	:= 	oModel:GetModel('CXJDETAIL')

	Do Case

		Case aDocs[1] == '1'	//- Tratativas para pedido de compra (SC7)
			
			cNumOri := aDocs[2	,aScan(aDocs[2],{|x| x[1] = 'C7_NUM'}),2]
			cPlan := aDocs[3,1,aScan(aDocs[3,1],{|x| x[1] = 'C7_PLANILH'}),2]
			
			If cNumDoc != cNumOri
				oModelCXN:GoLine(MtFindMVC(oModelCXN,{{'CXN_NUMPLA',cPlan}}))
				While (nLinCXJ := MtFindMVC(oModelCXJ,{{cAtuCpo,cNumOri}})) > 0
					oModelCXJ:GoLine(nLinCXJ)
					oModelCXJ:LoadValue(cAtuCpo,cNumDoc)
				EndDo
			EndIf
		
		Case aDocs[1] == '2'	//- Tratativas para pedido de venda (SC5)
			
			For nX := 1 To Len( aDocs[3] )
				
				cPlan := aDocs[ 2 , aScan( aDocs[2], {|x| x[1] = 'C5_MDPLANI'} ) , 2 ]
				cItem := aDocs[ 3 , nX , aScan( aDocs[3,1] , {|x| x[1] = 'C6_ITEMED'} ) , 2 ]
				
				oModelCXN:GoLine( MtFindMVC( oModelCXN , { { 'CXN_NUMPLA' , cPlan } } ) )
				oModelCXJ:SeekLine( { { "CXJ_NUMPLA" , cPlan } , { "CXJ_ITEMPL" , cItem } } )
				oModelCXJ:LoadValue( cAtuCpo , cNumDoc )
			
			Next nX
			
	EndCase
	
EndIf

FWRestRows(aSaveLines)

Return .T.

/*/{Protheus.doc} AtuCNEPed
	Atualiza todos os registros do submodelo da CNE com o numero do pedido
	em <cNumPed>
@author PHILIPE.POMPEU
@since 29/01/2019
@param oModelCNE, object FWFormGrid, submodelo da tabela CNE
@param aDocumento, array, Lista de itens do Pedido
@param cNumPed, characters, Numero do Pedido
/*/
Static Function AtuCNEPed(oModel,aPedido,cNumPed)
	Local cChaveMdl		:= ""
	Local cChaveArr		:= ""	
	Local nK	:= 0
	Local nI	:= 0	
	Local aItemPed := {}
	Local oModelCXN:= Nil
	Local oModelCNE:= Nil
	Local lCanUpdCNE := .F.
	Default cNumPed := SC7->C7_NUM
		
	oModelCXN := oModel:GetModel('CXNDETAIL')
	oModelCNE := oModel:GetModel('CNEDETAIL')
	
	For nK := 1 To Len(aPedido)
		aItemPed := aPedido[nK]
				
		For nI:= 1 To oModelCXN:Length()
			oModelCXN:GoLine(nI)
			cChaveMdl	:= oModelCXN:GetValue("CXN_FILIAL") + oModelCXN:GetValue("CXN_CONTRA") 
			cChaveMdl	+= oModelCXN:GetValue("CXN_REVISA") + oModelCXN:GetValue("CXN_NUMPLA")			
			cChaveArr	:= xFilial("CNE") + aItemPed[20,2] + aItemPed[21,2] + aItemPed[22,2]
			If cChaveMdl == cChaveArr
				Exit
			EndIf
		Next nI
	
		For nI := 1 To oModelCNE:Length()
			oModelCNE:GoLine(nI)
			cChaveMdl := oModelCNE:GetValue("CNE_FILIAL") + oModelCNE:GetValue("CNE_CONTRA")
			cChaveMdl += oModelCNE:GetValue("CNE_REVISA") + oModelCNE:GetValue("CNE_NUMERO")
			cChaveMdl += oModelCNE:GetValue("CNE_NUMMED") + oModelCNE:GetValue("CNE_ITEM")
						
			cChaveArr := xFilial("CNE") + aItemPed[20,2] + aItemPed[21,2] + aItemPed[22,2] + aItemPed[23,2] + aItemPed[14,2] 
			If cChaveMdl == cChaveArr
				//Verifica se a linha de CNE pode ser alterada
				lCanUpdCNE := oModelCNE:CanUpdateLine()
				
				//Se não puder alterar a CNE, então libera a grid para alteração
				If !lCanUpdCNE
					CNTA300BlMd(oModel:GetModel('CNEDETAIL'),.T.,.T.)
				EndIF
				
				oModelCNE:LoadValue("CNE_PEDIDO", cNumPed)
				
				//Se não podia alterar, então volta os bloqueios que haviam na grid
				If !lCanUpdCNE
					CNTA300BlMd(oModel:GetModel('CNEDETAIL'),.T.)
				EndIF
				
				Exit
			EndIf
		Next nI
	Next nK
Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121VFoCl(lCompra,cForCli,cCodLoj)
Posiciona no cadastro do cliente/fornecedor e abre o cadastro para visualização

@since 22/11/2016
@version P12
@return lRet
/*/
//-------------------------------------------------------------------
Function CN121VFoCl(lCompra,cForCli,cCodLoja,cFilCtr)
Local aArea			:= 	GetArea()
Local aSaveLines	:= 	FwSaveRows()

//- Variaveis para compatibilização com chamadas de funções MATA020 e MATA030
Private lPyme		:= .F.
Private lTMSOPdg	:= .F.
Private cCadastro	:= ""

Default lCompra 	:= 	CN121RetSt("COMPRA",,,CND->CND_CONTRA,.F.)
Default cForCli		:= 	""
Default cCodLoja	:= 	""
Default cFilCtr		:=	CND->CND_FILCTR

If lCompra
	//Mata020 - Cadastro de Fornecedores (A2_COD + A2_LOJA)
	dbSelectArea('SA2')
	If SA2->(MsSeek(xFilial('SA2',cFilCtr)+cForCli+cCodLoja))
		cCadastro := STR0152 //- Fornecedor
		A020Visual('SA2',SA2->(Recno()),3)
	EndIf
Else
	//Mata030 - Cadastro de Clientes (A1_COD + A1_LOJA)
	dbSelectArea('SA1')
	If SA1->(MsSeek(xFilial('SA1',cFilCtr)+cForCli+cCodLoja))
		cCadastro := STR0153 //- Cliente
		A030Visual('SA1',SA1->(Recno()),3)
	EndIf
EndIf

FWRestRows(aSaveLines)
RestArea(aArea)
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121CndPre(oFieldModel, cAction, cIDField, xValue)
Função bPre dos campos CND

@author israel.escorizza
@since 16/12/2016
@return
/*/
//-------------------------------------------------------------------
Static Function CN121CNDPre(oFldModel, cAction, cField, xValue)
Local oModel := oFldModel:GetModel()
CNTA300BlMd(oModel:GetModel('CXNDETAIL'),.F.)
Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121VldVlr(oModel)
@author israel.escorizza
@since 16/12/2016
@return
/*/
//-------------------------------------------------------------------
Function Cn121VldVlr(oModel)
Local oModelCNE	:= Nil
Local oModelCXN	:= Nil
Local lPrevFin	:= .F.
Local nVlrTot	:= 0
Local nVlrPrev	:= 0
Local nX

Default oModel 	:= FWModelActive()

oModelCXN	:= oModel:GetModel('CXNDETAIL')
oModelCNE	:= oModel:GetModel('CNEDETAIL')
lPrevFin	:= CN121RetSt('PREVFINANC')
nVlrPrev 	:= (CNB->CNB_VLUNIT * oModelCNE:GetValue('CNE_QUANT') /CNA->CNA_VLTOT) * CNF->CNF_VLPREV

If lPrevFin .And. oModelCNE:GetValue('CNE_VLTOT') != nVlrPrev .AND. TAMSX3('CNE_QUANT')[2] <= 4
	For nX := 5 To 10
		nVlrTot += Round(CNB->CNB_VLTOT/CNA->CNA_VLTOT,nX) * CNF->CNF_VLPREV
	Next nX
	nVlrTot := nVlrTot / 6
	If Round(nVlrTot,TAMSX3('CNF_VLPREV')[2]) == nVlrPrev
		oModelCXN:GetStruct():SetProperty('CXN_VLLIQD',MODEL_FIELD_WHEN,{||.T.})
		oModelCXN:SetValue('CXN_VLLIQD',oModelCXN:GetValue('CXN_VLLIQD') - oModelCNE:GetValue('CNE_VLTOT') + nVlrPrev)
		oModelCXN:GetStruct():SetProperty('CXN_VLLIQD',MODEL_FIELD_WHEN,{||.F.})
		oModelCNE:LoadValue('CNE_QUANT',NoRound(nVlrPrev/CNB->CNB_VLUNIT,TAMSX3('CNE_QUANT')[2]))
		oModelCNE:LoadValue('CNE_PERC',Round(oModelCNE:GetValue('CNE_QUANT')/oModelCNE:GetValue('CNE_QTDSOL')*100,TAMSX3('CNE_PERC')[2]))
		oModelCNE:LoadValue('CNE_VLTOT',nVlrPrev)
	EndIf
EndIf
Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121VFoCl(lCompra,cForCli,cCodLoj)
Selecao do adiantamenentos do modulo SIGAGCT

@since 22/11/2016
@version P12
@return lRet
/*/
//-------------------------------------------------------------------
Function CN121SeAdi(oModel)
Local aArea		:= GetArea()
Local oModelCND	:= oModel:GetModel('CNDMASTER')
Local oModelCXN	:= oModel:GetModel('CXNDETAIL')

Local cContra	:= oModelCND:GetValue("CND_CONTRA")
Local cTipRev	:= oModelCND:GetValue("CND_REVISA")
Local cCompet	:= oModelCND:GetValue("CND_COMPET")
Local cNumMed	:= oModelCND:GetValue("CND_NUMMED")
Local cNumPla	:= oModelCXN:GetValue("CXN_NUMPLA")

Local lRet		:= .T.

Local aColsCpos	:= {}
Local aColsAux	:= {}
Local aCpos		:= {}
Local aHeadCpos	:= {}

Local cQuery	:= ""
Local cAliasQry	:= ""

Local nVlrAdi	:= 0
Local nVlrCom	:= 0
Local nOpca		:= 0
Local nX		:= 0
Local nY		:= 0
Local nPla		:= 1
Local nZ		:= 0
Local nH		:= 0

Local oBold		:= Nil
Local oBut1		:= Nil
Local oBut2		:= Nil
Local oDlgMult	:= Nil

oModelCXN:GetStruct():SetProperty('CXN_VLRADI',MODEL_FIELD_WHEN,{||.T.})

If !Empty(cContra) .And. !Empty(cCompet)

	CN9->( dbSetOrder(1) )
	CN9->( dbSeek(xFilial("CN9",cFilCTR) + cContra + cTipRev))

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica os adiantamentos do Contrato        ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If oModelCXN:GetValue("CXN_CHECK")
		cAliasQry := GetNextAlias()
		cQuery := "SELECT CNX_FILIAL, CNX_CONTRA, CNX_NUMERO, CNX_DTADT, CNX_VLADT, CNX_NUMMED, CNX_SALDO + ISNULL(CZY.CZY_VALOR, 0) CNX_SLDATU ,CNX_SALDO, ISNULL(CZY.CZY_VALOR, 0) CNX_VLCOMP"
		cQuery += "  FROM "+RetSqlName("CNX")+" CNX "
		cQuery += "  LEFT JOIN " +  RetSqlName("CZY") +  " CZY ON  CZY.CZY_FILIAL = CNX.CNX_FILIAL AND CZY.CZY_CONTRA =  CNX.CNX_CONTRA  AND CZY.CZY_NUMERO = CNX.CNX_NUMERO  AND CZY.D_E_L_E_T_=' ' "
		cQuery += "  AND CZY.CZY_NUMMED = '" +cNumMed+ "'"
		cQuery += "  AND CZY.CZY_NUMPLA = '" +cNumPla+ "'"
		cQuery += " WHERE CNX_FILIAL ='"+xFilial("CNX",cFilCTR)+"'"
		cQuery += "   AND CNX_CONTRA ='"+cContra+ "'"

		//Verifica se contrato é de compra ou venda
		If Cn300RetSt('COMPRA',,,cContra,,.F.)
			cQuery += "AND CNX_FORNEC = '"+oModelCXN:GetValue("CXN_FORCLI")+"'"
			cQuery += "AND CNX_LJFORN = '"+oModelCXN:GetValue("CXN_LOJA")+"'"
		Else
			cQuery += "AND CNX_CLIENT = '"+oModelCXN:GetValue("CXN_FORCLI")+"'"
			cQuery += "AND CNX_LOJACL = '"+oModelCXN:GetValue("CXN_LOJA")+"'"
		EndIf

		cQuery += " AND CNX.D_E_L_E_T_=' ' "
		cQuery += " ORDER BY CNX_DTADT "

		cQuery := ChangeQuery( cQuery )
		dbUseArea( .T., "TOPCONN", TcGenQry( ,, cQuery ), cAliasQry, .F., .T. )

		TCSetField(cAliasQry,"CNX_DTADT","D",08,0)
		TCSetField(cAliasQry,"CNX_VLADT","N",TamSX3("CNX_VLADT")[1],TamSX3("CNX_VLADT")[2])
	Else
		lRet := .F.
	     Help("",1,"C121CHECKAD",,STR0117,1,1)//"Planilha posicionada não foi marcada, marque a mesma para mostrar os adiatamentos do fornecedor desta planilha!"
	EndIf

	If  lRet .And. (cAliasQry )->( Eof())
	     lRet := .F.
	     Help("",1,"CN121NOADIA",,STR0118,1,1)//"Não ha Adiantamentos para a planilha deste contrato!"

	ElseIf lRet
		If Len(aAdiants) == 0  .Or. (oModel:GetOperation() == MODEL_OPERATION_UPDATE)
			While !( cAliasQry )->( Eof() )
				aAdd(aColsCpos, {( cAliasQRY )->CNX_NUMERO, ( cAliasQRY )->CNX_DTADT, ( cAliasQRY )->CNX_VLADT, ( cAliasQRY )->CNX_SALDO, ( cAliasQRY )->CNX_VLCOMP,.F.})
				aAdd(aColsAux, {( cAliasQRY )->CNX_SLDATU})
				( cAliasQry )->( dbSkip() )
			EndDo
		ElseIf Len(aAdiants) != 0 .Or. oModel:GetOperation() == MODEL_OPERATION_INSERT
			While !( cAliasQry )->( Eof() )
				nVlrAdi := 0
				nVlrCom := 0
				nH		+= 1

				If nK := aScan(aAdiants,{|x| x[1][2][nH][1] == (cAliasQRY )->CNX_NUMERO })
					If nY := aScan(aAdiants[nK,1,2],{|x| x[1] == (cAliasQRY )->CNX_NUMERO })
						For nZ := 1 To Len(aAdiants)
							If aAdiants[nZ][1][2][nY][1] == (cAliasQRY )->CNX_NUMERO
								nVlrAdi += aAdiants[nZ,1,2,nY,2]
							EndIf

							If aAdiants[nZ][1][1] == cNumpla
								nVlrCom += aAdiants[nZ,1,2,nY,2]
							EndIf
						Next nZ
					EndIf
				EndIf

				If ( aScan(aAdiants,{|x| x[1][1] == cNumpla}))  == 0
					nPla	:= 2
				EndIf

				aAdd(aColsCpos,{(cAliasQRY )->CNX_NUMERO,(cAliasQRY)->CNX_DTADT,(cAliasQRY)->CNX_VLADT,((cAliasQRY)->CNX_SALDO+(cAliasQRY)->CNX_VLCOMP)-nVlrAdi,IIf(nPla == 2, 0, nVlrCom),.F.})
				aAdd(aColsAux, IIf (nPla == 2,{( cAliasQRY )->CNX_SLDATU-nVlrAdi},{( cAliasQRY )->CNX_SLDATU}))
				( cAliasQry )->( dbSkip() )
			EndDo
		EndIf

		aAdd(aCpos, {"CNX_NUMERO","CNX_DTADT","CNX_VLADT","CNX_SALDO","CNX_VLCOMP"})
		//Retorna o aHeader dos campos da query
		aHeadCpos := CN121x3Tit(aCpos)

		(cAliasQRY)->(dbCloseArea())

		DEFINE MSDIALOG oDlgMult TITLE STR0116 FROM 0,0 TO 300, 700 OF oMainWnd PIXEL //Adiantamentos
		DEFINE FONT oBold NAME "Arial" SIZE 0, -13 BOLD
		oSize := FwDefSize():New(.F.,,,oDlgMult)
		oSize:AddObject( "GETDADOS",  100, 90, .T., .T. ) // Totalmente dimensionavel
		oSize:AddObject( "BUTTONS",  100, 10, .T., .T. ) // Totalmente dimensionavel

		oSize:lProp 	:= .T. // Proporcional
		oSize:aMargins 	:= { 3, 3, 3, 3 } // Espaco ao lado dos objetos 0, entre eles 3

		oSize:Process() 	   // Dispara os calculos

		oGetAdia := MsNewGetDados():New(oSize:GetDimension("GETDADOS","LININI"),;
										oSize:GetDimension("GETDADOS","COLINI"),;
			     						oSize:GetDimension("GETDADOS","LINEND"),;
			     						oSize:GetDimension("GETDADOS","COLEND"),;
		    							GD_UPDATE,;
		    							,;
		    							'CNAdTdOk',;
		    							,;
		    							{'CNX_VLCOMP'},;
		    							,;
		    							999,;
		    							,;
		    							,;
		    							,;
		    							oDlgMult,;
		    							@aHeadCpos,;
		    							@aColsCpos)

		oDlgMult:Refresh()
		DEFINE SBUTTON oBut1 FROM 135, 280  TYPE 1 ACTION ( nOpca := 1,If(oGetAdia:TudoOk(), (oModelCXN:SetValue("CXN_VLRADI",Cn121TotAd()),oDlgMult:End()), .F.) )  ENABLE of oDlgMult
		DEFINE SBUTTON oBut2 FROM 135, 310  TYPE 2 ACTION ( nOpca := 2,oDlgMult:End() )  ENABLE of oDlgMult
		ACTIVATE MSDIALOG oDlgMult CENTERED

		If nOpca == 1
			If !Empty(aAdiants) .And. (nX := aScan(aAdiants,{|x| x[1][1] == cNumPla}))
				aAdiants[nX,1] := aClone(Cn121RetAd()[1])
			Else
				aAdd(aAdiants, Cn121RetAd())
			EndIf
			//aAdiants  := aClone(Cn121RetAd())
			aColsCpos := aClone(oGetAdia:aCols)

		ElseIf nOpca == 2
			aColsCpos	:= {}
			aColsAux 	:= {}

			If oModel:GetOperation() == MODEL_OPERATION_INSERT
				oModelCXN:SetValue("CXN_VLRADI", 0)
			EndIf
		EndIf
	EndIf
Else
	lRet := .F.
	Help("",1,"CN121ADIANTA",,STR0119,1,1)//"Informe o contrato e selecione a competência para verificar se existem adiantamentos!"
EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Restaura a integridade dos dados de entrada                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
RestArea( aArea )

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121VFoCl(lCompra,cForCli,cCodLoj)
Retornar o título definido no SX3 para o campo informado.

@since 22/11/2016
@version P12
@return lRet
/*/
//-------------------------------------------------------------------
Static Function CN121x3Tit(aCampo)
Local aSavArea	:= GetArea()
Local aTitCampo	:= {}
Local nX		:= 0

For nX := 1 to len(aCampo[1])
	SX3->(dbSetOrder(2))
	If SX3->(dbSeek(aCampo[1][nX]))
		aAdd(aTitCampo, {	GetSx3Cache(aCampo[1][nX],'X3_TITULO'),;
							GetSx3Cache(aCampo[1][nX],'X3_CAMPO'),;
							GetSx3Cache(aCampo[1][nX],'X3_PICTURE'),;
							GetSx3Cache(aCampo[1][nX],'X3_TAMANHO'),;
							GetSx3Cache(aCampo[1][nX],'X3_DECIMAL'),;
							GetSx3Cache(aCampo[1][nX],'X3_VALID'),;
							GetSx3Cache(aCampo[1][nX],'X3_USADO'),;
							GetSx3Cache(aCampo[1][nX],'X3_TIPO'),;
							GetSx3Cache(aCampo[1][nX],'X3_F3'),;
							GetSx3Cache(aCampo[1][nX],'X3_CONTEXT')})
	EndIf
Next nX

Aadd(aTitCampo,{ 'Vlr Compensar', 'CNX_VLCOMP', '@E 9,999,999,999,999.99', 16, 2, 'Cn121VComp()', '€€€€€€€€€€€€€€ ', 'N', ,'R'} )

RestArea(aSavArea)
Return aTitCampo

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121VFoCl(lCompra,cForCli,cCodLoj)
Retornar o título definido no SX3 para o campo informado.

@since 22/11/2016
@version P12
@return lRet
/*/
//-------------------------------------------------------------------
Function Cn121VComp()
Local aSavArea	:= GetArea()
Local oModel 		:= FwModelActive()
Local oModelCND		:= oModel:GetModel("CNDMASTER")
Local oModelCXN		:= oModel:GetModel("CXNDETAIL")
Local nPosSld		:= aScan(oGetAdia:Aheader,{|x| AllTrim(x[2])=="CNX_SALDO"})
Local nVlrAdi 		:= 0
Local nZ			:= 0
Local nN			:= 0
Local lRet			:= .T.

dbSelectArea("CNX")
CNX->(dbSetOrder(1))//CNX_FILIAL+CNX_CONTRA+CNX_NUMERO
CNX->(MsSeek(XFilial("CNX") + oModelCND:GetValue("CND_CONTRA") + oGetAdia:aCols[n][1]))

If oModel:GetOperation() == MODEL_OPERATION_UPDATE
	DbSelectArea("CZY")
	CZY->(DbsetOrder(2))
	CZY->(MsSeek(cFilCTR+ oModelCND:GetValue("CND_CONTRA")+oModelCND:GetValue("CND_REVISA")+oModelCND:GetValue("CND_NUMMED")+oModelCXN:GetValue("CXN_NUMPLA")+oGetAdia:aCols[n][1]))

	If M->CNX_VLCOMP > (CZY->CZY_VALOR + CNX->CNX_SALDO)
		Help(" ",1,"CN130NVLCOMP")
		lRet := .F.
	Endif

	If lRet
		oGetAdia:Acols[n,nPosSld] := (CZY->CZY_VALOR + CNX->CNX_SALDO) - M->CNX_VLCOMP
		oGetAdia:Refresh()
	EndIf
Else
	//Campo CNX_VLCOMP criado para tratativa do adiantamento
	If Len(aAdiants) == 0
		If M->CNX_VLCOMP > CNX->CNX_SALDO
			Help(" ",1,"CN130NVLCOMP")
			lRet := .F.
		EndIf
	Else
		If nN := aScan(aAdiants[1,1,2],{ |x| x[1] == oGetAdia:aCols[n][1] })
			For nZ := 1 To Len(aAdiants)
				If (aAdiants[nZ,1,1] <> oModelCXN:GetValue('CXN_NUMPLA')) .And. (aAdiants[nZ][1][2][nN][1] == oGetAdia:aCols[n][1])
					nVlrAdi += aAdiants[nZ,1,2,nN,2]
				EndIf
			Next nZ
		EndIf

		If  M->CNX_VLCOMP > (CNX->CNX_SALDO-nVlrAdi)
			Help(" ",1,"CN130NVLCOMP")
			lRet := .F.
		EndIf
	EndIf

	If lRet
		oGetAdia:Acols[n,nPosSld] := IIf(Len(aAdiants) == 0, CNX->CNX_SALDO - M->CNX_VLCOMP, (CNX->CNX_SALDO-nVlrAdi) - M->CNX_VLCOMP)
		oGetAdia:Refresh()
	EndIf
EndIf

RestArea(aSavArea)
Return lRet

//------------------------------------------------------------------
/*/{Protheus.doc} Cn121TotAd()
Função que retorna o total dos adiantamentos

@since 22/11/2016
@version P12
@return lRet
/*/
//-------------------------------------------------------------------
Function Cn121TotAd()
Local nVlr		:= aScan(oGetAdia:Aheader,{|x| AllTrim(x[2])=="CNX_VLCOMP"})
Local nTotal	:= 0
Local nI 		:= 0

For nI := 1 To Len(oGetAdia:Acols)
	If oGetAdia:Acols[nI, nVlr] > 0
		nTotal += oGetAdia:Acols[nI, aScan(oGetAdia:Aheader,{|x| AllTrim(x[2])=="CNX_VLCOMP"})]
	EndIf
Next nI

Return nTotal

//------------------------------------------------------------------
/*/{Protheus.doc} Cn121RetAd()
Função que retorna o total dos adiantamentos no cabeçalho da medição


@author Matheus Lando Raimundo
@since 19/12/2014
@version P12
/*/
//-------------------------------------------------------------------
Function Cn121RetAd()
Local oModel	:= FwModelActive()
Local oModelCND	:= oModel:GetModel("CNDMASTER")
Local oModelCXN	:= oModel:GetModel("CXNDETAIL")
Local cContra	:= oModelCND:GetValue("CND_CONTRA")
Local cRevisa	:= oModelCND:GetValue("CND_REVISA")
Local cNumMed	:= oModelCND:GetValue("CND_NUMMED")
Local cNumPla	:= oModelCXN:GetValue("CXN_NUMPLA")
Local nI 		:= 0
Local nTotal 	:= 0
Local aAdts		:= {}
Local nNumero	:= aScan(oGetAdia:Aheader,{|x| AllTrim(x[2])=="CNX_NUMERO"})
Local nVlr		:= aScan(oGetAdia:Aheader,{|x| AllTrim(x[2])=="CNX_VLCOMP"})

aAdd(aAdts, {cNumPla,{}})

For nI := 1 To Len(oGetAdia:Acols)
	If oGetAdia:Acols[nI, nVlr] > 0
		aAdd(aAdts[1][2], {oGetAdia:Acols[nI, nNumero],oGetAdia:Acols[nI, nVlr]})
		nTotal += oGetAdia:Acols[nI, nVlr]
	Else
		DbSelectArea("CZY")
		DbsetOrder(1)
		If DbSeek(xFilial("CND",cFilCTR)+cContra+cRevisa+cNumMed+oGetAdia:Acols[nI, nNumero])
			//CnGrvAdia(,5,oGetAdia:Acols[nI, nNumero])
			Cn121GrvAd(,5,oGetAdia:Acols[nI, nNumero])
		EndIf
	EndIf
Next nI

oModelCXN:LoadValue("CXN_VLRADI", nTotal)

Return aAdts

//------------------------------------------------------------------
/*/{Protheus.doc} CN121Exced()
Inclui excedente na medicao encerrada


@author Filipe Gonçalves Rodrigues
@since 19/12/2014
@version P12
/*/
//-------------------------------------------------------------------
Function CN121Exced(lAuto,aExcds)
Local lContinua := CN240VldUsr(CND->CND_CONTRA,DEF_TRAEDT_MED,.T.,,cFilCtr)
Local lSeekCN9	:= .F.
Local cTitulo 	:= STR0088 + " " + STR0050 + " " + STR0120
Local cChave 	:= CND->CND_CONTRA+CND->CND_REVISA+CND->CND_NUMERO+CND->CND_NUMMED
Local cModel	:= "CNTA121"
Local lRet 			:= .T.
Local oModel		:= Nil
Local oCNDMaster	:= Nil
Local oCXNDetail	:= Nil
Local oCNEDetail	:= Nil
Local oStruct		:= Nil
Local nY			:= 0
Local nX			:= 0
Local nI			:= 0
Local nPos			:= 0
Local aAux			:= {}
Local aSaveLines	:= {}
lOCAL cCodProd		:= ""

Default lAuto		:= .F.
Default aExcds		:= {}

If Cn121RetSt('MEDEVE',1,,,.F.)
	lRet := .F.
	MsgAlert(STR0162)
Else
If Cn121OriMd('CNTA120')
 	Aviso(STR0079,STR0127+CRLF+STR0128+CRLF+CRLF+STR0125+CRLF+STR0126,{STR0156},2) //- Opção indisponivel para medições realizadas com a rotina de medições padrão.
Else
	SetExcedME(.T.)

	CN9->(dbSetOrder(1))
	lSeekCN9 := CN9->(dbSeek(xFilial("CN9",cFilCTR)+CND->CND_CONTRA+CND->CND_REVISA))

	If lContinua .And. lSeekCN9
		If Cn300RetSt('COMPRA',,,CND->CND_CONTRA,,.F.)
			Help(" ",1,"CN121Exced") //- "Funcionalidade indisponível para contratos de compra."
			lContinua := .F.
			lRet := .F.
		EndIf
	EndIf

	If lContinua
		If CND->CND_SITUAC <> "E "
			Help(" ",1,"C121ExdEnc") //- Funcionalidade indisponível para medições de venda não encerradas.
			lContinua := .F.
			lRet := .F.
		EndIf
	EndIf

	If lContinua
		If LockByName("CN121"+xFilial("CND")+cChave,.T.,!Empty(xFilial("CND")),.T.)
			If !lAuto
				FWExecView(cTitulo ,cModel,MODEL_OPERATION_UPDATE,,{|| .T.})
			Else
				oModel := FwModelActive()
				If oModel:GetId() == "CNTA121" .And. oModel:IsActive()
					oModel:DeActivate()
				Endif

				oModel := FwLoadModel("CNTA121")
				oCNDMaster	:= oModel:GetModel("CNDMASTER")
				oCXNDetail	:= oModel:GetModel("CXNDETAIL")
				oCNEDetail	:= oModel:GetModel("CNEDETAIL")

				oModel:SetOperation(MODEL_OPERATION_UPDATE)

				If lRet := oModel:Activate()
					aSaveLines	:=	FwSaveRows()
					oStruct 	:= oCNEDetail:GetStruct()
					aAux 		:= oStruct:GetFields()

					For nY := 1 To oCXNDetail:Length()
						oCXNDetail:GoLine(nY)
						If oCXNDetail:GetValue("CXN_CHECK")

							For nI := 1 To oCNEDetail:Length()
								oCNEDetail:Goline(nI)
								If !Empty(oCNEDetail:GetValue("CNE_PRODUT"))
									cCodProd := oCNEDetail:GetValue("CNE_PRODUT")
								Endif
							Next nI

							//Libera o Update
							oCNEDetail:SetNoUpdateLine(.F.)

							If lRet := oCNEDetail:SeekLine({{"CNE_EXCEDE","1"}})
								//Habilita edição de campos
								CN121ChgPl()

								lRet := lRet .And. oCNEDetail:LoadValue("CNE_PRODUT",cCodProd)

								For nI := 1 To Len(aExcds)
									For nX := 1 To Len(aExcds[nI])
										If (nPos := aScan(aAux,{ |x| AllTrim(x[3]) == AllTrim(aExcds[nI][nX][1])})) > 0
											If !(lRet := oCNEDetail:LoadValue(aExcds[nI][nX][1],aExcds[nI][nX][2]))
												Exit
											Endif
										Endif
									Next nX
								Next nI
							Endif
						Endif
					Next nY
					FWRestRows( aSaveLines )
				Endif

				If lRet
					lRet := oModel:VldData() .And. oModel:CommitData()
				Endif

				If !lRet
					AtErroMvc(oModel)
					MostraErro()
				Endif

				If oModel:IsActive()
					oModel:DeActivate()
				Endif
			Endif
		Else
			Help(" ",1,"A121CONC")
			lRet := .F.
		EndIf
	EndIf

	UnLockByName("CN121"+xFilial("CND")+cChave,.T.,!Empty(xFilial("CND")),.T.)

	SetExcedME(.F.)
EndIf
EndIf
Return lRet

//------------------------------------------------------------------
/*/{Protheus.doc} CN121ExceC()
Inclui excedente na medicao para competência inexistente


@author Filipe Gonçalves Rodrigues
@since 19/12/2014
@version P12
/*/
//-------------------------------------------------------------------
Function CN121ExceC()
Local cTitulo 	:= STR0088 + " " + STR0050 + " " + STR0121
Local cModel	:= "CNTA121"

SetExcedNP(.T.)

lInclui := .T.
aComp	:= {}
FWExecView(cTitulo,cModel,MODEL_OPERATION_INSERT,,{|| .T.})//"Inclusão de Medição"
lInclui := .F.

SetExcedNP(.F.)

Return

//------------------------------------------------------------------
/*/{Protheus.doc} CN121VLDSF()
Inclui excedente na medicao para competência inexistente


@author Filipe Gonçalves Rodrigues
@since 19/12/2014
@version P12
/*/
//-------------------------------------------------------------------
Function CN121VLDSF(cContra, cRevisa ,cNumPla)
Local nTotMed 	:= 0
Local cQuery 	:= ""
Local aArea		:= GetArea()
Local cAliasTmp	:= GetNextAlias()

Default cContra	:= ""
Default cRevisa	:= ""
Default cNumPla	:= ""

cQuery += " SELECT SUM(CXN_VLTOT) AS TOTAL FROM "+RetSQLName("CXN")+" WHERE "
cQuery += " CXN_CONTRA = '"+cContra+"' AND "
cQuery += " CXN_REVISA = '"+cRevisa+"' AND "
cQuery += " CXN_NUMPLA = '"+cNumPla+"' AND "
cQuery += " CXN_NUMMED IN "
cQuery += " (SELECT CND_NUMMED FROM "+RetSQLName("CND")+" WHERE "
cQuery += "		CND_CONTRA = '"+cContra+"' AND "
cQuery += " 	CND_REVISA = '"+cRevisa+"' AND "
cQuery += " 	CND_SITUAC IN ('A','B','SA','FA') AND "
cQuery += " 	D_E_L_E_T_ = ' ') AND "
cQuery += " D_E_L_E_T_ = ' '"

cQuery := ChangeQuery(cQuery)
dbUseArea(.T.,"TOPCONN",TcGenQry( ,, cQuery ),cAliasTmp,.F.,.T.)

nTotMed := (cAliasTmp)->TOTAL
(cAliasTmp)->(dbCloseArea())
RestArea(aArea)

Return nTotMed

//------------------------------------------------------------------
/*/{Protheus.doc} C121CNEAgr()
Validação do agrupador referente ao valor máximo da CXM


@author Filipe Gonçalves Rodrigues
@since 16/02/2017
@version P12
/*/
//-------------------------------------------------------------------
Static Function C121CNEAgr(oModel,cField,xValue,nLine, lUndelete)
Local aArea		:= GetArea()
Local aSaveLines:= FWSaveRows()
Local oModelCND := oModel:GetModel('CNDMASTER')
Local oModelCXN	:= omodel:GetModel('CXNDETAIL')
Local oModelCNE	:= oModel:GetModel('CNEDETAIL')
Local oModelCXM := oModel:GetModel("CXMDETAIL")
Local aAgrvld	:= {}
Local nX		:= 0
Local nY		:= 0
Local nPos		:= 0
Local nPos1		:= 0
Local nValor	:= 0
Local lRet		:= .T.
Local cTipo		:= ""
Local cGrupo 	:= ""

Default oModel		:= FwModelActive()
Default cField		:= ""
Default xValue		:= 0
Default nLine		:= 0
Default lUndelete	:= .F.

For nX := 1 To oModelCNE:Length()
	oModelCNE:GoLine(nX)
	If !oModelCNE:IsDeleted() .Or. lUndelete
		SB1->(DbSeek(xFilial("SB1")+oModelCNE:GetValue("CNE_PRODUT")))
		cTipo := SB1->B1_TIPO
		cGrupo := SB1->B1_GRUPO
		If oModelCNE:GetLine() == nLine
			If (nPos := aScan(aAgrvld,{|x| x[1] == cTipo})) > 0
				If (nPos1 := aScan(aAgrvld,{|x| x[2] == cGrupo})) > 0

					If cField == "CNE_VLUNIT"
						nValor := oModelCNE:GetValue("CNE_QUANT") * xValue
					ElseIf cField == "CNE_QUANT"
						nValor := xValue * oModelCNE:GetValue("CNE_VLUNIT")
					Else
						nValor := oModelCNE:GetValue("CNE_QUANT") * oModelCNE:GetValue("CNE_VLUNIT")
					EndIf

					aAgrvld[nPos][3] += nValor
				Else
					If cField == "CNE_VLUNIT"
						nValor := oModelCNE:GetValue("CNE_QUANT") * xValue
					ElseIf cField == "CNE_QUANT"
						nValor := xValue * oModelCNE:GetValue("CNE_VLUNIT")
					Else
						nValor := oModelCNE:GetValue("CNE_QUANT") * oModelCNE:GetValue("CNE_VLUNIT")
					EndIf
					aAdd(aAgrvld,{cTipo, cGrupo, nValor})
				EndIf
			Else
				If cField == "CNE_VLUNIT"
						nValor := oModelCNE:GetValue("CNE_QUANT") * xValue
					ElseIf cField == "CNE_QUANT"
						nValor := xValue * oModelCNE:GetValue("CNE_VLUNIT")
					Else
						nValor := oModelCNE:GetValue("CNE_QUANT") * oModelCNE:GetValue("CNE_VLUNIT")
					EndIf
				aAdd(aAgrvld,{cTipo, cGrupo, nValor})
			EndIf
		Else
			If (nPos := aScan(aAgrvld,{|x| x[1] == cTipo})) > 0
				If (nPos1 := aScan(aAgrvld,{|x| x[2] == cGrupo})) > 0
					aAgrvld[nPos][3] += oModelCNE:GetValue("CNE_VLTOT")
				Else
					aAdd(aAgrvld,{cTipo, cGrupo, oModelCNE:GetValue("CNE_VLTOT")})
				EndIf
			Else
				aAdd(aAgrvld,{cTipo, cGrupo, oModelCNE:GetValue("CNE_VLTOT")})
			EndIf
		EndIf
	EndIf
Next Nx

//Percorre o array para posicionar na CXM e verificar se o total do agrupador é maior que o total dos itens
For nX := 1 to Len(aAgrvld)
	If (nPos := MtFindMVC(oModelCXM,{{"CXM_AGRTIP",aAgrvld[nX][1]}})) > 0
		If (nPos1 := MtFindMVC(oModelCXM,{{"CXM_AGRTIP",aAgrvld[nX][2]}})) > 0
			oModelCXM:Goline(nPos1)
		Else
			oModelCXM:Goline(nPos)
		EndIf

		If oModelCXM:GetValue("CXM_VLMAX") <> 0 .And. aAgrvld[nX][3] > oModelCXM:GetValue("CXM_VLMAX")
			lRet := .F.
			Help(" ",1,"CN121UNIGRP")
			Exit
		EndIf
	EndIf
Next nX

RestArea(aArea)
FWRestRows( aSaveLines )
Return lRet

//------------------------------------------------------------------
/*/{Protheus.doc} CN121Auto()

@author Kaique Schiller Olivero
@since 20/03/2017
@version P12.1.14
/*/
//-------------------------------------------------------------------
Function CN121Auto(aCposCab,aCposItem,nOpcAut,aExceds,aMultas,aDescts)
Local aArea			:= GetArea()
Local oModel 		:= Nil
Local oCNDMaster	:= Nil
Local oCXNDetail	:= Nil
Local oCNEDetail	:= Nil
Local oCNRDetail	:= Nil
Local oCNQDetail	:= Nil
Local oStruct		:= Nil
Local bValid		:= Nil
Local nX			:= 0
Local nI			:= 0
Local nY			:= 0
Local nZ			:= 0
Local nPos			:= 0
Local cNumPla		:= ""
Local lRet	 		:= .T.
Local cContra		:= ""
Local cRevisa		:= ""
Local cNumMed		:= ""
Local cTpDesc		:= ""
Default aCposCab	:= {}
Default aCposItem	:= {}
Default nOpcAut		:= 0
Default aExceds		:= {}
Default aMultas		:= {}
Default aDescts		:= {}

If !Empty(aCposCab) .And. !Empty(aCposItem)
	For nX := 1 To Len(aCposCab)
		If aCposCab[nX][1] == "CND_CONTRA"
			cContra := aCposCab[nX][2]
		Elseif aCposCab[nX][1] == "CND_REVISA"
			cRevisa := aCposCab[nX][2]
		Elseif aCposCab[nX][1] == "CND_NUMMED"
			cNumMed := aCposCab[nX][2]
		Endif
	Next nX

	If nOpcAut == 3 .Or. nOpcAut == 5
		oModel 		:= FwLoadModel("CNTA121")
		oCNDMaster	:= oModel:GetModel("CNDMASTER")
		oCXNDetail	:= oModel:GetModel("CXNDETAIL")
		oCNEDetail	:= oModel:GetModel("CNEDETAIL")
		oCNRDetail 	:= oModel:GetModel("CNRDETAIL1")
		oCNQDetail 	:= oModel:GetModel("CNQDETAIL")

		If nOpcAut == 3
			oModel:SetOperation(MODEL_OPERATION_INSERT)
		Elseif nOpcAut == 5
			DbSelectArea("CND")
			CND->(DbSetOrder(7)) //CND_FILIAL+CND_CONTRA+CND_REVISA+CND_NUMMED
			If CND->(DbSeek(xFilial("CND")+cContra+cRevisa+cNumMed))
				oModel:SetOperation(MODEL_OPERATION_DELETE)
			Else
				//Não foi possível encontrar a CND
				lRet := .F.
			Endif
		Endif

		If lRet
			lRet := oModel:Activate()
		Endif

		If lRet .And. nOpcAut == 3
			oStruct 	:= oCNDMaster:GetStruct()
			aAux 		:= oStruct:GetFields()
			For nI := 1 To Len(aCposCab) //Preenche o cabeçalho CND
				// Verifica se os campos passados existem na estrutura do cabeçalho
				If aScan(aAux,{ |x| AllTrim(x[3]) == AllTrim(aCposCab[nI][1])}) > 0
					If aCposCab[nI][1] == "CND_VLTOT"
						oCNDMaster:GetStruct():SetProperty('CND_VLTOT',MODEL_FIELD_WHEN,{||.T.})
					EndIf		
					If !(lRet := oCNDMaster:SetValue(aCposCab[nI][1],aCposCab[nI][2])) 
						Exit
					Endif
				Endif
				If aCposCab[nI][1] == "CND_NUMERO"
					cNumPla := aCposCab[nI][2]
				Endif
			Next nI
			// Atribui corretamente o conteúdo da competência para a carga dos valores pelo campo
			// CND_RCCOMP preencherá o CND_COMPET
			If lRet
				nI := aScan( aCposCab, {|x| x[1]== "CND_COMPET" } )
				nPos := aScan( aComp, {|x| aCposCab[nI,2] $ x } )
				If nPos > 0
					lRet := lRet .And. oCNDMaster:SetValue("CND_RCCOMP", SubStr( aComp[nPos], 1, (At( "=", aComp[nPos] ) - 1) ) )
				Else
					// Atribui vazio para que indique no erro o problema de estrutura no campo
					lRet := lRet .And. oCNDMaster:SetValue("CND_RCCOMP","")
				EndIf
			EndIf

			If lRet
				If lRet := oCXNDetail:SeekLine({{"CXN_NUMPLA",cNumPla}})
					lRet := oCXNDetail:SetValue("CXN_CHECK",.T.)
					If lRet
						nPosCli:= aScan(aCposCab, {|x| x[1] == 'CND_CLIENT'})
						nPosLoj:= aScan(aCposCab, {|x| x[1] == 'CND_LOJACL'}) 						
						If (nPosCli > 0) .And. (nPosLoj > 0)  
							If !Empty(aCposCab[nPosCli][2]) .And. !Empty(aCposCab[nPosLoj][2]) 

								oCXNDetail:GetStruct():SetProperty('CXN_FORCLI',MODEL_FIELD_WHEN,{||.T.})
								oCXNDetail:GetStruct():SetProperty('CXN_LOJA',MODEL_FIELD_WHEN,{||.T.})
						
								oCXNDetail:LoadValue('CXN_FORCLI'	, aCposCab[nPosCli][2])
								oCXNDetail:LoadValue('CXN_LOJA' 	, aCposCab[nPosLoj][2])

								oCXNDetail:GetStruct():SetProperty('CXN_FORCLI',MODEL_FIELD_WHEN,{||.F.})
								oCXNDetail:GetStruct():SetProperty('CXN_LOJA',MODEL_FIELD_WHEN,{||.F.})								
							EndIf 
						Endif
					EndIf
				Endif

				If lRet
					oStruct 	:= oCNEDetail:GetStruct()
					aAux 		:= oStruct:GetFields()

					For nI := 1 To oCNEDetail:Length()
						oCNEDetail:Goline(nI)
						If (nPos := aScan(aCposItem,{ |x| x[1][2] == oCNEDetail:GetValue("CNE_ITEM") })) > 0
							For nX := 1 To Len(aCposItem[nPos][nX]) //Inclui os itens da Apuração/Medição
								If aScan(aAux,{ |x| AllTrim(x[3]) == AllTrim(aCposItem[nPos][nX][1])}) > 0
									If !(lRet := oCNEDetail:SetValue(aCposItem[nPos][nX][1],aCposItem[nPos][nX][2]))
										Exit
									Endif
								Endif
							Next nX
						Else
							If !(lRet := oCNEDetail:SetValue("CNE_VLTOT",0))
								Exit
							Endif
						Endif
					Next nI

					If lRet .And. !Empty(aMultas)
						For nY := 1 To Len(aMultas) //Inclui as Multas/Bonificação

							lRet := lRet .And. Iif(oCNRDetail:GetValue("CNR_TIPO") <> aMultas[nY][1],oCNRDetail:SetValue("CNR_TIPO",aMultas[nY][1]),.T.)
							lRet := lRet .And. oCNRDetail:SetValue("CNR_DESCRI"	,aMultas[nY][2])
							lRet := lRet .And. oCNRDetail:SetValue("CNR_VALOR"	,aMultas[nY][3])

							oCNRDetail:GetStruct():SetProperty('CNR_MODO',MODEL_FIELD_WHEN,{||.T.})
							lRet := lRet .And. oCNRDetail:SetValue("CNR_MODO"	,aMultas[nY][4])
							oCNRDetail:GetStruct():SetProperty('CNR_MODO',MODEL_FIELD_WHEN,{||.F.})

							lRet := lRet .And. oCNRDetail:SetValue("CNR_FLGPED"	,aMultas[nY][5])

							If !lRet
								Exit
							Else
								If nY < Len(aMultas)
									oCNRDetail:AddLine()
								Endif
							Endif
						Next nY
					Endif

					For nY := 1 To Len(aDescts) //Inclui os descontos
						lRet := lRet .And. oCNQDetail:SetValue("CNQ_TPDESC"	,aDescts[nY,1])
						lRet := lRet .And. oCNQDetail:SetValue("CNQ_VALOR"	,aDescts[nY,2])
						If nY < Len(aDescts)
							oCNQDetail:AddLine()
						Endif
					Next nY

				Endif
			Endif
		EndIf

		If lRet
			lRet := oModel:VldData() .And. oModel:CommitData()
		Endif

		If !lRet
			AtErroMvc(oModel)
			MostraErro()
		Endif

		//Veriica se esta ativo e desativa o Modelo
		If oModel:IsActive()
			oModel:DeActivate()
		Endif

	ElseIf nOpcAut == 6
		DbSelectArea("CND")
		CND->(DbSetOrder(7)) //CND_FILIAL+CND_CONTRA+CND_REVISA+CND_NUMMED
		If CND->(DbSeek(xFilial("CND")+cContra+cRevisa+cNumMed))
			lRet := CN121Encerr(.T.)
		Endif
	Elseif nOpcAut == 7
		DbSelectArea("CND")
		CND->(DbSetOrder(7))
		If CND->(DbSeek(xFilial("CND")+cContra+cRevisa+cNumMed))
			lRet := CN121Estorn(.T.)
		Endif
	Elseif nOpcAut == 8
		DbSelectArea("CND")
		CND->(DbSetOrder(7))
		If CND->(DbSeek(xFilial("CND")+cContra+cRevisa+cNumMed))
			lRet := CN121Exced(.T.,aExceds)
		Endif
	Endif
Endif

RestArea(aArea)

Return lRet

//------------------------------------------------------------------
/*/{Protheus.doc} CN121VlSt()
	Verifica a sitauação pela função Cn300ReSt()
@author Kaique Schiller Olivero
@since 20/03/2017
@version P12.1.14
/*/
//-------------------------------------------------------------------
Function CN121VlSt()
Local lRet 		:= .F.
Local oModel	:= Nil
Local oModelCXN := Nil
Local cPlanCt 	:= ""
Local cConCt 	:= ""
Local lnotTEC930 := IIF( FindFunction("TEC930Test") .AND. TEC930Test() , .F. , !lMedicao)

If IsInCallStack('CNTA120') .And. lnotTEC930
	cPlanCt := M->CND_NUMERO
	cConCt 	:= M->CND_CONTRA
Else
	oModel		:= FwModelActive()
	oModelCXN 	:= oModel:GetModel('CXNDETAIL')
	cPlanCt 	:= oModelCXN:GetValue("CXN_NUMPLA")
	cConCt 		:= oModelCXN:GetValue("CXN_CONTRA")
EndIf

lRet := Cn300RetSt('FIXO',0,cPlanCt,cConCt,xFilial('CN9')) .And. CN300RetSt("SERVIÇO",0,cPlanCt,cConCt,xFilial('CN9'))

Return lRet

//------------------------------------------------------------------
/*/{Protheus.doc} Cn121GetLoc(cCodCtr, cNumPla)
	Pega informações do local de atendimento baseado na Planilla Med. de contratos
@author Kaique Schiller Olivero
@since 08/05/2017
@version P12.1.14
/*/
//-------------------------------------------------------------------
Function Cn121GetLoc(cCodCtr,cRev,cNumPla)
Local cAliasTemp	:= GetNextAlias()
Local aInfLoc 		:= {"","",""}

If !Empty(cCodCtr) .And. !Empty(cNumPla)
	BeginSQL Alias cAliasTemp
		SELECT ABS_RECISS,ABS_CODMUN,ABS_ESTADO
			FROM %Table:TFL% TFL
		INNER JOIN %Table:ABS% ABS ON
			ABS.ABS_FILIAL = %xFilial:ABS% AND
			ABS.ABS_LOCAL  = TFL.TFL_LOCAL
		WHERE
			TFL.TFL_FILIAL 	= %xFilial:TFL% AND
			TFL.TFL_CONTRT	= %Exp:cCodCtr%	AND
			TFL.TFL_CONREV	= %Exp:cRev%	AND
			TFL.TFL_PLAN	= %Exp:cNumPla%	AND
			TFL.%NotDel% AND ABS.%NotDel%
	EndSQL

	If (cAliasTemp)->(!Eof())
		aInfLoc[1] := (cAliasTemp)->ABS_CODMUN
		aInfLoc[2] := (cAliasTemp)->ABS_RECISS
		aInfLoc[3] := (cAliasTemp)->ABS_ESTADO
	EndIf

	(cAliasTemp)->(dbClosearea())

Endif

Return aInfLoc

//------------------------------------------------------------------
/*/{Protheus.doc} Cn121GLocTWW(cCodCtr, cNumPla)
	Pega informações do local de atendimento baseado na Planilla Med. de contratos
@author Kaique Schiller Olivero
@since 08/05/2017
@version P12.1.14
/*/
//-------------------------------------------------------------------
Function Cn121GLocTWW(cCodCtr,cRev,cNumPla)
Local cAliasTemp	:= GetNextAlias()
Local aInfLoc 		:= {"","",""}

If !Empty(cCodCtr) .And. !Empty(cNumPla)
	BeginSQL Alias cAliasTemp
		SELECT ABS_RECISS,ABS_CODMUN,ABS_ESTADO
			FROM %Table:TFL% TFL
		INNER JOIN %Table:ABS% ABS ON
			ABS.ABS_FILIAL = %xFilial:ABS% AND
			ABS.ABS_LOCAL  = TFL.TFL_LOCAL
		INNER JOIN %Table:TWW% TWW ON
			TWW.TWW_FILIAL = %xFilial:TWW% AND
			TWW.TWW_CONTRT	= %Exp:cCodCtr%	AND
			TWW.TWW_REVISA	= %Exp:cRev%	AND
			TWW.TWW_LOCAL  = TFL.TFL_LOCAL AND
				(TWW.TWW_PLANRH = %Exp:cNumPla% OR
				TWW.TWW_PLANMI = %Exp:cNumPla%  OR
				TWW.TWW_PLANMC = %Exp:cNumPla% )
		WHERE
			TFL.TFL_FILIAL 	= %xFilial:TFL% AND
			TFL.TFL_CONTRT	= %Exp:cCodCtr%	AND
			TFL.TFL_CONREV	= %Exp:cRev%	AND
			TFL.%NotDel%
	EndSQL

	If (cAliasTemp)->(!Eof())
		aInfLoc[1] := (cAliasTemp)->ABS_CODMUN
		aInfLoc[2] := (cAliasTemp)->ABS_RECISS
		aInfLoc[3] := (cAliasTemp)->ABS_ESTADO
	EndIf

	(cAliasTemp)->(dbClosearea())

Endif

Return aInfLoc

//------------------------------------------------------------------------------
/*/{Protheus.doc}  Cn121LtMed()
	Retorna o limite da medição respeitando o nivel de planilha e de tipo de contrato.
Autor: Kaique Schiller Olivero

/*/
//------------------------------------------------------------------------------//
Function Cn121LtMed( nSaldo, cNumCtr, cRevCtr, cNumPla, nValPrev )
Local nLmtMed	:= 0
Local nVlrRet	:= 0
Default nSaldo 	:= 0
Default cNumCtr := ""
Default cRevCtr	:= ""
Default cNumPla	:= ""
Default nValPrev := nSaldo

If nValPrev == 0
	nValPrev := nSaldo
EndIf

If nSaldo <> 0 .And. !Empty(cNumCtr)
	dbSelectArea("CNA")
	CNA->(dbSetOrder(1)) //CNA_FILIAL+CNA_CONTRA+CNA_REVISA+CNA_NUMERO
	If CNA->(dbSeek(xFilial("CNA")+cNumCtr+cRevCtr+cNumPla))
		dbSelectArea("CNL")
		CNL->(dbSetOrder(1)) //CNL_FILIAL+CNL_CODIGO
		If CNL->(dbSeek(xFilial("CNL")+CNA->CNA_TIPPLA))
			nLmtMed := CNL->CNL_LMTMED
		Endif
	Endif

	If nLmtMed == 0
		dbSelectArea("CN9")
		CN9->(dbSetOrder(1)) //CN9_FILIAL+CN9_NUMERO+CN9_REVISA
		If CN9->(dbSeek(xFilial("CN9")+cNumCtr+cRevCtr))
			dbSelectArea("CN1")
			CN1->(dbSetOrder(1)) //CN1_FILIAL+CN1_CODIGO+CN1_ESPCTR
			If CN1->(dbSeek(xFilial("CN1")+CN9->CN9_TPCTO))
				nLmtMed := CN1->CN1_LMTMED
			Endif
		Endif
	Endif
Endif

If nLmtMed > 0
	nVlrRet := nValPrev + ( ( nValPrev * nLmtMed ) / 100 )
	
	If nVlrRet > nSaldo
		nVlrRet := nSaldo
	EndIf
Else
	nVlrRet := nValPrev
Endif

Return nVlrRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121GrvAd()
Função para identificação de Medições de Serviços.
@author israel.escorizza
@since 11/08/2015
@version 1.0
@Return FwExecView
/*/
//-------------------------------------------------------------------
Function Cn121GrvAd(aAdiants,nOpc,cNumAd)
Local aArea 	:= GetArea()
Local oModel	:= Nil
Local cFilMed	:= ""
Local cContra	:= ""
Local cRevisa	:= ""
Local cNumMed	:= ""
Local cNumPla	:= ""
Local cNumAdt 	:= ""
Local cQuery	:= ""

Local aAdts		:= {}

Local nValor	:= 0
Local nDif		:= 0
Local nI 		:= 0
Local nJ		:= 0
Local nVlrAdi   := 0
Local nZ		:= 0

Local lInc 		:= .F.
Local lAltVlr	:= .F.

Default cNumAd := ""

oModel	:= FwModelActive()
cContra	:= oModel:GetValue("CNDMASTER", "CND_CONTRA")
cRevisa	:= oModel:GetValue("CNDMASTER", "CND_REVISA")
cNumMed	:= oModel:GetValue("CNDMASTER", "CND_NUMMED")

If Type('cFilCtr') == 'C'
	cFilMed := cFilCtr
Else
	cFilMed := cFilAnt
EndIf

nOpc 	:= oModel:GetOperation()

If nOpc <> MODEL_OPERATION_DELETE .And. Empty(cNumAd)
	For nI := 1 To Len(aAdiants)
		cNumPla	:= aAdiants[nI,1,1]
		For nJ := 1 To Len (aAdiants[nI,1,2])
			lInc    := .F.
			lAltVlr := .F.
			cNumero := aAdiants[nI,1,2,nJ,1]
			nValor  := aAdiants[nI,1,2,nJ,2]

			If nOpc == MODEL_OPERATION_INSERT
				DbSelectArea("CZY")
				CZY->(DbsetOrder(2))
				If !CZY->(MsSeek(cFilMed+cContra+cRevisa+cNumMed+cNumPla+cNumero))
					RecLock( "CZY", .T. )
					CZY->CZY_FILIAL := cFilMed
					CZY->CZY_CONTRA := cContra
					CZY->CZY_REVISA := cRevisa
					CZY->CZY_NUMMED := cNumMed
					CZY->CZY_NUMPLA := cNumPla
					CZY->CZY_NUMERO := cNumero
					CZY->CZY_VALOR  := nValor
					CZY->( MsUnlock() )

					DbSelectArea("CNX")
					CNX->(DbsetOrder(1))
					If CNX->(MsSeek(xFilial("CNX",cFilMed)+cContra+cNumero))
						Reclock("CNX",.F.)
						CNX->CNX_SALDO := CNX->CNX_SALDO - nValor
						CNX->(MsUnlock())
					EndIf
				EndIf
			ElseIf nOpc == MODEL_OPERATION_UPDATE .Or. IsInCallStack('CN121Encerr')
				DbSelectArea("CZY")
				CZY->(DbsetOrder(2))
				If CZY->(MsSeek(cFilMed+cContra+cRevisa+cNumMed+cNumPla+cNumero))
					If 	nValor <> CZY->CZY_VALOR
						lAltVlr := .T.
						nDif := nValor - CZY->CZY_VALOR
						RecLock( "CZY", .F. )
						CZY->CZY_VALOR  := nValor
						CZY->( MsUnlock() )
					EndIf
				Else
					lInc := .T.
					//-- Caso seja alteração e não encontrei o registro, inclui.
					RecLock( "CZY", .T. )
					CZY->CZY_FILIAL := cFilMed
					CZY->CZY_CONTRA := cContra
					CZY->CZY_REVISA := cRevisa
					CZY->CZY_NUMMED := cNumMed
					CZY->CZY_NUMPLA := cNumPla
					CZY->CZY_NUMERO := cNumero
					CZY->CZY_VALOR  := nValor
					CZY->( MsUnlock() )
				EndIf

				DbSelectArea("CNX")
				CNX->(DbsetOrder(1))
				If CNX->(MsSeek(xFilial("CNX",cFilMed)+cContra+cNumero))
					Reclock("CNX",.F.)
					If lInc
						CNX->CNX_SALDO := CNX->CNX_SALDO - nValor
					ElseIf lAltVlr
						CNX->CNX_SALDO := CNX->CNX_SALDO - nDif
					EndIf
					CNX->(MsUnlock())
				EndIf
			EndIf
		Next nJ
	Next nI
Else
	cQuery := " SELECT CZY.R_E_C_N_O_ as RECNO, "
	cQuery += " CZY_NUMERO, "
	cQuery += " CZY.CZY_VALOR "
	cQuery += " FROM "+RetSQLName("CZY")+" CZY "
	cQuery += " WHERE CZY.CZY_FILIAL = '"+xFilial("CND",cFilMed)+"' "
	cQuery += " AND CZY.CZY_CONTRA = '"+cContra+"' "
	cQuery += " AND CZY.CZY_NUMMED = '"+cNumMed+"' "

	If !Empty(cNumAd)
		cQuery += " AND CZY.CZY_NUMERO = '"+cNumAd+"' "
	EndIf

	cQuery += " AND CZY.D_E_L_E_T_ = ''"

	cQuery := ChangeQuery(cQuery)

	dbUseArea( .t., "TOPCONN", TcGenQry( ,,cQuery ), "TRBCZY", .f., .t. )
	dbSelectArea("CZY")
	While !TRBCZY->(Eof())
		dbGoto(TRBCZY->RECNO)
		Aadd(aAdts, {TRBCZY->CZY_NUMERO, TRBCZY->CZY_VALOR})

		RecLock("CZY", .F.)
		dbDelete()
		CZY->(MsUnlock())

		TRBCZY->(dbSkip())
	EndDo

	//Se não encontrar adiantamento na medição, não é necessário atualizar saldos.
	If Len(aAdts) == 0
		TRBCZY->(dbCloseArea())
		Return
	EndIf

	cQuery := ""
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Filtra Adiantamentos                           ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cQuery := " SELECT CNX.R_E_C_N_O_ as RECNO "
	cQuery += " FROM "+RetSQLName("CNX")+" CNX "
	cQuery += " WHERE CNX.CNX_FILIAL = '"+xFilial("CNX",cFilMed)+"'"
	cQuery += " AND CNX.CNX_CONTRA = '"+cContra+"'"
	cQuery += " AND CNX.D_E_L_E_T_ = ''"

	If !Empty(cNumAd)
		cQuery += " AND CNX.CNX_NUMERO = '"+cNumAd+"'"
	EndIf

	cQuery := ChangeQuery(cQuery)
	dbUseArea( .t., "TOPCONN", TcGenQry( ,,cQuery ), "TRBCNX", .f., .t. )

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Atualiza os Adiantamentos do Contrato                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	dbSelectArea("CNX")
	While !TRBCNX->(Eof())
		dbGoto(TRBCNX->RECNO)
		nVlrAdi := 0
		nPos := aScan( aAdts, {|x| AllTrim(x[1]) == CNX->CNX_NUMERO  } )
		If nPos > 0
			For nZ := 1 To Len(aAdts)
				nVlrAdi += aAdts[nZ,2]
			Next nZ
			RecLock("CNX", .F.)
			CNX->CNX_SALDO := CNX->CNX_SALDO + nVlrAdi
			CNX->(MsUnlock())
		EndIf
		TRBCNX->(dbSkip())
	EndDo

	TRBCZY->(dbCloseArea())
	TRBCNX->(dbCloseArea())
EndIf

RestArea(aArea)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121OriMd()
Função para identificar se medição veio do CNTA120 ou CNTA121
@author israel.escorizza/Alessandro Honda
@since 29/06/2017
@version 1.0
@Return lRet
/*/
//-------------------------------------------------------------------
Function Cn121OriMd(cOrigem)
Local lRet	:= .F.
Local aArea	:= GetArea()
Local aAreaCXN	:= {}
Local lnotTEC930 := !lMedicao

Default cOrigem := ""

dbSelectArea('CXN')

aAreaCXN := CXN->(GetArea())

CXN->(dbSetOrder(1))	//- CXN_FILIAL+CXN_CONTRA+CXN_REVISA+CXN_NUMMED+CXN_NUMPLA
If cOrigem == 'CNTA120' .And. !(CXN->(dbSeek(xFilial('CXN')+CND->(CND_CONTRA+CND_REVISA+CND_NUMMED)))).And. lnotTEC930
 	lRet := .T.
Else
	lRet := .F.
EndIf

RestArea(aAreaCXN)
RestArea(aArea)

Return lRet

//---------------------------------------------------------------------
/*/{Protheus.doc} CN121TPed()
Função para verificar se ao menos um item da planilha esta configurado
para gerar pedido.

@author jose.delmondes
@since 07/08/2017
@version 1.0
@Return Logico: True -> Sera gerado ao menos um pedido para a planilha.
				  False -> Nao sera gerado pedido para a planilha.
/*/
//---------------------------------------------------------------------
Static Function CN121TPed( oModel )
Local lRet := .F.
Local nX	:= 0
Local aSaveLines	:= FwSaveRows()

For nX := 1 To oModel:Length()
	If oModel:GetValue('CNE_PEDTIT') == '1'
		lRet := .T.
		Exit
	EndIf
Next nX

FWRestRows(aSaveLines)

Return lRet

//-----------------------------------------------------------------------
/*/{Protheus.doc} CN121DcItf()
Função para verificar se o desconto será aplicado no pedido ou no título
gerado pela NF.

@author jose.delmondes
@since 07/08/2017
@version 1.0
@Return Logico: True -> Deconto deve ser aplicado no pedido
				  False -> Desconto sera aplicado no título gerado pela NF
/*/
//-----------------------------------------------------------------------
Static Function CN121DcItf( oModel )
Local lRet := .F.
Local aArea := GetArea()
Local aAreaCNP := {}

dbSelectArea('CNP')

aAreaCNP := CNP->(GetArea())

dbSetorder(1)

If dbSeek( xFilial('CNP') + oModel:GetValue('CNQ_TPDESC') )
	lRet := CNP->CNP_FLGPED == '1'
Endif

RestArea( aAreaCNP )
RestArea( aArea )

Return lRet

//-----------------------------------------------------------------------
/*/{Protheus.doc} CN121InCau()
Grava Caução Retida

@author jose.delmondes
@since 11/08/2017
@version 1.0
@Return
/*/
//-----------------------------------------------------------------------
Static Function CN121InCau(oModel)

Local oModelCND		:= oModel:GetModel("CNDMASTER")
Local oModelCXN		:= oModel:GetModel("CXNDETAIL")

Local lCn120IncCa 	:= ExistBlock("CN120INCCA")
Local lGrvCau     	:= .T.

Local nX			:= 0

//Ponto de entrada para indicar se grava ou não a retencao de caucao
If ExistBlock("CN120GRVCA")
	lGrvCau := ExecBlock("CN120GRVCA",.F.,.F.)
	If ValType(lGrvCau) <> "L"
		lGrvCau := .T.
	EndIf
EndIf

If lGrvCau

	dbSelectArea("CNT")

	For nX := 1 To oModelCXN:Length()

		oModelCXN:GoLine(nX)

		RecLock("CNT",.T.)

			CNT->CNT_FILIAL := xFilial("CNT", oModelCND:GetValue('CND_FILCTR'))
			CNT->CNT_CONTRA := oModelCND:GetValue('CND_CONTRA')
			CNT->CNT_NUMMED := oModelCND:GetValue('CND_NUMMED')
			CNT->CNT_NUMPLA := oModelCXN:GetValue('CXN_NUMPLA')
			CNT->CNT_VLRET  := oModelCND:GetValue('CND_RETCAC') * (oModelCXN:GetValue('CXN_VLLIQD') / oModelCND:GetValue('CND_VLLIQD'))
			CNT->CNT_DTMED  := dDataBase
			CNT->CNT_FORNEC := oModelCXN:GetValue('CXN_FORNEC')
			CNT->CNT_LJFORN := oModelCXN:GetValue('CXN_LJFORN')
			CNT->CNT_CLIENT := oModelCXN:GetValue('CXN_CLIENT')
			CNT->CNT_LOJACL := oModelCXN:GetValue('CXN_LJCLI')

			If lCn120IncCa
				ExecBlock("CN120INCCA",.F.,.F.)
			Endif

			//Executa contabilizacao da retencao do contrato
			CN120Contab( '695' )

		CNT->(MsUnlock())

	Next nX

EndIf

Return

//-----------------------------------------------------------------------
/*/{Protheus.doc} SetExcedP()
Inicializa variavel lExcedPrv (Excedente para competencia prevista)

@author jose.delmondes
@since 15/08/2017
@version 1.0
@Return Nao possui
/*/
//-----------------------------------------------------------------------
Function SetExcedME(lConteudo)
lExcedMEnc	:= lConteudo
Return

//-----------------------------------------------------------------------
/*/{Protheus.doc} SetExcedP()
Inicializa variavel lExcedNPrv (Excedente para competencia não prevista)

@author jose.delmondes
@since 15/08/2017
@version 1.0
@Return Nao possui
/*/
//-----------------------------------------------------------------------
Function SetExcedNP(lConteudo)
lExcedNPrv := lConteudo
Return

//-----------------------------------------------------------------------
/*/{Protheus.doc} IsExced()
Verifica se a medição é Excedente

@author jose.delmondes
@since 15/08/2017
@version 1.0
@Return Logico:   True: eh excedente
                  False: Nao eh excedente
/*/
//-----------------------------------------------------------------------
Function IsExced()

lRet := lExcedMEnc .Or. lExcedNPrv
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121VldCalc
Função para validação do calculo dos campos totalizadores
@author israel.escorizza
@since 17/08/2017
@version V12.1.17
@return lRet
/*/
//--------------------------------------------------------------------
Function Cn121VldCalc(FModel)
Local lRet := FModel:GetValue('CXNDETAIL','CXN_CHECK')
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121VlrTt
Função para calculo do totalizador com atualização do valor total
@author israel.escorizza
@since 17/08/2017
@version V12.1.17
@return lRet
/*/
//--------------------------------------------------------------------
Function Cn121VlrTt(oModel,nVlrAtu,xValor,lSoma,cIdField)
If xValor > 0
	nVlrAtu += xValor * Iif(lSoma,1,-1)
	Cn121VlrMd(oModel,nVlrAtu,xValor,lSoma,cIdField)
EndIf
Return nVlrAtu

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121VlrMd
Função para calculo do totalizador valor total e Retenção da caução
@author israel.escorizza
@since 17/08/2017
@version V12.1.17
@return lRet
/*/
//--------------------------------------------------------------------
Function Cn121VlrMd(oModel,nVlrAtu,xValor,lSoma,cIdField)
Local oModelCND := oModel:GetModel('CNDMASTER')
Local oModelTOT := oModel:GetModel('TOTMED')
Local nModCt	:= IIf(Cn300RetSt('COMPRA',0,,oModelCND:GetValue('CND_CONTRA')),1,-1)
Local nVlLiqd	:= oModelTOT:GetValue('CND_VLLIQD')
Local nTotMul	:= oModelTOT:GetValue('CND_VLMULT')
Local nTotBon	:= oModelTOT:GetValue('CND_VLBONI')
Local nTotDes	:= oModelTOT:GetValue('CND_DESCME')
Local nTotAdt	:= oModelTOT:GetValue('CND_TOTADT')
Local nVlrTot	:= 0
Local nRetCau	:= 0

DO 	CASE
	CASE cIdField == 'CND_VLLIQD'
		nVlLiqd := nVlrAtu
	CASE cIdField == 'CND_VLMULT'
		nTotMul := nVlrAtu
	CASE cIdField == 'CND_VLBONI'
		nTotBon := nVlrAtu
	CASE cIdField == 'CND_DESCME'
		nTotDes := nVlrAtu
	CASE cIdField == 'CND_TOTADT'
		nTotAdt := nVlrAtu
ENDCASE

//Regras de aplicação de multa, desconto e bonificação
//Contratos de Compra:	Multas(-)|Bonificação(+)|Desconto(-)|Adiantamento(-)|Retenção(-)
//Contratos de Venda :  Multas(+)|Bonificação(-)|Desconto(-)|Adiantamento(-)|Retenção(-)
nVlrTot	:= nVlLiqd + ((nTotBon - nTotMul) * nModCt) - nTotDes - nTotAdt
nRetCau	:= CN121RetCa( nVlrTot, oModel )

If cIdField != 'CND_RETCAC' .And. oModel:GetOperation() != MODEL_OPERATION_DELETE
	If nRetCau > 0
		oModelCND:LoadValue('CND_RETCAC',nRetCau)
		nVlrTot -= nRetCau
	Else
		oModelCND:LoadValue('CND_RETCAC',0)
	EndIf

	If cIdField != 'CND_VLTOT'
		oModelTOT:LoadValue('CND_VLTOT',nVlrTot)
	EndIf
Else
	nVlrTot := nRetCau
EndIf

Return nVlrTot

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121AutEnc
Função para desbloquear movimentações financeiras encerrada Aut. Fornecimento.
@author israel.escorizza
@since 22/08/2017
@version V12.1.17
@return lRet
/*/
//--------------------------------------------------------------------
Function Cn121AutEnc(nReg,lAviso)
Local cQuery 	:= ""
Local cPedidos 	:= ""
local cAliasQry := ""
Local cAliasSD1	:= ""
Local cAliasSE2	:= ""

Local lGCTBloq 	:= SE2->(FieldPos("E2_MSBLQL")) > 0 //- Valida bloqueio de movimentação financeira pelo GCT
Local lBloqSE2  := .F.

Default lAviso 	:= .T.

Begin Transaction
	dbSelectArea("CND")
	CND->(MsGoTo(nReg)) //-- Posiciona na medicao

	RecLock('CND')
	CND->CND_SITUAC := 'FE'
	CND->CND_DTFIM 	:= dDataBase
	CND->(MsUnlock())

	cQuery := " SELECT DISTINCT "
	cQuery += " CXJ_NUMPED "
	cQuery += " FROM "
	cQuery += RetSQLName("CXJ") + " CXJ "
	cQuery += " WHERE CXJ.CXJ_NUMMED = '"+CND->CND_NUMMED+"' AND CXJ.D_E_L_E_T_ = '' "

	cQuery    := ChangeQuery( cQuery )
	cAliasQry := GetNextAlias()
	dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQuery ), cAliasQry, .F., .T. )

	While !(cAliasQry)->(Eof())
		If !Empty(cPedidos)
			cPedidos += ", "
		EndIf
		cPedidos += "'"+(cAliasQry)->CXJ_NUMPED+"'""
		(cAliasQry)->(dbSkip())
	End
	(cAliasQry)->(dbCloseArea())

	//- Seleciona a nota
	cQuery := " SELECT DISTINCT "
	cQuery += " SF1.F1_DOC, 	"
	cQuery += " SF1.F1_SERIE, 	"
	cQuery += " SF1.F1_TIPO,	"
	cQuery += " SF1.F1_DUPL,	"
	cQuery += " SF1.F1_PREFIXO,	"
	cQuery += " F1_FORNECE, 	"
	cQuery += " F1_LOJA 		"

	cQuery += " FROM "
	cQuery += RetSQLName("SF1") + " SF1, "
	cQuery += RetSQLName("SD1") + " SD1 "

	cQuery += " WHERE
	cQuery += " SF1.F1_FILIAL  = '"+xFilial("SF1")+"' 	AND "
	cQuery += " SD1.D1_FILIAL  = '"+xFilial("SD1")+"' 	AND "
	cQuery += " SF1.F1_DOC     = SD1.D1_DOC     		AND "
	cQuery += " SF1.F1_SERIE   = SD1.D1_SERIE   		AND "
	cQuery += " SF1.F1_TIPO    = SD1.D1_TIPO    		AND "
	cQuery += " SF1.F1_FORNECE = SD1.D1_FORNECE 		AND "
	cQuery += " SF1.F1_LOJA    = SD1.D1_LOJA    		AND "
	cQuery += " SD1.D1_PEDIDO  IN ("+cPedidos+") 		AND "
	cQuery += " SF1.D_E_L_E_T_ = ' ' 					AND "
	cQuery += " SD1.D_E_L_E_T_ = ' '"

	cQuery    := ChangeQuery( cQuery )
	cAliasQry := GetNextAlias()
	dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQuery ), cAliasQry, .F., .T. )

	If !(cAliasQry)->(Eof())
		//³ Seleciona os pedidos relacionados na mesma nota   ³
		cQuery := " SELECT DISTINCT SD1.D1_PEDIDO "
		cQuery += " FROM " + RetSQLName("SD1") + " SD1 "
		cQuery += " WHERE "
		cQuery += " SD1.D1_FILIAL 	= 	'" + xFilial("SD1") + "' 		AND "
		cQuery += " SD1.D1_DOC		= 	'" + (cAliasQry)->F1_DOC + "' 	AND "
		cQuery += " SD1.D1_SERIE  	= 	'" + (cAliasQry)->F1_SERIE + "' AND "
		cQuery += " SD1.D1_TIPO   	= 	'" + (cAliasQry)->F1_TIPO + "' 	AND "
		cQuery += " SD1.D1_PEDIDO 	NOT IN 	("+cPedidos+") 	AND "
		cQuery += " SD1.D_E_L_E_T_ 	= 	' '"

		cQuery    := ChangeQuery( cQuery )
		cAliasSD1 := GetNextAlias()
		dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQuery ), cAliasSD1, .F., .T. )

		While !(cAliasSD1)->(Eof())
			dbSelectArea("SC7")
			SC7->(dbSetOrder(1))
			If SC7->(MsSeek(cFilSC7+(cAliasSD1)->D1_PEDIDO))
				//³ Verifica se o pedido foi originado por uma medicao³
				If !Empty(SC7->C7_CONTRA)
					dbSelectArea("CND")
					CND->(dbSetOrder(1))

					//³ Posiciona na Medicao ³
					If CND->(MsSeek(cFilCND+SC7->(C7_CONTRA+C7_CONTREV+C7_PLANILH+C7_MEDICAO)))
						//³ Quando houver alguma medicao NAO encerrada impede o desbloqueio dos titulos ³
						If Empty(CND->CND_DTFIM)
							lBloqSE2 := .T.
							Exit
						EndIf
					EndIf
				EndIf
			EndIf
			(cAliasSD1)->(dbSkip())
		EndDo
		(cAliasSD1)->(dbCloseArea())

		//³ Desbloqueia os titulos ³
		If !lBloqSE2 .And. lGCTBloq
			//³ Seleciona os titulos ³
			cQuery := "	SELECT SE2.R_E_C_N_O_ AS RECNO "
			cQuery += " FROM " + RetSQLName("SE2") + " SE2 "
			cQuery += " WHERE "
			cQuery += " SE2.E2_FILIAL  		= '" + xFilial("SE2") + "'"
			cQuery += " AND SE2.E2_NUM     	= '" + (cAliasQry)->F1_DUPL + "'"
			cQuery += " AND SE2.E2_PREFIXO 	= '" + IIf(Empty((cAliasQry)->F1_PREFIXO),&(SuperGetMV("MV_2DUPREF")),(cAliasQry)->F1_PREFIXO) + "'"
			cQuery += " AND SE2.E2_FORNECE 	= '" + (cAliasQry)->F1_FORNECE + "'"
			cQuery += " AND SE2.E2_LOJA    	= '" + (cAliasQry)->F1_LOJA + "'"
			cQuery += " AND SE2.E2_TIPO    	= 'NF '"
			cQuery += " AND SE2.D_E_L_E_T_ 	= ' ' "

			cQuery    := ChangeQuery( cQuery )
			cAliasSE2 := GetNextAlias()
			dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQuery ), cAliasSE2, .F., .T. )

			//³ Desbloqueia os titulos ³
			While !(cAliasSE2)->(Eof())
				SE2->( MsGoTo( (cAliasSE2)->RECNO ) )
				RecLock("SE2",.F.)
				SE2->E2_MSBLQL := "2"
				MsUnlock()
				(cAliasSE2)->(dbSkip())
			EndDo
			(cAliasSE2)->(dbCloseArea())
		EndIf
	EndIf
	(cAliasQry)->(dbCloseArea())

End Transaction
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121AutEst
Função para estornar Aut. Fornecimento.
@author israel.escorizza
@since 22/08/2017
@version V12.1.17
@return lRet
/*/
//--------------------------------------------------------------------
Function Cn121AutEst(nReg, lAviso)
Local cQuery 	:= ""
Local cPedidos 	:= ""
local cAliasQry := ""
Local cAliasSE2	:= ""

Local lGCTBloq 	:= SE2->(FieldPos("E2_MSBLQL")) > 0 //- Valida bloqueio de movimentação financeira pelo GCT
Local lBloqSE2  := .F.
Local lRet 		:= .T.

Default lAviso	:= .T.

Begin Transaction
	dbSelectArea("CND")
	CND->(MsGoTo(nReg)) //-- Posiciona na medicao

	cQuery := " SELECT DISTINCT "
	cQuery += " CXJ_NUMPED "
	cQuery += " FROM "
	cQuery += RetSQLName("CXJ") + " CXJ "
	cQuery += " WHERE CXJ.CXJ_NUMMED = '"+CND->CND_NUMMED+"' AND CXJ.D_E_L_E_T_ = '' "

	cQuery    := ChangeQuery( cQuery )
	cAliasQry := GetNextAlias()
	dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQuery ), cAliasQry, .F., .T. )

	While !(cAliasQry)->(Eof())
		If !Empty(cPedidos)
			cPedidos += ", "
		EndIf
		cPedidos += "'"+(cAliasQry)->CXJ_NUMPED+"'""
		(cAliasQry)->(dbSkip())
	End
	(cAliasQry)->(dbCloseArea())

	//- Seleciona a nota
	cQuery := " SELECT DISTINCT "
	cQuery += " SF1.F1_DOC, 	"
	cQuery += " SF1.F1_SERIE, 	"
	cQuery += " SF1.F1_TIPO,	"
	cQuery += " SF1.F1_DUPL,	"
	cQuery += " SF1.F1_PREFIXO,	"
	cQuery += " F1_FORNECE, 	"
	cQuery += " F1_LOJA 		"

	cQuery += " FROM "
	cQuery += RetSQLName("SF1") + " SF1, "
	cQuery += RetSQLName("SD1") + " SD1 "

	cQuery += " WHERE
	cQuery += " SF1.F1_FILIAL  = '"+xFilial("SF1")+"' 	AND "
	cQuery += " SD1.D1_FILIAL  = '"+xFilial("SD1")+"' 	AND "
	cQuery += " SF1.F1_DOC     = SD1.D1_DOC     		AND "
	cQuery += " SF1.F1_SERIE   = SD1.D1_SERIE   		AND "
	cQuery += " SF1.F1_TIPO    = SD1.D1_TIPO    		AND "
	cQuery += " SF1.F1_FORNECE = SD1.D1_FORNECE 		AND "
	cQuery += " SF1.F1_LOJA    = SD1.D1_LOJA    		AND "
	cQuery += " SD1.D1_PEDIDO  IN ("+cPedidos+") 		AND "
	cQuery += " SF1.D_E_L_E_T_ = ' ' 					AND "
	cQuery += " SD1.D_E_L_E_T_ = ' '"

	cQuery    := ChangeQuery( cQuery )
	cAliasQry := GetNextAlias()
	dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQuery ), cAliasQry, .F., .T. )

	If !(cAliasQry)->(Eof())
		//- Verifica os valores dos titulos
		cQuery := " SELECT SUM(E2_VALOR) AS E2_VALOR,SUM(E2_SALDO) AS E2_SALDO "
		cQuery += " FROM " + RetSQLName("SE2") + " SE2 "
		cQuery += " WHERE SE2.E2_FILIAL  = '" + xFilial("SE2") + "'"
		cQuery += " AND SE2.E2_NUM     = '" + (cAliasQry)->F1_DUPL + "'"
		cQuery += " AND SE2.E2_PREFIXO = '" + IIf(Empty((cAliasQry)->F1_PREFIXO),&(SuperGetMV("MV_2DUPREF")),(cAliasQry)->F1_PREFIXO) + "'"
		cQuery += " AND SE2.E2_FORNECE = '" + (cAliasQry)->F1_FORNECE + "'"
		cQuery += " AND SE2.E2_LOJA    = '" + (cAliasQry)->F1_LOJA + "'"
		cQuery += " AND SE2.E2_TIPO    = 'NF '"
		cQuery += " AND SE2.D_E_L_E_T_ = ' '"

		cQuery    := ChangeQuery( cQuery )
		cAliasSE2 := GetNextAlias()
		dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQuery ), cAliasSE2, .F., .T. )

		TCSetField( cAliasSE2, "E2_VALOR", "N", TamSX3("E2_VALOR")[1], TamSX3("E2_VALOR")[2] )
		TCSetField( cAliasSE2, "E2_SALDO", "N", TamSX3("E2_SALDO")[1], TamSX3("E2_SALDO")[2] )

		//- Verifica se houve movimentacoes nos titulos
		If (cAliasSE2)->E2_VALOR > (cAliasSE2)->E2_SALDO
			If lAviso
				Aviso("CNTA121",OemToAnsi(STR0160)+(cAliasQry)->F1_DOC+"/"+ SerieNfID("SF1", 2, "F1_SERIE") +OemToAnsi(STR0161),{STR0156})//STR0160"Não foi possível estornar a autorização de fornecimento, pois a NFE: "##" possui movimentações financeiras."
				lRet := .F.
			EndIf
			lBloqSE2 := .T.
		EndIf
		(cAliasSE2)->(dbCloseArea())

		If !lBloqSE2 .And. lGCTBloq
			//- Seleciona os titulos
			cQuery := " SELECT SE2.R_E_C_N_O_ AS RECNO "
			cQuery += " FROM " + RetSQLName("SE2") + " SE2 "
			cQuery += " WHERE SE2.E2_FILIAL  = '" + xFilial("SE2") + "'"
			cQuery += " AND SE2.E2_NUM     = '" + (cAliasQry)->F1_DUPL + "'"
			cQuery += " AND SE2.E2_PREFIXO = '" + IIf(Empty((cAliasQry)->F1_PREFIXO),&(SuperGetMV("MV_2DUPREF")),(cAliasQry)->F1_PREFIXO) + "'"
			cQuery += " AND SE2.E2_FORNECE = '" + (cAliasQry)->F1_FORNECE + "'"
			cQuery += " AND SE2.E2_LOJA    = '" + (cAliasQry)->F1_LOJA + "'"
			cQuery += " AND SE2.E2_TIPO    = 'NF '"
			cQuery += " AND SE2.D_E_L_E_T_ = ' '"

			cQuery    := ChangeQuery( cQuery )
			cAliasSE2 := GetNextAlias()
			dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQuery ), cAliasSE2, .F., .T. )

			//- Bloqueia os titulos
			While !(cAliasSE2)->(Eof())
				SE2->(MsGoTo((cAliasSE2)->RECNO))
				RecLock("SE2",.F.)
					SE2->E2_MSBLQL := "1"
				MsUnlock()
				(cAliasSE2)->(dbSkip())
			EndDo
			(cAliasSE2)->(dbCloseArea())
		EndIf

	EndIf
	(cAliasQry)->(dbCloseArea())

	If !lBloqSE2
		RecLock("CND",.F.)
		CND->CND_DTFIM 	:= CTOD("")
		CND->CND_SITUAC := "FA"
		MsUnlock()
	EndIf
End Transaction

If lRet .And. lAviso
	Aviso("CNTA121",OemToAnsi(STR0113),{STR0156})	//"Autorização de fornecimento estornada com sucesso"
EndIf

Return

//-----------------------------------------------------------------------
/*/{Protheus.doc} GCTExcedNP(cNumMed)
Verifica se todos os itens da medição são excedentes
(Excedente para competencia não prevista)

@author jose.delmondes
@since 23/08/2017
@version 1.0
@Return Logico:   True: Eh uma medição de excedente para competência não prevista
                  False: Nao eh uma medição de excedente para competência não prevista
/*/
//-----------------------------------------------------------------------
Function GCTExcedNP(cNumMed)
Local lRet	:= .F.
Local cAliasCNE	:= GetNextAlias()

//Conta a quantidade de itens não excedentes da medição
BeginSQL alias cAliasCNE

SELECT	COUNT(*) AS QTD
FROM 	%table:CNE% CNE
WHERE	CNE.CNE_NUMMED = %Exp:cNumMed% AND
		CNE.CNE_EXCEDE <> '1' AND
		CNE.%NotDel%

EndSQL

//Se não houver nenhum item que não seja excedente, a medição é considerada como excedente para competencia não prevista
IF (cAliasCNE)->QTD == 0
	lRet := .T.
EndIf

(cAliasCNE)->(dbCloseArea())

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121GAutF()
Função para retornar o valor da variavel estatica lAutForn
@author israel.escorizza
@since 24/08/2017
@version V12.1.17
@return lAutForn
/*/
//--------------------------------------------------------------------
Function Cn121GAutF()
Return lAutForn

//-------------------------------------------------------------------
/*/{Protheus.doc} Cn121DelPed()
Função para validar exclusão do pedido
@author israel.escorizza
@since 24/08/2017
@version V12.1.17
@return lRet
/*/
//--------------------------------------------------------------------
Function Cn121DelPed(oModel)
Local aArea 	:= GetArea()
Local aAreaSC7	:= SC7->(GetArea())
Local aSaveLines:= FWSaveRows()
Local cAliasTemp:= GetNextAlias()
Local cFilMed	:= ""
Local cNumMed	:= ""
Local lRet		:= .T.

Default oModel	:= FwModelActive()

cFilMed	:= oModel:GetValue('CNDMASTER','CND_FILIAL')
cNumMed	:= oModel:GetValue('CNDMASTER','CND_NUMMED')

BeginSQL Alias cAliasTemp
SELECT DISTINCT C7_NUM
FROM %Table:SC7%
	WHERE %NotDel% AND
	C7_FILIAL  = %Exp:cFilMed% AND
	C7_MEDICAO = %Exp:cNumMed%
EndSQL

dbSelectArea('SC7')
SC7->(dbSetOrder(1))
While lRet .And. (cAliasTemp)->(!Eof())
	If SC7->(MsSeek(cFilMed+(cAliasTemp)->C7_NUM))
		lRet := MaCanDelPC("SC7")
	EndIf
	(cAliasTemp)->(dbSkip())
End

(cAliasTemp)->(dbClosearea())

FWRestRows(aSaveLines)
RestArea(aAreaSC7)
RestArea(aArea)
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121CondC()
Função para tratar condição de execução do gatilho das entidades contábeis
para medições que permitam informar o produto.

@author Israel Escorizza
@since 31/10/2017
@return lRet
/*/
//-------------------------------------------------------------------
Function CN121CondC()
Local lRet 		:= .F.
Local lModel	:= .F.
Local lSemiAgr	:= .F.
Local lFlex		:= .F.

Local cFilCtr	:= ""
Local cContra 	:= ""
Local cPlan		:= ""

Local oModel 	:= Nil

DO 	CASE
 	CASE IsInCallStack('CNTA121')
 		 oModel		:= FwModelActive()
		 cFilCtr	:= oModel:GetValue('CNDMASTER','CND_FILCTR')
		 cContra 	:= oModel:GetValue('CNDMASTER','CND_CONTRA')
		 cPlan		:= oModel:GetValue('CXNDETAIL','CXN_NUMPLA')
		 lModel		:= .T.

	CASE IsInCallStack('CNTA120')
		cFilCtr		:= M->CND_FILCTR
		cContra		:= M->CND_CONTRA
		cPlan		:= M->CND_NUMERO
ENDCASE

lSemiAgr:= Cn300RetSt('SEMIAGRUP',0,cPlan,cContra,cFilCtr,lModel)
lFlex	:= Cn300RetSt('EVENTUAL' ,0,cPlan,cContra,cFilCtr,lModel)

If lFlex .Or. lSemiAgr
	lRet := .T.
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121Liq()
Atualiza o valor líquido dos itens (CNE_VLLIQD)

@author jose.delmondes
@since 21/11/2017
/*/
//-------------------------------------------------------------------
Function Cn121Liq(oModel)

Local oModelCND	:= oModel:GetModel('CNDMASTER')
Local oModelCXN	:= oModel:GetModel('CXNDETAIL')
Local oModelCNE	:= oModel:GetModel('CNEDETAIL')

Local cEspCtr		:= Cn300RetSt( "ESPECIE" , , , oModelCND:GetValue('CND_CONTRA') , oModelCND:GetValue('CND_FILCTR') , .F. )

Local nX	:= 0
Local nY 	:= 0
Local nCaucPla	:= 0
Local nPercCauc	:= 0

Local lExced	:= IsExced()

For nX := 1 To oModelCXN:Length()

	oModelCXN:GoLine(nX)

	If oModelCXN:GetValue('CXN_CHECK')

		//-- Calcula o percentual de caucao para a planilha
		nPercCauc	:= oModelCXN:GetValue('CXN_VLLIQD') / oModelCND:GetValue('CND_VLLIQD')
		nCaucPla	:= nPercCauc * oModelCND:GetValue('CND_RETCAC')

		For nY := 1 To oModelCNE:Length()

			oModelCNE:GoLine(nY)

			//-- Calculo do valor liquido do item
			If !lExced
				nValLiq := CN130Liq( cEspCtr , oModelCNE:GetValue('CNE_VLTOT') , oModelCNE:GetValue('CNE_VLDESC') , oModelCXN:GetValue('CXN_VLLIQD') , oModelCXN:GetValue('CXN_VLMULT') , oModelCXN:GetValue('CXN_VLBONI') , oModelCXN:GetValue('CXN_VLDESC') , nCaucPla ,oModelCXN:GetValue('CXN_VLRADI'))
				oModelCNE:LoadValue( 'CNE_VLLIQD' , nValLiq )
			ElseIf oModelCNE:GetValue('CNE_EXCEDE') == '1'
				oModelCNE:LoadValue( 'CNE_VLLIQD' , oModelCNE:GetValue('CNE_VLTOT')  )
			EndIf

		Next nY

	EndIf

Next nX

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121RatP(oModel)
Função de importação de Rateio Pré-Configurado

@author israel.escorizza
@since 06/12/2017
/*/
//-------------------------------------------------------------------
Function CN121RatP(oModel)
Local aSaveLines	:= FWSaveRows()
Local oModelCNE	:= oModel:GetModel('CNEDETAIL')
Local oModelCNZ	:= oModel:GetModel('CNZDETAIL')

If oModelCNE:IsDeleted() .Or. Empty(oModelCNE:GetValue('CNE_PRODUT'))
	Help("",1,"CN121RATP",,STR0164,4,1)
Else
	AdmRatExt( , , { |x,y,z| GCTRatMVC(x,@y,z) } , oModelCNZ )
EndIf

FWRestRows(aSaveLines)
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} CN121ClrAc()
Apaga o conteúdo da static aComp.
Função utilizada quando há execução em lote.
@author mateus.boiani
@since 21/12/2017
/*/
//-------------------------------------------------------------------
Function CN121ClrAc()
aComp := {}
Return
//==============================================================================================================================
/*/{Protheus.doc} Cn121Track() - Tracker da nova medição
@Param	
@author Israel.Escorizza 
@since 	23/03/2018 
@return Nil
/*/
//==============================================================================================================================
Function Cn121Track(oModel)
Local aArea		:= GetArea() 
Local aSaveLine	:= FWSaveRows()
Local aEnt		:= {}

Local oModelCND	:= Nil
Local cSeekKey 	:= ""

Default oModel := FwModelActive()

If oModel:GetId() == 'CNTA121'
	oModelCND:= oModel:GetModel('CNDMASTER')
	cSeekKey := xFilial("CND") + oModelCND:GetValue('CND_CONTRA') + oModelCND:GetValue('CND_REVISA') + oModelCND:GetValue('CND_NUMMED')

	AAdd( aEnt, { "CND21", cSeekKey} )
	MaTrkShow( aEnt )
Else
	Help(" ",1, 'Help','CN121TRK01',,4,0) 	//- "Modelo ativo invalido"
EndIf


FWRestRows( aSaveLine )     
RestArea(aArea)
Return 
//--------------------------------------------------------------------
/*/{Protheus.doc} VldPedTit()
Valid do campo CNE_PEDTIT

@author jose.delmondes
@since 20/04/2018
@version 1.0
@return Logico			
/*/
//-------------------------------------------------------------------
Function VldPedTit()

Local lRet	:= .T.
Local oModel	:= Nil
Local oModelCNE	:= Nil
Local lCompra	:= .F. 
Local lReinf	:= CNE->( Columnpos('CNE_15ANOS') ) > 0 
Local lAuto	:= IsBlind()

If FUNNAME() == 'CNTA121' .And. lReinf
	
	oModel := FwModelactive()
	oModelCNE := oModel:GetModel('CNEDETAIL')
	
	lCompra	:= CN300RetSt( "COMPRA" , , , oModel:Getvalue( 'CNDMASTER' , 'CND_CONTRA' ) , oModel:Getvalue( 'CNDMASTER' , 'CND_FILCTR' ) , .F. )
	
	If lCompra .And. oModelCNE:GetValue('CNE_PEDTIT') == '1' .And. ( oModelCNE:GetValue('CNE_15ANOS') + oModelCNE:GetValue('CNE_20ANOS') + oModelCNE:GetValue('CNE_25ANOS') ) > 0
		
		If lAuto .Or. ( !lAuto .And. MsgYesNo( 'Os valores de aposentadoria especial serão zerados.' +CRLF+CRLF+ 'Deseja prosseguir com a alteração?' ) )
			oModelCNE:LoadValue( 'CNE_15ANOS' , 0 )
			oModelCNE:LoadValue( 'CNE_20ANOS' , 0 )
			oModelCNE:LoadValue( 'CNE_25ANOS' , 0 )
		Else
			lRet := .F.
        EndIf
	EndIf
EndIf

Return lRet

//==============================================================================================================================
/*/{Protheus.doc} CxnZeroWhe() - Função When do campo CXN_ZERO
@Param	
@author Israel.Escorizza 
@since 	02/05/2018 
@return lRet
/*/
//==============================================================================================================================
Function CxnZeroWhe()
Local  lRet := !Empty(FwFldGet('CXN_CRONOG'))
Return lRet

//==============================================================================================================================
/*/{Protheus.doc} CN121SLDZR(oModel)
Funcao para processamento da medicao zerada
@author jose.delmondes
@since 16/04/2018
@version 1.0
@return 
/*/
//==============================================================================================================================
Function CN121ZERO( cContra , cRevisa , cMed , cPlan , cFilCtr , nOpc )

Local aArea	:= GetArea()
Local aAreaCXN	:= {}
Local aAreaCNF	:= {}
Local lCNPROVI	:= GetNewPar( "MV_CNPROVI" ,  "S" ) == "S"

dbSelectArea('CXN')
aAreaCXN := CXN->(Getarea())
CXN->( dbSetOrder(1) )

If CXN->( dbSeek( xFilial('CXN') + cContra + cRevisa + cMed + cPlan ) )
	
	dbSelectArea('CNF')
	aAreaCNF := CNF->(GetArea())
	CNF->( dbSetOrder(3) )
	
	If CNF->(dbSeek( xFilial('CNF', cFilCtr) + cContra + cRevisa + CXN->CXN_CRONOG + CXN->CXN_PARCEL ))
		
		Do Case
			
			Case nOpc == '1' 	//-- Encerramento da medicao
				
				//-- Exclui titulo provisorio, referente a parcela do cronograma financeiro
				If lCNPROVI
					CN100ETit( cContra , cRevisa , CNF->CNF_NUMERO , CNF->CNF_PARCEL , cFilCtr )
				EndIf
				
				//-- Preenche data de realizacao da parcela
				RecLock("CNF")
					CNF->CNF_DTREAL := dDataBase
				MsUnlock()
				
			Case nOpc == '2'	//-- Estorno da medicao
				
				//-- Gera titulo provisorio
				If lCNPROVI
					CN100CTit( cContra , cRevisa , CNF->CNF_NUMERO , CNF->CNF_PARCEL , CNF->CNF_SALDO , cFilCtr )
				EndIf
				
				//-- Limpa data de realizacao da parcela
				RecLock("CNF")
					CNF->CNF_DTREAL := CTOD("")
				MsUnlock()
		
		EndCase
		
	EndIf
	
	RestArea( aAreaCNF )
	
EndIf

RestArea( aAreaCXN )
RestArea( aArea )

Return

//==============================================================================================================================
/*/{Protheus.doc} Cn121NatTt() - Função responsável por definir a natureza que será encaminhada para o titulo.
@Param	
@author Israel.Escorizza 
@since 	16/05/2018 
@return cRetNat	- Natureza a ser utilizada.
/*/
//==============================================================================================================================
Function Cn121NatTt(lTitPag,aDocs,cFilContr,nPosic)
Local aArea		:= GetArea() 
Local aSaveLine	:= FWSaveRows()

Local lCN121NAT := ExistBlock("CN121NAT")
Local cRetNat	:= ""

//- Variaveis posicionamento no array
Local nNumMed	:= IIf(lTitPag,aScan(aDocs[nPosic,2],{|x|x[1] == 'E2_MEDNUME'}),aScan(aDocs[nPosic,2],{|x|x[1] == 'E1_MEDNUME'}))
Local nNumPla	:= IIf(lTitPag,aScan(aDocs[nPosic,2],{|x|x[1] == 'E2_MDPLANI'}),aScan(aDocs[nPosic,2],{|x|x[1] == 'E1_MDPLANI'}))
Local nContra	:= IIf(lTitPag,aScan(aDocs[nPosic,2],{|x|x[1] == 'E2_MDCONTR'}),aScan(aDocs[nPosic,2],{|x|x[1] == 'E1_MDCONTR'}))
Local nRevisa	:= IIf(lTitPag,aScan(aDocs[nPosic,2],{|x|x[1] == 'E2_MDREVIS'}),aScan(aDocs[nPosic,2],{|x|x[1] == 'E2_MDREVIS'}))
Local nForCli	:= IIf(lTitPag,aScan(aDocs[nPosic,2],{|x|x[1] == 'E2_FORNECE'}),aScan(aDocs[nPosic,2],{|x|x[1] == 'E1_CLIENTE'}))
Local nLoja		:= IIf(lTitPag,aScan(aDocs[nPosic,2],{|x|x[1] == 'E2_LOJA'})   ,aScan(aDocs[nPosic,2],{|x|x[1] == 'E1_LOJA'}))

//- Atribuição de variaveis para utilização
Local cNumMed	:= IIf(nNumMed > 0, aDocs[nPosic,2,nNumMed,2], '')
Local cNumPla	:= IIf(nNumPla > 0, aDocs[nPosic,2,nNumPla,2], '')
Local cContra	:= IIf(nContra > 0, aDocs[nPosic,2,nContra,2], '')
Local cRevisa	:= IIf(nRevisa > 0, aDocs[nPosic,2,nRevisa,2], '')
Local cForCli	:= IIf(nForCli > 0, aDocs[nPosic,2,nForCli,2], '')
Local cLoja		:= IIf(nLoja > 0  , aDocs[nPosic,2,nLoja,2]  , '')

Default cFilContr := cFilCtr

If lCN121NAT //- Executa ponto de entrada para definição de natureza.
	cRetNat := ExecBlock("CN121NAT",.F.,.F.,{xFilial("CND", cFilContr), cNumMed})
Else
	//- Verifica natureza do contrato
	
	cRetNat := POSICIONE('CN9',1,cFilContr+cContra+cRevisa,'CN9_NATURE' )  //- CONTRATO: CN9_FILIAL+CN9_NUMERO+CN9_REVISA
	
	If Empty(cRetNat)
	
		//- Verifica natureza do Cliente/Fornecedor
		If lTitPag
			cRetNat := POSICIONE('SA2',1,xFilial('SA2',cFilContr)+cForCli+cLoja,'A2_NATUREZ') //- FORNECEDOR: A2_FILIAL+A2_COD+A2_LOJA
		Else
			cRetNat := POSICIONE('SA1',1,xFilial('SA1',cFilContr)+cForCli+cLoja,'A1_NATUREZ') //- CLIENTE: A1_FILIAL+A1_COD+A1_LOJA
		EndIf
		
		If Empty(cRetNat)
			
			//- Utiliza a natureza do parametro.
			cRetNat := SuperGetMv("MV_CNNATMD",.F.,"")
		EndIf
	EndIf
	
	//- Garante que o retorno será do tamanho correto do campo.
	cRetNat := PadR(cRetNat, Iif(lTitPag, TAMSX3('E2_NATUREZ')[1], TAMSX3('E1_NATUREZ')[1]))
EndIf

FWRestRows( aSaveLine )     
RestArea(aArea)
Return cRetNat

//-----------------------------------------------------------------------
/*/{Protheus.doc} CN121VParc()
Valida existência de parcela no cronograma financeiro

@author jose.delmondes
@since 22/05/2018
@version 1.0
@Return Logico: 	True -> parcela existe
				  	False -> parcela nao existe
/*/
//-----------------------------------------------------------------------
Function CN121VParc()
Local aArea	:= GetArea()
Local cAliasCNF	:= GetNextAlias()
Local oModel	:= FWModelActive()
Local oModelCXN	:= oModel:GetModel('CXNDETAIL')
Local oModelCND	:= oModel:GetModel('CNDMASTER')
Local lRet	:= .T.

BeginSQL Alias cAliasCNF
	
	SELECT	CNF_NUMERO, CNF_DTVENC, CNF_VLPREV
	
	FROM 	%Table:CNF% CNF
	
	WHERE	CNF.CNF_FILIAL = %xFilial:CNF%	AND
			CNF.CNF_CONTRA = %Exp:oModelCND:GetValue('CND_CONTRA')% AND
			CNF.CNF_REVISA = %Exp:oModelCND:GetValue('CND_REVISA')% AND
			CNF.CNF_NUMERO = %Exp:oModelCXN:GetValue('CXN_CRONOG')% AND
			CNF.CNF_PARCEL = %Exp:oModelCXN:GetValue('CXN_PARCEL')% AND
			CNF.CNF_COMPET = %Exp:oModelCND:GetValue('CND_COMPET')% AND
			CNF.%NotDel%
EndSQL


If (cAliasCNF)->(EOF())
	lRet := .F.
Else
	TCSetField(cAliasCNF,"CNF_DTVENC","D")
	oModelCXN:LoadValue('CXN_DTVENC',(cAliasCNF)->(CNF_DTVENC))
	oModelCXN:LoadValue('CXN_VLPREV',(cAliasCNF)->(CNF_VLPREV))
EndIf

(cAliasCNF)->(dbCloseArea())

RestArea(aArea)

Return lRet				 

//-------------------------------------------------------------------
/*/{Protheus.doc} IntegDef
Rotina para integração EAI

@author janaina.jesus
@since 14/05/2018
/*/
//-------------------------------------------------------------------
Static Function IntegDef(cXML, nTypeTrans, cTypeMessage, cVersion)
Local  aRet	:= 	CNTI121( cXML, nTypeTrans, cTypeMessage, cVersion)
Return aRet

//-----------------------------------------------------------------------
/*/{Protheus.doc} A121SeqTit()
Obtém o próximo número sequencial para inclusão de títulos.

@author janaina.jesus
@since 12/07/2018
@version 1.0
@Return caracter: próximo número disponível.
/*/
//-----------------------------------------------------------------------
Function A121SeqTit(cAlias, cCampo, nQualIndex, cPrefixo)
Local aArea      := GetArea()	//Guarda area atual
Local cProxNum					//Proximo numero do SX8

Default nQualIndex := 1
          
cProxNum := GetSx8Num(cAlias, cCampo,, nQualIndex)
	
dbSelectArea(cAlias)
dbSetOrder(nQualIndex)
			
While dbSeek( xFilial( cAlias ) + cPrefixo + cProxNum )
	ConfirmSX8()
	cProxNum := GetSx8Num(cAlias, cCampo,, nQualIndex)
End

RestArea(aArea)
Return(cProxNum)

/*/{Protheus.doc} PegaQtdCNB
Função para pegar a quantidade de itens em uma planilha de serviços, para realizar o cálculo
de valor unitário de cada serviço que será medido ( valor total previsto / quantidade de itens )

@param cFilCNB, Filial dos itens do contrato, com base na filial do contrato 
@param cContra, Número do contrato
@param cRevisa, Número da revisão do contrato
@param cPlan, Número da planilha do contrato
@Return nRet, Indica a quantidade de registros encontrados na CNB, conforme parâmetros de busca

@author pedro.alencar
@since 05/02/2019
/*/
Static Function PegaQtdCNB( cFilCNB As Char, cContra As Char, cRevisa As Char, cPlan As Char ) As Numeric
	Local nRet As Numeric
	Local cQuery As Char
	Local cAliasCNB As Char
	Default cFilCNB := ""
	Default cContra := ""
	Default cRevisa := ""
	Default cPlan := ""
		
	nRet := 0
	cAliasCNB := GetNextAlias()
	
	cQuery := "SELECT COUNT(*) AS QTDE" + CRLF
	cQuery += " FROM " + RetSqlName("CNB") + CRLF
	cQuery += " WHERE " + CRLF 
	cQuery += " CNB_FILIAL = '" + cFilCNB + "' AND " + CRLF
	cQuery += " CNB_CONTRA = '" + cContra + "' AND " + CRLF
	cQuery += " CNB_REVISA = '" + cRevisa + "' AND " + CRLF
	cQuery += " CNB_NUMERO = '" + cPlan + "' AND " + CRLF
	cQuery += " D_E_L_E_T_ = ' ' "
	
	cQuery := ChangeQuery( cQuery )
	
	dbUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), cAliasCNB, .T., .T. )
	
	If ( cAliasCNB )->( ! EOF() )
		nRet := ( cAliasCNB )->( QTDE )
	Endif
	
	If Select(cAliasCNB) > 0
		( cAliasCNB )->( dbCloseArea() )
		FErase( ( cAliasCNB ) + GetDBExtension() )
	EndIf		
Return nRet

/*/{Protheus.doc} CNDViewCpo
	Retorna os campos da tabela CND que devem ser exibidos na view
@author philipe.pompeu
@since 13/02/2019
@return cCampos, lista de campos da CND que devem ficar visiveis na View
/*/
Static Function CNDViewCpo()
	Local aArea := SX3->(GetArea())
	Local cCampos := ""
	
	cCampos := "CND_NUMMED|CND_CONTRA|CND_REVISA|CND_DTFIM|CND_OBS|CND_DESCCP|CND_APROV|CND_MOEDA|CND_COMPET|CND_TXMOED|CND_CONDPG" 
	
	If(cPaisLoc == "RUS")
		cCampos += "|CND_MOEDES|CND_CONUNI"
	EndIf
	
	SX3->(DbSetOrder(1))
	SX3->(DbSeek("CND"))
	While ( SX3->(!Eof() .And. AllTrim(X3_ARQUIVO) == 'CND' ))
		If(SX3->( AllTrim(X3_PROPRI) == 'U' .And. X3USO(X3_USADO) .And. cNivel >= X3_NIVEL ))
			cCampos += "|" + AllTrim(SX3->X3_CAMPO)			
		EndIf
		SX3->(dbSkip())
	EndDo
		
	cCampos += "|"//Finalizar string com '|'
	
	RestArea(aArea)
Return cCampos

/*/{Protheus.doc} CN121Parc
	Consulta especifica que permite a selecao da 
	parcela de uma competencia.
@author philipe.pompeu
@since 25/02/2019
@return lResult, se a consulta foi confirmada
/*/
Function CN121Parc()
	Local aArea	:= GetArea()
	Local lResult	:= .F.
	Local cMyAlias:= GetNextAlias()	
	Local aAdvSize:= {}
	Local aInfoAdvSize:= {}
	Local aObjCoords	:= {}
	Local aObjSize	:= {}
	LOcal oFont		:= Nil
	Local oDlg			:= NIL
	Local oListResp	:= NIL
	Local aHead		:= {}
	Local nPosLinha	:= 0.00
	Local aOpcoes 	:= {}
	Local bOk		:= { ||lResult := .T., nPosLinha:=oListResp:nAt,oDlg:End()}   
	Local bCancel	:= { ||lResult := .F., oDlg:End() }
	Local oModel	:= FWModelActive()
	Local cContra	:= ""
	Local cRevisa	:= ""
	Local cCompet	:= ""
	Local cCronog	:= ""
	Local cTitulo	:= ""
	Local cPicVal	:= GetSx3Cache("CNF_VLPREV","X3_PICTURE")
	
	If(ValType(oModel) == 'O' .And. oModel:IsActive() .And. oModel:GetId() == "CNTA121")
		cContra := oModel:GetValue('CXNDETAIL', 'CXN_CONTRA')
		cRevisa := oModel:GetValue('CNDMASTER', 'CND_REVISA')
		cCompet := oModel:GetValue('CNDMASTER', 'CND_COMPET')
		cCronog := oModel:GetValue('CXNDETAIL', 'CXN_CRONOG')
		
		cTitulo := cContra + " | " + cCompet
		
		BeginSql alias cMyAlias
			COLUMN CNF_DTVENC As Date
			SELECT CNF_PARCEL,CNF_VLPREV, CNF_DTVENC, R_E_C_N_O_ as RECNUM
			FROM %table:CNF% CNF		
			WHERE
			CNF.%notDel% AND CNF_FILIAL = %xFilial:CNF%
			AND (CNF_SALDO > 0)					
			AND (CNF_CONTRA =  %Exp:cContra% AND CNF_REVISA =  %Exp:cRevisa%)
			AND (CNF_COMPET =  %Exp:cCompet% AND CNF_NUMERO =  %Exp:cCronog%)
			ORDER BY CNF_PARCEL
		EndSql
			
		while ( (cMyAlias)->(!Eof()) )		
			aAdd(aOpcoes,{ (cMyAlias)->CNF_PARCEL, Transform((cMyAlias)->CNF_VLPREV, cPicVal), DtoC((cMyAlias)->CNF_DTVENC), (cMyAlias)->RECNUM })
			(cMyAlias)->(dbSkip())
		End
		(cMyAlias)->(dbCloseArea())
		
		if !(Len(aOpcoes) > 0)
			aOpcoes := {{'','','',''}}
		endIf
			
		aAdd(aHead,GetSx3Cache("CNF_PARCEL"	, "X3_TITULO"))
		aAdd(aHead,GetSx3Cache("CNF_VLPREV"	, "X3_TITULO"))
		aAdd(aHead,GetSx3Cache("CNF_DTVENC"	, "X3_TITULO"))
		aAdd(aHead,"RecNo")
		
		aAdvSize := MsAdvSize( , .T., 390)
		aInfoAdvSize	:= { aAdvSize[1] , aAdvSize[2] , aAdvSize[3] , aAdvSize[4] , 15 , 5 }
		aAdd( aObjCoords , { 000 , 000 , .T. , .T. } )
		aObjSize := MsObjSize( aInfoAdvSize , aObjCoords )
	
		DEFINE FONT oFont NAME "Arial" SIZE 0,-11 BOLD 
		DEFINE MSDIALOG oDlg FROM aAdvSize[7],0 TO aAdvSize[6],aAdvSize[5] TITLE cTitulo PIXEL
				
		@ aObjSize[1,1], aObjSize[1,2] LISTBOX oListResp FIELDS HEADER aHead[1],aHead[2],aHead[3]  SIZE 290,130 OF oDlg PIXEL;
		ON DBLCLICK ( lResult := .T., nPosLinha:=oListResp:nAt,oDlg:End() )
			
		oListResp:SetArray(aOpcoes)	
		oListResp:bLine := { || {aOpcoes[oListResp:nAt,1],aOpcoes[oListResp:nAt,2],aOpcoes[oListResp:nAt,3]}}
		
		ACTIVATE MSDIALOG oDlg CENTERED ON INIT (EnchoiceBar(oDlg, bOk, bCancel))
		
		If(lResult)
			VAR_IXB := aOpcoes[nPosLinha,1]
			
			CNF->(DbGoTo(aOpcoes[nPosLinha,4]))
		Else
			VAR_IXB := ''
		EndIf		
	EndIf	
	RestArea(aArea)
Return lResult

/*/{Protheus.doc} EstTitMed
	Rotina estorna titulo de uma medicao
@author PHILIPE.POMPEU
@since 08/03/2019
@return lResult, se o titulo foi estornado corretamente
/*/
Static Function EstTitMed(cRetPrf As Character, cNumTit As Character, cTpTit As Character, lVenda as Logical)
	Local lResult := .T.
	Local cUmAlias:= GetNextAlias()
	Local aTitulo := {}
	Local bExecAut:= Nil
	Default lVenda := .T.
	
	if(lVenda)
		bExecAut := {|x,y| FINA040(x,y)}
		BeginSql Alias cUmAlias
			SELECT E1_PARCELA AS PARCELA
			FROM	%Table:SE1% SE1
			WHERE SE1.E1_FILIAL = %xFilial:SE1%
			AND SE1.E1_NUM = %Exp:cNumTit%
			AND SE1.E1_PREFIXO = %Exp:cRetPrf%
			AND SE1.E1_TITPAI = ''
			AND SE1.%NotDel%
		EndSql
	Else
		bExecAut := {|x,y,z| FINA050(x,y,z)}
		BeginSql Alias cUmAlias
			SELECT E2_PARCELA AS PARCELA
			FROM %Table:SE2% SE2
			WHERE SE2.E2_FILIAL = %xFilial:SE2%
			AND SE2.E2_NUM = %Exp:cNumTit%
			AND SE2.E2_PREFIXO = %Exp:cRetPrf%
			AND SE2.E2_TIPO = %Exp:cTpTit%
			AND SE2.E2_TITPAI = ''
			AND SE2.%NotDel%
		EndSql
	endIf	
	
	While !(cUmAlias)->(EOF())
		aTitulo := {}
		
		If(lVenda)
			aAdd(aTitulo,{"E1_FILIAL"	, xFilial("SE1")		, NIL})
			aAdd(aTitulo,{"E1_PREFIXO"	, cRetPrf				, NIL})
			aAdd(aTitulo,{"E1_NUM"		, cNumTit				, NIL})
			aAdd(aTitulo,{"E1_TIPO"		, cTpTit				, NIL})
			aAdd(aTitulo,{"E1_ORIGEM"	, "CNTA121"				, NIL})
			aAdd(aTitulo,{"E1_PARCELA"	, (cUmAlias)->PARCELA	, NIL})
		Else
			aAdd(aTitulo,{"E2_FILIAL"	, xFilial("SE2")		, NIL})
			aAdd(aTitulo,{"E2_PREFIXO"	, cRetPrf				, NIL})
			aAdd(aTitulo,{"E2_NUM"		, cNumTit	  			, NIL})
			aAdd(aTitulo,{"E2_TIPO"		, cTpTit				, NIL})
			aAdd(aTitulo,{"E2_ORIGEM"	, "CNTA121"				, NIL})
			aAdd(aTitulo,{"E2_PARCELA"	, (cUmAlias)->PARCELA	, NIL})		
		EndIf
		
		If(lVenda)			
			MSExecAuto(bExecAut,aTitulo,5)
		Else
			MSExecAuto(bExecAut,aTitulo,,5)//Exclui títulos à pagar
		EndIf
		
		If lMsErroAuto
			MostraErro()
			lResult := .F.
			Exit
		Else
			CN120EstSld(CND->CND_NUMMED)
		Endif
		
		(cUmAlias)->(DbSkip())
	EndDo	
	(cUmAlias)->(dbCloseArea())
Return lResult