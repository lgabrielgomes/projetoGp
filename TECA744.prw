#INCLUDE 'PROTHEUS.CH' 
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TECA744.CH'

Static aTabPrc := {}

/*/{Protheus.doc} TECA744
Interface para inclusão de orçamento de serviços adicionais.

@author 	Leandro Dourado - Totvs Ibirapuera
@sample 	TECA744() 
@since		08/06/2016       
@version	P12   
/*/
Function TECA744()
Local oBrw    := FwMBrowse():New()
Private aRotina  := MenuDef()

At740SCmt(.T.)

oBrw:SetAlias( 'TFJ' )
oBrw:SetMenudef( 'TECA744' )
oBrw:SetDescription( OEmToAnsi( STR0001 ) ) //'Orçamentos de Serviço Extra' 
oBrw:SetFilterDefault("TFJ->TFJ_SRVEXT == '1'")
oBrw:AddLegend( "TFJ->TFJ_STATUS=='4'"						   , "GREEN" , STR0002 ) //"Orc. Serviços Extra em aberto"
oBrw:AddLegend( "TFJ->TFJ_STATUS=='1' .AND. !Empty(TFJ_ORCPAI)", "BLUE"  , STR0003 ) //"Orc. Serviços Extra Efetivado com Contrato"
oBrw:AddLegend( "TFJ->TFJ_STATUS=='1' .AND. Empty(TFJ_ORCPAI)" , "ORANGE", STR0004 ) //"Orc. Serviços Extra Efetivado sem Contrato"
oBrw:AddLegend( "TFJ->TFJ_STATUS=='5'"                         , "BLACK" , STR0013 ) //"Orc. Serviços Extra Encerrado"

oBrw:Activate()

At740SCmt(.F.)

Return

/*/{Protheus.doc} Menudef
Criacao do menu funcional da rotina

@author Leandro Dourado - Totvs Ibirapuera
@return	 	aMenu, Array, Opção para seleção no Menu
@since		14/06/2016       
@version	P12   
/*/
Static Function MenuDef()

Local aRotPE  := {}
Local nX      := 0
Local aRotina :={}

ADD OPTION aRotina TITLE STR0005 ACTION 'PesqBrw'         OPERATION 1 					   ACCESS 0	// "Pesquisar"
ADD OPTION aRotina TITLE STR0006 ACTION 'VIEWDEF.TECA744' OPERATION MODEL_OPERATION_VIEW   ACCESS 0	// "Visualizar"
ADD OPTION aRotina TITLE STR0007 ACTION 'At744Inclui'     OPERATION MODEL_OPERATION_INSERT ACCESS 0	// "Incluir"
ADD OPTION aRotina TITLE STR0008 ACTION 'At744Altera'     OPERATION MODEL_OPERATION_UPDATE ACCESS 0	// "Alterar"
ADD OPTION aRotina TITLE STR0009 ACTION 'At744Exclui'     OPERATION MODEL_OPERATION_DELETE ACCESS 0	// "Excluir"
ADD OPTION aRotina TITLE STR0010 ACTION 'TECA744A' 	      OPERATION MODEL_OPERATION_UPDATE ACCESS 0	// "Efetivar"
ADD OPTION aRotina TITLE STR0018 ACTION "MsDocument"	  OPERATION MODEL_OPERATION_INSERT ACCESS 0 //"Conhecimento"
ADD OPTION aRotina TITLE STR0019 ACTION "FATR600" 		  OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //"Impressão de Proposta"


 If ExistBlock("AT744MNU")
	aRotPE := ExecBlock("AT744MNU",.F.,.F.,{aRotina})
	If ValType(aRotPE) == "A"
		For nX := 1 To Len(aRotPe)
			aAdd(aRotina,aRotPe[nX])
		Next nX
	EndIf
EndIf

Return (aRotina)

/*/{Protheus.doc} ModelDef
Definicao do Modelo

@author Leandro Dourado - Totvs Ibirapuera
@since 06/08/2012
@version 11.7
/*/
Static Function ModelDef()
Local oModel  := Nil
Local oStrTFJ := Nil
Local lOrcPrc := SuperGetMv("MV_ORCPRC",,.F.)

