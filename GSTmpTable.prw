#INCLUDE 'TOTVS.CH'
#INCLUDE "PARMTYPE.CH"
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE "FWEVENTVIEWCONSTS.CH"

Function GsTmpTable()
Return

//-----------------------------------------------------------------
/*/{Protheus.doc} Classe GSTmpTable
@description	Classe para tabelas tempor�rias do Gest�o de Servi�os
@author		Alexandre da Costa (a.costa)
@since			30/11/2016
@version		V12.15
/*/
//--------------------------------------------------------------------

Class GSTmpTable

	Data cAliasTmp				AS Character
	Data lAvailable				AS Logical
	Data lCreateTMPTable			AS Logical
	Data lError					AS Logical
	Data nStepCommitInsert		AS Numeric
	Data aStruct					AS Array
	Data aIndex					AS Array
	Data aData						AS Array
	Data aInitPad					AS Array
	Data nPosData					AS Numeric
	Data nMaxPosData				AS Numeric
	Data oTempTable				AS Object
	Data aTempTableInfo			AS Array
	Data aError					AS Array

	//-- M�todo de inicializa��o
	Method New()

	//-- M�todos operacionais
	Method CreateTMPTable()
	Method GetObjTMPTable()
	Method SetProp()
	Method GetProp()
	Method Seek()
	Method Insert()
	Method Update()
	Method Delete()
	Method GetValue()
	Method Commit()
	Method Close()

	//-- M�todo para teste das informa��es j� comitadas na tabela tempor�ria
	Method ShwTmpTable()

	//-- M�todo para exibi��o das mensagens de erro do objeto
	Method AddError()
	Method ShowErro()

EndClass

//-----------------------------------------------------------------
/*/{Protheus.doc} New() (M�todo da Classe GSTmpTable)
@description	M�todo construtor da classe
@author		Alexandre da Costa (a.costa)
@since			30/11/2016
@version		V12.15
/*/
//--------------------------------------------------------------------
Method New(cAliasTmp, aStruct, aIndex, aInitPad, nStepCommitInsert) Class GSTmpTable

Local cMsgError				:= "N�o foi poss�vel executar o m�todo 'New'"
Local cSolution				:= ""
Local nInd						:= 0
Local nInd2					:= 0
Local nPos						:= 0
Local lError					:= .F.

Default cAliasTmp				:= GetNextAlias()
Default aStruct				:= {}
Default aIndex				:= {}
Default aInitPad				:= {}
Default nStepCommitInsert	:= 500

If	ValType(cAliasTmp) <> "C"
	cAliasTmp					:= GetNextAlias()
EndIf

Self:cAliasTmp				:= cAliasTmp
Self:lAvailable				:= .F.
Self:lCreateTMPTable			:= .F.
Self:lError					:= .F.
Self:nStepCommitInsert		:= If( ValType(nStepCommitInsert) <> "N" .OR. nStepCommitInsert <= 0, 500, nStepCommitInsert )
Self:aStruct					:= {}
Self:aIndex					:= {}
Self:aInitPad					:= {}
Self:aData						:= {}
Self:nPosData					:= 0
Self:nMaxPosData				:= 0
Self:oTempTable				:= NIL
Self:aTempTableInfo			:= {}
Self:aError					:= {}

If	! lError
	If	ValType(aStruct) == "A" .AND. Len(aStruct) >= 1
		For nInd := 1 to Len(aStruct)
			If	( Len(aStruct[nInd]) <> 4 )                                                                                               .OR.;
				( ValType(aStruct[nInd][01]) <> "C" .OR. Len(AllTrim(aStruct[nInd][01])) == 0 .OR. Len(AllTrim(aStruct[nInd][01])) > 10 ) .OR.;
				( ValType(aStruct[nInd][02]) <> "C" .OR. Len(AllTrim(aStruct[nInd][02])) <> 1 )                                           .OR.;
				( ValType(aStruct[nInd][03]) <> "N" .OR. aStruct[nInd][03] <= 0 )                                                         .OR.;
				( ValType(aStruct[nInd][04]) <> "N" .OR. aStruct[nInd][04] < 0 )                                                          .OR.;
				( aStruct[nInd][02] == "N" .AND. ( aStruct[nInd][03] > 18 .OR. (aStruct[nInd][03] == 1 .And. aStruct[nInd][04] != 0) .OR. (aStruct[nInd][03] != 1 .And. aStruct[nInd][04] >= ( aStruct[nInd][03] - 1 ) )) ) .OR.;
				( aStruct[nInd][02] == "D" .AND. ( aStruct[nInd][03] <> 8 .OR. aStruct[nInd][04] <> 0 ) )                                 .OR.;
				( aStruct[nInd][02] == "L" .AND. ( aStruct[nInd][03] > 1  .OR. aStruct[nInd][04] <> 0 ) )
				lError		:= .T.
				cSolution	:= "Verifique a defini��o da estrutura para a tabela tempor�ria."
				EXIT
			EndIf
			aAdd(Self:aStruct, aStruct[nInd])
		Next nInd
	Else
		lError		:= .T.
		cSolution	:= "Verifique a defini��o da estrutura para a tabela tempor�ria."
	EndIf
EndIf
If	lError
	Self:aStruct		:= {}
EndIf

