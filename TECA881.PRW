#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TECA881.CH"

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECA881

Realiza a listagem dos armamentos disponiveis
@since		29/11/2013 
@version P11 R9
     
@return lRet, Retorna .T.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TECA881()

Local oDlg			:= Nil								// Dialog Principal
Local aSize			:= FWGetDialogSize( oMainWnd ) 		// Array com tamanho da janela.
Local oBrw			:= Nil								// Objeto do Browse
Local oBrwM			:= Nil								// Objeto do Browse
Local aColumns		:= {}								// Array com as colunas para o browse
Local aList			:= {}								// Array com os dados a serem apresentados
Local oColumns		:= Nil
Local lPerg			:= .T.

//Ativa o Pergunte
lPerg := Pergunte("TECA881",.T.)

If !lPerg
	Return
EndIf

If MV_PAR01 == 1	// Armas
	//Cria o Array para exibição dos dados
	MsgRun(STR0005,STR0004,{ || aList := At881Query() }) //'Buscando Armamentos....'
ElseIf MV_PAR01 == 2	// Coletes
	//Cria o Array para exibição dos dados
	MsgRun(STR0005,STR0004,{ || aList := At881QryCol() }) //'Buscando Armamentos....'
EndIf

//Atualiza o Array em Ordem Numerica
asort(aList,,, {|x,y| x[2] < y[2] }) 

//Cria a tela para o browse
DEFINE DIALOG oDlg TITLE STR0001 FROM aSize[1],aSize[2] TO aSize[3],aSize[4] PIXEL //"Lista de Disponibilidade"
	
	DEFINE FWFORMBROWSE oBrw DATA ARRAY ARRAY aList LINE BEGIN 1 OF oDlg
		
		ADD COLUMN oColumns DATA &("{ || aList[oBrw:At()][1] }") TITLE ""	SIZE 1 PICTURE "@BMP" IMAGE OF oBrw
		ADD COLUMN oColumns DATA &("{ || aList[oBrw:At()][2] }") TITLE TxSX3Campo("TE0_COD")[1] 	SIZE TamSX3("TE0_COD")[1] 		OF oBrw
		ADD COLUMN oColumns DATA &("{ || aList[oBrw:At()][3] }") TITLE TxSX3Campo("TE0_ATIVO")[1] 	SIZE TamSX3("TE0_ATIVO")[1] 	OF oBrw
		ADD COLUMN oColumns DATA &("{ || aList[oBrw:At()][4] }") TITLE TxSX3Campo("TE0_SITUA")[1] 	SIZE TamSX3("TE0_SITUA")[1] 	OF oBrw
		ADD COLUMN oColumns DATA &("{ || aList[oBrw:At()][5] }") TITLE TxSX3Campo("TE0_LOCAL")[1]	SIZE TamSX3("TE0_LOCAL")[1] 	OF oBrw
		ADD COLUMN oColumns DATA &("{ || aList[oBrw:At()][6] }") TITLE TxSX3Campo("TE0_CLIDES")[1]	SIZE TamSX3("TE0_CLIDES")[1]	OF oBrw
		ADD COLUMN oColumns DATA &("{ || aList[oBrw:At()][7] }") TITLE TxSX3Campo("TFQ_DMOVIM")[1]	SIZE TamSX3("TFQ_DMOVIM")[1] 	OF oBrw
		ADD COLUMN oColumns DATA &("{ || aList[oBrw:At()][8] }") TITLE TxSX3Campo("TFO_DTRET")[1]	SIZE TamSX3("TFO_DTRET")[1] 	OF oBrw
					
		//Adiciona o Botão para a Legenda
		ADD Button oBtLegend Title STR0002 Action "At881Leg()" OPERATION MODEL_OPERATION_VIEW   Of oBrw //"Legenda"
					
		//Adiciona o Botão para a Legenda
		ADD Button oBtRefresh Title STR0003 Action {|| At881Refresh(aList,oBrw)} OPERATION MODEL_OPERATION_VIEW   Of oBrw //"Legenda"
				
			
	ACTIVATE FWFORMBROWSE oBrw
		
	
ACTIVATE DIALOG oDlg CENTERED

	

