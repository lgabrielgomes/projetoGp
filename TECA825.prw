#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'FWBROWSE.CH'
#INCLUDE 'LOCACAO.CH'
#INCLUDE 'TECA825.CH'

STATIC lPEDatas  := ExistBlock('AT850DTR')
STATIC dDtIniAt  := CTOD('')
STATIC dDtFimAt  := CTOD('')
STATIC lAltData  := .F.
STATIC aCompKit  := {}
STATIC lResKit   := .F.
STATIC aResVld   := {}
STATIC lUsePerg  := .F.

//------------------------------------------------------------------------------
/*/{Protheus.doc} TECA825
	Visualizar dos registros de movimentação dos equipamentos
@sample 	TECA825()
@since		11/03/2014       
@version	P12
@param  	cFilter, caracter, conteúdo padrão para filtro dos dados no browse
/*/
//------------------------------------------------------------------------------
Function TECA825( cFilter )

Local oBrwReserva := FwMBrowse():New()

DEFAULT cFilter := ""

Private aDtsPE

oBrwReserva:SetAlias( 'TEW' )
oBrwReserva:SetMenudef( "TECA825" )
oBrwReserva:SetDescription( OEmToAnsi( STR0001 ) ) // 'Reservas'
If !Empty( cFilter )
	oBrwReserva:SetFilterDefault( "TEW->TEW_TIPO == '2' " .And. cFilter )
Else
	oBrwReserva:SetFilterDefault( "TEW->TEW_TIPO == '2' ")
EndIf

//----------- // Adicionando filtros padrões para a rotina
oBrwReserva:AddFilter( STR0001, "TEW->TEW_MOTIVO == '"+DEF_RESERVA+"'" ) // "Reservas"
oBrwReserva:AddFilter( STR0002, "TEW->TEW_MOTIVO == '"+DEF_RES_CANCELADA+"'" )//  "Reservas Canceladas"
oBrwReserva:AddFilter( STR0003, "TEW->TEW_MOTIVO == '"+DEF_RES_EFETIVADA+"'" )//  "Reservas Efetivadas"
oBrwReserva:AddFilter( STR0004, "TEW->TEW_MOTIVO == '"+DEF_RES_ENVIADA+"'" )//  "Reservas Separadas"

//----------- // Adicionando legendas 
oBrwReserva:AddLegend( "TEW->TEW_MOTIVO == '"+DEF_RESERVA+"'",       "BLUE",   STR0001 )  // "Reservas"
oBrwReserva:AddLegend( "TEW->TEW_MOTIVO == '"+DEF_RES_CANCELADA+"'", "RED",    STR0002 )  // "Reservas Canceladas"
oBrwReserva:AddLegend( "TEW->TEW_MOTIVO == '"+DEF_RES_EFETIVADA+"'", "YELLOW", STR0003 )  // "Reservas Efetivadas"
oBrwReserva:AddLegend( "TEW->TEW_MOTIVO == '"+DEF_RES_ENVIADA+"'",   "GRAY",   STR0004 )  // "Reservas Enviadas"


oBrwReserva:DisableDetails()
oBrwReserva:Activate()

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} Menudef
	Menu da rotina
@sample 	Menudef()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function Menudef()

Local aMenu := {}

aAdd(aMenu,{ STR0005 , 'PesqBrw'         , 0 , 1, 0, .T. } ) // 'Pesquisar'
aAdd(aMenu,{ STR0006 , 'At825Vis'        , 0 , 2, 0, .T. } ) // 'Visualizar'
aAdd(aMenu,{ STR0007 , 'At825Inc'        , 0 , 3, 0, .F. } ) // 'Incluir'
aAdd(aMenu,{ STR0008 , 'At825Canc'       , 0 , 4, 0, .F. } ) // 'Cancelar'
aAdd(aMenu,{ STR0009 , 'At825BEnc'       , 0 , 4, 0, .F. } ) // 'Encerrar Reservas'
aAdd(aMenu,{ STR0010 , 'At825BFor'       , 0 , 4, 0, .F. } ) // 'Forçar Liberação de Reservas'

Return aMenu

//------------------------------------------------------------------------------
/*/{Protheus.doc} At825Vis
	Função para vsualização, selecionando os itens da TFI
@sample 	At825Vis()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Function At825Vis( cAlias, nReg, nOpc )

Local aSave     := GetArea()
Local aSaveTFI  := TFI->( GetArea() )
Local lExibe    := .F.

DbSelectArea('TFI')
TFI->( DbSetOrder( 6 ) ) // TFI_FILIAL+TFI_RESERV

If TFI->( Dbseek( xFilial('TFI')+TEW->TEW_RESCOD ) )
	lExibe    := .T.
Else
	TFI->( DbSetOrder( 1 ) ) // TFI_FILIAL+TFI_COD
	
	If TFI->( Dbseek( xFilial('TFI')+TEW->TEW_CODEQU ) )
		lExibe    := .T.
	EndIf

EndIf

If lExibe
	FWExecView( STR0001,'VIEWDEF.TECA825C', MODEL_OPERATION_VIEW, /*oDlg*/, {||.T.} /*bCloseOk*/, ;  // 'Reservas' 
									{||.T.}/*bOk*/,/*nPercRed*/,/*aButtons*/, {||.T.}/*bCancel*/ )
EndIf

RestArea(aSaveTFI)
RestArea(aSave)

Return Nil

