#Include "PROTHEUS.CH"
#Include "FWMVCDEF.CH"
#Include "TECA970.CH"

#Define DF_HORIMETRO_FASE_SEPARACAO 	"SEP"	//Saida do horimetro da empresa
#Define DF_HORIMETRO_FASE_OCORRENCIA	"OCO"	//Outras ocorrências com o horimetro
#Define DF_HORIMETRO_FASE_RETORNO   	"RET"	//Retorno do horimetro para a empresa
#Define DF_HORIMETRO_FASE_INTEGRADO 	"INT"	//

#Define DF_HORIMETRO_MOTIVO_SAIDA		"0"		//Saida do horimetro da empresa
#Define DF_HORIMETRO_MOTIVO_MARCACAO	"1"		//Marcação do horimetro (registro de sua leitura)
#Define DF_HORIMETRO_MOTIVO_SUBST		"2"		//Substituição do horimetro
#Define DF_HORIMETRO_MOTIVO_QUEBRA		"3"		//Quebra do horimetro
#Define DF_HORIMETRO_MOTIVO_RETORNO 	"9"		//Retorno do horimetro para a empresa

#Define DF_HORIMETRO_TPLCTO_SAIDA		"1"		//Saída para locação
#Define DF_HORIMETRO_TPLCTO_ATUALIZA	"2"		//Atualização
#Define DF_HORIMETRO_TPLCTO_RETORNO 	"3"		//Retorno de locação
#Define DF_HORIMETRO_TPLCTO_INTEGRADO	"4"		//Integrado

Static cPVA460Ava		:= ""
Static cItPVA460Ava		:= ""
Static aApontaHrm		:= {}	// Array que irá conter as indicações para o apontamento do horimetro da(s) base(s) de atendimento

//------------------------------------------------------------------------------
/*/{Protheus.doc} TECA970
@description  Horimetro das bases de atendimento
@author        Alexandre da Costa (a.costa)
@since         13/07/2016
@version       P12
/*/
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
@description  Definição do Model
@sample        ModelDef() 
@param         Nenhum
@return        ExpO:         Objeto FwFormModel 
@author        Alexandre da Costa (a.costa)      
@since         20/07/2016
@version       P12   
/*/
//------------------------------------------------------------------------------
Static Function ModelDef()

Local	oModel		:= Nil
Local	oStrAA3	:= FWFormStruct(1, "AA3")
Local	oStrTWT	:= FWFormStruct(1, "TWT")	// TWT - Atualizações do horimetro

// Cria o objeto do modelo de dados principal
oModel := MPFormModel():New("TECA970", /*<bPreValid>*/, /*<bTudoOK>*/, {|oModel| At970Commit(oModel)} /*<bCommit>*/, /*<bCancel>*/)

oModel:AddFields("AA3MASTER", /*<cOwner>*/ , oStrAA3)
oModel:AddGrid("TWTDETAIL"/*<cId>*/,;
               "AA3MASTER"/*<cOwner>*/,;
               oStrTWT/*<oModelStruct>*/,;
               {|oModTWT, nLine, cAcao, cCampo| PrLinOkTWT(oModTWT, nLine, cAcao, cCampo)}/*<bLinePre>*/,;
               {|oModTWT, nLine, cAcao, cCampo| PsLinOkTWT(oModTWT, nLine)}/*<bLinePos>*/,;
               /*<bPreVal>*/,;
               /*<bPosVal>*/,;
               /*<bLoad>*/) // Cria a grid das atualizações do horimetro

oModel:SetRelation("TWTDETAIL", {{"TWT_FILIAL","xFilial('TWT')"}, {"TWT_CODAA3","AA3_NUMSER"}}, TWT->(IndexKey(1)))

oModel:GetModel("TWTDETAIL"):SetDescription(STR0001)	//"Atualização do horimetro"

oModel:GetModel("TWTDETAIL"):SetOptional(.T.)

oModel:GetModel("TWTDETAIL"):SetUniqueLine({"TWT_ITEM"})	// Chave única na entrada de dados no GRID

oStrAA3:SetProperty("AA3_CBASE", MODEL_FIELD_WHEN, {|| .F.})
oStrAA3:SetProperty("AA3_ITEM",  MODEL_FIELD_WHEN, {|| .F.})
oStrAA3:SetProperty("AA3_CHAPA", MODEL_FIELD_WHEN, {|| .F.})

oModel:SetVldActivate({|oModel| At970SVAct(oModel)})	//Verifica se o modelo pode ser ativado.
Return(oModel)

//------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
@description  Definição da View
@sample        ViewDef()
@param         Nenhum
@return        ExpO:         Objeto FwFormView 
@author        Alexandre da Costa (a.costa)
@since         20/07/2016       
@version       P12   
/*/
//------------------------------------------------------------------------------
Static Function ViewDef()

Local oView		:= Nil									// Interface de visualização construída	
Local oModel		:= ModelDef()							// Cria um objeto de Modelo de dados baseado no ModelDef do fonte informado

// Cria as estruturas a serem usadas na View
Local oStrAA3		:= FWFormStruct(2, "AA3", {|cCampo| (AllTrim(cCampo)$"AA3_CODPRO,AA3_DESPRO,AA3_NUMSER,AA3_CBASE,AA3_ITEM,AA3_CHAPA,AA3_CDBMFL,AA3_CODBEM") })	// AA3 - Base de atendimento
Local oStrTWT 	:= FWFormStruct(2, "TWT")						// TWT - Atualização do horimetro

oStrAA3:AddFolder('GROUP1', STR0093,'',2) // "Base GS"
oStrAA3:AddFolder('GROUP2', STR0094,'',2) // "Ativo ATF"
oStrAA3:AddFolder('GROUP3', STR0095,'',2) // "Bem MNT"

oStrAA3:SetProperty("*", MVC_VIEW_CANCHANGE, .F.)

oStrAA3:SetProperty("AA3_CODPRO", MVC_VIEW_FOLDER_NUMBER, "GROUP1")
oStrAA3:SetProperty("AA3_DESPRO", MVC_VIEW_FOLDER_NUMBER, "GROUP1")
oStrAA3:SetProperty("AA3_NUMSER", MVC_VIEW_FOLDER_NUMBER, "GROUP1")

oStrAA3:SetProperty("AA3_CBASE", MVC_VIEW_FOLDER_NUMBER, "GROUP2")
oStrAA3:SetProperty("AA3_ITEM", MVC_VIEW_FOLDER_NUMBER, "GROUP2")
oStrAA3:SetProperty("AA3_CHAPA", MVC_VIEW_FOLDER_NUMBER, "GROUP2")

oStrAA3:SetProperty("AA3_CDBMFL", MVC_VIEW_ORDEM, "01")
oStrAA3:SetProperty("AA3_CDBMFL", MVC_VIEW_FOLDER_NUMBER, "GROUP3")
oStrAA3:SetProperty("AA3_CODBEM", MVC_VIEW_FOLDER_NUMBER, "GROUP3")

oView	:= FWFormView():New()										// Cria o objeto de View
oView:SetModel(oModel)												// Define qual modelo de dados será utilizado

oView:AddField("VIEW_AA3", oStrAA3, "AA3MASTER")					// Adiciona no nosso View um controle do tipo formulário (antiga Enchoice)
oView:AddGrid("VIEW_TWT",  oStrTWT, "TWTDETAIL")					// Cria a grid para lançamento das atualizações do horimetro

oView:CreateHorizontalBox("TOP",  30)								// Adiciona e proporciona as visões na tela
oView:CreateHorizontalBox("DOWN", 70)								// Adiciona e proporciona as visões na tela

oView:SetOwnerView("VIEW_AA3", "TOP")								// Relaciona o identificador (ID) da View com o "box" para sua exibição
oView:SetOwnerView("VIEW_TWT", "DOWN")								// Relaciona o identificador (ID) da View com o "box" para sua exibição

oView:AddIncrementField("VIEW_TWT", "TWT_ITEM")					// Sequência de usuários da etapa (campo incremental - automático) 

oView:SetDescription(STR0001)	//"Atualização do horimetro"	// Identificação (Nomeação) da VIEW

// Opções extras da rotina
oView:AddUserButton(STR0080,'BUDGET', {|oModel| TECA650()})		//"Indenização"
oView:AddUserButton(STR0081,'BUDGET', {|oModel| TECA450()})		//"Ordem de serviço"
Return(oView)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At970SVAct
@description  Valida se o modelo de lançamentos das marcações do horimetro pode ser ativado
@sample        At970SVAct(oModel)
@param         oModel:       Modelo
@return        ExpL:         .T.=Ativação permitida // .F.=Ativação não permitida
@author        Alexandre da Costa (a.costa)
@since         22/07/2016       
@version       P12   
/*/
//------------------------------------------------------------------------------
Static Function At970SVAct(oModel)

Local lRet		:= .T.

If	AA3->AA3_HMEATV <> "1"	// O uso do horimetro para a base de atendimento está configurado?
	Help(,, "At970SVAct",,STR0002,1,0,,,,,,{STR0010})	//"Ação não permitida." ## "A base de atendimento selecionada não está utilizando horimetro. Para utilizar esta funcionalidade, ative o uso do horimetro da base de atendimento."
	lRet	:= .F.
ElseIf	AA3->AA3_HMELIM == 0	// A quantidade limite de dígitos do horimetro para a base de atendimento está configurada?
	Help(,, "At970SVAct",,STR0002,1,0,,,,,,{STR0011})	//"Ação não permitida." ## "A base de atendimento não está com o limite de dígitos do horimetro configurado. Para utilizar esta funcionalidade, configure o limite de dígitos do visor do horimetro ativo da base de atendimento."
	lRet	:= .F.
EndIf
Return	lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At970InTWT
@description  Inicializador de campos da GRID dos lançamentos das marcações do horimetro
@sample        At970InTWT(oModTWT, cTWTFldName, xTWTNewVlr)
@param         oModTWT:     Modelo ativo
@param         cTWTFldName: Nome do campo
@param         xTWTNewVlr:  Conteúdo do campo
@return        ExpX:         Conteúdo para o inicializador do campo selecionado
@author        Alexandre da Costa (a.costa)
@since         20/07/2016       
@version       P12   
/*/
//------------------------------------------------------------------------------
Function At970InTWT(oModTWT, cTWTFldName, xTWTNewVlr)

Local aSaveRows	:= {}
Local nTamNumHor	:= 0
Local nTWTLinGrd	:= 0
Local cUltMotivo	:= ""
Local cUltTpLcto	:= ""
Local cUltHorim	:= ""
Local xRet			:= NIL

Do Case
	Case	cTWTFldName == "TWT_NUMHOR"

			nTamNumHor	:= TamSX3("TWT_NUMHOR")[1]
			If	oModTWT:GetLine() == 0
				xRet	:= StrZero(1,nTamNumHor)
			Else
				cUltMotivo	:= oModTWT:GetValue("TWT_MOTIVO")
				cUltHorim	:= oModTWT:GetValue("TWT_NUMHOR")
				If	( cUltMotivo == DF_HORIMETRO_MOTIVO_SAIDA .OR. cUltMotivo == DF_HORIMETRO_MOTIVO_MARCACAO .OR. cUltMotivo == DF_HORIMETRO_MOTIVO_RETORNO )
					xRet	:= cUltHorim
				ElseIf	( cUltMotivo == DF_HORIMETRO_MOTIVO_SUBST .OR. cUltMotivo == DF_HORIMETRO_MOTIVO_QUEBRA )
					xRet	:= Soma1( cUltHorim )
				EndIf
			EndIf

	Case	cTWTFldName == "TWT_CODMV"

			If	oModTWT:Length() > 0
				aSaveRows	:= FwSaveRows()
				nTWTLinGrd	:= oModTWT:GetLine()
				While	nTWTLinGrd > 0
					oModTWT:GoLine( nTWTLinGrd )
					If	!( oModTWT:IsDeleted() )
						cUltMotivo	:= oModTWT:GetValue("TWT_MOTIVO", nTWTLinGrd)
						cUltTpLcto	:= oModTWT:GetValue("TWT_TPLCTO", nTWTLinGrd)
						If	cUltMotivo <> DF_HORIMETRO_MOTIVO_RETORNO .AND. cUltTpLcto <> DF_HORIMETRO_TPLCTO_RETORNO
							xRet	:= oModTWT:GetValue("TWT_CODMV", nTWTLinGrd)
						EndIf
						EXIT
					EndIf
					-- nTWTLinGrd
				EndDo
				FwRestRows( aSaveRows )
			EndIf
			If	Empty(xRet)
				xRet	:= At970GetMV( AA3->AA3_FILORI, AA3->AA3_NUMSER )
			EndIf

	Case	cTWTFldName == "TWT_HMELIM"

			If	oModTWT:GetLine() == 0
				xRet	:= AA3->AA3_HMELIM
			Else
				If	oModTWT:Length() > 0
					aSaveRows	:= FwSaveRows()
					nTWTLinGrd	:= oModTWT:GetLine()
					While	nTWTLinGrd > 0
						oModTWT:GoLine( nTWTLinGrd )
						If	!( oModTWT:IsDeleted() )
							xRet	:= oModTWT:GetValue("TWT_HMELIM", nTWTLinGrd)
							EXIT
						EndIf
						-- nTWTLinGrd
					EndDo
					FwRestRows( aSaveRows )
				EndIf
			EndIf

EndCase
Return	xRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At970VdTWT
@description  Validação de campos da GRID dos lançamentos das marcações do horimetro
@sample        At970VdTWT(oModTWT, cTWTFldName, xTWTNewVlr, nTWTLinGrd)
@param         oModTWT:      Modelo ativo
@param         cTWTFldName: Nome do campo
@param         xTWTNewVlr:  Conteúdo do campo
@param         nTWTLinGrd:  Linha do GRID
@return        ExpL:         .T.=Informação válida // .F.=Informação inválida
@author        Alexandre da Costa (a.costa)
@since         20/07/2016       
@version       P12   
/*/
//------------------------------------------------------------------------------
Function At970VdTWT(oModTWT, cTWTFldName, xTWTNewVlr, nTWTLinGrd)

Local oView		:= FwViewActive()
Local aSaveRows	:= FwSaveRows()
Local cTimeNow	:= Left(StrTran(Time(),":",""),4)
Local nLinAuxTWT	:= 0
Local dDtAntTWT	:= CtoD(Space(08))
Local cHrAntTWT	:= Space(08)
Local cHmAntTWT	:= Space(TamSX3("TWT_NUMHOR")[1])
Local nVlAntTWT	:= 0
Local nLmAntTWT	:= 0
Local dDtPosTWT	:= CtoD(Space(08))
Local cHrPosTWT	:= Space(08)
Local cHmPosTWT	:= Space(TamSX3("TWT_NUMHOR")[1])
Local nVlPosTWT	:= 0
Local nLmPosTWT	:= 0
Local xAux			:= NIL
Local lRet			:= .T.
Local cMaxHour 		:= "2359"  // quando ainda não existe hora definida usa o máximo para o dia
Local cHoraUsar 	:= ""
 
