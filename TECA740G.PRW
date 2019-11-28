#INCLUDE 'PROTHEUS.CH' 
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TECA740G.CH'

Static aTFFOri := {}

//------------------------------------------------------------------------------
/*/{Protheus.doc} TECA740G

Rotina responsável por filtrar e exibir uma interface de seleção de postos para
inclusão de reforços | Recursos Humanos TFF

@author 	Fernando Alves Silva
@sample 	TECA740G() 
@type 		Function
@since		26/09/2016       
@version	P12   
/*/
//------------------------------------------------------------------------------

Function TECA740G()

Local oBrwAcessos := Nil
Local lRet		:= .T.
Local cPerg		:= "TECA740G"
Local cQuery	:= ""
Local cAliasREF	:= "TECA740GTRAB"				// Alias utilizado na Query Principal


Pergunte(cPerg,.F.)
// -----------------------------
// Parâmetros - Filtro de Dados
// -----------------------------
// MV_PAR01 - CODIGO DO CLIENTE 	
// MV_PAR02 - LOJA DO CLIENTE
// MV_PAR03 - N° DO CONTRATO
// MV_PAR04 - CODIGO DO LOCAL
// -----------------------------

dbSelectArea("TFF")
dbSelectArea("TFJ")

aInfoColumn := At740GCols()
cQuery   	:= At740GQry(aInfoColum[2])

// ----------------------
// Filtro através de F12
// ----------------------
SetKey( VK_F12 ,{|| Pergunte(cPerg,.T.), Refresh(oBrwAcessos)})

// -----------------------------------------------------------------------------------------------------------------
// Cria a tela para o Browse com as seguintes colunas:
// TFF_COD | TFF_PRODUT | B1_DESC | TFF_REFVLR | TFF_FUNCAO | RJ_DESC | TFF_ESCAL | TDW_DESC | TFF_CALEND | AC0_DESC
// -----------------------------------------------------------------------------------------------------------------
oBrwAcessos := FwMBrowse():New()	
oBrwAcessos:SetDataQuery(.T.)
oBrwAcessos:SetQuery(cQuery)
oBrwAcessos:SetAlias(cAliasREF)	
oBrwAcessos:SetMenudef( 'TECA740G' )
oBrwAcessos:SetUseFilter( .T. )
oBrwAcessos:SetFieldFilter(aInfoColumn[2]) 
oBrwAcessos:SetColumns(aInfoColumn[1])

// -------------------------------------------------------------------------
// Botão reponsável por chamar a rotina de manutenção de Reforços: TECA740G
// -------------------------------------------------------------------------
oBrwAcessos:AddButton( STR0029 , {|| T740AddRef((oBrwAcessos:cAlias)->TFF_COD, (oBrwAcessos:cAlias)->TFF_CONTRT)} ) // "Gestão de Reforços"

oBrwAcessos:DisableDetails()
oBrwAcessos:SetDescription(STR0001) // "Adição de Reforço"  
oBrwAcessos:Activate()

oBrwAcessos:DeActivate()

SetKey( VK_F12, Nil )

Return lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef

Definição do Modelo de Dados 

@author     Fernando Alves Silva
@sample     TECA740G() 
@type       Function
@since      26/09/2016       
@version    P12   
/*/
//------------------------------------------------------------------------------
Static Function ModelDef() 

// -------------------------------------------
// Objetos de Estrutura: TFJ | TFF | TW4 | T44
// ------------------------------------------- 
Local cCampo    := ""
Local oStruTFJ  := FWFormStruct( 1, 'TFJ' , {|cCampo| (AllTrim(cCampo) $ "TFJ_CODIGO|TFJ_CONTRT|TFJ_CODENT|TFJ_LOJA" )} ) 
Local oStruTFF  := FWFormStruct( 1, 'TFF' )
Local oStruTW4  := FWFormStruct( 1, 'TW4' )
Local oStruT44  := FWFormStruct( 1, 'T44' )


// ----------------------------------------
// Modelo de dados que será construído 
// ----------------------------------------
Local oModel        := Nil  

// ------------------------------
// Blocos de Pré e Pós Validação 
// ------------------------------
Local bPreVldTFF    := {|oGridModel, nLine, cAction, cIDField, xValue, xCurrentValue| Tc740GPreVld(oGridModel, nLine, cAction, cIDField, xValue, xCurrentValue) }
Local bCommit       := {|oModel| At740GCom(oModel)}
Local bPosVldTFF	:= {|oGridModel| At740PosVld (oGridModel)}

// --------------------------------
// Variáveis utilizadas no Gatilho 
// --------------------------------
Local aAuxSeg   := {}
Local aAuxTer   := {}
Local aAuxQua   := {}
Local aAuxQui   := {}
Local aAuxSex   := {}
Local aAuxSab   := {}
Local aAuxDom   := {}
Local aAuxFer   := {}

// --------------------------------------------------------------------------------------
// TFJ | Campo Virtual do nome do cliente 
// --------------------------------------------------------------------------------------
oStruTFJ:AddField(                    ; // Ord. Tipo Desc.
                    STR0023         , ; // [01]  C   Titulo do campo
                    STR0023         , ; // [02]  C   ToolTip do campo
                    'TFJ_NOME'      , ; // [03]  C   Id do Field
                    'C'             , ; // [04]  C   Tipo do campo
                    50              , ; // [05]  N   Tamanho do campo
                    0               , ; // [06]  N   Decimal do campo
                    Nil             , ; // [07]  B   Code-block de validação do campo
                    NIL             , ; // [08]  B   Code-block de validação When do campo
                    NIL             , ; // [09]  A   Lista de valores permitido do campo
                    .T.             , ; // [10]  L   Indica se o campo tem preenchimento obrigatório
                    NIL             , ; // [11]  B   Code-block de inicializacao do campo
                    NIL             , ; // [12]  L   Indica se trata-se de um campo chave
                    NIL             , ; // [13]  L   Indica se o campo pode receber valor em uma operação de update.
                    .T.             )   // [14]  L   Indica se o campo é virtual

oStruTFJ:SetProperty("TFJ_NOME" ,MODEL_FIELD_INIT, {||Posicione("SA1",1,xFilial("SA1")+TFJ->TFJ_CODENT+TFJ->TFJ_LOJA, "A1_NOME")})

// --------------------------------------------------------------------------------
// Criação do Modelo Hierárquico dos Campos de Edição
// --------------------------------------------------------------------------------
oModel := MPFormModel():New('TECA740GOK', /*Pre-Validacao*/, /*Pos-Validacao*/, bCommit ) 

oModel:AddFields('TFJ_REFER'    , /*cOwner*/    , oStruTFJ) 
oModel:AddGrid  ('TFF_RH'       , 'TFJ_REFER'   , oStruTFF ,, bPosVldTFF ,bPreVldTFF)
oModel:AddGrid  ('TW4DETAIL'    , 'TFF_RH'      , oStruTW4 ,,/*bPosVldTFF*/,bPreVldTFF)
oModel:AddGrid  ('T44DETAIL'    , 'TW4DETAIL'   , oStruT44 ,,/*bPosVldTFF*/,bPreVldTFF)

// -----------------------------
// Relacionamento das Entidades
// -----------------------------
oModel:SetRelation('TFF_RH'   , { {'TFF_FILIAL','xFilial("TFF")'}, {'TFF_CONTRT','TFJ_CONTRT'} }    , TFF->( IndexKey( 1 ) ) )
oModel:SetRelation('TW4DETAIL', { {'TW4_FILIAL','xFilial("TW4")'}, {'TW4_CODTFF','TFF_COD'   } }    , TW4->( IndexKey( 1 ) ) )
oModel:SetRelation('T44DETAIL', { {'T44_FILIAL','xFilial("T44")'}, {'T44_CODTW4','TW4_COD'   } }    , T44->( IndexKey( 1 ) ) )

