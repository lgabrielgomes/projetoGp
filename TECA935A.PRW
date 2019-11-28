#INCLUDE 'PROTHEUS.CH' 
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE "XMLXFUN.CH"
#INCLUDE 'PARMTYPE.CH'
#INCLUDE "TECA935.CH"

STATIC aPrcOrc	:= {}	
STATIC oFWSheet	:= FWUIWorkSheet():New(,.F. )
STATIC oView		:= Nil
STATIC oModel		:= Nil
STATIC cXML		:= ""

#DEFINE _TV7TITULO	1
#DEFINE _TV7IDENT		2
#DEFINE _TV7MODO 		3
#DEFINE _TV7TAM 		4
#DEFINE _TV7DEC 		5
#DEFINE _TV7VALID 	6
#DEFINE _TV7EDICAO 	7
#DEFINE _TV7INIT 		8
#DEFINE _TV7FORM 		9
#DEFINE _TV7ORDEM 	10
#DEFINE _TV7DESC 		11
#DEFINE _TV7ABA		12

#DEFINE _fwTFF		1	// Chave dos Recursos Contidos no Local de Atendimento
#DEFINE _fwOBJ		2	// Objerto FWSheet - Para precificação de Recursos e Impostos
#DEFINE _fwDEL		3	// Linha Marcada para Deleção

//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
	Definição do modelo de Dados
@since		06/04/2017
@author 	Serviços    
@version	P12.1.17  
/*/
//-------------------------------------------------------------------
Static Function ModelDef()
Local oStructFke	:= FWFormModelStruct():New()
Local nI			:= 0

oStructFke:AddTable("ZYY",{},STR0059) //"Cabeçalho do cálculo"

oStructFke:AddField(STR0060,;		// cTitle	//"Titulo"
                    STR0060,;		// cToolTip	//"Titulo"
                    "ZYY_FAKE",;	// cIdField
                    "C",;			// cTipo
                    1,;				// nTamanho
                    0,;				// nDecimal
                    NIL,;			// bValid
                    NIL,;			// bWhen
                    NIL,;			// aValues
                    .F.,;			// lObrigat
                    NIL,;			// bInit
                    .F.,;			// lKey
                    Nil,;			// lNoUpd
                    .T.)				// lVirtual

// Carrega as informaões para a montagem das estruturas
aPrcOrc := At740FPrc( TV6->TV6_NUMERO, TV6->TV6_REVISA )

// Montagem das estruturas para o model
At740FStru( @aPrcOrc, .T.,.T. )

//Instancia o cadastro de Regime de Caixa
oModel := MPFormModel():New('TECA935A',/*bPreValidacao*/,/*bPosVld*/,/*bCommit*/,/*bCancel*/)

//Instancia o cabeçalho
oModel:AddFields('FAKMASTER',/*cOwner*/,oStructFke,/*bPreValidacao*/,/*bPosValidacao*/,{|| {} },/*bFieldAbp*/)

//Criação dos fields dinamicos para o RH
For nI:=1 To Len(aPrcOrc)
	If Empty(AllTrim(aPrcOrc[nI][1]))
		Loop
	EndIf
	// Indica o nome do model a ser criado
	cModel  := aPrcOrc[nI][3][2]	
	// Assume a nova estrutura do model3
	&("oStrR" + StrZero(nI,3)) := aPrcOrc[nI][3][1]	
	oModel:AddFields( cModel, "FAKMASTER", &("oStrR" + StrZero(nI,3)),,/*bPost*/,{||})
	oModel:GetModel(cModel):SetDescription(cModel)  	
Next nI

oModel:SetPrimaryKey( {} )

oModel:GetModel('FAKMASTER'):SetOnlyQuery(.T.)

oModel:SetActivate( {|oModel| InitDados( oModel ) } )

Return(oModel)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef

Definição da View

@since		06/04/2017
@author 	Serviços    
@version	P12.1.17  

@return ExpO:oView
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ViewDef()
Local oModel   		:= FWLoadModel('TECA935A')
Local oStructFke  	:= FWFormViewStruct():New() //Cabeçalho
Local nI			:= 0

//Adiciona o campo para o model fake
oStructFke:AddField("ZYY_FAKE","01",STR0060,STR0060,{STR0060},"C","X",Nil,Nil,.F.,Nil)	//"Titulo"

