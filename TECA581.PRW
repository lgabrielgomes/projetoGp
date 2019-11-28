#include "TECA581.CH"
#include "PROTHEUS.CH"
#include "FWMVCDEF.CH"

Static lLimpTW1 := .T. //Auxilia na limpeza dos campos.
Static nTipoRt	:= 0   //Tipo de rota de cobertura.

//----------------------------------------------------------
/*/{Protheus.doc} TECA581
@description	Rota de cobertura
@return	 		NIL
@author	 		Serviços
@since			04/06/2018
@version		P12
/*/
//----------------------------------------------------------
Function TECA581()
Local oMBrowse

If At581EscRt()
	oMBrowse	:= FWmBrowse():New()
	oMBrowse:SetAlias("TW0")
	oMBrowse:SetDescription(STR0001)   // "Rota de Cobertura"

	If nTipoRt == 1
		oMBrowse:SetFilterDefault( "TW0_TIPO $ '1|2|3' " )  
	Elseif nTipoRt == 2
		oMBrowse:SetFilterDefault( "TW0_TIPO = '4' " )  
	Endif

	oMBrowse:Activate()
Endif

Return


//----------------------------------------------------------
/*/{Protheus.doc} ModelDef
@description	Model - Relacionamentos - Rota de cobertura 
@return			oExp1: Modelo MVC da Rota de cobertura
@author			Serviços
@since			04/06/2018
@version		P12
/*/
//----------------------------------------------------------
Static Function ModelDef()
Local oModel	:= Nil
Local oStrTW0 	:= FWFormStruct(1,"TW0")
Local oStrTW1 	:= FWFormStruct(1,"TW1")
Local bPosValid	:= {|oModel|At581PosVl(oModel)}
Local bLinePost	:= {|a,b|At581LnPos(a,b)}
Local bLgIni	:= {|a,b,c|At581IniLg(a,b,c)}
Local bAction	:= {|oModel|At581Act(oModel)}
Local bCommit	:= {|a,b,c|At581Cmt(a,b,c)}

oStrTW1:AddField( 		"Status" 	,;  	// [01] C Titulo do campo  # Status
						"Status"	,;   	// [02] C ToolTip do campo # Status
						"TW1_STATUS",;   	// [03] C identificador (ID) do Field
						"BT"		,;   	// [04] C Tipo do campo
						1			,;   	// [05] N Tamanho do campo
						0			,;   	// [06] N Decimal do campo
						nil	 		,;   	// [07] B Code-block de validação do campo 
						Nil			,;    	// [08] B Code-block de validação When do campo 
						Nil			,;   	// [09] A Lista de valores permitido do campo 
						.F.			,;  	// [10] L Indica se o campo tem preenchimento obrigatório 
						bLgIni		,;  // [11] B Code-block de inicializacao do campo                
						Nil			,; 		// [12] L Indica se trata de um campo chave 
						Nil			,;    	// [13] L Indica se o campo pode receber valor em uma operação de update.
 						.T. )            	// [14] L Indica se o campo é virtual