If	! lError
	If	! Empty(aIndex)
		If	ValType(aIndex) == "A"
			For nInd := 1 to Len(aIndex)
				If	ValType(aIndex[nInd]) == "A"
					If	ValType(aIndex[nInd][01]) <> "C"    .OR. Empty(AllTrim(aIndex[nInd][01]))    .OR.;
						Len(AllTrim(aIndex[nInd][01])) > 10 .OR. ( " " $ AllTrim(aIndex[nInd][01]) )	.OR.;
						ValType(aIndex[nInd][02]) <> "A"    .OR. Len(aIndex[nInd][02]) == 0
						lError		:= .T.
						EXIT
					EndIf
					For nInd2 := 1 to Len(aIndex[nInd][02])
						If	( " " $ AllTrim(aIndex[nInd][02][nInd2]) ) .OR.;
							Empty(aIndex[nInd][02][nInd2])             .OR.;
							( aScan(Self:aStruct,{|x| AllTrim(x[01]) == AllTrim(aIndex[nInd][02][nInd2])}) == 0 )
							lError		:= .T.
							EXIT
						EndIf
					Next nInd2
					If	lError
						EXIT
					EndIf
					aAdd(Self:aIndex, aIndex[nInd])
				Else
					lError	:= .T.
					EXIT
				EndIf
			Next nInd
		Else
			lError		:= .T.
		EndIf
		If	lError
			cSolution		:= "Verifique a defini��o dos �ndices para a tabela tempor�ria."
			Self:aIndex	:= {}
		EndIf
	EndIf
EndIf

If	! lError
	If	! Empty(aInitPad)
		aChkArray	:= ChkInfArray(Self:aStruct, aInitPad)
		If	aChkArray[01]
			For nInd := 1 to Len(aInitPad)
				If	ValType(aInitPad[nInd]) <> "A" .OR. ValType(aInitPad[nInd][01]) <> "C"                       .OR.;
					Empty(aInitPad[nInd][01])      .OR. ( " " $ AllTrim(aInitPad[nInd][01]) )                    .OR.;
					( ( nPos := aScan(Self:aStruct,{|x| AllTrim(x[01]) == AllTrim(aInitPad[nInd][01])}) ) == 0 ) .OR.;
					ValType(aInitPad[nInd][02]) <> aStruct[nPos][02]
					lError	:= .T.
					EXIT
				EndIf
				aAdd(Self:aInitPad, aInitPad[nInd])
			Next nInd
		Else
			lError	:= .T.
		EndIf
		If	lError
			cSolution		:= "Verifique a defini��o dos inicializadores padr�es para a tabela tempor�ria."
			Self:aInitPad	:= {}
		EndIf
	EndIf
EndIf

If	lError
	Self:AddError(cMsgError, cSolution, "")
EndIf

Self:lAvailable	:= !( Self:lError )
Return

//-----------------------------------------------------------------
/*/{Protheus.doc} CreateTMPTable() (M�todo da Classe GSTmpTable)
@description	M�todo respons�vel pela cria��o da tabela tempor�ria
@author		Alexandre da Costa (a.costa)
@since			30/11/2016
@version		V12.15
/*/
//--------------------------------------------------------------------
Method CreateTMPTable() Class GSTmpTable

Local aOldArea	:= GetArea()
Local cMsgError	:= "N�o foi poss�vel executar o m�todo 'CreateTMPTable'"
Local cSolution	:= ""
Local oTempTable	:= NIL
Local nInd			:= 0
Local lRet			:= .F.

If	Self:lAvailable
	If	! Self:lError
		If	! Self:lCreateTMPTable

			oTempTable := FWTemporaryTable():New(Self:cAliasTmp)
			oTempTable:SetFields(Self:aStruct)
			For nInd := 1 to Len(Self:aIndex)
				oTempTable:AddIndex(Self:aIndex[nInd][01], Self:aIndex[nInd][02])
			Next nInd
			oTempTable:Create()

			If	( lRet := ( ValType(oTempTable) == "O" ) )
				Self:lCreateTMPTable		:= .T.
				Self:oTempTable			:= oTempTable
				aAdd(Self:aTempTableInfo, oTempTable:GetAlias())
				aAdd(Self:aTempTableInfo, oTempTable:GetRealName())
			Else
				cSolution	:= "Problemas na execu��o da 'FWTemporaryTable()'"
			EndIf

		Else
			cSolution	:= "N�o � poss�vel criar mais de uma tabela tempor�ria no mesmo objeto 'GsTmpTable'"
		EndIf
	Else
		cSolution	:= "Existem erros anteriores a este procesamento."
	EndIf
Else
	cSolution	:= "Objeto n�o est� dispon�vel."
EndIf

If	! lRet
	Self:AddError(cMsgError, cSolution, "")
EndIf

RestArea(aOldArea)
Return lRet


//-----------------------------------------------------------------
/*/{Protheus.doc} GetObjTMPTable() (M�todo da Classe GSTmpTable)
@description	M�todo respons�vel por retornar o objeto da tabela tempor�ria criada
@author		Alexandre da Costa (a.costa)
@since			30/11/2016
@version		V12.15
/*/
//--------------------------------------------------------------------
Method GetObjTMPTable() Class GSTmpTable

Return Self:oTempTable

//-----------------------------------------------------------------
/*/{Protheus.doc} SetProp() (M�todo da Classe GSTmpTable)
@description	M�todo respons�vel por realizar a configura��o das propriedades que s�o dispon�veis do objeto
@author		Alexandre da Costa (a.costa)
@since			30/11/2016
@version		V12.15
/*/
//--------------------------------------------------------------------
Method SetProp(cProp, xValue) Class GSTmpTable

