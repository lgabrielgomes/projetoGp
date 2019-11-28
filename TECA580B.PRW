#include "TECA580B.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH" 

Static lSrvExt := .F.
Static oHashDia := nil

//----------------------------------------------------------
/*/{Protheus.doc} TECA580B()
Gestão de Escalas  

@Return 	nil
@author 	Serviços
@since 		15/05/2014
/*/
//----------------------------------------------------------
Function TECA580B()
Local aColumns	:= {}
Local aFiltros	:= {}
Local cQuery		:= ""
Local cAliasGES	:= "TECA580BTRAB"
Local oDlg 		:= Nil   							// Janela Principal.
Local aSize	 	:= FWGetDialogSize( oMainWnd ) 	// Array com tamanho da janela.
Local oBrwAcessos := Nil
Local aMenu       := {}
Local nI          := 0

//Foram Criadas as variáveis para controle do PONA080
Private INCLUI := .T.
Private ALTERA := .F.

dbSelectArea("TFF")
dbSelectArea("ABQ")
dbSelectArea("ABB")

//Criacao dos tipos de movimentos PADROES do sistema caso nao existam
At690Unit()

Pergunte("TEC580B",.F.)

lSrvExt := MV_PAR07 == 1

aInfoColumn := At580BCols()
cQuery   := At580BQuery(aInfoColum[2])

SetKey( VK_F12 ,{|| Pergunte("TEC580B",.T.), Refresh(oBrwAcessos)})//Filtro através de F12

//Cria a tela para o browse
DEFINE DIALOG oDlg TITLE STR0001 FROM aSize[1],aSize[2] TO aSize[3],aSize[4] PIXEL // STR0001//"Gestão de Escalas"
	
	oBrwAcessos := FWFormBrowse():New()	
	oBrwAcessos:SetOwner(oDlg)	
	oBrwAcessos:SetDataQuery(.T.)
	oBrwAcessos:SetQuery(cQuery)
	oBrwAcessos:SetAlias(cAliasGES)	
	oBrwAcessos:SetUseFilter( .T. )
	oBrwAcessos:SetFieldFilter(aInfoColumn[2]) 
	oBrwAcessos:SetColumns(aInfoColumn[1])
	
	oBrwAcessos:AddButton( STR0003, {|| Tx580PxC((oBrwAcessos:cAlias)->TFF_COD)} )//"Posto x Calendario"
	oBrwAcessos:AddButton( STR0004, {|| Tx580PxE((oBrwAcessos:cAlias)->TFF_COD)} )//"Posto x Escala"
	oBrwAcessos:AddButton( STR0005, {|| Tx580PxF((oBrwAcessos:cAlias)->TFF_COD)} )//"Posto x Funcionario"
	oBrwAcessos:AddButton( STR0009, {|| At580BAloc((oBrwAcessos:cAlias)->TFF_COD,1)} )//"Alocação por escala"
	oBrwAcessos:AddButton( STR0010, {|| At580BAloc((oBrwAcessos:cAlias)->TFF_COD,2)} )//"Alocação automatica"		 
	If !lSrvExt	 
		oBrwAcessos:AddButton( STR0013, {|| At580GerMem((oBrwAcessos:cAlias)->TFF_CONTRT,(oBrwAcessos:cAlias)->TFF_CONREV) },,,, .F., 2 )	//"Memorando"
	EndIf
	oBrwAcessos:DisableDetails()
	oBrwAcessos:SetDescription(STR0002)  // STR0002//"Gestão de Escalas"
	oBrwAcessos:Activate()
		
ACTIVATE DIALOG oDlg CENTERED

oBrwAcessos:DeActivate()

SetKey( VK_F12, Nil )

Return 


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580BQuery

Query com os dados da gestão de escala

@author 	Serviços
@since 		14/05/2014
@version 	P12
	
@return	cQuery - Query com as informações da gestão de escala
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At580BQuery(aColumns)

Local cQuery := ""
Local nI := 1
Local cOrcDe  := MV_PAR08
Local cOrcAte := MV_PAR09

cQuery += "SELECT "
For nI := 1 To Len(aColumns)
	cQuery += " "+aColumns[nI][1]+","
