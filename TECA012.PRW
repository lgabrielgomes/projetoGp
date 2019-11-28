#include "TECA012.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

Function TECA012()

Local oMBrowse

oMBrowse:= FWmBrowse():New() 
oMBrowse:SetAlias("AA1")
oMBrowse:SetDescription(STR0001)   // "Cadastro de Restrições"
oMBrowse:Activate()
	
Return

//----------------------------------------------------------
/*/{Protheus.doc} ModelDef()
Model - Relacionamentos - restrição de cadastro operacional 

@Return 	model
@author 	Serviços
@since 		28/09/2015
/*/
//----------------------------------------------------------
Static Function ModelDef()

Local oModel		:= Nil
Local oStrAA1 		:= FWFormStruct(1,"AA1")
Local oStrTW2Cli 	:= FWFormStruct(1,"TW2")
Local oStrTW2Loc 	:= FWFormStruct(1,"TW2")

oStrAA1:AddField(	"Situação",;								// 	[01]  C   Titulo do campo
					"Situação",;								// 	[02]  C   ToolTip do campo
					 "AA1_TECSIT",;								// 	[03]  C   Id do Field
					 "C",;										// 	[04]  C   Tipo do campo
					 20,;					// 	[05]  N   Tamanho do campo
					 0,;										// 	[06]  N   Decimal do campo
					 NIL,;										// 	[07]  B   Code-block de validação do campo
					 NIL,;										// 	[08]  B   Code-block de validação When do campo
					 NIL,;										//	[09]  A   Lista de valores permitido do campo
					 .F.,;										//	[10]  L   Indica se o campo tem preenchimento obrigatório
					 {|| At012Sit()},;									//	[11]  B   Code-block de inicializacao do campo
					 NIL,;										//	[12]  L   Indica se trata-se de um campo chave
					 .T.,;										//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
					 .T.)										// 	[14]  L   Indica se o campo é virtual