Return (.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At881Query

Query com os dados a serem exibidos na lista de disponibilidade
@sample 	At881Query() 
@since		29/11/2013 
@version P11 R9
     
@return aList, Retorna o Array com a lista de armas disponiveis
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At881Query()
Local aTER		:= {}							//Armas no Cofre
Local aABS		:= {}							//Retorno
Local aRet		:= {}
Local cAlias	:= GetNextAlias()
Local cAtiva	:= '1'
Local cAloc		:= '2'
Local cManut	:= '3'

If Select("cAlias") > 0 
	(cAlias)->(DbCloseArea())
Endif

If MV_PAR04 == 1
	cWhere := "% TE0.TE0_ENTIDA = 'TER' " 
	If !Empty(MV_PAR05) .And. !Empty(MV_PAR06)
		cWhere += " AND TE0.TE0_LOCAL   BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"' " 	
	EndIf
	cWhere += " %"	
Else
	cWhere := "% TE0.TE0_ENTIDA = 'ABS' " 
	cWhere += "AND TE0.TE0_CODMOV <> ' ' "
	If !Empty(MV_PAR07) .And. !Empty(MV_PAR08)
		cWhere += " AND TE0.TE0_LOCAL   BETWEEN '"+MV_PAR07+"' AND '"+MV_PAR08+"' " 	
	EndIf
	cWhere += " %"
EndIf
	
BeginSQL alias cAlias
	SELECT TE0.*
	FROM
		%Table:TE0% TE0
	WHERE
			TE0.TE0_FILIAL = %xfilial:TE0%
		AND
			(TE0.TE0_SITUA = %Exp:cAtiva% OR TE0.TE0_SITUA = %Exp:cAloc% OR TE0.TE0_SITUA = %Exp:cManut% )
		AND
			%Exp:cWhere%
		AND
			TE0.%NotDel%
EndSQL	
		
While (cAlias)->(!Eof())
	
	//Verifico se a arma está no cofre ou em cliente
	If (cAlias)->TE0_ENTIDA = 'TER'
		AAdd( aTER, { 	(cAlias)->TE0_COD,;
			(cAlias)->TE0_ATIVO,;
			(cAlias)->TE0_SITUA,;
			(cAlias)->TE0_LOCAL,;
			(cAlias)->TE0_CLIDES,;
			sToD((cAlias)->TE0_DTALOC),;
			(cAlias)->TE0_ENTIDA,;
			(cAlias)->TE0_CODMOV } )			
	Else
		AAdd( aABS, { 	(cAlias)->TE0_COD,;
			(cAlias)->TE0_ATIVO,;
			(cAlias)->TE0_SITUA,;
			(cAlias)->TE0_LOCAL,;
			(cAlias)->TE0_CLIDES,;
			sToD((cAlias)->TE0_DTALOC),;
			(cAlias)->TE0_CODMOV,;
			sToD((cAlias)->TE0_PRVRET),;
			(cAlias)->TE0_ENTIDA } )	
	EndIf
		
	(cAlias)->(DbSkip())
		
EndDo

(cAlias)->(DbCloseArea())

If Len(aTER) > 0
	//Verifico quais as Armas que estão livres para alocação
	aRet := At881Free(aTER)
ElseIf Len(aABS) > 0
	//Verifico quais das Armas Alocadas tem previsão de retorno
	aRet:= At881DispRet(aABS)
	
	//Verifico se as armas tem movimentações agendadas para outra ABS.
	At881AgCli(aABS,@aRet)
EndIf

Return(aRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At881QryCol

Query com os dados a serem exibidos na lista de disponibilidade
@sample 	At881Query() 
@since		29/11/2013 
@version P11 R9
     
@return aList, Retorna o Array com a lista de armas disponiveis
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At881QryCol()
Local aTER		:= {}							//Armas no Cofre
Local aABS		:= {}							//Retorno
Local aRet		:= {}
Local cAlias	:= GetNextAlias()
Local cAtiva	:= '1'
Local cAloc	:= '2'

If Select("cAlias") > 0 
	(cAlias)->(DbCloseArea())
Endif

If MV_PAR04 == 1
	cWhere := "% TE1.TE1_ENTIDA = 'TER' " 
	If !Empty(MV_PAR05) .And. !Empty(MV_PAR06)
		cWhere += " AND TE1.TE1_LOCAL   BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"' " 	
	EndIf
	cWhere += " %"	
Else
	cWhere := "% TE1.TE1_ENTIDA = 'ABS' " 
	cWhere += "AND TE1.TE1_CODMOV <> ' ' "
	If !Empty(MV_PAR07) .And. !Empty(MV_PAR08)
		cWhere += " AND TE1.TE1_LOCAL   BETWEEN '"+MV_PAR07+"' AND '"+MV_PAR08+"' " 	
	EndIf
	cWhere += " %"
EndIf
	
BeginSQL alias cAlias
	SELECT TE1.*
	FROM
		%Table:TE1% TE1
	WHERE
			TE1.TE1_FILIAL = %xfilial:TE1%
		AND
			(TE1.TE1_SITUA = %Exp:cAtiva% OR TE1.TE1_SITUA = %Exp:cAloc%)
		AND
			%Exp:cWhere%
		AND
			TE1.%NotDel%
EndSQL	
		
While (cAlias)->(!Eof())
	
	//Verifico se a arma está no cofre ou em cliente
	If (cAlias)->TE1_ENTIDA = 'TER'
		AAdd( aTER, { 	(cAlias)->TE1_CODCOL,;
			 " "					,;
			(cAlias)->TE1_SITUA,;
			(cAlias)->TE1_LOCAL,;
			(cAlias)->TE1_CLIDES,;
			sToD((cAlias)->TE1_DTALOC),;
			(cAlias)->TE1_ENTIDA } )		
	Else
		AAdd( aABS, { 	(cAlias)->TE1_CODCOL,;
			" "  					,;
			(cAlias)->TE1_SITUA,;
			(cAlias)->TE1_LOCAL,;
			(cAlias)->TE1_CLIDES,;
			sToD((cAlias)->TE1_DTALOC),;
			(cAlias)->TE1_CODMOV,;
			sToD((cAlias)->TE1_PRVRET),;
			(cAlias)->TE1_ENTIDA } )	
	EndIf
		
	(cAlias)->(DbSkip())
		
EndDo

(cAlias)->(DbCloseArea())

If Len(aTER) > 0
	//Verifico quais as Armas que estão livres para alocação
	aRet := At881Free(aTER)
ElseIf Len(aABS) > 0
	//Verifico quais das Armas Alocadas tem previsão de retorno
	aRet:= At881DispRet(aABS)
	
	//Verifico se as armas tem movimentações agendadas para outra ABS.
	At881AgCli(aABS,@aRet)
EndIf

Return(aRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At881Free

Verifica as armas e coletes que estão livres
@since		29/11/2013 
@version P11 R9
     
@return lRet, Retorna .T.
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At881Free(aTER)
Local aRet			:= {}
Local aMov			:= {}
Local cAlias		:= GetNextAlias()
Local cArma		:= ""				//Variavel com o codigo das armas a serem verificadas
Local nY			:= 0
Local cWhere		:= ""
Local nX			:= 0

Default aTER	:= {}

If Len(aTER) > 0
	
	//Verifico quais armas estão realmente sem nenhuma movimentação
	If Len(aTER) == 1
		cArma := "In('" + aTER[1][1] + "')	
	Else
		For nY := 1 to Len(aTER)
			//Monta o Range com as Armas
			If nY == Len(aTER)
				cArma += ",'" + aTER[nY][1] + "')	
			ElseIf !Empty(cArma) 
				cArma += ",'" + aTER[nY][1] + "'	
			Else
				cArma := "In('" + aTER[nY][1] + "'	
			EndIf
			
		Next nY
	EndIf
	
	cWhere := "% TFO.TFO_ITCOD  " + cArma 
	
	If !Empty(MV_PAR01)
		cWhere += "AND TFO.TFO_ITMOV = '" + cValtoChar(MV_PAR01) + "' "
	EndIf
	
	cWhere += " %"
	
	If MV_PAR01 == 1
		
			BeginSQL alias cAlias
				SELECT DISTINCT 
					TFQ.TFQ_CODIGO,
					TFO.TFO_ITMOV,
					TFO.TFO_ITCOD,
					TFQ.TFQ_DESTIN,
					TFO.TFO_LRET,
					TFO.TFO_DTRET,
					TFQ.TFQ_DMOVIM,
					TFQ.TFQ_STATUS,
					TE0.TE0_ATIVO,
					TE0.TE0_SITUA,
					TE0.TE0_ENTIDA,
					TE0.TE0_LOCAL,
					TE0.TE0_CLIDES
				FROM
					%Table:TFQ% TFQ
				INNER JOIN 
					%Table:TFO% TFO 
					ON
						TFO.TFO_FILIAL = TFQ.TFQ_FILIAL
					AND 
						TFO.TFO_CDMOV = TFQ.TFQ_CODIGO
					AND 
						TFO.%NotDel%
				INNER JOIN 
					%Table:TE0% TE0  
			       ON 
			       	TE0.TE0_FILIAL = %xfilial:TE0% 
			      	AND 
			      		TE0.TE0_COD = TFO.TFO_ITCOD
			      	AND 
		      			TFQ.TFQ_CODIGO > TE0.TE0_CODMOV
			      	AND 
			      		TE0.%NotDel%

				WHERE
					TFQ.TFQ_FILIAL = %xfilial:TFQ%
				AND
					%Exp:cWhere%
				AND
					TFQ.%NotDel%
			EndSQL
			
			While (cAlias)->(!Eof())
				//Monta o Array com aquelas armas que tem movimentação
				AAdd( aMov, { (cAlias)->TFO_ITCOD,;
					(cAlias)->TE0_ATIVO,;
					(cAlias)->TE0_SITUA,;
					(cAlias)->TE0_LOCAL,;
					(cAlias)->TE0_CLIDES,;
					sToD((cAlias)->TFQ_DMOVIM),;
					sToD((cAlias)->TFO_DTRET) } )			
				
			(cAlias)->(DbSkip())
				
			EndDo
		
			(cAlias)->(DbCloseArea())
		
		//Verifica as armas que não tem nenhum agendamento
		//e da o Status de livre
		If Len(aMov) > 0
			For nY := 1 To Len(aTER)
				nX := aScan(aMov,{|x| AllTrim(x[1]) == aTER[nY][1]})
				If nX == 0
					AAdd( aRet, { 	"BR_VERDE",;
						aTER[nY][1],;
						aTER[nY][2],;
						aTER[nY][3],;
						aTER[nY][4],;
						aTER[nY][5],;
						aTER[nY][6],;				
						" " } )	
				EndIf
			Next nY
			
			//Verifica se as armas que tem movimentação, seus agendamentos e data de retorno
			At881Agend(aMov,@aRet)
		Else
			//Indica que todas as armas listadas estão livres
			For nY := 1 To Len(aTER)
				AAdd( aRet, { 	"BR_VERDE",;
					aTER[nY][1],;
					aTER[nY][2],;
					aTER[nY][3],;
					aTER[nY][4],;
					aTER[nY][5],;
					aTER[nY][6],;				
					" " } )	
			Next nY		
		EndIf
		
	ElseIf MV_PAR01 == 2
	
		BeginSQL alias cAlias
				SELECT DISTINCT 
					TFQ.TFQ_CODIGO,
					TFO.TFO_ITMOV,
					TFO.TFO_ITCOD,
					TFQ.TFQ_DESTIN,
					TFO.TFO_LRET,
					TFO.TFO_DTRET,
					TFQ.TFQ_DMOVIM,
					TFQ.TFQ_STATUS,
					TE1.TE1_SITUA,
					TE1.TE1_ENTIDA,
					TE1.TE1_LOCAL,
					TE1.TE1_CLIDES
				FROM
					%Table:TFQ% TFQ
				INNER JOIN 
					%Table:TFO% TFO 
					ON
						TFO.TFO_FILIAL = TFQ.TFQ_FILIAL
					AND 
						TFO.TFO_CDMOV = TFQ.TFQ_CODIGO
					AND 
						TFO.%NotDel%
				INNER JOIN 
					%Table:TE1% TE1  
			       ON 
			       	TE1.TE1_FILIAL = %xfilial:TE1% 
			      	AND 
			      		TE1.TE1_CODCOL = TFO.TFO_ITCOD
			      	AND 
		      			TFQ.TFQ_CODIGO > TE1.TE1_CODMOV
			      	AND 
			      		TE1.%NotDel%

				WHERE
					TFQ.TFQ_FILIAL = %xfilial:TFQ%
				AND
					%Exp:cWhere%
				AND
					TFQ.%NotDel%
			EndSQL
			
			While (cAlias)->(!Eof())
				//Monta o Array com aquelas armas que tem movimentação
				AAdd( aMov, { (cAlias)->TFO_ITCOD,;
					" "						,;
					(cAlias)->TE1_SITUA,;
					(cAlias)->TE1_LOCAL,;
					(cAlias)->TE1_CLIDES,;
					sToD((cAlias)->TFQ_DMOVIM),;
					sToD((cAlias)->TFO_DTRET) } )			
				
			(cAlias)->(DbSkip())
				
			EndDo
		
			(cAlias)->(DbCloseArea())
		
		//Verifica as armas que não tem nenhum agendamento
		//e da o Status de livre
		If Len(aMov) > 0
			For nY := 1 To Len(aTER)
				nX := aScan(aMov,{|x| AllTrim(x[1]) == aTER[nY][1]})
				If nX == 0
					AAdd( aRet, { 	"BR_VERDE",;
						aTER[nY][1],;
						aTER[nY][2],;
						aTER[nY][3],;
						aTER[nY][4],;
						aTER[nY][5],;
						aTER[nY][6],;				
						" " } )	
				EndIf
			Next nY
			
			//Verifica se as armas que tem movimentação, seus agendamentos e data de retorno
			At881Agend(aMov,@aRet)
		Else
			//Indica que todas as armas listadas estão livres
			For nY := 1 To Len(aTER)
				AAdd( aRet, { 	"BR_VERDE",;
					aTER[nY][1],;
					aTER[nY][2],;
					aTER[nY][3],;
					aTER[nY][4],;
					aTER[nY][5],;
					aTER[nY][6],;				
					" " } )	
			Next nY		
		EndIf
	
	EndIf
	
EndIf

Return(aRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At881Agend

Verifica as armas e coletes que estão agendadas
@since		29/11/2013 
@version P11 R9
     
@return lRet, Retorna .T.
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At881Agend(aTER,aRet,lPrazo,dData)
Local cAlias		:= GetNextAlias()
Local cArma			:= ""				//Variavel com o codigo das armas a serem verificadas
Local nY			:= 0
Local cWhere		:= ""

Default aTER	:= {}
Default lPrazo	:= .T.
Default dData	:= MV_PAR02

If Len(aTER) > 0
	
	If Len(aTER) == 1
		cArma := "In('" + aTER[1][1] + "')	
	Else
		For nY := 1 to Len(aTER)
			//Monta o Range com as Armas
			If nY == Len(aTER)
				cArma += ",'" + aTER[nY][1] + "')	
			ElseIf !Empty(cArma) 
				cArma += ",'" + aTER[nY][1] + "'	
			Else
				cArma := "In('" + aTER[nY][1] + "'	
			EndIf
			
		Next nY
	EndIf
	
	cWhere := "% TFO.TFO_ITCOD  " + cArma 
	
	If !Empty(MV_PAR01)
		cWhere += "AND TFO.TFO_ITMOV = '" + cValtoChar(MV_PAR01) + "' "
	EndIf
	
	cWhere += " AND TFQ.TFQ_STATUS = '1' "
	
	If lPrazo
		If !Empty(MV_PAR02) .And. MV_PAR02 <= dDataBase 
			cWhere += "AND TFQ.TFQ_DMOVIM >= '" + Dtos(MV_PAR02) + "'"
		Else
			cWhere += "AND TFQ.TFQ_DMOVIM BETWEEN '" + Dtos(dDataBase) + "' AND '" +Dtos(MV_PAR02) + "'
		EndIf
	
	Else
		cWhere += "AND TFQ.TFQ_DMOVIM <= '" + Dtos(dData) + "'"
	EndIf
	
	cWhere += " %"
	
	If MV_PAR01 == 1
	
		BeginSQL alias cAlias
			SELECT DISTINCT 
				TFQ.TFQ_CODIGO,
				TFO.TFO_ITMOV,
				TFO.TFO_ITCOD,
				TFQ.TFQ_DESTIN,
				TFO.TFO_LRET,
				TFO.TFO_DTRET,
				TFQ.TFQ_DMOVIM,
				TFQ.TFQ_STATUS,
				TE0.TE0_ATIVO,
				TE0.TE0_SITUA,
				TE0.TE0_ENTIDA,
				TE0.TE0_LOCAL,
				TE0.TE0_CLIDES
			FROM
				%Table:TFQ% TFQ
			INNER JOIN 
				%Table:TFO% TFO 
				ON
					TFO.TFO_FILIAL = TFQ.TFQ_FILIAL
				AND 
					TFO.TFO_CDMOV = TFQ.TFQ_CODIGO
				AND 
					TFO.%NotDel%
			INNER JOIN 
				%Table:TE0% TE0  
		       ON 
		       	TE0.TE0_FILIAL = %xfilial:TE0% 
		      	AND 
		      		TE0.TE0_COD = TFO.TFO_ITCOD
		      	AND 
		      		TFQ.TFQ_CODIGO > TE0.TE0_CODMOV
		      	AND 
		      		TE0.%NotDel%

			WHERE
				TFQ.TFQ_FILIAL = %xfilial:TFQ%
			AND
				%Exp:cWhere%
			AND
				TFQ.%NotDel%
		EndSQL
		
		While (cAlias)->(!Eof())
				If  dDataBase <= sToD((cAlias)->TFQ_DMOVIM) .Or. ((dDataBase >= MV_PAR02) .Or. !lPrazo)
					lPrazo := .F.
					If 	MV_PAR02 <= sToD((cAlias)->TFQ_DMOVIM)
						AAdd( aRet, { 	"BR_AMARELO",;
							(cAlias)->TFO_ITCOD,;
							(cAlias)->TE0_ATIVO,;
							(cAlias)->TE0_SITUA,;
							(cAlias)->TE0_LOCAL,;
							(cAlias)->TE0_CLIDES,;
							sToD((cAlias)->TFQ_DMOVIM),;
							sToD((cAlias)->TFO_DTRET) } )		
					Else
						AAdd( aRet, { 	"BR_PRETO",;
							(cAlias)->TFO_ITCOD,;
							(cAlias)->TE0_ATIVO,;
							(cAlias)->TE0_SITUA,;
							(cAlias)->TE0_LOCAL,;
							(cAlias)->TE0_CLIDES,;
							sToD((cAlias)->TFQ_DMOVIM),;
							sToD((cAlias)->TFO_DTRET) } )	
					EndIf
				Else
						AAdd( aRet, { 	"BR_PRETO",;
						(cAlias)->TFO_ITCOD,;
						(cAlias)->TE0_ATIVO,;
						(cAlias)->TE0_SITUA,;
						(cAlias)->TE0_LOCAL,;
						(cAlias)->TE0_CLIDES,;
						sToD((cAlias)->TFQ_DMOVIM),;
						sToD((cAlias)->TFO_DTRET) } )	
				EndIf	
			
			(cAlias)->(DbSkip())
			
		EndDo
	
		(cAlias)->(DbCloseArea())
		
		If lPrazo
			At881Agend(aTER,@aRet,.F.,MV_PAR02)
		EndIf 
		
	ElseIf MV_PAR01 == 2
		
		BeginSQL alias cAlias
			SELECT DISTINCT 
				TFQ.TFQ_CODIGO,
				TFO.TFO_ITMOV,
				TFO.TFO_ITCOD,
				TFQ.TFQ_DESTIN,
				TFO.TFO_LRET,
				TFO.TFO_DTRET,
				TFQ.TFQ_DMOVIM,
				TFQ.TFQ_STATUS,
				TE1.TE1_SITUA,
				TE1.TE1_ENTIDA,
				TE1.TE1_LOCAL,
				TE1.TE1_CLIDES
			FROM
				%Table:TFQ% TFQ
			INNER JOIN 
				%Table:TFO% TFO 
				ON
					TFO.TFO_FILIAL = TFQ.TFQ_FILIAL
				AND 
					TFO.TFO_CDMOV = TFQ.TFQ_CODIGO
				AND 
					TFO.%NotDel%
			INNER JOIN 
				%Table:TE1% TE1  
		       ON 
		       	TE1.TE1_FILIAL = %xfilial:TE1% 
		      	AND 
		      		TE1.TE1_CODCOL = TFO.TFO_ITCOD
		      	AND 
		      		TFQ.TFQ_CODIGO > TE1.TE1_CODMOV
		      	AND 
		      		TE1.%NotDel%

			WHERE
				TFQ.TFQ_FILIAL = %xfilial:TFQ%
			AND
				%Exp:cWhere%
			AND
				TFQ.%NotDel%
		EndSQL
		
		While (cAlias)->(!Eof())
			If  dDataBase <= sToD((cAlias)->TFQ_DMOVIM) .Or. ((dDataBase >= MV_PAR02) .Or. !lPrazo)
				lPrazo := .F.
				If MV_PAR02 <= sToD((cAlias)->TFQ_DMOVIM)
					AAdd( aRet, { 	"BR_AMARELO",;
						(cAlias)->TFO_ITCOD,;
						" "						,;
						(cAlias)->TE1_SITUA,;
						(cAlias)->TE1_LOCAL,;
						(cAlias)->TE1_CLIDES,;
						sToD((cAlias)->TFQ_DMOVIM),;
						sToD((cAlias)->TFO_DTRET) } )			
				Else
					AAdd( aRet, { 	"BR_PRETO",;
						(cAlias)->TFO_ITCOD,;
						" "						,;
						(cAlias)->TE1_SITUA,;
						(cAlias)->TE1_LOCAL,;
						(cAlias)->TE1_CLIDES,;
						sToD((cAlias)->TFQ_DMOVIM),;
						sToD((cAlias)->TFO_DTRET) } )
				EndIf
			Else
				AAdd( aRet, { 	"BR_PRETO",;
					(cAlias)->TFO_ITCOD,;
					" "						,;
					(cAlias)->TE1_SITUA,;
					(cAlias)->TE1_LOCAL,;
					(cAlias)->TE1_CLIDES,;
					sToD((cAlias)->TFQ_DMOVIM),;
					sToD((cAlias)->TFO_DTRET) } )	
			EndIf
			
		(cAlias)->(DbSkip())
			
		EndDo
	
		(cAlias)->(DbCloseArea())
		
		If lPrazo
			At881Agend(aTER,@aRet,.F.,MV_PAR02)
		EndIf 
		
	EndIf
		
EndIf

Return(aRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At881DispRet

Verifica as armas e coletes com disponibilidade de retorno
@since		29/11/2013 
@version P11 R9
     
@return lRet, Retorna .T.
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At881DispRet(aABS)
Local aRet			:= {}
Local cAlias		:= GetNextAlias()
Local cArma			:= ""				//Variavel com o codigo das armas a serem verificadas
Local nY			:= 0
Local cWhere		:= ""
Local aMov			:= {}

Default aABS		:= {}

If Len(aABS) > 0
	
	If Len(aABS) == 1
		cArma := "In('" + aABS[1][7] + "'	)	
	Else		
		For nY := 1 to Len(aABS)
			//Monta o Range com as Armas
			If nY == Len(aABS)
				cArma += ",'" + aAbs[nY][7] + "')	
			ElseIf !Empty(cArma) 
				cArma += ",'" + aAbs[nY][7] + "'	
			Else
				cArma := "In('" + aAbs[nY][7] + "'	
			EndIf
			
		Next nY
	EndIf
	
	
	cWhere := "% TFQ.TFQ_CODIGO  " + cArma 
	
	
	cWhere += " AND TFO.TFO_LRET = '1' "
	
	If !Empty(MV_PAR03)
		cWhere += "AND (TFO.TFO_DTRET <> ' ' AND TFO.TFO_DTRET <= '" + Dtos(MV_PAR03) + "')"
	EndIf
	
	cWhere += " %"
	
	If MV_PAR01 == 1
	
		BeginSQL alias cAlias
			SELECT DISTINCT 
				TFQ.TFQ_CODIGO,
				TFO.TFO_ITMOV,
				TFO.TFO_ITCOD,
				TFQ.TFQ_DESTIN,
				TFO.TFO_LRET,
				TFO.TFO_DTRET,
				TFQ.TFQ_DMOVIM,
				TE0.TE0_ATIVO,
				TE0.TE0_SITUA,
				TE0.TE0_ENTIDA,
				TE0.TE0_LOCAL,
				TE0.TE0_CLIDES
			FROM
				%Table:TFQ% TFQ
			INNER JOIN 
				%Table:TFO% TFO 
				ON
					TFO.TFO_FILIAL = TFQ.TFQ_FILIAL
				AND 
					TFO.TFO_CDMOV = TFQ.TFQ_CODIGO
				AND 
					TFO.%NotDel%
			INNER JOIN 
				%Table:TE0% TE0  
		       ON 
		       	TE0.TE0_FILIAL = %xfilial:TE0% 
		      	AND 
		      		TE0.TE0_COD = TFO.TFO_ITCOD
		      	AND 
		      		TE0.%NotDel%

			WHERE
				TFQ.TFQ_FILIAL = %xfilial:TFQ%
			AND
				%Exp:cWhere%
			AND
				TFQ.%NotDel%
		EndSQL
		
		While (cAlias)->(!Eof())
		
			AAdd( aRet, { "BR_LARANJA",;
				(cAlias)->TFO_ITCOD,;
				(cAlias)->TE0_ATIVO,;
				(cAlias)->TE0_SITUA,;
				(cAlias)->TE0_LOCAL,;
				(cAlias)->TE0_CLIDES,;
				sToD((cAlias)->TFQ_DMOVIM)	,;  
				sToD((cAlias)->TFO_DTRET) } )			
			
		(cAlias)->(DbSkip())
			
		EndDo
	
		(cAlias)->(DbCloseArea())
		
		
		//Verifica as armas que não tem previsão de retorno, ou data superior
		If Len(aRet) > 0
			For nY := 1 To Len(aABS)
				nX := aScan(aRet,{|x| AllTrim(x[2]) == aABS[nY][1]})
				If nX == 0
					If aABS[nY][3] == "3"
						AAdd( aRet, { 	"BR_PINK",;
							aABS[nY][1],;
							aABS[nY][2],;
							aABS[nY][3],;
							aABS[nY][4],;
							aABS[nY][5],;
							aABS[nY][6],;				
							aABS[nY][8] } )	
					Else
						AAdd( aRet, { 	"BR_VERMELHO",;
							aABS[nY][1],;
							aABS[nY][2],;
							aABS[nY][3],;
							aABS[nY][4],;
							aABS[nY][5],;
							aABS[nY][6],;				
							aABS[nY][8] } )	
					EndIf
				Else
					//Verifica se a Data de retorno é maior que a data de retorno
					If aABS[nY][3] == "3"
					 	aRet[nX][1] := "BR_PINK"
					ElseIf MV_PAR03 > aABS[nY][8]
						aRet[nX][1] := "BR_VIOLETA"	
					EndIf
				EndIf
			Next nY
	
		Else
			//Indica que todas as armas listadas estão Implantadas e sem previsão de retorno
			For nY := 1 To Len(aABS)
				If aABS[nY][3] == "3"
					AAdd( aRet, { 	"BR_PINK",;
						aABS[nY][1],;
						aABS[nY][2],;
						aABS[nY][3],;
						aABS[nY][4],;
						aABS[nY][5],;
						aABS[nY][6],;			
						aABS[nY][8] } )
				Else
					AAdd( aRet, { 	"BR_VERMELHO",;
						aABS[nY][1],;
						aABS[nY][2],;
						aABS[nY][3],;
						aABS[nY][4],;
						aABS[nY][5],;
						aABS[nY][6],;			
						aABS[nY][8] } )
				EndIf
			Next nY		
		EndIf
	
	ElseIf MV_PAR01 == 2
	
		BeginSQL alias cAlias
			SELECT DISTINCT 
				TFQ.TFQ_CODIGO,
				TFO.TFO_ITMOV,
				TFO.TFO_ITCOD,
				TFQ.TFQ_DESTIN,
				TFO.TFO_LRET,
				TFO.TFO_DTRET,
				TFQ.TFQ_DMOVIM,
				TE1.TE1_SITUA,
				TE1.TE1_ENTIDA,
				TE1.TE1_LOCAL,
				TE1.TE1_CLIDES
			FROM
				%Table:TFQ% TFQ
			INNER JOIN 
				%Table:TFO% TFO 
				ON
					TFO.TFO_FILIAL = TFQ.TFQ_FILIAL
				AND 
					TFO.TFO_CDMOV = TFQ.TFQ_CODIGO
				AND 
					TFO.%NotDel%
			INNER JOIN 
				%Table:TE1% TE1  
		       ON 
		       	TE1.TE1_FILIAL = %xfilial:TE1% 
		      	AND 
		      		TE1.TE1_CODCOL = TFO.TFO_ITCOD
		      	AND 
		      		TE1.%NotDel%

			WHERE
				TFQ.TFQ_FILIAL = %xfilial:TFQ%
			AND
				%Exp:cWhere%
			AND
				TFQ.%NotDel%
		EndSQL
		
		While (cAlias)->(!Eof())
		
			AAdd( aRet, { "BR_LARANJA",;
				(cAlias)->TFO_ITCOD,;
				" "						,;
				(cAlias)->TE1_SITUA,;
				(cAlias)->TE1_LOCAL,;
				(cAlias)->TE1_CLIDES,;
				sToD((cAlias)->TFQ_DMOVIM)	,;  
				sToD((cAlias)->TFO_DTRET) } )			
			
		(cAlias)->(DbSkip())
			
		EndDo
	
		(cAlias)->(DbCloseArea())
		
		
		//Verifica as armas que não tem previsão de retorno, ou data superior
		If Len(aRet) > 0
			For nY := 1 To Len(aABS)
				nX := aScan(aRet,{|x| AllTrim(x[2]) == aABS[nY][1]})
				If nX == 0
					AAdd( aRet, { 	"BR_VERMELHO",;
						aABS[nY][1],;
						aABS[nY][2],;
						aABS[nY][3],;
						aABS[nY][4],;
						aABS[nY][5],;
						aABS[nY][6],;				
						aABS[nY][8] } )	
				Else
					//Verifica se a Data de retorno é maior que a database
					If MV_PAR03 > aABS[nY][8]
						aRet[nX][1] := "BR_VIOLETA"	
					EndIf
				EndIf
			Next nY
	
		Else
			//Indica que todas as armas listadas estão Implantadas e sem previsão de retorno
			For nY := 1 To Len(aABS)
				AAdd( aRet, { 	"BR_VERMELHO",;
					aABS[nY][1],;
					aABS[nY][2],;
					aABS[nY][3],;
					aABS[nY][4],;
					aABS[nY][5],;
					aABS[nY][6],;			
					aABS[nY][8] } )	
			Next nY		
		EndIf
	
	EndIf
		
EndIf

Return(aRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At881DispRet

Verifica as armas e coletes com disponibilidade de retorno
@since		29/11/2013 
@version P11 R9
     
@return lRet, Retorna .T.
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At881AgCli(aABS,aRet)
Local aAgen			:= {}
Local cAlias		:= GetNextAlias()
Local cArma			:= ""				//Variavel com o codigo das armas a serem verificadas
Local nY			:= 0
Local cWhere		:= ""
Local aMov			:= {}

Default aABS		:= {}

If Len(aABS) > 0
		
	If MV_PAR01 == 1
	
		BeginSQL alias cAlias
			SELECT DISTINCT 
				TFQ.TFQ_CODIGO,
				TFO.TFO_ITMOV,
				TFO.TFO_ITCOD,
				TFQ.TFQ_DESTIN,
				TFQ.TFQ_STATUS,
				TFO.TFO_LRET,
				TFO.TFO_DTRET,
				TFQ.TFQ_DMOVIM,
				TE0.TE0_ATIVO,
				TE0.TE0_SITUA,
				TE0.TE0_ENTIDA,
				TE0.TE0_LOCAL,
				TE0.TE0_CLIDES
			FROM
				%Table:TFQ% TFQ
			INNER JOIN 
				%Table:TFO% TFO 
				ON
					TFO.TFO_FILIAL = TFQ.TFQ_FILIAL
				AND 
					TFO.TFO_CDMOV = TFQ.TFQ_CODIGO
				AND 
					TFO.%NotDel%
			INNER JOIN 
				%Table:TE0% TE0  
		       ON 
		       	TE0.TE0_FILIAL = %xfilial:TE0% 
		      	AND 
		      		TE0.TE0_COD = TFO.TFO_ITCOD
		      	AND
		      		TE0.TE0_ENTIDA = 'ABS'
		      	AND 
		      		TE0.%NotDel%

			WHERE
				TFQ.TFQ_FILIAL = %xfilial:TFQ%
			AND
				TFQ.TFQ_STATUS = '1'
			AND
				TFQ.%NotDel%
		EndSQL
		
		While (cAlias)->(!Eof())
		
			AAdd( aAgen, { "BR_AZUL",;
				(cAlias)->TFO_ITCOD,;
				(cAlias)->TE0_ATIVO,;
				(cAlias)->TE0_SITUA,;
				(cAlias)->TE0_LOCAL,;
				(cAlias)->TE0_CLIDES,;
				sToD((cAlias)->TFQ_DMOVIM)	,;  
				sToD((cAlias)->TFO_DTRET) } )			
			
		(cAlias)->(DbSkip())
			
		EndDo
	
		(cAlias)->(DbCloseArea())
		
		
		//Verifica as armas que tem agendamentos superiores
		If Len(aAgen) > 0
			For nY := 1 To Len(aAgen)
				nX := aScan(aRet,{|x| AllTrim(x[2]) == aAgen[nY][2]})
				If nX > 0 
					If MV_PAR02 > aAgen[nY][7]
						aRet[nX][1] := "BR_VERDE_ESCURO"
						aRet[nX][7] := aAgen[nY][7]
					Else
						If MV_PAR02 <= aAgen[nY][7]
							aRet[nX][1] := "BR_AZUL"
							aRet[nX][7] := aAgen[nY][7]
						EndIf
					EndIf
				EndIf
			Next nY
		EndIf
	
	ElseIf MV_PAR01 == 2
	
		BeginSQL alias cAlias
			SELECT DISTINCT 
				TFQ.TFQ_CODIGO,
				TFO.TFO_ITMOV,
				TFO.TFO_ITCOD,
				TFQ.TFQ_DESTIN,
				TFQ.TFQ_STATUS,
				TFO.TFO_LRET,
				TFO.TFO_DTRET,
				TFQ.TFQ_DMOVIM,
				TE1.TE1_SITUA,
				TE1.TE1_ENTIDA,
				TE1.TE1_LOCAL,
				TE1.TE1_CLIDES
			FROM
				%Table:TFQ% TFQ
			INNER JOIN 
				%Table:TFO% TFO 
				ON
					TFO.TFO_FILIAL = TFQ.TFQ_FILIAL
				AND 
					TFO.TFO_CDMOV = TFQ.TFQ_CODIGO
				AND 
					TFO.%NotDel%
			INNER JOIN 
				%Table:TE1% TE1  
		       ON 
		       	TE1.TE1_FILIAL = %xfilial:TE1% 
		      	AND 
		      		TE1.TE1_CODCOL = TFO.TFO_ITCOD
		      	AND
		      		TE1.TE1_ENTIDA = 'ABS'
		      	AND 
		      		TE1.%NotDel%

			WHERE
				TFQ.TFQ_FILIAL = %xfilial:TFQ%
			AND
				TFQ.TFQ_STATUS = '1'
			AND
				TFQ.%NotDel%
		EndSQL
		
		While (cAlias)->(!Eof())
		
			AAdd( aAgen, { "BR_AZUL",;
				(cAlias)->TFO_ITCOD,;
				" "						,;
				(cAlias)->TE1_SITUA,;
				(cAlias)->TE1_LOCAL,;
				(cAlias)->TE1_CLIDES,;
				sToD((cAlias)->TFQ_DMOVIM)	,;  
				sToD((cAlias)->TFO_DTRET) } )				
			
		(cAlias)->(DbSkip())
			
		EndDo
	
		(cAlias)->(DbCloseArea())
		
		
		//Verifica as armas que tem agendamentos superiores
		If Len(aAgen) > 0
			For nY := 1 To Len(aAgen)
				nX := aScan(aRet,{|x| AllTrim(x[2]) == aAgen[nY][2]})
				If nX > 0 
					If MV_PAR02 > aAgen[nY][7]
						aRet[nX][1] := "BR_VERDE_ESCURO"
						aRet[nX][7] := aAgen[nY][7]
					Else
						If MV_PAR02 <= aAgen[nY][7]
							aRet[nX][1] := "BR_AZUL"
							aRet[nX][7] := aAgen[nY][7]
						EndIf
					EndIf
				EndIf
			Next nY
		EndIf
	EndIf	
EndIf

Return(aRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At881Leg

Legenda da Lista de disponibilidade
@since		29/11/2013 
@version P11 R9
     
@return lRet, Retorna .T.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At881Leg()
Local oLegenda  :=  FWLegend():New() 		// Objeto FwLegend.
                                                  	
oLegenda:Add("","BR_VERDE"		 ,STR0006)	// "Arma Disponivel"					
oLegenda:Add("","BR_AMARELO"	 ,STR0007)	// "Arma com Agendamento"
oLegenda:Add("","BR_LARANJA"	 ,STR0008)	// "Arma com Previsão de Retorno"
oLegenda:Add("","BR_VERMELHO"	 ,STR0009)	// "Arma com Previsão de Retorno"
oLegenda:Add("","BR_PRETO"		 ,STR0010)  // "Arma não movimentada"
oLegenda:Add("","BR_PINK"		 ,STR0018)  // "Arma em Manutenção"
oLegenda:Add("","BR_VIOLETA"	 ,STR0019)  // "Arma Implantada com Retorno Expirado"
oLegenda:Add("","BR_AZUL"		 ,STR0020)	// "Arma Implantada com Agendamento Previsto"
oLegenda:Add("","BR_VERDE_ESCURO",STR0021)  // "Arma Implantada com Agendamento Expirado"

oLegenda:Activate()
oLegenda:View()
oLegenda:DeActivate()

Return Nil        
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At881Refresh

Atualiza os parametros e atualiza o Browse
@since		29/11/2013 
@version P11 R9
     
@return lRet, Retorna .T.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At881Refresh(aList,oBrw)
Local lPerg	:= .F.

//Ativa o Pergunte
lPerg:= Pergunte("TECA881",.T.)

If lPerg
	If MV_PAR01 == 1
		//Cria o Array para exibição dos dados
		MsgRun(STR0005,STR0004,{ || aList := At881Query() }) //'Buscando Armamentos....'
		
		//Atualiza o Array em Ordem Numerica
		asort(aList,,, {|x,y| x[2] < y[2] }) 
	
		oBrw:SetArray(aList)
	
		oBrw:Refresh(.T.)
	ElseIf MV_PAR01 == 2
		//Cria o Array para exibição dos dados
		MsgRun(STR0005,STR0004,{ || aList := At881QryCol() }) //'Buscando Armamentos....'
		
		//Atualiza o Array em Ordem Numerica
		asort(aList,,, {|x,y| x[2] < y[2] }) 
	
		oBrw:SetArray(aList)
	
		oBrw:Refresh(.T.)
	EndIf
EndIf
	
Return Nil