#INCLUDE "TOTVS.CH"  
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "GPEA061.CH"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ GPEA061  ³ Autor ³ Flavio S. Correa           ³ Data ³ 31/03/15   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Lançamento Vinculos - Beneficios(calculo automatico)              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Generico                                                          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³              ATUALIZACOES SOFRIDAS DESDE A CONSTRU€AO INICIAL.               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Programador   ³ Data   ³ BOPS/FNC  ³  Motivo da Alteracao                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Flavio Corr   ³31/03/15³PCREQ-2680 ³Inclusao de fonte                         ³±±
±±³Emerson Campos³25/06/2015³Fonte alterado pelo setor de Serviços com base no   ³±±
±±³              ³          ³Changeset 307854 de 11/06/2015 da Sustentação       ³±±
±±³Gabriel A.    ³14/07/16³TVKROM     ³Ajuste para que antes da montagem do      ³±±
±±³              ³        ³           ³browser/grid seja verificado se os        ³±±
±±³              ³        ³           ³registros da tabela S011 já foram         ³±±
±±³              ³        ³           ³vinculados.                               ³±±
±±³Allyson M     ³15/07/16³TVILOK     ³Ajuste para que antes da montagem do      ³±±
±±³              ³        ³           ³browser/grid seja verificado se os        ³±±
±±³              ³        ³           ³registros da tabela S011 já foram         ³±±
±±³Cícero Alves  ³26/09/16³TWDIHY     ³Ajuste para gravar corretamente o campo   ³±±
±±³              ³        ³           ³LY_AGRUP									 ³±±
±±³Allyson M     ³06/01/17³MRH-2908   ³Ajuste p/ validar bloqueio da CTT	     ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function GPEA061()
Local aArea         := GetArea()
Local aCoors  		:= FWGetDialogSize( oMainWnd )
Local cIdBrowse
Local cIdGrid
Local oPanelUp
Local oTela
Local oPanelDown
Local oRelacSJS
Local oDlgPrinc

Private oBrowseUp
Private oBrowseDwn


Define MsDialog oDlgPrinc Title OemToAnsi(STR0001) From aCoors[1], aCoors[2] To aCoors[3], aCoors[4] Pixel  //"Lancamento Vinculos"

// Cria o conteiner onde serão colocados os paineis
oTela     := FWFormContainer():New( oDlgPrinc )
cIdBrowse := oTela:CreateHorizontalBox( 40 )
cIdGrid   := oTela:CreateHorizontalBox( 55 )

oTela:Activate( oDlgPrinc, .F. )

//Cria os paineis onde serao colocados os browses
oPanelUp  	:= oTela:GeTPanel( cIdBrowse )
oPanelDown  := oTela:GeTPanel( cIdGrid )

dbSelectArea("SJQ")
SJQ->(dbsetOrder(4))
// FWmBrowse Superior: Agrupamentos
oBrowseUp:= FWmBrowse():New()
oBrowseUp:SetOwner( oPanelUp )                  // Aqui se associa o browse ao componente de tela
oBrowseUp:SetDescription( OemToAnsi(STR0002) )	//"Agrupamento"
oBrowseUp:SetAlias( 'SJQ' )
oBrowseUp:DisableDetails()
oBrowseUp:SetMenuDef( '' )  
oBrowseUp:SetProfileID( 'brw_GPEA061_1' )
oBrowseUp:SetCacheView (.F.) 
oBrowseUp:ExecuteFilter(.T.)
oBrowseUp:AddLegend( "SJQ->JQ_STATUS=='2'"		, 'RED'	, OemToAnsi(STR0004) ) //Inativa
oBrowseUp:AddLegend( "SJQ->JQ_STATUS=='1'"		, 'GREEN', OemToAnsi(STR0005) ) //Ativa	

oBrowseUp:Activate()

dbSelectArea("SJS")
SJS->(dbsetOrder(2))
// FWmBrowse Inferior: Entidades    
oBrowseDwn:= FWMBrowse():New()
oBrowseDwn:SetOwner( oPanelDown )
oBrowseDwn:SetDescription( OemToAnsi(STR0003) )	//"Entidades"
oBrowseDwn:SetMenuDef( 'GPEA061' )                       
oBrowseDwn:DisableDetails()
oBrowseDwn:SetAlias( 'SJS' )
oBrowseDwn:SetProfileID( 'brw_GPEA061_2' )
oBrowseDwn:ForceQuitButton()					//sempre que existem dois menudefs na tela, deve-se indicar em qual browse vai ficar o botao 'Sair'
oBrowseUp:SetAttach(.T.)
oBrowseDwn:SetCacheView (.F.)
oBrowseDwn:ExecuteFilter(.T.)
oBrowseDwn:Activate()


// Relacionamento entre os Paineis
oRelacSJS:= FWBrwRelation():New()
oRelacSJS:AddRelation( oBrowseUp  , oBrowseDwn , { { 'JS_FILIAL', 'JQ_FILIAL' }, {  'JS_CDAGRUP','JQ_CODIGO'  },{'JS_TABELA',"'SRA'",'<>'} } )
oRelacSJS:Activate()


oBrowseUp:Refresh()
oBrowseDwn:Refresh()

Activate MsDialog oDlgPrinc Center