Do Case
	Case	cTWTFldName == "TWT_DTMARC"

			If	xTWTNewVlr > dDataBase
				Help(,, "At970VldCp",,STR0003,1,0,,,,,,{STR0012})	//"Data da marcação inválida." ## "Data da marcação não pode ser posterior à data atual."
				lRet	:= .F.
			ElseIf	nTWTLinGrd > 1
				nLinAuxTWT	:=	nTWTLinGrd
				While	nLinAuxTWT > 1
					oModTWT:GoLine( -- nLinAuxTWT )
					If	!( oModTWT:IsDeleted() )
						dDtAntTWT	:= oModTWT:GetValue("TWT_DTMARC", nLinAuxTWT)
						cHrAntTWT	:= oModTWT:GetValue("TWT_HRMARC", nLinAuxTWT)
						EXIT
					EndIf
				EndDo
				If nTWTLinGrd < oModTWT:Length()
					nLinAuxTWT	:=	nTWTLinGrd
					While	nLinAuxTWT < oModTWT:Length()
						oModTWT:GoLine( ++ nLinAuxTWT )
						If	!( oModTWT:IsDeleted() )
							dDtPosTWT	:= oModTWT:GetValue("TWT_DTMARC", nLinAuxTWT)
							cHrPosTWT	:= oModTWT:GetValue("TWT_HRMARC", nLinAuxTWT)
							EXIT
						EndIf
					EndDo
				EndIf
				cHoraUsar := If( Empty(oModTWT:GetValue("TWT_HRMARC", nTWTLinGrd)), cMaxHour, oModTWT:GetValue("TWT_HRMARC", nTWTLinGrd) )
				lRet	:= At970VDtHr(dDtAntTWT, cHrAntTWT, xTWTNewVlr, cHoraUsar, dDtPosTWT, cHrPosTWT)
			EndIf

	Case	cTWTFldName == "TWT_HRMARC"

			If	Type(Left(xTWTNewVlr,2))  <> "N" .OR.;
				Type(Right(xTWTNewVlr,2)) <> "N" .OR.;
				Val(Left(xTWTNewVlr,2))   <  0   .OR.;
				Val(Left(xTWTNewVlr,2))   >  23  .OR.;
				Val(Right(xTWTNewVlr,2))  <  0   .OR.;
				Val(Right(xTWTNewVlr,2))  >  59  .OR.;
				Len(AllTrim(xTWTNewVlr))  <  4
				Help(,, "At970VldCp",,STR0004,1,0,,,,,,{STR0013})	//"Hora da marcação inválida." ## "Informe uma hora de marcação válida."
				lRet	:= .F.
			ElseIf	Empty(oModTWT:GetValue("TWT_DTMARC"))
				Help(,, "At970VldCp",,STR0004,1,0,,,,,,{STR0014})	//"Hora da marcação inválida." ## "É necessário que a data da marcação seja informada antes da hora de marcação."
				lRet	:= .F.
			ElseIf oModTWT:GetValue("TWT_DTMARC") == dDataBase .And. ;
					( ( Val(Left(xTWTNewVlr,2)) > Val(Left(cTimeNow,2)) ) .OR.;
					( Val(Left(xTWTNewVlr,2)) == Val(Left(cTimeNow,2)) .AND.;
					Val(Right(xTWTNewVlr,2)) > Val(Right(cTimeNow,2)) ) )
					
				Help(,, "At970VldCp",,STR0004,1,0,,,,,,{STR0015})	//"Hora da marcação inválida." ## "É necessário que a hora da marcação seja anterior ao momento atual."
				lRet	:= .F.
			ElseIf	nTWTLinGrd > 1
				nLinAuxTWT	:=	nTWTLinGrd
				While	nLinAuxTWT > 1
					oModTWT:GoLine( -- nLinAuxTWT )
					If	!( oModTWT:IsDeleted() )
						dDtAntTWT	:= oModTWT:GetValue("TWT_DTMARC", nLinAuxTWT)
						cHrAntTWT	:= oModTWT:GetValue("TWT_HRMARC", nLinAuxTWT)
						EXIT
					EndIf
				EndDo
				If nTWTLinGrd < oModTWT:Length()
					nLinAuxTWT	:=	nTWTLinGrd
					While	nLinAuxTWT < oModTWT:Length()
						oModTWT:GoLine( ++ nLinAuxTWT )
						If	!( oModTWT:IsDeleted() )
							dDtPosTWT	:= oModTWT:GetValue("TWT_DTMARC", nLinAuxTWT)
							cHrPosTWT	:= oModTWT:GetValue("TWT_HRMARC", nLinAuxTWT)
							EXIT
						EndIf
					EndDo
				EndIf
				lRet	:= At970VDtHr(dDtAntTWT, cHrAntTWT, oModTWT:GetValue("TWT_DTMARC", nTWTLinGrd), xTWTNewVlr, dDtPosTWT, cHrPosTWT)
			EndIf

	Case	cTWTFldName == "TWT_MOTIVO"

			If	nTWTLinGrd == 1
				If	xTWTNewVlr <> DF_HORIMETRO_MOTIVO_SAIDA
					Help(,, "At970VldCp",,STR0005,1,0,,,,,,{STR0016})	//"Motivo da marcação inválido." ## "O primeiro motivo de marcação do horimetro de um equipamento deve ser igual à 'Saída'."
					lRet	:= .F.
				ElseIf	oModTWT:GetValue("TWT_TPLCTO", nTWTLinGrd) <> DF_HORIMETRO_TPLCTO_SAIDA
					Help(,, "At970VldCp",,STR0006,1,0,,,,,,{STR0017})	//"Tipo de lançamento da marcação inválido." ## "O primeiro tipo de lançamento da marcação do horimetro de um equipamento deve ser igual à 'Saída p/Separação'. Para isso, acesse a funcionalidade de 'Horimetro -> Atualização para separação'."
					lRet	:= .F.
				EndIf
			Else
				If	xTWTNewVlr == DF_HORIMETRO_MOTIVO_RETORNO
					Help(,, "At970VldCp",,STR0005,1,0,,,,,,{STR0018})	//"Motivo da marcação inválido." ## "Não é permitido o lançamento do retorno de um horimetro. Para isso, acesse a funcionalidade de 'Horimetro -> Atualização para retorno'."
					lRet	:= .F.
				Else
					xAux	:= oModTWT:GetValue("TWT_MOTIVO", nTWTLinGrd - 1)
					If	( xAux == DF_HORIMETRO_MOTIVO_SAIDA   .AND. xTWTNewVlr == DF_HORIMETRO_MOTIVO_SAIDA ) .OR.;
						( xAux == DF_HORIMETRO_MOTIVO_RETORNO .AND. xTWTNewVlr == DF_HORIMETRO_MOTIVO_RETORNO )
						Help(,, "At970VldCp",,STR0005,1,0,,,,,,{STR0019})	//"Motivo da marcação inválido." ## "Não é permitido o lançamento múltiplo de saída e/ou retorno de um horimetro."
						lRet	:= .F.
					ElseIf ( xAux == DF_HORIMETRO_MOTIVO_MARCACAO .AND. xTWTNewVlr == DF_HORIMETRO_MOTIVO_SAIDA )
						Help(,, "At970VldCp",,STR0005,1,0,,,,,,{STR0020})	//"Motivo da marcação inválido." ## "Não é permitida a saída de um horimetro após o lançamento de uma marcação."
						lRet	:= .F.
					ElseIf	( xAux == DF_HORIMETRO_MOTIVO_SUBST .OR. xAux == DF_HORIMETRO_MOTIVO_QUEBRA .OR. xAux == DF_HORIMETRO_MOTIVO_RETORNO ) .AND.;
							( xTWTNewVlr <> DF_HORIMETRO_MOTIVO_SAIDA )
						Help(,, "At970VldCp",,STR0005,1,0,,,,,,{STR0021})	//"Motivo da marcação inválido." ## "É permitido somente o lançamento de uma saída de um novo horimetro após de uma substituição, quebra ou retorno do horimetro anterior do equipamento."
						lRet	:= .F.
					EndIf
					If	lRet
						While	nTWTLinGrd < oModTWT:Length()
							oModTWT:GoLine( ++ nTWTLinGrd )
							If	!( oModTWT:IsDeleted() )
								xAux	:= oModTWT:GetValue("TWT_MOTIVO")
								If	( xAux == DF_HORIMETRO_MOTIVO_SAIDA   .AND. xTWTNewVlr == DF_HORIMETRO_MOTIVO_SAIDA ) .OR.;
									( xAux == DF_HORIMETRO_MOTIVO_RETORNO .AND. xTWTNewVlr == DF_HORIMETRO_MOTIVO_RETORNO )
									Help(,, "At970VldCp",,STR0005,1,0,,,,,,{STR0019})	//"Motivo da marcação inválido." ## "Não é permitido o lançamento múltiplo de saída e/ou retorno de um horimetro."
									lRet	:= .F.
									EXIT
								ElseIf	( xTWTNewVlr == DF_HORIMETRO_MOTIVO_SAIDA .OR. xTWTNewVlr == DF_HORIMETRO_MOTIVO_SUBST .OR. xTWTNewVlr == DF_HORIMETRO_MOTIVO_QUEBRA )
									Help(,, "At970VldCp",,STR0005,1,0,,,,,,{STR0022})	//"Motivo da marcação inválido." ## "Não é permitido o lançamento de uma saída, substituição ou quebra de um horimetro que possua lançamentos posteriores a esta marcação."
									lRet	:= .F.
									EXIT
								ElseIf ( xTWTNewVlr == DF_HORIMETRO_MOTIVO_MARCACAO .AND. xAux == DF_HORIMETRO_MOTIVO_SAIDA )
									Help(,, "At970VldCp",,STR0005,1,0,,,,,,{STR0023})	//"Motivo da marcação inválido." ## "Não é permitido o lançamento de uma marcação de um horimetro que possua um lançamento posterior de saída de um novo horimetro."
									lRet	:= .F.
									EXIT
								EndIf
							EndIf
						EndDo
					EndIf
				EndIf
			EndIf

	Case	cTWTFldName == "TWT_VALHOR"

			If	Empty(oModTWT:GetValue("TWT_DTMARC"))
				Help(,, "At970VldCp",,STR0007,1,0,,,,,,{STR0024})	//"Valor da marcação inválido." ## "É necessário que a data da marcação seja informada antes do valor da marcação."
				lRet	:= .F.
			ElseIf	Empty(oModTWT:GetValue("TWT_HRMARC"))
				Help(,, "At970VldCp",,STR0007,1,0,,,,,,{STR0025})	//"Valor da marcação inválido." ## "É necessário que a hora da marcação seja informada antes do valor da marcação."
				lRet	:= .F.
			ElseIf	xTWTNewVlr < 0
				Help(,, "At970VldCp",,STR0007,1,0,,,,,,{STR0026})	//"Valor da marcação inválido." ## "Informe um valor de marcação válido."
				lRet	:= .F.
			ElseIf	xTWTNewVlr > Val(Replicate("9",oModTWT:GetValue("TWT_HMELIM")))
				Help(,, "At970VldCp",,STR0007,1,0,,,,,,{STR0027})	//"Valor da marcação inválido." ## "O valor de marcação informado ultrapassa o limite do visor do horimetro."
				lRet	:= .F.
			ElseIf	nTWTLinGrd > 1
				If	nTWTLinGrd == oModTWT:Length()
					If oModTWT:GetValue("TWT_VIRADA") <> "1" .And. ;
						xTWTNewVlr < oModTWT:GetValue("TWT_VALHOR", nTWTLinGrd - 1) .And. ;
						oModTWT:GetValue("TWT_NUMHOR") == oModTWT:GetValue("TWT_NUMHOR", nTWTLinGrd - 1)  // só faz a pergunta se não trocou de medidor
						
						If	MsgNoYes(STR0028)	//"O valor informado é inferior ao seu último valor de lançamento. Confirma a virada das marcações desse horimetro?"
							oModTWT:SetValue("TWT_VIRADA","1")
						Else
							Help(,, "At970VldCp",,STR0007,1,0,,,,,,{STR0029})	//"Valor da marcação inválido." ## "Para que não ocorra a virada das marcações do horimetro, o valor da sua marcação deve ser posterior ou igual à marcação anterior."
							lRet	:= .F.
						EndIf
					//ElseIf oModTWT:GetValue("TWT_MOTIVO") <> DF_HORIMETRO_MOTIVO_SAIDA .And. ;  // se o lançamento atual for diferente de Saída
					//	oModTWT:GetValue("TWT_MOTIVO",nTWTLinGrd - 1) == DF_HORIMETRO_MOTIVO_RETORNO 
					//	
					//	Help(,, "At970VldCp",,STR0007,1,0,,,,,,{STR0030})	//"Valor da marcação inválido." ## "O último lançamento da marcação do horimetro foi um 'retorno'. Portanto, somente será válido o lançamento de uma 'saída'."
					//	lRet	:= .F.
					EndIf
				Else
					nLinAuxTWT	:=	nTWTLinGrd
					While	nLinAuxTWT > 1
						oModTWT:GoLine( -- nLinAuxTWT )
						If	!( oModTWT:IsDeleted() )
							cHmAntTWT	:= oModTWT:GetValue("TWT_NUMHOR", nLinAuxTWT)
							nVlAntTWT	:= oModTWT:GetValue("TWT_VALHOR", nLinAuxTWT)
							EXIT
						EndIf
					EndDo
					If nTWTLinGrd < oModTWT:Length()
						nLinAuxTWT	:=	nTWTLinGrd
						While	nLinAuxTWT < oModTWT:Length()
							oModTWT:GoLine( ++ nLinAuxTWT )
							If	!( oModTWT:IsDeleted() )
								cHmPosTWT	:= oModTWT:GetValue("TWT_NUMHOR", nLinAuxTWT)
								nVlPosTWT	:= oModTWT:GetValue("TWT_VALHOR", nLinAuxTWT)
								EXIT
							EndIf
						EndDo
					EndIf
					If	! Empty(cHmAntTWT) .AND. ! Empty(cHmPosTWT)                 .AND.;
						( xTWTNewVlr < nVlAntTWT .OR. xTWTNewVlr > nVlPosTWT )      .AND.;
						( oModTWT:GetValue("TWT_NUMHOR", nTWTLinGrd) == cHmAntTWT ) .AND.;
						( oModTWT:GetValue("TWT_NUMHOR", nTWTLinGrd) == cHmPosTWT )
						Help(,, "At970VldCp",,STR0007,1,0,,,,,,{STR0031})	//"Valor da marcação inválido." ## "Este tipo de alteração irá gerar uma virada de horimetro. Se deseja realmente realizar esta manutenção, exclua as marcações a partir desta (inclusive), grave-as, e execute o relançamento destas marcações."
						lRet	:= .F.
					EndIf
				EndIf
			EndIf

	Case	cTWTFldName == "TWT_HMELIM"

			If	xTWTNewVlr <= 0
				Help(,, "At970VldCp",,STR0009,1,0,,,,,,{STR0032})	//"Quantidade limite de dígitos do horimetro inválido." ## "Informe uma quantidade de dígitos para o visor do horimetro válida."
				lRet	:= .F.
			Else
				nLinAuxTWT	:= nTWTLinGrd
				xAux		:= oModTWT:GetValue("TWT_NUMHOR", nTWTLinGrd)
				nLmAntTWT	:= -1
				nLmPosTWT	:= -1
				While	nLinAuxTWT > 1
					oModTWT:GoLine( -- nLinAuxTWT )
					If	!( oModTWT:IsDeleted() ) .AND. xAux == oModTWT:GetValue("TWT_NUMHOR", nLinAuxTWT)
						nLmAntTWT	:= oModTWT:GetValue("TWT_HMELIM", nLinAuxTWT)
						EXIT
					EndIf
				EndDo
				nLinAuxTWT	:=	nTWTLinGrd
				While	nLinAuxTWT < oModTWT:Length()
					oModTWT:GoLine( ++ nLinAuxTWT )
					If	!( oModTWT:IsDeleted() ) .AND. xAux == oModTWT:GetValue("TWT_NUMHOR", nLinAuxTWT)
						nLmPosTWT	:= oModTWT:GetValue("TWT_HMELIM", nLinAuxTWT)
						EXIT
					EndIf
				EndDo
				If	( nLmAntTWT <> -1 .AND. xTWTNewVlr <> nLmAntTWT ) .OR. ( nLmPosTWT <> -1 .AND. xTWTNewVlr <> nLmPosTWT )
					If MsgNoYes(STR0078+CRLF+;	//"Confirma a alteração da quantidade limite de digitos do visor do horimetro selecionado?"
					            STR0079)			//"Observação: Esta alteração será considerada em todas as marcações desse horimetro que ainda não participaram de uma medição/apuração."
						nLinAuxTWT	:=	nTWTLinGrd
						While	nLinAuxTWT > 1
							oModTWT:GoLine( -- nLinAuxTWT )
							If	!( oModTWT:IsDeleted() )
								If xAux <> oModTWT:GetValue("TWT_NUMHOR", nLinAuxTWT) .OR. ! Empty( oModTWT:GetValue("TWT_CODTFV", nLinAuxTWT) ) 
									EXIT
								EndIf
								oModTWT:LoadValue("TWT_HMELIM",xTWTNewVlr)
							EndIf
						EndDo
						nLinAuxTWT	:=	nTWTLinGrd
						While	nLinAuxTWT < oModTWT:Length()
							oModTWT:GoLine( ++ nLinAuxTWT )
							If	!( oModTWT:IsDeleted() )
								If	xAux <> oModTWT:GetValue("TWT_NUMHOR", nLinAuxTWT) .OR. ! Empty( oModTWT:GetValue("TWT_CODTFV", nLinAuxTWT) )
									EXIT
								EndIf
								oModTWT:LoadValue("TWT_HMELIM",xTWTNewVlr)
							EndIf
						EndDo
						oModTWT:SeekLine({{"TWT_NUMHOR",xAux}})
						oView:Refresh()
					EndIf
				EndIf
			EndIf

