#INCLUDE "PROTHEUS.CH"
#INCLUDE "TECA910.CH"
#INCLUDE "FILEIO.CH"   

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECA910()

Gera as marcaï¿½ï¿½es atraves do atendimento da O.S

@return ExpL: Retorna .T. quando teve sucesso na operaï¿½ï¿½o
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TECA910()
Local aArea		:= GetArea()
Local cQuery	:= ""
Local cAlias	:= GetNextAlias()	// Alias
Local nTotal	:= 0
Local oDlg
Local oPanTop
Local oPanBot
Local oFont
Local nMeter
Local oMeter
Local oSay
Local oSayMsg
Local dDataIni		
Local dDataFim

//----------------------------------------------------------------------------
// Parametros Utilizados no Pergunte                                                             
// 
// MV_PAR01: Atendente De ?
// MV_PAR02: Atendente Ate ?                                               	  
// MV_PAR03: Data Inicio De ?                                                     
// MV_PAR04: Data Inicio Ate ?                                                                                                    
// MV_PAR05: Processamento ? 1=Inclusao;2=Exclusao
// MV_PAR06: Mantem Int Turnos? 1=Sim;2=Nï¿½o
// MV_PAR07: Minutos aleatorios ? 1=Sim ;2=Nï¿½o
// MV_PAR08: Quantidade de minutos
// MV_PAR09: CC do Local ? 1=Sim ;2=Nï¿½o 
//------------------------------------------------------------------------------

lContinua := Pergunte("TEC910",.T.)

If lContinua
	
	//Verifica Periodo de Apontamente(MV_PAPONTA)
	PerAponta(@dDataIni,@dDataFim )
	
	If MV_PAR03 < dDataIni .OR. MV_PAR04 > dDataFim 
		// "Atenï¿½ï¿½o"#"Impossï¿½vel enviar ao RH marcaï¿½ï¿½es anteriores ao perï¿½odo inicial ou posteriores ao perï¿½odo final de apontamento "#"OK"
		Aviso(STR0001,STR0002+Dtoc(dDataIni)+STR0003+Dtoc(dDataFim)+"  (MV_PAPONTA).",{"OK"},2)		
		lContinua := .F.
	EndIf
EndIf

If lContinua
	
	//Monta a Query para geraï¿½ï¿½o da marcaï¿½ï¿½o
	cQuery := At910Qry()
	
	cQuery := ChangeQuery( cQuery )
	
	dbUseArea( .T., "TOPCONN", TcGenQry( , , cQuery ), cAlias , .T. , .T. ) 
		
	TcSetField(  cAlias	, "AB9_DTINI", "D", 8, 0 ) 
	TcSetField(  cAlias	, "AB9_DTFIM", "D", 8, 0 )
	
	(cAlias)->(DbGoTop())	
	While !(cAlias)->(EOF())
		nTotal++
		(cAlias)->(DbSkip())
	End	
	(cAlias)->(DbGoTop())
	
	If nTotal > 0 
		DEFINE MSDIALOG oDlg TITLE STR0005 FROM 0,0 TO 100,422 PIXEL STYLE DS_MODALFRAME // "Geraï¿½ï¿½o das Marcaï¿½ï¿½es"
			oPanTop := TPanel():New( 0, 0, , oDlg, , , , , , 0, 0, ,  )
			oPanTop:Align := CONTROL_ALIGN_ALLCLIENT     
			
			oPanBot := TPanel():New( 0, 0, , oDlg, , , , ,/*CLR_YELLOW*/, 0, 25 , )
			oPanBot:Align := CONTROL_ALIGN_BOTTOM
				
			DEFINE FONT oFont NAME "Arial" SIZE 0,16 
			// "Serï¿½o processados "#" atendimentos para a Geraï¿½ï¿½o de Marcaï¿½ï¿½es."  
			@ 05,08 SAY oSay Var "<center>"+STR0006+cValToChar(nTotal)+STR0007+"</center>" PIXEL SIZE 210,65 HTML FONT oFont PIXEL OF oPanTop
					
			nMeter := 0
			oMeter := TMeter():New(02,7,{|u|if(Pcount()>0,nMeter:=u,nMeter)},nTotal,oPanBot,200,100,,.T.,,,.F.)		
			//"Processando..."#
			@ 10,02 SAY oSayMsg Var "<center>"+STR0008+"</center>" PIXEL SIZE 210,65 HTML FONT oFont PIXEL OF oPanBot
				
		ACTIVATE DIALOG oDlg CENTERED ON INIT At910GerMa(cAlias,oDlg,oMeter,oSayMsg,dDataIni,dDataFim,MV_PAR06==1)
	Else
		//"Atenï¿½ï¿½o"#"Nï¿½o hï¿½ registros para gerar marcaï¿½ï¿½es conforme parametros informados."#"OK"
		Aviso(STR0001,STR0009,{STR0004},2)			
	EndIf
