#include 'totvs.ch'
#include 'FWMVCDef.ch'
#INCLUDE 'Protheus.ch'
#INCLUDE 'TECA932.ch'

STATIC lSrvExt := .F.
STATIC lContra := .F.
STATIC cChvCli := ""
STATIC aRetTFJ := {"",""}

//------------------------------------------------------------------------------
/*/{Protheus.doc} TECA932
@description	Rotina responsável por configurar Grupos de Faturamento no GS
@sample	 		TECA932()
@return			NIL
@author			Fernando Alves Silva
@since			07/08/2017
@version		P12   
/*/
//------------------------------------------------------------------------------

Function TECA932()
Local cAlias  := "TFJ"
Local oBrowse := Nil

oBrowse := FWMBrowse():New()
oBrowse:SetAlias(cAlias)

oBrowse:SetDescription(STR0001)  //"Cadastro de Clientes por Serviço"

oBrowse:SetFilterDefault( "(!Empty(TFJ->TFJ_CONTRT) .AND. TFJ->TFJ_STATUS == '1' ) .Or. TFJ->TFJ_SRVEXT=='1'" ) 
oBrowse:SetOnlyFields( { 'TFJ_CODIGO' , 'TFJ_CODENT' , 'TFJ_LOJA' , 'TFJ_CONTRT' , 'TFJ_CONREV' } )

oBrowse:AddLegend( "TFJ->TFJ_SRVEXT=='2' .And. !Empty(TFJ->TFJ_CONTRT)" 	, "BR_VERDE"	, STR0002 ) //"Contrato Ativo"
oBrowse:AddLegend( "TFJ->TFJ_SRVEXT=='1' .And. Empty(TFJ->TFJ_CONTRT)" 		, "BR_AZUL"		, STR0003 ) //"Orçamento de Serv. Extra"		 	

oBrowse:Activate()

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef()

MenuDef - Cadastro de Clientes por Serviço

@Return 	MenuDef
@author 	Fernando Alves Silva
@since 		07/08/2017
/*/
//------------------------------------------------------------------------------
Static Function MenuDef()
Local aRotina := {}

ADD OPTION aRotina TITLE STR0004	ACTION "At932CadGF" 		OPERATION 4 ACCESS 0 //"Configurar"
ADD OPTION aRotina TITLE STR0005 	ACTION "PesqBrw"         	OPERATION 1 ACCESS 0 //"Pesquisar"
ADD OPTION aRotina TITLE STR0006 	ACTION "VIEWDEF.TECA932" 	OPERATION 2 ACCESS 0 //"Visualizar"

Return(aRotina)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At932CadGF()

Função responsável por verificar o tipo de vínculo: 
Contrato Normal ou Orçamento Serviço Extra

@Return 	MenuDef
@author 	Fernando Alves Silva
@since 		07/08/2017
/*/
//------------------------------------------------------------------------------
Function At932CadGF(cAlias, nReg, nOpc)

Local nOperacao  := MODEL_OPERATION_UPDATE

Do Case 
	Case TFJ->TFJ_SRVEXT=='2' .And. !Empty(TFJ->TFJ_CONTRT)  
		lSrvExt	:= .F.
		lContra	:= .T. 		
	Case TFJ->TFJ_SRVEXT=='1' .And. Empty(TFJ->TFJ_CONTRT)
		lSrvExt	:= .T.
		lContra	:= .F. 		
EndCase

MsgRun( STR0007, STR0008, {|| FWExecView(STR0009,"VIEWDEF.TECA932",nOperacao,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/) } ) //"Processando Grupo de Faturamento" # "Aguarde..." # "Config. Grupo de Faturamento"

Return(Nil)

//------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef()
Model - Relacionamentos - Cadastro de Clientes por Serviços

@Return 	oModel
@author 	Fernando Alves
@since 		21/09/2016
/*/
//------------------------------------------------------------------------------
Static Function ModelDef()
Local oModel      := Nil
Local oStructTFJ  := FwFormStruct(1, "TFJ") //Cabeçalho do Contrato
Local oStructTWW  := FwFormStruct(1, "TWW") //Clientes por Serviço
Local cNomeCli	  := POSICIONE("SA1",1,xFilial("SA1") + TFJ->TFJ_CODENT + TFJ->TFJ_LOJA, "A1_NOME")
Local bPosVld	  := {|oModel| Vld932Lj(oModel)}

Do Case 
	Case TFJ->TFJ_SRVEXT=='2' .And. !Empty(TFJ->TFJ_CONTRT)  
		lSrvExt	:= .F.
		lContra	:= .T. 		
	Case TFJ->TFJ_SRVEXT=='1' .And. Empty(TFJ->TFJ_CONTRT)
		lSrvExt	:= .T.
		lContra	:= .F. 		
EndCase

oModel:= MpFormModel():New("TECA932", /*Pre Vld Mdl*/,bPosVld, /*Commit*/)
oModel:SetDescription(STR0010) //"Clientes por Serviço"

