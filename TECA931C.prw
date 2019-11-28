#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TECA931B.CH"

//#DEFINE OPER_EFETIVA	7
//#DEFINE OPER_APROVA		8
//#DEFINE OPER_ALTERA		4

STATIC lContra	:=	.F.
STATIC lSrvExt	:=	.F.
STATIC aRetTFJ 	:= {}
//STATIC lGrpFat	:= SuperGetMv("MV_GSGRFAT",,"2")=="1"
Static __nOper 	:= 0 // Operacao da rotina
Static aCliLog	:= {} // Clientes para gravação de log


//------------------------------------------------------------------------------
/*/{Protheus.doc} TECA931C
@description	Rotina de Configuração Faturamento	
@sample	 		TECA931C()
@author			Leandro Fini
@since			02/02/2018
@version		P12   
/*/
//------------------------------------------------------------------------------
Function TECA931C()

Local nOpcFS	 := 0
Local oMBrowse   := NIL

Private aRotina	:= {}



nOpcFS:= 	GSEscolha( 	STR0001					,; 	//"Seleção de configuração"
						STR0002	,;  //"Selecione a configuração de faturamento:"
					 	{STR0003, STR0004 }		,; //"Oportunidade / Contrato" - "Orçamento Serv. Extra" 
																	1) 
If nOpcFS > 0
	Do Case
		Case nOpcFS == 1 //Contrato
			lContra := .T.
			lSrvExt := .F.	
		Case nOpcFS == 2 //Orçamento Serv. Extra
			lSrvExt := .T.		
			lContra := .F.	
	EndCase
	
	aRotina	:= Menudef()
	
	oMBrowse	:= FWmBrowse():New()
	
	If lContra
		oMBrowse:SetFilterDefault("T42->T42_SRVEXT <> '1'")
	Else
		oMBrowse:SetFilterDefault("T42->T42_SRVEXT = '1'") 
	EndIf
	
	oMBrowse:SetAlias("T42")			
	oMBrowse:SetDescription(STR0005)	//Configuração de Faturamento	
	/*If lContra
		oMBrowse:AddLegend( "T42->T42_STATUS == '1' " 		, "BR_VERDE"	, STR0052) //"Ativo" 
		oMBrowse:AddLegend( "T42->T42_STATUS == '2'" 		, "BR_AMARELO"	, STR0053) //"Em Revisão" 	
		oMBrowse:AddLegend( "T42->T42_STATUS == '3'" 		, "BR_PINK"		, STR0054 )//"Aguardando Aprovação"
	EndIf*/

	
	oMBrowse:Activate()
EndIf


Return	NIL

//------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
@description	Menu Funcional
@sample	 		MenuDef()
@author			Leandro Fini
@since			02/02/2017
@version		P12
/*/	
//------------------------------------------------------------------------------
Static Function MenuDef()    

Local	aRotina	:= {}

ADD OPTION aRotina TITLE STR0023	ACTION "PesqBrw"          	OPERATION 1                      ACCESS 0	// "Pesquisar"
ADD OPTION aRotina TITLE STR0024	ACTION "VIEWDEF.TECA931C" 	OPERATION MODEL_OPERATION_INSERT ACCESS 0	// "Incluir"
ADD OPTION aRotina TITLE STR0025 	ACTION "VIEWDEF.TECA931C" 	OPERATION MODEL_OPERATION_VIEW   ACCESS 0	// "Visualizar"
ADD OPTION aRotina TITLE STR0026	ACTION "VIEWDEF.TECA931C" 	OPERATION MODEL_OPERATION_UPDATE ACCESS 0	// "Alterar"
ADD OPTION aRotina TITLE STR0027	ACTION "VIEWDEF.TECA931C"  	OPERATION MODEL_OPERATION_DELETE ACCESS 0	// "Excluir"
ADD OPTION aRotina TITLE STR0051	ACTION "MsDocument"			OPERATION MODEL_OPERATION_UPDATE ACCESS 0 	//"Conheimento"


Return(aRotina)

//------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
@description	Definição do Model
@sample	 		ModelDef()
@author			Leandro Fini
@since			02/02/2018
@version		P12
/*/
//------------------------------------------------------------------------------
Static Function ModelDef()

Local	oModel		:= Nil
Local	oStrT42 	:= FWFormStruct(1, "T42") //Fatura separado	
Local 	oStrTWW  	:= FwFormStruct(1, "TWW") //Grupo de Faturamento
Local 	aAux		:= {}


aAux := FwStruTrigger( "T42_NROPOR", "T42_NROPOR", "A931CT42('T42MASTER',FwFldGet('T42_NROPOR'))", .F. )
oStrT42:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])

aAux := FwStruTrigger( "T42_CODIGO", "T42_CODIGO", "A931CTWW('TWWDETAIL',FwFldGet('T42_CODIGO'),'')", .F. )
oStrT42:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])

oModel := MPFormModel():New("TECA931C",/*bPreVld*/ , {|oModel| Vld931Lj(oModel)}, {|oModel| A931CCommit(oModel)})	
oModel:AddFields("T42MASTER", /*cOwner*/ , oStrT42/*, {|oModel| A931CPValid(oModel)}*/)	 
oModel:AddGrid('TWWDETAIL','T42MASTER'   ,oStrTWW,{|oModel,nLine,cAction,cField| A931GridVld(oModel,nLine,cAction,cField)},/*bLinePost*/, /*bPreVal*/,/*bPosVld*/,/*bLoadFunc*/)

oModel:SetRelation('TWWDETAIL', { { 'TWW_FILIAL', 'FWxFilial("TWW")' }, { Alltrim('TWW_NUMERO'), Alltrim('T42_CODIGO') }, { Alltrim('TWW_CHAVE'), Alltrim('T42_CHAVE') } }, TWW->(IndexKey(1)) )

oModel:SetPrimaryKey({"TWW_FILIAL","TWW_CHAVE","TWW_LOCAL"})
oModel:GetModel('TWWDETAIL'):SetUniqueLine({'TWW_LOCAL'})
oModel:GetModel('TWWDETAIL'):SetOptional(.T.)

oModel:SetVldActivate( {|oModel,cAction| InitDados(oModel)} )


Return(oModel)