EndIf

Return .T.


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At910GerMa()

Realiza o Processamento do Pergunte na geraï¿½ï¿½o de marcacoes

@param ExpC:Alias da Tabela de processamento
@param ExpO:Dialog do Processamento
@param ExpO:Tmeter para atualizar o processamento
@param ExpO:Texto do processamento
@param ExpD:Data Inicial Limite
@param ExpD:Data Final Limite
@param ExpL:Gera marcaï¿½ï¿½o com os intervalos dos turno?

@return ExpL: Retorna .T. quando houve sucesso na operaï¿½ï¿½o
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At910GerMa(cAlias,oDlg,oMeter,oSayMsg,dDataIni,dDatafim,lGeraMarcInt)

Local nCritica	:= 0
Local nX			:= 0
Local nY			:= 0
Local lRet 		:= .F.
Local nReg			:= 0
Local aRetorno	:= {}
Local aMarcacao	:= {}
Local nTotal		:= 0
Local cMsg			:= ""
Local cTecTran	:= ""	//Controle de Transacao por tecnico
Local lErro		:= .F.
Local nTecnico	:= 0
Local dMarcIni
Local cMarcIni
Local dMarcFim
Local cMarcFim
Local aMarcTec := {}//Armazena marcaï¿½ï¿½es do atendente para enviar ao Mï¿½dulo de ponto eletronico
Local cAtendOld := ""//controle do codigo do atendente
Local aBkpMarc  := {}
Local aRetMrc	:= {}
Local cDiretorio := MV_PAR10 //Diretorio onde serï¿½ copiado o log

While !(cAlias)->(Eof())	

	oMeter:Set(++nReg) // Atualiza Gauge/Tmeter
	oSayMsg:SetText("<center>"+STR0011+cValToChar(nReg)+"</center>")      // "Processando..."

	cMarcIni	:= (cAlias)->AB9_HRINI
	cMarcFim	:= (cAlias)->AB9_HRFIM	
	
	
	//Impede envio de marcaï¿½ï¿½es anteriores ao periodo inicial do apontamento
	If (cAlias)->TDV_DTREF < DTOS(dDataIni) .OR. (cAlias)->TDV_DTREF > DTOS(dDataFim)
		nCritica++  
		// "Impossï¿½vel enviar ao RH marcaï¿½ï¿½es anteriores ao perï¿½odo inicial ou posteriores ao perï¿½odo final de apontamento "#" a "
		At910Log(cAlias,,STR0012+Dtoc(dDataIni)+STR0013+Dtoc(dDataFim)+"  (MV_PAPONTA).")
	Else	
		If (cAlias)->AB9_DTINI == (cAlias)->AB9_DTFIM
			dMarcIni	:= (cAlias)->AB9_DTINI
			dMarcFim	:= (cAlias)->AB9_DTFIM	
			At910AProc(@aRetorno,cAlias,dMarcIni,cMarcIni,dMarcFim,cMarcFim)									
		ElseIf (cAlias)->AB9_DTFIM > (cAlias)->AB9_DTINI 
			//Quando hora final > inicial ï¿½ pq a marcaï¿½ï¿½o final ï¿½ no dia seguinte. Ex. das 20:00 as 05:00 
			If (cAlias)->AB9_HRINI > (cAlias)->AB9_HRFIM
				//Faz por periodo. Se mais de mais de 1 dia de diferenï¿½a.
				//Ex. Se de 01/10 a 03/10 das 20:00 as 05:00 gera atendimento:
				//Entrada - 01/10 as 20:00 saida 02/10 as 05:00
				//Entrada - 02/10 as 20:00 saida 03/10 as 05:00 
				For nX := 0 To (((cAlias)->AB9_DTFIM) - ((cAlias)->AB9_DTINI) - 1)
					dMarcIni	:= (cAlias)->AB9_DTINI + nX
					dMarcFim	:= (cAlias)->AB9_DTINI + nX + 1					
					At910AProc(@aRetorno,cAlias,dMarcIni,cMarcIni,dMarcFim,cMarcFim)
				Next nX			
			Else //(cAlias)->AB9_HRINI <= (cAlias)->AB9_HRFIM
				//Faz por periodo quando hora inicial < hora final. Ex. de 01 a 02 das 08:00 as 17:00
				//Entrada - 01/10 as 08:00 saida 01/10 as 17:00
				//Entrada - 02/10 as 08:00 saida 02/10 as 17:00
				For nX := 0 To (((cAlias)->AB9_DTFIM) - ((cAlias)->AB9_DTINI))
					dMarcIni	:= (cAlias)->AB9_DTINI + nX
					dMarcFim	:= (cAlias)->AB9_DTINI + nX
					At910AProc(@aRetorno,cAlias,dMarcIni,cMarcIni,dMarcFim,cMarcFim)
				Next nX		
			EndIf
		EndIf
	EndIf
	(cAlias)->(DbSkip())	 	