// ------------------------------------------------------------------
// Bloqueio a edição dos campos que serão herdados do Posto Original
// ------------------------------------------------------------------
oStruTFF:SetProperty("TFF_ORIREF"   ,MODEL_FIELD_WHEN, {||.F.} )
oStruTFF:SetProperty("TFF_PRODUT"   ,MODEL_FIELD_WHEN, {||.F.} )
oStruTFF:SetProperty("TFF_PRCVEN"   ,MODEL_FIELD_WHEN, {||.F.} )
oStruTFF:SetProperty("TFF_FUNCAO"   ,MODEL_FIELD_WHEN, {||.T.} )
oStruTFF:SetProperty("TFF_CARGO"    ,MODEL_FIELD_WHEN, {||.F.} )
oStruTFF:SetProperty("TFF_CALEND"   ,MODEL_FIELD_WHEN, {||.F.} )
oStruTFF:SetProperty("TFF_ESCALA"   ,MODEL_FIELD_WHEN, {||.F.} )


// ----------------------------------------------------------------------------------
// TW4 | Inicializador Padrão:
// Inicio Todos os dias desmarcados devido ao posicionamento estar no Posto Original
// ----------------------------------------------------------------------------------
oStruTW4:SetProperty("TW4_SEG"      ,MODEL_FIELD_INIT,{|| .F. })
oStruTW4:SetProperty("TW4_TER"      ,MODEL_FIELD_INIT,{|| .F. })
oStruTW4:SetProperty("TW4_QUA"      ,MODEL_FIELD_INIT,{|| .F. })
oStruTW4:SetProperty("TW4_QUI"      ,MODEL_FIELD_INIT,{|| .F. })
oStruTW4:SetProperty("TW4_SEX"      ,MODEL_FIELD_INIT,{|| .F. })
oStruTW4:SetProperty("TW4_SAB"      ,MODEL_FIELD_INIT,{|| .F. })
oStruTW4:SetProperty("TW4_DOM"      ,MODEL_FIELD_INIT,{|| .F. })
oStruTW4:SetProperty("TW4_FER"      ,MODEL_FIELD_INIT,{|| .F. })


If Len(aTFFOri) > 0 
    // -------------------------------------------------------------------
    // TFF | Inicializador Padrão:
    // Inicio os campos abaixo de acordo com a herança do Posto Original 
    // -------------------------------------------------------------------

    oStruTFF:SetProperty("TFF_ORIREF"   ,MODEL_FIELD_INIT, {||aTFFOri[01] })
    oStruTFF:SetProperty("TFF_PRODUT"   ,MODEL_FIELD_INIT, {||aTFFOri[02] })
    oStruTFF:SetProperty("TFF_PRCVEN"   ,MODEL_FIELD_INIT, {||aTFFOri[03] })
    oStruTFF:SetProperty("TFF_FUNCAO"   ,MODEL_FIELD_INIT, {||aTFFOri[04] })
    oStruTFF:SetProperty("TFF_CARGO"    ,MODEL_FIELD_INIT, {||aTFFOri[05] })
    oStruTFF:SetProperty("TFF_CALEND"   ,MODEL_FIELD_INIT, {||aTFFOri[06] })
    oStruTFF:SetProperty("TFF_LOCAL"    ,MODEL_FIELD_INIT, {||aTFFOri[07] })
    oStruTFF:SetProperty("TFF_UM"       ,MODEL_FIELD_INIT, {||aTFFOri[08] })
    oStruTFF:SetProperty("TFF_CODPAI"   ,MODEL_FIELD_INIT, {||aTFFOri[09] }) 
    oStruTFF:SetProperty("TFF_ESCALA"   ,MODEL_FIELD_INIT, {||aTFFOri[10] }) 
    oStruTFF:SetProperty("TFF_CONTRT"   ,MODEL_FIELD_INIT, {||aTFFOri[11] })
    oStruTFF:SetProperty("TFF_CONREV"   ,MODEL_FIELD_INIT, {||aTFFOri[12] })
    oStruTFF:SetProperty("TFF_FILIAL"   ,MODEL_FIELD_INIT, {||aTFFOri[13] })
    oStruTFF:SetProperty("TFF_INSALU"   ,MODEL_FIELD_INIT, {||aTFFOri[14] })
    oStruTFF:SetProperty("TFF_GRAUIN"   ,MODEL_FIELD_INIT, {||aTFFOri[15] })
    oStruTFF:SetProperty("TFF_PERICU"   ,MODEL_FIELD_INIT, {||aTFFOri[16] })
    oStruTFF:SetProperty("TFF_QTDVEN"   ,MODEL_FIELD_INIT, {||1           }) // Inicializa com a quantidade padrão 1 
    
    // -------------------------------------------------------------------
    // TFF | Inicializador Padrão:
    // Inicializador dos campos Virtuais de Descrição 
    // -------------------------------------------------------------------  
    oStruTFF:SetProperty("TFF_DESCRI"   ,MODEL_FIELD_INIT,{||Posicione("SB1",1,xFilial("SB1")+aTFFOri[02], "B1_DESC"    )})
    oStruTFF:SetProperty("TFF_DCARGO"   ,MODEL_FIELD_INIT,{||Posicione("SQ3",1,xFilial("SQ3")+aTFFOri[05], "Q3_DESCSUM" )})
    oStruTFF:SetProperty("TFF_DFUNC"    ,MODEL_FIELD_INIT,{||Posicione("SRJ",1,xFilial("SRJ")+aTFFOri[04], "RJ_DESC"    )})
    oStruTFF:SetProperty("TFF_DSCALE"   ,MODEL_FIELD_INIT,{||Posicione("AC0",1,xFilial("AC0")+aTFFOri[06], "AC0_DESC"   )})
    oStruTFF:SetProperty("TFF_NOMESC"   ,MODEL_FIELD_INIT,{||Posicione("TDW",1,xFilial("TDW")+aTFFOri[10], "TDW_DESC"   )})
        
    oStruTFF:SetProperty("TFF_PERINI"   ,MODEL_FIELD_VALID, {|| AT740GVLPO("I",oModel)  } )
    oStruTFF:SetProperty("TFF_PERFIM"   ,MODEL_FIELD_VALID, {|| AT740GVLPO("F",oModel)  } )
Endif

// ----------------------------------------
// oModel | Descrição do Modelo
// ----------------------------------------
oModel:SetDescription(STR0003) // "Movimentação Ágil" 
oModel:GetModel( 'TFJ_REFER' ):SetDescription(STR0001) //"Adição de Reforço" 

// ------------------------------------------------------
// TW4 | T44 - Ativa Preenchimento Opcional do Formulário 
// ------------------------------------------------------
oModel:GetModel( 'TW4DETAIL' ):SetOptional( .T. )
oModel:GetModel( 'T44DETAIL' ):SetOptional( .T. )


// ---------------------------------------------------------------------------------------------------------
// TW4 | T44 - Limita a quantidade da Grid. Obs.: Foi utilizado uma Grid por questões estéticas e funcionais.
// ---------------------------------------------------------------------------------------------------------
oModel:GetModel( 'TW4DETAIL' ):SetMaxLine(1)
oModel:GetModel( 'T44DETAIL' ):SetMaxLine(4)

