#Include 'Protheus.ch'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TECA890.CH'

//Variaveis para verificar periodo de apontamento para contrato recorrente
Static cPriDia		:= "01"									//Primeiro dia do Mes
Static cUltDia		:= StrZero( F_UltDia(dDataBase), 2 )    //Ultimo dia do mes corrrente
Static cMesCor		:= StrZero( Month(dDataBase)   , 2 )	//Mes do dia corrente
Static cAnoCor	 	:= Alltrim(Str ( Year(dDataBase)))      //Ano do Mes corrente 
Static lLegend		:= .T.
Static nSaldoKit 	:= 0
Static cKitExcl  	:= ""
Static lSigaMdtGS	:= SuperGetMv("MV_NG2GS",.F.,.F.)	//Par�metro de integra��o entre o SIGAMDT x SIGATEC
Static lStKit		:= .F.
Static lPeriod	:= .F.
Static lAprov		:= .F.
Static aMDT		:= {}

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECA890
 
Realiza apontamento dos materiais de Recursos Humanos do Local de Atencimento
@author Servi�os
@since 31/10/13
@version P11 R9

@return  .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TECA890()
Local oBrowse
Local aColumns	:= {}
Local cQuery	:= ""
Local cAliasPro	:= "MNTPRO2"
Local oDlg 		:= Nil   							// Janela Principal.
Local aSize	 	:= FWGetDialogSize( oMainWnd ) 	// Array com tamanho da janela.
Local aRotina	:= {}

Private cCadastro := ""

oBrowse := FWFormBrowse():New()

Pergunte("TEC890",.F.)

SetKey( VK_F12 ,{|| Iif (Pergunte("TEC890",.T.), Refresh(oBrowse,cAliasPro),Nil)})//Filtro atrav�s de F12

aColumns := At890Cols(cAliasPro)
cQuery   := At890Query()

DEFINE DIALOG oDlg TITLE STR0001 FROM aSize[1],aSize[2] TO aSize[3],aSize[4] PIXEL // "Apontamento de Materiais"
	
// Cria um Form Browse
oBrowse := FWFormBrowse():New()
// Atrela o browse ao Dialog form nao abre sozinho
oBrowse:SetOwner(oDlg)
// Indica que vai utilizar query
oBrowse:SetAlias(cAliasPro)
oBrowse:SetDataQuery(.T.)
oBrowse:SetQuery(cQuery)

oBrowse:SetColumns(aColumns)
	
oBrowse:AddButton(STR0001,; //"Aloca��o de atendentes"
		{|| MsgRun(STR0024,STR0025,{|| At890Apon((cAliasPro)->TFL_CODIGO,(cAliasPro)->TFJ_GESMAT,(cAliasPro)->TFJ_GSMTMI,(cAliasPro)->TFJ_GSMTMC,(cAliasPro)->TFJ_ISGSMT)} ) },,,,.F.,1)// "Montando os componentes visuais..."##"Aguarde" 						 

oBrowse:AddButton(STR0032,; //"Retorno Material de Implanta��o" 
		{|| MsgRun(STR0024,STR0025,{|| At890RtMip((cAliasPro)->TFL_CODIGO, (cAliasPro)->TFL_CONTRT, (cAliasPro)->TFJ_GESMAT,(cAliasPro)->TFJ_GSMTMI,(cAliasPro)->TFJ_GSMTMC,(cAliasPro)->TFJ_ISGSMT) } ) },,,,.F.,1)// "Montando os componentes visuais..."##"Aguarde" 						 

oBrowse:AddButton(STR0111,; //"Relatorio Apontamento de Material" 
		{|| MsgRun(STR0112,STR0025,{|| TECR890A() } ) },,,,.F.,1)// "Gerando Relatorio"##"Aguarde" 						 


oBrowse:AddButton( STR0023, { || oDlg:End() },,,, .F., 2 )	//'Sair'

oBrowse:SetDescription(STR0001)	//"Apontamento de Materiais"

oBrowse:Activate()

ACTIVATE DIALOG oDlg CENTERED
oBrowse:DeActivate()

SetKey( VK_F12, Nil )

Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef

MenuDef do Fonte TECA890
@author Servi�os
@since 31/10/13
@version P11 R9

@return  .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function MenuDef()
Local aRotina := {}

ADD OPTION aRotina TITLE STR0002 ACTION 'VIEWDEF.TECA890'	OPERATION 4	ACCESS 0 //"Apontamento"

Return (aRotina)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef

Cria��o do Modelo de Dados conforme arquitetura MVC
@author Servi�os
@since 31/10/13
@version P11 R9
@return oModel: Modelo de Dados
/*/
//--------------------------------------------------------------------------------------------------------------------

Static Function ModelDef()

Local oStruTFL 	  := FwFormStruct(1,'TFL',/*bAvalCampo*/,/*lViewUsado*/)
Local oStrGrdMtCn := FwFormStruct(1,'TFT',/*bAvalCampo*/,/*lViewUsado*/)
Local oStGrdMtImp := FwFormStruct(1,'TFS',/*bAvalCampo*/,/*lViewUsado*/)
Local oStFuncMat  := FwFormStruct(1,'T4A' )
Local oModel
//Local bDcommit 	:= {|oModel| At890Commit(oModel)}
Local bDcommit 	:= {|oModel| At890Cmt(oModel)}
Local bPosValid	:= {|oModel| At890PosVld(oModel)}
Local aAux4	  	:= {}
Local bVldPrd    	:= FwBuildFeature( STRUCT_FEATURE_VALID, "Vazio() .Or. At890IsVld( a, b, c, d )" )
Local cDtIni	  	:= cAnoCor + cMesCor + cPriDia
Local cDtFin	  	:= cAnoCor + cMesCor + cUltDia 
Local bVldAct		:= {|oModel| At890Vig(oModel)}

lLegend			  := .T.

//Cria��o dos Campos
oStrGrdMtCn:AddField(STR0003,STR0003,'TFT_SIT','BT',1,0,{||At890GetLg()}/*bValid*/,/*bWhen*/, /*aValues*/, .F., {|| At890LgTFT()},/*lKey*/, /*lNoUpd*/, .T./*lVirtual*/,/*cValid*/)//"Status"
oStGrdMtImp:AddField(STR0003,STR0003,'TFS_SIT','BT',1,0,{||At890GetLg()}/*bValid*/,/*bWhen*/, /*aValues*/, .F., {|| At890LgTFS()},/*lKey*/, /*lNoUpd*/, .T./*lVirtual*/,/*cValid*/)//"Status"

oStrGrdMtCn:AddField(STR0004,STR0004,'TFT_SLDTTL','N',11,2,/* */,/*bValid*/, /*bWhen*/, .F., /* */,/*lKey*/, /*lNoUpd*/, .T./*lVirtual*/,/*cValid*/)//"Saldo"
oStGrdMtImp:AddField(STR0004,STR0004,'TFS_SLDTTL','N',11,2,/* */,/*bValid*/, /*bWhen*/, .F., /* */,/*lKey*/, /*lNoUpd*/, .T./*lVirtual*/,/*cValid*/)//"Saldo"

//When dos campos
oStGrdMtImp:SetProperty("*"         ,MODEL_FIELD_WHEN,{|| Empty(FwFldGet("TFS_ITAPUR")) .AND. At890IsKitCmp("TFS",.T.)})
oStGrdMtImp:SetProperty("TFS_PRODUT",MODEL_FIELD_WHEN,{|| Empty(FwFldGet("TFS_ITAPUR"))                               })
oStGrdMtImp:SetProperty("TFS_DPROD" ,MODEL_FIELD_WHEN,{|| .T.                               })
oStGrdMtImp:SetProperty("TFS_DESKIT",MODEL_FIELD_WHEN,{|| .T.                               })
oStGrdMtImp:SetProperty("TFS_CODTFG",MODEL_FIELD_WHEN,{|| Empty(FwFldGet("TFS_ITAPUR")) .AND. At890IsKitCmp("TFS",.F.)})
oStGrdMtImp:SetProperty("TFS_QUANT" ,MODEL_FIELD_WHEN,{|| Empty(FwFldGet("TFS_ITAPUR")) .AND. At890IsKitCmp("TFS",.F.)})
oStGrdMtImp:SetProperty("TFS_SLDTTL",MODEL_FIELD_WHEN,{|| .T. })
oStGrdMtImp:SetProperty("TFS_SIT"	,MODEL_FIELD_WHEN,{|| .T. })
oStGrdMtImp:SetProperty("TFS_USRAPV",MODEL_FIELD_WHEN,{|| At890APV("TFS") })

oStrGrdMtCn:SetProperty("*"         ,MODEL_FIELD_WHEN,{|| Empty(FwFldGet("TFT_ITAPUR")) .AND. At890IsKitCmp("TFT",.T.)})
oStrGrdMtCn:SetProperty("TFT_PRODUT",MODEL_FIELD_WHEN,{|| Empty(FwFldGet("TFT_ITAPUR"))                               })
oStrGrdMtCn:SetProperty("TFT_DPROD" ,MODEL_FIELD_WHEN,{|| .T.                               })
oStrGrdMtCn:SetProperty("TFT_DESKIT",MODEL_FIELD_WHEN,{|| .T.                               })
oStrGrdMtCn:SetProperty("TFT_CODTFH",MODEL_FIELD_WHEN,{|| Empty(FwFldGet("TFT_ITAPUR")) .AND. At890IsKitCmp("TFT",.F.)})
oStrGrdMtCn:SetProperty("TFT_QUANT" ,MODEL_FIELD_WHEN,{|| Empty(FwFldGet("TFT_ITAPUR")) .AND. At890IsKitCmp("TFT",.F.)})
oStrGrdMtCn:SetProperty("TFT_SLDTTL",MODEL_FIELD_WHEN,{|| .T. })
oStrGrdMtCn:SetProperty("TFT_SIT"	,MODEL_FIELD_WHEN,{|| .T. })
oStrGrdMtCn:SetProperty("TFT_USRAPV",MODEL_FIELD_WHEN,{|| At890APV("TFT") })

//Valida��o dos campos
oStrGrdMtCn:SetProperty("TFT_LOCALI",MODEL_FIELD_VALID,{|| .T. /*ExistCpo("SBE",FwFldGet("TFT_LOCAL")+FwFldGet("TFT_LOCALI"),1)*/ })

oStrGrdMtCn:SetProperty("TFT_QUANT" ,MODEL_FIELD_VALID,{|| Positivo() .And. At890ValdQnt(FWFLDGET("TFT_QUANT"), "TFH", FWFLDGET("TFT_CODTFH")) })
oStGrdMtImp:SetProperty("TFS_QUANT" ,MODEL_FIELD_VALID,{|| Positivo() .And. At890ValdQnt(FWFLDGET("TFS_QUANT"), "TFG", FWFLDGET("TFS_CODTFG")) })

oStFuncMat:SetProperty("T4A_QTDENT",MODEL_FIELD_VALID,{|| AT890VlQtd( oModel, FWFLDGET("T4A_QTDENT")) })
oStFuncMat:SetProperty("T4A_CODEPI",MODEL_FIELD_VALID,{|| At890VPEPI( oModel, FWFLDGET("T4A_CODEPI")) })

oStGrdMtImp:SetProperty( "TFS_PRODUT", MODEL_FIELD_VALID, bVldPrd )
oStrGrdMtCn:SetProperty( "TFT_PRODUT", MODEL_FIELD_VALID, bVldPrd )

//Iniciado padrao
oStFuncMat:SetProperty("T4A_CODEPI"	,MODEL_FIELD_INIT,{|| At890T4AProd(oModel,"T4A_CODEPI") })
oStFuncMat:SetProperty("T4A_DESC"	,MODEL_FIELD_INIT,{|| At890T4AProd(oModel,"T4A_DESC") })

oStGrdMtImp:SetProperty("TFS_USER"	,MODEL_FIELD_INIT,{|| RetCodUsr() })			 //Codigo do usuario logado no protheus
oStGrdMtImp:SetProperty("TFS_HORA"	,MODEL_FIELD_INIT,{|| SubStr(Time(),1,5)	 }) //Hora do apontamento no formato HH:MM

oStrGrdMtCn:SetProperty("TFT_USER"	,MODEL_FIELD_INIT,{|| RetCodUsr() })			 //Codigo do usuario logado no protheus
oStrGrdMtCn:SetProperty("TFT_HORA"	,MODEL_FIELD_INIT,{|| SubStr(Time(),1,5)	 }) //Hora do apontamento no formato HH:MM


//Cria��o dos Gatilhos
aAux4 := FwStruTrigger("TFT_CODTFH","TFT_PRODUT","At890DcTFT(),At890SlTFH(),At890PrTFT()",.F.,Nil,Nil,Nil) 					//Gatilho do material de consumo, preenche produto, descri��o do produto e saldo
oStrGrdMtCn:AddTrigger(aAux4[1],aAux4[2],aAux4[3],aAux4[4])

aAux4 := FwStruTrigger("TFS_CODTFG","TFS_PRODUT","At890DcTFS(),At890SlTFG(),At890PrTFS()",.F.,Nil,Nil,Nil) 					//Gatilho do material de consumo, preenche produto, descri��o do produto e saldo
oStGrdMtImp:AddTrigger(aAux4[1],aAux4[2],aAux4[3],aAux4[4])

oModel := MPFormModel():New('TECA890',/*bPreValid*/, bPosValid ,bDcommit,/*bCancel*/)
oModel:AddFields('TFLMASTER',/*cOwner*/,oStruTFL,/*bPreValidacao*/,/*bPosValidacao*/,/*bFieldAbp*/,/*bCarga*/,/*bFieldTfl*/)
 
oModel:AddGrid('TFTGRID', 'TFLMASTER',oStrGrdMtCn,{|oMdlG,nLine,cAcao,cCampo| At890PosVal(oMdlG,nLine,cAcao,"TFT_ITAPUR","TFT",cCampo,"TFT_CODKIT")}/*bPreValidacao*/,{|oMdl| At890LinhaOK(oMdl)},/*bPre*/,/*bPost*/,/*bLoad*/)
oModel:SetRelation('TFTGRID', {{'TFT_FILIAL', 'xFilial("TFT")'}, {'TFT_CODTFL', 'TFL_CODIGO'}}, TFT->(IndexKey(1)))

oModel:AddGrid('TFSGRID', 'TFLMASTER',oStGrdMtImp,{|oMdlG,nLine,cAcao,cCampo| At890PosVal(oMdlG,nLine,cAcao,"TFS_ITAPUR","TFS",cCampo,"TFS_CODKIT")}/*bPreValidacao*/,{|oMdl| At890LnOKTFS(oMdl)},/*bPre*/,/*bPost*/,/*bLoad*/)
oModel:SetRelation('TFSGRID', {{'TFS_FILIAL', 'xFilial("TFS")'}, {'TFS_CODTFL', 'TFL_CODIGO'}}, TFS->(IndexKey(1)))

oModel:AddGrid('T4AGRID', 'TFSGRID',oStFuncMat, {|oMdlG,nLine,cAcao,cCampo| At890T4APosVal(oMdlG,nLine,cAcao,cCampo)}/*bPreValidacao*/,,,,)
oModel:SetRelation('T4AGRID', {{'T4A_FILIAL', 'xFilial("T4A")'}, {'T4A_CODTFS', 'TFS_CODIGO'}, {'T4A_TPMAT', 'TFS_TPMAT'} , {'T4A_CODTFL', 'TFL_CODIGO'} , {'T4A_LOCAL', 'TFL_LOCAL'} , {'T4A_CODPAI', 'TFL_CODPAI'},{'T4A_CODKIT', 'TFS_CODKIT'} }, T4A->(IndexKey(4)))

oModel:GetModel('TFLMASTER'):SetDescription('TFL')
oModel:GetModel('TFLMASTER'):SetOnlyView(.T.)

oModel:GetModel('TFSGRID'):SetDescription('TFS')
oModel:GetModel('TFTGRID'):SetDescription('TFT')
oModel:GetModel('TFSGRID'):SetOptional(.T.)
oModel:GetModel('TFTGRID'):SetOptional(.T.)
oModel:GetModel('T4AGRID'):SetOptional(.T.)

oModel:setDescription(STR0001)//"Apontamento de Materiais"

//Se for recorrente s� carrega apontamentos do mes corrente
If Posicione( "TFJ", 1, xFilial("TFJ") + TFL->TFL_CODPAI, "TFJ_CNTREC") == "1"
	oModel:GetModel( 'TFSGRID' ):SetLoadFilter( , "(TFS_DTAPON BETWEEN '" + cDtIni + "' AND '" + cDtFin + "' ) AND TFS_MOV = '1' " )
	oModel:GetModel( 'TFTGRID' ):SetLoadFilter( , "(TFT_DTAPON BETWEEN '" + cDtIni + "' AND '" + cDtFin + "' )" )
Else
	//Filtra o grid de implanta��o pra n�o carregar movimentos de devolu��o
	oModel:GetModel('TFSGRID'):SetLoadFilter({{'TFS_MOV',"'1'",MVC_LOADFILTER_EQUAL}})
Endif

//Valida se o contrato a ser apontado est� vigente
If IsInCallStack("TECA890")
	oModel:SetVldActivate(bVldAct)
EndIf	

oModel:SetActivate( {|oModel| InitDados( oModel ) } )

Return (oModel)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef

Cria��o da View da Tela de Cadastro
@author Servi�os
@since 31/10/13
@version P11 R9
@return ExpO: View criada para o cadastro
/*/
//--------------------------------------------------------------------------------------------------------------------

Static Function ViewDef()
Local oView	
Local oModel		:= FwLoadModel('TECA890')
Local oStruTFL		:= FwFormStruct(2,'TFL', {|cCpo| At890SelFields( 'TFL', Alltrim(cCpo) ) } )
Local oStrGrdMtCn	:= FwFormStruct(2,'TFT')
Local oStrGrdImp	:= FwFormStruct(2,'TFS')
Local nOperation 	:= oModel:GetOperation()

oView := FWFormView():New()
oView:SetModel(oModel)

//Remove o campo da View
oStrGrdImp:RemoveField("TFS_MOV")

//Remove o campo da View
oStrGrdImp:RemoveField("TFS_PEND")
oStrGrdMtCn:RemoveField("TFT_PEND")

//Campo virtual que indicar� se o apontamento do material de consumo foi ou n�o apurado. 
oStrGrdMtCn:AddField( 'TFT_SIT', ; // cIdField
       				'01', ; // cOrdem
                    STR0003, ; // cTitulo
                    STR0003, ; // cDescric
                    {}, ; // aHelp
                   	'BT', ; // cType
                   	'', ; // cPicture
       				Nil, ; // nPictVar
                    Nil, ; // Consulta F3
                    .T., ; // lCanChange
                    '', ; // cFolder
                    Nil, ; // cGroup
                    Nil, ; // aComboValues
                    Nil, ; // nMaxLenCombo
                    Nil, ; // cIniBrow
                    .T., ; // lVirtual
                    Nil ) // cPictVar
//Campo virtual para visualiza��o do saldo do material de consumo.    
oStrGrdMtCn:AddField( 'TFT_SLDTTL', ; // cIdField
       				'06', ; // cOrdem
                    	STR0004, ; // cTitulo
                     STR0004, ; // cDescric
                     {}, ; // aHelp
                   	'N', ; // cType
                   	'@E 99,999,999.99', ; // cPicture
       				Nil, ; // nPictVar
                     Nil, ; // Consulta F3
                     .F., ; // lCanChange
                    	'', ; // cFolder
                     Nil, ; // cGroup
                     Nil, ; // aComboValues
                     Nil, ; // nMaxLenCombo
                     Nil, ; // cIniBrow
                     .T., ; // lVirtual
                     Nil ) // cPictVar
//Campo virtual que indicar� se o apontamento do material operacional foi ou n�o apurado.                    
oStrGrdImp:AddField( 'TFS_SIT', ; // cIdField
       				'01', ; // cOrdem
                    	STR0003, ; // cTitulo
                     STR0003, ; // cDescric
                     {}, ; // aHelp
                   	'BT', ; // cType
                   	'', ; // cPicture
       				Nil, ; // nPictVar
                     Nil, ; // Consulta F3
                     .T., ; // lCanChange
                    	'', ; // cFolder
                     Nil, ; // cGroup
                     Nil, ; // aComboValues
                     Nil, ; // nMaxLenCombo
                     Nil, ; // cIniBrow
                     .T., ; // lVirtual
                     Nil ) // cPictVar 
//Campo virtual para visualiza��o do saldo do material operacional.                      
oStrGrdImp:AddField( 'TFS_SLDTTL', ; // cIdField
       				'06', ; // cOrdem
                     STR0004, ; // cTitulo
                     STR0004, ; // cDescric
                     {}, ; // aHelp
                   	'N', ; // cType
                   	'@E 99,999,999.99', ; // cPicture
       				Nil, ; // nPictVar
                     Nil, ; // Consulta F3
                     .F., ; // lCanChange
                    	'', ; // cFolder
                     Nil, ; // cGroup
                     Nil, ; // aComboValues
                     Nil, ; // nMaxLenCombo
                     Nil, ; // cIniBrow
                     .T., ; // lVirtual
                     Nil ) // cPictVar

oView:AddField('VIEW_GERAL', oStruTFL, 'TFLMASTER') 	//View geral onde ser� o cabe�alho, tabela TFL

oView:AddGrid('VIEW_MAIMP', oStrGrdImp, 'TFSGRID')
oView:AddGrid('VIEW_MACONS', oStrGrdMtCn, 'TFTGRID')

oView:CreateHorizontalBox('TELAGERAL',30)
oView:CreateHorizontalBox('METADE',70)

oView:CreateFolder('PASTA','METADE')
oView:AddSheet('PASTA','ABA01',STR0028)//"Material de Implanta��o"
oView:AddSheet('PASTA','ABA02',STR0029)//"Material de Consumo"

oView:CreateHorizontalBox('INFERIOR', 100,,,'PASTA','ABA01')
oView:CreateHorizontalBox('MAXINFERIOR', 100,,,'PASTA','ABA02')

oView:SetOwnerView( 'VIEW_GERAL','TELAGERAL' )
oView:SetOwnerView( 'VIEW_MAIMP', 'INFERIOR' )
oView:SetOwnerView( 'VIEW_MACONS', 'MAXINFERIOR' )

oView:SetFieldAction("TFS_CODTFG",{|oView,cIDView,cField| At890KitMat( cField )})
oView:SetFieldAction("TFT_CODTFH",{|oView,cIDView,cField| At890KitMat( cField )})
oView:SetCloseOnOk({|| .T.} )

oView:AddUserButton( STR0054, 'CLIPS', {|oView| AT890F4()} ) // 'Consulta Saldo do Produto'
oView:AddUserButton(STR0093,"CLIPS",{|oView| At890VnFunc(oModel)})	//"Vinculo com Funcion�rio"

SetKey( VK_F4, { || AT890F4() })

Return (oView)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890ConsMC

Realiza a Consulta especifica para os Materiais de Consumo do local de atendimento
@sample  At890ConsMC() 
@author  Servi�os
@since 	  31/10/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na opera��o
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At890ConsMC()
Local lRet              := .F.
Local aCmpBco           := {}
Local cQuery            := ""
Local cDscCmp           := ""
Local cConteudo   	   := ""
Local cCodigo           := ""
Local cEntida           := ""
Local cLocal            := ""
Local lOk               := .F.
Local cProdut 			:= ""
Local cPesq				:= Space(TamSX3("TFT_CODTFH")[1])
Local oPesqui			:= Nil //Objeto Pesquisa
Local oModel            := Nil //Modelo atual
Local oDlgCmp           := Nil //Dialog
Local oPanel            := Nil //Objeto Panel
Local oFooter           := Nil //Rodap�
Local oListBox          := Nil //Grid campos
Local oOk               := Nil //Objeto Confirma 
Local oCancel           := Nil //Objeto Cancel
Local lOrcPrc 			:= SuperGetMv("MV_ORCPRC",,.F.)
Local aTitColun			:= {}		
Local cCntRec			:= Posicione( "TFJ", 1, xFilial("TFJ") + TFL->TFL_CODPAI, "TFJ_CNTREC")
	
aCmpBco := At890QryMC()

If !Empty(aCmpBco)

	  If lOrcPrc
		  aTitColun := {STR0005,STR0006,STR0007}
	  Else
		  aTitColun := {STR0005,STR0006,STR0007,"Desc. RH"}
	  Endif

      //    Cria a tela para a pesquisa dos campos e define a area a ser utilizada na tela 
      Define MsDialog oDlgCmp FROM 000, 000 To 350, 550 Pixel
                  
      //Cria o Panel de pesquisa
      @ 000, 000 MsPanel oPesqui Of oDlgCmp Size 000, 012 // Coordenada para o panel
      oPesqui:Align   := CONTROL_ALIGN_TOP //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
       
      @ 02,147 SAY STR0063 SIZE 70,30 PIXEL OF oPesqui//"Cod. Mat. Cons: " 
      
      @ 001,190 GET oPesqui VAR cPesq SIZE 25,03 OF oDlgCmp PIXEL
            
      @ 001,227 BUTTON STR0055 SIZE 50,10 ACTION {|| At890Find(cPesq, oListBox, 1) } OF oDlgCmp PIXEL //"Pesquisar"
                  
      // Cria o panel principal
      @ 000, 000 MsPanel oPanel Of oDlgCmp Size 250, 340 // Coordenada para o panel
      oPanel:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
            
      // Cria��o do grid para o panel    
      oListBox := TWBrowse():New( 40,05,204,100,,aTitColun,,oPanel,,,,,,,,,,,,.F.,,.T.,,.F.,,,) //"C�digo"###"Produto"###"Desc Produto"
      oListBox:SetArray(aCmpBco) // Atrela os dados do grid com a matriz

      oListBox:bLine := { || Iif( lOrcPrc , {aCmpBco[oListBox:nAT][1], aCmpBco[oListBox:nAT][2], aCmpBco[oListBox:nAT][3]} , {aCmpBco[oListBox:nAT][1], aCmpBco[oListBox:nAT][2], aCmpBco[oListBox:nAT][3], aCmpBco[oListBox:nAT][4]} ) } // Indica as linhas do grid

      oListBox:bLDblClick := { ||Eval(oOk:bAction), oDlgCmp:End()} // Duplo clique executa a a��o do objeto indicado
      oListBox:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do browse
            
      // Cria o panel para os botoes     
      @ 000, 000 MsPanel oFooter Of oDlgCmp Size 000, 010 // Corrdenada para o panel dos botoes (size)
      oFooter:Align   := CONTROL_ALIGN_BOTTOM //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
                  
      // Botoes para o grid auxiliar     
      @ 000, 000 Button oCancel Prompt STR0008  Of oFooter Size 030, 000 Pixel //"Cancelar"
      oCancel:bAction := { || lOk := .F., oDlgCmp:End() }
      oCancel:Align   := CONTROL_ALIGN_RIGHT
            
      @ 000, 000 Button oOk     Prompt STR0009 Of oFooter Size 030, 000 Pixel //"Confirmar"
      oOk:bAction     := { || lOk := .T.,cCodigo:=aCmpBco[oListBox:nAT][1],oDlgCmp:End() } // Acao ao clicar no botao
      oOk:Align       := CONTROL_ALIGN_RIGHT // Alinhamento do botao referente ao panel
     	cProdut:= aCmpBco[oListBox:nAT][2]
            // Ativa a tela exibindo conforme a coordenada
      Activate MsDialog oDlgCmp Centered
                  
      //Utilizar o modelo ativo para substituir os valores das variaves de memoria      
      oModel      := FWModelActive()
            
	If lOk
		lRet := .T. 
    	oModel:SetValue("TFTGRID","TFT_CODTFH", cCodigo)
    	oModel:SetValue("TFTGRID","TFT_PRODUT", "")
    	oModel:SetValue("TFTGRID","TFT_DPROD", "")
		If cCntRec == "1"
	    	oModel:SetValue("TFTGRID","TFT_SLDTTL", At890SldRec("TFT",cCodigo))
		Else
	    	oModel:SetValue("TFTGRID","TFT_SLDTTL", Posicione('TFH',1,xFilial('TFH') + cCodigo , 'TFH_SLD'))
   		Endif
	EndIf
Else
      Help( ,, 'Help',, STR0010, 1, 0 )//"N�o h� Materiais de Consumo para este Local de Atendimento"
EndIf

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT890RetMC

Retorna a variavel da memoria do model, para a consulta especifica
@sample     At890RetMC() 
@since      31/10/2013
@version 	 P11 R9
     
@return     cCodigo, CHARACTER, conteudo da variavel de memoria.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At890RetMC()
Return (FwFldGet("TFT_CODTFH"))

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890QryMC

Realiza a Query para a consulta especifica para trazer somentete materiais de consumo que o local de atendimento possua.
@sample     At890QryMC() 
@since      31/10/2013 
@version 	 P11 R9
     
@return     aRet, Array com os Responsaveis
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At890QryMC()


	Local aArea		:= GetArea()
	Local aAreaSB1	:= SB1->(GetArea())
	Local aRet      := {}
	
	Local oModel    := FwModelActive()
	Local oMdlTFL	:= nil
	
	Local cAlias := GetNextAlias()
	Local cCond 	:= ''
	
	Local lOrcPrc := SuperGetMv("MV_ORCPRC",,.F.) 

	If ValType(oModel) == 'O' .and. oModel:GetId() == 'TECA890'
		
		oMdlTFL := oModel:GetModel('TFLMASTER')
		cCond	:= oMdlTFL:GetValue('TFL_CODIGO')
		
		If lOrcPrc //Or�amento com tabela de Precifica��o
			
			BeginSql Alias cAlias

				SELECT
					TFH_COD, 
					TFH_PRODUT
				
				FROM %table:TFL% TFL
				
				INNER JOIN %table:TFH% TFH
					 ON TFH.TFH_FILIAL = %xFilial:TFH%   
					AND TFH.TFH_CODPAI = TFL.TFL_CODIGO
				
				WHERE
					TFL.TFL_FILIAL = %xFilial:TFL% AND
					TFL.TFL_CODIGO = %Exp:cCond% AND  	
					TFL.%NotDel% AND
					TFH.%NotDel% 
			
			EndSql
			
		Else //or�amento Sem tabela de Precifica��o

			BeginSql Alias cAlias
				
				SELECT
					TFH_COD, 
					TFH_PRODUT,
					TFF_PRODUT
				FROM %table:TFL% TFL
				
				INNER JOIN %table:TFF% TFF
					 ON TFF.TFF_FILIAL = %xFilial:TFF%  
					AND TFF.TFF_CODPAI = TFL.TFL_CODIGO
				
				INNER JOIN %table:TFH% TFH
					 ON TFH.TFH_FILIAL = %xFilial:TFH%   
					AND TFH.TFH_CODPAI = TFF.TFF_COD
				
				WHERE
					TFL.TFL_FILIAL = %xFilial:TFL% AND
					TFL.TFL_CODIGO = %Exp:cCond% AND  	
					TFF.TFF_ENCE <> '1' AND
					TFL.%NotDel% AND
					TFF.%NotDel% AND
					TFH.%NotDel%  
					
			EndSql
		
		EndIf
			
	EndIf
	
	While !(cAlias)->(Eof())					 
	
		//faz dbseek na SB1 e ve se o produto existe l� para que seja aceito.
		DbSelectArea("SB1")
		SB1->(DbSetOrder(1))
		
		If SB1->(DbSeek(xFilial("SB1") + (cAlias)->TFH_PRODUT))
			If lOrcPrc
				aAdd(aRet,{(cAlias)->TFH_COD 	,;
					 (cAlias)->TFH_PRODUT 		,;
					 Posicione("SB1", 1, xFilial("SB1") + (cAlias)->TFH_PRODUT, "B1_DESC")})	
			Else
				aAdd(aRet,{(cAlias)->TFH_COD 	,;
					 (cAlias)->TFH_PRODUT 		,;
					 Posicione("SB1", 1, xFilial("SB1") + (cAlias)->TFH_PRODUT, "B1_DESC"),;
					 Posicione("SB1", 1, xFilial("SB1") + (cAlias)->TFF_PRODUT, "B1_DESC")})	
			Endif
		EndIf				
		
		(cAlias)->(DbSkip())	

	EndDo
	
	(cAlias)->(DbCloseArea())
	
	RestArea(aAreaSB1)
	RestArea(aArea)

Return(aRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890ConsMI

Realiza a Consulta especifica para os Materiais operacionais do local de atendimento

@sample  At890ConsMI() 
@author  Servi�os
@since 	  31/10/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na opera��o
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At890ConMI()
Local lRet              := .F.
Local aCmpBco           := {}
Local cQuery            := ""
Local cDscCmp           := ""
Local cConteudo   		:= ""
Local cCodigo           := ""
Local cEntida           := ""
Local cLocal            := ""
Local lOk               := .F.
Local cPesq				:= Space(TamSX3("TFS_CODTFG")[1])
Local oModel			:= Nil //Modelo atual
Local oDlgCmp			:= Nil //Dialog
Local oPanel			:= Nil //Objeto Panel
Local oFooter			:= Nil //Rodap�
Local oListBox			:= Nil //Grid campos
Local oOk				:= Nil //Objeto Confirma 
Local oCancel			:= Nil //Objeto Cancel
Local oPesqui			:= Nil //Objeto Pesquisa
Local lOrcPrc 			:= SuperGetMv("MV_ORCPRC",,.F.) 
Local aTitColun			:= {}
Local cCntRec			:= Posicione( "TFJ", 1, xFilial("TFJ") + TFL->TFL_CODPAI, "TFJ_CNTREC")

aCmpBco := At890QryMI()

If !Empty(aCmpBco)
	  If lOrcPrc
		  aTitColun := {STR0005,STR0006,STR0007}
	  Else
		  aTitColun := {STR0005,STR0006,STR0007,"Desc. RH"}
	  Endif

      //    Cria a tela para a pesquisa dos campos e define a area a ser utilizada na tela 
      Define MsDialog oDlgCmp FROM 000, 000 To 350, 550 Pixel
                  
      //Cria o Panel de pesquisa
      @ 000, 000 MsPanel oPesqui Of oDlgCmp Size 000, 012 // Coordenada para o panel
      oPesqui:Align   := CONTROL_ALIGN_TOP //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
      
      @ 02,150 SAY STR0064 SIZE 70,030 PIXEL OF oPesqui  //"Cod. Mat. Imp: " 
      
      @ 001,190 GET oPesqui VAR cPesq SIZE 25,03 OF oDlgCmp PIXEL
            
      @ 001,227 BUTTON STR0055 SIZE 50,10 ACTION {|| At890Find(cPesq, oListBox, 1) } OF oDlgCmp PIXEL //"Pesquisar"
                  
      // Cria o panel principal
      @ 000, 000 MsPanel oPanel Of oDlgCmp Size 250, 340 // Coordenada para o panel
      oPanel:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
            
      // Cria��o do grid para o panel    

      oListBox := TWBrowse():New( 40,05,204,100,,aTitColun,,oPanel,,,,,,,,,,,,.F.,,.T.,,.F.,,,) //"C�digo"###"Produto"###"Desc Produto"

      oListBox:SetArray(aCmpBco) // Atrela os dados do grid com a matriz


      oListBox:bLine := { || Iif( lOrcPrc , {aCmpBco[oListBox:nAT][1], aCmpBco[oListBox:nAT][2], aCmpBco[oListBox:nAT][3]} , {aCmpBco[oListBox:nAT][1], aCmpBco[oListBox:nAT][2], aCmpBco[oListBox:nAT][3], aCmpBco[oListBox:nAT][4]} ) } // Indica as linhas do grid

      oListBox:bLDblClick := { ||Eval(oOk:bAction), oDlgCmp:End()} // Duplo clique executa a a��o do objeto indicado
      oListBox:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do browse
            
      // Cria o panel para os botoes     
      @ 000, 000 MsPanel oFooter Of oDlgCmp Size 000, 010 // Corrdenada para o panel dos botoes (size)
      oFooter:Align   := CONTROL_ALIGN_BOTTOM //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
                  
      // Botoes para o grid auxiliar     
      @ 000, 000 Button oCancel Prompt STR0008  Of oFooter Size 030, 000 Pixel //"Cancelar"
      oCancel:bAction := { || lOk := .F., oDlgCmp:End() }
      oCancel:Align   := CONTROL_ALIGN_RIGHT
            
      @ 000, 000 Button oOk     Prompt STR0009 Of oFooter Size 030, 000 Pixel //"Confirmar"
      oOk:bAction     := { || lOk := .T.,cCodigo:=aCmpBco[oListBox:nAT][1],oDlgCmp:End() } // Acao ao clicar no botao
      oOk:Align       := CONTROL_ALIGN_RIGHT // Alinhamento do botao referente ao panel
     	cProdut:= aCmpBco[oListBox:nAT][2]
            // Ativa a tela exibindo conforme a coordenada
      Activate MsDialog oDlgCmp Centered
                  
      //Utilizar o modelo ativo para substituir os valores das variaves de memoria      
      oModel      := FWModelActive()
            
	If lOk
		lRet := .T.	 
    	oModel:SetValue("TFSGRID","TFS_CODTFG", cCodigo)
    	oModel:SetValue("TFSGRID","TFS_PRODUT", "")
    	oModel:SetValue("TFSGRID","TFS_DPROD", "")
		If cCntRec == "1"
	    	oModel:SetValue("TFSGRID","TFS_SLDTTL", At890SldRec("TFS",cCodigo) )		
		Else
	    	oModel:SetValue("TFSGRID","TFS_SLDTTL", Posicione('TFG',1,xFilial('TFG') + cCodigo , 'TFG_SLD'))		
		Endif
	EndIf
Else
      Help( ,, 'Help',, STR0011, 1, 0 )//"N�o h� Materiais operacionais para este Local de Atendimento"
EndIf

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT890RetMI

Retorna a variavel da memoria do model, para a consulta especifica

@sample  AT890RetMI() 
@author  Servi�os
@since 	  31/10/13
@version P11 R9
     
@return     cCodigo, CHARACTER, conteudo da variavel de memoria.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At890RetMI()
Return (FwFldGet("TFS_CODTFG"))

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890QryMI

Realiza a Query para a consulta especifica do Material Operacional especifico do local de atendimento.

@sample  At890QryMI() 
@author  Servi�os
@since 	  31/10/13
@version P11 R9
    
@return     aRet, Array com os Responsaveis
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At890QryMI()

	Local aArea		:= GetArea()
	Local aAreaSB1	:= SB1->(GetArea())
	Local aRet      := {}
	
	Local oModel    := FwModelActive()
	Local oMdlTFL	:= nil
	
	Local cAlias := GetNextAlias()
	Local cCond 	:= ''
	
	Local lOrcPrc := SuperGetMv("MV_ORCPRC",,.F.) 
	
	If ValType(oModel) == 'O' .and. oModel:GetId() == 'TECA890'
		
		oMdlTFL := oModel:GetModel('TFLMASTER')
		cCond	:= oMdlTFL:GetValue('TFL_CODIGO')
		
		If lOrcPrc //Or�amento com tabela de Precifica��o
			
			BeginSql Alias cAlias

				SELECT
					TFG_COD, 
					TFG_PRODUT
				
				FROM %table:TFL% TFL
				
				INNER JOIN %table:TFG% TFG
					 ON TFG.TFG_FILIAL = %xFilial:TFG%   
					AND TFG.TFG_CODPAI = TFL.TFL_CODIGO
				
				WHERE
					TFL.TFL_FILIAL = %xFilial:TFL% AND
					TFL.TFL_CODIGO = %Exp:cCond% AND  	
					TFL.%NotDel% AND
					TFG.%NotDel% 
			
			EndSql
			
		Else //or�amento Sem tabela de Precifica��o

			BeginSql Alias cAlias
				
				SELECT
					TFG_COD, 
					TFG_PRODUT,
					TFF_PRODUT
				FROM %table:TFL% TFL
				
				INNER JOIN %table:TFF% TFF
					 ON TFF.TFF_FILIAL = %xFilial:TFF%  
					AND TFF.TFF_CODPAI = TFL.TFL_CODIGO
				
				INNER JOIN %table:TFG% TFG
					 ON TFG.TFG_FILIAL = %xFilial:TFG%   
					AND TFG.TFG_CODPAI = TFF.TFF_COD
				
				INNER JOIN %table:SB1% SB1 
					ON SB1.B1_FILIAL = %xFilial:SB1% 
					AND SB1.B1_COD = TFG.TFG_PRODUT 
					AND SB1.%NotDel%
				
				INNER JOIN %table:SB5% SB5 
					ON SB5.B5_FILIAL = %xFilial:SB5% 
					AND SB5.B5_COD = SB1.B1_COD
					AND SB5.B5_TPISERV = '5'
					AND SB5.%NotDel%
					
				WHERE
					TFL.TFL_FILIAL = %xFilial:TFL% AND
					TFL.TFL_CODIGO = %Exp:cCond% AND  	
					TFL.%NotDel% AND
					TFF.%NotDel% AND
					TFG.%NotDel%  
					
			EndSql
		
		EndIf
			
	EndIf
	
	While !(cAlias)->(Eof())					 
	
		//faz dbseek na SB1 e ve se o produto existe l� para que seja aceito.
		DbSelectArea("SB1")
		SB1->(DbSetOrder(1))
		
		If SB1->(DbSeek(xFilial("SB1") + (cAlias)->TFG_PRODUT))
			If lOrcPrc
				aAdd(aRet,{(cAlias)->TFG_COD 	,;
					 (cAlias)->TFG_PRODUT 		,;
					 Posicione("SB1", 1, xFilial("SB1") + (cAlias)->TFG_PRODUT, "B1_DESC")})	
			Else
				aAdd(aRet,{(cAlias)->TFG_COD 	,;
					 (cAlias)->TFG_PRODUT 		,;
					 Posicione("SB1", 1, xFilial("SB1") + (cAlias)->TFG_PRODUT, "B1_DESC"),;
					 Posicione("SB1", 1, xFilial("SB1") + (cAlias)->TFF_PRODUT, "B1_DESC")})	
			Endif
		EndIf				
		
		(cAlias)->(DbSkip())	

	EndDo
	
	(cAlias)->(DbCloseArea())
	
	RestArea(aAreaSB1)
	RestArea(aArea)

Return(aRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890PrTFS

Realiza busca do produto para preenchimento no gatilho

@sample  At890PrTFS() 
@author  Servi�os
@since 	  31/10/13
@version P11 R9
    
@return     cFinal, Valor do Produto
/*/
//--------------------------------------------------------------------------------------------------------------------