End

(cAlias)->(DbCloseArea())


If Empty(aRetorno)  
	//"Atenï¿½ï¿½o"#"Nï¿½o hï¿½ registros para gerar marcaï¿½ï¿½es conforme parametros informados."#"OK"
	Aviso(STR0001,STR0014,{STR0004},2)			
Else
	//Ordena por Tecnico/Data|Hora Inicial+daTA rEFERENCIA
	ASort(aRetorno,,,{|x,y| x[1]+DToS(x[2])+x[3]+x[14] < y[1]+DToS(y[2])+y[3]+x[14] })
	
	If !lGeraMarcInt
		aMarcacao := At910PMarc(aRetorno,lGeraMarcInt)
	Else	
		aMarcacao := aRetorno
	EndIf
	
	//Ponto de entrada para tratamento dos itens que serao geradas marcacoes
	
	If (ExistBlock("A910MRC"))
		aBkpMarc := aClone(aMarcacao)
		
		aRetMrc:= ExecBlock("A910MRC", .F., .F., aMarcacao)
		
		If (ValType(aMarcacao) != "A")
			aMarcacao := aBkpMarc
		Else
			aMarcacao := aRetMrc[1]
			nCritica  += aRetMrc[2]
		EndIf
	EndIf
	
	nReg := 0
	oMeter:SetTotal(Len(aMarcacao))
	oMeter:Set(nReg) // Atualiza Gauge/Tmeter		
	
	//realiza aglutinaï¿½ï¿½o da marcaï¿½ï¿½o para o atendente, considerando que aMarcacao esteja ordenado por atendente.	
	For nX := 1 To Len(aMarcacao)
		If cAtendOld != aMArcacao[nX][1]			
			aAdd(aMarcTec, {aMarcacao[nX][1], {}})//cria posiï¿½ï¿½o do array para o atendente
			cAtendOld := aMarcacao[nX][1]
		EndIf		
		aAdd(aMarcTec[Len(aMarcTec)][2], aMarcacao[nX])//adiciona marcaï¿½ï¿½es para o atendente
	Next nX	
		
	For nX := 1 To Len(aMarcTec)
		nReg+= Len(aMarcTec[nX][2])
		oSayMsg:SetText("<center>"+STR0015+cValToChar(Len(aMarcacao))+STR0016+cValToChar(nReg)+"</center>")
		oMeter:Set(nReg) // Atualiza Gauge/Tmeter
		
		If (lRet := At910Marca(aMarcTec[nX][2],@cMsg))
			For nY:=1 To Len(aMarcTec[nX][2])
				At910AtAB9(aMarcTec[nX][2][nY][11],.T.)					
			Next nY					
		Else								
			nCritica += nTecnico
			For nY:=1 To Len(aMarcTec[nX][2])
				nCritica++ 
				At910Log(,aMarcTec[nX][2][nY],cMsg)
			Next nY				
		EndIf	
	Next nX
	
	
	If nCritica == 0 
		//"Atenï¿½ï¿½o"#"Foram processadas: "#" marcaï¿½ï¿½es de entrada e saï¿½da."#"OK"
		Aviso(STR0001,STR0018+ cValToChar(nReg) + STR0019,{STR0004},2)	
	Else
		/*"Atenï¿½ï¿½o"#"Foram processadas: "#" Ocorreram "#" erro(s) no processamento."#
		"Quando hï¿½ critica todas marcaï¿½ï¿½es do tecnico para o perï¿½odo nï¿½o serï¿½o geradas." 
		"Foi gerado o log no arquivo "#"OK" */
		Aviso(STR0001,STR0018+cValToChar(Len(aMarcacao))+STR0019;
		+STR0020+cValtoChar(nCritica)+STR0021+CRLF+STR0022;
		+CRLF+STR0023+Alltrim(cDiretorio)+"\MarcaErro-" + AllTrim(DToS(Date())) + ".LOG",{STR0004},2)
	EndIf	
EndIf

oDlg:End()

Return( .T. )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At910AProc()

Gera a array de processamento dos atendimentos da o.s.