//------------------------------------------------------------------------------
/*/{Protheus.doc} At825Canc
	Função para cancelamento, selecionando os itens da TFI
@sample 	At825Canc()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Function At825Canc( cAlias, nReg, nOpc )

Local aSave     := GetArea()
Local aSaveTFI  := TFI->( GetArea() )

If TEW->TEW_MOTIVO == DEF_RESERVA .OR. TEW->TEW_MOTIVO == DEF_RES_EFETIVADA
	DbSelectArea('TFI')
	TFI->( DbSetOrder( 6 ) ) // TFI_FILIAL+TFI_RESERV
	
	If TFI->( Dbseek( xFilial('TFI')+TEW->TEW_RESCOD ) )
	
		At825CText( STR0011 ) // 'Cancelado pelo usuário'
		At825CTipo( DEF_RES_CANCELADA )
	
		FWExecView( STR0012,'VIEWDEF.TECA825C', MODEL_OPERATION_UPDATE, /*oDlg*/, {||.T.} /*bCloseOk*/, ;  // 'Cancelamento de Reserva' 
										{||.T.}/*bOk*/,/*nPercRed*/,/*aButtons*/, {||.T.}/*bCancel*/ )
	
	EndIf
Else
	Help(,,'AT825CANC',,STR0013,1,0)  // 'Reserva não pode sofrer o cancelamento'
EndIf

RestArea(aSave)
RestArea(aSaveTFI)

Return Nil

//------------------------------------------------------------------------------
/*/{Protheus.doc} At825Inc
	Função para inclusão, selecionando os itens da TFI
@sample 	At825Inc()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Function At825Inc( cAlias, nReg, nOpc )

If Pergunte('TEC825', .T.)
	lUsePerg := .T.
	At825Res()
EndIf

Return Nil

//------------------------------------------------------------------------------
/*/{Protheus.doc} At825Res
	Exibe a sequência de janelas para realização da reserva
@sample 	At825Res()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Function At825Res()

Local lConfirm	:= .F.
Local aSave		:= GetArea()
Local aSaveTFI	:= TFI->( GetArea() )
Local aSaveTFL	:= TFL->( GetArea() )
Local aSaveTFJ	:= TFJ->( GetArea() )
Local aSaveADY	:= ADY->( GetArea() )
Local xAux		:= Nil
Local lSrvExt    := If(ValType(MV_PAR06) <> "U",MV_PAR06 == 1,.F.)
Local cGrpCom	:= ""
Local cTxt		:= ""
Local aButtons	:= {	{.F.,Nil},;		//- Copiar
							{.F.,Nil},;	//- Recortar
							{.F.,Nil},;	//- Colar
							{.F.,Nil},;	//- Calculadora
							{.F.,Nil},;	//- Spool
							{.F.,Nil},;	//- Imprimir
							{.T.,Nil},;	//- Confirmar
							{.T.,Nil},;	//- Cancelar
							{.F.,Nil},;	//- WalkThrough
							{.F.,Nil},;	//- Ambiente
							{.F.,Nil},;	//- Mashup
							{.F.,Nil},;	//- Help
							{.F.,Nil},;	//- Formulário HTML
							{.F.,Nil};	//- ECM
						}

aDtsPE := {}

lConfirm := ( FWExecView( STR0014,'VIEWDEF.TECA825A', MODEL_OPERATION_UPDATE, /*oDlg*/, {||.T.} /*bCloseOk*/, ;  // 'Item da Locação' 
									{||.T.}/*bOk*/,20/*nPercRed*/,aButtons, {||.T.}/*bCancel*/ ) == 0 )

If lConfirm
	
	DbSelectArea('TFI')
	DbSetOrder(1) // TFI_FILIAL + TFI_COD

	DbSelectArea('TFL')
	DbSetOrder(1) // TFL_FILIAL + TFL_CODIGO
	
	DbSelectArea('TFJ')
	DbSetOrder(1)  // TFJ_FILIAL + TFJ_CODIGO

	DbSelectArea('ADY')
	DbSetOrder(1) // ADY_FILIAL + ADY_PROPOS + ADY_PREVIS
	
	If TFI->( DbSeek( At825AGetKey() ) ) .And. ;  // posiciona no item selecionado
		TFL->( DbSeek( xFilial('TFL')+TFI->TFI_CODPAI ) ) .And. ;  // identifica o local associado da venda
		TFJ->( DbSeek( xFilial('TFJ')+TFL->TFL_CODPAI ) ) .And. ;  // posiciona nos dados do cabeçalho do orçamento
		If(lSrvExt,.T.,ADY->( DbSeek( xFilial('ADY')+TFJ->(TFJ_PROPOS+TFJ_PREVIS) ) ))  // posiciona na proposta comercial relacionada
		
		//--------------------------
		//  Executa o PE e caso não identifique o retorno
		// faz o processo normal
		If lPEDatas
			xAux := ExecBlock('AT850DTR',.F.,.F., {TFI->TFI_COD,;					// Código do item da TFI
			                                       TFI->TFI_PRODUT,;				// código produto
			                                       TFJ->TFJ_ENTIDA,;				// Tipo da entidade
			                                       TFJ->(TFJ_CODENT+TFJ_LOJA),;	// Código do Cliente/Prospect+Loja
			                                       __cUserId,;						// código Usuário
					                               If(lSrvExt,"",ADY->ADY_VEND)	  ,; 	// código Vendedor
			                                       TFI->TFI_PERINI,;				// Data de início da locação
			                                       TFI->TFI_PERFIM,;				// Data de término da locação
			                                       TFI->TFI_TOTAL})					// valor total do item da locação
			
			If Len(xAux)==2
				aDtsPE := { xAux[1], xAux[2] }
			Else
				aDtsPE := { TFI->TFI_PERINI, TFI->TFI_PERFIM }
			EndIf
		Else
			aDtsPE := { TFI->TFI_PERINI, TFI->TFI_PERFIM }
		EndIf
		
		cGrpCom  := TFJ->TFJ_GRPCOM
		cTxt := "<b>" + STR0032 + "</b>" + TFJ->TFJ_PROPOS //"Num. Proposta: " 
		cTxt += "<b>" + STR0033 + "</b>" + TFI->TFI_PRODUT //"Cod. Produto: " 
		cTxt += "<b>" + STR0034 + "</b>" + AllTrim(Posicione("SB1",1,xFilial("SB1")+TFI->TFI_PRODUT,"B1_DESC")) + "<br>" // "Descrição: "
		
		lConfirm := ( FWExecView( STR0001,'VIEWDEF.TECA825', MODEL_OPERATION_UPDATE, /*oDlg*/, {||.T.} /*bCloseOk*/, ;  // 'Reservas' 
									{||.T.}/*bOk*/,/*nPercRed*/,/*aButtons*/, {||.T.}/*bCancel*/ ) == 0 )
		
		If lConfirm .AND. !Empty(cGrpCom)
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³SIGATEC WorkFlow # RE - Reserva de Equipamentos     ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			At774Mail("TFJ",cGrpCom,"RE",cTxt)
		Endif
	Else
		Help(,,'AT825TFI',,STR0015,1,0)  // 'Item de Locação não identificado' 
	EndIf