Local cMsgError	:= "N�o foi poss�vel executar o m�todo 'SetProp'"
Local cSolution	:= ""
Local lRet			:= .F.

Default cProp		:= ""
Default xValue	:= NIL

If	Self:lAvailable
	If	! Self:lError

		cProp	:= AllTrim(cProp)
		Do Case
			Case	AllTrim(cProp) == "STEP_COMMIT_INSERT"
					If	( lRet := ( ValType(xValue) == "N" ) )
						Self:nStepCommitInsert	:= If( xValue <= 0, 500, xValue )
					Else
						cSolution	:= "Nesta propriedade do objeto s�o aceitos somente valores num�ricos."
					EndIf
			Case	AllTrim(cProp) == "POS_DATA"
					If ( lRet := ( ValType(xValue) == "N" ) )
						If ( lRet := ( xValue >= 0 .AND. xValue <= Self:nMaxPosData ) )
							Self:nPosData	:= If( xValue > 0, xValue, Self:nPosData )
						Else
							cSolution		:= "O valor sugerido para a propriedade 'POS_DATA' deve ser menor ou igual ao valor m�ximo de 'registros' existentes no objeto (Propriedade 'QTY_DATA')."
						EndIf
					Else
						cSolution			:= "A propriedade 'POS_DATA' aceita somente valores num�ricos."
					EndIf
			Otherwise
					cSolution				:= "Verifique as propriedades dispon�veis."
		EndCase

	Else
		cSolution	:= "Existem erros anteriores a este procesamento."
	EndIf
Else
	cSolution	:= "Objeto n�o est� dispon�vel."
EndIf

If	! lRet
	Self:AddError(cMsgError, cSolution, "")
EndIf
Return lRet


//-----------------------------------------------------------------
/*/{Protheus.doc} GetProp() (M�todo da Classe GSTmpTable)
@description	M�todo respons�vel por retornar a informa��o das propriedades que s�o dispon�veis do objeto
@author		Alexandre da Costa (a.costa)
@since			30/11/2016
@version		V12.15
/*/
//--------------------------------------------------------------------
Method GetProp(cProp) Class GSTmpTable

Local cMsgError	:= "N�o foi poss�vel executar o m�todo 'GetProp'"
Local cSolution	:= ""
Local lError		:= .F.
Local xRet			:= NIL

Default cProp		:= ""

If	Self:lAvailable
	cProp		:= AllTrim(cProp)
	If	cProp == "ERROR"
		xRet	:= Self:lError
	Else
		If	! Self:lError
			Do Case
				Case	cProp == "ALIASTMP"
						xRet	:= Self:cAliasTmp
				Case	cProp == "AVAILABLE"
						xRet	:= Self:lAvailable
				Case	cProp == "CREATE_TMP_TABLE"
						xRet	:= Self:lCreateTMPTable
				Case	cProp == "STEP_COMMIT_INSERT"
						xRet	:= Self:nStepCommitInsert
				Case	cProp == "POS_DATA"
						xRet	:= Self:nPosData
				Case	cProp == "QTY_DATA"
						xRet	:= Self:nMaxPosData
				Case	cProp == "REAL_NAME_TEMPTABLE"
						xRet	:= If( Self:lAvailable .AND. Self:lCreateTMPTable, Self:aTempTableInfo[02], "" )
				Otherwise
						cSolution	:= "Verifique as propriedades dispon�veis."
						lError		:= .T.
			EndCase
		Else
			cSolution	:= "Existem erros anteriores a este procesamento."
			lError		:= .T.
		EndIf
	EndIf
Else
	cSolution	:= "Objeto n�o est� dispon�vel."
	lError		:= .T.
EndIf

If	lError
	Self:AddError(cMsgError, cSolution, "")
EndIf
Return xRet


//-----------------------------------------------------------------
/*/{Protheus.doc} Insert (M�todo da Classe GSTmpTable)
@description	M�todo respons�vel por adicionar 'registros' na estrutura do objeto.
				Este m�todo n�o efetiva o registro na tabela tempor�ria.
@author		Alexandre da Costa (a.costa)
@since			30/11/2016
@version		V12.15
/*/
//--------------------------------------------------------------------
Method Insert(aInsert) Class GSTmpTable

Local cMsgError	:= "N�o foi poss�vel executar o m�todo 'Insert'"
Local cSolution	:= ""
Local aNewData	:= {}
Local nInd			:= 0
Local nPos			:= 0
Local lError		:= .F.
Local lRet			:= .F.
Local aChkArray	:= {}

Default aInsert	:= {}