@param ExpA:Array que sera alimentada, enviar por referencia
@param ExpC:Alias da tabela de processamento
@param ExpD:Data Entrada da Marcacao
@param ExpC:Hora Entrada da Marcacao
@param ExpD:Data Saida da Marcacao
@param ExpC:Hora Saida da Marcacao
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At910AProc(aRetorno,cAlias,dMarcIni,cMarcIni,dMarcFim,cMarcFim)
	AAdd(aRetorno,{;
		(cAlias)->AB9_CODTEC,;
		dMarcIni,;
		cMarcIni,;
		dMarcFim,;
		cMarcFim,;		
		(cAlias)->AA1_CDFUNC,;
		(cAlias)->AA1_FUNFIL,;
		(cAlias)->AB9_NUMOS,;
		(cAlias)->AB9_CODCLI,;
		(cAlias)->AB9_LOJA,;		
		(cAlias)->AB9RECNO,;
		(cAlias)->ABS_CCUSTO ,;
		(cAlias)->ABB_CODTW3,;
		(cAlias)->TDV_DTREF}) 
		
Return


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At910Qry()

Gera a query para a geraï¿½ï¿½o de marcaï¿½ï¿½es

@return ExpC: Retorna a query utilizada para trazer os atendimentos
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At910Qry()
Local cQuery := ""

//--------------------------------------
// Parametros Utilizados no Pergunte                                                             
// 
// MV_PAR01: Atendente De ?
// MV_PAR02: Atendente Ate ?                                               	  
// MV_PAR03: Data Inicio De ?                                                     
// MV_PAR04: Data Inicio Ate ?                                                                                                    
// MV_PAR05: Processamento ? 1=Inclusao;2=Exclusao
//--------------------------------------

//ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ä¿
//ï¿½Monta a Query para geraï¿½ï¿½o da marcaï¿½ï¿½o                                  ï¿½
//ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
		
cQuery += "SELECT AB9.AB9_FILIAL,AB9.AB9_NUMOS, ABB.ABB_LOCAL, ABS.ABS_CCUSTO,AB9.AB9_SEQ,AB9.AB9_CODTEC,AB9.AB9_DTINI,"
cQuery	+= "AB9.AB9_HRINI,AB9.AB9_DTFIM,AB9.AB9_HRFIM,AB9.AB9_CODCLI,AB9.AB9_LOJA,AB9.AB9_CONTRT, "
cQuery += "AA1.AA1_CDFUNC,AA1.AA1_FUNFIL,AA1.AA1_CC,AA1.AA1_TURNO,AA1.AA1_MPONTO, ABB.ABB_CODTW3 ,  " 
cQuery += "AB9.R_E_C_N_O_ AB9RECNO, TDV.TDV_DTREF  FROM "  + RetSqlName( "AB9" ) + " AB9 "
cQuery += "INNER JOIN "  + RetSqlName( "AA1" ) + " AA1 ON AA1.AA1_FILIAL='" + xFilial( "AA1" ) + "' AND AA1.AA1_CODTEC = AB9.AB9_CODTEC "
	cQuery += "INNER JOIN "  + RetSqlName( "TDV" ) + " TDV ON TDV.TDV_FILIAL ='"+xFilial("TDV") +"' AND TDV.TDV_CODABB = AB9.AB9_ATAUT "
cQuery += "INNER JOIN "  + RetSqlName( "ABB" ) + " ABB ON ABB.ABB_FILIAL='" + xFilial( "ABB" ) + "' AND ABB.ABB_CODTEC = AB9.AB9_CODTEC AND ABB.ABB_CHAVE = AB9.AB9_NUMOS AND ABB.ABB_CODIGO = AB9.AB9_ATAUT "
cQuery += "INNER JOIN "  + RetSqlName( "ABS" ) + " ABS ON ABS.ABS_FILIAL='" + xFilial( "ABS" ) + "' AND ABB.ABB_LOCAL = ABS.ABS_LOCAL "
cQuery += "WHERE " 
cQuery += "AB9_FILIAL='" + xFilial( "AB9" ) + "' AND AA1.AA1_MPONTO = '2' AND "

//Filtra Tecnico
If !Empty(MV_PAR01) 
	cQuery += "AB9.AB9_CODTEC >='" +  MV_PAR01 + "' AND " 	
EndIf
If !Empty(MV_PAR02) 
	cQuery += "AB9.AB9_CODTEC <='" +  MV_PAR02 + "' AND " 	
EndIf

//Filtra Data de Inicio
If !Empty(MV_PAR03) 
		cQuery += "TDV.TDV_DTREF >='" + DToS( MV_PAR03 ) + "' AND "
EndIf
If !Empty(MV_PAR04) 
		cQuery += "TDV.TDV_DTREF <='" + DToS( MV_PAR04 ) + "' AND "
EndIf

//Filtra Marcacao conforme processamento
cQuery += "AB9.AB9_MPONTO = '"+Iif(MV_PAR05==1,'F','T')+"' AND "
	
cQuery += "AB9.D_E_L_E_T_=' ' AND "
cQuery += "AA1.D_E_L_E_T_=' ' AND "
cQuery += "TDV.D_E_L_E_T_=' ' AND "
cQuery += "ABB.D_E_L_E_T_=' ' AND "
cQuery += "ABS.D_E_L_E_T_=' ' "