oModel := MPFormModel():New("TECA581", /*bPreValidacao*/, bPosValid, bCommit, /*bCancel*/ )
oModel:AddFields("TW0MASTER", /*cOwner*/, oStrTW0, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

//Relacionamento das tabelas
oModel:AddGrid("TW1DETAIL", "TW0MASTER", oStrTW1,/*bLinePre*/, bLinePost , /*bPosVal*/, , /*bLoad*/)
oModel:SetRelation("TW1DETAIL", {{"TW1_FILIAL", "xFilial('TW0')"}, {"TW1_CODTW0", "TW0_COD"}}, TW1->(IndexKey(1)))
oModel:SetDescription(STR0001)	//"Rota de Cobertura"

oModel:GetModel("TW1DETAIL"):SetOptional(.T.)

oModel:GetModel("TW1DETAIL"):SetUniqueLine({"TW1_CODTFF", "TW1_CODTGX", "TW1_CODTDX", "TW1_ATEND", "TW1_GRUPO" })

oModel:SetActivate(bAction)

Return oModel


//----------------------------------------------------------
/*/{Protheus.doc} ViewDef
@description	View - Relacionamentos - Rota de cobertura 
@sample			ViewDef()
@return			oExp1: View da Rota de cobertura
@author			Serviços
@since			04/06/2018
@version		P12
/*/
//----------------------------------------------------------
Static Function ViewDef()
Local oView
Local oModel  := FWLoadModel("TECA581")
Local oStrTW0 := FWFormStruct(2, "TW0" )
Local oStrTW1 := FWFormStruct(2, "TW1", {|cCpo| At581Cmps(cCpo)} )

oStrTW1:AddField( 	"TW1_STATUS"	,; // cIdField
                   	"01"			,; // cOrdem
                   	"  "			,; // cTitulo
                   	"  "			,; // cDescric
                   	{}				,; // aHelp
                   	"BT"			,; // cType
					""				,; // cPicture
                    Nil				,; // nPictVar
                    Nil				,; // Consulta F3
                    .T.				,; // lCanChange
                    Nil				,; // cFolder
                    Nil				,; // cGroup
                    Nil				,; // aComboValues
                    Nil				,; // nMaxLenCombo
                    Nil				,; // cIniBrow
                    .T.				,; // lVirtual
                    Nil ) 			   // cPictVar

oStrTW0:SetNoFolder()

oView	:= FWFormView():New()
oView:SetModel(oModel)

If nTipoRt == 2
	oStrTW1:SetProperty("TW1_ATEND",MVC_VIEW_LOOKUP,"AA1")
Endif

oView:AddField("VIEW_TW0", oStrTW0, 'TW0MASTER')
oView:AddGrid("VIEW_TW1", oStrTW1, 'TW1DETAIL')

oView:CreateHorizontalBox("SUPERIOR", 20)
oView:CreateHorizontalBox("INFERIOR", 80)

oView:SetOwnerView("VIEW_TW0", "SUPERIOR")
oView:SetOwnerView("VIEW_TW1", "INFERIOR")

//oView:AddUserButton(STR0002, STR0002, {|oView| At581FilRegiao()}) // "Filtra Região" ## "Filtra Região"
oView:AddUserButton(STR0003, STR0003, {|oView| At581PostoFun()})  // "Vis. Posto X Func." ## "Vis. Posto X Func."

oView:SetViewProperty("VIEW_TW1", "GRIDDOUBLECLICK", {{|oFormulario,cFieldName,nLineGrid,nLineModel| at581DClck(oFormulario,cFieldName)}})


Return oView


//----------------------------------------------------------
/*/{Protheus.doc} MenuDef()
@description	MenuDef da Rota de cobertura 
@sample		MenuDef()
@return 		aExp1: Array com as rotinas específicas
@author 		Serviços
@since			04/06/2018
@version		P12
/*/
//----------------------------------------------------------
Static Function MenuDef()
Local aRotina := FwMVCMenu("TECA581")

//Retira a copia do Menu
nPos := AsCan(aRotina, { |x|  x[4] == 9 })

If nPos > 0 
	Adel(aRotina,nPos)
	Asize(aRotina,Len(aRotina)-1)
EndIf

//Altera a chamada da funçao do alterar
nPos := AsCan(aRotina, { |x|  x[4] == 4 })

If nPos > 0
	aRotina[nPos,2] := "At581Update"
EndIf

Return aRotina

//-----------------------------------------------------------------------------
/*/{Protheus.doc} At581PosVl
@description	Movimentação ou Remoção da rota de cobertura
@sample			At581PosVl(oModel)
@param			oExp1: Objeto geral do model que será alterado
@return			lExp1: .T.=Pós-validação do modelo OK // .F.=Pós-validação do modelo possui inconsistências
@author			Serviços
@since			04/06/2018
@version		P12
/*/
//------------------------------------------------------------------------------
Function At581PosVl(oModel)
Local oMdlTW0		:= oModel:GetModel("TW0MASTER")
Local cRota			:= oMdlTW0:GetValue("TW0_COD")
Local cCodTec		:= oMdlTW0:GetValue("TW0_ATEND")
Local cTipoCob		:= oMdlTW0:GetValue("TW0_TIPO")
Local cTmpQry		:= ""
Local lRet			:= .T.
Local oMdlTW1 		:= oModel:GetModel("TW1DETAIL")
Local nX 			:= 0
Local nMaxLines 	:= 0
Local aHrInfos 		:= {}
Local nPosErro 		:= 0

If	oModel:GetOperation() == MODEL_OPERATION_DELETE

	// Verifica se a rota de cobertura está sendo utilizada por alguma gestão de escalas
	cTmpQry	:= GetNextAlias()
	BeginSql Alias cTmpQry
		SELECT count(*) as REGTGZ
		  FROM %table:TGZ% TGZ
		 WHERE TGZ.TGZ_FILIAL = %xFilial:TGZ%
		   AND TGZ.%NotDel%
		   AND TGZ.TGZ_CODTW0 = %Exp:cRota% 
	EndSql

	If (cTmpQry)->REGTGZ > 0 //Foram encontrados registros de cobertura na Gestão de Escalas que participam do histórico da rota de cobertura
		Help( ,, "At581PosVl",, STR0037, 1, 0 ) // "Não é permitida a exclusão de uma rota de cobertura que tenha sido utilizada em alguma Gestão de Escalas."
		lRet	:= .F.
	EndIf

	(cTmpQry)->(DbCloseArea())

	If lRet
		// Verifica se a rota de cobertura possui um atendente associado
		If	!( Empty(cCodTec) )
			Help( ,, "At581PosVl",, STR0038, 1, 0 ) // "Não é permitida a exclusão de uma rota de cobertura que possua um atendente associado a ela."
			lRet	:= .F.
		EndIf
	EndIf
Else
	If cTipoCob $ "2|3"
/*		
		cTmpQry := GetNextAlias()
	
		BeginSql Alias cTmpQry
			SELECT TW1.TW1_CODTW0,TW1_COD
			FROM %table:TW1% TW1
			WHERE TW1.TW1_FILIAL = %xFilial:TW1%
			  AND TW1.TW1_CODTFF = %Exp:cCodTFF%
			  AND TW1.%NotDel%
		EndSql

		For nX := 1 To oMdlTW1:Length()
			oMdlTW1:Goline(nX)
			
		Next nX
	*/
	Endif
EndIf

Return	lRet


//-----------------------------------------------------------------------------
/*/{Protheus.doc} At581MvRmv
@description	Movimentação ou Remoção da rota de cobertura
@sample			At581MvRmv(cTpOper, cRota, cAtuAtend)
@param			cExp1: Tipo de operação ("MV"=Movimentação p/rota de cobertura, ou "RE"=Remoção da rota de cobertura)
@param			cExp2: Rota em que o atendente estará ou está alocado
@param			cExp3: Código do atendente
@return			lExp1: .T.=Processamento realizado // .F.=Processamento não realizado 
@author			Serviços
@since			07/06/2016
@version		P12
/*/
//------------------------------------------------------------------------------
Function At581MvRmv(cTpOper, cRota, cAtuAtend, lAutomato, cAtend, cCobert)
Local cAtdMvRmv		:= CriaVar("AA1_CODTEC", .F.)
Local cPictAtd		:= PesqPict("AA1", "AA1_CODTEC")
Local cTitAtend		:= Posicione("SX3",2,"AA1_CODTEC","X3Titulo()")
Local cTitNAtend	:= Posicione("SX3",2,"AA1_NOMTEC","X3Titulo()")
Local oDlg			:= ""
Local cTitulo		:= ""
Local cDesAten		:= ""
Local lWhenAtd		:= .F.
Local lOk			:= .F.
Local lRet			:= .F.

Default cTpOper		:= "MV"
Default cRota		:= TW0->TW0_COD
Default cAtuAtend	:= TW0->TW0_ATEND
Default lAutomato 	:= .F.
Default cAtend		:= ""
Default cCobert		:= ""

If cTpOper == "MV"
	lWhenAtd	:= .T.
	cTitulo	:= STR0022	//"Movimentação da Rota de Cobertura"
Else
	lWhenAtd	:= .F.
	cTitulo	:= STR0029 //"Remoção da Rota de Cobertura"
EndIf

If !Empty(cAtuAtend)
	cAtdMvRmv	:= cAtuAtend
	cDesAten	:= Posicione("AA1", 1, xFilial("AA1")+cAtdMvRmv, "AA1_NOMTEC")
EndIf

If !lAutomato
	Define Dialog oDlg Title cTitulo From 167,115 to 270,630 Pixel
	@ 005,005 Say cTitAtend of oDlg Pixel
	@ 005,045 MsGet cAtdMvRmv Picture cPictAtd F3 "AA1" Valid If(ExistCpo("AA1", cAtdMvRmv),;
                                                            Eval({|| cDesAten := Posicione("AA1", 1, xFilial("AA1")+cAtdMvRmv, "AA1_NOMTEC"),;
                                                                     oDesAten:Refresh()}),;
                                                            "") When lWhenAtd of oDlg Pixel
	@ 020,005 Say cTitNAtend of oDlg Pixel
	@ 020,045 MsGet oDesAten Var cDesAten Size 210,0                When .F.      of oDlg Pixel
	Define SButton From 037,200 Type 1 Enable of oDlg Action ( lOk := .T., oDlg:End() )
	Define SButton From 037,230 Type 2 Enable of oDlg Action ( lOk := .F., oDlg:End() )
	Activate Dialog oDlg Centered
Else 
	cDesAten := Posicione("AA1", 1, xFilial("AA1")+cAtend, "AA1_NOMTEC")
	cAtdMvRmv := cAtend
	lOk := .T.
EndIf

If	lOk
	If	cTpOper == "MV" .AND. cAtdMvRmv == cAtuAtend
		Help( ,, "At581MvRmv",, STR0032, 1, 0 ) //"Não é possível realizar a movimentação para o mesmo atendente."
		lRet := .F.
	Else
		If	cTpOper == "RE" .AND. Empty(cAtdMvRmv)
			Help( ,, "At581MvRmv",, STR0028, 1, 0 ) //"Não existe atendente preenchido na rota de cobertura. Remoção permitida apenas para rotas que já tenham atendente"
			lRet	:= .F.
		Else
			( lRet := At581Efet(cTpOper, cRota, dDatabase, cAtdMvRmv, lAutomato, cCobert) )
		EndIf
	EndIf
EndIf
Return	lRet


//-----------------------------------------------------------------
/*/{Protheus.doc} At581FilRegiao 
@description	Apresentar a tela de filtro das regiões
@sample			At581FilRegiao()
@return			NIL
@author			Serviços
@since			25/06/2015 
@version		P12
/*/
//--------------------------------------------------------------------
Function At581FilRegiao()
Local aParams		:= {}
Local lUseCombo	:= .F.

//Carrega as regiões do usuário
aParams	:= {'SX5', 'A2_', 'Região', 1, 'X5_FILIAL+X5_TABELA+X5_CHAVE', 'A2', {{'SX5', 1, 'X5_DESCRI'}}, {}, {||.F.}, 'A2', /*VldExtra*/ }  // 'Região'
TECA670(aParams, lUseCombo)
Return

//--------------------------------------------------------------------
/*/{Protheus.doc} At581PostoFun 
@description	Relação de Posto X Funcionário
@sample			At581PostoFun()
@return			NIL
@author			Serviços
@since			03/07/2015 
@version		P12
/*/
//--------------------------------------------------------------------
Function At581PostoFun()
//Carrega amarracao Posto X Funcionário
If !Empty(FwFldGet("TW1_CODTFF"))
	DbSelectArea("TFF")
	TFF->(DbSetOrder(1))
	TFF->(DbSeek(xFilial("TFF")+FwFldGet("TW1_CODTFF")))
	FWExecView(STR0017, "VIEWDEF.TECA580E", MODEL_OPERATION_VIEW, /*oDlg*/, {||.T.},{||.T.},/*nReducao*/, /*aButtons*/, {||.T.}/*bCancel*/) //"Posto X Funcionário"
Else
	Aviso(STR0013, STR0018, {"OK"}, 2) //"Atenção"#"Informe o campo codigo RH "
EndIf

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At581Efet
@description	Realiza a efetivação da movimentação ou remoção da rota de cobertura na gestão de escalas
@sample			At581Efet(cTpOper, cRota, cAtuAtend, dData, cAtdMvRmv)
@param			cExp1 - Tipo de operação ("MV"=Movimentar; "RE"=Remover")
@param			cExp2 - Rota em que o atendente estará alocado
@param			dExp3 - Data da efetivação do atendente na rota de cobertura
@param			cExp4 - Código do atendente que será associado ou removido da associação à rota de cobertura
@param			cExp5 - Controle de execução do robô da Automação para execução dos testes
@return			lExp1: .T.=Movimentação/Remoção executada com sucesso // .F.=Movimentação/Remoção não executada
@author			Serviços
@since			15/06/2016
@version		P12
/*/
//------------------------------------------------------------------------------
Function At581Efet(cTpOper, cRota, dData, cAtdMvRmv, lAutomato, cCobert)
Local aOldAlias		:= (Alias())->(GetArea())
Local cTitCodTFF	:= AllTrim(Posicione("SX3",2,"TW1_CODTFF","X3Titulo()"))
Local cTitAtend		:= AllTrim(Posicione("SX3",2,"TW0_ATEND" ,"X3Titulo()"))
Local cTitCodTGX	:= AllTrim(Posicione("SX3",2,"TW1_CODTGX","X3Titulo()"))
Local oModel		:= Nil
Local oMdlTW0		:= Nil
Local oMdlTW1		:= Nil
Local oMdlTFF		:= Nil
Local oMdlTGX		:= Nil
Local oMdlTGZ		:= Nil
Local nInd1			:= 0
Local nInd2			:= 0
Local nTotHrsTrb	:= 0
Local nGrupo		:= 0
Local nDelLine		:= 0
Local cAtuAtend		:= ""
Local cTmpAgenda	:= ""
Local cItem			:= ""
Local cCodTFF		:= ""
Local cCodTGX		:= ""
Local cCodTec		:= ""
Local cLogTGX		:= ""
Local cLogABB		:= ""
Local cMsgShwLog	:= ""
Local aOldAlias2	:= {}
Local aDesalocar	:= {}
Local aAgenda		:= {}
Local aCalAtd		:= {}
Local aErro			:= {}
Local aArrAtend		:= {}
Local aAgCodTec		:= {}
Local aNoExcCTec	:= {}
Local lFoundTGZ		:= .F.
Local lDelLine		:= .F.
Local lRet			:= .T.
Local cTipoCob		:= ""
Local nTpRota		:= 0
Local aAloc			:= {}
Default cTpOper		:= "MV"
Default cRota		:= TW0->TW0_COD
Default cAtdMvRmv	:= ""
Default dData		:= dDataBase
Default cCobert		:= ""

//posicionar na TW0
DbSelectArea("TW0")
DbSetOrder(1)	//TW0_FILIAL+TW0_COD
DbSeek(xFilial("TW0")+cRota)

cAtuAtend	:= TW0->TW0_ATEND
If	Empty(cAtdMvRmv) .AND. (cTpOper == "MV" .OR. cTpOper == "RE") 
	cAtdMvRmv	:= TW0->TW0_ATEND
EndIf

If	cTpOper == "MV" .AND. cAtdMvRmv == cAtuAtend

	Help( ,, "At581Efet",, STR0032, 1, 0 ) //"Não é possível realizar a movimentação para o mesmo atendente."
	lRet := .F.

ElseIf	cTpOper == "RE" .AND. Empty(cAtdMvRmv)

	Help( ,, "At581Efet",, STR0028, 1, 0 ) //"Não existe atendente preenchido na rota de cobertura. Remoção permitida apenas para rotas que já tenham atendente"
	lRet	:= .F.

Else

	oModel		:= FWLoadModel("TECA581")	//Cria um objeto de Modelo de dados baseado no ModelDef do fonte informado
	oModel:SetOperation(MODEL_OPERATION_UPDATE)

	If TW0->TW0_TIPO $ "1|2|3"
		nTpRota := 1
	Elseif TW0->TW0_TIPO == "4"
		nTpRota := 2
	Endif

	At581EscRt(nTpRota)
	
	oModel:Activate()

	oMdlTW0	:= oModel:GetModel("TW0MASTER")
	oMdlTW1	:= oModel:GetModel("TW1DETAIL")

	If	(! Empty(cAtuAtend)) .AND. aScan(aArrAtend,{|x| x == cAtuAtend}) == 0
		aAdd(aArrAtend, cAtuAtend)
	EndIf
	If	(! Empty(cAtdMvRmv)) .AND. aScan(aArrAtend,{|x| x == cAtdMvRmv}) == 0
		aAdd(aArrAtend, cAtdMvRmv)
	EndIf

	If nTpRota == 1
		//===========================================================================================================================
		// Análise geral dos itens da rota "TW1", avaliando se todos os registros são válidos para efetivar a movimentação/remoção...
		//===========================================================================================================================
		For nInd1 := 1 to oMdlTW1:Length()
	
			oMdlTW1:GoLine(nInd1)
			cCodTFF	:= oMdlTW1:GetValue("TW1_CODTFF")
			cCodTGX	:= oMdlTW1:GetValue("TW1_CODTGX")
	
			DbSelectArea("TFF")
			TFF->(DbSetOrder(1)) //TFF_FILIAL+TFF_COD
			TFF->(DbSeek(xFilial("TFF")+cCodTFF))
			oMdlTFF	:= FWLoadModel("TECA580E")	//Cria um objeto de Modelo de dados baseado no ModelDef do fonte informado
			oMdlTFF:SetOperation(MODEL_OPERATION_VIEW)
			oMdlTFF:Activate()
	
			oMdlTGX	:= oMdlTFF:GetModel("TGXDETAIL")
	
			// Verifica se existe na Gestão de Escalas a configuração para ALMOCISTA ou JANTISTA
			// Posicionar na linha da TGX
			If ! ( oMdlTGX:SeekLine({{"TGX_COD",cCodTGX}}) )
				cLogTGX	+= "- ("+cTitCodTGX+" = '"+cCodTGX+"')"+CRLF
				lRet		:= .F.
			EndIf
	
			// Verifica se existe agenda atendida ou com manutenção para o atendente com data posterior à atual
			For nInd2 := 1 to	Len(aArrAtend)
				cCodTec := aArrAtend[nInd2]
				If	!( At581GAgMA(cCodTFF, cCodTec, dData) )
					If	!( cCodTec $ cLogABB )
						cLogABB	+= "- ("+cTitCodTFF+" = '"+cCodTFF+"') "+cTitAtend+" = '"+cCodTec+"'-"+AllTrim(Posicione("AA1",1,xFilial("AA1")+cCodTec,"AA1_NOMTEC"))+CRLF
					EndIf
					lRet	:= .F.
				EndIf
			Next nInd2
	
		Next nInd1
	
		If	Len(aArrAtend) == 0
			cLogABB	+= "- " + STR0033 + CRLF	//"Não foram encontrados atendentes configurados para a execução deste procedimento."
			lRet		:= .F.
		EndIf
	Endif
	//===========================================================================================================================
	// Inicia a efetivação da movimentação/remoção após a análise geral dos itens da rota "TW1" e da confirmação de que todos os
	// registros são válidos
	//===========================================================================================================================
	If	lRet

		aAgCodTec	:= {}
		aNoExcCTec	:= {}
		cCodTec		:= If(! Empty(cAtuAtend), cAtuAtend, cAtdMvRmv)
		aOldAlias2	:= (Alias())->(GetArea())
		cTmpAgenda	:= GetNextAlias()

		// Levantamento das agendas pendentes do atendente.
		For nInd1 := 1 to oMdlTW1:Length()	// Lê os itens da rota TW1

			oMdlTW1:GoLine(nInd1)

			If nTpRota == 1
				cCodTFF	:= oMdlTW1:GetValue("TW1_CODTFF")
			Elseif nTpRota == 2
				
				aAloc := TxEscCalen(cCodTec,dData,dData)
				
				If !Empty(aAloc)
					cCodTFF := aAloc[1][11]
				Endif
			Endif
			
			If !Empty(cCodTFF)
				BeginSql Alias cTmpAgenda
					SELECT ABB.R_E_C_N_O_ as RECABB
					  FROM %table:ABB% ABB
					       LEFT JOIN %table:ABQ% ABQ on %xFilial:ABQ% = ABQ.ABQ_FILIAL
					                                AND ABQ.%NotDel%
					                                AND %xFilial:ABB% = ABQ.ABQ_FILTFF
					                                AND ABB.ABB_IDCFAL = ABQ.ABQ_CONTRT || ABQ.ABQ_ITEM || ABQ.ABQ_ORIGEM
					       LEFT JOIN %table:TFF% TFF on TFF.TFF_FILIAL = %xFilial:TFF%
					                                AND TFF.%NotDel%
					                                AND TFF.TFF_COD = %Exp:cCodTFF%
					                                AND TFF.TFF_COD = ABQ.ABQ_CODTFF
					 WHERE ABB.ABB_FILIAL = %xFilial:ABB%
					   AND ABB.%NotDel%
					   AND ABB.ABB_MANUT   = '2'
					   AND ABB.ABB_ATENDE  = '2'
					   AND ABB.ABB_ATIVO   = '1'
					   AND ABB.ABB_CODTEC  = %Exp:cCodTec%
					   AND ABB.ABB_DTINI  >= %Exp:dData%
					   AND ABB.ABB_TIPOMV <> 'RES'
				EndSql
	
				While (cTmpAgenda)->(! Eof())
					If	aScan(aAgCodTec, {|x| x == (cTmpAgenda)->RECABB}) == 0
						aAdd(aAgCodTec,(cTmpAgenda)->RECABB)
					EndIf
					(cTmpAgenda)->(DbSkip())
				EndDo
				(cTmpAgenda)->(DbCloseArea())
	
				BeginSql Alias cTmpAgenda
					SELECT ABB.R_E_C_N_O_ as RECABB
					  FROM %table:ABB% ABB
					       LEFT JOIN %table:ABQ% ABQ on %xFilial:ABQ% = ABQ.ABQ_FILIAL
					                                AND ABQ.%NotDel%
					                                AND %xFilial:ABB% = ABQ.ABQ_FILTFF
					                                AND ABB.ABB_IDCFAL = ABQ.ABQ_CONTRT || ABQ.ABQ_ITEM || ABQ.ABQ_ORIGEM
					       LEFT JOIN %table:TFF% TFF on TFF.TFF_FILIAL = %xFilial:TFF%
					                                AND TFF.%NotDel%
					                                AND TFF.TFF_COD = %Exp:cCodTFF%
					                                AND TFF.TFF_COD = ABQ.ABQ_CODTFF
					 WHERE ABB.ABB_FILIAL = %xFilial:ABB%
					   AND ABB.%NotDel%
					   AND ( ABB.ABB_MANUT = '1' OR ABB.ABB_ATENDE = '1' )
					   AND ABB.ABB_CODTEC = %Exp:cCodTec%
					   AND ABB.ABB_DTINI <= %Exp:dData%
					   AND ABB.ABB_ATIVO  = '1'
					   AND ABB.ABB_TIPOMV <> 'RES'
				EndSql
	
				If (cTmpAgenda)->(! Eof())
					aAdd(aNoExcCTec, {cCodTec, cCodTFF})
				EndIf
	
				(cTmpAgenda)->(DbCloseArea())
				RestArea(aOldAlias2)
			Endif
		Next nInd1
	
		BEGIN TRANSACTION

				DbSelectArea("TFF")
				// Le os itens da rota TW1
				cCodTFF := ""
	
				For nInd1 := 1 to oMdlTW1:Length()
	
					oMdlTW1:GoLine(nInd1)
					
					If cCodTFF <> oMdlTW1:GetValue("TW1_CODTFF")

						If nTpRota == 1
							cCodTFF	:= oMdlTW1:GetValue("TW1_CODTFF")
							cCodTGX	:= oMdlTW1:GetValue("TW1_CODTGX")
							nGrupo	:= oMdlTW1:GetValue("TW1_GRUPO")	
	
							// Posiciona na TFF através da TW1 (TW1_CODTFF)
							DbSelectArea("TFF")
							TFF->(DbSetOrder(1)) //TFF_FILIAL+TFF_COD
							TFF->(DbSeek(xFilial("TFF")+oMdlTW1:GetValue("TW1_CODTFF")))
							
							oMdlTFF	:= FWLoadModel("TECA580E")	//Cria um objeto de Modelo de dados baseado no ModelDef do fonte informado
							oMdlTFF:SetOperation(MODEL_OPERATION_UPDATE)
							oMdlTFF:Activate()
			
							oMdlTGX	:= oMdlTFF:GetModel("TGXDETAIL")
			
							// Posiciona na linha da TGX
							oMdlTGX:SeekLine({{"TGX_COD",cCodTGX}})
			
							// Verificar regras de gravacao e ou alteracao
							// modelo Grid TGZ
							oMdlTGZ	:= oMdlTFF:GetModel("TGZDETAIL")
			
							lFoundTGZ	:= .F.
							lDelLine	:= .F.
							nDelLine	:= 0
							If	!( oMdlTGZ:IsEmpty() ) .AND. !( Empty(cCodTec) )
								lFoundTGZ := oMdlTGZ:SeekLine({ {"TGZ_ATEND",  cCodTec},;
								                                {"TGZ_GRUPO",  nGrupo},;
								                                {"TGZ_CODTW0", cRota} })
								If	lFoundTGZ	// Se encontrou o atendente atual sem data final de agendamento no Gestão de Escalas,
												// então verificará se deve ser atualizada a sua data final de alocação 
									If	aScan(aNoExcCTec, {|x| x[01] == cCodTec .AND. x[02] == cCodTFF}) > 0
										// Se o atendente possuir agenda com manutenção ou atendida, então o registro de cobertura
										// do atendente no Gestão de Escalas não será deletado, e sim finalizado.
										oMdlTGZ:SetValue("TGZ_DTFIM", DaySub(dData, 1))
									Else
										lDelLine	:= .T.
										nDelLine	:= oMdlTGZ:GetLine()
									EndIf
								EndIf
							EndIf
						ElseIf nTpRota == 2

							aAloc := TxEscCalen(cCodTec,dData,dData)

							If !Empty(aAloc)
								cCodTFF := aAloc[1][11]
							Endif

						Endif
	
						If	cTpOper == "MV"	// Movimentar
							If nTpRota == 1
								At580VdFolder({2}) // Seta cFolder para 2-Cobertura, corrigindo assim um error log ao validar o atendente.
			
								If	( oMdlTGZ:IsEmpty() ) .OR. !( lFoundTGZ )
									cItem		:= "00"
									For nInd2 := 1 to oMdlTGZ:Length()
										oMdlTGZ:GoLine(nInd2)
										cItem	:= If(!Empty(oMdlTGZ:GetValue("TGZ_ITEM")), oMdlTGZ:GetValue("TGZ_ITEM"), cItem)
									Next nInd2
									If	!( oMdlTGZ:IsEmpty() )
										oMdlTGZ:AddLine()
									EndIf
			
									lRet := lRet .And. oMdlTGZ:SetValue("TGZ_ITEM",   Soma1(cItem))
									lRet := lRet .And. oMdlTGZ:SetValue("TGZ_ATEND",  cAtdMvRmv)
									lRet := lRet .And. oMdlTGZ:SetValue("TGZ_CODTW0", cRota)
									lRet := lRet .And. oMdlTGZ:SetValue("TGZ_DTINI",  dData)
									lRet := lRet .And. oMdlTGZ:SetValue("TGZ_GRUPO",  nGrupo)
									lRet := lRet .And. oMdlTGZ:SetValue("TGZ_CODTDX", cCodTGX)
									lRet := lRet .And. oMdlTGZ:SetValue("TGZ_ESCALA", oMdlTW1:GetValue("TW1_CODTDW"))
								EndIf
							Endif
						Else
				
							For nInd2 := 1 to Len(aAgCodTec)
		
								ABB->(DbGoTo(aAgCodTec[nInd2]))
		
								nTotHrsTrb	:= SubtHoras(ABB->ABB_DTINI, ABB->ABB_HRINI, ABB->ABB_DTFIM, ABB->ABB_HRFIM)
								aCalAtd	:= { {	ABB->ABB_DTINI,;
													ABB->ABB_DTINI,;
													ABB->ABB_HRINI,;
													ABB->ABB_DTFIM,;
													ABB->ABB_HRFIM,;
													TxRtDiaSem(ABB->ABB_DTINI),;
													nTotHrsTrb,;
													Posicione("TFF", 1, xFilial("TFF")+cCodTFF, "TFF_SEQTRN") } }
		
								aAgenda	:= {aCalAtd, nTotHrsTrb, 1}
		
								aAdd(aDesalocar, {cCodTec,;
								                  "",;
								                  Posicione("AA1", 1, xFilial("AA1")+cAtuAtend, "AA1_CDFUNC"),;
								                  oMdlTGZ:GetValue("TGZ_TURNO"),;
								                  Posicione("TFF", 1, xFilial("TFF")+cCodTFF, "TFF_FUNCAO"),;
								                  Posicione("TFF", 1, xFilial("TFF")+cCodTFF, "TFF_CARGO"),;
								                  aAgenda[1],;
								                  aAgenda[2],;
								                  aAgenda[3]})
		
							Next nInd2
		
							If !Empty(aDesalocar)
								//funcao At330GvDes - desalocar o atendente
								If !lAutomato//Tratativa para execução do robô
									MsgRun(STR0030,STR0031,{|| At330GvDes(aDesalocar)}) // "Removendo Agenda..." ### "Aguarde"
								Else
									At330GvDes(aDesalocar)
								EndIf
							Endif
		
							aDesalocar := {}
							aAgCodTec  := {}
		
						EndIf
						
						If nTpRota == 1
							If	lRet .and. lDelLine
								oMdlTGZ:GoLine(nDelLine)
								If	! ( lRet := oMdlTGZ:DeleteLine() )
									oMdlTFF:DeActivate()
									EXIT
								EndIf
							EndIf
			
							If lRet
								If ( lRet := ( oMdlTFF:VldData() .And. oMdlTFF:CommitData() ) )
									oMdlTFF:DeActivate()
								Else
									aErro	:= oMdlTFF:GetErrorMessage()
									Help( , , "At581Efet", , aErro[MODEL_MSGERR_MESSAGE], 1, 0 )
									EXIT
								EndIf
							Else
								Exit
							EndIf
						Endif

					Endif
				Next nInd1

			If	lRet
				// Atualiza a agenda com o novo atendente na ABB
				If	cTpOper == "MV" // Movimentar
					For nInd2 := 1 to Len(aAgCodTec)
						ABB->(DbGoTo(aAgCodTec[nInd2]))
						ABB->(Reclock("ABB",.F.))
						ABB->ABB_CODTEC := cAtdMvRmv
						ABB->(MsUnlock())
					Next nInd2
				EndIf

				// Atualiza o atendente da TW0
				oMdlTW0:SetValue("TW0_ATEND", If( cTpOper == "MV", cAtdMvRmv, "" ))
				
				If !Empty(cCobert) .And. cTpOper == "MV"
					oMdlTW0:SetValue("TW0_COBRT", "1" )
				ElseIf cTpOper == "RE"
					oMdlTW0:SetValue("TW0_COBRT", "2" )
				Endif

				If ( lRet := ( oModel:VldData() .And. oModel:CommitData() ) )
					oModel:DeActivate()
				Else
					aErro	:= oModel:GetErrorMessage()
					Help( , , "At581Efet", , aErro[MODEL_MSGERR_MESSAGE], 1, 0 )
					DisarmTransaction()
					Break
				EndIf
			Else
				DisarmTransaction()
				Break
			EndIf

		END TRANSACTION

		If	lRet
			If !lAutomato
				MsgInfo(STR0026) //"Rota de cobertura atualizada com sucesso!"
			EndIf
		Else
			Help( , , "At581Efet", , STR0027, 1, 0,,,,,,{STR0036})	// "Durante a execução deste procedimento foram encontradas situações que impedem a sua efetivação." ## "Corrija as inconsistências para efetivar o processamento desejado."	
		EndIf
	Else
		If	!Empty(cLogTGX) .And. !lAutomato
			cMsgShwLog		+= STR0020 + ":" + CRLF + cLogTGX + CRLF + CRLF	// "Não existe item relacionado na configuração da escala de cobertura"
		EndIf
		
		If	!Empty(cLogABB) .And. !lAutomato
			cMsgShwLog		+= STR0019 + CRLF + cLogABB + CRLF + CRLF // "Foi encontrada uma ou mais agendas atendidas ou com manutenção realizada numa data posterior a este processamento da rota de cobertura:"
		EndIf
		
		If !lAutomato
			cMsgShwLog	:=	If(!(Empty(cMsgShwLog)), STR0034 + CRLF + CRLF + cMsgShwLog, "")	// "Inconsistências"
		EndIf
		
		If	!Empty(cMsgShwLog) .And. !lAutomato
			AtShowLog(cMsgShwLog /*<cMemoLog>*/, STR0001 /*<cTitle>*/, /*<lVScroll>*/, /*<lHScroll>*/, .T. /*<lWrdWrap>*/)	//"Rota de Cobertura"
			Help( , , "At581Efet", , STR0035, 1, 0,,,,,,{STR0036})	//	"Não é permitido movimentar ou remover uma rota de cobertura que possua inconsistências." ## "Corrija as inconsistências para efetivar o processamento desejado."
		EndIf
	EndIf
EndIf

RestArea(aOldAlias)

Return	lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At581GAgMA
@description	Verifica se existe agenda posterior com manutenção ou atendida para o atendente...
@sample			At581GAgMA(cCodTFF, cCodTec, dData)
@param			cExp1 - Código RH
@param			cExp2 - Código do Atendente
@param			dExp3 - Data de efetivação do atendente na Rota de Cobertura
@return			lExp1 - .T.=Atendente não possui agenda posterior com manutenção ou atendida // .F.=Atendente possui agenda posterior com manutenção ou atendida
@author			Serviços
@since			13/06/2016
@version		P12
/*/
//------------------------------------------------------------------------------
Static Function At581GAgMA(cCodTFF, cCodTec, dData)
Local	aOldAlias	:= (Alias())->(GetArea())
Local	cTmpAgenda	:= ""
Local	lRet		:= .T.

//Verifica se existe agenda posterior atendida ou com manutenção para o atendente...
cTmpAgenda	:= GetNextAlias()
BeginSql Alias cTmpAgenda
	SELECT count(*) as REGABB
	  FROM %table:ABB% ABB
	       LEFT JOIN %table:ABQ% ABQ on %xFilial:ABQ% = ABQ.ABQ_FILIAL
	                                AND ABQ.%NotDel%
	                                AND %xFilial:ABB% = ABQ.ABQ_FILTFF
	                                AND ABB.ABB_IDCFAL = ABQ.ABQ_CONTRT || ABQ.ABQ_ITEM || ABQ.ABQ_ORIGEM
	       LEFT JOIN %table:TFF% TFF on TFF.TFF_FILIAL = %xFilial:TFF%
	                                AND TFF.%NotDel%
	                                AND TFF.TFF_COD = %Exp:cCodTFF%
	                                AND TFF.TFF_COD = ABQ.ABQ_CODTFF
	 WHERE ABB.ABB_FILIAL = %xFilial:ABB%
	   AND ABB.%NotDel%
	   AND ( ABB.ABB_MANUT = '1' OR ABB.ABB_ATENDE = '1' )
	   AND ABB.ABB_CODTEC = %Exp:cCodTec%
	   AND ABB.ABB_DTINI >= %Exp:dData%
	   AND ABB.ABB_ATIVO  = '1'
EndSql

lRet	:= ( (cTmpAgenda)->REGABB == 0 )	//Foi encontrada uma ou mais agendas posterior(es) atendida(s) ou com manutenção para o atendente

(cTmpAgenda)->(DbCloseArea())
RestArea(aOldAlias)

Return	lRet

//------------------------------------------------------------------------
/*/{Protheus.doc} At581F3TFF
@description	Montagem da consulta específica para o campo TW1_CODTFF (Código RH)

@sample			At581F3TFF()
@return			lExp1: .T.=Registro selecionado na consulta específica // .F.=Registro não selecionado na consulta específica. 
@author			Serviços
@since			03/08/2015 
/*/
//---------------------------
Function At581F3TFF()
Local oModel			:= FWModelActive()
Local oMdlTW0			:= oModel:GetModel("TW0MASTER")
Local cTipoCob 			:= oMdlTW0:Getvalue("TW0_TIPO")
Local lRet              := .T.
Local cTit				:= ""
Local cQry				:= ""
Local aHeader			:= {}
Local aSeek				:= {}
Local aIndex			:= {}
Local cCmpRet			:= ""
Local cFuncao			:= "At581GrvF3"

cTit := "Postos"

cQry := At581Qry(cTipoCob)

Aadd( aHeader, 	{"TFF_FILIAL"})
Aadd( aHeader, 	{"TFF_COD"	 })
Aadd( aHeader, 	{"TFF_LOCAL" })
Aadd( aHeader, 	{"ABS_DESCRI"})
Aadd( aHeader, 	{"TGY_ATEND" })
Aadd( aHeader, 	{"AA1_NOMTEC"})
Aadd( aHeader, 	{"TFF_PRODUT"})
Aadd( aHeader, 	{"B1_DESC"	 })
Aadd( aHeader, 	{"TFF_ESCALA"})
Aadd( aHeader, 	{"TDW_DESC"	 })
Aadd( aHeader, 	{"TGY_GRUPO" })
Aadd( aHeader, 	{"TDX_COD"	 })
Aadd( aHeader, 	{"TDX_TURNO" })
Aadd( aHeader, 	{"TDX_SEQTUR"})
Aadd( aHeader, 	{"TFF_CONTRT"})

Aadd( aSeek, 	"TFF_COD")
Aadd( aSeek, 	"AA1_NOMTEC")
Aadd( aSeek, 	"ABS_DESCRI")
Aadd( aSeek, 	"TFF_CONTRT")
				
Aadd( aIndex, "TFF_COD" )
Aadd( aIndex, "AA1_NOMTEC")
Aadd( aIndex, "ABS_DESCRI")
Aadd( aIndex, "TFF_CONTRT")
Aadd( aIndex, "TFF_FILIAL")

cCmpRet := "TFF_COD"

lRet := TxF3Gen(cTit, cQry, aHeader, aSeek, aIndex, cCmpRet, cFuncao)

Return(lRet)

//---------------------------------------------
/*/{Protheus.doc} At581GF3TFF 
@description	Retornar o código do item selecionado no browser. 
@sample			At581GF3TFF()
@return			cExp1: Retornará o 'Código RH' selecionado na consulta padrão. 
@author			Serviços
@since			25/06/2015 
@version		P12
/*/
//---------------------------------------------
Function At581GF3TFF()

lLimpTW1 := .F.

Return TxRetF3()

//-------------------------------------------------------------------
/*/{Protheus.doc} At581VldTp()
@description	Valida a consistencia do tipo da rota de cobertura.

@author Kaique Schiller
@since 22/05/2018
@return cRet
/*/
//------------------------------------------------------------------
Function At581VldTp(oMdl, cCmp, xVlr , xVlrAnt)
Local oModel	:= FWModelActive()
Local oMdlTW0	:= oModel:GetModel("TW0MASTER")
Local oMdlTW1	:= oModel:GetModel("TW1DETAIL")
Local lRet 		:= .T. 
Local cTipoCob	:= oMdlTW0:GetValue("TW0_TIPO")

If nTipoRt == 1 .And. cTipoCob == "4"
 	lRet := .F.
	Help( , , "At581VldTp", , STR0068 , 1, 0,,,,,,{STR0069}) //"Não é possível alterar o tipo da rota de cobertura."##"Realize a alteração pra Almocista, Jantista ou Folguista."
Elseif nTipoRt == 2 .And. cTipoCob $ "1|2|3"
	lRet := .F.
	Help( , , "At581VldTp", , STR0068, 1, 0,,,,,,{STR0070}) //"Não é possível alterar o tipo da rota de cobertura."##"Realize a alteração pra Ferista."
Endif

If lRet .ANd. xVlr <> xVlrAnt .And. !(oMdlTW1:IsEmpty()) .And. !MsgYesNo(STR0045)	//"Deseja realmente mudar o tipo da rota de cobertura? Os itens da rota de cobertura serão excluidos."
	oMdlTW0:LoadValue("TW0_TIPO",xVlrAnt)
	lRet := .F.
Endif

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At581GatTp()
@description	Garante a consistência do tipo da rota de cobertura, 
				se for alterado o tipo sera deletado todos os itens inseridos na inclusão.

@author Kaique Schiller
@since 22/05/2018
@return cTipoCob
/*/
//------------------------------------------------------------------
Function At581GatTp()
Local oModel	:= FWModelActive()
Local oMdlTW0	:= oModel:GetModel("TW0MASTER")
Local oMdlTW1	:= oModel:GetModel("TW1DETAIL")
Local cTipoCob 	:= oMdlTW0:Getvalue("TW0_TIPO")
Local nX		:= 0
Local lClear	:= .F.

For nX := 1 To oMdlTW1:Length()
	oMdlTW1:Goline(nX)
	oMdlTW1:DeleteLine()
	lClear	:= .T.
Next nX

If lClear
	oMdlTW1:ClearData()
Endif

Return cTipoCob

//------------------------------------------------------------------
/*/{Protheus.doc} At581GrvF3()
@description	Realiza a gravação das informações no grid do campo TW1_CODTFF (Código RH) consulta específica.

@author Kaique Schiller
@since 22/05/2018
@return lRet
/*/
//------------------------------------------------------------------
Function At581GrvF3(oBrw)
Local oView		:= FwViewActive()
Local oModel	:= FWModelActive()
Local oMdlTW1	:= oModel:GetModel("TW1DETAIL")
Local lRet		:= .T.
Local aErro		:= {}
Default oBrw	:= Nil

If nTipoRt == 1 
	lRet := lRet .And. oMdlTW1:LoadValue("TW1_STATUS"	,"BR_AMARELO" )
Elseif nTipoRt == 2
	DbselectArea("AA1")
	AA1->(DbSetOrder(1))
	If AA1->(DbSeek(FwxFilial("AA1")+(oBrw:Alias())->&("TGY_ATEND"	)))

		aChkFe := At570ChkFe(AA1->AA1_FILIAL, AA1->AA1_CDFUNC, dDataBase, dDataBase+730)
		
		lProgFer := aChkFe[1] .Or. aChkFe[2] .Or. aChkFe[3] 
		
		lFerias	 := aChkFe[4]
		
		If lProgFer .Or. lFerias
		
			If lFerias .And. dDataBase >= aChkFe[5] .And. dDataBase <= aChkFe[6]
				oMdlTW1:LoadValue("TW1_STATUS"	,"BR_AMARELO")
			Elseif lProgFer
				oMdlTW1:LoadValue("TW1_STATUS"	,"BR_VERDE")
			Endif
		Endif
	Endif
Endif

lRet := lRet .And. oMdlTW1:LoadValue("TW1_CODTDX"	,(oBrw:Alias())->&("TDX_COD"	))
lRet := lRet .And. oMdlTW1:LoadValue("TW1_CODTGX"	,(oBrw:Alias())->&("TGX_COD"	))
lRet := lRet .And. oMdlTW1:LoadValue("TW1_ATEND" 	,(oBrw:Alias())->&("TGY_ATEND"	))
lRet := lRet .And. oMdlTW1:LoadValue("TW1_NOMTEC"	,(oBrw:Alias())->&("AA1_NOMTEC"	))
lRet := lRet .And. oMdlTW1:LoadValue("TW1_GRUPO"	,(oBrw:Alias())->&("TGY_GRUPO"	))
lRet := lRet .And. oMdlTW1:LoadValue("TW1_TURTDX"	,(oBrw:Alias())->&("TDX_TURNO"	))
lRet := lRet .And. oMdlTW1:LoadValue("TW1_SEQTDX"	,(oBrw:Alias())->&("TDX_SEQTUR"	))

If !lRet
	aErro	:= oMdlTW1:GetErrorMessage()
	Help( , , "At581GrvF3", , aErro[MODEL_MSGERR_MESSAGE], 1, 0 )
Endif

oView:Refresh()

Return lRet

//------------------------------------------------------------------
/*/{Protheus.doc} At581When()
@description	  Liberação de preenchimento de campos.

@author Kaique Schiller
@since 22/05/2018
@return lRet
/*/
//------------------------------------------------------------------
Function At581When(cCmp)
Local lRet 		:= .F.
Local oModel	:= FWModelActive()
Local oMdlTW0	:= oModel:GetModel("TW0MASTER")
Local cTipoCob	:= oMdlTW0:GetValue("TW0_TIPO")
Local cCodAtend	:= oMdlTW0:GetValue("TW0_ATEND")
Default cCmp	:= ""

If cCmp == "TW0_TIPO"
	lRet := Empty(cCodAtend) .And. oModel:GetOperation() <> MODEL_OPERATION_UPDATE
Endif

Return lRet

//------------------------------------------------------------------
/*/{Protheus.doc} At581Vld()
@description	  Validação dos campos da tabela TW1 para garantir a integridade rota de cobertura.

@author Kaique Schiller
@since 22/05/2018
@return lRet
/*/
//------------------------------------------------------------------
Function At581Vld(oMdl, cCmp, xVlr , xVlrAnt, cTipoCob)
Local lRet 		:= .T.
Local cAliasQry	:= GetNextAlias()
Local cQry		:= ""
Local aChkFe	:= {}
Local cCodFunc	:= ""
Local lProgFer	:= .F.
Local lFerias	:= .F.

If cTipoCob $ "1|2|3"

	cQry := At581Qry(cTipoCob)

	If cCmp == "TW1_CODTFF"
	
		cQry += " AND TFF.TFF_COD = '" + xVlr + "'"
		cQry := ChangeQuery( cQry )
		
		If Select(cAliasQry) > 0
			(cAliasQry)->(dbClosearea())
		Endif
		
		dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQry ), cAliasQry, .F., .T. )
	
		If (cAliasQry)->(Eof())
			Help( , , "At581Vld", , STR0047, 1, 0,,,,,,{STR0048}) //"Código do RH incorreto."# "Verifique se existe o código relacionado no orçamento ou se a escala permite o tipo cobertura."
			lRet := .F.
		Endif
	
		If lRet
			oMdl:LoadValue("TW1_STATUS","BR_VERDE")
		Endif
	
		If lLimpTW1 .And. lRet
			oMdl:LoadValue("TW1_CODTDX"	,"")
			oMdl:LoadValue("TW1_CODTGX"	,"")
			oMdl:LoadValue("TW1_ATEND"	,"")
			oMdl:LoadValue("TW1_NOMTEC"	,"")
			oMdl:LoadValue("TW1_GRUPO"	,0)	
		Else
			lLimpTW1 := .T.
		Endif
	
		(cAliasQry)->(dbClosearea())
	
	Endif
	
	If cCmp == "TW1_CODTDX"
	
		cQry += " AND TFF.TFF_COD = '" + oMdl:GetValue("TW1_CODTFF") + "'"
		cQry += " AND TDX.TDX_COD = '" + xVlr + "'"
		cQry := ChangeQuery( cQry )
		
		If Select(cAliasQry) > 0
			(cAliasQry)->(dbClosearea())
		Endif
		
		dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQry ), cAliasQry, .F., .T. )
	
		If (cAliasQry)->(Eof())
			Help( , , "At581Vld", , STR0049, 1, 0,,,,,,{STR0050}) //"Codigo de configuração do efetivo incorreto."#"Verifique se existe o código relacionado no cadastro de escalas ou se existe efetivos implantados nessa configuração."
			lRet := .F.
		Endif	
	
		If lLimpTW1 .And. lRet
			oMdl:LoadValue("TW1_CODTGX"	,"")
			oMdl:LoadValue("TW1_ATEND"	,"")
			oMdl:LoadValue("TW1_NOMTEC"	,"")
			oMdl:LoadValue("TW1_GRUPO"	,0)	
		Else
			lLimpTW1 := .T.
		Endif
	
		(cAliasQry)->(dbClosearea())
	
	Endif
	
	If cCmp == "TW1_CODTGX"
	
		cQry += " AND TFF.TFF_COD = '" + oMdl:GetValue("TW1_CODTFF") + "'"
		cQry += " AND TDX.TDX_COD = '" + oMdl:GetValue("TW1_CODTDX") + "'"
		cQry += " AND TGX.TGX_COD = '" + xVlr + "'"
		cQry := ChangeQuery( cQry )
		
		If Select(cAliasQry) > 0
			(cAliasQry)->(dbClosearea())
		Endif
		
		dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQry ), cAliasQry, .F., .T. )
	
		If (cAliasQry)->(Eof())
			Help( , , "At581Vld", , STR0051, 1, 0,,,,,,{STR0052}) //"Codigo de configuração da cobertura incorreto."#"Verifique se existe o código relacionado no cadastro de escalas."
			lRet := .F.
		Endif	
	
		If lLimpTW1 .And. lRet
			oMdl:LoadValue("TW1_ATEND"	,"")
			oMdl:LoadValue("TW1_NOMTEC"	,"")
			oMdl:LoadValue("TW1_GRUPO"	,0)	
		Else
			lLimpTW1 := .T.
		Endif
	
		(cAliasQry)->(dbClosearea())
	
	Endif 
	
	If cCmp == "TW1_ATEND"
		If !Empty(xVlr)
			cQry += " AND TFF.TFF_COD 	= '" + oMdl:GetValue("TW1_CODTFF") + "'"
			cQry += " AND TDX.TDX_COD 	= '" + oMdl:GetValue("TW1_CODTDX") + "'"
			cQry += " AND TGX.TGX_COD 	= '" + oMdl:GetValue("TW1_CODTGX") + "'"
			cQry += " AND TGY.TGY_ATEND 	= '" + xVlr + "'"
			cQry := ChangeQuery( cQry )
			
			If Select(cAliasQry) > 0
				(cAliasQry)->(dbClosearea())
			Endif
			
			dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQry ), cAliasQry, .F., .T. )
			
			If (cAliasQry)->(Eof())
				Help( , , "At581Vld", , STR0053, 1, 0,,,,,,{STR0054}) //"Codigo do atendente efetivo incorreto."# "Verifique se o atendente está implantado nesse posto."
				lRet := .F.
			Else
				If cCmp == "TW1_ATEND"
					oMdl:LoadValue("TW1_NOMTEC"	,(cAliasQry)->AA1_NOMTEC )
					oMdl:LoadValue("TW1_GRUPO"	,(cAliasQry)->TGY_GRUPO )
					lLimpTW1 := .F.
				Endif
			Endif
		
			If lLimpTW1
				If lRet
					oMdl:LoadValue("TW1_NOMTEC"	,"")
					oMdl:LoadValue("TW1_GRUPO"	,0)
				Endif
			Else
				lLimpTW1 := .T.
			Endif
			
			(cAliasQry)->(dbClosearea())
		Else
			oMdl:LoadValue("TW1_NOMTEC"	,"")
			oMdl:LoadValue("TW1_GRUPO"	,0)
		Endif
	Endif