Function At890PrTFS()
Local cFinal	:= ""
Local aArea	:=	GetArea()
Local lKit   := !Empty(FwFldGet("TFS_CODKIT"))

DbSelectArea("TFG")
DbSetOrder(1)
If lKit
	cFinal := FwFldGet("TFS_PRODUT")
Else
	If TFG->(DbSeek(xFilial("TFG")+(FwFldGet("TFS_CODTFG"))))
		cFinal:=TFG->TFG_PRODUT
	EndIf
EndIf
RestArea(aArea)
Return cFinal

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890DcTFS

Realiza busca do produto para preenchimento no gatilho

@sample  At890PrTFS() 
@author  Servi�os
@since 	  31/10/13
@version P11 R9
    
@return     cDesc, Descri��o do Produto
/*/
//--------------------------------------------------------------------------------------------------------------------

Function At890DcTFS()

	Local aArea		:= GetArea()
	Local aAreaTFG	:= TFG->(GetArea())
	Local aAreaSB1	:= SB1->(GetArea()) 
	Local aSaveLines	:= FWSaveRows()
	
	Local cFinal	:= ""
	Local cDesc		:= ""
	
	Local oModel	:= FwModelActive() 
	Local oMdlTFS	:= Nil

	If ValType(oModel)=='O' .and. oModel:GetId()=='TECA890'
		
		cFinal := At890PrTFS()
		
		cDesc := Posicione("SB1",1,xFilial("SB1") + cFinal,"B1_DESC") 
		At890Set(oModel:GetModel("TFSGRID"), "TFS_DPROD", cDesc )  
		
	EndIf

	FWRestRows(aSaveLines)
	RestArea(aAreaSB1)
	RestArea(aAreaTFG)
	RestArea(aArea)

Return cDesc 

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890SlTFG

Busca saldo atual, quando ouver o disparo do gatilho do campo quantidade.

@sample  At890SlTFG() 
@author  Servi�os
@since 	  31/10/13
@version P11 R9
@return nSld: Retorna saldo atual do material Operacional posicionado
/*/
//--------------------------------------------------------------------------------------------------------------------

Function At890SlTFG()

Local aArea		:= GetArea()
Local aAreaTFG 	:= TFG->(GetArea())
Local aSaveLines:= FWSaveRows()
	
Local oModel	:= FwModelActive()
Local oModelTFS	:= Nil//oModel:GetModel("TFTGRID")
Local cProdut	:= ""
Local cCodTFG	:= ""
Local nSld		:= 0
Local nX		:= 0
Local nLAt		:= 0 
Local lSeExist:=.F.
Local cCntRec	:= Posicione( "TFJ", 1, xFilial("TFJ") + TFL->TFL_CODPAI, "TFJ_CNTREC")
Local nSaldoDel	:= 0
	
If ValType(oModel)=='O' .and. oModel:GetId()== 'TECA890'	
		
	oModelTFS := oModel:GetModel("TFSGRID") 
	
	cCodTFG := oModelTFS:GetValue("TFS_CODTFG")
	
	nLAt := oModelTFS:GetLine() //Captura Linha Atual
	
	//Caso j� Exista o Produto na Grid Ele Pega o Ultimo Valor do (Saldo - Saldo)
	For nX := 1 To oModelTFS:Length() 
		oModelTFS:GoLine(nX)
		
		If  !oModelTFS:IsDeleted() .and.;
			oModelTFS:GetValue("TFS_CODTFG") = cCodTFG .and.;
			oModelTFS:GetValue("TFS_SLDTTL") > 0 .And. !lSeExist
			
			If Empty(oModelTFS:GetValue("TFS_CODKIT")) 
				nSld := oModelTFS:GetValue("TFS_SLDTTL")
				lSeExist := .T.
			EndIf
		Else
			If oModelTFS:IsDeleted() .and. Empty(oModelTFS:GetValue("TFS_CODKIT"))
				nSaldoDel += oModelTFS:GetValue("TFS_QUANT")
			EndIf	
		EndIf
	Next nX
	
	If !lSeExist
		DbSelectArea("TFG")
		TFG->(DbSetOrder(1))//TFH_FILIAL + TFH_COD		
		If TFG->(DbSeek(xFilial("TFG") + cCodTFG))
			If cCntRec == "1"
				nSld := At890SldRec("TFS",cCodTFG,lStKit)	
				nSld := nSld + nSaldoDel		
			Else	
				nSld := TFG->TFG_SLD
			Endif
		EndIf	
	EndIf
	
	oModelTFS:GoLine(nLAt)//Retorna para linha Atual
	oModel:SetValue("TFSGRID","TFS_SLDTTL", nSld)

EndIf

FWRestRows(aSaveLines)	
RestArea(aAreaTFG)
RestArea(aArea)

Return nSld

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890PrTFT

Busca produto, quando ouver o disparo do gatilho do campo material.
@sample  At890PrTFT() 
@author  Servi�os
@since 	  31/10/13
@version P11 R9
@return cFinal: Retorna produto relacionado ao material do local de atendimento.
/*/
//--------------------------------------------------------------------------------------------------------------------

Function At890PrTFT()
Local cFinal	:= ""
Local aArea	 := GetArea()
Local lKit   := !Empty(FwFldGet("TFT_CODKIT"))

DbSelectArea("TFH")
DbSetOrder(1)

If lKit
	cFinal := FwFldGet("TFT_PRODUT")
Else
	If TFH->(DbSeek(xFilial("TFH")+(FwFldGet("TFT_CODTFH"))))
		cFinal:=TFH->TFH_PRODUT
	EndIf
EndIf
RestArea(aArea)
Return cFinal

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890DcTFT

Busca produto, quando ouver o disparo do gatilho do campo material.

@sample  At890DcTFT() 
@author  Servi�os
@since 	  31/10/13
@version P11 R9
@return cFinal: Retorna a descri��o do produto relacionado ao material do local de atendimento.
/*/
//--------------------------------------------------------------------------------------------------------------------

Function At890DcTFT()

	Local aArea		:= GetArea()
	Local aAreaTFH	:= TFH->(GetArea())
	Local aAreaSB1	:= SB1->(GetArea()) 
	Local aSaveLines	:= FWSaveRows()
	
	Local cFinal	:= ""
	Local cDesc		:= ""
	
	Local oModel	:= FwModelActive() 
	Local oMdlTFT	:= Nil
	
	If ValType(oModel)=='O' .and. oModel:GetId()=='TECA890'
		cFinal := At890PrTFT()
		cDesc := Posicione("SB1",1,xFilial("SB1") + cFinal,"B1_DESC") 
		At890Set(oModel:GetModel("TFTGRID"), "TFT_DPROD", cDesc )	
	EndIf
	
	FWRestRows(aSaveLines)
	RestArea(aAreaSB1)
	RestArea(aAreaTFH)
	RestArea(aArea) 

Return cDesc
///

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890SlTFH

Busca saldo atual, quando ouver o disparo do gatilho do campo quantidade.
@sample  At890DcTFT() 
@author  Servi�os
@since 	  31/10/13
@version P11 R9
@return nSld: Retorna saldo atual do material de consumo posicionado
/*/
//--------------------------------------------------------------------------------------------------------------------

Function At890SlTFH()

Local aArea		:= GetArea()
Local aAreaTFH 	:= TFH->(GetArea())
Local aSaveLines	:= FWSaveRows()

Local oModel		:= FwModelActive()
Local oModelTFT	:= Nil
Local cProdut		:= ""
Local cCodTFH		:= ""
Local nSld			:= 0
Local nX			:= 0
Local nLAt			:= 0 
Local lSeExist 	:= .F.
Local cCntRec		:= Posicione( "TFJ", 1, xFilial("TFJ") + TFL->TFL_CODPAI, "TFJ_CNTREC")
	
If ValType(oModel)=='O' .and. oModel:GetId()== 'TECA890'	
	
	oModelTFT := oModel:GetModel("TFTGRID") 
	
	cCodTFH := oModelTFT:GetValue("TFT_CODTFH")//FWFLDGET("TFT_CODTFH")
	
	nLAt := oModelTFT:GetLine() //Captura Linha Atual
	
	//Caso j� Exista o Produto na Grid Ele Pega o Ultimo Valor do (Saldo - Saldo)
	For nX := 1 To oModelTFT:Length() 
		oModelTFT:GoLine(nX)
		
		If  !oModelTFT:IsDeleted() .and.;
			oModelTFT:GetValue("TFT_CODTFH") = cCodTFH .and.;
			oModelTFT:GetValue("TFT_SLDTTL") > 0 .And. !lSeExist
			
			If Empty(oModelTFT:GetValue("TFT_CODKIT"))
				nSld := oModelTFT:GetValue("TFT_SLDTTL")
				lSeExist := .T.
			EndIf
		EndIf
	Next nX
	
	If !lSeExist
		DbSelectArea("TFH")
		TFH->(DbSetOrder(1))//TFH_FILIAL + TFH_COD
		If TFH->(DbSeek(xFilial("TFH") + cCodTFH))
			If cCntRec == "1"
				nSld := At890SldRec("TFT",cCodTFH)
			Else
				nSld := TFH->TFH_SLD
			Endif
		EndIf	
	EndIf
	
	oModelTFT:GoLine(nLAt)//Retorna para linha Atual	
	oModel:SetValue("TFTGRID","TFT_SLDTTL", nSld)

EndIf

FWRestRows(aSaveLines)	
RestArea(aAreaTFH)
RestArea(aArea)

Return nSld

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890Commit

Realiza a Grava��o dos Dados utilizando o Model
@sample  At890DcTFT() 
@author  Servi�os
@since 	  31/10/13
@version P11 R9
@param ExpO:Modelo de Dados da Tela de Locais de Atendimento

@return ExpL: Retorna .T. quando houve sucesso na Grava��o
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At890Commit(oModel)

Local lRetorno 	:= .T.
Local lConfirm 
Local nOperation	:= oModel:GetOperation()
Local oModelTFS   	:= oModel:GetModel('TFSGRID')
Local oModelT4A   	:= oModel:GetModel('T4AGRID')

//A opera��o no momento s� permite altera��o e n�o entrar� no caso de exclus�o.
If nOperation == 5					// Quando a opera��o for de exclus�o, questionar� se realmente deseja excluir a exce��o por cliente junto as exce��es por periodo que est�o relacionadas.
	If !IsBlind()
		lConfirm:= MsgYesNo(STR0012) //"Deseja realmente desfazer o apontamento?"
	Else
		lConfirm	:= .T.
	EndIf
		
	If lConfirm == .T.
		Begin Transaction
	
		If !(lRetorno := At890ExcAt(oModel))
			DisarmTransacation()
		Else
			FWFormCommit(oModel)
		EndIf
	
		End Transaction
	EndIf
Else								//Sen�o for exclus�o, n�o haver� questionamento.
	Begin Transaction
	
		If !(lRetorno := At890ExcAt(oModel))
			DisarmTransacation()
		Else
			lLegend	:= .F.
			FWFormCommit(oModel)			
		EndIf
	
		If	lSigaMdtGS		

			//-->Realiza inclus�o de EPI x Funcionario (MSEXECAUTO da rotina MDTA695)
			MsgRun(STR0092,STR0025,{|| AT890MDTA695(oModel) } )	//"EPI x Funcionario (EPIs Entregues por Funcionario)"###"Aguarde"
			
			//-->Chama rotina de impress�o de modelos
			If	!oModelTFS:IsDeleted().AND. oModelT4A:Length() > 0 
				AT990IntWord(oModel,.F.)
			Endif 				
			
		Endif 			
	End Transaction
	
EndIf

Return( lRetorno )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890ExcAt

Realiza a Grava��o dos dados utilizando a ExecAuto MATA240 para inclus�o e extorno de apontamentos.
no Modulo Estoque
@sample  At890ExcAt() 
@author  Servi�os
@since 	  31/10/13
@version P11 R9
@param ExpO:Modelo de Dados da Tela de Locais de Atendimento

@return ExpL: Retorna .T. quando houve sucesso na ExecAuto
/*/
//--------------------------------------------------------------------------------------------------------------------

Function At890ExcAt(oModel)
Local aLinha		:= {}				//array que ser� passado com os valores no execauto para preencher a tabela PS2
Local aLinha2		:= {}
Local lRetorno	:= .T.				//validador de retorno, caso ocorra algum erro, ele retorna false, evitando que seja adicionado dados na tabela ABV
Local lAlter		:= .T.				// Ser� quem definir� se houve ou n�o altera��o em alguma linha do grid
Local nCntFor		:= 0
Local aKitsApont    := {}           // Guarda os kits j� apontados
Local nPosKit       := 0
Local aArea		:= GetArea()		//Pega posi��o GetArea()
Local aSaveLines	:= FWSaveRows()
Local aDados		:= {}
Local oModelTFS	:= oModel:GetModel("TFSGRID")
Local oModelTFT	:= oModel:GetModel("TFTGRID")
Local oMdlTFL 	:= oModel:GetModel('TFLMASTER')
Local cCodTWZ	:= ""
Local cCodKit       := ""
Local nQtdKit       := 0
Local cCntRec		:= Posicione( "TFJ", 1, xFilial("TFJ") + oMdlTFL:GetValue("TFL_CODPAI"), "TFJ_CNTREC")

Private lMsHelpAuto 	:= .T. 			// Controle interno do ExecAuto
Private lMsErroAuto 	:= .F. 			// Informa a ocorr�ncia de erros no ExecAuto
Private lAutoErrNoFile 	:= .F.
Private INCLUI 			:= .T. 			// Variavel necess�ria para o ExecAuto identificar que se trata de uma inclus�o
Private ALTERA 			:= .F. 			// Variavel necess�ria para o ExecAuto identificar que se trata de uma altera��o
PRIVATE VISUA			:= .T.

For nCntFor := 1 To oModelTFS:Length()											//Percorrer� todo grid do material Operacional
	aLinha2:={}
	aLinha:={}
	oModelTFS:GoLine(nCntFor)				
	aSaveLines	:= FWSaveRows()
	aDados	:= aClone(oModelTFS:GetOldData())
	If Empty(oModelTFS:GetValue("TFS_ITAPUR"))											// Verifica se o apontamento ainda n�o foi apurado
		If (!oModelTFS:IsDeleted() .AND. !Empty(oModelTFS:GetValue("TFS_CODTFG")))		//	Verifica se � uma linha deletada e se tem c�digo de apontamento
			aadd(aLinha,{"D3_FILIAL"    ,xFilial("SD3")			,NIL})		//	aLinha array que ser� enviado pelo execauto MATA240
			aadd(aLinha,{"D3_TM"     	,oModelTFS:GetValue("TFS_TM")/*aDados[2][nCntFor][13]*/	,NIL})
			aadd(aLinha,{"D3_COD"     	,oModelTFS:GetValue("TFS_PRODUT")/*aDados[2][nCntFor][4]*/ 	,NIL})
			aadd(aLinha,{"D3_QUANT"     ,oModelTFS:GetValue("TFS_QUANT")/*aDados[2][nCntFor][6] 	*/,NIL})
			aadd(aLinha,{"D3_LOCAL"		,oModelTFS:GetValue("TFS_LOCAL")/*aDados[2][nCntFor][8]*/ 	,NIL})
			aadd(aLinha,{"D3_LOCALIZ"   ,oModelTFS:GetValue("TFS_LOCALI")/*aDados[2][nCntFor][9]*/ 	,NIL})
			aadd(aLinha,{"D3_CC"      	,oModelTFS:GetValue("TFS_CC")/*aDados[2][nCntFor][7]*/	,NIL})
			aadd(aLinha,{"D3_LOTECTL"   ,oModelTFS:GetValue("TFS_LOTECT")/*aDados[2][nCntFor][10]*/ ,NIL})
			aadd(aLinha,{"D3_NUMLOTE"   ,oModelTFS:GetValue("TFS_NUMLOT")/*aDados[2][nCntFor][11]*/ ,NIL})
			aadd(aLinha,{"D3_NUMSERI"   ,oModelTFS:GetValue("TFS_NUMSER")/*aDados[2][nCntFor][12]*/ ,NIL})			
			FwRestRows(aSaveLines)
			
			// Verifica se a linha do apontamento do material operacional possui movimenta��o	
			If !Empty(oModelTFS:GetValue("TFS_NUMMOV"))
				aadd(aLinha,{"D3_NUMSEQ"   ,oModelTFS:GetValue("TFS_NUMMOV"),NIL})
				DbSelectArea("TFS")
				DbSetOrder(1)
				If TFS->(DbSeek(xFilial("TFS")+oModelTFS:GetValue("TFS_CODIGO")/*aDados[2][nCntFor][2]*/))		//Verifica se a linha teve altera��o
					aLinha2:={}													//array que receber� o valores da tabela para compara��o com o linha atual
					aadd(aLinha2,{TFS->TFS_FILIAL		})		
					aadd(aLinha2,{TFS->TFS_TM			})
					aadd(aLinha2,{Posicione("TFG", 1, xFilial("TFG") + TFS->TFS_CODTFG, "TFG_PRODUT")})
					aadd(aLinha2,{TFS->TFS_QUANT		})
					aadd(aLinha2,{TFS->TFS_LOCAL	 	})
					aadd(aLinha2,{TFS->TFS_LOCALI	 	})
					aadd(aLinha2,{TFS->TFS_CC			})
					aadd(aLinha2,{TFS->TFS_LOTECT	 	})
					aadd(aLinha2,{TFS->TFS_NUMLOT	 	})
					aadd(aLinha2,{TFS->TFS_NUMSER	 	})
					aadd(aLinha2,{TFS->TFS_NUMMOV	 	})		
				EndIf
				lAlter	:=	At890Alt(aLinha2, aLinha)
				If lAlter															//Verifica se a linha sofreu altera��o
					DbSelectArea("SD3")
					DbSetOrder(6)
					If SD3->(DbSeek(xFilial("SD3")+Dtos(oModelTFS:GetValue("TFS_DTAPON")/*aDados[2][nCntFor][15]*/)+ oModelTFS:GetValue("TFS_NUMMOV")/*aDados[2][nCntFor][14]*/))
						aadd(aLinha,{"D3_EMISSAO"   ,SD3->D3_EMISSAO ,NIL})
						aadd(aLinha,{"INDEX"			,6						, NIL})
						MATA240(aLinha,5)											// Quando teve altera��o a movimenta��o atual ser� extornada.
						If !lMsErroAuto
							If cCntRec <> "1"
								DbSelectArea("TFS")
								DbSetOrder(1)
								If TFS->(DbSeek(xFilial("TFS")+FWFLDGET("TFS_CODIGO")))
									If Empty(FWFLDGET("TFS_CODKIT"))
										lRetorno	:=	At890Extrn(TFS->TFS_QUANT, "TFG", TFS->TFS_CODTFG)														
									Else 
										lRetorno	:=	At890Extrn(TFS->TFS_QTDKIT, "TFG", TFS->TFS_CODTFG)														
									Endif
								EndIf
							EndIf
							If lRetorno
								At995ExcC(oMdlTFL:GetValue("TFL_CODPAI"),TFS->TFS_CODTWZ)
								aLinha[12][2]:=dDataBase
								MATA240(aLinha,3)									// Depois do movimento ter sido extornado ele ir� gerar uma nova movimenta��o
								If !lMsErroAuto
									If cCntRec <> "1"
										If Empty(FWFLDGET("TFS_CODKIT"))
											lRetorno	:=	At890Apont(FWFLDGET("TFS_QUANT"), "TFG", FWFLDGET("TFS_CODTFG"))
										Else
											lRetorno	:=	At890Apont(FWFLDGET("TFS_QTDKIT"), "TFG", FWFLDGET("TFS_CODTFG"))
										Endif
	
										If lRetorno
											ConOut(STR0013) //"Inclusao com sucesso!"
											oModelTFS:GoLine(nCntFor)
											oModelTFS:LoadValue("TFS_NUMMOV",SD3->D3_NUMSEQ)
											oModelTFS:LoadValue("TFS_DTAPON",dDataBase)
											cCodTWZ := At995Custo(oMdlTFL:GetValue("TFL_CODPAI"),;
																oModelTFS:GetValue("TFS_CODTFG"),;
																oMdlTFL:GetValue("TFL_CODIGO"),;
																oModelTFS:GetValue("TFS_PRODUT"),;
																"2",SD3->D3_CUSTO1,"TECA890")
											If !Empty(cCodTWZ)
												oModelTFS:LoadValue("TFS_CODTWZ",cCodTWZ)
											EndIf
										EndIf
									Endif								
								Else
									ConOut(STR0014) //"Erro na inclusao!"
									MostraErro()
									lRetorno	:=	.F.
								EndIf
							EndIf
						Else
							ConOut(STR0015) //"Erro na Altera��o!"
							MostraErro()
							lRetorno	:=	.F.
						EndIf
					EndIf
				EndIf
			Else						//Se for a primeira inclus�o
				MATA240(aLinha,3)		//Ir� gerar a movimenta��o
				If !lMsErroAuto
					If cCntRec <> "1"
						If Empty(FwFldGet("TFS_CODKIT"))
							lRetorno	:=	At890Apont(FWFLDGET("TFS_QUANT"), "TFG", FWFLDGET("TFS_CODTFG"))
						Else
							nPosKit := aScan(aKitsApont,{|x| AllTrim(x[2]) == AllTrim(FwFldGet("TFS_CODKIT"))})
							If 	nPosKit == 0 .OR. (nPosKit > 0 .AND. AllTrim(aKitsApont[nPosKit,1]) <> FWFLDGET("TFS_CODTFG") ) 						
								aAdd(aKitsApont,{FWFLDGET("TFS_CODTFG"),FwFldGet("TFS_CODKIT")})
								lRetorno	:=	At890Apont(FWFLDGET("TFS_QTDKIT"), "TFG", FWFLDGET("TFS_CODTFG"))
							EndIf
						EndIf
					Endif
					If lRetorno
						ConOut(STR0013) //"Inclusao com sucesso! "
						oModelTFS:GoLine(nCntFor)
						oModelTFS:LoadValue("TFS_NUMMOV",SD3->D3_NUMSEQ)
						cCodTWZ := At995Custo(oMdlTFL:GetValue("TFL_CODPAI"),;
											oModelTFS:GetValue("TFS_CODTFG"),;
											oMdlTFL:GetValue("TFL_CODIGO"),;
											oModelTFS:GetValue("TFS_PRODUT"),;
											"2",SD3->D3_CUSTO1,"TECA890")
						If !Empty(cCodTWZ)
							oModelTFS:LoadValue("TFS_CODTWZ",cCodTWZ)
						EndIf
					EndIf
				Else
					ConOut(STR0014) //"Erro na inclusao!"
					MostraErro()
					lRetorno	:=	.F.
				EndIf		
			EndIf	
		Else		//Se for um delete
					///tratamento de extorno por delete
			If !Empty(oModelTFS:GetValue("TFS_NUMMOV")/*aDados[2][nCntFor][14]*/) .AND. !Empty(oModelTFS:GetValue("TFS_CODTFG")/*aDados[2][nCntFor][3]*/)//Valida se � uma linha que j� possuia movimenta��o
				cCodKit := oModelTFS:GetValue("TFS_CODKIT") + oModelTFS:GetValue("TFS_SEQKIT")
				aadd(aLinha,{"D3_FILIAL"    ,xFilial("SD3")			,NIL})		
				aadd(aLinha,{"D3_TM"     	,oModelTFS:GetValue("TFS_TM")/*aDados[2][nCntFor][13]*/	,NIL})
				aadd(aLinha,{"D3_COD"     	,oModelTFS:GetValue("TFS_PRODUT")/*aDados[2][nCntFor][4]*/ 	,NIL})
				aadd(aLinha,{"D3_QUANT"     ,oModelTFS:GetValue("TFS_QUANT")/*aDados[2][nCntFor][6] 	*/,NIL})
				aadd(aLinha,{"D3_LOCAL"		,oModelTFS:GetValue("TFS_LOCAL")/*aDados[2][nCntFor][8]*/ 	,NIL})
				aadd(aLinha,{"D3_LOCALIZ"   ,oModelTFS:GetValue("TFS_LOCALI")/*aDados[2][nCntFor][9]*/ 	,NIL})
				aadd(aLinha,{"D3_CC"      	,oModelTFS:GetValue("TFS_CC")/*aDados[2][nCntFor][7]*/	,NIL})
				aadd(aLinha,{"D3_LOTECTL"   ,oModelTFS:GetValue("TFS_LOTECT")/*aDados[2][nCntFor][10]*/ ,NIL})
				aadd(aLinha,{"D3_NUMLOTE"   ,oModelTFS:GetValue("TFS_NUMLOT")/*aDados[2][nCntFor][11]*/ ,NIL})
				aadd(aLinha,{"D3_NUMSERI"   ,oModelTFS:GetValue("TFS_NUMSER")/*aDados[2][nCntFor][12]*/ ,NIL})	
				aadd(aLinha,{"D3_NUMSEQ"   ,oModelTFS:GetValue("TFS_NUMMOV")/*aDados[2][nCntFor][14]*/ ,NIL})
				DbSelectArea("SD3")
				DbSetOrder(6)
				If SD3->(DbSeek(xFilial("SD3")+Dtos(oModelTFS:GetValue("TFS_DTAPON")/*aDados[2][nCntFor][15]*/)+ oModelTFS:GetValue("TFS_NUMMOV")/*aDados[2][nCntFor][14]*/))	//Posiciona na movimenta��o
					aadd(aLinha,{"D3_EMISSAO"   ,SD3->D3_EMISSAO ,NIL})										//recebe no array a data de movimenta��o
					aadd(aLinha,{"INDEX"			,6					, NIL})
					MATA240(aLinha,5)		//Executa extorno da movimenta��o
					If !lMsErroAuto
						If cCntRec <> "1"
							If Empty(cCodKit) .OR. (!Empty(cCodKit) .AND. cCodKit <> cKitExcl )
								cKitExcl := cCodKit
								DbSelectArea("TFS")
								DbSetOrder(1)
								If TFS->(DbSeek(xFilial("TFS")+FWFLDGET("TFS_CODIGO")))
									If !Empty(cCodKit)
										lRetorno :=	At890Extrn(TFS->TFS_QTDKIT, "TFG", TFS->TFS_CODTFG)
									Else
										lRetorno	:=	At890Extrn(TFS->TFS_QUANT, "TFG", TFS->TFS_CODTFG)
									EndIf
									If lRetorno
										At995ExcC(oMdlTFL:GetValue("TFL_CODPAI"),TFS->TFS_CODTWZ)
									EndIf
								EndIf
							EndIf
						EndIf
						ConOut(STR0016) //"Estorno com sucesso!"
					Else
						ConOut(STR0017) //"Erro no Estorno!"
						MostraErro()
						lRetorno	:=	.F.
					EndIf
				EndIf
			EndIf
		EndIf
		aLinha := {}
	Else		//Se a linha foi deletada e j� foi apurado.
		oModelTFS:UnDeleteLine()
	EndIf
	FwRestRows( aSaveLines )
