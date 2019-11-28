#INCLUDE "Protheus.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "TECA730.CH"

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECA730

Cadastro de Munições - TE2
@author Serviços
@since 28/08/13
@version P11 R9

/*/
//----------------------------------------------------------------------------------------------------------------------
Function TECA730()

Local oBrowse

Private aRotina	:= MenuDef() 
Private cCadastro	:=STR0001 // Cadastro de Munições

oBrowse := FWMBrowse():New()
oBrowse:SetAlias('TE2')
oBrowse:SetDescription(STR0001) // Cadastro de Munições
oBrowse:Activate()

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef

Definição do MenuDef
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpO:aRotina
/*/
//--------------------------------------------------------------------------------------------------------------------
Static function MenuDef()
Local aRotina :={}

ADD OPTION aRotina TITLE STR0002 	ACTION 'PesqBrw' 				OPERATION 1 ACCESS 0 //"Pesquisar"
ADD OPTION aRotina TITLE STR0003 	ACTION 'VIEWDEF.TECA730' 	OPERATION 2 ACCESS 0 //"Visualizar"
ADD OPTION aRotina TITLE STR0004	ACTION 'VIEWDEF.TECA730' 	OPERATION 3 ACCESS 0 //"Incluir"
ADD OPTION aRotina TITLE STR0005	ACTION 'VIEWDEF.TECA730' 	OPERATION 4 ACCESS 0 //"Alterar"
ADD OPTION aRotina TITLE STR0006 	ACTION 'VIEWDEF.TECA730' 	OPERATION 5 ACCESS 0 //"Excluir"
ADD OPTION aRotina TITLE STR0007	ACTION 'MSDOCUMENT'			OPERATION 7 ACCESS 0 //"Bco. Conhecimento"

Return(aRotina)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef

Definição do Model 
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpO:oModel
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ModelDef()
Local oModel
Local oStruTE2			:= FWFormStruct(1,'TE2')
Local oStruT49			:= FWFormStruct(1,'T49') 
Local oStruTFP			:= FWFormStruct(1,'TFP')

Local bPosValidacao		:= {|oModel|At730Vld(oModel)}
Local bCommit			:= {|oModel|At730Commit(oModel)}

Local aAux				:= {}
Local aAux1				:= {}
Local aAux2				:= {}
Local aAux3				:= {}


//Criação de Gatilhos para os campos virtuais
aAux := FwStruTrigger("TE2_LOJA","TE2_NOME","At730DescFor(1),At730DescFor(2)",.F.,Nil,Nil,Nil)
oStruTE2:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux1 := FwStruTrigger("TE2_CODPRO","TE2_DESPRO","At730DescPro()",.F.,Nil,Nil,Nil)
oStruTE2:AddTrigger(aAux1[1],aAux1[2],aAux1[3],aAux1[4])

aAux3 := FwStruTrigger("TE2_LOCAL","TE2_CLIDES","At730DscLoc()",.F.,Nil,Nil,Nil)
oStruTE2:AddTrigger(aAux3[1],aAux3[2],aAux3[3],aAux3[4])
oStruTFP:SetProperty('*',MODEL_FIELD_OBRIGAT,.F.)


//Adiciona a descrição do local de atendimento.
oStruTFP:AddField( GetSx3Cache("ABS_DESCRI","X3_TITULO"),;                                                		       // cTitle // "Desc. Local"
                GetSx3Cache("ABS_DESCRI","X3_TITULO"),;                                                			   // cToolTip // "Desc. Local"
                "TFP_DESLOC",;                                                                                     // cIdField
                GetSx3Cache("ABS_DESCRI","X3_TIPO"),;                                                              // cTipo
                GetSx3Cache("ABS_DESCRI","X3_TAMANHO"),;                                                           // nTamanho
                GetSx3Cache("ABS_DESCRI","X3_DECIMAL"),;                                                           // nDecimal
                Nil,; 																           							   // bValid
                Nil,;                                                                                         	   // bWhen
                {},;                                                                                               // aValues
                .F.,;                                                           								   // lObrigat
                Nil,;                                                                                              // bInit
                Nil,;                                                                                              // lKey
                .F.,;                                                                                              // lNoUpd
                .T. )                                                                                              // lVirtual
                
//Adiciona a descrição do local de atendimento.
oStruTFP:AddField( GetSx3Cache("TER_DESCRI","X3_TITULO"),;                                                		       // cTitle // "Desc. Local"
                GetSx3Cache("TER_DESCRI","X3_TITULO"),;                                                			   // cToolTip // "Desc. Local"
                "TFP_DESLCI",;                                                                                     // cIdField
                GetSx3Cache("TER_DESCRI","X3_TIPO"),;                                                              // cTipo
                GetSx3Cache("TER_DESCRI","X3_TAMANHO"),;                                                           // nTamanho
                GetSx3Cache("TER_DESCRI","X3_DECIMAL"),;                                                           // nDecimal
                Nil,; 																           							   // bValid
                Nil,;                                                                                         	   // bWhen
                {},;                                                                                               // aValues
                .F.,;                                                           								   // lObrigat
                Nil,;                                                                                              // bInit
                Nil,;                                                                                              // lKey
                .F.,;                                                                                              // lNoUpd
                .T. )                                                                                              // lVirtual                

//Instancia o cadastro de munições
oModel := MPFormModel():New('TECA730',/*bPreValidacao*/,bPosValidacao,bCommit,/*bCancel*/)

//Instancia o cabeçalho

oModel:AddFields('TE2MASTER',/*cOwner*/,oStruTE2,/*bPreValidacao*/,/*bPosValidacao*/,/*bCarga*/,/*bFieldAbp*/)

//Instancia o Grid para Entrada de Munições
oModel:AddGrid('T49DETAIL','TE2MASTER',oStruT49,{|oModelGrid, nLine,cAction,cField|PreValT49(oModelGrid, nLine, cAction, cField)})
oModel:AddGrid('TFPDETAIL','TE2MASTER',oStruTFP)

oModel:GetModel('TE2MASTER'):SetDescription('Munições')//Descriçao dos componentes do Model
oModel:GetModel('T49DETAIL'):SetDescription('Registro de entradas')//Descriçao dos componentes do Model
oModel:GetModel('TFPDETAIL'):SetDescription('Saldos')//Descriçao dos componentes do Model