oStructTFJ:AddField(STR0011,;								// [01] C Titulo do campo # "Contrato"
					STR0011,;								// [02] C ToolTip do campo # "Contrato"
     				"TWW_XCONT",;							// [03] C identificador (ID) do Field
         			"C",;									// [04] C Tipo do campo
            		TamSX3("CN9_NUMERO")[1],;				// [05] N Tamanho do campo
              		0,;										// [06] N Decimal do campo
                	Nil,;									// [07] B Code-block de validação do campo
                 	Nil,;									// [08] B Code-block de validação When do campo
                  	Nil,;									// [09] A Lista de valores permitido do campo
                   	Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    {|| TFJ->TFJ_CONTRT},;					// [11] B Code-block de inicializacao do campo
                    Nil,;									// [12] L Indica se trata de um campo chave
                    Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    .T. )									// [14] L Indica se o campo é virtual  

oStructTFJ:AddField(STR0012,;								// [01] C Titulo do campo # "Revisão"
					STR0012,;								// [02] C ToolTip do campo # "Revisão"
     				"TWW_XREVIS",;							// [03] C identificador (ID) do Field
         			"C",;									// [04] C Tipo do campo
            		TamSX3("CN9_REVISA")[1],;				// [05] N Tamanho do campo
              		0,;										// [06] N Decimal do campo
                	Nil,;									// [07] B Code-block de validação do campo
                 	Nil,;									// [08] B Code-block de validação When do campo
                  	Nil,;									// [09] A Lista de valores permitido do campo
                   	Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    {|| TFJ->TFJ_CONREV},;					// [11] B Code-block de inicializacao do campo
                    Nil,;									// [12] L Indica se trata de um campo chave
                    Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    .T. )									// [14] L Indica se o campo é virtual  

oStructTFJ:AddField(STR0013,;								// [01] C Titulo do campo # "Nome"
					STR0013,;								// [02] C ToolTip do campo # "Nome"
     				"TWW_XNOMCL",;							// [03] C identificador (ID) do Field
         			"C",;									// [04] C Tipo do campo
            		TamSX3("A1_NOME")[1],;					// [05] N Tamanho do campo
              		0,;										// [06] N Decimal do campo
                	Nil,;									// [07] B Code-block de validação do campo
                 	Nil,;									// [08] B Code-block de validação When do campo
                  	Nil,;									// [09] A Lista de valores permitido do campo
                   	Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    {|| cNomeCli},;							// [11] B Code-block de inicializacao do campo
                    Nil,;									// [12] L Indica se trata de um campo chave
                    Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    .T. )									// [14] L Indica se o campo é virtual                      

oModel:AddFields('TFJMASTER', , oStructTFJ)
oModel:GetModel('TFJMASTER'):SetDescription("Cabeçalho do Contrato") //"Cabeçalho do Contrato" 
                    
oModel:AddGrid('TWWDETAIL','TFJMASTER',oStructTWW)
oModel:GetModel('TWWDETAIL'):SetDescription("Clientes por Serviço") //"Clientes por Serviço"

oModel:GetModel('TWWDETAIL'):SetUniqueLine({'TWW_LOCAL'})

If lContra
	oModel:SetRelation('TWWDETAIL', { { 'TWW_FILIAL', 'FWxFilial("TWW")' }, { 'TWW_NUMERO', 'TFJ_CONTRT' }, { 'TWW_REVISA', 'TFJ_CONREV' } }, TWW->(IndexKey(1)) )
Else
	oModel:SetRelation('TWWDETAIL', { { 'TWW_FILIAL', 'FWxFilial("TWW")' }, { 'TWW_NUMERO', 'TFJ_CODIGO' } }, TWW->(IndexKey(1)) )
EndIf

oStructTFJ:SetProperty("*", MODEL_FIELD_OBRIGAT, .F.)

oModel:SetPrimaryKey({})
oModel:SetVldActivate( {|oModel| AT932VldCt(oModel)} )

oModel:SetActivate( {|oModel| InitDados( oModel ) } )

oModel:GetModel('TWWDETAIL'):SetNoInsertLine( .T. ) 
oModel:GetModel('TWWDETAIL'):SetNoDeleteLine( .T. ) 

oModel:GetModel('TWWDETAIL'):SetOptional(.T.)

// [14] L Indica se o campo é virtual

Return oModel

//------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef()
View - Cadastro de Clientes por Serviço

