#INCLUDE "PROTHEUS.CH" 
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TECA160.CH" 

STATIC cF3CC := ""

//------------------------------------------------------------------------------
/*/{Protheus.doc} TECA160

Cadastro de Local de Atendimento

@sample 	TECA160() 

@param		Nenhum
	
@return	ExpL	Verdadeiro / Falso

@since		16/01/2012       
@version	P11   
/*/
//------------------------------------------------------------------------------
Function TECA160()

Local oMBrowse
Local oTableAtt       := Nil

PRIVATE cCadastro := '' // Variavel private utilizado na consulta padrão

oTableAtt := TableAttDef() //Retorna o widget com a visao e o grafico do browse

oMBrowse:= FWmBrowse():New() 
oMBrowse:SetAlias("ABS")
oMBrowse:SetDescription(STR0001)       							// "Local de Atendimento"
oMBrowse:SetAttach(.T.)
oMBrowse:SetOpenChart(.F.)
oMBrowse:SetViewsDefault(oTableAtt:aViews)
oMBrowse:SetChartsDefault(oTableAtt:aCharts)

oMBrowse:Activate()
	
Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef

Define o menu funcional. 

@sample 	MenuDef() 

@param		Nenhum
	
@return	ExpA Opções da Rotina.

@since		16/01/2012       
@version	P11   
/*/
//------------------------------------------------------------------------------

Static Function MenuDef()    

Local aRotina := {}

ADD OPTION aRotina TITLE STR0004 ACTION "VIEWDEF.TECA160" OPERATION 2 ACCESS 0 	// "Visualizar"
ADD OPTION aRotina TITLE STR0005 ACTION "VIEWDEF.TECA160" OPERATION 3 ACCESS 0 	// "Incluir"
ADD OPTION aRotina TITLE STR0006 ACTION "VIEWDEF.TECA160" OPERATION 4 ACCESS 0		// "Alterar"
ADD OPTION aRotina TITLE STR0007 ACTION "VIEWDEF.TECA160" OPERATION 5 ACCESS 0		// "Excluir"
aAdd(aRotina,{STR0002,"At160Estru",0 ,4}) //"Estrutura"
aAdd(aRotina,{STR0043, "AT352AABS()", 0 ,0,0, NIL}) //"Vinculo de Beneficios" 
	
Return( aRotina )


//------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef

Definição do Model

@sample 	ModelDef() 

@param		Nenhum
	
@return	ExpO Objeto FwFormModel 

@since		16/01/2012       
@version	P11   
/*/
//------------------------------------------------------------------------------

Static Function ModelDef()

Local oStruABS	:= FWFormStruct( 1, "ABS" )				// Estrutura ABS.
Local oStruTFF	:= FWFormStruct( 1, "TFF" )
Local oStruTFG	:= FWFormStruct( 1, "TFG" )
Local oStruTFH	:= FWFormStruct( 1, "TFH" )
Local oStruTFI	:= FWFormStruct( 1, "TFI" )
Local oStruABP	:= FWFormStruct( 1, "ABP" )
Local oStruTFU 	:= FWFormStruct( 1, "TFU" )
Local oStruTEV 	:= FWFormStruct( 1, "TEV" )
Local oModel		:= Nil 									// Modelo de dados construído.
Local bPosValid	:= {|oModel| At160VdFil(oModel) }		// Pos validação.
Local aAux			:= {}										// Array auxiliar para o gatilho.
Local bInitVazio := FwBuildFeature( STRUCT_FEATURE_INIPAD, "" )

oStruTFF:SetProperty("*", MODEL_FIELD_OBRIGAT, .F.)
oStruTFF:SetProperty("*", MODEL_FIELD_INIT, bInitVazio )

oStruTFU:SetProperty("*", MODEL_FIELD_OBRIGAT, .F.)
oStruTFU:SetProperty("*", MODEL_FIELD_INIT, bInitVazio )

oStruTFG:SetProperty("*", MODEL_FIELD_OBRIGAT, .F.)
oStruTFG:SetProperty("*", MODEL_FIELD_INIT, bInitVazio )

oStruTFH:SetProperty("*", MODEL_FIELD_OBRIGAT, .F.)
oStruTFH:SetProperty("*", MODEL_FIELD_INIT, bInitVazio )

oStruTFH:SetProperty("*", MODEL_FIELD_OBRIGAT, .F.)
oStruTFH:SetProperty("*", MODEL_FIELD_INIT, bInitVazio )

oStruTFI:SetProperty("*", MODEL_FIELD_OBRIGAT, .F.)
oStruTFI:SetProperty("*", MODEL_FIELD_INIT, bInitVazio )

oStruTEV:SetProperty("*", MODEL_FIELD_OBRIGAT, .F.)
oStruTEV:SetProperty("*", MODEL_FIELD_INIT, bInitVazio )