//Realiza o relacionamento entre o cabeçalho e os grids
oModel:SetRelation('T49DETAIL', { {'T49_FILIAL','xFilial("T49")' }, {'T49_CODMUN','TE2_CODMUN' }, {'T49_CODPRO','TE2_CODPRO' }},T49->(IndexKey(1) ))
oModel:SetRelation('TFPDETAIL', { {'TFP_FILIAL','xFilial("TFP")' }, {'TFP_PRODUT','TE2_CODPRO' }, {'TFP_PRODUT','TE2_CODPRO' }},TFP->(IndexKey(7) ))

// Obrigatoriedade de preenchimento - Entrada de Munições
oStruT49:SetProperty('T49_QTDEMU',MODEL_FIELD_OBRIGAT,.T.)
oStruT49:SetProperty('T49_CODFOR',MODEL_FIELD_OBRIGAT,.T.)

oModel:GetModel('TFPDETAIL'):SetOptional(.T.)
oModel:GetModel('TFPDETAIL'):SetLoadFilter( { { 'TFP_MOVIM', "{'1','2'}", MVC_LOADFILTER_IS_CONTAINED } } )
oModel:SetPrimaryKey({"TE2_FILIAL","TE2_CODPRO"})

oStruTFP:SetProperty('TFP_MOVIM', MODEL_FIELD_TITULO,'Tipo')

oModel:SetActivate({|oModel| At730Init( oModel ) })

Return(oModel)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef

Definição da View 
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpO:oView
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ViewDef()
Local oView
Local oModel    := FWLoadModel('TECA730')
Local oStruTE2  := FWFormStruct(2,'TE2',{|cCampo| !AllTrim(cCampo) $ "TE2_ITEM|TE2_SEQ|TE2_DOC|TE2_SERIE|TE2_DTNOTA|TE2_COMPRA|TE2_CODFOR|TE2_LOJA|TE2_NOME|TE2_CNPJ|TE2_REGFOR|TE2_EMISSA|TE2_QTDMUN|TE2_LOCAL|TE2_CLIDES|TE2_DSCPOS|TE2_DTALOC|TE2_POSTAL|TE2_SINAE|TE2_SINARM|TE2_DTSINA"})
Local oStruT49	:= FWFormStruct(2,'T49',{|cCampo| !AllTrim(cCampo) $ "T49_CODPRO|T49_CODMUN|T49_ORIGEM"})
Local oStruTFP	:= FWFormStruct(2,'TFP',{|cCampo| AllTrim(cCampo) $ "TFP_CODINT|TFP_CODLOC|TFP_SALDO|TFP_DTHIST|TFP_MOVIM"})

oView:= FWFormView():New()
oView:SetModel(oModel)

oStruTFP:AddField( "TFP_DESLOC",;           // cIdField
                "36",;                   // cOrdem
                "Desc. Local",;           	 // cTitulo //"Desc. Local"
                "Desc. Local",;   			 // cDescric //"Desc. Local"
                Nil,;                    // aHelp
                "GET",;                  // cType
                PesqPict("ABS","ABS_DESCRI"),;// cPicture
                NIL,;                    // nPictVar
                "",;                     // Consulta F3
                .F.,;                    // lCanChange
                NIL,;                    // cFolder
                NIL,;                    // cGroup
                {},;                     // aComboValues
                Nil,;                    // nMaxLenCombo
                NIL,;                    // cIniBrow
                .T.,;                    // lVirtual
                NIL )                    // cPictVar

oStruTFP:AddField( "TFP_DESLCI",;           // cIdField
                "36",;                   // cOrdem
                "Desc. Loc Int",;           	 // cTitulo //"Desc. Local"
                "Desc. Loc Int",;   			 // cDescric //"Desc. Local"
                Nil,;                    // aHelp
                "GET",;                  // cType
                PesqPict("ABS","ABS_DESCRI"),;// cPicture
                NIL,;                    // nPictVar
                "",;                     // Consulta F3
                .F.,;                    // lCanChange
                NIL,;                    // cFolder
                NIL,;                    // cGroup
                {},;                     // aComboValues
                Nil,;                    // nMaxLenCombo
                NIL,;                    // cIniBrow
                .T.,;                    // lVirtual
                NIL )                    // cPictVar
                
oStruTFP:SetProperty('TFP_MOVIM', MVC_VIEW_ORDEM ,'01')                
oStruTFP:SetProperty('TFP_CODINT', MVC_VIEW_ORDEM ,'02')
oStruTFP:SetProperty('TFP_DESLCI', MVC_VIEW_ORDEM ,'03')
oStruTFP:SetProperty('TFP_CODLOC', MVC_VIEW_ORDEM ,'04')
oStruTFP:SetProperty('TFP_DESLOC', MVC_VIEW_ORDEM ,'05')
oStruTFP:SetProperty('TFP_SALDO', MVC_VIEW_ORDEM ,'06')
oStruTFP:SetProperty('TFP_DTHIST', MVC_VIEW_ORDEM ,'07')


oView:AddUserButton(STR0007, 'CLIPS',{|oView|MsDocument('TE2',TE2->(RECNO()),oModel:GetOperation() )}) //"Bco. Conhecimento"

oView:AddUserButton(STR0019, 'CLIPS',{|oView| At730Ocorr(FwFldGet("TE2_CODPRO"))}) //"Ocorrencias"

oView:AddUserButton(STR0020, 'CLIPS',{|oView| At730Manut(FwFldGet("TE2_CODMUN"))}) //"Manutenções"

oView:AddUserButton(STR0021, 'CLIPS',{|oView| At730Movim(FwFldGet("TE2_CODPRO"))}) //"Movimentações"

oView:AddUserButton(STR0022, 'CLIPS',{|oView| At730Aloc(FwFldGet("TE2_CODMUN"))}) //"Alocações"

oView:AddUserButton(STR0023, 'CLIPS',{|oView| At730Descarte(FwFldGet("TE2_CODMUN"))}) //"Descartes"

oStruTE2:RemoveField("TE2_ORIGEM")

oView:CreateHorizontalBox('TELA',100)

// Criação da pasta para conter as abas da parte inferior
oView:CreateFolder( "ABAS", "TELA" )

// Criação das Abas
oView:AddSheet( "ABAS", "ABA01", "Munições" ) // 'Munições'
oView:AddSheet( "ABAS", "ABA02", "Entrada de Munições" ) // 'Entrada de Munições'
oView:AddSheet( "ABAS", "ABA03", "Saldo" ) // 'Entrada de Munições'