If	Self:lAvailable
	If	! Self:lError

		aChkArray	:= ChkInfArray(Self:aStruct, aInsert)
		If	aChkArray[01]
			For nInd := 1 to Len(Self:aStruct)
				If	( nPos	:= aScan(aInsert, {|x| AllTrim(x[01]) == AllTrim(Self:aStruct[nInd][01])}) ) > 0
					// Se o campo da estrutura possuir um valor recebido atrav�s do par�metro do m�todo, assume o valor sugerido
					aAdd(aNewData, aInsert[nPos][02])
				ElseIf ( nPos	:= aScan(Self:aInitPad, {|x| AllTrim(x[01]) == AllTrim(Self:aStruct[nInd][01])}) ) > 0
					// Se o campo da estrutura possuir um inicializador padr�o, assume o valor sugerido da propriedade de 'inicializadores padr�es' do objeto
					aAdd(aNewData, Self:aInitPad[nPos][02])
				Else
					// Se o campo da estrutura n�o possuir valor sugerido (via par�metro) e nem um inicializador padr�o, assume o valor 'default' de acordo com o tipo do campo
					If	Self:aStruct[nInd][02] == "C"
						aAdd(aNewData, Space(Self:aStruct[nInd][03]))
					ElseIf	Self:aStruct[nInd][02] == "M"
						aAdd(aNewData, "")
					ElseIf	Self:aStruct[nInd][02] == "N"
						aAdd(aNewData, 0)
					ElseIf	Self:aStruct[nInd][02] == "D"
						aAdd(aNewData, CtoD(Space(08)))
					ElseIf	Self:aStruct[nInd][02] == "L"
						aAdd(aNewData, .F.)
					EndIf
				EndIf
			Next nInd
			aAdd(Self:aData, aNewData)
			Self:nMaxPosData	:= Len(Self:aData)
			Self:nPosData		:= Self:nMaxPosData
		Else
			cSolution	:= aChkArray[02]
			lError		:= .T.
		EndIf

	Else
		cSolution	:= "Existem erros anteriores a este procesamento."
		lError		:= .T.
	EndIf
Else
	cSolution	:= "Objeto n�o est� dispon�vel."
	lError		:= .T.
EndIf

If	lError
	Self:AddError(cMsgError, cSolution, "")
	lRet	:= .F.
Else
	lRet	:= .T.
EndIf
Return lRet


//-----------------------------------------------------------------
/*/{Protheus.doc} Update (M�todo da Classe GSTmpTable)
@description	M�todo respons�vel por realizar a atualiza��o das informa��es do "registro" posicionado no objeto.
				Este m�todo n�o efetiva o registro na tabela tempor�ria.
@author		Alexandre da Costa (a.costa)
@since			30/11/2016
@version		V12.15
/*/
//--------------------------------------------------------------------
Method Update(aUpdate) Class GSTmpTable

Local cMsgError	:= "N�o foi poss�vel executar o m�todo 'Update'"
Local cSolution	:= ""
Local nInd			:= 0
Local nPos			:= 0
Local aChkArray	:= {}
Local lError		:= .F.
Local lRet			:= .F.

Default aUpdate	:= {}

If	Self:lAvailable
	If	! Self:lError
		If	Self:nPosData > 0 .AND. Len(Self:aData) > 0

			aChkArray	:= ChkInfArray(Self:aStruct, aUpdate)
			If	aChkArray[01]
				For nInd := 1 To Len(aUpdate)
					nPos	:= aScan(Self:aStruct, {|x| AllTrim(x[01]) == AllTrim(aUpdate[nInd][01])})
					Self:aData[Self:nPosData][nPos]	:= aUpdate[nInd][02]
				Next nInd
			Else
				cSolution	:= aChkArray[02]
				lError		:= .T.
			EndIf

		Else
			cSolution	:= "Analise as seguintes informa��es:" + CRLF + "1) Verifique o conte�do da propriedade 'POS_DATA'." + CRLF + "2) O objeto 'GSTmpTable' pode n�o possuir informa��es para que seja executado esse m�todo."
			lError		:= .T.
		EndIf
	Else
		cSolution	:= "Existem erros anteriores a este procesamento."
		lError		:= .T.
	EndIf
Else
	cSolution	:= "Objeto n�o est� dispon�vel."
	lError		:= .T.
EndIf

If	lError
	Self:AddError(cMsgError, cSolution, "")
	lRet	:= .F.
Else
	lRet	:= .T.
EndIf
Return lRet


//-----------------------------------------------------------------
/*/{Protheus.doc} Seek() (M�todo da Classe GSTmpTable)
@description	M�todo respons�vel por localizar um 'registro' dentro do objeto.
				Este m�todo n�o localiza o registro na tabela tempor�ria.
@author		Alexandre da Costa (a.costa)
@since			30/11/2016
@version		V12.15
/*/
//--------------------------------------------------------------------
Method Seek(aSeek) Class GSTmpTable

Local cMsgError		:= "N�o foi poss�vel executar o m�todo 'Seek'"
Local cSolution		:= ""
Local cValType		:= ""
Local cAuxSeek		:= ""
Local cSeek			:= ""
Local nPosStruct		:= 0
Local nInd				:= 0
Local nPos				:= 0
Local lError			:= .F.
Local lSeekOK			:= .F.
Local aChkArray		:= {}
Local lRet				:= .F.

Default aSeek	:= {}

