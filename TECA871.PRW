#include "TECA871.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

//Status do orçamento de serviços 
#DEFINE DEF_TFJ_ATIVO     "1"			//TFJ_STATUS Ativo
#DEFINE DEF_TFJ_EMREVISAO "2"			//TFJ_STATUS Em Revisão
#DEFINE DEF_TFJ_REVISADO  "3"			//TFJ_STATUS Revisado
#DEFINE DEF_TFJ_AGDAPROVA "4"			//TFJ_STATUS Aguardando Aprovação
#DEFINE DEF_TFJ_ENCERRADO "5"			//TFJ_STATUS Encerrado
#DEFINE DEF_TFJ_CANCELADO "6"			//TFJ_STATUS Cancelado

//----------------------------------------------------------
/*/{Protheus.doc} ModelDef()
Model - Efetivar encerramento do posto 

@Return 	model
@author 	Serviços
@since 		25/08/2015
/*/
//----------------------------------------------------------
Static Function ModelDef()

Local oModel	:= Nil
Local oStrCab	:= FWFormStruct(1,"TFJ")
Local oStrTFL := FWFormStruct(1,"TFL")
Local oStrTFF := FWFormStruct(1,"TFF")
Local oStrTFI := FWFormStruct(1,"TFI")
Local lSrvExt := FUNNAME()== "TECA870A"
Local aRelTFL := {}
Local aRelTFF := {}
Local aRelTFI := {}
Local xAux	  := Nil

If lSrvExt
	aRelTFL := { { "TFL_FILIAL", "xFilial('TFJ')" }, { "TFL_CODPAI", "TFJ_CODIGO" }}
	aRelTFF := { { "TFF_FILIAL", "xFilial('TFL')" }, { "TFF_CODPAI", "TFL_CODIGO" }}
	aRelTFI := { { "TFI_FILIAL", "xFilial('TFL')" }, { "TFI_CODPAI", "TFL_CODIGO" }}
Else
	aRelTFL := { { "TFL_FILIAL", "xFilial('TFJ')" }, { "TFL_CONTRT", "TFJ_CONTRT" } , { "TFL_CONREV", "TFJ_CONREV" } }
	aRelTFF := { { "TFF_FILIAL", "xFilial('TFL')" }, { "TFF_CONTRT", "TFL_CONTRT" } , { "TFF_CONREV", "TFL_CONREV" } , { "TFF_LOCAL", "TFL_LOCAL" } }
	aRelTFI := { { "TFI_FILIAL", "xFilial('TFL')" }, { "TFI_CONTRT", "TFL_CONTRT" } , { "TFI_CONREV", "TFL_CONREV" } , { "TFI_LOCAL", "TFL_LOCAL" } }
EndIf

oModel := MPFormModel():New("TECA871", /*bPreValidacao*/, {|oMdl| At871RecPen(oMdl)}, {|oMdl| At871Commit(oMdl)}, /*bCancel*/ )

//Criando master falso para a alimentação dos details.
oModel:AddFields("TFJMASTER",/*cOwner*/,oStrCab, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

//locais do contrato
oModel:AddGrid( "TFLDETAIL", "TFJMASTER", oStrTFL, {|oMdlTFL, nLine, cAction, cField, xValue| At871PVTFL(oMdlTFL, cAction, nLine, cField, xValue)}, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*bLoad*/ )
oModel:SetRelation( "TFLDETAIL", aRelTFL , TFL->(IndexKey(1)) )
oModel:SetDescription(STR0001) //"Locais do contrato"

//Itens do RH
oModel:AddGrid( "TFFDETAIL", "TFLDETAIL", oStrTFF, {|oMdlTFF, nLine, cAction, cField, xValue| At871PVTFF(oMdlTFF, cAction, nLine, cField, xValue)}, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*bLoad*/ )
oModel:SetRelation( "TFFDETAIL",aRelTFF , TFF->(IndexKey(1)) )
oModel:SetDescription(STR0002) //"Itens do RH"

//Itens de locação
oModel:AddGrid( "TFIDETAIL", "TFLDETAIL", oStrTFI, {|oMdlTFI, nLine, cAction, cField, xValue| At871PVTFI(oMdlTFI, cAction, nLine, cField, xValue)}, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*bLoad*/ )
oModel:SetRelation( "TFIDETAIL", aRelTFI, TFI->(IndexKey(1)) )
oModel:SetDescription(STR0003) //"Itens de locação" 

//Adicional campo OK para controle da operação
oStrTFL:AddField("", "", "OK", "L", 1, 0, /*{ || At871VldDt("TFL") }bValid */, , {}	, .F., , .F., .F., .F., , )//''#//'Seleção'
oStrTFF:AddField("", "", "OK", "L", 1, 0, /*{ || At871VldDt("TFF") }/*bValid */, , {}	, .F., , .F., .F., .F., , )//''#//'Seleção'
oStrTFI:AddField("", "", "OK", "L", 1, 0, /*{ || At871VldDt("TFF") }/*bValid */, , {}	, .F., , .F., .F., .F., , )//''#//'Seleção'

//Adiciona a data anterior ao encerramento.
oStrTFL:AddField(	GetSx3Cache("TFL_DTFIM","X3_TITULO"),;          // cTitle 	// "Vigenc. Final"
					GetSx3Cache("TFL_DTFIM","X3_TITULO"),;          // cToolTip // "Vigenc. Final"
					"TFL_FIMOLD",;                                  // cIdField
					GetSx3Cache("TFL_DTFIM","X3_TIPO"),;            // cTipo
					GetSx3Cache("TFL_DTFIM","X3_TAMANHO"),;         // nTamanho
					GetSx3Cache("TFL_DTFIM","X3_DECIMAL"),;        	// nDecimal
					Nil,;											// bValid
					Nil,;                                           // bWhen
					Nil,;                                           // aValues
					.F.,;                                           // lObrigat
					Nil,;                                           // bInit
					.F.,;                                           // lKey
					.F.,;                                           // lNoUpd
					.T.)                                       		// lVirtual

//Adiciona a data anterior ao encerramento.
oStrTFF:AddField(	GetSx3Cache("TFF_PERFIM","X3_TITULO"),;         // cTitle 	// "Per. Final"
					GetSx3Cache("TFF_PERFIM","X3_TITULO"),;         // cToolTip // "Per. Final"
					"TFF_FIMOLD",;                                  // cIdField
					GetSx3Cache("TFF_PERFIM","X3_TIPO"),;           // cTipo
					GetSx3Cache("TFF_PERFIM","X3_TAMANHO"),;        // nTamanho
					GetSx3Cache("TFF_PERFIM","X3_DECIMAL"),;        // nDecimal
					Nil,;											// bValid
					Nil,;                                           // bWhen
					Nil,;                                           // aValues
					.F.,;                                           // lObrigat
					Nil,;                                           // bInit
					.F.,;                                           // lKey
					.F.,;                                           // lNoUpd
					.T.)                                       		// lVirtual

//Adiciona a data anterior ao encerramento.
oStrTFI:AddField(	GetSx3Cache("TFI_PERFIM","X3_TITULO"),;         // cTitle 	// "Per. Final"
					GetSx3Cache("TFI_PERFIM","X3_TITULO"),;         // cToolTip // "Per. Final"
					"TFI_FIMOLD",;                                  // cIdField
					GetSx3Cache("TFI_PERFIM","X3_TIPO"),;           // cTipo
					GetSx3Cache("TFI_PERFIM","X3_TAMANHO"),;        // nTamanho
					GetSx3Cache("TFI_PERFIM","X3_DECIMAL"),;        // nDecimal
					Nil,;											// bValid
					Nil,;                                           // bWhen
					Nil,;                                           // aValues
					.F.,;                                           // lObrigat
					Nil,;                                           // bInit
					.F.,;                                           // lKey
					.F.,;                                           // lNoUpd
					.T.)                                       		// lVirtual

xAux := FwStruTrigger( 'OK', 'OK', 'At871GtDt("TFL")', .F. )
		oStrTFL:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])

