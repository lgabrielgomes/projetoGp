#INCLUDE 'TECA670.CH' 
#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'FWBROWSE.CH'

//------------------------------------------------------
//  Defines para posicionamento no array de configuração da rotina de filtro
#DEFINE FIL_POS_ALIAS 	1
#DEFINE FIL_POS_NICK  	2
#DEFINE FIL_POS_NOME  	3
#DEFINE FIL_POS_ORDEM  	4
#DEFINE FIL_POS_FIELD 	5
#DEFINE FIL_POS_F3	  	6
#DEFINE FIL_POS_COLS  	7
//----------------------------------------------------
// Posições para uso no formato de combobox
#DEFINE FIL_POS_DADOSCB 8
#DEFINE FIL_POS_VALIDCB 9
//----------------------------------------------------
//  Posições adicionais para validação de tabela do SX5 e validações extras
#DEFINE FIL_POS_TABSX5 	10
#DEFINE FIL_POS_VLDEXT 	11

// Exemplo Colunas Virtuais { {'SA1', 1, 'A1_NOME+A1_CGC'} }
#DEFINE VIR_POS_ALIAS 	1
#DEFINE VIR_POS_ORDEM  	2
#DEFINE VIR_POS_FIELDS 	3
//-----------------------------------------------

Static lInUso        := .F.  // caso a rotina já esteja em uso e uma mesma thread tente realizar a abertura
Static aDefEstru     := {'','','',0,'','',{},{},{||.T.},'',Nil}  // 
Static aInfsCharge   := aClone(aDefEstru)  // array padrão para carregamento da estrutura

Static lValorCombo   := .F.  // valor é por combobox?

Static lParamsOk     := .F.  // define se os parâmetros fora configurados/passados corretamente
Static lRetF3        := .F.  // indica se deve ou não retornar o conteúdo do F3 definido
Static nTamChave     := 0  // tamanho da chave informada para gravação/leitura dos filtros definidos

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECA670
	Chama a rotina para alteração das informações controla para não permitir edição simultanea no filtro
	por conta dos controles de variáveis static
@sample		TECA670( aParam[nParams], .F. )
	
@since		24/04/2014 
@version 	P12

@param		aParams, Array, lista com as informações para configuração do filtro
@param		lUseCombo, Logico, define se o campo de valor terá o formato de combo (.T.) ou get (.F.).

/*/
//--------------------------------------------------------------------------------------------------------------------
Function TECA670( aParams, lUseCombo )

Local nOpc			:= 0
Local lConfirm	:= .F.

AtAvalNulos()

If !lInUso
	lInUso := .T.
	
	If aParams <> Nil .And. Valtype(aParams)=='A'
		At670DefParams( lUseCombo, aParams )  // define os conteúdos
	EndIf
	
	If lParamsOk
		DbSelectArea("TIZ")
		TIZ->( DbSetOrder( 2 ) ) // TIZ_FILIAL+TIZ_CODUSR+TIZ_TABELA+TIZ_NICK+TIZ_SEQ
		If TIZ->( DbSeek( xFilial('TIZ')+PadR(__cUserId,TamSX3('TIZ_CODUSR')[1])+;
				PadR(aInfsCharge[FIL_POS_ALIAS],TamSX3('TIZ_TABELA')[1])+PadR(aInfsCharge[FIL_POS_NICK],TamSX3('TIZ_NICK')[1]) ) )
			nOpc := MODEL_OPERATION_UPDATE
		Else
			nOpc := MODEL_OPERATION_INSERT
		EndIf
		
		lConfirm		:= ( FWExecView( aInfsCharge[FIL_POS_NOME],'VIEWDEF.TECA670', nOpc,,{||.T.},{||.T.},25,,{||.T.}) == 0 )
		lValorCombo	:= .F.
		lParamsOk		:= .F.
		lRetF3			:= .F.
		nTamChave		:= 0
	EndIf
	lInUso := .F.
EndIf

Return lConfirm

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At670DefParams
	Define os valores que serão repetidos e que servem de referência para a construção da rotina

@sample		AT670DEFPARAMS()

// ** Exemplos para a construção dos filtros **
// { 'SA1', '001', 'Cliente/Loja', 1, 'A1_FILIAL+A1_COD+A1_LOJA', 'SA1', {} , {}, {|| }, ''}
// { 'SITATD','001', 'Sitação Funcionário', , , , , {'1=Dado 1','2=Dado 2','3=Dado 3'}, {|| Pertence('123') }, '' }
// { 'SX5'   , 'A4_', 'Habilidade', 1,'X5_FILIAL+X5_TABELA+X5_CHAVE', 'A4', { {'SX5', 1, 'X5_DESCRI'} }, {}, {||.F.}, 'A4' }
	
@since		24/04/2014 
@version 	P12

@param		lCombobox, Logico, define se o vapo de valor será no formato de combobox
@param		aParams, Array, conteúdo para configuração dos parA~emtros
@return		lRet, Logico, 
/*/
//--------------------------------------------------------------------------------------------------------------------
//-----------------------------------------------
Static Function At670DefParams( lComboBox, aParams )