If	Self:lAvailable
	If	!( Self:lError )

		aChkArray	:= ChkInfArray(Self:aStruct, aSeek)
		If	aChkArray[01]
			For nInd := 1 to Len(aSeek)
				nPosStruct		:= aScan(Self:aStruct,{|x| AllTrim(x[01]) == AllTrim(aSeek[nInd][01])})
				cAuxSeek		:= ""
				cValType		:= ValType(aSeek[nInd][02])
				If	cValType $ "C|M"
					cAuxSeek	:= "'" + aSeek[nInd][02] + "'"
				ElseIf cValType == "N"
					cAuxSeek	:= AllTrim(Str(aSeek[nInd][02]))
				ElseIf cValType == "D"
					cAuxSeek	:= "CtoD('" + DtoC(aSeek[nInd][02]) + "')"
				ElseIf cValType == "L"
					cAuxSeek	:= If( ValType(aSeek[nInd][02]), ".T.", ".F." )
				EndIf
				cSeek			+= If( ! Empty(cSeek), " .AND. ", "" ) + "x[" + StrZero(nPosStruct,3) + "] == " + cAuxSeek
			Next nInd

			cSeek	:= "aScan(Self:aData, {|x| " + cSeek + "})"
			If	( lSeekOK := ( ( nPos := &( cSeek ) ) > 0 ) )
				Self:nPosData	:= nPos
			EndIf
		Else
			cSolution	:= aChkArray[02]
			lError		:= .T.
		EndIf

	Else
		cSolution	:= "Existem erros anteriores a este procesamento."
		lError		:= .T.
	EndIf
Else
	cSolution	:= "Objeto n�o est� dispon�vel."
	lError		:= .T.
EndIf

If	lError
	Self:AddError(cMsgError, cSolution, "")
	lRet	:= .F.
Else
	lRet	:= lSeekOK
EndIf
Return lRet


//-----------------------------------------------------------------
/*/{Protheus.doc} ChkInfArray
@description	Analisa as informa��es entre a estrutura e os dados para a tabela tempor�ria.
@author		Alexandre da Costa (a.costa)
@since			02/12/2016
@version		V12.15
/*/
//--------------------------------------------------------------------
Static Function ChkInfArray(aStruct, aArray)

Local cValType	:= ""
Local nPos			:= 0
Local nInd			:= 0
Local nNumbMax	:= 0
Local aRet			:= {.T., ""}

If	ValType(aArray) == "A" .AND. Len(aArray) > 0 .AND. ValType(aArray[01]) == "A" .AND. Len(aArray[01]) == 2

	For nInd := 1 to Len(aArray)
		cValType	:= ValType(aArray[nInd][02])
		If	( ( nPos := aScan(aStruct, {|x| AllTrim(x[01]) == AllTrim(aArray[nInd][01])}) ) == 0 ) .OR.;
			( aStruct[nPos][02] $ "C|M" .AND. cValType <> "C" )                                    .OR.;
			( aStruct[nPos][02] == "N"  .AND. cValType <> "N" )                                    .OR.;
			( aStruct[nPos][02] == "D"  .AND. cValType <> "D" )                                    .OR.;
			( aStruct[nPos][02] == "L"  .AND. cValType <> "L" )
			aRet	:= {.F., "Informa��es incompat�veis com a estrutura da tabela tempor�ria."}
			EXIT
		EndIf

		If	( aStruct[nPos][02] $ "C|M" .AND. Len(aArray[nInd][02]) > aStruct[nPos][03] )
			aRet	:= {.F., "Informa��es incompat�veis com a estrutura da tabela tempor�ria." + CRLF + "O conte�do para o campo '" + aStruct[nPos][01] + "' ultrapassa o seu tamanho permitido."}
			EXIT
		EndIf

		If	aStruct[nPos][02] == "N"
			If	aStruct[nPos][04] == 0
				nNumbMax	:= Val(Replicate("9", aStruct[nPos][03]))
			Else
				nNumbMax	:= Val( ( Replicate("9", (aStruct[nPos][03] - aStruct[nPos][04] - 1)) + "." + Replicate("9", aStruct[nPos][04]) ) )
			EndIf
			If	aArray[nInd][02] > nNumbMax
				aRet	:= {.F., "Informa��es incompat�veis com a estrutura da tabela tempor�ria." + CRLF + "O conte�do para o campo '" + aStruct[nPos][01] + "' ultrapassa o seu tamanho permitido."}
				EXIT
			EndIf
		EndIf
	Next nInd

Else
	aRet	:= {.F., "Verifique a estrutura na qual as informa��es est�o sendo enviadas ao m�todo do objeto 'GSTmpTable'."}
EndIf
Return aRet


//-----------------------------------------------------------------
/*/{Protheus.doc} Delete (M�todo da Classe GSTmpTable)
@description	M�todo respons�vel por realizar a exclus�o do 'registro' do objeto.
				Este m�todo n�o elimina o registro da tabela tempor�ria.
@author		Alexandre da Costa (a.costa)
@since			30/11/2016
@version		V12.15
/*/
//--------------------------------------------------------------------
Method Delete() Class GSTmpTable

Local cMsgError	:= "N�o foi poss�vel executar o m�todo 'Delete'"
Local cSolution	:= ""
Local nLenData	:= 0
Local lError		:= .F.
Local lRet			:= .F.

If	Self:lAvailable
	If	! Self:lError
		If	Self:nPosData > 0 .AND. Len(Self:aData) > 0 .AND. Len(Self:aData) >= Self:nPosData

			aDel(Self:aData, Self:nPosData)
			aSize(Self:aData, Len(Self:aData)-1)

			nLenData			:= Len(Self:aData)
			Self:nMaxPosData	:= nLenData

			If Self:nMaxPosData == 0
				Self:nPosData	:= 0
			ElseIf Self:nPosData > Self:nMaxPosData
				Self:nPosData	:= Self:nMaxPosData
			EndIf

		Else
			cSolution	:= "Analise as seguintes informa��es:" + CRLF + "1) Verifique o conte�do da propriedade 'POS_DATA'." + CRLF + "2) O objeto 'GSTmpTable' pode n�o possuir informa��es para que seja executado esse m�todo."
			lError		:= .T.
		EndIf
	Else
		cSolution	:= "Existem erros anteriores a este procesamento."
		lError		:= .T.
	EndIf