// ------------------------------------------------------------
// TW4 | T44 - Remove Obrigatoriedade de Preenchimento dos Campos
// ------------------------------------------------------------
oStruTW4:SetProperty("*"            , MODEL_FIELD_OBRIGAT, .F. )
oStruT44:SetProperty("*"            , MODEL_FIELD_OBRIGAT, .F. )

// ------------------------------------------------------------
// TFF - Remove Obrigatoriedade de Preenchimento dos Campos
// ------------------------------------------------------------
oStruTFF:SetProperty("TFF_CODPAI"   , MODEL_FIELD_OBRIGAT, .F. )
oStruTFF:SetProperty("TFF_LOCAL"    , MODEL_FIELD_OBRIGAT, .F. )
oStruTFF:SetProperty("TFF_PERFIM"   , MODEL_FIELD_OBRIGAT, .F. )

// -------------------------------------------------------------
// Desabilita a Edição de Todos os Campos da Estrutura oStruTFJ
// -------------------------------------------------------------
oStruTFJ:SetProperty("*", MODEL_FIELD_WHEN, {||.F.})

// -------------------------------------------------------------------------------------------------
// Gatilhos utilizados na inteligência de Preenchimento dos Campos Relacionados aos dias da Semana.
// -------------------------------------------------------------------------------------------------
aAuxSeg := FwStruTrigger("TW4_MODO","TW4_SEG","Gat740G(M->TW4_MODO,'Seg')",.F.,Nil,Nil,Nil)
oStruTW4:AddTrigger(aAuxSeg[1],aAuxSeg[2],aAuxSeg[3],aAuxSeg[4])

aAuxTer := FwStruTrigger("TW4_MODO","TW4_TER","Gat740G(M->TW4_MODO,'Ter')",.F.,Nil,Nil,Nil)
oStruTW4:AddTrigger(aAuxTer[1],aAuxTer[2],aAuxTer[3],aAuxTer[4])

aAuxQua := FwStruTrigger("TW4_MODO","TW4_QUA","Gat740G(M->TW4_MODO,'Qua')",.F.,Nil,Nil,Nil)
oStruTW4:AddTrigger(aAuxQua[1],aAuxQua[2],aAuxQua[3],aAuxQua[4])

aAuxQui := FwStruTrigger("TW4_MODO","TW4_QUI","Gat740G(M->TW4_MODO,'Qui')",.F.,Nil,Nil,Nil)
oStruTW4:AddTrigger(aAuxQui[1],aAuxQui[2],aAuxQui[3],aAuxQui[4])

aAuxSex := FwStruTrigger("TW4_MODO","TW4_SEX","Gat740G(M->TW4_MODO,'Sex')",.F.,Nil,Nil,Nil)
oStruTW4:AddTrigger(aAuxSex[1],aAuxSex[2],aAuxSex[3],aAuxSex[4])

aAuxSab := FwStruTrigger("TW4_MODO","TW4_SAB","Gat740G(M->TW4_MODO,'Sab')",.F.,Nil,Nil,Nil)
oStruTW4:AddTrigger(aAuxSab[1],aAuxSab[2],aAuxSab[3],aAuxSab[4])

aAuxDom := FwStruTrigger("TW4_MODO","TW4_DOM","Gat740G(M->TW4_MODO,'Dom')",.F.,Nil,Nil,Nil)
oStruTW4:AddTrigger(aAuxDom[1],aAuxDom[2],aAuxDom[3],aAuxDom[4])

aAuxFer := FwStruTrigger("TW4_MODO","TW4_FER","Gat740G(M->TW4_MODO,'Fer')",.F.,Nil,Nil,Nil)
oStruTW4:AddTrigger(aAuxFer[1],aAuxFer[2],aAuxFer[3],aAuxFer[4])

// ----------------------------------------------------------------------------------------
// Legenda utilizada para identificar o Tipo de Posto | Original[VERMELHO] | Reforço[VERDE]
// ----------------------------------------------------------------------------------------
oStruTFF:AddField("","","TFF_LEG","BT",1,0,{||At740GGetLE()},,,.F.,{||At740GLeg(1)},,,.T.,) 
oStruTFF:SetProperty("TFF_LEG", MODEL_FIELD_WHEN, {||.T.})

// ----------------------------------------------------------------------------------------------------------------------------
// Filtro o TFF_RH para apresentar apenas o Item original e os reforços adicionados exclusivamente ao item selecionado
// ----------------------------------------------------------------------------------------------------------------------------
If Len(aTFFOri) > 0
    oModel:GetModel( 'TFF_RH' ):SetLoadFilter( { { 'TFF_COD', aTFFOri[1] }, { 'TFF_ORIREF', aTFFOri[1],, MVC_LOADFILTER_OR } } )
EndIf

oModel:SetActivate( {|oModel| InitDados( oModel ) } )

Return oModel


//------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef

Definição da Interface Visual do Modelo