cQuery += "ORDER BY AB9.AB9_CODTEC,AB9.AB9_DTINI"

Return( cQuery )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At910PMarc()

Ordena o array com as datas e horarios iniciais e finais

		Estrutura do Array aRetorno
		[nX][1]	- Codigo do Atendente(Caracter)
		[nX][2]	- Dia Inicial da marcaï¿½ï¿½o(Data)	
		[nX][3]	- Horario Inicial(Caracter)
		[nX][4]	- Horario Final(Caracter)
		[nX][5]	- Dia Final(Data)
		[nX][6]	- Codigo da Matricula(Caracter)		
		[nX][7]	- Filial do Funcionario(Caracter)
		[nX][8]	- Numero da O.S.(Caracter)		
		[nX][9]	- Codigo do Cliente(Caracter)
		[nX][10]	- Loja do Cliente(Caracter)
		[nX][11]	- Recno AB9(Numerico)
		[nX][12]	- Centro de Custo do Local de Atendimento(Caracter)

@param ExpA:Array contendo os atendimentos
		
@return ExpA: Array ordenado de acordo com as datas e horarios
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At910PMarc(aRetorno)
Local nX			:= 0 
Local aMarcacao	:= {}	//Marcacoes Tratadas
Local aRecno		:= {}	//Array com os Recnos que serao atualizados 
Local cCodTec		:= ""
Local dMarcIni	:= CtoD("  /  /    ")
Local cMarcIni	:= ""
Local dMarcFim	:= CtoD("  /  /    ")
Local cMarcFim	:= ""
Local cCodFunc	:= ""
Local cFilFun		:= ""
Local cCliente	:= ""
Local cLoja		:= ""
Local cNumOs		:= ""
Local cCCusto		:= ""
		
For nX := 1 To Len(aRetorno)
	//Quando inicia, muda o tecnico ou muda o dia inicial ou final da marcacao
	If nX == 1 .OR. cCodTec != aRetorno[nX][1] .OR. dMarcIni != aRetorno[nX][2]
		//Quando mudar adiciona a marcacao antes de reiniciar as variaveis desde que nao seja a ultima vez no loop
		If nX != 1
			AAdd(aMarcacao,{cCodTec,dMarcIni,cMarcIni,dMarcFim,cMarcFim,cCodFunc,cFilFun,cCliente,cLoja,cNumOs,aRecno,cCCusto})
		EndIf
		cCodTec		:= aRetorno[nX][1]		
		dMarcIni	:= aRetorno[nX][2]
		cMarcIni	:= aRetorno[nX][3]
		dMarcFim	:= aRetorno[nX][4]
		cMarcFim	:= aRetorno[nX][5]		
		cCodFunc	:= aRetorno[nX][6]
		cFilFun		:= aRetorno[nX][7]
		cCliente	:= aRetorno[nX][8]
		cLoja		:= aRetorno[nX][9]
		cNumOs		:= aRetorno[nX][10]
		aRecno		:= {aRetorno[nX][11]}	//Quando inicia limpa o recno
		cCCusto		:= aRetorno[nX][12]
	Else //Quando ï¿½ o mesmo tecnico e mesmo dia verifica a data/hora fim da Marcacao
		AAdd(aRecno,aRetorno[nX][11]) //
		If DToS(dMarcFim)+cMarcFim < DToS(aRetorno[nX][4])+aRetorno[nX][5]
			dMarcFim := aRetorno[nX][4]
			cMarcFim := aRetorno[nX][5]
		EndIf 
	EndIf
	
	//Adiciona o ï¿½ltimo registro na marcaï¿½ï¿½o
	If nX == Len(aRetorno) //Quando mudar adiciona a marcacao antes de reiniciar as variaveis
		AAdd(aMarcacao,{cCodTec,dMarcIni,cMarcIni,dMarcFim,cMarcFim,cCodFunc,cFilFun,cCliente,cLoja,cNumOs,aRecno,cCCusto})
	EndIf				
Next nX

Return(aMarcacao)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At910Marca()

Inclui via ExecAuto a Marcacao no POnto Eletronico

@param ExpA:Array contendo os dados para a ExecAuto
@param ExpC:Mensagem de Critica (Passar por referencia. Ira alterar com a mensagem quando houver erro)
		
