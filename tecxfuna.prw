#INCLUDE "TECXFUNA.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "FILEIO.CH"
#INCLUDE 'FWMVCDEF.CH'    
#INCLUDE "PONCALEN.CH"
           
#DEFINE T_ENTIDADE		1
#DEFINE T_INDICE		2
#DEFINE T_CHAVE			3
#DEFINE _TPIP_CABEC    	"0"
#DEFINE _TPIP_FUNCAO    "1"
#DEFINE _TPIP_TURNO    	"2"
#DEFINE _TPIP_ESCALA    "3"
#DEFINE _TPIP_MATIMPL   "4"
#DEFINE _TPIP_MATCONS   "5"


Static cRetProd := ""
Static _cTecRetF3 	:= ""


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TxEntPerm()

Retorna as entidades permitidas para agendamento no sigatec, tabela ABB

@return ExpC: Entidades permitidas para agendamento. Ex: AB6|AB7|AAT
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TxEntPerm() 
Return "AAT|AB6|AB7"

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TxEntABB()

@param cEntidade Parametro Opcional. Código da Entidade de Agendamento (X2_CHAVE). Quando informado retornara apenas os dados daquela entidade. 

Funcao utilizada para montar o array das entidades de agendamento do sigatec.
Retornara informacoes de indice e chava utilizada para todas as entidades que for permitido realizar agendamento via ABB

@return ExpA: Entidades de agendamento. Ex: aEntidad[1][T_ENTIDADE], aEntidad[1][T_INDICE], aEntidad[1][T_CHAVE]
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TxEntABB(cEntidade) 
	
Local nX		:= 1
Local aEntPerm	:= StrTokArr(TxEntPerm(),"|")
Local aArea		
Local aAreaSX2	
Local aAreaSIX
Local nPos
Local aRet

Default cEntidade	:= ""	

Static aEntidade	:= {} //Dados das Entidades

If Len(aEntidade) == 0
	aArea		:= GetArea()
	aAreaSX2	:= SX2->(GetArea())
	aAreaSIX	:= SIX->(GetArea())
	
	For nX := 1 To Len(aEntPerm)							
		SIX->(DbSeek(aEntPerm[nX]))
		AAdd(aEntidade,{aEntPerm[nX],1,SIX->CHAVE}) //Ordem conforme defines
	Next nX		
	
	RestArea(aAreaSX2)
	RestArea(aAreaSIX)
	RestArea(aArea)    
EndIf

If !Empty(cEntidade) .AND. Len(aEntidade) > 0
	If (nPos := aScan(aEntidade,{|x| x[1] == cEntidade})) > 0
		aRet := aEntidade[nPos]
	EndIf
Else
	aRet := aEntidade 
EndIf

Return aRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TxSeekEnt()

@param cEntidade Código da Entidade de Agendamento (X2_CHAVE)
@param cChave Chave da Tabela para posicionamento

Retorna Posiciona e retorna o registro da entidade de agendamento a partir da Entidade/Chave

@return ExpL:.T. para quando encontrar a chave na entidade, .F. para quando não encontrar

/*/
//--------------------------------------------------------------------------------------------------------------------
Function TxSeekEnt(cEntidade,cChave)
Local lRet		:= .F.
Local aArea		:= GetArea()
Local aEnt		:= TxEntABB(cEntidade)
	
If Len(aEnt) > 0
	DbSelectArea(aEnt[T_ENTIDADE])
	DbSetOrder(aEnt[T_INDICE])
	lRet := DbSeek(XFilial(cEntidade)+cChave)
EndIf
	 			
RestArea(aArea)

Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TXSelEnt()

Consulta Padrão especifica ABBENT do campo ABB_CHAVE - Aciona a Conpad Entidade + "ABB".
De acordo com a entidade escolhida na tabela ABB acionará a conpad adequada.
Exemplos:
Quando ABB_ENTIDA for preenchida com AAT, acionará a conpad AATABB. 
Quando ABB_ENTIDA for preenchida com AB6 acionará conpad AB6ABB.

@return ExpL: Retornara .T. quando a chave for válida.

/*/
//--------------------------------------------------------------------------------------------------------------------
Function TXSelEnt(cVar)
Local lRet		:= .T.
Local cMVar		:= ReadVar()
Local nPosEnt
Local aArea		:= GetArea()
Local cVal
Local cTabela

Default cVar 	:= ""

SaveInter()

If Empty(cVar)
	cVar := TxGetVar("ABB_ENTIDA")
EndIf

If !Empty(cVar)
	cF3 := cVar+"ABB" //Conpad sempre será Entidade+ABB. Ex. AATABB 
	
	DbSelectArea("SXB")
	SXB->(dbSetOrder(1))
	If SXB->(dbSeek(cF3+"1"))
		cTabela := Trim(SXB->XB_CONTEM)
	EndIf
	If SXB->(dbSeek(cF3+"5"))
		If Trim(SXB->XB_CONTEM) != ""
			cVal := Trim(SXB->XB_CONTEM)
		EndIf 			
		SXB->(DbSkip())
	EndIf
		
	lRet := Conpad1( NIL,NIL,NIL,cF3)
	If lRet 		
		&(cMVar) := PadR(&(cVal),TamSX3("ABB_CHAVE")[1])		
	EndIf		
Else
	Help(,,'HELP', 'TXSELENT', STR0042, 1, 0) //"É necessário Escolher uma Entidade de Agendamento para utilizar a consulta padrão."	 		
EndIf

RestInter()

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TxVldChave()

Valida a Chave da Entidade de Agendamento. Uso: X3_VALID do campo ABB_CHAVE

@return ExpL: Retornara .T. quando a chave for válida.

/*/
//--------------------------------------------------------------------------------------------------------------------
Function TxVldChave(cChv,cVar,cNumOs,cMsgHlp)

Local lRet		:= .F.
Local aEnt		:= {}
Local aChv		:= {} 
Local nX		:= 0
Local nPosEnt 	:= 0
Local aArea		:= GetArea()
Local aAreaEnt	:= {}
Local cChave	:= "" 

Default cVar	:= ""
Default cChv	:= ""
Default cNumOs  := ""
Default cMsgHlp := STR0001 //"Item de Agendamento Inválido. O Item agendado deve ser correspondente à entidade escolhida."

//Quando vazio procura no M-> ou Acols ou Dicionario
If Empty(cVar)
	cVar := TxGetVar("ABB_ENTIDA")
EndIf

//Retorna os dados da Entidade
aEnt := TxEntABB(Trim(cVar))

If Len(aEnt) > 0	.AND. ValType(aEnt) == "A" .AND. ValType(aEnt[1]) != "A"			
	aAreaEnt := &(aEnt[T_ENTIDADE]+"->(GetArea())")
	DbSelectArea(aEnt[T_ENTIDADE])
	DbSetOrder(aEnt[T_INDICE])
	
	If Empty(cChv) 
		If ReadVar() == "M->ABB_CHAVE" 		
			cChv := &(ReadVar())
		Else
			aChv := StrTokArr(aEnt[T_CHAVE],"+")			
			For nX := 2 To Len(aChv) //Todos menos filial				 
				cChv += &("ABB->"+aChv[nX])
			Next nX
		EndIf   		
	EndIf		
	
	lRet := DbSeek(XFilial(aEnt[T_ENTIDADE])+RTrim(cChv))	//Busca pela chave informada
	
	// Quando cNumOs informado Valida se a O.S. bate com a chave
	If Trim(cNumOs) != "" 
		lRet := (cNumOs == &(aEnt[T_ENTIDADE]+"->"+PrefixoCpo(aEnt[T_ENTIDADE])+"_NUMOS"))
	EndIf
	RestArea(aAreAEnt) 
EndIf

If !lRet .AND. !Empty(cVar)
	Help(,,'HELP', 'TXVLDCHV', cMsgHlp, 1, 0)	
ElseIf Empty(cVar)
	lRet := .T. 	
EndIf

RestArea(aArea)
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TxGatNOS()

Funcao acionada pelo gatilho de ABB_CHAVE para retornar o número da Ordem de Serviço em ABB_NUMOS.

@return ExpC: Retorna o número da O.S. AB6_NUMOS para ABB_NUMOS 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TxGatNumOS()
Local cEnt
Local cRet := Space(TamSX3("ABB_NUMOS")[1])

cVar := TxGetVar("ABB_CHAVE")
cEnt := TxGetVar("ABB_ENTIDA")

If !Empty(cVar) .AND. cEnt $ "AB6|AB7" //Numero De O.S apenas para AB6 e AB7
	If TxSeekEnt(cEnt,cVar)
		If cEnt == "AB6"
			cRet := AB6->AB6_NUMOS
		Else
			cRet := AB7->AB7_NUMOS
		EndIf	
	EndIf			
EndIf

Return cRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TxGetVar()

Retorna Varivel da ABB conforme escopo. Procura no model, em M->, Acols ou Tabela

@param cVar:Campo da abb. Ex: "ABB_ENTIDA" procura no model, em M->, Acols ou Tabela 

@return ExpX: Retorna o Conteudo da Variavel da ABB com o Tipo da Variavel 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TxGetVar(cVar)
Local xRetVar
Local oModel	:= FwModelActive()
Local nPosChv	:= 0

If ValType(oModel) == "O"
	xRetVar := FwFldGet(cVar) 
ElseIf Type("M->"+cVar) != "U"
	xRetVar := &("M->"+cVar)	
ElseIf Type("aHeader") != "U" .AND. (nPosChv := aScan(aHeader,{|x| AllTrim(x[2])==cVar})) > 0
	If (nPosChv := aScan(aHeader,{|x| AllTrim(x[2])==cVar})) > 0		
		xRetVar := &("aCols[N]["+cValToChar(nPosChv)+"]")
	EndIf
ElseIf Select("ABB") .AND. !Empty(&("ABB->"+cVar))
	xRetVar := &("ABB->"+cVar)
EndIf

Return xRetVar

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TxExistAloc()

Verifica se ja existe alocação na ABB para o Tecnico no Periodo Informado

@param ExpC:Codigo do Tecnico (ABB_CODTEC)
@param ExpD:Data Inicial (ABB_DTINI)
@param ExpC:Hora Inicial (ABB_HRINI)
@param ExpD:Data Final (ABB_DTFIM)
@param ExpC:Hora Final (ABB_HRFIM)
@param ExpN:Recno da ABB a ser Ignorado (Caso seja uma alteração, informe o recno para ignorar o proprio na consulta) 
@param ExpC:Local de atendimento para busca
@param ExpÇ:Indica se irá considerar somente agendas ativas
@param ExpC:Local de destino da alocacao (OPCIONAL) para validar se for lugar efetivo e atual alocacao for RESERVA TECNICA
@return ExpL: Retorna .T. quando há alocação 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TxExistAloc(cCodTec,dDtIni,cHrIni,dDtFim,cHrFim,nRecno,cLocal, lAtiva,cLocDestino)
Local aOldArea	:= GetArea()
Local nX
Local cAlias		:= GetNextAlias()
Local lRet			:= .F.
Local aSM0 		:= FWArrFilAtu()
Local aFilPesq	:= {}
Local cFilPesq	:= "" 
Local cExpConc	:= If(Trim(Upper(TcGetDb())) $ "ORACLE,POSTGRES,DB2,INFORMIX","%ABB.ABB_DTINI||ABB.ABB_HRINI%","%ABB.ABB_DTINI+ABB.ABB_HRINI%") //Sinal de concatenação (Igual ao ADMXFUN)
Local cExpConcF	:= If(Trim(Upper(TcGetDb())) $ "ORACLE,POSTGRES,DB2,INFORMIX","%ABB.ABB_DTFIM||ABB.ABB_HRFIM%","%ABB.ABB_DTFIM+ABB.ABB_HRFIM%") //Sinal de concatenação (Igual ao ADMXFUN)
Local cCompE		:= FWModeAccess("ABB",1)
Local cCompU		:= FWModeAccess("ABB",2)
Local cCompF		:= FWModeAccess("ABB",3)
Local cAgenAtiv 	:= '1'
Local cWhere		:= ""
Local cWhereABS	:= ""
Local cFiltroAge	:= ""
Local lExecQry		:= .T.

Default nRecno := 0
Default cLocal := ""
Default lAtiva := .T.
Default cLocDestino := ""

If !Empty (cLocal)
	cWhere := " AND ABB_LOCAL = '" + cLocal + "' "
Endif	

If !Empty(cLocDestino)
	dbSelectArea("ABS")
	ABS->(dbSetOrder(1))
	If ABS->(dbSeek(xFilial("ABS")+cLocDestino ))
		
		//Caso local de destino seja EFETIVO, e local da agenda seja RESERVA, nao considera como indisponivel
		If ABS->ABS_RESTEC <> "1"
			cWhereABS += " AND ABS.ABS_RESTEC <> '1' "
		Endif

		//Caso o local de destino seja reciclagem ou curso não verifica se existe agenda permitindo a geração de uma nova agenda para recebimento do atendente.
		If ABS->ABS_RECICL == "1" .Or. ABS->ABS_CURSO == "1" .Or. ABS->ABS_ADISPO == "1"
			lExecQry := .F.
		Endif
	EndIf
EndIf

If lExecQry

	cWhereABS	:= "%"+ cWhereABS + "%"
	cWhere := "%"+ cWhere+"%"
	
	If lAtiva
		cFiltroAge := "%AND ABB.ABB_ATIVO = '"+cAgenAtiv+"'%"
	Else
		cFiltroAge := "%%"
	EndIf

	If cCompE == 'C' .AND. cCompU == 'C' .AND. cCompF == 'C'
		cFilPesq := XFilial("ABB")
	ElseIf cCompU == 'E'
		aFilPesq := FWAllFilial(aSM0[SM0_EMPRESA],aSM0[SM0_UNIDNEG])
	ElseIf cCompE == 'E'
		aFilPesq := FWAllUnitBusiness(aSM0[SM0_EMPRESA])
	EndIf	
	
	For nX := 1 To Len(aFilPesq)
		If nX > 1
			cFilPesq+="','"
		EndIf
		If cCompF == 'E'
			cFilPesq += aSM0[SM0_EMPRESA]+aSM0[SM0_UNIDNEG]+aFilPesq[nX]
		ElseIf cCompU == 'E'
			cFilPesq += aSM0[SM0_EMPRESA]+aSM0[SM0_UNIDNEG]+Space(Len(aFilPesq[nX]))
		ElseIf cCompE == 'E'
			cFilPesq += aSM0[SM0_EMPRESA]+Space(Len(aSM0[SM0_UNIDNEG]))+Space(Len(aSM0[SM0_FILIAL]))
		EndIf
	Next nX 
	
	BeginSQL alias cAlias							
	select COUNT(*) CT
	  from %table:ABB% ABB
	       left join %table:ABS% ABS ON ABS.%NotDel%
	                                AND ABS.ABS_FILIAL = %xFilial:ABS%
	                                AND ABS.ABS_LOCAL = ABB.ABB_LOCAL
	                                    %Exp:cWhereABS%
	 where ABB.%NotDel%
			%Exp:cFiltroAge%
			   AND ABB.ABB_CODTEC = %exp:cCodTec%
			   AND ABB.R_E_C_N_O_ != %exp:nRecno%
			   AND ABB.ABB_FILIAL IN (%exp:cFilPesq%)
			   AND (
				(%exp:dDtIni% > ABB.ABB_DTINI AND %exp:dDtIni% < ABB.ABB_DTFIM)
				OR
				(%exp:dDtFim% > ABB.ABB_DTINI AND %exp:dDtFim% < ABB.ABB_DTFIM)
				OR
				(ABB.ABB_DTINI > %exp:dDtIni% AND ABB.ABB_DTINI < %exp:dDtFim%)
				OR
				(ABB.ABB_DTFIM > %exp:dDtIni% AND ABB.ABB_DTFIM < %exp:dDtFim%)
				OR 
				(%exp:DTOS(dDtIni)+cHrIni% BETWEEN %exp:cExpConc% AND %exp:cExpConcF% )
				OR 
				(%exp:DTOS(dDtFim)+cHrFim% BETWEEN %exp:cExpConc% AND %exp:cExpConcF% )
				OR 			
				(%exp:cExpConc% BETWEEN %exp:DTOS(dDtIni)+cHrIni% AND %exp:DTOS(dDtFim)+cHrFim%)
				OR
				(%exp:cExpConc% BETWEEN %exp:DTOS(dDtIni)+cHrIni% AND %exp:DTOS(dDtFim)+cHrFim%)
			)		
			%Exp:cWhere%
			
	EndSQL		
	
	DbSelectArea(cAlias)
	If (cAlias)->(!Eof()) .AND. (cAlias)->CT > 0
		lRet := .T.
	EndIf
	(cAlias)->(DbCloseArea())
Endif	

RestArea(aOldArea)
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TxPrefix()

A partir do campo retorna o prefixo da tabela, Ex. para A1_COD retorna SA1. Para ABB_CODTEC retorna ABB

@param ExpC:Campo. Ex. ABB_CODTEC 

@return ExpC: Retorna a Tabela a qual o campo pertence 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TxPrefix(cCampo)
Local aParte := StrTokArr(cCampo,"_")
Local cRet	:= ""
If Len(aParte) == 2
	cRet := aParte[1]
	If Len(cRet) == 2
		cRet := "S"+cRet
	EndIf
EndIf
Return cRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} ListarApoio
Função para criar tabela temporária com registros de recursos do 
Banco de Apoio para uso em rotinas do SIGATEC.

@sample 	ListarApoio( 	 dIniAloc, dFimAloc, aCargos, aFuncoes, aHabil, cDisponib,;
						 cContIni, cContFim, cCCusto, cLista, nLegenda, cItemOS,;
						 aTurnos, aRegiao, lEstrut, aPeriodos, cIdCfAbq, cLocOrc, aSeqTrn, aPeriodRes,cLocAloc  )

@param		dIniAloc	Data inicial do período de alocação.
			dFimAloc	Data final do período de alocação.
			cCargo		Cargo do recurso
			cFuncao	Função que será exercida.
			aCarac		Array com dados da Caracteristicas do local de atendimento
			aCursos		Array com dados do Cursos do local de atendimento
			aHabil		Array com dados da habilidade que deve ser filtrada.
						Integrado ao RH ([1]Habilidade - [2]Item da Escala
						Não integrado ao RH ([1]Habilidade - [2]Nível)
			cDisponib	Indica se deve filtrar apenas os recursos Disponíveis(D),
						apenas os Indisponíveis(I), Alocados(A) ou Todos(T)
			cContIni	Indica o contrato inicial para filtrar os recursos do mesmo 
						Centro de Custo.
			cContFim	Indica o contrato final para filtrar os recursos do mesmo 
						Centro de Custo.
			cCCusto	Indica um centro de custo para filtrar os recursos.
			cLista		Indica quais atendentes deverão ser listados.
						(1)Lista apenas Banco de Apoio (Atendentes não relacionados a um contrato)
						(2)Lista apenas Reserva Técnica (Atendentes relacionados ao contrato informado)
						(3)Lista Banco de Apoio e Reserva Técnica
						(4)Lista todos os atendentes do Banco de Apoio e Reserva técnica (Inclusive de outros contratos) 
			nLegenda	Indica como será montada a legenda.
						(1) Legenda de alocação
						(2) Legenda de recursos alocados
			cItemOS	Item da OS para filtrar os atendentes alocados
			cTurno		Turno do atendente
			lEstrut	Indica se deve retornar apenas a estrutura
						(F) Consulta completa
						(T) Apenas a estrutura 
			
			cIdCfAbq	Indica o relacionamento com a tabela ABQ
			cLocOrc	Local onde serão listados os atendentes
			aSeqTrn	Array com dados da Sequencia do turno a serem filtradas
			aPeriodRes Periodo a ser considerado quando consulta for por reserva Tecnica
			cLocalAloc Codigo do local de DESTINO caso seja informado, para consistir se existe uma efetivacao em periodo no qual o recurso estava alocado como RESERVA TECNICA  
			
@return	aRet 		Array de 3 posições
			aRet[1]	Tabela temporária com Banco de Apoio
			aRet[2]	Índice da tabela temporária
			aRet[3]	Estrutura das colunas para uso com FwFormBrowse

@author	Danilo Dias
@since		30/05/2012
@version	P12
/*/
//------------------------------------------------------------------------------
Function ListarApoio( dIniAloc, dFimAloc, aCargos, aFuncoes, aHabil, cDisponib,;
						 cContIni, cContFim, cCCusto, cLista, nLegenda, cItemOS,;
						 aTurnos, aRegiao, lEstrut, aPeriodos, cIdCfAbq, cLocOrc,;
						 aSeqTrn, aPeriodRes, cLocalAloc, aCarac, aCursos, cFilTec )

Local lRH 				:= SuperGetMv("MV_TECXRH",,.F.)
Local cAlias			:= GetNextAlias()
Local cTempTab		:= ''	   								//Tabela temporária criada
Local cTempIdx		:= ''	   								//indice da tabela temporária
Local cTempKey		:= ''									//Chave para o índice da tabela temporária
Local aCampos			:= {}									//Campos retornados na consulta
Local aColumns		:= {}									//Estrutura dos campos retornada de acordo com os campos em aCampos
Local aStructure		:= {}									//Estrutura da tabela para criação do arquivo temporário
Local nI				:= 1									//Contador de uso geral
Local cSim				:= STR0036								//Indica o sim de acordo com o idioma corrente
Local cNao				:= STR0037								//Indica o não de acordo com o idioma corrente
Local cWhereDisp		:= ''									//Condição de filtro para os atendentes disponíveis
Local cWhereIndisp	:= ''									//Condição de filtro para os atendentes indisponíveis
Local cWhereABB		:= ''									//Condição para filtrar apenas agendamentos para um determinado Item da OS
Local cWhereHabRH		:= '' 									//Condição de where da consulta para filtrar atendentes por Habilidade com integração RH
Local cWhereHab		:= '' 									//Condição de where da consulta para filtrar atendentes por Habilidade sem integração RH
Local cWhereReg		:= ''									//Condição de where da consulta para filtrar atendentes por Região de Atendimento
Local cFiltroCC		:= '' 									//Condição de where da consulta para filtrar atendentes por Centro de Custo
Local nHabil			:= 0									//Indica qual a habilidade será usada, do RH ou do FieldService
Local cCCVazio		:= Space( TamSX3('AA1_CC')[1] )		//Cria campo de Centro de Custo vazio
Local aHabAtd 		:= {}									//Retorna as habilidades do atendente
Local aRegAtd			:= {}									//Retorna as regioes de atendimento do atendimento.
Local aRet				:= {}									//Array de retorno.
Local cTableAlias		:= ''
Local cAliasRBG		:= ''
Local cAliasRBLX		:= ''
Local cAliasRBI		:= '' 
Local cJoinHabil		:= ''
Local dDtIni			:= nil
Local dDtFim			:= nil
Local cHrIni			:= nil
Local cHrFim			:= nil
Local nX				:= 0
Local aEquipe 		:= {}
Local aAcesso			:= {}
Local cAtend			:= ''
Local nPerc				:= 1   
Local cReserva		:= "1"
Local cApoio			:= "2"
Local lDispRH			:= .T. //Controle de disponibilidade no RH 
Local cCarac			:= ''
Local cJoinCarac		:= '' // Caracteristica do atendente
Local cCursos			:= ''
Local cJoinCursos		:= '' // Cursos do funcionário
Local aCarAtd 		:= {} //Retorna as Características do atendente
Local aCurAtd 		:= {} //Retorna os cursos do funcionario
Local nPosTW2        := 0
Local aTW2Restri   := {}
Local oTempTab		:= Nil
//--------------------------------------------------------------------------
// Inicialização de valores padrão para os parâmetros da função
//-------------------------------------------------------------------------
Default dIniAloc 		:= ''												//Por padrão filtra recursos agendados apenas para a data atual.
Default dFimAloc		:= ''												//Por padrão filtra recursos agendados apenas para a data atual.
Default cDisponib		:= 'T'												//Por padrão lista todos os recursos (Disponíveis e Indisponíveis).
Default cContIni		:= Space( TamSX3('AAH_CONTRT')[1] )			//Por padrão filtra recursos de todos os contratos
Default cContFim		:= Replicate( '9', TamSX3('AAH_CONTRT')[1] )	//Por padrão filtra recursos de todos os contratos
Default aHabil		:= {}												//Por padrão não filtra habilidades.
Default cCCusto		:= cCCVazio										//Por padrão não filtra Centro de Custo.
Default cLista			:= '3'												//Por padrão lista todos os atendentes (Banco de Apoio e Reserva de qualquer contrato)
Default nLegenda		:= 1												//Por padrão monta legenda de alocação.
Default cItemOS		:= ''												//Por padrão não filtra por item da OS
Default aRegiao		:= {}												//Por padrão não filtra por regiao
Default lEstrut		:= .F.												//Indica como a tabela será retornada
Default aPeriodos		:= {}
Default aCargos		:= {}
Default aFuncoes		:= {}
Default aTurnos		:= {}
Default aSeqTrn		:= {}												//Filtro por sequencia do turno
Default cIdCfAbq 		:= ''
Default cLocOrc 		:= ''
Default aPeriodRes	:= {}
Default cLocalAloc  := ''												//Periodo para reserva Tecnica
Default aCarac		:= {}
Default aCursos		:= {}
Default cFilTec     := ""