Elseif cTipoCob == "4"
	If cCmp == "TW1_ATEND"
		DbselectArea("AA1")
		AA1->(DbSetOrder(1))
		If AA1->(DbSeek(FwxFilial("AA1")+xVlr))

			aChkFe := At570ChkFe(AA1->AA1_FILIAL, AA1->AA1_CDFUNC, dDataBase, dDataBase+730)
			
			lProgFer := aChkFe[1] .Or. aChkFe[2] .Or. aChkFe[3] 
			
			lFerias	 := aChkFe[4]
			
			If lProgFer .Or. lFerias
			
				If lFerias .And. dDataBase >= aChkFe[5] .And. dDataBase <= aChkFe[6]
					oMdl:LoadValue("TW1_STATUS"	,"BR_AMARELO")
				Elseif lProgFer
					oMdl:LoadValue("TW1_STATUS"	,"BR_VERDE")
				Endif
				
				oMdl:LoadValue("TW1_NOMTEC"	,AA1->AA1_NOMTEC)
				oMdl:LoadValue("TW1_FERINI"	,aChkFe[5])
				oMdl:LoadValue("TW1_FERFIN"	,aChkFe[6])
				oMdl:LoadValue("TW1_COBINI"	,sTod(""))
				oMdl:LoadValue("TW1_COBFIN"	,sTod(""))
			Else
				Help( , , "At581Vld", , STR0071, 1, 0,,,,,,{STR0072}) //"Não é possível incluir um atendente que não está de férias ou com as férias programadas."##"Utilize um atendente que está de férias ou com as férias programadas."
				lRet := .F.
			Endif
		Else
			Help( , , "At581Vld", , STR0073, 1, 0,,,,,,{STR0074}) //"Não é possível incluir um atendente que não está cadastrado no RH."##"Utilize um atendente que está cadastrado no RH."
			lRet := .F.
		Endif
	Elseif cCmp == "TW1_COBINI"
		If xVlr < oMdl:GetValue("TW1_FERINI") .Or. xVlr > oMdl:GetValue("TW1_FERFIN")
			Help( , , "At581Vld", , STR0075, 1, 0,,,,,,{STR0076}) //"Não é possivel incluir uma data que esta fora do período de ferias."##"Utilize uma data que esta dentro do período de ferias."  
			lRet := .F.
		Elseif !Empty(oMdl:GetValue("TW1_COBFIN")) .And. xVlr > oMdl:GetValue("TW1_COBFIN")
			Help( , , "At581Vld", , STR0077, 1, 0,,,,,,{STR0078}) //"Não é possivel incluir uma data que é maior que a data final da cobertura."##"Utilize uma data que é menor que a data final da cobertura."
			lRet := .F.
		Endif
	Elseif cCmp == "TW1_COBFIN"
		If xVlr < oMdl:GetValue("TW1_FERINI") .Or. xVlr > oMdl:GetValue("TW1_FERFIN")
			Help( , , "At581Vld", , STR0079, 1, 0,,,,,,{STR0080}) //"Não é possivel incluir uma data que esta fora do período de ferias."##"Utilize uma data que esta dentro do período de ferias."
			lRet := .F.
		Elseif !Empty(oMdl:GetValue("TW1_COBINI")) .And. xVlr < oMdl:GetValue("TW1_COBINI")
			Help( , , "At581Vld", , STR0081, 1, 0,,,,,,{STR0082}) //"Não é possivel incluir uma data que é menor que a data inicial da cobertura."##"Utilize uma data que é maior que a data inicial da cobertura."
			lRet := .F.
		Endif
	Endif