EndIf

RestArea(aSaveADY)
RestArea(aSaveTFJ)
RestArea(aSaveTFL)
RestArea(aSaveTFI)
RestArea(aSave)

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
	Cria o modelo de dados para realizar a reserva dos itens (seleção do equipamentos)
@sample 	ModelDef()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function ModelDef()
Local oModel    := Nil
Local oStr1     := FWFormStruct(1,'TFI',{|cCpo|At825CpTFI(Alltrim(cCpo))})
Local oStr2     := FWFormStruct(1,'AA3',{|cCpo|CposAA3(cCpo)})
Local oStr3     := FWFormStruct(1,'AA3',{|cCpo|CposAA3(cCpo)})

oModel := MPFormModel():New('TECA825',,,{|oMdlFull| At825Grv( oMdlFull) },{|| lUsePerg := .F., .T. })
oModel:SetDescription(STR0016) // 'Reserva de Equipamentos'

oStr1:SetProperty('TFI_DESCRI', MODEL_FIELD_INIT , {||Posicione('SB1',1,xFilial('SB1')+TFI->TFI_PRODUT,'B1_DESC')})

oStr1:AddField(STR0017, STR0017, 'TFI_RESINI', 'D', 8, 0,; // 'Início Reserva' ### 'Início Reserva'
			{|oMdl, cCampo, xValueNew, nLine, xValueOld| lAltData := .T., xValueNew >= dDataBase .And. xValueNew <= oMdl:GetValue('TFI_RESFIM') } ,{||!ExistBlock('AT850DTR')} , {}, .T.,{||At825DtIni(1)} , .F., .F., .T., , )

oStr1:AddField(STR0018, STR0018, 'TFI_RESFIM', 'D', 8, 0,;  // 'Final Reserva' ### 'Final Reserva'
			{|oMdl, cCampo, xValueNew, nLine, xValueOld| lAltData := .T., xValueNew >= oMdl:GetValue('TFI_RESINI') },{||!ExistBlock('AT850DTR')} , {}, .T.,{||At825DtIni(2)} , .F., .F., .T., , )

// Adiciona o Campo tipo de Frete
oStr1:AddField( 'Tipo Frete', ; // cTitle // 'Mark'
				'Tipo de Frete', ; // cToolTip // 'Mark'
				'TFI_XTPFRETE', ; // cIdField
				'C', ; // cTipo
				3, ; // nTamanho
				0, ; // nDecimal
				{|| .T.}, ; // bValid
				{|| .F.}, ; // bWhen
				Nil, ; // aValues
				Nil, ; // lObrigat
				{|oMdlTFIP,cField|At825CTpFr(oMdlTFIP,cField)}, ; // bInit
				Nil, ; // lKey
				.T., ; // lNoUpd
				.T. ) // lVirtual

oStr2:SetProperty('*', MODEL_FIELD_WHEN , {||.T.} )
oStr2:SetProperty('*', MODEL_FIELD_VALID, {||.T.} )
oStr2:SetProperty('*', MODEL_FIELD_INIT , Nil )

oStr3:SetProperty('*', MODEL_FIELD_WHEN , {||.T.} )
oStr3:SetProperty('*', MODEL_FIELD_VALID, {||.T.} )
oStr3:SetProperty('*', MODEL_FIELD_INIT , Nil )

oStr2:AddField(STR0019,STR0019, 'AA3_FLAG', 'L', 1, 0, ; // 'Mark' ### 'Mark'
	{|oMdl, cCampo, xValueNew, nLine, xValueOld| vldMark(oMdl, cCampo, xValueNew, nLine, xValueOld) }, , {}, .F., {||.F.}, .F., .F., .T., , )

// cabeçalho da TFI
oModel:AddFields('CAB_TFI',,oStr1)

// Cria o vínculo do grid com o cabeçalho e inibe a incialização do grid pelo relation
oModel:AddGrid('GRD_AA3','CAB_TFI',oStr2,,,,,{|oMdlGrid|At825AA3Load( oMdlGrid )})  

oModel:AddGrid('GRD_AA3NID','CAB_TFI',oStr3,,,,,{|oMdlGrid|At825AA3Grn( oMdlGrid )})

// Adiciona o campo para receber o valor da quantidaade disponivel para locação.
oStr3:AddField( "Qtd. Disp.",;                     // cTitle // "Qtd. Disp."
                "Quantidade Disponível",;          // cTitle // "Quantidade Disponível"
                "AA3_QTDDSP",;                     // cIdField
                "N",;                              // cTipo
                TamSx3("N1_QUANTD")[1],;           // nTamanho
                0,;                                // nDecimal
                Nil,;                              // bValid
                Nil,;                              // bWhen
                Nil,;                              // aValues
                Nil,;                              // lObrigat
                Nil,;
                Nil,;                              // lKey
                .F.,;                              // lNoUpd
                .T. )                              // lVirtual