RestArea(aArea)

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³MenuDef   ºAutor  ³Flavio S Correa     º Data ³  31/03/15   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Menu Funcional                                              º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³SIGAGPE                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function MenuDef()
Local aRotina 		:=  {}

ADD OPTION aRotina TITLE STR0006 ACTION 'PesqBrw'          	OPERATION 1 ACCESS 0 //"Pesquisar"
ADD OPTION aRotina TITLE STR0007 ACTION 'VIEWDEF.GPEA061' 	OPERATION 4 ACCESS 0 //"Manutencao"
ADD OPTION aRotina TITLE STR0008 ACTION 'VIEWDEF.GPEA061'	OPERATION 2 ACCESS 0 //"Visualizar"
	

Return aRotina

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ModelDef    ³ Autor ³ Flavio S Correa       ³ Data ³ 31/03/15 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Modelo de Dados da Rotina                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ModelDef()                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß/*/

Static Function ModelDef()
Local oModel    	                                      
Local oStruTMP 	:= FWFormModelStruct():New()
Local oStruSLY
Local oStruSJS

oModel := MPFormModel():New( 'GPEA061', /*bPreValid*/, /*bTudoOK*/, /*bCommiM040*/, /*bCancel*/ )

//Agrupamento
oStruSJS := FWFormStruct(1,"SJS")
oStruSJS:SetProperty( '*' , MODEL_FIELD_OBRIGAT, .F.)
A061Str( 1, @oStruSJS ,"SJS")
oModel:AddFields("GPEA061_MSJS", /*cOwner*/, oStruSJS , /*Pre-Validacao*/,/*Pos-Validacao*/,/*Carga*/)
oModel:GetModel( "GPEA061_MSJS" ):SetOnlyView(.T.)

//Tabela temporaria de beneficios
A061Str( 1,@oStruTMP  )
oModel:AddGrid("GPEA061_TMP","GPEA061_MSJS" , oStruTMP,/*bLinePre*/, /* bLinePost*/, /*bPre*/,  /*bPost*/,{|oGrid| A061Carga(oGrid) }/*bLoad*/) 
oModel:GetModel("GPEA061_TMP"):SetDescription(STR0012 )// "Beneficios"
oModel:GetModel("GPEA061_TMP"):SetNoInsertLine(.T.)
oModel:GetModel("GPEA061_TMP"):SetNoDeleteLine(.T.)
oModel:GetModel('GPEA061_TMP'):SetOnlyView(.T.)
oModel:GetModel('GPEA061_TMP'):SetOnlyQuery(.T.)


//Tabela de Vinculos
oStruSLY := FWFormStruct(1, "SLY")
oStruSLY:AddTrigger( "LY_CODIGO", "LY_DESBEN", {|| .T. }, {|oMdl| fInitBen(oMdl) }  )
oStruSLY:AddTrigger( "LY_CHVENT", "LY_DESENT", {|| .T. }, {|oMdl| fInitEnt(oMdl) }  )
oStruSLY:AddTrigger( "LY_TIPO"  , "LY_DESCTIP", {|| .T. }, {|oMdl| fInitTip(oMdl) }  ) // Trigger da descricao do tipo
oStruSLY:SetProperty("LY_FILENT", MODEL_FIELD_INIT, FwBuildFeature( STRUCT_FEATURE_INIPAD,'xFilial(SJS->JS_TABELA)'))
//oStruSLY:SetProperty("LY_DESCTIP", MODEL_FIELD_INIT, {|| fInitTip() })
oStruSLY:SetProperty("LY_TIPO", MODEL_FIELD_VALID, FwBuildFeature( STRUCT_FEATURE_VALID,'fVldTpBen()'))


oModel:AddGrid("GPEA061_SLY", "GPEA061_TMP", oStruSLY,/*bLinePre*/, { |oModel| SLY_LinhaOK(oModel) }/* bLinePost*/, /*bPre*/,  /*bPost*/,/*{|oGrid| CargaSRR(oGrid) }*//*bLoad*/) 
oModel:GetModel( "GPEA061_SLY" ):SetOptional(.T.)
											                                                                                                                                                                             
oModel:SetRelation( 'GPEA061_SLY', { { 'LY_FILIAL', 'xFilial( "SLY" )' }, { 'LY_AGRUP', 'SJS->JS_CDAGRUP' }, { 'LY_ALIAS', 'SJS->JS_TABELA' },{ 'LY_TIPO', 'TMP_TPBEN' }}, SLY->( IndexKey( 2 ) ) ) //LY_FILIAL+ LY_AGRUP+ LY_ALIAS+ LY_TIPO
oModel:GetModel('GPEA061_SLY'):SetUniqueLine({'LY_FILIAL','LY_TIPO','LY_AGRUP','LY_ALIAS','LY_FILENT','LY_CHVENT','LY_CODIGO','LY_DTINI'})

oModel:SetPrimaryKey( {"JS_FILIAL", "JS_CDAGRUP", "JS_TABELA"} )

oModel:SetActivate( { |oModel| fInitModel(oModel,oModel:GetOperation()) } )
Return oModel

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³fInitModel     ³ Autor ³ Leandro Drumond       ³ Data ³ 11/12/13 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³View                                                          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³fInitModel)                                                     ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß/*/
Static Function fInitModel(oModel,nOperation)

Local oModelDet	:= oModel:GetModel("GPEA061_SLY")
Local oGrid   	:= oModel:GetModel("GPEA061_SLY")

If nOperation == MODEL_OPERATION_INSERT

	oGrid:LoadValue("LY_AGRUP", "JQ_CODIGO")
	oGrid:LoadValue("LY_ALIAS", "JS_TABELA")

Endif

Return Nil

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ViewDef     ³ Autor ³ Leandro Drumond       ³ Data ³ 11/12/13 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³View                                                          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ViewDef()                                                     ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß/*/
Static Function ViewDef()