@Return 	oView
@author 	Fernando Alves
@since 		21/09/2016
/*/
//------------------------------------------------------------------------------
Static Function ViewDef()
Local oView      := Nil
Local oModel     := ModelDef()
Local oStructTFJ := FWFormStruct(2, 'TFJ', { |cCampo| TFJSTRU(cCampo) })
Local oStructTWW := FWFormStruct(2, 'TWW', { |cCampo| TWWSTRU(cCampo) })

oView := FWFormView():New()
oView:SetModel(oModel)

oView:AddField('FORMTFJ' , oStructTFJ, 'TFJMASTER' )
oView:AddGrid('FORMTWW'  , oStructTWW, 'TWWDETAIL' )

If lSrvExt
	oStructTWW:SetProperty("TWW_CLIERH",MVC_VIEW_LOOKUP, "TWW001")
	oStructTWW:SetProperty("TWW_CLIEMI",MVC_VIEW_LOOKUP, "TWW001")
	oStructTWW:SetProperty("TWW_CLIEMC",MVC_VIEW_LOOKUP, "TWW001")
	oStructTWW:SetProperty("TWW_CLIELE",MVC_VIEW_LOOKUP, "TWW001")
	oStructTWW:SetProperty("TWW_CLIEHE",MVC_VIEW_LOOKUP, "TWW001")
	oStructTWW:SetProperty("TWW_CLIEAD",MVC_VIEW_LOOKUP, "TWW001")
Else
	oStructTWW:SetProperty("TWW_CLIERH",MVC_VIEW_LOOKUP, "TWW002")
	oStructTWW:SetProperty("TWW_CLIEMI",MVC_VIEW_LOOKUP, "TWW002")
	oStructTWW:SetProperty("TWW_CLIEMC",MVC_VIEW_LOOKUP, "TWW002")
	oStructTWW:SetProperty("TWW_CLIELE",MVC_VIEW_LOOKUP, "TWW002")
	oStructTWW:SetProperty("TWW_CLIEHE",MVC_VIEW_LOOKUP, "TWW002")
	oStructTWW:SetProperty("TWW_CLIEAD",MVC_VIEW_LOOKUP, "TWW002")	
EndIf

oStructTFJ:AddField( ;									// Ord. Tipo Desc.
						"TWW_XCONT",;					// [01] C Nome do Campo
						"03",;							// [02] C Ordem
						STR0011,;					// [03] C Titulo do campo # "Contrato"
						STR0011,;					// [04] C Descrição do campo # "Contrato"
						Nil,;							// [05] A Array com Help
						"C",;							// [06] C Tipo do campo
						"@!",;							// [07] C Picture
						NIL,;							// [08] B Bloco de Picture Var
						"" ,;							// [09] C Consulta F3
						.F.,;							// [10] L Indica se o campo é editável
						NIL,;							// [11] C Pasta do campo
						NIL,;							// [12] C Agrupamento do campo
						NIL,;							// [13] A Lista de valores permitido do campo (Combo)
						NIL,;							// [14] N Tamanho Maximo da maior opção do combo
						NIL,;							// [15] C Inicializador de Browse
						.T.,;							// [16] L Indica se o campo é virtual
						NIL )							// [17] C Picture Variável	
						
oStructTFJ:AddField( ;									// Ord. Tipo Desc.
						"TWW_XREVIS",;					// [01] C Nome do Campo
						"04",;							// [02] C Ordem
						STR0012,;						// [03] C Titulo do campo # "Revisão"
						STR0012,;						// [04] C Descrição do campo # "Revisão"
						Nil,;							// [05] A Array com Help
						"C",;							// [06] C Tipo do campo
						"@!",;							// [07] C Picture
						NIL,;							// [08] B Bloco de Picture Var
						"" ,;							// [09] C Consulta F3
						.F.,;							// [10] L Indica se o campo é editável
						NIL,;							// [11] C Pasta do campo
						NIL,;							// [12] C Agrupamento do campo
						NIL,;							// [13] A Lista de valores permitido do campo (Combo)
						NIL,;							// [14] N Tamanho Maximo da maior opção do combo
						NIL,;							// [15] C Inicializador de Browse
						.T.,;							// [16] L Indica se o campo é virtual
						NIL )							// [17] C Picture Variável							

oStructTFJ:AddField( ;									// Ord. Tipo Desc.
						"TWW_XNOMCL",;					// [01] C Nome do Campo
						"09",;							// [02] C Ordem
						STR0013,;						// [03] C Titulo do campo # "Nome"
						STR0013,;						// [04] C Descrição do campo # "Nome"
						Nil,;							// [05] A Array com Help
						"C",;							// [06] C Tipo do campo
						"@!",;							// [07] C Picture
						NIL,;							// [08] B Bloco de Picture Var
						"" ,;							// [09] C Consulta F3
						.F.,;							// [10] L Indica se o campo é editável
						NIL,;							// [11] C Pasta do campo
						NIL,;							// [12] C Agrupamento do campo
						NIL,;							// [13] A Lista de valores permitido do campo (Combo)
						NIL,;							// [14] N Tamanho Maximo da maior opção do combo
						NIL,;							// [15] C Inicializador de Browse	
						.T.,;							// [16] L Indica se o campo é virtual
						NIL )							// [17] C Picture Variável		
oView:CreateHorizontalBox( 'BOXFORMTFJ', 30)
oView:CreateHorizontalBox( 'BOXFORMTWW', 70)

oView:SetOwnerView('FORMTFJ','BOXFORMTFJ')
oView:SetOwnerView('FORMTWW','BOXFORMTWW')


Return oView
	
//------------------------------------------------------------------------------
/*/{Protheus.doc} InitDados()
		
