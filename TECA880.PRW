#INCLUDE "TECA880.CH"
#INCLUDE "Protheus.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "MSOle.Ch" 

#DEFINE itARMA    "1"
#DEFINE itCOLETE  "2"
#DEFINE itMUNICAO "3"

#DEFINE eoLOCINTER	'1'
#DEFINE eoLOCATEND	'2'
#DEFINE edCLIENTE		'1'
#DEFINE edEMPRESA		'2'

#DEFINE stAGENDADA	'1'
#DEFINE stEFETIVADA	'2'
#DEFINE stANULADA		'3'

#DEFINE mtIMPLANTACAO	'1'
#DEFINE mtMANUTENCAO		'2'
#DEFINE mtDESCARTE		'3'
#DEFINE mtREFORCO			'4'

Static cTab		:= ""
Static aCmpBco	:= {} //Array com os locais de alocação da munição
Static oModel
Static oView

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECA880	

Cadastro de Movimentação - TFQ

@author 	Serviços
@since 		20/08/13
@version 	P11 R9
@param		cFilDefault, Caracter, código de filtro para restrição forçada da exibição dos dados na tabela/browse
/*/
//----------------------------------------------------------------------------------------------------------------------
Function TECA880(cFilDefault)
Local oBrowse	:= Nil
Local nX		:= 0
Local aCores 		:= {	{ 'TFQ->TFQ_STATUS=="1"' , 'BR_AMARELO', 	STR0002 },; 	//"Agendada"
							{ 'TFQ->TFQ_STATUS=="2"' , 'BR_VERDE', 	STR0003},;	//"Efetivada"
							{ 'TFQ->TFQ_STATUS=="3"' , 'BR_VERMELHO', STR0004}}		//"Cancelada"

Default cFilDefault := ''

Private aRotina	:= MenuDef()
Private cCadastro	:= STR0001 //"Movimentação"
 
oBrowse := FWMBrowse():New()
oBrowse:SetAlias('TFQ')

// Adiciona as legendas.
For nX := 1 To Len(aCores)
	oBrowse:AddLegend(aCores[nX][1],aCores[nX][2],aCores[nX][3]) 
Next nX   

If !Empty(cFilDefault)
	oBrowse:SetFilterDefault(cFilDefault)
EndIf

oBrowse:SetDescription(STR0001) //"Movimentação"
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
Static Function MenuDef()

LOCAL aRotina:= FWMVCMenu( "TECA880" )

aAdd( aRotina, { STR0005, 'MSDOCUMENT', 0, 7, 0, NIL } ) //"Bco. Conhecimento"

Return aRotina

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

Local oStruTFQ	:= FWFormStruct(1,'TFQ', {|cCampo| AT880GFLD('CABECALHO',cCampo)})		//Cabeçalho de Movimentação
Local oStruTFR  	:= FWFormStruct(1,'TFR')		//Tabela de Funcionarios da ocorrencia	
Local oStruTFOA	:= FWFormStruct(1,'TFO', {|cCampo| AT880GFLD('ARMAS'   , cCampo)})		//Item de Movimentação - Armas
Local oStruTFOM	:= FWFormStruct(1,'TFO', {|cCampo| AT880GFLD('MUNICOES', cCampo)})		//Item de Movimentação - Munições
Local oStruTFOC	:= FWFormStruct(1,'TFO', {|cCampo| AT880GFLD('COLETES' , cCampo)})		//Item de Movimentação - Coletes

Local aAux			:= {}

Local bPosVld			:= {|oModel|At880PosTFQ(oModel)}
Local bPosValidacao	:= {|oModel|At880PosValid(oModel)}
Local bCommit			:= {|oModel|At880Commit(oModel)}
Local bActivate		:= {|oModel|At880Active(oModel)}
Local bPosTRF			:= {|oModel|At880PosTRF(oModel)}
Local bLnPsTFOA 		:= {|oModel,nLine,cAcao,cCampo|At880LPArm(oModel,nLine,cAcao,cCampo)}
Local bLnPsTFOM 		:= {|oModel,nLine,cAcao,cCampo|At880LPMun(oModel,nLine,cAcao,cCampo) .And. At880VldQt(oModel:GetModel())}
Local bPosTFOA		:= {|oModel,nLine,cAcao,cCampo|At880PosGA(oModel,nLine,cAcao,cCampo)}
Local bLocalVld		:= {||}
Local cAtuProp		:= ""

Local aLoadFilter		:= {}

//Criação de Gatilhos para os campos virtuais
aAux := FwStruTrigger("TFQ_ORIGEM","TFQ_DSCLOC","At880LDsc('ORIGEM')",.F.,Nil,Nil,Nil)
oStruTFQ:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4]) 

aAux := FwStruTrigger("TFQ_DESTIN","TFQ_DDESTI","At880LDsc('DESTINO')",.F.,Nil,Nil,Nil)
oStruTFQ:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TFQ_RESTRA","TFQ_DRESP","At880Resp()",.F.,Nil,Nil,Nil)
oStruTFQ:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TFR_CODTEC","TFR_NOMTEC","At880Atend()",.F.,Nil,Nil,Nil)
oStruTFR:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

//Gatilhos para as descrições dos armamentos
aAux := FwStruTrigger("TFO_ITCOD","TFO_DESCR","At880IniArma('"+itARMA+"',FwFldGet('TFO_ITCOD'))",.F.,Nil,Nil,Nil)
oStruTFOA:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TFO_PRODUT","TFO_DSCMUN","At880IniArma('"+itMUNICAO+"',FwFldGet('TFO_PRODUT'))",.F.,Nil,Nil,Nil)
oStruTFOM:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TFO_ITCOD","TFO_DESCR","At880IniArma('"+itCOLETE+"',FwFldGet('TFO_ITCOD'))",.F.,Nil,Nil,Nil)
oStruTFOC:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

//Aplicar os inicializadores padrão
oStruTFOA:SetProperty('TFO_ITMOV',MODEL_FIELD_INIT,{|| itARMA })
oStruTFOM:SetProperty('TFO_ITMOV',MODEL_FIELD_INIT,{|| itMUNICAO })
oStruTFOC:SetProperty('TFO_ITMOV',MODEL_FIELD_INIT,{|| itCOLETE })

// Pré Validação de Edição - Master
oStruTFQ:SetProperty("TFQ_CONTRT",MODEL_FIELD_WHEN,{ || (FwFldGet("TFQ_ENTDES") == edCLIENTE .And. !Empty(FwFldGet("TFQ_DESTIN"))) } )

// Pós Validação de Edição - Master
oStruTFQ:SetProperty("TFQ_ORIGEM",MODEL_FIELD_VALID,{ |oModel|At880VldOri(oModel,'TFQ_ORIGEM')})
oStruTFQ:SetProperty("TFQ_ENTORI",MODEL_FIELD_VALID,{ |oModel|At880VlEnt(oModel,'TFQ_ENTORI') })
oStruTFQ:SetProperty("TFQ_ENTDES",MODEL_FIELD_VALID,{ |oModel|At880VlEnt(oModel,'TFQ_ENTDES') })
oStruTFQ:SetProperty("TFQ_MOTIVO",MODEL_FIELD_VALID,{ |oModel|At880VlEnt(oModel,'TFQ_MOTIVO') .And. At880VldTp() })
oStruTFQ:SetProperty("TFQ_CONTRT",MODEL_FIELD_VALID,{ |oModel|At880VlCont(oModel,FwFldGet("TFQ_DESTIN"),oModel:GetValue("TFQ_CONTRT")) })
oStruTFQ:SetProperty("TFQ_DMOVIM",MODEL_FIELD_VALID,{ |oModel|At880VDtMv(oModel) })

// Obrigatoriedade de preenchimento - Armas
oStruTFOA:SetProperty('TFO_LGUIA',MODEL_FIELD_OBRIGAT,.T.)
// Pré Validação de Edição - Armas
oStruTFOA:SetProperty('TFO_ITMOV',MODEL_FIELD_WHEN,{|oModel| .F.})
oStruTFOA:SetProperty('TFO_NRGUIA',MODEL_FIELD_WHEN,{|oModel| oModel:GetValue('TFO_LGUIA') == '1'})
oStruTFOA:SetProperty('TFO_DTRET',MODEL_FIELD_WHEN,{|oModel| oModel:GetValue('TFO_LRET') == '1'})
// Pós Validação de Edição - Armas
oStruTFOA:SetProperty("TFO_ITCOD",MODEL_FIELD_VALID,{ |oModel| At880VIMV(oModel) })
oStruTFOA:SetProperty("TFO_LGUIA",MODEL_FIELD_VALID,{ |oModel| Pertence('12') .and. At880NGuia(oModel) })
oStruTFOA:SetProperty("TFO_LRET",MODEL_FIELD_VALID,{ |oModel| Pertence('12') .and. At880DtPrv(oModel) })
oStruTFOA:SetProperty("TFO_DTRET",MODEL_FIELD_VALID,{ |oModel| At880VDtRt(oModel) })

// Obrigatoriedade de preenchimento - Munições
oStruTFOM:SetProperty('TFO_LGUIA',MODEL_FIELD_OBRIGAT,.T.)
oStruTFOM:SetProperty('TFO_QTDE',MODEL_FIELD_OBRIGAT,.T.)

// Pré Validação de Edição - Munições
oStruTFOM:SetProperty('TFO_ITMOV',MODEL_FIELD_WHEN,{|oModel| .F.})
oStruTFOM:SetProperty('TFO_NRGUIA',MODEL_FIELD_WHEN,{|oModel| oModel:GetValue('TFO_LGUIA') == '1'})
oStruTFOM:SetProperty('TFO_DTRET',MODEL_FIELD_WHEN,{|oModel| oModel:GetValue('TFO_LRET') == '1'})

// Pós Validação de Edição - Munições
oStruTFOM:SetProperty("TFO_LGUIA",MODEL_FIELD_VALID,{ |oModel| Pertence('12') .and. At880NGuia(oModel) })
oStruTFOM:SetProperty("TFO_LRET",MODEL_FIELD_VALID,{ |oModel| Pertence('12') .and. At880DtPrv(oModel) })
oStruTFOM:SetProperty("TFO_DTRET",MODEL_FIELD_VALID,{ |oModel| At880VDtRt(oModel) })

// monta a validação para o campo TFO_PRODUT
cAtuProp := RTrim( GetSX3Cache("TFO_PRODUT","X3_VALID") ) + " .And. At880VldAloc('3')"
If !Empty( Alltrim(cValUser := GetSX3Cache("TFO_PRODUT","X3_VLDUSER") ) )
	cAtuProp += " .And. " + cValUser
EndIf
bLocalVld := FwBuildFeature( STRUCT_FEATURE_VALID, cAtuProp )
oStruTFOM:SetProperty("TFO_PRODUT", MODEL_FIELD_VALID, bLocalVld )


// Pré Validação de Edição - Coletes
oStruTFOC:SetProperty('TFO_ITMOV',MODEL_FIELD_WHEN,{|oModel|.F.})
oStruTFOC:SetProperty('TFO_DTRET',MODEL_FIELD_WHEN,{|oModel|oModel:GetValue('TFO_LRET') == '1'})
// Pós Validação de Edição - Coletes
oStruTFOC:SetProperty("TFO_ITCOD",MODEL_FIELD_VALID,{ |oModel| At880VIMV(oModel) })
oStruTFOC:SetProperty("TFO_LRET",MODEL_FIELD_VALID,{ |oModel| Pertence('12') .and. At880DtPrv(oModel) })
oStruTFOC:SetProperty("TFO_DTRET",MODEL_FIELD_VALID,{ |oModel| At880VDtRt(oModel) })

//Instancia o cadastro de Ocorrencia
oModel := MPFormModel():New('TECA880',/*bPreValidacao*/,bPosVld,bCommit,/*bCancel*/)

//Instancia o cabeçalho da ocorrencia
oModel:AddFields('TFQMASTER',/*cOwner*/,oStruTFQ,/*bPreValidacao*/,bPosValidacao,/*bCarga*/,/*bFieldAbp*/)

//Instancia os Grids para cadastro de ocorrencia
oModel:AddGrid("TFRFUNC","TFQMASTER",oStruTFR,/*bLinePre*/,/*bLinePost*/,/*bPreValidacao*/,bPosTRF,/*bLoadPrd*/)
oModel:AddGrid("TFOARMA","TFQMASTER",oStruTFOA,/*bLinePre*/,bLnPsTFOA,/*bPreTFOA*/,/*bPosTFOA*/,/*bLoadPrd*/)
oModel:AddGrid("TFOMUNI","TFQMASTER",oStruTFOM,/*bLinePre*/,bLnPsTFOM, ,/*bLoadPrd*/)
oModel:AddGrid("TFOCOLE","TFQMASTER",oStruTFOC,/*bLinePre*/,/*bLinePost*/,/*bPreValidacao*/,/*bPosValidacao*/,/*bLoadPrd*/)

//Realiza o relacionamento entre o cabeçalho e os grids Funcionario/Pessoas - Armas - Munições - Coletes
oModel:SetRelation("TFRFUNC",{{"TFR_FILIAL","xFilial('TFR')"},{"TFR_CODMOV","TFQ_CODIGO"}},TFR->( IndexKey(1)))  
oModel:SetRelation("TFOARMA",{{"TFO_FILIAL","xFilial('TFO')"},{"TFO_CDMOV","TFQ_CODIGO"}},TFO->( IndexKey(1)))  
oModel:SetRelation("TFOMUNI",{{"TFO_FILIAL","xFilial('TFO')"},{"TFO_CDMOV","TFQ_CODIGO"}},TFO->( IndexKey(1)))  
oModel:SetRelation("TFOCOLE",{{"TFO_FILIAL","xFilial('TFO')"},{"TFO_CDMOV","TFQ_CODIGO"}},TFO->( IndexKey(1)))  

//Determina a obrigatoriedade de preenchimento dos Grid's
oModel:GetModel('TFOARMA'):SetOptional(.T.)
oModel:GetModel('TFOMUNI'):SetOptional(.T.)
oModel:GetModel('TFOCOLE'):SetOptional(.T.)
oModel:GetModel("TFRFUNC"):SetOptional(.T.)

//Configura o Grid para não duplicar a linha
oModel:GetModel("TFRFUNC"):SetUniqueLine({"TFR_CODTEC"})
oModel:GetModel("TFOARMA"):SetUniqueLine({"TFO_ITMOV","TFO_ITCOD"})
oModel:GetModel("TFOMUNI"):SetUniqueLine({"TFO_ITMOV","TFO_PRODUT"})
oModel:GetModel("TFOCOLE"):SetUniqueLine({"TFO_ITMOV","TFO_ITCOD"})

//Aplicar filtro de dados aos Grid's
aLoadFilter := { { "TFO_ITMOV", itARMA, MVC_LOADFILTER_EQUAL } }
oModel:GetModel("TFOARMA"):SetLoadFilter( aLoadFilter, /*cLoadFilter*/ )
aLoadFilter := { { "TFO_ITMOV", itCOLETE, MVC_LOADFILTER_EQUAL } }
oModel:GetModel("TFOCOLE"):SetLoadFilter( aLoadFilter, /*cLoadFilter*/ )
aLoadFilter := { { "TFO_ITMOV", itMUNICAO, MVC_LOADFILTER_EQUAL } }
oModel:GetModel("TFOMUNI"):SetLoadFilter( aLoadFilter, /*cLoadFilter*/ )

//Valida o Model para Ativa-lo
oModel:SetVldActivate(bActivate)

oModel:SetPrimaryKey( {} )

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

Local oModel   	:= FWLoadModel('TECA880')
Local oStruTFQ	:= FWFormStruct(2,'TFQ', {|cCampo| AT880GFLD('CABECALHO',cCampo)})		//Cabeçalho de Movimentação
Local oStruTFR  	:= FWFormStruct(2,'TFR')		//Tabela de Funcionarios da ocorrencia	
Local oStruTFOA	:= FWFormStruct(2,'TFO', {|cCampo| AT880GFLD('ARMAS'   , cCampo)})		//Item de Movimentação - Armas
Local oStruTFOM	:= FWFormStruct(2,'TFO', {|cCampo| AT880GFLD('MUNICOES', cCampo)})		//Item de Movimentação - Munições
Local oStruTFOC	:= FWFormStruct(2,'TFO', {|cCampo| AT880GFLD('COLETES' , cCampo)})		//Item de Movimentação - Coletes

oView:= FWFormView():New()
oView:SetModel(oModel)

oView:AddUserButton(STR0005, 'CLIPS',{|oView|MsDocument('TFQ',TFQ->(RECNO()),oModel:GetOperation() )}) //"Bco. Conhecimento"

//Adiciona o Link para Emissão da Guia
oView:AddUserButton(STR0048,"",{|oView|At880Guia(oModel)},,,) //Guia de Trafego

oStruTFQ:RemoveField("TFQ_ULTSTA")
oStruTFQ:RemoveField("TFQ_ENTIDA")
oStruTFR:RemoveField("TFR_CODMOV")


oView:AddField('VIEW_CAB',oStruTFQ,'TFQMASTER')
oView:AddGrid("VIEW_GRID_TFR",oStruTFR,"TFRFUNC")
oView:AddGrid("VIEW_GRID_TFOA",oStruTFOA,"TFOARMA")
oView:AddGrid("VIEW_GRID_TFOM",oStruTFOM,"TFOMUNI")
oView:AddGrid("VIEW_GRID_TFOC",oStruTFOC,"TFOCOLE")

oView:CreateHorizontalBox('SUPERIOR',65)
oView:CreateHorizontalBox('INFERIOR',35)

// Criação da pasta para conter as abas da parte inferior
oView:CreateFolder( "ABAS", "INFERIOR" )

// Criação das Abas
oView:AddSheet( "ABAS", "ABA01", "Destinatários" )	// 'Destinatários'
oView:AddSheet( "ABAS", "ABA02", "Armas" )			// 'Armas'
oView:AddSheet( "ABAS", "ABA03", "Munição" )			// 'Munição'
oView:AddSheet( "ABAS", "ABA04", "Coletes" )			// "Coletes"

// Criação das áreas de exibição dos dados nas abas
oView:CreateHorizontalBox( "ID_ABA01", 100,,, "ABAS", "ABA01" )
oView:CreateHorizontalBox( "ID_ABA02", 100,,, "ABAS", "ABA02" )
oView:CreateHorizontalBox( "ID_ABA03", 100,,, "ABAS", "ABA03" )
oView:CreateHorizontalBox( "ID_ABA04", 100,,, "ABAS", "ABA04" )