Else
	cSolution	:= "Objeto n�o est� dispon�vel."
	lError		:= .T.
EndIf

If	lError
	Self:AddError(cMsgError, cSolution, "")
	lRet		:= .F.
Else
	lRet		:= .T.
EndIf
Return lRet


//-----------------------------------------------------------------
/*/{Protheus.doc} GetValue (M�todo da Classe GSTmpTable)
@description	M�todo respons�vel por retornar o conte�do do 'registro' ou de um 'campo do registro' posicionado no objeto.
				Utilizado para "registros" ainda n�o efetivados na tabela tempor�ria.
@author		Alexandre da Costa (a.costa)
@since			30/11/2016
@version		V12.15
/*/
//--------------------------------------------------------------------
Method GetValue(cTpOper, aGetField) Class GSTmpTable

Local cMsgError	:= "N�o foi poss�vel executar o m�todo 'GetValue'"
Local cSolution	:= ""
Local cValType	:= ""
Local cKeyString	:= ""
Local cKey			:= ""
Local lError		:= .F.
Local nInd			:= 0
Local nInd2		:= 0
Local aAux			:= {}
Local aRet			:= {}

Default cTpOper	:= "LINE"
Default aGetField	:= {}

If	Self:lAvailable
	If	! Self:lError
		If	Self:nPosData > 0 .AND. Len(Self:aData) > 0 .AND. Len(Self:aData) >= Self:nPosData

			Do Case
				Case	cTpOper == "LINE"
						For nInd := 1 To Len(Self:aStruct)
							aAdd( aRet, {Self:aStruct[nInd][01], Self:aData[Self:nPosData][nInd]})
						Next nInd
						aRet		:= {.T., aRet}
				Case	cTpOper == "FIELDS"
						If	ValType(aGetField) == "A" .AND. Len(aGetField) > 0
							For nInd := 1 to Len(aGetField)
								If	ValType(aGetField[nInd]) == "C"
									If	(nInd2 := aScan(Self:aStruct, {|x| AllTrim(x[01]) == AllTrim(aGetField[nInd])})) > 0
										aAdd(aAux, {aGetField[nInd], Self:aData[Self:nPosData][nInd2]})
									Else
										cSolution	:= "O 'campo " + AllTrim(aGetField[nInd]) + "' n�o est� dispon�vel na estrutura do objeto."
										lError		:= .T.
										EXIT
									EndIf
								Else
									cSolution	:= "Problemas encontrados na execu��o do m�todo com o par�metro 'FIELDS'."
									lError		:= .T.
									EXIT
								EndIf
							Next nInd
							If	!( lError )
								aRet	:= {.T., aAux}
							EndIf
						Else
							cSolution	:= "Se for utilizado o par�metro 'FIELDS', os campos desejados dever�o ser enviados ao m�todo na forma de um array monodimensional."
							lError		:= .T.
						EndIf
				Case	cTpOper == "KEY"
						If	ValType(aGetField) == "A" .AND. Len(aGetField) > 0
							For nInd := 1 to Len(aGetField)
								If	ValType(aGetField[nInd]) == "C"
									If	(nInd2 := aScan(Self:aStruct, {|x| AllTrim(x[01]) == AllTrim(aGetField[nInd])})) > 0
										cValType		:= ValType(Self:aData[nInd][nInd2])
										cKeyString		+= If(! Empty(cKeyString), "+", "" )
										If		cValType $ "C|M"
												cKeyString	+= AllTrim(aGetField[nInd])
												cKey		+= Self:aData[nInd][nInd2]
										ElseIf	cValType == "N"
												cKeyString	+= "Str(" + AllTrim(aGetField[nInd]) + "," + AllTrim(Str(Self:aStruct[nInd2][03])) + "," + AllTrim(Str(Self:aStruct[nInd2][04])) + ")"
												cKey		+= Str(Self:aData[nInd][nInd2], Self:aStruct[nInd2][03], Self:aStruct[nInd2][04])
										ElseIf	cValType == "D"
												cKeyString	+= "DtoS(" + AllTrim(aGetField[nInd]) + ")"
												cKey		+= DtoS(Self:aData[nInd][nInd2])
										ElseIf	cValType == "L"
												cKeyString	+= AllTrim(aGetField[nInd])
												cKey		+= If( Self:aData[nInd][nInd2], "T", "F" )
										EndIf
									Else
										cSolution	:= "O 'campo " + AllTrim(aGetField[nInd]) + "' n�o est� dispon�vel na estrutura do objeto."
										lError		:= .T.
										EXIT
									EndIf
								Else
									cSolution	:= "Problemas encontrados na execu��o do m�todo com o par�metro 'KEY'."
									lError		:= .T.
									EXIT
								EndIf
							Next nInd
							If	!( lError )
								aRet	:= {.T., {cKeyString, cKey}}
							EndIf
						Else
							cSolution	:= "Se for utilizado o par�metro 'KEY', os campos desejados dever�o ser enviados ao m�todo na forma de um array monodimensional."
							lError		:= .T.
						EndIf
				Otherwise
					cSolution	:= "Verifique as op��es dispon�veis para execu��o desse m�todo."
					lError		:= .T.
			EndCase

		Else
			cSolution	:= "Analise as seguintes informa��es:" + CRLF + "1) Verifique o conte�do da propriedade 'POS_DATA'." + CRLF + "2) O objeto 'GSTmpTable' pode n�o possuir informa��es para que seja executado esse m�todo."
			lError		:= .T.
		EndIf
	Else
		cSolution	:= "Existem erros anteriores a este procesamento."
		lError		:= .T.
	EndIf