Endif

Return lRet

//------------------------------------------------------------------
/*/{Protheus.doc} At581Qry()
@description	 Construção da Query de efetivos pelo tipo de cobertura.

@author Kaique Schiller
@since 22/05/2018
@return cQryRet
/*/
//------------------------------------------------------------------
Static Function At581Qry(cTipoCob)
Local cQryRet	:= ""
Local cOrcRes	:= Alltrim(SuperGetMV("MV_GSORCRE"))

cQryRet := " SELECT TFF.TFF_FILIAL,"
cQryRet += "       	TFF.TFF_COD,"
cQryRet += "       	TGY.TGY_ATEND,"
cQryRet += "       	TGY.TGY_TURNO,"
cQryRet += "       	TGY.TGY_SEQ,"
cQryRet += "       	AA1.AA1_NOMTEC,"
cQryRet += "       	TFF.TFF_LOCAL,"
cQryRet += "       	ABS.ABS_DESCRI,"
cQryRet += "       	TFF.TFF_PRODUT,"
cQryRet += "       	SB1.B1_DESC,"
cQryRet += "       	TFF.TFF_ESCALA,"
cQryRet += "       	TDW.TDW_DESC,"
cQryRet += "       	TGY.TGY_GRUPO,"
cQryRet += "       	TDX.TDX_COD,"
cQryRet += "       	TDX.TDX_TURNO,"
cQryRet += "       	TDX.TDX_SEQTUR,"
cQryRet += "       	TFF.TFF_CONTRT,"
cQryRet += "       	TGX.TGX_COD,"
cQryRet += "       	TGY.TGY_DTFIM"