//------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
@description	Definição da View
@sample	 		ViewDef()
@author			Leandro Fini
@since			02/02/2018
@version		P12
/*/
//------------------------------------------------------------------------------
Static Function ViewDef()

Local oView		:= Nil								
Local oModel	:= ModelDef()						
Local oStrT42	:= FWFormStruct(2, "T42")	
Local oStrTWW	:= FWFormStruct(2, "TWW")			

oView	:= FWFormView():New()						
oView:SetModel(oModel)								

oView:AddField("FORMT42", oStrT42, "T42MASTER")	
oView:AddGrid('FORMTWW' , oStrTWW, 'TWWDETAIL' )
oView:SetDescription(STR0005)//"Configuração de Faturamento"

//T42-------------------------//
oStrT42:RemoveField("T42_CHAVE")
oStrT42:RemoveField("T42_SRVEXT")
oStrT42:RemoveField("T42_REVOPO")
oStrT42:RemoveField("T42_STATUS")
//TWW-------------------------//
oStrTWW:RemoveField("TWW_NUMERO")  
oStrTWW:RemoveField("TWW_REVISA")
oStrTWW:RemoveField("TWW_CONTRT")
oStrTWW:RemoveField("TWW_PLANRH")
oStrTWW:RemoveField("TWW_PLANMI")
oStrTWW:RemoveField("TWW_PLANMC")
oStrTWW:RemoveField("TWW_PLANLE")
oStrTWW:RemoveField("TWW_ITEMRH")
oStrTWW:RemoveField("TWW_ITEMMI")
oStrTWW:RemoveField("TWW_ITEMMC")
oStrTWW:RemoveField("TWW_ITEMLE")
oStrTWW:RemoveField("TWW_CHAVE")
oStrTWW:RemoveField("TWW_CLIERH")
oStrTWW:RemoveField("TWW_CLIEMI")
oStrTWW:RemoveField("TWW_CLIEMC")
oStrTWW:RemoveField("TWW_CLIELE")
oStrTWW:RemoveField("TWW_LOJARH")
oStrTWW:RemoveField("TWW_LOJAMI")
oStrTWW:RemoveField("TWW_LOJAMC")
oStrTWW:RemoveField("TWW_LOJALE")
oStrTWW:RemoveField("TWW_NOMERH")
oStrTWW:RemoveField("TWW_NOMEMC")
oStrTWW:RemoveField("TWW_NOMEMI")
oStrTWW:RemoveField("TWW_NOMELE")


If lSrvExt //Se for serviço extra
	//T42---------------------------//
	oStrT42:RemoveField("T42_NROPOR")
	oStrT42:RemoveField("T42_REVOPO")
	oStrT42:RemoveField("T42_PROPOS")
	oStrT42:RemoveField("T42_PREVIS")
	oStrT42:RemoveField("T42_NOMEOP")
	oStrT42:RemoveField("T42_CONTRA")
	oStrT42:RemoveField("T42_CONREV")
	oStrT42:SetProperty("T42_CODIGO",MVC_VIEW_LOOKUP, "TFJT42")
EndIf
	
//oStrTWW:SetProperty("TWW_CLIERH",MVC_VIEW_LOOKUP, "TWW001")
//oStrTWW:SetProperty("TWW_CLIEMI",MVC_VIEW_LOOKUP, "TWW001")
//oStrTWW:SetProperty("TWW_CLIEMC",MVC_VIEW_LOOKUP, "TWW001")
//oStrTWW:SetProperty("TWW_CLIELE",MVC_VIEW_LOOKUP, "TWW001")
oStrTWW:SetProperty("TWW_CLIEHE",MVC_VIEW_LOOKUP, "TWW001")
oStrTWW:SetProperty("TWW_CLIEAD",MVC_VIEW_LOOKUP, "TWW001")  

oView:CreateHorizontalBox( 'BOXFORMT42', 40)
oView:CreateHorizontalBox( 'BOXFORMTWW', 60)

oView:SetOwnerView('FORMT42','BOXFORMT42')
oView:SetOwnerView('FORMTWW','BOXFORMTWW')	

oView:EnableTitleView('FORMT42',STR0006)//"Config. de Faturamento"
oView:EnableTitleView('FORMTWW',STR0007)//"Config. Grupo de Faturamento"

oView:AddUserButton(STR0055,"",{|oModel| A931CCsLog(oModel)},,,) // Histórico da Configuração


Return(oView)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At931BTdOk
@description	Validação Final do Modelo
@sample	 		ViewDef()
@author			Leandro Fini
@since			02/02/2018
@version		P12
/*/
//------------------------------------------------------------------------------
/*Function At931BTdOk(oModel)

Local oT42MASTER	:= oModel:GetModel("T42MASTER")
Local lRet			:= .T.
Local cFatSep		:= oT42MASTER:GetValue("T42_FATDAD")
Local cFatHEx		:= oT42MASTER:GetValue("T42_FATHEX") 
Local aSaveT42		:= T42->(GetArea())

	If oModel:GetOperation() == MODEL_OPERATION_INSERT
		If lSrvExt //Serviço extra
			DbSelectArea("T42")
			T42->(DbSetOrder(2))
			If T42->(DbSeek(xFilial("T42") + oT42MASTER:GetValue("T42_CODIGO"))) 
				Help(" ",1,"At931BTdOk", , STR0008 + T42->T42_CODIGO, 3, 1 ) //"Já existe uma configuração de faturamento para o Orçamento : "
				lRet := .F.
			EndIf
		Else //Oportunidade/Contrato
			DbSelectArea("T42")
			T42->(DbSetOrder(4))
			If T42->(DbSeek(xFilial("T42") + oT42MASTER:GetValue("T42_NROPOR"))) 
				Help(" ",1,"At931BTdOk", , STR0009 + T42->T42_NROPOR, 3, 1 ) //"Já existe uma configuração de faturamento para a Oportunidade: "                                                                                                                                                                                                                                                                                                                                                                                                                                                   
				lRet := .F.
			EndIf
		EndIf
	EndIf
	
	If lRet 
		If cFatSep == '3' .Or. cFatHEx == '3'
			If cFatSep <> cFatHEx  
				Help(" ",1,"At931BTdOk", , STR0010, 3, 1 ) //"Para gerar uma única fatura é necessário selecionar '3-Aglutinado' para ambos."
				lRet := .F.
			EndIf
		EndIf
	EndIf

RestArea(aSaveT42)

Return lRet*/
//------------------------------------------------------------------------------
/*/{Protheus.doc} InitDados
@description	Inicialização dos dados
@sample	 		InitDados()
@author			Leandro Fini
@since			02/02/2018
@version		P12
/*/
//------------------------------------------------------------------------------
Static Function InitDados(oModel)

Local oT42MASTER	:= oModel:GetModel("T42MASTER")
Local oTWWDETAIL	:= oModel:GetModel("TWWDETAIL")
Local oStruT42	 	:= oModel:GetModel('T42MASTER'):GetStruct()
Local lRet			:= .T.

oTWWDETAIL:SetNoInsertLine(.T.)