If lOrcPrc 
	oModel := FwLoadModel("TECA740F")
Else
	oModel := FwLoadModel("TECA740")
EndIf

oStrTFJ := oModel:GetModel("TFJ_REFER"):GetStruct()
oStrTFJ:SetProperty("TFJ_CODENT",MODEL_FIELD_OBRIGAT,.T.)
oStrTFJ:SetProperty("TFJ_LOJA"  ,MODEL_FIELD_OBRIGAT,.T.)
oStrTFJ:SetProperty("TFJ_GRPFAT"  ,MODEL_FIELD_INIT , {|| "2" })

Return oModel

/*/{Protheus.doc} ViewDef
Definicao da Visao

@author Leandro Dourado - Totvs Ibirapuera
@since 14/08/2016
@version 12
/*/
Static Function ViewDef()
Local oModel     := ModelDef()
Local oView      := Nil
Local lOrcPrc    := SuperGetMv("MV_ORCPRC",,.F.)
Local oStrTFJ := Nil
Local oStrTFF := Nil
Local oStrTFG := Nil
Local oStrTFH := Nil
Local oStrTFI := Nil
Local cGsDsGcn := ""
Local cIsGsMt	:= ""

If lOrcPrc
	oView := FwLoadView("TECA740F")
Else
	oView := FwLoadView("TECA740")
EndIf

oView:SetModel(oModel)

oStrTFJ := oView:GetViewStruct('VIEW_REFER')

oStrTFJ:SetProperty('TFJ_CODENT', MVC_VIEW_CANCHANGE, .T.  )
oStrTFJ:SetProperty('TFJ_LOJA'  , MVC_VIEW_CANCHANGE, .T.  )
oStrTFJ:SetProperty('TFJ_CODENT', MVC_VIEW_LOOKUP   , "SA1")

// remove os campos que indicam fat. antecipado, contrato recorrente e regime de caixa
oStrTFJ:RemoveField( "TFJ_ANTECI" )
oStrTFJ:RemoveField( "TFJ_CNTREC" )
oStrTFJ:RemoveField( "TFJ_RGMCX" )

oStrTFF := oView:GetViewStruct('VIEW_RH')
oStrTFF:RemoveField("TFF_REFVLR")
oStrTFF:RemoveField("TFF_ORIREF")

oStrTFG := oView:GetViewStruct('VIEW_MI')
oStrTFH := oView:GetViewStruct('VIEW_MC')
oStrTFI := oView:GetViewStruct('VIEW_LE')

If IsInCallStack("At744Inclui")
	cGsDsGcn	:= SuperGetMv("MV_GSDSGCN",,"2")
	cIsGsMt  	:= SuperGetMv("MV_ISGSMT",,"2")
Else
	cGsDsGcn	:= TFJ->TFJ_DSGCN
	cIsGsMt  	:= TFJ->TFJ_ISGSMT
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

oView:SetAfterViewActivate({|oView| At744Init(oView)})

Return oView

/*/{Protheus.doc} At744Altera
Rotina responsável por fazer a exclusão de orçamentos de serviço extra.

@author 	Leandro Dourado - Totvs Ibirapuera
@since		14/07/2016       
@version	P12   
/*/
Function At744Altera()
Local lOrcPrc := SuperGetMv("MV_ORCPRC",,.F.)

If lOrcPrc
	aAdd(aTabPrc,TFJ->TFJ_CODTAB)
	aAdd(aTabPrc,TFJ->TFJ_TABREV)
EndIf

If TFJ->TFJ_STATUS == "1"
	Help("",1,"AT744ALTERA",,STR0014,2,0) //"Esse orçamento está efetivado e não poderá ser alterado!"
ElseIf TFJ->TFJ_STATUS == "5"
	Help("",1,"AT744ALTERA",,STR0015,2,0) //"Esse orçamento está encerrado e não poderá ser alterado!"
Else
	FWExecView(STR0008, "VIEWDEF.TECA744",MODEL_OPERATION_UPDATE,, {||.T.},,,,{||.T.}) //"Alterar"
EndIf

If lOrcPrc
	aSize( aTabPrc, 0 )