IIf( lRH, nHabil := 1, nHabil := 2 )

//-----------------------------------------------------------------------------------------
// Estrutura de campos da tabela temporária
//-----------------------------------------------------------------------------------------

//Campos retornados
AAdd( aCampos, { 'TMP_LEGEN'	, ''	} )
AAdd( aCampos, { 'TMP_FILIAL'	, TxDadosCpo( 'AA1_FILIAL' )[1]	} )
AAdd( aCampos, { 'TMP_CODTEC'	, TxDadosCpo( 'AA1_CODTEC' )[1]	} )
AAdd( aCampos, { 'TMP_NOMTEC'	, TxDadosCpo( 'AA1_NOMTEC' )[1]	} )
AAdd( aCampos, { 'TMP_CDFUNC'	, TxDadosCpo( 'AA1_CDFUNC' )[1]	} )
AAdd( aCampos, { 'TMP_TURNO'	, TxDadosCpo( 'AA1_TURNO'  )[1]	} )
AAdd( aCampos, { 'TMP_FUNCAO'	, TxDadosCpo( 'AA1_FUNCAO' )[1]	} )
AAdd( aCampos, { 'TMP_CARGO'	, TxDadosCpo( 'RA_CARGO'   )[1]	} )
AAdd( aCampos, { 'TMP_DISP'		, STR0038 	} )						//'Disponível?'
AAdd( aCampos, { 'TMP_DISPRH'		, STR0043 	} )	   					//'Disponivel RH?'
AAdd( aCampos, { 'TMP_ALOC'		, STR0039 	} )	   					//'Alocado?'
AAdd( aCampos, { 'TMP_SITFOL'	, TxDadosCpo( 'RA_SITFOLH' )[1]	} )
AAdd( aCampos, { 'TMP_DESC'		, STR0040 } )						//'Descrição'
AAdd( aCampos, { 'TMP_RESTEC'	, TxDadosCpo( 'TCU_RESTEC'  )[1] } ) // Reserva Tecnica
AAdd( aCampos, { 'TMP_OK'		, STR0041 } ) 						// "OK"  


//Estrutura para criação do arquivo temporário
AAdd( aStructure, { aCampos[1][1]	, 'C', 15, 0 } )
AAdd( aStructure, { aCampos[2][1]	, 'C', TamSX3('AA1_FILIAL')[1], TamSX3('AA1_FILIAL')[2] } )
AAdd( aStructure, { aCampos[3][1]	, 'C', TamSX3('AA1_CODTEC')[1], TamSX3('AA1_CODTEC')[2] } )
AAdd( aStructure, { aCampos[4][1]	, 'C', TamSX3('AA1_NOMTEC')[1], TamSX3('AA1_NOMTEC')[2] } )
AAdd( aStructure, { aCampos[5][1]	, 'C', TamSX3('AA1_CDFUNC')[1], TamSX3('AA1_CDFUNC')[2] } )
AAdd( aStructure, { aCampos[6][1]	, 'C', TamSX3('AA1_TURNO')[1], TamSX3('AA1_TURNO')[2] } )
AAdd( aStructure, { aCampos[7][1]	, 'C', TamSX3('AA1_FUNCAO')[1], TamSX3('AA1_FUNCAO')[2] } )
AAdd( aStructure, { aCampos[8][1]	, 'C', TamSX3('RA_CARGO')[1], TamSX3('RA_CARGO')[2] } )
AAdd( aStructure, { aCampos[9][1]	, 'C', 3, 0 } )
AAdd( aStructure, { aCampos[10][1]	, 'C', 3, 0 } )
AAdd( aStructure, { aCampos[11][1]	, 'C', 3, 0 } )
AAdd( aStructure, { aCampos[12][1]	, 'C', TamSX3('RA_SITFOLH')[1], TamSX3('RA_SITFOLH')[2] } )
AAdd( aStructure, { aCampos[13][1]	, 'C', 55, 0 } )
AAdd( aStructure, { aCampos[14][1]	, 'C', TamSX3('TCU_RESTEC')[1], TamSX3('TCU_RESTEC')[2] } )
AAdd( aStructure, { aCampos[15][1]	, 'C', 2, 0 } )

//-----------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------
// Monta filtros dinâmicos da consulta
//-----------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------

//------------------------------------------------------------------
// Filtra atendentes disponíveis pela agenda e RH
//------------------------------------------------------------------
cWhereDisp := "ABB_CODTEC IS NULL "		//Filtra apenas atendentes sem agenda

//------------------------------------------------------------------	
// Filtra atendentes indisponíveis no RH
//------------------------------------------------------------------
If ( Upper(cDisponib) == 'A' )
	cWhereIndisp := "ABB.ALOCADO = '" + cSim + "' "
Else
	cWhereIndisp := "(  ABB.ALOCADO = '" + cSim + "' ) "		//Filtra as situações de folha Afastado, Férias e Transferido
EndIf

//------------------------------------------------------------------
// Caso seja chamada pelo movimentar (TECA336), filtra somente os atendentes da filial informada em tela.
//------------------------------------------------------------------
If !Empty(cFilTec)
	cChvAA1 := "%AND AA1_FILIAL = '"+cFilTec+"'%"
Else
	cChvAA1 := "%%"
EndIf

//-----------------------------------------------------------------------------------------
// Filtro por Centro de Custo, de acordo com o parâmetro cLista
//-----------------------------------------------------------------------------------------
If ( !Empty(cCCusto) )
	cWhereDisp += "AND AA1_CC = '" + cCCusto + "' "
	cWhereIndisp += "AND AA1_CC = '" + cCCusto + "' "
EndIf         

// Carrega os filtros de equipe 
aAcesso := At670FilArr( __cUserId, "AAX", "001", .T. )

//Filtra apenas Banco de Apoio ( Atendentes não ligados a um contrato )
If ( cLista == '1' )     
    
    If checkSIX("AAX", 2)
		DbSelectArea("AAX")
		AAX->(DbSetOrder(2)) //AAX_FILIAL+AAX_TPGRUP
		AAX->(DbSeek(xFilial("AAX")+cApoio))
	
		While AAX->(!Eof()) .AND. AAX->(AAX_FILIAL+AAX_TPGRUP) == xFilial("AAX")+cApoio
			If Len(aAcesso[2]) > 0 .And. ; // verifica se o filtro consta a equipe
			   aScan(aAcesso[2], { |x| Alltrim(x[7]) == AllTrim(AAX->(AAX_FILIAL+AAX_CODEQU)) } ) == 0
				AAX->(DbSkip())
				Loop	
			EndIf
		   	aAdd(aEquipe,AAX->AAX_CODEQU)
			AAX->(DbSkip())   
		End
	      
		For nX:= 1 To Len(aEquipe) 
			DbSelectArea("AAY")   
			AAY->(DbSetOrder(1)) //AAY_FILIAL+AAY_CODEQU
			DbSeek(xFilial("AAY")+aEquipe[nX])
			While AAY->(!Eof()) .AND. xFilial("AAY") == AAY->AAY_FILIAL .AND. aEquipe[nX] == AAY->AAY_CODEQU
				If nPerc == 1
			   		cAtend += "'"+AAY->AAY_CODTEC+"'"
			   	Else
			   		cAtend += ",'"+AAY->AAY_CODTEC+"'" 
			   	EndIf	
			   	nPerc++
			AAY->(DbSkip())   
			End
			AAY->(DbCloseArea())   
		Next          
		
		If !Empty(cAtend)
			cWhereDisp += "AND AA1_CODTEC IN (" + cAtend + ") "
			cWhereIndisp += "AND AA1_CODTEC IN (" + cAtend + ") " 
		Else
			cWhereDisp += "AND AA1_CODTEC = '      ' "
			cWhereIndisp += "AND AA1_CODTEC = '      ' " 
		EndIf	
	EndIf	
	
//Filtra apenas Reserva Técnica ( Atendentes ligados ao contrato )
ElseIf ( cLista == '2' )	

	If checkSIX("AAX", 2) 
		DbSelectArea("AAX")
		AAX->(DbSetOrder(2)) //AAX_FILIAL+AAX_TPGRUP
		AAX->(DbSeek(xFilial("AAX")+cReserva))
		
		While AAX->(!Eof()) .AND. AAX->(AAX_FILIAL+AAX_TPGRUP) == xFilial("AAX")+cReserva
			If Len(aAcesso[2]) > 0 .And. ; // verifica se o filtro consta a equipe
			   aScan(aAcesso[2], { |x| Alltrim(x[7]) == AllTrim(AAX->(AAX_FILIAL+AAX_CODEQU)) } ) == 0
				AAX->(DbSkip())
				Loop	
			EndIf
		   	aAdd(aEquipe,AAX->AAX_CODEQU)
			AAX->(DbSkip())   
		End
	      
		For nX:= 1 To Len(aEquipe) 
			DbSelectArea("AAY")   
			AAY->(DbSetOrder(1)) //AAY_FILIAL+AAY_CODEQU
			AAY->(DbSeek(xFilial("AAY")+aEquipe[nX]))
			While AAY->(!Eof()) .AND. xFilial("AAY") == AAY->AAY_FILIAL .AND. aEquipe[nX] == AAY->AAY_CODEQU
				If nPerc == 1
			   		cAtend += "'"+AAY->AAY_CODTEC+"'"
			   	Else
			   		cAtend += ",'"+AAY->AAY_CODTEC+"'" 
			   	EndIf	
			   	nPerc++
			AAY->(DbSkip())   
			End
			AAY->(DbCloseArea())   
		Next          
		
		If !Empty(cAtend)
			cWhereDisp += "AND AA1_CODTEC IN (" + cAtend + ") "
			cWhereIndisp += "AND AA1_CODTEC IN (" + cAtend + ") "
		Else
			cWhereDisp += "AND AA1_CODTEC = '      ' "
			cWhereIndisp += "AND AA1_CODTEC = '      ' " 
		EndIf	 
	EndIf	
	
ElseIf Len(aAcesso[2]) > 0 	//verificar se o filtro existe de equipes

    If checkSIX("AAX", 2)
		DbSelectArea("AAX")
		AAX->(DbSetOrder(1)) //AAX_FILIAL+AAX_CODEQU
			
		While AAX->(!Eof()) .AND. AAX->AAX_FILIAL == xFilial("AAX")
			If aScan(aAcesso[2], { |x| Alltrim(x[7]) == AllTrim(AAX->(AAX_FILIAL+AAX_CODEQU)) } ) == 0
				AAX->(DbSkip())
				Loop	
			EndIf
		   	aAdd(aEquipe,AAX->AAX_CODEQU)
			AAX->(DbSkip())   
		End
	      
		For nX:= 1 To Len(aEquipe) 
			DbSelectArea("AAY")   
			AAY->(DbSetOrder(1)) //AAY_FILIAL+AAY_CODEQU
			DbSeek(xFilial("AAY")+aEquipe[nX])
			While AAY->(!Eof()) .AND. xFilial("AAY") == AAY->AAY_FILIAL .AND. aEquipe[nX] == AAY->AAY_CODEQU
				If nPerc == 1
			   		cAtend += "'"+AAY->AAY_CODTEC+"'"
			   	Else
			   		cAtend += ",'"+AAY->AAY_CODTEC+"'" 
			   	EndIf	
			   	nPerc++
			AAY->(DbSkip())   
			End
			AAY->(DbCloseArea())   
		Next          
		
		If !Empty(cAtend)
			cWhereDisp += "AND AA1_CODTEC IN (" + cAtend + ") "
			cWhereIndisp += "AND AA1_CODTEC IN (" + cAtend + ") " 
		Else
			cWhereDisp += "AND AA1_CODTEC = '      ' "
			cWhereIndisp += "AND AA1_CODTEC = '      ' " 
		EndIf	
	EndIf
		
EndIf

//Se for igual a 3 ou estiver em branco, 
//lista todos os atendentes independente do centro de custo

//------------------------------------------------------------------
// Filtra por função
//------------------------------------------------------------------
If ( Len( aFuncoes ) > 0 )
	
	If ( !lRH )
		cWhereDisp 	+= " AND AA1_FUNCAO IN ("
		cWhereIndisp 	+= " AND AA1_FUNCAO IN ("
	Else
		cWhereDisp 	+= " AND RA_CODFUNC IN ("
		cWhereIndisp 	+= " AND RA_CODFUNC IN ("
	EndIf
	
	For nI := 1 To Len( aFuncoes )
	
		cWhereDisp 	+= " '" + aFuncoes[nI] + "'"
		cWhereIndisp 	+= " '" + aFuncoes[nI] + "'"
		
		If ( nI < Len( aFuncoes ) )
			cWhereDisp 	+= ","
			cWhereIndisp 	+= ","
		EndIf
		
	Next nI
	
	cWhereDisp 	+= " )"
	cWhereIndisp 	+= " )"
	
EndIf

//------------------------------------------------------------------
// Filtra por cargo, apenas se integrado ao RH
//------------------------------------------------------------------
If ( lRH ) .And. ( Len( aCargos ) > 0 )
	
	cWhereDisp 	+= " AND RA_CARGO IN ("
	cWhereIndisp 	+= " AND RA_CARGO IN ("

	For nI := 1 To Len( aCargos )
	
		cWhereDisp 	+= " '" + aCargos[nI] + "'"
		cWhereIndisp 	+= " '" + aCargos[nI] + "'"
		
		If ( nI < Len( aCargos ) )
			cWhereDisp 	+= ","
			cWhereIndisp 	+= ","
		EndIf
		
	Next nI
	
	cWhereDisp 	+= " )"
	cWhereIndisp 	+= " )"
	
EndIf

//------------------------------------------------------------------
// Filtra por turno
//------------------------------------------------------------------
If ( Len( aTurnos ) > 0 )

	If ( !lRH )
		cWhereDisp 	+= " AND AA1_TURNO IN ("
		cWhereIndisp 	+= " AND AA1_TURNO IN ("
	Else
		cWhereDisp 	+= " AND RA_TNOTRAB IN ("
		cWhereIndisp 	+= " AND RA_TNOTRAB IN ("
	EndIf
	
	For nI := 1 To Len( aTurnos )
	
		cWhereDisp 	+= " '" + aTurnos[nI] + "'"
		cWhereIndisp 	+= " '" + aTurnos[nI] + "'"
		
		If ( nI < Len( aTurnos ) )
			cWhereDisp 	+= ","
			cWhereIndisp 	+= ","
		EndIf
		
	Next nI
	
	cWhereDisp 	+= " )"
	cWhereIndisp 	+= " )"
	
EndIf

//------------------------------------------------------------------
// Filtro por Sequencia do Turno
//------------------------------------------------------------------
If ( Len( aSeqTrn ) > 0 )

	If ( !lRH )
		cWhereDisp 	+= " AND AA1_SEQTUR IN ("
		cWhereIndisp 	+= " AND AA1_SEQTUR IN ("
	Else
		cWhereDisp 	+= " AND RA_SEQTURN IN ("
		cWhereIndisp 	+= " AND RA_SEQTURN IN ("
	EndIf
	
		For nI := 1 To Len( aSeqTrn )
		
			cWhereDisp 	+= " '" + aSeqTrn[nI] + "'"
			cWhereIndisp 	+= " '" + aSeqTrn[nI] + "'"
	
			If ( nI < Len( aSeqTrn ) )
				cWhereDisp 	+= ","
				cWhereIndisp 	+= ","
			EndIf
			
		Next nI	
	cWhereDisp 	+= " )"
	cWhereIndisp 	+= " )"
EndIf
//------------------------------------------------------------------
// Filtro por Habilidade
//------------------------------------------------------------------
//Verifica se foi informada alguma habilidade no filtro		
If ( Len(aHabil) > 0 )

	cJoinHabil := ''
	
	For nI := 1 To Len( aHabil )
	
		//Verifica se está integrado com RH
		//Se sim busca Habilidades na tabela RBI
		//Se não busca na AA2
		If ( lRH )	
			
			//Realiza relacionamento para encontrar o valor da escala
			cAliasRBG		:= "RBG" + cValToChar(nI)	
			cJoinHabil 	+= " JOIN "+RetSQLName('RBG')+" " + cAliasRBG + " ON "
			cJoinHabil 	+= cAliasRBG + ".RBG_FILIAL = '"+xFilial("RBG")+"' " 
			cJoinHabil 	+= " AND " + cAliasRBG + ".RBG_HABIL = '" + aHabil[nI][1] + "' "
			cJoinHabil 	+= " AND " + cAliasRBG + ".D_E_L_E_T_ = ' ' "
			
			cAliasRBLX		:= "RBLX" + cValToChar(nI)								
			cJoinHabil 	+= "JOIN " + RetSQLName('RBL') + " " + cAliasRBLX + " ON "
			cJoinHabil 	+= cAliasRBLX + ".RBL_FILIAL = '"+xFilial("RBL")+"' "
			cJoinHabil 	+= "AND " + cAliasRBLX + ".RBL_ESCALA = "+cAliasRBG+".RBG_ESCALA "
			cJoinHabil 	+= "AND " + cAliasRBLX + ".RBL_ITEM = '" + aHabil[nI][3] + "' "
			cJoinHabil 	+= "AND " + cAliasRBLX + ".D_E_L_E_T_ = ' ' "
			
			//Recupera atendentes considerando o valor da escala atribuido a ele
			cAliasRBI		:= "RBI" + cValToChar(nI)					                            
			cJoinHabil 	+= "JOIN " + RetSQLName('RBI') + " " + cAliasRBI + " ON "
			cJoinHabil 	+= cAliasRBI+".RBI_FILIAL = '"+xFilial("RBI")+"' "
			cJoinHabil 	+= " AND AA1.AA1_CDFUNC = " + cAliasRBI + ".RBI_MAT "
			cJoinHabil 	+= " AND " + cAliasRBI + ".RBI_HABIL = " + cAliasRBG + ".RBG_HABIL "                        
			cJoinHabil 	+= " AND " + cAliasRBI + ".D_E_L_E_T_ = ' ' "
                  
			cTableAlias	:= "RBL" + cValToChar(nI)	 
			cJoinHabil 	+= "JOIN " + RetSQLName('RBL') + " "+cTableAlias+" ON "
			cJoinHabil 	+= cTableAlias+".RBL_FILIAL = '"+xFilial("RBL")+"' "
			cJoinHabil 	+= "AND " + cTableAlias + ".RBL_ESCALA = " + cAliasRBI + ".RBI_ESCALA "
			cJoinHabil 	+= "AND " + cTableAlias + ".RBL_ITEM = " + cAliasRBI + ".RBI_ITESCA "
			cJoinHabil 	+= "AND " + cTableAlias + ".RBL_VALOR >= " + cAliasRBLX + ".RBL_VALOR "
			cJoinHabil 	+= "AND " + cTableAlias + ".D_E_L_E_T_ = ' ' "

		Else
			cTableAlias 	:= "AA2" + cValToChar(nI)  
			cJoinHabil 	+= " JOIN " + RetSQLName('AA2') + " " + cTableAlias + " ON "
			cJoinHabil 	+= cTableAlias + ".AA2_FILIAL = '" + xFilial("AA2") + "' "
			cJoinHabil 	+= " AND AA1.AA1_CODTEC = " + cTableAlias + ".AA2_CODTEC " 
			cJoinHabil		+= " AND " + cTableAlias + ".AA2_HABIL = '" + aHabil[nI][1] + "' "
			cJoinHabil		+= " AND " + cTableAlias + ".AA2_NIVEL >= " + cValToChar(aHabil[nI][2])
			cJoinHabil		+= " AND " + cTableAlias + ".D_E_L_E_T_ = ' ' "
		EndIf
	
	Next nI
	
EndIf

//------------------------------------------------------------------
If !Empty(cIdCfAbq) // Estrutura nova de alocação	
	cWhereABB 	:= "AND ( ABB_IDCFAL = '" + cIdCfAbq + "')"
	If !Empty(cLocOrc)
		cWhereABB += " AND ABB_LOCAL = '" + cLocOrc + "'"
	EndIf
ElseIf ( !Empty(cItemOS) )	// Filtro por Item da OS
	cWhereABB 	:= "AND ( ABB_ENTIDA = 'AB7' AND ABB_CHAVE = '" + cItemOS + "')"
EndIf 
//------------------------------------------------------------------

//------------------------------------------------------------------
// Filtro por Data do agendamento da alocação
//------------------------------------------------------------------
If ( !Empty(dIniAloc) ) .And. ( !Empty(dFimAloc) )

	cWhereABB	+= " AND ( ABB_DTINI BETWEEN '" + DtoS(dIniAloc) + "' AND '" + DToS(dFimAloc) + "'"
	cWhereABB	+= " OR ABB_DTFIM BETWEEN '" + DToS(dIniAloc) + "' AND '" + DToS(dFimAloc) + "' )"

//
ElseIf ( Len( aPeriodos ) > 0 .OR. Len(aPeriodRes) > 0)
	//Caso seja listagem de Reserva considera as informações do periodo da reserva
	If cLista == "2" .AND. Len(aPeriodRes) > 0//Reserva
		cWhereABB += GetSqlPeri(aPeriodRes)
	Else
		cWhereABB += GetSqlPeri(aPeriodos)
	EndIf

EndIf

//------------------------------------------------------------------
// Filtra apenas agendamentos ativos e que nao foi atendido.
//------------------------------------------------------------------ 
cWhereABB	+= " AND ABB.ABB_ATIVO <> '2'"

If cDisponib == "A"
	cWhereABB += " AND ABB.ABB_ATENDE <> '1'"
EndIf

//------------------------------------------------------------------
// Filtro por região de atendimento
//------------------------------------------------------------------
If ( Len(aRegiao) > 0 )
	
	cWhereReg := " AND ( "
	
	For nI := 1 To Len(aRegiao)
		cWhereReg += " ABU_REGIAO = '" + aRegiao[nI] + "'"
		
		If ( nI == Len(aRegiao) )
			cWhereReg += " )"
		Else
			cWhereReg += " OR"
		EndIf
	Next nI
	
	cWhereDisp		+= " AND ABU.ABU_CODTEC IS NOT NULL"
	cWhereIndisp	+= " AND ABU.ABU_CODTEC IS NOT NULL"
EndIf

cWhereDisp 	+= " AND '" + cDisponib + "' IN ('T','D') "		//Se for "A" ou "I", ignora a consulta de disponíveis
cWhereIndisp 	+= " AND '" + cDisponib + "' IN ('T','A','I') "	//Se for "A" ou "I", ignora a consulta de disponíveis

If ( lEstrut )
	cWhereDisp		+= " AND 1 = 2"
	cWhereIndisp	+= " AND 1 = 2"
EndIf

//------------------------------------------------------------------
// Filtra por Caracteristica
//------------------------------------------------------------------
//Verifica se foi informada alguma caracteristica no filtro		
If ( Len(aCarac) > 0 )

	For nI := 1 To Len( aCarac )
		cCarac 	+= " '" + aCarac[nI] + "'"

		If ( nI < Len( aCarac ) )
			cCarac 	+= ","
		EndIf
	Next nI
	
	cJoinCarac := " JOIN "+RetSQLName('TDU')+" TDU ON TDU_FILIAL = '"+xFilial("TDU")+"' "
	cJoinCarac += "    AND TDU_CODTEC = AA1_CODTEC "
	cJoinCarac += "    AND TDU.D_E_L_E_T_ = ' ' "
	cJoinCarac += "    AND TDU_CODTCZ IN( "+cCarac+") "
EndIf

//------------------------------------------------------------------
// Filtra por Curso, apenas se integrado ao RH
//------------------------------------------------------------------
If ( lRH ) .And. ( Len( aCursos ) > 0 )
	
	For nI := 1 To Len( aCursos )
		cCursos	+= " '" + aCursos[nI] + "'"

		If ( nI < Len( aCursos ) )
			cCursos 	+= ","
		EndIf
	Next nI
	
	cJoinCursos := " JOIN "+RetSQLName('RA4')+" RA4 ON RA4_FILIAL = '"+xFilial("RA4")+"' "
	cJoinCursos += "    AND RA4_MAT = RA_MAT "
	cJoinCursos += "    AND RA4.D_E_L_E_T_ = ' ' "
	cJoinCursos += "    AND RA4_CURSO IN( "+cCursos+") "	
