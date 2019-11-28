#Include "Protheus.ch"
#Include "RwMake.ch" 
#Include "TopConn.ch"
#Include "TECA353.ch"


#DEFINE INSALUBRIDADE 1
#DEFINE PERICULOSIDADE 2

#DEFINE NENHUM ""
#DEFINE MINIMO "2"
#DEFINE MEDIO "3"
#DEFINE MAXIMO "4"

#DEFINE INTEGRAL "2"
#DEFINE PROPORCIONAL "3"

#DEFINE ID_PERICULOSIDADE 		36
#DEFINE ID_INSALUBRIDADE_MAXIMA	39
#DEFINE ID_INSALUBRIDADE_MEDIA	38
#DEFINE ID_INSALUBRIDADE_MINIMA	37


#DEFINE ADICIONAIS_ADICIONAL	1
#DEFINE ADICIONAIS_TIPO			2
#DEFINE ADICIONAIS_GRAU			3
#DEFINE ADICIONAIS_HORAS			4
#DEFINE ADICIONAIS_AB9			5
#DEFINE ADICIONAIS_CC			6
#DEFINE ADICIONAIS_PREV			6

Static aCacheCFol := {}
  
/*------------------------------------------------------------------------------
{Protheus.doc} TECA353

@sample 	 TECA353() 
@since		 25/05/2015       
@version	 P12    
@description Envio de adicionais de periculosidade e insalubridade 
------------------------------------------------------------------------------*/

Function TECA353()
 
	Local lPerg := .F.
 
	lPerg := Pergunte("TECA353",.T.)
 
	If lPerg == .T.
		MsgRun( STR0017,, {|| At353Gera() })//"Processando..."
	EndIf
	

Return()