Else
	cSolution	:= "Objeto n�o est� dispon�vel."
	lError		:= .T.
EndIf

If	lError
	Self:AddError(cMsgError, cSolution, "")
	aRet		:= {.F., {{NIL,NIL}}}
EndIf
Return aRet


//-----------------------------------------------------------------
/*/{Protheus.doc} Commit (M�todo da Classe GSTmpTable)
@description	M�todo respons�vel por efetivar os 'registros' do objeto na tabela tempor�ria.
				Se o m�todo 'commit' foi executado com sucesso, os 'registros' passar�o a estar
				na tabela tempor�ria, e n�o mais na estrutura do objeto.
@author		Alexandre da Costa (a.costa)
@since			30/11/2016
@version		V12.15
/*/
//--------------------------------------------------------------------
Method Commit() Class GSTmpTable

Local cMsgError		:= "N�o foi poss�vel executar o m�todo 'Commit'"
Local cSolution		:= ""
Local cQry				:= ""
Local cQryError		:= ""
Local cInsFields		:= ""
Local cInsValRec		:= ""
Local cInsValues		:= ""
Local cValType		:= ""
Local nMaxStepIns		:= Self:GetProp("STEP_COMMIT_INSERT")
Local nInd				:= 0
Local nInd2			:= 0
Local nAux				:= 0
Local nCountStp		:= 0
Local nStatusQry		:= 0
Local lCommitOK		:= .F.
Local lError			:= .F.
Local lRet				:= .F.

If	Self:lAvailable
	If	!( Self:lError )
		If	Self:lCreateTMPTable .AND. ValType(Self:oTempTable) == "O"
			If	Len(Self:aData) > 0

				For nInd := 1 to Len(Self:aStruct)
					cInsFields	+= If( ! Empty(cInsFields), ", ", "") + AllTrim(Self:aStruct[nInd][01] )
				Next nInd

				If	Len(Self:aData) < nMaxStepIns
					nMaxStepIns	:= Len(Self:aData)
				EndIf

				cInsValues		:= ""
				For nInd := 1 To Len(Self:aData)

					cInsValRec	:= ""
					For nInd2 := 1 To Len(Self:aData[nInd])
						cValType		:= ValType(Self:aData[nInd][nInd2])
						cInsValRec		+= If( ! Empty(cInsValRec), ", ", "" )
						If		cValType $ "C|M"
								cInsValRec		+= "'" + Self:aData[nInd][nInd2] + "'"
						ElseIf	cValType == "N"
								cInsValRec		+= AllTrim(Str(Self:aData[nInd][nInd2], Self:aStruct[nInd2][03], Self:aStruct[nInd2][04]))
						ElseIf	cValType == "D"
								cInsValRec		+= "'" + AllTrim(DtoS(Self:aData[nInd][nInd2])) + "'"
						ElseIf	cValType == "L"
								cInsValRec		+= "'" + If( Self:aData[nInd][nInd2], "T", "F" ) + "'"
						EndIf
					Next nInd2

					cInsValues		+= If( ! Empty(cInsValues), ", " + CRLF, "" ) + "       (" + AllTrim(cInsValRec) + ")"
					nCountStp		+= 1
					If	nCountStp == nMaxStepIns .Or. (Len(cInsValues) > 15000)
						cQry	:= "INSERT INTO " + AllTrim(Self:aTempTableInfo[02]) + CRLF +;
						          "       (" + cInsFields + ") " + CRLF +;
								   "VALUES " + CRLF +;
								   cInsValues
						If	( nStatusQry := TCSqlExec(cQry) ) == 0
							nCountStp		:= 0
							nAux			:= ( Len(Self:aData) - nInd )
							If	nAux > 0 .AND. nAux < nMaxStepIns
								nMaxStepIns	:= nAux
							EndIf
							lCommitOK		:= .T.
							cInsValues		:= ""
						Else
							cQryError		:= "TCSQLExec Error #" + AllTrim(Str(nStatusQry)) + CRLF +;
							              	Replicate("-",20) + CRLF +;
							              	TCSQLError() + CRLF +;
							              	Replicate("-",60) + CRLF +;
							              	cQry
							cSolution		:= "Verifique o comando 'INSERT INTO' executado."
							lError			:= .T.
							lCommitOK		:= .T.
							EXIT
						EndIf
					EndIf

				Next nInd

			EndIf
		Else
			cSolution	:= "Tabela tempor�ria n�o dispon�vel."
			lError		:= .T.
		EndIf
	Else
		cSolution	:= "Existem erros anteriores a este procesamento."
		lError		:= .T.
	EndIf
Else
	cSolution	:= "Objeto n�o est� dispon�vel."
	lError		:= .T.
EndIf

If	lError
	Self:AddError(cMsgError, cSolution, cQryError)
	lRet		:= .F.