@return ExpL: Retorna .T. quando hï¿½ sucesso na operaï¿½ï¿½o
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At910Marca(aMarcacao,cMsg)
Local lRet		:= .F. //Retorno da funï¿½ï¿½o
Local aCabec	:= {}	
Local aLinha	:= {}	
Local aItens	:= {}  
Local nMsg		:= 0
Local nOpc		:= Iif(MV_PAR05==1,3,5)
Local nI		:= 1
Local cFilProc 	:= ""
Local lAleato	:= .F.	
Local lCCusto	:= .F.
Local nMinuto	:= 0
Local nAleato	:= 0
Local lExiste	:= .F.
Local nX		:= 0
Local nPosFil	:= 0 
Local nPosMat	:= 0
Local nPosDat	:= 0
Local nPosHor	:= 0
Local nMinAleAux:= 0

lAleato			:= ( MV_PAR07 == 1 )	//Se Gera Marcacoes Aleatï¿½rias	

lCCusto			:= ( MV_PAR09 == 1 )	//Se o Centro de Custo do Local de Atendimento

If Len(aMarcacao) > 0
	AAdd(aCabec,{"RA_FILIAL"	,aMarcacao[1][7]})
	AAdd(aCabec,{"RA_MAT" 		,aMarcacao[1][6]})
	cFilProc := aMarcacao[1][7]
EndIf

If nOpc == 5 //se for exclusï¿½o , retorna a marcaï¿½ï¿½o da SP8 por causa dos minutos aleatorios
	DbSelectArea("SP8")
	DbSetOrder(2) // P8_FILIAL+P8_MAT+DTOS(P8_DATA)+STR(P8_HORA,5,2)
	
	For nI := 1 To Len(aMarcacao)
		If SP8->(DbSeek(xfilial('SP8') + aMarcacao[nI][6] + DTOS(aMarcacao[nI][2])))
			While SP8->(P8_FILIAL + P8_MAT + DTOS(P8_DATA) ) == xfilial('SP8') + aMarcacao[nI][6] + DTOS(aMarcacao[nI][2]) .and. SP8->(!EOF())
				For nX := 1 to len(aItens)		
					nPosFil	:= AScan(aItens[nX],{|x| Iif(ValType(x[2]) == ValType(SP8->P8_FILIAL)	, x[2] == SP8->P8_FILIAL , 0) })
					nPosMat	:= AScan(aItens[nX],{|x| Iif(ValType(x[2]) == ValType(SP8->P8_MAT)		, x[2] == SP8->P8_MAT , 0) })					
					nPosDat	:= AScan(aItens[nX],{|x| Iif(ValType(x[2]) == ValType(SP8->P8_DATA)		, x[2] == SP8->P8_DATA , 0) })
					nPosHor	:= AScan(aItens[nX],{|x| Iif(ValType(x[2]) == ValType(SP8->P8_HORA)		, x[2] == SP8->P8_HORA , 0) })
					If nPosFil > 0 .and. nPosMat > 0 .and. nPosDat > 0 .and. nPosHor > 0
						lExiste := .T.
						Exit
					Else
						lExiste := .F.
					EndIf					
				Next

				
				If !lExiste
					aLinha := {}
					// 1a Entrada
					AAdd(aLinha,{"P8_FILIAL"	,aMarcacao[nI][7]})
					AAdd(aLinha,{"P8_MAT"		,aMarcacao[nI][6]})
					AAdd(aLinha,{"P8_DATA"		,aMarcacao[nI][2]})
					AAdd(aLinha,{"P8_HORA"		,SP8->P8_HORA})
					AAdd(aItens,aLinha)
				EndIf
				SP8->(dbskip())
			EndDo
		EndIf
		
		If SP8->(DbSeek(xfilial('SP8') + aMarcacao[nI][6] + DTOS(aMarcacao[nI][4])))
			While SP8->(P8_FILIAL + P8_MAT + DTOS(P8_DATA) ) == xfilial('SP8') + aMarcacao[nI][6] + DTOS(aMarcacao[nI][4]) .and. SP8->(!EOF())
				For nX := 1 to len(aItens)
					nPosFil	:= AScan(aItens[nX],{|x| Iif(ValType(x[2]) == ValType(SP8->P8_FILIAL), x[2] == SP8->P8_FILIAL , 0) })
					nPosMat	:= AScan(aItens[nX],{|x| Iif(ValType(x[2]) == ValType(SP8->P8_MAT), x[2] == SP8->P8_MAT , 0) })					
					nPosDat	:= AScan(aItens[nX],{|x| Iif(ValType(x[2]) == ValType(SP8->P8_DATA), x[2] == SP8->P8_DATA , 0) })
					nPosHor	:= AScan(aItens[nX],{|x| Iif(ValType(x[2]) == ValType(SP8->P8_HORA), x[2] == SP8->P8_HORA , 0) })
					If nPosFil > 0 .and. nPosMat > 0 .and. nPosDat > 0 .and. nPosHor > 0
						lExiste := .T.
						Exit
					Else
						lExiste := .F.
					EndIf
				Next
												
				If !lExiste	
					aLinha := {}	
					// 2a Saida
					AAdd(aLinha,{"P8_FILIAL"	,aMarcacao[nI][7]})
					AAdd(aLinha,{"P8_MAT"		,aMarcacao[nI][6]})
					AAdd(aLinha,{"P8_DATA"		,aMarcacao[nI][4]})
					AAdd(aLinha,{"P8_HORA"		,SP8->P8_HORA})
					AAdd(aItens,aLinha)
				EndIf
				SP8->(dbskip())
			EndDo
		EndIf	
	Next nI
	