If oModel:GetOperation() == MODEL_OPERATION_INSERT
	If lContra 
		oStruT42:SetProperty("T42_REVOPO" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruT42:SetProperty("T42_CONTRA" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruT42:SetProperty("T42_CONREV" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruT42:SetProperty("T42_CODIGO" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruT42:SetProperty("T42_PROPOS" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruT42:SetProperty("T42_PREVIS" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruT42:SetProperty("T42_NOMEOP" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruT42:SetProperty("T42_CODCLI" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruT42:SetProperty("T42_LOJA" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruT42:SetProperty("T42_NOMCLI" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruT42:SetProperty("T42_NROPOR" 	,MODEL_FIELD_WHEN, {||.T.} )
	Else
		oStruT42:SetProperty("T42_CODIGO" 	,MODEL_FIELD_WHEN, {||.T.} )
		oStruT42:SetProperty("T42_CODCLI" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruT42:SetProperty("T42_LOJA" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruT42:SetProperty("T42_NOMCLI" 	,MODEL_FIELD_WHEN, {||.F.} )
	EndIf
Endif

If oModel:GetOperation() == MODEL_OPERATION_UPDATE
	oStruT42:SetProperty("T42_REVOPO" 	,MODEL_FIELD_WHEN, {||.F.} )
	oStruT42:SetProperty("T42_CONTRA" 	,MODEL_FIELD_WHEN, {||.F.} )
	oStruT42:SetProperty("T42_CONREV" 	,MODEL_FIELD_WHEN, {||.F.} )
	oStruT42:SetProperty("T42_CODIGO" 	,MODEL_FIELD_WHEN, {||.F.} )
	oStruT42:SetProperty("T42_NROPOR" 	,MODEL_FIELD_WHEN, {||.F.} )
	oStruT42:SetProperty("T42_PROPOS" 	,MODEL_FIELD_WHEN, {||.F.} )
	oStruT42:SetProperty("T42_NOMEOP" 	,MODEL_FIELD_WHEN, {||.F.} )
	oStruT42:SetProperty("T42_PREVIS" 	,MODEL_FIELD_WHEN, {||.F.} )
	oStruT42:SetProperty("T42_CODCLI" 	,MODEL_FIELD_WHEN, {||.F.} )
	oStruT42:SetProperty("T42_LOJA" 	,MODEL_FIELD_WHEN, {||.F.} )
	oStruT42:SetProperty("T42_NOMCLI" 	,MODEL_FIELD_WHEN, {||.F.} )
Endif

Return lRet
//------------------------------------------------------------------------------
/*/{Protheus.doc} A931GridVld
@description	Validação da Grid
@author			Leandro Fini
@since			02/02/2018
@version		P12
/*/
//------------------------------------------------------------------------------
Static Function A931GridVld(oModel,nLine,cAction,cField)

Local lRet 			:= .T.
Local oT42MASTER	:= oModel:GetModel("T42MASTER")
Local oTWWDETAIL	:= oT42MASTER:GetModel("TWWDETAIL")
Local nX			:= 0
Local nTamTWW		:= oTWWDETAIL:Length()

If cAction = 'DELETE'
	lRet := .F.
	Help(" ",1,"A931GridVld", ,STR0011, 3, 1 )//"Não é permitido deletar a configuração de locais."                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
Endif

If Empty(aCliLog) .and. oModel:GetOperation() == MODEL_OPERATION_UPDATE
	//aqui adicionar carga do aCliLog na alteração
	For nX := 1 to nTamTWW
		oTWWDETAIL:Goline(nX)
		Aadd(aCliLog, {oTWWDETAIL:GetValue("TWW_LOCAL") ,; // Local [1]
		  				oTWWDETAIL:GetValue("TWW_CLIEHE"),; //Cliente Hora Extra [2]
		  				oTWWDETAIL:GetValue("TWW_LOJAHE"),; //Loja Hora Extra [3]	
		  				oTWWDETAIL:GetValue("TWW_CLIEAD"),; //Cliente Desp Adicional [4]
		  				oTWWDETAIL:GetValue("TWW_LOJAAD"),; //Loja Desp Adicional [5]	
		  				})
	 Next nX

EndIf

Return lRet

//----------------------------------------------------------------------------------------
/*/{Protheus.doc} A931CT42
@description	Gatilha os dados da proposta e orçamento através da oportunidade digitada.
@author			Leandro Fini
@since			15/02/2018
@version		P12
/*/
//----------------------------------------------------------------------------------------

Function A931CT42(cModel, cOport)

Local oMdl   		:= FwModelActive()
Local oModelT42		:= oMdl:GetModel( cModel )
Local oView 	    := FwViewActive()
Local oStruT42	 	:= oMdl:GetModel(cModel):GetStruct()
Local cNomeOp		:= Posicione("AD1",1,xFilial("AD1")+ cOport,"AD1_DESCRI")
Local cOpoRev		:= Posicione("ADY",2,xFilial("ADY")+ cOport,"ADY_REVISA")
Local cPropos		:= Posicione("ADY",2,xFilial("ADY")+ cOport,"ADY_PROPOS")
Local cPropRev		:= Posicione("ADY",2,xFilial("ADY")+ cOport,"ADY_PREVIS")
Local cOrc			:= Posicione("TFJ",2,xFilial("TFJ")+ cPropos,"TFJ_CODIGO")
Local cContrato		:= Posicione("TFJ",2,xFilial("TFJ")+ cPropos,"TFJ_CONTRT")
Local cRevisa		:= ""//Posicione("TFJ",2,xFilial("TFJ")+ cPropos,"TFJ_CONREV")
Local cCodCli		:= Posicione("AD1",1,xFilial("AD1")+ cOport,"AD1_CODCLI")
Local cLoja			:= Posicione("AD1",1,xFilial("AD1")+ cOport,"AD1_LOJCLI")
Local cNomeCli		:= Posicione("SA1",1,xFilial("SA1")+ cCodCli + cLoja ,"A1_NOME")

//Abre campos para edição
oStruT42:SetProperty("T42_REVOPO" 	,MODEL_FIELD_WHEN, {||.T.} )
oStruT42:SetProperty("T42_NOMEOP" 	,MODEL_FIELD_WHEN, {||.T.} )
oStruT42:SetProperty("T42_PROPOS" 	,MODEL_FIELD_WHEN, {||.T.} )
oStruT42:SetProperty("T42_PREVIS" 	,MODEL_FIELD_WHEN, {||.T.} )
oStruT42:SetProperty("T42_CODIGO" 	,MODEL_FIELD_WHEN, {||.T.} )
oStruT42:SetProperty("T42_CODCLI" 	,MODEL_FIELD_WHEN, {||.T.} )
oStruT42:SetProperty("T42_LOJA" 	,MODEL_FIELD_WHEN, {||.T.} )
oStruT42:SetProperty("T42_NOMCLI" 	,MODEL_FIELD_WHEN, {||.T.} )

If !Empty(cContrato)
	oStruT42:SetProperty("T42_CONTRA" 	,MODEL_FIELD_WHEN, {||.T.} )
	oStruT42:SetProperty("T42_CONREV" 	,MODEL_FIELD_WHEN, {||.T.} )
	cRevisa := A931CGtRev(cContrato)
	oModelT42:SetValue("T42_CONTRA", cContrato)
	oModelT42:SetValue("T42_CONREV", cRevisa )
	cOrc:= A931CGtOrc(cContrato)
EndIf

oModelT42:SetValue("T42_REVOPO", cOpoRev )
oModelT42:SetValue("T42_NOMEOP", Alltrim(Substr(cNomeOp,0,30)) )
oModelT42:SetValue("T42_PROPOS", cPropos )
oModelT42:SetValue("T42_PREVIS", cPropRev )
oModelT42:SetValue("T42_CODIGO", cOrc )
oModelT42:SetValue("T42_CODCLI", cCodCli )
oModelT42:SetValue("T42_LOJA", 	cLoja )
oModelT42:SetValue("T42_NOMCLI", 	cNomeCli )

//Restaura a estrutura original de edição
oStruT42:SetProperty("T42_REVOPO" 	,MODEL_FIELD_WHEN, {||.F.} )
oStruT42:SetProperty("T42_NOMEOP" 	,MODEL_FIELD_WHEN, {||.F.} )
oStruT42:SetProperty("T42_PROPOS" 	,MODEL_FIELD_WHEN, {||.F.} )
oStruT42:SetProperty("T42_PREVIS" 	,MODEL_FIELD_WHEN, {||.F.} )
oStruT42:SetProperty("T42_CODIGO" 	,MODEL_FIELD_WHEN, {||.F.} )
oStruT42:SetProperty("T42_CODCLI" 	,MODEL_FIELD_WHEN, {||.F.} )
oStruT42:SetProperty("T42_LOJA" 	,MODEL_FIELD_WHEN, {||.F.} )
oStruT42:SetProperty("T42_NOMCLI" 	,MODEL_FIELD_WHEN, {||.F.} )

Return (0)

//------------------------------------------------------------------------------
/*/{Protheus.doc} A931CTWW
@description	Gatilho que retorna na Grid os locais referentes ao contrato/serv extra 
@author			Leandro Fini
@since			23/01/2018
@version		P12
/*/
//------------------------------------------------------------------------------

Function A931CTWW(cModel, cCod, cRev)

Local cAliasQry 	:= GetNextAlias()
Local oMdl   		:= FwModelActive()
Local oModelTWW		:= oMdl:GetModel( cModel )
Local oModelT42		:= oMdl:GetModel( 'T42MASTER' )
Local oView 	    := FwViewActive()
Local oStruTWW	 	:= oMdl:GetModel(cModel):GetStruct()
Local oStruT42	 	:= oMdl:GetModel('T42MASTER'):GetStruct()
Local nX			:= 1
Local cAgrup		:= Posicione("TFJ",1,xFilial("TWW")+ cCod,"TFJ_AGRUP")
Local cCodCli		:= NIL
Local cLoja			:= NIL
Local cNomeCli		:= NIL

// Tratamento para gatilhar o campo T42_CODCLI, T42_LOJA, T42_NOMCLI no cabeçalho
If lSrvExt

	cCodCli		:= Posicione("TFJ",1,xFilial("TFJ")+ cCod,"TFJ_CODENT")
	cLoja		:= Posicione("TFJ",1,xFilial("TFJ")+ cCod,"TFJ_LOJA")
	cNomeCli	:= Posicione("SA1",1,xFilial("SA1")+ cCodCli + cLoja ,"A1_NOME")

	//Abre campos para edição
	oStruT42:SetProperty("T42_CODCLI" 	,MODEL_FIELD_WHEN, {||.T.} )
	oStruT42:SetProperty("T42_LOJA" 	,MODEL_FIELD_WHEN, {||.T.} )
	oStruT42:SetProperty("T42_NOMCLI" 	,MODEL_FIELD_WHEN, {||.T.} )
	
	oModelT42:SetValue("T42_CODCLI", cCodCli )
	oModelT42:SetValue("T42_LOJA"  ,   cLoja )
	oModelT42:SetValue("T42_NOMCLI",cNomeCli )
	oModelT42:SetValue("T42_SRVEXT", "1" )//Serv. Extra = Sim
	
	//Restaura a estrutura original de edição
	oStruT42:SetProperty("T42_CODCLI" 	,MODEL_FIELD_WHEN, {||.F.} )
	oStruT42:SetProperty("T42_LOJA" 	,MODEL_FIELD_WHEN, {||.F.} )
	oStruT42:SetProperty("T42_NOMCLI" 	,MODEL_FIELD_WHEN, {||.F.} )

EndIf

oModelTWW:ClearData() //Limpa a GRID para inserir os dados do contrato	
oModelTWW:SetNoUpdateLine(.F.) //Habilita a edição de linha
oModelTWW:SetNoInsertLine(.F.) //Desabilita a trava de inserção de linha do InitDados

If  cAgrup == "2" //Se Agrup diferente de 2 não terá grid, pois não haverá config de fat.
		
		BeginSQL Alias cAliasQry
			SELECT
			TFL.TFL_LOCAL, ABS.ABS_CLIFAT, ABS.ABS_LJFAT
			FROM
				%table:TFL% TFL
				INNER JOIN %table:ABS% ABS ON
					ABS.ABS_FILIAL = %xFilial:ABS% AND
					ABS.ABS_LOCAL = TFL.TFL_LOCAL AND
					ABS.%notDel%
				LEFT JOIN %table:TWW% TWW ON
					TWW.TWW_FILIAL = %xFilial:TWW% AND
					TWW.TWW_NUMERO = TFL.TFL_CONTRT AND
					TWW.TWW_REVISA = TFL.TFL_CONREV AND
					TWW.TWW_LOCAL = TFL.TFL_LOCAL AND
					TWW.%notDel%
				WHERE
					TFL.TFL_FILIAL = %xFilial:TFL% AND
					TFL.TFL_CODPAI = %exp:cCod% AND
					TFL.%notDel%
		EndSQL
	
		(cAliasQry)->(DbGoTop())
		While (cAliasQry)->(!EoF())
			cNomeCli	:= Posicione("SA1",1,xFilial("SA1")+ (cAliasQry)->ABS_CLIFAT + (cAliasQry)->ABS_LJFAT ,"A1_NOME")
			 If nX > 1 
     			oModelTWW:AddLine()
   			 EndIf
   			 
   			 If !oModelTWW:IsDeleted() 
		 		oModelTWW:SetValue("TWW_LOCAL",   (cAliasQry)->TFL_LOCAL   )
			    oModelTWW:LoadValue("TWW_CLIEHE", (cAliasQry)->ABS_CLIFAT  )
			    oModelTWW:LoadValue("TWW_LOJAHE", (cAliasQry)->ABS_LJFAT   )
			    oModelTWW:LoadValue("TWW_NOMEHE", cNomeCli				   )
			    oModelTWW:LoadValue("TWW_CLIEAD", (cAliasQry)->ABS_CLIFAT  )
			    oModelTWW:LoadValue("TWW_LOJAAD", (cAliasQry)->ABS_LJFAT   )
			    oModelTWW:LoadValue("TWW_NOMEAD", cNomeCli				   )
			 EndIf
			  
			 nX++
   			 (cAliasQry)->(DbSkip())
   			 
		Enddo
	
		oModelTWW:GoLine(1)
	 	If oView <> NIL .AND. oView:IsActive()
	   		oView:Refresh('FORMTWW')
	 	EndIf
	
	(cAliasQry)->(DbCloseArea())
	oModelTWW:SetNoInsertLine(.T.)//Restaura a inserção de linha

Else
	oModelTWW:SetNoUpdateLine(.T.)
		
EndIf // cAgrup = "2"

Return (0)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At931TW001
Consulta especifica para o orçamento de serviço extra - TWW001.
@sample	 	At931TW001()
@return		lRet
@since		09/11/2017
@author		Kaique Schiller
@version	P12   
/*/
//------------------------------------------------------------------------------
/*
Function At931TW001()

Local lRet          := .F.
Local oBrowse       := Nil
Local cAls          := GetNextAlias()
Local nSuperior     := 0
Local nEsquerda     := 0
Local nInferior     := 460
Local nDireita      := 800
Local oDlgTela 		:= Nil
Local cQry   		:= ""
//Definição do índice da Consulta Padrão
Local aIndex 		:= {}
//Definição da Descrição da Chave de Pesquisa da Consulta Padrão
Local aSeek 		:= {{ STR0030, {{STR0030,"C",TamSx3('A1_COD')[1],0,"",,}} }} //"Clientes" ## "Clientes"
Local aRet 			:= {"",""}
Local oModel		:= FwModelActive()
Local oView			:= FwViewActive()
Local oGridDtl		:= oModel:GetModel('TWWDETAIL')
Local cCmpCli		:= ReadVar()
Local cCmpLoj		:= ""
Local cTFJCod		:= FwFldGet("T42_CODIGO")
Local nOper			:= oModel:GetOperation()

aAdd(aIndex,"TFJ_CODENT")
aAdd(aIndex,"TFJ_LOJA")

If "TWW_CLIERH" $ cCmpCli
	cCmpCli := "TWW_CLIERH"
	cCmpLoj := "TWW_LOJARH"
Elseif "TWW_CLIEMI" $ cCmpCli
	cCmpCli := "TWW_CLIEMI"
	cCmpLoj := "TWW_LOJAMI"
Elseif "TWW_CLIEMC" $ cCmpCli
	cCmpCli := "TWW_CLIEMC"
	cCmpLoj := "TWW_LOJAMC"
Elseif "TWW_CLIELE" $ cCmpCli
	cCmpCli := "TWW_CLIELE"
	cCmpLoj := "TWW_LOJALE"
Elseif "TWW_CLIEHE" $ cCmpCli
	cCmpCli := "TWW_CLIEHE"
	cCmpLoj := "TWW_LOJAHE"
Elseif "TWW_CLIEAD" $ cCmpCli
	cCmpCli := "TWW_CLIEAD"
	cCmpLoj := "TWW_LOJAAD"
Endif

If Empty(FwFldGet("T42_CONTRA"))
	cQry := At931QrySr(cTFJCod)
Else
	cQry := At931QryCt(FwFldGet("T42_CONTRA"),FwFldGet("T42_CONREV"))
EndIf
DEFINE MSDIALOG oDlgTela TITLE STR0012 FROM nSuperior,nEsquerda TO nInferior,nDireita PIXEL //Cli. Fat. Contrato
 
oBrowse := FWFormBrowse():New()
oBrowse:SetOwner(oDlgTela)
oBrowse:SetDataQuery(.T.)
oBrowse:SetAlias(cAls)
oBrowse:SetQueryIndex(aIndex)
oBrowse:SetQuery(cQry)
oBrowse:SetSeek(,aSeek)
oBrowse:SetDescription(STR0013) //Clientes de faturamento

oBrowse:SetDoubleClick({ || aRet[1] := (oBrowse:Alias())->CODENT, aRet[2] := (oBrowse:Alias())->LOJA, lRet := .T., oDlgTela:End()}) //"Confirmar"
oBrowse:AddButton( OemTOAnsi(STR0031), {|| aRet[1] := (oBrowse:Alias())->CODENT, aRet[2] := (oBrowse:Alias())->LOJA,  lRet := .T., oDlgTela:End()},, 2 ) //"Cancelar"
oBrowse:AddButton( OemTOAnsi(STR0032),  {|| aRet[1] := "" , aRet[2] := "", oDlgTela:End()} ,, 2 ) //"Cancelar" 
oBrowse:DisableDetails()

ADD COLUMN oColumn DATA { ||  CODENT  } TITLE STR0033	SIZE TamSx3('TFJ_CODENT')[1] OF oBrowse //"Código"
ADD COLUMN oColumn DATA { ||  LOJA    } TITLE STR0034	SIZE TamSx3('TFJ_LOJA')[1] 	 OF oBrowse //"Loja"
ADD COLUMN oColumn DATA { ||  NOME     } TITLE STR0035 	SIZE TamSx3('A1_NOME')[1]  	 OF oBrowse //"Nome"

oBrowse:Activate()

ACTIVATE MSDIALOG oDlgTela CENTERED

If lRet .And. !Empty(aRet) .and. (nOper == MODEL_OPERATION_INSERT .or. nOper == MODEL_OPERATION_UPDATE) 		
	lRet := oGridDtl:SetValue(cCmpCli,aRet[1]) .And. oGridDtl:SetValue(cCmpLoj,aRet[2])
	If lRet
		aRetTFJ := aRet
	Endif
Endif

If oView:IsActive()
	oView:Refresh("FORMTWW")
Endif

Return lRet
*/
//------------------------------------------------------------------------------
/*/{Protheus.doc} At931RetTW
Retorno da consulta especifica para o orçamento de serviço extra - TWW001.
@sample	 	At931RetTW()
@return		lRet
@since		09/11/2017
@author		Kaique Schiller
@version	P12   
/*/
//------------------------------------------------------------------------------
/*
Function At931RetTW()

Return aRetTFJ[1]
*/
//------------------------------------------------------------------------------
/*/{Protheus.doc} At931QryCt
Função com query para busca dos clientes com contrato
@sample	 	At931QryCt()
@return		cQry
@since		21/02/2018
@author		Leandro Fini
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At931QryCt(cContra, cRevisa)

Local cQry := ""

cQry := " SELECT CNC_CLIENT AS CODENT, CNC_LOJACL AS LOJA, A1_NOME AS NOME FROM " + RetSqlName("CNC") + " CNC "
cQry += " JOIN " + RetSqlName('SA1') + " SA1 ON A1_COD = CNC_CLIENT "
cQry += "AND A1_LOJA = CNC_LOJACL "
cQry += "WHERE CNC_NUMERO = '" + cContra +"' "
cQry += "AND CNC_REVISA = '"+ cRevisa +" ' "
cQry += "AND CNC.D_E_L_E_T_ = ' ' "

Return cQry
//------------------------------------------------------------------------------
/*/{Protheus.doc} At931QrySr
função com a query dos clientes do serviço extra.
@sample	 	At931QrySr()
@return		lRet
@since		09/11/2017
@author		Kaique Schiller
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At931QrySr(cCodTFJ)
Local cQry := ""

cQry := " SELECT TFJ_CODENT AS CODENT, TFJ_LOJA AS LOJA, A1_NOME AS NOME "
cQry += " FROM " + RetSqlName("TFJ") + " TFJ "
cQry += " INNER JOIN " + RetSqlName("SA1") + " SA1 "
cQry += " ON SA1.A1_FILIAL = '" + xFilial('SA1') + "'"
cQry += " AND SA1.A1_COD = TFJ.TFJ_CODENT AND SA1.A1_LOJA = TFJ.TFJ_LOJA AND SA1.D_E_L_E_T_ <> '*'"                                                                   
cQry += " WHERE TFJ.TFJ_FILIAL = '" + xFilial('TFJ') + "'"
cQry += " AND TFJ.TFJ_CODIGO = '" + cCodTFJ + "' AND TFJ.D_E_L_E_T_ <> '*'"

cQry += " UNION "
cQry += " SELECT ABS_CODIGO TFJ_CODENT , ABS_LOJA TFJ_LOJA, A1_NOME "
cQry += " FROM " + RetSqlName("TFJ") + " TFJ "
cQry += " INNER JOIN " + RetSqlName("TFL") + " TFL "
cQry += " ON TFL.TFL_FILIAL = '" + xFilial('TFL') + "'"
cQry += " AND TFL_CODPAI = TFJ_CODIGO AND TFL.D_E_L_E_T_ <> '*'"                                                                   
cQry += " INNER JOIN " + RetSqlName("ABS") + " ABS "
cQry += " ON ABS.ABS_FILIAL = '" + xFilial('ABS') + "'"
cQry += " AND ABS_LOCAL  = TFL_LOCAL AND ABS.D_E_L_E_T_ <> '*'"                                                                   
cQry += " INNER JOIN " + RetSqlName("SA1") + " SA1 "
cQry += " ON SA1.A1_FILIAL = '" + xFilial('SA1') + "'"
cQry += " AND SA1.A1_COD = ABS.ABS_CODIGO AND SA1.A1_LOJA = ABS.ABS_LOJA AND SA1.D_E_L_E_T_ <> '*'"                                                                   
cQry += " WHERE TFJ.TFJ_FILIAL = '" + xFilial('TFJ') + "'"
cQry += " AND TFJ.TFJ_CODIGO = '" + cCodTFJ + "' AND TFJ.D_E_L_E_T_ <> '*' "

cQry += " UNION "
cQry += " SELECT ABS_CLIFAT TFJ_CODENT , ABS_LJFAT TFJ_LOJA, A1_NOME "
cQry += " FROM " + RetSqlName("TFJ") + " TFJ "
cQry += " INNER JOIN " + RetSqlName("TFL") + " TFL "
cQry += " ON TFL.TFL_FILIAL = '" + xFilial('TFL') + "'"
cQry += " AND TFL_CODPAI = TFJ_CODIGO AND TFJ.D_E_L_E_T_ <> '*'"                                                                   
cQry += " INNER JOIN " + RetSqlName("ABS") + " ABS "
cQry += " ON ABS.ABS_FILIAL = '" + xFilial('ABS') + "'"
cQry += " AND ABS_LOCAL  = TFL_LOCAL AND TFL.D_E_L_E_T_ <> '*'"                                                                   
cQry += " INNER JOIN " + RetSqlName("SA1") + " SA1 "
cQry += " ON SA1.A1_FILIAL = '" + xFilial('SA1') + "'"
cQry += " AND SA1.A1_COD = ABS.ABS_CLIFAT AND SA1.A1_LOJA = ABS.ABS_LJFAT AND SA1.D_E_L_E_T_ <> '*'"                                                                   
cQry += " WHERE TFJ.TFJ_FILIAL = '" + xFilial('TFJ') + "'"
cQry += " AND TFJ.TFJ_CODIGO = '" + cCodTFJ + "' AND TFJ.D_E_L_E_T_ <> '*' "


Return cQry

//------------------------------------------------------------------------------
/*/{Protheus.doc} Gt931CodLj
Função para gatilhar a loja do cliente digitado manualmente.
@sample	 	Gt931CodLj()
@return		lRet
@since		27/11/2017
@author		Leandro Fini
@version	P12   
/*/
//------------------------------------------------------------------------------
/*
Function Gt931CodLj(cCampo)

Local cQuery 		:= ""
Local cAliasCodLJ   := GetNextAlias()
Local cRet			:= ""
Local cCliTWW 		:= ""
Local cContrt		:= FwFldGet("TWW_NUMERO")
Local cRevisa		:= FwFldGet("TWW_REVISA")
Local cTFJCod		:= Posicione("TFJ",1,xFilial("TWW")+ FwFldGet("T42_CODIGO"),"TFJ_CODIGO")//IIF(lContra == .T.,Posicione("TFJ",5,xFilial("TWW")+ FwFldGet("T42_CONTRA") + FwFldGet("T42_CONREV"),"TFJ_CODIGO"),Posicione("TFJ",1,xFilial("TWW")+ FwFldGet("T42_CODIGO"),"TFJ_CODIGO"))

If cCampo == "RH"
	cCliTWW := M->TWW_CLIERH
ElseIf cCampo == "MI"
	cCliTWW := M->TWW_CLIEMI
ElseIf cCampo == "MC"
	cCliTWW := M->TWW_CLIEMC
ElseIf cCampo == "LE"
	cCliTWW := M->TWW_CLIELE
ElseIf cCampo == "HE"
	cCliTWW := M->TWW_CLIEHE
ElseIf cCampo == "AD"
	cCliTWW := M->TWW_CLIEAD
Endif

If Empty(TFJ->TFJ_CONTRT)
	//Coloca a loja proveniente da consulta padrão
	If !Empty(aRetTFJ)
		cRet := aRetTFJ[2]
	Else	
		//Busca a loja do cliente digitado manualmente
		cQuery := At931QrySr(cTFJCod)
		cQuery := ChangeQuery(cQuery)
		dbUseArea( .T., "TOPCONN", TcGenQry( ,, cQuery ) , cAliasCodLJ, .F., .T. )
		
		While (cAliasCodLJ)->(!EoF())
			If (cAliasCodLJ)->CODENT == cCliTWW 
				cRet := (cAliasCodLJ)->LOJA
			Endif
			(cAliasCodLJ)->(DbSkip())
		EndDo
	EndIf
Else
	
	//Busca a loja do cliente digitado
	DbSelectArea("CNC")
	CNC->(DbSetOrder(3)) //CNC_FILIAL+CNC_NUMERO+CNC_REVISA+CNC_CLIENT
	If CNC->(dbSeek(xFilial("CNC")+TFJ->TFJ_CONTRT+TFJ->TFJ_CONREV+cCliTWW))
		cRet := CNC->CNC_LOJACL	
	Endif

Endif

aRetTFJ := {}
Return cRet
*/
//------------------------------------------------------------------------------
/*/{Protheus.doc} Vld931Lj
Função para validar o cliente e loja inseridos manualmente.
@sample	 	Vld931Lj()
@return		lRet
@since		27/11/2017
@author		Leandro Fini
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function Vld931Lj(oModel)
	
Local oModelTWW := oModel:GetModel('TWWDETAIL')
Local cCliTWW 	:= ""
Local cLojTWW 	:= ""
Local cQuery  	:= ""
Local cAliasTWW := GetNextAlias()
Local aCliLj    := {}
Local aDadosTWW := {}
Local aDadosVld := {}
Local cHelpVld	:= ""
Local lRet		:= .T.
Local nPos		:= 0
Local nY		:= 0
Local nX		:= 0
Local oT42MASTER	:= oModel:GetModel("T42MASTER")
Local cFatSep		:= oT42MASTER:GetValue("T42_FATDAD")
Local cFatHEx		:= oT42MASTER:GetValue("T42_FATHEX") 
Local aSaveT42		:= T42->(GetArea())
Local cContrt		:= FwFldGet("T42_CONTRA")
Local cRevisa		:= FwFldGet("T42_CONREV")
Local cCodSrv		:= FwFldGet("T42_CODIGO")
Local cTFJCod		:= Posicione("TFJ",1,xFilial("TWW")+ cCodSrv,"TFJ_CODIGO")
Local cAgrup		:= Posicione("TFJ",1,xFilial("TWW")+ cCodSrv,"TFJ_AGRUP")

If oModel:GetOperation() == MODEL_OPERATION_INSERT 
	If lSrvExt
		DbSelectArea("T42")
		T42->(DbSetOrder(1))
		If T42->(DbSeek(xFilial("T42") + oT42MASTER:GetValue("T42_CODIGO"))) 
			Help(" ",1,"PreVld931", , STR0008 + T42->T42_CODIGO, 3, 1 ) //"Já existe uma configuração de faturamento para o Orçamento: "                                                                                                                                                                                                                                                                                                                                                                                                                                                      
			lRet := .F.	
		Endif
	Else
		DbSelectArea("T42")
		T42->(DbSetOrder(4))
		If T42->(DbSeek(xFilial("T42") + oT42MASTER:GetValue("T42_NROPOR"))) 
			Help(" ",1,"PreVld931", , STR0009 + T42->T42_NROPOR, 3, 1 ) //"Já existe uma configuração de faturamento para a Oportunidade: "                                                                                                                                                                                                                                                                                                                                                                                                                                                   
			lRet := .F.	
		Endif
	EndIf
	
	If lRet
		If lContra
			If Empty(oT42MASTER:GetValue("T42_NROPOR"))
				Help(" ",1,"PreVld931", , STR0014, 3, 1 )//"Selecione uma oportunidade." 
				lRet := .F.	
			EndIf
		Else
			If Empty(oT42MASTER:GetValue("T42_CODIGO"))
				Help(" ",1,"PreVld931", , STR0015, 3, 1 ) //"Selecione um orçamento."
				lRet := .F.	
			EndIf
		EndIf
	EndIf
EndIf

If lRet
	If cFatSep == '3' .Or. cFatHEx == '3'
		If cFatSep <> cFatHEx  
			Help(" ",1,"Vld931Lj", , STR0010, 3, 1 ) //"Para gerar uma única fatura é necessário selecionar '3-Aglutinado' para ambos."                                                                                                                                                                                                                                                                                                                                                                                                                                    
			lRet := .F.
		EndIf
	EndIf
EndIf

If cAgrup == "2" //Se Agrup diferente de 2 não terá grid, pois não haverá config de fat.

	If lRet .AND. (cFatSep == '3' .AND. cFatHEx == '3')
		For nY := 1 To oModelTWW:Length()
			oModelTWW:GoLine(nY)
			If ( oModelTWW:GetValue("TWW_CLIEHE") + oModelTWW:GetValue("TWW_LOJAHE") ) <> ( oModelTWW:GetValue("TWW_CLIEAD") + oModelTWW:GetValue("TWW_LOJAAD") )
				lRet := .F.
			EndIf
		Next nY	
		If !lRet
			Help(" ",1,"Vld931Lj", , STR0016, 3, 1 )//"Para gerar uma única fatura é necessário que os Clientes HE e AD sejam iguais."                                                                                                                                                                                                                                                                                                                                                                                                                                     	
		EndIf
	EndIf
	
	If lRet
		//Armazena os clientes digitados no browser no aDadosTWW
		For nY := 1 To oModelTWW:Length()
			oModelTWW:GoLine(nY)
			If !oModelTWW:IsDeleted() 
		
				nPos:= aScan(aDadosTWW, { |x| x == oModelTWW:GetValue("TWW_CLIEHE") + oModelTWW:GetValue("TWW_LOJAHE") } ) 
				If nPos == 0 		
					aAdd(aDadosTWW, oModelTWW:GetValue("TWW_CLIEHE") + oModelTWW:GetValue("TWW_LOJAHE") )
				Endif
		
				nPos:= aScan(aDadosTWW, { |x| x == oModelTWW:GetValue("TWW_CLIEAD") + oModelTWW:GetValue("TWW_LOJAAD") } ) 
				If nPos == 0 		
					aAdd(aDadosTWW, oModelTWW:GetValue("TWW_CLIEAD") + oModelTWW:GetValue("TWW_LOJAAD") )
				Endif
		
			Endif
		Next nY
		
		If Empty(TFJ->TFJ_CONTRT)
	
			//Query para buscar os locais vinculados ao serviço.
			cQuery := At931QrySr(cCodSrv)
			cQuery := ChangeQuery(cQuery)
			dbUseArea( .T., "TOPCONN", TcGenQry( ,, cQuery ) , cAliasTWW, .F., .T. )
						
				//Armazena o resultado da query no aCliLj
				While (cAliasTWW)->(!EoF())
					aAdd(aCliLj, (cAliasTWW)->CODENT + (cAliasTWW)->LOJA )
					(cAliasTWW)->(DbSkip())
				EndDo
				
				//Compara os clientes digitados no browser(aDadosTWW) com os locais vinculados ao serviço(aCliLj).
				For nX := 1 to Len(aDadosTWW)
				  nPos:= aScan(aCliLj, { |x| x == aDadosTWW[nX] } )
					If nPos == 0
						aAdd(aDadosVld, aDadosTWW[nX] )
						lRet := .F.
					Endif		
				Next nX
				
				//Alimenta um array com os clientes errados para o help.
				If lRet == .F.
					For nX := 1 to Len(aDadosVld)
						cHelpVld += " [" + Substr(aDadosVld[nX],0,8) + "/" + Substr(aDadosVld[nX],9,4) + "] "
					Next nX			
			      Help(" ",1,"Vld931Lj", , STR0017 + cHelpVld + STR0018 , 3, 1 ) //"O(s) cliente(s) " + cHelpVld + "não estão vinculados ao serviço."
				Endif
			
		Else
	
			For nY := 1 to Len(aDadosTWW)
				//Busca a loja do cliente digitado
				DbSelectArea("CNC")
				CNC->(DbSetOrder(3)) //CNC_FILIAL+CNC_NUMERO+CNC_REVISA+CNC_CLIENT
				If CNC->(!dbSeek(xFilial("CNC") + TFJ->TFJ_CONTRT + TFJ->TFJ_CONREV + aDadosTWW[nY]))
					cHelpVld += " [" + Substr(aDadosTWW[nY],0,8) + "/" + Substr(aDadosTWW[nY],9,4) + "] "
					lRet := .F.
				Endif
			Next nY
		 	Help(" ",1,"Vld931Lj", , STR0017 + cHelpVld + STR0019 , 3, 1 )//"O(s) cliente(s) " + cHelpVld + "não estão vinculados ao contrato."
		Endif
	
	EndIf //If lRet
	
EndIf //If cAgrup = "2"
RestArea(aSaveT42)

Return lRet
//------------------------------------------------------------------------------
/*/{Protheus.doc} A931CCommit
Função de commit.
@sample	 	A931CCommit()
@return		lRet
@since		05/02/2018
@author		Leandro Fini
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function A931CCommit(oModel)

Local lRet 		:= .T.
Local bAfter	:= {|oModel| A931CAfter(oModel)}
Local nOpcao	:= oModel:GetOperation()
Local oModelT42	:= oModel:GetModel("T42MASTER")
Local oModelTWW	:= oModel:GetModel("TWWDETAIL")
Local cCodCN0	:= SuperGetMv("MV_GSTPRFT",,"")
Local cCodTfj	:= ""
Local cRevTfj	:= ""
Local oStruT42	:= oModelT42:GetStruct()
Local nX		:= 1
Local nTamTWW	:= 0
Local aAlt      := {}
Local nPos      := 0
Local cCliAux   := ""
Local cLojAux   := ""
Local cLocAux	:= ""
Local cMunic	:= ""

Begin Transaction
		
	If lRet
		lRet := FWFormCommit(oModel,,bAfter,NIL)
		If lRet
		
			If nOpcao == MODEL_OPERATION_UPDATE 
				nTamTWW:= oModelTWW:Length()
			
				For nX := 1 to nTamTWW
					oModelTWW:GoLine(nX)
					nPos:= Ascan(aCliLog,{|e| e[1] == oModelTWW:GetValue("TWW_LOCAL")})
					If nPos > 0
						cMunic 	:= POSICIONE("ABS",1,xFilial("ABS")+oModelTWW:GetValue("TWW_LOCAL"),"ABS_MUNIC")
						cLocAux := STR0059 +" "+oModelTWW:GetValue("TWW_LOCAL")+ " - " + AllTrim(oModelTWW:GetValue("TWW_DESLOC")) + " - " + AllTrim(cMunic) +" " ////"do local "
						
						cCliAux := oModelTWW:GetValue("TWW_CLIEHE")
						cLojAux	:= oModelTWW:GetValue("TWW_LOJAHE")
						If !(aCliLog[nPos][2]+aCliLog[nPos][3] == cCliAux+ cLojAux)
							aadd( aAlt,{ STR0060,STR0067+" "+cLocAux+ STR0062+" "+ Alltrim(aCliLog[nPos][2]) +" / "  + AllTrim(aCliLog[nPos][3]) + " " + STR0063  +" " +  Alltrim(cCliAux) +" / "   + AllTrim(cLojAux) })
						EndIf
						//"Alteração"**"Cliente e loja de Hora Extra "**"foi alterado de "** ' para '
						cCliAux := oModelTWW:GetValue("TWW_CLIEAD")
						cLojAux	:= oModelTWW:GetValue("TWW_LOJAAD")
						If !(aCliLog[nPos][4]+aCliLog[nPos][5] == cCliAux+ cLojAux)
							aadd( aAlt,{ STR0060,STR0068+" "+cLocAux+STR0062+" "+ Alltrim(aCliLog[nPos][4]) +" / "  + AllTrim(aCliLog[nPos][5]) + " " + STR0063  +" " +  Alltrim(cCliAux) +" / "  + AllTrim(cLojAux) })
							//"Alteração"**"Cliente e loja de desp. adic. "**"foi alterado de "** ' para '
						EndIf
					EndIf
				
				Next nX
			ElseIf nOpcao == MODEL_OPERATION_INSERT
				aadd( aAlt,{ STR0069,STR0070 })//"Inclusão"**"Inclusão da configuração de faturamento"
			EndIf
			
			A931CEsLog(aAlt, oModelT42:GetValue('T42_CHAVE'))
		EndIf
	Else
		DisarmTransacation()
	EndIf
	
End Transaction

aCliLog:={}

Return lRet
//------------------------------------------------------------------------------
/*/{Protheus.doc} A931CAfter
Função responsável pelo flag em tabela na TFJ, dentro da transação.
@sample	 	A931CAfter()
@return		lRet
@since		05/02/2018
@author		Leandro Fini
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function A931CAfter(oModel,nOpc)

	Local cContrt  	:= FwFldGet("T42_CONTRA")
	Local cRevisa  	:= FwFldGet("T42_CONREV")
	Local cCodSrv  	:= FwFldGet("T42_CODIGO")
	Local nOpc     	:= oModel:GetOperation()
	Local cChave   	:= FwFldGet("T42_CHAVE")
	
	DbSelectArea("TFJ")
	TFJ->(DbSetOrder(1))//TFJ_FILIAL+TFJ_CODIGO
	If TFJ->(DbSeek(xFilial("TFJ") + cCodSrv))
		RecLock("TFJ",.F.)
			If nOpc == 3 //Inclusão
				TFJ->TFJ_CODGRP := cChave
			ElseIf nOpc == 5 //Exclusão
			  	TFJ->TFJ_CODGRP := "" 
			EndIf
		TFJ->(MsUnlock())
	EndIf

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At931VldCl
Função Responsável por validar o cliente e loja. 
@sample	 	At931VldCl()
@return		lRet
@since		09/11/2017
@author		Kaique Schiller
@version	P12   
/*/
//------------------------------------------------------------------------------
/*
Function At931VldCl(cCodCli)
Local lRet 		:= .F.
Local cAliasQry	:= ""
Local cQry		:= ""
Local cTFJCod	:= Posicione("TFJ",1,xFilial("TWW")+ FwFldGet("T42_CODIGO"),"TFJ_CODIGO") //IIF(lContra == .T.,Posicione("TFJ",5,xFilial("TWW")+ FwFldGet("T42_CONTRA") + FwFldGet("T42_CONREV"),"TFJ_CODIGO"),Posicione("TFJ",1,xFilial("TWW")+ FwFldGet("T42_CODIGO"),"TFJ_CODIGO"))

If !IsInCallStack("At870GrvTWW")
	If Empty(TFJ->TFJ_CONTRT)  //Se for serviço extra ou não houver contrato vinculado ainda.
	
		cAliasQry	:= GetNextAlias()
		cQry 		:= At931QrySr(cTFJCod)
		cQry 		:= ChangeQuery(cQry)
	
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAliasQry,.T.,.T.)
	
		While !(cAliasQry)->(EOF())
			If cCodCli == (cAliasQry)->CODENT
				lRet := .T.
				Exit
			Endif
			(cAliasQry)->(DbSkip())
		EndDo
	
		If !lRet
		    Help( "", 1, "AT932VISUAL", , i18n(STR0020,;//O cliente: #1[codorc]# não faz parte do orçamento de serviço extra."
		    									{ cCodCli }), 1, 0,,,,,,;  
							                  {STR0021}) //"Informe um cliente que esteja envolvido no orçamento."
		Endif
	
		(cAliasQry)->(DbCloseArea())
	Else
		lRet := ExistCpo("CNC", TFJ->TFJ_CONTRT + TFJ->TFJ_CONREV + cCodCli, 3) 
	Endif
Else
	lRet := .T.
Endif

Return lRet
*/

//------------------------------------------------------------------------------
/*/{Protheus.doc} A931CExcl
Função para Exclusão de registros
@sample	 	A931CExcl()
@return		lRet
@since		14/03/2018
@author		Pâmela Bernardo
@version	P12   
/*/
//------------------------------------------------------------------------------
//Function A931CExcl(cAlias,nReg,nOpc)

//	Local nRet 	:= 0
	
//	oModel       := FWLoadModel( "TECA931C" )
//	oModel:SetOperation( nOpc ) 
//	oModel:Activate(.T.) 
	
	//nRet := FWExecView(STR0050,"TECA931C",MODEL_OPERATION_DELETE, /*oDlg*/, {|| .T. } ,/*bOk*/ , /*nPercReducao*/, /*aEnableButtons*/, /*bCancel*/ , /*cOperatId*/, /*cToolBar*/) //"Exclusão"

	
//Return 


//------------------------------------------------------------------------------
/*/{Protheus.doc} A931CAlt
Função para alteração da configuração de faturamento
@sample	 	A931CAlt()
@return		lRet
@since		15/03/2018
@author		Pâmela Bernardo
@version	P12   
/*/
//------------------------------------------------------------------------------
/*Function A931CAlt(cAlias,nReg,nOpc)

	Local nRet 	:= 0
	
	__nOper := OPER_ALTERA
	aCliLog:={}
	
	oModel       := FWLoadModel( "TECA931C" )
	oModel:SetOperation( nOpc ) 
	oModel:Activate(.T.) 

	
	If oModel:GetValue("T42MASTER","T42_STATUS") == "3"
		Help(" ",1,"CONFNOALT", , STR0044, 3, 1 ) //"Configuração pendente de aprovação. Alteração não permitida."
	Else*/
		//nRet := FWExecView("","TECA931C",MODEL_OPERATION_UPDATE, /*oDlg*/, {|| .T. } ,/*bOk*/ , /*nPercReducao*/, /*aEnableButtons*/, /*bCancel*/ , /*cOperatId*/, /*cToolBar*/)
	/*EndIf
	
	__nOper 	:= 0
	
Return */


//------------------------------------------------------------------------------
/*/{Protheus.doc} A931CCodOr
Função para retornar o codigo na TFJ
@sample	 	A931CCodOr()
@return		cRet - codigo da TFJ
@since		16/03/2018
@author		Pâmela Bernardo
@version	P12   
/*/
//------------------------------------------------------------------------------
/*Static Function A931CCodOr(cCodGrp, cStatus, cRevTfj)

	Local cRet := ""
	Local cQuery := ""
	Local cAliasTFJ := GetNextAlias()

	If !Empty(cCodGrp)
		cQuery := "SELECT * FROM "
		cQuery += RetSqlName("TFJ") 
		cQuery += " WHERE "
		cQuery += " TFJ_CODIGO = "  
		cQuery += "(SELECT MAX (TFJ_CODIGO) TFJ_CODIGO FROM "
		cQuery += RetSqlName("TFJ") 
		cQuery += " WHERE "                                    
		cQuery += "TFJ_FILIAL = '"+xFilial("TFJ")+"' AND "
		cQuery += "TFJ_CODGRP= '" + cCodGrp + "' AND "
		cQuery += "TFJ_STATUS= '" + cStatus + "'  AND "
		cQuery += "D_E_L_E_T_ = ' ' )"
		cQuery := ChangeQuery(cQuery)
	
		dBUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),cAliasTFJ,.F.,.T.)
	
		If !Empty((cAliasTFJ)->TFJ_CODIGO)
			cRet := (cAliasTFJ)->TFJ_CODIGO
			cRevTfj:=(cAliasTFJ)->TFJ_CONREV
		Endif
		(cAliasTFJ)->(dbCloseArea())							
	EndIf 

Return cRet*/


/*/{Protheus.doc} A931CCsLog
Consulta do Histórico de Alteração do contrato
@author Pâmela Bernardo
@since  04/06/2018
@version 12
/*/
Function A931CCsLog(oModel)
	Local oModelT42	:= oModel:GetModel("T42MASTER")
	Local cChave := oModelT42:GetValue("T42_CHAVE")
	
	ProcLogView( cFilAnt, cChave)

Return

/*/{Protheus.doc} A931CEsLog
Estrutura o histórico para gravação do log
@author Pâmela Bernardo
@since  04/06/2018
@version 12
/*/
Static Function A931CEsLog(aAlt, cChaveT42)
	Local nCx        := 0 
	Local cHistorico := ''
	Local cProcesso  := ''
	
	For nCx := 1 to LEN(aAlt)
	
	    cProcesso := aAlt[nCx][1]
	    
	    If !Empty(aAlt[nCx][2])    
		    cHistorico += aAlt[nCx][2] + CRLF
		endif 
		cHistorico += CRLF      	
	
	Next nCx
	
	A931CGvLog(cProcesso,cHistorico, cChaveT42)

Return

/*/{Protheus.doc} A931CGvLog
Gravação do histórico de alteração
@author Pâmela Bernardo
@since  04/06/2018
@version 12
/*/
Static Function A931CGvLog(cProcesso,cHistorico, cChaveT42)
	Local cIdCV8 := ''
	
	Default cProcesso  := ''
	Default cHistorico := ''
	
	If !Empty(cProcesso) .and. !Empty(cHistorico)
		//Gravo o log para histórico 
		ProcLogIni( {}, cChaveT42,   , @cIdCV8 )
		ProcLogAtu( STR0071, cProcesso, cHistorico ,,.T. ) // "MENSAGEM"
	Endif	

Return
/*/{Protheus.doc} A931CGtRev
Busca ultima revisão do contrato
@author Pâmela Bernardo
@since  04/06/2018
@version 12
/*/
Static Function A931CGtRev(cContrato)
	Local cRet := ""
	Local cAliasTFJ	:= GetNextAlias()
	
	BeginSQL Alias cAliasTFJ
	SELECT MAX(TFJ_CONREV) AS REVMAX
	FROM	%Table:TFJ% TFJ
	WHERE	TFJ.TFJ_FILIAL = %XFilial:TFJ%
			AND TFJ.TFJ_CONTRT  = %Exp:cContrato%
			AND TFJ.TFJ_STATUS  = "1"
			AND TFJ.%NotDel%
	EndSQL
		
	If !(cAliasTFJ)->(Eof())
		cRet := (cAliasTFJ)->(REVMAX)
	EndIf
		
	(cAliasTFJ)->( dbCloseArea() )
	

Return cRet

/*/{Protheus.doc} A931CGtOrc
Busca ultimo orcamento
@author Pâmela Bernardo
@since  04/06/2018
@version 12
/*/
Static Function A931CGtOrc(cContrato)
	Local cRet := ""
	Local cAliasTFJ	:= GetNextAlias()
	
	BeginSQL Alias cAliasTFJ
	SELECT MAX(TFJ_CODIGO) AS ORCMAX
	FROM	%Table:TFJ% TFJ
	WHERE	TFJ.TFJ_FILIAL = %XFilial:TFJ%
			AND TFJ.TFJ_CONTRT  = %Exp:cContrato%
			AND TFJ.TFJ_STATUS  = "1"
			AND TFJ.%NotDel%
	EndSQL
		
	If !(cAliasTFJ)->(Eof())
		cRet := (cAliasTFJ)->(ORCMAX)
	EndIf
		
	(cAliasTFJ)->( dbCloseArea() )
	

Return cRet