Next nCntFor

aKitsApont := {}
cKitExcl   := ""

For nCntFor := 1 To oModelTFT:Length()									//Percorrer� todo grid do material Operacional
	aLinha2:={}
	aLinha:={}
	oModelTFT:GoLine(nCntFor)
	aSaveLines	:= FWSaveRows()
	aDados	:= aClone(oModelTFT:GetOldData())
	If Empty(oModelTFT:GetValue("TFT_ITAPUR")/*aDados[2][nCntFor][16]*/)									//Verifica se ja foi apurado
		If (!oModelTFT:IsDeleted() .AND. !Empty(oModelTFT:GetValue("TFT_CODTFH")/*aDados[2][nCntFor][3]*/))
			aadd(aLinha,{"D3_FILIAL"    ,xFilial("SD3")			,NIL})		
			aadd(aLinha,{"D3_TM"     	,oModelTFT:GetValue("TFT_TM")/*aDados[2][nCntFor][13]*/	,NIL})
			aadd(aLinha,{"D3_COD"     	,oModelTFT:GetValue("TFT_PRODUT")/*aDados[2][nCntFor][4]*/ 	,NIL})
			aadd(aLinha,{"D3_QUANT"     ,oModelTFT:GetValue("TFT_QUANT")/*aDados[2][nCntFor][6]*/ 	,NIL})
			aadd(aLinha,{"D3_LOCAL"		,oModelTFT:GetValue("TFT_LOCAL")/*aDados[2][nCntFor][8]*/ 	,NIL})
			aadd(aLinha,{"D3_LOCALIZ"   ,oModelTFT:GetValue("TFT_LOCALI")/*aDados[2][nCntFor][9]*/ 	,NIL})
			aadd(aLinha,{"D3_CC"      	,oModelTFT:GetValue("TFT_CC")/*aDados[2][nCntFor][7]*/	,NIL})
			aadd(aLinha,{"D3_LOTECTL"   ,oModelTFT:GetValue("TFT_LOTECT")/*aDados[2][nCntFor][10]*/ ,NIL})
			aadd(aLinha,{"D3_NUMLOTE"   ,oModelTFT:GetValue("TFT_NUMLOT")/*aDados[2][nCntFor][11]*/ ,NIL})
			aadd(aLinha,{"D3_NUMSERI"   ,oModelTFT:GetValue("TFT_NUMSER")/*aDados[2][nCntFor][12]*/ ,NIL})	
			
			If !Empty(oModelTFT:GetValue("TFT_NUMMOV"))	    //Verifica se tem n�mero de movimenta��o-
				aadd(aLinha,{"D3_NUMSEQ"   ,oModelTFT:GetValue("TFT_NUMMOV")/*aDados[2][nCntFor][14]*/ ,NIL})
				DbSelectArea("TFT")
				DbSetOrder(1)
				If TFT->(DbSeek(xFilial("TFT")+ oModelTFT:GetValue("TFT_CODIGO")/*aDados[2][nCntFor][2]*/)) //busca TFT pelo c�digo
					aLinha2:={}
					aadd(aLinha2,{TFT->TFT_FILIAL		})		
					aadd(aLinha2,{TFT->TFT_TM			})
					aadd(aLinha2,{Posicione("TFH", 1, xFilial("TFH") + TFT->TFT_CODTFH, "TFH_PRODUT")})
					aadd(aLinha2,{TFT->TFT_QUANT		})
					aadd(aLinha2,{TFT->TFT_LOCAL	 	})
					aadd(aLinha2,{TFT->TFT_LOCALI	 	})
					aadd(aLinha2,{TFT->TFT_CC			})
					aadd(aLinha2,{TFT->TFT_LOTECT	 	})
					aadd(aLinha2,{TFT->TFT_NUMLOT	 	})
					aadd(aLinha2,{TFT->TFT_NUMSER	 	})	
					aadd(aLinha2,{TFT->TFT_NUMMOV	 	})	
				EndIf
				lAlter	:=	At890Alt(aLinha2, aLinha)					//Se houve altera��o 
				If lAlter
					DbSelectArea("SD3")
					DbSetOrder(6)
					If SD3->(DbSeek(xFilial("SD3")+Dtos(oModelTFT:GetValue("TFT_DTAPON")/*aDados[2][nCntFor][15]*/)+ oModelTFT:GetValue("TFT_NUMMOV")/*aDados[2][nCntFor][14]*/))
						aadd(aLinha,{"D3_EMISSAO"   ,SD3->D3_EMISSAO ,NIL})
						aadd(aLinha,{"INDEX"			,6						, NIL})
						MATA240(aLinha,5)
						If !lMsErroAuto
							If cCntRec <> "1"
								DbSelectArea("TFT")
								DbSetOrder(1)
								If TFT->(DbSeek(xFilial("TFT")+FWFLDGET("TFT_CODIGO")))
									If Empty(FWFLDGET("TFT_CODKIT"))
										lRetorno	:=	At890Extrn(TFT->TFT_QUANT, "TFH", TFT->TFT_CODTFH)
									Else
										lRetorno	:=	At890Extrn(TFT->TFT_QTDKIT, "TFH", TFT->TFT_CODTFH)	
									Endif
								EndIf
							Endif
							If lRetorno
								At995ExcC(oMdlTFL:GetValue("TFL_CODPAI"),TFT->TFT_CODTWZ)
								aLinha[12][2]:=dDataBase
								MATA240(aLinha,3)	
								If !lMsErroAuto
									If cCntRec <> "1"
										If Empty(FwFldGet("TFT_CODKIT"))
											lRetorno	:=	At890Apont(FWFLDGET("TFT_QUANT"), "TFH", FWFLDGET("TFT_CODTFH"))
										Else
											lRetorno	:=	At890Apont(FWFLDGET("TFT_QTDKIT"), "TFH", FWFLDGET("TFT_CODTFH"))
										EndIf
									Endif
									If lRetorno
										ConOut(STR0013) //"Inclusao com sucesso!"
										oModelTFT:GoLine(nCntFor)
										oModelTFT:LoadValue("TFT_NUMMOV",SD3->D3_NUMSEQ)
										oModelTFT:LoadValue("TFT_DTAPON",dDataBase)
										cCodTWZ := At995Custo(oMdlTFL:GetValue("TFL_CODPAI"),;
													oModelTFT:GetValue("TFT_CODTFH"),;
													oMdlTFL:GetValue("TFL_CODIGO"),;
													oModelTFT:GetValue("TFT_PRODUT"),;
													"3",SD3->D3_CUSTO1,"TECA890")
										If !Empty(cCodTWZ)
											oModelTFT:LoadValue("TFT_CODTWZ",cCodTWZ)
										EndIf
									EndIf
								Else
									ConOut(STR0014) //"Erro na inclus�o!"
									MostraErro()
									lRetorno	:=	.F.
								EndIf
							EndIf
						Else
							ConOut(STR0015) //"Erro na Altera��o!"
							MostraErro()
							lRetorno	:=	.F.
						EndIf
					EndIf
				EndIf
			Else
				MATA240(aLinha,3)	
				If !lMsErroAuto
					If cCntRec <> "1"
						If Empty(FwFldGet("TFT_CODKIT"))
							lRetorno	:=	At890Apont(FWFLDGET("TFT_QUANT"), "TFH", FWFLDGET("TFT_CODTFH"))
						Else
							nPosKit := aScan(aKitsApont,{|x| AllTrim(x[2]) == AllTrim(FwFldGet("TFT_CODKIT"))})
							If 	nPosKit == 0 .OR. (nPosKit > 0 .AND. AllTrim(aKitsApont[nPosKit,1]) <> FWFLDGET("TFT_CODTFH") ) 						
								aAdd(aKitsApont,{FWFLDGET("TFT_CODTFH"),FwFldGet("TFT_CODKIT")})
							lRetorno	:=	At890Apont(FWFLDGET("TFT_QTDKIT"), "TFH", FWFLDGET("TFT_CODTFH"))
							EndIf
						EndIf
					Endif
					If lRetorno
						ConOut(STR0013) //"Inclusao com sucesso!"
						oModelTFT:GoLine(nCntFor)
						oModelTFT:LoadValue("TFT_NUMMOV",SD3->D3_NUMSEQ)
						cCodTWZ := At995Custo(oMdlTFL:GetValue("TFL_CODPAI"),;
									oModelTFT:GetValue("TFT_CODTFH"),;
									oMdlTFL:GetValue("TFL_CODIGO"),;
									oModelTFT:GetValue("TFT_PRODUT"),;
									"3",SD3->D3_CUSTO1,"TECA890")
						If !Empty(cCodTWZ)
							oModelTFT:LoadValue("TFT_CODTWZ",cCodTWZ)
						EndIf
					EndIf
				Else
					ConOut(STR0014) //"Erro na inclus�o!"
					MostraErro()
					lRetorno	:=	.F.
				EndIf		
			EndIf
		Else
		///tratar extorno aqui.
			If !Empty(oModelTFT:GetValue("TFT_NUMMOV")/*aDados[2][nCntFor][14]*/) .AND. !Empty(oModelTFT:GetValue("TFT_CODTFH")/*aDados[2][nCntFor][3]*/)
				cCodKit := oModelTFT:GetValue("TFT_CODKIT") + oModelTFT:GetValue("TFT_SEQKIT")
				aadd(aLinha,{"D3_FILIAL"    ,FWxFilial("SD3")		                                    ,NIL})		
				aadd(aLinha,{"D3_TM"     	,oModelTFT:GetValue("TFT_TM")/*aDados[2][nCntFor][13]*/	,NIL})
				aadd(aLinha,{"D3_COD"     	,oModelTFT:GetValue("TFT_PRODUT")/*aDados[2][nCntFor][4]*/ 	,NIL})
				aadd(aLinha,{"D3_QUANT"     ,oModelTFT:GetValue("TFT_QUANT")/*aDados[2][nCntFor][6]*/ 	,NIL})
				aadd(aLinha,{"D3_LOCAL"		,oModelTFT:GetValue("TFT_LOCAL")/*aDados[2][nCntFor][8]*/ 	,NIL})
				aadd(aLinha,{"D3_LOCALIZ"   ,oModelTFT:GetValue("TFT_LOCALI")/*aDados[2][nCntFor][9]*/ 	,NIL})
				aadd(aLinha,{"D3_CC"      	,oModelTFT:GetValue("TFT_CC")/*aDados[2][nCntFor][7]*/	,NIL})
				aadd(aLinha,{"D3_LOTECTL"   ,oModelTFT:GetValue("TFT_LOTECT")/*aDados[2][nCntFor][10]*/ ,NIL})
				aadd(aLinha,{"D3_NUMLOTE"   ,oModelTFT:GetValue("TFT_NUMLOT")/*aDados[2][nCntFor][11]*/ ,NIL})
				aadd(aLinha,{"D3_NUMSERI"   ,oModelTFT:GetValue("TFT_NUMSER")/*aDados[2][nCntFor][12]*/ ,NIL})	
				aadd(aLinha,{"D3_NUMSEQ"   ,oModelTFT:GetValue("TFT_NUMMOV")/*aDados[2][nCntFor][14]*/ ,NIL})
				DbSelectArea("SD3")
				DbSetOrder(6)
				If SD3->(DbSeek(xFilial("SD3")+Dtos(oModelTFT:GetValue("TFT_DTAPON")/*aDados[2][nCntFor][15]*/)+ oModelTFT:GetValue("TFT_NUMMOV")/*aDados[2][nCntFor][14]*/))
					aadd(aLinha,{"D3_EMISSAO"   ,SD3->D3_EMISSAO ,NIL})
					aadd(aLinha,{"INDEX"			,6						, NIL})
					MATA240(aLinha,5)
					If !lMsErroAuto
						If cCntRec <> "1"
							If Empty(cCodKit) .OR. (!Empty(cCodKit) .AND. cCodKit <> cKitExcl)
								cKitExcl := cCodKit
								DbSelectArea("TFT")
								DbSetOrder(1)
								If TFT->(DbSeek(xFilial("TFT")+FWFLDGET("TFT_CODIGO")))
									If !Empty(cCodKit)
										lRetorno :=	At890Extrn(TFT->TFT_QTDKIT, "TFH", TFT->TFT_CODTFH)
									Else
										lRetorno	:=	At890Extrn(TFT->TFT_QUANT, "TFH", TFT->TFT_CODTFH)
										At995ExcC(oMdlTFL:GetValue("TFL_CODPAI"),TFT->TFT_CODTWZ)
									EndIf
								EndIf
							EndIf
						Endif
						ConOut(STR0016) //"Estorno com sucesso!"
					Else
						ConOut(STR0017) //"Erro no Estorno!"
						MostraErro()
						lRetorno	:=	.F.
					EndIf
				EndIf
			EndIf
		EndIf
		aLinha := {}
	Else
		oModelTFT:UnDeleteLine()
	EndIf
	FwRestRows( aSaveLines )	
Next nCntFor	 
RestArea(aArea)

cKitExcl := ""

Return (lRetorno)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890Apont

Realiza a Grava��o dos dados utilizando a ExecAuto MATA240 para inclus�o de apontamentos
no Modulo Estoque
@author  Servi�os
@since 	  31/10/13
@version P11 R9
@param nQuApnt: Quantidade que se deseja apontar.
@param cAliasMat: O "alias" que se deseja, podendo ser da TFG para mat�riais operacionais e TFH para os mat�riais de Consumo.
@param cCodMat: C�digo do Material a ser apontado.

@return lRet: Retorna .T. quando o saldo do material foi suficiente para suprir a quantidade do apontamento.
/*/
//--------------------------------------------------------------------------------------------------------------------

Function At890Apont(nQuApnt, cAliasMat, cCodMat)
Local aArea	:= GetArea()
Local nQuApont	:=	nQuApnt
Local cCodigo		:=	cCodMat
Local lRet			:= .F.

DbSelectArea(cAliasMat)
DbSetOrder(1)
If (cAliasMat)->(DbSeek(xFilial(cAliasMat)+cCodigo))
	If cAliasMat == "TFG" .AND. (cAliasMat)->TFG_SLD >= nQuApont
		RecLock(cAliasMat,.F.)
		(cAliasMat)->TFG_SLD	:=	(cAliasMat)->TFG_SLD - nQuApont
		MsUnlock()
		lRet:=.T.
	ElseIf cAliasMat == "TFH" .AND. (cAliasMat)->TFH_SLD >= nQuApont
		RecLock(cAliasMat,.F.)
		(cAliasMat)->TFH_SLD	:=	(cAliasMat)->TFH_SLD - nQuApont
		MsUnlock()
		lRet:=.T.
	Else
		HELP(,,'Saldo',,STR0020)//"Saldo insuficiente para esta quantidade!"
		lRet:= .F.
	EndIf
EndIf
RestArea(aArea)
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890Extrn

Realiza a Grava��o dos dados utilizando a ExecAuto MATA240 para extorno de apontamentos
no Modulo Estoque
@author  Servi�os
@since 	  31/10/13
@version P11 R9
@param nQuApnt: Quantidade que se deseja apontar.
@param cAliasMat: O "alias" que se deseja, podendo ser da TFG para mat�riais operacionais e TFH para os mat�riais de Consumo.
@param cCodMat: C�digo do Material a ser apontado.

@return lRet: Retorna .T. quando o extorno for realizado.
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At890Extrn(nQuApnt, cAliasMat, cCodMat)
Local aArea	:= GetArea()	
Local nQuApont	:=	nQuApnt
Local cCodigo		:=	cCodMat
Local lRet			:= .F.

DbSelectArea(cAliasMat)
DbSetOrder(1)
If (cAliasMat)->(DbSeek(xFilial(cAliasMat)+cCodigo))
	If cAliasMat == "TFG"
		RecLock(cAliasMat,.F.)
		(cAliasMat)->TFG_SLD	:=	(cAliasMat)->TFG_SLD + nQuApont 	
		MsUnlock()
		lRet:=.T.
	ElseIf cAliasMat == "TFH"
		RecLock(cAliasMat,.F.)
		(cAliasMat)->TFH_SLD	:=	(cAliasMat)->TFH_SLD + nQuApont
		MsUnlock()
		lRet:=.T.
	EndIf
EndIf
RestArea(aArea)
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890Alt

Realiza a Grava��o dos dados utilizando a ExecAuto MATA240 para extorno de apontamentos
no Modulo Estoque
@author  Servi�os
@since 	  31/10/13
@version P11 R9
@param aDdBnc: Array com informa��es do Banco
@param aDdGrid:Array com informa��es da linha do Grid

@return lRet: Retorna .T. quando encontrou valores diferentes nos arrays.
/*/
//--------------------------------------------------------------------------------------------------------------------

Static Function At890Alt(aDdBnc, aDdGrid)//Teve altera��o
Local nCont	:= 0
Local lRet	:= .F.
Local lKit   := !Empty(FwFldGet("TFS_CODKIT"))

For nCont := 1 To Len(aDdBnc)
	If	!lKit .And. aDdBnc[nCont][1]!=aDdGrid[nCont][2]
		lRet	:= .T.
	EndIf
Next nCont

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890GetLegend

Cria as informa��es referentes a legenda do grid de material de consumo.

@author  Servi�os
@since 	  31/10/13
@version P11 R9
@return lRet: Retorna .T. quando a cria��o foi bem sucedida.
/*/
//--------------------------------------------------------------------------------------------------------------------

Function At890GetLg()
Local	oLegenda := FwLegend():New()
       If	lLegend         
               oLegenda:Add('','GREEN',STR0021)	//"Apontamento n�o apurado"
               oLegenda:Add('','RED',STR0022)			//"Apontamento Apurado"
               oLegenda:Add('','BLACK',STR0113)			//"Apontamento com Periodicidade n�o aprovado"
               oLegenda:View()
               DelClassIntf()
       EndIf                                                                                                                                   
Return .T.

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890LgTFT

Atribui a cor verde nos apontamento do material de consumo que n�o foram apurados e vermelho no que j� foram apurados.
@author  	Servi�os
@since 	  	31/10/13
@version	P11 R9
@return 	br_verde para o apontamento que n�o foi apurado
@return 	br_vermelho par ao apontamento j� apurado
/*/
//--------------------------------------------------------------------------------------------------------------------

Function At890LgTFT(cItapur,cPend)
Local cCor			:= ""
Default cItapur 	:= ""
Default cPend 	:= "N"

If Empty(cItapur) .AND. cPend == "N"
	cCor	:=	'br_verde'
ElseIf Empty(cItapur) .AND. cPend == "S"
	cCor := 'br_preto'
ElseIf !Empty(cItapur) .AND. cPend == "N"
	cCor	:=	'br_vermelho'
EndIf

return cCor
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890LgTFS

Atribui a cor verde nos apontamento do material operacional que n�o foram apurados e vermelho no que j� foram apurados.
@author 	Servi�os
@since 		31/10/13
@version 	P11 R9
@return 	br_verde para o apontamento que n�o foi apurado
@return 	br_vermelho par ao apontamento j� apurado
/*/
//--------------------------------------------------------------------------------------------------------------------

Function At890LgTFS(cItapur,cPend)
Local cCor			:= ""
Default cItapur 	:= ""
Default cPend 	:= "N"

If Empty(cItapur) .AND. cPend == "N"
	cCor	:=	'br_verde'
ElseIf Empty(cItapur) .AND. cPend == "S"
	cCor := 'br_preto'
ElseIf !Empty(cItapur) .AND. cPend == "N"
	cCor	:=	'br_vermelho'
EndIf

return cCor

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  InitDados()

Inicializador do campo Saldo do material operacional
@author 	Servi�os
@since 		31/10/13
@version 	P11 R9
@Param		ExpO:Modelo de Dados da Tela de Locais de Atendimento

@return O saldo atual do material selecionado
/*/
//-------------------------------------------------
Static Function InitDados( oModel )

Local cDesLoc	:= ""
Local cMunic	:= ""
Local cEstado	:= ""
Local cCodMat      := ""
Local cCodKit      := ""
Local nQtdKit      := 0
Local aKitCmp      := {} // Array com os componentes de kit
Local nPosKit      := 0
Local cCodProd     := ""

Local oMdlTFS := oModel:GetModel("TFSGRID")
Local oMdlTFT := oModel:GetModel("TFTGRID")

Local nX := 0
Local nPos := 0
Local nVal := 0

Local aRetTFG := {}
Local aRetTFH := {}
Local aKits	  := {}
Local cCntRec := Posicione( "TFJ", 1, xFilial("TFJ") + FWFLDGET("TFL_CODPAI"), "TFJ_CNTREC")

DbSelectArea("ABS")
DbSetOrder(1)
If ABS->(DbSeek(xFilial("ABS")+FWFLDGET("TFL_LOCAL")))
	cDesLoc	:= ABS->ABS_DESCRI
	cMunic	:= ABS->ABS_MUNIC
	cEstado	:= ABS->ABS_ESTADO
Endif

oModel:LoadValue("TFLMASTER", "TFL_DESLOC", cDesLoc)               
oModel:LoadValue("TFLMASTER", "TFL_MUNIC" , cMunic)                
oModel:LoadValue("TFLMASTER", "TFL_ESTADO", cEstado)

aRetTFH := At890TFHRetAr(oModel:GetModel('TFLMASTER'):GetValue('TFL_CODIGO'))
aRetTFG := At890TFGRetAr(oModel:GetModel('TFLMASTER'):GetValue('TFL_CODIGO'))

lLegend := .F.

For nX := 1 To oMdlTFS:Length()        	

	oMdlTFS:GoLine(nX)

	cCodMat := oMdlTFS:GetValue('TFS_CODTFG')	

	If !Empty(cCodMat)
		//Legenda
		oMdlTFS:LoadValue("TFS_SIT" ,At890LgTFS(oMdlTFS:GetValue('TFS_ITAPUR'),oMdlTFS:GetValue('TFS_PEND')))	
	
		//Descri��es
		oMdlTFS:LoadValue("TFS_DPROD" ,Posicione("SB1", 1, xFilial("SB1") + oMdlTFS:GetValue('TFS_PRODUT'), "B1_DESC"))
		oMdlTFS:LoadValue("TFS_DESKIT",Posicione("SB1", 1, xFilial("SB1") + oMdlTFS:GetValue('TFS_CODKIT'), "B1_DESC"))
		
		nPos := ASCAN(aRetTFG, { |x| Alltrim(x[1]) == Alltrim(cCodMat) })
		
		cCodKit := oMdlTFS:GetValue('TFS_CODKIT')
		If !Empty(cCodKit)
			cCodProd := oMdlTFS:GetValue('TFS_PRODUT')
			nPosKit  := aScan(aKitCmp,{|x| AllTrim(x[1]) == AllTrim(cCodMat+cCodProd) })
			
			If nPosKit == 0
				nQtdKit := Posicione("TWX",1,FwxFilial("TWX")+cCodKit+cCodProd,"TWX_QUANT")
				nVal    := (aRetTFG[nPos,2] * nQtdKit) - oMdlTFS:GetValue('TFS_QUANT')
				
				Aadd(aKitCmp,{cCodMat+cCodProd,oMdlTFS:GetValue('TFS_QUANT')})
			Else
				nQtdKit := Posicione("TWX",1,FwxFilial("TWX")+cCodKit+cCodProd,"TWX_QUANT")
				nVal    := (aRetTFG[nPos,2] * nQtdKit) - (oMdlTFS:GetValue('TFS_QUANT')+ aKitCmp[nPosKit,2])
				
				aKitCmp[nPosKit,2] += oMdlTFS:GetValue('TFS_QUANT')
			EndIf
		Else
			nVal := aRetTFG[nPos,2] - oMdlTFS:GetValue('TFS_QUANT')
			aRetTFG[nPos,2] := nVal
		EndIf		
	EndIf     	
Next nX	

For nX := 1 To oMdlTFS:Length()        	

	oMdlTFS:GoLine(nX)

	cCodMat := oMdlTFS:GetValue('TFS_CODTFG')
	
	If !Empty(cCodMat)
		
		nPos := ASCAN(aRetTFG, { |x| Alltrim(x[1]) == Alltrim(cCodMat) })
		
		cCodKit := oMdlTFS:GetValue('TFS_CODKIT')
		If Empty(cCodKit)
			At890Set(oMdlTFS, "TFS_SLDTTL", aRetTFG[nPos,2] )
		Else		
			nPos := ASCAN(aKits, { |x| Alltrim(x[1])+Alltrim(x[2]) == Alltrim(cCodMat)+Alltrim(cCodKit) })
			If nPos == 0
				Aadd(aKits,{oMdlTFS:GetValue('TFS_CODTFG'),oMdlTFS:GetValue('TFS_CODKIT')})
			Endif
		Endif
	Endif
Next nX

DbSelectArea("TFG")
TFG->(DbSetOrder(1)) //TFG_FILIAL+TFG_COD
For nX := 1 To Len(aKits)
	If TFG->(DbSeek(xFilial("TFG")+aKits[nX,1]))
		AtSldKitComp(oMdlTFS, "TFS", aKits[nX,2])	
	Endif
Next nX

aKits := {}

For nX := 1 To oMdlTFT:Length()  

	oMdlTFT:GoLine(nX)

	cCodMat := oMdlTFT:GetValue('TFT_CODTFH')

	If !Empty(cCodMat)      	 

		//Legenda
		oMdlTFT:LoadValue("TFT_SIT" ,At890LgTFT(oMdlTFT:GetValue('TFT_ITAPUR'),oMdlTFT:GetValue('TFT_PEND')))
		
		//Descri��es
		oMdlTFT:LoadValue("TFT_DPROD" ,Posicione("SB1", 1, xFilial("SB1") + oMdlTFT:GetValue('TFT_PRODUT'), "B1_DESC"))	
		oMdlTFT:LoadValue("TFT_DESKIT",Posicione("SB1", 1, xFilial("SB1") + oMdlTFT:GetValue('TFT_CODKIT'), "B1_DESC"))

		nPos := ASCAN(aRetTFH, { |x| Alltrim(x[1]) == Alltrim(oMdlTFT:GetValue('TFT_CODTFH')) })
				
		cCodKit := oMdlTFT:GetValue('TFT_CODKIT')
		If !Empty(cCodKit)
			cCodProd := oMdlTFT:GetValue('TFT_PRODUT')
			nPosKit  := aScan(aKitCmp,{|x| AllTrim(x[1]) == AllTrim(cCodMat+cCodProd) })
			
			If nPosKit == 0
				nQtdKit := Posicione("TWX",1,FwxFilial("TWX")+cCodKit+cCodProd,"TWX_QUANT")
				nVal    := (aRetTFH[nPos,2] * nQtdKit) - oMdlTFT:GetValue('TFT_QUANT')
				
				Aadd(aKitCmp,{cCodMat+cCodProd,oMdlTFT:GetValue('TFT_QUANT')})
			Else
				nQtdKit := Posicione("TWX",1,FwxFilial("TWX")+cCodKit+cCodProd,"TWX_QUANT")
				nVal    := (aRetTFH[nPos,2] * nQtdKit) - (oMdlTFT:GetValue('TFT_QUANT')+ aKitCmp[nPosKit,2])
				
				aKitCmp[nPosKit,2] += oMdlTFT:GetValue('TFT_QUANT')
			EndIf
		Else
			nVal := aRetTFH[nPos,2] - oMdlTFT:GetValue('TFT_QUANT')
			aRetTFH[nPos,2] := nVal
		EndIf		
	EndIf     	
Next nX	

For nX := 1 To oMdlTFT:Length()  

	oMdlTFT:GoLine(nX)

	cCodMat := oMdlTFT:GetValue('TFT_CODTFH')
	
	If !Empty(cCodMat)      	 

		nPos := ASCAN(aRetTFH, { |x| Alltrim(x[1]) == Alltrim(oMdlTFT:GetValue('TFT_CODTFH')) })
				
		cCodKit := oMdlTFT:GetValue('TFT_CODKIT')
		If Empty(cCodKit)		
			At890Set(oMdlTFT, "TFT_SLDTTL", aRetTFH[nPos,2] )
		Else		
			nPos := ASCAN(aKits, { |x| Alltrim(x[1])+Alltrim(x[2]) == Alltrim(cCodMat)+Alltrim(cCodKit) })
			If nPos == 0
				Aadd(aKits,{oMdlTFT:GetValue('TFT_CODTFH'),oMdlTFT:GetValue('TFT_CODKIT')})
			Endif
		Endif
	Endif
Next nX

DbSelectArea("TFH")
TFH->(DbSetOrder(1)) //TFH_FILIAL+TFH_COD
For nX := 1 To Len(aKits)
	If TFH->(DbSeek(xFilial("TFH")+aKits[nX,1]))
		AtSldKitComp(oMdlTFT, "TFT", aKits[nX,2])	
	Endif
Next nX

lLegend := .T.

Return (Nil)
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890Set()

Grava o valor no campo conforme os par�metros.
@author 	Servi�os
@since 		31/10/13
@return 	lRet:Se a grava��o foi realizada com sucesso .T. / Se a grava��o n�o foi realizada com sucesso .F.
/*/
//-------------------------------------------------
Static Function At890Set(oModel, cField, xValue)
	Local lRet := .T.
	If oModel:GetOperation() == MODEL_OPERATION_VIEW
		oModel:LoadValue( cField, xValue )
	Else
		lRet := oModel:SetValue( cField, xValue )
	EndIf
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At870Cols

Colunas para o browse com os dados do Local x Or�amento
@author Servi�os
@since 02/12/2013
@version P11 R9

@param		ExpC1 - Alias utilizado para o retorno das colunas	
@return	nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At890Cols(cAliasPro)

Local nI			:= 0 
Local aArea		:= GetArea()
Local aColumns	:= {}
Local cCampo 	:= ""
Local nLinha 	:= 0
Local aCampos 	:= 	 {"TFJ_CODIGO" , "ADY_OPORTU", "TFL_CONTRT", "TFL_LOCAL", "ABS_DESCRI", "ABS_MUNIC",;
							"ABS_ESTADO", "TFL_DTINI","TFL_DTFIM"} 
							
DbSelectArea("SX3")
SX3->(DbSetOrder(2))

For nI:=1 To Len(aCampos)

	If SX3->(dbSeek(aCampos[nI]))
	
		cCampo := AllTrim(SX3->X3_CAMPO)
		
		AAdd(aColumns,FWBrwColumn():New())
		nLinha := Len(aColumns)
	   	aColumns[nLinha]:SetType(SX3->X3_TIPO)
	   	aColumns[nLinha]:SetTitle(X3Titulo())
		aColumns[nLinha]:SetSize(SX3->X3_TAMANHO)
		aColumns[nLinha]:SetDecimal(SX3->X3_DECIMAL)
		
		If SX3->X3_TIPO == "D"
			aColumns[nLinha]:SetData(&("{|| sTod(" + cCampo + ")}"))		
		Else
			aColumns[nLinha]:SetData(&("{||" + cCampo + "}"))	
		EndIf
		
	EndIf
	
Next nI

SX3->(dbCloseArea())

RestArea(aArea)

Return(aColumns)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890Query

Query com os dados do Local x Or�amento
@author Servi�os
@since 02/12/2013
@version P11 R9
	
@return	nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At890Query

Local cQuery := ""
If ValType(MV_PAR02) == 'N'
	MV_PAR02 := ' '
	MV_PAR03 := 'ZZZZZZZZZZZZZZZ'
	MV_PAR04 := ' '	
	MV_PAR05 := 'ZZZZZZZZZZZ'
EndIf

cQuery += "SELECT  TFJ_CODIGO , TFL_CONTRT,TFL_CODIGO, TFL_LOCAL, ABS_DESCRI, ABS_MUNIC, ABS_ESTADO, TFL_DTINI,TFL_DTFIM, TFJ_GESMAT, ISNULL(ADY_OPORTU,'') ADY_OPORTU, TFJ_GSMTMI, TFJ_GSMTMC, TFJ_ISGSMT"
 
cQuery += " FROM " + RetSqlName("TFL") + " TFL"

if MV_PAR01 == 1 //or�amento com contrato
	cQuery += " INNER JOIN " + RetSqlName("CN9") + " CN9"
	cQuery += " ON CN9_FILIAL = '" + xFilial("CN9") + "' AND"
	cQuery += " TFL_CONTRT = CN9_NUMERO  AND"  
	cQuery += " TFL_CONREV = CN9_REVISA"
	cQuery += " AND CN9_SITUAC = '05'"
	cQuery += " AND CN9.D_E_L_E_T_ = ' '"

elseif MV_PAR01 == 3 //ambos
	cQuery += " LEFT JOIN " + RetSqlName("CN9") + " CN9"
	cQuery += " ON CN9_FILIAL = '" + xFilial("CN9") + "' AND"
	cQuery += " TFL_CONTRT = CN9_NUMERO  AND"  
	cQuery += " TFL_CONREV = CN9_REVISA"
	cQuery += " AND CN9.D_E_L_E_T_ = ' '"

endif

cQuery += " INNER JOIN " + RetSqlName("TFJ")+ " TFJ"
cQuery += " ON TFJ_FILIAL = '" + xFilial("TFJ") + "' AND"
cQuery += " TFL_CODPAI = TFJ_CODIGO"  
if MV_PAR01 == 1 //or�amento com contrato
	cQuery += " AND TFJ_CONTRT <> '' "  
elseif MV_PAR01 == 2 //or�amento servi�o extra
	cQuery += " AND TFJ_SRVEXT = '1'" 
elseif MV_PAR01 == 3
	cQuery += " AND (TFJ_CONTRT <> '' OR TFJ_SRVEXT = '1') " 
endif
cQuery += " AND TFJ.D_E_L_E_T_ = ' '"
 
cQuery += " INNER JOIN " + RetSqlName("ABS")+ " ABS"
cQuery += " ON ABS_FILIAL = '" + xFilial("ABS") + "' AND"
cQuery += " TFL_LOCAL = ABS_LOCAL" 
cQuery += " AND ABS.D_E_L_E_T_ = ' '"

if MV_PAR01 == 1 //or�amento com contrato
	cQuery += " INNER JOIN " + RetSqlName("ADY")+ " ADY"
	cQuery += " ON ADY_FILIAL = '" + xFilial("ADY") + "' AND"
	cQuery += " TFJ_PROPOS = ADY_PROPOS"  
	cQuery += " AND ADY.D_E_L_E_T_ = ' '"
else 
	cQuery += " LEFT JOIN " + RetSqlName("ADY")+ " ADY"
	cQuery += " ON ADY_FILIAL = '" + xFilial("ADY") + "' AND"
	cQuery += " TFJ_PROPOS = ADY_PROPOS"  
	cQuery += " AND ADY.D_E_L_E_T_ = ' '"
endif	
 
cQuery += " WHERE TFL_FILIAL = '"+xFilial("TFL")+"' "
cQuery += " AND TFJ_STATUS = 1"

If MV_PAR01 == 1 
	cQuery += " AND TFJ_CONTRT BETWEEN '" +MV_PAR02+ "' AND '"+MV_PAR03+"' "
EndIf]

If MV_PAR01 == 2 
	cQuery += " AND TFJ_CODIGO BETWEEN '" +MV_PAR04+ "' AND '"+MV_PAR05+"' "
EndIf

If MV_PAR01 == 3
	cQuery += " AND ((TFJ_CODIGO BETWEEN '" +MV_PAR04+ "' AND '"+MV_PAR05+"') OR "	 
	cQuery += " (TFJ_CONTRT BETWEEN '" +MV_PAR02+ "' AND '"+MV_PAR03+"' AND CN9_SITUAC = '05')) "
endif

cQuery += " AND TFL.D_E_L_E_T_ = ' '"

cQuery += " ORDER BY TFJ_CODIGO"

Return(cQuery)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890Apon

In�cia a p�gina de apontamento
@author Servi�os
@param cCodTFL - C�digo a ser buscado na tabela TFL
@since 02/12/2013
@version P11 R9
	
@return	lRet- valor true quando tudo ocorrer de acordo
/*/
//--------------------------------------------------------------------------------------------------------------------