Local lRet    := .F.
Local nX      := 0
Local aCpos   := {}
Local aTamSx3 := {}

Default lComboBox := .F.

lParamsOk := .F.
aSize( aInfsCharge, 0)
aInfsCharge   := aClone(aDefEstru)

If !lComboBox
	If Len(aParams) >= FIL_POS_FIELD
		aInfsCharge[FIL_POS_ALIAS] := aParams[FIL_POS_ALIAS]
		aInfsCharge[FIL_POS_NICK]  := aParams[FIL_POS_NICK]
		aInfsCharge[FIL_POS_NOME]  := aParams[FIL_POS_NOME]
		aInfsCharge[FIL_POS_ORDEM] := aParams[FIL_POS_ORDEM]
		aInfsCharge[FIL_POS_FIELD] := aParams[FIL_POS_FIELD]
		aInfsCharge[FIL_POS_VLDEXT] := aParams[FIL_POS_VLDEXT] 
		
		nTamChave := 0
		aCpos := StrToKArr( aInfsCharge[FIL_POS_FIELD], '+' )
		For nX := 1 To Len(aCpos)
			aTamSx3 := TamSX3(aCpos[nX])
			nTamChave += If( Len(aTamSx3)==0, Len(aCpos[nX]), aTamSx3[1])
		Next nX
		//-------------------------
		// atribui f3 ao campo
		If Len(aParams) >= FIL_POS_F3
			aInfsCharge[FIL_POS_F3]    := aParams[FIL_POS_F3]
		EndIf
		
		//--------------------------------
		// colunas para exibição dos campos virtuais
		If Len(aParams) >= FIL_POS_COLS
			aInfsCharge[FIL_POS_COLS]    := aClone(aParams[FIL_POS_COLS])
		EndIf
		
		//-------------------------------------------
		// tabela do sx5 para validação de posicionamento nas tabelas corretas A2,A5,A4,etc
		If Len(aParams) >= FIL_POS_TABSX5
			aInfsCharge[FIL_POS_TABSX5]    := aParams[FIL_POS_TABSX5]
		EndIf
		
		//------------------------------------------------
		// caso tenha validação adicional, adiciona ao array para carregamento no modelo (modeldef)
		If Len(aParams) >= FIL_POS_VLDEXT
			aInfsCharge[FIL_POS_TABSX5]    := aParams[FIL_POS_TABSX5]
		EndIf
		
		lRet := .T.
		lParamsOk := .T.
	EndIf
Else
	
	lValorCombo := .T.
	aInfsCharge[FIL_POS_ALIAS]   := aParams[FIL_POS_ALIAS]
	aInfsCharge[FIL_POS_NICK]    := aParams[FIL_POS_NICK]
	aInfsCharge[FIL_POS_NOME]    := aParams[FIL_POS_NOME]
	aInfsCharge[FIL_POS_FIELD]   := 'COMBOBOX'
	aInfsCharge[FIL_POS_DADOSCB] := aClone(aParams[FIL_POS_DADOSCB])
	aInfsCharge[FIL_POS_VALIDCB] := aParams[FIL_POS_VALIDCB]
	
	lRet := .T.
	lParamsOk := .T.
EndIf

Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} MODELDEF
	Construção do modelo de dados para a rotina de filtro

@sample		ModelDef()
	
@since		29/04/2014 
@version 	P12

@return		oModel, Objeto, instância da classe MpFormModel para realização das operação de atualização e inclusão de filtros

/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ModelDef()
Local oModel  := Nil
Local oStr1   := FWFormStruct(1,'TIZ')
Local oStr2   := FWFormStruct(1,'TIZ')