// Adiciona o campo para receber o valor da quantidaade da reserva para locação.
oStr3:AddField( "Qtd. Reserva",;                  // cTitle // "Qtd. Separação"
                "Quantidade Separado",;        	   // cTitle // "Quantidade aa Separação"
                "AA3_QTDRES",;                      // cIdField
                "N",;                              // cTipo
                TamSx3("N1_QUANTD")[1],;           // nTamanho
                0,;                                // nDecimal
                {|oMdlGRD, cCmp, xValueNew, nLi , xValueOld| At825VldRes(oMdlGRD, cCmp, xValueNew, nLi , xValueOld )},;// bValid,;							   // bValid
                Nil,;				   			   // bWhen
                Nil,;                              // aValues
                Nil,;                              // lObrigat
                Nil,;					           // bInit
                Nil,;                              // lKey
                .F.,;                              // lNoUpd
                .T. )                              // lVirtual

oModel:GetModel('GRD_AA3'):SetDescription(STR0020) // 'Equipamentos'

oModel:GetModel('GRD_AA3'):SetOptional(.T.)
oModel:GetModel('GRD_AA3NID'):SetOptional(.T.)

oModel:GetModel('GRD_AA3NID'):SetDescription("Sem ID único") // 'Item da Locação'
oModel:GetModel('CAB_TFI'):SetDescription(STR0014) // 'Item da Locação'

oModel:GetModel('CAB_TFI'):SetOnlyQuery(.F.)
oModel:GetModel('GRD_AA3'):SetOnlyQuery(.T.)

oModel:getModel('GRD_AA3'):SetNoDeleteLine(.T.)
oModel:getModel('GRD_AA3'):SetNoInsertLine(.T.)

oModel:SetActivate( {|oModel| At825AtSld( oModel ) } )

Return oModel

//------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
	Cria a interface para realizar a reserva dos itens (seleção do equipamentos)
@sample 	ViewDef()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function ViewDef()
Local oView    := Nil
Local oModel	:= ModelDef()
Local oStr1    := FWFormStruct(2, 'TFI',{|cCpo|Alltrim(cCpo)$'TFI_FILIAL+TFI_COD+TFI_PRODUT+TFI_DESCRI+TFI_QTDVEN+TFI_TOTAL+TFI_PERINI+TFI_PERFIM'})
Local oStr2    := FWFormStruct(2, 'AA3',{|cCpo|CposAA3(cCpo)})
Local oStr3    := FWFormStruct(2, 'AA3',{|cCpo|CposAA3(cCpo)})

oView := FWFormView():New()

oView:SetModel(oModel)

oStr1:SetProperty( '*', MVC_VIEW_CANCHANGE, .F. )
oStr2:SetProperty( '*', MVC_VIEW_CANCHANGE, .F. )
oStr3:SetProperty( '*', MVC_VIEW_CANCHANGE, .F. )

oStr3:AddField( "AA3_QTDDSP",;           // cIdField
                "08",;                   // cOrdem
                "Qtd. Disp.",;           // cTitulo  //"Qtd. Disp."
                "Quantidade Disponível",;// cDescric //"Quantidade Disponível"
                {""},;                   // aHelp
                'GET',;                  // cType
                PesqPict("TFI","TFI_QTDVEN"),;// cPicture
                Nil,;                    // nPictVar
                Nil,;                    // Consulta F3
                .F.,;                    // lCanChange
                '02',;                   // cFolder
                Nil,;                    // cGroup
                Nil,;                    // aComboValues
                Nil,;                    // nMaxLenCombo
                Nil,;                    // cIniBrow
                .T.,;                    // lVirtual
                Nil )                    // cPictVar

oStr3:AddField( "AA3_QTDRES",;           // cIdField
                "09",;                  // cOrdem
                "Qtd. Reserv",;       // cTitulo  //"Qtd. Disp."
                "Quantidade Reserva",;// cDescric //"Quantidade Disponível"
                {""},;                   // aHelp
                'GET',;                  // cType
                PesqPict("TFI","TFI_QTDVEN"),;// cPicture
                Nil,;                    // nPictVar
                Nil,;                    // Consulta F3
                .T.,;                    // lCanChange
                '02',;                   // cFolder
                Nil,;                    // cGroup
                Nil,;                    // aComboValues
                Nil,;                    // nMaxLenCombo
                Nil,;                    // cIniBrow
                .T.,;                    // lVirtual
                Nil )                    // cPictVar

oStr1:AddGroup('GROUP1',STR0014,'',2)  // 'Item da Locação'
oStr1:AddGroup('GROUP2',STR0021,'',2) // 'Período Reserva'

oStr1:AddField('TFI_XTPFRETE',;				// cIdField
               '08',;					// cOrdem
               'Tipo Frete',;					// cTitulo // 'Mark'
               'Tipo de Frete',;					// cDescric // 'Mark'
               {'Tipo de Frete', 'Tipo de frete (Branco), CIF ou FOB'},;	// aHelp : 'Marque os itens que deseja realizar  ' ### 'a reserva dos equipamentos '    
               '',;					// cType
               '@!',;					// cPicture
               Nil,;						// nPictVar
               Nil,;						// Consulta F3
               .F.,;						// lCanChange
               '01',;					// cFolder
               Nil,;						// cGroup
               Nil,;						// aComboValues
               Nil,;						// nMaxLenCombo
               Nil,;						// cIniBrow
               .T.,;						// lVirtual
               Nil )						// cPictVar

