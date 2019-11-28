#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH" 
#INCLUDE "TECA680.CH"

Static aPermissao := { { "001", STR0001 },; // "Define os grupos e permissões de acesso?"
                       { "002", STR0002 },; // "Pode incluir itens para alocação de recurso humano sem cobrança de valor para o cliente? (Cortesia)"
                       { "003", STR0003 },; // "Pode incluir itens de material de implantação sem cobrança de valor para o cliente?"
                       { "004", STR0004 },; // "Pode incluir itens de material de consumo sem cobrança de valor para o cliente?"
                       { "005", STR0005 },; // "Pode alocar mais atendentes que a quantidade vendida (excedente)?"
                       { "006", STR0006 },; // "Pode alocar mais armamentos que a quantidade definida?"
                       { "007", STR0007 },; // "Pode movimentar armamento fora do contrato?"
                       { "008", STR0008 },; // "Edita filtro de alocação: Centro de Custo?"
                       { "009", STR0009 },; // "Edita filtro de alocação: Região?"
                       { "010", STR0010 },; // "Edita filtro de alocação: Função?"
                       { "011", STR0011 },; // "Edita filtro de alocação: Cargo?"
                       { "012", STR0012 },; // "Edita filtro de alocação: Habilidades?"
                       { "013", STR0013 },; // "Edita filtro de alocação: Turno?"
                       { "014", STR0014 },; // "Edita a Configuração de Alocação?"
                       { "015", STR0015 },; // "Pode alocar recurso humano fora do período planejado?"
                       { "016", STR0023 },; // "Edita filtro de alocação: Sequência de Turno?"
                       { "017", STR0024 },; // "Pode realizar alocações com conflito?"
                       { "018", STR0025 },; // "Pode efetuar a movimentação da munição excedendo as 3 cargas?"
                       { "019", STR0026 },; // "Edita Filtro de Alocação: Curso?"
                       { "020", STR0027 },; // "Edita Filtro de Alocação: Característica?"
                       { "021", STR0028 },; // "Define Restrição Operacional?"
                       { "022", STR0032 },; // "Central do Cliente: Permite consultar opções do grupo Oportunidades "
                       { "023", STR0033 },; // "Central do Cliente: Permite consultar opções do grupo Propostas Comerciais"
                       { "024", STR0034 },; // "Central do Cliente: Permite consultar opções do grupo Contratos"
                       { "025", STR0035 },; // "Central do Cliente: Permite consultar opções do grupo Financeiro"
                       { "026", STR0036 },; // "Central do Cliente: Permite consultar opções do grupo Faturamento"
                       { "027", STR0037 },; // "Central do Cliente: Permite consultar opções do grupo Locais de Atendimento"
                       { "028", STR0038 },; // "Central do Cliente: Permite consultar opções do grupo Equipamentos"
                       { "029", STR0039 },; // "Central do Cliente: Permite consultar opções do grupo Recursos Humanos"
                       { "030", STR0040 },; // "Central do Cliente: Permite consultar opções do grupo Ordens de Servico"
                       { "031", STR0041 },; // "Central do Cliente: Permite consultar opções do grupo Armamentos"
                       { "032", STR0042 },; // "Pode inserir local sem valor?"
                       { "033", STR0029 },; // "Pode incluir itens para alocação de recurso humano sem cobrança de valor para o cliente? (Item Extra)"
                       { "034", STR0030 },; // "Pode incluir itens de material de implantação com cobrança de valor para o cliente? (Item Extra)"
                       { "035", STR0031 },; // "Pode incluir itens de material de consumo com cobrança de valor para o cliente? (Item Extra)"
					   { "036", STR0043 }}  // "Pode excluir itens importados pelo facilitador no orçamento de serviços?"
Static oBrwAcessos := Nil

//----------------------------------------------------------
/*/{Protheus.doc} TECA680()
@description	Cadastro de Grupo de acesso / perfil  
@Return		nil
@author	 	Serviços
@since			07/04/2014
/*/
//----------------------------------------------------------
Function TECA680()

DbSelectArea("TCT")
DbSelectArea("TIN")