Inicialização de Dados no Modelo

@Return 	lRet
@author 	Fernando Alves
@since 		21/09/2016
/*/
//------------------------------------------------------------------------------
Static Function InitDados(oMdlGer)

Local oMdlTWW   := oMdlGer:GetModel('TWWDETAIL')
Local nQtdLin   := oMdlTWW:Length() //Quantidade de Linhas
Local aCampoCli := {'TWW_CLIERH', 'TWW_CLIEMI', 'TWW_CLIEMC', 'TWW_CLIELE', 'TWW_CLIEHE', 'TWW_CLIEAD'} //Campos de Cliente
Local aCampoLoja:= {'TWW_LOJARH', 'TWW_LOJAMI', 'TWW_LOJAMC', 'TWW_LOJALE', 'TWW_LOJAHE', 'TWW_LOJAAD'} //Campos de Loja
Local nOper     := oMdlGer:GetOperation() //Tipo de Operação
Local cAliasQry := '' 
Local lNewCfg	:= .F.
	Local nCount	:= 0
Local nI		:= 0
Local aSaveRows := {}

	aSaveRows := FwSaveRows()

If (nQtdLin == 0 .Or. nQtdLin == 1) .And. Empty(oMdlTWW:GetValue('TWW_LOCAL'))
	lNewCfg := .T.
EndIf  

If lNewCfg .And. (nOper == MODEL_OPERATION_UPDATE)
	
			cAliasQry := GetNextAlias()
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
					TFL.TFL_CODPAI = %exp:TFJ->TFJ_CODIGO% AND
		TFL.TFL_CONTRT = %exp:TFJ->TFJ_CONTRT% AND
		TFL.TFL_CONREV = %exp:TFJ->TFJ_CONREV% AND
					TFL.%notDel%
			EndSQL

	aDebug := GetLastQuery()
	
	oMdlGer:GetModel("TFJMASTER"):SetValue('TFJ_GRPFAT', '1')
	
			While (!(cAliasQry)->(EOF()))

				If nCount > 0  
					oMdlTWW:AddLine(.T.)
				EndIf
				
				oMdlTWW:SetValue('TWW_LOCAL', (cAliasQry)->TFL_LOCAL)
		
					For nI := 1 To Len(aCampoCli)
						oMdlTWW:LoadValue(aCampoCli[nI], (cAliasQry)->ABS_CLIFAT) 
						oMdlTWW:SetValue(aCampoLoja[nI], (cAliasQry)->ABS_LJFAT)
					Next nI

				nCount++
				(cAliasQry)->(DbSkip())
			EndDo
	
	EndIf

	FwRestRows( aSaveRows )

Return(Nil)

//------------------------------------------------------------------------------
/*/{Protheus.doc} AT932VldCt()

Validação de Ativação do Modelo de Dados