/*------------------------------------------------------------------------------
{Protheus.doc} At353Gera
	
@since       25/05/2015
@version     12
@param             
@return           
@description Efetiva a inclusão ou exclusão de lançamentos de adicionais de 
             periculosidade e insalubridade no SIGAGPE via GPEA580
------------------------------------------------------------------------------*/
Function At353Gera()

	Local aAdicionais := {}	
	Local nPos := 0
	Local cFilFunOld := ""
	Local cMatFunOld := ""
	Local lErro := .F.
	
	cQuery :="SELECT SRA.RA_FILIAL, SRA.RA_MAT, SRA.RA_NOME, SRA.RA_ADCINS, SRA.RA_ADCPERI, SRA.RA_PROCES, SRA.RA_HRSMES, SRA.RA_CC, SRA.RA_CODFUNC, "
	cQuery += CRLF + "TFF.TFF_PERICU, TFF.TFF_INSALU, TFF.TFF_GRAUIN, "
	cQuery += CRLF + "AA1.AA1_FUNFIL, AA1.AA1_CDFUNC, "
	cQuery += CRLF + "ABS.ABS_CCUSTO, "
	cQuery += CRLF + "AB9.R_E_C_N_O_ AS RECAB9, ABA_QUANT HORAS "	
	
	cQuery += CRLF + " FROM " + RetSqlName("ABB")+ " ABB, "
	cQuery += CRLF +            RetSqlName("AA1")+ " AA1, "
	cQuery += CRLF +            RetSqlName("SRA")+ " SRA, "
	cQuery += CRLF +            RetSqlName("AB9")+ " AB9, "
	cQuery += CRLF +            RetSqlName("ABA")+ " ABA, "
	cQuery += CRLF +            RetSqlName("ABQ")+ " ABQ, "
	cQuery += CRLF +            RetSqlName("TFF")+ " TFF, "
	cQuery += CRLF +            RetSqlName("ABS")+ " ABS  "	

	cQuery += CRLF + " WHERE ABB.ABB_FILIAL  = '"+ xFilial("ABB") +"'"
	cQuery += CRLF + " AND ABB.ABB_CODTEC BETWEEN '"+ Mv_par01 +"' AND '"+ Mv_par02 +"'"
	cQuery += CRLF + " AND ABB.ABB_DTINI  >= '"+ DtoS(Mv_Par03) +"'"
	cQuery += CRLF + " AND ABB.ABB_DTFIM  <= '"+ DtoS(Mv_Par04) +"'"
	cQuery += CRLF + " AND ABB.ABB_ATENDE  = '1'"
	cQuery += CRLF + " AND ABB.ABB_ATIVO   = '1'"
	cQuery += CRLF + " AND ABB.ABB_LOCAL  <> ' '"
	cQuery += CRLF + " AND ABB.D_E_L_E_T_  = ' '"

	cQuery += CRLF + " AND ABS.ABS_FILIAL  = '"+ xFilial("ABS") +"'"
	cQuery += CRLF + " AND ABS.ABS_LOCAL  = ABB.ABB_LOCAL"
	cQuery += CRLF + " AND ABS.D_E_L_E_T_  = ' '"

	cQuery += CRLF + " AND AA1.AA1_FILIAL  = '"+ xFilial("AA1") +"'"
	cQuery += CRLF + " AND AA1.AA1_CODTEC  = ABB.ABB_CODTEC"
	cQuery += CRLF + " AND AA1.D_E_L_E_T_  = ' '"

	cQuery += CRLF + " AND SRA.RA_FILIAL   = AA1.AA1_FUNFIL"
	cQuery += CRLF + " AND SRA.RA_MAT      = AA1.AA1_CDFUNC"
	cQuery += CRLF + " AND SRA.D_E_L_E_T_  = ' '"
	
	cQuery += CRLF + " AND AB9.AB9_FILIAL  = '"+ xFilial("AB9") +"'"
	cQuery += CRLF + " AND AB9.AB9_ATAUT   = ABB.ABB_CODIGO"	 
	cQuery += CRLF + " AND SUBSTRING( AB9.AB9_NUMOS, 1, 6 ) = ABB.ABB_NUMOS"
	cQuery += CRLF + " AND AB9.AB9_CODTEC = ABB.ABB_CODTEC"
	If Mv_par06  == 1
		cQuery += CRLF + " AND AB9.AB9_ADIENV  = 'F'"
	Else
		cQuery += CRLF + " AND AB9.AB9_ADIENV  = 'T'"
	EndIf
	cQuery += CRLF + " AND AB9.D_E_L_E_T_ = ' '"

	cQuery += CRLF + " AND ABA.ABA_FILIAL = '"+ xFilial("ABA") +"'"
	cQuery += CRLF + " AND ABA.ABA_NUMOS = AB9.AB9_NUMOS"
	cQuery += CRLF + " AND ABA.ABA_SEQ = AB9.AB9_SEQ"
	cQuery += CRLF + " AND ABA.D_E_L_E_T_ = ' '"
	
	cQuery += CRLF + " AND ABQ.ABQ_FILIAL  = '"+ xFilial("ABQ") +"'"
	cQuery += CRLF + " AND ABQ.ABQ_CONTRT || ABQ.ABQ_ITEM || ABQ.ABQ_ORIGEM = ABB.ABB_IDCFAL"
	cQuery += CRLF + " AND ABQ.D_E_L_E_T_  = ' '"

	cQuery += CRLF + " AND TFF.TFF_FILIAL  = ABQ.ABQ_FILTFF"
	cQuery += CRLF + " AND TFF.TFF_COD     = ABQ.ABQ_CODTFF"
	cQuery += CRLF + " AND (TFF.TFF_PERICU <> '1' OR TFF.TFF_INSALU <> '1')"
	cQuery += CRLF + " AND TFF.D_E_L_E_T_  = ' '"
	
	cQuery += CRLF + " ORDER BY ABB.ABB_CODTEC"
 
	nTotReg := 0
	cAliasA := GetNextAlias()
	cQuery := ChangeQuery(cQuery)
	DbUseArea( .T., 'TOPCONN', TCGENQRY(,,cQuery), cAliasA , .T., .T.)
	aEval( ABB->(DbStruct()),{|x| If(x[2] != "C", TcSetField(cAliasA, AllTrim(x[1]), x[2], x[3], x[4]),Nil)})

	DbSelectArea( cAliasA )
	(cAliasA)->( DbEval( { || nTotReg++ },,{ || !Eof() } ) )
	(cAliasA)->( DbGoTop() )
	
	ProcRegua( nTotReg )
 
	If nTotReg <= 0
		Aviso(STR0001,STR0003, {STR0001}) // "Atenção" # "Não há dados, verifique parâmetros # "OK"
		Return()
	EndIf
	
	If (cAliasA)->(!EOF())
		cFilFunOld := (cAliasA)->RA_FILIAL
		cMatFunOld := (cAliasA)->RA_MAT
	EndIf
	

	While (cAliasA)->(!Eof())
	
		//Verifica se mudou funcionário e envia informações para RH.
		If cFilFunOld != (cAliasA)->RA_FILIAL .OR. cMatFunOld != (cAliasA)->RA_MAT
						
			If !At353EnvRH(cFilFunOld, cMatFunOld, aAdicionais)//Envia para RH
				lErro := .T.
			EndIf
						
			//Reinicia Variaveis
			aAdicionais	:= {}
			cFilFunOld := (cAliasA)->RA_FILIAL
			cMatFunOld := (cAliasA)->RA_MAT
			
		EndIf
		
		//Armazena informação relativa a horas e ao nivel de adicional (integral/proporcional,  maximo/medio/minimo)
				
		//Periculosidade
		If !Empty((cAliasA)->TFF_PERICU) .AND. (cAliasA)->TFF_PERICU != "1" 
			
			//Busca posição por tipo e grau
			nPos := aScan(aAdicionais, {|x|	x[ADICIONAIS_ADICIONAL] == PERICULOSIDADE .AND.;
				 								x[ADICIONAIS_TIPO] == (cAliasA)->TFF_PERICU .AND.;
				  								x[ADICIONAIS_GRAU] == NENHUM .AND.;
				  								x[ADICIONAIS_CC] == (cAliasA)->ABS_CCUSTO})
				  								
			If nPos == 0
				aAdd(aAdicionais, Array(ADICIONAIS_PREV))
				nPos := Len(aAdicionais)
				aAdicionais[nPos][ADICIONAIS_ADICIONAL] 	:= PERICULOSIDADE
				aAdicionais[nPos][ADICIONAIS_TIPO] 		:= (cAliasA)->TFF_PERICU
				aAdicionais[nPos][ADICIONAIS_GRAU] 		:= NENHUM
				aAdicionais[nPos][ADICIONAIS_HORAS] 		:= (cAliasA)->HORAS
				aAdicionais[nPos][ADICIONAIS_AB9] 			:= {(cAliasA)->RECAB9}
				aAdicionais[nPos][ADICIONAIS_CC] 			:= If(!Empty((cAliasA)->ABS_CCUSTO),(cAliasA)->ABS_CCUSTO,(cAliasA)->RA_CC)
	
			Else
				aAdicionais[nPos][ADICIONAIS_HORAS] += (cAliasA)->HORAS
				aAdd(aAdicionais[nPos][ADICIONAIS_AB9],(cAliasA)->RECAB9 )
			EndIf		
			
		EndIf
		
		
		//Insalubridade
		If !Empty((cAliasA)->TFF_INSALU) .AND. (cAliasA)->TFF_INSALU != "1" 	
			
			//Busca posição por tipo e grau
			nPos := aScan(aAdicionais, {|x| x[ADICIONAIS_ADICIONAL] == INSALUBRIDADE .AND. ;
												x[ADICIONAIS_TIPO] == (cAliasA)->TFF_INSALU .AND.;
												x[ADICIONAIS_GRAU] == (cAliasA)->TFF_GRAUIN .AND.;
				  								x[ADICIONAIS_CC] == (cAliasA)->ABS_CCUSTO})		
			If nPos == 0
				aAdd(aAdicionais, Array(ADICIONAIS_PREV))
				nPos := Len(aAdicionais)
				aAdicionais[nPos][ADICIONAIS_ADICIONAL] 	:= INSALUBRIDADE
				aAdicionais[nPos][ADICIONAIS_TIPO] 		:= (cAliasA)->TFF_INSALU
				aAdicionais[nPos][ADICIONAIS_GRAU] 		:= (cAliasA)->TFF_GRAUIN
				aAdicionais[nPos][ADICIONAIS_HORAS] 		:= (cAliasA)->HORAS
				aAdicionais[nPos][ADICIONAIS_AB9] 			:= {(cAliasA)->RECAB9}
				aAdicionais[nPos][ADICIONAIS_CC] 			:= If(!Empty((cAliasA)->ABS_CCUSTO),(cAliasA)->ABS_CCUSTO,(cAliasA)->RA_CC)
		
			Else
				aAdicionais[nPos][4] += 	(cAliasA)->HORAS
				aAdd(aAdicionais[nPos][5],(cAliasA)->RECAB9 )
			EndIf
			
		EndIf 
	
		(cAliasA)->(DbSkip())
	End-While
	
	
	//Envia ultimas informações para RH.
	If Len(aAdicionais) > 0
			
		If !At353EnvRH(cFilFunOld, cMatFunOld, aAdicionais)//Envia para RH
			lErro := .T.
		EndIf
		
		//Reinicia Variaveis
		aAdicionais	:= {}
		cFilFunOld 	:= ""
		cMatFunOld 	:= ""
		
	EndIf

	(cAliasA)->(DbCloseArea())
   
	If lErro
		Aviso(STR0016, STR0010 + CRLF + STR0011 +TxLogPath(STR0007),  {STR0001}) // "Ocorreram erros " # "Foi gerado o log no arquivo " # ", deseja visualizar LOG?" # " Atenção"
	Else
		Aviso(STR0016/*STR0015*/, STR0016, {STR0001}) // "Finalização" # "Processo finalizado" # "OK"
	EndIf