Local oModel   	:= FWLoadModel( 'GPEA061' )
Local oStruTMP 	:= FWFormViewStruct():New()
Local oStruSLY 	:= FWFormStruct(2, "SLY")	
Local oStruSJS  := FWFormStruct(2,"SJS")
Local oView

A061Str( 2, @oStruTMP )

oView := FWFormView():New()
oView:SetModel( oModel )

oStruSJS:AddGroup( 'GRPGRP', OemToAnsi(STR0002) , '', 2 )     //Agrupamento
A061Str( 2, @oStruSJS ,"SJS")
oStruSJS:SetProperty( "JS_DESGRP" , MVC_VIEW_GROUP_NUMBER , 'GRPGRP' )
oStruSJS:SetProperty( "JS_DTINI" , MVC_VIEW_GROUP_NUMBER , 'GRPGRP' )
oStruSJS:SetProperty( "JS_DTFIM" , MVC_VIEW_GROUP_NUMBER , 'GRPGRP' )


oStruSJS:AddGroup( 'GRPENT', OemToAnsi(STR0020) , '', 2 )     //Entidade 
oStruSJS:SetProperty( "JS_TABELA" , MVC_VIEW_GROUP_NUMBER , 'GRPENT' )
oStruSJS:SetProperty( "JS_DESENT" , MVC_VIEW_GROUP_NUMBER , 'GRPENT' )
oStruSJS:RemoveField("JS_CAMPO")
oStruSJS:RemoveField("JS_SEQ")
		
oView:AddField( 'VIEW_SJS', oStruSJS, 'GPEA061_MSJS' )
oView:AddGrid( 'VIEW_TMP', oStruTMP, 'GPEA061_TMP' )

oStruSLY:RemoveField("LY_FILENT")
oStruSLY:RemoveField("LY_FILIAL")
oStruSLY:RemoveField("LY_TIPO")
oStruSLY:RemoveField("LY_AGRUP")
oStruSLY:RemoveField("LY_ALIAS")

//se nao for entidade de serviço nao mostra esses campos
If !A061lServ()
	oStruSLY:RemoveField("LY_PGDUT")
	oStruSLY:RemoveField("LY_PGSAB")
	oStruSLY:RemoveField("LY_PGDOM")
	oStruSLY:RemoveField("LY_PGFER")
	oStruSLY:RemoveField("LY_PGSUBS")
	oStruSLY:RemoveField("LY_DIAS")
	oStruSLY:RemoveField("LY_PGFALT")
	oStruSLY:RemoveField("LY_PGAFAS")
	oStruSLY:RemoveField("LY_PGVAC")
EndIf
oStruSLY:SetProperty('LY_CHVENT' , MVC_VIEW_LOOKUP, A061SXB() )


oView:AddGrid( 'VIEW_SLY', oStruSLY, 'GPEA061_SLY' )

oView:CreateHorizontalBox( 'SUPERIOR', 50 )
oView:CreateVerticalBox( 'ESQUERDO', 30, 'SUPERIOR' )
oView:CreateVerticalBox( 'DIREITO', 70, 'SUPERIOR' )
	
oView:CreateHorizontalBox( 'INFERIOR', 50 )

oView:SetOnlyView('VIEW_SJS') //nao permite alteracoes no Grid
oView:SetOnlyView('VIEW_TMP') //nao permite alteracoes no Grid
If A061lServ() .Or. SJQ->JQ_STATUS == "2"
	oView:SetOnlyView('VIEW_SLY') //nao permite alteracoes no Grid
EndIf
oView:SetOwnerView( 'VIEW_TMP', 'DIREITO' )
oView:SetOwnerView( 'VIEW_SJS', 'ESQUERDO' )
oView:SetOwnerView( 'VIEW_SLY', 'INFERIOR' )


oView:SetCloseOnOk({ || .T. }) //Fecha tela apos commit

Return oView