@author 	Fernando Alves Silva
@sample 	TECA740G() 
@type 		Function
@since		26/09/2016       
@version	P12   
/*/
//------------------------------------------------------------------------------

Static Function ViewDef() 

Local oModel 	:= FWLoadModel( 'TECA740G' )
Local cCampo	:= ""
// -------------------------------------------
// Objetos de Estrutura: TFJ | TFF | TW4 | T44
// ------------------------------------------- 
Local oStruTFJ 	:= FWFormStruct( 2, 'TFJ', {|cCampo| (AllTrim(cCampo) $ "TFJ_CODIGO|TFJ_CONTRT|TFJ_CODENT|TFJ_LOJA" )} ) 
Local oStruTFF 	:= FWFormStruct( 2, 'TFF' )
Local oStruTW4 	:= FWFormStruct( 2, 'TW4', {|cCampo| !(AllTrim(cCampo) $ "TW4_COD|TW4_CODTFF"   )} )
Local oStruT44	:= FWFormStruct( 2, 'T44', {|cCampo| !(AllTrim(cCampo) $ "T44_CODTW4")} )


// ----------------------------------------
// Objeto de Interface Gráfica do Modelo
// ---------------------------------------- 
Local oView		:= Nil 
Local cOrdem   := '00'

// -----------------------
// Pega a última ordem
/// ------------------------
aEval( oStruTFJ:aFields, { |aX| cOrdem := IIf( aX[MVC_VIEW_ORDEM] > cOrdem, aX[MVC_VIEW_ORDEM] , cOrdem )  } )
cOrder := Soma1( cOrdem )

// --------------------------------------------------------------------------------------
// TFJ | Campo Virtual do nome do cliente 
// --------------------------------------------------------------------------------------
oStruTFJ:AddField( 					  ;	// Ord. Tipo Desc.
					'TFJ_NOME'		, ; // [01]  C   Nome do Campo
					cOrder          , ; // [02]  C   Ordem
					STR0023      	, ; // [03]  C   Titulo do campo	#"Nome"
					STR0023        	, ; // [04]  C   Descricao do campo	#"Nome"
					{ STR0024 }    	, ; // [05]  A   Array com Help		#"Nome da entidade"
					'C'             , ; // [06]  C   Tipo do campo
					'@!'         	, ; // [07]  C   Picture
					NIL            	, ; // [08]  B   Bloco de Picture Var
					''             	, ; // [09]  C   Consulta F3
					.T.            	, ; // [10]  L   Indica se o campo é alteravel
					NIL            	, ; // [11]  C   Pasta do campo
					NIL            	, ; // [12]  C   Agrupamento do campo
					NIL            	, ; // [13]  A   Lista de valores permitido do campo (Combo)
					NIL            	, ; // [14]  N   Tamanho maximo da maior opção do combo
					NIL            	, ; // [15]  C   Inicializador de Browse
					.T.            	, ; // [16]  L   Indica se o campo é virtual
					NIL            	, ; // [17]  C   Picture Variavel
					NIL            	)   // [18]  L   Indica pulo de linha após o campo

oView:= FWFormView():New()
oView:SetModel( oModel )

// ----------------------------------------
// Definições Visuais da Rotina 
// ----------------------------------------
oView:AddField( 'VIEW_TFJ' , oStruTFJ, 'TFJ_REFER' ) 
oView:AddGrid ( 'VIEW_TFF' , oStruTFF, 'TFF_RH'    )   
oView:AddGrid ( 'VIEW_TW4' , oStruTW4, 'TW4DETAIL' )
oView:AddGrid ( 'VIEW_T44' , oStruT44, 'T44DETAIL' )

oView:CreateHorizontalBox	( 'SUPERIOR'   , 020 )  
oView:CreateHorizontalBox	( 'INFERIOR1'  , 040 ) 
oView:CreateHorizontalBox	( 'INFERIOR2'  , 040 ) 
oView:CreateVerticalBox		( 'ESQUERDA'   , 060 , 'INFERIOR2' )
oView:CreateVerticalBox		( 'ESPACO'     , 001 , 'INFERIOR2' ) 
oView:CreateVerticalBox		( 'DIREITA'    , 039 , 'INFERIOR2' )

oView:SetOwnerView( 'VIEW_TFJ', 'SUPERIOR'   ) 
oView:SetOwnerView( 'VIEW_TFF', 'INFERIOR1'  )  
oView:SetOwnerView( 'VIEW_TW4', 'ESQUERDA'   )
oView:SetOwnerView( 'VIEW_T44', 'DIREITA'    )

// -------------------------------------------------------------------------
// Botão reponsável por chamar a rotina de manutenção de Reforços: TECA740G
// -------------------------------------------------------------------------
oView:AddUserButton(STR0031,"",{|| A740ENCPOST(TFJ->TFJ_CONTRT,TFJ->TFJ_CONREV, TFJ->TFJ_PROPOS, oView, oModel) },,,{MODEL_OPERATION_UPDATE})	

// ------------------------------------------------------------------
// FWFormViewStruct | Criação de títulos para as estruturas do Form. 
// ------------------------------------------------------------------
oView:EnableTitleView('VIEW_TFJ' , STR0019 )	// "Orçamento"
oView:EnableTitleView('VIEW_TFF' , STR0020 )	// "Recursos Humanos"
oView:EnableTitleView('VIEW_TW4' , STR0021 )	// "Dias de Execução de Serviços"
oView:EnableTitleView('VIEW_T44' , STR0022 )	// "Horários"

// -----------------------------------------------------------
// TFF_ITEM | Definição de campo sequencial de auto incremento 
// -----------------------------------------------------------
oView:AddIncrementField('VIEW_TFF' , 'TFF_ITEM' )

// -----------------------------------------------------------
// T44_ITEM | Definição de campo sequencial de auto incremento 
// -----------------------------------------------------------
oView:AddIncrementField( "VIEW_T44", "T44_SEQUEN" )

// ----------------------------------------------------------
// oStruTFF | Remoção da visualização dos campos da esturura  
// ----------------------------------------------------------
SX3->(dbGoTop())
SX3->(dbSetOrder(1))	//X3_ARQUIVO+X3_ORDEM

If SX3->(dbSeek("TFF"))	
	While SX3->(!Eof()) .And. SX3->X3_ARQUIVO == "TFF"
		If !(AllTrim(SX3->X3_CAMPO) $ "TFF_COD|TFF_ITEM|TFF_PRODUT|TFF_DESCRI|TFF_QTDVEN|TFF_LOCAL|TFF_PERINI|TFF_PERFIM|TFF_CARGO|TFF_DCARGO|TFF_FUNCAO|TFF_DFUNC |TFF_ESCALA|TFF_NOMESC|TFF_CALEND|TFF_DSCALE|TFF_OBS"	) 		
			oStruTFF:RemoveField(AllTrim(SX3->X3_CAMPO))	
		EndIf
		SX3->(dbSkip())
	EndDo
EndIf

// --------------------------------------------------------------------------------------
// TFF_LEG | Campo Virtual para identificar Posto Original[VERMELHO] e Reforço[VERDE] 
// --------------------------------------------------------------------------------------
oStruTFF:AddField("TFF_LEG","01","","",{},"BT","",Nil,Nil,.T.,"",Nil,Nil,Nil,Nil,.T.,Nil) 

Return oView
 

//------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At740GCols

Função responsável por criar as colunas e aplicar os filtros para adição de Reforço

@author 	Fernando Alves Silva
@sample 	At740GCols() 
@type 		Static Function
@since		26/09/2016       
@version	P12   

@return	aInfoColumn - [aColumns - Colunas para o browse, aFiltros - Descrição dos filtros do Browse]
/*/
//------------------------------------------------------------------------------------------------------
Static Function At740GCols()

Local nI		:= 0 
Local aColumns	:= {}
Local aFiltros	:= {}
Local cCampo	:= ''
Local nLinha	:= 0
Local aCampos	:= { "TFJ_CODIGO", "TFF_COD", "TFF_CONTRT", "TFF_CONREV", "TFF_LOCAL", "ABS_DESCRI", "TFF_PRODUT", "B1_DESC", "TFF_REFVLR" ,"TFF_FUNCAO", "RJ_DESC", "TFF_ESCAL", "TDW_DESC" }

dbSelectArea("SX3")
SX3->(DbSetOrder(2))	//X3_CAMPO

For nI:=1 To Len(aCampos)

	If SX3->(dbSeek(aCampos[nI]))
	
		cCampo := AllTrim(SX3->X3_CAMPO)
		
		AAdd(aColumns,FWBrwColumn():New())
		nLinha := Len(aColumns)
	   	aColumns[nLinha]:SetType(SX3->X3_TIPO)
	   	If aCampos[nI] = "TFJ_CODIGO" 
	   		aColumns[nLinha]:SetTitle(STR0034) //"Código Orçamento"
	   	Elseif aCampos[nI] = "TFF_COD" 
	   		aColumns[nLinha]:SetTitle(STR0035) //"Código Posto"
	   	Else
	   		aColumns[nLinha]:SetTitle(X3Titulo())
	   	Endif
		aColumns[nLinha]:SetSize(SX3->X3_TAMANHO)
		aColumns[nLinha]:SetDecimal(SX3->X3_DECIMAL)		
		aColumns[nLinha]:SetData(&("{||" + cCampo + "}"))
		
		aadd(aFiltros,{cCampo,X3Titulo(),SX3->X3_TIPO,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_PICTURE})
		
	EndIf
	
Next nI

SX3->(dbCloseArea())

Return{aColumns, aFiltros}


//------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At740GQry

Query com os dados filtratos pelos parâmetros iniciais [F12]

@author 	Fernando Alves Silva
@sample 	At740GQry() 
@type 		Static Function
@since		26/09/2016       
@version	P12   
	