// Relacionando o componente da interface com o componente de dados.
oView:SetOwnerView( 'VIEW_CAB', 'SUPERIOR' )			// Cabeçalho da Movimentação		
oView:SetOwnerView( 'VIEW_GRID_TFR', 'ID_ABA01' )	// Grid Destinatários 
oView:SetOwnerView( 'VIEW_GRID_TFOA', 'ID_ABA02' )	// Grid Armas
oView:SetOwnerView( 'VIEW_GRID_TFOM', 'ID_ABA03' )	// Grid Munição
oView:SetOwnerView( 'VIEW_GRID_TFOC', 'ID_ABA04' )	// Grid Coletes

// Adicionando propriedade F3
oStruTFOA:SetProperty('TFO_ITCOD',MVC_VIEW_LOOKUP,'SB1ARM')
oStruTFOC:SetProperty('TFO_ITCOD',MVC_VIEW_LOOKUP,'SB1COL')
oStruTFOM:SetProperty('TFO_PRODUT',MVC_VIEW_LOOKUP,'SB1MUN')

oView:AddIncrementField( 'VIEW_GRID_TFR', 'TFR_ITEM' )


oStruTFOM:SetProperty('TFO_ITMOV', MVC_VIEW_ORDEM, '01')
oStruTFOM:SetProperty('TFO_PRODUT', MVC_VIEW_ORDEM, '02')
oStruTFOM:SetProperty('TFO_DSCMUN', MVC_VIEW_ORDEM, '03')

oStruTFOC:SetProperty('TFO_ITCOD',MVC_VIEW_TITULO,STR0083) //"Colete"

oView:SetCloseOnOk({|| .T.} )


Return(oView)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880Active

Verifica se o Status da Movimentação está Efetivada ou cancelada e não permite a sua edição
@author Serviços
@since 17/10/13
@version P11 R9

@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At880Active(oMdl)
Local nOperation 	:= oMdl:GetOperation()
Local lRet			:= .T.

If (nOperation == MODEL_OPERATION_UPDATE .Or. nOperation == MODEL_OPERATION_DELETE) .And. TFQ->TFQ_STATUS <> stAGENDADA
	Help( ,, "At880Active",, STR0007, 1, 0 )//"Movimentação",'Não é permitido alterar ou excluir a Movimentação Efetivada / Cancelada.'
	lRet := .F.
EndIf

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880PosValid

Pos-Validação do cadastro de Movimentação
@author Serviços
@since 28/08/13
@version P11 R9

@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At880PosValid(oMdl)
Local lRet	:= .T.
Local oMdlAux := nil
Local nQtMin	:= 0

If lRet 
	// Grade Armas
	oMdlAux := oMdl:GetModel():GetModel('TFOARMA')	
	// Verifica a quantidade de itens válidos
	nQtMin += At880SumIt(oMdlAux) 

	//Verifica se foi preenchido o Numero da Guia
	lRet := At880VldGuia(oMdlAux)

	If lRet
		//Verifica as datas de Retorno e da movimentação
		lRet := At880Status(oMdlAux)
	EndIf	
EndIf

If lRet	
	// Grade de Munições
	oMdlAux := oMdl:GetModel():GetModel('TFOMUNI')
	nQtMin += At880SumIt(oMdlAux)

	//Verifica se foi preenchido o Numero da Guia
	lRet := At880VldGuia(oMdlAux)

	If lRet
		//Verifica as datas de Retorno e da movimentação
		lRet := At880Status (oMdlAux,.T.)
	EndIf
EndIf

If lRet
	// Grade de Coletes
	oMdlAux := oMdl:GetModel():GetModel('TFOCOLE')
	nQtMin += At880SumIt(oMdlAux)
	

If lRet
	//Verifica as datas de Retorno e da movimentação
		lRet := At880Status(oMdlAux)
	EndIf
EndIf

If lRet .And. Empty(nQtMin)
	Help( ,, "At880PosValid",, STR0063, 1, 0 ) //'Alocação''Nenhum item de armamento foi selecionado!'
	lRet := .F.
EndIf

// Validação os campos da manutenção. 
If lRet 
	lRet := At880MntCmp()
EndIf
	
Return( lRet )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880LPArm
	Pos-Validação da linha do cadastro de Movimentação - Grid Armas

@param oModel,object,Objeto Master do formulário de movimentação
@param nLine,numerico,Linha da grade na edição atual

@sample At880LPArm(oMdl,nLine)

@author Serviços
@since 01/06/2015
@version P12

@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At880LPArm(oMdl,nLine)
Local lRet := .T.
Local nOperation := oMdl:GetOperation()

If nOperation == MODEL_OPERATION_UPDATE .Or. nOperation == MODEL_OPERATION_INSERT
	If oMdl:GetValue('TFO_LGUIA') == '1' .AND. Empty(oMdl:GetValue('TFO_NRGUIA'))
		Help( ,, "At880LPArm",, STR0012, 1, 0 ) //'Alocação','Preencha o Numero da Guia!'
		lRet := .F.
	EndIf
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880LPMun
	Pos-Validação da linha do cadastro de Movimentação - Grid Munições

@param oModel,object,Objeto Master do formulário de movimentação
@param nLine,numerico,Linha da grade na edição atual

@sample At880LPMun(oMdl,nLine)

@author Serviços
@since 08/07/2015
@version P12

@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At880LPMun(oMdl,nLine)
Local lRet := .T.
Local nOperation := oMdl:GetOperation()

If nOperation == MODEL_OPERATION_UPDATE .Or. nOperation == MODEL_OPERATION_INSERT
	If oMdl:GetValue('TFO_LGUIA') == '1' .AND. Empty(oMdl:GetValue('TFO_NRGUIA'))
		Help( ,, "At880LPMun",, STR0012, 1, 0 ) //'Alocação','Preencha o Numero da Guia!'
		lRet := .F.
	EndIf
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880PosTRF

Pos-Validação do cadastro de Movimentação - Grid Reponsaveis
@author Serviços
@since 28/08/13
@version P11 R9

@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At880PosTRF(oModel)
Local lRet			:= .T.
Local nI			:= 0
Local aArea		:= GetArea()

For nI := 1 to oModel:Length()
	oModel:GoLine(nI)
	//Verifica se o campo CNV está preenchido
	If (oModel:IsUpdated() .Or. oModel:IsInserted())
		DbSelectArea("AA1")
		AA1->(DbSetOrder(1))
		
		If AA1->(DbSeek(xFilial("AA1") + FwFldGet("TFR_CODTEC")))
			If Empty(AA1->AA1_CNV)
				Help( ,, "At880PosTRF",, STR0058 + cValToChar(nI) + STR0059, 1, 0 )//"O Atendente selecionado na linha: "##" não está com a CNV preenchida"
				lRet:= .F.	
			EndIf
		EndIf
	EndIf
	
Next nI

RestArea(aArea)

Return(lRet)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880PosTFQ

Pos-Validação do cadastro de Movimentação - Geral

@author 	Serviços
@since 		28/08/13
@version 	P11 R9

@return 	lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At880PosTFQ(oModel)
Local lRet			:= .T.
Local aArea	    	:= GetArea()
Local nI 			:= 0
Local oTFOMuni		:= oModel:GetModel('TFOMUNI')
Local aRows 		:= FwSaveRows()

If Empty(FwFldGet("TFQ_CONTRT")) .And. FwFldGet("TFQ_ENTDES") == edCLIENTE 
	lRet := At680Perm( Nil, __cUserId, "007" ) // Pode movimentar armamento fora do contrato?
	If !lRet
		Help( ,, 'AT880ACE',, STR0060, 1, 0) // "Usuário sem permissão para movimentação fora do contrato!"		
	EndIf
EndIf


If lRet
	For nI := 1 To oTFOMuni:Length()		
		oTFOMuni:GoLine(nI)
		If !oTFOMuni:IsDeleted() .And. !Empty(oTFOMuni:GetValue('TFO_PRODUT'))
			lRet := At880VldQt(oModel)
			If !lRet
				Exit
			EndIf	
		EndIf	
	Next nI	
EndIf

RestArea(aArea)
FwRestRows( aRows )

Return(lRet)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880Commit

Realiza a gravação da movimentação e alteração de Status dos armamentos
@author Serviços
@since 28/08/13
@version P11 R9

@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At880Commit(oMdl)

Local lRet 			:= .T.
Local nOperation 	:= oMdl:GetOperation()
Local lProtocolo	:= FindFunction("U_Tec880EXE")	//Verifica se o Rdmake de impressão do Protocolo existe
Local oMdlAux		:= nil
Local cTpArma		:= ''
Local cItArma		:= ''
Local dRetorno		:= CToD('')
Local nI			:= 0
Local oMdl			:= FwModelActive()

If nOperation == MODEL_OPERATION_INSERT .Or. nOperation == MODEL_OPERATION_UPDATE

	Begin Transaction
		Do Case
			Case FwFldGet("TFQ_MOTIVO") == mtIMPLANTACAO  .Or. FwFldGet("TFQ_MOTIVO") == mtREFORCO //Implantação ou Reforço
				
				//Verifica se os campos de manutenção estão preenchidos, senão realiza a sua limpeza
				If !(Empty(FwFldGet("TFQ_CDRESP"))) .Or. !(Empty(FwFldGet("TFQ_TPMNT"))) .Or. !(Empty(FwFldGet("TFQ_MOTMNT")))
					At880MntClean()
				EndIf
				
				//Altera a situação do Armamento		
				If FwFldGet("TFQ_STATUS") == stEFETIVADA

					// Instancia Grid Armas			
					oMdlAux	:= oMdl:GetModel('TFOARMA')
					cTpArma := itARMA
					If	!( oMdlAux:IsEmpty() )
						For nI := 1 To oMdlAux:Length()
							oMdlAux:GoLine(nI)
							cItArma  := oMdlAux:getValue('TFO_ITCOD')
							dRetorno := oMdlAux:GetValue('TFO_DTRET')
							If !oMdlAux:IsDeleted() .AND. !Empty(cItArma)
								At880SitArma(cTpArma,cItArma,dRetorno,oMdl)	//Altera o Status da Arma para Implantada
							EndIf
						Next nI
					EndIf

					// Instancia Grid Coletes
					oMdlAux	:= oMdl:GetModel('TFOCOLE')
					cTpArma := itCOLETE
					If	!( oMdlAux:IsEmpty() )
						For nI := 1 To oMdlAux:Length()
							oMdlAux:GoLine(nI)
							cItArma  := oMdlAux:getValue('TFO_ITCOD')
							dRetorno := oMdlAux:GetValue('TFO_DTRET')
							If !oMdlAux:IsDeleted() .AND. !Empty(cItArma)
								At880SitArma(cTpArma,cItArma,dRetorno,oMdl)	//Altera o Status da Arma para Implantada
							EndIf
						Next nI
					EndIf
					
					// Instancia Grid Munição
					oMdlAux	:= oMdl:GetModel('TFOMUNI')
					cTpArma	:= itMUNICAO
					If	!( oMdlAux:IsEmpty() )
						For nI := 1 To oMdlAux:Length()
							oMdlAux:GoLine(nI)
							//cItArma:= oMdlAux:getValue('TFO_ITCOD')
							cItArma:= oMdlAux:getValue('TFO_PRODUT')
							nQtd	:= oMdlAux:GetValue('TFO_QTDE')
							If !oMdlAux:IsDeleted() .AND. !Empty(cItArma)
								At880IncTFP(cItArma,nQtd)				//Altera o Saldo da Munição
								At880SitArma(cTpArma,cItArma,dRetorno)	//Altera o Status da Municao para Implantada
							EndIf
						Next nI
					EndIf

				EndIf
			Case FwFldGet("TFQ_MOTIVO") == mtMANUTENCAO //Manutenção
			
				If FwFldGet("TFQ_STATUS") == stEFETIVADA

					// Instancia Grid Armas			
					oMdlAux	:= oMdl:GetModel('TFOARMA')
					cTpArma := itARMA
					If	!( oMdlAux:IsEmpty() )
						For nI := 1 To oMdlAux:Length()
							oMdlAux:GoLine(nI)
							cItArma  := oMdlAux:getValue('TFO_ITCOD')
							dRetorno := oMdlAux:GetValue('TFO_DTRET')
							If !oMdlAux:IsDeleted() .AND. !Empty(cItArma)
								//Gera o registro de manutenção
								If !(lRet := At880IncManut(oMdl,cTpArma,cItArma))
									Exit
								EndIf
								If lRet
									At880SitArma(cTpArma,cItArma,dRetorno,oMdl)	//Altera o Status da Arma para Ativa
								EndIf	
							EndIf
						Next nI
					EndIf

					// Instancia Grid Coletes
					oMdlAux	:= oMdl:GetModel('TFOCOLE')
					cTpArma := itCOLETE
					If	!( oMdlAux:IsEmpty() )
						For nI := 1 To oMdlAux:Length()
							oMdlAux:GoLine(nI)
							cItArma  := oMdlAux:getValue('TFO_ITCOD')
							dRetorno := oMdlAux:GetValue('TFO_DTRET')
							If !oMdlAux:IsDeleted() .AND. !Empty(cItArma)
								//Gera o registro de manutenção
								If !(lRet := At880IncManut(oMdl,cTpArma,cItArma))
									Exit
								EndIf
								If lRet
									At880SitArma(cTpArma,cItArma,dRetorno,oMdl)	//Altera o Status da Arma para Ativa
								EndIf							
							EndIf
						Next nI
					EndIf
					
					// Instancia Grid Munição
					oMdlAux	:= oMdl:GetModel('TFOMUNI')
					cTpArma	:= itMUNICAO
					If	!( oMdlAux:IsEmpty() )
						For nI := 1 To oMdlAux:Length()
							oMdlAux:GoLine(nI)
							cItArma:= oMdlAux:getValue('TFO_PRODUT')
							nQtd	:= oMdlAux:GetValue('TFO_QTDE')
							If !oMdlAux:IsDeleted() .AND. !Empty(cItArma)
								At880IncTFP(cItArma,nQtd)				//Altera o Saldo da Munição
							EndIf
						Next nI
					EndIf
					

					If lRet
						ApMsgInfo( STR0041, STR0042 ) //'Manutenção incluida com sucesso.','ATENÇÃO'
					EndIf
						
				EndIf

			Case FwFldGet("TFQ_MOTIVO") == mtDESCARTE //Descarte

				If FwFldGet("TFQ_STATUS") == stEFETIVADA

					// Instancia Grid Armas			
					oMdlAux	:= oMdl:GetModel('TFOARMA')
					cTpArma := itARMA
					If	!( oMdlAux:IsEmpty() )
						For nI := 1 To oMdlAux:Length()
							oMdlAux:GoLine(nI)
							cItArma  := oMdlAux:getValue('TFO_ITCOD')
							dRetorno := oMdlAux:GetValue('TFO_DTRET')
							If !oMdlAux:IsDeleted() .AND. !Empty(cItArma)
								At880SitArma(cTpArma,cItArma,dRetorno,oMdl)	//Altera o Status da Arma para Ativa
							EndIf
						Next nI
					EndIf

					// Instancia Grid Coletes
					oMdlAux	:= oMdl:GetModel('TFOCOLE')
					cTpArma := itCOLETE
					If	!( oMdlAux:IsEmpty() )
						For nI := 1 To oMdlAux:Length()
							oMdlAux:GoLine(nI)
							cItArma  := oMdlAux:getValue('TFO_ITCOD')
							dRetorno := oMdlAux:GetValue('TFO_DTRET')
							If !oMdlAux:IsDeleted() .AND. !Empty(cItArma)
								At880SitArma(cTpArma,cItArma,dRetorno,oMdl)	//Altera o Status da Arma para Ativa
							EndIf
						Next nI
					EndIf
					
					// Instancia Grid Munição
					oMdlAux	:= oMdl:GetModel('TFOMUNI')
					cTpArma	:= itMUNICAO
					If	!( oMdlAux:IsEmpty() )
						For nI := 1 To oMdlAux:Length()
							oMdlAux:GoLine(nI)
							cItArma:= oMdlAux:getValue('TFO_PRODUT')
							nQtd	:= oMdlAux:GetValue('TFO_QTDE')
							If !oMdlAux:IsDeleted() .AND. !Empty(cItArma)
								At880IncTFP(cItArma,nQtd)				//Altera o Saldo da Munição
							EndIf
						Next nI
					EndIf

				EndIf

		EndCase

		// Zera o campo de contrato quando a movimentação for interna
		If FwFldGet("TFQ_ENTDES") == edEMPRESA
			oMdl:LoadValue( "TFQMASTER", "TFQ_CONTRT",  "" )
		EndIf

	End Transaction

EndIf

If lProtocolo
	//Imprime o Protocolo
	//Quando a Movimentação for efetivada é realizado a impressão sem perguntar ao usuario
	If (FwFldGet("TFQ_STATUS") == stEFETIVADA .And. FwFldGet("TFQ_ENTDES") == edCLIENTE) .OR.;
		(FwFldGet("TFQ_STATUS") == stAGENDADA .AND. MsgYesNo(STR0011))	//"Deseja Imprimir o Protocolo de Entrega?"
		// Instancia Grid Armas			
		oMdlAux	:= oMdl:GetModel('TFOARMA')
		If	!( oMdlAux:IsEmpty() )
			For nI := 1 To oMdlAux:Length()
				oMdlAux:GoLine(nI)
				If !oMdlAux:IsDeleted() .AND. !Empty(oMdlAux:GetValue('TFO_ITCOD'))
					If FindFunction("U_Tec880ImpProt")
						U_Tec880ImpProt(FwFldGet("TFQ_CODIGO"),oMdlAux:GetValue("TFO_ITMOV"),oMdlAux:GetValue("TFO_ITCOD"),FwFldGet("TFQ_DRESP"),0,FwFldGet("TFQ_DDESTI"))
					EndIf					
				EndIf
			Next nI
		EndIf

		// Instancia Grid Coletes
		oMdlAux	:= oMdl:GetModel('TFOCOLE')
		If	!( oMdlAux:IsEmpty() )
			For nI := 1 To oMdlAux:Length()
				oMdlAux:GoLine(nI)
				If !oMdlAux:IsDeleted() .AND. !Empty(oMdlAux:getValue('TFO_ITCOD'))
					If FindFunction("U_Tec880ImpProt")
						U_Tec880ImpProt(FwFldGet("TFQ_CODIGO"),oMdlAux:GetValue("TFO_ITMOV"),oMdlAux:GetValue("TFO_ITCOD"),FwFldGet("TFQ_DRESP"),0,FwFldGet("TFQ_DDESTI"))
					EndIf					
				EndIf
			Next nI
		EndIf

		// Instancia Grid Munição
		oMdlAux	:= oMdl:GetModel('TFOMUNI')
		If	!( oMdlAux:IsEmpty() )
			For nI := 1 To oMdlAux:Length()
				oMdlAux:GoLine(nI)
				If !oMdlAux:IsDeleted() .AND. !Empty(oMdlAux:getValue('TFO_PRODUT'))
					If FindFunction("U_Tec880ImpProt")
						U_Tec880ImpProt(FwFldGet("TFQ_CODIGO"),oMdlAux:GetValue("TFO_ITMOV"),oMdlAux:GetValue("TFO_PRODUT"),FwFldGet("TFQ_DRESP"),oMdlAux:GetValue("TFO_QTDE"),FwFldGet("TFQ_DDESTI"))
					EndIf					
				EndIf
			Next nI
		EndIf
	EndIf