oStr1:SetProperty('*',MVC_VIEW_GROUP_NUMBER,'GROUP1')

oView:CreateHorizontalBox( 'BOXFORM1', 30)
oView:CreateHorizontalBox( 'BOXFORM2', 05)
oView:CreateHorizontalBox( 'BOXFORM3', 65)

oView:CreateFolder("FOLDER","BOXFORM3")                                 //-- cria uma pasta no box inferior
oView:AddSheet("FOLDER","FLDCOD1","Equip. ID único")
oView:AddSheet("FOLDER","FLDCOD2","Equip. ID não único ")

oView:CreateHorizontalBox('COMID',100,,,"FOLDER","FLDCOD1")
oView:CreateHorizontalBox('SEMID'  ,100,,,"FOLDER","FLDCOD2")

oStr1:AddField( 'TFI_RESINI','22',STR0017,STR0017,, 'GET' ,,,,,,'GROUP2',,,,.T.,, )  // 'Início Reserva' ### 'Início Reserva' 
oStr1:AddField( 'TFI_RESFIM','23',STR0018,STR0018,, 'GET' ,,,,,,'GROUP2',,,,.T.,, )  // 'Final Reserva' ### 'Final Reserva'

oStr2:AddField( 'AA3_FLAG','01',STR0019,STR0019,, 'CHECK' ,,,,,,,,,,.T.,, )  // 'Mark' ### 'Mark'
oStr2:SetProperty( 'AA3_FILORI', MVC_VIEW_ORDEM, '02' )

oStr3:SetProperty( 'AA3_FILORI', MVC_VIEW_ORDEM, '02' )

oView:AddField('CABEC' , oStr1,'CAB_TFI' )
oView:AddGrid('GRID' , oStr2,'GRD_AA3')
oView:AddGrid('GRIDNID' , oStr3,'GRD_AA3NID')
oView:AddOtherObject('OTHER',{|oPanel,oView| At825AddBt(oPanel,oView)})  

oView:SetOwnerView('CABEC','BOXFORM1')
oView:SetOwnerView('OTHER','BOXFORM2')
oView:SetOwnerView('GRID','COMID')
oView:SetOwnerView('GRIDNID','SEMID')

Return oView

//------------------------------------------------------------------------------
/*/{Protheus.doc} At825CpTFI
	Definição dos campos que não serão exibidos na estrutura da View
@sample 	At825CpTFI( cField )
@since		01/09/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Function At825CpTFI(cCpo)

Local aFldNotVw	:= {"TFI_ITEM",   "TFI_SEPSLD", "TFI_HORAIN", "TFI_HORAFI", "TFI_DESCON", "TFI_VALDES", "TFI_TES",;
	                  "TFI_SEPARA", "TFI_CONREV", "TFI_CODSUB", "TFI_OK",     "TFI_CODTGQ", "TFI_ITTGR",;
	                  "TFI_CODATD", "TFI_NOMATD", "TFI_ENCE",   "TFI_APUMED", "TFI_CHVTWO", "TFI_DTPFIM"}

Return (aScan(aFldNotVw, {|x| x == cCpo}) == 0)

//------------------------------------------------------------------------------
/*/{Protheus.doc} CposAA3
	Seleciona os campos para exibir no grid dos equipamentos
@sample 	CposAA3()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Function CposAA3(cCpo)

Local lAdd := .F.

lAdd := !lAdd .And. Alltrim(cCpo)$'AA3_FILIAL+AA3_CODPRO+AA3_DESPRO+AA3_NUMSER+AA3_CBASE+AA3_ITEM+AA3_CHAPA+AA3_MODELO+AA3_MANPRE+AA3_FILORI'

Return lAdd

//------------------------------------------------------------------------------
/*/{Protheus.doc} At825DtIni
	Inicializador padrão para as datas da reserva
@sample 	At825DtIni()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Function At825DtIni( nData )

Local dRet := aDtsPE[nData]

Return dRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At825ACharge
	Carrega as informações no grid dos equipamentos
@sample 	At825ACharge()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Function At825ACharge( oView )

Local oMdlFull   := oView:GetModel()
Local dDtIni     := oMdlFull:GetModel('CAB_TFI'):GetValue('TFI_RESINI')
Local dDtFim     := oMdlFull:GetModel('CAB_TFI'):GetValue('TFI_RESFIM')
Local oViewFull  := FwViewActive()  // captura a view completa quando é executada a rotina

//---------------------------------
//   Quando a atualização é requerida pelo botão

	// ------------------------------------------
	//  salve de forma 'static' para conseguir acessar o conteúdo
	// quando passar no formato de reinicialização
	dDtIniAt := dDtIni
	dDtFimAt := dDtFim
	
	//-----------------------------------------------
	//  Desativa os dados do model completo e reativa para 
	// considerar as informações do novo filtro
	oMdlFull:CancelData()
	oMdlFull:DeActivate()
	oMdlFull:Activate()
	
	oMdlFull:GetModel('CAB_TFI'):SetValue('TFI_RESINI',dDtIni)
	oMdlFull:GetModel('CAB_TFI'):SetValue('TFI_RESFIM',dDtFim)
	
	dDtIniAt := CTOD('')
	dDtFimAt := CTOD('')

//-----------------------------------
//  Atualiza o trecho de grid da view
oViewFull:Refresh('GRD_AA3')

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At825AddBt
	Adiciona o botão no panel do outro objeto
@sample 	At825AddBt()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Function At825AddBt(oPanel,oView)

Local bChargeGrd := {|| At825ACharge( oView, .T. ), lAltData := .F. }
Local oBtnAtual	 := TButton():New( 3, 3, STR0022, oPanel, bChargeGrd, 045,,,,,.T.,,,,,,, )	//'Carregar Equip.' 

Return 

//------------------------------------------------------------------------------
/*/{Protheus.doc} At825AA3Load
	Carrega os dados do grid de equipamentos