xAux := FwStruTrigger( 'OK', 'OK', 'At871GtDt("TFF")', .F. )
		oStrTFF:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])

xAux := FwStruTrigger( 'OK', 'OK', 'At871GtDt("TFI")', .F. )
		oStrTFI:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])

oModel:getModel("TFFDETAIL"):SetOptional(.T.)
oModel:getModel("TFIDETAIL"):SetOptional(.T.)

oModel:GetModel("TFLDETAIL"):SetNoDeleteLine()
oModel:GetModel("TFFDETAIL"):SetNoDeleteLine()
oModel:GetModel("TFIDETAIL"):SetNoDeleteLine()

oModel:GetModel("TFLDETAIL"):SetNoInsertLine()
oModel:GetModel("TFFDETAIL"):SetNoInsertLine()
oModel:GetModel("TFIDETAIL"):SetNoInsertLine()

oStrCab:SetProperty("*",         MODEL_FIELD_OBRIGAT, .F. )
oStrTFF:SetProperty("TFF_PRCVEN",         MODEL_FIELD_OBRIGAT, .F. )

oStrTFL:SetProperty("TFL_DESLOC", MODEL_FIELD_INIT, {|| Posicione("ABS",1,xFilial("ABS")+TFL->TFL_LOCAL,"ABS_DESCRI")})
oStrTFL:SetProperty("TFL_MUNIC",  MODEL_FIELD_INIT, {|| Posicione("ABS",1,xFilial("ABS")+TFL->TFL_LOCAL,"ABS_MUNIC")})
oStrTFL:SetProperty("TFL_ESTADO", MODEL_FIELD_INIT, {|| Posicione("ABS",1,xFilial("ABS")+TFL->TFL_LOCAL,"ABS_ESTADO")})
oStrTFI:SetProperty("TFI_DESCRI", MODEL_FIELD_INIT, {|| Posicione("SB1",1,xFilial("SB1")+TFI->TFI_PRODUT,"B1_DESC")}) 
oStrTFI:SetProperty("TFI_UM",     MODEL_FIELD_INIT, {|| Posicione("SB1",1,xFilial("SB1")+TFI->TFI_PRODUT,"B1_UM")})
oStrTFF:SetProperty("TFF_DESCRI", MODEL_FIELD_INIT, {|| Posicione("SB1",1,xFilial("SB1")+TFF->TFF_PRODUT,"B1_DESC")})

oStrTFF:SetProperty("OK",         MODEL_FIELD_WHEN, {|| !(Empty(FwFldGet("TFF_PRODUT")))})
oStrTFF:SetProperty("TFF_ENCE",   MODEL_FIELD_WHEN, {|| !(Empty(FwFldGet("TFF_PRODUT")))})
oStrTFI:SetProperty("OK",         MODEL_FIELD_WHEN, {|| !(Empty(FwFldGet("TFI_PRODUT")))})
oStrTFI:SetProperty("TFI_ENCE",   MODEL_FIELD_WHEN, {|| !(Empty(FwFldGet("TFI_PRODUT")))})

oModel:GetModel( 'TFLDETAIL' ):SetLoadFilter( { { 'TFL_ENCE', "' '" }, { 'TFL_ENCE', "'2'",, MVC_LOADFILTER_OR } } )
oModel:GetModel( 'TFIDETAIL' ):SetLoadFilter( { { 'TFI_ENCE', "' '" }, { 'TFI_ENCE', "'2'",, MVC_LOADFILTER_OR } } )

If IsInCallStack("TECA740G")//Adição de reforço

	oModel:GetModel( 'TFFDETAIL' ):SetLoadFilter( , " ( TFF_ORIREF <> ' ' AND (TFF_ENCE = ' ' OR TFF_ENCE = '2') )" )

Else
	oModel:GetModel( 'TFFDETAIL' ):SetLoadFilter( { { 'TFF_ENCE', "' '" }, { 'TFF_ENCE', "'2'",, MVC_LOADFILTER_OR } } )
Endif



oModel:SetPrimarykey({})
oModel:SetActivate( {|oModel| InitDados( oModel ) } )

Return(oModel)

//----------------------------------------------------------
/*/{Protheus.doc} ViewDef()
View - Relacionamentos - Gestão de Escalas 

@Return 	view
@author 	Serviços
@since 		17/08/2015
/*/
//----------------------------------------------------------
Static Function ViewDef()

Local oView
Local oModel  := FWLoadModel("TECA871")
Local oStrCab := FWFormStruct(2,"TFJ")  
Local oStrTFL := FWFormStruct(2,"TFL",{|cCpo| !(Alltrim(cCpo)$"TFL_ENCE")})
Local oStrTFF := FWFormStruct(2,"TFF",{|cCpo| !(Alltrim(cCpo)$"TFF_ENCE")})
Local oStrTFI := FWFormStruct(2,"TFI",{|cCpo| !(Alltrim(cCpo)$"TFI_ENCE")})
Local lAdcRef := IsInCallStack("TECA740G")//Adição de reforço

oView := FWFormView():New()
oView:SetModel(oModel)

oView:AddField("FORM_FAKE",oStrCab, "TFJMASTER") //Cabeçalho falso
oView:AddGrid("VIEW_TFL",  oStrTFL, "TFLDETAIL") //Locais do contrato
oView:AddGrid("VIEW_TFF",  oStrTFF, "TFFDETAIL") //Itens do RH
oView:AddGrid("VIEW_TFI",  oStrTFI, "TFIDETAIL") //Itens de locação

//campo adicional OK
oStrTFL:AddField( "OK", "01", "", "", , "Check" ,,,,,,,,,,,, ) //''#//''
oStrTFF:AddField( "OK", "01", "", "", , "Check" ,,,,,,,,,,,, ) //''#//''
oStrTFI:AddField( "OK", "01", "", "", , "Check" ,,,,,,,,,,,, ) //''#//''

oView:CreateHorizontalBox("BOXCABEC", 0)	//Cabeçalho
oView:CreateHorizontalBox("SUPERIOR", 30)	//locais do contrato
oView:CreateHorizontalBox("INFERIOR", 70)	//locais do contrato