Else
	For nI := 1 To Len(aMarcacao)

		aLinha := {}
		//Entrada
		AAdd(aLinha,{"P8_FILIAL"	,aMarcacao[nI][7]})
		AAdd(aLinha,{"P8_MAT"		,aMarcacao[nI][6]})
		AAdd(aLinha,{"P8_DATA"		,aMarcacao[nI][2]})
		
		If lAleato

			nAleato := 0

			nMinuto	:= Abs( MV_PAR08 )	//Minutos para a Aleatoriedade das Marcacoes
		
			nMinAleAux := (Val(StrTran(aMarcacao[nI][3],":","."))-(nMinuto/100))

			//Calculo para não voltar para o dia anterior quando for minutos aleatórios
			If nMinAleAux < 0
				nMinuto := (nMinAleAux+(nMinuto/100))
			EndIf

			If nMinuto > 0
				AAdd(aLinha,{"P8_HORA"	,DataHora2Ale(aMarcacao[nI][2],Val(StrTran(aMarcacao[nI][3],":",".")),nMinuto,@nAleato,"E")})
			Else
				AAdd(aLinha,{"P8_HORA"	,Val(StrTran(aMarcacao[nI][3],":","."))})
			Endif
		Else
			AAdd(aLinha,{"P8_HORA"	,Val(StrTran(aMarcacao[nI][3],":","."))})
		EndIf
		
		If lCCusto .and. !Empty(aMarcacao[nI][12])
			AAdd(aLinha,{"P8_CC"	,aMarcacao[nI][12]})
		EndIf
		
		AAdd(aItens,aLinha)
		
		aLinha := {}	
		//Saida
		AAdd(aLinha,{"P8_FILIAL"	,aMarcacao[nI][7]})
		AAdd(aLinha,{"P8_MAT"		,aMarcacao[nI][6]})
		AAdd(aLinha,{"P8_DATA"		,aMarcacao[nI][4]})

		If lAleato

			nAleato := 0

			nMinuto	:= Abs( MV_PAR08 )	//Minutos para a Aleatoriedade das Marcacoes

			nMinAleAux := (Val(StrTran(aMarcacao[nI][5],":","."))+(nMinuto/100))

			//Calculo para não transcender o dia quando for minutos aleatórios
			If nMinAleAux > 23.59
				nMinuto := ((23.59-Val(StrTran(aMarcacao[nI][5],":",".")))*100)
			EndIf
			
			If nMinuto > 0
				AAdd(aLinha,{"P8_HORA"	,DataHora2Ale(aMarcacao[nI][4],Val(StrTran(aMarcacao[nI][5],":",".")),nMinuto,@nAleato,"S")})
			Else
				AAdd(aLinha,{"P8_HORA"	,Val(StrTran(aMarcacao[nI][5],":","."))})
			Endif

		Else
			AAdd(aLinha,{"P8_HORA"	,Val(StrTran(aMarcacao[nI][5],":","."))})
			
		EndIf

		If lCCusto .and. !Empty(aMarcacao[nI][12])
			AAdd(aLinha,{"P8_CC"	,aMarcacao[nI][12]})
		EndIf

		AAdd(aItens,aLinha)
	
	Next nI
EndIf

aRetInc := Ponm010(		.F.				,;	//01 -> Se o "Start" foi via WorkFlow
						.F. 			,;	//02 -> Se deve considerar as configuracoes dos parametros do usuario
						.T.				,;	//03 -> Se deve limitar a Data Final de Apontamento a Data Base
						cFilProc		,;	//04 -> Filial a Ser Processada
						.F.				,;	//05 -> Processo por Filial
						.F.				,;	//06 -> Apontar quando nao Leu as Marcacoes para a Filial
						.F.				,;	//07 -> Se deve Forcar o Reapontamento
						aCabec			,;
						aItens			,;
						nOpc    		,;
						)

If Len(aRetInc) > 0 .And. !(aRetInc[1])
	cMsg := ""
	For nMsg := 1 to Len(aRetInc[2])
		cMsg += aRetInc[2,nMsg] + CRLF
	Next
	lRet := .F.	
ElseIf aRetInc[1]
	lRet := .T.
EndIf


Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At910AtAB9()