@sample 	At825AA3Load()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function At825AA3Load( oMdlgrid )

Local aRet    	  := {}
Local cTmpQry     := ''
Local dDtIni      := CTOD('')
Local dDtFim      := CTOD('')
Local xProdSel    := Nil

If dDtIniAt <> CTOD('') .And. dDtFimAt <> CTOD('')
	dDtIni := dDtIniAt
	dDtFim := dDtFimAt
Else
	dDtIni := At825DtIni(1)
	dDtFim := At825DtIni(2)
EndIf

If ( lResKit := At810IsKit( xFilial('TEZ')+TFI->TFI_PRODUT ) )
	aCompKit := At810GetKit( xFilial('TEZ')+TFI->TFI_PRODUT )
	xProdSel := {}
	aResVld  := {}
	AEval( aCompKit, {|x| aAdd( xProdSel, x[1] ) } )
	AEval( aCompKit, {|x| aAdd( aResVld, { x[1], (x[2]*TFI->TFI_QTDVEN), 0 } ) } )
Else
	aCompKit := {}
	aResVld  := { { TFI->TFI_PRODUT, TFI->TFI_QTDVEN, 0 } }
	xProdSel := TFI->TFI_PRODUT
EndIf

cTmpQry := At180xDisp( xProdSel, dDtIni, dDtFim )

aRet := FwLoadByAlias( oMdlgrid, cTmpQry )

(cTmpQry)->(DbCloseArea())

Return aRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At825AA3Grn
	Carrega os dados do grid de equipamentos
@sample 	At825AA3Load()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function At825AA3Grn( oMdlgrid )

Local aRet    	  	:= {}
Local cTmpQry     	:= ''
Local dDtIni      	:= CTOD('')
Local dDtFim      	:= CTOD('')
Local xProdSel    	:= Nil
Local oTecProvider	:= TecProvider():New()

If dDtIniAt <> CTOD('') .And. dDtFimAt <> CTOD('')
	dDtIni := dDtIniAt
	dDtFim := dDtFimAt
Else
	dDtIni := At825DtIni(1)
	dDtFim := At825DtIni(2)
EndIf

If ( lResKit := At810IsKit( xFilial('TEZ')+TFI->TFI_PRODUT ) )
	aCompKit := At810GetKit( xFilial('TEZ')+TFI->TFI_PRODUT )
	xProdSel := {}
	aResVld  := {}
	AEval( aCompKit, {|x| aAdd( xProdSel, x[1] ) } )
	AEval( aCompKit, {|x| aAdd( aResVld, { x[1], (x[2]*TFI->TFI_QTDVEN), 0 } ) } )
Else
	aCompKit := {}
	aResVld  := { { TFI->TFI_PRODUT, TFI->TFI_QTDVEN, 0 } }
	xProdSel := TFI->TFI_PRODUT
EndIf


cTmpQry := oTecProvider:SelectNotId(TFI->TFI_COD)

aRet := FwLoadByAlias( oMdlgrid, cTmpQry )

(cTmpQry)->(DbCloseArea())

FreeObj(oTecProvider)

Return aRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} vldMark
	Valida a seleção dos itens
@sample 	vldMark()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function vldMark(oMdl, cCampo, xValueNew, nLine, xValueOld)

Local lRet       := .T.
Local nPosIt     := 0 

If lAltData
	lRet := .F.
	Help(,,'AT825DATA',,STR0023 + CRLF + ; // 'Realizada alteração na data da reserva, é preciso executar o filtro novamente.'
						STR0024+'"'+STR0022+'"',1,0)  // 'Acione o botão '
Else
	//----------------------------------
	//  Valida a qtde de itens selecionados... 
	// inibindo somente a seleção de uma quantidade maior que a vendida
	If lResKit
		nPosIt := aScan( aResVld, {|x| x[1] == oMdl:GetValue('AA3_CODPRO') } )
	Else
		nPosIt := 1
	EndIf

	If xValueNew
		If aResVld[nPosIt,2] < aResVld[nPosIt,3]+1
			lRet := .F.
			Help(,,'AT825MAIOR',,STR0025,1,0) // 'Item não pode ser reservado pois supera a quantidade vendida no item'
		Else
			// ----------------------------------------
			//  Realiza a marcação do item e adiciona ao array de controle
			aResVld[nPosIt,3] += 1
		EndIf
	Else
		// ----------------------------------------
		//  Desconsidera a marcação do item
		aResVld[nPosIt,3] -= 1
	EndIf

EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At825Perg
	Retorna indicando se houve o uso do prgunte
@sample 	At825Perg()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Function At825Perg()
Return lUsePerg