// Carrega as informaões para a montagens das estruturas
If Len(aPrcOrc) == 0	
	aPrcOrc := At740FPrc( TV6->TV6_NUMERO, TV6->TV6_REVISA )
EndIf
At740FStru( @aPrcOrc, .F. )

oView:= FWFormView():New()
oView:SetModel(oModel)

//Define a dimensão da tela
oView:CreateHorizontalBox('view_hide', 0)
oView:CreateHorizontalBox('ID_RH', 100)

oView:AddField('FIELD_HIDE', oStructFke, 'FAKMASTER' )

oView:SetOwnerView('FIELD_HIDE','view_hide')

// Criação dos fields dinamicos para o RH
For nI:=1 To Len(aPrcOrc)
	If Empty(AllTrim(aPrcOrc[nI][1]))
		Loop
	EndIf
	cView := aPrcOrc[nI][4][2]	// Indica o nome da view a ser criada	
	// Assume a nova estrutura da view
	&("oStrR" + StrZero(nI,3)) := aPrcOrc[nI][4][1]
	oView:AddField( cView, &("oStrR" + StrZero(nI,3)), aPrcOrc[nI][3][2] ) 	
Next nI

// Criação das abas para Recursos Humanos
oView:CreateFolder( "RH_ABAS", "ID_RH")

// Criação das abas e areas dinamicas para o RH
For nI:=1 To Len(aPrcOrc)
	If Empty(AllTrim(aPrcOrc[nI][1]))
		Loop
	EndIf
	cAbaRH  := "RH_ABAD" + StrZero(nI,3)
	cAreaRH := "ID_RH_D" + StrZero(nI,3)
	oView:AddSheet( "RH_ABAS", cAbaRH, AllTrim(aPrcOrc[nI][1]) ) 		// Define as abas dinamicas
	oView:CreateHorizontalBox( cAreaRH, 100,,, "RH_ABAS", cAbaRH ) 	// Define a área das abas dinamicas
	oView:SetOwnerView( aPrcOrc[nI][4][2], cAreaRH ) 					// Informa a area a ser colocado o fields	
Next nI

oView:setUpdateMessage(STR0053,STR0054) //"Sucesso"##"Calculo realizado com sucesso!"
oView:SetCloseOnOk({|| .T.} )

Return(oView)

//------------------------------------------------------------------------------
/*/{Protheus.doc} InitDados

Inicializa os dados para o modelo

@since		06/04/2017
@author 	Serviços    
@version	P12.1.17  

@param  	oMdlGer, Objeto, objeto geral do model que será alterado

/*/
//------------------------------------------------------------------------------
Static Function InitDados( oMdlGer )
Local nI		:= 0
Local nJ		:= 0
Local aSaveRows	:= {}
Local uValor 	:= Nil
Local cIDCampo	:= ''

//Verifica se já tem XML carregado
cXML := Get935XML()

If Empty(cXML)
	cXml := At740ELTP( TV6->TV6_NUMERO, TV6->TV6_REVISA )
EndIf

If Valtype(oFWSheet) <> 'O'
	oFWSheet := FWUIWorkSheet():New(,.F. )	
EndIf 

oFWSheet:LoadXmlModel(cXml)

If !Empty(oMdlGer)
	// Savar Ponteiros
	aSaveRows	:= FwSaveRows()
	For nI := 1 To Len(aPrcOrc)

		If Empty(AllTrim(aPrcOrc[nI][1]))
			Loop
		EndIf
					
		For nJ	:= 1 To Len(aPrcOrc[nI][2])
			
			cIDCampo := AllTrim(aPrcOrc[nI][2][nJ][_TV7IDENT])
							
			nPosNick := AScan(OFWSHEET:OFWFORMULA:CELLS,{|o| o:NICKNAME == cIDCampo})
							
			If nPosNick > 0
							
				cPicture := OFWSHEET:OFWFORMULA:CELLS[nPosNick]:CPICTURE
					
				If aPrcOrc[nI][2][nJ][_TV7MODO] == '1'	// 1-Valor ; 2-Combo
					uValor := oFWSheet:GetCellValue(cIDCampo)
					uValor := If( ValType(uValor) == 'C', Val(uValor), uValor )
				Else
					uValor := Transform(oFWSheet:GetCellValue(cIDCampo), cPicture)
				EndIf
								
				If oMdlGer:GetOperation() <> MODEL_OPERATION_DELETE
					If cIDCampo == 'TOT_VIMP' .And. oMdlGer:GetOperation() <> MODEL_OPERATION_VIEW
						oMdlGer:GetModel(aPrcOrc[nI][3][2]):SetValue(cIDCampo,uValor)
					Else
						oMdlGer:GetModel(aPrcOrc[nI][3][2]):LoadValue(cIDCampo,uValor)
					EndIf
				EndIf
			EndIf
							
		Next nJ	// Campos Dinâmicos
					
	Next nI	// Abas