EndIf

cJoinHabil		:= '%' + cJoinHabil + '%'
cWhereDisp		:= '%' + cWhereDisp + '%'
cWhereIndisp	:= '%' + cWhereIndisp + '%'
cWhereABB		:= '%' + cWhereABB + '%'
cWhereHab		:= '%' + cWhereHab + '%'
cWhereHabRH	:= '%' + cWhereHabRH + '%'
cWhereReg		:= '%' + cWhereReg + '%'
cJoinCarac		:= '%' + cJoinCarac + '%'
cJoinCursos		:= '%' + cJoinCursos + '%'

//-------------------------------------------------------------------------------------
// Query de consulta de recursos
//-------------------------------------------------------------------------------------
BeginSql alias cAlias

	//-----------------------------------------------------------
	// Seleciona os Atendentes disponíveis para alocação
	//-----------------------------------------------------------	   
	SELECT DISTINCT TMP_LEGEN, TMP_FILIAL, TMP_CODTEC, TMP_NOMTEC, TMP_CDFUNC, TMP_TURNO, TMP_FUNCAO, 
	       TMP_CARGO, TMP_DISP, TMP_DISPRH, TMP_ALOC, TMP_SITFOL, TMP_DESC, TMP_OK, TMP_RESTEC 
	FROM (   
	   SELECT '               '	AS TMP_LEGEN,
	   		   AA1_FILIAL 		AS TMP_FILIAL,
	          AA1_CODTEC 		AS TMP_CODTEC,
	          AA1_NOMTEC 		AS TMP_NOMTEC,
	          AA1_CDFUNC 		AS TMP_CDFUNC,
	          CASE WHEN RA_TNOTRAB IS NULL
	              THEN AA1_TURNO
	              ELSE RA_TNOTRAB
	          END  				AS TMP_TURNO,
	          CASE WHEN RA_CODFUNC IS NULL
	              THEN AA1_FUNCAO
	              ELSE RA_CODFUNC
	          END  				AS TMP_FUNCAO,
	          RA_CARGO			AS TMP_CARGO,	
	          %Exp:cSim% 		AS TMP_DISP,
	          %Exp:cSim% 		AS TMP_DISPRH,
	          %Exp:cNao% 		AS TMP_ALOC,
	          CASE WHEN RA_SITFOLH IS NULL THEN ' ' 
	          		ELSE RA_SITFOLH 
	          END 				AS TMP_SITFOL,
	          CASE WHEN X5_DESCRI IS NULL THEN ' ' 
	          		ELSE X5_DESCRI 
	          END 				AS TMP_DESC,	          
	          '  ' AS TMP_OK,
	          ABB.TCU_RESTEC    AS TMP_RESTEC
	     FROM %Table:AA1% AA1
	//Contratos de Manutenção
	LEFT JOIN %Table:AAH% AAH  
	       ON %xFilial:AAH% = AAH.AAH_FILIAL
	      AND AA1.AA1_CC = AAH.AAH_CCUSTO
	      AND AA1.AA1_CC <> %Exp:cCCVazio%
	      AND AAH.%NotDel%
	//Agenda de Atendimentos
	LEFT JOIN (   SELECT ABB_FILIAL, ABB_CODTEC, TCU_RESTEC       
	              FROM %Table:ABB% ABB, %Table:TCU% TCU
	              WHERE ABB.%NotDel% AND
	                    TCU.%NotDel% AND TCU_FILIAL = %xFilial:TCU% AND
	                    (TCU_COD = ABB_TIPOMV OR ABB_TIPOMV='')  
	                    %Exp:cWhereABB%  
	           ) ABB
	       ON %xFilial:ABB% = ABB.ABB_FILIAL
	      AND AA1.AA1_CODTEC = ABB.ABB_CODTEC
	//Funcionários
	LEFT JOIN %Table:SRA% SRA  
	       ON AA1.AA1_FUNFIL = SRA.RA_FILIAL
	      AND AA1.AA1_CDFUNC = SRA.RA_MAT
	      AND SRA.%NotDel%
	//Programação de Férias
	LEFT JOIN %Table:SRF% SRF  
	       ON SRA.RA_MAT = SRF.RF_MAT
	      AND SRA.RA_FILIAL = SRF.RF_FILIAL
	      AND SRF.%NotDel%

	%Exp:cJoinCarac%
	
	//Tabelas genéricas
	LEFT JOIN %Table:SX5% SX5  
	       ON SX5.X5_TABELA = '31'	//31 - Tabela de Situações da Folha
	      AND SX5.X5_CHAVE = SRA.RA_SITFOLH
	      AND SX5.%NotDel%
	//Habilidades dos funcionários
	%Exp:cJoinHabil%		      
	//Região de atendimento
	LEFT JOIN ( SELECT DISTINCT
			            ABU_FILIAL,
	                   ABU_CODTEC
	              FROM %Table:ABU% ABU
	             WHERE ABU.%NotDel% %Exp:cWhereReg% ) ABU
	       ON ABU.ABU_FILIAL = %xFilial:ABU%
	      AND AA1.AA1_CODTEC = ABU.ABU_CODTEC

	%Exp:cJoinCursos%
	      
	    WHERE %Exp:cWhereDisp%
	      AND AA1.%NotDel%
	      %Exp:cChvAA1%
      
	UNION ALL
	
	//-----------------------------------------------------------
	//Seleciona os Atendentes indisponíveis para alocação
	//-----------------------------------------------------------
	SELECT '               '	AS TMP_LEGEN,
	   		AA1_FILIAL 		AS TMP_FILIAL,
	       AA1_CODTEC 		AS TMP_CODTEC,
	       AA1_NOMTEC 		AS TMP_NOMTEC,
	       AA1_CDFUNC 		AS TMP_CDFUNC,
	       CASE WHEN RA_TNOTRAB IS NULL
	              THEN AA1_TURNO
	              ELSE RA_TNOTRAB
	          END  			AS TMP_TURNO,
	          CASE WHEN RA_CODFUNC IS NULL
	              THEN AA1_FUNCAO
	              ELSE RA_CODFUNC
	          END  			AS TMP_FUNCAO,
          	RA_CARGO			AS TMP_CARGO,		       
	       %Exp:cNao% 		AS TMP_DISP,
	       %Exp:cSim% 		AS TMP_DISPRH,
	       CASE WHEN ABB.ALOCADO IS NULL THEN %Exp:cNao% 
	       	ELSE ABB.ALOCADO 
	       END 				AS TMP_ALOC,
	       CASE WHEN RA_SITFOLH IS NULL THEN ' ' 
	       	ELSE RA_SITFOLH 
	       END			       AS TMP_SITFOL,
	       CASE WHEN X5_DESCRI IS NULL THEN ' ' 
	       	ELSE X5_DESCRI 
	       END 				AS TMP_DESC,	       
	       '  ' 				AS TMP_OK,
	       ABB.TCU_RESTEC AS TMP_RESTEC
	       
	     FROM %Table:AA1% AA1
	//Contratos de Manutenção
	LEFT JOIN %Table:AAH% AAH  
	       ON %xFilial:AAH% = AAH.AAH_FILIAL
	      AND AA1.AA1_CC = AAH.AAH_CCUSTO
	      AND AA1.AA1_CC <> %Exp:cCCVazio%
	      AND AAH.%NotDel%
	//Agenda de Atendimentos
	LEFT JOIN ( SELECT ABB_FILIAL, ABB_CODTEC, TCU_RESTEC, %Exp:cSim% AS ALOCADO       
	              FROM %Table:ABB% ABB, %Table:TCU% TCU
	             WHERE ABB.%NotDel% %Exp:cWhereABB% AND
	                   TCU.%NotDel% AND TCU_FILIAL = %xFilial:TCU% AND
	                   (TCU_COD = ABB_TIPOMV OR ABB_TIPOMV='') ) ABB
	       ON %xFilial:ABB% = ABB.ABB_FILIAL
	      AND AA1.AA1_CODTEC = ABB.ABB_CODTEC
	//Funcionários
	LEFT JOIN %Table:SRA% SRA  
	       ON AA1.AA1_FUNFIL = SRA.RA_FILIAL
	      AND AA1.AA1_CDFUNC = SRA.RA_MAT
	//Programação de Férias
	LEFT JOIN %Table:SRF% SRF  
	       ON SRA.RA_MAT = SRF.RF_MAT
	      AND SRA.RA_FILIAL = SRF.RF_FILIAL

	%Exp:cJoinCarac%
	
	//Tabelas genéricas
	LEFT JOIN %Table:SX5% SX5  
	       ON SX5.X5_TABELA = '31'	//31 - Tabela de Situações da Folha
	      AND SX5.X5_CHAVE = SRA.RA_SITFOLH	
	//Habilidades dos funcionários
	%Exp:cJoinHabil%

	//Região de atendimento	
	LEFT JOIN ( SELECT DISTINCT
			            ABU_FILIAL,
	                   ABU_CODTEC
	              FROM %Table:ABU% ABU
	             WHERE ABU.%NotDel% %Exp:cWhereReg% ) ABU
	       ON ABU.ABU_FILIAL = %xFilial:ABU%
	      AND AA1.AA1_CODTEC = ABU.ABU_CODTEC

	%Exp:cJoinCursos%
		            
	    WHERE %Exp:cWhereIndisp%
	      AND AA1.%NotDel%	 	           
	      %Exp:cChvAA1%	 	           
	 ) TAB_QRY       
	
EndSql

//----------------------------------------------------------------------
// Cria arquivo de dados temporário
//----------------------------------------------------------------------
cTempTab:= GetNextAlias()
oTempTab:= FWTemporaryTable():New(cTempTab)
oTempTab:SetFields(aStructure)
oTempTab:AddIndex("I1",{"TMP_FILIAL","TMP_CODTEC"})
oTempTab:Create()
(cTempTab)->(dbGotop())

DBTblCopy(cAlias, cTempTab)

If ( Select( cAlias ) > 0 )
	DbSelectArea(cAlias)
	DbCloseArea()
EndIf

dbSelectArea(cTempTab)

//----------------------------------------------------------------------
// Monta estrutura para a criação do FormBrowse
//----------------------------------------------------------------------
For nI := 1 To Len( aCampos )
	
	If ( aCampos[nI][1] != 'TMP_OK' )
	
		AAdd( aColumns, FWBrwColumn():New() )
		aColumns[nI]:SetData( &("{||" + aCampos[nI][1] + "}") )
		aColumns[nI]:SetTitle( aCampos[nI][2] )
		aColumns[nI]:SetSize(5)
		aColumns[nI]:SetDecimal(0)
	
		If ( aCampos[nI][1] == 'TMP_LEGEN' )
			aColumns[nI]:SetPicture("@BMP")
			aColumns[nI]:SetImage(.T.)
		EndIf
	EndIf	
	
Next nI

//----------------------------------------------------------------------
// Monta legenda da consulta
//----------------------------------------------------------------------
(cTempTab)->(DbGoTop())

//verificar as restrições por local de atendimento / cliente - tabela TW2
// por performance sera retornado um array com todas as restrições do local

aTW2Restri:=TxRestri(cLocalAloc) 	
   
While (cTempTab)->(!Eof())
	
	(cTempTab)->(Reclock( cTempTab, .F.))
	
	//Integração com RH
	If lRH
		
		//Verificação pela data de alocação
		If ( !Empty(dIniAloc) ) .And. ( !Empty(dFimAloc) )				
			lDispRH := At570VldRh((cTempTab)->TMP_CODTEC, dIniAloc, dFimAloc )
			
		//Verificação pelos periodos informados
		ElseIf Len( aPeriodos ) > 0
			For nI := 1 To Len( aPeriodos )
				lDispRh := At570VldRh((cTempTab)->TMP_CODTEC, aPeriodos[nI][1], aPeriodos[nI][3] )
				If !lDispRh
					Exit
				EndIf
			Next nI
		EndIf
		
		If !lDispRh
			(cTempTab)->TMP_DISP := cNao
			(cTempTab)->TMP_DISPRH := cNao
		EndIf
		
	EndIf
	
	//Tratamento para consultar alocacao em RESERVA TECNICA
	//regra: caso o local de destino seja informado, e nao seja reserva, se o recurso estiver em algum local como reserva, lista como DISPONIVEL
	If !Empty(cLocalAloc)
		dbSelectArea("ABS")
		ABS->(dbSetOrder(1))
		ABS->(dbSeek(xFilial("ABS")+cLocalAloc ))
		If ABS->ABS_RESTEC <> "1" .And. (cTempTab)->TMP_RESTEC == "1"
			(cTempTab)->TMP_DISP := cSim
			(cTempTab)->TMP_ALOC := cNao
		EndIf
	EndIf
	
	//Monta legenda para tela de alocação com status dos atendentes
	If ( nLegenda == 1 )		
		//Recurso indisponível (RH)
		If UPPER((cTempTab)->TMP_DISPRH) == UPPER(cNao)
		 	(cTempTab)->TMP_LEGEN := 'BR_VERMELHO'			
		//Recurso disponível
		ElseIf ( UPPER((cTempTab)->TMP_DISP) == UPPER(cSim) ) .And. ( UPPER((cTempTab)->TMP_ALOC) == UPPER(cNao) )
			//Verificar se tem restrição operacional
			nPosTw2:= aScan(aTW2Restri,{|x| x[1] == (cTempTab)->TMP_CODTEC })
			If 	nPosTW2 > 0
				If aTW2Restri[nPosTW2][8] == '1' //Aviso de restrição local/cliente
					(cTempTab)->TMP_LEGEN := 'BR_LARANJA'
				Elseif aTW2Restri[nPosTW2][8] == '2' //Bloqueio de restrição local/cliente
					(cTempTab)->TMP_LEGEN := 'BR_PRETO'
				Endif
			Else
				//disponivel para alocação
				(cTempTab)->TMP_LEGEN := 'BR_BRANCO'
			Endif
		//Recurso indisponível (Alocado)
		ElseIf ( UPPER((cTempTab)->TMP_DISP) == UPPER(cNao) ) .And. ( UPPER((cTempTab)->TMP_ALOC) == UPPER(cSim) )
			(cTempTab)->TMP_LEGEN := 'BR_AMARELO'
		 	
		//Recurso indisponível (RH)				
		Else
			(cTempTab)->TMP_LEGEN := 'BR_VERMELHO'
		EndIf
		
	//Monta legenda de tela de recursos alocados com apenas uma cor
	ElseIf ( nLegenda == 2 )
		(cTempTab)->TMP_LEGEN := 'BR_PRETO'
	EndIf
	
	(cTempTab)->(MsUnlock())
	
		aRet := TxAHabil((cTempTab)->TMP_CODTEC)
	
		If Len(aRet) > 0
			aAdd(aHabAtd,aRet[1])
		EndIf 
	
		aRet := TxARegiao((cTempTab)->TMP_CODTEC)
	
		If Len(aRet) > 0
			aAdd(aRegAtd,aRet[1])
		EndIf 

		// Caracteristica
		aRet := TxCarac((cTempTab)->TMP_CODTEC)
	
		If Len(aRet) > 0
			aAdd(aCarAtd,aRet[1])
		EndIf		

		// Curso
		aRet := TxCurso((cTempTab)->TMP_CODTEC)
	
		If Len(aRet) > 0
			aAdd(aCurAtd,aRet[1])
		EndIf
		
	(cTempTab)->(DbSkip())
	
EndDo 
  
Return { cTempTab, cTempIdx, aColumns, aHabAtd, aRegAtd, aCarAtd, aCurAtd  }


//------------------------------------------------------------------------------
/*/{Protheus.doc} TxDadosCpo
Função auxiliar que retorna dados de um campo no SX3.

@sample 	TxDadosCpo( cCampo )

@param		cCampo	Nome do campo que deseja obter informações.
			
@return	aDados Dados do campo.
					[1] Título do campo.
					[2] Descrição do campo.

@since		13/11/2012
@version	P12
/*/
//------------------------------------------------------------------------------
Function TxDadosCpo( cCampo )

Local aArea	:= GetArea()
Local aDados	:= {}

DbSelectArea('SX3')		//Campos da tabela
SX3->( DbSetOrder(2) )	//X3_CAMPO
SX3->( DbGoTop() )

If ( SX3->( MsSeek( cCampo ) ) )

	AAdd( aDados, X3Titulo() )	//Retorna título do campo no X3
	AAdd( aDados, X3Descric() )	//Retorna descrição do campo no X3

EndIf

RestArea( aArea )

Return aDados         


//------------------------------------------------------------------------------
/*/{Protheus.doc} ApagarTemp
Função auxiliar que exclui arquivo temporário.

@sample 	ApagarTemp( cArquivo )

@param		cArquivo	Arquivo que deve ser apagado.
			
@return	aRet 		Resultado da operação.
						[1] Resultado - (0)Sucesso | (-1) Erro.
						[2] Descrição do erro, caso o resultado seja -1.

@since		23/11/2012
@version	P12
/*/
//------------------------------------------------------------------------------
Function ApagarTemp( cArquivo )

Local aRet 	:= {}
Local nResult	:= 0
Local cErro	:= ''

Default cArquivo := Nil

If ( cArquivo != Nil )

	If ( File( cArquivo + '.DBF' ) )
	
		(cArquivo)->(DbCloseArea())
		
		nResult := FErase( cArquivo + '.DBF' )
		
		If ( nResult != 0 )
			cErro = FError()
		Else
			If ( File( cArquivo + '.IDX' ) )
				FErase( cArquivo + '.IDX' )
			EndIf
		EndIf
		
		AAdd( aRet, { nResult, cErro } )
		
	EndIf
		
EndIf

Return aRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} TxAHabil
Função para criar tabela temporária com registros de recursos do 
Banco de Apoio para uso em rotinas do SIGATEC.

@sample TxAHabil(cCodAtend)

@param	ExpC1	Codigo do atendente.
			
@return	ExpA	Habilidades do Atendente.

@author		Anderson Silva	
@since		13/11/2012
@version	P12
/*/
//------------------------------------------------------------------------------
Function TxAHabil(cCodAtend)

Local aHabAtd 	 := {}
Local cDescHab	 := ""
Local nLinha 	 	 := 0
Local lTecXRh	 	 := SuperGetMv("MV_TECXRH",,.F.)	   			// Integracao Gestao de Servicos com RH?.
Local cDescHabil	 := ""
Local cDescEscal	 := ""
Local cDescItEsc	 := ""

If lTecXRh
	
	DbSelectArea("AA1")
	DbSetOrder(1)  
	
	DbSelectArea("RBI")
	DbSetOrder(1)
	
		
	If AA1->(DbSeek(xFilial("AA1")+cCodAtend))
			
		DbSelectArea("RBI")
		DbSetOrder(1)
			
		If RBI->(DbSeek(xFilial("RBI")+AA1->AA1_CDFUNC))
			
			aAdd(aHabAtd,{cCodAtend})
					
			While ( RBI->(!Eof()) .AND. RBI->RBI_FILIAL == xFilial("RBI") .AND. RBI->RBI_MAT == AA1->AA1_CDFUNC )
					
				cDescHabil := Capital(AllTrim(FDesc("RBG",RBI->RBI_HABIL,"RBG_DESC")))
				cDescEscal := Capital(AllTrim(FDesc("RBK",RBI->RBI_ESCALA,"RBK_DESCRI")))
				cDescItEsc := Capital(AllTrim(FDesc("RBL",RBI->RBI_ESCALA + RBI->RBI_ITESCA,"RBL_DESCRI")))
				nLinha := Len(aHabAtd)
				aAdd(aHabAtd[nLinha],{RBI->RBI_HABIL,cDescHabil,0,RBI->RBI_ESCALA,cDescEscal,RBI->RBI_ITESCA,cDescItEsc})
					
				RBI->(DbSkip())
			End
				
		EndIf
	EndIf
			
Else
	
	DbSelectArea("AA2")
	DbSetOrder(1)
	
	If AA2->(DbSeek(xFilial("AA2")+cCodAtend))
			
		aAdd(aHabAtd,{cCodAtend})
			
		While ( AA2->(!Eof()) .AND. AA2->AA2_FILIAL == xFilial("AA2") .AND. AA2->AA2_CODTEC == cCodAtend )
				
			cDescHab :=	Posicione("SX5",1,xFilial("SX5")+"A4"+AA2->AA2_HABIL,"X5_DESCRI")
			cDescHab := Capital(Alltrim(cDescHab))
			nLinha := Len(aHabAtd)
			aAdd(aHabAtd[nLinha],{AA2->AA2_HABIL,cDescHab,AA2->AA2_NIVEL,"","","",""})
				
			AA2->(DbSkip())
		End
			
	EndIf
			
EndIf

Return( aHabAtd )

//------------------------------------------------------------------------------
/*/{Protheus.doc} TxARegiao
Função que retorna as regioes de atendimento do atendentes.

@sample	TxARegiao(cCodAtend)

@param	ExpC1	Codigo do atendente.
			
@return	ExpA	Regiao de Atendimento.

@author		Anderson Silva	
@since		13/11/2012
@version	P12
/*/
//------------------------------------------------------------------------------
Function TxARegiao(cCodAtend)

Local aRegiao 	 := {}
Local nLinha 		 := 0
Local cDescReg 	 := ""
	
DbSelectArea("AA1")
DbSetOrder(1)

If AA1->(DbSeek(xFilial("AA1")+cCodAtend))
	If !Empty(AA1->AA1_REGIAO)	
		aAdd(aRegiao,{cCodAtend})
		cDescReg :=	Posicione("SX5",1,xFilial("SX5")+"A2"+AA1->AA1_REGIAO,"X5_DESCRI")
		cDescReg := Capital(Alltrim(cDescReg))
		nLinha := Len(aRegiao)
		aAdd(aRegiao[nLinha],{AA1->AA1_REGIAO,cDescReg+STR0028}) //" (Residência)"			
	EndIf
EndIf

DbSelectArea("ABU")
DbSetOrder(1)

If ABU->(DbSeek(xFilial("ABU")+cCodAtend)) 	
	If Len(aRegiao) == 0
		aAdd(aRegiao,{cCodAtend})
	EndIf	
	
	While ( ABU->(!Eof()) .AND. ABU->ABU_FILIAL == xFilial("ABU") .AND. ABU->ABU_CODTEC == cCodAtend )		
		If ABU->ABU_REGIAO <> AA1->AA1_REGIAO 
			cDescReg :=	Posicione("SX5",1,xFilial("SX5")+"A2"+ABU->ABU_REGIAO,"X5_DESCRI")
			cDescReg := Capital(Alltrim(cDescReg))
			nLinha := Len(aRegiao)
			aAdd(aRegiao[nLinha],{ABU->ABU_REGIAO,cDescReg})
		EndIf		
		ABU->(DbSkip())
	End		
EndIf
		
Return( aRegiao )

//------------------------------------------------------------------------------
/*/{Protheus.doc} TxRtDiaSem
Retorna o dia da semana.

@sample	TxRtDiaSem(dData)

@param	ExpD1	Data.
			
@return	ExpC	Dia da Semana.

@author		Anderson Silva	
@since		13/11/2012
@version	P12
/*/
//------------------------------------------------------------------------------
Function TxRtDiaSem(dData)
Local aSemana	:= {}
Local nPos		:= 0

aSemana := {{1,STR0029}	,;	//"Domingo"
			{2,STR0030}	,;	//"Segunda-feira"
			{3,STR0031}	,;	//"Terça-feira"
			{4,STR0032}	,;	//"Quarta-feira"
			{5,STR0033}	,;	//"Quinta-feira"
			{6,STR0034}	,;	//"Sexta-feira"
			{7,STR0035}} 	//"Sábado"
				
nPos := aScan(aSemana,{|x| x[1] == Dow(dData)})


Return( aSemana[nPos][2] )     

/*/{Protheus.doc} TxCalenAtd
Funcao para criar o calendario do atendente utilizado CriaCalend.

@sample 	TxCalenAtd(dAlocDe,dAlocAte,cCodAtend,aCalendAtd,aCalendInf)

@param		ExpD1	Alocacao De. 
			ExpD2	Alocacao Ate.
			ExpC3	Codigo do atendente.
			ExpA4	Calendario do atendente (Referencia).
			ExpA5	Informacoes do calendario do atendente (Referencia).
			ExpC6	Turno a ser considerado para montar o calendario.
			ExpC7	Sequencia a ser considerada para montar o calendario. 
			ExpL8	Utiliza o CriaCalend para transferencia.
			ExpL9	Exibe a mensagem de help quando existir conflito de alocação?
			ExpC10	Dia inicial do período de alocação.
			ExpC11	Codigo do local de destino da alocacao, para validacao em caso de RESERVA TECNICA
			ExpC12	Filial do atendente para uso na pesquisa ao atendente (default: xFilial("AA1"))
			ExpC13	Variável para captura da descrição do erro.
			