/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A061Str     ³ Autor ³ Flavio S. Correa      ³ Data ³ 01/04/15 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Monta strutura tabela temporaria Benficios para Model/View    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß/*/
Static Function A061Str(nTipo, oStruct ,cTabela )
Local aArea    := GetArea()
Local bValid   := Nil
Local bWhen    := Nil
Local bRelac   := Nil
Local aTit 		:= {}
Local nI		:= 1

DEFAULT cTabela := "TMP

If cTabela == "TMP"
	aadd(aTit,{STR0009,STR0010,"TMP_TPBEN",'C',2,0,"@!",,,.T.,"C",bRelac,.F.})//"Tipo Ben"#"Tipo Beneficio"     
	aadd(aTit,{STR0011,STR0011,"TMP_BENEF",'C',50,0,"@!",,,.T.,"C",bRelac,.F.})//"Beneficio"     
ElseIf cTabela == "SJS"
	aadd(aTit,{STR0021,STR0021,"JS_DESGRP",'C',150,0,"@!",,,.T.,"C",{|| SJQ->JQ_DESCR},.T.})//"Descrição"     
	If Alltrim(SJS->JS_TABELA) != "SM0"
		aadd(aTit,{STR0021,STR0021,"JS_DESENT",'C',150,0,"@!",,,.T.,"C",{|| fDesc( "SX2" , SJS->JS_TABELA , "X2Nome()" , 30 , "" , 1 , .F. )},.T.})//Descrição"
	Else
		aadd(aTit,{STR0021,STR0021,"JS_DESENT",'C',150,0,"@!",,,.T.,"C",{|| STR0022},.T.})//Descrição"//Filiais
	Endif     
	aadd(aTit,{STR0024,STR0024,"JS_DTINI",'C',6,0,"",,,.T.,"C",{|| SJQ->JQ_PERINI},.T.})//
	aadd(aTit,{STR0025,STR0025,"JS_DTFIM",'C',6,0,"",,,.T.,"C",{|| SJQ->JQ_PERFIM},.T.})//
EndIf
For nI := 1 To Len(aTit)
	If nTipo = 1
		If cTabela=="TMP"
			oStruct:AddTable(cTabela,,STR0012) //beneficios
		EndIf
		oStruct:AddField( ;
			aTit[nI][1]           , ;              // [01] Titulo do campo
			aTit[nI][2]           , ;              // [02] ToolTip do campo
			aTit[nI][3]           , ;              // [03] Id do Field
			aTit[nI][4]           , ;              // [04] Tipo do campo
			aTit[nI][5]           , ;              // [05] Tamanho do campo
			aTit[nI][6]           , ;              // [06] Decimal do campo
			bValid                , ;              // [07] Code-block de validação do campo
			bWhen                 , ;              // [08] Code-block de validação When do campo
			aTit[nI][9]           , ;              // [09] Lista de valores permitido do campo
			.F.                   , ;              // [10] Indica se o campo tem preenchimento obrigatório
			aTit[nI][12]          , ;              // [11] Code-block de inicializacao do campo
			NIL                   , ;              // [12] Indica se trata-se de um campo chave
			Nil                   , ;              // [13] Indica se o campo não pode receber valor em uma operação de update.
			aTit[nI][13])          		           // [14] Indica se o campo é virtual
	Else
		oStruct:AddField( 				      ;
		   		aTit[nI][3]                 , ;              // [01] Campo
				alltrim(strzero(nI+3,2))  	, ;              // [02] Ordem
				aTit[nI][1]                 , ;              // [03] Titulo
				aTit[nI][1]                 , ;              // [04] Descricao
				NIL                    		, ;              // [05] Help
				aTit[nI][11]                , ;              // [06] Tipo do campo   COMBO, Get ou CHECK
				aTit[nI][7]                 , ;              // [07] Picture
				                       		, ;              // [08] PictVar
				                  			, ;              // [09] F3
				aTit[nI][10]   	            , ;              // [10] Editavel
				                      		, ;              // [11] Folder
				                  			, ;              // [12] Group
				 aTit[nI][9]                , ;              // [13] Lista Combo
				                       		, ;              // [14] Tam Max Combo
				                       		, ;              // [15] Inic. Browse
				aTit[nI][13])                                    // [16] Virtual
			
	EndIf

Next nI

RestArea( aArea )

Return oStruct

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A061Carga     ³ Autor ³ Flavio S. Correa    ³ Data ³ 01/04/15 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Carrega tabela temporaria Benficios para Model/View  	        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß/*/
Static Function A061Carga()
Local aRet 	:= {}
Local aBen 	:= {}
Local nI	:= 1
Local aTb11	:= {}

aadd(aBen,{"VR",STR0013})//"Vale Refeição"
aadd(aBen,{"VA",STR0014})//"Vale Alimentação"
aadd(aBen,{"PS",STR0015})//"Plano de Saude"

For nI := 1 To Len(aBen)
	aadd(aRet,{1,1})
	aRet[nI][1]	:= 1
	aRet[nI][2]	:= {aBen[nI][1],aBen[nI][2]}
Next nI

fCarrTab( @aTb11,"S011" )

//Verifica se o benefício já está vinculado na tabela SRN ou RFO para não apresentar.
fVerVinc(@aTb11)

For nI := 1 To Len(aTb11)
	aadd(aRet,{1,1})
	aRet[len(aRet)][1]	:= 1
	aRet[len(aRet)][2]	:= {aTb11[nI][5],aTb11[nI][6]}
Next nI