@return	cQuery - Query com as informações do Posto que receberá o reforço
/*/
//------------------------------------------------------------------------------------------------------
Static Function At740GQry(aColumns)

Local cQuery := ""
Local nI := 1

cQuery += "SELECT "
For nI := 1 To Len(aColumns)
    If aColumns[nI][1]=='TFF_REFVLR'
        cQuery += " "+aColumns[nI][1]+","
    Else
        cQuery += " COALESCE("+aColumns[nI][1]+",' ') AS "+aColumns[nI][1]+","
    Endif    
Next nI

// -----------------------------
// MV_PAR01 - CODIGO DO CLIENTE 	
// MV_PAR02 - LOJA DO CLIENTE
// MV_PAR03 - N° DO CONTRATO
// MV_PAR04 - CODIGO DO LOCAL
// -----------------------------

cQuery := substr(cQuery, 1, Len(cQuery)-1)
cQuery += " , MAX(TFF_CONREV) TFL_CONREV				" + CRLF
cQuery += " FROM " + RetSqlName("TFJ") + 	" TFJ		" + CRLF

cQuery += " JOIN " + RetSqlName("TFF") + " TFF 			" + CRLF
cQuery += "	ON TFJ_FILIAL	= '" + xFilial("TFJ") + "'	" + CRLF
cQuery += "	AND TFJ_CONTRT		= TFF_CONTRT 			" + CRLF
cQuery += "	AND TFJ_CONREV		= TFF_CONREV 			" + CRLF
cQuery += "	AND TFF_CONTRT <> '' 						" + CRLF
cQuery += "	AND TFF_COBCTR = '1'		 				" + CRLF
cQuery += "	AND TFJ.TFJ_STATUS = '1' 					" + CRLF
If !Empty(MV_PAR03)
	cQuery += "AND TFF_CONTRT	= '"+ MV_PAR03 +	"'	" + CRLF 
Else
	cQuery += "AND TFF_CONTRT <> ''						" + CRLF 
EndIf
If !Empty(MV_PAR04)
	cQuery += "AND TFF_LOCAL	= '"+ MV_PAR04 +	"'	" + CRLF
Else
	cQuery += "AND TFF_LOCAL <> ''						" + CRLF  
EndIf
cQuery += "	AND TFF.D_E_L_E_T_	= ' '  					" + CRLF

cQuery += "LEFT JOIN " + RetSqlName("ABS") + " ABS		" + CRLF
cQuery += "	ON  ABS_FILIAL = '" + xFilial("ABS")  + "'	" + CRLF
cQuery += "	AND ABS_LOCAL = TFF_LOCAL	 				" + CRLF
cQuery += "	AND ABS.D_E_L_E_T_ = ' '					" + CRLF

cQuery += "LEFT JOIN " + RetSqlName("SB1") + " SB1		" + CRLF
cQuery += "	ON  B1_FILIAL = '" + xFilial("SB1")  + "'	" + CRLF
cQuery += "	AND B1_COD = TFF_PRODUT						" + CRLF
cQuery += "	AND SB1.D_E_L_E_T_ = ' ' 					" + CRLF

cQuery += "LEFT JOIN " + RetSqlName("SRJ") + " SRJ		" + CRLF
cQuery += "	ON  RJ_FILIAL = '" + xFilial("SRJ")  + "'	" + CRLF
cQuery += "	AND RJ_FUNCAO = TFF_FUNCAO 					" + CRLF
cQuery += "	AND SRJ.D_E_L_E_T_ = ' '					" + CRLF

cQuery += "LEFT JOIN " + RetSqlName("TDW") + " TDW 		" + CRLF
cQuery += "	ON  TDW_FILIAL = '" + xFilial("TDW") + "'	" + CRLF
cQuery += "	AND TDW_COD = TFF_ESCALA					" + CRLF
cQuery += "	AND TDW.D_E_L_E_T_ = ' ' 					" + CRLF

If !Empty(MV_PAR01)
	cQuery += "WHERE TFJ_CODENT	= '"	+ MV_PAR01 +	"' 	" + CRLF
Else
	cQuery += "AND TFJ_CODENT <> ''							" + CRLF
Endif

If !Empty(MV_PAR02)
	cQuery += "AND TFJ_LOJA		= '"	+ MV_PAR02 +	"' 	" + CRLF 
Else
	cQuery += "AND TFJ_LOJA <> ''							" + CRLF
Endif

cQuery += "AND TFJ_CONTRT <> ''      						" + CRLF
cQuery += "AND TFJ_STATUS = '1'      						" + CRLF
	
cQuery += "AND TFF_ORIREF   = ' '							" + CRLF
cQuery += "AND TFF_CODSUB   = ' '							" + CRLF
cQuery += "AND TFJ.D_E_L_E_T_ = ' '							" + CRLF

cQuery += "GROUP BY "
For nI := 1 To Len(aColumns)
	cQuery += " "+aColumns[nI][1]+","
Next nI

cQuery := SubStr(cQuery, 1, Len(cQuery)-1)

cQuery := ChangeQuery(cQuery) 

Return(cQuery)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} T740AddRef

Chamada para Adição de Reforço

@author 	Fernando Alves Silva
@sample 	T740AddRef() 
@type 		Static Function
@since		26/09/2016       
@version	P12   

/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function T740AddRef(cCodTFF, cContra)

Local nPercReducao  := 0               
Local aArea					:= GetArea()
Local lOk						:= .T.
Local cRev					:= CnUltRev(cContra)

DbSelectArea("CN9")
CN9->(DbSetOrder(1))	//CN9_FILIAL+CN9_NUMERO+CN9_REVISA
If CN9->(DbSeek(xFilial("CN9") + cContra + cRev)) .And. CN9->CN9_SITUAC <> "05"
	Help( ,, 'T740AddRef',,"Não é possível incluir um reforço para este item, pois o mesmo não está com o contrato vigente.", 1, 0 )	//"Não é possível incluir um reforço para este item, pois o mesmo não possui Valor de Reforço cadastrado."
	lOk := .F.
Endif

DbSelectArea("TFJ")
TFJ->(DbSetOrder(5))	//TFJ_FILIAL+TFJ_CONTRT+TFJ_CONREV

If lOk .And. TFJ->(DbSeek(xFilial("TFJ") + cContra + cRev))
	
	DbSelectArea("TFF")
	TFF->(DbSetOrder(1))	//TFF_FILIAL+TFF_COD
	
	If TFF->(DbSeek(xFilial("TFF")+cCodTFF))
		
		// ---------------------------------------
		// Guardo as Informações do Item Original 
		// ---------------------------------------
		aTFFOri := {TFF->TFF_COD 	,; // [01]
					TFF->TFF_PRODUT ,; // [02]
					TFF->TFF_REFVLR ,; // [03]
					TFF->TFF_FUNCAO ,; // [04]
					TFF->TFF_CARGO 	,; // [05]
					TFF->TFF_CALEND	,; // [06]
					TFF->TFF_LOCAL	,; // [07]
					TFF->TFF_UM			,; // [08]
					TFF->TFF_CODPAI	,; // [09]
					TFF->TFF_ESCALA	,; // [10]
					TFF->TFF_CONTRT	,; // [11]
					TFF->TFF_CONREV	,; // [12]
					TFF->TFF_FILIAL	,; // [13]
					TFF->TFF_INSALU	,; // [14]	
					TFF->TFF_GRAUIN	,; // [15]
					TFF->TFF_PERICU	}  // [16]
					
								
		If TFF->TFF_REFVLR > 0			
			FWExecView(Upper(STR0029),"VIEWDEF.TECA740G",MODEL_OPERATION_UPDATE,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,nPercReducao) // Gestão de Reforços
		Else
			Help( ,, 'T740AddRef',,STR0018, 1, 0 )	//"Não é possível incluir um reforço para este item, pois o mesmo não possui Valor de Reforço cadastrado."
		EndIf	
	EndIf
	
EndIf

RestArea( aArea )

Return(.T.)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Refresh

Atualiza o browse após confirmação do Filtro [F12]

@author 	Fernando Alves Silva
@sample 	Refresh() 
@type 		Static Function
@since		26/09/2016       
@version	P12   

/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Refresh(oBrowse)

Local aInfoColumn := At740GCols()
Local cQuery   	  := At740GQry(aInfoColum[2])	

oBrowse:SetQuery(cQuery)
oBrowse:Refresh( .T. )
oBrowse:ExecuteFilter()

Return


//--------------------------------------------------------------------------------------
/*/{Protheus.doc}  InitDados
@author  	Fernando Alves Silva
@since 	  	26/09/2016
@version	P12
@return 	Nil
/*/
//---------------------------------------------------------------------------------------

Static Function InitDados(oModel)

Local oModelTFF := oModel:GetModel('TFF_RH')
Local oStruTFF	:= oModel:GetModel('TFF_RH'):GetStruct()
Local oStruTW4	:= oModel:GetModel('TW4DETAIL'):GetStruct()

// ---------------------------------------------------------
// TW4 | Inicializador Padrão:
// Inicio Todos os dias Marcados para itens de Reforço
// ---------------------------------------------------------
oStruTW4:SetProperty("TW4_MODO"		, MODEL_FIELD_INIT,{|| '1'								})
oStruTW4:SetProperty("TW4_SEG"		, MODEL_FIELD_INIT,{|| .T.								})
oStruTW4:SetProperty("TW4_TER"		, MODEL_FIELD_INIT,{|| .T.								})
oStruTW4:SetProperty("TW4_QUA"		, MODEL_FIELD_INIT,{|| .T.								})
oStruTW4:SetProperty("TW4_QUI"		, MODEL_FIELD_INIT,{|| .T.								})
oStruTW4:SetProperty("TW4_SEX"		, MODEL_FIELD_INIT,{|| .T.								})
oStruTW4:SetProperty("TW4_SAB"		, MODEL_FIELD_INIT,{|| .T.								})
oStruTW4:SetProperty("TW4_DOM"		, MODEL_FIELD_INIT,{|| .T.								})
oStruTW4:SetProperty("TW4_FER"		, MODEL_FIELD_INIT,{|| .T.								})

// ------------------------------------------------------------------
// Inicializo a Legenda como Verde (Reforço) para os Novos Itens 
// ------------------------------------------------------------------
oStruTFF:SetProperty("TFF_LEG"		,MODEL_FIELD_INIT, {|| "BR_VERDE" })
oStruTFF:SetProperty("TFF_COBCTR"	,MODEL_FIELD_INIT, {|| "2"}) // Indica que a Cobrança será realizada via pedido de venda fora do contrato.

Return Nil 


//----------------------------------------------------------------
/*/{Protheus.doc}  At740GGetLE			   
Cria as informações referentes a legenda do Grid [TFF] .