Function At890Apon(cCodTFL,cCodGesMat,cCodGsMtMi,cCodGsMtMc,cIsGsMt)	
Local aArea := GetArea()
Local cAliasTFL	:="TFL"
Local lRet := .F.
Local lGsMt	   := .F.
Local cMsgMi   := ""
Local cMsgMc   := ""	
Local nOper	   := 0
Local lCancel  := .F.

Private INCLUI := .F.
Private ALTERA := .T.
PRIVATE EXCLUI := .F.

Default cCodGesMat := ""
Default cCodGsMtMi := ""
Default cCodGsMtMc := ""
Default cIsGsMt	   := ""

//Foi necessario abrir o SX3
DbSelectArea("SX3")
SX3->(DbSetOrder(1))

DbSelectArea(cAliasTFL)
TFL->(DbSetOrder(1))//TFL_FILIAL+TFL_CODIGO
If (cAliasTFL)->(DbSeek(xFilial("TFL")+cCodTFL))
	//verificar se local est� encerrado - TFL_ENCE = 1
	If 	(cAliasTFL)->TFL_ENCE <> "1"	
		//Quando o codigo gest�o de materiais for igual a 2 ou 3 deve-se chamar a rotina de apontamento de materiais TECA891

		If cIsGsMt == "1"
			If cCodGsMtMi $ '2|3' .And. cCodGsMtMc $ '2|3' 
				lGsMt := .T.
			Else
				If cCodGsMtMi $ '2|3' .And. cCodGsMtMc == '1'
					nOper := GSEscolha( STR0099						,; 	//"Apontamento de Materiais."	
										STR0100						,;  //"Selecione o tipo de Gest�o de Materiais que deseja apontar."
										{ STR0101, STR0102 }		,;  //"Material de Implanta��o por valor" # "Material de Consumo por quantidade"
										1 ) 
					If nOper == 1
						lGsMt := .T.
					Elseif nOper == 2
						lGsMt := .F.
					Else
						lCancel := .T.
					Endif
				Elseif cCodGsMtMi == '1' .And. cCodGsMtMc $ '2|3'
					nOper := GSEscolha( STR0099					,;  //"Apontamento de Materiais."	
										STR0100					,;  //"Selecione o tipo de Gest�o de Materiais que deseja apontar."
										{ STR0103, STR0104 }	,;  //"Material de Implanta��o por quantidade"#"Material de Consumo por valor"
										1 ) 
					If nOper == 1
						lGsMt := .F.
					Elseif nOper == 2
						lGsMt := .T.
					Else
						lCancel := .T.
					Endif
				Endif
			Endif
		Else
			lGsMt := cCodGesMat $ '2|3'						
		Endif

		If !lCancel
			If lGsMt			
				FWExecView(Upper(STR0001),"VIEWDEF.TECA891",MODEL_OPERATION_UPDATE,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/)//"Apontamento de Materiais por Valor"
				lRet:=.T.		
			Else
				FWExecView(Upper(STR0001),"VIEWDEF.TECA890",MODEL_OPERATION_UPDATE,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/)//"Apontamento de Materiais por Quantidade"
				lRet:=.T.			
			endif
		Endif
	Elseif (cAliasTFL)->TFL_ENCE == "1" // local ja encerrado
		lRet:= .F.
		Aviso( STR0033, STR0034, { STR0035 }, 2 )	//"Aten��o", "Local j� encerrado. N�o permitido gerar movimenta��o", { "OK" } 
	Endif
Else
	Aviso( STR0036, STR0037, {STR0038 }, 2 )	//"Aten��o", "Registro n�o encontrado. Favor verificar", { "OK" } 
Endif
RestArea(aArea)
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890PosVal

P�s valida��o dos submodelos de grid.
@author Servi�os
@param cCodTFL - C�digo a ser buscado na tabela TFL
@since 02/12/2013
@version P11 R9
	
@return	lRet- valor true quando tudo ocorrer de acordo
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At890PosVal(oMdlG,nLine,cAcao,cCampo,cIdent,cCampoMVC,cCampoKit)

Local lRet       := .T.
Local cCodKit    := FwFldGet(cCampoKit)
Local cSeqKit    := FwFldGet(cIdent+"_SEQKIT")
Local aSaveLines := FWSaveRows() 
Local cCpoVal	 := ""
Local cPrdPrin   := ""
Local cTab		 := IIF(cCampoMVC <> nil, SubStr(cCampoMVC,1,3),'')
Local cCpoProd   := ""
Local cCpoQtd	 := ""
Local lDelKit	 := IsInCallStack("At890DelKit")

If cTab == 'TFS' .Or. cIdent == 'TFS'
	cCpoVal	 := 'TFS_CODTFG'
	cCpoProd := 'TFS_PRODUT'
	cCpoQtd  := "TFS_QUANT"
ElseIf cTab == 'TFT' .Or. cIdent == 'TFT'
	cCpoVal	 := 'TFT_CODTFH'
	cCpoProd := 'TFT_PRODUT'
	cCpoQtd  := "TFT_QUANT"
Endif

If !Empty(cCpoVal)
	cPrdPrin :=	At890PrdPad( oMdlG:GetValue(cCpoVal), cTab, oMdlG:GetValue(cCpoProd) )
EndIf	

If (cCampoMVC == 'TFS_PRODUT' .Or. cCampoMVC == 'TFT_PRODUT')  .And. cAcao == 'CANSETVALUE' .And. !(!Empty(FwFldGet("TFS_ITAPUR")) .OR.  AT890VldTWY(cPrdPrin))
	lRet := .F.
EndIf

If !Empty(FwFldGet(cCampo)) .AND.  cAcao == "DELETE"
	lRet:=.F.
	Help(,,'AT890DEL',,STR0027,1,0)//"Apontamento j� apurado! N�o pode ser deletado"
EndIf

If lRet .AND. cAcao $ "DELETE|UNDELETE"	
	If !Empty(cCodKit) .AND. !lDelKit
		lRet := At890DelKit(cCodKit,cIdent,cCampoKit,cCampo,cAcao,cSeqKit)
	Else 
		If !lDelKit
			//oMdlG:SetValue(cCpoQtd , 0 )
			//Atualiza o Saldo nas outras linhas
			lRet := At890AtSld(oMdlG,cIdent,oMdlG:GetValue(cCpoVal),oMdlG:GetValue(cCpoQtd),cAcao)
			If !lRet
					oMdlG:GetModel():SetErrorMessage(oMdlG:GetId(),cCpoProd,oMdlG:GetModel():GetId(),cCpoProd,'At890Del',; 
							STR0105, STR0106 ) //"Esse produto n�o pode ser restaurado"#"O saldo do produto ser� extrapolado com o que foi contratado s� o item for restaurado"

			EndIf
		EndIf	
	Endif
EndIf

FwRestRows( aSaveLines )		

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890DelKit

Ao deletar um item que � componente de um kit, essa rotina varre o resto do grid deletando os demais componentes.
@author Leandro Dourado - Totvs Ibirapuera
@param cCodTFL - C�digo a ser buscado na tabela TFL
@since 02/12/2013
@version P11 R9
	
@return	lRet- valor true quando tudo ocorrer de acordo
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At890DelKit(cCodKit,cTabela,cCampo,cCpoItapur,cAcao,cSeqKit)
Local oView   	:= FwViewActive()
Local oGrid   	:= oView:GetModel(cTabela+"GRID")
Local nLineBkp	:= oGrid:GetLine()
Local nX      	:= 0
Local cItapur 	:= ""
Local cSeqAtu 	:= ""
Local lRet	  	:= .T.

cKitExcl := cCodKit// + cSeqKit

At890CalcSldKit(oGrid, cTabela, cCodKit)

For nX := 1 To oGrid:Length()
	oGrid:GoLine(nX)
	cItapur := oGrid:GetValue(cCpoItapur)
	cSeqAtu := oGrid:GetValue(cTabela+"_SEQKIT")
	If AllTrim(oGrid:GetValue(cCampo)) == AllTrim(cCodKit) .AND. Empty(cItapur) .AND. cSeqAtu == cSeqKit
		If cAcao == "DELETE"
			oGrid:DeleteLine()
		Else
			If (nSaldoKit - oGrid:GetValue(cTabela+"_QTDKIT")) >= 0
				oGrid:UnDeleteLine()
			Else
				lRet := .F.
				oGrid:GetModel():SetErrorMessage(oGrid:GetId(),cCampo,oGrid:GetModel():GetId(),cCampo,'At890DelKit',; 
														STR0107, STR0108  ) //"Esse Kit n�o pode ser restaurado" # "O saldo do kit ser� extrapolado com o que foi contratado s� o item for restaurado"
			EndIf	
		EndIf
	EndIf
Next nX

If lRet
	AtSldKitComp(oGrid, cTabela, cCodKit)
	
	cKitExcl := ""
		
	oGrid:GoLine(nLineBkp)
	oView:Refresh()
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890ValdQnt

Valida campo quantidade
no Modulo Estoque
@author  Servi�os
@since 	  31/10/13
@version P11 R9
@param nQuApnt: Quantidade que se deseja apontar.
@param cAliasMat: O "alias" que se deseja, podendo ser da TFG para mat�riais operacionais e TFH para os mat�riais de Consumo.
@param cCodMat: C�digo do Material a ser apontado.

@return lRet: Retorna .T. quando o saldo do material foi suficiente para suprir a quantidade do apontamento.
/*/
//--------------------------------------------------------------------------------------------------------------------

Function At890ValdQnt(nQuApnt, cAliasMat, cCodMat)
Local aArea	:= GetArea()
Local nQuApont	:=	nQuApnt
Local cCodigo		:=	cCodMat
Local lRet			:= .F.
Local oModel	:= FWModelActive()
Local oModelTFS	:= oModel:GetModel("TFSGRID")
Local oModelTFT	:= oModel:GetModel("TFTGRID")
Local oView		:= FWViewActive()
Local nQuant	:=0
Local nQuantant	:= 0
Local nX:=1
Local nSld:=0
Local cCodTFG    := ""
Local aSaveLines := FWSaveRows()
Local oMdl893TFS := oModel:GetModel("TFSDETAIL")
Local nTpMov:="" //tipo de movimento - envio / retorno
Local cCodProd   := ""
Local nQtTFS:=0
Local cCodKit    := ""
Local aQtdKit    := {} // Array de controle de saldos dos componentes do kit.
Local nPosKit    := 0  // Posicao do aQtdKit, do componente do kit posicionado pela grid.
Local lIsKit     := .F.
Local cCtnRec 	 := Posicione( "TFJ", 1, xFilial("TFJ") + TFL->TFL_CODPAI, "TFJ_CNTREC")	
Local nBkpLine   := 0

If IsInCallStack("At890KitMat")
	lRet := .T.
Else
	//verificar rotina chamada
	If !IsInCallStack("At890RtMip")
		DbSelectArea(cAliasMat)
		DbSetOrder(1)
		If (cAliasMat)->(DbSeek(xFilial(cAliasMat)+cCodigo))
			If cAliasMat == "TFG" 
				cProdut:= oModelTFS:GetValue("TFS_CODTFG")	
				cCodProd := oModelTFS:GetValue("TFS_PRODUT")
				lIsKit   := Posicione("SB1",1,FwxFilial("SB1")+cCodProd,"B1_TIPO") == "KT"// Caso o produto informado seja um kit de materiais, far� a explos�o do produto.
				If lIsKit
					lRet :=.T.
				Else
					For nX := 1 To oModelTFS:Length() 
						oModelTFS:GoLine(nX)
						If oModelTFS:GetValue("TFS_CODTFG")==cProdut .AND. !oModelTFS:IsDeleted()
							nQuant:=nQuant+oModel:GetModel("TFSGRID"):GetValue("TFS_QUANT")
							nQuantant:= nQuantant+Posicione("TFS", 1, xFilial("TFS") + oModelTFS:GetValue("TFS_CODIGO"), "TFS_QUANT")
						EndIf
					Next nX
					
					If cCtnRec == "1"
						If (cAliasMat)->TFG_QTDVEN - nQuant >= 0
							lRet:=.T.
							nSld:= (cAliasMat)->TFG_QTDVEN - nQuant 
							For nX := 1 To oModelTFS:Length() 
								oModelTFS:GoLine(nX)
								If oModelTFS:GetValue("TFS_CODTFG") == cProdut 
									oModelTFS:LoadValue("TFS_SLDTTL", nSld )
								EndIf
							Next nX	
						Else
							HELP(,,'Saldo',,STR0020)//"Saldo insuficiente para esta quantidade!"
							lRet:= .F.
						EndIf	
					Else
						If (cAliasMat)->TFG_SLD + nQuantant - nQuant >= 0
							lRet:=.T.
							nSld:= (cAliasMat)->TFG_SLD + nQuantant - nQuant 
							For nX := 1 To oModelTFS:Length() 
								oModelTFS:GoLine(nX)
								If oModelTFS:GetValue("TFS_CODTFG") == cProdut 
									oModelTFS:LoadValue("TFS_SLDTTL", nSld )
								EndIf
							Next nX	
						Else
							HELP(,,'Saldo',,STR0020)//"Saldo insuficiente para esta quantidade!"
							lRet:= .F.
						EndIf	
					Endif
				EndIf		
			ElseIf cAliasMat == "TFH" 
				cProdut:=oModelTFT:GetValue("TFT_CODTFH")
				cCodProd := oModelTFT:GetValue("TFT_PRODUT")
				lIsKit   := Posicione("SB1",1,FwxFilial("SB1")+cCodProd,"B1_TIPO") == "KT"// Caso o produto informado seja um kit de materiais, far� a explos�o do produto.
				If lIsKit
					lRet :=.T.
				Else
					For nX := 1 To oModel:GetModel( "TFTGRID" ):Length()
						oModelTFT:GoLine(nX)
						If oModelTFT:GetValue("TFT_CODTFH")=cProdut .AND. !oModelTFT:IsDeleted()
							nQuant:=nQuant+oModel:GetModel("TFTGRID"):GetValue("TFT_QUANT")
							nQuantant:= nQuantant+Posicione("TFT", 1, xFilial("TFT") + FWFLDGET("TFT_CODIGO"), "TFT_QUANT")
						EndIf
					Next nX
					If cCtnRec == "1"
						If (cAliasMat)->TFH_QTDVEN - nQuant >= 0
							lRet:=.T.
							nSld:= (cAliasMat)->TFH_QTDVEN - nQuant 
							For nX := 1 To oModel:GetModel( "TFTGRID" ):Length() 
								oModelTFT:GoLine(nX)
								If oModelTFT:GetValue("TFT_CODTFH")=cProdut
									oModel:LoadValue("TFTGRID", "TFT_SLDTTL", nSld )
								EndIf
							Next nX	
						Else
							HELP(,,'Saldo',,STR0020)//"Saldo insuficiente para esta quantidade!"
							lRet:= .F.
						EndIf
					Else
						If (cAliasMat)->TFH_SLD + nQuantant - nQuant >= 0
							lRet:=.T.
							nSld:= (cAliasMat)->TFH_SLD + nQuantant - nQuant 
							For nX := 1 To oModel:GetModel( "TFTGRID" ):Length() 
								oModelTFT:GoLine(nX)
								If oModelTFT:GetValue("TFT_CODTFH")=cProdut
									oModel:LoadValue("TFTGRID", "TFT_SLDTTL", nSld )
								EndIf
							Next nX	
						Else
							HELP(,,'Saldo',,STR0020)//"Saldo insuficiente para esta quantidade!"
							lRet:= .F.
						EndIf
					Endif
				EndIf
			EndIf
		EndIf
		FwRestRows( aSaveLines )
		RestArea(aArea)
	Else	//rotina de retorno material implanta��o TECA893
		nSld:=0
		nQuant:=0
		cCodProd:= oMdl893TFS:GetValue("TFS_PRODUT")
		
		//Verifica o total de itens apontados no retorno
		nBkpLine := oMdl893TFS:GetLine()
		For nX := 1 To oMdl893TFS:Length() 
			oMdl893TFS:GoLine(nX)
			If oMdl893TFS:GetValue("TFS_PRODUT")=cCodProd
				nQtTFS += oMdl893TFS:GetValue("TFS_QUANT")
			EndIf
		Next nX	
		oMdl893TFS:GoLine(nBkpLine)
		
		//Verifica o saldo dos produtos j� apontados
		nSld := At890ApSld(cCodigo,cCodProd,"1")
					
		//verificar se saldo e positivo
		If (nSld - nQtTFS) >= 0 
			lRet:= .T.
		Else
			HELP(,,'Saldo',,STR0039) //"Saldo insuficiente para retornar esta quantidade, verifique!" 
			lRet:= .F.
		Endif
	Endif
EndIf

If lRet .And. ValType(oView) == "O"
	oView:Refresh()
Endif

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  AtSldKitComp

Corrige a apresenta��o do saldo dos produtos que s�o componentes de um kit.
@author  Leandro Dourado - Totvs Ibirapuera
@since 	 21/10/16
@version 12.1.14
@param nQuApnt: Quantidade que se deseja apontar.
@param cAliasMat: O "alias" que se deseja, podendo ser da TFG para mat�riais operacionais e TFH para os mat�riais de Consumo.
@param cCodMat: C�digo do Material a ser apontado.

@return lRet: Retorna .T. quando o saldo do material foi suficiente para suprir a quantidade do apontamento.
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function AtSldKitComp(oModelMat, cAliasMat, cCodKit)
Local oView      := FwViewActive()
Local cCodProd   := ""
Local cCpoProdut := ""
Local nX         := 0
Local nY         := 0
Local nZ		 := 0
Local aQtdKit    := {} // Array de controle de saldos dos componentes do kit.
Local nPosKit    := 0  // Posicao do aQtdKit, do componente do kit posicionado pela grid.
Local nQuant     := 0
Local nQuantant  := 0
Local nSld       := 0
Local nSldAnt    := 0
Local nQtdKit    := 0
Local cProdKit	 := 0
Local aInterCam	 := {}
Local cCodigo	 := ""
Local cCpoCod	 := ""
Local cCpoMov	 := ""
Local cCntRec	 := Posicione( "TFJ", 1, xFilial("TFJ") + TFL->TFL_CODPAI, "TFJ_CNTREC")

If cAliasMat == "TFS" 
	cCodigo	   := TFG->TFG_COD
	cCpoCod	   := cAliasMat+"_CODTFG"
	If cCntRec == "1"
		If IsInCallStack("InitDados")
			nSld := At890SldRec("TFS",cCodigo,.T.)
		Else
			At890CalcSldKit(oModelMat, cAliasMat, cCodKit)
			nSld := nSaldoKit
		EndIf	
	Else
		//nSld := TFG->TFG_SLD
		At890CalcSldKit(oModelMat, cAliasMat, cCodKit)
		nSld := nSaldoKit
	Endif 
ElseIf cAliasMat == "TFT" 
	cCodigo	   := TFH->TFH_COD
	cCpoCod	   := cAliasMat+"_CODTFH"
	If cCntRec == "1"	
		If IsInCallStack("InitDados")
			nSld := At890SldRec("TFT",cCodigo,.T.)
		Else
			At890CalcSldKit(oModelMat, cAliasMat, cCodKit)
			nSld := nSaldoKit
		EndIf	
	Else
		//nSld       := TFH->TFH_SLD
		At890CalcSldKit(oModelMat, cAliasMat, cCodKit)
		nSld := nSaldoKit
	Endif
EndIf

cCpoMov	   := cAliasMat+"_NUMMOV"
cCpoProdut := cAliasMat+"_PRODUT"
cCpoKit	   := cAliasMat+"_CODKIT"

nSldAnt := nSld

If !Empty(cCodKit) .And. !Empty(cCodigo)
	For nX  := 1 To oModelMat:Length()
		oModelMat:GoLine(nX)
		If oModelMat:GetValue(cCpoCod) == cCodigo  .And. oModelMat:GetValue(cCpoKit) == cCodKit
			
			// Inicio do tratamento de saldo para componentes de kits de produtos.
			cCodProd := At890KtPrd(cCodKit,oModelMat:GetValue(cCpoProdut))

			If cAliasMat == "TFS"
				aInterCam	:= At890RtTWY()
			Elseif cAliasMat == "TFT"
				aInterCam	:= At890TWYRet()
			Endif

			For nZ := 1 To Len(aInterCam)
				cCodProd += "|"+aInterCam[nZ,2]
			Next nZ
			
			If !Empty(cCodProd) .And. !Empty(cCodKit)
	
				nPosKit  := aScan(aQtdKit,{|x| AllTrim(x[1]) $ AllTrim(cCodProd)})
				
				nQuant    := oModelMat:GetValue(cAliasMat+"_QUANT")
				nQuantant := Posicione(cAliasMat, 1, xFilial(cAliasMat) + oModelMat:GetValue(cAliasMat+"_CODIGO"), cAliasMat+"_QUANT")
				
				If nPosKit > 0
					aQtdKit[nPosKit,2] += nQuant
					aQtdKit[nPosKit,3] += nQuantant
				Else
					Aadd(aQtdKit,{cCodProd,nQuant,nQuantant})
				EndIf
				
			EndIf
		Endif
	Next nX
	
	For nX := 1 To Len(aQtdKit)
	
		nSld := nSldAnt	

		nQtdKit := Posicione("TWX",1,FwxFilial("TWX")+cCodKit+aQtdKit[nX,1],"TWX_QUANT")
		
		If (nSld * nQtdKit) >= 0
			nSld := (nSld * nQtdKit)
			For nY := 1 To oModelMat:Length() 
				oModelMat:GoLine(nY)
				If oModelMat:GetValue(cCpoCod) == cCodigo .And. oModelMat:GetValue(cCpoKit) == cCodKit .And. oModelMat:GetValue(cCpoProdut) $ aQtdKit[nX,1]
					 oModelMat:LoadValue(cAliasMat+"_SLDTTL", nSld )
				EndIf
			Next nY	
		EndIf		
	Next nX

	//oModelMat:GoLine(1)
	If oView <> Nil	
		If oView:IsActive()
			oView:Refresh()
		Endif
	Endif
Endif

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890LinhaOK

Valida campos referentes a estoque
no Modulo Estoque
@author  Servi�os
@since 	  31/10/13
@version P11 R9

@return lRet: Retorna .T. quando os campos estiverem ok.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At890LinhaOK( oModelTFT )
Local aArray		:= {}
Local nX			:= 0
Local lRet			:= .T.
Local nQtd			:= 0
Local aArea		:= GetArea()
Local oModel	:= oModelTFT:GetModel()

If !Empty(oModelTFT:GetValue("TFT_PRODUT"))
	If	!Empty(oModelTFT:GetValue("TFT_LOTECT")) .OR.; 
		!Empty(oModelTFT:GetValue("TFT_NUMLOT")) .OR.;
		!Empty(oModelTFT:GetValue("TFT_LOCALI")) .OR.;
		!Empty(oModelTFT:GetValue("TFT_NUMSER"))
	 
		aArray := SldPorLote(oModelTFT:GetValue("TFT_PRODUT"),oModelTFT:GetValue("TFT_LOCAL"),oModelTFT:GetValue("TFT_QUANT"),NIL,oModelTFT:GetValue("TFT_LOTECT"),;
							oModelTFT:GetValue("TFT_NUMLOT"),oModelTFT:GetValue("TFT_LOCALI"),oModelTFT:GetValue("TFT_NUMSER"))
		For nX := 1 to Len(aArray)
			nQtd += aArray[nX, 5]
		Next nX
		
	Else
		dbSelectArea("SB2")
		dbSetOrder(1)	
		If (!DbSeek(xFilial("SB2")+oModelTFT:GetValue("TFT_PRODUT")+oModelTFT:GetValue("TFT_LOCAL")) )
			lRet := .F.
		Else
			nQtd := SaldoSB2()
		EndIf
	EndIf
					      
	If lRet .And. nQtd < oModelTFT:GetValue("TFT_QUANT") .And. Empty(oModelTFT:GetValue("TFT_NUMMOV"))
		lRet := .F.
		Help(,,STR0030,,STR0031,1,0)//"Saldo Insuficiente" #	"Saldo Insuficiente para realizar a movimenta��o com estas informa��es de estoque"
	EndIf

Endif

RestArea(aArea)
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890LnOKTFS

Valida campos referentes a estoque
no Modulo Estoque
@author  Servi�os
@since 	  31/10/13
@version P11 R9

@return lRet: Retorna .T. quando os campos estiverem ok.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At890LnOKTFS( oModelTFS )
Local aArray		:= {}
Local nX			:= 0
Local lRet			:= .T.
Local nQtd			:= 0
Local aArea		:= GetArea()
Local oModel	:= oModelTFS:GetModel()

If !Empty(oModelTFS:GetValue("TFS_PRODUT"))
	If	!Empty(oModelTFS:GetValue("TFS_LOTECT")) .OR.; 
		!Empty(oModelTFS:GetValue("TFS_NUMLOT")) .OR.;
		!Empty(oModelTFS:GetValue("TFS_LOCALI")) .OR.;
		!Empty(oModelTFS:GetValue("TFS_NUMSER"))
	 
		aArray := SldPorLote(oModelTFS:GetValue("TFS_PRODUT"),oModelTFS:GetValue("TFS_LOCAL"),oModelTFS:GetValue("TFS_QUANT"),NIL,oModelTFS:GetValue("TFS_LOTECT"),;
								oModelTFS:GetValue("TFS_NUMLOT"),oModelTFS:GetValue("TFS_LOCALI"),oModelTFS:GetValue("TFS_NUMSER"))
		For nX := 1 to Len(aArray)
			nQtd += aArray[nX, 5]
		Next nX
		
	Else
		dbSelectArea("SB2")
		dbSetOrder(1) // B2_FILIAL + B2_COD + B2_LOCAL	
		If (!DbSeek(xFilial("SB2")+oModelTFS:GetValue("TFS_PRODUT")+oModelTFS:GetValue("TFS_LOCAL")) )
			lRet := .F.
		Else
			nQtd := SaldoSB2()
		EndIf
	EndIf
					      
	If nQtd < oModelTFS:GetValue("TFS_QUANT") .And. Empty(oModelTFS:GetValue("TFS_NUMMOV"))
		lRet := .F.
		Help(,,STR0030,,STR0031,1,0)//"Saldo Insuficiente" #	"Saldo Insuficiente para realizar a movimenta��o com estas informa��es de estoque"
	EndIf
	
Endif

RestArea(aArea)
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890RetMi

Fun��o para retornar material de implanta��o do contrato 
no Modulo Estoque
@author  Servi�os
@since 	  17/08/15
@version P12

@return lRet: Retorna .T. quando os campos estiverem ok.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At890RtMip(cCodTFL,cConTrt,cCodGesMat,cCodGsMtMi,cCodGsMtMc,cIsGsMt)

Local aArea 	:= {}
Local oModel 	:= Nil
Local aArea 	:= GetArea()
Local lRet 		:= .F.
Local lGsMt	    := .F.

Default cConTrt 	:= ""
Default cCodGesMat := ""
Default cCodGsMtMi := ""
Default cCodGsMtMc := ""
Default cIsGsMt	   := ""

//Foi necessario abrir o SX3
DbSelectArea("SX3")
SX3->(DbSetOrder(1))

DbSelectArea("TFL")
TFL->(DbSetOrder(1))//TFL_FILIAL+TFL_CODIGO
If TFL->(DbSeek(xFilial("TFL")+cCodTFL))
	If TFL->TFL_ENCE <> "1"
		
		If cIsGsMt == "1"
			lGsMt := cCodGsMtMi $ '2|3'
		Else		
			lGsMt := cCodGesMat $ '2|3'
		Endif

		if lGsMt
			lRet := .F.
			Aviso(STR0033,STR0065, {STR0042}, 2) //"Aten��o","O Contrato/Or�amento escolhido utiliza apontamento por valor, onde n�o h� retorno"
		Else
			lRet := .T.
			FWExecView( STR0043, "VIEWDEF.TECA893", MODEL_OPERATION_UPDATE, /*oDlg*/, {||.T.} /*bCloseOk*/,	{||.T.}/*bOk*/,/*nReducao*/, /*aButtons*/, {||.T.}/*bCancel*/ ) //"Retorno Material de Implanta��o"		
		EndIf
	Elseif TFL->TFL_ENCE == "1" // local ja encerrado
		lRet := .F.
		Aviso( STR0033, STR0041, { STR0042 }, 2 )	//"Aten��o", "Local j� encerrado. N�o permitido gerar movimenta��o", { "OK" } 
	Endif
Endif	

RestArea(aArea)

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890VdSld

Fun��o Para fazer valida��o do Material
@author  Joni Lima
@since 	  19/08/16
@version P12

@param oMdlGrid, Objeto, FwFormGrid
@param cCampo  , Caractre, Campo 
@param xValue  , x       , Valor a ser validado
@param nLin    , numerico, Linha Posicionada
@param xOldValue, x      , Valor Anterior do Campo

@return lRet: Retorna .T. quando os campos estiverem ok.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At890VdSld(oMdlGrid,cCampo,xValue,nLin,xOldValue)
	Local aArea		:= GetArea()
	Local aSaveLines:= FWSaveRows()	
	Local oModel	:= oMdlGrid:GetModel()
	Local cTab		:= LEFT(cCampo,3)
	Local cCodField := cTab + '_COD' + IIF(cTab=='TFT','TFH','TFG')
	Local cSldField := cTab + '_SLDTTL'
	Local cProdut	:= ""
	Local cCodMat	:= ""	
	Local nX		:= 0
	Local lRet		:= .T.

	If ValType(oModel)=='O' .And. oModel:GetId()== 'TECA890'  .And. !IsInCallStack("TECA870")
		
		If cCampo == "TFS_CODTFG"
			lRet := ExistCpo("TFG")
		ElseIf cCampo == "TFT_CODTFH"
			lRet := ExistCpo("TFH")
		EndIf
		
		If lRet
		
			cCodMat := oMdlGrid:GetValue(cCampo)
			
			For nX := 1 To oMdlGrid:Length() 
				oMdlGrid:GoLine(nX)
				
				If  !oMdlGrid:IsDeleted() .and.;
					oMdlGrid:GetValue(cCodField) = cCodMat .and.;
					oMdlGrid:GetValue(cSldField) == 0 .and. nLin<>nX
					
					lRet := .F.
					
					oModel:GetModel():SetErrorMessage(oModel:GetId(),cCampo,oModel:GetModel():GetId(),cCampo,cCampo,; 
						STR0044, STR0045 ) //# 'Material n�o possui mais Saldo para apontamento' #'Verificar Material'  
				
				EndIf
			Next nX
			
			oMdlGrid:GoLine(nLin)//Volta para Linha 
			
		EndIf
	EndIf
	
	FWRestRows(aSaveLines)	
	RestArea(aArea)

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890TFHRetAr

Fun��o que executa query para trazer valores iniciais para tela
@author  Joni Lima
@since 	  19/08/16
@version P12

@param cCond  , Caractere, Codigo para filtro 

@return lRet: Retorna array contendo os dados para {COdigo,Saldo,Saldo}
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At890TFHRetAr(cCond)
	
	Local aArea := GetArea()
	Local aRet	:= {}
	
	Local cAlias := GetNextAlias()
	Local lOrcPrc := SuperGetMv("MV_ORCPRC",,.F.)
	
	If lOrcPrc //Or�amento com tabela de Precifica��o
		
		BeginSql Alias cAlias
			
			SELECT
			TFH_COD,
			TFH_QTDVEN
			
			FROM %table:TFL% TFL
			
			INNER JOIN %table:TFH% TFH
			ON TFH.TFH_FILIAL = %xFilial:TFH%
			AND TFH.TFH_CODPAI = TFL.TFL_CODIGO
			
			WHERE
			TFL.TFL_FILIAL = %xFilial:TFL% AND
			TFL.TFL_CODIGO = %Exp:cCond% AND
			TFL.%NotDel% AND
			TFH.%NotDel%
			
		EndSql
		
	Else //or�amento Sem tabela de Precifica��o
		
		BeginSql Alias cAlias
			
			SELECT
			TFH_COD,
			TFH_QTDVEN
			
			FROM %table:TFL% TFL
			
			INNER JOIN %table:TFF% TFF
			ON TFF.TFF_FILIAL = %xFilial:TFF%
			AND TFF.TFF_CODPAI = TFL.TFL_CODIGO
			
			INNER JOIN %table:TFH% TFH
			ON TFH.TFH_FILIAL = %xFilial:TFH%
			AND TFH.TFH_CODPAI = TFF.TFF_COD
			
			WHERE
			TFL.TFL_FILIAL = %xFilial:TFL% AND
			TFL.TFL_CODIGO = %Exp:cCond% AND
			TFF.TFF_ENCE <> '1' AND
			TFL.%NotDel% AND
			TFF.%NotDel% AND
			TFH.%NotDel%
			
		EndSql
	EndIf
	
	While !(cAlias)->(Eof())
		
		AADD(aRet,{(cAlias)->TFH_COD ,(cAlias)->TFH_QTDVEN})

		(cAlias)->(DbSkip())
		
	EndDo
	
	(cAlias)->(DbCloseArea())
	
	RestArea(aArea)
	
Return aRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890TFGRetAr

Fun��o que executa query para trazer valores iniciais para tela
@author  Joni Lima
@since 	  19/08/16
@version P12

@param cCond  , Caractere, Codigo para filtro 