EndIf

FWModelActive( oMdl )
FWFormCommit( oMdl )
Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} FA880F3

Chama a Consulta Padrão conforme o que foi selecionado no campo TFQ_ITMOV
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function FA880F3(cTpArma)
Local lRet			:= .T.
Local aArea		:= GetArea()
Local oMdl		:= FwModelActive()
Default cTpArma	:= "" 

If Empty(cTpArma)  
	cTpArma := oMdl:GetValue("TFOARMA","TFO_ITMOV")
EndIf

SaveInter()
Do Case
	Case cTpArma == "1"
		lRet := Conpad1( NIL,NIL,NIL,"TE0")
		
	Case cTpArma == "2"
		lRet := ConPad1(Nil,Nil,Nil,"TE1")
		
	Case cTpArma == "3"
		lRet := ConPad1(Nil,Nil,Nil,"TE2")
									
EndCase
RestInter()
RestArea(aArea)
Return (lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880DscArma

Realiza o preenchimento da descrição do Armamento
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880DscArma()
Local cDesc		:= ""
Local cLocal		:= ""
Local cDscLocal	:= ""
Local aArea		:= GetArea()
Local cArma		:= ""

Do Case
 	Case FwFldGet("TFO_ITMOV") == "1"
		
		DbSelectArea("TE0")
		TE0->(DbSetOrder(1))
		
		If TE0->(DbSeek(xFilial("TE0") + FwFldGet("TFO_ITCOD")))		
			cArma := TE0->TE0_CODPRO
			cDesc := Posicione("SB1",1,xFilial("SB1") + cArma,"SB1->B1_DESC")
			cLocal		:= TE0->TE0_LOCAL
			cDscLocal	:= TE0->TE0_CLIDES
			
			//Atribiu o valor para os campos de origem
			At880DscOrigem(cLocal,cDscLocal)
			
	 	EndIf
	 
	 Case FwFldGet("TFO_ITMOV") == "2"
		
		DbSelectArea("TE1")
		TE1->(DbSetOrder(1))
		
		If TE1->(DbSeek(xFilial("TE1") + FwFldGet("TFO_ITCOD")))		
			cArma := TE1->TE1_CODPRO
			cDesc := Posicione("SB1",1,xFilial("SB1") + cArma,"SB1->B1_DESC")
			cLocal		:= TE1->TE1_LOCAL
			cDscLocal	:= TE1->TE1_CLIDES
			
			//Atribiu o valor para os campos de origem
			At880DscOrigem(cLocal,cDscLocal)
	 	EndIf
	
	Case FwFldGet("TFO_ITMOV") == "3"
		
		DbSelectArea("TE2")
		TE2->(DbSetOrder(1))
		
		If TE2->(DbSeek(xFilial("TE2") + FwFldGet("TFO_PRODUT")))		
			cArma := TE2->TE2_CODPRO
			cDesc := Posicione("SB1",1,xFilial("SB1") + cArma,"SB1->B1_DESC")
			cLote		:= TE2->TE2_LOTE
			
			//Atribiu o valor para o campo de Lote
			At880DscOrigem(Nil,Nil,cLote)
	 	EndIf		
EndCase
RestArea(aArea)
Return(cDesc)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880DscOrigem

Seta os valores para os campos de Origem e descrição da Origem
@author Serviços
@since 28/08/13
@version P11 R9

@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At880DscOrigem(cLocal,cDesc,cLote)
Local oModel	:= FWModelActive()

Default cLocal	:= ""
Default cDesc		:= ""
Default cLote		:= ""

If !Empty(cLocal)
	oModel:SetValue("TFQMASTER","TFQ_ORIGEM", cLocal)
EndIf

If !Empty(cDesc)
	oModel:SetValue("TFQMASTER","TFQ_DSCLOC", cDesc)	
EndIf

If !Empty(cLote)
	oModel:SetValue("TFQMASTER","TFO_LOTE", cLote)
EndIf

Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880Agend

Verifica se a arma escolhida possui Movimentação Agendada

@param cItMov,caractere,Tipo de Armamento
@param cItCod,caractere,Código do Armamento
@sample At880Agend(cItMov,cItCod)
@author Serviços
@since 28/08/13
@version P11 R9

@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At880Agend(cItMov,cItCod)
	Local lRet		:= .T.
	Local cTabTMP	:= GetNextAlias()
	Local cStatus	:= stAGENDADA
	Local aArea	:= GetArea()

	BeginSQL alias cTabTMP

		column NCONT as Numeric(3,0)
				
		SELECT COUNT(TFO.TFO_ITCOD) AS NCONT
		
		FROM %Table:TFQ% TFQ
		
		INNER JOIN %Table:TFO% TFO ON
		TFO.TFO_FILIAL = TFQ.TFQ_FILIAL
		AND TFO.TFO_CDMOV = TFQ.TFQ_CODIGO
		AND TFO.%NotDel%
		
		WHERE
		TFQ.TFQ_FILIAL = %xfilial:TFP%
		AND TFO.TFO_ITMOV = %exp:cItMov%
		AND TFO.TFO_ITCOD = %exp:cItCod%
		AND TFQ.TFQ_STATUS = %exp:cStatus%
		AND TFQ.%NotDel%
		
	EndSQL
	
	While (cTabTMP)->(!Eof())
		lRet := (cTabTMP)->NCONT > 0
		(cTabTMP)->(dbSkip())
	EndDo

	(cTabTMP)->(dbCloseArea())
RestArea(aArea)
Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880VldAloc

Verifica se a arma escolhida possui alocação na origem

@param cItMov,caractere,Item de Armamento
@param cItCod,caractere,Código do armamento

@sample At880VldAloc(cItMov,cItCod)
@author Serviços
@since 28/08/13
@version P11 R9

@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880VldAloc(cItMov,cItCod,lVldLaXLo)
Local lRet		:= .T.
Local aArea	:= GetArea()	
Local cTab		:= ''
Local cEnt		:= ''
Local cCdEnt	:= '' 	

Default cItMov	:= ''
Default cItCod	:= ''
Default lVldLaXLo	:= .F.

Do Case
	Case cItMov == itARMA
		cTab := "TE0"
	Case cItMov == itCOLETE
		cTab := "TE1"
	Case cItMov == itMUNICAO
		cTab := "TE2"
EndCase

If cTab $ 	"TE0;TE1"
	DbSelectArea(cTab)
	(cTab)->(DbSetOrder(1))
			
	If (cTab)->(DbSeek(xFilial(cTab) + cItCod))
		
		cEnt	:= (cTab)->&(cTab + '_ENTIDA')
		cEnt	:= If( cEnt == 'TER', '1' , '2' )
				
		cCdEnt	:= (cTab)->&(cTab + '_LOCAL')
				
		If Empty(cCdEnt)
				lRet := .F.
		ElseIf lVldLaXLo
			lRet := (cEnt == FWFLDGET('TFQ_ENTORI')) .and. (cCdEnt == FWFLDGET('TFQ_ORIGEM'))
			EndIf
		
		EndIf
ElseIf	cTab == "TE2"
	DbSelectArea("TFP")	// HISTORICO MOVIMENTACAO MUNICAO
				
	If FwFldGet("TFQ_ENTORI") == "1"
		TFP->(DbSetOrder(7))
	Else
		TFP->(DbSetOrder(8))
	EndIf
	
	If !TFP->(DbSeek(xFilial("TFP") + FwFldGet("TFQ_ENTORI") + FwFldGet("TFQ_ORIGEM") + FwFldGet('TFO_PRODUT')))
		Help( ,, "At880VIMV",, STR0072, 1, 0 )//'Alocação','Esse armamento não está alocado na Origem informada!'
		lRet := .F.
	EndIf
	
EndIf	

RestArea(aArea)
	 
Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880VldGuia

Verifica se o Numero da Guia ou a justificativa foram preenchidas
@author Serviços
@since 28/08/13
@version P11 R9

@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At880VldGuia(oMdl)
Local lRet	:= .T.
Local nI := 0

Default oMdl := nil

If !Empty(oMdl)
	For nI := 1 To oMdl:Length()
		oMdl:GoLine(nI)

		//Verifica se o campo Numero da Guia está preenchido
		If		!oMdl:IsDeleted() .and. oMdl:GetValue('TFO_LGUIA') == '1' .and. Empty(oMdl:GetValue('TFO_NRGUIA'))
			Help( ,, "At880VldGuia",, STR0012, 1, 0 ) //'Alocação','Preencha o Numero da Guia'
			lRet	:= .F.
			//Verifica se o ocampo Justificativa está preenchido
		ElseIf	!oMdl:IsDeleted() .and. oMdl:GetValue('TFO_LGUIA') == '2' .and. Empty(FwFldGet("TFQ_JUSTIF"))
			Help( ,, "At880VldGuia",, STR0013, 1, 0 ) //'Alocação','Preencha a Justificativa'
			lRet	:= .F.
		EndIf
	
		// Havendo um caso, abandona.
		If !lRet
			Exit	
	EndIf	
	Next nI
EndIf
		
Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880VldStat

Verifica o Status da Arma ou Colete e verifica se é possivel a sua movimentação

@param cItMov,caractere,Tipo do Armamento
@param cItCod,caractere,Codigo do armamento
@param cMotivo,caractere,Motivo da movimentação

@sample At880VldStat(cItMov,cItCod,cMotivo)

@author Serviços
@since 28/08/13
@version P11 R9

@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At880VldStat(cItMov,cItCod,cMotivo)
Local lRet		:= .F.
Local aArea	:= GetArea()

Default cItCod := FwFldGet("TFQ_ITARMA")

If Empty(cMotivo)
	Help( ,, "At880VldStat",, STR0064, 1, 0 ) //'Alocação','Informe o Motivo para a Movimentação!'
Else
	Do Case
		Case cItMov == itARMA
			DbSelectArea("TE0")
			TE0->(DbSetOrder(1))
				
			If TE0->(DbSeek(xFilial("TE0") + cItCod))
				//Verifica o tipo do motivo e verifica o Status		
				If cMotivo == mtIMPLANTACAO .Or. cMotivo == mtMANUTENCAO .Or. cMotivo == mtREFORCO
					If TE0->TE0_SITUA == "1" .Or. TE0->TE0_SITUA == "2" .Or. TE0->TE0_SITUA == "8"
						lRet := .T.
					EndIf
				ElseIf cMotivo == mtDESCARTE
					If TE0->TE0_SITUA == "1" .Or. TE0->TE0_SITUA == "2" .Or. TE0->TE0_SITUA == "8" .Or. TE0->TE0_SITUA == "9"
						lRet := .T.
					EndIf
				EndIf
			
				If !lRet
					Help( ,, "At880VldStat",, STR0014, 1, 0 ) //'Alocação','O Status do Armamento não permite movimentação!'
				EndIf
			EndIf
		Case cItMov == itCOLETE
			DbSelectArea("TE1")
			TE1->(DbSetOrder(1))
				
			If TE1->(DbSeek(xFilial("TE1") + cItCod))
				//Verifica o tipo do motivo e verifica o Status		
				If cMotivo == mtIMPLANTACAO .Or. cMotivo == mtMANUTENCAO .Or. cMotivo == mtREFORCO
					If TE1->TE1_SITUA == "1" .Or. TE1->TE1_SITUA == "2" .Or. TE1->TE1_SITUA == "8"
						lRet := .T.
					EndIf
				ElseIf cMotivo == mtDESCARTE
					If TE1->TE1_SITUA == "1" .Or. TE1->TE1_SITUA == "2" .Or. TE1->TE1_SITUA == "8" .Or. TE1->TE1_SITUA == "9"
						lRet := .T.
					EndIf
				EndIf
			
				If !lRet
					Help( ,, "At880VldStat",, STR0014, 1, 0 )//'Alocação','O Status do Armamento não permite movimentação!'
				EndIf
			EndIf
		Case cItMov == itMUNICAO
			DbSelectArea("TE2")
			TE2->(DbSetOrder(1))
		
			If TE2->(DbSeek(xFilial("TE2") + cItCod))
				lRet := .T.
			Else
				lRet := .F.	
			Endif

	EndCase
EndIf
RestArea(aArea)
Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880VldSaldo
	Verifica o Saldo do local de origem informado
@param oMdl,objeto,Objeto de dados sendo editado.

@sample At880VldSaldo(oMdl)
@author Serviços
@since 28/08/13
@version P11 R9

@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At880VldSaldo(oMdl)
Local lRet			:= .T.
Local aArea		:= GetArea()
Local cItCod		:= oMdl:GetValue('TFO_ITCOD')
Local nQtde		:= oMdl:GetValue('TFO_QTDE')
Local nCargas	:= 0

If FwFldGet("TFQ_ENTORI") == "1"
	//Atualiza o Saldo do Local Interno Selecionada para a Movimentação
	DbSelectArea("TFP")
	TFP->(DbSetOrder(2))
Else
	//Atualiza o Saldo do Local de Alocação Selecionada para a Movimentação
	DbSelectArea("TFP")
	TFP->(DbSetOrder(4))
EndIf

//Verifica se a quantidade informada é maior que o saldo do blister	
If TE2->(DbSeek(xFilial("TE2") + cItCod))	
	If TFP->(DbSeek(xFilial("TFP") + FwFldGet("TFQ_ENTORI") + FwFldGet("TFQ_ORIGEM")))
		If TFP->TFP_SALDO < nQtde
			Help( ,, "At880VldSaldo",, STR0018, 1, 0 )//'Alocação',"A quantidade informada é maior do que está alocado ou é superior ao saldo disponivel para movimentação no Blister relacionado."
			lRet := .F.
		EndIf
	EndIf
EndIf

RestArea(aArea)			

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtVldLocMun

Valida se o local informado realmente existe para a munição informada
@sample AtVldLocMun(cCodigo) 
@author Serviços
@since 28/08/13
@version P11 R9
@Param cCodigo, Codigo do Local informado no campo TFQ_ORIMUN

@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Function AtVldLocMun(cCodigo)
Local lRet		:= .T.
Local nY		:= 0	
Local oModel	:= Nil
Local aArea	:= GetArea()

aCmpBco := At880QryLoc()
	
If FwFldGet("TFQ_ENTORI") == "1"
		//Faz a Busca para Locais Internos
	nY := aScan(aCmpBco,{|x| AllTrim(x[3]) == Alltrim(cCodigo)})
		
	If nY == 0
		Help( ,, "AtVldLocMun",, STR0020, 1, 0 )//"Codigo",'O codigo informado não está relacionado'
		lRet := .F.
	EndIf
Else
		//Faz a Busca para Locais de Atendimento
	nY := aScan(aCmpBco,{|x| AllTrim(x[4]) == Alltrim(cCodigo)})
		
	If nY == 0
		Help( ,, "AtVldLocMun",, STR0020, 1, 0 )//"Codigo",'O codigo informado não está relacionado'
		lRet := .F.
	EndIf
		
EndIf

RestArea(aArea)

Return(lRet)
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880VldLoc

Verifica se o local de destino não é igual ao de origem
@author Serviços
@since 28/08/13
@version P11 R9

@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880VldLoc()
Local lRet 	:= .T.
Local aArea	:= GetArea()

Do Case
	Case FwFldGet("TFQ_ITMOV") == itARMA
		DbSelectArea("TE0")
		TE0->(DbSetOrder(1))
		If TE0->(DbSeek(xFilial("TE0") + FwFldGet("TFQ_ITARMA")))
			If TE0->TE0_ENTIDA == "TER" .And. FwFldGet("TFQ_ENTDES") == edEMPRESA
				
				DbSelectArea("TER")
				TER->(DbSetOrder(1))
				
				If TER->(DbSeek(xFilial("TER") + FwFldGet("TFQ_DESTIN")))
					If Alltrim(FwFldGet("TFQ_DESTIN")) == Alltrim(FwFldGet("TFQ_ORIGEM"))
						Help( ,, "At880VldLoc",, STR0021, 1, 0 )//'Alocação','Local de Origem é o mesmo de destino'
						lRet := .F.
					EndIf	
				EndIf
			ElseIf TE0->TE0_ENTIDA == "ABS" .And. FwFldGet("TFQ_ENTDES") == edCLIENTE
				
				DbSelectArea("ABS")
				ABS->(DbSetOrder(1))
				
				If ABS->(DbSeek(xFilial("ABS") + FwFldGet("TFQ_DESTIN")))
					If Alltrim(FwFldGet("TFQ_DESTIN")) == Alltrim(FwFldGet("TFQ_ORIGEM"))
						Help( ,, "At880VldLoc",, STR0021, 1, 0 )//'Alocação','Local de Origem é o mesmo de destino'
						lRet := .F.
					EndIf	
				EndIf	
			EndIf
		EndIf

	Case FwFldGet("TFQ_ITMOV") == itCOLETE
		DbSelectArea("TE1")
		TE1->(DbSetOrder(1))
		If TE1->(DbSeek(xFilial("TE1") + FwFldGet("TFQ_ITARMA")))
			If TE1->TE1_ENTIDA == "TER" .And. FwFldGet("TFQ_ENTDES") == edEMPRESA
				
				DbSelectArea("TER")
				TER->(DbSetOrder(1))
				
				If TER->(DbSeek(xFilial("TER") + FwFldGet("TFQ_DESTIN")))
					If Alltrim(FwFldGet("TFQ_DESTIN")) == Alltrim(FwFldGet("TFQ_ORIGEM"))
						Help( ,, "At880VldLoc",, STR0021, 1, 0 )//'Alocação','Local de Origem é o mesmo de destino'
						lRet := .F.
					EndIf	
				EndIf
			ElseIf TE1->TE1_ENTIDA == "ABS" .And. FwFldGet("TFQ_ENTIDA") == "1"
				DbSelectArea("ABS")
				ABS->(DbSetOrder(1))
				If ABS->(DbSeek(xFilial("ABS") + FwFldGet("TFQ_DESTIN")))
					If Alltrim(FwFldGet("TFQ_DESTIN")) == Alltrim(FwFldGet("TFQ_ORIGEM"))
						Help( ,, "At880VldLoc",, STR0021, 1, 0 )//'Alocação','Local de Origem é o mesmo de destino'
						lRet := .F.
					EndIf	
				EndIf	
			EndIf
		EndIf
		
	Case FwFldGet("TFQ_ITMOV") == itMUNICAO
		If FwFldGet("TFQ_ENTORI") == eoLOCINTER .AND. FwFldGet("TFQ_ENTDES") == edEMPRESA
				DbSelectArea("TER")
				TER->(DbSetOrder(1))
				If TER->(DbSeek(xFilial("TER") + FwFldGet("TFQ_DESTIN")))
					If Alltrim(FwFldGet("TFQ_DESTIN")) == Alltrim(FwFldGet("TFQ_ORIMUN"))
						Help( ,, "At880VldLoc",, STR0021, 1, 0 )//'Alocação','Local de Origem é o mesmo de destino'
						lRet := .F.
					EndIf	
				EndIf
		ElseIf FwFldGet("TFQ_ENTORI") == eoLOCATEND .AND. FwFldGet("TFQ_ENTDES") == edCLIENTE
			DbSelectArea("ABS")
			ABS->(DbSetOrder(1))
				
			If ABS->(DbSeek(xFilial("ABS") + FwFldGet("TFQ_DESTIN")))
				If Alltrim(FwFldGet("TFQ_DESTIN")) == Alltrim(FwFldGet("TFQ_ORIMUN"))
					Help( ,, "At880VldLoc",, STR0021, 1, 0 )//'Alocação','Local de Origem é o mesmo de destino'
					lRet := .F.
				EndIf	
			EndIf		
		EndIf
		
EndCase
RestArea(aArea)
Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880VldCons

Validação do campo de codigo das Armas conforme o que foi selecionado no campo TEU_TPARMA
@sample 	At880VldCons() 
@since		11/09/2013 
@version P11 R9
     
@return 	lRet, Retorno do ExistCPO de acordo com o que foi selecionado no campo TEU_TPARMA
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880VldCons()
Local lRet	:= .F.
Do Case
	Case FwFldGet("TFO_ITMOV") == "1"
		lRet := ExistCpo("TE0")

	Case FwFldGet("TFO_ITMOV") == "2"
		lRet := ExistCpo("TE1")
		
	Case FwFldGet("TFO_ITMOV") == "3"
		lRet := ExistCpo("TE2")
	
EndCase
Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} FA880ENT