Return aRet

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³GP061F3     ³ Autor ³ Flavio S. Correa      ³ Data ³ 01/04/15 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Consulta padrao generica de beneficios			 	        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß/*/
Function GP061F3()
Local lRet 		:= .F.
Local cSXB		:= "RIS"
Local oModel	:= FwModelActive()
Local oBen		:= oModel:GetModel("GPEA061_TMP")	
Local oStructSLY	:= oModel:GetModel("GPEA061_SLY")
Local nLinha	:= 0
Local cTipoBen	:= ""
Local nLinSLY		:= oStructSLY:GetLine()

oStructSLY:GoLine(nLinSLY)
cTipoBen := oStructSLY:GetValue("LY_TIPO")

VAR_IXB := {"",""}

If Valtype(oBen) != "U" .and. Empty(cTipoBen)
	nLinha	:= oBen:GetLine()
	oBen:Goline(nLinha)
	cTipoBen := oBen:GetValue("TMP_TPBEN")
EndIf

If cTipoBen == "VR"
	cSXB := "RFO03"
	lRet := ConPad1(,,,cSXB )
	
	If lRet
		VAR_IXB[1] := RFO->RFO_CODIGO
		VAR_IXB[2] := RFO->RFO_DESCR 
	EndIf
ElseIf cTipoBen == "VA"
	cSXB := "RFO04"
	lRet := ConPad1(,,,cSXB )
	
	If lRet
		VAR_IXB[1] := RFO->RFO_CODIGO
		VAR_IXB[2] := RFO->RFO_DESCR 
	EndIf
ElseIf cTipoBen == "PS"
	cSXB := "SG0"
	lRet := ConPad1(,,,cSXB )
	If lRet
		VAR_IXB[1] := SG0->G0_CODIGO
		VAR_IXB[2] := SG0->G0_DESCR  
	EndIf 
Else
	cSXB := "RIS"
	lRet := ConPad1(,,,cSXB )
	If lRet
		VAR_IXB[1] := RIS->RIS_COD
		VAR_IXB[2] := RIS->RIS_DESC  
	EndIf   
EndIf

Return lRet

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³fVldCdBen   ³ Autor ³ Flavio S. Correa      ³ Data ³ 01/04/15 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Valida Codigo Beneficio                  			 	        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß/*/
Function fVldCdBen()
Local lRet 			:= .T.
Local aArea 		:= GetArea()
Local oModel		:= FwModelActive()
Local oBen			:= oModel:GetModel("GPEA061_TMP")	
Local oStructSLY	:= oModel:GetModel("GPEA061_SLY")
Local nLinha		:= 0
Local nLinSLY		:= oStructSLY:GetLine()
Local nTamCpo		:= Len(alltrim(oStructSLY:GetValue("LY_CODIGO")))
Local nTamTab		:= 0
local cTipoBen		:= ""

oStructSLY:GoLine(nLinSLY)
If !Empty(oStructSLY:GetValue("LY_CODIGO"))
	cTipoBen := oStructSLY:GetValue("LY_TIPO")
	
	If Valtype(oBen) != "U" .and. Empty(cTipoBen)
		nLinha	:= oBen:GetLine()
		oBen:Goline(nLinha)
		cTipoBen := oBen:GetValue("TMP_TPBEN")
	EndIf
	
	
	If cTipoBen == "VR"
		//1=Vale Refeicao;2=Vale Alimentacao                                                                                              
		dbSelectArea("RFO") 
		RFO->(dbSetOrder(1)) 
		lRet := RFO->(dbSeek(xFilial("RFO")+"1"+Alltrim(oStructSLY:GetValue("LY_CODIGO"))))
	ElseIf cTipoBen == "VA"
		//1=Vale Refeicao;2=Vale Alimentacao                                                                                              
		dbSelectArea("RFO")
		RFO->(dbSetOrder(1))
		lRet := RFO->(dbSeek(xFilial("RFO")+"2"+Alltrim(oStructSLY:GetValue("LY_CODIGO"))))
	ElseIf cTipoBen == "PS"
		dbSelectArea("SG0")
		SG0->(dbSetOrder(1))
		lRet := SG0->(dbSeek(xFilial("SG0")+Alltrim(oStructSLY:GetValue("LY_CODIGO"))))
	Else
		dbSelectArea("RIS")
		RIS->(dbSetOrder(1))
		lRet := RIS->(dbSeek(xFilial("RIS")+cTipoBen+Alltrim(oStructSLY:GetValue("LY_CODIGO"))))
	EndIf
	
	If !lRet
		Help( , , 'HELP', , OemToAnsi( STR0018 ), 1, 0 ) //"Benefício não encontrado!"
	EndIf
EndIf
RestArea(aArea)
Return lRet

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A061lServ   ³ Autor ³ Flavio S. Correa      ³ Data ³ 01/04/15 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Verifica se é entidade de gestao de serviços		 	        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß/*/
Static Function A061lServ()
Local lRet	:= .F.
Local aArea	:= GetArea()
Local cQry	:= GetNextAlias()

If SJS->JS_TABELA == "SM0"
	BeginSql alias cQry
		SELECT JS_TABELA
		FROM %table:SJS% SJS
		WHERE JS_FILIAL=%exp:SJS->JS_FILIAL% 
		AND JS_CDAGRUP=%exp:SJS->JS_CDAGRUP%
		AND JS_TABELA IN ('ABS','SA1','TDX')
		and SJS.%notdel%
	EndSql
	If !(cQry)->(eof())
		lRet := .T.
	EndIf
	(cQry)->(dbCloseArea())
Else
	lRet := SJS->JS_TABELA $ "ABS/SA1/TDX"
EndIf

RestArea(aArea)
Return lRet

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³SLY_LinhaOK ³ Autor ³ Flavio S. Correa      ³ Data ³ 01/04/15 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Linha OK do grid SLY		               			 	        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß/*/
Function SLY_LinhaOK(oStructSLY)
Local lRet 		:= .T.
Local dDtIniA	:= stod(SJQ->JQ_PERINI+"01")
Local dDtFimA	:= stod(SJQ->JQ_PERFIM+alltrim(str(day(lastday(stod(SJQ->JQ_PERFIM+"01"))))))
Local dDtIni	:= oStructSLY:GetValue("LY_DTINI")
Local dDtFim	:= oStructSLY:GetValue("LY_DTFIM")
Local cChave	:= oStructSLY:GetValue("LY_CHVENT")
Local cCod		:= oStructSLY:GetValue("LY_CODIGO")
Local cTipo		:= oStructSLY:GetValue("LY_TIPO")
Local nI		:= 1
Local nAtual	:= oStructSLY:GetLine()
Local aPer		:= {}
Local cTip		:= ""