@Return 	lRet
@author 	Fernando Alves
@since 		21/09/2016
/*/
//------------------------------------------------------------------------------
Static Function AT932VldCt(oModel)
Local aArea 	:= GetArea() 
Local lRet 		:= .T. 
Local nOper 	:= oModel:GetOperation() 

If (nOper == MODEL_OPERATION_VIEW)
	DbSelectArea("TWW")
	TWW->(DbSetOrder(1))
	If lContra
		If !(TWW->(dbSeek(xFilial("TWW")+TFJ->(TFJ_CONTRT+TFJ_CONREV))))
	        Help( "", 1, "AT932VISUAL", , i18n(	STR0014+CRLF+; //"Orçamento: #1[codorc]# vinculado ao Contrato: #2[codcont]# Revisão: #3[codrev]#."
	        									STR0015,; //"Não existe configuração de grupo de faturamento, operação não poderá ser efetuada."
	        									{ TFJ->TFJ_CODIGO,AllTrim(TFJ->TFJ_CONTRT),AllTrim(TFJ->TFJ_CONREV) }), 1, 0,,,,,,;  
	 						                  	{STR0016}) //"Realize a configuração do grupo de faturamento."
			lRet := .F.		
		Endif
	Else
		If !(TWW->(dbSeek(xFilial("TWW")+TFJ->TFJ_CODIGO)))
	        Help( "", 1, "AT932VISUAL", , i18n(	STR0017+CRLF+; //"Orçamento de serviço extra: #1[codorcext]#."
	        									STR0015,;//"Não existe configuração de grupo de faturamento, operação não poderá ser efetuada."
 	        									{ TFJ->TFJ_CODIGO }), 1, 0,,,,,,;  // 
	 						                  	{STR0016}) //"Realize a configuração do grupo de faturamento."
			lRet := .F.		
		Endif
	Endif
Elseif (nOper == MODEL_OPERATION_UPDATE)
		If lContra
		If (TFJ->TFJ_AGRUP == '1')
		        Help( "", 1, "AT932ERRAGR", , i18n( STR0018+CRLF+; //"Orçamento: #1[codorc]# vinculado ao Contrato: #2[codcont]# Revisão: #3[codrev]#."
		        									STR0019,; //"O orçamento está configurado para agrupar o faturamento, operação não poderá ser efetuada."
		        									{ TFJ->TFJ_CODIGO,AllTrim(TFJ->TFJ_CONTRT),AllTrim(TFJ->TFJ_CONREV) }), 1, 0,,,,,,;  
		 						                  	{""})	 
				lRet := .F.		
			Elseif (TFJ->TFJ_CONREV <> Posicione("CN9",7,xFilial("CN9")+TFJ->TFJ_CONTRT+"05","CN9_REVISA"))
		        Help( "", 1, "AT932ULTREV", , i18n(	STR0020+CRLF+; //"Orçamento: #1[codorc]# vinculado ao Contrato: #2[codcont]# Revisão: #3[codrev]#."
 		        									STR0021,; //"Não é a última revisão, operação não poderá ser efetuada."
		        									{ TFJ->TFJ_CODIGO,AllTrim(TFJ->TFJ_CONTRT),AllTrim(TFJ->TFJ_CONREV) }), 1, 0,,,,,,; 
		 						                  	{""})	 
			lRet := .F.		
			Elseif (CN9->CN9_SITUAC <> '05')
		        Help( "", 1, "AT932VIGENT", , i18n(	STR0020+CRLF+; //"Orçamento: #1[codorc]# vinculado ao Contrato: #2[codcont]# Revisão: #3[codrev]#."
		        									STR0022,; //"O contrato não está vigente, operação não poderá ser efetuada."
		        									{ TFJ->TFJ_CODIGO,AllTrim(TFJ->TFJ_CONTRT),AllTrim(TFJ->TFJ_CONREV) }), 1, 0,,,,,,;  
		 						                  	{""})	 
				lRet := .F.		
			Endif
		Else
			If (TFJ->TFJ_AGRUP == '1')
		        Help( "", 1, "AT932ERRAGR", , i18n(	STR0017+CRLF+; //"Orçamento de serviço extra: #1[codorcext]#."
		        									STR0019,; //"O orçamento está configurado para agrupar o faturamento, operação não poderá ser efetuada."
		        									{ TFJ->TFJ_CODIGO }), 1, 0,,,,,,;
		 						                  	{""})	 
				lRet := .F.		
			Endif
		Endif	
	Endif

RestArea(aArea) //Restaurando a Área
		
Return lRet
//------------------------------------------------------------------------------
/*/{Protheus.doc} TFJSTRU()

Determina os campos que serão exibidos na estrutura da Tabela TFJ

@Return 	lRet
@author 	Fernando Alves
@since 		21/09/2016
/*/
//------------------------------------------------------------------------------

Static Function TFJSTRU( cCampo )

	Local lRet := .F.
Local aCampos 	:= { 'TFJ_CODIGO' , 'TFJ_CODENT' , 'TFJ_LOJA' , 'TFJ_CONTRT' , 'TFJ_CONREV', 'TWW_XCONT' }
	
If (AScan(aCampos, {|x| AllTrim(x) == AllTrim(cCampo)}) > 0)
		lRet := .T.
	EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} TWWSTRU()

Determina os campos que serão exibidos na estrutura da Tabela TWW

@Return 	lRet
@author 	Fernando Alves
@since 		21/09/2016
/*/
//------------------------------------------------------------------------------
Static Function TWWSTRU( cCampo )
Local lRet := .T.

If (AllTrim(cCampo) == 'TWW_NUMERO' .OR. AllTrim(cCampo) == 'TWW_REVISA')
	lRet := .F.
EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At932CliGF
[GRUPO FAT] - Função Responsável por retornar o Cliente x Tipo de Serviço
@sample	 	At932CliGF()
@return		aRet - [1] Cod. Cliente | [2] Loja Cliente
@since		22/09/2017
@author		Fernando Alves Silva
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At932CliGF(cTipo,cContrato,cRevisao,cCodTFL)