@return		ExpL	Verdadeiro / Falso.

@author		Anderson Silva					
@since		23/11/2012
@version	P12
/*/ 
Function TxCalenAtd(dAlocDe,dAlocAte,cCodAtend,aCalendAtd,aCalendInf,cTurno,cSequen,lTransf,lExibeHelp,dPerIni, cLocAloc, cFilAtd, cErroRet)

Local lRetorno  	:= .F.												//	Retorno da rotina.
Local aTabPadrao	:= {}        										//	Tabela de horario padrao.
Local aTabCalend	:= {}   											//	Calendario do atendente retornando pelo CriaCalend.
Local aPeriodos		:= {}   											// 	Calendario do atendente (Tratato). 
Local nX			:= 0       											//	Incremento utilizado no for.
Local lTecXRh 		:= SuperGetMv("MV_TECXRH",,.F.) 					//	Integracao Gestao de Servicos com RH?.
Local nTotalHrs	 	:= 0    											// 	Total de horas.
Local nDiasTrab	 	:= 0												//	Total de dias trabalhados. 			
Local nTotHrsTrb	:= 0												//	Total de horas trabalhadas.
Local cTurnoTrb		:= ""												//	Turno de trabalho.
Local cSeqTurno		:= "" 												//	Sequencia do turno.	
Local cHrEntrada	:= ""												//	Hora de entrada.
Local cHrSaida		:= ""												//	Hora de saida.

Default dAlocDe 	:= cTod("//")  										//	Alocacao de.
Default dAlocAte	:= cTod("//") 										//	Alocacao ate.
Default cCodAtend	:= "" 												//	Codigo do atendente.
Default cTurno		:= "" 												//	Turno de trabalho.
Default cSequen		:= "" 												//	Sequencia do turno.   
Default aCalendAtd 	:= {}												//	Calendario do atendente (Referencia)
Default aCalendInf 	:= {}  												//	Informacoes do calendario (Referencia)
Default lTransf		:= .F. 												//	Utiliza o CriaCalend para transferencia de atendentes.
Default lExibeHelp 	:= .T.											// Define se será exebido help quando identificar divergência na alocação
Default dPerIni		:= STOD("")
Default cLocAloc    := "" 												//  Codigo do local de destino da alocacao do atendente 
Default cFilAtd 	:= xFilial("AA1")									// Código da filial do atendente selecionado para alocação
Default cErroRet 	:= "" 												// variável para retorno mais inteligente com a descrição do erro

DbSelectArea("AA1")
DbSetOrder(1)

If !(AA1->(DbSeek( cFilAtd+cCodAtend )))
	cErroRet := STR0071  // "Atendente não encontrado."
Else
	
	If lTecXRh .And. !lTransf
		
		DbSelectArea("SRA")
		DbSetOrder(1)
		
		If DbSeek(AA1->AA1_FUNFIL + AA1->AA1_CDFUNC)
			
			If 	!Empty(cTurno)
			
				If cTurno == SRA->RA_TNOTRAB .AND. cSequen == SRA->RA_SEQTURN
						lRetorno := CriaCalend(	dAlocDe	   		,;	//01 -> Data Inicial do Periodo
											dAlocAte		,;	//02 -> Data Final do Periodo
											SRA->RA_TNOTRAB	,;	//03 -> Turno Para a Montagem do Calendario
											SRA->RA_SEQTURN ,;	//04 -> Sequencia Inicial para a Montagem Calendario
											@aTabPadrao		,;	//05 -> Array Tabela de Horario Padrao
											@aTabCalend		,;	//06 -> Array com o Calendario de Marcacoes
											SRA->RA_FILIAL  ,;	//07 -> Filial para a Montagem da Tabela de Horario
											SRA->RA_MAT		,;	//08 -> Matricula para a Montagem da Tabela de Horario
											SRA->RA_CC 		,;	//09 -> Centro de Custo para a Montagem da Tabela
											)
				
				Else					
					DbSelectArea("SR6") 
					SR6->( DbSetOrder( 1 ) )// R6_FILIAL + R6_TURNO

					DbSelectArea("SPJ")
					SPJ->( DbSetOrder( 1 ) ) // PJ_FILIAL + PJ_TURNO + PJ_SEMANA + PJ_DIA

					If SR6->( DbSeek( xFilial("SR6", SRA->RA_FILIAL) + cTurno ) ) .And. ;
						SPJ->( DbSeek( xFilial("SPJ", SRA->RA_FILIAL) + cTurno + cSequen ) )

						lRetorno := CriaCalend(	dAlocDe	   		,;	//01 -> Data Inicial do Periodo
												dAlocAte				,;	//02 -> Data Final do Periodo
												cTurno					,;	//03 -> Turno Para a Montagem do Calendario
												cSequen 				,;	//04 -> Sequencia Inicial para a Montagem Calendario
												@aTabPadrao			,;	//05 -> Array Tabela de Horario Padrao
												@aTabCalend			,;	//06 -> Array com o Calendario de Marcacoes
												SRA->RA_FILIAL  		,;	//07 -> Filial para a Montagem da Tabela de Horario
													)						
					Else
						cErroRet := STR0072 // "Turno ou Sequência do item de RH não existe na filial do funcionário."
					EndIf
			
				EndIf	
			Else
				cErroRet := STR0073 // "Turno não informado para a criação do calendário."
			EndIf	
		Else
			cErroRet := STR0074 // "Atendente tem vínculo com funcionário e o funcionário não foi encontrado na tabela SRA."
		EndIf
	Else                    
		
		cTurnoTrb	:= IIF(Empty(cTurno),AA1->AA1_TURNO,cTurno)
		cSeqTurno	:= IIF(Empty(cSequen),"01",cSequen)
		
		lRetorno := CriaCalend(	dAlocDe	   		,;	//01 -> Data Inicial do Periodo
								dAlocAte		,;	//02 -> Data Final do Periodo
								cTurnoTrb		,;	//03 -> Turno Para a Montagem do Calendario
								cSeqTurno		,;	//04 -> Sequencia Inicial para a Montagem Calendario
								@aTabPadrao		,;	//05 -> Array Tabela de Horario Padrao
								@aTabCalend		,;	//06 -> Array com o Calendario de Marcacoes  
								xFilial("SRA")	,;	//07 -> Filial para a Montagem da Tabela de Horario
								)	
	EndIf 
	          
	If lRetorno
			             
		For nX := 1 To Len(aTabCalend) Step 2  
			If aTabCalend[nX][6] == "S" .And. ;
				aTabCalend[nX][1] >= dAlocDe .And. aTabCalend[nX][1] <= dAlocAte // verifica se a data está no período da alocação
				
				cHrEntrada := IntToHora(TxAjtHoras(aTabCalend[nX][3]))
				cHrSaida   := IntToHora(TxAjtHoras(aTabCalend[nX+1][3]))
				nTotHrsTrb := SubtHoras(aTabCalend[nX][1],cHrEntrada,aTabCalend[nX+1][1],cHrSaida)
				
				//Criar validação para o dia a dia.
				If lExibeHelp .And. TxExistAloc(cCodAtend,aTabCalend[nX][1],cHrEntrada,aTabCalend[nX+1][1],cHrSaida,0,,,cLocAloc)
						Help( ,, "TxExistAloc",, ;
							I18N( STR0055,;  // "Já existe alocação para o atendente no período de '#1[diaEnt]# - #2[horaEnt]#' a '#3[diaSai]# - #4[horaSai]#'"
							{aTabCalend[nX][1],cHrEntrada,aTabCalend[nX+1][1],cHrSaida}), 1, 0 )
						Return .F.	
				EndIf
				
				aAdd(aPeriodos,{	aTabCalend[nX][1], TxRtDiaSem(aTabCalend[nX][1]),; // dia entrada ## dia da semana
									cHrEntrada, cHrSaida, IntToHora(nTotHrsTrb),; // hora entrada ## hora saída ## total de horas
									aTabCalend[nX][8], aTabCalend[nX+1][1], ; // sequência do turno ## dia saída
									aTabCalend[nX][48]}) // data referência
				nTotalHrs	+= nTotHrsTrb   
				If aTabCalend[nX][4] == "1E"
					nDiasTrab	+= 1 
				EndIf	
			EndIf	
		Next nX
		
		aCalendAtd	:= aPeriodos
		aCalendInf	:= {nTotalHrs,nDiasTrab}   
	ElseIf Empty(cErroRet)
		cErroRet := STR0075 // "Problemas na geração do calendário padrão para o item ou atendente."
	EndIf 
	
EndIf

Return( lRetorno )

/*/{Protheus.doc} TxSaldoCfg
Funcao para controlar o saldo de horas da configuracao da alocacao.

@sample 	TxSaldoCfg(cIdAloc,nValor,lSoma)

@param		ExpC1	Id. da configuracao da alocacao. 
			ExpN2	Quantidade de horas para compor o saldo.
			ExpL3	Tipo de operacao (.T. para devolver horas para o saldo / .F. para consumir o saldo de horas.) .F.(Default)
			
@return		ExpN	 Saldo de Horas.

@author		Anderson Silva					
@since		23/11/2012
@version	P12
/*/
Function TxSaldoCfg(cIdAloc,nQtdHrs,lSoma)

Local aAreaABQ 	:= ABQ->(GetArea())
Local nSaldo	:= 0

Default cIdAloc := ""
Default nQtdHrs	:= 0
Default lSoma	:= .F.

DbSelectArea("ABQ")
DbSetOrder(1)   

If DbSeek(xFilial("ABQ")+cIdAloc)
 	nSaldo := IIF(lSoma,(ABQ->ABQ_SALDO+nQtdHrs),(ABQ->ABQ_SALDO-nQtdHrs))
	RecLock("ABQ",.F.)
	Replace ABQ->ABQ_SALDO With nSaldo
	MsUnLock()
EndIf

RestArea(aAreaABQ)

Return( nSaldo )    

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TxAjtHoras
Ajusta o formato da horas. (Exemplo 1.3 para 1.5)

@sample TxAjtHoras(nHoras)

@param	ExpN1	Horas sem o ajuste.
			
@return	ExpN	Saldo de Horas. 

@author		Anderson Silva						
@since		23/11/2012
@version	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TxAjtHoras(nHoras)

Local nHrsInt 	:= 0 
Local nResul	:= 0  
Local nHrsAjt	:= 0  

Default nHoras	:= 0

nHrsInt := Int(nHoras)   

nResul 	:= ( nHoras - nHrsInt ) * 100

nHrsAjt :=  ( nResul + ( nHrsInt * 60 ) ) / 60 

Return( nHrsAjt )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TxLogFile()

Cria um Arquivo de Log dentro da pasta do startpath do appserver.ini.
O arquivo sera nomeado de acordo com o parametro + "-" + 

@param ExpC:Nome do Arquivo de Log. Ex: "atendimento" para gerar atendimento-20130131.log
@param ExpC:Texto a ser gravado no arquivo de log

/*/
//--------------------------------------------------------------------------------------------------------------------
Function TxLogFile(cLogName,cText)

Local cFileLog := ""		//Path do arquivo de log a ser gravado
Local nAux					//Auxilia na construcao do arquivo de log                                                                                  

cFileLog := TxLogPath(cLogName)
	
If File(cFileLog)
	nAux := FOpen(cFileLog, FO_READWRITE+FO_SHARED)		
Else
	nAux := FCreate(cFileLog,0)
EndIf
	
If nAux != -1
	FSeek(nAux,0,2)
	FWrite(nAux, AllTrim(DtoC(Date())) + " " + TIME() + " - " + cText + CRLF)
	FClose(nAux)	
EndIf
	
Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TxLogPath()

Retorna o nome do arquivo de log a partir do prefixo informado.

@param ExpC:Nome do Arquivo de Log. Ex: "atendimento" para gerar atendimento-20130131.log

@return cFileLog nome-data.log

/*/
//--------------------------------------------------------------------------------------------------------------------
Function TxLogPath(cLogName)

cFileLog  := ALLTRIM(GetPvProfString(GetEnvServer(),"startpath","",GetADV97()))

If Subs(cFileLog,Len(cFileLog),1) <> "\"
	cFileLog += "\"
EndIf
cFileLog += "GestaoServicos\"

MakeDir(cFileLog)

cFileLog += cLogName + "-" + AllTrim(DToS(Date())) + ".LOG"	  

Return cFileLog


//------------------------------------------------------------------------------
/*/{Protheus.doc} TxSX3Campo
Função auxiliar que retorna dados de um campo no SX3.

@sample 	TxSX3Campo( cCampo )

@param		cCampo	Nome do campo que deseja obter informações.
			
@return	aDados Dados do campo.
					[1] Título do campo.
					[2] Descrição do campo.
					[3] Tamanho do campo.
					[4] Decimais do campo.
					[5] Picture do campo.

@author	Danilo Dias
@since		13/11/2012
@version	P12
/*/
//------------------------------------------------------------------------------
Function TxSX3Campo( cCampo )

Local aArea	:= GetArea()
Local aDados	:= {}

DbSelectArea('SX3')		//Campos da tabela
SX3->( DbSetOrder(2) )	//X3_CAMPO
SX3->( DbGoTop() )

If ( SX3->( MsSeek( cCampo ) ) )

	AAdd( aDados, X3Titulo() )			//Retorna título do campo no X3
	AAdd( aDados, X3Descric() )			//Retorna descrição do campo no X3
	AAdd( aDados, TamSX3(cCampo)[1] )	//Retorna tamanho do campo
	AAdd( aDados, TamSX3(cCampo)[2] )	//Retorna quantidade de casas decimais do campo
	AAdd( aDados, Alltrim(X3Picture(cCampo)) )	//Retorna a picture do campo
	AAdd( aDados, SX3->X3_TIPO ) 
	AAdd( aDados, X3CBox() )

EndIf

RestArea( aArea )

Return aDados

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} checkSIX

Verifica se indice informado existe no dicionário.
Rotina utilizada para a realização de proteção dos indices novos no fonte

@param cALias  String - Tabela do dicionario
@param nOrder Integer - numero do indice a ser verificado.
	
@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   12/06/2013 
@return lRet Boolean
/*/
//--------------------------------------------------------------------------------------------------------------------
Function checkSIX(cAlias, nOrder)
	Local aArea := GetArea()
	Local aAreaSIX := SIX->(GetArea())
	Local lRet := .F.
	
	SIX->(DbSetOrder(1))//INDICE+ORDEM
	If SIX->(MSSeek(cAlias+cValToChar(nOrder)))
		lRet := .T.
	EndIf
	
	RestArea(aAreaSIX)
	RestArea(aArea)
Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} AtCpyData
	Realiza a cópia dos dados de um modelo para outro
evitando sobrepor conteudo de alguns campos, informados na exceção

@sample 	CpyData

@since		23/09/2013
@version	P11.90

@param 		oMdlFrom, Objeto, Modelo de origem dos dados a serem copiado
@param 		oMdlTo, Objeto, Modelo destino dos dados
@param 		aNoCpos, Array, lista com os campos que não devem ter o conteúdo copiado

@return 	lRet, Logico, status da cópia dos dados

/*/
//------------------------------------------------------------------------------
Function AtCpyData( oMdlFrom, oMdlTo, aNoCpos )

Local lRetCpy  := .T.
Local nCpos := 0

Local aStruFrom := oMdlFrom:GetStruct():GetFields()
Local aStruTo   := oMdlTo:GetStruct():GetFields()

Local lExAllStru := .F. 
Local xTmpValue   := Nil
//Campos que dever ser utilizados por SetValue, para que disparem os gatilhos de cálculo 
Local aCposAux  := {	'TFJ_TOTRH','TFJ_TOTMC','TFJ_TOTMI','TFJ_TOTLE',;
						'TFL_TOTRH','TFL_TOTMI','TFL_TOTMC','TFL_TOTLE','TFL_TOTAL','TFL_TOTIMP','TFL_MESRH','TFL_MESMI','TFL_MESMC','TFL_MESIMP',;
						'TFF_SUBTOT','TFF_TOTMI','TFF_TOTMI','TFF_TOTMC','TFF_TOTMES','TFF_PERFIM',;
						'TFI_TOTAL','TEV_MODCOB','TEV_VLRUNI','TEV_SUBTOT','TEV_VLTOT','TEV_QTDE',;
						'TFG_TOTAL','TFG_TOTGER','TFG_PERFIM',;
						'TFH_TOTAL','TFH_TOTGER','TFH_PERFIM' ;
					}


Local lOkWhen   := .F.

lRetCpy := ( Len( aStruFrom ) > 0 .And. Len( aStruTo ) > 0 )

If lRetCpy
	For nCpos := 1 To Len( aStruTo )
		
		lExAllStru := ( aScan( aStruFrom, {|x| x[MODEL_FIELD_IDFIELD]==aStruTo[ nCpos, MODEL_FIELD_IDFIELD ] } ) > 0 .And. ;
						aScan( aNoCpos, aStruTo[ nCpos, MODEL_FIELD_IDFIELD ] ) == 0 )
		
		lOkWhen := If( Valtype(aStruTo[ nCpos, MODEL_FIELD_WHEN ]) == 'B', ; 
					Eval( aStruTo[ nCpos, MODEL_FIELD_WHEN ], oMdlTo, aStruTo[ nCpos, MODEL_FIELD_IDFIELD ]  ), ;
					.T. )
		
		If lExAllStru .And. lOkWhen
			
			xTmpValue := oMdlFrom:GetValue( aStruTo[ nCpos, MODEL_FIELD_IDFIELD ] )
			If aScan( aCposAux, {|x| x==aStruTo[ nCpos, MODEL_FIELD_IDFIELD ] } ) > 0
				lRetCpy := oMdlTo:SetValue( aStruTo[ nCpos, MODEL_FIELD_IDFIELD ], xTmpValue )						
			Else
				lRetCpy := oMdlTo:LoadValue( aStruTo[ nCpos, MODEL_FIELD_IDFIELD ], xTmpValue )
			EndIf
		EndIf
		
	Next nCpos
Else
	Help(,,'CPYMDL01',,STR0024,1,0)  // 'Estrutura dos campos vazia'
EndIf

Return lRetCpy

//------------------------------------------------------------------------------
/*/{Protheus.doc} AtErroMvc
	Captura o erro no objeto do mvc e gera o log. Pode ser usado tbm em execauto 

@sample 	AtErroMvc(oModel)

@since		24/02/2014
@version	P12

@param 		oMdl, Objeto, objeto do mvc MpFormModel/FwFormModel

/*/		  
//------------------------------------------------------------------------------
Function AtErroMvc( oMdl )

Local aMsgErro := {}

DEFAULT oMdl := FwModelActive()

		aMsgErro := oMdl:GetErrorMessage()

		AutoGrLog( STR0044 + ' [' + AllToChar( aMsgErro[1] ) + ']' )	//"Id do formulário de origem:"
		AutoGrLog( STR0045 + ' [' + AllToChar( aMsgErro[2] ) + ']' )	//"Id do campo de origem: "
		AutoGrLog( STR0046 + ' [' + AllToChar( aMsgErro[3] ) + ']' )	//"Id do formulário de erro: "
		AutoGrLog( STR0047 + ' [' + AllToChar( aMsgErro[4] ) + ']' )	//"Id do campo de erro: "
		AutoGrLog( STR0048 + ' [' + AllToChar( aMsgErro[5] ) + ']' )	//"Id do erro: "
		AutoGrLog( STR0049 + ' [' + AllToChar( aMsgErro[6] ) + ']' )	//"Mensagem do erro: "
		AutoGrLog( STR0050 + ' [' + AllToChar( aMsgErro[7] ) + ']' )	//"Mensagem da solução: "
		AutoGrLog( STR0051 + ' [' + AllToChar( aMsgErro[8] ) + ']' )	//"Valor atribuído: "
		AutoGrLog( STR0052 + ' [' + AllToChar( aMsgErro[9] ) + ']' )	//"Valor anterior: "
		
		If ValType(oMdl:GetModel(AllToChar( aMsgErro[3] ))) == "O" .And. ;
			oMdl:GetModel(AllToChar( aMsgErro[3] )):ClassName() == 'FWFORMGRID' .And. ;
			oMdl:GetModel(AllToChar( aMsgErro[3])):GetLine() > 0
			
			AutoGrLog( STR0053 + ' [' + AllTrim( AllToChar( oMdl:GetModel(AllToChar( aMsgErro[3]) ):GetLine() ) ) + ']' )	//"Erro no Item: "
		EndIf

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} TxDiaTrab()
       Verfica se o dia informado é um dia trabalhado de acordo com o turno

@sample      TxDiaTrab(dData, cTurno, cSeq)

@since       26/02/2014
@version     P12

@param              dData dia a ser verificado
@param       cTurno turno que será verificado
@param       cSeq sequencia dos dias do turno
@param       cMat Matrícula do funcionário para geração do criacalend com base no funcionário 
@param       cCC centro de custo do funcionário

/*/            
//------------------------------------------------------------------------------
Function TxDiaTrab(dData, cTurno, cSeq, cMat, cCC)
       Local lRet := .F.
       Local aTabPadrao:= {}
       Local aTabCalend := {}
       Local lRetorno := .T.
       Local cAliasABB	:= GetNextAlias()
       Default cSeq := "01"
       Default cMat := ""
       Default cCC  := ""
       
       If Empty(cMat) .Or. Empty(cCC)
       
              lRetorno := CriaCalend(    dData ,;                  //01 -> Data Inicial do Periodo
                                                            dData ,;            //02 -> Data Final do Periodo
                                                            cTurno,;            //03 -> Turno Para a Montagem do Calendario
                                                            cSeq,;                     //04 -> Sequencia Inicial para a Montagem Calendario
                                                            @aTabPadrao,;       //05 -> Array Tabela de Horario Padrao
                                                            @aTabCalend,;       //06 -> Array com o Calendario de Marcacoes  
                                                            xFilial("SRA"),;    //07 -> Filial para a Montagem da Tabela de Horario
                                                            )
		Else
              lRetorno := CriaCalend(    dData ,;                   //01 -> Data Inicial do Periodo
                                                            dData ,;                   //02 -> Data Final do Periodo
                                                            cTurno,;                   //03 -> Turno Para a Montagem do Calendario
                                                            cSeq,;                     //04 -> Sequencia Inicial para a Montagem Calendario
                                                            @aTabPadrao,;       //05 -> Array Tabela de Horario Padrao
                                                            @aTabCalend,;       //06 -> Array com o Calendario de Marcacoes  
                                                            xFilial("SRA"),;    //07 -> Filial para a Montagem da Tabela de Horario
                                                            cMat ,;                           //08 -> Matrícula do funcionário para a consulta da tabela de horário
                                                            cCC )                      //09 -> Centro de custo para carregar a tabela
		EndIf
                                                      
       If Len(aTabCalend) > 0 .AND. Len(aTabCalend[1])>=6           
			If aTabCalend[1][6] == "S"
				lRet := .T.
			EndIf        
       EndIf
       
		If !lRet .And. !Empty(cMat)

			BeginSql alias cAliasABB
				SELECT 1
					FROM %table:ABB% ABB
					WHERE ABB.ABB_CODTEC =  %exp:cMat%
					AND ABB.ABB_DTINI >= %exp:dData%
					AND ABB.ABB_DTFIM <= %exp:dData%
					AND ABB.ABB_ATIVO = '1'
					AND ABB.%NotDel%
			EndSql

			DbSelectArea(cAliasABB)

			If (cAliasABB)->(!Eof())
				lRet := .T.
			Endif

			(cAliasABB)->(DbCloseArea())

		Endif

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} TxTransfAA1()
Monta o array aCampos para replicar as informações no cadastro de atendente