dbSelectArea("SJQ")
SJQ->(dbSetOrder(3))//JQ_FILIAL+JQ_CODIGO                                                                                                                                             
If SJQ->(dbSeek(xFilial("SJQ")+oStructSLY:GetValue("LY_AGRUP")))
	dDtIniA	:= stod(SJQ->JQ_PERINI+"01")
	dDtFimA	:= stod(SJQ->JQ_PERFIM+alltrim(str(day(lastday(stod(SJQ->JQ_PERFIM+"01"))))))
EndIf
/*
D  = VR
E  = VA
C  = PS
I  = Outros Beneficios
*/

Do Case
	Case (oStructSLY:GetValue("LY_TIPO") == "VR")
		cTip := "D"
	Case (oStructSLY:GetValue("LY_TIPO") == "VA")
		cTip := "E"
	Case (oStructSLY:GetValue("LY_TIPO") == "PS")
		cTip := "C"
	OtherWise
		cTip := "I"
EndCase

If dDtIni < dDtIniA
	Help( , , 'HELP', , OemToAnsi( STR0016 + dToC(dDtIniA) ), 1, 0 ) //"Data inicial não pode ser menor que "
	lRet := .F.
EndIf

If !Empty(dDtFimA)
	If dDtFim > dDtFimA
		Help( , , 'HELP', , OemToAnsi( STR0017 + dToC(dDtFimA) ), 1, 0 ) //"Data Final não pode ser maior que "
		lRet := .F.
	EndIf
EndIf

If !Empty(dDtFim)
	If dDtFim < dDtIni
		Help( , , 'HELP', , OemToAnsi( STR0023 ), 1, 0 ) //"Data Final não pode ser menor que a inicial "
		lRet := .F.
	EndIf
	
	fGetPerAtual( @aPer, xFilial("RCH"), SRA->RA_PROCES, fGetCalcRot(cTip) )
	If !Empty(aPer)
		If dDtFim < aPer[1,7]
			Help( , , 'HELP', , OemToAnsi( STR0028 + dToC(aPer[1,7]) ), 1, 0 ) //"Data Final não pode ser menor que a data final do periodo :"                                                                                                                                                                                                                                                                                                                                                                                                                                                       
			lRet := .F.
		EndIf
	EndIf
EndIf

For nI := 1 To oStructSLY:GetQtdLine()
	If nAtual <> nI 
		oStructSLY:Goline(nI)
		If !oStructSLY:Isdeleted()
			If cTipo == oStructSLY:GetValue("LY_TIPO") .And. cChave == oStructSLY:GetValue("LY_CHVENT") .And. cCod == oStructSLY:GetValue("LY_CODIGO")
				IF ((dDtIni) >= oStructSLY:GetValue("LY_DTINI") .And. (Empty(oStructSLY:GetValue("LY_DTFIM")) .OR. dDtIni <= oStructSLY:GetValue("LY_DTFIM") )) .Or. ;
				   (dDtIni <= oStructSLY:GetValue("LY_DTINI") .And. (Empty(dDtFim) .OR. dDtFim >= oStructSLY:GetValue("LY_DTINI")))
						Help(" ", 1, OemToAnsi(STR0026),, OemToAnsi(STR0027), 1, 0) // "Já existe configuração para este período"                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
						lRet := .F.
						Exit
				Endif
			EndIf
		EndIf
	EndIf
Next nI
oStructSLY:Goline(nAtual)
Return lRet

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³SLY_LinhaOK ³ Autor ³ Flavio S. Correa      ³ Data ³ 01/04/15 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Consulta Padrao entidades	               			 	        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß/*/
Static Function A061SXB()
Local aTab 	:= {"SQB","CTT","RCL","SQ3","SRJ","SR6","RCE","SM0"}
Local aSXB 	:= {"SQB_01","CTT002","RCLCAR","SQ3_01","SRJ_01","SR6","RCE","SM0"}
Local nPos	:= 0
Local cSXB	:= ""
nPos := Ascan(aTab,{|x| x == Alltrim(SJS->JS_TABELA)})
If nPos > 0
	cSxb := aSXB[nPos]
EndIf

Return cSxb

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³fInitBen    ³ Autor ³ Flavio S. Correa      ³ Data ³ 01/04/15 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Inicializador padrao Codigo Beneficio    			 	        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß/*/
Function fInitBen(oStructSLY)
Local cRet 		:= ""
Local aArea 	:= GetArea()
Local oModel	:= ''
Local oBen		:= ''	
Local nLinha	:= ''
Local cChave	:= ""
Local cTipoBen	:= ""
Local oModel	:= FwModelActive()
Local oMdlSLY	:= oModel:GetModel("GPEA061_SLY")