Local bDefAlias := {|| aInfsCharge[FIL_POS_ALIAS] }
Local bDefNick  := {|| aInfsCharge[FIL_POS_NICK] }
Local bDefNome  := {|| aInfsCharge[FIL_POS_NOME] }

Local bVldInfo   := {|| }
Local cActInfo   := '{|oMdl, cCampo, xValueNew, nLine, xValueOld| XXX }'
Local cContInfo  := 'At670Valor(oMdl, cCampo, xValueNew, nLine, xValueOld)'

oModel := MPFormModel():New('TECA670', /*bPreValid*/, /*bPosValid*/, {|oModel| At670Commit( oModel ) })

oStr1:RemoveField( 'TIZ_VALOR' )
oStr1:RemoveField( 'TIZ_FILIAL' )
oStr1:RemoveField( 'TIZ_SEQ' )
oStr1:RemoveField( 'TIZ_FILTRA' )

oStr1:SetProperty('TIZ_TABELA',MODEL_FIELD_INIT,bDefAlias)
oStr1:SetProperty('TIZ_NICK'  ,MODEL_FIELD_INIT,bDefNick)
oStr1:SetProperty('TIZ_NOME'  ,MODEL_FIELD_INIT,bDefNome)

oModel:addFields('CAB',,oStr1)

oStr2:SetProperty('TIZ_SEQ'   ,MODEL_FIELD_OBRIGAT,.F.)
oStr2:SetProperty('TIZ_CODUSR',MODEL_FIELD_OBRIGAT,.F.)
oStr2:SetProperty('TIZ_TABELA',MODEL_FIELD_OBRIGAT,.F.)
oStr2:SetProperty('TIZ_CAMPOS',MODEL_FIELD_OBRIGAT,.F.)

If aInfsCharge[FIL_POS_VLDEXT] <> Nil .And. ValType(aInfsCharge[FIL_POS_VLDEXT])=='C'
	cContInfo += ' .And. ' + aInfsCharge[FIL_POS_VLDEXT]
	cActInfo := StrTran( cActInfo, 'XXX', cContInfo )
	bVldInfo := &(cActInfo)
Else
	cActInfo := StrTran( cActInfo, 'XXX', cContInfo )
	bVldInfo := &(cActInfo)
EndIf

oStr2:SetProperty('TIZ_VALOR', MODEL_FIELD_VALID, bVldInfo )

If lValorCombo .And. Len( aInfsCharge[FIL_POS_DADOSCB] ) > 0
	oStr2:SetProperty('TIZ_VALOR', MODEL_FIELD_TAMANHO, 1)
	oStr2:SetProperty('TIZ_VALOR', MODEL_FIELD_VALUES , aInfsCharge[FIL_POS_DADOSCB])
	oStr2:SetProperty('TIZ_VALOR', MODEL_FIELD_VALID  , aInfsCharge[FIL_POS_VALIDCB])
ElseIf Len( aInfsCharge[FIL_POS_FIELD] ) > 0
	//----------------------------
	// Adiciona os campos virtuais
	At670AddCpo( 1, oStr2 )
	At670AddTrg( oStr2 )
EndIf

oModel:addGrid('GRID1','CAB',oStr2)
oModel:GetModel('GRID1'):SetUniqueLine( { 'TIZ_VALOR' } )
oModel:SetRelation('GRID1', { { 'TIZ_FILIAL', 'xFilial("TIZ")' }, { 'TIZ_CODUSR', 'TIZ_CODUSR' }, { 'TIZ_TABELA', 'TIZ_TABELA' }, { 'TIZ_CAMPOS', 'TIZ_CAMPOS' }, { 'TIZ_NOME', 'TIZ_NOME' }, { 'TIZ_NICK', 'TIZ_NICK' } }, TIZ->(IndexKey(2)) )

oModel:GetModel('GRID1'):SetOptional(.T.)

oModel:SetPrimaryKey({})
oModel:SetDescription(STR0001) // 'Filtro'
oModel:SetActivate({|oMdlGeral| At670IniIns(oMdlGeral)})

Return oModel

//-------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
	Definição do interface

@since 24/03/2014
@version 12