@since 18/03/2014
@version 1.0
/*/
//------------------------------------------------------------------------------
Function TxTransfAA1(cEmpAnt, cEmpAte,cFilDe, cFilAte,  cMatDe, cMatAte, cCcDe, cCcuAte, cFuncDe, cFuncAte,;
						cTurnDe, cTurnAte, cSeqDe, cSeqAte, cNomDe, cNomAte)
Local aCampos := {}
Local lInteRHAA1	:= If(FindFunction("IntegRHAA1"),IntegRHAA1(),.F.)
Default cEmpAnt	:= ""
Default cEmpAte	:= ""
Default cFilDe	:= ""
Default cFilAte	:= ""
Default cMatDe	:= ""
Default cMatAte	:= ""
Default cCcDe		:= ""
Default cCcuAte	:= ""

If lInteRHAA1

	//Mudança de Filial
	If cEmpAte == cEmpAnt .And. cFilDe <> cFilAte 
		Aadd(aCampos,{"RA_FILIAL",cFilAte})
	EndIf			
	
	//Mudança de Centro de Custo
	If cEmpAte == cEmpAnt .And. cCcDe <> cCcuAte
		Aadd(aCampos,{"RA_CC",cCcuAte})
	EndIf
	
	//Mudança de Matricula
	If cEmpAte == cEmpAnt .And. cMatDe <> cMatAte
		Aadd(aCampos,{"RA_MAT",cMatAte})
	EndIf
	
	//Mudança de Funçao
	If cEmpAte == cEmpAnt .And. cFuncDe <> cFuncAte
		Aadd(aCampos,{"RA_CODFUNC",cFuncAte})
	EndIf
	
	//Mudança de Turno
	If cEmpAte == cEmpAnt .And. cTurnDe <> cTurnAte
		Aadd(aCampos,{"RA_TNOTRAB",cTurnAte})
	EndIf
	
	//Mudança de Sequencia
	If cEmpAte == cEmpAnt .And. cSeqDe <> cSeqAte
		Aadd(aCampos,{"RA_SEQTURN",cSeqAte})
	EndIf
	
	//Mudança de Nome
	If cEmpAte == cEmpAnt .And. cNomDe <> cNomAte
		Aadd(aCampos,{"RA_NOME",cNomAte})
	EndIf
	
	At020AltRH(cMatDe,cFilDe, aCampos)

EndIf

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} IntegRHAA1()
Validação de integração Gest.Serv. com RH para replicar as informações no cadastro de atendente

@since 03/07/2014
@version 1.0
/*/
//------------------------------------------------------------------------------
Function IntegRHAA1()
Local lRet := SuperGetMv("MV_TECXRH",,.F.) .And. FindFunction("At020AltRH")

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} TxQtIntTrab()
	Conta a quantidade de intervalos em um determinado período

@sample 	TxQtIntTrab(dDataIni, dDataFim, cTurno, cSeq)

@since		22/04/2014
@version	P12

@param 		dDataIni data inicial do período para 
@param 		dDataFim dia a ser verificado
@param		cTurno turno que será verificado
@param		cSeq sequencia dos dias do turno

/*/		  
//------------------------------------------------------------------------------
Function TxQtIntTrab(dDataIni,dDataFim, cTurno, cSeq)

Local aTabPadrao    := {}
Local aTabCalend    := {}
Local lRetorno      := .T.
Local nX			:= 0
Local nIntervalos	:= 0
   
Default cSeq := "01"
   
lRetorno := CriaCalend(	dDataIni		,;    //01 -> Data Inicial do Periodo
						dDataFim		,;    //02 -> Data Final do Periodo
						cTurno			,;    //03 -> Turno Para a Montagem do Calendario
						cSeq			,;    //04 -> Sequencia Inicial para a Montagem Calendario
						@aTabPadrao		,;    //05 -> Array Tabela de Horario Padrao
						@aTabCalend		,;    //06 -> Array com o Calendario de Marcacoes  
						xFilial("SRA")	,;    //07 -> Filial para a Montagem da Tabela de Horario
						)

If Len(aTabCalend) > 0
	For nX := 1 To Len(aTabCalend)
		// avalia se é um dia trabalhado e se é um registro de entrada
		If Len(aTabCalend[1])>=6 .AND. aTabCalend[nX][6] == "S" .And. "E"$aTabCalend[nX][4]
			nIntervalos++
		EndIf
	Next nX
EndIf     
         
Return nIntervalos

//------------------------------------------------------------------------------
/*/{Protheus.doc} TxCalF3Medicao / TxRetF3Medicao
	Chama a consulta padrão das medições com o filtro do contrato

@sample 	TxCalF3Medicao( '000000000000009' )

@since		27/06/2014
@version	P12

@param 		xVal, Caracter, número do contrato para receber o filtro das medições 

/*/		  
//------------------------------------------------------------------------------
Function TxCalF3Medicao( xVal )
Local lRet := .F.

If ValType(xVal)=='C'
	cCNDContra := xVal // cria a variável que vai filtrar o código do contrato 
	lRet := ConPad1(,,,'CNDTEC',,,.F.)
EndIf

Return lRet
//------------------------------------------------------------------------------
Function TxRetF3Medicao()
cCNDContra := ''  // zera o código do contrato que recebeu o filtro
Return CND->CND_NUMMED

Static Function GetSqlPeri(aPeriodos)
	Local cRet := ""
	Local nI := 1
	Local dDtIni := CTOD("//")	
	Local cHrIni := ""
	Local dDtFim := CTOD("//")
	Local cHrFim := ""
	
	If Len(aPeriodos)> 0
		cRet += " AND ( "
		
		For nI := 1 To Len( aPeriodos )
		
			dDtIni := aPeriodos[nI][1]
			cHrIni := aPeriodos[nI][2]
			dDtFim := aPeriodos[nI][3]
			cHrFim := aPeriodos[nI][4]
			
			IF Empty(dDtIni)
				dDtIni := CTOD("//")
			ENDIF

			IF Empty(cHrIni)
				cHrIni := ""
			ENDIF

			IF Empty(dDtFim)
				dDtFim := CTOD("//")
			ENDIF

			IF Empty(cHrFim)
				cHrFim := ""
			ENDIF
											
			If ( dDtIni = dDtFim )	//Quando as datas de início e fim do período forem iguais
		
				cRet += " ( ( ABB_DTINI = '" + DtoS(dDtIni) + "' AND ABB_HRINI >= '" + cHrIni + "' AND ABB_HRINI <= '" + cHrFim + "' ) OR" 					//Agendas que comecem dentro do período
				cRet += " ( ABB_DTFIM = '" + DtoS(dDtIni) + "' AND ABB_HRFIM >= '" + cHrIni + "' AND ABB_HRFIM <= '" + cHrFim + "' ) OR" 							//Agendas que terminem dentro do período
				cRet += " ( ABB_DTINI = '" + DtoS(dDtIni) + "' AND ABB_HRINI < '" + cHrIni + "' AND ABB_DTFIM = '" + DtoS(dDtFim) + "' AND ABB_HRFIM > '" + cHrFim + "' ) OR"	//Agendas que comecem antes e termine depois do período, tendo a mesma data de início e fim
		       cRet += " ( ABB_DTINI < '" + DtoS(dDtIni) + "' AND ABB_DTFIM > '" + DtoS(dDtFim) + "' ) )"			  											//Agendas que comecem antes e termine depois do período, tendo data de início e fim diferentes
		
			Else					//Quando as datas de início e fim do período forem diferentes
		
				cRet += " ( ( ABB_DTINI = '" + DtoS(dDtIni) + "' AND ABB_HRINI >= '" + cHrIni + "' ) OR"		//Agendas que comecem dentro do período (Data Inicial)
				cRet += " ( ABB_DTINI = '" + DtoS(dDtFim) + "' AND ABB_HRINI <= '" + cHrFim + "' ) OR"				//Agendas que comecem dentro do período (Data Final)
			   	cRet += " ( ABB_DTFIM = '" + DtoS(dDtIni) + "' AND ABB_HRFIM >= '" + cHrIni + "' ) OR"				//Agendas que terminem dentro do período
				cRet += " ( ABB_DTINI = '" + DtoS(dDtIni) + "' AND ABB_DTFIM = '" + DtoS(dDtFim) + "' ) )"				//Agendas que comecem e terminem nas mesmas datas do período
		
			EndIf
			
			If ( Len(aPeriodos) > nI )
				cRet += " OR"
			Else
				cRet += " )"
			EndIf
			
		Next nI
	EndIf
	
Return cRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} ExistFilTFF()
Verifica se o campo ABQ_FILTFF existe no banco

@since 24/02/2015
@version 12
/*/
//------------------------------------------------------------------------------
Function ExistFilTFF()

Local lRet     := .F.
Local aAreaABQ := GetArea()

DbSelectArea("ABQ")
lRet := ABQ->(FieldPos("ABQ_FILTFF"))>0 // Filial do Recursos Humanos 

RestArea(aAreaABQ)

RETURN lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} TXRetAloc
Retorna as informações de alocação de um determinado funcionário

@sample 	TXRetAloc(_cFunFil, _cMatFunc, _dDtIni, _dDtFim)

@param		ExpC1	Filial do Funcionario
@param		ExpC2	Matricula do Funcionario
@param		ExpD3	Data Inicial da Alocacao
@param		ExpD4	Data Final da Alocacao
	
@return	ExpA	Array dos dados de Alocacao

@author	TOTVS
@since		22/04/2015       
@version	P12.1.5   
/*/         
//------------------------------------------------------------------------------

FUNCTION TXRetAloc(_cFunFil, _cMatFunc, _dDtIni, _dDtFim) 

Local aAreaAloc   := GetArea()	// Guarda a Area de Trabalho
Local aRetAloc    := {}			// Vetor de dados da alocacao

// Temporarios
Local _cAliasABB_ := ''
Local _cAliasABR_ := ''

// Variavel de Controle
Local lOk         := .T.

// Variaveis Auxiliares
Local _cCodTec    := Space(TamSx3('AA1_CODTEC')[1])
Local _cDataI     := ''
Local _cDataF     := ''
Local _cDataI2    := ''
Local _cDataF2    := ''
Local _cHoraI2    := ''
Local _cHoraF2    := ''
Local _dDtRef := CTOD('//')
Local _nPosABB    := 0
Local _cManut     := Space(TamSx3('ABB_MANUT')[1])
Local aEscala	  := {}	
Local aTabCalend  := {}
Local aTabPadrao  := {}		
Local cFilTFF	  := xFilial("TFF")

Local nI			:= 0
Local nZ			:= 0
Local nTotalDias 	:= 0
Local nTotEsc		:= 0

Default _dDtIni := CTOD('//')
Default _dDtFim := CTOD('//')

// Validacao dos Parametros

// Filial do Funcionario
If ! Empty(_cFunFil)
	_cFunFil := PadR(_cFunFil,TamSx3('AA1_FUNFIL')[1],' ')
EndIf

// Matricula do Funcionario
If Empty(_cMatFunc)
	lOk := .F.
Else
	_cMatFunc := PadR(_cMatFunc,TamSx3('AA1_CDFUNC')[1],' ')
EndIf

// Data Inicial
If lOk .AND. Empty(_dDtIni)
	lOk := .F.
Else
	_cDataI := DTOS(_dDtIni)
EndIf

// Data Final
If lOk .AND. Empty(_dDtFim)
	lOk := .F.
Else
	_cDataF := DTOS(_dDtFim)	
EndIf

// Valida o Periodo
If lOk .AND. _dDtIni > _dDtFim
	lOk := .F.
EndIf

// Funcionario
If lOk
	DbSelectArea("AA1")
	AA1->(DbSetOrder(7)) // AA1_FILIAL, AA1_CDFUNC, AA1_FUNFIL
	If AA1->(DbSeek(xFilial("AA1") + _cMatFunc + _cFunFil))
		If Empty(AA1->AA1_CODTEC)
			lOk := .F.
		Else
			//Verifica se o atendente está disponivel ou bloqueado
			If AA1->AA1_ALOCA == "1" .Or. RegistroOK("AA1")
				_cCodTec := AA1_CODTEC
			Else
				lOk := .F.
			EndIf	
		EndIf
	Else
		lOk := .F.
	EndIf
EndIf

//Descobrir a Escala e Calendario
If lOk
	aEscala := TxEscCalen(_cCodTec,_cDataI,_cDataF)
EndIf	
		   
//Realiza a projeção da agenda
If Len(aEscala) > 0
	nTotEsc := Len(aEscala)
	For nI := 1 to nTotEsc
		aSize(aTabCalend,0)
		aSize(aTabPadrao,0)
		
		TxProjEsc(aEscala[nI][1],aEscala[nI][4],If(dtos(aEscala[nI][5])<= _cDataI,stod(_cDataI),aEscala[nI][5]),If(dtos(aEscala[nI][6])>= _cDataF,stod(_cDataF),aEscala[nI][6]),aEscala[nI][2],aEscala[nI][3],@aTabPadrao,@aTabCalend)
		
		//Realiza a busca da agenda(ABB)
		_cAliasABB_ := TxBuscAgen(_cFunFil,_cMatFunc,_cCodTec,If(dtos(aEscala[nI][5])<= _cDataI,stod(_cDataI),aEscala[nI][5]),If(dtos(aEscala[nI][6])>= _cDataF,stod(_cDataF),aEscala[nI][6]))
		
		//Realiza a comparação da projeção com a agenda
		nZ := 1
		nTotalDias := Len(aTabCalend)
		While nZ <= nTotalDias
		
			If !(_cAliasABB_)->(Eof()) .And. aTabCalend[ nZ, CALEND_POS_DATA ] >= (_cAliasABB_)->TDV_DTREF

			// Repassa o periodo da alocacao
			_cDataI2 := (_cAliasABB_)->ABB_DTINI
			_cDataF2 := (_cAliasABB_)->ABB_DTFIM

			// Repassa o horario
			_cHoraI2 := (_cAliasABB_)->ABB_HRINI
			_cHoraF2 := (_cAliasABB_)->ABB_HRFIM			
			
			// Armazena um registro por data de referencia
				If _dDtRef <> (_cAliasABB_)->TDV_DTREF
					Aadd(aRetAloc,{	(_cAliasABB_)->TFF_FILIAL,;							// 01 - FILIAL
									(_cAliasABB_)->TDV_DTREF,;							// 02 - DATA REFERENCIA
									(_cAliasABB_)->ABB_DTINI,;							// 03 - DATA INICIAL
									(_cAliasABB_)->ABB_HRINI,;							// 04 - HORA INICIAL
									(_cAliasABB_)->ABB_DTFIM,;							// 05 - DATA FINAL
									(_cAliasABB_)->ABB_HRFIM,;							// 06 - HORA FINAL
									(_cAliasABB_)->ABB_LOCAL,;							// 07 - LOCAL
									(_cAliasABB_)->TDV_TURNO,;							// 08 - TURNO
									(_cAliasABB_)->TFF_CONTRT,;							// 09 - CONTRATO
									(_cAliasABB_)->ABS_CODIGO,;							// 10 - CLIENTE
									(_cAliasABB_)->ABS_LOJA,;							// 11 - LOJA
									IIF(!Empty((_cAliasABB_)->TDV_FERIAD),.T.,.F.),;	// 12 - FERIADO
									IIF((_cAliasABB_)->ABN_TIPO == "01",.T.,.F.),;	// 13 - FALTA
									.F.,;													// 14 - SUBSTITUTO
									(_cAliasABB_)->TFF_COD})								// 15 - CODIGO RH

				// Repassa a Data de Referencia
				_dDtRef := (_cAliasABB_)->TDV_DTREF
				
				// Repassa se a alocacao sofreu algum tipo de manutencao
				_cManut := (_cAliasABB_)->ABB_MANUT

				// Contabiliza o numero de registros
				_nPosABB := Len(aRetAloc)
			Else
				
				Do Case
					// Caso exista mais de uma sequencia no turno atualiza
					// a data e hora final
					Case _cManut == (_cAliasABB_)->ABB_MANUT
						aRetAloc[_nPosABB][05] := (_cAliasABB_)->ABB_DTFIM
						aRetAloc[_nPosABB][06] := (_cAliasABB_)->ABB_HRFIM

					// Caso exista mais de uma sequencia no turno
					// e exista falta considera somente a hora produtiva
					Case (_cManut <> (_cAliasABB_)->ABB_MANUT) .AND. aRetAloc[_nPosABB][13] .AND. (_cAliasABB_)->ABN_TIPO <> "01"
						aRetAloc[_nPosABB][03] := (_cAliasABB_)->ABB_DTINI
						aRetAloc[_nPosABB][04] := (_cAliasABB_)->ABB_HRINI					
					
					EndCase
				
			// Filtra as Manutencoes do Funcionario Substituto
			_cAliasABR_ := GetNextAlias()
			
			BeginSql Alias _cAliasABR_
		
				SELECT DISTINCT ABR_CODSUB
				     , ABR_AGENDA
				     , ABR_DTINI
				     , ABR_HRINI
				     , ABR_DTFIM
				     , ABR_HRFIM 
				  FROM %Table:ABR% ABR
				 WHERE ABR.ABR_FILIAL = %xFilial:ABR%
				   AND ABR.ABR_CODSUB = %Exp:_cCodTec%
				   AND ABR.ABR_DTINI = %Exp:_cDataI2%
				   AND ABR.ABR_DTFIM = %Exp:_cDataF2%
				   AND ABR.ABR_HRINI = %Exp:_cHoraI2%
				   AND ABR.ABR_HRFIM = %Exp:_cHoraF2%
				   AND ABR.%NotDel%	
			
			EndSql

			// Atualiza o parametro como substituto
			IF (_cAliasABR_)->(!Eof())
				aRetAloc[_nPosABB][14] := .T.
			ENDIF
			
			// Finaliza o Temporario da Manutencao
			DbSelectArea(_cAliasABR_)
			(_cAliasABR_)->(DbCloseArea())
						
			EndIf

			DbSelectArea(_cAliasABB_)
			(_cAliasABB_)->(DbSkip())

			// Passa para o próximo dia
			nZ += 2

			Else
				// Armazena um registro por data de referencia dentro da projeção
				If (_dDtRef <> (_cAliasABB_)->TDV_DTREF .Or. (_cAliasABB_)->(Eof())) .And. (aTabCalend[nZ][CALEND_POS_TIPO_MARC] == "1E" .And. aTabCalend[nZ][CALEND_POS_TIPO_DIA ] == "S")
					Aadd(aRetAloc,{	cFilTFF,;														// 01 - FILIAL
										aTabCalend[ nZ, CALEND_POS_DATA ],;							// 02 - DATA REFERENCIA
										aTabCalend[ nZ, CALEND_POS_DATA ],;							// 03 - DATA INICIAL
										IntToHora(aTabCalend[ nZ, CALEND_POS_HORA ]),;				// 04 - HORA INICIAL
										aTabCalend[ nZ, CALEND_POS_DATA ],;							// 05 - DATA FINAL
										IntToHora(aTabCalend[ nZ+1, CALEND_POS_HORA ]),;				// 06 - HORA FINAL
										aEscala[nI][7],;											// 07 - LOCAL
										aEscala[nI][2],;											// 08 - TURNO
										aEscala[nI][10],;											// 09 - CONTRATO
										aEscala[nI][8],;											// 10 - CLIENTE
										aEscala[nI][9],;											// 11 - LOJA
										aTabCalend[ nZ, CALEND_POS_FERIADO ],;						// 12 - FERIADO
										.F.,;														// 13 - FALTA
										.F.,;														// 14 - SUBSTITUTO
										aEscala[nI][11]})											// 15 - CODIGO RH
	
					// Repassa a Data de Referencia
					_dDtRef := aTabCalend[ nZ, CALEND_POS_DATA ]
	
					// Contabiliza o numero de registros
					_nPosABB := Len(aRetAloc)
				Else
					If "S" $ aTabCalend[nZ+1][CALEND_POS_TIPO_MARC] .And. aTabCalend[nZ+1][CALEND_POS_TIPO_DIA ] == "S"
						aRetAloc[_nPosABB][05] := aTabCalend[ nZ+1, CALEND_POS_DATA ]
						aRetAloc[_nPosABB][06] := IntToHora(aTabCalend[ nZ+1, CALEND_POS_HORA ])
					EndIf
				EndIf
				// Passa para o próximo dia
				nZ += 2
			EndIf
		
		End
		
	// Finaliza o temporário da alocação
	DbSelectArea(_cAliasABB_)
	(_cAliasABB_)->(DbCloseArea())
		
	Next nI
EndIf

RestArea(aAreaAloc)

RETURN aRetAloc 

//-------------------------------------------------------------------
/*/{Protheus.doc} TECFilSB1()
Construção da consulta especifica

@author Matheus Lando Raimundo
@since 12/01/2016
@version P12.1.7
@return Nil
/*/
//------------------------------------------------------------------
Function TECFilSB1(nAba)

Local lRet		:= .F.
Local oBrowse	:= Nil
Local cAls		:= GetNextAlias()
Local nSuperior	:= 0
Local nEsquerda	:= 0
Local nInferior	:= 0
Local nDireita	:= 0
Local oDlgEscTela	:= Nil
Local cQry		:= ""
Local cTabela	:= SubStr(ReadVar(),1,AT("_",ReadVar())-1)
Local aIndex:= {}
Local aSeek := {} 
Local oView := Nil 
Local lGSVinc := SuperGetMv("MV_GSVINC",,.F.) .AND. ExistFunc("At994RetVc") .AND. AliasInDic("TXA")
Local cCodProd := ""
Local oModel := NIL
Local cRetTXA := "0"
Local cTpIt := ""

Default nAba		:= 0


Aadd( aSeek, {"Código", {{"","C",TamSX3("B1_COD")[1],0,"Código",,}} } )	//"Código"
Aadd( aSeek, {"Descrição", {{"","C",TamSX3("B1_DESC")[1],0,"Descrição",,}}})

Aadd( aIndex, "B1_COD" )
Aadd( aIndex, "B1_DESC")
Aadd( aIndex, "B1_FILIAL")




 
If nAba == 0
	cTabela := Substr(cTabela,4,Len(cTabela))
Else
	If nAba == 1 // Aba RH
		cTabela := 'TFF'
	ElseIf nAba == 2 // Aba MC
		cTabela := 'TFH'
	ElseIf nAba == 3 // Aba MI
		cTabela := 'TFG' 
	ElseIf nAba == 4 // Aba LE
		cTabela := 'TFI'
	ElseIf nAba == 5
		cTabela := 'SB5'
	EndIf
Endif

//Tratativa para tela de Facilitador
If FunName() == "TECA984"
	If nAba == 0
		oView := FwViewActive()
		If oView:GetFolderActive("ABAS", 2)[1] == 1 // Aba RH
			cTabela := 'TFF'
		ElseIf oView:GetFolderActive("ABAS", 2)[1] == 2 // Aba MC
			cTabela := 'TFH'
		ElseIf oView:GetFolderActive("ABAS", 2)[1] == 3 // Aba MI
			cTabela := 'TFG'
		ElseIf oView:GetFolderActive("ABAS", 2)[1] == 4 // Aba LE
			cTabela := 'TFI'
		EndIf
	Else
		If nAba == 1 // Aba RH
			cTabela := 'TFF'
		ElseIf nAba == 2 // Aba MC
			cTabela := 'TFH'
		ElseIf nAba == 3 // Aba MI
			cTabela := 'TFG' 
		ElseIf nAba == 4 // Aba LE
			cTabela := 'TFI'
		EndIf
	Endif
ElseIf FunName() == "TECA994"
	If nAba == 0
		oView := FwViewActive()
		If cTabela = "ZXA"
			cTabela := 'TFF'
		ElseIf oView:GetFolderActive("ABAS", 2)[1] == 4 // Aba MC
			cTabela := 'TFH'
		ElseIf oView:GetFolderActive("ABAS", 2)[1] == 5 // Aba MI
			cTabela := 'TFG'

		EndIf
	EndIf
EndIf

If lGSVinc .AND. cTabela $ "TFG|TFH"
	oModel := FWModelActive() //Modelo Ativo
	If RTrim(oModel:GetId()) ==  "TECA740" .or. RTrim(oModel:GetId())  == "TECA740B" .OR. RTrim(oModel:GetId())  == "TECA740C"
		cCodProd := oModel:GetValue(IIF(RTrim(oModel:GetId()) ==  "TECA740", "TFF_RH", "TFF_GRID"),"TFF_PRODUT")
		//Verifica se existe um vinculo cadastrado para o Produto
		cTpIt := IIF( cTabela == 'TFG', _TPIP_MATIMPL, _TPIP_MATCONS)
	 	cRetTXA := At994RtPrd(cCodProd, cTpIt)
	 EndIf
EndIf

If cRetTXA <> "2"
	cQry := " SELECT "
	cQry += " B1_FILIAL, B1_COD, B1_DESC "
	cQry += " FROM " + RetSqlName("SB1") + " B1 "
	cQry += " INNER JOIN " + RetSqlName("SB5") + " B5 "
	cQry += " 		ON B1.B1_FILIAL = B5.B5_FILIAL "
	cQry += " 		AND B1.B1_COD = B5.B5_COD "
	cQry += " 		AND B1.D_E_L_E_T_ = '' "
	cQry += " 		AND B5.D_E_L_E_T_ = '' "
	cQry += " WHERE B1_FILIAL = '" +  xFilial('SB1') + "'"
Else
	cQry := " SELECT "
	cQry += " B1_FILIAL, B1_COD, B1_DESC "
	cQry += " FROM " + RetSqlName("SB1") + " B1 "
	cQry += " INNER JOIN " + RetSqlName("SB5") + " B5 "
	cQry += " 		ON B1.B1_FILIAL = B5.B5_FILIAL "
	cQry += " 		AND B1.B1_COD = B5.B5_COD "
	cQry += " 		AND B1.D_E_L_E_T_ = '' "
	cQry += " 		AND B5.D_E_L_E_T_ = '' "
	cQry += " INNER JOIN " + RetSqlName("TXA") + " TXA "
	cQry += " 		ON B1.B1_FILIAL = TXA.TXA_FILIAL "
	cQry += " 		AND B1.B1_COD = TXA.TXA_PRDMAT "
	cQry += " 		AND TXA.TXA_TPIT = '" + cTpIt + "' "	
	cQry += " 		AND TXA.TXA_PRODUT = '" + cCodProd + "' "
	cQry += " 		AND TXA.D_E_L_E_T_ = '' "
	cQry += " 		AND TXA.D_E_L_E_T_ = '' "	
	cQry += " WHERE B1_FILIAL = '" +  xFilial('SB1') + "'"
EndIf

If cTabela == 'TFF'
	cQry += " AND B5.B5_TPISERV = '4'"
ElseIf cTabela == 'TFG'
	cQry += " AND B5.B5_TPISERV <> '4'"
	//cQry += " AND B5.B5_TPISERV = '5'"
	cQry += " AND B5.B5_GSMI= '1' "
ElseIf cTabela == 'TFH'
	cQry += " AND B5.B5_TPISERV = '5'"
	cQry += " AND B5.B5_GSMC= '1' "
ElseIf cTabela == 'TFI'
	cQry += " AND B5.B5_TPISERV = '5'"
	cQry += " AND B5.B5_GSLE= '1' "
ElseIf cTabela == 'SB5'
	cQry += " AND B5.B5_TPISERV = '5'"
	cQry += " AND B5.B5_GSBE= '1' "	
EndIf

//-- Necessário utilizar FieldPos, pois o campo de bloqueio de registro é opcional para o cliente. 
If SB1->(FieldPos('B1_MSBLQL')) > 0
	cQry += " AND B1.B1_MSBLQL <> '1'"	
EndIf

If SB5->(FieldPos('B5_MSBLQL ')) > 0
	cQry += " AND B5.B5_MSBLQL <> '1'"	
EndIf

nSuperior := 0
nEsquerda := 0
nInferior := 460
nDireita  := 800
 
DEFINE MSDIALOG oDlgEscTela TITLE "Produtos" FROM nSuperior,nEsquerda TO nInferior,nDireita PIXEL
 
oBrowse := FWFormBrowse():New()
oBrowse:SetOwner(oDlgEscTela)
oBrowse:SetDataQuery(.T.)
oBrowse:SetAlias(cAls)
oBrowse:SetQueryIndex(aIndex)
oBrowse:SetQuery(cQry)
oBrowse:SetSeek(,aSeek)
oBrowse:SetDescription("Produtos")
oBrowse:SetMenuDef("")
oBrowse:DisableDetails()


oBrowse:SetDoubleClick({ || cRetProd := (oBrowse:Alias())->B1_COD, lRet := .T. ,oDlgEscTela:End()})
oBrowse:AddButton( OemTOAnsi("Confirmar"), {|| cRetProd   := (oBrowse:Alias())->B1_COD, lRet := .T., oDlgEscTela:End() } ,, 2 ) //"Confirmar"
oBrowse:AddButton( OemTOAnsi("Cancelar"),  {||  cRetProd  := "", oDlgEscTela:End() } ,, 2 ) //"Cancelar"
oBrowse:DisableDetails()
 
ADD COLUMN oColumn DATA { ||  B1_COD  } TITLE "Código" SIZE TamSX3("B1_COD")[1] OF oBrowse //"Código"
ADD COLUMN oColumn DATA { ||  B1_DESC } TITLE "Descrição" SIZE TamSX3("B1_DESC")[1] OF oBrowse //"Descrição"
            
oBrowse:Activate()
 
ACTIVATE MSDIALOG oDlgEscTela CENTERED
     	
Return( lRet )

//-------------------------------------------------------------------
/*/{Protheus.doc} TECRetProd()
Retorno da consulta especifica