EndCase

FwRestRows( aSaveRows )
Return	lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At970VDtHr
@description  Validação da TIMELINE de lançamento das marcações do horimetro
@sample        At970VDtHr(dDtDe, cHrDe, dDtAte, cHrAte)
@param         dDtAnt:      Data do lançamento anterior na Timeline de lançamentos das marcações do horimetro
@param         cHrAnt:      Hora do lançamento anterior na Timeline de lançamentos das marcações do horimetro
@param         dDtAnalise: Data a ser analizada na Timeline de lançamentos das marcações do horimetro
@param         cHrAnalise: Hora a ser analizada na Timeline de lançamentos das marcações do horimetro
@param         dDtPos:      Data do lançamento posterior na Timeline de lançamentos das marcações do horimetro
@param         cHrPos:      Hora do lançamento posterior na Timeline de lançamentos das marcações do horimetro
@return        ExpL:        .T.=Timeline válida // .F.=Timeline inválida
@author        Alexandre da Costa (a.costa)
@since         28/07/2016
@version       P12   
/*/
//------------------------------------------------------------------------------
Static Function At970VDtHr(dDtAnt, cHrAnt, dDtAnalise, cHrAnalise, dDtPos, cHrPos)

Local lRet		:= .T.

Default	dDtAnt		:= CtoD(Space(08))
Default	cHrAnt		:= Space(08)
Default	dDtAnalise	:= dDataBase
Default	cHrAnalise	:= Time()
Default	dDtPos		:= CtoD(Space(08))
Default	cHrPos		:= Space(08)

If	! Empty(dDtAnt)
	If	dDtAnalise == dDtAnt
		If	( Val(Left(cHrAnalise,2)) < Val(Left(cHrAnt,2)) ) .OR.;
			( Val(Left(cHrAnalise,2)) == Val(Left(cHrAnt,2)) .AND.;
			  Val(Right(cHrAnalise,2)) < Val(Right(cHrAnt,2)) )
			Help(,, "At970VDtHr",,STR0004,1,0,,,,,,{STR0033})	//"Hora da marcação inválida." ## "É necessário que a hora da marcação seja posterior ao seu lançamento anterior."
			lRet	:= .F.
		EndIf
	ElseIf	dDtAnalise < dDtAnt
		Help(,, "At970VDtHr",,STR0003,1,0,,,,,,{STR0034})	//"Data da marcação inválida." ## "Data da marcação deve ser posterior ou igual à data da marcação do seu lançamento anterior."
		lRet	:= .F.
	EndIf
EndIf

If	lRet .AND. ! Empty(dDtPos)
	If	dDtAnalise == dDtPos
		If	( Val(Left(cHrAnalise,2)) > Val(Left(cHrPos,2)) ) .OR.;
			( Val(Left(cHrAnalise,2)) == Val(Left(cHrPos,2)) .AND.;
			  Val(Right(cHrAnalise,2)) > Val(Right(cHrPos,2)) )
			Help(,, "At970VDtHr",,STR0004,1,0,,,,,,{STR0035})	//"Hora da marcação inválida." ## "É necessário que a hora da marcação seja anterior ao seu lançamento posterior."
			lRet	:= .F.
		EndIf
	ElseIf	dDtAnalise > dDtPos
		Help(,, "At970VDtHr",,STR0003,1,0,,,,,,{STR0036})	//"Data da marcação inválida." ## "Data da marcação deve ser anterior ou igual à data da marcação do seu lançamento seguinte."
		lRet	:= .F.
	EndIf
EndIf

Return	lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} PrLinOkTWT
@description  Pré-validação da GRID dos lançamentos das marcações do horimetro
@sample        PrLinOkTWT(oModTWT, nTWTLinGrd, cTWTAcao, cTWTFldName)
@param         oModTWT:     Modelo ativo
@param         nTWTLinGrd:  Linha do GRID
@param         cTWTAcao:    Ação
@param         cTWTFldName: Campo
@return        ExpL:        .T.=Ação válida // .F.=Ação inválida
@author        Alexandre da Costa (a.costa)
@since         21/07/2016       
@version       P12   
/*/
//------------------------------------------------------------------------------
Static Function PrLinOkTWT(oModTWT, nTWTLinGrd, cTWTAcao, cTWTFldName)

Local aSaveLine	:= FWSaveRows()
Local nLinAuxTWT	:= nTWTLinGrd
Local nLmAtuTWT	:= 0
Local cHmAtuTWT	:= ""
Local lRet			:= .T.

If	cTWTAcao == "CANSETVALUE"

	If	! Empty(oModTWT:GetValue("TWT_CODTFV"))
		MsgStop(STR0008+" "+STR0037,"TECA970-PrLinOkTWT")	//"Operação não permitida." ## "Este lançamento já foi considerado nos cálculos de uma medição/apuração."
		lRet	:= .F.
	ElseIf	cTWTFldName <> "TWT_DSCMOT" 
		If oModTWT:GetValue("TWT_TPLCTO") == DF_HORIMETRO_TPLCTO_INTEGRADO
			MsgAlert(STR0008+" "+STR0101,"TECA970-PrLinOkTWT_INT")  // "Operação não permitida." ### "Registros integrados não podem sofrer alteração"
			lRet := .F.
		ElseIf oModTWT:GetValue("TWT_TPLCTO") <> DF_HORIMETRO_TPLCTO_ATUALIZA
			MsgAlert(STR0008+" "+STR0038,"TECA970-PrLinOkTWT")	//"Operação não permitida." ## "Para as marcações cujo tipo de lançamento é igual a 'Saída para locação' ou 'Retorno de locação', somente o campo 'Descrição do motivo' pode ser alterado."
			lRet	:= .F.
		EndIf
	EndIf

ElseIf	cTWTAcao == "DELETE"
	
	If oModTWT:GetValue("TWT_TPLCTO") == DF_HORIMETRO_TPLCTO_RETORNO
		If At970DelInt( oModTWT, oModTWT:GetLine() )
			Help(,, "AT970NODELINT",,STR0096,1,0,,,,,,{STR0097})  // "Registro lançado via integração e não pode ser excluído." ### "Exclua a informação na origem do lançamento."
			lRet := .F.
		EndIf
	Else
		If	! Empty(oModTWT:GetValue("TWT_CODTFV"))
			Help(,, "TECA970-PrLinOkTWT",,STR0008,1,0,,,,,,{STR0037})	//"Operação não permitida." ## "Este lançamento já foi considerado nos cálculos de uma medição/apuração."
			lRet	:= .F.
		ElseIf	nTWTLinGrd < oModTWT:Length()
			While	nLinAuxTWT < oModTWT:Length()
				oModTWT:GoLine( ++ nLinAuxTWT )
				If	!( oModTWT:IsDeleted() )
					Help(,, "TECA970-PrLinOkTWT",,STR0008,1,0,,,,,,{STR0040})	//"Operação não permitida." ## "A exclusão dos lançamentos das marcações deve ocorrer apenas em ordem cronologica decrescente."
					lRet	:= .F.
					EXIT
				EndIf
			EndDo
			oModTWT:GoLine(nTWTLinGrd)
		EndIf
		If	lRet
			If oModTWT:GetValue("TWT_TPLCTO") == DF_HORIMETRO_TPLCTO_SAIDA 
				If	! ( MsgNoYes(STR0089) )	//"Confirma o estorno do lançamento de 'Saída para locação' desse horimetro?"
					Help(,, "TECA970-PrLinOkTWT",,STR0087,1,0,,,,,,{STR0039})	//"Estorno do evento 'Saída para locação'" ## "Operação não confirmada. Se realmente deseja realizar esta operação, selecione novamente essa marcação e confirme o seu estorno quando for questionado a respeito desse processamento."
					lRet	:= .F.
				EndIf
			ElseIf oModTWT:GetValue("TWT_TPLCTO") == DF_HORIMETRO_TPLCTO_RETORNO 
				If	! ( MsgNoYes(STR0090) )	//"Confirma o estorno do lançamento de 'Retorno da locação' desse horimetro?"
					Help(,, "TECA970-PrLinOkTWT",,STR0088,1,0,,,,,,{STR0039})	//"Estorno do evento 'Retorno da locação'" ## "Operação não confirmada. Se realmente deseja realizar esta operação, selecione novamente essa marcação e confirme o seu estorno quando for questionado a respeito desse processamento."
					lRet	:= .F.
				EndIf
			EndIf
		EndIf
	EndIf

ElseIf	cTWTAcao == "UNDELETE"

	nLmAtuTWT	:= oModTWT:GetValue("TWT_HMELIM", nLinAuxTWT)
	cHmAtuTWT	:= oModTWT:GetValue("TWT_NUMHOR", nLinAuxTWT)
	While	nLinAuxTWT > 1
		oModTWT:GoLine( -- nLinAuxTWT )
		If	! Empty(oModTWT:GetValue("TWT_CODTFV"))
			EXIT
		EndIf
		If	oModTWT:IsDeleted()
			Help(,, "TECA970-PrLinOkTWT",,STR0008,1,0,,,,,,{STR0041})	//"Operação não permitida." ## "Execute a reativação do lançamento das marcações em ordem cronologica crescente."
			lRet	:= .F.
			EXIT
		ElseIf	oModTWT:GetValue("TWT_NUMHOR", nLinAuxTWT) == cHmAtuTWT .AND. oModTWT:GetValue("TWT_HMELIM", nLinAuxTWT) <> nLmAtuTWT
			Help(,, "TECA970-PrLinOkTWT",,STR0008,1,0,,,,,,{STR0042})	//"Operação não permitida." ## "A quantidade limite de dígitos do visor do horimetro da marcação anterior é diferente em relação à marcação que deseja reativar."
			lRet	:= .F.
			EXIT
		EndIf
	EndDo

EndIf
FWRestRows(aSaveLine)
Return lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} PsLinOkTWT
@description  Pós-validação da GRID dos lançamentos das marcações do horimetro
@sample        PsLinOkTWT(oModTWT, nTWTLinGrd)
@param         oModTWT:     Modelo ativo
@param         nTWTLinGrd:  Linha do GRID
@return        ExpL:        .T.=Ação válida // .F.=Ação inválida
@author        Alexandre da Costa (a.costa)
@since         26/07/2016       
@version       P12   
/*/
//------------------------------------------------------------------------------
Static Function PsLinOkTWT(oModTWT, nTWTLinGrd)

Local cMotivo		:= oModTWT:GetValue("TWT_MOTIVO", nTWTLinGrd)
Local cTpLcto		:= oModTWT:GetValue("TWT_TPLCTO", nTWTLinGrd)
Local cMotivoAnt	:= ""
Local nLinAuxTWT	:= 0
Local lRet			:= .T.

If	nTWTLinGrd == 1
	// lançamentos via integração podem existir em qualquer momento
	lRet := .T.
	If cTpLcto <> DF_HORIMETRO_TPLCTO_INTEGRADO
		If	cMotivo <> DF_HORIMETRO_MOTIVO_SAIDA
			Help(,, "TECA970-PsLinOkTWT",,STR0005,1,0,,,,,,{STR0016})	//"Motivo da marcação inválido." ## "O primeiro motivo de marcação do horimetro de um equipamento deve ser igual à 'Saída'."
			lRet	:= .F.
		ElseIf	cTpLcto <> DF_HORIMETRO_TPLCTO_SAIDA
			Help(,, "TECA970-PsLinOkTWT",,STR0006,1,0,,,,,,{STR0017})	//"Tipo de lançamento da marcação inválido." ## "O primeiro tipo de lançamento da marcação do horimetro de um equipamento deve ser igual à 'Saída p/Separação'. Para isso, acesse a funcionalidade de 'Horimetro -> Atualização para separação'."
			lRet	:= .F.
		EndIf
	EndIf
Else

	nLinAuxTWT	:= nTWTLinGrd
	While	nLinAuxTWT > 1
		oModTWT:GoLine( -- nLinAuxTWT )
		If	!( oModTWT:IsDeleted() )
			cMotivoAnt	:= oModTWT:GetValue("TWT_MOTIVO", nLinAuxTWT)
			EXIT
		EndIf
	EndDo
	If	cMotivoAnt == DF_HORIMETRO_MOTIVO_RETORNO .AND. ( cMotivo <> DF_HORIMETRO_MOTIVO_SAIDA .OR. cTpLcto <> DF_HORIMETRO_TPLCTO_SAIDA )
		Help(,, "TECA970-PsLinOkTWT",,STR0005,1,0,,,,,,{STR0043})	//"Motivo da marcação inválido." ## "Após o retorno de um equipamento é permitido somente o lançamento da 'Saída p/Separação' de um horimetro. Para isso, acesse a funcionalidade de 'Horimetro -> Atualização para separação'."
		lRet	:= .F.
	ElseIf ( cMotivoAnt == DF_HORIMETRO_MOTIVO_SUBST .OR. cMotivoAnt == DF_HORIMETRO_MOTIVO_QUEBRA ) .AND. cMotivo <> DF_HORIMETRO_MOTIVO_SAIDA
		Help(,, "TECA970-PsLinOkTWT",,STR0005,1,0,,,,,,{STR0044})	//"Motivo da marcação inválido." ## "É permitido somente o lançamento de saída de um novo horimetro após a substituição, quebra ou retorno do horimetro anterior do equipamento."
		lRet	:= .F.
	ElseIf	( cMotivo == DF_HORIMETRO_MOTIVO_SUBST .OR. cMotivo == DF_HORIMETRO_MOTIVO_QUEBRA ) .AND. Empty(oModTWT:GetValue("TWT_DSCMOT", nTWTLinGrd)) 
		Help(,, "TECA970-PsLinOkTWT",,STR0082,1,0,,,,,,{STR0077})	//"Descrição do motivo da marcação inválido." ## "Quando o motivo escolhido for igual a 'Substituição' ou 'Quebra', o preenchimento da 'Descrição do motivo' torna-se obrigatório. Descreva os detalhes referente ao motivo escolhido." 
		lRet	:= .F.
	EndIf

EndIf
Return lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At970Commit
@description  Efetiva a gravação do modelo.
@sample        At970Commit(oModel)
@param         oModel:    Model ativo
@return        ExpL:      .T.=Gravação com sucesso // .F.=Gravação não executada
@author        Alexandre da Costa (a.costa)
@since         05/08/2016
@version       P12
/*/
//------------------------------------------------------------------------------
Static Function At970Commit(oModel)