@return		oView, Objeto, instãncia da classe FwFormView para exibição das informaões do filtro
/*/
//-------------------------------------------------------------------
Static Function ViewDef()
Local oView
Local oModel := ModelDef()
Local oStr1:= FWFormStruct(2, 'TIZ')
Local oStr2:= FWFormStruct(2, 'TIZ')

oView := FWFormView():New()

oView:SetModel(oModel)

oStr1:RemoveField('TIZ_VALOR'  )
oStr1:RemoveField('TIZ_FILTRA' )
oStr1:RemoveField('TIZ_CAMPOS' )
oStr1:RemoveField('TIZ_NICK'   )
oStr1:RemoveField('TIZ_TABELA' )
oStr1:RemoveField('TIZ_CODUSR' )
oStr1:RemoveField('TIZ_SEQ'    )

oStr2:RemoveField('TIZ_SEQ'    )
oStr2:RemoveField('TIZ_NOME'   )
oStr2:RemoveField('TIZ_CAMPOS' )
oStr2:RemoveField('TIZ_NICK'   )
oStr2:RemoveField('TIZ_TABELA' )
oStr2:RemoveField('TIZ_CODUSR' )
oStr2:SetProperty('TIZ_FILTRA',MVC_VIEW_ORDEM,'01')
oStr2:SetProperty('TIZ_VALOR',MVC_VIEW_ORDEM,'03')

If Len( aInfsCharge[FIL_POS_COLS] ) > 0
	//----------------------------
	// Adiciona os campos virtuais
	At670AddCpo( 2, oStr2 )
EndIf

If lValorCombo .And. Len( aInfsCharge[FIL_POS_DADOSCB] ) > 0
	oStr2:SetProperty('TIZ_VALOR', MVC_VIEW_PICT    , "@!" )
	oStr2:SetProperty('TIZ_VALOR', MVC_VIEW_COMBOBOX, aInfsCharge[FIL_POS_DADOSCB])
ElseIf !Empty(aInfsCharge[FIL_POS_F3])
	oStr2:SetProperty('TIZ_VALOR' ,MVC_VIEW_LOOKUP,'TIZOPE')
EndIf

oView:SetCloseOnOK({||.T.})
oView:AddField('FORM1', oStr1,'CAB' )
oView:AddGrid('FORM2' , oStr2,'GRID1')  

oView:CreateHorizontalBox( 'BOXFORM1', 15)
oView:CreateHorizontalBox( 'BOXFORM2', 85)

oView:SetOwnerView('FORM2','BOXFORM2')
oView:SetOwnerView('FORM1','BOXFORM1')

oView:SetCloseOnOk({||.T.})

Return oView

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT670INIINS
	Função que inicia o conteúdo nos campos obrigatórios

@sample		At670IniIns(oMdlGeral)
	
@since		24/04/2014 
@version 	P12

@param		oMdlGeral, Objeto, objeto principal da classe MpFormModel e ativo para atualização das informações

/*/
//--------------------------------------------------------------------------------------------------------------------
Function At670IniIns(oMdlGeral)

Local oMdlCab := oMdlGeral:GetModel('CAB')
Local oMdlGrd := oMdlGeral:GetModel('GRID1')
Local nLin    := 1

If oMdlGeral:GetOperation()<>MODEL_OPERATION_DELETE .And. ;
	oMdlGeral:GetOperation()<>MODEL_OPERATION_VIEW
	
	oMdlCab:SetValue('TIZ_CODUSR', __cUserId)
	oMdlCab:SetValue('TIZ_TABELA', aInfsCharge[FIL_POS_ALIAS])
	oMdlCab:SetValue('TIZ_NICK'  , aInfsCharge[FIL_POS_NICK])
	oMdlCab:SetValue('TIZ_NOME'  , aInfsCharge[FIL_POS_NOME])
	oMdlCab:SetValue('TIZ_CAMPOS', aInfsCharge[FIL_POS_FIELD])
	
	If lValorCombo .And. ;
		oMdlGeral:GetOperation()==MODEL_OPERATION_UPDATE .And. ;
		oMdlGrd:Length() > 0
			
		For nLin := 1 To oMdlGrd:Length()
			oMdlGrd:GoLine(nLin)
			oMdlGrd:SetValue('TIZ_VALOR', RTrim(oMdlGrd:GetValue('TIZ_VALOR')))
		Next nLin
		oMdlGrd:GoLine(1)
	EndIf
EndIf

If oMdlGeral:GetOperation() == MODEL_OPERATION_VIEW
	oMdlGeral:lModify := .F.
EndIf

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At670FunF3
	Função de chamada do F3 genérico para o campo de Valor

@sample		At670FunF3()
	
@since		24/04/2014 
@version 	P12