// Criação das áreas de exibição dos dados nas abas
oView:CreateHorizontalBox( "ID_ABA01", 100,,, "ABAS", "ABA01" )
oView:CreateHorizontalBox( "ID_ABA02", 100,,, "ABAS", "ABA02" )
oView:CreateHorizontalBox( "ID_ABA03", 100,,, "ABAS", "ABA03" )

oView:AddField('VIEW_CAB1',oStruTE2,'TE2MASTER')
oView:SetOwnerView( 'VIEW_CAB1','ID_ABA01' )

oView:AddGrid('VIEW_CAB2',oStruT49,'T49DETAIL')
oView:SetOwnerView( 'VIEW_CAB2','ID_ABA02' )

oView:AddGrid('VIEW_CAB3',oStruTFP,'TFPDETAIL')
oView:SetOwnerView( 'VIEW_CAB3','ID_ABA03' )

oView:AddIncrementField( 'VIEW_CAB2', 'T49_CODIGO' )

Return(oView)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730Imp

Inclusão da Munição quando é adicionado uma nota Fiscal de Entrada
@author Serviços
@since 28/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730Imp(cCod, cSerie, cForn, cLoja, cProd, cItem)
Local lRet := .T.

Processa( { || lRet := At730Inc(cCod, cSerie, cForn, cLoja, cProd, cItem) },STR0042,STR0043,.F.)//'Aguarde';'Realizando Inclusão de Munições'

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730Inc

Inclusão do Munição quando é adicionado uma nota Fiscal de Entrada
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730Inc(cCod, cSerie, cForn, cLoja, cProd, cItem)
Local oModel
Local lRet 		:=.T.
Local aAreaSD1 	:= SD1->(GetArea())
Local aAreaSA2 	:= SA2->(GetArea())
Local nQuant		:= 0
Local oTE2Master := Nil
Local oT49Detail := Nil
Local cItT49		:= Replicate("0", (TamSx3('T49_CODIGO')[1]))

DbSelectArea('SD1')
SD1->(DbSetOrder(1)) // A1_FILIAL+A1_COD+A1_LOJA
//If SD1->(DbSeek(xFilial('SD1')+ SD1->D1_COD + SD1->D1_DOC + SD1->D1_SERIE + SD1->D1_FORNECE + SD1->D1_LOJA)) // Filial: 01, Código: 000001, Loja: 02

If SD1->(DbSeek(xFilial('SD1')+ cCod + cSerie + cForn + cLoja + cProd + cItem)) // Filial: 01, Código: 000001, Loja: 02

	DbSelectArea('SA2')
	SA2->(DbSetOrder(1))
	SA2->(DbSeek(xFilial("SA2") + SD1->D1_FORNECE + SD1->D1_LOJA))

	//For nQuant:= 1 To SD1->D1_QUANT

		oModel:=FwloadModel('TECA730')
		TE2->(DbSetOrder(4))
		oTE2Master := oModel:GetModel('TE2MASTER')
		oT49Detail := oModel:GetModel('T49DETAIL')
		
		If !TE2->(DbSeek(xFilial("TE2") + SD1->D1_COD))
			oModel:SetOperation(MODEL_OPERATION_INSERT)	
			oModel:Activate()
			oTE2Master:SetValue('TE2_CODPRO',SD1->D1_COD)
		Else
			oModel:SetOperation(MODEL_OPERATION_UPDATE)
			oModel:Activate()
				
			If !oT49Detail:IsEmpty()
				oT49Detail:GoLine(oT49Detail:Length())
				cItT49 := oT49Detail:GetValue('T49_CODIGO')
				oT49Detail:AddLine()
			EndIf	
		EndIf
				
		
		oT49Detail:LoadValue('T49_DOC',SD1->D1_DOC)
		oT49Detail:LoadValue('T49_SERIE',SD1->D1_SERIE)		
		//Atualiza campo _SDOC dos documentos fiscais, caso habilitado
		/*If SerieNFId("T49", 3, "T49_SERIE") != "T49_SERIE"					
			lAux:= oModel:SetValue('T49DETAIL',SerieNFId("T49", 3, "T49_SERIE"), SerieNFId("SD1", 2, "D1_SERIE"))
		EndIf*/
		
		oT49Detail:LoadValue('T49_CODIGO',Soma1(cItT49)) 
		oT49Detail:LoadValue('T49_DTNOTA',SD1->D1_EMISSAO)
		oT49Detail:LoadValue('T49_COMPRA',SD1->D1_EMISSAO)
		oT49Detail:LoadValue('T49_CODFOR',SD1->D1_FORNECE)
		oT49Detail:LoadValue('T49_LOJA',SD1->D1_LOJA)
		oT49Detail:LoadValue('T49_CODPRO',SD1->D1_COD)
		oT49Detail:LoadValue('T49_ITEM',SD1->D1_ITEM)
		oT49Detail:LoadValue('T49_QTDEMU',SD1->D1_QUANT)	
		oT49Detail:LoadValue('T49_ORIGEM',"MATA103")
		oT49Detail:LoadValue('T49_NOME',SA2->A2_NOME)
		oT49Detail:LoadValue('T49_CNPJ',SA2->A2_CGC)
		

		If ( lRet := oModel:VldData() )
			// Se o dados foram validados faz-se a gravação efetiva dos dados (commit)
			oModel:CommitData()
		EndIf
			
		If !lRet
			// Se os dados não foram validados obtemos a descrição do erro para gerar LOG ou 
			//mensagem de aviso
			aErro := oModel:GetErrorMessage()
					 
			AutoGrLog( STR0008 + ' [' + AllToChar( aErro[1] ) + ']' ) //"Id do formulário de origem:"
			AutoGrLog( STR0009 + ' [' + AllToChar( aErro[2] ) + ']' ) //"Id do campo de origem: "
			AutoGrLog( STR0010 + ' [' + AllToChar( aErro[3] ) + ']' ) //"Id do formulário de erro: "
			AutoGrLog( STR0011 + ' [' + AllToChar( aErro[4] ) + ']' ) //"Id do campo de erro: "
			AutoGrLog( STR0012 + ' [' + AllToChar( aErro[5] ) + ']' ) //"Id do erro: "
			AutoGrLog( STR0013 + ' [' + AllToChar( aErro[6] ) + ']' ) //"Mensagem do erro: "
			AutoGrLog( STR0014 + ' [' + AllToChar( aErro[7] ) + ']' ) //"Mensagem da solução: "
			AutoGrLog( STR0015 + ' [' + AllToChar( aErro[8] ) + ']' ) //"Valor atribuído: "
			AutoGrLog( STR0016 + ' [' + AllToChar( aErro[9] ) + ']' )//"Valor anterior: "
		
			MostraErro()
					
			// Desativamos o Model 
			oModel:DeActivate()
		EndIf
			
	//Next nQuant