Next nI

cQuery := substr(cQuery, 1, Len(cQuery)-1)

cQuery += " FROM " + RetSqlName("TFF") + " TFF "

If !lSrvExt
	cQuery += "INNER JOIN " + RetSqlName("CN9") + " CN9 ON " 
	cQuery += "	CN9.CN9_FILIAL = '" + xFilial("CN9") + "' AND "
	cQuery += "	CN9.CN9_NUMERO = TFF.TFF_CONTRT AND "   
	cQuery += "	CN9.CN9_REVISA = TFF.TFF_CONREV AND " 
	cQuery += "	CN9.CN9_SITUAC = '05' AND "
	cQuery += "	CN9.D_E_L_E_T_ = ' ' "
EndIf

cQuery += "INNER JOIN " + RetSqlName("TFL") + " TFL ON " 
cQuery += "	TFL.TFL_FILIAL = '" + xFilial("TFL") + "' AND "
cQuery += "	TFL.TFL_CODIGO = TFF.TFF_CODPAI AND "   
cQuery += "	TFL.D_E_L_E_T_ = ' ' "

cQuery += "INNER JOIN " + RetSqlName("TFJ") + " TFJ ON " 
cQuery += "	TFJ.TFJ_FILIAL = '" + xFilial("TFJ") + "' AND "
cQuery += "	TFJ.TFJ_CODIGO = TFL.TFL_CODPAI AND "
cQuery += "	TFJ.TFJ_STATUS = '1' AND " //Filtra somente orçamento de serviços ativo      
If lSrvExt
	cQuery += "	TFJ.TFJ_SRVEXT = '1' AND " 
	cQuery += "	TFJ.TFJ_CODIGO >= '"+cOrcDe+"' AND "
	If !Empty(cOrcAte)
		cQuery += "	TFJ.TFJ_CODIGO <= '"+cOrcAte+"' AND "
	Endif
EndIf
cQuery += "	TFJ.D_E_L_E_T_ = ' ' "

cQuery += "INNER JOIN " + RetSqlName("ABS") + " ABS ON " 
cQuery += "	ABS.ABS_FILIAL = '" + xFilial("ABS") + "' AND " 
cQuery += "	ABS.ABS_LOCAL = TFF.TFF_LOCAL AND " 
cQuery += "	ABS.D_E_L_E_T_ = ' ' " 

cQuery += "INNER JOIN "+RetSqlName("SA1") + " SA1 ON "
cQuery += "	SA1.A1_FILIAL = '" + xFilial("SA1") + "' AND " 
cQuery += "	SA1.A1_COD = ABS.ABS_CODIGO AND " 
cQuery += "	SA1.A1_LOJA = ABS.ABS_LOJA AND " 
cQuery += "	SA1.D_E_L_E_T_ = ' ' "

cQuery += "INNER JOIN " + RetSqlName("SB1") + " SB1 ON "
cQuery += "	SB1.B1_FILIAL = '" + xFilial("SB1") + "' AND "
cQuery += "	SB1.B1_COD = TFF.TFF_PRODUT AND " 
cQuery += "	SB1.D_E_L_E_T_ = ' ' "

cQuery += "INNER JOIN " + RetSqlName("SRJ") + " SRJ ON " 
cQuery += "	SRJ.RJ_FILIAL = '" + xFilial("SRJ") + "' AND " 
cQuery += "	SRJ.RJ_FUNCAO = TFF.TFF_FUNCAO AND  "
cQuery += "	SRJ.D_E_L_E_T_ = ' ' "

cQuery += "WHERE TFF.TFF_FILIAL = '" + xFilial("TFF") + "' AND "
If !lSrvExt
	cQuery += "	TFF.TFF_CONTRT BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"' AND "
EndIf
cQuery += "	ABS.ABS_CODIGO BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR03+"' AND "
cQuery += "	ABS.ABS_LOJA BETWEEN '"+MV_PAR02+"' AND '"+MV_PAR04+"' AND "
cQuery += " TFF.TFF_CODSUB = '      '  AND TFF.D_E_L_E_T_ = ' ' "
If lSrvExt
	cQuery += "ORDER BY TFF.TFF_LOCAL"