Local oModTWT		:= oModel:GetModel("TWTDETAIL")
Local oMdlAA3 		:= oModel:GetModel("AA3MASTER")
Local aSaveLine		:= FWSaveRows()
Local nTWTLinGrd	:= 0
Local nUltSaida		:= 0
Local nUltRetorno	:= 0
Local lConSep		:= AA3->AA3_CONSEP
Local lConRet		:= AA3->AA3_CONRET
Local lRet			:= .T.
Local nMaxLines 	:= 0
Local nRecSTP 		:= 0
Local nRecST9 		:= 0
Local cBemFil 		:= oMdlAA3:GetValue("AA3_CDBMFL")
Local cBemCod 		:= oMdlAA3:GetValue("AA3_CODBEM")
Local lIntMNT 		:= At040IsMNT( @nRecST9, oMdlAA3:GetValue("AA3_FILORI"), oMdlAA3:GetValue("AA3_NUMSER"), oMdlAA3:GetValue("AA3_CODPRO") )
Local dDtMarc 		:= Nil
Local cHrMarc 		:= Nil
Local nMarcacao 	:= Nil
Local lUltLinha 	:= .F.
Local lVirada 		:= .F.
Local lQuebra 		:= .F.
// controles de lançamentos no MNT
Local cTpLanMNT 	:= ""
Local nValAcum 		:= 0
Local nPosSTP 		:= 0
Local nDiffMarc 	:= 0
Local nValLancAcum 	:= 0
Local aLinesChanged := oModTWT:GetLinesChanged()

DbSelectArea("STP")
STP->( DbSetOrder( 1 ) ) // TP_FILIAL+TP_ORDEM+TP_PLANO+TP_CODBEM+TP_DTORIGI

Begin Transaction
nMaxLines := oModTWT:Length()

For	nTWTLinGrd := 1 to nMaxLines
	oModTWT:GoLine(nTWTLinGrd)
	If	( oModTWT:IsDeleted() ) .AND. Empty(oModTWT:GetValue("TWT_CODTFV"))
		If	oModTWT:GetValue("TWT_TPLCTO") == DF_HORIMETRO_TPLCTO_SAIDA
			lConSep	:= .F.
		ElseIf oModTWT:GetValue("TWT_TPLCTO") == DF_HORIMETRO_TPLCTO_RETORNO
			lConRet	:= .F.
		EndIf
	Else
		If	oModTWT:GetValue("TWT_TPLCTO") == DF_HORIMETRO_TPLCTO_SAIDA
			nUltSaida		:= oModTWT:GetValue("TWT_VALHOR")
			lConSep		:= .T.
			lConRet		:= .F.
		ElseIf oModTWT:GetValue("TWT_TPLCTO") == DF_HORIMETRO_TPLCTO_RETORNO
			nUltRetorno	:= oModTWT:GetValue("TWT_VALHOR")
			lConSep		:= .F.
			lConRet		:= .T.
		EndIf
	EndIf
	// verifica se o item está em condição de integração com o MNT
	If oModTWT:GetValue("TWT_TPLCTO") <> DF_HORIMETRO_TPLCTO_INTEGRADO .And. lIntMNT
		ST9->(DbGoTo(nRecST9))
		// caso o Bem esteja ativo segue com o processo
		If ST9->T9_TEMCONT = "S" .And. ST9->T9_SITBEM = "A"

			dDtMarc := oModTWT:GetValue("TWT_DTMARC")
			cHrMarc := Transform( oModTWT:GetValue("TWT_HRMARC"), "@R 99:99")
			nMarcacao := oModTWT:GetValue("TWT_VALHOR")
			// virada
			lVirada := oModTWT:GetValue("TWT_VIRADA")=="1" 
			// considera se é saída e se o anterior é quebra / substituição
			If nTWTLinGrd > 1
				lQuebra := oModTWT:GetValue("TWT_MOTIVO")=="0" .And. oModTWT:GetValue("TWT_MOTIVO", nTWTLinGrd - 1) $ "3/2" 
			Else
				lQuebra := .F.
			EndIf

			lUltLinha := ( nTWTLinGrd == nMaxLines )
			
			cTpLanMNT := If( lVirada, "V", If( lQuebra, "Q", "C" ) )

			If oModTWT:IsInserted() .And. !oModTWT:IsDeleted()
				
				If lVirada
					// avalia se o lançamento da virada está OK
					If NGCHKVIRAD( cBemCod, dDtMarc, nMarcacao, cHrMarc, 1/*nTipoCont*/, cBemFil)
						xRet := NGTRETCON( cBemCod, dDtMarc, nMarcacao, cHrMarc, 1, , .F., cTpLanMNT/*cTIPOLAN*/, cBemFil)
					Else
						lRet := .F.
					EndIf
				
				ElseIf lQuebra

					Private aIndSTW := {}
					Private cCondicao := 'T9_FILIAL == "' + cBemFil + '"'
					cCondicao += ' .And. ST9->T9_TEMCONT = "S" '
					cCondicao += ' .And. ST9->T9_SITBEM = "A" '

					FilBrowse("ST9", @aIndSTW, @cCondicao)

					// atualiza diretamente as informações do cadastro do bem - processo copiado da função A840Quebra (MNTA840)
					RecLock("ST9",.F.)
						ST9->T9_POSCONT := nMarcacao
						If dDtMarc > ST9->T9_DTULTAC 
							ST9->T9_DTULTAC := dDtMarc
						EndIf   
					ST9->(MsUnlock())
						
					//Funcao que grava o registro no STP
					NGGRAVAHIS( cBemCod, nMarcacao, ST9->T9_VARDIA, dDtMarc,;
								ST9->T9_CONTACU, ST9->T9_VIRADAS, cHrMarc, 1, cTpLanMNT )
					
					//Atualiza filhos do contador 1 e 2
					A840FILHO( cBemCod )
				Else
					If NGCHKHISTO( cBemCod, dDtMarc, nMarcacao, cHrMarc, 1,, .T., cBemFil) .And.;
						NGVALIVARD( cBemCod, nMarcacao, dDtMarc, cHrMarc, 1, .T.,, cBemFil)
						
						xRet := NGTRETCON( cBemCod, dDtMarc, nMarcacao, cHrMarc, 1, , .F., cTpLanMNT/*cTIPOLAN*/, cBemFil)
					Else
						lRet := .F.
					EndIf
				EndIf

				If !lRet
					oModel:SetErrorMessage( oModel:GetId() ,;
										"" ,;
										oModel:GetId() ,;
										"" ,;
										'AT970GRV_MNT' ,;
										i18n(STR0091,{ oModTWT:GetValue('TWT_ITEM' ) }),;  // "Problemas ao incluir marcação no Manutenção de Ativos do item [#1]."
										STR0092,;  // "Verifique se o valor pode ser inserido pelo MNT"
										"",;
										"" )
					Exit
				EndIf

			ElseIf oModTWT:IsUpdated() .And. At970PosTP( cBemFil, cBemCod, dDtMarc, cHrMarc, @nRecSTP ) .And. ;
				( aScan( aLinesChanged, oModTWT:GetLine() ) > 0 )

				STP->(DbGoTo(nRecSTP))
				// pega a diferença de contador para calcular o valor acumulado
				nDiffMarc := nMarcacao - STP->TP_POSCONT

				nValLancAcum := STP->TP_ACUMCON + nDiffMarc

				If lUltLinha 
					nValAcum := nValLancAcum // valor acumulado do contador
					nPosSTP := nMarcacao
				Else
					nValAcum := ST9->T9_CONTACU
					nPosSTP := ST9->T9_POSCONT
				EndIf
				
				// chamar as rotinas para realizar a alteração do registro
				Reclock("STP",.F.)
					STP->TP_DTLEITU 	:= dDtMarc
					STP->TP_HORA 		:= cHrMarc
					STP->TP_POSCONT 	:= nMarcacao
					STP->TP_ACUMCON 	:= nValLancAcum
					// trata as situações em que acontece alteração do tipo de lançamento
					If lVirada .And. STP->TP_TIPOLAN <> "V"
						STP->TP_TIPOLAN := "V"
					ElseIf lQuebra .And. STP->TP_TIPOLAN <> "Q"
						STP->TP_TIPOLAN := "Q"
					ElseIf !lQuebra .And. !lVirada .And. STP->TP_TIPOLAN $ "Q/V"
						STP->TP_TIPOLAN := "C"
					EndIf
				STP->(MsUnLock())

				// chama função para ajustar as demais informações relacionadas
				NGATUCONT( cBemCod, dDtMarc, nPosSTP, nValAcum,;
							ST9->T9_VARDIA, 1/*tipoContador*/, lVirada, .F.,;
							cBemFil )
				
				NGRECALHIS( cBemCod, nDiffMarc, nPosSTP, dDtMarc,;
							1/*tipoContador*/, .F./*lSKIP*/, lVirada, .T.,;
							/*nACUMEX*/, cBemFil, cBemFil )

				lRet := .T.

			ElseIf oModTWT:IsDeleted() .And. At970PosTP( cBemFil, cBemCod, dDtMarc, cHrMarc, @nRecSTP )
				// Posiciona na marcação do contador para realizar a exclusão do registro
				STP->(DbGoTo(nRecSTP))
				// Exclui o registro no banco de dados
				lRet := MNT470EXCO( cBemCod, dDtMarc, cHrMarc, 1/*nTIPCON*/)
			EndIf
		EndIf
	EndIf
Next nTWTLinGrd
FWRestRows(aSaveLine)

If	( lRet := lRet .And. FWFormCommit(oModel) )
	AA3->(RecLock("AA3",.F.))
	AA3->AA3_HMESEP	:= nUltSaida
	AA3->AA3_CONSEP	:= lConSep
	AA3->AA3_HMERET	:= nUltRetorno
	AA3->AA3_CONRET	:= lConRet
	AA3->(MsUnLock())
EndIf

If !lRet
	DisarmTransaction()
EndIf
End Transaction

Return lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At970VldFt
@description  Verifica se algum item do pedido se refere a um equipamento de locação existente em um orçamento de serviços do
                módulo de Gestão de Serviços possui como tipo e modalidade de cobrança pelo serviço a ser prestado configurados
                com a utilização de horimetro. Caso afirmativo, será verificado se o valor de marcação do seu horimetro encontra-se
                devidamente atualizado. Caso seja constatada a falta da sua atualização, não será permitida a geração do documento
                de saída. Se o pedido não for encontrado na base de dados do módulo de Gestão de Serviços, ou não forem identificados
                itens (equipamentos) com essa configuração, a geração do documento fiscal ocorrerá normalmente.
@sample        At970VldFt(cNumPV)
@param         cNumPV:    Número do pedido de venda
@return        ExpL:      .T.=É permitida a geração do documento de saída do pedido de remessa //
                            .F.=Não é permitida a geração do documento de saída do pedido de remessa
@author        Alexandre da Costa (a.costa)
@since         15/07/2016
@version       P12
/*/
//------------------------------------------------------------------------------
Function At970VldFt(cNumPV)

Local	aOldArea	:= GetArea()
Local	aOldSC6	:= SC6->(GetArea())
Local	aOldTEW	:= TEW->(GetArea())
Local	cFilTEW	:= xFilial("TEW")
Local	cFilSC6	:= xFilial("SC6")
Local	cMsgLog	:= ""
Local	lRet		:= .T.

TEW->(dBSetOrder(4))	//TEW_FILIAL+TEW_NUMPED+TEW_ITEMPV
If	TEW->(dBSeek(cFilTEW+cNumPV)) .AND. SC6->(dBSeek(cFilSC6+cNumPV))
	cMsgLog := STR0049+" "			//"Esse pedido foi gerado a partir do módulo de Gestão de Serviços. Nele, existem equipamentos para locação com cobrança a ser gerada a partir dos valores de marcação do seu horimetro."
	cMsgLog += STR0050+" "			//"Foi constatado que o valor de saída do horimetro de um ou mais dos equipamentos desse pedido não foi atualizado até o momento. Portanto, realize a atualização dessa informação."
	cMsgLog += STR0051+CRLF			//"Acesse o cadastro das bases de atendimento do módulo de Gestão de Serviços, localize o equipamento desejado, e atualize o valor de saida do seu horimetro."
	cMsgLog += STR0052+CRLF+CRLF	//"A preparação do documento de saída desse pedido de remessa somente será permitida após a atualização do valor de saída do horimetro de seus equipamentos."
	While SC6->(! EOF() ) .AND. SC6->C6_FILIAL == cFilSC6 .AND. SC6->C6_NUM == cNumPV
		If !( At970ChkHr(DF_HORIMETRO_FASE_SEPARACAO /*cFase*/,;
		                 SC6->C6_NUM /*cNumPV*/,;
		                 SC6->C6_ITEM /*cItemPV*/,;
		                 /*cOrcSer*/,;
		                 /*cCodMV*/,;
		                 /*cCodEqu*/,;
		                 /*cProdut*/,;
		                 /*cBaAtd*/,;
		                 .F. /*lExibeMsg*/) )
			lRet		:= .F.
			cMsgLog	+= "- "+STR0046+" "+AllTrim(SC6->C6_PRODUTO)+CRLF+;		//"Produto:"
			       	   "  "+STR0047+" "+AllTrim(SC6->C6_DESCRI)+CRLF+;		//"Descrição:"
			       	   "  "+STR0048+" "+AlLTrim(SC6->C6_NUMSERI)+CRLF+CRLF	//"Identificação:"
		EndIf
		SC6->(dBSkip())
	EndDo
EndIf
If	!lRet
	AtShowLog(cMsgLog/*<cMemoLog>*/,;
	          STR0045/*<cTitle>*/,; //"Verificação da atualização do horimetro"
	          .T./*<lVScroll>*/,;
	          .F./*<lHScroll>*/,;
	          .T./*<lWrdWrap>*/)