EndIf

RestArea(aAreaSD1)
RestArea(aAreaSA2)

Return lRet
		
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730Vld

Validação do cadastro de Munições
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpO:Model do Cadastro de Munições
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At730Vld(oModel)
Local lRet       := .T.
Local nOperation := oModel:GetOperation()
Local cCodPro	 := oModel:GetValue('TE2MASTER','TE2_CODPRO')
Local nI 		 := 0
Local aSaldos 	 := {}		
Local aArea		 := GetArea()

//Não permite a exclusão quando a Situação for diferente de 1
If nOperation == 5	

	//Não permite excluir se a munição foi movimentada ou Alocada
	If At730MvMun(cCodPro) .Or. !Empty(FwFldGet("TE2_LOCAL"))
		Help( ,, "At730Vld",, STR0018, 1, 0 )//"A Munição já foi movimentada, não é possivel alterar/Excluir"
		lRet := .F.
	EndIf
	
ElseIf nOperation == 3 .OR. nOperation == 4
	
	If nOperation == 4
		aSaldos := At730LocSl(oModel:GetModel('T49DETAIL'))
		TFP->(DbSetOrder(7))
		For nI := 1 To Len(aSaldos)
			If !lRet
				Exit
			EndIf	
			If TFP->(DbSeek(xFilial("TFP") + '1' + aSaldos[nI,1] + cCodPro))
				If (At730QtdDB(cCodPro,aSaldos[nI,1]) - aSaldos[nI,2]) > TFP->TFP_SALDO
					lRet := .F.
					Help( ,, "At730Qtd",, STR0032 + Alltrim(cCodPro) + STR0033, 1, 0 )//STR0081  STR0082
				EndIf	  		
			EndIf
		Next nI	
	EndIf	
	
	If lRet .And. !At730Prod(FwfldGet("TE2_CODPRO"))
		Help("  ",1,"AT730Prod")
		lRet := .F.
	EndIf
EndIf

/*If lRet .And. (nOperation == 3 .Or. nOperation == 4) .And. (!Empty(FwFldGet("TE2_LOCAL")))

	If !At730Status()
		Help( "", 1, "At730Status" )
		lRet := .F.	
	EndIf
EndIf*/

RestArea(aArea)
Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730DescFor

Realiza o preenchimento da descrição do Fornecedor e do CNPJ do Fornecedor
@author Serviços
@since 20/08/13
@version P11 R9

@Param nPos,Indica qual o campo que será preenchido

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730DescFor(nPos)
Local cDesc		:= ""
Local oModel
Local aAreaSA2		:= SA2->(GetArea())

Default nPos := 0

If nPos > 0
	DbSelectArea("SA2")
	DbSetOrder(1)
	
	If DbSeek(xFilial("SA2") + FwFldGet("TE2_CODFOR") + FwFldGet("TE2_LOJA"))
		If nPos == 1
			oModel := FWModelActive()
			oModel:setValue("TE2MASTER",'TE2_CNPJ',SA2->A2_CGC)
		ElseIf nPos == 2
			cDesc := SA2->A2_NOME
		EndIf	
	EndIf
EndIf

RestArea(aAreaSA2)
					
Return(cDesc)	

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730DescPro

Realiza o preenchimento da descrição do Produto
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730DescPro()
Local cDesc		:= ""
Local aAreaSB1		:= SB1->(GetArea())

cDesc := Posicione("SB1",1,xFilial("SB1") + FwFldGet("TE2_CODPRO"),"SB1->B1_DESC")

RestArea(aAreaSB1)

Return(cDesc)	

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730DscLoc

Realiza o preenchimento da descrição do Local Interno
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpC:Retorna a Descrição do Local Interno
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730DscLoc()
Local cLocal		:= ""
Local aAreaTER	:= TER->(GetArea())

cLocal	:= Posicione("TER",1,xFilial("TER") + FwFldGet("TE2_LOCAL"),"TER->TER_DESCRI")

RestArea(aAreaTER)

Return(cLocal)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730When

Habilita os campos Forncedor e Produto quando a Origem não for MATA103
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730When()
Local lRet 		:= .T.
Local oModel		:= FWModelActive() 
Local nOperation	:= oModel:GetOperation()

//Não deixa alterar o fornecedor e o produto quando o mesmo tiver vinculo com Nota Fiscal
//If nOperation == 4 .AND. Alltrim(TE2->TE2_ORIGEM) == "MATA103"
If Alltrim(TE2->TE2_ORIGEM) == "MATA103"
	lRet := .F.
EndIf

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730WLocal

Desabilita o campo de Local quando ele já está preenchido
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730WLocal()
Local lRet 		:= .T.
Local oModel		:= FWModelActive() 
Local nOperation	:= oModel:GetOperation()

//Não deixa alterar o fornecedor e o produto quando o mesmo tiver vinculo com Nota Fiscal
If nOperation == 4 .AND. !Empty(TE2->TE2_LOCAL)
	lRet := .F.
EndIf

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730Exc

Exclui o registro da Arma, através da exclusão da NFE
Informa ao usuario e pergunta se ele deseja continuar com a Exclusão

@author Serviços
@since 20/08/13
@version P11 R9

@Param cDoc,Numero do Documento de Entrada
@Param cSerie,Numero da Serie do Documento de Entrada

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730Exc(cDoc,cSerie,lExc,cItem)
Local lRet			:= .T.
Local aAreaT49		:= T49->(GetArea())

Default cDoc		:= ""
Default cSerie		:= ""
Default lExc		:= .F.

DbSelectArea("T49")
T49->(DbSetOrder(2))