Else
	cQuery += "ORDER BY TFF.TFF_LOCAL, TFF.TFF_CONTRT, TFF.TFF_CONREV"  
EndIf

Return(cQuery)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580BCols

Colunas e filtros para o browse com os dados da gestão de escala

@author 	Serviços
@since 		14/05/2014
@version 	P12

@return	aInfoColumn - [aColumns - Colunas para o browse, aFiltros - Descrição dos filtros do Browse]
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At580BCols()

Local nI		 := 0 
Local aColumns := {}
Local aFiltros := {}
Local cCampo   := ''
Local nLinha   := 0
Local aCampos  := {}

aCampos  := { "TFF_LOCAL", "ABS_DESCRI", "A1_COD", "A1_LOJA", "A1_NOME", "TFF_COD", "TFF_PRODUT", "B1_DESC", "TFF_QTDVEN",; 
			  "TFF_CONTRT","TFF_CONREV","TFL_CODPAI", "TFF_ESCALA", "TFF_TURNO", "TFF_FUNCAO", "RJ_DESC" }

dbSelectArea("SX3")
SX3->(DbSetOrder(2))

For nI:=1 To Len(aCampos)

	If SX3->(dbSeek(aCampos[nI]))
	
		cCampo := AllTrim(SX3->X3_CAMPO)
		
		AAdd(aColumns,FWBrwColumn():New())
		nLinha := Len(aColumns)
	   	aColumns[nLinha]:SetType(SX3->X3_TIPO)
	   	aColumns[nLinha]:SetTitle(X3Titulo())
		aColumns[nLinha]:SetSize(SX3->X3_TAMANHO)
		aColumns[nLinha]:SetDecimal(SX3->X3_DECIMAL)		
		aColumns[nLinha]:SetData(&("{||" + cCampo + "}"))
		
		aadd(aFiltros,{cCampo,X3Titulo(),SX3->X3_TIPO,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_PICTURE})
		
	EndIf
	
Next nI

SX3->(dbCloseArea())

Return{aColumns, aFiltros}


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580BAloc
Rotinas para a alocação do recurso selecionado  

@author 	Serviços
@since 		03/07/2014
@version 	P12

/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580BAloc( cCodTFF, nOpcx )

Local lRh := FindFunction("U_PNMSESC") .And. FindFunction("U_PNMSCAL") 

Local lConfirm

If lRh
	If nOpcx == 1 // Alocação por escala
		
		If Pergunte( "TEC580BE", .T. )
		
			dbSelectArea("TFF")
			TFF->(dbSetOrder(1))
			
			If TFF->(dbSeek(xFilial("TFF")+cCodTFF)).And. At580VlEsc(TFF->TFF_ESCALA,.T.)
				lConfirm := (FWExecView( STR0009, "VIEWDEF.TECA330A", MODEL_OPERATION_UPDATE, /*oDlg*/, {||.T.} /*bCloseOk*/,;  //  "Alocacao por escala" 
											{||.T.}/*bOk*/,/*nReducao*/, /*aButtons*/, {||.T.}/*bCancel*/ ) == 0 )								
			EndIf									
											
		EndIf
	
	ElseIf nOpcx == 2 // Alocação automática
	
		If Pergunte( "TEC580BA", .T. )					
			At330AloAut( MV_PAR01, MV_PAR02, MV_PAR03, MV_PAR04, MV_PAR05, MV_PAR06, MV_PAR07, MV_PAR08, MV_PAR09, MV_PAR10, MV_PAR11, MV_PAR12, MV_PAR13, MV_PAR14,,,,lSrvExt )	
		EndIf			
		
	EndIf
Else
	Help( " ", 1, STR0011, Nil, STR0012, 1 )  //"Atenção"#"Para que seja possivel executar essa rotina, aplique o patch para as configurações do RH!"
EndIf

Return(Nil)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Tx580PxC

Chamada do relacionamento Feriado X Posto 

@author 	Serviços
@since 		08/04/2014
@version 	P12