// Criação da pasta para conter as abas da parte inferior
oView:CreateFolder( "ABAS", "INFERIOR" )

// Criação das Abas
oView:AddSheet( "ABAS", "ABA01", STR0002 )	// "Itens RH"
oView:AddSheet( "ABAS", "ABA02", STR0003 )	// "Itens de locação"

// Criação das áreas de exibição dos dados nas abas
oView:CreateHorizontalBox( "ID_ABA01", 100,,, "ABAS", "ABA01" )
oView:CreateHorizontalBox( "ID_ABA02", 100,,, "ABAS", "ABA02" )

oStrCab:SetProperty("*",        MVC_VIEW_CANCHANGE, .F.)
oStrTFL:SetProperty("*",        MVC_VIEW_CANCHANGE, .F.)
oStrTFF:SetProperty("*",        MVC_VIEW_CANCHANGE, .F.)
oStrTFI:SetProperty("*",        MVC_VIEW_CANCHANGE, .F.)
oStrTFF:SetProperty("OK",       MVC_VIEW_CANCHANGE, .T.)
oStrTFI:SetProperty("OK",       MVC_VIEW_CANCHANGE, .T.)
If !lAdcRef //Se rotina for chamada via Adição de Reforço, não poderá ser encerrado o posto original, desabilitado campo OK
	oStrTFL:SetProperty("OK",       MVC_VIEW_CANCHANGE, .T.)
Else
	oStrTFL:SetProperty("OK",       MVC_VIEW_CANCHANGE, .F.)
EndIf

oView:SetOwnerView("FORM_FAKE", "BOXCABEC")	// Cabeçalho
oView:SetOwnerView("VIEW_TFL",  "SUPERIOR") 
oView:SetOwnerView("VIEW_TFF",  "ID_ABA01")	// Grid Itens do RH
oView:SetOwnerView("VIEW_TFI",  "ID_ABA02")	// Grid Itens de locação
 
Return oView


//----------------------------------------------------------
/*/{Protheus.doc} At871RecPen()
	Validar recursos dos postos a serem encerrados 

@Return 	ExpL: .T. = Registros avaliados com sucesso; .F. = Há inconsistências nos registros que impedem a sua gravação
@author 	Serviços
@since 		26/08/2015
/*/
//----------------------------------------------------------
Static Function At871RecPen(oMdl)

Local cOldAlias	:= Alias()
Local aOldSX3		:= SX3->(GetArea())
Local aOldAlias	:= (cOldAlias)->(GetArea()) 
Local oMdlTFL		:= oMdl:GetModel("TFLDETAIL")
Local oMdlTFF		:= oMdl:GetModel("TFFDETAIL")
Local oMdlTFI		:= oMdl:GetModel("TFIDETAIL")
Local oMdlTFJ		:= oMdl:GetModel("TFJMASTER")
Local aSaveLines	:= FWSaveRows()
Local lRet			:= .T.
Local lOkTFF		:= .T.
Local lOkTFS		:= .T.
Local lOkTEW		:= .T.
Local lAllMrk		:= .T.
Local aCmpTFS		:= {}
Local cMens		:= ""
Local cMens02		:= ""
Local cTmpTFF		:= ""
Local cTmpTFS		:= ""
Local cTmpTEW		:= ""
Local cProduto	:= ""
Local cTpMov		:= ""
Local cTitTFFFunc	:= ""
Local cTitABBCod	:= ""
Local cTitTFSPrd	:= "" 
Local cTitTFSQtde	:= "" 
Local cPicTFSQtde	:= ""
Local nInd			:= 0
Local nQuant		:= 0
Local nSld			:= 0
Local nRes			:= 0
Local nLinTFL		:= 0
Local nLinTFF		:= 0
Local nLinTFI		:= 0
Local lSrvExt       := FUNNAME()== "TECA870A"
Local cOrigemABQ    := ""
Local cChvTFF       := ""
Local cMensLocal	:= ""
Local cItem 		:= ""
Local cProd 		:= ""
Local cDesc			:= ""

If lSrvExt
	cOrigemABQ := "TFJ"
	cChvTFF    := "%TFF.TFF_CODPAI = '"+oMdlTFF:GetValue("TFF_CODPAI")+"'%"
Else
	cOrigemABQ := "CN9"
	cChvTFF    := "%TFF.TFF_CONTRT = '"+oMdlTFF:GetValue("TFF_CONTRT")+"'%"
EndIf

SX3->(dBSetOrder(2))	// X3_CAMPO
SX3->(dBSeek(PadR("ABB_CODTEC",Len(SX3->X3_CAMPO))))
cTitABBCod		:= AllTrim(X3Titulo())+":"
SX3->(dBSeek(PadR("TFF_FUNCAO",Len(SX3->X3_CAMPO))))
cTitTFFFunc	:= AllTrim(X3Titulo())+":"
SX3->(dBSeek(PadR("TFS_PRODUT",Len(SX3->X3_CAMPO))))
cTitTFSPrd		:= AllTrim(X3Titulo())+":"
SX3->(dBSeek(PadR("TFS_QUANT",Len(SX3->X3_CAMPO))))
cTitTFSQtde	:= AllTrim(X3Titulo())+":"
cPicTFSQtde	:= X3Picture()