If T49->(DbSeek(xFilial("T49") + cDoc + cSerie + cItem ))
	If Alltrim(T49->T49_ORIGEM) == "MATA103" .And. At730Saldo()
		If !lExc
			lRet :=MsgYesNo(STR0017) //"Essa Nota está vinculada a uma munição ativa no cadastro de Munições, Deseja Continuar?"
		EndIf
		If lExc
			While !T49->(Eof()) .And. T49->T49_DOC == cDoc .And. T49->T49_SERIE == cSerie .And. T49->T49_ITEM = cItem
				RecLock("T49",.F.)
					T49->( dbDelete() )
					T49->( MsUnlock() )
				T49->(dbSkip())
			End
		EndIf	
	ElseIf Alltrim(T49->T49_ORIGEM) == "MATA103" .And. !At730Saldo()
		Help( "", 1, "At730Mov" )
	EndIf
EndIf

RestArea(aAreaT49)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730Mov

Verifica se a Arma está movimentada ou com o Status Frear alterado

@author Serviços
@since 20/08/13
@version P11 R9

@Param cDoc,Numero do Documento de Entrada
@Param cSerie,Numero da Serie do Documento de Entrada

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730Mov(cDoc,cSerie)
Local lRet			:= .T.
Local aAreaT49		:= T49->(GetArea())

Default cDoc		:= ""
Default cSerie		:= ""

DbSelectArea("T49")
T49->(DbSetOrder(2))

If T49->(DbSeek(xFilial("T49") + cDoc + cSerie))
	If  Alltrim(T49->T49_ORIGEM) == "MATA103" .And. !At730Saldo(TE2->TE2_LOCAL,TE2->TE2_LOTE)
		lRet := .F.
	EndIf
EndIf

RestArea(aAreaT49)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730Status

Verifica campos Obrigatorios para a troca de Status da Munição

@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730Status()
Local lRet	:= .T.
Local oModel		:= FWModelActive() 
Local nOperation	:= oModel:GetOperation()

//Verifica se os campos estão preenchidos para alterar o Status para Implantado
If nOperation == 4 .Or. nOperation == 3
	If (Empty(FwFldGet("TE2_ORGAO")).OR.;
	   Empty(FwfldGet("TE2_ESPEC")) .OR. Empty(FwFldGet("TE2_MARCA")) .OR. Empty(FwFldGet("TE2_CALIBR")).OR. ;
	   Empty(FwfldGet("TE2_MODELO")) .OR. Empty(FwFldGet("TE2_SINARM")))
		
		lRet := .F.
	EndIf	
EndIf

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730Prod

Valida o Tipo de Produto no cadastro, para não permitir a inclusão de produtos que não
são do tipo Munição

@author Serviços
@since 20/08/13
@version P11 R9

@Param ExpC,Codigo do Produto

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730Prod(cProd)
Local lRet		:= .T.
Local aAreaSB1	:= SB1->(GetArea())

Default cProd	:= ""

If !Empty(cProd)
	//Verifica se a unidade do Produto Munição é Caixa ou "UN" unidade. 
	If SB1->(Dbseek(xFilial("SB1") + cProd))
		
		If SB1->B1_UM <> "CX" .AND. SB1->B1_UM <> "UN"
			lRet := .F.
		EndIf
	EndIf
EndIf

RestArea(aAreaSB1)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730VldUn

Verifica se o produto munição tem o seu tipo de unidade como CX, senão informa ao usuario.
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730VldUn()
Local lRet			:= .T.
Local aAreaSB5 	:= SB5->(GetArea())

DbSelectArea('SB5')
SB5->(DbSetOrder(1)) // acordo com o arquivo SIX -> A1_FILIAL+A1_COD+A1_LOJA

If SB5->(DbSeek(xFilial("SB5")+FwFldGet("TE2_CODPRO"))) // Filial: 01, Código: 000001, Loja: 02
			
	If SB5->B5_TPISERV=='3' 
		If !At730Prod(FwFldGet("TE2_CODPRO"))
			Help( ,, "At730VldUn",, STR0029, 1, 0 )//"Para produtos com complemento do tipo Munição o produto deve ter a sua Unidade de Medida CX"
			lRet := .F.
		EndIf
	Else
		Help("  ",1,"AT730Tipo")
		lRet := .F.		
	EndIf
Else
	lRet := .F.
EndIf

		
RestArea(aAreaSB5)

Return(lRet)
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730Saldo

Gatilha o valor da quantidade para o Saldo.
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730Saldo(cLocal,cProduto)
Local lRet	:= .T.
Local aArea := GetArea()

Default cLocal	 := ""
Default cProduto := ""

DbSelectArea("TFP")
TFP->(DbSetOrder(6))

If IsIncallStack("MATA103")

//If nOperation == 3 

	If !Empty(cLocal) .And. !Empty(cProduto)
	
		If TFP->(DbSeek(xFilial("TFP") + "1" + cLocal + cProduto))
			If TFP->TFP_SALDO <> TE2->TE2_QTDMUN
				lRet := .F.
			EndIf
		EndIf	
	EndIf

Else
	
	If Empty(cLocal) .And. Empty(cProduto)

		If TFP->(DbSeek(xFilial("TFP") + "1" + FwFldGet("TE2_LOCAL") + FwFldGet("TE2_CODPRO")))
			If TFP->TFP_SALDO <> TE2->TE2_QTDMUN
				lRet := .F.
			EndIf
		EndIf

	Else
		If TFP->(DbSeek(xFilial("TFP") + "1" + cLocal + cProduto))
			If TFP->TFP_SALDO <> TE2->TE2_QTDMUN
				lRet := .F.
			EndIf
		EndIf
	EndIf
	
EndIf

RestArea(aArea)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730VldProd

Valida o Tipo de Produto no cadastro, para não permitir a inclusão de produtos que não
são do tipo Munição
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730VldProd()
Local lRet			:= .T.
Local aAreaSB5 	:= SB5->(GetArea())

DbSelectArea('SB5')
SB5->(DbSetOrder(1)) // acordo com o arquivo SIX -> A1_FILIAL+A1_COD+A1_LOJA


If SB5->(DbSeek(xFilial('SB5')+FwFldGet("TE2_CODPRO"))) // Filial: 01, Código: 000001, Loja: 02
			
	If SB5->B5_TPISERV <>'3' 
		Help("  ",1,"AT730Tipo")
		lRet := .F.		
	EndIf
Else
	Help("  ",1,"AT730Tipo")
	lRet := .F.	
EndIf

		
RestArea(aAreaSB5)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730Commit

Realiza o Commit do Modelo de Dados e gera a linha de Saldo da Munição na Tabela TFP