/*/
//--------------------------------------------------------------------------------------------------------------------
Function Tx580PxC(cCodTFF)

Local nPercReducao := 50                

//Foi necessario abrir o SX3
DbSelectArea("SX3")
SX3->(DbSetOrder(1))

DbSelectArea("TFF")
TFF->(DbSetOrder(1))
	
If TFF->(DbSeek(xFilial("TFF")+cCodTFF))
	FWExecView(Upper(STR0006),"VIEWDEF.TECA580D",MODEL_OPERATION_UPDATE,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,nPercReducao)	//"Relacionamento FeriadoxPosto"
EndIf

Return(.T.)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Tx580PxE

Chamada para o relacionamento  Posto X Escala

@author 	Serviços
@since 		08/04/2014
@version 	P12

/*/
//--------------------------------------------------------------------------------------------------------------------
Function Tx580PxE(cCodTFF)

Local nPercReducao := 50                

//Foi necessario abrir o SX3
DbSelectArea("SX3")
SX3->(DbSetOrder(1))

DbSelectArea("TFF")
TFF->(DbSetOrder(1))
	
If TFF->(DbSeek(xFilial("TFF")+cCodTFF))
	FWExecView(Upper(STR0007),"VIEWDEF.TECA580C",MODEL_OPERATION_UPDATE,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,nPercReducao)	//"Relacionamento PostoXEscala"
EndIf

Return(.T.)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Tx580PxE

Chamada para o relacionamento  Posto X Funcionario

@author 	Serviços
@since 		08/04/2014
@version 	P12

/*/
//--------------------------------------------------------------------------------------------------------------------
Function Tx580PxF(cCodTFF)
Local lMV_GSGEHOR := SuperGetMV("MV_GSGEHOR",,.F.)
Local aArea

//Foi necessario abrir o SX3
DbSelectArea("SX3")
SX3->(DbSetOrder(1))

DbSelectArea("TFF")
TFF->(DbSetOrder(1))
	
If TFF->(DbSeek(xFilial("TFF")+cCodTFF)) .And. At580VlEsc(TFF->TFF_ESCALA,.T.) .And. TFF->TFF_ENCE != '1'
	If lMV_GSGEHOR
		aArea := GetArea()
		At580EGHor((VldEscala(TFF->(RECNO()))))
		RestArea(aArea)
	EndIf

	FWExecView(Upper(STR0008),"VIEWDEF.TECA580E",MODEL_OPERATION_UPDATE,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/)	//"Relacionamento PostoXFuncionario"	
	If lMV_GSGEHOR	
		At580bKill()
	EndIf
EndIf

Return(.T.)

Static Function Refresh(oBrowse)
	Local aInfoColumn := {}
	Local cQuery   	  := ""
	
	lSrvExt := MV_PAR07 == 1
	
	aInfoColumn := At580BCols()
	cQuery   	:= At580BQuery(aInfoColum[2])
	
	oBrowse:SetQuery(cQuery)
	
	oBrowse:Refresh( .T. )
	oBrowse:ExecuteFilter()
Return


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580GerMem
@since        05/02/2015
@version      12
@sample       At580GerMem(cNumContr, cRevContr)		
@param        cNumContr - Numero do Contrato
@param        cRevContr - Numero da Revisao
@return       lRet, Retorno logico
@description Realiza consistencias e chama tela de memorando
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At580GerMem(cNumContr, cRevContr)

Local lRet      := .F.
Local aAreaMe   := GetArea()
Local cAliasCN9 := GetNextAlias()
Local cMaxRev   := Space(TamSX3("CN9_REVISA")[1])

// Somente podera gerar o memorando para contratos vigentes
If ! Empty(cNumContr)
	DbSelectArea("CN9")
	CN9->(DbSetOrder(1)) // CN9_FILIAL, CN9_NUMERO, CN9_REVISA
	If CN9->(DbSeek(xFilial("CN9")+cNumContr+cRevContr))

		If CN9_SITUAC == '05'
		// Verifica se contrato possui revisao
			BeginSql Alias cAliasCN9

				SELECT MAX(CN9.CN9_REVISA) AS CN9_REVISA
				  FROM %table:CN9% CN9
				 WHERE CN9.CN9_FILIAL = %xFilial:CN9%
				   AND CN9.%notDel%
				   AND CN9.CN9_NUMERO = %Exp:cNumContr%
				   AND CN9.CN9_SITUAC = '05'

			EndSql

			DbSelectArea(cAliasCN9)
			While (cAliasCN9)->( !Eof() )
				cMaxRev := (cAliasCN9)-> CN9_REVISA
				(cAliasCN9)->(DbSkip())
			EndDo
			(cAliasCN9)->( DbCloseArea() )

			If cMaxRev <> cRevContr
				Help( ' ', 1, 'TECA580B', , STR0014, 1, 0 )	//"Não é possível gerar o memorando para revisões anteriores"
			Else
				If MSGYESNO( STR0015, STR0013 ) //"Deseja realmente gerar os memorandos?" # "Memorando"
				// Chama rotina de geracao do memorando
					lRet := At330GerMem(cNumContr, cRevContr, '')
				Else
					lRet := .F.
				EndIf
			EndIf
		Else
			Help( ' ', 1, 'TECA580B', , STR0016, 1, 0 )	//"Permitido somente para contratos vigentes"
		EndIf
	Else
		Help( ' ', 1, 'TECA580B', , STR0017, 1, 0 )	//"Contrato não localizado"
	EndIf
Else
	Help( ' ', 1, 'TECA580B', , STR0018, 1, 0 )	//"Não existe contrato gerado"
EndIf

RestArea(aAreaMe)

Return lRet

/*/{Protheus.doc} At580BSrvExt
Retorna a variável static lSrvExt, para identificar se 
	