Local cAliasQry := GetNextAlias()
Local aQryDbg	:= {}
Local aRet 		:= {}
 
BeginSQL Alias cAliasQry
	SELECT
		TWW.TWW_LOCAL, TWW.TWW_CLIERH, TWW.TWW_LOJARH, TWW.TWW_CLIEMI, TWW.TWW_LOJAMI,
		TWW.TWW_CLIEMC, TWW.TWW_LOJAMC, TWW.TWW_CLIELE, TWW.TWW_LOJALE,
		TWW.TWW_CLIEHE, TWW.TWW_LOJAHE, TWW.TWW_CLIEAD, TWW.TWW_LOJAAD,
		TFL.TFL_LOCAL, ABS1.ABS_CLIFAT, ABS1.ABS_LJFAT
	FROM
		%Table:TFL% TFL
	INNER JOIN %Table:TWW% TWW ON
		TWW.TWW_FILIAL = TFL.TFL_FILIAL AND
		TWW.TWW_NUMERO = TFL.TFL_CONTRT AND
		TWW.TWW_REVISA = TFL.TFL_CONREV AND
		TWW.TWW_LOCAL = TFL.TFL_LOCAL AND
		TWW.%NotDel%
	INNER JOIN %Table:ABS% ABS1 ON
		ABS1.ABS_FILIAL = %xFilial:ABS% AND
		ABS1.ABS_LOCAL = TFL.TFL_LOCAL AND
		ABS1.%NotDel%
	WHERE
		TFL.TFL_FILIAL = %xFilial:TFL% 		AND
		TFL.TFL_CODIGO = %Exp:cCodTFL% 		AND
		TFL.TFL_CONTRT = %Exp:cContrato%	AND	
		TFL.TFL_CONREV = %Exp:cRevisao%		AND
		TFL.%NotDel%
EndSQL

aQryDbg := GetLastQuery()

If !((cAliasQry)->(EOF()))

	Do Case
		Case cTipo == 'RH'
			aAdd(aRet, (cAliasQry)->TWW_CLIERH)
			aAdd(aRet, (cAliasQry)->TWW_LOJARH)
		Case cTipo == 'MI'
			aAdd(aRet, (cAliasQry)->TWW_CLIEMI)
			aAdd(aRet, (cAliasQry)->TWW_LOJAMI)
		Case cTipo == 'MC'
			aAdd(aRet, (cAliasQry)->TWW_CLIEMC)
			aAdd(aRet, (cAliasQry)->TWW_LOJAMC)
		Case cTipo == 'LE'
			aAdd(aRet, (cAliasQry)->TWW_CLIELE)
			aAdd(aRet, (cAliasQry)->TWW_LOJALE)		
		Case cTipo == 'HE'
			aAdd(aRet, (cAliasQry)->TWW_CLIEHE)
			aAdd(aRet, (cAliasQry)->TWW_LOJAHE)		
		Case cTipo == 'AD'
			aAdd(aRet, (cAliasQry)->TWW_CLIEAD)
			aAdd(aRet, (cAliasQry)->TWW_LOJAAD)					
	EndCase

EndIf

Return aRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At932VldCl
Função Responsável por validar o cliente e loja. 
@sample	 	At932VldCl()
@return		lRet
@since		09/11/2017
@author		Kaique Schiller
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At932VldCl(cCodCli)
Local lRet 		:= .F.
Local cAliasQry	:= ""
Local cQry		:= ""

If lSrvExt

	cAliasQry	:= GetNextAlias()
	cQry 		:= At932QrySr(FwFldGet("TFJ_CODIGO"))
	cQry 		:= ChangeQuery(cQry)

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAliasQry,.T.,.T.)

	While !(cAliasQry)->(EOF())
		If cCodCli == (cAliasQry)->TFJ_CODENT
	lRet := .T.
			Exit
		Endif
		(cAliasQry)->(DbSkip())
	EndDo

	If !lRet
	    Help( "", 1, "AT932VISUAL", , i18n(	STR0024,; //"O cliente: #1[codorc]# não faz parte do orçamento de serviço extra."
	    									{ cCodCli }), 1, 0,,,,,,;  
						                  	{STR0025}) //"Informe um cliente que esteja envolvido no orçamento de serviço extra." 
	Endif

	(cAliasQry)->(DbCloseArea())
Else
	lRet := ExistCpo("CNC", FwFldGet("TFJ_CONTRT") + FwFldGet("TFJ_CONREV") + cCodCli, 3) 
Endif