//verificar se a linha selecionada esta para ser encerrado o posto esta marcado o OK
cMens	:= ""
For nLinTFL := 1 To oMdlTFL:Length()		//Percorrerá todo grid

	oMdlTFL:GoLine(nLinTFL)
	cMensLocal := ""
	If	!( oMdlTFF:IsEmpty() )
		//verificar os itens do RH
		For nLinTFF := 1 to oMdlTFF:Length()
			oMdlTFF:GoLine(nLinTFF)
			If oMdlTFF:GetValue("OK")

				//Verificar se existe agenda futura
				cTmpTFF		:= GetNextAlias()
				BeginSql Alias cTmpTFF
				   Select DISTINCT ABQ.ABQ_CONTRT, ABQ.ABQ_ITEM, TFF.TFF_COD, TFF.TFF_ITEM,
				                   TFF.TFF_PRODUT, (ABQ.ABQ_CONTRT || ABQ.ABQ_ITEM || %Exp:cOrigemABQ%) AS TFF_IDCFAL,
				                   ABB.ABB_CODTEC, AA1.AA1_NOMTEC, SRJ.RJ_DESC
				     From %table:TFF% TFF
				          Inner join %table:ABQ% ABQ ON ABQ.ABQ_FILIAL = %xFilial:ABQ%
				                                    AND ABQ.%NotDel%
				                                    AND ABQ.ABQ_FILTFF = TFF.TFF_FILIAL
				                                    AND ABQ.ABQ_CODTFF = TFF.TFF_COD
				          Inner join %table:ABB% ABB ON ABB.ABB_FILIAL = %xFilial:ABB%
				                                    AND ABB.%NotDel%
				                                    AND ABB.ABB_IDCFAL = (ABQ.ABQ_CONTRT || ABQ.ABQ_ITEM || %Exp:cOrigemABQ%)
				          Inner join %table:AA1% AA1 ON AA1.AA1_FILIAL = %xFilial:AA1%
				                                    AND AA1.%NotDel%
				                                    AND AA1.AA1_CODTEC = ABB.ABB_CODTEC
				          Inner join %table:SRJ% SRJ ON SRJ.RJ_FILIAL = %xFilial:SRJ%
				                                    AND SRJ.%NotDel%
				                                    AND SRJ.RJ_FUNCAO = TFF.TFF_FUNCAO
				    Where TFF.TFF_FILIAL = %xFilial:TFF%
				      AND TFF.%NotDel%
				      AND %exp:cChvTFF%
				      AND TFF.TFF_COD = %exp:oMdlTFF:GetValue("TFF_COD")%
				      AND ABB.ABB_ATIVO = '1'
				      AND 'S' IN (select DISTINCT 'S' AGENDAATIVA
				                    from %table:ABB% ABB
				                   where ABB.ABB_FILIAL = %xFilial:ABB%
				                     AND ABB.%NotDel%
				                     AND ABB.ABB_ATIVO = '1'
				                     AND ABB.ABB_DTINI >= %exp:DtoS(dDataBase)%
				                     AND ABB.ABB_IDCFAL = (ABQ.ABQ_CONTRT || ABQ.ABQ_ITEM || %Exp:cOrigemABQ%))
				    Order by ABQ.ABQ_CONTRT, ABQ.ABQ_ITEM, TFF.TFF_COD, TFF.TFF_ITEM, TFF.TFF_PRODUT
				EndSql
				DbSelectArea(cTmpTFF)
				(cTmpTFF)->(DbGoTop())
				If	(cTmpTFF)->( ! Eof() )
					lOkTFF	:= .F.
					If Empty(cMensLocal)
						cMensLocal	+= If( !Empty(cMens), CRLF + CRLF, "" )
						cMensLocal	+=	STR0004 + AllTrim(oMdlTFL:GetValue("TFL_CODIGO")) + " "+;
										STR0005 + AllTrim(oMdlTFL:GetValue("TFL_LOCAL")) + "-"+;
										AllTrim(oMdlTFL:GetValue("TFL_DESLOC")) + CRLF // Código: " "- Posto: "
						cMens	+= cMensLocal
					Endif						
					cMens	+= If( !Empty(cMens), CRLF, "" )
					cMens	+= STR0021 + CRLF	//"Os atendentes abaixo possuem agenda ativa:"
				EndIf
				While (cTmpTFF)->( ! EOF() )
					cMens	+= If( !Empty(cMens), CRLF, "" )
					cMens	+=	STR0006 + " [" + AllTrim((cTmpTFF)->TFF_ITEM) + "] " +;		//"RH-Item: "
								STR0020 + " [" + AllTrim((cTmpTFF)->TFF_PRODUT) + "] " +;	//"Prod:"
								cTitABBCod + " [" + AllTrim((cTmpTFF)->ABB_CODTEC) + "-" + AllTrim((cTmpTFF)->AA1_NOMTEC) + "] " +;
								cTitTFFFunc + " [" + AllTrim((cTmpTFF)->RJ_DESC) + "] "
					(cTmpTFF)->(dBSkip())
					If (cTmpTFF)->( EOF())
						cMens	+= CRLF
					Endif
				Enddo
				(cTmpTFF)->(DbCloseArea())

				//Verificar os materiais de implantação não retornados
				cTmpTFS	:=	GetNextAlias()
				BeginSql Alias cTmpTFS
				   Select TFF.TFF_ITEM, TFF.TFF_COD, TFS.TFS_PRODUT, SB1.B1_DESC, sum(TFS.TFS_QUANT) AS QtTotal, TFS.TFS_MOV, TFG.TFG_RESRET
				     From %table:TFS% TFS
				          Inner join %table:TFG% TFG on TFG.TFG_FILIAL = %xFilial:TFG%
				                                    AND TFG.%NotDel%
				                                    AND TFG.TFG_COD = TFS.TFS_CODTFG
				          Inner join %table:TFF% TFF on TFF.TFF_FILIAL = %xFilial:TFF%
				                                    AND TFF.%NotDel%
				                                    AND TFF.TFF_COD = TFG.TFG_CODPAI
				          Inner join %table:SB1% SB1 on SB1.B1_FILIAL = %xFilial:SB1%
				                                    AND SB1.%NotDel%
				                                    AND SB1.B1_COD = TFS.TFS_PRODUT
				    Where TFF.TFF_FILIAL = %xFilial:TFF%
				      AND TFF.%NotDel%
				      AND %exp:cChvTFF%
				      AND TFF.TFF_COD = %exp:oMdlTFF:GetValue("TFF_COD")%
				    Group by TFF_COD, TFF_ITEM, TFS_PRODUT, SB1.B1_DESC, TFS_QUANT, TFS_MOV, TFG_RESRET
				    Order by TFF_COD, TFF_ITEM, TFS_PRODUT, TFS_MOV
				EndSql
				//
				aCmpTFS	:=	{}
				cMens02	:= ""
				nSld		:= 0
				DbSelectArea(cTmpTFS)
				(cTmpTFS)->(DbGoTop())
				While (cTmpTFS)->( ! Eof() )
					aAdd(aCmpTFS,{(cTmpTFS)->TFS_PRODUT,;
									(cTmpTFS)->QtTotal,;
									(cTmpTFS)->TFS_MOV,;
									(cTmpTFS)->TFG_RESRET,;
									(cTmpTFS)->TFF_ITEM,;
									(cTmpTFS)->B1_DESC})
					(cTmpTFS)->(dBSkip())
				Enddo
				(cTmpTFS)->(DbCloseArea())
				//Verificar se existe quantidade (saldo) a retornar
				For nInd := 1 to len(aCmpTFS)

					If nInd == 1
						cProduto	:= aCmpTFS[nInd][1]
					Endif

					If cProduto <> aCmpTFS[nInd][1]
						If nSld - nRes > 0
							lOkTFS	:= .F.
							cMens02	+= If( !Empty(cMens02), CRLF, "" )
							//se existir saldo a retornar, avisar o usuário...
							cMens02	+=	STR0024 + " [" + AllTrim(cItem) + "] " +;	//"MI-Item:"
											cTitTFSPrd + " [" + AllTrim(cProd) + "-" + AllTrim(cDesc) + "] " +;
											cTitTFSQtde + " [" + AllTrim(Transform(nSld,cPicTFSQtde)) + "]"

							//zera as quantidades
							nSld	:= 0
							nRes	:= 0
							nQuant	:= 0

						Endif
						
						nRes	:= aCmpTFS[nInd][4]
						nQuant	:= aCmpTFS[nInd][2]
						cTpMov	:= aCmpTFS[nInd][3]
						cItem 		:= aCmpTFS[nInd][5]
						cProd 		:= aCmpTFS[nInd][1]
						cDesc		:= aCmpTFS[nInd][6]
	
						If cTpMov == "1"
							nSld	+= nQuant
						Elseif cTpMov == "2"
							nSld	-= nQuant
						Endif
						//se for o último registro
						If nInd == len(acmpTFS)
							If nSld - nRes > 0
								lOkTFS	:= .F.
								cMens02	+= If( !Empty(cMens02), CRLF, "" )
								//se existir saldo a retornar, avisar o usuário...
								cMens02	+=	STR0024 + " [" + AllTrim(aCmpTFS[nInd][5]) + "] " +;	//"MI-Item:"
												cTitTFSPrd + " [" + AllTrim(aCmpTFS[nInd][1]) + "-" + AllTrim(aCmpTFS[nInd][6]) + "] " +;
												cTitTFSQtde + " [" + AllTrim(Transform(nSld,cPicTFSQtde)) + "]"
							Endif
						Endif
					Else
						nRes	:= aCmpTFS[nInd][4]
						nQuant	:= aCmpTFS[nInd][2]
						cTpMov	:= aCmpTFS[nInd][3]
						cItem 	:= aCmpTFS[nInd][5]
						cProd 	:= aCmpTFS[nInd][1]
						cDesc	:= aCmpTFS[nInd][6]
	
						If cTpMov == "1"
							nSld	+= nQuant
						Elseif cTpMov == "2"
							nSld	-= nQuant
						Endif

						//se for o último registro
						If nInd == len(acmpTFS)
							If nSld - nRes > 0
								lOkTFS	:= .F.
								cMens02	+= If( !Empty(cMens02), CRLF, "" )
								//se existir saldo a retornar, avisar o usuário...
								cMens02	+=	STR0024 + " [" + AllTrim(aCmpTFS[nInd][5]) + "] " +;	//"MI-Item:"
												cTitTFSPrd + " [" + AllTrim(aCmpTFS[nInd][1]) + "-" + AllTrim(aCmpTFS[nInd][6]) + "] " +;
												cTitTFSQtde + " [" + AllTrim(Transform(nSld,cPicTFSQtde)) + "]"
							Endif
						Endif
					Endif
				
					cProduto	:= aCmpTFS[nInd][1]
				
				Next nInd
					
				nRes	:= 0
				nQuant	:= 0
				cTpMov	:= ""
				cItem 	:= ""
				cProd 	:= ""
				cDesc	:= ""

				If	!Empty(cMens02)
					If Empty(cMensLocal)
						cMensLocal	+= If( !Empty(cMens), CRLF + CRLF, "" )
						cMensLocal	+=	STR0004 + AllTrim(oMdlTFL:GetValue("TFL_CODIGO")) + " "+;
										STR0005 + AllTrim(oMdlTFL:GetValue("TFL_LOCAL")) + "-"+;
										AllTrim(oMdlTFL:GetValue("TFL_DESLOC")) + CRLF // Código: " "- Posto: "
						cMens 	+= cMensLocal
					Endif						
					cMens	+= If( !Empty(cMens), CRLF, "" )
					cMens	+= STR0022 + CRLF + CRLF	//"Os materiais de implantação abaixo estão pendentes de retorno:"
					cMens	+= cMens02 + CRLF
				EndIf

			Endif
		Next nLinTFF
	EndIf

	If	!( oMdlTFI:IsEmpty() )
		//verificar os itens de locação
		For nLinTFI := 1 to oMdlTFI:Length()
			oMdlTFI:GoLine(nLinTFI)
			If oMdlTFI:GetValue("OK")
				//verificar equipamentos não retornados
				cTmpTEW	:= GetNextAlias()
				BeginSql Alias cTmpTEW
					Select TEW.TEW_CODEQU, TEW.TEW_PRODUT, TEW.TEW_BAATD, SB1.B1_DESC, TEW.TEW_DTRFIM, TFI.TFI_COD, TFI.TFI_ITEM
					  From %table:TEW% TEW
					       Inner join %table:TFI% TFI on TFI.TFI_FILIAL = %xFilial:TFI%
					                                 AND TFI.%NotDel%
					                                 AND TFI.TFI_COD = TEW.TEW_CODEQU
					       Inner join %table:SB1% SB1 on SB1.B1_FILIAL = %xFilial:SB1%
					                                 AND SB1.%NotDel%
					                                 AND SB1.B1_COD = TEW.TEW_PRODUT
					 Where TEW.TEW_FILIAL = %xFilial:TEW%
					   AND TEW.%NotDel%
					   AND TEW.TEW_CODEQU = %exp:oMdlTFI:GetValue("TFI_COD")%
					   AND TEW.TEW_DTSEPA <> ''
					   AND TEW.TEW_DTRFIM = ''
				EndSql

				DbSelectArea(cTmpTEW)
				(cTmpTEW)->( DbGoTop() )
				If	(cTmpTEW)->( ! Eof() )
					lOkTEW	:= .F.
					If Empty(cMensLocal)
						cMensLocal	+= If( !Empty(cMens), CRLF + CRLF, "" )
						cMensLocal	+=	STR0004 + AllTrim(oMdlTFL:GetValue("TFL_CODIGO")) + " "+;
										STR0005 + AllTrim(oMdlTFL:GetValue("TFL_LOCAL")) + "-"+;
										AllTrim(oMdlTFL:GetValue("TFL_DESLOC")) + CRLF // Código: " "- Posto: "
						cMens 	+= cMensLocal
					Endif						
					cMens	+= If( !Empty(cMens), CRLF, "" )
					cMens	+= STR0023 + CRLF	//"Os equipamentos abaixo estão pendentes de retorno ou encontram-se separados:"
				EndIf
				While (cTmpTEW)->( ! EOF() )
					cMens	+= If( !Empty(cMens), CRLF, "" )
					cMens	+=	STR0014 + " [" + AllTrim((cTmpTEW)->TFI_ITEM) + "] " +;												//"LE - Item: "
								STR0015 + " [" + AllTrim((cTmpTEW)->TFI_COD) + "] " +;												//" - Cód.Locação: "
								STR0016 + " [" + AllTrim((cTmpTEW)->TEW_PRODUT) + "-" + AllTrim((cTmpTEW)->B1_DESC) + "] "	+;	//" prod "
								STR0025 + " [" + AllTrim((cTmpTEW)->TEW_BAATD) + "] "												//"Núm.Série:"
					(cTmpTEW)->(dBSkip())
				Enddo
				(cTmpTEW)->(DbCloseArea())
			Endif
		Next nLinTFI
	EndIf