@since   11/11/2016
@version 12
@return  lRet, Retorno logico
/*/
Function At580BSrvExt()
Return lSrvExt

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} VldEscala
@description Valida integridade da Escala, verificando os dados do turno. Também preenche a variavel
               static de HashMap, utilizada no TECA580E
@author       Mateus Boiani
@since        27/08/2018
@param        nRecTFF, int, RECNO da TFF
@return       lRet, bool, .T. se a escala estiver OK
/*/
//--------------------------------------------------------------------------------------------------------------------
Function VldEscala(nRecTFF,lMsg)
Local lRet 			:= .T.
Local cAliasAux 	:= GetNextAlias()
Local cSQl 			:= ""
Local cEscala 		:= ""
Local cErrorMsg 	:= ""
Local cTurno 		:= ""
Local aDias 		:= {}
Local nDiaModelo	:= 0
Local nX 			:= 0
Local nY 			:= 0
Local nAux 			:= 0
Local cItemRH 		:= ""
Local cCampo 		:= ""
Local cSeq 			:= ""
Local cDia 			:= ""
Local cValEsp 		:= ""
Local cValEnc 		:= ""
Local aAux 			:= {}
Local lMovimentar 	:= IsInCallStack("TECA336")
Default lMsg		:= .T.

DbSelectArea("TFF")
DbGoTo(nRecTFF)

cEscala := TFF->TFF_ESCALA
cItemRH := TFF->TFF_COD