Else
	//	Se n�o houve erro no processamento da efetiva��o das informa��es na tabela tempor�ria
	If	lCommitOK
		//	Se os dados dispon�veis no objeto foram todos efetivados na tabela tempor�ria, ent�o,
		//	reinicia as respectivas propriedades do objeto
		Self:aData			:= {}
		Self:nPosData		:= 0
		Self:nMaxPosData	:= 0
	EndIf
	lRet		:= .T.
EndIf
Return lRet


//-----------------------------------------------------------------
/*/{Protheus.doc} Close() (M�todo da Classe GSTmpTable)
@description	M�todo respons�vel por fechar a �rea tempor�ria associada ao objeto GsTmpTable
@author		Alexandre da Costa (a.costa)
@since			30/11/2016
@version		V12.15
/*/
//--------------------------------------------------------------------
Method Close() Class GSTmpTable

Local aOldArea	:= GetArea()
Local cMsgError	:= "N�o foi poss�vel executar o m�todo 'Close'"
Local cSolution	:= ""
Local lError		:= .F.
Local lRet			:= .T.

If	Self:lAvailable
	If	!( Self:lError )
		If	Self:lCreateTMPTable .AND. ValType(Self:oTempTable) == "O"
			If	( lRet := Select(Self:cAliasTmp) > 0 )
				Self:oTempTable:Delete()
				TecDestroy(Self:oTempTable)
				Self:lCreateTMPTable		:= .F.
				Self:aTempTableInfo		:= {}
				Self:aData					:= {}
				Self:nPosData				:= 0
				Self:nMaxPosData			:= 0
				Self:lError				:= .F.
				Self:aError				:= {}
			Else
				cSolution	:= "Tabela tempor�ria n�o est� aberta."
				lError		:= .T.
			EndIf
		Else
			cSolution	:= "Tabela tempor�ria n�o dispon�vel."
			lError		:= .T.
		EndIf
	Else
		cSolution	:= "Existem erros anteriores a este procesamento."
		lError		:= .T.
	EndIf
Else
	cSolution	:= "Objeto n�o est� dispon�vel."
	lError		:= .T.
EndIf

If	lError
	Self:AddError(cMsgError, cSolution, "")
	lRet		:= .F.
EndIf
RestArea(aOldArea)
Return	lRet

//-----------------------------------------------------------------
/*/{Protheus.doc} AddError (M�todo da Classe GSTmpTable)
@description	M�todo respons�vel por adicionar novas informa��es de erro ao objeto
@author		Alexandre da Costa (a.costa)
@since			30/11/2016
@version		V12.15
/*/
//--------------------------------------------------------------------
Method AddError(cMsgError, cSolution, cQuery) Class GSTmpTable

Default cMsgError	:= "Objeto inv�lido!"
Default cSolution	:= ""
Default cQuery	:= ""

aAdd(Self:aError, {cMsgError, cSolution, cQuery})
Self:lError		:= .T.
Return NIL


//-----------------------------------------------------------------
/*/{Protheus.doc} ShowErro (M�todo da Classe GSTmpTable)
@description	M�todo respons�vel por exibir o erro encontrado no processamento do objeto
@author		Alexandre da Costa (a.costa)
@since			30/11/2016
@version		V12.15
/*/
//--------------------------------------------------------------------
Method ShowErro() Class GSTmpTable

Local nLastError	:= Len(Self:aError)

If	nLastError > 0
	Help("", 1, "GSTmpTable",, Self:aError[nLastError][01], 4, 10,,,,,, {Self:aError[nLastError][02]})
EndIf
Return NIL


//-----------------------------------------------------------------
/*/{Protheus.doc} ShwTmpTable (M�todo da Classe GSTmpTable)
@description	M�todo respons�vel por exibir os registros j� efetivados na tabela tempor�ria associada ao objeto
@author		Alexandre da Costa (a.costa)
@since			06/12/2016
@version		V12.15
/*/
//--------------------------------------------------------------------
Method ShwTmpTable() Class GSTmpTable

Local aOldArea	:= GetArea()
Local cAliasQry	:= GetNextAlias()
Local cQuery		:= ""
Local nInd			:= 0
Local lError		:= .F.
Local lRet			:= .T.

If	Self:lAvailable
	If	!( Self:lError )
		If	Self:lCreateTMPTable .AND. ValType(Self:oTempTable) == "O"
			cQuery	:= "select * from " + Self:aTempTableInfo[02]
			MPSysOpenQuery( cQuery, cAliasQry )
			DbSelectArea(cAliasQry)
			While (cAliasQry)->(! Eof())
				For nInd := 1 to (cAliasQry)->( FCount() )
					VarInfo((cAliasQry)->( FieldName(nInd) ), (cAliasQry)->( FieldGet(nInd) ))
				Next nInd
				(cAliasQry)->( dBSkip() )
			Enddo
			(cAliasQry)->( dBCloseArea() )
		Else
			cSolution	:= "Tabela tempor�ria n�o dispon�vel."
			lError		:= .T.
		EndIf
	Else
		cSolution	:= "Existem erros anteriores a este procesamento."
		lError		:= .T.
	EndIf
Else
	cSolution	:= "Objeto n�o est� dispon�vel."
	lError		:= .T.
EndIf

If	lError
	Self:AddError(cMsgError, cSolution, "")
	lRet		:= .F.
EndIf
RestArea(aOldArea)

Return	lRet