@return		lRetF3, Logico, indica se houve a seleção e confirmação de registro dentro da consulta chamada
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At670FunF3()

lRetF3 := .F.

If !Empty(aInfsCharge[FIL_POS_F3]) .And. ;
	ConPad1(,,,aInfsCharge[FIL_POS_F3],,,.F.)
	
	lRetF3 := .T.
EndIf

Return lRetF3

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT670RETF3
	Função de retorno de conteúdo do F3 genérico

@sample		At670RetF3()
	
@since		24/04/2014 
@version 	P12

@return		xRet, Variável, macro executa a informação definida para preenchimento do conteúdo no filtro
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At670RetF3()

Local xRet := ''

If lRetF3

	xRet := (aInfsCharge[FIL_POS_ALIAS])->(&(aInfsCharge[FIL_POS_FIELD]))
	
	lRetF3 := .F.
EndIf 

Return xRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT670ADDCPO
	Adiciona os campos virtuais à estrutura

@sample		At670AddCpo( 1, oStr2 ) // At670AddCpo( 2, oStr2 )
	
@since		24/04/2014 
@version 	P12

@param		nTipo, Numerico, define se a estrutura a ser criada para o campo deve ser para o model (1) ou para a view (2)
@param		oStr, Objeto, estrutura que irá receber o novo campo
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At670AddCpo( nTipo, oStr )

Local nI       := 0
Local nK       := 0
Local aVirCols := {}
Local aCpos    := {}

Local aSave    := GetArea()
Local aSaveSX3 := SX3->( GetArea() )

Local bInitVir := {|| }
Local cOrdem   := '03'
Local aOpcs    := {}
Local xAux     := Nil

DEFAULT nTipo  := 1

aVirCols := aInfsCharge[FIL_POS_COLS]

If nTipo == 1
	For nI := 1 To Len( aVirCols )
		
		aCpos := StrToKArr( aVirCols[nI, VIR_POS_FIELDS], '+' )
		xAux  := MontaPosicione( aVirCols[nI] )
			
		For nK := 1 To Len( aCpos )
			
			SX3->( DbSetOrder( 2 ) ) //X3_CAMPO
			bInitVir := Nil
			If SX3->( DbSeek( Padr( aCpos[nK], 10 ) ) )
				
				aOpcs := StrToKArr( RTrim(X3CBox()), ";" )
				bInitVir := &("{||"+StrTran( xAux, '##CAMPO##', aCpos[nK])+"}")
				
				oStr:AddField( X3Titulo(), ; // cTitle // 'Mark'
								X3Descric(), ; // cToolTip // 'Mark'
								aCpos[nK], ; // cIdField
								Rtrim(SX3->X3_TIPO), ; // cTipo
								SX3->X3_TAMANHO, ; // nTamanho
								SX3->X3_DECIMAL, ; // nDecimal
								{||.T.}, ; // bValid
								{||.T.}, ; // bWhen
								aOpcs, ; // aValues
								.F., ; // lObrigat
								bInitVir, ; // bInit
								Nil, ; // lKey
								.F., ; // lNoUpd
								.T. ) // lVirtual
			EndIf
		
		Next nK
	
	
	Next nI
Else
	For nI := 1 To Len( aVirCols )
		
		aCpos := StrToKArr( aVirCols[nI, VIR_POS_FIELDS], '+' )
		
		For nK := 1 To Len( aCpos )
			
			SX3->( DbSetOrder( 2 ) ) //X3_CAMPO
			
			If SX3->( DbSeek( Padr( aCpos[nK], 10 ) ) )
				
				cOrdem := Soma1(cOrdem)
				aOpcs := StrToKArr( RTrim(X3CBox()), ";" )
				
				oStr:AddField( aCpos[nK], ; // cIdField
								cOrdem, ; // cOrdem
								X3Titulo(), ; // cTitulo
								X3Descric(), ; // cDescric
								{}, ; // aHelp
								RTrim(SX3->X3_TIPO), ; // cType
								RTrim(SX3->X3_PICTURE), ; // cPicture
								Nil, ; // nPictVar
								Nil, ; // Consulta F3
								.F., ; // lCanChange
								'01', ; // cFolder
								Nil, ; // cGroup
								aOpcs, ; // aComboValues
								1, ; // nMaxLenCombo
								Nil, ; // cIniBrow
								.T., ; // lVirtual
								RTrim(SX3->X3_PICTVAR) ) // cPictVar
			EndIf
		
		Next nK
	
	
	Next nI