If ( lRet := !EMPTY(cEscala) )
	cSQl += " SELECT TDX.TDX_TURNO FROM "
	cSQl += RetSqlName('TDX') + " TDX "
	cSQl += " WHERE TDX.TDX_CODTDW = '" + cEscala + "' AND "
	cSQl += " TDX.D_E_L_E_T_ = ' ' AND TDX.TDX_FILIAL = '" + xFilial("TDX") + "'"
	cSQl := ChangeQuery(cSQl)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cSQl),cAliasAux, .F., .T.)
	
	While (cAliasAux)->(!Eof())
		If EMPTY(cTurno)
			cTurno := (cAliasAux)->(TDX_TURNO)
		EndIf
		If cTurno == (cAliasAux)->(TDX_TURNO)
			(cAliasAux)->(DbSkip())
		Else
			lRet := .F.
			cErrorMsg := STR0043 //"O parâmetro MV_GSGEHOR está ativo, porém, para que a flexibilidade de horários seja utilizada, é necessário que todos os turnos de trabalho da escala possuam a mesma estrutura."
			cErrorMsg += CRLF
			cErrorMsg += STR0044 //"O sistema localizou a seguinte incompatibilidade:"
			cErrorMsg += CRLF + CRLF
			cErrorMsg += STR0045 //"Turnos de trabalho diferentes (TDX_TURNO) em uma mesma escala (TDX_CODTDW)"
			cErrorMsg += CRLF + CRLF
			If lMovimentar
				cErrorMsg += "A rotina de Movimentação de Atendente será executada normalmente, porém, sem a liberação dos campos de customização de hora de entrada e hora de saída."	 //"A rotina de Movimentação de Atendente será executada normalmente, porém, sem a liberação dos campos de customização de hora de entrada e hora de saída."		
			Else
				cErrorMsg += STR0046 //"A rotina de Posto x Funcionário será executada normalmente, porém, sem a adição dos campos de customização de hora de entrada e hora de saída."
			Endif			
			Exit
		EndIf
	End
	(cAliasAux)->(DbCloseArea())
	
	If lRet
		cAliasAux := GetNextAlias()
		cSQl := " SELECT "
		For nX := 1 To LEN(GetCpoArr())
			cSQl += " PJ." + GetCpoData(nX) + IIF(nX == LEN(GetCpoArr()), SPACE(2) , ", " )
		Next
		cSQl += " FROM "
		cSQl += RetSqlName('SPJ') + " PJ "
		cSQl += " WHERE PJ.D_E_L_E_T_ = ' ' AND PJ.PJ_FILIAL = '" + xFilial("SPJ") + "' AND "
		cSQl += " PJ.PJ_TURNO = '" + cTurno + "' "
		cSQl := ChangeQuery(cSQl)
		dbUseArea( .T., "TOPCONN", TCGENQRY(,,cSQl),cAliasAux, .F., .T.)
		
		While (cAliasAux)->(!Eof())
			For nX := 1 To LEN(GetCpoArr())
				AADD(aAux, (&("('" + cAliasAux + "')->(" + GetCpoData(nX) + ")")) )
			Next
			AADD(aDias, aAux)
			aAux := {}
			(cAliasAux)->(DbSkip())
		End
		(cAliasAux)->(DbCloseArea())
		
		nDiaModelo := ASCAN(aDias, {|f| f[1] == 'S' .AND. f[16] > 0})
		
		For nX := 1 To LEN(aDias)
			If lRet				
				For nY := 4 to 16
					If ( nAux :=  ASCAN(aDias, {|f| f[nY] > 0 .AND. f[nY] != aDias[nDiaModelo][nY] }) ) > 0
						lRet := .F.
						cCampo := Alltrim(GetSX3Cache( GetCpoData(nY), "X3_CAMPO" ))
						cSeq := aDias[nAux][2]
						cDia := TECCdow( VAL(aDias[nAux][3]) )
						cValEsp := Alltrim(AllToChar( aDias[nDiaModelo][nY]  ))
						cValEnc := Alltrim(AllToChar( aDias[nAux][nY]  ))
						
						cErrorMsg := STR0043 //"O parâmetro MV_GSGEHOR está ativo, porém, para que a flexibilidade de horários seja utilizada, é necessário que todos os turnos de trabalho da escala possuam a mesma estrutura."
						cErrorMsg += CRLF
						cErrorMsg += STR0044 //"O sistema localizou a seguinte incompatibilidade:"
						cErrorMsg += CRLF + CRLF
						cErrorMsg += STR0047 //"Horário de entrada ou saída diverge em um ou mais dias da escala."
						cErrorMsg += CRLF + CRLF
						If lMovimentar
							cErrorMsg += "A rotina de Movimentação de Atendente será executada normalmente, porém, sem a liberação dos campos de customização de hora de entrada e hora de saída."	 //"A rotina de Movimentação de Atendente será executada normalmente, porém, sem a liberação dos campos de customização de hora de entrada e hora de saída."		
						Else
							cErrorMsg += STR0046 //"A rotina de Posto x Funcionário será executada normalmente, porém, sem a adição dos campos de customização de hora de entrada e hora de saída."
						Endif	
						Exit
					EndIf
				Next
				
				For nY := 17 to 23
					If ( nAux :=  ASCAN(aDias, {|f| f[nY] != aDias[nDiaModelo][nY] }) ) > 0
						lRet := .F.
						cCampo := Alltrim(GetSX3Cache( GetCpoData(nY), "X3_CAMPO" ))
						cSeq := aDias[nAux][2]
						cDia := TECCdow( VAL(aDias[nAux][3]) )
						cValEsp := Alltrim(AllToChar( aDias[nDiaModelo][nY]  ))
						cValEnc := Alltrim(AllToChar( aDias[nAux][nY]  ))
						
						cErrorMsg := STR0043 //"O parâmetro MV_GSGEHOR está ativo, porém, para que a flexibilidade de horários seja utilizada, é necessário que todos os turnos de trabalho da escala possuam a mesma estrutura."
						cErrorMsg += CRLF
						cErrorMsg += STR0044 //"O sistema localizou a seguinte incompatibilidade:"
						cErrorMsg += CRLF + CRLF
						cErrorMsg += STR0048 //"Configuração de jornada contínua ou de intervalo diverge na configuração da escala."
						cErrorMsg += CRLF + CRLF
						If lMovimentar
							cErrorMsg += "A rotina de Movimentação de Atendente será executada normalmente, porém, sem a liberação dos campos de customização de hora de entrada e hora de saída."	 //"A rotina de Movimentação de Atendente será executada normalmente, porém, sem a liberação dos campos de customização de hora de entrada e hora de saída."		
						Else
							cErrorMsg += STR0046 //"A rotina de Posto x Funcionário será executada normalmente, porém, sem a adição dos campos de customização de hora de entrada e hora de saída."
						Endif	
						Exit
					EndIf
				Next
			Else
				Exit
			EndIf
		Next
	EndIf