@author Matheus Lando Raimundo
@since 12/01/2016
@version P12.1.7
@return Nil
/*/
//------------------------------------------------------------------
Function TECRetProd()

Return cRetProd

/*/{Protheus.doc} AtIsPrdLoc
	Verifica se um produto corresponde a um item de locação e está ativo

@since		22/04/2015   

@sample 	AtIsPrdLoc(_cFunFil, _cMatFunc, _dDtIni, _dDtFim)
@param 		cExp1, Char, Código do produto que deseja verificar
@return	ExpA	Array dos dados de Alocacao

/*/
Function AtIsPrdLoc( cCodPrd, cFilSB5 )

Local lRet := .F.
Local aArea := GetArea()
Local aAreaSB5 := {}

Default cFilSB5 := xFilial("SB5")

DbSelectArea("SB5")
SB5->( DbSetOrder( 1 ) ) // B5_FILIAL+B5_COD

If !Empty(cCodPrd) .And. SB5->( DbSeek( cFilSB5+cCodPrd ) )
	lRet := ( SB5->B5_TPISERV == "5" .And. SB5->B5_GSLE == "1" )
EndIf

RestArea( aArea )

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} AtShowLog
Exibe log de processamento na tela
@param cMemoLog, caracter: (LOG a ser exibido)
@param cTitle, caracter: Título da tela de LOG de processamento
@param lVScroll, lógico: habilita ou não a barra de scroll vertical
@param lHScroll, lógico: habilita ou não a barra de scroll horizontal
@param lWrdWrap, lógico: habilita a quebra de linha automática ou não, obedecendo ao tamanho da caixa de texto do log
@return lRet, Indica confirmação ou cancelamento
@author 	Alexandre da Costa
@since 24/09/2015
@version 1.0
/*/
//------------------------------------------------------------------------------
Function AtShowLog(cMemoLog,cTitle,lVScroll,lHScroll,lWrdWrap,lCancel)
Local lRet			:=	.F.
Local oFont		:=	TFont():New("Courier New",07,15)
Local oMemo 	:= Nil
Local oDlgEsc 		:= Nil
Default cMemoLog	:=	""
Default cTitle	:=	""
Default lVScroll	:=	.T.
Default lHScroll	:=	.F.
Default lWrdWrap	:=	.T.
Default lCancel		:=  .T.

If	!Empty(cMemoLog)
	Define Dialog oDlgEsc Title AllTrim(STR0056+" "+AllTrim(cTitle)) From 0,0 to 425, 600 Pixel
	@ 000, 000 MsPanel oTop Of oDlgEsc Size 000,250	// Coordenada para o panel
	oTop:Align := CONTROL_ALIGN_TOP //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
	@ 005,005 Get oMemo Var cMemoLog Memo FONT oFont Size 292,186 READONLY Of oTop Pixel
	oMemo:EnableVScroll(lVScroll)
	oMemo:EnableHScroll(lHScroll)
	oMemo:lWordWrap := lWrdWrap
	oMemo:bRClicked := {|| AllwaysTrue()}
	Define SButton From 196, 270 Type  1 Action (lRet := .T., oDlgEsc:End()) Enable Of oTop Pixel // OK

	If lCancel
		Define SButton From 196, 240 Type  2 Action (lRet := .F., oDlgEsc:End()) Enable Of oTop Pixel // Cancelar
	Endif
	
	Activate Dialog oDlgEsc Centered

EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} TxCarac
Função que retorna as regioes de atendimento do atendentes.

@sample	TxCarac(cCodAtend)

@param	ExpC1	Codigo do atendente.
			
@return	ExpA	Caracteristica do Atendimento.

@author		Anderson Silva	
@since		13/11/2012
@version	P12
/*/
//------------------------------------------------------------------------------
Function TxCarac(cCodAtend)

Local aCarac	 := {}
Local nLinha 	 := 0
Local cDescCar 	 := ""
	
DbSelectArea("AA1")
DbSetOrder(1) // AA1_FILIAL+AA1_CODTEC

If AA1->(DbSeek(xFilial("AA1")+cCodAtend))

	DbSelectArea("TDU")
	DbSetOrder(2) //  TDU_FILIAL+TDU_CODTEC+TDU_CODTCZ
	
	If TDU->(DbSeek(xFilial("TDU")+cCodAtend)) 	
		If Len(aCarac) == 0
			aAdd(aCarac,{cCodAtend})
		EndIf	
		
		While ( TDU->(!Eof()) .AND. TDU->TDU_FILIAL == xFilial("TDU") .AND. TDU->TDU_CODTEC == cCodAtend )		
			cDescCar :=	Posicione("TCZ",1,xFilial("TCZ")+TDU->TDU_CODTCZ,"TCZ_DESC")
			cDescCar := Capital(Alltrim(cDescCar))
			nLinha := Len(aCarac)
			aAdd(aCarac[nLinha],{TDU->TDU_CODTCZ,cDescCar})
		
			TDU->(DbSkip())
		End		
	EndIf
Endif
		
Return( aCarac )

//------------------------------------------------------------------------------
/*/{Protheus.doc} TxCurso
Função que retorna os Cursos do Funcionário.

@sample	TxCurso(cCodAtend)

@param	ExpC1	Codigo do atendente.
			
@return	ExpA	Curso do Funcionario.

@author		Anderson Silva	
@since		13/11/2012
@version	P12
/*/
//------------------------------------------------------------------------------
Function TxCurso(cCodAtend)

Local aCurso	 := {}
Local nLinha 	 := 0
Local cDescCur 	 := ""

DbSelectArea("AA1")
DbSetOrder(1)

If AA1->(DbSeek(xFilial("AA1")+cCodAtend))

	DbSelectArea("RA4")
	DbSetOrder(1) //RA4_FILIAL, RA4_MAT, RA4_CURSO
	
	If RA4->(DbSeek(xFilial("RA4")+AA1->AA1_CDFUNC)) 	
		If Len(aCurso) == 0
			aAdd(aCurso,{cCodAtend})
		EndIf	
		
		While ( RA4->(!Eof()) .AND. RA4->RA4_FILIAL == xFilial("RA4") .AND. RA4->RA4_MAT == AA1->AA1_CDFUNC )		
			cDescCur :=	Posicione("RA1",1,xFilial("RA1")+RA4->RA4_CURSO,"RA1_DESC")
			cDescCur := Capital(Alltrim(cDescCur))
			nLinha := Len(aCurso)
			aAdd(aCurso[nLinha],{RA4->RA4_CURSO,cDescCur})
		
			RA4->(DbSkip())
		End		
	EndIf
Endif

		
Return( aCurso )

//------------------------------------------------------------------------------
/*/{Protheus.doc} TxRestri(cLocAloc)
Função que retorna as restrições dos atendentes.

@sample	TxRestri(cLocAloc)

@param	ExpC1 Local de Atendimento	
			
@return	ExpA	 Array Restrições.

@author	services	
@since		15/10/2015
@version	P12
/*/
//------------------------------------------------------------------------------
Function TxRestri(cLocalAloc)

Local aRestri:={}
Local tmpRestri:=""
Local tmpResCli:=""

//query com as restricoes do local de atendimento
If !Empty(cLocalAloc)
	tmpRestri:= GetNextAlias()
	BeginSql Alias tmpRestri
		Select TW2_CODTEC, TW2_CLIENT, TW2_LOJA, TW2_LOCAL, TW2_TEMPO, TW2_DTINI, TW2_DTFIM, TW2_RESTRI
		From %table:TW2% TW2
		left join %table:ABS% ABS on ABS_FILIAL = %xFilial:ABS% 
			AND ABS_LOCAL = TW2_LOCAL
		WHERE	TW2_FILIAL = %xFilial:TW2%
		AND TW2_LOCAL = %Exp:cLocalAloc% 
		AND TW2.%NotDel%
	EndSql
	
	//adiciona numa matriz
	DbSelectArea(tmpRestri)
	(tmpRestri)->(DbGoTop())
	While (tmpRestri)->(! Eof())
	
		AADD(aRestri,{(tmpRestri)->TW2_CODTEC,;
					  (tmpRestri)->TW2_CLIENT,;
					  (tmpRestri)->TW2_LOJA,;
					  (tmpRestri)->TW2_LOCAL,;
					  (tmpRestri)->TW2_TEMPO,;
					  (tmpRestri)->TW2_DTINI,;
					  (tmpRestri)->TW2_DTFIM,;
					  (tmpRestri)->TW2_RESTRI,;	
					})
		
	(tmpRestri)->(DbSkip())
	
	Enddo

	//verificar restrição no cliente
	
	//cliente do local de atendimento
	cCliente:= Posicione("ABS",1,xFilial("ABS")+cLocalAloc,"ABS_CODIGO")
	cLojaCli:= Posicione("ABS",1,xFilial("ABS")+cLocalAloc,"ABS_LOJA")
			
	tmpResCli:= GetNextAlias()
	BeginSql Alias tmpResCli
		Select TW2_CODTEC, TW2_CLIENT, TW2_LOJA, TW2_LOCAL, TW2_TEMPO, TW2_DTINI, TW2_DTFIM, TW2_RESTRI
		From %table:TW2% TW2
		left join %table:ABS% ABS on ABS_FILIAL = %xFilial:ABS% 
			AND ABS_LOCAL = TW2_LOCAL
		WHERE	TW2_FILIAL = %xFilial:TW2%
		AND TW2_CLIENT = %Exp:cCliente%
		AND TW2_LOJA = %Exp:cLojaCli%
		AND TW2.%NotDel%
	EndSql
			
	DbSelectArea(tmpResCli)
	(tmpResCli)->(DbGoTop())
		While (tmpResCli)->(! Eof())
			//verificar se ja existe o atendente e nao adicionar novamente
			If ! aScan(aRestri,{|x| x[1] == (tmpResCli)->TW2_CODTEC})
				AADD(aRestri,{(tmpResCli)->TW2_CODTEC,;
						  (tmpResCli)->TW2_CLIENT,;
						  (tmpResCli)->TW2_LOJA,;
						  (tmpResCli)->TW2_LOCAL,;
						  (tmpResCli)->TW2_TEMPO,;
						  (tmpResCli)->TW2_DTINI,;
						  (tmpResCli)->TW2_DTFIM,;
						  (tmpResCli)->TW2_RESTRI,;	
							})
			Endif
			(tmpResCli)->(DbSkip())
		Enddo

//Fecha a area das tabelas
(tmpResCli)->(DbCloseArea())
(tmpRestri)->(DbCloseArea())

Endif

Return( aRestri )

//-------------------------------------------------------------------
/*/{Protheus.doc} At820PrdF3()
Construção da consulta especifica

@author Filipe Gonçalves Rodrigues
@since 07/07/2016
@version P12.1.14
@return Nil
/*/
//------------------------------------------------------------------
Function At820PrdF3()
Local lRet		:= .F.
Local oBrowse	:= Nil
Local cAls		:= GetNextAlias()
Local nSuperior	:= 0
Local nEsquerda	:= 0
Local nInferior	:= 0
Local nDireita	:= 0
Local oDlgEscTela	:= Nil
Local cQry		:= ""
Local cTabela	:= SubStr(ReadVar(),1,AT("_",ReadVar())-1)
Local aIndex	:= {"B1_COD","B1_FILIAL"}
Local aSeek		:= {{STR0057, {{STR0058,"C",TamSX3("B1_COD")[1],0,"",,}} }}	//"Produtos" # "Produto"
Local oModel	:= Nil 
Local cFil 		:= ""

cTabela := Substr(cTabela,4,Len(cTabela))

cQry := " SELECT "
cQry += " B1_FILIAL, B1_COD, B1_DESC "
cQry += " FROM " + RetSqlName("SB1") + " B1 "
cQry += " INNER JOIN " + RetSqlName("SB5") + " B5 "
cQry += " 		ON B1.B1_FILIAL = B5.B5_FILIAL "
cQry += " 		AND B1.B1_COD = B5.B5_COD "
cQry += " 		AND B1.D_E_L_E_T_ = '' "
cQry += " 		AND B5.D_E_L_E_T_ = '' "
cQry += " AND B5.B5_TPISERV = '5'"
cQry += " AND B5.B5_GSLE= '1' "

//Tratativa para tela de Facilitador
If FunName() == "TECA001"
	oModel := FwModelActive()
	cFil := oModel:GetValue("GRIDDETAIL","TWS_FILPRD")
	cQry += " AND B1_FILIAL = '" +  cFil + "'"+   CRLF
EndIf

//-- Necessário utilizar FieldPos, pois o campo de bloqueio de registro é opcional para o cliente. 
If SB1->(FieldPos('B1_MSBLQL')) > 0
	cQry += " AND B1.B1_MSBLQL <> '1'"	
EndIf

If SB5->(FieldPos('B5_MSBLQL ')) > 0
	cQry += " AND B5.B5_MSBLQL <> '1'"	
EndIf

nSuperior := 0
nEsquerda := 0
nInferior := 460
nDireita  := 800
 
DEFINE MSDIALOG oDlgEscTela TITLE STR0059 FROM nSuperior,nEsquerda TO nInferior,nDireita PIXEL	//"Produtos"
 
oBrowse := FWFormBrowse():New()
oBrowse:SetDescription(STR0060)	//"Produtos" 
oBrowse:SetAlias(cAls)
oBrowse:SetDataQuery()
oBrowse:SetQuery(cQry)
oBrowse:SetOwner(oDlgEscTela)
oBrowse:SetDoubleClick({ || cRetProd := (oBrowse:Alias())->B1_COD, lRet := .T. ,oDlgEscTela:End()})
oBrowse:AddButton( OemTOAnsi(STR0061), {|| cRetProd  := (oBrowse:Alias())->B1_COD, lRet := .T., oDlgEscTela:End() } ,, 2 ) //"Confirmar"
oBrowse:AddButton( OemTOAnsi(STR0062), {|| cRetProd  := "", oDlgEscTela:End() } ,, 2 ) //"Cancelar"
oBrowse:DisableDetails()
oBrowse:SetQueryIndex(aIndex)
oBrowse:SetSeek({||.T.},aSeek)
 
ADD COLUMN oColumn DATA {|| B1_COD}  TITLE STR0063 SIZE TamSX3("B1_COD")[1] OF oBrowse //"Código"
ADD COLUMN oColumn DATA {|| B1_DESC} TITLE STR0064 SIZE TamSX3("B1_DESC")[1] OF oBrowse //"Descrição"
            
oBrowse:Activate()
 
ACTIVATE MSDIALOG oDlgEscTela CENTERED
     	
Return( lRet )

//-------------------------------------------------------------------
/*/{Protheus.doc} At820PrdRt()
Retorno da consulta especifica

@author Matheus Lando Raimundo
@since 12/01/2016
@version P12.1.7
@return Nil
/*/
//------------------------------------------------------------------
Function At820PrdRt()

Return cRetProd

//------------------------------------------------------------------------------
/*/{Protheus.doc} AtChkHasKey
  Pesquisa se um determinado valor chave existe em uma tabela, não considera a filial corrente 
como a ExistCpo faz
@since  04/08/2016       
@version P12
@author  Inovação - Gestão de Serviços
@param   cTab, Caracter, define qual a tabela terá o conteúdo pesquisado
@param   nInd, Numérico, Default = 1, determina qual deve ser utilizado na tabela a ter o conteúdo pesquisado
@param   cChave, Caracter, conteúdo a ser verificado
@param   lHelp, Lógico, Default = .T., indica se deve ser exibido ou não help
@return  Lógico, determina de conseguiu encontrar o registro (.T.) ou não (.F.).
/*/
//------------------------------------------------------------------------------
Function AtChkHasKey( cTab, nInd, cChave, lHelp )
	
Local lRet := .F.
Local aArea := {}
Local aAreacTab := {}

Default nInd := 1
Default lHelp := .T.

If !Empty(cTab) .And. !Empty(cChave)
	
	aArea := GetArea()
	aAreacTab := (cTab)->(GetArea())
	
	DbSelectArea(cTab)
	(cTab)->(DbSetOrder(nInd))
	
	lRet := ( (cTab)->(DbSeek( cChave ) ) )
	
	If lHelp .And. !lRet
		Help(,,'REGNOIS')
	EndIf
	
	RestArea( aAreacTab )
	RestArea(aArea)
	
EndIf
	
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At740F3Tur()
Construção da consulta especifica

@author Filipe Gonçalves Rodrigues
@since 07/07/2016
@version P12.1.14
@return Nil
/*/
//------------------------------------------------------------------
Function At740F3Tur()
Local lRet			:= .F.
Local oBrowse		:= Nil
Local cAls			:= GetNextAlias()
Local nSuperior	:= 0
Local nEsquerda	:= 0
Local nInferior	:= 0
Local nDireita	:= 0
Local oDlgTela	:= Nil
Local cQry			:= ""
Local _cRdVar		:= ReadVar()
Local cTabela		:= SubStr(_cRdVar,1,AT("_",_cRdVar)-1)
Local aIndex		:= {}
Local aSeek		:= {}
Local oModel		:= Nil 
Local cFil 		:= ""
Local lGSVinc 	:= SuperGetMv("MV_GSVINC",,.F.) .AND. ExistFunc("At994RetVc") .AND. AliasInDic("TXA")
Local cCodProd 	:= ""
Local aAreaTXA 	:= {}
Local cRetTXA 	:= "0" //Retorno dos valores da TXA

Aadd( aSeek, { STR0063, {{"","C",TamSX3("R6_TURNO")[1],0,STR0063,,}} } ) // "Código" ### "Código"
Aadd( aSeek, { STR0066, {{"","C",TamSX3("R6_DESC")[1],0,STR0066,,}}}) // "Turnos" ### "Turnos"

Aadd( aIndex, "R6_TURNO" )
Aadd( aIndex, "R6_DESC")

If lGSVinc

	oModel := FWModelActive() //Modelo Ativo
	If oModel:GetId() == "TECA740" .or. oModel:GetId() == "TECA740A"
		cCodProd := oModel:GetValue("TFF_RH","TFF_PRODUT")
	//Verifica se existe um vinculo cadastrado para o Produto
	 	//cRetTXA := At994RetVc(cCodProd, _TPIP_TURNO)
	 	cRetTXA := At994RtPrd(cCodProd, _TPIP_TURNO)
	 EndIf
EndIf


	cTabela := Substr(cTabela,4,Len(cTabela))
	
If cRetTXA <> "2"	
	cQry := "SELECT SR6.R6_FILIAL, SR6.R6_TURNO, SR6.R6_DESC"
	cQry += " FROM " + RetSqlName("SR6") + " SR6 "
	cQry += " WHERE R6_FILIAL = '"+xFilial("SR6")+"' AND SR6.D_E_L_E_T_ = '' "
Else
	cQry := "SELECT SR6.R6_FILIAL, SR6.R6_TURNO, SR6.R6_DESC"
	cQry += " FROM " + RetSqlName("SR6") + " SR6, " 
	cQry += " " + RetSqlName("TXA") + " TXA "
	cQry += " WHERE  SR6.R6_TURNO = TXA.TXA_TURNO "
	cQry += " AND  SR6.R6_FILIAL = '"+xFilial("SR6")+"' AND SR6.D_E_L_E_T_ = '' "
	cQry += " AND TXA_PRODUT = '"+cCodProd+"' AND TXA.TXA_TPIT  = '"+ _TPIP_TURNO + "' "
	cQry += " AND TXA_FILIAL = '"+xFilial("TXA")+"' AND TXA.D_E_L_E_T_ = '' "
EndIf

nSuperior := 0
nEsquerda := 0
nInferior := 460
nDireita  := 800
 
DEFINE MSDIALOG oDlgTela TITLE STR0067 FROM nSuperior,nEsquerda TO nInferior,nDireita PIXEL	//"Turnos"
          
oBrowse := FWFormBrowse():New() 
oBrowse:SetOwner(oDlgTela)
oBrowse:SetDataQuery(.T.)
oBrowse:SetAlias(cAls)
oBrowse:SetQueryIndex(aIndex)
oBrowse:SetQuery(cQry)
oBrowse:SetSeek(,aSeek)
oBrowse:SetDescription(STR0068)  //"Turnos"
oBrowse:SetMenuDef("")
oBrowse:DisableDetails()