@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At730Commit(oModel)
Local lRet			:= .T.
Local nOperation	:= oModel:GetOperation()
Local oTE2Master    := oModel:GetModel('TE2MASTER')
Local oT49Detail    := oModel:GetModel('T49DETAIL')
Local aSaldos		:= {}
Local nI 			:= 1

If nOperation == MODEL_OPERATION_UPDATE .Or. nOperation == MODEL_OPERATION_INSERT	
	//Verifica se o saldo da alocação inicial foi alterado, senão não será permitida a sua alteração
	aSaldos :=  At730LocSl(oT49Detail)
	For nI := 1 To Len(aSaldos) 
	 
		DbSelectArea("TFP")
		TFP->(DbSetOrder(7))

		If TFP->(DbSeek(xFilial("TFP") + '1' + aSaldos[nI,1] + oTE2Master:GetValue("TE2_CODPRO")))
		
			Begin Transaction
				DbSelectArea("TFP")
				RecLock("TFP",.F.)
					REPLACE TFP_SALDO	With TFP_SALDO + (aSaldos[nI,2] - At730QtdDB(oTE2Master:GetValue("TE2_CODPRO"),aSaldos[nI,1] ))  
					REPLACE TFP_DTHIST	With dDataBase
					REPLACE TFP_STATUS	With "1"								//Efetivada	
				MsUnlock()
				ConfirmSX8()
			End Transaction
		Else
			Begin Transaction
				RecLock("TFP",.T.)
					REPLACE TFP_FILIAL 	With xFilial("TFP")
					REPLACE TFP_CODIGO 	With GetSXENum("TFP","TFP_CODIGO") 
					REPLACE TFP_ENTIDA 	With "1"
					REPLACE TFP_CODINT 	With aSaldos[nI,1]		
					REPLACE TFP_SALDO	With aSaldos[nI,2]
					REPLACE TFP_MOVIM 	With "1"
					REPLACE TFP_CODMUN	With oTE2Master:GetValue("TE2_CODMUN")
					REPLACE TFP_DTHIST	With dDataBase
					REPLACE TFP_STATUS	With "1"								//Efetivada
					REPLACE TFP_PRODUT	With oTE2Master:GetValue("TE2_CODPRO")	
				MsUnlock()
				ConfirmSX8()
			End Transaction
		oModel:setValue("TE2MASTER",'TE2_DTALOC',dDataBase)	
		
		EndIf	
	Next nI
		
ElseIf nOperation == MODEL_OPERATION_DELETE
	DbSelectArea("TFP")
	TFP->(DbSetOrder(7))

	If TFP->(DbSeek(xFilial("TFP") + oTE2Master:GetValue("TE2_CODPRO")))
		
		Begin Transaction	
			RecLock("TFP",.F.)
				TFP->(DbDelete())
			MsUnlock()
		End Transaction
	EndIf
	
EndIf

If lRet	
	FWModelActive( oModel )
	FWFormCommit( oModel )
EndIf

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730Ocorr

Monta a Tela com todas as ocorrencias relacionadas ao Colete
@author Serviços
@since 20/08/13
@version P11 R9

@Param cColete,Codigo do Colete
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730Ocorr(cMunicao)
Local oPanel		:= Nil
Local oBrowse		:= Nil
Local aBckp		:= aClone(aRotina)

aRotina := {}

DEFINE MSDIALOG oPanel TITLE STR0019 FROM 050,050 TO 500,800 PIXEL//"Ocorrencias"

oBrowse:= FWmBrowse():New()
oBrowse:SetOwner( oPanel )   
oBrowse:SetDescription( STR0024 ) //"Lista de Ocorrencias" 
oBrowse:SetAlias( "TET" ) 
oBrowse:DisableDetails() 
oBrowse:SetWalkThru(.F.)
oBrowse:SetAmbiente(.F.)
oBrowse:SetProfileID("12")
oBrowse:SetMenuDef( "  " )
oBrowse:SetFilterDefault( "TET_PRODUT = '" + cMunicao + "'" ) 
oBrowse:Activate() 

//bloco de codigo para duplo click - deve ficar após o activate, senao o FWMBrowse ira sobreescrever com o bloco padrao
oBrowse:BlDblClick := {||At730VisOcor()} 
oBrowse:Refresh()

ACTIVATE MSDIALOG oPanel CENTERED

aRotina := aBckp
aBckp	:= {}

Return
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730VisOcor

Ação do Duplo-click na Ocorrencias, abrindo o cadastro de ocorrencia no modo 
Visualização
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730VisOcor()
Local aArea		:= GetArea()
                 
DbSelectArea("TE4")
TE4->(DbSetOrder(1))
	
If TE4->(DbSeek(xFilial("TE4")+TET->TET_CDOCOR))
	FWExecView(Upper(STR0003),"VIEWDEF.TECA750",MODEL_OPERATION_VIEW,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/)	
EndIf

RestArea(aArea)

Return (.T.)
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730Manut

Monta a Tela com todas as ocorrencias relacionadas a Arma
@author Serviços
@since 20/08/13
@version P11 R9

@Param cArma,Codigo da Arma 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730Manut(cMunicao)
Local oPanel		:= Nil
Local oBrowse		:= Nil
Local aBckp		:= aClone(aRotina)

aRotina := {}

DEFINE MSDIALOG oPanel TITLE STR0020 FROM 050,050 TO 500,800 PIXEL//"Manutenções"

oBrowse:= FWmBrowse():New()
oBrowse:SetOwner( oPanel )   
oBrowse:SetDescription( STR0025 ) //"Lista de Manutenções"
oBrowse:SetAlias( "TEU" ) 
oBrowse:DisableDetails() 
oBrowse:SetWalkThru(.F.)
oBrowse:SetAmbiente(.F.)
oBrowse:SetProfileID("13")
oBrowse:SetMenuDef( "  " )
oBrowse:SetFilterDefault( "TEU_TPARMA = '3' .AND. TEU_CDARM = '" + cMunicao + "' " ) 
oBrowse:Activate() 

//bloco de codigo para duplo click - deve ficar após o activate, senao o FWMBrowse ira sobreescrever com o bloco padrao
oBrowse:BlDblClick := {||At730VisManut()} 
oBrowse:Refresh()

ACTIVATE MSDIALOG oPanel CENTERED

aRotina := aBckp
aBckp	:= {}

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730VisManut