Else
	cErrorMsg := STR0043 //"O parâmetro MV_GSGEHOR está ativo, porém, para que a flexibilidade de horários seja utilizada, é necessário que todos os turnos de trabalho da escala possuam a mesma estrutura."
	cErrorMsg += CRLF
	cErrorMsg += STR0044 //"O sistema localizou a seguinte incompatibilidade:"
	cErrorMsg += CRLF + CRLF
	cErrorMsg := STR0049 //"Escala não configurada. Utilize a rotina 'Posto x Escala' para selecionar a escala deste item de RH"
	cErrorMsg += CRLF + CRLF
	If lMovimentar
		cErrorMsg += "A rotina de Movimentação de Atendente será executada normalmente, porém, sem a liberação dos campos de customização de hora de entrada e hora de saída."	 //"A rotina de Movimentação de Atendente será executada normalmente, porém, sem a liberação dos campos de customização de hora de entrada e hora de saída."		
	Else
		cErrorMsg += STR0046 //"A rotina de Posto x Funcionário será executada normalmente, porém, sem a adição dos campos de customização de hora de entrada e hora de saída."
	Endif	
EndIf
If !Empty(cErrorMsg) .AND. !ISBlind() .And. !lRet .And. lMsg
	AtShowLog(cErrorMsg + CRLF + CRLF +;
			REPLICATE("-",35) + CRLF +;
			IIF(EMPTY(cItemRH),"",STR0050 + " " + cItemRH + CRLF )+; //"Item de RH:"
			IIF(EMPTY(cEscala),"",STR0051 + " " + cEscala + CRLF )+; //"Escala:"
			IIF(EMPTY(cTurno),"",STR0052 + " " + cTurno + CRLF )+; //"Turno:"
			IIF(EMPTY(cSeq),"",STR0053 + " " + cSeq + CRLF)+; //"Sequência:"
			IIF(EMPTY(cDia),"",STR0054 + " " + cDia + CRLF )+; //"Dia:"
			IIF(EMPTY(cCampo),"",STR0055 + " " + cCampo + CRLF )+; //"Campo:"
			IIF(EMPTY(cValEsp),"",STR0056 + " " + cValEsp + CRLF )+; //"Valor Esperado:"
			IIF(EMPTY(cValEnc),"",STR0057 + " " + cValEnc + CRLF); //"Valor Encontrado:"
			,STR0058) //"Gestão de Escalas"