EndIf

RestArea(aOldTEW)
RestArea(aOldSC6)
RestArea(aOldArea)
Return	lRet


//-----------------------------------------------------------------------------------------------
/*/{Protheus.doc} At970ChkHr
@description  Verifica se o horimetro de uma base de atendimento está devidamente atualizado.
@sample        At970ChkHr(cFase, cNumPV, cItemPV, cOrcSer, cCodMV, cCodEqu, cProdut, cBaAtd, lExibeMsg)
@param         cFase:      "SEP" = Fase de separação do equipamento // "RET" = Fase de retorno do equipamento
@param         cNumPV:     Número do pedido de venda. Esta informação existirá apenas para os equipamentos que exigirem a emissão da NF de saída.
@param         cItemPV:    Item do pedido de venda. Esta informação existirá apenas para os equipamentos que exigirem a emissão da NF de saída.
@param         cOrcSer:    Número do Orçamento de serviços. Esta informação existirá apenas para os equipamentos que não exigirem a emissão da NF de saída.
@param         cCodMV:     Código do movimento. Esta informação existirá apenas para os equipamentos que não exigirem a emissão da NF de saída.
@param         cCodEqu:    Código do equipamento. Esta informação existirá apenas para os equipamentos que não exigirem a emissão da NF de saída.
@param         cProdut:    Código do produto. Esta informação existirá apenas para os equipamentos que não exigirem a emissão da NF de saída.
@param         cBaAtd:     Código da base de atendimento. Esta informação existirá apenas para os equipamentos que não exigirem a emissão da NF de saída.
@param         lExibeMsg: .T.=Exibe mensagem de orientação padrão da função //
                             .F.=Não exibe a mensagem de orientação padrão da função. A mensagem deverá ser tratada pela função chamadora. 
@return        ExpL:       .T.=Horimetro da base de atendimento está atualizado //
                             .F.=Horimetro da base de atendimento não está atualizado
@author        Alexandre da Costa (a.costa)
@since         13/07/2016
@version       P12
/*/
//-----------------------------------------------------------------------------------------------
Function At970ChkHr(cFase, cNumPV, cItemPV, cOrcSer, cCodMV, cCodEqu, cProdut, cBaAtd, lExibeMsg)

Local aOldArea	:= GetArea()
Local cAliasQry	:= GetNextAlias()
Local cCondSQL	:= ""
Local cMensagem	:= ""
Local nTamHMESEP	:= TamSX3("AA3_HMESEP")[1] //Tamanho do campo
Local nDecHMESEP	:= TamSX3("AA3_HMESEP")[2] //decimal do campo
Local nTamHMERET	:= TamSX3("AA3_HMERET")[1] //Tamanho do campo
Local nDecHMERET	:= TamSX3("AA3_HMERET")[2] //decimal do campo
Local lA460Avalia	:= IsInCallStack("A460Avalia")
Local lA460VerPRS	:= IsInCallStack("A460VERPRS")
Local lA460Msg	:= .T.
Local lExigeNF	:= .T.
Local lRet			:= .T.

Default cFase		:= DF_HORIMETRO_FASE_SEPARACAO

If	Empty(cNumPV) .AND. Empty(cItemPV)
	Default cOrcSer	:= TEW->TEW_ORCSER
	Default cCodMV	:= TEW->TEW_CODMV
	Default cCodEqu	:= TEW->TEW_CODEQU
	Default cProdut	:= TEW->TEW_PRODUT
	Default cBaAtd	:= TEW->TEW_BAATD
Else
	Default cOrcSer	:= ""
	Default cCodMV	:= ""
	Default cCodEqu	:= ""
	Default cProdut	:= ""
	Default cBaAtd	:= ""
EndIf
Default lExibeMsg	:= .T.

cCondSQL	:=	"%"
If	Empty(cNumPV) .AND. Empty(cItemPV)
	cCondSQL	+=	"TEW.TEW_ORCSER = '"+cOrcSer+"' AND "+;
					"TEW.TEW_CODMV = '"+cCodMV+"' AND "+;
					"TEW.TEW_CODEQU = '"+cCodEqu+"' AND "+;
					"TEW.TEW_PRODUT = '"+cProdut+"' AND "+;
					"TEW.TEW_BAATD = '"+cBaAtd+"' "
	lExigeNF	:= .F.
Else
	cCondSQL	+=	"TEW.TEW_NUMPED = '"+cNumPV+"' AND "+;
					"TEW.TEW_ITEMPV = '"+cItemPV+"'"
	lExigeNF	:= .T.
EndIf
cCondSQL	+=	"%"

If	! lA460VerPRS
	If	lA460Avalia
		If	cPVA460Ava == cNumPV .AND. cItPVA460Ava == cItemPV
			lA460Msg		:= .F.
			cPVA460Ava		:= ""
			cItPVA460Ava	:= ""
		Else
			lA460Msg		:= .T.
			cPVA460Ava		:= cNumPV
			cItPVA460Ava	:= cItemPV
		EndIf
	EndIf

	BeginSql Alias cAliasQry
		
	   COLUMN AA3_CONSEP AS LOGICAL
	   COLUMN AA3_CONRET AS LOGICAL
	   COLUMN AA3_HMESEP AS NUMERIC(nTamHMESEP, nDecHMESEP)
	   COLUMN AA3_HMERET AS NUMERIC(nTamHMERET, nDecHMERET)
		   
	   SELECT TEW.TEW_NUMPED, TEW.TEW_ITEMPV, TEW.TEW_CODEQU, TEW.TEW_PRODUT,
	          TEW.TEW_BAATD,  TEV.TEV_CODLOC, TEV.TEV_ITEM,   AA3.AA3_CONSEP, 
	          AA3.AA3_CONRET, AA3.AA3_HMESEP, AA3.AA3_HMERET, TFI.TFI_TPCOBR,
	          TEV.TEV_MODCOB, SB1.B1_DESC 
	     FROM %table:TEW% TEW
	          INNER JOIN %table:TFI% TFI ON TFI.TFI_FILIAL = %xFilial:TFI%
	                                    AND TFI.%NotDel%
	                                    AND TFI.TFI_COD = TEW.TEW_CODEQU
	                                    AND TFI.TFI_PRODUT = TEW.TEW_PRODUT
	                                    AND TFI.TFI_TPCOBR = '2' 
	          INNER JOIN %table:TEV% TEV ON TEV.TEV_FILIAL = %xFilial:TEV%
	                                    AND TEV.%NotDel%
	                                    AND TEV.TEV_CODLOC = TFI.TFI_COD
	                                    AND TEV.TEV_ITEM = TFI.TFI_ITEM
	                                    AND TEV.TEV_MODCOB = '4' 
	          INNER JOIN %table:AA3% AA3 ON AA3.AA3_FILIAL = %xFilial:AA3%
	                                    AND AA3.%NotDel%
	                                    AND AA3.AA3_CODPRO = TEW.TEW_PRODUT
	                                    AND AA3.AA3_NUMSER = TEW.TEW_BAATD
	          INNER JOIN %table:SB1% SB1 ON SB1.B1_FILIAL = %xFilial:SB1%
	                                    AND SB1.%NotDel%
	                                    AND SB1.B1_COD = TEW.TEW_PRODUT
	    WHERE TEW.TEW_FILIAL = %xFilial:TEW%
	      AND TEW.%NotDel%
	      AND %Exp:cCondSQL%
	EndSql

	If	(cAliasQry)->(! EOF()) .AND. (cAliasQry)->TFI_TPCOBR == "2" .AND. (cAliasQry)->TEV_MODCOB == "4" //Tipo de cobrança = HORIMETRO e Modo de cobrança = HORIMETRO

		If	cFase == DF_HORIMETRO_FASE_SEPARACAO	//Fase da SEPARAÇÃO do equipamento

			If	! ( lRet := (cAliasQry)->AA3_CONSEP )

				If	lExibeMsg .AND. lA460Msg
					cMensagem := STR0053+CRLF+CRLF+;											//"O valor de saída do horimetro da base de atendimento não está atualizado."
					             STR0046+" "+AllTrim((cAliasQry)->TEW_PRODUT)+CRLF+;		//"Produto:"
					             STR0047+" "+AllTrim((cAliasQry)->B1_DESC)+CRLF+;			//"Descrição:"
					             STR0048+" "+AlLTrim((cAliasQry)->TEW_BAATD)+CRLF+CRLF+;	//"Identificação:"
					             STR0051+CRLF													//"Acesse o cadastro das bases de atendimento do módulo de Gestão de Serviços, localize o equipamento desejado, e atualize o valor de saida do seu horimetro."
					cMensagem += If(lExigeNF,;
					                STR0054,;	//"A preparação do documento de saída desse equipamento somente será permitida após a atualização do valor de saída do seu horimetro."
					                STR0055)		//"A liberação para a locação referente a esse equipamento somente será permitida após a atualização do valor de saída do seu horimetro."
					MsgStop(cMensagem)
				EndIf

			EndIf

		Else

			If	! ( lRet := (cAliasQry)->AA3_CONRET )

				If	lExibeMsg
					cMensagem := STR0083+CRLF+CRLF+;											//"O valor de retorno do horimetro da base de atendimento não está atualizado."
					             STR0046+" "+AllTrim((cAliasQry)->TEW_PRODUT)+CRLF+;		//"Produto:"
					             STR0047+" "+AllTrim((cAliasQry)->B1_DESC)+CRLF+;			//"Descrição:"
					             STR0048+" "+AlLTrim((cAliasQry)->TEW_BAATD)+CRLF+CRLF+;	//"Identificação:"
					             STR0084+CRLF													//"Acesse o cadastro das bases de atendimento do módulo de Gestão de Serviços, localize o equipamento desejado, e atualize o valor de retorno do seu horimetro."
					cMensagem += If(lExigeNF,;
					                STR0085,;	//"A preparação do documento de entrada desse equipamento somente será permitida após a atualização do valor de retorno do seu horimetro."
					                STR0086)		//"A liberação para o retorno referente a esse equipamento somente será permitida após a atualização do valor de retorno do seu horimetro."
					MsgStop(cMensagem)
				EndIf

			EndIf

		EndIf

	EndIf

	(cAliasQry)->(DbCloseArea())
EndIf
RestArea(aOldArea)
Return lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At970PVTEW
@description  Verifica se o pedido de venda está associado a um processo de locação do Gestão de Serviços
@sample        At970PVTEW(cNumPV, cItemPV)
@param         cNumPV:    Número do pedido de venda
@param         cItemPV:   Item do pedido de venda
@return        ExpL:      .T.=Pedido de venda pertence a um processo de locação do Gestão de Serviços //
                            .F.=Pedido de venda não pertence a um processo de locação do Gestão de Serviços
@author        Alexandre da Costa (a.costa)
@since         18/07/2016
@version       P12
/*/
//------------------------------------------------------------------------------
Function At970PVTEW(cNumPV, cItemPV)

Local aOldArea	:= GetArea()
Local aOldTEW		:= TEW->(GetArea())
Local lRet			:= .T.

TEW->(dBSetOrder(4)) //TEW_FILIAL+TEW_NUMPED+TEW_ITEMPV
lRet	:= TEW->(dBSeek(xFilial("TEW")+cNumPV+cItemPV))

RestArea(aOldTEW)
RestArea(aOldArea)
Return lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At970AtSep
@description  Atualiza a marcação de saída do horimetro
@sample        At970AtSep()
@param         Nenhum
@return        Nil
@author        Alexandre da Costa (a.costa)
@since         20/07/2016
@version       P12
/*/
//------------------------------------------------------------------------------
Function At970AtSep()

Local lRet := At970AtHor(DF_HORIMETRO_FASE_SEPARACAO,;
           AA3->AA3_CODPRO,;
           Posicione("SB1",1,xFilial("SB1")+AA3->AA3_CODPRO,"B1_DESC"),;
           AA3->AA3_NUMSER,;
		   AA3->AA3_FILORI)
Return lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At970AtRet
@description  Atualiza a marcação de retorno do horimetro
@sample        At970AtRet()
@param         Nenhum
@return        Nil
@author        Alexandre da Costa (a.costa)
@since         20/07/2016
@version       P12
/*/
//------------------------------------------------------------------------------
Function At970AtRet()

Local lRet := At970AtHor(DF_HORIMETRO_FASE_RETORNO,;
           AA3->AA3_CODPRO,;
           Posicione("SB1",1,xFilial("SB1")+AA3->AA3_CODPRO,"B1_DESC"),;
           AA3->AA3_NUMSER,;
		   AA3->AA3_FILORI)
Return lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At970AtHor
@description  Realiza o lançamento do valor da marcação de "SAÌDA" ou "RETORNO" para as fases de SEPARAÇÃO / RETORNO,
                respectivamente, do equipamento que possui o controle de horimetro.
@sample        At970AtHor(cFase, cCodPro, cDescPro, cIDUnico)
@param         cFase:    Fase de atualização do horimetro ("SEP"=Separação, "RET"=Retorno)
@param         cCodPro:  Código do produto
@param         cDescPro: Descrição do produto
@param         cIDUnico: ID único da base de atendimento
@param         cFilOri: Filial de origem e dona do equipamento
@return        ExpL:     .T.=Fase do horimetro atualizada // .F.=Fase do horimetro não atualizada
@author        Alexandre da Costa (a.costa)
@since         19/07/2016
@version       P12
/*/
//------------------------------------------------------------------------------
Function At970AtHor(cFase, cCodPro, cDescPro, cIDUnico, cFilOri )

Local aOldArea		:= GetArea()
Local aOldAA3		:= AA3->(GetArea())
Local aOldSX3		:= SX3->(GetArea())
Local aMotivo		:= {}
Local aInfoHorim	:= {}
Local cPctProdut	:= X3Picture("TEW_PRODUT")
Local cPctDescri	:= X3Picture("B1_DESC")
Local cPctIDUnic	:= X3Picture("TEW_BAATD")
Local cPctNumHor	:= X3Picture("TWT_NUMHOR")
Local cPctItem		:= X3Picture("TWT_ITEM")
Local cPctValHor	:= X3Picture("TWT_VALHOR")
Local cPctHmeLim	:= X3Picture("TWT_HMELIM")
Local cNumHor		:= ""
Local cItem			:= ""
Local cTitCompl		:= ""
Local cUltMotivo	:= ""
Local cCodMV		:= ""
Local nTamNumHor	:= TamSX3("TWT_NUMHOR")[1]
Local nTamItem		:= TamSX3("TWT_ITEM")[1]
Local nUltValHor	:= 0
Local nValHorim		:= 0
Local oValHorim 	:= Nil
Local nHMELimite	:= 0
LOcal oHMELimite 	:= Nil
Local nLinDLG		:= 0
Local oDlg			:= NIL
Local oButOk		:= NIL
Local oButCanc		:= NIL
Local lVirada		:= .F.
Local lRet			:= .F.

Default cFase		:= DF_HORIMETRO_FASE_SEPARACAO
Default cCodPro		:= Space(TamSX3("B1_COD")[1])
Default cDescPro	:= Space(TamSX3("B1_DESC")[1])
Default cIDUnico	:= Space(TamSX3("TWT_CODAA3")[1])
Default cFilOri 	:= ""