Atualiza o Atendimento para informar que jï¿½ foi gerado Marcacao

@param ExpC:Recno do Atendimento que serï¿½ atualizado

@return ExpL: Retorna .T. a atualizaï¿½ï¿½o aconteceu com sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At910AtAB9(xRecno)
Local nRecnoAB9  	:= 0 	// Recno da tabela ABB
Local nI			:= 0
Local lMarca		:= Iif(MV_PAR05==1,.T.,.F.)
Local aRecnoAB9		:= {}
DbSelectArea("AB9")

If ValType(xRecno) != "A"
	aRecnoAB9 := {xRecno}
Else
	aRecnoAB9 := xRecno
EndIf 

For nI := 1 To Len(aRecnoAB9)
	AB9->( MsGoto( nRecnoAB9 := aRecnoAB9[nI] ) )
	RecLock("AB9", .F.)
	AB9_MPONTO	:= lMarca	//Gerou Marcaï¿½ï¿½o ".T." - Sim ; ".F." - Nï¿½o	
	AB9->( MsUnLock() )				
Next nI
  		
Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At910Log()

Adiciona dados do registro em processamento quando houver crï¿½tica.

@param ExpA:Array com as criticas de todo o processamento.
@param Expc:Alias da tabela do processamento.
@param cMsg:Mensagem de critica do registro corrente.

/*/
//--------------------------------------------------------------------------------------------------------------------
Function At910Log(cAlias,aMarcacao,cMsg)
Local cText			:= ""
Local cRecno			:= ""
Local cPath			:= ""
Local cDirDest		:= MV_PAR10
Default cAlias		:= ""
Default aMarcacao		:= {}
		
If !Empty(cAlias)  
	//"Crï¿½tica ao processar : R_E_C_N_O_ " 	
	cText += STR0026+cValToChar((cAlias)->AB9RECNO)+CRLF;
	+" "+RetTitle("AB9_CODTEC")+":"+(cAlias)->AB9_CODTEC+CRLF;
	+" "+RetTitle("AB9_NUMOS")+":"+(cAlias)->AB9_NUMOS+CRLF;
	+" "+RetTitle("AB9_SEQ")+":"+(cAlias)->AB9_SEQ+CRLF;
	+" "+RetTitle("AB9_CODCLI")+":"+(cAlias)->AB9_CODCLI+CRLF;
	+" "+RetTitle("AB9_LOJA")+":"+(cAlias)->AB9_LOJA+CRLF;
	+" "+RetTitle("AB9_DTINI")+":"+DtoC((cAlias)->AB9_DTINI)+CRLF;
	+" "+RetTitle("AB9_HRINI")+":"+(cAlias)->AB9_HRINI+CRLF;
	+" "+RetTitle("AB9_DTFIM")+":"+DToC((cAlias)->AB9_DTFIM)+CRLF;
	+" "+RetTitle("AB9_HRFIM")+":"+(cAlias)->AB9_HRFIM+CRLF;
	+" "+CRLF+cMsg+CRLF		
EndIf

If Len(aMarcacao) > 0
	If ValType(aMarcacao[11]) == "A"
		AEval(aMarcacao[11],{|x| cRecno += cValToChar(x)+"," })
	Else
		cRecno += cValToChar(aMarcacao[11])
	EndIf  
	//"Crï¿½tica execauto de marcaï¿½ï¿½o : R_E_C_N_O_ "
	cText += STR0027+cRecno+CRLF;
	+" "+RetTitle("AB9_CODTEC")+":"+aMarcacao[1]+CRLF;
	+" "+RetTitle("AB9_NUMOS")+":"+aMarcacao[10]+CRLF;
	+" "+RetTitle("AB9_CODCLI")+":"+aMarcacao[8]+CRLF;
	+" "+RetTitle("AB9_LOJA")+":"+aMarcacao[9]+CRLF;
	+" "+RetTitle("AA1_CDFUNC")+":"+aMarcacao[6]+CRLF;
	+" "+RetTitle("AA1_FUNFIL")+":"+aMarcacao[7]+CRLF;
	+STR0029+DtoC(aMarcacao[2])+CRLF;  	// " Data Inicio:"  
	+STR0030+aMarcacao[3]+CRLF;   			// " Hora Inicio:" 
	+STR0031+DToC(aMarcacao[4])+CRLF;   	// "Data Fim:" 
	+STR0032+aMarcacao[5]+CRLF;   			// " Hora Fim:"
	+" "+CRLF+cMsg+CRLF
EndIf

//Cria arquivo de Log
TxLogFile("MarcaErro",cText)

cPath := TxLogPath("MarcaErro") //Resgata o nome do arquivo log gerado
CpyS2T(cPath, cDirDest, .F. ) //Faz uma cï¿½pia do log para a maquina do usuario	
	              
Return