Next nLinTFL

lRet := ( lOkTFF .And. lOkTFS .And. lOkTEW )

If lRet
	For nLinTFL := 1 to oMdlTFL:Length()		//encerrar os locais
		oMdlTFL:GoLine(nLinTFL)

		// Prepara o encerramento dos itens de RH do local
		If	!( oMdlTFF:IsEmpty() )
			For nLinTFF := 1 to oMdlTFF:Length()
				oMdlTFF:GoLine(nLinTFF)
				oMdlTFF:SetValue("TFF_ENCE",If(oMdlTFF:GetValue("OK"),"1","2"))
			Next nLinTFF
		EndIf

		// Prepara o encerramento dos itens de locação do local
		If	!( oMdlTFI:IsEmpty() )
			For nLinTFI := 1 to oMdlTFI:Length()
				oMdlTFI:GoLine(nLinTFI)
				oMdlTFI:SetValue("TFI_ENCE",If(oMdlTFI:GetValue("OK"),"1","2"))
			Next nLinTFI
		EndIf

		// Prepara o encerramento do local
		oMdlTFL:SetValue("TFL_ENCE",If(oMdlTFL:GetValue("OK"),"1","2"))
		If	lAllMrk
			lAllMrk := oMdlTFL:GetValue("OK")
		EndIf
	Next nLinTFL

	//verificar se pode encerrar o contrato caso todos os postos estejam encerrados
	If	lAllMrk
		// Atualiza o status do Orçamento de Serviços como ENCERRADO
		oMdlTFJ:SetValue("TFJ_STATUS",DEF_TFJ_ENCERRADO)
	EndIf