If	( lRet := ( ( cFase == DF_HORIMETRO_FASE_SEPARACAO .OR. cFase == DF_HORIMETRO_FASE_RETORNO ) .AND.;
	            ! Empty(cCodPro)                                                                 .AND.;
	            ! Empty(cDescPro)                                                                .AND.;
	            ! Empty(cIDUnico) ) )
				 

	TWT->(dBSetOrder(1))	//TWT_FILIAL+TWT_CODAA3+TWT_ITEM+TWT_NUMHOR
	AA3->(dBSetOrder(6))	//AA3_FILIAL+AA3_NUMSER
	// se o AA3_FILORI for passado utiliza como referência para posicionar no item
	If Empty( cFilOri ) 
		lRet := AA3->(DbSeek(xFilial("AA3")+cIDUnico))
		cFilOri := AA3->AA3_FILORI
	Else
		lRet := AtPosAA3( cFilOri+cIDUnico, cCodPro )
	EndIf

	If lRet

		If	AA3->AA3_HMEATV <> "1"	// O uso do horimetro para a base de atendimento está configurado?
			Help(,, "At970AtHor1",,STR0002,1,0,,,,,,{STR0010})	//"Ação não permitida." ## "A base de atendimento selecionada não está utilizando horimetro. Para utilizar esta funcionalidade, ative o uso do horimetro da base de atendimento."
			lRet	:= .F.
		ElseIf	AA3->AA3_HMELIM == 0	// A quantidade limite de dígitos do horimetro para a base de atendimento está configurada?
			Help(,, "At970AtHor2",,STR0002,1,0,,,,,,{STR0011})	//"Ação não permitida." ## "A base de atendimento não está com o limite de dígitos do horimetro configurado. Para utilizar esta funcionalidade, configure o limite de dígitos do visor do horimetro ativo da base de atendimento."
			lRet	:= .F.
		ElseIf	cFase == DF_HORIMETRO_FASE_SEPARACAO .AND. AA3->AA3_CONSEP
			Help(,, "At970AtHor3",,STR0002,1,0,,,,,,{STR0056})	//"Ação não permitida." ## "Não é permitido realizar nova atualização para separação do equipamento, pois a mesma já ocorreu."
			lRet	:= .F.
		ElseIf	cFase == DF_HORIMETRO_FASE_RETORNO .AND. AA3->AA3_CONRET
			Help(,, "At970AtHor4",,STR0002,1,0,,,,,,{STR0057})	//"Ação não permitida." ## "Não é permitido realizar nova atualização para retorno do equipamento, pois a mesma já ocorreu."
			lRet	:= .F.
		EndIf

		If	lRet

			aInfoHorim	:= At970UltHrm(cIDUnico)
			cNumHor		:= If(Empty(aInfoHorim[01]),                StrZero(1,nTamNumHor), aInfoHorim[01])
			cItem		:= If(Empty(aInfoHorim[02]),                StrZero(0,nTamItem),   aInfoHorim[02])
			cCodMV		:= If(cFase == DF_HORIMETRO_FASE_SEPARACAO, At970GetMV(cFilOri,cIdUnico),  aInfoHorim[03])	// Busca o código da movimentação ao qual a marcação de 'SAÍDA' / 'RETORNO' do horimetro estará associada.
			nHMELimite	:= If(Empty(aInfoHorim[04]),                AA3->AA3_HMELIM,       aInfoHorim[04])
			If	! ( Empty(cNumHor) .AND. Empty(cItem) )
				TWT->(dBSeek(xFilial("TWT")+cIDUnico+cItem+cNumHor))
				cUltMotivo	:= TWT->TWT_MOTIVO
				nUltValHor	:= TWT->TWT_VALHOR
			EndIf
			nValHorim	:= nUltValHor

			If	cFase == DF_HORIMETRO_FASE_RETORNO .AND. ( cUltMotivo == DF_HORIMETRO_MOTIVO_SUBST .OR. cUltMotivo == DF_HORIMETRO_MOTIVO_QUEBRA )
				Help(,, "At970AtHor5",,STR0002+" "+STR0058,1,0,,,,,,{STR0059})	//"Ação não permitida." ## "O último lançamento do valor de marcação do horimetro deste equipamento refere-se a uma substituição ou quebra." ## "Antes de lançar o valor da marcação de retorno, acesse a funcionalidade 'Lançamento das marcações' e informe o valor da marcação de saída do novo horimetro que substituiu o horimetro anterior do equipamento." 
				lRet	:= .F.
			ElseIf Empty(cCodMV)
				Help(,, "At970AtHor6",,STR0002+" "+STR0060,1,0,,,,,,{STR0061})	//"Ação não permitida." ## "Não foi encontrado um código da movimentação válido para associá-lo ao lançamento da marcação do horimetro." ## "Para realizar o lançamento de uma marcação de 'SAÍDA' ou 'RETORNO' de um horimetro, é necessário que exista um código de movimentação ativo para a base de atendimento (equipamento)."
				lRet	:= .F.
			EndIf

			If	lRet
				nLinDLG	:= 5
				cTitCompl	:= If(cFase == DF_HORIMETRO_FASE_SEPARACAO, STR0062, STR0063)	//"Separação" ## "Retorno"
				aMotivo	:= Separa(Posicione("SX3",2,"TWT_MOTIVO","X3CBox()"),";",.T.)
				lRet		:= .F.

				Define Dialog oDlg Title STR0001+" - "+cTitCompl From 00,00 to 310,460 Pixel	//"Atualização do horimetro"
				@ nLinDLG,        005 Say STR0064                                                                                            Of oDlg Pixel	//"Produto"
				@ nLinDLG,        050 MsGet cCodPro    Picture cPctProdut              When .F.                                              Of oDlg Pixel
				@ (nLinDLG += 15),005 Say STR0065                                                                                            Of oDlg Pixel	//"Descrição"
				@ nLinDLG,        050 MsGet cDescPro   Picture cPctDescri              When .F.                                              Of oDlg Pixel
				@ (nLinDLG += 15),005 Say STR0066                                                                                            Of oDlg Pixel	//"ID.Único"
				@ nLinDLG,        050 MsGet cIDUnico   Picture cPctIDUnic              When .F.                                              Of oDlg Pixel
				@ (nLinDLG += 15),005 Say STR0067                                                                                            Of oDlg Pixel	//"No.Horimetro"
				@ nLinDLG,        050 MsGet cNumHor    Picture cPctNumHor              When .F.                                              Of oDlg Pixel
				@ (nLinDLG += 15),005 Say STR0068                                                                                            Of oDlg Pixel	//"Item"
				@ nLinDLG,        050 MsGet cItem      Picture cPctItem                When .F.                                              Of oDlg Pixel 
				@ (nLinDLG += 15),005 Say STR0069                                                                                            Of oDlg Pixel	//"Ult.Marcação"
				@ nLinDLG,        050 MsGet nUltValHor Picture cPctValHor              When .F.                                              Of oDlg Pixel 
				@ (nLinDLG += 15),005 Say STR0070                                                                                            Of oDlg Pixel	//"Ult.Motivo"
				@ nLinDLG,        050 ComboBox oUltMotivo Var cUltMotivo Items aMotivo When .F. Size 100,10                                  Of oDlg Pixel 
				@ (nLinDLG += 15),005 Say STR0073                                                                                            Of oDlg Pixel	//"Limite dígitos"
				@ nLinDLG,        050 MsGet oHMELimite Var nHMELimite Picture cPctHmeLim Valid ( At970IsPos( nHMELimite ) ) When (cFase == DF_HORIMETRO_FASE_SEPARACAO) Of oDlg Pixel
				@ (nLinDLG += 15),005 Say IIf( cFase == DF_HORIMETRO_FASE_SEPARACAO, STR0071, STR0072 )                                      Of oDlg Pixel	//"Vlr.Saída (SEP)" ## "Vlr.Retorno (RET)"
				@ nLinDLG,        050 MsGet oValHorim Var nValHorim  Picture cPctValHor Valid At970VlHor(nUltValHor, nValHorim, .F., @lVirada, nHMELimite) Of oDlg Pixel
				oDlg:Refresh()
				Define SButton oButOk   From (nLinDLG += 15),175 Type 1 Action ( oDlg:End(), lRet := At970VlHor(nUltValHor, nValHorim, .T., @lVirada, nHMELimite) .AND. nHMELimite > 0 ) Enable Of oDlg
				Define SButton oButCanc From nLinDLG,        203 Type 2 Action ( oDlg:End(), lRet := .F. )                                                                               Enable Of oDlg
				Activate Dialog oDlg Centered

				If	lRet
					// executa a função para a gravação dos dados
					lRet := At970Gv1( cFase, Soma1(cItem), cNumHor, lVirada, ;
								dDataBase, Left(StrTran(Time(),":",""),4), nValHorim, nHMELimite, ;
								cCodMV )

				EndIf
			EndIf
		EndIf
	EndIf
EndIf
RestArea(aOldSX3)
RestArea(aOldAA3)
RestArea(aOldArea)
Return( lRet )


//------------------------------------------------------------------------------
/*/{Protheus.doc} At970GetMV
@description  Busca o código do movimento da separação do equipamento (base de atendimento)
@sample        At970GetMV(cIdUnico)
@param         cFilOri: Identificação da filial dona do equipamento
@param         cIDUnico: ID único da base de atendimento
@return        ExpC:     Código do movimento da separação do equipamento (base de atendimento)
@author        Alexandre da Costa (a.costa)
@since         27/07/2016
@version       P12
/*/
//------------------------------------------------------------------------------
Static Function At970GetMV( cFilOri, cIdUnico )

Local aOldArea		:= GetArea()
Local cAliasQry		:= GetNextAlias()
Local cRet			:= ""

Default cFilOri 	:= AA3->AA3_FILORI
Default cIDUnico	:= AA3->AA3_NUMSER

BeginSql Alias cAliasQry

   SELECT TEW.TEW_CODMV
     FROM %table:TEW% TEW
    WHERE TEW.TEW_BAATD = %Exp:cIDUnico%
	  AND TEW.TEW_FILBAT = %Exp:cFilOri%
      AND TEW.TEW_DTSEPA <> ' '
      AND TEW.TEW_DTRFIM = ' ' 
      AND TEW.TEW_TIPO IN ('1',' ')
	  AND TEW.%NotDel%

EndSql

If	(cAliasQry)->(! EOF())
	cRet := (cAliasQry)->TEW_CODMV
EndIf
(cAliasQry)->(DbCloseArea())
RestArea(aOldArea)
Return cRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At970VlHor
@description  Valida os valores de marcação do horimetro lançados na tela de atualização das marcações de SAÍDA / RETORNO
@sample        At970VlHor(nUltValHor, nValHorim, lOkTela, lVirada)
@param         nUltValHor: Último valor de marcação válido para o horimetro
@param         nValHorim:  Novo valor de marcação para o horimetro
@param         lOkTela:    .T.=A validação está ocorrendo no "OK" da tela de atualização do horimetro //
                             .F.=A validação está ocorrendo no momento do "GET"
@param         lVirada:    .T.=Ocorreu a virada de marcação do mesmo horimetro //
                             .F.=Não ocorreu a virada de marcação do mesmo horimetro
@param         nHMELimite: Valor limite do visor do horimetro                    
@return        ExpL:        .T.=Valor de marcação do horimetro informado é válido //
                              .F.=Valor de marcação do horimetro informado é inválido
@author        Alexandre da Costa (a.costa)
@since         18/07/2016
@version       P12
/*/
//------------------------------------------------------------------------------
Static Function At970VlHor(nUltValHor, nValHorim, lOkTela, lVirada, nHMELimite)

Local nVlMaxHor	:= Val(Replicate("9",nHMELimite))
Local cMsg			:= ""
Local lRet			:= .T.
Local lStopMsg	:= .F.
Local lAlertMsg	:= .F.

If	nUltValHor < 0 .OR. nValHorim < 0
	cMsg		:= STR0074	//"Não é permitido o lançamento de um valor negativo de marcação do horimetro."
	lRet		:= .F.
	lStopMsg	:= .T.
ElseIf	nValHorim > nVlMaxHor
	cMsg		:= STR0027	//"O valor de marcação informado ultrapassa o limite do visor do horimetro."
	lRet		:= .F.
	lStopMsg	:= .T.
ElseIf nValHorim < nUltValHor
	If !( lVirada	:=	MsgNoYes(STR0028) )	//"O valor informado é inferior ao seu último valor de lançamento. Confirma a virada das marcações desse horimetro?"
		cMsg		:= STR0075	//"Não foi confirmada a virada do horimetro para que seja aceito um valor de marcação inferior ao seu último lançamento." 
		lRet		:= .F.
		lAlertMsg	:= .T.
	EndIf
ElseIf lOkTela .AND. nUltValHor == nValHorim
	lRet	:=	MsgYesNo(STR0076)	//"O novo valor de marcação do horimetro é igual ao seu último valor de lançamento. Confirma?"
EndIf

If	! Empty(cMsg)
	If	lStopMsg
		cMsg	:= STR0007 + CRLF + cMsg	//"Valor da marcação inválido."
		MsgStop(cMsg, "At970VlHor")
	EndIf
	If	lAlertMsg
		MsgAlert(cMsg, "At970VlHor")
	EndIf
EndIf
Return lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At970UltHrm
@description  Busca o último item do horimetro em utilização que está associado à Base de atendimento, excluindo os horimetros substituidos/quebrados
@sample        At970UltHrm(cIDUnico)
@param         cIDUnico:   ID único da base de atendimento
@return        ExpA:        Onde, ExpA[01] = Número do horimetro ativo para a base de atendimento e ExpA[02] = Item da marcação
@author        Alexandre da Costa (a.costa)
@since         18/07/2016
@version       P12
/*/
//------------------------------------------------------------------------------
Function At970UltHrm(cIDUnico)

Local aOldArea	:= GetArea()
Local cAliasQry	:= GetNextAlias()
Local nTamNumHor	:= TamSX3("TWT_NUMHOR")[1]
Local nTamItem	:= TamSX3("TWT_ITEM")[1]
Local nTamCodMV	:= TamSX3("TWT_CODMV")[1]
Local nTamHMELIM	:= TamSX3("TWT_HMELIM")[1]
Local nDecHMELIM	:= TamSX3("TWT_HMELIM")[2]
Local aRet			:= {Space(nTamNumHor), Space(nTamItem), Space(nTamCodMV), 0}

Default cIDUnico := TWT->TWT_CODAA3

BeginSql Alias cAliasQry

   COLUMN TWT_HMELIM AS NUMERIC(nTamHMELIM, nDecHMELIM)

   SELECT MAX(TWT.TWT_NUMHOR) TWT_NUMHOR, MAX(TWT.TWT_ITEM) TWT_ITEM, TWT.TWT_CODMV, TWT.TWT_HMELIM
     FROM %table:TWT% TWT
   WHERE TWT.TWT_FILIAL = %xFilial:TWT%
      AND TWT.TWT_CODAA3 = %Exp:cIDUnico%
      AND TWT.TWT_MOTIVO IN ('0','1','9')
      AND TWT.%NotDel%
      AND TWT.TWT_NUMHOR NOT IN (SELECT DISTINCT TWTTMP.TWT_NUMHOR
                                  FROM %table:TWT% TWTTMP
                                  WHERE TWTTMP.TWT_FILIAL = %xFilial:TWT%
                                    AND TWTTMP.%NotDel%
                                    AND TWTTMP.TWT_CODAA3 = %Exp:cIDUnico%
                                    AND TWTTMP.TWT_MOTIVO IN ('2','3')
								)
   GROUP BY TWT.TWT_CODMV, TWT.TWT_HMELIM
   HAVING MAX(TWT.TWT_NUMHOR) <> ' ' AND MAX(TWT.TWT_ITEM) <> ' '
   ORDER BY TWT_ITEM DESC