At680Ajust()

//Cria a tela para o browse
oBrwAcessos	:= FwMarkBrowse():New()
oBrwAcessos:SetAlias("TIN")
oBrwAcessos:SetMenuDef("TECA680")
oBrwAcessos:DisableDetails()
oBrwAcessos:SetDescription(STR0016)  // "Cadastro de Grupo de Acesso/Perfil"
oBrwAcessos:Activate()
oBrwAcessos:DeActivate()
oBrwAcessos	:= NIL
Return


//----------------------------------------------------------
/*/{Protheus.doc} MenuDef()
@description	MenuDef - Cadastro de Grupo de acesso/perfil
@Return	 	MenuDef
@author	 	Serviços
@since			07/04/2014
/*/
//----------------------------------------------------------
Static Function MenuDef()

Local aRotina	:= {}

ADD OPTION aRotina TITLE STR0017 ACTION "AxPesqui"  OPERATION 1 ACCESS 0 // "Pesquisar"
ADD OPTION aRotina TITLE STR0018 ACTION "At680Auto" OPERATION 2 ACCESS 0 // "Visualizar"
ADD OPTION aRotina TITLE STR0019 ACTION "At680Auto" OPERATION 3 ACCESS 0 // "Incluir"
ADD OPTION aRotina TITLE STR0020 ACTION "At680Auto" OPERATION 4 ACCESS 0 // "Alterar"
ADD OPTION aRotina Title STR0021 ACTION "At680Auto" OPERATION 5 ACCESS 0 // "Excluir"
Return(aRotina)


//----------------------------------------------------------
/*/{Protheus.doc} ModelDef()
@description	Model - Cadastro de Grupo de acesso/perfil
@Return	 	model
@author	 	Serviços
@since			07/04/2013
/*/
//----------------------------------------------------------
Static Function ModelDef()

Local oModel
Local oStrCabec	:= FWFormStruct(1,"TIN", {|cCampo|  ( Alltrim( cCampo )$"TIN_GRUPO+TIN_NOME+TIN_MSBLQL" ) } )
Local oStrGrid	:= FWFormStruct(1,"TIN", {|cCampo| !( Alltrim( cCampo )$"TIN_NOME+TIN_MSBLQL" ) } )
Local oStruTCT	:= FWFormStruct(1,"TCT")
Local aAux			:= {}

aAux				:= FwStruTrigger("TIN_CODUSR","TIN_NOMUSR","UsrRetName(FwFldGet('TIN_CODUSR'))",.F.,Nil,Nil,Nil)
oStrGrid:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

oStrGrid:SetProperty( "TIN_GRUPO" 	, MODEL_FIELD_OBRIGAT, .F. )
oStrGrid:SetProperty( "TIN_NOMUSR"	, MODEL_FIELD_INIT, {|oModel| At680Init(oModel)} )

oStruTCT:SetProperty( "TCT_GRUPO", MODEL_FIELD_OBRIGAT, .F. )

// Cria o objeto do Modelo de Dados
oModel				:= MPFormModel():New("TECA680", /*bPreValidacao*/,/*bPosValidacao*/,/*bCommit*/,/*bCancel*/ )