EndIf

RestArea(aSaveSX3)
RestArea(aSave)

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} MONTAPOSICIONE
	Cria o formato de posicione para os campos e retorna em string

@sample		MontaPosicione( aItem, cTIZValor )
	
@since		24/04/2014 
@version 	P12

@param		aItem, Array, lista com tabela e ordem para geração do posicione
@param		cTIZValor, Caracter, valor a ser utilizado como chave 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function MontaPosicione( aItem, cTIZValor )

DEFAULT cTIZValor := 'TIZ->TIZ_VALOR'

Return ( "Posicione('"+aItem[VIR_POS_ALIAS] +"',"+; // nome da tabela
						cValToChar(aItem[VIR_POS_ORDEM]) +","+;  // ordem da tabela
						cTIZValor +","+;  // chave do seek
						"'##CAMPO##')" )  //campo de retorno

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT670ADDTRG
	Adiciona os gatilhos que irão preencher os campos virtuais

@sample		At670AddTrg( oStr )
	
@since		24/04/2014 
@version 	P12

@param		oStr, Objeto, objeto da estrutura que irá receber os gatilhos de preenchimento dos conteúdos
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At670AddTrg( oStr )

Local nI       := 0
Local nK       := 0
Local aVirCols := {}
Local aCpos    := {}

Local cTrgVir  := {|| }
Local xAux     := Nil
Local aAuxTrg  := {}

aVirCols := aInfsCharge[FIL_POS_COLS]

For nI := 1 To Len(aVirCols)
	//-----------------------------------------
	//  identifica os campos que precisarão receber o preenchimento
	aCpos := StrToKArr( aVirCols[nI, VIR_POS_FIELDS], '+' )
	xAux  := MontaPosicione( aVirCols[nI], 'M->TIZ_VALOR' )
	
	For nK := 1 To Len(aCpos)	
		// substitui ###CAMPO### pelo nome do campo a ter o conteúdo capturado pelo posicione
		cTrgVir := StrTran( xAux, '##CAMPO##', aCpos[nK])
	
		aAuxTrg := FwStruTrigger( 'TIZ_VALOR', aCpos[nK], cTrgVir, .F. )
			oStr:AddTrigger( aAuxTrg[1], aAuxTrg[2], aAuxTrg[3], aAuxTrg[4])
			
	Next nK
	
Next nI

Return 

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT670SETCB
	Define se o campo de valor será no formato de get ou combo

@sample		At670SetCb( lValor )
	
@since		24/04/2014 
@version 	P12

@param		lValor, Logico, define se será combo (.T.) ou não (.F.)
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At670SetCb( lValor )

lValorCombo := lValor

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT670VALOR
	Função para validação do conteúdo digitado pelo usuário para filtro dos dados

@sample		At670Valor
	
@since		24/04/2014 
@version 	P12
     
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At670Valor(oMdl, cCampo, xValueNew, nLine, xValueOld)

Local lRet      := .F.

Local cTabAtu   := aInfsCharge[FIL_POS_ALIAS]
Local nOrdem    := aInfsCharge[FIL_POS_ORDEM]

Local aSave     := GetAreA()
Local aSaveX    := (cTabAtu)->( GetArea() )

DbSelectArea(cTabAtu)
(cTabAtu)->( DbSetOrder( nOrdem ) )
lRet := (cTabAtu)->( DbSeek( SubStr(xValueNew,1,nTamChave) ) ) .And. ;
		IIf( cTabAtu == 'SX5' .And. !Empty(aInfsCharge[FIL_POS_TABSX5]), ( SX5->X5_TABELA==aInfsCharge[FIL_POS_TABSX5] ), .T. )

RestArea(aSaveX)
RestArea(aSave)

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At670FilSql
	Função para consulta dos filtros e construção das cláusulas SQL para restrição das informações

@sample		At670FilSql( __cUserId, .F., 'SA1', '001' )
	
@since		24/04/2014 
@version 	P12

@param		ExpC1, Caracter, código do usuário para a consulta dos filtros definidos
@param		ExpL2, Logico, define se cria a instrução SQL para o where no formato de IN
@param		ExpC3, Caracter, tabela a ter as informações retornadas
@param		ExpC4, Caracter, identificador adicional a tabela para resgate dos filtros definidos
@param		ExpL5, Logico, indica se a geração da instrução é para item formato como combobox
@param		ExpC6, Caracter, código a ser utilizado como prefixo do campo quando necessário para a instrução SQL de restrição
@param		ExpC7, Caracter, campo a ser utilizado para a comparação com os conteúdo de filtro