oBrowse:SetDoubleClick({ || cRetProd := (oBrowse:Alias())->R6_TURNO, lRet := .T. ,oDlgTela:End()})
oBrowse:AddButton( OemTOAnsi(STR0061), {|| cRetProd := (oBrowse:Alias())->R6_TURNO, lRet := .T., oDlgTela:End() } ,, 2 ) //"Confirmar"
oBrowse:AddButton( OemTOAnsi(STR0062), {|| cRetProd := "", oDlgTela:End() } ,, 2 ) //"Cancelar"
oBrowse:DisableDetails()

ADD COLUMN oColumn DATA {|| R6_TURNO} TITLE STR0069 SIZE TamSX3("R6_TURNO")[1] OF oBrowse //"Turno"
ADD COLUMN oColumn DATA {|| R6_DESC}  TITLE STR0070 SIZE TamSX3("R6_DESC")[1] OF oBrowse //"Descrição"

oBrowse:Activate()
 
ACTIVATE MSDIALOG oDlgTela CENTERED
     	
Return( lRet )

//-------------------------------------------------------------------
/*/{Protheus.doc} At740turRt()
Retorno da consulta especifica

@author Filipe Gonçalves Rodrigues
@since 07/07/2016
@version P12.1.7
@return Nil
/*/
//------------------------------------------------------------------
Function At740turRt()

Return cRetProd

//------------------------------------------------------------------------------
/*/{Protheus.doc} AtPosAA3
  Verifica a existência e posiciona na base de atendimento considerando a combinação de FIlial de Origem + Numero de Série 
@since		12/08/2016       
@version	P12
@author 	Inovação - Gestão de Serviços
@param 		cFilOri_NS, Caracter, define qual a tabela a chave a ser pesquisada considerando a concatenação dos campos AA3_FILORI+AA3_NUMSER
@param 		cProdFiltro, Caracter, define o produto da base de atendimento a ser pesquisada
@return 	Lógico, determina de conseguiu encontrar o registro (.T.) ou não (.F.).
/*/
Function AtPosAA3( cFilOri_NS, cProdFiltro )

Local lFound := .F.
Local cTmpAlias := GetNextAlias()
Local cFiltroQry := "%%"

//  não foi adicionado default pois este parâmetro passa a ser obrigatório para a identificação
// correta da base de atendimento 
If !Empty(cProdFiltro)
	cFiltroQry := "% AND AA3_CODPRO = '"+cProdFiltro+"'%"
EndIf

BeginSQL Alias cTmpAlias
	SELECT AA3.R_E_C_N_O_ AA3RECNO
	FROM %Table:AA3% AA3
	WHERE AA3.%NotDel%
		AND ( AA3_FILORI || AA3_NUMSER ) = ( %Exp:cFilOri_NS% )
		%Exp:cFiltroQry%
EndSql

If (cTmpAlias)->(!EOF())
	AA3->( DbGoTo( (cTmpAlias)->AA3RECNO ) )
	lFound := .T.
EndIf
(cTmpAlias)->( DbCloseArea() )

Return lFound

//------------------------------------------------------------------------------
/*/{Protheus.doc} AtTamFilTab
  Identifica a quantidade de caracteres do campo filial considerando o nível de compartilhamento das tabelas 
@since		17/08/2016
@version	P12
@author 	Inovação - Gestão de Serviços
@param 		cTab, Caracter, define qual a tabela deverá ter nível de compartilhamento considerado
@return 	Numérico, retorna a quantidade de caracteres considerando o nível de compartilhamento da tabela
/*/
//------------------------------------------------------------------------------
Function AtTamFilTab( cTab )
Local nTamNvlEmp := 0
Local nTamNvlUni := 0
Local nTamNvlFil := 0
Local nTamFilTot := 0
Local nTamFilTab := 0

If ( nTamNvlFil := Len( FWSM0Layout(cEmpAnt,3) ) ) > 0
	nTamNvlUni := Len( FWSM0Layout(cEmpAnt,2) )
	nTamNvlEmp := Len( FWSM0Layout(cEmpAnt,1) )
	nTamFilTot := ( nTamNvlEmp + nTamNvlUni + nTamNvlFil )
ElseIf !Empty( SM0->M0_LEIAUTE )
	nTamNvlEmp := AtCharCount( SM0->M0_LEIAUTE, "E" )
	nTamNvlUni := AtCharCount( SM0->M0_LEIAUTE, "U" )
	nTamNvlFil := AtCharCount( SM0->M0_LEIAUTE, "F" )
EndIf

nTamFilTab := If( FWModeAccess(cTab,3) == "E", nTamFilTot, If( FWModeAccess(cTab,2) == "E", nTamNvlEmp + nTamNvlUni, If( FWModeAccess(cTab,1) == "E", nTamNvlEmp, 0 ) ) )

Return nTamFilTab

//------------------------------------------------------------------------------
/*/{Protheus.doc} GSEscolha
Exibe uma interface grafica para que o usuario escolha 1 opcao entre varias 
@since		29/09/2016
@version	P12
@author 	Cesar A. Bianchi
@param 		aPergs, nDefault
@return 	nRet - Numero da opção escolhida dentro do parametro aPergs
/*/
//------------------------------------------------------------------------------
Function GSEscolha(cTitle,cMsg,aPergs,nDefault)
	Local nRet := 1
	Local oDlgEsc := Nil
	Local oSayMain:= Nil
	Local oBoxOpc	:= Nil
	Local oRadM	:= Nil
	Local nRadio 	:= 0
	Local nAlt		:= 0
	Local nLarg	:= 0
	Local nFatAlt := 20
	Local bOk		:= Nil
	Local bCancel := Nil
	Local aEnchBt := {}
	Local lOk		:= .F.

	Default aPergs := {}
	Default nDefault := 1
	Default cTitle := "Titulo não definido"
	Default cMsg	 := "Mensagem não definida"	


	If len(aPergs) > 1
		//1* - Seta a escolha Default
		nRet := nDefault
		nRadio := nDefault
		
		//2* - Define a largura e a altura da tela
		nAlt := 200 + (nFatAlt * len(aPergs))
		nLarg := 400
		
		//3* - Define as acoes do botao Ok e Cancel
		bOk := {|| lOk := .T., oDlgEsc:End()}
		bCancel := {|| lOk := .F., oDlgEsc:End()}
				
		//"Pinta" a Dialog
		oDlgEsc:= MSDIALOG():Create()
		oDlgEsc:cName     := "oDlgEsc"
		oDlgEsc:cCaption  := cTitle 
		oDlgEsc:nLeft     := 0
		oDlgEsc:nTop      := 10
		oDlgEsc:nWidth    := nLarg
		oDlgEsc:nHeight   := nAlt
		oDlgEsc:lShowHint := .F.
		oDlgEsc:lCentered := .T.
		oDlgEsc:bInit := EnchoiceBar(oDlgEsc,bOk,bCancel,,aEnchBt)
		
		//"Pinta" a Mensagem de alerta ao usuario
		oSayMain:= TSAY():Create(oDlgEsc)
		oSayMain:cName			:= "oSayMain"
		oSayMain:cCaption 		:= cMsg
		oSayMain:nLeft 			:= 30
		oSayMain:nTop 			:= 80
		oSayMain:nWidth 	   		:= oDlgEsc:nWidth - 30 - 30
		oSayMain:nHeight 			:= 40
		oSayMain:lShowHint 		:= .F.
		oSayMain:lReadOnly 		:= .F.
		oSayMain:Align 			:= 0
		oSayMain:lVisibleControl	:= .T.
		oSayMain:lWordWrap 	  	:= .T.
		oSayMain:lTransparent 	:= .F.
			
		//"Pinta" o Box das opções
		oBoxOpc:= TGROUP():Create(oDlgEsc)
		oBoxOpc:cName 	   := "oBoxOpc"
		oBoxOpc:cCaption    := ""
		oBoxOpc:nLeft 	   := 30
		oBoxOpc:nTop  	   := 130
		oBoxOpc:nWidth 	   := oDlgEsc:nWidth - 30 - 30
		oBoxOpc:nHeight 	   := oDlgEsc:nHeight - 130 - 40
		
		//"Pinta" as opções disponiveis no array aPergs
		oRadM:= TRadMenu():Create(oDlgEsc)
		oRadM:bSetGet := {|u|Iif (PCount()==0,nRadio,nRadio:=u)}	 
		oRadM:nTop := oBoxOpc:nTop + 20
		oRadM:nLeft := oBoxOpc:nLeft + 20
		oRadM:nWidth := oBoxOpc:nWidth - 40
		oRadM:nHeight := oBoxOpc:nHeight - 40
		oRadM:aItems := aPergs
		oRadM:cMsg := "Teste cMsg Property" 
		
		
		//Exibe a Dialog		
		oDlgEsc:Activate()
		
		//Define o retorno a partir da escolha feita pelo usuario
		If lOk 
			nRet := nRadio
		Else
			nRet := 0
		EndIf
		
		//Destroi os objetos da memoria
		TecDestroy(oDlgEsc)
		TecDestroy(oSayMain)
		TecDestroy(oBoxOpc)
		TecDestroy(oRadM)
	Else
		nRet := 0
	EndIf
	
Return nRet

//-------------------------------------------------------------------
/*/{Protheus.doc} AtABBNumCd()
Validação da numeração do codigo da agenda(ABB_CODIGO)

@author Serviços
@since 28/09/2016
@version P12.1.7
@return cNumCod - Numero do codigo da agenda
/*/
//------------------------------------------------------------------
Function AtABBNumCd()

Local aArea		:= GetArea()
Local aAreaABB	:= ABB->(GetArea())
Local cNumCod   := ""

cNumCod:= GetSXENum("ABB","ABB_CODIGO")
nSaveSX8  := 1

dbSelectArea("ABB")
dbSetOrder(8)
dbGoTop()

While ABB->( MsSeek(xFilial("ABB")+cNumCod) )
	If ( __lSx8 )
		ConfirmSX8()
	EndIf
	cNumCod:= GetSXENum("ABB","ABB_CODIGO")
EndDo

RestArea(aAreaABB)
RestArea(aArea)

Return( cNumCod )

//------------------------------------------------------------------------------
/*/{Protheus.doc} AtCharCount
  Conta a quantidade de caracteres em uma determinada string 
@since		25/10/2016
@version	P12
@author 	Inovação - Gestão de Serviços
@param 		cStrAval, Caracter, define qual a cadeia de caracteres será avaliada
@param 		cCharAlvo, Caracter, define qual o caracter deverá ter a
@return 	Numérico, quantidade de vezes que o caracter se repete na string
/*/
//------------------------------------------------------------------------------
Function AtCharCount( cStrAval, cCharAlvo )

Local nCount := 0
Local nPosNew := 0
Local nDifChar := Len(cCharAlvo)

While ( nPosNew := At( cCharAlvo, cStrAval ) ) > 0
	nCount++
	cStrAval := SubStr( cStrAval, nPosNew+nDifChar )
EndDo

Return nCount

//------------------------------------------------------------------------------
/*/{Protheus.doc} TxEscCalen
  Função para descobrir a escala e calendario do atendente dentro de um periodo
@since		31/05/2017
@version	P12.1.17
@author 	Inovação - Gestão de Serviços

@param		ExpC1	Filial do Funcionario
@param		ExpC2	Matricula do Funcionario
@param		ExpD3	Data Inicial da Alocacao
@param		ExpD4	Data Final da Alocacao

@return 	aEscala[1][1] - Codigo da Escala
			aEscala[1][2] - turno da escala
			aEscala[1][3] - Sequencia do Turno da escala
			aEscala[1][4] - Calendario da Escala(TFF)
			aEscala[1][5] - Data inicial da escala
			aEscala[1][6] - Data Final da escala
			aEscala[1][7] - Local de Atendimento
			aEscala[1][8] - Codigo do cliente 
			aEscala[1][9] - Loja do Clientte
			aEscala[1][10] - Numero do Contrato
			aEscala[1][11] - Codigo da TFF
/*/
//-----------------------------------------------------------------------------
Function TxEscCalen(_cCodTec,_cDataI,_cDataF)
Local aEscala	:= {}
Local cAliasTmp := GetNextAlias()

BeginSql Alias cAliasTmp

	COLUMN TGY_DTINI AS DATE
	COLUMN TGY_DTFIM AS DATE

	SELECT 	TGY.TGY_ESCALA,
		   	TGY.TGY_ATEND,
	      	TGY_DTINI,
	       	TGY_DTFIM,
			TGY.TGY_CODTFF,
			TDX.TDX_TURNO,
        	TDX.TDX_SEQTUR,
			TFF.TFF_FILIAL,
			TFF.TFF_COD,
			TFF.TFF_ESCALA,
			TFF.TFF_CALEND,
			TFF.TFF_CONTRT,
			TFF.TFF_LOCAL,
			ABS.ABS_CODIGO,
			ABS.ABS_LOJA
			
	FROM %Table:TGY% TGY
	
	JOIN %Table:TDX% TDX ON TDX_FILIAL = %xFilial:TDX%
						AND TDX_COD = TGY_CODTDX
						AND TDX.%NotDel%
		
	JOIN %Table:TFF% TFF ON TFF_FILIAL = %xFilial:TFF%
						AND TFF_FILIAL = TGY_FILIAL
						AND TFF_COD = TGY_CODTFF
						AND TFF.%NotDel%
	
	JOIN %Table:ABS% ABS ON ABS_FILIAL = %xFilial:ABS%
			   AND TFF_LOCAL = ABS_LOCAL
			   AND ABS.%NotDel%
	
	WHERE TGY_FILIAL = %xFilial:TGY%
			AND TGY.TGY_ATEND = %Exp:_cCodTec%
			AND NOT (TGY.TGY_DTINI > %Exp:_cDataF% OR TGY.TGY_DTFIM < %Exp:_cDataI%)
			AND TGY.%NotDel%
	
	ORDER BY TGY.TGY_DTINI, TGY.TGY_DTFIM

EndSql

While (cAliasTmp)->(!Eof())

	AAdd( aEscala, {(cAliasTmp)->TFF_ESCALA,(cAliasTmp)->TDX_TURNO,;
		 (cAliasTmp)->TDX_SEQTUR, (cAliasTmp)->TFF_CALEND,;
		  (cAliasTmp)->TGY_DTINI,(cAliasTmp)->TGY_DTFIM,;
		   (cAliasTmp)->TFF_LOCAL,(cAliasTmp)->ABS_CODIGO,;
		   (cAliasTmp)->ABS_LOJA,(cAliasTmp)->TFF_CONTRT,;
		   (cAliasTmp)->TFF_COD}) 
	
	(cAliasTmp)->(DbSkip())	
		   
EndDo

(cAliasTmp)->(DbCloseArea())

Return aEscala

//------------------------------------------------------------------------------
/*/{Protheus.doc} TxProjEsc
  Função para realizar a projeção de uma agenda baseado em uma escala
@since		31/05/2017
@version	P12.1.17
@author 	Inovação - Gestão de Serviços

@param		ExpC1	Codigo da Escala
@param		ExpD2	Data Inicial da Alocacao
@param		ExpD3	Data Final da Alocacao
@param		ExpC4	Codigo do turno
@param		ExpC5	Sequencia do Turno
@param		ExpA6	Array da tabela padrão
@param		ExpA7	Array da tabela de calendario
@param		ExpC8	Filial da SR6

@return 	Nenhum
/*/
//------------------------------------------------------------------------------
Function TxProjEsc(cEscala,cCalend,dDatIni,dDatFim,cTurno,cSeq,aTabPadrao,aTabCalend,cFilSR6)
Local lRetCalend 	:= .T.
local lPEEscala		:= FindFunction('U_PNMSEsc') .And. FindFunction('U_PNMSCal')

Default cFilSR6    	:= xFilial("SR6")

If !lPEEscala 
	If !IsBlind()
		Help( , , "TxProjEsc", , STR0076, 1, 0,,,,,,{STR0077}) //"O RDMAKE PNMTABC01 não está compilado no repositorio"##"Para realizar a projeção baseado na escala é necessario que o RDMAKE esteja compilado no repositorio"
	EndIf
Else
	U_PNMSEsc(cEscala) // informar escala
	U_PNMSCal(cCalend) // informar calendario  
		
	lRetCalend := CriaCalend( 	dDatIni    ,;    //01 -> Data Inicial do Periodo
	                           		dDatFim    ,;    //02 -> Data Final do Periodo
	                            	cTurno     ,;    //03 -> Turno Para a Montagem do Calendario
	                            	cSeq       ,;    //04 -> Sequencia Inicial para a Montagem Calendario
	                            	@aTabPadrao,;    //05 -> Array Tabela de Horario Padrao
	                            	@aTabCalend,;    //06 -> Array com o Calendario de Marcacoes  
	                            	cFilSR6    ,;    //07 -> Filial para a Montagem da Tabela de Horario
	                            	Nil, Nil )
	                            	
	U_PNMSEsc(Nil) // Limpar as variaveis estaticas
	U_PNMSCal(Nil)  
EndIf

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} TxBuscAgen
  Função para buscar a agenda do atendente dentro de um periodo
@since		31/05/2017
@version	P12.1.17
@author 	Inovação - Gestão de Serviços

@param		ExpC1	Filial do Funcionario
@param		ExpC2	Matricula do Funcionario
@param		ExpC3	Codigo do técnico
@param		ExpD4	Data inicial
@param		ExpD5	Data inicial

@return 	Caracter, Alias da agenda
/*/
//------------------------------------------------------------------------------
Function TxBuscAgen(_cFunFil,_cMatFunc,_cCodTec,_cDataI,_cDataF)
Local cAliasABB	:= GetNextAlias()

BeginSql Alias cAliasABB

	COLUMN TDV_DTREF AS DATE
	COLUMN ABB_DTINI AS DATE
	COLUMN ABB_DTFIM AS DATE
		SELECT ABB_CODIGO
		     , ABB_MANUT
		     , ABB_CODTEC
		     , ABB_ATIVO
		     , TDV_DTREF
		     , ABB_DTINI
		     , ABB_HRINI
		     , ABB_DTFIM
		     , ABB_HRFIM
		     , ABB_LOCAL
		     , ABS_CODIGO
		     , ABS_LOJA
		     , COALESCE(ABR_CODSUB,'') ABR_CODSUB
		     , COALESCE(ABN_TIPO,'') ABN_TIPO
		     , TDV_FERIAD
		     , TDV_TURNO
		     , TFF_FILIAL
		     , TFF_CONTRT
		     , TFF_COD
		  FROM %Table:ABB% ABB

		  JOIN %Table:ABS% ABS ON ABS_FILIAL = %xFilial:ABS%
		   AND ABS_LOCAL = ABB_LOCAL
		   AND ABS.%NotDel%

		  LEFT OUTER JOIN %Table:ABR% ABR ON ABR_FILIAL = %xFilial:ABR%
		   AND ABR_AGENDA = ABB_CODIGO
		   AND ABR.%NotDel%

		  LEFT OUTER JOIN %Table:ABN% ABN ON ABN_FILIAL = %xFilial:ABN%
		   AND ABN_CODIGO = ABR_MOTIVO
		   AND ABN.%NotDel%

		  JOIN %Table:AA1% AA1 ON AA1_FILIAL = %xFilial:AA1%
		   AND AA1_CODTEC = ABB_CODTEC
		   AND AA1_CDFUNC = %Exp:_cMatFunc%
		   AND AA1_FUNFIL = %Exp:_cFunFil%
		   AND AA1.%NotDel%

		  JOIN %Table:TDV% TDV ON TDV_FILIAL = %xFilial:TDV%
		   AND TDV_CODABB = ABB_CODIGO
		   AND TDV.%NotDel%

		  JOIN %Table:ABQ% ABQ ON ABQ_FILIAL = %xFilial:ABQ%
		   AND ABQ_CONTRT||ABQ_ITEM||ABQ_ORIGEM = ABB_IDCFAL
		   AND ABQ.%NotDel%

		  JOIN %Table:TFF% TFF ON TFF_FILIAL = %xFilial:TFF%
		   AND TFF_FILIAL = ABQ_FILTFF
		   AND TFF_COD = ABQ_CODTFF
		   AND TFF.%NotDel%

		 WHERE ABB_FILIAL = %xFilial:ABB%
		   AND ABB.ABB_CODTEC = %Exp:_cCodTec%
   		   AND ABB.ABB_DTINI >= %Exp:_cDataI%
		   AND ABB.ABB_DTFIM <= %Exp:_cDataF%
		   AND ABB.%NotDel%

		 ORDER BY TDV_DTREF
		        , ABB_DTINI
		        , ABB_HRINI
		        , ABB_DTFIM
		        , ABB_HRFIM
		        , TFF_CONTRT
		        , ABB_LOCAL

EndSql

Return cAliasABB
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TxProdArm

Construção da consulta especifica para armamentos.
            
@author Rebeca Facchinato Asunção
@since 25/08/2017
@version P12.1.17
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TxProdArm(nOpc)

Local lRet        := .F.
Local oBrowse     := Nil
Local cAls        := GetNextAlias()
Local nSuperior   := 0
Local nEsquerda   := 0
Local nInferior   := 0
Local nDireita    := 0
Local cQry        := ""
Local aIndex      := {}
Local aSeek       := {} 
Local oView       := Nil
Local oDlgEscTela := Nil

Aadd( aSeek, { STR0063, {{"","C",TamSX3("B1_COD")[1],0,STR0063,,}} } ) // "Código" ### "Código"
Aadd( aSeek, { STR0064, {{"","C",TamSX3("B1_DESC")[1],0,STR0064,,}}}) // "Descrição" ### "Descrição"

Aadd( aIndex, "B1_COD" )
Aadd( aIndex, "B1_DESC")
Aadd( aIndex, "B1_FILIAL")  // adicionado para não ter problema de não encontrar o último índice, em caso de adicionar mais deixe a filial por último

Do Case
      Case nOpc == 1
      
		cQry :=    "  SELECT TE0_COD 'CODIGO', B1_COD, B1.B1_DESC FROM " + RetSqlName("TE0") + " TE0 " 
		cQry +=     " INNER JOIN "  + RetSqlName("SB1")  + " B1 " +   "ON B1_FILIAL =  '" + xFilial("SB1") + "' AND B1.B1_COD = TE0.TE0_CODPRO AND B1.D_E_L_E_T_ = ' '"
		cQry +=     " INNER JOIN "  + RetSqlName("SB5")  + " B5 " +  "ON B5_FILIAL =  '" + xFilial("SB5") + "'  AND B5.B5_COD = B1.B1_COD AND B5.D_E_L_E_T_ = ' '"
		cQry +=     " WHERE TE0_FILIAL = '" +  xFilial('TE0') + "'" 
		cQry +=     " AND TE0.D_E_L_E_T_ = ' '"
            
      Case nOpc == 2
      
      	cQry :=    "  SELECT TE1_CODCOL 'CODIGO', B1_COD, B1.B1_DESC FROM " + RetSqlName("TE1") + " TE1 " 
		cQry +=     " INNER JOIN "  + RetSqlName("SB1")  + " B1 " +   "ON B1_FILIAL =  '" + xFilial("SB1") + "' AND B1.B1_COD = TE1.TE1_CODPRO AND B1.D_E_L_E_T_ = ' '"
		cQry +=     " INNER JOIN "  + RetSqlName("SB5")  + " B5 " +  "ON B5_FILIAL =  '" + xFilial("SB5") + "'  AND B5.B5_COD = B1.B1_COD AND B5.D_E_L_E_T_ = ' '"
		cQry +=     " WHERE TE1_FILIAL = '" +  xFilial('TE1') + "'" 
		cQry +=     " AND TE1.D_E_L_E_T_ = ' '"
		
	  Case nOpc == 3
	
      	cQry :=    "  SELECT DISTINCT B1_COD 'CODIGO', B1.B1_DESC FROM " + RetSqlName("TE2") + " TE2 " 
      	cQry +=     " INNER JOIN "  + RetSqlName("SB1")  + " B1 " +   "ON B1_FILIAL =  '" + xFilial("SB1") + "' AND B1.B1_COD = TE2.TE2_CODPRO AND B1.D_E_L_E_T_ = ' '"
		cQry +=     " INNER JOIN "  + RetSqlName("SB5")  + " B5 " +  "ON B5_FILIAL =  '" + xFilial("SB5") + "'  AND B5.B5_COD = B1.B1_COD AND B5.D_E_L_E_T_ = ' '"
		cQry +=     " WHERE TE2_FILIAL = '" +  xFilial('TE2') + "'" 
		cQry +=     " AND TE2.D_E_L_E_T_ = ' '"
      
EndCase

nSuperior := 0
nEsquerda := 0
nInferior := 460
nDireita  := 800

DEFINE MSDIALOG oDlgEscTela TITLE STR0057 FROM nSuperior,nEsquerda TO nInferior,nDireita PIXEL // "Produtos"

oBrowse := FWFormBrowse():New() 
oBrowse:SetOwner(oDlgEscTela)
oBrowse:SetDataQuery(.T.)
oBrowse:SetAlias(cAls)
oBrowse:SetQuery(cQry)
oBrowse:SetQueryIndex(aIndex)
oBrowse:SetSeek(,aSeek)
oBrowse:SetDescription(STR0057)  // "Produtos"
oBrowse:SetMenuDef("")
oBrowse:DisableDetails()

oBrowse:SetDoubleClick({ || cRetProd := (oBrowse:Alias())->CODIGO, lRet := .T. ,oDlgEscTela:End()})
oBrowse:AddButton( OemTOAnsi(STR0061), {|| cRetProd   := (oBrowse:Alias())->CODIGO, lRet := .T., oDlgEscTela:End() } ,, 2 ) //"Confirmar"
oBrowse:AddButton( OemTOAnsi(STR0062),  {||  cRetProd  := "", oDlgEscTela:End() } ,, 2 ) //"Cancelar"
oBrowse:DisableDetails()

ADD COLUMN oColumn DATA { ||  CODIGO } TITLE STR0063 SIZE TamSX3("TE0_COD")[1] OF oBrowse //"Código"

If nOpc <> 3
	ADD COLUMN oColumn DATA { ||  B1_COD  } TITLE STR0063 SIZE TamSX3("TE2_CODPRO")[1] OF oBrowse //"Código"
EndIf	

ADD COLUMN oColumn DATA { ||  B1_DESC } TITLE STR0064 SIZE TamSX3("TE2_DESPRO")[1] OF oBrowse //"Descrição"

oBrowse:Activate()

ACTIVATE MSDIALOG oDlgEscTela CENTERED


Return( lRet )

//-------------------------------------------------------------------
/*/{Protheus.doc} TxRetArm()