@author 	Fernando Alves Silva
@since		26/09/2016       
@version	P12   

@return 	lRet: Retorna .T. quando a criação foi bem sucedida.
/*/
//----------------------------------------------------------------
Function At740GGetLE()

Local oLegenda := FwLegend():New()
     
oLegenda:Add( "", "BR_VERMELHO" , STR0004) 	// "Posto Original"	
oLegenda:Add( "", "BR_VERDE"  	, STR0005) 	// "Posto Reforço"	
oLegenda:Add( "", "BR_AMARELO" 	, STR0006) 	// "Posto Reforço Alocado"	
oLegenda:Add( "", "BR_PRETO" 	, STR0007) 	// "Posto Reforço Finalizado"
oLegenda:View()
DelClassIntf()

Return(.T.)


//----------------------------------------------------------------
/*/{Protheus.doc}  At740ELeg
Atribui a cor na legenda, conforme a necessidade.

@author  	Fernando Alves Silva
@since 	  	26/09/2016
@version	P12

@return 	cRet: Cor da legenda conforme a configuração do efetivo
/*/
//-----------------------------------------------------------------
Function At740GLeg()

Local cRet	 	:= ""

If Len(aTFFOri) > 0
	If TFF->TFF_COD == aTFFOri[1]
		cRet := "BR_VERMELHO"
	Else
		If AT740GALOC(TFF->TFF_COD, TFF->TFF_PERINI, TFF->TFF_PERFIM)
			cRet := "BR_AMARELO"
		ElseIf !Empty(TFF->TFF_PERFIM) .And. TFF->TFF_PERFIM < dDataBase .OR. TFF->TFF_ENCE == "1"
			cRet := "BR_PRETO"
		Else
			cRet := "BR_VERDE"
		EndIf
	EndIf
EndIf

Return(cRet)


//--------------------------------------------------------------------------------------
/*/{Protheus.doc}  Tc740GPreVld
Função de Pré-Validação do Modelo [bPreVldTFF]

@author  	Fernando Alves Silva
@since 	  	26/09/2016
@version	P12

@return 	lRET
/*/
//---------------------------------------------------------------------------------------
Static Function Tc740GPreVld(oGridModel, nLine, cAction, cIDField, xValue, xCurrentValue)

Local lRet		:= .T.
Local oModel	:= FwModelActive()
Local oModelTFF	:= oModel:GetModel("TFF_RH")
Local oModelTW4	:= oModel:GetModel("TW4DETAIL")
Local oModelT44	:= oModel:GetModel("T44DETAIL")
Local oStruTFF  := oModel:getModel("TFF_RH"):GetStruct()
Local oStruTW4	:= oModel:GetModel("TW4DETAIL"):GetStruct()
Local oStruT44	:= oModel:GetModel("T44DETAIL"):GetStruct()
Local aAreaABQ	:= ABQ->(GetArea())

// --------------------------------------------------------------------
// AÇÃO [DELETE] - Bloqueio de exclusão do posto original.
// --------------------------------------------------------------------
If cAction == "DELETE"
  If  oModelTFF:GetValue("TFF_COD") == aTFFOri[1]
	  Help( ,, 'Tc740GPreVld',, STR0026, 1, 0 ) //"Não é permitido excluir o posto original."
	  lRet := .F.
    ElseIf oModelTFF:GetValue("TFF_LEG") == "BR_AMARELO" //posto alocado
  	  Help(,, "Tc740GPreVld",,STR0027,1,0,,,,,,{STR0028})//STR0027 - "Não é permitido excluir posto alocado" 
	  lRet := .F.                                        //STR0028 - "Recolha o posto pela rotina de movimentação de atendentes"
	ElseIf oModelTFF:GetValue("TFF_LEG") == "BR_PRETO" //posto finalizado
  	  Help( ,, 'Tc740GPreVld',, STR0030, 1, 0 )//STR0027 - "Não é permitido excluir posto finalizado" 
	  lRet := .F.										 
  Endif
EndIf

// --------------------------------------------------------------------
// AÇÃO [CANSETVALUE] - Bloqueio Totalmente a Edição do Posto Original
// --------------------------------------------------------------------
If AllTrim(cAction) == "CANSETVALUE" 
	If oModelTFF:GetValue("TFF_LEG") == "BR_PRETO" //posto finalizado
		lRet := .F.
	Endif
	// -------------------------------------------------------------------------------------------------------------------------------------------
	// 1- Não permite alterar o item Original | 2 - Não Permite Alteração de Itens Finalizados | 3 - Não Permite Alteração de Itens com Alocação
	// -------------------------------------------------------------------------------------------------------------------------------------------
	If Len(aTFFOri) > 0
	
		If  oModelTFF:GetValue("TFF_COD") == aTFFOri[1] 																			.Or. ; 	// 1
			(!Empty(oModelTFF:GetValue("TFF_PERFIM")) .And. oModelTFF:GetValue("TFF_PERFIM") < dDataBase) 							.Or. ;	// 2
			AT740GALOC(oModelTFF:GetValue("TFF_COD"), oModelTFF:GetValue("TFF_PERINI"), oModelTFF:GetValue("TFF_PERFIM")) 				  	// 3
			lRet       := .F.
		EndIf
	EndIf
	
		
	// -------------------------------------------------------------------------------------------------------------------------------------------
	// Habilita dias de execução e horários para a escala de reforço
	// -------------------------------------------------------------------------------------------------------------------------------------------
	oStruT44:SetProperty("T44_SEQUEN" 	,MODEL_FIELD_WHEN, {||.T.} )
	oStruT44:SetProperty("T44_HORAIN" 	,MODEL_FIELD_WHEN, {||.T.} )
	oStruT44:SetProperty("T44_HORAFI" 	,MODEL_FIELD_WHEN, {||.T.} )
		
 	If  oModelTW4:GetValue("TW4_MODO") <> '4' 	
		oStruTW4:SetProperty("TW4_SEG" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruTW4:SetProperty("TW4_TER" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruTW4:SetProperty("TW4_QUA" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruTW4:SetProperty("TW4_QUI" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruTW4:SetProperty("TW4_SEX" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruTW4:SetProperty("TW4_SAB" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruTW4:SetProperty("TW4_DOM" 	,MODEL_FIELD_WHEN, {||.F.} )
		oStruTW4:SetProperty("TW4_FER" 	,MODEL_FIELD_WHEN, {||.F.} )
	EndIf
	
	oModel:LoadValue("TW4DETAIL", "TW4_FILIAL", oModelTFF:GetValue("TFF_FILIAL"))
	oModel:LoadValue("TW4DETAIL", "TW4_CODTFF", oModelTFF:GetValue("TFF_COD"   ))

    // -------------------------------------------------------------------------------------------------------------------------------------------
    //Habilita data final pois em cadastro de contrato recorrente este campo é de preenchimento automático
    // para o reforço, é preciso informar a data final
    // -------------------------------------------------------------------------------------------------------------------------------------------
    If lRet
        oStruTFF:SetProperty("TFF_PERFIM"  ,MODEL_FIELD_WHEN, {||.T.} )
    EndIf
EndIf


RestArea(aAreaABQ)

Return lRet


//--------------------------------------------------------------------------------------
/*/{Protheus.doc}  Gat740G