Ação do Duplo-click na Ocorrencias, abrindo o cadastro de ocorrencia no modo 
Visualização
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730VisManut()
Local aArea		:= GetArea()
                 
DbSelectArea("TEU")
TEU->(DbSetOrder(1))
	
If TEU->(DbSeek(xFilial("TEU")+TEU->TEU_CODIGO))
	FWExecView(Upper(STR0003),"VIEWDEF.TECA780",MODEL_OPERATION_VIEW,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/)	
EndIf

RestArea(aArea)

Return (.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730Movim

Monta a Tela com todas as movimentações relacionadas a arma
@author Serviços
@since 20/08/13
@version P11 R9

@Param cMunicao,Codigo da Arma 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730Movim(cMunicao)
Local oPanel		:= Nil
Local oBrowse		:= Nil
Local aBckp		:= aClone(aRotina)

aRotina := {}

DEFINE MSDIALOG oPanel TITLE STR0021 FROM 050,050 TO 500,800 PIXEL//"Movimentações"

oBrowse:= FWmBrowse():New()
oBrowse:SetOwner( oPanel )   
oBrowse:SetDescription( STR0026 ) //"Lista de Movimentações"
oBrowse:SetAlias( "TFO" ) 
oBrowse:DisableDetails() 
oBrowse:SetWalkThru(.F.)
oBrowse:SetAmbiente(.F.)
oBrowse:SetProfileID("14")
oBrowse:SetMenuDef( "  " )
oBrowse:SetFilterDefault( "TFO_ITMOV = '3' .AND. TFO_PRODUT = '" + cMunicao + "' " ) 

oBrowse:Activate() 

//bloco de codigo para duplo click - deve ficar após o activate, senao o FWMBrowse ira sobreescrever com o bloco padrao
oBrowse:BlDblClick := {||At730VisMovim()} 
oBrowse:Refresh()

ACTIVATE MSDIALOG oPanel CENTERED

aRotina := aBckp
aBckp := {}

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730VisMovim

Ação do Duplo-click na Movimentação, abrindo o cadastro de movimentaadminções no modo 
Visualização
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730VisMovim()
Local aArea		:= GetArea()
                 
DbSelectArea("TFQ")
TFQ->(DbSetOrder(1))
	
If TFQ->(DbSeek(xFilial("TFQ")+TFO->TFO_CDMOV))
	FWExecView(Upper(STR0003),"VIEWDEF.TECA880",MODEL_OPERATION_VIEW,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/)	
EndIf

RestArea(aArea)

Return (.T.)
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730Aloc

Monta a Tela com todas as Alocações da Munição		
@author Serviços
@since 20/08/13
@version P11 R9

@Param cMunicao,Codigo da Munição
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730Aloc(cMunicao)
Local oPanel		:= Nil
Local oBrowse		:= Nil
Local aBckp		:= aClone(aRotina)

aRotina := {}

DEFINE MSDIALOG oPanel TITLE STR0022 FROM 050,050 TO 500,800 PIXEL//"Alocações"

oBrowse:= FWmBrowse():New()
oBrowse:SetOwner( oPanel )   
oBrowse:SetDescription( STR0027 ) //"Lista de Alocações"
oBrowse:SetAlias( "TFP" ) 
oBrowse:DisableDetails() 
oBrowse:SetWalkThru(.F.)
oBrowse:SetAmbiente(.F.)
oBrowse:SetProfileID("16")
oBrowse:SetMenuDef( "  " )
oBrowse:SetFilterDefault( "(TFP_MOVIM = '1' .OR. TFP_MOVIM = '2') .AND. TFP_SALDO > 0 .AND. TFP_CODMUN = '" + cMunicao + "' " ) 
oBrowse:Activate() 

oBrowse:Refresh()

ACTIVATE MSDIALOG oPanel CENTERED

aRotina := aBckp
aBckp := {}

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730Descarte

Monta a Tela com todas as Alocações da Munição		
@author Serviços
@since 20/08/13
@version P11 R9

@Param cMunicao,Codigo da Munição
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730Descarte(cMunicao)
Local oPanel		:= Nil
Local oBrowse		:= Nil
Local aBckp		:= aClone(aRotina)

aRotina := {}

DEFINE MSDIALOG oPanel TITLE STR0023 FROM 050,050 TO 500,800 PIXEL//"Descartes"

oBrowse:= FWmBrowse():New()
oBrowse:SetOwner( oPanel )   
oBrowse:SetDescription( STR0028 ) //"Lista de Munições Descartadas"
oBrowse:SetAlias( "TFP" ) 
oBrowse:DisableDetails() 
oBrowse:SetWalkThru(.F.)
oBrowse:SetAmbiente(.F.)
oBrowse:SetProfileID("17")
oBrowse:SetMenuDef( "  " )
oBrowse:SetFilterDefault( "TFP_MOVIM = '8'.AND. TFP_CODMUN = '" + cMunicao + "' " ) 
oBrowse:Activate() 

oBrowse:Refresh()

ACTIVATE MSDIALOG oPanel CENTERED

aRotina := aBckp
aBckp := {}

Return


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730SAtual

Monta a Tela com todas as Alocações da Munição		
@author Serviços
@since 20/08/13
@version P11 R9

@Param cMunicao,Codigo da Munição
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730SAtual(cMunicao)
Local oPanel		:= Nil
Local oBrowse		:= Nil
Local aBckp		:= aClone(aRotina)

aRotina := {}

DEFINE MSDIALOG oPanel TITLE STR0031 FROM 050,050 TO 500,800 PIXEL //"Saldo Atualizado"

oBrowse:= FWmBrowse():New()
oBrowse:SetOwner( oPanel )   
oBrowse:SetDescription( STR0031 ) //"Saldo Atualizado"
oBrowse:SetAlias( "TFP" ) 
oBrowse:DisableDetails() 
oBrowse:SetWalkThru(.F.)
oBrowse:SetAmbiente(.F.)
oBrowse:SetProfileID("18")
oBrowse:SetMenuDef( "  " )
oBrowse:SetFilterDefault( "(TFP_MOVIM = '1' .Or. TFP_MOVIM = '2') .AND. TFP_CODMUN = '" + cMunicao + "' " ) 
oBrowse:Activate() 

oBrowse:Refresh()

ACTIVATE MSDIALOG oPanel CENTERED

aRotina := aBckp
aBckp := {}

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TecFilMun

Retorna a consulta especifica para munições.

@since 25/08/2017
@version P12.1.17
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TecFilMun(nOpc)

Local lRet := .F.

	lRet:= TxProdArm(3)

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} PreValT49