cQryRet += " FROM " + RetSqlName("TFF") + " TFF "
cQryRet += " 	INNER JOIN " + RetSqlName("TFL") + " TFL "
cQryRet += " 		ON TFL.TFL_FILIAL = '" +  xFilial("TFL") + "'"
cQryRet += " 		AND TFL.D_E_L_E_T_ = '' "
cQryRet += " 		AND TFL.TFL_CODIGO = TFF.TFF_CODPAI"

cQryRet += " 	INNER JOIN " + RetSqlName("TFJ") + " TFJ "
cQryRet += " 		ON TFJ.TFJ_FILIAL = '" +  xFilial("TFJ") + "'"
cQryRet += " 		AND TFJ.D_E_L_E_T_ = '' "
cQryRet += " 		AND TFJ.TFJ_CODIGO = TFL.TFL_CODPAI"

cQryRet += " 	INNER JOIN " + RetSqlName("TDX") + " TDX "
cQryRet += " 		ON TDX.TDX_FILIAL = '" +  xFilial("TDX") + "'"
cQryRet += " 		AND TDX.D_E_L_E_T_ = '' "
cQryRet += "		AND TDX.TDX_CODTDW = TFF.TFF_ESCALA"

cQryRet += " 	INNER JOIN " + RetSqlName("TDW") + " TDW "
cQryRet += " 		ON TDW.TDW_FILIAL = '" +  xFilial("TDW") + "'"
cQryRet += " 		AND TDW.D_E_L_E_T_ = '' "
cQryRet += " 		AND TDW.TDW_COD = TFF.TFF_ESCALA"

cQryRet += " 	INNER JOIN " + RetSqlName("TGX") + " TGX "
cQryRet += " 		ON TGX.TGX_FILIAL = '" +  xFilial("TGX") + "'"
cQryRet += " 		AND TGX.D_E_L_E_T_ = '' "
cQryRet += " 		AND TGX.TGX_CODTDW = TDW.TDW_COD"

cQryRet += " 	INNER JOIN " + RetSqlName("TGY") + " TGY " 
cQryRet += " 		ON TGY.TGY_FILIAL = '" +  xFilial("TGY") + "'"
cQryRet += " 		AND TGY.D_E_L_E_T_ = '' "
cQryRet += " 		AND TGY.TGY_ESCALA = TFF.TFF_ESCALA"
cQryRet += " 		AND TGY.TGY_CODTDX = TDX.TDX_COD"
cQryRet += " 		AND TGY.TGY_CODTFF = TFF.TFF_COD"

cQryRet += " 	INNER JOIN " + RetSqlName("SB1") + " SB1 "
cQryRet += " 		ON SB1.B1_FILIAL = '" +  xFilial("SB1") + "'"
cQryRet += " 		AND SB1.D_E_L_E_T_ = '' "
cQryRet += " 		AND SB1.B1_COD = TFF.TFF_PRODUT"

cQryRet += " 	INNER JOIN " + RetSqlName("ABS") + " ABS "
cQryRet += " 		ON ABS.ABS_FILIAL = '" +  xFilial("ABS") + "'"
cQryRet += " 		AND ABS.D_E_L_E_T_ = '' "
cQryRet += " 		AND ABS.ABS_LOCAL 	= TFF.TFF_LOCAL"

cQryRet += " 	INNER JOIN " + RetSqlName("AA1") + " AA1 "
cQryRet += " 		ON AA1.AA1_FILIAL = '" +  xFilial("AA1") + "'"
cQryRet += " 		AND AA1.D_E_L_E_T_ = '' "
cQryRet += " 		AND AA1.AA1_CODTEC = TGY.TGY_ATEND"

cQryRet += " 	LEFT JOIN " + RetSqlName("SX5") + " SX5 "
cQryRet += " 		ON SX5.X5_FILIAL = '" +  xFilial("SX5") + "'"
cQryRet += " 		AND SX5.D_E_L_E_T_ = '' "
cQryRet += " 		AND SX5.X5_TABELA 	= 'A2'"
cQryRet += " 		AND SX5.X5_CHAVE 	= ABS.ABS_REGIAO"