Else
	AtShowLog(cMens, STR0017, .T., .T., .F.)  // "Inconsistências"
	Help( , , "At871RecPen", , STR0018, 1, 0,,,,,, {STR0019})	//"Não será possivel realizar o encerramento do posto, pois existem inconsistências que impedem tal procedimento." # "Realize as manutenções necessárias para que sejam atendidas as premissas para a efetivação do encerramento do posto." 
Endif

FWRestRows( aSaveLines )
SX3->(RestArea(aOldSX3))
(cOldAlias)->(RestArea(aOldAlias))
dBSelectArea(cOldAlias)
Return lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} InitDados
Inicializa as informações 
@sample 	InitDados()
@param  	oModel, Objeto, objeto geral do model que será alterado
@return	Nil 
@author 	Serviços
@since		19/06/2015
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function InitDados(oModel)

Local oMdlTFL 	:= oModel:GetModel("TFLDETAIL") 
Local oMdlTFF 	:= oModel:GetModel("TFFDETAIL")
Local oMdlTFI 	:= oModel:GetModel("TFIDETAIL")
Local aSaveLines	:= FWSaveRows()
Local nI			:= 0

If IsBlind()
	//inicia TFL
	For nI := 1 to oMdlTFL:Length()
		oMdlTFL:GoLine(nI)
		oMdlTFL:SetValue("OK",.T.)
	Next nI

	//inicia a TFF
	If	!( oMdlTFF:IsEmpty() )
		For nI := 1 to oMdlTFF:Length()
			oMdlTFF:GoLine(nI)
			oMdlTFF:SetValue("OK",.T.)	
		Next nI
	EndIf

	//inicia a TFI
	If	!( oMdlTFI:IsEmpty() )
		For nI := 1 to oMdlTFI:Length()
			oMdlTFI:GoLine(nI)
			oMdlTFI:SetValue("OK",.T.)	
		Next nI
	EndIf
Else
	//inicia TFL
	For nI := 1 to oMdlTFL:Length()
		oMdlTFL:GoLine(nI)
		If oMdlTFL:GetValue("TFL_ENCE") == "1"
			oMdlTFL:SetValue("OK",.T.)
		Endif
	Next nI

	//inicia a TFF
	If	!( oMdlTFF:IsEmpty() )
		For nI := 1 to oMdlTFF:Length()
			oMdlTFF:GoLine(nI)
			If oMdlTFF:GetValue("TFF_ENCE") == "1" 
				oMdlTFF:SetValue("OK",.T.)
			Endif	
		Next nI
	EndIf

	//inicia a TFI
	If	!( oMdlTFI:IsEmpty() )
		For nI := 1 to oMdlTFI:Length()
			oMdlTFI:GoLine(nI)
			If oMdlTFI:GetValue("TFI_ENCE") == "1"
				oMdlTFI:SetValue("OK",.T.)
			Endif	
		Next nI
	EndIf
EndIf

FWRestRows( aSaveLines )
Return