oModel := MPFormModel():New("TECA012", /*bPreValidacao*/,/*bPosValidacao*/,/*bCommit*/,/*bCancel*/ )
oModel:AddFields("AA1MASTER",/*cOwner*/,oStrAA1, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

//restricoes cliente
oModel:AddGrid( "TW2DETCLI", "AA1MASTER", oStrTW2Cli, {|oModel,nLine,cAcao,cCampo| At012PrAge(oModel,cAcao)} /*bLinePre*/,{|oModel| At012VlAge(oModel)},/*bPreVal*/ ,/*bPosVal*/ , /*bLoad */ )
oModel:SetRelation( "TW2DETCLI", { { "TW2_FILIAL", "xFilial('TW2')" }, { "TW2_CODTEC", "AA1_CODTEC"},{ "TW2_TIPO", "'1'"} }, TW2->(IndexKey(1)) )
oModel:SetDescription(STR0004) //"Cliente"

//restricoes local
oModel:AddGrid( "TW2DETLOC", "AA1MASTER", oStrTW2Loc, {|oModel,nLine,cAcao,cCampo| At012PrAge(oModel,cAcao)},{|oModel| At012VlAge(oModel)},/*bPreVal*/ ,/*bPosVal*/ , /*bLoad */ )
oModel:SetRelation( "TW2DETLOC", { { "TW2_FILIAL", "xFilial('TW2')" }, { "TW2_CODTEC", "AA1_CODTEC" } , { "TW2_TIPO", "'2'"} }, TW2->(IndexKey(1)) )
oModel:SetDescription(STR0005) //"Local de Atendimento"

//inicializador padrao 
oStrTW2Cli:SetProperty("TW2_NOMCLI",MODEL_FIELD_INIT,{||Posicione("SA1",1,xFilial("SA1")+TW2->TW2_CLIENT,"A1_NOME")})
oStrTW2Loc:SetProperty("TW2_DESLOC",MODEL_FIELD_INIT,{||Posicione("ABS",1,xFilial("ABS")+TW2->TW2_LOCAL,"ABS_DESCRI")})

oStrAA1:SetProperty('*', MODEL_FIELD_OBRIGAT , .F. )
oStrTW2Cli:SetProperty('TW2_CODTEC', MODEL_FIELD_OBRIGAT , .F. )
oStrTW2Loc:SetProperty('TW2_CODTEC', MODEL_FIELD_OBRIGAT , .F. )

oStrTW2Cli:SetProperty('TW2_TIPO', MODEL_FIELD_INIT , {|| "1" } )
oStrTW2Loc:SetProperty('TW2_TIPO', MODEL_FIELD_INIT , {|| "2" } )
oStrTW2Cli:SetProperty('TW2_DTFIM',MODEL_FIELD_WHEN ,{|| at012VlCpo(1) } )
oStrTW2Loc:SetProperty('TW2_DTFIM',MODEL_FIELD_WHEN ,{|| at012VlCpo(2) } )

//validacao data
oStrTW2Cli:SetProperty("TW2_DTINI", MODEL_FIELD_VALID, {|oModel| At012VlDt("TW2DETCLI","TW2_DTFIM","TW2_DTINI","TW2_DTFIM") } )
oStrTW2Loc:SetProperty("TW2_DTINI", MODEL_FIELD_VALID, {|oModel| At012VlDt("TW2DETLOC","TW2_DTFIM","TW2_DTINI","TW2_DTFIM") } )
oStrTW2Cli:SetProperty("TW2_DTFIM", MODEL_FIELD_VALID, {|oModel| At012VlDt("TW2DETCLI","TW2_DTFIM","TW2_DTINI","TW2_DTFIM") } )
oStrTW2Loc:SetProperty("TW2_DTFIM", MODEL_FIELD_VALID, {|oModel| At012VlDt("TW2DETLOC","TW2_DTFIM","TW2_DTINI","TW2_DTFIM") } )

oModel:GetModel('AA1MASTER'):SetOnlyView(.T.)
oModel:GetModel('AA1MASTER'):SetOnlyQuery(.T.)
oModel:GetModel('TW2DETCLI'):SetOptional(.T.)
oModel:GetModel('TW2DETLOC'):SetOptional(.T.)

Return(oModel)

//----------------------------------------------------------
/*/{Protheus.doc} ViewDef()
View - Relacionamentos - Restrição de cadastro operacional 

@Return 	view
@author 	Serviços
@since 		28/09/2015
/*/
//----------------------------------------------------------
Static Function ViewDef()

Local oView
Local oModel  := FWLoadModel("TECA012")  
Local oStrAA1 := FWFormStruct( 2, "AA1" , {|cCpo| AllTrim(cCpo)$'AA1_CODTEC+AA1_NOMTEC' }  )
Local oStrTW2Cli := FWFormStruct( 2, "TW2" ,{|cCpo| !AllTrim(cCpo)$'TW2_TIPO+TW2_CODTEC+TW2_NOME+TW2_LOCAL+TW2_DESLOC' } )
Local oStrTW2Loc := FWFormStruct( 2, "TW2" ,{|cCpo| !AllTrim(cCpo)$'TW2_TIPO+TW2_CODTEC+TW2_NOME+TW2_CLIENT+TW2_LOJA+TW2_NOMCLI' } )

oStrAA1:AddField( ;									// Ord. Tipo Desc.
						"AA1_TECSIT",;					// [01] C Nome do Campo
						"04",;							// [02] C Ordem
						"Situação",;						// [03] C Titulo do campo # "Local" 
						"Situação do Atendente",;						// [04] C Descrição do campo # "Local" 
						Nil,;							// [05] A Array com Help
						"C",;							// [06] C Tipo do campo
						"@!",;							// [07] C Picture
						NIL,;							// [08] B Bloco de Picture Var
						"",;							// [09] C Consulta F3
						.F.,;							// [10] L Indica se o campo é editável
						NIL,;							// [11] C Pasta do campo
						NIL,;							// [12] C Agrupamento do campo
						NIL,;							// [13] A Lista de valores permitido do campo (Combo)
						NIL,;							// [14] N Tamanho Maximo da maior opção do combo
						NIL,;							// [15] C Inicializador de Browse
						.T.,;							// [16] L Indica se o campo é virtual
						NIL )							// [17] C Picture Variável

oStrAA1:SetNoFolder()

oView := FWFormView():New()
oView:SetModel(oModel)
oView:AddField( 'VIEW_AA1' , oStrAA1, 'AA1MASTER' )
oView:AddGrid ( 'VIEW_TW2CLI' , oStrTW2Cli, 'TW2DETCLI' )
oView:AddGrid ( 'VIEW_TW2LOC' , oStrTW2Loc, 'TW2DETLOC' )

oView:CreateHorizontalBox('SUPERIOR', 10 ) //atendente
oView:CreateHorizontalBox('INFERIOR', 90 ) //restrições

// Criação da pasta para conter as abas da parte inferior
oView:CreateFolder( "ABAS", "INFERIOR" )

// Criação das Abas
oView:AddSheet( "ABAS", "ABA01", STR0004 )	// "Cliente"
oView:AddSheet( "ABAS", "ABA02", STR0005 )	// "Local de Atendimento"

// Criação das áreas de exibição dos dados nas abas
oView:CreateHorizontalBox( "ID_ABA01", 100,,, "ABAS", "ABA01" )
oView:CreateHorizontalBox( "ID_ABA02", 100,,, "ABAS", "ABA02" )

oView:SetOwnerView( 'VIEW_AA1' , 'SUPERIOR' ) 
oView:SetOwnerView( 'VIEW_TW2CLI' , 'ID_ABA01' )	// Grid Cliente
oView:SetOwnerView( 'VIEW_TW2LOC' , 'ID_ABA02' )	// Grid Local de Atendimento

Return oView
//----------------------------------------------------------
/*/{Protheus.doc} MenuDef()
MenuDef - Cadastro de Restrições 

@Return 	MenuDef
@author 	Serviços
@since 		03/08/2015
/*/
//----------------------------------------------------------
Static Function MenuDef()
Local aRotina := {}

ADD OPTION aRotina TITLE STR0002 ACTION 'At012Manut(AA1_CODTEC)' OPERATION 2 ACCESS 0 //"Manutenção"
ADD OPTION aRotina TITLE STR0003 ACTION 'At012Vis(AA1_CODTEC)'   OPERATION 4 ACCESS 0 //"Visualização"
 
Return(aRotina)

//----------------------------------------------------------
/*/{Protheus.doc} At012Manut(cCodTec)

Manutenção Restição operacional	 

@sample     At012Manut(cCodTec)

@return      

@author     serviços
@since      28/09/2015
@version    P12
/*/

//----------------------------------------------------------
Function At012Manut(cCodTec)

Local aArea 	:= {}
Local oModel 	:= Nil
Local aArea := GetArea()
Local lRet := .F.

lRet := At680Perm( Nil, __cUserId, "021" ) // Define regras de restrição

If !lRet
	Help( ,, 'TECA012',, STR0008, 1, 0) // "Usuário sem permissão para regras de restrição operacional"		
Else
	DbSelectArea("AA1")
	AA1->(DbSetOrder(1))//
	If AA1->(DbSeek(xFilial("AA1")+cCodTec))
			lRet := .T.
			FWExecView( STR0006, "VIEWDEF.TECA012", MODEL_OPERATION_UPDATE, /*oDlg*/, {||.T.} /*bCloseOk*/,	{||.T.}/*bOk*/,/*nReducao*/, /*aButtons*/, {||.T.}/*bCancel*/ )	//"Restrição"							
	Else
		MsgStop(STR0007) //"Registro não encontrado"
	Endif	
Endif

Return lRet

//----------------------------------------------------------
/*/{Protheus.doc} At012Vis(cCodTec)

Manutenção Restição operacional	 

@sample     At012Vis(cCodTec) 

@return      

@author     serviços
@since      28/09/2015
@version    P12
/*/

//----------------------------------------------------------
Function At012Vis(cCodTec)

Local aArea 	:= {}
Local oModel 	:= Nil
Local aArea := GetArea()
Local lRet := .F.

DbSelectArea("AA1")
AA1->(DbSetOrder(1))//
If AA1->(DbSeek(xFilial("AA1")+cCodTec))
		lRet := .T.
		FWExecView( STR0006, "VIEWDEF.TECA012", MODEL_OPERATION_VIEW, /*oDlg*/, {||.T.} /*bCloseOk*/,	{||.T.}/*bOk*/,/*nReducao*/, /*aButtons*/, {||.T.}/*bCancel*/ )	//"Restrição"							
Else
	MsgStop(STR0007) //"Registro não encontrado"
Endif	

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At012VlDt
Função para validação dos períodos iniciais e finais das restrições.

@sample 	At012VlDt(cModelo,cCpoSelec,cCpoDtIn,cCpoDtFm)

@since		30/09/2015      
@version	P12

@return 	lRet, Lógico, retorna .T. se data for válida.

@param  	oModel, Objeto, Model utilizado para a consistencia das informações.
@param  	cModelo, Caracter, nome do modelo de dados principal.
@param  	cCpoSelec, Caracter, nome do campo da data selecionada para validação.
@param  	cCpoDtIn, Caracter, nome do campo da data inicial.
@param  	cCpoDtFm, Caracter, nome do campo da data final.
/*/
//------------------------------------------------------------------------------
Function At012VlDt(cModelo,cCpoSelec,cCpoDtIni,cCpoDtFim)

Local oModel  := FwModelActive()
Local oMdl		:= oModel:GetModel(cModelo)
Local lRet		:= .T.

If  oMdl:GetValue('TW2_TEMPO') == '2' //contrato determinado
	If !Empty(oMdl:GetValue('TW2_DTFIM')) .AND. !Empty(oMdl:GetValue('TW2_DTINI'))
		If DtoS(oMdl:GetValue(cCpoDtIni)) > DtoS(oMdl:GetValue(cCpoDtFim))  		
			lRet := .F.
			Help(,,"AT012VLDDT",,STR0009,1,0) // "Data final deve ser maior ou igual a data inicail da restrição para contratos determinados!"
		EndIf
	Endif
Elseif oMdl:GetValue('TW2_TEMPO') == '1' //contrato determinado
	If !Empty(oMdl:GetValue('TW2_DTFIM'))
		Help(,,"AT012AVLDDT",,STR0002,1,0) //"Para contratos indeterminados, deixar a data final em branco"
		lRet := .F.
	Endif	
EndIf

Return(lRet)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At012VlAge(oModel)
Função para validação da linha digitada para verificar se existe agenda para o atendente

@sample 	At012VlAge(oModel)

@since		01/10/2015      
@version	P12

@return 	lRet, Lógico, retorna .T. se nao existir agenda futura.
/*/
//------------------------------------------------------------------------------
Function At012VlAge(oModel)

Local lRet:= .F.
Local oMdlAA1:= oModel:GetModel("AA1MASTER")
Local oMdlTW2CLI:= oModel:GetModel("TW2DETCLI")
Local oMdlTW2LOC:= oModel:GetModel("TW2DETLOC")
Local cCodTec:=""
Local dDtIni:=""
Local dDtFim:=""
Local lOk:= .F.  
Local cTempo := ""

cCodTec:=FWFLDGET("AA1_CODTEC")
dDtIni:=oModel:getValue("TW2_DTINI")
dDtFim:=oModel:getValue("TW2_DTFIM")
tmpAgenda:=GetNextAlias()

If oModel:getId() == "TW2DETCLI"
	If Empty(oModel:GetValue("TW2_CLIENT"))
		Help(,,"AT012VLCLI",,STR0012,1,0) // "Favor informar codigo do cliente."
	ElseIf oModel:GetValue("TW2_TEMPO") == '2' //contrato determinado
		If Empty(dDtFIm)
			Help(,,"AT012DTFIM",,STR0014,1,0) // "Para contratos determinados, preencher a data final."
			lOk:= .F.
		Else
			lOk:= .T.	
		Endif
	Else
		lOk:= .T.
	Endif
Elseif oModel:getId() == "TW2DETLOC"
	If Empty(oModel:GetValue("TW2_LOCAL"))
		Help(,,"AT012VLLOC",,STR0013,1,0) // "Favor informar local de atendimento."	
	ElseIf oModel:GetValue("TW2_TEMPO") == '2' //contrato determinado
		If Empty(dDtFim)
			Help(,,"AT012DTFIM",,STR0014,1,0) // "Para contratos determinados, preencher a data final."
			lOk:= .F.
		Else
			lOk:= .T.	
		Endif
	Else
		lOk:= .T.
	Endif
Endif

If lOk
	If !empty(dDtFim)
		cTempo := "%AND ABB_DTFIM <='"+ DtoS(dDtFim) + "'%"
	Else
		cTempo := '%%'
	Endif
	If oModel:getId() == "TW2DETCLI"
		//verificar a agenda da atendente do registro na tabela ABB por cliente
		BeginSql Alias tmpAgenda
		SELECT count(*) as regABB
		FROM %table:ABB% ABB
		WHERE	ABB_FILIAL = %xFilial:ABB%
			AND ABB_LOCAL IN (Select ABS_LOCAL
							From %table:ABS% ABS
							Where ABS_CODIGO = %Exp:oModel:GetValue("TW2_CLIENT")% 
								AND ABS_LOJA = %Exp:oModel:GetValue("TW2_LOJA")%
								AND ABS.%NotDel%
								Group By ABS_LOCAL )
			AND ABB_ATIVO ='1' AND ABB_ATENDE ='2'
			AND ABB_CODTEC = %Exp:cCodTec%
			AND ABB_DTINI >=  %Exp:dDtIni%
			AND ABB.%NotDel%
			%Exp:cTempo%
		EndSql
	Elseif oModel:getId() == "TW2DETLOC"
		BeginSql Alias tmpAgenda
		SELECT count(*) as regABB
		FROM %table:ABB% ABB
		WHERE	ABB_FILIAL = %xFilial:ABB%
			AND ABB_LOCAL  = %Exp:oModel:GetValue("TW2_LOCAL")%
			AND ABB_ATIVO ='1' AND ABB_ATENDE ='2'
			AND ABB_CODTEC = %Exp:cCodTec%
			AND ABB_DTINI >=  %Exp:dDtIni%
			AND ABB.%NotDel%
			%Exp:cTempo%
		EndSql
	Endif
	DbSelectArea(tmpAgenda)
	If (tmpAgenda)->regABB > 0 //existe agenda posterior atendida ou com manutenção 
		Help(,,"AT012VLDAGE",,STR0011,1,0) // "Atendente com alocação no período de restrição."
	Else
		lRet:= .T.	
	Endif
Endif

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At012VlCpo(oModel)
Função para validação do campo para edição

@sample 	At012VlCpo(oModel)

@since		01/10/2015      
@version	P12

@return 	lRet, Lógico, retorna .T. se nao existir agenda futura.
/*/
//------------------------------------------------------------------------------
Function At012VlCpo(nTipo)

Local lRet:= .F.
Local oModel:=FWModelActive()

If nTipo == 1
	If oModel:GetModel("TW2DETCLI"):GetValue("TW2_TEMPO") == '2' //contrato determinado
		lRet:= .T.
	Else
		lRet:= .F.
	Endif
Elseif nTipo == 2
	If oModel:GetModel("TW2DETLOC"):GetValue("TW2_TEMPO") == '2' //contrato determinado
		lRet:= .T.
	Else
		lRet:= .F.
	Endif
Endif

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At012Blq(cAtend,dDataDe,dDataAte,cLocal)
Função para validação de restrição operacional

@sample 	At012Blq(cAtend,dDataDe,dDataAte,cLocal)

@since		01/10/2015      
@version	P12

@return 	lRet, Lógico, retorna .T. se nao existir restrições operacionais.
/*/
//------------------------------------------------------------------------------
Function At012Blq(cAtend,dDataDe,dDataAte,cLocal)

Local lRet      := .T.
Local aRestri   :={}
Local cTpResLoc := "0"
Local cTpResCli := "0"

cTpResLoc:=at012ResLoc(cAtend,dDataDe,dDataAte,cLocal)
If cTpResLoc == "0"
	cTpResCli:=at012ResCli(cAtend,dDataDe,dDataAte,cLocal)
	If cTpResCli == '1'
		If !MsgYesNo(STR0015,STR0017) //"Atendente com restrição operacional de aviso."##"Deseja Continuar?" 
			lRet := .F.
		Endif
	Elseif cTpResCli == '2'
	 	lRet:= .F.
	 	Help(,,"AT012REST",,STR0016,1,0) // "Atendente com restrição operacional para o local/cliente"		
	Endif	
Else
	If cTpResLoc == '1'
		If !MsgYesNo(STR0015,STR0017) //"Atendente com restrição operacional de aviso."##"Deseja Continuar?" 
			lRet := .F.
		Endif
	Elseif cTpResLoc == '2'
	 	lRet:= .F.
	 	Help(,,"AT012REST",,STR0016,1,0) // "Atendente com restrição operacional para o local/cliente"		
	Endif
Endif

Return lRet

//-----------------------------------------------------------------------------
/*/{Protheus.doc} At012ResLoc(cAtend,dDataDe,dDataAte,cLocal)
Função para validação de restrição operacional

@sample 	At012ResLoc(cAtend,dDataDe,dDataAte,cLocal)

@since		06/11/2015      
@version	P12

@return 	lRet, 0,1,2
/*/
//------------------------------------------------------------------------------
Function at012ResLoc(cAtend,dDataDe,dDataAte,cLocal)

Local cResLoc:="0"
Local lAchou:=.F.
Local tmpRestri:=""

//query com as restricoes do local de atendimento
If !Empty(cLocal)
	tmpRestri:= GetNextAlias()
	BeginSql Alias tmpRestri
		Select TW2_CODTEC, TW2_CLIENT, TW2_LOJA, TW2_LOCAL, TW2_TEMPO, TW2_DTINI, TW2_DTFIM, TW2_RESTRI
		From %table:TW2% TW2
		left join %table:ABS% ABS on ABS_FILIAL = %xFilial:ABS% 
			AND ABS_LOCAL = TW2_LOCAL
		WHERE	TW2_FILIAL = %xFilial:TW2%
		AND TW2_CODTEC = %Exp:cAtend%
		AND TW2_LOCAL = %Exp:cLocal% 
		AND TW2.%NotDel%
	EndSql
	
	DbSelectArea(tmpRestri)
	(tmpRestri)->(DbGoTop())
	While (tmpRestri)->(! Eof())
		If !lAchou
			//verificar tipo restricao
			If  (tmpRestri)->TW2_TEMPO == '1' // periodo indeterminado
				If ( dtos(dDataDe) > (tmpRestri)->TW2_DTINI ) .OR. ( dtos(dDataAte) > (tmpRestri)->TW2_DTINI ) 
					cResLoc:= (tmpRestri)->TW2_RESTRI
					lAchou:= .T.
				Endif
			Elseif (tmpRestri)->TW2_TEMPO == '2' //periodo determinado
				If  (dtos(dDataDe) > (tmpRestri)->TW2_DTINI) .AND. (dtos(dDataDe) < (tmpRestri)->TW2_DTFIM ) 
					cResLoc:= (tmpRestri)->TW2_RESTRI
					lAchou:= .T.
				Endif
			Endif
		Endif
	(tmpRestri)->(DbSkip())
	Enddo
Endif

Return cResloc 

//-----------------------------------------------------------------------------
/*/{Protheus.doc} At012ResCli(cAtend,dDataDe,dDataAte,cLocal)
Função para validação de restrição operacional

@sample 	At012ResLoc(cAtend,dDataDe,dDataAte,cLocal)

@since		06/11/2015      
@version	P12

@return 	lRet, 0,1,2
/*/
//-----------------------------------------------------------------------------
Function at012ResCli(cAtend,dDataDe,dDataAte,cLocal)

Local cResCli:= "0"
Local cCliente:=""
Local cLojaCli:=""
Local lAchou:=.F.
Local tmpResCli:=""

//cliente do local de atendimento
cCliente:= Posicione("ABS",1,xFilial("ABS")+cLocal,"ABS_CODIGO")
cLojaCli:= Posicione("ABS",1,xFilial("ABS")+cLocal,"ABS_LOJA")
	
tmpResCli:= GetNextAlias()
BeginSql Alias tmpResCli
	Select TW2_CODTEC, TW2_CLIENT, TW2_LOJA, TW2_LOCAL, TW2_TEMPO, TW2_DTINI, TW2_DTFIM, TW2_RESTRI
	From %table:TW2% TW2
	left join %table:ABS% ABS on ABS_FILIAL = %xFilial:ABS% 
		AND ABS_LOCAL = TW2_LOCAL
	WHERE	TW2_FILIAL = %xFilial:TW2%
	AND TW2_CODTEC = %Exp:cAtend%
	AND TW2_CLIENT = %Exp:cCliente%
	AND TW2_LOJA = %Exp:cLojaCli%
	AND TW2.%NotDel%
EndSql
	
DbSelectArea(tmpResCli)
(tmpResCli)->(DbGoTop())
While (tmpResCli)->(! Eof())
	If !lAchou
		//verificar tipo restricao
		If  (tmpResCli)->TW2_TEMPO == '1' // periodo indeterminado
			If ( dtos(dDataDe) > (tmpResCli)->TW2_DTINI ) .OR. ( dtos(dDataAte) > (tmpResCli)->TW2_DTINI ) 
				cResCli:= (tmpResCli)->TW2_RESTRI
				lAchou:= .T.
			Endif
		Elseif (tmpResCli)->TW2_TEMPO == '2' //periodo determinado
			If  (dtos(dDataDe) > (tmpResCli)->TW2_DTINI) .AND. (dtos(dDataDe) < (tmpResCli)->TW2_DTFIM ) 
				cResCli:= (tmpResCli)->TW2_RESTRI
				lAchou:= .T.
			Endif
		Endif
	Endif
(tmpResCli)->(DbSkip())
Enddo

Return cResCli 


//-----------------------------------------------------------------------------
/*/{Protheus.doc} At012PrAge(oModel,cAcao)
Função de pré valid dos grids de cliente e local de atendimento

@sample 	At012PrAge(oModel,cAcao)

@since		25/06/2018      
@version	P12

@return 	lRet
/*/
//-----------------------------------------------------------------------------
Function At012PrAge(oModel,cAcao)
Local lRet := .T.

If cAcao == 'DELETE' .And. !oModel:IsInserted()
	Help( ,, 'TECA012DEL',,STR0018, 1, 0, NIL, NIL, NIL, NIL, NIL, {STR0019})	
	lRet := .F.
EndIf

Return lRet

//-----------------------------------------------------------------------------
/*/{Protheus.doc} At012PrAge(oModel,cAcao)
Função de pré valid dos grids de cliente e local de atendimento

@sample 	At012PrAge(oModel,cAcao)

@since		25/06/2018      
@version	P12

@return 	lRet
/*/
//-----------------------------------------------------------------------------
Function At012Sit()

Local cCodTec := AA1->AA1_CODTEC
Local cMatric := Posicione("AA1",1,xFilial("AA1")+ cCodTec ,"AA1_CDFUNC")
Local cDisAlo := Posicione("AA1",1,xFilial("AA1")+ cCodTec ,"AA1_ALOCA")
Local cTecSit := ""

DbSelectArea("SRA")
SRA->(DbSetOrder(1))// FILIAL + MATRICULA
If SRA->(DbSeek(xFilial("SRA") + cMatric))

	If SRA->RA_SITFOLH == "D" 
		cTecSit := STR0020 //"Demitido"
	ElseIf SRA->RA_SITFOLH == "A"
		cTecSit := STR0021 //"Afastado"
	ElseIf SRA->RA_SITFOLH == "F"
		cTecSit :=  STR0022 //"Férias"
	Else
		cTecSit := STR0023 //"Normal"
	EndIf
Else
	If cDisAlo == "1"
		cTecSit := STR0024 //"Disponível"
	Else
		cTecSit := STR0025 //"Indisponível"
	EndIf
	
EndIf

Return cTecSit