EndSql

If (cAliasQry)->(! EOF())
	aRet := {(cAliasQry)->TWT_NUMHOR, (cAliasQry)->TWT_ITEM, (cAliasQry)->TWT_CODMV, (cAliasQry)->TWT_HMELIM}
EndIf

(cAliasQry)->(DbCloseArea())
RestArea(aOldArea)
Return aRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At970SetHm
@description  Inicializa o array de medição/apuração dos apontamentos da base de atendimento
@sample        At970SetHm()
@param         nenhum
@return        NIL
@author        Alexandre da Costa (a.costa)
@since         25/07/2016
@version       P12
/*/
//------------------------------------------------------------------------------
Function At970SetHm()

aApontaHrm		:= {}
Return NIL


//------------------------------------------------------------------------------
/*/{Protheus.doc} At970TotHm
@description  Recupera o total de medição/apuração dos apontamentos para a base de atendimento
@sample        At970TotHm(cIDUnico)
@param         cIDUnico:  ID único da base de atendimento
@return        ExpN:       Quantidade total de aputação/medição do horimetro da base de atendimento
@author        Alexandre da Costa (a.costa)
@since         25/07/2016
@version       P12
/*/
//------------------------------------------------------------------------------
Function At970TotHm(cIDUnico)

Local nPosIDUnico	:= 0
Local nPosHorim	:= 0
Local nRet			:= 0

Default cIDUnico	:= Space(TamSX3("TWT_CODAA3")[1])

If	! Empty(cIDUnico)
	If ( nPosIDUnico := aScan(aApontaHrm, {|x| x[01] == cIDUnico}) ) > 0
		For nPosHorim := 1 to Len(aApontaHrm[nPosIDUnico][02])
			nRet	+= aApontaHrm[nPosIDUnico][02][nPosHorim][05]
		Next nPosHorim
	EndIf
EndIf
Return nRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At970BldHm
@description  Monta o array dos valores totais das marcações dos horimetros das bases de atendimento para ser utilizado nas medições/apurações.
@sample        At970BldHm(cIDUnico)
@param         cIDUnico:   ID único da base de atendimento
@param         cCodMV:      Código da movimentação da base de atendimento
@param         dDtFmMdApu: Data final para apuração/medição
@return        NIL
@author        Alexandre da Costa (a.costa)
@since         22/07/2016
@version       P12
/*/
//------------------------------------------------------------------------------
Function At970BldHm(cIDUnico, cCodMV, dDtFmMdApu)

Local aOldArea	:= GetArea()
Local cAliasQry	:= GetNextAlias()
Local cCodTFVAnt	:= ""
Local nTamValHor	:= TamSX3("TWT_VALHOR")[1]
Local nDecValHor	:= TamSX3("TWT_VALHOR")[2]
Local nTamHMELIM	:= TamSX3("TWT_HMELIM")[1]
Local nDecHMELIM	:= TamSX3("TWT_HMELIM")[2]
Local nVlMaxHor	:= 0
Local nPosHorim	:= 0
Local nPosIDUnico	:= 0
Local lNewHorim	:= .F.

Default cIDUnico	:= Space(TamSX3("TWT_CODAA3")[1])
Default cCodMV	:= Space(TamSX3("TWT_CODMV")[1])

//--------------------------------------------------------------------------------------------------------------------------------
// A seleção das marcações da Base de atendimento + Movimentação leva em consideração somente a DATA FINAL DE APURAÇÃO/MEDIÇÃO
// para que não hajam períodos anteriores que não tenham sido apurados/medidos corretamente. Quando ocorrer uma nova solicitação 
// para a apuração/medição da mesma base de atendimento + movimentação com um próximo período, a seleção de registros irá trazer 
// as marcações a partir da última marcação já apurada para aquele equipamento/movimentação até a data limite de apuração/medição 
// da nova solicitação.
//--------------------------------------------------------------------------------------------------------------------------------
If	! Empty(cIDUnico) .AND. ! Empty(cCodMV) .AND. ! Empty(dDtFmMdApu)
	BeginSql Alias cAliasQry

		COLUMN TWT_VALHOR AS NUMERIC(nTamValHor, nDecValHor)
		COLUMN TWT_HMELIM AS NUMERIC(nTamHMELIM, nDecHMELIM)

		SELECT DISTINCT TWT.TWT_NUMHOR, TWT.TWT_ITEM, TWT.TWT_MOTIVO, TWT.TWT_VIRADA, TWT.TWT_VALHOR, TWT.TWT_CODTFV, TWT.TWT_HMELIM
		  FROM %table:TWT% TWT
		 WHERE TWT.TWT_FILIAL = %xFilial:TWT%
		   AND TWT.%NotDel%
		   AND TWT.TWT_CODAA3 = %Exp:cIDUnico%
		   AND TWT.TWT_CODMV = %Exp:cCodMV%
		   AND TWT.TWT_DTMARC <= %Exp:dDtFmMdApu%
		   AND TWT.TWT_CODTFV = ' '

		UNION

		SELECT DISTINCT TWT.TWT_NUMHOR, TWT.TWT_ITEM, TWT.TWT_MOTIVO, TWT.TWT_VIRADA, TWT.TWT_VALHOR, TWT.TWT_CODTFV, TWT.TWT_HMELIM
		  FROM %table:TWT% TWT
		 WHERE TWT.TWT_FILIAL = %xFilial:TWT%
		   AND TWT.%NotDel%
		   AND TWT.TWT_CODAA3 = %Exp:cIDUnico%
		   AND TWT.TWT_CODMV = %Exp:cCodMV%
		   AND TWT.TWT_DTMARC <= %Exp:dDtFmMdApu%
		   AND TWT.TWT_CODTFV <> ' '
		   AND ( TWT.TWT_ITEM IN ( SELECT DISTINCT MIN(TWT.TWT_ITEM)
		                             FROM %table:TWT% TWT
		                            WHERE TWT.TWT_FILIAL = %xFilial:TWT%
		                              AND TWT.%NotDel%
		                              AND TWT.TWT_CODAA3 = %Exp:cIDUnico%
		                              AND TWT.TWT_CODMV = %Exp:cCodMV%
		                              AND TWT.TWT_DTMARC <= %Exp:dDtFmMdApu%
		                              AND TWT.TWT_CODTFV <> ' ' ) OR
		         TWT.TWT_ITEM IN ( SELECT DISTINCT MAX(TWT.TWT_ITEM)
		                             FROM %table:TWT% TWT
		                            WHERE TWT.TWT_FILIAL = %xFilial:TWT%
		                              AND TWT.%NotDel%
		                              AND TWT.TWT_CODAA3 = %Exp:cIDUnico%
		                              AND TWT.TWT_CODMV = %Exp:cCodMV%
		                              AND TWT.TWT_DTMARC <= %Exp:dDtFmMdApu%
		                              AND TWT.TWT_CODTFV <> ' ' ) )

		 ORDER BY TWT.TWT_NUMHOR, TWT.TWT_ITEM

	EndSql

	If	(cAliasQry)->(! EOF())
		If ( nPosIDUnico := aScan(aApontaHrm, {|x| x[01] == cIDUnico}) ) == 0
			aAdd( aApontaHrm, {cIDUnico,{}})
			nPosIDUnico := Len(aApontaHrm)
		EndIf
	EndIf

	While	(cAliasQry)->(! EOF())

		lNewHorim	:= .F.
		// Faz o controle do armazenamento do número do horimetro do equipamento para a medição/apuração... 
		If	( nPosHorim := aScan(aApontaHrm[nPosIDUnico][02], {|x| x[01] == (cAliasQry)->TWT_NUMHOR}) ) == 0
			// Adiciona o horimetro para a contagem...
			aAdd( aApontaHrm[nPosIDUnico][02], {(cAliasQry)->TWT_NUMHOR,;
			                                    (cAliasQry)->TWT_MOTIVO,;
			                                    (cAliasQry)->TWT_VALHOR,;
			                                    0,;
			                                    0,;
			                                    {(cAliasQry)->TWT_ITEM}} )
			lNewHorim	:= .T.
			nPosHorim	:= Len(aApontaHrm[nPosIDUnico][02])
		EndIf
		// Faz o controle do armazenamento do item da marcação do horimetro do equipamento para a medição/apuração...
		If	aScan(aApontaHrm[nPosIDUnico][02][nPosHorim][06], {|x| x == (cAliasQry)->TWT_ITEM}) == 0
			aAdd( aApontaHrm[nPosIDUnico][02][nPosHorim][06], (cAliasQry)->TWT_ITEM)
		EndIf

		If	! lNewHorim
			If	Empty( (cAliasQry)->TWT_CODTFV ) .OR. (Empty(cCodTFVAnt) .AND. ! Empty( (cAliasQry)->TWT_CODTFV ))
				// Verifica se houve a marcação de virada no horimetro. Caso afirmativo, contempla o valor total com a virada do contador do horimetro
				// Acumula a marcação do horimetro
				If	(cAliasQry)->TWT_VIRADA == "1"	//"1"=Sim;"2"=Não
					nVlMaxHor	:= Val(Replicate("9",Int((cAliasQry)->TWT_HMELIM)))
					aApontaHrm[nPosIDUnico][02][nPosHorim][05]	+= (( nVlMaxHor + 1) - aApontaHrm[nPosIDUnico][02][nPosHorim][04]) + (cAliasQry)->TWT_VALHOR
				Else
					aApontaHrm[nPosIDUnico][02][nPosHorim][05]	+= ( (cAliasQry)->TWT_VALHOR - aApontaHrm[nPosIDUnico][02][nPosHorim][04] )
				EndIf
			EndIf
		EndIf

		cCodTFVAnt											:= (cAliasQry)->TWT_CODTFV
		aApontaHrm[nPosIDUnico][02][nPosHorim][02]	:= (cAliasQry)->TWT_MOTIVO	// Guarda o último motivo de marcação do horimetro
		aApontaHrm[nPosIDUnico][02][nPosHorim][04]	:= (cAliasQry)->TWT_VALHOR	// Guarda a última marcação do horimetro
		(cAliasQry)->(dBSkip())
	EndDo

	If	Len(aApontaHrm) > 0 .AND. Len(aApontaHrm[nPosIDUnico][02]) > 0
		// Se o último motivo de marcação do horimetro for igual à SAÍDA, então, este item não fará parte dessa medição/apuração,
		// pois o valor total de utilização a partir dessa SAÍDA, entrará na próxima medição/apuração do equipamento... 
		If	aApontaHrm[nPosIDUnico][02][Len(aApontaHrm[nPosIDUnico][02])][02] == DF_HORIMETRO_MOTIVO_SAIDA
			aDel(aApontaHrm[nPosIDUnico][02],Len(aApontaHrm[nPosIDUnico][02]))
			aSize(aApontaHrm[nPosIDUnico][02],Len(aApontaHrm[nPosIDUnico][02])-1)
		EndIf
	EndIf
	(cAliasQry)->(DbCloseArea())
EndIf
RestArea(aOldArea)
Return NIL


//------------------------------------------------------------------------------
/*/{Protheus.doc} At970GvTFV
@description  Efetiva a gravação do código da apuração/medição do horimetro da base de atendimento.
@sample        At970GvTFV(cIDUnico, cCodTFV)
@param         cIDUnico:   ID único da base de atendimento
@param         cCodTFV:    Código da apuração/medição da base de atendimento
@return        NIL
@author        Alexandre da Costa (a.costa)
@since         28/07/2016
@version       P12
/*/
//------------------------------------------------------------------------------
Function At970GvTFV(cIDUnico, cCodTFV)

Local cFilTWT		:= xFilial("TWT")
Local nPosIDUnico	:= 0
Local nPosHorim	:= 0
Local nPosItem	:= 0

Default cIDUnico	:= Space(TamSX3("TWT_CODAA3")[1])
Default cCodTFV	:= Space(TamSX3("TWT_CODTFV")[1])

If	! Empty(cIDUnico) .AND. ! Empty(cCodTFV) 

	TWT->(dBSetOrder(1))	//TWT_FILIAL+TWT_CODAA3+TWT_ITEM+TWT_NUMHOR
	If ( nPosIDUnico := aScan(aApontaHrm, {|x| x[01] == cIDUnico}) ) > 0
		For nPosHorim := 1 to Len(aApontaHrm[nPosIDUnico][02])
			For nPosItem := 1 to Len(aApontaHrm[nPosIDUnico][02][nPosHorim][06])
				If	TWT->(dBSeek(cFilTWT+cIDUnico+aApontaHrm[nPosIDUnico][02][nPosHorim][06][nPosItem])) .AND. Empty(TWT->TWT_CODTFV)
					TWT->(RecLock("TWT",.F.))
					TWT->TWT_CODTFV	:= cCodTFV
					TWT->(MsUnLock())
				EndIf
			Next
		Next nPosHorim
	EndIf
EndIf

Return NIL


//------------------------------------------------------------------------------
/*/{Protheus.doc} At970DlTFV
@description  Estorna a efetivação da apuração/medição do horimetro da base de atendimento.
@sample        At970DlTFV(cIDUnico, cCodTFV)
@param         cIDUnico:   ID único da base de atendimento
@param         cCodTFV:    Código da apuração/medição da base de atendimento
@return        NIL
@author        Alexandre da Costa (a.costa)
@since         28/07/2016
@version       P12
/*/
//------------------------------------------------------------------------------
Function At970DlTFV(cIDUnico, cCodTFV)

Local aOldArea	:= GetArea()
Local cAliasQry	:= GetNextAlias()
Local cFilTWT		:= xFilial("TWT")

Default cIDUnico	:= Space(TamSX3("TWT_CODAA3")[1])
Default cCodTFV	:= Space(TamSX3("TWT_CODTFV")[1])

If	! Empty(cIDUnico) .AND. ! Empty(cCodTFV)
	BeginSql Alias cAliasQry

	   SELECT TWT.TWT_CODAA3, TWT.TWT_ITEM, TWT.TWT_NUMHOR
	     FROM %table:TWT% TWT
	    WHERE TWT.TWT_FILIAL = %xFilial:TWT%
	      AND TWT.%NotDel%
	      AND TWT.TWT_CODAA3 = %Exp:cIDUnico%
	      AND TWT.TWT_CODTFV = %Exp:cCodTFV%

	EndSql

	TWT->(dBSetOrder(1))	//TWT_FILIAL+TWT_CODAA3+TWT_ITEM+TWT_NUMHOR
	While	(cAliasQry)->(! EOF())
		TWT->(dBSeek(cFilTWT+(cAliasQry)->TWT_CODAA3+(cAliasQry)->TWT_ITEM+(cAliasQry)->TWT_NUMHOR))
		TWT->(RecLock("TWT",.F.))
		TWT->TWT_CODTFV	:= ""
		TWT->(MsUnLock())
		(cAliasQry)->(dBSkip())
	EndDo

	(cAliasQry)->(DbCloseArea())