//Cabecalho do grupo
oModel:AddFields("TINMASTER",/*cOwner*/,oStrCabec, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

//Grid detalhes do grupo
oModel:AddGrid( "TINDETAIL","TINMASTER",oStrGrid,/*bLinePre*/,/*bLinePost*/, /*bPreVal*/, /*bPosVal*/)
oModel:SetRelation( "TINDETAIL", { { "TIN_FILIAL", "xFilial('TIN')" }, { "TIN_GRUPO", "TIN_GRUPO" } }, TIN->(IndexKey(1)) )

//Grid permissoes do grupo
oModel:AddGrid( "TCTDETAIL","TINMASTER",oStruTCT,/*bLinePre*/,/*bLinePost*/, /*bPreVal*/, /*bPosVal*/)
oModel:SetRelation( "TCTDETAIL", { { "TCT_FILIAL", "xFilial('TCT')" }, { "TCT_GRUPO", "TIN_GRUPO" } }, TCT->(IndexKey(1)) )

oModel:SetPrimaryKey( {} )
oModel:SetDescription(STR0016) // Cadastro de Grupo de acesso/perfil

oModel:SetActivate( {|oModel| InitDados( oModel ) } )
Return(oModel)


//----------------------------------------------------------
/*/{Protheus.doc} ViewDef()
@description	View - Cadastro de Lista de emails
@Return		view
@author		Serviços
@since			09/09/2013
/*/
//----------------------------------------------------------
Static Function ViewDef()

Local oView
Local oModel		:= FWLoadModel("TECA680")
Local oStrCabec	:= FWFormStruct( 2,"TIN", {|cCampo|  ( Alltrim( cCampo )$"TIN_GRUPO+TIN_NOME+TIN_MSBLQL" ) } )
Local oStrGrid	:= FWFormStruct( 2,"TIN", {|cCampo| !( Alltrim( cCampo )$"TIN_GRUPO+TIN_NOME+TIN_MSBLQL" ) } )
Local oStruTCT	:= FWFormStruct( 2,"TCT")

oStrGrid:RemoveField( "TIN_GRUPO" )
oStruTCT:RemoveField( "TCT_GRUPO" )

oView				:= FWFormView():New()

oView:SetModel( oModel )
oView:SetDescription( STR0016 ) // "Cadastro de Grupo de acesso/perfil"
oView:SetCloseOnOk({|| .T. } )

oView:AddField("TIN_CABEC", oStrCabec, "TINMASTER" )
oView:AddGrid( "TIN_GRID" , oStrGrid , "TINDETAIL" )
oView:AddGrid( "TCT_GRID" , oStruTCT , "TCTDETAIL" )

//--------------------------------------
//		Cria os Box's
//--------------------------------------
oView:CreateHorizontalBox( "TOP"   , 10 )
oView:CreateHorizontalBox( "MIDDLE", 50 )
oView:CreateHorizontalBox( "DOWN"	, 40 )

//--------------------------------------
//		Associa os componentes ao Box
//--------------------------------------
oView:SetOwnerView( "TIN_CABEC", "TOP" 	)
oView:SetOwnerView( "TIN_GRID" , "MIDDLE" )
oView:SetOwnerView( "TCT_GRID" , "DOWN" 	)

// Incrementa automaticamente o campo ao incluir uma nova linha
oView:AddIncrementField( "TIN_GRID", "TIN_ITEM" )
Return(oView)


//----------------------------------------------------------
/*/{Protheus.doc} InitDados()
@description	Inicializa as informações do cadastro de grupo/acessps
@sample	 	InitDados()
@param			oModel, Objeto, objeto geral do model que será alterado
@author	 	Serviços
@since			09/09/2013
/*/
//----------------------------------------------------------
Static Function InitDados(oModel)

Local aSaveRows	:= {}
Local oMdlTCT 	:= oModel:GetModel("TCTDETAIL")
Local nTotPermi 	:= Len(aPermissao)
Local nI	 		:= 0

aSaveRows			:= FwSaveRows()

If oModel:GetOperation() == MODEL_OPERATION_INSERT

	For nI:=1 To nTotPermi

		If nI > 1
			oMdlTCT:AddLine()
		EndIf

		oMdlTCT:SetValue( "TCT_ITEM", aPermissao[nI][1] )
		oMdlTCT:SetValue( "TCT_ACESSO", aPermissao[nI][2] )

	Next nI

EndIf

FwRestRows( aSaveRows )

oModel:GetModel("TCTDETAIL"):SetNoInsertLine(.T.)
oModel:GetModel("TCTDETAIL"):SetNoDeleteLine(.T.)
Return(Nil)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At680DesPerm
@description	Retorna a descrição da regra cadastrada
@author	 	Serviços
@since 			08/04/2014
@version	 	P12
@return		cRet - Retorna a descrição da regra cadastrada
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At680DesPerm(cCodItem)

Local cRet		:= ""
Local nPos		:= aScan( aPermissao, { |x| x[1] == cCodItem } )

If nPos > 0
	cRet	:= aPermissao[nPos][2]
EndIf
Return(cRet)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At680Auto
@description	Rotinas para utilizar o posicionamento da tabela a ser chamada  
@author	 	Serviços
@since 			08/04/2014
@version	 	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At680Auto( cAlias, nReg, nOpcx )

Local cTitulo		:= ""
Local lRet			:= (nOpcx == 3)
Local nTINRecNo	:= TIN->(RecNo())
Local cTINGrupo	:= ""
Local nOpeMnu

If nOpcx == 2
	cTitulo	:= STR0018 //"Visualizar"
	nOpeMnu	:= MODEL_OPERATION_VIEW
ElseIf nOpcx == 3
	cTitulo	:= STR0019 // "Incluir"
	nOpeMnu	:= MODEL_OPERATION_INSERT
ElseIf nOpcx == 4
	cTitulo	:= STR0020 //"Alterar"
	nOpeMnu	:= MODEL_OPERATION_UPDATE
ElseIf nOpcx == 5
	cTitulo	:= STR0021 //"Excluir"
	nOpeMnu	:= MODEL_OPERATION_DELETE
EndIf

If TIN->(DbSeek(xFilial('TIN'))) .And. !At680Perm( , __cUserId, '001' )
	lRet	:= .F.
	Help( ,, 'AT680ACESSO',, STR0022, 1, 0) // 'Usuário sem permissão para acesso a essas informações.'
Else
	lRet	:= .T.
EndIf

If lRet .And. nOpcx <> 3
	DbSelectArea("TIN")
	DbSetOrder(1) //TIN_FILIAL+TIN_GRUPO+TIN_ITEM
	If	nTINRecNo > 0
		TIN->(dBGoTo(nTINRecNo))
		cTINGrupo	:= TIN->TIN_GRUPO
		lRet		:= TIN->(dbSeek(xFilial("TIN")+cTINGrupo))
	Else
		lRet		:= .F.
	EndIf
EndIf

If lRet .And. !( Empty(cTitulo) )
	FWExecView(cTitulo,"VIEWDEF.TECA680",nOpeMnu,/*oDlg*/,{||.T.}/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/)
	oBrwAcessos:Data():DeActivate()
	oBrwAcessos:Data():Activate()
	oBrwAcessos:GoTo( 1, .T.)
	oBrwAcessos:Refresh(.T.)
EndIf
Return(Nil)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At680Perm
@description	Rotina para a consulta ou validação dos acessos do grupo/usuario  
@param			cGrupo, String, grupo qual deseja consulta ou verificar o acesso
@param		 	cUsuario, String, usuario qual deseja consulta ou verificar o acesso
@param			cRegra, String, regra qual deseja verificar o acesso
@author		Serviços
@since			10/04/2014
@version		P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At680Perm( cGrupo, cIdUsuario, cRegra )

Local xRet  		:= .F.
Local aArea 		:= GetArea()
Local cSeek 		:= ""

Default cGrupo 		:= ""
Default cIdUsuario 	:= ""
Default cRegra 		:= ""

If ValType(xRet) == "L" .And. !xRet
	xRet	:= (cIdUsuario == "000000")
EndIf

dbSelectArea("TIN")
TIN->(dbSetOrder(3))

If !xRet .And. TIN->(DbSeek( xFilial('TIN')))
	// Verifica qual grupo o usuario pertence
	If Empty(cGrupo) .And. !( Empty(cIdUsuario) )
		If TIN->(dbSeek(xFilial("TIN")+cIdUsuario))
			cGrupo		:= TIN->TIN_GRUPO
		EndIf
	EndIf

	// Verifica a regra ou verifica a lista de acessos
	If !( Empty(cGrupo) )

		dbSelectArea("TCT")
		TCT->(dbSetOrder(1))

		cSeek	:= xFilial("TCT")+cGrupo

		If !( Empty(cRegra) )
			cSeek	+= cRegra
		EndIf

		If TCT->(dbSeek(cSeek))
			If !( Empty(cRegra) )
				xRet	:= (TCT->TCT_PODE == "1")
			Else
				xRet	:= {}
				// Bloco para carregar os acessos			
				While TCT->(! Eof()) .And. (TCT->TCT_FILIAL + TCT->TCT_GRUPO == cSeek)
					aAdd( xRet, { TCT->TCT_ITEM, TCT->TCT_PODE } )
					TCT->(dbSkip())
				EndDo
			EndIf
		EndIf
	EndIf
Else
	// Quando não tem grupo de acesso configurado
	// não considera as permissões
	xRet	:= .T.
EndIf

RestArea(aArea)
Return(xRet)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At680Init
@description	Inicializa o campo de nome do usuario
@author	 	Serviços
@since			27/01/2015
@version	 	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At680Init(oModel)

Local nOper	:= oModel:GetOperation()
Local cRet		:= ""

If nOper <> MODEL_OPERATION_INSERT
	If oModel:GetLine() == 0
		cRet	:= UsrRetName(TIN->TIN_CODUSR)
	EndIf
EndIf
Return(cRet)

//----------------------------------------------------------
/*/{Protheus.doc} At680Ajust
@description 	Realiza os ajustes adicionando os itens que não existem ainda no banco de dados
@author 		josimar.assuncao
@since 			2017.02.15
@version 		P12
/*/
//----------------------------------------------------------
Static Function At680Ajust()

Local cQryTemp 	:= GetNextAlias()
Local nMaxPerms 	:= Len( aPermissao )
Local aArea 		:= GetArea()
Local aAreaTCT 	:= TCT->(GetArea())
Local aAreaTIN 	:= TIN->(GetArea())
Local cFilTIN 	:= xFilial("TIN")
Local cFilTCT 	:= xFilial("TCT")
Local oModel 		:= FWLoadModel( "TECA680" )
Local oMdlTCT 	:= Nil
Local nI 			:= 0

BeginSQL Alias cQryTemp
	SELECT DISTINCT TIN_GRUPO
	  FROM %Table:TIN% TIN
	 WHERE TIN.TIN_FILIAL = %xFilial:TCT%
	   AND TIN.%NotDel%
	   AND %Exp:nMaxPerms% > ( SELECT COUNT( TCTIN.TCT_ITEM )
	                             FROM %Table:TCT% TCTIN
	                            WHERE TCTIN.TCT_FILIAL = %xFilial:TCT%
	                              AND TCTIN.%NotDel%
	                              AND TCTIN.TCT_GRUPO = TIN.TIN_GRUPO
	                         )
EndSQL

DbSelectArea("TCT")
TCT->( DbSetOrder( 1 ) ) // TCT_FILIAL+TCT_GRUPO+TCT_ITEM

DbSelectArea("TIN")
TIN->( DbSetOrder( 1 ) ) // TIN_FILIAL+TIN_GRUPO+TIN_ITEM

While (cQryTemp)->(! Eof())
	TIN->( DbSeek( cFilTIN + (cQryTemp)->TIN_GRUPO ) )
	TCT->( DbSeek( cFilTCT + (cQryTemp)->TIN_GRUPO ) )

	oModel:SetOperation( MODEL_OPERATION_UPDATE )
	oModel:Activate()

	oMdlTCT	:= oModel:GetModel("TCTDETAIL")
	oMdlTCT:SetNoInsertLine(.F.)

	If nMaxPerms > oMdlTCT:Length()
		For nI := 1 To nMaxPerms
			// quando não encontrar a permissão, realiza a inclusão.
			If !(oMdlTCT:SeekLine( { { "TCT_ITEM", aPermissao[nI][1] } } ) )
				oMdlTCT:AddLine()
				oMdlTCT:SetValue( "TCT_ITEM", aPermissao[nI][1] )
				oMdlTCT:SetValue( "TCT_ACESSO", aPermissao[nI][2] )
			EndIf
		Next nI
	EndIf

	oModel:VldData()
	oModel:CommitData()

	oModel:DeActivate()

	(cQryTemp)->(DbSkip())
EndDo

oModel:Destroy()
(cQryTemp)->(DbCloseArea())

RestArea(aAreaTIN)
RestArea(aAreaTCT)
RestArea(aArea)
Return