Retorno da consulta especifica

@author Rebeca Facchinato Asunção
@since 25/08/2017
@version P12.1.17
@return Nil
/*/
//------------------------------------------------------------------
Function TxRetArm()

Return cRetProd

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TxProdArm

Construção da consulta especifica para armamentos.
            
@author Rebeca Facchinato Asunção
@since 25/08/2017
@version P12.1.17
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TxPrdArma(nOpc)

Local lRet        := .F.
Local oBrowse     := Nil
Local cAls        := GetNextAlias()
Local nSuperior   := 0
Local nEsquerda   := 0
Local nInferior   := 0
Local nDireita    := 0
Local cQry        := ""
Local aIndex      := {}
Local aSeek       := {} 
Local oView       := Nil
Local oDlgEscTela := Nil

Aadd( aSeek, { STR0063, {{"","C",TamSX3("B1_COD")[1],0,STR0063,,}} } ) // "Código" ### "Código"
Aadd( aSeek, { STR0064, {{"","C",TamSX3("B1_DESC")[1],0,STR0064,,}}}) // "Descrição" ### "Descrição"

Aadd( aIndex, "B1_COD" )
Aadd( aIndex, "B1_DESC")
Aadd( aIndex, "B1_FILIAL")  // adicionado para não ter problema de não encontrar o último índice, em caso de adicionar mais deixe a filial por último

cQry :=     " SELECT B1_FILIAL, B1_COD, B1_DESC"
cQry +=     " FROM " + RetSqlName("SB1") + " B1"
cQry +=     " INNER JOIN " + RetSqlName("SB5") + " B5"
cQry +=     " ON B1.B1_FILIAL = B5.B5_FILIAL"
cQry +=     " AND B1.B1_COD = B5.B5_COD"

Do Case
      Case nOpc == 1
            cQry += 	" AND B5_TPISERV = '1'" // Arma
      Case nOpc == 2
            cQry += 	" AND B5_TPISERV = '2'" //Colete
      Case nOpc == 3
            cQry += 	" AND B5_TPISERV = '3'" //Municao
EndCase

cQry +=     " AND B1.D_E_L_E_T_ = ' '"
cQry +=     " AND B5.D_E_L_E_T_ = ' '"
cQry +=     " WHERE B1_FILIAL = '" +  xFilial('SB1') + "'

nSuperior := 0
nEsquerda := 0
nInferior := 460
nDireita  := 800

DEFINE MSDIALOG oDlgEscTela TITLE STR0057 FROM nSuperior,nEsquerda TO nInferior,nDireita PIXEL // "Produtos"

oBrowse := FWFormBrowse():New() 
oBrowse:SetOwner(oDlgEscTela)
oBrowse:SetDataQuery(.T.)
oBrowse:SetAlias(cAls)
oBrowse:SetQueryIndex(aIndex)
oBrowse:SetQuery(cQry)
oBrowse:SetSeek(,aSeek)
oBrowse:SetDescription(STR0057)  // "Produtos"
oBrowse:SetMenuDef("")
oBrowse:DisableDetails()

oBrowse:SetDoubleClick({ || cRetProd := (oBrowse:Alias())->B1_COD, lRet := .T. ,oDlgEscTela:End()})
oBrowse:AddButton( OemTOAnsi(STR0061), {|| cRetProd   := (oBrowse:Alias())->B1_COD, lRet := .T., oDlgEscTela:End() } ,, 2 ) //"Confirmar"
oBrowse:AddButton( OemTOAnsi(STR0062),  {||  cRetProd  := "", oDlgEscTela:End() } ,, 2 ) //"Cancelar"
oBrowse:DisableDetails()

ADD COLUMN oColumn DATA { ||  B1_COD  } TITLE STR0063 SIZE TamSX3("B1_COD")[1] OF oBrowse //"Código"
ADD COLUMN oColumn DATA { ||  B1_DESC } TITLE STR0064 SIZE TamSX3("B1_DESC")[1] OF oBrowse //"Descrição"

oBrowse:Activate()

ACTIVATE MSDIALOG oDlgEscTela CENTERED

Return( lRet )

//-------------------------------------------------------------------
/*/{Protheus.doc} TxF3Gen()
Consulta genérica para F3 especifico.

@author Kaique Schiller
@since 18/05/2018
@return lRet
/*/
//------------------------------------------------------------------
Function TxF3Gen(cTit, cQry, aHeader, aSeek, aIndex, cCmpRet, cFunc, lClose)
Local lRet			:= .F.
Local oBrowse		:= Nil
Local cAls			:= GetNextAlias()
Local nSuperior		:= 0
Local nEsquerda		:= 0
Local nInferior		:= 0
Local nDireita		:= 0
Local oDlgEscTela	:= Nil
Local nX			:= 0
Local aRetHead		:= {}
Local aRetSeek		:= {}
Local aArea			:= GetArea()				
Local aAreaSX3		:= SX3->(GetArea())

Default cTit		:= ""
Default cQry		:= ""
Default aHeader		:= {}
Default aSeek 		:= {}
Default aIndex		:= {}
Default cCmpRet		:= ""
Default cFunc		:= ".T."
Default lClose		:= .T.

If !Empty(aHeader) .And. !Empty(cQry) .And. !Empty(cTit) .And. !Empty(aSeek) .And. !Empty(aIndex) .And. !Empty(cCmpRet)
	
	DbSelectArea("SX3")
	SX3->(dbSetOrder(2))
	
	For	nX := 1 To Len(aHeader)
		If SX3->(DbSeek(aHeader[nX,1]))
			If Len(aHeader[nX]) < 2
				aAdd(aRetHead,{"{ || " +aHeader[nX,1] +" }", Alltrim(x3Titulo()),TamSX3(aHeader[nX,1])[1] })
			Else
				aAdd(aRetHead,{"{ || " +aHeader[nX,1] +" }", Alltrim(aHeader[nX,2]),TamSX3(aHeader[nX,1])[1] })
			Endif
		Endif
	Next nX
	
	For	nX := 1 To Len(aSeek)
		If SX3->(DbSeek(aSeek[nX]))
			Aadd( aRetSeek, {Alltrim(x3Titulo()), {{"",SX3->X3_TIPO,TamSX3(aSeek[nX])[1],TamSX3(aSeek[nX])[2],Alltrim(x3Titulo())	,,}}})
		Endif
	Next nX
	
	nSuperior := 0
	nEsquerda := 0
	nInferior := 460
	nDireita  := 800
	 
	DEFINE MSDIALOG oDlgEscTela TITLE cTit FROM nSuperior,nEsquerda TO nInferior,nDireita PIXEL Style 128
	 
	oBrowse := FWFormBrowse():New()
	oBrowse:SetOwner(oDlgEscTela)
	oBrowse:SetDataQuery(.T.)
	oBrowse:SetAlias(cAls)
	oBrowse:SetQueryIndex(aIndex)
	oBrowse:SetDescription(cTit)
	oBrowse:SetMenuDef("")
		
	oBrowse:SetDoubleClick({ || lRet := &cFunc.(oBrowse), Iif( lRet, _cTecRetF3 := (oBrowse:Alias())->&(cCmpRet),_cTecRetF3 := "" ),Iif( !Empty(_cTecRetF3),oDlgEscTela:End(),.F.)})
	oBrowse:AddButton( OemTOAnsi(STR0061), {|| lRet := &cFunc.(oBrowse), Iif( lRet, _cTecRetF3 := (oBrowse:Alias())->&(cCmpRet),_cTecRetF3 := "" ),Iif( !Empty(_cTecRetF3),oDlgEscTela:End(),.F.)} ,, 2 ) //"Confirmar"
	
	If lClose
	oBrowse:AddButton( OemTOAnsi(STR0062), {|| _cTecRetF3  := "", oDlgEscTela:End() } ,, 2 ) //"Cancelar"
	Else
		oDlgEscTela:lEscClose 	:= .F.
	Endif	
	
	oBrowse:DisableDetails()
	oBrowse:SetQuery(cQry)
	oBrowse:SetSeek(,aRetSeek)
	oBrowse:SetUseFilter()
	
	For nX := 1 To Len(aRetHead)
		ADD COLUMN oColumn DATA &(aRetHead[nX,1]) TITLE aRetHead[nX,2] SIZE aRetHead[nX,3] OF oBrowse
	Next nX
	
	oBrowse:Activate()
	 
	ACTIVATE MSDIALOG oDlgEscTela CENTERED
	
	RestArea(aAreaSX3)
	RestArea(aArea)

Endif
     	
Return( lRet )

//-------------------------------------------------------------------
/*/{Protheus.doc} TxRetF3()
Retorno da consulta genérica para F3 especifico.

@author Kaique Schiller
@since 18/05/2018
@return _cTecRetF3
/*/
//------------------------------------------------------------------
Function TxRetF3()

Return _cTecRetF3

//-------------------------------------------------------------------
/*/{Protheus.doc} TxTpServ()
Função de When do campo B5_GSBE

@author Serviços
@since 27/08/2018
@return lRet
/*/
//------------------------------------------------------------------
Function TxTpServ(cCampo)
Local lRet		 := .F.

If M->B5_TPISERV == "5"
	lRet := .T.
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} TxTpGat()
Função de Gatilho para o campo B5_GSBE

@author Serviços
@since 27/08/2018
@return lRet
/*/
//------------------------------------------------------------------
Function TxTpGat()
Local cRet := ""

If M->B5_GSBE == "1"
	M->B5_GSMI := "2"
	M->B5_GSMC := "2"
	cRet := "2"
Else
	M->B5_GSMI := ""
	M->B5_GSMC := ""
EndIf

Return cRet


//-------------------------------------------------------------------
/*/{Protheus.doc} At740F3Fun()
Construção da consulta especifica

@author fabiana.silva
@since 16/03/2018
@version P12.1.17
@return Nil
/*/
//------------------------------------------------------------------
Function At740F3Fun()
Local lRet			:= .F.
Local oBrowse		:= Nil
Local cAls			:= GetNextAlias()
Local nSuperior	:= 0
Local nEsquerda	:= 0
Local nInferior	:= 0
Local nDireita	:= 0
Local oDlgTela	:= Nil
Local cQry			:= ""
Local aIndex		:= {}
Local aSeek		:= {}
Local oModel		:= Nil 
Local cFil 		:= ""
Local lGSVinc 	:= SuperGetMv("MV_GSVINC",,.F.) .AND. ExistFunc("At994RetVc") .AND. AliasInDic("TXA")
Local cCodProd 	:= ""
Local cRetTXA 	:= "0" //Retorno dos valores da TXA

Aadd( aSeek, { STR0063, {{"","C",TamSX3("RJ_FUNCAO")[1],0,STR0063,,}} } ) // "Código" ### "Código"
Aadd( aSeek, { STR0087, {{"","C",TamSX3("RJ_DESC")[1],0,STR0087,,}}}) // "Funções" ### "Funções"

Aadd( aIndex, "RJ_FUNCAO" )
Aadd( aIndex, "RJ_DESC")

If lGSVinc

	oModel := FWModelActive() //Modelo Ativo
	cCodProd := oModel:GetValue(IIF( RTrim(oModel:GetId() )  == "TECA740A", "TFF_GRID", "TFF_RH"),"TFF_PRODUT")
	//Verifica se existe um vinculo cadastrado para o Produto
	 //cRetTXA := At994RetVc(cCodProd, _TPIP_FUNCAO)
	 cRetTXA := At994RtPrd(cCodProd, _TPIP_FUNCAO)
EndIf

	
If cRetTXA <> "2"	
	cQry := "SELECT SRJ.RJ_FILIAL, SRJ.RJ_FUNCAO, SRJ.RJ_DESC"
	cQry += " FROM " + RetSqlName("SRJ") + " SRJ "
	cQry += " WHERE RJ_FILIAL = '"+xFilial("SRJ")+"' AND SRJ.D_E_L_E_T_ = '' "
Else
	cQry := "SELECT SRJ.RJ_FILIAL, SRJ.RJ_FUNCAO, SRJ.RJ_DESC"
	cQry += " FROM " + RetSqlName("SRJ") + " SRJ, " 
	cQry += " " + RetSqlName("TXA") + " TXA "
	cQry += " WHERE  SRJ.RJ_FUNCAO = TXA.TXA_FUNCAO "
	cQry += " AND  SRJ.RJ_FILIAL = '"+xFilial("SRJ")+"' AND SRJ.D_E_L_E_T_ = '' "
	cQry += " AND TXA_PRODUT = '"+cCodProd+"' AND TXA.TXA_TPIT  = '"+ _TPIP_FUNCAO + "' "
	cQry += " AND TXA_FILIAL = '"+xFilial("TXA")+"' AND TXA.D_E_L_E_T_ = '' "
EndIf

nSuperior := 0
nEsquerda := 0
nInferior := 460
nDireita  := 800
 
DEFINE MSDIALOG oDlgTela TITLE STR0087 FROM nSuperior,nEsquerda TO nInferior,nDireita PIXEL	//"Funções"

oBrowse := FWFormBrowse():New() 
oBrowse:SetOwner(oDlgTela)
oBrowse:SetDataQuery(.T.)
oBrowse:SetAlias(cAls)
oBrowse:SetQueryIndex(aIndex)
oBrowse:SetQuery(cQry)
oBrowse:SetSeek(,aSeek)
oBrowse:SetDescription(STR0087)  //"Funções"
oBrowse:SetMenuDef("")
oBrowse:DisableDetails()

oBrowse:SetDoubleClick({ || cRetProd := (oBrowse:Alias())->RJ_FUNCAO, lRet := .T. ,oDlgTela:End()})
oBrowse:AddButton( OemTOAnsi(STR0061), {|| cRetProd := (oBrowse:Alias())->RJ_FUNCAO, lRet := .T., oDlgTela:End() } ,, 2 ) //"Confirmar"
oBrowse:AddButton( OemTOAnsi(STR0062),  {|| cRetProd := "", oDlgTela:End() } ,, 2 ) //"Cancelar"
oBrowse:DisableDetails()

ADD COLUMN oColumn DATA {|| RJ_FUNCAO } TITLE RetTitle("RJ_FUNCAO") SIZE TamSX3("RJ_FUNCAO")[1] OF oBrowse //"Turno"
ADD COLUMN oColumn DATA {|| RJ_DESC }  TITLE RetTitle("RJ_DESC") SIZE TamSX3("RJ_DESC")[1] OF oBrowse //"Descrição"

oBrowse:Activate()
 
ACTIVATE MSDIALOG oDlgTela CENTERED
     	
Return( lRet )

//-------------------------------------------------------------------
/*/{Protheus.doc} At740turRt()
Retorno da consulta especifica

@author Filipe Gonçalves Rodrigues
@since 07/07/2016
@version P12.1.7
@return Nil
/*/
//------------------------------------------------------------------
Function At740FunRt()

Return cRetProd

//------------------------------------------------------------------------------


//-------------------------------------------------------------------
/*/{Protheus.doc} At740F3Fun()
Construção da consulta especifica

@author fabiana.silva
@since 16/03/2018
@version P12.1.17
@return Nil
/*/
//------------------------------------------------------------------
Function At740F3Esc()
Local lRet		:= .F.
Local oBrowse	:= Nil
Local cAls		:= GetNextAlias()
Local nSuperior	:= 0
Local nEsquerda	:= 0
Local nInferior	:= 0
Local nDireita	:= 0
Local oDlgTela	:= Nil
Local cQry		:= ""
Local aIndex      := {}
Local aSeek       := {} 
Local oModel	:= Nil 
Local cFil 		:= ""
Local lGSVinc := SuperGetMv("MV_GSVINC",,.F.) .AND. ExistFunc("At994RetVc") .AND. AliasInDic("TXA")
Local cCodProd := ""
Local cRetTXA := "0"

Aadd( aSeek, { STR0063, {{"","C",TamSX3("TDW_COD")[1],0,STR0063,,}} } ) // "Código" ### "Código"
Aadd( aSeek, { STR0088, {{"","C",TamSX3("TDW_DESC")[1],0,STR0088,,}}}) // "Escalas" ### "Escalas"

Aadd( aIndex, "TDW_COD" )
Aadd( aIndex, "TDW_DESC")

If lGSVinc
	oModel := FWModelActive() //Modelo Ativo
	
	cCodProd := oModel:GetValue(IIF( RTrim(oModel:GetId() )  == "TECA740A", "TFF_GRID", "TFF_RH"),"TFF_PRODUT")
	//Verifica se existe um vinculo cadastrado para o Produto
	 //cRetTXA := At994RetVc(cCodProd, _TPIP_ESCALA)
	 cRetTXA := At994RtPrd(cCodProd, _TPIP_ESCALA)
EndIf

	
If cRetTXA <> "2"	
	cQry := "SELECT TDW.TDW_FILIAL, TDW.TDW_COD, TDW.TDW_DESC"
	cQry += " FROM " + RetSqlName("TDW") + " TDW "
	cQry += " WHERE TDW_FILIAL = '"+xFilial("TDW")+"' AND TDW.D_E_L_E_T_ = '' "
Else
	cQry := "SELECT TDW.TDW_FILIAL, TDW.TDW_COD, TDW.TDW_DESC"
	cQry += " FROM " + RetSqlName("TDW") + " TDW, " 
	cQry += " " + RetSqlName("TXA") + " TXA "
	cQry += " WHERE  TDW.TDW_COD = TXA.TXA_ESCALA "
	cQry += " AND  TDW.TDW_FILIAL = '"+xFilial("TDW")+"' AND TDW.D_E_L_E_T_ = '' "
	cQry += " AND TXA_PRODUT = '"+cCodProd+"' AND TXA.TXA_TPIT  = '"+ _TPIP_ESCALA + "' "
	cQry += " AND TXA_FILIAL = '"+xFilial("TXA")+"' AND TXA.D_E_L_E_T_ = '' "
EndIf

nSuperior := 0
nEsquerda := 0
nInferior := 460
nDireita  := 800
 
DEFINE MSDIALOG oDlgTela TITLE STR0088 FROM nSuperior,nEsquerda TO nInferior,nDireita PIXEL	//"Escalas

oBrowse := FWFormBrowse():New() 
oBrowse:SetOwner(oDlgTela)
oBrowse:SetDataQuery(.T.)
oBrowse:SetAlias(cAls)
oBrowse:SetQueryIndex(aIndex)
oBrowse:SetQuery(cQry)
oBrowse:SetSeek(,aSeek)
oBrowse:SetDescription(STR0088)  //"Escalas"
oBrowse:SetMenuDef("")
oBrowse:DisableDetails()

oBrowse:SetDoubleClick({ || cRetProd := (oBrowse:Alias())->TDW_COD, lRet := .T. ,oDlgTela:End()})
oBrowse:AddButton( OemTOAnsi(STR0061), {|| cRetProd   := (oBrowse:Alias())->TDW_COD, lRet := .T., oDlgTela:End() } ,, 2 ) //"Confirmar"
oBrowse:AddButton( OemTOAnsi(STR0062),  {||  cRetProd  := "", oDlgTela:End() } ,, 2 ) //"Cancelar"
oBrowse:DisableDetails()

ADD COLUMN oColumn DATA { ||  TDW_COD  } TITLE RetTitle("TDW_COD") SIZE TamSX3("TDW_COD")[1] OF oBrowse //"Código"
ADD COLUMN oColumn DATA { ||  TDW_DESC } TITLE RetTitle("TDW_DESC") SIZE TamSX3("TDW_DESC")[1] OF oBrowse //"Descrição"

oBrowse:Activate()
 
ACTIVATE MSDIALOG oDlgTela CENTERED
     	
Return( lRet )

//-------------------------------------------------------------------
/*/{Protheus.doc} At740turRt()
Retorno da consulta especifica

@author Filipe Gonçalves Rodrigues
@since 07/07/2016
@version P12.1.7
@return Nil
/*/
//------------------------------------------------------------------
Function At740EscRt()

Return cRetProd

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} T180WhenMdtGS
Caso exista o parâmetro (MV_NG2GS) de integração (SIGAMDT x SIGATEC) durante a inclusão na tabela (TN0-Risco) 
os campos TN0_CC (Centro Custo), TN0_CODFUN (Função) e TN0_DEPTO (Departamento) serão preenchidos automaticamente com “*”.
@param  cField, Caracter, Campo posicionado durante a validção
@return lRetorno, Lógico, Verdadeiro/Falso
@author Eduardo Gomes Júnior
@since 09/01/2018
/*/
//------------------------------------------------------------------------------------------
Function T180WhenMdtGS(cField)

Local lRetorno		:= .T.
Local lSigaMdtGS	:= SuperGetMv("MV_NG2GS",.F.,.F.)	//Parâmetro de integração entre o SIGAMDT x SIGATEC

If	cField == "TN0_CC"
	
	If	lSigaMdtGS
	
		M->TN0_CC := "*"
		RunTrigger( 1,,,, "TN0_CC" )
		lRetorno := .F.
		
	Else 
	
		lRetorno := A180DESTIN() .And. (Type('lTrava902')=='L' .AND. lTrava902)
	
	Endif 		
			
ElseIf	cField == "TN0_CODFUN"

	If	lSigaMdtGS

		M->TN0_CODFUN := "*"
		RunTrigger( 1,,,, "TN0_CODFUN" )
		lRetorno := .F.
		
	Else
	
		lRetorno := DTVALIDA .And. (Type('lTrava902') == 'L' .AND. lTrava902)
	
	Endif 		
			
ElseIf	cField == "TN0_DEPTO"

	If	lSigaMdtGS

		M->TN0_DEPTO := "*"
		RunTrigger( 1,,,, "TN0_DEPTO" )
		lRetorno := .F.
		
	Else
	
		lRetorno := DTVALIDA .And. (Type('lTrava902') == 'L' .AND. lTrava902) 
					  	
	Endif 		

Endif 

Return(lRetorno) 


//------------------------------------------------------------------------------------------
/*/{Protheus.doc} T180ValidMdtGS
Caso exista o parâmetro (MV_NG2GS) de integração (SIGAMDT x SIGATEC) durante a inclusão na 
tabela (TN0-Risco) o campo TN0_CODTAR não poderá ser preenchido com "*" 
Validação adicionada no VALID do campo mencionado acima.
@param  cField, Caracter, Campo posicionado durante a validção
@return lRetorno, Lógico, Verdadeiro/Falso
@author Eduardo Gomes Júnior
@since 09/01/2018
/*/
//------------------------------------------------------------------------------------------	
Function T180ValidMdtGS(cField)

Local lRetorno		:= .T.
Local lSigaMdtGS	:= SuperGetMv("MV_NG2GS",.F.,.F.)	//Parâmetro de integração entre o SIGAMDT x SIGATEC

If	lSigaMdtGS .AND. Alltrim(M->TN0_CODTAR) == "*"
	HELP(' ',1,'T180ValidMdtGS',,"Tarefa não pode ser preenchida com (*).",5,1)	//"Tarefa não pode ser preenchida com (*)."
	lRetorno := .F.
Endif 

Return(lRetorno)