@return lRet: Retorna array contendo os dados para {COdigo,Saldo,Saldo}
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At890TFGRetAr(cCond)
	
	Local aArea := GetArea()
	Local aRet	:= {}
	
	Local cAlias := GetNextAlias()
	Local lOrcPrc := SuperGetMv("MV_ORCPRC",,.F.)
	
	If lOrcPrc //Or�amento com tabela de Precifica��o
		
		BeginSql Alias cAlias
			
			SELECT
			TFG_COD,
			TFG_QTDVEN
			
			FROM %table:TFL% TFL
			
			INNER JOIN %table:TFG% TFG
			ON TFG.TFG_FILIAL = %xFilial:TFG%
			AND TFG.TFG_CODPAI = TFL.TFL_CODIGO
			
			WHERE
			TFL.TFL_FILIAL = %xFilial:TFL% AND
			TFL.TFL_CODIGO = %Exp:cCond% AND
			TFL.%NotDel% AND
			TFG.%NotDel%
			
		EndSql
		
	Else //or�amento Sem tabela de Precifica��o
		
		BeginSql Alias cAlias
			
			SELECT
			TFG_COD,
			TFG_QTDVEN
			
			FROM %table:TFL% TFL
			
			INNER JOIN %table:TFF% TFF
			ON TFF.TFF_FILIAL = %xFilial:TFF%
			AND TFF.TFF_CODPAI = TFL.TFL_CODIGO
			
			INNER JOIN %table:TFG% TFG
			ON TFG.TFG_FILIAL = %xFilial:TFG%
			AND TFG.TFG_CODPAI = TFF.TFF_COD
			
			WHERE
			TFL.TFL_FILIAL = %xFilial:TFL% AND
			TFL.TFL_CODIGO = %Exp:cCond% AND
			TFL.%NotDel% AND
			TFF.%NotDel% AND
			TFG.%NotDel%
			
		EndSql
	EndIf
	
	While !(cAlias)->(Eof())
		
		AADD(aRet,{(cAlias)->TFG_COD ,(cAlias)->TFG_QTDVEN})
		
		(cAlias)->(DbSkip())
		
	EndDo
	
	(cAlias)->(DbCloseArea())
	
	RestArea(aArea)
	
Return aRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890KitMat
Fun��o que verifica se o produto informado � um Kit de materiais. 
Caso seja um kit, a fun��o exibir� uma tela com todos os componentes do kit e solicitar� para o usu�rio informar a quantidade de kits que ser� apontada.
Na confirma��o da quantidade a ser apontada, essa rotina estar� encarregada de fazer a "explos�o" do kit, ou seja, alimentar� o grid apenas com os componentes do kit,
multiplicando a quantidade do kit pela quantidade de componentes por kit, para cada componente.

@author  Servi�os
@since 	  12/08/15
@param   cField, Caracter, Indica o campo que ser� utilizado pela fun��o.
@version P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At890KitMat(cField)
Local aArea      := GetArea()
Local cCodTWX    := ""
Local cCodPrd    := ""
Local lKit       := .F.
Local lRet        := .T.
Local cAliasGrid := SubStr(cField,1,3)
Local oModelMat   := FwModelActive()
Local nQtdKit     := 0
Local nExec       := 0
Local cCpoMat     := ""
Local nLinIni     := 0
Local aButtons    := {{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.T.,"Confirmar"},{.T.,"Fechar"},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil}} //"Confirmar"#####"Fechar"
Local oView       := FwViewActive()

If cAliasGrid == "TFS"
	cCpoMat   := "TFS_CODTFG"
	cCodTWX   := FwFldGet(cCpoMat)
	cCodPrd := Posicione("TFG",1,FwxFilial("TFG")+cCodTWX,"TFG_PRODUT")
	oModelMat := oModelMat:GetModel("TFSGRID")
	Else
	cCpoMat   := "TFT_CODTFH"
	cCodTWX   := FwFldGet(cCpoMat)
		cCodPrd := Posicione("TFH",1,FwxFilial("TFH")+cCodTWX,"TFH_PRODUT")
	oModelMat := oModelMat:GetModel("TFTGRID")	
	EndIf
	
	lKit := Posicione("SB1",1,FwxFilial("SB1")+cCodPrd,"B1_TIPO") == "KT"
	
	nLinIni := oModelMat:GetLine()

	If lKit

	At890CalcSldKit(oModelMat,cAliasGrid,cCodPrd)
	
	DbSelectArea("TWX")
	TWX->(DbSetOrder(1))		
	If TWX->(DbSeek(FwxFilial("TWX")+cCodPrd))
		nExec := FWExecView(STR0053,"VIEWDEF.TECA892", MODEL_OPERATION_UPDATE, /*oDlg*/, {||.T.} /*bCloseOk*/, {|oModel| At892Confirm(oModel,@nQtdKit) }/*bOk*/,30,aButtons, {||.T.}/*bCancel*/ ) //"Kit de Materiais"
		If nExec == 0
			lRet := At890KitExpl(cCodPrd,cAliasGrid,nQtdKit)
			lStKit := .T.
		Else 
			lRet := .F.
		EndIf
	Else
		Help(,,STR0048,,STR0049,1,0) //'Sele��o de Kit'###"O produto do tipo Kit n�o possui componentes cadastrados."
		lRet := .F.
	EndIf
	If !lRet
		/* 
			Caso o usu�rio feche a tela de sele��o de kits sem selecionar um kit,  ou caso o produto n�o tenha componentes cadastrados,
			zera os campos para n�o permitir que ele fa�a um apontamento incorreto.
		*/	
			oModelMat:GoLine(nLinIni)
			oModelMat:LoadValue(cCpoMat              ,"")
			oModelMat:LoadValue(cAliasGrid+"_DPROD"  ,"")
			oModelMat:LoadValue(cAliasGrid+"_PRODUT" ,"")
			oModelMat:LoadValue(cAliasGrid+"_SLDTTL" ,0 )
	EndIf
EndIf

//oModelMat:GoLine(1)
oView:Refresh()

nSaldoKit := 0	

RestArea(aArea)

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At892Confirm
Valida se os campos obrigat�rios foram preechidos e repassa as informa��es para a tela de apontamento de materiais.

@author   Servi�os
@since 	  12/08/15
@version  P12
@return   lRet: Retorna .T. quando os campos estiverem ok.
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At892Confirm(oModel,nQtdKit)
Local lRet := .T.

nQtdKit  := oModel:GetValue("TWXMASTER","TWX_QTDKIT")

If Empty(nQtdKit)
	Help(,,STR0048,,STR0050,1,0) //'Sele��o de Kit'###"Quantidade n�o preenchida!"
	lRet := .F.
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890KitExpl

@author  Servi�os
@since 	  12/08/15
@version P12
@return lRet: Retorna .T. quando os campos estiverem ok.
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At890KitExpl(cCodPrd, cAliasGrid, nQtdKit)
Local aRows    := FwSaveRows()
Local aArea    := GetArea()
Local oView    := FwViewActive()
Local oModel   := FwModelActive()
Local oGrid    := If(cAliasGrid == "TFS",oModel:GetModel("TFSGRID"),oModel:GetModel("TFTGRID"))
Local nLin     := oGrid:GetLine()
Local nCount   := nLin
Local nSaldo   := 0
Local cCodGrid := ""
Local lRet      := .T.
Local cCampoMat := ""
Local cSeqKit   := At890RetSeq(oGrid, cAliasGrid,cCodPrd)
Local cCampoComp := ""
Local nX			:= 0

If cAliasGrid == "TFS"
	cCampoMat   := "TFS_CODTFG"
	cCampoComp  := "B5_GSMI"
	cCodGrid := oGrid:GetValue("TFS_CODTFG")
Else
	cCampoMat   := "TFT_CODTFH"
	cCampoComp  := "B5_GSMC"
	cCodGrid := oGrid:GetValue("TFT_CODTFH")
EndIf

DbSelectArea("TWX")
TWX->(DbSetOrder(1)) //TWX_FILIAL+TWX_KITPRO+TWX_CODPRO
If TWX->(DbSeek(FwxFilial("TWX")+cCodPrd))
	lRet := At890ChkSaldo(cCodPrd, nQtdKit)  // Verifica se todos os componentes do Kit possuem saldo em estoque
	lRet := lRet .And. At890ChkComp(cCodPrd,cCampoComp) //Verifica se todos os componentes do KIT possuem complemento de produto.
	If lRet
		aObriga := At890CpoOb()// Retorna os campos obrigat�rios e os desabilita para o AddLine funcionar.
		While TWX->(!EoF()) .AND. TWX->(TWX_FILIAL+TWX_KITPRO) == FWxFilial("TWX")+cCodPrd
			If nCount <> nLin
				oGrid:AddLine()
			EndIf

			lRet := lRet .And. oGrid:SetValue(cCampoMat,cCodGrid)
			lRet := lRet .And. oGrid:SetValue(cAliasGrid+"_PRODUT",TWX->TWX_CODPRO)
			lRet := lRet .And. oGrid:SetValue(cAliasGrid+"_DPROD" ,Posicione("SB1",1,FwxFilial("SB1")+TWX->TWX_CODPRO,"B1_DESC"))
			lRet := lRet .And. oGrid:LoadValue(cAliasGrid+"_QUANT" ,nQtdKit *  TWX->TWX_QUANT)
			lRet := lRet .And. oGrid:SetValue(cAliasGrid+"_CODKIT",cCodPrd )
			lRet := lRet .And. oGrid:SetValue(cAliasGrid+"_QTDKIT",nQtdKit )
			lRet := lRet .And. oGrid:SetValue(cAliasGrid+"_LOCAL" ,Posicione("SB1",1,FwxFilial("SB1")+TWX->TWX_CODPRO,"B1_LOCPAD"))
			lRet := lRet .And. oGrid:SetValue(cAliasGrid+"_SEQKIT",cSeqKit )
			
			If !lRet
				ViewErroMvc( oModel, .T. )
				Exit
			EndIf
			
			nCount++
			TWX->(DbSkip())
		EndDo
		At890Obriga() // Restaura a obrigatoriedade dos itens.
		
		//Apaga todas as linhas anteriores
		If !lRet
			For nX := nCount To nLin Step -1
				oGrid:GoLine(nX)
				oGrid:DeleteLine()
			Next nX
		EndIf
		
		oGrid:GoLine(nLin)
	Else
		/* 
			Caso algum componente do produto kit n�o tenha saldo, zera os campos
		*/	
		oGrid:GoLine(nLin)
		oGrid:LoadValue(cCampoMat            ,"")
		oGrid:LoadValue(cAliasGrid+"_DPROD"  ,"")
		oGrid:LoadValue(cAliasGrid+"_PRODUT" ,"")
		oGrid:LoadValue(cAliasGrid+"_SLDTTL" ,0 )
	EndIf
EndIf

If lRet
	AtSldKitComp(oGrid, cAliasGrid, cCodPrd ) // Corrige os saldos dos componentes do kit.
EndIf

//oGrid:GoLine(nLin)
oView:Refresh()

FwRestRows( aRows )
RestArea( aArea )

Return lRet

/*/{Protheus.doc}  At890RetSeq
Retorna a sequencia de apontamento a ser gravada quando o produto for um kit.

@author  Servi�os
@since 	  12/08/15
@version P12
@return cRet: Retorna string com a sequ�ncia de apontamento de um kit de materiais.
/*/
Static Function At890RetSeq(oGrid, cAliasGrid, cCodPrd)
Local aRows   := FwSaveRows()
Local nLinIni := oGrid:GetLine()
Local cRet    := "000"
Local nX      := ""

For nX := 1 To oGrid:Length()
	oGrid:GoLine(nX)
	If oGrid:GetValue(cAliasGrid+"_CODKIT") == cCodPrd .AND. oGrid:GetValue(cAliasGrid+"_SEQKIT") > cRet
		cRet := oGrid:GetValue(cAliasGrid+"_SEQKIT")
	EndIf
Next nX

cRet := Soma1(cRet,,,.F.)

oGrid:GoLine(nLinIni)

FwRestRows( aRows )

Return cRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890ChkSaldo
Verifica se todos os componentes do kit de materiais possuem saldo em estoque.

@author   Leandro Dourado - Totvs Ibirapuera
@since 	  12/08/15
@version P12
@return lRet: Retorna .T. quando os campos estiverem ok.
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At890ChkSaldo(cCodKit, nQtdKit)
Local aArea    := GetArea()
Local lRet     := .T.
Local aPrds    := {}
Local cProduto := ""
Local cLocal   := ""
Local cMsgHelp := ""
Local nX       := 0

DbSelectArea("SB1")
SB1->(DbSetOrder(1))

DbSelectArea("SB2")
SB2->(DbSetOrder(1))

While TWX->(!EoF()) .AND. TWX->(TWX_FILIAL+TWX_KITPRO) == FWxFilial("TWX")+cCodKit
	
	cProduto := TWX->TWX_CODPRO
	
	If SB1->( DbSeek( xFilial( "SB1" ) + cProduto ) )
		cLocal := SB1->B1_LOCPAD
	
		If SB2->( DbSeek( xFilial( "SB2" ) + cProduto + cLocal ) )
			If SaldoSB2() < (nQtdKit * TWX->TWX_QUANT)
				Aadd(aPrds,AllTrim(cProduto) + ' - '+ AllTrim(Posicione("SB1",1,FwxFilial("SB1")+cProduto,"B1_DESC")))
				lRet := .F.
			Endif
		Else
			Aadd(aPrds,AllTrim(cProduto) + ' - '+ AllTrim(Posicione("SB1",1,FwxFilial("SB1")+cProduto,"B1_DESC")))
			lRet := .F.
		Endif
	Endif
	TWX->(DbSkip())
EndDo

If !lRet
	cMsgHelp := STR0060 //"O(s) componente(s) abaixo n�o possui(em) saldo em estoque:"
	
	For nX := 1 To Len(aPrds)
		cMsgHelp += CRLF + aPrds[nX]
	Next nX
	
	cMsgHelp += CRLF + CRLF + STR0061 //"N�o ser� poss�vel fazer o apontamento desse kit!"
	
	Help(,,'Help',,cMsgHelp,1,0)
EndIf

RestArea( aArea )

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At890Obriga
Fun��o para tornar os campos obrigat�rios novamente, ap�s a fun��o At890CpoOb() retirar a obrigatoriedade.

@author  Leandro Dourado - Totvs Ibirapuera
@since 29/06/2016
@version P12
/*/
//-------------------------------------------------------------------
Function At890Obriga()
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

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} At890CpoOb
Fun��o respons�vel por pegar os campos obrigat�rios de determinados modelos da rotina e retirar o obrigat�rio deles por conta da "explos�o" do kit de materiais.

@author  Leandro Dourado - Totvs Ibirapuera
@since 07/06/2016
@version P12
/*/
//-------------------------------------------------------------------
Function At890CpoOb()
Local oModel := FwModelActive()
Local cRet	 := ""
Local aCpos	 := {{"TFSGRID",{}},{"TFTGRID",{}}}
Local nX	 := 0
Local nY	 := 0
Local nPos   := 0

For nX := 1 to Len(oModel:GetAllSubModels())
	If  oModel:GetAllSubModels()[nX]:CID $ "TFSGRID|TFTGRID"
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

Return aCpos

//-------------------------------------------------------------------
/*/{Protheus.doc} At890IsKitCmp
Verifica se o grid est� posicionado em uma linha na qual o produto � um componente de um kit de materiais.

@author  Leandro Dourado - Totvs Ibirapuera
@since 07/06/2016
@version P12
/*/
//-------------------------------------------------------------------
Function At890IsKitCmp(cAliasMat,lChkInsert)
Local oModel     := FwModelActive()
Local oGrid      := oModel:GetModel(cAliasMat+"GRID")
Local lInserted  := .T.
Local lRet       := .T.

Default lChkInsert := .F.

If lChkInsert
	lInserted := Empty(oGrid:GetValue(cAliasMat+"_NUMMOV"))
EndIf

If !Empty(oGrid:GetValue(cAliasMat+"_CODKIT")) .And. !IsInCallStack("copyapont")
	lRet := .F.
	
	If lChkInsert .AND. lInserted
	// Caso o produto posicionado seja um componente de kit rec�m inclu�do (com o n�mero da movimenta��o do D3 em branco), alguns campos podem ser alterados.
		lRet := .T.
	EndIf
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At890CalcSldKit
Retorna o saldo do kit de materiais para a tela com os detalhes do kit de materiais.

@author  Leandro Dourado - Totvs Ibirapuera
@since   07/06/2016
@version P12
/*/
//-------------------------------------------------------------------
Static Function At890CalcSldKit(oModelMat,cAliasMat,cCodKit)
Local aRows     := FwSaveRows()
Local nX        := 0
Local aKit      := {}
Local cKit      := ""
Local nQtdVen   := 0
Local cCodApo	:= "" 
Local cCodMat	:= ""

DEFAULT cCodKit := ""

If cAliasMat == "TFS"
	nQtdVen := TFG->TFG_QTDVEN
	cCodApo := TFG->TFG_COD
	cCodMat := "TFS_CODTFG"
Else
	nQtdVen := TFH->TFH_QTDVEN
	cCodApo := TFH->TFH_COD
	cCodMat := "TFT_CODTFH"
EndIf

nSaldoKit := nQtdVen

For nX := 1 To oModelMat:Length()
	oModelMat:GoLine(nX)
	If !oModelMat:IsDeleted() .AND. AllTrim(cCodKit) == AllTrim(oModelMat:GetValue(cAliasMat+"_CODKIT")) .And. AllTrim(oModelMat:GetValue(cCodMat)) == cCodApo
		cKit := oModelMat:GetValue(cAliasMat+"_CODKIT") + oModelMat:GetValue(cAliasMat+"_SEQKIT")
		If aScan(aKit,cKit) == 0
			Aadd(aKit,cKit)
			nSaldoKit -= oModelMat:GetValue(cAliasMat+"_QTDKIT")
		EndIf
	EndIf
Next nX

FwRestRows( aRows )

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} At890SldKit
Retorna o saldo do kit de materiais para a tela com os detalhes do kit de materiais.

@author Leandro Dourado - Totvs Ibirapuera
@since 07/06/2016
@version P12
/*/
//-------------------------------------------------------------------
Function At890SldKit()
Return nSaldoKit

/*/{Protheus.doc} At890F4
Fun��o atribu�da � tecla de atalho F4. 
	
@author 	Leandro Dourado - Totvs Ibirapuera
@since		04/11/2016
@version	P12.1.14
/*/
Static Function At890F4()
Local aArea       := GetArea()
Local aAreaSB1    := SB1->(GetArea())
Local oView       := FwViewActive()
Local aFolderMat  := oView:GetFolderActive("PASTA",2)
Local cCodProd    := ""
Local oModelMat   := Nil
Local cFilBkp     := cFilAnt

If     aFolderMat[1] == 1 // Material de Implanta��o
	oModelMat := oView:GetModel("TFSGRID")
	cCodProd  := oModelMat:GetValue("TFS_PRODUT")
ElseIf aFolderMat[1] == 2 // Material de Consumo
	oModelMat := oView:GetModel("TFTGRID")
	cCodProd  := oModelMat:GetValue("TFT_PRODUT")
EndIf

If !Empty(cCodProd)

	DbSelectArea("SB1")
	SB1->(DbSetOrder())
	SB1->(DbSeek(FwxFilial("SB1")+cCodProd))
	
	
	Set Key VK_F4 TO
	If FWModeAccess("SB1")=="E"
		cFilAnt := SB1->B1_FILIAL
	EndIf	
	MaViewSB2(SB1->B1_COD)
	cFilAnt := cFilBkp
	
EndIf

Set Key VK_F4 TO At890F4()

RestArea( aAreaSB1 )
RestArea( aArea )

Return

/*/{Protheus.doc} Refresh
Atualiza browse
@author Rodolfo Novaes
@since 01/02/2017
@version 1.0
@param oBrowse, objeto, (Descri��o do par�metro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function Refresh(oBrowse,cAliasPro)
	Local aInfoColumn := {}
	Local cQuery   	  := ""
	
	aInfoColumn :=  At890Cols(cAliasPro)
	cQuery   	:=  At890Query()
		
	oBrowse:SetQuery(cQuery)
	oBrowse:SetColumns(aInfoColumn)
	
	oBrowse:Refresh( .T. )
	oBrowse:ExecuteFilter()

Return


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  AT890VldTWY
Valida campos referentes a itens intercambiaveis
no Modulo Gest�o Servi�os
@author  Servi�os
@since 	  05/09/2016
@version P12
@return lRet: Retorna .T. quando os campos estiverem ok.
/*/
//--------------------------------------------------------------------------------------------------------------------

Function AT890VldTWY(cCodProd)
	
	Local lRet			:= .T.
	Local aAreaTWY	:= TWY->(GetArea())
	
	DbSelectArea("TWY")
	TWY->(DbSetOrder(1))
	
	If !TWY->(DbSeek(FwxFilial("TWY") + cCodProd)) 
		If IsInCallStack("TECA890")
			lRet	:= .F.
		EndIf	
	Else
		If TWY->TWY_ATIVO != "1"
			lRet	:= .F.
			Help( , , 'TWY_ATIVO', , STR0115, 1, 0, NIL, NIL, NIL, NIL, NIL, {STR0116})//"O Produto intercambi�vel n�o est� ativo"##"Selecione outro produto"
		Endif
	Endif
	
	RestArea(aAreaTWY)
	
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890PrdPad
Seleciona o produto princ�pal.
@author  Servi�os
@since 	  10/08/2017
@version P12
@return lRet: Retorna .T. quando os campos estiverem ok.
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At890PrdPad(cCod,cTab, cProdAtu)

	Local aArea    := GetArea()
	Local aAreaTFG := TFG->(GetArea())
	local aAreaTFH := TFH->(GetArea())
	Local aAreaTWX := TWX->(GetArea())
	Local aAreaTWY := TWY->(GetArea())
	Local cProdKit := ""
	Local cRet     := ''
	
	Default cTab := ''
	
	If !Empty(cTab)
		
		If cTab == 'TFS'
			
			dbSelectArea('TFG')
			TFG->(DbSetOrder(1)) //TFG_FILIAL + TFG_COD
			
			If (TFG->(dbSeek(xFilial('TFG') + cCod)))
				cRet := TFG->TFG_PRODUT					
			EndIf
		
		ElseIf cTab == 'TFT'

			dbSelectArea('TFH')
			TFH->(DbSetOrder(1)) //TFH_FILIAL + TFH_COD
			
			If (TFH->(dbSeek(xFilial('TFH') + cCod)))
				cRet := TFH->TFH_PRODUT					
			EndIf
		
		EndIf
		
		// Avalia se o produto � um Kit de Materiais
		TWX->( DbSetOrder( 1 ) ) // TWX_FILIAL+TWX_KITPRO+TWX_CODPRO
		If TWX->( DbSeek( xFilial("TWX")+cRet ) )
			// Recupera o produto principal de um kit com intercambi�veis
			cRet := At890KtPrd( cRet, cProdAtu )
		EndIf
	EndIf
	
	RestArea(aAreaTWX)
	RestArea(aAreaTFH)
	RestArea(aAreaTFG)
	RestArea(aArea)
	
Return cRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890ConsTWY
Monta tela de consulta padr�o com dados da TWY
no Modulo Gest�o Servi�os
@author  Servi�os
@since 	  05/09/2016
@version P12
@return lRet: Retorna .T. quando os campos estiverem ok.
/*/
//--------------------------------------------------------------------------------------------------------------------

Function At890ConsTWY()
Local lRet			:= .T.
Local aCmpBco		:= {}
Local cQuery		:= ""
Local cDscCmp		:= ""
Local cConteudo	:= ""
Local cEntida		:= ""
Local cLocal		:= ""
Local cCdPrdTWY	:= ""
Local lOk			:= .F.
Local cPesq			:= Space(TamSX3("TFS_PRODUT")[1])
Local oPesqui		:= Nil //Objeto Pesquisa
Local oModel        := Nil //Modelo atual
Local oDlgCmp       := Nil //Dialog
Local oPanel        := Nil //Objeto Panel
Local oFooter       := Nil //Rodap�
Local oListBox      := Nil //Grid campos
Local oOk           := Nil //Objeto Confirma
Local oCancel       := Nil //Objeto Cancel
Local aSaveLines	:= {}
	
	aCmpBco := At890RtTWY()
	
	If !Empty(aCmpBco)
		
		//    Cria a tela para a pesquisa dos campos e define a area a ser utilizada na tela
		Define MsDialog oDlgCmp FROM 000, 000 To 350, 550 Pixel
		
	//Cria o Panel de pesquisa
	@ 000, 000 MsPanel oPesqui Of oDlgCmp Size 000, 012 // Coordenada para o panel
	oPesqui:Align   := CONTROL_ALIGN_TOP //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
	      
	@ 02,00 SAY STR0058 SIZE 70,10 PIXEL OF oPesqui//"Cod. Prod. Imp: "
	      
	@ 001,075 GET oPesqui VAR cPesq SIZE 30,03 OF oDlgCmp PIXEL
	            
	@ 001,247 BUTTON STR0055 SIZE 30,10 ACTION {|| At890Find(cPesq, oListBox, 2) } OF oDlgCmp PIXEL //"Pesquisar"
		
		// Cria o panel principal
		@ 000, 000 MsPanel oPanel Of oDlgCmp Size 250, 340 // Coordenada para o panel
		oPanel:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
		
		// Cria��o do grid para o panel
		oListBox := TWBrowse():New( 40,05,204,100,,{STR0005,STR0006,STR0007},,oPanel,,,,,,,,,,,,.F.,,.T.,,.F.,,,) //"C�digo"###"Produto"###"Desc Produto"
		oListBox:SetArray(aCmpBco) // Atrela os dados do grid com a matriz
		oListBox:bLine := { ||{aCmpBco[oListBox:nAT][1], aCmpBco[oListBox:nAT][2], aCmpBco[oListBox:nAT][3]}} // Indica as linhas do grid
		oListBox:bLDblClick := { ||Eval(oOk:bAction), oDlgCmp:End()} // Duplo clique executa a a��o do objeto indicado
		oListBox:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do browse
		
		// Cria o panel para os botoes
		@ 000, 000 MsPanel oFooter Of oDlgCmp Size 000, 010 // Corrdenada para o panel dos botoes (size)
		oFooter:Align   := CONTROL_ALIGN_BOTTOM //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
		
		// Botoes para o grid auxiliar
		@ 000, 000 Button oCancel Prompt STR0008  Of oFooter Size 030, 000 Pixel //"Cancelar"
		oCancel:bAction := { || lOk := .F., oDlgCmp:End() }
		oCancel:Align   := CONTROL_ALIGN_RIGHT
		
		@ 000, 000 Button oOk     Prompt STR0009 Of oFooter Size 030, 000 Pixel //"Confirmar"
		oOk:bAction     := { || lOk := .T.,cCdPrdTWY:=aCmpBco[oListBox:nAT][2],oDlgCmp:End() } // Acao ao clicar no botao
		oOk:Align       := CONTROL_ALIGN_RIGHT // Alinhamento do botao referente ao panel
		cCdPrdTWY:= aCmpBco[oListBox:nAT][2]
		// Ativa a tela exibindo conforme a coordenada
		Activate MsDialog oDlgCmp Centered
		
		//Utilizar o modelo ativo para substituir os valores das variaves de memoria
		oModel      := FWModelActive()

		If lOk
			lRet := .T. 
	    	oModel:SetValue("TFSGRID","TFS_PRODUT", cCdPrdTWY)	    	
		EndIf
		
	Else
		Help( ,, 'Help',, STR0010, 1, 0 )//"N�o h� Materiais de Consumo para este Local de Atendimento"
	EndIf
	
Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890RtTWY
Monta array com dados da TWY
no Modulo Gest�o Servi�os
@author  Servi�os
@since 	  05/09/2016
@version P12
@return lRet: Retorna .T. quando os campos estiverem ok.
/*/
//--------------------------------------------------------------------------------------------------------------------

Static Function At890RtTWY()
	
	Local aRet       	:= {}
	Local aAreaTWY		:= TWY->(GetArea())
	Local oModel 		:= FwModelActive()
	Local oMdlTFS		:= oModel:GetModel('TFSGRID')
	Local cCond 		:= oMdlTFS:GetValue('TFS_CODTFG')//&(READVAR())//FwFldGet("TFS_CODTFG")
	Local cProdPdr		:= At890PrdPad( cCond, 'TFS', oMdlTFS:GetValue('TFS_PRODUT') )
	
	DbSelectArea("TWY")
	DbsetOrder(1)
	If TWY->(DbSeek(FwxFilial("TWY") + cProdPdr ))
		While TWY->(!Eof()) .And. Alltrim(TWY->TWY_CODPRO) == Alltrim(cProdPdr)
			If TWY->TWY_ATIVO == "1"
				aAdd(aRet,{TWY->TWY_CODPRO, TWY->TWY_CODINT, Posicione("SB1", 1, xFilial("SB1") + TWY->TWY_CODINT, "B1_DESC")})
				TWY->(DbSkip())
			Endif
		EndDo
	Endif
	RestArea(aAreaTWY)