Função do Gatilho utilizada para para determinar a marcação dos dias da Semana.

@author  	Fernando Alves Silva
@since 	  	26/09/2016
@version	P12
@return 	lRet
/*/
//---------------------------------------------------------------------------------------

Function Gat740G(cModo,cDia)

Local lRet 		:= .F.
Local i			:= 0
Local aDias 	:= {"Seg", "Ter", "Qua", "Qui", "Sex"}	//Arrays criadas separadamente para que não haja problema ao alterar ordem em campos pelo dicionário
Local aSDF		:= {"Sab", "Dom", "Fer"}				
Local oModel   	:= FwModelActive()
Local oStruTW4	:= oModel:GetModel('TW4DETAIL'):GetStruct()

// -----------------------------------------------------------------------------
// Ativo a Edição dos Campos TW4 para evitar critica de validação no Gatilho
// -----------------------------------------------------------------------------
For i := 1 to Len(aDias)
	oStruTW4:SetProperty("TW4_" + UPPER(aDias[i]) 	,MODEL_FIELD_WHEN, {||.T.} )
Next i 

For i := 1 to Len(aSDF)
	oStruTW4:SetProperty("TW4_" + UPPER(aSDF[i]) 	,MODEL_FIELD_WHEN, {||.T.} )
Next i 

Do Case

	// --------------------------------
	// TW4_MODO = '1' | Todos dos Dias
	// --------------------------------
	Case cModo == "1"

		For i := 1 To Len(aDias)
			If cDia == aDias[i]  
				lRet:= .T.
			EndIf 	
		Next i
		For i := 1 To Len(aSDF)
			If cDia == aSDF[i]  
				lRet:= .T.
			EndIf 	
		Next i
		

	// --------------------------------
	// TW4_MODO = '2' | Dias da Semana
	// --------------------------------			
	Case cModo == "2"
		
		If cDia $ (aDias[1] + "|" + aDias[2] + "|" + aDias[3] + "|" + aDias[4] + "|" + aDias[5])  
			lRet:= .T.
		Else
			lRet:= .F.	
		EndIf 	
	
	// --------------------------------
	// TW4_MODO = '3' | SDF
	// --------------------------------
	Case cModo == "3"
	
		If cDia $ (aSDF[1] + "|" + aSDF[2] + "|" + aSDF[3])  
			lRet:= .T.
		Else
			lRet:= .F.	
		EndIf 	
	
	// ---------------------------------
	// TW4_MODO = '4' | Dias Específicos
	// ---------------------------------
	OtherWise

		For i := 1 To Len(aDias)
			If cDia == aDias[i]  
				lRet:= .F.
			EndIf 	
		Next i
		For i := 1 To Len(aSDF)
			If cDia == aSDF[i]  
				lRet:= .F.
			EndIf 	
		Next i
		
EndCase
	
Return lRet


//--------------------------------------------------------------------------------------
/*/{Protheus.doc}  AT740GVLPO

Validação de Campos do Modelo

@author  	Fernando Alves Silva
@since 	  	26/09/2016
@version	P12

@return 	lRET
/*/
//---------------------------------------------------------------------------------------
FUNCTION AT740GVLPO(cID, oModel)

Local cTurno	:= ""
Local cEscala	:= ""
Local lRet		:= .T.
Local oMdlTFF 	:= oModel:GetModel("TFF_RH")
Local aAreaTFL	:= TFL->(GetArea())

Do Case
	
	// --------------
	// TFF_PERINI
	// --------------		
	Case cID == 'I'	
		DbSelectArea("TFL")
		TFL->(DbSetOrder(1))	//TFL_FILIAL+TFL_CODIGO
		If DbSeek(xFilial("TFL")+aTFFOri[9])
 			If M->TFF_PERINI < TFL->TFL_DTINI
				Help( ,, 'AT740GVLPO',, STR0015 + DtoC(TFL->TFL_DTINI)+")", 1, 0 ) // "A data informada é menor que a data do Inicial Local de Antendimento("
				lRet := .F.
			
			ElseIf M->TFF_PERINI > TFL->TFL_DTFIM
				Help( ,, 'AT740GVLPO',, STR0016 + DtoC(TFL->TFL_DTFIM)+")", 1, 0 ) // "Data inválida! A data informada é maior que a data Final do Local de Antendimento("
				lRet := .F.			
			Else 
				If M->TFF_PERINI < dDataBase
					Help( ,, 'AT740GVLPO',,STR0017 , 1, 0 ) // "Data inválida! A Data informado é anterior à Data atual."
					lRet := .F.				
				Else
					If !Empty(oMdlTFF:GetValue("TFF_PERFIM")) .And. M->TFF_PERINI > oMdlTFF:GetValue("TFF_PERFIM")
						Help( ,, 'AT740GVLPO',,STR0010 , 1, 0 ) // "Data inválida! A data inicial é maior que a data final."
						lRet := .F.
					EndIf
				EndIf
			EndIf
		Endif
	
	// --------------
	// TFF_PERFIM
	// --------------	
	Case cID == 'F'
		
		If !Empty(M->TFF_PERFIM)
			DbSelectArea("TFL")
			TFL->(DbSetOrder(1))	//TFL_FILIAL+TFL_CODIGO
			If DbSeek(xFilial("TFL")+aTFFOri[9])
					
				If M->TFF_PERFIM > TFL->TFL_DTFIM
					Help( ,, 'AT740GVLPO',, STR0012 + DtoC(TFL->TFL_DTFIM)+")", 1, 0 ) // "A data informada é maior que a data do Local de Atendimento("
					lRet := .F.
					
				ElseIf M->TFF_PERFIM < TFL->TFL_DTINI
					Help( ,, 'AT740GVLPO',, STR0013 + DtoC(TFL->TFL_DTINI)+")", 1, 0 ) // "A data informada é menor que a data do Inicial Local de Atendimento("
					lRet := .F.		
				Else 
					If M->TFF_PERFIM < dDataBase
						Help( ,, 'AT740GVLPO',, STR0014, 1, 0 ) // "Data inválida! A Data informado é anterior à Data atual."
						lRet := .F.				
					Else
						If !Empty(oMdlTFF:GetValue("TFF_PERINI")) .And. M->TFF_PERFIM < oMdlTFF:GetValue("TFF_PERINI")
							Help( ,, 'AT740GVLPO',,STR0011 , 1, 0 ) // "Data inválida! A data final é menor que a data inicial." 
							lRet := .F.
						EndIf
					EndIf	
				EndIf
			Endif
		EndIf		
EndCase
	
RestArea( aAreaTFL )

Return lRet


//--------------------------------------------------------------------------------------
/*/{Protheus.doc}  AT740GALOC