Chama a Consulta Padrão conforme o que foi selecionado no campo TFQ_ENTDES
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function FA880ENT(cChave)
Local oModel		:= FwModelActive()
Local oModelTFQ 	:= oModel:GetModel('TFQMASTER')
Local cTpEntOri	:= oModelTFQ:GetValue("TFQ_ENTORI") 
Local cTpEntDes	:= oModelTFQ:GetValue("TFQ_ENTDES")
Local lRet			:= .T.
Local aArea		:= GetArea()

Default cChave	:= ""

SaveInter()

If cChave == 'ORIGEM'
	If		cTpEntOri == eoLOCATEND  
		lRet := Conpad1( NIL,NIL,NIL,"ABS")
	ElseIf	cTpEntOri == eoLOCINTER	
		lRet := ConPad1(Nil,Nil,Nil,"TER")
	EndIf
Else
	If		cTpEntDes == edCLIENTE  
		lRet := Conpad1( NIL,NIL,NIL,"ABS")
	ElseIf	cTpEntDes == edEMPRESA	
		lRet := ConPad1(Nil,Nil,Nil,"TER")
	EndIf
EndIf
RestInter()
RestArea(aArea)
Return (lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880RetEnt

Retorna a variavel da memoria do model, para a consulta especifica
@sample 	At880RetEnt() 
@since		11/09/2013
@version P11 R9
     
@return 	cCodigo, CHARACTER, codigo do Armamento.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880RetEnt(cChave)
Local oModel		:= FwModelActive()
Local oModelTFQ 	:= oModel:GetModel('TFQMASTER')
Local cTpEntOri	:= oModelTFQ:GetValue("TFQ_ENTORI") 
Local cTpEntDes	:= oModelTFQ:GetValue("TFQ_ENTDES")
Local cCodigo	:= ""		

Default cChave	:= ""
	
If cChave == 'ORIGEM'
	If		cTpEntOri == eoLOCATEND  
		cCodigo := ABS->ABS_LOCAL
	ElseIf	cTpEntOri == eoLOCINTER	
		cCodigo := TER->TER_CODIGO
	EndIf
Else
	If		cTpEntDes == edCLIENTE  
		cCodigo := ABS->ABS_LOCAL
	ElseIf	cTpEntDes == edEMPRESA	
		cCodigo := TER->TER_CODIGO
	EndIf
EndIf

Return(cCodigo)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880LDsc

Realiza o preenchimento da descrição do Local

@param	cLocal,caractere,Tipo do Local de Atendimento

@sample At880LDsc(cLocal)
@author Serviços
@since 20/08/13
@version P11 R9
@return cRet,caractere,Retorna a descrição do Local selecionado
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880LDsc(cLocal)
Local cRet		:= ""
Local aArea		:= GetArea()
Local aIdLoc	:= {{'TFQ_ENTORI','TFQ_ORIGEM'},{'TFQ_ENTDES','TFQ_DESTIN'}}
Local cCampo	:= ''

Default cLocal:= ""

If cLocal == 'ORIGEM'
	cCampo	:= 'TFQ_ORIGEM'
	If		FwFldGet('TFQ_ENTORI') == "1"
		cTab := 'TER'	// Locais Internos - Empresa
	ElseIf	FwFldGet('TFQ_ENTORI') == "2"
		cTab := 'ABS'	// Locais de Atendimento - Cliente
	EndIf
Else
	cCampo	:= 'TFQ_DESTIN'
	If		FwFldGet('TFQ_ENTDES') == "1"
		cTab := 'ABS'	// Locais de Atendimento - Cliente
	ElseIf	FwFldGet('TFQ_ENTDES') == "2"
		cTab := 'TER'	// Locais Internos - Empresa
	EndIf
EndIf
cRet := Alltrim(Posicione(cTab,1,xFilial(cTab)+FwFldGet(cCampo),cTab+"_DESCRI"))
RestArea(aArea)
Return(cRet)
		
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880VldOri
	 
Validação do campo de codigo de origem
@sample 	At880VldOri() 
@since		08/07/2015 
@version P11 R9
		
@return 	lRet, Retorno do ExistCPO de acordo com a configuração do campo TFQ_ENTORI e com o código informado no TFQ_ORIGEM
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880VldOri(oMdl,cIdCall)
Local lRet	:= .F.

Do Case
	Case FwFldGet("TFQ_ENTORI") == eoLOCINTER
		lRet := ExistCpo("TER",FwFldGet(cIdCall))

	Case FwFldGet("TFQ_ENTORI") == eoLOCATEND
		lRet := ExistCpo("ABS",FwFldGet(cIdCall))

EndCase
Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880VldEnt

Validação do campo de codigo de destino
@sample 	At780VldEnt() 
@since		11/09/2013 
@version P11 R9
     
@return 	lRet, Retorno do ExistCPO de acordo com o que foi selecionado no campo TEU_TPARMA
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880VldEnt()
Local lRet	:= .F.

Do Case
	Case FwFldGet("TFQ_ENTDES") == edCLIENTE
		lRet := ExistCpo("ABS")

	Case FwFldGet("TFQ_ENTDES") == edEMPRESA
		lRet := ExistCpo("TER")
	
EndCase
Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880Resp

Realiza o preenchimento da descrição do Responsavel
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880Resp()
Local cDesc		:= ""
Local aArea		:= GetArea()

cDesc := Alltrim(Posicione("AA1",1,xFilial("AA1")+FwFldGet("TFQ_RESTRA"),"AA1_NOMTEC"))

RestArea(aArea)

Return(cDesc)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880Atend

Realiza o preenchimento do nome e dados do atendente responsavel pelo armamento
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880Atend()
Local cDesc		:= ""
Local aArea		:= GetArea()
Local oModel		:= Nil

DbSelectArea("AA1")
AA1->(DbSetOrder(1))

If AA1->(DbSeek(xFilial("AA1")+FwFldGet("TFR_CODTEC")))
	oModel := FWModelActive()

	oModel:setValue("TFRFUNC","TFR_FUNCAO"	,AA1->AA1_FUNCAO)
	oModel:setValue("TFRFUNC","TFR_CDFUNC"	,AA1->AA1_CDFUNC)
	oModel:setValue("TFRFUNC","TFR_TURNO"	,AA1->AA1_TURNO)

	cDesc := AA1->AA1_NOMTEC
	
EndIf

RestArea(aArea)

Return(cDesc)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880IniArma 

Realiza a Inicialização padrão do armamento
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpC:Retorna a descrição da Arma
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880IniArma(cItem,cArma)
Local cDesc		:= ""
Local aArea		:= GetArea()
Local cProd		:= ""

Default cItem		:= ""
Default cArma		:= ""

If !Empty(cItem) .And. !Empty(cArma)
	Do Case
		Case cItem == "1"
			cProd := Posicione("TE0",1,xFilial("TE0") + cArma ,"TE0->TE0_CODPRO")	
			cDesc := Posicione("SB1",1,xFilial("SB1") + cProd ,"SB1->B1_DESC")

		Case cItem == "2"
			cProd := Posicione("TE1",1,xFilial("TE1") + cArma ,"TE1->TE1_CODPRO")
			cDesc := Posicione("SB1",1,xFilial("SB1") + cProd ,"SB1->B1_DESC")
		
		Case cItem == "3"			
			cDesc := Posicione("SB1",1,xFilial("SB1") + cArma ,"SB1->B1_DESC")
	
	EndCase
EndIf
RestArea(aArea)
Return(cDesc)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880IniDscLoc 

Realiza a Inicialização padrão da descrição do local 
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpC:Retorna a descrição do local de origem
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880IniDscLoc(cEntida,cLocal)
Local cDesc		:= ""
Local aArea		:= GetArea()
Local lModoInc	:= .F.

Default cEntida		:= ""
Default cLocal		:= ""

If Type('INCLUI') == 'L'
	lModoInc := INCLUI
EndIf 

If !lModoInc .And. !Empty(cEntida) .And. !Empty(cLocal)
	Do Case
		Case cEntida == eoLOCINTER
			cDesc := Alltrim(Posicione("TER",1,xFilial("TER")+ cLocal ,"TER_DESCRI"))

		Case cEntida == eoLOCATEND
			cDesc := Alltrim(Posicione("ABS",1,xFilial("ABS")+ cLocal ,"ABS_DESCRI"))
	
	EndCase
EndIf

RestArea(aArea)

Return(cDesc)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880IniEnt 

Realiza a Inicialização padrão da descrição do local destino
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpC:Retorna a descrição do Local de destino
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880IniEnt(cEntida,cLocal)
Local cDesc		:= ""
Local aArea		:= GetArea()
Local lModoInc	:= .F.

Default cEntida		:= ""
Default cLocal		:= ""

If Type('INCLUI') == 'L'
	lModoInc := INCLUI
EndIf 

If !lModoInc .And. !Empty(cEntida) .And. !Empty(cLocal)

	Do Case
		Case cEntida == edCLIENTE
			cDesc := Alltrim(Posicione("ABS",1,xFilial("ABS")+ cLocal ,"ABS_DESCRI"))

		Case cEntida == edEMPRESA
			cDesc := Alltrim(Posicione("TER",1,xFilial("TER")+ cLocal ,"TER_DESCRI"))
	
	EndCase
EndIf
RestArea(aArea)
Return(cDesc)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880WMnt

Habilita ou desabilita os campos de manutenção 
@sample 	At880WMnt() 
@since		11/09/2013 
@version P11 R9
     
@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880WMnt()                                                   
Local lRet := .F.
Local oMdlArma	:= oModel:GetModel('TFOARMA')
Local nI			:= 0

If INCLUI .and. (FwFldGet('TFQ_MOTIVO') == mtMANUTENCAO)
	lRet := .T.
EndIf

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880ConsLoc

Realiza a Consulta especifica para os Locais de origem da Munição
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880ConsLoc()
Local lRet			:= .T.
Local cQuery		:= ""
Local cDscCmp		:= ""
Local cConteudo	:= ""
Local cCodigo		:= ""
Local cEntida		:= ""
Local cLocal		:= ""
Local lOk			:= .F.
Local aArea		:= GetArea()

Local oModel				//Modelo atual
Local oDlgCmp				//Dialog
Local oPanel 				//Objeto Panel
Local oFooter				//Rodapé
Local oListBox			//Grid campos
Local oOk					//Objeto Confirma 
Local oCancel				//Objeto Cancel

aCmpBco := At880QryLoc()

If !Empty(aCmpBco)

	//	Cria a tela para a pesquisa dos campos e define a area a ser utilizada na tela 
	Define MsDialog oDlgCmp FROM 000, 000 To 350, 550 Pixel
			
	// Cria o panel principal
	@ 000, 000 MsPanel oPanel Of oDlgCmp Size 250, 340 // Coordenada para o panel
	oPanel:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
		
	// Criação do grid para o panel	
	oListBox := TWBrowse():New( 40,05,204,100,,{STR0019,STR0022,STR0023,STR0024,STR0025,STR0026,STR0027},,oPanel,,,,,,,,,,,,.F.,,.T.,,.F.,,,) // "Codigo","Entidade","Codigo Interno","Codigo do Local", "Movimentação", "Saldo", "Lote"
	oListBox:SetArray(aCmpBco) // Atrela os dados do grid com a matriz
	oListBox:bLine := { ||{aCmpBco[oListBox:nAT][1],aCmpBco[oListBox:nAT][2],aCmpBco[oListBox:nAT][3],aCmpBco[oListBox:nAT][4],aCmpBco[oListBox:nAT][5],aCmpBco[oListBox:nAT][6],aCmpBco[oListBox:nAT][7]}} // Indica as linhas do grid
	oListBox:bLDblClick := { ||Eval(oOk:bAction), oDlgCmp:End()} // Duplo clique executa a ação do objeto indicado
	oListBox:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do browse
		
	// Cria o panel para os botoes	
	@ 000, 000 MsPanel oFooter Of oDlgCmp Size 000, 010 // Corrdenada para o panel dos botoes (size)
	oFooter:Align   := CONTROL_ALIGN_BOTTOM //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
			
	// Botoes para o grid auxiliar	
	@ 000, 000 Button oCancel Prompt STR0028  Of oFooter Size 030, 000 Pixel //Cancelar
	oCancel:bAction := { || lOk := .F., oDlgCmp:End() }
	oCancel:Align   := CONTROL_ALIGN_RIGHT
		
	@ 000, 000 Button oOk     Prompt STR0029 Of oFooter Size 030, 000 Pixel //Confirmar
	oOk:bAction     := { || lOk := .T.,cCodigo:=aCmpBco[oListBox:nAT][3],cEntida:=aCmpBco[oListBox:nAT][2],cLocal:=aCmpBco[oListBox:nAT][4],oDlgCmp:End() } // Acao ao clicar no botao
	oOk:Align       := CONTROL_ALIGN_RIGHT // Alinhamento do botao referente ao panel
		
		// Ativa a tela exibindo conforme a coordenada
	Activate MsDialog oDlgCmp Centered
			
	//Utilizar o modelo ativo para substituir os valores das variaves de memoria		
	oModel	:= FWModelActive()
		
	If lOk
		If cEntida == "1"
			cTab	:= "TER"
			oModel:SetValue("TFQMASTER","TFQ_ENTIDA", cEntida)
			oModel:SetValue("TFQMASTER","TFQ_ORIMUN", cCodigo)
		ElseIf cEntida == "2"
			cTab := "ABS"
			oModel:SetValue("TFQMASTER","TFQ_ENTIDA", cEntida)
			oModel:SetValue("TFQMASTER","TFQ_ORIMUN", cLocal)
		EndIf
	EndIf
Else
	Help( ,, "At880ConsLoc",, STR0030, 1, 0 )//"Alocação,'Não há alocação para essa munição, selecione outro lote'
EndIf

RestArea(aArea)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT880RetLoc

Retorna a variavel da memoria do model, para a consulta especifica
@sample 	AT840RetLoc() 
@since		11/09/2013
@version P11 R9
     
@return 	cCodigo, CHARACTER, conteudo da variavel de memoria.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880RetLoc()
Return (FwFldGet("TFQ_ORIMUN"))

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880QryLoc

Realiza a Query para a consulta especifica do Local de Alocação da Munição
@sample 	At780Query() 
@since		11/09/2013 
@version P11 R9
     
@return 	aRet, Array com os Responsaveis
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At880QryLoc()
Local aRet		:= {}
Local cAlias	:= GetNextAlias()
Local cCond	:= FwFldGet("TFQ_ITARMA")	//Codigo do Armamento
Local cEntida	:= FwFldGet("TFQ_ENTORI") 	//1=Local Interno, 2=Local de Atendimento
Local cMovim	:= ""							//1=Saldo Cofre,2=Saldo no Cliente(Local de Atendimento)	

If Select("cAlias") > 0 
	(cAlias)->(DbCloseArea())
Endif

If !Empty(cEntida)
	
	If cEntida == "1"
		cMovim := "1"
	ElseIf cEntida == "2"
		cMovim := "2"
	EndIf
	
	BeginSQL alias cAlias		
		SELECT TFP.*
		FROM
			%Table:TFP% TFP
		WHERE
			TFP.TFP_FILIAL = %xfilial:TFP%
			AND
			TFP.TFP_ENTIDA = %Exp:cEntida% 
			AND
			TFP.TFP_MOVIM = %Exp:cMovim% 
			AND
			TFP.TFP_SALDO > 0
			AND
			TFP.TFP_CODMUN = %Exp:cCond%
			AND 
			TFP.%NotDel%  	
	EndSQL	
	
	While (cAlias)->(!Eof())
	
		AAdd( aRet, { 	(cAlias)->TFP_CODIGO,;
							(cAlias)->TFP_ENTIDA,;
							(cAlias)->TFP_CODINT,;
							(cAlias)->TFP_CODLOC,;
							(cAlias)->TFP_MOVIM,;
							(cAlias)->TFP_SALDO,;
							(cAlias)->TFP_LOTE } )
		
		(cAlias)->(DbSkip())
		
	EndDo
	(cAlias)->(DbCloseArea())
EndIf

Return(aRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880LocMun

Realiza o preenchimento da descrição do Local
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880LocMun()
Local cDescLoc 	:= ""
Local aArea		:= GetArea()

If FwFldGet("TFQ_ENTORI") == eoLOCINTER
	
	cDescLoc	:= Posicione("TER",1,xFilial("TER") + FwFldGet("TFQ_ORIMUN"),"TER->TER_DESCRI")
	
ElseIf FwFldGet("TFQ_ENTORI") == eoLOCATEND
	
	cDescLoc	:= Posicione("ABS",1,xFilial("ABS") + FwFldGet("TFQ_ORIMUN"),"ABS->ABS_DESCRI")
	
EndIf

RestArea(aArea)

Return(cDescLoc)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880VldMov

Limpa os campos de descrição codigo dependendo da seleção do campo TFQ_ITMOV
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880VldMov()
Local lRet			:= .T.
Local oModel		:= FWModelActive()

If 	FwFldGet("TFQ_ITMOV") == itARMA .Or. FwFldGet("TFQ_ITMOV") == itCOLETE
	
	//Limpa o codigo da arma quando ela for alterada
	If !Empty(FwFldGet("TFQ_ITARMA"))
		oModel:LoadValue("TFQMASTER","TFQ_ITARMA", "")
		oModel:LoadValue("TFQMASTER","TFQ_DITEM", "")
	EndIf
	
	//Limpa a Origem da Arma
	If !Empty(FwFldGet("TFQ_ORIGEM")) .OR. !Empty(FwFldGet("TFQ_DSCLOC"))
		oModel:LoadValue("TFQMASTER","TFQ_ORIGEM", "")
		oModel:LoadValue("TFQMASTER","TFQ_DSCLOC", "")
	EndIf
	
	//Tira o valor do campo lote quando for selecionado Arma ou colete
	If !Empty(FwFldGet("TFQ_LOTE"))
		oModel:SetValue("TFQMASTER","TFQ_LOTE", "")
	EndIf
	
	If !Empty(FwFldGet("TFQ_ENTORI"))
		oModel:SetValue("TFQMASTER","TFQ_ENTORI", "")
	EndIf
	
	If !Empty(FwFldGet("TFQ_ORIMUN"))
		oModel:SetValue("TFQMASTER","TFQ_ORIMUN", "")
	EndIf
	
	If !Empty(FwFldGet("TFQ_DSCMUN"))
		oModel:LoadValue("TFQMASTER","TFQ_DSCMUN", "")
	EndIf
	
	If !Empty(FwFldGet("TFQ_QTDMUN"))
		oModel:LoadValue("TFQMASTER","TFQ_QTDMUN", 0)
	EndIf
	
ElseIf	FwFldGet("TFQ_ITMOV") == itMUNICAO 
	
	//Limpa o codigo da arma quando ela for alterada
	If !Empty(FwFldGet("TFQ_ITARMA"))
		oModel:LoadValue("TFQMASTER","TFQ_ITARMA", "")
		oModel:LoadValue("TFQMASTER","TFQ_DITEM", "")
	EndIf
	
	//Limpa a Origem da Arma
	If !Empty(FwFldGet("TFQ_ORIGEM")) .OR. !Empty(FwFldGet("TFQ_DSCLOC"))
		oModel:LoadValue("TFQMASTER","TFQ_ORIGEM", "")
		oModel:LoadValue("TFQMASTER","TFQ_DSCLOC", "")
	EndIf
	
	//Tira o valor do campo Origem e descrição da origem quando for selecionado munição
	If !Empty(FwFldGet("TFQ_ORIGEM"))
		oModel:SetValue("TFQMASTER","TFQ_ORIGEM", "")
	EndIf
	
	If !Empty(FwFldGet("TFQ_DSCLOC"))
		oModel:SetValue("TFQMASTER","TFQ_DSCLOC", "")
	EndIf	
		
EndIf
	
Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880CleanEnt

Limpa os campos de descrição codigo dependendo da seleção do campo TFQ_ENTDES
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880CleanEnt()
Local lRet			:= .T.
Local oModel		:= FWModelActive()

//Antes de Limpar verifica se é manutenção, onde só será permitida
//a movimentação para a empresa
If FwFldGet("TFQ_ENTDES") == edCLIENTE .And. (FwFldGet("TFQ_MOTIVO") == mtMANUTENCAO .Or. FwFldGet("TFQ_MOTIVO") == mtDESCARTE)
	Help( ,, "At880CleanEnt",, STR0031, 1, 0 )//'Para movimentação de Manutenção ou Descarte, só será possivel selecionar a Empresa'
	lRet := .F.	
EndIf

If 	lRet .And. (FwFldGet("TFQ_ENTDES") == edCLIENTE .Or. FwFldGet("TFQ_ENTDES") == edEMPRESA)
	
	//Limpa o codigo de destino e sua descrição	
	If !Empty(FwFldGet("TFQ_DESTIN"))
		oModel:LoadValue("TFQMASTER","TFQ_DESTIN", "")
		oModel:LoadValue("TFQMASTER","TFQ_DDESTI", "")
	EndIf
			
EndIf
	
Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880ClnOri

Limpa os campos de descrição codigo dependendo da seleção do campo TFQ_ENTORI
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880ClnOri()
Local lRet		:= .T.
Local oModel	:= FWModelActive()

If (FwFldGet("TFQ_ENTORI") == eoLOCINTER .Or. FwFldGet("TFQ_ENTORI") == eoLOCATEND)
	
	//Limpa o codigo de Origem e sua descrição	
	If !Empty(FwFldGet("TFQ_ORIMUN"))
		oModel:LoadValue("TFQMASTER","TFQ_ORIMUN", "")
		oModel:LoadValue("TFQMASTER","TFQ_DSCMUN", "")
	EndIf
			
EndIf
	
Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880MntClean

Limpa os campos de descrição codigo dependendo da seleção do campo TFQ_ENTDES
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At880MntClean()
Local lRet			:= .T.
Local oModel		:= FWModelActive()

oModel:LoadValue("TFQMASTER","TFQ_CDRESP", "")
oModel:LoadValue("TFQMASTER","TFQ_TPMNT" , "")
oModel:LoadValue("TFQMASTER","TFQ_MOTMNT", "")

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880SumIt
	Efetua uma contagem dos itens não deletados da grade.
	
@author Serviços
@param oMdl,objeto,Grade de Armamentos
@sample	At880SumIt(oMdl)
@since 20/08/13
@version P11 R9
@return nRet,numerico,A quantidade de itens não deletados.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880SumIt(oMdl)
Local nRet	:= 0
Local nI	:= 0
Local cField := ""

If oMdl:HasField('TFO_ITCOD')
	cField := 'TFO_ITCOD'
ElseIf oMdl:HasField('TFO_PRODUT')
	cField := 'TFO_PRODUT'
EndIf	

If !Empty(oMdl) .And. !Empty(cField)
	If	!( oMdl:IsEmpty() )
		For nI := 1 To oMdl:Length()
			oMdl:GoLine( nI )
			If !oMdl:IsDeleted() .and. !Empty(oMdl:GetValue(cField))
				nRet++
			EndIf
			
		Next nI
	EndIf
EndIf
Return nRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880Status

Verifica a Data de movimentação para realizar a efetivação da movimentação
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880Status(oMdl,lMuni)
Local lRet	:= .T.
Local nI := 0

Default oMdl := nil
Default lMuni := .F.

If FwFldGet("TFQ_STATUS") == stAGENDADA
	//Verifica se a data de movimentação é menor ou igual a database
	If FwFldGet("TFQ_DMOVIM") < DDataBase
		Help( ,, "At880Status",, STR0033, 1, 0 )//'Não é possivel agendar uma movimentação com data menor que a database'
		lRet := .F.
	EndIf
EndIf

If FwFldGet("TFQ_STATUS") == stEFETIVADA
	//Verifica se a data de movimentação é menor ou igual a database
	If FwFldGet("TFQ_DMOVIM") > DDataBase
		Help( ,, "At880Status",, STR0034, 1, 0 )//'A data de movimentação não pode ser maior que a database para ser efetivada'
		lRet := .F.
	EndIf	
EndIf

If lRet .and. !Empty(oMdl)
	For nI := 1 To oMdl:Length()

		oMdl:GoLine( nI )
		
		If !oMdl:IsDeleted()
			//Valida se a data de retorno foi preenchida quando foi selecionado previsão de retorno
			If oMdl:GetValue("TFO_LRET") == "1" .and. Empty(oMdl:GetValue("TFO_DTRET")) 
				Help( ,, "At880Status",, STR0035, 1, 0 ) //'Informe uma data de retorno'
				lRet := .F.	
			EndIf

			// Verifica a Data de Validade dos Armamentos
			If lRet .And. !lMuni
				lRet := At880VlArm(oMdl:GetValue("TFO_ITMOV"),oMdl:GetValue("TFO_ITCOD"),FwFldGet("TFQ_ENTORI"),FwFldGet("TFQ_ENTDES"))
			EndIf
		EndIf
				
		If !lRet
			Exit	// Havendo um caso, abandona.
		EndIf
		
	Next nI
EndIf

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880DtMovim

Valida a data de retorno e de movimentação
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880DtMovim()
Local lRet	:= .T.

If !Empty(FwFldGet("TFQ_DTRETO"))
	If !FwFldGet("TFQ_DTRETO") > dDataBase
		Help( ,, "At880DtMovim",, STR0036, 1, 0 )
		lRet := .F.	
	EndIf
EndIf

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880SitArma

Função para alterar o Status das Armas
@sample 	At780SitArma() 
@since		11/09/2013 
@version P11 R9

@Param lIniciada,lFinalizado,Indica se o Status voltará ao antigo ou par Em Manutenção
     
@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At880SitArma(cTpArma,cItArma,dRetorno,oMdl)
Local aArea			:= GetArea()
Local cSubLoc		:= ""			//Codigo do SubLocal
Local cDscSub		:= ""			//Descrição do SubLocal
Local cStatus		:= ""			//Status de Armamento

Default oMdl		:= FwModelActive()
Default cTpArma		:= FwFldGet("TFQ_ITMOV")
Default cItArma		:= FwFldGet("TFQ_ITARMA")
Default dRetorno	:= FwFldGet("TFQ_DTRETO")  

Do Case	
	Case cTpArma == itARMA
		
		DbSelectArea("TE0")
		TE0->(DbSetOrder(1))
							
		If TE0->(DbSeek(xFilial("TE0")+ cItArma))
			
			//Altera o Status para Implantado	
			RecLock("TE0",.F.)
			
			If oMdl:GetValue("TFQMASTER","TFQ_ENTDES") == edCLIENTE
					REPLACE TE0_SITUA WITH "2"
				
					//Altera o local de alocação
					REPLACE TE0_LOCAL 	WITH oMdl:GetValue("TFQMASTER","TFQ_DESTIN")
					REPLACE TE0_CLIDES 	WITH oMdl:GetValue("TFQMASTER","TFQ_DDESTI")
						
					//Verifica se a origem é sublocal e grava o local
					cSubLoc := At880SubLoc(oMdl:GetValue("TFQMASTER","TFQ_DESTIN"),@cDscSub)
					
					If !Empty(cSubLoc)
						REPLACE TE0_POSTAL 	WITH cSubLoc
						REPLACE TE0_DSCPOS	WITH cDscSub
					Else
						REPLACE TE0_POSTAL 	WITH ""
						REPLACE TE0_DSCPOS	WITH ""
					EndIf	
					
					REPLACE TE0_ENTIDA WITH "ABS"
					REPLACE TE0_DTALOC WITH oMdl:GetValue("TFQMASTER","TFQ_DMOVIM")
					REPLACE TE0_PRVRET WITH dRetorno
					REPLACE TE0_CODMOV 	With oMdl:GetValue("TFQMASTER","TFQ_CODIGO")
					
					//Grava o registro de Alteração do FREAR
					At880Hist(cItArma,Nil,.T.,.F.,"2")
					
				ElseIf oMdl:GetValue("TFQMASTER","TFQ_ENTDES") == edEMPRESA
					
					If oMdl:GetValue("TFQMASTER","TFQ_MOTIVO") == mtDESCARTE //Descarte
						//Retorna para Ativo
						REPLACE TE0_SITUA WITH "A"
						cStatus := "A"							
					Else
						//Retorna para Ativo
						REPLACE TE0_SITUA WITH "1"
						cStatus := "1"	
					EndIf
					
					//Altera o local de alocação
					REPLACE TE0_LOCAL 	WITH oMdl:GetValue("TFQMASTER","TFQ_DESTIN")
					REPLACE TE0_CLIDES 	WITH oMdl:GetValue("TFQMASTER","TFQ_DDESTI")
					REPLACE TE0_POSTAL 	WITH ""
					REPLACE TE0_DSCPOS	WITH ""	
					REPLACE TE0_ENTIDA WITH "TER"
					REPLACE TE0_DTALOC WITH oMdl:GetValue("TFQMASTER","TFQ_DMOVIM")
					REPLACE TE0_PRVRET	WITH dRetorno
					REPLACE TE0_CODMOV 	With oMdl:GetValue("TFQMASTER","TFQ_CODIGO")
					
					//Grava o registro de Alteração do FREAR
					At880Hist(cItArma,Nil,.T.,.F.,cStatus,oMdl)
					
				EndIf
				
				TE0->(MsUnLock())	
						
		EndIf

	Case cTpArma == itCOLETE
	
		DbSelectArea("TE1")
		TE1->(DbSetOrder(1))
							
		If TE1->(DbSeek(xFilial("TE1")+cItArma))
	
			//Altera o Status para Implantado	
			RecLock("TE1",.F.)
			
			If oMdl:GetModel('TFQMASTER'):GetValue("TFQ_ENTDES") == edCLIENTE
				REPLACE TE1_SITUA WITH "2"
				
				//Altera o local de alocação
				REPLACE TE1_LOCAL 	WITH oMdl:GetModel('TFQMASTER'):GetValue("TFQ_DESTIN")
				REPLACE TE1_CLIDES 	WITH oMdl:GetModel('TFQMASTER'):GetValue("TFQ_DDESTI")
						
				//Verifica se a origem é sublocal e grava o local
				cSubLoc := At880SubLoc(oMdl:GetModel('TFQMASTER'):GetValue("TFQ_DESTIN"),@cDscSub)
					
				If !Empty(cSubLoc)
					REPLACE TE1_POSTAL 	WITH cSubLoc
					REPLACE TE1_DSCPOS	WITH cDscSub
				Else
					REPLACE TE1_POSTAL 	WITH ""
					REPLACE TE1_DSCPOS	WITH ""
				EndIf	
					
				REPLACE TE1_ENTIDA WITH "ABS"
				REPLACE TE1_DTALOC WITH oMdl:GetModel('TFQMASTER'):GetValue("TFQ_DMOVIM")
				REPLACE TE1_PRVRET WITH dRetorno
				REPLACE TE1_CODMOV 	With oMdl:GetModel('TFQMASTER'):GetValue("TFQ_CODIGO")
				//Grava o registro de Alteração do FREAR
				At880Hist(Nil,cItArma,.F.,.T.,"2",oMdl)
					
			ElseIf oMdl:GetModel('TFQMASTER'):GetValue("TFQ_ENTDES") == edEMPRESA
					
				If oMdl:GetModel('TFQMASTER'):GetValue("TFQ_MOTIVO") == mtDESCARTE //Descarte
					//Retorna para Ativo
					REPLACE TE1_SITUA WITH "A"
					cStatus := "A"							
				Else
					//Retorna para Ativo
					REPLACE TE1_SITUA WITH "1"
					cStatus := "1"	
				EndIf
				
				//Altera o local de alocação
				REPLACE TE1_LOCAL 	WITH oMdl:GetModel('TFQMASTER'):GetValue("TFQ_DESTIN")
				REPLACE TE1_CLIDES 	WITH oMdl:GetModel('TFQMASTER'):GetValue("TFQ_DDESTI")
				REPLACE TE1_POSTAL 	WITH ""
				REPLACE TE1_DSCPOS	WITH ""	
				REPLACE TE1_ENTIDA WITH "TER"
				REPLACE TE1_DTALOC WITH oMdl:GetModel('TFQMASTER'):GetValue("TFQ_DMOVIM")
				REPLACE TE1_PRVRET	WITH dRetorno
				REPLACE TE1_CODMOV 	With oMdl:GetModel('TFQMASTER'):GetValue("TFQ_CODIGO")
					
				//Grava o registro de Alteração do FREAR
				At880Hist(Nil,cItArma,.F.,.T.,cStatus,oMdl)
				
			EndIf
				
			TE1->(MsUnLock())	
						
		EndIf
	
	Case cTpArma == itMUNICAO
		//Atualiza o cadastro da munição
		RecLock("TE2",.F.)
		TE2->TE2_LOCAL 	:= oMdl:GetValue("TFQMASTER","TFQ_DESTIN")
		TE2->TE2_CLIDES := oMdl:GetValue("TFQMASTER","TFQ_DDESTI")
		TE2->(MsUnlock())
					
EndCase
RestArea(aArea)
Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880Hist

Atualiza a Tabela TIO para armazenar toda troca de Status dos Armamentos

@author Serviços
@since 20/08/13
@version P11 R9

@param cArma,Codigo da Arma
@Param cColete,Codigo do Colete
@Param lArma,Indica se deve Atualizar a Arma
@Param lColete,Indica se deve atualizar o Colete
@Param cStatus,Indica o Status que foi alterado

@return ExpL:Retorna .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At880Hist(cArma,cColete,lArma,lColete,cStatus,oMdl)
Local cMotivo		:= ""
Local aArea			:= GetArea()

Default cArma		:= ""
Default cColete		:= ""
Default lArma		:= .F.	
Default lColete		:= .F.
Default cStatus		:= ""
Default oMdl		:= FwModelActive()

If cStatus == "2"
	//Concatena o Movimentação mais o codigo
	cMotivo	:= STR0037 + oMdl:GetValue("TFQMASTER","TFQ_CODIGO") //"Movimentação para implantação, Codigo: "
ElseIf cStatus == "1" .Or. cStatus == "A"
	//Concatena Retorno mais o codigo
	cMotivo	:= STR0038 + oMdl:GetValue("TFQMASTER","TFQ_CODIGO") //"Retorno para Empresa, Codigo: "		
EndIf

//Grava o TIO para controle do FREAR
Begin Transaction
	DbSelectArea("TIO")
	RecLock("TIO",.T.)
		REPLACE TIO_FILIAL 	With xFilial("TIO")
		REPLACE TIO_CODIGO 	With At880PrxTIO() //GetSXENum("TIO","TIO_CODIGO")
		REPLACE TIO_CODMOV 	With oMdl:GetValue("TFQMASTER","TFQ_CODIGO")
		REPLACE TIO_DTALT 	With dDataBase		
		If lArma
			REPLACE TIO_ARMA 		With cArma
			REPLACE TIO_MOTIVO 	With cMotivo
			REPLACE TIO_FREAR		With cStatus 
		ElseIf lColete
			REPLACE TIO_COLETE 	With cColete
			REPLACE TIO_MOTIVO 	With cMotivo
			REPLACE TIO_FREAR		With cStatus
		EndIf
		REPLACE TIO_CODUSU 	With __cUserId
	TIO->(MsUnlock())
	TIO->(ConfirmSX8())
End Transaction	

RestArea(aArea)
	
Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880SubLoc

Verifica se o destino possui sublocal para preencher
@sample 	At880SubLoc() 
@since		11/09/2013 
@version P11 R9

@Param cLocal, Codigo do Local de Atendimento
     
@return cCodLoc, Codigo do SubLocal
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At880SubLoc(cLocal,cDesc)
Local cCodLoc	:= ""
Local aArea	:= GetArea()

DbSelectArea("ABS")
ABS->(DbSetOrder(1))
				
If ABS->(DbSeek(xFilial("ABS") + cLocal))
	If !Empty(ABS->ABS_LOCPAI)
		cCodLoc	:= ABS->ABS_LOCPAI
		If ABS->(DbSeek(xFilial("ABS") + cCodLoc))
			cDesc		:= ABS->ABS_DESCRI	
		EndIf	
	EndIf
EndIf

RestArea(aArea)

Return(cCodLoc)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880IncManut

Realiza a Inclusão da manutenção
@sample 	At880IncManut() 
@since		11/09/2013 
@version P11 R9

@Param cArma, Codigo do Armamento
     
@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At880IncManut(oMdl,cTpArma,cItArma,nQtd)
Local lRet 		:= .T.
Local aCampos	:= {}
Local cCDRESP	:= oMdl:GetModel('TFQMASTER'):GetValue("TFQ_CDRESP")
Local dDMOVIM	:= oMdl:GetModel('TFQMASTER'):GetValue("TFQ_DMOVIM")
Local cTPMNT	:= oMdl:GetModel('TFQMASTER'):GetValue("TFQ_TPMNT")
Local cMOTMNT	:= oMdl:GetModel('TFQMASTER'):GetValue("TFQ_MOTMNT")
Local cDESTIN 	:= oMdl:GetModel('TFQMASTER'):GetValue("TFQ_DESTIN")
Local cDDESTI	:= oMdl:GetModel('TFQMASTER'):GetValue("TFQ_DDESTI")
Local aArea		:= GetArea()

Default cTpArma := ""
Default cItArma := ""
Default nQtd    := 0

Private lMsHelpAuto := .T.			// Variavel de controle interno do ExecAuto
Private lMsErroAuto := .F.	

If !Empty(cTpArma) .and. !Empty(cItArma)

	If cTpArma <> itMUNICAO
		//Monta o Array para inclusão da manutenção
		aCampos:= 	{{"TEU_CODIGO"		,GetSXENum("TEU","TEU_CODIGO")			,NIL},; //Codigo
					{"TEU_TPARMA"     	,cTpArma     								,NIL},; //Tipo da Arma
					{"TEU_CDARM"      	,cItArma					     			,NIL},; //Codigo da Arma
					{"TEU_CDRESP"			,cCDRESP					      			,NIL},; //Responsavel
					{"TEU_RESPON"			,At780DescRes(cCDRESP)					,NIL},; //Nome do Responsavel
					{"TEU_DTABER"			,dDMOVIM				        			,NIL},; //Data de Abertura
					{"TEU_TPMNT"			,cTPMNT				         			,NIL},; //Tipo de Manutenção
					{"TEU_LOCAL" 			,"2"         								,NIL},; //Manutenção no Local, 2 = Não
					{"TEU_MOTIVO"    		,cMOTMNT 									,NIL},;  //Motivo da Manutenção
					{"TEU_ORIGEM"    		,"TECA880" 								,NIL}}  //Origem da Manutenção
	ElseIf cTpArma == itMUNICAO .and. !Empty(nQtd)
		//Monta o Array para inclusão da manutenção
		TE2->(DbSetOrder(4))				
		TE2->(DbSeek(xFilial("TE2") + cItArma))
		cCodMun := TE2->TE2_CODMUN
		
		
		aCampos:= 	{{"TEU_CODIGO"		,GetSXENum("TEU","TEU_CODIGO")			,NIL},; //Codigo
					{"TEU_TPARMA"     	,cTpArma     								,NIL},; //Tipo da Arma
					{"TEU_CDARM"      	,cCodMun					     			,NIL},; //Codigo da Arma
					{"TEU_ENTORI"      	,"1"						     			,NIL},; //Entidade do local de Manutenção
					{"TEU_CODLOC"      	,cDESTIN     								,NIL},; //Codigo do Local de Manutenção
					{"TEU_DSCLOC"      	,cDDESTI					     			,NIL},; //Descrição do Local
					{"TEU_QTDMUN"      	,nQTD						     			,NIL},; //Quantidade de Munições
					{"TEU_CDRESP"			,cCDRESP					      			,NIL},; //Responsavel
					{"TEU_RESPON"			,At780DescRes(cCDRESP)					,NIL},; //Nome do Responsavel
					{"TEU_DTABER"			,dDMOVIM				        			,NIL},; //Data de Abertura
					{"TEU_TPMNT"			,cTPMNT				         			,NIL},; //Tipo de Manutenção
					{"TEU_LOCAL" 			,"2"         								,NIL},; //Manutenção no Local, 2 = Não
					{"TEU_MOTIVO"    		,cMOTMNT				 					,NIL},;  //Motivo da Manutenção
					{"TEU_ORIGEM"    		,"TECA880" 								,NIL}}  //Origem da Manutenção
		
	EndIf		
	
	If !Empty(aCampos)
		Processa( { || TECA780(aCampos,3) },STR0039,STR0040,.F.) //'Aguarde','Processando...'
			
		If lMsErroAuto
			MostraErro()
			DisarmTransaction()
			lRet := .F.
		EndIf
			
		ConfirmSX8()
	EndIf
	
EndIf
RestArea(aArea)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880MntCmp

Verifica se os campos de Manutenção estão preenchidos
@sample 	At880MntCmp() 
@since		11/09/2013 
@version P11 R9

@Param cArma, Codigo do Armamento
     
@return cCodLoc, Codigo do SubLocal
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At880MntCmp()
Local lRet	:= .T.

// Se a movimentação é de manutenção...
If FwFldGet("TFQ_MOTIVO") == mtMANUTENCAO
 
	//Verifica se o campo de responsavel está preenchido
	If Empty(FwFldGet("TFQ_CDRESP"))
		Help( ,, "At880MntCmp",, STR0043, 1, 0 ) //'O campo de responsavel pela manutenção não está preenchido'
		lRet := .F.
	EndIf
	
	//Verifica se o campo tipo da manutenção está preenchido
	If lRet .And. Empty(FwFldGet("TFQ_TPMNT"))
		Help( ,, "At880MntCmp",, STR0044, 1, 0 ) //'O campo tipo da manutenção não está preenchido'
		lRet := .F.
	EndIf
	
	//Verifica se o campo de motivo da manutenção está preenchido
	If lRet .And. Empty(FwFldGet("TFQ_MOTMNT"))
		Help( ,, "At880MntCmp",, STR0045, 1, 0 )//'O campo motivo da manutenção não está preenchido'
		lRet := .F.
	EndIf

EndIf

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880MntAbe

Verifica se a arma selecionada possui alguma manutenção em aberto
@sample 	At880MntAbe() 
@since		11/09/2013 
@version P11 R9

@Param cArma, Codigo do Armamento
     
@return cCodLoc, Codigo do SubLocal
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At880MntAbe(cITMov,cCDMov)
Local lRet		:= .T.
Local aRet		:= {}
Local cAlias	:= GetNextAlias()
Local cArma	:= cCDMov
Local cTipo	:= cITMov
Local cStatus	:= "1"

If Select("cAlias") > 0 
	(cAlias)->(DbCloseArea())
Endif

BeginSQL alias cAlias		
	SELECT TEU.TEU_CODIGO, TEU.TEU_TPARMA, TEU.TEU_CDARM, TEU.TEU_CDRESP, TEU.TEU_DTABER 
	  FROM %Table:TEU% TEU
	 WHERE TEU.TEU_FILIAL = %xfilial:TEU%
	   AND TEU.TEU_TPARMA = %Exp:cTipo%
	   AND TEU.TEU_CDARM = %Exp:cArma%
	   AND TEU.TEU_STATUS = %Exp:cStatus%
	   AND TEU.%NotDel%	   	
EndSQL	

While (cAlias)->(!Eof())

	AAdd( aRet, { 	(cAlias)->TEU_CODIGO,;
						(cAlias)->TEU_CDARM } )
	
	(cAlias)->(DbSkip())
	
EndDo

(cAlias)->(DbCloseArea())

If Len(aRet) > 0
	Help( ,, "At880MntAbe",, STR0046, 1, 0 )	//'A Arma selecionada possui uma manutenção em aberto, Exclua ou encerre a manutenção'
	lRet := .F.
EndIf

Return(lRet)



//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880RetDados

Retorna os dados da Arma
@sample 	At880RetDados(cArma,cDesc,aCarac)
@since		11/09/2013 
@version P11 R9

@Param cArma, Codigo do Armamento
     
@return cCodLoc, Codigo do SubLocal
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880RetDados(cTpArma,cArma,cDesc,aCarac)
Local aArea		:= GetArea()
Local cMarca		:= ""
Local cEspecie	:= ""
Local cProd		:= ""

Do Case
	Case cTpArma == itARMA
		DbSelectArea("TE0")
		TE0->(DbSetOrder(1))
		
		If TE0->(DbSeek(xFilial("TE0") + cArma ))
			cProd := TE0->TE0_CODPRO	
			cDesc := Posicione("SB1",1,xFilial("SB1") + cProd ,"SB1->B1_DESC")
			cMarca	:= Posicione("SX5",1,xFilial("SX5")+"79"+TE0->TE0_MARCA,"SX5->X5_DESCRI")
			
			If TE0->TE0_ESPEC == "1"
				cEspecie := "Revolver"
			Else
				cEspecie := "Pistola"
			EndIf
			
			AAdd( aCarac, TE0->TE0_ATIVO )
			AAdd( aCarac, cEspecie )
			AAdd( aCarac, cMarca )
			AAdd( aCarac, TE0->TE0_CALIBR )
			AAdd( aCarac, TE0->TE0_MODELO )
			AAdd( aCarac, TE0->TE0_NUMREG )
			AAdd( aCarac, TE0->TE0_SINARM )
		EndIf
		
	Case cTpArma == itCOLETE
		DbSelectArea("TE1")
		TE1->(DbSetOrder(1))
		
		If TE1->(DbSeek(xFilial("TE1") + cArma ))
			cProd := TE1->TE1_CODPRO	
			cDesc := Posicione("SB1",1,xFilial("SB1") + cProd ,"SB1->B1_DESC")
			
			AAdd( aCarac, TE1->TE1_MARCA )
			AAdd( aCarac, TE1->TE1_VALIDA )
			AAdd( aCarac, TE1->TE1_NUMCOL )
			AAdd( aCarac, TE1->TE1_NUMSER )
			AAdd( aCarac, TE1->TE1_SINARM )
			AAdd( aCarac, TE1->TE1_PLCDIA )
			AAdd( aCarac, TE1->TE1_PLCTRA )
		EndIf
		
	Case cTpArma == itMUNICAO
		DbSelectArea("TE2")
		TE2->(DbSetOrder(4))
		
		If TE2->(DbSeek(xFilial("TE2") + cArma ))
			cProd := TE2->TE2_CODPRO	
			cDesc := Posicione("SB1",1,xFilial("SB1") + cProd ,"SB1->B1_DESC")
			
			If TE2->TE2_ESPEC == "1"
				cEspecie := "Revolver"
			ElseIf TE2->TE2_ESPEC == "2"
				cEspecie := "Pistola"
			Else
				cEspecie := "Espingarda"
			EndIf
			
			AAdd( aCarac, cProd )
			AAdd( aCarac, TE2->TE2_VALIDA )
			AAdd( aCarac, cEspecie )
			AAdd( aCarac, TE2->TE2_MARCA )
			AAdd( aCarac, TE2->TE2_CALIBR )
			AAdd( aCarac, TE2->TE2_MODELO )
			AAdd( aCarac, TE2->TE2_SINARM )
	
		EndIf
EndCase
RestArea(aArea)
Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880RetResp

Retorna os responsaveis pela alocação
@sample 	At880RetResp() 
@since		11/09/2013 
@version P11 R9
     
@return aARet, Array com o retorno
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880RetResp()
Local aRet			:= {}
Local oModel 		:= FWModelActive()
Local oModelTFR	:= oModel:GetModel('TFRFUNC')	//Model do Grid Pai
Local nX			:= 0

For nX := 1 To oModelTFR:Length()
	oModelTFR:GoLine(nX)
	AAdd( aRet, FwFldGet("TFR_NOMTEC") )
Next nX
Return(aRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880Guia

Realiza a abertura do Link para verificação do C.A do Fornecedor
@author Serviços
@since 20/08/13
@version P11 R9

@Param oModel,Model do Cadastro
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880Guia(oModel)
Local oDlg		:= Nil
Local aSize	:=	{}
Local cUrl		:= SuperGetMV("MV_TECGUIA",,"") //"http://www.sgte.eb.mil.br/guiatrafego/index.jsp"	

aSize	:=	MsAdvSize()

oMainWnd:CoorsUpdate()  // Atualiza as corrdenadas da Janela MAIN
nMyWidth  := oMainWnd:nClientWidth - 10
nMyHeight := oMainWnd:nClientHeight - 30

DEFINE DIALOG oDlg TITLE STR0047 From aSize[7],00 To nMyHeight,nMyWidth PIXEL //"Movimentação"

oTIBrowser := TIBrowser():New(05,05,nMyHeight-250, nMyWidth-820,cUrl,oDlg )
oTIBrowser:GoHome()

ACTIVATE DIALOG oDlg CENTERED 
Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880IncTFP

Atualiza a Tabela TFP e registra a movimentação

@param cItArma,caractere,Código do Armamento
@param nQtd,numerico,Quantidade movimentada

@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At880IncTFP(cItArma,nQtd)
Local lRet			:= .T.
Local lContinua	:= .F.
Local aAreaTFP	:= TFP->(GetArea())
Local aAreaTE2	:= TE2->(GetArea())
Local cLote		:= ""
Local cEntDes	:= "" 		//Variavel com a Entidade de Destino
Local cCodMun	:= ""

Default cItArma	:= FwFldGet("TFQ_ITARMA")
Default nQtd	:= FwFldGet("TFQ_QTDMUN")

Do Case
	Case FwFldGet("TFQ_ENTDES") == edCLIENTE
		If FwFldGet("TFQ_ENTORI") == "1"
			//Atualiza o Saldo do Local Interno Selecionada para a Movimentação
			DbSelectArea("TFP")
			TFP->(DbSetOrder(7))
		Else
			//Atualiza o Saldo do Local de Alocação Selecionada para a Movimentação
			DbSelectArea("TFP")
			TFP->(DbSetOrder(8))
		EndIf
		
		DbSelectArea("TE2")
		TE2->(DbSetOrder(4))
		
		If TE2->(DbSeek(xFilial("TE2") + cItArma))
		
			If TFP->(DbSeek(xFilial("TFP") + FwFldGet("TFQ_ENTORI") + FwFldGet("TFQ_ORIGEM") + cItArma ))
				cLote	:= TFP->TFP_LOTE
				cCodMun := TFP->TFP_CODMUN

				RecLock("TFP",.F.)
			    REPLACE TFP_SALDO	WITH (TFP->TFP_SALDO - nQtd)
				MsUnlock()
	
				lContinua	:= .T.	
			EndIf
		EndIf
		
		//Inclui local de alocação da munição
		If lContinua
			If FwFldGet("TFQ_ENTDES") == edEMPRESA
				//Atualiza o Saldo do Local Interno Selecionada para a Movimentação
				TFP->(DbSetOrder(7))
				cEntDes := "1"
			Else
				//Atualiza o Saldo do Local de Alocação Selecionada para a Movimentação
				TFP->(DbSetOrder(8))
				cEntDes := "2"
			EndIf
				
			//Se Local de Destino já existe Atualiza os dados e soma o saldo
			If TFP->(DbSeek(xFilial("TFP") + cEntDes + FwFldGet("TFQ_DESTIN") + cItArma))
				RecLock("TFP",.F.)
				REPLACE TFP_SALDO		With (TFP->TFP_SALDO + nQtd)
			Else
				RecLock("TFP",.T.)
				REPLACE TFP_SALDO		With nQtd
			EndIf	
					
			REPLACE TFP_FILIAL 	With xFilial("TFP")
			REPLACE TFP_CODIGO 	With GetSXENum("TFP","TFP_CODIGO")
			REPLACE TFP_ENTIDA 	With "2" 								//1=Empresa, 2= Cliente
			REPLACE TFP_CODLOC 	With FwFldGet("TFQ_DESTIN")		
			REPLACE TFP_MOVIM 	With "2"								//Saldo Cliente
			REPLACE TFP_CODMUN	With cCodMun
			REPLACE TFP_LOTE	With cLote
			REPLACE TFP_STATUS	With "1"								//Efetivada
			REPLACE TFP_DTHIST	With FwFldGet("TFQ_DMOVIM")
			REPLACE TFP_CODMOV	With FwFldGet("TFQ_CODIGO")	
			REPLACE TFP_PRODUT	With cItArma
			MsUnlock()
			ConfirmSX8()
		EndIf
	
	Case FwFldGet("TFQ_ENTDES") == edEMPRESA
		
		Do Case
			Case FwFldGet("TFQ_MOTIVO") == mtIMPLANTACAO
				If FwFldGet("TFQ_ENTORI") == "1"
					//Atualiza o Saldo do Local Interno Selecionada para a Movimentação
					DbSelectArea("TFP")
					TFP->(DbSetOrder(7))
				Else
					//Atualiza o Saldo do Local de Alocação Selecionada para a Movimentação
					DbSelectArea("TFP")
					TFP->(DbSetOrder(8))
				EndIf
				
				DbSelectArea("TE2")
				TE2->(DbSetOrder(4))
				
				If TE2->(DbSeek(xFilial("TE2") + cItArma))
				
					If TFP->(DbSeek(xFilial("TFP") + FwFldGet("TFQ_ENTORI") + FwFldGet("TFQ_ORIGEM") + cItArma))
						cLote	:= TFP->TFP_LOTE
						cCodMun := TFP->TFP_CODMUN
								
						RecLock("TFP",.F.)
						REPLACE TFP_SALDO With (TFP->TFP_SALDO - nQtd)
						MsUnlock()
								
						lContinua	:= .T.	
					EndIf
				EndIf
				
				//Inclui local de alocação da munição
				If lContinua
					If FwFldGet("TFQ_ENTDES") == edEMPRESA
						//Atualiza o Saldo do Local Interno Selecionada para a Movimentação
						TFP->(DbSetOrder(7))
						cEntDes := "1"
					Else
						//Atualiza o Saldo do Local de Alocação Selecionada para a Movimentação
						TFP->(DbSetOrder(8))
						cEntDes := "2"
					EndIf
						
					//Se Local de Destino já existe Atualiza os dados e soma o saldo
					If TFP->(DbSeek(xFilial("TFP") + cEntDes + FwFldGet("TFQ_DESTIN") + cItArma))
						RecLock("TFP",.F.)
						REPLACE TFP_SALDO		With (TFP->TFP_SALDO + nQtd)
					Else
						RecLock("TFP",.T.)
						REPLACE TFP_SALDO		With nQtd
					EndIf	
								
					REPLACE TFP_FILIAL 	With xFilial("TFP")
					REPLACE TFP_CODIGO 	With GetSXENum("TFP","TFP_CODIGO")
					REPLACE TFP_ENTIDA 	With "1" 								//1=Empresa, 2= Cliente
					REPLACE TFP_CODINT 	With FwFldGet("TFQ_DESTIN")		
					REPLACE TFP_MOVIM 	With "1"								//Saldo Empresa		
					REPLACE TFP_CODMUN	With  cCodMun 
					REPLACE TFP_LOTE	With cLote
					REPLACE TFP_STATUS	With "1"								//Efetivada
					REPLACE TFP_DTHIST	With FwFldGet("TFQ_DMOVIM")
					REPLACE TFP_CODMOV	With FwFldGet("TFQ_CODIGO")
					REPLACE TFP_PRODUT	With cItArma	
					MsUnlock()
					ConfirmSX8()
				EndIf
			Case FwFldGet("TFQ_MOTIVO") == mtMANUTENCAO //Manutenção
				If FwFldGet("TFQ_ENTORI") == "1"
					//Atualiza o Saldo do Local Interno Selecionada para a Movimentação
					DbSelectArea("TFP")
					TFP->(DbSetOrder(7))
				Else
					//Atualiza o Saldo do Local de Alocação Selecionada para a Movimentação
					DbSelectArea("TFP")
					TFP->(DbSetOrder(8))
				EndIf
				
				DbSelectArea("TE2")
				TE2->(DbSetOrder(4))
				
				If TE2->(DbSeek(xFilial("TE2") + cItArma))
				
					If TFP->(DbSeek(xFilial("TFP") + FwFldGet("TFQ_ENTORI") + FwFldGet("TFQ_ORIGEM") + cItArma))
						cLote	:= TFP->TFP_LOTE
						cCodMun := TFP->TFP_CODMUN
						RecLock("TFP",.F.)
						REPLACE TFP_SALDO With (TFP->TFP_SALDO - nQtd)
						MsUnlock()
						lContinua	:= .T.	
					EndIf
				EndIf
				
				//Inclui local de alocação da munição
				If lContinua
					//Atualiza o Saldo do Local Interno Selecionada para a Movimentação
					TFP->(DbSetOrder(7))
					cEntDes := "1"
						
					//Se Local de Destino já existe Atualiza os dados e soma o saldo
					If TFP->(DbSeek(xFilial("TFP") + cEntDes + FwFldGet("TFQ_DESTIN") + cItArma))
						RecLock("TFP",.F.)
						REPLACE TFP_SALDO		With (TFP->TFP_SALDO + nQtd)
					Else
						RecLock("TFP",.T.)
						REPLACE TFP_SALDO		With nQtd
					EndIf	
		
					REPLACE TFP_FILIAL 	With xFilial("TFP")
					REPLACE TFP_CODIGO 	With GetSXENum("TFP","TFP_CODIGO")
					REPLACE TFP_ENTIDA 	With "1" 								//1=Empresa, 2= Cliente
					REPLACE TFP_CODINT 	With FwFldGet("TFQ_DESTIN")		
					REPLACE TFP_MOVIM 	With "1"								//Saldo Empresa		
					REPLACE TFP_CODMUN	With cCodMun
					REPLACE TFP_LOTE	With cLote
					REPLACE TFP_STATUS	With "1"								//Efetivada
					REPLACE TFP_DTHIST	With FwFldGet("TFQ_DMOVIM")
					REPLACE TFP_CODMOV	With FwFldGet("TFQ_CODIGO")
					REPLACE TFP_PRODUT	With cItArma	
					MsUnlock()
					ConfirmSX8()
				EndIf	
			Case FwFldGet("TFQ_MOTIVO") == mtDESCARTE //Descarte
				 If FwFldGet("TFQ_ENTORI") == "1"
					//Atualiza o Saldo do Local Interno Selecionada para a Movimentação
					DbSelectArea("TFP")
					TFP->(DbSetOrder(7))
				Else
					//Atualiza o Saldo do Local de Alocação Selecionada para a Movimentação
					DbSelectArea("TFP")
					TFP->(DbSetOrder(8))
				EndIf
				
				DbSelectArea("TE2")
				TE2->(DbSetOrder(4))
				
				If TE2->(DbSeek(xFilial("TE2") + cItArma))
					If TFP->(DbSeek(xFilial("TFP") + FwFldGet("TFQ_ENTORI") + FwFldGet("TFQ_ORIGEM") + cItArma))
						cLote	:= TFP->TFP_LOTE
						cCodMun := TFP->TFP_CODMUN
						RecLock("TFP",.F.)
						REPLACE TFP_SALDO With (TFP->TFP_SALDO - nQtd)
						MsUnlock()
						lContinua	:= .T.	
					EndIf
				EndIf
				
				//Inclui local de alocação da munição
				If lContinua
					//Atualiza o Saldo do Local Interno Selecionada para a Movimentação
					TFP->(DbSetOrder(2))
					cEntDes := "1"
						
					RecLock("TFP",.T.)
						
					REPLACE TFP_FILIAL 	With xFilial("TFP")
					REPLACE TFP_CODIGO 	With GetSXENum("TFP","TFP_CODIGO")
					REPLACE TFP_ENTIDA 	With "1" 								//1=Empresa, 2= Cliente
					REPLACE TFP_CODINT 	With FwFldGet("TFQ_DESTIN")		
					REPLACE TFP_MOVIM 	With "8"								//Saldo Empresa		
					REPLACE TFP_SALDO	With nQtd
					REPLACE TFP_CODMUN	With cCodMun
					REPLACE TFP_LOTE	With cLote
					REPLACE TFP_STATUS	With "1"								//Efetivada
					REPLACE TFP_DTHIST	With FwFldGet("TFQ_DMOVIM")
					REPLACE TFP_CODMOV	With FwFldGet("TFQ_CODIGO")
					REPLACE TFP_PRODUT	With cItArma		
						
					MsUnlock()
					ConfirmSX8()
				EndIf	
		EndCase		
EndCase
RestArea(aAreaTFP)
RestArea(aAreaTE2)
Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880IniPad

Inicializador do local de origem da munição

@author Serviços
@since 20/08/13
@version P11 R9

@return ExpC:Descrição do Local de origem
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880IniPad(cEntOri,cOriMun)
Local cDesc 	:= ""
Local aArea	:= GetArea()
Local lModoInc	:= .F.

If Type('INCLUI') == 'L'
	lModoInc := INCLUI
EndIf 

If !lModoInc .And. !Empty(cENTORI) .And. !Empty(cORIMUN)
	Do Case
		Case cEntOri == "2"
			cDesc := Alltrim(Posicione("ABS",1,xFilial("ABS")+ cOriMun ,"ABS_DESCRI"))

		Case cEntOri == "1"
			cDesc := Alltrim(Posicione("TER",1,xFilial("TER")+ cOriMun ,"TER_DESCRI"))
	
	EndCase
EndIf
RestArea(aArea)
Return(cDesc)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880IniLote

Inicializador do Lote da munição

@author Serviços
@since 20/08/13
@version P11 R9

@return ExpC:Descrição do Lote
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880IniLote(cITMOV,cCdARMA)
Local cDesc 	:= ""
Local aArea	:= GetArea()

If !Inclui .And. !Empty(cITMOV) .And. !Empty(cCdARMA)
	If cITMOV == itMUNICAO
		cDesc := Posicione("TE2",1,xFilial("TE2") + cCdARMA ,"TE2->TE2_LOTE") 
	EndIf	
EndIf
RestArea(aArea)
Return(cDesc)

//----------------------------------------------------------
/*/{Protheus.doc} At880VldCont()
Efetua a validação do campo de contrato

@Return 	lRet,, define se bloqueia ou nao

@author 	Serviços
@since 		28/04/2014
/*/
//----------------------------------------------------------
Function At880VlCont( oModel, cLocal, cContrato )

Local lRet := (FwFldGet("TFQ_ENTDES") == edEMPRESA)

If !lRet
	If Empty(cContrato)
		lRet := At680Perm( Nil, __cUserId, "007" ) // Pode movimentar armamento fora do contrato?		
		If !lRet
			oModel:GetModel():SetErrorMessage(oModel:GetId(),"TFQ_CONTRT",oModel:GetModel():GetId(),"TFQ_CONTRT",'AT880ACE',; 
				STR0060, "" ) // "Usuário sem permissão para movimentação fora do contrato!"			
		EndIf
	Else 
		lRet := At880FilCont( cLocal, cContrato )
		If !lRet
			oModel:GetModel():SetErrorMessage(oModel:GetId(),"TFQ_CONTRT",oModel:GetModel():GetId(),"TFQ_CONTRT",'AT880ACE2',; 
				STR0061, "" ) // "Contrato invalido para o local escolhido!"	
		EndIf 		
	EndIf
EndIf

Return(lRet)

//----------------------------------------------------------
/*/{Protheus.doc} At880FilCont()
Efetua o filtro dos contratos do local

@param 		oModel

@Return 	lRet,, define se bloqueia ou nao

@author 	Serviços
@since 		28/04/2014
/*/
//----------------------------------------------------------
Function At880FilCont(cCodLocal, cContrato, cRevisao )

Local aArea:= GetArea()
Local lRet := .F.

Default cRevisao := ""

If CN9->CN9_SITUAC == "05"
	DbSelectArea("TFL")
	TFL->(dbSetOrder(3)) //TFL_FILIAL+TFL_LOCAL
	If TFL->( dbSeek( xFilial("TFL") + cCodLocal ) )
		While TFL->(!Eof()) .And. TFL->TFL_LOCAL == cCodLocal		
			If cContrato == TFL->TFL_CONTRT .And. ;
			   (Empty(cRevisao) .Or. cRevisao == TFL->TFL_CONREV)
				lRet := .T.
				Exit
			EndIf			
			TFL->(dbSkip())		
		EndDo
	EndIf
EndIf
RestArea(aArea)
Return lRet

//----------------------------------------------------------
/*/{Protheus.doc} At880QtdMov()
Verifica a quantidade de movimentação do armamento

@param 		oModel

@Return 	lRet,, define se bloqueia ou nao

@author 	Serviços
@since 		28/04/2014
/*/
//----------------------------------------------------------
Function At880QtdMov( cTipo, cLocal, cContrato )
 
Local lRet 	  := (cTipo == "3" .Or. Empty(cContrato)) 
Local cAliasTFF := GetNextAlias()
Local cAliasTFQ := GetNextAlias()
Local nNumTFF   := 0
Local nNumTFQ   := 0

If !lRet

 	lRet := At680Perm( Nil, __cUserId, "006" ) // Pode alocar mais armamentos que a quantidade definida?	
		
	If !lRet 
	
		// Verifica a quantidade definida no contrato para o numero de armamentos
		BeginSql Alias cAliasTFF	
		
			SELECT 
				TFL.TFL_LOCAL, TFL.TFL_CONTRT, 
				SUM(TFF.TFF_NARMA) MOV_ARM, SUM(TFF.TFF_NCOLE) MOV_COL
			FROM 
				%table:TFL% TFL
			JOIN %table:TFF% TFF ON
				TFF.TFF_FILIAL = %xFilial:TFF% AND
				TFF.TFF_CODPAI = TFL.TFL_CODIGO AND 
				TFF.%NotDel%
			WHERE 
				TFL.TFL_FILIAL = %xFilial:TFL% AND 
				TFL.TFL_LOCAL = %Exp:cLocal% AND 
				TFL.TFL_CONTRT = %Exp:cContrato% AND 
				TFL.%NotDel%
			GROUP BY 
				TFL.TFL_LOCAL, TFL.TFL_CONTRT	
		
		EndSql	
		
		If		cTipo == itARMA				// Arma
			nNumTFF := (cAliasTFF)->MOV_ARM
		ElseIf	cTipo == itCOLETE				// Colete
			nNumTFF := (cAliasTFF)->MOV_COL 
		EndIf
		
		// Verifica a quantidade movimentada de armamentos		
		BeginSql Alias cAliasTFQ		
		
			SELECT 
				TFO.TFO_ITMOV, TFQ_ENTDES
			FROM 
				%table:TFQ% TFQ
			INNER JOIN %table:TFO% TFO ON 
					TFQ.TFQ_FILIAL = TFO.TFO_FILIAL 
				AND TFQ.TFQ_CODIGO = TFO.TFO_CDMOV
			WHERE 
				TFQ.TFQ_FILIAL = %xFilial:TFQ% AND
				(TFQ.TFQ_DESTIN = %Exp:cLocal% OR 
				TFQ.TFQ_ORIGEM = %Exp:cLocal%) AND 
				TFQ.TFQ_CONTRT = %Exp:cContrato% AND 
				TFQ.%NotDel%
		
		EndSql	
		
		nNumTFQ := 0
		
		While (cAliasTFQ)->(!Eof())
		
			If (cAliasTFQ)->TFO_ITMOV <> cTipo
				(cAliasTFQ)->(dbSkip())
				Loop			
			EndIf
			
			If (cAliasTFQ)->TFQ_ENTDES == "1"
				nNumTFQ++
			Else 
				nNumTFQ--
			EndIf
		
			(cAliasTFQ)->(dbSkip())
		
		EndDo	
		
		lRet := (nNumTFF >= (nNumTFQ+1))
				
		If !lRet 
			Help( ,, "AT880MOVARM",, STR0062, 1, 0) // "Usuário sem permissão para movimentar equipamentos adicionais no contrato!"			
		EndIf			
	
	EndIf
	
EndIf 
Return(lRet)

//----------------------------------------------------------
/*/{Protheus.doc} AT880GFLD
	Realiza a classificação de campos baseado num determinado contexto 

@param 		cTipo,caractere,Constante que determina se a estrutura a ser construida: ARMAS - MUNICOES - COLETES
@param		cCampo,caractere,Nome do campo para validação de apresentação na interface.

@sample	AT880GFLD(cTipo, cCampo)
@return 	lRet,, define se apresenta ou nao

@author 	Serviços
@since 		02/06/2015
/*/
//----------------------------------------------------------
Function AT880GFLD(cTipo, cCampo)
Local lRet := .F.
Local cHeader	:= ''

cHeader += 'TFQ_FILIAL;TFQ_CODIGO;TFQ_ORIGEM;TFQ_DSCLOC;TFQ_ENTORI;TFQ_MOTIVO;TFQ_ENTDES;TFQ_DESTIN;'
cHeader += 'TFQ_DDESTI;TFQ_JUSTIF;TFQ_DMOVIM;TFQ_RESTRA;TFQ_DRESP;TFQ_STATUS;TFQ_USUAR;TFQ_DATA;TFQ_HORA;'
cHeader += 'TFQ_ENTIDA;TFQ_ULTSTA;TFQ_CDRESP;TFQ_TPMNT;TFQ_MOTMNT;TFQ_CONTRT'

cCampo := AllTrim(cCampo)

If		cTipo == 'CABECALHO'
	lRet := cCampo $ cHeader
ElseIf		cTipo == 'ARMAS'
	lRet := cCampo $ 'TFO_ITCOD;TFO_ITMOV;TFO_DESCR;TFO_LGUIA;TFO_NRGUIA;TFO_LRET;TFO_DTRET'
ElseIf	cTipo == 'MUNICOES'
	lRet := cCampo $ 'TFO_PRODUT;TFO_ITMOV;TFO_DSCMUN;TFO_LOTE;TFO_QTDE;TFO_LGUIA;TFO_NRGUIA;TFO_LRET;TFO_DTRET' //TFO_CARGA;
ElseIf	cTipo == 'COLETES'
	lRet := cCampo $ 'TFO_ITCOD;TFO_ITMOV;TFO_DESCR;TFO_LRET;TFO_DTRET'
EndIf
Return lRet

//----------------------------------------------------------
/*/{Protheus.doc} At880NGuia
	Realiza consistência no preenchimento do Nr da Guia.  
@Param		oMdl.objeto,Modelo de dados em edição

@sample	At880NGuia(oMdl)
@return 	lRet,, Define se valida a edição

@author 	Serviços
@since 		02/06/2015
/*/
//----------------------------------------------------------
Function At880NGuia(oMdl)
Local lRet := .T.
Local nOperation := oMdl:GetOperation()

If nOperation == MODEL_OPERATION_UPDATE .Or. nOperation == MODEL_OPERATION_INSERT
	If oMdl:GetValue('TFO_LGUIA') == '2' .AND. !Empty(oMdl:GetValue('TFO_NRGUIA'))
		oMdl:LoadValue('TFO_NRGUIA',Space(TamSX3('TFO_NRGUIA')[1]))
	EndIf
EndIf
Return lRet

//----------------------------------------------------------
/*/{Protheus.doc} At880VDtMv
	Realiza a validação da data do movimento versus a data de retorno do armamento.  

@param		oMdl,OObjeto,Modelo de dados Master
@sample	At880VDtMv(oMdl)
@return 	lRet,logico,Determina a validação da edição

@author 	Serviços
@since 		02/06/2015
/*/
//----------------------------------------------------------
Function At880VDtMv(oMdl)
Local lRet			:= .T.
Local oMdlTFO		:= nil
Local dMov			:= oMdl:GetValue('TFQ_DMOVIM')
Local dRet			:= CToD('')
Local nJ			:= 0
Local nI			:= 0

For nI := 1 To 3
	If		nI == 1 
		//Verifica as datas de retorno do grupo armas
		oMdlTFO	:= oMdl:GetModel():GetModel('TFOARMA')
	ElseIf nI == 2
		//Verifica as datas de retorno do grupo Munições
		oMdlTFO	:= oMdl:GetModel():GetModel('TFOMUNI')
	ElseIf nI == 3
		//Verifica as datas de retorno do grupo Coletes
		oMdlTFO	:= oMdl:GetModel():GetModel('TFOCOLE')
	EndIf
	
	For nJ := 1 To oMdlTFO:Length()
		oMdlTFO:GoLine(nJ)
		If !oMdlTFO:IsDeleted()
			dRet := oMdlTFO:GetValue('TFO_DTRET')
			If !Empty(dMov) .and. !Empty(dRet)
				If !(lRet := dRet >= dMov)
					Exit		
				EndIf
			EndIf		
		EndIf
	Next nJ
	
	If !lRet
		Help( ,, "AT880VLDTRT",, STR0065, 1, 0) // "Data de retorno deve ser maior ou igual que a data da movimentação!"
		Exit
	EndIf
Next nI
Return lRet

//----------------------------------------------------------
/*/{Protheus.doc} At880VlArm
	Realiza a validação da data de validade do armamento.  

@param		cItMov,caractere,Tipo do armamento
@param		cItCod,caractere,Código do armamento

@sample	At880VlArm(cItMov,cItCod)
@return 	lRet,logico,Determina a data de validade é igual ou superior à data da movimentação

@author 	Serviços
@since 		02/06/2015
/*/
//----------------------------------------------------------
Function At880VlArm(cItMov,cItCod,cOri,cDes)
Local lRet		:= .T.
Local aArea		:= GetArea()
Local dMov		:= FwFldGet('TFQ_DMOVIM')
Local dValida	:= CToD('')

Default cItMov := ""
Default cItCod := ""
Default cOri := ""
Default cDes := ""

//Valida apenas se o destino nao for igual a 2: Empresa
//Movimentacoes com destino igual a empresa podem acontecer mesmo quando o armamento esta vencido por conta de operacoes de descarte
If alltrim(cDes) != "2"
If !Empty(cItMov) .and. !Empty(cItCod)
	Do Case
		Case cItMov == itARMA
			DbSelectArea("TE0");	TE0->(DbSetOrder(1))
			If TE0->(DbSeek(xFilial("TE0") + cItCod))
				dValida := TE0->TE0_VALIDA
			EndIf
		Case cItMov == itCOLETE
			DbSelectArea("TE1");TE1->(DbSetOrder(1))
			If TE1->(DbSeek(xFilial("TE1") + cItCod))
				dValida := TE1->TE1_VALIDA
			EndIf
		
	EndCase
	If !Empty(dValida)
		lRet := dValida >= dMov
	EndIf
	If !lRet
		Help( ,, "At880VlArm",, STR0066, 1, 0) // "Data de Validade do Armamento expirou!"
	EndIf
EndIf
EndIf

RestArea(aArea)
Return lRet

//----------------------------------------------------------
/*/{Protheus.doc} At880VDtRt
	Realiza a validação da data prevista de retorno do armamento.  

@param		oMdl,OObjeto,Modelo de dados em edição
@sample	At880VDtRt(oMdl)
@return 	lRet,logico,Determina a validação da edição

@author 	Serviços
@since 		02/06/2015
/*/
//----------------------------------------------------------
Function At880VDtRt(oMdl)
Local lRet	:= .T.
Local dRet	:= oMdl:GetValue('TFO_DTRET')
Local dMov	:= FwFldGet('TFQ_DMOVIM')

If !Empty(dRet) .and. !Empty(dMov)
	If dRet < dMov
		Help( ,, "AT880VLDTRT",, STR0067, 1, 0) // "Data de retorno deve ser maior ou igual que a data da movimentação!"
		lRet := .F.		
	EndIf
EndIf
Return lRet

//----------------------------------------------------------
/*/{Protheus.doc} At880DtPrv
	Realiza consistência no preenchimento da Previsão de retorno do armamento.  

@param		oMdl,OObjeto,Modelo de dados em edição
@sample	At880DtPrv(oMdl)
@return 	lRet,Logico,Define se valida a edição

@author 	Serviços
@since 		02/06/2015
/*/
//----------------------------------------------------------
Function At880DtPrv(oMdl)
Local lRet := .T.

If oMdl:GetValue('TFO_LRET') == '2' .AND. !Empty(oMdl:GetValue('TFO_DTRET'))
	oMdl:LoadValue('TFO_DTRET',CToD(''))
EndIf
Return lRet

//----------------------------------------------------------
/*/{Protheus.doc} At880VlEnt
	Valida as entidades de Origem e Destino da Movimentação bem como o motivo para a movimentação entre elas.  
@param		oModel,object,Objeto de dados Movimentação de Armamentos
@param		cIdCall,caractere,Identificação do campo que está sendo editado
@sample	At880VlEnt(oMdlcIdCall)
@return 	lRet,, Determina se os critérios para movimentação entre as entidades foram cumpridos ou não

@author 	Serviços
@since 		02/06/2015
/*/
//----------------------------------------------------------
Function At880VlEnt(oMdl,cIdCall)
Local lRet			:= .T.
Local cEntOrig	:= oMdl:GetValue('TFQ_ENTORI')
Local cEntDest	:= oMdl:GetValue('TFQ_ENTDES')
Local cMotivo		:= oMdl:GetValue('TFQ_MOTIVO') 

If lRet
	// Limpa os campos dependentes do tipo de entidade: Origem ou Destino
	If		cIdCall == 'TFQ_ENTORI'
		oMdl:LoadValue('TFQ_ORIGEM',Space(TAMSX3('TFQ_ORIGEM')[1]))
		oMdl:LoadValue('TFQ_DSCLOC',Space(TAMSX3('TFQ_DSCLOC')[1]))
	ElseIf	cIdCall == 'TFQ_ENTDES'
		oMdl:LoadValue('TFQ_DESTIN',Space(TAMSX3('TFQ_DESTIN')[1]))
		oMdl:LoadValue('TFQ_DDESTI',Space(TAMSX3('TFQ_DDESTI')[1]))
	EndIf
EndIf 

// Valida o motivo da movimentação versus o destino
// 1-Implantações tem sempre como destino o Local de Atendimento de Cliente.
// 2-Manutenções  tem sempre como destino a Empresa prestadora do serviço.
// 3-Descartes    tem sempre como destino a Empresa prestadora do serviço.
// 4-Reforço      tem sempre como destino o Local de Atendimento de Cliente. 

If lRet .and. cEntDest == edCLIENTE .And. (cMotivo == mtMANUTENCAO .Or. cMotivo == mtDESCARTE)
	Help( ,, "At880VlEnt",, STR0031, 1, 0 )//'Para movimentação de Manutenção ou Descarte, só será possivel selecionar a Empresa como destino'
	lRet := .F.	
EndIf

//Para a movimentação de reforco só será possivel selecionar o cliente
If lRet .and. cEntDest == edEMPRESA .And. cMotivo == mtREFORCO
	Help( ,, "At880VlEnt",, STR0032, 1, 0 )//'Para movimentação de Reforço ou Implantação, só será possivel selecionar o cliente como destino'
	lRet := .F.	
EndIf
Return lRet

//----------------------------------------------------------
/*/{Protheus.doc} At880VMXA
	verifica se a arma vinculada à municação está relacionada no Grid de Armas.  
@param		oModel,object,Objeto de dados Movimentação de Armamentos
@sample	At880VMXA(oMdl)
@return 	lRet,logico,determinando se tem um cadastro respectivo ou não.

@author 	Serviços
@since 		02/06/2015
/*/
//----------------------------------------------------------
Function At880VMXA(oMdl)
Local lRet			:= .F.
Local oMdlArma		:= oModel:GetModel('TFOARMA')
Local cCdArma		:= oMdl:GetValue('TFO_ARMA')
Local nI			:= 0

If !Empty(cCdArma)
	For nI := 1 to oMdlArma:Length()
		oMdlArma:GoLine(nI)
		If !oMdlArma:IsDeleted()
			If lRet := oMdlArma:GetValue('TFO_ITCOD') == cCdArma
				Exit
			EndIf
		EndIf
	Next nI
Else
	lRet := .T.
EndIf

If !lRet
	Help( ,, "At880VMXA",,STR0069, 1, 0 )//'Não há registro com este código na Aba de Armas!'
EndIf

Return lRet

//----------------------------------------------------------
/*/{Protheus.doc} At880PosGA
	  
@param		oMdl,object,Objeto Master do formulário de movimentação
@param		nLine,numerico,Linha da grade na edição atual
@param		cAcao,caractere,Mode de Edição: ISENABLE,CANSETVALUE,SETVALUE,ADDLINE,DELETE,UNDELETE, etc.
@param		cCampo,caractere,Identificador do campo com foco de edição

@sample	At880PosGA(oMdl,nLine,cAcao,cCampo)
@return 	lRet,logico,

@author 	Serviços
@since 		02/06/2015
/*/
//----------------------------------------------------------
Function At880PosGA(oMdl,nLine,cAcao,cCampo)
Local lRet := .T.
Return lRet

//----------------------------------------------------------
/*/{Protheus.doc} At880VIMV
	Validação dos Itens de Movimentação
	  
@param		oModel,object,Objeto relativo a Armamento

@sample	At880VIMV(oMdl)
@return 	lRet,logico,Determina se o item pode ser movimentado.

@author 	Serviços
@since 		02/06/2015
/*/
//----------------------------------------------------------
Function At880VIMV(oMdl)
Local lRet		:= .T.
Local cItMov	:= ''
Local cItCod	:= ''
Local cMotivo	:= ''
Local cItMun	:= ''
Local nOperation := oMdl:GetOperation()
Local oViewTFO   :=FWViewActive()

cItMov := oMdl:GetValue('TFO_ITMOV')
cItCod := oMdl:GetValue('TFO_ITCOD')
cMotivo := FwFldGet('TFQ_MOTIVO')

//Verifico se já existe um agendamento para o armamento selecionado
If lRet .and. cItMov == itARMA .and. nOperation == MODEL_OPERATION_INSERT .And. At880Agend(cItMov,cItCod)
	Help( ,, "At880VIMV",, STR0009, 1, 0 )//'Alocação','Já existe um agendamento para esse armamento'
	lRet := .F.	
EndIf

If lRet .and. cItMov == itCOLETE .and. nOperation == MODEL_OPERATION_INSERT .And. At880Agend(cItMov,cItCod)
	Help( ,, "At880VIMV",, STR0009, 1, 0 )//'Alocação','Já existe um agendamento para esse armamento'
	lRet := .F.	
EndIf

//Verifica se o armamento está alocado no local de Origem
If lRet
	 //Verificar se o local de origem está preenchido
	If lRet .and. Empty(FwFldGet('TFQ_ORIGEM'))
		Help( ,, "At880VIMV",, STR0071, 1, 0 )//'Alocação','A Origem da Movimentação deve ser informada!'
		lRet := .F.
	EndIf
	 
	If lRet .and. !At880VldAloc(cItMov,cItCod,(cItMov <> itMUNICAO))
		Help( ,, "At880VIMV",, STR0072, 1, 0 )//'Alocação','Esse armamento não está alocado na Origem informada!'
		lRet := .F.
	EndIf
EndIf

If lRet .AND. cItMov <> itMUNICAO
	//Verifica o Status das armas baseado do motivo
	lRet := At880VldStat(cItMov,cItCod,cMotivo)
EndIf

// Verifica a quantidade de movimentação do armamento no local de atendimento
If lRet .And. FwFldGet("TFQ_ENTDES") == edCLIENTE
	lRet := At880QtdMov(cItMov, FwFldGet("TFQ_DESTIN"), FwFldGet("TFQ_CONTRT"))
EndIf

//Verifica se a arma selecionada possui manutenção em aberto
If lRet
	lRet := At880MntAbe(cItMov,cItCod)
EndIf

//Verifica a Data de Validade do armamento
If lRet .and. FwFldGet("TFQ_ENTDES") == edCLIENTE
	lRet := At880VlArm(cItMov,cItCod,FwFldGet("TFQ_ENTORI"),FwFldGet("TFQ_ENTDES"))
EndIf

If lRet .AND. oMdl:GetValue("TFO_ITMOV") == itMUNICAO 
	lRet := ExistCpo("TE2",cItCod)
Endif

If lRet .AND. oMdl:GetValue("TFO_ITMOV") == itCOLETE
	lRet := ExistCpo("TE1",cItCod)
Endif

//Verifica se a arma esta desativada e indo para um cliente
If lRet .and. FwFldGet("TFQ_ENTDES") == edCLIENTE .and. oMdl:GetValue("TFO_ITMOV") == itARMA
	If alltrim(upper(Posicione("TE0",1,xFilial('TE0') + oMdl:GetValue('TFO_ITCOD'),"TE0_SITUA"))) == "9" .or. ;
		alltrim(upper(Posicione("TE0",1,xFilial('TE0') + oMdl:GetValue('TFO_ITCOD'),"TE0_SITUA"))) == "A"
		
		lRet := .F.
		Help( ,,,STR0074,STR0075, 1, 0 ) //"Arma Descartada ou Desativada" //"O armamento escolhido tem situação igual a Desativada ou Descartada"
	EndIf
EndIf

//Verifica se o colete esta desativado e indo para um cliente
If lRet .and. FwFldGet("TFQ_ENTDES") == edCLIENTE .and. oMdl:GetValue("TFO_ITMOV") == itCOLETE
	If alltrim(upper(Posicione("TE1",1,xFilial('TE1') + oMdl:GetValue('TFO_ITCOD'),"TE1_SITUA"))) == "9" .or. ;
		alltrim(upper(Posicione("TE1",1,xFilial('TE1') + oMdl:GetValue('TFO_ITCOD'),"TE1_SITUA"))) == "A"
		
		lRet := .F.
		Help( ,,,STR0076,STR0077, 1, 0 ) //"Colete Descartado ou Desativado" //"O colete escolhido tem situação igual a Desativado ou Descartado"
	EndIf
EndIf

Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880GtSld

Valida a quantidade de saldo de um local para movimentação

@since 18/10/2017
@version P12
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880GtSld(cCodPro,cEntida,cLocal)
Local nRet  := 0
Local cTemp := GetNextAlias()

If cEntida == '1'
	BeginSQL Alias cTemp
		
		SELECT 
			TFP_SALDO
		FROM 	
			%Table:TFP% TFP
		WHERE 
			TFP.TFP_FILIAL = %Exp:xFilial("TFP")% AND
			TFP.TFP_PRODUT = %Exp:cCodPro% AND
			TFP.TFP_CODINT = %Exp:cLocal% AND
			TFP.TFP_MOVIM = 1 AND
			TFP.%NotDel%
	EndSql
	
	nRet := ( cTemp )->( TFP_SALDO ) 
	
	(cTemp)->(DbCloseArea())
	
ElseIf cEntida == '2'
	
	BeginSQL Alias cTemp
		SELECT 
				TFP_SALDO
			FROM 	
				%Table:TFP% TFP
			WHERE 
				TFP.TFP_FILIAL = %Exp:xFilial("TFP")% AND
				TFP.TFP_PRODUT = %Exp:cCodPro% AND
				TFP.TFP_CODLOC = %Exp:cLocal% AND
				TFP.TFP_MOVIM = 2 AND
				TFP.%NotDel%
	EndSql
	
	nRet := ( cTemp )->( TFP_SALDO ) 
	
	(cTemp)->(DbCloseArea())
					
EndIf

Return nRet 

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880VldQt

Valida a quantidade da munição

@since 18/10/2017
@version P12
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880VldQt(oModel) 
Local lRet := .T.
Local oTFQMaster := oModel:GetModel('TFQMASTER')
Local oTFODetail := oModel:GetModel('TFOMUNI')
Local nQtd 		:= oTFODetail:GetValue('TFO_QTDE')
Local cCodPro	:= oTFODetail:GetValue('TFO_PRODUT')
Local cEntida	:= oTFQMaster:GetValue('TFQ_ENTORI')
Local cLocal	:= oTFQMaster:GetValue('TFQ_ORIGEM')

If !Empty(cEntida) .And. !Empty(cLocal) .And. !Empty(cCodPro)
	lRet := At880GtSld(cCodPro,cEntida,cLocal) >= nQtd
EndIf	  

If !lRet
	Help( ,, "At880Qtd",, STR0081 + Alltrim(cCodPro) + STR0082, 1, 0 )
EndIf

Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At880VldTp

Valida o tipo de movimentação

@since 18/10/2017
@version P12
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At880VldTp()
Local oModel 		:= FwModelActive()
Local oTFQMaster 	:= oModel:GetModel('TFQMASTER')
Local oTFODetail 	:= oModel:GetModel('TFOMUNI')
Local lRet 			:= .T.
Local aRows 		:= FwSaveRows()
Local nI    		:= 0

If oTFQMaster:GetValue('TFQ_MOTIVO') == mtMANUTENCAO
	If !oTFODetail:IsEmpty()
		For nI := 1 To oTFODetail:Length()
			oTFODetail:GoLine(nI)
			oTFODetail:DeleteLine()
		Next nI 
		
	EndIf
	
	oTFODetail:SetNoDeleteLine(.T.)
	oTFODetail:SetNoInsertLine(.T.)
	oTFODetail:SetNoUpdateLine(.T.)
Else
	oTFODetail:SetNoDeleteLine(.F.)
	oTFODetail:SetNoInsertLine(.F.)
	oTFODetail:SetNoUpdateLine(.F.)
EndIf

FwRestRows( aRows )

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At880PrxTIO
Inicializador padrão do campo TIO_CODIGO

@author Serviços
@since 18/08/2016
/*/
//-------------------------------------------------------------------
Function At880PrxTIO()
Local cNum 		:= ''
Local aArea		:= GetArea()
Local aAreaTIO	:= TIO->(GetArea())

DbSelectArea("TIO")
TIO->(DbSetOrder(2))
dbGoTop()

cNum := GetSXENum("TIO","TIO_CODIGO")

While TIO->(MsSeek(xFilial("TIO")+cNum))
	If ( __lSx8 )
		TIO->(ConfirmSX8())
	EndIf
	cNum := GETSXENUM('TIO','TIO_CODIGO')
EndDo

RestArea(aAreaTIO)
RestArea(aArea)

Return cNum