@return		Expc, instrução sql para uso em restrição (where) de query
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At670FilSql( cUser, lUseIn, cTab, cNick, lCombo, cTabPref, cCpoUse )

Local cExpSqlRet  := ""
Local aDadosTemp  := At670FilArr( cUser, cTab, cNick, .T. )
Local nPosValor   := aScan( aDadosTemp[1], {|x| Alltrim(x[1])=="TIZ_VALOR"  } )
Local nPosCampo   := aScan( aDadosTemp[1], {|x| Alltrim(x[1])=="TIZ_CAMPOS" } )
Local nLinha      := 1
Local xAux        := Nil
Local xAux1       := Nil
Local nTamCont    := 0
Local lChgConcat  := (Trim(Upper(TcGetDb())) $ "ORACLE,POSTGRES,DB2,INFORMIX")
Local lUsePrefTab := .F.

DEFAULT lCombo    := .F.
DEFAULT cTabPref  := ''
DEFAULT cCpoUse   := ''

If nPosValor > 0 .And. nPosCampo > 0 .And. Len(aDadosTemp[2]) > 0
	
	cCpoUse := If(Empty(cCpoUse), RTrim(aDadosTemp[2,1,nPosCampo]),cCpoUse)
	xAux := StrToKArr( cCpoUse, '+' )
	
	If (lUsePrefTab := !Empty(cTabPref))
		cCpoUse := ''
	EndIf 
	
	If !lCombo
		For nLinha := 1 To Len(xAux)
			xAux1 := TamSX3(xAux[nLinha])
			nTamCont += If( Len(xAux1)==0, Len(xAux[nLinha]), xAux1[1])
			
			If lUsePrefTab
				cCpoUse += cTabPref+"."+xAux[nLinha]+"+"
			EndIf
		Next nLinha

		If lUsePrefTab
			cCpoUse := SubStr( cCpoUse,1,Len(cCpoUse)-1)
		EndIf
	Else
		nTamCont := 1
	EndIf
	
	xAux  := Nil
	xAux1 := Nil

	If lUseIn
		cExpSqlRet += "AND "+ cCpoUse +" IN ("
			For nLinha := 1 To Len(aDadosTemp[2])
				cExpSqlRet += "'"+SubStr(aDadosTemp[2,nLinha,nPosValor],1,nTamCont)+"',"
			Next nLinha
		cExpSqlRet := SubStr( cExpSqlRet, 1, Len(cExpSqlRet)-1 )
		cExpSqlRet += ")"
	Else
		cExpSqlRet += " AND ("
		For nLinha := 1 To Len(aDadosTemp[2])
			cExpSqlRet += " "+cCpoUse+"='"+SubStr(aDadosTemp[2,nLinha,nPosValor],1,nTamCont)+"' OR"
		Next nLinha
		
		cExpSqlRet := SubStr( cExpSqlRet, 1, Len(cExpSqlRet)-2 )
		cExpSqlRet += ")"
		
	EndIf

EndIf

If lChgConcat
	cExpSqlRet := StrTran(cExpSqlRet,'+','||')
EndIf

Return cExpSqlRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT670FILARR
	Função para consulta dos filtros e retornar os dados em array

@sample		At670FilArr( cUser, cTab, cNick, .T. )
	
@since		24/04/2014 
@version 	P12

@param		ExpC1, Caracter, código do usuário para a consulta dos filtros definidos
@param		ExpC2, Caracter, tabela a ter as informações retornadas
@param		ExpC3, Caracter, identificador adicional a tabela para resgate dos filtros definidos
@param		ExpL4, Caracter, define se somente os itens marcados para filtrar serão retornados no array

@return		ExpA, Array, retorna os campos que e os conteúdos para filtro
			Campos -> { { CAMPO, TIPO, TAMANHO, DECIMAL }, ... }
			Conteúdo -> { { CONTEÚDO1,CONTEÚDO2,CONTEÚDO3,CONTEÚDO4,...},...}
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At670FilArr( cUser, cTab, cNick, lOnlyYes )