Return lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At932TW001
Consulta especifica para o orçamento de serviço extra - TWW001.
@sample	 	At932TW001()
@return		lRet
@since		09/11/2017
@author		Kaique Schiller
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At932TW001()

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
Local aSeek 		:= {{ STR0026, {{STR0026,"C",TamSx3('A1_COD')[1],0,"",,}} }} //"Cliente" ## "Cliente"
Local aRet 			:= {"",""}
Local oModel		:= FwModelActive()
Local oView			:= FwViewActive()
Local oGridDtl		:= oModel:GetModel('TWWDETAIL')
Local cCmpCli		:= ReadVar()
Local cCmpLoj		:= ""

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

cQry := At932QrySr(FwFldGet("TFJ_CODIGO"))

DEFINE MSDIALOG oDlgTela TITLE STR0027 FROM nSuperior,nEsquerda TO nInferior,nDireita PIXEL //"Cli. Fat. Contrato"
 
oBrowse := FWFormBrowse():New()
oBrowse:SetOwner(oDlgTela)
oBrowse:SetDataQuery(.T.)
oBrowse:SetAlias(cAls)
oBrowse:SetQueryIndex(aIndex)
oBrowse:SetQuery(cQry)
oBrowse:SetSeek(,aSeek)
oBrowse:SetDescription(STR0027) //"Cli. Fat. Contrato"

oBrowse:SetDoubleClick({ || aRet[1] := (oBrowse:Alias())->TFJ_CODENT, aRet[2] := (oBrowse:Alias())->TFJ_LOJA, lRet := .T., oDlgTela:End()}) //"Confirmar"
oBrowse:AddButton( OemTOAnsi(STR0028), {|| aRet[1] := (oBrowse:Alias())->TFJ_CODENT, aRet[2] := (oBrowse:Alias())->TFJ_LOJA,  lRet := .T., oDlgTela:End()},, 2 ) //"Cancelar"
oBrowse:AddButton( OemTOAnsi(STR0029),  {|| aRet[1] := "" , aRet[2] := "", oDlgTela:End()} ,, 2 ) //"Cancelar" 
oBrowse:DisableDetails()

ADD COLUMN oColumn DATA { ||  TFJ_CODENT  } TITLE STR0030	SIZE TamSx3('TFJ_CODENT')[1] OF oBrowse //"Código"
ADD COLUMN oColumn DATA { ||  TFJ_LOJA    } TITLE STR0031	SIZE TamSx3('TFJ_LOJA')[1] 	 OF oBrowse //"Loja"
ADD COLUMN oColumn DATA { ||  A1_NOME     } TITLE STR0032 	SIZE TamSx3('A1_NOME')[1]  	 OF oBrowse //"Nome"

oBrowse:Activate()

ACTIVATE MSDIALOG oDlgTela CENTERED

If lRet .And. !Empty(aRet)		
	lRet := oGridDtl:SetValue(cCmpCli,aRet[1]) .And. oGridDtl:SetValue(cCmpLoj,aRet[2])
	If lRet
		aRetTFJ := aRet
	Endif
Endif

If oView:IsActive()
	oView:Refresh("FORMTWW")
Endif

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At932RetTW
Retorno da consulta especifica para o orçamento de serviço extra - TWW001.
@sample	 	At932RetTW()
@return		lRet
@since		09/11/2017
@author		Kaique Schiller
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At932RetTW()

Return aRetTFJ[1]

//------------------------------------------------------------------------------
/*/{Protheus.doc} At932QrySr
função com a query do dos clientes do serviço extra.
@sample	 	At932QrySr()
@return		lRet
@since		09/11/2017
@author		Kaique Schiller
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At932QrySr(cCodTFJ)
Local cQry := ""

cQry := " SELECT TFJ_CODENT, TFJ_LOJA, A1_NOME "
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
/*/{Protheus.doc} Gt932CodLj
Função para gatilhar a loja do cliente digitado manualmente.
@sample	 	Gt932CodLj()
@return		lRet
@since		27/11/2017
@author		Leandro Fini
@version	P12   
/*/
//------------------------------------------------------------------------------

Function Gt932CodLj(cCampo)

Local cQuery := ""
Local cAliasCodLJ := GetNextAlias()
Local cRet	:= ""
Local cCliTWW := ""
Local cContrt	:= FwFldGet("TWW_NUMERO")
Local cRevisa	:= FwFldGet("TWW_REVISA")

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

If lSrvExt == .T. .AND. lContra == .F. //Serviço extra

	cQuery := At932QrySr(FwFldGet("TFJ_CODIGO"))
	cQuery := ChangeQuery(cQuery)
	dbUseArea( .T., "TOPCONN", TcGenQry( ,, cQuery ) , cAliasCodLJ, .F., .T. )
	
	//Busca a loja do cliente digitado
	While (cAliasCodLJ)->(!EoF())
		If (cAliasCodLJ)->TFJ_CODENT == cCliTWW 
			cRet := (cAliasCodLJ)->TFJ_LOJA
		Endif
		(cAliasCodLJ)->(DbSkip())
	EndDo

ElseIf lContra == .T. .AND. lSrvExt == .F. //Contrato
	
	//Busca a loja do cliente digitado
	DbSelectArea("CNC")
	CNC->(DbSetOrder(3)) //CNC_FILIAL+CNC_NUMERO+CNC_REVISA+CNC_CLIENT
	If CNC->(dbSeek(xFilial("CNC")+cContrt+cRevisa+cCliTWW))
		cRet := CNC->CNC_LOJACL	
	Endif

Endif

Return cRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} Vld932Lj
Função para validar o cliente e loja inseridos manualmente.
@sample	 	Vld932Lj()
@return		lRet
@since		27/11/2017
@author		Leandro Fini
@version	P12   
/*/
//------------------------------------------------------------------------------