Return(aRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890RetII
Retorna informa��o para campo TFS_PRODUT
no Modulo Gest�o Servi�os
@author  Servi�os
@since 	  05/09/2016
@version P12
@return lRet: Retorna .T. quando os campos estiverem ok.
/*/
//--------------------------------------------------------------------------------------------------------------------

Function At890RetII()
Return (FwFldGet("TFS_PRODUT"))

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890TWYTFT
Monta tela de consulta padr�o com dados da TWY
no Modulo Gest�o Servi�os
@author  Servi�os
@since 	  05/09/2016
@version P12
@return lRet: Retorna .T. quando os campos estiverem ok.
/*/
//--------------------------------------------------------------------------------------------------------------------

Function At890TWYTFT()
	
Local lRet			:= .T.
Local aCmpBco		:= {}
Local cQuery		:= ""
Local cDscCmp		:= ""
Local cConteudo	:= ""
Local cEntida		:= ""
Local cLocal		:= ""
Local cCdPrdTWY	:= ""
Local lOk			:= .F.
Local cPesq			:= Space(TamSX3("TFT_PRODUT")[1])
Local oPesqui		:= Nil //Objeto Pesquisa
Local oModel        := Nil //Modelo atual
Local oDlgCmp       := Nil //Dialog
Local oPanel        := Nil //Objeto Panel
Local oFooter       := Nil //Rodap�
Local oListBox      := Nil //Grid campos
Local oOk           := Nil //Objeto Confirma
Local oCancel       := Nil //Objeto Cancel
Local aSaveLines	:= {}
	
	aCmpBco := At890TWYRet()
	
	If !Empty(aCmpBco)
		
		//    Cria a tela para a pesquisa dos campos e define a area a ser utilizada na tela
		Define MsDialog oDlgCmp FROM 000, 000 To 350, 550 Pixel
		
	//Cria o Panel de pesquisa
	@ 000, 000 MsPanel oPesqui Of oDlgCmp Size 000, 012 // Coordenada para o panel
	oPesqui:Align   := CONTROL_ALIGN_TOP //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
	      
	@ 02,00 SAY STR0059 SIZE 70,10 PIXEL OF oPesqui//"Cod. Prod. Cons: "
	      
	@ 001,065 GET oPesqui VAR cPesq SIZE 25,03 OF oDlgCmp PIXEL
	            
	@ 001,247 BUTTON STR0055 SIZE 30,10 ACTION {|| At890Find(cPesq, oListBox, 2) } OF oDlgCmp PIXEL //"Pesquisar"	
	
	
		// Cria o panel principal
		@ 000, 000 MsPanel oPanel Of oDlgCmp Size 250, 340 // Coordenada para o panel
		oPanel:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
		
		// Cria��o do grid para o panel
		oListBox := TWBrowse():New( 40,05,204,100,,{STR0005,STR0006,STR0007},,oPanel,,,,,,,,,,,,.F.,,.T.,,.F.,,,) //"C�digo"###"Produto"###"Desc Produto"
		oListBox:SetArray(aCmpBco) // Atrela os dados do grid com a matriz
		oListBox:bLine := { ||{aCmpBco[oListBox:nAT][1], aCmpBco[oListBox:nAT][2], aCmpBco[oListBox:nAT][3]}} // Indica as linhas do grid
		oListBox:bLDblClick := { ||Eval(oOk:bAction), oDlgCmp:End()} // Duplo clique executa a a��o do objeto indicado
		oListBox:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do browse
		
		// Cria o panel para os botoes
		@ 000, 000 MsPanel oFooter Of oDlgCmp Size 000, 010 // Corrdenada para o panel dos botoes (size)
		oFooter:Align   := CONTROL_ALIGN_BOTTOM //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
		
		// Botoes para o grid auxiliar
		@ 000, 000 Button oCancel Prompt STR0008  Of oFooter Size 030, 000 Pixel //"Cancelar"
		oCancel:bAction := { || lOk := .F., oDlgCmp:End() }
		oCancel:Align   := CONTROL_ALIGN_RIGHT
		
		@ 000, 000 Button oOk     Prompt STR0009 Of oFooter Size 030, 000 Pixel //"Confirmar"
		oOk:bAction     := { || lOk := .T.,cCdPrdTWY:=aCmpBco[oListBox:nAT][2],oDlgCmp:End() } // Acao ao clicar no botao
		oOk:Align       := CONTROL_ALIGN_RIGHT // Alinhamento do botao referente ao panel
		cCdPrdTWY:= aCmpBco[oListBox:nAT][2]
		// Ativa a tela exibindo conforme a coordenada
		Activate MsDialog oDlgCmp Centered
		
		//Utilizar o modelo ativo para substituir os valores das variaves de memoria
		oModel      := FWModelActive()
		
		If lOk
			aSaveLines	:= FWSaveRows()
			oModel:LoadValue("TFTGRID","TFT_PRODUT", cCdPrdTWY)
			oModel:LoadValue("TFTGRID","TFT_DPROD", Alltrim(Posicione("SB1", 1, FwxFilial("SB1") + Alltrim(cCdPrdTWY), "B1_DESC" )))
			FwRestRows( aSaveLines )
		EndIf
	Else
		Help( ,, 'Help',, STR0010, 1, 0 )//"N�o h� Materiais de Consumo para este Local de Atendimento"
	EndIf
	
Return(lRet)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890TWYTFT
Monta array com dados da TWY
no Modulo Gest�o Servi�os
@author  Servi�os
@since 	  05/09/2016
@version P12
@return lRet: Retorna .T. quando os campos estiverem ok.
/*/
//--------------------------------------------------------------------------------------------------------------------

Static Function At890TWYRet()
	
	Local aRet      := {}
	Local aAreaTWY	:= TWY->(GetArea())
	Local aArea		:= GetArea()
	Local oModel 		:= FwModelActive()
	Local oMdlTFT		:= oModel:GetModel('TFTGRID')
	Local cCond 		:= oMdlTFT:GetValue('TFT_CODTFH')
	Local cProdPdr		:= At890PrdPad( cCond, 'TFT', oMdlTFT:GetValue('TFT_PRODUT') )
	
	DbSelectArea("TWY")
	TWY->(DbsetOrder(1))
	
	If TWY->(DbSeek(FwxFilial("TWY") + cProdPdr ))
		While TWY->(!Eof()) .And. Alltrim(TWY->TWY_CODPRO) == Alltrim(cProdPdr)
			If TWY->TWY_ATIVO == "1"
				aAdd(aRet,{TWY->TWY_CODPRO, TWY->TWY_CODINT, Posicione("SB1", 1, xFilial("SB1") + TWY->TWY_CODINT, "B1_DESC")})
				TWY->(DbSkip())
			Endif
		EndDo
	Endif
	RestArea(aArea)
	RestArea(aAreaTWY)
Return(aRet)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890RtTFT
Retorna informa��o para campo TFS_PRODUT
no Modulo Gest�o Servi�os
@author  Servi�os
@since 	  05/09/2016
@version P12
@return lRet: Retorna .T. quando os campos estiverem ok.
/*/
//--------------------------------------------------------------------------------------------------------------------

Function At890RtTFT()
	Local oModel	:= FWModelActive()
Local oView		:= FwViewActive()

If ValType(oView) == "O"
	oView:Refresh()
Endif

Return (oModel:GetValue( 'TFTGRID', 'TFT_PRODUT' ))

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890Find
Posiciona no registro das consultas especificas do apontamento de materiais
@author  Servi�os
@param cPesq	, Caracter	, conteudo do Get de pesquisa
@param oListBox	, objeto	, Grid com os produtos 
@param nOpc		, num�rico	, Valor quando � a consulta dos c�digos ou produtos 
@since 	  15/12/2016
@version P12
@return nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At890Find(cPesq, oListBox, nOpc)
Local nPos := 0

If !Empty(cPesq)
	If nOpc == 1
		nPos := ASCAN(oListBox:aArray,{|x| alltrim(x[1]) == alltrim(cPesq)})
	ElseIf nOpc == 2
		nPos := ASCAN(oListBox:aArray,{|x| alltrim(x[2]) == alltrim(cPesq)})
	EndIf
	
	If nPos <> 0 
		oListBox:GoPosition(nPos)
		oListBox:Refresh()
	EndIf
EndIf

Return

/*/{Protheus.doc}  At890IsVld
@description Avalia se o produto pode ser utilizado no apontamento do material.
@author  	josimar.assuncao
@since 	  	10.07.2017
@version 	P12
@param 		oMdlGrid, Objeto FwFormModelGrid, modelo do grid em valida��o do campo de produto.
@param 		cCampo, caracter, campo do produto em valida��o (TFS_PRODUT ou TFT_PRODUT).
@param 		cConteudo, caracter, valor sendo validado no campo.
@param 		nLinha, num�rico, indica a linha que est� tendo o campo validado.
@return 	L�gico, indica se o conte�do � valido ou n�o para o campo.
/*/
Function At890IsVld( oMdlGrid, cCampo, cConteudo, nLinha)
Local lRet 			:= .T.
Local oModel 		:= oMdlGrid:GetModel()
Local cCodPrd 		:= ""
Local cItemApt 		:= ""
Local lIsIntercam 	:= .F.
Local lIsKitMat 		:= .F.
Local lIsKitInter		:= .F.
Local aPeriod			:= {}	//Array com as informa��es do produto com periodicidade

If oMdlGrid:GetId() == "TFSGRID"
	cItemApt 	:= oMdlGrid:GetValue("TFS_CODTFG")
	aPeriod	:= At890Peri(cItemApt,"TFG")
	cCodPrd 	:= aPeriod[1][1] //Aray deve retornar somente 1 posi��o
	
	// S� continua a valida��o se os c�digos de produtos forem diferentes
	If cCodPrd <> cConteudo
		
		// Verifica se o SB5 est� configurado para Material de Implanta��o
		If ( Posicione("SB5", 1, xFilial("SB5")+cConteudo, "B5_GSMI" ) == "1" )
			
			// Verifica se o produto est� configurado em itens intercambi�veis
			// ou se o produto � formado atrav�s de kit
			// ou se � um kit com produtos intercabi�veis.
			lIsIntercam := At890IsInt( cCodPrd, cConteudo )
			lIsKitMat 	:= At890IsKt( cCodPrd, cConteudo )
			lIsKitInter	:= !Empty( At890KtPrd ( cCodPrd, cConteudo ) )
			
			// Quando n�o � intercambi�vel nem kit e nem kit com intercabi�vel, o c�digo do produto est� errado
			If !lIsIntercam .And. !lIsKitMat .And. !lIsKitInter
				lRet := .F.
				oModel:SetErrorMessage( oMdlGrid:GetId(), cCampo, oModel:GetModel():GetId(), cCampo, cConteudo,; 
							STR0066, STR0067 ) // "O produto n�o � v�lido para apontamento." ### "Um produto diferente do or�amento s� pode ser apontado quando for intercambi�vel ou perten�a a um kit de materiais."
			EndIf
		Else
			lRet := .F.
			oModel:SetErrorMessage( oMdlGrid:GetId(), cCampo, oModel:GetModel():GetId(), cCampo, cConteudo,; 
							STR0068, STR0069 )  // "O produto n�o � um material de implanta��o." ### "Insira um produto que seja material de implanta��o no complemento de produtos."
		EndIf		
	EndIf
	
	//Verifica se o produto tem periodicidade
	If aPeriod[1][2] == "1"
		lPeriod := .T.
		oMdlGrid:LoadValue("TFS_PERIOD","1")
		//Verifica se esse produto j� possui apontamento e se est� dentro do periodo
		If !At890ApTFS(cItemApt,cCodPrd,aPeriod[1][3],"TFS") .And. !IsInCallStack("At890ConMI")
			lRet := .F.
			If MsgYesNo(STR0114) //"O produto possui periodicidade e n�o pode ser apontado, Deseja continuar mesmo assim?"
				lRet := .T.
				oMdlGrid:LoadValue("TFS_PEND","S")
				lAprov := .T.
			EndIf
			
		EndIf
	EndIf	
	
ElseIf oMdlGrid:GetId() == "TFTGRID"
	cItemApt := oMdlGrid:GetValue("TFT_CODTFH")
	aPeriod	:= At890Peri(cItemApt,"TFH")
	cCodPrd 	:= aPeriod[1][1] //Aray deve retornar somente 1 posi��o
	
	// S� continua a valida��o se os c�digos de produtos forem diferentes
	If cCodPrd <> cConteudo
		
		// Verifica se o SB5 est� configurado para Material de Consumo
		If ( Posicione("SB5", 1, xFilial("SB5")+cConteudo, "B5_GSMC" ) == "1" )
			
			// Verifica se o produto est� configurado em itens intercambi�veis
			// ou se o produto � formado atrav�s de kit
			lIsIntercam := At890IsInt( cCodPrd, cConteudo )
			lIsKitMat 	:= At890IsKt( cCodPrd, cConteudo )
			lIsKitInter	:= !Empty( At890KtPrd ( cCodPrd, cConteudo ) )

			// Quando n�o � intercambi�vel nem kit, o c�digo do produto est� errado
			If !lIsIntercam .And. !lIsKitMat .And. !lIsKitInter
				lRet := .F.
				oModel:SetErrorMessage( oMdlGrid:GetId(), cCampo, oModel:GetModel():GetId(), cCampo, cConteudo,; 
							STR0066, STR0067 ) // "O produto n�o � v�lido para apontamento." ### "Um produto diferente do or�amento s� pode ser apontado quando for intercambi�vel ou perten�a a um kit de materiais."
			EndIf
		Else
			lRet := .F.
			oModel:SetErrorMessage( oMdlGrid:GetId(), cCampo, oModel:GetModel():GetId(), cCampo, cConteudo,; 
							STR0070, STR0071 ) // "O produto n�o � um material de consumo." ### "Insira um produto que seja material de consumo no complemento de produtos."
		EndIf
	
	EndIf
	
	//Verifica se o produto tem periodicidade
	If aPeriod[1][2] == "1"
		lPeriod := .T.
		oMdlGrid:LoadValue("TFT_PERIOD","1")
		//Verifica se esse produto j� possui apontamento e se est� dentro do periodo
		If !At890ApTFS(cItemApt,cCodPrd,aPeriod[1][3],"TFT") .And. !IsInCallStack("At890ConsMC")
			lRet := .F.
			If MsgYesNo(STR0114) //"O produto possui periodicidade e n�o pode ser apontado, Deseja continuar mesmo assim?"
				lRet := .T.
				oMdlGrid:LoadValue("TFT_PEND","S")
				lAprov := .T.
			EndIf
			
		EndIf
	EndIf	
	
Else
	lRet := .F.
	oModel:SetErrorMessage( oMdlGrid:GetId(), cCampo, oModel:GetModel():GetId(), cCampo, cConteudo,; 
					STR0072, STR0073 )  // "Grid n�o identificado para a valida��o" ### "O grid precisa ser TFSGRID ou TFTGRID."
EndIf

Return lRet

/*/{Protheus.doc}  At890IsInt
@description Identifica se 2 produtos s�o pai e item em uma estrutura de itens intercambi�veis
@author  	josimar.assuncao
@since 	  	10.07.2017
@version 	P12
@param 		cProdPai, caracter, c�digo do produto mestre do cadastro de intercambi�veis.
@param 		cProdItem, caracter, c�digo do produto item do cadastro de intercambi�veis.
@return 	L�gico, determina se uma combina��o de produtos est� dentro do cadastro de produtos intercambi�veis.
/*/
Function At890IsInt( cProdPai, cProdItem )
Local lRet := .F.
Local cQryIntercamb := ""

If !Empty(cProdPai) .And. !Empty(cProdItem)

	cQryIntercamb := GetNextAlias()

	BeginSql Alias cQryIntercamb
		SELECT R_E_C_N_O_ RECNO
		FROM %Table:TWY%
		WHERE TWY_FILIAL = %xFilial:TWY%
			AND TWY_ATIVO = '1'
			AND TWY_CODPRO = %Exp:cProdPai%
			AND TWY_CODINT = %Exp:cProdItem%
			AND %NotDel%
	EndSql

	lRet := (cQryIntercamb)->(!EOF())

	(cQryIntercamb)->(DbCloseArea())
EndIf

Return lRet

/*/{Protheus.doc}  At890IsKt
@description Identifica se 2 produtos s�o pai e item em uma estrutura de kit de materiais
@author  	josimar.assuncao
@since 	  	10.07.2017
@version 	P12
@param 		cProdPai, caracter, c�digo do produto mestre do cadastro de kit.
@param 		cProdItem, caracter, c�digo do produto item do cadastro de kit.
@return 	L�gico, determina se uma combina��o de produtos est� dentro do cadastro de kit de materiais.
/*/
Function At890IsKt( cProdPai, cProdItem )
Local lRet := .F.
Local cQryKitMat := ""

If !Empty(cProdPai) .And. !Empty(cProdItem)

	cQryKitMat := GetNextAlias()

	BeginSql Alias cQryKitMat
		SELECT R_E_C_N_O_ RECNO
		FROM %Table:TWX%
		WHERE TWX_FILIAL = %xFilial:TWX%
			AND TWX_KITPRO = %Exp:cProdPai%
			AND TWX_CODPRO = %Exp:cProdItem%
			AND %NotDel%
	EndSql

	lRet := (cQryKitMat)->(!EOF())

	(cQryKitMat)->(DbCloseArea())
EndIf

Return lRet

/*/{Protheus.doc}  At890KtPrd
@description Identifica se 2 produtos s�o pai e item em uma estrutura de kit de materiais intercambi�veis
@author  	josimar.assuncao
@since 	  	09.08.2017
@version 	P12
@param 		cProdPai, caracter, c�digo do produto mestre do cadastro de kit.
@param 		cProdItem, caracter, c�digo do produto item do cadastro de kit ou de produto intercambi�vis.
@return 	cRet, Codigo do produto.
/*/
Static Function At890KtPrd( cCodPrdKit, cPrdAtual )
Local cRet 	  := ""
Local cQryTmp := ""

If !Empty(cCodPrdKit) .And. !Empty(cPrdAtual)

	cQryTmp := GetNextAlias()

	BeginSql Alias cQryTmp
		SELECT TWX_FILIAL, TWX_CODPRO, TWX_QUANT
		FROM %Table:TWX% TWX
			LEFT JOIN %Table:TWY% TWY ON TWY_FILIAL = %xFilial:TWY%
								AND TWY_CODPRO = TWX_CODPRO
								AND TWY.%NotDel%
		WHERE TWX_FILIAL = %xFilial:TWX%
			AND TWX_KITPRO = %Exp:cCodPrdKit%
			AND ( TWX_CODPRO = %Exp:cPrdAtual% OR TWY_CODINT = %Exp:cPrdAtual% )
			AND TWX.%NotDel%
	EndSql

	If (cQryTmp)->(!EOF())
		cRet := (cQryTmp)->TWX_CODPRO
	EndIf

	(cQryTmp)->(DbCloseArea())
EndIf

Return cRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890ChkComp
Verifica se todos os componentes do kit de materiais possuem complemento de produto.

@author   Kaique Schiller
@since 	  23/08/2017
@version P12
@return lRet: Retorna .T. quando os campos estiverem ok.
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At890ChkComp(cCodKit,cCampo)
Local aArea    := GetArea()
Local lRet     := .T.
Local aPrds    := {}
Local cProduto := ""
Local cMsgHelp := ""
Local nX       := 0

While TWX->(!EoF()) .AND. TWX->(TWX_FILIAL+TWX_KITPRO) == FWxFilial("TWX")+cCodKit
	cProduto := TWX->TWX_CODPRO
	If ( Posicione("SB5", 1, xFilial("SB5")+cProduto, cCampo ) <> "1" )
		Aadd(aPrds,AllTrim(cProduto) + ' - '+ AllTrim(Posicione("SB1",1,FwxFilial("SB1")+cProduto,"B1_DESC")))
		lRet := .F.
	Endif
	TWX->(DbSkip())
EndDo

If !lRet
	cMsgHelp := STR0109+CRLF //"O(s) componente(s) abaixo n�o possui(em) complemento de produto ou n�o esta(�o) cadastrado(s) como MI ou MC:"
	For nX := 1 To Len(aPrds)
		cMsgHelp += CRLF + aPrds[nX]
	Next nX
	Help( "", 1, "At890ChkComp", , cMsgHelp, 1, 0,,,,,,{STR0110})  // "Realize a inclus�o do(s) complemento de produto"
EndIf

RestArea( aArea )

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At890SelFields
	Filtra os campos de controle da rotina para n�o serem exibidos na view
@sample 	At890SelFields() 
@since		18/10/2017       
@param   	cTab, Caracter, C�digo da tabela a ter o campo avaliado
@param   	cCpoAval, Caracter, C�digo do campo a ser avaliado

@return 	lRet, Logico, define se o campo deve ser apresentado na view
/*/
//------------------------------------------------------------------------------
Static Function At890SelFields(cTab,cCpoAval)
Local lRet		:= .T.

// Retirar campos para o modelo antigo de or�amento de servi�os
If cTab == "TFL"
	lRet := lRet .And. (cCpoAval $ 'TFL_CODIGO#TFL_LOCAL#TFL_DESLOC#TFL_DTINI#TFL_DTFIM#TFL_ESTADO#TFL_MUNIC#TFL_CODPAI')
Endif

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At890SldRec
	Retorna o saldo dos materias para contrato recorrente.
@sample 	At890SldRec(cTab,cCodMat) 
@since		20/10/2017       
@param   	cTab, Caracter, C�digo da tabela a ter a quantidade somada.
@param   	cCodMat, Caracter, C�digo do material.

@return 	nQtdRec, Numerico, Quantidade do saldo recorrente.
/*/
//------------------------------------------------------------------------------
Function At890SldRec(cTab,cCodMat,lKit)
Local aAreaMat	:= (cTab)->(GetArea())
Local nQtdRec 	:= 0
Local nSldMat	:= 0
Local cQryTmp	:= "" 
Local cSelect	:= ""
Local cFrom		:= ""
Local cWhere	:= ""
Local cDtIni	:= cAnoCor + cMesCor + cPriDia
Local cDtFin	:= cAnoCor + cMesCor + cUltDia
Local cSeqKit	:= ""
Local cCmpSeqKit:= ""
Default cTab	:= ""
Default cCodMat := ""
Default lKit	:= .F.

If cTab == "TFS"
	If lKit
		cSelect := "%TFS_CODKIT, TFS_SEQKIT, TFS_QTDKIT SLDMAT %"
	Else
		cSelect := "%SUM( TFS_QUANT ) SLDMAT %"
	Endif
	cFrom   := "%"+RetSqlName("TFS")+" TFS%" 
	cWhere  := "%TFS_FILIAL = '" + xFilial("TFS") + "' AND TFS_CODTFG = '" +  cCodMat + "' "
	cWhere  += "AND TFS.TFS_DTAPON BETWEEN '" + cDtIni + "' AND '" + cDtFin + "'
	cWhere  += "AND TFS.D_E_L_E_T_ = ' '%"

	DbSelectArea("TFG")
	TFG->(DbSetOrder(1))
	If TFG->(DbSeek(xFilial("TFG") + cCodMat))
		nQtdRec := TFG->TFG_QTDVEN
	Endif
	
	cCmpSeqKit  := "TFS_SEQKIT"
Elseif cTab == "TFT"
	If lKit
		cSelect := "%TFT_CODKIT, TFT_SEQKIT, TFT_QTDKIT SLDMAT %"
	Else
		cSelect := "%SUM( TFT_QUANT ) SLDMAT %"
	Endif

	cFrom   := "%"+RetSqlName("TFT")+" TFT%"
	cWhere  := "%TFT_FILIAL = '" + xFilial("TFT") + "' AND TFT_CODTFH = '" +  cCodMat + "' "
	cWhere  += "AND TFT.TFT_DTAPON BETWEEN '" + cDtIni + "' AND '" + cDtFin + "'
	cWhere  += "AND TFT.D_E_L_E_T_ = ' '%"
	DbSelectArea("TFH")
	TFH->(DbSetOrder(1))
	If TFH->(DbSeek(xFilial("TFH") + cCodMat))
		nQtdRec := TFH->TFH_QTDVEN
	Endif

	cCmpSeqKit  := "TFT_SEQKIT"
Endif

If !Empty(cCodMat) .And. !Empty(cSelect) .And. !Empty(cFrom) .And. !Empty(cWhere) 

	cQryTmp := GetNextAlias()
	
	BeginSql Alias cQryTmp
    
	    SELECT							
		    %Exp:cSelect%
	    FROM              	
	        %Exp:cFrom%
		WHERE
			%EXP:cWhere% 
	
	EndSql
	
	If lKit
		While (cQryTmp)->(!EOF())
			If cSeqKit <> (cQryTmp)->&(cCmpSeqKit)
				nSldMat += (cQryTmp)->SLDMAT
			Endif

			cSeqKit := (cQryTmp)->&(cCmpSeqKit)

			(cQryTmp)->(DbSkip())
		EndDo
	Endif	

	(cQryTmp)->(DbGoTop())

	If (cQryTmp)->(!EOF())
		If lKit
			nQtdRec := nQtdRec-nSldMat
		Else
			nQtdRec := nQtdRec-(cQryTmp)->SLDMAT
		Endif
	Endif

	(cQryTmp)->(DbCloseArea())
EndIf

RestArea(aAreaMat)

Return nQtdRec

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890VnFunc
Interface para inclus�o de vinculo de funcion�rios
@param  oModPos, Objeto, Model posicionado 
@return lRetorno, L�gico, Verdadeiro
@author Eduardo Gomes J�nior
@since 05/02/2018
/*/
//------------------------------------------------------------------------------------------
Function At890VnFunc(oModPos)
     
Local aArea 			:= GetArea() 
Local aSaveLines  	:= FWSaveRows()
Local oModel        	:= FwModelActive()
Local oStruT4A      	:= FwFormStruct(2,'T4A',{|cCampo| !AllTrim(cCampo) $ "T4A_CODTEC, T4A_NOMTEC, T4A_TIPDEV, T4A_CODTFS, T4A_DFOLHA, T4A_TPMAT, T4A_PRV1, T4A_CODTFL, T4A_LOCAL, T4A_CODPAI, T4A_DSCGFH" })
Local oSubView      	:= FwFormView():New(oModel)
Local oModelTFS 		:= oModel:GetModel('TFSGRID')
Local oModelT4A   	:= oModel:GetModel('T4AGRID')
Local lRetorno     	:= .T.
Local cHlpVnFu		:= ""
Local nLine			:= oModelTFS:GetLine()
Local oStrT4A			:= Nil
Local aButtons	:= {	{.F.,Nil},;			//- Copiar
							{.F.,Nil},;			//- Recortar
							{.F.,Nil},;			//- Colar
							{.F.,Nil},;			//- Calculadora
							{.F.,Nil},;			//- Spool
							{.F.,Nil},;			//- Imprimir
							{.T.,"Confirmar"},;			//- Confirmar
							{.T.,"Cancelar"},;	//- Cancelar
							{.F.,Nil},;			//- WalkThrough
							{.F.,Nil},;			//- Ambiente
							{.F.,Nil},;			//- Mashup
							{.F.,Nil},;			//- Help
							{.F.,Nil},;			//- Formul�rio HTML
							{.F.,Nil};				//- ECM
						}
Local bSetonOk    := 	{|oModel|At890VinOk(oModel)}	

If	Empty(oModelTFS:GetValue("TFS_CODTFG")) 
	cHlpVnFu += STR0077 + CHR(13) + CHR(10)	//"Informe o c�digo do material de implanta��o"
Endif 

If	oModelTFS:GetValue("TFS_QUANT") == 0
	cHlpVnFu += STR0078 + CHR(13) + CHR(10)	//"Informe a quantidade do material de implanta��o"
Endif 

If	!Empty(cHlpVnFu)
	Help( ,, 'At890VnFunc',, cHlpVnFu , 1, 0 )
	RestArea(aArea)
	Return
EndIf

oSubView:SetModel(oModel)
oSubView:CreateHorizontalBox('POPBOX',100)

oSubView:AddGrid('VIEW_T4A',oStruT4A,'T4AGRID')
oSubView:AddIncrementField( 'VIEW_T4A', 'T4A_ITEM' )
oSubView:SetOwnerView('VIEW_T4A','POPBOX')

If	At890VPEPI( oModel, FwFldGet("TFS_PRODUT"))

	If Empty(oModelTFS:GetValue("TFS_CODKIT"))
		oModelT4A:LoadValue('T4A_CODEPI', FwFldGet("TFS_PRODUT"))
		oModelT4A:LoadValue('T4A_DESC'	, Posicione("SB1",1,xFilial("SB1")+FwFldGet("TFS_PRODUT"),"B1_DESC"))
		
		If !Empty(FwFldGet("T4A_FORNEC")) .And. !Empty(FwFldGet("T4A_LOJA"))
			oModelT4A:LoadValue("T4A_NUMCAP", At890NCA(.F.))
		EndIf
		
		TECXFPOPUP(oModel,oSubView, , MODEL_OPERATION_UPDATE, 40 ,, STR0079 + oModelTFS:GetValue("TFS_CODIGO"),bSetonOk )	//"Vinculo com Funcion�rio - Apontamento:"
	Else		
		//Posiciona a TFS no primeiro item do Kit para n�o dar problema de relacionamento
		At890SeekT4A(oModelTFS,oModelT4A)
		
		//Adiciona os produtos para o Kit
		At890IncKit(oModelTFS,oModelT4A)
		
		//Carrega a estrutura para alterar a propriedade de alguns campos
		oStrT4A	:= oModelT4A:GetStruct()
		oStrT4A:SetProperty('T4A_QTDENT',MODEL_FIELD_WHEN ,{|| .F. } )
		
		//Bloqueia novas linhas
		oModelT4A:SetNoInsertLine( .T. )
		
		TECXFPOPUP(oModel,oSubView, , MODEL_OPERATION_UPDATE, 20 ,aButtons, STR0079 + oModelTFS:GetValue("TFS_CODKIT"),bSetonOk )	//"Vinculo com Funcion�rio - Apontamento:"		
		
		//Retorna a linha da TFS
		oModelTFS:GoLine(nLine)
		
		oStrT4A:SetProperty('T4A_QTDENT',MODEL_FIELD_WHEN ,{|| .T. } )
		oModelT4A:SetNoInsertLine( .F. )
		
	EndIf
Endif 	

FWRestRows( aSaveLines )
RestArea(aArea)

Return lRetorno

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} TC890TPMAT
Valida��o aplicada no VALID do campo TFS_TPMAT:
Valida se o par�metro de integra��o MV_NG2GS est� ativo e se tipo de material informado � 2-EPI.
Valida se j� existe algum vinculo de funcion�rio criado para o apontamento posicionado. 
@param  cCpoCdMov, Caracter, Codigo do apontamento
@param  cCpoTPMAT, Caracter, Tipo de material (1-Normal/2-EPI/3-Unifforme)   
@return lRetorno, L�gico, Verdadeiro
@author Eduardo Gomes J�nior
@since 05/02/2018
/*/
//------------------------------------------------------------------------------------------
Function TC890TPMAT(cCpoCdMov, cCpoTPMAT)

Local aArea			:= GetArea()
Local lRetorno		:= .T.

If	cCpoTPMAT == "2" .AND. !lSigaMdtGS 
	Help( ,, 'TC890TPMAT',, STR0080 , 1, 0 )	//"Par�metro (MV_NG2GS) de integra��o SIGAMDT x SIGATEC inexistente ou n�o esta ativo. Op��o 2=EPI n�o permitida."
	lRetorno := .F.
EndIf

If	lRetorno
	dbSelectArea("T4A")
	dbSetOrder(2)	//T4A_FILIAL+T4A_CODTFS
	If	dbSeek(xFilial("T4A")+cCpoCdMov)
		Help( ,, 'TC890TPMAT',, STR0081 + cCpoCdMov + STR0082 , 1, 0 )	//"Vinculo de funcion�rio j� criado para o apontamento :"###" Altera��o de tipo de material n�o permitida."
		lRetorno := .F.
	Endif 
Endif 

Return(lRetorno)

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890PosVld
Aplica valida��es na tela de vinculo de funcion�rios antes da grava��o final
- avalia quantidade informada (soma tem que ser igual ao apontado)
- caso o tipo de UNIFORME/EPI n�o permite salvar sem informar os funcion�rios vinculados
-n�o permite exclus�o caso funcion�rio vinculado esteja com o produto com tipo de devolu��o igual a 3 ou 4.
@param  oModPos, Objeto, Model posicionado   
@return lRetorno, L�gico, Verdadeiro
@author Eduardo Gomes J�nior
@since 05/02/2018
/*/
//------------------------------------------------------------------------------------------
Function At890PosVld(oModel) 

Local aArea			:= GetArea()
Local aSaveLines  	:= FWSaveRows()
Local lRetorno		:= .T.
Local lAplVld		:= .F.
Local nITFS			:= 1
Local nIT4A			:= 1
Local nSmaIT4A		:= 0
Local oModelTFS 	:= oModel:GetModel('TFSGRID')
Local oModelT4A   	:= oModel:GetModel('T4AGRID')

If	lSigaMdtGS

	For nITFS :=1 To oModelTFS:Length() 
		
		//Verifica se � kit e posiciona na linha correta
		If !Empty(oModelTFS:GetValue("TFS_CODKIT"))
			At890SeekT4A(oModelTFS,oModelT4A)
		Else		
			oModelTFS:GoLine(nITFS)
		EndIf
		
		If	!oModelTFS:IsDeleted() .AND. oModelTFS:GetValue("TFS_TPMAT") $ "2|3"
		
			If	oModelT4A:Length() == 1 
				
				If	Empty(oModelT4A:GetValue("T4A_MAT")) .OR. oModelT4A:IsDeleted()
					lRetorno := .F.
				Endif
				
			Else
			
				For nIT4A:=1 To oModelT4A:Length()
				
					oModelT4A:GoLine(nIT4A)	
					
					If	Empty(oModelT4A:GetValue("T4A_MAT")) .OR. oModelT4A:IsDeleted()
						nSmaIT4A ++
					Endif
		
				Next nIT4A 
				
				If	nSmaIT4A == oModelT4A:Length()
					lRetorno := .F.
				Endif 
			
			Endif 				   
			
			
			If	!lAplVld .AND. !lRetorno	
				Help( ,, 'At890PosVld',, STR0083, 1, 0 )	//"Vinculo de funcion�rio obrigat�rio para material de implanta��o com o tipo igual a 2=EPI ou 3=Uniformes."			
			Endif			 
		
		Endif 
		
		If	oModelTFS:IsDeleted() 
		
			If	oModelTFS:GetValue("TFS_TPMAT") == "2"	//Tipo de material EPI
				
				dbSelectArea("TNF")
				dbSetOrder(7)
			
				If	dbSeek(xFilial("TNF")+oModelTFS:GetValue("TFS_CODIGO"))
					Help( ,,'At890PosVld',, STR0086+" "+STR0088 + oModelTFS:GetValue("TFS_CODIGO")+ STR0089+" "+STR0090 , 1, 0 )	//"Exclus�o n�o permitida."###"Existe vinculo de EPI x Funcion�rio criados para o apontamento: "###" Acesse o modulo SIGAMDT (Medicina e Seguran�a do Trabalho) op��o Funcion�rio x EPI para realizar a "###"exclus�o do EPI e ap�s isso ser� poss�vel a exclus�o no SIGATEC (Gest�o de Servi�o). "
					lRetorno := .F.
					lAplVld	 := .T.
				Endif
				
			Endif 				
			
			If	oModelTFS:GetValue("TFS_TPMAT") == "3"	//Tipo de material UNIFORME

				If	At890StsT4a(oModelTFS:GetValue("TFS_CODIGO"))
					Help( ,,'At890PosVld',, STR0086 +" "+ STR0094 + oModelTFS:GetValue("TFS_CODIGO")  , 1, 0 )	//"Exclus�o n�o permitida."###Existem materiais do tipo UNIFORME com o tipo de devolu��o igual a (3- Devolvido Operacional ou 4- Devolu��o Conclu�da) criados para o apontamento: ###	
					lRetorno := .F.
					lAplVld	 := .T.
				Endif
				 
			Endif 			 				
		
		Endif 
			
	Next nITFS

Endif 

FWRestRows( aSaveLines )
RestArea(aArea)

Return lRetorno

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890T4APosVal
Conforme tipo de devolu��o avalia se funcion�rio x vinculo pode ser alterado ou exclu�do. 
@param  oMdlG, Objeto, Model posicionado   
@param  nLine, N�merico, Linha posicionada
@param  cAcao, Caracter, A��o realizada
@param  cCampo, Caracter, Nome do campo sendo alterado
@return lRetorno, L�gico, Verdadeiro
@author Eduardo Gomes J�nior
@since 05/02/2018
/*/
//------------------------------------------------------------------------------------------
Function At890T4APosVal(oMdlG,nLine,cAcao,cCampo)

Local aArea			:= GetArea()
Local aSaveLines  	:= FWSaveRows()
Local lRetorno		:= .T.
Local cTipDEV 		:= ""

If	oMdlG:GetValue("T4A_TPMAT") == "2"	//EPI

	dbSelectArea("TNF")
	dbSetOrder(7)	//TNF_FILIAL+TNF_CODTFS+TNF_ITEM+TNF_MAT+TNF_CODEPI+TNF_FORNEC+TNF_LOJA
	If	dbSeek(xFilial("TNF")+oMdlG:GetValue("T4A_CODTFS")+oMdlG:GetValue("T4A_ITEM")+oMdlG:GetValue("T4A_MAT")+oMdlG:GetValue("T4A_CODEPI"))

		If	cAcao == "DELETE"
			Help( ,,'At890T4APosVal',,STR0086+" "+STR0088 + oMdlG:GetValue("T4A_CODTFS")+ STR0089+" "+STR0090   , 1, 0 )
			lRetorno := .F.		
		Endif
		
		If	cAcao == "SETVALUE"
			Help( ,,'At890T4APosVal',,STR0087+" "+STR0088 + oMdlG:GetValue("T4A_CODTFS")+ STR0089+" "+STR0091   , 1, 0 )
			lRetorno := .F.		
		Endif 				
		 				
		
	Endif
		
Endif

If	oMdlG:GetValue("T4A_TPMAT") == "3"	//UNIFORMES

	If	cAcao == "DELETE" .OR. cAcao == "SETVALUE"

		dbSelectArea("T4A")
		dbSetOrder(3)
		If	dbSeek(xFilial("T4A")+oMdlG:GetValue("T4A_CODTFS")+oMdlG:GetValue("T4A_ITEM")+oMdlG:GetValue("T4A_CODEPI")+oMdlG:GetValue("T4A_MAT"))

			If	T4A_TIPDEV == "3"  
				cTipDEV := STR0095	//"3- Devolvido Operacional"
			Endif
			
			If	T4A_TIPDEV == "4"  
				cTipDEV := STR0096	//"4- Devolu��o Conclu�da"
			Endif
			
			If	T4A_TIPDEV $ "3|4"
				Help( ,,'At890T4APosVal',, If( cAcao == "DELETE" , STR0086 , STR0087 ) + STR0097 + cTipDEV  , 1, 0 )	//"Exclus�o n�o permitida." ###"Altera��o n�o permitida."###"Material com o tipo de devolu��o igual a " 
				lRetorno := .F.
			Endif 				
		
		Endif

	Endif
		
Endif 		 						 				

FWRestRows( aSaveLines )
RestArea(aArea)

Return lRetorno

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT890MDTA695
Caso v�nculo de funcion�rio seja igual a 2-EPI realiza a inclus�o do funcion�rio x EPI 
no modulo SIGAMDT atrav�s de rotina autom�tica (MDTA695).
@param  oModel, Objeto, Model posicionado
@return .T., L�gico, Verdadeiro
@author Eduardo Gomes J�nior
@since 05/02/2018
/*/
//------------------------------------------------------------------------------------------
Function AT890MDTA695(oModel,aLines)

Local aArea			:= GetArea()
Local aAreaTFS		:= TFS->(GetArea())
Local aAreaT4A		:= T4A->(GetArea())
Local aSaveLines  	:= FWSaveRows()
Local oModelTFS 		:= oModel:GetModel('TFSGRID')
Local oModelT4A   	:= oModel:GetModel('T4AGRID')
Local aCabe			:= {}
Local aItem			:= {}
Local nOpcao			:= 4
Local nITFS			:= 1
Local nIT4A			:= 1
Local cMatAnt			:= ""
Local lExAuto			:= .F.

Private lMSErroAuto	:= .F.	//Variavel PRIVATE criada para uso do MSExecAuto 
Private cArquivTLW 	:= ""	//Variavel PRIVATE criada para n�o ocorrer erro durente MSExecAuto da rotina MDTA695. Dentro da rotina MDTA695 � usado essa variavel por�m ela n�o esta declarada.  

For nITFS :=1 To Len(aLines)

	oModelTFS:GoLine(aLines[nITFS,1])
	If	!oModelTFS:IsDeleted() .AND. !Empty(oModelTFS:GetValue("TFS_CODIGO")) .AND. oModelTFS:GetValue("TFS_TPMAT") ==  "2"
	
		For nIT4A :=1 To oModelT4A:Length()
		
			oModelT4A:GoLine(nIT4A)

			If	!oModelT4A:IsDeleted() .AND. oModelT4A:GetValue("T4A_CODTFS") == oModelTFS:GetValue("TFS_CODIGO")
			
				If	nIT4A > 1 .And. !Empty(cMatAnt) .AND. cMatAnt <>  oModelT4A:GetValue("T4A_MAT")
				
					MSExecAuto({|x,z,y,w| MDTA695(x,z,y,w)},"TECA890", aCabe , aItem, nOpcao )
			
					If	lMsErroAuto
						MostraErro()
						DisarmTransaction()
						Break
						Return .F.
					EndIf
					
					aCabe 	:= {}
					aItem	:= {}
				
				Endif
				
				aCabe := { {"RA_MAT",oModelT4A:GetValue("T4A_MAT") , Nil } } 			
	
				aAdd( aItem , {	{"TNF_FILIAL"	  , xFilial("TNF")													, NIL},;
								{"TNF_MAT"        , oModelT4A:GetValue("T4A_MAT")		 							, NIL},;
								{"TNF_CODEPI"     , oModelT4A:GetValue("T4A_CODEPI") 								, NIL},;
								{"TNF_FORNEC"     , oModelT4A:GetValue("T4A_FORNEC")	 							, NIL},;
								{"TNF_LOJA"       , oModelT4A:GetValue("T4A_LOJA") 									, NIL},;
								{"TNF_NUMCAP"     , oModelT4A:GetValue("T4A_NUMCAP")         						, NIL},;
								{"TNF_DTENTR"     , oModelT4A:GetValue("T4A_DTENTR")  								, NIL},;
								{"TNF_HRENTR"     , oModelT4A:GetValue("T4A_HRENTR")    							, NIL},;
								{"TNF_QTDENT"     , oModelT4A:GetValue("T4A_QTDENT")								, NIL},;
								{"TNF_MOTIVO"     , oModelT4A:GetValue("T4A_MOTIVO")								, NIL},;
								{"TNF_INDDEV"     , "2"			        											, NIL},;
								{"TNF_CODTFS"     , oModelT4A:GetValue("T4A_CODTFS")								, NIL},;
								{"TNF_ITEM  "     , oModelT4A:GetValue("T4A_ITEM")									, NIL},;
								{"TNF_CODFUN"     , Posicione("SRA",1,xFilial("SRA")+oModelT4A:GetValue("T4A_MAT"),"RA_CODFUNC")	, NIL}} )																
			
				cMatAnt := oModelT4A:GetValue("T4A_MAT")
								
			Endif
		
		Next nIT4A
		
		MSExecAuto({|x,z,y,w| MDTA695(x,z,y,w)},"TECA890", aCabe , aItem, nOpcao )
			
		If	lMsErroAuto
			MostraErro()
			DisarmTransaction()
			Break
			Return .F.
		EndIf
		
		aCabe 	:= {}
		aItem	:= {}
		
	Endif 	
	
Next  nITFS

FWRestRows( aSaveLines )

RestArea(aArea)
RestArea(aAreaTFS)
RestArea(aAreaT4A)

Return .T.

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT890VlQtd
Valida quantidade informada no material vinculado ao funcion�rio. A soma tem que ser igual ou 
menor que o total informado no apontamento. E caso j� exista EPI x Funcion�rio criado n�o permite mais a altera��o
@param  oModel, Objeto, Model posicionado
@param  nQtdInfo, N�merico, Quantidade informada 
@return lRetorno, L�gico, Verdadeiro/Falso
@author Eduardo Gomes J�nior
@since 05/02/2018
/*/
//------------------------------------------------------------------------------------------
Function AT890VlQtd( oModel, nQtdInfo)

Local aSaveLines  	:= FWSaveRows()
Local oModelTFS 	:= oModel:GetModel('TFSGRID')
Local oModelT4A   	:= oModel:GetModel('T4AGRID')
Local nQtdApont		:= oModelTFS:GetValue("TFS_QUANT") 
Local nVI	 		:= 1
Local nTotVinc		:= 0
Local nLinhAtu		:= oModelT4A:GetLine()
Local cTpMat		:= oModelTFS:GetValue("TFS_TPMAT") 
Local lRetorno		:= .T.

If	oModelT4A:Length() == 1 .AND.  !oModelT4A:IsDeleted()

	If	cTpMat == "2"

		dbSelectArea("TNF")
		dbSetOrder(7)	//TNF_FILIAL+TNF_CODTFS+TNF_ITEM+TNF_MAT+TNF_CODEPI+TNF_FORNEC+TNF_LOJA
		If	dbSeek(xFilial("TNF")+oModelT4A:GetValue("T4A_CODTFS")+oModelT4A:GetValue("T4A_ITEM")+oModelT4A:GetValue("T4A_MAT")+oModelT4A:GetValue("T4A_CODEPI"))
			Help( ,,'AT890VlQtd',, STR0087 + oModelTFS:GetValue("TFS_CODIGO")+ STR0088 , 1, 0 )	//"Altera��o n�o permitida."###"Existe vinculo de EPI x Funcion�rio criados para o apontamento: "
			lRetorno := .F.
		Endif

	Endif 

	If	lRetorno	 

		If	nQtdInfo > nQtdApont	
			Help( ,, 'AT890VlQtd',, STR0084 , 1, 0 )	//"Quantidade informada deve ser menor ou igual a quantidade do material de implanta��o."
			lRetorno := .F.
		Endif
	
	Endif
	 
Else

	For nVI :=1 To oModelT4A:Length()
	
		oModelT4A:GoLine(nVI)
		
		If	cTpMat == "2"

			dbSelectArea("TNF")
			dbSetOrder(7)	//TNF_FILIAL+TNF_CODTFS+TNF_ITEM+TNF_MAT+TNF_CODEPI+TNF_FORNEC+TNF_LOJA
			If	dbSeek(xFilial("TNF")+oModelT4A:GetValue("T4A_CODTFS")+oModelT4A:GetValue("T4A_ITEM")+oModelT4A:GetValue("T4A_MAT")+oModelT4A:GetValue("T4A_CODEPI"))
				Help( ,,'AT890VlQtd',, "STR0086" + oModelTFS:GetValue("TFS_CODIGO")+ "STR0087" , 1, 0 )
				lRetorno := .F.
				Exit
			Endif

		Endif
		
		If	lRetorno
	
			If	!oModelT4A:IsDeleted()
	
				If	nVI == nLinhAtu 
					nTotVinc += nQtdInfo 
				Else 
					nTotVinc += oModelT4A:GetValue("T4A_QTDENT")					
				Endif
				
			Endif 			
			
		Endif 			
					
	Next nVI
	
	If	nTotVinc > nQtdApont	
		Help( ,, 'AT890VlQtd',, STR0085 , 1, 0 )	//"A soma da quantidade de todos os funcion�rios deve ser menor ou igual a quantidade do material de implanta��o. Refa�a a distribui��o das quantidades"
		lRetorno := .F.
	Endif

Endif 	

FWRestRows( aSaveLines )

Return(lRetorno)

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890VPEPI
Aplica valida��o no codigo do produto/EPI informado.
@param  oModel, Objeto, Model posicionado
@param  cEpiInfo, Caracter, Codigo do EPI 
@return lRetorno, L�gico, Verdadeiro/Falso
@author Eduardo Gomes J�nior
@since 05/02/2018
/*/
//------------------------------------------------------------------------------------------
Function At890VPEPI(oModel,cEpiInfo)

Local aArea			:= GetArea()
Local aSaveLines  	:= FWSaveRows()
Local oModelTFS 	:= oModel:GetModel('TFSGRID')
Local oModelT4A   	:= oModel:GetModel('T4AGRID')
Local cTpMat		:= oModelTFS:GetValue("TFS_TPMAT")
Local cTipo 		:= SuperGetMv("MV_MDTPEPI",.F.,"")
Local lSX5  		:= !Empty(cTipo)

Local lRetorno	:= .T.

If	oModelT4A:Length() == 1 .AND.  !oModelT4A:IsDeleted()

	If	cTpMat == "2"
		lRetorno := MDTProEpi(cEpiInfo,cTipo,lSX5) 
	Else 
		lRetorno := EXISTCPO("SB1",cEpiInfo)                                                                                                                 
	Endif
	
Endif 	 

FWRestRows( aSaveLines )

RestArea(aArea)

Return lRetorno

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890StsT4a
Caso material vinculado ao funcion�rio esteja com tipo de devolu��o igual a 3=Devolvido Operacional 
ou 4=Devolu��o Conclu�da retorna verdadeiro.  
@param  cCodApont, Caracter, C�digo do Apontamento
@return lRetorno, L�gico, Verdadeiro/Falso
@author Eduardo Gomes J�nior
@since 05/02/2018
/*/
//------------------------------------------------------------------------------------------
Static Function At890StsT4a(cCodApont)

Local aArea		:= GetArea()
Local lRetorno	:= .F.
Local cQueryT4A	:= GetNextAlias()

BeginSql Alias cQueryT4A
	SELECT MAX(T4A_TIPDEV) ULTSTATUS  	
	FROM %Table:T4A% T4A
	WHERE T4A_CODTFS = %exp:cCodApont% AND T4A.%NotDel%
EndSql

If	(cQueryT4A)->(!Eof()) .AND. ULTSTATUS $ '3|4' 
	lRetorno := .T.
Endif 

IF Select( cQueryT4A ) > 0
	(cQueryT4A)->(dbCloseArea())
EndIf

RestArea(aArea)
	
Return lRetorno

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890T4AProd
Iniciador padr�o para os campos T4A_CODEPI e T4A_DESC 
@param  oModel, Objeto, Model posicionado
@param  cCampo, Caracter, Nome do campo
@return cRetorno, Caracter, De acordo com o par�metro retorna o c�digo do produto ou descri��o
@author Eduardo Gomes J�nior
@since 05/02/2018
/*/
//------------------------------------------------------------------------------------------
Function At890T4AProd(oModel,cCampo)

Local cRetorno 	:= "" 
Local oMdl			:= FwModelActive()
Local oModelTFS  	:= oMdl:GetModel('TFSGRID')
Local oModelT4A   := oMdl:GetModel('T4AGRID')
Local aProd		:= {}
Local nPosKit		:= 0

If Empty(FwFldGet("TFS_CODKIT"))
	If	cCampo == "T4A_CODEPI" 	
		
		If	At890VPEPI( oModel, FwFldGet("TFS_PRODUT"))
			cRetorno := FwFldGet("TFS_PRODUT")
		Endif		
		
	Endif 	
	
	If	cCampo == "T4A_DESC"  	
		cRetorno := Posicione("SB1",1,xFilial("SB1")+FwFldGet("TFS_PRODUT"),"B1_DESC")
	Endif
EndIf

Return cRetorno

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890ApSld
Verifica��o do saldo dos produtos j� apontados

@param  cCodTFG, Caracter, Codigo da TFG
@param  cCodProd, Caracter, Codigo do Produto a ser verificado
@param  cTipMov, Caracter, Tipo da movimenta��o se � Apontamento ou Retorno

@return nSaldo, Numerico, Saldo do produto pesquisado

@author Luiz Gabriel Gomes de Jesus
@since 03/07/2018
/*/
//------------------------------------------------------------------------------------------
Function At890ApSld(cCodTFG,cCodProd,cTipMov)
Local nSaldo
Local tmpQry1:=GetNextAlias()

//montar query		
BeginSql Alias tmpQry1
	SELECT  TFS.TFS_PRODUT, SUM(TFS.TFS_QUANT) TFS_QUANT, TFS.TFS_MOV 
		FROM %Table:TFS% TFS
			WHERE	TFS.TFS_FILIAL = %xFilial:TFS% 	
			AND TFS_CODTFG = %Exp:cCodTFG%
			AND TFS_PRODUT = %Exp:cCodProd%
			AND TFS_MOV = %Exp:cTipMov%
			AND TFS.%NotDel%
		Group By TFS.TFS_PRODUT, TFS.TFS_MOV 
EndSql
	
If(tmpQry1)->(!EOF())			
	nSaldo:= (tmpQry1)->TFS_QUANT	  
EndIf				
	
(tmpQry1)->(DbCloseArea())

Return nSaldo

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890Cmt
Commit do modelo de dados

@return lRetorno, Logico, Retorna .T. se o modelo foi gravado corretamente

@author Luiz Gabriel Gomes de Jesus
@since 03/07/2018
/*/
//------------------------------------------------------------------------------------------
Function At890Cmt(oModel)
Local lRetorno 		:= .T.
Local aKitsApont    := {}           // Guarda os kits j� apontados
Local oMdlTFL 		:= oModel:GetModel('TFLMASTER')
Local oModelTFS   	:= oModel:GetModel('TFSGRID')
Local oModelT4A   	:= oModel:GetModel('T4AGRID')
Local cCntRec			:= Posicione( "TFJ", 1, xFilial("TFJ") + oMdlTFL:GetValue("TFL_CODPAI"), "TFJ_CNTREC")
Local bBefore			:= {|oModel,cID,cAlias,lNew|At890Grava(oModel,cID,cAlias,lNew,cCntRec,oMdlTFL,aKitsApont,oModelT4A)} //Realiza a movimenta��o antes da grava��o

Begin Transaction
	
	lRetorno := FWFormCommit(oModel,bBefore)
	
	If	lSigaMdtGS .AND. lRetorno

		//-->Realiza inclus�o de EPI x Funcionario (MSEXECAUTO da rotina MDTA695)
		MsgRun(STR0092,STR0025,{|| lRetorno := AT890MDTA695(oModel,aMDT) } )	//"EPI x Funcionario (EPIs Entregues por Funcionario)"###"Aguarde"
			
		//-->Chama rotina de impress�o de modelos
		If	Len(aMdt) > 0 .And. !oModelTFS:IsDeleted().AND. oModelT4A:Length() > 0 
			AT990IntWord(oModel,.F.)
		Endif 	
		
		aMdt := {}
		
	EndIf			
	
End Transaction

Return( lRetorno )

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890Grava
Fun��o de grava��o das linhas de apontamento

@param  oModel, Objeto, Objeto do Model
@param  cID, Caracter, Id do submodelo de edi��o
@param  cAlias, Caracter, Alias da tabela
@param  lNew, Logico, Indica se � uma linha nova
@param  cCntRec, Caracter, Indica se o contrato � recorrente
@param  oMdlTFL, Objeto, Modelo de dados da TFL
@param  aKitsApont, Array, Array para controlar a grava��o dos produtos do tipo Kit

@return lRetorno, Logico, Se .T. indica que a grava��o foi correta

@author Luiz Gabriel Gomes de Jesus
@since 03/07/2018
/*/
//------------------------------------------------------------------------------------------
Function At890Grava(oModel,cID,cAlias,lNew,cCntRec,oMdlTFL,aKitsApont,oModelT4A)
Local lRetorno		:= .T.				//validador de retorno, caso ocorra algum erro, ele retorna false, evitando que seja adicionado dados na tabela ABV
Local aArea			:= GetArea()		//Pega posi��o GetArea()
Local aSaveLines	:= FWSaveRows()
Local cCodTWZ		:= ""

//Verifica qual apontamento vai ser realizado
If cAlias == "TFS"
	If lNew .And. Empty(oModel:GetValue("TFS_ITAPUR")) //Verifica se o apontamento ainda n�o foi apurado
		If (!oModel:IsDeleted() .AND. !Empty(oModel:GetValue("TFS_CODTFG")))		//	Verifica se � uma linha deletada e se tem c�digo de apontamento
			
			If lPeriod .And. oModel:GetValue("TFS_PEND") == "S" .AND. !Empty(oModel:GetValue("TFS_USRAPV"))
				oModel:LoadValue("TFS_PEND","N")
			ElseIf lPeriod
				lRetorno := .F.
			EndIf
						
			//Realiza a movimenta��o
			lRetorno := lRetorno .And. At890Movi(oModel,cAlias,3,cCntRec,lNew,aKitsApont)
					
			If lRetorno
				If	lSigaMdtGS .AND. oModel:GetValue("TFS_TPMAT") $ "2|3"
					aAdd(aMDT,{oModel:GetLine()})					
				EndIf 			
				oModel:LoadValue("TFS_HORA",SubStr(Time(),1,5))
				If lPeriod
					oModel:LoadValue("TFS_PERIOD","1")
					If lAprov
						oModel:LoadValue("TFS_PEND","S")
					EndIf
				EndIf
				ConOut(STR0013) //"Inclusao com sucesso! "
				oModel:LoadValue("TFS_NUMMOV",SD3->D3_NUMSEQ)
				cCodTWZ := At995Custo(oMdlTFL:GetValue("TFL_CODPAI"),;
					oModel:GetValue("TFS_CODTFG"),;
					oMdlTFL:GetValue("TFL_CODIGO"),;
					oModel:GetValue("TFS_PRODUT"),;
					"2",SD3->D3_CUSTO1,"TECA890")
				If !Empty(cCodTWZ)
					oModel:LoadValue("TFS_CODTWZ",cCodTWZ)
				EndIf
			EndIf
		EndIf
	ElseIf !lNew
		If oModel:IsDeleted() //Verifica se a linha est� deletada, e realiza o extorno
		
		//Realiza a movimenta��o como extorno
			lRetorno := At890Movi(oModel,cAlias,5,cCntRec,lNew,aKitsApont)
				
			If lRetorno
				At995ExcC(oMdlTFL:GetValue("TFL_CODPAI"),oModel:GetValue("TFS_CODTWZ"))
			EndIf
		
		ElseIf oModel:IsUpdated() // Se a linha foi alterada realiza o extorno e aponta novamente
			
		//Busca quais campos foram alterados
			aCampos := At890FldUpd(oModel)
			
			If Len(aCampos) > 4
			
				If lPeriod .And. oModel:GetValue("TFS_PEND") == "S" .AND. !Empty(oModel:GetValue("TFS_USRAPV"))
					oModel:LoadValue("TFS_PEND","N")
				ElseIf lPeriod
					lRetorno := .F.
				EndIf
			
				//Realiza a movimenta��o como extorno
				If lRetorno .And. !Empty(oModel:GetValue("TFS_NUMMOV"))
					lRetorno := At890Movi(oModel,cAlias,5,cCntRec,lNew,aKitsApont)	
					If lRetorno
						At995ExcC(oMdlTFL:GetValue("TFL_CODPAI"),oModel:GetValue("TFS_CODTWZ"))
					EndIf		
				EndIf		
				
				//Depois do Extorno realiza o novo apontamento
				If lRetorno
				//Realiza a movimenta��o
					lRetorno := At890Movi(oModel,cAlias,3,cCntRec,lNew,aKitsApont)
						
					If lRetorno

						If	lSigaMdtGS .AND. oModel:GetValue("TFS_TPMAT") $ "2|3"
							aAdd(aMDT,{oModel:GetLine()})					
						EndIf 	
						 								
						oModel:LoadValue("TFS_HORA",SubStr(Time(),1,5))
						If lPeriod
							oModel:LoadValue("TFS_PERIOD","1")
							If lAprov
								oModel:LoadValue("TFS_PEND","S")
							EndIf
						EndIf
						ConOut(STR0013) //"Inclusao com sucesso! "
						oModel:LoadValue("TFS_NUMMOV",SD3->D3_NUMSEQ)
						oModel:LoadValue("TFS_DTAPON",dDataBase)
						cCodTWZ := At995Custo(oMdlTFL:GetValue("TFL_CODPAI"),;
							oModel:GetValue("TFS_CODTFG"),;
							oMdlTFL:GetValue("TFL_CODIGO"),;
							oModel:GetValue("TFS_PRODUT"),;
							"2",SD3->D3_CUSTO1,"TECA890")
						If !Empty(cCodTWZ)
							oModel:LoadValue("TFS_CODTWZ",cCodTWZ)
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
ElseIf cAlias == "TFT"

	If lNew .And. Empty(oModel:GetValue("TFT_ITAPUR")) //Verifica se o apontamento ainda n�o foi apurado
		If (!oModel:IsDeleted() .AND. !Empty(oModel:GetValue("TFT_CODTFH")))		//	Verifica se � uma linha deletada e se tem c�digo de apontamento
			
			If lPeriod .And. oModel:GetValue("TFT_PEND") == "S" .AND. !Empty(oModel:GetValue("TFT_USRAPV"))
				oModel:LoadValue("TFT_PEND","N")
			ElseIf lPeriod
				lRetorno := .F.
			EndIf
			
			//Realiza a movimenta��o
			lRetorno := lRetorno .And. At890Movi(oModel,cAlias,3,cCntRec,lNew,aKitsApont)
					
			If lRetorno
				oModel:LoadValue("TFT_HORA",SubStr(Time(),1,5))
				If lPeriod
					oModel:LoadValue("TFT_PERIOD","1")
					If lAprov
						oModel:LoadValue("TFT_PEND","S")
					EndIf
				EndIf
				ConOut(STR0013) //"Inclusao com sucesso! "
				oModel:LoadValue("TFT_NUMMOV",SD3->D3_NUMSEQ)
				cCodTWZ := At995Custo(oMdlTFL:GetValue("TFL_CODPAI"),;
					oModel:GetValue("TFT_CODTFG"),;
					oMdlTFL:GetValue("TFL_CODIGO"),;
					oModel:GetValue("TFT_PRODUT"),;
					"2",SD3->D3_CUSTO1,"TECA890")
				If !Empty(cCodTWZ)
					oModel:LoadValue("TFT_CODTWZ",cCodTWZ)
				EndIf
			EndIf
		EndIf
	ElseIf !lNew
		If oModel:IsDeleted() //Verifica se a linha est� deletada, e realiza o extorno
		
			//Realiza a movimenta��o como extorno
			lRetorno := At890Movi(oModel,cAlias,5,cCntRec,lNew,aKitsApont)
				
			If lRetorno
				At995ExcC(oMdlTFL:GetValue("TFL_CODPAI"),oModel:GetValue("TFT_CODTWZ"))
			EndIf
		
		ElseIf oModel:IsUpdated() // Se a linha foi alterada realiza o extorno e aponta novamente
			
			//Busca quais campos foram alterados
			aCampos := At890FldUpd(oModel)
			
			If Len(aCampos) > 4
			
				If lPeriod .And. oModel:GetValue("TFT_PEND") == "S" .AND. !Empty(oModel:GetValue("TFT_USRAPV"))
					oModel:LoadValue("TFT_PEND","N")
				ElseIf lPeriod
					lRetorno := .F.
				EndIf
			
				//Realiza a movimenta��o como extorno
				If lRetorno .And. !Empty(oModel:GetValue("TFT_NUMMOV"))
					lRetorno := At890Movi(oModel,cAlias,5,cCntRec,lNew,aKitsApont)	
					If lRetorno
						At995ExcC(oMdlTFL:GetValue("TFL_CODPAI"),oModel:GetValue("TFT_CODTWZ"))
					EndIf		
				EndIf	
				
				//Depois do Extorno realiza o novo apontamento
				If lRetorno
				//Realiza a movimenta��o
					lRetorno := At890Movi(oModel,cAlias,3,cCntRec,lNew,aKitsApont)
						
					If lRetorno
						oModel:LoadValue("TFT_HORA",SubStr(Time(),1,5))
						If lPeriod
							oModel:LoadValue("TFT_PERIOD","1")
							If lAprov
								oModel:LoadValue("TFT_PEND","S")
							EndIf
						EndIf
						ConOut(STR0013) //"Inclusao com sucesso! "
						oModel:LoadValue("TFT_NUMMOV",SD3->D3_NUMSEQ)
						oModel:LoadValue("TFT_DTAPON",dDataBase)
						cCodTWZ := At995Custo(oMdlTFL:GetValue("TFL_CODPAI"),;
							oModel:GetValue("TFT_CODTFG"),;
							oMdlTFL:GetValue("TFL_CODIGO"),;
							oModel:GetValue("TFT_PRODUT"),;
							"2",SD3->D3_CUSTO1,"TECA890")
						If !Empty(cCodTWZ)
							oModel:LoadValue("TFT_CODTWZ",cCodTWZ)
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf

EndIf

FWRestRows( aSaveLines )

RestArea(aArea)

Return ( lRetorno )

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890Movi
Realiza o apontamento da movimenta��o de estoque

@param  oModel, Objeto, Objeto do Model
@param  cID, Caracter, Id do submodelo de edi��o
@param  cAlias, Caracter, Alias da tabela
@param  nOperation, Numerico, Indica qual a opera��o ser� feita para a grava��o
@param  cCntRec, Caracter, Indica se o contrato � recorrente
@param  lNew, Logico, Indica se � uma linha nova
@param  aKitsApont, Array, Array para controlar a grava��o dos produtos do tipo Kit

@return lRetorno, Logico, Se .T. indica que a grava��o foi correta

@author Luiz Gabriel Gomes de Jesus
@since 03/07/2018
/*/
//------------------------------------------------------------------------------------------
Static Function At890Movi(oModel,cAlias,nOperation,cCntRec,lNew,aKitsApont)
Local lRetorno 		:= .F.
Local aLinha		:= {}
Local nPosKit       := 0

Private lMsHelpAuto 	:= .T. 			// Controle interno do ExecAuto
Private lMsErroAuto 	:= .F. 			// Informa a ocorr�ncia de erros no ExecAuto
Private lAutoErrNoFile 	:= .F.
Private INCLUI 			:= .T. 			// Variavel necess�ria para o ExecAuto identificar que se trata de uma inclus�o
Private ALTERA 			:= .F. 			// Variavel necess�ria para o ExecAuto identificar que se trata de uma altera��o
Private VISUA			:= .T.

If cAlias == "TFS"
	Aadd(aLinha,{"D3_FILIAL"    ,xFilial("SD3")					,NIL})		//	aLinha array que ser� enviado pelo execauto MATA240
	Aadd(aLinha,{"D3_TM"     	,oModel:GetValue("TFS_TM")		,NIL})
	Aadd(aLinha,{"D3_COD"     	,oModel:GetValue("TFS_PRODUT")	,NIL})
	Aadd(aLinha,{"D3_QUANT"     ,oModel:GetValue("TFS_QUANT")	,NIL})
	Aadd(aLinha,{"D3_LOCAL"		,oModel:GetValue("TFS_LOCAL")	,NIL})
	Aadd(aLinha,{"D3_LOCALIZ"   ,oModel:GetValue("TFS_LOCALI")	,NIL})
	Aadd(aLinha,{"D3_CC"      	,oModel:GetValue("TFS_CC")		,NIL})
	Aadd(aLinha,{"D3_LOTECTL"   ,oModel:GetValue("TFS_LOTECT")	,NIL})
	Aadd(aLinha,{"D3_NUMLOTE"   ,oModel:GetValue("TFS_NUMLOT")	,NIL})
	Aadd(aLinha,{"D3_NUMSERI"   ,oModel:GetValue("TFS_NUMSER")	,NIL})		
	
	If !lNew
		aadd(aLinha,{"D3_NUMSEQ"   ,oModel:GetValue("TFS_NUMMOV"),NIL})	
	EndIf
	
	If nOperation == 3
		MATA240(aLinha,nOperation)
		If !lMsErroAuto
			If cCntRec <> "1"
				If Empty(oModel:GetValue("TFS_CODKIT"))
					lRetorno	:=	At890Apont(oModel:GetValue("TFS_QUANT"), "TFG", oModel:GetValue("TFS_CODTFG"))	
				Else
					nPosKit := aScan(aKitsApont,{|x| AllTrim(x[2]) == AllTrim(oModel:GetValue("TFS_CODKIT"))})
					If 	nPosKit == 0 .OR. (nPosKit > 0 .AND. AllTrim(aKitsApont[nPosKit,1]) <> oModel:GetValue("TFS_CODTFG") ) 						
						aAdd(aKitsApont,{oModel:GetValue("TFS_CODTFG"),oModel:GetValue("TFS_CODKIT")})
						lRetorno	:=	At890Apont(oModel:GetValue("TFS_QTDKIT"), "TFG", oModel:GetValue("TFS_CODTFG"))
					EndIf				
				EndIf
			Else
				lRetorno := .T.
			EndIf
		Else
			MostraErro()
			DisarmTransaction()
			Break
			lRetorno := .F.
		EndIf
	ElseIf nOperation == 5
		DbSelectArea("SD3")
		SD3->(DbSetOrder(6))
		If SD3->(DbSeek(xFilial("SD3")+Dtos(oModel:GetValue("TFS_DTAPON")) + oModel:GetValue("TFS_NUMMOV")))		
			Aadd(aLinha,{"D3_EMISSAO"   ,SD3->D3_EMISSAO 						,NIL})
			Aadd(aLinha,{"INDEX"		,6										, NIL})
					
			//Ao deletar a linha a movimenta��o ser� extornada
			MATA240(aLinha,nOperation)
			
			If !lMsErroAuto
				If cCntRec <> "1"
					If Empty(oModel:GetValue("TFS_CODKIT"))
						lRetorno	:=	At890Extrn(oModel:GetValue("TFS_QUANT"), "TFG", oModel:GetValue("TFS_CODTFG"))
					Else	
						nPosKit := aScan(aKitsApont,{|x| AllTrim(x[2]) == AllTrim(oModel:GetValue("TFS_CODKIT"))})
						If 	nPosKit == 0 .OR. (nPosKit > 0 .AND. AllTrim(aKitsApont[nPosKit,1]) <> oModel:GetValue("TFS_CODTFG") ) 						
							aAdd(aKitsApont,{oModel:GetValue("TFS_CODTFG"),oModel:GetValue("TFS_CODKIT")})
							lRetorno	:=	At890Extrn(oModel:GetValue("TFS_QTDKIT"), "TFG", oModel:GetValue("TFS_CODTFG"))
						EndIf					
					EndIf
				Else
					lRetorno := .T.
				EndIf
			Else
				MostraErro()
				DisarmTransaction()
				Break
				lRetorno	:=	.F.
			EndIf			
		EndIf	
	EndIf

ElseIf cAlias == "TFT"

	Aadd(aLinha,{"D3_FILIAL"    ,xFilial("SD3")					,NIL})		//	aLinha array que ser� enviado pelo execauto MATA240
	Aadd(aLinha,{"D3_TM"     	,oModel:GetValue("TFT_TM")		,NIL})
	Aadd(aLinha,{"D3_COD"     	,oModel:GetValue("TFT_PRODUT")	,NIL})
	Aadd(aLinha,{"D3_QUANT"     ,oModel:GetValue("TFT_QUANT")	,NIL})
	Aadd(aLinha,{"D3_LOCAL"		,oModel:GetValue("TFT_LOCAL")	,NIL})
	Aadd(aLinha,{"D3_LOCALIZ"   ,oModel:GetValue("TFT_LOCALI")	,NIL})
	Aadd(aLinha,{"D3_CC"      	,oModel:GetValue("TFT_CC")		,NIL})
	Aadd(aLinha,{"D3_LOTECTL"   ,oModel:GetValue("TFT_LOTECT")	,NIL})
	Aadd(aLinha,{"D3_NUMLOTE"   ,oModel:GetValue("TFT_NUMLOT")	,NIL})
	Aadd(aLinha,{"D3_NUMSERI"   ,oModel:GetValue("TFT_NUMSER")	,NIL})		
	
	If !lNew
		aadd(aLinha,{"D3_NUMSEQ"   ,oModel:GetValue("TFT_NUMMOV"),NIL})	
	EndIf
	
	If nOperation == 3
		MATA240(aLinha,nOperation)
		If !lMsErroAuto
			If cCntRec <> "1"
				If Empty(oModel:GetValue("TFT_CODKIT"))
					lRetorno	:=	At890Apont(oModel:GetValue("TFT_QUANT"), "TFH", oModel:GetValue("TFT_CODTFH"))	
				Else
					nPosKit := aScan(aKitsApont,{|x| AllTrim(x[2]) == AllTrim(oModel:GetValue("TFT_CODKIT"))})
					If 	nPosKit == 0 .OR. (nPosKit > 0 .AND. AllTrim(aKitsApont[nPosKit,1]) <> oModel:GetValue("TFT_CODTFH") ) 						
						aAdd(aKitsApont,{oModel:GetValue("TFT_CODTFH"),oModel:GetValue("TFT_CODKIT")})
						lRetorno	:=	At890Apont(oModel:GetValue("TFT_QTDKIT"), "TFH", oModel:GetValue("TFT_CODTFH"))
					EndIf	
				EndIf
			Else
				lRetorno := .T.
			EndIf
		Else
			MostraErro()
			DisarmTransaction()
			Break
			lRetorno := .F.
		EndIf
	ElseIf nOperation == 5
		DbSelectArea("SD3")
		SD3->(DbSetOrder(6))
		If SD3->(DbSeek(xFilial("SD3")+Dtos(oModel:GetValue("TFT_DTAPON")) + oModel:GetValue("TFT_NUMMOV")))		
			Aadd(aLinha,{"D3_EMISSAO"   ,SD3->D3_EMISSAO 						,NIL})
			Aadd(aLinha,{"INDEX"		,6										, NIL})
					
			//Ao deletar a linha a movimenta��o ser� extornada
			MATA240(aLinha,nOperation)
			
			If !lMsErroAuto
				If cCntRec <> "1"
					If Empty(oModel:GetValue("TFT_CODKIT"))
						lRetorno	:=	At890Extrn(oModel:GetValue("TFT_QUANT"), "TFH", oModel:GetValue("TFT_CODTFH"))
					Else	
						nPosKit := aScan(aKitsApont,{|x| AllTrim(x[2]) == AllTrim(oModel:GetValue("TFT_CODKIT"))})
						If 	nPosKit == 0 .OR. (nPosKit > 0 .AND. AllTrim(aKitsApont[nPosKit,1]) <> oModel:GetValue("TFT_CODTFH") ) 						
							aAdd(aKitsApont,{oModel:GetValue("TFT_CODTFH"),oModel:GetValue("TFT_CODKIT")})
							lRetorno	:=	At890Extrn(oModel:GetValue("TFT_QTDKIT"), "TFH", oModel:GetValue("TFT_CODTFH"))
						EndIf					
					EndIf
				Else
					lRetorno := .T.
				EndIf
			Else
				MostraErro()
				DisarmTransaction()
				Break
				lRetorno	:=	.F.
			EndIf			
		EndIf	
	EndIf

EndIf
	
Return lRetorno

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890FldUpd
Fun��o que retorna os campos que foram editados no modelo de dados posicionado

@param  oModel, Objeto, Objeto do Model que ser� pesquisado

@return aCampos, Array, Array com os campos que foram editados no modelo de dados

@author Luiz Gabriel Gomes de Jesus
@since 03/07/2018
/*/
//------------------------------------------------------------------------------------------
Function At890FldUpd(oModel)
Local aCampos	:= {}
Local oStruct	:= oModel:GetStruct()
Local aFields 	:= oStruct:GetFields()
Local nX		:= 0
Local nTotal	:= Len(aFields)

For nX := 1 To nTotal
	If oModel:IsFieldUpdated( aFields[nX][MODEL_FIELD_IDFIELD] )
		Aadd(aCampos,aFields[nX][MODEL_FIELD_IDFIELD])
	EndIf
Next nX

Return aCampos

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890ChkAp
Fun��o para verificar se o produto possui apontamentos ativos

@param  oModel, Objeto, Objeto do Model anterior a revis�o
@param  cAlias, Caracter, Alias da tabela
@param  nLine, Numerico, Numero da linha que est� sendo editada

@return lRetorno, Logico, Se .T. indica que o produto possui apontamento

@author Luiz Gabriel Gomes de Jesus
@since 03/07/2018
/*/
//------------------------------------------------------------------------------------------
Function At890ChkAp(oMdlRev,cAlias,nLine)
Local lRet 		:= .T.
Local oMdlAp	:= NIL
Local oMdlTFL	:= NIL
Local cCod		:= ""
Local cProd 	:= ""
Local cCodTFL	:= ""

Default nLine := 0

If cAlias == "TFG"

	If oMdlRev <> Nil .And. ValType(oMdlRev) == 'O'
		oMdlAp 	:= oMdlRev:GetModel("TFG_MI")
		oMdlTFL := oMdlRev:GetModel("TFL_LOC")
		cCodTFL := oMdlTFL:GetValue("TFL_CODIGO")
		If oMdlAp <> Nil .And. (nLine > 0 .And. oMdlAp:Length() >= nLine)
			oMdlAp:GoLine(nLine)
			cCod 	:= oMdlAp:GetValue("TFG_COD")
			cProd 	:= oMdlAp:GetValue("TFG_PRODUT")
			
			If !Empty(cCod) .And. !Empty(cProd)
				lRet := A890TFSTFG(cCod,cProd,cCodTFL,cAlias)
			Else
				lRet := .F.
			EndIf
		Else
			lRet := .F.
		EndIf
	EndIf
	
ElseIf cAlias = "TFH"

	If oMdlRev <> Nil .And. ValType(oMdlRev) == 'O'
		oMdlAp 	:= oMdlRev:GetModel("TFH_MC")
		oMdlTFL := oMdlRev:GetModel("TFL_LOC")
		cCodTFL := oMdlTFL:GetValue("TFL_CODIGO")
		If oMdlAp <> Nil .And. (nLine > 0 .And. oMdlAp:Length() >= nLine)
			oMdlAp:GoLine(nLine)
			cCod 	:= oMdlAp:GetValue("TFH_COD")
			cProd 	:= oMdlAp:GetValue("TFH_PRODUT")
			
			If !Empty(cCod) .And. !Empty(cProd)
				lRet := A890TFSTFG(cCod,cProd,cCodTFL,cAlias)
			Else
				lRet := .F.
			EndIf
		Else
			lRet := .F.
		EndIf
	EndIf

EndIf	

Return lRet

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} A890TFSTFG
Fun��o que verifica se o produto possui apontamento

@param  cCod, Caracter, Codigo da TFG
@param  cProd, Caracter, Codigo do Produto
@param  cCodTFL, Caracter, Codigo da TFL
@param  cTab, Caracter, Tabela a ser pesquisada

@return lRetorno, Logico, Se .T. indica que a grava��o foi correta

@author Luiz Gabriel Gomes de Jesus
@since 03/07/2018
/*/
//------------------------------------------------------------------------------------------
Static Function A890TFSTFG(cCod,cProd,cCodTFL,cTab)
Local lRet 		:= .F.
Local cAlias 	:= GetNextAlias()

If cTab == "TFG"
	BeginSql Alias cAlias
	
		SELECT
			TFS_CODTFG,
			TFS_PRODUT,
			TFS_CODTFL,
			TFS_CODKIT			
			
			FROM %table:TFS% TFS
		
		WHERE
			TFS.TFS_FILIAL = %xFilial:TFS% AND
			TFS.TFS_CODTFG = %Exp:cCod% AND  
			(TFS.TFS_PRODUT = %Exp:cProd% OR TFS.TFS_CODKIT = %Exp:cProd%)  AND	
			TFS.TFS_CODTFL = %Exp:cCodTFL% AND
			TFS.%NotDel% 
				
	EndSql
	
	If !(cAlias)->(Eof())					 	
		lRet := .T.
	EndIf
	
	(cAlias)->(DbCloseArea())
	
ElseIf cTab = "TFH"
	BeginSql Alias cAlias
	
		SELECT
			TFT_CODTFH,
			TFT_PRODUT,
			TFT_CODTFL,
			TFT_CODKIT			
			
			FROM %table:TFT% TFT
		
		WHERE
			TFT.TFT_FILIAL = %xFilial:TFT% AND
			TFT.TFT_CODTFH = %Exp:cCod% AND  
			(TFT.TFT_PRODUT = %Exp:cProd% OR TFT.TFT_CODKIT = %Exp:cProd%) AND	
			TFT.TFT_CODTFL = %Exp:cCodTFL% AND
			TFT.%NotDel% 
				
	EndSql
	
	If !(cAlias)->(Eof())					 	
		lRet := .T.
	EndIf
	
	(cAlias)->(DbCloseArea())
	
EndIf

Return lRet

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890AtSld
Fun��o de grava��o das linhas de apontamento

@param  oModel, Objeto, Objeto do Model
@param  cTab, Caracter, Tabela a ser verificada o saldo para ser restaurado
@param  cCodTFG, Caracter, Codigo da TFG
@param  nQuant, Numerico, Quantidade a ser restaurada
@param  cAcao, Caracter, A��o que est� sendo feita no GRID

@return lRetorno, Logico, Se .T. indica que o saldo pode ser restaurado

@author Luiz Gabriel Gomes de Jesus
@since 03/07/2018
/*/
//------------------------------------------------------------------------------------------
Static Function At890AtSld(oMdl,cTab,cCodTFG,nQuant,cAcao)
Local oView   	:= FwViewActive()
Local nX 		:= 0
Local nLineBkp	:= oMdl:GetLine()
Local nLin		:= oMdl:Length() 
Local lRet		:= .T.

If cTab == "TFS"
	For nX := 1 To nLin 
		oMdl:GoLine(nX)
			
		If  oMdl:GetValue("TFS_CODTFG") = cCodTFG //.And. oMdl:GetValue("TFS_SLDTTL") >= 0			
			If Empty(oMdl:GetValue("TFS_CODKIT"))
				If cAcao == "DELETE"
					nSld := oMdl:GetValue("TFS_SLDTTL") + nQuant  
				Else
					nSld := oMdl:GetValue("TFS_SLDTTL") - nQuant  
				EndIf
				If nSld >=0
					oMdl:LoadValue("TFS_SLDTTL",nSld)
				Else
					lRet := .F.
				EndIf			
			EndIf
		EndIf
	Next nX
ElseIf cTab == "TFT"
	For nX := 1 To nLin 
		oMdl:GoLine(nX)
			
		If  oMdl:GetValue("TFT_CODTFH") = cCodTFG //.And. oMdl:GetValue("TFT_SLDTTL") >= 0			
			If Empty(oMdl:GetValue("TFT_CODKIT"))
				If cAcao == "DELETE"
					nSld := oMdl:GetValue("TFT_SLDTTL") + nQuant  
				Else
					nSld := oMdl:GetValue("TFT_SLDTTL") - nQuant  
				EndIf
				If nSld >=0
					oMdl:LoadValue("TFT_SLDTTL",nSld)
				Else
					lRet := .F.
				EndIf			
			EndIf
		EndIf
	Next nX
EndIf

//Restaura a linha
oMdl:GoLine(nLineBkp)

If lRet
	oView:Refresh()
EndIf

Return lRet

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890ChkQtd
Fun��o de grava��o das linhas de apontamento

@param  oMdlRev, Objeto, Objeto do Model
@param  cAlias, Caracter, Alias da tabela
@param  nLine, Numerico, Numero da linha que est� sendo editado
@param  xVal, Caracter, Valor a ser editado
@param  cVal, Caracter, Valor a ser comparado

@return lRetorno, Logico, Se .T. indica que a quantidade informada n�o pode ser confirmada

@author Luiz Gabriel Gomes de Jesus
@since 03/07/2018
/*/
//------------------------------------------------------------------------------------------
Function At890ChkQtd(oMdlRev,cAlias,nLine,xVal,cVal)
Local lRet 		:= .T.
Local oMdlAp	:= NIL
Local oMdlTFL	:= NIL
Local cCod		:= ""
Local cProd 	:= ""
Local cCodTFL	:= ""
Local lRecor  	:= oMdlRev:GetModel("TFJ_REFER"):GetValue("TFJ_CNTREC") == "1" //Indica se o contrato � recorrente 1=Recorrente 2= N�o Recorrente
Local nSld		:= 0
Local lKit		:= .F.

Default nLine 	:= 0

If cAlias == "TFG"
	If oMdlRev <> Nil .And. ValType(oMdlRev) == 'O'
		If lRecor
			oMdlAp := oMdlRev:GetModel("TFG_MI")		
			oMdlTFL := oMdlRev:GetModel("TFL_LOC")
			cCodTFL := oMdlTFL:GetValue("TFL_CODIGO")		
			If oMdlAp <> Nil .And. (nLine > 0 .And. oMdlAp:Length() >= nLine)
				oMdlAp:GoLine(nLine)
				cProd := oMdlAp:GetValue("TFG_PRODUT")
				If Posicione("SB1",1,FwxFilial("SB1")+cProd,"B1_TIPO") == "KT"
					nSld := At890SldRec("TFS",oMdlAp:GetValue("TFG_COD"),.T.)
					If nSld > 0 .OR. xVal >= oMdlAp:GetValue("TFG_QTDVEN")
						nSld := oMdlAp:GetValue("TFG_QTDVEN") - nSld
					EndIf	
				Else
					nSld := At890SldRec("TFS",oMdlAp:GetValue("TFG_COD"))
					If nSld > 0 .OR. xVal >= oMdlAp:GetValue("TFG_QTDVEN")
						nSld := oMdlAp:GetValue("TFG_QTDVEN") - At890SldRec("TFS",oMdlAp:GetValue("TFG_COD"))
					EndIf	
				EndIf
				
				//N�o permite que altere para um quantidade menor do que j� foi apontado
				cVal := cValToChar(nSld)				
				If nSld >= 0
					lRet := (oMdlAp:GetValue("TFG_QTDVEN") - nSld) > xVal
				EndIf					 
			EndIf
		Else
			oMdlAp 	:= oMdlRev:GetModel("TFG_MI")
			If oMdlAp <> Nil .And. (nLine > 0 .And. oMdlAp:Length() >= nLine)
				oMdlAp:GoLine(nLine)
				//N�o permite que altere para um quantidade menor do que j� foi apontado				
				If oMdlAp:GetValue("TFG_SLD") > 0 .OR. xVal >= oMdlAp:GetValue("TFG_QTDVEN")
					cVal := cValToChar((oMdlAp:GetValue("TFG_QTDVEN") - oMdlAp:GetValue("TFG_SLD")))				
					lRet := (oMdlAp:GetValue("TFG_QTDVEN") - oMdlAp:GetValue("TFG_SLD")) > xVal
				EndIf						
			EndIf	
		EndIf
	EndIf

ElseIf cAlias == "TFH"
	If oMdlRev <> Nil .And. ValType(oMdlRev) == 'O'
		If lRecor
			oMdlAp := oMdlRev:GetModel("TFH_MC")		
			oMdlTFL := oMdlRev:GetModel("TFL_LOC")
			cCodTFL := oMdlTFL:GetValue("TFL_CODIGO")		
			If oMdlAp <> Nil .And. (nLine > 0 .And. oMdlAp:Length() >= nLine)
				oMdlAp:GoLine(nLine)
				cProd := oMdlAp:GetValue("TFH_PRODUT")
				If Posicione("SB1",1,FwxFilial("SB1")+cProd,"B1_TIPO") == "KT"
					nSld:= At890SldRec("TFT",oMdlAp:GetValue("TFH_COD"),.T.)
					If nSld > 0 .OR. xVal >= oMdlAp:GetValue("TFH_QTDVEN")
						nSld := oMdlAp:GetValue("TFH_QTDVEN") - nSld
					EndIf	
				Else
					nSld := At890SldRec("TFT",oMdlAp:GetValue("TFH_COD"))
					If nSld > 0 .OR. xVal >= oMdlAp:GetValue("TFH_QTDVEN")
						nSld := oMdlAp:GetValue("TFH_QTDVEN") - nSld
					EndIf	
				EndIf

				//N�o permite que altere para um quantidade menor do que j� foi apontado	
				cVal := cValToChar(nSld)
				If nSld > 0				
					lRet := nSld > xVal	
				EndIf				 
			EndIf
		Else
			oMdlAp 	:= oMdlRev:GetModel("TFH_MC")
			If oMdlAp <> Nil .And. (nLine > 0 .And. oMdlAp:Length() >= nLine)
				oMdlAp:GoLine(nLine)
				//N�o permite que altere para um quantidade menor do que j� foi apontado
				If oMdlAp:GetValue("TFH_SLD") > 0 .OR. xVal >= oMdlAp:GetValue("TFH_QTDVEN")
					cVal := cValToChar((oMdlAp:GetValue("TFH_QTDVEN") - oMdlAp:GetValue("TFH_SLD")))				
					lRet := (oMdlAp:GetValue("TFH_QTDVEN") - oMdlAp:GetValue("TFH_SLD")) > xVal
				EndIf	 				
			EndIf	
		EndIf
	EndIf
	
EndIf
	
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewErroMvc
@sample        ViewErroMvc( oObjMdl )
@param         oObjMdl, Objeto, Objeto Model
@return        NIL
@author        Luiz Gabriel

/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ViewErroMvc( oObjMdl, lExibeErro )

Local aErro	:= {}
Default lExibeErro := .F.

aErro := oObjMdl:GetErrorMessage()

If Len(aErro) > 0
	AutoGrLog( '[' + AllToChar( aErro[MODEL_MSGERR_IDFORMERR] ) + ']' )
	AutoGrLog( '[' + AllToChar( aErro[MODEL_MSGERR_IDFIELDERR] ) + ']' )
	AutoGrLog( '[' + AllToChar( aErro[MODEL_MSGERR_ID] ) + ']' )
	AutoGrLog( '[' + AllToChar( aErro[MODEL_MSGERR_MESSAGE] ) + '|' + AllToChar( aErro[MODEL_MSGERR_SOLUCTION] ) + ']' )
	
	If lExibeErro
		MostraErro()
	EndIf
EndIf

Return 

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890Peri
Fun��o para retornar o codigo do produto da TFG/TFH e se o mesmo tem periodicidade

@param  cCod, Caracter, Codigo da TFG ou TFH
@param  cCod, Caracter, Alias da Tabela a ser pesquisada

@return aRet, Array, aRet[1] - Codigo do Produto
					    aRet[2] - Informar se o produto tem periodicidade
					    aRet[3] - Quantidade de periodicidade do produto

@author Luiz Gabriel Gomes de Jesus
@since 08/08/2018
/*/
//------------------------------------------------------------------------------------------
Static Function At890Peri(cCod,cTab)
Local aRet 		:= {}
Local cAlias 		:= GetNextAlias()

If cTab == "TFG"
	BeginSql Alias cAlias
	
		SELECT
			TFG_COD,
			TFG_PRODUT,
			TFG_PERIOD,
			TFG_QTPERI			
			
			FROM %table:TFG% TFG
		
		WHERE
			TFG.TFG_FILIAL = %xFilial:TFG% AND
			TFG.TFG_COD = %Exp:cCod% AND  
			TFG.%NotDel% 
				
	EndSql
	
	If !(cAlias)->(Eof())					 	
		aAdd(aRet,{(cAlias)->TFG_PRODUT ,;
					 (cAlias)->TFG_PERIOD ,;
					 (cAlias)->TFG_QTPERI})
	EndIf
	
	(cAlias)->(DbCloseArea())
	
ElseIf cTab = "TFH"
	BeginSql Alias cAlias
	
		SELECT
			TFH_COD,
			TFH_PRODUT,
			TFH_PERIOD,
			TFH_QTPERI				
			
			FROM %table:TFH% TFH
		
		WHERE
			TFH.TFH_FILIAL = %xFilial:TFH% AND
			TFH.TFH_COD = %Exp:cCod% AND  
			TFH.%NotDel% 
	
	EndSql
	
	If !(cAlias)->(Eof())					 	
		aAdd(aRet,{(cAlias)->TFH_PRODUT ,;
					 (cAlias)->TFH_PERIOD ,;
					 (cAlias)->TFH_QTPERI})
	EndIf
	
	(cAlias)->(DbCloseArea())
	
EndIf

Return aRet

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890ApTFS
Fun��o para verificar se o item tem apontamento ativo

@param  cCodTF, Caracter, Codigo da TFG ou TFH
@param  cCodPrd, Caracter, Codigo do Produto
@param  cPeriod, Caracter, Periodo em meses que est� configurado a periodicidade
@param  cTab, Caracter, Codigo da tabela

@return lRet, Logico, Informa se tem apontamento ativo e que o mesmo est� no periodo de periodicidade

@author Luiz Gabriel Gomes de Jesus
@since 17/08/2018
/*/
//------------------------------------------------------------------------------------------
Static Function At890ApTFS(cCodTF,cCodPrd,cPeriod,cTab)
Local lRet	:= .T.
Local cProdut		:= ""
Local cCodTFG		:= ""
Local cAliasApo	:= GetNextAlias()
Local dData		:= cToD("")
Local dDataAp		:= cToD("")

//Verifica se o item tem apontamento ativo	
If cTab == "TFS"
		
	BeginSql Alias cAliasApo
	
		SELECT
		MAX(TFS.TFS_DTAPON) AS TFS_DTAPON
				
		FROM %table:TFS% TFS
			
		WHERE
		TFS.TFS_FILIAL = %xFilial:TFS% AND
		TFS.TFS_CODTFG = %Exp:cCodTF% AND
		TFS.TFS_PRODUT = %Exp:cCodPrd% AND
		TFS.%NotDel%
				
	EndSql
		
	If !(cAliasApo)->(Eof())
		dData := sTod((cAliasApo)->TFS_DTAPON)
	EndIf
	
	(cAliasApo)->(DbCloseArea())
		
	//Verifica a data que pode ser feito o proximo apontamento
	dDataAp	:= DaySum( dData, (cPeriod * 30))
		
	If dDataBase < dDataAp
		lRet := .F.   //N�o permite o apontamento
	EndIf
		
ElseIf cTab = "TFT"
	
	BeginSql Alias cAliasApo
	
		SELECT
		MAX(TFT.TFT_DTAPON) AS TFT_DTAPON
				
		FROM %table:TFT% TFT
			
		WHERE
		TFT.TFT_FILIAL = %xFilial:TFT% AND
		TFT.TFT_CODTFH = %Exp:cCodTF% AND
		TFT.TFT_PRODUT = %Exp:cCodPrd% AND
		TFT.%NotDel%
				
	EndSql
		
	If !(cAliasApo)->(Eof())
		dData := sTod((cAliasApo)->TFT_DTAPON)
	EndIf
	
	(cAliasApo)->(DbCloseArea())
		
	//Verifica a data que pode ser feito o proximo apontamento
	dDataAp	:= DaySum( dData, (cPeriod * 30))
		
	If dDataBase < dDataAp
		lRet := .F.   //N�o permite o apontamento
	EndIf
	
EndIf

Return lRet

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890APV
Fun��o para controlar o when do campo de aprovador

@param  cAliasMat, Caracter, Codigo da tabela

@return lRet, Logico, Informa se o campo ser� bloqueado ou n�o

@author Luiz Gabriel Gomes de Jesus
@since 17/08/2018
/*/
//------------------------------------------------------------------------------------------
Function At890APV(cAliasMat)
Local oModel     := FwModelActive()
Local oGrid      := oModel:GetModel(cAliasMat+"GRID")
Local lRet       := .F.

If oGrid:GetValue(cAliasMat+"_PERIOD") == "1" .And. oGrid:GetValue(cAliasMat+"_PEND") == "S"
	lRet := .T.
EndIf

Return lRet

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890VlUsr
Fun��o de valida��o do campo do usuario aprovador

@param  cAliasMat, Caracter, Codigo da tabela

@return lRet, Logico, Informa se tem apontamento ativo e que o mesmo est� no periodo de periodicidade

@author Luiz Gabriel Gomes de Jesus
@since 17/08/2018
/*/
//------------------------------------------------------------------------------------------
Function At890VlUsr(cAliasMat)
Local oView   	:= FwViewActive()
Local oGrid      := oView:GetModel(cAliasMat+"GRID")
Local lRet       := .F.

lRet := Vazio() .Or. UsrExist(oGrid:GetValue(cAliasMat+"_USRAPV"))

If lRet
	If cAliasMat == "TFS"
		//Atualiza a legenda
		oGrid:LoadValue("TFS_SIT" ,At890LgTFS(oGrid:GetValue('TFS_ITAPUR'),"N"))	
	Else
		//Atualiza a legenda
		oGrid:LoadValue("TFT_SIT" ,At890LgTFT(oGrid:GetValue('TFT_ITAPUR'),"N"))	
	EndIf
	
	If oView <> Nil	
		If oView:IsActive()
			oView:Refresh()
		Endif
	Endif
EndIf

Return lRet

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890Vig
Fun��o para validar que somente contratos vigentes podem ser apontados

@param  oModel, Objeto, Modelo de dados

@return lRet, Logico, Informa se o contrato est� vigente

@author Luiz Gabriel Gomes de Jesus
@since 18/10/2018
/*/
//------------------------------------------------------------------------------------------
Function At890Vig(oModel)
Local lRet	:= .T.
Local aArea	:= GetArea()

DbSelectArea("CN9")
CN9->(DbSetOrder(1))
If CN9->(DbSeek(xFilial('CN9')+ TFL->TFL_CONTRT + TFL->TFL_CONREV))
	If CN9->CN9_SITUAC <> '05'
		lRet := .F.
		Help( "", 1, STR0117, , STR0118, 1, 0,,,,,,{STR0119})//"Vigencia"##"O Contrato n�o est� vigente"##"Selecione um contrato vigente para apontamento"
	EndIf
EndIf
	
RestArea(aArea)

Return lRet

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890IncKit
Fun��o para incluir o kit no grid do vinculo com o funcionario

@param  oModelTFS, Objeto, Modelo de dados da tabela TFS
@param  oModelT4A, Objeto, Modelo de dados da tabela T4A

@author Luiz Gabriel Gomes de Jesus
@since 18/10/2018
/*/
//------------------------------------------------------------------------------------------
Static Function At890IncKit(oModelTFS,oModelT4A)
Local nX				:= 0
Local nY				:= 0
Local aProd			:= {}
Local nTam				:= 0
Local nLine			:= 0
Local nZ				:= 1
Local cSeqKit			:= ""
Local cCodKit			:= ""
Local nQtdKit			:= 0

Default oModelTFS 	:= Nil
Default oModelT4A		:= Nil

If Valtype(oModelTFS) == "O" .And. Valtype(oModelT4A) == "O"
	nLine 		:= oModelTFS:GetLine()
	cSeqKit 	:= oModelTFS:GetValue("TFS_SEQKIT")
	cCodKit	:= oModelTFS:GetValue("TFS_CODKIT")
	nQtdKit	:= oModelTFS:GetValue("TFS_QTDKIT")
	
	aProd := At890AdPro(oModelTFS,oModelT4A)
	
	oModelTFS:GoLine(nLine)
	nTam := Len(aProd)
	
	If (nTam > 0 .And. oModelT4A:Length() == 1)
		For nY := 1 To nQtdKit
			For nX := 1 To nTam
				oModelT4A:GoLine(nZ)
				oModelT4A:LoadValue('T4A_CODTFS', aProd[nX][1])
				oModelT4A:LoadValue('T4A_CODEPI', aProd[nX][2])
				oModelT4A:LoadValue('T4A_DESC'	, Posicione("SB1",1,xFilial("SB1")+aProd[nX][2],"B1_DESC"))
				oModelT4A:LoadValue('T4A_QTDENT', aProd[nX][3])
				oModelT4A:LoadValue('T4A_CODKIT', cCodKit)
				oModelT4A:LoadValue('T4A_SEQKIT', cValToChar(StrZero(nY,TamSX3("T4A_SEQKIT")[1])))
				If nZ < (nQtdKit * nTam)
					nZ := oModelT4A:AddLine() 
				EndIf	
			Next nX	
		Next nY	
	EndIf
	
	oModelT4A:GoLine(1)
	
EndIf

Return 

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890AdPro
Fun��o para adicionar os produtos do kit para o vinculo

@param  oModelTFS, Objeto, Modelo de dados da tabela TFS
@param  oModelT4A, Objeto, Modelo de dados da tabela T4A

@return aProd, Array, Retorna os produtos e outras informa��es do Kit

@author Luiz Gabriel Gomes de Jesus
@since 18/10/2018
/*/
//------------------------------------------------------------------------------------------
Static Function At890AdPro(oModelTFS,oModelT4A)
Local lSeek			:= .F.
Local nX				:= 0
Local nY				:= 0
Local nLine			:= 0
Local cSeqKit			:= ""
Local cCodKit			:= ""
Local aProd			:= {}
Local nTam				:= 0

Default oModelTFS 	:= Nil
Default oModelT4A		:= Nil

If Valtype(oModelTFS) == "O" .And. Valtype(oModelT4A) == "O"
	cSeqKit 	:= oModelTFS:GetValue("TFS_SEQKIT")
	cCodKit	:= oModelTFS:GetValue("TFS_CODKIT")
	
	lSeek := oModelTFS:SeekLine({{"TFS_CODKIT", cCodKit},{"TFS_SEQKIT", cSeqKit}})
	
	If lSeek
		For nX := oModelTFS:GetLine() To oModelTFS:Length()
			oModelTFS:GoLine(nX)
			If cCodKit == oModelTFS:GetValue("TFS_CODKIT") .And. cSeqKit == oModelTFS:GetValue("TFS_SEQKIT")
				aAdd(aProd,{oModelTFS:GetValue("TFS_CODIGO"),oModelTFS:GetValue("TFS_PRODUT"),(oModelTFS:GetValue("TFS_QUANT")/oModelTFS:GetValue("TFS_QTDKIT"))})
			EndIf
		Next nX
	EndIf
EndIf

Return aProd

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890VlSRA
Valid do campo T4A_MAT

@return lRet, Logico, Informa se os dados est�o corretos

@author Luiz Gabriel Gomes de Jesus
@since 18/10/2018
/*/
//------------------------------------------------------------------------------------------
Function At890VlSRA()
Local lRet 		:= .T.
Local cCodFunc	:= ""
Local lIsKit		:= Iif(!Empty(FwFldGet("T4A_CODKIT")) .And. !Empty(FwFldGet("T4A_SEQKIT")),.T.,.F.)
Local nX			:= 0
Local oView   	:= FwViewActive()
Local oModel		:= FwModelActive()
Local oModelTFS	:= oModel:GetModel('TFSGRID')
Local oModelT4A  	:= oModel:GetModel('T4AGRID')
Local cCodMat		:= oModelT4A:GetValue("T4A_MAT")
Local cSeqKit		:= oModelT4A:GetValue("T4A_SEQKIT")
Local nLine		:= 0
Local lSeek		:= .F.

lSeek := oModelT4A:SeekLine({{"T4A_CODKIT", oModelT4A:GetValue("T4A_CODKIT")},{"T4A_SEQKIT", oModelT4A:GetValue("T4A_SEQKIT")}})

nLine := oModelT4A:GetLine()

If lIsKit
	If ExistCpo("SRA")
		For nX := 1 To oModelT4A:Length()
			oModelT4A:GoLine(nX)
			If cSeqKit == oModelT4A:GetValue("T4A_SEQKIT") 
				oModelT4A:LoadValue('T4A_MAT', cCodMat)
				oModelT4A:LoadValue('T4A_NOME', Posicione("SRA",1,xFilial("SRA")+oModelT4A:GetValue("T4A_MAT"),"RA_NOME"))
			EndIf	
		Next nX
		oModelT4A:GoLine(nLine)
		oView:Refresh()
	EndIf
Else
	ExistCpo("SRA")
EndIf

Return lRet

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890SeekT4A
Posiciona sempre na primeira linha do apontamento de Kit

@param  oModelTFS, Objeto, Modelo de dados da tabela TFS
@param  oModelT4A, Objeto, Modelo de dados da tabela T4A

@return lRet, Logico, Informa se foi encontrado o item

@author Luiz Gabriel Gomes de Jesus
@since 18/10/2018
/*/
//------------------------------------------------------------------------------------------
Static Function At890SeekT4A(oModelTFS,oModelT4A)
Local lSeek			:= .F.
Local cSeqKit			:= ""
Local cCodKit			:= ""

Default oModelTFS 	:= Nil
Default oModelT4A		:= Nil

If Valtype(oModelTFS) == "O" .And. Valtype(oModelT4A) == "O"
	cSeqKit 	:= oModelTFS:GetValue("TFS_SEQKIT")
	cCodKit	:= oModelTFS:GetValue("TFS_CODKIT")
	
	lSeek := oModelTFS:SeekLine({{"TFS_CODKIT", cCodKit},{"TFS_SEQKIT", cSeqKit}})	
EndIf

Return

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890VinOk
Fun��o para validar o vinculo e os campos obrigatorios

@param  oModel, Objeto, Modelo de dados

@return lRet, Logico, Informa se os dados obrigatorios est�o preenchidos

@author Luiz Gabriel Gomes de Jesus
@since 18/10/2018
/*/
//------------------------------------------------------------------------------------------
Function At890VinOk(oModel)
Local lRet			:= .T.
Local oModelTFS	:= oModel:GetModel('TFSGRID')
Local oModelT4A  	:= oModel:GetModel('T4AGRID')
Local nX			:= 0

//Verifica se os campos est�o preenchidos
For nX := 1 To oModelT4A:Length()
	oModelT4A:GoLine(nX)
	If Empty(oModelT4A:GetValue("T4A_MAT")) .Or. Empty(oModelT4A:GetValue("T4A_FORNEC")) .Or. Empty(oModelT4A:GetValue("T4A_QTDENT"))
		lRet := .F.
		Help( "", 1, STR0120, , STR0121, 1, 0,,,,,,{STR0122})//"Obrigatorio"##"Campos Obrigatorios n�o est�o preenchidos"##"Verifique os campos T4A_MAT, T4A_FORNEC, T4A_QTDENT "
	EndIf
Next nX

Return lRet

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890Prod
Fun��o para validar o vinculo e os campos obrigatorios

@return cDesc, Caracter, Descri��o do produto

@author Luiz Gabriel Gomes de Jesus
@since 18/10/2018
/*/
//------------------------------------------------------------------------------------------
Function At890Prod()
Local cDesc	:= ""
Local oView  	:= FwViewActive()

cDesc := Posicione("SB1",1,xFilial("SB1") + FwFldGet("TFS_PRODUT"),"B1_DESC") 
oView:Refresh()

Return cDesc

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At890NCA
Fun��o para gatilhar o CA e a data de validade do EPI

@return cNum, Caracter, C�digo do CA e data de validade

@author Luiz Gabriel Gomes de Jesus
@since 18/10/2018
/*/
//------------------------------------------------------------------------------------------
Function At890NCA(lView)
Local cNum			:= ""
Local aArea		:= GetArea()
Local oModel 		:= FwModelActive()
Local oMdlTFS		:= oModel:GetModel('TFSGRID')
Local oModelT4A  	:= oModel:GetModel('T4AGRID')
Local cCond 		:= oMdlTFS:GetValue('TFS_CODTFG')
Local cProdPdr	:= At890PrdPad( cCond, 'TFS', oMdlTFS:GetValue('TFS_PRODUT') )
Local oView  		:= FwViewActive()
Local lAtualiza	:= .F.

Default lView		:= .F.

DbSelectArea("TN3")
TN3->(DbSetOrder(1))

DbSelectArea("TWY")
TWY->(DbsetOrder(1))

If !Empty(cProdPdr) .And. oModelT4A:IsActive() .And. !Empty(oModelT4A:aDataModel)
	lAtualiza := .T.
	If TWY->(DbSeek(FwxFilial("TWY") + cProdPdr ))
	          
		If TN3->(DbSeek(xFilial("TN3") + oModelT4A:GetValue("T4A_FORNEC") + oModelT4A:GetValue("T4A_LOJA") + cProdPdr))
			If TN3->TN3_GENERI == "2"
				DbSelectArea("TL0")
				TL0->(DbSetOrder(1))
				
				If TL0->(DbSeek(xFilial("TL0")+cProdPdr + oModelT4A:GetValue("T4A_FORNEC") + oModelT4A:GetValue("T4A_LOJA") + oModelT4A:GetValue("T4A_CODEPI")))
					cNum := TL0->TL0_NUMCAP
					oModelT4A:LoadValue("T4A_DTVENC",TL0->TL0_DTVENC)
				EndIf
			Else
				cNum := TN3->TN3_NUMCAP
				oModelT4A:LoadValue("T4A_DTVENC",TN3->TN3_DTVENC)
			EndIf
		EndIf
	
	Else
		             
		cNum := Posicione("TN3",1,xFilial("TN3") + oModelT4A:GetValue("T4A_FORNEC") + oModelT4A:GetValue("T4A_LOJA") + oModelT4A:GetValue("T4A_CODEPI"),"TN3_NUMCAP")
		oModelT4A:LoadValue("T4A_DTVENC",TN3->TN3_DTVENC)
	EndIf
EndIf

If lView
	If ValType(oView) == "O" .And. lAtualiza	
		If oView:IsActive() .And. OVIEW:ACURRENTSELECT[1] == "VIEW_T4A"
			oView:Refresh("VIEW_T4A")
		Endif
	Endif
EndIf

RestArea(aArea)

Return cNum