Verificar se existe alocação para o Posto de Reforço em questão.. 

@author  	Fernando Alves Silva
@since 	  	26/09/2016
@version	P12

@return 	lRET
/*/
//---------------------------------------------------------------------------------------
Function AT740GALOC(cCodTFF, dPerIni, dPerFim)

Local aQry	  := {}
Local cQry	  := ""
Local TMPLOCE := GetNextAlias()
Local TMPLOCR := GetNextAlias()
Local lRet	  := .F.

// -------------------
// VERIFICA EFETIVO
// -------------------
BeginSql Alias TMPLOCE
	SELECT COUNT(*) AS T_ALOC
	FROM %table:TGY% TGY
	WHERE	TGY_FILIAL 	=  %xFilial:TGY%
		AND	TGY_CODTFF 	=  %Exp:cCodTFF%
		AND	TGY_DTINI 	>= %Exp:dPerIni%
		AND	(TGY_DTFIM 	<= %Exp:dPerFim% OR TGY_DTFIM = ' ') 
		AND	TGY.%NotDel%
EndSql

DbSelectArea(TMPLOCE)
If (TMPLOCE)->T_ALOC > 0 
	lRet:= .T.	
Else
	// -------------------
	// VERIFICA REFORÇO
	// -------------------
	BeginSql Alias TMPLOCR
		SELECT COUNT(*) AS T_ALOC
		FROM %table:TGZ% TGZ
		WHERE	TGZ_FILIAL 	=  %xFilial:TGZ%
			AND	TGZ_CODTFF 	=  %Exp:cCodTFF%
			AND	TGZ_DTINI 	>= %Exp:dPerIni%
			AND	(TGZ_DTFIM 	<= %Exp:dPerFim% OR TGZ_DTFIM = ' ') 
			AND	TGZ.%NotDel%
	EndSql
	
	aQry := GetLastQuery()
	
	DbSelectArea(TMPLOCR)
	If (TMPLOCR)->T_ALOC > 0 
		lRet:= .T.	
	Endif
	
	(TMPLOCR)->(DbCloseArea())
Endif

(TMPLOCE)->(DbCloseArea())

Return lRet


//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At740GCom
Faz a validação de preenchimento de todas as grids.

@author Ana Maria Utsumi 
@version 12.1.16
@since 13/04/2017
@return lRet
/*/
//--------------------------------------------------------------------------------------------------------
Static Function At740GCom(oModel)
Local lRet		:= .T.
Local oModelTFF	:= oModel:GetModel("TFF_RH")
Local oModelTW4	:= oModel:GetModel("TW4DETAIL")
Local oModelT44	:= oModel:GetModel("T44DETAIL")

If oModelTFF:IsInserted()
	If oModelT44:IsEmpty()
		Help( ,, 'AT740GCOM',, STR0025, 1, 0 ) // "Não foram informados os horários do reforço."
		lRet := .F.
	ElseIf oModelTW4:IsEmpty()
		oModelTW4:GetValue()
	EndIf
EndIf	

If lRet
	lRet := FwFormCommit(oModel)
EndIf

Return lRet
//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} A740GConsult
Retorno da consulta padrão de contratos.

@author Leandro Fini 
@version 10.01.17
@return cRet
/*/
//--------------------------------------------------------------------------------------------------------
Function A740GConsult()

Local cRet := ""

If Empty(MV_PAR01) //Se o cliente do Pergunte TECA740G estiver vazio
  cRet := "TFJ->TFJ_STATUS=='1' .And. !Empty(TFJ->TFJ_CONTRT) .And. TFJ->TFJ_CODENT <> ''"
Else
  cRet := "TFJ->TFJ_STATUS=='1'  .And. !Empty(TFJ->TFJ_CONTRT) .And. TFJ->TFJ_CODENT == MV_PAR01"
Endif

Return cRet


//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} A740ENCPOST
Rotina para chamar a view TECA871 para encerramento de posto.
E atualizar legenda para Posto Encerrado

@author Leandro Fini 
@version 12.01.17
@return cRet
/*/
//--------------------------------------------------------------------------------------------------------
Function A740ENCPOST(cContra, cRev, cPropos, oView, oModel)

Local nExec := 0
Local nX	:= 1
Local oModelTFF := oModel:GetModel('TFF_RH')

	DbSelectArea("TFJ")
	TFJ->(DbSetOrder(5))//TFJ_CONTRT+TFJ_CONREV
	
	If TFJ->(DbSeek(xFilial("TFJ")+cContra+cRev))
		If At871VldDt(,cPropos,.F.)
	  	 nExec := FWExecView( STR0031, "VIEWDEF.TECA871", MODEL_OPERATION_UPDATE, /*oDlg*/, {||.T.} /*bCloseOk*/,	{||.T.}/*bOk*/,/*nReducao*/, /*aButtons*/, {||.T.}/*bCancel*/ )	//"Encerrar Posto"
			If nExec == 0 //Execview foi confirmada
				For nX := 1 to oModelTFF:Length()
					oModelTFF:GoLine(nX)
					If !oModelTFF:IsDeleted() .AND. oModelTFF:GetValue("TFF_LEG") == "BR_VERDE"
						If Posicione("TFF",1,xFilial("TFF") + oModelTFF:GetValue("TFF_COD"), "TFF_ENCE") == "1" //Posto Encerrado
							oModelTFF:SetValue("TFF_PERFIM", dDataBase )
							oModelTFF:LoadValue("TFF_LEG", "BR_PRETO" )		
						EndIf
					Endif
				Next nX
				oView:Refresh('VIEW_TFF')
			EndIf
		EndIf
	EndIf

Return
//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At740PosVld
Rotina de pós validação da Grid TFF_RH

@author Leandro Fini 
@version 19.01.17
@return lRet
/*/
//--------------------------------------------------------------------------------------------------------
Static Function At740PosVld(oGridModel)

Local lRet		:= .T.
Local oModel	:= FwModelActive()
Local oModelTFF	:= oModel:GetModel("TFF_RH")

	If Empty(oModelTFF:GetValue("TFF_PERINI"))
		Help( ,, 'At740PosVld',,STR0032, 1, 0 )//"Preencha o período inicial."                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
		lRet := .F.
	Elseif Empty(oModelTFF:GetValue("TFF_PERFIM"))
		Help( ,, 'At740PosVld',,STR0033, 1, 0 )//"Preencha o período final."                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
		lRet := .F.
	Endif

Return lRet