Return()


/*/{Protheus.doc} At353EnvRH
Aplica regras de hierarquia de beneficios e realiza o envio dos adicionais para o RH. 
@since 26/06/2015
@version 1.0
@param cFilFun, String, Filial do Funcionário
@param cMatFun, String, Matricula do funcionário
@param aAdicionais, Array, Adicionais a serem enviados
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

Static Function at353EnvRH(cFilFun, cMatFun, aAdicionais)
		
	Local lRet := .T.	
	Local aAB9 := {}	
	Local lLogSuccess := (MV_PAR07 == 1) //Gera Log Total
	Local aCabec := {}
	Local aItens := {}	
	Local lGera := .T.
	Local cRoteiro := ""
	Local cPeriodo := ""
	Local cNumPagto := ""
	Local aPerAtual := {}
	Local aCodFol := {}
	Local cTxtLog := ""
	Local nPerInt := 0
	Local nPerProp := 0
	Local nInsIntMax := 0
	Local nInsIntMed := 0
	Local nInsIntMin := 0
	Local nInsPrpMax := 0
	Local nInsPrpMed := 0
	Local nInsPrpMin := 0
	Local nOpc      := Iif(MV_PAR06 == 1, 3, 5)//Inclusão ou estorno
	Local cErro := ""
	Local nI := 0
	Local nY := 0
	Local nX	:= 0
		
	Private lMsHelpAuto    := .F.
	Private lMsErroAuto    := .F.
	Private lAutoErrNoFile := .T.
	
	SRA->(DbSetOrder(1))
	
	If SRA->(DbSeek(cFilFun+cMatFun))
	
		cTxtLog 	:= STR0004+" "+SRA->RA_MAT +" / "+SRA->RA_NOME+CRLF  //"Funcionário"
		
		cRoteiro 	:= At353GtRot()
		aCodFol := At353GetPd(SRA->RA_FILIAL)//Carrega aCodFol da Filial
		
		If Len(aCodFol) == 0
			TxLogFile(STR0007,cTxtLog+ CRLF + STR0008 +CRLF)  // "Funcionário " # "Erro ao carregar o roteiro de calculo"
			lGera := .F.	
		EndIf
			
		If Empty(cRoteiro)//VErifica roteiro da Folha
			TxLogFile(STR0007,cTxtLog+ CRLF + STR0008 +CRLF)  // "Funcionário " # "Erro ao carregar o roteiro de calculo"
			lGera := .F.	
		EndIF
		
		//Verifica periodo
		If fGetPerAtual( @aPerAtual, NIL, SRA->RA_PROCES, cRoteiro )				
			cPeriodo 	:= aPerAtual[1,1]
			cNumPagto	:= aPerAtual[1,2]				
		Else
			TxLogFile(STR0007,cTxtLog+ CRLF + STR0018 +CRLF)  // "Funcionário " # "Erro ao carregar o periodo atual"
			lGera := .F.	
		EndIf
	
		// pagamento de periculosidade configurada pelo cadastro de funcionários
		If  SRA->RA_ADCPERI <> '1'
			TxLogFile(STR0007,cTxtLog + CRLF + STR0005 +CRLF)  // "Funcionário" # "Pagamento de periculosidade configurada pelo cadastro de funcionários"
			lGera    := .F.				
		EndIf
			 
		// pagamento de insalubridade configurada pelo cadastro de funcionários
		If SRA->RA_ADCINS <> '1'
			TxLogFile(STR0007,cTxtLog + CRLF + STR0006 +CRLF) // "Funcionário" # "Pagamento de insalubridade configurada pelo cadastro de funcionários"
			lGera    := .F.			
		EndIf
		
		If lGera
			//Identifica configurações
			nPerInt	:= aScan(aAdicionais, {|x| x[ADICIONAIS_ADICIONAL] == PERICULOSIDADE .AND. x[ADICIONAIS_TIPO] == INTEGRAL })
			nPerProp 	:= aScan(aAdicionais, {|x| x[ADICIONAIS_ADICIONAL] == PERICULOSIDADE .AND. x[ADICIONAIS_TIPO] == PROPORCIONAL })
			
			nInsIntMax	:= aScan(aAdicionais, {|x| x[ADICIONAIS_ADICIONAL] == INSALUBRIDADE .AND. x[ADICIONAIS_TIPO] == INTEGRAL .AND. x[ADICIONAIS_GRAU] == MAXIMO })
			nInsIntMed	:= aScan(aAdicionais, {|x| x[ADICIONAIS_ADICIONAL] == INSALUBRIDADE .AND. x[ADICIONAIS_TIPO] == INTEGRAL .AND. x[ADICIONAIS_GRAU] == MEDIO })
			nInsIntMin	:= aScan(aAdicionais, {|x| x[ADICIONAIS_ADICIONAL] == INSALUBRIDADE .AND. x[ADICIONAIS_TIPO] == INTEGRAL .AND. x[ADICIONAIS_GRAU] == MINIMO })
			nInsPrpMax	:= aScan(aAdicionais, {|x| x[ADICIONAIS_ADICIONAL] == INSALUBRIDADE .AND. x[ADICIONAIS_TIPO] == PROPORCIONAL .AND. x[ADICIONAIS_GRAU] == MAXIMO })
			nInsPrpMed	:= aScan(aAdicionais, {|x| x[ADICIONAIS_ADICIONAL] == INSALUBRIDADE .AND. x[ADICIONAIS_TIPO] == PROPORCIONAL .AND. x[ADICIONAIS_GRAU] == MEDIO })
			nInsPrpMin	:= aScan(aAdicionais, {|x| x[ADICIONAIS_ADICIONAL] == INSALUBRIDADE .AND. x[ADICIONAIS_TIPO] == PROPORCIONAL .AND. x[ADICIONAIS_GRAU] == MINIMO })
		
			//PRIORIDADE DE ENVIO PERICULOSIDADE
			//1-Periculosidade Integral
			//2-Periculosidade Proporcional		
			
			//PRIORIDADE DE ENVIO INSALUBRIDADE
			//Insalubridade Integral Maxima
			//Insalubridade Integral Media
			//Insalubridade Integral Minima
			//Insalubridade Proporcinal conforme Grau
		
			If nPerInt > 0
				If At353ChkId(aCodFol, ID_PERICULOSIDADE)			
					aItens := At353AddIt(aItens, aCodFol[ID_PERICULOSIDADE,1], SRA->RA_HRSMES, cNumPagto, aAdicionais[nPerInt, ADICIONAIS_CC])
				Else
					TxLogFile(STR0007,cTxtLog + CRLF + STR0019 +CRLF) // "Funcionário" # "ID de Calculo de Periculosidade não configurado no módulo de Gestão de Pessoal"
					lRet := .F.
				EndIf
			ElseIf nPerProp > 0
				For nX := nPerProp to Len(aAdicionais)
				
					If aAdicionais[nX,1] == 2 .and. aAdicionais[nX,2] == "3"
				
						If At353ChkId(aCodFol, ID_PERICULOSIDADE)
							aItens := At353AddIt(aItens, aCodFol[ID_PERICULOSIDADE,1], aAdicionais[nX, ADICIONAIS_HORAS], cNumPagto, aAdicionais[nX,ADICIONAIS_CC])
						Else
							TxLogFile(STR0007,cTxtLog + CRLF + STR0019 +CRLF) // "Funcionário" # "ID de Calculo de Periculosidade não configurado no módulo de Gestão de Pessoal"
							lRet := .F.
						EndIf
						
					EndIf
			
				Next nX
				
			EndIf
		
			
			If nInsIntMax > 0 //Adiciona Insalubridade Integral Maxima
				If At353ChkId(aCodFol, ID_INSALUBRIDADE_MAXIMA)
					aItens := At353AddIt(aItens, aCodFol[ID_INSALUBRIDADE_MAXIMA,1], SRA->RA_HRSMES, cNumPagto, aAdicionais[nInsIntMax, ADICIONAIS_CC])
				Else
					TxLogFile(STR0007,cTxtLog + CRLF + STR0022 +CRLF) // "Funcionário" # "ID de Calculo de Insalubridade Máxima não configurado no módulo de Gestão de Pessoal"
					lRet := .F.
				EndIf
			
			ElseIf nInsIntMed > 0 //Adiciona Insalubridade Integral Media
				If At353ChkId(aCodFol, ID_INSALUBRIDADE_MEDIA)
					aItens := At353AddIt(aItens, aCodFol[ID_INSALUBRIDADE_MEDIA,1], SRA->RA_HRSMES, cNumPagto, aAdicionais[nInsIntMed, ADICIONAIS_CC])
				Else
					TxLogFile(STR0007,cTxtLog + CRLF + STR0021 +CRLF) // "Funcionário" # "ID de Calculo de Insalubridade Média não configurado no módulo de Gestão de Pessoal"
					lRet := .F.
				EndIf
			
			ElseIf nInsIntMin > 0 //Adiciona Insalubridade Integral Minima
				If At353ChkId(aCodFol, ID_INSALUBRIDADE_MINIMA)
					aItens := At353AddIt(aItens, aCodFol[ID_INSALUBRIDADE_MINIMA,1], SRA->RA_HRSMES, cNumPagto, aAdicionais[nInsIntMin, ADICIONAIS_CC])
				Else
					TxLogFile(STR0007,cTxtLog + CRLF + STR0020 +CRLF) // "Funcionário" # "ID de Calculo de Insalubridade Minima não configurado no módulo de Gestão de Pessoal"
					lRet := .F.
				EndIf	
			Else
			
				For nX := 1 to Len(aAdicionais)
				
					If aAdicionais[nX,1] == 1 .and. aAdicionais[nX,2] == "3" .and. aAdicionais[nX,3] == "4" 
				
					//If nInsPrpMax > 0	 //Adiciona Proporcional Maxima			
						If At353ChkId(aCodFol, ID_INSALUBRIDADE_MAXIMA)
							aItens := At353AddIt(aItens, aCodFol[ID_INSALUBRIDADE_MAXIMA,1], aAdicionais[nX, ADICIONAIS_HORAS], cNumPagto, aAdicionais[nX, ADICIONAIS_CC])
						Else
							TxLogFile(STR0007,cTxtLog + CRLF + STR0022 +CRLF) // "Funcionário" # "ID de Calculo de Insalubridade Máxima não configurado no módulo de Gestão de Pessoal"
							lRet := .F.
						EndIf
					EndIf

					If aAdicionais[nX,1] == 1 .and. aAdicionais[nX,2] == "3" .and. aAdicionais[nX,3] == "3" 
					
					//If nInsPrpMed > 0 //Adiciona Proporcional Media
						If At353ChkId(aCodFol, ID_INSALUBRIDADE_MEDIA)
							aItens := At353AddIt(aItens, aCodFol[ID_INSALUBRIDADE_MEDIA,1], aAdicionais[nX, ADICIONAIS_HORAS], cNumPagto, aAdicionais[nX, ADICIONAIS_CC])
						Else
							TxLogFile(STR0007,cTxtLog + CRLF + STR0021 +CRLF) // "Funcionário" # "ID de Calculo de Insalubridade Média não configurado no módulo de Gestão de Pessoal"
							lRet := .F.
						EndIf
					EndIf

					If aAdicionais[nX,1] == 1 .and. aAdicionais[nX,2] == "3" .and. aAdicionais[nX,3] == "2" 					
					//If nInsPrpMin > 0 //Adiciona Proporcional Minima
						If At353ChkId(aCodFol, ID_INSALUBRIDADE_MINIMA)
							aItens := At353AddIt(aItens, aCodFol[ID_INSALUBRIDADE_MINIMA,1], aAdicionais[nX, ADICIONAIS_HORAS], cNumPagto, aAdicionais[nX, ADICIONAIS_CC])
						Else
							TxLogFile(STR0007,cTxtLog + CRLF + STR0020 +CRLF) // "Funcionário" # "ID de Calculo de Insalubridade Minima não configurado no módulo de Gestão de Pessoal"
							lRet := .F.
						EndIf
					EndIf		
				
				Next nX
				
			EndIf
		
			If Len(aItens) > 0
				
				aadd(aCabec,{'RA_FILIAL' , SRA->RA_FILIAL, Nil })
				aadd(aCabec,{'RA_MAT'    , SRA->RA_MAT, Nil })
				aadd(aCabec,{'CPERIODO'  , cPeriodo            , Nil })
				aadd(aCabec,{'CROTEIRO'  , cRoteiro            , Nil })
				aadd(aCabec,{'CNUMPAGTO' , cNumPagto           , Nil })	
				
				If nOpc == 3
					RGB->(DbSetOrder(1))
					If RGB->(DbSeek(SRA->RA_FILIAL + SRA->RA_MAT))
						nOpc := 4
					Else
						nOpc := 3
					EndIf
				EndIf
  				
  				// nOpc: 3 - Inclusão, 4 - Alteração, 5 - Exclusão
				// O ultimo parametro com 2 foram as alterações feitas no execauto para atender a forma de envio das informações do GS
  				MsExecAuto( {|w,x,y,z| GPEA580(Nil,w,x,y,z)}, aCabec ,aItens, nOpc, 2)
				
				If lMsErroAuto
					cErro := ""
					aEval(GetAutoGRLog(),{|x| cErro +=  x + CRLF })							
					TxLogFile(STR0007, cTxtLog + cErro)   // "Adicionais"
					lRet := .F.
				Else
					For nI:=1 To Len(aAdicionais)
						For nY:=1 To Len(aAdicionais[nI][ADICIONAIS_AB9])
							AB9->(DbGoTo( aAdicionais[nI][ADICIONAIS_AB9][nY] ))
							If AB9->(!EOF())
								RecLock("AB9", .F.)
								AB9->AB9_ADIENV := iIf(MV_PAR06 == 1, .T., .F.)
								MsUnLock()
							EndIf															
						Next nY										
					Next nI

					If lLogSuccess
						If nOpc == 5
							TxLogFile(STR0007,cTxtLog + CRLF + STR0024 + CRLF)   //"Funcionário # "Estorno realizado com sucesso"								
						Else
							TxLogFile(STR0007,cTxtLog + CRLF + STR0009 + CRLF)   //"Funcionário # "Lançamento realizado com sucesso"
						EndIf
						
					EndIf
				EndIf
								
			EndIf
		EndIf
	EndIf
 
Return lGera .AND. lRet


/*/{Protheus.doc} At353AddIt
Realiza a inclusão de um novo item na estrutura de itens da RGB
@since 26/06/2015

