#include "TECA580C.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

//----------------------------------------------------------
/*/{Protheus.doc} TECA580C()
Relacionamentos - Gestão de Escalas 

@Return 	nil
@author 	Serviços
@since 		15/05/2014
/*/
//----------------------------------------------------------
Function TECA580C() 
Local oBrowse 

oBrowse := FwMBrowse():New()
oBrowse:SetAlias("TFF")
oBrowse:SetDescription(STR0001) // STR0001//"Relacionamento"
oBrowse:DisableDetails()
oBrowse:Activate()

Return(Nil) 

//----------------------------------------------------------
/*/{Protheus.doc} MenuDef()
MenuDef - Relacionamentos - Gestão de Escalas 

@Return 	MenuDef
@author 	Serviços
@since 		14/05/2014
/*/
//----------------------------------------------------------
Static Function MenuDef()
Local aRotina := {}

aRotina := FWMVCMenu( 'TECA580C' )

Return(aRotina)

//----------------------------------------------------------
/*/{Protheus.doc} ModelDef()
Model - Relacionamentos - Gestão de Escalas 

@Return 	model
@author 	Serviços
@since 		14/05/2014
/*/
//----------------------------------------------------------
Static Function ModelDef()
Local oModel		:= Nil
Local oStrTFF 	:= FWFormStruct(1,"TFF") 
Local bCommit		:= {|oModel|Tec580GrvC(oModel)}

oModel := MPFormModel():New("TECA580C", /*bPreValidacao*/,/*bPosValidacao*/,bCommit,/*bCancel*/ )

oStrTFF:SetProperty('TFF_PRODUT',MODEL_FIELD_WHEN ,{||.F.})
oStrTFF:SetProperty('TFF_ESCALA',MODEL_FIELD_WHEN ,{||At680Perm( Nil, __cUserID, "014" )})
oStrTFF:SetProperty("TFF_DESCRI",MODEL_FIELD_INIT,{||Posicione("SB1",1,xFilial("SB1")+TFF->TFF_PRODUT,"B1_DESC")})
oStrTFF:SetProperty("TFF_NOMESC",MODEL_FIELD_INIT,{||POSICIONE("TDW",1,xFilial("TDW")+TFF->TFF_ESCALA,"TDW_DESC") })