cQryRet += " WHERE TFF_FILIAL = '" +  xFilial('TFF') + "'"
cQryRet += " 		AND TFF.D_E_L_E_T_ = '' "
cQryRet += " 		AND TFF.TFF_PERFIM > '" +  dTos(dDatabase) + "'"
cQryRet += " 		AND TGY.TGY_DTFIM  > '" +  dTos(dDatabase) + "'"
cQryRet += " 		AND TFF.TFF_ENCE <> '1'"
cQryRet += " 		AND TFF.TFF_CODSUB = ' '"
cQryRet += " 		AND TFJ_STATUS = '1' "
cQryRet += " 		AND TDX_STATUS = '1' "
cQryRet += " 		AND TGX.TGX_TIPO = '" + cTipoCob + "'"
cQryRet += " 		AND ( ( TFJ_SRVEXT = '1' ) OR ( TFJ_SRVEXT = '2' AND TFJ_CONTRT <> ' ' ) ) "
cQryRet += " 		AND TFJ_CODIGO <> '" + cOrcRes + "'"
cQryRet += "		AND NOT EXISTS ( SELECT 1 FROM " + RetSqlName( "TW1" ) + " TW1 WHERE "
cQryRet += "							TW1.TW1_FILIAL = '" +  xFilial("TW1") + "'"
cQryRet += "							AND TW1.TW1_CODTFF = TFF.TFF_COD "
cQryRet += "							AND TW1.TW1_CODTGX = TGX.TGX_COD "
cQryRet += "							AND TW1.TW1_GRUPO  = TGY.TGY_GRUPO "
cQryRet += "							AND TW1.TW1_CODTDX = TDX.TDX_COD "
cQryRet += "							AND TW1.D_E_L_E_T_= '')"

/*
NO EXISTS (		SELECT 1
				FROM %Table:TW1% TW1
				WHERE TW1.TW1_FILIAL   = %xFilial:TW1%
					AND TW1.TW1_CODTFF = TFF.TFF_COD
					AND TW1.TW1_CODTGX = TGX.TGX_COD
					AND TW1.TW1_GRUPO  = TGY.TGY_GRUPO
					AND TW1.TW1_CODTDX = TDX.TDX_COD
				)

		cQuery += "EXISTS ( SELECT A1_REGIAO FROM " + RetSqlName( "SA1" ) + " SA1 WHERE "
		cQuery += "SA1.A1_COD=SD2.D2_CLIENTE AND SA1.A1_LOJA=SD2.D2_LOJA AND "
		cQuery += "SA1.A1_REGIAO='" + cRegiao + "' AND "
		cQuery += "SA1.D_E_L_E_T_<>'*') AND "
*/				

Return cQryRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At581F3TGY()
@description	Montagem da consulta específica para o campo TW1_ATEND (Atendente)

@author Kaique Schiller
@since 22/05/2018
@return lRet
/*/
//------------------------------------------------------------------
Function At581F3TGY()
Local oModel			:= FWModelActive()
Local oMdlTW0			:= oModel:GetModel("TW0MASTER")
Local oMdlTW1			:= oModel:GetModel("TW1DETAIL")
Local cTipoCob 			:= oMdlTW0:Getvalue("TW0_TIPO")
Local lRet              := .T.
Local cTit				:= ""
Local cQry				:= ""
Local aHeader			:= {}
Local aSeek				:= {}
Local aIndex			:= {}
Local cCmpRet			:= ""
Local cFuncao			:= "At581GvTGY"

cTit := "Atendentes."

cQry := At581Qry(cTipoCob)

cQry += " AND TFF.TFF_COD 	= '" + oMdlTW1:GetValue("TW1_CODTFF") + "'"
cQry += " AND TDX.TDX_COD 	= '" + oMdlTW1:GetValue("TW1_CODTDX") + "'"
cQry += " AND TGX.TGX_COD 	= '" + oMdlTW1:GetValue("TW1_CODTGX") + "'"

cQry := ChangeQuery( cQry )

Aadd( aHeader, 	{"TGY_ATEND"})
Aadd( aHeader, 	{"AA1_NOMTEC"})
Aadd( aHeader, 	{"TGY_GRUPO"})
Aadd( aHeader, 	{"TDX_TURNO"})
Aadd( aHeader, 	{"TDX_SEQTUR"})

Aadd( aSeek, 	"AA1_NOMTEC")
				
Aadd( aIndex, "AA1_NOMTEC")

cCmpRet := "TGY_ATEND"

lRet := TxF3Gen(cTit, cQry, aHeader, aSeek, aIndex, cCmpRet, cFuncao)

Return(lRet)

//-------------------------------------------------------------------
/*/{Protheus.doc} At581F3TGY()
@description	Retorna o código do atendente selecionado no browser. 

@return		TxRetF3: Retornará o 'Codigo do atendente' selecionado na consulta padrão. 

@author Kaique Schiller
@since 22/05/2018
@return cRet
/*/
//------------------------------------------------------------------
Function At581GF3TGY()

lLimpTW1 := .F.

Return TxRetF3()

//-------------------------------------------------------------------
/*/{Protheus.doc} At581GvTGY()
@description	Realiza a gravação das informações no grid do campo TW1_ATEND (Atendente) consulta específica.

@author Kaique Schiller
@since 22/05/2018
@return cRet
/*/
//------------------------------------------------------------------
Function At581GvTGY(oBrw)
Local lRet		:= .T.
Local oView		:= FwViewActive()
Local oModel	:= FWModelActive()
Local oMdlTW1	:= oModel:GetModel("TW1DETAIL")

lRet := lRet .And. oMdlTW1:LoadValue("TW1_NOMTEC"	,(oBrw:Alias())->&("AA1_NOMTEC"	))
lRet := lRet .And. oMdlTW1:LoadValue("TW1_GRUPO"	,(oBrw:Alias())->&("TGY_GRUPO"	))

oView:Refresh()

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At581LnPos()
@description	Validação de linha para não sobrepor os dias e os horários de atendimento conforme o tipo de cobertura, escala, turno e sequencia.

@author Kaique Schiller
@since 22/05/2018
@return cRet
/*/
//------------------------------------------------------------------
Function At581LnPos(oMdl,nLine)
Local lRet	  		:= .T.
Local nX	  		:= 0
Local nY			:= 0
Local cConfEsc		:= ""
Local cConfCob		:= ""
Local cEscala		:= ""
Local cTurno		:= ""
Local cSeq			:= ""
Local aCobEft		:= {}
Local aCobEftAux	:= {}
Local cDiaSem		:= ""
Local nHrIni		:= 0
Local nHrFim		:= 0
Local oModelo		:= oMdl:GetModel()
Local oMdlTW0		:= oModelo:GetModel("TW0MASTER")
Local cTipoCob		:= oMdlTW0:Getvalue("TW0_TIPO")
Local cCodTFF		:= oMdl:GetValue("TW1_CODTFF")
Local nSldHrFer		:= 0
Local nContQtdHrF 	:= 0

DbSelectArea("TW1")
TW1->(DbSetOrder(1))

DbSelectArea("TFF")
TFF->(DbSetOrder(1))
TFF->(DbSeek(xFilial("TFF")+oMdl:GetValue("TW1_CODTFF")))

nSldHrFer := TFF->TFF_SLDHRR

If cTipoCob $ "2|3"
	If nSldHrFer <> 0
		For nX := 1 To oMdl:Length()
	
			oMdl:GoLine(nX)
			//Verifica se não esta deletado e se é o mesmo codigo de tff e se é um registro novo.
			If !oMdl:IsDeleted() .And. cCodTFF == oMdl:GetValue("TW1_CODTFF") //.And. TFF->(DbSeek(xFilial("TFF")+oMdl:GetValue("TW1_CODTFF")))		
				nContQtdHrF++
			Endif
			
		Next nX
	
		If nContQtdHrF > nSldHrFer
			Help( , , "At581LnPos", , "Atingiu o limite de almoços/jantas a serem cobertos.", 1, 0,,,,,,{""}) //"Configuração de Escala não permite esse tipo de cobertura."#"Realize a configuração no cadastro de escalas."
			lRet := .F.
		Endif
	
	Else
		Help( , , "At581LnPos", , "Atingiu o limite de almoços/jantas a serem cobertos.", 1, 0,,,,,,{""}) //"Configuração de Escala não permite esse tipo de cobertura."#"Realize a configuração no cadastro de escalas."
		lRet := .F.
	Endif
Endif

If lRet .And. cTipoCob $ "1|2|3"

	DbSelectArea("TDX")
	TDX->(DbSetOrder(1))

	For nX := 1 To oMdl:Length()
	
		oMdl:GoLine(nX)
		If !oMdl:IsDeleted()

			cEscala	 := oMdl:GetValue("TW1_CODTDW")
			cConfCob := oMdl:GetValue("TW1_CODTGX")
			cTurno	 := oMdl:GetValue("TW1_TURTDX")
			cSeq	 := oMdl:GetValue("TW1_SEQTDX")
			
			//Lista os dias e os horários da cobertura.
			aCobEftAux := At581Cob( cEscala, cConfCob, cTurno, cSeq )
		
			If !Empty(aCobEftAux)
				For nY := 1 To Len(aCobEftAux)
					If aCobEftAux[nY,2] == 0
						Help( , , "At581LnPos", , STR0055, 1, 0,,,,,,{STR0056}) //"Não é permitido deixar o horário inicio da cobertura zerado."#"Realize o preechimento do horário da cobertura no cadastro de escalas."
						lRet := .F.
						Exit
					Elseif aCobEftAux[nY,3] == 0
						Help( , , "At581LnPos", , STR0057, 1, 0,,,,,,{STR0058}) //"Não é permitido deixar o horário final da cobertura zerado."#"Realize o preechimento do horário da cobertura no cadastro de escalas."
						lRet := .F.
						Exit
					Else
						aAdd( aCobEft, { aCobEftAux[nY,1], aCobEftAux[nY,2], aCobEftAux[nY,3] } )
					Endif
				Next nY
			Else
				Help( , , "At581LnPos", , STR0059, 1, 0,,,,,,{STR0060}) //"Configuração de Escala não permite esse tipo de cobertura."#"Realize a configuração no cadastro de escalas."
				lRet := .F.
				Exit
			Endif
		Endif
	Next nX
	
	If !Empty(aCobEft) .And. lRet
	
		aCobEft := aSort(aCobEft, , ,{|x,y|x[1] < y[1]})
			
		For nX := 1 To Len(aCobEft)
	
			If cDiaSem <> aCobEft[nX,1]  //Quando o dia for diferente
				cDiaSem := aCobEft[nX,1] //Dia da Semana
				nHrIni 	:= aCobEft[nX,2] //Horário inicio
				nHrFim 	:= aCobEft[nX,3] //Horário fim
	
			Else //Quando for o mesmo dia, verifica se os horários estão sobrepostos.
				If !(nHrIni > aCobEft[nX,3] .Or. nHrFim < aCobEft[nX,2])
					Help( , , "At581LnPos", , STR0061, 1, 0,,,,,,{STR0062}) //"Conflito no dia e no horário da cobertura."#"Escolha um posto que tem dia ou o horário de atendimento diferente."
					lRet := .F.
					Exit
				Endif
			Endif
		Next nX
	Endif
	
Elseif cTipoCob == "4"
	dCobIni := oMdl:GetValue("TW1_COBINI")
	dCobFin := oMdl:GetValue("TW1_COBFIN")
	For nX := 1 To oMdl:Length()
		oMdl:GoLine(nX)
		If !oMdl:IsDeleted() .And. nX <> nLine .And. !(dCobIni >= oMdl:GetValue("TW1_COBFIN") .Or. dCobFin <= oMdl:GetValue("TW1_COBINI"))
			Help( , , "At581LnPos", , STR0083, 1, 0,,,,,,{STR0084}) //"Conflito na data inicial e final da cobertura."#"Informe uma data que não conflite com as datas anteriores."
			lRet := .F.
			Exit
		Endif
	Next nX
Endif

oMdl:Goline(nLine)

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At581Cob()
@description	Lista a cobertura do efetivo por escala, turno e sequência.

@author Kaique Schiller
@since 22/05/2018
@return cRet
/*/
//------------------------------------------------------------------
Static Function At581Cob( cEscala, cConfCob, cTurno, cSeq )
Local aRet 	  	:= {}
Local cAliasTGW := GetNextAlias()
Local aCobEfe   := {}
Local nPos      := 0
Local nPosAte   := 0

BeginSql Alias cAliasTGW

	SELECT 
		TGW.TGW_DIASEM, TGW.TGW_HORINI, TGW.TGW_HORFIM, 
		TGW.TGW_STATUS, TGW.TGW_COBTDX, TGW.TGW_COBTIP
	FROM 
		%table:TGW% TGW
	JOIN %table:TDX% TDX ON 
		TDX.TDX_FILIAL = %xFilial:TDX% AND
		TDX.TDX_CODTDW = %Exp:cEscala% AND
		TDX.TDX_TURNO  = %Exp:cTurno%  AND
		TDX.TDX_SEQTUR = %Exp:cSeq%	   AND
		TDX.%NotDel%
	JOIN %table:TGX% TGX ON
		TGX.TGX_FILIAL = %xFilial:TGX% AND
		TGX.TGX_CODTDW = %Exp:cEscala% AND 
		TGX.TGX_COD	   = %Exp:cConfCob% AND 
		TGX.TGX_ITEM   = TGW.TGW_COBTDX AND
		TGX.%NotDel%
	WHERE
		TGW.TGW_FILIAL = %xFilial:TGW% AND 
		TGW.TGW_EFETDX = TDX.TDX_COD   AND 
		TGW.TGW_COBTDX <> ' ' 		   AND 
		TGW.%NotDel%	

EndSql

While (cAliasTGW)->(!Eof())

	aAdd( aCobEfe, { 	(cAliasTGW)->TGW_DIASEM,;	//Dia da Semana
						(cAliasTGW)->TGW_HORINI,;	//Hora Inicio
						(cAliasTGW)->TGW_HORFIM } ) //Hora Final

	(cAliasTGW)->(dbSkip())

EndDo

(cAliasTGW)->(dbCloseArea())

aRet := aCobEfe

Return(aRet)

//-------------------------------------------------------------------
/*/{Protheus.doc} At581IniLg()
@description	Inicializador padrão da legenda.