If Valtype(oStructSLY) == "U"
	If oMdlSLY:GetLine() == 0 
		cChave := Alltrim(SLY->LY_CODIGO)
		cTipoBen := Alltrim(SLY->LY_TIPO)
	End
Else
	cChave := Alltrim(oStructSLY:GetValue("LY_CODIGO"))
	cTipoBen := Alltrim(oStructSLY:GetValue("LY_TIPO"))
EndIF

oModel	:= FwModelActive()
oBen	:= oModel:GetModel("GPEA061_TMP")	

If Valtype(oBen) != "U" .And. Empty(cTipoBen)
	nLinha	:= oBen:GetLine()
	oBen:Goline(nLinha)
	cTipoBen := oBen:GetValue("TMP_TPBEN")
EndIf

If !Empty(cChave)
	If cTipoBen == "VR"
		//1=Vale Refeicao;2=Vale Alimentacao                                                                                              
		cRet  := Fdesc("RFO", "1"+cChave, "RFO_DESCR")
	ElseIf cTipoBen == "VA"
		//1=Vale Refeicao;2=Vale Alimentacao                                                                                              
		cRet  := Fdesc("RFO", "2"+cChave, "RFO_DESCR")
	ElseIf cTipoBen == "PS"
		cRet  := Fdesc("SG0", cChave, "G0_DESCR")
	Else
		cRet  := Fdesc("RIS", cTipoBen+cChave, "RIS_DESC")
	EndIf
EndIf

RestArea(aArea)
Return cRet

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³fInitEnt    ³ Autor ³ Flavio S. Correa      ³ Data ³ 01/04/15 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Inicializador padrao Entidades		   			 	        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß/*/
Function fInitEnt(oStructSLY)
Local cRet 		:= ""
Local aArea 	:= GetArea()
Local oModel	
Local cChave	:= ""

If Valtype(oStructSLY) == "U"
	cChave := Alltrim(SLY->LY_CHVENT) 
Else
	cChave := Alltrim(oStructSLY:GetValue("LY_CHVENT"))
EndIF

If !Empty(cChave)
	Do Case
		Case SJS->JS_TABELA == "SQB"
			cRet  := Fdesc("SQB", cChave, "QB_DESCRIC")
		Case SJS->JS_TABELA == "CTT"
			cRet  := Fdesc("CTT", cChave, "CTT_DESC01")
		Case SJS->JS_TABELA == "RCL"
			cRet  := ""
		Case SJS->JS_TABELA == "SQ3"
			cRet  := Fdesc("SQ3", cChave, "Q3_DESCSUM")
		Case SJS->JS_TABELA == "SRJ"
			cRet  := Fdesc("SRJ", cChave, "RJ_DESC")
		Case SJS->JS_TABELA == "SR6"
			cRet  := Fdesc("SR6", cChave, "R6_DESC")
		Case SJS->JS_TABELA == "RCE"
			cRet  := Fdesc("RCE", cChave, "RCE_DESCRI")
		Case SJS->JS_TABELA == "SM0"
			cRet  := FWFilialName(,cChave)
		
		OtherWise
			cRet  := ""
	EndCase
EndIf
RestArea(aArea)
Return cRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} fInitTip

Retorna a descrição do campo LY_DESCTIP

@sample 	fInitTip(oStructSLY)
@param		ExpO	Objeto:Modelo
@return	ExpC	Descrição
@since		10/06/2015
@author	Serviços       
@version	P12   
/*/
//------------------------------------------------------------------------------
Function fInitTip(oStructSLY)
Local cChave 	:= ""
Local aArea 	:= GetArea()
Local aRet		:= {}
Local nPos		:= 0
Local cRet		:= "" 
Local oModel	:= FwModelActive()
Local oMdlSLY	:= oModel:GetModel("GPEA061_SLY")
Local aLnChg	:= {}

aLnChg := oMdlSLY:GetLinesChanged()	

If Valtype(oStructSLY) == "U" 
	If oMdlSLY:GetLine() == 0 
		cChave := Alltrim(SLY->LY_TIPO)
	EndIf
Else
	cChave := Alltrim(oStructSLY:GetValue("LY_TIPO"))
EndIF

IF !Empty(cChave)
	aRet := A061Carga()
	nPos := ascan(aRet,{|x| x[2][1] == cChave})
ENDIF
	
If nPos > 0
	cRet := aRet[nPos][2][2]
Else
	cRet := ""
EndIf