oModel:AddFields("TFFMASTER",/*cOwner*/,oStrTFF, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

oModel:SetDescription(STR0002) // STR0002 									  //"Relacionamento"

Return(oModel)


//----------------------------------------------------------
/*/{Protheus.doc} ViewDef()
View - Relacionamentos - Gestão de Escalas 

@Return 	view
@author 	Serviços
@since 		15/05/2014
/*/
//----------------------------------------------------------
Static Function ViewDef()

Local oView
Local oModel   	:= FWLoadModel("TECA580C")  
Local oStrTFF	:= FwFormStruct(2,"TFF", {|cCpo| AllTrim(cCpo)$'TFF_CONTRT+TFF_PRODUT+TFF_DESCRI+TFF_LOCAL+TFF_ESCALA+TFF_NOMESC' } )

oView := FWFormView():New()
oView:SetModel(oModel)

oView:AddField("VIEW_TFF",oStrTFF,"TFFMASTER")

oView:CreateHorizontalBox( "TELA" , 100 )
oView:SetOwnerView( "VIEW_TFF", "TELA" ) 

//Fechar a janela apos a gravação
oView:SetCloseOnOk({|| .T.} )

Return(oView)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Tec580GrvC

Gravação do Model

@author 	Serviços
@since 		08/04/2014
@version 	P12

/*/
//--------------------------------------------------------------------------------------------------------------------
Function Tec580GrvC(oModel)
Local nOpcx		:= oModel:GetOperation()
Local aArea		:= GetArea()
Local lRet			:= .T.
Local lRecLock	:= .F.
Local lSrvExt   := At580BSrvExt()
Local cContrt   := ""
Local cCodEscala := oModel:GetModel("TFFMASTER"):GetValue("TFF_ESCALA")
Local cErroRet 	:= ""

If nOpcx == MODEL_OPERATION_UPDATE .And. IsInCallStack('Tx580PxE')
	
	If lSrvExt
		cContrt := PadR( Posicione("TFL",1,FWxFilial("TFL")+TFF->TFF_CODPAI,"TFL_CODPAI"), TamSX3("TFF_CONTRT")[1] )
	Else
		cContrt := TFF->TFF_CONTRT
	EndIf
	
	//Verifica se existe configuração de alocação criado para o contrato
	lRecLock := At580VldTFF( cContrt, TFF->TFF_COD, TFF->TFF_FILIAL, lSrvExt ) 

	//Calcula o saldo para atualizar a ABQ
	nHoras := TecCalcEsc( cCodEscala )
	
	//Atualiza a ABQ
	lRet := Tec580GrABQ(nHoras,lRecLock)

	// Atualiza os benefícios vinculados
	lRet := lRet .And. At352AtVin( TFF->TFF_FILIAL, TFF->TFF_COD, cCodEscala, @cErroRet )
	// em caso de erro, define o motivo do erro
	If !lRet .And. !Empty(cErroRet)
		oModel:GetModel():SetErrorMessage( oModel:GetId() ,"TFF_ESCALA" ,"TFFMASTER", "TFF_ESCALA" , cCodEscala, cErroRet, "" )
	EndIf
	
	lRet := lRet .And. FwFormCommit( oModel )
	
	If lRet 
		If !IsBlind()
			Aviso( STR0003, STR0004, { STR0005 }, 2 )//"Atenção"//"Escala Atualizada com sucesso!"//"OK"
		EndIf
	EndIf
EndIf

RestArea(aArea)

Return(lRet)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At580VldTFF
	
Valida se existe o recurso ja criado na configuração de alocação do atendente

@sample 	At580VldTFF(cContrato,cCodTFF,cFilTFF)

@since		26/06/2014      
@version	P119

@return 	lRet, Lógico, retorna .T. se data for válida.

@param  	cContrato, Caracter, Numero do contrato para a consistencia.
@param  	cCodTFF, Caracter, codigo do recurso para a consistencia.
@param  	cFilTFF, Caracter, filial do recurso para a consistencia.
@param  	lSrvExt, Logico ,  Indica se é um posto originado a partir de um serviço extra.

/*/
//------------------------------------------------------------------------------
Static Function At580VldTFF( cContrato, cCodTFF, cFilTFF, lSrvExt )

Local lRet    := .T.
Local aArea   := GetArea()
Local lFilTFF := FindFunction("ExistFilTFF") .And. ExistFilTFF()
Local cOrigem := ""

If lSrvExt
	cOrigem := "TFJ"
Else
	cOrigem := "CN9"
EndIf

dbSelectArea("ABQ")
ABQ->(dbSetOrder(2))

If ABQ->(dbSeek(xFilial("ABQ")+cContrato+cOrigem))
		
	While ABQ->(!Eof()) .And. ABQ->ABQ_FILIAL == xFilial("ABQ") .And. ;
		  	ABQ->ABQ_CONTRT == cContrato .And. ABQ->ABQ_ORIGEM == cOrigem

		IF !lFilTFF	
			If ABQ->ABQ_CODTFF == cCodTFF
				lRet := .F.
				Exit
			EndIf
		ELSE
			If (ABQ->ABQ_CODTFF == cCodTFF) .AND. (ABQ->ABQ_FILTFF == cFilTFF)
				lRet := .F.
				Exit
			EndIf
		ENDIF

		ABQ->(dbSkip())
	
	EndDo
	
EndIf	

RestArea(aArea)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Tx580PxE

Realiza o Calculo das horas comparando a escala com o criacalend

@author 	Serviços
@since 		08/04/2014
@version 	P12

/*/
//--------------------------------------------------------------------------------------------------------------------
Function TecCalcEsc(cEscala)
Local nHoras	:= 0
Local aTurno		:= {}
Local nX			:= 0
Local nI			:= 0
Local nTotHrsEst	:= 0
Local nTotHrEsc	:= 0
Local aHoraEsc	:= {}
Local lReturn		:= .F.
Local aTabPadrao	:= {}
Local aTabCalend	:=	{}
Local aExcePer	:=	{}
Local nPos			:= 0

Default cEscala := ""

//Verificar quais os turnos estão configurados na escala
DbSelectArea("TDW")
TDW->(DbSetOrder(1))
	
If TDW->(DbSeek(xFilial("TDW") + cEscala ))
	DbSelectArea("TDX")
	TDX->(DbSetOrder(2))
	If TDX->(DbSeek(xFilial("TDX") + TDW->TDW_COD))
		While !TDX->(Eof()) .AND. TDX->TDX_FILIAL == xFilial("TDX") .AND. TDX->TDX_CODTDW == TDW->TDW_COD .AND. TDX->TDX_TIPO == "1"
			Aadd(aTurno,{TDX->TDX_COD,TDX->TDX_TURNO,TDX->TDX_SEQTUR})
			TDX->(DbSkip())
		End
	EndIf
		
EndIf
	
DbSelectArea("TGW")
TGW->(DbSetOrder(2))	
	
For nI := 1 To Len(aTurno)
	//Calcula o intervalo e a folga na escala
	If TGW->(DbSeek(xFilial("TGW") + aTurno[nI][1]))
		While !TGW->(Eof()) .AND. TGW->TGW_FILIAL == xFilial("TGW") .AND. TGW->TGW_EFETDX == aTurno[nI][1]
			If (TGW->TGW_STATUS == "2" .Or. TGW->TGW_STATUS == "3") .And. !Empty(TGW_COBTDX)
				Aadd(aHoraEsc,{TGW->TGW_DIASEM,TxAjtHoras((TGW->TGW_HORFIM - TGW->TGW_HORINI))})
			EndIF
				
			TGW->(DbSkip())	
		End
			
	EndIf
		
	lReturn := CriaCalend(TFF->TFF_PERINI,TFF->TFF_PERFIM,aTurno[nI][2],aTurno[nI][3],@aTabPadrao,@aTabCalend,xFilial("SR6"),,,,aExcePer)
	If lReturn
		For nX := 1 To Len(aTabCalend)
			If aTabCalend[nX][4] == "1E"
				nPos := Ascan(aHoraEsc,{ |x| x[1] == cValToChar(Dow(aTabCalend[nX][1])) })
				If nPos > 0
					nTotHrEsc += aHoraEsc[nPos][2]
				EndIf
			EndIf
				
			If aTabCalend[nX][6] == "S"					
				If Substr(aTabCalend[nX][4],2,1) == "E"
					nTotHrsEst += TxAjtHoras(aTabCalend[nX][7])
				ElseIf Substr(aTabCalend[nX][4],2,1) == "S"  
					nTotHrsEst += TxAjtHoras(aTabCalend[nX][9])	
				EndIf
			EndIf	
		Next nX
	EndIf
	
Next nI
	
nHoras := nTotHrEsc + nTotHrsEst

Return(nHoras)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Tx580PxE

Atualiza a Tabela ABQ - Configuração de Alocação

@author 	Serviços
@since 		08/04/2014
@version 	P12

/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function Tec580GrABQ(nHoras,lRecLock)
Local lRet 	:= .F.
Local nSaldo := 0

Default nHoras := 0

If !lRecLock
	//Calcula o Saldo
	nSaldo := ABQ->ABQ_TOTAL - ABQ->ABQ_SALDO
	
	BEGIN TRANSACTION
		RecLock("ABQ", lRecLock)
			ABQ->ABQ_HRSEST	:=	nHoras
			ABQ->ABQ_TOTAL	:= ABQ->ABQ_FATOR*nHoras
			ABQ->ABQ_SALDO	:= ABQ->ABQ_TOTAL - nSaldo
		ABQ->(MsUnlock())	
	END TRANSACTION
	
	lRet := .T.
	
EndIf

Return(lRet)