Static Function Vld932Lj(oModel)
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
Local cContrt	:= oModelTWW:GetValue('TWW_NUMERO')
Local cRevisa	:= oModelTWW:GetValue('TWW_REVISA')

//Armazena os clientes digitados no browser no aDadosTWW
For nY := 1 To oModelTWW:Length()
	oModelTWW:GoLine(nY)
	If !oModelTWW:IsDeleted() 

		aAdd(aDadosTWW, oModelTWW:GetValue("TWW_CLIERH") + oModelTWW:GetValue("TWW_LOJARH") )

		nPos:= aScan(aDadosTWW, { |x| x == oModelTWW:GetValue("TWW_CLIEMI") + oModelTWW:GetValue("TWW_LOJAMI") } ) 
		If nPos == 0 
			aAdd(aDadosTWW, oModelTWW:GetValue("TWW_CLIEMI") + oModelTWW:GetValue("TWW_LOJAMI") )
		EndIf
		
		nPos:= aScan(aDadosTWW, { |x| x == oModelTWW:GetValue("TWW_CLIEMC") + oModelTWW:GetValue("TWW_LOJAMC") } ) 
		If nPos == 0 		
			aAdd(aDadosTWW, oModelTWW:GetValue("TWW_CLIEMC") + oModelTWW:GetValue("TWW_LOJAMC") )
		EndIf
		
		nPos:= aScan(aDadosTWW, { |x| x == oModelTWW:GetValue("TWW_CLIELE") + oModelTWW:GetValue("TWW_LOJALE") } ) 
		If nPos == 0 		
			aAdd(aDadosTWW, oModelTWW:GetValue("TWW_CLIELE") + oModelTWW:GetValue("TWW_LOJALE") )
		EndIf

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

If lSrvExt == .T. .AND. lContra == .F. //Serviço extra
	
		//Query para buscar os locais vinculados ao serviço.
		cQuery := At932QrySr(FwFldGet("TFJ_CODIGO"))
		cQuery := ChangeQuery(cQuery)
		dbUseArea( .T., "TOPCONN", TcGenQry( ,, cQuery ) , cAliasTWW, .F., .T. )
		
		//Armazena o resultado da query no aCliLj
		While (cAliasTWW)->(!EoF())
			aAdd(aCliLj, (cAliasTWW)->TFJ_CODENT + (cAliasTWW)->TFJ_LOJA )
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
				If nX == 1
					cHelpVld := " [" + Substr(aDadosVld[nX],0,8) + "/" + Substr(aDadosVld[nX],9,4) + "] "
				Else
					cHelpVld += " [" + Substr(aDadosVld[nX],0,8) + "/" + Substr(aDadosVld[nX],9,4) + "] "
				Endif
			Next nX			
	      Help(" ",1,"HELP", , STR0033 + cHelpVld + STR0034 , 3, 1 ) //"O(s) cliente(s) "#"não estão vinculados ao serviço."
		Endif
	
ElseIf lContra == .T. .AND. lSrvExt == .F. //Contrato

	For nY := 1 to Len(aDadosTWW)
		//Busca a loja do cliente digitado
		DbSelectArea("CNC")
		CNC->(DbSetOrder(3)) //CNC_FILIAL+CNC_NUMERO+CNC_REVISA+CNC_CLIENT
		If CNC->(!dbSeek(xFilial("CNC") + cContrt + cRevisa + aDadosTWW[nY]))
			If nY == 1
				cHelpVld := " [" + Substr(aDadosTWW[nY],0,8) + "/" + Substr(aDadosTWW[nY],9,4) + "] "
				lRet := .F.
			Else
				cHelpVld += " [" + Substr(aDadosTWW[nY],0,8) + "/" + Substr(aDadosTWW[nY],9,4) + "] "
			Endif
		Endif
	Next nY

	Help(" ",1,"HELP", , STR0033 + cHelpVld + STR0034 , 3, 1 ) //"O(s) cliente(s) "#"não estão vinculados ao contrato."

Endif

Return lRet