@author Kaique Schiller
@since 22/05/2018
@return cCor
/*/
//------------------------------------------------------------------
Function At581IniLg(oMdl,cCmp,xVlr)
Local cCor 		:= ""
Local cEncTFF	:= ""
Local aChkFe	:= {}
Local lProgFer	:= .F.
Local lFerias	:= .F.

If oMdl:GetOperation() <> MODEL_OPERATION_INSERT
	If TW0->TW0_TIPO $ "1|2|3"
		If !Empty(TW1->TW1_CODTFF)
			
			cEncTFF := Posicione("TFF", 1, xFilial("TFF")+TW1->TW1_CODTFF, "TFF_ENCE")
	
			If cEncTFF == "1"
				cCor := "BR_AZUL"
			Else
				If Empty(TW1->TW1_ATEND)
					cCor := "BR_VERDE"
				Elseif !Empty(TW1->TW1_ATEND)
					cCor := "BR_AMARELO"
				Endif
			Endif
		Endif
	Elseif TW0->TW0_TIPO == "4"
		DbselectArea("AA1")
		AA1->(DbSetOrder(1))
		If AA1->(DbSeek(FwxFilial("AA1")+TW1->TW1_ATEND))

			aChkFe := At570ChkFe(AA1->AA1_FILIAL, AA1->AA1_CDFUNC, TW1->TW1_COBINI, TW1->TW1_COBFIN+1)
			
			lProgFer := aChkFe[1] .Or. aChkFe[2] .Or. aChkFe[3] 
	
			lFerias := aChkFe[4]
	
			If lFerias .And. dDataBase >= aChkFe[5] .And. dDataBase <= aChkFe[6]
				cCor := "BR_AMARELO"
			ElseIf lProgFer
				cCor := "BR_VERDE"
			Endif
		Endif
	Endif
Endif

Return cCor

//-------------------------------------------------------------------
/*/{Protheus.doc} at581DClck()
@description	Double Click da legenda.

@author Kaique Schiller
@since 22/05/2018
@return .T.
/*/
//------------------------------------------------------------------
Function at581DClck(oFormulario,cField)

If cField == 'TW1_STATUS'
	A581Legend()
EndIf

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} A581Legend()
@description	Composição das legendas.

@author Kaique Schiller
@since 22/05/2018
@return Nil
/*/
//------------------------------------------------------------------
Function A581Legend()
Local aLeg	:= {}

If nTipoRt == 1
	aAdd(aLeg,{"BR_VERDE"	,STR0063}) //"Posto sem alocação."
	aAdd(aLeg,{"BR_AMARELO"	,STR0064}) //"Posto com alocação."
	aAdd(aLeg,{"BR_AZUL" 	,STR0065}) //"Posto encerrado."
Elseif nTipoRt == 2
	aAdd(aLeg,{"BR_VERDE"	,STR0085}) //"Férias Programadas."
	aAdd(aLeg,{"BR_AMARELO"	,STR0086}) //"Férias."
Endif

BrwLegenda(STR0066,STR0067,aLeg) //"Legenda"#"Status"

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} At581Act()
@description	Ativação do modelo.

@author Kaique Schiller
@since 22/05/2018
@return Nil
/*/
//------------------------------------------------------------------
Function At581Act(oMdl)
Local oMdlTW1 	:= oMdl:GetModel("TW1DETAIL")
Local oStruTW1	:= oMdlTW1:GetStruct()

If nTipoRt == 2
	oStruTW1:SetProperty("TW1_CODTFF",MODEL_FIELD_OBRIGAT,.F.)
	oStruTW1:SetProperty("TW1_CODTDX",MODEL_FIELD_OBRIGAT,.F.)
	oStruTW1:SetProperty("TW1_CODTGX",MODEL_FIELD_OBRIGAT,.F.)
	oStruTW1:SetProperty("TW1_GRUPO" ,MODEL_FIELD_OBRIGAT,.F.)
	oStruTW1:SetProperty("TW1_COBINI",MODEL_FIELD_OBRIGAT,.T.)
	oStruTW1:SetProperty("TW1_COBFIN",MODEL_FIELD_OBRIGAT,.T.)

Endif

Return .T.

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At581Alt

@description	Alteração dos atendentes na rota de cobertura.

@author Kaique Schiller
@since 22/06/2018
@return lRet
/*/
//--------------------------------------------------------------------------------------------------------
Function At581Alt(cCodTFF,cCodTDX,cCodTec,nGrupo)
Local cTmpQry 	:= GetNextAlias()
Local oMdl581	:= Nil
Local oMdlTW1	:= Nil 
Local aErro		:= {}
Local lRet		:= .T.
Local cWhere    := ""
Local nTpRota	:= 0
Default nGrupo	:= 0

If nGrupo == 0
	cWhere += "TW1.TW1_ATEND = '"+cCodTec+"' AND "
Else
	cWhere += "TW1.TW1_ATEND = '' AND "
Endif

cWhere := "%"+cWhere+"%"

BeginSql Alias cTmpQry
	SELECT TW1.TW1_COD,TW1.TW1_CODTW0
	FROM %table:TW1% TW1
	WHERE %Exp:cWhere%
	  TW1.TW1_FILIAL = %xFilial:TW1%
	  AND TW1.%NotDel%
	  AND TW1.TW1_CODTFF  = %Exp:cCodTFF%
	  AND TW1.TW1_CODTDX  = %Exp:cCodTDX%	  
EndSql

While (cTmpQry)->(!Eof())

	DbSelectArea("TW0")
	TW0->(DbSetOrder(1))
	If TW0->(DbSeek(FwxFilial("TW0")+(cTmpQry)->TW1_CODTW0))
		oMdl581 := FwLoadModel("TECA581")
		oMdl581:SetOperation(MODEL_OPERATION_UPDATE)
		
		If TW0->TW0_TIPO $ "1|2|3"
			nTpRota := 1
		Elseif TW0->TW0_TIPO == "4"
			nTpRota := 2
		Endif

		At581EscRt(nTpRota)

		oMdl581:Activate()

		oMdlTW1 := oMdl581:GetModel("TW1DETAIL")

		If nGrupo == 0
			If oMdlTW1:SeekLine({{"TW1_CODTFF", cCodTFF},;
								 {"TW1_CODTDX", cCodTDX},;
								 {"TW1_ATEND" , cCodTec}})
	
				lRet := oMdlTW1:SetValue("TW1_ATEND","")
			Endif
		Else
			If oMdlTW1:SeekLine({{"TW1_CODTFF", cCodTFF},;
								 {"TW1_CODTDX", cCodTDX}})
	
				lRet := oMdlTW1:SetValue("TW1_ATEND",cCodTec)
				lRet := lRet .And. oMdlTW1:SetValue("TW1_GRUPO",nGrupo)
			Endif
		Endif

		If lRet

			lRet := oMdl581:VldData()
	
			If lRet
				lRet  := oMdl581:CommitData()
			Endif
		Endif

		If !lRet
			aErro := oMdl581:GetErrorMessage()
			Help( ,, "At336RecRt",, aErro[MODEL_MSGERR_MESSAGE], 1, 0 )
			Exit
		Endif

	Endif

	(cTmpQry)->(dbSkip())

EndDo

(cTmpQry)->(DbCloseArea())

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At581Alt

@description	Seleção de campos.

@author Kaique Schiller
@since 22/06/2018
@return lRet
/*/
//--------------------------------------------------------------------------------------------------------
Static Function At581Cmps(cCampo)
Local lRet	:= .T.

If nTipoRt == 1
	lRet := !( AllTrim(cCampo)$"TW1_CODTW0|TW1_FERINI|TW1_FERFIN|TW1_COBINI|TW1_COBFIN|TW1_CODREV")
ELseif nTipoRt == 2
	lRet := !( AllTrim(cCampo)$"TW1_CODTW0|TW1_CODTFF|TW1_CODABS|TW1_LOCAL|TW1_CODTDX|TW1_CODTGX|TW1_GRUPO|TW1_CODTDW|TW1_ESCALA|TW1_TURTDX|TW1_SEQTDX|TW1_CODREV")
Endif

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At581EscRt

@description	Escolha de configuração de rota de cobertura.

@author Kaique Schiller
@since 22/06/2018
@return lRet
/*/
//--------------------------------------------------------------------------------------------------------
Function At581EscRt(nTpRt)
Local lRet		:= .T.
Default nTpRt 	:= 0

If nTpRt == 0
	nTipoRt := 	GSEscolha( 	STR0087,; 	//"Rota de Cobertura."
							STR0088,;  	//"Selecione o tipo de Rota de Cobertura."
						 {  STR0089, STR0090},;  	//"Almocista, Jantista e Folguista"##"Ferista"
				1 )
Else
	nTipoRt := nTpRt
Endif

If nTipoRt == 0 
	lRet := .F.
Endif

Return lRet


//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At581GetRt

@description	Verifica qual foi a escolha na rota de cobertura e também é utilizado no inicializador padrão do campo TW0_TIPO.

@author Kaique Schiller
@since 22/06/2018
@return xRet
/*/
//--------------------------------------------------------------------------------------------------------
Function At581GetRt(cRelac)
Local xRet
Default cRelac := ""

If cRelac == "2"
	xRet := nTipoRt
Elseif cRelac == "1"
	If nTipoRt == 1
		xRet := "1"
	Elseif nTipoRt == 2
		xRet := "4"
	Else
		xRet := ""
	Endif
Endif

Return xRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At581Rota

@description	Verifica se o atendente esta envolvido na rota de cobertura.

@author Kaique Schiller
@since 22/06/2018
@return lRet
/*/
//--------------------------------------------------------------------------------------------------------
Function At581Rota(cCodTFF,cCodTDX,cCodTec,nGrupo,dDtCob,nTipRt)
Local cAliasTW1 := GetNextAlias()
Local lRet		:= .F.
Local cWhere    := ""
Default cCodTFF := ""
Default cCodTDX := ""
Default cCodTec := ""
Default nGrupo  := 0
Default dDtCob	:= sTod("")
Default nTipRt	:= 0

If nTipRt == 1
	If !Empty(cCodTec)
		BeginSql Alias cAliasTW1
		
			SELECT 
				TW1.TW1_COD
			FROM 
				%table:TW1% TW1
			INNER JOIN %Table:TW0% TW0 
				ON 	TW0.TW0_FILIAL 	= %xFilial:TW0%
				AND TW0.TW0_COD 	= TW1.TW1_CODTW0
				AND TW0.%NotDel%
			WHERE
				TW1.TW1_FILIAL = %xFilial:TW1% 	AND
				TW1.TW1_ATEND  = %Exp:cCodTec%  AND
				%Exp:dDtCob% BETWEEN TW1.TW1_COBINI AND TW1.TW1_COBFIN AND
				TW1.%NotDel% 					AND
				TW0.TW0_ATEND <> ' '			AND
				TW0.TW0_TIPO = '4'
		EndSql
	
		If !(cAliasTW1)->(Eof())
			lRet := .T.
		Endif
	Endif

	(cAliasTW1)->(DbCloseArea())

Elseif nTipRt == 2 .Or. nTipRt == 3

	If !Empty(cCodTFF) .And. !Empty(cCodTDX) .And. !Empty(cCodTec) .And. nGrupo <> 0

		If nTipRt == 2
			cWhere := "% TW0.TW0_TIPO ='1' %"
		Elseif nTipRt == 3
			cWhere := "% (TW0.TW0_TIPO ='2' OR TW0.TW0_TIPO ='3') %"
		Endif

		BeginSql Alias cAliasTW1
		
			SELECT 
				TW1.TW1_COD
			FROM 
				%table:TW1% TW1
			INNER JOIN %Table:TW0% TW0 
				ON 	TW0.TW0_FILIAL 	= %xFilial:TW0%
				AND TW0.TW0_COD 	= TW1.TW1_CODTW0
				AND TW0.%NotDel%
			WHERE
				TW1.TW1_FILIAL = %xFilial:TW1% 	AND
				TW1.TW1_CODTFF = %Exp:cCodTFF%  AND
				TW1.TW1_CODTDX = %Exp:cCodTDX%  AND
				TW1.TW1_ATEND  = %Exp:cCodTec%  AND
				TW1.TW1_GRUPO  = %Exp:nGrupo%   AND
				TW1.%NotDel% 					AND
				TW0.TW0_ATEND <> ' '			AND
				%Exp:cWhere%
		EndSql
	
		If !(cAliasTW1)->(Eof())
			lRet := .T.
		Endif
	
		(cAliasTW1)->(DbCloseArea())
	
	Endif
Endif

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At581Feris

@description	Seleciona o atendente que fará a cobertura das férias.