//------------------------------------------------------------------------------
/*/{Protheus.doc} At825Grv
	Realiza a gravação do mvc e a geração dos movimentos de reserva
@sample 	At825Grv()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Function At825Grv(oMdlFull)

Local lRet        := .F.
Local cReserva    := AtGetReserva()
Local nItReserva  := 0
Local oMdlGrd     := oMdlFull:getModel('GRD_AA3')
Local oMdlGrdNId     := oMdlFull:getModel('GRD_AA3NID')
Local oMdlCab     := oMdlFull:getModel('CAB_TFI')
Local oMdlReserva := Nil
Local cCaptErro   := ''
Local oTecProvider	:= Nil

BeginTran()

lRet := oMdlCab:LoadValue( 'TFI_RESERV', cReserva )

lRet := lRet .And. FwFormCommit( oMdlFull )

If lRet
	
	oMdlReserva := FwLoadModel('TECA825B')  // cria objeto com o modelo de dados para a reserva

	For nItReserva := 1 To oMdlGrd:Length()
	
		oMdlGrd:GoLine(nItReserva)
		
		If oMdlGrd:GetValue('AA3_FLAG')
		
			oMdlReserva:SetOperation( MODEL_OPERATION_INSERT )
			
			lRet := oMdlReserva:Activate()
			
			//--------------------------------------
			//  Preenche os campos relacionados com a reserva
	  		lRet := lRet .And. oMdlReserva:GetModel('MAIN'):SetValue('TEW_PRODUT', At820GetPrd( oMdlFull, oMdlCab:GetValue('TFI_FILIAL'), 'GRD_AA3' ) )
	  		lRet := lRet .And. oMdlReserva:GetModel('MAIN'):SetValue('TEW_FILBAT', oMdlGrd:GetValue('AA3_FILORI') )
	  		lRet := lRet .And. oMdlReserva:GetModel('MAIN'):SetValue('TEW_BAATD' , oMdlGrd:GetValue('AA3_NUMSER') )
	  		lRet := lRet .And. oMdlReserva:GetModel('MAIN'):SetValue('TEW_DTSEPA', dDatabase )
	  		lRet := lRet .And. oMdlReserva:GetModel('MAIN'):SetValue('TEW_DTRINI', oMdlCab:GetValue('TFI_RESINI') )
	  		lRet := lRet .And. oMdlReserva:GetModel('MAIN'):SetValue('TEW_DTRFIM', oMdlCab:GetValue('TFI_RESFIM') )
	  		lRet := lRet .And. oMdlReserva:GetModel('MAIN'):SetValue('TEW_RESCOD', cReserva )
	  		lRet := lRet .And. oMdlReserva:GetModel('MAIN'):SetValue('TEW_MOTIVO', DEF_RESERVA )  // inclui a reserva do registro
	  		lRet := lRet .And. oMdlReserva:GetModel('MAIN'):SetValue('TEW_QTDRES', 1) 
	  		
	  		lRet := lRet .And. ;  // só executa a gravação quando não captura erros anteriores
			oMdlReserva:VldData() .And. ;  // Chama a validação do TudoOk()
			oMdlReserva:CommitData()  // Realiza a gravação
				
		If lRet .And. SuperGetMv('MV_TECATF', .F.,'N') == 'S'
			If ValType(oTecProvider) <> 'O'
				oTecProvider := TecProvider():New()
			EndIf
						
				oTecProvider:InsertTWU(oMdlReserva:GetModel('MAIN'):GetValue('TEW_CODMV'),oMdlGrd:GetValue('AA3_NUMSER'),1,'1')
			EndIf
				
	  		If !lRet
	  			cCaptErro := STR0026 + CRLF + IdErrorMvc( oMdlReserva ) // 'Erro na geração da reserva dos equipamentos'
	  			Exit
			EndIf
			
			oMdlReserva:DeActivate()
		
		EndIf

	Next nItReserva

	For nItReserva := 1 To oMdlGrdNId:Length()
	
		oMdlGrdNId:GoLine(nItReserva)
		
		If oMdlGrdNId:GetValue('AA3_QTDRES') > 0
		
			oMdlReserva:SetOperation( MODEL_OPERATION_INSERT )
			
			lRet := oMdlReserva:Activate()
			
				//--------------------------------------
				//  Preenche os campos relacionados com a reserva
			lRet := lRet .And. oMdlReserva:GetModel('MAIN'):SetValue('TEW_PRODUT', At820GetPrd( oMdlFull, oMdlCab:GetValue('TFI_FILIAL'), 'GRD_AA3NID' ) )
			lRet := lRet .And. oMdlReserva:GetModel('MAIN'):SetValue('TEW_FILBAT', oMdlGrdNId:GetValue('AA3_FILORI') )
			lRet := lRet .And. oMdlReserva:GetModel('MAIN'):SetValue('TEW_BAATD' , oMdlGrdNId:GetValue('AA3_NUMSER') )
			lRet := lRet .And. oMdlReserva:GetModel('MAIN'):SetValue('TEW_DTSEPA', dDatabase )
			lRet := lRet .And. oMdlReserva:GetModel('MAIN'):SetValue('TEW_DTRINI', oMdlCab:GetValue('TFI_RESINI') )
			lRet := lRet .And. oMdlReserva:GetModel('MAIN'):SetValue('TEW_DTRFIM', oMdlCab:GetValue('TFI_RESFIM') )
			lRet := lRet .And. oMdlReserva:GetModel('MAIN'):SetValue('TEW_RESCOD', cReserva )
			lRet := lRet .And. oMdlReserva:GetModel('MAIN'):SetValue('TEW_MOTIVO', DEF_RESERVA )  // inclui a reserva do registro
			lRet := lRet .And. oMdlReserva:GetModel('MAIN'):SetValue('TEW_QTDRES', oMdlGrdNId:GetValue('AA3_QTDRES') )  // inclui a reserva do registro
				
			lRet := lRet .And. ;  // só executa a gravação quando não captura erros anteriores
					oMdlReserva:VldData() .And. ;  // Chama a validação do TudoOk()
					oMdlReserva:CommitData()  // Realiza a gravação
						
			If lRet .And. SuperGetMv('MV_TECATF', .F.,'N') == 'S'
				If ValType(oTecProvider) <> 'O'
					oTecProvider := TecProvider():New()
				EndIf
				oTecProvider:InsertTWU(oMdlReserva:GetModel('MAIN'):GetValue('TEW_CODMV'),oMdlGrdNId:GetValue('AA3_NUMSER'),oMdlGrdNId:GetValue('AA3_QTDRES'),'1')
			EndIf
				
				
			If !lRet
				cCaptErro := STR0026 + CRLF + IdErrorMvc( oMdlReserva ) // 'Erro na geração da reserva dos equipamentos'
				Exit
			EndIf
			
			oMdlReserva:DeActivate()
		
		EndIf

	Next nItReserva

	oMdlReserva:Destroy()
	
Else
	cCaptErro := STR0027 + CRLF + IdErrorMvc( oMdlFull )  // 'Erro na atualização da reserva'
EndIf

If lRet
	EndTran()
Else
	DisarmTransaction()
	Help(,,'AT825RESER',, cCaptErro,1,0)
EndIf

If ValType(oTecProvider) == 'O'
	FreeObj(oTecProvider)
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} IdErrorMvc
	Função para captura do erro gerado dentro do MVC

@sample 	IdErrorMvc()

@since  	17/02/2014
@version 	P12
@param  	ExpO, OBJECT, Objeto principal do MVC em que o erro aconteceu
/*/
//-------------------------------------------------------------------
Static Function IdErrorMvc( oObj )