//------------------------------------------------------------------------------
/*/{Protheus.doc} At871Commit
Atualiza as informações na base de dados 
@sample 	At871Commit(oMdl)
@param  	oMdl, Objeto, objeto geral do model que será alterado
@return	Nil 
@author 	Alexandre da Costa
@since		30/03/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function At871Commit(oMdl)
Local	lRet		:=	.T.
Local	cContrato	:=	oMdl:GetModel("TFJMASTER"):GetValue("TFJ_CONTRT")
Local	cRevisao	:=	oMdl:GetModel("TFJMASTER"):GetValue("TFJ_CONREV")
Local   cOrcSrv     :=  oMdl:GetModel("TFJMASTER"):GetValue("TFJ_CODIGO")
Local   lSrvExt     := Empty(cContrato) //IsInCallStack("TECA870A")
If	oMdl:GetModel("TFJMASTER"):GetValue("TFJ_STATUS") == DEF_TFJ_ENCERRADO
	lRet := At870NwSit(cContrato, cRevisao, DEF_TFJ_ENCERRADO, .F.,,cOrcSrv,lSrvExt)
EndIf
lRet	:=	( lRet .And. FwFormCommit(oMdl) )
Return	lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At871PVTFL
Pré-validação do grid dos locais de atendimento 
@sample 	At871PVTFL(oModelGrid,cAction, nLine, cField, xValue)
@param  	oMdlTFL, Objeto, objeto geral do model que será alterado
@param  	cAction, Caracter, ação que está sendo executada 
@param  	nLine, Numérido, número da linha ativa do modelo do grid
@param  	cField, Caracter, nome do campo que está em edição
@param  	xValue, conterá o conteúdo que foi informado no campo no momento da execução desta função
@return	Nil
@author 	Alexandre da Costa
@since		13/05/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function At871PVTFL(oMdlTFL, cAction, nLine, cField, xValue)
Local oModel		:= FwModelActive()
Local oView			:= FwViewActive()
Local oMdlTFF		:= oModel:GetModel("TFFDETAIL")
Local oMdlTFI		:= oModel:GetModel("TFIDETAIL")
Local aSaveLines	:= FWSaveRows()
Local nI			:= 0
Local lRet			:= .T.

If cAction == "SETVALUE"

	If	cField == "OK"
		If At871VldDt("TFL")
			// Se o usuário marcou ou desmarcou o  LOCAL DE ATENDIMENTO, então todos os seus itens de RH e
			// LOCAÇÃO serão marcados ou desmarcados da mesma maneira.   A validação final que será a res- 
			// ponsável por indicar se tal encerramento do posto desse local de atendimento será efetivado  
			// ou não, ocorrerá na validação final do modelo, antes do COMMIT.
			//
			// Marca ou desmarca todos os itens de RH
			If	!( oMdlTFF:IsEmpty() )
				For nI := 1 to oMdlTFF:Length()
					oMdlTFF:GoLine(nI)
					If !At871VldDt("TFF")
						lRet := .F.
						Exit
					Endif
				Next nI
				If lRet
					For nI := 1 to oMdlTFF:Length()
						oMdlTFF:GoLine(nI)
						oMdlTFF:LoadValue("OK", xValue)
						At871GtDt("TFF")
					Next nI
				Endif
			EndIf
			//Marca ou desmarca todos os itens de locação
			If	!( oMdlTFI:IsEmpty() )
				For nI := 1 to oMdlTFI:Length()
					oMdlTFI:GoLine(nI)
					If !At871VldDt("TFI")
						lRet := .F.
						Exit
					Endif
				Next nI
				If lRet 
					For nI := 1 to oMdlTFI:Length()
						oMdlTFI:GoLine(nI)
						oMdlTFI:LoadValue("OK", xValue)
						At871GtDt("TFI")
					Next nI
				Endif
			EndIf
		Else
			lRet := .F.
		Endif
	EndIf
EndIf

FWRestRows( aSaveLines ) 
If !IsBlind() .And. oView <> NIL .and. oView:IsActive() .And. lRet
	oView:Refresh()
EndIf
Return lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At871PVTFF
Pré-validação do grid dos itens de RH dos locais de atendimento 
@sample 	At871PVTFF(oModelGrid,cAction, nLine, cField, xValue)
@param  	oMdlTFF, Objeto, objeto geral do model que será alterado
@param  	cAction, Caracter, ação que está sendo executada 
@param  	nLine, Numérido, número da linha ativa do modelo do grid
@param  	cField, Caracter, nome do campo que está em edição
@param  	xValue, conterá o conteúdo que foi informado no campo no momento da execução desta função
@return	Nil
@author 	Alexandre da Costa
@since		13/05/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function At871PVTFF(oMdlTFF, cAction, nLine, cField, xValue)
Local oModel		:= FwModelActive()
Local oView			:= FwViewActive()
Local oMdlTFL		:= oModel:GetModel("TFLDETAIL")
Local oMdlTFI		:= oModel:GetModel("TFIDETAIL")
Local oMdlTFF		:= oModel:GetModel("TFFDETAIL")
Local aSaveLines	:= FWSaveRows()
Local nAtLineTFF	:= oMdlTFF:GetLine()
Local nI			:= 0
Local lAllMrk		:= .T.
Local lRet			:= .T.
Local lAdcRef		:= IsInCallStack("TECA740G")//Adição de reforço
Local lAloca		:= .F.			

If cAction == "SETVALUE"

	If	cField == "OK"
		If At871VldDt("TFF")
			// Verifica se todos os itens de RH e de locação de equipamentos estão marcados ou se o registro que está sendo processado nesse
			// momento é o último que está sendo selecionado (marcado) pelo usuário. Caso afirmativo, então o registro-pai (da tabela TFL)
			// será automaticamente marcado. Caso contrário, o registro-pai será desmarcado.
			lAllMrk	:= xValue
			If	lAllMrk
				If	!( oMdlTFF:IsEmpty() )
					For nI := 1 to oMdlTFF:Length()
						oMdlTFF:GoLine(nI)
						If	nI <> nAtLineTFF .AND. !( lAllMrk := oMdlTFF:GetValue("OK") )
							EXIT
						EndIf
					Next nI
				EndIf
				If	lAllMrk .AND. !( oMdlTFI:IsEmpty() )
					For nI := 1 to oMdlTFI:Length()
						oMdlTFI:GoLine(nI)
						If	!( lAllMrk := oMdlTFI:GetValue("OK") )
							EXIT
						EndIf
					Next nI
				EndIf
			EndIf
			If !lAdcRef //Se for encerrado via TECA740G(Adicional de Reforço) não pode encerar o posto original(TFL)
				oMdlTFL:LoadValue("OK", lAllMrk)
				At871GtDt("TFL")
			EndIf
		Else
			lRet := .F.
		Endif
	EndIf
EndIf

FWRestRows( aSaveLines )
If !IsBlind() .And. oView <> NIL .and. oView:IsActive() .And. lRet
	oView:Refresh()
EndIf
Return	lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At871PVTFI
Pré-validação do grid dos itens de locação dos locais de atendimento 
@sample 	At871PVTFI(oModelGrid,cAction, nLine, cField, xValue)
@param  	oMdlTFI, Objeto, objeto geral do model que será alterado
@param  	cAction, Caracter, ação que está sendo executada 
@param  	nLine, Numérido, número da linha ativa do modelo do grid
@param  	cField, Caracter, nome do campo que está em edição
@param  	xValue, conterá o conteúdo que foi informado no campo no momento da execução desta função
@return	Nil
@author 	Alexandre da Costa
@since		13/05/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function At871PVTFI(oMdlTFI, cAction, nLine, cField, xValue)
Local oModel		:= FwModelActive()
Local oView		:= FwViewActive()
Local oMdlTFL		:= oModel:GetModel("TFLDETAIL")
Local oMdlTFF		:= oModel:GetModel("TFFDETAIL")
Local aSaveLines	:= FWSaveRows()
Local nAtLineTFI	:= oMdlTFI:GetLine()
Local nI			:= 0
Local lAllMrk		:= .T.
Local lRet			:= .T.

If cAction == "SETVALUE"

	If	cField == "OK"
		If At871VldDt("TFI")
			// Verifica se todos os itens de RH e de locação de equipamentos estão marcados ou se o registro que está sendo processado nesse
			// momento é o último que está sendo selecionado (marcado) pelo usuário. Caso afirmativo, então o registro-pai (da tabela TFL)
			// será automaticamente marcado. Caso contrário, o registro-pai será desmarcado.
			lAllMrk	:= xValue
			If	lAllMrk
				If	!( oMdlTFI:IsEmpty() )
					For nI := 1 to oMdlTFI:Length()
						oMdlTFI:GoLine(nI)
						If	nI <> nAtLineTFI .AND. !( lAllMrk := oMdlTFI:GetValue("OK") )
							EXIT
						EndIf
					Next nI
				EndIf
				If	lAllMrk .AND. !( oMdlTFF:IsEmpty() )
					For nI := 1 to oMdlTFF:Length()
						oMdlTFF:GoLine(nI)
						If	!( lAllMrk := oMdlTFF:GetValue("OK") )
							EXIT
						EndIf
					Next nI
				EndIf
			EndIf
			oMdlTFL:LoadValue("OK", lAllMrk)
			At871GtDt("TFL")
		Else
			lRet := .F.
		Endif
	EndIf
EndIf

FWRestRows( aSaveLines )
If !IsBlind() .And. oView:IsActive() .And. lRet
	oView:Refresh()
EndIf
Return	lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At871GtDt
Altera a data final quando o usuário marca/desmarca o check do encerramento de posto.
@return	.T.
@param  	cGrid, Caracter, Qual Grid esta sendo executado marca/desmarca.
@author 	Kaique Schiller
@since		04/07/2017
@version	P12
/*/
//------------------------------------------------------------------------------
Function At871GtDt(cGrid)
Local oModel 		:= FwModelActive()
Local aSaveLines	:= FWSaveRows(oModel)
Local oModelTFL 	:= Nil 
Local oModelTFF 	:= Nil 
Local oModelTFI 	:= Nil

If cGrid == "TFL"
	oModelTFL := oModel:GetModel("TFLDETAIL")
	If oModelTFL:GetValue("OK")
		oModelTFL:SetValue("TFL_FIMOLD",oModelTFL:GetValue("TFL_DTFIM"))
		oModelTFL:LoadValue("TFL_DTFIM",dDataBase)
	ElseIf !Empty(oModelTFL:GetValue("TFL_FIMOLD"))
		oModelTFL:LoadValue("TFL_DTFIM",oModelTFL:GetValue("TFL_FIMOLD"))	
	Endif