Valida se é possível excluir munição, a partir da Nota Fiscal.

@since 25/08/2017
@version P12
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Function PreValT49(oModelGrid, nLine, cAction, cField)

Local lRet := .T.

If cAction == 'DELETE' .And. !Empty(oModelGrid:GetValue('T49_DOC'))
	Help("",,"AT730DelNF") // Não é possível excluir se a munição possuir vínculo com Nota Fiscal. 
	lRet := .F.
	
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730GetQt

Retorna a quantidade de entrada de uma munição

@since 20/10/2017
@version P12
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730GetQt(oMdlT49)
Local nRet := 0
Local nI := 0

For nI := 1 To oMdlT49:Length()
	oMdlT49:GoLine(nI)
	If !oMdlT49:IsDeleted()
		nRet += oMdlT49:GetValue('T49_QTDEMU')
	EndIf	 	
Next nI

Return nRet 

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730MvMun

Valida se é possível excluir munição, a partir da Nota Fiscal.

@since 18/10/2017
@version P12
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730MvMun(cCodPro)
Local lRet  := .F.
Local cTemp := GetNextAlias()


BeginSQL Alias cTemp
	
	SELECT 
		1
	FROM 	
		%Table:TFP% TFP
	WHERE 
		TFP.TFP_FILIAL = %Exp:xFilial("TFP")% AND
		TFP.TFP_PRODUT = %Exp:cCodPro% AND
		TFP.TFP_MOVIM = 2 AND
		TFP.TFP_MOVIM = 2 AND
		
		TFP.%NotDel%
EndSql

lRet := ( cTemp )->( !Eof() )

Return lRet






//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730LocSl

Valida se é possível excluir munição, a partir da Nota Fiscal.

@since 18/10/2017
@version P12
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730LocSl(oT49Detail)
Local aRet 	:= {}
Local nI  	:= 1
Local nPos 	:= 0


For nI := 1 To oT49Detail:Length()
	oT49Detail:GoLine(nI)
	If !oT49Detail:IsDeleted() .And. !Empty(oT49Detail:GetValue('T49_LOCINT'))
		nPos := Ascan(aRet, {|x| x[1] == oT49Detail:GetValue('T49_LOCINT')})
		If nPos == 0
			Aadd(aRet,{oT49Detail:GetValue('T49_LOCINT'),oT49Detail:GetValue('T49_QTDEMU')})
		Else
			aRet[nPos,2] += oT49Detail:GetValue('T49_QTDEMU')
		EndIf	
	EndIf	 	
Next nI

Return aRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730QtdDB

Retorna quantidade de munições no banco de dados

@since 18/10/2017
@version P12
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730QtdDB(cCodPro,cLocal)
Local nRet  := 0
Local cTemp := GetNextAlias()
Local aArea := GetArea()


BeginSQL Alias cTemp
	
	SELECT SUM(T49_QTDEMU) QTD FROM %Table:T49% T49
	WHERE 
		T49.T49_FILIAL = %Exp:xFilial("T49")% AND
		T49.T49_CODPRO = %Exp:cCodPro% AND
		T49.T49_LOCINT = %Exp:cLocal% AND		
		T49.%NotDel%
EndSql

nRet := ( cTemp )->( QTD )

RestArea(aArea)
Return nRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730WhLoc

When do campo local interno da tabela T49

@since 18/10/2017
@version P12
@return Nil
/*/		 
Function At730WhLoc()
Local lRet := .T.
Local oModel := FwModelActive()
Local oT49Detail := oModel:GetModel('T49DETAIL')
Local nOpc := oModel:GetOperation() 

If nOpc == MODEL_OPERATION_UPDATE .And. !Empty(oT49Detail:GetValue('T49_LOCINT'))  .And. !oT49Detail:IsInserted()
	lRet := .F.
EndIf	
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730VldLoc

valid do campo local interno da tabela T49

@since 18/10/2017
@version P12
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730VlLoc()
Local lRet := .T.
Local oModel := FwModelActive()
Local oT49Detail := oModel:GetModel('T49DETAIL')
 
lRet := Empty(GetDBValue("T49","T49_LOCINT",oT49Detail:GetDataId()))

If !lRet
	Help("  ",1,"AT730VLDLOC")           
EndIf 
	
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At730DesLc

Retorna descição do local de atendimento

@since 18/10/2017
@version P12
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At730DesLc()
Local cRet := ""

cRet := Posicione( "ABS", 1, xFilial("ABS")+FwFldGet('TFP_CODLOC'), "ABS_DESCRI")
	
Return cRet


//-------------------------------------------------------------------
/*/{Protheus.doc} At995Init()

@author Matheus Lando Raimundo      
/*/
//------------------------------------------------------------------
Function At730Init( oModel )
Local nI := 1
Local nVlCust := 0
Local oTFPDetail  := oModel:GetModel('TFPDETAIL')
Local cLocal	:= ""
Local cRet	:= ""

oModel:GetModel('TFPDETAIL'):SetNoInsertLine(.F.)
oModel:GetModel('TFPDETAIL'):SetNoUpdateLine(.F.)
oModel:GetModel('TFPDETAIL'):SetNoDeleteLine(.F.)

For nI := 1 To oTFPDetail:Length()
	oTFPDetail:GoLine(nI)
	If !oTFPDetail:IsDeleted()
		If !Empty(oTFPDetail:GetValue('TFP_CODLOC'))			
			cRet   := Posicione( "ABS", 1, xFilial("ABS")+oTFPDetail:GetValue('TFP_CODLOC'), "ABS_DESCRI")
			oTFPDetail:LoadValue('TFP_DESLOC',cRet)
		EndIf
		
		
		If !Empty(oTFPDetail:GetValue('TFP_CODINT'))			
			cRet   := Posicione( "TER", 1, xFilial("TER")+oTFPDetail:GetValue('TFP_CODINT'), "TER_DESCRI")
			oTFPDetail:LoadValue('TFP_DESLCI',cRet)
		EndIf
	EndIf			
Next nI

oModel:GetModel('TFPDETAIL'):SetNoInsertLine(.T.)
oModel:GetModel('TFPDETAIL'):SetNoUpdateLine(.T.)
oModel:GetModel('TFPDETAIL'):SetNoDeleteLine(.T.)
	
Return .T.