Local aDataFilter := {}
Local cTabTemp    := At670FilQry( cUser, cTab, cNick, lOnlyYes )
Local nLinha      := 0
Local nCpos       := 1
Local aCposFil    := (cTabTemp)->( DbStruct() )
Local nTotCpos    := Len( aCposFil )

If (cTabTemp)->( !EOF() )
	
	While (cTabTemp)->( !EOF() )
	
		aAdd( aDataFilter, Array(nTotCpos) )
		nLinha += 1
		
		For nCpos := 1 To nTotCpos
			aDataFilter[nLinha,nCpos] := (cTabTemp)->(FieldGet(nCpos))
		Next nCpos
		
		(cTabTemp)->( DbSkip() )
	End
EndIf

(cTabTemp)->( DbCloseArea() )

Return { aClone(aCposFil), aClone(aDataFilter) }

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT670FILQRY
	Consulta os filtros conforme usuário, tabela, nick, etc

@sample		At670FilQry( cUser, cTab, cNick, lOnlyYes )
	
@since		24/04/2014 
@version 	P12

@param		ExpC1, Caracter, código do usuário para a consulta dos filtros definidos
@param		ExpC2, Caracter, tabela a ter as informações retornadas
@param		ExpC3, Caracter, identificador adicional a tabela para resgate dos filtros definidos
@param		ExpL4, Caracter, define se somente os itens marcados para filtrar serão retornados no array

@return		cTabTfilter, Caracter, instrução sql para filtro das informações conforme os parâmetros
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At670FilQry( cUser, cTab, cNick, lOnlyYes )

Local cTabTfilter  := ''
Local cOptWhere    := ''
Local aSave        := GetArea()
Local aSaveTIZ     := TIZ->( GetArea() )

DEFAULT cTab     := ''
DEFAULT cNick    := ''
DEFAULT lOnlyYes := .F.

If !Empty(cUser)
	cTabTfilter := GetNextAlias()
	
	cOptWhere := '%'
	
	If !Empty(cTab)
		cOptWhere += " AND TIZ.TIZ_TABELA = '"+cTab+"'"
	EndIf
	
	If !Empty(cNick)
		cOptWhere += " AND TIZ.TIZ_NICK = '"+cNick+"'"
	EndIf
	
	If lOnlyYes
		cOptWhere += " AND TIZ.TIZ_FILTRA = '1'"
	EndIf
	
	cOptWhere += '%'
	
	BeginSql Alias cTabTfilter
	
		SELECT *
		FROM %Table:TIZ% TIZ
		WHERE TIZ.%NotDel% AND TIZ.TIZ_FILIAL = %xFilial:TIZ% 
			AND %Exp:cUser% = TIZ.TIZ_CODUSR 
			%Exp:cOptWhere%
		
	EndSql
EndIf

RestArea(aSaveTIZ)
RestArea(aSave)

Return cTabTfilter

/*/{Protheus.doc} At670Commit
	Grava os dados inseridos para filtro na rotina

@since		24/04/2014 
@version 	P12
@param		oModel, Objeto Classe FwFormModel/MpFormModel, modelo a ser persistido no banco de dados
@return		Lógico, determina se a operação aconteceu com sucesso ou não
/*/
Static Function At670Commit( oModel )

Local lRet := .T.
Local oMdlGrd := oModel:GetModel('GRID1')

Begin Transaction

If lRet .And. oMdlGrd:Length() >= 1 .And. !Empty( oMdlGrd:GetValue("TIZ_VALOR",1) )
	lRet := FwFormCommit( oModel )
EndIf

End Transaction
Return lRet

/*/{Protheus.doc} AtAvalNulos
	Consulta os registros inválidos inseridos e os remove 
	Os registros a serem eliminados são => TIZ_VALOR = ' '

@since		24/04/2014 
@version 	P12
/*/
Function AtAvalNulos()

Local cQry := GetNextAlias()

BeginSQL Alias cQry
	SELECT TIZ.R_E_C_N_O_ TIZRECNO
	  FROM %Table:TIZ% TIZ
	 WHERE TIZ.TIZ_FILIAL = %xFilial:TIZ%
	   AND TIZ.%NotDel%
	   AND TIZ.TIZ_VALOR = ' '
EndSQL

While (cQry)->(!EOF())
	
	TIZ->( DbGoTo( (cQry)->TIZRECNO ) )
	
	Reclock("TIZ",.F.)
	TIZ->( DbDelete() )
	TIZ->( MsUnlock() )
	
	(cQry)->(DbSkip())
EndDo

Return