Elseif cGrid == "TFF"
	oModelTFF := oModel:GetModel("TFFDETAIL")
	If oModelTFF:GetValue("OK")
		oModelTFF:SetValue("TFF_FIMOLD",oModelTFF:GetValue("TFF_PERFIM"))
		oModelTFF:LoadValue("TFF_PERFIM",dDataBase)
	ElseIf !Empty(oModelTFF:GetValue("TFF_FIMOLD"))
		oModelTFF:LoadValue("TFF_PERFIM",oModelTFF:GetValue("TFF_FIMOLD"))		
	Endif
	
Elseif cGrid == "TFI"
	oModelTFI := oModel:GetModel("TFIDETAIL")
	If oModelTFI:GetValue("OK")
		oModelTFI:SetValue("TFI_FIMOLD",oModelTFI:GetValue("TFI_PERFIM"))
		oModelTFI:LoadValue("TFI_PERFIM",dDataBase)
	ElseIf !Empty(oModelTFI:GetValue("TFI_FIMOLD"))
		oModelTFI:LoadValue("TFI_PERFIM",oModelTFI:GetValue("TFI_FIMOLD"))
	Endif

Endif

FwRestRows(aSaveLines,oModel)

Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} At871VldDt
Query responsavel pela validação das datas do encerramento de posto.
@return	lRet
@param  	cTbl	, Caracter, Qual query será executada.
@param  	cPropos	, Caracter, código da proposta do orçamento de serviços.
@author 	Kaique Schiller
@since		04/07/2017
@version	P12
/*/
//------------------------------------------------------------------------------
Function At871VldDt(cTbl,cPropos)
Local lRet 		:= .F.
Local cTabTemp 	:= ""
Local dDataBs	:= dDataBase
Local oMdl		:= Nil
Local oMdlDtl	:= Nil
Default cTbl	:= ""
Default cPropos	:= ""

If Empty(cTbl) .And. !Empty(cPropos)
	cTabTemp 	:= GetNextAlias()
	
	BeginSql Alias cTabTemp
	
		SELECT TFL_DTFIM
		FROM %Table:TFJ% TFJ
			INNER JOIN %Table:TFL% TFL 
				ON TFL_FILIAL = %xFilial:TFL%
				AND TFJ_CODIGO = TFL_CODPAI
				AND TFL.%NotDel%
		WHERE TFJ.TFJ_PROPOS = %Exp:cPropos%
			AND TFJ.%NotDel%
			AND NOT( TFL_DTINI > %Exp:dDataBs% OR TFL_DTFIM < %Exp:dDataBs% )
	EndSql
	
	If (cTabTemp)->(!EOF())
		lRet := .T.
	EndIf
	
	(cTabTemp)->(DbCloseArea())
	
	cTabTemp 	:= GetNextAlias()
	
	BeginSql Alias cTabTemp
	
		SELECT TFF_PERFIM
		FROM %Table:TFJ% TFJ
			INNER JOIN %Table:TFL% TFL 
				ON TFL_FILIAL = %xFilial:TFL%
				AND TFJ_CODIGO = TFL_CODPAI
				AND TFL.%NotDel%
			INNER JOIN %Table:TFF% TFF 
				ON TFF_FILIAL = %xFilial:TFF%
				AND TFL_CODIGO = TFF_CODPAI 
				AND TFF.%NotDel%
		WHERE TFJ.TFJ_PROPOS = %Exp:cPropos%
			AND TFJ.%NotDel%
			AND NOT( TFF_PERINI > %Exp:dDataBs% OR TFF_PERFIM < %Exp:dDataBs% )
	
	EndSql
	
	If (cTabTemp)->(!EOF())
		lRet := .T.
	EndIf
	
	(cTabTemp)->(DbCloseArea())
	
	cTabTemp 	:= GetNextAlias()
	
	BeginSql Alias cTabTemp
	
		SELECT TFI_PERFIM
		FROM %Table:TFJ% TFJ
			INNER JOIN %Table:TFL% TFL 
				ON TFL_FILIAL = %xFilial:TFL%
				AND TFJ_CODIGO = TFL_CODPAI
				AND TFL.%NotDel%
			INNER JOIN %Table:TFI% TFI 
				ON TFI_FILIAL = %xFilial:TFI%
				AND TFL_CODIGO = TFI_CODPAI 
				AND TFI.%NotDel%
		WHERE TFJ.TFJ_PROPOS = %Exp:cPropos%
			AND TFJ.%NotDel%
			AND NOT( TFI_PERINI > %Exp:dDataBs% OR TFI_PERFIM < %Exp:dDataBs% )
	
	EndSql
	
	If (cTabTemp)->(!EOF())
		lRet := .T.
	EndIf
	
	(cTabTemp)->(DbCloseArea())

Else
	lRet 	:= .T.
	oMdl	:= FwModelActive()
	If cTbl == "TFL"
		oMdlDtl	:= oMdl:GetModel("TFLDETAIL")
		If !oMdlDtl:IsEmpty()
			If dDataBs < oMdlDtl:GetValue("TFL_DTINI") .Or. dDataBs > oMdlDtl:GetValue("TFL_DTFIM")
				Help( "", 1, "At871VldDt", , STR0028+STR0029, 1, 0,,,,,,;  // "A data base está fora do(s) período(s) do local de atendimento."
											{STR0032+STR0029})  // "Realize o encerramento de posto com a data base entre o(s) período(s)" ## "do local de atendimento."
				lRet := .F.
			Endif
		ENdif
	Elseif cTbl == "TFF"
		oMdlDtl	:= oMdl:GetModel("TFFDETAIL")
		If !oMdlDtl:IsEmpty()
			If dDataBs < oMdlDtl:GetValue("TFF_PERINI") .Or. dDataBs > oMdlDtl:GetValue("TFF_PERFIM")
				Help( "", 1, "At871VldDt", , STR0028+STR0030, 1, 0,,,,,,;  // "A data base está fora do(s) período(s) de alocação de recursos humanos."
											{STR0032+STR0030})  // "Realize o encerramento de posto com a data base entre o(s) período(s)" ## "de alocação de recursos humanos."
				lRet := .F.
			Endif
		Endif
	Elseif cTbl == "TFI"
		oMdlDtl	:= oMdl:GetModel("TFIDETAIL")
		If !oMdlDtl:IsEmpty()
			If dDataBs < oMdlDtl:GetValue("TFI_PERINI") .Or. dDataBs > oMdlDtl:GetValue("TFI_PERFIM")
				Help( "", 1, "At871VldDt", , STR0028+STR0031, 1, 0,,,,,,;  // "A data base está fora do(s) período(s) de locação de equipamento."
											{STR0032+STR0031})  // "Realize o encerramento de posto com a data base entre o(s) período(s)" ## "de locação de equipamento."
				lRet := .F.
			Endif
		Endif
	Endif
Endif

Return lRet