ElseIf lRet
	oHashDia := FwHashMap():New()
	For nX := 1 to LEN(GetCpoArr())
		oHashDia:Put(GetCpoData(nX),aDias[nDiaModelo][nX])
	Next
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECCdow
@description Retorna a descrição de um dia da semana, baseando-se no número do dia. 
				Função similar a cDow(), porém recebe int ao invés de date
@author       Mateus Boiani
@since        27/08/2018
@param        nDia, int, dia da semana. (exemplo: 1 = Domingo , 2 = Segunda , etc..)
@return       cRet, string, descrição do dia da semana
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TECCdow(nDia)
Local cRet := ""
Default nDia := 0
If nDia == 1
	cRet := STR0059 //"Domingo"
ElseIf nDia == 2
	cRet := STR0060 //"Segunda-feira"
ElseIf nDia == 3
	cRet := STR0061 //"Terça-feira"
ElseIf nDia == 4
	cRet := STR0062 //"Quarta-feira"
ElseIf nDia == 5
	cRet := STR0063 //"Quinta-feira"
ElseIf nDia == 6
	cRet := STR0064 //"Sexta-feira"
ElseIf nDia == 7
	cRet := STR0065 //"Sábado"
EndIf

Return cRet
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} GetCpoData
@description Retorna o nome do campo na posição N do array de campos pesquisados na SPJ
@author       Mateus Boiani
@since        27/08/2018
@param        nCpo, int, posição do campo
@return       cRet, string, nome do campo
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function GetCpoData(nCpo)

Return ( GetCpoArr()[nCpo] )
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} GetCpoArr
@description Retorna o array dos campos pesquisados na SPJ
@author       Mateus Boiani
@since        27/08/2018
@return       aRet, array, array dos campos utilizados
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function GetCpoArr()

Local aRet := {;
				"PJ_TPDIA",;   //[ 1]
				"PJ_SEMANA",;  //[ 2]
				"PJ_DIA",;     //[ 3]
				"PJ_ENTRA1",;  //[ 4]
				"PJ_ENTRA2",;  //[ 5]
				"PJ_ENTRA3",;  //[ 6]
				"PJ_ENTRA4",;  //[ 7]
				"PJ_SAIDA1",;  //[ 8]
				"PJ_SAIDA2",;  //[ 9]
				"PJ_SAIDA3",;  //[10]
				"PJ_SAIDA4",;  //[11]
				"PJ_HRSTRAB",; //[12]
				"PJ_HRSTRA2",; //[13]
				"PJ_HRSTRA3",; //[14]
				"PJ_HRSTRA4",; //[15]
				"PJ_HRTOTAL",; //[16]
				"PJ_JND1CON",; //[17]
				"PJ_JND2CON",; //[18]
				"PJ_JND3CON",; //[19]
				"PJ_JND4CON",; //[20]
				"PJ_INTERV1",; //[21]
				"PJ_INTERV2",; //[22]
				"PJ_INTERV3",; //[23]
				"PJ_TURNO";    //[24]
				}
Return aRet
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580bHash
@description Retorna o HashMap que será utilizado pra montar o "Dia Modelo"
@author       Mateus Boiani
@since        27/08/2018
@return       oHashDia, obj, hashmap static utilizado no "Dia Modelo"
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580bHash()

Return oHashDia
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580bHGet
@description Executa o método Get no hashMap Static do dia modelo. Função utilizada no TECA580E
@author       Mateus Boiani
@since        27/08/2018
@param        cKey, string, chave do hashmap
@return       xValue, unknown, Valor da chave cKey do hashmap oHashDia
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580bHGet(cKey)

Return ( oHashDia:Get(cKey) )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580bKill
@description Executa o método Destroy no hashMap Static do dia modelo. Função utilizada no TECA580E
@author       Kaique Schiller
@since        15/01/2019
@param        cKey, string, chave do hashmap
@return       xValue, unknown, Valor da chave cKey do hashmap oHashDia
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580bKill()

If VALTYPE( At580bHash() ) == 'O'
	oHashDia:Destroy()
	FreeObj(oHashDia)
	oHashDia := nil
	DelClassIntF()
EndIf

Return .T.