Local xAux := oObj:GetErrorMessage()

Local cMsgErro := ;
			STR0028 + '[' + ConvAllToChar( xAux[MODEL_MSGERR_IDFIELDERR] ) + ']' + ; // " Id do campo de erro: "
			STR0029 + '[' + ConvAllToChar( xAux[MODEL_MSGERR_MESSAGE] ) + ']' + ;  // " Mensagem do erro:    "
			STR0030 + '[' + ConvAllToChar( xAux[MODEL_MSGERR_SOLUCTION] ) + ']' + ;  // " Mensagem da solução: "
			STR0031 + '[' + ConvAllToChar( xAux[MODEL_MSGERR_VALUE]  ) + ']'  // " Valor atribuido:     "

Return cMsgErro

//-------------------------------------------------------------------
/*/{Protheus.doc} ConvAllToChar
	Converte um dado em String

@sample 	ConvAllToChar()

@since  	17/02/2014
@version 	P12
@param  	ExpX, SEM TIPO DEFINIDO, Valor a ser convertido
@return  	ExpC, Char, valor convertido em string
/*/
//-------------------------------------------------------------------
Static Function ConvAllToChar( xValue )

If ValType(xValue) == 'U'
	xValue := 'Nil'
ElseIf ValType(xValue) == 'D'
	xValue := DtoC( xValue )
ElseIf ValType(xValue) == 'L' .Or. ValType(xValue) == 'N'
	xValue := cValToChar( xValue )
EndIf 

Return xValue

//------------------------------------------------------------------------------
/*/{Protheus.doc} AtGetReserva
	Identifica o código seguinte para a reserva
@sample 	AtGetReserva()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Function AtGetReserva()

Local cRet      := ''
Local aSave     := GetArea()
Local aSaveTEW  := TEW->( GetArea() )
Local cAliasQry := GetNextAlias()

BeginSql Alias cAliasQry
	SELECT 
		MAX(TEW.TEW_RESCOD) AS TEW_RESCOD
	FROM 
		%Table:TEW% TEW
	WHERE 
		TEW.TEW_FILIAL = %xFilial:TEW% AND TEW.%NotDel% 
EndSql

If (cAliasQry)->(!EOF()) .And. !Empty((cAliasQry)->TEW_RESCOD)
	cRet := Soma1(AllTrim((cAliasQry)->TEW_RESCOD))
Else
	cRet := StrZero( 1, TamSx3('TEW_RESCOD')[1] )
EndIf

(cAliasQry)->( DbCloseArea() )

RestArea( aSaveTEW )
RestArea( aSave )

Return cRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At825VldRes
Matheus Lando Raimundo
	Valid do campo Qtd Res 
@sample 	At825VldRes()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Function At825VldRes(oMdlGRD, cCmp, xValueNew, nLi , xValueOld )
Local lRet := .T.
Local oModel	:= oMdlGRD:GetModel()

If Positivo(xValueNew) 
	If xValueNew > oMdlGRD:GetValue('AA3_QTDDSP') 
		Help( , , "At820VldRes", , "Quantidade de reserva maior do que a quantidade disponível.", 1, 0,,,,,,{"Informe a quantidade de reserva menor ou igual a quantidade disponível."}) //"Quantidade de separação maior que o saldo a separar." # "Informe a quantidade de separação menor ou igual a quantidade disponível."
		lRet := .F.
	ElseIf xValueNew > oModel:GetModel('CAB_TFI'):GetValue('TFI_QTDVEN')
		Help( , , "At820VldRes", , "Quantidade de reserva maior do que a quantidade de locação", 1, 0,,,,,,{"Informe a quantidade de reserva menor ou igual a quantidade de locação."}) //"Quantidade de separação maior que o saldo a separar." # "Informe a quantidade de separação menor ou igual a quantidade disponível." 
		lRet := .F.
	EndIf
EndIf	
Return lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At825AtSld
Matheus Lando Raimundo
	Atualiza o saldo disponivel das bases   
@sample 	At825VldRes()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Function At825AtSld( oModel )
Local oMdlGrn	:= oModel:GetModel('GRD_AA3NID')
Local nI	:= 0
Local oTecPvd	:= Nil

For nI := 1 To oMdlGrn:Length()
	oMdlGrn:GoLine(nI)
	oTecPvd  := TECProvider():New(oMdlGrn:GetValue('AA3_NUMSER'),oMdlGrn:GetValue('AA3_FILORI'))
	oMdlGrn:SetValue('AA3_QTDDSP',oTecPvd:SaldoDisponivel())
	FreeObj(oTecPvd)	  
Next nI

Return 