@param aItens}, Array, array que será adicionado o item
@param cVerba, String, Código da verba
@param nHoras, Integer, Quantidade de horas
@param cNumPagto, String, Numero de pagamento

@return aItens, Array com o item incluído

/*/
Static Function At353AddIt(aItens, cVerba, nHoras, cNumPagto, cCCusto)

	Local aAux := {}
	
	aAdd(aAux,{"RGB_FILIAL" , xFilial("RGB")	, Nil })
	aAdd(aAux,{"RGB_MAT"    , SRA->RA_MAT    	, Nil })
	aAdd(aAux,{"RGB_PROCESS", SRA->RA_PROCES 	, Nil })
	aAdd(aAux,{"RGB_PD"     , cVerba         	, Nil })
	aAdd(aAux,{"RGB_TIPO1"  , "H"            	, Nil })
	aAdd(aAux,{"RGB_HORAS"  , nHoras			, Nil })
	aAdd(aAux,{"RGB_CC"     , cCCusto	     	, Nil })
	aAdd(aAux,{"RGB_CODFUN" , SRA->RA_CODFUNC	, Nil })
	aAdd(aAux,{"RGB_SEMANA" , cNumPagto		, Nil })
	Aadd(aAux,{"RGB_ROTORI"	, "IGS"			, Nil })
	Aadd(aAux,{"RGB_TIPO2"	, "G"				, Nil })	
	aadd(aItens, aAux)

Return aItens

Function At353GtRot()

Return fGetRotOrdinar()

/*/{Protheus.doc} At353GetPd

Realiza otimização do carregamento das verbas por filial

@since 25/06/2015
@version 1.0
@param aCods, Array, Cache para controle de verbas por ID de calculo
@return aCodFol, Array com identificadores de calculo da filial

/*/
Static Function At353GetPd( cFil)
	Local aRet := {}
	Local nPos := 0
	Local aCodFol := {}

	nPos := aScan(aCacheCFol, {|x| x[1] == cFil})
	If nPos == 0	
		Fp_CodFol(@aCodFol, cFil)
		
		aAdd(aCacheCFol, {cFil, aClone(aCodFol)}) 		
	Else
		aCodFol := aClone(aCacheCFol[nPos][2])
	EndIf
	
Return aCodFol

/*/{Protheus.doc} At353ChkId
Verifica se id é existende em aCodFol

@since 26/06/2015
@param aCodFol, Array, COdigos de identificadores de calculo
@param nId, Integer, id do identificador de calculo
@return Boolean
/*/
Static Function At353ChkId(aCodFol, nId)
	Local lRet := .T.
	
	lRet := !Empty(aCodFol[nId][1])
	
Return lRet