@author Kaique Schiller
@since 22/06/2018
@return aRet
/*/
//--------------------------------------------------------------------------------------------------------
Function At581Feris(cCodTec,dDtCobIni,dDtCobFin,lFerista,lCobFer)
Local aRet 		 := {}
Local cAliasTW1  := GetNextAlias()
Local cWhere	 := ""
Default lFerista := .F.
Default lCobFer	 := .F.

If lFerista
	cWhere += "TW0.TW0_ATEND = '"+cCodTec+"' AND "
Else
	cWhere += "TW1.TW1_ATEND = '"+cCodTec+"' AND "
Endif

cWhere := "%"+cWhere+"%"

BeginSql Alias cAliasTW1

	SELECT
		TW0.TW0_ATEND,TW1.TW1_COBINI,TW1_COBFIN,TW1.TW1_ATEND
	FROM 
		%table:TW1% TW1
	INNER JOIN %Table:TW0% TW0 
		ON 	TW0.TW0_FILIAL 	= %xFilial:TW0%
		AND TW0.TW0_COD 	= TW1.TW1_CODTW0
		AND TW0.%NotDel%
	WHERE
		%Exp:cWhere%
		TW1.TW1_FILIAL = %xFilial:TW1% 	AND
		NOT( TW1_COBINI > %Exp:dDtCobFin% OR TW1_COBFIN < %Exp:dDtCobIni% ) AND
		TW1.%NotDel% 					AND
		TW0.TW0_ATEND <> ' '			AND
		TW0.TW0_TIPO = '4'
EndSql

If !(cAliasTW1)->(Eof())

	aRet := {Iif(lCobFer,(cAliasTW1)->TW1_ATEND,(cAliasTW1)->TW0_ATEND),;
			 sTod((cAliasTW1)->TW1_COBINI),;
			 sTod((cAliasTW1)->TW1_COBFIN)}

Endif

(cAliasTW1)->(DbCloseArea())

Return aRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At581ChkFe

@description	Verifica se o atendente está de ferias.

@author Kaique Schiller
@since 02/08/2018
@return aFerRet
/*/
//--------------------------------------------------------------------------------------------------------
Function At581ChkFe(cCodAtend,dDtIni,dDtFim)
Local aFerRet := {.F.,.F.,.F.,.F.,sTod(""),sTod("")}
Default cCodAtend := ""
Default dDtIni	  := sTod("")
Default dDtFim	  := sTod("")

If !Empty(cCodAtend) .And. !Empty(dDtIni) .And. !Empty(dDtFim)
	DbselectArea("AA1")
	AA1->(DbSetOrder(1))
	If AA1->(DbSeek(FwxFilial("AA1")+cCodAtend))
		aFerRet := At570ChkFe(AA1->AA1_FILIAL, AA1->AA1_CDFUNC, dDtIni,dDtFim)
	Endif
Endif

Return aFerRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At581TpRot
Verifica qual é o tipo de rota de cobertura que o atendente esta envolvido

@author Kaique Schiller
@since 28/03/2018
@return cTpRota
/*/
//--------------------------------------------------------------------------------------------------------
Function At581TpRot(cCodTec)
Local cTpRota	:= ""
Default cCodTec := ""

DbSelectArea("TW0")
TW0->(DbSetOrder(2))
If TW0->(DbSeek(xFilial("TW0")+cCodTec))
	cTpRota := TW0->TW0_TIPO
Endif

Return cTpRota

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At581FerRt
Verifica se os atendentes que pertencem a rota do ferista realmente sairam de ferias

@author Kaique Schiller
@since 04/10/2018
@return lRet
/*/
//--------------------------------------------------------------------------------------------------------
Function At581FerRt(cCodRt)
Local aRet 		:= {.F.,""}
Local aFerRet	:= {}

DbSelectArea("TW1")
TW1->(DbSetOrder(1))
If TW1->(DbSeek(xFilial("TW1")+cCodRt))
	While TW1->(!Eof()) .And. xFilial("TW1") == TW1->TW1_FILIAL .And. cCodRt == TW1->TW1_CODTW0 .And. !aRet[1]
		aFerRet := At581ChkFe(TW1->TW1_ATEND,dDataBase,dDataBase)
		If aFerRet[4] .And. dDataBase >= aFerRet[5] .And. dDataBase <= aFerRet[6]			
			aRet := {.T.,TW1->TW1_ATEND}
		Endif
		TW1->(DbSkip())
	EndDo
Endif

Return aRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At581FerRt
Verifica se os atendentes que pertencem a rota do folguista sairam de folga.

@author Kaique Schiller
@since 04/10/2018
@return lRet
/*/
//--------------------------------------------------------------------------------------------------------
Function At581Folg(cCodTec,dData)
Local lRet		:= .F.
Local cTmpLoc 	:= ""
Local cEscala   := ""
Local cCodTDX	:= ""
Local cCodTFF   := ""
Local aCfgCob	:= {}

DbSelectArea("TW0")
TW0->(DbSetOrder(2))
If TW0->(DbSeek(xFilial("TW0")+cCodTec)) //seleciona o atendente dentro da rota

	DbSelectArea("TW1")
	TW1->(DbSetOrder(1))
	If TW1->(DbSeek(xFilial("TW1")+TW0->TW0_COD)) //seleciona os itens da rota

		While TW1->(!Eof()) .And. xFilial("TW1") == TW1->TW1_FILIAL .And. TW0->TW0_COD == TW1->TW1_CODTW0 .And. !lRet
		
			cCodTFF   := TW1->TW1_CODTFF		
			cCodTDX	  := TW1->TW1_CODTDX
			cEscala   := Posicione("TFF", 1, xFilial("TFF")+cCodTFF, "TFF_ESCALA")
			cTurno	  := Posicione("TDX", 1, xFilial("TDX")+cCodTDX, "TDX_TURNO")
			cSeq	  := Posicione("TDX", 1, xFilial("TDX")+cCodTDX, "TDX_SEQTUR")
							 
			aCfgCob := At581Cob( cEscala , cCodTDX, cTurno, cSeq )

			If aScan(	aCfgCob, { |x| x[1] == Str(Dow(dData),1) } ) > 0
				lRet := .T.
			Endif

			TW1->(DbSkip())
		EndDo
	Endif
Endif

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At581RtRev
Armazena o código da TFF nova na rota de cobertura quando é relizado uma revisão de contrato.

@author Kaique Schiller
@since 05/11/2018
@return .T.
/*/
//--------------------------------------------------------------------------------------------------------
Function At581RtRev(cCodTFF,cCodRev)
Local cTmpQry := ""

If !Empty(cCodTFF)

	cTmpQry := GetNextAlias()

	BeginSql Alias cTmpQry
		SELECT TW1.TW1_CODTW0,TW1_COD
		FROM %table:TW1% TW1
		WHERE TW1.TW1_FILIAL = %xFilial:TW1%
		  AND TW1.TW1_CODTFF = %Exp:cCodTFF%
		  AND TW1.%NotDel%
	EndSql
	
	DbSelectArea("TW1")
	TW1->(DbSetOrder(1))
	While (cTmpQry)->(!Eof())
		TW1->(DbSeek(FwxFilial("TW1")+(cTmpQry)->(TW1_CODTW0+TW1_COD)))
		Reclock("TW1",.F.)
			TW1->TW1_CODREV := cCodRev
		TW1->(MsUnlock())
		(cTmpQry)->(DbSkip())
	EndDo
	
	(cTmpQry)->(DbCloseArea())

Endif

Return .T.

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At581AtuRt
Atualiza o codigo da TFF na rota de cobertura com o código da revisão armazenado na tabela TW1.

@author Kaique Schiller
@since 06/11/2018
@return .T.
/*/
//--------------------------------------------------------------------------------------------------------
Function At581AtuRt(cCodOrc)
Local cTmpQry := ""

If !Empty(cCodOrc)

	cTmpQry := GetNextAlias()

	BeginSql Alias cTmpQry
		SELECT TW1_CODTW0,TW1_COD
		FROM %table:TFJ% TFJ
		JOIN %table:TFL% TFL 
			ON 	TFL.TFL_FILIAL = %xFilial:TFL% 
			AND TFL.TFL_CODPAI = TFJ.TFJ_CODIGO 
			AND TFL.%NotDel%
		JOIN %table:TFF% TFF 
			ON TFF.TFF_FILIAL  = %xFilial:TFF% 
			AND TFF.TFF_CODPAI = TFL_CODIGO 
			AND TFF.%NotDel%
		JOIN %table:TW1% TW1
			ON TW1.TW1_FILIAL  = %xFilial:TW1% 
			AND TW1.TW1_CODREV = TFF.TFF_COD
			AND TW1.%NotDel%
		WHERE TFJ.TFJ_FILIAL   = %xFilial:TFJ% AND 
			  TFJ.TFJ_CODIGO   = %Exp:cCodOrc% AND
			  TFJ.%NotDel%
	EndSql
	
	DbSelectArea("TW1")
	TW1->(DbSetOrder(1))
	While (cTmpQry)->(!Eof())
		TW1->(DbSeek(FwxFilial("TW1")+(cTmpQry)->(TW1_CODTW0+TW1_COD)))
		Reclock("TW1",.F.)
			TW1->TW1_CODTFF := TW1->TW1_CODREV
			TW1->TW1_CODREV := ""
		TW1->(MsUnlock())
		(cTmpQry)->(DbSkip())
	EndDo
	
	(cTmpQry)->(DbCloseArea())

Endif

Return .T.


//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At581Cmt
Bloco de gravação do modelo da rota de cobertura.

@author Kaique Schiller
@since 06/11/2018
@return lRet
/*/
//--------------------------------------------------------------------------------------------------------
Function At581Cmt(oMdl,b,c)
Local oMdlTW0 	:= oMdl:GetModel("TW0MASTER")
Local oMdlTW1 	:= oMdl:GetModel("TW1DETAIL")
Local cTipoCob 	:= oMdlTW0:Getvalue("TW0_TIPO")
Local oMdlTFF 	:= Nil
Local cCodRota	:= ""
Local cAtdRota	:= ""
Local cCodTFF	:= ""
Local cCodTDX	:= ""
Local cCodTGX	:= ""
Local nGrupo	:= 0
Local cEscala	:= ""
Local nX		:= 0 
Local aErro		:= {}
Local lRet		:= .T.

DbSelectArea("TW1")
TW1->(DbSetOrder(1))

DbSelectArea("TFF")
TFF->(DbSetOrder(1))

If oMdl:GetOperation() <> MODEL_OPERATION_DELETE
	If cTipoCob $ "2|3"
		For nX := 1 To oMdlTW1:Length()
			oMdlTW1:Goline(nX)
			//Posiciona na YFF para atualizar o saldo de quantidade de coberturas do almocista.
			TFF->(DbSeek(xFilial("TFF")+oMdlTW1:GetValue("TW1_CODTFF")))
			//Se for deleção.
			If !oMdlTW1:IsDeleted()
				//Se não existir na TW1 atualiza o saldo.
				If !TW1->(DbSeek(xFilial("TW1")+oMdlTW1:GetValue("TW1_CODTW0")+oMdlTW1:GetValue("TW1_COD")))
					Reclock("TFF",.F.)
						TFF->TFF_SLDHRR := TFF->TFF_SLDHRR-1
					TFF->(MsUnlock())
				Endif
			Else
				//Se existir na tabela e a linha estiver excluida atualiza o saldo.
				If TW1->(DbSeek(xFilial("TW1")+oMdlTW1:GetValue("TW1_CODTW0")+oMdlTW1:GetValue("TW1_COD")))
					Reclock("TFF",.F.)
						TFF->TFF_SLDHRR := TFF->TFF_SLDHRR+1
					TFF->(MsUnlock())
				Endif
			Endif
		Next nX
	Endif
Else
	If cTipoCob $ "2|3"
		For nX := 1 To oMdlTW1:Length()
			oMdlTW1:Goline(nX)
			//Posiciona na YFF para atualizar o saldo de quantidade de coberturas do almocista.
			TFF->(DbSeek(xFilial("TFF")+oMdlTW1:GetValue("TW1_CODTFF")))
			Reclock("TFF",.F.)
				TFF->TFF_SLDHRR := TFF->TFF_SLDHRR+1
			TFF->(MsUnlock())
		Next nX
	Endif
Endif

lRet := FwFormCommit(oMdl)

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At581Update
Alteração do modelo da rota de cobertura.

@author Kaique Schiller
@since 13/03/2019
@return lRet
/*/
//--------------------------------------------------------------------------------------------------------
Function At581Update()

If Empty(TW0->TW0_ATEND)
	FWExecView("Alterar","TECA581",MODEL_OPERATION_UPDATE,,{|| .T.})//"Alterar"
Else
	Help( , , "At581Update", ,"Não é possível realizar a alteração, pois existe atendente efetivo ou em cobertura.", 1, 0,,,,,,{"Realize o recolhimento do atendente na movimentação de atendente."}) // "Não é possível realizar a alteração, pois existe atendente efetivo ou em cobertura."##"Realize o recolhimento do atendente de rota de cobertura na movimentação de atendente."
Endif

Return .T.