EndIf

// Restaura Ponteiros
FwRestRows( aSaveRows )

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} a935ACalc

Função para realizar o calculo da tabela de precificação

@since		06/04/2017
@author 	Serviços    
@version	P12.1.17  
/*/
//--------------------------------------------------------------------------------------------------------------------
Function a935ACalc(aValor)

Processa( {|| (a935ACalcRH(aValor)) }, STR0055, STR0056,.F.) //"Aguarde..."##"Executando cálculo"

Return .T.

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} a935ACalcRH

Função para atribiur os valores no XML

@since		06/04/2017
@author 	Serviços    
@version	P12.1.17  

/*/
//--------------------------------------------------------------------------------------------------------------------
Function a935ACalcRH(aValor)
Local oModel 		:= FwModelActive()
Local aSaveRows 	:= FwSaveRows()
Local nI			:= 0
Local nJ			:= 0

// Pega o valor dos campos de todas em Abas do Modelo
For nI := 1 To Len(aPrcOrc)
	IncProc()
		
	// O objeto Model da Aba correspondente
	oDataSrc := oModel:GetModel(aPrcOrc[nI][3][2])
		// identifica a aba de imposto para executar depois
	If !Empty( AllTrim( aPrcOrc[nI][1] ) )
			// Atribui o valor de cada campo da aba atual ao objeto de calculo
		For nJ := 1 To Len(aPrcOrc[nI][2])
			IncProc()
			At935eProc( aPrcOrc, nI, nJ, oFWSheet, oModel, oDataSrc, /*aCampos*/,@aValor )
		Next
	EndIf
Next

TecDestroy(oFWSheet)

FwRestRows( aSaveRows )	

Return .T.

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At935eProc

Função para processar os valores nas celulas do xml

@since		06/04/2017
@author 	Serviços    
@version	P12.1.17  

/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At935eProc( aPrcTab, nI, nJ, oFWSheet, oMdlPrc, oDataSrc, aCampos,aValor ) 
Local cCampo 	:= ""
Local nVal 		:= 0
Local lContinua := .T.

cCampo := AllTrim(aPrcTab[nI][2][nJ][2])
// Filtro para trabalhar Campos especificos
If !Empty(aCampos) .and. (AScan(aCampos,{|e| AllTrim(e) == cCampo}) == 0)
	lContinua := .F.
EndIf 

If lContinua
	// Se for um campo com fórmula o seu valor será calculado, portanto, não informar valor algum. 
	If !Empty(aPrcTab[nI][2][nJ][9]) 
		
		If At( 'U_', aPrcTab[nI][2][nJ][9] ) > 0
			// quando a fórmula possuir função de usuário realiza a reatribuição na planilha
			oFWSheet:SetCellValue(cCampo, aPrcTab[nI][2][nJ][9])
		EndIf
	// caso tenha inicializador e seja com id
	ElseIf !Empty(aPrcTab[nI][2][nJ][8]) .And. ;
		AtIsCalcId( Alltrim( aPrcTab[nI][2][nJ][8] ) )
		// busca o valor conforme o id de somatória 
		nVal := AtCalcIdent( Alltrim( aPrcTab[nI][2][nJ][8] ), oMdlPrc )
		oFWSheet:SetCellValue(cCampo, nVal)
		// atualiza a interface/modelo exibido
		oDataSrc:LoadValue(cCampo, nVal)
	Else
		// Deixa a atribuição somente em caso de alteração pela estrutura interna do framework
		oFWSheet:SetCellValue(cCampo, oDataSrc:GetValue(cCampo))
	EndIf

EndIf

If cCampo == "TOTAL_RH"
	//Armazena o XML para gravação na tabela T47
	AAdd(aValor, oFWSheet:GetXMLModel(,,,,.F.,.T.,.F.))
	AAdd(aValor, oFWSheet:GetCellValue('TOTAL_RH'))
EndIf

Return .T.