EndIf

Return

/*/{Protheus.doc} At744Exclui
Rotina responsável por fazer a exclusão de orçamentos de serviço extra.

@author 	Leandro Dourado - Totvs Ibirapuera
@since		14/07/2016       
@version	P12   
/*/
Function At744Exclui()
Local lOrcPrc := SuperGetMv("MV_ORCPRC",,.F.)

If lOrcPrc
	aAdd(aTabPrc,TFJ->TFJ_CODTAB)
	aAdd(aTabPrc,TFJ->TFJ_TABREV)
EndIf

If TFJ->TFJ_STATUS == "1" .OR. TFJ->TFJ_STATUS == "5"
	Help("",1,"AT744ALTERA",,STR0011,2,0) //"Esse orçamento está efetivado e não poderá ser excluído!"
Else
	FWExecView(STR0009, "VIEWDEF.TECA744",MODEL_OPERATION_DELETE,, {||.T.},,,,{||.T.}) //"Excluir"
EndIf

If lOrcPrc
	aSize(aTabPrc, 0)
EndIf

Return

/*/{Protheus.doc} At744Init
Inicializa campos que indicam que se trata de um orçamento de serviço extra.

@author 	Leandro Dourado - Totvs Ibirapuera
@since		14/07/2016       
@version	P12   
/*/
Function At744Init(oView)
Local oModel  := FwModelActive()
Local lOrcPrc := SuperGetMv("MV_ORCPRC",,.F.)
Local cTabela := ""
Local cRevisa := ""

At740Refre(oView)

If oModel:GetOperation() == MODEL_OPERATION_INSERT	
		
	If lOrcPrc
		cTabela := aTabPrc[1]
		cRevisa := aTabPrc[2]
	oModel:SetValue('TFJ_REFER','TFJ_CODTAB',cTabela)
	oModel:SetValue('TFJ_REFER','TFJ_TABREV',cRevisa)
	EndIf
	
	oModel:SetValue('TFJ_REFER','TFJ_STATUS','4')
	oModel:SetValue('TFJ_REFER','TFJ_SRVEXT','1')
	oModel:SetValue('TFJ_REFER','TFJ_ENTIDA','1')
	oModel:SetValue('TFJ_REFER','TFJ_ANTECI','2')  // não habilita faturamento antecipado
	oModel:SetValue('TFJ_REFER','TFJ_CNTREC','2')  // não habilita contrato recorrente
	oModel:SetValue('TFJ_REFER','TFJ_RGMCX','2')  // não habilita regime de caixa
	
	oView:Refresh()
EndIf

Return

/*/{Protheus.doc} At744GetTab
Retorna a tabela de precificação selecionada, caso o parâmetro MV_ORCPRC esteja habilitado.

@author 	Leandro Dourado - Totvs Ibirapuera
@since		14/07/2016       
@version	P12   
/*/
Function At744GetTab()
Return aTabPrc

/*/{Protheus.doc} At744Inclui
@description 	Retorna a tabela de precificação selecionada, caso o parâmetro MV_ORCPRC esteja habilitado.
@author 		josimar.assuncao
@since			06.07.2017 
@version		P12
/*/
Function At744Inclui( cAlias, cRecno, nOpc )
Local lContinua := .T.
Local lOrcPrc := SuperGetMv("MV_ORCPRC",,.F.)

If lOrcPrc
	If ConPad1( NIL,NIL,NIL,"TV6" )
		aAdd(aTabPrc,TV6->TV6_NUMERO)
		aAdd(aTabPrc,TV6->TV6_REVISA)
	Else
		lContinua := .F.
		Help(,, "AT744TABPRC",,STR0016,1,0,,,,,,;  // "Tabela de precificação não selecionada."
				{ STR0017 } )  // "Para prosseguir é necessário selecionar uma tabela de precificação."
	EndIf
EndIf

If lContinua
	FWExecView(STR0007, "VIEWDEF.TECA744",MODEL_OPERATION_INSERT,, {||.T.},,,,{||.T.}) // "Incluir"
EndIf

If lOrcPrc
	aSize( aTabPrc, 0 )
EndIf

Return