// Situacao do contrato para os recursos humanos
oStruTFF:AddField(	STR0018																			,;  	// [01] C Titulo do campo 	# Situacao
						STR0018 																			,;   	// [02] C ToolTip do campo	# Situacao
     					"TFF_SITUAC"																		,;    	// [03] C identificador (ID) do Field
         				"C" 																				,;    	// [04] C Tipo do campo
            			2 																					,;    	// [05] N Tamanho do campo
              		0 																					,;    	// [06] N Decimal do campo
                		Nil 																				,;    	// [07] B Code-block de validação do campo
                 		Nil																					,;     // [08] B Code-block de validação When do campo
                  	Nil 																				,;    	// [09] A Lista de valores permitido do campo
                   	Nil 																				,;  	// [10] L Indica se o campo tem preenchimento obrigatório
                    	{|| POSICIONE("CN9", 1, xFilial("CN9")+TFF->TFF_CONTRT+TFF->TFF_CONREV, "CN9_SITUAC" ) }	,;   	// [11] B Code-block de inicializacao do campo
                    	Nil 																				,;  	// [12] L Indica se trata de um campo chave
                    	Nil 																				,;     // [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.F. )            																			// [14] L Indica se o campo é virtual                  	

// Situacao do contrato para locacao de recursos
oStruTFI:AddField(	STR0018																			,;  	// [01] C Titulo do campo	# Situacao
						STR0018																			,;   	// [02] C ToolTip do campo	# Situacao
     					"TFI_SITUAC"																		,;    	// [03] C identificador (ID) do Field
         				"C" 																				,;    	// [04] C Tipo do campo
            			2 																					,;    	// [05] N Tamanho do campo
              		0 																					,;    	// [06] N Decimal do campo
                		Nil 																				,;    	// [07] B Code-block de validação do campo
                 		Nil																					,;     // [08] B Code-block de validação When do campo
                  	Nil 																				,;    	// [09] A Lista de valores permitido do campo
                   	Nil 																				,;  	// [10] L Indica se o campo tem preenchimento obrigatório
                    	{|| POSICIONE("CN9", 1, xFilial("CN9")+TFI->TFI_CONTRT+TFI->TFI_CONREV, "CN9_SITUAC" ) }	,;   	// [11] B Code-block de inicializacao do campo
                    	Nil 																				,;  	// [12] L Indica se trata de um campo chave
                    	Nil 																				,;     // [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.F. )           																			// [14] L Indica se o campo é virtual
                    	
// Legendas dos grids
oStruTFF:AddField( 	STR0019 	,;  	// [01] C Titulo do campo # Status
						STR0019	,;   	// [02] C ToolTip do campo	# Status
						"TFF_SIT"	,;   	// [03] C identificador (ID) do Field
						"BT"		,;   	// [04] C Tipo do campo
						1			,;   	// [05] N Tamanho do campo
						0			,;   	// [06] N Decimal do campo
						nil	 		,;   	// [07] B Code-block de validação do campo 
						Nil			,;    	// [08] B Code-block de validação When do campo 
						Nil			,;   	// [09] A Lista de valores permitido do campo 
						.F.			,;  	// [10] L Indica se o campo tem preenchimento obrigatório 
						Nil			,;  	// [11] B Code-block de inicializacao do campo                
						Nil			,; 		// [12] L Indica se trata de um campo chave 
						Nil			,;    	// [13] L Indica se o campo pode receber valor em uma operação de update.
 						.T. )            						// [14] L Indica se o campo é virtual
 						
oStruTFI:AddField( 	STR0019   ,;  	// [01] C Titulo do campo # Status
						STR0019	,;   	// [02] C ToolTip do campo # Status
						"TFI_SIT"	,;   	// [03] C identificador (ID) do Field
						"BT"		,;   	// [04] C Tipo do campo
						1			,;   	// [05] N Tamanho do campo
						0			,;   	// [06] N Decimal do campo
						Nil	 		,;   	// [07] B Code-block de validação do campo 
						Nil			,;    	// [08] B Code-block de validação When do campo 
						Nil			,;   	// [09] A Lista de valores permitido do campo 
						.F.			,;  	// [10] L Indica se o campo tem preenchimento obrigatório 
						Nil			,;   	// [11] B Code-block de inicializacao do campo                
						Nil			,;  	// [12] L Indica se trata de um campo chave 
						Nil			,;    	// [13] L Indica se o campo pode receber valor em uma operação de update.
 						.T. )      		// [14] L Indica se o campo é virtual

oStruTFI:AddField( 	'Num Série'   ,;  	// [01] C Titulo do campo # Status
						'Num Série'	,;   	// [02] C ToolTip do campo # Status
						"TFI_NUMSER"	,;   	// [03] C identificador (ID) do Field
						"C"		,;   	// [04] C Tipo do campo
						TamSX3("AA3_NUMSER")[1]			,;   	// [05] N Tamanho do campo
						0			,;   	// [06] N Decimal do campo
						Nil	 		,;   	// [07] B Code-block de validação do campo 
						Nil			,;    	// [08] B Code-block de validação When do campo 
						Nil			,;   	// [09] A Lista de valores permitido do campo 
						.F.			,;  	// [10] L Indica se o campo tem preenchimento obrigatório 
						Nil,;	           // bInit                
						Nil			,;  	// [12] L Indica se trata de um campo chave 
						Nil			,;    	// [13] L Indica se o campo pode receber valor em uma operação de update.
 						.T. )      		// [14] L Indica se o campo é virtual

oStruABS:SetProperty( "ABS_ENTIDA", MODEL_FIELD_WHEN, {|oMdl,cCpo,xValor| At160WhCli( oMdl,cCpo,xValor ) } )
oStruABS:SetProperty( "ABS_CODIGO", MODEL_FIELD_WHEN, {|oMdl,cCpo,xValor| At160WhCli( oMdl,cCpo,xValor ) } )
oStruABS:SetProperty( "ABS_LOJA", MODEL_FIELD_WHEN, {|oMdl,cCpo,xValor| At160WhCli( oMdl,cCpo,xValor ) } )

aAux := FwStruTrigger("ABS_LOCPAI","ABS_DESPAI",'At160LDesc(FwFldGet("ABS_LOCPAI"))',.F.,Nil,Nil,Nil)
oStruABS:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("ABS_SINDIC","ABS_DSCSIN",'ALLTRIM( POSICIONE("RCE",1,XFILIAL("RCE")+M->ABS_SINDIC,"RCE_DESCRI") )',.F.,Nil,Nil,Nil)
oStruABS:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("ABS_REGIAO","ABS_DSCREG",'ALLTRIM( POSICIONE("SX5",1,XFILIAL("SX5")+"A2"+M->ABS_REGIAO,"X5_DESCRI") )',.F.,Nil,Nil,Nil)
oStruABS:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("ABS_LOJA","ABS_DESENT",'At160DsEnt()',.F.,Nil,Nil,Nil)
oStruABS:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("ABS_ENTIDA","ABS_CODIGO",'',.F.,Nil,Nil,Nil)
oStruABS:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("ABS_ENTIDA","ABS_LOJA",'',.F.,Nil,Nil,Nil)
oStruABS:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("ABS_ENTIDA","ABS_DESENT",'',.F.,Nil,Nil,Nil)
oStruABS:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("ABS_CODIGO","ABS_LOJA",'',.F.,Nil,Nil,Nil)
oStruABS:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

oStruABP:RemoveField("ABP_COD")
oStruABP:RemoveField("ABP_REVISA")
oStruABP:RemoveField("ABP_VERBA")
oStruABP:RemoveField("ABP_DSVERB")
oStruABP:RemoveField("ABP_CODPRO")
oStruABP:RemoveField("ABP_ENTIDA")

// Cria o objeto do Modelo de Dados
oModel := MPFormModel():New("TECA160",/*bPreValid*/,bPosValid,/*bCommit*/)

oModel:AddFields("ABSMASTER",/*cOwner*/,oStruABS)

// Janela Locacao de equipamentos
oModel:AddGrid("TFIDETAIL","ABSMASTER",oStruTFI,/*bLinePre*/,/*bLinePost*/,/*bPreVal*/,/*bPosVal*/,{|oGrid,lCopia| At160FillData(oGrid,lCopia,"TFI")})
oModel:addGrid("TEVDETAIL","TFIDETAIL",oStruTEV)

// Janela RH
oModel:AddGrid("TFFDETAIL","ABSMASTER",oStruTFF,/*bLinePre*/,/*bLinePost*/,/*bPreVal*/,/*bPosVal*/,{|oGrid,lCopia| At160FillData(oGrid,lCopia,"TFF")})
oModel:AddGrid("TFGDETAIL","TFFDETAIL",oStruTFG,/*bLinePre*/,/*bLinePost*/,/*bPreVal*/,/*bPosVal*/,/*bLoad*/)
oModel:AddGrid("TFHDETAIL","TFFDETAIL",oStruTFH,/*bLinePre*/,/*bLinePost*/,/*bPreVal*/,/*bPosVal*/,/*bLoad*/)
oModel:AddGrid("ABPDETAIL","TFFDETAIL",oStruABP,/*bLinePre*/,/*bLinePost*/,/*bPreVal*/,/*bPosVal*/,/*bLoad*/)
oModel:AddGrid("TFUDETAIL","TFFDETAIL",oStruTFU,/*bLinePre*/,/*bLinePost*/,/*bPreVal*/,/*bPosVal*/,/*bLoad*/)

oModel:SetPrimaryKey({"ABS_FILIAL","ABS_LOCAL"})

// Relacionamento com o GRID Principal
oModel:SetRelation("TFFDETAIL",{{"TFF_FILIAL","xFilial('TFF')"},{"TFF_LOCAL" ,"ABS_LOCAL" }},TFF->(IndexKey(1)))
oModel:SetRelation("TFIDETAIL",{{"TFI_FILIAL","xFilial('TFI')"},{"TFI_LOCAL" ,"ABS_LOCAL" }},TFI->(IndexKey(1)))

// Relacionamento com o GRID Locacao de Equipamento
oModel:SetRelation("TEVDETAIL",{{"TEV_FILIAL","xFilial('TEV')"},{"TEV_CODLOC", "TFI_COD"	}},TEV->(IndexKey(1)))

// Relacionamento com o GRID RH
oModel:SetRelation("ABPDETAIL",{{"ABP_FILIAL","xFilial('ABP')"},{"ABP_ITRH"  ,"TFF_COD"	}}										,ABP->(IndexKey(1)))
oModel:SetRelation("TFGDETAIL",{{"TFG_FILIAL","xFilial('TFG')"},{"TFG_CODPAI","TFF_COD"	} , { 'TFG_LOCAL', 'ABS_LOCAL' }}	,TFG->(IndexKey(1)))
oModel:SetRelation("TFHDETAIL",{{"TFH_FILIAL","xFilial('TFH')"},{"TFH_CODPAI","TFF_COD"	} , { 'TFH_LOCAL', 'ABS_LOCAL' }}	,TFH->(IndexKey(1)))
oModel:SetRelation("TFUDETAIL",{{"TFU_FILIAL","xFilial('TFU')"},{"TFU_CODTFF","TFF_COD"	}}										,TFU->(IndexKey(1)))

oModel:SetDescription(STR0001)  // "Local de Atendimento"

oStruTFF:SetProperty('TFF_DESCRI', MODEL_FIELD_INIT, {|| ALLTRIM( POSICIONE("SB1",1,XFILIAL("SB1")+TFF->TFF_PRODUT,"B1_DESC"))})
oStruTFF:SetProperty('TFF_UM'    , MODEL_FIELD_INIT, {|| ALLTRIM( POSICIONE("SB1",1,XFILIAL("SB1")+TFF->TFF_PRODUT,"B1_UM"))})
oStruTFG:SetProperty('TFG_DESCRI', MODEL_FIELD_INIT, {|| ALLTRIM( POSICIONE("SB1",1,XFILIAL("SB1")+TFG->TFG_PRODUT,"B1_DESC"))})
oStruTFG:SetProperty('TFG_UM'    , MODEL_FIELD_INIT, {|| ALLTRIM( POSICIONE("SB1",1,XFILIAL("SB1")+TFG->TFG_PRODUT,"B1_UM"))})
oStruTFH:SetProperty('TFH_DESCRI', MODEL_FIELD_INIT, {|| ALLTRIM( POSICIONE("SB1",1,XFILIAL("SB1")+TFH->TFH_PRODUT,"B1_DESC"))})
oStruTFH:SetProperty('TFH_UM'    , MODEL_FIELD_INIT, {|| ALLTRIM( POSICIONE("SB1",1,XFILIAL("SB1")+TFH->TFH_PRODUT,"B1_UM"))})
oStruTFI:SetProperty('TFI_DESCRI', MODEL_FIELD_INIT, {|| ALLTRIM( POSICIONE("SB1",1,XFILIAL("SB1")+TFI->TFI_PRODUT,"B1_DESC"))})
oStruTFI:SetProperty('TFI_UM'    , MODEL_FIELD_INIT, {|| ALLTRIM( POSICIONE("SB1",1,XFILIAL("SB1")+TFI->TFI_PRODUT,"B1_UM"))})
oStruTFU:SetProperty('TFU_ABNDES', MODEL_FIELD_INIT, {|| ALLTRIM( POSICIONE("ABN",1,XFILIAL("ABN")+TFU->TFU_CODABN,"ABN_DESC"))})

oModel:getModel('TFFDETAIL'):SetDescription(STR0020) // 'Recursos Humanos'
oModel:getModel('TFFDETAIL'):SetOptional(.T.)
oModel:getModel('TFFDETAIL'):SetNoInsertLine(.T.)
oModel:getModel('TFFDETAIL'):SetNoUpdateLine(.T.)
oModel:getModel('TFFDETAIL'):SetNoDeleteLine(.T.)
oModel:getModel('TFFDETAIL'):SetOnlyQuery(.T.)

oModel:getModel('ABPDETAIL'):SetDescription(STR0021)  // 'Beneficios'
oModel:getModel('ABPDETAIL'):SetOptional(.T.)
oModel:getModel('ABPDETAIL'):SetNoInsertLine(.T.)
oModel:getModel('ABPDETAIL'):SetNoUpdateLine(.T.)
oModel:getModel('ABPDETAIL'):SetNoDeleteLine(.T.)
oModel:getModel('ABPDETAIL'):SetOnlyQuery(.T.)

oModel:getModel('TFGDETAIL'):SetDescription(STR0022) // 'Materiais de Implantação'
oModel:getModel('TFGDETAIL'):SetOptional(.T.)
oModel:getModel('TFGDETAIL'):SetNoInsertLine(.T.)
oModel:getModel('TFGDETAIL'):SetNoUpdateLine(.T.)
oModel:getModel('TFGDETAIL'):SetNoDeleteLine(.T.)
oModel:getModel('TFGDETAIL'):SetOnlyQuery(.T.)

oModel:getModel('TFHDETAIL'):SetDescription(STR0023) // 'Material de Consumo'
oModel:getModel('TFHDETAIL'):SetOptional(.T.)
oModel:getModel('TFHDETAIL'):SetNoInsertLine(.T.)
oModel:getModel('TFHDETAIL'):SetNoUpdateLine(.T.)
oModel:getModel('TFHDETAIL'):SetNoDeleteLine(.T.)
oModel:getModel('TFHDETAIL'):SetOnlyQuery(.T.)

oModel:getModel('TFUDETAIL'):SetDescription(STR0024) // 'Hora Extra'
oModel:getModel('TFUDETAIL'):SetOptional(.T.)
oModel:getModel('TFUDETAIL'):SetNoInsertLine(.T.)
oModel:getModel('TFUDETAIL'):SetNoUpdateLine(.T.)
oModel:getModel('TFUDETAIL'):SetNoDeleteLine(.T.)
oModel:getModel('TFUDETAIL'):SetOnlyQuery(.T.)

oModel:getModel('TFIDETAIL'):SetDescription(STR0025) // 'Locação de Equipamentos'
oModel:getModel('TFIDETAIL'):SetOptional(.T.)
oModel:getModel('TFIDETAIL'):SetNoInsertLine(.T.)
oModel:getModel('TFIDETAIL'):SetNoUpdateLine(.T.)
oModel:getModel('TFIDETAIL'):SetNoDeleteLine(.T.)
oModel:getModel('TFIDETAIL'):SetOnlyQuery(.T.)

oModel:getModel('TEVDETAIL'):SetDescription(STR0026) // 'Cobrança da Locação'
oModel:getModel('TEVDETAIL'):SetOptional(.T.)
oModel:getModel('TEVDETAIL'):SetNoInsertLine(.T.)
oModel:getModel('TEVDETAIL'):SetNoUpdateLine(.T.)
oModel:getModel('TEVDETAIL'):SetNoDeleteLine()
oModel:getModel('TEVDETAIL'):SetOnlyQuery(.T.)

oModel:SetActivate( {|oModel| InitDados( oModel ) } )

Return( oModel )

//------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef

Definição da View

@sample 	ViewDef()

@param		Nenhum
	
@return	ExpO Objeto FwFormView 

@since		16/01/2012       
@version	P11   
/*/
//------------------------------------------------------------------------------

Static Function ViewDef()

Local oView	 := Nil										// Interface de visualização construída	
Local oModel   := FWLoadModel("TECA160")				// Cria um objeto de Modelo de dados baseado no ModelDef do fonte informado

Local oStruABS := FWFormStruct( 2, "ABS" )				// Cria as estruturas a serem usadas na View
Local oStruTFF := FWFormStruct( 2, "TFF", {|cCpo| !( Alltrim(cCpo)$'TFF_COD#TFF_LOCAL#TFF_SITUAC') })
Local oStruTFG := FWFormStruct( 2, "TFG", {|cCpo| !( Alltrim(cCpo)$'TFG_COD#TFG_LOCAL') })
Local oStruTFH := FWFormStruct( 2, "TFH", {|cCpo| !( Alltrim(cCpo)$'TFH_COD#TFH_LOCAL') })
Local oStruTFI := FWFormStruct( 2, "TFI", {|cCpo| !( Alltrim(cCpo)$'TFI_COD#TFI_LOCAL#TFI_SITUAC') })
Local oStruABP := FWFormStruct( 2, "ABP", {|cCpo| !( Alltrim(cCpo)$'ABP_COD#ABP_REVISA#ABP_VERBA#ABP_DSVERB#ABP_CODPRO#ABP_ENTIDA#ABP_ITRH#ABP_ITEMPR') })  
Local oStruTFU := FWFormStruct( 2, "TFU", {|cCpo| !( Alltrim(cCpo)$'TFU_CODIGO#TFU_CODTFF#TFU_LOCAL') })
Local oStruTEV := FWFormStruct( 2, "TEV")

oStruTFF:AddField( 	"TFF_SIT"	,; // cIdField
                   	"01"		,; // cOrdem
                   	"  "		,; // cTitulo
                   	"  "		,; // cDescric
                   	{}			,; // aHelp
                   	"BT"		,; // cType
						""			,; // cPicture
                     Nil			,; // nPictVar
                     Nil			,; // Consulta F3
                     .T.			,; // lCanChange
                     "RH_A02"	,; // cFolder
                     Nil			,; // cGroup
                     Nil			,; // aComboValues
                     Nil			,; // nMaxLenCombo
                     Nil			,; // cIniBrow
                     .T.			,; // lVirtual
                     Nil ) 			// cPictVar

oStruTFI:AddField( 	"TFI_SIT"	,; // cIdField
                   	"01"		,; // cOrdem
                   	"  "		,; // cTitulo
                   	"  "		,; // cDescric
                   	{}			,; // aHelp
                   	"BT"		,; // cType
						""			,; // cPicture
                     Nil			,; // nPictVar
                     Nil			,; // Consulta F3
                     .T.			,; // lCanChange
                     "LOC_A03"	,; // cFolder
                     Nil			,; // cGroup
                     Nil			,; // aComboValues
                     Nil			,; // nMaxLenCombo
                     Nil			,; // cIniBrow
                     .T.			,; // lVirtual
                     Nil ) 			// cPictVar
                    
oStruTFI:AddField( 	"TFI_NUMSER"	,; // cIdField
                   	"05"		,; // cOrdem
                   	"Num. Série"		,; // cTitulo
                   	"Num. Série"		,; // cTitulo
                   	{}			,; // aHelp
                   	"C"		,; // cType
						""			,; // cPicture
                     Nil			,; // nPictVar
                     Nil			,; // Consulta F3
                     .T.			,; // lCanChange
                     "LOC_A03"	,; // cFolder
                     Nil			,; // cGroup
                     Nil			,; // aComboValues
                     Nil			,; // nMaxLenCombo
                     Nil			,; // cIniBrow
                     .T.			,; // lVirtual
                     Nil ) 			// cPictVar
                    


oView := FWFormView():New()								// Cria o objeto de View
oView:SetModel(oModel)									// Define qual Modelo de dados será utilizado
				
oView:AddField("VIEW_ABS",oStruABS,"ABSMASTER")		// Adiciona no nosso View um controle do tipo formulário (antiga Enchoice)

oView:AddGrid( "TECA160_RH" , oStruTFF, "TFFDETAIL" )
oView:AddGrid( "TECA160_RMI", oStruTFG, "TFGDETAIL" )
oView:AddGrid( "TECA160_RMC", oStruTFH, "TFHDETAIL" )
oView:AddGrid( "TECA160_LCE", oStruTFI, "TFIDETAIL" )
oView:AddGrid( "TECA160_ABP", oStruABP, "ABPDETAIL" )
oView:AddGrid( "TECA160_TFU", oStruTFU, "TFUDETAIL" )
oView:AddGrid( "TECA160_TEV", oStruTEV, "TEVDETAIL" )

oStruABS:SetProperty( "ABS_CODIGO", MVC_VIEW_LOOKUP,{|| At160RetCP()}	)
oStruABS:SetProperty( "ABS_CLIFAT", MVC_VIEW_LOOKUP,{|| At160RetCP()}	)

// Altera a ordem dos campos para exibição das informações de contrato
oStruTFF:SetProperty( "TFF_SIT"		, MVC_VIEW_ORDEM , "01" )
oStruTFF:SetProperty( "TFF_CONTRT"	, MVC_VIEW_ORDEM , "02" )
oStruTFF:SetProperty( "TFF_CONREV"	, MVC_VIEW_ORDEM , "03" )
oStruTFI:SetProperty( "TFI_SIT"		, MVC_VIEW_ORDEM , "01" )
oStruTFI:SetProperty( "TFI_CONTRT"	, MVC_VIEW_ORDEM , "02" )
oStruTFI:SetProperty( "TFI_CONREV"	, MVC_VIEW_ORDEM , "03" )

// Cria Folder na view
oView:CreateFolder("FOLDER")

// Cria pastas nas folders
oView:AddSheet( "FOLDER", "ABA_PRI", STR0013 )	//"Principal"
oView:AddSheet( "FOLDER", "ABA_RH" , STR0014 )	//"Recursos Humanos"
oView:AddSheet( "FOLDER", "ABA_LOC", STR0017 )	//"Locação de Equipamentos"

// Cria um "box" horizontal para receber cada elemento da view
oView:CreateHorizontalBox("PRINCIPAL"	,100,,,"FOLDER" , "ABA_PRI" )		
oView:CreateHorizontalBox("RH_A02"   	,60 ,,,"FOLDER" , "ABA_RH" )
oView:CreateHorizontalBox("RH_A02A"	,40 ,,,"FOLDER" , "ABA_RH" )

	// cria folder e sheets para Abas de Material Consumo, Implantação e Benefícios
	oView:CreateFolder( 'RH_ABAS', 'RH_A02A')
	oView:AddSheet('RH_ABAS','RH_ABA01',STR0027) // 'Benefícios RH'
	oView:AddSheet('RH_ABAS','RH_ABA02',STR0022) // 'Materiais de Implantação'
	oView:AddSheet('RH_ABAS','RH_ABA03',STR0023) // 'Materiais de Consumo'
	oView:AddSheet('RH_ABAS','RH_ABA04',STR0028) // 'Hora Extra'
	
oView:CreateHorizontalBox( 'ID_RH_01' , 100,,, 'RH_ABAS', 'RH_ABA01' ) // Define a área de Benefícios item de Rh
oView:CreateHorizontalBox( 'ID_RH_02' , 100,,, 'RH_ABAS', 'RH_ABA02' ) // Define a área de Materiais de Implantação
oView:CreateHorizontalBox( 'ID_RH_03' , 100,,, 'RH_ABAS', 'RH_ABA03' ) // Define a área de Materiais de Consumo
oView:CreateHorizontalBox( 'ID_RH_04' , 100,,, 'RH_ABAS', 'RH_ABA04' ) // Define a área da Hora Extra

oView:CreateHorizontalBox("LOC_A03" ,70,,,"FOLDER" , "ABA_LOC" )
oView:CreateHorizontalBox("LOC_A03A",30,,,"FOLDER" , "ABA_LOC" )

// Relaciona o identificador (ID) da View com o "box" para exibição
oView:SetOwnerView("VIEW_ABS"		, "PRINCIPAL"	)
oView:SetOwnerView("TECA160_RH"		, "RH_A02"		)
oView:SetOwnerView("TECA160_ABP"	, "ID_RH_01"	)
oView:SetOwnerView("TECA160_RMI"	, "ID_RH_02"	)
oView:SetOwnerView("TECA160_RMC"	, "ID_RH_03"	)
oView:SetOwnerView("TECA160_TFU"	, "ID_RH_04"	)
oView:SetOwnerView("TECA160_LCE"	, "LOC_A03"	)

oView:SetOwnerView("TECA160_TEV"	, "LOC_A03A"	)
oView:EnableTitleView("TECA160_TEV", STR0029)  // 'Cobrança da Locação'

oView:AddUserButton(STR0011,"",{|| At160VfLoc(oModel)},,,) //"Verificar Localização"
oView:AddUserButton(STR0030,"",{|| At160GetLegend()},,,) //"Legenda"
oView:AddUserButton(STR0038, 'CLIPS',{|oView| At160Disci(FwFldGet("ABS_LOCAL"))})//"Histórico Disciplinar" 

oView:SetDescription( STR0001 )

Return( oView )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At160Estru

Estrutura dos locais de atendimento

@sample 	At160Estru() 

@param		Nenhum
	
@return	ExpL Verdadeiro /  Falso 

@since		16/01/2012       
@version	P11   
/*/
//------------------------------------------------------------------------------
Function At160Estru()

Local lRetorno	:= .F.
Local oDlg			:= Nil
Local oTree		:= Nil
Local aSize		:= MsAdvSize(.F.)
Local oMenuPop	:= Nil
Local aMenuPop	:= {}
Local aAreaABS	:= ABS->(GetArea())

DEFINE DIALOG oDlg TITLE STR0003 FROM aSize[7],0 TO aSize[6],aSize[5] PIXEL   // "Locais de Atendimento"
	 	
	oTree := DbTree():New(0,0,160,260,oDlg,,,.T.)	// Insere itens    
	oTree:Align := CONTROL_ALIGN_ALLCLIENT
		
	// Posiciona no Pai
	While !Empty(ABS->ABS_LOCPAI)
		ABS->(DbSetOrder(1)) //ABS_LOCAL
		ABS->(DbSeek(xFilial("ABS")+ABS->ABS_LOCPAI)) 		
	EndDo
		
	At160MTree(oTree,ABS->ABS_LOCAL)   

	MENU oMenuPop POPUP OF oTree
		aAdd(aMenuPop,MenuAddItem(STR0004,,,.T.,,,,oMenuPop,{|| At160MVCEx(oTree,MODEL_OPERATION_VIEW )	},,,,,{ || .T. } )) 	// "Visualizar"
		aAdd(aMenuPop,MenuAddItem(STR0005,,,.T.,,,,oMenuPop,{|| At160MVCEx(oTree,MODEL_OPERATION_INSERT)	},,,,,{ || .T. } ))  // "Incluir"
		aAdd(aMenuPop,MenuAddItem(STR0006,,,.T.,,,,oMenuPop,{|| At160MVCEx(oTree,MODEL_OPERATION_UPDATE)	},,,,,{ || .T. } ))  // "Alterar"
		aAdd(aMenuPop,MenuAddItem(STR0007,,,.T.,,,,oMenuPop,{|| At160MVCEx(oTree,MODEL_OPERATION_DELETE)	},,,,,{ || .T. } ))  // "Excluir"
	ENDMENU
		
	oTree:BrClicked := {|oTree,x,y| oMenuPop:Activate(x-20,y-110,oTree) } // Posição x,y em relação a Dialog	
	oTree:EndTree()
	  	
ACTIVATE DIALOG oDlg ON INIT EnchoiceBar(oDlg,{|| lRetorno := .T., oDlg:End()},{||oDlg:End()}) CENTERED

RestArea(aAreaABS)
Return( lRetorno )     


//------------------------------------------------------------------------------
/*/{Protheus.doc} At160MVCEx

Executa a rotina de Visualizar, Incluir, Alterar e Excluir em MVC.

@sample 	At160MVCEx(oTree,nOperation) 

@param		ExpO1 Objeto DbTree.
			ExpN2 Tipo de operacao.
	
@return	ExpL Verdadeiro 

@since		16/01/2012       
@version	P11   
/*/
//------------------------------------------------------------------------------

Static Function At160MVCEx(oTree,nOperation)

Local aSize	 	:= FWGetDialogSize( oMainWnd )			// Coordenadas da Dialog Principal.
Local lRetorno 	:= .T. 									// Retorno da validacao.
Local lConfirma	:= .F. 									// Confirmacao da rotina MVC.
Local oModel 	 	:= Nil										// Modelo de dados.
Local oView   	:= Nil										// Interface.
Local oFWMVCWin	:= Nil										// Dialog MVC.
Local cLocal		:= ""										// Local.
Local cLocPaiBkp	:= ""										// Sublocal do local principal(Backup).					
Local cDescBkp 	:= ""										// Backup da descrição.

DbSelectArea("ABS")

Do Case

	Case nOperation == 1
	
		ABS->(DbSetOrder(1))
		ABS->(DbSeek(xFilial("ABS")+oTree:GetCargo()))
		FwExecView(STR0004,"TECA160",nOperation)
		
	Case nOperation == 3
	
		oModel   := FWLoadModel("TECA160")
		oMdlABS  := oModel:GetModel("ABSMASTER")
		oStrtABS := oMdlABS:GetStruct()
		oStrtABS:SetProperty("ABS_LOCPAI",MODEL_FIELD_INIT,{|| oTree:GetCargo() })
		oStrtABS:SetProperty("ABS_DESPAI",MODEL_FIELD_INIT,{|| At160LDesc(oTree:GetCargo()) })
		oStrtABS:SetProperty("ABS_LOCPAI",MODEL_FIELD_WHEN,{|| Empty(FwFldGet("ABS_LOCPAI")) })
		   
		oModel:SetOperation(3)
		oModel:Activate() 
			 
		oView := FWLoadView("TECA160")
		oView:SetModel(oModel)
		oView:SetOperation(3)
	                               
		oFWMVCWin := FWMVCWindow():New()
		oFWMVCWin:SetUseControlBar(.T.)
		oFWMVCWin:SetView(oView)
		oFWMVCWin:SetCentered(.T.)
		oFWMVCWin:SetPos(aSize[1],aSize[2])
		oFWMVCWin:SetSize(aSize[3],aSize[4]) 
		oFWMVCWin:SetTitle(STR0005)
		oFWMVCWin:oView:BCloseOnOk := {|| .T. }
		oFWMVCWin:Activate(,{|| cLocal := oMdlABS:GetValue("ABS_LOCAL"), .T. })
		
		DbSelectArea("ABS")
		DbSetOrder(1)
		
		If ( !Empty(cLocal) .AND. DbSeek(xFilial("ABS")+cLocal) )
			At160MTree(oTree,ABS->ABS_LOCAL)
			oTree:EndTree()
		EndIf 
	
	Case nOperation == 4
	
		ABS->(DbSetOrder(1))
		ABS->(DbSeek(xFilial("ABS")+oTree:GetCargo()))
		cLocal		:= ABS->ABS_LOCAL
		cLocPaiBkp	:= ABS->ABS_LOCPAI
		cDescBkp	:= ABS->ABS_DESCRI
		FwExecView(STR0006,"TECA160",nOperation,,{|| .T. },{|| lConfirma := .T. })
		// Garante que o posicionamento do registro alterado.
		ABS->(DbSetOrder(1))
		ABS->(DbSeek(xFilial("ABS")+cLocal)) 
		If lConfirma 
			If	( ABS->ABS_LOCPAI == cLocPaiBkp .AND. ABS->ABS_DESCRI <> cDescBkp )
				oTree:ChangePrompt(STR0008+ABS->ABS_LOCAL+ " | "+STR0009+Capital(ABS->ABS_DESCRI),ABS->ABS_LOCAL) //"Código: "#"Descrição: "
			Else
				// Posiciona no Pai
				While !Empty(ABS->ABS_LOCPAI)
					ABS->(DbSetOrder(1)) //ABS_LOCAL
					ABS->(DbSeek(xFilial("ABS")+ABS->ABS_LOCPAI)) 		
				EndDo
				oTree:Reset()
				At160MTree(oTree,ABS->ABS_LOCAL)  
			EndIf 
		EndIf	
	Case nOperation == 5

		DbSelectArea("ABS")
		DbSetOrder(1)
		If DbSeek(xFilial("ABS")+oTree:GetCargo())
			cLocal := ABS->ABS_LOCAL
			FwExecView(STR0007,"TECA160",nOperation,,{|| .T. },{|| lConfirma := .T. })
			If ( lConfirma .AND. !DbSeek(xFilial("ABS")+cLocal) )
				oTree:DelItem()
				oTree:EndTree()
			EndIf	
		EndIf	
		
EndCase

Return( lRetorno )       

//------------------------------------------------------------------------------
/*/{Protheus.doc} At160MTree

Monta os locais de atendimento no Tree.

@sample 	At160MTree(oTree,cLocPai) 

@param		ExpO1 Objeto DbTree.
			ExpC2 Local Pai.
	
@return	ExpL Verdadeiro 

@since		16/01/2012       
@version	P11   
/*/ 
//------------------------------------------------------------------------------

Static Function At160MTree(oTree,cLocPai)
 
Local nRecno	:= 0					// Recno.

If !Empty(ABS->ABS_LOCPAI)
	oTree:AddItem(STR0008+ABS->ABS_LOCAL+" | "+STR0009+Capital(ABS->ABS_DESCRI),ABS->ABS_LOCAL,"PMSTASK4","PMSTASK1",,,2)  				//"Código: "#"Descrição: "
Else
	oTree:AddItem(STR0008+ABS->ABS_LOCAL+" | "+STR0009+Capital(ABS->ABS_DESCRI)+Space(500),ABS->ABS_LOCAL,"FOLDER5","FOLDER6",,,1)		//"Código: "#"Descrição: "	
EndIf

ABS->(DbSetOrder(3)) //ABS_LOCPAI
ABS->(DbSeek(xFilial("ABS")+cLocPai))

While !ABS->(EOF()) .AND. ABS->ABS_LOCPAI == cLocPai
	oTree:TreeSeek(cLocPai)
	nRecno := Recno()
	At160MTree(oTree,ABS->ABS_LOCAL)
	ABS->(DbGoTo(nRecno))		
	ABS->(DbSkip())
End 
 
Return( .T. )		

//------------------------------------------------------------------------------
/*/{Protheus.doc} At160VdFil

Verifica se há filhos de um local de atendimento.

@sample 	At160VdFil(oModel) 

@param		ExpO1 Modelo de dados.
	
@return	ExpL Verdadeiro / Falso

@since		16/01/2012       
@version	P11   
/*/
//------------------------------------------------------------------------------

Static Function At160VdFil(oModel)  
 
Local lRetorno := .T.							// Retorno da validacao
Local aAreaABS := ABS->(GetArea())				// Guarda a area atual.
Local oMdlCab 	:= Nil
Local cFilAlvo 	:= ""
Local cCodCC 	:= ""

DbSelectArea("ABS")
DbSetOrder(3)

If oModel:GetOperation() == MODEL_OPERATION_DELETE 
	If DbSeek(xFilial("ABS")+oModel:GetValue("ABSMASTER","ABS_LOCAL"))
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		//³	 Problema: Este local contém sublocais, sua exclusão não será possivel.     ³
		//³	 Solucao: Exclua os sublocais relacionado a este local.						   ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		lRetorno := .F.
		Help("",1,"AT160EXSUB")
	EndIf
ElseIf oModel:GetOperation() == MODEL_OPERATION_INSERT .Or. oModel:GetOperation() == MODEL_OPERATION_UPDATE
	oMdlCab := oModel:GetModel("ABSMASTER")
	// copia as informações preenchidas nos campos 
	cFilAlvo := oMdlCab:GetValue("ABS_FILCC")
	cCodCC := oMdlCab:GetValue("ABS_CCUSTO")

	If !Empty( cCodCC ) .And. !Empty(  cFilAlvo)

		lRetorno := AtChkHasKey( "CTT", 1, xFilial("CTT",cFilAlvo)+cCodCC, .T. )

	ElseIf ( Empty( cCodCC ) .And. !Empty( cFilAlvo ) ) .Or. ;
		( !Empty( cCodCC ) .And. Empty( cFilAlvo ) )

		lRetorno := .F.
		Help( "", 1, "AT160CCLOC", , STR0045, 1, 0,,,,,,;  // "Informações incompletas de centro de custo no local de atendimento"
							{STR0046}) // "Preencha os 2 campos relacionados a centro de custo: Código [ABS_CCUSTO] e filial [ABS_FILCC]"
	EndIf
EndIf

RestArea(aAreaABS) 

Return( lRetorno )    		

//------------------------------------------------------------------------------
/*/{Protheus.doc} At160LDesc

Descricao do sublocal no browse.

@sample 	At160LDesc(cLocal) 

@param		ExpC1 Sublocal
	
@return	ExpC Descricao

@since		16/01/2012       
@version	P11   
/*/
//------------------------------------------------------------------------------
Function At160LDesc(cLocal)

Local aAreaABS := ABS->(GetArea())
Local cRet := POSICIONE("ABS",1,XFILIAL("ABS")+cLocal,"ABS_DESCRI")

RestArea(aAreaABS)

Return( cRet )        

//------------------------------------------------------------------------------
/*{Protheus.doc} At160VfLoc

.

@sample 	At160VfLoc(oView) 

@param		ExpC1 Modelo de Dados
	
@return	

@since		09/08/2013       
@version	P12
/*/
//------------------------------------------------------------------------------				
Function At160VfLoc(oModel)

Local oDlg
Local aSize			:= MsAdvSize()
Local oMdl := oModel:GetModel("ABSMASTER") 
Local cEnd	:= oMdl:GetValue("ABS_END")
Local cMuni	:= oMdl:GetValue("ABS_MUNIC")
Local cEsta	:= oMdl:GetValue("ABS_ESTADO")
Local cUrl		:= "https://maps.google.com"

If(!Empty(cEnd).OR.!Empty(cMuni).OR.!Empty(cEsta))
	cUrl := cUrl+"/maps?q="+AllTrim(cEnd)+" - "+AllTrim(cMuni)+" - "+AllTrim(cEsta) 
Else
	cUrl := cUrl+"/maps?q=Brasil"
	Help( " ", 1, "At160VfLoc", , STR0010, 1, 0 ) // Mensagem conforme TECA160.CH 
EndIf

	oMainWnd:CoorsUpdate()	// Atualiza as corrdenadas da Janela MAIN
	nMyWidth  := oMainWnd:nClientWidth - 10
	nMyHeight := oMainWnd:nClientHeight - 30

   	DEFINE DIALOG oDlg TITLE STR0012 From aSize[7],00 To nMyHeight,nMyWidth PIXEL	//"Localização"
     
        oTIBrowser := TIBrowser():New(07,07,nMyHeight-220, nMyWidth-820,cUrl)
        oTIBrowser:GoHome()
                     
    	ACTIVATE DIALOG oDlg CENTERED 
		
	
Return

//------------------------------------------------------------------------------
/*{Protheus.doc} At160RetCP

Retorna qual consulta padrão será exibida de acordo com a opção escolhida.

@sample 	At160RetCP() 

@param		ExpC1 Modelo de Dados
	
@return	

@since		09/25/2013       
@version	P12
/*/
//------------------------------------------------------------------------------	 
 
Function At160RetCP()

Local oModel		:= FwModelActive()
Local oMdl 		:= oModel:GetModel("ABSMASTER")
Local cEntidade	:= oMdl:GetValue("ABS_ENTIDA")
Local cConsulta	:= ""

Private CCADASTRO := ""

If cEntidade == "1"
	cConsulta := "SA1"
ElseIf cEntidade == "2"
	cConsulta := "SUS"
EndIf

Return cConsulta  

//------------------------------------------------------------------------------
/*{Protheus.doc} At160DsEnt

Retorna o nome da entidade (Cliente ou Prospect) no campo ABS_DESENT

@sample 	At160DsEnt() 

@param		ExpC1 Modelo de Dados
@param      ExpC2 Origem da chamada da rotina
	
@return	

@since		09/25/2013       
@version	P12
/*/
//------------------------------------------------------------------------------	 

Function At160DsEnt(cOrigem)
Local aArea       := GetArea()
Local oModel      := Nil 
Local oMdl       := Nil
Local cDesc       := ""

Default cOrigem   := ""

If Empty(cOrigem)
	oModel := FwModelActive()
	If oModel != Nil .AND. oModel:GetId() == "TECA160"
		oMdl := oModel:GetModel("ABSMASTER")
		If ( oMdl:GetValue("ABS_ENTIDA") == "1" )
	    	cDesc := ALLTRIM( POSICIONE('SA1',1,XFILIAL('SA1')+FWFLDGET("ABS_CODIGO")+FWFLDGET("ABS_LOJA"),'A1_NOME') )     	
		Else
	    	cDesc := ALLTRIM( POSICIONE('SUS',1,XFILIAL('SUS')+FWFLDGET("ABS_CODIGO")+FWFLDGET("ABS_LOJA"),'US_NOME') )
		EndIf
	Else
		If ( ABS->ABS_ENTIDA == "1" )
	    	cDesc := ALLTRIM( POSICIONE('SA1',1,XFILIAL('SA1')+ABS->ABS_CODIGO+ABS->ABS_LOJA,'A1_NOME') )     	
		Else
	    	cDesc := ALLTRIM( POSICIONE('SUS',1,XFILIAL('SUS')+ABS->ABS_CODIGO+ABS->ABS_LOJA,'US_NOME') )
		EndIf	 
	EndIf
Else
	If ( ABS->ABS_ENTIDA == "1" )
    	cDesc := ALLTRIM( POSICIONE('SA1',1,XFILIAL('SA1')+ABS->ABS_CODIGO+ABS->ABS_LOJA,'A1_NOME') )     	
	Else
    	cDesc := ALLTRIM( POSICIONE('SUS',1,XFILIAL('SUS')+ABS->ABS_CODIGO+ABS->ABS_LOJA,'US_NOME') )
	EndIf	 
EndIf
    
RestArea(aArea)

Return cDesc


//------------------------------------------------------------------------------
/*{Protheus.doc} At160GetLegend

Retorna a lista das legendas disponiveis para os contratos

@sample 	At160GetLegend() 

@return 	Nil	

@since		25/10/2013       
@version	P11.9
/*/
//------------------------------------------------------------------------------	 
Function At160GetLegend()

oLegenda := FwLegend():New()

oLegenda:Add( "", "BR_AMARELO", STR0031 )	// "Elaboracao"
oLegenda:Add( "", "BR_AZUL"   , STR0032 )	// "Emitido"	
oLegenda:Add( "", "BR_LARANJA", STR0033 )	// "Em Aprovacao"
oLegenda:Add( "", "BR_VERDE"  , STR0034 )	// "Vigente"
oLegenda:Add( "", "BR_CINZA"  , STR0035 )	// "Paralisado"		
oLegenda:Add( "", "BR_MARRON" , STR0036 )	// "Sol. Finalizacao"
oLegenda:Add( "", "BR_PRETO"  , STR0037 )	// "Finalizado"
oLegenda:View()		
		
oLegenda := Nil
DelClassIntf()

Return(Nil) 


//------------------------------------------------------------------------------
/*{Protheus.doc} At160IniLeg

Retorna a cor da  legenda da linha corrente

@sample 	At160IniLeg() 

@param		ExpC1 Campo para verificacao da situacao do contrato
	
@return 	Nil	

@since		25/10/2013       
@version	P11.9
/*/
//------------------------------------------------------------------------------	 
Function At160IniLeg(cModel, cCampo)

Local cCor 	   := ""
Local oMdlAtivo  := FwModelActive()
Local oMdlGrid   := Nil

If oMdlAtivo <> Nil .And. oMdlAtivo:GetId()=="TECA160"
	
	oMdlGrid := oMdlAtivo:GetModel(cModel)
	
	If oMdlGrid:GetLine() > 0	 	
	
		Do Case
			Case FwFldGet(cCampo) == "02" ; cCor := "BR_AMARELO"
			Case FwFldGet(cCampo) == "03" ; cCor := "BR_AZUL"   
			Case FwFldGet(cCampo) == "04" ; cCor := "BR_LARANJA"
			Case FwFldGet(cCampo) == "05" ; cCor := "BR_VERDE"  
			Case FwFldGet(cCampo) == "06" ; cCor := "BR_CINZA"  
			Case FwFldGet(cCampo) == "07" ; cCor := "BR_MARRON" 
			Case FwFldGet(cCampo) == "08" ; cCor := "BR_PRETO"  		
		EndCase
				
	EndIf 
	
EndIf	

Return(cCor)


//------------------------------------------------------------------------------
/*{Protheus.doc} At160FillData

Filtra as informações do grid com relação ao contratos

@sample 	At160FillData(oGrid,lCopia,nPasta) 

@param		ExpO1 Grid para a verificação dos dados
@param		ExpL2 Para verificar se e necessario a copia
	
@return 	Array - Com a lista de informações

@since		28/10/2013       
@version	P11.9
/*/
//------------------------------------------------------------------------------
Function At160FillData(oGrid,lCopia, cAliasFil)
Local aRet     := {}
Local aRet2	 :=	{}
Local cCmpCont := cAliasFil + "_CONTRT"
Local cCmpRev	:= cAliasFil + "_CONREV"
Local cSitCont := ""
Local cContrt	 := "" 
Local cRevisa	:= ""
Local nX        

aRet2  := FormLoadGrid(oGrid,lCopia)

For nX:= 1 TO Len(aRet2)

	(cAliasFil)->(MsGoto(aRet2[nX,1]))				
	
	cContrt := (cAliasFil)->(&cCmpCont)
	cRevisa := (cAliasFil)->(&cCmpRev)
	
	If !Empty(Alltrim(cContrt))
		cSitCont := Posicione("CN9", 1, xFilial("CN9")+cContrt+cRevisa, "CN9_SITUAC" )
		If ! cSitCont $ "01#09#10"
			aAdd(aRet,aClone(aRet2[nX]))
		EndIf
	Endif	
		
Next

Return aRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} InitDados
	
Inicializa as informações de status dos contratos

@sample 	InitDados(  )

@since		28/10/2013
@version	P11.90

@param  	oMdlGer, Objeto, objeto geral do model que será alterado

/*/
//------------------------------------------------------------------------------
Static Function InitDados ( oMdlGer )

Local oMdlLoc	:= oMdlGer:GetModel("TFIDETAIL")
Local oMdlRh	:= oMdlGer:GetModel("TFFDETAIL")
Local nLinLoc	:= 0
Local nLinRh	:= 0
Local cCorLoc := ""
Local cCorRh 	:= ""
Local aSaveRows := {}

If !(oMdlGer:GetOperation() == MODEL_OPERATION_INSERT .Or. oMdlGer:GetOperation() == MODEL_OPERATION_DELETE)  

	aSaveRows := FwSaveRows()
	
	For nLinLoc := 1 To oMdlLoc:Length()
	
		oMdlLoc:GoLine( nLinLoc )
		
		If !oMdlLoc:IsDeleted() .And. !Empty(oMdlLoc:GetValue( "TFI_COD"))
			oMdlLoc:SetNoUpdateLine(.F.)		
			oMdlLoc:LoadValue( "TFI_NUMSER",At160NSer(oMdlLoc:GetValue( "TFI_COD"),oMdlLoc:GetValue( "TFI_PRODUT" )))
			cCorLoc := At160IniLeg("TFIDETAIL","TFI_SITUAC")
			If !Empty(cCorLoc)
				
				oMdlLoc:LoadValue( "TFI_SIT", cCorLoc )
	
				
			EndIf
			oMdlLoc:SetNoUpdateLine(.T.)
			
		EndIf
	
	Next nLinLoc
	
	For nLinRh := 1 to oMdlRh:Length()
			
		oMdlRh:GoLine( nLinRh )
		
		If !oMdlRh:IsDeleted()
			cCorRh := At160IniLeg("TFFDETAIL","TFF_SITUAC")
			If !Empty(cCorRh)
				oMdlRh:SetNoUpdateLine(.F.)
				oMdlRh:LoadValue( "TFF_SIT", cCorRh )
				oMdlRh:SetNoUpdateLine(.T.)
			EndIf
		EndIf		
		
	Next nLinRh
	
	FwRestRows( aSaveRows )

EndIf

oMdlRh:GoLine( 1 )
oMdlLoc:GoLine( 1 )

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At020Disci()
Rotina Abre a Tela do Histórico Disciplina do Atendente Posicionado

@author arthur.colado
@since 18/03/2014
@version 1.0
/*/
//------------------------------------------------------------------------------

Function At160Disci(cLocal)
Local oPanel            := Nil
Local oBrowse           := Nil

DEFINE MSDIALOG oPanel TITLE STR0038 FROM 050,050 TO 500,800 PIXEL//"Histórico Disciplinar"

oBrowse:= FWmBrowse():New()
oBrowse:SetOwner( oPanel )   
oBrowse:SetDescription( STR0038 ) //"Histórico Discilinar"
oBrowse:SetAlias( "TIT" )   
oBrowse:DisableDetails() 
oBrowse:SetWalkThru(.F.)
oBrowse:SetAmbiente(.F.)
oBrowse:SetProfileID("02")  
oBrowse:SetMenuDef( "  " )
oBrowse:SetFilterDefault( "TIT_CODABS = '" + cLocal + "' " )  
oBrowse:Activate() 

//bloco de codigo para duplo click - deve ficar após o activate, senao o FWMBrowse ira sobreescrever com o bloco padrao
oBrowse:BlDblClick := {||At160VisDisci()}   
oBrowse:Refresh()

ACTIVATE MSDIALOG oPanel CENTERED

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At020Disci()
Rotina Realiza a abertura da tela de disciplina

@author arthur.colado
@since 18/03/2014
@version 1.0
/*/
//------------------------------------------------------------------------------

Function At160VisDisci()
Local aArea       := GetArea()
                 
DbSelectArea("TIT")
TIT->(DbSetOrder(1))
      
If TIT->(DbSeek(xFilial("TIT")+TIT->TIT_CODIGO))
      FWExecView(Upper(STR0039),"VIEWDEF.TECA440",MODEL_OPERATION_VIEW,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/)//"Visualizar Disciplina"      
EndIf

RestArea(aArea)

Return (.T.)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At160VlPai()
Rotina Realiza validação do campo ABS_LOCPAI

@author Alessandro.Silva
@since 27/08/2014
@version 1.0
/*/
//------------------------------------------------------------------------------
Function At160VlPai()
Local	cCodPai:= M->ABS_LOCPAI
Local	cCodigo:= M->ABS_LOCAL
Local  lRetorno 	:= .T. 									
Local  aArea := GetArea()	

dbSelectArea("ABS")
ABS->(dbSetOrder(1))

If ABS->(dbSeek(xFilial("ABS")+cCodPai+cCodigo))
	If ( cCodPai == ABS->ABS_LOCAL .AND. cCodigo == ABS->ABS_LOCPAI )
		lRetorno := .F.
		Help( " ", 1, "At160VlPai", , STR0040, 1, 0 ) // "Valor do Sublocal invalido para este local"
	EndIf
	ABS->(dbSkip())
EndIf	

RestArea(aArea)
 
Return( lRetorno )
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
/*/{Protheus.doc} TableAttDef()
Rotina cria a visao LOCAIS POR CLIENTES e grafico de browse CONTAGEM DE LOCAIS POR CLIENTES

@since 16/05/2015
@version 1.0
@return ExpO oTableAtt  - Objeto do tipo FWTableAtt com as propriedades de grafico e visoes
/*/
//------------------------------------------------------------------------------
Static Function TableAttDef()
Local oBrwDsView  := Nil
Local oGrafLocCli := Nil
Local oTableAtt   := FWTableAtt():New() 

oTableAtt:SetAlias("ABS") 

//Visao
oBrwDsView := FWDSView():New()
oBrwDsView:SetId("VIS001")
oBrwDsView:SetName(STR0041) // "Locais por Clientes"
oBrwDsView:SetPublic(.T.)
oBrwDsView:SetCollumns({"ABS_CODIGO","ABS_LOJA","ABS_DESENT","ABS_LOCAL","ABS_DESCRI","ABS_CCUSTO","ABS_CLIFAT","ABS_LJFAT"})
oBrwDsView:SetOrder(1)
oBrwDsView:AddFilter(STR0041,"ABS_ENTIDA == '1'") // "Locais por Clientes"
oTableAtt:AddView(oBrwDsView)

//Grafico
oGrafLocCli := FWDSChart():New()
oGrafLocCli:SetID("GRF001")
oGrafLocCli:SetName(STR0042) //"Contagem Locais por Cliente"
oGrafLocCli:SetTitle(STR0042) //"Contagem Locais por Cliente"
oGrafLocCli:SetPublic(.T.)
oGrafLocCli:SetSeries({{"ABS","ABS_LOCAL","COUNT"}})
oGrafLocCli:SetCategory({{"ABS","ABS_CODIGO+ABS_ENTIDA"}})
oGrafLocCli:SetType("PIECHART")
oGrafLocCli:SetLegend(CONTROL_ALIGN_LEFT)
oGrafLocCli:SetTitleAlign(CONTROL_ALIGN_TOP)
oGrafLocCli:SetPicture("999,999,999.99")
oTableAtt:AddChart(oGrafLocCli) 

Return(oTableAtt)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At160NSer()
Retorna o numero de serie do equipamento

@since 15/09/2015

/*/
//------------------------------------------------------------------------------

Function At160NSer(cCodTFI,cProdut)
Local cRet  := ""
Local aArea       := GetArea()

TEW->( DbSetOrder( 7 ) ) // TEW_FILIAL+TEW_CODEQU+TEW_PRODUT+TEW_BAATD

If TEW->( DbSeek( xFilial('TEW') + cCodTFI+ cProdut) ) 
	cRet := TEW->TEW_BAATD
EndIf

RestArea(aArea)
Return cRet

/*/{Protheus.doc} At160WhCli()
	Retorna o numero de serie do equipamento

@since 	27/10/2016
@param 	oMdl, Objeto FwFormModelField, 

/*/
Function At160WhCli( oMdl,cCpo,xValor )
Local lRet := .T.
Local oModel := oMdl:GetModel()
Local cTip := oMdl:GetValue("ABS_ENTIDA")
Local cCodLocal := ""
Local cQry := ""

If oModel:GetOperation() == MODEL_OPERATION_UPDATE .And. ;
	cTip == "1"
	
	cCodLocal := oMdl:GetValue("ABS_LOCAL")
	cQry := GetNextAlias()
	
	BeginSQL Alias cQry
		SELECT ABS_LOCAL 
		FROM %Table:ABS% ABS
		WHERE ABS_FILIAL = %xFilial:ABS%
			AND ABS_LOCAL = %Exp:cCodLocal%
			AND ABS.%NotDel%
			AND EXISTS (
				SELECT 1
				FROM %Table:TFL% TFL
				WHERE TFL_FILIAL = %xFilial:TFI%
					AND TFL_LOCAL = ABS_LOCAL
					AND TFL_CONTRT <> ' '
					AND TFL.%NotDel%
				) 
	EndSQL
	
	If (cQry)->(!EOF())  // quando encontra registro significa que já há contrato gerado
		lRet := .F.  // e por isso não permite a alteração 
	EndIf
	(cQry)->(DbCloseArea())
EndIf

Return lRet

/*/{Protheus.doc} At160GetCC()
	Retorna o centro de custo associado ao local de atendimento

@since 		28/12/2016
@author 	josimar.assuncao
@param 		cCodLocal, Caracter, Código do local para a busca 
@return 	Caracter, código do Centro de Custo no campo ABS_CCUSTO
/*/
Function At160GetCC( cCodLocal )
Local cCC := ""
DEFAULT cCodLocal := ""

DbSelectArea("ABS")
ABS->( DbSetOrder( 1 ) )  // ABS_FILIAL + ABS_LOCAL
If !Empty(cCodLocal) .And. ABS->( DbSeek( xFilial("ABS")+cCodLocal ) )
	cCC := ABS->ABS_CCUSTO
EndIf

Return cCC

/*/{Protheus.doc} At160HasCC()
	Verifica se um determinado centro de custo existe na base, utiliza a filial preenchida no campo ABS_FILCC como filial
@since 		02/01/2017
@author 	josimar.assuncao
@param 		cFilAlvo, Caracter, filial para a procura do centro de custo
@param 		cCodLocal, Caracter, código do centro de custo a ser procurado
@return 	Lógico, indica se encontrou ou não o centro de custo na base
/*/
Function At160HasCC( cFilAlvo, cCodCC )
Local lRet := .F.

If Empty(cFilAlvo)
	lRet := .F.
	Help( "", 1, "AT160HASCC", , STR0047, 1, 0,,,,,,;  // "Filial para a pesquisa de centro de custo não preenchida."
							{STR0048}) // "Preencha o campo de filial [ABS_FILCC] antes do campo de código."
Else
	lRet := AtChkHasKey( "CTT", 1, xFilial("CTT",cFilAlvo)+cCodCC, .T. )
EndIf

Return lRet

/*/{Protheus.doc} At160CCF3() / At160CCRet()
	Combinação de funções para criação da janela de busca e para o retorno do conteúdo da consulta padrão
@since 		02/01/2017
@author 	josimar.assuncao
/*/
Function At160CCF3()
Local lRet 			:= .F.
Local oDlgCmp 		:= Nil
Local oPesqui 		:= Nil
Local cPesq 		:= TamSX3("CTT_CUSTO")[1]
Local oListBox 		:= Nil
Local aCmpBco 		:= {}
Local oModel 		:= FwModelActive()
Local oMdlABS 		:= oModel:GetModel("ABSMASTER")
Local cFilAlvo 		:= oMdlABS:GetValue("ABS_FILCC")
Local cCodCC 		:= ""
Local cFilBkp 		:= ""

If Empty(cFilAlvo)
	lRet := .F.
	Help( "", 1, "AT160F3CC", , STR0047, 1, 0,,,,,,;  // "Filial para a pesquisa de centro de custo não preenchida."
							{STR0049}) // "Preencha o campo de filial [ABS_FILCC] antes de usar a consulta padrão."
Else
	cFilBkp := cFilAnt
	cFilAnt := cFilAlvo

	DbSelectArea("CTT")
	CTT->( DbSetOrder(1) )  // CTT_FILIAL+CTT_CUSTO
	CTT->( DbSeek( xFilial("CTT", cFilAlvo ) ) )

	DbSelectArea("SI3")
	SI3->( DbSetOrder(1) ) // I3_FILIAL+I3_CUSTO+
	SI3->( DbSeek( xFilial("SI3", cFilAlvo ) ) )

	lRet := Conpad1( NIL, NIL, NIL, "CCU" )
	If lRet
		// copiada a expressão de retorno da consulta específica CCU
		cF3CC := If( CtbInUse(), CTT->CTT_CUSTO, SI3->I3_CUSTO )
	EndIf

	cFilAnt := cFilBkp

	CTT->( DbSeek( xFilial("CTT") ) )
	SI3->( DbSeek( xFilial("SI3") ) )
EndIf


Return lRet
//--------------------- retorno
Function At160CCRet()
Return cF3CC