RestArea(aArea)
Return cRet

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³fVldCdEnt    ³ Autor ³ Flavio S. Correa      ³ Data ³ 01/04/15 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Valid Entidades						   			 	        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß/*/
Function fVldCdEnt()
Local lRet 		:= .T.
Local lRetBloq 	:= .F.
Local aArea 	:= GetArea()
Local oModel		:= FwModelActive()
Local oStructSLY	:= oModel:GetModel("GPEA061_SLY")
Local nLinSLY		:= oStructSLY:GetLine()
Local nTamCpo		:= Len(alltrim(oStructSLY:GetValue("LY_CHVENT")))
Local nTamTab		:= 0
oStructSLY:GoLine(nLinSLY)

Do Case
	Case SJS->JS_TABELA == "SQB"
		dbSelectArea("SQB")
		SQB->(dbSetOrder(1))
		nTamTab := GetSx3Cache("QB_DEPTO","X3_TAMANHO")
		If nTamCpo > nTamTab
			lRet := .F.
		Else
			lRet  := SQB->(dbSeek(xFilial("SQB")+alltrim(oStructSLY:GetValue("LY_CHVENT"))))
		EndIf
	Case SJS->JS_TABELA == "CTT"
		dbSelectArea("CTT")
		CTT->(dbSetOrder(1))
		nTamTab := GetSx3Cache("CTT_CUSTO","X3_TAMANHO")
		If nTamCpo > nTamTab
			lRet := .F.
		Else
			lRet  := CTT->(dbSeek(xFilial("CTT")+alltrim(oStructSLY:GetValue("LY_CHVENT"))))
		EndIf
		
		If lRet
			lRet 	 := ValidaBloq(AllTrim(oStructSLY:GetValue("LY_CHVENT")),dDataBase,"CTT")
			lRetBloq := !lRet
		EndIf		
	Case SJS->JS_TABELA == "RCL"
		dbSelectArea("RCL")
		RCL->(dbSetOrder(2))
		nTamTab := GetSx3Cache("RCL_POSTO","X3_TAMANHO")
		If nTamCpo > nTamTab
			lRet := .F.
		Else
			lRet  := RCL->(dbSeek(xFilial("RCL")+alltrim(oStructSLY:GetValue("LY_CHVENT"))))
		Endif
	Case SJS->JS_TABELA == "SQ3"
		dbSelectArea("SQ3")
		SQ3->(dbSetOrder(1))
		nTamTab := GetSx3Cache("Q3_CARGO","X3_TAMANHO")
		If nTamCpo > nTamTab
			lRet := .F.
		Else
			lRet  := SQ3->(dbSeek(xFilial("SQ3")+alltrim(oStructSLY:GetValue("LY_CHVENT"))))
		EndIf
	Case SJS->JS_TABELA == "SRJ"
		dbSelectArea("SRJ")
		SRJ->(dbSetOrder(1))
		nTamTab := GetSx3Cache("RJ_FUNCAO","X3_TAMANHO")
		If nTamCpo > nTamTab
			lRet := .F.
		Else
			lRet  := SRJ->(dbSeek(xFilial("SRJ")+alltrim(oStructSLY:GetValue("LY_CHVENT"))))
		EndIf
	Case SJS->JS_TABELA == "SR6"
		dbSelectArea("SR6")
		SR6->(dbSetOrder(1))
		nTamTab := GetSx3Cache("R6_TURNO","X3_TAMANHO")
		If nTamCpo > nTamTab
			lRet := .F.
		Else
			lRet  := SR6->(dbSeek(xFilial("SR6")+alltrim(oStructSLY:GetValue("LY_CHVENT"))))
		EndIf
	Case SJS->JS_TABELA == "RCE"
		dbSelectArea("RCE")
		RCE->(dbSetOrder(1))
		nTamTab := GetSx3Cache("RCE_CODIGO","X3_TAMANHO")
		If nTamCpo > nTamTab
			lRet := .F.
		Else
			lRet  := RCE->(dbSeek(xFilial("RCE")+alltrim(oStructSLY:GetValue("LY_CHVENT"))))
		EndIf
	Case SJS->JS_TABELA == "SM0"
		lRet  := FWFilExist(,alltrim(oStructSLY:GetValue("LY_CHVENT"))) 
EndCase

If !lRet .And. !lRetBloq
	Help( , , 'HELP', , OemToAnsi( STR0019 ), 1, 0 ) //"Entidade inválida!"
EndIf

If lRetBloq
	Help( " " , 1 , "CTA_BLOQ" ,, "CTT: " + AllTrim(oStructSLY:GetValue("LY_CHVENT")),3,0)
EndIf

RestArea(aArea)
Return lRet

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³GPCRGTPBEN  ³ Autor ³ Flavio S. Correa      ³ Data ³ 22/04/15 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Retorno de dados para consulta padrao GPTPBE			        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß/*/
Function GPCRGTPBEN()
Local aArea := GetArea()
Local lRet	:= .T.
lRet := GP310SXB("S011","BRA_S01101",,"BRA_S01102")                                                                                                                                                                                                                             

RestArea(aArea)
Return lRet 

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³fVldTpBen   ³ Autor ³ Flavio S. Correa      ³ Data ³ 01/04/15 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Valida Codigo Beneficio                  			 	        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß/*/
Function fVldTpBen()
Local lRet 			:= .T.
Local aArea 		:= GetArea()
Local oModel		:= FwModelActive()
Local oStructSLY	:= oModel:GetModel("GPEA061_SLY")
Local nLinSLY		:= oStructSLY:GetLine()
Local aRet			:= {}
Local nPos			:= 0 

oStructSLY:GoLine(nLinSLY)

aRet := A061Carga()
nPos := ascan(aRet,{|x| x[2][1] == oStructSLY:GetValue("LY_TIPO")})
//oStructSLY:LoadValue("LY_CODIGO","")

If nPos > 0
	oStructSLY:LoadValue("LY_DESCTIP",aRet[nPos][2][2])
	lRet := .T.
Else
	oStructSLY:LoadValue("LY_DESCTIP","")
	lRet := .F.
EndIf
If !lRet
	Help( , , 'HELP', , OemToAnsi( STR0029 ), 1, 0 ) //"Tipo de Benefício invalido!"
EndIf

RestArea(aArea)
Return lRet