EndIf
RestArea(aOldArea)
Return NIL

/*/{Protheus.doc} At970IsPos
@description   Verifica se o valor inserido é maior que zero
@param         nValor, Numérico, Valor digitado pelo usuário para validação
@return        Lógico, 
@author        Inovação Gestão de Serviços
@since         15/09/2016
@version       P12
/*/
Static Function At970IsPos( nValor )

Local lRet := ( nValor > 0 )

If !lRet
	Help(,, "AT970ISPOS",,STR0098,1,0,,,,,,{STR0099})  // "Valor não pode ser negativo ou zero." ### "Insira um valor maior que zero."
EndIf

Return lRet

/*/{Protheus.doc} At970PosTP
@description   Função para identificar se uma marcação 
@author        josimar.assuncao
@since         06.01.2017
@version       P12
@param 			cFilOri, caracter, filial do bem a ser pesquisado
@param 			cCodBem, caracter, código do bem a ser pesquisado
@param 			dDataMarc, data, data da marcação no contador
@param 			cHoraMarc, caracter, hora da marcação no contador
@param 			nRetRecno, numérico, referência, recno do registro na STP
@return 		Lógico, indica se foi possível encontrar o registro com as informações passadas
/*/
Function At970PosTP( cFilOri, cCodBem, dDataMarc, cHoraMarc, nRetRecno )
Local lFound := .F.
Local cQrySearch := GetNextAlias()

nRetRecno := 0

BeginSQL Alias cQrySearch
	SELECT STP.R_E_C_N_O_ STPRECNO
	FROM %Table:STP% STP
	WHERE TP_FILIAL = %Exp:cFilOri%
		AND TP_CODBEM = %Exp:cCodBem%
		AND TP_DTLEITU = %Exp:DTOS(dDataMarc)%
		AND TP_HORA = %Exp:cHoraMarc%
		AND STP.%NotDel%
EndSQL

If (cQrySearch)->(!EOF())
	lFound := .T.
	nRetRecno := (cQrySearch)->STPRECNO
EndIf

(cQrySearch)->(DbCloseArea())

Return lFound

/*/{Protheus.doc} At970TWTIns
@description   	Função para inserir os registros de TWT lançados unicamente utilizando modelo de dados
@author        	josimar.assuncao
@since         	11.01.2017
@version       	P12
@param 			cRetErro, 	caracter, referência, variável para retorno caso erro aconteça
@param 			cFilOri, 	caracter, filial de origem do equipamento
@param 			cNumSer, 	caracter, número de série do equipamento
@param 			cPrdAA3, 	caracter, produto da base de atendimento a ser pesquisada
@param 			dDataMarc, 	data, dia da marcação
@param 			cHoraMarc, 	caracter, hora da marcação 
@param 			nValMarc, 	numérico, valor para a marcação do medidor
@param 			lVirada, 	lógico, determina se o lançamento é uma virada ou não
@return 		Lógico, indica se o processo foi inserido com sucesso ou não
/*/
Function At970TWTIns( cRetErro, cFilOri, cNumSer, cPrdAA3, dDataMarc, cHoraMarc, nValMarc, lVirada )
Local lRetorno 		:= .F.
Local aErro 		:= {}
Local nHMELimite 	:= 0
Local lShowErro 	:= If(ValType(cRetErro) == "U", .T., .F.)

cRetErro := ""

If (lRetorno := AtPosAA3(cFilOri + cNumSer, cPrdAA3))
	nHMELimite := AA3->AA3_HMELIM

	If At( ":", cHoraMarc )
		cHoraMarc := StrTran( cHoraMarc, ":", "" )
	EndIf

	lRetorno := lRetorno .And. At970Gv1( DF_HORIMETRO_FASE_INTEGRADO, /*cItem*/, /*cNumHor*/, lVirada,;
											dDataMarc, cHoraMarc, nValMarc, nHMELimite, /*cCodMV*/, lShowErro )

	If !lRetorno .And. Len(aErro := GetAutoGrLog()) > 0
		aEval(aErro, {|x| cRetErro += x })
	EndIf
EndIf

Return lRetorno

/*/{Protheus.doc} At970TWTAlt
@description   	Função para alterar os registros de TWT lançados unicamente utilizando modelo de dados
@author        	josimar.assuncao
@since         	01.02.2017
@version       	P12
@param 			cRetErro, 		caracter, referência, variável para retorno caso erro aconteça
@param 			cFilOri, 		caracter, filial de origem do equipamento
@param 			cNumSer, 		caracter, número de série do equipamento
@param 			cPrdAA3, 		caracter, produto da base de atendimento a ser pesquisada
@param 			lUltLinha, 		lógico, indica se a atualização deve acontecer na última linha ou não
@param 			dDataMarc, 		data, dia da marcação
@param 			cHoraMarc, 		caracter, hora da marcação 
@param 			cMotivo, 		caracter, define qual o motivo deve ser utilizado na atualização do lançamento
@param 			nValMarc, 		numérico, valor para a marcação do medidor
@param 			cDescMotivo, 	caracter, quando a alteração é para quebra ou substituição faz-se nece
@param 			lVirada, 		lógico, determina quando o lançamento é virada
@return 		Lógico, indica se a atualização aconteceu com sucesso ou não
/*/
Function At970TWTAlt( cRetErro, cFilOri, cNumSer, cPrdAA3, lUltLinha, dDtMarc, cHoraMarc, cMotivo, nValMarc, cDescMotivo, lVirada )
Local lRetorno 		:= .T.
Local oModel 		:= Nil
Local oMdlTWT 		:= Nil
Local nLinha 		:= 0
Local lShowErro 	:= (cRetErro == Nil)

Default lUltLinha 	:= .F.
Default dDtMarc 	:= CTOD("")
Default cHoraMarc 	:= ""
Default cMotivo 	:= ""
Default nValMarc 	:= 0
Default cDescMotivo := ""

cRetErro := ""

If (lRetorno := AtPosAA3(cFilOri + cNumSer, cPrdAA3))

	oModel := FwLoadModel("TECA970")
	oModel:SetOperation( MODEL_OPERATION_UPDATE )
	lRetorno := oModel:Activate()

	// captura o modelo dos lançamentos
	oMdlTWT := oModel:GetModel("TWTDETAIL")
	// como surge via integração não exige preenchimento de código de movimentação
	oMdlTWT:GetStruct():SetProperty("TWT_CODMV", MODEL_FIELD_OBRIGAT, .F.)

	If lUltLinha
		nLinha := oMdlTWT:Length()
		oMdlTWT:GoLine( nLinha )
	Else
		lRetorno := .F.
		cRetErro := STR0100 // "Função não preparada para alterar linhas intermediárias."
	EndIf
	
	// só altera as informações caso receba algum conteúdo para inserção
	If !Empty(dDtMarc) 
		lRetorno := lRetorno .And. oMdlTWT:SetValue("TWT_DTMARC", dDtMarc)
	EndIf
	If !Empty(cHoraMarc)
		lRetorno := lRetorno .And. oMdlTWT:SetValue("TWT_HRMARC", cHoraMarc)
	EndIf
	If !Empty(cMotivo)
		lRetorno := lRetorno .And. oMdlTWT:SetValue("TWT_MOTIVO", cMotivo)
	EndIf
	
	// verifica se precisa atualizar que o registro é de virada
	If lRetorno .And. lVirada .And. oMdlTWT:GetValue("TWT_VIRADA")=="2"
		// recebe que é virada e não está registrado como virada
		lRetorno := lRetorno .And. oMdlTWT:SetValue("TWT_VIRADA", "1")
	
	ElseIf lRetorno .And. !lVirada .And. oMdlTWT:GetValue("TWT_VIRADA")=="1"
		// recebe que não é virada e está registrado como virada
		lRetorno := lRetorno .And. oMdlTWT:SetValue("TWT_VIRADA", "2")
	EndIf
	
	// atualiza o valor do registro
	If nValMarc > 0
		lRetorno := lRetorno .And. oMdlTWT:SetValue("TWT_VALHOR", nValMarc)
	EndIf
	
	// verifica a descrição do motivo está preenchida
	If !Empty( cDescMotivo )
		lRetorno := lRetorno .And. oMdlTWT:SetValue("TWT_DSCMOT", cDescMotivo)
	EndIf

	// garante que os dados estejam preenchidos corretamente na linha
	lRetorno := lRetorno .And. oMdlTWT:VldLineData()

	If !lRetorno 
		AtErroMvc(oModel)
		If lShowErro
			MostraErro()
		ElseIf (Len(aErro := GetAutoGrLog())) > 0
			aEval(aErro, {|x| cRetErro += x })
		EndIf
	EndIf
EndIf

Return lRetorno

/*/{Protheus.doc} At970Gv1
@description   	Função para gravar os registros de TWT lançados unicamente utilizando modelo de dados
@author        	josimar.assuncao
@since         	11.01.2017
@version       	P12
@param 			cOperLcto, caracter, indicador de operação que está sendo feita
@param 			cItem, caracter, sequência de lançamento do registro
@param 			cNumHor, caracter, código sequêncial de identificação do medidor atual do equipamento
@param 			lVirada, lógico, determina se está acontecendo uma virada no medidor
@param 			dDtMarc, data, data da leitura do registro
@param 			cHrMarc, caracter, hora de marcação do registro
@param 			nValHorim, numérico, valor de leitura da informação do horímetro
@param 			nHMELimite, numérico, quantidade máxima de caracteres para registro no medidor [2 = 99, 3 = 999]
@param 			cCodMV, caractere, identifica se o registro está sendo lançado dentro da alocação de 
@return 		Lógico, indica se foi possível encontrar o registro com as informações passadas
/*/
Static Function At970Gv1( cOperLcto, cItem, cNumHor, lVirada, dDtMarc, cHrMarc, nValHorim, nHMELimite, cCodMV, lMostraErro )
Local lRet 			:= .T.
Local cMotivo 		:= ""
Local cTpLcto 		:= ""
Local oModel 		:= Nil
Local oModTWT 		:= Nil
Local nLastLine 	:= 0
Local nNewLine 		:= 0

Default cCodMV := At970GetMV( AA3->AA3_FILORI, AA3->AA3_NUMSER )
Default lMostraErro := .T.

Begin Transaction
	AA3->(RecLock("AA3",.F.))
	If	cOperLcto == DF_HORIMETRO_FASE_SEPARACAO
		AA3->AA3_HMESEP	:= nValHorim
		AA3->AA3_CONSEP	:= .T.
		AA3->AA3_CONRET	:= .F.
		AA3->AA3_HMELIM	:= nHMELimite
		cMotivo			:= DF_HORIMETRO_MOTIVO_SAIDA	//0=Saida;1=Marcação;2=Substituição;3=Quebra;9=Retorno
		cTpLcto			:= DF_HORIMETRO_TPLCTO_SAIDA	//1=Saída para locação;2=Atualização;3=Retorno de locação;4=Integrado
	ElseIf cOperLcto == DF_HORIMETRO_FASE_RETORNO
		AA3->AA3_HMERET	:= nValHorim
		AA3->AA3_CONRET	:= .T.
		AA3->AA3_CONSEP	:= .F.
		cMotivo			:= DF_HORIMETRO_MOTIVO_RETORNO	//0=Saida;1=Marcação;2=Substituição;3=Quebra;9=Retorno
		cTpLcto			:= DF_HORIMETRO_TPLCTO_RETORNO	//1=Saída para locação;2=Atualização;3=Retorno de locação
	ElseIf cOperLcto == DF_HORIMETRO_FASE_INTEGRADO
		cMotivo			:= DF_HORIMETRO_MOTIVO_MARCACAO	 //0=Saida;1=Marcação;2=Substituição;3=Quebra;9=Retorno
		cTpLcto			:= DF_HORIMETRO_TPLCTO_INTEGRADO	//1=Saída para locação;2=Atualização;3=Retorno de locação;4=Integrado
	Else
		lRet := .F.
	EndIf
	AA3->(MsUnLock())
	
	If lRet
		oModel := FwLoadModel("TECA970")
		oModel:SetOperation(MODEL_OPERATION_UPDATE)
		
		lRet := lRet .And. oModel:Activate()
		
		oModTWT := oModel:GetModel("TWTDETAIL")
		oModTWT:GetStruct():SetProperty("TWT_CODMV", MODEL_FIELD_OBRIGAT, .F.)

		nLastLine := oModTWT:Length()
		oModTWT:GoLine( nLastLine )

		If cItem == Nil
			cItem := Soma1(oModTWT:GetValue("TWT_ITEM"))
		EndIf

		If cNumHor == Nil
			cNumHor := oModTWT:GetValue("TWT_NUMHOR")
		EndIf

		If nLastLine > 1 .Or. !Empty( oModTWT:GetValue( "TWT_VALHOR") )
			nNewLine := ( nLastLine + 1 )
			If oModTWT:AddLine() <> nNewLine
				lRet := .F.
			EndIf
		EndIf

		lRet := lRet .And. oModTWT:LoadValue( "TWT_MOTIVO" 	, cMotivo )
		lRet := lRet .And. oModTWT:SetValue( "TWT_TPLCTO" 	, cTpLcto )
		lRet := lRet .And. oModTWT:SetValue( "TWT_ITEM"		, cItem )
		lRet := lRet .And. oModTWT:SetValue( "TWT_VIRADA" 	, If(lVirada,"1","2") ) 	//1=Sim;2=Não
		lRet := lRet .And. oModTWT:SetValue( "TWT_DTMARC" 	, dDtMarc )
		lRet := lRet .And. oModTWT:SetValue( "TWT_HRMARC" 	, cHrMarc )
		lRet := lRet .And. oModTWT:SetValue( "TWT_NUMHOR" 	, cNumHor )
		lRet := lRet .And. oModTWT:SetValue( "TWT_HMELIM" 	, nHMELimite )
		lRet := lRet .And. oModTWT:SetValue( "TWT_VALHOR" 	, nValHorim )
		lRet := lRet .And. oModTWT:SetValue( "TWT_DSCMOT" 	, "" )
		lRet := lRet .And. oModTWT:SetValue( "TWT_CODMV" 	, cCodMV )
		lRet := lRet .And. oModTWT:SetValue( "TWT_CODTFV" 	, "" )
		// convertido para mvc para chamar o processo de integração com o MNT
		lRet := lRet .And. oModel:VldData() .And. oModel:CommitData()
	EndIf

	If !lRet
		DisarmTransaction()
		AtErroMvc(oModel)
		If lMostraErro
			MostraErro()
		EndIf
	EndIf

End Transaction

oModel:DeActivate()
oModel:Destroy()

Return lRet

/*/{Protheus.doc} At970DelInt
@description   	Função para avaliar se um determinado item lançado no medidor deve ou não continuar sendo bloqueado
@author        	josimar.assuncao
@since         	16.01.2017
@version       	P12
@return 		Lógico, indica se pode prosseguir com o bloqueio do registro ou não
/*/
Static Function At970DelInt( oGrid, nLinha )
Local lRetorno := .T.

lRetorno := !IsInCallStack('At970TWTAlt')

Return lRetorno
